"""Run the real standalone ERB and pfUI integration with strict WoW 1.12 UI mocks.

Fixtures are synthetic; no character settings or WTF files are read. Passing
these checks does not constitute acceptance of the actual game renderer.
"""
import argparse
from pathlib import Path
import sys
import unittest

from test_pfui_energybar import MOCK, ROOT, DEFAULTS

sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime, LuaError

parser = argparse.ArgumentParser()
parser.add_argument("--addons", type=Path, default=ROOT / "Interface/AddOns")
ARGS, REMAINING = parser.parse_known_args()

EXTENSIONS = r'''
health=750;healthMax=1000;shift=false;loadedAddons={};disabledAddons=0
reads.health=0;reads.healthmax=0;legacyEventCalls=0;legacyUpdateCalls=0
function UnitHealth() reads.health=reads.health+1;return health end
function UnitHealthMax() reads.healthmax=reads.healthmax+1;return healthMax end
function IsShiftKeyDown() return shift end
function GetShapeshiftFormInfo() return nil end
function IsAddOnLoaded(name) return loadedAddons[name] end
function DisableAddOn() disabledAddons=disabledAddons+1;error('standalone must remain enabled until game acceptance') end
function ReloadUI() reloads=(reloads or 0)+1 end
function methods:SetUserPlaced(value) self.userPlaced=value end
function methods:StartMoving() self.moving=true;self.calls.startmoving=(self.calls.startmoving or 0)+1 end
function methods:StopMovingOrSizing() self.moving=false;self.calls.stopmoving=(self.calls.stopmoving or 0)+1 end
function methods:SetAutoFocus(value) self.autofocus=value end
function methods:SetMaxLetters(value) self.maxletters=value end
function methods:SetTextInsets(...) self.textInsets={...} end
function methods:SetMultiLine(value) self.multiline=value end
function methods:SetNumeric(value) self.numeric=value end
function methods:ClearFocus() self.focus=false end
function methods:SetFocus() self.focus=true end
function methods:SetChecked(value) self.checked=value end
function methods:GetChecked() return self.checked end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:SetHitRectInsets(...) self.hitrect={...} end
function methods:SetNormalFontObject(font) self.normalFont=font end
function methods:SetHighlightFontObject(font) self.highlightFont=font end
function methods:SetDisabledFontObject(font) self.disabledFont=font end
function methods:SetScrollChild(child) self.scrollchild=child end
function methods:SetVerticalScroll(value) self.scroll=value end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:GetVerticalScrollRange() return 0 end
function methods:SetOwner(owner,anchor) self.owner=owner;self.ownerAnchor=anchor end
function methods:SetColorRGB(r,g,b) self.rgb={r,g,b} end
function methods:GetColorRGB() return unpack(self.rgb or {1,1,1}) end
function methods:GetValue() return self.value or 1 end
local oldEnableMouse=methods.EnableMouse
function methods:EnableMouse(value) oldEnableMouse(self,value~=false) end
local oldSetScript=methods.SetScript
function methods:SetScript(key,callback)
  if key=='OnEnter' or key=='OnLeave' or key=='OnClick' or key=='OnEnterPressed'
    or key=='OnEscapePressed' or key=='OnTextChanged' or key=='OnEditFocusLost'
    or key=='OnMouseWheel' or key=='OnVerticalScroll' then
    self.scripts[key]=callback
  else oldSetScript(self,key,callback) end
end
local anchorFactors={CENTER={.5,.5},LEFT={0,.5},RIGHT={1,.5},TOP={.5,1},BOTTOM={.5,0},
  TOPLEFT={0,1},TOPRIGHT={1,1},BOTTOMLEFT={0,0},BOTTOMRIGHT={1,0}}
function methods:GetCenter()
  if self==UIParent then return self.width/2,self.height/2 end
  if self.screenCenter then return self.screenCenter[1],self.screenCenter[2] end
  local point=self.points[1]
  if not point then return nil end
  local relative=point[2] or self.parent or UIParent
  assert(relative~=self,'self anchor')
  local rx,ry=relative:GetCenter();if not rx then return nil end
  local af=assert(anchorFactors[point[1]],'anchor');local rf=assert(anchorFactors[point[3] or point[1]],'relative anchor')
  return rx+(rf[1]-.5)*relative:GetWidth()+point[4]-(af[1]-.5)*self.width,
    ry+(rf[2]-.5)*relative:GetHeight()+point[5]-(af[2]-.5)*self.height
end
function methods:GetLeft() local x=self:GetCenter();return x and x-self.width/2 end
function methods:GetRight() local x=self:GetCenter();return x and x+self.width/2 end
function methods:GetTop() local _,y=self:GetCenter();return y and y+self.height/2 end
function methods:GetBottom() local _,y=self:GetCenter();return y and y-self.height/2 end
GameTooltip=object('Frame','GameTooltip',UIParent)
ColorPickerFrame=object('Frame','ColorPickerFrame',UIParent)
OpacitySliderFrame=object('Slider','OpacitySliderFrame',UIParent)
pfUI.api={};pfUI.movables={};pfUI_config=C;C.global={offscreen='0'}
C.resourcebars={enable='0',followcolors='1'}
local nativeCreateFrame=CreateFrame
function CreateFrame(kind,name,parent,template)
  local frame=nativeCreateFrame(kind,name,parent,template)
  if template=='InputBoxTemplate' then frame:SetFontObject(GameFontNormalSmall) end
  if template=='OptionsCheckButtonTemplate' and name then
    frame.label=frame:CreateFontString(name..'Text','OVERLAY','GameFontNormalSmall')
  end
  if template=='UIPanelCloseButton' then frame:SetScript('OnClick',function() this:GetParent():Hide() end) end
  return frame
end
local strictSetText=methods.SetText
function methods:SetText(value)
  assert(self.kind~='EditBox' or self.font,'EditBox SetText(): Font not set')
  strictSetText(self,value);self.calls.text=(self.calls.text or 0)+1
end
function pfUI.api.SkinButton(frame) assert(frame,'skin button') end
function pfUI.api.SkinCheckbox(frame) assert(frame,'skin checkbox') end
function pfUI.api.CreateBackdrop(frame) assert(frame,'backdrop frame') end
function UpdateMovable(frame,init)
  assert(frame:GetName()=='pfERBHealth' or frame:GetName()=='pfERBPower','another movable touched')
  pfUI.api.UpdateMovable(frame,init)
end
function shallowlessCopy(value)
  if type(value)~='table' then return value end
  local copy={};for k,v in pairs(value) do if k~='frame' then copy[k]=shallowlessCopy(v) end end
  return copy
end
function sameData(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~='table' then return a==b end
  for k,v in pairs(a) do if k~='frame' and not sameData(v,b[k]) then return false end end
  for k,v in pairs(b) do if k~='frame' and a[k]==nil then return false end end
  return true
end
function rememberLegacy()
  legacyRoot=ERB_options;legacyHealthRoot=ERB_options.erb_hp;legacyPowerRoot=ERB_options.erb_pp
  legacyData=shallowlessCopy(ERB_options)
  legacyHealthFrame=ERB_options.erb_hp.frame;legacyPowerFrame=ERB_options.erb_pp.frame
  oldSlash=SlashCmdList.ERB
  oldHPEvent=erb_hp:GetScript('OnEvent');oldPPEvent=erb_pp:GetScript('OnEvent')
  oldDummyEvent=erb_dummy_frame:GetScript('OnEvent')
  for _,frame in ipairs({erb_hp,erb_pp,erb_dummy_frame}) do
    frame:SetScript('OnUpdate',function() legacyUpdateCalls=legacyUpdateCalls+1 end)
  end
  oldHPUpdate=erb_hp:GetScript('OnUpdate');oldPPUpdate=erb_pp:GetScript('OnUpdate')
  oldDummyUpdate=erb_dummy_frame:GetScript('OnUpdate')
end
function assertLegacyUnchanged()
  assert(ERB_options==legacyRoot and ERB_options.erb_hp==legacyHealthRoot and ERB_options.erb_pp==legacyPowerRoot,'legacy tables replaced')
  assert(ERB_options.erb_hp.frame==legacyHealthFrame and ERB_options.erb_pp.frame==legacyPowerFrame,'legacy frame references changed')
  assert(sameData(ERB_options,legacyData),'legacy settings mutated')
end
function assertLeaseRestored()
  assert(erb_hp:GetScript('OnEvent')==oldHPEvent and erb_pp:GetScript('OnEvent')==oldPPEvent)
  assert(erb_dummy_frame:GetScript('OnEvent')==oldDummyEvent)
  assert(erb_hp:GetScript('OnUpdate')==oldHPUpdate and erb_pp:GetScript('OnUpdate')==oldPPUpdate)
  assert(erb_dummy_frame:GetScript('OnUpdate')==oldDummyUpdate)
  assert(SlashCmdList.ERB==oldSlash,'legacy slash command not restored')
  assertLegacyUnchanged()
end
'''


