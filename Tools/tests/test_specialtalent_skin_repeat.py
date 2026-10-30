"""Run the complete SpecialTalent OnShow with the real pfUI skin functions.

The UI mock never resets button heights while skinning. FontString writes use
the shared strict 1.12 font contract. --baseline-ref PRE_FIX_REF reproduces
the old shrink from a prior Git source without modifying the working tree.
"""
from pathlib import Path
import argparse
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

parser = argparse.ArgumentParser()
parser.add_argument("--baseline-ref")
ARGS, REMAINING = parser.parse_known_args()
SOURCE = "Interface/AddOns/SpecialTalent/SpecialTalentUI.lua"

MOCK = r'''
methods={};buttons={};objects={};skinCalls=0
function object(kind,name,height)
  local o=setmetatable({kind=kind,name=name,height=height or 40,width=120,scripts={},heightWrites=0,fontWrites=0}, {__index=methods})
  if name then _G[name]=o end
  table.insert(objects,o)
  return o
end
function methods:GetName() return self.name end
function methods:GetHeight() return self.height end
function methods:SetHeight(value)
  assert(type(value)=='number' and value>=0,'invalid button height')
  self.height=value;self.heightWrites=self.heightWrites+1
end
function methods:GetScript(key) return self.scripts[key] end
function methods:SetScript(key,fn) self.scripts[key]=fn end
function methods:HookScript(key,fn)
  self.hookCalls=(self.hookCalls or 0)+1
  local previous=self.scripts[key]
  self.scripts[key]=function() if previous then previous() end;fn() end
end
function methods:SetBackdrop(value) self.backdropStyle=value end
function methods:SetBackdropColor(...) self.backdropColor={...} end
function methods:SetBackdropBorderColor(...) self.borderColor={...} end
function methods:SetNormalTexture(value) self.normalTexture=value end
function methods:SetHighlightTexture(value) self.highlightTexture=value end
function methods:SetPushedTexture(value) self.pushedTexture=value end
function methods:SetDisabledTexture(value) self.disabledTexture=value end
function methods:SetTextColor(...) self.textColor={...} end
function methods:Enable() self.enabled=true end
function methods:Disable() self.enabled=false end
function methods:ClearAllPoints() self.point=nil end
function methods:SetPoint(...) self.point={...} end
function UnitClass() return 'Mage','MAGE' end
function UnitLevel() return 60 end
function GetBorderSize() return 1,1 end
function GetPerfectPixel() return 1 end
function GetStringColor() return .2,.2,.2,1 end
function MouseIsOver() return false end
function SetButtonPulse() end
function PlaySound() end
function UpdateMicroButtons() end
function SetPortraitTexture() end
function LearnTalent() error('opening the frame must not learn talents') end
max=math.max;getglobal=function(name) return _G[name] end
RAID_CLASS_COLORS={MAGE={r=.2,g=.5,b=1}}
C={global={font_size=12},appearance={border={force_blizz='0',background='0,0,0,1',color='.2,.2,.2,1'}}}
pfUI_config=C
pfUI={api={},env={},font_default='Fonts\\FZXHLJW.TTF',backdrop={},backdrop_thin={}}
function pfUI:GetEnvironment() return self.api end
pfUI.api.GetStringColor=GetStringColor
UIParent=object('Frame','UIParent')
SpecialTalentFrame=object('Frame','SpecialTalentFrame')
TalentMicroButton=object('Button','TalentMicroButton')
SpecialTalentFramePortrait=object('Frame','SpecialTalentFramePortrait')
SpecialTalentFramePlannedCheckButtonText=object('FontString','SpecialTalentFramePlannedCheckButtonText')
SpecialTalentFrameTitleText=object('FontString','SpecialTalentFrameTitleText')
SpecialTalentFrameTalentPointsText=object('FontString','SpecialTalentFrameTalentPointsText')
PlayerOfRealm='synthetic'
SpecialTalentPlannedSaved={synthetic={selectedPlan=1,plans={{name='Synthetic plan'}}}}
SPECIAL_TALENT='SpecialTalent';SPECIAL_TALENT_RESET_PLAN='Reset';SPECIAL_TALENT_APPLY_PLAN='Apply'
buttonNames={'SpecialTalentFrameMinimizeButton','SpecialTalentFramePreviousButtonSmall',
 'SpecialTalentFrameNextButtonSmall','SpecialTalentFramePreviousButtonLarge',
 'SpecialTalentFrameNextButtonLarge','SpecialTalentRename','SpecialTalentFrameResetButton',
 'SpecialTalentFrameApplyButton'}
function addButton(name,height)
  local b=object('Button',name,height)
  b:SetFontObject(GameFontNormalSmall)
  buttons[name]=b
  return b
end
'''


