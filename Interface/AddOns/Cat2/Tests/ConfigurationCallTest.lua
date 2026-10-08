-- 从项目根目录运行；只模拟客户端 API，加载真实卡片、编码器、编辑器和执行器。
table.getn = table.getn or function(value) return #value end
unpack = unpack or table.unpack
local checks = 0
local function check(value, message)
    assert(value, message)
    checks = checks + 1
end
local frames = {}
function CreateFrame(kind, name)
    local frame = { scripts = {} }
    function frame:RegisterEvent() end
    function frame:SetScript(eventName, callback) self.scripts[eventName] = callback end
    if name then frames[name] = frame end
    return frame
end
function UnitClass() return "盗贼", "ROGUE" end
function UnitExists(unit) return true, unit .. "-guid" end
function GetTime() return 10 end
function GetSpellNameAndRankForId() return "TestHeal" end
SlashCmdList = {}
local messages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, value) table.insert(messages, value) end }
local settings = { NP_QueueCastTimeSpells = "1", NP_QueueInstantSpells = "2", NP_QueueChannelingSpells = "3" }
function GetCVar(key) return settings[key] end
function SetCVar(key, value) settings[key] = value end
Cat2 = { UI = {}, PlayerInformation = { temporary = {}, basic = { guid = "player-guid", classFile = "ROGUE" } } }
dofile("Cat2/Core/CardRegistry.lua")
Cat2.RegisterOptionalEvent = function() return true end
dofile("Cat2/Core/CardEventDispatcher.lua")
dofile("Cat2/Core/CastInterruptMonitor.lua")
dofile("Cat2/Cards/Logic/CallConfiguration.lua")
dofile("Cat2/Core/Persistence.lua")
dofile("Cat2/Core/ConfigurationCodec.lua")
dofile("Cat2/Core/ConfigurationRunner.lua")
Cat2.Nampower = true
local refreshes = 0
Cat2.RefreshPlayerTemporaryInformation = function() refreshes = refreshes + 1 end
local serial = 0
local function card(execute, passive)
    serial = serial + 1
    local definition = { id = "call_test_" .. serial, name = "Test", category = "logic", Execute = execute, behavior = passive and "passive" or nil }
    Cat2.RegisterCard(definition)
    return definition
end
local function call(id)
    return Cat2.RestoreConfigurationStep({ id = "logic_call_configuration", optionValues = { targetProfile = tostring(id) } })
end
local function repository(parent, child)
    Cat2.RuntimeConfigurations = {
        activeProfileId = 1, profileOrder = {1, 2}, nextProfileId = 3,
        profiles = { [1] = {id = 1, name = "Parent", steps = parent}, [2] = {id = 2, name = "Child", steps = child} },
    }
end
local function run()
    refreshes = 0
    local found, total, failed, stopped = Cat2.ExecuteConfiguration("Parent")
    check(found and refreshes == 1, "Snapshot must refresh once")
    check(Cat2.CurrentExecutionContext == nil, "Execution context leaked")
    check(settings.NP_QueueCastTimeSpells == "1" and settings.NP_QueueInstantSpells == "2" and settings.NP_QueueChannelingSpells == "3", "CVar restoration failed")
    check(Cat2.RuntimeConfigurations.activeProfileId == 1, "Call changed editor selection")
    return total, failed, stopped
