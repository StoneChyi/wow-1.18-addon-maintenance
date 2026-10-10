"""Exercise diagnostics with the actual Bagshui update, UI and event queue paths.

Controlled clocks/UI stand-ins verify attribution and behavior, not game FPS.
Uses the existing ignored Lua 5.1 test runtime.
"""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = ROOT / 'Interface/AddOns/Bagshui'
PRELUDE = r'''
now=100; milliseconds=1000; clockCalls=0; messages={}; frames={}
function GetTime() return now end
function debugprofilestop() clockCalls=clockCalls+1; return milliseconds end
function cost(ms) milliseconds=milliseconds+ms end
function PlaySound() end
function CreateFrame()
 local frame={shown=true, scripts={}}
 function frame:SetScript(key, fn) self.scripts[key]=fn end
 function frame:Show() self.shown=true end
 function frame:Hide() self.shown=false end
 table.insert(frames,frame); return frame
end
BS_VERSION='1.5.15'; BS_INVENTORY_TYPE_UI_ORDER={'Bags','Bank','Keyring'}
BS_INVENTORY_UI_VISIBILITY_ACTION={OPEN='Open'}
Bagshui={prototypes={Inventory={}},components={},queuedEvents={events={},class={},classFunction={},arg1={},arg2={},arg3={},arg4={}}}
function Bagshui:AddComponent(fn) fn() end
function Bagshui:LoadComponent(fn) fn() end
function Bagshui:RaiseEvent() end
function Bagshui:Print(message) table.insert(messages,message) end
function Bagshui:PrintError(message) error(message) end
BsSlash={handlerList={}}
function BsSlash:AddHandler(key,fn) self.handlerList[string.lower(key)]=fn end
function command(action) BsSlash.handlerList.perf({'perf',action}) end
L={}
BsItemInfo={}
function BsItemInfo:GetTooltip(item, inventory, force)
 cost(3); return nil, item, nil, force
end
Inventory=Bagshui.prototypes.Inventory
function Inventory:Visible() return self.uiFrame.shown end
function Inventory:UpdateOnlineStatus() self.online = self.inventoryType~='Bank' or self.atBank end
function Inventory:NotifySkinOfPositionChange() end
function Inventory:SetDockedToFrameVisibility() end
function makeInventory(id)
 local inv=setmetatable({inventoryType=id,initialized=true,settings={},events={},myContainerIds={[0]=true},
  containers={[0]={numSlots=20,slotsFilled=12}},online=true, inventoryUpdateAllowed=true}, {__index=Inventory})
 inv._super=Inventory
 inv.uiFrame={shown=false}
 function inv.uiFrame:IsVisible() return self.shown end
 function inv.uiFrame:Show()
  if not self.shown then self.shown=true; inv:UiFrame_OnShow() end
 end
 function inv.uiFrame:Raise() end
 Bagshui.components[id]=inv
 return inv
end
Bags=makeInventory('Bags'); Bank=makeInventory('Bank'); Keyring=makeInventory('Keyring')
Bagshui.prototypes.ScrollableTextWindow={}
function Bagshui.prototypes.ScrollableTextWindow:New(props)
 function props:Open(text) self.text=text end
 return props
end
'''


def extract(relative, name, following):
    source = (ADDON / relative).read_text(encoding='utf-8-sig')
    return 'function ' + name + source.split('function ' + name, 1)[1].split('function ' + following, 1)[0]


def runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(PRELUDE)
    lua.execute((ADDON / 'Components/Bagshui.Events.lua').read_text(encoding='utf-8-sig'))
    lua.execute((ADDON / 'Components/Inventory.Layout.lua').read_text(encoding='utf-8-sig'))
    lua.execute((ADDON / 'Components/Inventory.Ui.lua').read_text(encoding='utf-8-sig'))
    lua.execute(extract('Components/Inventory.lua', 'Inventory:QueueUpdate(', 'Inventory:OnEvent('))
    lua.execute(extract('Components/Inventory.lua', 'Inventory:OnEvent(', 'Inventory:UpdateOnlineStatus('))
    lua.execute(extract('Components/Bank.lua', 'Bank:Open(', 'Bank:Close('))
    lua.execute(r'''
local Inventory=Bagshui.prototypes.Inventory
function Inventory:NotifySkinOfPositionChange() end
function Inventory:SetDockedToFrameVisibility() end
function Inventory:UpdateCache()
 cost(2)
 if self.cacheUpdateNeeded then BsItemInfo:GetTooltip('dummy',self) end
 self.cacheUpdateNeeded=false; self.forceCacheUpdate=false
end
function Inventory:ValidateLayout() cost(1) end
function Inventory:ManageDryRun() cost(1) end
function Inventory:UpdateLayoutLookupTables() cost(2) end
function Inventory:CategorizeItems() cost(5) end
function Inventory:SortGroups() cost(4) end
function Inventory:FindSpecialItems() cost(1) end
function Inventory:UpdateWindow() cost(6); self.windowUpdateNeeded=false end
function Inventory:UpdateBagBar() cost(1) end
function Inventory:UpdateToolbar() cost(1) end
function Bags:Open() self._super.Open(self) end
''')
    lua.execute((ADDON / 'Components/Performance.lua').read_text(encoding='utf-8-sig'))
    lua.execute('P=Bagshui.components.Performance')
    return lua


