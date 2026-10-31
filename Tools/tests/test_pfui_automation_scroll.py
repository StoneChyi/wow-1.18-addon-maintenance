"""Event-driven scrolling of expanded automation settings with actual pfUI widgets.

Uses explicit UI geometry/focus events; no client FPS or gameplay claim.
Loads real EntryUpdate so the historical per-row polling cost is observable.
"""
from pathlib import Path
import json
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from test_pfui_automation_options import MOCK


def main():
    lua = LuaRuntime(unpack_returned_tuples=True)
    font = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute(MOCK, font)
    lua.execute(r'''
local methods=getmetatable(parent).__index
local create=obj
function obj(kind,name,parent)
 local result=create(kind,name,parent)
 result.children={}
 if parent then parent.children=parent.children or {};table.insert(parent.children,result) end
 return result
end
calls={get=0,set=0,notify=0,render=0,focus=0,mouse=0,lost=0,vertical=0,range=0,size=0,rowOps=0}
function fire(object,event,a,b)
 local old,old1,old2=this,arg1,arg2
 this,arg1,arg2=object,a,b
 if event=='OnEditFocusLost' then calls.lost=calls.lost+1 end
 if event=='OnVerticalScroll' then calls.vertical=calls.vertical+1 end
 if event=='OnScrollRangeChanged' then calls.range=calls.range+1 end
 if event=='OnSizeChanged' then calls.size=calls.size+1 end
 if object.scripts[event] then object.scripts[event]() end
 this,arg1,arg2=old,old1,old2
end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
local function notify(object,event)
 if event=='OnHide' and object.kind=='EditBox' and object.focused then object:ClearFocus() end
 fire(object,event)
 for _,child in ipairs(object.children or {}) do if child.shown then notify(child,event) end end
end
function methods:Show()
 if self.widget then calls.rowOps=calls.rowOps+1 end
 local was=self:IsVisible();self.shown=true
 if not was and self:IsVisible() then notify(self,'OnShow') end
end
function methods:Hide()
 if self.widget then calls.rowOps=calls.rowOps+1 end
 local was=self:IsVisible();self.shown=false
 if was then notify(self,'OnHide') end
end
function methods:SetFocus() self.focused=true;fire(self,'OnEditFocusGained') end
function methods:ClearFocus()
 if self.focused then self.focused=false;fire(self,'OnEditFocusLost') end
end
function methods:GetBottom() return 0 end
function methods:GetTop() return 800 end
function methods:GetEffectiveScale() return 1 end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(v) self.level=v end
function methods:EnableMouseWheel(v) self.wheel=v end
function methods:SetVertexColor(...) self.vertex=arg end
function methods:SetScrollChild(child) self.content=child end
function methods:GetVerticalScrollRange() return math.max(0,(self.content and self.content:GetHeight() or 0)-self:GetHeight()) end
function methods:UpdateScrollChildRect() fire(self,'OnScrollRangeChanged',0,self:GetVerticalScrollRange()) end
function methods:SetVerticalScroll(v)
 v=math.max(0,math.min(v,self:GetVerticalScrollRange()))
 local changed=self.scroll~=v;self.scroll=v
 if changed then fire(self,'OnVerticalScroll',v) end
end
function methods:SetMinMaxValues(a,b)
 self.minimum=a;self.maximum=b
 if self.value and (self.value<a or self.value>b) then self:SetValue(self.value) end
end
function methods:SetValue(v)
 v=math.max(self.minimum or 0,math.min(v,self.maximum or v))
 local changed=self.value~=v;self.value=v
 if changed then fire(self,'OnValueChanged',v) end
end
function methods:GetValue() return self.value or 0 end
local setHeight=methods.SetHeight
function methods:SetHeight(value)
 local changed=self.height~=value;setHeight(self,value)
 if changed then
  fire(self,'OnSizeChanged',self:GetWidth(),value)
  if self.parent and self.parent.content==self then self.parent:UpdateScrollChildRect() end
 end
end
function methods:SetOrientation(v) assert(v=='VERTICAL' or v=='HORIZONTAL') end
function methods:SetThumbTexture(v) self.thumb=obj('Texture',nil,self);self.thumb:SetTexture(v) end
function methods:GetThumbTexture() return self.thumb end
function SkinArrowButton(b) b.icon=obj('Texture',nil,b) end
function MouseIsOver() calls.mouse=calls.mouse+1;return true end
function GetMouseFocus() calls.focus=calls.focus+1;return nil end
RAID_CLASS_COLORS={PALADIN={r=1,g=1,b=1}}
GameFontWhite=GameFontHighlight
pfUI.api={};pfUI.media=setmetatable({},{__index=function(_,k)return k end})
UIParent=obj('Frame');pfUI.gui=obj('Frame',nil,UIParent)
OpacitySliderFrame=obj('Slider');ColorPickerFrame:Hide()
''')
    widgets = (ROOT / 'Interface/AddOns/pfUI/api/ui-widgets.lua').read_text(encoding='utf-8-sig')
    dropdown = widgets[widgets.index('do -- dropdown'):widgets.index('function pfUI.api.CreateTabChild')]
    scroll = widgets[widgets.index('function pfUI.api.CreateScrollFrame'):widgets.index('function pfUI.api.CreateTextBox')]
    lua.execute(dropdown + scroll)
    lua.execute("CreateDropDownButton=pfUI.api.CreateDropDownButton;parent=pfUI.api.CreateScrollChild(nil,pfUI.api.CreateScrollFrame(nil,pfUI.gui));parent.parent=parent:GetParent();parent.parent:SetHeight(240)")
    gui = (ROOT / 'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf-8-sig')
    start = gui.index('    function EntryUpdate(')
    lua.execute('local searchDB={}\n' + gui[start:gui.index('    local TabFrameOnMouseDown', start)] + '\npfUI.gui.CreateConfig=CreateConfig')
    lua.execute(r'''
this=parent
local legacy=pfUI.gui.CreateConfig(function()end,'Legacy',{value=''},'value','text')
assert(legacy:GetScript('OnUpdate'))
for i=1,3 do fire(legacy,'OnUpdate') end
assert(calls.focus==3 and calls.mouse>=3,'original polling cost was not modeled')
legacy:Hide();parent.objectCount=nil;this=nil
''')
    lua.execute((ROOT / 'Interface/AddOns/pfUI/modules/automation_options.lua').read_text(encoding='utf-8-sig'))
    lua.execute(r'''
local R=pfUI.automationOptions
local originalRender=R.Render
function R:Render(...) calls.render=calls.render+1;return originalRender(self,unpack(arg)) end
local saved={text='initial',pick='a',enabled=false,color={.2,.3,.4,1}}
local function get(key) calls.get=calls.get+1;return saved[key] end
local function set(key,value) calls.set=calls.set+1;saved[key]=value end
local options={
 pick={type='text',name='Pick',order=1,validate={a='Alpha',b='Beta'},get=function()return get('pick')end,set=function(v)set('pick',v)end},
 text={type='text',name='Text',desc='Text help',order=2,get=function()return get('text')end,set=function(v)set('text',v)end},
 toggle={type='toggle',name='Toggle',order=3,get=function()return get('enabled')end,set=function(v)set('enabled',v)end},
 color={type='color',name='Color',order=4,get=function()calls.get=calls.get+1;return unpack(saved.color)end,set=function(...)calls.set=calls.set+1;saved.color=arg end},
}
for i=1,1000 do
 local key='field'..i;saved[key]=i
 options[key]={type=i%2==0 and 'text' or 'toggle',name=key,order=i+4,
  get=function()return get(key)end,set=function(value)set(key,value)end}
end
local module={_options=options}
local function changed() calls.notify=calls.notify+1 end
assert(R:Render(parent,module,changed))
local state=parent.automationOptionsState
local scroll=parent.parent
assert(#state.visible==1004)
assert(parent:GetScript('OnUpdate')==nil,'scroll child still polls every frame')
for _,row in ipairs(state.visible) do assert(row:GetScript('OnUpdate')==nil,'row still polls mouse focus every frame') end
local maximumShown=0
local function checkViewport()
 local top,height=scroll:GetVerticalScroll(),scroll:GetHeight()
 local shown=0
 for _,row in ipairs(state.visible) do
  local expected=row.automationOffset+row.automationHeight>=top-48 and row.automationOffset<=top+height+48
  assert(row:IsShown()==expected,'wrong clipped visibility for '..row.option.name)
  if row:IsShown() then shown=shown+1 end
 end
 maximumShown=math.max(maximumShown,shown)
 assert(shown<=math.ceil((height+96)/22)+2,'too many active rows')
end
local function snapshot() return {calls.get,calls.set,calls.notify,calls.render,created,calls.focus,calls.mouse} end
local function unchanged(before)
 local after=snapshot()
 for i=1,#before do assert(after[i]==before[i],'scroll invoked callback/render/allocation/polling at metric '..i) end
end
checkViewport()
local before=snapshot()
local operations=0
for iteration=1,100 do
 local rowOps=calls.rowOps
 fire(scroll,'OnMouseWheel',iteration%2==0 and 1 or -1)
 checkViewport();assert(calls.rowOps-rowOps<80,'wheel scanned all row visibility')
 operations=operations+1
end
for _,fraction in ipairs({1,.5,.01,.8,0,.4,1,0}) do
 local rowOps=calls.rowOps
 scroll.slider:SetValue(scroll:GetVerticalScrollRange()*fraction)
 checkViewport();assert(calls.rowOps-rowOps<80,'slider scanned all row visibility')
 operations=operations+1
end
unchanged(before)
assert(calls.vertical>100,'native wheel/slider did not emit actual scroll callbacks')
-- A focused input leaving the viewport must actually receive focus loss,
-- retain its draft, and avoid submitting or rebuilding while scrolling.
local text=rowNamed('Text')
text.input:SetFocus();text.input:SetText('draft retained')
local lost=calls.lost;before=snapshot()
scroll.slider:SetValue(scroll:GetVerticalScrollRange());checkViewport()
assert(calls.lost==lost+1 and not text.input.focused and not text:IsShown())
assert(saved.text=='initial' and text.input:GetText()=='draft retained')
unchanged(before)
scroll.slider:SetValue(0);checkViewport();unchanged(before)
assert(text:IsShown() and text.input:GetText()=='draft retained')
fire(text.input,'OnEnterPressed')
assert(saved.text=='draft retained' and calls.set==1 and calls.notify==1)
text.input:SetFocus();text.input:SetText('hidden draft committed on close')
before=snapshot();scroll.slider:SetValue(scroll:GetVerticalScrollRange());unchanged(before)
assert(R:Suspend(parent))
assert(saved.text=='hidden draft committed on close' and calls.set==2)
assert(R:Render(parent,module,changed));scroll.slider:SetValue(0);checkViewport()
-- Detached dropdowns and color dialogs cannot remain active for hidden rows.
local pick=rowNamed('Pick').input
pick:ShowMenu();assert(pick.menuframe:IsShown())
before=snapshot();scroll.slider:SetValue(scroll:GetVerticalScrollRange())
assert(not pick.menuframe:IsShown());unchanged(before)
scroll.slider:SetValue(0)
fire(rowNamed('Color').color,'OnClick')
assert(ColorPickerFrame:IsShown() and R.colorRow==rowNamed('Color'))
before=snapshot();scroll.slider:SetValue(scroll:GetVerticalScrollRange())
assert(not ColorPickerFrame:IsShown() and not R.colorOwner and not R.colorRow);unchanged(before)
scroll.slider:SetValue(0)
GameTooltip:Hide();fire(rowNamed('Text'),'OnEnter')
assert(GameTooltip:IsShown() and R.tooltipRow==rowNamed('Text'))
before=snapshot();scroll.slider:SetValue(scroll:GetVerticalScrollRange())
assert(not GameTooltip:IsShown() and not R.tooltipRow);unchanged(before)
-- Boundaries use the actual native wheel clamping, direct placement emits
-- OnVerticalScroll, and viewport resizing updates without a full rebuild.
before=snapshot()
fire(scroll,'OnMouseWheel',100000)
assert(scroll:GetVerticalScroll()==0);checkViewport()
fire(scroll,'OnMouseWheel',-100000)
assert(scroll:GetVerticalScroll()==scroll:GetVerticalScrollRange());checkViewport()
local target=rowNamed('field700')
scroll:SetVerticalScroll(target.automationOffset)
assert(target:IsShown());checkViewport()
scroll:SetHeight(500);checkViewport()
scroll:SetHeight(240);checkViewport()
unchanged(before)
assert(scroll:GetScript('OnSizeChanged'),'resize callback missing')
assert(scroll:GetScript('OnScrollRangeChanged'),'range callback missing')
local oldRange=scroll:GetVerticalScrollRange();scroll.slider:SetValue(oldRange)
-- A filter shortening the content exercises real range/slider recursion.
local short={_options={text=options.text,toggle=options.toggle}}
assert(R:Render(parent,short,changed));checkViewport()
assert(#state.visible==2 and scroll:GetVerticalScrollRange()==0 and scroll:GetVerticalScroll()==0)
assert(not scroll.slider:IsShown())
assert(R:Render(parent,{_options={}},changed));checkViewport()
assert(#state.visible==0 and scroll:GetVerticalScrollRange()==0)
-- A failed hidden numeric draft must block an unrelated checkbox, preserve
-- both settings, and reveal the rejected input for correction.
options.field700.type='number'
assert(R:Render(parent,module,changed))
local invalid=rowNamed('field700')
scroll.slider:SetValue(invalid.automationOffset)
invalid.input:SetFocus();invalid.input:SetText('not a number')
scroll.slider:SetValue(0);assert(not invalid:IsShown())
local sets,notifications=calls.set,calls.notify
local toggle=rowNamed('Toggle')
toggle.input:SetChecked(1);fire(toggle.input,'OnClick')
assert(not saved.enabled and saved.field700==700 and calls.set==sets and calls.notify==notifications)
assert(invalid:IsShown() and invalid.input:GetText()=='not a number' and R.lastError)
assert(scroll.slider:GetValue()==scroll:GetVerticalScroll(),'revealed invalid draft did not sync slider position')
assert(not toggle.input:GetChecked(),'blocked toggle did not restore stored value')
checkViewport()
invalid.input:SetText('701');fire(invalid.input,'OnEnterPressed')
assert(saved.field700==701 and not R.lastError)
scroll.slider:SetValue(0);assert(toggle:IsShown());toggle.input:SetChecked(1);fire(toggle.input,'OnClick')
assert(saved.enabled,'corrected hidden draft still blocked later actions')
report={logical_rows=1004,scroll_operations=operations,maximum_shown_rows=maximumShown,
 focus_loss_events=calls.lost,scroll_events=calls.vertical,range_events=calls.range,
 verified='real native EntryUpdate, wheel, slider and renderer; simulated focus and geometry; no live FPS claim'}
''')
    print(json.dumps(dict(lua.globals().report.items()), ensure_ascii=True, sort_keys=True))


if __name__ == '__main__':
    main()
