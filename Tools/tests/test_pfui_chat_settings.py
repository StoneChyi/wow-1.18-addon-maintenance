"""Real chat/link/error module options in native pfUI pages; offline UI only."""
from pathlib import Path
import re
import unittest
from test_pfui_automation_host import ROOT, runtime

SOURCES = {
    'ItemLinkEnUS': 'Modules/S_ItemLinktoenUS.lua',
    'pfQuestSendLink': 'Modules/pfQuestSendLink.lua',
    'ErrClear': 'Modules/ErrClear.lua',
    'CleanChat': 'Plubics/CleanChat/CleanChat.lua',
}
SETUP = r'''
function GetLocale()return 'zhCN'end
function UnitName()return 'TestPlayer'end
StaticPopupDialogs={};YES='Yes';NO='No'
function AceLibrary()
 return {new=function()return setmetatable({RegisterTranslations=function()end},{__index=function(_,key)return key end})end}
end
saved={ItemLinkEnUS={profile={personal='item'}},pfQuestSendLink={profile={personal='quest'}},
 ErrClear={char={customErrors={'old%d+','['}}},
 CleanChat={profile={THighlightText={'keyword'},TFilterKeyworld={'filter'},lootCelebrationItems={'personal loot'},ShowChatTime=true,CopyChatTime=false}}}
function Automaton:NewModule(name)
 local m=setmetatable({name=name},{__index=self.modulePrototype});self.modules[name]=m;return m
end
function Automaton:AcquireDBNamespace(name)return saved[name]end
function Automaton:RegisterDefaults(name,scope,values)
 saved[name][scope]=saved[name][scope]or{}
 for k,v in pairs(values)do if saved[name][scope][k]==nil then saved[name][scope][k]=v end end
end
function Automaton:SetDisabledAsDefault(module,name)self.db.char.disabledModules[name]=true end
local toggle=Automaton.ToggleModuleActive
function Automaton:ToggleModuleActive(module,state)
 local name=type(module)=='table' and module.name or module
 if not saved[name]then return toggle(self,module,state)end
 if state==nil then state=not self:IsModuleActive(name)end
 if self:GetModuleScope()=='account'then self:GetRawDisabledTable(true)[name]=not state or nil
 else self.db.char.disabledModules[name]=not state or nil end
 return state
end
C.global.errors_hide='0';C.global.errors_limit='1'
C.chat={global={repeatfilter='1',repeatfilterinterval='23',repeatfilterexclude='世界，Trade'},text={time='0'}}
function findPage(name,hidden)
 for _,entry in ipairs(pfUI.automation:NavigationEntries(hidden))do if entry.name==name then return entry end end
end
'''


def host_runtime():
    lua=runtime(True)
    lua.execute(SETUP)
    core=(ROOT/'Interface/AddOns/Automatonex/Core.lua').read_text(encoding='utf-8-sig')
    register=re.search(r'function Automaton.modulePrototype:RegisterOptions\(options\).*?\nend',core,re.S).group(0)
    lua.execute('local L=setmetatable({}, {__index=function(_,key)return key end})\n'+register)
    for name,relative in SOURCES.items():
        lua.execute((ROOT/'Interface/AddOns/Automatonex'/relative).read_text(encoding='utf-8-sig'))
        module=lua.globals().Automaton.modules[name]
        module.OnInitialize(module)
    lua.execute('h=pfUI.automation;h:Sync()')
    return lua


