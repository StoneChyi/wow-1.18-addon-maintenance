"""Ready talent actions must not wait for missing skills or slow equipment."""
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

def source(addon, name):
    return (ROOT / 'Interface/AddOns' / addon / name).read_text(encoding='utf-8-sig')

UI = literal('test_bcs_float.py', 'STUB')
GAME = literal('test_talent_preset_sync.py', 'GAME_STUB')
ABP = source('ActionBarProfiles', 'ActionBarProfiles.lua')
BRAIN = source('BrainwasherPro', 'BrainwasherPro.lua')
PANEL = source('BetterCharacterStats', 'BCS_PropertiesPanel.lua')

rt = LuaRuntime(unpack_returned_tuples=True)
for code in (UI, GAME, r'''
function GetActionText(i)
 local a=slots[i];if not a then return nil end
 return a.kind=="macro" and a.name or nil,string.upper(a.kind),a.kind=="item" and 13446 or 1
end
function HasAction(i) return slots[i] and slots[i].count~=0 end
''', ABP):
    rt.execute(code)
rt.execute(r'''
initABP();local player="测试角色 of 测试服"
local profile={spells={[1]={name="通用",rank="等级 1"},[2]={name="天赋A",rank="等级 1"},
 [3]={name="迟到技能",rank="等级 1"}},macros={[4]="普通宏"},items={[5]="药水"},itemInfo={[5]={id=13446}}}
ABP_Layout[player].target=profile
local zero={kind="item",name="药水",count=0}
slots={[1]={kind="spell",name="错误技能"},[2]={kind="macro",name="旧宏"},
 [3]={kind="spell",name="旧天赋技能"},[5]=zero,[6]={kind="spell",name="旧天赋技能"}}
local gearReads,bagReads,bookReads=0,0,0
local flyoutUpdates=0
function Flyout_GetActionButton() return {} end
function Flyout_UpdateBars() flyoutUpdates=flyoutUpdates+1 end
local eq,bag,spell=ABP_Tooltip.SetInventoryItem,ABP_Tooltip.SetBagItem,GetSpellName
function ABP_Tooltip:SetInventoryItem(...) gearReads=gearReads+1;return eq(self,unpack(arg)) end
function ABP_Tooltip:SetBagItem(...) bagReads=bagReads+1;return bag(self,unpack(arg)) end
function GetSpellName(...) bookReads=bookReads+1;return spell(unpack(arg)) end
local ok,report=ABP_LoadProfile("target",{quiet=true,phase="core",deferMissingSpells=true,allowPartialSpells=true})
check(ok and slots[1].name=="通用" and slots[2].name=="天赋A" and slots[4].name=="普通宏",
 "ready skills and macros load despite another missing skill")
check(slots[3]==nil and slots[6]==nil and report.pendingSpells[3],"obsolete talent skill and target empty slot clear immediately")
check(slots[5]==zero and report.hasItems,"zero-stock native item survives the core phase")
check(gearReads==0 and bagReads==0,"core phase performs no equipment or bag scans")
check(#messages==0,"partial core restore does not claim the whole profile is complete")
local manuallyChanged={kind="spell",name="手动按钮"};slots[1]=manuallyChanged
spellBook[3]={name="迟到技能",rank="等级 1"}
ok,report=ABP_LoadProfile("target",{quiet=true,phase="core",slots=report.pendingSpells,allowPartialSpells=true})
check(ok and slots[3].name=="迟到技能" and not next(report.pendingSpells),"late spell fills its pending slot")
check(slots[1]==manuallyChanged and slots[5]==zero,"selective retry leaves all non-pending slots untouched")
bookReads=0;bagItems={};equipment={}
ok,report=ABP_LoadProfile("target",{quiet=true,phase="items"})
check(ok and slots[5]==zero and slots[1]==manuallyChanged,"item phase preserves zero item and unrelated manual action")
check(bookReads==0,"item phase never rescans the skillbook")
profile.spells[3].name="永久缺失"
ok,report=ABP_LoadProfile("target",{quiet=true,phase="core",slots={[3]=true},allowPartialSpells=true})
check(ok and slots[3]==nil and report.pendingSpells[3],"newly missing spell is a pending empty slot")
local beforeFlyouts=flyoutUpdates
ok,report=ABP_LoadProfile("target",{quiet=true,phase="core",slots=report.pendingSpells,allowPartialSpells=true})
check(ok and flyoutUpdates==beforeFlyouts,"unavailable single-slot retry does not rebuild Flyout bars")
ok,report=ABP_LoadProfile("target",{quiet=true,phase="core",slots=report.pendingSpells})
check(ok and #report.missing==1 and not next(report.pendingSpells),"deadline reports only the genuinely missing slot")
check(slots[1]==manuallyChanged and slots[5]==zero,"deadline never reloads other slots")
profile.spells[121]={name="特殊栏"};profile.items[133]="越界物品"
ok,report=ABP_LoadProfile("target",{phase="core",quiet=true,allowPartialSpells=true})
check(ok and report.ignoredSlots[121] and report.ignoredSlots[133],"phased restore keeps legacy-slot protection")
cursor={kind="item",name="玩家光标"};local held=cursor
ok,report=ABP_LoadProfile("target",{phase="items",quiet=true})
check(not ok and report=="cursor" and cursor==held,"item phase never takes a player-held cursor")
cursor=nil;combat=true
ok,report=ABP_LoadProfile("target",{phase="core",quiet=true,allowPartialSpells=true})
check(not ok and report=="combat","core phase respects combat protection")
print("PASS: "..passed.." phased action restoration checks")
''')

