"""Exercise actual nameplate identity/color code; no FontStrings are created."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

PATH = 'Interface/AddOns/pfUI/modules/nameplates.lua'
source = (ROOT / PATH).read_text(encoding='utf-8')


def between(text, start, end):
    begin = text.index(start)
    return text[begin:text.index(end, begin)]


def check_upvalues(text):
    """Read compiler metadata: Lua 5.1 accepts more upvalues than WoW 1.12."""
    binary_lua = LuaRuntime(encoding=None)
    chunk = binary_lua.eval(b'string.dump')(binary_lua.compile(text.encode('utf-8')))
    assert chunk[:6] == b'\x1bLua\x51\x00'
    endian = '<' if chunk[6] else '>'
    int_size, size_t, instruction, number = chunk[7:11]
    position = 12
    functions = []

    def integer(size=int_size):
        nonlocal position
        result = int.from_bytes(chunk[position:position+size],
                                'little' if endian == '<' else 'big')
        position += size
        return result

    def string():
        nonlocal position
        size = integer(size_t)
        result = chunk[position:position+size].rstrip(b'\0')
        position += size
        return result

    def function():
        nonlocal position
        string()
        first, last = integer(), integer()
        upvalues = integer(1)
        position += 3  # parameters, vararg flag, stack size
        code_size = integer()
        position += code_size * instruction
        for _ in range(integer()):
            tag = integer(1)
            if tag == 1:
                position += 1
            elif tag == 3:
                position += number
            elif tag == 4:
                string()
            else:
                assert tag == 0
        for _ in range(integer()):
            function()
        line_count = integer()
        position += line_count * int_size
        for _ in range(integer()):
            string()
            integer()
            integer()
        names = [string() for _ in range(integer())]
        functions.append((first, last, upvalues, names))

    function()
    assert position == len(chunk)
    line = text[:text.index('  nameplates.OnDataChanged = function')].count('\n') + 1
    result = next(f for f in functions if f[0] == line)
    assert result[2] <= 32, ('WoW 1.12 upvalue limit exceeded', result)
    return result[2]


STUB = r'''
nameplates = {}
C = {nameplates = {use_unitfonts='0', enemyclassc='1', friendclassc='1'},
     global = {font_size=12}}
cfg = {barcombatstate=true, ccombatthreat=true, ccombatnothreat=true,
       ccombatstun=true, ccombatcasting=true, ccombatofftank=true}
RAID_CLASS_COLORS = {WARRIOR={r=.78,g=.61,b=.43}, MAGE={r=.41,g=.8,b=.94}}
frameState = {now=100}
NULL_GUID = '0x0000000000000000'
UNIT_FLAG_IN_COMBAT = 1
combatColorCache, threatMemory, raidGuidCache, offtanks = {}, {}, {}, {}
guidRegistry, visiblePlates, hiddenPlates = {}, {}, {}
pfUI = {api={}}
units, aliases, inCombat = {}, {}, false
guidQueries, liveQueries = true, 0
dbClass, dbLevel, dbPlayer = 'WARRIOR', 54, nil
strlower = string.lower
function unit(token)
  if token == 'player' or token == '0x0000000000000001' then
    return {name='Me', guid='0x0000000000000001', player=true}
  end
  if not token then return nil end
  if not guidQueries and string.find(token, '^0x') then return nil end
  return units[aliases[token] or token]
end
function UnitExists(token) return unit(token) and 1 or nil end
function UnitName(token) local u=unit(token); return u and u.name end
function UnitIsPlayer(token)
  local u=assert(unit(token), 'Unvalidated identity query: '..tostring(token))
  liveQueries=liveQueries+1
  return u.player and 1 or nil
end
function GetUnitGUID(token) local u=unit(token); return u and u.guid end
function GetUnitData(name, active) return dbClass, dbLevel, nil, dbPlayer end
function UnitCanAssist(player, token) return false end
function UnitIsTapped(token) local u=unit(token); return u and u.tapped end
function UnitIsTappedByPlayer(token) local u=unit(token); return u and u.ownTap end
function UnitAffectingCombat(token) return token == 'player' and inCombat end
function GetUnitField(token, field) local u=unit(token); return u and u[field] end
function HasFlag(flags, flag) return flags == flag end
function GetCastInfo(token) local u=unit(token); return u and u.cast end
function UnitIsUnit(a,b)
  if string.sub(a,-6) == 'target' then a=GetUnitField(string.sub(a,1,-7), 'target') end
  local ua,ub=unit(a),unit(b)
  return ua and ub and ua.guid == ub.guid
end
function NewPlate(guid, name, reaction)
  local p = {guid=guid, name=name or 'Bat', reaction=reaction or {1,0,0}, cache={}, cdCache={}}
  local f = {nameplate=p}
  p.parent=f
  function f:GetName(arg) assert(arg==1); return p.guid end
  function p:IsVisible() return true end
  p.original = {
    healthbar={GetValue=function() return 3990 end,
      GetMinMaxValues=function() return 0,3990 end,
      GetStatusBarColor=function() return unpack(p.reaction) end},
    name={GetText=function() return p.name end},
    level={IsShown=function() return true end, GetObjectType=function() return 'FontString' end,
      GetText=function() return '54' end},
    glow={IsShown=function() return p.hover end}}
  p.health={SetStatusBarColor=function(self,...) self.color={...}; self.calls=(self.calls or 0)+1 end}
  return p
end
function Reset()
  units,aliases={},{}
  dbClass,dbLevel,dbPlayer='WARRIOR',54,nil
  guidQueries,liveQueries,inCombat,event=true,0,false,nil
  cfg.barcombatstate=true
  C.nameplates.enemyclassc='1'; C.nameplates.friendclassc='1'
  combatColorCache,threatMemory,offtanks={},{},{}
  frameState.now=frameState.now+1
end
function AddUnit(guid,name,player)
  units[guid]={guid=guid,name=name or 'Bat',player=player}
  return units[guid]
end
'''


def runtime(text):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.compile(text)
    lua.execute(STUB)
    lua.execute(between(text, '  local unitcolors = {', '  -- 从配置刷新') +
                between(text, '  local combatstate = {', '  local elitestrings = {') +
                between(text, '  local function GetUnitType(', '  local filter, list, cache') +
                between(text, '  local function GetCombatStateColor(',
                        '  -- ============================================================================') +
                '\nTestUnitColors=unitcolors; TestCombatColors=combatstate\n' +
                between(text, '  nameplates.OnDataChanged = function(self, plate)',
                        '    elite = plate.original.levelicon:IsShown()') +
                '\nlocal npccolor=unitcolors._custom[nameLower]\n' +
                between(text, '    local r, g, b, a = unpack(unitcolors[unittype])',
                        '    if r + g + b ~= plate.cache.namecolor') +
                '\nreturn unittype, unitstr, r, g, b, a\nend\n' +
                between(text, '  nameplates.OnShow = function(frame)',
                        '  nameplates.OnUpdate = function(frame, state)') +
                '\nfunction UpdateRegistry(frame)\nlocal nameplate=frame.nameplate\n' +
                between(text, '    -- Update GUID registry (lightweight',
                        '    -- PERF: Intelligent throttling') + '\nend')
    return lua


CHECKS = r'''
local a,b='0x0000000000000010','0x0000000000000020'
local count=0
local function expect(p, kind, color, token)
  local k,u,r,g,b,alpha=nameplates:OnDataChanged(p)
  assert(k==kind, 'Expected '..kind..', got '..k)
  assert(u==token, 'Wrong validated unit: '..tostring(u))
  for i,v in ipairs({r,g,b,alpha}) do
    assert(math.abs(v-color[i])<.00001, 'Check '..(count+1)..' color channel '..i..': '..v..' ~= '..color[i])
    assert(p.health.color and math.abs(p.health.color[i]-color[i])<.00001, 'Rendered color differs')
  end
  count=count+1
end
local red,warrior,mage={.9,.2,.3,.8},{.78,.61,.43,1},{.41,.8,.94,1}

-- Target-change mismatch cannot seed PLAYER, even without GUIDs.
Reset(); local p=NewPlate(nil); p.istarget=true
AddUnit(a,'Other player',true); aliases.target=a; event='PLAYER_TARGET_CHANGED'
expect(p,'ENEMY_NPC',red,nil); assert(p.cache.player==nil and liveQueries==0)
event=nil; AddUnit(b); aliases.target=b
expect(p,'ENEMY_NPC',red,'target'); assert(p.cache.player=='NPC')

-- Correct live identity overrides an existing bad cache on the same unit.
p.cache.player='PLAYER'
expect(p,'ENEMY_NPC',red,'target'); assert(p.cache.player=='NPC')
p.cache.player='NPC'; units[b].player=true; dbClass='MAGE'; dbPlayer=true
expect(p,'ENEMY_PLAYER',mage,'target'); assert(p.cache.player=='PLAYER')

-- GUID wins over stale target/mouseover and remains valid during target events.
for _,hover in ipairs({false,true}) do
  Reset(); AddUnit(a); AddUnit(b,'Other player',true)
  aliases.target=b; aliases.mouseover=b; event='PLAYER_TARGET_CHANGED'
  p=NewPlate(a); p.istarget=not hover; p.hover=hover
  expect(p,'ENEMY_NPC',red,a); assert(p.cache.player=='NPC')
end

-- When GUID queries are unavailable, same-name tokens must still match GUID.
Reset(); AddUnit(b,'Bat',true); aliases.target=b; guidQueries=false
p=NewPlate(a); p.istarget=true
expect(p,'ENEMY_NPC',red,nil); assert(p.cache.player==nil)
aliases.target='targetData'; units.targetData={guid=a,name='Bat',player=false}
expect(p,'ENEMY_NPC',red,'target')
event='PLAYER_TARGET_CHANGED'; expect(p,'ENEMY_NPC',red,nil)

-- GUID changes clear same-name identity and spell timers before live data exists.
Reset(); p=NewPlate(a); p.cache={name='Bat',guid=b,player='PLAYER'}
expect(p,'ENEMY_NPC',red,nil); assert(p.cache.player==nil and p.cdCache==nil)
p.guid=nil; p.cache.player='PLAYER'; p.cdCache={}
expect(p,'ENEMY_NPC',red,nil); assert(p.cache.player==nil and p.cdCache==nil)
Reset(); AddUnit(a,'Bat',true); AddUnit(b); p=NewPlate(a)
expect(p,'ENEMY_PLAYER',warrior,a)
p.guid=b; expect(p,'ENEMY_NPC',red,b); assert(p.cache.guid==b and p.cache.player=='NPC')

-- A validated NPC overrides a colliding player-name database entry immediately.
Reset(); AddUnit(a); p=NewPlate(a); dbPlayer=true
expect(p,'ENEMY_NPC',red,a)
local calls=p.health.calls
expect(p,'ENEMY_NPC',red,a); assert(p.health.calls==calls)

-- Empty, zero and ordinary frame names are not treated as GUIDs.
for _,bad in ipairs({'','0x0000000000000000','NamePlate1'}) do
  Reset(); AddUnit(a); aliases.target=a; p=NewPlate(bad); p.istarget=true
  expect(p,'ENEMY_NPC',red,'target'); assert(p.cache.guid==nil)
end

-- Name mismatch / missing token is rejected before UnitIsPlayer.
for _,token in ipairs({'target','mouseover'}) do
  for _,exists in ipairs({false,true}) do
    Reset(); if exists then AddUnit(a,'Other',true); aliases[token]=a end
    p=NewPlate(nil); p.istarget=token=='target'; p.hover=token=='mouseover'
    expect(p,'ENEMY_NPC',red,nil); assert(liveQueries==0 and p.cache.player==nil)
  end
end

-- Name database fallback survives when live units cannot be queried.
Reset(); dbClass='MAGE'; dbPlayer=true; p=NewPlate(nil,'Known player')
expect(p,'ENEMY_PLAYER',mage,nil)
dbLevel=60; expect(p,'ENEMY_NPC',red,nil)

-- Player class colors and faction reactions remain intact; NPC class is ignored.
for _,isPlayer in ipairs({false,true}) do
  for _,reaction in ipairs({{1,0,0},{1,1,0},{0,1,0},{0,0,1}}) do
    Reset(); AddUnit(a,'Bat',isPlayer); dbPlayer=isPlayer or nil
    p=NewPlate(a,'Bat',reaction)
    local kind = reaction[1]==1 and (reaction[2]==1 and 'NEUTRAL_NPC' or 'ENEMY_NPC') or
                 (reaction[3]==1 and 'FRIENDLY_PLAYER' or 'FRIENDLY_NPC')
    if isPlayer and kind=='ENEMY_NPC' then kind='ENEMY_PLAYER' end
    if isPlayer and kind=='FRIENDLY_NPC' then kind='FRIENDLY_PLAYER' end
    local color=(kind=='ENEMY_PLAYER' or kind=='FRIENDLY_PLAYER') and warrior or TestUnitColors[kind]
    expect(p,kind,color,a)
    C.nameplates.enemyclassc='0'; C.nameplates.friendclassc='0'
    expect(p,kind,TestUnitColors[kind],a)
  end
end

-- Custom NPC color, foreign tap, combat override, then out-of-combat restoration.
Reset(); local u=AddUnit(a); p=NewPlate(a)
TestUnitColors._custom.bat={.1,.3,.6,1}
expect(p,'ENEMY_NPC',{.1,.3,.6,1},a)
u.tapped=true; expect(p,'ENEMY_NPC',{.5,.5,.5,.8},a)
u.ownTap=true; expect(p,'ENEMY_NPC',{.1,.3,.6,1},a)
TestUnitColors._custom.bat=nil; u.tapped=nil
inCombat=true; u.flags=1; u.target='0x0000000000000001'
expect(p,'ENEMY_NPC',{.7,.2,.2,1},a)
inCombat=false; expect(p,'ENEMY_NPC',red,a)
inCombat=true; cfg.barcombatstate=false; expect(p,'ENEMY_NPC',red,a)

-- Full OnShow resets same-name pools with no GUID support.
Reset(); p=NewPlate(nil); p.cache={name='Bat',player='PLAYER'}
nameplates.OnShow(p.parent); assert(p.cache.player==nil); count=count+1
AddUnit(a); aliases.mouseover=a; p.hover=true
expect(p,'ENEMY_NPC',red,'mouseover')
nameplates.OnShow(p.parent); assert(p.cache.player=='NPC'); count=count+1

-- Fixed target plates still use GUID identity and bypass floating registration.
Reset(); AddUnit(a); p=NewPlate(a); p.parent._pfFixedPlate=true; p.istarget=true
expect(p,'ENEMY_NPC',red,a)
local before=guidRegistry[a]; nameplates.OnShow(p.parent)
assert(guidRegistry[a]==before and p.cache.player=='NPC'); count=count+1

-- GUID reuse queues an immediate update even inside the normal throttle window.
Reset(); p=NewPlate(a); p.cachedGuid=b; guidRegistry[b]=p.parent
UpdateRegistry(p.parent)
assert(p.eventcache and p.cachedGuid==a and guidRegistry[a]==p.parent and guidRegistry[b]==nil)
count=count+1
return count
'''

BASELINE = '8fce60b3036db7e996246f38c202ee053fd761cd'
baseline = subprocess.check_output(['git', 'show', BASELINE + ':' + PATH], cwd=ROOT).decode('utf-8')
try:
    runtime(baseline).execute(r'''
      Reset(); local p=NewPlate(nil); p.istarget=true
      AddUnit('0x0000000000000010','Other player',true)
      aliases.target='0x0000000000000010'; event='PLAYER_TARGET_CHANGED'
      nameplates:OnDataChanged(p)
      AddUnit('0x0000000000000020'); aliases.target='0x0000000000000020'; event=nil
      local kind=nameplates:OnDataChanged(p)
      assert(kind=='ENEMY_NPC', 'Expected ENEMY_NPC, got '..kind)
    ''')
except Exception as error:
    assert 'Expected ENEMY_NPC, got ENEMY_PLAYER' in str(error), str(error)
    print('Baseline reproduces persistent NPC -> PLAYER / warrior-color error.')
else:
    raise AssertionError('Regression did not expose the baseline defect')

old_upvalues, new_upvalues = check_upvalues(baseline), check_upvalues(source)
assert new_upvalues <= old_upvalues
count = runtime(source).execute(CHECKS)
print(f'PASS: {count} identity/color/lifecycle checks; Lua syntax passed; '
      f'OnDataChanged upvalues {old_upvalues} -> {new_upvalues} (limit 32).')
