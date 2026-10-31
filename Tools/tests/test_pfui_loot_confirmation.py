"""Offline loot binding regression against live pfUI and LootBOP code.

Models 1.12 UIParent data=lootSlot and StaticPopup LOOT_BIND accept=LootSlot.
No synthetic confirmation dialog may be created by the addon. AceEvent's real
scheduler is used; only client frames, inventory and the passage of time are
simulated. This does not exercise server item transfers or touch saved files.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil;C_Timer=nil;format=string.format
now=10;party=0;raid=0;shift=false;actions={};queue={};frames={};errors={}
items={[1]='item:101:0:0:0',[2]='item:202:0:0:0',[3]='item:303:0:0:0'}
function GetTime()return now end
function geterrorhandler()return function(message)table.insert(errors,message)end end
function GetNumPartyMembers()return party end
function GetNumRaidMembers()return raid end
function GetNumLootItems()return 3 end
function GetLootSlotLink(slot)return items[slot]end
function LootSlotIsItem(slot)return items[slot] and true or false end
function IsShiftKeyDown()return shift end
function CreateFrame(kind,name,parent)
 local f={events={},scripts={},name=name,shown=false}
 function f:RegisterEvent(ev)self.events[ev]=true end
 function f:UnregisterEvent(ev)self.events[ev]=nil end
 function f:UnregisterAllEvents()self.events={}end
 function f:IsEventRegistered(ev)return self.events[ev]end
 function f:SetScript(name,func)self.scripts[name]=func end
 function f:GetScript(name)return self.scripts[name]end
 function f:GetName()return self.name end
 function f:IsShown()return self.shown end
 f.IsVisible=f.IsShown
 function f:Show()self.shown=true end
 function f:Hide()
  local was=self.shown;self.shown=false
  if was and self.scripts.OnHide then
   local prev=this;this=self;self.scripts.OnHide();this=prev
  end
 end
 table.insert(frames,f);if name then _G[name]=f end;return f
end
STATICPOPUP_NUMDIALOGS=4
for i=1,4 do
 local f=CreateFrame('Frame','StaticPopup'..i)
 local button={}
 function button:Click()
  assert(f.shown and f.which=='LOOT_BIND','wrong confirmation clicked')
  LootSlot(f.data);f:Hide()
 end
 _G[f.name..'Button1']=button
end
function StaticPopup_Show()error('addon must never create a confirmation popup')end
function StaticPopup_FindVisible(which)
 for i=1,4 do local f=_G['StaticPopup'..i];if f.shown and f.which==which then return f end end
end
function StaticPopup_Hide(which)
 for i=1,4 do local f=_G['StaticPopup'..i];if f.which==which then f:Hide()end end
end
local function Confirm(slot,api)
 assert(type(slot)=='number' and items[slot],'invalid/cleared loot slot')
 local found=false
 for i=1,4 do
  local f=_G['StaticPopup'..i]
  if f.shown and f.which=='LOOT_BIND' and f.data==slot then found=true end
 end
 assert(found,'confirmation no longer belongs to requested slot')
 table.insert(actions,{slot=slot,link=items[slot],api=api})
end
function LootSlot(slot)Confirm(slot,'vanilla')end
function ConfirmLootSlot(slot)Confirm(slot,'tbc')end
function QueueFunction(callback,...)
 assert(type(callback)=='function');table.insert(queue,{fn=callback,args={...},due=now+.2})
end
Automaton={modules={},dbs={},db={char={}}}
function Automaton:AcquireDBNamespace(name)
 self.dbs[name]=self.dbs[name]or{profile={}};return self.dbs[name]
end
function Automaton:RegisterDefaults(name,scope,defaults)
 local target=self:AcquireDBNamespace(name)[scope]
 for k,v in pairs(defaults)do if target[k]==nil then target[k]=v end end
end
function Automaton:SetDisabledAsDefault()end
function Automaton:IsModuleActive(name)return self.modules[name]and self.modules[name].savedActive end
function Automaton:NewModule(name)
 local m={events={},savedActive=false};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(ev,handler)self.events[ev]=handler or ev end
 function m:UnregisterEvent(ev)self.events[ev]=nil end
 function m:UnregisterAllEvents()self.events={}end
 function m:IsEventRegistered(ev)return self.events[ev]~=nil end
 function m:Debug()end
 return m
end
function AceLibrary()
 return{new=function()return setmetatable({RegisterTranslations=function(self,locale,fn)
  for k,v in pairs(fn())do self[k]=v end
 end},{__index=function(_,key)return key end})end}
end
C={loot={autopickup='1',mousecursor='0'},automation={enabled='1'}}
pfUI={client=11200,loot=CreateFrame('Frame','pfLootFrame'),automation={}}
pfUI.loot.slots={};pfUI.loot.announceFrame=CreateFrame('Frame')
function pfUI.loot:UpdateLootFrame()self.renderUpdates=(self.renderUpdates or 0)+1 end
function ShowUIPanel(frame)frame:Show()end
function HideUIPanel(frame)frame:Hide()end
function CloseLoot()end
DropDownList1=CreateFrame('Frame')
function CloseDropDownMenus()DropDownList1:Hide()end
Automaton.modules.Superwow={autolootManaged=true}
function pfUI.automation:IsEnabled()return C.automation.enabled=='1'end
function getglobal(name)return _G[name]end
function activate(enabled)
 -- Saved status deliberately changes after OnEnable/OnDisable, as Core does.
 if enabled then M:OnEnable()else M:OnDisable()end;M.savedActive=enabled
end
function emit(ev,slot)
 local oldEvent,oldArg,oldThis=event,arg1,this;event=ev;arg1=slot;this=pfUI.loot
 pfUI.loot:GetScript('OnEvent')()
 local handler=M.events[ev]
 if handler then if type(handler)=='string'then M[handler](M,slot)else handler(slot)end end
 event,arg1,this=oldEvent,oldArg,oldThis
end
function nativePopup(slot,index)
 local f=_G['StaticPopup'..(index or 1)]
 f.which='LOOT_BIND';f.data=slot;f:Show();return f
end
function advance(seconds)
 now=now+seconds
 local prevThis,prevArg=this,arg1
 this=AceScheduler.frame;arg1=seconds
 local update=AceScheduler.frame:GetScript('OnUpdate');if update then update()end
 this,arg1=prevThis,prevArg
 local scheduled=queue;queue={}
 for _,task in ipairs(scheduled)do
  if task.due<=now then task.fn(unpack(task.args))else table.insert(queue,task)end
 end
end
function clearActions()actions={}end
'''


def runtime(saved=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    scheduler = (ROOT / "Interface/AddOns/!Libs/Ace2/AceEvent-2.0/AceEvent-2.0.lua").read_text(encoding="utf-8-sig")
    start = scheduler.index("local delayRegistry\nlocal tmp = {}")
    end = scheduler.index("function AceEvent:UnregisterEvent(event)", start)
    lua.execute(r'''
AceScheduler={frame=CreateFrame('Frame')}
function AceScheduler:argCheck(value,index,...)
 for _,allowed in ipairs({...})do if type(value)==allowed then return end end
 error('AceEvent invalid argument '..index..': '..type(value))
end
function AceScheduler:error(message)error(message)end
local AceEvent=AceScheduler
local function new()return{}end
local function del(t)for key in pairs(t)do t[key]=nil end;return nil end
local function table_setn()end
''' + scheduler[start:end])
    lua.execute(saved)
    lua.execute((ROOT / "Interface/AddOns/Automatonex/Modules/LootBOP.lua").read_text(encoding="utf-8-sig"))
    lua.execute(r'''
M=Automaton.modules.LootBOP
M.ScheduleEvent=AceScheduler.ScheduleEvent
M.CancelScheduledEvent=AceScheduler.CancelScheduledEvent
M.IsEventScheduled=AceScheduler.IsEventScheduled
function M:CancelAllScheduledEvents()
 local ids={};for id,task in pairs(AceScheduler.delayRegistry or{})do if task.self==self then table.insert(ids,id)end end
 for _,id in ipairs(ids)do self:CancelScheduledEvent(id)end
end
M:OnInitialize()
''')
    source = (ROOT / "Interface/AddOns/pfUI/modules/loot.lua").read_text(encoding="utf-8-sig")
    block = source.split("-- BEGIN AUTOMATION LOOT CONFIRMATION", 1)[1].split("-- END AUTOMATION LOOT CONFIRMATION", 1)[0]
    lua.execute(block)
    start = source.index('  pfUI.loot:SetScript("OnEvent", function()')
    end = source.index('  LootFrame:UnregisterAllEvents()', start)
    lua.execute(source[start:end])
    return lua


class LootConfirmation(unittest.TestCase):
    def test_policy_matrix_and_runtime_activation(self):
        lua = runtime()
        lua.execute(r'''
pfUI.loot:SyncBindOwnership(true)
assert(pfUI.loot:ShouldConfirmBind())
C.loot.autopickup='0';assert(not pfUI.loot:ShouldConfirmBind())
activate(true);assert(pfUI.loot:ShouldConfirmBind())
party=1;assert(not pfUI.loot:ShouldConfirmBind())
M.options.confirmInGroup.set(true);assert(pfUI.loot:ShouldConfirmBind())
party=0;raid=1;assert(pfUI.loot:ShouldConfirmBind())
M.options.confirmInGroup.set(false);assert(not pfUI.loot:ShouldConfirmBind())
raid=0;activate(false);assert(not pfUI.loot:ShouldConfirmBind())
C.loot.autopickup='1';assert(pfUI.loot:ShouldConfirmBind())
''')

    def test_managed_single_owner_and_standalone_fallback(self):
        lua = runtime()
        lua.execute(r'''
activate(true);pfUI.loot:SyncBindOwnership(true)
assert(not M.events.LOOT_BIND_CONFIRM,'managed module kept competing event listener')
emit('LOOT_OPENED');nativePopup(1,3);emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==1 and actions[1].slot==1)
pfUI.loot:SyncBindOwnership(false)
assert(M.events.LOOT_BIND_CONFIRM,'standalone event listener was not restored')
emit('LOOT_OPENED');nativePopup(2,2);emit('LOOT_BIND_CONFIRM',2);advance(.3)
assert(#actions==2 and actions[2].slot==2,'fallback double confirmed or lost confirmation')
activate(false);assert(not M.events.LOOT_BIND_CONFIRM)
''')

    def test_popup_number_and_client_specific_accept_api(self):
        for client, api in ((11200, "vanilla"), (20400, "tbc")):
            lua = runtime()
            lua.execute(f"pfUI.client={client}")
            lua.execute(r'''
pfUI.loot:SyncBindOwnership(true);emit('LOOT_OPENED')
StaticPopup1.which='OTHER';StaticPopup1.data=1;StaticPopup1:Show()
nativePopup(1,4);emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==1 and StaticPopup1:IsShown()and StaticPopup1.which=='OTHER')
''')
            self.assertEqual(lua.globals().actions[1]["api"], api)

    def test_native_show_after_event_and_duplicate_requests(self):
        lua = runtime()
        lua.execute(r'''
pfUI.loot:SyncBindOwnership(true);emit('LOOT_OPENED')
emit('LOOT_BIND_CONFIRM',1);emit('LOOT_BIND_CONFIRM',1);nativePopup(1,2)
advance(.3);assert(#actions==1,'duplicate binding event confirmed twice')
nativePopup(2,3);emit('LOOT_BIND_CONFIRM',2);advance(.3)
assert(#actions==2 and actions[2].slot==2,'next item was swallowed')
''')

    def test_concurrent_slots_do_not_accept_the_other_items_popup(self):
        for standalone in (False, True):
            lua = runtime()
            lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
            lua.execute(r'''
emit('LOOT_OPENED');nativePopup(1);emit('LOOT_BIND_CONFIRM',1)
-- The native exclusive dialog is reused for a second binding request.
nativePopup(2);emit('LOOT_BIND_CONFIRM',2);advance(.3)
assert(#actions==1 and actions[1].slot==2,'accepted the wrong item from concurrent events')
-- The unconfirmed first item can be requested again; it must not stay locked.
nativePopup(1);emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==2 and actions[2].slot==1)
''')

    def test_superwow_and_shift_control_collection_separately_from_binding(self):
        lua = runtime()
        lua.execute(r'''
Automaton.modules.Superwow=nil;assert(pfUI.loot:ShouldCollectSoloLoot())
shift=true;assert(not pfUI.loot:ShouldCollectSoloLoot())
assert(pfUI.loot:ShouldConfirmBind(),'manual pickup must still retain its binding preference')
shift=false;Automaton.modules.Superwow={autolootManaged=true}
assert(not pfUI.loot:ShouldCollectSoloLoot(),'pfUI bypassed SuperWoW mode')
Automaton.modules.Superwow.autolootManaged=false;assert(pfUI.loot:ShouldCollectSoloLoot())
party=1;assert(not pfUI.loot:ShouldCollectSoloLoot())
party=0;raid=1;assert(not pfUI.loot:ShouldCollectSoloLoot())
raid=0;pfUI.client=20400;assert(not pfUI.loot:ShouldCollectSoloLoot())
pfUI.client=11200;C.loot.autopickup='0';assert(not pfUI.loot:ShouldCollectSoloLoot())
''')

    def test_popup_reuse_after_manual_hide_does_not_revive_pending_task(self):
        for standalone in (False, True):
            lua = runtime()
            lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
            lua.execute(r'''
local calls=0
StaticPopup2:SetScript('OnHide',function()
 assert(this==StaticPopup2,'native OnHide lost legacy this');calls=calls+1
end)
emit('LOOT_OPENED');local f=nativePopup(1,2);emit('LOOT_BIND_CONFIRM',1)
f:Hide();assert(calls==1);f:Show();advance(.3)
assert(#actions==0,'hidden same-slot popup revived old confirmation')
emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==1 and calls==2,'subsequent explicit request did not work')
''')

    def test_synchronous_reentry_stops_without_hiding_manual_popup(self):
        for standalone in (False, True):
            lua = runtime()
            lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
            lua.execute(r'''
local original=LootSlot
LootSlot=function(slot)original(slot);emit('LOOT_BIND_CONFIRM',slot)end
emit('LOOT_OPENED');nativePopup(1);emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==1 and StaticPopup1:IsShown(),'repeated native confirmation looped or hid approval')
advance(.3);assert(#actions==1,'reentry scheduled endless auto-confirmation')
''')

    def test_synchronous_slot_clear_new_request_survives_previous_callback(self):
        for standalone in (False, True):
            lua = runtime()
            lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
            lua.execute(r'''
local original=LootSlot;local replaced=false
LootSlot=function(slot)
 original(slot)
 if not replaced then
  replaced=true;emit('LOOT_SLOT_CLEARED',slot)
  items[slot]='item:777:0:0:0';nativePopup(slot);emit('LOOT_BIND_CONFIRM',slot)
 end
end
emit('LOOT_OPENED');nativePopup(1);emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==1 and StaticPopup1:IsShown(),'old callback hid new binding request')
advance(.3);assert(#actions==2 and actions[2].link=='item:777:0:0:0','new pending request was erased')
''')

    def test_synchronous_loot_session_change_preserves_new_manual_popup(self):
        for standalone in (False, True):
            for ev in ("LOOT_CLOSED", "LOOT_OPENED"):
                lua = runtime()
                lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()});sessionEvent='{ev}'")
                lua.execute(r'''
local original=LootSlot
LootSlot=function(slot)
 original(slot);emit(sessionEvent)
 -- A new native manual popup happens to reuse the same frame, slot and link.
 -- No automatic binding request was made for this new loot session.
 nativePopup(slot)
end
emit('LOOT_OPENED');nativePopup(1);emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==1 and StaticPopup1:IsShown(),'old accept hid a new-session manual popup')
advance(.3);assert(#actions==1 and StaticPopup1:IsShown(),'new manual popup became automatic')
''')

    def test_native_handler_clears_pending_even_if_loot_frame_hidden(self):
        lua = runtime()
        lua.execute(r'''
pfUI.loot:SyncBindOwnership(true);emit('LOOT_OPENED')
nativePopup(1);emit('LOOT_BIND_CONFIRM',1);pfUI.loot:Hide()
emit('LOOT_SLOT_CLEARED',1);advance(.3)
assert(#actions==0,'native hidden-frame early return bypassed pending cancellation')
''')

    def test_invalid_slots_are_rejected_before_scheduling(self):
        for standalone in (False, True):
            lua = runtime()
            lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
            lua.execute(r'''
emit('LOOT_OPENED')
for _,slot in ipairs({0,-1,1.5,'1',99})do emit('LOOT_BIND_CONFIRM',slot)end
emit('LOOT_BIND_CONFIRM');advance(.3)
assert(#actions==0 and #queue==0 and #errors==0)
''')

    def test_accept_error_does_not_lock_future_bindings(self):
        for standalone in (False, True):
            lua = runtime()
            lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
            lua.execute(r'''
local original=LootSlot;LootSlot=function()error('simulated client rejection')end
emit('LOOT_OPENED');nativePopup(1);emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==0 and #errors==1 and StaticPopup1:IsShown(),'error concealed or approval hidden')
LootSlot=original;emit('LOOT_BIND_CONFIRM',1);advance(.3)
assert(#actions==1 and actions[1].slot==1,'client error locked future requests')
''')

    def test_no_popup_or_wrong_slot_is_never_guessed(self):
        lua = runtime()
        lua.execute(r'''
pfUI.loot:SyncBindOwnership(true);emit('LOOT_OPENED')
emit('LOOT_BIND_CONFIRM',1);advance(.3);assert(#actions==0)
nativePopup(2);emit('LOOT_BIND_CONFIRM',1);advance(.3);assert(#actions==0)
StaticPopup1.which='CONFIRM_LOOT_ROLL';StaticPopup1.data=1
emit('LOOT_BIND_CONFIRM',1);advance(.3);assert(#actions==0)
assert(#errors==0,'unrelated popup reached the protected client API')
''')

    def test_manual_cancel_and_changed_slot_link(self):
        for standalone in (False, True):
            lua = runtime()
            lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
            lua.execute(r'''
emit('LOOT_OPENED');local f=nativePopup(1);emit('LOOT_BIND_CONFIRM',1)
f:Hide();advance(.3);assert(#actions==0,'manual cancel was undone')
emit('LOOT_OPENED');nativePopup(2);emit('LOOT_BIND_CONFIRM',2)
items[2]='item:999:0:0:0';advance(.3);assert(#actions==0,'new item inherited old confirmation')
''')

    def test_close_reopen_slot_clear_and_world_leave_invalidate_tasks(self):
        for ev in ("LOOT_CLOSED", "LOOT_OPENED", "LOOT_SLOT_CLEARED", "PLAYER_LEAVING_WORLD"):
            for standalone in (False, True):
                lua = runtime()
                lua.execute(f"activate(true);pfUI.loot:SyncBindOwnership({str(not standalone).lower()})")
                lua.execute("emit('LOOT_OPENED');nativePopup(1);emit('LOOT_BIND_CONFIRM',1)")
                lua.execute(f"emit('{ev}',1);advance(.3);assert(#actions==0,'stale {ev} confirmation ran')")

    def test_policy_disable_while_pending(self):
        lua = runtime()
        lua.execute(r'''
pfUI.loot:SyncBindOwnership(true);activate(true);C.loot.autopickup='0'
emit('LOOT_OPENED');nativePopup(1);emit('LOOT_BIND_CONFIRM',1);activate(false)
advance(.3);assert(#actions==0)
activate(true);party=1;M.options.confirmInGroup.set(true)
emit('LOOT_OPENED');nativePopup(2);emit('LOOT_BIND_CONFIRM',2);M.options.confirmInGroup.set(false)
advance(.3);assert(#actions==0)
''')

    def test_saved_flags_and_database_are_not_migrated(self):
        lua = runtime("Automaton.dbs.LootBOP={profile={confirmInGroup=true,disabled=true,personal='keep'}};saved=Automaton.dbs.LootBOP")
        lua.execute(r'''
assert(M.db==saved and M.options.confirmInGroup.get()==true)
activate(true);pfUI.loot:SyncBindOwnership(true);pfUI.loot:SyncBindOwnership(false)
activate(false);assert(M.db==saved and saved.profile.personal=='keep'and saved.profile.disabled==true)
M.options.confirmInGroup.set(false);assert(not saved.profile.confirmInGroup)
''')


if __name__ == "__main__":
    unittest.main(verbosity=2)
