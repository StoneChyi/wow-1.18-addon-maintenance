"""Movement page composition, native rendering and existing configuration storage.

Real Stand/ShaguStance/RandomMount declarations and host are executed. As in
host/catalog suites, gameplay lifecycle and AceDB storage are explicit seams;
this is UI/config regression, not movement or game-client acceptance.
"""
from pathlib import Path
import re
import unittest
from test_pfui_automation_host import ROOT, runtime

MODULES = ('Stand', 'ShaguStance', 'RandomMount')
SETUP = r'''
SPELL_FAILED_ONLY_SHAPESHIFT='Requires %s'
MANA_COST='%d Mana'
function GetBuildInfo() return '1.18.1' end
function AceLibrary()
 return {new=function()return setmetatable({RegisterTranslations=function()end},{__index=function(_,key)return key end})end}
end
saved={Stand={profile={personal='stand'}},ShaguStance={profile={personal='stance'}},
 RandomMount={profile={},char={customMounts={'Personal mount'},excludedMounts={'Black mount'},lastMountName='Last mount'}}}
SlashCmdList={}
function Automaton:NewModule(name)
 local m=setmetatable({name=name},{__index=self.modulePrototype});self.modules[name]=m;return m
end
function Automaton:AcquireDBNamespace(name)return saved[name]end
function Automaton:RegisterDefaults(name,scope,values)
 saved[name][scope]=saved[name][scope] or {}
 for k,v in pairs(values)do if saved[name][scope][k]==nil then saved[name][scope][k]=v end end
end
function Automaton:SetDisabledAsDefault(module,name)self.db.char.disabledModules[name]=true end
-- Explicit storage model: lifecycle actions are covered by business suites.
local toggle=Automaton.ToggleModuleActive
function Automaton:ToggleModuleActive(module,state)
 local name=type(module)=='table' and module.name or module
 if name~='Stand' and name~='ShaguStance' and name~='RandomMount' then return toggle(self,module,state) end
 if state==nil then state=not self:IsModuleActive(name)end
 if self:GetModuleScope()=='account' then self:GetRawDisabledTable(true)[name]=not state or nil
 else self.db.char.disabledModules[name]=not state or nil end
 return state
end
C.global.autodismount='1'
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
    for name in MODULES:
        lua.execute((ROOT/f'Interface/AddOns/Automatonex/Modules/{name}.lua').read_text(encoding='utf-8-sig'))
        lua.globals().Automaton.modules[name].OnInitialize(lua.globals().Automaton.modules[name])
    lua.execute('h=pfUI.automation;h:Sync()')
    return lua


class MovementSettings(unittest.TestCase):
    def test_original_options_and_random_mount_page_stay_separate(self):
        host_runtime().execute(r'''
assert(findPage('Stand').label=='骑乘与姿态' and not findPage('ShaguStance',true))
assert(findPage('RandomMount') and h:ResolvePage('RandomMount')=='RandomMount')
local options=h:ModuleOptions('ShaguStance')
for _,id in ipairs({'Stand','ShaguStance'})do
 local m=Automaton.modules[id];assert(options[id].moduleName==id)
 for key,opt in pairs(m._options)do assert(options[id].args[key]==opt,'copied original option')end
end
assert(not options.RandomMount)
local random=h:ModuleOptions('RandomMount')
assert(random.module.moduleName=='RandomMount')
for key,opt in pairs(Automaton.modules.RandomMount._options)do assert(random.module.args[key]==opt)end
local dynamic={type='description',name='later option'}
Automaton.modules.ShaguStance._options.dynamic=dynamic
assert(h:ModuleOptions('Stand').ShaguStance.args.dynamic==dynamic)
assert(options.pfuiDismount.get());options.pfuiDismount.set(false)
assert(C.global.autodismount=='0' and Automaton.db.char.disabledModules.Stand and Automaton.db.char.disabledModules.ShaguStance)
C.global.autodismount='1';assert(options.pfuiDismount.get())
''')

    def test_independent_switches_scope_and_reload_storage(self):
        host_runtime().execute(r'''
local stand,stance,mount=saved.Stand,saved.ShaguStance,saved.RandomMount
local options=h:ModuleOptions('Stand')
options.Stand.args.enabled.set(true)
assert(options.Stand.args.enabled.get() and not options.ShaguStance.args.enabled.get())
options.pfuiDismount.set(false)
Automaton:ApplyModuleScope('account')
assert(Automaton:GetModuleScope()=='account' and not Automaton.rawDisabled.Stand and Automaton.rawDisabled.ShaguStance)
options.ShaguStance.args.enabled.set(true)
assert(options.ShaguStance.args.enabled.get() and not Automaton.rawDisabled.ShaguStance)
options.Stand.args.enabled.set(false)
assert(Automaton.rawDisabled.Stand and options.ShaguStance.args.enabled.get())
Automaton:ApplyModuleScope('char')
assert(Automaton.db.char.disabledModules.Stand and not Automaton.db.char.disabledModules.ShaguStance)
assert(loadstring(hostSource))();h=pfUI.automation
local reload=h:ModuleOptions('ShaguStance')
assert(not reload.Stand.args.enabled.get() and reload.ShaguStance.args.enabled.get())
assert(not reload.pfuiDismount.get())
assert(saved.Stand==stand and saved.ShaguStance==stance and saved.RandomMount==mount)
assert(stand.profile.personal=='stand' and stance.profile.personal=='stance')
assert(mount.char.customMounts[1]=='Personal mount' and mount.char.excludedMounts[1]=='Black mount' and mount.char.lastMountName=='Last mount')
''')

    def test_alias_hidden_and_custom_order_preserve_old_values(self):
        host_runtime().execute(r'''
