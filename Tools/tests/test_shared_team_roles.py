"""Actual shared service offline checks. Does not establish server or live UI QA."""
from pathlib import Path
import sys
import unittest

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
LIB=ROOT/'Interface/AddOns/!Libs'
SERVICE=(LIB/'SC_TeamRoleService.lua').read_text(encoding='utf-8-sig')


def world():
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
now=0;sends={};frames={};nativeCalls={};identityReads=0
UNKNOWNOBJECT='Unknown';UNKNOWN='Unknown'
units={player={name='Self',class='MAGE',guid='self'},
 party1={name='Tank',class='WARRIOR',guid='one'},
 party2={name='Heal',class='PRIEST',guid='two'}}
partyCount=2;raidCount=0
function GetTime() return now end
function GetRealmName() return 'Realm' end
function GetNumPartyMembers() return partyCount end
function GetNumRaidMembers() return raidCount end
function UnitExists(u) identityReads=identityReads+1;return units[u]~=nil,units[u] and units[u].guid end
function UnitName(u) return units[u] and units[u].name end
function UnitClass(u) return units[u] and units[u].class,units[u] and units[u].class end
function UnitIsUnit(a,b) return units[a] and units[a]==units[b] end
function UnitIsConnected(u) return units[u] and not units[u].offline end
function UnitIsPlayer(u) return units[u]~=nil end
function SendAddonMessage(p,b,c) table.insert(sends,{p,b,c}) end
function InspectTalentsFrame_HandleMessage(b,s) table.insert(nativeCalls,{b,s}) end
function CreateFrame()
 local f={events={},scripts={}}
 function f:SetScript(k,v) self.scripts[k]=v end
 function f:RegisterEvent(e) self.events[e]=true end
 function f:UnregisterEvent(e) self.events[e]=nil end
 table.insert(frames,f);return f
end
''')
    for name in ('SC_TeamRoleData.lua','SC_TeamRoles.lua','SC_TeamRoleService.lua'):
        lua.execute((LIB/name).read_text(encoding='utf-8-sig'))
    lua.execute('''
S=SC_TeamRolesService
function Tick(t) now=t;S:Tick() end
function Packet(body,sender) S:Packet('TW_CHAT_MSG_WHISPER',body,'WHISPER',sender or 'Tank') end
function Reply(sender,class,ranks,framing)
 local data=SC_TeamRoleData[class];ranks=ranks or {}
 for tree=1,3 do
  local points=0
  for i=1,table.getn(data[tree]) do points=points+(ranks[tree..':'..i] or 0) end
  Packet((framing or '')..'INSTalentTabInfo;'..tree..';Tree;'..points..';'..table.getn(data[tree]),sender)
  for i,d in ipairs(data[tree]) do
   Packet((framing or '')..'INSTalentInfo;'..tree..';'..i..';Node;'..d[2]..';'..d[3]..';'..(ranks[tree..':'..i] or 0)..';'..d[1]..';0;-1;-1;-1',sender)
  end
 end
 Packet((framing or '')..'INSTalentEND;extra;',sender)
end
function Fill(class,tree,points,required)
 local ranks=required or {};local spent=0
 for _,v in pairs(ranks) do spent=spent+v end
 for i,d in ipairs(SC_TeamRoleData[class][tree]) do
  local k=tree..':'..i;local n=math.min(d[1]-(ranks[k] or 0),points-spent)
  ranks[k]=(ranks[k] or 0)+n;spent=spent+n
 end
 assert(spent==points);return ranks
end
''')
    return lua


class SharedRolesTests(unittest.TestCase):
    def test_no_consumer_has_no_driver_or_packets_and_loads_once(self):
        lua=world()
        lua.execute("assert(not frames[1].scripts.OnUpdate and table.getn(sends)==0);old=S")
        lua.execute(SERVICE)
        lua.execute("assert(old==SC_TeamRolesService and table.getn(frames)==1)")

    def test_single_pending_merges_subscribers_and_validates_tab_prefix(self):
        world().execute('''
local a,b=0,0
S:Acquire('healing')
S:Request('party1','inspect',function(r,e) assert(r and not e);a=a+1 end,false,100)
S:Request('party1','manager',function(r,e) assert(r and not e);b=b+1 end,false,100)
Tick(0);assert(table.getn(sends)==1)
Tick(2);assert(table.getn(sends)==1)
Packet('INSTalentControl;v2;')
Reply('Tank','WARRIOR',Fill('WARRIOR',3,31,{['3:14']=1}),'\t')
assert(a==1 and b==1 and S:GetRole('party1')=='TANK')
assert(SC_TeamRoles:IsTank('party1')==true)
assert(S:GetInfo('party1').tabs[3].points==31)
''')

    def test_incomplete_or_conflicting_packets_never_publish(self):
        world().execute('''