class Harness:
    def __init__(self, legacy=True, failed_font=False, load_gui=True, enabled_at_load=False):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        install = self.lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))
        install(self.lua.globals().methods, self.lua.globals().object)
        self.lua.execute(EXTENSIONS)
        for key, value in DEFAULTS.items():
            self.lua.globals().C.unitframes[key] = value
        api = (ARGS.addons / "pfUI/api/api.lua").read_text(encoding="utf-8-sig")
        self.lua.execute(api[api.index("function pfUI.api.LoadMovable("):api.index("-- [ Save Movable ]")])
        self.lua.execute("LoadMovable=pfUI.api.LoadMovable")
        self.lua.execute(api[api.index("function pfUI.api.UpdateMovable("):api.index("-- [ CreateShareListDialog ]")])
        self.lua.execute(api[api.index("function pfUI.api.strsplit("):api.index("-- [ isempty ]")])
        self.lua.execute("local color_cache={}\n" + api[api.index("function pfUI.api.GetStringColor("):api.index("-- [ rgbhex ]")])
        if legacy:
            self.load_legacy()
        if failed_font:
            self.execute(r"failedFontPaths['Configured.ttf']=true;failedFontPaths['Fonts\\FZJZJW.ttf']=true")
        if enabled_at_load:
            self.execute("C.resourcebars.enable='1'")
        self.execute((ARGS.addons / "pfUI/modules/resourcebars.lua").read_text(encoding="utf-8-sig"))
        if load_gui:
            self.execute((ARGS.addons / "pfUI/modules/resourcebars_gui.lua").read_text(encoding="utf-8-sig"))

    def load_legacy(self):
        self.execute((ARGS.addons / "ExtraResourceBars/ExtraResourceBars.lua").read_text(encoding="utf-8-sig"))
        self.execute("loadedAddons.ExtraResourceBars=true;ERB_Load();dispatchEvent('PLAYER_ENTERING_WORLD');rememberLegacy()")

    @property
    def module(self):
        return self.lua.globals().pfUI.resourcebars

    @property
    def health(self):
        return self.module.health

    @property
    def power(self):
        return self.module.power

    @property
    def config(self):
        return self.lua.globals().C.resourcebars

    def execute(self, code):
        return self.lua.execute(code)

    def eval(self, expression):
        return self.lua.eval(expression)

    def call(self, method):
        return self.module[method](self.module)

    def advance(self, seconds=.1, fps=60):
        self.lua.globals().advance(seconds, fps)

    def start(self):
        self.call("StartTrial")
        self.advance()

    def refresh(self):
        self.call("UpdateConfig")
        self.advance()


