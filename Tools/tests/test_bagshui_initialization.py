"""Check final-size borders and final-group creation against the prior personal build.

Native timings and relative frame levels are modeled, not client acceptance.
The shared strict font contract is retained, including a failed font-file case.
"""
from pathlib import Path
import runpy
import subprocess

ROOT = Path(__file__).resolve().parents[2]
ADDON = ROOT / 'Interface/AddOns/Bagshui'
REFERENCE = '92337acd44891ea9545c56baba8d41b4b9293d8c'
fixture = runpy.run_path(str(Path(__file__).with_name('test_bagshui_performance_v3.py')))


def runtime(original=False):
    lua = fixture['runtime']()
    if original:
        for name in ['Inventory.Layout.lua', 'Inventory.Ui.ItemButton.lua', 'Ui.ItemButton.lua']:
            source = subprocess.check_output(['git', 'show', f'{REFERENCE}:Interface/AddOns/Bagshui/Components/{name}'], cwd=ROOT)
            lua.execute(source.decode('utf-8-sig'))
    lua.execute(r'''
ui.CreateInventoryItemSlotButton=nil; ui.buttons.itemSlots={}
inventory.settings.itemSize=40
group[0]={}; otherGroup[0]={}
-- Relative level model: children start above their actual parent.
local createFrame=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=createFrame(kind,name,parent,template)
 f.frameLevel=(parent and parent:GetFrameLevel() or 0)+1
 f[0]={}; return f
end
local setFontObject=methods.SetFontObject
function methods:SetFontObject(font)
 if font=='NumberFontNormal' then font='GameFontNormal' end
 return setFontObject(self,font)
end
function prebuild()
 ui:CreateInventoryItemSlotButton(1)
 button=ui.buttons.itemSlots[1]
end
function freshRender(size)
 render(size or inventory.settings.itemSize)
 button=ui.buttons.itemSlots[1]
end
''')
    return lua


checks = []


def check(name, script):
    lua = runtime()
    lua.execute(script)
    checks.append(name)


check('prebuilt slot retains window parent and first layout reuses its final border', r'''
P:Start(); P:StartOpen(inventory); prebuild()
assert(button:GetParent()==inventory.uiFrame)
local edge=BsSkin.itemSlotEdgeSize*(1/(40/32))
assert(button.bagshuiData.buttonComponents.border.backdrop.edgeSize==edge)
assert(counts.backdrop==1)
freshRender()
assert(counts.backdrop==1 and counts.parent==1)
assert(P.inventories.Bags.stats.BorderApply==nil)
assert(P.inventories.Bags.stats.ParentCheck.calls==1)
assert(P.inventories.Bags.stats.ParentApplyReused.calls==1)
assert(P.inventories.Bags.stats.ParentApplyNew==nil)
''')

check('new slot creates under its final group without a parent migration', r'''
group.frameLevel=7
P:Start(); P:StartOpen(inventory); freshRender()
local d=button.bagshuiData; local c=d.buttonComponents
assert(button:GetParent()==group and counts.parent==nil and counts.backdrop==1)
assert(button:GetFrameLevel()>group:GetFrameLevel())
assert(c.border:GetFrameLevel()>button:GetFrameLevel())
assert(c.cooldown:GetFrameLevel()>button:GetFrameLevel())
for _,key in ipairs({'stockBadge','qualityBadge','topLeftBadge'}) do
 assert(c[key]:GetFrameLevel()>c.border:GetFrameLevel() and c[key]:GetFrameLevel()>c.cooldown:GetFrameLevel())
 assert(c[key].bagshuiData.texture and c[key].bagshuiData.shadow)
end
local s=P.inventories.Bags.stats
assert(s.ParentCheck.calls==1 and not s.ParentApplyNew and not s.ParentApplyReused)
assert(not s.BorderApply and P.inventories.Bags.created.CreateShadowedTexture==3)
assert(P.inventories.Bags.created.CreateItemButtonCooldown==1)
''')

