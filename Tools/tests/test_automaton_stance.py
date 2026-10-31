"""Legacy stance hooks with real module source; no client actions are performed."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.match=nil;string.gmatch=nil;select=nil
now=10;class='DRUID';power=0;build='1.18.0';BOOKTYPE_SPELL='spell';UIParent={}
SPELL_FAILED_ONLY_SHAPESHIFT='Requires %s.';MANA_COST='%d Mana'
spells={};forms={};actions={};calls={};shifts={};frames={};pfUI={}
function GetBuildInfo()return build end
function GetTime()return now end
function UnitClass()return class,class end
function UnitPowerType()return power end
function GetNumShapeshiftForms()return #forms end
function GetShapeshiftFormInfo(i)
 local f=forms[i];return f.texture or 'form',f.name,f.active,f.castable
end
function CastShapeshiftForm(i)
 assert(forms[i],'invalid hard-coded form index');shifts[#shifts+1]=i
 if shiftCallback then shiftCallback(i)end
end
function GetSpellName(i,book)
 assert(book=='spell' or book=='pet','old book token required')
 local s=(book=='pet' and petspells or spells)[i];if s then return s.name,s.rank end
end
function GetSpellTexture(i,book)return spells[i] and spells[i].texture end
function GetActionText(slot)return actions[slot] and actions[slot].macro end
function GetActionTexture(slot)return actions[slot] and actions[slot].texture end
function CastSpell(id,book) calls[#calls+1]={'spell',id,book};if castError then M:HandleError(castError)end;return 'spell-return',nil,3 end
function CastSpellByName(name,selfcast) calls[#calls+1]={'name',name,selfcast};if castError then M:HandleError(castError)end;return 'name-return',nil,4 end
function UseAction(slot,cursor,selfcast)calls[#calls+1]={'action',slot,cursor,selfcast};if castError then M:HandleError(castError)end;return 'action-return',nil,5 end
Automaton={modules={},dbs={}}
function Automaton:NewModule(name)
 local m={events={},hooks={}};self.modules[name]=m
 function m:RegisterOptions(options)self._options=options end
 function m:RegisterEvent(event,handler)self.events[event]=handler or event end
 function m:UnregisterAllEvents()self.events={}end
 function m:Hook(name)
  assert(not self.hooks[name],'duplicate hook');local original=_G[name];self.hooks[name]=original
  _G[name]=function(a,b,c)return self[name](self,a,b,c)end
 end
 function m:UnhookAll()for name,original in pairs(self.hooks)do _G[name]=original end;self.hooks={}end
 return m
end
function Automaton:AcquireDBNamespace(name)self.dbs[name]=self.dbs[name]or{profile={}};return self.dbs[name]end
function Automaton:RegisterDefaults(name,scope,values)
 for k,v in pairs(values)do if self.dbs[name][scope][k]==nil then self.dbs[name][scope][k]=v end end
end
function Automaton:SetDisabledAsDefault()end
methods={}
function methods:GetText()return self.text end
function newObject(kind,name,parent)
 local f=setmetatable({kind=kind,name=name,parent=parent},{__index=methods});if name then _G[name]=f end;return f
end
function methods:GetName()return self.name end
function methods:SetOwner(owner,anchor)assert(owner==UIParent and anchor=='ANCHOR_NONE')end
function methods:Hide()self.hidden=true end
function methods:ClearLines()for i=1,4 do _G[self.name..'TextLeft'..i]:SetText('')end end
function methods:SetSpell(id,book)
 assert(book==BOOKTYPE_SPELL);self:ClearLines();local s=spells[id];assert(s)
 for i=1,4 do _G[self.name..'TextLeft'..i]:SetText(s.lines and s.lines[i] or '')end
end
function methods:SetAction(slot)
 self:ClearLines();local a=actions[slot];if a then _G[self.name..'TextLeft1']:SetText(a.name or '')end
end
function CreateFrame(kind,name,parent,template)
 assert(kind=='GameTooltip' and template=='GameTooltipTemplate')
 assert(not _G[name],'named tooltip must be reused')
 local f=newObject(kind,name,parent)
 for i=1,4 do f:CreateFontString(name..'TextLeft'..i,'ARTWORK','GameFontNormal')end
 frames[#frames+1]=f;return f
end
'''


def runtime(setup=""):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    lua.execute((ROOT / "Tools/tests/wow112_fontstring_mock.lua").read_text(encoding="utf-8"))(lua.globals().methods, lua.globals().newObject)
    lua.execute(setup)
    lua.execute((ROOT / "Interface/AddOns/Automatonex/Modules/ShaguStance.lua").read_text(encoding="utf-8"))
    lua.execute(r'''
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
''')
    lua.execute((ROOT / "Interface/AddOns/!Libs/Ace2/AceHook-2.1/AceHook-2.1.lua").read_text(encoding="utf-8-sig"))
    lua.execute("M=Automaton.modules.ShaguStance;M.Hook=RealHook.Hook;M.Unhook=RealHook.Unhook;M.UnhookAll=RealHook.UnhookAll;RealHook:OnInstanceInit(M);M:OnInitialize()")
    return lua


class Stance(unittest.TestCase):
    def test_initialization_preserves_saved_namespace_and_old_lua(self):
        for build, turtle in (("1.18.0", True), ("1.12.1", False), ("unknown", False), ("3.3.5", False)):
            lua = runtime("build='"+build+"';Automaton.dbs.ShaguStance={profile={disabled=true,personal='keep'}}")
            self.assertEqual(lua.eval("M.isTurtle"), turtle)
            lua.execute("assert(M.db.profile.disabled and M.db.profile.personal=='keep');assert(M._options==M.options)")

    def test_repeated_enable_and_disable_reuse_tooltip_and_restore_hooks(self):
        lua = runtime()
        lua.execute(r'''
local original=CastSpellByName
M:OnEnable();local wrapped=CastSpellByName;local tip=M.tip
M:OnEnable();assert(CastSpellByName==wrapped and #frames==1)
M:OnDisable();assert(CastSpellByName==original and not M.runtimeActive and tip.hidden)
M:OnEnable();assert(M.tip==tip and #frames==1 and M.runtimeActive)
M:OnDisable();M:OnDisable();assert(CastSpellByName==original)
''')

    def test_owner_handoff_routes_only_one_event_and_clears_pending(self):
        lua = runtime("class='WARRIOR'")
        lua.execute(r'''
local syncs=0;pfUI.autoshift={SyncOwnership=function()syncs=syncs+1 end}
M:OnEnable();assert(syncs==1 and M.events.UI_ERROR_MESSAGE)
CastSpellByName('Charge');assert(M:HandleError('Requires Battle Stance.'))
local owner={};M:SetMovementOwner(owner)
assert(not M.events.UI_ERROR_MESSAGE and M.events.PLAYER_LEAVING_WORLD and not M.pendingStance)
CastSpellByName('Charge');M:HandleError('Requires Battle Stance.');assert(M.pendingStance)
M:SetMovementOwner(nil);assert(M.events.UI_ERROR_MESSAGE and not M.pendingStance)
M:OnDisable();assert(syncs==2 and not next(M.events) and not M:HandleError('Requires Battle Stance.'))
''')

    def test_error_selects_one_learned_castable_form_on_same_retry(self):
        lua = runtime("class='WARRIOR';forms={{name='Defensive Stance',castable=1},{name='Battle Stance',castable=1}}")
        lua.execute(r'''
M:OnEnable();castError='Requires Battle Stance, Defensive Stance.'
CastSpellByName('Charge');assert(#shifts==0)
castError=nil;CastSpellByName('Charge');assert(#shifts==1 and shifts[1]==1)
CastSpellByName('Charge');assert(#shifts==1)
assert(#calls==3)
''')

    def test_active_allowed_form_is_never_toggled_off(self):
        lua = runtime("class='WARRIOR';forms={{name='Battle Stance',castable=1},{name='Defensive Stance',active=1,castable=1}}")
        lua.execute("M:OnEnable();CastSpellByName('Attack');M:HandleError('Requires Battle Stance, Defensive Stance.');CastSpellByName('Attack');assert(#shifts==0)")

    def test_unlearned_or_uncastable_forms_do_not_fire(self):
        lua = runtime("class='WARRIOR';forms={{name='Battle Stance',castable=nil}}")
        lua.execute("M:OnEnable();CastSpellByName('Charge');M:HandleError('Requires Battle Stance, Berserker Stance.');CastSpellByName('Charge');assert(#shifts==0)")

    def test_error_is_not_reused_for_another_action_or_after_expiry(self):
        lua = runtime("class='WARRIOR';forms={{name='Battle Stance',castable=1}}")
        lua.execute(r'''
M:OnEnable();assert(not M:HandleError('Requires Battle Stance.'))
CastSpellByName('Charge');M:HandleError('Requires Battle Stance.');CastSpellByName('Shield Wall');assert(#shifts==0)
CastSpellByName('Charge');M:HandleError('Requires Battle Stance.');now=now+6;CastSpellByName('Charge');assert(#shifts==0)
CastSpellByName('Charge');M:HandleError('Requires Battle Stance.');assert(not M:HandleError('Out of range'));CastSpellByName('Charge');assert(#shifts==0)
''')

    def test_error_pattern_escapes_localized_punctuation_and_trims_aliases(self):
        lua = runtime("SPELL_FAILED_ONLY_SHAPESHIFT='[需要: %s]';forms={{name='猎豹形态',castable=1}}")
        lua.execute("M:OnEnable();CastSpellByName('Attack');assert(not M:HandleError('需要: 豹形态'));assert(M:HandleError('[需要:  豹形态 ]'));CastSpellByName('Attack');assert(shifts[1]==1)")

    def test_dynamic_druid_form_indices_and_active_form_are_respected(self):
        lua = runtime("spells={{name='撕碎',lines={'撕碎','40 Energy','需要豹形态'},texture='catspell'}};forms={{name='猎豹形态',castable=1},{name='熊形态',castable=1}}")
        lua.execute("M:OnEnable();CastSpell(1,'spell');assert(shifts[1]==1);forms[1].active=1;power=3;CastSpell(1,'spell');assert(#shifts==1)")

    def test_druid_current_spell_decision_wins_over_previous_error(self):
        lua = runtime("spells={{name='撕碎',lines={'撕碎','40 Energy','需要豹形态'}}};forms={{name='猎豹形态',castable=1},{name='熊形态',castable=1}}")
        lua.execute("M:OnEnable();CastSpellByName('撕碎');M:HandleError('Requires 熊形态.');shifts={};now=now+1.1;CastSpellByName('撕碎');assert(#shifts==1 and shifts[1]==1)")

    def test_mana_spell_unshifts_once_with_turtle_exceptions_preserved(self):
        for name, power, expected in (("治疗之触", 1, 1), ("自然之握", 1, 0), ("自然之握", 3, 1), ("重整", 3, 0)):
            lua = runtime("power="+str(power)+";spells={{name='"+name+"',lines={'"+name+"','100 Mana'}}};forms={{name='熊形态',active=1,castable=1}}")
            lua.execute("M:OnEnable();CastSpellByName('"+name+"');assert(#shifts=="+str(expected)+")")
        lua = runtime("build='1.12.1';power=1;spells={{name='自然之握',lines={'自然之握','100 Mana'}}};forms={{name='熊形态',active=1,castable=1}}")
        lua.execute("M:OnEnable();CastSpellByName('自然之握');assert(#shifts==1)")

    def test_rank_selfcast_book_and_multiple_return_values_are_unchanged(self):
        lua = runtime("spells={{name='治疗之触',rank='等级 1',lines={'治疗之触','10 Mana'}},{name='治疗之触',rank='等级 2',lines={'治疗之触','20 Mana'}}};petspells={{name='Bite'}}")
        lua.execute(r'''
M:OnEnable();local a,b,c=CastSpellByName('治疗之触(等级 1)',true)
assert(a=='name-return' and b==nil and c==4 and calls[1][2]=='治疗之触(等级 1)' and calls[1][3]==true)
a,b,c=CastSpell(1,'pet');assert(a=='spell-return' and b==nil and c==3 and calls[2][3]=='pet')
local old=M.CheckAndSwitchDruidForm;M.CheckAndSwitchDruidForm=function(self,name,id,book)assert(id==1);return false end
CastSpellByName('治疗之触(等级 1)',false);M.CheckAndSwitchDruidForm=old
''')

    def test_macro_item_and_action_arguments_remain_native(self):
        lua = runtime("power=1;spells={{name='治疗之触',texture='heal',lines={'治疗之触','10 Mana'}}};forms={{name='熊形态',active=1,castable=1}};actions={[1]={macro='My macro',texture='heal',name='治疗之触'},[2]={texture='item',name='治疗之触'},[3]={texture='heal',name='治疗之触'}}")
        lua.execute(r'''
M:OnEnable();local a,b,c=UseAction(1,1,true);assert(#shifts==0 and a=='action-return' and b==nil and c==5)
UseAction(2,0,false);assert(#shifts==0)
UseAction(3,1,true);assert(#shifts==1 and calls[3][2]==3 and calls[3][3]==1 and calls[3][4]==true)
''')

    def test_missing_tooltip_lines_and_spell_cache_are_harmless(self):
        lua = runtime("power=1;spells={{name='治疗之触'}};forms={{name='熊形态',active=1,castable=1}}")
        lua.execute("M:OnEnable();local tip=M.tip;M.tip=nil;CastSpellByName('治疗之触');M.tip=tip;CastSpellByName('unknown');assert(#shifts==0 and #calls==2)")

    def test_real_acehook_later_wrappers_survive_disable_and_reenable(self):
        lua = runtime("class='WARRIOR';forms={{name='Battle Stance',castable=1}}")
        lua.execute(r'''
M:OnEnable();local base=CastSpellByName;local outerCount=0
CastSpellByName=function(name,selfcast)outerCount=outerCount+1;return base(name,selfcast)end
local outer=CastSpellByName
M:OnDisable();CastSpellByName('Charge',true);assert(outerCount==1 and #calls==1 and not M.lastAction)
M:OnEnable();assert(CastSpellByName==outer)
CastSpellByName('Charge',true);M:HandleError('Requires Battle Stance.');CastSpellByName('Charge',true)
assert(outerCount==3 and #calls==3 and #shifts==1)
M:OnDisable();CastSpellByName('Charge');assert(outerCount==4 and #calls==4 and #shifts==1)
''')

    def test_channeled_mana_cost_suffix_retains_original_unshift(self):
        lua = runtime("power=1;spells={{name='治疗之触',lines={'治疗之触','100 Mana, plus 10 per sec'}}};forms={{name='熊形态',active=1,castable=1}}")
        lua.execute("M:OnEnable();CastSpellByName('治疗之触');assert(#shifts==1)")

    def test_pending_form_state_prevents_double_toggle_until_feedback_or_timeout(self):
        lua = runtime("power=1;spells={{name='治疗之触',lines={'治疗之触','10 Mana'}}};forms={{name='熊形态',active=1,castable=1}}")
        lua.execute(r'''
M:OnEnable();CastSpellByName('治疗之触');CastSpellByName('治疗之触');assert(#shifts==1 and #calls==2)
forms[1].active=nil;power=0;CastSpellByName('治疗之触');assert(#shifts==1)
forms[1].active=1;power=1;now=now+1.1;CastSpellByName('治疗之触');assert(#shifts==2)
''')

    def test_form_callback_error_does_not_create_a_new_spell_requirement(self):
        lua = runtime("class='WARRIOR';forms={{name='Battle Stance',castable=1},{name='Defensive Stance',castable=1}}")
        lua.execute(r'''
M:OnEnable();CastSpellByName('Charge');M:HandleError('Requires Battle Stance.')
shiftCallback=function()assert(not M:HandleError('Requires Defensive Stance.'))end
CastSpellByName('Charge');assert(#shifts==1 and not M.pendingStance)
CastSpellByName('Charge');assert(#shifts==1)
M.formRequest=nil;shiftCallback=function()error('native failure')end
local ok=pcall(function()M:ChooseForm('Battle Stance')end);assert(not ok and not M.switchingForm and not M.formRequest)
''')

    def test_non_druid_name_casts_do_not_scan_spellbook(self):
        lua = runtime("class='WARRIOR'")
        lua.execute("M:OnEnable();GetSpellName=function()error('warrior name cast should not scan spellbook')end;CastSpellByName('Charge');assert(#calls==1)")

    def test_world_leave_and_disable_discard_old_error(self):
        lua = runtime("class='WARRIOR';forms={{name='Battle Stance',castable=1}}")
        lua.execute("M:OnEnable();CastSpellByName('Charge');M:HandleError('Requires Battle Stance.');M:ClearPending();CastSpellByName('Charge');assert(#shifts==0);M:HandleError('Requires Battle Stance.');M:OnDisable();M:OnEnable();CastSpellByName('Charge');assert(#shifts==0)")


if __name__ == "__main__":
    unittest.main(verbosity=2)
