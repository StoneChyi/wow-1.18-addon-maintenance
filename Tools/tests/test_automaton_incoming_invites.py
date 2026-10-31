"""Incoming invite broker: real Group/Loner and the local AceEvent scheduler.

Offline only. Client actions are recorded; no actual invitations are processed.
The original saved namespaces remain in memory and no WTF files are accessed.
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
SlashCmdList={};now=10;friends={};guild={};party=0;raid=0
actions={};queries={};messages={};frames={};moduleOrder={}
STATICPOPUP_NUMDIALOGS=4;PARTY_INVITE='%s invites you to a group.'
function GetTime()return now end
function GetNumFriends()return #friends end
function GetFriendInfo(i)return friends[i]end
function GetNumGuildMembers()return #guild end
function GetGuildRosterInfo(i)return guild[i]end
function GuildRoster()end
function GetNumPartyMembers()return party end
function GetNumRaidMembers()return raid end
function UnitName(unit)if unit=='player'then return 'Self'end end
function SendWho(query)table.insert(queries,query)end
function CreateFrame(kind,name,parent)
 local f={events={},scripts={},name=name,shown=false}
 function f:RegisterEvent(event)self.events[event]=true end
 function f:UnregisterEvent(event)self.events[event]=nil end
 function f:UnregisterAllEvents()self.events={}end
 function f:SetScript(event,fn)self.scripts[event]=fn end
 function f:GetScript(event)return self.scripts[event]end
 function f:GetName()return self.name end
 function f:IsShown()return self.shown end
 function f:IsVisible()return self.shown end
 function f:Show()self.shown=true end
 function f:Hide()
  local was=self.shown;self.shown=false
  if was and self.scripts.OnHide then local old=this;this=self;self.scripts.OnHide();this=old end
 end
 table.insert(frames,f);if name then _G[name]=f end;return f
end
for i=1,4 do
 local name='StaticPopup'..i
 CreateFrame('Frame',name)
 _G[name..'Text']={GetText=function(self)return self.text or ''end,SetText=function(self,text)self.text=text end}
end
function StaticPopup_FindVisible(which)
 for i=1,4 do local f=_G['StaticPopup'..i];if f.which==which and f:IsShown()then return f end end
end
function StaticPopup_Hide(which)
 for i=1,4 do local f=_G['StaticPopup'..i];if f.which==which then f:Hide()end end
end
function StaticPopup_Show(which,name)
 local f=StaticPopup1;f.which=which
 StaticPopup1Text:SetText(string.format(PARTY_INVITE,name or ''))
 f:Show()
 -- Legacy client may return no frame, and invitation identity is not .data.
 return nil
end
function AcceptGroup(...)
 table.insert(actions,'accept');if not responseKeepsPopup then StaticPopup_Hide('PARTY_INVITE')end
 return 'accept-result',nil,'tail'
end
function DeclineGroup(...)
 table.insert(actions,'decline');if not responseKeepsPopup then StaticPopup_Hide('PARTY_INVITE')end
 return 'decline-result',nil,'tail'
end
function DeclineGuild()table.insert(actions,'guild-decline')end
function ClosePetition()table.insert(actions,'petition-close')end
StaticPopupDialogs={PARTY_INVITE={text=PARTY_INVITE,
 OnAccept=function()return AcceptGroup()end,OnCancel=function()return DeclineGroup()end}}
function hooksecurefunc(first,second,third)
 local owner,key,hook=_G,first,second
 if type(first)=='table'then owner,key,hook=first,second,third end
 local original=owner[key]
 assert(type(original)=='function' and type(hook)=='function')
 owner[key]=function(...)
  local result={original(...)};hook(...);return unpack(result,1,3)
 end
end
Automaton={modules={},dbs={}}
function Automaton:AcquireDBNamespace(name)
 self.dbs[name]=self.dbs[name] or {profile={}};return self.dbs[name]
end
function Automaton:RegisterDefaults(name,scope,defaults)
 local target=self:AcquireDBNamespace(name)[scope]
 for k,v in pairs(defaults)do if target[k]==nil then target[k]=v end end
end
function Automaton:SetDisabledAsDefault()end
function Automaton:IsModuleActive(name)
 local m=type(name)=='table'and name or self.modules[name]
 return m and m.savedActive or false
end
function Automaton:NewModule(name)
 local m={name=name,events={},savedActive=false};self.modules[name]=m;table.insert(moduleOrder,m)
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(event,handler)self.events[event]=handler or event end
 function m:UnregisterEvent(event)self.events[event]=nil end
 function m:UnregisterAllEvents()self.events={}end
 function m:IsActive()return self.savedActive end
 function m:ToggleActive(enabled)setActive(self,enabled)end
 function m:Debug()end
 function m:print(text)table.insert(messages,text)end
 m.Print=m.print
 return m
end
function AceLibrary()
 return {new=function()return setmetatable({RegisterTranslations=function(self,locale,fn)
  for k,v in pairs(fn())do self[k]=v end
 end},{__index=function(_,k)return k end})end}
end
function setActive(m,enabled)
 if m.savedActive==enabled then return end
 -- Core.lua writes the character saved flag AFTER the real lifecycle call.
 if enabled then m:OnEnable()
 else
  for id,task in pairs(AceScheduler.delayRegistry or {})do
   if task.self==m then m:CancelScheduledEvent(id)end
  end
  m:UnregisterAllEvents();m:OnDisable()
 end
 m.savedActive=enabled
end
function dispatch(eventName,arg,reverse)
 local oldEvent,oldArg,oldThis=event,arg1,this;event=eventName;arg1=arg
 for _,frame in ipairs(frames)do
  if frame.events[eventName]and frame.scripts.OnEvent then this=frame;frame.scripts.OnEvent()end
 end
 for n=1,#moduleOrder do
  local m=moduleOrder[reverse and #moduleOrder-n+1 or n]
  local handler=m.events[eventName]
  if handler then
   if type(handler)=='string'then m[handler](m,arg)else handler(arg)end
  end
 end
 event,arg1,this=oldEvent,oldArg,oldThis
end
function request(name,reverse)
 lastRequestTime=now
 StaticPopup_Show('PARTY_INVITE',name);dispatch('PARTY_INVITE_REQUEST',name,reverse)
 advance(.05)
end
function advance(seconds)
 now=now+seconds;local guard=0
 while true do
  local nextId,nextTask
  for id,task in pairs(AceScheduler.delayRegistry or {})do
   if task.time<=now and(not nextTask or task.time<nextTask.time)then nextId,nextTask=id,task end
  end
  if not nextTask then return end
  guard=guard+1;assert(guard<1000,'scheduler failed to drain')
  local callback=nextTask.event;local args={unpack(nextTask,1,20)}
  AceScheduler:CancelScheduledEvent(nextId)
  assert(type(callback)=='function','this suite expects actual callback scheduling')
  callback(unpack(args,1,20))
 end
end
function pendingCallback()
 local task=AceScheduler.delayRegistry and AceScheduler.delayRegistry.Automaton_GroupPending
 assert(task,'55-second pending invitation was not scheduled')
 assert(math.abs(task.time-(lastRequestTime+55))<.00001,'55-second deadline moved after popup binding')
 return task.event
end
function listenerCount(eventName)
 local count=0
 for _,frame in ipairs(frames)do if frame.events[eventName]then count=count+1 end end
 for _,m in ipairs(moduleOrder)do if m.events[eventName]then count=count+1 end end
 return count
end
'''


def runtime(saved=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    # Execute the repository's actual overload/argument-routing/cancellation
    # implementation. Only time advancement and pool allocation are simulated.
    source = (ROOT / "Interface/AddOns/!Libs/Ace2/AceEvent-2.0/AceEvent-2.0.lua").read_text(encoding="utf-8-sig")
    start = source.index("local delayRegistry\nlocal tmp = {}")
    end = source.index("function AceEvent:UnregisterEvent(event)", start)
    lua.execute(r'''
AceScheduler={frame=CreateFrame('Frame')}
function AceScheduler:argCheck(value,index,...)
 for _,allowed in ipairs({...})do if type(value)==allowed then return end end
 error('AceEvent bad argument '..index..': '..type(value))
end
function AceScheduler:error(message)error(message)end
local AceEvent=AceScheduler
local function new()return {}end
local function del(t)for k in pairs(t)do t[k]=nil end;return nil end
local function table_setn()end
''' + source[start:end])
    if saved:
        lua.execute(saved)
    for name in ("Group", "Loner"):
        lua.execute((ROOT / f"Interface/AddOns/Automatonex/Modules/{name}.lua").read_text(encoding="utf-8-sig"))
    lua.execute(r'''
G=Automaton.modules.Group;L=Automaton.modules.StrangerDecline
for _,m in ipairs({G,L})do
 m.ScheduleEvent=AceScheduler.ScheduleEvent
 m.CancelScheduledEvent=AceScheduler.CancelScheduledEvent
 m.IsEventScheduled=AceScheduler.IsEventScheduled
 m:OnInitialize()
end
B=Automaton.incomingInvites;assert(B,'missing incoming broker')
''')
    return lua


class IncomingInvites(unittest.TestCase):
    def test_single_listener_both_enable_disable_orders(self):
        for order in ("G,L", "L,G"):
            lua = runtime()
            lua.execute("for _,m in ipairs({" + order + "})do setActive(m,true)end")
            lua.execute(r'''
assert(listenerCount('PARTY_INVITE_REQUEST')==1)
friends={'Friend'};L.db.profile.blackList={'Friend'}
request('Friend');request('Friend',true)
assert(#actions==2 and actions[1]=='decline'and actions[2]=='decline','both accept and decline ran')
setActive(G,false);assert(listenerCount('PARTY_INVITE_REQUEST')==1)
request('Friend');assert(actions[3]=='decline','Loner stopped with Group')
setActive(L,false);request('Friend');assert(#actions==3)
setActive(G,true);request('Friend');assert(actions[4]=='accept','runtime flag read stale saved state')
setActive(L,true);setActive(L,false)
assert(listenerCount('PARTY_INVITE_REQUEST')==1)
request('Friend');assert(actions[5]=='accept','turning off Loner stopped active Group')
''')

    def test_policy_matrix_and_literal_case_insensitive_lists(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);setActive(L,true);friends={'Trusted'};guild={'Guildie'}
L.db.profile.partyEnabled=true;G.db.profile.decline=true
assert(B:Evaluate('Trusted')=='accept'and B:Evaluate('Guildie')=='accept')
L.db.profile.blackList={'TRUSTED'};L.db.profile.whiteList={'trusted'}
assert(B:Evaluate('Trusted')=='decline','black did not beat friend and white')
L.db.profile.blackList={};L.db.profile.whiteList={'White'}
assert(B:Evaluate('White')=='manual','white autoaccepted or was rejected as stranger')
assert(B:Evaluate('Outsider')=='decline')
L.isDisabled=true;G.db.profile.decline=false
assert(B:Evaluate('Outsider')=='manual')
L.db.profile.keywordList={'[bad]'}
assert(B:Evaluate('x[BAD]x')=='decline','temporary pause bypassed blacklist')
assert(B:Evaluate('bad')=='manual','keyword was treated as Lua pattern')
L.db.profile.enableBlackList=false;assert(B:Evaluate('x[bad]x')=='manual')
L.db.profile.enableBlackList=true;L.db.profile.enableKeywordMatch=false
assert(B:Evaluate('x[bad]x')=='manual')
setActive(G,false);assert(B:Evaluate('Trusted')=='manual','disabled Group still accepts')
''')

    def test_manual_and_who_are_not_accept(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);setActive(L,true)
request('Outsider');assert(#actions==0 and #queries==1)
assert(string.find(queries[1],'Outsider',1,true))
G.db.profile.who=false;request('Second');assert(#actions==0 and #queries==1)
L.db.profile.whiteList={'White'};G.db.profile.decline=true
request('White');assert(#actions==0,'whitelist is permission, not autoaccept')
''')

    def test_delayed_accept_decline_and_exact_ace_signatures(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);friends={'Friend'};G.db.profile.delay=true
request('Friend');pendingCallback();advance(54.9);assert(#actions==0)
advance(.1);assert(#actions==1 and actions[1]=='accept')
G.db.profile.decline=true;request('Outsider');pendingCallback()
advance(55);assert(#actions==2 and actions[2]=='decline')
assert(not G:IsEventScheduled('Automaton_GroupPending'))
''')

    def test_new_invitation_invalidates_old_even_same_inviter(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);friends={'Old','New'};G.db.profile.delay=true
request('Old');local old=pendingCallback()
advance(5);request('New');old();assert(#actions==0,'old generation acted on new inviter')
advance(50);assert(#actions==0);advance(5);assert(actions[1]=='accept')
actions={};request('Old');local same=pendingCallback()
advance(1);request('Old');same();assert(#actions==0,'same-name new invitation reused generation')
advance(55);assert(#actions==1 and actions[1]=='accept')
''')

    def test_cancel_events_popup_hidden_and_wrong_popup(self):
        for event in ("PARTY_INVITE_CANCEL", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD"):
            lua = runtime()
            lua.execute("setActive(G,true);friends={'Friend'};G.db.profile.delay=true;request('Friend');old=pendingCallback()")
            lua.execute(f"dispatch('{event}');old();advance(55);assert(#actions==0,'cancel event left stale action')")
        lua = runtime()
        lua.execute(r'''
setActive(G,true);friends={'Friend'};G.db.profile.delay=true
request('Friend');StaticPopup1:Hide();advance(55);assert(#actions==0)
request('Friend');StaticPopup1.which='OTHER_DIALOG';advance(55);assert(#actions==0)
''')

    def test_manual_actions_cancel_timer_and_preserve_return_values(self):
        for action in ("AcceptGroup", "DeclineGroup"):
            lua = runtime()
            lua.execute("setActive(G,true);friends={'Friend'};G.db.profile.delay=true;request('Friend');old=pendingCallback()")
            lua.execute(f"responseKeepsPopup=true;a,b,c={action}();assert(a and b==nil and c=='tail');old();advance(55);assert(#actions==1,'manual response left automatic response')")

    def test_visible_popup_must_still_belong_to_original_inviter(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);friends={'Friend'};G.db.profile.delay=true
request('Friend');pendingCallback()
StaticPopup1Text:SetText(string.format(PARTY_INVITE,'DifferentFriend'))
advance(55);assert(#actions==0,'visible unrelated invitation passed source validation')
''')

    def test_native_ui_show_after_broker_and_cancel_before_bind(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);friends={'Friend'}
dispatch('PARTY_INVITE_REQUEST','Friend');assert(#actions==0)
StaticPopup_Show('PARTY_INVITE','Friend');advance(.05)
assert(#actions==1 and actions[1]=='accept','broker-before-native-popup event ordering failed')
dispatch('PARTY_INVITE_REQUEST','Friend');StaticPopup_Show('PARTY_INVITE','Friend')
dispatch('PARTY_INVITE_CANCEL');advance(.05);assert(#actions==1)
StaticPopup_Hide('PARTY_INVITE') -- native UI handles the cancellation too
dispatch('PARTY_INVITE_REQUEST','Friend');advance(.05);assert(#actions==1,'missing popup was guessed')
''')

    def test_popup_hide_preserves_native_script_and_invalidates_reused_frame(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);friends={'Friend'};G.db.profile.delay=true;nativeHides=0
StaticPopup1:SetScript('OnHide',function()
 assert(this==StaticPopup1,'original native script lost legacy this')
 nativeHides=nativeHides+1
end)
request('Friend');local old=pendingCallback()
StaticPopup1:Hide();assert(nativeHides==1)
StaticPopup_Show('PARTY_INVITE','Friend');old();advance(55)
assert(#actions==0,'hidden/reused popup inherited previous invitation')
''')

    def test_localized_second_popup_and_unrecognizable_template(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);friends={'队友'}
StaticPopupDialogs.PARTY_INVITE.text='玩家 %s 邀请你加入队伍。'
StaticPopup1.which='OTHER_DIALOG';StaticPopup1:Show()
StaticPopup2.which='PARTY_INVITE';StaticPopup2Text:SetText('玩家 队友 邀请你加入队伍。');StaticPopup2:Show()
dispatch('PARTY_INVITE_REQUEST','队友');advance(.05)
assert(#actions==1 and actions[1]=='accept','did not find localized invitation in second popup')
StaticPopup2.which='PARTY_INVITE';StaticPopup2Text:SetText('玩家 队友 邀请你加入队伍。');StaticPopup2:Show()
StaticPopupDialogs.PARTY_INVITE.text='Third party changed invitation: %s'
dispatch('PARTY_INVITE_REQUEST','队友');advance(.05);assert(#actions==1)
StaticPopupDialogs.PARTY_INVITE.text=nil
dispatch('PARTY_INVITE_REQUEST','队友');advance(.05);assert(#actions==1)
''')

    def test_disable_and_rule_changes_invalidate_delayed_decision(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);setActive(L,true);friends={'Friend'};G.db.profile.delay=true
request('Friend');local old=pendingCallback();setActive(G,false)
old();advance(55);assert(#actions==0)
setActive(G,true);request('Friend');L.db.profile.blackList={'Friend'}
advance(55);assert(#actions==0,'old accept was changed into unrequested late decline')
L.db.profile.blackList={};request('Friend');friends={}
advance(55);assert(#actions==0,'friend removal did not invalidate accept')
G.db.profile.decline=true;request('Outsider');G.db.profile.decline=false
advance(55);assert(#actions==0,'disabled rule still declined')
''')

    def test_cancel_also_removes_legacy_timer_ids(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true)
G:ScheduleEvent('Automaton_GroupAccept',function()error('legacy accept escaped')end,55)
G:ScheduleEvent('Automaton_GroupDecline',function()error('legacy decline escaped')end,55)
B:Cancel();advance(55)
assert(not G:IsEventScheduled('Automaton_GroupAccept')and not G:IsEventScheduled('Automaton_GroupDecline'))
''')

    def test_guild_petition_blacklist_stays_registered_when_options_off(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);setActive(L,true)
L._options.party.set(false);L._options.guild.set(false)
L.db.profile.blackList={'Blocked'}
request('Blocked');assert(actions[1]=='decline')
dispatch('GUILD_INVITE_REQUEST','Blocked');assert(actions[2]=='guild-decline')
C_PetitionInfo={GetPetitionInfo=function()return {ownerName='Blocked'}end}
dispatch('PETITION_SHOW');assert(actions[3]=='petition-close')
friends={'Friend'};L.db.profile.whiteList={'White'};L._options.guild.set(true)
dispatch('GUILD_INVITE_REQUEST','Friend');dispatch('GUILD_INVITE_REQUEST','White');assert(#actions==3)
guild={'Guildie'};dispatch('GUILD_INVITE_REQUEST','Guildie');assert(actions[4]=='guild-decline')
C_PetitionInfo=nil;dispatch('PETITION_SHOW');assert(actions[5]=='petition-close')
L.db.profile.enableBlackList=false;dispatch('PETITION_SHOW');assert(#actions==5)
setActive(L,false);L._options.party.set(true);L._options.guild.set(true)
dispatch('GUILD_INVITE_REQUEST','Outsider');dispatch('PETITION_SHOW');assert(#actions==5,'editing options reenabled inactive module')
''')

    def test_real_scheduler_cancellation_preserves_new_invitation(self):
        lua = runtime()
        lua.execute(r'''
setActive(G,true);setActive(L,true);friends={'旧队友','新队友'};G.db.profile.delay=true
StaticPopupDialogs.PARTY_INVITE.text='%s邀请你加入队伍'
local function queue(name)
 lastRequestTime=now
 StaticPopup1.which='PARTY_INVITE'
 StaticPopup1Text:SetText(string.format(StaticPopupDialogs.PARTY_INVITE.text,name))
 StaticPopup1:Show();dispatch('PARTY_INVITE_REQUEST',name)
 now=now+.05;AceScheduler.frame:GetScript('OnUpdate')()
 assert(B.pending and B.pending.popup==StaticPopup1)
 return pendingCallback()
end
local old=queue('旧队友')
now=now+1;local current=queue('新队友')
local deadline=lastRequestTime+55
local task=AceScheduler.delayRegistry.Automaton_GroupPending
old()
assert(#actions==0 and AceScheduler.delayRegistry.Automaton_GroupPending==task,
 'old callback cancelled the newer native scheduler task')
now=deadline-.01;AceScheduler.frame:GetScript('OnUpdate')();assert(#actions==0)
-- The real AceEvent OnUpdate calls the callback BEFORE removing its task.
-- Apply/AcceptGroup cancel that currently executing task; its cleanup must
-- remain valid when control returns to the actual scheduler implementation.
now=deadline;AceScheduler.frame:GetScript('OnUpdate')()
assert(#actions==1 and actions[1]=='accept' and not B.pending)
assert(not G:IsEventScheduled('Automaton_GroupPending'))
local nextInvite=queue('旧队友')
local nextTask=AceScheduler.delayRegistry.Automaton_GroupPending
current();old()
assert(#actions==1 and AceScheduler.delayRegistry.Automaton_GroupPending==nextTask)
now=lastRequestTime+55;AceScheduler.frame:GetScript('OnUpdate')()
assert(#actions==2 and actions[2]=='accept')
nextInvite();assert(#actions==2)
''')

    def test_known_petition_policy_and_delayed_feedback(self):
        lua = runtime()
        lua.execute(r'''
setActive(L,true);L.db.profile.guildEnabled=true
local inviter='Outsider'
C_PetitionInfo={GetPetitionInfo=function()return {ownerName=inviter}end}
-- This ordinary stranger branch must use the real AceEvent callback/delay
-- signature. A missing delay throws before either timing assertion can pass.
dispatch('PETITION_SHOW')
assert(#actions==1 and actions[1]=='petition-close' and #messages==0)
advance(.49);assert(#messages==0)
advance(.02);assert(#messages==1 and string.find(messages[1],'取消',1,true))
L.db.profile.whiteList={'White'};inviter='White';dispatch('PETITION_SHOW')
friends={'Friend'};inviter='Friend';dispatch('PETITION_SHOW')
advance(.5);assert(#actions==1 and #messages==1,'friend/white petition was rejected')
inviter='Outsider';L.isDisabled=true;dispatch('PETITION_SHOW')
advance(.5);assert(#actions==1 and #messages==1,'temporary pause still rejected stranger')
L.isDisabled=false;L.db.profile.guildEnabled=false;dispatch('PETITION_SHOW')
advance(.5);assert(#actions==1 and #messages==1,'disabled guild policy still rejected stranger')
L.db.profile.blackList={'Blocked'};inviter='Blocked';L.isDisabled=true
dispatch('PETITION_SHOW');assert(#actions==2 and #messages==1)
advance(.49);assert(#messages==1)
advance(.02);assert(#messages==2 and string.find(messages[2],'Blocked',1,true))
L.db.profile.keywordList={'[bad]'};inviter='x[bad]x'
dispatch('PETITION_SHOW');assert(#actions==3 and #messages==2)
advance(.5);assert(#messages==3 and string.find(messages[3],'[bad]',1,true))
L.db.profile.enableBlackList=false;dispatch('PETITION_SHOW')
advance(.5);assert(#actions==3 and #messages==3)
''')

    def test_existing_namespaces_and_lists_preserved(self):
        lua = runtime(r'''
Automaton.dbs.Group={profile={who=false,decline=true,delay=true,custom='keep'}}
Automaton.dbs.StrangerDecline={profile={whiteList={'White'},blackList={'Blocked'},keywordList={'bad'},guildEnabled=true}}
savedGroup=Automaton.dbs.Group;savedLoner=Automaton.dbs.StrangerDecline
savedWhite=savedLoner.profile.whiteList
''')
        lua.execute(r'''
assert(G.db==savedGroup and L.db==savedLoner and L.db.profile.whiteList==savedWhite)
assert(not G.db.profile.who and G.db.profile.decline and G.db.profile.delay and G.db.profile.custom=='keep')
setActive(L,true);setActive(G,true)
assert(L.db.profile.blackList[1]=='Blocked'and L.db.profile.keywordList[1]=='bad'and L.db.profile.guildEnabled)
assert(G.db.profile.custom=='keep'and L.db.profile.whiteList==savedWhite)
''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
