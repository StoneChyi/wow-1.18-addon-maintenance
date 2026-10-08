from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

SOURCE = Path(r'E:\1.18\Interface\AddOns\BetterCharacterStats\BCS_PropertiesPanel.lua').read_text(encoding='utf-8-sig')
STUB = r'''
now = 10
api = {dodge=12.34, parry=15.67, block=20.89, armor=6500, speed=7}
calls = {dodge=0, parry=0, block=0, helperBlock=0, fonts=0, body=0}
STANDARD_TEXT_FONT = "Fonts\\ARIALN.ttf"
RAID_CLASS_COLORS = {PALADIN={r=1,g=0.6,b=0.8}}
SlashCmdList = {}
BOOKTYPE_SPELL = "spell"
function UnitClass() return "圣骑士", "PALADIN" end
function UnitName() return "测试角色" end
function UnitExists(unit) return unit == "player" or (unit == "target" and api.targetLevel ~= nil) end
function UnitLevel(unit) if unit == "target" then return api.targetLevel end; return api.playerLevel or 60 end
function GetTime() return now end
function UnitAttackPower() return 100, 20, -5 end
function UnitRangedAttackPower() return 120, 10, -2 end
function UnitAttackSpeed() return 2.4, 1.8 end
function UnitRangedDamage() return 2.6 end
function UnitArmor() return 1000, api.armor, 3000 end
function UnitDefense() return 300, 120 end
function UnitResistance(unit, school)
    local resist = {[2]=100,[3]=70,[4]=50,[5]=30,[6]=20}
    return 5, resist[school], 0, 0
end
function GetDodgeChance() calls.dodge=calls.dodge+1; return api.dodge end
function GetParryChance() calls.parry=calls.parry+1; return api.parry end
function GetBlockChance() calls.block=calls.block+1; return api.block end
function UnitXP() return api.speed end
function getglobal(name) return _G[name] end
function SendChatMessage() error("Tests must never send chat messages") end
function TextNoColors(s) return (string.gsub(string.gsub(s or "", "|c%x%x%x%x%x%x%x%x", ""), "|r", "")) end
local Object = {}
Object.__index = Object
function Object:SetWidth(v) self.width=v end
function Object:GetWidth() return self.width or 140 end
function Object:SetHeight(v) self.height=v end
function Object:GetHeight() return self.height or 20 end
function Object:SetScale(v) self.scale=v end
function Object:SetFont(path, size) self.fontSize=size; calls.fonts=calls.fonts+1 end
function Object:SetText(v) self.text=tostring(v or "") end
function Object:GetText() return self.text or "" end
function Object:SetPoint(...) self.point={...} end
function Object:GetPoint() return "CENTER", UIParent, "CENTER", 350, -100 end
function Object:ClearAllPoints() self.point=nil end
function Object:GetLeft() return 415 end
function Object:GetRight() return 865 end
function Object:SetScript(event, fn) self.scripts[event]=fn end
function Object:Fire(event)
    if self.scripts[event] then
        local previous=this; this=self
        self.scripts[event]()
        this=previous
    end
end
function Object:Show() local previous=self.visible; self.visible=true; if not previous then self:Fire("OnShow") end end
function Object:Hide() local previous=self.visible; self.visible=false; if previous then self:Fire("OnHide") end end
function Object:IsShown() return self.visible end
function Object:EnableMouse(v) self.mouseEnabled=v end
function Object:Enable() self.enabled=true end
function Object:Disable() self.enabled=false end
function Object:GetName() return self.name end
function Object:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
function Object:SetValueStep(v) self.step=v end
function Object:SetValue(v) local old=self.value; self.value=math.max(self.minimum or v,math.min(self.maximum or v,v)); if old~=self.value then self:Fire("OnValueChanged") end end
function Object:GetValue() return self.value or 0 end
function Object:SetFocus() self.focused=true end
function Object:ClearFocus() local old=self.focused;self.focused=false;if old then self:Fire("OnEditFocusLost") end end
function Object:StartMoving() self.moving=true end
function Object:StopMovingOrSizing() self.moving=false end
function Object:SetSpacing(v) self.spacing=v end
function Object:GetStringHeight()
    local clean=TextNoColors(self.text)
    if clean=="" then return 0 end
    local lines=0
    for s in string.gmatch(clean,"[^\n]+") do
        local chars=0;for _ in string.gmatch(s,"[\1-\127\194-\244]") do chars=chars+1 end
        lines=lines+math.max(1,math.ceil(chars*(self.fontSize or 13)*0.65/(self.width or 140)))
    end
    return lines*(self.fontSize or 13)+(lines-1)*(self.spacing or 0)
end
function Object:AddMessage(text) self.lastMessage=text end
local noops={"SetMovable","SetAlpha","SetFrameStrata","RegisterForDrag","SetBackdrop","SetBackdropColor","SetBackdropBorderColor","SetTexture","SetAllPoints","SetVertexColor","SetTextColor","SetJustifyH","SetJustifyV","SetOwner","AddLine","RegisterEvent","SetAutoFocus","SetNumeric","SetMaxLetters","HighlightText","SetClampedToScreen"}
for _, key in ipairs(noops) do Object[key]=function() end end
local function object(kind,name)
    local item=setmetatable({kind=kind,name=name,scripts={},visible=true},Object)
    if name then _G[name]=item end
    return item
end
function Object:CreateTexture() return object("Texture") end
function Object:CreateFontString() return object("FontString") end
function CreateFrame(kind,name,parent,template)
    local item=object(kind,name)
    if template=="OptionsSliderTemplate" then
        for _,suffix in ipairs({"Text","Low","High"}) do object("FontString",name..suffix) end
    end
    return item
end
UIParent=CreateFrame("Frame","UIParent");UIParent:SetWidth(1280);UIParent:SetHeight(720)
GameTooltip=CreateFrame("GameTooltip","GameTooltip")
DEFAULT_CHAT_FRAME=CreateFrame("Frame","ChatFrame1")
function UIDropDownMenu_SetWidth(width,menu) menu:SetWidth(width) end
function UIDropDownMenu_Initialize(menu,fn) menu.initialize=fn; fn() end
function UIDropDownMenu_AddButton(info) end
function UIDropDownMenu_SetText(text,menu) menu:SetText(text) end
C_Timer={NewTicker=function(interval,fn) return {interval=interval, callback=fn,Cancel=function(t) t.cancelled=true end} end}
ItemSocre={ScanUnit=function() return 70 end}
BCS={}
function BCS:IsNampowerReady() return false end
function BCS:GetSpellPower() return 500, 20, "火焰", 50 end
function BCS:GetHealingPower() return 350 end
function BCS:GetManaRegen() return 10, 20, 50 end
function BCS:GetCritChance() return 22.5 end
function BCS:GetRangedCritChance() return 24.5 end
function BCS:GetHitRating() return 6 end
function BCS:GetRangedHitRating() return 7 end
function BCS:GetSpellCritChance() return 18.5 end
function BCS:GetSpellHitRating() return 8, 1, 0, 0, 0, 0 end
function BCS:EstimateHaste() return 5 end
function BCS:GetHaste() return 5 end
function BCS:GetArmorPenetrationValue() return 100 end
function BCS:GetBlockValue() calls.helperBlock=calls.helperBlock+1; return 220 end
'''

