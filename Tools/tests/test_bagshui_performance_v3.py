"""Check v3 scopes on actual layout, button, creation and diagnostic code.

Controlled native-call costs test attribution, not client milliseconds or FPS.
The shared strict 1.12 font contract remains active in the UI fixture.
"""
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / 'Interface/AddOns/Bagshui'
hotpaths = runpy.run_path(str(Path(__file__).with_name('test_bagshui_hotpaths.py')))

SETUP = r'''
inventory.inventoryType='Bags'; inventory.initialItemSlotButtons=1
inventory.uiFrame=object('Frame','window'); ui.frames.main=group
ui.frames.groupMoveTargets={}; ui.buttons.itemSlots={button}
ui.UpdateItemButtonColorsAndBadges=nil
Bagshui.prototypes.InventoryUi=setmetatable({}, {__index=Bagshui.prototypes.Ui})
setmetatable(ui,{__index=Bagshui.prototypes.InventoryUi})
function ui:CreateElementName(name) return 'Test'..name end
function ui:SetFrameBackdrop(f) f:SetBackdrop({edgeFile='border',edgeSize=1,insets={top=0}}) end
function ui:SetGroupColors() end
function ui:CreateLabel(parent)
 local label=object('Frame','label',parent)
 local text=label:CreateFontString(nil,nil,'GameFontNormal')
 text:SetText(' ')
 return label,text
end
BS_INVENTORY_OBJECT_TYPE={GROUP='Group',GROUP_MOVE_TARGET='MoveTarget'}
BsSkin.itemSlotDecorationAnchor=1; BsSkin.itemSlotBorderAnchor=0; BsSkin.itemSlotInset=0
BsSkin.itemSlotBorderTexture='border'; BsSkin.itemSlotBorderDefaultColor=ITEM_QUALITY_COLORS[1]
BsSkin.itemSlotInnerGlowTexture='glow'; BsSkin.itemSlotInnerGlowAnchor=0
BS_UI_ITEM_BUTTON_TYPE.BAG='Bag'
function methods:GetWidth() return self.width or 32 end
function methods:GetHeight() return self.height or 32 end
function methods:GetFont() return unpack(self.font) end
function methods:GetFrameLevel() return self.frameLevel or 0 end
function methods:SetFrameLevel(v) self.frameLevel=v end
function methods:SetScript(k,v) self.scripts=self.scripts or {}; self.scripts[k]=v end
function methods:GetScript(k) return self.scripts and self.scripts[k] end
function methods:RegisterForClicks() end
function methods:RegisterForDrag() end
function methods:EnableMouse() end
function methods:SetShadowColor() end
function methods:SetShadowOffset() end
function methods:SetBlendMode() end
function methods:SetDesaturated() end
function methods:SetJustifyH() end
function methods:SetJustifyV() end
function methods:CreateTexture(name) return object('Texture',name,self) end
function methods:GetHighlightTexture() return self.highlight end
function methods:GetNormalTexture() return self.normal end
function methods:GetPushedTexture() return self.pushed end
function CreateFrame(kind,name,parent,template)
 local f=object(kind,name,parent)
 if name then _G[name]=f end
 if template=='ItemButtonTemplate' then
  f.highlight=object('Texture','highlight',f); f.normal=object('Texture','normal',f); f.pushed=object('Texture','pushed',f)
  _G[name..'IconTexture']=object('Texture','icon',f)
  for _,suffix in ipairs({'Count','Stock'}) do
   _G[name..suffix]=f:CreateFontString(name..suffix,nil,'GameFontNormal')
  end
 end
 return f
end
milliseconds=1000; clockCalls=0; messages={}
function debugprofilestop() clockCalls=clockCalls+1; return milliseconds end
function cost(ms) milliseconds=milliseconds+ms end
function Bagshui:Print(text) table.insert(messages,text) end
function Bagshui.prototypes.Inventory:QueueUpdate() end
function Bagshui.prototypes.Inventory:OnEvent() end
Bagshui.components.Bags=inventory; Bagshui.components.Bank={}
BS_INVENTORY_TYPE_UI_ORDER={'Bags','Bank','Keyring'}; BS_VERSION='1.5.15'
BsSlash={}; function BsSlash:AddHandler() end

function readyWindow()
 Bagshui.currentCharacterData={bags={}}
 inventory.inventory={[0]={item}}; inventory.layout={{{groupId='g',name='Test'}}}
 inventory.groupItems.g={item}; inventory.groupsIdsToFrames={}
 inventory.groupItemCounts={}; inventory.groupWidthsInItems={}; inventory.actualGroupWidths={}
 inventory.settings.windowBackground={0,0,0,1}; inventory.settings.windowBorder={1,1,1,1}
 inventory.settings.itemSize=32; inventory.settings.itemMargin=1
 inventory.settings.groupMargin=1; inventory.settings.groupPadding=1; inventory.settings.windowMaxColumns=1
 inventory.settings.showGroupLabels=true; inventory.settings.windowScale=1
 BS_INVENTORY_BAG_USAGE_DISPLAY={ALWAYS='ALWAYS',SMART='SMART'}
 for _,k in ipairs({'groupMarginFudge','groupLabelMinPadding','groupPaddingFudge','itemSlotMarginFudge',
  'groupLabelYPadding','groupLabelRelativeWidth','groupLabelXOffset','groupLabelYOffset'}) do BsSkin[k]=0 end
 BsSkin.inventoryWindowPadding=2; BsSkin.inventoryWindowMinWidth=10
 ui.frames.header=object('Frame','header'); ui.frames.footer=object('Frame','footer')
 ui.text={noData=object('Frame','noData')}
 local label,text=ui:CreateLabel(group)
 group.bagshuiData={labelFrame=label,text=text}
 function methods:SetBackdropColor() end
 function methods:SetFrameStrata() end
 function methods:IsShown() return self.shown end
 function methods:GetRight() return 40 end
 function methods:GetLeft() return 0 end
 function methods:GetBottom() return 0 end
 function inventory:FixWindowPosition() end
 function ui:SetGroupInteractivityEnabled() end
 function Bagshui:QueueClassCallback() queuedCallbacks=(queuedCallbacks or 0)+1 end
 inventory.windowUpdateNeeded=true
end
'''


