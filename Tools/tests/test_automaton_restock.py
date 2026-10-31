"""Offline restocking regressions using the actual Purchases module and AceEvent.

Inventory, merchants, money and server acknowledgement are explicit client
boundaries. No user SavedVariables or actual purchases are accessed.
"""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil;string.gmatch=nil;C_Timer=nil
now=10;money=10000;actions={};messages={};frames={};cursor=false
sizes={[0]=16,[1]=0,[2]=0,[3]=0,[4]=0};bags={[0]={},[1]={},[2]={},[3]={},[4]={}}
catalog={[101]={name='Reagent',stack=20,sub='Reagent'},[202]={name='Second',stack=20,sub='Reagent'},[21177]={name='Kings',stack=100,sub='Reagent'},[900]={name='Bag',stack=1,sub='Bag'}}
merchant={{id=101,price=10,pack=1,stock=-1}};inventory={}
function GetTime()return now end
function GetMoney()return money end
function CursorHasItem()return cursor end
function UnitName(unit)if unit=='player'then return 'Healer'else return 'Vendor'end end
function GetRealmName()return 'Realm'end
function GetLocale()return 'zhCN'end
function GetContainerNumSlots(bag)return assert(sizes[bag],'invalid bag')end
function GetContainerItemLink(bag,slot)
 assert(slot>=1 and slot<=sizes[bag],'invalid bag slot')
 local item=bags[bag][slot];return item and ('item:'..item.id..':0:0:0')
end
function GetContainerItemInfo(bag,slot)
 assert(slot>=1 and slot<=sizes[bag],'invalid bag slot')
 local item=bags[bag][slot];if item then return 'icon',item.count,item.locked,item.quality or 1 end
end
function GetInventoryItemLink(unit,slot)
 assert(unit=='player');local id=inventory[slot];return id and ('item:'..id..':0:0:0')
end
function GetItemInfo(input)
 if type(input)=='number' and numericUsage then error('Usage: GetItemInfo(itemLink)')end
 local id=tonumber(input)
 if not id and type(input)=='string'then local _,_,s=string.find(input,'item:(%d+)');id=tonumber(s)end
 local item=catalog[id];if not item or item.uncached then return end
 if standardInfo then return item.name,'item:'..id..':0:0:0',1,1,1,'Trade Goods',item.sub,item.stack end
 return item.name,'item:'..id..':0:0:0',1,1,'Trade Goods',item.sub,item.stack
end
function GetMerchantNumItems()return table.getn(merchant)end
function GetMerchantItemInfo(index)
 local item=merchant[index];if not item then return end
 return catalog[item.id].name,'icon',item.price,item.pack,item.stock,1,item.extended
end
function GetMerchantItemLink(index)
 local item=merchant[index];return item and ('item:'..item.id..':0:0:0')
end
function GetMerchantItemMaxStack(index)return math.floor(catalog[merchant[index].id].stack/merchant[index].pack)end
function Count(id)
 local result=0;for bag=0,4 do for _,item in pairs(bags[bag])do if item.id==id then result=result+item.count end end end;return result
end
function Fill(id,count)
 for bag=0,4 do for slot,item in pairs(bags[bag])do if item.id==id then bags[bag][slot]=nil end end end
 if count>0 then bags[0][1]={id=id,count=count}end
end
function Acknowledge(action,withCount,withMoney)
 if withCount~=false then
  local existing=Count(action.id);Fill(action.id,existing+action.pack)
 end
 if withMoney~=false then money=money-action.price end
 if action.stock>0 then merchant[action.index].stock=merchant[action.index].stock-1 end
end
function BuyMerchantItem(index,amount)
 assert(MerchantFrame:IsShown() and MerchantFrame.selectedTab==1,'purchase with merchant unavailable')
 assert(amount==1,'restock must issue one merchant pack, not item count')
 local item=assert(merchant[index],'invalid merchant slot')
 assert(item.stock~=0 and item.pack>0 and money>=item.price,'invalid current purchase budget')
 local action={index=index,id=item.id,pack=item.pack,price=item.price,stock=item.stock}
 table.insert(actions,action)
 if purchaseError then error('native purchase failed')end
 if synchronousAck then Acknowledge(action)end