# Actual SuperMacro wrappers must retain their virtual-only button semantics.
rt.execute('combat=false;SM_ACTION={};SM_SUPER={["超级宏"]={"超级宏","icon","/test"}};'
           'function GetSuperMacroInfo(name,code) if SM_SUPER[name] then return SM_SUPER[name][2] end end')
rt.execute(source('SuperMacro', 'SM_Super.lua'))
rt.execute(r'''
slots={};SM_ACTION[9]="超级宏"
assert(ABP_SaveProfile("virtual"))
SM_ACTION={}
local ok,report=ABP_LoadProfile("virtual",{phase="core",quiet=true,allowPartialSpells=true})
assert(ok and GetActionText(9)=="超级宏" and SM_CURSOR==nil,"core restores actual virtual-only SuperMacro")
ok,report=ABP_LoadProfile("virtual",{phase="items",quiet=true})
assert(ok and GetActionText(9)=="超级宏" and SM_CURSOR==nil,"item phase leaves SuperMacro untouched")
ABP_Layout["测试角色 of 测试服"].empty={spells={}}
ok,report=ABP_LoadProfile("empty",{phase="core",quiet=true,allowPartialSpells=true})
assert(ok and SM_ACTION[9]==nil and SM_CURSOR==nil,"core clears virtual-only obsolete macro")
''')
print('PASS: actual SuperMacro core restore, item-phase isolation and obsolete virtual macro clear')

rt = LuaRuntime(unpack_returned_tuples=True)
for code in (UI, GAME, PANEL, ABP, BRAIN):
    rt.execute(code)