end
local tailHits, childHits = 0, 0
local tail = card(function() tailHits = tailHits + 1 end)
local parentPassive = card(nil, true)
parentPassive.Apply = function(context) context.parameters.owner = "parent" end
local childPassive = card(nil, true)
childPassive.Apply = function(context) context.parameters.owner = "child" end
local childAction = card(function(context)
    childHits = childHits + 1
    check(context.parameters.owner == "child" and context.profileId == 2, "Child passive/context isolation failed")
    check(Cat2.CurrentExecutionContext == context, "Child global context wrong")
end)
local parentAction = card(function(context)
    check(context.parameters.owner == "parent" and context.profileId == 1, "Parent context not restored")
    check(Cat2.CurrentExecutionContext == context, "Parent global context not restored")
end)
repository({parentPassive, call(2), parentAction, tail}, {childPassive, childAction})
local total, failed, stopped = run()
check(total == 6 and failed == 0 and not stopped and tailHits == 1 and childHits == 1, "Normal return failed")
repository({call(2), tail}, {card(function() return true end)})
total, failed, stopped = run()
check(total == 2 and stopped and tailHits == 1, "Child stop did not stop parent")
repository({call(1), tail}, {})
total, failed, stopped = run()
check(total == 1 and failed == 1 and stopped, "Self recursion accepted")
repository({call(2), tail}, {call(1)})
total, failed, stopped = run()
check(total == 2 and failed == 1 and stopped, "Mutual recursion accepted")
repository({call(99), tail}, {})
total, failed, stopped = run()
check(failed == 1 and stopped and tailHits == 1, "Missing target accepted")
repository({call(2), tail}, {card(function() error("child failure") end), tail})
total, failed, stopped = run()
check(failed == 1 and stopped and tailHits == 1, "Child failure did not stop parent")
repository({call(2), tail}, {card(function(context) context.executionStepCount = -100; return Cat2.JumpTo(1) end)})
total, failed, stopped = run()
check(total == 60 and stopped and failed == 0 and tailHits == 1, "Nested budget reset")
repository({call(2), card(function() return Cat2.JumpTo(1) end)}, {card(function() end)})
total, failed, stopped = run()
check(total == 60 and stopped and failed == 0, "Repeated calls did not share budget")
local passiveHits = 0
local boundaryPassive = card(nil, true)
boundaryPassive.Apply = function() passiveHits = passiveHits + 1 end
local boundary = {}
for i = 1, 59 do boundary[i] = card(function() end) end
boundary[60] = call(2)
repository(boundary, {boundaryPassive, tail})
total, failed, stopped = run()
check(total == 60 and stopped and passiveHits == 0, "Child entered after final budget step")
local inactive = call(1)
inactive.enabled = 0
repository({inactive, tail}, {})
total, failed, stopped = run()
check(total == 1 and failed == 0 and not stopped, "Disabled call executed")
repository({call(2)}, {})
Cat2.RuntimeConfigurations.profiles[2].name = "Renamed"
check(Cat2.ResolveStepOption(Cat2.RuntimeConfigurations.profiles[1].steps[1], "targetProfile") == "2", "Rename lost ID")
local exportedOptions = Cat2.ExportCallConfigurationOptions(Cat2.RuntimeConfigurations.profiles[1].steps[1])
check(exportedOptions.configurationName == "Renamed" and exportedOptions.targetProfile == nil, "Export exposed local ID")
local encoded, encodeError = Cat2.ExportConfigurationText(Cat2.RuntimeConfigurations.profiles[1], "ROGUE")
check(encoded ~= nil, encodeError or "Export failed")
local decoded, decodeError = Cat2.ImportConfigurationText(encoded)
check(decoded ~= nil, decodeError or "Import failed")
check(decoded.steps[1].optionValues.targetProfile == "name:Renamed", "Name transport failed")
local savedDatabase
Cat2.SaveConfigurationData(Cat2.RuntimeConfigurations)
savedDatabase = Cat2CharacterDB
Cat2.RuntimeConfigurations = nil
local restored = Cat2.LoadConfigurationData()
check(restored.profiles[1].steps[1].optionValues.targetProfile == "2", "Login discarded ID before repository exists")
-- 真实 UI 导入入口：同名目标在另一角色使用不同 ID。
Cat2CharacterDB = nil
dofile("Cat2/UI/FlowEditor.lua")
Cat2.EnsureConfigurationDataLoaded()
local editor = Cat2.UI.FlowEditor
editor.RedrawFlow = function() end
editor.runtimeConfigurations.profiles[8] = {id = 8, name = "Renamed", steps = {}}
table.insert(editor.runtimeConfigurations.profileOrder, 8)
editor.runtimeConfigurations.nextProfileId = 9
check(Cat2.UI.ApplyImportedConfiguration(decoded), "UI import failed")
local imported = editor.runtimeConfigurations.profiles[9]
check(imported.steps[1].optionValues.targetProfile == "8", "Import reused sender ID")
decoded.steps[1].optionValues.targetProfile = "name:Missing"
check(Cat2.UI.ApplyImportedConfiguration(decoded, 9), "Overwrite import failed")
check(imported.steps[1].optionValues.targetProfile == "name:Missing", "Missing dependency lost name")
local label = Cat2.GetCardOptionDisplayValue(imported.steps[1].optionSchema[1], "name:Missing", imported.steps[1])
check(label == "待绑定：Missing", "Unresolved name not displayed")
local pendingExport = Cat2.ExportCallConfigurationOptions(imported.steps[1])
check(pendingExport.configurationName == "Missing", "Unresolved re-export lost name")
local sanitized = Cat2.ImportCallConfigurationOptions("logic_call_configuration", {targetProfile = "8"})
check(sanitized.targetProfile == "", "Foreign ID was trusted")
editor.runtimeConfigurations.profiles[10] = {id = 10, name = "Renamed", steps = {}}
table.insert(editor.runtimeConfigurations.profileOrder, 10)
imported.steps[1].optionValues.targetProfile = "name:Renamed"
Cat2.BindImportedConfigurationCalls(imported)
check(imported.steps[1].optionValues.targetProfile == "name:Renamed", "Ambiguous name bound silently")
-- 后续测试重新使用独立仓库。
Cat2.EnsureConfigurationDataLoaded = nil
repository({call(2)}, {})
Cat2.RuntimeConfigurations.profiles[2] = nil
local broken, brokenError = Cat2.ExportCallConfigurationOptions(Cat2.RuntimeConfigurations.profiles[1].steps[1])
check(broken == nil and brokenError, "Deleted target exported silently")
-- 延迟治疗施法事件应使用发起子流程的策略，而非编辑器当前配置。
local policy = card(nil, true)
policy.castInterruptPolicy = { matchTag = "healing", rules = {} }
local heal = card(function(context)
    Cat2.RecordPendingCastTarget("TestHeal", "target")
end)
Cat2.RegisterCardCastProfile({category = "logic", castProfile = { spellNames = {"TestHeal"}, tags = {healing = true} }})
repository({call(2)}, {policy, heal})
run()
event, arg1, arg2, arg3, arg4 = "UNIT_CASTEVENT", "player-guid", "target-guid", "START", 1
frames.Cat2CastInterruptMonitorFrame.scripts.OnEvent()
check(Cat2.GetActiveCastInterruptState() and Cat2.GetActiveCastInterruptState().profileId == 2, "Delayed cast used editor profile policy")
print("ConfigurationCallTest passed: " .. checks)
return checks