def runtime():
    lua = hotpaths['runtime']()
    lua.execute(SETUP)
    for name in ['Ui.Util.lua', 'Inventory.Ui.ItemButton.lua', 'Inventory.Ui.Group.lua', 'Performance.lua']:
        lua.execute((ADDON / 'Components' / name).read_text(encoding='utf-8-sig'))
    lua.execute('P=Bagshui.components.Performance')
    return lua


checks = []


def check(name, script):
    lua = runtime()
    lua.execute(script)
    checks.append(name)


check('disabled granular wrappers and manual scopes do not read clocks', r'''
local size=inventory.SizeAndShowFrame
render(40); ui.CreateInventoryItemSlotButton=nil; ui:CreateInventoryItemSlotButton(2)
assert(clockCalls==0 and P.startedAt==nil and next(P.inventories)==nil)
assert(inventory.SizeAndShowFrame==size and not P.enabled)
''')

check('full actual window update records group width and label blocks', r'''
readyWindow()
function ui:SetGroupColors() cost(5) end
P:Start(); P:StartOpen(inventory); inventory:UpdateWindow()
local s=P.inventories.Bags.stats
assert(s.GroupWidths.calls==1 and s.GroupLabels.calls==1 and s.GroupLabels.total==5)
assert(s.GetGroupItemCountForLayout.calls==1 and s.AssignItemsToSlots.calls==1)
assert(s.RowGeometry.calls==1 and s.WindowGeometry.calls==1 and s.WindowFinish.calls==1)
assert(s.UpdateWindow.calls==1 and P.inventories.Bags.redraws==1)
assert(not inventory.windowUpdateNeeded and queuedCallbacks==1 and P.stack==nil)
inventory:UpdateWindow(); assert(s.GroupWidths.calls==1 and P.inventories.Bags.redraws==1)
''')

check('native row geometry failures unwind the window stack', r'''
readyWindow(); local marker={}
function methods:GetRight() error(marker) end
P:Start(); local ok,err=pcall(inventory.UpdateWindow,inventory)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bags.stats.RowGeometry.errors==1)
assert(P.inventories.Bags.stats.UpdateWindow.errors==1)
''')

check('label block failures unwind the full window diagnostic stack', r'''
readyWindow(); local marker={}
function group.bagshuiData.text:SetText() error(marker) end
P:Start(); local ok,err=pcall(inventory.UpdateWindow,inventory)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bags.stats.GroupLabels.errors==1)
assert(P.inventories.Bags.stats.UpdateWindow.errors==1)
''')