TESTS = r'''
local P=BCS.PropertiesPanel
local passed=0
local function check(condition,label)
    assert(condition,label)
    passed=passed+1
end
local function plain(text) return TextNoColors(text) end
local function contains(text,part) return string.find(text,part,1,true) ~= nil end
local function click(button) button:Fire("OnClick") end
local function countText(text,word) local _,n=string.gsub(text,word,word);return n end

check(BCSConfig==nil, "file loading must not create saved configuration")
BCSConfig={PropertiesPanel={point="CENTER",rel_point="CENTER",x_offset=200,y_offset=-90,
    displayConfig="防御",locked=true,customProps={ap=true,fireRes=true,speed=false},enabled=true}}
P:Init()
check(P:GetTitleKey()=="three", "defense preset uses three dimensions as title")
check(table.concat(P:GetSelectedKeys(),",")=="three,armor,armorDR,defense,dodge,parry,block,speed", "new defense preset replaces hit and adds armor reduction")
check(P.frame.mouseEnabled==false and P.lockButton.enabled==false and P.unlockButton.enabled==true, "saved lock state synchronizes UI immediately")
check(BCSConfig.PropertiesPanel.x_offset==200, "position survives initialization")
local initCalls=BCSConfig.PropertiesPanel.profiles["防御"].props
check(initCalls.hit==nil, "defense preset excludes hit by default")

P:SelectConfig("自定义")
check(table.concat(P:GetSelectedKeys(),",")=="ap,fireRes", "legacy custom selections and disabled speed migrate")
check(P:GetTitleKey()=="ap", "legacy first selected item remains title")
P:SelectConfig("防御")
P:ShowCustomWindow(true)
local rowByKey={};for _,row in ipairs(P.customRows) do rowByKey[row.key]=row end
check(#P.customRows==30, "all thirty available properties have checkboxes")
click(rowByKey.fireRes)
check(P:EnsureProfile().props.fireRes==true, "add resistance to a preset")
P:SelectConfig("物理")
check(not P:EnsureProfile().props.fireRes, "presets keep independent selections")
P:SelectConfig("防御")
check(P:EnsureProfile().props.fireRes, "switching restores edited preset")
P:SetTitleKey("fireRes")
local title,details=P:GetDisplayLines()
check(plain(title)=="火抗: 100" and not contains(plain(details),"火抗"), "selected title is shown only once")
P:MoveProperty("fireRes",-1)
check(P:GetSelectedKeys()[8]=="fireRes", "move selected property up")
click(rowByKey.fireRes)
check(P:EnsureProfile().titleKey=="auto", "removing title selects automatic fallback")
P:SetTitleKey("three")

check(P:DisplayThreeDimensions()=="三维: 48.90%", "three dimensions sum unrounded values")
api.dodge,api.parry,api.block=1.234,2.234,3.234
check(P:DisplayThreeDimensions()=="三维: 6.70%", "round only after summing")
api.dodge,api.parry,api.block=40,40,30
check(P:DisplayThreeDimensions()=="三维: 110.00%", "three dimensions are not capped at one hundred")
api.dodge,api.parry,api.block=8.12,0,0
check(P:DisplayThreeDimensions()=="三维: 8.12%", "zero chance is valid")
api.parry=nil
check(contains(P:DisplayThreeDimensions(),"数据不可用"), "nil chance does not become a false zero")
api.parry=0/0
check(contains(P:DisplayThreeDimensions(),"数据不可用"), "NaN chance is rejected")
local old=GetParryChance;GetParryChance=function() error("missing") end
check(contains(P:DisplayThreeDimensions(),"数据不可用"), "API failure is handled")
GetParryChance=old
api.dodge,api.parry,api.block=12.34,15.67,20.89
calls.dodge,calls.parry,calls.block=0,0,0
BCS.ForceCalculate=false
P:BuildBody()
check(calls.dodge==1 and calls.parry==1 and calls.block==1, "individual chances and total share one rebuild snapshot")
check(BCS.ForceCalculate==false and P.defenseSnapshot==nil, "calculation state is restored")
check(P:DisplayResistance(2,"火抗")=="火抗: 100" and P:DisplayResistance(6,"奥抗")=="奥抗: 20", "resistance uses effective value and classic school indices")
check(P:DisplayArmor()=="护甲: 6500", "armor uses effective value rather than third return")
BCSConfig.PropertiesPanel.reductionLevel=70
check(P:DisplayArmorReduction()=="减伤: 54.17%", "no target uses player level and ignores saved manual reference")
api.targetLevel=63
check(P:DisplayArmorReduction()=="减伤: 53.04%", "current target level with percentage-only output")
api.targetLevel=50
check(P:DisplayArmorReduction()=="减伤: 58.30%", "changing target level changes reduction")
api.targetLevel=-1
check(P:DisplayArmorReduction()=="减伤: 53.04%", "question-mark target uses player level plus three")
api.playerLevel=50
check(P:DisplayArmorReduction()=="减伤: 56.99%", "question-mark reference follows player level")
api.playerLevel=0
check(P:DisplayArmorReduction()=="减伤: 数据不可用", "question-mark target with invalid player level remains unavailable")
api.playerLevel=nil
api.targetLevel=0
check(P:DisplayArmorReduction()=="减伤: 数据不可用", "invalid target level is not confused with question-mark sentinel")
api.targetLevel=nil
check(P:DisplayArmorReduction()=="减伤: 54.17%", "clearing target restores player-level reference")
P:GetDisplayLines()
api.targetLevel=-1
P.frame.scripts.OnEvent(P.frame,"PLAYER_TARGET_CHANGED")
local targetFirst,targetRest=P:GetDisplayLines()
check(contains(plain(targetFirst .. targetRest),"减伤: 53.04%"), "question-mark target change refreshes cached reduction immediately")
api.targetLevel=nil
api.armor=100000
check(contains(P:DisplayArmorReduction(),"75.00%"), "armor reduction cap")
api.armor=-100
check(contains(P:DisplayArmorReduction(),"0.00%"), "negative armor is bounded")
api.armor=6500
check(P:DisplayBlockValue()=="格挡值: 220" and calls.helperBlock>0, "missing extension block API falls back to BCS")
check(contains(P:DisplayRangedHitRating(),"远程命中") and contains(P:DisplayRangedCritChance(),"远程暴击"), "ranged labels are distinct")

P:RefreshNow()
local first,rest=P:GetDisplayLines()
local fonts=calls.fonts
api.speed=14;now=10.2
P:RefreshSpeedDisplay()
check(contains(plain(select(2,P:GetDisplayLines())),"移速: 200.0%"), "speed updates without body rebuild")
check(calls.fonts==fonts, "unchanged layout does not rewrite fonts each tick")
P:SetTitleKey("speed")
api.speed=3.5
first,rest=P:GetDisplayLines()
check(plain(first)=="移速: 50.0%" and not contains(plain(rest),"移速"), "speed may be a live main title")
P:SetTitleKey("three")
P:SetPanelOption("rowsPerColumn",3)
first,rest=P:GetDisplayLines();P:UpdateDisplay(1,first,rest)
check(#P.frame.columns==3, "specified row count creates multiple columns")
local all="";for _,col in ipairs(P.frame.columns) do if col:IsShown() then all=all..plain(col:GetText()).."\n" end end
check(countText(all,"移速")==1 and contains(all,"格挡") and contains(all,"减伤"), "all selected body properties survive column splitting")
P:SetPanelOption("scale",1.25)
P:SetPanelOption("detailFontSize",20)
P:SetPanelOption("columnWidth",100)
check(P.frame.scale==1.25 and P.frame:GetHeight()>100, "scale and wrapped-text frame sizing")
P:SetPanelOption("rowsPerColumn",0)
local visible=0;for _,col in ipairs(P.frame.columns) do if col:IsShown() then visible=visible+1 end end
check(visible==1, "automatic single-column hides old extra columns")
P:SetPanelOption("colorMode","whole")
check(contains(select(1,P:GetDisplayLines()),"|cFFFFD36B"), "three dimension color is applied")
local chat=P:GetPropertiesForChat()
check(not contains(chat,"|c") and countText(chat,"移速")==1, "chat remains plain and speed is not duplicated")

P.showWindow=false;P.frame:Hide()
SlashCmdList.PROPERTIESPANEL("unlock")
check(not P.locked and P.frame.mouseEnabled and not BCSConfig.PropertiesPanel.locked, "unlock command works while hidden")
click(P.lockButton)
check(P.locked and not P.frame.mouseEnabled and BCSConfig.PropertiesPanel.locked, "settings lock uses same persisted state")
click(P.unlockButton)
SlashCmdList.PROPERTIESPANEL("lock")
check(P.locked and P.unlockButton.enabled and not P.lockButton.enabled, "slash lock updates settings buttons")
check(P.reductionEdit==nil, "manual level editor is removed")
local oldPhy=P:EnsureProfile("物理")
P:ResetCurrentProfile()
check(P:GetTitleKey()=="three" and not P:EnsureProfile().props.fireRes and P:EnsureProfile("物理")==oldPhy, "reset affects only current preset")
click(P.customButtons.clearAll)
first,rest=P:GetDisplayLines();now=now+2;first,rest=P:GetDisplayLines()
check(first=="（未选择属性）" and rest=="", "empty selection has a stable placeholder")
click(P.customButtons.selectAll);now=now+2
check(#P:GetSelectedKeys()==30, "select all includes new properties")
first,rest=P:GetDisplayLines();P:UpdateDisplay(1,first,rest)
check(contains(plain(rest),"奥抗"), "all resistances render")
check(BCS.ForceCalculate==false, "force flag remains restored after all display paths")
P:SetPanelOption("rowsPerColumn",1)
first,rest=P:GetDisplayLines();P:UpdateDisplay(1,first,rest)
check(P.frame:GetWidth()*P.scale<=UIParent:GetWidth(), "column overflow increases rows to stay within screen width")
local lastRowTop=150+(math.ceil(#P.customRows/2)-1)*20
check(lastRowTop+20<=P.customFrame:GetHeight()-32, "checkboxes do not overlap editor footer buttons")
local speedApi=UnitXP;UnitXP=nil
check(P:DisplaySpeed()=="移速: 数据不可用", "missing speed extension is safe even as a title")
UnitXP=speedApi
local resistApi=UnitResistance;UnitResistance=function() return 25 end
check(P:DisplayResistance(2,"火抗")=="火抗: 25", "single-return resistance clients remain supported")
UnitResistance=resistApi
local itemApi=ItemSocre;ItemSocre={}
check(contains(P:GetPropertiesForChat(),"装等: 数据不可用"), "missing score method cannot break chat output")
ItemSocre=itemApi
check(BCSConfig.PropertiesPanel.customProps.speed==false, "legacy saved custom format preserves disabled speed")
print("PASS: "..passed.." floating panel integration checks")
'''

