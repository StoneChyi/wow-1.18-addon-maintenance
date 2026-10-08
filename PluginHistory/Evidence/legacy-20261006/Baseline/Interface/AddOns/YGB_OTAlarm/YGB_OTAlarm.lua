--[[
YGB_OTAlarm - 简单空框面板
作者: 烟锅巴
版本: 1.0.1

最简单的可移动面板，只有一个空框和显示命令
]]

-- 创建基本的命名空间
YGB_OTAlarm = YGB_OTAlarm or {}

-- 定义全局backdrop变量，用于文本输入框等UI元素
local backdrop = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
}

-- 初始化持久化数据
YGB_OTAlarmDB = YGB_OTAlarmDB or {
    threshold = 80,

    yellMessage = "",
    showThreatBar = true,
    debugMode = false,
    enableYell = false,
    channelSettings = {
        SAY = false,
        YELL = true,
        GUILD = false,
        RAID = false
    },
    -- 仇恨条相关设置
    barLength = 200,
    barHeight = 20,
    barScale = 1,
    -- 仇恨条位置
    threatBarPosition = {
        point = "TOP",
        relativeTo = "UIParent",
        relativePoint = "TOP",
        x = 0,
        y = -100
    },
    -- 距离检测相关设置（借鉴TargetDistance插件）
    desc = true,
    showDeadDistance = false,
    pp = 1, -- player <--> pet
    linearYardsFrom = 8,
    linearYardsTo = 42,
    linearColor = true,
    linearColorFrom = { 0, 1, 0 },
    linearColorTo = { 1, 0, 0 },
    faceColor = { 1, 0, 0.5 },
    meleeColor = { 0, 1, 0 },
    blinkColor = { 1, 1, 0 },
    fontSize = 21,
    fontSizePp = 16,
    fontColor = { 0, 1, 0 },
    fontColorPp = { 0, 1, 0 },
    rangedColor = false,
    rangedColor1 = { 1, 0, 0 }, -- 近战
    userColors = {},
    showFaceWarning = true, -- 控制打脸提示的显示
    playFaceWarningSound = true, -- 控制打脸提示的声音播放
    playFaceWarningSoundOnlyGroup = true, -- 仅在团队中播放打脸提示音
    intelligentPlayFaceWarningSound = false,
    mouseoverTooltipDistance = false -- 鼠标指向目标时在tooltip显示与目标的距离
}

-- 加载保存的设置
YGB_OTAlarm.threshold = YGB_OTAlarmDB.threshold
YGB_OTAlarm.yellMessage = YGB_OTAlarmDB.yellMessage
-- 加载仇恨条相关设置
YGB_OTAlarm.barLength = YGB_OTAlarmDB.barLength
YGB_OTAlarm.barHeight = YGB_OTAlarmDB.barHeight
YGB_OTAlarm.barScale = YGB_OTAlarmDB.barScale
-- 确保仇恨条位置数据存在
YGB_OTAlarmDB.threatBarPosition = YGB_OTAlarmDB.threatBarPosition or {
    point = "TOP",
    relativeTo = "UIParent",
    relativePoint = "TOP",
    x = 0,
    y = -100
}
-- 正确处理showThreatBar
if YGB_OTAlarmDB.showThreatBar == nil then
    YGB_OTAlarm.showThreatBar = false
else
    YGB_OTAlarm.showThreatBar = YGB_OTAlarmDB.showThreatBar ~= 0
end
-- 正确处理debugMode
if YGB_OTAlarmDB.debugMode == nil then
    YGB_OTAlarm.debugMode = true
else
    YGB_OTAlarm.debugMode = YGB_OTAlarmDB.debugMode ~= 0
end
-- 正确处理enableYell
if YGB_OTAlarmDB.enableYell == nil then
    YGB_OTAlarm.enableYell = true
else
    YGB_OTAlarm.enableYell = YGB_OTAlarmDB.enableYell ~= 0
end
-- 正确处理showCoverBar
if YGB_OTAlarmDB.showCoverBar == nil then
    YGB_OTAlarm.showCoverBar = true
else
    YGB_OTAlarm.showCoverBar = YGB_OTAlarmDB.showCoverBar ~= 0
end

-- 正确处理showDistanceBar
if YGB_OTAlarmDB.showDistanceBar == nil then
    YGB_OTAlarm.showDistanceBar = false
else
    YGB_OTAlarm.showDistanceBar = YGB_OTAlarmDB.showDistanceBar ~= 0
end

-- 确保 YGB_OTAlarmDB.debugMode 存在
if YGB_OTAlarmDB.debugMode == nil then
    YGB_OTAlarmDB.debugMode = 1 -- 默认开启
end
-- 确保 YGB_OTAlarmDB.showCoverBar 存在
if YGB_OTAlarmDB.showCoverBar == nil then
    YGB_OTAlarmDB.showCoverBar = 1 -- 默认开启
end
-- 确保 YGB_OTAlarmDB.showDistanceBar 存在
if YGB_OTAlarmDB.showDistanceBar == nil then
    YGB_OTAlarmDB.showDistanceBar = 0 -- 默认关闭
end

-- 确保 YGB_OTAlarmDB.channelSettings 存在
YGB_OTAlarmDB.channelSettings = YGB_OTAlarmDB.channelSettings or {
    SAY = false,
    YELL = true,
    GUILD = false,
    RAID = false
}

-- 确保 YGB_OTAlarm.channelSettings 存在
YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings

-- 跟踪已喊话的目标
YGB_OTAlarm.yelledTargets = YGB_OTAlarm.yelledTargets or {}
-- 跟踪已语音报警的目标
YGB_OTAlarm.soundedTargets = YGB_OTAlarm.soundedTargets or {}

-- 跟踪当前目标
YGB_OTAlarm.currentTarget = nil

-- 距离检测相关变量（借鉴TargetDistance插件）
local nextSoundPlayTime = 0
local iplay = 1
local cantload = nil

-- 基本常量定义
local PANEL_WIDTH = 400
local PANEL_HEIGHT = 425
local PANEL_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {
        left = 4,
        right = 4,
        top = 4,
        bottom = 4
    }
}

-- TWT消息处理相关变量
local twtUpdateTick = 0

-- 兼容性常量定义
BOOKTYPE_SPELL = BOOKTYPE_SPELL or "spell"
BOOKTYPE_PET = BOOKTYPE_PET or "pet"

-- 初始化全局表
if not ShaguPlates then ShaguPlates = {} end
if not ShaguPlates.threatData then ShaguPlates.threatData = {} end
if not tracked_guids then tracked_guids = {} end

-- 战斗显示功能
local function CreateCombatDisplayFrame()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTER_COMBAT")
    frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    
    -- 检查当前战斗状态并更新UI
    local function UpdateCombatDisplay()
        if YGB_OTAlarm.combatOnly then
            if UnitAffectingCombat("player") then
                -- 在战斗中，显示UI
                if YGB_OTAlarm.threatBar and YGB_OTAlarmDB.showThreatBar then
                    YGB_OTAlarm.threatBar:Show()
                    if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.showCoverBar then
                        YGB_OTAlarm.secondThreatBar:Show()
                    end
                    if YGB_OTAlarm.distanceBar and YGB_OTAlarm.showDistanceBar then
                        YGB_OTAlarm.distanceBar:Show()
                    end
                end
            else
                -- 不在战斗中，隐藏UI
                if YGB_OTAlarm.threatBar then
                    YGB_OTAlarm.threatBar:Hide()
                    if YGB_OTAlarm.secondThreatBar then
                        YGB_OTAlarm.secondThreatBar:Hide()
                    end
                    if YGB_OTAlarm.distanceBar then
                        YGB_OTAlarm.distanceBar:Hide()
                    end
                end
            end
        end
    end
    
    frame:SetScript("OnEvent", function() 
        if event == "PLAYER_ENTER_COMBAT" then
            -- 进入战斗，显示UI
            if YGB_OTAlarm.combatOnly then
                if YGB_OTAlarm.threatBar and YGB_OTAlarmDB.showThreatBar then
                    YGB_OTAlarm.threatBar:Show()
                    if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.showCoverBar then
                        YGB_OTAlarm.secondThreatBar:Show()
                    end
                    if YGB_OTAlarm.distanceBar and YGB_OTAlarm.showDistanceBar then
                        YGB_OTAlarm.distanceBar:Show()
                    end
                end
            end
        elseif event == "PLAYER_LEAVE_COMBAT" then
            -- 离开战斗，隐藏UI
            if YGB_OTAlarm.combatOnly then
                if YGB_OTAlarm.threatBar then
                    YGB_OTAlarm.threatBar:Hide()
                    if YGB_OTAlarm.secondThreatBar then
                        YGB_OTAlarm.secondThreatBar:Hide()
                    end
                    if YGB_OTAlarm.distanceBar then
                        YGB_OTAlarm.distanceBar:Hide()
                    end
                end
            end
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- 游戏加载完成，检查当前战斗状态
            UpdateCombatDisplay()
        end
    end)
    
    -- 初始检查战斗状态
    UpdateCombatDisplay()
    
    return frame
end

-- 创建战斗显示帧
YGB_OTAlarm.combatDisplayFrame = CreateCombatDisplayFrame()

-- 根据仇恨值生成颜色代码 (值越小越绿，值越大越红)
local function GetThreatColorCode(value)
    value = math.max(0, math.min(100, tonumber(value) or 0))
    local r, g

    if value < 50 then
        -- 绿色到黄色 (0-50%)
        r = value / 50
        g = 1
    else
        -- 黄色到红色 (50-100%)
        r = 1
        g = 1 - (value - 50) / 50
    end

    -- 将RGB值转换为十六进制颜色代码
    local hex_r = string.format("%02x", math.floor(r * 255))
    local hex_g = string.format("%02x", math.floor(g * 255))
    local hex_b = "00"  -- 蓝色始终为0

    return "|cff" .. hex_r .. hex_g .. hex_b
end

-- 处理TWT仇恨数据
local function ProcessTWTData(guid)
    local player_name = UnitName("player")
    local target_name = UnitName(guid)
    local my_threat_perc = nil
    local second_threat_name = nil
    local second_threat_perc = nil

    -- 初始化ShaguPlates和threatData表
    if not ShaguPlates then ShaguPlates = {} end
    if not ShaguPlates.threatData then ShaguPlates.threatData = {} end

    -- 从TWT.tankModeThreats获取多目标仇恨数据
    if TWT and TWT.tankModeThreats then
        for k, v in pairs(TWT.tankModeThreats) do
            if v.guid and v.guid == guid then
                -- 存储第二仇恨信息
                if v.name and v.perc then
                    ShaguPlates.threatData[guid] = ShaguPlates.threatData[guid] or {}
                    ShaguPlates.threatData[guid].int_second_threat = math.floor(tonumber(v.perc))
                    ShaguPlates.threatData[guid].second_threat_name = v.name
                    second_threat_name = v.name
                    second_threat_perc = v.perc
                end
                break
            end
        end
    end

    -- 从TWT.threats获取玩家仇恨数据
    if TWT and TWT.threats then
        -- 记录玩家自己的仇恨百分比
        for k, v in pairs(TWT.threats) do
            if k == player_name then
                if type(v) == "table" and v.perc then
                    my_threat_perc = v.perc
                elseif type(v) == "number" then
                    my_threat_perc = tostring(v)
                end
            end
        end

        -- 查找100%仇恨目标
        local top_threat_name = nil
        local top_threat_perc = 0
        for k, v in pairs(TWT.threats) do
            local perc = 0
            if type(v) == "table" and v.perc then
                perc = tonumber(v.perc)
            elseif type(v) == "number" then
                perc = v
            end
            if perc > top_threat_perc and k ~= "-Pull Aggro at-" then
                top_threat_perc = perc
                top_threat_name = k
            end
        end

        -- 存储仇恨数据
        ShaguPlates.threatData[guid] = ShaguPlates.threatData[guid] or {}
        if my_threat_perc then
            local int_my_threat = math.floor(tonumber(my_threat_perc))
            ShaguPlates.threatData[guid].int_my_threat = int_my_threat
        end

        -- 当自己是最高仇恨时，查找第二仇恨
        if top_threat_name == player_name then
            local second_threat = 0
            local second_threat_player = "无"
            if TWT and TWT.threats then
                for k, v in pairs(TWT.threats) do
                    if k ~= player_name and k ~= "-Pull Aggro at-" then
                        local perc = 0
                        if type(v) == "table" and v.perc then
                            perc = tonumber(v.perc)
                        elseif type(v) == "number" then
                            perc = v
                        end
                        if perc > second_threat then
                            second_threat = perc
                            second_threat_player = k
                        end
                    end
                end
            end
            if second_threat > 0 then
                ShaguPlates.threatData[guid].int_second_threat = math.floor(second_threat)
                ShaguPlates.threatData[guid].second_threat_name = second_threat_player
            end
        end
    end
end

-- 处理TWT仇恨数据更新消息
local function OnChatMsgAddon(prefix, message, channel, sender)
    -- 处理TWTv4=和TMTv1=两种格式的消息
    if prefix == "TWT" and (string.find(message, "TWTv4=") or string.find(message, "TMTv1=")) then
        -- 检查TWT更新时间间隔，确保不超过0.3秒 [烟锅巴：2026-02-12 12:00:00]
        local currentTime = GetTime()
        if currentTime - twtUpdateTick >= 0.3 then
            twtUpdateTick = currentTime
            -- 处理TWT仇恨数据
            if UnitExists("target") then
                local targetGUID = nil
                if UnitGUID then
                    targetGUID = UnitGUID("target")
                end
                if targetGUID then
                    ProcessTWTData(targetGUID)
                end
            end
            -- TWT仇恨数据更新，触发所有血条更新
            for _, plate in pairs({ WorldFrame:GetChildren() }) do
                if plate:GetObjectType() == "Frame" and plate:GetName() and string.find(plate:GetName(), "NamePlate") then
                    local healthBar = plate:GetChildren()
                    if healthBar then
                        -- 模拟健康值变化以触发更新
                        local currentValue = healthBar:GetValue()
                        healthBar:SetValue(currentValue)
                    end
                end
            end
        end
    end
end

