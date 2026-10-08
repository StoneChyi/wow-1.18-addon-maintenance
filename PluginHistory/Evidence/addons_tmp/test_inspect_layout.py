from pathlib import Path
import sys
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).parent / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ROOT = Path(r'E:\1.18\Interface\AddOns')
runtime = LuaRuntime()
runtime.execute(r'''
frames={}
StaticPopupDialogs={}
local Object={}; Object.__index=Object
function Object:GetName() return self.name end
function Object:SetToplevel(value) self.topLevel=value end
function Object:SetText(v) self.text=v end
function Object:GetText() return self.text end
function Object:GetWidth() return self.width or 200 end
function Object:GetHeight() return self.height or 600 end
function Object:GetFont() return 'font',12 end
function Object:SetWidth(v) if self.width~=v then self.width=v; self:Fire('OnSizeChanged') end end
function Object:SetHeight(v) if self.height~=v then self.height=v; self:Fire('OnSizeChanged') end end
function Object:SetBackdrop(v) self.background=v end
function Object:GetBackdrop() return self.background end
function Object:SetBackdropColor(...) self.color={...} end
function Object:GetBackdropColor() return unpack(self.color or {0,0,0,1}) end
function Object:SetBackdropBorderColor(...) self.borderColor={...} end
function Object:GetBackdropBorderColor() return unpack(self.borderColor or {0,0,0,1}) end
function Object:SetAlpha(v) self.alpha=v end
function Object:GetAlpha() return self.alpha or 1 end
function Object:ClearAllPoints() self.point=nil end
function Object:SetPoint(a,b,c,x,y) self.point={a,b,c,x,y} end
function Object:GetPoint() if not self.point then return end; local p=self.point;return p[1],type(p[2])=='string' and _G[p[2]] or p[2],p[3],p[4],p[5] end
function Object:IsVisible() return self.visible end
function Object:IsShown() return self.visible end
function Object:Show() if not self.visible then self.visible=true; self:Fire('OnShow') end end
function Object:Hide() if self.visible then self.visible=false; self:Fire('OnHide') end end
function Object:SetFrameStrata(v) self.strata=v end
function Object:GetFrameStrata() return self.strata or 'MEDIUM' end
function Object:GetScript(s) return self.scripts[s] end
function Object:SetScript(s,f) self.scripts[s]=f end
function Object:RegisterEvent() end
function Object:CreateFontString() return CreateFrame('FontString') end
function Object:Fire(s,...)
 if self.scripts[s] then local prev=this;this=self;self.scripts[s](unpack(arg));this=prev end
end
function CreateFrame(kind,name,parent,template)
 local f=setmetatable({name=name,visible=true,scripts={},levelBg={}},Object)
 table.insert(frames,f);if name then _G[name]=f end;return f
end
function getglobal(name) return _G[name] end
function TEXT(text) return text end
function UnitExists() return false end
function IsAddOnLoaded() return false end
function StatCompare_GetSetting() return showSelf or 1 end
function StatCompare_RefreshPortrait() end
function Tick()
 local callbacks={};for _,f in ipairs(frames) do if f.scripts.OnUpdate then table.insert(callbacks,{f,f.scripts.OnUpdate}) end end
 local prevArg,prevThis=arg1,this;arg1=.1
 for _,call in ipairs(callbacks) do this=call[1];call[2](call[1],0.1) end
 arg1,this=prevArg,prevThis
end
function PendingTicks() local n=0;for _,f in ipairs(frames) do if f.scripts.OnUpdate then n=n+1 end end;return n end
UIParent=CreateFrame('Frame','UIParent')
CharacterFrame=CreateFrame('Frame','CharacterFrame'); CharacterFrame.visible=false
CharacterFrame.backdrop=CreateFrame('Frame',nil,CharacterFrame)
CharacterFrame.backdrop:SetBackdrop({bgFile='character-texture',edgeFile='character-border'})
CharacterFrame.backdrop:SetBackdropColor(.12,.16,.2,.65)
CharacterFrame.backdrop:SetBackdropBorderColor(.3,.4,.5,.8)
PaperDollFrame=CreateFrame('Frame','PaperDollFrame');PaperDollFrame.visible=false
InspectFrame=CreateFrame('Frame','InspectFrame');InspectFrame.unit='target'
InspectFrame.backdrop=CreateFrame('Frame',nil,InspectFrame)
InspectPaperDollFrame=CreateFrame('Frame','InspectPaperDollFrame')
OutfitterFrame=CreateFrame('Frame','OutfitterFrame');OutfitterFrame.visible=false
S_ItemTip_InspectFrame=CreateFrame('Frame','S_ItemTip_InspectFrame_UI')
S_ItemTip_Settings={showInspect=true}
StatCompareTargetFrame=CreateFrame('Frame','StatCompareTargetFrame')
StatCompareSelfFrame=CreateFrame('Frame','StatCompareSelfFrame')
StatCompareTargetFrame:SetScript('OnHide',function() StatCompareSelfFrame:Hide() end)
for _,name in ipairs({'StatCompareTargetFrame','StatCompareSelfFrame'}) do
 CreateFrame('FontString',name..'Text'); CreateFrame('FontString',name..'Title')
end
StatCompare_Player={FramePositions={
 StatCompareSelfFrame={point='TOPLEFT',relativePoint='TOPLEFT',xOfs=543.5,yOfs=-114},
 StatCompareTargetFrame={point='TOPLEFT',relativePoint='TOPLEFT',xOfs=786.51,yOfs=-23.47}}}
''')