class ChatSettings(unittest.TestCase):
    def test_composed_links_and_separate_chat_error_keep_original_option_objects(self):
        host_runtime().execute(r'''
assert(findPage('ItemLinkEnUS').label=='英文链接' and not findPage('pfQuestSendLink',true))
local links=h:ModuleOptions('pfQuestSendLink')
for _,id in ipairs({'ItemLinkEnUS','pfQuestSendLink'})do
 for key,opt in pairs(Automaton.modules[id]._options)do assert(links[id].args[key]==opt)end
end
for _,id in ipairs({'CleanChat','ErrClear'})do
 assert(findPage(id));local options=h:ModuleOptions(id)
 for key,opt in pairs(Automaton.modules[id]._options)do assert(options.module.args[key]==opt)end
end
local dynamic={type='description',name='dynamic'};Automaton.modules.pfQuestSendLink._options.dynamic=dynamic
assert(h:ModuleOptions('ItemLinkEnUS').pfQuestSendLink.args.dynamic==dynamic)
''')

    def test_native_controls_share_existing_config_and_preserve_legacy_lists(self):
        host_runtime().execute(r'''
local before=saved.CleanChat.profile;local errors=saved.ErrClear.char.customErrors
local options=h:ModuleOptions('CleanChat').module.args
assert(options.__pfui_repeat.get() and options.__pfui_interval.get()==23 and not options.__pfui_time.get())
options.__pfui_repeat.set(false);options.__pfui_interval.set(31);options.__pfui_exclude.set('世界,Trade');options.__pfui_time.set(true)
assert(C.chat.global.repeatfilter=='0' and C.chat.global.repeatfilterinterval=='31' and C.chat.global.repeatfilterexclude=='世界,Trade' and C.chat.text.time=='1')
assert(before==saved.CleanChat.profile and before.ShowChatTime and not before.CopyChatTime)
assert(before.THighlightText[1]=='keyword' and before.TFilterKeyworld[1]=='filter' and before.lootCelebrationItems[1]=='personal loot')
C.chat.global.repeatfilter='1';C.chat.global.repeatfilterinterval='9';C.chat.text.time='0'
assert(options.__pfui_repeat.get() and options.__pfui_interval.get()==9 and not options.__pfui_time.get())
local err=h:ModuleOptions('ErrClear').module.args;pfUI.gui.settingChanged=nil
err.__pfui_hide.set(true);assert(C.global.errors_hide=='1' and pfUI.gui.settingChanged)
pfUI.gui.settingChanged=nil;err.__pfui_line.set(false);assert(C.global.errors_limit=='0' and pfUI.gui.settingChanged)
assert(saved.ErrClear.char.customErrors==errors and errors[1]=='old%d+' and errors[2]=='[')
assert(Automaton.db.char.disabledModules.ErrClear and Automaton.db.char.disabledModules.CleanChat)
''')

    def test_scope_and_host_reload_keep_independent_module_switches(self):
        host_runtime().execute(r'''
local links=h:ModuleOptions('ItemLinkEnUS');links.ItemLinkEnUS.args.enabled.set(true)
assert(links.ItemLinkEnUS.args.enabled.get() and not links.pfQuestSendLink.args.enabled.get())
Automaton:ApplyModuleScope('account');links.pfQuestSendLink.args.enabled.set(true);links.ItemLinkEnUS.args.enabled.set(false)
assert(Automaton.rawDisabled.ItemLinkEnUS and not Automaton.rawDisabled.pfQuestSendLink)
Automaton:ApplyModuleScope('char');assert(Automaton.db.char.disabledModules.ItemLinkEnUS and not Automaton.db.char.disabledModules.pfQuestSendLink)
assert(loadstring(hostSource))();h=pfUI.automation;local reloaded=h:ModuleOptions('pfQuestSendLink')
assert(not reloaded.ItemLinkEnUS.args.enabled.get() and reloaded.pfQuestSendLink.args.enabled.get())
assert(saved.ItemLinkEnUS.profile.personal=='item' and saved.pfQuestSendLink.profile.personal=='quest')
assert(saved.CleanChat.profile.THighlightText[1]=='keyword' and saved.ErrClear.char.customErrors[2]=='[')
''')

    def test_alias_hidden_order_and_missing_members_preserve_ids(self):
        host_runtime().execute(r'''
C.automation.navSort='custom';C.automation.navOrder={'pfQuestSendLink','CleanChat','ItemLinkEnUS','ErrClear','unavailable'}
assert(h:NavigationPosition('pfQuestSendLink')==1)
h:MoveModule('pfQuestSendLink',3);assert(h:NavigationPosition('ItemLinkEnUS')==3)
local ids={};for _,id in ipairs(C.automation.navOrder)do ids[id]=true end;assert(ids.pfQuestSendLink and ids.unavailable)
Automaton.db.char.hiddenModules.pfQuestSendLink=true;assert(findPage('ItemLinkEnUS'))
h:SetPageHidden('ItemLinkEnUS',true);assert(not findPage('ItemLinkEnUS') and findPage('ItemLinkEnUS',true))
assert(Automaton.db.char.hiddenModules.pfQuestSendLink and not Automaton.db.char.hiddenModules.ItemLinkEnUS)
h:SetPageHidden('ItemLinkEnUS',false);assert(h:SelectModule('pfQuestSendLink') and h.selectedModule=='ItemLinkEnUS')
Automaton.modules.ItemLinkEnUS=nil;assert(h:ModuleOptions('pfQuestSendLink').pfQuestSendLink)
Automaton.modules.pfQuestSendLink=nil;assert(not findPage('ItemLinkEnUS',true) and findPage('CleanChat') and findPage('ErrClear'))
C.automation.enabled='0';assert(h:ModuleOptions('CleanChat').disabled)
''')

    def test_actual_renderer_covers_cleanchat_options_and_saves_shared_controls(self):
        from test_pfui_automation_catalog import runtime as render_runtime, initialize_module
        lua=render_runtime()
        for name,relative in SOURCES.items():
            lua.execute((ROOT/'Interface/AddOns/Automatonex'/relative).read_text(encoding='utf-8-sig'))
            initialize_module(lua,name,lua.globals().Automaton.modules[name])
        lua.execute(r'''
local methods=getmetatable(parent).__index
function methods:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
Automaton.db={char={hiddenModules={}},profile={moduleScope='char'}}
function Automaton:IsModuleHidden(name)return self.db.char.hiddenModules[name]end
function Automaton:GetModuleScope()return self.db.profile.moduleScope end
C.global={errors_hide='0',errors_limit='1'};C.chat={global={repeatfilter='0',repeatfilterinterval='20',repeatfilterexclude=''},text={time='0'}};C.automation={enabled='1'}
''')
        lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation.lua').read_text(encoding='utf-8-sig'))
        lua.execute(r'''
local h,R=pfUI.automation,pfUI.automationOptions
local originals,seen={},{}
local function collect(options)
 for _,opt in pairs(options)do if type(opt)=='table'then originals[opt]=true;if opt.args then collect(opt.args)end end end
end
for _,id in ipairs({'CleanChat','ErrClear','ItemLinkEnUS','pfQuestSendLink'})do collect(Automaton.modules[id]._options)end
for _,page in ipairs({'CleanChat','ErrClear','ItemLinkEnUS'})do
 local options=h:ModuleOptions(page);assert(R:Render(parent,{_options=options}),tostring(R.lastError).." page="..page)
 local rendered={}
 for _,row in ipairs(rows())do
  local opt=row.option;rendered[opt]=row
  if originals[opt]then
   seen[opt]=true
   if opt.get then
    local value=opt.passValue~=nil and opt.get(opt.passValue) or opt.get()
    if row.widget=='checkbox'then assert((not not row.input:GetChecked())==(not not value),'checkbox readback')
    elseif row.widget=='text'then assert(row.input:GetText()==tostring(value or ''),'text readback')
    elseif row.widget=='dropdown'then
     local label=tostring(value or '')
     for key,text in pairs(opt.validate)do if (type(key)=='number' and text or key)==value then label=tostring(text)end end
     assert(row.input.text:GetText()==label,'dropdown readback')
    elseif row.widget=='color'then
     local r,g,b,a=opt.get();local actual=row.color.prev.texture
     assert(actual[1]==r and actual[2]==g and actual[3]==b and actual[4]==(a or 1),'color readback')
    else error('unverified getter '..tostring(opt.name))end
   end
  end
 end
 if page=='CleanChat'then
  local args=options.module.args
  for _,key in ipairs({'__pfui_repeat','__pfui_time'})do
   local row=assert(rendered[args[key]]);assert(row.widget=='checkbox');row.input:SetChecked(1);click(row)
  end
  edit(assert(rendered[args.__pfui_interval]),'44');edit(assert(rendered[args.__pfui_exclude]),'世界，Trade')
  assert(C.chat.global.repeatfilter=='1' and C.chat.text.time=='1' and C.chat.global.repeatfilterinterval=='44' and C.chat.global.repeatfilterexclude=='世界，Trade')
 elseif page=='ErrClear'then
  local args=options.module.args
  for _,key in ipairs({'__pfui_hide','__pfui_line'})do
   local row=assert(rendered[args[key]]);row.input:SetChecked(1);click(row)
  end
  assert(C.global.errors_hide=='1' and C.global.errors_limit=='1' and pfUI.gui.settingChanged)
 else
  for _,id in ipairs({'ItemLinkEnUS','pfQuestSendLink'})do
   local opt=Automaton.modules[id]._options.enabled;local row=assert(rendered[opt]);local old=opt.get();row.input:SetChecked(not old and 1 or nil);click(row);assert(opt.get()==not old)
  end
 end
end
for opt in pairs(originals)do assert(seen[opt],'missing original option '..tostring(opt.name))end
local warm=created
for _,page in ipairs({'CleanChat','ErrClear','ItemLinkEnUS','CleanChat'})do assert(R:Render(parent,{_options=h:ModuleOptions(page)}))end
assert(created==warm,'chat page redraw leaked controls')
''')


if __name__=='__main__':
    unittest.main(verbosity=2)
