"""Actual pfUI repeat pipeline and extracted native link dispatcher contracts."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime
REPEAT_SOURCE = (ROOT / "Interface/AddOns/pfUI/modules/chatrepeatfilter.lua").read_text(encoding="utf-8")
CHAT_SOURCE = (ROOT / "Interface/AddOns/pfUI/modules/chat.lua").read_text(encoding="utf-8")

MOCK = r'''
string.match=nil;string.gmatch=nil;select=nil
local nativeUnpack=unpack
function unpack(values,...)assert(arg.n==0,'Lua5.0 unpack takes only the table');return nativeUnpack(values)end
now=10;normCalls=0;displays={};formatted=0;player='Self'
C={chat={global={repeatfilter='1',repeatfilterinterval='20',repeatfilterexclude=''}}}
pfUI={};function pfUI:RegisterModule(name,versions,init)init()end
function UnitName(unit)assert(unit=='player');return player end
function GetTime()return now end
function gsub(text,pattern,replacement,n)
 if pattern=='%s+' then normCalls=normCalls+1 end
 return string.gsub(text,pattern,replacement,n)
end
function strsplit(delimiter,text)
 local values={};for value in string.gfind(text..delimiter,'(.-)'..delimiter)do values[#values+1]=value end
 return unpack(values)
end
function frame(id)return {GetID=function()return id end}end
F1=frame(1);F2=frame(2);F3=frame(3)
function ChatFrame_OnEvent(kind)
 displays[#displays+1]={this:GetID(),kind,arg1,arg2,arg9}
 return 'displayed',nil,42
end
function cleanLayer()
 local original=ChatFrame_OnEvent
 ChatFrame_OnEvent=function(kind)
  return pfUI.chatRepeatFilter:Run(this,kind,function(k)
   local saved=arg1;formatted=formatted+1;arg1='[format '..formatted..'] '..tostring(saved)
   local result={original(k)};arg1=saved
   return result[1],result[2],result[3]
  end)
 end
end
function dispatch(f,kind,msg,sender,channel)
 this=f;event=kind;arg1=msg;arg2=sender;arg9=channel
 return ChatFrame_OnEvent(kind)
end
'''


def runtime(clean_order=None):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    if clean_order == "before":
        lua.execute("cleanLayer()")
    lua.execute(REPEAT_SOURCE)
    if clean_order == "after":
        lua.execute("cleanLayer()")
    return lua


def links_runtime():
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
C={automation={enabled='1'}};calls={};strsub=string.sub
pfUI={chat={urlcopy={text={}}},chatPlayerLinks={}}
function pfUI.chat.urlcopy.text:SetText(text)self.value=text end
function pfUI.chat.urlcopy:Show()self.shown=true end
function pfUI.chatPlayerLinks:Handle(link,text,button)
 calls[#calls+1]={'player',link,text,button};return string.sub(link,1,7)=='player:'
end
function SetItemRef(link,text,button)
 calls[#calls+1]={'native',link,text,button};return 'native-return',nil,42
end
Automaton={modules={CleanChat={}}};clean=Automaton.modules.CleanChat
function clean:SetChatOwner(owner)self.chatOwner=owner end
function clean:HandleLink(link,text,button)
 calls[#calls+1]={'clean',link,text,button};return string.sub(link,1,4)=='inv:' or string.sub(link,1,4)=='ezc:'
end
''')
    start = CHAT_SOURCE.index("  pfUI.chat.urlcopy.SetItemRef = SetItemRef")
    stop = CHAT_SOURCE.index('  pfUI.chat.right = CreateFrame', start)
    lua.execute(CHAT_SOURCE[start:stop])
    start = CHAT_SOURCE.index("  function pfUI.chat:SyncAutomation(managed)")
    stop = CHAT_SOURCE.index("  -- Player clicks share", start)
    lua.execute(CHAT_SOURCE[start:stop])
    return lua


def native_message_runtime(order='clean-first'):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(r'''
C={chat={global={whispermod='0'},text={time='1',timeformat='%H:%M',detecturl='0',classcolor='0',playerlevel='0',playerrace='0',channelnumonly='0'}}}
pfUI={chat={}};history={};display={};gsub=string.gsub
function GetTime()return 10 end
function date(format)assert(format=='%H:%M');return '12:34'end
function SaveChatHistory(id,text,r,g,b)history[#history+1]={id,text,r,g,b}end
Automaton={modules={CleanChat={runtimeActive=true,db={profile={ShowChatTime=true}}}}}
clean=Automaton.modules.CleanChat
function clean:ShouldFilterDisplay(text)return self.runtimeActive and type(text)=='string' and string.find(text,'blocked',1,true)~=nil end
frame=setmetatable({GetID=function()return 1 end},{__index=function(_,key)
 if key=='IsEventRegistered'then error('Frame:IsEventRegistered is absent in WoW 1.12')end
end})
function nativeDisplay(frame,text,a,b,c,d,e)display[#display+1]={text,a,b,c,d,e};return 'display-return'end
function wrapClean(original)
 return function(frame,text,a,b,c,d,e)
  if clean:ShouldFilterDisplay(text)then return end
  if clean.runtimeActive and not clean.chatOwner and clean.db.profile.ShowChatTime and not frame.pfCombatLog then text='[CC 12:34] '..text end
  return original(frame,text,a,b,c,d,e)
 end
end
''')
    start=CHAT_SOURCE.index('  local function UseNativeTimestamp(frame)')
    stop=CHAT_SOURCE.index('  for i=1,NUM_CHAT_WINDOWS do',start)
    lua.execute("local who_query={};local channelMap={};local timecolorhex='[PF]';local tleft='[';local tright=']'\n"+CHAT_SOURCE[start:stop]+"\nNativeMessage=AddMessage;NativeTimestamp=UseNativeTimestamp")
    if order == 'clean-first':
        lua.execute("frame.HookAddMessage=wrapClean(nativeDisplay);frame.AddMessage=NativeMessage")
    else:
        lua.execute("frame.HookAddMessage=nativeDisplay;frame.AddMessage=wrapClean(NativeMessage)")
    return lua


class ChatPipeline(unittest.TestCase):
    def test_two_load_orders_filter_raw_event_only_once(self):
        for order in ("before", "after"):
            with self.subTest(order=order):
                lua = runtime(order)
                lua.execute('''
local a,b,c=dispatch(F1,'CHAT_MSG_SAY','Raw   MMM message','Other','')
assert(a=='displayed' and b==nil and c==42)
assert(#displays==1 and formatted==1 and normCalls==1)
assert(arg1=='Raw   MMM message' and arg2=='Other' and arg9=='')
dispatch(F1,'CHAT_MSG_SAY','raw m message','Other','')
assert(#displays==1 and formatted==1 and normCalls==2)
''')

    def test_first_message_visible_in_each_frame_real_repeat_hidden_in_all(self):
        lua = runtime("after")
        lua.execute('''
for _,f in ipairs({F1,F2,F3})do dispatch(f,'CHAT_MSG_GUILD','first','Other','')end
assert(#displays==3 and normCalls==3)
for _,f in ipairs({F1,F2,F3})do dispatch(f,'CHAT_MSG_GUILD','first','Other','')end
assert(#displays==3 and normCalls==6 and formatted==3)
now=30
for _,f in ipairs({F1,F2,F3})do dispatch(f,'CHAT_MSG_GUILD','first','Other','')end
assert(#displays==6)
''')

    def test_sender_event_and_channel_identities_do_not_collide(self):
        lua = runtime()
        lua.execute('''
dispatch(F1,'CHAT_MSG_CHANNEL','same','A','World')
dispatch(F1,'CHAT_MSG_CHANNEL','same','B','World')
dispatch(F1,'CHAT_MSG_CHANNEL','same','A','Trade')
dispatch(F1,'CHAT_MSG_SAY','same','A','World')
assert(#displays==4)
dispatch(F1,'CHAT_MSG_CHANNEL','same','A','World');assert(#displays==4)
''')

    def test_self_empty_sender_nonstring_and_unfiltered_events_pass(self):
        lua = runtime()
        lua.execute('''
for i=1,2 do
 dispatch(F1,'CHAT_MSG_SAY','same','Self','')
 dispatch(F1,'CHAT_MSG_SAY','same','','')
 dispatch(F1,'CHAT_MSG_SAY',nil,'Other','')
 dispatch(F1,'CHAT_MSG_SYSTEM','same','Other','')
end
assert(#displays==8 and normCalls==0)
''')

    def test_excluded_channels_support_chinese_commas_and_number_prefix(self):
        lua = runtime()
        lua.execute('''
C.chat.global.repeatfilterexclude='4. 世界，Trade,  guild'
for i=1,2 do dispatch(F1,'CHAT_MSG_CHANNEL','same','Other','世界');dispatch(F1,'CHAT_MSG_CHANNEL','same','Other','TRADE')end
assert(#displays==4)
dispatch(F1,'CHAT_MSG_CHANNEL','same','Other','General');dispatch(F1,'CHAT_MSG_CHANNEL','same','Other','General');assert(#displays==5)
C.chat.global.repeatfilterexclude='General'
dispatch(F1,'CHAT_MSG_CHANNEL','same','Other','General');assert(#displays==6)
''')

    def test_interval_changes_and_disable_reenable_take_effect_live(self):
        lua = runtime()
        lua.execute('''
dispatch(F1,'CHAT_MSG_SAY','same','Other','');dispatch(F1,'CHAT_MSG_SAY','same','Other','');assert(#displays==1)
C.chat.global.repeatfilter='0';dispatch(F1,'CHAT_MSG_SAY','same','Other','');dispatch(F1,'CHAT_MSG_SAY','same','Other','');assert(#displays==3)
C.chat.global.repeatfilter='1';dispatch(F1,'CHAT_MSG_SAY','same','Other','');assert(#displays==4)
C.chat.global.repeatfilterinterval='1';now=11;dispatch(F1,'CHAT_MSG_SAY','same','Other','');assert(#displays==5)
for _,value in ipairs({'0','-1',1/0,0/0})do C.chat.global.repeatfilterinterval=value;dispatch(F1,'CHAT_MSG_SAY','same','Other','');dispatch(F1,'CHAT_MSG_SAY','same','Other','')end
assert(#displays==13)
''')

    def test_error_clears_context_and_preserves_event_arguments(self):
        lua = runtime()
        lua.execute('''
this=F1;arg1='one';arg2='Other';arg9='World';event='CHAT_MSG_CHANNEL'
local ok=pcall(function()pfUI.chatRepeatFilter:Run(F1,event,function()error('failure')end)end)
assert(not ok and arg1=='one' and arg2=='Other' and arg9=='World' and event=='CHAT_MSG_CHANNEL')
local count=normCalls;arg1='two'
local a,b,c=pfUI.chatRepeatFilter:Run(F1,event,function()return 'ok',nil,7 end)
assert(a=='ok' and b==nil and c==7 and normCalls==count+1)
''')

    def test_nested_pipeline_preserves_nil_returns_without_double_count(self):
        lua = runtime()
        lua.execute('''
arg1='nested';arg2='Other';arg9='';this=F1
local a,b,c,d=pfUI.chatRepeatFilter:Run(F1,'CHAT_MSG_SAY',function(kind)
 return pfUI.chatRepeatFilter:Run(F1,kind,function(k)assert(k==kind);return 1,nil,3,nil end)
end)
assert(a==1 and b==nil and c==3 and d==nil and normCalls==1)
''')

    def test_trailing_nil_return_count_and_legacy_unpack_contract(self):
        lua = runtime()
        lua.execute(r'''
arg1='returns';arg2='Other';arg9='';this=F1
local function pack(...)return arg end
local values=pack(pfUI.chatRepeatFilter:Run(F1,'CHAT_MSG_SAY',function()return 1,nil,3,nil end))
assert(values.n==4 and values[1]==1 and values[2]==nil and values[3]==3 and values[4]==nil)
arg1='empty';values=pack(pfUI.chatRepeatFilter:Run(F1,'CHAT_MSG_SAY',function()end));assert(values.n==0)
''')

    def test_native_chat_releases_standalone_style_before_applying_its_own(self):
        lua = LuaRuntime(unpack_returned_tuples=True)
        start = CHAT_SOURCE.index('  local cleanBeforeChat =')
        stop = CHAT_SOURCE.index('  -- 确保配置项存在', start)
        lua.globals().preamble = CHAT_SOURCE[start:stop]
        lua.execute(r'''
C={automation={enabled='1'}};releases=0
Automaton={modules={CleanChat={RestoreVisuals=function()releases=releases+1 end}}}
assert(loadstring(preamble))();assert(releases==1)
C.automation.enabled='0';assert(loadstring(preamble))();assert(releases==1)
C.automation=nil;assert(loadstring(preamble))();assert(releases==2)
Automaton=nil;assert(loadstring(preamble))();assert(releases==2)
Automaton={modules={}};assert(loadstring(preamble))();assert(releases==2)
''')

    def test_notification_decision_is_independent_from_display_frames(self):
        lua = runtime("before")
        lua.execute('''
dispatch(F1,'CHAT_MSG_SAY','same','Other','')
assert(pfUI.chatRepeatFilter:ShouldNotify('CHAT_MSG_SAY','same','Other',''))
dispatch(F2,'CHAT_MSG_SAY','same','Other','');assert(#displays==2)
assert(not pfUI.chatRepeatFilter:ShouldNotify('CHAT_MSG_SAY','same','Other',''))
dispatch(F1,'CHAT_MSG_SAY','same','Other','');assert(#displays==2)
assert(pfUI.chatRepeatFilter:ShouldNotify('CHAT_MSG_SYSTEM','same','Other',''))
C.chat.global.repeatfilter='0';assert(pfUI.chatRepeatFilter:ShouldNotify('CHAT_MSG_SAY','same','Other',''))
''')

    def test_filtered_display_never_enters_native_history_in_either_wrapper_order(self):
        for order in ('clean-first','pfui-first'):
            with self.subTest(order=order):
                lua=native_message_runtime(order)
                lua.execute(r'''
frame:AddMessage('blocked original',1,0,0,1,5)
assert(#history==0 and #display==0)
frame:AddMessage('legal original',.1,.2,.3,.4,5)
assert(#history==1 and #display==1 and string.find(history[1][2],'legal original',1,true))
assert(history[1][3]==.1 and display[1][2]==.1 and display[1][6]==5)
assert(not string.find(display[1][1],'[PF]',1,true) and string.find(display[1][1],'[CC 12:34]',1,true))
''')

    def test_timestamp_owner_switch_is_single_and_does_not_change_saved_preferences(self):
        for order in ('clean-first','pfui-first'):
            with self.subTest(order=order):
                lua=native_message_runtime(order)
                lua.execute(r'''
clean.chatOwner=pfUI.chat;frame:AddMessage('managed',1,1,1)
assert(string.find(display[1][1],'[PF]',1,true) and not string.find(display[1][1],'[CC',1,true))
clean.chatOwner=nil;frame:AddMessage('independent',1,1,1)
assert(not string.find(display[2][1],'[PF]',1,true) and string.find(display[2][1],'[CC',1,true))
clean.runtimeActive=false;frame:AddMessage('disabled module',1,1,1)
assert(string.find(display[3][1],'[PF]',1,true) and not string.find(display[3][1],'[CC',1,true))
assert(C.chat.text.time=='1' and clean.db.profile.ShowChatTime)
assert(#history==3)
''')

    def test_native_timestamp_helper_preserves_combat_and_setting_off(self):
        lua=native_message_runtime()
        lua.execute(r'''
assert(not NativeTimestamp(frame))
frame.pfCombatLog=true;assert(NativeTimestamp(frame))
NativeMessage(frame,'combat text',1,0,0,1,5)
assert(#history==0 and #display==1 and string.find(display[1][1],'[PF]',1,true))
C.chat.text.time='0';assert(not NativeTimestamp(frame))
frame.pfCombatLog=nil;assert(not NativeTimestamp(frame))
C.chat.text.time='1';clean.db.profile.ShowChatTime=false;assert(NativeTimestamp(frame))
clean.db=nil;assert(NativeTimestamp(frame));Automaton=nil;assert(NativeTimestamp(frame))
''')

    def test_link_dispatch_prioritizes_managed_clean_custom_links(self):
        lua = links_runtime()
        lua.execute("SetItemRef('inv:Name','text','LeftButton');assert(#calls==1 and calls[1][1]=='clean');SetItemRef('ezc:copy','text','RightButton');assert(#calls==2 and calls[2][1]=='clean')")

    def test_link_dispatch_preserves_player_url_and_other_chain_returns(self):
        lua = links_runtime()
        lua.execute('''
SetItemRef('player:Name','text','RightButton');assert(#calls==2 and calls[1][1]=='clean' and calls[2][1]=='player')
calls={};SetItemRef('url:https://example.invalid','display','LeftButton');assert(#calls==2 and pfUI.chat.urlcopy.text.value=='https://example.invalid' and pfUI.chat.urlcopy.shown)
calls={};local a,b,c=SetItemRef('item:123:0:0:0','original text','MiddleButton')
assert(a=='native-return' and b==nil and c==42 and #calls==3 and calls[3][2]=='item:123:0:0:0' and calls[3][3]=='original text' and calls[3][4]=='MiddleButton')
''')

    def test_managed_toggle_releases_and_reacquires_without_saved_value_changes(self):
        lua = links_runtime()
        lua.execute('''
assert(clean.chatOwner==pfUI.chat and C.automation.enabled=='1')
pfUI.automationIntegrations.CleanChat:Sync(false);assert(clean.chatOwner==nil and C.automation.enabled=='1')
SetItemRef('inv:Name','text','LeftButton');assert(#calls==2 and calls[1][1]=='player' and calls[2][1]=='native')
pfUI.automationIntegrations.CleanChat:Sync(true);assert(clean.chatOwner==pfUI.chat)
Automaton=nil;assert(pfUI.chat:SyncAutomation());calls={};local a,b,c=SetItemRef('item:1','text','LeftButton');assert(#calls==2 and a=='native-return' and b==nil and c==42)
''')


if __name__ == '__main__':
    unittest.main(verbosity=2)
