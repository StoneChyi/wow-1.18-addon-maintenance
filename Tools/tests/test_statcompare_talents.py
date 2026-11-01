"""StatCompare talent sessions: legacy UI/font contract and optional real client parser.

The optional native file stays outside Git. Passing these simulations does not
establish live server transport, client rendering or actual resource use.
"""
from pathlib import Path
import argparse
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

SOURCE = ROOT / 'Interface/AddOns/StatCompare/SCInspectTalents.lua'
NATIVE = ROOT / 'PluginHistory/staging/statcompare-inspect-research/patch-9.mpq-InspectTalentsFrame.lua'
FONT = (ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig')

BASE = r'''
objects, sends, notices, delivered = {}, {}, {}, {}
clock, renders, nativeEvents, nativeInspect, nativeShows = 0, 0, 0, 0, 0
targetName, targetClass, targetKey = 'Alpha', 'WARRIOR', 'guid-A'
targetValid, targetInspectable, talentLoaded, control = true, true, true, false
local methods = {}
local function invoke(obj, script, ...)
 local oldThis,oldEvent,oldArg1=this,event,arg1
 this=obj;arg1=select(1,...)
 local f=obj.scripts[script]
 if f then f() end
 this,event,arg1=oldThis,oldEvent,oldArg1
end
local function visible(obj)
 return obj.shown and (not obj.parent or visible(obj.parent))
end
local function updateVisibility()
 for _,obj in ipairs(objects) do
  local now=visible(obj)
  if now~=obj.wasVisible then
   obj.wasVisible=now
   invoke(obj,now and 'OnShow' or 'OnHide')
  end
 end
end
function NewObject(kind,name,parent)
 local obj=setmetatable({kind=kind,name=name,parent=parent,scripts={},shown=false,wasVisible=false},{__index=methods})
 table.insert(objects,obj);if name then _G[name]=obj end;return obj
end
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:GetScript(key) return self.scripts[key] end
function methods:Show() self.shown=true;updateVisibility() end
function methods:Hide() self.shown=false;updateVisibility() end
function methods:IsShown() return self.shown end
function methods:IsVisible() return visible(self) end
function methods:GetID() return self.id end
function methods:SetPoint(...) self.point={...} end
function methods:SetWidth(width) self.width=width end
function methods:SetTextColor(...) self.color={...} end
InstallFonts(methods,NewObject)
function CreateFrame(kind,name,parent) return NewObject(kind,name,parent) end
InspectFrame=CreateFrame('Frame','InspectFrame');InspectFrame.id=0
InspectPaperDollFrame=CreateFrame('Frame','InspectPaperDollFrame',InspectFrame);InspectPaperDollFrame.id=1
InspectHonorFrame=CreateFrame('Frame','InspectHonorFrame',InspectFrame);InspectHonorFrame.id=2
InspectArenaFrame=CreateFrame('Frame','InspectArenaFrame',InspectFrame);InspectArenaFrame.id=3
InspectTalentsFrame=CreateFrame('Frame','InspectTalentsFrame',InspectFrame);InspectTalentsFrame.id=4
TWTalentFrame=CreateFrame('Frame','TWTalentFrame',InspectTalentsFrame)
INSPECTFRAME_SUBFRAMES={'InspectPaperDollFrame','InspectHonorFrame','InspectArenaFrame','InspectTalentsFrame'}
function PanelTemplates_SetTab(frame,id) frame.selectedTab=id end
function InspectFrame_ShowSubFrame(name)
 for _,n in ipairs(INSPECTFRAME_SUBFRAMES) do if n==name then _G[n]:Show() else _G[n]:Hide() end end
end
function HideUIPanel(frame) frame:Hide() end
function GetTime() return clock end
function UnitExists(unit)
 if not targetValid then return nil end
 return 1,targetKey
end
function UnitName(unit) return targetValid and targetName or nil end
function UnitClass(unit) return targetClass,targetClass end
function UnitIsPlayer(unit) return targetValid end
function UnitIsUnit(a,b) return targetValid and (a=='target' or a=='mouseover') and b=='target' end
function CanInspect(unit) return targetValid and targetInspectable end
function IsControlKeyDown() return control end
function IsAddOnLoaded(name) return name~='Blizzard_TalentUI' or talentLoaded end
function LoadAddOn(name) if loadFailure then return nil,'MISSING' end;talentLoaded=true;return 1 end
function SendAddonMessage(prefix,message,channel,recipient)
 if sendFailure then error('send failure') end
 table.insert(sends,{prefix,message,channel,recipient});return 'sent',recipient
end
SavedSend=SendAddonMessage
DEFAULT_CHAT_FRAME={AddMessage=function(self,text) table.insert(notices,text) end}
UNKNOWNOBJECT='Unknown'
strfind=string.find;format=string.format
function explode(message,separator)
 local out={};for field in string.gmatch(message..separator,'(.-)'..separator) do table.insert(out,field) end;return out
end
Turtle_TalentsData={}
for _,class in ipairs({'WARRIOR','MAGE','PALADIN'}) do
 Turtle_TalentsData[class]={}
 for tree=1,3 do
  local tab={name=class..'-tree'..tree,background='background'}
  for i=1,2 do tab[i]={name=class..'-node'..i,icon='spell',desc={'rank-one','rank-two','rank-three','rank-four','rank-five'}} end
  Turtle_TalentsData[class][tree]=tab
 end
end
function GetNumTalentTabs() return 3 end
function GetNumTalents(tree) return 2 end
function GetTalentTabInfo(tree) return 'own-tree','icon',2 end
function GetTalentInfo(tree,i) return 'own-node','icon',i,i,1,5,nil,1 end
function GetTalentPrereqs(tree,i) return nil,nil,nil end
TOOLTIP_TALENT_RANK='%d/%d'
function Tick(seconds)
 clock=clock+seconds
 for _,obj in ipairs(objects) do if obj.scripts.OnUpdate then invoke(obj,'OnUpdate',seconds) end end
end
function ActiveUpdates()
 local n=0;for _,obj in ipairs(objects) do if obj.scripts.OnUpdate then n=n+1 end end;return n
end
function Requests()
 local n=0;for _,s in ipairs(sends) do if s[2]=='INSTalentShow' then n=n+1 end end;return n
end
function FireTarget(name,class,key)
 targetName,targetClass,targetKey=name,class,key
 local old=event;event='PLAYER_TARGET_CHANGED';invoke(InspectFrame,'OnEvent');event=old
end
function OpenTarget(name,class,key)
 InspectTalentsFrame:Hide();InspectFrame:Hide()
 targetName,targetClass,targetKey=name or 'Alpha',class or 'WARRIOR',key or 'guid-A'
 InspectFrame.unit='target';InspectFrame:Show();SCInspectTalents.Open()
end
function Tab(tree,points,count) return 'INSTalentTabInfo;'..tree..';tree;'..(points or 3)..';'..(count or 2) end
function Info(tree,i,rank)
 return 'INSTalentInfo;'..tree..';'..i..';node;'..i..';'..i..';'..(rank or i)..';5;1;-1;-1;-1'
end
function Feed(message,sender) InspectTalentsFrame_HandleMessage(message,sender or targetName) end
function Complete(sender)
 for tree=1,3 do Feed(Tab(tree),sender);for i=1,2 do Feed(Info(tree,i),sender) end end
 Feed('INSTalentEND;',sender)
end
'''

# Small independently written behavioral contract, used only when no extracted
# client parser is available. Real-client runs read their source from --native.
FALLBACK = r'''
local state={class='',{},{},{}}
local owner=''
function NativeState() return state,owner end
function NativeRead(t,i) local n=state[t][i];return '', '', n.tier,n.column,n.rank,n.maximum end
function NativeTab(t) return '', '',state[t].pointsSpent end
function InspectTalentsFrame_OnShow()
 if owner==targetName then TWTalentFrame:Show();return end
 state.class=targetClass
 for t=1,3 do state[t]={pointsSpent=0,numTalents=0} end
 SendAddonMessage('TW_CHAT_MSG_WHISPER<'..targetName..'>','INSTalentShow','GUILD')
end
function InspectTalentsFrame_HandleMessage(message,sender)
 local f=explode(message,';')
 if message=='INSTalentShow' then SendAddonMessage('peer','peer-response','GUILD');return end
 if f[1]=='INSTalentTabInfo' then
  local t=tonumber(f[2]);state[t].pointsSpent=tonumber(f[4]);state[t].numTalents=tonumber(f[5])
 elseif f[1]=='INSTalentInfo' then
  local t,i=tonumber(f[2]),tonumber(f[3]);state[t][i]={tier=tonumber(f[5]),column=tonumber(f[6]),rank=tonumber(f[7]),maximum=tonumber(f[8])}
 elseif message=='INSTalentEND;' then
  owner=targetName;TWTalentFrame:Hide();TWTalentFrame:Show()
 end
end
'''

HARNESS = r'''
local rawShow,rawMessage=InspectTalentsFrame_OnShow,InspectTalentsFrame_HandleMessage
RawNativeShow,RawNativeMessage=rawShow,rawMessage
InspectTalentsFrame_OnShow=function()
 nativeShows=nativeShows+1
 if extraSend then SendAddonMessage('OTHER','SIDE','WHISPER','SideTarget') end
 if initFailure then error('native init failed') end
 return rawShow()
end
InspectTalentsFrame_HandleMessage=function(message,sender)
 table.insert(delivered,{message,sender});return rawMessage(message,sender)
end
InspectTalentsFrame:SetScript('OnShow',function() InspectTalentsFrame_OnShow() end)
InspectFrame:SetScript('OnEvent',function()
 nativeEvents=nativeEvents+1
 if event=='PLAYER_TARGET_CHANGED' or event=='PARTY_MEMBERS_CHANGED' then nativeInspect=nativeInspect+1 end
end)
InspectFrame:SetScript('OnHide',function() InspectFrame.unit=nil end)
TWTalentFrame:SetScript('OnShow',function()
 local state,owner=NativeState()
 assert(state.class==targetClass,'native cache class does not match displayed player')
 assert(owner==targetName,'native cache owner does not match displayed player')
 for tree=1,3 do
  local total=0;assert(state[tree].numTalents==2,'native renderer received incomplete tree')
  for i=1,2 do local _,_,tier,column,rank,maximum=NativeRead(tree,i);assert(tier and column and rank and maximum);total=total+rank end
  local _,_,points=NativeTab(tree);assert(points==total,'native point total mismatch')
 end
 renders=renders+1
end)
'''


def native_chunk(path):
    if path and path.is_file():
        text = path.read_text(encoding='utf-8-sig')
        marker = 'TWTalent.TALENT_BRANCH_ARRAY = {}'
        if marker not in text:
            raise AssertionError('Unrecognized native parser boundary')
        return text.split(marker, 1)[0] + '''
function NativeState() return inspectCom.SPEC,loadedFor end
function NativeRead(t,i) return TWTalent.GetTalentInfo(t,i) end
function NativeTab(t) return TWTalent.GetTalentTabInfo(t) end
''', 'actual extracted client parser'
    return FALLBACK, 'independent native contract (no game source available)'


def world(native, enabled=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().InstallFonts = lua.execute(FONT)
    lua.execute(BASE)
    lua.execute(native)
    lua.execute(HARNESS)
    lua.execute(SOURCE.read_text(encoding='utf-8-sig'))
    if enabled:
        lua.execute('SCInspectTalents.SetEnabled(true)')
    return lua


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native', type=Path, default=NATIVE)
    parser.add_argument('--contract-only', action='store_true')
    args = parser.parse_args()
    native, mode = native_chunk(None if args.contract_only else args.native)
    print('Native compatibility mode:', mode)
    checks = 0

    def case(name, code, enabled=True):
        nonlocal checks
        lua = world(native, enabled)
        lua.execute(code)
        checks += 1
        print('PASS', name)

    case('default is inactive, allocates no update callback or text', '''
assert(not SCInspectTalents.enabled and ActiveUpdates()==0 and not SCInspectTalents.status)
''', enabled=False)
    case('font mock rejects uninitialized and failed fonts', '''
local text=NewObject('FontString',nil,nil)
assert(not pcall(function() text:SetText('invalid') end))
failedFontPaths.broken=true;assert(not text:SetFont('broken',12))
assert(not pcall(function() text:SetText('invalid') end))
text:SetFontObject(GameFontNormal);text:SetText('valid')
''')
    case('one new-protocol request, stable loading text and single temporary timer', '''
OpenTarget();assert(Requests()==1 and sends[1][1]=='TW_CHAT_MSG_WHISPER<Alpha>')
assert(sends[1][3]=='GUILD' and ActiveUpdates()==1)
local S=SCInspectTalents;local status=S.status;local n=table.getn(objects)
assert(status and status.font and status:IsVisible() and status.color[1]==.8)
S.Request();S.Open();assert(Requests()==1 and S.status==status and table.getn(objects)==n)
''')
    case('native private cache remains untouched until all three trees complete', '''
OpenTarget();Feed(Tab(1));Feed(Info(1,1));local state,owner=NativeState()
assert(state.class=='' and owner=='' and renders==0 and table.getn(delivered)==0)
Complete();state,owner=NativeState()
assert(state.class=='WARRIOR' and owner=='Alpha' and renders==1)
assert(Requests()==1 and SendAddonMessage==SavedSend and ActiveUpdates()==0)
assert(not SCInspectTalents.status:IsShown())
''')
    case('duplicate nodes are deduplicated and complete snapshot delivered once', '''
OpenTarget();Feed(Tab(1));Feed(Tab(1));Feed(Info(1,1));Feed(Info(1,1));Complete()
assert(renders==1 and table.getn(delivered)==10)
Feed('INSTalentEND;');assert(renders==1)
''')
    case('different sender cannot fill, fail or complete pending request', '''
OpenTarget();Complete('Other');assert(renders==0 and table.getn(notices)==0 and ActiveUpdates()==1)
Complete('Alpha');assert(renders==1)
''')
    case('native initializer suppresses its duplicate but forwards unrelated sends', '''
extraSend=true;OpenTarget();Complete()
assert(Requests()==1 and table.getn(sends)==2 and sends[2][1]=='OTHER')
assert(sends[2][4]=='SideTarget' and SendAddonMessage==SavedSend)
''')
    case('legitimate peer request and unrelated native messages remain forwarded', '''
Feed('INSTalentShow','Peer');assert(table.getn(sends)>0 and ActiveUpdates()==0)
Feed('OTHER_MESSAGE','Peer');assert(delivered[table.getn(delivered)][1]=='OTHER_MESSAGE')
''')
    case('END with tail fields is classified before tree index and completes native publish', '''
OpenTarget()
for tree=1,3 do Feed(Tab(tree));for i=1,2 do Feed(Info(tree,i)) end end
Feed('INSTalentEND;1;')
assert(renders==1 and SCInspectTalents.diagnostics.state=='complete' and ActiveUpdates()==0)
assert(delivered[table.getn(delivered)][1]=='INSTalentEND;')
''')
    case('END with an empty tail completes a validated three-tree snapshot', '''
OpenTarget()
for tree=1,3 do Feed(Tab(tree));for i=1,2 do Feed(Info(tree,i)) end end
Feed('INSTalentEND;;');assert(renders==1 and table.getn(notices)==0)
''')
    case('extension controls with or without tree-shaped fields cannot abort an active request', '''
OpenTarget();Feed('INSTalentExtension;1;');Feed('INSTalentExtension;no-tree;')
assert(ActiveUpdates()==1 and InspectTalentsFrame:IsShown() and table.getn(notices)==0)
local d=SCInspectTalents.diagnostics
assert(d.ignored==2 and table.getn(d.types)==1 and d.types[1]=='INSTalentExtension')
Complete();assert(renders==1 and d.tabs==3 and d.nodes==6)
''')
    case('wrong-sender extensions remain ignored without affecting session diagnostics', '''
OpenTarget();Feed('INSTalentExtension;1;','Other')
assert(SCInspectTalents.diagnostics.ignored==0 and ActiveUpdates()==1)
Complete();assert(renders==1)
''')
    case('peer requests with optional fields still use native peer response', '''
Feed('INSTalentShow;1;','Peer')
assert(table.getn(sends)>0 and ActiveUpdates()==0 and Requests()==0)
''')
    case('completed wire stream allows deliberate refresh after a short quiet period', '''
OpenTarget();Complete();control=true;clock=3;SCInspectTalents.Request()
assert(Requests()==2 and ActiveUpdates()==1)
Complete();assert(renders>=2 and SCInspectTalents.diagnostics.state=='complete' and ActiveUpdates()==0)
''')
    case('incomplete END permits retry after quiet period without full timeout lockout', '''
OpenTarget();Feed(Tab(1));Feed('INSTalentEND;1;')
assert(SCInspectTalents.diagnostics.state=='failed' and ActiveUpdates()==0)
clock=3;OpenTarget();assert(Requests()==2)
Complete();assert(renders==1)
''')
    case('drained canceled response cannot reopen UI and shortens retry wait only after END', '''
OpenTarget();InspectFrame_ShowSubFrame('InspectPaperDollFrame')
Feed('INSTalentEND;1;');assert(renders==0 and ActiveUpdates()==0)
clock=3;SCInspectTalents.Open();assert(Requests()==2)
Complete();assert(renders==1)
''')
    case('repeated cooldown clicks produce a throttled countdown instead of chat spam', '''
OpenTarget();InspectFrame_ShowSubFrame('InspectPaperDollFrame')
for i=1,8 do SCInspectTalents.Open() end
assert(Requests()==1 and table.getn(notices)==1)
clock=3;SCInspectTalents.Open();assert(table.getn(notices)==2)
''')
    case('manual diagnostics are bounded, do not query and exclude raw packet contents', '''
OpenTarget()
for i=1,20 do Feed('INSTalentExtension'..i..';1;PrivatePayload') end
local d=SCInspectTalents.diagnostics;assert(d.ignored==20 and table.getn(d.types)==6)
SCInspectTalents.ShowDiagnostics();assert(Requests()==1)
for _,line in ipairs(notices) do assert(not string.find(line,'PrivatePayload',1,true)) end
Complete();assert(renders==1)
''')
    for name, payload in [
        ('tree zero', 'INSTalentTabInfo;0;tree;3;2'),
        ('tree outside three', 'INSTalentTabInfo;4;tree;3;2'),
        ('too many talents', 'INSTalentTabInfo;1;tree;3;21'),
        ('negative points', 'INSTalentTabInfo;1;tree;-1;2'),
        ('noninteger node', 'INSTalentInfo;1;1.5;node;1;1;1;5;1;-1;-1;-1'),
        ('zero node', 'INSTalentInfo;1;0;node;1;1;1;5;1;-1;-1;-1'),
        ('tier outside layout', 'INSTalentInfo;1;1;node;9;1;1;5;1;-1;-1;-1'),
        ('column outside layout', 'INSTalentInfo;1;1;node;1;5;1;5;1;-1;-1;-1'),
        ('rank above maximum', 'INSTalentInfo;1;1;node;1;1;6;5;1;-1;-1;-1'),
        ('missing prerequisite fields', 'INSTalentInfo;1;1;node;1;1;1;5;1'),
        ('invalid prerequisite index', 'INSTalentInfo;1;1;node;1;1;1;5;1;0;-1;-1'),
        ('invalid prerequisite boolean', 'INSTalentInfo;1;1;node;1;1;1;5;no;-1;-1;-1'),
    ]:
        case('reject ' + name, f'''
OpenTarget();Feed({payload!r});assert(renders==0 and ActiveUpdates()==0 and not InspectTalentsFrame:IsShown())
local state,owner=NativeState();assert(state.class=='' and owner=='')
''')
    case('oversized packet fails without native delivery', '''
OpenTarget();Feed('INSTalentInfo;'..string.rep('x',2050))
assert(renders==0 and ActiveUpdates()==0 and table.getn(delivered)==0)
''')
    case('missing trees cannot commit cache', '''
OpenTarget();Feed(Tab(1));Feed(Info(1,1));Feed(Info(1,2));Feed('INSTalentEND;')
assert(renders==0 and ActiveUpdates()==0 and InspectFrame.selectedTab==1)
''')
    case('missing nodes cannot commit cache', '''
OpenTarget();for t=1,3 do Feed(Tab(t));Feed(Info(t,1)) end;Feed('INSTalentEND;')
assert(renders==0 and ActiveUpdates()==0)
''')
    case('points inconsistent with node ranks cannot commit cache', '''
OpenTarget();for t=1,3 do Feed(Tab(t,7));for i=1,2 do Feed(Info(t,i)) end end;Feed('INSTalentEND;')
assert(renders==0 and ActiveUpdates()==0)
''')
    case('timeout closes loading state and leaves no persistent update callback', '''
OpenTarget();Tick(SCInspectTalents.timeout+.01)
assert(renders==0 and ActiveUpdates()==0 and InspectFrame.selectedTab==1)
assert(not SCInspectTalents.status:IsShown())
Complete();assert(renders==0)
''')
    case('target event closes talent page without invoking native auto inspect', '''
OpenTarget();Complete();FireTarget('Beta','MAGE','guid-B')
assert(not InspectFrame:IsShown() and nativeInspect==0 and Requests()==1)
Complete('Alpha');assert(not InspectFrame:IsShown() and renders==1)
''')
    case('A complete then B canceled then A reopens correct native cached class', '''
OpenTarget();Complete();OpenTarget('Beta','MAGE','guid-B')
local state,owner=NativeState();assert(state.class=='WARRIOR' and owner=='Alpha')
FireTarget('Alpha','WARRIOR','guid-A');Complete('Beta')
OpenTarget();assert(Requests()==2 and renders==2)
state,owner=NativeState();assert(state.class=='WARRIOR' and owner=='Alpha')
''')
    case('changed identity without event is canceled by existing pending timer', '''
OpenTarget();targetName,targetClass,targetKey='Beta','MAGE','guid-B';Tick(.1)
assert(not InspectFrame:IsShown() and ActiveUpdates()==0 and Requests()==1)
''')
    case('closing parent drops late replies and cannot reopen talent frame', '''
OpenTarget();InspectFrame:Hide();Complete()
assert(not InspectFrame:IsShown() and renders==0 and ActiveUpdates()==0)
assert(not SCInspectTalents.status:IsShown())
''')
    case('switching to gear page drops late replies and preserves chosen page', '''
OpenTarget();PanelTemplates_SetTab(InspectFrame,1);InspectFrame_ShowSubFrame('InspectPaperDollFrame');Complete()
assert(InspectFrame:IsShown() and InspectPaperDollFrame:IsVisible() and renders==0 and ActiveUpdates()==0)
''')
    case('short cache reopens without request or new objects', '''
OpenTarget();Complete();local n=table.getn(objects)
InspectFrame_ShowSubFrame('InspectPaperDollFrame');SCInspectTalents.Open()
assert(Requests()==1 and renders==2 and table.getn(objects)==n and ActiveUpdates()==0)
''')
    case('Ctrl refresh obeys wire quarantine then requests fresh snapshot', '''
OpenTarget();Complete();control=true;SCInspectTalents.Request()
assert(Requests()==1 and TWTalentFrame:IsVisible())
Tick(SCInspectTalents.timeout+2.01);SCInspectTalents.Request();assert(Requests()==2)
Complete();assert(renders>=2 and ActiveUpdates()==0 and SendAddonMessage==SavedSend)
''')
    case('cache expiration requests again', '''
OpenTarget();Complete();Tick(SCInspectTalents.cacheTime+.01);SCInspectTalents.Request()
assert(Requests()==2 and ActiveUpdates()==1);Complete();assert(ActiveUpdates()==0)
''')
    case('canceled same-name request waits before retrying', '''
OpenTarget();InspectFrame:Hide();OpenTarget();assert(Requests()==1 and not InspectTalentsFrame:IsShown())
Tick(SCInspectTalents.timeout+2.01);SCInspectTalents.Open();assert(Requests()==2)
Complete();assert(renders==1)
''')
    case('failed send has no timer leak or native cache change', '''
sendFailure=true;OpenTarget();assert(ActiveUpdates()==0 and renders==0 and table.getn(notices)>0)
assert(SendAddonMessage==SavedSend)
''')
    case('failed native module load prevents requesting', '''
talentLoaded=false;loadFailure=true;OpenTarget();assert(Requests()==0 and ActiveUpdates()==0)
''')
    case('missing class data prevents requesting', '''
Turtle_TalentsData.WARRIOR=nil;OpenTarget();assert(Requests()==0 and ActiveUpdates()==0)
''')
    case('invalid target prevents requesting', '''
targetInspectable=false;OpenTarget();assert(Requests()==0 and ActiveUpdates()==0)
''')
    case('native initializer exception restores sender and closes safely', '''
initFailure=true;extraSend=true;OpenTarget();Complete()
assert(SendAddonMessage==SavedSend and Requests()==1 and renders==0 and ActiveUpdates()==0)
assert(sends[2][1]=='OTHER')
''')
    case('repeated enabling is idempotent and disabling restores owned hooks', '''
local S=SCInspectTalents
for i=1,5 do
 local show=InspectTalentsFrame_OnShow;S.SetEnabled(true);assert(show==InspectTalentsFrame_OnShow)
 S.SetEnabled(false);assert(not S.enabled and ActiveUpdates()==0)
 S.SetEnabled(true)
end
OpenTarget();Complete();assert(Requests()==1 and renders==1)
''')
    case('later third-party hooks remain installed and disabled wrappers forward', '''
local oldShow,oldMessage,oldOpen=InspectTalentsFrame_OnShow,InspectTalentsFrame_HandleMessage,InspectFrameTalentsTab_OnClick
local oldEvent=InspectFrame:GetScript('OnEvent');local showCalls,messageCalls,openCalls,eventCalls=0,0,0,0
local thirdShow=function() showCalls=showCalls+1;return oldShow() end
local thirdMessage=function(...) messageCalls=messageCalls+1;return oldMessage(...) end
local thirdOpen=function() openCalls=openCalls+1;return oldOpen() end
local thirdEvent=function() eventCalls=eventCalls+1;return oldEvent() end
InspectTalentsFrame_OnShow=thirdShow;InspectTalentsFrame_HandleMessage=thirdMessage;InspectFrameTalentsTab_OnClick=thirdOpen
InspectFrame:SetScript('OnEvent',thirdEvent)
SCInspectTalents.SetEnabled(false)
assert(InspectTalentsFrame_OnShow==thirdShow and InspectTalentsFrame_HandleMessage==thirdMessage)
assert(InspectFrameTalentsTab_OnClick==thirdOpen and InspectFrame:GetScript('OnEvent')==thirdEvent)
Feed('OTHER','Other');InspectFrameTalentsTab_OnClick()
assert(messageCalls==1 and openCalls==1 and ActiveUpdates()==0)
InspectFrame.unit='target';InspectFrame:Show();InspectTalentsFrame:Show()
assert(showCalls==1 and nativeShows==1 and Requests()==1)
FireTarget('Alpha','WARRIOR','guid-A')
assert(eventCalls==1 and nativeEvents==1 and nativeInspect==1)
SCInspectTalents.SetEnabled(true);OpenTarget();Complete();assert(Requests()==2 and renders==1)
''')
    source = (ROOT / 'Interface/AddOns/StatCompare/StatCompare.lua').read_text(encoding='utf-8-sig')
    skin = (ROOT / 'Interface/AddOns/pfUI/skins/blizzard/inspect.lua').read_text(encoding='utf-8-sig')
    assert 'INSShowTalents' not in source and 'Ins_Init()' not in source
    assert 'INSPECTFRAME_SUBFRAMES = { "InspectPaperDollFrame", "InspectHonorFrame", "InspectTalentsFrame" }' not in source
    assert 'CreateFrame(\'Button\', \'InspectFrameTab3\'' not in source
    assert 'hooksecurefunc("InspectUnit"' not in skin
    print('PASS real integration preserves four native tabs and removes pfUI auto-request hook')
    checks += 1
    compiler = ROOT / 'PluginHistory/staging/lua503-validation/win64/luac50.exe'
    if not compiler.is_file():
        raise AssertionError('Actual Lua 5.0 compiler unavailable')
    result = subprocess.run([str(compiler), '-p', str(SOURCE)], capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    print(f'{checks} behavior groups passed; actual Lua 5.0 syntax passed. Live game QA still required.')


if __name__ == '__main__':
    main()
