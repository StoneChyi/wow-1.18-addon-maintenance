"""Execute actual pfUI dropdown/scroll/renderer with per-object legacy API limits.

The contract rejects modern or wrong-object APIs instead of providing every
method on every fake object. Geometry/server behavior still requires the client.
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from test_pfui_automation_options import MOCK

contract = json.loads((Path(__file__).with_name('pfui_automation_api_contract.json')).read_text(encoding='utf8'))
# New client calls cannot silently pass because the permissive old mock happens
# to expose them. Addon methods declared in the file remain outside this API list.
for relative in ('Interface/AddOns/pfUI/modules/automation.lua', 'Interface/AddOns/pfUI/modules/automation_options.lua'):
    source = (ROOT / relative).read_text(encoding='utf8')
    reviewed = {entry['method'] for entry in contract['calls'] if entry['file'] == relative}
    declared = set(re.findall(r'function\s+[\w.]+:(\w+)\(', source))
    unknown = set(re.findall(r':(\w+)\(', source)) - reviewed - declared
    assert not unknown, f'Client/helper calls need explicit API review: {relative}: {sorted(unknown)}'
    assert ':GetStringHeight(' not in source
allowed = {}
for kind in contract['classes']:
    names = set()
    base = kind
    while base:
        names.update(contract['classes'][base])
        base = contract['parents'].get(base)
    allowed[kind] = names

lua = LuaRuntime(unpack_returned_tuples=True)
font = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf8'))
lua.execute(MOCK, font)
limits = lua.table()
for kind, names in allowed.items():
    limits[kind] = lua.table_from({name: True for name in names})
lua.globals().apiLimits = limits
lua.execute(r'''
local methods=getmetatable(parent).__index
local function typed(o)
 setmetatable(o,{__index=function(t,key)
  if apiLimits[t.kind] and apiLimits[t.kind][key] then return methods[key] end
  return nil
 end})
 return o
end
local create=obj
function obj(kind,name,parent) return typed(create(kind,name,parent)) end
local fontCreate=methods.CreateFontString
function methods:CreateFontString(...) return typed(fontCreate(self,unpack(arg))) end
function methods:GetBottom() return self.bottom or 400 end
function methods:GetTop() return self.top or 800 end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(v) assert(type(v)=='number');self.level=v end
function methods:EnableMouseWheel(v) self.wheel=v end
function methods:SetVertexColor(...) self.vertex=arg end
function methods:SetScrollChild(child) self.content=child end
function methods:GetVerticalScrollRange() return math.max(0,(self.content and self.content:GetHeight() or 0)-self:GetHeight()) end
function methods:UpdateScrollChildRect() end
function methods:SetMinMaxValues(a,b) self.minimum=a;self.maximum=b end
function methods:SetValue(v)
 local changed=self.value~=v;self.value=v
 if changed then fire(self,'OnValueChanged') end
end
function methods:GetValue() return self.value or 0 end
function methods:SetOrientation(v) assert(v=='VERTICAL' or v=='HORIZONTAL') end
function methods:SetThumbTexture(v) self.thumb=obj('Texture',nil,self);self.thumb:SetTexture(v) end
function methods:GetThumbTexture() return self.thumb end
function methods:Show() local was=self.shown;self.shown=true;if not was then fire(self,'OnShow') end end
function methods:Hide() local was=self.shown;self.shown=false;if was then fire(self,'OnHide') end end
function SkinArrowButton(b) b.icon=obj('Texture',nil,b) end
function MouseIsOver() return true end
RAID_CLASS_COLORS={PALADIN={r=1,g=1,b=1}}
GameFontWhite=GameFontHighlight
pfUI.api={};pfUI.media=setmetatable({},{__index=function(_,k)return k end})
UIParent=obj('Frame');UIParent.bottom=0
pfUI.gui=obj('Frame',nil,UIParent);pfUI.gui.bottom=10
ColorPickerFrame.kind='ColorSelect';typed(ColorPickerFrame)
OpacitySliderFrame=obj('Slider')
OpacitySliderFrame:SetScript('OnValueChanged',function()
 if ColorPickerFrame.opacityFunc then ColorPickerFrame.opacityFunc() end
end)
-- Original 1.12.1 ColorPickerFrame.xml: OnShow initializes the opacity slider;
-- SetColorRGB/slider changes can invoke callbacks during initialization.
ColorPickerFrame:SetScript('OnShow',function()
 if this.hasOpacity then OpacitySliderFrame:Show();OpacitySliderFrame:SetValue(this.opacity)
 else OpacitySliderFrame:Hide() end
end)
function ColorPickerFrame:SetColorRGB(r,g,b)
 self.rgb={r,g,b};if self.func then self.func() end
end
ColorPickerFrame:Hide()
-- Negative controls: wrong-object and missing APIs really are absent.
assert(obj('FontString').GetStringHeight==nil)
assert(obj('FontString').SetScript==nil)
assert(obj('EditBox').Disable==nil)
assert(obj('Button').GetVerticalScrollRange==nil)
''')
widgets=(ROOT/'Interface/AddOns/pfUI/api/ui-widgets.lua').read_text(encoding='utf8')
dropdown=widgets[widgets.index('do -- dropdown'):widgets.index('function pfUI.api.CreateTabChild')]
scroll=widgets[widgets.index('function pfUI.api.CreateScrollFrame'):widgets.index('function pfUI.api.CreateTextBox')]
lua.execute(dropdown + scroll)
lua.execute('CreateDropDownButton=pfUI.api.CreateDropDownButton; parent=pfUI.api.CreateScrollChild(nil,pfUI.api.CreateScrollFrame(nil,pfUI.gui));parent.parent=parent:GetParent();parent.parent:SetHeight(150)')
gui=(ROOT/'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf8')
start=gui.index('    function CreateConfig(')
lua.execute('local searchDB={}\n'+gui[start:gui.index('    local TabFrameOnMouseDown',start)]+'\npfUI.gui.CreateConfig=CreateConfig')
lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation_options.lua').read_text(encoding='utf8'))
lua.execute(r'''
local R=pfUI.automationOptions
local selected='item1';local text='initial';local enabled=false
local choices={};for i=1,70 do choices['item'..i]='Choice '..i end
local opts={_options={
 pick={type='text',name='Pick',order=1,validate=choices,get=function()return selected end,set=function(v)selected=v end},
 text={type='text',name='Text',order=2,get=function()return text end,set=function(v)text=v end},
 toggle={type='toggle',name='Toggle',order=3,get=function()return enabled end,set=function(v)enabled=v end},
 info={type='description',name=string.rep('long ',100),order=4},
 action={type='execute',name='Action',order=5,func=function()end},
}}
R:Render(parent,opts)
local pick=rowNamed('Pick').input
pick:ShowMenu()
assert(#pick.menu==70 and #pick.menuframe.elements==70)
assert(pick.maxrows>0 and pick.maxrows<70)
local old=this;this=pick.menuframe;arg1=-1;pick.menuframe:GetScript('OnMouseWheel')();this=old
assert(pick.menuscroll==1)
local entry=pick.menuframe.elements[2];local label=pick.menu[entry.id].text
fire(entry,'OnClick');assert(selected and pick.text:GetText()==label and not pick.menuframe:IsShown())
rowNamed('Text').input:SetText('saved');fire(rowNamed('Text').input,'OnEnterPressed');assert(text=='saved')
rowNamed('Toggle').input:SetChecked(1);fire(rowNamed('Toggle').input,'OnClick');assert(enabled)
assert(parent.parent:GetVerticalScrollRange()>0 and parent.parent.slider:IsShown())
parent.parent:Scroll(-20);assert(parent.parent:GetVerticalScroll()>0)
pick:ShowMenu();R:Suspend(parent);assert(not pick.menuframe:IsShown())
R:Render(parent,opts);assert(rowNamed('Text').input:GetText()=='saved' and rowNamed('Toggle').input:GetChecked())
opts._options.text.disabled=true
R:Render(parent,opts)
assert(rowNamed('Text').input.Disable==nil,'modern EditBox Disable leaked into contract')
assert(rowNamed('Text').input.keyboard==false and rowNamed('Text').input.mouse==false)
opts._options.text.disabled=false
R:Render(parent,opts)
assert(rowNamed('Text').input.keyboard==true and rowNamed('Text').input.mouse==true)
local ca={.1,.2,.3,.2};local cb={.6,.7,.8,.8}
opts._options.a={type='color',name='Color A',order=6,hasAlpha=true,
 get=function()return unpack(ca)end,set=function(...)ca=arg end}
opts._options.b={type='color',name='Color B',order=7,hasAlpha=true,
 get=function()return unpack(cb)end,set=function(...)cb=arg end}
R:Render(parent,opts)
fire(rowNamed('Color A').color,'OnClick')
assert(math.abs(OpacitySliderFrame:GetValue()-.8)<.0001)
OpacitySliderFrame:SetValue(.4)
assert(math.abs(ca[4]-.6)<.0001)
fire(rowNamed('Color B').color,'OnClick')
assert(math.abs(OpacitySliderFrame:GetValue()-.2)<.0001)
assert(math.abs(ca[4]-.6)<.0001 and math.abs(cb[4]-.8)<.0001,'opening second picker changed first setting')
OpacitySliderFrame:SetValue(.7);assert(math.abs(cb[4]-.3)<.0001)
HideUIPanel(ColorPickerFrame);ColorPickerFrame.cancelFunc()
assert(math.abs(cb[4]-.8)<.0001 and math.abs(ca[4]-.6)<.0001)
local count=created
for i=1,20 do R:Render(parent,opts);rowNamed('Pick').input:ShowMenu();R:Suspend(parent) end
assert(created==count,'real dropdown/render pool leaks controls')
''')
print('PASS: typed legacy API contract, actual native dropdown (70 entries/scroll/selection), actual scroll frame, renderer edit/toggle/reopen, bounded reuse')
