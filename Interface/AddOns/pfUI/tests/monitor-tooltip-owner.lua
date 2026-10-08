-- From the workspace root: lua5.1 Interface/AddOns/pfUI/tests/monitor-tooltip-owner.lua
-- Exercise the real monitor configuration function with WoW 1.12 tooltip APIs.
local file = assert(io.open("Interface/AddOns/pfUI/modules/actionbar.lua", "rb"))
local source = PFUI_TOOLTIP_TEST_SOURCE or file:read("*a")
file:close()
source = string.gsub(source, "\r\n", "\n")
local body = assert(string.match(source,
  "    pfUI%.bars%.UpdateMonitorConfig = function%(self%)(.-)\n    end\n"))

local function scenario(ownerIndex, hideTooltip, enabled, missingButton)
  local env = setmetatable({}, { __index = _G })
  local function noop() end
  local function frame()
    return setmetatable({
      Show = function(self) self.shown = true end,
      Hide = function(self) self.shown = false end,
    }, { __index = function() return noop end })
  end
  local mon = frame()
  mon.backdrop = false
  mon.buttons = {}
  for i = 1, 3 do
    local button = frame()
    button.count, button.macro, button.keybind = frame(), frame(), frame()
    mon.buttons[i] = button
  end
  if missingButton then mon.buttons[missingButton] = nil end
  local tooltipOwner = ownerIndex and mon.buttons[ownerIndex] or nil
  if ownerIndex == "external" then tooltipOwner = {} end
  local ownershipChecks, tooltipHides = 0, 0
  env.GameTooltip = {
    -- Deliberately omit GetOwner: the failing API is absent in the 1.12 client.
    IsOwned = function(self, owner)
      assert(owner ~= nil, "IsOwned must never receive a missing button")
      ownershipChecks = ownershipChecks + 1
      return owner == tooltipOwner
    end,
    Hide = function() tooltipHides = tooltipHides + 1 end,
  }
  env.C = { bars = {
    monitorhidetooltip = hideTooltip and "1" or "0",
    monitorenable = enabled and "1" or "0",
    monitorautotalent = "0", monitorbackdrop = "0", monitorcount = "1",
    monitorshowmacro = "0", monitorshowkeybind = "1", monitorautohide = "0",
    monitorborder = "1", monitorglow = "1", monitorhide = "0",
    macro_color = "1,1,1,1", bind_color = "1,1,1,1",
  } }
  env.pfUI = { font_unit = "test.ttf", bars = { MONITOR_COUNT = 3 }, api = {
    SetAllPointsOffset = noop, DisableAutohide = noop,
  } }
  env.mon, env.listener = mon, {}
  env.MonitorStopDrag, env.MonitorSyncProfile = noop, noop
  env.MonitorSetBorder, env.RemoveMovable = noop, noop
  env.UpdateMovable = function() env.layoutCompleted = true end
  env.strsplit = function() return 1, 1, 1, 1 end
  local chunk = assert(loadstring("return function(self)" .. body .. "\nend"))
  setfenv(chunk, env)
  local configure = chunk()
  configure(env.pfUI.bars)
  if enabled then
    assert(env.layoutCompleted and mon.dirty, "monitor initialization did not finish")
  end
  return tooltipHides, ownershipChecks
end

local hides, checks = scenario(2, true, true)
assert(hides == 1 and checks == 2, "monitor-owned tooltip must be hidden")
print("PASS: enabled monitor initializes without GetOwner and hides its own tooltip")
hides, checks = scenario("external", true, true)
assert(hides == 0 and checks == 3, "unrelated tooltip must remain visible")
print("PASS: unrelated tooltip remains visible")
hides, checks = scenario(nil, true, true)
assert(hides == 0 and checks == 3)
print("PASS: no tooltip owner is safe")
hides, checks = scenario(2, false, true)
assert(hides == 0 and checks == 0)
print("PASS: tooltip-hiding switch off preserves the tooltip")
hides, checks = scenario(2, true, false)
assert(hides == 1)
print("PASS: disabled monitor config is also safe")
hides, checks = scenario(nil, true, false, 2)
assert(hides == 0 and checks == 2)
print("PASS: missing monitor buttons are skipped")
print("Six tooltip ownership regressions passed (Lua 5.1 mock, not a live client).")
