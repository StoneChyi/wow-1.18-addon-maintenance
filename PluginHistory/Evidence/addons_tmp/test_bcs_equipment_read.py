from pathlib import Path
import sys

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ROOT = Path(r'E:/1.18/Interface/AddOns/BetterCharacterStats')
BACKUP = HERE / 'character-bcs-scan-backup-20261006'
STUB = r'''
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
'''

def make_runtime(source, class_name):
    rt = LuaRuntime()
    rt.globals().testClass = class_name
    rt.execute(STUB)
    rt.execute(ROOT.joinpath('Localization.lua').read_text(encoding='utf-8-sig'))
    rt.execute(source)
    rt.execute('SetupGear(3)')
    return rt

old_source = (BACKUP / 'BetterCharacterStats_helper.lua.original').read_text(encoding='utf-8-sig')
new_source = (ROOT / 'helper.lua').read_text(encoding='utf-8-sig')
for class_name in ['PALADIN','MAGE','PRIEST','HUNTER','WARRIOR','DRUID','SHAMAN','WARLOCK','ROGUE']:
    old = make_runtime(old_source, class_name)
    new = make_runtime(new_source, class_name)
    expected = dict(old.eval('RunCalculations()').items())
    new.execute('BCS:BeginEquipmentRead()')
    actual = dict(new.eval('RunCalculations()').items())
    assert actual == expected, (class_name, actual, expected)
    assert new.globals().gearReads == 20, (class_name,new.globals().gearReads)
    assert new.globals().buffReads == 1, 'each active aura is scanned once within the batch'
    new.execute('BCS:EndEquipmentRead();SetupGear(8);gearReads=0;BCS:BeginEquipmentRead()')
    changed = dict(new.eval('RunCalculations()').items())
    old.execute('SetupGear(8)')
    assert changed == dict(old.eval('RunCalculations()').items()), 'next batch sees new equipment'
    assert changed['spell power'] != actual['spell power'], 'fixture contains changing attribute values'
    new.execute('BCS:EndEquipmentRead();gearReads=0;BCS:GetLiveSpellPower();BCS:GetLiveHealingPower()')
    assert new.globals().gearReads == 40, 'standalone getters have no lasting cache'
    print(f'PASS: {class_name}, 13 getter outputs preserved, repeated gear reads {old.globals().gearReads // 2} -> 20 per batch')

rt = make_runtime(new_source,'PALADIN')
rt.execute(ROOT.joinpath('BetterCharacterStats.lua').read_text(encoding='utf-8-sig'))
rt.execute(r'''
local calls=0
function BCS:UpdatePaperdollStats(prefix,index)
 calls=calls+1
 if string.find(prefix,'Left') then self:GetLiveSpellPower()
 else self:GetLiveHealingPower() end
end
BCS:UpdateStats()
assert(calls==2 and gearReads==20,'actual UpdateStats shares equipment between both panels')
gearReads=0
local oldUpdate=BCS.UpdatePaperdollStats
function BCS:UpdatePaperdollStats() self:GetLiveSpellPower();error('expected error') end
local ok,message=pcall(function() BCS:UpdateStats() end)
assert(not ok and string.find(message,'expected error'),'original error remains visible')
SetupGear(8);gearReads=0
BCS:GetLiveSpellPower();BCS:GetLiveHealingPower()
assert(gearReads==40,'failed update releases batch data')
BCS.UpdatePaperdollStats=oldUpdate
BCSConfig.PropertiesPanel={characterPanelEnabled=false};gearReads=0;calls=0
BCS:UpdateStats()
assert(gearReads==0 and calls==0,'disabled character panel performs no reads')
''')
print('PASS: actual UpdateStats lifecycle, both panels, exception cleanup and disabled mode')

rt.execute(r'''
BCSConfig.PropertiesPanel.characterPanelEnabled=true
buffs={{{'first buff'},{'MATCH: 12, 34'}},{{'second buff'},{'MATCH: 56, 78'}}}
local debuffs={{{'debuff'},{'HARM: 9'}}}
local helpful=GetPlayerBuff
function GetPlayerBuff(i,kind)
 if kind=='HARMFUL' and debuffs[i+1] then return 50+i end
 return helpful(i,kind)
end
local nativeBuff=BetterCharacterStatsTooltip or CreateFrame()
local originalSetBuff=nativeBuff.SetPlayerBuff
function nativeBuff:SetPlayerBuff(i)
 if i>=50 then
  local previous=buffs;buffs=debuffs;originalSetBuff(self,i-50);buffs=previous
 else originalSetBuff(self,i) end
end
buffReads=0;BCS:BeginEquipmentRead()
local a,b,c,d=BCS:GetPlayerAura('MATCH: (%d+), (%d+)')
assert(c=='12' and d=='34','first buff match and multi-captures preserved')
BCS:GetPlayerAura('does not match');BCS:GetPlayerAura('MATCH: (%d+)')
local _,_,harm=BCS:GetPlayerAura('HARM: (%d+)','HARMFUL')
assert(harm=='9' and buffReads==3,'helpful and harmful tooltip indexes remain distinct')
BCS:EndEquipmentRead()
buffs={{{'changed buff'},{'MATCH: 90, 91'}}}
BCS:BeginEquipmentRead();local _,_,value=BCS:GetPlayerAura('MATCH: (%d+)');BCS:EndEquipmentRead()
assert(value=='90','new batch sees changed buffs')
buffs={{{'live buff'},{'MATCH: 99, 98'}}}
local _,_,value=BCS:GetPlayerAura('MATCH: (%d+)')
assert(value=='99','standalone aura lookup stays live')
''')
print('PASS: aura order, multiple captures, helpful/harmful separation and subsequent live updates')
