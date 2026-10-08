-- Vanilla 1.12: use this/arg1 callbacks and explicit 1/0 saved options.
local defaults = {
    SHOW_SAVE_BUTTON = 1, SHOW_HEALTH = 1, SHOW_HEALTH_PERCENT = 1,
    SHOW_SHORT_NAME = 0, SHOW_RESET_BUTTON = 1, SHOW_READY_BUTTON = 1,
    SHOW_COUNTDOWN_BUTTON = 1, SHOW_CLEAR_BUTTON = 1, SHOW_SETTINGS_BUTTON = 1,
}
local tools, checks, health = {}, {}, {}
local initialized = false
local countdown = CreateFrame("Frame")
countdown:Hide()

local function Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc0ffc0[SRTI]|r " .. text)
end

function SRTI_ApplyToolDefaults(reset)
    for key, value in pairs(defaults) do
        if reset or BANANA_CONFIG[key] == nil then BANANA_CONFIG[key] = value end
    end
end

local function GroupVisible()
    if BANANA_CONFIG.ENABLED ~= 1 then return false end
    if GetNumRaidMembers() > 0 then return BANANA_CONFIG.SHOW_IN_RAID == 1 end
    if GetNumPartyMembers() > 0 then return BANANA_CONFIG.SHOW_IN_PARTY == 1 end
    return BANANA_CONFIG.SHOW_OUT_OF_GROUP == 1
end

local function Leader(assistant)
    if GetNumRaidMembers() > 0 then
        return IsRaidLeader() or (assistant and IsRaidOfficer())
    end
    return GetNumPartyMembers() == 0 or IsPartyLeader()
end

local function CanReset()
    if not ResetInstances then Print("当前客户端不支持重置副本。") return false end
    if UnitAffectingCombat("player") then Print("战斗中不能重置副本。") return false end
    if IsInInstance and IsInInstance() then
        Print("请先离开副本再重置。") return false
    end
    if not Leader(false) then Print("只有队长或团长可以重置副本。") return false end
    return true
end

StaticPopupDialogs["SRTI_RESET_INSTANCES"] = {
    text = "重置所有可重置的副本？\n请确认队友已离开副本。",
    button1 = ACCEPT, button2 = CANCEL,
    OnAccept = function() if CanReset() then ResetInstances() end end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}

local function ReadyCheck()
    if GetNumRaidMembers() + GetNumPartyMembers() == 0 then
        Print("请先加入队伍或团队。") return
    end
    if not Leader(true) then Print("就位确认需要队长、团长或助理权限。") return end
    if DoReadyCheck then DoReadyCheck() else Print("当前客户端不支持就位确认。") end
end

local function Announce(text)
    if GetNumRaidMembers() > 0 then
        SendChatMessage(text, "RAID_WARNING")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(text, "PARTY")
    else
        Print(text)
    end
end

function SRTI_StopCountdown(announce)
    if countdown.untilTime then
        countdown.untilTime = nil
        countdown:SetScript("OnUpdate", nil)
        countdown:Hide()
        if announce then Announce("倒数已取消。") end
    end
end

local function CountdownClick()
    if countdown.untilTime then SRTI_StopCountdown(true) return end
    if arg1 == "RightButton" then return end
    if not Leader(true) then Print("开怪倒数需要队长、团长或助理权限。") return end
    countdown.untilTime = GetTime() + 5
    countdown.last = 5
    Announce("5 秒后开怪！")
    countdown:SetScript("OnUpdate", function()
        if not GroupVisible() or BANANA_CONFIG.SHOW_COUNTDOWN_BUTTON ~= 1 or not Leader(true) then
            SRTI_StopCountdown(false) return
        end
        local remaining = math.max(0, math.ceil(countdown.untilTime - GetTime()))
        if remaining ~= countdown.last then
            countdown.last = remaining
            if remaining == 0 then
                Announce("开怪！")
                SRTI_StopCountdown(false)
            else
                Announce(tostring(remaining) .. " 秒")
            end
        end
    end)
    countdown:Show()
