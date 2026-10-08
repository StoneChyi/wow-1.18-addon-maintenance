-- 时间
local diminfo_Time = CreateFrame("Button", "diminfo_Time", UIParent)
local Text = diminfo_Time:CreateFontString(nil, "OVERLAY")
Text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
Text:SetPoint("RIGHT", diminfo_Friend, "LEFT", -20, 0)
diminfo_Time:SetAllPoints(Text)

-- 获取当前角色配置
local function GetCharacterConfig()
    local charKey = GetRealmName() .. "-" .. UnitName("player")
    
    if not DimInfo_Config then
        DimInfo_Config = {}
    end
    
    if not DimInfo_Config[charKey] then
        DimInfo_Config[charKey] = {
            x = 0,
            spacing = 20,
            Hidden = {},
            OrderLeft = { "diminfo_Performance", "diminfo_RaidCD", "diminfo_Quest", "diminfo_Friend", "diminfo_Time" },
            OrderRight = { "diminfo_Loaddll", "diminfo_Durability", "diminfo_Bag", "diminfo_Gold" },
            ShowSeconds = false
        }
    end
    
    return DimInfo_Config[charKey]
end

-- 用于控制更新频率的变量
local updateThrottle = 0

-- 更新时间显示的函数
local function UpdateTimeDisplay()
    -- 每秒更新一次
    if updateThrottle > GetTime() then return end
    updateThrottle = GetTime() + 1
    
    local config = GetCharacterConfig()
    local secondsenabled = config.ShowSeconds
    
    if secondsenabled then
        Text:SetText(date("%H:%M:%S"))
    else
        Text:SetText(date("%H:%M"))
    end
end

--时间转换
local OnlineTime = function()
    local sessiontime = GetTime() - starttime
    if sessiontime < 60 then
        return format("%.0f", sessiontime).."s"
    elseif (sessiontime >= 60 and sessiontime < 3600) then
        return format("%.0f", sessiontime/60).."m"
    elseif (sessiontime >= 3600) then
        return math.floor(format("%.1f", sessiontime/3600)).."h"..format("%.0f", (sessiontime - math.floor(sessiontime/3600)*3600)/60).."m"
    end
end

-- 鼠标提示：显示具体时间信息
diminfo_Time:SetScript("OnEnter", function()
    local Weekday = {[0] = "日","一","二","三","四","五","六"}
    local h, m = GetGameTime()
    local config = GetCharacterConfig()
    local secondsenabled = config.ShowSeconds
    
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("时间")
    GameTooltip:AddLine("左键:计时器", .3, 1, .6)
    GameTooltip:AddLine("右键:战斗计时", .3, 1, .6)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine((date("%Y年%m月%d日".." 星期"..Weekday[tonumber(date("%w"))])))
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine('|cffffffff在线时长|r', OnlineTime())
    
    if secondsenabled then
        GameTooltip:AddDoubleLine('|cffffffff本地时间|r', date("%H:%M:%S"))
    else
        GameTooltip:AddDoubleLine('|cffffffff本地时间|r', date("%H:%M"))
    end
    
    GameTooltip:AddDoubleLine('|cffffffff服务器时间|r', format("%02d:%02d", h, m))
    GameTooltip:Show()
end)

diminfo_Time:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- 创建OnUpdate框架来更新时间显示
local timeUpdateFrame = CreateFrame("Frame")
timeUpdateFrame:SetScript("OnUpdate", UpdateTimeDisplay)

-- 暴露给全局的更新函数，供设置界面调用
function DimInfo_Time_UpdateDisplay()
    -- 强制立即更新一次
    updateThrottle = 0
    UpdateTimeDisplay()
end

--来自于Modui的秒表计时器
local x, y = 0, 0
local visible = false
local t0
local saved_time = 0
local MAX_TIMER_SEC = 99*3600 + 59*60 + 59   -- 最大可显示 99:59:59
local orig = {}
local pad = function(n) return strlen(n) == 2 and n or '0'..n end

