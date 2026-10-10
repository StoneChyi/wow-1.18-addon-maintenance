"""Exercise hidden prebuilding with visibility propagation and real callbacks.

The production prebuild loop and opening methods are extracted from source;
the surrounding toolbar setup is outside this fixture. Native timing is modeled.
"""
from pathlib import Path
import re
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[2]
COMPONENTS = ROOT / 'Interface/AddOns/Bagshui/Components'
REFERENCE = 'aa6299ee7a506f5dc54d94652c342fd61f5c66fa'
fixture = runpy.run_path(str(Path(__file__).with_name('test_bagshui_initialization.py')))


def source(name, old=False):
    if old:
        return subprocess.check_output(
            ['git', 'show', f'{REFERENCE}:Interface/AddOns/Bagshui/Components/{name}'],
            cwd=ROOT).decode('utf-8-sig').replace('\r\n', '\n')
    return (COMPONENTS / name).read_text(encoding='utf-8-sig')


def function_source(name, declaration):
    text = source(name)
    start = text.index(declaration)
    end = text.index('\nend', start) + len('\nend')
    return text[start:end]


def runtime(old=False):
    lua = fixture['runtime']()
    if old:
        for name in ['Ui.ItemButton.lua', 'Inventory.Ui.ItemButton.lua', 'Inventory.Layout.lua']:
            lua.execute(source(name, True))
    lua.execute(r'''
allFrames={inventory.uiFrame,group,otherGroup}; visibilityLog={}; tooltipHides=0; splitHides=0
local makeObject=object
function object(...)
 local f=makeObject(...); table.insert(allFrames,f); return f
end
function methods:IsShown() return self.shown end
local function nativeVisible(f)
 if not f.shown then return false end
 return not f.parent or nativeVisible(f.parent)
end
function methods:IsVisible() return nativeVisible(self) end
local function states()
 local result={}
 for _,f in ipairs(allFrames) do
  -- GetID proxies alias native objects through metatables; they are not new
  -- visible descendants after their userdata is replaced by the real frame.
  if getmetatable(f).__index==methods then result[f]=nativeVisible(f) end
 end
 return result
end
local function notify(before)
 for _,f in ipairs(allFrames) do
  if before[f]~=nil then
   local visible=nativeVisible(f)
   if before[f]~=visible then
    local key=visible and 'OnShow' or 'OnHide'
    table.insert(visibilityLog,{frame=f,key=key})
    local handler=f:GetScript(key)
    if handler then local oldThis=this; this=f; handler(); this=oldThis end
   end
  end
 end
end
function methods:Hide() local before=states(); self.shown=false; notify(before) end
function methods:Show() local before=states(); self.shown=true; notify(before) end
local setParent=methods.SetParent
function methods:SetParent(parent)
 local before=states()
 if self.bagshuiData and self.bagshuiData.getIdProxy then
  migrationStates=migrationStates or {}; table.insert(migrationStates,nativeVisible(self))
 end
 setParent(self,parent); notify(before)
end
function Bagshui:HideTooltips() tooltipHides=tooltipHides+1 end
BsInfoTooltip={}; function BsInfoTooltip:IsOwned() return false end
StackSplitFrame={}; function StackSplitFrame:Hide() splitHides=splitHides+1 end
inventory.uiFrame:Hide()
group.parent=inventory.uiFrame; otherGroup.parent=inventory.uiFrame
ui.CreateInventoryItemSlotButton=nil
''')
    # Execute the production loop, not a separately rewritten prebuild algorithm.
    text = source('Inventory.Ui.lua', old)
    loop = re.search(r'\tfor buttonNum = 1, self.initialItemSlotButtons do\n.*?\n\tend', text, re.S)
    assert loop
    lua.execute('function inventory:PrebuildFixture()\nlocal ui=self.ui\n' + loop[0] + '\nend')
    lua.execute(function_source('Inventory.Ui.lua', 'function Inventory:Open()').replace(
        'function Inventory:Open()', 'function Bagshui.prototypes.Inventory:Open()'))
    lua.execute(r'''
BS_INVENTORY_UI_VISIBILITY_ACTION={OPEN='OPEN'}
function inventory:SetDockedToFrameVisibility() hit('dock') end
function methods:Raise() hit('raise') end
function inventory:Update() hit('openUpdate') end
bank=setmetatable({inventoryType='Bank',settings={replaceBank=true},
 _super=Bagshui.prototypes.Inventory,uiFrame=inventory.uiFrame}, {__index=Bagshui.prototypes.Inventory})
function bank:Update() cost(7) end
function bank:SetDockedToFrameVisibility() cost(13) end
''')
    lua.execute(function_source('Bank.lua', 'function Bank:Open()').replace(
        'function Bank:Open()', 'function bank:Open()'))
    lua.execute('P:Wrap(Bagshui.prototypes.Inventory,"Open"); P:Wrap(bank,"Open","OpenBank")')
    return lua


