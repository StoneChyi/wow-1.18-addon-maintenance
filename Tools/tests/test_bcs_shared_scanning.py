"""Production shared collection, personal formulas, StatCompare and floating UI.

No client/account operations. Mock font writes fail before initialization;
the configured font can fail while stock templates remain available.
"""
from pathlib import Path
import argparse,sys,re
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
parser=argparse.ArgumentParser();parser.add_argument('--addons',type=Path,default=ROOT/'Interface/AddOns');ADDONS=parser.parse_args().addons.resolve()
def raw(p):return (ADDONS/p).read_bytes().removeprefix(b'\xef\xbb\xbf')
def fixture(name):
    return (ROOT/'Tools/tests/fixtures'/name).read_text(encoding='utf-8')

r=LuaRuntime(unpack_returned_tuples=True)
r.execute(r'''
BCS={};BCSConfig={};gear={};buffs={};now=10;gearReads=0;nativeReads=0;links={};frames={}
strfind=string.find;tinsert=table.insert;getn=table.getn;gsub=string.gsub
BOOKTYPE_SPELL='spell';WorldFrame={};UIParent={};testClass='PALADIN'
DODGE='闪避';PARRY='招架';BLOCK='格挡'
function getglobal(n) return _G[n] end
function GetTime() return now end
function GetLocale() return 'zhCN' end
function UnitClass() return 'Class',testClass end
function UnitFactionGroup() return 'Alliance' end
function UnitRace() return 'Human' end
function UnitLevel() return 60 end
function UnitStat() return 100,120,20,0 end
function GetNumTalents() return 0 end
function GetNumTalentTabs() return 3 end
function GetTalentInfo() return 'other',nil,nil,nil,0 end
function GetInventoryItemLink(unit,slot)
 if gear[slot] then return '|cffa335ee|Hitem:'..(links[slot] or slot)..':0:0:0|h[Item]|h|r' end
end
function GetItemInfo() return 'item',nil,4,60,'Armor',nil,nil,'INVTYPE_SHIELD' end
function GetSpellName() return nil end
function GetPlayerBuff(i,kind) if kind=='HELPFUL' and buffs[i+1] then return i end;return -1 end
function CreateFrame(kind,name)
 local f={scripts={},events={},count=0}
 function f:SetOwner() end
 function f:Hide() end
 function f:RegisterEvent(e) self.events[e]=true end
 function f:SetScript(e,fn) self.scripts[e]=fn end
 function f:NumLines() return self.count end
 function f:SetLines(lines)
  self.count=lines and (lines.n or table.getn(lines)) or 0
  for i=1,self.count do
   local row=lines[i] or {};local color=row[3] or {0,1,0}
   _G[name..'TextLeft'..i]={GetText=function() return row[1] end,GetTextColor=function() return unpack(color) end}
   _G[name..'TextRight'..i]={GetText=function() return row[2] end}
  end
 end
 function f:SetInventoryItem(unit,slot)
  gearReads=gearReads+1
  if name=='SCObjectTooltip' then nativeReads=nativeReads+1 end
  self:SetLines(gear[slot]);return gear[slot]~=nil
 end
 function f:SetHyperlink(link)
  local _,_,id=string.find(link,'item:(%d+):')
  self:SetInventoryItem('player',tonumber(id))
 end
 function f:SetPlayerBuff(index) self:SetLines(buffs[index+1]) end
 function f:SetTalent() self:SetLines({}) end
 if name then _G[name]=f end;table.insert(frames,f);return f
end
function Near(a,b) assert(math.abs(a-b)<.000001,tostring(a)..' ~= '..tostring(b)) end
''')
for p in ['BetterCharacterStats/BCS_GearStat.lua','BetterCharacterStats/Localization.lua','BetterCharacterStats/helper.lua']:
    r.execute(raw(p))
