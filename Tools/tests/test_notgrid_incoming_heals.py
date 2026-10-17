"""Exercise current HealComm libraries and NotGrid with Lua 5.1 and AceEvent timers.

Game APIs/UI are mocked. The scheduler is read from the installed AceEvent source;
the complete current HealComm and NotGrid core files are executed, not reimplemented.
"""
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDONS = ROOT / 'Interface/AddOns'
LIBRARIES = [
    ADDONS / '!Libs/HealComm-1.0/HealComm-1.0.lua',
    ADDONS / 'QuickHeal/libs/HealComm-1.0/HealComm-1.0.lua',
]
ace = (ADDONS / '!Libs/Ace2/AceEvent-2.0/AceEvent-2.0.lua').read_text(encoding='utf-8-sig')
SCHEDULER = ace[ace.index('local delayRegistry\n'):ace.index('function AceEvent:UnregisterEvent(')]

MOCK = r'''
now=0; messages={}; updates={}; locales={}; libraries={}; revisions={}
getn=table.getn; strfind=string.find; strlen=string.len
UNKNOWNOBJECT='Unknown'; UKNOWNBEING='Unknown being'
function GetTime() return now end
function GetRealZoneText() return 'Test zone' end
function GetTalentInfo() return nil,nil,nil,nil,0 end
function UnitStat() return 0,0,0,0 end
function UnitBuff() end
function getglobal(name) return _G[name] end
function SendAddonMessage(prefix,msg,channel) table.insert(messages,{prefix,msg,channel}) end
function table_setn() end
function new() return {} end
function del(t) for k in pairs(t) do t[k]=nil end end
function object()
 return {
  SetOwner=function() end, SetInventoryItem=function() end, NumLines=function() return 1 end,
  SetWidth=function(self,v) self.width=v end,SetHeight=function(self,v) self.height=v end,
  SetPoint=function(self,...) self.point={...} end,ClearAllPoints=function() end,
  SetBackdropColor=function(self,r,g,b,a) self.alpha=a end,
  SetMinMaxValues=function() end, SetValue=function(self,v) self.value=v end,
  SetText=function(self,v) self.text=v end,SetTextColor=function() end,SetStatusBarColor=function() end,
  Show=function(self) self.shown=true end,Hide=function(self) self.shown=false end,
 }
end
function CreateFrame() return object() end
WorldFrame={}; SlashCmdList={}
units={}; ids={}
for i,name in ipairs({'A','B','C','D','Player'}) do
 local id='raid'..i
 units[id]={name=name,hp=1200,max=2000,connected=true};ids[name]=id
end
units.player=units.raid5
for i=1,4 do units['party'..i]=units['raid'..i] end
function UnitName(unit) return units[unit] and units[unit].name end
function UnitExists(unit) return units[unit]~=nil end
function UnitIsConnected(unit) return units[unit].connected end
function UnitIsDead(unit) return units[unit].dead end
function UnitIsGhost(unit) return units[unit].ghost end
function UnitHealth(unit) return units[unit].hp end
function UnitHealthMax(unit) return units[unit].max end
function UnitMana() return 500 end;function UnitManaMax() return 1000 end
function UnitClass() return 'Priest','PRIEST' end;function UnitPowerType() return 0 end
function CheckInteractDistance(unit) return units[unit]~=nil end
ManaBarColor={[0]={r=0,g=0,b=1}};RAID_CLASS_COLORS={PRIEST={r=1,g=1,b=1}}
AceEvent={frame={}}
function AceEvent.frame:SetScript(name,fn) self[name]=fn end
function AceEvent.frame:Show() end;function AceEvent.frame:Hide() end
function AceEvent:argCheck() end
function AceEvent:RegisterEvent() end;function AceEvent:UnregisterAllEvents() end
function AceEvent:CancelAllScheduledEvents()
 for id,v in pairs(AceEvent.delayRegistry or {}) do
  if v.self==self then self:CancelScheduledEvent(id) end
 end
end
function AceEvent:TriggerEvent(event,name)
 table.insert(updates,{event,name})
 if event=='HealComm_Healupdate' and NotGrid and NotGrid.HealComm then
  NotGrid:HealCommHandler(name)
 end
end
function AceEvent:embed(target)
 for k,v in pairs(self) do if type(v)=='function' then target[k]=v end end
end
libraries['AceEvent-2.0']=AceEvent
libraries['AceHook-2.1']={embed=function() end}
libraries['RosterLib-2.0']={GetUnitIDFromName=function(self,name) return ids[name] end}
libraries['ItemBonusLib-1.0']={GetBonus=function() return 0 end}
libraries['AceLocale-2.2']={new=function(self,name)
 if not locales[name] then
  local l=setmetatable({}, {__index=function(_,k) return k end})
  function l:RegisterTranslations(language,fn)
   if language=='enUS' or language==TEST_LOCALE then
    for k,v in pairs(fn()) do self[k]=v==true and k or v end
   end
  end
  locales[name]=l
 end
 return locales[name]
end}
libraries['AceAddon-2.0']={new=function() return {} end}
AceLibrary=setmetatable({}, {__call=function(self,name) return assert(libraries[name],name) end})
function AceLibrary:HasInstance(name) return libraries[name]~=nil end
function AceLibrary:IsNewVersion(name,minor)
 if type(minor)=='string' then minor=tonumber(string.match(minor,'%d+')) end
 return not revisions[name] or revisions[name]<minor
end
function AceLibrary:Register(lib,name,minor,activate,_,external)
 local old=libraries[name];libraries[name]=lib;revisions[name]=minor
 activate(lib,old)
 external(lib,'AceEvent-2.0',AceEvent)
 external(lib,'AceHook-2.1',libraries['AceHook-2.1'])
end
function tick(t)
 now=t
 if AceEvent.frame.OnUpdate then AceEvent.frame.OnUpdate() end
end
function recv(msg,caster)
 arg1='HealComm';arg2=msg;arg4=caster or 'RemotePriest'
 h:CHAT_MSG_ADDON()
end
function group(caster,amount,ms)
 h:startGrpHeal(caster or 'RemotePriest',amount or 800,ms or 3000,'A','B','C','D','Player')
end
function noHeal(name)
 assert(h:getHeal(name)==0 and h:getNumHeals(name)==0,'prediction remains for '..name)
 local f=NotGrid.UnitFrames[ids[name]]
 assert(f.incheal.alpha==0 and not f.healcommtext.shown,'visible prediction remains for '..name)
end
'''