def function_source(path, begin, following):
    text = path.read_text(encoding="utf-8-sig")
    return text[text.index(begin):text.index(following, text.index(begin))]


class Harness:
    def __init__(self, source=None):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        install = self.lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))
        install(self.lua.globals().methods, self.lua.globals().object)
        self.lua.execute(r'''
          local realSetFont=methods.SetFont
          function methods:SetFont(...)
            self.fontWrites=self.fontWrites+1
            return realSetFont(self,...)
          end
          for _,name in ipairs({'SpecialTalentFramePlannedCheckButtonText',
            'SpecialTalentFrameTitleText','SpecialTalentFrameTalentPointsText'}) do
            _G[name]:SetFontObject(GameFontNormalSmall)
          end
          for i,name in ipairs(buttonNames) do addButton(name,40+i) end
        ''')
        api = ROOT / "Interface/AddOns/pfUI/api/api.lua"
        widgets = ROOT / "Interface/AddOns/pfUI/api/ui-widgets.lua"
        self.lua.execute(function_source(api, "function pfUI.api.CreateBackdrop(", "-- [ Create Shadow ]"))
        self.lua.execute(function_source(widgets, "local function SetHighlightEnter()", "function pfUI.api.HandleIcon("))
        self.lua.execute("SetHighlight=pfUI.api.SetHighlight")
        self.lua.execute(function_source(widgets, "function pfUI.api.SkinButton(", "-- [ Skin Collapse Button ]"))
        self.lua.execute(r'''
          actualSkinButton=pfUI.api.SkinButton
          pfUI.api.SkinButton=function(...)
            skinCalls=skinCalls+1
            return actualSkinButton(...)
          end
        ''')
        self.lua.execute(source if source is not None else (ROOT / SOURCE).read_text(encoding="utf-8-sig"))
        # The tested OnShow stays real. Replace only external data loading and
        # unrelated talent rendering, so this remains an offline display test.
        self.lua.execute('''
          SpecialTalent_LoadPlannedSaved=function() end
          SpecialTalent_ResolveTalentData=function() end
          SpecialTalentFrame_Update=function() end
          SpecialTalentUI_UpdateResetButtons=function() end
        ''')

    def execute(self, code):
        return self.lua.execute(code)

    def show(self, count=1):
        self.execute(f"for i=1,{count} do SpecialTalentFrame_OnShow() end")


