-- Append to the actual bridge and complete QuickHeal core in one test chunk.

QHV={RatioForceself=.4,RatioFull=.9,TargetPriority=true,PetPriority=0,SmartStopCasting=false,DebugMode=false}
QuickHealVariables=QHV
QuickHeal_debug=function()end
QuickHeal_UnitHasHealthInfo=function(u)return units[u]~=nil end
UnitFullName=function(u)return u end
UnitIsHealable=function(u)return units[u]~=nil end
UnitHasRenew=function() return false end
UnitHasRejuvenation=function() return false end
QuickHeal_GetSpellInfo=function()return {{SpellID=1}} end
QH_NoticeRoleListRemoved();QH_NoticeRoleListRemoved();assert(notices==1)
local actions={QuickHeal,QuickHOT,QuickChainHeal}
for _,action in ipairs(actions) do
 for _,mode in ipairs({'mt','nonmt','MT','NONMT'}) do action(mode,1) end
end
assert(casts==0 and stops==0 and cvarReads==0 and cvarWrites==0)
assert(QH_FindWhoToHOT('mt')==nil and cvarReads==0)
assert(FindWhoToHeal('mt')==nil and FindWhoToHOT('nonmt')==nil)
SC_TeamRolesProvider={apiVersion=1,GetRole=function()error('bad provider')end}
for _,mode in ipairs({'mt','nonmt'}) do
 assert(FindWhoToHeal(mode)==nil and FindWhoToHOT(mode)==nil)
end
assert(casts==0 and stops==0)
local roles={raid1='TANK',raid2='HEALER'}
SC_TeamRolesProvider.GetRole=function(self,u)return roles[u]end
assert(FindWhoToHeal('mt')=='raid1')
assert(FindWhoToHeal('nonmt')=='raid2')
assert(FindWhoToHOT('mt')=='raid1')
assert(FindWhoToHOT('nonmt')=='raid2')
assert(QH_FindWhoToHOT('MT')=='raid1' and QH_FindWhoToHOT('NONMT')=='raid2')
assert(FindWhoToHeal(nil)=='player' and FindWhoToHOT(nil)=='player')
assert(RoleMatches('target','mt')==false and RoleMatches('raid3','nonmt')==false)
local selected={};ExecuteHeal=function(u)table.insert(selected,u)end;ExecuteHOT=ExecuteHeal
for _,action in ipairs(actions) do
 action('mt',1);assert(selected[table.getn(selected)]=='raid1')
 action('nonmt',1);assert(selected[table.getn(selected)]=='raid2')
end
assert(table.getn(selected)==6)
print('PASS QH: complete main loaded; absent/error/mixed provider, mt/nonmt/uppercase, early self/target bypass, unknown exclusion, 3 healing entries, ordinary self preservation, retired notice idempotence')

Message=function() end
for _,u in ipairs({'raid1','raid2','raid3'}) do units[u].hp=1000 end
local count=table.getn(selected)
for _,action in ipairs(actions) do action('mt',1);action('nonmt',1) end
assert(table.getn(selected)==count)
SC_TeamRolesProvider.GetRole=function()error('broken provider')end
for _,action in ipairs(actions) do action('mt',1);action('nonmt',1) end
assert(table.getn(selected)==count and casts==0)
HasUnitXP=false
assert(FindWhoToHeal('mt')==nil and FindWhoToHOT('nonmt')==nil)
for _,action in ipairs(actions) do action('mt',1);action('nonmt',1) end
assert(table.getn(selected)==count and casts==0)
SC_TeamRolesProvider.GetRole=function(self,u)return roles[u]end
roles.raid1='TANK'
FindWhoToHeal=function() roles.raid1=nil;return 'raid1' end
QuickHeal('mt',1);assert(table.getn(selected)==count and casts==0)
print('PASS QH empty-role/full-health diagnostics on all 3 entries, provider failures, no-DLL calibration guard, and final role-change recheck')
