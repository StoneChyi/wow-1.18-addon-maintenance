
BCS={};BCSConfig={};gearReads=0;buffReads=0;gear={};buffs={};now=10
DODGE='闪避';PARRY='招架';BLOCK='格挡'
strfind=string.find;tinsert=table.insert;getn=table.getn
function tContains(t,v) for _,x in ipairs(t) do if x==v then return true end end end
function getglobal(name) return _G[name] end
function UnitClass() return 'test',testClass end
function UnitFactionGroup() return 'Alliance' end
function UnitRace() return 'Human' end
function UnitStat() return 100,120,20,0 end
function UnitLevel() return 60 end
function UnitBuff() return nil end
function GetTime() return now end
function GetTalentInfo() return 'test talent',nil,nil,nil,0 end
function GetInventoryItemLink(unit,slot) if slot==17 then return '|Hitem:1:0:0:0|h[shield]|h' end end
function GetItemInfo() return 'shield',nil,4,60,'Armor',nil,nil,'INVTYPE_SHIELD' end
function GetSpellName() return nil end
function GetNumTalents() return 0 end
function GetNumTalentTabs() return 3 end
function GetPlayerBuff(i,kind) if kind=='HELPFUL' and buffs[i+1] then return i end;return -1 end
WorldFrame={};PaperDollFrame={};SlashCmdList={}
function PaperDollFrame:GetScript() return nil end
function PaperDollFrame:SetScript() end
local tooltip={count=0}
local function SetLines(lines)
 tooltip.count=lines and (lines.n or table.getn(lines)) or 0
 for i=1,tooltip.count do
  local row=lines[i] or {}
  _G['BetterCharacterStatsTooltipTextLeft'..i]={GetText=function() return row[1] end}
  _G['BetterCharacterStatsTooltipTextRight'..i]={GetText=function() return row[2] end}
 end
end
function tooltip:SetOwner() end
function tooltip:NumLines() return self.count end
function tooltip:SetInventoryItem(unit,slot)
 assert(unit=='player');gearReads=gearReads+1;SetLines(gear[slot]);return gear[slot]~=nil
end
function tooltip:SetPlayerBuff(i) buffReads=buffReads+1;SetLines(buffs[i+1]) end
function tooltip:SetTalent() SetLines({}) end
function CreateFrame() return tooltip end
function Example(pattern,value)
 local text=string.gsub(pattern,'%%d%+',tostring(value))
 text=string.gsub(text,'%%d',tostring(value))
 text=string.gsub(text,'[()]','')
 text=string.gsub(text,'^%^','');text=string.gsub(text,'%$$','')
 return (string.gsub(text,'%%(.)','%1'))
end
function SetupGear(value)
 local lines={
  {'测试装备'},
  {Example(BCS.L['Equip: Improves your chance to hit by (%d)%%.'],value)},
  {Example(BCS.L_SPELLHIT['Equip: Improves your chance to hit with spells by (%d)%%.'],value)},
  {Example(BCS.L_SPELLCRIT['Equip: Improves your chance to get a critical strike with spells by (%d)%%.'],value)},
  {Example(BCS.L_SPELLPOWER['Equip: Increases damage and healing done by magical spells and effects by up to (%d+).'],value)},
  {Example(BCS.L_HEALPOWER['Equip: Increases healing done by spells and effects by up to (%d+).'],value)},
  {Example(BCS.L_MANAREGEN['Equip: Restores (%d+) mana per 5 sec.'],value)},
  {string.format('装备： 使你的攻击速度和施法速度提高%d%%。',value)},
  {'测试套装（2/2）'},
  {Example(BCS.L['^Set: Improves your chance to hit by (%d)%%.'],2)},
 }
 gear={[1]=lines,[2]=lines,[3]={n=3,[1]={'测试装备'},[3]={'无属性'}},
       [16]={{'主手','速度 2.40'}},[17]={{'盾牌'}},[18]={{'远程','速度 2.80'}}}
 buffs={{{'测试增益'},{Example(BCS.L_SPELLPOWER['Magical damage dealt is increased by up to (%d+).'],7)}}}
end
function RunCalculations()
 local result={}
 local function Save(name,...)
  local function Flatten(v)
   if type(v)=='table' then
    local keys={};for key in pairs(v) do table.insert(keys,key) end;table.sort(keys)
    local text='';for _,key in ipairs(keys) do text=text..key..'='..tostring(v[key])..';' end;return text
   end
   return tostring(v)
  end
  local text='';for i=1,arg.n do text=text..Flatten(arg[i])..'|' end
  result[name]=text
 end
 Save('hit',BCS:GetLiveHitRating())
 Save('spell hit',BCS:GetLiveSpellHitRating())
 Save('ranged crit',BCS:GetLiveRangedCritChance())
 Save('spell crit',BCS:GetLiveSpellCritChance())
 Save('spell power',BCS:GetLiveSpellPower())
 Save('healing',BCS:GetLiveHealingPower())
 Save('regen',BCS:GetLiveManaRegen())
 Save('haste',BCS:GetLiveHaste())
 Save('armor',BCS:GetLiveOnlyGearArmor())
 Save('block',BCS:GetLiveBlockValue())
 Save('armor pen',BCS:GetLiveArmorPenetrationValue())
 Save('weapon',BCS:GetOriWeaponSpeed(16))
 Save('ranged weapon',BCS:GetOriWeaponSpeed(18))
 return result
end
