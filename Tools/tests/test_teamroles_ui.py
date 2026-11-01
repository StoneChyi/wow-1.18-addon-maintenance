"""pfUI shared-role window with the strict WoW 1.12 font contract.

Runs actual module code. No rendering, server transport or live-game claims.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

SOURCE = (ROOT / 'Interface/AddOns/pfUI/modules/teamroles.lua').read_text(encoding='utf-8')


def world(failed_fonts=False, service=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    install = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
    lua.execute((ROOT / 'Tools/tests/puredispel_wow112_mock.lua').read_text(encoding='utf-8'), install)
    lua.execute('''
SetPfUI();CreateBackdrop=pfUI.api.CreateBackdrop
guiEntries={};configEntries={};operations={};owners={};listeners={};roster={};acquired=0;released=0
function pfUI:RegisterModule(name,version,fn) assert(name=='teamroles' and version=='vanilla');fn() end
function pfUI:ShowGUI() end
pfUI.gui={CreateGUIEntry=function(title,sub,fn)
 assert(title=='团队职责' and sub==nil);table.insert(guiEntries,fn)
end,CreateConfig=function(...) table.insert(configEntries,arg) end}
local S={}
SC_TeamRolesService=S
function S:Acquire(owner) acquired=acquired+1;owners[owner]=true end
function S:Release(owner) released=released+1;owners[owner]=nil end
function S:Subscribe(owner,fn) listeners[owner]=fn end
function S:Unsubscribe(owner) listeners[owner]=nil end
function S:GetRoster() return roster end
function S:GetInfo(value)
 for _,rec in ipairs(roster) do if rec.unit==value or rec.name==value then return rec end end
end
function NotifyRoles() for _,fn in pairs(listeners) do fn() end end
function S:Refresh(unit) table.insert(operations,{'refresh',unit});return true end
function S:SetOverride(unit,role,style)
 table.insert(operations,{'override',unit,role,style})
 local rec=self:GetInfo(unit)
 if rec then rec.role=role;rec.style=style;rec.source=role and 'manual' or 'talent';NotifyRoles() end
 return true
end
function S:SetTankOrder(unit,order)
 table.insert(operations,{'order',unit,order});self:GetInfo(unit).order=order;NotifyRoles();return true
end
function Populate(n)
 roster={}
 for i=1,n do
  local unit='raid'..i;AddUnit(unit,'Member'..i)
  table.insert(roster,{unit=unit,name=units[unit].name,key=units[unit].guid,class='WARRIOR',
   role='DAMAGER',style='MELEE',confidence='high',source='talent',queryState='complete',
   tabs={{points=0},{points=31},{points=20}}})
 end
end
''')
    if failed_fonts:
        lua.execute("methods.SetFont=function() return nil end")
    if not service:
        lua.execute('SC_TeamRolesService=nil')
    lua.execute(SOURCE)
    return lua


class TeamRoleUITests(unittest.TestCase):
    def test_module_registration_is_lazy_and_has_no_sampling_driver(self):
        lua = world()
        lua.execute('''
assert(not pfUI.teamroles.frame and acquired==0 and table.getn(guiEntries)==1)
for _,o in ipairs(objects) do assert(not o.scripts.OnUpdate) end
pfUI.teamroles:RegisterGUI();assert(table.getn(guiEntries)==1)
guiEntries[1]();assert(table.getn(configEntries)==2 and configEntries[2][5]=='button')
''')
        lua.execute(SOURCE)
        lua.execute('assert(table.getn(guiEntries)==1 and not pfUI.teamroles.frame)')

    def test_missing_font_paths_keep_real_template_font_on_every_text(self):
        world(failed_fonts=True).execute('''
Populate(5);pfUI:OpenTeamRoles()
for _,o in ipairs(objects) do if o.kind=='FontString' then assert(o.font) end end
pfUI.teamroles.frame:Hide();pfUI:OpenTeamRoles()
for _,o in ipairs(objects) do if o.kind=='FontString' then o:SetText('checked') end end
''')

    def test_window_reuses_twelve_rows_and_scrolls_all_forty_members(self):
        world().execute('''
Populate(40);pfUI:OpenTeamRoles()
local H=pfUI.teamroles;assert(table.getn(H.rows)==12)
local count=table.getn(objects)
for i=1,50 do invoke(H.rows[1],'OnMouseWheel',-1) end
assert(H.offset==28 and H.rows[12].record.name=='Member40')
for i=1,10 do H:Refresh();H.frame:Hide();pfUI.api.OpenTeamRoles() end
assert(table.getn(objects)==count and table.getn(UISpecialFrames)==1)
invoke(H.frame,'OnMouseWheel',1);assert(H.offset==27)
''')

    def test_close_only_releases_the_window_owner_and_escape_is_registered(self):
        world().execute('''
Populate(2);owners.QuickHeal=true;pfUI:OpenTeamRoles()
assert(owners['pfUI.teamroles'] and acquired==1 and released==0)
local f=pfUI.teamroles.frame;invoke(f.close,'OnClick','LeftButton')
assert(not f:IsShown() and owners.QuickHeal and not owners['pfUI.teamroles'])
assert(listeners['pfUI.teamroles']==nil and released==1)
assert(UISpecialFrames[1]=='pfTeamRoles')
''')

    def test_unknown_members_sort_first_without_modifying_the_shared_roster(self):
        world().execute('''
Populate(20);roster[20].role=nil;roster[20].confidence='unknown'
pfUI:OpenTeamRoles();local H=pfUI.teamroles
assert(H.rows[1].record.name=='Member20' and H.rows[1].role.text=='待确认')
assert(roster[1].name=='Member1' and roster[20].name=='Member20' and roster[1].order==nil)
invoke(H.frame.unknown,'OnClick');assert(H.rows[1].record.name=='Member1')
''')

    def test_all_corrections_write_only_the_shared_selected_member(self):
        world().execute('''
Populate(3);pfUI:OpenTeamRoles('Member2');local H=pfUI.teamroles
invoke(H.actions.melee,'OnClick');assert(operations[1][1]=='override' and operations[1][2]=='raid2')
assert(operations[1][3]=='DAMAGER' and operations[1][4]=='MELEE')
invoke(H.actions.ranged,'OnClick');assert(operations[2][4]=='RANGED')
invoke(H.actions.HEALER,'OnClick');assert(operations[3][3]=='HEALER')
invoke(H.actions.TANK,'OnClick');assert(operations[4][3]=='TANK')
invoke(H.actions.main,'OnClick');assert(operations[5][3]=='TANK' and operations[6][1]=='order' and operations[6][3]==1)
invoke(H.actions.order,'OnClick');assert(operations[7][1]=='order' and operations[7][3]==nil)
invoke(H.actions.auto,'OnClick');assert(operations[8][3]==nil)
invoke(H.frame.refreshSelected,'OnClick');assert(operations[9][1]=='refresh' and operations[9][2]=='raid2')
invoke(H.frame.refresh,'OnClick');assert(operations[10][1]=='refresh' and operations[10][2]==nil)
assert(roster[1].source=='talent' and roster[3].source=='talent')
''')

    def test_member_replacement_between_press_release_and_action_cannot_modify_other_player(self):
        world().execute('''
Populate(14);pfUI:OpenTeamRoles();local H=pfUI.teamroles
invoke(H.rows[1],'OnMouseDown','LeftButton')
H.offset=1;H:Refresh();invoke(H.rows[1],'OnClick','LeftButton')
assert(not H.selected)
pfUI:OpenTeamRoles('Member2');assert(H.selected.name=='Member2')
units.raid2.name='Replacement';invoke(H.actions.TANK,'OnClick')
assert(table.getn(operations)==0 and not H.selected)
''')

    def test_pfui_background_border_alpha_are_independent_of_text(self):
        world().execute('''
Populate(2);pfUI:OpenTeamRoles();local H=pfUI.teamroles
H.frame:Hide()
pfUI_config.appearance.border.background='0,0,0,0'
pfUI_config.appearance.border.color='0.2,0.2,0.2,0'
pfUI:OpenTeamRoles()
for _,o in ipairs(H.styled) do assert(o.bgColor[4]==0 and o.borderColor[4]==0 and o.alpha==1) end
for _,font in ipairs(H.fonts) do assert(font[1].alpha==1) end
''')

    def test_missing_service_can_open_close_and_reports_unavailable(self):
        world(service=False).execute('''
SlashCmdList.PFUITEAMROLES();local f=pfUI.teamroles.frame
assert(f:IsShown() and f.status.text=='共享职责服务尚未就绪')
invoke(f.refresh,'OnClick');assert(string.find(f.feedback.text,'尚未就绪',1,true))
f:Hide()
''')

    def test_new_member_notifications_update_only_while_window_is_visible(self):
        world().execute('''
Populate(2);pfUI:OpenTeamRoles();local H=pfUI.teamroles
assert(H.rows[2].record.name=='Member2')
Populate(1);NotifyRoles();assert(not H.rows[2]:IsShown())
H.frame:Hide();local writes=calls.text or 0;Populate(3);NotifyRoles();assert((calls.text or 0)==writes)
''')

    def test_actual_shared_service_corrections_and_owner_lifecycle(self):
        lua = world()
        for name in ('SC_TeamRoleData.lua', 'SC_TeamRoles.lua', 'SC_TeamRoleService.lua'):
            lua.execute((ROOT / 'Interface/AddOns/!Libs' / name).read_text(encoding='utf-8-sig'))
        lua.execute('''
Populate(3);raidCount=3
local S=SC_TeamRolesService;S:Acquire('QuickHeal')
pfUI:OpenTeamRoles('Member2');local H=pfUI.teamroles
assert(H.selected and H.selected.name=='Member2')
invoke(H.actions.main,'OnClick')
assert(S:GetInfo('raid2').role=='TANK' and S:GetInfo('raid2').order==1)
assert(SC_TeamRoles:IsTank('raid2')==true)
invoke(H.actions.auto,'OnClick')
assert(S:GetInfo('raid2').overrideRole==nil and S:GetInfo('raid2').order==nil)
assert(SC_TeamRoles:IsTank('raid2')==nil)
invoke(H.actions.melee,'OnClick');assert(SC_TeamRoles:IsTank('raid2')==false)
invoke(H.actions.auto,'OnClick');assert(S:GetInfo('raid2').overrideRole==nil)
H.frame:Hide();assert(S:GetDiagnostics().consumers==1)
''')


if __name__ == '__main__':
    unittest.main(verbosity=2)
