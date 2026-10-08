from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).parent / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ROOT = Path(r'E:\1.18\Interface\AddOns')
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
now=10
frames={}
UISpecialFrames={}
SlashCmdList={}
GameFontHighlightSmall={}
bit={}
function bit.band(a,b)
  local value,p=0,1
  while a>0 and b>0 do
    if math.mod(a,2)==1 and math.mod(b,2)==1 then value=value+p end
    a=math.floor(a/2);b=math.floor(b/2);p=p*2
  end
  return value
end
local F={};F.__index=F
function F:SetWidth(n) self.width=n end
function F:SetHeight(n) self.height=n end
function F:SetPoint(...) self.point={...} end
function F:ClearAllPoints() self.point=nil end
function F:GetName() return self.name end
function F:GetScale() return self.scale or 1 end
function F:SetScale(v) self.scale=v end
function F:SetText(v) self.value=v end
function F:GetText() return self.value or "" end
function F:SetTexture(v) self.texture=v end
function F:SetValue(v) self.barValue=v;if self.scripts.OnValueChanged then self:Fire("OnValueChanged",v) end end
function F:GetValue() return self.barValue or 0 end
function getglobal(name) return _G[name] end
function FauxScrollFrame_Update(f,count,visible,height) f.count=count;f.visibleRows=visible;f.rowHeight=height end
function FauxScrollFrame_GetOffset(f) return f.offset or 0 end
function FauxScrollFrame_OnVerticalScroll(height,callback) this.offset=math.floor(arg1/height+0.5);callback() end
function F:SetScript(event,fn) self.scripts[event]=fn end
function F:RegisterEvent(event) self.events[event]=true end
function F:UnregisterEvent(event) self.events[event]=nil end
function F:Show() self.visible=true end
function F:Hide() self.visible=false end
function F:IsShown() return self.visible end
function F:Fire(event,v)
  local previous,previousArg=this,arg1;this=self;arg1=v
  if self.scripts[event] then self.scripts[event]() end
  this=previous;arg1=previousArg
end
function F:CreateFontString() return CreateFrame("FontString",nil,self) end
function F:CreateTexture() return CreateFrame("Texture",nil,self) end
function F:ResetPie() self.pies={} end
function F:AddPie(percent,color,label) table.insert(self.pies,{percent=percent,label=label}) end
function F:ResetData() self.series={} end
function F:AddDataSeries(points,color) table.insert(self.series,{points=points,color=color}) end
function F:SetXAxis(a,b) self.xAxis={a,b} end
function F:SetYAxis(a,b) self.yAxis={a,b} end
for _,method in ipairs({"SetMinMaxValues","SetStatusBarTexture","SetStatusBarColor","SetJustifyH","SetBackdrop","SetBackdropColor","SetFrameStrata","SetMovable","EnableMouse",
  "SetFontObject","SetAutoFocus","SetTextInsets","SetHighlightTexture","EnableMouseWheel","StartMoving",
  "StopMovingOrSizing","ClearFocus","SetOwner","AddLine","SetGridColor","SetAxisDrawing","SetAxisColor",
  "SetAutoScale","SetYLabels","SetXLabels","SetGridSpacing","SetTextColor","SetClampedToScreen","SetAllPoints","RegisterForClicks"}) do F[method]=function() end end
function CreateFrame(kind,name,parent,template)
  local f=setmetatable({name=name or ("Anonymous"..table.getn(frames)),scripts={},events={},visible=true,parent=parent},F)
  table.insert(frames,f)
  if name then _G[name]=f end
  if template=="FauxScrollFrameTemplate" then
    f.scrollbar=CreateFrame("Slider",name.."ScrollBar",f)
    f.scrollbar:SetScript("OnValueChanged",function() f:Fire("OnVerticalScroll",arg1) end)
  end
  return f
end
UIParent=CreateFrame("Frame","UIParent")
GameTooltip=CreateFrame("Frame","GameTooltip")
function GetTime() return now end
function GetNampowerVersion() return 4,6,1 end
local names={A="PriestA",B="PriestB",T="Tank",E="Enemy",P="Pet",F="Friend"}
local spells={[1]="Power Word: Shield",[2]="Fire Ward",[3]="Frost Ward",[4]="Mana Shield",[5]="红月",
  [6]="Buff",[7]="Heal",[8]="Group Heal",[9]="Fireball",[10]="Pet Bite",[11]="Frostbolt",[12]="Power Word: Shield"}
function UnitName(guid)
  if guid==nameUnavailable then return nil end
  local alias=string.gsub(guid or "","^0x","")
  if alias=="player" then return "PriestA" end
  if alias=="Powner" then return "PriestA" end
  return names[alias]
