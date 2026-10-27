"""Offline checks for the actual 1.12 EavesDrop manual sampler.

No DLLs are executed, no private chat is observed, and no saved account files
are read or modified. The sampler does not construct any text controls.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

SOURCE = ROOT / "Interface/AddOns/EavesDrop/diagnostics.lua"
STUB = r'''
current=0; UIParent={}; version={4,6,1}; failEvent=nil; frames={}
player='0x0000000000000001'; pet='0x0000000000000002'
enemy='0x0000000000000003'; ally='0x0000000000000004'
lost='0xF13000EA59000001'; otherLost='0xF13000EA59000002'
names={[player]='Me',[pet]='Wolf',[enemy]='Wolf',[ally]='Ally',[lost]='迷失者',[otherLost]='迷失者'}
owners={}; created={}; summoned={}; fieldsRead=0
GetTime=function()return current end
GetNampowerVersion=function()return unpack(version)end
GetUnitGUID=function(u)
 if u=='player' then return player elseif u=='pet' then return pet end
 return owners[u]
end
UnitExists=function()return false end
UnitName=function(u)if u=='player' then return 'Me' elseif u=='pet' then return 'Wolf' end;return names[u]end
GetUnitField=function(u,key)
 fieldsRead=fieldsRead+1
 if key=='createdBy' then return created[u] elseif key=='summonedBy' then return summoned[u] end
 error('unsupported field: '..tostring(key))
end
GetSpellRecField=function(id,key)assert(key=='name');return 'Spell'..id end
SUPERWOW_STRING='SuperWoW test'
SetCVar=function()error('sampler must never write a CVar')end
GetCurrentCombatTextEventInfo=function()error('modern combat text getter is not available in 1.12')end
EavesDrop={_running=true,active=true,refreshes=0}
function EavesDrop:IsActive()return self.active end
function EavesDrop:UpdateSettings()self.refreshes=self.refreshes+1 end
CreateFrame=function(kind,name,parent)
 assert(kind=='Frame')
 local f={events={},scripts={}}
 function f:RegisterEvent(e)if e==failEvent then error('not supported')end;self.events[e]=true end
 function f:UnregisterAllEvents()self.events={} end
 function f:IsEventRegistered(e)return self.events[e]end
 function f:SetScript(k,v)self.scripts[k]=v end
 frames[name]=f
 return f
end
function fire(name,...)
 local f=EavesDrop.captureFrame
 if not f or not f.events[name] then return false end
 event=name;arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9=unpack(arg)
 f.scripts.OnEvent()
 event=nil;arg1=nil;arg2=nil;arg3=nil;arg4=nil;arg5=nil;arg6=nil;arg7=nil;arg8=nil;arg9=nil
 return true
end
function tick(t)
 current=t
 local f=EavesDrop.captureFrame
 if f and f.scripts.OnUpdate then f.scripts.OnUpdate()end
end
'''


def runtime(before=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUB)
    if before:
        lua.execute(before)
    lua.execute(SOURCE.read_text(encoding="utf-8-sig"))
    return lua


class CaptureTests(unittest.TestCase):
    def test_load_is_inert_and_old_records_are_not_auto_resumed(self):
        r = runtime("EavesDropCaptureDB={records={{event='COMBAT_TEXT_UPDATE'}},reason='采样中'}")
        r.execute("assert(not EavesDrop.captureFrame); local s=EavesDrop:GetCaptureState();assert(not s.active and s.count==1 and s.reason=='上次会话已结束');assert(next(frames)==nil)")

    def test_capture_rejects_disabled_monitor(self):
        r = runtime()
        r.execute("EavesDrop._running=false;local ok,reason=EavesDrop:StartCapture();assert(not ok and reason and not EavesDrop.captureFrame);EavesDrop._running=true;EavesDrop.active=false;assert(not EavesDrop:StartCapture())")

    def test_combat_text_keeps_native_arguments_and_types(self):
        r = runtime()
        r.execute("assert(EavesDrop:StartCapture());current=.123;fire('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者',42,true,nil,9);local a=EavesDropCaptureDB.records[1];assert(a.event=='COMBAT_TEXT_UPDATE' and a.time==.123 and a.args.n==9 and a.args[1]=='SPELL_CAST' and a.args[2]=='召唤迷失者' and a.args[3]==42 and a.args[4]==true and a.args[5]==nil and a.args[6]==9)")

    def test_reactive_hint_is_preserved_without_claiming_summon(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','SPELL_ACTIVE','召唤迷失者');local a=EavesDropCaptureDB.records[1];assert(a.args[1]=='SPELL_ACTIVE' and not a.trigger and not a.spawn)")

    def test_spell_go_self_and_other_keep_correct_identity(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('SPELL_GO_SELF',60809,123,player,enemy,0,1,0);fire('SPELL_GO_OTHER',0,124,ally,enemy,0,1,0);assert(#EavesDropCaptureDB.records==1);local a=EavesDropCaptureDB.records[1];assert(a.spellId==123 and a.spellName=='Spell123' and a.actors[1].relation=='player' and a.actors[1].role=='source')")

    def test_unit_castevent_uses_superwow_signature(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('UNIT_CASTEVENT',player,enemy,'CAST',123,1500);local a=EavesDropCaptureDB.records[1];assert(a.args[3]=='CAST' and a.spellId==123 and a.args[5]==1500 and a.actors[1].relation=='player')")

    def test_ordinary_unrelated_damage_is_filtered_despite_same_pet_name(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('AUTO_ATTACK_OTHER',enemy,ally,55);assert(#EavesDropCaptureDB.records==0);fire('AUTO_ATTACK_OTHER',enemy,player,55);assert(#EavesDropCaptureDB.records==1)")

    def test_owned_guardian_is_kept_with_owner_fields(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();created[lost]=player;fire('AUTO_ATTACK_OTHER',lost,enemy,55);local a=EavesDropCaptureDB.records[1].actors[1];assert(a.guid==lost and a.ownerGUID==player and a.createdBy==player and a.relation=='owned' and a.entry==59993 and a.candidate)")

    def test_unknown_owner_lost_is_only_a_candidate(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('AUTO_ATTACK_OTHER',lost,enemy,55);local a=EavesDropCaptureDB.records[1].actors[1];assert(a.relation=='unknown-owner' and a.candidate and not a.ownerGUID)")

    def test_foreign_lost_retains_explicit_foreign_owner(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();owners[otherLost..'owner']=ally;fire('AUTO_ATTACK_OTHER',otherLost,enemy,55);local a=EavesDropCaptureDB.records[1].actors[1];assert(a.relation=='other-owner' and a.candidate and a.ownerGUID==ally)")

    def test_legacy_scope_keeps_self_and_restricts_other_lines(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('CHAT_MSG_SPELL_SELF_BUFF','你施放了测试');fire('CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE','其他生物击中目标');fire('CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE','迷失者击中目标');assert(#EavesDropCaptureDB.records==2)")

    def test_private_chat_and_non_whitelist_events_are_never_registered(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();assert(not fire('CHAT_MSG_WHISPER','private'));EavesDrop:CaptureEvent('CHAT_MSG_GUILD','private');assert(#EavesDropCaptureDB.records==0);for e in pairs(EavesDrop.captureFrame.events)do assert(not string.find(e,'WHISPER') and not string.find(e,'GUILD') and not string.find(e,'CHANNEL'))end")

    def test_records_stop_exactly_at_limit(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();for i=1,1001 do fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test')end;local s=EavesDrop:GetCaptureState();assert(s.count==1000 and not s.active and s.reason=='达到条数上限');assert(next(EavesDrop.captureFrame.events)==nil and EavesDrop.captureFrame.scripts.OnUpdate==nil)")

    def test_time_limit_stops_even_without_new_events(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');tick(120);local s=EavesDrop:GetCaptureState();assert(not s.active and s.count==1 and s.reason=='达到时间上限' and not EavesDrop.captureFrame.scripts.OnUpdate)")

    def test_event_at_deadline_is_not_recorded(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();current=120;fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');assert(#EavesDropCaptureDB.records==0 and not EavesDrop:GetCaptureState().active)")

    def test_manual_stop_retains_records_and_reason(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');EavesDrop:StopCapture('监视已停用');assert(#EavesDropCaptureDB.records==1);assert(not EavesDrop:StopCapture('other'));assert(EavesDrop:GetCaptureState().reason=='监视已停用')")

    def test_clear_and_new_round_are_explicit(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','SPELL_CAST','A');EavesDrop:StopCapture();EavesDrop:StartCapture();assert(#EavesDropCaptureDB.records==0);fire('COMBAT_TEXT_UPDATE','SPELL_CAST','B');EavesDrop:ClearCapture();assert(not EavesDrop:GetCaptureState().active and #EavesDropCaptureDB.records==0 and EavesDrop:GetCaptureState().reason=='已清除')")

    def test_partial_registration_failure_does_not_break_native_sampling(self):
        r = runtime("failEvent='SPELL_GO_OTHER'")
        r.execute("EavesDrop:StartCapture();assert(not EavesDrop.captureFrame.events.SPELL_GO_OTHER);fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');assert(#EavesDropCaptureDB.records==1 and string.find(EavesDrop:GetCaptureStatus(),'不可用'))")

    def test_no_extensions_falls_back_without_changing_global_cvars(self):
        r = runtime("GetNampowerVersion=nil;SUPERWOW_STRING=nil")
        r.execute("EavesDrop:StartCapture();assert(not EavesDrop.captureFrame.events.SPELL_GO_SELF and not EavesDrop.captureFrame.events.UNIT_CASTEVENT);fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');assert(#EavesDropCaptureDB.records==1)")

    def test_long_utf8_strings_are_bounded_and_valid(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','SPELL_CAST',string.rep('召唤迷失者',200))")
        value = r.eval("EavesDropCaptureDB.records[1].args[2]")
        self.assertLessEqual(len(value.encode("utf-8")), 384)
        self.assertTrue(value.endswith("..."))

    def test_tables_and_nonfinite_numbers_are_not_serialized(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','TEST',{secret='not saved'},0/0,math.huge,false,5);local a=EavesDropCaptureDB.records[1].args;assert(a[2]==nil and a[3]==nil and a[4]==nil and a[5]==false and a[6]==5 and a.n==9)")

    def test_logout_stops_without_logging_extra_event(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');fire('PLAYER_LOGOUT');assert(#EavesDropCaptureDB.records==1 and not EavesDrop:GetCaptureState().active and EavesDrop:GetCaptureState().reason=='退出游戏')")

    def test_ui_refresh_is_throttled_and_removed_on_stop(self):
        r = runtime()
        r.execute("EavesDrop:StartCapture();local initial=EavesDrop.refreshes;tick(.1);tick(.25);assert(EavesDrop.refreshes==initial);tick(1);assert(EavesDrop.refreshes==initial+1);EavesDrop:StopCapture();assert(not EavesDrop.captureFrame.scripts.OnUpdate)")

    def test_repeated_sessions_reuse_one_frame(self):
        r = runtime()
        r.execute("for i=1,5 do EavesDrop:StartCapture();fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');EavesDrop:StopCapture()end;local count=0;for k in pairs(frames)do count=count+1 end;assert(count==1)")

    def test_environment_snapshot_survives_stop_and_reload(self):
        r = runtime(r'''
          EavesDrop.db={profile={DATASOURCE='auto',PROCSOURCE='floating',privateSetting='never save'}}
          SUPERWOW_VERSION='1.5'
          cvarReads=0
          function GetCVar(name)
            cvarReads=cvarReads+1
            assert(name=='NP_EnableAutoAttackEvents' or name=='NP_EnableSpellHealEvents' or
              name=='NP_EnableSpellEnergizeEvents' or name=='enableCombatText')
            return name=='enableCombatText' and '1' or '0'
          end
        ''')
        r.execute(r'''
          EavesDrop:StartCapture()
          local env=EavesDropCaptureDB.environment
          assert(env.datasource=='auto' and env.procsource=='floating' and not env.privateSetting)
          assert(env.nampower.major==4 and env.nampower.minor==6 and env.nampower.patch==1)
          assert(env.superwow.version=='1.5' and env.superwow.description=='SuperWoW test')
          assert(env.cvars.enableCombatText=='1' and env.cvars.NP_EnableSpellHealEvents=='0')
          local saved=EavesDropCaptureDB.registered
          local contains={};for _,e in ipairs(saved)do contains[e]=true end
          assert(contains.COMBAT_TEXT_UPDATE and contains.SPELL_GO_SELF and contains.UNIT_CASTEVENT)
          tick(1);tick(2);assert(cvarReads==4,'environment collected per frame')
          EavesDrop.db.profile.DATASOURCE='legacy';EavesDrop:StopCapture()
          assert(env.datasource=='auto' and #saved>0 and next(EavesDrop.captureFrame.events)==nil)
          assert(EavesDropCaptureDB.environment==env and EavesDropCaptureDB.registered==saved)
        ''')
        r.execute(SOURCE.read_text(encoding="utf-8-sig"))
        r.execute("assert(not EavesDrop:GetCaptureState().active and EavesDropCaptureDB.environment.datasource=='auto' and #EavesDropCaptureDB.registered>0)")

    def test_environment_absent_interfaces_and_partial_registration_are_saved(self):
        r = runtime("GetNampowerVersion=nil;GetCVar=nil;SUPERWOW_STRING=nil;SUPERWOW_VERSION=nil;failEvent='COMBAT_TEXT_UPDATE'")
        r.execute(r'''
          assert(EavesDrop:StartCapture())
          local db=EavesDropCaptureDB
          assert(type(db.environment)=='table' and next(db.environment.cvars)==nil)
          assert(next(db.environment.nampower)==nil and next(db.environment.superwow)==nil)
          assert(db.environment.datasource==nil and db.environment.procsource==nil)
          local failed={};for _,e in ipairs(db.unavailable)do failed[e]=true end
          assert(failed.COMBAT_TEXT_UPDATE and failed['nampower 增强事件'] and failed['SuperWoW 施法事件'])
          for _,e in ipairs(db.registered)do assert(e~='COMBAT_TEXT_UPDATE' and e~='SPELL_GO_SELF')end
          EavesDrop:StopCapture();assert(#db.registered>0 and #db.unavailable==3)
        ''')

    def test_unregistered_extension_cvars_do_not_abort_vanilla_sampling(self):
        r = runtime("GetNampowerVersion=nil;function GetCVar(name) if name~='enableCombatText' then error('unknown CVar') end;return '1' end")
        r.execute("assert(EavesDrop:StartCapture());assert(EavesDropCaptureDB.environment.cvars.enableCombatText=='1');assert(EavesDropCaptureDB.environment.cvars.NP_EnableAutoAttackEvents==nil);fire('COMBAT_TEXT_UPDATE','SPELL_CAST','Test');assert(#EavesDropCaptureDB.records==1)")

    def test_environment_values_are_scalar_bounded_and_whitelisted(self):
        r = runtime(r'''
          EavesDrop.db={profile={DATASOURCE=string.rep('a',1000),PROCSOURCE={private='discard'}}}
          SUPERWOW_STRING=string.rep('迷失者',200)
          SUPERWOW_VERSION={private='discard'}
          function GetNampowerVersion()return string.rep('4',1000),0/0,math.huge end
          function GetCVar(name)
            if name=='NP_EnableSpellHealEvents'then return {private='discard'}end
            return string.rep('x',1000)
          end
        ''')
        r.execute(r'''
          EavesDrop:StartCapture()
          local env=EavesDropCaptureDB.environment
          assert(string.len(env.datasource)==384 and env.procsource==nil)
          assert(string.len(env.nampower.major)==384 and env.nampower.minor==nil and env.nampower.patch==nil)
          assert(env.superwow.version==nil and string.len(env.superwow.description)<=384)
          assert(env.cvars.NP_EnableSpellHealEvents==nil and string.len(env.cvars.enableCombatText)==384)
        ''')
        r.eval("EavesDropCaptureDB.environment.superwow.description").encode("utf-8")


if __name__ == "__main__":
    unittest.main(verbosity=2)
