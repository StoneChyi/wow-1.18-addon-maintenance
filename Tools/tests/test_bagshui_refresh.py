"""Cache, layout reuse and event regressions against actual Bagshui functions.

Runs the diagnostic suite first, then substitutes controlled game APIs/data.
Does not measure real game performance.
"""
from pathlib import Path
import runpy

ROOT = Path(__file__).resolve().parents[2]
fixture = runpy.run_path(str(Path(__file__).with_name('test_bagshui_performance.py')))
ADDON = fixture['ADDON']
extract = fixture['extract']

SETUP = r'''
gets=0; tooltips=0; classifications=0; sorts=0; layouts=0; buttonRefreshes=0; emptyInitializations=0
BS_SUPER_WOW_LOADED=true
LAYOUT_LOOKUP_TABLE_COMPARE_DEPTH={categoryIdsGroupedBySequence=2,groupItems=2}
BS_ITEM_STOCK_STATE={NO_CHANGE='',NEW='New',UP='Up',DOWN='Down'}
BsGameInfo={itemSubclasses={Container={Bag='Bag'}}}
BsUtil={}
function BsUtil.TableClear(t) for k in pairs(t) do t[k]=nil end end
function BsUtil.TrueTableSize(t) local n=0; for k in pairs(t) do n=n+1 end; return n end
function BsUtil.TableCopy(a,b) b=b or {}; for k,v in pairs(a) do b[k]=type(v)=='table' and BsUtil.TableCopy(v) or v end; return b end
function BsUtil.ObjectsEqual(a,b,_,__,depth)
 if type(a)~='table' or type(b)~='table' then return a==b end
 for k,v in pairs(a) do if not BsUtil.ObjectsEqual(v,b[k],nil,nil,(depth or 1)-1) then return false end end
 for k in pairs(b) do if a[k]==nil then return false end end; return true
end
Bagshui.currentCharacterData={}; Bagshui.activeQuestItems={}
function Bagshui:OnEvent() end
Bagshui.config={ItemFixes={}}
BsCategories={list={all={sequence=1}},defaultCategory='all'}
function BsCategories:Categorize(item)
 classifications=classifications+1; item.bagshuiCategoryId='all'; item.bagshuiGroupId='1:1'
end
function BsCategories:GetErrors() return '' end
BsSortOrders={}
function BsSortOrders:SortGroup(items)
 sorts=sorts+1; table.sort(items,function(a,b) return a.count>b.count end)
end
L.Suffix_EmptySlot='%s Empty'; L.ItemPropFriendly_emptySlot='Empty'
BS_ITEM_PROTECTED_PROPERTIES={bagNum=true,bagType=true,slotNum=true}
BS_ITEM_NIL_PROPERTIES={itemLink=true,itemString=true,texture=true}
function BsItemInfo:Get(link,item,_,reinitialize,__,inventory)
 gets=gets+1
 if link and failingId==link then return false end
 if reinitialize then self:InitializeItem(item) end
 item.itemLink=link; item.itemString=link; item.id=link and tonumber(string.match(link,'%d+')) or 0
 if link then
  item.emptySlot=0; item.name=link; item.maxStackCount=20; item.tooltip='same'; item.texture='icon'
  if maxStackOverride then item.maxStackCount=maxStackOverride end
  self:GetTooltip(item,inventory)
 end
 return true
end
function BsItemInfo:GetTooltip(item,inventory)
 tooltips=tooltips+1
 item.tooltip=tooltipText or 'same'
 if not BS_SUPER_WOW_LOADED then item.charges=nativeCharges or 0 end
end
function BsItemInfo:GetUniqueItemId(item,bagOverride,slotOverride)
 return tostring(bagOverride or item.bagNum)..':'..tostring(slotOverride or item.slotNum)..':'..tostring(item.itemString)
end
gameSlots=3
game={[1]={link='item:10',count=4},[2]={link='item:20',count=7},[3]={}}
function GetContainerNumSlots() return gameSlots end
function ContainerIDToInventoryID(bag) return bag end
function IsInventoryItemLocked(bag) return containerLocked end
function GetContainerItemLink(bag,slot) return game[slot] and game[slot].link end
function GetContainerItemInfo(bag,slot)
 local v=game[slot] or {}; return 'icon',v.count,v.locked,nil,v.readable
end
function time() return 1000 end
local Inventory=Bagshui.prototypes.Inventory
function Inventory:PrintDebug() end
function Inventory:UpdateWindow()
 if self.windowUpdateNeeded then
  layouts=layouts+1
  for _,proxy in pairs(self.emptySlotStacks) do proxy.count=0; proxy.displayed=false end
  local buttons={}; local items=self.groupItems['1:1'] or {}
  for _,item in ipairs(items) do
   local display=item
   if item.emptySlot==1 and not item._bagshuiPreventEmptySlotStack then
    local proxy=self.emptySlotStacks['Bag']; proxy.count=proxy.count+1; display=proxy
   end
   local button={bagshuiData={item=display,groupId='1:1'},shown=true}
   function button:IsVisible() return self.shown end
   table.insert(buttons,button)
  end
  self.ui.buttons.itemSlots=buttons
 end
 self.windowUpdateNeeded=false
end
function Inventory:UpdateBagBar() end
function Inventory:UpdateToolbar() end
function Inventory:FindSpecialItems() end
function Inventory:InitUi() end
function configure(inv)
 inv.containerIds={0}; inv.myContainerIds={[0]=true}; inv.inventoryIdsToContainerIds={[0]=0}
 inv.primaryContainer={id=0,name='Backpack',texture='bag'}
 inv.inventory={}; inv.containers={[0]={numSlots=0}}
 inv.initialInventoryUpdateNeeded=true; inv.freshCache=true
 inv.lastUpdateLockedContainers={}; inv.pendingContainerChanges={}
 inv.partialStacks={}; inv.emptyGenericContainerSlots={}; inv.emptySlotStacks={}
 inv.preUpdateItemCounts={}; inv.postUpdateItemCounts={}; inv.shadowStockState={}; inv.shadowBagshuiDate={}
 inv.layout={{{categories={'all'}}}}
 inv.currentLayoutState={}; inv.proposedLayoutState={}
 for _,key in ipairs({'activeCategoryIds','activeGroups','categoriesToGroups','categoryIdsGroupedBySequence',
  'categorySequenceNumbers','groupItems','groups','sortedCategorySequenceNumbers'}) do
  inv.currentLayoutState[key]={}; inv.proposedLayoutState[key]={}; inv[key]=inv.currentLayoutState[key]
 end
 inv.ui={buttons={itemSlots={}}}
 function inv.ui:AssignItemToItemButton(button,item,group)
  buttonRefreshes=buttonRefreshes+1
  assert(button.bagshuiData.item==item and button.bagshuiData.groupId==group)
  button.refreshedCount=item.count; button.refreshedLocked=item.locked
  button.refreshedOnline=inv.online
 end
end
configure(Bags); configure(Bank); configure(Keyring)
function scan(inv) inv=inv or Bags; inv.cacheUpdateNeeded=true; return inv:UpdateCache() end
function clearCounts() gets=0; tooltips=0; classifications=0; sorts=0; layouts=0; buttonRefreshes=0 end
function ready()
 Bags:Open(); assert(gets==3 and tooltips==2 and classifications==3 and layouts==1)
 clearCounts()
end
'''