end
function UnitClass(guid) return "Priest","PRIEST" end
function GetUnitGUID(guid)
  if guid=="0xPowner" then return "0xA" end
  if guid=="player" then return "0xA" end
end
function UnitIsFriend(player,guid) return guid~="0xE" end
function UnitCanAttack(player,guid) return guid=="0xE" end
function UnitAffectingCombat() return false end
function GetUnitField(guid,field)
  if field=="health" then return 500 end
  if field=="maxHealth" then return 1000 end
end
function GetSpellNameAndRankForId(id) return spells[id] end
function GetItemInfo(id) return "Potion" end
iconCalls={record=0,texture=0}
function GetSpellRecField(id,field)
  assert(field=="spellIconID");iconCalls.record=iconCalls.record+1;return 1000+id
end
function GetSpellIconTexture(id)
  iconCalls.texture=iconCalls.texture+1;return "Interface\\Icons\\SpellIcon"..id
end
DPSMateX={Settings={enabledmodes={damage=true},mergepets=true,datasegments=3,targetscale=0.58,
  windows={{options={{healingabsorbsactual=true},{currentfight=true}},CurMode="healingabsorbsactual"}}},
  DB={},Parser={TargetParty={["0xA"]="player",["0xB"]="party1",["0xT"]="party2",["0xF"]="party3"},player="0xA"},
  Options={Options={{args={}}}},CacheUser={},UserId={},AbilityId={},CacheAbility={},RegistredModules={},EnabledModules={},ModuleNames={},
  DPSMateXHistory={names={"Old fight"}},Registered=true,L={unknown="Unknown"}}
local D=DPSMateX
D.Options.graph={}
function D.Options.graph:CreateGraphLine(name,parent) error("Timeline graphs must not be created") end
function D.Options.graph:CreateGraphPieChart(name,parent) local f=CreateFrame("Pie",name,parent);f.pies={};return f end
function D:SendMessage(message) self.lastMessage=message end
function D:TContains(t,key) for k,v in pairs(t) do if k==key or v==key then return true end end return false end
function D:Register(id,module,name) self.RegistredModules[id]=module;self.ModuleNames[name]=id end
function D:EnableModule(id) self.EnabledModules[id]=true end
function D:ApplyFilter(key,name) return name~="FilteredOut" end
function D:GetClassColor(name) return 1,1,1,"priest" end
function D.DB:BuildUser(guid,class)
  local name=UnitName(guid) or guid
  if guid=="0xP" then name="Pet (PriestA)" end
  if not D.CacheUser[name] then
    local id=table.getn(D.UserId)+1;D.UserId[id]=name;D.CacheUser[name]={id,class}
  end
  return D.CacheUser[name][1],name
end
function D:GetUserById(id) return self.UserId[id] end
function D.DB:BuildAbility(spell)
  if not D.CacheAbility[spell] then
    local id=table.getn(D.AbilityId)+1;D.AbilityId[id]=spell;D.CacheAbility[spell]={id}
  end
  return D.CacheAbility[spell][1],D.CacheAbility[spell]
end
combat=false
function D.DB:IsCombatActive() return combat end
function D.DB:BeginInsightsCombat()
  if not combat then D.Insights:ResetCurrent();combat=true;D.Insights:StartCombat() end
end
function D.Options:ToggleDrewDrop(kind,id,parent)
  local window=D.Settings.windows[parent.Key]
  window.options[kind]={[id]=true}
  if kind==1 then window.CurMode=id end
end
D.Options.Dewdrop={GetOpenedParent=function() return {Key=1} end}
function D.Options.Dewdrop:Close() end
function fresh()
  combat=false;D.Insights:Reset();D.DPSMateXHistory.names={};D.Insights:AlignHistory()
  for _,id in pairs(D.Insights.ids) do D.EnabledModules[id]=true end
  D.Registered=true;now=10;D.Settings.mergepets=true;D.Insights.db.config.rawHealing=false
  D.Settings.windows[1].options[2]={currentfight=true}
end
function begin() combat=true;DPSMateX.Insights:StartCombat() end
function aura(id,caster,target,mask,duration)
  DPSMateX.Insights:OnEvent("AURA_CAST_ON_OTHER",id,caster,target,6,69,0,mask,duration or 30000,0)
end
function damage(target,school,amount)
  now=now+0.1
  DPSMateX.Insights:OnEvent("SPELL_DAMAGE_EVENT_OTHER",target,"0xE",9,0,tostring(amount)..",0,0",0,school,"2,0,0,0")