end

local function CreateTool(key, label, title, tip, color, onClick)
    local button = CreateFrame("Button", "SRTI_" .. key, UIParent)
    button:SetWidth(36)
    button:SetHeight(36)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local text = button:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    text:SetPoint("CENTER", button, "CENTER", 0, 0)
    text:SetText(label)
    text:SetTextColor(unpack(color))
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(tip, .8, .8, .8, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:Hide()
    return button
end

function SRTI_UpdateToolOptions()
    for key, check in pairs(checks) do check:SetChecked(BANANA_CONFIG[key] == 1) end
end

local function CreateOptions()
    -- Include both columns in the draggable frame's bounds for screen clamping.
    BananaConfigFrame:SetWidth(604)
    local header = getglobal("BananaConfigFramePanel1")
    local title = getglobal("BananaConfigFramePanel1LabelTitle")
    local close = getglobal("BananaConfigFrameButtonClose")
    if header then header:SetWidth(584) end
    if title then title:SetWidth(552) end
    if close and header then
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -7, -6)
    end
    local panel = CreateFrame("Frame", "SRTI_ToolOptions", BananaConfigFrame)
    panel:SetWidth(280)
    panel:SetHeight(370)
    panel:SetPoint("TOPLEFT", BananaConfigFrame, "TOPLEFT", 316, -56)
    panel:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16,
        insets={left=5, right=5, top=5, bottom=5}})
    panel:SetBackdropColor(0, 0, 0, .9)
    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -16)
    heading:SetText("标记血条与团队工具")
    local options = {
        {"SHOW_SAVE_BUTTON", "显示“存 / 还原”按钮"},
        {"SHOW_HEALTH", "显示标记目标血条"},
        {"SHOW_HEALTH_PERCENT", "血条显示生命百分比"},
        {"SHOW_SHORT_NAME", "显示短姓名（长名省略）"},
        {"SHOW_RESET_BUTTON", "显示“重置副本”按钮"},
        {"SHOW_READY_BUTTON", "显示“就位确认”按钮"},
        {"SHOW_COUNTDOWN_BUTTON", "显示“5 秒开怪倒数”按钮"},
        {"SHOW_CLEAR_BUTTON", "显示“清除全部标记”按钮"},
        {"SHOW_SETTINGS_BUTTON", "显示“设置”按钮"},
    }
    for i, option in ipairs(options) do
        local key = option[1]
        local check = CreateFrame("CheckButton", "SRTI_Option_" .. key, panel, "OptionsCheckButtonTemplate")
        check:SetWidth(24)
        check:SetHeight(24)
        check:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -38 - (i-1)*28)
        getglobal(check:GetName() .. "Text"):SetText(option[2])
        check:SetScript("OnClick", function()
            BANANA_CONFIG[key] = this:GetChecked() and 1 or 0
            if key == "SHOW_COUNTDOWN_BUTTON" then SRTI_StopCountdown(false) end
            Banana_Layout()
            Banana_UpdateStatus()
        end)
        checks[key] = check
    end
    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -300)
    note:SetWidth(244)
    note:SetHeight(54)
    note:SetJustifyH("LEFT")
    note:SetText("姓名默认关闭；完整姓名可悬停查看。\n血条仅显示可读取单位的当前生命。\n聊天栏“标”或 /srti 可随时打开设置。")
    SRTI_UpdateToolOptions()
end

-- Remove the last UTF-8 character, never split a Chinese code point.
local function ShortName(font, name)
    font:SetWidth(0)
    font:SetText(name)
    if font:GetStringWidth() > 32 then
        local prefix = name
        repeat
            local n = string.len(prefix)
            while n > 1 and string.byte(prefix, n) >= 128 and string.byte(prefix, n) < 192 do n = n - 1 end
            prefix = string.sub(prefix, 1, n-1)
            font:SetText(prefix .. "..")
        until font:GetStringWidth() <= 32 or prefix == ""
    end
    font:SetWidth(32)