local result,reason
S:Request('party1','inspect',function(r,e) result=r;reason=e end)
Tick(0);Packet('INSTalentTabInfo;1;Tree;0;18');Packet('INSTalentEND;')
assert(result==nil and reason and S:GetRole('party1')==nil)
''')

    def test_identity_change_rejects_old_sender_and_drops_manual_roles(self):
        world().execute('''
S:Acquire('healing');S:SetOverride('party1','TANK','MELEE');assert(S:GetRole('party1')=='TANK')
S:Request('party1','inspect',function()error('must not publish')end,true,100)
Tick(0);units.party1={name='Other',class='MAGE',guid='new'}
S:OnEvent('PARTY_MEMBERS_CHANGED')
assert(S:GetInfo('Tank')==nil and S:GetRole('party1')==nil)
Reply('Tank','WARRIOR');assert(S:GetRole('party1')==nil)
''')

    def test_timeout_skips_member_and_circuit_is_bounded(self):
        world().execute('''
S:Acquire('healing');S:Request('party1','inspect',function(r,e)assert(r==nil and e=='timeout')end,false,100)
Tick(0);Tick(12);assert(S:GetDiagnostics().timeouts==1)
assert(S:GetInfo('party1').queryState=='timeout')
Tick(14);assert(table.getn(sends)>=2)
''')

    def test_manual_cache_reuse_and_force_isolation(self):
        world().execute('''
local count=0;S:Request('party1','inspect',function()count=count+1 end)
Tick(0);Reply('Tank','WARRIOR');assert(count==1)
S:Request('party1','inspect',function()count=count+1 end);assert(count==2 and table.getn(sends)==1)
local ok=S:Request('party1','inspect',function(r,e)assert(not r and e)end,true)
assert(not ok)
''')

    def test_canceled_inspect_does_not_cancel_other_subscriber_or_open_native_ui(self):
        world().execute('''
local a,b=0,0
S:Request('party1','inspect',function()a=a+1 end)
S:Request('party1','healing',function()b=b+1 end)
Tick(0);S:Cancel('inspect')
InspectTalentsFrame_HandleMessage('INSTalentInfo;garbage','Tank')
assert(table.getn(nativeCalls)==0)
Reply('Tank','WARRIOR');assert(a==0 and b==1)
InspectTalentsFrame_HandleMessage('INSTalentEND;','Tank');assert(table.getn(nativeCalls)==0)
InspectTalentsFrame_HandleMessage('INSTalentShow','Other');assert(table.getn(nativeCalls)==1)
S:GetNativeMessageHandler()('INSTalentEND;','Tank');assert(table.getn(nativeCalls)==2)
''')

    def test_combat_pauses_new_requests_keeps_valid_snapshot_then_expires(self):
        world().execute('''
S:Request('party1','inspect',function()end);Tick(0)
Reply('Tank','WARRIOR',Fill('WARRIOR',3,31,{['3:14']=1}))
now=10;S:OnEvent('PLAYER_REGEN_DISABLED')
local count=table.getn(sends);Tick(400);assert(table.getn(sends)==count)
assert(S:GetRole('party1')=='TANK')
S:OnEvent('PLAYER_REGEN_ENABLED');assert(S:GetRole('party1')==nil)
''')

    def test_repeated_acquire_and_peek_do_not_poll_unit_apis(self):
        world().execute('''
S:Acquire('healing');local n=identityReads
for i=1,100 do S:Acquire('healing');S:Peek('Tank','one','WARRIOR') end
assert(identityReads==n)
S:Release('healing');assert(frames[1].scripts.OnUpdate==nil)
''')

    def test_ambiguous_talents_do_not_become_confirmed_tanks_or_non_tanks(self):
        world().execute('''
units.party1.class='DRUID'
S:Request('party1','inspect',function()end);Tick(0)
Reply('Tank','DRUID',Fill('DRUID',2,31))
local rec=S:GetInfo('party1');assert(rec.style=='MELEE' and rec.provisional)
assert(S:GetRole('party1')==nil and SC_TeamRoles:IsTank('party1')==nil)
S:SetOverride('party1','TANK','MELEE');S:SetTankOrder('party1',1)
assert(S:GetRole('party1')=='TANK' and SC_TeamRoles:GetTankOrder('party1')==1)
S:SetOverride('party1',nil);assert(S:GetRole('party1')==nil)
''')

    def test_oversize_invalid_and_spoofed_packets_are_rejected(self):
        world().execute('''
S:Request('party1','inspect',function()end);Tick(0)
Packet('INSTalentEND;','Wrong');assert(S:GetDiagnostics().pending)
Packet('INSTalentInfo;'..string.rep('x',2100))
assert(not S:GetDiagnostics().pending and S:GetRole('party1')==nil)
''')

    def test_all_canonical_classes_and_melee_ranged_dimension(self):
        world().execute('''
