"""Behavior and API work counters for talent synchronization; no live game actions."""
from pathlib import Path
import ast
import sys

ROOT = Path(r'E:\1.18')
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

def literal(file, name):
    tree = ast.parse((ROOT / 'addons_tmp' / file).read_text(encoding='utf-8-sig'))
    return next(ast.literal_eval(n.value) for n in tree.body if isinstance(n, ast.Assign)
                and any(isinstance(t, ast.Name) and t.id == name for t in n.targets))

def source(addon, file):
    return (ROOT / 'Interface/AddOns' / addon / file).read_text(encoding='utf-8-sig')

UI = literal('test_bcs_float.py', 'STUB')
GAME = literal('test_talent_preset_sync.py', 'GAME_STUB')
HELPER = source('BetterCharacterStats', 'helper.lua')
PANEL = source('BetterCharacterStats', 'BCS_PropertiesPanel.lua')
BCS = source('BetterCharacterStats', 'BetterCharacterStats.lua')
ABP = source('ActionBarProfiles', 'ActionBarProfiles.lua')
BRAIN = source('BrainwasherPro', 'BrainwasherPro.lua')
for code in (HELPER, PANEL, BCS, ABP, BRAIN):
    LuaRuntime().compile(code)

rt = LuaRuntime(unpack_returned_tuples=True)
for code in (UI, GAME, ABP):
    rt.execute(code)
rt.execute(r'''
initABP();local player="测试角色 of 测试服"
local pickups, places, gearReads, bagReads, flyouts=0,0,0,0,0
local pickup,place=PickupAction,PlaceAction
function PickupAction(i) pickups=pickups+1;return pickup(i) end
function PlaceAction(i) places=places+1;return place(i) end
local eq,bag=ABP_Tooltip.SetInventoryItem,ABP_Tooltip.SetBagItem
function ABP_Tooltip:SetInventoryItem(...) gearReads=gearReads+1;return eq(self,unpack(arg)) end
function ABP_Tooltip:SetBagItem(...) bagReads=bagReads+1;return bag(self,unpack(arg)) end
function Flyout_GetActionButton(i) return {} end
function Flyout_UpdateBars() flyouts=flyouts+1 end
slots={[1]={kind="spell",name="通用",rank="等级 1"},[2]={kind="macro",name="普通宏"},[3]={kind="item",name="药水"}}
check(ABP_SaveProfile("same"),"save delta fixture")
pickups,places=0,0
local ok,report=ABP_LoadProfile("same")
check(ok and pickups==0 and places==0 and report.unchanged==3,"unchanged spell/macro/item has zero mutations")
check(flyouts==0,"unchanged load does not rebuild Flyout bars")
slots[4]={kind="spell",name="天赋A",rank="等级 1"};slots[1]={kind="spell",name="天赋A",rank="等级 1"}
ok,report=ABP_LoadProfile("same")
check(ok and pickups==2 and places==1 and slots[4]==nil,"only changed and newly empty slots are mutated")
check(flyouts==1,"changed actions refresh Flyout once")
ABP_Layout[player].same.spells[5]={name="未到位技能",rank="等级 1"}
gearReads,bagReads,pickups,places=0,0,0,0
ok,report=ABP_LoadProfile("same",{deferMissingSpells=true})
check(not ok and report=="spells_pending" and gearReads==0 and bagReads==0,"missing skills checked before equipment/bag scans")
check(pickups==0 and places==0,"unready spellbook performs no mutations")
print("PASS: "..passed.." action delta/work counter checks")
''')

rt = LuaRuntime(unpack_returned_tuples=True)
for code in (UI, GAME, PANEL):
    rt.execute(code)