check('actual layout native costs are separate and nested own time is correct', r'''
local clear=methods.ClearAllPoints; local point=methods.SetPoint; local top=methods.GetTop
function methods:ClearAllPoints() cost(2); return clear(self) end
function methods:SetPoint(...) cost(3); return point(self,...) end
function methods:GetTop() cost(7); return top(self) end
function methods:GetBackdrop() cost(11); return self.backdrop end
P:Start(); P:StartOpen(inventory); render(32)
local s=P.inventories.Bags.stats
assert(s.PositionFrames.total==5 and s.PositionFrames.own==5)
assert(s.ReadGeometry.total==7 and s.BorderRead.total==11)
assert(s.SizeAndShowFrame.total==23 and s.SizeAndShowFrame.own==0)
assert(s.SetItemButtonSize.total==11 and s.InvertItemButtonBorderScale.own==0)
assert(s.AssignItemsToSlots.total==23 and s.AssignItemsToSlots.own==0 and P.stack==nil)
assert(P.opens[1].stats.ReadGeometry.total==7)
''')

check('native backdrop application measured only when actually applied', r'''
local apply=methods.SetBackdrop
function methods:SetBackdrop(v) cost(13); return apply(self,v) end
P:Start(); render(40); render(40)
local s=P.inventories.Bags.stats
assert(s.BorderRead.calls==2 and s.BorderApply.calls==1 and s.BorderApply.total==13)
assert(s.InvertItemButtonBorderScale.total==13)
''')

check('real slot and decoration creation counters exclude reuse', r'''
ui.CreateInventoryItemSlotButton=nil
P:Start(); P:StartOpen(inventory)
ui:CreateInventoryItemSlotButton(1); ui:CreateInventoryItemSlotButton(2); ui:CreateInventoryItemSlotButton(2)
local d=P.inventories.Bags; local c=d.created; local s=d.stats
assert(s.CreateInventoryItemSlotButton.calls==3 and s.CreateItemSlotButton.calls==1)
assert(c.CreateItemSlotButton==1 and c.CreateShadowedTexture==3 and c.CreateItemButtonCooldown==1)
assert(d.poolStart==1 and d.poolEnd==2 and P.opens[1].poolEnd==2)
assert(P.opens[1].created.CreateItemSlotButton==1)
assert(ui.buttons.itemSlots[2].bagshuiData.getIdProxy)
''')

check('actual group and edit target preparation counts only new controls', r'''
P:Start(); P:StartOpen(inventory)
ui:CreateGroup(1); ui:CreateGroup(2); ui:CreateGroup(2)
ui:CreateGroupMoveTarget(); ui:CreateGroupMoveTarget(3)
local c=P.inventories.Bags.created
assert(c.CreateGroup==1 and c.CreateGroupMoveTarget==3)
assert(P.inventories.Bags.stats.CreateGroup.calls==3)
assert(ui.frames.groupMoveTargets[3].bagshuiData.text.text=='+')
''')

check('standalone UI cannot contaminate an inventory even during its measured call', r'''
local standalone=setmetatable({}, {__index=Bagshui.prototypes.Ui})
P:Start(); local span=P:Begin(inventory,'test')
local reads=clockCalls; standalone:CreateShadowedTexture(group,'x')
assert(clockCalls==reads and P.inventories.Bags.stats.CreateShadowedTexture==nil)
P:Finish(span); assert(P.stack==nil)
''')

check('native exceptions close manual scopes and keep the original error object', r'''
local marker={}; local top=methods.GetTop
function methods:GetTop() cost(7); error(marker) end
P:Start(); local ok,err=pcall(render,32)
assert(not ok and err==marker and P.stack==nil)
local s=P.inventories.Bags.stats
assert(s.ReadGeometry.errors==1 and s.SizeAndShowFrame.errors==1 and s.AssignItemsToSlots.errors==1)
methods.GetTop=top; render(32); assert(P.stack==nil and s.ReadGeometry.calls==2)
''')

check('border native exceptions close manual and method scopes', r'''
local marker={}; function methods:GetBackdrop() error(marker) end
P:Start(); local ok,err=pcall(render,32)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bags.stats.BorderRead.errors==1)
assert(P.inventories.Bags.stats.InvertItemButtonBorderScale.errors==1)
''')

