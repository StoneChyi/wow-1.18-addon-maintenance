"""Login/reload must not enforce talent outfits; active switches still do."""
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

def runtime():
    rt = LuaRuntime(unpack_returned_tuples=True)
    for code in (literal('test_bcs_float.py', 'STUB'), literal('test_talent_preset_sync.py', 'GAME_STUB')):
        rt.execute(code)
    for path in ('BetterCharacterStats/BCS_PropertiesPanel.lua', 'ActionBarProfiles/ActionBarProfiles.lua',
                 'BrainwasherPro/BrainwasherPro.lua'):
        rt.execute((ROOT / 'Interface/AddOns' / path).read_text(encoding='utf-8-sig'))
    rt.execute(r'''
BCSConfig={};BCS.PropertiesPanel:Init();initABP()
for _,f in ipairs(allFrames) do if f.events and f.events.GOSSIP_SHOW then controller=f end end
function signal(ev,unit) event=ev;arg1=unit;controller:Fire("OnEvent") end
function tick(seconds,spellEvents)
 for i=1,math.ceil(seconds/0.05) do
  now=now+0.05
  if spellEvents then signal("SPELLS_CHANGED") end
  controller:Fire("OnUpdate")
 end
end
signal("ADDON_LOADED","BrainwasherPro")
BrainwasherPro:SaveCurrentSpec(1)
BrainwasherProDB.specs[1].name="A";BrainwasherProDB.specs[1].propertiesPreset="防御"
talentRanks={{0,5},{0,0},{0,0}};BrainwasherPro:SaveCurrentSpec(2)
BrainwasherProDB.specs[2].name="B";BrainwasherProDB.specs[2].propertiesPreset="治疗"
talentRanks={{5,0},{0,0},{0,0}}
ABP_Layout["测试角色 of 测试服"]={A={spells={[1]={name="通用",rank="等级 1"}}},B={spells={}}}
slots={[1]={kind="spell",name="旧按钮"}}
gOutfitter_Settings={Outfits={Complete={
 {Name="A",Items={HeadSlot={Name="headA",Code=200}}},
 {Name="B",Items={HeadSlot={Name="headB",Code=300}}},
}}}
currentHead=100;wearLog={};forceCalls=0;matchReads=0;cacheFlushes=0
function GetInventorySlotInfo() return 1 end
function GetInventoryItemLink(_,slot)
 if slot==1 then matchReads=matchReads+1;return "item:"..currentHead..":0:0:0" end
end
function Outfitter_WearOutfit(outfit) table.insert(wearLog,outfit.Name);currentHead=outfit.Items.HeadSlot.Code end
function Outfitter_ForceEquipNow() forceCalls=forceCalls+1 end
function OutfitterItemList_FlushInventoryFromEquippableItems() cacheFlushes=cacheFlushes+1 end
function OutfitterItemList_FlushBagFromEquippableItems() cacheFlushes=cacheFlushes+1 end
messages={}
''')
    return rt

rt = runtime()
rt.execute(r'''
signal("PLAYER_ENTERING_WORLD");tick(12,true)
check(#wearLog==0 and forceCalls==0 and cacheFlushes==0,"login and late spell events never schedule an outfit")
check(matchReads==0 and currentHead==100,"login never reads actual head to compare the saved outfit")
check(not contains(table.concat(messages,"\n"),"装备未到位"),"login never emits outfit mismatch diagnostics")
check(slots[1].name=="通用" and BCS.PropertiesPanel.displayConfig=="防御","existing login bar/panel restoration remains")
signal("UNIT_INVENTORY_CHANGED","player");signal("BAG_UPDATE",0)
signal("PLAYER_ENTERING_WORLD");tick(5,true)
check(#wearLog==0 and matchReads==0,"bag/inventory events, zoning and idle safety checks do not re-enable login matching")

-- Exercise the actual confirmation callback, even for the same talent slot.
NUMGOSSIPBUTTONS=1
local button=CreateFrame("Button","GossipTitleButton1")
button:SetText("启用第1天赋");button:Show();local clicked=0
button:SetScript("OnClick",function() clicked=clicked+1 end)
BrainwasherPro:ParseGossipOptions();BrainwasherPro.currentSlotAction=1
StaticPopupDialogs.BRAINWASHERPRO_LOAD_SPEC.OnAccept();tick(0.7)
check(clicked==1 and #wearLog==1 and wearLog[1]=="A" and currentHead==200,
 "explicit enable of the same slot still switches its equipment")
talentRanks={{0,5},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.7)
check(#wearLog==2 and wearLog[2]=="B" and currentHead==300,"real later talent change still links its outfit")
talentRanks={{5,0},{0,0},{0,0}};tick(3.7)
check(#wearLog==3 and wearLog[3]=="A","missed later talent event is still covered by the safety check")
print("PASS: "..passed.." login suppression and active-switch checks")
''')

# A new addon session, as on /reload, must suppress gear enforcement again.
rt = runtime()
rt.execute(r'''
signal("PLAYER_ENTERING_WORLD");tick(15,true)
check(#wearLog==0 and matchReads==0 and currentHead==100,"reload starts with equipment matching suppressed")
-- A late first successful identification is still part of login, not a switch.
print("PASS: reload suppression check")
''')
rt = runtime()
rt.execute(r'''
talentRanks={{2,3},{0,0},{0,0}};signal("PLAYER_ENTERING_WORLD");tick(4)
talentRanks={{5,0},{0,0},{0,0}};signal("SPELLS_CHANGED");tick(10,true)
check(#wearLog==0 and matchReads==0,"late first login match is still suppressed")
talentRanks={{0,5},{0,0},{0,0}};signal("CHARACTER_POINTS_CHANGED");tick(0.7)
check(#wearLog==1 and wearLog[1]=="B","subsequent actual slot change enables normal outfit linking")
print("PASS: late login identification and subsequent switch checks")
''')
print('Mocked Lua 5.1 game APIs only; no running game or saved variables were changed.')
