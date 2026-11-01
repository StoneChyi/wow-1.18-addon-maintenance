"""Preset and role-policy integration against the actual 1.12 addon modules.

This uses the strict FontString contract and local API fixtures. It does not
establish live role-detection accuracy, rendering quality, or client performance.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / "Interface/AddOns/hyx"
FONT_CONTRACT = ROOT / "Tools/tests/wow112_fontstring_mock.lua"
MOCK = ROOT / "Tools/tests/puredispel_wow112_mock.lua"

# Extra APIs belong to these tests only; do not weaken the shared strict mock.
ROLE_APIS = r'''
function UnitPowerType(unit)
 record('powerType');local u=units[unit]
 if not u then return nil end
 if u.powerType~=nil then return u.powerType end
 if u.class=='WARRIOR' then return 1 elseif u.class=='ROGUE' then return 3 end
 if u.class=='UNKNOWN' then return nil end
 return 0
end
function UnitManaMax(unit) record('maxMana');local u=units[unit];return u and (u.maxMana or 5000) end
function UnitHealthMax(unit) record('maxHealth');local u=units[unit];return u and (u.maxHealth or 7000) end
function UnitHealth(unit) error('preset/role classification must not read current UnitHealth') end
function UnitLevel(unit) return units[unit] and 60 end
function UnitBuff() return nil end
function GetRealmName() return 'PresetTestRealm' end
function GetRaidRosterInfo(i)
 local u=units['raid'..i]
 if u then return u.name,0,u.group,60,u.class or 'WARRIOR',u.class or 'WARRIOR' end
end
function GetRaidTargetIndex() return nil end
'''

FIXTURE = r'''
raidCount=10;partyCount=0;playerClass='PALADIN'
units.player.class='PALADIN';units.player.powerType=0;units.player.group=2
units.raid1=units.player
local members={
 {'Tank','WARRIOR',1,2,16000},
 {'Healer','PRIEST',0,1,7500},
 {'Melee','ROGUE',3,2,6500},
 {'Ranged','HUNTER',0,1,6800},
 {'Caster','MAGE',0,2,5700},
 {'Unknown','DRUID',0,1,9000},
 {'Hybrid','PALADIN',0,2,9500},
 {'TankTwo','DRUID',0,1,19000},
 {'ManaOther','WARLOCK',0,1,6400}
}
for i,m in ipairs(members) do
 local token='raid'..(i+1);AddUnit(token,m[1],'Magic')
 units[token].class=m[2];units[token].powerType=m[3]
 units[token].group=m[4];units[token].maxHealth=m[5]
end
'''

HELPERS = r'''
P=XinDispel.Presets;R=XinDispel.Roles
assert(type(P)=='table' and type(R)=='table','Preset and role modules must be loaded')
function KnownRoles()
 for name,role in pairs({Tank='TANK',Healer='HEALER',Melee='MELEE',Ranged='RANGED',Caster='RANGED',TankTwo='TANK'}) do
  local ok,reason=R.SetManual(name,role);assert(ok,reason)
 end
 R.Refresh()
 XinDispel.MarkDirty()
 if XinDispel.InvalidateUndo then XinDispel.InvalidateUndo() end
end
function SetPreset(key,value)
 local ok,reason=P.Set(key,value)
 assert(ok~=false,reason or ('Preset rejected '..key))
 assert(P.GetConfig()[key]==value,'Preset selection did not take effect')
end
function FindEntry(name)
 for _,key in ipairs({'ready','blocked'}) do
  for _,entry in ipairs(XinDispel.entries[key]) do if entry.name==name then return entry,key end end
 end
end
function Position(name)
 for i,entry in ipairs(XinDispel.entries.ready) do if entry.name==name then return i end end
 return 999
end
function ExpectPolicy(name,state)
 local actual,scope=XinDispel.GetPolicy(name)
 assert(actual==state,name..': expected '..state..', got '..tostring(actual)..' / '..tostring(scope))
end
function Press(object,button) invoke(object,'OnMouseDown',button or 'LeftButton');invoke(object,'OnClick',button or 'LeftButton') end
'''


def world(ui=False, setup="", bad_font=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    installer = lua.execute(FONT_CONTRACT.read_text(encoding="utf-8-sig"))
    lua.execute(MOCK.read_text(encoding="utf-8-sig"), installer)
    lua.execute(ROLE_APIS)
    lua.execute("SetPfUI()")
    if bad_font:
        lua.execute("failedFontPaths['test-pf-font.ttf']=true")
    lua.execute(FIXTURE)
    if setup:
        lua.execute(setup)
    files = ["XinDispel.lua", "RaidData.lua", "RoleTalentData.lua", "RoleDetection.lua", "Presets.lua"]
    if ui:
        files.extend(["PureDispelUI.lua", "PresetsUI.lua", "Debug.lua"])
    for name in files:
        lua.execute((ADDON / name).read_text(encoding="utf-8-sig"))
    lua.execute("FireEvent('VARIABLES_LOADED');FireEvent('PLAYER_ENTERING_WORLD');Tick(.3)")
    lua.execute(HELPERS)
    return lua


class PresetIntegrationTests(unittest.TestCase):
    def run_lua(self, source, **kwargs):
        lua = world(**kwargs)
        lua.execute(source)
        return lua

    def test_role_correction_undo_restores_exactly_once(self):
        self.run_lua(r'''
assert(R.SetManual('Tank','TANK'));XinDispel.InvalidateUndo()
assert(R.SetManual('Tank','HEALER'));assert(XinDispel.CanUndo())
assert(XinDispel.Undo());assert(R.Get('Tank').role=='TANK')
assert(not XinDispel.CanUndo(),'Undo must not record another role operation')
assert(not XinDispel.Undo())
''')

    def test_saved_hidden_window_cannot_start_manual_identification(self):
        self.run_lua(r'''
assert(xinDB.listsVisible==false and R.visible==false)
local ok=R.Refresh();assert(ok==false)
local before=R.GetDiagnostics()
for i=1,20 do Tick(1) end
local after=R.GetDiagnostics()
assert(after.requests==before.requests and after.maxHealthReads==before.maxHealthReads)
''', setup="xinDB={listsVisible=false}", ui=True)

    def test_defaults_are_inert_and_role_detection_starts_disabled(self):
        self.run_lua(r'''
local c=P.GetConfig()
assert(c.priority=='none' and c.ignore=='none' and c.selfFirst==true)
local info=R.Get('Tank');assert(not info or info.role=='UNKNOWN')
ResetCalls();for i=1,20 do Tick(.3) end
assert(not calls.maxHealth,'Disabled role detection must not sample health')
assert(not calls.powerType,'Disabled roles/presets must not poll power types')
assert(XinDispel.GetManualPolicy('Tank')=='normal')
assert(not next(xinDB.teamRules) and not next(xinDB.PriorityList) and not next(xinDB.BlackList))
''')

    def test_options_are_complete_and_have_user_labels(self):
        self.run_lua(r'''
local priorities={none=true,smart=true,tanks=true,healers=true,mana=true,melee=true,ranged=true,casters=true,ownGroup=true}
local ignores={none=true,outsideGroup=true,nonMana=true,melee=true,ranged=true,damage=true}
for kind,expected in pairs({priority=priorities,ignore=ignores}) do
 local seen={}
 for _,option in ipairs(P.Options[kind]) do
  assert(expected[option.key] and not seen[option.key],'Unexpected/duplicate option '..tostring(option.key))
  assert(type(option.label)=='string' and option.label~='')
  assert(type(option.hint)=='string' and option.hint~='')
  seen[option.key]=true
 end
 for key in pairs(expected) do assert(seen[key],'Missing '..key) end
end
''')

    def test_each_priority_selection_immediately_changes_grouping_and_order(self):
        self.run_lua(r'''
KnownRoles()
for _,case in ipairs({
 {'tanks','Tank','Melee'}, {'healers','Healer','Tank'}, {'mana','Caster','Melee'},
 {'melee','Melee','Ranged'}, {'ranged','Ranged','Melee'}, {'casters','Caster','Ranged'},
 {'ownGroup','Melee','Healer'}, {'smart','Tank','Melee'}
}) do
 SetPreset('priority',case[1])
 ExpectPolicy(case[2],'priority')
 assert(Position(case[2])<Position(case[3]),case[1]..' failed to put matching group first')
end
SetPreset('priority','none');ExpectPolicy('Tank','normal')
''')

    def test_self_first_is_independent_from_the_selected_priority(self):
        self.run_lua(r'''
KnownRoles();units.player.auras={{name='SelfMagic',kind='Magic'}};XinDispel.MarkDirty()
SetPreset('priority','tanks');SetPreset('selfFirst',true)
assert(Position('Self')==1)
SetPreset('selfFirst',false)
assert(Position('Tank')<Position('Self'))
''')

    def test_filters_use_confirmed_roles_and_unknowns_stay_available(self):
        self.run_lua(r'''
KnownRoles()
for _,case in ipairs({
 {'melee','Melee','Ranged'}, {'ranged','Ranged','Melee'}, {'damage','Caster','Healer'},
 {'nonMana','Melee','Caster'}
}) do
 SetPreset('ignore',case[1]);ExpectPolicy(case[2],'ignore');assert(not FindEntry(case[2]))
 assert(XinDispel.GetPolicy(case[3])~='ignore')
 assert(FindEntry('Unknown'),'Unknown role must remain available for '..case[1])
end
SetPreset('ignore','none');assert(FindEntry('Melee') and FindEntry('Ranged'))
''')

    def test_low_confidence_or_provisional_roles_cannot_hide_players(self):
        self.run_lua(r'''
KnownRoles()
SetPreset('ignore','melee')
local unknown,hybrid=R.Get('Unknown'),R.Get('Hybrid');assert(unknown and hybrid)
unknown.role,unknown.confidence,unknown.provisional,unknown.source='MELEE','medium',false,'fixture'
hybrid.role,hybrid.confidence,hybrid.provisional,hybrid.source='MELEE','high',true,'fixture'
XinDispel.MarkDirty()
assert(FindEntry('Unknown') and FindEntry('Hybrid'))
assert(not FindEntry('Melee'))
unknown.confidence='high';XinDispel.MarkDirty()
assert(not FindEntry('Unknown'),'Confirmed non-provisional role must activate the filter')
unknown.confidence='low';XinDispel.MarkDirty();assert(FindEntry('Unknown'))
''')

    def test_own_group_filter_is_dynamic_and_unknown_group_is_preserved(self):
        self.run_lua(r'''
KnownRoles();units.raid7.group=nil;XinDispel.MarkDirty()
SetPreset('ignore','outsideGroup')
ExpectPolicy('Healer','ignore');assert(not FindEntry('Healer'))
assert(FindEntry('Melee') and FindEntry('Unknown'))
units.raid3.group=2;XinDispel.MarkDirty()
assert(FindEntry('Healer'),'Moving into own subgroup must restore the target')
units.raid3.group=1;XinDispel.MarkDirty();assert(not FindEntry('Healer'))
''')

    def test_manually_prioritized_players_can_be_rescued_from_auto_filter(self):
        self.run_lua(r'''
KnownRoles();SetPreset('ignore','melee');ExpectPolicy('Melee','ignore')
assert(XinDispel.SetPolicy('Melee','priority','team'))
ExpectPolicy('Melee','priority');assert(FindEntry('Melee'))
assert(string.find(P.GetReason('Melee'),'本队'),'Restored target must explain its manual exception')
assert(XinDispel.ClearPolicy('Melee','team'))
ExpectPolicy('Melee','ignore');assert(not FindEntry('Melee'))
assert(XinDispel.SetPolicy('Melee','ignore','longterm'))
SetPreset('ignore','none');ExpectPolicy('Melee','ignore')
local ok=XinDispel.SetPolicy('Melee','priority','team');assert(not ok,'Manual ignore must not be bypassed')
''')

    def test_manual_ignore_always_wins_over_priority_and_reset(self):
        self.run_lua(r'''
KnownRoles();assert(XinDispel.SetPolicy('Tank','ignore','longterm'))
SetPreset('priority','tanks');ExpectPolicy('Tank','ignore');assert(not FindEntry('Tank'))
P.Reset();ExpectPolicy('Tank','ignore');assert(not FindEntry('Tank'))
assert(xinDB.BlackList.Tank==true)
''')

    def test_preset_selection_does_not_write_per_person_rules(self):
        self.run_lua(r'''
KnownRoles()
local original=XinDispel.SetPolicy
XinDispel.SetPolicy=function() error('Preset must not manufacture per-name manual policies') end
for _,option in ipairs(P.Options.priority) do SetPreset('priority',option.key) end
for _,option in ipairs(P.Options.ignore) do SetPreset('ignore',option.key) end
assert(not next(xinDB.teamRules) and not next(xinDB.PriorityList) and not next(xinDB.BlackList))
XinDispel.SetPolicy=original
''')

    def test_single_undo_reverts_a_preset_and_reset_is_one_atomic_change(self):
        self.run_lua(r'''
KnownRoles();SetPreset('priority','healers');SetPreset('ignore','damage');SetPreset('selfFirst',false)
P.Reset();local c=P.GetConfig();assert(c.priority=='none' and c.ignore=='none' and c.selfFirst)
assert(XinDispel.Undo());c=P.GetConfig()
assert(c.priority=='healers' and c.ignore=='damage' and c.selfFirst==false)
SetPreset('priority','tanks');assert(XinDispel.Undo());assert(P.GetConfig().priority=='healers')
''')

    def test_summary_and_reason_explain_automatic_policy_and_recovery(self):
        self.run_lua(r'''
KnownRoles();SetPreset('ignore','damage')
local reason=P.GetReason('Melee');assert(type(reason)=='string' and reason~='')
local summary=P.GetSummary();assert(type(summary)=='table' and summary.roles~=nil)
assert(type(P.GetReason('Unknown'))=='string')
SetPreset('ignore','none');assert(FindEntry('Melee'))
assert(XinDispel.GetManualPolicy('Melee')=='normal')
''')

    def test_role_and_roster_changes_recompute_without_resaving_the_preset(self):
        self.run_lua(r'''
KnownRoles();SetPreset('ignore','damage');assert(FindEntry('Healer'))
assert(R.SetManual('Healer','RANGED'));XinDispel.MarkDirty();assert(not FindEntry('Healer'))
assert(R.SetManual('Healer','HEALER'));XinDispel.MarkDirty();assert(FindEntry('Healer'))
AddUnit('raid11','NewMelee','Magic');units.raid11.class='ROGUE';units.raid11.powerType=3;units.raid11.group=2
raidCount=11;FireEvent('RAID_ROSTER_UPDATE');Tick(.3)
assert(R.SetManual('NewMelee','MELEE'));XinDispel.MarkDirty()
ExpectPolicy('NewMelee','ignore');assert(not FindEntry('NewMelee'))
''')

    def test_banned_auras_and_expired_casts_still_block_casting(self):
        self.run_lua(r'''
KnownRoles();SetPreset('priority','tanks')
local stale=FindEntry('Tank');assert(stale)
assert(XinDispel.SetIgnoreRule('Debuff-Magic',2))
local ok=XinDispel.Cast(stale);assert(not ok and table.getn(casts)==0)
XinDispel.SetIgnoreRule('Debuff-Magic',0)
stale=FindEntry('Tank');assert(stale)
units.raid2.guid='new-person';units.raid2.name='Replacement'
ok=XinDispel.Cast(stale);assert(not ok and table.getn(casts)==0)
''')

    def test_no_external_role_provider_or_current_health_dependency(self):
        self.run_lua(r'''
KnownRoles()
for _,option in ipairs(P.Options.priority) do SetPreset('priority',option.key) end
for _,option in ipairs(P.Options.ignore) do SetPreset('ignore',option.key) end
XinDispel.MarkDirty();assert(P.GetSummary())
''', setup=r'''
local trap=setmetatable({}, {__index=function() error('External addon role state accessed') end})
SC_TeamRoles=trap;QuickHeal=trap;NotGrid=trap;StatCompare=trap
''')

    def test_invalid_selections_do_not_mutate_the_current_config(self):
        self.run_lua(r'''
KnownRoles();SetPreset('priority','tanks');SetPreset('ignore','damage')
assert(not P.Set('priority','not-a-preset'));assert(not P.Set('ignore','not-a-filter'))
assert(not P.Set('unknownSetting','none'))
local c=P.GetConfig();assert(c.priority=='tanks' and c.ignore=='damage')
''')

    def test_ui_is_lazy_reused_and_choosing_option_is_immediate(self):
        self.run_lua(r'''
KnownRoles();local U=XinDispel.UI
assert(not U.presets)
U.OpenPresets();local panel=U.presets;assert(panel and panel:IsShown())
Press(panel.priority)
local picker=U.presetPicker;assert(picker and picker:IsShown())
local found
for _,row in ipairs(picker.rows) do if row.option and row.option.key=='tanks' then found=row;break end end
assert(found,'Tank preset option missing');Press(found)
assert(P.GetConfig().priority=='tanks' and Position('Tank')<Position('Melee'))
local count=table.getn(objects)
for i=1,5 do panel:Hide();U.OpenPresets() end
assert(U.presets==panel and table.getn(objects)==count,'Reopening leaked UI objects')
U.OpenRoleEditor('Unknown');local editor=U.roleEditor;assert(editor)
Press(editor.buttons.HEALER)
assert(R.Get('Unknown').role=='HEALER')
''', ui=True, bad_font=True)

    def test_picker_hide_releases_blocker_and_reuse_has_no_stale_options(self):
        self.run_lua(r'''
KnownRoles();local U=XinDispel.UI;U.OpenPresets()
Press(U.presets.priority);local picker=U.presetPicker
assert(picker.blocker:IsShown())
picker:Hide();assert(not picker.blocker:IsShown())
Press(U.presets.ignore);assert(U.presetPicker==picker and picker.kind=='ignore')
for i,row in ipairs(picker.rows) do
 if i>table.getn(P.Options.ignore) then assert(not row:IsShown() and not row.option) end
end
picker:Hide();assert(not picker.blocker:IsShown())
''', ui=True)

    def test_auto_ignored_manager_row_opens_preset_and_can_restore_everyone(self):
        self.run_lua(r'''
KnownRoles();SetPreset('ignore','melee');assert(not FindEntry('Melee'))
local U=XinDispel.UI;U.OpenManager('ignore')
local target
for _,row in ipairs(U.manager.rows) do
 if row.item and row.item.name=='Melee' and row.item.scope=='preset' then target=row;break end
end
assert(target and target.restore.label:GetText()=='预设')
Press(target.restore);assert(U.presets and U.presets:IsShown())
Press(U.presets.ignore)
local none
for _,row in ipairs(U.presetPicker.rows) do if row.option and row.option.key=='none' then none=row;break end end
assert(none);Press(none)
assert(P.GetConfig().ignore=='none' and FindEntry('Melee'))
assert(XinDispel.GetManualPolicy('Melee')=='normal','Automatic restore must not write an exception list')
''', ui=True)


if __name__ == "__main__":
    unittest.main(verbosity=2)
