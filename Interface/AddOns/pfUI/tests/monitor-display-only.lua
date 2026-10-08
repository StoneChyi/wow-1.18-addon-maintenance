-- Run from the repository root with Lua 5.1 (or the bundled Lupa runtime).
local file = assert(io.open("Interface/AddOns/pfUI/modules/actionbar.lua", "rb"))
local source = string.gsub(file:read("*a"), "\r\n", "\n")
file:close()
local env = setmetatable({}, { __index = _G })
local used, removed, saved, animated = 0, 0, 0, 0
local shift, alt = false, false
env.C = { bars = { monitordisplayonly = "0", monitorlock = "0",
  monitorhidetooltip = "0", rightself = "1", altself = "1", animmode = "keypress" } }
env.mon = {}
env.pfUI = { bars = { ToggleMonitorSlot = function() removed = removed + 1 end } }
env.IsShiftKeyDown = function() return shift end
env.IsAltKeyDown = function() return alt end
env.HasAction = function() return true end
env.MacroFrame_SaveMacro = function() saved = saved + 1 end
env.UseAction = function(slot, _, selfcast) used = used + 1; env.lastCast = { slot, selfcast } end
env.T = setmetatable({}, { __index = function(_, key) return key end })
local button = { slot = 61, animation = { Show = function() animated = animated + 1 end },
  highlight = { Show = function() end } }
env.this, env.arg1 = button, "LeftButton"
local function callback(pattern)
  local body = assert(string.match(source, pattern), "source callback not found")
  local chunk = assert(loadstring("return function()" .. body .. "\nend"))
  setfenv(chunk, env)
  return chunk()
end
local monitorStart = assert(string.find(source, '  pfUI.bars.MONITOR_COUNT = 32', 1, true))
local monitorSource = string.sub(source, monitorStart)
local clickBody = assert(string.match(monitorSource, 'b:SetScript%("OnClick", function%(%)\n(.-)\n      end%)'))
local clickChunk = assert(loadstring("return function()" .. clickBody .. "\nend"))
setfenv(clickChunk, env)
local click = clickChunk()
for _, mouse in ipairs({"LeftButton", "RightButton"}) do
  env.arg1 = mouse
  click()
end
assert(used == 2 and saved == 2 and animated == 2)
assert(env.lastCast[1] == 61 and env.lastCast[2] == true)
print("PASS: default mode preserves left click, right self-cast and animation")

env.C.bars.monitordisplayonly = "1"
for _, locked in ipairs({"0", "1"}) do
  env.C.bars.monitorlock = locked
  for _, mouse in ipairs({"LeftButton", "RightButton"}) do
    env.arg1 = mouse
    click()
  end
end
assert(used == 2 and saved == 2 and animated == 2)
env.C.bars.monitorlock, env.arg1, alt = "0", "LeftButton", true
click()
assert(removed == 1 and used == 2)
env.C.bars.monitorlock = "1"
click()
assert(removed == 1 and used == 2)
env.C.bars.monitorlock, alt, shift = "0", false, true
click()
assert(used == 2 and removed == 1)
shift = false
env.mon.dragButton = button
click()
env.mon.dragButton = nil
assert(used == 2)
print("PASS: display-only blocks both mouse buttons and modifier self-cast, preserves Alt removal and Shift drag reservation")

local keyBody = assert(string.match(source, '    local function MonitorUseButton%(idx%)\n(.-)\n    end'))
local keyChunk = assert(loadstring("return function(idx)" .. keyBody .. "\nend"))
setfenv(keyChunk, env)
env.mon.buttons = { button }
local useKey = keyChunk()
useKey(1)
assert(used == 2)
env.C.bars.monitordisplayonly = "0"
useKey(1)
assert(used == 3 and saved == 3 and animated == 3)
print("PASS: dedicated monitor keybind follows the option and recovers when disabled")

local lines = {}
env.GameTooltip = {
  ClearLines = function() lines = {} end, SetAction = function() end,
  AddLine = function(_, text) table.insert(lines, text) end, Show = function() end, Hide = function() end,
}
env.GameTooltip_SetDefaultAnchor = function() end
local enterBody = assert(string.match(monitorSource, 'b:SetScript%("OnEnter", function%(%)\n(.-)\n      end%)'))
local enterChunk = assert(loadstring("return function()" .. enterBody .. "\nend"))
setfenv(enterChunk, env)
local enter = enterChunk()
env.C.bars.monitordisplayonly = "1"
enter()
assert(lines[1] == "Monitor Display Only")
assert(lines[2] == "Alt+Leftclick To Remove From Monitor" and lines[3] == "Shift+Drag To Reorder Monitor")
env.C.bars.monitordisplayonly = "0"
enter()
assert(lines[1] == "Click To Use Action")
print("PASS: tooltip accurately describes the current mode and retains management hints")

local profileStart = assert(string.find(source, '    local monitorProfileKeys = {', 1, true))
local profileEnd = assert(string.find(source, '    pfUI.bars.GetMonitorProfiles', profileStart, true))
local profileChunk = assert(loadstring(string.sub(source, profileStart, profileEnd - 1) .. '\nreturn MonitorSyncProfile'))
setfenv(profileChunk, env)
env.C.bars.monitorprofiles = { default = {settings = { monitordisplayonly = "1" }}, legacy = {settings = {}} }
env.C.bars.monitorprofile = "default"
local sync = profileChunk()
sync()
assert(env.C.bars.monitordisplayonly == "1")
env.C.bars.monitorprofile = "legacy"
sync()
assert(env.C.bars.monitordisplayonly == "0", "legacy profiles must not inherit the outgoing display-only flag")
env.C.bars.monitorprofile = "default"
sync()
assert(env.C.bars.monitordisplayonly == "1")
assert(env.C.bars.monitorprofiles.legacy.settings.monitordisplayonly == "0")
print("PASS: per-profile persistence, restoration and safe migration of older profiles")
print("Five display-only regression groups passed; no live game actions executed.")
