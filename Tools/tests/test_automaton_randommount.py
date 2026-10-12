"""RandomMount regressions using Lua 5.1 and the live AceDB default/save helpers."""
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

ADDON = 'Interface/AddOns/Automatonex/Modules/RandomMount.lua'
SOURCE = (ROOT / ADDON).read_text(encoding='utf-8')
if len(sys.argv) > 1:
    SOURCE = subprocess.check_output(['git', 'show', sys.argv[1] + ':' + ADDON], cwd=ROOT).decode('utf-8')
ACE = (ROOT / 'Interface/AddOns/!Libs/Ace2/AceDB-2.0/AceDB-2.0.lua').read_text(encoding='utf-8')
INHERIT = ACE[ACE.index('local function inheritDefaults('):ACE.index('local _,race =')]
CLEAN = ACE[ACE.index('local function cleanDefaults('):ACE.index('function AceDB:GetProfile()')]

STUB = r'''
BOOKTYPE_SPELL='spell'; SlashCmdList={}; logs={}; calls={}; reads={}; invalidReads=0
tabs={}; spells={}; zone='暴风城'; defaults={}; combat=false; casting=false
module={}; namespace={char=saved or {}, profile={}}
Automaton={}
function Automaton:NewModule() return module end
function Automaton:AcquireDBNamespace() return namespace end
function Automaton:RegisterDefaults(name, scope, values)
    defaults[scope]=values; inheritDefaults(namespace[scope], values)
end
function Automaton:SetDisabledAsDefault() end
function module:RegisterOptions(options) self.registeredOptions=options end
local locale=setmetatable({}, {__index=function(t,k) return k end})
function locale:new() return self end
function locale:RegisterTranslations() end
AceLibrary=function() return locale end
DEFAULT_CHAT_FRAME={AddMessage=function(self,msg) table.insert(logs,msg) end}
function GetNumSpellTabs() return #tabs end
function GetSpellTabInfo(i)
    local t=tabs[i]; assert(t); return t[1], '', t[2], t[3]
end
function GetSpellName(index, book)
    assert(book=='spell', '1.12 spellbook type required')
    table.insert(reads,index)
    if index < 1 or not spells[index] then invalidReads=invalidReads+1; error('invalid spell index') end
    if spells[index]=='ERROR' then error('spellbook temporarily unavailable') end
    return spells[index], ''
end
-- These extensions are deliberately absent: GetSpellInfo, GetNumSpellCount,
-- string.trim. Tests require only the 1.12 spellbook API.
function CastSpell(index, book)
    assert(book=='spell' and spells[index]); table.insert(calls,{index,spells[index]})
end
function UnitAffectingCombat() return combat end
function UnitCastingInfo() return casting end
function IsCurrentAction() return false end
function GetRealZoneText() return zone end
function random(count) return count end
function containsLog(text)
    for _,line in ipairs(logs) do if string.find(line,text,1,true) then return true end end
    return false
end
function showList() logs={}; SlashCmdList.RANDOMMOUNT('list') end
function snapshot(value)
    if type(value)=='table' then
        local pieces={}
        for k,v in pairs(value) do table.insert(pieces,'['..snapshot(k)..']='..snapshot(v)) end
        return '{'..table.concat(pieces,',')..'}'
    elseif type(value)=='string' then return string.format('%q',value)
    else return tostring(value) end
end
function save()
    cleanDefaults(namespace.char,defaults.char)
    return snapshot(namespace.char)
end
'''


def world(book, saved='nil'):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.globals().inheritDefaults = lua.execute(INHERIT + '\nreturn inheritDefaults')
    lua.globals().cleanDefaults = lua.execute(CLEAN + '\nreturn cleanDefaults')
    lua.execute('saved=' + saved)
    lua.execute(STUB)
    lua.execute(book)
    lua.execute(SOURCE)
    lua.execute('module:OnInitialize()')
    return lua


BOOK = "tabs={{'常规',0,1},{'坐骑',1,2}};spells={'火球术','白马','黑马'}"
groups = 0


def check(name, book, body, saved='nil'):
    global groups
    lua = world(book, saved)
    lua.execute(body)
    lua.execute("assert(invalidReads==0, 'scanned index zero or beyond spellbook')")
    groups += 1
    print('PASS:', name)
    return lua


