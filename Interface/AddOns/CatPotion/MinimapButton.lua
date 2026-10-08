--[[
独立小地图入口：点击切换主设置界面，左键拖动调整位置。
位置只保存 minimapAngle，登录时按固定半径 80 重新计算坐标；这种方式能适配不同 UI 缩放。
图标、按钮和 SavedVariables 都属于 CatPotion，不要改为调用 Cat/Cat2 的小地图共享模块。
]]

local addon = CatPotionAddon
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    local button = CreateFrame("Button", "CatPotionMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:EnableMouse(true)

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\Icons\\inv_potion_128")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetWidth(53)
    border:SetHeight(53)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local database = addon.GetDatabase()
    -- angle 会在拖动结束时写回每角色数据库，解决重新登录后位置复位的问题。
    local angle = database.minimapAngle or 2.05
    local radius = 80
    local dragging = false
    local moved = false

    local function PositionButton()
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
    end
    local function UpdateDragPosition()
        local scale = Minimap:GetEffectiveScale()
        local cursorX, cursorY = GetCursorPosition()
        local centerX, centerY = Minimap:GetCenter()
        cursorX = cursorX / scale
        cursorY = cursorY / scale
        angle = math.atan2(cursorY - centerY, cursorX - centerX)
        moved = true
        PositionButton()
    end

    PositionButton()
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnMouseDown", function()
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", button, "CENTER", 1, 0)
        icon:SetAlpha(0.82)
    end)
    button:SetScript("OnMouseUp", function()
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", button, "CENTER", 0, 1)
        icon:SetAlpha(1)
    end)
    button:SetScript("OnDragStart", function()
        dragging = true
        moved = false
        button:SetScript("OnUpdate", UpdateDragPosition)
    end)
    button:SetScript("OnDragStop", function()
        button:SetScript("OnUpdate", nil)
        dragging = false
        icon:ClearAllPoints()
        icon:SetPoint("CENTER", button, "CENTER", 0, 1)
        icon:SetAlpha(1)
        local currentDatabase = addon.GetDatabase()
        currentDatabase.minimapAngle = angle
    end)
    button:SetScript("OnClick", function()
        if dragging or moved then
            moved = false
            return
        end
        addon.ToggleSettings()
    end)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_LEFT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("Cat - Potion  药剂管理", 1, 0.82, 0.2)
        GameTooltip:AddLine("点击：打开 / 关闭主设置界面", 0.55, 0.7, 0.85)
        GameTooltip:AddLine("拖动：调整小地图图标位置", 0.55, 0.58, 0.62)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
end)
