"""Real CleanChat/AceHook regressions; simulated events only, no live messages."""
from pathlib import Path
import sys
import unittest
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil;string.gmatch=nil;select=nil
now=100;NUM_CHAT_WINDOWS=2;messages={};sounds={};sent={};emotes={};links={};invites={};observers={}
NORMAL_FONT_COLOR_CODE='';LIGHTYELLOW_FONT_COLOR_CODE='';ChatFontNormal={font={'Fonts\\FRIZQT__.TTF',12}}
StaticPopupDialogs={};ChatTypeInfo={};CHAT_FONT_HEIGHTS={12,14};CHAT_RAID_GET='original raid'
for _,name in ipairs({'SAY','EMOTE','YELL','PARTY','GUILD','OFFICER','RAID','RAID_WARNING','BATTLEGROUND','WHISPER','CHANNEL'})do ChatTypeInfo[name]={sticky=0}end
function GetTime()return now end
function UnitName()return 'Tester'end
function GetLocale()return 'zhCN'end
function GetNumRaidMembers()return 0 end
function GetNumPartyMembers()return 1 end
function IsShiftKeyDown()return shift end
function IsCn()return true end
function Localization_SpellNametocn()return nil end
function getglobal(name)return _G[name]end
format=string.format;strfind=string.find;gsub=string.gsub;tinsert=table.insert;strsub=string.sub
function date()return '12:34'end
function PlaySound(name)sounds[#sounds+1]=name end
function PlaySoundFile(name)sounds[#sounds+1]=name end
function SendChatMessage(text,channel)sent[#sent+1]={text,channel}end
function DoEmote(name)emotes[#emotes+1]=name end
function InviteByName(name)invites[#invites+1]=name end
function SetItemRef(link,text,button)links[#links+1]={link,text,button};return 'link',nil,9 end
ERR_AUCTION_SOLD_S='Your auction of %s sold.';ERR_AUCTION_EXPIRED_S='Your auction of %s expired.';ERR_AUCTION_WON_S='You won %s.'
methods={}
function newObject(kind,name,parent)
 local o=setmetatable({kind=kind,name=name,parent=parent,shown=true,scripts={},events={},lines={}},{__index=methods})
 if name then _G[name]=o end;return o
end
function methods:GetText()return self.text end
function methods:GetName()return self.name end
function methods:Show()self.shown=true end
function methods:Hide()self.shown=false end
function methods:IsShown()return self.shown end
function methods:IsVisible()return self.shown end
function methods:SetScript(name,fn)self.scripts[name]=fn end
function methods:GetScript(name)return self.scripts[name]end
function methods:RegisterEvent(name)assert(name~='CHAT_MSG_PARTY_LEADER','unknown vanilla event');self.events[name]=true end
function methods:UnregisterAllEvents()self.events={}end
function methods:EnableMouseWheel(v)self.wheel=v end
function methods:ScrollToTop()self.scroll='top'end
function methods:ScrollToBottom()self.scroll='bottom'end
function methods:ScrollUp()self.scroll='up'end
function methods:ScrollDown()self.scroll='down'end
function methods:AddMessage(text,r,g,b,id,extra)
 if nativeError then error('native failure')end
 messages[#messages+1]={frame=self.name,text=text,r=r,g=g,b=b,id=id,extra=extra}
 return 'message',nil,8
end
function CreateFrame(kind,name,parent,template)
 assert(kind=='Frame' and not template,'only the event observer is created here')
 local f=newObject(kind,name,parent);observers[#observers+1]=f;return f
end
ChatTypeGroup={SYSTEM={'CHAT_MSG_SYSTEM'},LOOT={'CHAT_MSG_LOOT'},HARDCORE={'CHAT_MSG_HARDCORE'},SAY={'CHAT_MSG_SAY'},WHISPER={'CHAT_MSG_WHISPER'}}
for i=1,NUM_CHAT_WINDOWS do
 local f=newObject('Frame','ChatFrame'..i)
 f.events={CHAT_MSG_SYSTEM=true,CHAT_MSG_LOOT=true,CHAT_MSG_HARDCORE=true,CHAT_MSG_CHANNEL=true,CHAT_MSG_SAY=true,CHAT_MSG_WHISPER=true}
 f.messageTypeList={'SYSTEM','LOOT','HARDCORE','SAY','WHISPER'};f.channelList={'World'};f.zoneChannelList={}
 f:SetScript('OnMouseWheel',function()f.oldWheel=true end)
 newObject('Frame','ChatFrame'..i..'UpButton');newObject('Frame','ChatFrame'..i..'DownButton')
end
DEFAULT_CHAT_FRAME=ChatFrame1
UIErrorsFrame=newObject('Frame','UIErrorsFrame')
function ChatFrame_OnEvent(kind)
 if nested then local fn=nested;nested=nil;fn()end
 this:AddMessage(arg1,1,.5,.2,4,5)
 return 'event',nil,7
end
Automaton={modules={},dbs={}}
function Automaton:NewModule(name)local m={events={},hooks={}};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(name,handler)self.events[name]=handler or name end
 function m:UnregisterAllEvents()self.events={}end
 return m
end
function Automaton:AcquireDBNamespace(name)self.dbs[name]=self.dbs[name]or{profile={}};return self.dbs[name]end
local function defaults(t,d)for k,v in pairs(d)do if t[k]==nil then t[k]=v elseif type(v)=='table'and type(t[k])=='table'then defaults(t[k],v)end end end
function Automaton:RegisterDefaults(name,scope,d)defaults(self.dbs[name][scope],d)end
function Automaton:SetDisabledAsDefault()end
function Dispatch(kind,msg,speaker,channel)
 event,arg1,arg2,arg9=kind,msg,speaker or '',channel
 for i=1,NUM_CHAT_WINDOWS do local f=_G['ChatFrame'..i];if f.events[kind]then
  this=f;assert(arg1==msg);ChatFrame_OnEvent(kind);assert(arg1==msg,'render leaked modified arg1')
 end end
 for _,f in ipairs(observers)do if f.events[kind]then this=f;f:GetScript('OnEvent')();assert(arg1==msg,'observer leaked arg1')end end
end
'''

def runtime(setup=""):
    lua=LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))(lua.globals().methods,lua.globals().newObject)
    lua.execute("EasyCopy=newObject('Frame','EasyCopy');EasyCopy:Hide();EasyCopyText=newObject('FontString','EasyCopyText');EasyCopyText:SetFontObject(ChatFontNormal)")
    lua.execute(setup)
    lua.execute((ROOT/'Interface/AddOns/Automatonex/Plubics/CleanChat/Localization.lua').read_text(encoding='utf-8-sig'))
    lua.execute((ROOT/'Interface/AddOns/Automatonex/Plubics/CleanChat/CleanChat.lua').read_text(encoding='utf-8-sig'))
    lua.execute(r'''
AceLibrary={}
function AceLibrary:IsNewVersion()return true end
function AceLibrary:HasInstance(name)return name=='AceOO-2.0'end
function AceLibrary:GetInstance(name)
 assert(name=='AceOO-2.0')
 return {Mixin=function()return {super={activate=function()end},error=function(self,fmt,...)error(string.format(fmt,...))end,
 argCheck=function(self,value,index,a,b,c)assert(type(value)==a or type(value)==b or type(value)==c,'AceHook type contract')end}end}
end
function AceLibrary:Register(lib,name,version,activate)RealHook=lib;activate(lib)end
''')
    lua.execute((ROOT/'Interface/AddOns/!Libs/Ace2/AceHook-2.1/AceHook-2.1.lua').read_text(encoding='utf-8-sig'))
    lua.execute("M=Automaton.modules.CleanChat;M.Hook=RealHook.Hook;M.Unhook=RealHook.Unhook;M.UnhookAll=RealHook.UnhookAll;RealHook:OnInstanceInit(M);M:OnInitialize()")
    return lua

def native_pipeline(order):
    lua=runtime()
    lua.execute(r'''
C={chat={global={whispermod='0'},text={time='1',timeformat='%H:%M',detecturl='0',classcolor='0',playerlevel='0',playerrace='0',channelnumonly='0'}}}
pfUI={chat={}};history={}
function methods:GetID()return tonumber(string.sub(self.name or '',10))or 1 end
function SaveChatHistory(id,text,r,g,b)history[#history+1]={id,text,r,g,b}end
''')
    source=(ROOT/'Interface/AddOns/pfUI/modules/chat.lua').read_text(encoding='utf-8-sig')
    start=source.index('  local function UseNativeTimestamp(frame)')
    end=source.index('  for i=1,NUM_CHAT_WINDOWS do',start)
    lua.execute("local who_query={};local channelMap={};local timecolorhex='[PF]';local tleft='[';local tright=']'\n"+source[start:end]+"\nNativeMessage=AddMessage")
    if order=='clean-first':
        lua.execute("M:OnEnable();ChatFrame1.HookAddMessage=ChatFrame1.AddMessage;ChatFrame1.AddMessage=NativeMessage")
    else:
        lua.execute("ChatFrame1.HookAddMessage=ChatFrame1.AddMessage;ChatFrame1.AddMessage=NativeMessage;M:OnEnable()")
    return lua


class CleanChat(unittest.TestCase):
    def test_initialization_preserves_disabled_visuals_and_saved_lists(self):
        lua=runtime("Automaton.dbs.CleanChat={profile={TFilterKeyworld={'keep'},THighlightText={'mine'},lootCelebrationItems={'rare'},ShowChatTime=true}};originalWheel=ChatFrame1:GetScript('OnMouseWheel');originalFonts=CHAT_FONT_HEIGHTS")
        lua.execute("assert(not M.runtimeActive and #observers==0);assert(CHAT_RAID_GET=='original raid' and CHAT_FONT_HEIGHTS==originalFonts);assert(ChatFrame1:GetScript('OnMouseWheel')==originalWheel and ChatFrame1UpButton:IsShown());assert(M.db.profile.TFilterKeyworld[1]=='keep' and M.db.profile.THighlightText[1]=='mine' and M.db.profile.lootCelebrationItems[1]=='rare')")

    def test_repeated_enable_disable_hooks_once_and_restores_visuals(self):
        lua=runtime()
        lua.execute(r'''
local base=ChatFrame_OnEvent;local add=ChatFrame1.AddMessage;local link=SetItemRef;local wheel=ChatFrame1:GetScript('OnMouseWheel');local fonts=CHAT_FONT_HEIGHTS
M:OnEnable();local wrapped=ChatFrame_OnEvent;M:OnEnable();assert(ChatFrame_OnEvent==wrapped and #observers==1)
M.db.profile.ShowChatTime=true;Dispatch('CHAT_MSG_SAY','hello','Other');assert(#messages==2 and string.find(messages[1].text,'12:34'))
M:OnDisable();assert(ChatFrame_OnEvent==base and ChatFrame1.AddMessage==add and SetItemRef==link)
assert(ChatFrame1:GetScript('OnMouseWheel')==wheel and CHAT_FONT_HEIGHTS==fonts and CHAT_RAID_GET=='original raid' and ChatFrame1UpButton:IsShown())
messages={};Dispatch('CHAT_MSG_SAY','hello','Other');assert(#messages==2 and messages[1].text=='hello')
M:OnEnable();assert(#observers==1);messages={};Dispatch('CHAT_MSG_SAY','again','Other');assert(#messages==2)
''')

    def test_third_party_later_wrappers_survive_disable_reenable(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();local base=ChatFrame_OnEvent;local add=ChatFrame1.AddMessage;local link=SetItemRef;outer=0
ChatFrame_OnEvent=function(kind)outer=outer+1;return base(kind)end
ChatFrame1.AddMessage=function(f,...)return add(f,unpack(arg))end
SetItemRef=function(...)return link(unpack(arg))end
local outerHook=ChatFrame_OnEvent;local outerAdd=ChatFrame1.AddMessage
M:OnDisable();Dispatch('CHAT_MSG_SAY','disabled','Other');assert(outer==2 and #messages==2)
M:OnEnable();assert(ChatFrame_OnEvent==outerHook and ChatFrame1.AddMessage==outerAdd)
Dispatch('CHAT_MSG_SAY','enabled','Other');assert(outer==4 and #messages==4)
''')

    def test_global_context_and_return_values_restored_on_success_and_failure(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();M.db.profile.THighlightText={'hello'};this=ChatFrame1;arg1='hello';arg2='Other';arg9='World';ChatFrame1.event='prior'
local a,b,c=ChatFrame_OnEvent('CHAT_MSG_SAY');assert(a=='event'and b==nil and c==7 and arg1=='hello'and this==ChatFrame1 and ChatFrame1.event=='prior')
nativeError=true;local ok=pcall(ChatFrame_OnEvent,'CHAT_MSG_SAY');assert(not ok and arg1=='hello'and this==ChatFrame1 and ChatFrame1.event=='prior' and M.renderPass==nil)
''')

    def test_nested_event_does_not_contaminate_outer_context(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();this=ChatFrame1;arg1='outer';arg2='Outer';arg9='World'
nested=function()local a,b,c,d=this,arg1,arg2,arg9;this=ChatFrame2;arg1='inner';arg2='Inner';arg9='Guild';ChatFrame_OnEvent('CHAT_MSG_GUILD');this,arg1,arg2,arg9=a,b,c,d end
ChatFrame_OnEvent('CHAT_MSG_SAY');assert(messages[1].text=='inner' and messages[2].text=='outer'and arg1=='outer'and M.renderPass==nil)
''')

    def test_filter_patterns_self_exemption_and_invalid_patterns(self):
        lua=runtime()
        lua.execute("M:OnEnable();M.db.profile.TFilterKeyworld={'[','spam%d+'};Dispatch('CHAT_MSG_SAY','spam123','Other');assert(#messages==0);Dispatch('CHAT_MSG_SAY','spam123','Tester');assert(#messages==2);M.db.profile.hasunitname=true;M.db.profile.TFilterKeyworld={'Blocked'};Dispatch('CHAT_MSG_SAY','hello','Blocked');assert(#messages==2)")

    def test_highlight_all_keywords_and_protect_link_payloads(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();M.db.profile.THighlightText={'later','earlier','[','a*','123'}
local text=M:HighlightText('earlier later |Hitem:123:0:0:0|h[123]|h|r')
assert(string.find(text,'|Hitem:123:0:0:0|h',1,true));assert(string.find(text,'|cff33ffcc'..'earlier'..'|r',1,true));assert(string.find(text,'|cff33ffcc'..'later'..'|r',1,true))
''')

    def test_native_observer_notifies_once_per_event_not_once_per_text(self):
        lua=runtime()
        lua.execute("M:OnEnable();Dispatch('CHAT_MSG_SYSTEM','副本已被重置','');assert(#sent==1 and #messages==2);Dispatch('CHAT_MSG_SYSTEM','副本已被重置','');assert(#sent==2 and #messages==4);M:OnDisable();Dispatch('CHAT_MSG_SYSTEM','副本已被重置','');assert(#sent==2)")

    def test_notices_require_subscription_and_repeat_policy(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();ChatFrame1.events.CHAT_MSG_SYSTEM=nil;ChatFrame2.events.CHAT_MSG_SYSTEM=nil;ChatFrame1.messageTypeList={};ChatFrame2.messageTypeList={}
Dispatch('CHAT_MSG_SYSTEM','副本已被重置','');assert(#sent==0)
ChatFrame1.events.CHAT_MSG_SYSTEM=true;ChatFrame1.messageTypeList={'SYSTEM'}
pfUI={chatRepeatFilter={ShouldNotify=function(self,kind,msg,sender,channel)assert(kind=='CHAT_MSG_SYSTEM'and msg=='副本已被重置');return false end}}
Dispatch('CHAT_MSG_SYSTEM','副本已被重置','');assert(#sent==0)
''')

    def test_loot_celebration_once_and_exact_saved_item_names(self):
        lua=runtime()
        lua.execute("M:OnEnable();M.db.profile.lootCelebrationItems={'恶魔布'};Dispatch('CHAT_MSG_LOOT','你获得了物品：[恶魔布披风]','');assert(#emotes==0);Dispatch('CHAT_MSG_LOOT','你获得了物品：[恶魔布]','');assert(#emotes==1);Dispatch('CHAT_MSG_LOOT','你获得了物品：[恶魔布]','');assert(#emotes==2)")

    def test_hardcore_output_once_but_legitimate_repetition_kept(self):
        lua=runtime()
        lua.execute("M:OnEnable();M.db.profile.HCFFrame=2;Dispatch('CHAT_MSG_HARDCORE','hello','Other');assert(#messages==1 and messages[1].frame=='ChatFrame2');Dispatch('CHAT_MSG_HARDCORE','hello','Other');assert(#messages==2);M.db.profile.onoff=true;Dispatch('CHAT_MSG_HARDCORE','hidden','Other');assert(#messages==2)")

    def test_popup_and_whisper_sound_once_across_frames(self):
        lua=runtime()
        lua.execute("M:OnEnable();M.db.profile.whispersound=true;M.db.profile.THighlightText={'look'};Dispatch('CHAT_MSG_WHISPER','look here','Other');assert(#sounds==2);local count=0;for _,m in ipairs(messages)do if m.frame=='UIErrorsFrame'then count=count+1 end end;assert(count==1)")

    def test_managed_visuals_yield_and_original_options_remain(self):
        lua=runtime()
        lua.execute(r'''
local wheel=ChatFrame1:GetScript('OnMouseWheel');local fonts=CHAT_FONT_HEIGHTS
local owner={};M:SetChatOwner(owner);M:OnEnable();M.db.profile.ShowChatTime=true
Dispatch('CHAT_MSG_SAY','plain','Other');assert(messages[1].text=='plain'and CHAT_FONT_HEIGHTS==fonts and ChatFrame1:GetScript('OnMouseWheel')==wheel)
assert(M.db.profile.ShowChatTime and M.db.profile.CopyChatTime)
M:SetChatOwner(nil);messages={};Dispatch('CHAT_MSG_SAY','timed','Other');assert(string.find(messages[1].text,'12:34'))
''')

    def test_owned_links_exact_prefix_disable_and_native_returns(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();SetItemRef('inv:Friend','','LeftButton');assert(invites[1]=='Friend')
SetItemRef('ezc:one/1two/2r','','LeftButton');assert(EasyCopy:IsShown()and EasyCopyText:GetText()=='one/two|r')
local a,b,c=SetItemRef('inventory:1','','LeftButton');assert(a=='link'and b==nil and c==9 and #links==1)
M:SetChatOwner({});SetItemRef('inv:Managed','','LeftButton');assert(#invites==1 and #links==2);assert(M:HandleLink('inv:Managed','','LeftButton')and #invites==2)
M:OnDisable();SetItemRef('inv:Disabled','','LeftButton');assert(#invites==2 and not M:HandleLink('inv:No','','LeftButton'))
''')

    def test_auction_roll_and_unrecognized_system_messages_keep_content(self):
        lua=runtime()
        lua.execute("M:OnEnable();Dispatch('CHAT_MSG_SYSTEM','Your auction of Sword sold.','');assert(messages[1].text=='Your auction of Sword sold.' and #sounds==1);Dispatch('CHAT_MSG_SYSTEM','Tester掷出42（1-100）','');assert(string.find(messages[3].text,'42'));Dispatch('CHAT_MSG_SYSTEM','unchanged system','');assert(messages[5].text=='unchanged system')")

    def test_combat_log_and_nonstring_messages_bypass_decorations(self):
        lua=runtime()
        lua.execute("M:OnEnable();M.db.profile.ShowChatTime=true;this=ChatFrame1;arg1='damage';arg2='Other';ChatFrame_OnEvent('CHAT_MSG_SPELL_SELF_DAMAGE');assert(messages[1].text=='damage');local a,b,c=ChatFrame1:AddMessage(nil,1,2,3,4,5);assert(a=='message'and b==nil and c==8 and messages[2].extra==5)")

    def test_repeat_service_wraps_original_raw_event(self):
        lua=runtime()
        lua.execute("local calls=0;pfUI={chatRepeatFilter={Run=function(self,frame,kind,handler)calls=calls+1;assert(arg1=='raw');return handler(kind)end}};M:OnEnable();Dispatch('CHAT_MSG_SAY','raw','Other');assert(calls==2 and #messages==2)")

    def test_non_chat_events_keep_native_initialization(self):
        lua=runtime()
        lua.execute("M:OnEnable();this=ChatFrame1;arg1=nil;arg2=nil;local a,b,c=ChatFrame_OnEvent('UPDATE_CHAT_WINDOWS');assert(a=='event'and b==nil and c==7 and #messages==1)")

    def test_channel_notices_require_selected_channel_not_only_event(self):
        lua=runtime()
        lua.execute("M:OnEnable();M.db.profile.THighlightText={'look'};ChatFrame1.channelList={};ChatFrame2.channelList={'Guild'};Dispatch('CHAT_MSG_CHANNEL','look here','Other','World');assert(#sounds==0);ChatFrame2.channelList={'World'};Dispatch('CHAT_MSG_CHANNEL','look again','Other','World');assert(#sounds==1)")

    def test_later_mousewheel_wrapper_survives_repeated_lifecycle(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();local base=ChatFrame1:GetScript('OnMouseWheel');local count=0
local outer=function()count=count+1;return base()end
ChatFrame1:SetScript('OnMouseWheel',outer);this=ChatFrame1;arg1=1
M:OnDisable();outer();assert(count==1 and ChatFrame1.oldWheel and not ChatFrame1.scroll)
M:OnEnable();assert(ChatFrame1:GetScript('OnMouseWheel')==outer);outer();assert(count==2 and ChatFrame1.scroll=='up')
M:SetChatOwner({});ChatFrame1.scroll=nil;outer();assert(count==3 and not ChatFrame1.scroll)
''')

    def test_all_original_localized_invite_words_include_zero_index(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();for i=0,4 do messages={};Dispatch('CHAT_MSG_SAY','请 '..CleanChat_CUSTOM_INV[i]..' ','Other');assert(string.find(messages[1].text,'|Hinv:Other|h',1,true),'missing original invite word '..i)end
CleanChat_CUSTOM_INV[5]='[';messages={};Dispatch('CHAT_MSG_SAY','normal text','Other');assert(messages[1].text=='normal text')
''')

    def test_display_predicate_is_pure_and_runtime_gated(self):
        lua=runtime()
        lua.execute("assert(not M:ShouldFilterDisplay('Delete your WDB'));M:OnEnable();this=ChatFrame1;arg1='keep';ChatFrame1.CleanChat_UnitName='kept';assert(M:ShouldFilterDisplay('Delete your WDB'));assert(arg1=='keep'and ChatFrame1.CleanChat_UnitName=='kept');M:OnDisable();assert(not M:ShouldFilterDisplay('Delete your WDB'))")

    def test_native_combat_log_marker_bypasses_filter_and_timestamp(self):
        lua=runtime()
        lua.execute("M:OnEnable();M.db.profile.ShowChatTime=true;ChatFrame1.pfCombatLog=true;assert(not M:ShouldFilterDisplay('Delete your WDB',ChatFrame1));ChatFrame1:AddMessage('Delete your WDB');assert(messages[1].text=='Delete your WDB')")

    def test_real_pfui_addmessage_and_cleanchat_two_load_orders(self):
        for order in ('clean-first','pfui-first'):
            with self.subTest(order=order):
                lua=native_pipeline(order)
                lua.execute(r'''
M.db.profile.ShowChatTime=true;this=ChatFrame1;arg2='Other'
ChatFrame1:AddMessage('Delete your WDB');assert(#messages==0 and #history==0)
ChatFrame1:AddMessage('normal');assert(#messages==1 and #history==1)
local _,count=string.gsub(messages[1].text,'12:34','');assert(count==1,'independent duplicate timestamp')
messages={};history={};M:SetChatOwner(pfUI.chat)
ChatFrame1:AddMessage('managed');local _,count=string.gsub(messages[1].text,'12:34','');assert(count==1 and #history==1)
messages={};history={};ChatFrame1.pfCombatLog=true;ChatFrame1.event=nil
ChatFrame1:AddMessage('Delete your WDB');assert(#messages==1 and #history==0)
local _,count=string.gsub(messages[1].text,'12:34','');assert(count==1 and string.find(messages[1].text,'Delete your WDB',1,true))
M:SetChatOwner(nil);messages={};ChatFrame1:AddMessage('combat');local _,count=string.gsub(messages[1].text,'12:34','');assert(count==1)
''')

    def test_managed_copy_uses_native_window_with_exact_text_and_fallback(self):
        lua=runtime()
        lua.execute(r'''
M:OnEnable();local copied={};local owner={urlcopy={CopyText=function(text)copied[#copied+1]=text end}}
M:SetChatOwner(owner);assert(M:HandleLink('ezc:one/1two/2r %42','','LeftButton'))
assert(#copied==1 and copied[1]=='one/two|r %42'and not EasyCopy:IsShown())
owner.urlcopy.CopyText=nil;assert(M:HandleLink('ezc:fallback/1/2','','LeftButton'))
assert(#copied==1 and EasyCopy:IsShown()and EasyCopyText:GetText()=='fallback/|')
M:SetChatOwner(nil);EasyCopy:Hide();assert(M:HandleLink('ezc:independent/1/2','','LeftButton'))
assert(EasyCopy:IsShown()and EasyCopyText:GetText()=='independent/|')
''')

    def test_fonts_have_template_fallback_for_copy_box(self):
        lua=runtime()
        lua.execute("M:OnEnable();EasyCopyText.font=nil;failedFontPaths['missing.ttf']=true;assert(not EasyCopyText:SetFont('missing.ttf',12));M:HandleLink('ezc:copied','','LeftButton');assert(EasyCopyText:GetText()=='copied')")

if __name__=='__main__':unittest.main(verbosity=2)
