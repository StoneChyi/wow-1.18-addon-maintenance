
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
function Object:SetFont() error("Install strict font contract before UI construction") end
function Object:SetText(v) assert(self.kind ~= "FontString" or self.font, "SetText(): Font not set");self.text=tostring(v or "") end
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
