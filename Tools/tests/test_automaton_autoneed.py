"""AutoNeed roll choices and manual-selection behavior against the live module."""
from pathlib import Path
import argparse
import sys

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--addons', type=Path, default=ROOT / 'Interface/AddOns')
ADDONS = parser.parse_args().addons
sys.path.insert(0, str(ROOT / 'addons_tmp/bcs-test-runtime'))
from lupa.lua51 import LuaRuntime

lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
module = {}
Automaton = {}
function Automaton:NewModule() return module end
function Automaton:AcquireDBNamespace() return {char={}, profile={}} end
function Automaton:RegisterDefaults(name, scope, defaults)
    module.db[scope] = defaults
end
function Automaton:SetDisabledAsDefault() end
function module:RegisterOptions() end
function UnitClass() return "Warrior", "WARRIOR" end
function GetItemInfo(id)
    return "Test item", "item:"..id, quality or 3, 1, "Armor", "Plate", 1, "INVTYPE_CHEST"
end
format = string.format
print = function() end
rolls = {}; timers = 0; clicks = 0
function GetLootRollItemLink(id) return "item:"..id..":0:0:0" end
function RollOnLoot(id, choice) table.insert(rolls, {id, choice}) end
C_Timer = {After = function(delay, callback) timers = timers + 1; callback() end}
StaticPopup1 = {which="CONFIRM_LOOT_ROLL", IsVisible=function() return true end}
StaticPopup1Button1 = {Click=function() clicks = clicks + 1 end}
function resetCalls() rolls = {}; timers = 0; clicks = 0 end
function rollAndCheck(id, expected)
    resetCalls()
    module:START_LOOT_ROLL(id)
    if expected == nil then
        assert(#rolls == 0 and timers == 0 and clicks == 0, "manual roll was touched: "..id)
    else
        assert(#rolls == 1 and rolls[1][1] == id and rolls[1][2] == expected)
        local confirmations = expected == 0 and 0 or 1
        assert(clicks == confirmations)
    end
end
''')
lua.execute((ADDONS / 'Automatonex/Modules/AutoNeed.lua').read_text(encoding='utf-8'))
lua.execute('''
module:OnInitialize()
initial = {}; for k,v in pairs(module.db.char) do initial[k] = v end
choices = {"需求", "贪婪", "放弃", "不选择"}
selectorCount = 0
for _, group in pairs(module.options) do
    for _, option in pairs(group.args or {}) do
        if option.validate then
            selectorCount = selectorCount + 1
            assert(#option.validate == 4)
            for i, value in ipairs(choices) do assert(option.validate[i] == value) end
            local old = option.passValue and option.get(option.passValue) or option.get()
            for _, value in ipairs(choices) do
                if option.passValue then
                    option.set(option.passValue, value)
                    assert(option.get(option.passValue) == value)
                else
                    option.set(value); assert(option.get() == value)
                end
            end
            if option.passValue then option.set(option.passValue, old) else option.set(old) end
        end
    end
end
assert(selectorCount == 31)

-- Exercise every built-in item through the actual loot event, including
-- equipment that would otherwise fall through to the quality rule.
local defaults
for i=1,20 do
    local name, value = debug.getupvalue(module.CheckItem, i)
    if name == "default" then defaults = value; break end
end
assert(defaults)
builtInCount = 0
for category, items in pairs(defaults) do
    local prefix = category == "安其拉废墟/神殿" and "安其拉废墟" or category
    module.db.char[prefix.."_enable"] = true
    module.db.char["品质_enable"] = true
    module.db.char["蓝装_rolltype"] = "需求"
    for _, item in ipairs(items) do
        builtInCount = builtInCount + 1
        local field = category == "杂项" and item.rolltype or prefix.."_"..item.rolltype
        for i, choice in ipairs(choices) do
            module.db.char[field] = choice
            local expected = ({1,2,0})[i]
            rollAndCheck(item.itemID, expected)
        end
        module.db.char[field] = nil
        module.db.char.rolltype = "不选择"
        rollAndCheck(item.itemID, nil)
        module.db.char.rolltype = "贪婪"
        rollAndCheck(item.itemID, 2)
        module.db.char[field] = initial[field]
    end
    module.db.char[prefix.."_enable"] = false
end

-- Custom items store numeric choices when added and take priority over
-- both category and quality automation, even after the default changes.
for i, choice in ipairs(choices) do
    module.db.char.autoneedsDB = {}
    module.db.char.rolltype = choice
    module:AddItem(4500)
    module.db.char["杂项_enable"] = true
    module.db.char.item_4500 = "需求"
    rollAndCheck(4500, ({1,2,0})[i])
    module.db.char.rolltype = "需求"
    rollAndCheck(4500, ({1,2,0})[i])
end
''')
lua.execute('''
module.db.char.autoneedsDB = {{itemID=4500}}
module.db.char.rolltype = "不选择"
rollAndCheck(4500, nil)
module.db.char.autoneedsDB = {}
for category in pairs(initial) do
    if string.find(category, "_enable$") then module.db.char[category] = false end
end
module.db.char["品质_enable"] = true
for rarity, field in pairs({[2]="绿装_rolltype", [3]="蓝装_rolltype", [4]="紫装_rolltype"}) do
    quality = rarity
    for i, choice in ipairs(choices) do
        module.db.char[field] = choice
        rollAndCheck(999999, ({1,2,0})[i])
    end
end
module.db.char["品质_enable"] = false
rollAndCheck(999999, nil)
GetLootRollItemLink = function() return nil end
rollAndCheck(999999, nil)
-- Existing saved choices, including manual selection, survive initialization.
local saved = module.db
saved.char.item_4500 = "不选择"
function Automaton:AcquireDBNamespace() return saved end
module:OnInitialize()
assert(module.db.char.item_4500 == "不选择")
''')
print(f'PASS: Lua 5.1 module load; {lua.globals().selectorCount} selectors; '
      f'{lua.globals().builtInCount} built-in items with all four choices and fallback; '
      'custom precedence, quality rules, confirmation behavior and saved settings')

lua.execute('''
-- Real asynchronous delivery: several items arrive while confirmation waits.
tasks={};rolls={};clicks=0
function GetLootRollItemLink(id) return 'item:'..id..':0:0:0' end
C_Timer.After=function(delay,callback) table.insert(tasks,callback) end
function flushOne() local cb=table.remove(tasks,1);if cb then cb() end end
function flushAll() local guard=0;while #tasks>0 do guard=guard+1;assert(guard<30);flushOne() end end
function module:CheckItem(id) if id==2 then return -1 elseif id==3 then return 0 else return 1 end end
module:START_LOOT_ROLL(1);module:START_LOOT_ROLL(2);module:START_LOOT_ROLL(3);module:START_LOOT_ROLL(4)
assert(#rolls==1 and rolls[1][1]==1)
flushAll()
assert(#rolls==3 and rolls[2][1]==3 and rolls[2][2]==0 and rolls[3][1]==4)
assert(clicks==2 and not module.isRolling and #module.pendingRolls==0)
-- Disable cancels queued automation and pending confirmation callbacks.
function module:UnhookAll() end
function module:UnregisterAllEvents() end
rolls={};clicks=0
module:START_LOOT_ROLL(5);module:START_LOOT_ROLL(6)
assert(#rolls==1)
module:OnDisable();flushAll()
assert(#rolls==1 and clicks==0 and #module.pendingRolls==0 and not module.isRolling)
-- A rejected/expired roll does not leave the queue permanently locked.
rolls={}
function RollOnLoot(id,choice) if id==7 then error('expired roll') end;table.insert(rolls,{id,choice}) end
module:START_LOOT_ROLL(7);module:START_LOOT_ROLL(8);flushAll()
assert(#rolls==1 and rolls[1][1]==8 and not module.isRolling)
''')
print('PASS: asynchronous FIFO, manual/pass choices, disable cancellation and expired-roll recovery')
