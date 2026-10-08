"""Offline behavior checks for hyx, with WoW 1.12-style event globals."""
from pathlib import Path
import ast
import sys

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE / 'bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ROOT = HERE.parent / 'Interface' / 'AddOns' / 'hyx'
# Reuse the existing frame simulator without importing/running its test suite.
tree = ast.parse((HERE / 'test_srti_tools.py').read_text(encoding='utf-8-sig'))
BASE = next(ast.literal_eval(n.value) for n in tree.body
            if isinstance(n, ast.Assign) and any(isinstance(t, ast.Name) and t.id == 'MOCK' for t in n.targets))
MOCK = r'''
local O = getmetatable(UIParent).__index
function O:EnableMouseWheel(v) self.wheel=v end
function O:SetOwner(owner) self.owner=owner end
function O:IsOwned(owner) return self.owner==owner end
function O:ClearLines() end
function O:SetUnitDebuff(unit,index)
 local aura=units[unit] and units[unit].auras[index]
 XinTooltipScannerTextLeft1:SetText(aura and aura.name)
end
function O:SetAutoFocus() end
function O:SetValueStep() end
function O:SetJustifyV() end
function O:SetMultiLine() end
function O:SetFontObject() end
function O:SetMaxLetters() end
function O:SetTextInsets() end
function O:EnableKeyboard() end
function O:SetScrollChild() end
function O:GetPoint() return 'CENTER',UIParent,'CENTER',30,-40 end
function O:AddLine() end
function O:RegisterEvent(name) self.events=self.events or {}; self.events[name]=true end
local oldCreate=CreateFrame
function CreateFrame(kind,name,parent,template)
 local f=oldCreate(kind,name,parent,template)
 if name and template then
  for _,suffix in ipairs({'Text','Low','High','TextLeft1'}) do
   if not _G[name..suffix] then oldCreate('FontString',name..suffix,f) end
  end
 end
 return f
end
function UIDropDownMenu_SetWidth() end
function UIDropDownMenu_SetText(text,frame) frame.text=text end
function UIDropDownMenu_GetText(frame) return frame.text end
function UIDropDownMenu_CreateInfo() return {} end
function FauxScrollFrame_Update() end
function FauxScrollFrame_GetOffset() return 0 end
function FauxScrollFrame_OnVerticalScroll() end
WorldFrame=UIParent
BOOKTYPE_SPELL='spell'; BOOKTYPE_PET='pet'
RAID_CLASS_COLORS={}
for _,class in ipairs({'WARRIOR','ROGUE','HUNTER','MAGE','PRIEST','DRUID','SHAMAN','PALADIN','WARLOCK'}) do
 RAID_CLASS_COLORS[class]={r=1,g=1,b=1}
end
books={spell={},pet={}}; casts={}; playerClass='PALADIN'; shift=false
function GetSpellName(slot,book) return books[book][slot] end
function GetSpellCooldown(slot,book)
 local cd=cooldown or {}; return cd.start or 0,cd.duration or 0,cd.enabled or 1
end
function IsSpellUsable() if oom then return nil,1 end; return 1,nil end
function IsSpellInRange(name,unit) return units[unit].nativeRange end
function UnitClass(unit) local c=(unit=='player' and playerClass) or 'WARRIOR'; return c,c end
function UnitIsConnected(unit) return units[unit] and not units[unit].offline end
function UnitIsDeadOrGhost(unit) return units[unit] and units[unit].dead end
function UnitIsFriend(a,b) return units[b] and not units[b].hostile end
function UnitCanAttack(a,b) return units[b] and units[b].hostile end
function UnitIsUnit(a,b) return units[a] and units[b] and units[a].name==units[b].name end
function UnitDebuff(unit,index)
 local a=units[unit] and units[unit].auras[index]
 if a then return a.texture or 'icon',a.stacks or 1,a.kind end
end
function UnitXP(command,source,unit)
 if xpError then error('DLL not loaded') end
 if command=='distanceBetween' then
  xpSource=source; return units[unit] and units[unit].distance
 end
 if command=='inSight' then return units[unit].sight end
end
function IsShiftKeyDown() return shift end
function CastSpellByName(name,unit) table.insert(casts,{name=name,unit=unit}) end
function TargetUnit(unit) lastTarget=units.target; units.target=units[unit] end
function TargetLastTarget() units.target=lastTarget end
function ClearTarget() units.target=nil end
function CastSpell(slot,book) table.insert(casts,{name=books[book][slot],unit=units.target.name}); targeting=true end
function SpellIsTargeting() return targeting end
function SpellTargetUnit(unit) resolved=unit; targeting=false end
function SpellStopTargeting() targeting=false end
function AddUnit(unit,name,kind,distance)
 units[unit]={name=name,auras=kind and {{name='Debuff-'..kind,kind=kind}} or {},distance=distance or 10,sight=true}
end
function FireEvent(name)
 local snapshot={}; for _,f in ipairs(frameObjects) do table.insert(snapshot,f) end
 for _,f in ipairs(snapshot) do
  if f.events and f.events[name] and f.scripts.OnEvent then
   event=name; this=f; arg1='player'; f.scripts.OnEvent()
  end
 end
end
function Tick() this=nil; arg1=.3
 for _,f in ipairs(frameObjects) do if f.scripts.OnUpdate then this=f; f.scripts.OnUpdate() end end
end
AddUnit('player','Self',nil,0)
xinDB={maxInRange=5,maxOutRange=5,enableOutRange=true,IgnoreList={},RaidSettings={}}
SUPERWOW_VERSION='test'
'''