def runtime():
    lua = fixture['runtime']()
    core = (ADDON / 'Bagshui.lua').read_text(encoding='utf-8-sig')
    skeleton = core.split('BS_ITEM_SKELETON = {', 1)[1].split('\n\t},', 1)[0]
    lua.execute('BS_ITEM_SKELETON = {' + skeleton + '\n}')
    lua.execute(SETUP)
    lua.execute(extract('Components/ItemInfo.lua', 'ItemInfo:InitializeItem(', 'ItemInfo:InitializeEmptySlotItem(').replace('function ItemInfo:', 'function BsItemInfo:'))
    lua.execute(extract('Components/ItemInfo.lua', 'ItemInfo:InitializeEmptySlotItem(', 'ItemInfo:ParseItemLink(').replace('function ItemInfo:', 'function BsItemInfo:'))
    lua.execute((ADDON / 'Components/Inventory.Cache.lua').read_text(encoding='utf-8-sig'))
    # Restore the real grouping and dry-run implementation, preserving the mock UI.
    for name, following in [
        ('ValidateLayout', 'ManageDryRun'), ('ManageDryRun', 'CategorizeAndSort'),
        ('UpdateLayoutLookupTables', 'AddCategoryToLookupTables'), ('AddCategoryToLookupTables', 'CategorizeItems'),
        ('CategorizeItems', 'SortGroups'), ('SortGroups', 'UpdateWindow'),
        ('UpdateItemButtons', 'UpdateItemSlotColors'),
    ]:
        lua.execute(extract('Components/Inventory.Layout.lua', 'Inventory:' + name + '(', 'Inventory:' + following + '('))
    lua.execute(extract('Components/Bank.lua', 'Bank:Close(', 'Bank:UiFrame_OnHide('))
    # Super.Close uses a simple hidden-frame stand-in; OnHide itself is tested below.
    lua.execute('function Bags.uiFrame:Hide() self.shown=false end; function Bank.uiFrame:Hide() self.shown=false end')
    return lua