source = (ROOT / 'StatCompare/StatCompare.lua').read_text(encoding='utf-8-sig')
module = source[:source.index('-- ===== 属性面板公共布局结束 =====')]
runtime.execute(source)  # Existing cached manifests already include StatCompare.lua.
runtime.execute(source)  # XML loads it again; initialization must remain idempotent.
assert runtime.eval('type(SCIsManagedPanel)') == 'function'
assert runtime.eval('type(SCRelayoutPanels)') == 'function'
runtime.execute(r'''
local n=0
function check(ok,label) assert(ok,label); n=n+1 end
function anchor(frame) local a=frame.point[2];return type(a)=='string' and _G[a] or a end
SCShowFrame(StatCompareTargetFrame,S_ItemTip_InspectFrame,'target','stats',-5,-5)
SCShowFrame(StatCompareSelfFrame,StatCompareTargetFrame,'self','stats',.5,0)
check(anchor(S_ItemTip_InspectFrame)==InspectFrame.backdrop,'equipment follows inspect background edge')
check(anchor(StatCompareTargetFrame)==S_ItemTip_InspectFrame,'old target position ignored in automatic layout')
check(anchor(StatCompareSelfFrame)==StatCompareTargetFrame,'self follows target')
check(StatCompareTargetFrame.point[5]==0 and StatCompareSelfFrame.point[5]==0,'top edges aligned')
check(StatCompare_Player.FramePositions.StatCompareTargetFrame.xOfs==786.51,'old custom positions retained')
check(S_ItemTip_InspectFrame.color[4]==.65 and StatCompareSelfFrame.color[4]==.65,'shared background opacity')
check(StatCompareTargetFrame.color[1]==.12 and StatCompareTargetFrame.color[3]==.2,'shared background color')
check(StatCompareTargetFrame.background.bgFile=='character-texture','shared background texture')
check(StatCompareTargetFrame.borderColor[4]==.8,'shared border')
StatCompareSelfFrame.backdrop=CreateFrame('Frame',nil,StatCompareSelfFrame)
StatCompareSelfFrame:SetBackdrop({bgFile='old-layer'})
SCRelayoutPanels()
check(StatCompareSelfFrame:GetBackdrop()==nil,'legacy layer removed when skinned background exists')
check(StatCompareSelfFrame.backdrop.color[4]==.65,'skin background inherits opacity')
CharacterFrame.backdrop:SetBackdropColor(.2,.3,.4,.45)
CharacterFrame.backdrop:SetAlpha(.8);CharacterFrame:SetAlpha(.6)
SCRelayoutPanels()
check(math.abs(S_ItemTip_InspectFrame.color[4]-.36)<.0001,'direct background includes source child alpha')
check(StatCompareSelfFrame.backdrop:GetAlpha()==.8 and StatCompareSelfFrame:GetAlpha()==.6,'skinned background preserves child and parent alpha')
CharacterFrame.backdrop:SetAlpha(1);CharacterFrame:SetAlpha(1)
StatCompareSelfFrame.backdrop=nil
SCShowFrame(StatCompareSelfFrame,PaperDollFrame,'self','refreshed',200,-12)
check(anchor(StatCompareSelfFrame)==StatCompareTargetFrame,'player gear refresh stays in inspect chain')
S_ItemTip_Settings.showInspect=false;SCRelayoutPanels()
check(not S_ItemTip_InspectFrame:IsVisible() and anchor(StatCompareTargetFrame)==InspectFrame.backdrop,'hidden equipment leaves no gap')
S_ItemTip_Settings.showInspect=true;S_ItemTip_InspectFrame:Show();SCRelayoutPanels()
S_ItemTip_InspectFrame:SetWidth(340);Tick()
check(anchor(StatCompareTargetFrame)==S_ItemTip_InspectFrame,'equipment width update keeps relative anchors')
showSelf=0;SCRelayoutPanels()
check(not StatCompareSelfFrame:IsVisible(),'respect comparison self visibility setting')
showSelf=1;StatCompareSelfFrame:Show();SCRelayoutPanels()
SCSetPanelLayoutMode('free')
check(anchor(StatCompareTargetFrame)==UIParent and StatCompareTargetFrame.point[4]==786.51,'free mode restores target position')
check(anchor(StatCompareSelfFrame)==UIParent and StatCompareSelfFrame.point[5]==-114,'free mode restores self position')
StatCompareTargetFrame:SetPoint('TOPLEFT',UIParent,'TOPLEFT',800,-40)
StatCompare_SaveFramePosition('StatCompareTargetFrame')
check(StatCompare_Player.FramePositions.StatCompareTargetFrame.relativeTo=='UIParent','free position saves its reference')
SCShowFrame(StatCompareTargetFrame,S_ItemTip_InspectFrame,'target','stats',-5,-5)
check(StatCompareTargetFrame.point[4]==800 and StatCompareTargetFrame.point[5]==-40,'refresh preserves free position')
SCSetPanelLayoutMode('auto')
StatCompare_SaveFramePosition('StatCompareTargetFrame')
check(StatCompare_Player.FramePositions.StatCompareTargetFrame.xOfs==800,'automatic updates do not overwrite free positions')
check(anchor(StatCompareSelfFrame)==StatCompareTargetFrame,'switching back to auto restores chain')
InspectFrame.visible=false;CharacterFrame.visible=true;PaperDollFrame.visible=true
StatCompareTargetFrame.visible=true;StatCompareSelfFrame.visible=true;S_ItemTip_InspectFrame.visible=true
SCRelayoutPanels()
check(not StatCompareTargetFrame:IsVisible() and StatCompareSelfFrame:IsVisible(),'character transition hides target but retains self')
check(anchor(S_ItemTip_InspectFrame)==CharacterFrame.backdrop and anchor(StatCompareSelfFrame)==S_ItemTip_InspectFrame,'character equipment and self align')
PaperDollFrame:Hide();Tick()
check(not StatCompareSelfFrame:IsVisible() and not S_ItemTip_InspectFrame:IsVisible(),'other character tabs hide side panels')
CharacterFrame.visible=false;InspectFrame.visible=true;InspectPaperDollFrame.visible=false
StatCompareTargetFrame.visible=true;StatCompareSelfFrame.visible=true;S_ItemTip_InspectFrame.visible=true
SCRelayoutPanels()
check(not StatCompareTargetFrame:IsVisible() and not S_ItemTip_InspectFrame:IsVisible(),'inspect honor and talent tabs hide side panels')
InspectPaperDollFrame:Show();Tick()
check(StatCompareTargetFrame:IsVisible() and StatCompareSelfFrame:IsVisible() and S_ItemTip_InspectFrame:IsVisible(),'returning to inspect equipment tab restores side panels')
InspectPaperDollFrame.visible=true;StatCompareTargetFrame.visible=true;StatCompareSelfFrame.visible=true;S_ItemTip_InspectFrame.visible=true
OutfitterFrame:Show();Tick()
check(not StatCompareTargetFrame:IsVisible() and not StatCompareSelfFrame:IsVisible(),'outfitter suppresses side panels')
OutfitterFrame:Hide();Tick()
check(StatCompareTargetFrame:IsVisible() and StatCompareSelfFrame:IsVisible(),'closing outfitter restores both comparison panels')
OutfitterFrame.visible=false;InspectFrame.visible=false;SCRelayoutPanels()
Tick();Tick();check(PendingTicks()==0,'layout scheduler settles without permanent polling')
CharacterFrame.backdrop=nil;InspectFrame.backdrop=nil
SCApplyPanelStyle(StatCompareSelfFrame)
check(StatCompareSelfFrame.color[4]==.75,'without pfUI consistent fallback opacity')
StatCompareOptFrame=CreateFrame('Frame','StatCompareOptFrame');StatCompareOkButton=CreateFrame('Button','StatCompareOkButton')
SCEnsureLayoutButton();check(StatCompareLayoutButton:GetText()=='排列：自动','settings expose current mode')
StatCompareLayoutButton:Fire('OnClick');check(SCGetPanelLayoutMode()=='free','settings button selects free mode')
StatCompareLayoutButton:Fire('OnClick');check(SCGetPanelLayoutMode()=='auto','settings button selects automatic mode')
print('PASS: '..n..' actual Lua layout/style integration checks')
''')

