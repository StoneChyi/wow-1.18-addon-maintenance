"""Real Superwow lifecycle and settings; no DLL or game actions are invoked."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil
SUPERWOW_VERSION='test';pfUI={};pfUI_config={}
Automaton={modules={},dbs={},savedActive=false}
function Automaton:NewModule(name)
 local m={name=name,events={},hooks={}};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(name,handler)self.events[name]=handler or name end
 function m:UnregisterAllEvents()self.events={}end
 function m:Hook(name)self.hooks[name]=function()end end
 return m
end
function Automaton:AcquireDBNamespace(name)
 self.dbs[name]=self.dbs[name]or{profile={}};return self.dbs[name]
end
function Automaton:RegisterDefaults(name,scope,defaults)
 local target=self.dbs[name][scope]
 for key,value in pairs(defaults)do if target[key]==nil then target[key]=value end end
end
function Automaton:SetDisabledAsDefault()end
function Automaton:IsModuleActive()return self.savedActive end
function AceLibrary()
 return {new=function()return setmetatable({RegisterTranslations=function(self,locale,fn)
  if locale=='enUS'then for key,value in pairs(fn())do self[key]=value==true and key or value end end
 end},{__index=function(_,key)return key end})end}
end
frames={};writes={};autoloot=0;shift=false;cvars={}
function CreateFrame(kind)
 assert(kind=='Frame')
 local f={scripts={},shown=true}
 function f:SetScript(event,fn)self.scripts[event]=fn end
 function f:Show()self.shown=true end
 function f:Hide()self.shown=false end
 frames[#frames+1]=f;return f
end
function SetAutoloot(value)
 if value==nil then
  if readFail then error('getter failed')end
  if invalidRead then return 'unknown'end
  if booleanRead then return autoloot==1 end
  return autoloot
 end
 assert(value==0 or value==1)
 if writeFail then error('setter failed')end
 writes[#writes+1]=value
 if not ignoredWrite then autoloot=value end
 return autoloot
end
function SetCVar(name,value)cvars[name]=value end
function GetCVar(name)return cvars[name]end
function Clickthrough(value)clickthrough=value end
function IsShiftKeyDown()return shift end
function tick(count)
 for i=1,count or 1 do
  for _,frame in ipairs(frames)do
   if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate()end
  end
 end
end
function active(value)
 -- Match Core: lifecycle sees the PREVIOUS saved state.
 if value then M:OnEnable()else M:OnDisable()end
 Automaton.savedActive=value
end
'''


def runtime(saved=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    if saved:
        lua.execute(saved)
    lua.execute((ROOT / "Interface/AddOns/Automatonex/Modules/Superwow.lua").read_text(encoding="utf-8"))
    lua.execute("M=Automaton.modules.Superwow;if M then M:OnInitialize()end")
    return lua


class SuperwowLoot(unittest.TestCase):
    def test_enabled_disabled_lifecycle_restores_original_state(self):
        lua = runtime()
        lua.execute(r'''
assert(not Automaton.savedActive);active(true)
assert(autoloot==1 and M.autolootManaged and M.autolootActive)
assert(M.autolootPrevious==0)
active(false);assert(autoloot==0 and not M.autolootManaged and not M.autolootActive)
local count=#writes;tick(10);M:OnDisable();assert(#writes==count)
autoloot=1;M.db.profile.autoloot=false;active(true)
assert(autoloot==0 and M.autolootManaged)
active(false);assert(autoloot==1)
''')

    def test_disabled_option_edits_only_save_preferences(self):
        lua = runtime()
        lua.execute(r'''
M.options.shiftloot.set(true);assert(M.db.profile.shiftloot and not M.db.profile.autoloot)
M.options.autoloot.set(true);assert(M.db.profile.autoloot and not M.db.profile.shiftloot)
M:TurnOnAutoloot();assert(#writes==0 and not M.autolootManaged and #frames==0)
active(true);active(false);local n=#writes
M.options.shiftloot.set(true);tick(10);assert(#writes==n)
active(true);assert(autoloot==0 and M.autolootManaged)
''')

    def test_shift_mode_only_writes_changes_and_preserves_direction(self):
        lua = runtime("Automaton.dbs.Superwow={profile={autoloot=false,shiftloot=true}}")
        lua.execute(r'''
active(true);assert(autoloot==0 and M.f and #frames==1)
local count=#writes;tick(100);assert(#writes==count)
shift=true;tick();assert(autoloot==1 and #writes==count+1)
tick(100);assert(#writes==count+1)
shift=false;tick();assert(autoloot==0 and #writes==count+2)
active(false);assert(not M.f.shown and not M.f.scripts.OnUpdate)
shift=true;count=#writes;tick(100);assert(#writes==count)
''')

    def test_mode_changes_reuse_frame_and_original_baseline(self):
        lua = runtime()
        lua.execute(r'''
active(true);M.options.shiftloot.set(true);local frame=M.f
shift=true;tick();assert(autoloot==1)
M.options.autoloot.set(true);assert(not M.db.profile.shiftloot and not frame.shown)
M.options.autoloot.set(false);assert(autoloot==0 and M.autolootManaged)
M.options.shiftloot.set(true);assert(M.f==frame and #frames==1 and autoloot==1)
assert(M.autolootPrevious==0);active(false);assert(autoloot==0)
active(true);assert(M.f==frame and #frames==1)
active(true);assert(M.autolootPrevious==0)
''')

    def test_absent_or_unreadable_capability_does_not_acquire(self):
        for setup in ("SetAutoloot=nil", "readFail=true", "invalidRead=true"):
            with self.subTest(setup=setup):
                lua = runtime(setup)
                lua.execute(r'''
M.db.profile.shiftloot=true;active(true)
assert(not M.autolootManaged and not M.autolootPrevious and #writes==0 and #frames==0)
active(false)
''')

    def test_write_failure_and_missing_api_stop_polling(self):
        lua = runtime()
        lua.execute(r'''
M.db.profile.shiftloot=true;active(true);local frame=M.f
writeFail=true;shift=true;tick()
assert(not M.autolootManaged and not frame.shown and not frame.scripts.OnUpdate)
writeFail=false;M:TurnOnAutoloot();assert(M.autolootManaged and autoloot==1)
SetAutoloot=nil;shift=false;tick()
assert(not M.autolootManaged and not frame.shown and not frame.scripts.OnUpdate)
active(false)
''')

    def test_ignored_setter_is_not_treated_as_owned(self):
        lua = runtime("ignoredWrite=true")
        lua.execute("active(true);assert(autoloot==0 and not M.autolootManaged);active(false)")

    def test_boolean_getter_and_external_owner_are_preserved(self):
        lua = runtime("booleanRead=true")
        lua.execute(r'''
active(true);assert(M.autolootPrevious==0 and autoloot==1)
autoloot=0 -- a different provider writes after this module
local n=#writes;active(false);assert(#writes==n and autoloot==0)
active(true);active(false);assert(autoloot==0)
''')

    def test_saved_namespace_and_unrelated_settings_survive(self):
        lua = runtime(r'''
Automaton.dbs.Superwow={profile={autoloot=false,shiftloot=true,autoopen_custom={['5523']=true},nameplatemotion=3}}
saved=Automaton.dbs.Superwow;custom=saved.profile.autoopen_custom
''')
        lua.execute(r'''
active(true);active(false)
assert(M.db==saved and M.db.profile.autoopen_custom==custom)
assert(M.db.profile.nameplatemotion==3 and cvars.NameplateMotion=='0')
assert(not M.db.profile.autoloot and M.db.profile.shiftloot)
''')

    def test_missing_superwow_leaves_module_unregistered(self):
        lua = runtime("SUPERWOW_VERSION=nil")
        lua.execute("assert(not M and #writes==0)")


if __name__ == "__main__":
    unittest.main(verbosity=2)
