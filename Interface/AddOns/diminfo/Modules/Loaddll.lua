-- 创建模组状态显示框（按钮）
local diminfo_Loaddll = CreateFrame("Button", "diminfo_Loaddll", UIParent)
local Text = diminfo_Loaddll:CreateFontString(nil, "OVERLAY")
Text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
Text:SetPoint("LEFT", diminfo_pos, "RIGHT", 20, 0)   -- 确保 diminfo_pos 已定义
diminfo_Loaddll:SetAllPoints(Text)

-- 颜色定义
local colorLoaded = {1, 1, 1}
local colorNotLoaded = {0.38, 0.38, 0.38}
local colorName = {0.3, 1, 0.6}

-- 更新模组状态显示（并调整按钮大小）
local function UpdateAddonStatus()
    local sStatus = SUPERWOW_STRING and colorLoaded or colorNotLoaded
    local uStatus = (type(UnitXP) == "function" and pcall(UnitXP, "nop", "nop")) and colorLoaded or colorNotLoaded
    -- 使用更严谨的检测方式
    local wStatus = (type(WSLoot) == "table") and colorLoaded or colorNotLoaded
    local nStatus = (type(GetNampowerVersion) == "function") and colorLoaded or colorNotLoaded

    Text:SetText(string.format("|cff%02x%02x%02xS|r |cff%02x%02x%02xU|r |cff%02x%02x%02xW|r |cff%02x%02x%02xN|r",
        sStatus[1]*255, sStatus[2]*255, sStatus[3]*255,
        uStatus[1]*255, uStatus[2]*255, uStatus[3]*255,
        wStatus[1]*255, wStatus[2]*255, wStatus[3]*255,
        nStatus[1]*255, nStatus[2]*255, nStatus[3]*255))

    local width = Text:GetStringWidth() + 4
    local height = Text:GetHeight() + 4
    diminfo_Loaddll:SetWidth(width)
    diminfo_Loaddll:SetHeight(height)
end

-- 鼠标提示（动态显示可用功能，未加载不显示）
diminfo_Loaddll:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("模组状态")

    local nameColorCode = string.format("|cff%02x%02x%02x",
        colorName[1]*255, colorName[2]*255, colorName[3]*255)

    -- 检测加载状态
    local superwowLoaded = SUPERWOW_STRING ~= nil
    local unitXPLoaded = type(UnitXP) == "function" and pcall(UnitXP, "nop", "nop")
    local wslootLoaded = type(WSLoot) == "table"
    local nampowerLoaded = type(GetNampowerVersion) == "function"

    -- 获取版本信息
    local function GetSuperWowVer()
        if superwowLoaded and SUPERWOW_VERSION then
            return SUPERWOW_VERSION
        end
        return nil
    end

    local function GetUnitXPVer()
        if unitXPLoaded then
            local success, timestamp = pcall(UnitXP, "version", "coffTimeDateStamp")
            if success and timestamp then
                return date("%Y-%m-%d", timestamp)
            end
        end
        return nil
    end

    -- 修正：使用 pcall 调用 WSLoot.GetVersion
    local function GetWSLootVer()
        if wslootLoaded and type(WSLoot.GetVersion) == "function" then
            local ok, ver = pcall(WSLoot.GetVersion)
            if ok and ver then
                return ver   -- 假设返回版本字符串（如 "1.2.3"）
            end
        end
        return nil
    end

    local function GetNampowerVer()
        if nampowerLoaded then
            local major, minor, patch = GetNampowerVersion()
            if major then
                return string.format("%d.%d.%d", major, minor or 0, patch or 0)
            end
        end
        return nil
    end

    local function BuildStatusLine(name, loaded, version)
        local statusText = loaded and ("|cFFFFD700已加载|r") or ("|cFF808080未加载|r")
        local versionText = version and (" (v"..version..")") or ""
        return nameColorCode..name..":|r "..statusText..versionText
    end

    GameTooltip:AddLine(BuildStatusLine("SuperWOW", superwowLoaded, GetSuperWowVer()))
    GameTooltip:AddLine(BuildStatusLine("UnitXP", unitXPLoaded, GetUnitXPVer()))
    GameTooltip:AddLine(BuildStatusLine("WSLoot", wslootLoaded, GetWSLootVer()))
    GameTooltip:AddLine(BuildStatusLine("Nampower", nampowerLoaded, GetNampowerVer()))

    -- 仅当有功能时才添加分隔线和操作说明
    local hasFunction = false
    if TWTMain then
        hasFunction = true
    end
    if ShaguDPSWindow or DPSMate or DPSMateX then
        hasFunction = true
    end

    if hasFunction then
        GameTooltip:AddLine(" ")
        if TWTMain then
            GameTooltip:AddLine("左键: 显/隐 TWT 仇恨统计", 0.3, 1, 0.6)
        end
        if ShaguDPSWindow then
            GameTooltip:AddLine("右键: 显/隐 ShaguDPS 窗口", 0.3, 1, 0.6)
        elseif DPSMate then
            GameTooltip:AddLine("右键: 显/隐 DPSMate 统计", 0.3, 1, 0.6)
        elseif DPSMateX then
            GameTooltip:AddLine("右键: 显/隐 DPSMateX 统计", 0.3, 1, 0.6)
        end
    end

    GameTooltip:Show()
end)

diminfo_Loaddll:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 鼠标点击处理（修复 ShaguDPS 多窗口切换）
diminfo_Loaddll:SetScript("OnMouseDown", function()
    local button = arg1
    if button == "LeftButton" then
        if TWTMain and TWTMain.IsVisible then
            if TWTMain:IsVisible() then
                TWTMain:Hide()
            else
                TWTMain:Show()
            end
        end
    elseif button == "RightButton" then
        if ShaguDPSWindow then
            local visible = ShaguDPSWindow:IsVisible()
            for k, v in pairs(_G) do
                if type(k) == "string" and string.match(k, "^ShaguDPSWindow") and type(v) == "table" and v.IsVisible then
                    if visible then
                        v:Hide()
                    else
                        v:Show()
                    end
                end
            end
        elseif DPSMate then
            if DPSMate_DPSMate and DPSMate_DPSMate:IsVisible() then
                DPSMate_DPSMate:Hide()
            elseif DPSMate_DPSMate then
                DPSMate_DPSMate:Show()
            end
        elseif DPSMateX then
            if DPSMateX_DPSMate and DPSMateX_DPSMate:IsVisible() then
                DPSMateX_DPSMate:Hide()
            elseif DPSMateX_DPSMate then
                DPSMateX_DPSMate:Show()
            end
        end
    end
end)

-- 注册事件
diminfo_Loaddll:RegisterEvent("PLAYER_LOGIN")
diminfo_Loaddll:RegisterEvent("ADDON_LOADED")
diminfo_Loaddll:SetScript("OnEvent", UpdateAddonStatus)