end
''')

for name in ('Core.lua', 'HealingStats.lua', 'Parser.lua', 'Modules.lua', 'Details.lua', 'HealingDetails.lua'):
    source = (ROOT / 'DPSMateXInsights' / name).read_text(encoding='utf-8-sig')
    lua.execute(source)

# Execute the actual core mode routing, rather than replacing it with the harness.
core = (ROOT / 'DPSMateX' / 'DPSMateX.lua').read_text(encoding='utf-8-sig')
route = core[core.index('function DPSMateX:GetMode(k)'):core.index('function DPSMateX:GetModeByArr')]
helper = core[core.index('function DPSMateX:NormalizeEncounterScope'):core.index('local nampower_events')]
lua.execute(helper)
lua.execute('local DPSMateX=DPSMateX; local strfind=string.find;local strsub=string.sub\n' + route)
lua.execute('DPSMateX.Insights:Initialize()')

def check(name, code):
    lua.execute('local D,E=DPSMateX,DPSMateX.Insights\n' + code)
    print('PASS:', name)

check('first-install modes, runtime version and old history placeholder', '''
assert(E.available and E.versionText=="4.6.1")
assert(D.EnabledModules.healingabsorbsactual and D.EnabledModules.spellcastsactual and D.EnabledModules.actionreplay)
assert(E.db.history[1].missing)
''')

check('pre-pull shield, partial/full absorbs, raw/effective healing, school masks', '''
fresh();aura(1,"0xA","0xT",127);begin()
damage("0xT",0,300);damage("0xT",4,200)
E:OnEvent("SPELL_HEAL_BY_OTHER","0xT","0xA",7,700,0,0)
local u=E.db.current.healing.PriestA
assert(u.absorb==500 and u.total==700 and u.effective==500)
assert(E:Value(u,"healing")==1000)
E.db.config.rawHealing=true;assert(E:Value(u,"healing")==1200)
assert(u.bins==nil and E.AddBin==nil)
fresh();aura(2,"0xA","0xT",4);begin();damage("0xT",4,100)
assert(E.db.current.unknown==100 and not E.db.current.healing.PriestA)
damage("0xT",2,120);assert(E.db.current.healing.PriestA.absorb==120)
''')

check('overlapping shields, no fixed capacity truncation, unknown/excluded conservation', '''
fresh();aura(1,"0xA","0xT",127);aura(3,"0xB","0xT",16);begin()
damage("0xT",4,1500);assert(E.db.current.unknown==1500)
damage("0xT",0,2000);assert(E.db.current.healing.PriestA.absorb==2000)
local credited=0;for name,u in pairs(E.db.current.healing) do if name~=E.UNKNOWN then credited=credited+u.absorb end end
assert(E.db.current.absorbed==credited+E.db.current.unknown+E.db.current.excluded)
fresh();aura(1,"0xA","0xT",127);aura(3,"0xA","0xT",16);begin();damage("0xT",4,250)
assert(E.db.current.healing.PriestA.skills["absorb:0"].absorb==250)
fresh();aura(5,"0xA","0xT",64);begin();damage("0xT",6,100)
assert(E.db.current.excluded==100 and E.db.current.unknown==0)
aura(1,"0xB","0xT",127);damage("0xT",6,50)
assert(E.db.current.unknown==50 and E.db.current.excluded==100)
''')

check('shield expiration, refreshed ranks, buff removal and death cleanup', '''
fresh();aura(1,"0xA","0xT",127,1000);begin();now=12;damage("0xT",0,100)
assert(E.db.current.unknown==100)
aura(1,"0xA","0xT",127);aura(12,"0xB","0xT",127);damage("0xT",0,90)
assert(E.db.current.healing.PriestB.absorb==90 and not E.shields["0xT"][1])
E:OnEvent("BUFF_REMOVED_OTHER","0xT",0,12,1,60,0,1);damage("0xT",0,50)
assert(E.db.current.unknown==150)
aura(1,"0xA","0xT",127);E:OnEvent("UNIT_DIED","0xT");assert(not E.shields["0xT"])
''')

check('one cast versus multiple heal results, HoT ticks, repeated valid casts, mirrored notification', '''
fresh();begin()
E:OnEvent("SPELL_GO_SELF",0,8,"0xA","0xT",0,3,0)
E:OnEvent("SPELL_HEAL_BY_SELF","0xT","0xA",8,200,0,0)
E:OnEvent("SPELL_HEAL_BY_SELF","0xF","0xA",8,200,0,0)
E:OnEvent("SPELL_HEAL_BY_SELF","0xA","0xA",8,200,0,0)
assert(E.db.current.casts.PriestA.count==1)
E:OnEvent("SPELL_HEAL_BY_SELF","0xT","0xA",8,20,0,1)
assert(E.db.current.casts.PriestA.count==1)
E:OnEvent("SPELL_GO_SELF",0,8,"0xA","0xT",0,3,0)
assert(E.db.current.casts.PriestA.count==2)
E:OnEvent("SPELL_GO_OTHER",0,8,"0xA","0xT",0,3,0)
assert(E.db.current.casts.PriestA.count==2)
E:OnEvent("SPELL_GO_SELF",0,8,"0xA","0xT",0,3,0)
assert(E.db.current.casts.PriestA.count==3)
''')

check('first hostile cast starts a segment and remains recorded; friendly pre-pull cast does not', '''
fresh();E:OnEvent("SPELL_GO_SELF",0,6,"0xA","0xT",0,1,0)
assert(not combat and not E.db.current.casts.PriestA)
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
assert(combat and E.db.current.casts.PriestA.count==1)
assert(E.db.current.playback.PriestA.count==1)
E:OnEvent("SPELL_GO_OTHER",0,9,"0xA","0xE",0,1,0)
assert(E.db.current.casts.PriestA.count==1)
''')

check('manual combat split continues timing and accounts for completed duration', '''
fresh();begin();now=12
E:SaveSegment("Split 1");table.insert(D.DPSMateXHistory.names,1,"Split 1")
E:ResetCurrent();assert(E.db.current.active and E.db.total.duration==2)
now=15;E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
local ev=E:RingValues(E.db.current.playback.PriestA.events,E.limits.perUser)[1]
assert(ev.t==3 and E.db.history[1].duration==2)
E:EndCombat();assert(E.db.total.duration==5)
''')

check('delayed unit name retries retain timestamps without repeating absorbs', '''
fresh();aura(1,"0xA","0xT",127);begin();nameUnavailable="0xP"
E:OnEvent("AUTO_ATTACK_OTHER","0xP","0xT",0,32,1,1,0,100,0)
assert(E.db.current.absorbed==100 and table.getn(E.pending)==1)
nameUnavailable=nil;now=10.5;E:FlushPending()
assert(E.db.current.absorbed==100 and table.getn(E.pending)==0)
local ev=E:RingValues(E.db.current.playback["Pet (PriestA)"].events,E.limits.perUser)[1]
assert(ev.t==0)
''')

check('group combat preflight starts before legacy data writes', '''
fresh()
local old=UnitAffectingCombat;UnitAffectingCombat=function(guid) return guid=="0xT" end
E:PrepareEvent("SPELL_HEAL_BY_SELF","0xT","0xA",7,100)
assert(combat and E.db.current.active)
E:OnEvent("SPELL_HEAL_BY_SELF","0xT","0xA",7,100,0,0)
assert(E.db.current.healing.PriestA.total==100)
UnitAffectingCombat=old
''')

check('pet/item source, toggleable pet merging, group isolation', '''
fresh();begin();E:OnEvent("SPELL_GO_OTHER",0,10,"0xP","0xE",0,1,0)
E:OnEvent("SPELL_GO_SELF",123,7,"0xA","0xA",0,1,0)
local sorted,total=E:Sorted(E.db.current,"casts",1)
assert(total==2 and table.getn(sorted)==1 and sorted[1].name=="PriestA")
D.Settings.mergepets=false;sorted,total=E:Sorted(E.db.current,"casts",1);assert(table.getn(sorted)==2)
assert(E.db.current.casts["Pet (PriestA)"].skills["pet:0:10"])
assert(E.db.current.casts.PriestA.skills["item:123:7"])
E:OnEvent("SPELL_GO_OTHER",0,9,"0xE","0xA",0,1,0)
assert(not E.db.current.casts.Enemy)
''')

check('spell/swing/death timeline, deterministic order and ring truncation', '''
fresh();begin()
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
E:OnEvent("AUTO_ATTACK_OTHER","0xA","0xE",0,16,0,1,0,0,0)
E:OnEvent("UNIT_DIED","0xE")
local u=E.db.current.playback.PriestA
assert(u.count==2 and u.events.count==3)
local list=E:RingValues(u.events,E.limits.perUser)
assert(list[1].kind=="cast" and list[2].kind=="swing" and list[3].kind=="death")
assert(list[1].seq<list[2].seq and list[2].seq<list[3].seq)
local ring={};for i=1,7 do E:Push(ring,i,3) end
local bounded=E:RingValues(ring,3);assert(bounded[1]==5 and bounded[2]==6 and bounded[3]==7 and ring.dropped==4)
''')

check('history deep copy, removal, alignment, current reset preserving pre-pull shields', '''
fresh();aura(1,"0xA","0xT",127);begin();damage("0xT",0,200)
now=15;E:EndCombat();combat=false
E:SaveSegment("New fight");table.insert(D.DPSMateXHistory.names,1,"New fight")
E:ResetCurrent();assert(E.shields["0xT"][1] and not E.db.current.healing.PriestA)
assert(E.db.history[1].healing.PriestA.absorb==200)
begin();damage("0xT",0,50);assert(E.db.history[1].healing.PriestA.absorb==200)
D.Settings.windows[1].options[2]={segment1=true}
local s,duration=D:GetMode(1);assert(s==E.db.history[1] and duration==5)
E:RemoveSegment(1);table.remove(D.DPSMateXHistory.names,1);assert(table.getn(E.db.history)==0)
D.Settings.windows[1].options[2]={total=true};local total=E:GetMode(1,"healing");assert(total==E.db.total)
local playback=E:GetMode(1,"playback");assert(playback.unsupported)
D.DPSMateXHistory.names={"Other older battle"};E:AlignHistory();assert(E.db.history[1].missing)
''')

check('module disable/enable and whole-plugin stop do not keep collecting', '''
fresh();begin();D.EnabledModules.healingabsorbsactual=nil
E:OnEvent("SPELL_HEAL_BY_SELF","0xT","0xA",7,200,0,0);assert(not E.db.current.healing.PriestA)
D.EnabledModules.spellcastsactual=nil
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
assert(not E.db.current.casts.PriestA and E.db.current.playback.PriestA.count==1)
D.Registered=false;E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
assert(E.db.current.playback.PriestA.count==1)
''')

check('per-user and per-fight limits preserve aggregate counts and report truncation', '''
fresh();begin();local oldUser,oldFight=E.limits.perUser,E.limits.perFight
E.limits.perUser=3;E.limits.perFight=4
for i=1,8 do now=now+0.1;E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0) end
E:OnEvent("SPELL_GO_OTHER",0,9,"0xB","0xE",0,1,0)
E:OnEvent("SPELL_GO_OTHER",0,11,"0xB","0xE",0,1,0)
assert(E.db.current.playback.PriestA.count==8 and E.db.current.playback.PriestA.events.count==3)
assert(E.db.current.stored==4 and E.db.current.dropped==6)
local list=E:RingValues(E.db.current.playback.PriestA.events,3)
assert(list[1].seq==6 and list[3].seq==8)
E.limits.perUser=oldUser;E.limits.perFight=oldFight
''')

check('compact healing overview, selection, targets, pie, comparison and playback filtering', '''
fresh();aura(1,"0xA","0xT",127);begin();damage("0xT",0,300)
E:OnEvent("SPELL_HEAL_BY_SELF","0xT","0xA",7,700,0,0)
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
E:OpenDetails("healing",nil,1)
local w=E.healingWindows[1];assert(w.visible and w.lineCount==1 and w.width==984 and w.height==450)
assert(w.statRows[1].average:GetText()=="500" and w.statRows[3].average:GetText()=="300" and not string.find(w.summary:GetText(),"HPS",1,true))
assert(w.viewButtons.graph==nil and E.DrawGraph==nil)
assert(w.search==nil and w.source==nil and w.targetType==nil and w.back==nil and w.refresh==nil)
assert(w.viewButtons.players==nil and w.viewButtons.skills==nil and w.viewButtons.targets==nil)
assert(w.statRows[1].percent.width==72 and w.statRows[1].average.width==64)
assert(w.statRows[1].percent.point[4]-(w.statRows[1].bar.point[4]+w.statRows[1].bar.width)==12)
w.rows[1]:Fire("OnClick");assert(w.person=="PriestA" and w.view=="skills")
assert(w.lineCount==2 and table.getn(w.pie.pies)==2)
w.rows[1]:Fire("OnClick");assert(w.view=="skills" and w.statRows[1].average:GetText()=="500")
w.raw:Fire("OnClick");assert(w.statRows[1].average:GetText()=="700")
w.rows[1]:Fire("OnClick","RightButton");assert(w.view=="targets" and w.rows[1].item.left=="Tank")
w.rows[1]:Fire("OnClick","RightButton");assert(w.view=="skills" and w.lineCount==2)
E:OpenDetails("healing","PriestA",1,true);assert(E.healingWindows[2].visible)
E:OpenDetails("playback","PriestA",1);assert(not w.visible);w=E.windows[1];assert(w.lineCount==1)
w.search:SetText("NoSuchSpell");w.search:Fire("OnTextChanged")
assert(w.rows[1].item.left=="没有匹配的数据")
w.search:SetText("");w.start:SetText("20");w.finish:SetText("10");E:Render(w)
assert(w.rows[1].item.left=="起始时间不能大于结束时间")
for _,row in ipairs(w.rows) do
  assert(row.width<=w.width and -row.point[5]+row.height<=w.height)
