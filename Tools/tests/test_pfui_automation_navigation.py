"""Real pfUI navigation helper with native tabs and strict WoW 1.12 UI mocks.

Offline checks only: viewport geometry, callbacks and object reuse do not replace
in-client visual acceptance. The automation engine and saved variables are not
loaded or changed by this test.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime
from test_pfui_automation_options import MOCK


NAV_MOCK = r'''
local methods = getmetatable(parent).__index
objects = {}
fontAttempts = {}
function methods:SetFont(path,size,flags)
 table.insert(fontAttempts,{path=path,size=size,object=self})
 if path~='valid-test-font.ttf' or type(size)~='number' or size<=0 then return nil end
 self.font={path,size,flags};return 1
end
local baseObj = obj
function obj(kind,name,parent)
 local o=baseObj(kind,name,parent);o.points={};o.children={}
 table.insert(objects,o)
 if parent and parent.children then table.insert(parent.children,o) end
 return o
end
local baseFontString=methods.CreateFontString
function methods:CreateFontString(name,layer,template)
 local o=baseFontString(self,name,layer,template)
 o.points={};o.children={};table.insert(objects,o)
 if self.children then table.insert(self.children,o) end
 return o
end
function methods:SetPoint(point,relative,relativePoint,x,y)
 assert(type(point)=='string' and type(relative)=='table' and type(relativePoint)=='string')
 assert(type(x)=='number' and type(y)=='number','legacy five-argument anchor signature')
 self.points=self.points or {};self.points[point]={relative,relativePoint,x,y}
 self.point={point,relative,relativePoint,x,y}
end
function methods:ClearAllPoints() self.points={};self.point=nil end
local function anchorY(anchor)
 if string.find(anchor[2],'TOP',1,true) then return anchor[1]:GetTop()+anchor[4] end
 if string.find(anchor[2],'BOTTOM',1,true) then return anchor[1]:GetBottom()+anchor[4] end
 return (anchor[1]:GetTop()+anchor[1]:GetBottom())/2+anchor[4]
end
local function anchored(self,edge)
 for point,anchor in pairs(self.points or {}) do
  if string.find(point,edge,1,true) then return anchorY(anchor) end
 end
end
function methods:GetTop()
 if self.viewportTop then return self.viewportTop end
 local top=anchored(self,'TOP');if top then return top end
 local bottom=anchored(self,'BOTTOM');if bottom then return bottom+self.height end
 return (self.bottom or 0)+self.height
end
function methods:GetBottom()
 if self.viewportBottom then return self.viewportBottom end
 local bottom=anchored(self,'BOTTOM');if bottom then return bottom end
 local top=anchored(self,'TOP');if top then return top-self.height end
 return self.bottom or 0
end
-- Legacy dual-anchor GetHeight can be scaled while GetTop/GetBottom stay in
-- local layout units. Tests below check actual bounds, not helper's formula.
function methods:GetHeight()
 if anchored(self,'TOP') and anchored(self,'BOTTOM') then
  return (self:GetTop()-self:GetBottom())*self:GetEffectiveScale()
 end
 return self.height
end
local function visibleEvent(o,event)
 fire(o,event)
 for _,child in ipairs(o.children or {}) do if child.shown then visibleEvent(child,event) end end
end
function methods:Show()
 if not self.shown then self.shown=true;visibleEvent(self,'OnShow') end
end
function methods:Hide()
 if self.shown then visibleEvent(self,'OnHide');self.shown=false end
end
function methods:IsVisible()
 if not self.shown then return false end
 return not self.parent or not self.parent.IsVisible or self.parent:IsVisible()
end
function methods:Click() fire(self,'OnMouseDown');fire(self,'OnClick') end
function methods:SetFocus() self.focus=true;fire(self,'OnEditFocusGained') end
function methods:ClearFocus() self.focus=nil;fire(self,'OnEditFocusLost') end
local baseText=methods.SetText
function methods:SetText(value)
 if self.kind=='EditBox' then assert(self.font,'EditBox text before valid font') end
 local previous=self.text;baseText(self,value)
 if self.kind=='EditBox' and previous~=self.text then fire(self,'OnTextChanged') end
end
function methods:RawStringWidth()
 local width=0
 for i=1,string.len(self.text or '') do
  local b=string.byte(self.text,i)
  if b<128 then width=width+7 elseif b>=192 then width=width+12 end
 end
 return width
end
function methods:GetStringWidth()
 local width=self:RawStringWidth()
 -- Legacy FontString line measurement can be constrained by its display box.
 -- A correct truncator removes that constraint while measuring full captions.
 return self.width and self.width>0 and math.min(width,self.width) or width
end
function methods:SetGradientAlpha(direction,...) assert(direction=='HORIZONTAL');self.gradient={...} end
function methods:SetTextColor(...) self.color={...} end
function methods:EnableMouseWheel(enabled) self.mouseWheel=enabled end
function methods:SetOrientation(value) assert(value=='VERTICAL');self.orientation=value end
function methods:SetMinMaxValues(low,high) assert(low<=high);self.low,self.high=low,high end
function methods:SetValue(value)
 value=math.max(self.low,math.min(value,self.high))
 local old=self.value;self.value=value
 if old~=value then fire(self,'OnValueChanged') end
end
function methods:GetValue() return self.value end
function methods:SetThumbTexture(path)
 assert(type(path)=='string');self.thumbTexture=obj('Texture',nil,self)
end
function methods:GetThumbTexture() return self.thumbTexture end
function wheel(frame,delta)
 local old=arg1;arg1=delta;fire(frame,'OnMouseWheel');arg1=old
end
function CreateScrollFrame(name,parent) return CreateFrame('ScrollFrame',name,parent) end
function CreateScrollChild(name,parent) return CreateFrame('Frame',name,parent) end
function SetAllPointsOffset(frame,parent,offset)
 frame:SetPoint('TOPLEFT',parent,'TOPLEFT',offset,-offset)
 frame:SetPoint('BOTTOMRIGHT',parent,'BOTTOMRIGHT',-offset,offset)
end
pfUI.api={CreateBackdrop=CreateBackdrop}
pfUI.gui.search=obj('EditBox');pfUI.gui.search:SetFontObject(GameFontHighlight)
pfUI.gui.frames={area=obj('Frame')}
pfUI.gui.frames.area.viewportTop=900
pfUI.gui.frames.area.viewportBottom=460
pfUI.gui.frames.area.scale=.75
'''


LOAD_HELPER = r'''
local source=...
-- Unlike gui.lua's registered module, this ordinary TOC chunk has no injected
-- C binding. Never let the native-GUI mock's C mask an invalid global lookup.
helperEnvironment=setmetatable({}, {__index=function(_,key)
 if key=='C' then error('automation navigation accessed unavailable global C') end
 return _G[key]
end})
local chunk=assert(loadstring(source,'@automation_navigation.lua'))
setfenv(chunk,helperEnvironment)
chunk()
'''


CASES = r'''
N=pfUI.automationNavigation
host={general='管理',merchant='商人服务',detail='功能设置',calls={}}
local nativeValues={}
for _,title in ipairs({host.general,host.detail,host.merchant}) do
 local caption=title
 CreateGUIEntry('自动化',title,function()
  nativeValues[caption]=(nativeValues[caption] or 0)+1
  CreateConfig(nil,caption,nil,nil,'header')
 end)
end
group=pfUI.gui.frames['自动化']
fire(group[host.general].area.scroll.content,'OnShow')
function host:OpenPage(page)
 table.insert(self.calls,{kind='page',name=page})
 group[page]:Click()
 N:Update(self,entries,page)
end
function host:SelectModule(name)
 table.insert(self.calls,{kind='module',name=name})
 group[self.detail]:Click()
 N:Update(self,entries,name)
end
local beforeAttach=created
s=N:Attach(host,group)
assert(s.frame:GetParent()==group.area)
assert(s.frame:GetTop()==900 and s.frame:GetBottom()==460)
assert(s.frame:GetHeight()==330,'scale regression model not active')
assert(s.capacity==17,'scaled menu left visible space unused')
assert(group[host.general].area:IsVisible(),'hiding native tab hid its content area')
for _,title in ipairs({host.general,host.detail,host.merchant}) do
 assert(not group[title]:IsShown(),'original native tab was not hidden')
 assert(group[title].area:GetScript('OnShow'),'native area lifecycle removed')
end
local attachedCount=created
assert(N:Attach(host,group)==s and created==attachedCount,'Attach leaked another menu')
assert(s.empty:IsShown() and s.count:GetText()=='0' and not s.slider:IsShown())
assert(s.manage.text:GetText()=='管理' and s.merchant.text:GetText()=='商人服务')

entries={}
for i=1,60 do
 entries[i]={name=string.format('Module%02d',i),label='自动模块'..i,description='说明 '..i}
end
entries[1].label='超级长中文模块名称与复杂选项测试功能（自动拾取）'
entries[1].description='独特描述 [100%]'
entries[2].native=true
entries[3].hidden=true
N:Update(host,entries,'Module01')
assert(table.getn(s.filtered)==59 and s.slider:IsShown())
assert(s.rows[1].text:GetText()~=entries[1].label and string.sub(s.rows[1].text:GetText(),-3)=='...')
assert(s.rows[1].text:RawStringWidth()<=114 and s.rows[1].text:GetWidth()==114)
assert(s.rows[1].text.font and s.search.font,'failed custom font lost fallback')
assert(s.rows[1].text.color[1]==.2 and s.rows[2].text.color[1]==1)
assert(s.rows[3].entry.name=='Module04','hidden module included in navigation')

-- Independent geometric containment checks: physical row rectangles versus
-- the fixed search/footer rectangles, at several scales and viewport sizes.
function checkBounds()
 local top,bottom=s.frame:GetTop(),s.frame:GetBottom()
 assert(s.manage:GetTop()==top and s.manage:GetBottom()==top-20)
 assert(s.merchant:GetTop()==top-20 and s.merchant:GetBottom()==top-40)
 local previous=s.search:GetBottom()
 local visible=0
 for _,row in ipairs(s.rows) do
  if row:IsShown() then
   visible=visible+1
   assert(row:GetTop()<=previous,'row overlaps search or preceding module')
   assert(row:GetBottom()>=s.count:GetTop(),'module extends into fixed footer')
   assert(row:GetTop()-row:GetBottom()==20)
   assert(row:GetTop()<=top and row:GetBottom()>=bottom,'row escapes viewport')
   assert(row.text:RawStringWidth()<=row:GetWidth()-8,'label spills outside row')
   assert(row.text:GetWidth()==114,'measurement forgot to restore display width')
   previous=row:GetBottom()
  end
 end
 assert(visible>0)
 if table.getn(s.filtered)>visible then
  assert(previous-s.count:GetTop()<20,'full module row worth of blank space at bottom')
 end
end
for _,scale in ipairs({1,.75,.64}) do
 for _,height in ipairs({440,300,560}) do
  group.area.viewportTop=900;group.area.viewportBottom=900-height;group.area.scale=scale
  fire(s.frame,'OnSizeChanged');checkBounds()
 end
end
group.area.viewportBottom=460;group.area.scale=.75
fire(s.frame,'OnSizeChanged');checkBounds()
assert(s.capacity==17)
-- During initial layout the edge coordinates may be unavailable. Exercise
-- the legacy scaled-height fallback without inventing modern rectangle APIs.
s.frame.GetTop=function() return nil end
s.frame.GetBottom=function() return nil end
s.frame.GetHeight=function() return 330 end
N:Render(s);assert(s.capacity==17,'fallback failed to undo effective scale')
s.frame.GetTop=nil;s.frame.GetBottom=nil;s.frame.GetHeight=nil

fire(s.rows[1],'OnEnter')
assert(s.tipOwner==s.rows[1] and GameTooltip:IsShown())
assert(GameTooltip:GetText()==entries[1].label,'tooltip lost full module name')
wheel(s.rows[1],-1)
assert(s.offset==3 and not GameTooltip:IsShown() and not s.tipOwner)
assert(s.manage:GetTop()==900 and s.merchant:GetTop()==880,'fixed buttons scrolled')
assert(s.rows[1].entry.name=='Module05')
s.rows[1]:Click()
assert(host.calls[table.getn(host.calls)].name=='Module05')
assert(group[host.detail].area:IsVisible() and not group[host.general].area:IsShown())
assert(s.frame:IsVisible(),'native tabs accidentally classified navigation as a page')
assert(nativeValues[host.detail]==1,'real native content lifecycle failed')
s.manage:Click();assert(host.calls[table.getn(host.calls)].name==host.general)
assert(group[host.general].area:IsVisible() and not group[host.detail].area:IsShown())
s.merchant:Click();assert(host.calls[table.getn(host.calls)].name==host.merchant)
assert(group[host.merchant].area:IsVisible() and nativeValues[host.merchant]==1)
assert(s.merchant.text.color[1]==.2 and s.manage.text.color[1]==1)

s.search:SetFocus();assert(not s.hint:IsShown())
s.search:SetText('mOdUlE60');assert(table.getn(s.filtered)==1 and s.rows[1].entry.name=='Module60')
assert(not s.slider:IsShown() and s.count:GetText()=='1-1 / 1')
s.search:SetText('[100%]');assert(table.getn(s.filtered)==1 and s.rows[1].entry.name=='Module01')
s.search:SetText('独特描述');assert(table.getn(s.filtered)==1)
s.search:SetText('no-such-module');assert(s.empty:IsShown() and s.count:GetText()=='0')
for _,row in ipairs(s.rows) do assert(not row:IsShown(),'stale row remained after empty filter') end
fire(s.search,'OnEscapePressed');assert(s.query=='' and not s.search.focus and s.hint:IsShown())
s.search:SetText('Module01');N:EnsureVisible(host,'Module60')
assert(s.query=='' and s.offset==42 and s.rows[17].entry.name=='Module60')
N:EnsureVisible(host,'Module01');assert(s.offset==0)
s.search:SetText('Module01');N:EnsureVisible(host,'Module03')
assert(s.query=='Module01' and entries[3].hidden,'EnsureVisible unhides hidden module')
N:EnsureVisible(host,'does-not-exist');assert(s.query=='Module01')
fire(s.search,'OnEscapePressed')
s.slider:SetValue(9999);assert(s.offset==42)
wheel(s.frame,-100);assert(s.offset==42)
s.slider:SetValue(4.6);assert(s.offset==5)
wheel(s.frame,100);assert(s.offset==0)

-- Hide/reorder updates change only the view and callback target. The helper
-- must not rewrite persistent entry order/hidden flags or enable modules.
local reversed={}
for i=60,1,-1 do table.insert(reversed,entries[i]) end
local firstRow=s.rows[1]
entries=reversed
N:Update(host,entries,'Module60')
assert(s.rows[1]==firstRow and s.rows[1].entry.name=='Module60')
s.rows[1]:Click();assert(host.calls[table.getn(host.calls)].name=='Module60','reused row retained old callback ID')
entries[1].hidden=true
local calls=table.getn(host.calls)
N:Update(host,entries,'Module60')
assert(s.rows[1].entry.name=='Module59' and table.getn(host.calls)==calls)
assert(entries[1].name=='Module60' and entries[1].hidden,'helper altered model order/visibility')
entries[1].hidden=nil;N:Update(host,entries,'Module60')
assert(s.rows[1].entry.name=='Module60')
local warmed=created
for i=1,100 do
 wheel(s.frame,-1);wheel(s.frame,1)
 s.search:SetText('Module60');s.search:SetText('')
 entries[1].hidden=true;N:Update(host,entries,'Module60')
 entries[1].hidden=nil;N:Update(host,entries,'Module60')
 N:EnsureVisible(host,'Module01');N:EnsureVisible(host,'Module60')
end
assert(created==warmed,'scroll/search/hide/selection allocated objects after warmup')
assert(table.getn(s.rows)==23,'resized viewport row pool was not reused')
for _,o in ipairs(objects) do
 local p=o
 while p and p~=s.frame do p=p.GetParent and p:GetParent() end
 if p==s.frame then
  assert(not o:GetScript('OnUpdate'),'navigation adds per-frame polling')
  if o.kind=='FontString' or o.kind=='EditBox' then assert(o.font,'missing fallback font') end
 end
end
assert(s.frame.GetStringHeight==nil and s.rows[1].text.SetWordWrap==nil,'modern API accidentally mocked')
fire(s.rows[1],'OnEnter');s.search:SetFocus();s.frame:Hide()
assert(not s.search.focus and not GameTooltip:IsShown() and not s.tipOwner)
s.frame:Show();checkBounds()
assert(nativeValues[host.general]==1 and nativeValues[host.detail]==1 and nativeValues[host.merchant]==1)
print('PASS: native tabs/CreateConfig lifecycle; viewport geometry/scales; UTF-8/font fallback; 60-module search, hide, reorder, scroll, callback and object reuse; no polling')

-- Replace the global configuration table after the chunk was loaded: ordinary
-- chunks must read current pfUI_config, not a cached/injected GUI-local C.
local originalConfig,originalFont=pfUI_config,pfUI.font_default
local function freshMenu()
 local g={area=obj('Frame')}
 g.area.viewportTop=900;g.area.viewportBottom=460;g.area.scale=.75
 local h={general='管理',merchant='商人服务'}
 return N:Attach(h,g)
end
pfUI_config={global={font_size='19'}};pfUI.font_default='valid-test-font.ttf'
local configured=freshMenu()
assert(C.global.font_size==12,'native GUI control config was not independent')
assert(configured.manage.text.font[2]==19 and configured.search.font[2]==19)
assert(configured.hint.font[1]=='valid-test-font.ttf' and configured.hint.font[2]==19)
pfUI_config={global={font_size='15'}};pfUI.font_default='missing-font.ttf'
local failed=freshMenu()
assert(failed.manage.text.font[1]=='Fonts\\FZXHLJW.TTF' and failed.manage.text.font[2]==10)
assert(failed.search.font[1]=='Fonts\\FZXHLJW.TTF' and failed.search.font[2]==10)
local seenSearch,seenLabel
for _,attempt in ipairs(fontAttempts) do
 if attempt.object==failed.search then seenSearch=attempt.size==15 and attempt.path=='missing-font.ttf' end
 if attempt.object==failed.manage.text then seenLabel=attempt.size==15 and attempt.path=='missing-font.ttf' end
end
assert(seenSearch and seenLabel,'font failure path did not read current configuration')
pfUI_config=originalConfig;pfUI.font_default=originalFont
print('PASS: ordinary chunk rejects global C; dynamic pfUI_config font size; successful font and failed-font fallback')
'''


def main():
    lua = LuaRuntime(unpack_returned_tuples=True)
    font = lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8-sig"))
    lua.execute(MOCK, font)
    lua.execute(NAV_MOCK)
    source = (ROOT / "Interface/AddOns/pfUI/modules/gui.lua").read_text(encoding="utf-8-sig")
    start = source.index("    function CreateConfig(")
    end = source.index("  do -- GUI Frame", start)
    lua.execute("do local searchDB={}\n" + source[start:end])
    lua.execute(LOAD_HELPER, (ROOT / "Interface/AddOns/pfUI/modules/automation_navigation.lua").read_text(encoding="utf-8-sig"))
    lua.execute(CASES)
    # Lupa decodes the actual rendered label as UTF-8: a partial multibyte suffix
    # raises here rather than passing a byte-only width/truncation assertion.
    lua.execute("entries[60].hidden=nil; N:Update(host,entries,'Module01'); N:EnsureVisible(host,'Module01')")
    labels = [lua.globals().s.rows[i].text.GetText(lua.globals().s.rows[i].text)
              for i in range(1, int(lua.globals().s.capacity) + 1)]
    assert any(label.endswith("...") and "中文" in label for label in labels)
    print("PASS: truncated rendered Chinese labels remain valid UTF-8")


if __name__ == "__main__":
    main()