rt.execute(r'''
local P=BCS.PropertiesPanel;BCSConfig={};P:Init();passed=0
local beginCount,endCount,invalidations,builds=0,0,0,0
function BCS:BeginEquipmentRead() beginCount=beginCount+1 end
function BCS:EndEquipmentRead() endCount=endCount+1 end
function BCS:InvalidateStatsCaches() invalidations=invalidations+1 end
local original=P.GetPropertyText
function P:GetPropertyText(key) builds=builds+1;return original(self,key) end
P:RefreshNow()
check(beginCount==1 and endCount==1 and invalidations==1,"panel shares a read batch and invalidates on manual refresh")
local before=beginCount
P:SelectConfig("治疗",true,true)
check(beginCount==before and P.displayConfig=="治疗","automatic preset changes defer heavy computation")
now=now+0.05;P:RequestRefresh();now=now+0.05;P:RequestRefresh();P:RefreshSpeedDisplay()
check(beginCount==before,"event burst is coalesced")
now=now+0.13;P:RefreshSpeedDisplay()
check(beginCount==before+1 and endCount==beginCount,"one final build after event burst")
before=beginCount
for i=1,10 do now=now+0.06;P:RequestRefresh();P:RefreshSpeedDisplay() end
check(beginCount>before,"continuous events cannot indefinitely starve rendering")
before=invalidations
P.frame.scripts.OnEvent(P.frame,"UNIT_STATS","target")
check(invalidations==before,"non-player stat events leave caches untouched")
P.frame.scripts.OnEvent(P.frame,"CHARACTER_POINTS_CHANGED")
check(invalidations==before+1 and P.pendingRefreshAt~=nil,"talent events invalidate and schedule fresh values")
now=now+0.15;P:RefreshSpeedDisplay()
check(P.pendingRefreshAt==nil,"talent refresh does not wait for one-second throttle")
local previousForce=BCS.ForceCalculate
function P:GetPropertyText() error("expected panel calculation failure") end
local ok=pcall(function() P:RefreshNow() end)
check(not ok and beginCount==endCount and BCS.ForceCalculate==previousForce and P.defenseSnapshot==nil,
      "failed build releases snapshot and restores calculation state")
P.GetPropertyText=original;P:RefreshNow()
P.showWindow=false;P.frame:Hide();before=beginCount
P:SelectConfig("防御",true,true);now=now+1;P:RefreshSpeedDisplay()
check(beginCount==before and not P.frame:IsShown(),"hidden panel computes nothing during automatic selection")
print("PASS: "..passed.." panel refresh/coalescing/lifecycle checks")
''')

# Use the actual attribute getters, not stand-ins, to prove TTL invalidation.
rt = LuaRuntime(unpack_returned_tuples=True)
rt.globals().testClass = 'PALADIN'
for code in (literal('test_bcs_equipment_read.py', 'STUB'),
             source('BetterCharacterStats', 'Localization.lua'), HELPER):
    rt.execute(code)
rt.execute(r'''
BCS.ForceCalculate=true;SetupGear(3)
oldHit=BCS:GetHitRating();oldHealing=BCS:GetHealingPower()
oldSpellHit=BCS:GetSpellHitRating();local _,_,regen=BCS:GetManaRegen();oldRegen=regen
oldHaste=BCS:GetHaste();oldPower=BCS:GetSpellPower()
SetupGear(8);now=now+0.1
assert(BCS:GetHitRating()==oldHit and BCS:GetHealingPower()==oldHealing,"fixture exercises old time caches")
math.huge=nil -- the classic client's math library need not expose this constant
BCS:InvalidateStatsCaches()
BCS:BeginEquipmentRead()
assert(BCS:GetHitRating()~=oldHit and BCS:GetHealingPower()~=oldHealing,"fresh hit/healing before two seconds")
local _,_,newRegen=BCS:GetManaRegen()
assert(BCS:GetSpellHitRating()~=oldSpellHit and newRegen~=oldRegen,"fresh spell hit/regen before two seconds")
assert(BCS:GetHaste()~=oldHaste and BCS:GetSpellPower()~=oldPower,"fresh haste/power before TTL expires")
BCS:EndEquipmentRead()
''')
print('PASS: actual hit/healing/spell-hit/regen/haste/power caches invalidate before TTL')

# Verify the two panels reuse real equipment tooltip reads within each build.
rt.execute(BCS)
rt.execute(r'''
function BCS:IsCharacterPanelEnabled() return false end
SetupGear(3);BCS:InvalidateStatsCaches();oldHit=BCS:GetHitRating();SetupGear(8)
event="UNIT_INVENTORY_CHANGED";arg1="player";BCS:OnEvent()
assert(BCS:GetHitRating()~=oldHit,"disabled character panel still invalidates shared cache")
''')
print('PASS: cache invalidation works with character panel disabled')

# Exercise a real floating-panel build against the real tooltip-based getters.
actual_panel = LuaRuntime(unpack_returned_tuples=True)
actual_panel.globals().testClass = 'PALADIN'
for code in (UI, 'uiCreateFrame=CreateFrame', literal('test_bcs_equipment_read.py', 'STUB'),
             source('BetterCharacterStats', 'Localization.lua'), HELPER,
             'CreateFrame=uiCreateFrame;function BCS:IsNampowerReady() return false end', PANEL):
    actual_panel.execute(code)