CHECKS = []


def check(name, script):
    lua = runtime()
    lua.execute(script)
    CHECKS.append(name)


check('default-off path performs no clock reads or recording', r'''
local update=Bags.Update
Bags:Open(); assert(clockCalls==0 and not P.enabled and P.startedAt==nil)
assert(next(P.inventories)==nil and #frames==0 and Bags.Update==update)
assert(Bags.uiFrame.shown and not Bags.windowUpdateBlocked)
''')
check('real open pipeline attribution and nested times', r'''
command('on'); Bags:Open()
local d=P.inventories.Bags; local s=P.opens[1]
assert(d.updates==1 and d.redraws==1 and #P.opens==1)
assert(s.slots==20 and s.items==12 and s.online)
assert(d.stats.Update.total==28 and d.stats.Update.own==0)
assert(d.stats.UpdateCache.total==5 and d.stats.UpdateCache.own==2)
assert(d.stats.GetTooltip.total==3 and d.stats.GetTooltip.calls==1)
assert(d.stats.CategorizeItems.total==5 and d.stats.SortGroups.total==4)
assert(d.stats.ManageDryRun.calls==2)
assert(s.stats.UiFrame_OnShow.total==28)
''')
check('events use actual debounce queue and record follow-up refresh', r'''
command('on'); event='BANKFRAME_OPENED'; Bank.events.BANKFRAME_OPENED='Open'
Bank:OnEvent('BANKFRAME_OPENED')
local d=P.inventories.Bank
assert(d.updates==1 and d.skipped==1 and d.queues==1)
assert(d.events.BANKFRAME_OPENED==1 and P.opens[1].updates==1)
local callbacks=0
for _,fn in pairs(Bagshui.queuedEvents.classFunction) do assert(fn==Bank.Update); callbacks=callbacks+1 end
assert(callbacks==1)
now=now+0.08; Bagshui:ProcessEventQueue()
assert(d.updates==2 and P.opens[1].updates==2)
assert(next(Bagshui.queuedEvents.events)==nil)
''')
check('toggles preserve callback identities and pending callbacks', r'''
local update=Bags.Update
command('on'); Bags:Open(); Bags:QueueUpdate(); command('off')
local reads=clockCalls; now=now+0.1; Bagshui:ProcessEventQueue()
assert(clockCalls==reads and Bags.Update==update)
command('on'); Bags:QueueUpdate(); command('on'); command('off'); command('on')
assert(Bags.Update==update)
now=now+0.1; Bagshui:ProcessEventQueue()
assert(P.inventories.Bags.updates==1 and next(Bagshui.queuedEvents.events)==nil)
''')
check('on/off forwards every argument and nil return slot', r'''
local owner={test=function(...) assert(arg.n==6); return nil,arg[2],nil,arg[6],nil end}
P:Wrap(owner,'test')
local function pack(...) return arg end
for _,mode in ipairs({'off','on'}) do
 command(mode)
 local r=pack(owner.test(Bags,'a',nil,'b',nil,'z'))
 assert(r.n==5 and r[1]==nil and r[2]=='a' and r[3]==nil and r[4]=='z' and r[5]==nil)
end
''')
check('errors retain identity and clear diagnostic stack', r'''
local marker={}; local owner={bad=function() error(marker) end}
P:Wrap(owner,'bad'); command('on')
local ok,err=pcall(owner.bad,Bags)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bags.stats.bad.errors==1)
command('off'); ok,err=pcall(owner.bad,Bags); assert(not ok and err==marker)
''')
check('clock resets are flagged instead of reporting fake zero time', r'''
local owner={badClock=function() milliseconds=0 end}; P:Wrap(owner,'badClock')
command('on'); owner.badClock(Bags)
assert(P.invalidSpans==1 and P.inventories.Bags.stats.badClock==nil and P.stack==nil)
''')
check('no accurate clock refuses sampling', r'''
debugprofilestop=nil; command('on')
assert(not P.enabled and P.startedAt==nil and #frames==0)
assert(string.find(messages[#messages],'debugprofilestop',1,true))
''')
check('offline bank does not become online due to profiling', r'''
command('on'); Bank.uiFrame:Show()
assert(not Bank.online and not P.opens[1].online)
assert(P.inventories.Bank.stats.UiFrame_OnShow.calls==1)
''')
check('one-second follow-up window excludes later operations', r'''
command('on'); Bags:Open(); Bags:QueueUpdate(); local s=P.opens[1]
assert(s.queues==1)
now=now+1.1; Bags:QueueUpdate(); Bags:Update()
assert(s.updates==1 and s.queues==1 and P.inventories.Bags.updates==2)
''')
check('reopening and bounded history retain latest twenty', r'''
command('on')
for i=1,25 do Bags.uiFrame.shown=false; Bags:Open(); now=now+1.1 end
assert(#P.opens==20 and P.active.Bags==P.opens[20])
assert(P.inventories.Bags.stats.UiFrame_OnShow.calls==25)
''')
check('frame delay and global frame gap have explicit scope', r'''
command('on'); Bags:Open(); cost(11); P:OnFrame(0.15)
assert(P.opens[1].nextFrame==39 and P.frameMax==150)
local first=P.opens[1].nextFrame; cost(50); P:OnFrame(0.01)
assert(P.opens[1].nextFrame==first and P.frameCount==2)
assert(string.find(P:ReportText(),'不能单独归因',1,true))
''')
check('auto-stop hides frame and report duration stays frozen', r'''
command('on'); Bags:Open(); now=160.1; P:OnFrame(0.02)
assert(not P.enabled and not P.frame.shown and P.stoppedAt==160.1)
local report=P:ReportText(); now=200; command('off'); command('report')
assert(P:ReportText()==report and P.reportWindow.text==report)
''')
check('report freezes sampling, supports copy and clear', r'''
command('report'); assert(string.find(P.reportWindow.text,'尚无采样',1,true))
command('on'); Bags:Open(); command('report')
assert(not P.enabled and not P.frame.shown and P.reportWindow.selectAllOnFocus)
assert(string.find(P.reportWindow.text,'分类规则',1,true))
command('clear'); assert(P.startedAt==nil and next(P.inventories)==nil and #P.opens==0)
command('on'); assert(P.enabled and #P.opens==0)
''')
check('standalone tooltip not counted; event arguments not retained', r'''
command('on'); local reads=clockCalls
BsItemInfo:GetTooltip('private item',nil,true)
assert(clockCalls==reads and next(P.inventories)==nil)
Bags:OnEvent('BAG_UPDATE_COOLDOWN','private account','private item')
local report=P:ReportText()
assert(not string.find(report,'private',1,true))
assert(P.inventories.Bags.events.BAG_UPDATE_COOLDOWN==1)
''')
check('blocked and hidden updates preserve early returns', r'''
command('on'); Bags.windowUpdateBlocked=true; Bags:Update()
assert(Bags.windowUpdateBlocked and P.inventories.Bags.skipped==1)
Bags.windowUpdateBlocked=false; Bags:Update()
assert(P.inventories.Bags.skipped==2 and P.inventories.Bags.stats.UpdateCache==nil)
''')
check('docked inventory remains separate and nested time is not double counted', r'''
command('on'); Bags:Open(); Keyring:Open()
Bags.dockedInventory=Keyring
Bags:Update(true)
assert(P.inventories.Bags.updates==2 and P.inventories.Keyring.updates==2)
assert(P.inventories.Bags.stats.Update.total==78)
assert(P.inventories.Bags.stats.Update.own==0)
assert(not Bags.windowUpdateBlocked and not Keyring.windowUpdateBlocked)
''')
check('only opening a hidden frame starts a new open sample', r'''
command('on'); Bags:Open(); Bags:Open(); assert(#P.opens==1)
Bags.uiFrame.shown=false; Bags:Open(); assert(#P.opens==2)
''')
check('clear and unknown commands do not enable diagnostics', r'''
command('clear'); command('status'); command('help'); command('nonsense')
assert(not P.enabled and #frames==0 and P.startedAt==nil)
''')

# Compile every addon Lua file and resolve XML load paths without altering bytes.
lua = LuaRuntime()
compile_lua = lua.eval('function(s,n) local f,e=loadstring(s,n); return f~=nil,e end')
files = list(ADDON.rglob('*.lua'))
for path in files:
    ok, error = compile_lua(path.read_bytes().decode('utf-8-sig'), str(path))
    assert ok, (path, error)
includes = 0
for path in ADDON.rglob('*.xml'):
    for node in ET.fromstring(path.read_bytes()).iter():
        target = node.attrib.get('file')
        if target and node.tag.rsplit('}', 1)[-1] in {'Include', 'Script'}:
            assert (path.parent / target.replace('\\', '/')).is_file(), (path, target)
            includes += 1
raw = (ADDON / 'Bagshui.xml').read_bytes()
assert raw.count(b'\r\n') == raw.count(b'\n'), 'Original CRLF must be preserved'
assert raw.index(b'Components\\Keyring.lua') < raw.index(b'Components\\Performance.lua')
assert not re.search(r'BagshuiData\s*[.\[]', (ADDON / 'Components/Performance.lua').read_text(encoding='utf-8'))
print(f'PASS: {len(CHECKS)} behavior groups; {len(files)} Lua files; {includes} XML load paths')
