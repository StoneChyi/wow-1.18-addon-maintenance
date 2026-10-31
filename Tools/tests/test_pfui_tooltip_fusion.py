"""Real shared tooltip dispatcher, provider helpers and pfUI Update integration.
Offline 1.12 API simulation, not in-game visual acceptance.
"""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
lua=LuaRuntime(unpack_returned_tuples=True)
MOCK=r"""
_G=_G or getfenv(0)
local unpack51=unpack
function unpack(values) return unpack51(values) end -- Lua 5.0 ignores range arguments
function obj() return {scripts={},SetScript=function(s,k,f)s.scripts[k]=f end,GetScript=function(s,k)return s.scripts[k]end,Show=function(s)s.shown=true end,Hide=function(s)s.shown=false end,IsShown=function(s)return s.shown end} end
function CreateFrame()return obj()end
UIParent=obj();GameTooltip=obj();rawCalls=0;lines={};results={}
function GameTooltip:ClearLines()lines={} end
function GameTooltip:AddLine(t) table.insert(lines,t)end
function GameTooltip:AddDoubleLine(a,b)table.insert(lines,a..b)end
function GameTooltip:NumLines()return #lines end
function GameTooltip:Show() local first=not self.shown;self.shown=true;if first and pfUI.tooltip.Update then pfUI.tooltip:Update()end end
function GameTooltip:Hide()self.shown=false;if pfUI.api.libtooltip then local f=pfUI.api.libtooltip:GetScript('OnHide');if f then f()end end end
function GameTooltip:SetBackdropBorderColor()end
function GameTooltip:AppendText()end
for _,k in ipairs({'SetHyperlink','SetBagItem','SetQuestLogItem','SetQuestItem','SetLootItem','SetInventoryItem','SetLootRollItem','SetMerchantItem','SetCraftItem','SetCraftSpell','SetTradeSkillItem','SetTradePlayerItem','SetTradeTargetItem','SetAuctionItem','SetAuctionSellItem','SetInboxItem','SetUnit','SetAction','SetPetAction','SetShapeshift','SetSpell','SetTrackingSpell','SetPlayerBuff','SetPlayerDebuff','SetUnitBuff','SetUnitDebuff','SetText'})do
 local method=k -- Lua 5.0 loop variables are shared by closures.
 GameTooltip[k]=function(self,a,b)rawCalls=rawCalls+1;self:ClearLines();if method=='SetText' then table.insert(lines,a);table.insert(lines,'Requires Herbalism')end;if not noNativeShow then self:Show()end;if a=='invalid' then error('native error')end;return 'first',nil,'third'end
end
C={tooltip={itemid='0',alwaysperc='0'},global={colorblind='0'},automation={enabled='1'}}
pfUI_config=C
pfUI={api={},tooltip=obj(),automationIntegrations={}}
function pfUI:GetEnvironment()return _G end
function pfUI:RegisterModule(name,version,fn)fn()end
pfUI.tooltip.UpdateBars=function()end
pfUI.tooltipStatusBar={HP={SetText=function()end}}
GameTooltipStatusBar={SetStatusBarColor_orig=function()end}
GameTooltipTextLeft1={GetText=function()return 'Mob'end,SetText=function()end}
function HideModel()end
function ShowModelForUnit()end
T=setmetatable({},{__index=function(_,k)return k end})
local module
Automaton={modules={},t={obj={},herbmini={}}}
function Automaton:NewModule(name)module={name=name,RegisterEvent=function()end,UnregisterAllEvents=function()end};self.modules[name]=module;return module end
function Automaton:IsModuleActive()return module.active end
function UnitExists(u)return u=='target' or u=='mouseover' or u=='pet'end
function UnitName(u)if UnitExists(u)then return 'Mob'end end
function UnitPVPName(u)return UnitName(u)end
function UnitIsPlayer()return false end
function UnitIsUnit(a,b)return a==b end
function UnitClass()return 'Warrior','WARRIOR'end
function UnitHealth()return 10 end
function UnitHealthMax()return 20 end
function UnitReaction()return 4 end
function UnitPlayerControlled()return false end
function UnitSex()return 1 end
function UnitResistance(u,i)return i,i*2 end
function UnitArmor()return 123 end
function UnitDamage()return 10,20 end
function UnitAttackSpeed()return 2.5 end
function UnitLevel()return 20 end
function UnitAffectingCombat()return combat end
function GetPetHappiness()return 3 end
function GetPetFoodTypes()return 'Meat','Fish'end
function GetPetExperience()return 15,100 end
function GetText()return 'Neutral'end
function GetGuildInfo()end
function IsShiftKeyDown()return shift end
function GetPlayerBuffID()return 42 end
function UnitBuff()return nil,nil,nil,nil,nil,nil,43 end
function UnitDebuff()return nil,nil,nil,44,nil,nil,44 end
function GetItemInfo(id)return 'Item','item:'..id..':0:0:0',1 end
function GetContainerItemLink(a,b)return 'item:'..(100+b)..':0:0:0'end
function GetContainerItemInfo()return nil,3 end
function GetInventoryItemLink()return 'item:200:0:0:0'end
function GetQuestItemLink()return 'item:300:0:0:0'end
function GetQuestLogItemLink()return nil end
function GetLootSlotLink()return 'item:400:0:0:0'end
function GetNumFactions()return 0 end
function Abbreviate(n)return tostring(n)end
UnitReactionColor={[4]={r=1,g=1,b=0}}
strfind=string.find;getn=table.getn;floor=math.floor;gsub=string.gsub;format=string.format
function getglobal(name) local n=tonumber(string.match(name,'GameTooltipTextLeft(%d+)'));if n then return {GetText=function()return lines[n]end,GetTextColor=function()return 1,1,1,1 end}end end
function count(text)local n=0;for _,v in ipairs(lines)do if string.find(v,text,1,true)then n=n+1 end end;return n end
"""
lua.execute(MOCK)
lua.execute((ROOT/'Interface/AddOns/Automatonex/Modules/Tooltip.lua').read_text(encoding='utf8'))
lua.execute(r"""
m=Automaton.modules.Tooltip
m.db={profile={showitemid=true,showResistance=true,showDamageAndSpeed=true,showgather=true,showReputation=true,showPetHappiness=true,showPetFood=true,showPetExp=true,showspellid=true,hideInCombat=false,showFrameName=false}}
m._options=m.options;m.active=true
m:InstallStandaloneHooks()
oldFallback=GameTooltip.SetUnit
m:InstallStandaloneHooks();assert(GameTooltip.SetUnit==oldFallback,'reinstalled fallback hooks')
""")
lua.execute((ROOT/'Interface/AddOns/pfUI/libs/libtooltip.lua').read_text(encoding='utf8'))
lua.execute('libtooltip=pfUI.api.libtooltip')
source=(ROOT/'Interface/AddOns/pfUI/modules/tooltip.lua').read_text(encoding='utf8')
a=source.index('  function pfUI.tooltip:GetUnit()');b=source.index('  pfUI.tooltip.dodge',a)
lua.execute(source[a:b])
a=source.index('  function pfUI.tooltip:Update()');b=source.index('  -- 添加 OnUpdate 钩子',a)
lua.execute(source[a:b])
lua.execute((ROOT/'Interface/AddOns/pfUI/modules/tooltip_extensions.lua').read_text(encoding='utf8'))
lua.execute(r"""
I=pfUI.automationIntegrations.Tooltip
assert(I:Sync(true));assert(m.pfUIManaged and C.tooltip.itemid=='1')
local a,b,c=GameTooltip:SetBagItem(0,1)
assert(a=='first' and b==nil and c=='third','lost nil return')
assert(count('ItemID')==1 and count('物品ID')==0,'duplicate ID path')
GameTooltip:Hide();noNativeShow=true;GameTooltip:SetBagItem(0,1);assert(count('ItemID')==1,'setter without Show recursively doubled ID');noNativeShow=nil
assert(libtooltip:GetItemID()==101 and libtooltip:GetItemCount()==3)
GameTooltip:SetBagItem(0,2);assert(libtooltip:GetItemID()==102 and count('ItemID')==1,'stale item cache')
GameTooltip:SetUnit('target')
assert(not libtooltip:GetItemID() and count('ItemID')==0)
assert(count('护甲123')==1 and count('伤害范围')==1 and count('攻击速度')==1,'unit data duplicate/missing')
assert(count('Neutral')==1)
GameTooltip:SetUnit('pet');assert(count('快乐度')==1 and count('食物需求')==1 and count('经验: 15/100')==1)
GameTooltip:SetPlayerBuff(1);assert(count('法术ID：42')==1)
AtlasLootCharDB={WishList={{101}}}
GameTooltip:SetBagItem(0,1);assert(count('我的愿望')==1)
local hooks=GameTooltip.SetUnit
for i=1,20 do m:OnDisable();m:OnEnable();I:Sync(true)end
assert(GameTooltip.SetUnit==hooks,'toggle piled up hooks')
m.db.profile.hideInCombat=true;m:PLAYER_REGEN_DISABLED()
local old=rawCalls;GameTooltip:SetUnit('target');assert(rawCalls==old and not GameTooltip.shown)
shift=true;GameTooltip:SetUnit('target');assert(GameTooltip.shown and count('护甲123')==1)
shift=nil;m:PLAYER_REGEN_ENABLED()
local ok=pcall(function()GameTooltip:SetUnit('invalid')end);assert(not ok and not libtooltip.setting,'error poisoned dispatcher')
GameTooltip:SetUnit('target');assert(count('护甲123')==1)
Automaton.t.herbmini.Herb=' (Skill 75)';Automaton.t.obj['Requires Herbalism']='需要草药'
GameTooltip:SetText('Herb');assert(not libtooltip:GetItemID() and libtooltip.kind=='SetText');assert(count('需要草药 (Skill 75)')==1,'direct object tooltip lost gathering extension')
I:Sync(false);assert(not m.pfUIManaged)
GameTooltip:SetBagItem(0,1);assert(count('物品ID')==1 and count('ItemID')==0,'standalone fallback doubled shared ID')
GameTooltip:SetUnit('target');assert(count('护甲123')==1,'fallback did not restore unique content')
m:OnDisable();GameTooltip:SetUnit('target');assert(count('护甲123')==0,'disabled provider still mutates tooltip')
I:Sync(true);assert(not I:GetOptions().showitemid.get()==false)
print('PASS: actual tooltip shared dispatcher/layout/provider, item ID, unit data, pet, spell, wishlist, combat Shift, fallback, nil returns, errors, repeated enable')
""")
