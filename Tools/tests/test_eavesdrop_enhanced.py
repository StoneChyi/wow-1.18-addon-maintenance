"""Exercise the actual EavesDrop Nampower adapter in Lua 5.1.

These are offline event-contract tests, not in-game validation. This module
creates no FontStrings or other text controls. The stub never runs DLL code.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

SOURCE = ROOT / "Interface/AddOns/EavesDrop/enhanced.lua"
STUB = r'''
UIParent={}; getglobal=function(k)return _G[k]end
ParserLib_SELF=101; ParserLib_MELEE=102; ParserLib_DAMAGESHIELD=113
SPELL_SCHOOL0_CAP='Physical'; SPELL_SCHOOL1_CAP='Holy'; SPELL_SCHOOL2_CAP='Fire'
SPELL_SCHOOL3_CAP='Nature'; SPELL_SCHOOL4_CAP='Frost'; SPELL_SCHOOL5_CAP='Shadow'; SPELL_SCHOOL6_CAP='Arcane'
MANA='Mana'; RAGE='Rage'; FOCUS='Focus'; ENERGY='Energy'; HAPPINESS='Happiness'; HEALTH='Health'
version={4,6,1}; failEvent=nil
player='0x0000000000000001'; pet='0x0000000000000002'
enemy='0x0000000000000003'; friend='0x0000000000000004'
GetNampowerVersion=function()return unpack(version)end
GetUnitGUID=function(u)if u=='player' then return player elseif u=='pet' then return pet end end
UnitExists=function()return false end
UnitName=function(u)
 if u=='player' or u==player then return 'Me'
 elseif u=='pet' or u==pet then return 'SameName'
 elseif u==enemy then return 'SameName'
 elseif u==friend then return 'Friend' end
end
GetSpellRecField=function(id,field)
 if field=='name' then return 'Spell'..id elseif field=='spellIconID' then return 5 end
end
GetSpellIconTexture=function(id)return 'Icon'..id end
cvars={NP_EnableAutoAttackEvents='0',NP_EnableSpellHealEvents='0',NP_EnableSpellEnergizeEvents='0'}
setCalls={}
function cvarName(name)
 for key in pairs(cvars)do if string.lower(key)==string.lower(name)then return key end end
 return name
end
GetCVar=function(name)return cvars[cvarName(name)]end
SetCVar=function(name,value,scriptCVar)
 table.insert(setCalls,{name,value,scriptCVar})
 cvars[cvarName(name)]=tostring(value)
 if returnMode=='none' then return end
 if returnMode=='nil' then return nil,nil end
 return 'ok',nil,'tail',nil
end
function pack(...)return arg end
CreateFrame=function()
 local f={events={},scripts={}}
 function f:RegisterEvent(e)if failEvent==e then error('unsupported')end; self.events[e]=true end
 function f:UnregisterEvent(e)self.events[e]=nil end
 function f:UnregisterAllEvents()self.events={} end
 function f:IsEventRegistered(e)return self.events[e]end
 function f:SetScript(e,fn)self.scripts[e]=fn end
 return f
end
EavesDrop={db={profile={PET=true,DATASOURCE='auto'}},events={},active=true}
function EavesDrop:IsActive()return self.active end
function EavesDrop:RouteCombatEvent(info)table.insert(self.events,info)end
function send(...)EavesDrop:HandleEnhancedEvent(...)end
function last()return EavesDrop.events[#EavesDrop.events]end
'''

CASES = [
    ("current-version registration and self-heal deduplication", r'''
      assert(EavesDrop.enhancedCategories.spell and not EavesDrop.enhancedCategories.aura)
      assert(not EavesDrop.enhancedFrame.events.SPELL_HEAL_ON_SELF)
      assert(not EavesDrop.enhancedFrame.events.SPELL_ENERGIZE_ON_SELF)
      assert(not EavesDrop.enhancedFrame.events.UNIT_DIED)
      assert(next(EavesDrop.enhancedObserved)==nil and #setCalls==0)
    '''),
    ("spell damage, mitigation, critical, school and icon", r'''
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,100,'10,20,30',2,2,'0,0,0,0')
      assert(last().type=='hit' and last().source==ParserLib_SELF and last().amount==100)
      assert(last().amountAbsorb==10 and last().amountBlock==20 and last().amountResist==30)
      assert(last().isCrit and last().element=='Fire' and last().texture=='Icon5')
      assert(string.find(last().message,'100',1,true))
    '''),
    ("incoming damage from an enemy sharing the pet name", r'''
      send('SPELL_DAMAGE_EVENT_OTHER',player,enemy,42,55,'0,0,0',0,5,'0,0,0,3')
      assert(last().victim==ParserLib_SELF and last().sourceIsPet==false)
    '''),
    ("own pet GUID identity", r'''
      send('SPELL_DAMAGE_EVENT_OTHER',enemy,pet,42,12,'0,0,0',0,2,'0,0,0,0')
      assert(last().sourceIsPet and not last().victimIsPet)
    '''),
    ("unrelated combat is filtered", r'''
      send('SPELL_DAMAGE_EVENT_OTHER',friend,enemy,42,55,'0,0,0',0,5,'0,0,0,3')
      assert(#EavesDrop.events==0)
    '''),
    ("pet monitoring off filters pet-only events", r'''
      EavesDrop.db.profile.PET=false
      send('SPELL_DAMAGE_EVENT_OTHER',enemy,pet,42,12,'0,0,0',0,2,'0,0,0,0')
      assert(#EavesDrop.events==0)
    '''),
    ("melee critical/glancing and mitigation bits", r'''
      send('AUTO_ATTACK_OTHER',enemy,player,50,128+16384,1,1,3,4,5)
      assert(last().isCrit and last().isGlancing and not last().isCrushing)
      assert(last().amountBlock==3 and last().amountAbsorb==4 and last().amountResist==5)
    '''),
    ("melee misses and zero-damage absorption", r'''
      send('AUTO_ATTACK_SELF',player,enemy,0,16,0,1,0,0,0)
      assert(last().type=='miss' and last().missType=='miss')
      send('AUTO_ATTACK_SELF',player,enemy,0,32,1,1,0,40,0)
      assert(last().type=='miss' and last().missType=='absorb')
    '''),
    ("spell miss identity and enum", r'''
      send('SPELL_MISS_OTHER',enemy,player,42,7)
      assert(last().missType=='immune' and last().victim==ParserLib_SELF)
    '''),
    ("self-heal emitted once", r'''
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      send('SPELL_HEAL_ON_SELF',player,player,42,30,1,0)
      assert(#EavesDrop.events==1 and last().type=='heal' and last().isCrit)
      assert(last().source==ParserLib_SELF and last().victim==ParserLib_SELF)
    '''),
    ("incoming periodic healing", r'''
      send('SPELL_HEAL_BY_OTHER',player,friend,42,31,0,1)
      assert(last().type=='heal' and last().isHoT and last().victim==ParserLib_SELF)
    '''),
    ("mana and unsigned health energize", r'''
      send('SPELL_ENERGIZE_BY_OTHER',player,friend,42,0,40,1)
      assert(last().amount==40 and last().attribute=='Mana' and last().isPeriodic)
      send('SPELL_ENERGIZE_BY_SELF',player,player,42,4294967294,41,0)
      assert(last().powerType==-2 and last().attribute=='Health')
    '''),
    ("damage shield keeps legacy to avoid first-event duplication", r'''
      send('DAMAGE_SHIELD_SELF',player,enemy,25,3)
      assert(#EavesDrop.events==0 and not EavesDrop.enhancedFrame.events.DAMAGE_SHIELD_SELF)
      assert(not EavesDrop:ShouldSuppressLegacy({type='hit',skill=ParserLib_DAMAGESHIELD}))
    '''),
    ("environmental damage keeps legacy to avoid first-event duplication", r'''
      send('ENVIRONMENTAL_DMG_SELF',player,2,20,3,4)
      assert(#EavesDrop.events==0 and not EavesDrop.enhancedFrame.events.ENVIRONMENTAL_DMG_SELF)
      assert(not EavesDrop:ShouldSuppressLegacy({type='environment'}))
    '''),
    ("aura adds, stack changes and expiration retain legacy ordering", r'''
      send('DEBUFF_ADDED_SELF',player,1,42,3,60,35,0)
      send('DEBUFF_REMOVED_SELF',player,1,42,2,60,35,2)
      send('DEBUFF_REMOVED_SELF',player,1,42,0,60,35,1)
      assert(#EavesDrop.events==0 and not EavesDrop.enhancedFrame.events.DEBUFF_ADDED_SELF)
      assert(not EavesDrop:ShouldSuppressLegacy({type='debuff',victim=ParserLib_SELF}))
      assert(not EavesDrop:ShouldSuppressLegacy({type='fade',victim=ParserLib_SELF}))
    '''),
    ("legacy suppression is strictly category based", r'''
      for _,t in ipairs({'hit','heal','gain'})do
        assert(not EavesDrop:ShouldSuppressLegacy({type=t,skill='Spell'}))
      end
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,10,'0,0,0',0,2,'0,0,0,3')
      send('AUTO_ATTACK_SELF',player,enemy,10,0,1,1,0,0,0)
      send('DAMAGE_SHIELD_SELF',player,enemy,10,3)
      send('SPELL_HEAL_BY_SELF',player,player,42,10,0,0)
      send('SPELL_ENERGIZE_BY_SELF',player,player,42,0,10,0)
      send('ENVIRONMENTAL_DMG_SELF',player,2,10,0,0)
      for _,t in ipairs({'hit','heal','gain'})do
        assert(EavesDrop:ShouldSuppressLegacy({type=t,skill='Spell'}))
      end
      assert(EavesDrop:ShouldSuppressLegacy({type='hit',skill=ParserLib_MELEE}))
      assert(not EavesDrop:ShouldSuppressLegacy({type='hit',skill=ParserLib_DAMAGESHIELD}))
      assert(not EavesDrop:ShouldSuppressLegacy({type='environment'}))
      assert(not EavesDrop:ShouldSuppressLegacy({type='drain',skill='Spell'}))
      assert(not EavesDrop:ShouldSuppressLegacy({type='leech',skill='Spell'}))
      assert(not EavesDrop:ShouldSuppressLegacy({type='death'}))
      assert(not EavesDrop:ShouldSuppressLegacy({type='hit',skill='Spell',enhanced=true}))
    '''),
    ("one failed event rolls back its entire category only", r'''
      failEvent='SPELL_HEAL_BY_OTHER'; EavesDrop:StartEnhancedEvents()
      assert(not EavesDrop.enhancedCategories.heal and EavesDrop.enhancedCategories.spell)
      assert(not EavesDrop.enhancedFrame.events.SPELL_HEAL_BY_SELF)
      assert(not EavesDrop:ShouldSuppressLegacy({type='heal'}))
    '''),
    ("4.5 retains legacy aura signature", r'''
      version={4,5,0}; EavesDrop:StartEnhancedEvents()
      assert(EavesDrop.enhancedCategories.heal and not EavesDrop.enhancedCategories.aura)
      assert(not EavesDrop:ShouldSuppressLegacy({type='buff',victim=ParserLib_SELF}))
    '''),
    ("old DLL and explicit legacy setting", r'''
      version={3,9,0}; EavesDrop:StartEnhancedEvents()
      assert(not EavesDrop.enhancedCategories.spell)
      version={4,6,1}; EavesDrop.db.profile.DATASOURCE='legacy'; EavesDrop:StartEnhancedEvents()
      assert(not EavesDrop.enhancedCategories.spell)
    '''),
    ("stop and restart are idempotent", r'''
      EavesDrop:StartEnhancedEvents(); EavesDrop:StartEnhancedEvents(); EavesDrop:StopEnhancedEvents()
      assert(next(EavesDrop.enhancedFrame.events)==nil and next(EavesDrop.enhancedCategories)==nil)
      EavesDrop:StartEnhancedEvents(); assert(EavesDrop.enhancedCategories.heal)
    '''),
    ("missing APIs or player GUID fall back", r'''
      GetNampowerVersion=nil; EavesDrop:StartEnhancedEvents()
      assert(next(EavesDrop.enhancedCategories)==nil)
      GetNampowerVersion=function()return 4,6,1 end
      GetUnitGUID=function()return nil end
      EavesDrop:StartEnhancedEvents()
      assert(next(EavesDrop.enhancedCategories)==nil and EavesDrop.enhancedNeedsRetry)
      GetUnitGUID=function(u)if u=='player' then return player end end
      EavesDrop:StartEnhancedEvents(); assert(not EavesDrop.enhancedNeedsRetry)
      EavesDrop:StopEnhancedEvents(); assert(not EavesDrop.enhancedNeedsRetry)
    '''),
    ("disabled addon rejects pending events", r'''
      EavesDrop.active=false
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(#EavesDrop.events==0)
    '''),
    ("possible percentage DoT is never treated as hit points", r'''
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,43,100,'0,0,0',0,5,'0,0,0,3')
      EavesDrop.events={}
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,5,'0,0,0',0,5,'0,0,0,89')
      assert(#EavesDrop.events==0)
      assert(not EavesDrop:ShouldSuppressLegacy({type='hit',skill='Spell42'}))
      assert(EavesDrop:ShouldSuppressLegacy({type='hit',skill='Spell43'}))
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,100,'0,0,0',0,5,'0,0,0,3')
      assert(#EavesDrop.events==0)
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,43,100,'0,0,0',0,5,'0,0,0,3')
      assert(#EavesDrop.events==1 and last().amount==100)
    '''),
    ("unknown percentage spell name safely falls back all spell damage", r'''
      GetSpellRecField=nil
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,5,'0,0,0',0,5,'0,0,0,89')
      assert(#EavesDrop.events==0 and not EavesDrop.enhancedCategories.spell)
      assert(not EavesDrop:ShouldSuppressLegacy({type='hit',skill='UnknownSpell'}))
      assert(EavesDrop.enhancedCategories.heal)
    '''),
    ("missing name/icon retain ID for later icon fallback", r'''
      GetSpellRecField=nil
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,5,'0,0,0',0,5,'0,0,0,3')
      assert(last().skill=='#42' and last().texture==nil)
    '''),
    ("legacy 1.12 global event dispatch", r'''
      event='SPELL_DAMAGE_EVENT_OTHER'; arg1=player; arg2=enemy; arg3=42; arg4=10
      arg5='0,0,0'; arg6=0; arg7=2; arg8='0,0,0,3'
      EavesDrop.enhancedFrame.scripts.OnEvent()
      assert(#EavesDrop.events==1 and last().victim==ParserLib_SELF)
    '''),
    ("first received enhanced event suppresses its following text record", r'''
      local legacy={type='heal',skill='Spell42',amount=30}
      assert(not EavesDrop:ShouldSuppressLegacy(legacy))
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      if not EavesDrop:ShouldSuppressLegacy(legacy) then table.insert(EavesDrop.events,legacy) end
      assert(#EavesDrop.events==1 and EavesDrop.enhancedObserved.heal)
    '''),
    ("registered event without actual samples leaves legacy enabled", r'''
      assert(EavesDrop.enhancedCategories.melee and not EavesDrop.enhancedObserved.melee)
      assert(not EavesDrop:ShouldSuppressLegacy({type='hit',skill=ParserLib_MELEE}))
      send('SPELL_DAMAGE_EVENT_OTHER',friend,enemy,42,10,'0,0,0',0,2,'0,0,0,3')
      assert(not EavesDrop:ShouldSuppressLegacy({type='hit',skill='Spell42'}))
    '''),
    ("CVar initial zero does not override registration's internal enable", r'''
      assert(GetCVar('NP_EnableSpellHealEvents')=='0')
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(#EavesDrop.events==1 and EavesDrop:ShouldSuppressLegacy({type='heal'}))
    '''),
    ("same-value explicit CVar disable immediately restores legacy", r'''
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(EavesDrop:ShouldSuppressLegacy({type='heal'}))
      SetCVar('NP_EnableSpellHealEvents','0')
      assert(not EavesDrop:ShouldSuppressLegacy({type='heal'}))
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(#EavesDrop.events==1)
      SetCVar('NP_EnableSpellHealEvents','1')
      assert(not EavesDrop:ShouldSuppressLegacy({type='heal'}))
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(#EavesDrop.events==2 and EavesDrop:ShouldSuppressLegacy({type='heal'}))
    '''),
    ("CVar value transition outside the observer clears previous samples", r'''
      cvars.NP_EnableSpellHealEvents='1'; EavesDrop:StartEnhancedEvents()
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      cvars.NP_EnableSpellHealEvents='0'
      assert(not EavesDrop:ShouldSuppressLegacy({type='heal'}))
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(#EavesDrop.events==1)
    '''),
    ("observer preserves three arguments and all nil returns", r'''
      local returns=pack(SetCVar('NP_EnableSpellHealEvents','0','script-flag'))
      assert(returns.n==4 and returns[1]=='ok' and returns[2]==nil and returns[3]=='tail' and returns[4]==nil)
      assert(#setCalls==1 and setCalls[1][1]=='NP_EnableSpellHealEvents')
      assert(setCalls[1][2]=='0' and setCalls[1][3]=='script-flag')
      local unrelated=pack(SetCVar('Unrelated','value','unrelated-flag'))
      assert(unrelated.n==4 and unrelated[3]=='tail' and #setCalls==2)
      assert(setCalls[2][3]=='unrelated-flag')
    '''),
    ("observer chains below and above other addon hooks without stacking", r'''
      EavesDrop:StopEnhancedEvents()
      local native=SetCVar
      local lowerCount, upperCount=0,0
      local lower=function(a,b,c)lowerCount=lowerCount+1; return native(a,b,c)end
      SetCVar=lower
      EavesDrop:StartEnhancedEvents()
      local own=SetCVar
      local upper=function(a,b,c)upperCount=upperCount+1; return own(a,b,c)end
      SetCVar=upper
      for i=1,5 do
        EavesDrop:StopEnhancedEvents(); assert(SetCVar==upper)
        local out=pack(SetCVar('NP_EnableSpellHealEvents','0','upper'))
        assert(out.n==4 and out[3]=='tail')
        EavesDrop:StartEnhancedEvents(); assert(SetCVar==upper)
      end
      assert(upperCount==5 and lowerCount==5 and #setCalls==5)
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(EavesDrop:ShouldSuppressLegacy({type='heal'}))
      SetCVar('NP_EnableSpellHealEvents','0')
      assert(not EavesDrop:ShouldSuppressLegacy({type='heal'}))
      assert(upperCount==6 and lowerCount==6)
    '''),
    ("observer unhooks when it is still the top-level function", r'''
      local own=SetCVar
      for i=1,5 do
        EavesDrop:StopEnhancedEvents(); assert(SetCVar~=own)
        EavesDrop:StartEnhancedEvents(); assert(SetCVar==own)
      end
      assert(#setCalls==0)
    '''),
    ("invalid identity uses a truthful generic spell after category activation", r'''
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,10,'0,0,0',0,2,'0,0,0,3')
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,0,11,'0,0,0',0,2,'0,0,0,3')
      assert(#EavesDrop.events==2 and last().amount==11 and last().skill=='未知法术')
      assert(last().spellId==nil and last().texture==nil)
      assert(EavesDrop:ShouldSuppressLegacy({type='hit',skill='ActualSpell'}))
    '''),
    ("unusable amount clears suppression and invalid aura stays legacy", r'''
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,10,'0,0,0',0,2,'0,0,0,3')
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,nil,'0,0,0',0,2,'0,0,0,3')
      assert(#EavesDrop.events==1 and not EavesDrop:ShouldSuppressLegacy({type='hit',skill='Spell42'}))
      send('DEBUFF_ADDED_SELF',player,1,42,3,60,35,0)
      assert(not EavesDrop:ShouldSuppressLegacy({type='debuff',victim=ParserLib_SELF}))
      send('DEBUFF_ADDED_SELF',player,1,0,3,60,35,0)
      assert(not EavesDrop:ShouldSuppressLegacy({type='debuff',victim=ParserLib_SELF}))
    '''),
    ("status distinguishes registration from actual received data", r'''
      assert(string.find(EavesDrop:GetCombatSourceStatus(),'已收到 0 类',1,true))
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,10,'0,0,0',0,2,'0,0,0,3')
      assert(string.find(EavesDrop:GetCombatSourceStatus(),'已收到 1 类',1,true))
    '''),
    ("observer preserves zero returns and multiple all-nil returns", r'''
      returnMode='none'
      assert(pack(SetCVar('NP_EnableSpellHealEvents','0')).n==0)
      returnMode='nil'
      local result=pack(SetCVar('NP_EnableSpellHealEvents','1'))
      assert(result.n==2 and result[1]==nil and result[2]==nil)
    '''),
    ("unusable GUIDs stop suppression after prior valid data", r'''
      send('SPELL_DAMAGE_EVENT_SELF',enemy,player,42,10,'0,0,0',0,2,'0,0,0,3')
      assert(EavesDrop:ShouldSuppressLegacy({type='hit',skill='Spell42'}))
      send('SPELL_DAMAGE_EVENT_OTHER',nil,nil,42,10,'0,0,0',0,2,'0,0,0,3')
      assert(#EavesDrop.events==1 and not EavesDrop:ShouldSuppressLegacy({type='hit',skill='Spell42'}))
    '''),
    ("CVar observer matches case-insensitively without rewriting arguments", r'''
      send('SPELL_HEAL_BY_SELF',player,player,42,30,1,0)
      assert(EavesDrop:ShouldSuppressLegacy({type='heal'}))
      SetCVar('np_enablespellhealevents','0','lowercase')
      assert(not EavesDrop:ShouldSuppressLegacy({type='heal'}))
      assert(setCalls[1][1]=='np_enablespellhealevents' and setCalls[1][3]=='lowercase')
    '''),
]


def main():
    source = SOURCE.read_text(encoding="utf-8-sig")
    for name, assertions in CASES:
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(STUB)
        lua.execute(source)
        lua.execute("EavesDrop:StartEnhancedEvents()")
        try:
            lua.execute(assertions)
        except Exception as exc:
            raise AssertionError(name) from exc
    data = SOURCE.read_bytes()
    assert not data.startswith(b"\xef\xbb\xbf")
    assert data.count(b"\n") == data.count(b"\r\n")
    print(f"EavesDrop enhanced: {len(CASES)} Lua 5.1 event/filter/fallback checks passed; UTF-8/CRLF verified.")


if __name__ == "__main__":
    main()