-- 创建空框面板函数
function YGB_OTAlarm:CreateEmptyPanel()
    -- 只创建一次面板
    if not self.panel then
        -- 确保 YGB_OTAlarmDB 存在
        YGB_OTAlarmDB = YGB_OTAlarmDB or {
            threshold = 80,

            yellMessage = "",
            showThreatBar = false,
            debugMode = true,
            enableYell = true,
            channelSettings = {
                SAY = false,
                YELL = true,
                GUILD = false,
                RAID = false
            }
        }
        
        -- 确保 YGB_OTAlarmDB.channelSettings 存在
        YGB_OTAlarmDB.channelSettings = YGB_OTAlarmDB.channelSettings or {
            SAY = false,
            YELL = true,
            GUILD = false,
            RAID = false
        }
        
        -- 确保 YGB_OTAlarm.channelSettings 存在
        YGB_OTAlarm.channelSettings = YGB_OTAlarm.channelSettings or YGB_OTAlarmDB.channelSettings
        
        -- 创建基本框架，没有任何额外元素
        self.panel = CreateFrame("Frame", "YGB_OTAlarm_EmptyFrame", UIParent)
        self.panel:SetWidth(PANEL_WIDTH)
        self.panel:SetHeight(PANEL_HEIGHT)
        self.panel:SetPoint("CENTER", UIParent, "CENTER")
        self.panel:SetBackdrop(PANEL_BACKDROP)
        self.panel:SetMovable(true)
        self.panel:EnableMouse(true)
        
        -- 整个面板都可以拖拽 - 优化拖拽功能
        self.panel:SetMovable(true)
        self.panel:EnableMouse(true)
        self.panel:RegisterForDrag("LeftButton")  -- 明确指定左键拖拽
        
        -- 使用闭包中的panel引用，而不是依赖参数
        local panel = self.panel
        
        self.panel:SetScript("OnDragStart", function() 
            panel:StartMoving() 
            panel.isMoving = true
        end)
        self.panel:SetScript("OnDragStop", function() 
            panel:StopMovingOrSizing() 
            panel.isMoving = false
        end)
        -- 额外添加鼠标按下和释放事件作为备用
        self.panel:SetScript("OnMouseDown", function(_, button) 
            if button == "LeftButton" then
                panel:StartMoving()
                panel.isMoving = true
            end
        end)
        self.panel:SetScript("OnMouseUp", function() 
            if panel.isMoving then
                panel:StopMovingOrSizing()
                panel.isMoving = false
            end
        end)
        
        -- 添加标题文字
        self.panel.title = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.title:SetPoint("TOP", self.panel, "TOP", 0, -10)
        self.panel.title:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
        self.panel.title:SetTextColor(1, 1, 1, 1)
        self.panel.title:SetText("烟锅巴原创-OT报警器")
        
        -- 添加版本号显示
        self.panel.version = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.version:SetPoint("LEFT", self.panel.title, "RIGHT", 10, 0)
        self.panel.version:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.version:SetTextColor(1, 1, 1, 1)
        -- 直接使用硬编码的版本号，因为GetAddOnMetadata在WoW 1.12中可能不存在
        self.panel.version:SetText("v2.1 2026-02-16")
        
        -- 添加关闭按钮
        self.panel.closeButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.closeButton:SetPoint("TOPRIGHT", self.panel, "TOPRIGHT", -10, -10)
        self.panel.closeButton:SetWidth(20)
        self.panel.closeButton:SetHeight(20)
        self.panel.closeButton:SetText("X")
        self.panel.closeButton:SetScript("OnClick", function() 
            panel:Hide()
        end)
        
        -- 添加报警阈值滑动组件
        -- 报警阈值文字
        self.panel.thresholdLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.thresholdLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -40)
        self.panel.thresholdLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.thresholdLabel:SetTextColor(1, 1, 1, 1)
        self.panel.thresholdLabel:SetText("报警阈值：")
        
        -- 滑动条背景
        self.panel.sliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.sliderBackground:SetPoint("LEFT", self.panel.thresholdLabel, "RIGHT", 10, 0)
        self.panel.sliderBackground:SetWidth(160)
        self.panel.sliderBackground:SetHeight(16)
        self.panel.sliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.thresholdSlider = CreateFrame("Slider", nil, self.panel, "OptionsSliderTemplate")
        self.panel.thresholdSlider:SetPoint("LEFT", self.panel.thresholdLabel, "RIGHT", 10, 0)
        self.panel.thresholdSlider:SetWidth(160)
        self.panel.thresholdSlider:SetMinMaxValues(10, 100)
        self.panel.thresholdSlider:SetValue(YGB_OTAlarmDB.threshold or 80)  -- 直接使用YGB_OTAlarmDB的值
        self.panel.thresholdSlider:SetValueStep(1)
        self.panel.thresholdSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.thresholdValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.thresholdValue:SetPoint("LEFT", self.panel.thresholdSlider, "RIGHT", 10, 0)
        self.panel.thresholdValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.thresholdValue:SetTextColor(1, 1, 1, 1)
        self.panel.thresholdValue:SetText((YGB_OTAlarmDB.threshold or 80) .. "%")  -- 直接使用YGB_OTAlarmDB的值
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.thresholdSlider:SetScript("OnValueChanged", function() 
            local value = math.floor(this:GetValue())
            panel.thresholdValue:SetText(value .. "%")
            -- 存储阈值设置到持久化数据
            YGB_OTAlarm.threshold = value
            YGB_OTAlarmDB.threshold = value
        end)
        
        -- 添加变身道具输入框

        
        -- 添加喊话内容输入框
        -- 喊话内容标签
        -- 喊话复选框
        self.panel.yellCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.yellCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -70)
        self.panel.yellCheckbox:SetWidth(20)
        self.panel.yellCheckbox:SetHeight(20)
        self.panel.yellCheckbox:SetChecked(YGB_OTAlarmDB.enableYell ~= 0)
        self.panel.yellCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            -- 保存设置
            YGB_OTAlarm.enableYell = checked
            YGB_OTAlarmDB.enableYell = checked and 1 or 0
            -- 显示提示信息
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00喊话功能" .. (checked and "已启用" or "已禁用") .. "！\124r")
        end)
        
        -- 喊话内容标签
        self.panel.yellLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.yellLabel:SetPoint("LEFT", self.panel.yellCheckbox, "RIGHT", 5, 0)
        self.panel.yellLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.yellLabel:SetTextColor(1, 1, 1, 1)
        self.panel.yellLabel:SetText("喊话内容：")
        
        -- 喊话文本输入框
        self.panel.yellEditBox = CreateFrame("EditBox", nil, self.panel)
        self.panel.yellEditBox:SetPoint("LEFT", self.panel.yellLabel, "RIGHT", 5, 0)
        self.panel.yellEditBox:SetWidth(160)
        self.panel.yellEditBox:SetHeight(25)
        self.panel.yellEditBox:SetAutoFocus(false)
        self.panel.yellEditBox:SetMaxLetters(100)
        self.panel.yellEditBox:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
        self.panel.yellEditBox:SetTextColor(1, 1, 1)
        self.panel.yellEditBox:SetTextInsets(5, 5, 5, 5)
        self.panel.yellEditBox:SetParent(self.panel)
        self.panel.yellEditBox:SetBackdrop(backdrop)
        self.panel.yellEditBox:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        self.panel.yellEditBox:SetBackdropBorderColor(1, 1, 1, 1)
        self.panel.yellEditBox:SetFrameLevel(self.panel:GetFrameLevel() + 1)
        self.panel.yellEditBox:SetScript("OnEscapePressed", function() self.panel.yellEditBox:ClearFocus() end)
        self.panel.yellEditBox:SetScript("OnEnterPressed", function() self.panel.yellEditBox:ClearFocus() end)
        self.panel.yellEditBox:SetText(YGB_OTAlarmDB.yellMessage or "")  -- 直接使用YGB_OTAlarmDB的值
        
        -- 喊话设置按钮
        self.panel.yellButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.yellButton:SetPoint("LEFT", self.panel.yellEditBox, "RIGHT", 5, 0)
        self.panel.yellButton:SetWidth(60)
        self.panel.yellButton:SetHeight(20)
        self.panel.yellButton:SetText("设置")
        self.panel.yellButton:SetScript("OnClick", function() 
            local yellMessage = this:GetParent().yellEditBox:GetText()
            if yellMessage then
                -- 保存设置到持久化数据
                YGB_OTAlarm.yellMessage = yellMessage
                YGB_OTAlarmDB.yellMessage = yellMessage
                local threshold = YGB_OTAlarm.threshold or 80
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00当仇恨阈值超过" .. threshold .. "%，则喊话：" .. (yellMessage ~= "" and yellMessage or "无") .. "！\124r")
            end
        end)
        
        -- 语音报警功能
        -- 语音报警复选框
        self.panel.soundCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.soundCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -95)
        self.panel.soundCheckbox:SetWidth(20)
        self.panel.soundCheckbox:SetHeight(20)
        self.panel.soundCheckbox:SetChecked(YGB_OTAlarmDB.enableSound ~= 0)
        self.panel.soundCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            -- 保存设置
            YGB_OTAlarm.enableSound = checked
            YGB_OTAlarmDB.enableSound = checked and 1 or 0
            -- 显示提示信息
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00语音报警" .. (checked and "已启用" or "已禁用") .. "！\124r")
        end)
        
        -- 语音报警标签
        self.panel.soundLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.soundLabel:SetPoint("LEFT", self.panel.soundCheckbox, "RIGHT", 5, 0)
        self.panel.soundLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.soundLabel:SetTextColor(1, 1, 1, 1)
        self.panel.soundLabel:SetText("语音报警：")
        
        -- 语音报警文本输入框
        self.panel.soundEditBox = CreateFrame("EditBox", nil, self.panel)
        self.panel.soundEditBox:SetPoint("LEFT", self.panel.soundLabel, "RIGHT", 5, 0)
        self.panel.soundEditBox:SetWidth(160)
        self.panel.soundEditBox:SetHeight(25)
        self.panel.soundEditBox:SetAutoFocus(false)
        self.panel.soundEditBox:SetMaxLetters(100)
        self.panel.soundEditBox:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
        self.panel.soundEditBox:SetTextColor(1, 1, 1)
        self.panel.soundEditBox:SetTextInsets(5, 5, 5, 5)
        self.panel.soundEditBox:SetParent(self.panel)
        -- 从完整路径中提取文件名（去除路径和扩展名）
        local defaultSoundFile = "超过仇恨阈值"
        if YGB_OTAlarmDB.soundFile then
            -- 提取文件名（去除路径）
            local filename = string.gsub(YGB_OTAlarmDB.soundFile, ".*\\", "")
            -- 去除扩展名
            filename = string.gsub(filename, "%.ogg$", "")
            defaultSoundFile = filename
        end
        self.panel.soundEditBox:SetText(defaultSoundFile)
        -- 修改背景纹理
        self.panel.soundEditBox:SetBackdrop(backdrop)
        self.panel.soundEditBox:SetBackdropColor(0.2, 0.2, 0.2, 0.8)
        self.panel.soundEditBox:SetBackdropBorderColor(1, 1, 1, 1)
        self.panel.soundEditBox:SetFrameLevel(self.panel:GetFrameLevel() + 1)
        self.panel.soundEditBox:SetScript("OnEscapePressed", function() self.panel.soundEditBox:ClearFocus() end)
        self.panel.soundEditBox:SetScript("OnEnterPressed", function() self.panel.soundEditBox:ClearFocus() end)
        
        -- 语音报警测试按钮
        self.panel.soundButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.soundButton:SetPoint("LEFT", self.panel.soundEditBox, "RIGHT", 5, 0)
        self.panel.soundButton:SetWidth(60)
        self.panel.soundButton:SetHeight(20)
        self.panel.soundButton:SetText("测试")
        self.panel.soundButton:SetScript("OnClick", function() 
            local soundName = this:GetParent().soundEditBox:GetText()
            if soundName then
                -- 构建完整的文件路径
                local soundFile = "Interface\\AddOns\\YGB_OTAlarm\\" .. soundName .. ".ogg"
                -- 测试播放音频
                PlaySoundFile(soundFile, "Master")
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00测试播放音频文件：" .. soundFile .. "！\124r")
            end
        end)
        
        -- 语音报警设置按钮
        self.panel.soundSetButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.soundSetButton:SetPoint("LEFT", self.panel.soundButton, "RIGHT", 5, 0)
        self.panel.soundSetButton:SetWidth(60)
        self.panel.soundSetButton:SetHeight(20)
        self.panel.soundSetButton:SetText("设置")
        self.panel.soundSetButton:SetScript("OnClick", function() 
            local soundName = this:GetParent().soundEditBox:GetText()
            if soundName then
                -- 构建完整的文件路径
                local soundFile = "Interface\\AddOns\\YGB_OTAlarm\\" .. soundName .. ".ogg"
                -- 保存设置到持久化数据
                YGB_OTAlarm.soundFile = soundFile
                YGB_OTAlarmDB.soundFile = soundFile
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00语音报警文件已设置为：" .. soundFile .. "！\124r")
            end
        end)
        
        -- 频道选择复选框（移到语音报警复选框下方）
        -- 说频道复选框
        self.panel.sayCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.sayCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -125)
        self.panel.sayCheckbox:SetWidth(20)
        self.panel.sayCheckbox:SetHeight(20)
        self.panel.sayCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.SAY or false)
        self.panel.sayCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            -- 保存设置
            YGB_OTAlarm.channelSettings.SAY = checked
            YGB_OTAlarmDB.channelSettings.SAY = checked
        end)
        
        -- 说频道标签
        self.panel.sayLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.sayLabel:SetPoint("LEFT", self.panel.sayCheckbox, "RIGHT", 5, 0)
        self.panel.sayLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.sayLabel:SetTextColor(1, 1, 1, 1)
        self.panel.sayLabel:SetText("说")
        
        -- 喊频道复选框
        self.panel.yellChannelCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.yellChannelCheckbox:SetPoint("LEFT", self.panel.sayLabel, "RIGHT", 20, 0)
        self.panel.yellChannelCheckbox:SetWidth(20)
        self.panel.yellChannelCheckbox:SetHeight(20)
        self.panel.yellChannelCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.YELL or true)
        self.panel.yellChannelCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            -- 保存设置
            YGB_OTAlarm.channelSettings.YELL = checked
            YGB_OTAlarmDB.channelSettings.YELL = checked
        end)
        
        -- 喊频道标签
        self.panel.yellChannelLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.yellChannelLabel:SetPoint("LEFT", self.panel.yellChannelCheckbox, "RIGHT", 5, 0)
        self.panel.yellChannelLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.yellChannelLabel:SetTextColor(1, 1, 1, 1)
        self.panel.yellChannelLabel:SetText("喊")
        
        -- 工会频道复选框
        self.panel.guildCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.guildCheckbox:SetPoint("LEFT", self.panel.yellChannelLabel, "RIGHT", 20, 0)
        self.panel.guildCheckbox:SetWidth(20)
        self.panel.guildCheckbox:SetHeight(20)
        self.panel.guildCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.GUILD or false)
        self.panel.guildCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            -- 保存设置
            YGB_OTAlarm.channelSettings.GUILD = checked
            YGB_OTAlarmDB.channelSettings.GUILD = checked
        end)
        
        -- 工会频道标签
        self.panel.guildLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.guildLabel:SetPoint("LEFT", self.panel.guildCheckbox, "RIGHT", 5, 0)
        self.panel.guildLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.guildLabel:SetTextColor(1, 1, 1, 1)
        self.panel.guildLabel:SetText("工会")
        
        -- 团队频道复选框
        self.panel.raidCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.raidCheckbox:SetPoint("LEFT", self.panel.guildLabel, "RIGHT", 20, 0)
        self.panel.raidCheckbox:SetWidth(20)
        self.panel.raidCheckbox:SetHeight(20)
        self.panel.raidCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.RAID or false)
        self.panel.raidCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            -- 保存设置
            YGB_OTAlarm.channelSettings.RAID = checked
            YGB_OTAlarmDB.channelSettings.RAID = checked
        end)
        
        -- 团队频道标签
        self.panel.raidLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.raidLabel:SetPoint("LEFT", self.panel.raidCheckbox, "RIGHT", 5, 0)
        self.panel.raidLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.raidLabel:SetTextColor(1, 1, 1, 1)
        self.panel.raidLabel:SetText("团队")

        -- 仇恨条复选框
        self.panel.threatBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.threatBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -155)
        self.panel.threatBarCheckbox:SetWidth(20)
        self.panel.threatBarCheckbox:SetHeight(20)
        self.panel.threatBarCheckbox:SetChecked(YGB_OTAlarmDB.showThreatBar or false)
        
        -- 仇恨条复选框标签
        self.panel.threatBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.threatBarLabel:SetPoint("LEFT", self.panel.threatBarCheckbox, "RIGHT", 5, 0)
        self.panel.threatBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.threatBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.threatBarLabel:SetText("显示仇恨条")
        
        -- 仇恨条复选框点击事件
        self.panel.threatBarCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            YGB_OTAlarm.showThreatBar = checked
            YGB_OTAlarmDB.showThreatBar = checked
            
            -- 更新仇恨条显示状态
            if YGB_OTAlarm.threatBar then
                if checked then
                    YGB_OTAlarm.threatBar:Show()
                    if YGB_OTAlarm.secondThreatBar then
                        -- 根据显示遮挡条设置决定是否显示遮挡条
                        if YGB_OTAlarm.showCoverBar then
                            YGB_OTAlarm.secondThreatBar:Show()
                        else
                            YGB_OTAlarm.secondThreatBar:Hide()
                        end
                    end
                else
                    YGB_OTAlarm.threatBar:Hide()
                    if YGB_OTAlarm.secondThreatBar then
                        YGB_OTAlarm.secondThreatBar:Hide()
                    end
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条" .. (checked and "已显示" or "已隐藏") .. "！\124r")
        end)
        
        -- 显示遮挡条复选框
        self.panel.coverBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.coverBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -180)
        self.panel.coverBarCheckbox:SetWidth(20)
        self.panel.coverBarCheckbox:SetHeight(20)
        self.panel.coverBarCheckbox:SetChecked(YGB_OTAlarmDB.showCoverBar or true)
        
        -- 显示遮挡条复选框标签
        self.panel.coverBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.coverBarLabel:SetPoint("LEFT", self.panel.coverBarCheckbox, "RIGHT", 5, 0)
        self.panel.coverBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.coverBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.coverBarLabel:SetText("显示遮挡条")
        
        -- 显示遮挡条复选框点击事件
        self.panel.coverBarCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            YGB_OTAlarm.showCoverBar = checked
            YGB_OTAlarmDB.showCoverBar = checked and 1 or 0
            
            -- 更新遮挡条显示状态
            if YGB_OTAlarm.secondThreatBar then
                if checked then
                    YGB_OTAlarm.secondThreatBar:Show()
                else
                    YGB_OTAlarm.secondThreatBar:Hide()
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00遮挡条" .. (checked and "已显示" or "已隐藏") .. "！\124r")
        end)
        
        -- 显示距离条复选框
        self.panel.distanceBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.distanceBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -205)
        self.panel.distanceBarCheckbox:SetWidth(20)
        self.panel.distanceBarCheckbox:SetHeight(20)
        self.panel.distanceBarCheckbox:SetChecked(YGB_OTAlarmDB.showDistanceBar or false)
        
        -- 显示距离条复选框标签
        self.panel.distanceBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.distanceBarLabel:SetPoint("LEFT", self.panel.distanceBarCheckbox, "RIGHT", 5, 0)
        self.panel.distanceBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.distanceBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.distanceBarLabel:SetText("显示距离条")
        
        -- 显示距离条复选框点击事件
        self.panel.distanceBarCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            YGB_OTAlarm.showDistanceBar = checked
            YGB_OTAlarmDB.showDistanceBar = checked and 1 or 0
            
            -- 更新距离条显示状态
            if YGB_OTAlarm.distanceBar then
                if checked then
                    YGB_OTAlarm.distanceBar:Show()
                else
                    YGB_OTAlarm.distanceBar:Hide()
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00距离条" .. (checked and "已显示" or "已隐藏") .. "！\124r")
        end)
        
        -- 锁定仇恨条复选框
        self.panel.lockThreatBarCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.lockThreatBarCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -230)
        self.panel.lockThreatBarCheckbox:SetWidth(20)
        self.panel.lockThreatBarCheckbox:SetHeight(20)
        self.panel.lockThreatBarCheckbox:SetChecked(YGB_OTAlarmDB.lockThreatBar or false)
        
        -- 锁定仇恨条复选框标签
        self.panel.lockThreatBarLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.lockThreatBarLabel:SetPoint("LEFT", self.panel.lockThreatBarCheckbox, "RIGHT", 5, 0)
        self.panel.lockThreatBarLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.lockThreatBarLabel:SetTextColor(1, 1, 1, 1)
        self.panel.lockThreatBarLabel:SetText("锁定仇恨条")
        
        -- 锁定仇恨条复选框点击事件
        self.panel.lockThreatBarCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            YGB_OTAlarm.lockThreatBar = checked
            YGB_OTAlarmDB.lockThreatBar = checked
            
            -- 更新仇恨条的可拖动性
            if YGB_OTAlarm.threatBar then
                if checked then
                    YGB_OTAlarm.threatBar:EnableMouse(false)
                else
                    YGB_OTAlarm.threatBar:EnableMouse(true)
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条" .. (checked and "已锁定" or "已解锁") .. "！\124r")
        end)
        
        -- 战斗显示复选框
        self.panel.combatOnlyCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.combatOnlyCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -255)
        self.panel.combatOnlyCheckbox:SetWidth(20)
        self.panel.combatOnlyCheckbox:SetHeight(20)
        self.panel.combatOnlyCheckbox:SetChecked(YGB_OTAlarmDB.combatOnly or false)
        
        -- 战斗显示复选框标签
        self.panel.combatOnlyLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.combatOnlyLabel:SetPoint("LEFT", self.panel.combatOnlyCheckbox, "RIGHT", 5, 0)
        self.panel.combatOnlyLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.combatOnlyLabel:SetTextColor(1, 1, 1, 1)
        self.panel.combatOnlyLabel:SetText("战斗显示|脱战隐藏")
        
        -- 战斗显示复选框点击事件
        self.panel.combatOnlyCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            YGB_OTAlarm.combatOnly = checked
            YGB_OTAlarmDB.combatOnly = checked
            
            -- 立即更新UI状态
            if checked then
                -- 启用战斗显示，检查当前战斗状态
                if UnitAffectingCombat("player") then
                    -- 在战斗中，显示UI
                    if YGB_OTAlarm.threatBar and YGB_OTAlarmDB.showThreatBar then
                        YGB_OTAlarm.threatBar:Show()
                        if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.showCoverBar then
                            YGB_OTAlarm.secondThreatBar:Show()
                        end
                        if YGB_OTAlarm.distanceBar and YGB_OTAlarm.showDistanceBar then
                            YGB_OTAlarm.distanceBar:Show()
                        end
                    end
                else
                    -- 不在战斗中，隐藏UI
                    if YGB_OTAlarm.threatBar then
                        YGB_OTAlarm.threatBar:Hide()
                        if YGB_OTAlarm.secondThreatBar then
                            YGB_OTAlarm.secondThreatBar:Hide()
                        end
                        if YGB_OTAlarm.distanceBar then
                            YGB_OTAlarm.distanceBar:Hide()
                        end
                    end
                end
            else
                -- 禁用战斗显示，恢复UI显示
                if YGB_OTAlarm.threatBar and YGB_OTAlarmDB.showThreatBar then
                    YGB_OTAlarm.threatBar:Show()
                    if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.showCoverBar then
                        YGB_OTAlarm.secondThreatBar:Show()
                    end
                    if YGB_OTAlarm.distanceBar and YGB_OTAlarm.showDistanceBar then
                        YGB_OTAlarm.distanceBar:Show()
                    end
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00战斗显示" .. (checked and "已启用" or "已禁用") .. "！\124r")
        end)
        
        -- 仇恨条长度滑动组件
        self.panel.barLengthLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barLengthLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -280)
        self.panel.barLengthLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barLengthLabel:SetTextColor(1, 1, 1, 1)
        self.panel.barLengthLabel:SetText("仇恨条长度：")
        
        -- 滑动条背景
        self.panel.barLengthSliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.barLengthSliderBackground:SetPoint("LEFT", self.panel.barLengthLabel, "RIGHT", 10, 0)
        self.panel.barLengthSliderBackground:SetWidth(160)
        self.panel.barLengthSliderBackground:SetHeight(16)
        self.panel.barLengthSliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.barLengthSlider = CreateFrame("Slider", nil, self.panel, "OptionsSliderTemplate")
        self.panel.barLengthSlider:SetPoint("LEFT", self.panel.barLengthLabel, "RIGHT", 10, 0)
        self.panel.barLengthSlider:SetWidth(160)
        self.panel.barLengthSlider:SetMinMaxValues(100, 500)
        self.panel.barLengthSlider:SetValue(YGB_OTAlarmDB.barLength or 200)
        self.panel.barLengthSlider:SetValueStep(1)
        self.panel.barLengthSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.barLengthValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barLengthValue:SetPoint("LEFT", self.panel.barLengthSlider, "RIGHT", 10, 0)
        self.panel.barLengthValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barLengthValue:SetTextColor(1, 1, 1, 1)
        self.panel.barLengthValue:SetText((YGB_OTAlarmDB.barLength or 200) .. "px")
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.barLengthSlider:SetScript("OnValueChanged", function() 
            local value = math.floor(this:GetValue())
            panel.barLengthValue:SetText(value .. "px")
            -- 存储设置到持久化数据
            YGB_OTAlarm.barLength = value
            YGB_OTAlarmDB.barLength = value
            -- 更新仇恨条长度
            if YGB_OTAlarm.threatBar then
                YGB_OTAlarm.threatBar:SetWidth(value)
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetWidth(value)
                end
                -- 更新阈值刻度线和文本位置
                local threshold = YGB_OTAlarm.threshold or 80
                local barWidth = value - 10 -- 减去左右边距5
                local thresholdX = (threshold / 100) * barWidth
                YGB_OTAlarm.threatBar.thresholdLine:SetPoint("LEFT", YGB_OTAlarm.threatBar, "LEFT", 5 + thresholdX, 0)
                YGB_OTAlarm.threatBar.thresholdText:SetPoint("BOTTOM", YGB_OTAlarm.threatBar.thresholdLine, "TOP", 0, 12)
            end
        end)
        
        -- 仇恨条高度滑动组件
        self.panel.barHeightLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barHeightLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -305)
        self.panel.barHeightLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barHeightLabel:SetTextColor(1, 1, 1, 1)
        self.panel.barHeightLabel:SetText("仇恨条高度：")
        
        -- 滑动条背景
        self.panel.barHeightSliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.barHeightSliderBackground:SetPoint("LEFT", self.panel.barHeightLabel, "RIGHT", 10, 0)
        self.panel.barHeightSliderBackground:SetWidth(160)
        self.panel.barHeightSliderBackground:SetHeight(16)
        self.panel.barHeightSliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.barHeightSlider = CreateFrame("Slider", nil, self.panel, "OptionsSliderTemplate")
        self.panel.barHeightSlider:SetPoint("LEFT", self.panel.barHeightLabel, "RIGHT", 10, 0)
        self.panel.barHeightSlider:SetWidth(160)
        self.panel.barHeightSlider:SetMinMaxValues(10, 50)
        self.panel.barHeightSlider:SetValue(YGB_OTAlarmDB.barHeight or 20)
        self.panel.barHeightSlider:SetValueStep(1)
        self.panel.barHeightSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.barHeightValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barHeightValue:SetPoint("LEFT", self.panel.barHeightSlider, "RIGHT", 10, 0)
        self.panel.barHeightValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barHeightValue:SetTextColor(1, 1, 1, 1)
        self.panel.barHeightValue:SetText((YGB_OTAlarmDB.barHeight or 20) .. "px")
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.barHeightSlider:SetScript("OnValueChanged", function() 
            local value = math.floor(this:GetValue())
            panel.barHeightValue:SetText(value .. "px")
            -- 存储设置到持久化数据
            YGB_OTAlarm.barHeight = value
            YGB_OTAlarmDB.barHeight = value
            -- 更新仇恨条高度
            if YGB_OTAlarm.threatBar then
                YGB_OTAlarm.threatBar:SetHeight(value)
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetHeight(value / 2)
                end
                if YGB_OTAlarm.distanceBar then
                    YGB_OTAlarm.distanceBar:SetHeight(value / 2)
                end
            end
        end)
        
        -- 仇恨条缩放滑动组件
        self.panel.barScaleLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barScaleLabel:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -330)
        self.panel.barScaleLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barScaleLabel:SetTextColor(1, 1, 1, 1)
        self.panel.barScaleLabel:SetText("仇恨条缩放：")
        
        -- 滑动条背景
        self.panel.barScaleSliderBackground = self.panel:CreateTexture(nil, "BACKGROUND")
        self.panel.barScaleSliderBackground:SetPoint("LEFT", self.panel.barScaleLabel, "RIGHT", 10, 0)
        self.panel.barScaleSliderBackground:SetWidth(160)
        self.panel.barScaleSliderBackground:SetHeight(16)
        self.panel.barScaleSliderBackground:SetTexture("Interface\\Buttons\\UI-SliderBar-Background")
        
        -- 滑动条
        self.panel.barScaleSlider = CreateFrame("Slider", nil, self.panel, "OptionsSliderTemplate")
        self.panel.barScaleSlider:SetPoint("LEFT", self.panel.barScaleLabel, "RIGHT", 10, 0)
        self.panel.barScaleSlider:SetWidth(160)
        self.panel.barScaleSlider:SetMinMaxValues(0.5, 2)
        self.panel.barScaleSlider:SetValue(YGB_OTAlarmDB.barScale or 1)
        self.panel.barScaleSlider:SetValueStep(0.1)
        self.panel.barScaleSlider:SetOrientation("HORIZONTAL")
        
        -- 滑动条值显示
        self.panel.barScaleValue = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.barScaleValue:SetPoint("LEFT", self.panel.barScaleSlider, "RIGHT", 10, 0)
        self.panel.barScaleValue:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.barScaleValue:SetTextColor(1, 1, 1, 1)
        self.panel.barScaleValue:SetText(string.format("%.1f", YGB_OTAlarmDB.barScale or 1))
        
        -- 滑动条脚本
        local panel = self.panel
        self.panel.barScaleSlider:SetScript("OnValueChanged", function() 
            local value = this:GetValue()
            -- 限制缩放值精度到小数点后2位
            local roundedValue = math.floor(value * 100) / 100
            panel.barScaleValue:SetText(string.format("%.1f", roundedValue))
            -- 存储设置到持久化数据
            YGB_OTAlarm.barScale = roundedValue
            YGB_OTAlarmDB.barScale = roundedValue
            -- 更新仇恨条缩放
            if YGB_OTAlarm.threatBar then
                YGB_OTAlarm.threatBar:SetScale(roundedValue)
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetScale(roundedValue)
                end
                if YGB_OTAlarm.distanceBar then
                    YGB_OTAlarm.distanceBar:SetScale(roundedValue)
                end
            end
        end)
        
        -- 调试模式复选框
        self.panel.debugCheckbox = CreateFrame("CheckButton", nil, self.panel, "UICheckButtonTemplate")
        self.panel.debugCheckbox:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -355)
        self.panel.debugCheckbox:SetWidth(20)
        self.panel.debugCheckbox:SetHeight(20)
        local debugModeValue = YGB_OTAlarm.debugMode
        if debugModeValue == nil then
            debugModeValue = YGB_OTAlarmDB.debugMode
        end
        -- 正确处理布尔值和数字值
        local isChecked = false
        if type(debugModeValue) == "boolean" then
            isChecked = debugModeValue
        elseif type(debugModeValue) == "number" then
            isChecked = debugModeValue ~= 0
        else
            isChecked = true -- 默认开启
        end
        self.panel.debugCheckbox:SetChecked(isChecked)
        
        -- 调试模式复选框标签
        self.panel.debugLabel = self.panel:CreateFontString(nil, "OVERLAY")
        self.panel.debugLabel:SetPoint("LEFT", self.panel.debugCheckbox, "RIGHT", 5, 0)
        self.panel.debugLabel:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        self.panel.debugLabel:SetTextColor(1, 1, 1, 1)
        self.panel.debugLabel:SetText("显示调试信息")
        
        -- 调试模式复选框点击事件
        self.panel.debugCheckbox:SetScript("OnClick", function() 
            local checked = this:GetChecked()
            YGB_OTAlarm.debugMode = checked
            YGB_OTAlarmDB.debugMode = checked and 1 or 0
            
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00调试信息" .. (checked and "已开启" or "已关闭") .. "！\124r")
        end)
        
        -- 复位仇恨条位置按钮
        self.panel.resetPositionButton = CreateFrame("Button", nil, self.panel, "UIPanelButtonTemplate")
        self.panel.resetPositionButton:SetPoint("TOPLEFT", self.panel, "TOPLEFT", 10, -380)
        self.panel.resetPositionButton:SetWidth(120)
        self.panel.resetPositionButton:SetHeight(25)
        self.panel.resetPositionButton:SetText("复位仇恨条位置")
        self.panel.resetPositionButton:SetScript("OnClick", function() 
            if YGB_OTAlarm.threatBar then
                -- 重置仇恨条位置到屏幕中间
                YGB_OTAlarm.threatBar:ClearAllPoints()
                YGB_OTAlarm.threatBar:SetPoint("TOP", UIParent, "TOP", 0, -100)
                -- 保存新的位置到持久化数据
                if not YGB_OTAlarmDB.threatBarPosition then YGB_OTAlarmDB.threatBarPosition = {} end
                YGB_OTAlarmDB.threatBarPosition.point = "TOP"
                YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
                YGB_OTAlarmDB.threatBarPosition.relativePoint = "TOP"
                YGB_OTAlarmDB.threatBarPosition.x = 0
                YGB_OTAlarmDB.threatBarPosition.y = -100
                
                -- 重置仇恨条的长度、高度、缩放为初始值
                local defaultLength = 200
                local defaultHeight = 20
                local defaultScale = 1
                
                -- 更新仇恨条
                YGB_OTAlarm.threatBar:SetWidth(defaultLength)
                YGB_OTAlarm.threatBar:SetHeight(defaultHeight)
                YGB_OTAlarm.threatBar:SetScale(defaultScale)
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetWidth(defaultLength)
                YGB_OTAlarm.secondThreatBar:SetHeight(defaultHeight / 2)
                YGB_OTAlarm.secondThreatBar:SetScale(defaultScale)
            end
            
            -- 更新距离条
            if YGB_OTAlarm.distanceBar then
                YGB_OTAlarm.distanceBar:SetWidth(defaultLength)
                YGB_OTAlarm.distanceBar:SetHeight(defaultHeight / 2 + 5)
                YGB_OTAlarm.distanceBar:SetScale(defaultScale)
            end
                
                -- 更新持久化数据
                YGB_OTAlarmDB.barLength = defaultLength
                YGB_OTAlarmDB.barHeight = defaultHeight
                YGB_OTAlarmDB.barScale = defaultScale
                YGB_OTAlarm.barLength = defaultLength
                YGB_OTAlarm.barHeight = defaultHeight
                YGB_OTAlarm.barScale = defaultScale
                
                -- 更新配置面板中的滑动组件
                if self.panel.barLengthSlider then
                    self.panel.barLengthSlider:SetValue(defaultLength)
                    self.panel.barLengthValue:SetText(defaultLength .. "px")
                end
                if self.panel.barHeightSlider then
                    self.panel.barHeightSlider:SetValue(defaultHeight)
                    self.panel.barHeightValue:SetText(defaultHeight .. "px")
                end
                if self.panel.barScaleSlider then
                    self.panel.barScaleSlider:SetValue(defaultScale)
                    self.panel.barScaleValue:SetText(string.format("%.1f", defaultScale))
                end
                
                -- 显示仇恨条（如果之前隐藏）
                if YGB_OTAlarm.showThreatBar then
                    YGB_OTAlarm.threatBar:Show()
                    if YGB_OTAlarm.secondThreatBar then
                        -- 根据显示遮挡条设置决定是否显示遮挡条
                        if YGB_OTAlarm.showCoverBar then
                            YGB_OTAlarm.secondThreatBar:Show()
                        else
                            YGB_OTAlarm.secondThreatBar:Hide()
                        end
                    end
                end
                
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条位置和大小已复位到初始状态！\124r")
            else
                DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000仇恨条尚未创建！\124r")
            end
        end)

        -- 默认隐藏
        self.panel:Hide()
    end