check('single mount at offset zero', "tabs={{'坐骑',0,1}};spells={'黑马'}", '''
RandomMount(); assert(#calls==1 and calls[1][1]==1)
showList(); assert(containsLog('黑马'))
module:AddCustomMount('黑马'); assert(namespace.char.customMounts[1]=='黑马')
''')
check('first/last entries without preceding ordinary spell', BOOK, '''
showList(); assert(containsLog('白马') and containsLog('黑马') and not containsLog('火球术'))
RandomMount(); assert(#calls==1 and calls[1][1]==3)
''')
check('add trims input, saves names, enables and deduplicates', BOOK, '''
module.options.customMountAdd.set('  黑马  ')
assert(namespace.char.customMountsEnable and namespace.char.customMounts[1]=='黑马')
module:AddCustomMount('黑马'); assert(#namespace.char.customMounts==1)
module:ListCustomMounts(); assert(containsLog('黑马'))
''')
check('invalid/empty and denied profession names', "tabs={{'常规',0,1},{'坐骑',1,1}};spells={'采矿','黑马'}", '''
module:AddCustomMount(nil); module:AddCustomMount('   ')
module:AddCustomMount('不存在的坐骑'); module:AddCustomMount('采矿')
assert(#namespace.char.customMounts==0 and not namespace.char.customMountsEnable)
''')
for tab in ['坐騎', 'Mounts', 'MOUNTS']:
    check('localized mount tab ' + tab, "tabs={{'" + tab + "',0,1}};spells={'Black Stallion'}", '''
showList(); assert(containsLog('Black Stallion'))
module:AddCustomMount(' black stallion '); module:AddCustomMount('BLACK STALLION')
assert(namespace.char.customMounts[1]=='Black Stallion' and #namespace.char.customMounts==1)
''')
check('actual tab ranges beyond 300 and class mount fallback', '''
tabs={{'常规',0,350},{'坐骑',350,1}}
for i=1,349 do spells[i]='普通法术'..i end
spells[350]='Summon Warhorse'; spells[351]='黑马'
''', '''
showList(); assert(containsLog('Summon Warhorse') and containsLog('黑马'))
module:AddCustomMount('黑马'); RandomMount(); assert(calls[1][1]==351)
''')
check('custom outside mount tab uses current index without GetSpellInfo', '''
tabs={{'常规',0,2},{'坐骑',2,1}}; spells={'特殊坐骑','火球术','黑马'}
''', '''
module:AddCustomMount('特殊坐骑'); RandomMount(); assert(calls[1][1]==1)
module.options.customMountsEnable.set(false)
calls={}; RandomMount(); assert(calls[1][1]==3)
assert(namespace.char.customMounts[1]=='特殊坐骑')
''')

