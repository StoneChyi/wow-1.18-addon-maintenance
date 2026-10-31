"""English item/quest gestures with real AceHook and legacy dispatchers; offline only."""
from pathlib import Path
import sys
import unittest
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil;string.gmatch=nil;string.split=nil;select=nil;hooksecurefunc=nil;GetItemID=nil
alt=true;ctrl=false;shift=false;inserts={};native={};messages={};cursor=true
function IsAltKeyDown()return alt end
function IsControlKeyDown()return ctrl end
function IsShiftKeyDown()return shift end
function CursorHasItem()return cursor end
function ClearCursor()error('must not clear existing cursor item')end
ChatFrameEditBox={visible=true,IsVisible=function(self)return self.visible end,Insert=function(self,t)table.insert(inserts,t)end}
MerchantFrame={selectedTab=1}
function full(id)return '|cff00ff00|Hitem:'..id..':8:9:10|h[Local]|h|r'end
itemLink=full(101)
function GetInventoryItemLink(unit,id)lastSlot=id;return itemLink end
function GetContainerItemLink(bag,id)lastBag=bag;lastSlot=id;return itemLink end
function GetMerchantItemLink(id)assert(MerchantFrame.selectedTab==1);lastSlot=id;return itemLink end
function GetLootSlotLink(id)lastSlot=id;return itemLink end
function GetItemInfo(value)return 'Local','item:101:0:0:0',2 end
ITEM_QUALITY_COLORS={[2]={hex='|cff00ff00'}}
function LibStub(name,silent)if missingLib then return nil end;return {Item_enUS={[101]='English Sword',[102]='English Shield'}}end
this={GetID=function()return 21 end,GetParent=function()return{GetID=function()return 2 end}end,slot=4}
for _,name in ipairs({'PaperDollItemSlotButton_OnClick','ContainerFrameItemButton_OnClick','MerchantItemButton_OnClick','LootFrameItem_OnClick','SetItemRef','QuestLogTitleButton_OnClick'})do
 local key=name;_G[name]=function(a,b,c)table.insert(native,{key,a,b,c});return 'native',nil,17 end
end
Automaton={modules={},dbs={}}
function Automaton:NewModule(name)
 local m={name=name,events={}};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(ev,method)self.events[ev]=method or ev end
 function m:UnregisterAllEvents()self.events={}end
 function m:Print(text)table.insert(messages,text)end
 return m