runtime = LuaRuntime(unpack_returned_tuples=True)
runtime.execute(STUB)
runtime.execute(SOURCE)
runtime.execute(TESTS)

def to_python(value):
    if hasattr(value, 'items'):
        return {key: to_python(item) for key, item in value.items()}
    return value

saved = to_python(runtime.globals().BCSConfig)
reloaded = LuaRuntime(unpack_returned_tuples=True)
reloaded.execute(STUB)

def to_lua(value):
    if isinstance(value, dict):
        return reloaded.table_from({key: to_lua(item) for key, item in value.items()})
    return value

reloaded.globals().BCSConfig = to_lua(saved)
reloaded.execute(SOURCE)
reloaded.execute(r'''
local P=BCS.PropertiesPanel
P:Init()
assert(#P:GetSelectedKeys()==30, "edited selections survive reload")
assert(P.locked and P.frame.mouseEnabled==false, "lock state survives reload")
assert(P.scale==1.25 and P.detailFontSize==20, "appearance survives reload")
assert(P:DisplayArmorReduction()=="减伤: 54.17%", "obsolete manual level is ignored after reload")
assert(P:EnsureProfile("自定义").props.speed==nil, "migrated legacy speed remains off after reload")
print("PASS: 5 reload and persistence checks")
''')

