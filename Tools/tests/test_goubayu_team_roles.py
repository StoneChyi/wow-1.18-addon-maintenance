"""Offline execution of actual GoubayuHeal role-consumer functions, not live client QA."""
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime
root=Path(__file__).resolve().parents[2]/'Interface/AddOns'
core=(root/'GoubayuHeal/GoubayuHeal.lua').read_text(encoding='utf-8-sig')
def fn(name):
 start=core.index('function GoubayuHeal.'+name+'(')
 return core[start:core.index('\nend\n',start)+5]
lua=LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
now=0; calls=0;warnings=0
units={player={name='Self',health=5},raid1={name='A',health=10},raid2={name='B',health=20}}
function GetTime() return now end
function UnitName(u) return units[u] and units[u].name end
function UnitExists(u) return units[u]~=nil end
function UnitIsFriend(_,u) return units[u] and not units[u].enemy end
function UnitIsDeadOrGhost(u) return units[u] and units[u].dead end
function UnitIsConnected(u) return units[u] and not units[u].offline end
function GetNumRaidMembers() return 2 end
function GetNumPartyMembers() return 0 end
DEFAULT_CHAT_FRAME={AddMessage=function() warnings=warnings+1 end}
function callable(t) return setmetatable(t,{__call=function(t,_,k)return next(t,k)end}) end
GoubayuHeal={Config={rescue_hp_threshold=40,raid_roles={A='MT',B='8T'},classes={test=callable({})}},Tank={}}
GoubayuHeal.UnitName=UnitName
function GoubayuHeal.GetUnitID(name) for u,d in pairs(units)do if d.name==name then return u end end end
function GoubayuHeal.GetUnitHealth(u) return units[u].health,100 end
function GoubayuHeal.HealUsingClass(u) calls=calls+1;lastUnit=u;return 1 end
''')
lua.execute((root/'!Libs/SC_TeamRoles.lua').read_text(encoding='utf-8-sig'))
for name in ['UnitIsOffline','IsMT','IsProtectedTank','ResolveTankTarget','TankInRescue','TankHealProfile']:
 lua.execute(fn(name))
lua.execute('''
assert(not GoubayuHeal.IsMT('raid1'))
assert(GoubayuHeal.ResolveTankTarget()==nil)
assert(not GoubayuHeal.TankInRescue())
assert(GoubayuHeal.TankHealProfile('test')==nil and calls==0 and warnings==1)
assert(GoubayuHeal.TankHealProfile('test')==nil and calls==0 and warnings==1)
SC_TeamRolesProvider={apiVersion=1,GetRole=function(self,u)
 if u=='raid1' then return 'TANK',2,'test' elseif u=='raid2' then return 'TANK',1,'test' end end}
assert(GoubayuHeal.ResolveTankTarget()=='raid2' and GoubayuHeal.Tank.Name==nil)
now=1;assert(GoubayuHeal.TankInRescue())
SC_TeamRolesProvider.GetRole=function(self,u) if u=='raid2' then return 'HEALER' end end
now=2;assert(not GoubayuHeal.TankInRescue())
GoubayuHeal.Tank={Name='A',Unit='raid1'}
assert(GoubayuHeal.ResolveTankTarget()=='raid1')
now=3;assert(GoubayuHeal.TankInRescue())
units.raid1.offline=true
assert(GoubayuHeal.ResolveTankTarget()==nil and GoubayuHeal.Tank.Name==nil)
local old=calls;assert(GoubayuHeal.TankHealProfile('test')==nil and calls==old)
units.raid1.offline=false;units.raid1.dead=true;GoubayuHeal.Tank={Name='A'}
assert(GoubayuHeal.ResolveTankTarget()==nil)
units.raid1.dead=false;units.raid1.enemy=true;GoubayuHeal.Tank={Name='A'}
assert(GoubayuHeal.ResolveTankTarget()==nil)
units.raid1.enemy=false;GoubayuHeal.Tank={Name='A'}
assert(GoubayuHeal.TankHealProfile('test')==1 and calls==old+1)
assert(GoubayuHeal.Config.raid_roles.A=='MT' and GoubayuHeal.Config.classes.test_Tank==nil)
''')
print('GoubayuHeal: stale roles inert, shared tank order, rescue parity, manual focus, invalid focus and strict no-target guards passed.')
lua.execute('''
function UnitIsUnit(a,b)return a==b end
function UnitInParty()return false end
function UnitInRaid()return true end
function GoubayuHeal_GetClassPower()return 'PRIEST',0 end
GoubayuHeal.Config.class_priority={}
GoubayuHeal.Config.MT_priority=8
GoubayuHeal.Config.buff_affect_priority=callable({})
GoubayuHeal.Config.debuff_affect_priority=callable({})
SC_TeamRolesProvider=nil
''')
lua.execute(fn('GetPriority'))
lua.execute('''
assert(GoubayuHeal.GetPriority('raid1')==0.5)
SC_TeamRolesProvider={apiVersion=1,GetRole=function()return 'TANK',2 end}
assert(GoubayuHeal.GetPriority('raid1')==7.5)
SC_TeamRolesProvider.GetRole=function()return 'TANK',1 end
assert(GoubayuHeal.GetPriority('raid1')==8.5)
SC_TeamRolesProvider.GetRole=function()return 'DAMAGER' end
assert(GoubayuHeal.GetPriority('raid1')==0.5)
''')
print('GoubayuHeal actual GetPriority: unknown/old-role neutral, shared primary/secondary tank weighting, known non-tank neutral passed.')