r.execute(r'''
gear={
 [1]={{'Item'}, {'+1% 急速'}, {'+2% 吸血'}, {'装备： 使你的法术目标的魔法抗性降低10点。'},
       {'Set A（1/2）'}, {'套装：使你的攻击速度和施法速度提高5%。',nil,{.5,.5,.5}}},
 [2]={{'Item'}, {'+1% 急速'}, {'所造成伤害的3%作为治疗返还。'}, {'法术穿透 +15'}},
 [16]={{'Weapon','速度 2.40'}}}
BCS:BeginEquipmentRead()
Near(BCS:GetLiveHaste('melee'),2.01)
Near(BCS:GetLifestealValue(),5)
Near(BCS:GetSpellPenetrationValue(),25)
Near(BCS:GetOriWeaponSpeed(16),2.4)
BCS:EndEquipmentRead()
assert(GearStat.ScanCount==1 and gearReads==20)
local snap=GearStat:GetSnapshot('player');assert(not snap.equipment[1].hasteSetActive[6])
Near(BCS:GetLiveHaste('melee'),2.01);assert(gearReads==20)
-- Same-frame item/link changes must be visible without relying on time.
gear[2][2][1]='+3% 急速';links[2]=2002
Near(BCS:GetLiveHaste('melee'),4.03);assert(GearStat.ScanCount==2)
-- Explicit inventory invalidation catches same-link enchant/set changes.
gear[1][6][3]={0,1,0};event='UNIT_INVENTORY_CHANGED';arg1='player';GearStat.eventFrame.scripts.OnEvent()
Near(BCS:GetLiveHaste('melee'),9.2315)
-- Auras change the personal formula without another equipment collection.
local scans=GearStat.ScanCount
buffs={{{'Casting buff'},{'施法速度提高20%。'}}}
Near(BCS:GetLiveHaste('melee'),9.2315)
Near(BCS:GetLiveHaste(),31.0778);assert(GearStat.ScanCount==scans)
-- Raw line holes and right-side text survive the compressed public view.
gear[16]={[1]={'Weapon','速度 3.20'},[3]={'line'},n=3};GearStat:InvalidateAll()
Near(BCS:GetOriWeaponSpeed(16),3.2)
-- Gear-only set armor penetration respects equipped/required counts.
gear={[1]={{'Item'},{'Set A（1/2）'},{'(2) 套装： 你的攻击无视目标150点护甲。'}}};buffs={}
GearStat:InvalidateAll();Near(BCS:GetLiveArmorPenetrationValue(),0)
gear[1][2][1]='Set A（2/2）';GearStat:InvalidateAll();Near(BCS:GetLiveArmorPenetrationValue(),150)
gear[2]=gear[1];GearStat:InvalidateAll();Near(BCS:GetLiveArmorPenetrationValue(),150)
''')
print('PASS: one physical collection, shared reuse, same-frame equipment changes, active sets, decimals, gear-only stats, raw/right lines and armor-penetration deduplication')

# Use the actual StatCompare pattern tables and scanner, not a fake summation.
for p in ['StatCompare/Localization_zhCN.lua','StatCompare/Localization_enUS.lua','StatCompare/Localization.lua']:
    r.execute(raw(p))
r.execute("SCObjectTooltip=CreateFrame('GameTooltip','SCObjectTooltip')")
core=raw('StatCompare/StatCompare.lua').decode('utf-8-sig')
for name in ['STATCOMPARE_SETNAME_PATTERN','STATCOMPARE_PREFIX_PATTERN','STATCOMPARE_SUFFIX_PATTERN','STATCOMPARE_ITEMLINK_PATTERN']:
    r.execute(re.search(r'^'+name+r'\s*=.*$',core,re.M).group(0))
r.execute(raw('StatCompare/StatScanner.lua'))
r.execute(r'''
links={}
gear={[1]={{'Item'},{'+2% 吸血'},{'装备： 使你的法术目标的魔法抗性降低10点。'},{'+1% 急速'}},
      [2]={{'Item'},{'装备： 所造成伤害的3%作为治疗返还。'},{'+15 法术穿透'},{'+1% 急速'}}}
GearStat:InvalidateAll();local scans=GearStat.ScanCount
Near(BCS:GetLifestealValue(),5);Near(BCS:GetSpellPenetrationValue(),25)
StatScanner_ScanAllInspect('player')
Near(StatScanner_bonuses.LIFEDRAIN,5);Near(StatScanner_bonuses.HASTE,2.01)
Near(StatScanner_bonuses.SPELLPENETRATION,25)
assert(GearStat.ScanCount==scans+1 and nativeReads==0)
-- Consumer mutations cannot poison shared texts or future equipment totals.
StatScanner_bonuses.HASTE=999;StatScanner_ScanAllInspect('player');Near(StatScanner_bonuses.HASTE,2.01)
-- Whole fast-path failure restarts the native scan without partial bonuses.
local original=StatScanner_ScanLine;local calls=0
StatScanner_ScanLine=function(...) calls=calls+1;if calls==2 then error('transient parser') end;return original(...) end
StatScanner_ScanAllInspect('player');Near(StatScanner_bonuses.HASTE,2.01);assert(nativeReads>0)
StatScanner_ScanLine=original
local before=nativeReads;StatScanner_ScanAllInspect('player');assert(nativeReads==before,'failure became permanent disable')
-- Missing or failing collector retains native compatibility.
local collector=GearStat;GearStat=nil;StatScanner_ScanAllInspect('player');Near(StatScanner_bonuses.HASTE,2.01)
GearStat={GetSnapshot=function() error('unavailable') end};StatScanner_ScanAllInspect('player');Near(StatScanner_bonuses.LIFEDRAIN,5)
GearStat=collector
-- A collector marked temporarily unavailable must not look like valid empty gear.
GearStat.BROKEN=true;GearStat:InvalidateAll();GearStat.BROKEN=true
local broken=GearStat:GetSnapshot('player');assert(not broken.complete)
StatScanner_ScanAllInspect('player');Near(StatScanner_bonuses.LIFEDRAIN,5)
GearStat:InvalidateAll();assert(GearStat:GetSnapshot('player').complete)
''')
print('PASS: actual StatCompare shared scan, immutable source, transactional fallback, recovery and collector-absent operation')

