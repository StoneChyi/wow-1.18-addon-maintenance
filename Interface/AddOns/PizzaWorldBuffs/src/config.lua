-- config.lua
local PWB = PizzaWorldBuffs
PWB.config = {}

local defaultConfig = {
  show = true,
  lock = false,
  fontSize = 14,
  align = 'center', -- This controls text justification within each frame
  header = false,
  allFactions = false,
  autoLogout = false,
  autoExit = false,
  frame = {
    top = 50,
    center = 0,
  },
  dmf = true,
  mapHeads = true,
  wbtSync = true, -- Import accurate world-buff timers from WorldBuffsTracker's TWB channel
  hideServerTime = true, -- Hide the "Server Time: ..." chat line printed by the .server info calibration
  orientation = 'vertical', -- New option: 'vertical' or 'horizontal'
}

function PWB.config.init()
  if not PWB_config then
    PWB_config = defaultConfig
    return
  end

  for key, defaultValue in pairs(defaultConfig) do
    if PWB_config[key] == nil then
      PWB_config[key] = defaultValue
    end
  end
end