check('optional creation parent never changes an already existing slot', r'''
prebuild(); ui:CreateInventoryItemSlotButton(1,group)
assert(button:GetParent()==inventory.uiFrame)
freshRender(); assert(button:GetParent()==group and counts.parent==1)
ui:CreateInventoryItemSlotButton(1,otherGroup)
assert(button:GetParent()==group and counts.parent==1)
''')

check('mixed prebuilt and new slots count actual reuse migrations', r'''
prebuild(); local second=BsUtil.TableCopy(item); second.id=2; second.slotNum=2
inventory.groupItems.g={item,second}
P:Start(); P:StartOpen(inventory)
inventory:AssignItemsToSlots('g',1,1,2,2,40,1)
local s=P.inventories.Bags.stats
assert(s.ParentCheck.calls==2 and s.ParentApplyReused.calls==1 and not s.ParentApplyNew)
assert(counts.parent==1 and counts.backdrop==2)
assert(P.inventories.Bags.created.CreateItemSlotButton==1)
ui.frames.groups[1]=otherGroup
inventory:AssignItemsToSlots('g',1,1,2,2,40,1)
assert(s.ParentApplyReused.calls==3 and not s.ParentApplyNew and counts.parent==3)
assert(counts.backdrop==2)
''')

check('GetID proxies track actual bag/slot after direct creation and later migration', r'''
freshRender(); local proxy=button.bagshuiData.getIdProxy
assert(proxy:GetID()==1 and proxy:GetParent():GetID()==0)
assert(proxy[0]==button[0] and proxy:GetParent()[0]==group[0])
item.bagNum=7; item.slotNum=3; inventory.containers[7]={genericType='Bag'}
ui.frames.groups[1]=otherGroup; freshRender()
assert(proxy:GetID()==3 and proxy:GetParent():GetID()==7)
assert(proxy:GetParent()[0]==otherGroup[0] and button:GetParent()==otherGroup)
''')

check('changing configured size after prebuild still reapplies the correct border', r'''
prebuild(); inventory.settings.itemSize=48; P:Start(); freshRender()
assert(counts.backdrop==2 and P.inventories.Bags.stats.BorderApply.calls==1)
assert(button.bagshuiData.buttonComponents.border.backdrop.edgeSize==1/(48/32))
freshRender(); assert(counts.backdrop==2)
''')

check('skin size fudge is incorporated exactly once', r'''
BsSkin.itemSlotSizeFudge=3; inventory.settings.itemSize=35
prebuild(); P:Start(); freshRender()
assert(button.bagshuiData.originalSizeAdjusted==35 and button.scale==1)
assert(counts.backdrop==1 and P.inventories.Bags.stats.BorderApply==nil)
''')

check('edge and external style changes still restore the actual border', r'''
freshRender(); P:Start(); BsSkin.itemSlotEdgeSize=2; freshRender()
local border=button.bagshuiData.buttonComponents.border
assert(border.backdrop.edgeSize==2/(40/32) and P.inventories.Bags.stats.BorderApply.calls==1)
border:SetBackdrop({edgeFile='external',edgeSize=9}); freshRender()
assert(border.backdrop.edgeFile=='border' and border.backdrop.edgeSize==2/(40/32))
assert(P.inventories.Bags.stats.BorderApply.calls==2)
button.bagshuiData.borderBackdropTable.insets.left=2; freshRender()
assert(border.backdrop.insets.left==2 and P.inventories.Bags.stats.BorderApply.calls==3)
''')

check('tiny representation differences avoid reapplication; meaningful differences do not', r'''
prebuild(); local border=button.bagshuiData.buttonComponents.border
border.backdrop.edgeSize=border.backdrop.edgeSize+0.0000001
P:Start(); freshRender(); assert(P.inventories.Bags.stats.BorderApply==nil)
border.backdrop.edgeSize=border.backdrop.edgeSize+0.01
freshRender(); assert(P.inventories.Bags.stats.BorderApply.calls==1)
''')

