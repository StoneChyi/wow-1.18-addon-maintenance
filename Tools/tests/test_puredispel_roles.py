"""PureDispel adapter checks; protocol validation belongs to shared-service tests."""
import unittest
from test_puredispel_presets import world

class SharedRoleAdapter(unittest.TestCase):
    def run_lua(self, code, **kwargs):
        lua=world(**kwargs);lua.execute(code)

    def test_one_cache_and_one_data_table(self):
        self.run_lua("""
local S=SC_TeamRolesService;S:Acquire('fixture')
assert(XinDispel.RoleTalentData==SC_TeamRoleData)
assert(R.Get('Tank')==S:GetInfo('Tank'))
assert(R.SetManual('Tank','TANK'))
assert(SC_TeamRoles:IsTank('raid2')==true)
assert(R.Get('Tank')==S:GetInfo('raid2'))
""")

    def test_damage_role_and_combat_style_are_separate(self):
        self.run_lua("""
SC_TeamRolesService:Acquire('fixture');assert(R.SetManual('Melee','MELEE'))
local info=R.Get('Melee');assert(info.role=='DAMAGER' and info.style=='MELEE')
assert(SC_TeamRoles:GetRole(info.unit)=='DAMAGER' and SC_TeamRoles:IsTank(info.unit)==false)
assert(R.SetManual('Melee','RANGED'));assert(info.role=='DAMAGER' and info.style=='RANGED')
""")

    def test_hiding_one_consumer_does_not_cancel_others(self):
        self.run_lua("""
local S=SC_TeamRolesService;S:Acquire('QuickHeal')
R.SetEnabled(true);R.SetVisible(false);R.SetEnabled(false)
assert(S:IsReady() and S:GetInfo('Tank'));assert(R.SetManual('Tank','TANK'))
R.ResetTeam();assert(SC_TeamRoles:IsTank(R.Get('Tank').unit)==true)
""")

    def test_old_saved_overrides_are_not_imported(self):
        self.run_lua("""
SC_TeamRolesService:Acquire('fixture')
local rec=R.Get('Tank');assert(rec and not rec.overrideRole)
""",setup="xinDB={teamRoleOverrides={Tank={role='TANK'}}}")

    def test_peek_rejects_wrong_identity_and_expired_facts(self):
        self.run_lua("""
local S=SC_TeamRolesService;S:Acquire('fixture');local rec=R.Get('Tank')
assert(R.Peek(rec.name,'wrong',rec.class)==nil)
rec.role='TANK';rec.confidence='high';rec.provisional=false;rec.time=now-1000
assert(R.Peek(rec.name,rec.key,rec.class)==nil)
assert(R.SetManual('Tank','TANK'));assert(R.Peek(rec.name,rec.key,rec.class)==rec)
""")

    def test_shared_changes_recompute_dispel_without_private_role_polling(self):
        self.run_lua("""
local S=SC_TeamRolesService;S:Acquire('fixture');SetPreset('ignore','melee')
assert(S:SetOverride('Melee','DAMAGER','MELEE'));XinDispel.MarkDirty();ExpectPolicy('Melee','ignore')
assert(S:SetOverride('Melee','HEALER'));XinDispel.MarkDirty();ExpectPolicy('Melee','normal')
assert(R.StartValidation()==false)
""")

if __name__=='__main__':unittest.main(verbosity=2)