rt.execute(r'''
BCSConfig={};local P=BCS.PropertiesPanel;P:Init();initABP();passed=0
local controller
for _,f in ipairs(allFrames) do if f.events and f.events.GOSSIP_SHOW then controller=f end end
local function signal(ev,unit) event=ev;arg1=unit;controller:Fire("OnEvent") end
signal("ADDON_LOADED","BrainwasherPro")
BrainwasherPro:SaveCurrentSpec(1);BrainwasherProDB.specs[1].name="A"
talentRanks={{0,5},{0,0},{0,0}}
BrainwasherPro:SaveCurrentSpec(2);BrainwasherProDB.specs[2].name="B";BrainwasherProDB.specs[2].propertiesPreset="防御"
local player="测试角色 of 测试服"
ABP_Layout[player]={
 A={spells={[1]={name="天赋A",rank="等级 1"}}},
 B={spells={[1]={name="通用",rank="等级 1"},[2]={name="迟到技能",rank="等级 1"}},
    macros={[3]="普通宏"},items={[7]="饰品"}},
}
slots={[1]={kind="spell",name="天赋A",rank="等级 1"},[2]={kind="spell",name="旧天赋技能"},
 [4]={kind="spell",name="旧天赋技能"},[7]={kind="spell",name="旧天赋技能"}}
local equippedHead=100;local wearCalls=0;local restoreCalls=0;local spellPlacements=0
local log={};local realLoad=ABP_LoadProfile;local realSpell=PickupSpell
function ABP_LoadProfile(name,opts)
 restoreCalls=restoreCalls+1;table.insert(log,{kind="bars",phase=opts.phase,time=now,name=name})
 return realLoad(name,opts)
end
function PickupSpell(...) spellPlacements=spellPlacements+1;return realSpell(unpack(arg)) end
function GetInventorySlotInfo() return 1 end
function GetInventoryItemLink(_,slot) return slot==1 and "item:"..equippedHead..":0:0:0" or nil end
gOutfitter_Settings={Outfits={Complete={{Name="B",Items={HeadSlot={Name="headB",Code=300}}},
 {Name="A",Items={HeadSlot={Name="headA",Code=200}}}}}}
function Outfitter_WearOutfit(outfit)
 wearCalls=wearCalls+1;table.insert(log,{kind="wear",time=now,name=outfit.Name})
 -- Deliberately leave the gear unsettled for more than five seconds.
end
function Outfitter_ForceEquipNow() end
local function tick(duration,churn)
 for i=1,math.ceil(duration/0.05) do
  now=now+0.05
  if churn then signal("SPELLS_CHANGED") end
  controller:Fire("OnUpdate")
  if P.speedUpdater and now>=(P.speedUpdater.testNext or 0) then
   P.speedUpdater.testNext=now+0.2;P.speedUpdater.callback()
  end
 end
end
local start=now
signal("PLAYER_ENTERING_WORLD");BrainwasherPro:SaveCurrentSpec(2);tick(0.6,true)
check(slots[1].name=="通用" and slots[3].name=="普通宏" and slots[4]==nil,
 "usable bar is ready within 0.6 simulated seconds despite continuous spell events and stalled equipment")
check(slots[2]==nil and slots[7]==nil,"pending skill and deferred item leave no wrong old skill")
local firstWear
for _,entry in ipairs(log) do if entry.kind=="wear" then firstWear=entry;break end end
check(log[1].kind=="bars" and log[1].phase=="core" and firstWear
 and firstWear.time>log[1].time,"core actions precede heavy equipment work on a later update")
local afterReady=spellPlacements
spellBook[3]={name="迟到技能",rank="等级 1"};tick(0.35) -- no event: short settling fallback
check(slots[2] and slots[2].name=="迟到技能","late skill is detected quickly even if its event is missed")
check(spellPlacements==afterReady+1,"only the pending spell is placed on retry")
tick(4.5,true)
check(now-start>5 and slots[1].name=="通用" and slots[2].name=="迟到技能" and slots[7]==nil,
 "five seconds of stalled gear never delay or reload core actions")
check(wearCalls==2,"unsettled outfit retries only once")
equippedHead=300;equipment[13]=nil;equipment[14]="饰品"
signal("UNIT_INVENTORY_CHANGED","player");local beforeItems=spellPlacements;tick(0.35)
check(slots[7] and slots[7].name=="饰品","item button restores from post-equipment position")
check(spellPlacements==beforeItems and log[#log].phase=="items","gear completion never replaces ready spells again")
local settledCalls=restoreCalls;tick(2,true)
check(restoreCalls==settledCalls,"later spell events do not reapply a completed profile")

-- A pending B skill must not reappear after selecting A.
spellBook[3]=nil;talentRanks={{5,0},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.6)
talentRanks={{0,5},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.5)
check(slots[2]==nil,"new B attempt has a pending skill")
talentRanks={{5,0},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.5)
spellBook[3]={name="迟到技能",rank="等级 1"};signal("SPELLS_CHANGED");tick(0.5)
check(slots[1].name=="天赋A" and slots[2]==nil,"cancelled pending B slot never appears in A")
print("PASS: "..passed.." slow-outfit, continuous-event and priority coordination checks")
''')
print('Lua 5.1 and simulated game time/API counters only; no live game actions.')
