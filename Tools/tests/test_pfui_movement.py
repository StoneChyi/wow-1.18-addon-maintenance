"""Real movement engines at the legacy client boundary; offline, not game acceptance."""
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

MOCK = r'''
string.gfind=string.gmatch;string.gmatch=nil;string.match=nil;select=nil
now=1; class='WARRIOR'; combat=false; casts={}; cancelled={}; stands=0; toggles=0
buffs={}; forms={}; spells={}; objects={}; talents=0; power=0
C={global={autodismount='1'},automation={enabled='1'}};pfUI_config=C
BOOKTYPE_SPELL='spell';MANA_COST='%d Mana';SPELL_FAILED_ONLY_SHAPESHIFT='Requires %s'
for _,key in ipairs({'SPELL_FAILED_NOT_MOUNTED','ERR_ATTACK_MOUNTED','ERR_TAXIPLAYERALREADYMOUNTED',
 'SPELL_FAILED_NOT_SHAPESHIFT','SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED','SPELL_NOT_SHAPESHIFTED',
 'SPELL_NOT_SHAPESHIFTED_NOSPACE','ERR_CANT_INTERACT_SHAPESHIFTED','ERR_NOT_WHILE_SHAPESHIFTED',
 'ERR_NO_ITEMS_WHILE_SHAPESHIFTED','ERR_TAXIPLAYERSHAPESHIFTED','ERR_MOUNT_SHAPESHIFTED',
 'ERR_EMBLEMERROR_NOTABARDGEOSET','SPELL_FAILED_NOT_STANDING','ERR_CANTATTACK_NOTSTANDING',
 'ERR_LOOT_NOTSTANDING','ERR_TAXINOTSTANDING'}) do _G[key]=key end
function GetTime() return now end
function GetLocale() return 'enUS' end
function GetBuildInfo() return '1.18.0' end
function UnitClass() return class,class end
function UnitPowerType() return power end
function UnitAffectingCombat() return combat end
function GetTalentInfo() return nil,nil,nil,nil,talents end
function GetPlayerBuffTexture(i) return buffs[i] and buffs[i].texture end
function GetNumShapeshiftForms() return table.getn(forms) end
function GetShapeshiftFormInfo(i) local f=forms[i];if f then local castable=f.castable;if castable==nil then castable=true end;return f.texture,f.name,f.active,castable end end
function GetSpellName(i) return spells[i] and spells[i].name end
function GetSpellTexture(i) return spells[i] and spells[i].texture end
function GetNumSpellTabs() return 1 end
function GetSpellTabInfo() return 'Spells',nil,0,table.getn(spells) end
function CastSpellByName(name,selfcast) table.insert(casts,{kind='name',name=name,selfcast=selfcast}) end
function CastSpell(index,book) table.insert(casts,{kind='index',index=index,book=book}) end
function UseAction(slot,check,selfcast) table.insert(casts,{kind='action',slot=slot,check=check,selfcast=selfcast}) end
function CastShapeshiftForm(i) table.insert(casts,{kind='form',index=i}) end
function GetActionText() return nil end
function CancelPlayerBuff(i) table.insert(cancelled,i) end
function SitOrStand() toggles=toggles+1 end
function DoEmote(name) assert(name=='stand');stands=stands+1 end
UIErrorsFrame={Clear=function()end}
function strsplit(delim,subject)
 local values={};for value in string.gfind(subject,'[^'..delim..']+') do table.insert(values,value) end
 return unpack(values)
end
strfind=string.find
mockMethods={}
function newObject(kind,name,parent)
 local object=setmetatable({kind=kind,name=name,parent=parent,events={},scripts={},shown=false},{__index=mockMethods})
 table.insert(objects,object);if name then _G[name]=object end;return object
end
function mockMethods:RegisterEvent(e) self.events[e]=true end
function mockMethods:UnregisterEvent(e) self.events[e]=nil end
function mockMethods:UnregisterAllEvents() self.events={} end
function mockMethods:SetScript(e,fn) self.scripts[e]=fn end
function mockMethods:GetScript(e) return self.scripts[e] end
function mockMethods:GetName() return self.name end
function mockMethods:GetText() return self.text end
function mockMethods:SetOwner(owner,anchor) self.owner,self.anchor=owner,anchor end
function mockMethods:Hide() self.shown=false end
function mockMethods:Show() self.shown=true end
function mockMethods:IsShown() return self.shown end
function mockMethods:ClearLines()
 for i=1,8 do local line=_G[(self.name or '')..'TextLeft'..i];if line then line:SetText('') end end
 self.tipLines={}
end
function mockMethods:SetPlayerBuff(i)
 self.tipLines=buffs[i] and buffs[i].lines or {}
 for j=1,8 do local line=_G[(self.name or '')..'TextLeft'..j];if line then line:SetText(self.tipLines[j] or '') end end
end
function mockMethods:SetSpell(i)
 self:ClearLines();local s=spells[i]
 for j,line in ipairs(s and s.lines or {}) do _G[self.name..'TextLeft'..j]:SetText(line) end
end
function mockMethods:SetAction(i) self:ClearLines();_G[self.name..'TextLeft1']:SetText('action'..i) end
function mockMethods:Find(pattern)
 for _,line in ipairs(self.tipLines or {}) do if string.find(line,pattern) then return true end end
end
function CreateFrame(kind,name,parent,template)
 local f=newObject(kind,name,parent)
 if kind=='GameTooltip' then
  assert(template=='GameTooltipTemplate');assert(name)
  for j=1,8 do f:CreateFontString(name..'TextLeft'..j,nil,'GameFontNormal') end
 end
 return f
end
UIParent=newObject('Frame','UIParent')
libtipscan={GetScanner=function(_,name) return CreateFrame('GameTooltip','scanner_'..name,UIParent,'GameTooltipTemplate') end}
pfUI={RegisterModule=function(_,name,version,fn) fn() end}
function AceLibrary(name)
 assert(name=='AceLocale-2.2')
 return {new=function() return setmetatable({RegisterTranslations=function()end},{__index=function(_,k)return k end}) end}
end
local methods={}
function methods:RegisterEvent(e,method) self.events[e]=method or e end
function methods:UnregisterEvent(e) self.events[e]=nil end
function methods:UnregisterAllEvents() self.events={} end
function methods:RegisterOptions(options) self._options=options end
function methods:Hook(name)
 if self.hooks[name] then return end
 self.hooks[name]=_G[name];local module=self
 _G[name]=function(...) return module[name](module,unpack(arg)) end
end
function methods:UnhookAll()
 for name,fn in pairs(self.hooks) do _G[name]=fn end;self.hooks={}
end
Automaton={modules={},db={char={disabledModules={}},raw={disabledModules={Default={}}}},namespaces={}}
function Automaton:NewModule(name)
 local m=setmetatable({name=name,events={},hooks={}},{__index=methods});self.modules[name]=m;return m
end
function Automaton:AcquireDBNamespace(name)
 if not self.namespaces[name] then self.namespaces[name]={profile={}} end;return self.namespaces[name]
end
function Automaton:RegisterDefaults(name,scope,defaults)
 local target=self:AcquireDBNamespace(name)[scope]
 for k,v in pairs(defaults) do if target[k]==nil then target[k]=v end end
end
function Automaton:SetDisabledAsDefault() end
function Automaton:IsModuleActive(name) return not self.db.char.disabledModules[name] end
function setActive(name,active)
 local m=Automaton.modules[name]
 -- Actual Core commits saved state AFTER the lifecycle callback.
 if active then m:OnEnable() else m:OnDisable() end
 Automaton.db.char.disabledModules[name]=not active or nil
end
function initModules()
 for _,name in ipairs({'Dismount','Stand','ShaguStance'}) do
  local m=Automaton.modules[name]
  if m then m:OnInitialize();if Automaton:IsModuleActive(name) then m:OnEnable() end end
 end
end
function emit(e,msg,oldFirst)
 local function old()
  for _,name in ipairs({'Dismount','Stand','ShaguStance'}) do
   local m=Automaton and Automaton.modules[name];local method=m and m.events[e]
   if method then event=e;arg1=msg;m[method](m,msg) end
  end
 end
 local function native()
  for _,f in ipairs(objects) do if f.events[e] and f.scripts.OnEvent then
   local prior=this;this=f;event=e;arg1=msg;f.scripts.OnEvent();this=prior
  end end
 end
 if oldFirst then old();native() else native();old() end
 event=nil;arg1=nil
end
function mount() buffs[0]={texture='mount',lines={'Horse','Increases speed by 100%'}} end
function bear() buffs[1]={texture='Interface\\Icons\\Ability_Racial_BearForm',lines={'Bear'}} end
function sync(managed)
 C.automation.enabled=managed and '1' or '0';pfUI.autoshift:SyncOwnership(managed)
end
'''