end
function Automaton:AcquireDBNamespace(name)self.dbs[name]=self.dbs[name]or{profile={personal='keep'}};return self.dbs[name]end
function Automaton:RegisterDefaults(name,scope,values)for k,v in pairs(values)do if self.dbs[name][scope][k]==nil then self.dbs[name][scope][k]=v end end end
function Automaton:SetDisabledAsDefault()end
AceLibrary=setmetatable({}, {__call=function(_,name)return {new=function()return setmetatable({RegisterTranslations=function()end},{__index=function(_,key)return key end})end}end})
function AceLibrary:IsNewVersion()return true end
function AceLibrary:HasInstance(name)return name=='AceOO-2.0'end
function AceLibrary:GetInstance(name)return{Mixin=function()return{super={activate=function()end},error=function(self,fmt,...)error(string.format(fmt,...))end,argCheck=function(self,v,i,a,b,c)assert(type(v)==a or type(v)==b or type(v)==c)end}end}end
function AceLibrary:Register(lib,name,version,activate)RealHook=lib;activate(lib)end
QuestLogListScrollFrame={}
function FauxScrollFrame_GetOffset(frame)return 3 end
pfQuestCompat={GetQuestLogTitle=function(id)lastQuest=id;return '本地任务',12,nil,false end}
pfDatabase={GetQuestIDs=function(self,id)return{42}end}
pfDB={quests={data={[42]={lvl=12}},enUS={[42]={T='English Quest'}}}}
pfQuest_config={questlinks='1'}
function GetDifficultyColor(level)return{r=1,g=.5,b=0}end
function QuestLog_SetSelection(id)selectedQuest=id end
'''

ITEM = ROOT/'Interface/AddOns/Automatonex/Modules/S_ItemLinktoenUS.lua'
QUEST = ROOT/'Interface/AddOns/Automatonex/Modules/pfQuestSendLink.lua'
ACE = ROOT/'Interface/AddOns/!Libs/Ace2/AceHook-2.1/AceHook-2.1.lua'

def load_modules(lua):
    lua.execute(ACE.read_text(encoding='utf-8-sig'))
    lua.execute(ITEM.read_text(encoding='utf-8'))
    lua.execute(QUEST.read_text(encoding='utf-8'))
    lua.execute("""
for _,id in ipairs({'ItemLinkEnUS','pfQuestSendLink'})do
 local m=Automaton.modules[id]
 m.Hook=RealHook.Hook;m.Unhook=RealHook.Unhook;m.UnhookAll=RealHook.UnhookAll;m.IsHooked=RealHook.IsHooked
 RealHook:OnInstanceInit(m);m:OnInitialize()
end
I=Automaton.modules.ItemLinkEnUS;Q=Automaton.modules.pfQuestSendLink
""")

def runtime(setup=''):
    lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(MOCK);lua.execute(setup);load_modules(lua);return lua

class EnglishLinks(unittest.TestCase):
    def test_original_saved_namespaces_and_defaults(self):
        lua=runtime();lua.execute("assert(I.db.profile.personal=='keep' and Q.db.profile.personal=='keep');assert(I.db.profile.disabled and Q.db.profile.disabled);assert(I._options==I.options and Q._options==Q.options)")

    def test_all_five_item_sources_consume_without_native_side_effects(self):
        for call in ["PaperDollItemSlotButton_OnClick('LeftButton')","ContainerFrameItemButton_OnClick('LeftButton')","MerchantItemButton_OnClick('LeftButton')","LootFrameItem_OnClick('LeftButton')","SetItemRef('item:101:8:9:10',full(101),'LeftButton')"]:
            lua=runtime();lua.execute("I:OnEnable();"+call+";assert(#inserts==1 and #native==0 and cursor);assert(inserts[1]=='|cff00ff00|Hitem:101:8:9:10|h[English Sword]|h|r')")

    def test_extended_indices_and_parent_bag_are_not_rewritten(self):
        lua=runtime();lua.execute("I:OnEnable();MerchantItemButton_OnClick('LeftButton');assert(lastSlot==21);ContainerFrameItemButton_OnClick('LeftButton');assert(lastBag==2 and lastSlot==21);LootFrameItem_OnClick('LeftButton');assert(lastSlot==4)")

    def test_modifiers_hidden_input_ignore_and_buyback_fall_through(self):
        for setup,call in [("ctrl=true","MerchantItemButton_OnClick('LeftButton')"),("shift=true","MerchantItemButton_OnClick('LeftButton')"),("alt=false","MerchantItemButton_OnClick('LeftButton')"),("ChatFrameEditBox.visible=false","LootFrameItem_OnClick('LeftButton')"),("MerchantFrame.selectedTab=2","MerchantItemButton_OnClick('LeftButton')"),("","MerchantItemButton_OnClick('LeftButton',1)"),("","PaperDollItemSlotButton_OnClick('LeftButton',1)"),("","LootFrameItem_OnClick('RightButton')")]:
            lua=runtime(setup);lua.execute("I:OnEnable();local a,b,c="+call+";assert(#inserts==0 and #native==1 and a=='native' and b==nil and c==17)")

    def test_missing_library_cache_and_empty_slot_are_safe(self):
        for setup in ["LibStub=nil","LibStub=function()error('missing library')end","missingLib=true","itemLink=nil","itemLink=full(999)"]:
            lua=runtime(setup);lua.execute("I:OnEnable();MerchantItemButton_OnClick('LeftButton');assert(#inserts==0 and #native==1)")
        lua=runtime("GetItemInfo=nil");lua.execute("I:OnEnable();SetItemRef('item:101:8:9:10',nil,'LeftButton');assert(#inserts==1 and string.find(inserts[1],'item:101:8:9:10',1,true))")

    def test_library_late_availability_needs_no_new_hook(self):
        lua=runtime('missingLib=true');lua.execute("I:OnEnable();local original=SetItemRef;SetItemRef('item:101:0:0:0',nil,'LeftButton');missingLib=false;I:InstallHooks();assert(SetItemRef==original);SetItemRef('item:101:0:0:0',nil,'LeftButton');assert(#inserts==1 and #native==1)")

    def test_item_repeated_enable_disable_preserves_later_wrapper(self):
        lua=runtime();lua.execute("""
I:OnEnable();local base=SetItemRef;local outerCount=0
SetItemRef=function(a,b,c)outerCount=outerCount+1;return base(a,b,c)end
local outer=SetItemRef;I:OnEnable();I:OnEnable();assert(SetItemRef==outer)
SetItemRef('item:101:0:0:0',nil,'LeftButton');assert(#inserts==1)
I:OnDisable();SetItemRef('item:101:0:0:0',nil,'LeftButton');assert(#inserts==1 and #native==1)
I:OnEnable();assert(SetItemRef==outer);SetItemRef('item:101:0:0:0',nil,'LeftButton');assert(#inserts==2 and outerCount==3)
""")

    def test_non_item_links_and_missing_frame_return_native_values(self):
        lua=runtime();lua.execute("I:OnEnable();for _,value in ipairs({'player:Bob','url:https://example.invalid','quest:42:12'})do local a,b,c=SetItemRef(value,'text','LeftButton');assert(a=='native'and b==nil and c==17)end;this=nil;LootFrameItem_OnClick('LeftButton');assert(#inserts==0 and #native==4)")

    def test_quest_success_uses_english_without_pfui(self):
        lua=runtime('alt=false;ctrl=true;pfUI=nil');lua.execute("Q:OnEnable();QuestLogTitleButton_OnClick('LeftButton');assert(#native==0 and #inserts==1 and selectedQuest==24);assert(inserts[1]=='|cffff7f00|Hquest:42:12|h[English Quest]|h|r')")

    def test_quest_plain_and_missing_translation_preserve_original_fallback(self):
        lua=runtime("alt=false;ctrl=true;pfQuest_config.questlinks='0'");lua.execute("Q:OnEnable();QuestLogTitleButton_OnClick('LeftButton');assert(inserts[1]=='[English Quest]');pfDB.quests.enUS=nil;QuestLogTitleButton_OnClick('LeftButton');assert(inserts[2]=='[本地任务]');pfDB=nil;pfDatabase.GetQuestIDs=function()return nil end;QuestLogTitleButton_OnClick('LeftButton');assert(inserts[3]=='[本地任务]')")

    def test_quest_dependencies_not_read_for_ordinary_clicks(self):
        lua=runtime("pfQuestCompat.GetQuestLogTitle=function()error('must not query')end");lua.execute("Q:OnEnable();local a,b,c=QuestLogTitleButton_OnClick('LeftButton');assert(a=='native'and b==nil and c==17 and #inserts==0)")

    def test_quest_missing_dependencies_and_late_load(self):
        lua=runtime('alt=false;ctrl=true;savedCompat=pfQuestCompat;pfQuestCompat=nil');lua.execute("Q:OnEnable();Q:OnEnable();assert(not Q:IsHooked('QuestLogTitleButton_OnClick'));QuestLogTitleButton_OnClick('LeftButton');assert(#native==1 and #messages==1);pfQuestCompat=savedCompat;Q:InstallHook();QuestLogTitleButton_OnClick('LeftButton');assert(#inserts==1);Q:OnDisable();QuestLogTitleButton_OnClick('LeftButton');assert(#native==2)")

    def test_quest_header_modifiers_and_hidden_editbox_preserve_original(self):
        for setup in ['this.isHeader=true','shift=true','alt=true','ChatFrameEditBox.visible=false','pfQuestCompat.GetQuestLogTitle=function()return "header",0,nil,true end']:
            lua=runtime('alt=false;ctrl=true;'+setup);lua.execute("Q:OnEnable();QuestLogTitleButton_OnClick('LeftButton');assert(#native==1 and #inserts==0)")

    def test_quest_repeated_enable_does_not_duplicate_or_clobber_wrapper(self):
        lua=runtime('alt=false;ctrl=true');lua.execute("Q:OnEnable();local base=QuestLogTitleButton_OnClick;count=0;QuestLogTitleButton_OnClick=function(b)count=count+1;return base(b)end;local outer=QuestLogTitleButton_OnClick;Q:OnEnable();Q:OnDisable();Q:OnEnable();assert(QuestLogTitleButton_OnClick==outer);QuestLogTitleButton_OnClick('LeftButton');assert(count==1 and #inserts==1)")

    def test_actual_pfui_itemref_dispatcher_both_load_orders(self):
        source=(ROOT/'Interface/AddOns/pfUI/modules/chat.lua').read_text(encoding='utf-8')
        block=source[source.index('  function _G.SetItemRef(link, text, button)'):source.index('  pfUI.chat.right =',source.index('  function _G.SetItemRef(link, text, button)'))]
        setup="""pfUI={chat={urlcopy={SetItemRef=SetItemRef,CopyText=function(text)copied=text end}},chatPlayerLinks={Handle=function(self,link)if string.sub(link,1,7)=='player:'then playerClicked=true;return true end end}};strsub=string.sub"""
        for item_outer in [True,False]:
            lua=runtime()
            if not item_outer:lua.execute('I:OnEnable()')
            lua.execute(setup);lua.execute(block)
            if item_outer:lua.execute('I:OnEnable()')
            lua.execute("SetItemRef('item:101:8:9:10',full(101),'LeftButton');assert(#inserts==1 and #native==0);SetItemRef('player:Bob','Bob','LeftButton');assert(playerClicked);SetItemRef('url:https://example.invalid',nil,'LeftButton');assert(copied=='https://example.invalid');I:OnDisable();SetItemRef('item:101:0:0:0',nil,'LeftButton');assert(#native==1)")

    def test_actual_pfui_loot_callback_consumes_only_successful_english_gesture(self):
        source=(ROOT/'Interface/AddOns/pfUI/modules/loot.lua').read_text(encoding='utf-8')
        start=source.index('    frame:SetScript("OnClick", function()',source.index("local frame = CreateFrame(LOOT_BUTTON_FRAME_TYPE"))
        block=source[start:source.index('    frame:SetScript("OnEnter"',start)]
        setup=r'''
