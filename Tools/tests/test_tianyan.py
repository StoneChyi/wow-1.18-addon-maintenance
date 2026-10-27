"""Run the full addon with 1.12 events and strict font preconditions; no live game."""
from pathlib import Path
import unittest
import sys
import math
import subprocess
import json
import random

ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
ADDON=ROOT/'Interface/AddOns/TianYan'
MOCK=(ROOT/'Tools/tests/tianyan_mock.lua').read_text(encoding='utf-8')
FONT=(ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8')
G1='0xF140000000000011'; G2='0xF140000000000012'

def new(setup='', fail_font=False):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute(FONT)(lua.globals().MockMethods,lua.eval('''function(kind,name,parent)
        local f=MockObject(); f.kind=kind; table.insert(parent.fonts,f); return f end'''))
    if fail_font: lua.execute("failedFontPaths.font=true")
    lua.execute('TY_DB={history={OldSummon=7},shown=false,miniAngle=-1.2}')
    lua.execute(setup)
    lua.execute((ADDON/'Tracker.lua').read_text(encoding='utf-8'))
    lua.execute((ADDON/'TianYan.lua').read_text(encoding='utf-8'))
    lua.globals().Emit('VARIABLES_LOADED')
    return lua

def count(lua): return lua.globals().TianYanTracker.Totals()[0]
def start(lua): lua.execute("inCombat=true; Emit('PLAYER_REGEN_DISABLED')")
def stop(lua,extra=0):
    lua.execute(f"now=now+{extra}; inCombat=false; Emit('PLAYER_REGEN_ENABLED')")
    return lua.globals().TY_DB.lastCombat

class TianYanTests(unittest.TestCase):
    def test_no_mouse_no_plates(self):
        for event,args in [('UNIT_CASTEVENT',f"'{G1}',nil,'START'"),('SPELL_GO_OTHER',f"0,123,'{G1}'"),
                           ('SPELL_START_OTHER',f"0,123,'{G1}'"),('SPELL_DAMAGE_EVENT_OTHER',f"nil,'{G1}',123"),
                           ('AUTO_ATTACK_OTHER',f"'{G1}'")]:
            with self.subTest(event=event):
                lua=new(f"AddUnit('{G1}','迷失者',PLAYER)")
                self.assertEqual(count(lua),0)
                lua.execute(f"EmitArgs('{event}',{args})")
                self.assertEqual(count(lua),1)
                lua.execute('Tick(0.31,0)')
                self.assertTrue(lua.globals().HasText('天眼 (1)'))

    def test_duplicate_and_same_name(self):
        lua=new()
        lua.execute(f"u=AddUnit('{G1}','Tree',PLAYER,'target'); units.mouseover=u; units.nameplate1=u; Plate('Tree','TestPlayer的宠物','{G1}')")
        for event in ['UNIT_CASTEVENT','AUTO_ATTACK_OTHER','UNIT_COMBAT_GUID']:
            lua.execute(f"EmitArgs('{event}','{G1}')")
        lua.execute(f"AddUnit('{G2}','Tree',PLAYER); EmitArgs('UNIT_CASTEVENT','{G2}'); Tick(0.3,0)")
        self.assertEqual(count(lua),2)

    def test_exact_owner_and_other_owner(self):
        for owner,text,expected in [('OTHER','TestPlayer的宠物',0),('nil','TestPlayerExtra的宠物',0),
                                    ('nil','TestPlayer的宠物',1),('PLAYER','Other的宠物',1)]:
            lua=new(f"AddUnit('{G1}','Tree',{owner},'target',{text!r})")
            self.assertEqual(count(lua),expected)

    def test_owner_fields_and_authority(self):
        lua=new(f"u=AddUnit('{G1}','Tree',nil);u.summonedBy=PLAYER")
        lua.execute(f"EmitArgs('UNIT_CASTEVENT','{G1}')")
        self.assertEqual(count(lua),1)
        lua.execute(f"u.ownerGuid=OTHER; EmitArgs('UNIT_MODEL_CHANGED_GUID','{G1}')")
        self.assertEqual(count(lua),0)

    def test_created_by_fallback(self):
        lua=new(f"u=AddUnit('{G1}','Tree',nil);u.createdBy=PLAYER")
        lua.execute(f"EmitArgs('UNIT_CASTEVENT','{G1}')")
        self.assertEqual(count(lua),1)

    def test_late_object_retry(self):
        lua=new()
        lua.execute(f"EmitArgs('UNIT_CASTEVENT','{G1}'); AddUnit('{G1}','Tree',PLAYER); Tick(0.31,0)")
        self.assertEqual(count(lua),1)

    def test_late_owner_retry(self):
        lua=new(f"u=AddUnit('{G1}','Tree',nil,nil,'unknown')")
        lua.execute(f"EmitArgs('UNIT_CASTEVENT','{G1}'); u.ownerGuid=PLAYER; Tick(0.31,0)")
        self.assertEqual(count(lua),1)

    def test_retry_bound_and_expiry(self):
        lua=new()
        lua.execute("for i=1,200 do EmitArgs('UNIT_CASTEVENT',string.format('0xF140%012x',i)) end; Tick(3,0)")
        self.assertEqual(count(lua),0)
        self.assertLessEqual(lua.globals().TianYanTracker.Diagnostics()[0].retry,64)

    def test_death_immediate_average(self):
        lua=new();start(lua)
        lua.execute(f"now=now+2; AddUnit('{G1}','Tree',PLAYER); EmitArgs('UNIT_CASTEVENT','{G1}'); now=now+4; EmitArgs('UNIT_DIED','{G1}')")
        self.assertEqual(count(lua),0)
        result=stop(lua,4)
        self.assertAlmostEqual(result.average,0.4)
        self.assertEqual(result.duration,10)

    def test_events_update_hidden_history(self):
        lua=new(); start(lua)
        lua.execute(f"AddUnit('{G1}','Tree',PLAYER); EmitArgs('UNIT_CASTEVENT','{G1}'); AddUnit('{G2}','Tree',PLAYER); EmitArgs('UNIT_CASTEVENT','{G2}'); now=now+1; EmitArgs('UNIT_DIED','{G2}')")
        self.assertEqual(lua.globals().TY_DB.history.Tree,2)
        self.assertFalse(lua.globals().TYBar.IsShown(lua.globals().TYBar))

    def test_long_life_without_plate(self):
        lua=new(f"AddUnit('{G1}','Tree',PLAYER)")
        lua.execute(f"EmitArgs('UNIT_CASTEVENT','{G1}'); Tick(120,0)")
        self.assertEqual(count(lua),1)

    def test_missing_object_estimate(self):
        lua=new(f"AddUnit('{G1}','Tree',PLAYER,'target')")
        lua.execute(f"RemoveUnit('{G1}'); Tick(0.31,0)")
        self.assertEqual(lua.globals().TianYanTracker.Totals()[2],1)
        lua.execute('Tick(1,0)')
        self.assertEqual(count(lua),0)

    def test_unknown_owner_not_foreign(self):
        lua=new(f"u=AddUnit('{G1}','Tree',PLAYER,'target','unknown')")
        lua.execute('u.ownerGuid=nil; Tick(3,0)')
        self.assertEqual(count(lua),1)
        lua.execute('Tick(1,0)')
        self.assertEqual(count(lua),0)

    def test_hostile_dead_player_excluded(self):
        for field in ['hostile','dead','player']:
            lua=new(f"u=AddUnit('{G1}','Tree',PLAYER); u.{field}=true")
            lua.execute(f"EmitArgs('UNIT_CASTEVENT','{G1}')")
            self.assertEqual(count(lua),0)
        lua=new(f"AddUnit('{G1}','疲倦的骡子',PLAYER,'target')")
        self.assertEqual(count(lua),0)

    def test_plate_fallback_promotion_reuse(self):
        lua=new(f"p=Plate('Tree','TestPlayer的宠物','{G1}')")
        self.assertEqual(count(lua),1)
        self.assertEqual(lua.globals().TianYanTracker.Totals()[2],1)
        lua.execute(f"AddUnit('{G1}','Tree',PLAYER); EmitArgs('UNIT_CASTEVENT','{G1}')")
        self.assertEqual(count(lua),1)
        lua.execute("p.guid=nil;p.ownerText='Other的宠物';Tick(0.31,0)")
        self.assertEqual(count(lua),1)

    def test_different_owner_plate_never_counts(self):
        lua=new(f"AddUnit('{G1}','Tree',OTHER);p=Plate('Tree','TestPlayer的宠物','{G1}')")
        self.assertEqual(count(lua),0)

    def test_temp_death(self):
        lua=new(f"p=Plate('Tree','TestPlayer的宠物','{G1}')")
        lua.execute(f"EmitArgs('UNIT_DIED','{G1}')")
        self.assertEqual(count(lua),0)

    def test_two_plates_one_unresolved_guid(self):
        lua=new(f"Plate('Tree','TestPlayer的宠物','{G1}'); Plate('Tree','TestPlayer的宠物','{G1}')")
        self.assertEqual(count(lua),1)

    def test_actual_capture_routing(self):
        rows=json.loads((ROOT/'Tools/tests/tianyan_lost_fixture.json').read_text(encoding='utf-8'))['rows']
        lua=new(); start(lua); seen=set()
        for row in rows:
            lua.globals().now=100+row['time']
            for guid in row['owned']:
                seen.add(guid)
                lua.execute(f"AddUnit('{guid}','迷失者',PLAYER)")
            lua.globals().EmitArgs(row['event'],*row['args'])
            self.assertEqual(count(lua),len(seen),row)
        self.assertEqual(count(lua),3)
        self.assertEqual(lua.globals().TY_DB.history['迷失者'],3)

    def test_lifespan_oracle(self):
        for seed in range(20):
            lua=new();start(lua);rng=random.Random(seed)
            alive=[]; area=0; elapsed=0
            for i in range(30):
                delay=rng.choice([0,0.05,0.4,1.7]);area+=len(alive)*delay;elapsed+=delay
                lua.execute(f'now=now+{delay}')
                if alive and rng.random()<0.45:
                    guid=alive.pop(rng.randrange(len(alive)))
                    lua.execute(f"EmitArgs('UNIT_DIED','{guid}'); RemoveUnit('{guid}')")
                else:
                    guid='0xF140'+format(i+1,'012X');alive.append(guid)
                    lua.execute(f"AddUnit('{guid}','Tree',PLAYER); EmitArgs('UNIT_CASTEVENT','{guid}')")
            area+=len(alive)*2;elapsed+=2
            result=stop(lua,2)
            self.assertAlmostEqual(result.average,area/elapsed)
            self.assertAlmostEqual(result.duration,elapsed)

    def test_debug_and_world_transition(self):
        lua=new(f"AddUnit('{G1}','Tree',PLAYER,'target')")
        lua.globals().SlashCmdList.TYDEBUG('')
        self.assertTrue(any('UNIT_CASTEVENT' in str(m) for m in lua.globals().messages.values()))
        lua.execute("units={}; Emit('PLAYER_ENTERING_WORLD')")
        self.assertEqual(count(lua),0)

    def test_partial_and_zero(self):
        lua=new('inCombat=true');result=stop(lua,5)
        self.assertTrue(result.partial);self.assertEqual(result.average,0)
        start(lua);result=stop(lua)
        self.assertEqual(result.average,0)

    def test_button_saved_mean_and_fonts(self):
        for fail in [False,True]:
            lua=new(f"AddUnit('{G1}','Tree',PLAYER,'target')",fail_font=fail)
            start(lua);stop(lua,10)
            lua.globals().TYResetHistoryButton.scripts.OnClick()
            self.assertIsNone(lua.globals().TY_DB.history.OldSummon)
            self.assertEqual(lua.globals().TY_DB.lastCombat.average,1)
            self.assertEqual(lua.globals().TYBar.width,220)
            self.assertEqual(lua.globals().TY_DB.miniAngle,-1.2)
            lua.execute("TYMiniBtn.scripts.OnDragStart(); Tick(.01,0); TYMiniBtn.scripts.OnDragStop()")

    def test_missing_extensions(self):
        lua=new('GetUnitGUID=nil;UnitGUID=nil;GetUnitField=nil;GetNampowerVersion=nil')
        start(lua);result=stop(lua,3)
        self.assertEqual(result.average,0)

    def test_null_primary_guid_falls_back(self):
        lua=new(f"u=AddUnit('{G1}','Tree',PLAYER,'target'); UnitGUID=GetUnitGUID; GetUnitGUID=function() return '0x0000000000000000' end")
        self.assertEqual(count(lua),1)

    def test_old_fields_not_called(self):
        lua=new(f"GetNampowerVersion=function() return 2,20,0 end;GetUnitField=function() error('unsupported') end;AddUnit('{G1}','Tree',nil,'target')")
        self.assertEqual(count(lua),1)

    def test_saved_mean_reload(self):
        lua=new(f"AddUnit('{G1}','Tree',PLAYER,'target')");start(lua);stop(lua,5)
        saved=lua.globals().Snapshot(lua.globals().TY_DB)
        other=new();other.execute('TY_DB='+saved);other.execute('Tick(1,0)')
        self.assertEqual(other.globals().TY_DB.lastCombat.average,1)
        self.assertEqual(other.globals().TY_DB.history.OldSummon,7)

    def test_registration_isolation(self):
        lua=new("unavailableEvents={SPELL_GO_OTHER=true,UNIT_COMBAT_GUID=true}")
        regs=lua.globals().TianYanTracker.Diagnostics()[2]
        self.assertFalse(regs.SPELL_GO_OTHER);self.assertTrue(regs.UNIT_CASTEVENT)

    def test_bad_ids_and_self_cast_not_a_summon(self):
        lua=new()
        lua.execute("EmitArgs('UNIT_CASTEVENT','0x0000000000000000'); EmitArgs('UNIT_CASTEVENT',PLAYER); EmitArgs('UNIT_CASTEVENT','bad');EmitArgs('SPELL_GO_SELF',0,123,PLAYER)")
        self.assertEqual(count(lua),0)

    def test_lua50_and_line_endings(self):
        compiler=ROOT/'PluginHistory/staging/lua503-validation/win64/luac50.exe'
        for name in ['Tracker.lua','TianYan.lua']:
            p=ADDON/name
            result=subprocess.run([str(compiler),'-p',str(p)],cwd=compiler.parent,capture_output=True)
            self.assertEqual(result.returncode,0,result.stderr)
            raw=p.read_bytes();self.assertEqual(raw.count(b'\n'),raw.count(b'\r\n'))

if __name__=='__main__': unittest.main()
