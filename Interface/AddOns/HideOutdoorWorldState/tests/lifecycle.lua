-- Run from the workspace root with Lua 5.1. The addon uses Lua 5.0 syntax.
local file = assert(io.open("Interface/AddOns/HideOutdoorWorldState/HideOutdoorWorldState.lua", "rb"))
local source = HIDE_OUTDOOR_TEST_SOURCE or file:read("*a")
file:close()

local function newClient(saved)
  local env = setmetatable({
    HideOutdoorWorldStateDB = saved,
    SlashCmdList = {}, nativeUpdates = 0, instanceType = "none",
    NUM_ALWAYS_UP_UI_FRAMES = 2, NUM_EXTENDED_UI_FRAMES = 1,
    pfUI = { bootup = true, config = { sentinel = "unchanged" } },
  }, { __index = _G })
  local function row()
    return {
      visible = true, hides = 0,
      Hide = function(self) self.visible = false; self.hides = self.hides + 1 end,
      Show = function(self) self.visible = true end,
    }
  end
  env.UIParent = row()
  env.WorldStateAlwaysUpFrame = row()
  env.pfPlayer, env.pfMinimap, env.addonButtons = row(), row(), row()
  env.AlwaysUpFrame1, env.AlwaysUpFrame2 = row(), row()
  env.WorldStateCaptureBar1 = row()
  env.DEFAULT_CHAT_FRAME = { AddMessage = function() end }
  env.CreateFrame = function(kind, name, parent)
    local driver = { scripts = {}, events = {}, parent = parent }
    function driver:RegisterEvent(eventName) self.events[eventName] = true end
    function driver:SetScript(scriptName, fn) self.scripts[scriptName] = fn end
    env.driver = driver
    if name then env[name] = driver end
    return driver
  end
  env.getglobal = function(name) return rawget(env, name) end
  env.IsInInstance = function() return env.instanceType ~= "none", env.instanceType end
  env.WorldStateAlwaysUpFrame_Update = function()
    env.nativeUpdates = env.nativeUpdates + 1
    local visible = env.HIDE_OUTDOOR_WORLD_STATE == "0" or env.instanceType == "pvp"
    env.AlwaysUpFrame1.visible = visible
    env.AlwaysUpFrame2.visible = visible
    env.WorldStateCaptureBar1.visible = visible
  end
  local addon = assert(loadstring(source, "@HideOutdoorWorldState.lua"))
  setfenv(addon, env)
  addon()
  function env:fire(eventName)
    assert(self.driver.events[eventName], "event not registered: " .. eventName)
    self.event, self.this = eventName, self.driver
    self.driver.scripts.OnEvent()
    self.event, self.this = nil, nil
  end
  function env:tick()
    if self.driver.scripts.OnUpdate then
      self.this = self.driver
      self.driver.scripts.OnUpdate()
      self.this = nil
    end
    assert(not self.driver.scripts.OnUpdate, "update handler must stop after one tick")
  end
  function env:assertUntouched()
    assert(self.UIParent.hides == 0 and self.WorldStateAlwaysUpFrame.hides == 0)
    assert(self.pfPlayer.hides == 0 and self.pfMinimap.hides == 0 and self.addonButtons.hides == 0)
    assert(self.pfUI.bootup and self.pfUI.config.sentinel == "unchanged")
  end
  return env
end

local tests = {}
tests.startup = function()
  local c = newClient()
  assert(c.nativeUpdates == 0)
  c:fire("VARIABLES_LOADED")
  assert(c.HIDE_OUTDOOR_WORLD_STATE == "1" and c.HideOutdoorWorldStateDB.enabled)
  assert(c.nativeUpdates == 0, "startup must not call the broad native updater")
  assert(c.AlwaysUpFrame1.hides == 0 and not c.driver.scripts.OnUpdate)
  c:fire("PLAYER_ENTERING_WORLD")
  assert(c.AlwaysUpFrame1.visible, "hiding must wait until event dispatch completes")
  c:tick()
  assert(not c.AlwaysUpFrame1.visible and not c.AlwaysUpFrame2.visible)
  assert(not c.WorldStateCaptureBar1.visible and c.nativeUpdates == 0)
  c:assertUntouched()
end
tests.event_order_and_zone = function()
  local c = newClient()
  c:fire("VARIABLES_LOADED")
  c:fire("PLAYER_ENTERING_WORLD")
  c:tick()
  c:fire("UPDATE_WORLD_STATES")
  -- Another handler runs later in the same dispatch and shows an existing row.
  c.AlwaysUpFrame1:Show()
  c:tick()
  assert(not c.AlwaysUpFrame1.visible)
  c.HIDE_OUTDOOR_WORLD_STATE = "0"
  c:fire("ZONE_CHANGED_NEW_AREA")
  c:tick()
  assert(c.HIDE_OUTDOOR_WORLD_STATE == "1" and c.nativeUpdates == 0)
  c:assertUntouched()
end
tests.battleground_and_return = function()
  local c = newClient()
  c:fire("VARIABLES_LOADED")
  c.instanceType = "pvp"
  c:fire("PLAYER_ENTERING_WORLD")
  c:tick()
  assert(c.AlwaysUpFrame1.visible and c.AlwaysUpFrame2.visible)
  assert(c.WorldStateCaptureBar1.visible and c.AlwaysUpFrame1.hides == 0)
  c.instanceType = "none"
  c:fire("PLAYER_ENTERING_WORLD")
  c:tick()
  assert(not c.AlwaysUpFrame1.visible and c.nativeUpdates == 0)
  c:assertUntouched()
end
tests.saved_show_and_commands = function()
  local c = newClient({ enabled = false })
  c:fire("VARIABLES_LOADED")
  c:fire("PLAYER_ENTERING_WORLD")
  c:tick()
  assert(c.HIDE_OUTDOOR_WORLD_STATE == "0" and c.AlwaysUpFrame1.visible)
  assert(c.nativeUpdates == 0)
  c.SlashCmdList.HIDEOUTDOORWORLDSTATE("hide")
  c:tick()
  assert(not c.AlwaysUpFrame1.visible and c.nativeUpdates == 0)
  c.SlashCmdList.HIDEOUTDOORWORLDSTATE("show")
  assert(c.nativeUpdates == 0, "manual restoration must also be deferred")
  c:tick()
  assert(c.nativeUpdates == 1 and c.AlwaysUpFrame1.visible)
  assert(c.HideOutdoorWorldStateDB.enabled == false)
  local restart = newClient(c.HideOutdoorWorldStateDB)
  restart:fire("VARIABLES_LOADED")
  restart:fire("PLAYER_ENTERING_WORLD")
  restart:tick()
  assert(restart.HIDE_OUTDOOR_WORLD_STATE == "0" and restart.nativeUpdates == 0)
  restart:assertUntouched()
end
tests.missing_rows_and_rapid_commands = function()
  local c = newClient()
  c.AlwaysUpFrame2, c.WorldStateCaptureBar1 = nil, nil
  c:fire("VARIABLES_LOADED")
  c:fire("PLAYER_ENTERING_WORLD")
  c:tick()
  c.SlashCmdList.HIDEOUTDOORWORLDSTATE("show")
  c.SlashCmdList.HIDEOUTDOORWORLDSTATE("hide")
  c:tick()
  assert(c.nativeUpdates == 0 and not c.AlwaysUpFrame1.visible)
  c:assertUntouched()
end

local count = 0
for name, test in pairs(tests) do
  test()
  count = count + 1
  print("PASS: " .. name)
end
print("Passed " .. count .. " lifecycle regression scenarios (Lua 5.1 mock, not a live client).")