actual_panel.execute(r'''
SetupGear(3);BCSConfig={};local P=BCS.PropertiesPanel;P:Init()
function P:GetSelectedKeys() return {"hit","sp","heal","shit","scrit","regen","arpen","blockval"} end
local beginRead,endRead=BCS.BeginEquipmentRead,BCS.EndEquipmentRead
BCS.BeginEquipmentRead,BCS.EndEquipmentRead=nil,nil
gearReads=0;P.freshStats=true;P:BuildBody()
local repeated=gearReads;local expected={}
for i,entry in ipairs(P.bodyEntries) do expected[i]=entry.text end
BCS.BeginEquipmentRead,BCS.EndEquipmentRead=beginRead,endRead
gearReads=0;P.freshStats=true;P:BuildBody()
assert(gearReads==20 and repeated>gearReads,"real floating panel reads equipment once per slot")
for i,entry in ipairs(P.bodyEntries) do assert(entry.text==expected[i],"shared reads preserve attribute text") end
local oldHealing=P.bodyEntries[3].text
SetupGear(8);P:RefreshNow()
assert(P.bodyEntries[3].text~=oldHealing,"real panel sees new gear before TTL expires")
print("PASS: real eight-attribute floating build, gear reads "..repeated.." -> 20, text unchanged")
''')

rt = LuaRuntime(unpack_returned_tuples=True)
for code in (UI, GAME, PANEL, ABP, BRAIN):
    rt.execute(code)
