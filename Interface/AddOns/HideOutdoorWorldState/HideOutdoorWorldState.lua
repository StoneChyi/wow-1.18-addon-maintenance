-- Use the client's outdoor-only switch so battleground displays stay available.
local function ApplySetting()
  if type(HideOutdoorWorldStateDB) ~= "table" then
    HideOutdoorWorldStateDB = {}
  end
  if HideOutdoorWorldStateDB.enabled == nil then
    HideOutdoorWorldStateDB.enabled = true
  end

  HIDE_OUTDOOR_WORLD_STATE = HideOutdoorWorldStateDB.enabled and "1" or "0"
  if type(WorldStateAlwaysUpFrame_Update) == "function" then
    WorldStateAlwaysUpFrame_Update()
  end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:SetScript("OnEvent", ApplySetting)

SLASH_HIDEOUTDOORWORLDSTATE1 = "/outdoorui"
SlashCmdList["HIDEOUTDOORWORLDSTATE"] = function(message)
  ApplySetting()
  local command = string.lower(message or "")
  if command == "show" then
    HideOutdoorWorldStateDB.enabled = false
  elseif command == "hide" then
    HideOutdoorWorldStateDB.enabled = true
  else
    DEFAULT_CHAT_FRAME:AddMessage("HideOutdoorWorldState: /outdoorui hide | /outdoorui show")
    return
  end
  ApplySetting()
  DEFAULT_CHAT_FRAME:AddMessage("Outdoor world-state UI: " ..
    (HideOutdoorWorldStateDB.enabled and "hidden" or "shown"))
end
