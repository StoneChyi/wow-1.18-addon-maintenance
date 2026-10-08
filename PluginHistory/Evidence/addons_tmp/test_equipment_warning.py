"""Report actual outfit mismatches after timeout; never operates a running game."""
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

rt = LuaRuntime(unpack_returned_tuples=True)
for code in (literal('test_bcs_float.py', 'STUB'), literal('test_talent_preset_sync.py', 'GAME_STUB'),
             (ROOT / 'Interface/AddOns/ActionBarProfiles/ActionBarProfiles.lua').read_text(encoding='utf-8-sig'),
             (ROOT / 'Interface/AddOns/BrainwasherPro/BrainwasherPro.lua').read_text(encoding='utf-8-sig')):
    rt.execute(code)
rt.execute(r'''
initABP()
local controller
for _,f in ipairs(allFrames) do if f.events and f.events.GOSSIP_SHOW then controller=f end end
event="ADDON_LOADED";arg1="BrainwasherPro";controller:Fire("OnEvent")
BrainwasherPro:SaveCurrentSpec(1);BrainwasherProDB.specs[1].name="装备诊断"
ABP_Layout["测试角色 of 测试服"]={ ["装备诊断"]={spells={}} }
local slotIDs={HeadSlot=1,ChestSlot=5,LegsSlot=7,FeetSlot=8,Trinket0Slot=13,MainHandSlot=16}
function GetInventorySlotInfo(name) return slotIDs[name] end
local worn={
 [1]="|cffa335ee|Hitem:100:0:0:0|h[旧头盔]|h|r",
 [5]="|cffa335ee|Hitem:105:0:0:0|h[正确胸甲]|h|r",
 [7]="|cffa335ee|Hitem:104:0:0:0|h[应卸下的护腿]|h|r",
 [13]="|cffa335ee|Hitem:103:0:-7:0|h[随机属性饰品]|h|r",
 [16]="|cffa335ee|Hitem:102:222:0:0|h[同一武器]|h|r",
}
function GetInventoryItemLink(_,slot) return worn[slot] end
gOutfitter_Settings={Outfits={Complete={{Name="装备诊断",Items={
 HeadSlot={Code=101,Name="目标头盔"},ChestSlot={Code=105,Name="正确胸甲"},
 LegsSlot={Code=0},FeetSlot={Code=106},Trinket0Slot={Code=103,SubCode=-5,Name="随机属性饰品"},
 MainHandSlot={Code=102,EnchantCode=111,Name="同一武器"},
}}}}}
function Outfitter_WearOutfit() end
function Outfitter_ForceEquipNow() end
messages={}
event="PLAYER_ENTERING_WORLD";controller:Fire("OnEvent")
BrainwasherPro:SaveCurrentSpec(1) -- explicit action; login itself skips outfits
for i=1,100 do now=now+0.1;controller:Fire("OnUpdate") end
local text=table.concat(messages,"\n")
check(contains(text,"套装“装备诊断”部分装备未到位"),"timeout names the exact outfit")
check(contains(text,"头部：目标 目标头盔（ID：101）") and contains(text,"[旧头盔]")
 and contains(text,"原因：物品不同"),"different item reports slot, target ID and current item link")
check(contains(text,"主手：目标 同一武器（ID：102）")
 and contains(text,"附魔不同（预设：111，当前：222）"),"same item with changed enchant is clearly distinguished")
check(contains(text,"饰品1：目标 随机属性饰品")
 and contains(text,"随机属性不同（预设：-5，当前：-7）"),"signed random-property identifiers reported")
check(contains(text,"腿部：目标 空槽（卸下装备）") and contains(text,"预设要求卸下"),"empty target reports required unequip")
check(contains(text,"脚部：目标 未知装备（ID：106）；当前 空槽；原因：当前槽位为空"),"missing item name falls back to ID")
check(not contains(text,"胸部：") and not contains(text,"可能缺失或被锁定"),"matching gear excluded; no unconfirmed lock diagnosis")
check(#messages==6,"one header and exactly five mismatched slot messages")
check(contains(messages[2],"头部：") and contains(messages[3],"腿部：")
 and contains(messages[4],"脚部：") and contains(messages[5],"饰品1：")
 and contains(messages[6],"主手："),"diagnostics sort by actual equipment slot")
local count=#messages
for i=1,30 do now=now+0.1;controller:Fire("OnUpdate") end
check(#messages==count,"completed job does not repeat diagnostics during idle checks")

-- Exact same outfit becomes valid after correcting the five mismatches.
worn[1]="item:101:0:0:0";worn[7]=nil;worn[8]="item:106:0:0:0"
worn[13]="item:103:0:-5:0";worn[16]="item:102:111:0:0"
messages={};BrainwasherPro:SaveCurrentSpec(1)
for i=1,100 do now=now+0.1;controller:Fire("OnUpdate") end
check(not contains(table.concat(messages,"\n"),"部分装备未到位"),"corrected item/enchant/subcode passes the same matching predicate")
print("PASS: "..passed.." equipment diagnostic checks")
''')
print('Lua 5.1 with mocked equipment links and game time; no live game actions.')