end
function CreateFrame(kind,name,parent)
 local f={events={},scripts={},shown=false,name=name}
 function f:RegisterEvent(event)self.events[event]=true end
 function f:UnregisterEvent(event)self.events[event]=nil end
 function f:UnregisterAllEvents()self.events={}end
 function f:SetScript(event,fn)self.scripts[event]=fn end
 function f:GetScript(event)return self.scripts[event]end
 function f:Show()self.shown=true end
 function f:Hide()self.shown=false end
 function f:IsShown()return self.shown end
 f.IsVisible=f.IsShown
 if name then _G[name]=f end;table.insert(frames,f);return f
end
MerchantFrame=CreateFrame('Frame');MerchantFrame.selectedTab=1;MerchantFrame:Show()
DEFAULT_CHAT_FRAME={AddMessage=function(_,message)table.insert(messages,message)end}
function geterrorhandler()return function(message)table.insert(messages,message)end end
function AceLibrary(name)
 assert(name=='AceLocale-2.2')
 return{new=function()return setmetatable({RegisterTranslations=function(self,locale,fn)for k,v in pairs(fn())do self[k]=v end end},{__index=function(_,key)return key end})end}
end
Automaton={modules={},dbs={},db={char={disabledModules={Purchases=true}},profile={moduleScope='char'}}}
function Automaton:AcquireDBNamespace(name)self.dbs[name]=self.dbs[name]or{profile={}};return self.dbs[name]end
function Automaton:RegisterDefaults(name,scope,defaults)
 local db=self:AcquireDBNamespace(name)[scope];for key,value in pairs(defaults)do if db[key]==nil then db[key]=value end end
end
function Automaton:SetDisabledAsDefault()end
function Automaton:IsModuleActive(name)return not self.db.char.disabledModules[name]end
function Automaton:NewModule(name)
 local m={name=name,events={}};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(event,handler)self.events[event]=handler or event end
 function m:UnregisterEvent(event)self.events[event]=nil end
 function m:UnregisterAllEvents()self.events={}end
 function m:IsEventRegistered(event)return self.events[event]~=nil end
 function m:Print(message)table.insert(messages,message)end
 m.print=m.Print;m.Debug=function()end
 return m
end
function activate(enabled)
 if enabled then M:OnEnable()else M:OnDisable()end
 Automaton.db.char.disabledModules.Purchases=enabled and nil or true
end
function emit(eventName,...)
 local handler=M.events[eventName]
 if handler then if type(handler)=='string'then M[handler](M,unpack(arg))else handler(unpack(arg))end end
end
function advance(seconds)
 now=now+seconds;local oldThis,oldArg=this,arg1;this=AceScheduler.frame;arg1=seconds
 local update=AceScheduler.frame:GetScript('OnUpdate');if update then update()end
 this,arg1=oldThis,oldArg
end
function ticks(n)for i=1,n do advance(.16)end end
function SetTarget(category,id,target)
 M.db.profile[category..'_quantity']['Healer-Realm']=target
 M.db.profile[category..'_reagents']['Healer-Realm']=M.db.profile[category..'_reagents']['Healer-Realm']or{}
 M.db.profile[category..'_reagents']['Healer-Realm'][tostring(id)]=catalog[id].name
end
function Begin(id,target,pack)
 SetTarget('Purchases',id,target);merchant[1].id=id;merchant[1].pack=pack or 1
 activate(true);emit('MERCHANT_SHOW')
end
'''


def runtime(saved=""):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    source=(ROOT/'Interface/AddOns/!Libs/Ace2/AceEvent-2.0/AceEvent-2.0.lua').read_text(encoding='utf-8-sig')
    start=source.index('local delayRegistry\nlocal tmp = {}')
    end=source.index('function AceEvent:UnregisterEvent(event)',start)
    lua.execute(r'''
