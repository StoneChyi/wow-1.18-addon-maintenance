"""Run the actual personal tick model and its read-only standalone display API."""
from pathlib import Path
import hashlib
import re
import sys
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

SOURCE = ROOT / 'Interface/AddOns/pfUI/modules/energytick.lua'
MOCK = r'''
now, power, amount, maximum, rank, agility, class = 0, 3, 0, 100, 0, 200, 'ROGUE'
C = {unitframes={player={energy='1',manatick='1',pheight=10,pwidth='200',width='200'}}}
local methods = {}
function methods:SetAllPoints() end
function methods:SetTexture() end
function methods:SetHeight(v) self.h=v end
function methods:SetWidth(v) self.w=v end
function methods:SetBlendMode() end
function methods:SetAlpha(v) self.alpha=v end
function methods:SetPoint(_, x, y) self.x=x;self.y=y end
function methods:Show() self.shown=true end
function methods:Hide() self.shown=false end
function methods:RegisterEvent(e) self.events[e]=true end
function methods:SetScript(k,fn) self.scripts[k]=fn end
function methods:CreateTexture() return CreateFrame() end
function CreateFrame()
 return setmetatable({shown=true,events={},scripts={}}, {__index=methods})
end
pfUI={uf={player={power={bar=CreateFrame()},UpdateConfig=function() end}}}
function pfUI:RegisterModule(name,versions,fn) assert(name=='energytick');fn() end
function UnitPowerType() return power, 'EXTRA_RETURN' end
function UnitMana() return amount end
function UnitManaMax() return maximum end
function UnitClass() return 'Localized class', class end
function UnitStat() return agility, agility+100, 100, 0 end
function GetTalentInfo() return '',0,0,0,rank end
function GetTime() return now end
function fire(e, value, timestamp, unit)
 if value~=nil then amount=value end
 if timestamp~=nil then now=timestamp end
 event=e; arg1=unit or 'player';this=pfUI.energytick
 this.scripts.OnEvent()
end
function update(timestamp)
 now=timestamp;this=pfUI.energytick
 if this.shown then this.scripts.OnUpdate() end
end
'''