# Actual full personal floating panel, adding a real strict font contract.
u=LuaRuntime(unpack_returned_tuples=True)
install=u.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
u.globals().installFontContract=install
stub=fixture('bcs_float_ui.lua')
stub=stub.replace('UIParent=CreateFrame("Frame","UIParent")','''
installFontContract(Object,object)
local contractSetFont=Object.SetFont
function Object:SetFont(path,size,flags)
 local ok=contractSetFont(self,path,size,flags);if ok then self.fontSize=size end;return ok
end
failedFontPaths['Fonts\\\\FRIZQT__.TTF']=true
failedFontPaths[STANDARD_TEXT_FONT]=true
strictMethods=Object;strictObject=object
UIParent=CreateFrame("Frame","UIParent")''',1)
stub=stub.replace('object("FontString",name..suffix)','object("FontString",name..suffix):SetFontObject(GameFontNormal)')
u.execute(stub)
u.execute('''
function BCS:GetLifestealValue() return 5 end
function BCS:GetSpellPenetrationValue() return 25 end
function BCS:GetAfflictionHitRating() return 18 end
''')
u.execute(raw('BetterCharacterStats/BCS_PropertiesPanel.lua'))
u.execute('''
local p=BCS.PropertiesPanel
assert(not pcall(function() strictObject('FontString'):SetText('bad') end))
assert(p:DisplayLifesteal()=='吸血: 5%' and p:DisplaySpellPenetration()=='法穿: 25')
p.displayConfig='物理';local physical=p:EnsureProfile();local originalOrder=table.concat(physical.order,',')
physical.props.lifesteal=true;physical.props.spen=true;physical.props.ahit=true
local keys=p:GetSelectedKeys();local joined=table.concat(keys,',')
assert(string.find(joined,'lifesteal') and string.find(joined,'spen') and string.find(joined,'ahit'))
assert(string.sub(table.concat(physical.order,','),1,#originalOrder)==originalOrder)
physical.titleKey='lifesteal';assert(p:GetTitleKey()=='lifesteal')
p.displayConfig='法系';local caster=p:EnsureProfile();assert(not caster.props.lifesteal and not caster.props.spen)
caster.props.spen=true;p:GetSelectedKeys();assert(caster.props.spen and physical.props.lifesteal)
p.displayConfig='物理';p:BuildBody();local title,body=p:GetDisplayLines()
assert(string.find(title,'吸血') and string.find(body,'法穿') and string.find(body,'痛苦命中'))
p:MoveProperty('spen',-1);assert(p:EnsureProfile().props.lifesteal)
-- All property rows are real stock-font strings even when SetFont fails.
p:ShowCustomWindow(true);p:ShowCustomWindow(false);p:ShowCustomWindow(true)
local rows={};for _,row in ipairs(p.customRows) do rows[row.key]=row;assert(row.text.font) end
assert(rows.lifesteal and rows.spen and rows.ahit)
''')
print('PASS: full floating UI with strict font failure fallback; new attributes select/order/title/render independently in each preserved preset')

# Preserve and execute the existing formula assertions against actual source.
rt=LuaRuntime();rt.globals().testClass='PALADIN'
rt.execute(fixture('bcs_equipment_tooltip.lua'))
rt.execute(raw('BetterCharacterStats/Localization.lua'))
rt.execute(raw('BetterCharacterStats/helper.lua'))
rt.execute(fixture('bcs_personal_haste.lua'))
print('PASS: original personal aura, Zeal/talent, set activity and melee/casting separation formula regression')