local d_stopwatch = CreateFrame('Frame', 'd_stopwatch', UIParent)
d_stopwatch:EnableMouse(true) d_stopwatch:SetMovable(true)
d_stopwatch:SetWidth(140) d_stopwatch:SetHeight(28)
d_stopwatch:RegisterForDrag'LeftButton'
d_stopwatch:SetPoint('TOP', Text, x, y - 20)
d_stopwatch:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 14, edgeSize = 14,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
})
d_stopwatch:SetBackdropColor(0, 0, 0, .8)
d_stopwatch:Hide()

local t = d_stopwatch:CreateFontString(nil, 'OVERLAY')
t:SetFontObject'GameFontNormalLarge'
t:SetPoint('LEFT', 6, 0)

local reset = CreateFrame('Button', 'd_stopwatch_reset', d_stopwatch, 'UIPanelButtonTemplate')
reset:SetWidth(35) reset:SetHeight(20)
reset:SetPoint('RIGHT', -6, 0)
reset:SetText'重置'

local play = CreateFrame('Button', 'd_stopwatch_playpause', d_stopwatch, 'UIPanelButtonTemplate')
play:SetWidth(35) play:SetHeight(20)
play:SetPoint('RIGHT', reset, 'LEFT', -2, 0)
play:SetText'开始'

local sw_stop = function()
    if not play.playing then return end
    play.playing = false
    play:SetText'开始'
    if t0 then saved_time = floor(saved_time + GetTime() - t0) end
    t0 = nil
    d_stopwatch:SetScript('OnUpdate', nil)
end

local sw_reset = function()
    d_stopwatch:SetScript('OnUpdate', nil)
    play.reverse, t0 = nil
    sw_stop()
    d_stopwatch:SetWidth(140)
    t:SetText'0:0:0'
    saved_time = 0
end

local sw_OnUpdate = function()
    local time = GetTime()
    local h, m, s
    if time - 0 > 1 then
        if play.reverse then
            s = (play.timer + t0) - time
            if  s <= 0 then s = 0 sw_reset() end
        else s = (t0 and floor(time - t0) or 0) + saved_time end
        -- 限制最大时间
        if s > MAX_TIMER_SEC then
            s = MAX_TIMER_SEC
        end
        h = floor(s/3600)
        s = s - h*3600
        m = floor(s/60)
        s = s - m*60
        t:SetText(string.format('%d:%d:%d', pad(h), pad(m), pad(s)))
    end
end

local sw_start = function()
    if play.playing then return end
    play.playing = true
    play:SetText'暂停'
    t0 = GetTime()
    d_stopwatch:SetScript('OnUpdate', sw_OnUpdate)
end

local sw_show = function(bu)
    if visible then
        d_stopwatch:Hide()
        visible = false
    else
        d_stopwatch:Show()
        t:SetText'0:0:0'
        visible = true
    end
end

local sw_countdown = function(h, m, s)
    local text
    local sec = 0
    if h then sec = h*3600 end
    if m then sec = sec + m*60 end
    if s then sec = sec + s end

    if sec > MAX_TIMER_SEC then
        play.timer = MAX_TIMER_SEC
        t0 = GetTime()
    elseif sec < 0 then
        play.timer = 0
        t0 = nil
    else
        play.timer = sec
        t0 = GetTime()
    end
    play.reverse = sec > 0
    play.playing = true
    play:SetText'暂停'
    d_stopwatch:SetScript('OnUpdate', sw_OnUpdate)
    d_stopwatch:Show()
    visible = true
end

local sw_toggle = function()
    if this.playing then
        sw_stop()
        PlaySound'igMainMenuOptionCheckBoxOff'
    else
        sw_start()
        PlaySound'igMainMenuOptionCheckBoxOn'
    end
end

d_stopwatch:SetScript('OnDragStart', function() d_stopwatch:StartMoving() end)
d_stopwatch:SetScript('OnDragStop',  function() d_stopwatch:StopMovingOrSizing() end)

play:SetScript('OnClick', sw_toggle)
reset:SetScript('OnClick', sw_reset)

