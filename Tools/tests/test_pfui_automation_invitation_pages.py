"""Composed invitation pages preserve engine options, independent state and old IDs.
Offline host integration only; no game-client acceptance is claimed.
"""
from pathlib import Path
from test_pfui_automation_host import runtime

ROOT = Path(__file__).resolve().parents[2]
lua = runtime(True)
lua.execute(r'''
function addModule(id)
 local m={name=id,modulename=id,moduledesc='description '..id,db={profile={value=id}},_options={}}
 local nested={type='group',name='nested',args={value={type='text',name='value',
  get=function() return m.db.profile.value end,set=function(v) m.db.profile.value=v end}}}
 m._options={enabled={type='toggle',name='enabled',get=function() return Automaton:IsModuleActive(id) end,
  set=function(v) Automaton:ToggleModuleActive(id,v) end},nested=nested}
 Automaton.modules[id]=m
 return m
end
for _,id in ipairs({'Group','StrangerDecline','Invite','invall'}) do addModule(id) end
local h=pfUI.automation
local function find(name,hidden)
 for _,e in ipairs(h:NavigationEntries(hidden)) do if e.name==name then return e end end
end
assert(find('Group').label=='邀请处理' and find('Invite').label=='邀请玩家')
assert(not find('StrangerDecline',true) and not find('invall',true))
for _,page in ipairs({'Group','Invite'}) do
 local aliases=page=='Group' and {'Group','StrangerDecline'} or {'Invite','invall'}
 local options=h:ModuleOptions(aliases[2])
 for _,id in ipairs(aliases) do
  local m=Automaton.modules[id]
  assert(options[id].moduleName==id)
  for key,opt in pairs(m._options) do assert(options[id].args[key]==opt,'original option object changed') end
  options[id].args.nested.args.value.set('saved '..id)
  assert(m.db.profile.value=='saved '..id)
 end
 options[aliases[1]].args.enabled.set(false)
 assert(not Automaton:IsModuleActive(aliases[1]) and Automaton:IsModuleActive(aliases[2]))
 options[aliases[2]].args.__pfui_menu.set(false)
 assert(Automaton:IsModuleHidden(aliases[2]) and not Automaton:IsModuleHidden(aliases[1]))
 assert(find(page),'partially hidden members should retain page')
 h:SetPageHidden(page,true)
 assert(not find(page) and find(page,true))
 assert(Automaton:IsModuleHidden(aliases[2]) and not Automaton:IsModuleHidden(aliases[1]))
 assert(h:SelectModule(aliases[2]) and h.selectedModule==page and C.automation.selected==page)
 h:SetPageHidden(page,false)
 assert(find(page) and Automaton:IsModuleHidden(aliases[2]))
 local replacement={type='description',name='dynamic'}
 Automaton.modules[aliases[2]]._options.dynamic=replacement
 assert(h:ModuleOptions(page)[aliases[2]].args.dynamic==replacement)
end
-- Enabled ordering treats either member as active.
C.automation.navSort='enabled'
assert(find('Group').active and find('Invite').active)
Automaton:ToggleModuleActive('StrangerDecline',false)
assert(not find('Group').active)
-- Old alias order is honored until a deliberate page move; aliases remain saved.
C.automation.navSort='custom';C.automation.navOrder={'invall','Tooltip','StrangerDecline','Group','Invite','unavailable'}
assert(h:NavigationPosition('Invite')==1 and h:NavigationPosition('invall')==1)
h:MoveModule('invall',3)
assert(h:NavigationPosition('Invite')==3)
local kept={};for _,id in ipairs(C.automation.navOrder) do kept[id]=true end
assert(kept.invall and kept.StrangerDecline and kept.unavailable)
-- Per-page hidden false is a durable explicit override over both old hidden bits.
Automaton.db.char.hiddenModules.Group=true
Automaton.db.char.hiddenModules.StrangerDecline=true
assert(find('Group'))
C.automation.pageHidden.Group=nil
assert(not find('Group'))
h:SetPageHidden('Group',false)
local g=h:GeneralOptions().nav_Group.args
assert(g.visible.name=='在模块列表中显示' and g.visible.get())
g.visible.set(false);assert(not find('Group'))
assert(Automaton.db.char.hiddenModules.Group and Automaton.db.char.hiddenModules.StrangerDecline)
-- Aliases remain routable with only the second engine loaded.
Automaton.modules.Group=nil;Automaton.modules.Invite=nil
assert(find('Group',true) and find('Invite',true))
assert(h:SelectModule('Group') and h.selectedModule=='Group')
assert(h:SelectModule('invall') and h.selectedModule=='Invite')
assert(h:ModuleOptions('Group').StrangerDecline and not h:ModuleOptions('Group').Group)
C.automation.selected='StrangerDecline';h.selectedModule=nil;h:SetPageHidden('Group',false)
assert(h:Open() and h.selectedModule=='Group')
-- Recreate host with the same persisted settings; old member bits stay intact.
assert(loadstring(hostSource))()
h=pfUI.automation
assert(h:Config().pageHidden.Group==false and h:Config().navSort=='custom')
assert(h:ModuleOptions('Group').StrangerDecline.args.nested.args.value.get()=='saved StrangerDecline')
assert(Automaton.db.char.hiddenModules.Group and Automaton.db.char.hiddenModules.StrangerDecline)
''')
print('PASS: invitation page composition, option identity, independent state, alias routes and persistence')
