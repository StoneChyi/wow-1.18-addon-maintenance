-- Automatic hiding must not call the native updater: it also repositions
-- unrelated UI through UIParent_ManageFramePositions during addon startup.
local enteredWorld = false
local restoreRequested = false
local frame = CreateFrame("Frame", "HideOutdoorWorldStateEvents", UIParent)

local function ApplySetting()
  if type(HideOutdoorWorldStateDB) ~= "table" then
    HideOutdoorWorldStateDB = {}
  end
  if HideOutdoorWorldStateDB.enabled == nil then
    HideOutdoorWorldStateDB.enabled = true
  end

  HIDE_OUTDOOR_WORLD_STATE = HideOutdoorWorldStateDB.enabled and "1" or "0"
end

local function HideOutdoorFrames()
  if not HideOutdoorWorldStateDB.enabled then return end
  local _, instanceType = IsInInstance()
  if instanceType == "pvp" then return end

  -- Only touch the actual world-state rows, never their parent or pfUI frames.
  for i = 1, (NUM_ALWAYS_UP_UI_FRAMES or 0) do
    local row = getglobal("AlwaysUpFrame" .. i)
    if row then row:Hide() end
  end
  for i = 1, (NUM_EXTENDED_UI_FRAMES or 0) do
    local bar = getglobal("WorldStateCaptureBar" .. i)
    if bar then bar:Hide() end
  end
end

local function QueueApply()
  if not enteredWorld then return end
  -- Run once after the event dispatch, regardless of native event-handler order.
  frame:SetScript("OnUpdate", function()
    frame:SetScript("OnUpdate", nil)
    ApplySetting()
    if restoreRequested and not HideOutdoorWorldStateDB.enabled then
      restoreRequested = false
      -- Only an explicit /outdoorui show requests a native rebuild, after login.
      if type(WorldStateAlwaysUpFrame_Update) == "function" then
        WorldStateAlwaysUpFrame_Update()
      end
    else
      restoreRequested = false
      HideOutdoorFrames()
    end
  end)
end

frame:RegisterEvent("VARIABLES_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("UPDATE_WORLD_STATES")
frame:SetScript("OnEvent", function()
  ApplySetting()
  if event == "PLAYER_ENTERING_WORLD" then enteredWorld = true end
  QueueApply()
end)

SLASH_HIDEOUTDOORWORLDSTATE1 = "/outdoorui"
SlashCmdList["HIDEOUTDOORWORLDSTATE"] = function(message)
  ApplySetting()
  local command = string.lower(message or "")
  if command == "show" then
    HideOutdoorWorldStateDB.enabled = false
    restoreRequested = true
  elseif command == "hide" then
    HideOutdoorWorldStateDB.enabled = true
    restoreRequested = false
  else
    DEFAULT_CHAT_FRAME:AddMessage("HideOutdoorWorldState: /outdoorui hide | /outdoorui show")
    return
  end
  ApplySetting()
  QueueApply()
  DEFAULT_CHAT_FRAME:AddMessage("Outdoor world-state UI: " ..
    (HideOutdoorWorldStateDB.enabled and "hidden" or "shown"))
end
