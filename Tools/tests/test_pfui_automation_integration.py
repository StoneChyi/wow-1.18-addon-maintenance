"""Exercise actual pfUI vendor + Automatonex merchant modules + ownership bridge.

Only AceDB/ModuleCore dispatch and the native game boundary are mocked. Both
merchant implementations, migration, queue shutdown and bridge run unchanged.
"""
from pathlib import Path
import hashlib
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from test_pfui_autovendor_merge import MOCK

FILES = [
    'Interface/AddOns/pfUI/modules/autovendor.lua',
    'Interface/AddOns/Automatonex/Modules/Repair.lua',
    'Interface/AddOns/Automatonex/Modules/Sell.lua',
    'Interface/AddOns/Automatonex/PfUIBridge.lua',
]

ACE_MOCK = r"""
floor=math.floor;TOOLTIP_UPDATE_TIME=.1
ITEM_QUALITY_COLORS={[0]={hex='|cff9d9d9d'}}
pfUI_config=C;hostConfig={};lifecycle={};actors={};moduleCalls={Repair=0,Sell=0};actor='test'
local oldRepair=RepairAllItems
function RepairAllItems() table.insert(actors,'repair:'..actor);oldRepair() end
local oldUse=UseContainerItem
function UseContainerItem(bag,slot) table.insert(actors,'sale:'..actor);oldUse(bag,slot) end
function PickupContainerItem(bag,slot) pickup={bag,slot};cursor=true end
function MerchantItemButton_OnClick(button)
 assert(button=='LeftButton' and pickup)
 cursor=false;UseContainerItem(pickup[1],pickup[2]);pickup=nil
end
function GetItemInfo(id) return 'item '..id end
function AceLibrary(name)
 assert(name=='AceLocale-2.2')
 return {new=function()
  return setmetatable({RegisterTranslations=function() end},{__index=function(_,k)return k end})
 end}
end
local moduleMethods={}
function moduleMethods:RegisterEvent(name)
 if traceHandoff and pfUI.autovendor then
  assert(not pfUI.autovendor:CanExecute(),'old handler enabled while pfUI still owns merchant')
 end
 self.events[name]=true;table.insert(lifecycle,'register:'..self.name..':'..name)
end
function moduleMethods:UnregisterAllEvents()
 if traceHandoff and pfUI.autovendor and next(self.events) then
  assert(not pfUI.autovendor:CanExecute(),'old handler stopped after new owner granted')
 end
 self.events={};table.insert(lifecycle,'stop:'..self.name)
end
function moduleMethods:RegisterOptions(options)
 self._options=options;self._optionOrder={}
end
function moduleMethods:Print(text) DEFAULT_CHAT_FRAME:AddMessage(text) end
function installEngine()
 local A={modules={},namespaces={Sell={profile=legacy}},db={char={disabledModules={}}}}
 function A:NewModule(name)
  local m=setmetatable({name=name,events={}},{__index=moduleMethods});self.modules[name]=m;return m
 end
 function A:AcquireDBNamespace(name)
  if not self.namespaces[name] then self.namespaces[name]={profile={}} end
  return self.namespaces[name]
 end
 function A:RegisterDefaults(name,scope,defaults)
  assert(scope=='profile')
  local db=self:AcquireDBNamespace(name).profile
  for k,v in pairs(defaults) do if db[k]==nil then db[k]=type(v)=='table' and {} or v end end
 end
 function A:SetDisabledAsDefault() end
 function A:IsModuleActive(module)
  local name=type(module)=='table' and module.name or module
  return not self.db.char.disabledModules[name]
 end
 function A:ToggleModuleActive(module,state)
  local name=type(module)=='table' and module.name or module
  if state==nil then state=not self:IsModuleActive(name) end
  self.db.char.disabledModules[name]=not state or nil
  if state then self.modules[name]:OnEnable() else self.modules[name]:OnDisable() end
 end
 function A:ToggleMainWindow() end
 function A:CreateMainWindow() end
 Automaton=A
end
host={Config=function()return hostConfig end,IsEnabled=function()return true end,
 OpenVendor=function()end,Open=function()end}
function initializeModules()
 for _,name in ipairs({'Repair','Sell'}) do
  local m=Automaton.modules[name];m:OnInitialize()
  if Automaton:IsModuleActive(name) then m:OnEnable() end
 end
 for _,o in ipairs(objects) do
  if o.timeSinceLast~=nil then legacyTimer=o end
 end
end
function acquire()
 assert(pfUI.autovendor:ImportLegacyRules())
 traceHandoff=true
 assert(AutomatonPfUIBridge:Acquire(host))
end
function dispatch(e,legacyFirst)
 local function oldHandlers()
  if not Automaton then return end
  for _,name in ipairs({'Repair','Sell'}) do
   local m=Automaton.modules[name]
   if m and m.events[e] then
    actor='legacy '..name;moduleCalls[name]=moduleCalls[name]+1;m[e](m)
   end
  end
 end
 local function newHandler()
  if pfUI.autovendor and pfUI.autovendor.frame.events[e] then
   actor='pfUI';event=e;invoke(pfUI.autovendor.frame,'OnEvent');event=nil
  end
 end
 if legacyFirst then oldHandlers();newHandler() else newHandler();oldHandlers() end
 actor='test'
end
function merchantOpen(legacyFirst)
 MerchantFrame.shown=true;dispatch('MERCHANT_SHOW',legacyFirst)
end
function merchantClose()
 MerchantFrame.shown=false;dispatch('MERCHANT_CLOSED')
end
function tickAll()
 now=now+.2;arg1=.2
 for _,o in ipairs(objects) do
  if o.shown and o.scripts.OnUpdate then
   actor=(pfUI.autovendor and o==pfUI.autovendor.frame) and 'pfUI' or 'legacy timer'
   invoke(o,'OnUpdate')
  end
 end
 actor='test';arg1=nil
end
function freeze(t)
 if type(t)~='table' then return tostring(t) end
 local keys={};for k in pairs(t) do table.insert(keys,k) end
 table.sort(keys,function(a,b)return tostring(a)<tostring(b)end)
 local result='';for _,k in ipairs(keys) do result=result..tostring(k)..'='..freeze(t[k])..';' end
 return '{'..result..'}'
end
"""