# Load S_ItemTip's actual lifecycle hooks and equipment creation, using empty inventories.
runtime.execute(r'''
local Object=getmetatable(CharacterFrame)
for _,method in ipairs({'EnableMouse','SetMovable','SetClampedToScreen','RegisterForDrag',
 'Raise','SetTexture','SetBlendMode','SetVertexColor','SetTextColor','SetJustifyH','SetFont','SetTexCoord'}) do
 Object[method]=function() end
end
function Object:GetFrameLevel() return 2 end
function Object:SetFrameLevel() end
function Object:StartMoving() self.moving=true end
function Object:StopMovingOrSizing() self.moving=false end
function Object:GetFont() return 'font',12 end
function Object:CreateTexture() return CreateFrame('Texture') end
function Object:CreateFontString() return CreateFrame('FontString') end
DEFAULT_CHAT_FRAME={AddMessage=function() end}
SlashCmdList={};ItemSocre={};RAID_CLASS_COLORS={}
function UnitExists() return true end
function UnitLevel() return 60 end
function UnitName(unit) return unit end
function UnitClass() return '战士','WARRIOR' end
function GetTime() return 10 end
function GetInventoryItemLink() end
function SetPortraitTexture() end
function HideUIPanel(frame) frame:Hide() end
CharacterFrame.visible=false;PaperDollFrame.visible=false
InspectFrame.visible=true;InspectPaperDollFrame.visible=true
''')
runtime.execute((ROOT / 'S_ItemTip/InspectFrame.lua').read_text(encoding='utf-8-sig'))
runtime.execute(r'''
S_ItemTip_Settings.showInspect=true
S_ItemTip_ShowForInspect('target')
assert(S_ItemTip_InspectFrame:IsVisible() and S_ItemTip_InspectFrame.currentUnit=='target')
assert(S_ItemTip_InspectFrame.point[2]==InspectFrame)
assert(S_ItemTip_InspectFrame.color[4]==.75)
S_ItemTip_InspectFrame:Fire('OnDragStart')
assert(not S_ItemTip_InspectFrame.moving,'automatic equipment list cannot drift from dragging')
SCSetPanelLayoutMode('free');S_ItemTip_InspectFrame:Fire('OnDragStart')
assert(S_ItemTip_InspectFrame.moving,'free equipment list can be dragged')
S_ItemTip_InspectFrame:SetPoint('TOPLEFT',UIParent,'TOPLEFT',123,-45)
S_ItemTip_InspectFrame:Fire('OnDragStop')
S_ItemTip_ShowForInspect('target')
assert(S_ItemTip_InspectFrame.point[4]==123,'free equipment position survives refresh')
SCSetPanelLayoutMode('auto')
S_ItemTip_ToggleInspect(false)
assert(not S_ItemTip_InspectFrame:IsVisible())
S_ItemTip_ToggleInspect(true)
assert(S_ItemTip_InspectFrame:IsVisible())
CharacterFrame:Show();PaperDollFrame:Show()
assert(not InspectFrame:IsVisible() and S_ItemTip_InspectFrame.currentUnit=='player')
assert(S_ItemTip_InspectFrame.point[2]==CharacterFrame)
for i=1,24 do Tick() end
CharacterFrame:Hide();InspectFrame.unit='focus';InspectFrame:Show()
assert(S_ItemTip_InspectFrame:IsVisible() and S_ItemTip_InspectFrame.currentUnit=='focus','actual inspect OnShow hook updates equipment unit')
StatCompareTargetFrame.levelBg=nil
SCShowFrame(StatCompareTargetFrame,S_ItemTip_InspectFrame,'target','stats',-5,-5)
assert(StatCompareTargetFrameTitle:GetText()=='focus','actual target display follows inspected unit')
assert(StatCompareTargetFrame.point[2]==S_ItemTip_InspectFrame)
InspectFrame:Hide();Tick()
assert(not StatCompareTargetFrame:IsVisible() and not S_ItemTip_InspectFrame:IsVisible(),'actual inspect OnHide removes side panels')
print('PASS: 14 actual S_ItemTip creation, lifecycle, settings and dragging checks')
''')

files = [
    'StatCompare/PanelLayout.lua', 'StatCompare/StatCompare.lua', 'StatCompare/SCOptions.lua',
    'S_ItemTip/InspectFrame.lua', 'S_ItemTip/InspectGemAndEnchant.lua',
    'pfUI-addonskinner/skins/StatCompare.lua',
]
for file in files:
    code = (ROOT / file).read_text(encoding='utf-8-sig')
    runtime.execute('assert(loadstring(...))', code)
ET.parse(ROOT / 'StatCompare/StatCompare.xml')
print('PASS: all changed Lua files compile with Lua 5.1; XML parses')
