from pathlib import Path
import runpy
import sys

HERE = Path(__file__).parent
ROOT = Path(r'E:\1.18\Interface\AddOns')
sys.path.insert(0, str(HERE / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

# Reuse the existing frame fixture and run the layout regression checks first.
runtime = runpy.run_path(str(HERE / 'test_inspect_layout.py'))['runtime']
runtime.execute(r'''
STATCOMPARE_SET_PREFIX='Set: '
STATCOMPARE_ITEMLINK_PATTERN='^|c(%x+)'
gsub=string.gsub
gear={player={},target={}}
gear.player[1]='|cffaabbcc|Hitem:101:0:0:0|h[Head]|h|r'
gear.player[2]='|cffaabbcc|Hitem:102:0:0:0|h[Neck]|h|r'
gear.target[1]='|cffaabbcc|Hitem:201:0:0:0|h[Other]|h|r'
playerLevel=60; missingInfo=false; missingLink=false; tooltipReads=0
function UnitLevel() return playerLevel end
function GetInventoryItemLink(unit,slot) return gear[unit] and gear[unit][slot] end
function GetInventoryItemTexture(unit,slot) return missingLink and slot==3 and 'icon' or nil end
function GetItemInfo(id) if not missingInfo then return 'Item '..id end end
SCObjectTooltip={
 Hide=function() end,SetOwner=function() end,
 SetHyperlink=function(self,link)
  tooltipReads=tooltipReads+1
  self.itemID=tonumber(string.match(link,'item:(%d+)'))
 end,
 SetInventoryItem=function(self) self.itemID=nil end,
 NumLines=function(self) return self.itemID and 2 or 0 end,
}
SCObjectTooltipTextLeft1={GetText=function() return 'Item' end}
SCObjectTooltipTextLeft2={GetText=function() return tostring(SCObjectTooltip.itemID) end}
''')
runtime.execute((ROOT / 'StatCompare/StatScanner.lua').read_bytes().decode('gb18030'))
runtime.execute(r'''
-- The reverted scanner must start afresh, including nested set data.
function StatScanner_ScanLine(line)
 StatScanner_AddValue('STR',tonumber(line))
 StatScanner_currentset='TestSet';StatScanner_currentsetcount=3
 StatScanner_setsproperty[1]={setsname='TestSet',count=2,line='set bonus'}
end
StatScanner_ScanAll()
assert(tooltipReads==2 and StatScanner_bonuses.STR==203,'actual gear scan')
StatScanner_bonuses.STR=999;StatScanner_setcount.TestSet.count=999
StatScanner_ScanAll()
assert(tooltipReads==4 and StatScanner_bonuses.STR==203,'fresh scan restores gear values')
assert(StatScanner_setcount.TestSet.count==2,'fresh nested set counts')
local show=SCShowFrame
local buffCalls,charCalls,nativeCalls=0,0,0
local currentBuff=5
SC_BuffScanner_ScanAllInspect=function(bonus) buffCalls=buffCalls+1;bonus.STR=bonus.STR+currentBuff end
StatCompare_CharStats_Scan=function() charCalls=charCalls+1 end
StatCompare_GetTooltipText=function(bonus) return tostring(bonus.STR) end
SCShowFrame=function(frame,target,title,text) displayedStats=text end
oldPaperDollFrame_OnShow=function() nativeCalls=nativeCalls+1 end
SCPaperDollFrame_OnShow();currentBuff=17;SCPaperDollFrame_OnShow()
assert(tooltipReads==8 and displayedStats=='220','actual C-open path refreshes live buffs')
assert(buffCalls==2 and charCalls==2 and nativeCalls==2,'live/native updates run every opening')
SCShowFrame=show
print('PASS: reverted scanner and live C-open values')
''')

runtime.execute(r'''
-- Exercise the actual enchant wrapper with an icon carrying visible state.
function time() return 123 end
gear.player={};gear.target={};clockNow=20
function GetTime() return clockNow end
ItemSocre={ScanUnit=function() clockNow=clockNow+.1;return 0 end}
local frame=S_ItemTip_InspectFrame
frame.visible=true;frame.lastUpdateTime=nil
frame.gemIcon1=CreateFrame('Frame')
local hideCount=0
frame.gemIcon1.Hide=function(self) hideCount=hideCount+1;self.visible=false end
iconHideCount=function() return hideCount end
''')
runtime.execute((ROOT / 'S_ItemTip/InspectGemAndEnchant.lua').read_text(encoding='utf-8-sig'))
runtime.execute(r'''
S_ItemTip_UpdateFrame('player')
assert(S_ItemTip_InspectFrame.lastUpdateTime==clockNow,'throttle starts when a slow update finishes')
local icon=S_ItemTip_InspectFrame.gemIcon1
icon.title='keep enchant';icon.enchantID=7;icon:Show()
local before=iconHideCount()
assert(S_ItemTip_UpdateFrame('player')==false,'duplicate wrapper call returns skipped')
assert(iconHideCount()==before and icon:IsShown() and icon.title=='keep enchant','skip preserves enchant icons')
clockNow=clockNow+.1;S_ItemTip_UpdateFrame('player')
assert(iconHideCount()>before and not icon:IsShown(),'later valid refresh still clears removed enchants')
print('PASS: actual enchant wrapper skips duplicate redraws and retains later updates')
''')

runtime.execute(r'''
scoreCalls=0
ItemSocre={ScanUnit=function() scoreCalls=scoreCalls+1;return 77.2 end}
function IsAddOnLoaded(name) return name=='S_ItemTip' end
local own=StatCompareSelfFrame
own.levelBg=nil;own.backdrop=nil
CreateFrame('FontString','StatCompareSelfFrameILevelText')
CreateFrame('Texture','StatCompareSelfFramePortrait')
CharacterFrame.visible=true;PaperDollFrame.visible=true;InspectFrame.visible=false
SCShowFrame(own,PaperDollFrame,'player','stats',200,-12)
assert(scoreCalls==1 and StatCompareSelfFrameILevelText.text=='装等 77.2','single score feeds both text and geometry')
assert(own:GetHeight()==710,'height still accommodates score')
assert(not own.portraitUpdateFrame,'own portrait needs no delayed retry')
local pane=StatCompareTargetFrame
CreateFrame('Texture','StatCompareTargetFramePortrait')
StatCompare_RefreshPortrait(pane,'target')
local timer=pane.portraitUpdateFrame;assert(timer,'inspected portraits retain retry')
StatCompare_RefreshPortrait(pane,'target')
assert(pane.portraitUpdateFrame==timer,'portrait retry frame reused')
StatCompare_RefreshPortrait(pane,'player')
assert(not timer:GetScript('OnUpdate'),'own portrait cancels an old retry')
print('PASS: single score calculation and immediate/reusable portraits')
''')

# Differential score checks against the backed-up function, across qualities,
# class/weapon coefficients, missing item info, and fallback item names.
def score_runtime(source):
    rt = LuaRuntime()
    rt.execute(r'''
lib={Item_enUS={[1]='Original',[2]='Custom',[3]='Duplicate',[4]='Duplicate'}}
levels={[1]=40,[2]=65,[3]=30,[4]=55,[100]=50}
dbVisits=0
local originalPairs=pairs
function pairs(tbl)
 if tbl==lib.Item_enUS then dbVisits=dbVisits+1 end
 return originalPairs(tbl)
end
function LibStub(name) if name=='LibItem-enUS-1.0' then return lib else return {Item_Level=levels} end end
function IsAddOnLoaded() return false end
function hooksecurefunc() end
GameTooltip={}
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
function UnitIsPlayer() return isPlayer~=false end
function UnitClass() return 'class',class or 'WARRIOR' end
gear={}
function GetInventoryItemLink(unit,slot) return gear[slot] end
function GetItemInfo(id)
 if missing then return nil end
 return customName or 'Custom',nil,rarity or 4,nil,nil,nil,nil,weapon or 'INVTYPE_WEAPON'
end
''')
    rt.execute(source)
    return rt

old = score_runtime((HERE / 'character-open-backup-20261006/S_ItemTip_ItemSocre.lua.original').read_text(encoding='utf-8-sig'))
new = score_runtime((ROOT / 'S_ItemTip/ItemSocre.lua').read_text(encoding='utf-8-sig'))
count = 0
for char_class in ['WARRIOR', 'HUNTER']:
    for quality in range(6):
        for weapon in ['INVTYPE_WEAPON', 'INVTYPE_2HWEAPON']:
            for rt in [old, new]:
                rt.globals()['class'] = char_class
                rt.globals()['rarity'] = quality
                rt.globals()['weapon'] = weapon
                rt.execute("gear={[1]='item:999:0:0:0',[16]='item:100:0:0:0',[17]='item:999:0:0:0',[18]='item:100:0:0:0'}")
            assert old.eval("ItemSocre:ScanUnit('player')") == new.eval("ItemSocre:ScanUnit('player')")
            count += 1
for name in ['Unknown', 'Duplicate']:
    for rt in [old, new]:
        rt.globals()['customName'] = name
    assert old.eval("ItemSocre:ScanUnit('player')") == new.eval("ItemSocre:ScanUnit('player')")
    count += 1
for rt in [old, new]:
    rt.globals()['missing'] = True
assert old.eval("ItemSocre:ScanUnit('player')") == new.eval("ItemSocre:ScanUnit('player')")
count += 1
assert new.eval('dbVisits') == 3
new.execute("missing=false;lib.Item_enUS={[5]='Duplicate'};levels[5]=80")
old.execute("missing=false;lib.Item_enUS={[5]='Duplicate'};levels[5]=80")
assert old.eval("ItemSocre:ScanUnit('player')") == new.eval("ItemSocre:ScanUnit('player')")
assert new.eval('dbVisits') == 4
print(f'PASS: {count} old/new equipment scores match; fallback search cached per requested name, without eager indexing')
