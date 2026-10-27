"""Offline Lua 5.1 tests for EavesDrop's exact-match icon resolver.

Exercises the real icons.lua. No game, native DLL, account data or network.
Lua 5.0 compilation is checked separately by test_eavesdrop_lua50.py.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

SOURCE = ROOT / "Interface/AddOns/EavesDrop/icons.lua"
STUB = r'''
EavesDrop={}; calls={native=0,icon=0,book=0,babble=0,extra=0}
local B={icons={}}
function B:GetSpellIcon(name) calls.babble=calls.babble+1;return self.icons[name]end
function AceLibrary(name) assert(name=='Babble-Spell-2.2');return B end
BS=B
function GetLocale() return 'zhCN' end
'''


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(STUB)
    lua.execute(SOURCE.read_text(encoding="utf-8-sig"))
    return lua


class IconResolverTests(unittest.TestCase):
    def test_explicit_texture_has_priority_and_preserves_custom_paths(self):
        r = runtime()
        r.execute(r'''
          function GetSpellRecField()error('explicit texture should win')end
          function GetSpellIconTexture()error('explicit texture should win')end
          assert(EavesDrop:ResolveSpellIcon('Example','Interface\\Custom\\Spell',99,false)=='Interface\\Custom\\Spell')
          assert(EavesDrop:ResolveSpellIcon('Example','ShortIcon',nil,false)=='Interface\\Icons\\ShortIcon')
          assert(EavesDrop:ResolveSpellIcon(nil,'pet',nil,false)=='pet')
        ''')

    def test_spell_id_is_translated_to_icon_id_before_texture_lookup(self):
        r = runtime()
        r.execute(r'''
          BS.icons.Example='Interface\\Icons\\Old'
          function GetSpellRecField(id,key)
            calls.native=calls.native+1;assert(id==125 and key=='spellIconID');return 17
          end
          function GetSpellIconTexture(id)calls.icon=calls.icon+1;assert(id==17);return 'Native17'end
          assert(EavesDrop:ResolveSpellIcon('Example',nil,125,false)=='Interface\\Icons\\Native17')
          assert(calls.native==1 and calls.icon==1 and calls.babble==0)
        ''')

    def test_native_missing_icon_falls_through_to_spellinfo(self):
        r = runtime()
        r.execute(r'''
          function GetSpellRecField()return 4 end
          function GetSpellIconTexture()return nil end
          function SpellInfo(id) assert(id==100);return 'Example','Rank 1','Interface\\Icons\\FromSpellInfo'end
          assert(EavesDrop:ResolveSpellIcon('Example',nil,100,false)=='Interface\\Icons\\FromSpellInfo')
        ''')

    def test_babble_precedes_optional_databases(self):
        r = runtime()
        r.execute(r'''
          BS.icons.Example='Interface\\Icons\\Babble'
          DPSMateX={BabbleSpellX={GetSpellIcon=function()error('Babble should win')end}}
          assert(EavesDrop:ResolveSpellIcon('Example',nil,nil,false)=='Interface\\Icons\\Babble')
        ''')

    def test_exact_static_dpsmatex_lookup_not_dynamic_global(self):
        r = runtime()
        r.execute(r'''
          DPSMateX={BabbleSpellX={GetSpellIcon=function(self,name)
            calls.extra=calls.extra+1;if name=='New Aura' then return 'Interface\\Icons\\Exact' end
          end}}
          DPSMateXSpellIcons={['New Aura']='WrongDynamic',['New Aura Extra']='WrongDynamic'}
          assert(EavesDrop:ResolveSpellIcon('New Aura',nil,nil,false)=='Interface\\Icons\\Exact')
          assert(EavesDrop:ResolveSpellIcon('New Aura Extra',nil,nil,false)==nil)
        ''')

    def test_pfui_locale_icon_table_and_missing_locale(self):
        r = runtime()
        r.execute(r'''
          pfUI_locale={zhCN={icons={['Some Debuff']='ShortDebuff'}}}
          assert(EavesDrop:ResolveSpellIcon('Some Debuff',nil,nil,false)=='Interface\\Icons\\ShortDebuff')
          assert(EavesDrop:ResolveSpellIcon('Some Debuff 2',nil,nil,false)==nil)
          GetLocale=function()return 'missing' end
          assert(EavesDrop:ResolveSpellIcon('Some Debuff',nil,nil,false)==nil)
        ''')

    def test_book_lookup_uses_its_valid_id_and_real_icon_id(self):
        r = runtime()
        r.execute(r'''
          function GetSpellIdForName(name)calls.book=calls.book+1;assert(name=='Book spell');return 122 end
          function GetSpellRecField(id,key)assert(id==122 and key=='spellIconID');return 44 end
          function GetSpellIconTexture(id)assert(id==44);return 'BookIcon' end
          assert(EavesDrop:ResolveSpellIcon('Book spell',nil,nil,false)=='Interface\\Icons\\BookIcon')
          assert(calls.book==1)
        ''')

    def test_zero_invalid_and_nonfinite_ids_never_reach_native_icon_api(self):
        r = runtime()
        r.execute(r'''
          function GetSpellIdForName()return 0 end
          function GetSpellRecField()error('invalid id')end
          function GetSpellIconTexture()error('invalid id')end
          for _,v in ipairs({0,-1,3.5,math.huge,0/0,4294967296,'123'}) do
            assert(EavesDrop:ResolveSpellIcon('Missing',nil,v,false)==nil)
          end
        ''')

    def test_empty_prefix_and_questionmark_do_not_block_fallback(self):
        r = runtime()
        r.execute(r'''
          BS.icons.Bad='Interface\\Icons\\'
          DPSMateX={BabbleSpellX={GetSpellIcon=function()return 'Interface\\Icons\\Better'end}}
          for _,v in ipairs({'','  ','Interface\\Icons\\','Interface/Icons/',
             'INV_Misc_QuestionMark','Interface\\Icons\\INV_Misc_QuestionMark.blp'})do
            assert(EavesDrop:ResolveSpellIcon('Bad',v,nil,false)=='Interface\\Icons\\Better')
          end
        ''')

    def test_placeholder_respects_setting(self):
        r = runtime()
        r.execute(r'''
          assert(EavesDrop:ResolveSpellIcon('Unknown','Interface\\Icons\\INV_Misc_QuestionMark',nil,false)==nil)
          assert(EavesDrop:ResolveSpellIcon('Unknown',nil,nil,true)=='Interface\\Icons\\INV_Misc_QuestionMark')
          assert(EavesDrop:ResolveSpellIcon(nil,nil,nil,false)==nil)
          assert(EavesDrop:ResolveSpellIcon(nil,nil,nil,true)==nil)
          assert(EavesDrop:ResolveSpellIcon(102,nil,nil,true)==nil)
          assert(EavesDrop:ResolveSpellIcon('   ',nil,nil,true)==nil)
          assert(EavesDrop:ResolveSpellIcon(nil,nil,42,true)=='Interface\\Icons\\INV_Misc_QuestionMark')
        ''')

    def test_late_loaded_provider_and_later_learned_spell_are_not_negatively_cached(self):
        r = runtime()
        r.execute(r'''
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)==nil)
          DPSMateX={BabbleSpellX={GetSpellIcon=function(self,name)
            if name=='Learned' then return 'Interface\\Icons\\Late'end
          end}}
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)=='Interface\\Icons\\Late')
          DPSMateX=nil;local id=0
          function GetSpellIdForName()return id end
          function GetSpellRecField()return 6 end
          function GetSpellIconTexture()return 'LearnedSpell'end
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)==nil)
          id=4
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)=='Interface\\Icons\\LearnedSpell')
        ''')

    def test_optional_providers_are_not_required(self):
        r = runtime()
        r.execute(r'''
          BS.icons.Existing='Interface\\Icons\\Existing'
          assert(EavesDrop:ResolveSpellIcon('Existing',nil,nil,false)=='Interface\\Icons\\Existing')
          assert(EavesDrop:ResolveSpellIcon('Unknown',nil,nil,false)==nil)
        ''')

    def test_book_miss_cache_expires_and_other_provider_loads_immediately(self):
        r = runtime()
        r.execute(r'''
          tick=100;local id=0
          function GetTime()return tick end
          function GetSpellIdForName()calls.book=calls.book+1;return id end
          function GetSpellRecField()return 6 end
          function GetSpellIconTexture()return 'LearnedSpell'end
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)==nil)
          id=4;tick=100.5
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)==nil and calls.book==1)
          DPSMateX={BabbleSpellX={GetSpellIcon=function(self,name)
            if name=='Learned' then return 'LateProvider'end
          end}}
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)=='Interface\\Icons\\LateProvider')
          DPSMateX=nil;tick=101
          assert(EavesDrop:ResolveSpellIcon('Learned',nil,nil,false)=='Interface\\Icons\\LearnedSpell')
          assert(calls.book==2)
        ''')

    def test_book_miss_cache_capacity_is_bounded(self):
        r = runtime()
        r.execute(r'''
          function GetTime()return 100 end
          function GetSpellIdForName()calls.book=calls.book+1;return 0 end
          for i=1,129 do EavesDrop:ResolveSpellIcon('Missing'..i,nil,nil,false)end
          assert(calls.book==129)
          EavesDrop:ResolveSpellIcon('Missing129',nil,nil,false);assert(calls.book==129)
          EavesDrop:ResolveSpellIcon('Missing1',nil,nil,false);assert(calls.book==130)
        ''')

    def test_missing_clock_queries_book_directly(self):
        r = runtime()
        r.execute(r'''
          function GetSpellIdForName()calls.book=calls.book+1;return 0 end
          EavesDrop:ResolveSpellIcon('Unknown',nil,nil,false)
          EavesDrop:ResolveSpellIcon('Unknown',nil,nil,false)
          assert(calls.book==2)
        ''')


if __name__ == '__main__':
    unittest.main(verbosity=2)