def world(full=True):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(BASE)
    lua.execute(MOCK)
    lua.execute((ROOT / 'XinDispel.lua').read_text(encoding='utf-8-sig'))
    if full:
        lua.execute((ROOT / 'hyx.lua').read_text(encoding='utf-8-sig'))
    lua.execute("FireEvent('VARIABLES_LOADED'); books.spell={'清洁术'}; Tick()")
    return lua

passed = 0
def check(name, code, lua=None):
    global passed
    (lua or world()).execute(code)
    passed += 1
    print('PASS', name)

check('full addon initializes, original settings and roster UI', '''
assert(XinSettingFrame and XinRaidFrame and XinIgnoreFrame)
SlashCmdList.XINLOAD(''); assert(XinSettingFrame:IsShown())
UpdateXinListFrame(); SlashCmdList.XINLOAD('status')
assert(SLASH_XINLOAD2=='/xin' and SLASH_XINLOAD3=='/hyx')
''')
check('all nine classes and actually learned abilities', '''
local cases={
 {'PALADIN',{'清洁术'},'Magic','Poison','Disease'},
 {'PRIEST',{'驱散魔法','祛病术'},'Magic','Disease'},
 {'DRUID',{'解除诅咒','驱毒术'},'Curse','Poison'},
 {'MAGE',{'解除次级诅咒'},'Curse'},
 {'SHAMAN',{'消毒术','祛病术'},'Poison','Disease'},
 {'WARLOCK',{},'Magic'}, {'WARRIOR',{}}, {'ROGUE',{}}, {'HUNTER',{}}
}
for _,c in ipairs(cases) do
 playerClass=c[1]; books.spell=c[2]; books.pet={'吞噬魔法'}; AddUnit('pet','Pet')
 XinDispel.RefreshSpells()
 local expected={}; for i=3,table.getn(c) do expected[c[i]]=true end
 for _,t in ipairs({'Magic','Poison','Curse','Disease'}) do
  assert((XinDispel.spells[t]~=nil)==(expected[t]==true),c[1]..':'..t)
 end
end
playerClass='PALADIN'; books.spell={'纯净术'}; XinDispel.RefreshSpells()
assert(not XinDispel.spells.Magic and XinDispel.spells.Poison.name=='纯净术')
books.spell={}; XinDispel.RefreshSpells(); assert(not next(XinDispel.spells))
''')
check('English client names and highest rank', '''
playerClass='PRIEST'; books.spell={'Dispel Magic','Dispel Magic','Cure Disease'}
XinDispel.RefreshSpells(); assert(XinDispel.spells.Magic.slot==2)
assert(XinDispel.spells.Disease.name=='Cure Disease')
''')
check('40 targets retained; locked rows scroll independently; Shift endpoints', '''
raidCount=40
for i=1,40 do AddUnit('raid'..i,'Member'..i,'Magic',i<=24 and 10 or 45) end
UpdateXinList()
assert(table.getn(XinMainFrame_InRange.entries)==24)
assert(table.getn(XinMainFrame_OutRange.entries)==16)
for i=1,5 do assert(XinRows_InRange[i]:IsShown()) end
assert(not XinRows_InRange[6]:IsShown())
XinRows_InRange[1]:Fire('OnMouseWheel',-1)
assert(XinMainFrame_InRange.offset==1 and XinRows_InRange[1].entry.name=='Member2')
assert(XinMainFrame_OutRange.offset==0)
UpdateXinList(); assert(XinMainFrame_InRange.offset==1)
shift=true; XinRows_InRange[1]:Fire('OnMouseWheel',-1)
assert(XinMainFrame_InRange.offset==19 and XinRows_InRange[5].entry.name=='Member24')
XinRows_InRange[1]:Fire('OnMouseWheel',1); assert(XinMainFrame_InRange.offset==0)
assert(XinMainFrame_InRange.pageText.text=='1-5/24  滚轮浏览')
''')
check('list shrink, resize, zero targets and disabled unavailable column', '''
partyCount=4
for i=1,4 do AddUnit('party'..i,'Mate'..i,'Magic',45) end
UpdateXinList(); assert(table.getn(XinMainFrame_OutRange.entries)==4)
xinDB.maxOutRange=3; XinRows_OutRange[1]:Fire('OnMouseWheel',-1)
assert(XinMainFrame_OutRange.offset==1)
units.party4.auras={}; UpdateXinList(); assert(XinMainFrame_OutRange.offset==0)
xinDB.enableOutRange=false; UpdateXinList()
assert(table.getn(XinMainFrame_OutRange.entries)==0 and not XinRows_OutRange[1]:IsShown())
''')
check('range, sight, cooldown, mana, absent and failing DLL', '''
partyCount=1; AddUnit('party1','Mate','Magic',10)
units.party1.sight=0; UpdateXinList(); assert(XinRows_OutRange[1].entry.reason=='视野之外')
units.party1.sight=true; units.party1.nativeRange=0; UpdateXinList()
assert(XinRows_OutRange[1].entry.reason=='距离过远')
units.party1.nativeRange=1; cooldown={start=10,duration=1.5}; UpdateXinList()
assert(XinRows_InRange[1]:IsShown(), 'global cooldown must not move rows')
cooldown={start=10,duration=8}; UpdateXinList()
assert(XinRows_OutRange[1].entry.reason=='冷却中')
cooldown=nil; oom=true; UpdateXinList(); assert(XinRows_OutRange[1].entry.reason=='法力不足')
oom=false; units.party1.nativeRange=nil; xpError=true; UpdateXinList()
assert(XinRows_OutRange[1].entry.reason=='距离未知')
UnitXP=nil; UpdateXinList(); assert(XinRows_OutRange[1].entry.reason=='距离未知')
units.party1.nativeRange=1; UpdateXinList(); assert(XinRows_InRange[1]:IsShown())
''')
check('priority, blacklist, class filters, and full-block unrelated aura', '''
raidCount=4
for i=1,4 do AddUnit('raid'..i,'Mate'..i,'Magic') end
PriorityList.Mate3=true; BlackList.Mate2=true; UpdateXinList()
assert(XinRows_InRange[1].entry.name=='Mate3')
assert(table.getn(XinMainFrame_InRange.entries)==3)
xinDB.IgnoreList['Debuff-Magic']=1; UpdateXinList(); assert(not XinRows_InRange[1]:IsShown())
xinDB.IgnoreList={}; xinDB.RaidSettings['Debuff-Magic']={ignoreClasses={['战士']=true}}
UpdateXinList(); assert(not XinRows_InRange[1]:IsShown())
xinDB.RaidSettings={}; units.raid1.auras[2]={name='DoNotDispel',kind='Curse'}
xinDB.IgnoreList.DoNotDispel=2; UpdateXinList()
assert(table.getn(XinMainFrame_InRange.entries)==2)
''')
check('pet source range, cooldown and pet replacement', '''
playerClass='WARLOCK'; books.spell={}; books.pet={'吞噬魔法'}; AddUnit('pet','Felhunter')
AddUnit('player','Self','Magic',10); FireEvent('UNIT_PET'); UpdateXinList()
assert(XinRows_InRange[1].entry.debuff.spell.pet and xpSource=='pet')
units.pet.dead=true; UpdateXinList(); assert(XinRows_OutRange[1].entry.reason=='宠物不可用')
units.pet=nil; books.pet={}; FireEvent('UNIT_PET'); UpdateXinList()
assert(not XinRows_InRange[1]:IsShown() and not XinRows_OutRange[1]:IsShown())
''')
check('click casts correct class spell and preserves current target', '''
partyCount=1; playerClass='MAGE'; books.spell={'解除次级诅咒'}
AddUnit('party1','Mate','Curse'); AddUnit('target','Boss'); FireEvent('SPELLS_CHANGED'); UpdateXinList()
XinRows_InRange[1]:Fire('OnClick','LeftButton')
assert(casts[1].name=='解除次级诅咒' and casts[1].unit=='party1' and units.target.name=='Boss')
XinRows_InRange[1]:Fire('OnClick','MiddleButton'); assert(units.target.name=='Mate' and table.getn(casts)==1)
''')
check('stale roster/aura or new blacklist cannot trigger wrong cast', '''
partyCount=1; AddUnit('party1','Mate','Magic'); UpdateXinList()
units.party1.name='Replacement'; XinRows_InRange[1]:Fire('OnClick','LeftButton'); assert(table.getn(casts)==0)
units.party1.name='Mate'; units.party1.auras={}; XinRows_InRange[1]:Fire('OnClick','LeftButton'); assert(table.getn(casts)==0)
units.party1.auras={{name='Debuff-Magic',kind='Magic'}}; BlackList.Mate=true
XinRows_InRange[1]:Fire('OnClick','LeftButton'); assert(table.getn(casts)==0)
''')
check('stock cast fallback restores target and resolves targeting cursor', '''
SUPERWOW_VERSION=nil; partyCount=1; AddUnit('party1','Mate','Magic'); AddUnit('target','Boss')
UpdateXinList(); XinRows_InRange[1]:Fire('OnClick','RightButton')
assert(casts[1].unit=='Mate' and units.target.name=='Boss' and resolved=='party1' and not targeting)
ClearTarget(); XinRows_InRange[1]:Fire('OnClick','LeftButton')
assert(units.target==nil and table.getn(casts)==2)
''')
check('list update between mouse press and release cannot cast on a different person', '''
partyCount=2; AddUnit('party1','First','Magic'); AddUnit('party2','Second','Magic'); UpdateXinList()
XinRows_InRange[1]:Fire('OnMouseDown','LeftButton')
units.party1.auras={}; UpdateXinList()
assert(XinRows_InRange[1].entry.name=='Second')
XinRows_InRange[1]:Fire('OnClick','LeftButton'); assert(table.getn(casts)==0)
''')
check('dead, disconnected and hostile units excluded', '''
partyCount=3
for i=1,3 do AddUnit('party'..i,'Mate'..i,'Magic') end
units.party1.dead=true; units.party2.offline=true; units.party3.hostile=true
UpdateXinList(); assert(not XinRows_InRange[1]:IsShown())
''')
check('saved priority/blacklist and anchor coordinates survive initialization', '''
PriorityList.Mate=true; BlackList.Other=true; FireEvent('PLAYER_LOGOUT')
assert(xinDB.PriorityList.Mate and xinDB.BlackList.Other)
XinMainFrame_InRange:Fire('OnDragStop')
assert(xinDB.positions.XinMainFrame_InRange[3]==30)
''')

print(f'{passed} behavior checks passed (Lua 5.1 mock of WoW 1.12; in-game QA still required).')