class Movement(unittest.TestCase):
    def load(self, rel):
        self.lua.execute((ROOT/rel).read_text(encoding='utf-8-sig'))

    def fresh(self, setup='', *, managed=True, native_first=False, stance=True):
        self.lua=LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute(MOCK)
        contract=self.lua.execute((ROOT/'Tools/tests/wow112_fontstring_mock.lua').read_text(encoding='utf-8'))
        contract(self.lua.globals().mockMethods,self.lua.globals().newObject)
        self.lua.execute(setup)
        if native_first: self.load('Interface/AddOns/pfUI/modules/autoshift.lua')
        for name,present in [('Stand',True),('ShaguStance',stance)]:
            if present: self.load(f'Interface/AddOns/Automatonex/Modules/{name}.lua')
        self.lua.execute('initModules()')
        if not native_first: self.load('Interface/AddOns/pfUI/modules/autoshift.lua')
        self.lua.execute(f'sync({str(managed).lower()})')

    def run_lua(self, code): self.lua.execute(code)

    def test_current_toc_keeps_optional_dismount_unloaded(self):
        toc=(ROOT/'Interface/AddOns/Automatonex/Automatonex.toc').read_text(encoding='utf-8-sig')
        self.assertNotIn('Modules\\Dismount.lua',toc)
        self.fresh()
        self.run_lua("emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_STANDING);assert(stands==1 and toggles==0)")

    def test_stand_once_both_dispatch_orders_and_duplicate_info(self):
        for order in ('true','false'):
            with self.subTest(order=order):
                self.fresh()
                self.run_lua(f"emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_STANDING,{order});emit('UI_INFO_MESSAGE',SPELL_FAILED_NOT_STANDING,{order});assert(stands==1 and toggles==0);now=now+.3;emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_STANDING);assert(stands==2)")

    def test_extra_stand_errors_require_original_module_enabled(self):
        self.fresh()
        self.run_lua("emit('UI_INFO_MESSAGE',ERR_LOOT_NOTSTANDING);assert(stands==1);setActive('Stand',false);now=now+1;emit('UI_ERROR_MESSAGE',ERR_CANTATTACK_NOTSTANDING);assert(stands==1);emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_STANDING);assert(stands==2)")

    def test_original_mount_switch_remains_live(self):
        self.fresh()
        self.run_lua("C.global.autodismount='0';mount();emit('UI_ERROR_MESSAGE',ERR_ATTACK_MOUNTED);assert(table.getn(cancelled)==0);C.global.autodismount='1';emit('UI_ERROR_MESSAGE',ERR_ATTACK_MOUNTED);assert(table.getn(cancelled)==1)")

    def test_mount_toggle_does_not_disable_native_form_cancel(self):
        self.fresh("C.global.autodismount='0'")
        self.run_lua("bear();emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_SHAPESHIFT);assert(table.getn(cancelled)==1 and cancelled[1]==1)")

    def test_combat_npc_exception_survives(self):
        self.fresh()
        self.run_lua("bear();combat=true;emit('UI_ERROR_MESSAGE',ERR_CANT_INTERACT_SHAPESHIFTED);assert(table.getn(cancelled)==0);combat=false;emit('UI_ERROR_MESSAGE',ERR_CANT_INTERACT_SHAPESHIFTED);assert(table.getn(cancelled)==1)")

    def test_shadow_form_waits_behind_mount(self):
        self.fresh()
        self.run_lua("buffs[0]={texture='Interface\\\\Icons\\\\Spell_Shadow_Shadowform',lines={'Shadow'}};buffs[3]={texture='mount',lines={'Horse','Increases speed by 100%'}};emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_SHAPESHIFT);assert(table.getn(cancelled)==1 and cancelled[1]==3)")

    def test_moonkin_icon_requires_druid_talent(self):
        self.fresh("class='DRUID'")
        self.run_lua("buffs[0]={texture='Interface\\\\Icons\\\\Spell_Nature_ForceOfNature',lines={'Buff'}};emit('PLAYER_ENTERING_WORLD');emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_SHAPESHIFT);assert(table.getn(cancelled)==0);talents=1;emit('UNIT_NAME_UPDATE');emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_SHAPESHIFT);assert(table.getn(cancelled)==1)")

    def test_unloaded_taxi_extension_is_not_activated(self):
        self.fresh()
        self.run_lua("mount();emit('TAXIMAP_OPENED');assert(table.getn(cancelled)==0)")

    def test_handoff_preserves_saved_flags_both_load_orders(self):
        for first in (True,False):
            with self.subTest(native_first=first):
                self.fresh(native_first=first)
                self.run_lua("local flags=Automaton.db.char.disabledModules;sync(false);assert(flags==Automaton.db.char.disabledModules and not flags.Stand);emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_STANDING,true);assert(stands==1 and toggles==0);sync(true);now=now+1;emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_STANDING,false);assert(stands==2 and toggles==0);setActive('Stand',false);sync(false);assert(flags.Stand==true)")

    def test_stance_owner_prevents_duplicate_native_cast(self):
        self.fresh("forms={{name='Battle Stance'},{name='Defensive Stance'}};spells={{name='Battle Stance'},{name='Defensive Stance'}}")
        self.run_lua("CastSpellByName('Charge(Rank 1)',true);emit('UI_ERROR_MESSAGE','Requires Battle Stance, Defensive Stance');assert(table.getn(casts)==1);CastSpellByName('Charge(Rank 1)',true);assert(table.getn(casts)==3 and casts[2].kind=='form' and casts[3].name=='Charge(Rank 1)' and casts[3].selfcast==true)")

    def test_native_stance_fallback_chooses_one_known_form(self):
        self.fresh("Automaton.db.char.disabledModules.ShaguStance=true;forms={{name='Defensive Stance'}};spells={{name='Defensive Stance'}}")
        self.run_lua("emit('UI_ERROR_MESSAGE','Requires Battle Stance, Defensive Stance');assert(table.getn(casts)==1 and (casts[1].name=='Defensive Stance' or (casts[1].kind=='form' and casts[1].index==1)))")

    def test_unknown_errors_never_trigger_actions(self):
        self.fresh()
        self.run_lua("mount();bear();emit('UI_ERROR_MESSAGE','other failure');emit('UI_INFO_MESSAGE',nil);assert(stands==0 and toggles==0 and table.getn(casts)==0 and table.getn(cancelled)==0)")

    def test_native_stance_prefers_already_active_allowed_form(self):
        self.fresh("Automaton.db.char.disabledModules.ShaguStance=true;forms={{name='Battle Stance'},{name='Defensive Stance',active=1}}")
        self.run_lua("emit('UI_ERROR_MESSAGE','Requires Battle Stance, Defensive Stance');assert(table.getn(casts)==0)")

    def test_native_stance_skips_uncastable_and_zero_is_inactive(self):
        self.fresh("Automaton.db.char.disabledModules.ShaguStance=true;forms={{name='Battle Stance',castable=0},{name='Defensive Stance',active=0}}")
        self.run_lua("emit('UI_ERROR_MESSAGE','Requires Battle Stance, Defensive Stance');assert(table.getn(casts)==1 and casts[1].name=='Defensive Stance')")

    def test_native_localized_template_is_literal_and_anchored(self):
        self.fresh("Automaton.db.char.disabledModules.ShaguStance=true;SPELL_FAILED_ONLY_SHAPESHIFT='Requires (%s).';forms={{name='Defensive Stance'}}")
        self.run_lua("emit('UI_ERROR_MESSAGE','Other Requires (Defensive Stance).');assert(table.getn(casts)==0);emit('UI_ERROR_MESSAGE','Requires (Defensive Stance).');assert(table.getn(casts)==1 and casts[1].name=='Defensive Stance')")

    def test_enabled_runtime_not_stale_saved_flag_drives_ownership(self):
        self.fresh("Automaton.db.char.disabledModules.Stand=true;Automaton.db.char.disabledModules.ShaguStance=true")
        self.run_lua("setActive('Stand',true);assert(Automaton.modules.Stand.runtimeActive and not Automaton.modules.Stand.events.UI_ERROR_MESSAGE);emit('UI_ERROR_MESSAGE',ERR_TAXINOTSTANDING);assert(stands==1);setActive('Stand',false);now=now+1;emit('UI_ERROR_MESSAGE',ERR_TAXINOTSTANDING);assert(stands==1);sync(false);setActive('Stand',true);assert(Automaton.modules.Stand.events.UI_ERROR_MESSAGE);emit('UI_INFO_MESSAGE',ERR_TAXINOTSTANDING);assert(stands==2)")

    def test_independent_stance_has_one_listener_and_retires_handoff_error(self):
        self.fresh("forms={{name='Battle Stance'}}",managed=False)
        self.run_lua("local stance=Automaton.modules.ShaguStance;assert(stance.events.UI_ERROR_MESSAGE);CastSpellByName('Charge');emit('UI_ERROR_MESSAGE','Requires Battle Stance');assert(table.getn(casts)==1);sync(true);assert(not stance.events.UI_ERROR_MESSAGE);CastSpellByName('Charge');assert(table.getn(casts)==2);emit('UI_ERROR_MESSAGE','Requires Battle Stance');setActive('ShaguStance',false);CastSpellByName('Other');assert(table.getn(casts)==3);emit('UI_ERROR_MESSAGE','Requires Battle Stance');assert(table.getn(casts)==4)")

    def test_pfui_baseline_survives_missing_engine_and_disabled_modules(self):
        self.fresh("Automaton.db.char.disabledModules.Stand=true;Automaton.db.char.disabledModules.ShaguStance=true")
        self.run_lua("Automaton=nil;sync(true);emit('UI_ERROR_MESSAGE',SPELL_FAILED_NOT_STANDING);assert(stands==1 and toggles==0);mount();emit('UI_ERROR_MESSAGE',ERR_ATTACK_MOUNTED);assert(table.getn(cancelled)==1)")

    def test_enabled_stance_with_no_failed_action_does_not_auto_cast(self):
        self.fresh("forms={{name='Battle Stance'}}")
        self.run_lua("emit('UI_ERROR_MESSAGE','Requires Battle Stance');CastSpellByName('Unrelated');assert(table.getn(casts)==1 and casts[1].name=='Unrelated')")

if __name__=='__main__': unittest.main(verbosity=2)