end

-- 命令处理函数 - 只处理显示命令
function YGB_OTAlarm_SlashCommand()
    -- 如果面板不存在，先创建
    if not YGB_OTAlarm.panel then
        YGB_OTAlarm:CreateEmptyPanel()
    end
    
    -- 显示面板
    if YGB_OTAlarm.panel then
        YGB_OTAlarm.panel:Show()
        DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00空框面板已显示\124r")
    end
end

-- 插件加载逻辑已直接内联到事件处理器中，不再需要单独的加载函数

-- 创建小地图按钮函数
function YGB_OTAlarm:CreateMinimapButton()
    -- 检查是否已经创建了小地图按钮
    if self.minimapButton then return end
    
    -- 创建小地图按钮框架
    local minimapButton = CreateFrame("Button", "YGB_OTAlarm_MinimapButton", Minimap)
    minimapButton:SetWidth(24)
    minimapButton:SetHeight(24)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetToplevel(true)
    minimapButton:SetMovable(true)
    minimapButton:EnableMouse(true)
    minimapButton:RegisterForDrag("LeftButton")
    
    -- 设置按钮纹理
    minimapButton:SetNormalTexture("Interface\\AddOns\\YGB_OTAlarm\\images\\minimap_icon")
    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    minimapButton:SetPushedTexture("Interface\\AddOns\\YGB_OTAlarm\\images\\minimap_icon")
    minimapButton:GetPushedTexture():SetDesaturated(true)
    
    -- 设置按钮位置
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 52 - (15 * cos(0)), (15 * sin(0)) - 52)
    
    -- 保存按钮引用
    self.minimapButton = minimapButton
    
    -- 实现按钮点击事件
    minimapButton:SetScript("OnClick", function() 
        -- 切换插件配置面板显示/隐藏
        if not YGB_OTAlarm.panel then
            YGB_OTAlarm:CreateEmptyPanel()
        end
        if YGB_OTAlarm.panel then
            if YGB_OTAlarm.panel:IsVisible() then
                YGB_OTAlarm.panel:Hide()
            else
                YGB_OTAlarm.panel:Show()
            end
        end
    end)
    
    -- 实现按钮拖拽功能
    minimapButton:SetScript("OnDragStart", function() 
        this:StartMoving() 
    end)
    
    minimapButton:SetScript("OnDragStop", function() 
        this:StopMovingOrSizing() 
        -- 保存按钮位置
        local x, y = this:GetLeft() - Minimap:GetLeft(), this:GetTop() - Minimap:GetTop()
        if not YGB_OTAlarmDB then YGB_OTAlarmDB = {} end
        if not YGB_OTAlarmDB.minimap then YGB_OTAlarmDB.minimap = {} end
        YGB_OTAlarmDB.minimap.x = x
        YGB_OTAlarmDB.minimap.y = y
    end)
    
    -- 实现鼠标悬停效果
    minimapButton:SetScript("OnEnter", function() 
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("YGB OT报警器")
        GameTooltip:AddLine("点击显示/隐藏设置面板", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("拖拽可移动按钮位置", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    
    minimapButton:SetScript("OnLeave", function() 
        GameTooltip:Hide()
    end)
    
    -- 尝试加载保存的按钮位置
    if YGB_OTAlarmDB and YGB_OTAlarmDB.minimap and YGB_OTAlarmDB.minimap.x and YGB_OTAlarmDB.minimap.y then
        minimapButton:ClearAllPoints()
        minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", YGB_OTAlarmDB.minimap.x, YGB_OTAlarmDB.minimap.y)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00YGB_OTAlarm: 小地图按钮已创建|r")
end

-- 直接在文件级别注册命令行 - 这种方式在WoW 1.12中更可靠
SLASH_YGBOTALARM1 = "/ygbot"
SlashCmdList["YGBOTALARM"] = YGB_OTAlarm_SlashCommand

-- 注册CHAT_MSG_ADDON事件
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:SetScript("OnEvent", function() 
    if event == "CHAT_MSG_ADDON" then
        OnChatMsgAddon(arg1, arg2, arg3, arg4)
    end
end)

-- 注册ADDON_LOADED事件，确保插件加载时初始化
local addonLoadFrame = CreateFrame("Frame")
addonLoadFrame:RegisterEvent("ADDON_LOADED")
addonLoadFrame:SetScript("OnEvent", function() 
    if event == "ADDON_LOADED" and arg1 == "YGB_OTAlarm" then
        -- 调用插件加载函数
        YGB_OTAlarm_OnLoad()
        -- 取消注册事件，只执行一次
        this:UnregisterEvent("ADDON_LOADED")
    end
end)

-- 添加一个事件监听器，在游戏完全加载后再次检查和应用持久化数据
local loadFrame = CreateFrame("Frame")
loadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loadFrame:SetScript("OnEvent", function() 
    if event == "PLAYER_ENTERING_WORLD" then
        -- 创建小地图按钮
        YGB_OTAlarm:CreateMinimapButton()
        -- 确保YGB_OTAlarmDB已初始化
        YGB_OTAlarmDB = YGB_OTAlarmDB or {
            threshold = 80,

            yellMessage = "",
            soundFile = "d:\\twmoa_1180\\Interface\\AddOns\\YGB_OTAlarm\\超过仇恨阈值.ogg",
            showThreatBar = true,
            lockThreatBar = false,
            debugMode = false,
            enableYell = false,
            enableSound = true,
            channelSettings = {
                SAY = false,
                YELL = true,
                GUILD = false,
                RAID = false
            }
        }
        
        -- 确保 YGB_OTAlarmDB.debugMode 存在
        if YGB_OTAlarmDB.debugMode == nil then
            YGB_OTAlarmDB.debugMode = 0 -- 默认关闭
        end
        
        -- 确保 YGB_OTAlarmDB.enableYell 存在
        if YGB_OTAlarmDB.enableYell == nil then
            YGB_OTAlarmDB.enableYell = 0 -- 默认关闭
        end
        -- 确保 YGB_OTAlarmDB.showCoverBar 存在
        if YGB_OTAlarmDB.showCoverBar == nil then
            YGB_OTAlarmDB.showCoverBar = 1 -- 默认开启
        end
        
        -- 确保 YGB_OTAlarmDB.channelSettings 存在
        YGB_OTAlarmDB.channelSettings = YGB_OTAlarmDB.channelSettings or {
            SAY = false,
            YELL = true,
            GUILD = false,
            RAID = false
        }
        
        -- 重新加载设置
        YGB_OTAlarm.threshold = YGB_OTAlarmDB.threshold

        YGB_OTAlarm.yellMessage = YGB_OTAlarmDB.yellMessage
        YGB_OTAlarm.soundFile = YGB_OTAlarmDB.soundFile
        -- 正确处理showThreatBar
        if YGB_OTAlarmDB.showThreatBar == nil then
            YGB_OTAlarm.showThreatBar = false
        else
            YGB_OTAlarm.showThreatBar = YGB_OTAlarmDB.showThreatBar ~= 0
        end
        -- 正确处理lockThreatBar
        if YGB_OTAlarmDB.lockThreatBar == nil then
            YGB_OTAlarm.lockThreatBar = false
        else
            YGB_OTAlarm.lockThreatBar = YGB_OTAlarmDB.lockThreatBar ~= 0
        end
        -- 正确处理debugMode
        if YGB_OTAlarmDB.debugMode == nil then
            YGB_OTAlarm.debugMode = true
        else
            YGB_OTAlarm.debugMode = YGB_OTAlarmDB.debugMode ~= 0
        end
        -- 正确处理enableYell
        if YGB_OTAlarmDB.enableYell == nil then
            YGB_OTAlarm.enableYell = true
        else
            YGB_OTAlarm.enableYell = YGB_OTAlarmDB.enableYell ~= 0
        end
        -- 正确处理enableSound
        if YGB_OTAlarmDB.enableSound == nil then
            YGB_OTAlarm.enableSound = true
        else
            YGB_OTAlarm.enableSound = YGB_OTAlarmDB.enableSound ~= 0
        end
        -- 正确处理showCoverBar
        if YGB_OTAlarmDB.showCoverBar == nil then
            YGB_OTAlarm.showCoverBar = true
        else
            YGB_OTAlarm.showCoverBar = YGB_OTAlarmDB.showCoverBar ~= 0
        end
        YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings
        
        -- 正确处理combatOnly
        if YGB_OTAlarmDB.combatOnly == nil then
            YGB_OTAlarm.combatOnly = false
        else
            -- 正确处理布尔值和数字值
            if type(YGB_OTAlarmDB.combatOnly) == "boolean" then
                YGB_OTAlarm.combatOnly = YGB_OTAlarmDB.combatOnly
            elseif type(YGB_OTAlarmDB.combatOnly) == "number" then
                YGB_OTAlarm.combatOnly = YGB_OTAlarmDB.combatOnly ~= 0
            else
                YGB_OTAlarm.combatOnly = false -- 默认关闭
            end
        end
        
        -- 根据保存的设置显示或隐藏仇恨条
        if YGB_OTAlarm.threatBar then
            if YGB_OTAlarmDB.showThreatBar then
                -- 检查战斗显示设置
                if YGB_OTAlarm.combatOnly then
                    -- 战斗显示开启，检查当前战斗状态
                    if UnitAffectingCombat("player") then
                        -- 在战斗中，显示UI
                        YGB_OTAlarm.threatBar:Show()
                        if YGB_OTAlarm.secondThreatBar then
                            -- 根据显示遮挡条设置决定是否显示遮挡条
                            if YGB_OTAlarm.showCoverBar then
                                YGB_OTAlarm.secondThreatBar:Show()
                            else
                                YGB_OTAlarm.secondThreatBar:Hide()
                            end
                        end
                        -- 根据显示距离条设置决定是否显示距离条
                        if YGB_OTAlarm.showDistanceBar and YGB_OTAlarm.distanceBar then
                            YGB_OTAlarm.distanceBar:Show()
                        end
                        DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已显示（战斗中 - 游戏加载后）\124r")
                    else
                        -- 不在战斗中，隐藏UI
                        YGB_OTAlarm.threatBar:Hide()
                        if YGB_OTAlarm.secondThreatBar then
                            YGB_OTAlarm.secondThreatBar:Hide()
                        end
                        if YGB_OTAlarm.distanceBar then
                            YGB_OTAlarm.distanceBar:Hide()
                        end
                        DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已隐藏（非战斗状态 - 游戏加载后）\124r")
                    end
                else
                    -- 战斗显示关闭，正常显示UI
                    YGB_OTAlarm.threatBar:Show()
                    if YGB_OTAlarm.secondThreatBar then
                        -- 根据显示遮挡条设置决定是否显示遮挡条
                        if YGB_OTAlarm.showCoverBar then
                            YGB_OTAlarm.secondThreatBar:Show()
                        else
                            YGB_OTAlarm.secondThreatBar:Hide()
                        end
                    end
                    -- 根据显示距离条设置决定是否显示距离条
                    if YGB_OTAlarm.showDistanceBar and YGB_OTAlarm.distanceBar then
                        YGB_OTAlarm.distanceBar:Show()
                    end
                    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已显示（根据持久化数据 - 游戏加载后）\124r")
                end
            else
                YGB_OTAlarm.threatBar:Hide()
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:Hide()
                end
                if YGB_OTAlarm.distanceBar then
                    YGB_OTAlarm.distanceBar:Hide()
                end
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已隐藏（根据持久化数据 - 游戏加载后）\124r")
            end
            
            -- 根据保存的设置锁定或解锁仇恨条
            if YGB_OTAlarmDB.lockThreatBar then
                YGB_OTAlarm.threatBar:EnableMouse(false)
            else
                YGB_OTAlarm.threatBar:EnableMouse(true)
            end
            
            -- 根据保存的设置更新仇恨条长度、高度和缩放
            local barLength = YGB_OTAlarmDB.barLength or 200
            local barHeight = YGB_OTAlarmDB.barHeight or 20
            local barScale = YGB_OTAlarmDB.barScale or 1
            -- 限制缩放值精度到小数点后2位
            barScale = math.floor(barScale * 100) / 100
            
            YGB_OTAlarm.threatBar:SetWidth(barLength)
            YGB_OTAlarm.threatBar:SetHeight(barHeight)
            YGB_OTAlarm.threatBar:SetScale(barScale)
            if YGB_OTAlarm.secondThreatBar then
                YGB_OTAlarm.secondThreatBar:SetWidth(barLength)
                YGB_OTAlarm.secondThreatBar:SetHeight(barHeight / 2)
                YGB_OTAlarm.secondThreatBar:SetScale(barScale)
            end
            
            -- 更新阈值刻度线位置
            if YGB_OTAlarm.threatBar.thresholdLine and YGB_OTAlarm.threatBar.thresholdText then
                local threshold = YGB_OTAlarm.threshold or 80
                local barWidth = barLength - 10 -- 减去左右边距5
                local thresholdX = (threshold / 100) * barWidth
                YGB_OTAlarm.threatBar.thresholdLine:SetPoint("LEFT", YGB_OTAlarm.threatBar, "LEFT", 5 + thresholdX, 0)
                YGB_OTAlarm.threatBar.thresholdText:SetPoint("BOTTOM", YGB_OTAlarm.threatBar.thresholdLine, "TOP", 0, 12)
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 游戏加载后更新仇恨条参数：长度=" .. barLength .. ", 高度=" .. barHeight .. ", 缩放=" .. barScale .. "\124r")
        end
        
        -- 取消注册事件，只执行一次
        this:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end)
-- [烟锅巴：2026-02-07 22:01:15]

-- 创建仇恨条框架
local function CreateThreatBar()
    -- 打印调试信息，确认创建仇恨条时使用的参数
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 创建仇恨条，使用的参数：长度=" .. (YGB_OTAlarmDB.barLength or 200) .. ", 高度=" .. (YGB_OTAlarmDB.barHeight or 20) .. ", 缩放=" .. (YGB_OTAlarmDB.barScale or 1) .. "\124r")
    
    local threatBarFrame = CreateFrame("Frame", "YGB_OTAlarm_ThreatBar", UIParent)
    -- 使用保存的仇恨条长度或默认值
    local barLength = YGB_OTAlarmDB.barLength or 200
    threatBarFrame:SetWidth(barLength)
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条宽度为：" .. barLength .. "\124r")
    
    -- 使用保存的仇恨条高度或默认值
    local barHeight = YGB_OTAlarmDB.barHeight or 20
    threatBarFrame:SetHeight(barHeight)
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条高度为：" .. barHeight .. "\124r")
    
    -- 使用保存的仇恨条位置或默认值
    local pos = YGB_OTAlarmDB.threatBarPosition or {
        point = "TOP",
        relativeTo = "UIParent",
        relativePoint = "TOP",
        x = 0,
        y = -100
    }
    -- 确保relativeTo是有效的
    local relativeTo = pos.relativeTo
    if not relativeTo or relativeTo == "" then
        relativeTo = "UIParent"
    end
    -- 设置仇恨条位置
    threatBarFrame:SetPoint(pos.point, relativeTo, pos.relativePoint, pos.x, pos.y)
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条位置为：" .. pos.point .. ", " .. relativeTo .. ", " .. pos.relativePoint .. ", " .. pos.x .. ", " .. pos.y .. "\124r")
    
    -- 使用保存的仇恨条缩放或默认值
    local barScale = YGB_OTAlarmDB.barScale or 1
    -- 限制缩放值精度到小数点后2位
    barScale = math.floor(barScale * 100) / 100
    threatBarFrame:SetScale(barScale)
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 设置仇恨条缩放为：" .. barScale .. "\124r")
    
    -- 设置背景
    local backdrop = {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 8, -- 减小边框粗细 [烟锅巴：2026-02-12 12:30:00]
        insets = {
            left = 2,
            right = 2,
            top = 2,
            bottom = 2
        }
    }
    threatBarFrame:SetBackdrop(backdrop)
    threatBarFrame:SetBackdropColor(0, 0, 0, 0.8)
    
    -- 使其可拖动
    threatBarFrame:SetMovable(true)
    -- 根据保存的设置决定是否启用鼠标事件
    if YGB_OTAlarmDB.lockThreatBar then
        threatBarFrame:EnableMouse(false)
    else
        threatBarFrame:EnableMouse(true)
    end
    threatBarFrame:RegisterForDrag("LeftButton")
    
    local threatBar = threatBarFrame
    threatBarFrame:SetScript("OnDragStart", function() 
        -- 只有在未锁定时才能拖动
        if not YGB_OTAlarmDB.lockThreatBar then
            threatBar:StartMoving() 
            threatBar.isMoving = true
        end
    end)
    threatBarFrame:SetScript("OnDragStop", function() 
        threatBar:StopMovingOrSizing() 
        threatBar.isMoving = false
        -- 保存仇恨条位置
        local point, relativeTo, relativePoint, x, y = threatBar:GetPoint()
        if not YGB_OTAlarmDB.threatBarPosition then YGB_OTAlarmDB.threatBarPosition = {} end
        YGB_OTAlarmDB.threatBarPosition.point = point
        -- 确保relativeTo是字符串，而不是框架对象
        if type(relativeTo) == "string" then
            YGB_OTAlarmDB.threatBarPosition.relativeTo = relativeTo
        else
            YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
        end
        YGB_OTAlarmDB.threatBarPosition.relativePoint = relativePoint
        -- 限制坐标精度，避免浮点数精度问题
        YGB_OTAlarmDB.threatBarPosition.x = math.floor(x * 100) / 100
        YGB_OTAlarmDB.threatBarPosition.y = math.floor(y * 100) / 100
    end)
    
    -- 仇恨条背景
    local barBackground = threatBarFrame:CreateTexture(nil, "BACKGROUND")
    barBackground:SetPoint("TOPLEFT", threatBarFrame, "TOPLEFT", 5, -5)
    barBackground:SetPoint("BOTTOMRIGHT", threatBarFrame, "BOTTOMRIGHT", -5, 5)
    barBackground:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    barBackground:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- 仇恨条
    local threatTexture = threatBarFrame:CreateTexture(nil, "ARTWORK")
    threatTexture:SetPoint("TOPLEFT", barBackground, "TOPLEFT")
    threatTexture:SetPoint("BOTTOMLEFT", barBackground, "BOTTOMLEFT")
    threatTexture:SetWidth(0)
    threatTexture:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    threatTexture:SetVertexColor(0, 1, 0, 1) -- 初始为绿色
    
    -- 阈值刻度线
    local thresholdLine = threatBarFrame:CreateTexture(nil, "ARTWORK")
    thresholdLine:SetPoint("TOP", barBackground, "TOP")
    thresholdLine:SetPoint("BOTTOM", barBackground, "BOTTOM")
    thresholdLine:SetWidth(2) -- 加粗刻度线
    thresholdLine:SetTexture(1, 1, 0, 1) -- 黄色
    
    -- 阈值文本
    local thresholdText = threatBarFrame:CreateFontString(nil, "OVERLAY")
    thresholdText:SetPoint("BOTTOM", thresholdLine, "TOP", 0, 12) -- 上移12像素，显示在仇恨条上方
    thresholdText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE") -- 增大字体大小
    thresholdText:SetTextColor(1, 1, 0, 1) -- 黄色文字
    thresholdText:SetText("80%")
    
    -- 仇恨值文本
    local threatText = threatBarFrame:CreateFontString(nil, "OVERLAY")
    threatText:SetPoint("CENTER", barBackground, "CENTER")
    threatText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    threatText:SetTextColor(1, 1, 1, 1)
    threatText:SetText("无目标")
    
    -- 存储引用
    threatBarFrame.barTexture = threatTexture
    threatBarFrame.barText = threatText
    threatBarFrame.thresholdLine = thresholdLine
    threatBarFrame.thresholdText = thresholdText
    
    -- 默认隐藏
    threatBarFrame:Hide()
    
    -- 在仇恨条下方创建一个一模一样的框架 [烟锅巴：2026-02-12 12:30:01]
    local secondThreatBarFrame = CreateFrame("Frame", "YGB_OTAlarm_SecondThreatBar", UIParent)
    -- 使用相同的宽度，但高度缩小一半
    secondThreatBarFrame:SetWidth(barLength)
    secondThreatBarFrame:SetHeight(barHeight / 2)
    -- 设置位置在第一个框架下方，紧挨在一起
    secondThreatBarFrame:SetPoint("TOP", threatBarFrame, "BOTTOM", 0, 0)
    secondThreatBarFrame:SetScale(barScale)
    -- 使用相同的背景
    secondThreatBarFrame:SetBackdrop(backdrop)
    secondThreatBarFrame:SetBackdropColor(0, 0, 0, 0.8)
    -- 使其可拖动（与第一个框架同步）
    secondThreatBarFrame:SetMovable(true)
    if YGB_OTAlarmDB.lockThreatBar then
        secondThreatBarFrame:EnableMouse(false)
    else
        secondThreatBarFrame:EnableMouse(true)
    end
    secondThreatBarFrame:RegisterForDrag("LeftButton")
    -- 第二个框架的拖动脚本（与第一个框架同步）
    local secondThreatBar = secondThreatBarFrame
    secondThreatBarFrame:SetScript("OnDragStart", function() 
        -- 只有在未锁定时才能拖动
        if not YGB_OTAlarmDB.lockThreatBar then
            threatBar:StartMoving() 
            secondThreatBar:StartMoving() 
            threatBar.isMoving = true
            secondThreatBar.isMoving = true
        end
    end)
    secondThreatBarFrame:SetScript("OnDragStop", function() 
        threatBar:StopMovingOrSizing() 
        secondThreatBar:StopMovingOrSizing() 
        threatBar.isMoving = false
        secondThreatBar.isMoving = false
        -- 保存仇恨条位置
        local point, relativeTo, relativePoint, x, y = threatBar:GetPoint()
        if not YGB_OTAlarmDB.threatBarPosition then YGB_OTAlarmDB.threatBarPosition = {} end
        YGB_OTAlarmDB.threatBarPosition.point = point
        -- 确保relativeTo是字符串，而不是框架对象
        if type(relativeTo) == "string" then
            YGB_OTAlarmDB.threatBarPosition.relativeTo = relativeTo
        else
            YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
        end
        YGB_OTAlarmDB.threatBarPosition.relativePoint = relativePoint
        -- 限制坐标精度，避免浮点数精度问题
        YGB_OTAlarmDB.threatBarPosition.x = math.floor(x * 100) / 100
        YGB_OTAlarmDB.threatBarPosition.y = math.floor(y * 100) / 100
        -- 第二个框架的位置会自动跟随第一个框架
    end)
    
    -- 第二个框架的背景（简化，只保留基本背景）
    local secondBarBackground = secondThreatBarFrame:CreateTexture(nil, "BACKGROUND")
    secondBarBackground:SetPoint("TOPLEFT", secondThreatBarFrame, "TOPLEFT", 5, -5)
    secondBarBackground:SetPoint("BOTTOMRIGHT", secondThreatBarFrame, "BOTTOMRIGHT", -5, 5)
    secondBarBackground:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    secondBarBackground:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- 第二个框架的中心文本
    local secondCenterText = secondThreatBarFrame:CreateFontString(nil, "OVERLAY")
    secondCenterText:SetPoint("CENTER", secondBarBackground, "CENTER")
    secondCenterText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    secondCenterText:SetTextColor(1, 1, 1, 1)
    secondCenterText:SetText("")
    
    -- 存储第二个框架的引用
    secondThreatBarFrame.barBackground = secondBarBackground
    secondThreatBarFrame.centerText = secondCenterText
    
    -- 在遮挡条下方创建一个距离框架 [烟锅巴：2026-02-13 10:00:00]
    local distanceBarFrame = CreateFrame("Frame", "YGB_OTAlarm_DistanceBar", UIParent)
    -- 使用相同的宽度，高度增加5像素
    local distanceBarWidth = barLength
    distanceBarFrame:SetWidth(distanceBarWidth)
    distanceBarFrame:SetHeight(barHeight / 2 + 5)
    -- 设置位置在遮挡条下方，紧挨在一起
    distanceBarFrame:SetPoint("TOP", secondThreatBarFrame, "BOTTOM", 0, 0)
    distanceBarFrame:SetScale(barScale)
    -- 使用相同的背景
    distanceBarFrame:SetBackdrop(backdrop)
    distanceBarFrame:SetBackdropColor(0, 0, 0, 0.8)
    -- 使其可拖动（与第一个框架同步）
    distanceBarFrame:SetMovable(true)
    if YGB_OTAlarmDB.lockThreatBar then
        distanceBarFrame:EnableMouse(false)
    else
        distanceBarFrame:EnableMouse(true)
    end
    distanceBarFrame:RegisterForDrag("LeftButton")
    -- 距离框架的拖动脚本（与第一个框架同步）
    local distanceBar = distanceBarFrame
    distanceBarFrame:SetScript("OnDragStart", function() 
        -- 只有在未锁定时才能拖动
        if not YGB_OTAlarmDB.lockThreatBar then
            threatBar:StartMoving() 
            secondThreatBar:StartMoving() 
            distanceBar:StartMoving() 
            threatBar.isMoving = true
            secondThreatBar.isMoving = true
            distanceBar.isMoving = true
        end
    end)
    distanceBarFrame:SetScript("OnDragStop", function() 
        threatBar:StopMovingOrSizing() 
        secondThreatBar:StopMovingOrSizing() 
        distanceBar:StopMovingOrSizing() 
        threatBar.isMoving = false
        secondThreatBar.isMoving = false
        distanceBar.isMoving = false
        -- 保存仇恨条位置
        local point, relativeTo, relativePoint, x, y = threatBar:GetPoint()
        if not YGB_OTAlarmDB.threatBarPosition then YGB_OTAlarmDB.threatBarPosition = {} end
        YGB_OTAlarmDB.threatBarPosition.point = point
        -- 确保relativeTo是字符串，而不是框架对象
        if type(relativeTo) == "string" then
            YGB_OTAlarmDB.threatBarPosition.relativeTo = relativeTo
        else
            YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
        end
        YGB_OTAlarmDB.threatBarPosition.relativePoint = relativePoint
        -- 限制坐标精度，避免浮点数精度问题
        YGB_OTAlarmDB.threatBarPosition.x = math.floor(x * 100) / 100
        YGB_OTAlarmDB.threatBarPosition.y = math.floor(y * 100) / 100
    end)
    
    -- 距离框架的背景（简化，只保留基本背景）
    local distanceBarBackground = distanceBarFrame:CreateTexture(nil, "BACKGROUND")
    distanceBarBackground:SetPoint("TOPLEFT", distanceBarFrame, "TOPLEFT", 5, -5)
    distanceBarBackground:SetPoint("BOTTOMRIGHT", distanceBarFrame, "BOTTOMRIGHT", -5, 5)
    distanceBarBackground:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    distanceBarBackground:SetVertexColor(0.1, 0.1, 0.1, 0.8)
    
    -- 距离填充条
    local distanceFillBar = distanceBarFrame:CreateTexture(nil, "ARTWORK")
    distanceFillBar:SetPoint("TOPLEFT", distanceBarFrame, "TOPLEFT", 5, -5)
    distanceFillBar:SetPoint("BOTTOMLEFT", distanceBarFrame, "BOTTOMLEFT", 5, 5)
    distanceFillBar:SetWidth(0)
    distanceFillBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    distanceFillBar:SetVertexColor(0, 0.8, 0, 0.8)
    
    -- 添加刻度
    local maxDistance = 45
    local scalePositions = {
        {0, "0", {1, 1, 1}},
        {8, "绿色", {0, 0.8, 0}},
        {30, "黄色", {0.8, 0.8, 0}},
        {35, "橙色", {0.8, 0.4, 0}},
        {41, "紫色", {0.8, 0, 0.8}},
        {45, "45", {1, 0, 0}}
    }
    
    distanceBarFrame.scales = {}
    for _, scaleInfo in ipairs(scalePositions) do
        local distance = scaleInfo[1]
        local label = scaleInfo[2]
        local color = scaleInfo[3]
        
        -- 计算刻度位置
        local scaleX = 5 + (distance / maxDistance) * (barLength - 10)
        
        -- 创建刻度线
        local scaleLine = distanceBarFrame:CreateTexture(nil, "OVERLAY")
        scaleLine:SetPoint("TOP", distanceBarFrame, "TOP", scaleX - (barLength / 2), -5)
        scaleLine:SetPoint("BOTTOM", distanceBarFrame, "BOTTOM", scaleX - (barLength / 2), 5)
        scaleLine:SetWidth(1)
        scaleLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
        scaleLine:SetVertexColor(unpack(color))
        
        -- 创建刻度标签
        local scaleText = distanceBarFrame:CreateFontString(nil, "OVERLAY")
        scaleText:SetPoint("TOP", distanceBarFrame, "BOTTOM", scaleX - (barLength / 2), 0)
        scaleText:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
        scaleText:SetTextColor(unpack(color))
        scaleText:SetText(distance)
        
        table.insert(distanceBarFrame.scales, {line = scaleLine, text = scaleText})
    end
    
    -- 距离框架的中心文本（显示在距离条下方）
    local distanceCenterText = distanceBarFrame:CreateFontString(nil, "OVERLAY")
    distanceCenterText:SetPoint("TOP", distanceBarFrame, "BOTTOM", 0, -5)
    distanceCenterText:SetFont("Fonts\\ARIALN.TTF", 12, "OUTLINE")
    distanceCenterText:SetTextColor(1, 1, 1, 1)
    distanceCenterText:SetText("")
    
    -- 距离框架的第二个文本标签（用于显示猎人的人宠距离，显示在距离条下方）
    local distanceCenterText2 = distanceBarFrame:CreateFontString(nil, "OVERLAY")
    distanceCenterText2:SetPoint("TOP", distanceCenterText, "BOTTOM", 0, -2)
    distanceCenterText2:SetFont("Fonts\\ARIALN.TTF", 10, "OUTLINE")
    distanceCenterText2:SetTextColor(1, 1, 1, 1)
    distanceCenterText2:SetText("")
    
    -- 存储距离框架的引用
    distanceBarFrame.barBackground = distanceBarBackground
    distanceBarFrame.fillBar = distanceFillBar
    distanceBarFrame.centerText = distanceCenterText
    distanceBarFrame.centerText2 = distanceCenterText2
    distanceBarFrame.maxDistance = maxDistance
    
    -- 存储距离框架的全局引用
    YGB_OTAlarm.distanceBar = distanceBarFrame
    
    -- 默认隐藏距离框架
    distanceBarFrame:Hide()
    
    -- 视野检测相关变量
    local LOS_CHECK_INTERVAL = 0.3       -- 视野检测间隔（秒）[烟锅巴：2026-02-12 12:30:02]
    local losCheckTimer = 0               -- 视野检测计时器
    
    -- 距离检测相关变量
    local DISTANCE_CHECK_INTERVAL = 0.1   -- 距离检测间隔（秒）[烟锅巴：2026-02-13 10:00:01]
    local distanceCheckTimer = 0          -- 距离检测计时器
    
    -- 创建视野检测函数
    local function CheckLOS()
        if not UnitExists("target") then
            -- 没有目标，清空第二个框架
            if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.secondThreatBar.barBackground and YGB_OTAlarm.secondThreatBar.centerText then
                YGB_OTAlarm.secondThreatBar.barBackground:SetVertexColor(0.1, 0.1, 0.1, 0.8)
                YGB_OTAlarm.secondThreatBar.centerText:SetText("")
            end
            return
        end
        
        -- 检查视野
        local hasLOS = UnitXP("inSight", "player", "target", "chains")
        
        -- 更新第二个框架的颜色和文字
        if YGB_OTAlarm.secondThreatBar and YGB_OTAlarm.secondThreatBar.barBackground and YGB_OTAlarm.secondThreatBar.centerText then
            if hasLOS then
                -- 视野未遮挡，显示绿色和"未遮挡"
                YGB_OTAlarm.secondThreatBar.barBackground:SetVertexColor(0, 0.8, 0, 0.8)
                YGB_OTAlarm.secondThreatBar.centerText:SetText("未遮挡")
            else
                -- 视野被遮挡，显示红色和"被遮挡"
                YGB_OTAlarm.secondThreatBar.barBackground:SetVertexColor(0.8, 0, 0, 0.8)
                YGB_OTAlarm.secondThreatBar.centerText:SetText("被遮挡")
            end
        end
    end
    
    -- 创建距离检测函数 [烟锅巴：2026-02-13 10:00:02]
    local function CheckDistance()
        local unit = "player"
        local text = ""
        local r, g, b = 0.1, 0.1, 0.1
        local distance = 0
        local maxDistance = 45
        
        if not UnitExists("target") or UnitIsUnit(unit, "target") then
            text = ""
        else
            if (UnitHealth("target") or 0) == 0 and YGB_OTAlarmDB.showDeadDistance == false then
                text = ""
            else
                distance = UnitXP("distanceBetween", unit, "target")
                
                if not distance then
                    text = ""
                else
                    if distance == 0 then
                        text = "0"
                    else
                        local fDistance = string.format("%.1f", distance)
                        text = fDistance
                    end
                    
                    -- 根据距离设置颜色
                    if distance < 8 then
                        r, g, b = 0, 0.8, 0 -- 绿色
                    elseif distance < 30 then
                        r, g, b = 0.8, 0.8, 0 -- 黄色
                    elseif distance < 35 then
                        r, g, b = 0.8, 0.4, 0 -- 橙色
                    elseif distance < 41 then
                        r, g, b = 0.8, 0, 0.8 -- 紫色
                    else
                        r, g, b = 0.8, 0, 0 -- 红色
                    end
                end
            end
        end
        
        -- 更新距离框架的颜色、文字和填充条
        if YGB_OTAlarm.distanceBar then
            -- 更新填充条长度
            if YGB_OTAlarm.distanceBar.fillBar then
                local barLength = YGB_OTAlarm.distanceBar:GetWidth() - 10
                -- 确保distance不为nil
                local safeDistance = distance or 0
                -- 当距离为0时，填充条宽度也应该为0
                local fillWidth = 0
                local displayR, displayG, displayB = r, g, b
                if safeDistance > 0 then
                    fillWidth = math.min((safeDistance / maxDistance) * barLength, barLength)
                else
                    -- 当距离为0时，使用默认颜色（灰色）
                    displayR, displayG, displayB = 0.1, 0.1, 0.1
                end
                YGB_OTAlarm.distanceBar.fillBar:SetWidth(fillWidth)
                YGB_OTAlarm.distanceBar.fillBar:SetVertexColor(displayR, displayG, displayB, 0.8)
            end
            
            -- 更新文本
            if YGB_OTAlarm.distanceBar.centerText then
                YGB_OTAlarm.distanceBar.centerText:SetText(text)
            end
        end
        
        -- 确保距离条显示
        if YGB_OTAlarm.showDistanceBar and YGB_OTAlarm.distanceBar then
            YGB_OTAlarm.distanceBar:Show()
        end
        
        -- 确保距离条宽度与仇恨条一致
        if YGB_OTAlarm.distanceBar and YGB_OTAlarm.threatBar then
            local threatBarWidth = YGB_OTAlarm.threatBar:GetWidth()
            local threatBarScale = YGB_OTAlarm.threatBar:GetScale()
            
            -- 确保宽度一致
            if YGB_OTAlarm.distanceBar:GetWidth() ~= threatBarWidth then
                YGB_OTAlarm.distanceBar:SetWidth(threatBarWidth)
                -- 同时更新遮挡条宽度，确保三者一致
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetWidth(threatBarWidth)
                end
            end
            
            -- 确保缩放比例一致
            if YGB_OTAlarm.distanceBar:GetScale() ~= threatBarScale then
                YGB_OTAlarm.distanceBar:SetScale(threatBarScale)
                -- 同时更新遮挡条缩放，确保三者一致
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:SetScale(threatBarScale)
                end
            end
        end
        
        -- 猎人的人宠距离显示
        local unitClass = UnitClass("player")
        if (unitClass == "猎人" or string.lower(unitClass) == "hunter") and YGB_OTAlarm.distanceBar and YGB_OTAlarm.distanceBar.centerText2 then
            if UnitExists("pet") and (YGB_OTAlarmDB.pp == 2 or (unit == "pet" and YGB_OTAlarmDB.pp == 3)) then
                if not (unit == "pet" and UnitIsUnit("target", "player")) and not (unit == "player" and UnitIsUnit("target", "pet")) then
                    local ppDistance = string.format("%.1f", UnitXP("distanceBetween", "player", "pet"))
                    if ppDistance and ppDistance ~= "" then
                        YGB_OTAlarm.distanceBar.centerText2:SetText(ppDistance)
                        local defaultColor = YGB_OTAlarmDB.fontColorPp or {0, 1, 0}
                        YGB_OTAlarm.distanceBar.centerText2:SetTextColor(unpack(defaultColor))
                    else
                        YGB_OTAlarm.distanceBar.centerText2:SetText("")
                    end
                else
                    YGB_OTAlarm.distanceBar.centerText2:SetText("")
                end
            else
                YGB_OTAlarm.distanceBar.centerText2:SetText("")
            end
        end
    end
    
    -- 添加视野检测和距离检测到主更新函数
    local originalOnUpdate = threatBarFrame:GetScript("OnUpdate")
    if originalOnUpdate then
        threatBarFrame:SetScript("OnUpdate", function()
            originalOnUpdate()
            
            -- 视野检测
            losCheckTimer = losCheckTimer + arg1
            if losCheckTimer >= LOS_CHECK_INTERVAL then
                losCheckTimer = 0
                CheckLOS()
            end
            
            -- 距离检测
            distanceCheckTimer = distanceCheckTimer + arg1
            if distanceCheckTimer >= DISTANCE_CHECK_INTERVAL then
                distanceCheckTimer = 0
                CheckDistance()
            end
        end)
    else
        -- 如果没有现有的OnUpdate脚本，创建一个新的
        threatBarFrame:SetScript("OnUpdate", function()
            -- 视野检测
            losCheckTimer = losCheckTimer + arg1
            if losCheckTimer >= LOS_CHECK_INTERVAL then
                losCheckTimer = 0
                CheckLOS()
            end
            
            -- 距离检测
            distanceCheckTimer = distanceCheckTimer + arg1
            if distanceCheckTimer >= DISTANCE_CHECK_INTERVAL then
                distanceCheckTimer = 0
                CheckDistance()
            end
        end)
    end
    
    -- 默认隐藏第二个框架
    secondThreatBarFrame:Hide()
    
    -- 存储第二个框架的引用到YGB_OTAlarm表中
    YGB_OTAlarm.secondThreatBar = secondThreatBarFrame
    
    -- 根据设置决定是否显示距离条
    if YGB_OTAlarm.showDistanceBar then
        YGB_OTAlarm.distanceBar:Show()
    else
        YGB_OTAlarm.distanceBar:Hide()
    end
    
    return threatBarFrame
end

-- 创建一个简单的初始化框架，直接调用函数而依赖事件
function YGB_OTAlarm_OnLoad()
    -- 打印加载消息
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00YGB_OTAlarm 已加载。输入 /ygbot 显示空框面板。\124r")
    
    -- 确保YGB_OTAlarmDB已初始化
    YGB_OTAlarmDB = YGB_OTAlarmDB or {
        threshold = 80,

        yellMessage = "",
        showThreatBar = true,
        debugMode = false,
        enableYell = false,
        channelSettings = {
            SAY = false,
            YELL = true,
            GUILD = false,
            RAID = false
        },
        -- 仇恨条相关设置
        barLength = 200,
        barHeight = 20,
        barScale = 1,
        -- 仇恨条位置
        threatBarPosition = {
            point = "TOP",
            relativeTo = "UIParent",
            relativePoint = "TOP",
            x = 0,
            y = -100
        }
    }
    
    -- 确保 YGB_OTAlarmDB.debugMode 存在
    if YGB_OTAlarmDB.debugMode == nil then
        YGB_OTAlarmDB.debugMode = 1 -- 默认开启
    end
    
    -- 确保 YGB_OTAlarmDB.enableYell 存在
    if YGB_OTAlarmDB.enableYell == nil then
        YGB_OTAlarmDB.enableYell = 1 -- 默认开启
    end
    
    -- 确保 YGB_OTAlarmDB.channelSettings 存在
    YGB_OTAlarmDB.channelSettings = YGB_OTAlarmDB.channelSettings or {
        SAY = false,
        YELL = true,
        GUILD = false,
        RAID = false
    }
    
    -- 确保仇恨条相关设置存在
    YGB_OTAlarmDB.barLength = YGB_OTAlarmDB.barLength or 200
    YGB_OTAlarmDB.barHeight = YGB_OTAlarmDB.barHeight or 20
    YGB_OTAlarmDB.barScale = YGB_OTAlarmDB.barScale or 1
    -- 限制缩放值精度到小数点后2位
    YGB_OTAlarmDB.barScale = math.floor(YGB_OTAlarmDB.barScale * 100) / 100
    YGB_OTAlarmDB.threatBarPosition = YGB_OTAlarmDB.threatBarPosition or {
        point = "TOP",
        relativeTo = "UIParent",
        relativePoint = "TOP",
        x = 0,
        y = -100
    }
    -- 确保仇恨条位置数据的正确性
    if YGB_OTAlarmDB.threatBarPosition then
        -- 确保relativeTo是字符串
        if YGB_OTAlarmDB.threatBarPosition.relativeTo and type(YGB_OTAlarmDB.threatBarPosition.relativeTo) ~= "string" then
            YGB_OTAlarmDB.threatBarPosition.relativeTo = "UIParent"
        end
        -- 限制坐标精度
        if YGB_OTAlarmDB.threatBarPosition.x then
            YGB_OTAlarmDB.threatBarPosition.x = math.floor(YGB_OTAlarmDB.threatBarPosition.x * 100) / 100
        end
        if YGB_OTAlarmDB.threatBarPosition.y then
            YGB_OTAlarmDB.threatBarPosition.y = math.floor(YGB_OTAlarmDB.threatBarPosition.y * 100) / 100
        end
    end
    
    -- 加载保存的设置
    YGB_OTAlarm.threshold = YGB_OTAlarmDB.threshold
    YGB_OTAlarm.yellMessage = YGB_OTAlarmDB.yellMessage
    YGB_OTAlarm.barLength = YGB_OTAlarmDB.barLength
    YGB_OTAlarm.barHeight = YGB_OTAlarmDB.barHeight
    YGB_OTAlarm.barScale = YGB_OTAlarmDB.barScale
    
    -- 打印调试信息，确认加载的设置
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 加载的仇恨条设置：长度=" .. YGB_OTAlarmDB.barLength .. ", 高度=" .. YGB_OTAlarmDB.barHeight .. ", 缩放=" .. YGB_OTAlarmDB.barScale .. "\124r")
    DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 加载的仇恨条位置：" .. YGB_OTAlarmDB.threatBarPosition.point .. ", " .. (YGB_OTAlarmDB.threatBarPosition.relativeTo or "UIParent") .. ", " .. YGB_OTAlarmDB.threatBarPosition.relativePoint .. ", " .. YGB_OTAlarmDB.threatBarPosition.x .. ", " .. YGB_OTAlarmDB.threatBarPosition.y .. "\124r")
    
    -- 初始化仇恨条（只在不存在时创建）
    if not YGB_OTAlarm.threatBar then
        YGB_OTAlarm.threatBar = CreateThreatBar()
    end
    -- 正确处理showThreatBar
    if YGB_OTAlarmDB.showThreatBar == nil then
        YGB_OTAlarm.showThreatBar = false
    else
        YGB_OTAlarm.showThreatBar = YGB_OTAlarmDB.showThreatBar ~= 0
    end
    -- 正确处理debugMode
    if YGB_OTAlarmDB.debugMode == nil then
        YGB_OTAlarm.debugMode = true
    else
        YGB_OTAlarm.debugMode = YGB_OTAlarmDB.debugMode ~= 0
    end
    -- 正确处理enableYell
    if YGB_OTAlarmDB.enableYell == nil then
        YGB_OTAlarm.enableYell = true
    else
        YGB_OTAlarm.enableYell = YGB_OTAlarmDB.enableYell ~= 0
    end
    -- 正确处理showDistanceBar
    if YGB_OTAlarmDB.showDistanceBar == nil then
        YGB_OTAlarm.showDistanceBar = false
    else
        YGB_OTAlarm.showDistanceBar = YGB_OTAlarmDB.showDistanceBar ~= 0
    end
    -- 正确处理combatOnly
    if YGB_OTAlarmDB.combatOnly == nil then
        YGB_OTAlarm.combatOnly = false
    else
        -- 正确处理布尔值和数字值
        if type(YGB_OTAlarmDB.combatOnly) == "boolean" then
            YGB_OTAlarm.combatOnly = YGB_OTAlarmDB.combatOnly
        elseif type(YGB_OTAlarmDB.combatOnly) == "number" then
            YGB_OTAlarm.combatOnly = YGB_OTAlarmDB.combatOnly ~= 0
        else
            YGB_OTAlarm.combatOnly = false -- 默认关闭
        end
    end
    YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings
    
    -- 根据保存的设置显示或隐藏仇恨条
    if YGB_OTAlarmDB.showThreatBar then
        -- 检查战斗显示设置
        if YGB_OTAlarm.combatOnly then
            -- 战斗显示开启，检查当前战斗状态
            if UnitAffectingCombat("player") then
                -- 在战斗中，显示UI
                YGB_OTAlarm.threatBar:Show()
                if YGB_OTAlarm.secondThreatBar then
                    -- 根据显示遮挡条设置决定是否显示遮挡条
                    if YGB_OTAlarm.showCoverBar then
                        YGB_OTAlarm.secondThreatBar:Show()
                    else
                        YGB_OTAlarm.secondThreatBar:Hide()
                    end
                end
                -- 根据显示距离条设置决定是否显示距离条
                if YGB_OTAlarm.showDistanceBar and YGB_OTAlarm.distanceBar then
                    YGB_OTAlarm.distanceBar:Show()
                end
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已显示（战斗中）\124r")
            else
                -- 不在战斗中，隐藏UI
                YGB_OTAlarm.threatBar:Hide()
                if YGB_OTAlarm.secondThreatBar then
                    YGB_OTAlarm.secondThreatBar:Hide()
                end
                if YGB_OTAlarm.distanceBar then
                    YGB_OTAlarm.distanceBar:Hide()
                end
                DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已隐藏（非战斗状态）\124r")
            end
        else
            -- 战斗显示关闭，正常显示UI
            YGB_OTAlarm.threatBar:Show()
            if YGB_OTAlarm.secondThreatBar then
                -- 根据显示遮挡条设置决定是否显示遮挡条
                if YGB_OTAlarm.showCoverBar then
                    YGB_OTAlarm.secondThreatBar:Show()
                else
                    YGB_OTAlarm.secondThreatBar:Hide()
                end
            end
            -- 根据显示距离条设置决定是否显示距离条
            if YGB_OTAlarm.showDistanceBar and YGB_OTAlarm.distanceBar then
                YGB_OTAlarm.distanceBar:Show()
            end
            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已显示（根据持久化数据）\124r")
        end
        -- 确保距离条和遮挡条宽度与仇恨条一致
        if YGB_OTAlarm.distanceBar and YGB_OTAlarm.threatBar then
            local threatBarWidth = YGB_OTAlarm.threatBar:GetWidth()
            local threatBarScale = YGB_OTAlarm.threatBar:GetScale()
            
            -- 确保宽度一致
            YGB_OTAlarm.distanceBar:SetWidth(threatBarWidth)
            if YGB_OTAlarm.secondThreatBar then
                YGB_OTAlarm.secondThreatBar:SetWidth(threatBarWidth)
            end
            
            -- 确保缩放比例一致
            YGB_OTAlarm.distanceBar:SetScale(threatBarScale)
            if YGB_OTAlarm.secondThreatBar then
                YGB_OTAlarm.secondThreatBar:SetScale(threatBarScale)
            end
        end
    else
        YGB_OTAlarm.threatBar:Hide()
        if YGB_OTAlarm.secondThreatBar then
            YGB_OTAlarm.secondThreatBar:Hide()
        end
        if YGB_OTAlarm.distanceBar then
            YGB_OTAlarm.distanceBar:Hide()
        end
        DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00仇恨条已隐藏（根据持久化数据）\124r")
    end
    
    -- 额外检查距离条的显示状态
    if YGB_OTAlarmDB.showThreatBar and YGB_OTAlarm.showDistanceBar and YGB_OTAlarm.distanceBar then
        -- 考虑战斗显示设置
        if YGB_OTAlarm.combatOnly then
            -- 战斗显示开启，只在战斗中显示
            if UnitAffectingCombat("player") then
                YGB_OTAlarm.distanceBar:Show()
            else
                YGB_OTAlarm.distanceBar:Hide()
            end
        else
            -- 战斗显示关闭，正常显示
            YGB_OTAlarm.distanceBar:Show()
        end
    end
    
    -- 同步已存在面板的控件状态
    if YGB_OTAlarm.panel then
        -- 同步报警阈值滑动条
        if YGB_OTAlarm.panel.thresholdSlider then
            YGB_OTAlarm.panel.thresholdSlider:SetValue(YGB_OTAlarmDB.threshold or 80)
            if YGB_OTAlarm.panel.thresholdValue then
                YGB_OTAlarm.panel.thresholdValue:SetText((YGB_OTAlarmDB.threshold or 80) .. "%")
            end
        end
        

        
        -- 同步喊话内容输入框
        if YGB_OTAlarm.panel.yellEditBox then
            YGB_OTAlarm.panel.yellEditBox:SetText(YGB_OTAlarmDB.yellMessage or "")
        end
        
        -- 同步喊话复选框
        if YGB_OTAlarm.panel.yellCheckbox then
            YGB_OTAlarm.panel.yellCheckbox:SetChecked(YGB_OTAlarmDB.enableYell ~= 0)
        end
        
        -- 同步频道复选框
        if YGB_OTAlarm.panel.sayCheckbox then
            YGB_OTAlarm.panel.sayCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.SAY or false)
        end
        if YGB_OTAlarm.panel.yellChannelCheckbox then
            YGB_OTAlarm.panel.yellChannelCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.YELL or true)
        end
        if YGB_OTAlarm.panel.guildCheckbox then
            YGB_OTAlarm.panel.guildCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.GUILD or false)
        end
        if YGB_OTAlarm.panel.raidCheckbox then
            YGB_OTAlarm.panel.raidCheckbox:SetChecked(YGB_OTAlarmDB.channelSettings and YGB_OTAlarmDB.channelSettings.RAID or false)
        end
        
        -- 同步仇恨条复选框
        if YGB_OTAlarm.panel.threatBarCheckbox then
            local showThreatBarValue = YGB_OTAlarmDB.showThreatBar
            YGB_OTAlarm.panel.threatBarCheckbox:SetChecked(showThreatBarValue and showThreatBarValue ~= 0 or false)
        end
        
        -- 同步调试模式复选框（重点修复）
        if YGB_OTAlarm.panel.debugCheckbox then
            local debugModeValue = YGB_OTAlarmDB.debugMode
            -- 正确处理布尔值和数字值
            local isChecked = false
            if type(debugModeValue) == "boolean" then
                isChecked = debugModeValue
            elseif type(debugModeValue) == "number" then
                isChecked = debugModeValue ~= 0
            else
                isChecked = true -- 默认开启
            end
            YGB_OTAlarm.panel.debugCheckbox:SetChecked(isChecked)
        end
        
        -- 同步显示遮挡条复选框
        if YGB_OTAlarm.panel.coverBarCheckbox then
            local coverBarValue = YGB_OTAlarmDB.showCoverBar
            -- 正确处理布尔值和数字值
            local isChecked = false
            if type(coverBarValue) == "boolean" then
                isChecked = coverBarValue
            elseif type(coverBarValue) == "number" then
                isChecked = coverBarValue ~= 0
            else
                isChecked = true -- 默认开启
            end
            YGB_OTAlarm.panel.coverBarCheckbox:SetChecked(isChecked)
        end
        
        -- 同步显示距离条复选框
        if YGB_OTAlarm.panel.distanceBarCheckbox then
            local distanceBarValue = YGB_OTAlarmDB.showDistanceBar
            -- 正确处理布尔值和数字值
            local isChecked = false
            if type(distanceBarValue) == "boolean" then
                isChecked = distanceBarValue
            elseif type(distanceBarValue) == "number" then
                isChecked = distanceBarValue ~= 0
            else
                isChecked = false -- 默认关闭
            end
            YGB_OTAlarm.panel.distanceBarCheckbox:SetChecked(isChecked)
        end
        
        -- 同步战斗显示复选框
        if YGB_OTAlarm.panel.combatOnlyCheckbox then
            local combatOnlyValue = YGB_OTAlarmDB.combatOnly
            -- 正确处理布尔值和数字值
            local isChecked = false
            if type(combatOnlyValue) == "boolean" then
                isChecked = combatOnlyValue
            elseif type(combatOnlyValue) == "number" then
                isChecked = combatOnlyValue ~= 0
            else
                isChecked = false -- 默认关闭
            end
            YGB_OTAlarm.panel.combatOnlyCheckbox:SetChecked(isChecked)
        end
        
        -- 同步仇恨条相关滑动组件
        if YGB_OTAlarm.panel.barLengthSlider then
            YGB_OTAlarm.panel.barLengthSlider:SetValue(YGB_OTAlarmDB.barLength or 200)
            if YGB_OTAlarm.panel.barLengthValue then
                YGB_OTAlarm.panel.barLengthValue:SetText((YGB_OTAlarmDB.barLength or 200) .. "px")
            end
        end
        if YGB_OTAlarm.panel.barHeightSlider then
            YGB_OTAlarm.panel.barHeightSlider:SetValue(YGB_OTAlarmDB.barHeight or 20)
            if YGB_OTAlarm.panel.barHeightValue then
                YGB_OTAlarm.panel.barHeightValue:SetText((YGB_OTAlarmDB.barHeight or 20) .. "px")
            end
        end
        if YGB_OTAlarm.panel.barScaleSlider then
            YGB_OTAlarm.panel.barScaleSlider:SetValue(YGB_OTAlarmDB.barScale or 1)
            if YGB_OTAlarm.panel.barScaleValue then
                YGB_OTAlarm.panel.barScaleValue:SetText(string.format("%.1f", YGB_OTAlarmDB.barScale or 1))
            end
        end
    end
