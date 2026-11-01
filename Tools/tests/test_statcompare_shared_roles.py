"""Shared-service observation adapter; real source and strict font/native contracts.

This does not validate live transport or client rendering. Wire parsing belongs
to the shared-service suite, not a second fake implementation in this adapter.
"""
from pathlib import Path
import argparse
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tools/tests'))
from test_statcompare_talents import (BASE, FALLBACK, FONT, HARNESS, NATIVE,
                                     SOURCE, LuaRuntime, native_chunk)

SERVICE = r'''
serviceRequests, serviceCancels, callbacks = {}, {}, {}
local cache={}
SC_TeamRolesService={}
local rawMessage,guard
local managed={}
function SC_TeamRolesService:EnsureNativeGuard()
 if guard then return end
 rawMessage=InspectTalentsFrame_HandleMessage
 guard=function(message,sender)
  local normalized=type(message)=='string' and string.gsub(message,'^%s+','') or message
  if type(normalized)=='string' then
   local at=string.find(normalized,';',1,true)
   local kind=at and string.sub(normalized,1,at-1) or normalized
   if kind=='INSTalentShow' then return rawMessage('INSTalentShow',sender) end
   if managed[sender] and string.find(kind,'INSTalent',1,true) then return end
  end
  return rawMessage(message,sender)
 end
 InspectTalentsFrame_HandleMessage=guard
end
function SC_TeamRolesService:GetNativeMessageHandler() return rawMessage end
function SC_TeamRolesService:GetInfo(unit) return cache[targetKey] end
function SC_TeamRolesService:GetDiagnostics() return {requests=table.getn(serviceRequests),completed=0,queued=1} end
function SC_TeamRolesService:Cancel(owner) table.insert(serviceCancels,owner);callbacks[owner]=nil end
function SC_TeamRolesService:Request(unit,owner,callback,force,priority)
 self:EnsureNativeGuard();managed[targetName]=true
 table.insert(serviceRequests,{unit,owner,callback,force,priority,targetKey})
 callbacks[owner]=callback
 if serviceFailure then return false,'查询服务不可用' end
 return true
end
function SharedRecord(name,class,key)
 local r={name=name or targetName,class=class or targetClass,key=key or targetKey,time=clock,tabs={},talents={{},{},{}}}
 for t=1,3 do
  r.tabs[t]={points=3,count=2,message=Tab(t)}
  for i=1,2 do r.talents[t][i]={rank=i,maximum=5,tier=i,column=i,message=Info(t,i)} end
 end
 return r
end
function SharedComplete(record)
 record=record or SharedRecord();cache[record.key]=record
 local callback=callbacks.StatCompareInspect
 if callback then callbacks.StatCompareInspect=nil;callback(record) end
end
function SharedFail(reason)
 local callback=callbacks.StatCompareInspect
 if callback then callbacks.StatCompareInspect=nil;callback(nil,reason or '共享查询超时') end
end
function SetSharedCache(record) cache[record.key]=record end
'''


