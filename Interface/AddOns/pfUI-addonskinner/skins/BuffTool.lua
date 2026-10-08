-- pfUI-addonskinner skin for BuffTool
-- Targets the config window (BuffToolConfigFrame, created lazily by /bufftool config).
-- The top-level BuffTool frame and the per-aura effect frames are transparent
-- containers (no backdrop) and are intentionally left untouched.

local addon = "BuffTool"

-- Debug flags (global, for /run print verification)
_G.FLAG_RAN  = _G.FLAG_RAN  or 0
_G.FLAG_OK   = _G.FLAG_OK   or false
_G.FLAG_ERR  = _G.FLAG_ERR  or nil

local function SkinAddon()
  _G.FLAG_RAN = _G.FLAG_RAN + 1

  -- Respect the GUI "Disable Skin XXX" toggle (semantic is reversed: "1" = disabled)
  local disabled = false
  pcall(function()
    if C and C.addonskinner and C.addonskinner.disabled and C.addonskinner.disabled[addon] == "1" then
      disabled = true
    end
  end)
  if disabled then return end

  if not pfUI or not pfUI.api then return end

  local penv = pfUI:GetEnvironment()
  local StripTextures  = penv.StripTextures
  local CreateBackdrop = penv.CreateBackdrop
  local SkinButton     = penv.SkinButton
  local SkinCheckbox   = penv.SkinCheckbox
  local SkinScrollbar  = penv.SkinScrollbar

  -- pfUI close icon (graceful fallback if media key is missing)
  local closeTex = (pfUI.media and pfUI.media["img:close"]) or "Interface\\AddOns\\pfUI\\img\\close"

  -- Custom close button: avoids the shared global texture name conflict of
  -- SkinCloseButton by reusing the button's own NormalTexture.
  local function SkinCustomCloseButton(b)
    pcall(function()
      SkinButton(b, 1, .25, .25)
      b:SetWidth(15)
      b:SetHeight(15)

      b:SetNormalTexture(closeTex)
      local nt = b:GetNormalTexture()
      if nt then
        nt:SetTexture(closeTex)
        nt:SetVertexColor(1, .25, .25, 1)
        nt:SetTexCoord(0, 1, 0, 1)
      end

      b:SetPushedTexture("")
      b:SetHighlightTexture("")
      b:SetDisabledTexture("")
    end)
  end

  local function SkinFrame()
    local frame = _G["BuffToolConfigFrame"]
    if not frame or frame.pfui_skinned then return end

    -- Replace the DialogBox backdrop with pfUI backdrop
    frame:SetBackdrop(nil)
    pcall(StripTextures, frame, true)
    CreateBackdrop(frame, nil, nil, .9)

    -- Title -> pfUI gold
    for _, child in ipairs({ frame:GetChildren() }) do
      if child:GetObjectType() == "FontString" then
        child:SetTextColor(1, 0.82, 0.2, 1)
      end
    end

    -- Children: close button (no text) vs action buttons (have text)
    for _, child in ipairs({ frame:GetChildren() }) do
      local ot = child:GetObjectType()
      if ot == "Button" then
        local txt = child:GetText()
        if txt and txt ~= "" then
          SkinButton(child)
        else
          SkinCustomCloseButton(child)
        end
      end
    end

    -- Scrollbar
    local sb = _G["BuffToolConfigScrollFrameScrollBar"]
    if sb then pcall(SkinScrollbar, sb) end

    -- Checkboxes inside the scroll content (scroll child)
    local sf = _G["BuffToolConfigScrollFrame"]
    if sf and sf.GetScrollChild then
      local content = sf:GetScrollChild()
      if content then
        for _, row in ipairs({ content:GetChildren() }) do
          if row and row:GetObjectType() == "CheckButton" then
            SkinCheckbox(row, 20)
          end
        end
      end
    end

    frame.pfui_skinned = true
  end

  -- Poll until the config window is created, then skin + hook OnShow for re-skins
  local wait = CreateFrame("Frame")
  wait:SetScript("OnUpdate", function()
    local frame = _G["BuffToolConfigFrame"]
    if frame then
      SkinFrame()

      local orig = frame:GetScript("OnShow")
      frame:SetScript("OnShow", function()
        if orig then pcall(orig) end
        SkinFrame()
      end)

      wait:SetScript("OnUpdate", nil)
    end
  end)

  _G.FLAG_OK = true
end

-- (1) Register with addonskinner (GUI list / unified disable), pcall-safe
pcall(function()
  if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
    pfUI.addonskinner:RegisterSkin(addon, SkinAddon)
  end
end)

-- (2) Self-contained trigger: guarantees execution regardless of load order
local trig = CreateFrame("Frame")
trig:RegisterEvent("ADDON_LOADED")
trig:RegisterEvent("VARIABLES_LOADED")
trig:RegisterEvent("PLAYER_LOGIN")
trig:SetScript("OnEvent", function()
  -- Re-register if addonskinner became ready later
  pcall(function()
    if pfUI and pfUI.addonskinner and type(pfUI.addonskinner.RegisterSkin) == "function" then
      pfUI.addonskinner:RegisterSkin(addon, SkinAddon)
    end
  end)

  if event == "ADDON_LOADED" and arg1 ~= addon then return end
  if IsAddOnLoaded(addon) then
    pcall(SkinAddon)
    trig:UnregisterAllEvents()
  end
end)