pfUI={loot={}};LootFrame={};lootCalls={};dressed={};hidden={};queued={}
frame={SetScript=function(self,kind,fn)self[kind]=fn end}
function StaticPopup_Hide(which)table.insert(hidden,which)end
function GetNumLootItems()return 1 end
function LootSlot(id)table.insert(lootCalls,id)end
function DressUpItemLink(link)table.insert(dressed,link)end
function QueueFunction(fn)table.insert(queued,fn)end
function CloseOnClick()end
this.GetName=function()return 'pfLootButton21'end;this.quality=2;this.name={GetText=function()return 'Local'end}
'''
        lua=runtime();lua.execute(setup);lua.execute(block)
        lua.execute("I:OnEnable();arg1='LeftButton';frame.OnClick();assert(#inserts==1 and #lootCalls==0 and #hidden==0);I:OnDisable();frame.OnClick();assert(#lootCalls==1 and lootCalls[1]==21 and #queued==1);I:OnEnable();missingLib=true;frame.OnClick();assert(#lootCalls==2);missingLib=false;ctrl=true;frame.OnClick();assert(#dressed==1 and #lootCalls==3);ctrl=false;shift=true;frame.OnClick();assert(#inserts==2 and #lootCalls==4)")

    def test_actual_pfui_bulk_both_hook_orders_and_extended_ids(self):
        from test_pfui_buyemall import MOCK as BULK_MOCK
        for item_outer in [True,False]:
            lua=LuaRuntime(unpack_returned_tuples=True);lua.execute(BULK_MOCK)
            contract=lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'));contract(lua.globals().mockMethods,lua.globals().newObject)
            lua.execute("failedFontPaths['missing-font']=true;bulkFrame=MerchantFrame;bulkEdit=ChatFrameEditBox;bulkMerchant=MerchantItemButton_OnClick;bulkGetItem=GetItemInfo;bulkGetMerchant=GetMerchantItemLink;bulkAutomaton=Automaton;bulkSelect=select;bulkGetContainer=GetContainerItemLink;bulkGetInventory=GetInventoryItemLink")
            lua.execute(MOCK)
            lua.execute("select=bulkSelect;GetContainerItemLink=bulkGetContainer;GetInventoryItemLink=bulkGetInventory;MerchantFrame=bulkFrame;ChatFrameEditBox=bulkEdit;MerchantItemButton_OnClick=bulkMerchant;GetItemInfo=bulkGetItem;GetMerchantItemLink=bulkGetMerchant;Automaton.modules.Purchases=bulkAutomaton.modules.Purchases;function ChatFrameEditBox:Insert(text)table.insert(inserts,text)end;ChatFrameEditBox:Show();alt=true;shift=false;ctrl=false;this=nil")
            load_modules(lua)
            if not item_outer:lua.execute('I:OnEnable()')
            lua.execute((ROOT/'Interface/AddOns/pfUI/modules/buyemall.lua').read_text(encoding='utf-8'))
            if item_outer:lua.execute('I:OnEnable()')
            lua.execute("openItem(21,'LeftButton');assert(#inserts==1 and #original==0 and #calls==0);alt=false;ctrl=true;openItem(21,'LeftButton');assert(#original==1);ctrl=false;ChatFrameEditBox:Hide();shift=true;openItem(21,'LeftButton');assert(pfBuyEmAllFrame:IsShown());I:OnDisable()")

if __name__=='__main__':unittest.main(verbosity=2)