first = check('saved lists pass actual AceDB cleanup', BOOK, '''
module:AddCustomMount('黑马'); module:ExcludeMount('白马')
''')
saved = first.globals().save()
check('fresh runtime reload after spell indices change', '''
tabs={{'常规',0,2},{'坐骑',2,2}};spells={'火球术','新学法术','黑马','白马'}
''', '''
assert(namespace.char.customMountsEnable and namespace.char.customMounts[1]=='黑马')
assert(namespace.char.excludedMounts[1]=='白马')
showList(); assert(containsLog('黑马') and not containsLog('白马'))
RandomMount(); assert(calls[1][1]==3 and calls[1][2]=='黑马')
module:UnExcludeMount('白马'); showList(); assert(containsLog('白马'))
''', saved)
custom = world("tabs={{'常规',0,1},{'坐骑',1,1}};spells={'特殊坐骑','黑马'}")
custom.execute("module:AddCustomMount('特殊坐骑');module:ExcludeMount('黑马')")
check('custom-only mount survives reload and changed position', '''
tabs={{'常规',0,2},{'坐骑',2,1}};spells={'新学法术','特殊坐骑','黑马'}
''', '''
assert(namespace.char.customMounts[1]=='特殊坐骑')
RandomMount(); assert(#calls==1 and calls[1][1]==2 and calls[1][2]=='特殊坐骑')
''', custom.globals().save())
check('characters do not share custom or excluded lists', BOOK, '''
assert(#namespace.char.customMounts==0 and #namespace.char.excludedMounts==0)
assert(not namespace.char.customMountsEnable)
''')
check('legacy indices migrate once, deduplicate and preserve unresolved', BOOK, '''
showList()
assert(namespace.char.customMounts[1]==999 and namespace.char.customMounts[2]==1)
assert(namespace.char.customMounts[3]=='黑马' and #namespace.char.customMounts==3)
assert(namespace.char.excludedMounts[1]=='白马')
module:ListCustomMounts(); assert(containsLog('无法确认') and containsLog('黑马'))
RandomMount(); assert(#calls==1 and calls[1][2]=='黑马')
-- An unresolved old position must not become a new mount after a later reorder.
spells[1]='白马'; showList(); assert(namespace.char.customMounts[2]==1)
''', '{customMounts={3,999,1,"黑马"},excludedMounts={2},customMountsEnable=true}')
check('defer migration until mount book becomes available', 'tabs={};spells={}', '''
showList(); assert(namespace.char.customMounts[1]==3 and namespace.char.mountNamesVersion==nil)
tabs={{'常规',0,1},{'坐骑',1,2}};spells={'火球术','白马','黑马'}
showList(); assert(namespace.char.customMounts[1]=='黑马' and namespace.char.mountNamesVersion==1)
''', '{customMounts={3}}')
check('missing learned mount remains saved and blacklist can be removed', BOOK, '''
module:ListCustomMounts(); assert(containsLog('旧坐骑（当前未学会）'))
module:UnExcludeMount('旧坐骑'); assert(#namespace.char.excludedMounts==0)
assert(namespace.char.customMounts[1]=='旧坐骑')
''', '{customMounts={"旧坐骑"},excludedMounts={"旧坐骑"}}')
check('blacklist exact names and duplicate ranks', '''
tabs={{'坐骑',0,3}};spells={'黑马','黑马','白马'}
''', '''
module:ExcludeMount(' 黑马 '); module:ExcludeMount('黑马')
assert(#namespace.char.excludedMounts==1)
showList(); assert(not containsLog('黑马') and containsLog('白马'))
module:UnExcludeMount('黑马'); RandomMount(); assert(calls[1][2]=='白马')
''')
check('bug mount classification and existing AQ behavior', '''
tabs={{'坐骑',0,2}};spells={'蓝色其拉作战坦克','黑马'}
''', '''
RandomMount(); assert(calls[1][2]=='黑马')
zone='安其拉'; RandomMount(); assert(calls[2][2]=='蓝色其拉作战坦克')
module:ExcludeMount('蓝色其拉作战坦克'); RandomMount(); assert(#calls==2)
''')
check('combat/casting, no mounts and temporary API errors', "tabs={{'坐骑',0,1}};spells={'ERROR'}", '''
RandomMount(); assert(#calls==0)
spells[1]='黑马'; combat=true; RandomMount(); assert(#calls==0)
combat=false; casting=true; RandomMount(); assert(#calls==0)
casting=false; RandomMount(); assert(#calls==1)
module:ClearCustomMounts(); module:ClearExcludedMounts()
assert(#namespace.char.customMounts==0 and #namespace.char.excludedMounts==0)
''')
check('two mounts alternate and a single mount stays usable', BOOK, '''
for i=1,20 do
    RandomMount()
    assert(calls[i][2]==(i%2==1 and '黑马' or '白马'))
end
module:ExcludeMount('白马')
for i=1,3 do RandomMount(); assert(calls[#calls][2]=='黑马') end
''')
for previous in ['白马', '黑马', '红马']:
    check('equal remaining choices after ' + previous,
          "tabs={{'坐骑',0,3}};spells={'白马','黑马','红马'}", '''
local previous=namespace.char.lastMountName
local seen={}
for draw=1,2 do
    namespace.char.lastMountName=previous
    function random(count) assert(count==2); return draw end
    RandomMount()
    local picked=calls[#calls][2]
    assert(picked~=previous and not seen[picked]); seen[picked]=true
end
''', '{lastMountName="' + previous + '"}')
check('absent previous mount leaves all current choices eligible', BOOK, '''
namespace.char.lastMountName='旧坐骑'
function random(count) assert(count==2); return 2 end
RandomMount(); assert(calls[1][2]=='黑马')
''')
check('blocked and empty calls do not change previous selection', BOOK, '''
RandomMount(); assert(namespace.char.lastMountName=='黑马')
combat=true; RandomMount(); combat=false
casting=true; RandomMount(); casting=false
module:ExcludeMount('白马'); module:ExcludeMount('黑马'); RandomMount()
assert(#calls==1 and namespace.char.lastMountName=='黑马')
''')
check('ordinary and AQ groups both avoid consecutive duplicates', '''
tabs={{'坐骑',0,4}};spells={'蓝色其拉作战坦克','红色其拉作战坦克','白马','黑马'}
''', '''
RandomMount(); RandomMount()
assert(calls[1][2]=='黑马' and calls[2][2]=='白马')
zone='安其拉'; RandomMount(); RandomMount()
assert(calls[3][2]=='红色其拉作战坦克' and calls[4][2]=='蓝色其拉作战坦克')
zone='暴风城'; RandomMount(); assert(calls[5][2]=='黑马')
''')
check('bug-only fallback also avoids duplicates', '''
tabs={{'坐骑',0,2}};spells={'蓝色其拉作战坦克','红色其拉作战坦克'}
''', '''
RandomMount(); RandomMount()
assert(calls[1][2]=='红色其拉作战坦克' and calls[2][2]=='蓝色其拉作战坦克')
''')
check('repeat avoidance follows names across reordering and blacklist changes', BOOK, '''
RandomMount(); assert(calls[1][2]=='黑马')
spells[2]='黑马'; spells[3]='白马'
RandomMount(); assert(calls[2][2]=='白马')
module:ExcludeMount('白马'); RandomMount(); assert(calls[3][2]=='黑马')
module:UnExcludeMount('白马'); RandomMount(); assert(calls[4][2]=='白马')
''')
last = world(BOOK)
last.execute('RandomMount()')
check('previous mount persists through reload with current spell positions', '''
tabs={{'坐骑',0,2}};spells={'黑马','白马'}
''', '''
assert(namespace.char.lastMountName=='黑马')
RandomMount(); assert(calls[1][2]=='白马')
''', last.globals().save())
check('custom and automatic duplicates still count as one candidate', BOOK, '''
module:AddCustomMount('黑马')
RandomMount(); RandomMount(); RandomMount()
assert(calls[1][2]=='黑马' and calls[2][2]=='白马' and calls[3][2]=='黑马')
''')
print(f'PASS: {groups} RandomMount Lua 5.1 behavior groups')
