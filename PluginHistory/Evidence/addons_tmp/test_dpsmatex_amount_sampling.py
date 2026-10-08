from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).parent/'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
from refactor_compact_details import ROOT,methods
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
DPSMateX={DB={},Options={},DBCache={},Settings={},DPSMateXHistory={},IgnoredDamage={},EnabledModules={damagetaken=true,enemydamagedone=true,healing=true,effectivehealing=true,overhealing=true},
HasHealingModules={[0]=true,[1]=true,[2]=true},Temp={ActiveMob={}}}
local D=DPSMateX
CombatState=true;cheatCombat=0;tablemodes={[1]="total",[2]="current"};strsub=string.sub
function GT() return 10 end
function D.DB:BuildAbility(name) return name end
function D.DB:BuildUser(name) return name,name end
function D:GetAbilityById(name) return name end
function D.DB:CheckActiveCC() end
D.DB.NextSwingEDD={}
for _,name in ipairs({"DamageDone","DamageTaken","EDD","EDT","THealing","EHealing","Overhealing","HealingTaken","EHealingTaken","OverhealingTaken"}) do D.DBCache[name]={{},{}} end
''')
source=(ROOT/'DPSMateX/DPSMateX_DataBuilder.lua').read_text(encoding='utf-8-sig')
for a,b,name in methods(source):
    if name in {'DamageDone','DamageTaken','EnemyDamage','Healing','HealingTaken'}:lua.execute(source[a:b])
lua.execute('''
local D,db=DPSMateX,DPSMateX.DB
for i=1,2000 do
 db:DamageDone("Player","Hit",1,0,0,0,0,0,100,0,0,"Enemy")
 db:DamageTaken("Player","Hit",1,0,0,0,0,0,100,"Enemy",0,0)
 db:EnemyDamage(false,D.DBCache.EDD,"Player","Hit",1,0,0,0,0,0,100,"Enemy",0,0)
 db:EnemyDamage(true,D.DBCache.EDT,"Player","Hit",1,0,0,0,0,0,100,"Enemy",0,0)
 for mode,name in pairs({[0]="EHealing",[1]="THealing",[2]="Overhealing"}) do db:Healing(mode,D.DBCache[name],"Player","Heal",1,0,150) end
 for mode,name in pairs({[0]="EHealingTaken",[1]="HealingTaken",[2]="OverhealingTaken"}) do db:HealingTaken(mode,D.DBCache[name],"Player","Heal",1,0,150,"Tank") end
end
for mode=1,2 do
 local done=D.DBCache.DamageDone[mode].Player
 assert(done.i==200000 and done.Hit[1]==2000 and done.Hit[2]==100 and done.Hit[3]==100 and done.Hit[4]==200000 and done.Hit[13]==200000 and done.Hit.i==nil)
 local taken=D.DBCache.DamageTaken[mode].Player
 assert(taken.i==200000 and taken.Enemy.Hit[13]==200000 and taken.Enemy.Hit.i==nil)
 for _,name in ipairs({"EDD","EDT"}) do local row=D.DBCache[name][mode].Enemy.Player;assert(row.i==200000 and row.Hit[13]==200000 and row.Hit.i==nil) end
 for _,name in ipairs({"THealing","EHealing","Overhealing"}) do local row=D.DBCache[name][mode].Player;assert(row.i==300000 and row.Heal[1]==300000 and row.Heal[2]==2000 and row.Heal[4]==300000 and row.Heal[6]==150 and row.Heal[7]==150 and row.Heal.i==nil) end
 for _,name in ipairs({"HealingTaken","EHealingTaken","OverhealingTaken"}) do local row=D.DBCache[name][mode].Player;assert(row.i==300000 and row.Tank.Heal[1]==300000 and row.Tank.Heal.i==nil) end
end
''')
print('PASS: 20,000 actual legacy amount writes preserve totals/counts/min/max without time samples')

core=(ROOT/'DPSMateX/DPSMateX.lua').read_text(encoding='utf-8-sig')
for a,b,name in methods(core):
    if name=='ReleaseDetailTimelines':lua.execute(core[a:b])
lua.execute('''
local D=DPSMateX
D.DBCache.DamageDone[1].Player.Hit.i={[1]=100,[2]=200}
D.DBCache.HealingTaken[2].Player.Tank.Heal.i={[1]=150}
D.DPSMateXHistory.DMGDone={{Player={i=300,Hit={[13]=300,i={[1]=100,[2]=200}}}}}
D.DPSMateXHistory.Absorbs={{event={i={"absorb event"}}}}
D.DBCache.Deaths={{event={i={"death event"}}}}
D:ReleaseDetailTimelines()
assert(D.DBCache.DamageDone[1].Player.Hit.i==nil and D.DBCache.DamageDone[1].Player.i==200000)
assert(D.DBCache.HealingTaken[2].Player.Tank.Heal.i==nil)
assert(D.DPSMateXHistory.DMGDone[1].Player.i==300 and D.DPSMateXHistory.DMGDone[1].Player.Hit[13]==300)
assert(D.DPSMateXHistory.DMGDone[1].Player.Hit.i==nil)
assert(D.DBCache.Deaths[1].event.i[1]=="death event" and D.DPSMateXHistory.Absorbs[1].event.i[1]=="absorb event")
assert(D.Settings.compactDetailsVersion==1)
''')
print('PASS: one-time migration removes old skill samples while preserving parent totals and event histories')

lua.execute('DPSMateX.Sync={}')
sync=(ROOT/'DPSMateX/DPSMateX_Sync.lua').read_text(encoding='utf-8-sig')
for a,b,name in methods(sync):
    if name in {'DMGDoneStatOut','DMGTakenStatOut','EDStatOut','HealingStatOut','HealingTakenStatOut'}:lua.execute(sync[a:b])
lua.execute('''
for _,name in ipairs({"DMGDoneStatOut","DMGTakenStatOut","EDStatOut","HealingStatOut","HealingTakenStatOut"}) do
 DPSMateX.Sync[name](DPSMateX.Sync) -- Safe even with no sync buffer or per-second data.
end
''')
print('PASS: amount timeline sync no longer sorts or constructs outgoing time packets')
