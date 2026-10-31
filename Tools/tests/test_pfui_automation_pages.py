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
-- A shared details pane must commit the old module before rebinding its rows.
h:SelectModule('Tooltip');current(h.detail)
assert(rowName('Text Tooltip') and not pcall(rowName,'Text QuestAutomation'))
rowName('Text Tooltip').input:SetText('edited tooltip')
h:SelectModule('QuestAutomation');current(h.detail)
assert(values.Tooltip=='edited tooltip' and values.QuestAutomation=='original quest')
assert(#setLog==1 and setLog[1]=='Tooltip:edited tooltip')
fire(rowName('Text QuestAutomation').input,'OnEditFocusLost');tick()
assert(#setLog==1,'focus loss wrote a rebound row to the wrong module')
-- Warm both module shapes and all three native areas, then ensure reuse.
h:OpenPage(h.general);h:SelectModule('Tooltip');h:SelectModule('QuestAutomation');h:OpenVendor();current(h.merchant)
local before=created
for i=1,40 do h:SelectModule('Tooltip');h:SelectModule('QuestAutomation');h:OpenPage(h.general);h:OpenVendor() end
assert(created==before,'shared module/page switches leaked new controls')
assert(pfUI.gui:GetWidth()==720 and pfUI.gui:GetHeight()==480)
assert(next(nativeSearchDB)==nil,'dynamic row references leaked into global search')
-- Management dropdowns must close on module navigation and GUI close.
h:OpenPage(h.general);current(h.general)
local menu=rowName('显示范围').input.menuframe
menu:Show();assert(menu:IsShown())
h:SelectModule('Tooltip');current(h.detail);assert(not menu:IsShown())
rowName('Text Tooltip').input:SetText('saved on page leave')
h:OpenVendor();current(h.merchant)
assert(values.Tooltip=='saved on page leave','page leave discarded pending edit')
h:OpenPage(h.general);current(h.general);menu=rowName('显示范围').input.menuframe;menu:Show()
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
assert(#h.pageOrder==3 and group[h.general] and group[h.merchant] and group[h.detail])
assert(not group['全部功能'] and not group['任务与升级'],'category tabs remain')
local enabled=false
local otherValue='before'
local number=3
Automaton.modules.QuestItemBar={name='QuestItemBar',modulename='Shared label',_options={
 enabled={type='toggle',name='Quest bar enabled',order=1,get=function()return enabled end,set=function(v)enabled=v end},
 text={type='text',name='Quest bar text',order=2,get=function()return otherValue end,set=function(v)otherValue=v end},
 number={type='number',name='Quest bar number',order=3,get=function()return number end,set=function(v)number=v end},
}}
Automaton.modules.QuestAutomation.modulename='Shared label'
h:SelectModule('QuestItemBar');current(h.detail)
assert(rowName('Quest bar text') and not pcall(rowName,'Text QuestAutomation'))
assert(rowName('Quest bar text').option==Automaton.modules.QuestItemBar._options.text)
assert(not Automaton.modules.QuestItemBar._options.__pfui_description)
rowName('Quest bar text').input:SetText('bar saved')
rowName('Quest bar number').input:SetText('invalid')
assert(h:SelectModule('QuestAutomation')==false)
assert(h.selectedModule=='QuestItemBar' and h.activePage==h.detail)
assert(rowName('Quest bar number').input:GetText()=='invalid' and number==3)
assert(h:OpenVendor()==false and h.activePage==h.detail)
assert(h:SetModuleHidden('QuestItemBar',true)==false and not Automaton:IsModuleHidden('QuestItemBar'))
rowName('Quest bar number').input:SetText('4')
assert(h:SelectModule('QuestAutomation'));current(h.detail)
assert(otherValue=='bar saved' and number==4)
assert(h.selectedModule=='QuestAutomation' and rowName('Text QuestAutomation'))
rowName('Text QuestAutomation').input:SetText('hide saves draft')
assert(h:SetModuleHidden('QuestAutomation',true));tick();current(h.general)
assert(values.QuestAutomation=='hide saves draft' and h.activePage==h.general)
assert(Automaton:IsModuleActive('QuestAutomation'),'hide disabled a gameplay module')
local found=false
for _,entry in ipairs(h:NavigationEntries(false)) do assert(entry.name~='QuestAutomation') end
for _,entry in ipairs(h:NavigationEntries(true)) do if entry.name=='QuestAutomation' then found=true end end
assert(found)
-- Even hidden modules can be opened from management without unhiding them.
local opts=h:GeneralOptions();opts.nav_QuestAutomation.args.open.func();current(h.detail)
assert(rowName('Text QuestAutomation') and Automaton:IsModuleHidden('QuestAutomation'))
h:OpenPage(h.general);current(h.general)
opts=h:GeneralOptions();opts.nav_QuestAutomation.args.visible.set(true);tick()
assert(not Automaton:IsModuleHidden('QuestAutomation'))
rowName('查找模块').input:SetText('QuestItemBar');fire(rowName('查找模块').input,'OnEnterPressed');tick()
opts=h:GeneralOptions();assert(opts.nav_QuestItemBar and not opts.nav_QuestAutomation)
rowName('查找模块').input:SetText('');fire(rowName('查找模块').input,'OnEnterPressed');tick()
h:SelectModule('QuestItemBar');h:SelectModule('QuestAutomation');h:OpenPage(h.general)
local before=created
for i=1,30 do h:SelectModule('QuestItemBar');h:SelectModule('QuestAutomation');h:OpenPage(h.general) end
assert(created==before,'direct module navigation leaked controls')
assert(not h.lastRenderError)
''')
print('pfUI automation pages: actual shared details/management/merchant controls and navigation saves passed')
