from pathlib import Path
import re
ROOT=Path(r'E:/1.18/Interface/AddOns')
# Reuse only the mock runtime and actual Insights modules, without its test cases.
harness=Path(__file__).with_name('test_dpsmatex_insights.py').read_text(encoding='utf-8')
exec(compile(harness.split("check('first-install")[0],__file__,'exec'))
core=(ROOT/'DPSMateX/DPSMateX.lua').read_text(encoding='utf-8-sig')
route=core[core.index('function DPSMateX:GetModeByArr'):core.index('local nampower_events')]
lua.execute('local strfind=string.find;local strsub=string.sub\n'+route)
options=(ROOT/'DPSMateX/DPSMateX_Options.lua').read_text(encoding='utf-8-sig')
toggle=options[options.index('function DPSMateX.Options:ToggleSegment'):options.index('function DPSMateX.Options:OnVerticalScroll')]
lua.execute(toggle)
lua.execute('''
local D=DPSMateX
getglobal=function(name) return _G[name] end
function time() return 123456 end
function GetRealZoneText() return zone or "Test Dungeon" end
function IsInInstance() return inInstance~=false end
function UnitClassification(unit) return unit=="0xE" and (npcClass or "normal") or "normal" end
local oldName=UnitName
function UnitName(unit) if unit=="target" then unit="0xE" end;if unit=="0xE" then return npcName or "Enemy" end;return oldName(unit) end
function UnitIsPlayer(unit) return unit=="0xPvP" or unit=="0xA" or unit=="0xB" end
function UnitCanAttack(player,unit) return unit=="0xE" or unit=="0xPvP" or unit=="target" end
D.DB.has_nampower=true
D.CombatTime={total=0,current=0,effective={{},{}},segments={}}
D.DBCache={};D.Modules={}
D.Options.Options[2]={args={}}
local metatable=getmetatable(UIParent)
function metatable:GetParent() return self.parent end
function D.Options:NewSegment()
  if D.Encounters then D.Encounters:BeforeReset() end
  D.Insights:ResetCurrent()
  for _,db in pairs(D.DBCache) do db[2]={} end
  D.CombatTime.current=0;D.CombatTime.effective[2]={}
end
''')
for name in ('Merge.lua','Encounter.lua','Views.lua'):
    lua.execute((ROOT/'DPSMateXEncounters'/name).read_text(encoding='utf-8-sig'))
lua.execute('''
local D,C=DPSMateX,DPSMateX.Encounters
for category,schema in pairs(C.schemas) do
  D.DBCache[schema.path]={{},{},Hist=category}
end
D.RegistredModules.damage={Hist="DMGDone",DB=D.DBCache.DamageDone}
D.RegistredModules.enemydamagetaken={Hist="EDTaken",DB=D.DBCache.EDT}
D.RegistredModules.dps=D.RegistredModules.damage
D.RegistredModules.deaths={Hist="Deaths",DB={{},{}}}
C:Initialize()
function newCase()
  combat=false;D.Insights:Reset();C:Reset()
  for _,db in pairs(D.DBCache) do db[2]={} end
  now=10;zone="Test Dungeon";inInstance=true;npcClass="normal";npcName="Enemy"
  C.guidCache={};C.guidCount=0;C.suspended=nil
  D.Settings.windows[1].CurMode="damage";D.Settings.windows[1].options[2]={currentfight=true}
  D.Registered=true
end
function beginEncounter()
  D.Options:NewSegment();combat=true;D.Insights:StartCombat();C:Start()
end
function D.DB:BeginInsightsCombat()
  if not combat then beginEncounter() end
end
function addCore(amount,min,max)
  local user=D.DB:BuildUser("PriestA","priest");local spell=D.DB:BuildAbility("Hit")
  local rows=D.DBCache.DamageDone[2]
  rows[user]=rows[user] or {i=0};local u=rows[user];u.i=u.i+amount
  local s=u[spell] or {};u[spell]=s;s[1]=(s[1] or 0)+1;s[2]=math.min(s[2] or min,min);s[3]=math.max(s[3] or max,max);s[4]=(s[4] or 0)+amount;s[12]=(s[12] or 0)+amount;s.i={{now,amount}}
  D.CombatTime.effective[2].PriestA=(D.CombatTime.effective[2].PriestA or 0)+1
end
function endEncounter()
  combat=false;D.Insights:EndCombat();C:End()
end
function selectScope(scope,key)
  D.Options:ToggleSegment(key or 1,scope.."all")
end
''')
def test(name,code):
    lua.execute('local D,E,C=DPSMateX,DPSMateX.Insights,DPSMateX.Encounters\n'+code)
    print('PASS:',name)

