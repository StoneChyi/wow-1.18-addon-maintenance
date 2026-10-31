"""Native pfUI navigation, original option persistence and merchant ownership checks."""
from pathlib import Path
import sys
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime
BRIDGE = ROOT / "Interface/AddOns/Automatonex/PfUIBridge.lua"
HOST = ROOT / "Interface/AddOns/pfUI/modules/automation.lua"
MOCK = r'''
local fontInstall = ...
local methods = {}
function obj(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,width=720,height=480,scale=1,shown=false,scripts={},points={},strata="DIALOG"},{__index=methods})
 if name then _G[name]=o end
 return o
end
function invoke(o,k) local old=this;this=o;if o.scripts[k] then o.scripts[k]() end;this=old end
function methods:SetScript(k,f) self.scripts[k]=f end
function methods:GetScript(k) return self.scripts[k] end
function methods:SetParent(p) self.parent=p end
function methods:GetParent() return self.parent end
function methods:SetWidth(n) self.width=n end
function methods:SetHeight(n) self.height=n end
function methods:GetWidth() return self.width end
function methods:GetHeight() return self.height end
function methods:SetScale(n) self.scale=n end
function methods:GetScale() return self.scale end
function methods:SetFrameStrata(s) self.strata=s end
function methods:GetFrameStrata() return self.strata end
function methods:GetNumPoints() return #self.points end
function methods:GetPoint(n) if self.badPoints then return "CENTER" end;return unpack(self.points[n]) end
function methods:SetPoint(a,b,c,d,e) assert(a and b and c and type(d)=="number" and type(e)=="number","invalid old-client anchor");table.insert(self.points,{a,b,c,d,e}) end
function methods:ClearAllPoints() self.points={} end
function methods:GetLeft() if self.badCoords then return nil end;return 40 end
function methods:GetBottom() if self.badCoords then return nil end;return 60 end
function methods:Show() local was=self.shown;self.shown=true;if not was then invoke(self,"OnShow") end end
function methods:Hide() local was=self.shown;self.shown=false;if was then invoke(self,"OnHide") end end
function methods:IsShown() return self.shown end
function methods:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
function methods:SetJustifyH() end
function methods:SetJustifyV() end
function methods:GetStringHeight() return math.max(20,#(self.text or "")/40*16) end
function methods:RegisterEvent(e) self.events=self.events or {};self.events[e]=true end
function methods:SetMovable() end
function methods:Click() invoke(self,"OnClick") end
fontInstall(methods,obj)
-- Force configurable font loading to fail. Template/FontObject initialization
-- still has to precede every FontString SetText in the actual host source.
function methods:SetFont() return nil end
UIParent=obj("Frame","UIParent");UIParent.width=800;UIParent.height=600
function CreateFrame(kind,name,parent) return obj(kind,name,parent) end
now=0
function GetTime() return now end
function GetItemInfo(id) return "Item "..id end
DEFAULT_CHAT_FRAME={AddMessage=function() end}
C={global={autorepair="0",autosell="0"},automation={enabled="1"}}
pfUI_config=C
controls={}
pfUI={gui=obj("Frame","pfConfigGUI",UIParent)}
pfUI.gui.frames={}
function pfUI:RegisterModule(name,version,fn) fn() end
pfUI.automationOptions={}
function pfUI.automationOptions:Suspend() end
function pfUI.automationOptions:Render(parent,module,changed)
 parent.options=module._options;parent.onChanged=changed;parent.renders=(parent.renders or 0)+1
end
-- Navigation/ownership tests use an observable renderer seam. The companion
-- test_pfui_automation_options.py executes the real renderer and native GUI.
function edit(parent,key,value)
 local option=parent.options[key];assert(option, "missing control "..key)
 if option.set then option.set(value) elseif option.func then option.func() end
 parent.onChanged();pfUI.automation.Tick()
end
function pfUI.gui.CreateGUIEntry(parent,title,populate)
 local groups=pfUI.gui.frames
 if not groups[parent] then
  local g=obj("Button",nil,pfUI.gui);g.area=obj("Frame",nil,pfUI.gui)
  g:SetScript("OnClick",function() g.area:Show() end);groups[parent]=g
 end
 local g=groups[parent];local tab=obj("Button",nil,g.area);tab.area=obj("Frame",nil,g.area)
 tab.content=obj("Frame",nil,tab.area)
 tab:SetScript("OnClick",function()
  for k,v in pairs(g) do if type(v)=="table" and v.area and v~=tab then v.area:Hide() end end
  tab.area:Show()
  if not tab.setup then local old=this;this=tab.content;populate();this=old;tab.setup=true end
 end)
 g[title]=tab
end
fallback=true;handoff={};rules={ignore={},custom={}}
pfUI.autovendor={ready=true}
function pfUI.autovendor:ImportLegacyRules() return not failImport end
function pfUI.autovendor:CanOwnLegacy() return self.ready end
function pfUI.autovendor:SetLegacyFallback(v)
 if v==false then assert(not Automaton.modules.Sell.running and not Automaton.modules.Repair.running,"double owner") end
 fallback=v;table.insert(handoff,v and "pause" or "start")
end
function pfUI.autovendor:GetRules() return rules end
function pfUI.autovendor:SetRule(k,id,name) rules[k][tostring(id)]=name;return true end
Automaton={modulePrototype={},db={char={disabledModules={},hiddenModules={}},profile={moduleScope="char"}},modules={},selectedModule="Sell"}
for _,name in ipairs({"Repair","Sell","ExpBar","Tooltip","InterPlayerLink"}) do
 local m={name=name,running=true,enableCount=0,disableCount=0,db={profile={}},_options={old={type="description",name="Legacy option"}},_optionOrder={{key="old",data={}}}}
 function m:OnEnable() self.running=true;self.enableCount=self.enableCount+1 end
 function m:OnDisable() self.running=false;self.disableCount=self.disableCount+1 end
 Automaton.modules[name]=m
end
function Automaton.modulePrototype:RegisterOptions(options)
 self._options=options;self._optionOrder={}
 for key,data in pairs(options) do table.insert(self._optionOrder,{key=key,data=data}) end
end
function Automaton:RefreshModuleSettings() self.legacyRefresh=(self.legacyRefresh or 0)+1 end
function Automaton:GetModuleScope() return self.db.profile.moduleScope end
function Automaton:GetRawDisabledTable(create)
 if not self.rawDisabled and create then self.rawDisabled={} end;return self.rawDisabled
end
function Automaton:IsModuleActive(m)
 local n=type(m)=="table" and m.name or m
 if self:GetModuleScope()=="account" then return not (self.rawDisabled or {})[n] end
 return not self.db.char.disabledModules[n]
end
function Automaton:IsModuleHidden(n) return self.db.char.hiddenModules[n] end
function Automaton:ToggleModuleActive(m,state) local n=type(m)=="table" and m.name or m;if state==nil then state=not self:IsModuleActive(n) end;self.db.char.disabledModules[n]=not state or nil;return state end
function Automaton:CreateMainWindow()
 if self.mainFrame then return end
 local f=obj("Frame","AutomatonMainFrame",UIParent);f:SetPoint("CENTER",UIParent,"CENTER",5,6);f:SetScale(.9)
 for _,k in ipairs({"closeBtn","zoomOutBtn","zoomInBtn","titleBg","titleText"}) do f[k]=obj("Frame",nil,f);f[k]:Show() end
 self.mainFrame=f
end
function Automaton:ToggleMainWindow() self.independentOpens=(self.independentOpens or 0)+1;self:CreateMainWindow();self.mainFrame:Show() end
function Automaton:PopulateModuleList() self.populates=(self.populates or 0)+1 end
function Automaton:SelectModule(n) self.selectedModule=n end
function Automaton:SetUIScale(v) self.mainFrame:SetScale(v) end
function Automaton:RebuildMainWindow() self.mainFrame:Hide();self.mainFrame=nil;self:CreateMainWindow();self.mainFrame:SetPoint("BOTTOMLEFT",UIParent,"BOTTOMLEFT",40,60);self.mainFrame:Show() end
'''

