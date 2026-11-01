"""Offline role-service and legacy-consumer checks; not live-game acceptance."""
from pathlib import Path
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDONS = ROOT / 'Interface/AddOns'
BRIDGE = (ADDONS / '!Libs/SC_TeamRoles.lua').read_text(encoding='utf-8-sig')


def bridge_world():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute('''
units={player=true,raid1=true,raid2=true,raid3=true};messages={}
function UnitExists(unit) return units[unit] end
DEFAULT_CHAT_FRAME={AddMessage=function(self,text) table.insert(messages,text) end}
function CreateFrame() error('Role bridge must not allocate UI or timers') end
function SendAddonMessage() error('Role bridge must not send network traffic') end
''')
    lua.execute(BRIDGE)
    return lua


def notgrid_world():
    path = ROOT / 'Tools/tests/test_notgrid_incoming_heals.py'
    # Reuse the installed full-library/core harness without running its suite twice.
    setup = path.read_text(encoding='utf-8').split('\ngroups = 0\n')[0]
    namespace = {'__file__': str(path)}
    exec(compile(setup, str(path), 'exec'), namespace)
    lua = namespace['world'](namespace['LIBRARIES'][0])
    lua.execute(BRIDGE)
    return lua


class BridgeTests(unittest.TestCase):
    def test_absent_provider_has_three_state_semantics(self):
        bridge_world().execute('''
assert(not SC_TeamRoles:IsReady())
assert(SC_TeamRoles:GetRole('raid1')==nil)
assert(SC_TeamRoles:IsTank('raid1')==nil)
assert(SC_TeamRoles:GetTankOrder('raid1')==nil)
assert(table.getn(messages)==0)
''')

    def test_provider_version_and_failure_are_not_role_facts(self):
        bridge_world().execute('''
local A=SC_TeamRoles
for _,p in ipairs({{apiVersion=2,GetRole=function() return 'TANK' end},
 {apiVersion=1,GetRole=function() error('unavailable') end},
 {apiVersion=1,GetRole=function() return 'MAINTANK' end},
 {apiVersion=1,IsReady=function() return false end,GetRole=function() return 'TANK' end},
 {apiVersion=1,IsReady=function() return 0 end,GetRole=function() return 'TANK' end},
 {apiVersion=1,IsReady=function() return 'yes' end,GetRole=function() return 'TANK' end},
 {apiVersion=1,IsReady=function() error('offline') end,GetRole=function() return 'TANK' end}}) do
 SC_TeamRolesProvider=p;assert(A:GetRole('raid1')==nil and A:IsTank('raid1')==nil)
end
''')

    def test_confirmed_tank_healer_damage_and_unknown_are_distinct(self):
        bridge_world().execute('''
SC_TeamRolesProvider={apiVersion=1,GetRole=function(self,unit)
 if unit=='raid1' then return 'TANK',2,'server' end
 if unit=='raid2' then return 'HEALER',1,'server' end
 if unit=='raid3' then return 'DAMAGER',9,'server' end
end}
local A=SC_TeamRoles
assert(A:IsReady() and A:IsTank('raid1')==true)
assert(A:IsTank('raid2')==false and A:IsTank('raid3')==false)
assert(A:IsTank('player')==nil and A:IsTank('absent')==nil)
assert(A:GetTankOrder('raid1')==2 and A:GetTankOrder('raid2')==nil)
local role,order,source=A:GetRole('raid1');assert(role=='TANK' and order==2 and source=='server')
''')

    def test_invalid_orders_and_missing_units_never_become_targets(self):
        bridge_world().execute('''
local A=SC_TeamRoles
SC_TeamRolesProvider={apiVersion=1,GetRole=function() return 'TANK',0,{} end}
for _,rank in ipairs({0,-1,1.5,41,'invalid'}) do
 SC_TeamRolesProvider.GetRole=function() return 'TANK',rank end
 assert(A:GetTankOrder('raid1')==nil and A:IsTank('raid1')==true)
end
local called=0;SC_TeamRolesProvider.GetRole=function() called=called+1;return 'TANK',1 end
assert(A:GetRole(nil)==nil and A:GetRole('')==nil and A:GetRole('absent')==nil)
assert(called==0)
''')

    def test_provider_replacement_and_data_changes_do_not_leave_stale_roles(self):
        bridge_world().execute('''
local A=SC_TeamRoles
SC_TeamRolesProvider={apiVersion=1,GetRole=function() return 'TANK',1 end}
assert(A:IsTank('raid1'))
SC_TeamRolesProvider.GetRole=function() return 'DAMAGER' end
assert(A:IsTank('raid1')==false)
units.raid1=nil;assert(A:GetRole('raid1')==nil)
SC_TeamRolesProvider=nil;assert(not A:IsReady() and A:IsTank('raid2')==nil)
''')

    def test_multiple_loads_are_idempotent_and_warnings_are_user_triggered(self):
        lua = bridge_world()
        lua.execute("saved=SC_TeamRoles;SC_TeamRoles:WarnUnavailable('QuickHeal')")
        for _ in range(4):
            lua.execute(BRIDGE)
        lua.execute('''
assert(saved==SC_TeamRoles and table.getn(messages)==1)
SC_TeamRoles:WarnUnavailable('QuickHeal');assert(table.getn(messages)==1)
SC_TeamRoles:WarnUnavailable('GoubayuHeal');assert(table.getn(messages)==2)
''')

    def test_toc_consumers_load_the_same_bridge_first(self):
        for addon in ('NotGrid', 'QuickHeal', 'GoubayuHeal', '!Libs'):
            toc = ADDONS / addon / (addon + '.toc')
            entries = [s.strip() for s in toc.read_text(encoding='utf-8-sig').splitlines()
                       if s.strip() and not s.lstrip().startswith('#')]
            path = (toc.parent / entries[0].replace('\\', '/')).resolve()
            self.assertEqual(path, (ADDONS / '!Libs/SC_TeamRoles.lua').resolve())
            self.assertTrue(path.is_file())