end
''')

check('empty healing window, bounded pie reuse and refresh update selected amounts', '''
fresh();E:OpenDetails("healing",nil,1)
local w=E.healingWindows[1]
assert(w.lineCount==0 and not w.rows[1]:IsShown() and w.statRows[1].count:GetText()==0)
begin();local u=E:User(E.db.current,"healing",{name="PriestA",class="priest",guid="0xA"})
for i=1,40 do
 local skill=E:Skill(u,"k"..i,"Heal"..i,7,"player")
 skill.total=i;skill.effective=i;skill.absorb=0;skill.count=1
 u.total=u.total+i;u.effective=u.effective+i;u.count=u.count+1
end
E:OpenDetails("healing","PriestA",1);assert(w.lineCount==40 and table.getn(w.pie.pies)==13)
local percent=0;for _,piece in ipairs(w.pie.pies) do percent=percent+piece.percent end;assert(math.abs(percent-100)<0.0001)
assert(w.previous==nil and w.next==nil and w.page==nil and w.scroll.visibleRows==11)
local framesBefore=table.getn(frames);local piesBefore=w.pie.pies
w:Fire("OnMouseWheel",-1);assert(w.offset==3 and w.rows[1].item.left=="Heal37")
w.scroll:Fire("OnVerticalScroll",w.scroll.rowHeight*8);assert(w.offset==8 and w.rows[1].item.left=="Heal32")
w.scroll.scrollbar:SetValue(w.scroll.rowHeight*10);assert(w.offset==10 and w.rows[1].item.left=="Heal30")
w:Fire("OnMouseWheel",100);assert(w.offset==0)
w:Fire("OnMouseWheel",-100);assert(w.offset==29 and w.rows[11].item.left=="Heal1")
w:Fire("OnMouseWheel",100);assert(w.offset==0)
w.rows[2]:Fire("OnClick");E:Render(w);assert(w.pie.pies==piesBefore and table.getn(frames)==framesBefore)
u.skills.k39.effective=88;u.skills.k39.total=88;E:Render(w)
assert(string.find(w.caption:GetText(),"Heal39",1,true) and w.statRows[4].average:GetText()=="88")
for _,p in ipairs({w.piePanel,w.listPanel,w.dataPanel}) do
 assert(p.point[4]+p.width<=w.width and -p.point[5]+p.height<=w.height)
