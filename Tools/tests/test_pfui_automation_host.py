"""pfUI Automaton hosting, ownership and strict-font UI regression checks."""
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
function pfUI.gui.CreateConfig(update,caption,category,key,widget,values)
 controls[caption]={update=update,category=category,key=key,widget=widget,values=values}
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
Automaton={db={char={disabledModules={},hiddenModules={}},profile={moduleScope="char"}},modules={},selectedModule="Sell"}
for _,name in ipairs({"Repair","Sell","ExpBar","Tooltip","InterPlayerLink"}) do
 local m={name=name,running=true,enableCount=0,disableCount=0,db={profile={}},_options={old=true},_optionOrder={{key="old",data={}}}}
 function m:OnEnable() self.running=true;self.enableCount=self.enableCount+1 end
 function m:OnDisable() self.running=false;self.disableCount=self.disableCount+1 end
 Automaton.modules[name]=m
end
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
local B=AutomatonPfUIBridge;local parent=CreateFrame("Frame",nil,UIParent)
local host={content=parent,Config=function() return C.automation end,IsEnabled=function() return true end}
assert(B:Acquire(host));Automaton:CreateMainWindow()
local f=Automaton.mainFrame;assert(f:GetParent()==parent and f:GetScale()==1 and not f.closeBtn:IsShown())
Automaton:SetUIScale(.2);assert(f:GetScale()==1)
Automaton:RebuildMainWindow();assert(Automaton.mainFrame:GetParent()==parent)
B:Release();f=Automaton.mainFrame;assert(f:GetParent()==UIParent and f:GetScale()==.9 and f.closeBtn:IsShown())
assert(f.points[1][1]=="BOTTOMLEFT" and f.points[1][4]==40)
''')
check(r'''
local B=AutomatonPfUIBridge;Automaton:CreateMainWindow();local f=Automaton.mainFrame
f.badPoints=true;f.badCoords=true;B:Attach(CreateFrame("Frame",nil,UIParent));B:Detach()
assert(f.points[1][1]=="CENTER" and f:GetParent()==UIParent)
''')
check(r'''
local h=pfUI.automation;h:Sync();Automaton:ToggleMainWindow()
assert(h.content and Automaton.mainFrame:GetParent()==h.content)
assert(pfUI.gui:GetWidth()==1040 and pfUI.gui:GetScale()<=776/1040)
h:OpenVendor();assert(h.summary and h.summary.font)
local edit=controls["物品 ID"];edit.category[edit.key]="123"
controls["加入保留名单"].values();assert(rules.ignore["123"])
controls["移出保留名单"].values();assert(rules.ignore["123"]==nil)
for i=1,500 do rules.custom[tostring(i)]=string.rep("长名称",12) end
h:RefreshSummary();assert(h.summary:GetParent():GetHeight()>650)
C.automation.enabled="0";h:Sync();assert(h.placeholder:IsShown() and Automaton.mainFrame:GetParent()==UIParent)
C.automation.enabled="1";h:Sync();assert(not h.placeholder:IsShown() and Automaton.mainFrame:GetParent()==h.content)
h:RestoreSize();assert(pfUI.gui:GetWidth()==720 and pfUI.gui:GetScale()==1)
''', True)
check(r'''
local h=pfUI.automation;h:OpenVendor();h:Sync()
assert(not Automaton.modules.Sell.running)
local before=Automaton.db.char.disabledModules
Automaton.modules.Sell._options.enabled.set(false)
assert(C.global.autosell=="0" and Automaton.db.char.disabledModules==before)
assert(Automaton.modules.Sell._optionOrder[2].data==Automaton.modules.Sell._options.pfui)
''', True)
check(r'''
local gui=pfUI.gui;pfUI.gui=nil
function pfUI:ShowGUI() self.gui=gui;gui:Show();return true end
assert(loadstring(hostSource))()
local h=pfUI.automation;assert(h:Sync() and not h.guiReady)
Automaton:ToggleMainWindow()
assert(h.guiReady and h.content and Automaton.mainFrame:GetParent()==h.content)
''')
check(r'''
local h=pfUI.automation;h:Sync();h:Open()
local area=pfUI.gui.frames[h.title].area
assert(pfUI.gui:GetWidth()==1040)
invoke(area,"OnHide");assert(pfUI.gui:GetWidth()==720 and pfUI.gui:GetScale()==1)
invoke(area,"OnShow");assert(pfUI.gui:GetWidth()==1040 and pfUI.gui:GetScale()<1)
''', True)
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
print(f"pfUI automation host: {checks} lifecycle/UI scenarios passed (strict fonts; SetFont fails)")