class IntegrationTests(unittest.TestCase):
    def load(self, path):
        self.lua.execute((ROOT / path).read_text(encoding='utf-8-sig'))

    def fresh(self, setup='', vendor_first=False, initialized=True):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        contract=self.lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
        contract(self.lua.globals().mockMethods,self.lua.globals().newObject)
        self.lua.execute("MerchantRepairText=newObject('FontString','MerchantRepairText');MerchantRepairText:SetFontObject(GameFontNormal)")
        self.lua.execute(ACE_MOCK)
        if vendor_first:
            self.lua.execute('Automaton=nil')
            self.load(FILES[0])
        self.lua.execute('installEngine()')
        self.lua.execute(setup)
        self.load(FILES[1]);self.load(FILES[2]);self.load(FILES[3])
        if initialized:
            self.lua.execute('initializeModules()')
        if not vendor_first:
            self.load(FILES[0])

    def check(self, code):
        self.lua.execute(code)

    def test_single_event_only_pfui_executes_in_both_dispatch_orders(self):
        for order in ('true','false'):
            with self.subTest(legacy_first=order):
                self.fresh("bags[1]=item(1,0)")
                self.check("acquire();merchantOpen("+order+");tickAll()")
                self.check("""
                assert(repairs==1 and #sales==1)
                assert(moduleCalls.Repair==0 and moduleCalls.Sell==0)
                assert(actors[1]=='repair:pfUI' and actors[2]=='sale:pfUI')
                """)

    def test_preexisting_legacy_queue_is_drained_before_pfui_ownership(self):
        self.fresh("bags[1]=item(1,0);bags[2]=item(2,0)")
        self.check("""
        merchantOpen(true);assert(legacyTimer.shown and #legacyTimer.junk==2)
        assert(not pfUI.autovendor:CanExecute())
        acquire();assert(not legacyTimer.shown and #legacyTimer.junk==0)
        tickAll();tickAll();assert(#sales==2 and repairs==1)
        assert(actors[1]=='repair:legacy Repair')
        assert(actors[2]=='sale:pfUI' and actors[3]=='sale:pfUI')
        """)

    def test_release_stops_pfui_before_restoring_only_saved_enabled_modules(self):
        self.fresh("Automaton.db.char.disabledModules.Repair=true;bags[1]=item(1,0);bags[2]=item(2,0)")
        self.check("""
        local snapshot=freeze(Automaton.db.char.disabledModules)
        acquire();merchantOpen();tickAll();assert(#sales==1)
        AutomatonPfUIBridge:Release()
        assert(not pfUI.autovendor:CanExecute() and not pfUI.autovendor.frame.shown)
        assert(not Automaton.modules.Repair.events.MERCHANT_SHOW)
        assert(Automaton.modules.Sell.events.MERCHANT_SHOW)
        tickAll();assert(#sales==1)
        merchantClose();repairCost=100;merchantOpen();tickAll()
        assert(#sales==2 and repairs==1)
        assert(actors[#actors]=='sale:legacy timer')
        assert(snapshot==freeze(Automaton.db.char.disabledModules))
        """)

    def test_both_disabled_legacy_modules_stay_disabled_on_release(self):
        self.fresh("Automaton.db.char.disabledModules={Repair=true,Sell=true};C.global.autorepair='0';C.global.autosell='0'")
        self.check("""
        acquire();assert(C.global.autorepair=='0' and C.global.autosell=='0')
        AutomatonPfUIBridge:Release()
        assert(not Automaton.modules.Sell.events.MERCHANT_SHOW)
        assert(not Automaton.modules.Repair.events.MERCHANT_SHOW)
        """)

    def test_pfui_before_automaton_and_repeated_acquire_no_repeat_repair(self):
        self.fresh("bags[1]=item(1,0)", vendor_first=True)
        self.check("""
        dispatch('ADDON_LOADED');assert(pfUI.autovendor.ready)
        acquire();merchantOpen();acquire();acquire();tickAll()
        assert(repairs==1 and #sales==1 and moduleCalls.Repair==0 and moduleCalls.Sell==0)
        """)

    def test_uninitialized_legacy_modules_refuse_handoff(self):
        self.fresh("bags[1]=item(1,0)", initialized=False)
        self.check("""
        assert(pfUI.autovendor:ImportLegacyRules())
        assert(not AutomatonPfUIBridge:Acquire(host))
        assert(not pfUI.autovendor:CanExecute())
        assert(not next(AutomatonPfUIBridge.leases))
        initializeModules();acquire();merchantOpen();tickAll();assert(#sales==1 and repairs==1)
        """)

    def test_failed_migration_does_not_stop_legacy_handlers(self):
        self.fresh()
        self.check("""
        C.autovendor_rules={ignore={},custom={}}
        legacy.custom[1]='historical array';pfUI.autovendor.ready=false
        assert(not pfUI.autovendor:ImportLegacyRules())
        assert(not AutomatonPfUIBridge:Acquire(host))
        assert(Automaton.modules.Sell.events.MERCHANT_SHOW and Automaton.modules.Repair.events.MERCHANT_SHOW)
        assert(not next(AutomatonPfUIBridge.leases))
        """)

    def test_original_lists_and_disabled_states_survive_toggle_acquire_release(self):
        self.fresh("legacy.ignore['1']='keep';legacy.custom['2']='white';Automaton.db.char.disabledModules.ProcDoc=true")
        self.check("""
        local original=freeze(legacy);local disabled=freeze(Automaton.db.char.disabledModules)
        acquire();pfUI.autovendor:SetRule('custom',2,nil)
        Automaton:ToggleModuleActive('Sell',false)
        assert(C.global.autosell=='0' and not Automaton.modules.Sell.events.MERCHANT_SHOW)
        Automaton:ToggleModuleActive('Repair',false)
        AutomatonPfUIBridge:Release();acquire();AutomatonPfUIBridge:Release()
        assert(freeze(legacy)==original and freeze(Automaton.db.char.disabledModules)==disabled)
        assert(C.autovendor_rules.custom['2']==nil and C.autovendor_rules.edited['2'])
        """)

    def test_leased_onenable_cannot_rearm_old_queue(self):
        self.fresh("bags[1]=item(1,0)")
        self.check("""
        acquire();traceHandoff=false
        Automaton.modules.Sell:OnEnable();Automaton.modules.Repair:OnEnable()
        assert(not Automaton.modules.Sell.events.MERCHANT_SHOW and not Automaton.modules.Repair.events.MERCHANT_SHOW)
        merchantOpen();tickAll();assert(#sales==1 and repairs==1)
        """)


if __name__=='__main__':
    for relative in FILES:
        path=ROOT/relative
        print(relative, 'mtime_ns='+str(path.stat().st_mtime_ns), 'sha256='+hashlib.sha256(path.read_bytes()).hexdigest(), flush=True)
    unittest.main(verbosity=2)