check('disabled inverse scaling, missing size and explicit opt-out keep old behavior', r'''
BsSkin.itemSlotBorderInverseScale=false; prebuild()
assert(button.bagshuiData.buttonComponents.border.backdrop.edgeSize==1)
freshRender(); assert(counts.backdrop==1)
BsSkin.itemSlotBorderInverseScale=true; button.bagshuiData.noBorderScale=true
ui:SkinItemButton(button); freshRender()
assert(button.bagshuiData.buttonComponents.border.backdrop.edgeSize==1)
button.bagshuiData.noBorderScale=nil; inventory.settings.itemSize=nil
ui:SkinItemButton(button); assert(button.bagshuiData.buttonComponents.border.backdrop.edgeSize==1)
''')

check('standalone creation and bag-slot skinning retain their initial border rules', r'''
local standalone=setmetatable({CreateElementName=ui.CreateElementName}, {__index=Bagshui.prototypes.Ui})
local b=standalone:CreateItemSlotButton('Standalone',inventory.uiFrame)
assert(not b.bagshuiData.inventory and b.bagshuiData.buttonComponents.border.backdrop.edgeSize==1)
standalone:SetItemButtonSize(b,40)
assert(b.bagshuiData.buttonComponents.border.backdrop.edgeSize==1/(40/32))
prebuild(); button.bagshuiData.type=BS_UI_ITEM_BUTTON_TYPE.BAG
ui:SkinItemButton(button)
assert(button.bagshuiData.buttonComponents.border.backdrop.edgeSize==1)
assert(button.bagshuiData.buttonComponents.stock.font)
''')

check('failed optional font preserves the valid ItemButtonTemplate font', r'''
BsSkin.itemSlotFont='missing-font.ttf'; failedFontPaths['missing-font.ttf']=true
freshRender(); local count=button.bagshuiData.buttonComponents.count
assert(count.font[1]=='Fonts\\FZXHLJW.TTF' and count.text=='4')
local bare=object('FontString','bare'); assert(not pcall(bare.SetText,bare,''))
assert(not bare:SetFont('missing-font.ttf',12) and not pcall(bare.SetText,bare,''))
''')

check('native parent checks and migration costs have separate attribution', r'''
prebuild()
local get=methods.GetParent; local set=methods.SetParent
function methods:GetParent() cost(3); return get(self) end
function methods:SetParent(p) cost(17); return set(self,p) end
P:Start(); P:StartOpen(inventory); freshRender()
local s=P.inventories.Bags.stats
assert(s.ParentCheck.calls==1 and s.ParentCheck.total==3)
assert(s.ParentApplyReused.calls==1 and s.ParentApplyReused.total==17)
assert(s.AssignItemsToSlots.total==20 and s.AssignItemsToSlots.own==0)
''')

check('native parent failures unwind diagnostics and retain error identity', r'''
prebuild(); local marker={}; function methods:SetParent() error(marker) end
P:Start(); local ok,err=pcall(freshRender)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bags.stats.ParentApplyReused.errors==1)
''')

check('native parent-check failures unwind diagnostics', r'''
local marker={}; function methods:GetParent() error(marker) end
P:Start(); local ok,err=pcall(freshRender)
assert(not ok and err==marker and P.stack==nil)
assert(P.inventories.Bags.stats.ParentCheck.errors==1)
''')

check('parent migration categories distinguish a custom factory that ignores the target', r'''
local factory=ui.CreateInventoryItemSlotButton
function ui:CreateInventoryItemSlotButton(i) return factory(self,i) end
P:Start(); freshRender()
assert(P.inventories.Bags.stats.ParentApplyNew.calls==1 and not P.inventories.Bags.stats.ParentApplyReused)
''')