class RepeatedSkin(unittest.TestCase):
    def test_twenty_opens_keep_only_the_first_one_pixel_adjustment(self):
        h = Harness()
        h.show(1)
        h.execute("for i,name in ipairs(buttonNames) do assert(_G[name]:GetHeight()==40+i-1) end")
        h.show(24)
        h.execute("""
          assert(skinCalls==25*8)
          for i,name in ipairs(buttonNames) do
            assert(_G[name]:GetHeight()==40+i-1)
            assert(_G[name].heightWrites==1)
            assert(_G[name].fontWrites==25)
          end
        """)

    def test_existing_real_skin_cache_does_not_skip_first_height_adjustment(self):
        h = Harness()
        h.execute("""
          for _,name in ipairs(buttonNames) do
            local b=_G[name]
            b:SetScript('OnEnter',function() end);b:SetScript('OnLeave',function() end)
            pfUI.api.SkinButton(b)
            assert(b.pfEnterLeave and b.hookCalls==2)
            b.originalEnter=b:GetScript('OnEnter');b.originalLeave=b:GetScript('OnLeave')
          end
        """)
        h.show(25)
        h.execute("""
          for i,name in ipairs(buttonNames) do
            local b=_G[name]
            assert(b:GetHeight()==40+i-1 and b.heightWrites==1)
            assert(b:GetScript('OnEnter')==b.originalEnter and b:GetScript('OnLeave')==b.originalLeave)
            assert(b.hookCalls==2)
          end
        """)

    def test_missing_and_late_buttons_are_adjusted_only_when_created(self):
        h = Harness()
        h.execute("SpecialTalentFrameNextButtonSmall=nil;SpecialTalentRename=nil")
        h.show(20)
        h.execute("addButton('SpecialTalentFrameNextButtonSmall',35);addButton('SpecialTalentRename',29)")
        h.show(21)
        h.execute("""
          assert(SpecialTalentFrameNextButtonSmall:GetHeight()==34 and SpecialTalentFrameNextButtonSmall.heightWrites==1)
          assert(SpecialTalentRename:GetHeight()==28 and SpecialTalentRename.heightWrites==1)
          assert(SpecialTalentFrameMinimizeButton.heightWrites==1)
        """)

    def test_recreated_button_with_the_same_name_gets_its_own_adjustment(self):
        h = Harness()
        h.show(20)
        h.execute("previousButton=SpecialTalentFrameNextButtonSmall;addButton('SpecialTalentFrameNextButtonSmall',32)")
        h.show(20)
        h.execute("""
          assert(SpecialTalentFrameNextButtonSmall:GetHeight()==31 and SpecialTalentFrameNextButtonSmall.heightWrites==1)
          assert(previousButton.heightWrites==1 and previousButton:GetHeight()==42)
        """)

    def test_private_cache_does_not_claim_original_button_fields(self):
        h = Harness()
        h.execute("""
          for _,name in ipairs(buttonNames) do
            local b=_G[name]
            b.skinned='original';b.originalHeight=55;b.heightAdjusted='owned';b.skinHeight=73
            b.specialTalentHeightAdjusted='existing';b.__specialTalentHeightAdjusted='existing-private'
          end
        """)
        h.show(25)
        h.execute("""
          for i,name in ipairs(buttonNames) do
            local b=_G[name]
            assert(b:GetHeight()==40+i-1 and b.skinned=='original' and b.originalHeight==55)
            assert(b.heightAdjusted=='owned' and b.skinHeight==73)
            assert(b.specialTalentHeightAdjusted=='existing' and b.__specialTalentHeightAdjusted=='existing-private')
          end
        """)

    def test_later_manual_height_and_skin_font_changes_stay_respected(self):
        h = Harness()
        h.show(1)
        h.execute("SpecialTalentRename:SetHeight(30);C.global.font_size=17")
        h.show(24)
        h.execute("assert(SpecialTalentRename:GetHeight()==30 and SpecialTalentRename.font[2]==17 and SpecialTalentRename.fontWrites==25)")

    def test_pfui_unavailable_then_late_available_does_not_pre_mark_buttons(self):
        h = Harness()
        h.execute("savedPfui=pfUI;pfUI=nil")
        h.show(20)
        h.execute("assert(skinCalls==0 and SpecialTalentRename.heightWrites==0);pfUI=savedPfui")
        h.show(20)
        h.execute("assert(SpecialTalentRename:GetHeight()==45 and SpecialTalentRename.heightWrites==1)")


if __name__ == "__main__":
    if ARGS.baseline_ref:
        baseline = subprocess.run(["git", "show", f"{ARGS.baseline_ref}:{SOURCE}"], cwd=ROOT,
                                  check=True, capture_output=True).stdout.decode("utf-8-sig")
        h = Harness(baseline)
        initial = h.execute("return SpecialTalentFrameApplyButton:GetHeight()")
        h.show(20)
        final = h.execute("return SpecialTalentFrameApplyButton:GetHeight()")
        assert final == initial - 20, (initial, final)
        print(f"Actual Git source reproduced: apply button {initial} -> {final} after 20 OnShow calls.")
    else:
        unittest.main(argv=[sys.argv[0], *REMAINING], verbosity=2)