AceScheduler={frame=CreateFrame('Frame')}
function AceScheduler:argCheck(value,index,...)
 for _,allowed in ipairs({...})do if type(value)==allowed then return end end
 error('AceEvent invalid argument '..index..': '..type(value))
end
function AceScheduler:error(message)error(message)end
local AceEvent=AceScheduler
local function new()return{}end
local function del(t)for key in pairs(t)do t[key]=nil end;return nil end
local function table_setn()end
'''+source[start:end])
    lua.execute(saved)
    lua.execute((ROOT/'Interface/AddOns/Automatonex/Modules/Purchases.lua').read_text(encoding='utf-8-sig'))
    lua.execute(r'''
M=Automaton.modules.Purchases
M.ScheduleEvent=AceScheduler.ScheduleEvent;M.CancelScheduledEvent=AceScheduler.CancelScheduledEvent
M.IsEventScheduled=AceScheduler.IsEventScheduled;M:OnInitialize()
''')
    return lua


def install_vendor(lua):
    lua.execute(r'''
C={global={autorepair='1',autosell='1'},automation={enabled='1'}}
T=setmetatable({},{__index=function(_,key)return key end})
pfUI={};function pfUI:RegisterModule(name,version,fn)fn()end
function GetBorderSize()return 1,1 end
function GetPerfectPixel()return 1 end
function SkinButton()end
function CreateGoldString(value)return tostring(value)end
function CanMerchantRepair()return true end
repairCost=100;repairs=0;sales={}
function GetRepairAllCost()return repairCost,true end
function RepairAllItems()repairs=repairs+1;if not repairDeferred then money=money-repairCost;repairCost=0 end end
function UseContainerItem(bag,slot)
 assert(MerchantFrame:IsShown()and MerchantFrame.selectedTab==1 and not cursor)
 local item=assert(bags[bag][slot]);table.insert(sales,{bag=bag,slot=slot,id=item.id})
 if not saleDeferred then bags[bag][slot]=nil;money=money+3 end
end
function MerchantFrame_Update()end
WidgetMethods={}
function WidgetMethods:SetWidth(value)self.width=value end
function WidgetMethods:SetHeight(value)self.height=value end
function WidgetMethods:SetPoint(...)self.point={...}end
function WidgetMethods:ClearAllPoints()self.point=nil end
function WidgetMethods:CreateTexture(name,layer)return NewWidget('Texture',name,self)end
function WidgetMethods:SetTexture(value)self.texture=value end
function WidgetMethods:SetDesaturated(value)self.desaturated=value end
function WidgetMethods:Enable()self.enabled=true end
function WidgetMethods:Disable()self.enabled=false end
function WidgetMethods:SetOwner(value)self.owner=value end
function WidgetMethods:AddLine(value)self.line=value end
local originalFrame=CreateFrame
function NewWidget(kind,name,parent)
 local f=originalFrame(kind,name,parent);f.kind=kind;f.parent=parent;setmetatable(f,{__index=WidgetMethods})
 function f:Show()local was=self.shown;self.shown=true;if not was and self.scripts.OnShow then invoke(self,'OnShow')end end
 function f:Hide()local was=self.shown;self.shown=false;if was and self.scripts.OnHide then invoke(self,'OnHide')end end
 return f
end
CreateFrame=NewWidget
function invoke(frame,script)local old=this;this=frame;if frame.scripts[script]then frame.scripts[script]()end;this=old end
MerchantRepairItemButton=NewWidget('Button');MerchantBuyBackItemItemButton=NewWidget('Button')
GameTooltip=NewWidget('GameTooltip')
Automaton.dbs.Sell={profile={ignore={},custom={['101']='Reagent',['202']='Second'}}}
function vendorEvent(name)
 local prev=event;event=name;invoke(pfUI.autovendor.frame,'OnEvent');event=prev
 emit(name)
end
function vendorTicks(n)
 for i=1,n do
  if pfUI.autovendor.frame:IsShown()then invoke(pfUI.autovendor.frame,'OnUpdate')end
  advance(.16)
 end
