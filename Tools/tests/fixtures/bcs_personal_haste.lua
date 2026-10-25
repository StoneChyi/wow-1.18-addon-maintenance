
function Near(actual,expected,label) assert(math.abs(actual-expected)<0.00000001,label..' actual='..actual..' expected='..expected) end
gear={[1]={{'+1% 急速'}},[2]={{'+1% 急速'}}};buffs={}
Near(BCS:GetLiveHaste(),2.01,'independent 1% gear factors multiply')
gear={[1]={{'+1% 急速'}},[2]={{'+2% 急速'}},[3]={{'+3% 急速'}}}
Near(BCS:GetLiveHaste(),6.1106,'three independent gear effects use product minus one')
gear={};buffs={{{'buff A'},{'急速提高2%。'}},{{'buff B'},{'急速提高3%。'}}}
Near(BCS:GetLiveHaste(),5.06,'separate auras with identical patterns both count')
buffs={{{'buff A'},{'急速提高3%。'},{'攻击和施法速度提高3%。'}}}
Near(BCS:GetLiveHaste(),3,'one aura is not duplicated across matching descriptions')
-- Color-aware actual tooltip fixture for active and inactive set bonuses.
local tooltip=CreateFrame('GameTooltip','Fixture')
local originalSet=tooltip.SetInventoryItem
function tooltip:SetInventoryItem(unit,slot)
 local has=originalSet(self,unit,slot)
 for line,row in ipairs(gear[slot] or {}) do
  local color=row[3] or {0,1,0}
  local font=getglobal('BetterCharacterStatsTooltipTextLeft'..line)
  font.GetTextColor=function() return unpack(color) end
 end
 return has
end
local function Set(name,value,active)
 return {{name},{'套装：使你的攻击速度和施法速度提高'..value..'%。',nil,active and {0,1,0} or {.5,.5,.5}}}
end
gear={[1]=Set('Set A（2/2）',2,true),[2]=Set('Set B（2/2）',3,true),
 [3]=Set('Set B（2/2）',3,true),[4]=Set('Set C（2/2）',4,false),
 [5]=Set('Set A（2/2）',2,true),[6]=Set('Set A（2/2）',5,true)}
buffs={}
Near(BCS:GetLiveHaste(),(1.02*1.03*1.05-1)*100,'unique active set bonuses, including a second distinct bonus')
BCS:BeginEquipmentRead()
Near(BCS:GetLiveHaste(),(1.02*1.03*1.05-1)*100,'snapshot retains active/inactive status')
BCS:EndEquipmentRead()
gear={[1]=Set('Set A(10/10)',2,true)}
Near(BCS:GetLiveHaste(),2,'ASCII set headers and multi-digit set counts')
-- Read the actual Crusader Strike tooltip rather than assuming a fixed amount.
local originalCreate=CreateFrame
local made=0
perStack=3
local spellMissing=false
function GetSpellName(index) if index==1 and not spellMissing then return '十字军打击' end end
function GetPlayerBuffApplications(index) return stacks or 3 end
function CreateFrame(kind,name,...)
 if name~='BCSZealSpellTooltip' then return originalCreate(kind,name,unpack(arg)) end
 made=made+1
 local tt={}
 function tt:SetOwner() end
 function tt:ClearLines() end
 function tt:Hide() end
 function tt:NumLines() return 2 end
 function tt:SetSpell()
  _G[name..'TextLeft1']={GetText=function() return '十字军打击' end}
  _G[name..'TextLeft2']={GetText=function()
   return spellDescription or '一次攻击，造成100%的武器伤害外加161点伤害，并使你的攻击速度提高|cff00ff00'..perStack..'%|r。持续30秒。最多可叠加3次。'
  end}
 end
 return tt
end
gear={[1]={{'+1% 急速'}},[2]={{'+1% 急速'}}}
for n=1,3 do
 stacks=n
 buffs={{{'狂热'},{'攻击和施法速度提高'..3*n..'%。'}}}
 Near(BCS:GetLiveHaste(),(1.01*1.01*(1+.03*n)-1)*100,'untalented Zeal uses total correctly')
end
stacks=3;perStack=5
buffs={{{'狂热'},{'攻击和施法速度提高9%。'}}}
Near(BCS:GetLiveHaste(),17.3115,'talented per-stack 5% overrides stale 9% aura tooltip')
perStack=3
Near(BCS:GetLiveHaste(),11.1909,'talent reset is reflected without stale skill cache')
spellMissing=true
Near(BCS:GetLiveHaste(),11.1909,'missing skill safely uses already-stacked aura magnitude')
assert(made==1,'skill tooltip reused')
spellMissing=false;stacks=3;perStack=5;gearReads=0;buffReads=0
BCS:BeginEquipmentRead()
Near(BCS:GetLiveHaste(),17.3115,'batch formula')
Near(BCS:GetLiveHaste(),17.3115,'batch reuse')
assert(gearReads==20 and buffReads==1,'equipment and auras scanned once per existing batch')
BCS:EndEquipmentRead()


gear={};perStack=3;stacks=3
buffs={{{'狂热'},{'攻击和施法速度提高9%。'}},{{'施法增益'},{'施法速度提高20%。'}}}
Near(BCS:GetLiveHaste('melee'),9,'melee formula excludes casting-only auras')
Near(BCS:GetLiveHaste(),30.8,'legacy casting/general formula retains casting aura')
BCS.ForceCalculate=true;BCS:InvalidateHasteCache();now=10
Near(BCS:GetCalculatedMeleeHaste(),9,'melee formula cache')
Near(BCS:GetHaste(),30.8,'casting/general cache independent of melee cache')
stacks=2;buffs[1][2][1]='攻击和施法速度提高6%。';now=10.1;BCS:InvalidateHasteCache()
Near(BCS:GetCalculatedMeleeHaste(),6,'aura change invalidates melee formula cache')
Near(BCS:GetHaste(),27.2,'aura change invalidates legacy cache independently')
perStack=5;now=12.2
Near(BCS:GetCalculatedMeleeHaste(),10,'talent changes update per-stack value on cache expiry')


-- Exact sentence supplied by the user is already covered by the parser.
spellDescription='使你的攻击速度提高3%'
Near(BCS:GetZealHastePerStack(),3,'exact user skill sentence is supported')
function GetSpellName() return nil end
local value,reason=BCS:GetZealHastePerStack()
assert(value==nil and string.find(reason,'未找到',1,true),'diagnostics distinguish missing skill from unmatched text')
function GetSpellName(index) if index==1 then return '十字军打击' end end
spellDescription='技能提示没有速度百分比'
value,reason=BCS:GetZealHastePerStack()
assert(value==nil and string.find(reason,spellDescription,1,true),'failed parse returns actual captured spell text')
