from pathlib import Path
import ast,sys
sys.path.insert(0,str(Path(__file__).parent/'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
ROOT=Path(r'E:/1.18/Interface/AddOns/BetterCharacterStats')
def fixture(name):
    for node in ast.parse((Path(__file__).parent/name).read_text(encoding='utf-8')).body:
        if isinstance(node,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='STUB' for t in node.targets):
            return ast.literal_eval(node.value)
rt=LuaRuntime()
rt.globals().testClass='PALADIN'
rt.execute(fixture('test_bcs_equipment_read.py'))
rt.execute(ROOT.joinpath('Localization.lua').read_text(encoding='utf-8-sig'))
rt.execute(ROOT.joinpath('helper.lua').read_text(encoding='utf-8-sig'))
rt.execute(r"""
BCS.ForceCalculate=true
-- A 10% item used to fail the one-digit pattern entirely.
gear={[1]={{'装备：使你的攻击速度和施法速度提高10%。'}}};buffs={}
assert(math.abs(BCS:GetLiveHaste()-10)<0.00001,'multi-digit gear haste')
gear={[1]={{'+6.65% 急速'}}}
buffs={{{'急速提高10%。'}}}
assert(math.abs(BCS:GetLiveHaste()-17.315)<0.00001,'decimal haste and aura multiply')
gear={[1]={{'+6.65% 急速'}}};buffs={};now=0.1
assert(math.abs(BCS:GetHaste()-6.65)<0.00001,'initial cache must not return zero')
now=0.2;buffs={{{'急速提高10%。'}}};BCS:InvalidateHasteCache()
assert(math.abs(BCS:GetHaste()-17.315)<0.00001,'aura gain invalidates cache inside two seconds')
now=0.3;buffs={};BCS:InvalidateHasteCache()
assert(math.abs(BCS:GetHaste()-6.65)<0.00001,'aura loss invalidates cache')
now=0.4;gear={[1]={{'+20% 急速'}}};BCS:InvalidateHasteCache()
assert(math.abs(BCS:GetHaste()-20)<0.00001,'equipment invalidates cache')
-- Real spell parser with Lua 5.0 compatibility (no string.match).
string.match=nil
function GetSpellName(index) if index==1 then return '救赎' end end
local nativeCreate=CreateFrame
local made=0
local spellText='10秒施法时间'
function CreateFrame(kind,name,...)
 if name~='BCSHasteSpellTooltip' then return nativeCreate(kind,name,unpack(arg)) end
 made=made+1
 local t={}
 function t:SetOwner() end
 function t:ClearLines() end
 function t:SetSpell() end
 function t:Hide() end
 function t:NumLines() return 1 end
 _G[name..'TextLeft1']={GetText=function() return spellText end}
 return t
end
assert(BCS:GetSpellCastTime('救赎')==10,'integer cast duration')
spellText='9.377 秒施法时间'
assert(BCS:GetSpellCastTime('救赎')==9.377,'preserve tooltip precision')
spellText='0秒施法时间';assert(BCS:GetSpellCastTime('救赎')==nil,'reject zero duration')
spellText='10秒施法时间';now=0.5;BCS:InvalidateHasteCache()
assert(BCS:EstimateHaste()==0,'first estimate is measured')
spellText='9秒施法时间';now=0.6;BCS:InvalidateHasteCache()
assert(math.abs(BCS:EstimateHaste()-(10/9-1)*100)<0.00001,'estimate invalidation')
assert(made==1,'reuse spell tooltip')
""")
print('PASS: real haste gear/aura parsing, fresh caches, legacy spell parser and tooltip reuse')
rt=LuaRuntime()
rt.execute(fixture('test_bcs_float.py'))
rt.execute(ROOT.joinpath('BCS_PropertiesPanel.lua').read_text(encoding='utf-8-sig'))
rt.execute(r"""
local P=BCS.PropertiesPanel
function UnitClass() return '法师','MAGE' end
function BCS:IsNampowerReady() return true end
function GetUnitField() return 1/1.1737 end
assert(P:DisplayHaste()=='急速: 17.37%','native coefficient conversion')
-- Do not add aura percentages again to a native total.
function BCS:EstimateHaste() return 99 end
assert(P:DisplayHaste()=='急速: 17.37%','native value is not double counted')
function GetUnitField() return 0 end
function BCS:EstimateHaste() return 17.37 end
assert(P:DisplayHaste()=='急速: 17.37%','invalid native value falls back')
GetUnitField=nil
assert(P:DisplayHaste()=='急速: 17.37%','old extension missing API')
function GetUnitField() error('unsupported field') end
assert(P:DisplayHaste()=='急速: 17.37%','native errors do not hide haste')
function BCS:EstimateHaste() error('bad tooltip') end
function BCS:GetHaste() return 17.37 end
assert(P:DisplayHaste()=='急速: 17.37%','estimate errors fall back to gear')
function BCS:GetHaste() return 0/0 end
assert(P:DisplayHaste()=='急速: 数据不可用','reject non-finite result')
local invalidations=0
function BCS:InvalidateHasteCache() invalidations=invalidations+1 end
P.showWindow=false
local handler=P.frame.scripts.OnEvent
handler(P.frame,'PLAYER_AURAS_CHANGED')
handler(P.frame,'UNIT_INVENTORY_CHANGED','player')
handler(P.frame,'UNIT_AURA','player')
assert(invalidations==3,'old and new aura events plus gear')
handler(P.frame,'UNIT_AURA','target')
handler(P.frame,'UNIT_INVENTORY_CHANGED','target')
assert(invalidations==3,'other units do not invalidate haste')
""")
print('PASS: real floating haste getter, native errors, finite values, no double count and event filtering')

rt.execute(r"""
local P=BCS.PropertiesPanel
BCSConfig={PropertiesPanel={enabled=true,displayConfig='法系'}}
P:Init()
local builds=0
local originalBuild=P.BuildBody
function P:BuildBody() builds=builds+1;return originalBuild(self) end
local currentHaste=6.6468
local nativeReads=0
function GetUnitField() nativeReads=nativeReads+1;return 1/(1+currentHaste/100) end
function BCS:IsNampowerReady() return true end
function BCS:EstimateHaste() error('native haste must not scan spell tooltips') end
P.forceNextBuild=true
local first,body=P:GetDisplayLines()
assert(string.find(TextNoColors(body),'急速: 6.65%',1,true),'initial live haste')
local oldBuilds=builds
-- Aura event may precede the coefficient update. No second event follows.
P.frame.scripts.OnEvent(P.frame,'PLAYER_AURAS_CHANGED')
currentHaste=17.37;now=now+0.2
first,body=P:GetDisplayLines()
assert(string.find(TextNoColors(body),'急速: 17.37%',1,true),'post-event coefficient updates at the next tick')
assert(builds==oldBuilds,'no full attribute rebuild for live haste')
currentHaste=6.6468;now=now+0.2
first,body=P:GetDisplayLines()
assert(string.find(TextNoColors(body),'急速: 6.65%',1,true),'aura expiry is visible without waiting five seconds')
assert(builds==oldBuilds,'expiry has no full rescan')
function BCS:GetOriWeaponSpeed(slot) assert(slot==16);return 2.4 end
function UnitAttackSpeed() return 2.4/1.1737 end
assert(math.abs(P:GetMeleeHaste()-17.37)<0.0001,'melee comparison uses weapon/current attack-speed ratio')
BCS.GetOriWeaponSpeed=nil
function BCS:IsNampowerReady() return false end
function BCS:EstimateHaste() return nil end
function BCS:GetHaste() assert(BCS.ForceCalculate==true);return 17.37 end
BCS.ForceCalculate=false
assert(P:DisplayHaste()=='急速: 17.37%','live fallback bypasses character tab on-demand filtering')
assert(BCS.ForceCalculate==false,'restore on-demand flag')
""")
print('PASS: post-aura live changes, expiry, no full body rescans, melee comparison and fallback flag cleanup')

rt.execute(r"""
local P=BCS.PropertiesPanel
function UnitClass() return '圣骑士','PALADIN' end
function BCS:IsNampowerReady() return true end
function BCS:GetOriWeaponSpeed(slot) return 2.4 end
local melee,cast=2.01,2.01
function UnitAttackSpeed() return 2.4/(1+melee/100) end
function GetUnitField() return 1/(1+cast/100) end
function BCS:EstimateHaste() error('Zeal must not use cast estimates') end
local cases={
 {2.01,2.01,'2.01'},
 {7.1105,7.1105,'7.11'},
 {7.1105,-2.63,'7.11'},
 {12.211,7.11,'12.21'},
 {17.3115,6.6468,'17.31'},
 {2.01,-2.63,'2.01'}
}
P.forceNextBuild=true
for _,c in ipairs(cases) do
 melee,cast=c[1],c[2];now=now+0.2
 assert(P:DisplayHaste()=='急速: '..c[3]..'%', 'measured melee haste for Zeal sequence')
 local first,body=P:GetDisplayLines()
 assert(string.find(TextNoColors(body),'急速: '..c[3]..'%',1,true),'actual panel follows Zeal sequence immediately')
end
-- The change is confined to the paladin floating statistic.
function UnitClass() return '法师','MAGE' end
cast=6.6468;melee=17.3115
assert(P:DisplayHaste()=='急速: 6.65%','other classes retain casting haste')
""")
print('PASS: user-reported Zeal sequence, abnormal cast coefficient, aura expiry and caster scope')

rt.execute(r"""
function UnitClass() return '圣骑士','PALADIN' end
local P=BCS.PropertiesPanel
local reads=0
local weapon='weapon A'
local base=2.4
function GetInventoryItemLink(unit,slot) return weapon end
function BCS:GetOriWeaponSpeed() reads=reads+1;return base end
function UnitAttackSpeed() return base/1.1737 end
P.hasteWeaponBase=nil
for i=1,10 do assert(P:DisplayHaste()=='急速: 17.37%') end
assert(reads==1,'frequent updates reuse unmodified weapon speed')
-- Switching weapons is noticed even if the equipment event has not arrived yet.
base=1.8;weapon='weapon B'
assert(P:DisplayHaste()=='急速: 17.37%')
assert(reads==2,'new weapon identity invalidates the baseline')
P.frame.scripts.OnEvent(P.frame,'UNIT_INVENTORY_CHANGED','player')
local afterEvent=reads
P:DisplayHaste()
assert(reads<=afterEvent+1,'equipment event allows one fresh tooltip read')
P.frame.scripts.OnEvent(P.frame,'PLAYER_AURAS_CHANGED')
local afterAura=reads
P:DisplayHaste()
assert(reads==afterAura,'aura changes never rescan an unchanged weapon')
""")
print('PASS: weapon baseline cache, identity changes, inventory refresh and no extra aura tooltip scans')

rt.execute(r"""
local P=BCS.PropertiesPanel
local base,current=2,1.999
local itemID,delay=100,2000
local delayReads,tooltipReads=0,0
function UnitClass() return '圣骑士','PALADIN' end
function GetInventoryItemLink() return '|Hitem:'..itemID..':0:0:0|h[Test weapon]|h' end
function GetItemStatsField(id,field)
 assert(id==itemID and field=='delay');delayReads=delayReads+1;return delay
end
function BCS:GetOriWeaponSpeed() tooltipReads=tooltipReads+1;return base end
function UnitAttackSpeed() return current end
P.hasteWeaponBase=nil
assert(P:DisplayHaste()=='急速: 0.00%','one millisecond residue must not appear as 0.05%')
current=1.9990000724792
assert(P:DisplayHaste()=='急速: 0.00%','client single-precision millisecond boundary')
current=2.001
assert(P:DisplayHaste()=='急速: 0.00%','negative one-millisecond residue')
current=2/1.0005
assert(P:DisplayHaste()=='急速: 0.05%','a real continuous 0.05% modifier is retained')
current=2/1.001
assert(P:DisplayHaste()=='急速: 0.10%','real 0.1% haste is retained')
current=2/1.05
assert(P:DisplayHaste()=='急速: 5.00%','Zeal remains visible')
assert(delayReads==1 and tooltipReads==0,'original delay cached, tooltip is not read when exact data exists')
-- An original 1.999-second delay must not be confused with tooltip rounding to 2.00.
itemID=101;delay=1999;current=1.999
assert(P:DisplayHaste()=='急速: 0.00%','raw item delay takes precedence over rounded tooltip')
current=1.999/1.05
assert(P:DisplayHaste()=='急速: 5.00%','haste uses original item precision')
-- The 1 ms rule does not zero every small percentage for fast weapons.
itemID=102;delay=1000;current=1/1.001
assert(P:DisplayHaste()=='急速: 0.10%','fast weapon real haste inside one millisecond remains visible')
-- Missing, unsupported or invalid extension fields retain the tooltip fallback.
itemID=103;delay=nil;current=2
assert(P:DisplayHaste()=='急速: 0.00%','missing original delay falls back')
itemID=104;delay=0
assert(P:DisplayHaste()=='急速: 0.00%','zero item delay is rejected')
itemID=105
function GetItemStatsField() error('unsupported field') end
current=2/1.05
assert(P:DisplayHaste()=='急速: 5.00%','extension errors fall back safely')
itemID=106;GetItemStatsField=nil;current=1.999
assert(P:DisplayHaste()=='急速: 0.00%','older clients normalize the boundary without extension support')
""")
print('PASS: reproduced 0.05% residue, raw item delay precision, small real haste, fast weapons, Zeal and old-client fallback')

rt.execute(r"""
local P=BCS.PropertiesPanel
function UnitClass() return '圣骑士','PALADIN' end
function UnitAttackSpeed() return nil end
function BCS:GetHaste() assert(BCS.ForceCalculate);return 17.3115 end
function GetUnitField() error('melee fallback must not read casting fields') end
BCS.ForceCalculate=false
assert(P:DisplayHaste()=='急速: 17.31%','melee fallback uses formula with corrected Zeal')
assert(BCS.ForceCalculate==false,'formula fallback restores forced calculation flag')
function BCS:GetHaste() return nil end
assert(P:DisplayHaste()=='急速: 数据不可用','missing melee data does not switch stat definitions')
""")
print('PASS: paladin formula fallback and no accidental casting-source switch')

rt.execute(r"""
local P=BCS.PropertiesPanel
function UnitClass() return '圣骑士','PALADIN' end
local current=2.018
function GetInventoryItemLink() return '|Hitem:200:0:0:0|h[Test]|h' end
function GetItemStatsField() return 2200 end
function UnitAttackSpeed() return current end
function BCS:GetOriWeaponSpeed() error('must not scan weapon tooltip') end
function BCS:GetCalculatedMeleeHaste() error('live tick must not scan all equipment') end
P.hasteWeaponBase=nil
local cast=9
function GetUnitField() return 1/(1+cast/100) end
assert(P:DisplayHaste()=='急速: 9.00%','user screenshot 9.0188 is calibrated to compatible precise coefficient')
assert(math.abs(P:GetMeleeHaste()-9.01883)<0.00001,'diagnostics retain measured haste')
local cases={{0,2.2,'0.00'},{3,2.135,'3.00'},{6,2.075,'6.00'},{9,2.018,'9.00'},
 {5,2.095,'5.00'},{10,2.0,'10.00'},{15,1.913,'15.00'}}
for _,c in ipairs(cases) do
 cast,current=c[1],c[2]
 for i=1,5 do assert(P:DisplayHaste()=='急速: '..c[3]..'%', 'quantized actual interval verifies precise total') end
end
current=2.018;cast=6.6468
assert(P:DisplayHaste()=='急速: 9.02%','corrupt cast coefficient cannot override melee measurement')
cast=12
assert(P:DisplayHaste()=='急速: 9.02%','casting-only haste cannot override melee measurement')
cast=9;current=2.01899995
assert(P:DisplayHaste()=='急速: 8.96%','matching within 1 ms but wrong rounding direction is rejected')
current=2.2/1.0005;cast=0
assert(P:DisplayHaste()=='急速: 0.05%','real continuous small haste is preserved')
current=2.2/1.0903;cast=9
assert(P:DisplayHaste()=='急速: 9.03%','continuous interval is not quantization-calibrated')
current=2.018
function GetUnitField() error('unsupported field') end
assert(P:DisplayHaste()=='急速: 9.02%','native error retains measured haste')
function GetUnitField() return 0/0 end
assert(P:DisplayHaste()=='急速: 9.02%','non-finite coefficient retains measured haste')
GetUnitField=nil
assert(P:DisplayHaste()=='急速: 9.02%','missing native extension retains measured haste')
""")
print('PASS: screenshot precision, 3/5 percent Zeal stacks, incompatible cast data, small real haste and no full equipment scans')
