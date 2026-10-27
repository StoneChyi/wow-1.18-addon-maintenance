"""Run actual proc/temporary-summon code under a Lua 5.1 event contract.

No game/DLL execution, saved settings, screenshots or network capture is used.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "addons_tmp/bcs-test-runtime"))
from lupa.lua51 import LuaRuntime

SOURCE = ROOT / "Interface/AddOns/EavesDrop/procs.lua"
STUB = r'''
UIParent={}; tick=100; failEvent=nil; active=true
player='0x0000000000000001'; pet='0xF140000001000001'
lost='0xF13000EA59000001'; otherLost='0xF13000EA59000002'
other='0x0000000000000002'; enemy='0xF130000010000001'
units={[lost]='迷失者',[otherLost]='迷失者',[enemy]='Enemy'}
fields={[lost]={createdBy=player},[otherLost]={createdBy=other}}
owners={}; spellNames={[42]='召唤迷失者',[43]='召唤迷失者的幻影'}
version={4,6,1}; fieldCalls=0
function GetTime()return tick end
function date()return '12:34:56'end
function getglobal(name)return _G[name]end
function GetNampowerVersion()return unpack(version)end
function GetUnitGUID(unit)
 if unit=='player'then return player elseif unit=='pet'then return pet end
 return owners[unit]
end
function UnitName(unit)return units[unit]end
function UnitExists()return false end
function UnitIsPlayer(guid)return guid==player or guid==other end
function GetUnitField(guid,key)
 assert(key=='createdBy' or key=='summonedBy','unverified field '..tostring(key))
 fieldCalls=fieldCalls+1
 return fields[guid] and fields[guid][key]
end
function GetSpellRecField(id,key)assert(key=='name');return spellNames[id]end
function GetSpellNameAndRankForId(id)return spellNames[id]end
function SetCVar()error('proc monitoring must not write CVar')end
function CreateFrame()
 local f={events={},scripts={}}
 function f:RegisterEvent(name)if failEvent==name then error('unsupported')end;self.events[name]=true end
 function f:UnregisterAllEvents()self.events={}end
 function f:IsEventRegistered(name)return self.events[name]end
 function f:SetScript(name,fn)self.scripts[name]=fn end
 function f:CreateFontString()error('proc logic must not construct UI')end
 return f
end
EavesDrop={_running=true,db={profile={PROCWATCH=true,SUMMONWATCH=true,PROCSOURCE='floating',PROCMERGE=true,
 PROCCOLOR={r=.1,g=.2,b=.3},SUMMONCOLOR={r=.7,g=.8,b=.9}}},merged={},observed={}}
function EavesDrop:IsActive()return active end
function EavesDrop:DisplayEvent(direction,text,texture,color)
 table.insert(self.merged,{direction=direction,text=text,texture=texture,color=color,message=self.eventMessage})
end
function EavesDrop:OnProcRecord(record)table.insert(self.observed,record)end
function send(...)EavesDrop:HandleProcEvent(...)end
function native(name,...)
 local f=EavesDrop.procFrame
 assert(f and f.events[name])
 event=name;arg1,arg2,arg3,arg4=unpack(arg)
 f.scripts.OnEvent()
 event=nil;arg1=nil;arg2=nil;arg3=nil;arg4=nil
end
function last()local rs=EavesDrop:GetProcRecords();return rs[#rs]end
function damage(guid,n,passthrough)
 return EavesDrop:ObserveSummonCombat({type='hit',sourceGUID=guid,victimGUID=enemy,amount=n,
  message='real enhanced message',texture='ActualIcon'},passthrough)
end
'''

CASES = [
    ("floating is the only default cast source", r'''
      assert(EavesDrop.procFrame.events.COMBAT_TEXT_UPDATE)
      assert(not EavesDrop.procFrame.events.SPELL_GO_SELF and not EavesDrop.procFrame.events.UNIT_CASTEVENT)
    '''),
    ("default floating cast notification is trigger, never creation", r'''
      native('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')
      assert(EavesDrop.procStats.triggers==1 and EavesDrop.procStats.summons==0)
      assert(last().evidence=='浮动战斗信息 SPELL_CAST' and string.find(last().message,'不据此认定单位已生成',1,true))
      assert(last().timestamp=='12:34:56' and last().detail==last().message)
    '''),
    ("availability notification is not a trigger", r'''
      send('COMBAT_TEXT_UPDATE','SPELL_ACTIVE','召唤迷失者')
      assert(EavesDrop.procStats.triggers==0 and EavesDrop.procStats.available==1)
      assert(last().evidence=='available')
    '''),
    ("exact-name rule rejects fuzzy and unrelated messages", r'''
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者的幻影')
      send('COMBAT_TEXT_UPDATE','AURA_START','召唤迷失者')
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','Summon The Lost')
      assert(#EavesDrop:GetProcRecords()==0)
    '''),
    ("other sources never double-count the chosen floating source", r'''
      send('SPELL_GO_SELF',0,42,player,enemy)
      send('UNIT_CASTEVENT',player,enemy,'CAST',42)
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')
      assert(EavesDrop.procStats.triggers==1)
    '''),
    ("simultaneous distinct notifications are not time-debounced", r'''
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')
      assert(EavesDrop.procStats.triggers==2)
    '''),
    ("native source is explicit and validates caster", r'''
      EavesDrop.db.profile.PROCSOURCE='native';EavesDrop:RefreshProcMonitoring()
      assert(EavesDrop.procFrame.events.SPELL_GO_SELF and not EavesDrop.procFrame.events.UNIT_CASTEVENT)
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')
      send('SPELL_GO_SELF',0,42,other,enemy)
      send('SPELL_GO_SELF',0,42,player,enemy)
      assert(EavesDrop.procStats.triggers==1 and last().spellId==42)
    '''),
    ("itemId zero is not an exclusion rule", r'''
      EavesDrop.db.profile.PROCSOURCE='native';EavesDrop:RefreshProcMonitoring()
      send('SPELL_GO_SELF',0,42,player,enemy)
      assert(EavesDrop.procStats.triggers==1)
    '''),
    ("unsupported native source does not switch silently", r'''
      EavesDrop.db.profile.PROCSOURCE='native';GetNampowerVersion=nil;EavesDrop:RefreshProcMonitoring()
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')
      assert(EavesDrop.procStats.triggers==0 and string.find(EavesDrop:GetProcStatus(),'未切换',1,true))
    '''),
    ("native registration failure remains noncounting", r'''
      EavesDrop.db.profile.PROCSOURCE='native';failEvent='SPELL_GO_SELF';EavesDrop:RefreshProcMonitoring()
      send('SPELL_GO_SELF',0,42,player,enemy)
      assert(EavesDrop.procStats.triggers==0)
    '''),
    ("SuperWoW only accepts player successful CAST", r'''
      EavesDrop.db.profile.PROCSOURCE='superwow';EavesDrop:RefreshProcMonitoring()
      assert(EavesDrop.procFrame.events.UNIT_CASTEVENT and not EavesDrop.procFrame.events.SPELL_GO_SELF)
      send('UNIT_CASTEVENT',player,enemy,'START',42)
      send('UNIT_CASTEVENT',other,enemy,'CAST',42)
      send('UNIT_CASTEVENT',player,enemy,'CAST',42)
      assert(EavesDrop.procStats.triggers==1)
    '''),
    ("unsupported SuperWoW never falls through to floating", r'''
      EavesDrop.db.profile.PROCSOURCE='superwow';GetSpellNameAndRankForId=nil;EavesDrop:RefreshProcMonitoring()
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者');assert(EavesDrop.procStats.triggers==0)
    '''),
    ("NPC GUID plus creator confirms lost summon without name", r'''
      units[lost]=nil;assert(EavesDrop:IsOwnedTemporarySummon(lost))
    '''),
    ("summonedBy is a second verified ownership field", r'''
      fields[lost]={summonedBy=player};assert(EavesDrop:IsOwnedTemporarySummon(lost))
    '''),
    ("owner token is a verified ownership alternative", r'''
      fields[lost]={};owners[lost..'owner']=player;assert(EavesDrop:IsOwnedTemporarySummon(lost))
    '''),
    ("same-name foreign summon remains excluded", r'''
      assert(not EavesDrop:IsOwnedTemporarySummon(otherLost))
      assert(not damage(otherLost,10));assert(EavesDrop.procStats.damage==0)
    '''),
    ("current foreign owner takes priority over original creator", r'''
      owners[lost..'owner']=other;fields[lost]={createdBy=player}
      assert(not EavesDrop:IsOwnedTemporarySummon(lost))
      owners[lost..'owner']=nil;fields[lost]={summonedBy=other,createdBy=player}
      assert(not EavesDrop:IsOwnedTemporarySummon(lost))
    '''),
    ("old native field API is not called as a fallback", r'''
      version={3,0,0};assert(not EavesDrop:IsOwnedTemporarySummon(lost) and fieldCalls==0)
      owners[lost..'owner']=player;assert(EavesDrop:IsOwnedTemporarySummon(lost) and fieldCalls==0)
    '''),
    ("summon status reports disabled and unavailable data separately", r'''
      EavesDrop.db.profile.SUMMONWATCH=false
      assert(string.find(EavesDrop:GetProcStatus(),'临时召唤监视已关闭',1,true))
      EavesDrop.db.profile.SUMMONWATCH=true;EavesDrop.db.profile.DATASOURCE='legacy'
      assert(string.find(EavesDrop:GetProcStatus(),'旧文字模式无可靠归属',1,true))
      EavesDrop.db.profile.DATASOURCE='auto'
      assert(string.find(EavesDrop:GetProcStatus(),'等待增强日志',1,true))
    '''),
    ("regular pet and player remain on core routes", r'''
      units[pet]='迷失者';fields[pet]={createdBy=player}
      assert(not EavesDrop:IsOwnedTemporarySummon(pet) and not EavesDrop:IsOwnedTemporarySummon(player))
    '''),
    ("ownership is rechecked after every observation", r'''
      assert(damage(lost,10));fields[lost]={createdBy=other}
      assert(not damage(lost,20) and EavesDrop.procStats.damage==10)
    '''),
    ("missing ownership never trusts previous discovery", r'''
      assert(damage(lost,10));fields[lost]=nil;units[lost]=nil
      assert(not damage(lost,20) and EavesDrop.procStats.damage==10)
    '''),
    ("known contradictory creature entry defeats same-name match", r'''
      units[enemy]='迷失者';fields[enemy]={createdBy=player}
      assert(not EavesDrop:IsOwnedTemporarySummon(enemy))
    '''),
    ("first observation has one unique GUID notice, never spawn count", r'''
      assert(damage(lost,10));assert(damage(lost,12))
      assert(EavesDrop.procStats.summons==1 and EavesDrop.procStats.triggers==0 and EavesDrop.procStats.damage==22)
      assert(EavesDrop:GetProcRecords()[1].evidence=='first_observed' and #EavesDrop:GetProcRecords()==3)
    '''),
    ("summon records retain actual icon and tooltip", r'''
      damage(lost,10);assert(last().texture=='ActualIcon' and last().message=='real enhanced message')
      assert(last().text=='[迷失者] 10' and last().kind=='summon')
    '''),
    ("taken damage does not inflate summon outgoing damage", r'''
      assert(EavesDrop:ObserveSummonCombat({type='hit',sourceGUID=enemy,victimGUID=lost,amount=7}))
      assert(last().direction==-1 and EavesDrop.procStats.damage==0 and EavesDrop.procStats.taken==7)
    '''),
    ("player-involved combat is not merged twice", r'''
      assert(not EavesDrop:ObserveSummonCombat({type='heal',sourceGUID=player,victimGUID=lost,amount=7},true))
      assert(#EavesDrop.merged==1 and last().merge==false and last().combatType=='heal')
      assert(EavesDrop:GetProcRecords()[1].evidence=='first_observed')
    '''),
    ("disabled merge keeps independent records and callback", r'''
      EavesDrop.db.profile.PROCMERGE=false;send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者');damage(lost,10)
      assert(#EavesDrop.merged==0 and #EavesDrop:GetProcRecords()==3 and #EavesDrop.observed==3)
    '''),
    ("merge preserves surrounding message and independent color", r'''
      EavesDrop.eventMessage='outer';send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')
      assert(EavesDrop.merged[1].color==EavesDrop.db.profile.PROCCOLOR and EavesDrop.eventMessage=='outer')
      damage(lost,10);assert(EavesDrop.merged[3].color==EavesDrop.db.profile.SUMMONCOLOR)
    '''),
    ("independent summon toggle and proc toggle", r'''
      EavesDrop.db.profile.SUMMONWATCH=false;assert(not damage(lost,10))
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者');assert(EavesDrop.procStats.triggers==1)
      EavesDrop.db.profile.SUMMONWATCH=true;EavesDrop.db.profile.PROCWATCH=false;EavesDrop:RefreshProcMonitoring()
      assert(next(EavesDrop.procFrame.events)==nil and damage(lost,10))
    '''),
    ("stop and inactive reject delayed callbacks", r'''
      EavesDrop:StopProcMonitoring();send('COMBAT_TEXT_UPDATE','SPELL_ACTIVE','召唤迷失者')
      assert(#EavesDrop:GetProcRecords()==0);EavesDrop:StartProcMonitoring();EavesDrop._running=false
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者');assert(not damage(lost,10))
      assert(#EavesDrop:GetProcRecords()==0)
    '''),
    ("refresh and stop preserve login counters and bounded records", r'''
      send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者');damage(lost,10)
      for i=1,5 do EavesDrop:RefreshProcMonitoring()end
      assert(EavesDrop.procStats.triggers==1 and EavesDrop.procStats.summons==1 and #EavesDrop:GetProcRecords()==3)
      damage(lost,5);assert(EavesDrop.procStats.summons==1)
      for i=1,300 do send('COMBAT_TEXT_UPDATE','SPELL_CAST','召唤迷失者')end
      assert(#EavesDrop:GetProcRecords()==128 and EavesDrop.procStats.triggers==301)
    '''),
    ("malformed combat and forged temporary flags are rejected", r'''
      assert(not EavesDrop:ObserveSummonCombat({type='hit',sourceGUID=otherLost,sourceIsTemporary=true,amount=10}))
      assert(not EavesDrop:ObserveSummonCombat({type='hit',sourceGUID=lost,amount=-1}))
      assert(not EavesDrop:ObserveSummonCombat({type='hit',sourceGUID=lost,amount=0/0}))
      assert(not EavesDrop:ObserveSummonCombat({type='hit',sourceGUID=lost,amount=math.huge}))
      local infinity=math.huge;math.huge=nil
      assert(not EavesDrop:ObserveSummonCombat({type='hit',sourceGUID=lost,amount=infinity}))
      assert(not EavesDrop:ObserveSummonCombat({type='fade',sourceGUID=lost}))
    '''),
    ("future explicit verified spell rules do not use fuzzy matching", r'''
      assert(not EavesDrop:RegisterProcRule('invalid',{label='Bad',unitLabel='Bad',spellNames='bad'}))
      assert(EavesDrop:RegisterProcRule('verified',{label='Verified',unitLabel='Guardian',spellIds={[99]=true}}))
      EavesDrop.db.profile.PROCSOURCE='native';EavesDrop:RefreshProcMonitoring()
      send('SPELL_GO_SELF',0,99,player,enemy)
      assert(EavesDrop.procStats.triggers==1 and last().rule=='verified' and last().spellId==99)
    '''),
]


if __name__ == "__main__":
    for name, checks in CASES:
        lua = LuaRuntime(unpack_returned_tuples=True)
        lua.execute(STUB)
        lua.execute(SOURCE.read_text(encoding="utf-8-sig"))
        lua.execute("EavesDrop:StartProcMonitoring()")
        try:
            lua.execute(checks)
        except Exception as exc:
            raise AssertionError(name) from exc
    print(f"EavesDrop procs: {len(CASES)} Lua 5.1 source/ownership/evidence checks passed; game verification required.")
