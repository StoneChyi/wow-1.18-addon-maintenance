from pathlib import Path
import runpy

HERE = Path(__file__).parent
rt = runpy.run_path(str(HERE / 'test_inspect_layout.py'))['runtime']
rt.execute(r'''
local object=getmetatable(CharacterFrame)
local equipment=S_ItemTip_InspectFrame
local clamps=0
equipment.SetClampedToScreen=function(self,value) clamps=clamps+1;self.clamped=value end
equipment.sItemTipClamped=nil
CharacterFrame.visible=true;PaperDollFrame.visible=true;InspectFrame.visible=false
SCSetPanelLayoutMode('auto')
assert(equipment.clamped==false,'shared anchors are not independently clamped')
for _,pane in ipairs({equipment,StatCompareSelfFrame,StatCompareTargetFrame}) do
 assert(pane.topLevel==false,'automatic panels do not use independent top-level promotion')
end
local own=StatCompareSelfFrame
local showCalls,topLevelWrites=0,0
own.Show=function(self) showCalls=showCalls+1;object.Show(self) end
own.SetToplevel=function(self,value) topLevelWrites=topLevelWrites+1;object.SetToplevel(self,value) end
own.visible=false
SCShowPanel(own)
for i=1,5 do SCShowPanel(own);SCRelayoutPanels() end
assert(showCalls==1 and topLevelWrites==0,'shown panels are not shown or promoted again by layout')
local baseline=clamps
for i=1,5 do SCRelayoutPanels() end
assert(clamps==baseline,'settled layout does not repeatedly toggle native clamping')
SCSetPanelLayoutMode('free')
assert(equipment.clamped==true,'free dragging retains screen clamping')
for _,pane in ipairs({equipment,StatCompareSelfFrame,StatCompareTargetFrame}) do
 assert(pane.topLevel==true,'free windows retain their original independent promotion')
end
SCSetPanelLayoutMode('auto')
assert(equipment.clamped==false,'returning to automatic placement releases individual clamping')
assert(topLevelWrites==2,'native top-level policy only changes when the placement mode changes')

local currentItem=111
LibItem_Level={[111]=76,[222]=88}
function GetInventoryItemLink(unit,slot)
 if slot==16 and currentItem then return '|cffaa00ff|Hitem:'..currentItem..':0:0:0|h[装备]|h|r' end
end
function GetItemInfo(id) return id==111 and '第一把武器' or '第二把武器',nil,4,60,'Weapon' end
function GetItemQualityColor() return .6,0,.8 end
ItemSocre.ScanUnit=function() return currentItem==111 and 77.2 or 80 end
local clock=100
function GetTime() return clock end
local function NextUpdate() clock=clock+1 end
local row
for _,candidate in ipairs(equipment.slotFrames) do if candidate.slotId==16 then row=candidate end end
assert(row,'actual equipment frame supplies mainhand row')
local textWrites,widthWrites,measurements=0,0,0
local currentFontSize=11
row.itemName.SetText=function(self,value) textWrites=textWrites+1;object.SetText(self,value) end
row.itemName.SetWidth=function(self,value) widthWrites=widthWrites+1;self.width=value end
row.itemName.GetWidth=function(self)
 measurements=measurements+1
 if self.width==0 then return currentItem==111 and 150 or 210 end
 return self.width
end
row.itemName.GetFont=function() return 'font',currentFontSize end
local expectedUnit='player'
equipment.Show=function(self)
 assert(self.currentUnit==expectedUnit,'equipment identity must be written before showing')
 assert(row.itemID==currentItem,'equipment rows must be populated before showing')
 object.Show(self)
end
equipment:Hide();equipment.lastUpdateTime=nil
S_ItemTip_OnCharacterShow();Tick();Tick()
assert(row.itemName:GetText()=='第一把武器' and row.itemName.width==150,'first item renders at its intrinsic width')
local t,w,m=textWrites,widthWrites,measurements
for i=1,3 do
 equipment:Hide();NextUpdate();S_ItemTip_OnCharacterShow();Tick();Tick()
end
assert(textWrites==t and widthWrites==w and measurements==m,'unchanged reopens never reset or remeasure equipment name')

currentItem=222;NextUpdate();S_ItemTip_OnCharacterShow();Tick()
assert(row.itemName:GetText()=='第二把武器' and row.itemName.width==210 and row.itemLevel:GetText()=='88','new equipment refreshes name, width and level')
assert(equipment.ilevelText:GetText()=='装等 80.0','score remains current')
local previousMeasure=measurements
currentFontSize=13;NextUpdate();S_ItemTip_OnCharacterShow();Tick()
assert(measurements==previousMeasure+1,'font changes remeasure even when name is unchanged')

expectedUnit='target';equipment:Hide()
CharacterFrame.visible=false;PaperDollFrame.visible=false
InspectFrame.visible=true;InspectFrame.unit='target';InspectPaperDollFrame.visible=true
NextUpdate();S_ItemTip_ShowForInspect('target');Tick();Tick()
assert(equipment.currentUnit=='target' and equipment.point[2]==InspectFrame,'inspection switches data and anchor before showing')
currentItem=nil;NextUpdate();S_ItemTip_ShowForInspect('target');Tick()
assert(row.itemName:GetText()=='' and row.itemLevel:GetText()=='' and row.itemLink==nil,'removed item clears all displayed data')
print('PASS: clamp policy, hidden population before Show, unchanged name caching, changed items/fonts, target changes and removed items')
''')
