"""Real automation startup across native module and ordinary chunk environments.

Uses real native GUI constructors, renderer, host and navigation together. The
client boundary is simulated; this is not an in-game startup acceptance test.
"""
from pathlib import Path

from test_pfui_automation_navigation import NAV_MOCK

ROOT = Path(__file__).resolve().parents[2]


def run(navigation_source=None):
    # Borrow client/engine boundary setup only. Replace its synthetic native-tab
    # implementation before any automation source is loaded.
    path = ROOT / "Tools/tests/test_pfui_automation_pages.py"
    source = path.read_text(encoding="utf-8-sig")
    setup = source.split("lua.execute((ROOT/'Interface/AddOns/pfUI/modules/automation_options.lua')", 1)[0]
    namespace = {"__file__": str(path)}
    exec(compile(setup, str(path), "exec"), namespace)
    lua = namespace["lua"]
    lua.execute(NAV_MOCK)
    lua.execute(r'''
local methods=getmetatable(parent).__index
local anchored=methods.SetPoint
function methods:SetPoint(point,relative,relativePoint,x,y)
 -- Native CreateConfig also uses documented parent-relative 3/4-arg forms.
 if type(relative)=='number' then
  return anchored(self,point,self:GetParent(),point,relative,relativePoint)
 elseif type(relativePoint)=='number' then
  return anchored(self,point,relative,point,relativePoint,x)
 end
 return anchored(self,point,relative,relativePoint,x or 0,y or 0)
end
pfUI.env=setmetatable({}, {__index=_G})
pfUI.module={};pfUI.modules={};pfUI.bootup=true;pfUI.expansion='vanilla'
pfUI_locale={enUS={}}
function GetLocale() return 'enUS' end
-- C exists only in registered-module environments, exactly as during startup.
C=nil
assert(rawget(_G,'C')==nil)
function runOrdinary(source,name)
 local chunk=assert(loadstring(source,'@'..name))
 local plain=setmetatable({}, {__index=function(_,key)
  if key=='C' then error(name..' read unavailable module-local C') end
  return _G[key]
 end})
 setfenv(chunk,plain);chunk()
end
''')
    core = (ROOT / "Interface/AddOns/pfUI/pfUI.lua").read_text(encoding="utf-8-sig")
    start = core.index("local translations\nfunction pfUI:GetEnvironment()")
    end = core.index("function pfUI:RegisterSkin", start)
    load_start = core.index("function pfUI:LoadModule(")
    load_end = core.index("function pfUI:LoadSkin(", load_start)
    lua.execute(core[start:end] + core[load_start:load_end])
    gui = (ROOT / "Interface/AddOns/pfUI/modules/gui.lua").read_text(encoding="utf-8-sig")
    start = gui.index("    function CreateConfig(")
    end = gui.index("  do -- GUI Frame", start)
    native = ("do local searchDB={}\n" + gui[start:end]
              + "\npfUI.gui.CreateGUIEntry=CreateGUIEntry;pfUI.gui.CreateConfig=CreateConfig")
    lua.execute(r'''
local chunk=assert(loadstring(...,'@native_gui_constructors.lua'))
setfenv(chunk,pfUI:GetEnvironment());chunk()
assert(getfenv(pfUI.gui.CreateGUIEntry).C==pfUI_config and rawget(_G,'C')==nil)
''', native)
    for name in ("automation_options", "automation_navigation", "automation"):
        code = (ROOT / f"Interface/AddOns/pfUI/modules/{name}.lua").read_text(encoding="utf-8-sig")
        if name == "automation_navigation" and navigation_source is not None:
            code = navigation_source
        lua.globals().runOrdinary(code, name)
    lua.execute(r'''
assert(not pfUI.automation,'registered module executed before bootstrap')
assert(pfUI.automationOptions and pfUI.automationNavigation)
pfUI:LoadModule('automation')
local h=pfUI.automation
assert(h.guiReady and h.navigation and rawget(_G,'C')==nil)
assert(getfenv(pfUI.module.automation).C==pfUI_config)
assert(getfenv(pfUI.automationNavigation.Attach)~=getfenv(pfUI.module.automation))
h:Sync();h.Tick()
local s=h.navigation
assert(#s.entries==2 and #s.filtered==2)
assert(not h.lastRenderError)
local function selectFromSidebar(id)
 pfUI.automationNavigation:EnsureVisible(h,id)
 for _,button in ipairs(s.rows) do
  if button.entry and button.entry.name==id then
   button:Click();current(h.detail)
   assert(h.selectedModule==id and h.activePage==h.detail)
   assert(h.pages[h.detail]:IsVisible() and #rows()>0 and not h.lastRenderError)
   assert(rowName('Text '..id):IsShown())
   return
  end
 end
 error('missing sidebar module '..id)
end
selectFromSidebar('Tooltip')
rowName('Text Tooltip').input:SetText('bootstrap tooltip draft')
selectFromSidebar('QuestAutomation')
assert(values.Tooltip=='bootstrap tooltip draft','sidebar navigation discarded draft')
rowName('Text QuestAutomation').input:SetText('bootstrap quest draft')
s.manage:Click();current(h.general)
assert(values.QuestAutomation=='bootstrap quest draft')
assert(h.activePage==h.general and parent:IsVisible() and rowName('模块排序'):IsShown())
s.merchant:Click();current(h.merchant)
assert(h.activePage==h.merchant and parent:IsVisible() and rowName('自动修理'):IsShown())
rowName('自动修理').input:SetChecked(1);click(rowName('自动修理'));tick()
assert(pfUI_config.global.autorepair=='1')
s.manage:Click();current(h.general)
assert(rowName('查找模块'):IsShown() and not h.lastRenderError)
selectFromSidebar('Tooltip')
assert(rowName('Text Tooltip').input:GetText()=='bootstrap tooltip draft')
selectFromSidebar('QuestAutomation')
assert(rowName('Text QuestAutomation').input:GetText()=='bootstrap quest draft')
assert(rawget(_G,'C')==nil,'integration test leaked module C into global scope')
''')


def main():
    run()
    print("PASS: isolated real module bootstrap + ordinary helper/renderer + native tabs; sidebar module and management/merchant clicks; drafts/configuration preserved")
    # Sensitivity check: recreate the original ordinary-chunk/module-local C
    # mistake and require failure during startup, before any navigation click.
    path = ROOT / "Interface/AddOns/pfUI/modules/automation_navigation.lua"
    code = path.read_text(encoding="utf-8-sig")
    original = "local config = pfUI_config"
    assert original in code
    try:
        run(code.replace(original, "local config = C", 1))
    except Exception as error:
        assert "automation_navigation read unavailable module-local C" in str(error), str(error)
    else:
        raise AssertionError("bootstrap fixture failed to detect original global-C startup fault")
    print("PASS: regression negative control rejects module-local C access at bootstrap")


if __name__ == "__main__":
    main()