def runtime(host=False):
    lua=LuaRuntime(unpack_returned_tuples=True)
    font=lua.execute((ROOT/"Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf8"))
    lua.execute(MOCK,font)
    import re
    core=(ROOT/"Interface/AddOns/Automatonex/Core.lua").read_text(encoding="utf8")
    scope=re.search(r"function Automaton:ApplyModuleScope\(scope\).*?\nend", core, re.S).group(0)
    lua.execute(scope)
    lua.execute(BRIDGE.read_text(encoding="utf8"))
    lua.globals().hostSource = HOST.read_text(encoding="utf8")
    if host:
        lua.execute(HOST.read_text(encoding="utf8"))
    return lua

checks=0

def check(body, host=False):
    global checks
    lua=runtime(host)
    lua.execute(body)
    checks+=1

check(r'''
local B=AutomatonPfUIBridge;local host={Config=function() return C.automation end,IsEnabled=function() return true end}
assert(B:Acquire(host));assert(C.global.autorepair=="1" and C.global.autosell=="1")
assert(not fallback and not Automaton.modules.Sell.running)
assert(Automaton.db.char.disabledModules.Sell==nil)
assert(Automaton.modules.Sell._optionOrder[2].key=="pfui")
Automaton:ToggleModuleActive("Sell",false)
assert(C.global.autosell=="0" and Automaton.db.char.disabledModules.Sell==nil)
Automaton.modules.Sell:OnEnable();assert(not Automaton.modules.Sell.running)
B:Acquire(host);assert(C.global.autosell=="0","migration reenabled disabled sales")
B:Release();assert(fallback and Automaton.modules.Sell.running)
assert(Automaton.modules.Sell._options.old and Automaton.modules.Sell._optionOrder[1].key=="old")
''')
check(r'''
Automaton.db.char.disabledModules.Sell=true;Automaton.modules.Sell.running=false
local B=AutomatonPfUIBridge;local host={Config=function() return C.automation end}
assert(B:Acquire(host));assert(C.global.autosell=="0")
B:Release();assert(not Automaton.modules.Sell.running and Automaton.db.char.disabledModules.Sell)
''')
check(r'''
failImport=true;local B=AutomatonPfUIBridge
assert(not B:Acquire({Config=function() return C.automation end}));assert(not B.active)
assert(Automaton.modules.Sell.running and not C.automation.merchantMigrated)
''')
check(r'''
Automaton.modules.Sell._optionOrder=nil;local B=AutomatonPfUIBridge
assert(not B:Acquire({Config=function() return C.automation end}));assert(Automaton.modules.Sell.running)
''')
check(r'''
local h=pfUI.automation;Automaton:CreateMainWindow();local f=Automaton.mainFrame
f:Show();h:Sync();Automaton:ToggleMainWindow()
assert(h.pages[h.all] and not f:IsShown())
assert(f:GetParent()==UIParent and f:GetScale()==.9 and f.closeBtn:IsShown())
assert(pfUI.gui:GetWidth()==720 and pfUI.gui:GetHeight()==480 and pfUI.gui:GetScale()==1)
C.automation.enabled="0";h:Sync();Automaton:ToggleMainWindow()
assert(Automaton.independentOpens==1 and f:IsShown() and f:GetParent()==UIParent)
C.automation.enabled="1";h:Sync();assert(not f:IsShown())
assert(AutomatonPfUIBridge.Attach==nil and AutomatonPfUIBridge.Detach==nil)
''',True)
check(r'''
local h=pfUI.automation;h:Sync();h:OpenPage(h.general)
local p=h.pages[h.general]
assert(p.options.enabled.get())
edit(p,"scope","account");assert(Automaton:GetModuleScope()=="account")
edit(p,"scope","char");assert(Automaton:GetModuleScope()=="char")
edit(p,"enabled",false);assert(not h:IsEnabled() and fallback)
edit(p,"open");assert(Automaton.independentOpens==1)
edit(p,"enabled",true);assert(h:IsEnabled() and not fallback)
''',True)
check(r'''
local h=pfUI.automation;h:Sync();h:Open()
local p=h.pages[h.all]
assert(p.options.module.args==Automaton.modules[C.automation.selected]._options)
edit(p,"query","Tooltip")
assert(C.automation.selected=="Tooltip" and p.options.module.args==Automaton.modules.Tooltip._options)
edit(p,"visible",false);assert(Automaton.db.char.hiddenModules.Tooltip)
edit(p,"visibility","hidden");assert(C.automation.selected=="Tooltip")
edit(p,"query","does-not-exist");assert(p.options.empty and not p.options.module)
edit(p,"query","");edit(p,"visibility","all");edit(p,"category","quest")
assert(C.automation.selected=="ExpBar")
assert(not p.options.selected.validate.Repair and not p.options.selected.validate.Sell)
h:SelectModule("Sell");assert(h.pages[h.merchant])
''',True)
check(r'''
local h=pfUI.automation;h:Sync();h:Open()
local p=h.pages[h.all]
edit(p,"selected","Tooltip")
assert(Automaton.db.char.lastModule=="Tooltip" and Automaton.selectedModule=="Tooltip")
local list=h:ModuleList(false);assert(list[#list].name=="Tooltip")
p.options.order.buttons[1].func();p.onChanged();h.Tick()
local moved=h:ModuleList(false);assert(moved[#moved-1].name=="Tooltip")
assert(Automaton.db.char.moduleOrder[#Automaton.db.char.moduleOrder]=="Sell")
''',True)
check(r'''
local h=pfUI.automation;h:Sync();h:OpenVendor();local p=h.pages[h.merchant]
edit(p,"item","123");edit(p,"addKeep");assert(rules.ignore["123"])
edit(p,"addSell");assert(rules.custom["123"])
assert(p.options.ignore.args["123"].buttonText=="移除")
p.options.ignore.args["123"].func();p.onChanged();h.Tick()
assert(not rules.ignore["123"] and rules.custom["123"])
edit(p,"removeSell");assert(not rules.custom["123"])
edit(p,"item","invalid");edit(p,"addSell");assert(next(rules.custom)==nil)
edit(p,"sell",false);assert(C.global.autosell=="0" and not Automaton.modules.Sell.running)
for i=1,500 do rules.custom[tostring(i)]="Long item "..i end
h:RefreshPage(h.merchant);local count=0
for _ in pairs(p.options.custom.args) do count=count+1 end
assert(count==500 and pfUI.gui:GetWidth()==720)
''',True)
check(r'''
local h=pfUI.automation;h:Sync();h:Open();local p=h.pages[h.all]
edit(p,"selected","Tooltip");local before=p.renders
Automaton.modulePrototype.RegisterOptions(Automaton.modules.Tooltip,{new={type="toggle",name="New setting"}})
assert(h.refreshPending);h.Tick()
assert(p.renders>before and p.options.module.args.new)
Automaton:RefreshModuleSettings("Tooltip");h.Tick()
assert(not Automaton.legacyRefresh)
''',True)
check(r'''
local h=pfUI.automation;h:Sync()
local module=Automaton.modules.Sell
Automaton.modulePrototype.RegisterOptions(module,{updated={type="description",name="New legacy options"}})
assert(module._options.pfui and not module._options.updated)
C.automation.enabled="0";h:Sync()
assert(module._options.updated and module.running)
''',True)
check(r'''
local gui=pfUI.gui;pfUI.gui=nil
function pfUI:ShowGUI() self.gui=gui;gui:Show();return true end
assert(loadstring(hostSource))()
local h=pfUI.automation;assert(h:Sync() and not h.guiReady)
Automaton:ToggleMainWindow()
assert(h.guiReady and h.pages[h.all] and not Automaton.mainFrame)
''')
check(r'''
local h=pfUI.automation;local renderer=pfUI.automationOptions
pfUI.automationOptions=nil;h.guiReady=nil
h:Open();assert(h.pendingPage==h.all)
pfUI.automationOptions=renderer;h:BuildGUI()
assert(h.guiReady and h.pendingPage==nil and h.pages[h.all])
''',True)
check(r'''
local h=pfUI.automation;h:Sync();h:Open()
for i=1,100 do h:OpenVendor();h:Open();h:OpenPage(h.general) end
assert(pfUI.gui:GetWidth()==720 and pfUI.gui:GetScale()==1)
local count=0
for _,v in pairs(pfUI.gui.frames[h.title]) do if type(v)=="table" and v.content then count=count+1 end end
assert(count==3,"unbounded tab creation")
h.Tick();assert(h.driver:GetScript("OnUpdate")==nil,"idle polling")
''',True)
check(r'''
local B=AutomatonPfUIBridge;local host={Config=function() return C.automation end}
Automaton.db.char.disabledModules.Sell=true;Automaton.modules.Sell.running=false
assert(B:Acquire(host))
Automaton:ApplyModuleScope("account")
assert(Automaton:GetModuleScope()=="account" and Automaton.rawDisabled.Sell==true)
Automaton:ToggleModuleActive("Sell",true)
assert(C.global.autosell=="1" and Automaton.rawDisabled.Sell==true)
Automaton:ApplyModuleScope("char")
assert(Automaton.db.char.disabledModules.Sell==true)
B:Release();assert(not Automaton.modules.Sell.running)
''')
# Execute the real legacy OnDisable body with its original upvalue contract.
import re
source=(ROOT/"Interface/AddOns/Automatonex/Modules/Sell.lua").read_text(encoding="utf8")
body=re.search(r"function Automaton_Sell:OnDisable\(\)(.*?)\nend", source, re.S).group(1)
lua=runtime()
lua.execute("local sellTimer={junk={1,2},timeSinceLast=5,Hide=function(self) self.hidden=true end}; "
            "local module={UnregisterAllEvents=function(self) self.stopped=true end}; "
            "local function stop(self) "+body+" end; stop(module); "
            "assert(module.stopped and sellTimer.hidden and #sellTimer.junk==0 and sellTimer.timeSinceLast==0)")
checks+=1
print(f"pfUI automation host: {checks} native navigation/lifecycle scenarios passed")