class SharedTickTests(unittest.TestCase):
    def runtime(self, setup=''):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK)
        lua.execute(setup)
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute("fire('PLAYER_ENTERING_WORLD', amount, 0)")
        return lua

    def test_personal_calibrator_is_byte_identical(self):
        prefix = SOURCE.read_bytes().split(b'pfUI:RegisterModule("energytick"', 1)[0]
        self.assertEqual(hashlib.sha256(prefix).hexdigest(),
                         'b67a2d76e718f114ce8decf1720bce2930abb0329a2e32f8620602f020aa2ad3')

    def test_no_anchor_and_other_resources_have_no_phase(self):
        lua = self.runtime()
        lua.execute('assert(pfUI.energytick:EnergyProgress()==nil)')
        lua.execute("fire('UNIT_ENERGY',20,1);now=1.5;assert(pfUI.energytick:EnergyProgress()==.25)")
        lua.execute('power=0;assert(pfUI.energytick:EnergyProgress()==nil)')
        lua.execute('power=1;assert(pfUI.energytick:EnergyProgress()==nil)')

    def test_phase_zero_and_getter_does_not_move_anchor(self):
        lua = self.runtime()
        lua.execute("fire('UNIT_ENERGY',20,1);assert(pfUI.energytick:EnergyProgress()==0)")
        lua.execute('now=2;assert(pfUI.energytick:EnergyProgress()==.5)')
        lua.execute('now=3;assert(pfUI.energytick:EnergyProgress()==0);assert(pfUI.energytick.anchorMS==1000)')

    def test_avatar_spark_disabled_still_shares_calibration(self):
        lua = self.runtime("C.unitframes.player.energy='0'")
        lua.execute("fire('UNIT_ENERGY',20,1);fire('UNIT_ENERGY',40,3);now=3.5")
        lua.execute('assert(not pfUI.energytick.shown);assert(pfUI.energytick:EnergyProgress()==.25)')

    def test_instant_energy_and_full_cap_do_not_shift_phase(self):
        lua = self.runtime()
        lua.execute("fire('UNIT_ENERGY',20,1);fire('UNIT_ENERGY',40,3);fire('UNIT_ENERGY',80,3.4)")
        lua.execute('assert(pfUI.energytick.anchorMS==3000)')
        lua.execute("fire('UNIT_ENERGY',95,5);fire('UNIT_ENERGY',100,7)")
        lua.execute('assert(pfUI.energytick.anchorMS==5000)')
        lua.execute("fire('UNIT_ENERGY',80,8);fire('UNIT_ENERGY',100,11)")
        lua.execute('assert(pfUI.energytick.anchorMS==11000);assert(pfUI.energytick.energyTickMS==2000)')

    def test_stats_and_talent_model_remains_class_specific(self):
        lua = self.runtime('rank=2')
        lua.execute('assert(pfUI.energytick.energyTickMS==1760)')
        lua.execute("agility=300;fire('UNIT_STATS',nil,1);assert(pfUI.energytick.energyTickMS==1640)")
        cat = self.runtime("class='DRUID';rank=5")
        cat.execute('assert(pfUI.energytick.energyTickMS==2000)')

    def test_existing_mana_five_second_visual_cycle(self):
        lua = self.runtime('power=0;amount=80')
        lua.execute("fire('UNIT_MANA',60,1);update(1);assert(pfUI.energytick.max==5)")
        lua.execute('update(3);assert(pfUI.energytick.max==5);assert(pfUI.energytick.spark.x==72.5)')
        lua.execute('update(6.1);assert(pfUI.energytick.max==2)')
        lua.execute("fire('UNIT_MANA',100,7);assert(not pfUI.energytick.shown);assert(pfUI.energytick:EnergyProgress()==nil)")

    def test_provider_absent_when_avatar_module_is_unavailable(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(MOCK)
        lua.execute('pfUI.uf=nil')
        lua.execute(SOURCE.read_text(encoding='utf-8'))
        lua.execute('assert(pfUI.energytick==nil)')


class IntegrationTests(unittest.TestCase):
    def test_configuration_preserves_existing_values_and_defaults_off(self):
        source = (ROOT / 'Interface/AddOns/pfUI/api/config.lua').read_text(encoding='utf-8')
        begin = source.index('  -- Independent resource display:')
        block = source[begin:source.index('  -- Nampower Settings', begin)]
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
        C={unitframes={comboenergywidth='333'},resourcebars={}};pfUI={}
        function pfUI:UpdateConfig(section, subsection, key, value)
          assert((section=='unitframes' or section=='resourcebars') and subsection==nil)
          if section=='unitframes' then assert(string.find(key, '^comboenergy')) end
          if C[section][key]==nil then C[section][key]=value end
        end
        ''')
        lua.execute(block)
        lua.execute("assert(C.unitframes.comboenergyshow=='0');assert(C.unitframes.comboenergywidth=='333')")
        lua.execute("assert(C.resourcebars.enable=='0' and C.resourcebars.followcolors=='1')")
        lua.execute('assert(C.unitframes.bottomalign==nil and C.unitframes.comboenergyshift==nil)')

    def test_actual_settings_page_uses_complete_defaults_and_module_updater(self):
        gui = (ROOT / 'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf-8')
        begin = gui.index('    CreateGUIEntry(T["Unit Frames"], T["Independent Resource Bar"]')
        page = gui[begin:gui.index('\n    end)', begin)+len('\n    end)')]
        config = (ROOT / 'Interface/AddOns/pfUI/api/config.lua').read_text(encoding='utf-8')
        defaults = set(re.findall(r'UpdateConfig\("unitframes", nil,\s*"(comboenergy\w+)"', config))
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
        T=setmetatable({}, {__index=function(_,k) return k end})
        updates=0;C={unitframes={}};fields={}
        function refresh() updates=updates+1 end
        U={energybar=refresh};pfUI={gui={dropdowns={combo_texture={},comboenergy_format={},comboenergy_align={},resourcebar_colors={}}}}
        function CreateGUIEntry(parent,title,callback)
          assert(parent=='Unit Frames' and title=='Independent Resource Bar');callback()
        end
        function CreateConfig(updater,title,config,key,kind,options)
          if kind=='header' then return end
          assert(updater==refresh and config==C.unitframes and fields[key]==nil)
          if kind=='dropdown' then assert(type(options)=='table') end
          fields[key]=true;updater()
        end
        ''')
        lua.execute(page)
        fields = set(lua.globals().fields.keys())
        self.assertEqual(fields, defaults)
        self.assertEqual(lua.globals().updates, len(defaults))

    def test_single_load_entry_after_shared_provider(self):
        paths = [node.attrib.get('file', '').replace('\\', '/') for node in
                 ET.parse(ROOT / 'Interface/AddOns/pfUI/init/modules.xml').getroot()]
        self.assertEqual(paths.count('../modules/energybar.lua'), 1)
        self.assertGreater(paths.index('../modules/energybar.lua'), paths.index('../modules/energytick.lua'))

    def test_legacy_trial_page_calls_the_correct_actions_and_is_loaded_once(self):
        source = (ROOT / 'Interface/AddOns/pfUI/modules/gui.lua').read_text(encoding='utf-8')
        begin = source.index('    CreateGUIEntry(T["Unit Frames"], T["Health and Resource Bars"]')
        page = source[begin:source.index('\n    end)', begin)+len('\n    end)')]
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute('''
        T=setmetatable({}, {__index=function(_,k) return k end})
        C={resourcebars={enable='0',followcolors='1'}};calls={};fields={}
        pfUI={resourcebars={}}
        for _,key in ipairs({'ImportLegacy','OpenConfig','StopTrial'}) do
          pfUI.resourcebars[key]=function() calls[key]=(calls[key] or 0)+1 end
        end
        U={resourcebars=function() calls.config=(calls.config or 0)+1 end}
        function CreateGUIEntry(parent,title,fn)
          assert(parent=='Unit Frames' and title=='Health and Resource Bars');fn()
        end
        function CreateConfig(updater,title,config,key,kind,action)
          assert(config==C.resourcebars)
          if kind=='button' then action()
          else assert(kind=='checkbox' and updater==U.resourcebars);fields[key]=true;updater() end
        end
        ''')
        lua.execute(page)
        lua.execute('assert(calls.ImportLegacy==1 and calls.OpenConfig==1 and calls.StopTrial==1 and calls.config==2)')
        self.assertEqual(set(lua.globals().fields.keys()), {'enable', 'followcolors'})
        paths = [node.attrib.get('file', '').replace('\\', '/') for node in
                 ET.parse(ROOT / 'Interface/AddOns/pfUI/init/modules.xml').getroot()]
        for name in ('resourcebars.lua', 'resourcebars_gui.lua'):
            self.assertEqual(paths.count('../modules/' + name), 1)
        self.assertLess(paths.index('../modules/resourcebars.lua'), paths.index('../modules/resourcebars_gui.lua'))


if __name__ == '__main__':
    unittest.main()