checks = []


def check(name, script):
    lua = runtime()
    lua.execute(script)
    checks.append(name)


check('prebuild stays hidden before custom callbacks and through first window show', r'''
inventory:PrebuildFixture(); button=ui.buttons.itemSlots[1]
assert(not button:IsShown() and not button:IsVisible() and tooltipHides==0 and splitHides==0)
inventory.uiFrame:Show()
assert(not button:IsVisible() and tooltipHides==0)
P:Start(); P:StartOpen(inventory); freshRender()
assert(button:IsVisible() and button:GetParent()==group and migrationStates[1]==false)
assert(P.inventories.Bags.stats.ParentApplyHidden.calls==1)
assert(not P.inventories.Bags.stats.ParentApplyVisible)
assert(tooltipHides==0 and splitHides==0)
''')

check('first layout still works when the inventory window remains hidden', r'''
inventory:PrebuildFixture(); P:Start(); freshRender()
assert(button:IsShown() and not button:IsVisible() and migrationStates[1]==false)
inventory.uiFrame:Show(); assert(button:IsVisible())
''')

check('unused prebuilt slots stay hidden and can later join a growing group', r'''
inventory.initialItemSlotButtons=2; inventory:PrebuildFixture()
inventory.uiFrame:Show(); freshRender()
assert(button:IsVisible() and not ui.buttons.itemSlots[2]:IsShown())
local second=BsUtil.TableCopy(item); second.id=2; second.slotNum=2
inventory.groupItems.g={item,second}
inventory:AssignItemsToSlots('g',1,1,2,2,40,1)
assert(ui.buttons.itemSlots[2]:IsVisible() and migrationStates[2]==false)
''')

check('later visible regrouping does not add a hide/show pair or change split ownership', r'''
inventory:PrebuildFixture(); inventory.uiFrame:Show(); freshRender()
button.hasStackSplit=1; local hides=tooltipHides; local log=#visibilityLog
ui.frames.groups[1]=otherGroup; P:Start(); freshRender()
assert(button:IsVisible() and migrationStates[2]==true)
assert(tooltipHides==hides and splitHides==0 and #visibilityLog==log)
assert(P.inventories.Bags.stats.ParentApplyVisible.calls==1)
inventory.uiFrame:Hide(); assert(tooltipHides==hides+1 and splitHides==1)
''')

check('normal repeated window opens retain callback and split cleanup behavior', r'''
inventory:PrebuildFixture(); inventory.uiFrame:Show(); freshRender()
button.hasStackSplit=1
inventory.uiFrame:Hide(); assert(tooltipHides==1 and splitHides==1)
inventory.uiFrame:Show(); assert(button:IsVisible())
local parents=counts.parent; freshRender(); assert(counts.parent==parents)
inventory.uiFrame:Hide(); assert(tooltipHides==2 and splitHides==2)
''')

check('standalone and direct-on-demand creation default to their previous shown state', r'''
inventory.uiFrame:Show(); ui:CreateInventoryItemSlotButton(1,group)
button=ui.buttons.itemSlots[1]; assert(button:IsShown() and button:IsVisible())
local standalone=setmetatable({CreateElementName=ui.CreateElementName},{__index=Bagshui.prototypes.Ui})
local b=standalone:CreateItemSlotButton('Standalone',inventory.uiFrame)
assert(b:IsShown() and b:IsVisible())
''')

