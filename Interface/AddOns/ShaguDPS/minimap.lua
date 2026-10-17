-- ============================================================================
-- ShaguDPS 小地图按钮
-- 左键打开/关闭设置窗口；可拖动，角度存于 config.minimap_angle。
-- by 武藤纯子酱 2026.10.12
-- ============================================================================

local config = ShaguDPS.config

local button = CreateFrame("Button", "ShaguDPSMinimapButton", Minimap)
button:SetWidth(32)
button:SetHeight(32)
button:SetFrameStrata("MEDIUM")
button:SetFrameLevel(8)
button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- 图标
local icon = button:CreateTexture(nil, "BACKGROUND")
icon:SetWidth(20)
icon:SetHeight(20)
icon:SetPoint("CENTER", button, "CENTER", 0, 1)
icon:SetTexture("Interface\\AddOns\\ShaguDPS\\img\\battlenet-portrait")
button.icon = icon

-- 边框
local overlay = button:CreateTexture(nil, "OVERLAY")
overlay:SetWidth(53)
overlay:SetHeight(53)
overlay:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- 拖动
button:SetMovable(true)
button:EnableMouse(true)
button:RegisterForDrag("LeftButton")
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local function UpdatePosition()
    local angle = config.minimap_angle or 180
    local x = 80 * cos(angle)
    local y = 80 * sin(angle)
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

button:SetScript("OnDragStart", function()
    this:LockHighlight()
    this:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale

        config.minimap_angle = math.deg(math.atan2(py - my, px - mx))
        UpdatePosition()
    end)
end)

button:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
    this:UnlockHighlight()
    if ShaguDPS.SaveConfig then ShaguDPS.SaveConfig() end
end)

-- 左键：打开/关闭设置窗口
button:SetScript("OnClick", function()
    ShaguDPS.ToggleSettingsWindows()
end)

button:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    GameTooltip:AddLine("Shagu|cffffffffDPS")
    GameTooltip:AddLine("左键：打开/关闭设置窗口", 1, 1, 1)
    GameTooltip:Show()
end)

button:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

UpdatePosition()
button:Show()

ShaguDPS.minimapButton = button
