"""Selective display filtering with actual legacy AceHook; no game acceptance."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil;string.gmatch=nil;select=nil
strfind=string.find;tinsert=table.insert
ERR_ITEM_COOLDOWN='Item not ready.';ERR_OUT_OF_MANA='Not enough mana.'
SPELL_FAILED_INTERRUPTED='Interrupted'
UIErrorsFrame={events={UI_ERROR_MESSAGE=true,UI_INFO_MESSAGE=true}}
shown={};prints={};eventChanges=0;gameEvents=0
function UIErrorsFrame:RegisterEvent(name)self.events[name]=true;eventChanges=eventChanges+1 end
function UIErrorsFrame:UnregisterEvent(name)self.events[name]=nil;eventChanges=eventChanges+1 end
function UIErrorsFrame:AddMessage(message,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18)
 shown[#shown+1]={self,message,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17,a18}
 return 'display-return',nil,42
end
function dispatch(kind,message)
 gameEvents=gameEvents+1 -- independent stance/other listeners see the real event
 if UIErrorsFrame.events[kind]then UIErrorsFrame:AddMessage(message,1,0,0,1,5)end
end
Automaton={modules={},dbs={}}
function Automaton:NewModule(name)
 local m={name=name,events={}};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:UnregisterAllEvents()self.events={}end
 function m:Print(message)prints[#prints+1]=message end
 return m
end
function Automaton:AcquireDBNamespace(name)
 self.dbs[name]=self.dbs[name]or{char={}};return self.dbs[name]
end
function Automaton:RegisterDefaults(name,scope,values)
 local db=self.dbs[name][scope]
 for k,v in pairs(values)do if db[k]==nil then db[k]=v end end
end
function Automaton:SetDisabledAsDefault()end
AceLibrary={}
function AceLibrary:IsNewVersion()return true end
function AceLibrary:HasInstance(name)return name=='AceOO-2.0'end
function AceLibrary:GetInstance(name)
 assert(name=='AceOO-2.0')
 return {Mixin=function()
  return {super={activate=function()end},error=function(self,fmt,...)error(string.format(fmt,...))end,
   argCheck=function(self,value,index,a,b,c)
    assert(type(value)==a or type(value)==b or type(value)==c,'AceHook type contract')
   end}
 end}
end
function AceLibrary:Register(lib,name,version,activate)RealHook=lib;activate(lib)end
'''


def runtime(setup=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute(setup)
    lua.execute((ROOT / "Interface/AddOns/Automatonex/Modules/ErrClear.lua").read_text(encoding="utf-8"))
    lua.execute((ROOT / "Interface/AddOns/!Libs/Ace2/AceHook-2.1/AceHook-2.1.lua").read_text(encoding="utf-8-sig"))
    lua.execute("M=Automaton.modules.ErrClear;M.Hook=RealHook.Hook;M.Unhook=RealHook.Unhook;M.UnhookAll=RealHook.UnhookAll;RealHook:OnInstanceInit(M);M:OnInitialize()")
    return lua


class ErrorFilter(unittest.TestCase):
    def test_disabled_initialization_keeps_original_role_config(self):
        lua = runtime("Automaton.dbs.ErrClear={char={disabled=true,customErrors={'mine.*','['},personal='keep'},profile={other='unchanged'}}")
        lua.execute("assert(M.db.char.disabled and M.db.char.personal=='keep' and M.db.profile.other=='unchanged');assert(M._options==M.options);assert(not M:ShouldFilter('mine'));UIErrorsFrame:AddMessage('Not enough mana.');assert(#shown==1)")

    def test_defaults_and_original_pattern_substrings_still_filter(self):
        lua = runtime()
        lua.execute("M:OnEnable();M:NewError('alpha%d+');assert(M:ShouldFilter('prefix alpha123 suffix'));assert(not M:ShouldFilter('Alpha123'));assert(M:ShouldFilter('Not enough mana.'));assert(M:ShouldFilter('prefix 不能在移动中 suffix'));assert(not M:ShouldFilter('A different error'));assert(M.db.char.customErrors[1]=='alpha%d+')")

    def test_malformed_patterns_fall_back_to_literal_without_rewriting(self):
        lua = runtime("Automaton.dbs.ErrClear={char={customErrors={'[','%','foo('}}}")
        lua.execute("M:OnEnable();assert(M:ShouldFilter('literal [ warning'));assert(M:ShouldFilter('100% chance'));assert(M:ShouldFilter('foo(bar'));assert(not M:ShouldFilter('ordinary error'));assert(M.db.char.customErrors[1]=='[' and M.db.char.customErrors[2]=='%' and M.db.char.customErrors[3]=='foo(')")

    def test_non_string_message_and_corrupt_rule_do_not_crash(self):
        lua = runtime("Automaton.dbs.ErrClear={char={customErrors={42,false,{},'blocked'}}}")
        lua.execute("M:OnEnable();UIErrorsFrame:AddMessage(nil);UIErrorsFrame:AddMessage(123);UIErrorsFrame:AddMessage({value=1});assert(#shown==3);assert(M:ShouldFilter('blocked'));assert(not M:ShouldFilter('normal'))")

    def test_disable_restores_display_and_reenable_is_idempotent(self):
        lua = runtime()
        lua.execute("local original=UIErrorsFrame.AddMessage;M:OnEnable();local hook=UIErrorsFrame.AddMessage;M:OnEnable();assert(UIErrorsFrame.AddMessage==hook);UIErrorsFrame:AddMessage('Not enough mana.');assert(#shown==0);M:OnDisable();assert(UIErrorsFrame.AddMessage==original and not M.runtimeActive);UIErrorsFrame:AddMessage('Not enough mana.');assert(#shown==1);M:OnEnable();UIErrorsFrame:AddMessage('Not enough mana.');assert(#shown==1);M:OnDisable();assert(eventChanges==0)")

    def test_all_original_arguments_and_multiple_returns_are_forwarded(self):
        lua = runtime()
        lua.execute("M:OnEnable();local a,b,c=UIErrorsFrame:AddMessage('visible',1,nil,3,nil,5,6,7,8,9,10,11,12,13,14,15,16,17,18);assert(a=='display-return' and b==nil and c==42);assert(shown[1][1]==UIErrorsFrame and shown[1][3]==1 and shown[1][4]==nil and shown[1][7]==5 and shown[1][20]==18)")

    def test_later_wrapper_survives_disable_and_reenable(self):
        lua = runtime()
        lua.execute('''
M:OnEnable();local base=UIErrorsFrame.AddMessage;outerCalls=0
UIErrorsFrame.AddMessage=function(frame,msg,a,b,c,d,e)
 outerCalls=outerCalls+1;return base(frame,msg,a,b,c,d,e)
end
local outer=UIErrorsFrame.AddMessage
M:OnDisable();local a,b,c=UIErrorsFrame:AddMessage('Not enough mana.',1,0,0,1,5)
assert(a=='display-return' and b==nil and c==42 and #shown==1 and outerCalls==1)
M:OnEnable();assert(UIErrorsFrame.AddMessage==outer)
UIErrorsFrame:AddMessage('Not enough mana.');assert(#shown==1 and outerCalls==2)
M:OnDisable();UIErrorsFrame:AddMessage('Not enough mana.');assert(#shown==2 and outerCalls==3)
''')

    def test_existing_wrapper_and_repeated_cycles_do_not_accumulate(self):
        lua = runtime()
        lua.execute('''
local base=UIErrorsFrame.AddMessage;beforeCalls=0
UIErrorsFrame.AddMessage=function(frame,msg,a,b,c,d,e)beforeCalls=beforeCalls+1;return base(frame,msg,a,b,c,d,e)end
for i=1,10 do M:OnEnable();UIErrorsFrame:AddMessage('visible');M:OnDisable();UIErrorsFrame:AddMessage('visible')end
assert(beforeCalls==20 and #shown==20 and eventChanges==0)
''')

    def test_filtering_display_never_consumes_gameplay_events(self):
        lua = runtime()
        lua.execute("M:OnEnable();dispatch('UI_ERROR_MESSAGE','Not enough mana.');dispatch('UI_INFO_MESSAGE','normal notice');assert(gameEvents==2 and #shown==1);assert(UIErrorsFrame.events.UI_ERROR_MESSAGE and UIErrorsFrame.events.UI_INFO_MESSAGE and eventChanges==0)")

    def test_native_hide_and_selective_filter_remain_independent(self):
        lua = runtime()
        source = (ROOT / "Interface/AddOns/pfUI/modules/skin.lua").read_text(encoding="utf-8")
        start = source.index('  if C.global.errors_hide == "1" then')
        block = source[start:source.index('\n  end', start)+len('\n  end')]
        lua.globals().nativeHideBlock = block
        lua.execute('''
C={global={errors_hide='1'}};M:OnEnable();assert(loadstring(nativeHideBlock))()
dispatch('UI_ERROR_MESSAGE','visible');assert(#shown==0 and gameEvents==1)
-- Explicit addon notices remain a separate display path, as before.
UIErrorsFrame:AddMessage('addon notice');assert(#shown==1)
C.global.errors_hide='0';assert(loadstring(nativeHideBlock))()
dispatch('UI_ERROR_MESSAGE','Not enough mana.');assert(#shown==1 and gameEvents==2)
dispatch('UI_ERROR_MESSAGE','visible');assert(#shown==2 and gameEvents==3)
M:OnDisable();assert(C.global.errors_hide=='0' and UIErrorsFrame.events.UI_ERROR_MESSAGE)
''')

    def test_settings_can_edit_while_disabled_and_preserve_existing_values(self):
        lua = runtime("Automaton.dbs.ErrClear={char={disabled=true,customErrors={'old.*'}}}")
        lua.execute("M.options.ignore.args.add.set('new%d+');assert(M.db.char.customErrors[1]=='old.*' and M.db.char.customErrors[2]=='new%d+' and M.db.char.disabled);M.options.ignore.args.remove.set('new%d+');assert(#M.db.char.customErrors==1);M:OnEnable();M:OnDisable();assert(M.db.char.customErrors[1]=='old.*' and M.db.char.disabled)")

    def test_management_rejects_invalid_input_and_retains_literal_values(self):
        lua = runtime()
        lua.execute("M:NewError(nil);M:NewError(12);M:NewError('');M:RemoveError(nil);M:RemoveError(12);assert(#M.db.char.customErrors==0);M:NewError('[');M:NewError('same');M:NewError('same');M:RemoveError('same');assert(#M.db.char.customErrors==2 and M.db.char.customErrors[1]=='[');M:ListErrors();M:PurgeErrors();assert(#M.db.char.customErrors==0)")

    def test_whole_saved_list_is_not_migrated_on_lifecycle(self):
        lua = runtime("Automaton.dbs.ErrClear={char={customErrors={'prefix','%d+', '', '['},disabled=false},account={saved='keep'}}")
        lua.execute("local rules=M.db.char.customErrors;M:OnEnable();assert(M:ShouldFilter('any') and M.db.char.customErrors==rules);M:OnDisable();assert(M.db.char.customErrors==rules and #rules==4 and rules[3]=='' and M.db.account.saved=='keep')")


if __name__ == '__main__':
    unittest.main(verbosity=2)