check('creation-only option never hides an existing assigned button', r'''
inventory:PrebuildFixture(); inventory.uiFrame:Show(); freshRender()
local hides=tooltipHides
ui:CreateInventoryItemSlotButton(1,nil,true)
assert(button:IsVisible() and tooltipHides==hides)
''')

check('hidden parent migration measures the actual native cost separately', r'''
inventory:PrebuildFixture(); inventory.uiFrame:Show()
local set=methods.SetParent
function methods:SetParent(p) cost(11); return set(self,p) end
P:Start(); freshRender()
local s=P.inventories.Bags.stats
assert(s.ParentApplyHidden.calls==1 and s.ParentApplyHidden.total==11)
assert(s.ParentApplyReused.total==11 and s.ParentApplyReused.own==0)
assert(s.AssignItemsToSlots.total==11 and s.AssignItemsToSlots.own==0)
''')

check('initial border cost is inside skin creation and excluded from skin own time', r'''
local set=methods.SetBackdrop
function methods:SetBackdrop(v) cost(17); return set(self,v) end
P:Start(); inventory:PrebuildFixture()
local s=P.inventories.Bags.stats
assert(s.SkinBorderInit.calls==1 and s.SkinBorderInit.total==17)
assert(s.SkinItemButton.total==17 and s.SkinItemButton.own==0)
assert(s.CreateItemSlotButton.total==17 and not s.BorderApply)
''')

check('bank opening retains order and separates Show own cost from OnShow', r'''
local trace={}
function bank:Update() table.insert(trace,'update'); cost(7) end
function bank:UiFrame_OnShow() table.insert(trace,'OnShow'); cost(19) end
function bank:SetDockedToFrameVisibility() table.insert(trace,'dock'); cost(13) end
P:Wrap(bank,'UiFrame_OnShow')
inventory.uiFrame:SetScript('OnShow',function() bank:UiFrame_OnShow() end)
local show=methods.Show
function methods:Show() table.insert(trace,'Show'); cost(3); return show(self) end
function methods:Raise() table.insert(trace,'Raise'); cost(5) end
P:Start(); trace={}; event='BANKFRAME_OPENED'; bank:Open()
local s=P.inventories.Bank.stats
assert(s.BankPreShowUpdate.total==7 and s.OpenShow.total==22 and s.OpenShow.own==3)
assert(s.OpenRaise.total==5 and s.OpenDock.total==13 and s.Open.total==40)
assert(s.OpenBank.total==47 and bank.atBank)
assert(P.opens[1].stats.BankPreShowUpdate==nil)
assert(P.opens[1].stats.OpenShow==nil) -- Starts before this open observation window.
assert(P.opens[1].stats.OpenRaise.total==5 and P.stack==nil)
assert(table.concat(trace,',')=='update,Show,OnShow,Raise,dock')
''')

check('bank replacement opt-out still updates status but never shows or raises', r'''
bank.settings.replaceBank=false; P:Start(); event='BANKFRAME_OPENED'; bank:Open()
local s=P.inventories.Bank.stats
assert(s.BankPreShowUpdate.calls==1 and not s.OpenShow and not s.OpenRaise and not s.OpenDock)
assert(not inventory.uiFrame:IsVisible())
''')

check('opening stages preserve error identity and unwind manual scopes', r'''
local marker={}; function methods:Raise() error(marker) end
P:Start(); event='BANKFRAME_OPENED'; local ok,err=pcall(bank.Open,bank)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bank.stats.OpenRaise.errors==1)
assert(not P.inventories.Bank.stats.OpenDock)
''')

check('display-before-update failure still prevents all subsequent opening work', r'''
local marker={}; function bank:Update() error(marker) end
P:Start(); event='BANKFRAME_OPENED'; local ok,err=pcall(bank.Open,bank)
assert(not ok and err==marker and P.stack==nil)
local s=P.inventories.Bank.stats
assert(s.BankPreShowUpdate.errors==1 and not s.OpenShow and not s.OpenRaise and not s.OpenDock)
''')

