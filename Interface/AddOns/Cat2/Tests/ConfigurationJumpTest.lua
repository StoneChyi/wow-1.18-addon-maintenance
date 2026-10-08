-- 从项目根目录用 Lua 5.1 运行；加载真实注册器、持久化与执行器，不加入游戏 TOC。
Cat2 = { UI = {}, PlayerInformation = { temporary = {} } }
function CreateFrame() return { RegisterEvent = function() end, SetScript = function() end } end
function UnitClass() return "德鲁伊", "DRUID" end
SlashCmdList = {}
local messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, message) table.insert(messages, message) end }
local settings = { NP_QueueCastTimeSpells = "1", NP_QueueInstantSpells = "2", NP_QueueChannelingSpells = "3" }
function GetCVar(key) return settings[key] end
function SetCVar(key, value) settings[key] = value end
Cat2.Nampower = true
dofile("Cat2/Core/CardRegistry.lua")
dofile("Cat2/Core/Persistence.lua")
dofile("Cat2/Core/ConfigurationRunner.lua")
local serial = 0
local function card(execute, behavior)
    serial = serial + 1
    local definition = { id = "test_" .. serial, name = "Test " .. serial, category = "logic", behavior = behavior, Execute = execute }
    Cat2.RegisterCard(definition)
    return definition
end
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local refreshes = 0
Cat2.RefreshPlayerTemporaryInformation = function() refreshes = refreshes + 1 end
local function run(steps)
    messages = {}
    refreshes = 0
    Cat2.RuntimeConfigurations = { profileOrder = {1}, profiles = { [1] = { id = 1, name = "Jump test", steps = steps } } }
    local found, total, failed, stopped, names = Cat2.ExecuteConfiguration("Jump test")
    check(found and refreshes == 1, "Profile/snapshot behavior changed")
    check(Cat2.CurrentExecutionContext == nil, "Execution context leaked")
    check(settings.NP_QueueCastTimeSpells == "1" and settings.NP_QueueInstantSpells == "2" and settings.NP_QueueChannelingSpells == "3", "Queue settings not restored")
    return total, failed, stopped, names
end
local hits = 0
local tail = card(function() hits = hits + 1; return false end)
local total, failed, stopped = run({card(function() return false end), card(function() end), tail})
check(total == 3 and failed == 0 and not stopped and hits == 1, "False/nil did not continue")
hits = 0
total, failed, stopped = run({card(function() return true end), tail})
check(total == 1 and stopped and hits == 0, "True did not terminate")
for _, value in ipairs({0, 1, "jump", {}, {action = "jump", target = 1}}) do
    hits = 0
    total, failed, stopped = run({card(function() return value end), tail})
    check(total == 2 and failed == 0 and hits == 1 and not stopped, "Legacy result became control instruction")
end
hits = 0
local skip = card(function() error("Skipped card executed") end)
local forward = card(function() return Cat2.JumpTo(3) end, "logic")
total, failed, stopped = run({forward, skip, tail})
check(total == 2 and failed == 0 and hits == 1, "Forward jump failed")
hits = 0
local backward = card(function(context)
    check(context.currentStepIndex == 2, "Current index incorrect")
    if context.executionStepCount < 4 then return Cat2.JumpTo(1) end
    return false
end, "logic")
total, failed, stopped = run({tail, backward})
check(total == 4 and failed == 0 and hits == 2 and not stopped, "Backward jump/count failed")
local selfJump = card(function(context)
    -- 公共快照字段不可绕过执行器的局部预算。
    context.executionStepCount = -100
    return Cat2.JumpTo(1)
end, "logic")
total, failed, stopped = run({selfJump})
check(total == 60 and failed == 0 and stopped, "Self loop exceeded budget")
total, failed, stopped = run({selfJump})
check(total == 60 and stopped, "New invocation did not reset budget")
total, failed, stopped = run({card(function() return Cat2.JumpTo(2) end), card(function() return Cat2.JumpTo(1) end)})
check(total == 60 and stopped, "Two-card loop exceeded budget")
for _, invalid in ipairs({0, -1, 1.5, 2, 61, "1", false, {}, math.huge, -math.huge, 0/0}) do
    total, failed, stopped = run({card(function() return Cat2.JumpTo(invalid) end)})
    check(total == 1 and failed == 1 and stopped and table.getn(messages) == 1, "Invalid target was accepted")
end
total, failed, stopped = run({card(function() return Cat2.JumpTo() end)})
check(total == 1 and failed == 1 and stopped, "Missing target was accepted")
local applyCount, validateCount = 0, 0
local passive = card(function() error("Passive Execute called") end, "passive")
passive.Apply = function(context) applyCount = applyCount + 1; context.parameters.ready = true end
passive.Validate = function(context) validateCount = validateCount + 1; return context.parameters.ready end
local disabled = card(function() error("Disabled Execute called") end)
disabled.enabled = 0
total, failed, stopped = run({card(function(context)
    check(context.parameters.ready, "Passive not applied before jump")
    return Cat2.JumpTo(2)
end), disabled, passive, card(function() return Cat2.JumpTo(2) end)})
check(total == 61 and failed == 0 and stopped and applyCount == 1 and validateCount == 1, "Passive/disabled consumed budget or repeated")
hits = 0
passive.Validate = function() return false end
total, failed, stopped = run({tail, passive})
check(stopped and failed == 0 and hits == 0, "Passive validation no longer blocks")
local repeatedError = card(function() error("Expected test error") end)
total, failed, stopped = run({repeatedError, card(function() return Cat2.JumpTo(1) end)})
check(total == 60 and failed == 30 and stopped, "Failures did not consume budget")
local sequence = {}
for i = 1, 61 do sequence[i] = tail end
hits = 0
total, failed, stopped = run(sequence)
check(total == 60 and hits == 60 and stopped, "61st execution was allowed")
sequence = { card(function() return Cat2.JumpTo(60) end) }
for i = 2, 59 do sequence[i] = disabled end
sequence[60] = tail
hits = 0
total, failed, stopped = run(sequence)
check(total == 2 and hits == 1 and failed == 0, "Valid slot 60 was rejected")
hits = 0
local restored = Cat2.RestoreConfigurationStep({id = forward.id, enabled = 1, minimizedVisible = 1})
total, failed, stopped = run({restored, skip, tail})
check(total == 2 and failed == 0 and hits == 1, "Restored card wrapper lost jump")
local direct = card(function() return Cat2.JumpTo(3) end)
local delegate = card(function(context) return Cat2.ExecuteCardById(direct.id, context) end)
hits = 0
total, failed, stopped = run({delegate, skip, tail})
check(total == 2 and hits == 1 and failed == 0, "Direct helper lost control result")
total, failed, stopped = run({})
check(total == 0 and failed == 0 and not stopped, "Empty flow changed")
return checks
