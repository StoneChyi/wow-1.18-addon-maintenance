"""Reject API access outside 1..120; load legacy 121..144 records safely."""
from pathlib import Path
import ast
import sys

ROOT = Path(r'E:\1.18')
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

def literal(file, name):
    tree = ast.parse((ROOT / 'addons_tmp' / file).read_text(encoding='utf-8-sig'))
    return next(ast.literal_eval(node.value) for node in tree.body if isinstance(node, ast.Assign)
                and any(isinstance(target, ast.Name) and target.id == name for target in node.targets))

runtime = LuaRuntime(unpack_returned_tuples=True)
runtime.execute(literal('test_bcs_float.py', 'STUB'))
runtime.execute(literal('test_talent_preset_sync.py', 'GAME_STUB'))
runtime.execute(r'''
actionCalls={};maxReadSlot=0
for _,name in ipairs({"HasAction","GetActionTexture","GetActionText","PickupAction","PlaceAction"}) do
    local method=name
    local original=_G[method]
    _G[method]=function(slot,...)
        assert(type(slot)=="number" and slot>=1 and slot<=120 and slot==math.floor(slot),method.." touched invalid action slot "..tostring(slot))
        maxReadSlot=math.max(maxReadSlot,slot)
        actionCalls[method]=(actionCalls[method] or 0)+1
        return original(slot,unpack(arg))
    end
end
''')
source = (ROOT / 'Interface/AddOns/ActionBarProfiles/ActionBarProfiles.lua').read_text(encoding='utf-8-sig')
runtime.compile(source)
runtime.execute(source)
runtime.execute(r'''
initABP()
local player="测试角色 of 测试服"
local reserved121={kind="item",name="越界幻影图标"}
local reserved133={kind="spell",name="特殊栏"}
local reserved144={kind="macro",name="插件记录"}
slots={[1]={kind="spell",name="通用",rank="等级 1"},[120]={kind="spell",name="通用",rank="等级 1"},
       [121]=reserved121,[133]=reserved133,[144]=reserved144}
check(ABP_SaveProfile("Normal"),"save never queries invalid native slots")
check(maxReadSlot==120 and ABP_Layout[player].Normal.spells[120]~=nil,"slot 120 remains supported")
check(ABP_Layout[player].Normal.items[121]==nil and ABP_Layout[player].Normal.spells[133]==nil,"new saves omit reserved slots")
check(slots[121]==reserved121 and slots[133]==reserved133 and slots[144]==reserved144,"saving leaves special and phantom slot state untouched")
ABP_Layout[player].Legacy={
    spells={[1]={name="通用",rank="等级 1"},[120]={name="通用",rank="等级 1"},
            [121]={name="未学习的越界技能",rank="等级 99"},[132]=false},
    macros={[130]="不存在的越界宏",[134]={old="legacy"}},
    items={[133]="不存在的越界物品",[144]=false},
    itemInfo={[122]=false,[133]={id=-1},[144]="old"},
}
local legacy=ABP_Layout[player].Legacy
local ok,report=ABP_LoadProfile("Legacy",{deferMissingSpells=true})
check(ok and #report.missing==0,"legacy out-of-range missing spells cannot delay or break valid restore")
check(slots[1].name=="通用" and slots[120].name=="通用","legacy profile restores both valid boundaries")
check(report.ignoredSlots[121] and report.ignoredSlots[130] and report.ignoredSlots[133] and report.ignoredSlots[144],"121 and 130-plus records are reported as ignored")
check(slots[121]==reserved121 and slots[133]==reserved133 and slots[144]==reserved144,"load never mutates phantom or special slots")
check(legacy.spells[121].name=="未学习的越界技能" and legacy.items[133]=="不存在的越界物品","loading preserves legacy saved data")
ABP_Layout[player].OnlyLegacy={spells={[121]=false},items={[139]="物品"},macros={[144]="宏"}}
check(ABP_LoadProfile("OnlyLegacy") and slots[1]==nil and slots[120]==nil,"legacy-only profile still clears truly empty valid action slots")
check(slots[121]==reserved121 and slots[133]==reserved133,"empty valid snapshot does not clear special slots")
ABP_Layout[player].Broken={spells={[120]={name=false},[121]={name="忽略"}}}
slots[120]={kind="spell",name="必须保留"};local before=slots[120]
ok,report=ABP_LoadProfile("Broken")
check(not ok and report=="invalid_profile" and slots[120]==before,"invalid content inside valid range still rejected before mutation")
ABP_Layout[player].TooLarge={items={[145]="不是旧版槽位"}}
ok,report=ABP_LoadProfile("TooLarge")
check(not ok and report=="invalid_profile" and slots[120]==before,"unknown out-of-range records are rejected safely")
ABP_Layout[player].Fraction={items={[120.5]="坏槽位"}}
ok,report=ABP_LoadProfile("Fraction")
check(not ok and report=="invalid_profile","fractional slot keys are rejected")
check(cursor==nil and autoSelfCast=="1","cleanup restores cursor and self-cast setting")
print("PASS: "..passed.." action slot boundary and legacy compatibility checks")
''')
print('Every mocked action API rejects access outside 1..120; no live game actions.')