rt.execute(r'''
BCSConfig={};local P=BCS.PropertiesPanel;P:Init();initABP();passed=0
local controller
for _,f in ipairs(allFrames) do if f.events and f.events.GOSSIP_SHOW then controller=f end end
local function signal(ev,unit) event=ev;arg1=unit;controller:Fire("OnEvent") end
signal("ADDON_LOADED","BrainwasherPro")
BrainwasherPro:SaveCurrentSpec(1);BrainwasherProDB.specs[1].name="A";BrainwasherProDB.specs[1].propertiesPreset="治疗"
talentRanks={{0,5},{0,0},{0,0}}
BrainwasherPro:SaveCurrentSpec(2);BrainwasherProDB.specs[2].name="B";BrainwasherProDB.specs[2].propertiesPreset="防御"
local player="测试角色 of 测试服"
ABP_Layout[player]={A={spells={[5]={name="天赋A",rank="等级 1"}}},B={spells={}}}
local talentCalls,loadCalls,wearCalls,flushInventory,flushBags=0,0,0,0,0
local gt,load=GetTalentInfo,ABP_LoadProfile
function GetTalentInfo(...) talentCalls=talentCalls+1;return gt(unpack(arg)) end
function ABP_LoadProfile(...) loadCalls=loadCalls+1;return load(unpack(arg)) end
local function tick(seconds)
 for i=1,math.ceil(seconds/0.05) do
  now=now+0.05;controller:Fire("OnUpdate")
  if P.speedUpdater and now>=(P.speedUpdater.testNextTick or 0) then
   P.speedUpdater.testNextTick=now+P.speedUpdater.interval;P.speedUpdater.callback()
  end
 end
end
talentRanks={{5,0},{0,0},{0,0}};signal("PLAYER_ENTERING_WORLD");tick(0.6)
check(slots[5] and slots[5].name=="天赋A" and loadCalls==1,"ready no-equipment switch finishes within 0.6 simulated seconds")
talentCalls=0;tick(2)
check(talentCalls==0 and loadCalls==1,"idle coordinator reads no talents between safety checks")
tick(3)
check(talentCalls<=9 and loadCalls==1,"low-frequency safety check reads live talents once, without reapplying")

local outfitA={Name="A",Items={HeadSlot={Name="headA",Code=200},Trinket0Slot={Name="trinketA",Code=201}}}
local outfitB={Name="B",Items={HeadSlot={Name="headB",Code=300},Trinket0Slot={Name="trinketB",Code=301}}}
gOutfitter_Settings={Outfits={Complete={outfitA,outfitB}}}
local equipped={[1]=200,[13]=201};local delayed=false;local skipHead=false
function GetInventorySlotInfo(name) return ({HeadSlot=1,Trinket0Slot=13})[name] end
function GetInventoryItemLink(_,slot) return equipped[slot] and "item:"..equipped[slot]..":0:0:0" end
function OutfitterItemList_FlushInventoryFromEquippableItems() flushInventory=flushInventory+1 end
function OutfitterItemList_FlushBagFromEquippableItems() flushBags=flushBags+1 end
function Outfitter_WearOutfit(outfit,category)
 check(category=="Complete","retry retains outfit category")
 wearCalls=wearCalls+1
 if not delayed then
  if not skipHead then equipped[1]=outfit.Items.HeadSlot.Code end
  equipped[13]=outfit.Items.Trinket0Slot.Code
 end
end
function Outfitter_ForceEquipNow() end
local before=loadCalls
talentRanks={{0,5},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.6)
check(wearCalls==1 and loadCalls==before+1 and slots[5]==nil,"ready outfit proceeds without fixed head/equipment waits")
check(flushInventory==1 and flushBags==0,"successful outfit invalidates only inventory subcache")
ABP_Layout[player].A.items={[6]="饰品"}
delayed=true;before=loadCalls
talentRanks={{5,0},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.5)
check(loadCalls==before+1 and slots[5].name=="天赋A" and slots[6]==nil,"core actions precede delayed outfit; item restore waits")
equipped[1]=200;signal("UNIT_INVENTORY_CHANGED","player");tick(0.3)
check(loadCalls==before+1 and slots[6]==nil,"head alone does not release item restore")
equipped[13]=201;signal("UNIT_INVENTORY_CHANGED","player");tick(0.3)
check(loadCalls==before+2 and slots[5].name=="天赋A" and slots[6].name=="饰品","last equipment slot releases item-only restoration")

-- Old pending outfit must not restore its bars after a newer talent event.
before=loadCalls
talentRanks={{0,5},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.4)
talentRanks={{5,0},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.6)
check(loadCalls==before+3 and slots[5].name=="天赋A","cancelled B job cannot clear A actions after switching back")

-- Retry a missed head, and verify again rather than declaring success on an attempt.
delayed=false;skipHead=true
function GetContainerNumSlots(bag) return bag==0 and 1 or 0 end
function GetContainerItemLink() return "item:300:0:0:0" end
function PickupContainerItem() cursor={kind="item",name="headB"} end
function EquipCursorItem(slot) equipped[slot]=300;cursor=nil end
before=loadCalls;local beforeWear=wearCalls;local beforeBags=flushBags
talentRanks={{0,5},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(1.4)
check(loadCalls==before+1 and equipped[1]==300 and wearCalls==beforeWear+2,"bounded retry and head fallback complete latest job")
check(flushBags==beforeBags+5,"all five bags invalidated only on missed outfit retry")

gOutfitter_Settings=nil;spellBook={{name="通用",rank="等级 1"}}
before=loadCalls
talentRanks={{5,0},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(2.5)
check(loadCalls-before<=10 and slots[5]==nil,"short skill settling retries are bounded and leave old talent skill cleared")
check(P.displayConfig=="治疗" and P.pendingRefreshAt==nil,"panel finishes independently of missing spellbook: "..tostring(P.displayConfig).." / "..tostring(P.pendingRefreshAt).." / "..tostring(P.showWindow))
spellBook[2]={name="天赋A",rank="等级 1"};signal("SPELLS_CHANGED");tick(0.4)
check(slots[5] and slots[5].name=="天赋A","spell event resumes pending job promptly")

-- Intentionally omit the talent event: the low-frequency fallback still recovers.
talentRanks={{0,5},{0,0},{0,0}};tick(3.6)
check(slots[5]==nil and P.displayConfig=="防御","missed talent event is covered by idle safety check")
gOutfitter_Settings={Outfits={Complete={outfitA,outfitB}}};delayed=true
before=loadCalls
talentRanks={{5,0},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.5)
check(loadCalls==before+1 and slots[5].name=="天赋A","missing outfit never holds up usable talent actions")
tick(9)
check(loadCalls==before+2 and slots[5].name=="天赋A","missing outfit wait ends and item stage restores without reloading skills")
local warned=false
for _,msg in ipairs(messages) do if string.find(msg,"部分装备未到位",1,true) then warned=true end end
check(warned,"incomplete outfit is reported instead of being claimed as equipped")
print("PASS: "..passed.." coordinator performance and race checks")
''')

# Character panel event storms are coalesced too, even while its window is open.
rt.execute(BCS)
rt.execute(r'''
local statsCalls=0
BCS.PaperDollFrame=CreateFrame("Frame");BCS.PaperDollFrame:Show()
function BCS:IsCharacterPanelEnabled() return true end
function BCS:InvalidateStatsCaches() end
function BCS:UpdateStats() statsCalls=statsCalls+1 end
for i=1,12 do event="UNIT_INVENTORY_CHANGED";arg1="player";BCS:OnEvent() end
assert(statsCalls==0,"gear event burst does not rebuild synchronously")
now=now+0.13;BCS.statsUpdateFrame:Fire("OnUpdate")
assert(statsCalls==1 and not BCS.statsUpdateFrame:IsShown(),"one scheduled rebuild after burst; idle frame hidden")
BCS.PaperDollFrame:Hide();BCS:RequestStatsUpdate()
assert(statsCalls==1 and BCS.needUpdate,"closed character panel does not recalculate")
''')
print('PASS: character panel event burst coalescing and closed-panel behavior')
print('All timing and work counts are simulated; in-game frame time remains unmeasured.')