checks = []


def check(name, code):
    lua = runtime()
    lua.execute(code)
    checks.append(name)


check('repeated unlocked scans do not reload filled items or empty proxies', r'''
ready(); local proxy=Bags.emptySlotStacks.Bag; local count=proxy.count
for i=1,5 do scan() end
assert(gets==0 and tooltips==0 and not Bags.resortNeeded and not Bags.windowUpdateNeeded)
assert(Bags.emptySlotStacks.Bag==proxy and proxy.count==count)
assert(#Bags.emptyGenericContainerSlots==1 and Bags.inventory[0][3].charges==-1)
assert(Bags.multiplePartialStacks==false and Bags.containers[0].slotsFilled==2)
''')
check('nil false zero and true one locks normalize and do not reload tooltips', r'''
ready()
for _,value in ipairs({false,0,true,1,false,0}) do
 game[1].locked=value; scan(); assert(gets==0 and tooltips==0)
 assert(Bags.inventory[0][1].locked==((value==true or value==1) and 1 or 0))
end
game[1].locked=nil; scan(); assert(Bags.inventory[0][1].locked==0 and gets==0)
''')
check('stable reopen reuses grouping and layout but refreshes assigned buttons', r'''
ready(); local group=Bags.groupItems['1:1']; local order=group[1]; local buttons=Bags.ui.buttons.itemSlots
Bags.uiFrame.shown=false; Bags:Open()
assert(gets==0 and tooltips==0 and classifications==0 and sorts==0 and layouts==0)
assert(Bags.groupItems['1:1']==group and group[1]==order and Bags.ui.buttons.itemSlots==buttons)
assert(buttonRefreshes==3)
''')
check('count change while closed refreshes item and sorts before display', r'''
ready(); Bags.uiFrame.shown=false; game[1].count=12; Bags:Open()
assert(gets==1 and tooltips==1 and classifications==3 and layouts==1)
assert(Bags.groupItems['1:1'][1].id==10)
assert(Bags.inventory[0][1].bagshuiStockState=='Up')
''')
check('visible count change keeps positions and offers resort until next open', r'''
ready(); local first=Bags.groupItems['1:1'][1]
game[1].count=12; Bags:OnEvent('BAG_UPDATE',0); now=now+0.08; Bagshui:ProcessEventQueue()
assert(Bags.groupItems['1:1'][1]==first and Bags.enableResortIcon)
assert(classifications==3 and gets==1)
clearCounts(); Bags.uiFrame.shown=false; Bags:Open()
assert(Bags.groupItems['1:1'][1].id==10 and not Bags.enableResortIcon and classifications==3)
''')
check('disabled automatic resort retains positions on reopen', r'''
ready(); Bags.settings.disableAutomaticResort=true; local first=Bags.groupItems['1:1'][1]
Bags.uiFrame.shown=false; game[1].count=12; Bags:Open()
assert(Bags.groupItems['1:1'][1]==first and Bags.enableResortIcon)
''')
check('manual force resort still works when content is unchanged', r'''
ready(); Bags.forceResort=true; Bags:Update()
assert(classifications==3 and sorts==1 and layouts==1)
''')
check('cooldown event updates buttons without category or layout work', r'''
ready(); Bags:OnEvent('BAG_UPDATE_COOLDOWN'); now=now+0.08; Bagshui:ProcessEventQueue()
assert(gets==0 and tooltips==0 and classifications==0 and layouts==0 and buttonRefreshes==3)
''')
check('replacement in a filled slot invalidates grouping', r'''
ready(); game[1].link='item:30'; scan()
assert(gets==1 and Bags.resortNeeded and Bags.inventory[0][1].id==30)
''')
check('removal keeps newly free slot separate until automatic reopen resort', r'''
ready(); game[1]={}; scan()
assert(Bags.resortNeeded and Bags.inventory[0][1]._bagshuiPreventEmptySlotStack)
assert(#Bags.emptyGenericContainerSlots==2 and Bags.containers[0].slotsFilled==1)
Bags:Update(); assert(Bags.inventory[0][1]._bagshuiPreventEmptySlotStack)
Bags.uiFrame.shown=false; Bags:Open(); assert(not Bags.inventory[0][1]._bagshuiPreventEmptySlotStack)
''')
check('partial stacks remain correctly counted when every item is unchanged', r'''
game[2].link='item:10'; ready(); scan()
assert(Bags.partialStacks[10]==2 and Bags.multiplePartialStacks and gets==0)
''')
check('SuperWoW negative charges change without tooltip rescans', r'''
maxStackOverride=1; game[1].count=-5; ready()
assert(Bags.inventory[0][1].count==1 and Bags.inventory[0][1].charges==5)
game[1].count=-4; scan()
assert(gets==0 and tooltips==0 and Bags.inventory[0][1].charges==4 and Bags.resortNeeded)
''')
check('native charges still refresh while empty slots do not scan tooltips', r'''
BS_SUPER_WOW_LOADED=false; nativeCharges=5; ready(); scan()
assert(gets==0 and tooltips==2 and Bags.inventory[0][1].charges==5)
assert(Bags.inventory[0][3].charges==-1)
nativeCharges=4; scan(); assert(Bags.resortNeeded and Bags.inventory[0][1].charges==4)
''')
check('uncharged native items have no stable tooltip reloads', r'''
BS_SUPER_WOW_LOADED=false; ready(); scan()
assert(gets==0 and tooltips==0 and not Bags.resortNeeded)
''')
check('full cache requests reload all items and invalidate grouping', r'''
ready(); Bags.forceFullCacheUpdate=true; scan()
assert(gets==3 and tooltips==2 and Bags.resortNeeded and not Bags.forceFullCacheUpdate)
''')
check('recipe and character events invalidate even without count changes', r'''
ready(); Bags:OnEvent('BAGSHUI_CHARACTER_LEARNED_RECIPE'); now=now+0.08; Bagshui:ProcessEventQueue()
assert(gets==3 and tooltips==2 and classifications==3)
clearCounts(); Bags:OnEvent('BAGSHUI_CHARACTER_UPDATE'); now=now+0.08; Bagshui:ProcessEventQueue()
assert(classifications==3 and layouts==1)
''')
check('category and sort edits still force recalculation', r'''
ready(); Bags:OnEvent('BAGSHUI_CATEGORY_UPDATE'); now=now+0.08; Bagshui:ProcessEventQueue()
assert(classifications==3 and sorts==1)
clearCounts(); Bags:OnEvent('BAGSHUI_SORTORDER_UPDATE'); now=now+0.08; Bagshui:ProcessEventQueue()
assert(classifications==3 and sorts==1)
''')
check('profile and layout presentation invalidations remain conservative', r'''
ready(); Bags.windowUpdateNeeded=true; Bags:Update()
assert(classifications==3 and layouts==1)
''')
check('bank open event consumes one scan with no synthetic second refresh', r'''
Bank.events.BANKFRAME_OPENED='Open'; event='BANKFRAME_OPENED'; Bank:OnEvent(event)
assert(layouts==1 and classifications==3 and gets==3)
assert(next(Bagshui.queuedEvents.events)==nil)
clearCounts(); Bank.uiFrame.shown=false; Bank:OnEvent(event)
assert(gets==0 and classifications==0 and layouts==0 and buttonRefreshes==3)
assert(next(Bagshui.queuedEvents.events)==nil)
''')
check('independent update already queued before opening is not cancelled', r'''
Bags:QueueUpdate(); Bags:Open(); clearCounts()
assert(next(Bagshui.queuedEvents.events)~=nil)
game[1].count=9; Bags:OnEvent('BAG_UPDATE',0); now=now+0.08; Bagshui:ProcessEventQueue()
assert(gets==1 and Bags.inventory[0][1].count==9)
''')
check('bank close changes offline presentation without classification or layout', r'''
event='BANKFRAME_OPENED'; Bank:Open(); clearCounts(); event='BANKFRAME_CLOSED'
Bank:Close(); assert(not Bank.online and not Bank.uiFrame.shown)
assert(classifications==0 and layouts==0 and gets==0 and buttonRefreshes==3)
''')
check('opening a visible offline bank scans contents on physical bank arrival', r'''
event=nil; Bank:Open(); clearCounts(); event='BANKFRAME_OPENED'; Bank.events.BANKFRAME_OPENED='Open'
Bank:OnEvent(event)
assert(Bank.online and gets==3 and layouts==1 and classifications==3)
''')
check('missing item info retries without consuming opening/resort intent', r'''
failingId='item:20'; Bags:Open()
assert(layouts==0 and classifications==0 and not Bags.windowUpdateBlocked)
assert(Bags._resortOnOpen and Bags.inventory[0][2]._getItemInfoFailed)
failingId=nil; now=now+0.11; Bagshui:ProcessEventQueue()
assert(layouts==1 and classifications==3 and Bags._resortOnOpen==nil)
assert(Bags.preUpdateItemCounts['item:10']==4 and Bags.preUpdateItemCounts['item:20']==7)
''')
check('bag movement defers scans and retains old rendered layout until ready', r'''
ready(); Bags.lastEvent='ITEM_LOCK_CHANGED'; Bags.lastUpdateLockedContainers[0]=1
Bags.cacheUpdateNeeded=true; Bags:Update()
assert(gets==0 and layouts==0 and not Bags.windowUpdateBlocked)
assert(next(Bagshui.queuedEvents.events)~=nil)
now=now+0.11; Bagshui:ProcessEventQueue(); assert(gets==0 and layouts==0)
''')
check('bag size changes rebuild tracking including new empty slots', r'''
ready(); gameSlots=4; game[4]={}; scan()
assert(Bags.forceResort and #Bags.inventory[0]==4 and #Bags.emptyGenericContainerSlots==2)
Bags:Update(); assert(layouts==1 and classifications==4)
''')
check('geometry resets on reopen do not reuse an edit/expanded layout', r'''
ready(); Bags.editMode=true; Bags.expandEmptySlotStacks=true; Bags.temporarilyShowWindowHeader=true
Bags.uiFrame.shown=false; Bags:Open()
assert(layouts==1 and classifications==3 and not Bags.editMode and not Bags.expandEmptySlotStacks)
''')
check('button refresh does not reassign hidden or uninitialized buttons', r'''
ready(); local buttons=Bags.ui.buttons.itemSlots; buttons[1].shown=false
table.insert(buttons,{IsVisible=function() return true end,bagshuiData={}})
Bags:UpdateItemButtons(); assert(buttonRefreshes==2)
''')
check('split stacks preserve inventory totals and do not create false stock changes', r'''
ready(); game[1].count=2; game[3]={link='item:10',count=2}; scan()
assert(Bags.preUpdateItemCounts['item:10']==4 and Bags.partialStacks[10]==2)
assert(Bags.inventory[0][1].bagshuiStockState=='' and Bags.inventory[0][3].bagshuiStockState=='')
assert(#Bags.emptyGenericContainerSlots==0 and Bags.resortNeeded)
''')
check('item swaps restore stock state from the old positions', r'''
ready(); Bags.inventory[0][1].bagshuiStockState='Up'; Bags.inventory[0][1].bagshuiDate=950
Bags.inventory[0][2].bagshuiStockState='Down'; Bags.inventory[0][2].bagshuiDate=960
scan(); Bagshui.pickedUpItemBagNum=0; Bagshui.pickedUpItemSlotNum=1
Bagshui.putDownItemBagNum=0; Bagshui.putDownItemSlotNum=2
game[1],game[2]=game[2],game[1]; scan()
assert(Bags.inventory[0][1].bagshuiStockState=='Down' and Bags.inventory[0][1].bagshuiDate==960)
assert(Bags.inventory[0][2].bagshuiStockState=='Up' and Bags.inventory[0][2].bagshuiDate==950)
''')
check('container swaps retain per-item stock states and clear swap tracking', r'''
local bags={
 [1]={name='First',id=100,items={{link='item:10',count=4},{}}},
 [2]={name='Second',id=200,items={{link='item:20',count=7},{}}},
}
Bags.containerIds={1,2}; Bags.myContainerIds={[1]=true,[2]=true}
Bags.containers={[1]={numSlots=0},[2]={numSlots=0}}
Bags.inventoryIdsToContainerIds={[101]=1,[102]=2}
function GetContainerNumSlots(bag) return #bags[bag].items end
function GetBagName(bag) return bags[bag].name end
function GetInventoryItemLink(_,bag) return 'item:'..bags[bag].id..':0' end
function GetItemInfo(id) return 'bag','item:'..id,1,0,'Container','Bag',1,'','bagtexture' end
function GetContainerItemLink(bag,slot) return bags[bag].items[slot].link end
function GetContainerItemInfo(bag,slot)
 local item=bags[bag].items[slot]; return 'icon',item.count,item.locked
end
Bags:Open(); Bags.inventory[1][1].bagshuiStockState='Up'; Bags.inventory[1][1].bagshuiDate=950
scan(); bags[1],bags[2]=bags[2],bags[1]
Bagshui.pickedUpBagSlotNum=101; Bagshui.putDownBagSlotNum=102; scan()
assert(Bags.inventory[2][1].id==10 and Bags.inventory[2][1].bagshuiStockState=='Up')
assert(Bags.inventory[2][1].bagshuiDate==950 and #Bags.emptyGenericContainerSlots==2)
assert(next(Bags.pendingContainerChanges)==nil and Bagshui.pickedUpBagSlotNum==nil)
''')
check('settings changes keep their explicit cache and resort behavior', r'''
ready(); Bags:OnEvent('BAGSHUI_SETTING_UPDATE','defaultSortOrder',{inventoryResortOnChange=true})
now=now+0.01; Bagshui:ProcessEventQueue(); assert(classifications==3 and layouts==1)
clearCounts(); Bags:OnEvent('BAGSHUI_SETTING_UPDATE','itemSize',{inventoryWindowUpdateOnChange=true})
now=now+0.01; Bagshui:ProcessEventQueue(); assert(classifications==3 and layouts==1)
''')
check('unrelated bag updates do not scan or queue this inventory', r'''
ready(); Bags:OnEvent('BAG_UPDATE',99)
assert(gets==0 and next(Bagshui.queuedEvents.events)==nil)
''')
check('a pending open remains queued if synchronous cache is not ready', r'''
failingId='item:20'; Bags.events.BANKFRAME_OPENED='Open'; event='BANKFRAME_OPENED'
Bags:OnEvent(event); assert(Bags.cacheUpdateNeeded and next(Bagshui.queuedEvents.events)~=nil)
failingId=nil; now=now+0.2; Bagshui:ProcessEventQueue(); assert(layouts==1)
''')
check('all existing change signals invalidate reused layout results', r'''
ready()
for _,event in ipairs({'BAGSHUI_ACTIVE_QUEST_ITEM_UPDATE','BAGSHUI_EQUIPPED_HISTORY_UPDATE',
 'BAGSHUI_GAME_UPDATE','BAGSHUI_PROFESSION_ITEM_UPDATE'}) do
 clearCounts(); Bags:OnEvent(event); now=now+0.08; Bagshui:ProcessEventQueue()
 assert(classifications==3 and layouts==1)
end
''')
check('profession empty slots stay outside generic bag swap destinations', r'''
ready(); Bags.containers[0].genericType='Herb'; Bags.containers[0].isProfessionBag=true
scan(); assert(#Bags.emptyGenericContainerSlots==0)
''')

# Compare an unchanged inventory after its first layout using the same fixture.
# This is a work-count regression, not a millisecond/FPS benchmark.
lua = runtime()
lua.execute('ready(); Bags.uiFrame.shown=false; Bags:Open(); assert(gets==0 and classifications==0 and layouts==0)')
print(f'PASS: {len(checks)} cache/layout/event behavior groups; stable reopen does 0 item reloads, 0 classifications, 0 full layouts')
