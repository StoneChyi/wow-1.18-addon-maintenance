"""Actual automation host + option renderer + native pfUI CreateConfig integration.
WoW frames are simulated; no live-game visual or server acceptance is claimed.
"""
from pathlib import Path
import sys
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from test_pfui_automation_options import MOCK

lua=LuaRuntime(unpack_returned_tuples=True)
font=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
lua.execute(MOCK,font)
source=(ROOT/'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf-8-sig')
start=source.index('    function CreateConfig(')
end=source.index('    local TabFrameOnMouseDown',start)
lua.execute('local searchDB={}\n'+source[start:end]+'\npfUI.gui.CreateConfig=CreateConfig; nativeSearchDB=searchDB')
lua.execute(r'''
local methods=getmetatable(parent).__index
function methods:GetScale() return self.scale or 1 end
function methods:SetScale(value) self.scale=value end
function methods:RegisterEvent() end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
local function notifyChildren(object,event)
 for _,child in ipairs(object.children or {}) do
  if child.shown then fire(child,event);notifyChildren(child,event) end
 end
end
function methods:Show()
 local was=self.shown;self.shown=true
 if not was then
  fire(self,'OnShow')
  notifyChildren(self,'OnShow')
 end
end
function methods:Hide()
 local was=self.shown;self.shown=false
 if was then
  fire(self,'OnHide')
  notifyChildren(self,'OnHide')
 end
end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:GetVerticalScrollRange()
 local content=self.content
 local height=content and content:GetHeight() or 0
 if content and content.anchors and content.anchors.all then height=self:GetHeight() end
 return math.max(0,height-self:GetHeight())
end
function methods:SetAllPoints(parent) self.anchors={all=parent} end
function methods:ClearAllPoints() self.anchors={} end
function methods:SetPoint(...) self.anchors=self.anchors or {};table.insert(self.anchors,arg) end
function methods:SetMinMaxValues(min,max) self.min=min;self.max=max end
function methods:SetValue(value) self.value=value end
function methods:UpdateScrollChildRect() end
function methods:GetNumPoints() return self.point and 1 or 0 end
function methods:Click() fire(self,'OnClick') end
local create=CreateFrame
function CreateFrame(kind,name,parent,template)
 local result=create(kind,name,parent,template)
 if parent then parent.children=parent.children or {};table.insert(parent.children,result) end
 return result
end
UIParent=obj('Frame');UIParent.width=1920;UIParent.height=1080
pfUI.gui.width=720;pfUI.gui.height=480;pfUI.gui.frames={}
function pfUI.gui.CreateGUIEntry(parent,title,populate)
 local groups=pfUI.gui.frames
 if not groups[parent] then
  local group=CreateFrame('Button',nil,pfUI.gui);group.area=CreateFrame('Frame',nil,pfUI.gui)
  group:SetScript('OnClick',function() group.area:Show() end);groups[parent]=group
 end
 local group=groups[parent]
 if group[title] then return end
 local tab=CreateFrame('Button',nil,group.area);tab.area=CreateFrame('Frame',nil,group.area)
 tab.area.scroll=CreateFrame('ScrollFrame',nil,tab.area);tab.area.scroll.height=420
 tab.area.scroll.content=CreateFrame('Frame',nil,tab.area.scroll)
 tab.area.scroll.content.parent=tab.area.scroll
 tab.area.scroll.content:SetAllPoints(tab.area.scroll)
 tab.area.scroll.content:SetScript('OnShow',function()
  if not this.setup then populate();this.setup=true end
 end)
 tab.area:Hide()
 tab:SetScript('OnClick',function()
  for _,entry in pairs(group) do
   if type(entry)=='table' and entry.area and entry~=tab then entry.area:Hide() end
  end
  tab.area:Show()
  local content=tab.area.scroll.content
  if not content.setup then fire(content,'OnShow') end
 end)
 group[title]=tab
end
now=0
function GetTime() return now end
function GetItemInfo(id) return 'Item '..id end
DEFAULT_CHAT_FRAME={AddMessage=function()end}
C.global.autorepair='0';C.global.autosell='0';C.automation={enabled='1'}
Automaton.db={char={disabledModules={},hiddenModules={}},profile={moduleScope='char'}}
function Automaton:GetModuleScope() return self.db.profile.moduleScope end
function Automaton:ApplyModuleScope(scope) self.db.profile.moduleScope=scope end
function Automaton:IsModuleActive(name) return not self.db.char.disabledModules[name] end
function Automaton:IsModuleHidden(name) return self.db.char.hiddenModules[name] end
function Automaton:ToggleModuleActive(name,value) self.db.char.disabledModules[name]=not value or nil end
values={Tooltip='original tooltip',QuestAutomation='original quest'}
setLog={}
for _,name in ipairs({'Tooltip','QuestAutomation'}) do
 local key=name
 Automaton.modules[name]={name=name,modulename=name,moduledesc=name..' description',_options={
  enabled={type='toggle',order=1,name='Enabled '..key,get=function()return Automaton:IsModuleActive(key)end,set=function(value)Automaton:ToggleModuleActive(key,value)end},
  text={type='text',order=2,name='Text '..key,get=function()return values[key]end,set=function(value)values[key]=value;table.insert(setLog,key..':'..value)end}
 }}
end
function Automaton:ToggleMainWindow() self.legacyOpened=true end
rules={ignore={},custom={}}
pfUI.autovendor={ready=true}
function pfUI.autovendor:GetRules() return rules end
function pfUI.autovendor:SetRule(kind,id,name) rules[kind][tostring(id)]=name;return true end
AutomatonPfUIBridge={}
function AutomatonPfUIBridge:Acquire(host) self.host=host;self.active=true;return true end
function AutomatonPfUIBridge:Release() self.host=nil;self.active=nil end
function current(page)
 local p=pfUI.automation.pages[page]
 assert(p,'page not constructed');parent=p;return p
end
function tick() pfUI.automation.Tick() end
function rowName(name)
 for _,row in ipairs(parent.automationOptionsState.visible) do
  if row.option.name==name then return row end
 end
 error('missing visible control '..name)
end
function pick(name,pattern)
 local row=rowName(name);row.input:UpdateMenu()
 for _,entry in ipairs(row.input.menu) do
  if string.find(entry.text,pattern,1,true) then entry.func();tick();return end
 end
 error('missing dropdown label '..pattern)
end
''')
lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation_options.lua').read_text(encoding='utf-8-sig'))
lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation.lua').read_text(encoding='utf-8-sig'))
lua.execute(r'''
local h=pfUI.automation
h:Sync();h:OpenVendor();current(h.merchant)
-- Typing the ID and immediately clicking the action must commit once first.
rowName('物品 ID').input:SetText('123')
click(rowName('加入保留名单'));tick()
assert(rules.ignore['123']=='Item 123')
click(rowName('加入售卖名单'));tick();assert(rules.custom['123'])
local remove
for _,row in ipairs(parent.automationOptionsState.visible) do
 if row.option.buttonText=='移除' and string.find(row.option.name,'123',1,true) then remove=row;break end
end
assert(remove);click(remove);tick();assert(not rules.ignore['123'] and rules.custom['123'])
-- Dropdown reuse and deferred rebuild must not submit old values to new modules.
h:Open();current(h.all);pick('选择功能','Tooltip')
rowName('Text Tooltip').input:SetText('edited tooltip')
pick('选择功能','QuestAutomation')
assert(values.Tooltip=='edited tooltip' and values.QuestAutomation=='original quest')
assert(#setLog==1 and setLog[1]=='Tooltip:edited tooltip')
local editrow=rowName('Text QuestAutomation')
fire(editrow.input,'OnEditFocusLost');tick()
assert(#setLog==1,'focus loss wrote a rebound row to the wrong module')
rowName('搜索功能').input:SetText('Tooltip');fire(rowName('搜索功能').input,'OnEnterPressed');tick()
assert(C.automation.selected=='Tooltip')
rowName('搜索功能').input:SetText('nothing-matches');fire(rowName('搜索功能').input,'OnEnterPressed');tick()
assert(not pcall(rowName,'Text Tooltip'))
rowName('搜索功能').input:SetText('');fire(rowName('搜索功能').input,'OnEnterPressed');tick()
-- Warm all pages and both option layouts before measuring repeated reuse.
h:OpenPage(h.general);h:Open();h:OpenVendor();current(h.merchant)
local before=created
for i=1,40 do h:Open();h:OpenPage(h.general);h:OpenVendor() end
assert(created==before,'native page switches leaked new controls')
assert(pfUI.gui:GetWidth()==720 and pfUI.gui:GetHeight()==480)
assert(next(nativeSearchDB)==nil,'dynamic row references leaked into global search')
-- Native dropdowns are parented to the GUI, so switching pages must close them.
h:Open();current(h.all);pick('选择功能','Tooltip')
local menu=rowName('选择功能').input.menuframe
menu:Show();assert(menu:IsShown())
rowName('Text Tooltip').input:SetText('saved on page leave')
h:OpenVendor();current(h.merchant)
assert(not menu:IsShown(),'automation dropdown covered another settings page')
assert(values.Tooltip=='saved on page leave','page leave discarded pending edit')
h:Open();current(h.all);menu=rowName('选择功能').input.menuframe;menu:Show()
pfUI.gui:Hide();assert(not menu:IsShown(),'closing native GUI left detached dropdown visible')
h:OpenVendor();current(h.merchant)
-- Large rule lists must expand content, then shrink without stale entries.
for i=1,80 do rules.ignore[tostring(i)]='Listed item '..i end
h:RefreshPage(h.merchant);current(h.merchant)
assert(parent:GetHeight()>1000)
local longHeight=parent:GetHeight()
assert(not parent.anchors.all and #parent.anchors==2,'content remains fixed to viewport height')
assert(parent.parent:GetVerticalScrollRange()>0,'long content cannot scroll')
parent.parent:SetVerticalScroll(parent.parent:GetVerticalScrollRange())
for key in pairs(rules.ignore) do rules.ignore[key]=nil end
h:RefreshPage(h.merchant)
assert(parent:GetHeight()<longHeight)
assert(parent.parent:GetVerticalScroll()<=parent.parent:GetVerticalScrollRange(),'stale scroll offset on short list')
''')
lua.execute(r'''
local h=pfUI.automation
local original=h.GeneralOptions
-- The actual client lacks this method; all three pages must still render.
assert(rowName('物品 ID').input.GetStringHeight==nil)
for _,page in ipairs({h.general,h.all,h.merchant}) do
 h:OpenPage(page);current(page)
 assert(not h.rendering and not h.lastRenderError)
 assert(#parent.automationOptionsState.visible>0)
end
h.GeneralOptions=function(self)
 local options=original(self)
 options.failed={type='text',name='Broken getter',order=99,get=function()error('injected getter failure')end}
 return options
end
h:OpenPage(h.general);current(h.general)
assert(h.lastRenderError and not h.rendering)
assert(not parent.automationOptionsState.building)
h:OpenVendor();current(h.merchant)
assert(not h.lastRenderError and #parent.automationOptionsState.visible>0)
h.GeneralOptions=original
h:OpenPage(h.general);current(h.general)
assert(not h.lastRenderError and #parent.automationOptionsState.visible>0)
-- CreateConfig failure must also restore the temporary global this and marker.
local create=pfUI.gui.CreateConfig
h.GeneralOptions=function(self)
 local options=original(self)
 options.failed={type='color',name='New color',get=function()return 1,1,1,1 end}
 return options
end
pfUI.gui.CreateConfig=function(...)error('injected constructor failure')end
local sentinel={};this=sentinel
h:RefreshPage(h.general)
assert(this==sentinel and not parent.automationDynamic)
assert(h.lastRenderError and not h.rendering and not parent.automationOptionsState.building)
pfUI.gui.CreateConfig=create;h.GeneralOptions=original
h:RefreshPage(h.general)
assert(not h.lastRenderError and #parent.automationOptionsState.visible>0)
''')
lua.execute(r'''
local h=pfUI.automation
local group=pfUI.gui.frames[h.title]
local expected={'管理','全部功能','任务与升级','战斗与移动','物品与交易','界面与提示','组队与社交','其他便利功能','商人服务'}
assert(#h.pageOrder==#expected)
for i,title in ipairs(expected) do assert(h.pageOrder[i]==title and group[title]) end
assert(not group['功能设置'],'old category dropdown page remains')
local cases={
 {'任务与升级','QuestAutomation'},{'战斗与移动','RandomMount'},
 {'物品与交易','AutoNeed'},{'界面与提示','Tooltip'},
 {'组队与社交','AutoShout'},{'其他便利功能','ClearCache'},
}
for _,item in ipairs(cases) do
 local name=item[2]
 if not Automaton.modules[name] then
  Automaton.modules[name]={name=name,modulename=name,_options={info={type='description',name='Info '..name}}}
 end
end
for _,item in ipairs(cases) do
 -- Actual submenu click path, not just directly asking the host to render.
 group[item[1]]:Click();current(item[1])
 assert(not h.lastRenderError)
 assert(not pcall(rowName,'功能分类'))
 local menu=rowName('选择功能').input.menu
 assert(#menu==1 and string.find(menu[1].text,item[2],1,true))
end
-- Filters and module selection belong to their category, not a global dropdown.
group['界面与提示']:Click();current('界面与提示')
rowName('搜索功能').input:SetText('no-result');fire(rowName('搜索功能').input,'OnEnterPressed');tick()
assert(not pcall(rowName,'选择功能'))
group['任务与升级']:Click();current('任务与升级')
assert(rowName('搜索功能').input:GetText()=='')
assert(rowName('Text QuestAutomation'))
rowName('Text QuestAutomation').input:SetText('saved while changing category')
group['战斗与移动']:Click();current('战斗与移动')
assert(values.QuestAutomation=='saved while changing category')
group['界面与提示']:Click();current('界面与提示')
assert(rowName('搜索功能').input:GetText()=='no-result')
h:SelectModule('Tooltip');current('界面与提示')
assert(group['界面与提示'].area:IsShown() and rowName('搜索功能').input:GetText()=='')
assert(rowName('Text Tooltip'))
-- Warm all nine views, then ensure ordinary navigation never rebuilds controls.
for _,title in ipairs(expected) do group[title]:Click() end
local before=created
for i=1,10 do for _,title in ipairs(expected) do group[title]:Click() end end
assert(created==before,'category navigation leaked controls')
assert(not h.lastRenderError)
''')
print('pfUI automation pages: actual host/renderer/CreateConfig integration passed')