class NotGridTests(unittest.TestCase):
    def test_legacy_lists_and_private_messages_do_not_supply_roles(self):
        notgrid_world().execute('''
NotGrid.ManualRoles={A='TANK'};NotGrid.o.manualroles={A='TANK'}
assert(NotGrid:GetUnitRole('raid1')==nil)
local old=NotGrid.o.manualroles
for _,msg in ipairs({'ROLE:A:HEALER','ROLESELECT'}) do
 arg1='NotGrid';arg2=msg;arg4='A';NotGrid:CHAT_MSG_ADDON()
end
assert(NotGrid.o.manualroles==old and old.A=='TANK')
assert(NotGridRoleSelectionFrame==nil and NotGridRoleSettingsFrame==nil)
assert(NotGrid.ShowRoleSelection==nil and NotGrid.SyncRoleToRaid==nil)
SC_TeamRolesProvider={apiVersion=1,GetRole=function() return 'HEALER' end}
assert(NotGrid:GetUnitRole('raid1')=='HEALER')
''')

    def test_live_threat_tank_flags_remain_independent_of_assigned_roles(self):
        notgrid_world().execute('''
NotGrid:ParseThreatV4('TWTv4=A:1:100:0:100;B:0:90:0:95;')
NotGrid:ParseTankMode('TMTv1=Creature:GUID:A:100;Creature:GUID:B:95;')
assert(NotGrid.TankNames.A and not NotGrid.TankNames.B)
assert(not NotGrid:IsMultiTargetThreatWarning('raid1'))
assert(NotGrid:IsMultiTargetThreatWarning('raid2'))
assert(NotGrid:GetUnitRole('raid1')==nil)
assert(NotGrid:GetUnitThreatPercent('raid1')==100)
''')

    def test_retired_windows_and_role_layout_options_are_removed(self):
        for name in ('frames.lua', 'menus.lua', 'options.lua'):
            text = (ADDONS / 'NotGrid' / name).read_text(encoding='utf-8-sig')
            for retired in ('manualroles', 'showdungeonrole', 'dungeon_role',
                            'NotGridRoleSettingsFrame', 'SyncRoleToRaid'):
                self.assertNotIn(retired, text)


class HealingConsumerTests(unittest.TestCase):
    def test_quickheal_complete_core_with_native_lua50(self):
        # Keep private selection functions in their original lexical scope.
        parts = [ROOT / 'Tools/tests/qh_team_roles_mock.lua',
                 ADDONS / '!Libs/SC_TeamRoles.lua',
                 ADDONS / 'QuickHeal/QuickHeal.lua',
                 ROOT / 'Tools/tests/qh_team_roles_cases.lua']
        script = ROOT / 'PluginHistory/staging/teamroles-qh-current.lua'
        script.write_bytes(b'\n'.join(p.read_bytes() for p in parts))
        vm = ROOT / 'PluginHistory/staging/lua503-validation/win64/lua50.exe'
        result = subprocess.run([str(vm), str(script)], capture_output=True, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stderr.decode('utf-8', errors='replace'))
        self.assertIn(b'PASS QH empty-role/full-health', result.stdout)

    def test_quickheal_retired_xml_and_skin_references_are_gone(self):
        import xml.etree.ElementTree as ET
        xml = ADDONS / 'QuickHeal/QuickHeal.xml'
        ET.parse(xml)
        skin = ADDONS / 'pfUI-addonskinner/skins/QuickHeal.lua'
        for path in (xml, skin):
            text = path.read_text(encoding='utf-8-sig')
            for retired in ('MTListFrame', 'QuickHeal_MTList', 'MeleeDPSListFrame'):
                self.assertNotIn(retired, text)

    def test_goubayu_member_name_retains_template_font_when_file_font_fails(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        install = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
        lua.execute((ROOT / 'Tools/tests/puredispel_wow112_mock.lua').read_text(encoding='utf-8'), install)
        source = (ADDONS / 'GoubayuHeal/GoubayuHeal_UI.lua').read_text(encoding='utf-8-sig')
        start = source.index('        local nm = slotFrame:CreateFontString(')
        end = source.index('        -- 牧师：', start)
        lua.execute("slotFrame=CreateFrame('Frame');group=1;slot=1;FONT='missing';failedFontPaths.missing=true")
        lua.execute(source[start:end] + "\nassert(nm.font and nm.text=='')")

    def test_no_legacy_role_storage_consumers_remain(self):
        for addon in ('NotGrid', 'QuickHeal', 'GoubayuHeal'):
            for path in (ADDONS / addon).glob('*.lua'):
                text = path.read_text(encoding='utf-8-sig')
                for legacy in ('raid_roles', 'ManualRoles', 'QHV.MTList',
                               'QHV.HealerList', 'QHV.MeleeDPSList', 'QHV.RangedDPSList',
                               'ROLESELECT', 'RequestTWARoster', 'RosterUpdated'):
                    self.assertNotIn(legacy, text, str(path))


if __name__ == '__main__':
    unittest.main(verbosity=2)