local originalMount=Automaton.modules.RandomMount._options
C.automation.navSort='custom';C.automation.navOrder={'ShaguStance','RandomMount','Stand','unavailable'}
assert(h:NavigationPosition('Stand')==1 and h:NavigationPosition('ShaguStance')==1)
h:MoveModule('ShaguStance',3);assert(h:NavigationPosition('Stand')==3)
local ids={};for _,id in ipairs(C.automation.navOrder)do ids[id]=true end
assert(ids.ShaguStance and ids.RandomMount and ids.unavailable)
Automaton.db.char.hiddenModules.ShaguStance=true
assert(findPage('Stand'),'one visible member retains combined page')
h:SetPageHidden('Stand',true);assert(not findPage('Stand') and findPage('Stand',true))
assert(Automaton.db.char.hiddenModules.ShaguStance and not Automaton.db.char.hiddenModules.Stand)
h:SetPageHidden('Stand',false);assert(findPage('Stand') and Automaton.db.char.hiddenModules.ShaguStance)
assert(h:SelectModule('ShaguStance') and h.selectedModule=='Stand' and C.automation.selected=='Stand')
assert(h:SelectModule('RandomMount') and h.selectedModule=='RandomMount')
assert(Automaton.modules.RandomMount._options==originalMount)
local general=h:GeneralOptions().nav_Stand.args
assert(general.visible.name=='在模块列表中显示')
general.visible.set(false);assert(not findPage('Stand'))
assert(findPage('RandomMount'),'hiding movement page hid random mount')
''')

    def test_missing_module_and_native_component_fallback(self):
        host_runtime().execute(r'''
assert(h:ModuleOptions('Stand').nativeMissing)
pfUI.autoshift={};assert(not h:ModuleOptions('Stand').nativeMissing)
Automaton.modules.Stand=nil
assert(findPage('Stand',true) and h:SelectModule('ShaguStance'))
assert(h:ModuleOptions('Stand').ShaguStance and not h:ModuleOptions('Stand').Stand)
Automaton.modules.ShaguStance=nil
assert(not findPage('Stand',true) and findPage('RandomMount'))
C.automation.enabled='0';h:Sync()
assert(h:ModuleOptions('Stand').disabled)
Automaton:SelectModule('RandomMount');assert(Automaton.selectedModule=='RandomMount')
''')

    def test_native_renderer_displays_and_saves_actual_controls(self):
        from test_pfui_automation_catalog import runtime as render_runtime, initialize_module
        lua=render_runtime()
        for name in MODULES:
            lua.execute((ROOT/f'Interface/AddOns/Automatonex/Modules/{name}.lua').read_text(encoding='utf-8-sig'))
            initialize_module(lua,name,lua.globals().Automaton.modules[name])
        lua.execute(r'''
local methods=getmetatable(parent).__index
function methods:RegisterEvent(event)self.events=self.events or {};self.events[event]=true end
Automaton.db={char={hiddenModules={}},profile={moduleScope='char'}}
function Automaton:IsModuleHidden(name)return self.db.char.hiddenModules[name]end
function Automaton:GetModuleScope()return self.db.profile.moduleScope end
C.global={autodismount='0'};C.automation={enabled='1'}
''')
        lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation.lua').read_text(encoding='utf-8-sig'))
        lua.execute(r'''
local h,R=pfUI.automation,pfUI.automationOptions
local options=h:ModuleOptions('ShaguStance')
assert(R:Render(parent,{_options=options}))
local rendered={}
for _,row in ipairs(rows())do rendered[row.option]=row end
local native=assert(rendered[options.pfuiDismount]);assert(native.widget=='checkbox' and not native.input:GetChecked())
native.input:SetChecked(1);click(native);assert(C.global.autodismount=='1')
for _,id in ipairs({'Stand','ShaguStance'})do
 for key,opt in pairs(Automaton.modules[id]._options)do
  local row=assert(rendered[opt],'missing original movement option '..id..':'..key)
  if key=='enabled'then
   local previous=opt.get();row.input:SetChecked(not previous and 1 or nil);click(row)
   assert(opt.get()==not previous,'original enabled control did not save')
  end
 end
end
local warm=created
assert(R:Render(parent,{_options=h:ModuleOptions('Stand')}));assert(created==warm,'movement redraw leaked controls')
assert(h:ModuleOptions('RandomMount').module.moduleName=='RandomMount')
''')


if __name__=='__main__':
    unittest.main(verbosity=2)
