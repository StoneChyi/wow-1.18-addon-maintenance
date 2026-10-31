"""Real player click handlers, both hook orders, preserved PLE actions and fallback."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil -- no modern compatibility shim in vanilla Lua
strsub=string.sub;strlen=string.len;gsub=string.gsub
function getglobal(n)return _G[n]end
calls={};popups={};chatVisible=true
function record(kind,value)table.insert(calls,{kind,value})end
function IsShiftKeyDown()return shift end
function IsControlKeyDown()return ctrl end
function IsAltKeyDown()return alt end
function StaticPopup_Visible(which)return popups[which]end
ChatFrameEditBox={IsVisible=function()return chatVisible end,Insert=function(_,s)record('insert',s)end}
PopupEditBox={SetText=function(_,s)record('popup',s)end}
function SendWho(s)record('who',s)end
function TargetByName(s)record('target',s)end
function ple_GetName(s)record('name',s)end
function FriendsFrame_ShowDropdown(s)record('menu',s)end
function ChatFrame_SendTell(s)record('tell',s)end
function Base(link)record('base',link)end
SetItemRef=Base
pfUI_config={chat={text={playerlinks='1'}},automation={}}
pfUI={automationIntegrations={}}
Automaton={modules={},db={char={disabledModules={}}},modulePrototype={}}
function Automaton:IsModuleActive(name)return not self.db.char.disabledModules[name]end
function Automaton:ToggleModuleActive(name,value)self.db.char.disabledModules[name]=not value or nil end
function Automaton:ToggleMainWindow()end
function Automaton:NewModule(name)
 local m={name=name,hooks={},tokens={},hookCount=0};self.modules[name]=m
 function m:RegisterOptions(opts)self._options=opts end
 function m:Hook(key)
  local before=_G[key];local token={active=true};self.tokens[key]=token;self.hooks[key]=before;self.hookCount=self.hookCount+1
  _G[key]=function(...)if token.active then return self[key](self,unpack(arg))else return before(unpack(arg))end end
 end
 function m:UnhookAll()for _,t in pairs(self.tokens)do t.active=false end end
 return m
end
function Automaton:AcquireDBNamespace()return {profile={}}end
function Automaton:RegisterDefaults()end
function Automaton:SetDisabledAsDefault()end
'''

def runtime(order='before', ple=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    legacy = ROOT/'Interface/AddOns/Automatonex/Modules/InterPlayerLink.lua'
    lua.execute(legacy.read_text(encoding='utf8'))
    lua.execute('legacy=Automaton.modules.InterPlayerLink;legacy:OnInitialize();legacy:OnEnable()')
    lua.execute((ROOT/'Interface/AddOns/Automatonex/PfUIBridge.lua').read_text(encoding='utf8'))
    lua.execute((ROOT/'Interface/AddOns/pfUI/modules/chat_playerlinks.lua').read_text(encoding='utf8'))
    source = (ROOT/'Interface/AddOns/PlayerLinkEnhance/PlayerLinkEnhance.lua').read_text(encoding='utf8')
    start = source.index('function ple_SetItemRef(')
    stop = source.index('\nfunction ple_GetName(', start)
    ple_source = source[start:stop]
    chat = (ROOT/'Interface/AddOns/pfUI/modules/chat.lua').read_text(encoding='utf8')
    start = chat.index('  function _G.SetItemRef(')
    stop = chat.index('  pfUI.chat.right =', start)
    native = chat[start:stop]
    def load_ple():
        lua.execute('ori_SetItemRef=SetItemRef')
        lua.execute(ple_source)
        lua.execute('SetItemRef=ple_SetItemRef')
    if ple and order == 'before': load_ple()
    lua.execute("pfUI.chat={urlcopy={SetItemRef=SetItemRef,Show=function()record('url','open')end,SetText=function(_,s)record('url',s)end}};pfUI.chatPlayerLinks.ready=true")
    lua.execute(native)
    if ple and order == 'after': load_ple()
    lua.execute('links=pfUI.chatPlayerLinks;assert(links:Sync(true))')
    return lua

class FusionTests(unittest.TestCase):
    def test_hook_orders_insert_exactly_once_and_strip_line_suffix(self):
        for order in ('before','after'):
            lua=runtime(order)
            lua.execute("shift=true;SetItemRef('player:兼职奶骑:37','name','LeftButton');assert(#calls==1 and calls[1][2]=='|cffffffff|Hplayer:兼职奶骑|h[兼职奶骑]|h|r');assert(links.managed)")
    def test_all_popup_types_take_priority_over_open_chat(self):
        for order in ('before','after'):
            for popup in ('ADD_IGNORE','ADD_FRIEND','ADD_GUILDMEMBER','ADD_RAIDMEMBER'):
                lua=runtime(order)
                lua.globals().popupKind=popup
                lua.execute("shift=true;popups[popupKind]='Popup';SetItemRef('player:Example:42','','LeftButton');assert(#calls==1 and calls[1][1]=='popup' and calls[1][2]=='Example')")
    def test_unique_ple_actions_are_preserved(self):
        for order in ('before','after'):
            lua=runtime(order)
            lua.execute(r'''
shift=true;chatVisible=false;SetItemRef('player:A','','LeftButton');assert(calls[1][1]=='who')
shift=false;ctrl=true;SetItemRef('player:A','','LeftButton');assert(calls[2][1]=='target')
ctrl=false;alt=true;SetItemRef('player:A','','LeftButton');assert(calls[3][1]=='name')
alt=false;SetItemRef('player:A','','RightButton');assert(calls[4][1]=='menu')
SetItemRef('player:A','','LeftButton');assert(calls[5][1]=='tell')
''')
    def test_native_setting_changes_apply_immediately_without_reenable(self):
        lua=runtime()
        lua.execute("Automaton:ToggleModuleActive('InterPlayerLink',false);assert(not links:GetEnabled() and not Automaton:IsModuleActive('InterPlayerLink'));shift=true;SetItemRef('player:A','','LeftButton');assert(calls[1][2]=='A');assert(Automaton.db.char.disabledModules.InterPlayerLink==nil);links:Sync(true);assert(not links:GetEnabled())")
    def test_old_enabled_imports_once_and_preserves_raw_intent(self):
        lua=runtime()
        lua.execute("pfUI_config.chat.text.playerlinks='0';pfUI_config.automation.playerlinksMigrated=nil;links:Sync(true);assert(links:GetEnabled());links:SetEnabled(false);links:Sync(true);assert(not links:GetEnabled());assert(Automaton.db.char.disabledModules.InterPlayerLink==nil)")
    def test_release_restores_original_enabled_module_with_lua50_strings(self):
        lua=runtime(ple=False)
        lua.execute("links:Sync(false);assert(not links.managed);links.ready=false;shift=true;SetItemRef('player:A:55','','LeftButton');assert(#calls==1 and string.find(calls[1][2],'Hplayer:A|h',1,true));local n=legacy.hookCount;links:Sync(false);assert(legacy.hookCount==n)")
    def test_original_disabled_module_does_not_start_on_release(self):
        lua=runtime()
        lua.execute("Automaton.db.char.disabledModules.InterPlayerLink=true;local n=legacy.hookCount;links:Sync(false);assert(legacy.hookCount==n);assert(Automaton.db.char.disabledModules.InterPlayerLink)")
    def test_legacy_onenable_cannot_reinstall_duplicate_hook(self):
        lua=runtime()
        lua.execute("local n=legacy.hookCount;for i=1,20 do links:Sync(true);legacy:OnEnable()end;assert(n==legacy.hookCount)")
    def test_no_ple_keeps_default_actions_and_nonplayer_passthrough(self):
        lua=runtime(ple=False)
        lua.execute("SetItemRef('item:123','','LeftButton');SetItemRef('player:A','','RightButton');assert(#calls==2 and calls[1][1]=='base' and calls[2][1]=='base');shift=true;SetItemRef('player:A','','LeftButton');assert(calls[3][1]=='insert')")
    def test_native_chat_inactive_uses_unchanged_ple_behavior(self):
        lua=runtime('after')
        lua.execute("Automaton.db.char.disabledModules.InterPlayerLink=true;links:Sync(false);links.ready=false;shift=true;SetItemRef('player:A','','LeftButton');assert(#calls==1 and calls[1][2]=='A')")

if __name__ == '__main__': unittest.main(verbosity=2)