end
''')
    contract=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
    contract(lua.globals().WidgetMethods,lua.globals().NewWidget)
    lua.execute("MerchantRepairText=NewWidget('FontString');MerchantRepairText:SetFontObject(GameFontNormal)")
    lua.execute((ROOT/'Interface/AddOns/pfUI/modules/autovendor.lua').read_text(encoding='utf-8-sig'))
    lua.execute("assert(pfUI.autovendor:ImportLegacyRules());assert(pfUI.autovendor:SetLegacyFallback(false))")


class Restock(unittest.TestCase):
    def test_duplicate_categories_are_inventory_targets_not_sum(self):
        lua=runtime()
        lua.execute(r'''
SetTarget('Purchases',101,10);SetTarget('Purchases1',101,20);SetTarget('Purchases2',101,15)
local targets=M:GetRestockTargets();assert(targets['101']==20 or targets[101]==20)
Fill(101,20);activate(true);emit('MERCHANT_SHOW');ticks(8);assert(#actions==0)
''')

    def test_pack_size_and_pending_ack_do_not_duplicate(self):
        lua=runtime()
        lua.execute(r'''
Begin(101,12,5);ticks(2);assert(#actions==1 and actions[1].pack==5)
emit('MERCHANT_SHOW');ticks(8);assert(#actions==1,'duplicate MERCHANT_SHOW reset budget')
Acknowledge(actions[1]);ticks(2);assert(#actions==2)
Acknowledge(actions[2]);ticks(2);assert(#actions==3)
Acknowledge(actions[3]);ticks(4);assert(#actions==3 and Count(101)==15)
''')

    def test_requires_both_count_and_money_ack(self):
        lua=runtime()
        lua.execute(r'''
Begin(101,3,1);ticks(2);assert(#actions==1)
Acknowledge(actions[1],true,false);ticks(3);assert(#actions==1,'bag-only acknowledgement sent another purchase')
money=money-actions[1].price;ticks(3);assert(#actions==2)
''')

    def test_timeout_stops_until_close_reopen(self):
        lua=runtime()
        lua.execute(r'''
Begin(101,3,1);ticks(2);assert(#actions==1);advance(6);ticks(3)
emit('MERCHANT_SHOW');ticks(3);assert(#actions==1,'timeout blindly retried')
emit('MERCHANT_CLOSED');emit('MERCHANT_SHOW');ticks(2);assert(#actions==2)
''')

    def test_free_items_only_require_inventory_ack(self):
        lua=runtime()
        lua.execute(r'''
merchant[1].price=0;money=0;Begin(101,2,1);ticks(2);assert(#actions==1)
Acknowledge(actions[1]);ticks(2);assert(#actions==2)
Acknowledge(actions[2]);ticks(2);assert(#actions==2)
''')

    def test_budget_stock_and_capacity_are_checked(self):
        for setup in ['money=0','merchant[1].stock=0','sizes[0]=0','catalog[101].uncached=true']:
            lua=runtime()
            lua.execute(setup+";Begin(101,3,1);ticks(5);assert(#actions==0)")

    def test_cancel_disable_close_and_buyback_stop_dispatch(self):
        for stop in ["M:CancelRestock('manual')", "activate(false)", "emit('MERCHANT_CLOSED')", "MerchantFrame:Hide()", "MerchantFrame.selectedTab=2"]:
            lua=runtime()
            lua.execute("Begin(101,3,1);ticks(2);assert(#actions==1);"+stop+";Acknowledge(actions[1]);ticks(5);assert(#actions==1)")

    def test_price_pack_link_or_target_changes_stop_old_request(self):
        for change in ['merchant[1].price=11','merchant[1].pack=2','merchant[1].id=202',"M.db.profile.Purchases_quantity['Healer-Realm']=0"]:
            lua=runtime()
            lua.execute("Begin(101,3,1);ticks(2);assert(#actions==1);Acknowledge(actions[1]);"+change+";ticks(5);assert(#actions==1)")

    def test_disabling_and_reenabling_cannot_revive_old_queue(self):
        lua=runtime()
        lua.execute(r'''
Begin(101,3,1);ticks(2);activate(false);activate(true);Acknowledge(actions[1]);ticks(4);assert(#actions==1)
''')

    def test_disabled_settings_safe_and_validated(self):
        lua=runtime()
        lua.execute(r'''
local options=M._options.original.args
numericUsage=true
options.add.set('00101');assert(M.db.profile.Purchases_reagents['Healer-Realm']['101']=='Reagent')
assert(not M.restockActive and Automaton.db.char.disabledModules.Purchases)
for _,value in ipairs({'-1','0','1.5','not-an-id'})do options.add.set(value)end
assert(M.db.profile.Purchases_reagents['Healer-Realm']['-1']==nil)
options.quantity.set(20);assert(options.quantity.get()==20)
options.remove.set('00101');assert(M.db.profile.Purchases_reagents['Healer-Realm']['101']==nil)
''')

    def test_saved_role_lists_are_not_migrated(self):
        lua=runtime(r'''
Automaton.dbs.Purchases={profile={Purchases_quantity={default=7,['Healer-Realm']=10},Purchases_reagents={default={},['Healer-Realm']={['101']='Reagent'},['Other-Realm']={['202']='Keep'}},custom='keep'}}
savedProfile=Automaton.dbs.Purchases.profile;savedLists=savedProfile.Purchases_reagents;savedMine=savedLists['Healer-Realm'];savedOther=savedLists['Other-Realm']
''')
        lua.execute(r'''
assert(M.db.profile==savedProfile and M.db.profile.Purchases_reagents==savedLists)
assert(savedLists['Healer-Realm']==savedMine and savedLists['Other-Realm']==savedOther)
activate(true);activate(false);assert(savedProfile.custom=='keep'and savedOther['202']=='Keep')
''')

    def test_search_item_matches_id_and_never_scans_slot_zero(self):
        lua=runtime()
        lua.execute(r'''
bags[0][1]={id=101,count=2};bags[0][2]={id=202,count=7};sizes[1]=2;bags[1][2]={id=101,count=3}
assert(M:SearchItem('101')==5)
''')


    def test_money_only_ack_is_not_a_completed_purchase(self):
        lua=runtime()
        lua.execute(r'''
Begin(101,3,1);ticks(2);Acknowledge(actions[1],false,true);ticks(3)
assert(#actions==1,'money-only change accepted as item delivery')
Fill(101,1);ticks(3);assert(#actions==2)
''')

    def test_metadata_layouts_and_special_bags_do_not_invent_space(self):
        for standard in [False,True]:
            lua=runtime()
            lua.execute("standardInfo="+str(standard).lower()+r'''
assert(M:GetRestockCapacity('item:101:0:0:0')==320)
sizes[0]=0;sizes[1]=2
assert(M:GetRestockCapacity('item:101:0:0:0')==0,'uncached/unknown bag assumed generic')
inventory[20]=900;assert(M:GetRestockCapacity('item:101:0:0:0')==40)
catalog[900].sub='Soul Bag';assert(M:GetRestockCapacity('item:101:0:0:0')==0)
bags[1][1]={id=101,count=7};assert(M:GetRestockCapacity('item:101:0:0:0')==13)
bags[1][1].locked=true;assert(M:GetRestockCapacity('item:101:0:0:0')==0)
''')

    def test_vendor_sale_wait_and_manual_bulk_precedence(self):
        lua=runtime()
        lua.execute(r'''
selling=true;pfUI={autovendor={IsSelling=function()return selling end}}
Begin(101,3,1);ticks(5);assert(#actions==0)
selling=false;ticks(2);assert(#actions==1)
''')
        lua=runtime()
        lua.execute(r'''
pfUI={buyemall={IsBusy=function()return true end}}
Begin(101,3,1);ticks(3);assert(#actions==0)
pfUI.buyemall.IsBusy=function()return false end;ticks(4);assert(#actions==0,'manual purchase did not retire automatic restocking')
''')

    def test_old_scheduler_callback_cannot_start_new_session(self):
        lua=runtime()
        lua.execute(r'''
Begin(101,3,1)
local old=AceScheduler.delayRegistry.Automaton_Restock.event
emit('MERCHANT_CLOSED');emit('MERCHANT_SHOW')
local current=AceScheduler.delayRegistry.Automaton_Restock
old();assert(#actions==0,'old callback sent a purchase from newer session')
assert(AceScheduler.delayRegistry.Automaton_Restock==current,'old callback replaced current scheduler task')
ticks(2);assert(#actions==1)
''')

    def test_manual_pending_and_uncertain_receipts_block_automatic_purchase(self):
        lua=runtime();install_vendor(lua)
        lua.execute(r'''
manualState='pending'
pfUI.buyemall={IsBusy=function()return false end,CanStartRestock=function()
 if manualState then return false,manualState end
 return true
end}
SetTarget('Purchases',101,3);activate(true);vendorEvent('MERCHANT_SHOW')
vendorTicks(10);assert(#actions==0,'closed manual purchase UI was mistaken for settled request')
manualState=nil;vendorTicks(3);assert(#actions==1,'settled manual request blocked fresh restock session')
''')
        lua=runtime();install_vendor(lua)
        lua.execute(r'''
manualState='pending'
pfUI.buyemall={IsBusy=function()return false end,CanStartRestock=function()return not manualState,manualState end}
SetTarget('Purchases',101,3);activate(true);vendorEvent('MERCHANT_SHOW');vendorTicks(3)
manualState='uncertain';vendorTicks(3);assert(#actions==0)
manualState=nil;vendorEvent('MERCHANT_SHOW');vendorTicks(4)
assert(#actions==0,'uncertain manual receipt resumed automatic buying within same session')
vendorEvent('MERCHANT_CLOSED');vendorEvent('MERCHANT_SHOW');vendorTicks(3);assert(#actions==1)
''')

    def test_extended_cost_and_native_failure_stop_automatic_purchase(self):
        lua=runtime()
        lua.execute("GetMerchantItemCostInfo=function()return 1 end;Begin(101,3,1);ticks(5);assert(#actions==0)")
        lua=runtime()
        lua.execute(r'''
purchaseError=true;Begin(101,3,1);ticks(2);assert(#actions==1)
ticks(15);assert(#actions==1,'native error caused blind retry')
assert(M:CanStartManualPurchase()==false,'uncertain purchase was treated as completed')
''')

    def test_editing_targets_cancels_live_session_without_changing_disabled(self):
        lua=runtime()
        lua.execute(r'''
Begin(101,3,1);ticks(2);M._options.original.args.quantity.set(20)
Acknowledge(actions[1]);ticks(4);assert(#actions==1)
assert(M._options.original.args.quantity.get()==20 and M.restockActive)
''')


    def test_actual_vendor_serializes_repair_sale_and_restock_without_selling_targets(self):
        # Regression: retaining an already-settled repair until after sale income
        # arrived made the new balance look like an unacknowledged repair.
        lua=runtime();install_vendor(lua)
        lua.execute(r'''
SetTarget('Purchases',101,4);Fill(101,2);bags[0][2]={id=202,count=1}
activate(true);assert(M.merchantOwner==pfUI.autovendor and not M.events.MERCHANT_SHOW)
vendorEvent('MERCHANT_SHOW');vendorTicks(3)
assert(repairs==1 and #sales==1 and sales[1].id==202,'restock target sold or unrelated sale lost')
assert(#actions==1,'restock did not follow settled sale')
assert(not pfUI.autovendor:CanSell('item:101:0:0:0',1))
Acknowledge(actions[1]);vendorTicks(3);assert(#actions==2)
Acknowledge(actions[2]);vendorTicks(4);vendorEvent('MERCHANT_SHOW');vendorTicks(3)
assert(repairs==1 and #sales==1 and #actions==2,'duplicate session repeated work')
local rules=pfUI.autovendor:GetRules();assert(rules.custom['101']=='Reagent'and not rules.ignore['101'],'transient protection rewrote saved lists')
''')

    def test_actual_vendor_waits_for_repair_and_sale_feedback(self):
        lua=runtime();install_vendor(lua)
        lua.execute(r'''
repairDeferred=true;saleDeferred=true;SetTarget('Purchases',101,2);bags[0][2]={id=202,count=1}
activate(true);vendorEvent('MERCHANT_SHOW');vendorTicks(4);assert(#actions==0)
money=money-repairCost;repairCost=0;vendorTicks(3);assert(#actions==0,'unsettled sale was ignored')
bags[0][2]=nil;money=money+3;vendorTicks(3);assert(#actions==1)
''')

    def test_actual_vendor_handoff_and_manual_protection_do_not_migrate_preferences(self):
        lua=runtime();install_vendor(lua)
        lua.execute(r'''
SetTarget('Purchases',101,3);local originalLists=M.db.profile.Purchases_reagents
activate(true);vendorEvent('MERCHANT_SHOW');vendorTicks(2);assert(#actions==1)
pfUI.autovendor:SetLegacyFallback(true);assert(M.merchantOwner==nil and M.events.MERCHANT_SHOW)
Acknowledge(actions[1]);vendorTicks(4);assert(#actions==1,'handoff continued cancelled work')
vendorEvent('MERCHANT_CLOSED');pfUI.autovendor:SetLegacyFallback(false)
assert(M.merchantOwner==pfUI.autovendor and not M.events.MERCHANT_SHOW)
pfUI.autovendor:ProtectPurchase('item:202:0:0:0');assert(not pfUI.autovendor:CanSell('item:202:0:0:0',1))
assert(pfUI.autovendor:GetRules().custom['202']=='Second'and not pfUI.autovendor:GetRules().ignore['202'])
assert(M.db.profile.Purchases_reagents==originalLists and M.db.profile.Purchases_quantity['Healer-Realm']==3)
''')

    def test_extended_cost_flag_blocks_without_cost_api(self):
        for value in ('true','1'):
            lua=runtime()
            lua.execute("assert(GetMerchantItemCostInfo==nil);merchant[1].extended="+value+r'''
Begin(101,3,1);ticks(8);assert(#actions==0,'extended-cost offer dispatched without cost API')
''')
            lua=runtime()
            lua.execute("Begin(101,3,1);ticks(2);merchant[1].extended="+value+r'''
Acknowledge(actions[1]);ticks(6);assert(#actions==1,'offer changing to extended cost kept buying')
''')

    def test_late_receipt_after_reopen_restores_transient_sale_protection(self):
        lua=runtime();install_vendor(lua)
        lua.execute(r'''
SetTarget('Purchases',101,3);activate(true);vendorEvent('MERCHANT_SHOW');vendorTicks(2)
assert(#actions==1 and M.pendingPurchase)
vendorEvent('MERCHANT_CLOSED')
M.db.profile.Purchases_reagents['Healer-Realm']['101']=nil
vendorEvent('MERCHANT_SHOW');vendorTicks(2)
assert(not M:IsRestockProtected('101'),'fixture still protected by new target list')
assert(not pfUI.autovendor.purchaseProtected['101'],'fixture retained old temporary protection')
Acknowledge(actions[1]);vendorTicks(2)
assert(not M.pendingPurchase and pfUI.autovendor.purchaseProtected['101'],'late receipt failed to restore temporary protection')
assert(not pfUI.autovendor:CanSell('item:101:0:0:0',1))
pfUI.autovendor:Resume();vendorTicks(4);assert(#sales==0 and #actions==1)
assert(not pfUI.autovendor:GetRules().ignore['101'] and pfUI.autovendor:GetRules().custom['101']=='Reagent')
''')

    def test_actual_legacy_sell_rechecks_queue_after_restock_session_starts(self):
        lua=runtime()
        lua.execute(r'''
TOOLTIP_UPDATE_TIME=.1;floor=math.floor;ITEM_QUALITY_COLORS={[0]={hex='|cff9d9d9d'}}
sales={};Automaton.dbs.Sell={profile={ignore={},custom={['101']='Reagent',['202']='Second'}}}
function PickupContainerItem(bag,slot)
 assert(not cursor and bags[bag][slot]);cursor={bag=bag,slot=slot}
end
function MerchantItemButton_OnClick(button)
 assert(button=='LeftButton' and cursor and MerchantFrame:IsShown())
 local item=bags[cursor.bag][cursor.slot]
 table.insert(sales,{id=item.id});bags[cursor.bag][cursor.slot]=nil;cursor=false;money=money+3
end
beforeSellFrames=#frames
''')
        lua.execute((ROOT/'Interface/AddOns/Automatonex/Modules/Sell.lua').read_text(encoding='utf-8-sig'))
        lua.execute(r'''
local seller=Automaton.modules.Sell;seller:OnInitialize();seller:OnEnable()
local pump=frames[beforeSellFrames+1]
SetTarget('Purchases',101,3);bags[0][1]={id=101,count=2,quality=0};bags[0][2]={id=202,count=1,quality=0}
activate(true);seller:MERCHANT_SHOW()
assert(seller:IsSelling() and #pump.junk==2,'fixture did not queue target before restock')
emit('MERCHANT_SHOW');assert(seller:ProcessLink('item:101:0:0:0')==0)
for i=1,4 do
 if pump:IsShown()then this=pump;arg1=.16;pump:GetScript('OnUpdate')()end
 advance(.16)
end
assert(#sales==1 and sales[1].id==202,'legacy queue sold late-protected restock target')
assert(Count(101)==2 and not seller:IsSelling() and #actions==1)
assert(seller.db.profile.custom['101']=='Reagent' and not seller.db.profile.ignore['101'])
''')

    def test_actual_vendor_handles_synchronous_repair_callbacks(self):
        for callback in ('PLAYER_MONEY','MERCHANT_CLOSED'):
            with self.subTest(callback=callback):
                lua=runtime();install_vendor(lua)
                lua.globals().repairCallback=callback
                lua.execute(r'''
function RepairAllItems()
 repairs=repairs+1;assert(repairs==1,'repair callback recursively repaired again')
 money=money-repairCost;repairCost=0
 if repairCallback=='MERCHANT_CLOSED'then MerchantFrame:Hide()end
 vendorEvent(repairCallback)
 assert(pfUI.autovendor.repairPending==nil,'synchronous callback did not consume pending repair')
 assert(#actions==0,'repair callback sent purchase before returning')
end
SetTarget('Purchases',101,3);activate(true);vendorEvent('MERCHANT_SHOW')
assert(repairs==1 and not pfUI.autovendor.repairPending)
if repairCallback=='MERCHANT_CLOSED'then
 vendorTicks(8);assert(#actions==0 and not M.restockSession,'closed repair callback left live purchase work')
 MerchantFrame:Show();vendorEvent('MERCHANT_SHOW')
end
vendorTicks(3);assert(#actions==1 and repairs==1)
vendorEvent('MERCHANT_SHOW');vendorTicks(3);assert(#actions==1 and repairs==1,'duplicate merchant event repeated pending work')
''')

    def test_selling_progress_refreshes_timeout_but_no_progress_retires_session(self):
        lua=runtime()
        lua.execute(r'''
selling=true;pfUI={autovendor={IsSelling=function()return selling end}}
Begin(101,3,1)
for i=1,100 do money=money+1;ticks(1)end
assert(now-M.restockSession.started>10 and not M.restockSession.cancelled and #actions==0,'ongoing sale progress cancelled restock')
selling=false;ticks(2);assert(#actions==1,'restock did not follow long progressing sale')
''')
        lua=runtime()
        lua.execute(r'''
selling=true;pfUI={autovendor={IsSelling=function()return selling end}}
Begin(101,3,1);ticks(1);ticks(62)
assert(not M.restockSession.cancelled and #actions==0,'stalled session stopped before ten seconds')
ticks(2);assert(M.restockSession.cancelled and #actions==0,'ten seconds without progress did not stop restock')
selling=false;ticks(5);assert(#actions==0,'timed-out sale queue later resumed restock')
''')


if __name__=='__main__':
    unittest.main(verbosity=2)