class ResourceBars(unittest.TestCase):
    def test_preview_defaults_does_not_block_later_legacy_import(self):
        h = Harness(legacy=False)
        h.call("OpenConfig")
        self.assertIsNone(h.config.data)
        self.assertFalse(h.module.active)
        h.load_legacy()
        h.call("ImportLegacy")
        h.execute("assert(sameData(C.resourcebars.data,legacyData));assertLegacyUnchanged()")

    def test_stop_trial_refreshes_legacy_values_and_restores_callback_context(self):
        h = Harness()
        h.execute("""
        erb_hp.time=.23;erb_hp.fading=true;erb_hp:SetAlpha(.6)
        erb_pp.time=.77;erb_pp.fading=false;erb_pp:SetAlpha(.4);erb_pp:Hide()
        """)
        h.start()
        h.execute("health=450;resource=3000;dispatchEvent('UNIT_HEALTH','player');dispatchEvent('UNIT_MANA','player')")
        h.advance(.2)
        h.execute("this=UIParent;event='SENTINEL_EVENT';arg1='SENTINEL_ARG'")
        h.call("StopTrial")
        h.execute("""
        assert(string.find(erb_hp.text:GetText(),'450') and string.find(erb_hp.text:GetText(),'45%%'),'stale HP after handoff')
        assert(erb_pp.text:GetText()=='3000','stale power after handoff')
        assert(this==UIParent and event=='SENTINEL_EVENT' and arg1=='SENTINEL_ARG','event globals leaked')
        assert(erb_hp.time==.23 and erb_hp.fading==true and erb_pp.time==.77 and erb_pp.fading==false)
        assert(erb_hp:IsShown() and not erb_pp:IsShown())
        assert(erb_hp:GetAlpha()==.6 and erb_pp:GetAlpha()==.4)
        assertLeaseRestored();otherFramesUnchanged()
        """)

    def test_default_disabled_leaves_legacy_engine_and_settings_untouched(self):
        h = Harness()
        h.execute("beforeReads=shallowlessCopy(reads)")
        h.call("UpdateConfig")
        h.execute("""
        assert(not pfERBHealth and not pfERBPower,'disabled integration created bars')
        assertLeaseRestored();otherFramesUnchanged()
        for k,v in pairs(reads) do assert(v==beforeReads[k],'disabled integration read '..k) end
        assert(disabledAddons==0)
        """)

    def test_import_is_deep_read_only_and_does_not_enable(self):
        h = Harness()
        h.call("ImportLegacy")
        h.execute("""
        assert(C.resourcebars.enable=='0' and not pfERBHealth and not pfERBPower)
        assert(sameData(C.resourcebars.data,legacyData),'legacy fields missing from import')
        assert(C.resourcebars.data.erb_hp.frame==nil and C.resourcebars.data.erb_pp.frame==nil)
        assert(C.resourcebars.data.erb_hp~=ERB_options.erb_hp)
        assert(C.resourcebars.data.erb_pp.powers~=ERB_options.erb_pp.powers)
        assert(C.resourcebars.data.erb_pp.powers.mana~=ERB_options.erb_pp.powers.mana)
        assertLegacyUnchanged();assertLeaseRestored();otherFramesUnchanged()
        """)

    def test_trial_pauses_all_old_callbacks_and_restores_exact_lease(self):
        h = Harness()
        h.execute("erb_hp:SetAlpha(.6);erb_pp:SetAlpha(.4);erb_pp:Hide()")
        h.start()
        h.execute("""
        for _,frame in ipairs({erb_hp,erb_pp,erb_dummy_frame}) do
          assert(not frame:GetScript('OnEvent') and not frame:GetScript('OnUpdate'),'legacy updater retained')
          assert(not frame:IsShown(),'legacy frame retained')
        end
        assert(SlashCmdList.ERB~=oldSlash)
        oldUpdateCount=legacyUpdateCalls
        """)
        h.execute("dispatchEvent('PLAYER_ENTERING_WORLD');dispatchEvent('UNIT_HEALTH','player')")
        h.advance(.5)
        h.execute("assert(legacyUpdateCalls==oldUpdateCount);assertLegacyUnchanged();otherFramesUnchanged()")
        h.call("StopTrial")
        h.execute("""
        assertLeaseRestored()
        assert(erb_hp:IsShown() and not erb_pp:IsShown())
        assert(erb_hp:GetAlpha()==.6 and erb_pp:GetAlpha()==.4)
        assert(not pfERBHealth:IsShown() and not pfERBPower:IsShown())
        assert(disabledAddons==0)
        """)

    def test_all_39_fields_and_manual_extra_fields_survive_import(self):
        h = Harness()
        h.execute("""
        local hp,pp=ERB_options.erb_hp,ERB_options.erb_pp
        hp.hide=true;hp.barResize='RIGHT';hp.width=219;hp.height=31;hp.color={.11,.22,.33,.44}
        hp.fontSize=17;hp.textType=4;hp.textAlign='LEFT';hp.gradiantHP=false
        hp.bar=35;hp.border=0;hp.background=false;hp.backgroundColor={.12,.23,.34,.45}
        hp.only_combat=true;hp.hide_when_full=true;hp.fade_in_time=.37;hp.fade_out_time=.91
        hp.moveable=false;hp.under='SyntheticExternal';hp.spacing=-7
        pp.hide=true;pp.barResize='CENTER';pp.width=187;pp.height=29
        pp.powers={main='rage',mana={.13,.24,.35,.46},rage={.14,.25,.36,.47},energy={.15,.26,.37,.48}}
        pp.fontSize=19;pp.textType=0;pp.textAlign='RIGHT';pp.under='erb_hp';pp.spacing=-11
        pp.bar=34;pp.border=4;pp.background=false;pp.backgroundColor={.16,.27,.38,.49}
        pp.only_combat=true;pp.hide_when_full=true;pp.fade_in_time=.53;pp.fade_out_time=.79
        pp.moveable=false
        rememberLegacy()
        """)
        h.call("ImportLegacy")
        h.execute("""
        for _,spec in ipairs(CONFIG_SETTINGS) do
          local path=spec[5];local actual=C.resourcebars.data[path[1]]
          local expected=legacyData[path[1]]
          if path[3] then actual=actual[path[3]];expected=expected[path[3]] end
          assert(sameData(actual[path[2]],expected[path[2]]),'missing setting '..spec[2])
        end
        assert(C.resourcebars.data.erb_hp.moveable==false and C.resourcebars.data.erb_pp.moveable==false)
        assert(C.resourcebars.data.erb_hp.under=='SyntheticExternal' and C.resourcebars.data.erb_hp.spacing==-7)
        assertLegacyUnchanged()
        """)

    def test_repeated_trial_reuses_frames_and_preserves_personal_edits(self):
        h = Harness()
        h.start()
        h.execute("C.resourcebars.data.erb_hp.width=237")
        h.refresh()
        h.execute("firstHealth=pfERBHealth;firstPower=pfERBPower;objectCount=#objects")
        h.call("StopTrial")
        h.start()
        h.execute("""
        assert(pfERBHealth==firstHealth and pfERBPower==firstPower and #objects==objectCount)
        assert(C.resourcebars.data.erb_hp.width==237 and pfERBHealth:GetWidth()==237)
        assertLegacyUnchanged();otherFramesUnchanged()
        """)
        h.call("StopTrial")
        h.execute("assertLeaseRestored()")

    def test_text_formats_and_alignment_refresh_without_stale_anchors(self):
        h = Harness()
        h.start()
        for mode in range(5):
            h.execute(f"C.resourcebars.data.erb_hp.textType={mode}")
            h.refresh()
            text = h.health.text.GetText(h.health.text)
            if mode < 3:
                self.assertEqual(text, ("", "750", "75%")[mode])
            else:
                self.assertIn("750", text)
                self.assertIn("1000", text)
                self.assertIn("75%", text)
                self.assertEqual(text.startswith("75%"), mode == 4)
        for alignment in ("LEFT", "CENTER", "RIGHT", "LEFT"):
            h.execute(f"C.resourcebars.data.erb_hp.textAlign='{alignment}'")
            h.refresh()
            self.assertEqual(h.health.text.point[1], alignment)
            self.assertEqual(h.health.text.GetNumPoints(h.health.text), 1)

    def test_fill_direction_width_and_texture_crop(self):
        h = Harness()
        h.start()
        h.execute("health=100;healthMax=400;C.resourcebars.data.erb_hp.width=180")
        expected_crop = {"LEFT": (0, .25), "CENTER": (.375, .625), "RIGHT": (.75, 1)}
        for border in (0, 1, 2, 3, 4):
            for alignment in ("LEFT", "CENTER", "RIGHT"):
                h.execute(f"C.resourcebars.data.erb_hp.border={border};C.resourcebars.data.erb_hp.barResize='{alignment}'")
                h.refresh()
                expected = (180 - 8 + (5 if border == 4 else 0)) * .25
                self.assertAlmostEqual(h.health.bar.GetWidth(h.health.bar), expected, delta=.002)
                self.assertEqual(h.health.bar.point[1], alignment)
                self.assertEqual(h.health.bar.GetNumPoints(h.health.bar), 1)
                for index, value in enumerate(expected_crop[alignment], 1):
                    self.assertAlmostEqual(h.health.bar.texcoords[index], value, delta=.002)

    def test_all_textures_and_borders_are_owned_pfui_assets(self):
        h = Harness()
        h.start()
        for texture in range(1, 36):
            h.execute(f"C.resourcebars.data.erb_hp.bar={texture}")
            h.refresh()
            path = h.health.bar.GetTexture(h.health.bar)
            self.assertIn("pfUI\\img\\resourcebars\\", path)
            self.assertNotIn("ExtraResourceBars", path)
            relative = path.replace("\\", "/").split("Interface/AddOns/", 1)[1]
            asset = ARGS.addons / relative
            if not asset.suffix:
                asset = asset.with_suffix(".blp" if texture <= 5 else ".tga")
            self.assertTrue(asset.is_file(), asset)
            self.assertEqual(asset.read_bytes(), (ARGS.addons / "ExtraResourceBars/bars" / asset.name).read_bytes())
        for border in range(5):
            h.execute(f"C.resourcebars.data.erb_hp.border={border}")
            h.refresh()
            if border == 4:
                self.assertIn("pfUI\\img\\resourcebars\\", h.health.backdrop.edgeFile)
        for name in ("bar_1.blp", "bar_35.tga"):
            self.assertTrue((ARGS.addons / "pfUI/img/resourcebars" / name).is_file())

    def test_power_type_events_ignore_locale_and_update_maximum(self):
        h = Harness()
        h.start()
        h.execute("""
        C.resourcebars.followcolors='0'
        C.resourcebars.data.erb_pp.powers={main='mana',mana={.1,.2,.3,1},rage={.4,.5,.6,1},energy={.7,.8,.9,1}}
        classToken='DRUID'
        """)
        h.refresh()
        for power, color in ((3, (.7, .8, .9)), (1, (.4, .5, .6)), (0, (.1, .2, .3))):
            h.execute(f"powerType={power};resource=40;maximum=100;dispatchEvent('UNIT_DISPLAYPOWER','player')")
            h.advance()
            self.assertEqual(tuple(h.power.bar.color[i] for i in (1, 2, 3)), color)
            self.assertIn("40", h.power.text.GetText(h.power.text))
        h.execute("maximum=200;dispatchEvent('UNIT_MAXMANA','player')")
        h.advance()
        ratio_width = (h.power.GetWidth(h.power) - 8) * .2
        self.assertAlmostEqual(h.power.bar.GetWidth(h.power.bar), ratio_width, delta=.002)
        h.execute("health=0;healthMax=0;resource=0;maximum=0;dispatchEvent('UNIT_MAXHEALTH','player');dispatchEvent('UNIT_MAXMANA','player')")
        h.advance()
        h.execute("assert(pfERBHealth.bar:GetWidth()==pfERBHealth.bar:GetWidth());assert(pfERBPower.bar:GetWidth()==pfERBPower.bar:GetWidth())")

    def test_gradient_background_and_hidden_empty_text_keep_valid_fonts(self):
        h = Harness(failed_font=True)
        h.start()
        h.execute("C.resourcebars.data.erb_hp.gradiantHP=true")
        h.refresh()
        for current, expected in ((0, (1, 0, 0)), (250, (1, .5, 0)), (500, (1, 1, 0)), (750, (.5, 1, 0)), (1000, (0, 1, 0))):
            h.execute(f"health={current};dispatchEvent('UNIT_HEALTH','player')")
            h.advance()
            for index, value in enumerate(expected, 1):
                self.assertAlmostEqual(h.health.bar.color[index], value)
        h.execute("C.resourcebars.data.erb_hp.background=false;C.resourcebars.data.erb_hp.textType=0")
        h.refresh()
        self.assertFalse(h.health.background.IsShown(h.health.background))
        self.assertEqual(h.health.text.GetText(h.health.text), "")
        h.execute(r"""
        for _,frame in ipairs({pfERBHealth,pfERBPower}) do
          assert(frame.text.font and frame.text.font[1]~='Fonts\\FZJZJW.ttf','font fallback missing')
          frame.text:Hide();frame.text:SetText('');frame.text:Show()
        end
        assertLegacyUnchanged()
        """)

    def test_integration_loaded_before_standalone_can_acquire_and_release_it(self):
        h = Harness(legacy=False)
        h.load_legacy()
        h.start()
        h.execute("assert(not erb_hp:GetScript('OnEvent') and not erb_dummy_frame:GetScript('OnEvent'));assertLegacyUnchanged()")
        h.call("StopTrial")
        h.execute("assertLeaseRestored();otherFramesUnchanged()")

    def test_saved_enabled_startup_waits_for_legacy_initialization_in_either_load_order(self):
        for legacy_first in (True, False):
            h = Harness(legacy=legacy_first, enabled_at_load=True)
            if not legacy_first:
                self.assertIsNone(h.health)
                h.load_legacy()
            h.advance(.2)
            h.execute("""
            assert(pfERBHealth and pfERBPower,'saved enabled startup did not prepare')
            assert(C.resourcebars.data and sameData(C.resourcebars.data,legacyData),'startup imported premature defaults')
            assert(not erb_hp:GetScript('OnEvent') and not erb_pp:GetScript('OnEvent'))
            assert(not erb_dummy_frame:GetScript('OnEvent'),'late legacy loader still updating')
            assertLegacyUnchanged();otherFramesUnchanged()
            """)
            h.call("StopTrial")
            h.execute("assertLeaseRestored()")

    def test_shift_drag_relative_under_and_detach_restore_mouse(self):
        h = Harness()
        h.start()
        h.execute("""
        C.resourcebars.data.erb_hp.height=20
        C.resourcebars.data.erb_pp.height=14
        C.resourcebars.data.erb_pp.spacing=3
        C.resourcebars.data.erb_pp.under='erb_hp'
        C.resourcebars.data.erb_hp.moveable=true
        """)
        h.refresh()
        h.execute("""
        local a,parent,r,x,y=pfERBPower:GetPoint()
        assert(a=='CENTER' and parent==pfERBHealth and r=='CENTER' and x==0 and y==-17,'legacy under geometry changed')
        assert(not pfERBPower.mouse,'linked frame is draggable')
        shift=false;runScript(pfERBHealth,'OnDragStart');assert(not pfERBHealth.moving)
        shift=true;runScript(pfERBHealth,'OnDragStart');assert(pfERBHealth.moving)
        pfERBHealth:ClearAllPoints();pfERBHealth:SetPoint('CENTER',UIParent,'CENTER',30,-80)
        runScript(pfERBHealth,'OnDragStop');assert(not pfERBHealth.moving)
        assert(C.resourcebars.positions.erb_hp and next(C.resourcebars.positions.erb_hp),'drag not persisted')
        C.resourcebars.data.erb_pp.under=nil;C.resourcebars.data.erb_pp.moveable=true
        """)
        h.refresh()
        self.assertTrue(h.power.mouse)
        self.assertEqual(h.health.GetCenter(h.health), (990, 460))
        h.call("StopTrial")
        h.start()
        self.assertEqual(h.health.GetCenter(h.health), (990, 460))
        h.execute("C.resourcebars.data.erb_hp.moveable=false")
        h.refresh()
        self.assertFalse(h.health.mouse)
        h.execute("assertLegacyUnchanged();otherFramesUnchanged()")

    def test_import_uses_live_centers_and_preserves_original_frame_geometry(self):
        h = Harness()
        h.execute("""
        erb_hp:ClearAllPoints();erb_hp:SetPoint('CENTER',UIParent,'CENTER',-145,107)
        erb_pp:ClearAllPoints();erb_pp:SetPoint('CENTER',UIParent,'CENTER',-145,82)
        ERB_options.erb_pp.under=nil
        rememberLegacy()
        """)
        h.start()
        self.assertEqual(h.health.GetCenter(h.health), (815, 647))
        self.assertEqual(h.power.GetCenter(h.power), (815, 622))
        h.execute("""
        local _,_,_,x,y=erb_hp:GetPoint();assert(x==-145 and y==107,'legacy anchor mutated')
        local _,_,_,x,y=erb_pp:GetPoint();assert(x==-145 and y==82,'legacy anchor mutated')
        assertLegacyUnchanged()
        """)

    def test_gui_all_39_fields_save_without_mutating_legacy_and_reuses_widgets(self):
        h = Harness(failed_font=True)
        h.start()
        h.call("OpenConfig")
        h.execute("""
        editor=pfUI.resourcebars.editor
        assert(editor and editor.fields and editor.save and editor.reset and editor.close)
        expectedEdit=shallowlessCopy(C.resourcebars.data)
        for _,spec in ipairs(CONFIG_SETTINGS) do
          local field=assert(editor.fields[spec[2]],'missing GUI setting '..spec[2])
          local path=spec[5];local target=expectedEdit[path[1]]
          if path[3] then target=target[path[3]] end
          local value
          if type(spec[4])=='boolean' then
            value=not spec[4];field:SetChecked(value)
          elseif spec[6] then
            value={.12,.34,.56,.78};field:SetText('{0.12,0.34,0.56,0.78}')
          elseif path[2]=='width' then value=213;field:SetText('213')
          elseif path[2]=='height' then value=27;field:SetText('27')
          elseif path[2]=='fontSize' then value=15;field:SetText('15')
          elseif path[2]=='textType' then value=4;field:SetText('4')
          elseif path[2]=='bar' then value=35;field:SetText('35')
          elseif path[2]=='border' then value=4;field:SetText('4')
          elseif path[2]=='spacing' then value=-4;field:SetText('-4')
          elseif path[2]=='fade_in_time' then value=.31;field:SetText('.31')
          elseif path[2]=='fade_out_time' then value=.47;field:SetText('.47')
          elseif path[2]=='textAlign' then value='RIGHT';field:SetText('RIGHT')
          elseif path[2]=='barResize' then value='CENTER';field:SetText('CENTER')
          elseif path[2]=='main' then value='rage';field:SetText('rage')
          elseif path[2]=='under' then value='erb_hp';field:SetText('erb_hp')
          else error('untested editor field '..spec[2]) end
          target[path[2]]=value
        end
        editor.fields.hp_font:SetText('Missing.ttf');editor.fields.pp_font:SetText('Missing.ttf')
        failedFontPaths['Missing.ttf']=true
        runScript(editor.save,'OnClick')
        for _,spec in ipairs(CONFIG_SETTINGS) do
          local path=spec[5];local actual=C.resourcebars.data[path[1]];local expected=expectedEdit[path[1]]
          if path[3] then actual=actual[path[3]];expected=expected[path[3]] end
          assert(sameData(actual[path[2]],expected[path[2]]),'GUI did not save '..spec[2])
        end
        assert(pfERBHealth.text.font and pfERBPower.text.font,'failed configured font lost fallback')
        editorObjectCount=#objects
        runScript(editor.close,'OnClick')
        assert(not editor:IsShown(),'close button did not hide editor')
        """)
        h.call("OpenConfig")
        h.execute("""
        assert(pfUI.resourcebars.editor==editor and #objects==editorObjectCount,'editor leaked controls')
        assertLegacyUnchanged();otherFramesUnchanged()
        """)

    def test_gui_rejects_invalid_input_atomically_without_executing_it(self):
        h = Harness()
        h.start()
        invalid_fields = (("hp_width", "bad"), ("hp_width", "-1"), ("hp_textType", "9"),
                          ("hp_bar", "36"), ("hp_border", "5"),
                          ("pp_color_mana", "{1,0,0};invalidExecuted=true"))
        for name, invalid in invalid_fields:
            h.call("OpenConfig")
            h.execute("beforeEdit=shallowlessCopy(C.resourcebars.data)")
            h.module.editor.fields[name].SetText(h.module.editor.fields[name], invalid)
            result = h.call("SaveEditor")
            success = result[0] if isinstance(result, tuple) else result
            self.assertFalse(success, (name, invalid, result))
            h.execute("assert(sameData(C.resourcebars.data,beforeEdit),'partial invalid save');assert(not invalidExecuted);assertLegacyUnchanged()")

    def test_gui_reset_only_changes_draft_until_save(self):
        h = Harness()
        h.start()
        h.execute("C.resourcebars.data.erb_hp.width=239")
        h.refresh()
        h.call("OpenConfig")
        h.execute("runScript(pfUI.resourcebars.editor.reset,'OnClick');assert(C.resourcebars.data.erb_hp.width==239,'reset applied before save')")
        h.execute("runScript(pfUI.resourcebars.editor.save,'OnClick')")
        self.assertEqual(h.config.data.erb_hp.width, 124)
        h.execute("assertLegacyUnchanged();otherFramesUnchanged()")

    def test_gui_color_picker_preserves_precision_alpha_and_cancelled_draft(self):
        h = Harness(failed_font=True)
        h.start()
        h.execute("C.resourcebars.data.erb_hp.backgroundColor={.123456789,.234567891,.345678912,.456789123}")
        h.call("OpenConfig")
        h.call("SaveEditor")
        self.assertAlmostEqual(h.config.data.erb_hp.backgroundColor[1], .123456789, places=12)
        h.execute("""
        local field=pfUI.resourcebars.editor.fields.hp_backgroundColor
        assert(field.font,'editor font failure has no fallback')
        colorDraftBefore=field:GetText()
        runScript(field,'OnMouseUp','LeftButton')
        assert(ColorPickerFrame:IsShown() and ColorPickerFrame.hasOpacity)
        assert(math.abs(ColorPickerFrame.opacity-(1-.456789123))<.000000001)
        ColorPickerFrame:SetColorRGB(.71,.82,.93)
        OpacitySliderFrame:SetValue(.36)
        ColorPickerFrame.func()
        assert(field:GetText()~=colorDraftBefore,'picker did not update draft')
        ColorPickerFrame.cancelFunc(ColorPickerFrame.previousValues)
        assert(field:GetText()==colorDraftBefore,'cancel did not restore original draft')
        runScript(field,'OnMouseUp','RightButton')
        ColorPickerFrame:SetColorRGB(.71,.82,.93)
        OpacitySliderFrame:SetValue(.36)
        ColorPickerFrame.opacityFunc()
        assert(pfUI.resourcebars:SaveEditor())
        local color=C.resourcebars.data.erb_hp.backgroundColor
        assert(color[1]==.71 and color[2]==.82 and color[3]==.93 and color[4]==.64,'picker opacity converted incorrectly')
        assertLegacyUnchanged();otherFramesUnchanged()
        """)

    def test_follow_colors_uses_real_player_palette_and_can_return_to_legacy(self):
        h = Harness()
        h.start()
        h.execute("""
        pfUI.uf.player.config={defcolor='0',manacolor='.13,.23,.33,.43',
          ragecolor='.14,.24,.34,.44',energycolor='.15,.25,.35,.45'}
        C.resourcebars.followcolors='1'
        """)
        h.refresh()
        for ptype, rgb in ((0, (.13, .23, .33)), (1, (.14, .24, .34)), (3, (.15, .25, .35))):
            h.execute(f"powerType={ptype};dispatchEvent('UNIT_DISPLAYPOWER','player')")
            h.advance()
            self.assertEqual(tuple(h.power.bar.color[i] for i in (1, 2, 3)), rgb)
        h.execute("""
        C.resourcebars.followcolors='0'
        C.resourcebars.data.erb_pp.powers.energy={.71,.81,.91,1}
        """)
        h.refresh()
        self.assertEqual(tuple(h.power.bar.color[i] for i in (1, 2, 3)), (.71, .81, .91))
        h.execute("C.resourcebars.followcolors='1';pfUI.api.GetPlayerResourceColor=function() error('palette unavailable') end")
        h.refresh()
        self.assertEqual(tuple(h.power.bar.color[i] for i in (1, 2, 3)), (.71, .81, .91))

    def test_disabled_integration_needs_no_standalone_or_resource_assets(self):
        h = Harness(legacy=False)
        h.execute("beforeCount=#objects;beforeReads=shallowlessCopy(reads)")
        h.call("UpdateConfig")
        h.advance(1)
        h.execute("""
        assert(not ERB_options and not pfERBHealth and not pfERBPower)
        assert(#objects==beforeCount and type(SlashCmdList.ERB)=='function')
        for k,v in pairs(reads) do assert(v==beforeReads[k],'disabled read '..k) end
        assert(disabledAddons==0);otherFramesUnchanged()
        """)
        h.execute("SlashCmdList.ERB();assert(pfUI.resourcebars.editor:IsShown());assert(C.resourcebars.enable=='0' and not pfERBHealth and not pfERBPower)")

    def test_standalone_absent_can_run_owned_bars_and_disable_without_legacy_globals(self):
        h = Harness(legacy=False)
        h.start()
        self.assertIsNotNone(h.health)
        self.assertIsNotNone(h.power)
        self.assertIn("750", h.health.text.GetText(h.health.text))
        h.execute("assert(not ERB_options and not erb_hp and not erb_pp,'standalone globals fabricated')")
        h.call("StopTrial")
        h.execute("""
        assert(type(SlashCmdList.ERB)=='function' and disabledAddons==0)
        SlashCmdList.ERB()
        assert(pfUI.resourcebars.editor:IsShown() and C.resourcebars.enable=='0')
        assert(not pfERBHealth:IsShown() and not pfERBPower:IsShown())
        otherFramesUnchanged()
        """)

    def test_disabled_after_trial_detaches_private_updates(self):
        h = Harness()
        h.start()
        h.call("StopTrial")
        h.execute("""
        assert(not pfERBHealth:GetScript('OnEvent') and not pfERBHealth:GetScript('OnUpdate'))
        assert(not pfERBPower:GetScript('OnEvent') and not pfERBPower:GetScript('OnUpdate'))
        assert(not pfUI.resourcebars.driver:GetScript('OnUpdate'),'private engine remains active')
        assertLeaseRestored()
        """)

    def test_combat_full_value_and_rage_empty_visibility_matrix(self):
        h = Harness()
        h.start()
        for only_combat, hide_full in ((False, False), (False, True), (True, False), (True, True)):
            for fighting in (False, True):
                for full in (False, True):
                    h.execute(f"""
                    C.resourcebars.data.erb_hp.only_combat={str(only_combat).lower()}
                    C.resourcebars.data.erb_hp.hide_when_full={str(hide_full).lower()}
                    C.resourcebars.data.erb_hp.fade_in_time=0;C.resourcebars.data.erb_hp.fade_out_time=0
                    combat={str(fighting).lower()};health={1000 if full else 750}
                    """)
                    h.refresh()
                    wanted = fighting if only_combat else True
                    if hide_full:
                        wanted = fighting or not full if only_combat else not full
                    visible = h.health.IsShown(h.health) and h.health.GetAlpha(h.health) > 0
                    self.assertEqual(visible, wanted, (only_combat, hide_full, fighting, full))
        h.execute("""
        combat=false;powerType=1;resource=0;maximum=100
        C.resourcebars.data.erb_pp.hide_when_full=true;C.resourcebars.data.erb_pp.only_combat=false
        C.resourcebars.data.erb_pp.fade_in_time=0;C.resourcebars.data.erb_pp.fade_out_time=0
        """)
        h.refresh()
        self.assertFalse(h.power.IsShown(h.power) and h.power.GetAlpha(h.power) > 0)
        h.execute("C.resourcebars.data.erb_hp.hide=true;combat=true;health=500")
        h.refresh()
        self.assertFalse(h.health.IsShown(h.health))

    def test_fade_uses_elapsed_time_at_30_60_120_fps_and_reverses_smoothly(self):
        samples = []
        for rate in (30, 60, 120):
            h = Harness()
            h.start()
            h.execute("""
            C.resourcebars.data.erb_hp.only_combat=true
            C.resourcebars.data.erb_hp.hide_when_full=false
            C.resourcebars.data.erb_hp.fade_in_time=.4
            C.resourcebars.data.erb_hp.fade_out_time=.4
            combat=false
            """)
            h.refresh()
            h.advance(.5, rate)
            h.execute("combat=true;dispatchEvent('PLAYER_REGEN_DISABLED')")
            h.advance(.2, rate)
            middle = h.health.GetAlpha(h.health)
            samples.append(middle)
            self.assertGreater(middle, .2)
            self.assertLess(middle, .8)
            h.execute("combat=false;dispatchEvent('PLAYER_REGEN_ENABLED')")
            self.assertAlmostEqual(h.health.GetAlpha(h.health), middle, delta=.001)
            h.advance(.05, rate)
            self.assertLess(h.health.GetAlpha(h.health), middle)
            h.advance(.5, rate)
            self.assertFalse(h.health.IsShown(h.health))
        self.assertLess(max(samples) - min(samples), .1)

    def test_stable_values_throttle_reads_and_do_not_rewrite_textures_or_text(self):
        h = Harness()
        h.start()
        h.advance(.3, 120)
        h.execute("""
        beforeHealthReads=reads.health;beforePowerReads=reads.mana
        stableCounters={}
        for _,frame in ipairs({pfERBHealth,pfERBPower}) do
          stableCounters[frame]={text=frame.text.calls.text,width=frame.bar.calls.width,
            color=frame.bar.calls.color,texture=frame.bar.calls.texture}
        end
        """)
        h.advance(1, 120)
        h.execute("""
        assert(reads.health-beforeHealthReads<=12 and reads.mana-beforePowerReads<=12,'unthrottled resource reads')
        for frame,before in pairs(stableCounters) do
          assert(frame.text.calls.text==before.text,'stable text rewritten')
          assert(frame.bar.calls.width==before.width,'stable width rewritten')
          assert(frame.bar.calls.color==before.color,'stable color rewritten')
          assert(frame.bar.calls.texture==before.texture,'stable texture rewritten')
        end
        assertLegacyUnchanged();otherFramesUnchanged()
        """)


if __name__ == "__main__":
    unittest.main(argv=[sys.argv[0]] + REMAINING, verbosity=2)