print('Verified with Lua 5.1; UI APIs mocked, no live game actions.')

startup = LuaRuntime(unpack_returned_tuples=True)
startup.execute(STUB)
startup.execute('math.huge=nil; select=nil; string.gmatch=nil')
# The mocked text measurement uses gmatch, whereas the addon supports Lua 5.0 gfind.
startup.execute('ObjectGmatch=string.gfind')
startup.execute(SOURCE)
startup.execute(r'''
string.gmatch=string.gfind
event="ADDON_LOADED";arg1="BetterCharacterStats"
BCS.PropertiesPanel.frame:Fire("OnEvent")
assert(BCS.PropertiesPanel:GetTitleKey()=="ap", "classic callback convention initializes a fresh character")
assert(BCS.PropertiesPanel.frame:IsShown(), "initial event builds the visible HUD")
assert(BCS.PropertiesPanel:DisplayThreeDimensions()=="三维: 48.90%", "finite check works without math.huge")
assert(BCS.PropertiesPanel:DisplayAttackSpeed()=="攻速: 2.40", "speed getter works without Lua 5.1 select")
BCS.PropertiesPanel.frame.scripts.OnEvent(BCS.PropertiesPanel.frame,"UNIT_AURA","player")
assert(BCS.PropertiesPanel.bodyDirty, "modern callback convention marks player data dirty")
print("PASS: 5 startup and legacy-API compatibility checks")
''')
