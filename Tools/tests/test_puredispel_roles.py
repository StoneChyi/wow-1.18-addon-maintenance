"""Independent role engine checks; simulations are not live-client validation."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/hyx'
FIXTURE = r'''
XinDispel={};roster={};sent={};hpReads=0;nativeReads=0
function UnitClass(unit) nativeReads=nativeReads+1;local u=units[unit];return u and u.class,u and u.class end
function GetUnitField(unit,field)
 assert(field=='maxHealth','current health/other unit fields are forbidden')
 hpReads=hpReads+1;return units[unit] and units[unit].maxHealth
end
function UnitHealth() error('current health must never be read') end
function UnitHealthMax() error('unexpected percentage/legacy fallback') end
function GetTalentInfo() error('no remote inspect fallback') end
function GetNampowerVersion() return '4.6.3' end
function SendAddonMessage(p,m,c) table.insert(sent,{p,m,c}) end
function SetCVar() error('role module must not change CVars') end
function UnitIsEnemy(player,unit) return units[unit] and units[unit].enemy end
function UnitIsPlayer(unit) return not (units[unit] and units[unit].npc) end
function AddMember(name,class,hp)
 local token='raid'..(table.getn(roster)+1)
 AddUnit(token,name,nil);units[token].class=class;units[token].maxHealth=hp or 5000
 table.insert(roster,{name=name,unit=token,key=units[token].guid,class=class,self=false})
 return token
end
function Step(dt)
 now=now+(dt or 1)
 R.SetEnabled(R.enabled);R.SetVisible(R.visible)
 R.UpdateRoster(roster);R.Tick(now)
end
function Begin() R.UpdateRoster(roster);R.SetEnabled(true);Step(0) end
function Build(class,tree,points,signature)
 local result={{},{},{}};local data=XinDispel.RoleTalentData[class]
 if signature then result[tree][signature]=1;points=points-1 end
 for i,entry in ipairs(data[tree]) do
  if i~=signature and points>0 then local n=math.min(entry[1],points);result[tree][i]=n;points=points-n end
 end
 assert(points==0,'not enough points in tree');return result
end
function Reply(sender,class,ranks,options)
 options=options or {};ranks=ranks or {{},{},{}}
 local data=XinDispel.RoleTalentData[class]
 local suffix=options.terminator and ';' or ''
 local function Packet(body,p)
  R.OnEvent('CHAT_MSG_ADDON',p or 'TW_CHAT_MSG_WHISPER',body,'WHISPER',sender)
 end
 for tree=1,3 do
  local sum=0;for _,rank in pairs(ranks[tree] or {}) do sum=sum+rank end
  Packet('INSTalentTabInfo;'..tree..';Tree;'..sum..';'..table.getn(data[tree])..suffix)
  for i,entry in ipairs(data[tree]) do
   if not (options.missing and tree==3 and i==1) then
    local rank=ranks[tree] and ranks[tree][i] or 0
    Packet('INSTalentInfo;'..tree..';'..i..';Talent;'..entry[2]..';'..entry[3]..';'..rank..';'..entry[1]..';1;-1;-1;-1'..suffix)
   end
  end
 end
 Packet('INSTalentEND;')
end
'''


def world():
    lua = LuaRuntime(unpack_returned_tuples=True)
    installer = lua.execute((ROOT / 'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8-sig'))
    lua.execute((ROOT / 'Tools/tests/puredispel_wow112_mock.lua').read_text(encoding='utf-8-sig'), installer)
    lua.execute(FIXTURE)
    for name in ('RoleTalentData.lua', 'RoleDetection.lua'):
        lua.execute((ADDON / name).read_text(encoding='utf-8-sig'))
    lua.execute('R=XinDispel.Roles')
    return lua


class RoleEngine(unittest.TestCase):
    def check_lua(self, text):
        world().execute(text)

    def test_disabled_and_hidden_cost_nothing(self):
        self.check_lua("""
        AddMember('A','WARRIOR',9000);R.UpdateRoster(roster)
        for i=1,100 do Step(.25) end
        assert(hpReads==0 and table.getn(sent)==0 and R.GetDiagnostics().ticks==0)
        R.SetVisible(false);R.SetEnabled(true)
        for i=1,100 do Step(.25) end
        assert(hpReads==0 and table.getn(sent)==0)
        for _,o in ipairs(objects) do assert(not o.scripts.OnUpdate) end
        """)

    def test_one_serial_request_and_complete_structure(self):
        self.check_lua("""
        AddMember('A','MAGE');AddMember('B','ROGUE');Begin()
        assert(table.getn(sent)==1 and sent[1][1]=='TW_CHAT_MSG_WHISPER<A>')
        assert(sent[1][2]=='INSTalentShow' and sent[1][3]=='GUILD')
        Reply('A','MAGE');assert(R.Get('A').role=='RANGED' and R.Get('A').confidence=='high')
        Step(1);assert(table.getn(sent)==2 and sent[2][1]=='TW_CHAT_MSG_WHISPER<B>')
        Reply('B','ROGUE');assert(R.Get('B').role=='MELEE')
        """)

    def test_foreign_sender_prefix_and_end_cannot_complete(self):
        self.check_lua("""
        AddMember('A','MAGE');Begin();Reply('Stranger','MAGE')
        R.OnEvent('CHAT_MSG_ADDON','bogusTW_CHAT_MSG_WHISPER','INSTalentEND;','WHISPER','A')
        R.OnEvent('CHAT_MSG_ADDON','TW_CHAT_MSG_WHISPER','xINSTalentEND;','WHISPER','A')
        assert(R.GetDiagnostics().pending and not R.Get('A').talents)
        Reply('A','MAGE');assert(R.Get('A').queryState=='complete')
        """)

    def test_missing_packet_pauses_batch(self):
        self.check_lua("""
        AddMember('A','MAGE');AddMember('B','ROGUE');Begin()
        Reply('A','MAGE',nil,{missing=true});Step(10)
        assert(R.Get('A').queryState=='incomplete' and table.getn(sent)==1)
        assert(R.GetDiagnostics().state=='paused' and not R.Get('A').talents)
        """)

    def test_one_terminal_separator_is_allowed(self):
        self.check_lua("AddMember('A','MAGE');Begin();Reply('A','MAGE',nil,{terminator=true});assert(R.Get('A').queryState=='complete')")

    def test_malformed_rank_extra_fields_and_middle_empty_fail(self):
        for tail in (';99;1;1;-1;-1;-1', ';0;99;1;-1;-1;-1', ';0;1;1;-1;-1;-1;extra', ';0;;1;-1;-1;-1'):
            lua = world()
            lua.execute("AddMember('A','MAGE');Begin();local d=XinDispel.RoleTalentData.MAGE[1];R.OnEvent('CHAT_MSG_ADDON','TW_CHAT_MSG_WHISPER','INSTalentTabInfo;1;Tree;0;'..table.getn(d),'WHISPER','A')")
            lua.globals().bad_tail = tail
            lua.execute("local d=XinDispel.RoleTalentData.MAGE[1][1];R.OnEvent('CHAT_MSG_ADDON','TW_CHAT_MSG_WHISPER','INSTalentInfo;1;1;Talent;'..d[2]..';'..d[3]..bad_tail,'WHISPER','A');assert(R.GetDiagnostics().state=='paused')")

    def test_timeout_pauses_and_late_sender_is_isolated(self):
        self.check_lua("""
        AddMember('A','MAGE');AddMember('B','ROGUE');Begin();Step(7)
        assert(R.Get('A').queryState=='timeout' and table.getn(sent)==1)
        Reply('A','MAGE');assert(not R.Get('A').talents)
        R.Refresh();Step(1);assert(sent[2][1]=='TW_CHAT_MSG_WHISPER<B>')
        Reply('A','MAGE');assert(R.GetDiagnostics().pending and not R.Get('B').talents)
        Reply('B','ROGUE');assert(R.Get('B').queryState=='complete')
        """)

    def test_reset_does_not_let_old_pending_enter_new_team(self):
        self.check_lua("""
        AddMember('A','MAGE');Begin();R.ResetTeam();R.UpdateRoster(roster);Step(1)
        Reply('A','MAGE');assert(table.getn(sent)==1 and not R.Get('A').talents)
        assert(R.Get('A').queryState=='isolated')
        """)

    def test_unit_identity_change_rejects_old_response(self):
        self.check_lua("""
        local u=AddMember('A','MAGE');Begin();units[u].name='B';units[u].guid='guid:B'
        Reply('A','MAGE');assert(not R.GetDiagnostics().pending and not R.Get('A'))
        """)

    def test_manual_default_none_and_undo_bypasses_wrapper(self):
        self.check_lua("""
        AddMember('A','DRUID');R.UpdateRoster(roster)
        local ok,reason,old=R.SetManual('A','TANK')
        assert(ok and old==nil and hpReads==0 and table.getn(sent)==0)
        assert(R.Get('A').source=='manual' and not R.Get('A').provisional)
        local raw=R.SetManual;R.SetManual=function() error('undo must not re-enter wrapper') end
        assert(R.RestoreManual('A',old));assert(R.Get('A').role=='UNKNOWN')
        assert(not raw('A','caster') and not raw('Unknown','TANK'))
        """)

    def test_cached_roles_and_peek_have_no_repeated_native_sampling(self):
        self.check_lua("""
        AddMember('A','MAGE');Begin();Reply('A','MAGE');local initialHP=hpReads
        for i=1,100 do Step(1) end
        assert(hpReads==initialHP and table.getn(sent)==1)
        local before=nativeReads
        for i=1,100 do assert(R.Peek('A',roster[1].key,'MAGE')) end
        assert(nativeReads==before and not R.Peek('A','wrong','MAGE'))
        assert(not R.GetDiagnostics().validationActive)
        """)

    def test_repeated_state_sync_preserves_one_second_throttle(self):
        self.check_lua("""
        AddMember('A','MAGE');Begin();Reply('A','MAGE');local before=R.GetDiagnostics().ticks
        for i=1,20 do Step(.25) end
        assert(R.GetDiagnostics().ticks-before==5)
        """)

    def test_combat_uses_cache_and_does_not_query_new_members(self):
        self.check_lua("""
        AddMember('A','MAGE');Begin();Reply('A','MAGE')
        R.OnEvent('PLAYER_REGEN_DISABLED');AddMember('B','WARRIOR',9000)
        local before=hpReads;for i=1,20 do Step(1) end
        assert(hpReads==before and table.getn(sent)==1 and not R.Refresh())
        assert(R.Get('A').role=='RANGED' and R.Get('B').role=='UNKNOWN')
        R.OnEvent('PLAYER_REGEN_ENABLED');Step(1);assert(table.getn(sent)==2)
        """)

    def test_refresh_invalidates_old_talents(self):
        self.check_lua("""
        AddMember('A','MAGE');Begin();Reply('A','MAGE');R.Refresh()
        assert(not R.Get('A').talents and R.Get('A').role=='UNKNOWN')
        Step(1);assert(R.Get('A').role=='UNKNOWN')
        """)

    def test_high_health_alone_remains_unknown(self):
        self.check_lua("""
        AddMember('A','WARRIOR',50000);AddMember('B','MAGE');AddMember('C','ROGUE');Begin()
        assert(R.Get('A').role=='UNKNOWN');Reply('A','WARRIOR')
        assert(R.Get('A').role=='UNKNOWN' and R.Get('A').provisional)
        """)

    def test_known_defensive_tree_and_feral_uncertainty(self):
        self.check_lua("""
        AddMember('A','WARRIOR');Begin();Reply('A','WARRIOR',Build('WARRIOR',3,31,14))
        assert(R.Get('A').role=='TANK' and R.Get('A').confidence=='high' and not R.Get('A').provisional)
        R.ResetTeam();roster={};AddMember('B','DRUID');R.UpdateRoster(roster);Step(1)
        Reply('B','DRUID',Build('DRUID',2,31,18))
        assert(R.Get('B').role=='MELEE' and R.Get('B').provisional)
        """)

    def test_short_validation_is_explicit_bounded_and_conservative(self):
        self.check_lua("""
        local u=AddMember('A','WARRIOR',9000);AddMember('B','MAGE');AddMember('C','ROGUE');Begin()
        local spec=Build('WARRIOR',2,31,17);spec[3]=Build('WARRIOR',3,16,12)[3]
        Reply('A','WARRIOR',spec);assert(R.Get('A').candidate and R.Get('A').confidence=='low')
        assert(not R.StartValidation());R.OnEvent('PLAYER_REGEN_DISABLED');assert(R.StartValidation())
        units.target={name='Enemy',guid='npc:1',npc=true,enemy=true,class='WARRIOR'}
        for i=1,4 do R.OnEvent('AUTO_ATTACK_OTHER','npc:1',units[u].guid,500,0,5,1,50,0,0) end
        Step(8);local rec=R.Get('A');assert(rec.role=='TANK' and rec.confidence=='medium' and rec.provisional)
        assert(rec.validation.attacks==4 and not R.GetDiagnostics().validationActive)
        assert(not R.StartValidation())
        for _,o in ipairs(objects) do assert(not o.events.AUTO_ATTACK_OTHER) end
        R.OnEvent('AUTO_ATTACK_OTHER','npc:1',units[u].guid,900,0,1,1,0,0,0)
        assert(R.GetDiagnostics().validationEvents==4)
        """)

    def test_unknown_hostile_or_player_attacker_cannot_promote(self):
        self.check_lua("""
        local u=AddMember('A','WARRIOR');local b=AddMember('B','MAGE');Begin()
        R.OnEvent('PLAYER_REGEN_DISABLED');assert(R.StartValidation())
        for i=1,4 do R.OnEvent('AUTO_ATTACK_OTHER','unresolved',units[u].guid,500,0,1,1,0,0,0) end
        units.target={name='B',guid=units[b].guid,enemy=true,class='MAGE'}
        for i=1,4 do R.OnEvent('AUTO_ATTACK_OTHER',units[b].guid,units[u].guid,500,0,1,1,0,0,0) end
        Step(8);assert(R.GetDiagnostics().validationEvents==0 and R.Get('A').role=='UNKNOWN')
        """)

    def test_manual_batch_finishes_with_presets_off(self):
        self.check_lua("""
        AddMember('A','MAGE');R.UpdateRoster(roster);assert(R.Refresh());Step(1)
        Reply('A','MAGE');Step(1);local count=hpReads
        assert(not R.enabled and R.Get('A').queryState=='complete')
        for i=1,80 do Step(1) end
        assert(hpReads==count and table.getn(sent)==1)
        for _,o in ipairs(objects) do assert(not o.events.CHAT_MSG_ADDON) end
        """)

    def test_diagnostics_has_no_personal_names(self):
        lua = world()
        lua.execute("AddMember('PrivateName','MAGE');Begin()")
        for key, value in lua.globals().R.GetDiagnostics().items():
            self.assertNotIn('PrivateName', str(key) + str(value))

    def test_manual_saved_fields_and_same_owner_reload(self):
        lua = world()
        lua.execute("""
        xinDB={teamOwner='Realm:Self'};XinDispel.teamOwnerReady=true
        AddMember('A','DRUID');R.UpdateRoster(roster);assert(R.SetManual('A','TANK'))
        local saved=xinDB.teamRoleOverrides.A
        assert(saved.role=='TANK' and saved.key=='guid:A' and saved.class=='DRUID')
        local n=0;for _ in pairs(saved) do n=n+1 end;assert(n==3)
        R.SetEnabled(false)
        """)
        lua.execute((ADDON / 'RoleDetection.lua').read_text(encoding='utf-8-sig'))
        lua.execute("""
        R=XinDispel.Roles;R.UpdateRoster(roster)
        local ok,reason,old=R.SetManual('A','HEALER')
        assert(ok and old=='TANK' and hpReads==0)
        assert(R.RestoreManual('A',old) and xinDB.teamRoleOverrides.A.role=='TANK')
        R.SetEnabled(true);Step(0);assert(R.Get('A').source=='manual' and R.Get('A').role=='TANK')
        """)

    def test_manual_owner_identity_departure_and_reset_guards(self):
        self.check_lua("""
        xinDB={teamOwner='Realm:Self',teamRoleOwner='Realm:Other',
          teamRoleOverrides={A={role='TANK',key='guid:A',class='DRUID'}}}
        XinDispel.teamOwnerReady=true;AddMember('A','DRUID');Begin()
        assert(not R.Get('A').manual and not xinDB.teamRoleOverrides.A)
        assert(R.SetManual('A','TANK'));assert(xinDB.teamRoleOverrides.A)
        roster={};Step(1);assert(not xinDB.teamRoleOverrides.A and not R.Get('A'))
        roster={};AddMember('A','DRUID');Step(1)
        assert(R.SetManual('A','HEALER'));R.ResetTeam()
        assert(next(xinDB.teamRoleOverrides)==nil)
        """)

    def test_saved_manual_requires_identity_and_known_owner(self):
        self.check_lua("""
        xinDB={teamOwner='Realm:Self',teamRoleOwner='Realm:Self',
          teamRoleOverrides={A={role='TANK',key='other-guid',class='DRUID'}}}
        XinDispel.teamOwnerReady=false;AddMember('A','DRUID');Begin()
        assert(not R.Get('A').manual and xinDB.teamRoleOverrides.A.role=='TANK')
        XinDispel.teamOwnerReady=true;Step(1);assert(not R.Get('A').manual)
        xinDB.teamRoleOverrides.A.key='guid:A';Step(1)
        assert(R.Get('A').manual=='TANK' and R.Get('A').confidence=='high')
        """)

    def test_ambiguous_fury_is_not_confirmed_melee_with_missing_hp_or_two_people(self):
        for fixture in (
            "AddMember('A','WARRIOR',9000);AddMember('B','MAGE')",
            "local u=AddMember('A','WARRIOR');units[u].maxHealth=nil;AddMember('B','MAGE');AddMember('C','ROGUE')",
        ):
            lua = world()
            lua.execute(fixture)
            lua.execute("""
            Begin();local spec=Build('WARRIOR',2,31,17);spec[3]=Build('WARRIOR',3,16,12)[3]
            Reply('A','WARRIOR',spec);local rec=R.Get('A')
            assert(rec.role=='MELEE' and rec.confidence=='medium' and rec.provisional)
            assert(rec.source=='talent-ambiguous' and not rec.candidate)
            """)

    def test_inactive_departure_clears_saved_manual_without_sampling(self):
        self.check_lua("""
        xinDB={teamOwner='Realm:Self'};XinDispel.teamOwnerReady=true
        local u=AddMember('A','DRUID');R.UpdateRoster(roster);assert(R.SetManual('A','HEALER'))
        assert(xinDB.teamRoleOverrides.A and not R.enabled)
        units[u]=nil;roster={};Step(1)
        assert(not xinDB.teamRoleOverrides.A and not R.Get('A'))
        AddMember('A','DRUID');Step(1)
        local ok,reason,old=R.SetManual('A','MELEE');assert(ok and old==nil)
        assert(hpReads==0 and table.getn(sent)==0 and R.GetDiagnostics().ticks==0)
        """)

    def test_initial_missing_group_does_not_erase_unseen_reload_override(self):
        self.check_lua("""
        xinDB={teamOwner='Realm:Self',teamRoleOwner='Realm:Self',
          teamRoleOverrides={A={role='TANK',key='guid:A',class='DRUID'}}}
        XinDispel.teamOwnerReady=true;R.UpdateRoster(roster)
        assert(xinDB.teamRoleOverrides.A)
        local u=AddMember('A','DRUID');Step(1);assert(xinDB.teamRoleOverrides.A)
        roster={};units[u]=nil;Step(1);assert(not xinDB.teamRoleOverrides.A)
        assert(hpReads==0 and table.getn(sent)==0)
        """)

    def test_offline_first_member_is_skipped_and_requeued_only_after_reconnect(self):
        self.check_lua("""
        local a=AddMember('A','MAGE');units[a].offline=true
        AddMember('B','ROGUE');Begin();local initialHP=hpReads
        assert(R.Get('A').queryState=='offline' and table.getn(sent)==1)
        assert(sent[1][1]=='TW_CHAT_MSG_WHISPER<B>')
        Reply('B','ROGUE');Step(1)
        assert(R.Get('A').queryState=='offline' and table.getn(sent)==1)
        units[a].offline=false;Step(1)
        assert(R.Get('A').queryState=='pending' and sent[2][1]=='TW_CHAT_MSG_WHISPER<A>')
        Reply('A','MAGE');assert(R.Get('A').queryState=='complete')
        assert(R.GetDiagnostics().timeouts==0 and hpReads==initialHP)
        """)


if __name__ == '__main__':
    unittest.main()
