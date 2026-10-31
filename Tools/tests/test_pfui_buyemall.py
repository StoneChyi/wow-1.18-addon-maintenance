"""Real bulk-buy UI and transaction engine with strict legacy frame/font mocks.

No actual merchant interaction or SavedVariables writes. The mock server sells
quantity items per BuyMerchantItem request unit and delivers observable receipts.
"""
from pathlib import Path
import sys
import unittest
ROOT=Path(__file__).resolve().parents[2]
sys.path.insert(0,str(ROOT/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

MOCK=r'''
string.match=nil;C_Timer=nil
floor=math.floor;ceil=math.ceil;min=math.min;mod=math.mod
now=0;cash=10000;shift=true;ctrl=false;errors={};messages={};calls={};original={};frames={};bags={};bagTypes={};bagSlots={[0]=6};catalog={}
C={global={buyemall='1'}};T=setmetatable({},{__index=function(_,k)return k end})
OKAY='Okay';CANCEL='Cancel';YES='Yes';NO='No';GREEN_FONT_COLOR_CODE='';GREEN_FONT_COLOR={r=0,g=1,b=0};HIGHLIGHT_FONT_COLOR={r=1,g=1,b=1}
pfUI={font_default='missing-font'};function pfUI:RegisterModule(name,version,fn)assert(name=='buyemall'and version=='vanilla');fn()end
MoneyTypeInfo={};StaticPopupDialogs={}
Automaton={modules={Purchases={cancelled=0,CancelRestock=function(self,reason)assert(reason=='manual');self.cancelled=self.cancelled+1 end}}}
pfUI.autovendor={IsSelling=function()return selling end}
function GetTime()return now end
function GetMoney()return cash end
function IsShiftKeyDown()return shift end
function IsControlKeyDown()return ctrl end
function geterrorhandler()return function(err)table.insert(errors,err)end end
DEFAULT_CHAT_FRAME={AddMessage=function(_,s)table.insert(messages,s)end}
function link(id)return '|cffffffff|Hitem:'..id..':0:0:0|h[Same Name]|h|r'end
function GetMerchantItemInfo(i)local x=offers[i];if x then return x.name,'tex',x.price,x.preset,x.stock,1,x.extended end end
function GetMerchantItemLink(i)return offers[i]and link(offers[i].id)end
function GetItemInfo(value)
 local _,_,id=string.find(tostring(value),'item:(%d+):');id=tonumber(id)or tonumber(value)
 local x=catalog[id];if not x then return end
 if layout=='old' then return x.name,link(id),1,1,'Trade Goods',x.subtype,x.stack,'' end
 return x.name,link(id),1,1,1,'Trade Goods',x.subtype,x.stack,''
end
function GetContainerNumSlots(bag)return bagSlots[bag]or 0 end
function GetContainerItemLink(bag,slot)local x=bags[bag]and bags[bag][slot];return x and link(x.id)end
function GetContainerItemInfo(bag,slot)local x=bags[bag]and bags[bag][slot];if x then return 'tex',x.count,x.locked end end
function GetInventoryItemLink(unit,slot)local id=bagTypes[slot-19];return id and link(id)end
function put(id,count,bag,slot)bag=bag or 0;slot=slot or 1;bags[bag]=bags[bag]or{};bags[bag][slot]={id=id,count=count}end
function deliver(i,n)
 local o=offers[i];local amount=o.preset*n;cash=cash-o.price*n
 if o.stock~=-1 then o.stock=o.stock-n end
 local stack=catalog[o.id].stack
 for b=0,4 do for s=1,GetContainerNumSlots(b)do
  local x=bags[b]and bags[b][s]
  if x and x.id==o.id and x.count<stack then local take=math.min(amount,stack-x.count);x.count=x.count+take;amount=amount-take end
 end end
 for b=0,4 do for s=1,GetContainerNumSlots(b)do
  if amount>0 and not(bags[b]and bags[b][s])then local take=math.min(amount,stack);put(o.id,take,b,s);amount=amount-take end
 end end
 assert(amount==0,'client capacity overrun')
end
function BuyMerchantItem(i,n)
 assert(MerchantFrame:IsVisible()and MerchantFrame.selectedTab==1 and not selling)
 assert(type(n)=='number'and n>0 and n==floor(n),'invalid quantity')
 table.insert(calls,{i,n})
 if failBuy then error('request failed')end
 if onBuy then onBuy()end
 if not deferred then deliver(i,n)end
end
local methods={}
function newObject(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,scripts={},events={},shown=true,enabled=true},{__index=methods})
 if name then _G[name]=o end;table.insert(frames,o);return o
end
function invoke(obj,event,...)
 local prev,prevArg=this,arg1;this=obj;arg1=select(1,...);if obj.scripts[event]then obj.scripts[event](...)end;this=prev;arg1=prevArg
end
function methods:SetScript(k,v)self.scripts[k]=v end
function methods:GetScript(k)return self.scripts[k]end
function methods:RegisterEvent(k)self.events[k]=true end
function methods:SetWidth(v)self.width=v end
function methods:SetHeight(v)self.height=v end
function methods:SetFrameStrata(v)self.strata=v end
function methods:SetToplevel(v)self.top=v end
function methods:EnableMouse(v)self.mouse=v end
function methods:EnableKeyboard(v)self.keyboard=v end
function methods:SetBackdropColor(...)self.bg={...}end
function methods:SetJustifyH(v)self.justify=v end
function methods:SetPoint(...)self.point={...}end
function methods:ClearAllPoints()self.point=nil end
function methods:SetAllPoints(v)self.all=v end
function methods:SetNormalTexture(v)self.normal=v end
function methods:SetPushedTexture(v)self.pushed=v end
function methods:SetDisabledTexture(v)self.disabledTexture=v end
function methods:Enable()self.enabled=true end
function methods:Disable()self.enabled=false end
function methods:IsEnabled()return self.enabled and 1 or 0 end
function methods:Show()local was=self.shown;self.shown=true;if not was then invoke(self,'OnShow')end end
function methods:Hide()local was=self.shown;self.shown=false;if was then invoke(self,'OnHide')end end
function methods:IsShown()return self.shown end
function methods:IsVisible()return self.shown and(not self.parent or self.parent:IsVisible())end
function methods:GetID()return self.id end
function methods:GetName()return self.name end
function methods:SetOwner(owner,anchor)self.owner=owner end
function methods:AddDoubleLine(...)self.line={...}end
function CreateFrame(kind,name,parent,template)
 local o=newObject(kind,name,parent)
 if template then assert(template=='SmallMoneyFrameTemplate');for _,coin in ipairs({'Gold','Silver','Copper'})do newObject('Button',name..coin..'Button',o)end end
 return o
end
mockMethods=methods
function CreateBackdrop()end
function SkinButton()end
function MoneyFrame_Update(name,value)assert(value>=0 and value==value);_G[name].amount=value end
function getglobal(name)return _G[name]end
function HookScript(obj,k,fn)local old=obj.scripts[k];obj:SetScript(k,function(...)if old then old(...)end;fn(...)end)end
UIParent=newObject('Frame','UIParent');MerchantFrame=newObject('Frame','MerchantFrame',UIParent);MerchantFrame.selectedTab=1
ChatFrameEditBox=newObject('Frame','ChatFrameEditBox');ChatFrameEditBox.shown=false
GameTooltip=newObject('Tooltip','GameTooltip')
function MerchantItemButton_OnClick(button,ignore)table.insert(original,{button,ignore,this:GetID()})end
function StaticPopup_Hide(which)
 local p=popup
 if p and p.shown and p.which==which then p.shown=false;local info=StaticPopupDialogs[which];if info and info.OnHide then info.OnHide()end end
end
function StaticPopup_Show(which,a,b,...)
 assert(select('#',...)==0,'1.12 does not provide fourth data arg')
 StaticPopup_Hide(which);popup={which=which,shown=true,args={a,b}}
 return popup
end
function accept()
 assert(popup and popup.shown);local p=popup
 StaticPopupDialogs[p.which].OnAccept(p.data);StaticPopup_Hide(p.which)
end
function click(label)
 for _,o in ipairs(frames)do if o.parent==pfBuyEmAllFrame and o.kind=='Button'and o.text and o.text.text==label then invoke(o,'OnClick');return end end
 error('missing button '..label)
end
function openItem(i,button,ignore)
 local b=newObject('Button',nil,MerchantFrame);b.id=i;this=b
 MerchantItemButton_OnClick(button or 'RightButton',ignore);this=nil
end
function emit(ev)event=ev;invoke(pfBuyEmAllPump,'OnEvent');event=nil end
function step(dt)now=now+(dt or .1);if pfBuyEmAllPump:IsShown()then invoke(pfBuyEmAllPump,'OnUpdate',dt or .1)end end
function typeAmount(n)for c in string.gfind(tostring(n),'.')do invoke(pfBuyEmAllFrame,'OnChar',c)end end
catalog[101]={name='Same Name',subtype='Trade Goods',stack=20}
catalog[102]={name='Same Name',subtype='Trade Goods',stack=20}
offers={[1]={id=101,name='Same Name',price=10,preset=1,stock=-1},[21]={id=102,name='Same Name',price=20,preset=1,stock=-1}}
'''

def runtime(setup=''):
    lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(MOCK)
    contract=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf8'))
    contract(lua.globals().mockMethods,lua.globals().newObject)
    lua.execute("failedFontPaths['missing-font']=true")
    lua.execute(setup)
    lua.execute((ROOT/'Interface/AddOns/pfUI/modules/buyemall.lua').read_text(encoding='utf8'))
    return lua

class BulkBuy(unittest.TestCase):
    def test_modifiers_and_extended_merchant_ids_preserved(self):
        lua=runtime();lua.execute("ctrl=true;openItem(21);assert(#original==1);ctrl=false;shift=false;openItem(1);shift=true;ChatFrameEditBox:Show();openItem(1,'LeftButton');ChatFrameEditBox:Hide();MerchantFrame.selectedTab=2;openItem(1);MerchantFrame.selectedTab=1;openItem(1,'RightButton',1);assert(#original==5);openItem(21);click('Okay');step();assert(calls[1][1]==21 and calls[1][2]==1)")
    def test_confirmed_snapshot_cannot_buy_new_selection(self):
        lua=runtime();lua.execute("openItem(1);typeAmount(40);click('Okay');local old=popup.data;assert(type(old)=='table');openItem(21);StaticPopupDialogs.PFUI_BUYEMALL_CONFIRM.OnAccept(old);step();assert(#calls==0);assert(pfUI.buyemall:IsBusy())")
    def test_offer_changes_and_session_close_invalidate(self):
        for change in ["offers[1].id=102","offers[1].price=9","offers[1].preset=2","C.global.buyemall='0'","MerchantFrame.selectedTab=2","emit('MERCHANT_CLOSED');emit('MERCHANT_SHOW')"]:
            lua=runtime();lua.execute("openItem(1);typeAmount(40);click('Okay');local old=popup.data;"+change+";StaticPopupDialogs.PFUI_BUYEMALL_CONFIRM.OnAccept(old);step();assert(#calls==0)")
    def test_bundle_units_price_and_stock(self):
        lua=runtime("offers[1].preset=5;offers[1].price=50;offers[1].stock=8")
        lua.execute("openItem(1);typeAmount(40);click('Okay');assert(popup and popup.data.amount==40);accept();for i=1,12 do step()end;assert(#calls==8);for _,x in ipairs(calls)do assert(x[2]==1)end;assert(cash==9600 and offers[1].stock==0 and not pfUI.buyemall:IsBusy())")
    def test_partial_stack_workaround_and_ack_wait(self):
        lua=runtime("put(101,18);deferred=true")
        lua.execute("openItem(1);typeAmount(22);click('Okay');accept();step();step();assert(#calls==1 and calls[1][2]==1);deliver(1,1);step();assert(#calls==2 and calls[2][2]==1);deliver(1,1);step();assert(#calls==3 and calls[3][2]==20);deliver(1,20);step();assert(not pfUI.buyemall:IsBusy())")
    def test_unconfirmed_receipt_times_out_without_retry(self):
        lua=runtime("deferred=true");lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();step(3.1);step();local ready,why=pfUI.buyemall:CanStartRestock();assert(#calls==1 and not ready and why=='uncertain' and pfUI.buyemall:IsBusy());emit('MERCHANT_SHOW');assert(not pfUI.buyemall:CanStartRestock());emit('MERCHANT_CLOSED');assert(pfUI.buyemall:CanStartRestock() and not pfUI.buyemall:IsBusy())")
    def test_dynamic_budget_stock_capacity_rechecked(self):
        for change in ["cash=0","offers[1].stock=0","bagSlots[0]=1"]:
            lua=runtime();lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();"+change+";step();assert(#calls==1 and not pfUI.buyemall:IsBusy())")
    def test_unknown_bags_same_name_and_locked_partial_not_counted(self):
        lua=runtime("bagSlots[0]=1;put(102,1);bagSlots[1]=2;bagTypes[1]=999")
        lua.execute("assert(pfUI.buyemall:GetCapacity(link(101))==0);openItem(1);assert(not pfUI.buyemall:IsBusy());put(101,1);bags[0][1].locked=true;assert(pfUI.buyemall:GetCapacity(link(101))==0)")
    def test_font_failure_still_allows_display_and_cancel(self):
        lua=runtime();lua.execute("openItem(1);assert(pfBuyEmAllFrame.keyboard);click('Cancel');assert(not pfBuyEmAllFrame.keyboard and not pfUI.buyemall:IsBusy());assert(#calls==0)")
    def test_manual_priority_and_sale_wait(self):
        lua=runtime("selling=true");lua.execute("openItem(1);assert(Automaton.modules.Purchases.cancelled==1);click('Okay');step();assert(#calls==0 and pfUI.buyemall:IsBusy());selling=false;step();assert(#calls==1 and Automaton.modules.Purchases.cancelled>=2);step();assert(not pfUI.buyemall:IsBusy())")
    def test_immediate_merchant_hide_stops_queued_requests(self):
        lua=runtime();lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();MerchantFrame:Hide();MerchantFrame:Show();step();assert(#calls==1 and not pfUI.buyemall:IsBusy())")
    def test_free_items_cache_missing_and_old_layout(self):
        lua=runtime("offers[1].price=0;layout='old'");lua.execute("openItem(1);click('Okay');step();step();assert(#calls==1 and cash==10000 and not pfUI.buyemall:IsBusy())")
        lua=runtime("catalog[101]=nil");lua.execute("local capacity,stack=pfUI.buyemall:GetCapacity(link(101));assert(capacity==0 and stack==nil);openItem(1);assert(not pfUI.buyemall:IsBusy()and #calls==0)")
    def test_request_error_stops_and_reports(self):
        lua=runtime("failBuy=true");lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();step();local ready,why=pfUI.buyemall:CanStartRestock();assert(#calls==1 and #errors==1 and not ready and why=='pending');step(3.1);assert(not pfUI.buyemall:CanStartRestock());emit('MERCHANT_CLOSED');assert(pfUI.buyemall:CanStartRestock())")

    def test_restock_pending_and_uncertain_feedback(self):
        lua=runtime("Automaton.modules.Purchases.CanStartManualPurchase=function()return restockReady,restockReason end;restockReason='pending'")
        lua.execute("openItem(1);click('Okay');step();assert(#calls==0 and pfUI.buyemall:IsBusy());restockReason='uncertain';step();assert(#calls==0 and not pfUI.buyemall:IsBusy())")
        lua=runtime("Automaton.modules.Purchases.CanStartManualPurchase=function()return restockReady,'pending' end")
        lua.execute("openItem(1);click('Okay');step();restockReady=true;step();assert(#calls==1)")
    def test_purchase_protection_and_dynamic_native_limit(self):
        lua=runtime("pfUI.autovendor.ProtectPurchase=function(_,value)protected=value end;function GetMerchantItemMaxStack()return 5 end")
        lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();assert(calls[1][2]==5 and protected==link(101));for i=1,60 do step()end;local total=0;for _,call in ipairs(calls)do total=total+call[2]end;assert(total==40 and not pfUI.buyemall:IsBusy())")
    def test_manual_native_action_cancels_remaining_bulk_order(self):
        lua=runtime("deferred=true")
        lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();shift=false;openItem(21);assert(#original==1);step();assert(#calls==1 and not pfUI.buyemall:CanStartRestock());deliver(1,20);step();local ready,why=pfUI.buyemall:CanStartRestock();assert(not ready and why=='uncertain');emit('MERCHANT_CLOSED');assert(pfUI.buyemall:CanStartRestock())")
    def test_synchronous_merchant_close_cannot_revive_queue(self):
        lua=runtime("deferred=true;onBuy=function()MerchantFrame:Hide();MerchantFrame:Show()end")
        lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();step();local ready,why=pfUI.buyemall:CanStartRestock();assert(#calls==1 and not ready and why=='pending');deliver(1,20);step();assert(pfUI.buyemall:CanStartRestock() and not pfUI.buyemall:IsBusy())")
    def test_bundle_fit_is_rounded_down_and_bad_stack_is_rejected(self):
        lua=runtime("bagSlots[0]=1;put(101,18);offers[1].preset=5")
        lua.execute("openItem(1);assert(not pfUI.buyemall:IsBusy()and #calls==0)")
        lua=runtime("catalog[101].stack=0")
        lua.execute("openItem(1);assert(not pfUI.buyemall:IsBusy()and #calls==0)")

    def test_closed_pending_purchase_blocks_new_restock_until_receipt(self):
        lua=runtime("deferred=true")
        lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();MerchantFrame:Hide();emit('MERCHANT_CLOSED');MerchantFrame:Show();emit('MERCHANT_SHOW');local ready,why=pfUI.buyemall:CanStartRestock();assert(not ready and why=='pending' and pfUI.buyemall:IsBusy());step();assert(#calls==1);deliver(1,20);step();assert(pfUI.buyemall:CanStartRestock()and not pfUI.buyemall:IsBusy());assert(#calls==1)")
    def test_closed_before_timeout_does_not_clear_later_uncertainty(self):
        lua=runtime("deferred=true")
        lua.execute("openItem(1);click('Okay');step();MerchantFrame:Hide();emit('MERCHANT_CLOSED');step(3.1);MerchantFrame:Show();emit('MERCHANT_SHOW');local ready,why=pfUI.buyemall:CanStartRestock();assert(not ready and why=='uncertain');MerchantFrame:Hide();assert(pfUI.buyemall:CanStartRestock())")

    def test_cache_disappearing_during_queue_stops_without_error(self):
        lua=runtime()
        lua.execute("openItem(1);typeAmount(40);click('Okay');accept();step();catalog[101]=nil;step();assert(#calls==1 and #errors==0 and not pfUI.buyemall:IsBusy())")
    def test_merchant_services_wake_after_busy_release_only_once(self):
        lua=runtime("resumes=0;pfUI.autovendor.Resume=function()assert(not pfUI.buyemall:IsBusy());resumes=resumes+1;selling=true end")
        lua.execute("selling=true;openItem(1);click('Okay');step();assert(#calls==0 and resumes==0);selling=false;step();assert(#calls==1);step();assert(resumes==1 and selling and not pfUI.buyemall:IsBusy());step();assert(resumes==1)")
    def test_cancel_quantity_window_defers_service_resume(self):
        lua=runtime("resumes=0;pfUI.autovendor.Resume=function()assert(not pfUI.buyemall:IsBusy());resumes=resumes+1 end")
        lua.execute("openItem(1);pfUI.buyemall:CancelPurchases();step();assert(resumes==0);click('Cancel');assert(resumes==0);step();assert(resumes==1 and #calls==0)")

    def test_real_vendor_resume_and_busy_checks_have_no_deadlock(self):
        lua=runtime()
        source=(ROOT/'Interface/AddOns/pfUI/modules/autovendor.lua').read_text(encoding='utf8')
        start=source.index('  function module:IsSelling()')
        end=source.index('  -- Keep one session',start)
        lua.execute("C.global.autosell='1';C.global.autorepair='0';saleFrame=newObject('Frame');saleFrame:Hide();saleFrame.merchant=true;function pfUI.autovendor:CanExecute()return true end")
        lua.execute("local module=pfUI.autovendor;local autovendor=saleFrame;local processed={};local function MerchantOpen()return MerchantFrame:IsVisible()end;local function FindItem()if newGray then return 0,1,'gray','gray:1' end end;"+source[start:end])
        lua.execute("saleFrame:Show();openItem(1);click('Okay');step();assert(#calls==0);saleFrame:Hide();newGray=true;pfUI.autovendor:Resume();assert(not saleFrame:IsShown());step();assert(#calls==1);step();assert(saleFrame:IsShown()and saleFrame.runMode=='auto'and not pfUI.buyemall:IsBusy());step();assert(#calls==1)")

if __name__=='__main__':unittest.main(verbosity=2)
