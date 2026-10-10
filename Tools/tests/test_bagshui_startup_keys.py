"""Run the startup recorder with real bag hook routing and event queue code.

No client keyboard timing, focus, visibility or addon compatibility is simulated
as evidence of the reported bug being fixed.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

COMP = ROOT / 'Interface/AddOns/Bagshui/Components'


def runtime(before_recorder=''):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
now=0; clockReads=0; bindings=0; initCalls=0; opens=0; queue={}; handlers={}
function GetTime() clockReads=clockReads+1; return now end
function GetBindingAction(key) bindings=bindings+1; assert(key=='B'); return binding or 'TOGGLEBACKPACK' end
function setglobal(key,value) _G[key]=value end
BS_VERSION='1.5.15'; BS_HOOK_ACTION={REGISTER=1,UNREGISTER=2,CHECK=3}
BS_INVENTORY_TYPE={BAGS='Bags'}
BS_INVENTORY_UI_VISIBILITY_ACTION={OPEN='Open',CLOSE='Close',TOGGLE='Toggle'}
Inventory={}
Bagshui={components={},prototypes={Inventory=Inventory},eventConsumers={},
 queuedEvents={events={},class={},classFunction={},arg1={},arg2={},arg3={},arg4={}}}
function Bagshui:AddComponent(fn) fn() end
function Bagshui:LoadComponent(fn) fn() end
function Bagshui:PrintDebug() end
function Bagshui:PrintWarning() error('Unexpected warning') end
Bagshui.eventFrame={bagshuiData={registeredEvents={}}}; function Bagshui.eventFrame:RegisterEvent() end
function Bagshui:OnEvent(event)
 for consumer, events in pairs(self.eventConsumers) do
  if events[event] then consumer[events._eventFunctionName](consumer,event) end
 end
end
BsSlash={}; function BsSlash:AddHandler(key,fn) handlers[key]=fn end
Bagshui.prototypes.ScrollableTextWindow={}
function Bagshui.prototypes.ScrollableTextWindow:New(props)
 assert(props.readOnly and props.selectAllOnFocus)
 function props:Open(text) self.text=text end
 return props
end
local bags={initialized=false,initialInventoryUpdateNeeded=true,
 settings={},myContainerIds={[0]=true},containerIds={},
 hookSettingTranslations={['Backpack$']='hookBag0',['^OpenAllBags$']='hookBag0'}}
function Inventory:New() Bagshui.components.Bags=bags; return bags end
bags._super=Inventory
function Inventory:Open() bags.uiFrame.shown=true; opens=opens+1 end
function Inventory:Close() bags.uiFrame.shown=false end
function bags:Toggle() if self.uiFrame.shown then self:Close() else self:Open() end end
function bags:Visible(action)
 if not self.uiFrame then return false end
 if action then self[action](self) end
 return self.uiFrame:IsVisible()
end
function bags:Init()
 if self.initialized then return end
 initCalls=initCalls+1
 self.hooks=Bagshui.prototypes.Hooks:New({ToggleBackpack='ToggleBag',OpenBackpack='OpenBag',OpenAllBags='ToggleBag'},self)
 self.uiFrame={shown=false}; function self.uiFrame:IsVisible() return self.shown end
 self.ui={frames={searchBox={bagshuiData={hasFocus=false}}}}
 self.initialized=true
end
function OpenBackpack() native=(native or 0)+1 end
function ToggleBackpack() native=(native or 0)+1 end
function OpenAllBags() native=(native or 0)+1 end
''')
    lua.execute((COMP / 'Bagshui.Events.lua').read_text(encoding='utf-8-sig'))
    lua.execute((COMP / 'Hooks.lua').read_text(encoding='utf-8-sig'))
    lua.execute((COMP / 'Bags.lua').read_text(encoding='utf-8-sig'))
    text = (COMP / 'Inventory.Ui.lua').read_text(encoding='utf-8-sig')
    for name in ('OpenCloseToggle', 'GetHookEnabled', 'GetHookSettingName'):
        start = text.index('function Inventory:' + name + '(')
        end = text.index('\nend', start) + len('\nend')
        lua.execute(text[start:end].replace('function Inventory:', 'function Bagshui.components.Bags:', 1))
    if before_recorder:
        lua.execute(before_recorder)
    lua.execute((COMP / 'StartupKeys.lua').read_text(encoding='utf-8'))
    lua.execute('Bags=Bagshui.components.Bags; Keys=Bagshui.components.StartupKeys')
    return lua


cases = [
    ('pre-init snapshot', "Keys:OnEvent('PLAYER_LOGIN'); assert(#Keys.rows==1 and not Bags.uiFrame)"),
    ('single initialization', "Bags:Init(); Bags:Init(); assert(initCalls==1 and #Keys.rows==2)"),
    ('early native binding opens before initial cache', "Bags:Init(); ToggleBackpack(); assert(opens==1 and Bags.initialInventoryUpdateNeeded and #Keys.rows==4)"),
    ('native binding closes', "Bags:Init(); ToggleBackpack(); ToggleBackpack(); assert(not Bags:Visible() and Keys.calls==2)"),
    ('disabled hook passes to native', "Bags:Init(); Bags.settings.hookBag0=false; ToggleBackpack(); assert(native==1 and opens==0)"),
    ('automatic event suppression retained', "Bags:Init(); event='BANKFRAME_OPENED'; Bags.settings.toggleBagsWithBankFrame=false; ToggleBackpack(); assert(opens==0)"),
    ('external wrapper detected without reinstall', "Bags:Init(); local old=ToggleBackpack; ToggleBackpack=function() return old() end; local outer=ToggleBackpack; Keys:Record('check'); assert(string.find(Keys.rows[#Keys.rows],'ToggleBackpack=已变化')); assert(ToggleBackpack==outer)"),
    ('fallback world event and zoning do not duplicate queue', "Keys:OnEvent('PLAYER_ENTERING_WORLD'); local n=0; for _ in pairs(Bagshui.queuedEvents.events) do n=n+1 end; Keys:OnEvent('PLAYER_LOGIN'); Keys:OnEvent('PLAYER_ENTERING_WORLD'); local m=0; for _ in pairs(Bagshui.queuedEvents.events) do m=m+1 end; assert(n==7 and m==7 and #Keys.rows==1)"),
    ('scheduled queue completes with no window opened', "Bags:Init(); Keys:OnEvent('PLAYER_LOGIN'); for _,t in ipairs({0.1,1,2,5,10,30,60}) do now=t; Bagshui:ProcessEventQueue() end; assert(Keys.closed and opens==0 and #Keys.rows==10); assert(not next(Bagshui.queuedEvents.events))"),
    ('closed recorder avoids state reads on hot path', "Bags:Init(); Keys.closed=true; local c,b=clockReads,bindings; ToggleBackpack(); assert(clockReads==c and bindings==b and opens==1)"),
    ('limited entry records', "Bags:Init(); for i=1,20 do ToggleBackpack() end; assert(Keys.calls==12 and #Keys.rows==26)"),
    ('bounded memory', "for i=1,100 do Keys:Record('check') end; assert(#Keys.rows==48)"),
    ('report before initialization', "handlers.keys(); assert(string.find(Keys.window.text,'初始化=false'))"),
    ('report available after stop', "Bags:Init(); Keys.closed=true; now=80; handlers.keys(); assert(string.find(Keys.window.text,'手动查看'))"),
    ('custom bindings and event content not retained', "binding='secret macro text'; event='private chat content'; Keys:Record('check'); handlers.keys(); assert(not string.find(Keys.window.text,'secret macro') and not string.find(Keys.window.text,'private chat'))"),
    ('chat and search states observed without focus mutations', "Bags:Init(); ChatFrameEditBox={IsVisible=function() return true end}; Bags.ui.frames.searchBox.bagshuiData.hasFocus=true; Keys:Record('check'); assert(string.find(Keys.rows[#Keys.rows],'搜索焦点=true') and string.find(Keys.rows[#Keys.rows],'聊天输入框可见=true'))"),
    ('original errors propagate with entry evidence', "Bags:Init(); Inventory.Open=function() error('original failure') end; local ok,err=pcall(ToggleBackpack); assert(not ok and string.find(err,'original failure') and #Keys.rows==3)"),
]
for name, code in cases:
    runtime().execute(code)
runtime(r'''
function Bagshui.components.Bags:OpenCloseToggle(action,api,bag,force)
 assert(action=='Toggle' and api=='ToggleBackpack' and bag==nil and force==false)
 return nil,false,nil,77
end
''').execute(r'''
Bags:Init()
local function check(...)
 assert(select('#',...)==4); local a,b,c,d=...; assert(a==nil and b==false and c==nil and d==77)
end
check(Bags:OpenCloseToggle('Toggle','ToggleBackpack',nil,false))
Keys.closed=true
check(Bags:OpenCloseToggle('Toggle','ToggleBackpack',nil,false))
''')
print(f'{len(cases)+1} startup diagnostic behavior groups passed; client B-key failure remains unconfirmed')