end
-- [烟锅巴：2026-02-07 22:01:30]

-- 自动施法逻辑
-- 创建定时器
local function CreateThreatChecker()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTER_COMBAT")
    frame:RegisterEvent("PLAYER_LEAVE_COMBAT")
    
    local lastCheck = 0
    local lastDebug = 0
    local inCombat = false
    
    frame:SetScript("OnEvent", function() 
        if event == "PLAYER_ENTER_COMBAT" then
            inCombat = true
        elseif event == "PLAYER_LEAVE_COMBAT" then
            inCombat = false
            -- 战斗结束，清除已喊话和已语音报警目标记录
            YGB_OTAlarm.yelledTargets = {}
            YGB_OTAlarm.soundedTargets = {}
            YGB_OTAlarm.currentTarget = nil
        end
    end)
    
    frame:SetScript("OnUpdate", function() 
        local currentTime = GetTime()
        if currentTime - lastCheck >= 0.3 then -- 每0.3秒检查一次 [烟锅巴：2026-02-12 12:00:01]
            lastCheck = currentTime
            
            if inCombat and YGB_OTAlarm.threshold then
                -- 检查目标是否存在
                if UnitExists("target") then
                    local target_name = UnitName("target")
                    
                    -- 计算表大小的辅助函数
                    local function table_size(t)
                        local count = 0
                        for _ in pairs(t) do
                            count = count + 1
                        end
                        return count
                    end
                    
                    -- 直接处理TWT仇恨数据，不依赖GUID
                    if TWT and TWT.threats then
                        -- 初始化ShaguPlates和threatData表
                        if not ShaguPlates then ShaguPlates = {} end
                        if not ShaguPlates.threatData then ShaguPlates.threatData = {} end
                        
                        -- 检查目标是否更换
                        if YGB_OTAlarm.currentTarget ~= target_name then
                            -- 目标更换，重置喊话状态
                            YGB_OTAlarm.currentTarget = target_name
                            -- 注意：不重置yelledTargets，因为可能会重新面对同一个目标
                        end
                        
                        -- 使用目标名称作为键，确保能够找到仇恨数据
                        local targetKey = target_name
                        ShaguPlates.threatData[targetKey] = ShaguPlates.threatData[targetKey] or {}
                        
                        -- 从TWT.threats获取玩家仇恨数据
                        local player_name = UnitName("player")
                        local my_threat_perc = nil
                        
                        for k, v in pairs(TWT.threats) do
                            if k == player_name then
                                if type(v) == "table" and v.perc then
                                    my_threat_perc = v.perc
                                elseif type(v) == "number" then
                                    my_threat_perc = tostring(v)
                                end
                            end
                        end
                        
                        -- 存储玩家仇恨数据
                        if my_threat_perc then
                            local int_my_threat = math.floor(tonumber(my_threat_perc))
                            ShaguPlates.threatData[targetKey].int_my_threat = int_my_threat
                        end
                        
                        -- 获取仇恨数据
                        local threatData = ShaguPlates.threatData[targetKey]
                        
                        if threatData and threatData.int_my_threat then
                            -- 检查自己的仇恨是否超过阈值
                            if threatData.int_my_threat >= YGB_OTAlarm.threshold then
                                -- 确保YGB_OTAlarmDB已初始化
                                YGB_OTAlarmDB = YGB_OTAlarmDB or {
                                    threshold = 80,

                                    yellMessage = "",
                                    debugMode = true,
                                    enableYell = true,
                                    channelSettings = {
                                        SAY = false,
                                        YELL = true,
                                        GUILD = false,
                                        RAID = false
                                    }
                                }
                                
                                -- 确保YGB_OTAlarm表已更新
                                YGB_OTAlarm.threshold = YGB_OTAlarmDB.threshold

                                YGB_OTAlarm.yellMessage = YGB_OTAlarmDB.yellMessage
                                YGB_OTAlarm.debugMode = YGB_OTAlarmDB.debugMode ~= 0
                                YGB_OTAlarm.enableYell = YGB_OTAlarmDB.enableYell ~= 0
                                YGB_OTAlarm.channelSettings = YGB_OTAlarmDB.channelSettings
                                
                                -- 检查是否可以施法
                                local canCast = true
                                
                                -- 注意：变身法术不需要在战斗中施放，所以跳过战斗状态检查
                                
                                -- 检查是否在施法中（兼容WoW 1.12）
                                if (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player")) then
                                    canCast = false
                                end
                                
                                if canCast then
                                    -- 直接使用CastSpellByName施放法术，更加可靠

                                    
                                    -- 喊话功能：检查该目标是否已经喊话过
                                    local yellMessage = YGB_OTAlarm.yellMessage or YGB_OTAlarmDB.yellMessage
                                    local enableYell = false
                                    if YGB_OTAlarm.enableYell ~= false then
                                        enableYell = true
                                    elseif YGB_OTAlarmDB.enableYell ~= 0 then
                                        enableYell = true
                                    end
                                    local channelSettings = YGB_OTAlarm.channelSettings or YGB_OTAlarmDB.channelSettings
                                    if enableYell and yellMessage and yellMessage ~= "" then
                                        if not YGB_OTAlarm.yelledTargets[targetKey] then
                                            -- 遍历所有频道，在启用的频道中喊话
                                            for channel, enabled in pairs(channelSettings) do
                                                if enabled then
                                                    -- 尝试喊话
                                                    SendChatMessage(yellMessage, channel)
                                                    if YGB_OTAlarm.debugMode then
                                                        DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000仇恨过高！已在" .. channel .. "频道喊话：" .. yellMessage .. "\124r")
                                                    end
                                                end
                                            end
                                            -- 标记该目标已喊话
                                            YGB_OTAlarm.yelledTargets[targetKey] = true
                                        end
                                    end
                                    
                                    -- 语音报警功能：检查是否启用了语音报警
                                    local soundFile = YGB_OTAlarm.soundFile or YGB_OTAlarmDB.soundFile
                                    local enableSound = false
                                    if YGB_OTAlarm.enableSound ~= false then
                                        enableSound = true
                                    elseif YGB_OTAlarmDB.enableSound ~= 0 then
                                        enableSound = true
                                    end
                                    if enableSound and soundFile and soundFile ~= "" then
                                        -- 检查该目标是否已经语音报警过
                                        if not YGB_OTAlarm.soundedTargets[targetKey] then
                                            -- 确保使用正确的路径格式
                                            local correctedSoundFile = soundFile
                                            -- 如果路径包含本地绝对路径格式，转换为WoW可用的格式
                                            if string.find(correctedSoundFile, "^[a-zA-Z]:\\") then
                                                correctedSoundFile = string.gsub(correctedSoundFile, "^[a-zA-Z]:\\twmoa_1180\\", "")
                                                correctedSoundFile = string.gsub(correctedSoundFile, "\\", "\\\\")
                                            end
                                            -- 播放音频文件
                                            PlaySoundFile(correctedSoundFile, "Master")
                                            if YGB_OTAlarm.debugMode then
                                                DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000仇恨过高！已播放报警音频：" .. correctedSoundFile .. "\124r")
                                            end
                                            -- 标记该目标已语音报警
                                            YGB_OTAlarm.soundedTargets[targetKey] = true
                                        end
                                    end
                                else
                                    if YGB_OTAlarm.debugMode then
                                        DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000施法条件不满足！\124r")
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        -- 每2秒通报一次仇恨调试信息
        if currentTime - lastDebug >= 2 then
            lastDebug = currentTime
            
            if UnitExists("target") then
                local targetName = UnitName("target")
                
                -- 计算表大小的辅助函数
                local function table_size(t)
                    local count = 0
                    for _ in pairs(t) do
                        count = count + 1
                    end
                    return count
                end
                
                -- 直接处理TWT仇恨数据，不依赖GUID
                if TWT and TWT.threats then
                    -- 初始化ShaguPlates和threatData表
                    if not ShaguPlates then ShaguPlates = {} end
                    if not ShaguPlates.threatData then ShaguPlates.threatData = {} end
                    
                    -- 使用目标名称作为键，确保能够找到仇恨数据
                    local targetKey = targetName
                    ShaguPlates.threatData[targetKey] = ShaguPlates.threatData[targetKey] or {}
                    
                    -- 从TWT.threats获取玩家仇恨数据和第二仇恨数据
                    local player_name = UnitName("player")
                    local my_threat_perc = nil
                    local second_threat_name = "无"
                    local second_threat_perc = 0
                    
                    -- 存储所有仇恨数据
                    local all_threats = {}
                    
                    for k, v in pairs(TWT.threats) do
                        local threat_value = 0
                        if type(v) == "table" and v.perc then
                            threat_value = tonumber(v.perc)
                        elseif type(v) == "number" then
                            threat_value = v
                        end
                        
                        if threat_value > 0 then
                            table.insert(all_threats, {name = k, perc = threat_value})
                        end
                    end
                    
                    -- 排序仇恨数据
                    table.sort(all_threats, function(a, b) return a.perc > b.perc end)
                    
                    -- 找到玩家的仇恨和第二仇恨
                    local player_found = false
                    for i, threat in ipairs(all_threats) do
                        if threat.name == player_name then
                            my_threat_perc = tostring(threat.perc)
                            player_found = true
                        end
                    end
                    
                    -- 找到第二仇恨
                    local valid_threats = {}
                    for i, threat in ipairs(all_threats) do
                        if threat.name ~= "-Pull Aggro at-" then
                            table.insert(valid_threats, threat)
                        end
                    end
                    
                    if table.getn(valid_threats) >= 2 then
                        if valid_threats[1].name == player_name then
                            -- 如果玩家是第一仇恨，那么第二仇恨就是第二个
                            second_threat_name = valid_threats[2].name
                            second_threat_perc = valid_threats[2].perc
                        else
                            -- 如果玩家不是第一仇恨，那么第二仇恨就是第一个
                            second_threat_name = valid_threats[1].name
                            second_threat_perc = valid_threats[1].perc
                        end
                    elseif table.getn(valid_threats) == 1 then
                        -- 如果只有一个仇恨目标，且不是玩家自己
                        if valid_threats[1].name ~= player_name then
                            second_threat_name = valid_threats[1].name
                            second_threat_perc = valid_threats[1].perc
                        end
                    end
                    
                    -- 存储玩家仇恨数据和第二仇恨数据
                    if my_threat_perc then
                        local int_my_threat = math.floor(tonumber(my_threat_perc))
                        ShaguPlates.threatData[targetKey].int_my_threat = int_my_threat
                    end
                    
                    -- 存储第二仇恨数据
                    ShaguPlates.threatData[targetKey].second_threat_name = second_threat_name
                    ShaguPlates.threatData[targetKey].int_second_threat = math.floor(second_threat_perc)
                    
                    -- 获取仇恨数据
                    local threatData = ShaguPlates.threatData[targetKey]
                    
                    -- 打印调试信息，了解ShaguPlates.threatData的结构
                    if YGB_OTAlarm.debugMode then
                        DEFAULT_CHAT_FRAME:AddMessage("[调试] 调试信息部分 - targetName = " .. (targetName or "nil"))
                        if ShaguPlates.threatData then
                            local threatDataSize = table_size(ShaguPlates.threatData)
                            DEFAULT_CHAT_FRAME:AddMessage("[调试] 调试信息部分 - ShaguPlates.threatData 存在，包含 " .. threatDataSize .. " 个条目")
                            for k, v in pairs(ShaguPlates.threatData) do
                                if type(v) == "table" then
                                    DEFAULT_CHAT_FRAME:AddMessage("[调试] 调试信息部分 - ShaguPlates.threatData[" .. k .. "].int_my_threat = " .. (v.int_my_threat or "nil"))
                                end
                            end
                        else
                            DEFAULT_CHAT_FRAME:AddMessage("[调试] 调试信息部分 - ShaguPlates.threatData 不存在")
                        end
                    end
                    
                    if threatData then
                        local myThreat = threatData.int_my_threat or 0
                        local secondThreat = threatData.int_second_threat or 0
                        local secondThreatName = threatData.second_threat_name or "无"
                        local threshold = YGB_OTAlarm.threshold or 80
                        
                        -- 如果没有第二仇恨数据，尝试从TWT直接获取
                        if not secondThreat or secondThreat == 0 then
                            local player_name = UnitName("player")
                            if TWT and TWT.threats then
                                -- 查找100%仇恨目标
                                local top_threat_name = nil
                                local top_threat_perc = 0
                                for k, v in pairs(TWT.threats) do
                                    if v.perc and tonumber(v.perc) > top_threat_perc and k ~= "-Pull Aggro at-" then
                                        top_threat_perc = tonumber(v.perc)
                                        top_threat_name = k
                                    end
                                end
                                
                                -- 如果自己是最高仇恨，查找第二仇恨
                                if top_threat_name == player_name then
                                    local sorted_threats = {}
                                    for k, v in pairs(TWT.threats or {}) do
                                        if k ~= player_name and v.perc and k ~= "-Pull Aggro at-" then
                                            table.insert(sorted_threats, {name = k, perc = tonumber(v.perc)})
                                        end
                                    end
                                    
                                    -- 按仇恨值排序
                                    table.sort(sorted_threats, function(a, b) return a.perc > b.perc end)
                                    
                                    if next(sorted_threats) then
                                        secondThreatName = sorted_threats[1].name
                                        secondThreat = sorted_threats[1].perc
                                        -- 更新ShaguPlates.threatData
                                        ShaguPlates.threatData[targetKey].int_second_threat = math.floor(secondThreat)
                                        ShaguPlates.threatData[targetKey].second_threat_name = secondThreatName
                                    end
                                end
                            end
                        end
                        
                        if YGB_OTAlarm.debugMode then
                            DEFAULT_CHAT_FRAME:AddMessage("\124cFF00FF00[调试] 目标：" .. targetName .. "，我的仇恨：" .. myThreat .. "%，第二仇恨：" .. secondThreatName .. "(" .. secondThreat .. "%)，阈值：" .. threshold .. "%\124r")
                        end
                        
                        -- 更新仇恨条显示
                        if YGB_OTAlarm.threatBar and YGB_OTAlarm.showThreatBar then
                            local barWidth = 0
                            local r, g, b = 0, 1, 0 -- 初始为绿色
                            local alpha = 0
                            local displayText = ""
                            
                            -- 获取玩家名称
                            local playerName = UnitName("player")
                            
                            -- 检查玩家是否是最高仇恨目标
                            local isHighestThreat = false
                            if myThreat == 100 or (secondThreat > 0 and myThreat > secondThreat) then
                                isHighestThreat = true
                            end
                            
                            if isHighestThreat then
                                -- 玩家是最高仇恨目标，显示第二仇恨信息
                                if secondThreat > 0 and secondThreatName and secondThreatName ~= "无" then
                                    barWidth = (secondThreat / 100) * 280 -- 280是仇恨条的最大宽度
                                    alpha = 1
                                    
                                    -- 第二仇恨条颜色根据百分比数值动态变化（绿色到黄色到红色）
                                    if secondThreat < 50 then
                                        r = secondThreat / 50
                                        g = 1
                                    else
                                        r = 1
                                        g = 1 - (secondThreat - 50) / 50
                                    end
                                    b = 0
                                    
                                    -- 显示第二仇恨目标名字及其仇恨值百分比数值
                                    displayText = secondThreatName .. " - " .. secondThreat .. "%"
                                else
                                    -- 没有第二仇恨数据
                                    barWidth = 0
                                    alpha = 0
                                    displayText = targetName .. " - 无第二仇恨"
                                end
                            else
                                -- 玩家不是最高仇恨目标，显示自己的仇恨信息
                                if myThreat > 0 then
                                    barWidth = (myThreat / 100) * 280 -- 280是仇恨条的最大宽度
                                    alpha = 1
                                    
                                    -- 根据仇恨值改变颜色（绿色到黄色到红色）
                                    if myThreat < 50 then
                                        r = myThreat / 50
                                        g = 1
                                    else
                                        r = 1
                                        g = 1 - (myThreat - 50) / 50
                                    end
                                end
                                
                                -- 显示当前怪物的名字和自己的仇恨百分比数值
                                displayText = targetName .. " - " .. myThreat .. "%"
                            end
                            
                            -- 更新仇恨条
                            YGB_OTAlarm.threatBar.barTexture:SetWidth(barWidth)
                            YGB_OTAlarm.threatBar.barTexture:SetVertexColor(r, g, 0, alpha)
                            YGB_OTAlarm.threatBar.barText:SetText(displayText)
                            
                            -- 更新阈值刻度线位置
                            local threshold = YGB_OTAlarm.threshold or 80
                            local barWidth = (YGB_OTAlarm.threatBar:GetWidth() or 300) - 20 -- 减去左右边距10
                            local thresholdX = (threshold / 100) * barWidth
                            YGB_OTAlarm.threatBar.thresholdLine:SetPoint("LEFT", YGB_OTAlarm.threatBar, "LEFT", 10 + thresholdX, 0)
                            YGB_OTAlarm.threatBar.thresholdText:SetText(threshold .. "%")
                        end
                    else
                        if YGB_OTAlarm.debugMode then
                            DEFAULT_CHAT_FRAME:AddMessage("\124cFFFF0000[调试] 目标：" .. targetName .. "，未找到仇恨数据\124r")
                        end
                        
                        -- 更新仇恨条显示（无仇恨数据）
                        if YGB_OTAlarm.threatBar and YGB_OTAlarm.showThreatBar then
                            YGB_OTAlarm.threatBar.barTexture:SetWidth(0)
                            YGB_OTAlarm.threatBar.barTexture:SetVertexColor(0, 1, 0, 0) -- 设置为透明
                            YGB_OTAlarm.threatBar.barText:SetText(targetName .. " - 无仇恨数据")
                            
                            -- 更新阈值刻度线位置
                            local threshold = YGB_OTAlarm.threshold or 80
                            local barWidth = (YGB_OTAlarm.threatBar and YGB_OTAlarm.threatBar:GetWidth() or 300) - 20 -- 减去左右边距10
                            local thresholdX = (threshold / 100) * barWidth
                            YGB_OTAlarm.threatBar.thresholdLine:SetPoint("LEFT", YGB_OTAlarm.threatBar, "LEFT", 10 + thresholdX, 0)
                            YGB_OTAlarm.threatBar.thresholdText:SetText(threshold .. "%")
                        end
                    end
                end
            else
                -- 无目标时更新仇恨条
                if YGB_OTAlarm.threatBar and YGB_OTAlarm.showThreatBar then
                    YGB_OTAlarm.threatBar.barTexture:SetWidth(0)
                    YGB_OTAlarm.threatBar.barTexture:SetVertexColor(0, 1, 0, 0) -- 设置为透明
                    YGB_OTAlarm.threatBar.barText:SetText("无目标")
                    
                    -- 更新阈值刻度线位置
                    local threshold = YGB_OTAlarm.threshold or 80
                    local barWidth = (YGB_OTAlarm.threatBar and YGB_OTAlarm.threatBar:GetWidth() or 300) - 20 -- 减去左右边距10
                    local thresholdX = (threshold / 100) * barWidth
                    YGB_OTAlarm.threatBar.thresholdLine:SetPoint("LEFT", YGB_OTAlarm.threatBar, "LEFT", 10 + thresholdX, 0)
                    YGB_OTAlarm.threatBar.thresholdText:SetText(threshold .. "%")
                end
            end
        end
    end)
    
    return frame
end

-- 初始化自动施法检查器
YGB_OTAlarm.threatChecker = CreateThreatChecker()

-- 立即执行初始化函数
YGB_OTAlarm_OnLoad()