end
for _,row in ipairs(w.rows) do assert(-row.point[5]+row.height<=w.listPanel.height) end
''')

check('older healing bins are released once without changing saved amounts', '''
local old=E.db
local u={name="PriestA",total=700,effective=500,absorb=300,count=2,bins={[0]={total=700,effective=500,absorb=300}},binCount=1,binsTruncated=true}
E.db={total={healing={PriestA=E:Copy(u)}},current={healing={PriestA=E:Copy(u)}},history={{healing={PriestA=E:Copy(u)}}}}
E:ReleaseHealingBins()
for _,s in ipairs({E.db.total,E.db.current,E.db.history[1]}) do
 assert(s.healing.PriestA.bins==nil and s.healing.PriestA.binCount==nil)
 assert(s.healing.PriestA.total==700 and s.healing.PriestA.effective==500 and s.healing.PriestA.absorb==300)
end
E.db=old
''')

check('same-name ranks and pet sources merge without losing target drilldown', '''
fresh();begin()
E:OnEvent("SPELL_GO_SELF",0,1,"0xA","0xT",0,1,0)
E:OnEvent("SPELL_GO_SELF",0,12,"0xA","0xT",0,1,0)
E:OnEvent("SPELL_GO_OTHER",0,12,"0xP","0xE",0,1,0)
E:OpenDetails("casts","PriestA",1)
local w=E.windows[1]
assert(w.lineCount==1 and w.rows[1].item.left=="Power Word: Shield")
assert(string.find(w.rows[1].item.right,"3",1,true))
w.rows[1]:Fire("OnClick")
assert(w.lineCount==2 and w.rows[1].item.left=="Tank")
assert(string.find(w.rows[1].item.right,"2",1,true))
w.view="skills";w.sourceIndex=2;E:Render(w)
assert(w.lineCount==1 and string.find(w.rows[1].item.right,"2",1,true))
''')

check('healing hit and crit outcomes survive rank, pet, target and multi-player merges', '''
fresh();begin()
E:Heal("0xA","0xT",1,300,0,0)
E:Heal("0xA","0xT",12,700,0,1)
E:Heal("0xP","0xF",12,200,0,0)
E:Heal("0xB","0xT",7,400,0,0)
E:OpenDetails("healing",nil,1)
local w=E.healingWindows[1]
assert(w.statRows[1].count:GetText()==3 and w.statRows[2].count:GetText()==1)
assert(w.statRows[1].min:GetText()=="200" and w.statRows[1].max:GetText()=="400")
assert(w.statRows[2].average:GetText()=="500" and w.statRows[2].percent:GetText()=="25.0%")
assert(not w.statRows[4].label:IsShown())
E:OpenDetails("healing","PriestA",1)
assert(w.lineCount==1 and w.selected.amounts.count==3)
assert(w.statRows[1].count:GetText()==2 and w.statRows[1].average:GetText()=="250")
assert(w.statRows[2].min:GetText()=="500" and w.statRows[2].max:GetText()=="500")
w.raw:Fire("OnClick")
assert(w.statRows[2].average:GetText()=="700" and w.statRows[2].min:GetText()=="700")
w.rows[1]:Fire("OnClick","RightButton")
assert(w.lineCount==2 and w.selected.left=="Tank")
assert(w.statRows[1].count:GetText()==1 and w.statRows[2].count:GetText()==1)
local count=0;for _ in pairs(E.db.current.healing.PriestA.outcomes) do count=count+1 end;assert(count==2)
-- Outcome summaries have fixed categories even when the event count keeps growing.
for i=1,2000 do E:Heal("0xA","0xT",1,100,0,0) end
count=0;for _ in pairs(E.db.current.healing.PriestA.outcomes) do count=count+1 end;assert(count==2)
assert(E.db.current.healing.PriestA.bins==nil)
''')

check('DBC icon IDs are resolved once and reused for spells and auras', r'''
local beforeRecord,beforeTexture=iconCalls.record,iconCalls.texture
assert(E:Icon(12,"Power Word: Shield")=="Interface\\Icons\\SpellIcon1012")
assert(E:Icon(12,"Power Word: Shield")=="Interface\\Icons\\SpellIcon1012")
assert(iconCalls.record==beforeRecord+1 and iconCalls.texture==beforeTexture+1)
assert(E:Icon(nil,nil,"swing") and E:Icon(nil,nil,"death"))
''')

check('replay target index drops evicted targets and keeps retained death references', '''
fresh();begin();local old=E.limits.perUser;E.limits.perUser=2
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xT",0,1,0)
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xF",0,1,0)
local u=E.db.current.playback.PriestA
assert(not E:ReplayTargetIndex(u)["0xE"])
E:OnEvent("UNIT_DIED","0xE");assert(E.db.current.seq==3)
E:OnEvent("UNIT_DIED","0xT");assert(E.db.current.seq==4 and u.count==3)
assert(E:ReplayTargetIndex(u)["0xT"]==1)
E.limits.perUser=old
''')

check('older replay rings migrate to lower limits while aggregate action counts survive', '''
fresh()
local oldUser,oldFight=E.limits.perUser,E.limits.perFight
E.limits.perUser=3;E.limits.perFight=4
local s=E.db.current
s.playback.A={count=5,events={}};s.playback.B={count=5,events={}}
for i=1,5 do
 E:Push(s.playback.A.events,{seq=i},2000)
 E:Push(s.playback.B.events,{seq=i+5},2000)