def world(library, locale='enUS'):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().TEST_LOCALE = locale
    lua.execute(MOCK)
    lua.execute(SCHEDULER)
    lua.execute(library.read_text(encoding='utf-8-sig'))
    lua.execute((ADDONS / 'NotGrid/localization.lua').read_text(encoding='utf-8-sig'))
    lua.execute((ADDONS / 'NotGrid/core.lua').read_text(encoding='utf-8-sig'))
    lua.execute('''
     h=AceLibrary('HealComm-1.0');L=locales['HealComm-1.0']
     NotGrid.HealComm=h;NotGrid.RosterLib=AceLibrary('RosterLib-2.0')
     NotGrid.IdenticalUnits={};NotGrid.UnitFrames={}
     NotGrid.o={unithealthorientation=0,unitwidth=80,unitheight=40,
      unithealcommbarcolor={0,1,0,1},namelength=12,healththreshhold=100,
      showhealcommbar=true,showhealcommtext=true}
     for i=1,5 do
      local id='raid'..i
      NotGrid.UnitFrames[id]={unit=id,incheal=object(),healthbar=object(),powerbar=object(),
       namehealthtext=object(),healcommtext=object(),incres=object()}
      NotGrid:UNIT_MAIN(id)
     end
    ''')
    return lua


CASES = {
    'normal group expiry refreshes all five frames': '''
     group();for name in pairs(ids) do assert(h:getHeal(name)==800) end
     tick(3.01);for name in pairs(ids) do noHeal(name) end
    ''',
    'group replaced by single before its timer fires': '''
     group();now=2.9;recv('Heal/A/1200/2500/')
     noHeal('B');assert(h:getHeal('A')==1200)
     tick(3.1);assert(h:getHeal('A')==1200)
     tick(60);for name in pairs(ids) do noHeal(name) end
    ''',
    'single replaced by group': '''
     recv('Heal/A/1200/2500/');now=2;group()
     assert(h:getHeal('A')==800 and h:getNumHeals('A')==1)
     tick(2.6);assert(h:getHeal('A')==800);tick(5.1);noHeal('A')
    ''',
    'unrelated single stop and delay leave group timer intact': '''
     group();now=2.9;recv('Healstop');recv('Healdelay/500/')
     assert(h:getHeal('B')==800);tick(3.1);noHeal('B')
    ''',
    'unrelated group stop and delay leave single timer intact': '''
     recv('Heal/A/1200/2500/');now=2;recv('GrpHealstop');recv('GrpHealdelay/500/')
     assert(h:getHeal('A')==1200);tick(2.6);noHeal('A')
    ''',
    'group replacement refreshes former targets': '''
     group();now=1;h:startGrpHeal('RemotePriest',900,3000,'A','Player')
     noHeal('B');assert(h:getHeal('A')==900);tick(4.1);noHeal('A')
    ''',
    'single target switch refreshes former target': '''
     recv('Heal/A/1200/2500/');now=1;recv('Heal/B/900/2500/')
     noHeal('A');assert(h:getHeal('B')==900);tick(3.6);noHeal('B')
    ''',
    'group delay uses extended deadline': '''
     recv('GrpHeal/800/3000/A/B/C/D/Player/');now=1;recv('GrpHealdelay/1000/')
     tick(3.1);assert(h:getHeal('A')==800);tick(4.1);noHeal('A')
    ''',
    'single delay uses extended deadline': '''
     recv('Heal/A/1200/2500/');now=1;recv('Healdelay/1000/')
     tick(2.6);assert(h:getHeal('A')==1200);tick(3.6);noHeal('A')
    ''',
    'expired records ignored even with missing timers': '''
     group();h:startHeal('SecondPriest','A',500,1000)
     h:CancelAllScheduledEvents();now=60
     for name,id in pairs(ids) do NotGrid:UNIT_MAIN(id);noHeal(name) end
    ''',
    'multiple healers add independently and expire separately': '''
     group();h:startHeal('SecondPriest','A',500,1500)
     assert(h:getHeal('A')==1300 and h:getNumHeals('A')==2)
     tick(1.6);assert(h:getHeal('A')==800 and h:getNumHeals('A')==1)
     tick(3.1);noHeal('A')
    ''',
    'group completed locally broadcasts stop and clears immediately': '''
     group('Player');h.spellIsCasting=L['Prayer of Healing']
     h.SpellCastInfo={L['Prayer of Healing'],1,'A'};now=2.9;h:SPELLCAST_STOP()
     assert(messages[#messages][2]=='GrpHealstop' and not h.spellIsCasting)
     for name in pairs(ids) do noHeal(name) end
    ''',
    'single completed locally broadcasts stop': '''
     h:startHeal('Player','A',1200,2500);h.spellIsCasting=L['Flash Heal']
     h.SpellCastInfo={L['Flash Heal'],1,'A'};now=2.4;h:SPELLCAST_STOP()
     assert(messages[#messages][2]=='Healstop');noHeal('A')
    ''',
    'group interrupted locally broadcasts stop': '''
     group('Player');h.spellIsCasting=L['Prayer of Healing'];h:SPELLCAST_INTERRUPTED()
     assert(messages[#messages][2]=='GrpHealstop');noHeal('A')
    ''',
    'single interrupted locally broadcasts stop': '''
     h:startHeal('Player','A',1200,2500);h.spellIsCasting=L['Flash Heal']
     h:SPELLCAST_INTERRUPTED();assert(messages[#messages][2]=='Healstop');noHeal('A')
    ''',
    'received group stop clears every target': '''
     recv('GrpHeal/800/3000/A/B/C/D/Player/');recv('GrpHealstop')
     for name in pairs(ids) do noHeal(name) end
    ''',
    'local cast start routes Prayer of Healing to five targets': '''
     h.SpellCastInfo={L['Prayer of Healing'],1,'Player',0,1}
     arg1=L['Prayer of Healing'];arg2=3000;h:SPELLCAST_START()
     assert(string.find(messages[#messages][2],'GrpHeal/',1,true)==1)
     for name in pairs(ids) do assert(h:getHeal(name)>0) end
     h:SPELLCAST_STOP();for name in pairs(ids) do noHeal(name) end
    ''',
    'renew and rejuvenation still track their HoTs on stop': '''
     for _,spell in ipairs({'Renew','Rejuvenation'}) do
      h.SpellCastInfo={L[spell],1,'A'};h:SPELLCAST_STOP()
      assert(string.find(messages[#messages][2],spell=='Renew' and 'Renew/' or 'Reju/',1,true)==1)
     end
     local renewStart,renewDuration=h:getRenewTime('raid1')
     local rejuStart,rejuDuration=h:getRejuTime('raid1')
     assert(renewStart==now and renewDuration==15 and rejuStart==now and rejuDuration==12)
    ''',
    'death clears estimates even while group remains active; resurrection icon survives': '''
     group();h:startResurrection('ResPriest','B')
     units.raid2.dead=true;units.raid2.hp=0;NotGrid:UNIT_MAIN('raid2')
     local f=NotGrid.UnitFrames.raid2
     assert(f.incheal.alpha==0 and not f.healcommtext.shown and f.incres.shown)
     assert(h:getHeal('B')==800 and h:getHeal('A')==800)
    ''',
    'death flag with positive health cannot repaint estimates': '''
     group();units.raid2.dead=true;NotGrid:UNIT_MAIN('raid2')
     local f=NotGrid.UnitFrames.raid2
     assert(f.incheal.alpha==0 and not f.healcommtext.shown and f.healthbar.value==0)
    ''',
    'ghost with positive health cannot repaint estimates': '''
     group();units.raid2.ghost=true;units.raid2.hp=1;NotGrid:UNIT_MAIN('raid2')
     local f=NotGrid.UnitFrames.raid2
     assert(f.incheal.alpha==0 and not f.healcommtext.shown)
    ''',
    'offline clears visible estimates': '''
     group();units.raid2.connected=false;NotGrid:UNIT_MAIN('raid2')
     assert(NotGrid.UnitFrames.raid2.incheal.alpha==0 and not NotGrid.UnitFrames.raid2.healcommtext.shown)
    ''',
    'full health clears old bar in both orientations': '''
     for orientation=0,1 do
      NotGrid.o.unithealthorientation=orientation;units.raid2.hp=1200
      group();local f=NotGrid.UnitFrames.raid2;assert(f.incheal.alpha==1)
      units.raid2.hp=2000;NotGrid:UNIT_MAIN('raid2');assert(f.incheal.alpha==0)
     end
    ''',
    'bar and text toggles immediately clear previous display independently': '''
     group();local f=NotGrid.UnitFrames.raid2
     NotGrid.o.showhealcommbar=false;NotGrid:UNIT_MAIN('raid2')
     assert(f.incheal.alpha==0 and f.healcommtext.shown)
     NotGrid.o.showhealcommbar=true;NotGrid.o.showhealcommtext=false;NotGrid:UNIT_MAIN('raid2')
     assert(f.incheal.alpha==1 and not f.healcommtext.shown)
    ''',
    'zero maximum health clears stale bar without division': '''
     group();units.raid2.hp=0;units.raid2.max=0;NotGrid:UNIT_MAIN('raid2')
     assert(NotGrid.UnitFrames.raid2.incheal.alpha==0)
    ''',
    'reviving with no active heal does not restore expired estimates': '''
     group();units.raid2.dead=true;units.raid2.hp=0;NotGrid:UNIT_MAIN('raid2')
     tick(3.1);units.raid2.dead=nil;units.raid2.hp=1000;NotGrid:UNIT_MAIN('raid2');noHeal('B')
     group();assert(NotGrid.UnitFrames.raid2.incheal.alpha==1)
    ''',
}

groups = 0
for library in LIBRARIES:
    for locale in ('enUS', 'zhCN'):
        for name, case in CASES.items():
            try:
                world(library, locale).execute(case)
            except Exception as error:
                raise AssertionError(f'{library.relative_to(ADDONS)} [{locale}] {name}') from error
            groups += 1

# Both embedded copies must be safe whichever loads first; old revision cannot replace them.
for first, second in (LIBRARIES, LIBRARIES[::-1]):
    lua = world(first)
    lua.execute(second.read_text(encoding='utf-8-sig'))
    # Both load orders select the maintained merged revision over embedded 11733.
    lua.execute("assert(revisions['HealComm-1.0']==11734 and not AceLibrary:IsNewVersion('HealComm-1.0',11733))")
    lua.execute("h=AceLibrary('HealComm-1.0');assert(h.getHeal and h.startGrpHeal and h.stopGrpHeal)")
    groups += 1

print(f'PASS: {groups} behavior groups; full current libraries/core; English/Chinese; actual AceEvent scheduler')