def world(native, enabled=True, service=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().InstallFonts = lua.execute(FONT)
    lua.execute(BASE)
    lua.execute(native)
    lua.execute(HARNESS)
    if service:
        lua.execute(SERVICE)
    lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
    if enabled:
        lua.execute('SCInspectTalents.SetEnabled(true)')
    return lua


def real_world(native):
    """Actual broker plus actual adapter; two-node class fixture is wire data only."""
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().InstallFonts = lua.execute(FONT)
    lua.execute(BASE)
    lua.execute(native)
    lua.execute(HARNESS)
    lua.execute(r'''
local methods=getmetatable(InspectFrame).__index
function methods:RegisterEvent(name) self.events=self.events or {};self.events[name]=true end
function methods:UnregisterEvent(name) if self.events then self.events[name]=nil end end
SC_TeamRoleData={}
for _,class in ipairs({'PRIEST','WARRIOR','MAGE','PALADIN'}) do
 SC_TeamRoleData[class]={}
 for tree=1,3 do SC_TeamRoleData[class][tree]={{5,1,1},{5,2,2}} end
end
partyCount=0
function GetNumRaidMembers() return 0 end
function GetNumPartyMembers() return partyCount end
function GetRealmName() return 'TestRealm' end
function UnitExists(unit)
 if unit=='player' then return 1,'guid-Player' end
 if unit=='target' or unit=='party1' and partyCount>0 then
  if targetValid then return 1,targetKey end
 end
end
function UnitName(unit)
 if unit=='player' then return 'Player' end
 if unit=='target' or unit=='party1' and partyCount>0 then return targetValid and targetName end
end
function UnitClass(unit)
 if unit=='player' then return 'Priest','PRIEST' end
 return targetClass,targetClass
end
function UnitIsUnit(a,b)
 return a==b or a=='target' and b=='party1' and partyCount>0 or b=='target' and a=='party1' and partyCount>0
end
function UnitIsConnected(unit) return UnitExists(unit)~=nil end
function UnitAffectingCombat() return false end
function FeedWire(message,sender)
 sender=sender or targetName
 InspectTalentsFrame_HandleMessage(message,sender)
 SC_TeamRolesService:Packet('TW_CHAT_MSG_WHISPER<Player>',message,'WHISPER',sender)
end
function CompleteWire(tabPrefix)
 local prefix=tabPrefix or ''
 for tree=1,3 do
  FeedWire(prefix..Tab(tree))
  for i=1,2 do FeedWire(prefix..Info(tree,i)) end
 end
 FeedWire(prefix..'INSTalentEND;1;')
end
''')
    lua.execute((ROOT / 'Interface/AddOns/!Libs/SC_TeamRoles.lua').read_text(encoding='utf-8-sig'))
    lua.execute((ROOT / 'Interface/AddOns/!Libs/SC_TeamRoleService.lua').read_text(encoding='utf-8-sig'))
    lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
    lua.execute('SCInspectTalents.SetEnabled(true)')
    return lua


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', type=Path, default=NATIVE)
    parser.add_argument('--contract-only', action='store_true')
    parser.add_argument('--no-compile', action='store_true')
    args = parser.parse_args()
    native, mode = native_chunk(None if args.contract_only else args.native)
    print('Native compatibility mode:', mode)
    checks = 0

    def case(name, code, enabled=True, service=True):
        nonlocal checks
        lua = world(native, enabled, service)
        lua.execute(code)
        checks += 1
        print('PASS', name)

    case('disabled adapter owns no traffic, cache or timer', '''
assert(not SCInspectTalents.enabled and ActiveUpdates()==0 and not SCInspectTalents.status)
assert(Requests()==0 and table.getn(serviceRequests)==0)
''', enabled=False)
    case('strict fonts reject missing initialization and preserve valid templates', '''
local t=NewObject('FontString',nil,nil)
assert(not pcall(function() t:SetText('bad') end))
failedFontPaths.bad=true;assert(not t:SetFont('bad',12))
assert(not pcall(function() t:SetText('bad') end))
t:SetFontObject(GameFontNormal);t:SetText('valid')
OpenTarget();assert(SCInspectTalents.status.font)
''')
    case('manual inspection requests shared broker once with priority and no private send', '''
OpenTarget();SCInspectTalents.Request();SCInspectTalents.Open()
assert(table.getn(serviceRequests)==1 and Requests()==0 and ActiveUpdates()==0)
local req=serviceRequests[1]
assert(req[1]=='target' and req[2]=='StatCompareInspect' and not req[4] and req[5]==100)
assert(SCInspectTalents.status:IsVisible())
''')
    case('only complete shared result initializes and replays native cache', '''
OpenTarget();local state,owner=NativeState();assert(state.class=='' and owner=='')
SharedComplete();state,owner=NativeState()
assert(state.class=='WARRIOR' and owner=='Alpha' and renders==1)
assert(Requests()==0 and ActiveUpdates()==0 and table.getn(delivered)==10)
assert(SendAddonMessage==SavedSend and not SCInspectTalents.status:IsShown())
''')
    case('background and raw replies do not reach native display path', '''
OpenTarget();Complete('Alpha');assert(renders==0 and table.getn(delivered)==0)
Feed(string.char(9)..'INSTalentEND;1;','Alpha')
Feed(string.char(9)..'INSTalentExtension;no-tree;','Alpha')
assert(renders==0 and table.getn(serviceRequests)==1)
SharedComplete();assert(renders==1)
''')
    case('peer requests with framing and tail fields use original response', '''
Feed(string.char(9)..'INSTalentShow;1;','Peer')
assert(table.getn(sends)>0 and Requests()==0 and table.getn(serviceRequests)==0)
local text=string.char(9)..'OTHER_MESSAGE';Feed(text,'Peer')
assert(delivered[table.getn(delivered)][1]==text)
''')
    case('one shared cache supplies reopen without own talent copy or query', '''
OpenTarget();SharedComplete();local n=table.getn(objects)
InspectFrame_ShowSubFrame('InspectPaperDollFrame');SCInspectTalents.Open()
assert(table.getn(serviceRequests)==1 and renders==2 and table.getn(objects)==n)
assert(SCInspectTalents.diagnostics.state=='cached' and ActiveUpdates()==0)
''')
    case('Ctrl refresh bypasses UI freshness through shared broker', '''
OpenTarget();SharedComplete();control=true;SCInspectTalents.Request()
assert(table.getn(serviceRequests)==2 and serviceRequests[2][4])
SharedComplete();assert(renders==2 and Requests()==0)
''')
    case('cache older than UI freshness requests broker again', '''
OpenTarget();SharedComplete();Tick(30.01);SCInspectTalents.Request()
assert(table.getn(serviceRequests)==2 and Requests()==0)
SharedComplete();assert(renders==2)
''')
    case('missing shared service fails safely instead of private fallback', '''
OpenTarget();assert(Requests()==0 and ActiveUpdates()==0 and renders==0)
assert(InspectFrame.selectedTab==1 and table.getn(notices)==1)
''', service=False)
    case('broker rejection and timeout leave no private timer or native changes', '''
serviceFailure=true;OpenTarget();assert(renders==0 and Requests()==0 and ActiveUpdates()==0)
serviceFailure=false;OpenTarget();SharedFail()
assert(renders==0 and Requests()==0 and InspectFrame.selectedTab==1)
''')
    case('native initializer restores global sender on errors', '''
initFailure=true;extraSend=true;OpenTarget();SharedComplete()
assert(SendAddonMessage==SavedSend and Requests()==0 and renders==0)
assert(sends[1][1]=='OTHER' and sends[1][4]=='SideTarget')
''')
    case('native replay retains unrelated synchronous messages', '''
extraSend=true;OpenTarget();SharedComplete()
assert(renders==1 and Requests()==0 and table.getn(sends)==1)
assert(sends[1][1]=='OTHER' and SendAddonMessage==SavedSend)
''')
    case('closing page cancels only inspection owner and rejects retained callback', '''
OpenTarget();local callback=serviceRequests[1][3]
InspectFrame_ShowSubFrame('InspectPaperDollFrame');callback(SharedRecord())
assert(renders==0 and InspectPaperDollFrame:IsVisible() and Requests()==0)
assert(serviceCancels[table.getn(serviceCancels)]=='StatCompareInspect')
''')
    case('closing parent cannot reopen on late result', '''
OpenTarget();local callback=serviceRequests[1][3];InspectFrame:Hide()
callback(SharedRecord());assert(renders==0 and not InspectFrame:IsShown())
''')
    case('target change cancels without native auto inspection or replacement query', '''
OpenTarget();local callback=serviceRequests[1][3]
FireTarget('Beta','MAGE','guid-B');callback(SharedRecord('Alpha','WARRIOR','guid-A'))
assert(not InspectFrame:IsShown() and nativeInspect==0 and renders==0)
assert(table.getn(serviceRequests)==1)
''')
    case('identity checks reject silent target changes without waiting for a timer', '''
OpenTarget();local callback=serviceRequests[1][3]
targetName,targetClass,targetKey='Beta','MAGE','guid-B'
callback(SharedRecord('Alpha','WARRIOR','guid-A'))
assert(renders==0 and ActiveUpdates()==0 and not InspectFrame:IsShown())
''')
    case('new ticket rejects same-player completion from canceled UI subscription', '''
OpenTarget();local old=serviceRequests[1][3]
InspectFrame_ShowSubFrame('InspectPaperDollFrame');SCInspectTalents.Open()
old(SharedRecord());assert(renders==0)
SharedComplete();assert(renders==1)
''')
    case('completed A canceled B then cached A displays correct native class', '''
OpenTarget();SharedComplete();OpenTarget('Beta','MAGE','guid-B')
local callback=serviceRequests[2][3]
FireTarget('Alpha','WARRIOR','guid-A');callback(SharedRecord('Beta','MAGE','guid-B'))
OpenTarget();local state,owner=NativeState()
assert(state.class=='WARRIOR' and owner=='Alpha' and renders==2 and table.getn(serviceRequests)==2)
''')
    case('shared records incompatible with native layout never publish', '''
OpenTarget();local r=SharedRecord();r.tabs[1].count=21;SharedComplete(r)
assert(renders==0 and InspectFrame.selectedTab==1)
''')
    case('missing native module and class definitions prevent query', '''
talentLoaded=false;loadFailure=true;OpenTarget();assert(table.getn(serviceRequests)==0)
talentLoaded=true;loadFailure=false;Turtle_TalentsData.WARRIOR=nil
OpenTarget();assert(table.getn(serviceRequests)==0)
''')
    case('diagnostics read shared counters without request or private packet data', '''
SCInspectTalents.ShowDiagnostics();assert(table.getn(serviceRequests)==0 and Requests()==0)
assert(table.getn(notices)==2)
''')
    case('repeated enabling restores owned hooks without frame growth', '''
for i=1,5 do
 local show=InspectTalentsFrame_OnShow
 SCInspectTalents.SetEnabled(true);assert(show==InspectTalentsFrame_OnShow)
 SCInspectTalents.SetEnabled(false);assert(not SCInspectTalents.enabled and ActiveUpdates()==0)
 SCInspectTalents.SetEnabled(true)
end
OpenTarget();SharedComplete();assert(renders==1 and table.getn(serviceRequests)==1)
''')
    case('later third party hooks remain installed after disable', '''
local oldShow,oldMessage,oldOpen=InspectTalentsFrame_OnShow,InspectTalentsFrame_HandleMessage,InspectFrameTalentsTab_OnClick
local thirdShow=function() return oldShow() end
local thirdMessage=function(...) return oldMessage(...) end
local thirdOpen=function() return oldOpen() end
InspectTalentsFrame_OnShow=thirdShow;InspectTalentsFrame_HandleMessage=thirdMessage;InspectFrameTalentsTab_OnClick=thirdOpen
SCInspectTalents.SetEnabled(false)
assert(InspectTalentsFrame_OnShow==thirdShow and InspectTalentsFrame_HandleMessage==thirdMessage)
assert(InspectFrameTalentsTab_OnClick==thirdOpen and ActiveUpdates()==0)
Feed('OTHER','Peer');assert(delivered[1][1]=='OTHER')
''')
    text = SOURCE.read_text(encoding='utf-8-sig')
    assert 'local recent' not in text and 'local draining' not in text
    assert ':SetScript("OnUpdate"' not in text
    assert 'pcall(SendAddonMessage' not in text
    print('PASS adapter has no independent wire queue, quarantine or update timer')
    checks += 1
    for name, code in {
        'real broker and adapter send once, validate TAB/END extensions, replay once': '''
OpenTarget();Tick(.1);assert(Requests()==1 and renders==0)
FeedWire(string.char(9)..'INSTalentExtension;not-a-tree;')
CompleteWire(string.char(9))
assert(renders==1 and Requests()==1 and SendAddonMessage==SavedSend)
assert(SC_TeamRolesService:GetInfo('target').queryState=='complete')
''',
        'real background and inspection same member share queue and cache': '''
partyCount=1;SC_TeamRolesService:Acquire('test-background')
OpenTarget();Tick(.1);assert(Requests()==1)
CompleteWire();assert(renders==1)
InspectFrame_ShowSubFrame('InspectPaperDollFrame');SCInspectTalents.Open()
assert(Requests()==1 and renders==2)
assert(SC_TeamRolesService:GetDiagnostics().consumers==1)
''',
        'real canceled subscriber does not stop cache completion or reopen page': '''
partyCount=1;SC_TeamRolesService:Acquire('test-background')
OpenTarget();Tick(.1);InspectFrame_ShowSubFrame('InspectPaperDollFrame')
CompleteWire();assert(renders==0 and InspectPaperDollFrame:IsVisible())
assert(SC_TeamRolesService:GetInfo('target').queryState=='complete')
SCInspectTalents.Open();assert(renders==1 and Requests()==1)
''',
        'real passive core guard survives disabled display adapter': '''
OpenTarget();Tick(.1);SCInspectTalents.SetEnabled(false)
CompleteWire();assert(renders==0 and not SCInspectTalents.enabled and Requests()==1)
assert(table.getn(delivered)==0)
FeedWire(string.char(9)..'INSTalentShow;1;','Peer')
assert(table.getn(delivered)==1 and delivered[1][1]=='INSTalentShow')
''',
        'real timeout and wrong target never publish partial native state': '''
OpenTarget();Tick(.1);Tick(13)
assert(renders==0 and SCInspectTalents.diagnostics.state=='failed')
CompleteWire();assert(renders==0)
''',
    }.items():
        lua = real_world(native)
        lua.execute(code)
        checks += 1
        print('PASS', name)
    if not args.no_compile:
        compiler = ROOT / 'PluginHistory/staging/lua503-validation/win64/luac50.exe'
        result = subprocess.run([str(compiler), '-p', str(SOURCE)], capture_output=True)
        assert result.returncode == 0, result.stderr
        print('PASS actual Lua 5.0 syntax')
    print(f'{checks} shared-observation groups passed. Live game QA remains required.')


if __name__ == '__main__':
    main()