local expected={MAGE='RANGED',WARLOCK='RANGED',ROGUE='MELEE',HUNTER='RANGED',
 WARRIOR='MELEE',PALADIN='MELEE',SHAMAN='RANGED',DRUID='RANGED',PRIEST='RANGED'}
local trees={MAGE=1,WARLOCK=1,ROGUE=1,HUNTER=2,WARRIOR=1,PALADIN=3,SHAMAN=1,DRUID=1,PRIEST=3}
for class,style in pairs(expected) do
 units.party1={name=class,class=class,guid=class};S:OnEvent('PARTY_MEMBERS_CHANGED')
 local ranks=Fill(class,trees[class],31,class=='PRIEST' and {['3:17']=1} or nil)
 S:Request('party1','inspect',function()end);Tick(now+2)
 Reply(class,class,ranks)
 local r=S:GetInfo('party1');assert(r.role=='DAMAGER' and r.style==style,class)
 assert(S:GetRole('party1')=='DAMAGER',class)
end
''')

    def test_offline_member_recovers_on_connection_event(self):
        world().execute('''
units.party1.offline=true;S:Request('party1','inspect',function(r,e)assert(not r and e=='offline')end)
Tick(0);assert(table.getn(sends)==0)
units.party1.offline=false;S:Acquire('healing');S:OnEvent('UNIT_CONNECTION','party1');Tick(2)
Tick(4);assert(table.getn(sends)>=1)
''')

    def test_idle_cache_expiry_sweep_has_no_unit_api_polling(self):
        world().execute('''
S:Acquire('healing')
for _,u in ipairs({'party1','party2'}) do S:SetOverride(u,'DAMAGER','RANGED') end
Tick(0);Tick(2);local n=identityReads
for i=1,100 do Tick(2+i*.04) end
assert(identityReads==n)
''')

    def test_repeated_observe_target_replacement_keeps_queue_bounded(self):
        world().execute('''
for i=1,100 do
 units.target={name='Target'..i,class='MAGE',guid='target'..i}
 S:Request('target','inspect',function()end)
end
assert(S:GetDiagnostics().queued<=1)
Tick(0);assert(table.getn(sends)==1 and sends[1][1]=='TW_CHAT_MSG_WHISPER<Target100>')
''')

    def test_read_self_failure_finishes_callback_instead_of_hanging(self):
        world().execute('''
local done=false
S:Request('player','inspect',function(r,e) assert(not r and e=='unavailable');done=true end)
Tick(0);assert(done and not S:GetDiagnostics().pending)
''')

    def test_extension_diagnostics_are_bounded_and_keep_no_payload(self):
        world().execute('''
S:Request('party1','inspect',function()end);Tick(0)
for i=1,20 do Packet('INSTalentExtension'..i..';PrivatePayload;') end
local d=S:GetDiagnostics();assert(d.ignored==20 and table.getn(d.types)==6)
for _,v in ipairs(d.types) do assert(not string.find(v,'PrivatePayload',1,true)) end
''')

    def test_three_failures_pause_queue_then_allow_later_work(self):
        world().execute('''
partyCount=4
units.party3={name='Three',class='MAGE',guid='three'}
units.party4={name='Four',class='MAGE',guid='four'}
for i=1,4 do S:Request('party'..i,'owner'..i,function()end) end
Tick(0);Tick(12);Tick(24);Tick(36)
assert(table.getn(sends)==3 and S:GetDiagnostics().state=='paused')
Tick(40);assert(table.getn(sends)==3)
Tick(97);assert(table.getn(sends)==4)
''')

    def test_reinstalling_native_guard_preserves_original_handler_without_recursion(self):
        world().execute('''
S:EnsureNativeGuard();local raw=S:GetNativeMessageHandler()
local previous=InspectTalentsFrame_HandleMessage
InspectTalentsFrame_HandleMessage=function(a,b) return previous(a,b) end
S:EnsureNativeGuard();S:EnsureNativeGuard()
InspectTalentsFrame_HandleMessage('OtherMessage','Other')
assert(table.getn(nativeCalls)==1 and S:GetNativeMessageHandler()==raw)
''')

    def test_leaving_group_clears_self_override_before_next_team(self):
        world().execute('''
S:Acquire('healing');S:SetOverride('player','TANK','MELEE');S:SetTankOrder('player',1)
assert(S:GetRole('player')=='TANK')
partyCount=0;S:OnEvent('PARTY_MEMBERS_CHANGED')
assert(S:GetInfo('player').overrideRole==nil and S:GetRole('player')==nil)
partyCount=2;S:OnEvent('PARTY_MEMBERS_CHANGED')
assert(S:GetInfo('player').overrideRole==nil)
''')


if __name__=='__main__':
    unittest.main(verbosity=2)