check('clock reset invalidates ancestors even if later time catches up', r'''
function methods:GetBackdrop() milliseconds=0; return self.backdrop end
function methods:GetTop() milliseconds=3000; return 1 end
P:Start(); render(32)
local s=P.inventories.Bags.stats
assert(s.BorderRead==nil and s.InvertItemButtonBorderScale==nil and s.AssignItemsToSlots==nil)
assert(s.ReadGeometry and P.invalidSpans>=4 and P.stack==nil)
''')

check('creation errors do not claim successfully completed buttons', r'''
ui.CreateInventoryItemSlotButton=nil
local marker={}; function ui:SkinItemButton() error(marker) end
P:Start(); local ok,err=pcall(ui.CreateInventoryItemSlotButton,ui,2)
assert(not ok and err==marker and P.stack==nil)
assert(not P.inventories.Bags.created.CreateItemSlotButton)
assert(P.inventories.Bags.stats.CreateItemSlotButton.errors==1)
''')

check('follow-up creation counters retain entry-time one-second observation boundary', r'''
ui.CreateInventoryItemSlotButton=nil
P:Start(); local sample=P:StartOpen(inventory)
clock=clock+1.1; ui:CreateInventoryItemSlotButton(2)
assert(sample.created.CreateItemSlotButton==nil and sample.poolEnd==1)
assert(P.inventories.Bags.created.CreateItemSlotButton==1 and P.inventories.Bags.poolEnd==2)
''')

check('UI wrappers preserve nil holes, trailing returns and separate inventories', r'''
local owner={test=function(...) assert(arg.n==4); cost(3); return nil,arg[4],nil end}
P:Wrap(owner,'test',nil,'ui')
local function pack(...) return arg end
for _,on in ipairs({false,true}) do
 if on then P:Start() end
 local r=pack(owner.test(ui,'a',nil,'z'))
 assert(r.n==3 and r[1]==nil and r[2]=='z' and r[3]==nil)
end
local bank={inventoryType='Bank'}; owner.test({inventory=bank},'a',nil,'z')
assert(P.inventories.Bank.stats.test.total==3 and P.inventories.Bags.stats.test.total==3)
''')

check('v3 report shows nested-scope limits, actual creations and per-open detail', r'''
ui.CreateInventoryItemSlotButton=nil
P:Start(); P:StartOpen(inventory); ui:CreateInventoryItemSlotButton(2); render(40); P:Stop()
local report=P:ReportText()
for _,text in ipairs({'诊断 v3','勿与 v2','不能相加','准备次数包含复用','实际新建','物品按钮 1',
 '按钮池 1→2','定位后 GetTop','颜色与徽标','缩放边框读取','细分 ms','定位/边框 ms'}) do
 assert(string.find(report,text,1,true),text)
end
local frozen=report; clock=clock+50; assert(P:ReportText()==frozen)
P:Reset(); assert(next(P.inventories)==nil and #P.opens==0)
''')

# Granular recording must preserve the same actual item operations/display.
before, after = runtime(), runtime()
after.execute('P:Start()')
for step in ["render(40)", "item.locked=1; render(40)", "item.locked=0; item.count=7; render(32)",
             "inventory.searchText='name(\"absent\")'; render(32)",
             "inventory.searchText=nil; inventory.online=false; render(32)",
             "inventory.online=true; inventory.editMode=true; render(32)"]:
    before.execute(step)
    after.execute(step)
    assert before.eval('snapshot()') == after.eval('snapshot()'), step
checks.append('enabled/disabled real rendering preserves lock/count/search/offline/edit display')

for name in ['Inventory.Layout.lua', 'Ui.ItemButton.lua']:
    old = subprocess.check_output(['git', 'show', f'6117ba0:Interface/AddOns/Bagshui/Components/{name}'], cwd=ROOT)
    current = (ADDON / 'Components' / name).read_bytes()
    assert current.startswith(b'\xef\xbb\xbf') == old.startswith(b'\xef\xbb\xbf')
    assert current.count(b'\r\n') == current.count(b'\n')
assert (ADDON / 'Components/Performance.lua').read_bytes().count(b'\r\n') == 0
print(f'PASS: {len(checks)} granular diagnostic behavior groups; native costs are simulated')