check('current report includes per-open migration counts and preserves disabled-clock behavior', r'''
local update=inventory.Update
prebuild(); freshRender(); assert(clockCalls==0 and P.startedAt==nil)
ui.frames.groups[1]=otherGroup
P:Start(); P:StartOpen(inventory); freshRender(); P:Stop()
local report=P:ReportText()
for _,text in ipairs({'诊断 v3.2','按钮父框架检查','复用按钮父框架更换','父框架：检查 1 次',
 '新建按钮更换 0 次','复用按钮更换 1 次'}) do assert(string.find(report,text,1,true),text) end
assert(inventory.Update==update)
''')

# Differential final display/IDs and unchanged hook calls on real created buttons.
before, after = runtime(True), runtime()
setup = '''prebuild(); local second=BsUtil.TableCopy(item); second.id=2; second.slotNum=2
inventory.groupItems.g={item,second}
function twoSlots()
 inventory:AssignItemsToSlots('g',1,1,2,2,inventory.settings.itemSize,1)
end'''
before.execute(setup)
after.execute(setup)
steps = [
    'twoSlots()',
    'item.locked=1; twoSlots()',
    'item.locked=0; item.count=1; item.maxStackCount=1; item.charges=7; twoSlots()',
    'inventory.settings.itemQualityBadges=true; inventory.settings.itemUsableBadges=true; item.usable=false; twoSlots()',
    'inventory.settings.itemActiveQuestBadges=true; Bagshui.activeQuestItems[item.name]=true; twoSlots()',
    'cooldownStart=900; cooldownDuration=30; cooldownEnabled=1; twoSlots()',
    'cooldownEnabled=0; twoSlots()',
    'cooldownDuration=0; inventory.online=false; twoSlots()',
    'inventory.online=true; inventory.searchText="axe"; twoSlots()',
    'inventory.searchText=nil; inventory.editMode=true; twoSlots()',
    'inventory.editMode=false; inventory.settings.itemSize=48; twoSlots()',
    'ui.frames.groups[1]=otherGroup; twoSlots()',
    'inventory.settings.windowContentAlignment="RIGHT"; twoSlots()',
]
for step in steps:
    before.execute(step)
    after.execute(step)
    for index in [1, 2]:
        before.execute(f'button=ui.buttons.itemSlots[{index}]')
        after.execute(f'button=ui.buttons.itemSlots[{index}]')
        assert before.eval('snapshot()') == after.eval('snapshot()'), (step, index)
for key in ['texture', 'count', 'cooldown', 'cooldownRead']:
    assert before.eval(f'counts.{key}') == after.eval(f'counts.{key}'), key
checks.append('prior-build display/count/lock/charges/badges/cooldown/search/offline/edit/position differential')

old, new = runtime(True), runtime()
for lua in [old, new]:
    lua.execute(setup + '; twoSlots()')
assert old.eval('counts.parent') == 2 and new.eval('counts.parent') == 1
assert old.eval('counts.backdrop') == 4 and new.eval('counts.backdrop') == 2
for lua in [old, new]:
    lua.execute('twoSlots()')
assert old.eval('counts.parent') == 2 and new.eval('counts.parent') == 1
assert old.eval('counts.backdrop') == 4 and new.eval('counts.backdrop') == 2
checks.append('mixed cold layout removes one new-slot parent migration and both second backdrop applications')

for name in ['Inventory.Layout.lua', 'Inventory.Ui.ItemButton.lua', 'Ui.ItemButton.lua']:
    old = subprocess.check_output(['git', 'show', f'{REFERENCE}:Interface/AddOns/Bagshui/Components/{name}'], cwd=ROOT)
    current = (ADDON / 'Components' / name).read_bytes()
    assert current.startswith(b'\xef\xbb\xbf') == old.startswith(b'\xef\xbb\xbf')
    assert current.count(b'\r\n') == current.count(b'\n')
print(f'PASS: {len(checks)} initialization/parent behavior groups; simulated work counts only')
print('WORK COUNTS: one prebuilt + one new slot: SetParent 2 -> 1; SetBackdrop 4 -> 2; item/count/cooldown hooks retained')