check('initial border errors close the new block and its creation parents', r'''
local marker={}; function methods:SetBackdrop() error(marker) end
P:Start(); local ok,err=pcall(inventory.PrebuildFixture,inventory)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bags.stats.SkinBorderInit.errors==1)
assert(P.inventories.Bags.stats.SkinItemButton.errors==1)
''')

check('disabled new diagnostics do not query migration visibility or clocks', r'''
inventory:PrebuildFixture(); inventory.uiFrame:Show()
local visible=methods.IsVisible
function methods:IsVisible()
 if forbidVisibility and self.bagshuiData and self.bagshuiData.getIdProxy then error('diagnostic read while off') end
 return visible(self)
end
-- The native stand-in itself observes visibility; count only the production query.
local parent=methods.SetParent
function methods:SetParent(p)
 local prior=forbidVisibility; forbidVisibility=false
 parent(self,p); forbidVisibility=prior
end
forbidVisibility=true; freshRender(); forbidVisibility=false
bank:Open(); assert(clockCalls==0 and P.startedAt==nil)
''')

check('v3.2 report distinguishes migration states and documents observation boundaries', r'''
inventory:PrebuildFixture(); inventory.uiFrame:Show()
P:Start(); P:StartOpen(inventory); freshRender(); P:Stop()
local report=P:ReportText()
for _,text in ipairs({'诊断 v3.2','隐藏按钮父框架更换','隐藏 1 次','可见 0 次','主要查看库存累计'}) do
 assert(string.find(report,text,1,true),text)
end
''')

# Match final visual/slot identity against the immediately preceding personal build.
old, new = runtime(True), runtime()
steps = [
    'inventory:PrebuildFixture(); inventory.uiFrame:Show(); freshRender()',
    'item.locked=1; freshRender()',
    'item.locked=0; item.count=1; item.maxStackCount=1; item.charges=7; freshRender()',
    'inventory.settings.itemQualityBadges=true; item.quality=2; freshRender()',
    'cooldownStart=900; cooldownDuration=30; cooldownEnabled=1; freshRender()',
    'inventory.online=false; freshRender()',
    'inventory.online=true; inventory.searchText="axe"; freshRender()',
    'inventory.searchText=nil; inventory.editMode=true; freshRender()',
    'inventory.editMode=false; inventory.settings.itemSize=48; freshRender()',
    'ui.frames.groups[1]=otherGroup; freshRender()',
    'inventory.uiFrame:Hide(); inventory.uiFrame:Show(); freshRender()',
]
for step in steps:
    for lua in [old, new]:
        lua.execute(step)
    assert old.eval('snapshot()') == new.eval('snapshot()'), step
    for expr in ['button:IsVisible()', 'button.bagshuiData.getIdProxy:GetID()',
                 'button.bagshuiData.getIdProxy:GetParent():GetID()', 'tooltipHides', 'splitHides']:
        assert old.eval(expr) == new.eval(expr), (step, expr)
for name in ['texture', 'count', 'cooldown', 'cooldownRead', 'parent', 'backdrop']:
    assert old.eval(f'counts.{name}') == new.eval(f'counts.{name}'), name
assert old.eval('migrationStates[1]') is True and new.eval('migrationStates[1]') is False
checks.append('prior-build final display, ID proxies, callbacks and refresh-call differential')

for name in ['Inventory.Ui.lua', 'Inventory.Ui.ItemButton.lua', 'Ui.ItemButton.lua',
             'Inventory.Layout.lua', 'Bank.lua', 'Performance.lua']:
    old = subprocess.check_output(['git', 'show', f'{REFERENCE}:Interface/AddOns/Bagshui/Components/{name}'], cwd=ROOT)
    current = (COMPONENTS / name).read_bytes()
    assert current.startswith(b'\xef\xbb\xbf') == old.startswith(b'\xef\xbb\xbf')
    if b'\r\n' in old:
        assert current.count(b'\r\n') == current.count(b'\n'), name
    else:
        assert b'\r\n' not in current, name
print(f'PASS: {len(checks)} hidden-prebuild/open-entry groups; visibility/callback/native costs modeled')
print('STATE CHECK: first prebuilt migration visible -> hidden; parent/backdrop/item/cooldown call counts unchanged')