diminfo_Time:RegisterEvent("PLAYER_ENTERING_WORLD")
diminfo_Time:SetScript("OnEvent", function() 
    if event == "PLAYER_ENTERING_WORLD" then 
        starttime = GetTime() 
        -- 初始化时间显示
        DimInfo_Time_UpdateDisplay()
    end 
end)

---------------------------------------------------------------------------
-- 战斗计时器（带BOSS死亡时间预估）
---------------------------------------------------------------------------
local d_combattimer = CreateFrame('Frame', 'd_combattimer', UIParent)
d_combattimer:EnableMouse(true)
d_combattimer:SetMovable(true)
d_combattimer:SetWidth(140)
d_combattimer:SetHeight(50)  -- 增高以容纳两行文字
d_combattimer:RegisterForDrag'LeftButton'
d_combattimer:SetPoint('TOP', Text, x, y - 50)
d_combattimer:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
})
d_combattimer:SetBackdropColor(0, 0, 0, .8)
d_combattimer:Hide()

local ct = d_combattimer:CreateFontString(nil, 'OVERLAY')
ct:SetFontObject'GameFontNormalLarge'
-- 改为左对齐，并锚定到框架的左上角，留出左边距 15
ct:SetJustifyH("LEFT")
ct:SetPoint('TOPLEFT', d_combattimer, 'TOPLEFT', 15, -5)
ct:SetText'战斗: 00:00:00'

-- 新增：预计死亡时间显示（字体改为与战斗计时一致）
local ct_estimate = d_combattimer:CreateFontString(nil, 'OVERLAY')
ct_estimate:SetFontObject'GameFontNormalLarge'
-- 同样左对齐，并锚定到 ct 的左下角，垂直间隔 2
ct_estimate:SetJustifyH("LEFT")
ct_estimate:SetPoint('TOPLEFT', ct, 'BOTTOMLEFT', 0, -2)
ct_estimate:SetText('')

-- 战斗状态变量
local combat_starttime = 0
local combat_totaltime = 0
local combat_inprogress = false

-- 预估相关变量
local est_health0, est_time0, est_mhealth, est_mtime, est_text
local est_targetMaxHealth = nil

local function Estimate_Reset()
    est_health0 = nil
    est_time0 = nil
    est_mhealth = nil
    est_mtime = nil
    est_targetMaxHealth = nil
    ct_estimate:SetText('')
end

local function Estimate_Update()
    if not combat_inprogress then
        ct_estimate:SetText('')
        return
    end

    local unit = "target"
    if UnitIsFriend('player', unit) then
        Estimate_Reset()
        ct_estimate:SetText('')
        return
    end

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    if maxHealth < 100000 or UnitIsDead(unit) or not UnitExists(unit) then
        Estimate_Reset()
        ct_estimate:SetText('')
        return
    end

    local time = GetTime()
    if not est_health0 then
        est_health0 = health
        est_time0 = time
        est_mhealth = health
        est_mtime = time
        est_targetMaxHealth = maxHealth
        return
    end

    -- 平滑处理
    est_mhealth = (est_mhealth + health) * 0.5
    est_mtime = (est_mtime + time) * 0.5

    if est_mhealth >= est_health0 then
        Estimate_Reset()
        ct_estimate:SetText('')
    else
        -- 计算剩余秒数
        local remaining = health * (est_time0 - est_mtime) / (est_mhealth - est_health0)
        remaining = math.max(0, math.floor(remaining))
        -- 限制最大时间
        if remaining > MAX_TIMER_SEC then
            remaining = MAX_TIMER_SEC
        end
        
        -- 转换为小时、分钟、秒
        local h = math.floor(remaining / 3600)
        local m = math.floor((remaining - h * 3600) / 60)
        local s = remaining - h * 3600 - m * 60
        
        -- 格式化显示（补零为两位）
        local h_str = pad(tostring(h))
        local m_str = pad(tostring(m))
        local s_str = pad(tostring(s))
        
        -- 拼接显示文本，剩余时间<=40秒时红色警示
        local text
        if remaining < 41 then
             text = format("|cffff1100死亡: %s:%s:%s|r", h_str, m_str, s_str)
        else
             text = format("死亡: %s:%s:%s", h_str, m_str, s_str)
        end
        ct_estimate:SetText(text)
    end