end

function SRTI_UpdateHealth(index, cur)
    local bar = health[index]
    if not bar then return end
    local unit = cur.Unit
    if not cur.Target or not unit or not UnitExists(unit) or Banana_GetSymbol(unit) ~= index then
        bar:Hide()
        bar.name:Hide()
        return
    end
    local maximum = UnitHealthMax(unit) or 0
    if BANANA_CONFIG.SHOW_HEALTH == 1 and maximum > 0 then
        local dead = UnitIsDead(unit) or UnitIsGhost(unit)
        local current = dead and 0 or math.max(0, math.min(maximum, UnitHealth(unit) or 0))
        local fraction = current / maximum
        if bar.maximum ~= maximum then bar:SetMinMaxValues(0, maximum) bar.maximum = maximum end
        if bar.current ~= current then bar:SetValue(current) bar.current = current end
        if bar.fraction ~= fraction then
            bar:SetStatusBarColor(math.min(1, 2*(1-fraction)), math.min(1, 2*fraction), .15)
            bar.fraction = fraction
        end
        local text = dead and "死亡" or (math.floor(fraction*100+.5) .. "%")
        if bar.percent ~= text then bar.text:SetText(text) bar.percent = text end
        if BANANA_CONFIG.SHOW_HEALTH_PERCENT == 1 then bar.text:Show() else bar.text:Hide() end
        bar:Show()
    else
        bar:Hide()
    end
    if BANANA_CONFIG.SHOW_SHORT_NAME == 1 then
        local name = UnitName(unit) or cur.Target
        if bar.fullName ~= name then ShortName(bar.name, name) bar.fullName = name end
        bar.name:ClearAllPoints()
        if bar:IsShown() then
            bar.name:SetPoint("TOP", bar, "BOTTOM", 0, -1)
        else
            bar.name:SetPoint("TOP", cur.FrameButton, "BOTTOM", 0, -1)
        end
        bar.name:Show()
    else
        bar.name:Hide()
    end
end

function SRTI_ToolRowSpacing()
    local extra = 0
    if BANANA_CONFIG.SHOW_HEALTH == 1 then extra = extra + 12 end
    if BANANA_CONFIG.SHOW_SHORT_NAME == 1 then extra = extra + 11 end
    return 4 + extra
end

-- Follow the outside edges of every layout, including reversal and detached hunter mark.
function SRTI_LayoutTools()
    if not initialized then return end
    local flipped = BANANA_CONFIG.FLIP == 1
    local left, right, gap = "LEFT", "RIGHT", 4
    if flipped then left, right, gap = "RIGHT", "LEFT", -4 end
    local start = RaidTargetFrame1Button
    if BANANA_CONFIG.DETACH ~= 1 and BANANA_CONFIG.BUTTON_LAYOUT ~= 5 then start = RaidTargetFrame9Button end
    local ending = RaidTargetFrame8Button
    -- Vertical tools use their own column beside the top icon, clear of the blood bars.
    if BANANA_CONFIG.BUTTON_LAYOUT == 4 then start = RaidTargetFrame1Button ending = RaidTargetFrame1Button end
    local before, after = start, ending
    local order = {
        {tools.ready, "SHOW_READY_BUTTON", true},
        {tools.countdown, "SHOW_COUNTDOWN_BUTTON", true},
        {getglobal("SRTI_SaveBtn"), "SHOW_SAVE_BUTTON", false},
        {tools.clear, "SHOW_CLEAR_BUTTON", false},
        {tools.reset, "SHOW_RESET_BUTTON", false},
        {tools.settings, "SHOW_SETTINGS_BUTTON", false},
    }
    for _, item in ipairs(order) do
        local button = item[1]
        if button then
            button:SetScale(BANANA_CONFIG.BUTTON_SCALE / 100)
            button:ClearAllPoints()
            if item[3] then button:SetPoint(right, before, left, -gap, 0)
            else button:SetPoint(left, after, right, gap, 0) end
            if BANANA_CONFIG[item[2]] == 1 then
                if item[3] then before = button else after = button end
            end
        end
    end
    SRTI_UpdateTools()