end
s.stored=10;E.db.replayLimit=nil;E.db.replayFightLimit=nil
E:MigrateReplayBounds()
assert(s.stored==4 and s.dropped==6)
assert(s.playback.A.count==5 and s.playback.B.count==5)
local a=E:RingValues(s.playback.A.events,3);local b=E:RingValues(s.playback.B.events,3)
assert(table.getn(a)==1 and a[1].seq==5 and table.getn(b)==3 and b[3].seq==10)
E.limits.perUser=oldUser;E.limits.perFight=oldFight
fresh();s=E.db.current;s.playback.A={count=2100,events={}}
for i=1,2100 do E:Push(s.playback.A.events,{seq=i},2000) end
s.stored=2000;s.dropped=100;E.db.replayLimit=nil;E.db.replayFightLimit=nil
E:MigrateReplayBounds();a=E:RingValues(s.playback.A.events,oldUser)
assert(table.getn(a)==500 and a[1].seq==1601 and a[500].seq==2100)
assert(s.stored==500 and s.dropped==1600 and s.playback.A.count==2100)
''')

check('distinct mode menu closures and replay automatically choosing current combat', '''
fresh();D.Settings.windows[1].options[2]={total=true}
D.Options.Options[1].args.actionreplay.set()
assert(D.Settings.windows[1].CurMode=="actionreplay" and D.Settings.windows[1].options[2].currentfight)
D.Options.Options[1].args.spellcastsactual.set();assert(D.Settings.windows[1].CurMode=="spellcastsactual")
''')

check('legacy detail-report adapters return ability IDs and stable totals', '''
fresh();begin();E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
E:OnEvent("SPELL_GO_SELF",0,11,"0xA","0xE",0,1,0)
local ids,total,values=E.modules.casts:EvalTable(D.CacheUser.PriestA,1)
assert(total==2 and table.getn(ids)==2 and type(ids[1])=="number" and values[1]==1)
assert(D.AbilityId[ids[1]] and D.AbilityId[ids[2]])
''')

check('target death snapshots accept boolean and numeric API results', '''
fresh();begin()
local saved=UnitIsDead
UnitIsDead=function() return 0 end
assert(not E:TargetSnapshot({},"0xE","0xA").dead)
UnitIsDead=function() return 1 end
assert(E:TargetSnapshot({},"0xE","0xA").dead)
UnitIsDead=function() return false end
assert(not E:TargetSnapshot({},"0xE","0xA").dead)
UnitIsDead=saved
''')

# Execute the actual event bridge, including legacy handlers changing global arguments.
builder = (ROOT / 'DPSMateX' / 'DPSMateX_DataBuilder.lua').read_text(encoding='utf-8-sig')
bridge = builder[builder.index('DPSMateX.DB:SetScript("OnEvent", function()'):builder.index('function DPSMateX.DB:IsCombatActive()')]
lua.execute('function DPSMateX.DB:SetScript(kind,fn) self[kind]=fn end\n' + bridge)
check('actual core event bridge starts combat before legacy handling and preserves payload', '''
fresh()
D.DB.SPELL_GO_SELF=function(first)
  assert(combat and E.db.current.active and first==0)
  event="UNIT_DIED";arg1="0xT";arg2=999;arg3="0xB";arg4="0xT"