end

local function CombatTimer_Reset()
    combat_starttime = 0
    combat_totaltime = 0
    ct:SetText("战斗: 00:00:00")
end

local function CombatTimer_Update()
    if combat_inprogress then
        local current = GetTime()
        local elapsed = current - combat_starttime
        -- 限制最大时间
        if elapsed > MAX_TIMER_SEC then
            elapsed = MAX_TIMER_SEC
        end
        
        local h = floor(elapsed/3600)
        local m = floor((elapsed - h*3600)/60)
        local s = floor(elapsed - h*3600 - m*60)
        
        ct:SetText(string.format("战斗: %s:%s:%s", pad(h), pad(m), pad(s)))
    end
end

local function CombatTimer_Start()
    combat_inprogress = true
    combat_starttime = GetTime()
    combat_totaltime = 0
    d_combattimer:SetScript("OnUpdate", CombatTimer_Update)
    Estimate_Reset()  -- 重置估计，准备新战斗
    -- 完全手动控制显示，不自动弹出
    -- d_combattimer:Show()   -- 注释掉，不自动显示
end

local function CombatTimer_Stop()
    combat_inprogress = false
    d_combattimer:SetScript("OnUpdate", nil)
    -- 保留战斗时长文本，不清零（用户可手动查看上一次战斗时长）
    -- CombatTimer_Reset()   -- 移除重置，保留最后显示的时间
    Estimate_Reset()  -- 估算重置
    -- 不自动隐藏
end

d_combattimer:SetScript('OnDragStart', function() d_combattimer:StartMoving() end)
d_combattimer:SetScript('OnDragStop', function() d_combattimer:StopMovingOrSizing() end)

-- 注册战斗事件和目标相关事件
d_combattimer:RegisterEvent("PLAYER_REGEN_DISABLED")
d_combattimer:RegisterEvent("PLAYER_REGEN_ENABLED")
d_combattimer:RegisterEvent("PLAYER_TARGET_CHANGED")
d_combattimer:RegisterEvent("UNIT_HEALTH")

d_combattimer:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_DISABLED" then
        CombatTimer_Start()
    elseif event == "PLAYER_REGEN_ENABLED" then
        CombatTimer_Stop()
    elseif event == "PLAYER_TARGET_CHANGED" then
        Estimate_Reset()
        Estimate_Update()
    elseif event == "UNIT_HEALTH" and arg1 == "target" then
        Estimate_Update()
    end
end)

---------------------------------------------------------------------------
-- 主时间按钮点击：左键控制秒表，右键手动切换战斗计时器显示/隐藏
---------------------------------------------------------------------------
diminfo_Time:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
        sw_show()
    elseif arg1 == "RightButton" then
        -- 手动切换战斗计时器显示/隐藏（完全由用户控制）
        if d_combattimer:IsShown() then
            d_combattimer:Hide()
        else
            d_combattimer:Show()
        end
    end
end)

---------------------------------------------------------------------------
-- pfUI 皮肤支持（如果存在）
---------------------------------------------------------------------------
if pfUI then
    local penv = pfUI:GetEnvironment()
    local StripTextures, SkinButton, CreateBackdrop = penv.StripTextures, penv.SkinButton, penv.CreateBackdrop

    StripTextures(d_stopwatch)
    d_stopwatch:SetBackdropColor(0, 0, 0, 0.5)
    CreateBackdrop(d_stopwatch, nil, nil, .75)
    
    SkinButton(d_stopwatch_playpause)
    SkinButton(d_stopwatch_reset)
    
    -- 为战斗计时器添加pfUI皮肤
    StripTextures(d_combattimer)
    d_combattimer:SetBackdropColor(0, 0, 0, 0.5)
    CreateBackdrop(d_combattimer, nil, nil, .75)
end