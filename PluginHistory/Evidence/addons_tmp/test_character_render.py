from pathlib import Path
import runpy

HERE = Path(__file__).parent
rt = runpy.run_path(str(HERE / 'test_inspect_layout.py'))['runtime']
rt.execute(r'''
CharacterFrame.visible=true;PaperDollFrame.visible=true;InspectFrame.visible=false
StatCompareTargetFrame.visible=false;S_ItemTip_InspectFrame.visible=true
local own=StatCompareSelfFrame
own.levelBg=nil;own.backdrop=nil
local body=StatCompareSelfFrameText
local portrait=CreateFrame('Texture','StatCompareSelfFramePortrait')
local border=CreateFrame('Texture','StatCompareSelfFramePortraitBorder')
local scoreText=CreateFrame('FontString','StatCompareSelfFrameILevelText')
local calls={body=0,measure=0,width=0,height=0,point=0,border=0,portrait=0}
local object=getmetatable(own)
body.SetText=function(self,text) calls.body=calls.body+1;object.SetText(self,text) end
local bodyWidth,bodyHeight,fontSize=200,600,12
body.GetFont=function() return 'bodyfont',fontSize end
body.GetWidth=function() calls.measure=calls.measure+1;return bodyWidth end
body.GetHeight=function() calls.measure=calls.measure+1;return bodyHeight end
own.SetWidth=function(self,v) calls.width=calls.width+1;object.SetWidth(self,v) end
own.SetHeight=function(self,v) calls.height=calls.height+1;object.SetHeight(self,v) end
own.SetPoint=function(self,...) calls.point=calls.point+1;object.SetPoint(self,unpack(arg)) end
border.SetTexture=function(self,v) calls.border=calls.border+1;self.texture=v end
border.GetTexture=function(self) return self.texture end
portrait.GetTexture=function(self) return self.texture end
function SetPortraitTexture(texture,unit) calls.portrait=calls.portrait+1;texture.texture='portrait-'..unit end
local score=77.2
ItemSocre={ScanUnit=function() return score end}
function IsAddOnLoaded(name) return name=='S_ItemTip' end
SCShowFrame(own,PaperDollFrame,'player','stats',200,-12)
Tick();Tick()
assert(calls.body==1 and calls.measure==2 and calls.portrait==1 and calls.border==1,'initial render executes necessary operations')
for key in pairs(calls) do calls[key]=0 end
for i=1,5 do
 own:Hide()
 SCShowFrame(own,PaperDollFrame,'player','stats',200,-12)
 Tick();Tick()
end
for key,value in pairs(calls) do assert(value==0,'unchanged reopen must skip '..key) end
assert(body:GetText()=='stats' and scoreText:GetText()=='装等 77.2','cached display retains correct text')
calls.measure=0
bodyWidth,bodyHeight=300,620
SCShowFrame(own,PaperDollFrame,'player','new stats',200,-12)
assert(calls.body==1 and calls.measure==2 and own:GetWidth()==340 and own:GetHeight()==730,'changed values update text and geometry')
fontSize=13;bodyWidth=400
SCShowFrame(own,PaperDollFrame,'player','new stats',200,-12)
assert(calls.measure==4 and own:GetWidth()==440,'font changes invalidate measurements')
score=80
SCShowFrame(own,PaperDollFrame,'player','new stats',200,-12)
assert(scoreText:GetText()=='装等 80.0','gear score stays live')
event='UNIT_PORTRAIT_UPDATE';arg1='player';StatCompare_OnEvent()
assert(calls.portrait==1,'visible appearance event refreshes immediately')
own:Hide();event='UNIT_MODEL_CHANGED';StatCompare_OnEvent()
assert(calls.portrait==1 and own.scPortraitDirty,'hidden appearance event marks pending refresh')
SCShowFrame(own,PaperDollFrame,'player','new stats',200,-12)
assert(calls.portrait==2 and not own.scPortraitDirty,'next show consumes pending appearance refresh')
portrait.texture=nil;border.texture=nil
SCShowFrame(own,PaperDollFrame,'player','new stats',200,-12)
assert(calls.portrait==3 and calls.border==1,'skin-cleared textures are restored')

local originalName=UnitName
function UnitName(unit) if unit=='target' then return inspectedName or 'first' else return originalName(unit) end end
local pane=StatCompareTargetFrame
CreateFrame('Texture','StatCompareTargetFramePortrait')
StatCompare_RefreshPortrait(pane,'target')
local timer=pane.portraitUpdateFrame
inspectedName='second';StatCompare_RefreshPortrait(pane,'target')
assert(pane.scPortraitName=='second' and pane.portraitUpdateFrame==timer,'inspected identity refreshes and reuses its retry frame')
print('PASS: repeated openings skip unchanged text/metrics/geometry/textures; changed stats/fonts/appearance still refresh')

-- Exercise S_ItemTip's actual OnShow path, which previously placed the list
-- at a legacy anchor before the shared layout moved it a second time.
S_ItemTip_OnCharacterShow();Tick();Tick()
local equipment=S_ItemTip_InspectFrame
local pointWrites,clears,showWrites=0,0,0
equipment.SetPoint=function(self,...) pointWrites=pointWrites+1;object.SetPoint(self,unpack(arg)) end
equipment.ClearAllPoints=function(self) clears=clears+1;object.ClearAllPoints(self) end
equipment.Show=function(self) showWrites=showWrites+1;object.Show(self) end
for i=1,3 do S_ItemTip_OnCharacterShow();Tick();Tick() end
assert(pointWrites==0 and clears==0,'character OnShow never replaces an unchanged managed anchor')
assert(showWrites==0,'repeated character callbacks do not show an already shown list')
CharacterFrame.visible=false;PaperDollFrame.visible=false
InspectFrame.visible=true;InspectFrame.unit='target';InspectPaperDollFrame.visible=true
S_ItemTip_ShowForInspect('target');Tick();Tick()
assert(pointWrites==1 and clears==1,'inspect transition goes directly to the final anchor')
S_ItemTip_ShowForInspect('target');Tick();Tick()
assert(pointWrites==1 and clears==1,'repeated inspect refresh keeps the managed anchor')

-- Standalone S_ItemTip still supplies its own anchor without StatCompare.
SCRelayoutPanels=nil;SCGetPanelLayoutMode=nil;SCSetPanelPoint=nil
StatCompareSelfFrame=nil;StatCompareTargetFrame=nil
S_ItemTip_ShowForInspect('target')
assert(equipment.point[2]==InspectFrame and equipment.point[4]==-35,'standalone inspect anchor retained')
InspectFrame.visible=false;CharacterFrame.visible=true;PaperDollFrame.visible=true
S_ItemTip_OnCharacterShow()
assert(equipment.point[2]==CharacterFrame and equipment.point[4]==-35.5,'standalone character anchor retained')
print('PASS: equipment OnShow skips interim anchors; root transitions and standalone fallback remain correct')
''')