end

function SRTI_UpdateTools()
    if not initialized then return end
    local visible = GroupVisible()
    local options = {ready="SHOW_READY_BUTTON", countdown="SHOW_COUNTDOWN_BUTTON",
        clear="SHOW_CLEAR_BUTTON", reset="SHOW_RESET_BUTTON", settings="SHOW_SETTINGS_BUTTON"}
    for key, option in pairs(options) do
        if visible and BANANA_CONFIG[option] == 1 then tools[key]:Show() else tools[key]:Hide() end
    end
    local save = getglobal("SRTI_SaveBtn")
    if save then
        if visible and BANANA_CONFIG.SHOW_SAVE_BUTTON == 1 then save:Show() else save:Hide() end
    end
    if not visible then SRTI_StopCountdown(false) end
end

function SRTI_InitTools()
    if initialized then return end
    SRTI_ApplyToolDefaults()
    tools.ready = CreateTool("ReadyButton", "位", "就位确认", "左键：发起就位确认", {.4, .9, .4},
        function() if arg1 == "LeftButton" then ReadyCheck() end end)
    tools.countdown = CreateTool("CountdownButton", "倒", "开怪倒数", "左键：开始 / 取消 5 秒倒数；右键：取消", {1, .8, .3}, CountdownClick)
    tools.clear = CreateTool("ClearButton", "清", "清除全部标记", "左键：清除场上全部团队标记；保留已保存的记录", {1, .4, .4},
        function() if arg1 == "LeftButton" then Banana_ClearAllSymbols() Banana_UpdateStatus() end end)
    tools.reset = CreateTool("ResetButton", "重", "重置副本", "左键：确认后重置副本（需离开副本并拥有队长权限）", {1, .75, .35},
        function() if arg1 == "LeftButton" and CanReset() then StaticPopup_Show("SRTI_RESET_INSTANCES") end end)
    tools.settings = CreateTool("SettingsButton", "设", "标记助手设置", "左键：打开 / 关闭设置面板", {.4, .75, 1},
        function() if arg1 == "LeftButton" then Banana_Toggle() end end)
    for index = 1, 9 do
        local button = getglobal("RaidTargetFrame" .. index .. "Button")
        local bar = CreateFrame("StatusBar", "SRTI_Health" .. index, button)
        bar:SetWidth(32)
        bar:SetHeight(9)
        bar:SetPoint("TOP", button, "BOTTOM", 0, -1)
        bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        bar:EnableMouse(false)
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(.05, .05, .05, .9)
        bar.text = bar:CreateFontString(nil, "OVERLAY")
        bar.text:SetFont(STANDARD_TEXT_FONT, 8, "OUTLINE")
        bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
        bar.text:SetTextColor(1, 1, 1)
        -- Parent the name to the icon so it can stay visible with health disabled.
        bar.name = button:CreateFontString(nil, "OVERLAY")
        bar.name:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        bar.name:SetHeight(10)
        bar.name:SetJustifyH("CENTER")
        bar.name:SetTextColor(.9, .9, .9)
        bar:Hide()
        bar.name:Hide()
        health[index] = bar
    end
    CreateOptions()
    initialized = true
    local onShow = BananaConfigFrame:GetScript("OnShow")
    local onHide = BananaConfigFrame:GetScript("OnHide")
    BananaConfigFrame:SetScript("OnShow", function()
        if onShow then onShow() end
        SRTI_UpdateToolOptions()
        Banana_UpdateStatus()
    end)
    BananaConfigFrame:SetScript("OnHide", function()
        if onHide then onHide() end
        Banana_UpdateStatus()
    end)
    SRTI_LayoutTools()
    Banana_UpdateStatus()
end
