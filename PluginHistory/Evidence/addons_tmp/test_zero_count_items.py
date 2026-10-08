"""Zero-stock action preservation and placeholder behavior, using mocked WoW APIs."""
from pathlib import Path
import ast
import sys

ROOT = Path(r'E:\1.18')
sys.path.insert(0, str(ROOT / 'addons_tmp' / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

def literal(file, variable):
    tree = ast.parse((ROOT / 'addons_tmp' / file).read_text(encoding='utf-8-sig'))
    return next(ast.literal_eval(n.value) for n in tree.body if isinstance(n, ast.Assign)
                and any(isinstance(t, ast.Name) and t.id == variable for t in n.targets))

runtime = LuaRuntime(unpack_returned_tuples=True)
runtime.execute(literal('test_bcs_float.py', 'STUB'))
runtime.execute(literal('test_talent_preset_sync.py', 'GAME_STUB'))
runtime.execute(r'''
catalog={["药水"]=13446,["食物"]=13930,["另一物品"]=17031}
macroBodies={};createdCount=0;macroMode="normal";classicOnly=false
function HasAction(i) return slots[i] and slots[i].count~=0 end
function GetActionTexture(i) return slots[i] and not slots[i].noTexture and "icon" or nil end
function GetActionText(i)
    local a=slots[i]
    if not a then return nil end
    local name=a.kind=="macro" and a.name or nil
    if classicOnly then return name end
    return name,string.upper(a.kind),a.kind=="item" and catalog[a.name] or 1
end
function GetItemInfo(name)
    if catalog[name] then return name,"item:"..catalog[name]..":0:0:0" end
end
function GetMacroInfo(i) return normalMacros[i],"icon",macroBodies[i] end
function CreateMacro(name,icon,body,isLocal,perCharacter)
    assert(isLocal==nil,"vanilla fourth argument must be isLocal")
    assert(type(perCharacter)=="boolean","vanilla fifth argument must select character macros")
    if macroMode=="full" or (macroMode=="accountOnly" and perCharacter) then error("macro slots full") end
    local i=37+createdCount;normalMacros[i]=name;macroBodies[i]=body
    createdCount=createdCount+1;lastCreatedCharacter=perCharacter
    return i
end
function GetActionCount(i)
    local a=slots[i];if not a then return 0 end
    if a.kind=="item" then return a.count or 1 end
    local index=GetMacroIndexByName(a.name);local body=macroBodies[index] or ""
    local _,_,id=string.find(body,"^/tooltip item:(%d+)")
    if id then
        for name,itemId in pairs(catalog) do
            if tostring(itemId)==id then
                for _,bag in pairs(bagItems) do for _,item in pairs(bag) do if item==name then return 1 end end end
                return 0
            end
        end
    end
    return 0
end
''')
source = (ROOT / 'Interface/AddOns/ActionBarProfiles/ActionBarProfiles.lua').read_text(encoding='utf-8-sig')
runtime.compile(source)
runtime.execute(source)
runtime.execute(r'''
initABP();bagItems={};equipment={}
local player="测试角色 of 测试服"
slots={[5]={kind="item",name="药水",count=0},[6]={kind="item",name="食物",count=0},[7]={kind="spell",name="通用",rank="等级 1"}}
local potion,food=slots[5],slots[6]
select=nil
check(ABP_SaveProfile("Zero"),"save depleted item actions without Lua 5.1 select")
local profile=ABP_Layout[player].Zero
check(profile.items[5]=="药水" and profile.items[6]=="食物","zero items are recorded despite HasAction returning false")
check(profile.itemInfo[5].id==13446 and profile.itemInfo[6].texture=="icon","save item IDs and icon metadata")
check(slots[5]==potion and slots[6]==food,"saving does not remove depleted item buttons")
local ok,report=ABP_LoadProfile("Zero")
check(ok and slots[5]==potion and slots[6]==food,"matching native zero buttons survive reload intact")
check(report.preservedItems==2 and #report.missing==0 and createdCount==0,"existing zero buttons require no macros")
slots[5]=nil;slots[6]={kind="spell",name="无关技能"}
ok,report=ABP_LoadProfile("Zero")
check(ok and report.placeholders==2 and #report.missing==0,"restore absent zero items as item placeholders")
check(createdCount==2 and lastCreatedCharacter,"prefer character-only macros with correct five-argument API")
local macroIndex=GetMacroIndexByName(slots[5].name)
check(string.find(macroBodies[macroIndex],"/tooltip item:13446\n/",1,true)==1,"placeholder includes SuperWoW item tooltip and count metadata")
check(GetActionCount(5)==0 and GetActionCount(6)==0,"depleted placeholders represent zero stock")
check(ABP_SaveProfile("ZeroAgain"),"resave placeholders")
check(ABP_Layout[player].ZeroAgain.items[5]=="药水" and ABP_Layout[player].ZeroAgain.macros[5]==nil,"placeholders serialize as items, not ordinary macros")
check(ABP_Layout[player].ZeroAgain.itemInfo[5].id==13446,"placeholder ID survives resaving")
ok,report=ABP_LoadProfile("ZeroAgain")
check(ok and createdCount==2 and report.preservedItems==2,"repeated loading reuses placeholders")
bagItems={[0]={[1]="药水"}}
check(GetActionCount(5)==1,"placeholder reflects restocked item")
ok,report=ABP_LoadProfile("ZeroAgain")
check(ok and slots[5].kind=="item" and slots[5].name=="药水" and report.placeholders==0,"restocked item returns to native action while other placeholder remains")
ABP_Layout[player].Empty={spells={},items={},macros={}}
slots[9]={kind="item",name="食物",count=0}
check(ABP_LoadProfile("Empty") and slots[5]==nil and slots[6]==nil and slots[9]==nil,"genuinely empty target clears both zero native items and placeholders")
bagItems={};normalMacros={};macroBodies={};createdCount=0
normalMacros[1]="ABPi13446";macroBodies[1]="/say 玩家原有宏"
check(ABP_LoadProfile("Zero") and macroBodies[1]=="/say 玩家原有宏","never overwrite colliding player macro")
check(slots[5].name=="ABPi13446_1","resolve managed macro name collision")
slots={};macroMode="accountOnly"
ABP_Layout[player].AccountFallback={items={[10]="另一物品"}}
check(ABP_LoadProfile("AccountFallback") and slots[10] and lastCreatedCharacter==false,"fall back to account macro when character macro space is full")
slots={};macroMode="full"
ABP_Layout[player].Full={items={[11]="全新物品"}}
ok,report=ABP_LoadProfile("Full")
check(ok and #report.missing==1 and contains(report.missing[1],"宏栏空间"),"full macro slots produce explicit failure rather than silent omission")
check(ABP_Layout[player].Full.items[11]=="全新物品","failed placeholder creation never deletes saved item reference")
macroMode="normal";classicOnly=true
slots={[12]={kind="item",name="药水",count=0}}
check(ABP_SaveProfile("VanillaZero") and ABP_Layout[player].VanillaZero.items[12]=="药水","vanilla single-return API saves zero items by icon and tooltip")
check(ABP_LoadProfile("VanillaZero") and slots[12].kind=="item","vanilla zero item retained")
classicOnly=false;slots={[13]={kind="item",name="食物",count=0,noTexture=true}}
check(ABP_SaveProfile("ExtendedZero") and ABP_Layout[player].ExtendedZero.items[13]=="食物","extended ITEM metadata prevents omission even without icon or HasAction")
cursor={kind="item",name="拖动物品"};local held=cursor
check(not ABP_LoadProfile("Zero") and cursor==held,"new placeholder path never steals a held item")
cursor=nil
print("PASS: "..passed.." zero-count item checks")
''')

# Exercise the real SuperMacro wrappers after the addon captured the native interface.
runtime.execute('SM_ACTION={};function GetSuperMacroInfo() return nil end')
runtime.execute((ROOT / 'Interface/AddOns/SuperMacro/SM_Super.lua').read_text(encoding='utf-8-sig'))
runtime.execute(r'''
slots={};bagItems={};normalMacros[1]="普通宏"
local ok,report=ABP_LoadProfile("Zero")
assert(ok and report.placeholders==2 and SM_CURSOR==nil,"normal placeholder macros work through real SuperMacro wrappers")
assert(ABP_SaveProfile("SuperWrappedZero") and ABP_Layout["测试角色 of 测试服"].SuperWrappedZero.items[5]=="药水","wrapped placeholder resaves as item")
print("PASS: 2 zero-count SuperMacro compatibility checks")
''')
print('Compiled and checked with Lua 5.1 and simulated vanilla/SuperWoW interfaces; no live game actions.')
