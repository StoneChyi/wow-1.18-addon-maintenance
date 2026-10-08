"""Behavioral checks with mocked WoW APIs; never sends chat or controls the game."""
from pathlib import Path
import ast
import sys

ROOT = Path(r'E:\1.18')
sys.path.insert(0, str(ROOT / 'addons_tmp' / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

base_tree = ast.parse((ROOT / 'addons_tmp' / 'test_bcs_float.py').read_text(encoding='utf-8-sig'))
UI_STUB = next(ast.literal_eval(n.value) for n in base_tree.body
               if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'STUB' for t in n.targets))

GAME_STUB = r'''
StaticPopupDialogs={}; SAVE="保存"; CANCEL="取消"
NUM_BAG_SLOTS=4; MAX_SKILLLINE_TABS=4
messages={}; slots={}; cursor=nil; combat=false; autoSelfCast="1"
spellBook={{name="通用",rank="等级 1"},{name="天赋A",rank="等级 1"}}
normalMacros={[1]="普通宏"}; bagItems={[0]={[1]="药水"}}; equipment={[13]="饰品"}
function DEFAULT_CHAT_FRAME:AddMessage(msg) table.insert(messages,msg) end
function GetCVar(key) if key=="realmName" then return "测试服" end; return autoSelfCast end
function SetCVar(key,value) if key=="autoSelfCast" then autoSelfCast=value end end
function UnitAffectingCombat() return combat end
function CursorHasItem() return cursor and cursor.kind=="item" end
function CursorHasSpell() return cursor and cursor.kind=="spell" end
function CursorHasMacro() return cursor and cursor.kind=="macro" end
function ClearCursor() cursor=nil end
function HasAction(i) return slots[i]~=nil end
function GetActionText(i) return slots[i] and slots[i].kind=="macro" and slots[i].name or nil end
function GetActionTexture(i) return slots[i] and "icon" or nil end
function UseAction() end
function PickupAction(i) cursor=slots[i];slots[i]=nil end
function PlaceAction(i) if cursor then local old=slots[i];slots[i]=cursor;cursor=old end end
function PickupSpell(i) local s=spellBook[i];if s then cursor={kind="spell",name=s.name,rank=s.rank} end end
function PickupMacro(i) if normalMacros[i] then cursor={kind="macro",name=normalMacros[i]} end end
function GetMacroIndexByName(name) for i,n in pairs(normalMacros) do if n==name then return i end end;return 0 end
function GetMacroInfo(i) return normalMacros[i],"Interface\\Icons\\INV_MISC_QUESTIONMARK" end
function GetNumMacros() return table.getn(normalMacros),0 end
function EditMacro() end
function GetSpellTabInfo(tab) if tab==1 then return "测试",nil,0,table.getn(spellBook) end end
function GetSpellName(i) if spellBook[i] then return spellBook[i].name,spellBook[i].rank end end
function PickupInventoryItem(i) if equipment[i] then cursor={kind="item",name=equipment[i]} end end
function GetContainerNumSlots(bag) return bagItems[bag] and table.getn(bagItems[bag]) or 0 end
function GetContainerItemInfo(bag,slot) if bagItems[bag] and bagItems[bag][slot] then return "icon" end end
function PickupContainerItem(bag,slot) if bagItems[bag] and bagItems[bag][slot] then cursor={kind="item",name=bagItems[bag][slot]} end end
function GetInventoryItemLink(unit,slot) if slot==1 and headCode then return "item:"..headCode..":0" end end
function GetInventorySlotInfo() return 1 end
function GetContainerItemLink() return nil end
function GetMacroIconInfo() return "icon" end
function GetNumMacroIcons() return 1 end
function GetTalentTabInfo(tab) local total=0;for _,count in ipairs(talentRanks[tab]) do total=total+count end;return "树"..tab,nil,total end
function GetTalentInfo(tab,i) local count=talentRanks[tab][i];if count~=nil then return "天赋"..tab..":"..i,"icon",1,i,count,5 end end
talentRanks={{5,0},{0,0},{0,0}}
function GetInventoryItemTexture() return "icon" end

local meta=getmetatable(UIParent).__index
function meta:GetTexture() return self.texture end
function meta:SetTexture(v) self.texture=v end
function meta:IsVisible() return self.visible end
function meta:SetScrollChild(child) self.child=child end
function meta:RegisterEvent(ev) self.events=self.events or {}; self.events[ev]=true end
function meta:GetParent() return self.parent end
function meta:Click() self:Fire("OnClick") end
for _,name in ipairs({"SetNormalTexture","SetPushedTexture","SetHighlightTexture","RegisterForClicks"}) do meta[name]=function() end end
allFrames={}
local oldCreateFrame=CreateFrame
function CreateFrame(kind,name,parent,template)
    local frame=oldCreateFrame(kind,name,parent,template);frame.parent=parent;table.insert(allFrames,frame);return frame
end
function UIDropDownMenu_Initialize(menu,fn) menu.initialize=fn end
function UIDropDownMenu_AddButton(info) table.insert(menuEntries,info) end
function CloseDropDownMenus() end
function StaticPopup_Show() end
menuEntries={}
ABP_Tooltip=CreateFrame("GameTooltip","ABP_Tooltip")
ABP_TooltipTextLeft1=CreateFrame("FontString","ABP_TooltipTextLeft1")
ABP_TooltipTextRight1=CreateFrame("FontString","ABP_TooltipTextRight1")
function ABP_Tooltip:ClearLines() ABP_TooltipTextLeft1:SetText("");ABP_TooltipTextRight1:SetText("") end
function ABP_Tooltip:SetAction(i) local a=slots[i];if a then ABP_TooltipTextLeft1:SetText(a.name);ABP_TooltipTextRight1:SetText(a.rank or "") end end
function ABP_Tooltip:SetInventoryItem(unit,i) if equipment[i] then ABP_TooltipTextLeft1:SetText(equipment[i]);return true end end
function ABP_Tooltip:SetBagItem(bag,i) ABP_TooltipTextLeft1:SetText(bagItems[bag][i]) end
ABP_DropDownMenu=CreateFrame("Frame","ABP_DropDownMenu")
function initABP() ABPButton_UpdatePosition=function() end;event="VARIABLES_LOADED";ABP_OnEvent() end
passed=0
function check(condition,label) assert(condition,label);passed=passed+1 end
function contains(text,part) return string.find(text,part,1,true)~=nil end
'''

ABP_TESTS = r'''
initABP()
local player="测试角色 of 测试服"
slots={[1]={kind="spell",name="通用",rank="等级 1"},[5]={kind="spell",name="天赋A",rank="等级 1"},
       [6]={kind="macro",name="普通宏"},[7]={kind="item",name="饰品"},[8]={kind="item",name="药水"},
       [120]={kind="spell",name="通用",rank="等级 1"}}
select=nil -- 原生 Lua 5.0 没有 select，保存和物品扫描也必须可用。
check(ABP_SaveProfile("A"),"save all supported action kinds")
slots[5]=nil;slots[6]=nil;slots[7]=nil;slots[8]=nil;slots[120]=nil
check(ABP_SaveProfile("B"),"save empty slots in legacy-compatible format")
check(ABP_LoadProfile("A"),"restore A")
check(slots[5].name=="天赋A" and slots[6].name=="普通宏","spell and macro placement")
check(slots[7].name=="饰品" and slots[8].name=="药水","equipped and bag item placement")
check(slots[120].name=="通用","last valid action slot restoration")
check(ABP_LoadProfile("B"),"restore B")
check(slots[5]==nil and slots[6]==nil and slots[7]==nil and slots[8]==nil and slots[120]==nil,"clear all target-empty slots")
check(ABP_LoadProfile("A") and slots[5].name=="天赋A","switch back restores omitted skill")
check(cursor==nil and autoSelfCast=="1","cursor and self cast restored")
spellBook={{name="通用",rank="等级 1"}};local old5=slots[5]
local ok,reason=ABP_LoadProfile("A",{deferMissingSpells=true})
check(not ok and reason=="spells_pending" and slots[5]==old5,"preflight waits without clearing any action")
normalMacros={};bagItems={};equipment={}
slots[7]={kind="spell",name="无关技能"};slots[8]={kind="macro",name="无关宏"}
ok,reason=ABP_LoadProfile("A")
check(ok and table.getn(reason.missing)==4,"missing spell macro and items reported")
check(slots[5]==nil and slots[6]==nil and slots[7]==nil and slots[8]==nil,"missing target leaves no unrelated old skill")
cursor={kind="item",name="dragged"};local held=cursor
ok,reason=ABP_LoadProfile("B")
check(not ok and reason=="cursor" and cursor==held,"player cursor left untouched")
check(not ABP_SaveProfile("B") and ABP_Layout[player].B~=nil,"busy save preserves profile")
cursor=nil;combat=true
ok,reason=ABP_LoadProfile("B")
check(not ok and reason=="combat","combat mutation blocked")
combat=false
ABP_Layout[player].Bad={spells={[5]={name=false}}}
old5={kind="spell",name="old"};slots[5]=old5
ok,reason=ABP_LoadProfile("Bad")
check(not ok and reason=="invalid_profile" and slots[5]==old5,"invalid profile cannot clear actions")
ABP_Layout[player].Bad="bad"
ok,reason=ABP_LoadProfile("Bad")
check(not ok and reason=="invalid_profile","non-table profile rejected")
local oldPlace=PlaceAction
PlaceAction=function() error("simulated placement failure") end
slots[1]={kind="spell",name="错误技能",rank="等级 1"}
ok,reason=ABP_LoadProfile("B")
check(not ok and reason=="runtime_error" and autoSelfCast=="1" and cursor==nil,"failed load restores temporary state")
local oldProfile=ABP_Layout[player].B
slots[1]={kind="spell",name="通用",rank="等级 1"}
check(not ABP_SaveProfile("B") and ABP_Layout[player].B==oldProfile,"failed save never overwrites existing snapshot")
PlaceAction=oldPlace
ABP_Layout[player].Bad={spells=false}
ok,reason=ABP_LoadProfile("Bad")
check(not ok and reason=="invalid_profile","malformed false table is not treated as empty snapshot")
local oldPickup=PickupAction;PickupAction=function() end
slots[1]={kind="spell",name="错误技能",rank="等级 1"}
ok,reason=ABP_LoadProfile("B")
check(not ok and reason=="runtime_error","failed clearing cannot report complete success")
PickupAction=oldPickup
normalMacros={[1]="普通宏"}
print("PASS: "..passed.." action profile behavioral checks")
'''

SUPER_TESTS = r'''
SM_ACTION={};SM_SUPER={["超级宏"]={"超级宏","Interface\\Icons\\INV_MISC_QUESTIONMARK","/test"}}
function GetSuperMacroInfo(name,code) if SM_SUPER[name] then return SM_SUPER[name][2] end end
'''
SUPER_ASSERTIONS = r'''
slots={};SM_ACTION[5]="超级宏";slots[5]={kind="macro",name="普通宏"}
check(ABP_SaveProfile("Super"),"save real SuperMacro hook action")
check(ABP_LoadProfile("B") and SM_ACTION[5]==nil and SM_CURSOR==nil,"clear SuperMacro including virtual cursor")
check(ABP_LoadProfile("Super") and GetActionText(5)=="超级宏","restore SuperMacro through actual wrappers")
check(SM_ACTION[1]==nil and SM_CURSOR==nil,"virtual cursor cannot contaminate another slot")
normalMacros={};slots={};SM_ACTION={[5]="超级宏"}
check(ABP_SaveProfile("Virtual"),"save virtual-only macro without native carrier")
check(ABP_LoadProfile("B") and SM_ACTION[5]==nil,"clear virtual-only SuperMacro")
check(ABP_LoadProfile("Virtual") and GetActionText(5)=="超级宏" and SM_CURSOR==nil,"restore virtual-only SuperMacro")
print("PASS: 7 real SuperMacro wrapper checks")
'''

SYNC_TESTS = r'''
BCSConfig={};BCS.PropertiesPanel:Init();initABP()
local P=BCS.PropertiesPanel
local controller
for _,f in ipairs(allFrames) do if f.events and f.events.GOSSIP_SHOW then controller=f end end
check(controller~=nil,"controller registered")
event="ADDON_LOADED";arg1="BrainwasherPro";controller:Fire("OnEvent")
BrainwasherPro.UpdateSpecDisplay=function() end -- 主窗口在本测试中未创建。
BrainwasherPro:SaveCurrentSpec(1)
BrainwasherProDB.specs[1].name="A";BrainwasherProDB.specs[1].propertiesPreset="治疗"
talentRanks={{0,5},{0,0},{0,0}};BrainwasherPro:SaveCurrentSpec(2)
BrainwasherProDB.specs[2].name="B";BrainwasherProDB.specs[2].propertiesPreset="防御"
ABP_Layout["测试角色 of 测试服"]={
 A={spells={[1]={name="通用",rank="等级 1"},[5]={name="天赋A",rank="等级 1"}}},
 B={spells={[1]={name="通用",rank="等级 1"}}}}
local fixtureTalents
function tick(count)
 local signature=table.concat(talentRanks[1],",")..":"..table.concat(talentRanks[2],",")..":"..table.concat(talentRanks[3],",")
 if signature~=fixtureTalents then
  fixtureTalents=signature;event="CHARACTER_POINTS_CHANGED";controller:Fire("OnEvent")
 end
 for i=1,count do now=now+0.3;controller:Fire("OnUpdate") end
end
function world() event="PLAYER_ENTERING_WORLD";controller:Fire("OnEvent") end
local realLoad=ABP_LoadProfile;loadLog={}
ABP_LoadProfile=function(name,opts) local ok,reason=realLoad(name,opts);table.insert(loadLog,{name=name,ok=ok});return ok,reason end
talentRanks={{5,0},{0,0},{0,0}};world();tick(5)
check(P.displayConfig=="治疗" and slots[5].name=="天赋A","login detects full talents without gossip")
check(#loadLog==1,"one complete restore without blind delayed reload")
world();tick(4)
check(#loadLog==1,"zoning does not reapply unchanged action profile")
talentRanks={{0,5},{0,0},{0,0}};tick(5)
check(P.displayConfig=="防御" and slots[5]==nil,"same total talent points distinguish exact builds")
talentRanks={{5,0},{0,0},{0,0}};tick(1);talentRanks={{0,5},{0,0},{0,0}};tick(5)
check(P.displayConfig=="防御" and slots[5]==nil,"rapid unstable switch only applies latest build")
for i=3,#loadLog do check(loadLog[i].name=="B","no outdated A reload") end
local before=#loadLog;cursor={kind="item",name="held"}
talentRanks={{5,0},{0,0},{0,0}};tick(5)
check(P.displayConfig=="治疗" and #loadLog==before,"panel independent while action cursor busy")
cursor=nil;tick(2)
check(slots[5].name=="天赋A" and #loadLog==before+1,"pending actions resume after releasing cursor")
combat=true;talentRanks={{0,5},{0,0},{0,0}};before=#loadLog;tick(5)
check(#loadLog==before and slots[5]~=nil,"combat defers action clearing")
combat=false;tick(2);check(slots[5]==nil,"combat exit resumes full restore")
ABP_Layout["测试角色 of 测试服"].A=nil
talentRanks={{5,0},{0,0},{0,0}};tick(5)
check(P.displayConfig=="治疗" and slots[1].name=="通用","missing action profile still switches panel and preserves actions")
P:SelectConfig("防御")
BrainwasherPro:OnEditClicked(1)
local editor=BrainwasherProEditFrame
check(editor.propertiesPreset=="治疗","editing retrieves saved preset")
menuEntries={};editor.presetMenu.initialize()
check(#menuEntries==8,"dropdown includes seven presets and no-switch option")
for _,entry in ipairs(menuEntries) do if entry.text=="自定义" then entry.func() end end
editor.nameEdit:SetText("改名A");BrainwasherPro:ConfirmEdit();tick(5)
check(BrainwasherProDB.specs[1].propertiesPreset=="自定义" and P.displayConfig=="自定义","slot binding survives rename and applies immediately")
check(not P.customFrame:IsShown(),"automatic custom selection never opens editor")
local savedProfile=P:EnsureProfile("自定义");savedProfile.props.fireRes=true
P:SelectConfig("防御",true);P:SelectConfig("自定义",true)
check(P:EnsureProfile("自定义").props.fireRes,"edited preset properties retained")
P.showWindow=false;P.frame:Hide();local point=P.frame.point;local locked=P.locked
P:SelectConfig("治疗",true)
check(not P.frame:IsShown() and P.frame.point==point and P.locked==locked,"silent selection preserves visibility position and lock")
check(not P:SelectConfig("未知",true) and P.displayConfig=="治疗","invalid preset leaves configuration unchanged")
BrainwasherPro:OnEditClicked(1);menuEntries={};editor.presetMenu.initialize()
for _,entry in ipairs(menuEntries) do if entry.text=="不切换" then entry.func() end end
BrainwasherPro:ConfirmEdit();tick(5)
check(BrainwasherProDB.specs[1].propertiesPreset==nil and P.displayConfig=="治疗","no-switch retains manually selected panel")
local previous=slots[1];before=#loadLog
talentRanks={{2,3},{0,0},{0,0}};tick(6)
check(#loadLog==before and slots[1]==previous,"unmatched talents never clear actions")
talentRanks={{5,0},{0,0},{0,0}}
BrainwasherProDB.specs[3]=BrainwasherProDB.specs[1]
BrainwasherPro.activeSpecSlot=nil;world();tick(5)
check(#loadLog==before,"ambiguous duplicate builds do not auto-apply")
BrainwasherProDB.specs[3]=nil
ABP_Layout["测试角色 of 测试服"]["改名A"]={spells={[5]={name="天赋A",rank="等级 1"}}}
spellBook={{name="通用",rank="等级 1"}};world();event="CHARACTER_POINTS_CHANGED";controller:Fire("OnEvent");before=#loadLog;tick(5)
check(slots[1]==nil and slots[5]==nil,"unready target skill is empty while other target slots already update")
spellBook[2]={name="天赋A",rank="等级 1"};event="SPELLS_CHANGED";controller:Fire("OnEvent");tick(4)
check(slots[5].name=="天赋A" and slots[1]==nil,"skillbook readiness resumes pending latest plan")
check(loadLog[#loadLog].ok,"only confirmed success finishes load")

-- 技能/宏/空格优先；物品按钮在换装后单独恢复。
gOutfitter_Settings={Outfits={Complete={
 {Name="B",Items={HeadSlot={Name="头B",Code=300}}},
 {Name="改名A",Items={HeadSlot={Name="头A",Code=200}}}}}}
wearLog={};headCode=100
function Outfitter_WearOutfit(outfit) table.insert(wearLog,outfit.Name);headCode=outfit.Items.HeadSlot.Code;equipment[13]=nil;equipment[14]="饰品" end
function Outfitter_ForceEquipNow() end
local oldInventoryPickup=PickupInventoryItem
function PickupInventoryItem(i) lastInventoryPickup=i;oldInventoryPickup(i) end
ABP_Layout["测试角色 of 测试服"]["改名A"].items={[6]="饰品"}
before=#loadLog;talentRanks={{0,5},{0,0},{0,0}};tick(2)
check(wearLog[1]==nil and #loadLog==before+1 and slots[5]==nil,"core actions restore before outfit work")
before=#loadLog
talentRanks={{5,0},{0,0},{0,0}};tick(12)
check(wearLog[#wearLog]=="改名A" and slots[5].name=="天赋A","latest switch coordinates equipment and actions")
for i=before+1,#loadLog do check(loadLog[i].name=="改名A","old pending B cannot restore after switching A") end
check(slots[6].name=="饰品" and lastInventoryPickup==14,"item mapping built after equipment has moved")
check(headCode==200,"outdated head check cannot equip previous build")
gOutfitter_Settings=nil

-- 等待技能书有上限；确认仍缺失后清空旧技能并给出缺失报告。
ABP_Layout["测试角色 of 测试服"].B.spells[5]={name="不存在技能",rank="等级 1"}
talentRanks={{0,5},{0,0},{0,0}};tick(5)
check(slots[5]==nil and slots[1].name=="通用","missing skill does not retain old talent skill or block ready actions")
tick(30)
check(slots[5]==nil and loadLog[#loadLog].ok,"deadline resolves unavailable skills without old residue")
BrainwasherProDB.specs[1].propertiesPreset="防御"
print("PASS: "..passed.." talent and property panel integration checks")
'''

abp_source = (ROOT / 'Interface/AddOns/ActionBarProfiles/ActionBarProfiles.lua').read_text(encoding='utf-8-sig')
brain_source = (ROOT / 'Interface/AddOns/BrainwasherPro/BrainwasherPro.lua').read_text(encoding='utf-8-sig')
panel_source = (ROOT / 'Interface/AddOns/BetterCharacterStats/BCS_PropertiesPanel.lua').read_text(encoding='utf-8-sig')
for source in (abp_source, brain_source, panel_source):
    LuaRuntime().compile(source)
print('PASS: all three modified files compile with Lua 5.1')

runtime = LuaRuntime(unpack_returned_tuples=True)
for source in (UI_STUB, GAME_STUB, abp_source, ABP_TESTS, SUPER_TESTS,
               (ROOT / 'Interface/AddOns/SuperMacro/SM_Super.lua').read_text(encoding='utf-8-sig'), SUPER_ASSERTIONS):
    runtime.execute(source)

runtime = LuaRuntime(unpack_returned_tuples=True)
for source in (UI_STUB, GAME_STUB, panel_source, abp_source, brain_source, SYNC_TESTS):
    runtime.execute(source)

def snapshot(value):
    if hasattr(value, 'items'):
        return {key: snapshot(item) for key, item in value.items()}
    return value

saved_brain = snapshot(runtime.globals().BrainwasherProDB)
saved_panel = snapshot(runtime.globals().BCSConfig)
reloaded = LuaRuntime(unpack_returned_tuples=True)
for source in (UI_STUB, GAME_STUB):
    reloaded.execute(source)

def restore(value):
    if isinstance(value, dict):
        return reloaded.table_from({key: restore(item) for key, item in value.items()})
    return value

reloaded.globals().BrainwasherProDB = restore(saved_brain)
reloaded.globals().BCSConfig = restore(saved_panel)
for source in (panel_source, brain_source):
    reloaded.execute(source)
reloaded.execute(r'''
local P=BCS.PropertiesPanel;P:Init()
local controller
for _,f in ipairs(allFrames) do if f.events and f.events.GOSSIP_SHOW then controller=f end end
event="ADDON_LOADED";arg1="BrainwasherPro";controller:Fire("OnEvent")
event="PLAYER_ENTERING_WORLD";controller:Fire("OnEvent")
for i=1,5 do now=now+0.3;controller:Fire("OnUpdate") end
assert(BrainwasherProDB.specs[1].name=="改名A", "renamed slot persists")
assert(BrainwasherProDB.specs[1].propertiesPreset=="防御" and P.displayConfig=="防御", "binding survives reload and works without ABP")
assert(P:EnsureProfile("自定义").props.fireRes, "custom preset changes survive reload")
assert(P.locked==BCSConfig.PropertiesPanel.locked, "panel lock setting remains intact")
print("PASS: 4 saved-variable reload checks")
''')
print('All checks use mocked game APIs; live game verification remains necessary.')
