"""Run actual resource-palette resolvers; no character files or game are read."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime


class ResourceColors(unittest.TestCase):
    def runtime(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
        C={unitframes={manacolor='.5,.5,1,1',ragecolor='1,.5,.5,1',
          energycolor='1,1,.5,1',focuscolor='1,.5,.25,1',player={defcolor='1'}},resourcebars={}}
        pfUI={api={},uf={player={config=C.unitframes.player,power={bar={}}}}}
        currentType=0
        function UnitPowerType() return currentType,'extra return' end
        function pfUI.uf.player.power.bar:GetStatusBarColor() return statusR,statusG,statusB,statusA end
        ''')
        api = (ROOT / 'Interface/AddOns/pfUI/api/api.lua').read_text(encoding='utf-8-sig')
        lua.execute(api[api.index('function pfUI.api.strsplit('):api.index('-- [ isempty ]')])
        lua.execute('local color_cache={}\n' + api[api.index('function pfUI.api.GetStringColor('):api.index('-- [ rgbhex ]')])
        return lua

    def test_default_palette_does_not_repeat_purple_avatar_theme(self):
        lua = self.runtime()
        for power, expected in [(0, (.271, .467, 1, 1)), (1, (1, 0, 0, 1)),
                                (2, (1, .5, .25, 1)), (3, (1, 1, 0, 1))]:
            self.assertEqual(lua.eval(f'pfUI.api.GetResourceBarColor({power})'), expected)
        lua.execute("assert(C.unitframes.manacolor=='.5,.5,1,1','avatar theme was rewritten')")

    def test_existing_and_imported_character_palettes_are_preserved(self):
        lua = self.runtime()
        lua.execute('ERB_options={erb_pp={powers={mana={.15,.45,.95,.8},rage={.9,.1,0},energy={1,.9,.05}}}}')
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.15, .45, .95, .8))
        lua.execute('C.resourcebars.data={erb_pp={powers={mana={.2,.55,.9,1}}}}')
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.2, .55, .9, 1))
        lua.execute('C.resourcebars.data.erb_pp.powers.mana={0,.6,1,0}')
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (0, .6, 1, 0))
        lua.execute('assert(ERB_options.erb_pp.powers.mana[1]==.15)')

    def test_avatar_option_reads_the_rendered_status_bar(self):
        lua = self.runtime()
        lua.execute("C.unitframes.comboenergycolorstyle='player';statusR=.18;statusG=.48;statusB=.92;statusA=.7")
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.18, .48, .92, .7))
        lua.execute('statusR=.22;statusG=.6;statusB=1;statusA=1')
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.22, .6, 1, 1))

    def test_avatar_other_power_and_missing_widget_use_correct_configuration(self):
        lua = self.runtime()
        lua.execute("C.unitframes.comboenergycolorstyle='player';currentType=3;statusR=1;statusG=1;statusB=0;statusA=1")
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.5, .5, 1, 1))
        lua.execute("pfUI.uf.player.config={defcolor='0',manacolor='.1,.5,.9,.8'}")
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.1, .5, .9, .8))
        lua.execute('pfUI.uf.player.power.bar.GetStatusBarColor=function() error("unavailable") end')
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.1, .5, .9, .8))
        lua.execute('pfUI.uf.player=nil')
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.5, .5, 1, 1))

    def test_bad_legacy_channels_and_unknown_types_fall_back(self):
        lua = self.runtime()
        lua.execute('ERB_options={erb_pp={powers={mana={-1,"invalid",0/0,5}}}}')
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(0)'), (.271, .467, 1, 1))
        self.assertEqual(lua.eval('pfUI.api.GetResourceBarColor(99)'), (.5, .5, .5, 1))

    def test_real_independent_bar_uses_selected_palette(self):
        from test_pfui_energybar import Harness
        h = Harness(enabled=True)
        h.update(comboenergycolorstyle='legacy')
        h.execute('ERB_options={erb_pp={powers={mana={.271,.467,1}}}}')
        h.advance(.1)
        self.assertEqual(tuple(h.fill().texture[i] for i in (1, 2, 3, 4)), (.271, .467, 1, 1))
        h.update(comboenergycolorstyle='player')
        h.advance(.1)
        self.assertEqual(tuple(h.fill().texture[i] for i in (1, 2, 3, 4)), (.5, .5, 1, 1))
        h.unchanged()

    def test_real_integrated_bar_uses_same_scheme_without_changing_old_settings(self):
        from test_pfui_resourcebars import Harness
        h = Harness()
        h.start()
        h.execute("C.unitframes.comboenergycolorstyle='legacy';C.resourcebars.data.erb_pp.powers.mana={.18,.55,.9,.8}")
        h.advance(.2)
        self.assertEqual(tuple(h.power.bar.color[i] for i in (1, 2, 3, 4)), (.18, .55, .9, .8))
        h.execute('assertLegacyUnchanged();otherFramesUnchanged()')


if __name__ == '__main__':
    unittest.main()