test('menu entries have independent closures and live window flags','''
assert(D.Options.Options[2].args.bossall.name=="Boss汇总")
assert(D.Options.Options[2].args.trashall.name=="小怪汇总")
newCase();selectScope("boss");assert(D.RegistredModules.damage.acceptNewValues[1])
assert(D.Options.Options[2].args.bossall.get() and not D.Options.Options[2].args.trashall.get())
''')
test('boss involvement promotes whole encounter including previous trash slice','''
newCase();beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(100,30,100)
assert(C.db.current.kind=="trash")
now=15;D.Options:NewSegment();addCore(200,20,200)
npcClass="worldboss";npcName="Test Boss";C.guidCache={};C.guidCount=0
C:PrepareEvent("SPELL_GO_SELF",0,9,"0xA","0xE")
now=20;endEncounter();C:End()
local b=C.db.buckets.boss;local user=D.CacheUser.PriestA[1];local spell=D.CacheAbility.Hit[1]
assert(b.fightCount==1 and b.duration==10 and b.core.DMGDone[user].i==300)
assert(b.core.DMGDone[user][spell][2]==20 and b.core.DMGDone[user][spell][3]==200)
assert(next(b.core.DMGDone[user][spell].i)==nil)
assert(C.db.buckets.trash.fightCount==0 and b.effective.PriestA==2)
selectScope("boss");local rows,seconds,effective=D:GetMode(1)
assert(rows[user].i==300 and seconds==10 and effective.PriestA==2)
assert(string.find(D:GetModeName(1),"Boss汇总",1,true))
''')
test('ordinary PvE, target-only boss, unrelated boss and PvP isolation','''
newCase();beginEncounter();addCore(25,25,25);now=12;endEncounter()
assert(C.db.buckets.unclassified.fightCount==1 and C.db.buckets.boss.fightCount==0)
beginEncounter();npcClass="worldboss";C:PrepareEvent("AUTO_ATTACK_OTHER","0xStranger","0xE")
assert(C.db.current.kind=="unclassified")
C:PrepareEvent("AUTO_ATTACK_OTHER","0xA","0xPvP");addCore(20,20,20);now=14;endEncounter()
assert(C.db.buckets.unclassified.fightCount==2 and C.db.buckets.trash.fightCount==0)
npcClass="normal";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(40,40,40);now=17;endEncounter()
assert(C.db.buckets.trash.fightCount==1 and C.db.buckets.trash.duration==3)
''')
test('failed world boss attempt, pet involvement and disabled death mode','''
newCase();npcClass="worldboss";inInstance=false
C:PrepareEvent("SPELL_MISS_OTHER","0xP","0xE")
assert(combat and C.db.current.kind=="boss")
addCore(50,50,50);C:PrepareEvent("UNIT_DIED","0xE");assert(C.db.current.observedBossDeath)
now=13;endEncounter();assert(C.db.buckets.boss.fightCount==1)
''')
test('explicit dungeon boss and zone-scoped custom whitelist','''
newCase();npcClass="elite";npcName="Baron Rivendare";beginEncounter()
C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");assert(C.db.current.kind=="boss")
now=12;endEncounter();newCase();npcClass="elite";npcName="Custom Boss"
SlashCmdList.DPSMATEXENCOUNTERS("boss");beginEncounter()
C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");assert(C.db.current.kind=="boss")
now=12;endEncounter();zone="Different Dungeon";beginEncounter()
C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");assert(C.db.current.kind=="trash")
''')
test('healing absorbs and casts use same scope without replay duplication','''
newCase();aura(1,"0xA","0xT",127);npcClass="worldboss";beginEncounter()
C:PrepareEvent("SPELL_DAMAGE_EVENT_OTHER","0xT","0xE")
damage("0xT",0,100);E:OnEvent("SPELL_HEAL_BY_OTHER","0xT","0xA",7,700,0,0)
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0);now=15;endEncounter()
D.Settings.windows[1].CurMode="healingabsorbsactual";selectScope("boss")
local s,seconds=D:GetMode(1);assert(s.aggregate and seconds==5 and E:Value(s.healing.PriestA,"healing")==600)
assert(next(s.playback)==nil and next(s.audit)==nil and s.healing.PriestA.bins==nil)
assert(s.healing.PriestA.outcomes.hit.count==1 and s.healing.PriestA.outcomes.absorb.effective==100)
D.Settings.windows[1].CurMode="spellcastsactual";local s2=D:GetMode(1);assert(s2.casts.PriestA.count==1)
E:OpenDetails("healing","PriestA",1);local w=E.healingWindows[1];assert(w.viewButtons.graph==nil and not w.viewButtons.audit:IsShown())
w.view="graph";E:Render(w);assert(w.view=="skills")
D.Settings.windows[1].CurMode="actionreplay";D:GetMode(1);assert(D.Settings.windows[1].options[2].currentfight)
''')
test('healing classifications and min/max merge across completed boss encounters','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE")
E:Heal("0xA","0xT",7,200,0,0);E:Heal("0xA","0xT",7,700,0,1)
now=12;endEncounter();D.Options:NewSegment()
beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE")
E:Heal("0xA","0xT",7,400,0,0);E:Heal("0xA","0xT",7,900,0,1)
now=15;endEncounter();D.Settings.windows[1].CurMode="healingabsorbsactual";selectScope("boss")
local s=D:GetMode(1);local u=s.healing.PriestA
assert(u.count==4 and u.outcomes.hit.count==2 and u.outcomes.crit.count==2)
assert(u.outcomes.hit.min==200 and u.outcomes.hit.max==400 and u.outcomes.crit.max==900)
assert(u.outcomes.crit.effectiveMin==500 and u.outcomes.crit.effectiveMax==500)
for _,row in pairs(u.skills) do assert(row.outcomes.crit.count==2 and row.targets.Tank.outcomes.hit.min==200) end
''')

test('live view, cache refresh, two windows and category routing','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE")
addCore(100,100,100);selectScope("boss")
local rows,seconds=D:GetMode(1);local user=D.CacheUser.PriestA[1];assert(rows[user].i==100)
addCore(50,50,50);local cached=D:GetMode(1);assert(cached[user].i==100)
now=now+1.1;local refreshed=D:GetMode(1);assert(refreshed[user].i==150)
D.Settings.windows[2]={options={{},{currentfight=true}},CurMode="damage"};selectScope("trash",2)
assert(next((D:GetMode(2)))==nil)
local edt=D:GetModeByArr(D.DBCache.EDT,1);assert(next(edt)==nil)
for cat in pairs(C.schemas) do C:GetCore(1,cat) end
local count=0;for _ in pairs(C.cache) do count=count+1 end;assert(count<=4)
D.Settings.windows[2]=nil;now=15;endEncounter()
assert(C.db.buckets.boss.core.DMGDone[user].i==150)
''')
test('history deletion and only-boss settings do not change aggregates','''
local before=C.db.buckets.boss.core.DMGDone[D.CacheUser.PriestA[1]].i
D.Settings.onlybossfights=true;E:SaveSegment("Temporary history");E:RemoveSegment(1)
assert(C.db.buckets.boss.core.DMGDone[D.CacheUser.PriestA[1]].i==before)
''')
test('manual split then live boss duration counted once','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE")
addCore(10,10,10);now=13;D.Options:NewSegment();addCore(20,20,20);now=16;selectScope("boss")
local rows,seconds=D:GetMode(1);assert(seconds==6 and rows[D.CacheUser.PriestA[1]].i==30)
now=18;endEncounter();assert(C.db.buckets.boss.duration==8 and C.db.buckets.boss.fightCount==1)
''')
test('full clear during combat discards previous data and preserves boss classification','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(500,500,500)
now=14;C:Reset();E:Reset()
for _,db in pairs(D.DBCache) do db[2]={} end
D.CombatTime.effective[2]={};E:StartCombat();C:Initialize();addCore(10,10,10)
now=17;endEncounter();local b=C.db.buckets.boss
assert(b.duration==3 and b.fightCount==1 and b.core.DMGDone[D.CacheUser.PriestA[1]].i==10)
''')
test('interrupted trash becomes unclassified and no offline time is counted','''
newCase();beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(12,12,12)
now=14;C:OnUpdate(0.6);C.initialized=nil;now=10000;combat=false;C:Initialize()
assert(C.db.buckets.unclassified.duration==4 and C.db.buckets.trash.fightCount==0)
local before=C.db.buckets.unclassified.fightCount;C:Initialize();assert(C.db.buckets.unclassified.fightCount==before)
''')
test('zone transition freezes old encounter and prevents cross-zone collection','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(30,30,30)
now=13;C:PrepareEvent("ZONE_CHANGED_NEW_AREA");assert(C.suspended and C.db.buckets.boss.fightCount==1)
C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");assert(C.db.current.settled)
combat=false;C:BeforeReset();assert(not C.suspended)
''')
test('pending caster name resolves before settlement without duplicating core totals','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(50,50,50)
E.identities={};nameUnavailable="0xA"
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
assert(table.getn(E.pending)==1);now=11;endEncounter()
assert(C.db.current.waiting and C.db.buckets.boss.fightCount==0)
nameUnavailable=nil;E:FlushPending();now=11.5;C:OnUpdate(0.6)
local b=C.db.buckets.boss
assert(b.fightCount==1 and b.duration==1 and b.casts.PriestA.count==1 and b.core.DMGDone[D.CacheUser.PriestA[1]].i==50)
''')
test('unresolved pending event never leaks into next encounter','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(60,60,60)
E.identities={};nameUnavailable="0xA";E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
now=10.2;endEncounter();assert(C.db.current.waiting)
nameUnavailable=nil;beginEncounter()
assert(C.db.buckets.boss.casts.PriestA.count==1 and not E.db.current.casts.PriestA and table.getn(E.pending)==0)
assert(not C.db.current.settled)
''')
test('pending name expiration retains known core totals and closes once','''
newCase();npcClass="worldboss";beginEncounter();C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(70,70,70)
E.identities={};nameUnavailable="0xA";E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
now=10.2;endEncounter();now=13;C:OnUpdate(0.6);C:Finalize()
assert(C.db.buckets.boss.fightCount==1 and C.db.buckets.boss.core.DMGDone[D.CacheUser.PriestA[1]].i==70)
assert(E.db.current.missed==1 and table.getn(E.pending)==0);nameUnavailable=nil
''')
test('unsupported modules, unavailable Nampower and disabled addon fall back safely','''
newCase();D.Settings.windows[1].CurMode="deaths";selectScope("boss");assert(D.Settings.windows[1].options[2].currentfight)
D.Settings.windows[1].CurMode="damage";C.available=false;selectScope("boss");assert(D.Settings.windows[1].options[2].currentfight)
local saved=D.Encounters;D.Encounters=nil;D.Settings.windows[1].options[2]={bossall=true}
local rows=D:GetMode(1);assert(type(rows)=="table" and D.Settings.windows[1].options[2].currentfight)
D.Encounters=saved;C.available=true
''')
test('damage, taken and heal minima maxima merge correctly','''
local a,b={},{[1]=1,[2]=10,[3]=25,[4]=25,[12]=25}
C:MergeLeaf(a,b,"damage");C:MergeLeaf(a,{[1]=2,[2]=5,[3]=40,[4]=60,[12]=60},"damage")
assert(a[1]==3 and a[2]==5 and a[3]==40 and a[12]==85)
local t={};C:MergeLeaf(t,{[1]=2,[2]=10,[3]=30,[13]=40,[14]=20},"taken")
C:MergeLeaf(t,{[1]=1,[2]=5,[3]=50,[13]=50,[14]=50},"taken")
assert(t[2]==5 and t[3]==50 and t[13]==90 and t[14]==30)
local h={};C:MergeLeaf(h,{[1]=50,[2]=1,[6]=50,[7]=50},"heal")
C:MergeLeaf(h,{[1]=20,[2]=1,[6]=20,[7]=20},"heal")
assert(h[1]==70 and h[2]==2 and h[6]==20 and h[7]==50)
''')
test('bounded target and skill details preserve totals under pressure','''
local b=C:NewBucket();local user=D.DB:BuildUser("Pressure","priest")
for target=1,80 do
  local npc=D.DB:BuildUser("NPC"..target,"warrior")
  local u={i=150};for skill=1,150 do
    local spell=D.DB:BuildAbility("PressureSpell"..skill);u[spell]={[1]=1,[2]=1,[3]=1,[4]=1,[12]=1,i={{1,1}}}
  end
  C:MergeCore(b.core,{EDTaken={[npc]={[user]=u}}},b)
end
local targets,total,leaves=0,0,0
for _,players in pairs(b.core.EDTaken) do targets=targets+1;for _,u in pairs(players) do
  if type(u)=="table" then total=total+(u.i or 0);for key,row in pairs(u) do if type(key)=="number" then leaves=leaves+1 end end end
end end
assert(targets<=65 and total==12000 and b.detailTrimmed and leaves<11000)
local leafTotal=0;for _,players in pairs(b.core.EDTaken) do for _,u in pairs(players) do
 if type(u)=="table" then for key,row in pairs(u) do if type(key)=="number" then leafTotal=leafTotal+row[12] end end end
end end;assert(leafTotal==12000)
''')
test('idle coordinator does not scan units or create snapshots','''
newCase();local cached=C.cache;local calls=0;local old=UnitClassification
UnitClassification=function(...) calls=calls+1;return old(...) end
for i=1,1000 do C:OnUpdate(0.02);C:PrepareEvent("BUFF_ADDED_OTHER",6,"0xStranger") end
assert(calls==0 and C.cache==cached)
UnitClassification=old
''')
test('compact detail hooks retain scope titles without creating graph notes','''
newCase();local title=CreateFrame("FontString","TestEncounterTitle",UIParent)
C.detailTitles.DetailsTest={"TestEncounterTitle"}
local m={UpdateDetails=function(self,obj,key) title:SetText("详情") end}
D.Modules.DetailsTest=m;C:InstallDetailHooks();selectScope("boss")
m:UpdateDetails({},1);assert(m.encounterKey==1 and string.find(title:GetText(),"汇总",1,true))
assert(C.GraphNote==nil and m.UpdateLineGraph==nil)
D.Options:ToggleSegment(1,"currentfight");m:UpdateDetails({},1)
assert(title:GetText()=="详情")
''')
lua.execute('savedNewSegment=DPSMateX.Options.NewSegment')
segment=options[options.index('function DPSMateX.Options:NewSegment'):options.index('function DPSMateX.Options:CreateSegment')]
lua.execute('local strfind=string.find;local strsub=string.sub\n'+segment)
test('actual history naming keeps observed boss when adds take more damage','''
newCase();npcClass="worldboss";npcName="Observed Boss"
-- Use the normal boundary stub to start, then the actual legacy menu method to split.
savedNewSegment(D.Options);combat=true;E:StartCombat();C:Start()
C:PrepareEvent("AUTO_ATTACK_SELF","0xA","0xE");addCore(100,100,100)
local user=D.CacheUser.PriestA[1];local add=D.DB:BuildUser("Large Add","warrior")
D.DBCache.EDT[2][add]={[user]={i=999}}
D.BabbleBoss={Contains=function() return false end}
D.Options.FormatTime=function(self,seconds) return tostring(seconds) end
D.Options.CreateSegment=function(self,label) self.savedLabel=label end
D.DB.ResetCurrentFight=function() savedNewSegment(D.Options) end
D.SetStatusBarValue=function() end
D.Settings.onlybossfights=true;now=13;D.Options:NewSegment()
assert(string.find(D.Options.savedLabel,"Observed Boss",1,true))
assert(C.db.current.active and C.db.current.slice==2 and C.db.buckets.boss.fightCount==0)
now=16;endEncounter();assert(C.db.buckets.boss.fightCount==1 and C.db.buckets.boss.duration==6)
D.Options.NewSegment=savedNewSegment
''')
builder=(ROOT/'DPSMateX/DPSMateX_DataBuilder.lua').read_text(encoding='utf-8-sig')
bridge=builder[builder.index('DPSMateX.DB:SetScript("OnEvent"'):builder.index('DPSMateX.DB:SetScript("OnUpdate"')]
lua.execute('''
newCase()
DPSMateX.DB.scripts={}
function DPSMateX.DB:SetScript(name,fn) self.scripts[name]=fn end
CombatState=false
''')
lua.execute(bridge)
test('actual event bridge starts, classifies and records before legacy writes','''
npcClass="worldboss";npcName="Bridge Boss"
D.DB.SPELL_GO_SELF=function()
  assert(C.db.current.active and C.db.current.kind=="boss" and E.db.current.active)
  addCore(99,99,99)
  arg3="0xStranger";event="Nested script"
end
this=D.DB;event="SPELL_GO_SELF";arg1=0;arg2=9;arg3="0xA";arg4="0xE";arg5=0;arg6=1;arg7=0
D.DB.scripts.OnEvent()
assert(E.db.current.casts.PriestA.count==1 and C.db.current.name=="Bridge Boss")
now=14;CombatState=false;E:EndCombat();C:End()
assert(C.db.buckets.boss.fightCount==1 and C.db.buckets.boss.core.DMGDone[D.CacheUser.PriestA[1]].i==99)
''')
for addon in ('DPSMateX','DPSMateXExtend','DPSMateXExtendMore','DPSMateXInsights','DPSMateXEncounters'):
    for p in (ROOT/addon).rglob('*.lua'):
        # Legacy Lua 5.0 table-iterator syntax is accepted by loadstring for syntax QA.
        lua.execute('assert(loadstring(...))',p.read_text(encoding='utf-8-sig'))
toc=(ROOT/'DPSMateXEncounters/DPSMateXEncounters.toc').read_text(encoding='utf-8')
for name in toc.splitlines():
    if name and not name.startswith('##'): assert (ROOT/'DPSMateXEncounters'/name).is_file(), name
print('PASS: complete addon syntax and TOC load order')
