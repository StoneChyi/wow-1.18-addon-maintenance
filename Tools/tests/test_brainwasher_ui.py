"""Actual BrainwasherPro UI/skin, strict fonts and 1.12 frame hierarchy mocks."""
from pathlib import Path
import ast
import sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

def literal(name, key):
    tree = ast.parse((ROOT / 'PluginHistory/Evidence/addons_tmp' / name).read_text(encoding='utf-8-sig'))
    return next(ast.literal_eval(n.value) for n in tree.body if isinstance(n, ast.Assign)
                and any(isinstance(t, ast.Name) and t.id == key for t in n.targets))

brain = (ROOT / 'Interface/AddOns/BrainwasherPro/BrainwasherPro.lua').read_text(encoding='utf-8-sig')
skin = (ROOT / 'Interface/AddOns/pfUI-addonskinner/skins/BrainwasherPro.lua').read_text(encoding='utf-8-sig')
widgets = (ROOT / 'Interface/AddOns/pfUI/api/ui-widgets.lua').read_text(encoding='utf-8-sig')
font = (ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig')
for style in ('dark', 'classic'):
    rt = LuaRuntime()
    rt.execute(literal('test_bcs_float.py', 'STUB'))
    rt.execute(literal('test_talent_preset_sync.py', 'GAME_STUB'))
    rt.execute(r'''
local methods=getmetatable(UIParent).__index
local function object(kind,name,parent)
 local o=CreateFrame(kind,name,parent);o.regions={};return o
end
local install=assert(loadstring(...))();install(methods,object)
-- Additional valid built-in template used by this addon.
local createFS=methods.CreateFontString
function methods:CreateFontString(name,layer,template)
 return createFS(self,name,layer,template=='GameFontNormalSmall' and 'GameFontNormal' or template)
end
failedFontPaths['Fonts\\FRIZQT__.TTF']=true
local uninitialized=UIParent:CreateFontString()
assert(not pcall(function() uninitialized:SetText('') end),'font contract must reject even empty text')
assert(not uninitialized:SetFont('Fonts\\FRIZQT__.TTF',12),'missing font must fail')
function methods:GetCenter() return 640,360 end
function methods:GetScript(k) return self.scripts[k] end
function methods:GetFrameStrata() return self.strata or (self.parent and self.parent:GetFrameStrata()) or 'MEDIUM' end
function methods:SetFrameStrata(v) self.strata=v end
function methods:GetFrameLevel() return self.level or (self.parent and self.parent:GetFrameLevel()+1) or 0 end
function methods:SetFrameLevel(v) self.level=v end
function methods:IsObjectType(kind)
 return self.kind==kind or (kind=='Frame' and self.kind~='Texture' and self.kind~='FontString')
end
function methods:GetChildren()
 local a={};for _,f in ipairs(allFrames) do if f.parent==self and f.kind~='Texture' and f.kind~='FontString' then table.insert(a,f) end end
 return unpack(a)
end
function methods:GetRegions()
 local a={};for _,f in ipairs(allFrames) do if f.parent==self and (f.kind=='Texture' or f.kind=='FontString') then table.insert(a,f) end end
 return unpack(a)
end
function methods:CreateTexture(name,layer) local t=object('Texture',name,self);t.layer=layer;return t end
function methods:GetDrawLayer() return self.layer end
function methods:SetVertexColor(...) self.tint={...} end
function methods:SetBackdrop(v) self.backdropDef=v end
function methods:SetBackdropColor(...) self.fill={...} end
function methods:SetBackdropBorderColor(...) self.border={...} end
for _,state in ipairs({'Normal','Highlight','Pushed','Disabled'}) do
 local k=state
 methods['Set'..k..'Texture']=function(self,path,blend)
  local t=self['texture'..k] or self:CreateTexture(nil,k=='Highlight' and 'HIGHLIGHT' or 'ARTWORK')
  t:SetTexture(path);t.blend=blend;self['texture'..k]=t
 end
 methods['Get'..k..'Texture']=function(self) return self['texture'..k] end
end
local oldCreate=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=oldCreate(kind,name,parent,template)
 if template=='UIPanelButtonTemplate' then f:SetNormalTexture('Interface\\Buttons\\UI-Panel-Button-Up') end
 if template=='UIPanelCloseButton' then f:SetNormalTexture('Interface\\Buttons\\UI-Panel-MinimizeButton-Up') end
 return f
end
function HookScript(f,k,fn)
 local old=f:GetScript(k);f:SetScript(k,function() if old then old() end;fn() end)
end
function GetStringColor() return .3,.3,.3,1 end
function MouseIsOver() return false end
UISpecialFrames={};GossipFrame=CreateFrame('Frame','GossipFrame')
pfUI_config={appearance={border={color='gray'}},global={font_size=12}}
pfUI={api={},font_default='Fonts\\FRIZQT__.TTF',addonskinner={}}
function pfUI.addonskinner:RegisterSkin(name,fn) skinCallback=fn end
function pfUI.api.CreateBackdrop(f)
 if not f.backdrop then f.backdrop=CreateFrame('Frame',nil,f) end
 f.backdrop:SetFrameLevel(math.max(0,f:GetFrameLevel()-1));f.backdrop:SetBackdropBorderColor(.3,.3,.3,1)
end
checks=0
function check(v,label) assert(v,label);checks=checks+1 end
''', font)
    # Use actual pfUI hover chaining, SkinButton and texture stripping functions.
    rt.execute(widgets[widgets.index('local function SetHighlightEnter()'):widgets.index('-- [ Skin Collapse Button ]')])
    rt.execute(widgets[widgets.index('function pfUI.api.StripTextures('):widgets.index('function pfUI.api.SetAllPointsOffset(')])
    rt.execute('SetHighlight=pfUI.api.SetHighlight')
    rt.execute(brain)
    rt.globals().legacyStyle = style
    rt.execute(r'''
BrainwasherProDB={specs={},style=legacyStyle}
event='ADDON_LOADED';arg1='BrainwasherPro'
for _,f in ipairs(allFrames) do if f.events and f.events.GOSSIP_SHOW then f:Fire('OnEvent');break end end
check(BrainwasherPro.currentStyle=='dark','legacy style value ignored')
BrainwasherPro:CreateMainFrame();BrainwasherPro:CreateEditFrame()
local main,edit=BrainwasherProFrame,BrainwasherProEditFrame
check(main:GetFrameStrata()=='DIALOG' and edit:GetFrameStrata()=='DIALOG','both windows above HIGH action bars')
check(edit:GetFrameLevel()>main:GetFrameLevel()+5,'editor above main controls')
check(not StaticPopupDialogs.BRAINWASHERPRO_SWITCH_STYLE,'style confirmation removed')
for _,f in ipairs(allFrames) do
 check(f:GetText()~='经典风格' and f:GetText()~='暗黑风格','style button absent')
end
main:Show();main:Hide();main:Show()
check(main:GetFrameStrata()=='DIALOG','layer survives reopen')
''')
    rt.execute(skin)
    rt.execute(r'''
local main,edit=BrainwasherProFrame,BrainwasherProEditFrame
local actions={}
for _,f in ipairs(allFrames) do if f.kind=='Button' then actions[f]=f:GetScript('OnClick') end end
skinCallback()
local count=0
for f,click in pairs(actions) do
 if f:GetParent()~=BrainwasherProIconContent then
  check(f:GetHighlightTexture() and f:GetHighlightTexture():GetTexture()=='Interface\\Buttons\\WHITE8X8','visible native hover texture')
  check(f:GetPushedTexture() and f:GetPushedTexture().tint[4]>.2,'native press texture')
  check(f:GetScript('OnClick')==click,'click callback preserved')
  local base=f.backdrop.border[1];f:Fire('OnEnter')
  check(f.backdrop.border[1]>base,'hover changes actual pfUI border')
  f:Fire('OnLeave');check(f.backdrop.border[1]==base,'leave restores border')
  count=count+1
 end
end
check(count>=15,'main/editor controls covered')
local fontsBefore=0
for _,f in ipairs(allFrames) do if f.xtext then fontsBefore=fontsBefore+1;check(f.xtext.font and f.xtext.font[1]=='Fonts\\FZXHLJW.TTF' and f.xtext:GetText()=='×','close font fallback survives failed font file') end end
check(fontsBefore==2,'both close buttons rendered')
skinCallback();skinCallback()
local fontsAfter=0
for _,f in ipairs(allFrames) do if f.xtext then fontsAfter=fontsAfter+1 end end
check(fontsAfter==fontsBefore,'repeated skin reuses close labels')
check(BrainwasherProEditFrame.iconButton.iconTexture:IsShown(),'editor icon survives repeated skin')
check(main:GetFrameLevel()==10 and edit:GetFrameLevel()==20,'skin leaves window levels intact')
menuEntries={};edit.presetMenu.initialize();check(#menuEntries==8,'preset choices still available')
print('PASS: '..checks..' actual UI/skin/font checks for legacy style '..legacyStyle)
''')
print('Lua 5.1 syntax and mock UI checks only; in-game hover/layer acceptance pending.')