end
this=D.DB;event="SPELL_GO_SELF"
arg1=0;arg2=9;arg3="0xA";arg4="0xE";arg5=0;arg6=1;arg7=0;arg8=nil;arg9=nil
D.DB.OnEvent()
assert(E.db.current.casts.PriestA.count==1 and not E.db.current.casts.PriestB)
local records=E:RingValues(E.db.current.playback.PriestA.events,E.limits.perUser)
assert(records[1].spellId==9 and records[1].targetGuid=="0xE")
this=nil
''')

check('older Nampower versions stop collection without changing saved totals', '''
fresh();begin()
local saved=GetNampowerVersion
GetNampowerVersion=function() return 4,4,9 end
E:Initialize();assert(not E.available)
E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0)
assert(not E.db.current.casts.PriestA)
GetNampowerVersion=saved;E:Initialize();assert(E.available)
''')

# Recreate the extension after a reload with persisted data and configuration.
check('save/reload semantics and preservation of disabled modes', '''
fresh();begin();E:OnEvent("SPELL_GO_SELF",0,9,"0xA","0xE",0,1,0);now=13
E.db.current.duration=E:Duration(E.db.current)
D.Settings.enabledmodes.actionreplay=nil
''')
for name in ('Core.lua', 'HealingStats.lua', 'Parser.lua', 'Modules.lua', 'Details.lua', 'HealingDetails.lua'):
    lua.execute((ROOT / 'DPSMateXInsights' / name).read_text(encoding='utf-8-sig'))
lua.execute('DPSMateX.EnabledModules={};DPSMateX.Insights:Initialize()')
check('reloaded current data, monotonic offset, and no invented active shields', '''
assert(E.db.current.casts.PriestA.count==1 and E.db.current.duration==3)
assert(not E.db.current.active and next(E.shields)==nil)
assert(not D.EnabledModules.actionreplay)
now=20;E:StartCombat();now=22;assert(E:Duration(E.db.current)==5)
''')

for name in ('DPSMateX.lua', 'DPSMateX_DataBuilder.lua', 'DPSMateX_Options.lua'):
    lua.execute('assert(loadstring(...))', (ROOT / 'DPSMateX' / name).read_text(encoding='utf-8-sig'))
print('PASS: modified core Lua syntax')
