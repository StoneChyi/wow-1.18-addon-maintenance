"""Real outgoing invitation policies with a strict legacy client boundary.
Offline event simulation only; no messages or invitations are sent to a server.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil
format=string.format;tinsert=table.insert;foreachi=table.foreachi
now=10;party=0;raid=0;leader=false;rank=0;zone='暴风城'
sent={};promoted={};kicked={};converted=0;friends={};guild={};ignores={}
Automaton={modules={},dbs={}}
function Automaton:NewModule(name)
 local m={name=name,events={}};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(name,handler)self.events[name]=handler or name end
 function m:UnregisterAllEvents()self.events={} end
 function m:print()end
 return m
end
function Automaton:AcquireDBNamespace(name)
 self.dbs[name]=self.dbs[name] or {profile={}}
 return self.dbs[name]
end
function Automaton:RegisterDefaults(name,scope,defaults)
 local target=self.dbs[name][scope]
 for key,value in pairs(defaults)do if target[key]==nil then target[key]=value end end
end
function Automaton:SetDisabledAsDefault()end
function Automaton:IsModuleActive(name)return self.active and self.active[name] or false end
function AceLibrary()
 return {new=function()return setmetatable({RegisterTranslations=function(self,locale,fn)
  for key,value in pairs(fn())do self[key]=value end
 end},{__index=function(_,key)return key end})end}
end
function CreateFrame()return {SetScript=function(self,event,fn)self[event]=fn end}end
function GetTime()return now end
function GetNumPartyMembers()return party end
function GetNumRaidMembers()return raid end
function UnitIsPartyLeader()return leader end
function UnitInRaid()return raid>0 end
function UnitName(unit)if unit=='player'then return 'Self' end;return units and units[unit]end
function UnitExists(unit)return units and units[unit]~=nil end
function GetRaidRosterInfo(index)if index==1 then return 'Self',rank else return 'Member'..index,0 end end
function InviteByName(name)table.insert(sent,name)end
function ConvertToRaid()converted=converted+1 end
function GetZoneText()return zone end
function PromoteToAssistant(name)table.insert(promoted,name)end
function GetRealmName()return 'TestRealm'end
function GetNumIgnores()return #ignores end
function GetIgnoreName(index)return ignores[index]end
function UninviteByName(name)table.insert(kicked,name)end
function GuildRoster()end
function GetNumGuildMembers()return #guild end
function GetGuildRosterInfo(index)return guild[index]end
function GetNumFriends()return #friends end
function GetFriendInfo(index)return friends[index]end
function dispatch(m,event,text,from)
 local handler=m.events[event]
 if not handler then return end
 arg1,arg2=text,from
 if type(handler)=='string'then m[handler](m,text,from)else handler(text,from)end
end
'''


def runtime(saved=""):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    if saved: lua.execute(saved)
    for file in ("Invite.lua", "1invall.lua"):
        lua.execute((ROOT / "Interface/AddOns/Automatonex/Modules" / file).read_text(encoding="utf-8-sig"))
    lua.execute("I=Automaton.modules.Invite;N=Automaton.modules.invall;I:OnInitialize();N:OnInitialize();I:OnEnable();N:OnEnable()")
    return lua


class OutgoingInvites(unittest.TestCase):
    def test_both_module_event_orders_send_once(self):
        lua=runtime()
        lua.execute(r'''
I.db.profile.anyone=true
for _,first in ipairs({'I','N'})do
 sent={};now=now+2
 if first=='I'then dispatch(I,'CHAT_MSG_WHISPER','invite','Other');dispatch(N,'CHAT_MSG_WHISPER','invite','Other')
 else dispatch(N,'CHAT_MSG_WHISPER','invite','Other');dispatch(I,'CHAT_MSG_WHISPER','invite','Other')end
 assert(#sent==1 and sent[1]=='Other')
end
now=now+2;dispatch(I,'CHAT_MSG_WHISPER','invite','Other');assert(#sent==2)
''')

    def test_keyword_filters_and_custom_case_preserved(self):
        lua=runtime()
        lua.execute(r'''
I.db.profile.friends=false;I.db.profile.guild=false
I:AddCustomName('Allowed')
dispatch(I,'CHAT_MSG_WHISPER','INVITE','Allowed');assert(#sent==1)
dispatch(I,'CHAT_MSG_WHISPER','invite','Outsider');assert(#sent==1)
I.db.profile.ignoreCase=false;now=now+2
dispatch(I,'CHAT_MSG_WHISPER','INVITE','Allowed');assert(#sent==1)
dispatch(I,'CHAT_MSG_GUILD','invite','Allowed');assert(#sent==1)
I.db.profile.isguild=true;dispatch(I,'CHAT_MSG_GUILD','invite','Allowed');assert(#sent==2)
I.db.profile.inviteString='[';dispatch(I,'CHAT_MSG_WHISPER','invite','Allowed');assert(#sent==2)
I.db.profile.inviteString='join%d';dispatch(I,'CHAT_MSG_WHISPER','join3','Allowed');now=now+2
dispatch(I,'CHAT_MSG_WHISPER','join3','Allowed');assert(#sent==3)
I:RemoveCustomName('Allowed');now=now+2;dispatch(I,'CHAT_MSG_WHISPER','join3','Allowed');assert(#sent==3)
I.db.profile.guild=true;guild={'Guildie'};dispatch(I,'CHAT_MSG_WHISPER','join3','Guildie');assert(#sent==4)
I.db.profile.friends=true;friends={'Friend'};dispatch(I,'CHAT_MSG_WHISPER','join3','Friend');assert(#sent==5)
''')

    def test_authority_capacity_and_conversion_policy(self):
        lua=runtime()
        lua.execute(r'''
I.db.profile.anyone=true
party=1;leader=false
dispatch(I,'CHAT_MSG_WHISPER','invite','Other');dispatch(N,'CHAT_MSG_SAY','inv','Other');assert(#sent==0)
leader=true;party=4;I.db.profile.autoRaid=false
dispatch(I,'CHAT_MSG_WHISPER','invite','Other');dispatch(N,'CHAT_MSG_SAY','inv','Other');assert(#sent==0 and converted==0)
I.db.profile.autoRaid=true;I.db.profile.anyone=false;I.db.profile.guild=false;I.db.profile.friends=false
dispatch(I,'CHAT_MSG_WHISPER','invite','Other');assert(#sent==0 and converted==0,'rejected sender converted party')
I.db.profile.anyone=true
dispatch(I,'CHAT_MSG_WHISPER','invite','Other');dispatch(N,'CHAT_MSG_WHISPER','invite','Other')
assert(#sent==1 and converted==1)
raid=10;party=0;leader=false;rank=0;now=now+2
dispatch(N,'CHAT_MSG_SAY','inv','Other');assert(#sent==1)
rank=1;dispatch(N,'CHAT_MSG_SAY','inv','Other');assert(#sent==2)
raid=40;now=now+2;dispatch(I,'CHAT_MSG_WHISPER','invite','Other');dispatch(N,'CHAT_MSG_YELL','inv','Other');assert(#sent==2)
raid=0;party=0;now=now+2;dispatch(N,'CHAT_MSG_SAY','inv','Self');assert(#sent==2)
''')

    def test_blacklist_and_shutdown_remain_independent(self):
        lua=runtime()
        lua.execute(r'''
leader=true;party=2;units={party1='Banned',party2='Ignored'}
SI_Global={DataByRealm={TestRealm={BannedPlayers={{'Banned'}}}}};ignores={'Ignored'}
I:DoKickCheck();assert(#kicked==2)
I:OnDisable();assert(not I.kickFrame.OnUpdate and not next(I.events))
dispatch(N,'CHAT_MSG_SAY','inv','Allowed');assert(#sent==1,'disabling Invite disabled invall')
N:OnDisable();assert(not next(N.events))
''')


    def test_invall_channel_and_zone_switches(self):
        lua=runtime()
        lua.execute(r'''
I:OnDisable()
assert(N.zone=='暴风城' and N.events.ZONE_CHANGED_NEW_AREA and not N.events.ZONE_CHANGED_NEW_ARE)
dispatch(N,'CHAT_MSG_SAY','求组','One');assert(#sent==1,'legacy all-zone behavior changed')
N._options.say.set(false);dispatch(N,'CHAT_MSG_SAY','inv','Two');assert(#sent==1)
dispatch(N,'CHAT_MSG_YELL','INV','Two');assert(#sent==2)
N._options.yell.set(false);dispatch(N,'CHAT_MSG_YELL','inv','Three');assert(#sent==2)
dispatch(N,'CHAT_MSG_WHISPER','invite','Three');assert(#sent==3)
N._options.whisper.set(false);dispatch(N,'CHAT_MSG_WHISPER','inv','Four');assert(#sent==3)
N._options.say.set(true);N._options.onlyWinterVeil.set(true)
dispatch(N,'CHAT_MSG_SAY','inv','Four');assert(#sent==3)
zone='冬幕谷';dispatch(N,'ZONE_CHANGED_NEW_AREA')
dispatch(N,'CHAT_MSG_SAY','inv','Four');assert(#sent==4)
zone='暴风城';dispatch(N,'ZONE_CHANGED_NEW_AREA')
dispatch(N,'CHAT_MSG_SAY','inv','Five');assert(#sent==4)
''')

    def test_invite_policy_cannot_be_bypassed_by_invall_whisper(self):
        lua=runtime()
        lua.execute(r'''
I.db.profile.friends=false;I.db.profile.guild=false
for _,first in ipairs({'I','N'})do
 if first=='I'then dispatch(I,'CHAT_MSG_WHISPER','invite','Stranger');dispatch(N,'CHAT_MSG_WHISPER','invite','Stranger')
 else dispatch(N,'CHAT_MSG_WHISPER','invite','Stranger');dispatch(I,'CHAT_MSG_WHISPER','invite','Stranger')end
end
assert(#sent==0)
I.db.profile.anyone=true;ignores={'Banned'}
dispatch(N,'CHAT_MSG_WHISPER','inv','Banned');dispatch(I,'CHAT_MSG_WHISPER','invite','Banned');assert(#sent==0)
I:OnDisable();dispatch(N,'CHAT_MSG_WHISPER','invite','Stranger');assert(#sent==1)
I:OnEnable();now=now+2;I.db.profile.anyone=false
dispatch(N,'CHAT_MSG_WHISPER','invite','Stranger');assert(#sent==1)
''')

    def test_assistant_promotion_is_explicit_and_leader_only(self):
        lua=runtime()
        lua.execute(r'''
assert(N.db.profile.promoteAssistant==true)
raid=10;rank=1;dispatch(N,'CHAT_MSG_SYSTEM','Other加入了团队');assert(#promoted==0)
rank=2;dispatch(N,'CHAT_MSG_SYSTEM','Other加入了团队');assert(#promoted==1)
N._options.promoteAssistant.set(false);dispatch(N,'CHAT_MSG_SYSTEM','Next加入了团队');assert(#promoted==1)
N._options.promoteAssistant.set(true);dispatch(N,'CHAT_MSG_SYSTEM','Self加入了团队');assert(#promoted==1)
raid=0;dispatch(N,'CHAT_MSG_SYSTEM','Next加入了团队');assert(#promoted==1)
N:OnDisable();raid=10;dispatch(N,'CHAT_MSG_SYSTEM','Next加入了团队');assert(#promoted==1)
''')

    def test_existing_preferences_survive_initialization(self):
        lua=runtime("Automaton.dbs.invall={profile={disabled=false,say=false,yell=true,whisper=false,onlyWinterVeil=true,promoteAssistant=false,customUnknown='keep'}}; Automaton.dbs.Invite={profile={inviteString='team',ignoreCase=false,anyone=true,autoRaid=false,kickBlacklist=false,custom={'Existing'}}}")
        lua.execute(r'''
assert(N.db.profile.say==false and N.db.profile.whisper==false and N.db.profile.yell==true)
assert(N.db.profile.onlyWinterVeil and N.db.profile.promoteAssistant==false and N.db.profile.customUnknown=='keep')
assert(N.db.profile.disabled==false and I.db.profile.inviteString=='team' and I.db.profile.custom[1]=='Existing')
assert(I.db.profile.autoRaid==false and I.db.profile.kickBlacklist==false)
''')

    def test_bad_event_payload_and_duplicate_cache_expiration(self):
        lua=runtime()
        lua.execute(r'''
I.db.profile.anyone=true
dispatch(I,'CHAT_MSG_WHISPER',nil,nil);dispatch(N,'CHAT_MSG_SAY',nil,nil)
dispatch(N,'CHAT_MSG_SYSTEM',nil);assert(#sent==0)
for i=1,20 do dispatch(N,'CHAT_MSG_SAY','inv','Player'..i)end
assert(#sent==20)
now=now+2;dispatch(N,'CHAT_MSG_SAY','inv','Fresh')
local count=0;for _ in pairs(Automaton.outgoingInvites.pending)do count=count+1 end
assert(count==1,'expired sender records leaked')
''')


    def test_runtime_policy_tracks_lifecycle_before_core_saved_flags(self):
        lua=runtime()
        lua.execute(r'''
Automaton.active={Invite=false}
I.db.profile.anyone=true;ignores={'Banned'}
assert(I.outgoingEnabled and not Automaton:IsModuleActive('Invite'))
dispatch(N,'CHAT_MSG_WHISPER','inv','Banned');assert(#sent==0,'OnEnable saw stale inactive core state')
Automaton.active.Invite=true;I:OnDisable()
assert(Automaton:IsModuleActive('Invite') and not I.outgoingEnabled)
dispatch(N,'CHAT_MSG_WHISPER','inv','Banned');assert(#sent==1,'OnDisable retained stale blacklist policy')
Automaton.active.Invite=false;I:OnEnable();now=now+2
dispatch(N,'CHAT_MSG_WHISPER','inv','Banned');assert(#sent==1)
''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
