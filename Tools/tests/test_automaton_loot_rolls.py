"""Offline AutoNeed queue tests with real AceEvent scheduling and original rules."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime
from test_automaton_incoming_invites import MOCK


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
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
    lua.execute(r'''
function UnitClass()return 'Paladin','PALADIN'end
function GetItemInfo(id)return 'Item '..id,'item:'..id..':0:0:0',3,1,'Armor','Plate',1,'INVTYPE_CHEST'end
links={};left={};rolls={};confirms={};popupIndex=2
function GetLootRollItemLink(id)return links[id]end
function GetLootRollTimeLeft(id)return left[id] or 0 end
function RollOnLoot(id,choice)
 if failRoll then error('server roll failure')end
 table.insert(rolls,{id,choice})
 if onRoll then onRoll()end
 if choice>0 and not noPopup then
  local popup=_G['StaticPopup'..popupIndex]
  popup.which='CONFIRM_LOOT_ROLL';popup.data=id;popup.data2=choice;popup:Show()
 end
end
function ConfirmLootRoll(id,choice)
 if failConfirm then error('server confirm failure')end
 table.insert(confirms,{id,choice})
 if onConfirm then onConfirm()end
end
function addRoll(id,item,choice)
 links[id]='item:'..item..':0:0:0';left[id]=60000
 table.insert(N.db.char.autoneedsDB,{itemID=item,rolltype=choice})
end
function tick(dt)
 now=now+dt;local update=AceScheduler.frame:GetScript('OnUpdate');if update then update()end
end
function drain()for i=1,30 do tick(.1)end end
function callback(id)return AceScheduler.delayRegistry[id].event end
Automaton.dbs.AutoNeed={profile={},char={autoneedsDB={}}}
''')
    lua.execute((ROOT / "Interface/AddOns/Automatonex/Modules/AutoNeed.lua").read_text(encoding="utf-8-sig"))
    lua.execute(r'''
N=Automaton.modules.AutoNeed
N.ScheduleEvent=AceScheduler.ScheduleEvent
N.CancelScheduledEvent=AceScheduler.CancelScheduledEvent
N.IsEventScheduled=AceScheduler.IsEventScheduled
function N:UnhookAll()end
N:OnInitialize();N:OnEnable()
''')
    return lua


class LootRolls(unittest.TestCase):
    def test_original_rules_and_all_choice_controls(self):
        lua=runtime()
        lua.execute(r'''
local choices=0
local function check(options)
 for _,option in pairs(options)do
  if option.args then check(option.args)end
  if option.validate and option.validate[1]=='需求' then
   choices=choices+1
   assert(#option.validate==4 and option.validate[4]=='不选择')
  end
 end
end
check(N.options);assert(choices==31)
addRoll(1,99001,-1);N:START_LOOT_ROLL(1);assert(#rolls==0)
N.db.char.autoneedsDB={};N.db.char['品质_enable']=true
N.db.char['蓝装_rolltype']='不选择';assert(N:CheckItem(99001)==nil)
N:START_LOOT_ROLL(1);assert(#rolls==0)
N.db.char['蓝装_rolltype']='贪婪';assert(N:CheckItem(99001)==2)
N.db.char['杂项_enable']=true;N.db.char.item_4500='需求';assert(N:CheckItem(4500)==1)
''')

    def test_matching_second_popup_only(self):
        lua=runtime()
        lua.execute(r'''
StaticPopup1.which='DELETE_ITEM';StaticPopup1:Show()
addRoll(10,99010,1);N:START_LOOT_ROLL(10);drain()
assert(#rolls==1 and #confirms==1 and confirms[1][1]==10 and confirms[1][2]==1)
assert(StaticPopup1:IsShown() and not StaticPopup2:IsShown())
''')

    def test_two_rolls_are_serialized_and_duplicates_suppressed(self):
        lua=runtime()
        lua.execute(r'''
addRoll(1,99001,1);addRoll(2,99002,2)
N:START_LOOT_ROLL(1);N:START_LOOT_ROLL(2);N:START_LOOT_ROLL(1)
assert(#rolls==1);drain()
assert(#rolls==2 and #confirms==2 and confirms[1][1]==1 and confirms[2][1]==2)
assert(not N.isRolling and #N.pendingRolls==0)
''')

    def test_manual_or_different_confirmation_is_left_untouched(self):
        for mutation in ["StaticPopup2:Hide()", "StaticPopup2.data=77", "StaticPopup2.data2=2", "StaticPopup2.which='LOOT_BIND'"]:
            lua=runtime()
            lua.execute("addRoll(1,99001,1);N:START_LOOT_ROLL(1);"+mutation+";drain();assert(#confirms==0)")

    def test_hidden_same_popup_identity_cannot_revive_old_confirmation(self):
        lua=runtime()
        lua.execute(r'''
nativeHides=0
StaticPopup2:SetScript('OnHide',function()
 assert(this==StaticPopup2,'original hide script lost native this')
 nativeHides=nativeHides+1
end)
addRoll(1,99001,1);N:START_LOOT_ROLL(1)
local watcher=StaticPopup2:GetScript('OnHide')
StaticPopup2:Hide();StaticPopup2:Show();drain()
assert(#confirms==0 and StaticPopup2:IsShown() and nativeHides==1)
addRoll(2,99002,2);N:START_LOOT_ROLL(2)
assert(StaticPopup2:GetScript('OnHide')==watcher,'watchers accumulated')
drain();assert(#confirms==1 and confirms[1][1]==2 and nativeHides==2)
''')

    def test_synchronous_confirmation_hide_and_reopen_is_not_closed(self):
        lua=runtime()
        lua.execute(r'''
addRoll(1,99001,1)
onConfirm=function()StaticPopup2:Hide();StaticPopup2:Show()end
N:START_LOOT_ROLL(1);drain()
assert(#confirms==1 and StaticPopup2:IsShown(),'confirmation hid a reopened same-identity popup')
''')

    def test_synchronous_cancel_and_same_id_reuse_preserves_new_popup(self):
        lua=runtime()
        lua.execute(r'''
addRoll(1,99001,1)
onConfirm=function()
 N:CANCEL_LOOT_ROLL(1)
 N:START_LOOT_ROLL(1)
end
N:START_LOOT_ROLL(1);tick(.1)
assert(#confirms==1 and StaticPopup2:IsShown(),'cancelled task hid a later same-ID dialog')
onConfirm=nil;drain();assert(#confirms==2)
''')

    def test_rule_changes_and_expiration_before_confirmation(self):
        for mutation in ["left[1]=0", "links[1]='item:777:0:0:0'", "N.db.char.autoneedsDB[1].rolltype=-1"]:
            lua=runtime()
            lua.execute("addRoll(1,99001,1);N:START_LOOT_ROLL(1);"+mutation+";drain();assert(#confirms==0)")

    def test_queue_rule_changes_and_expiration_before_sending(self):
        for mutation in ["left[2]=0", "links[2]='item:777:0:0:0'", "N.db.char.autoneedsDB[2].rolltype=-1"]:
            lua=runtime()
            lua.execute("addRoll(1,99001,1);addRoll(2,99002,2);N:START_LOOT_ROLL(1);N:START_LOOT_ROLL(2);"+mutation+";drain();assert(#rolls==1 and #confirms==1)")

    def test_cancel_current_and_pending_rolls(self):
        lua=runtime()
        lua.execute(r'''
addRoll(1,99001,1);addRoll(2,99002,2);addRoll(3,99003,2)
N:START_LOOT_ROLL(1);N:START_LOOT_ROLL(2);N:START_LOOT_ROLL(3)
N:CANCEL_LOOT_ROLL(1);N:CANCEL_LOOT_ROLL(2);drain()
assert(#rolls==2 and #confirms==1 and confirms[1][1]==3)
''')

    def test_disable_and_old_callbacks_cannot_touch_new_queue(self):
        lua=runtime()
        lua.execute(r'''
addRoll(1,99001,1);N:START_LOOT_ROLL(1)
local old=callback('Automaton_AutoNeedConfirm');N:OnDisable()
old();drain();assert(#confirms==0 and not N.isRolling)
N:OnEnable();addRoll(2,99002,2);N:START_LOOT_ROLL(2)
local task=AceScheduler.delayRegistry.Automaton_AutoNeedConfirm
old();assert(AceScheduler.delayRegistry.Automaton_AutoNeedConfirm==task)
drain();assert(#confirms==1 and confirms[1][1]==2)
''')

    def test_world_leave_and_finish_callback_invalidation(self):
        lua=runtime()
        lua.execute(r'''
assert(N.events.PLAYER_LEAVING_WORLD=='ResetRollQueue')
addRoll(1,99001,0);N:START_LOOT_ROLL(1)
local old=callback('Automaton_AutoNeedNext');N:ResetRollQueue()
addRoll(2,99002,2);N:START_LOOT_ROLL(2);old()
assert(N.currentRoll.id==2);drain();assert(#confirms==1 and confirms[1][1]==2)
''')

    def test_pass_no_popup_and_failures_keep_queue_moving(self):
        for setup in ['noPopup=true', 'failRoll=true', 'failConfirm=true']:
            lua=runtime()
            lua.execute(setup+";addRoll(1,99001,2);addRoll(2,99002,0);N:START_LOOT_ROLL(1);N:START_LOOT_ROLL(2);drain();assert(#confirms==0 and not N.isRolling and #N.pendingRolls==0)")

    def test_synchronous_native_events_do_not_hide_reused_frame(self):
        lua=runtime()
        lua.execute(r'''
addRoll(1,99001,1)
onConfirm=function()N:CANCEL_LOOT_ROLL(1);StaticPopup2.which='DELETE_ITEM';StaticPopup2.data=9 end
N:START_LOOT_ROLL(1);drain()
assert(#confirms==1 and StaticPopup2:IsShown() and StaticPopup2.which=='DELETE_ITEM')
''')

    def test_synchronous_shutdown_cannot_reschedule_after_disable(self):
        for hook in ['onRoll','onConfirm']:
            lua=runtime()
            lua.execute(hook+"=function()N:OnDisable()end;addRoll(1,99001,1);N:START_LOOT_ROLL(1);drain();assert(not N:IsEventScheduled('Automaton_AutoNeedNext') and not N:IsEventScheduled('Automaton_AutoNeedConfirm') and not N.isRolling)")


if __name__ == '__main__':
    unittest.main(verbosity=2)
