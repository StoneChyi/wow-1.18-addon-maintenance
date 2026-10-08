-- 简化版PVP监控模块 - 确保命令功能正常工作

-- 全局变量存储框架和状态
local PVPMainFrame = nil
local isInBattleground = false

-- 简单的PVP技能数据库（职业 -> 技能列表）
local pvpSkillsDB = {
    -- 战士
    WARRIOR = {
        {name = "拦截", cooldown = 30},
        {name = "盾牌格挡", cooldown = 25},
        {name = "破胆怒吼", cooldown = 60}
    },
    -- 法师
    MAGE = {
        {name = "冰霜新星", cooldown = 20},
        {name = "闪现术", cooldown = 24},
        {name = "变形术", cooldown = 45}
    },
    -- 盗贼
    ROGUE = {
        {name = "消失", cooldown = 300},
        {name = "致盲", cooldown = 120},
        {name = "凿击", cooldown = 5}
    },
    -- 牧师
    PRIEST = {
        {name = "心灵控制", cooldown = 300},
        {name = "恐惧术", cooldown = 30},
        {name = "渐隐术", cooldown = 30}
    }
}

-- 存储敌对玩家的技能冷却信息
local enemyCooldowns = {}

-- 创建技能冷却条函数
local function CreateCooldownBar(parent, index)
    local barHeight = 16
    local x, y = 10, -40 - (index - 1) * (barHeight + 4)
    
    -- 创建冷却条容器
    local barFrame = CreateFrame("Frame", nil, parent)
    barFrame:SetWidth(parent:GetWidth() - 20)
    barFrame:SetHeight(barHeight)
    barFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    
    -- 背景
    local bg = barFrame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(barFrame)
    bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bg:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    
    -- 进度条
    local progressBar = barFrame:CreateTexture(nil, "ARTWORK")
    progressBar:SetPoint("LEFT", barFrame, "LEFT", 0, 0)
    progressBar:SetWidth(barFrame:GetWidth())
    progressBar:SetHeight(barFrame:GetHeight())
    progressBar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetVertexColor(0, 1, 0)
    
    -- 技能名称文本
    local skillName = barFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    skillName:SetPoint("LEFT", barFrame, "LEFT", 5, 0)
    skillName:SetTextColor(1, 1, 1)
    
    -- 倒计时文本
    local timeText = barFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    timeText:SetPoint("RIGHT", barFrame, "RIGHT", -5, 0)
    timeText:SetTextColor(1, 1, 1)
    
    -- 存储引用
    barFrame.progressBar = progressBar
    barFrame.skillName = skillName
    barFrame.timeText = timeText
    barFrame.isVisible = false
    
    -- 初始隐藏
    barFrame:Hide()
    
    return barFrame
end

-- 初始化框架函数
local function CreateMainFrame()
    if PVPMainFrame then return PVPMainFrame end
    
    -- 创建主框架
    local frame = CreateFrame("Frame", "PVP_Monitor_Frame", UIParent)
    frame:SetWidth(300)
    frame:SetHeight(300) -- 增加高度以容纳技能冷却条
    frame:SetPoint("CENTER", UIParent, "CENTER", -200, 0)
    
    -- 设置框架可移动
    frame:SetMovable(true)
    frame:EnableMouse(true)
    
    -- 设置背景（WoW 1.12兼容方式）
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    bg:SetVertexColor(0, 0, 0, 0.5)
    
    -- 设置标题
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, 10)
    title:SetText("PVP监控框架 (可拖动)")
    title:SetTextColor(1, 0, 0)
    
    -- 添加状态文本
    local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal") -- 使用正常大小的字体
    statusText:SetPoint("CENTER", frame, "CENTER", 0, 0) -- 居中显示
    statusText:SetWidth(frame:GetWidth() - 20) -- 设置适当的宽度
    statusText:SetJustifyH("CENTER") -- 水平居中对齐
    statusText:SetJustifyV("MIDDLE") -- 垂直居中对齐
    statusText:SetText("框架已初始化")
    statusText:SetTextColor(1, 1, 1)
    statusText:Show() -- 确保文本显示
    
    -- 添加拖动功能（WoW 1.12兼容）
    frame:SetScript("OnMouseDown", function()
        frame:StartMoving()
    end)
    
    frame:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
    end)
    
    -- 存储引用以便后续访问
    frame.titleText = title
    frame.statusText = statusText
    
    -- 创建技能冷却条（最多10个）
    frame.cooldownBars = {}
    for i = 1, 10 do
        frame.cooldownBars[i] = CreateCooldownBar(frame, i)
    end
    
    -- 初始隐藏
    frame:Hide()
    
    PVPMainFrame = frame
    return frame
end

-- 定义命令处理函数
function PVPMonitor_Command(cmd)
    -- 基本命令信息输出
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 命令已执行|r")
    
    -- 检查是否在战场中（简单实现）
    local inInstance, instanceType = IsInInstance()
    isInBattleground = inInstance and instanceType == "pvp"
    
    -- 将cmd转为小写以便匹配（兼容Lua 5.0）
    local cmd_lower = cmd or ""
    if type(cmd_lower) == "string" then
        cmd_lower = strlower(cmd_lower)
    end
    
    -- 确保框架已创建
    local frame = CreateMainFrame()
    
    -- 简单命令处理
    if cmd_lower == "show" or cmd_lower == "显示" then
        frame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 框架已显示|r")
    elseif cmd_lower == "hide" or cmd_lower == "隐藏" then
        frame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 框架已隐藏|r")
    elseif cmd_lower == "toggle" or cmd_lower == "切换" then
        if frame:IsVisible() then
            frame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 框架已隐藏|r")
        else
            frame:Show()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 框架已显示|r")
        end
    elseif cmd_lower == "test" or cmd_lower == "测试" then
        frame:Show()
        
        -- 简单的敌对目标检测
        local enemyCount = 0
        
        -- 首先检查目标是否是敌对玩家
        if UnitExists("target") and UnitIsPlayer("target") and UnitIsEnemy("target", "player") then
            enemyCount = enemyCount + 1
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[PVP监控] 目标: "..UnitName("target").." (距离: "..math.floor((UnitDistance("target") or 0) / 10).."码)|r")
        end
        
        -- 检查焦点是否是敌对玩家
        if UnitExists("focus") and UnitIsPlayer("focus") and UnitIsEnemy("focus", "player") then
            enemyCount = enemyCount + 1
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[PVP监控] 焦点: "..UnitName("focus").." (距离: "..math.floor((UnitDistance("focus") or 0) / 10).."码)|r")
        end
        
        -- 更新框架文本
        if frame.statusText then
            local status = isInBattleground and "战场中" or "不在战场中"
            -- 设置文本内容，并确保格式正确
            frame.statusText:SetText("测试模式激活\n状态: "..status.."\n敌对目标: "..enemyCount)
            -- 确保文本可见
            frame.statusText:Show()
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 测试模式已激活|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 当前状态: "..(isInBattleground and "战场中" or "不在战场中").."|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[PVP监控] 检测到敌对目标: "..enemyCount.." 个|r")
    elseif cmd_lower == "help" or cmd_lower == "帮助" or cmd_lower == "" then
        DEFAULT_CHAT_FRAME:AddMessage("====== PVP监控命令 ======", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/pvpmon show - 显示监控框架", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/pvpmon hide - 隐藏监控框架", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/pvpmon toggle - 切换框架显示", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/pvpmon test - 激活测试模式", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/pvpmon skills - 显示职业技能列表", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/pvpmon help - 显示此帮助", 0, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("=========================", 0, 1, 1)
    elseif cmd_lower == "skills" or cmd_lower == "技能" then
        DEFAULT_CHAT_FRAME:AddMessage("====== PVP技能数据库 ======", 0, 1, 1)
        -- 显示各职业技能
        for class, skills in pairs(pvpSkillsDB) do
            DEFAULT_CHAT_FRAME:AddMessage("\n|cff00ff00"..class.." 技能:|r", 0, 1, 1)
            for _, skill in pairs(skills) do
                DEFAULT_CHAT_FRAME:AddMessage("- "..skill.name.." (CD: "..skill.cooldown.."秒)", 0, 1, 1)
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("===========================", 0, 1, 1)
    end
end

-- 添加简单的事件监听函数
local function OnEvent(self, event, ...)
    if event == "ZONE_CHANGED_NEW_AREA" then
        local inInstance, instanceType = IsInInstance()
        isInBattleground = inInstance and instanceType == "pvp"
        
        -- 当进入或离开战场时通知用户
        if isInBattleground then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[PVP监控] 进入战场区域，监控已激活|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[PVP监控] 离开战场区域|r")
        end
    end
end

-- 添加一个简单的函数来获取玩家职业的技能
local function GetClassSkills(className)
    if not className then return {} end
    return pvpSkillsDB[strupper(className)] or {}
end

-- 创建事件监听框架
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", OnEvent)
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")

-- 注册命令（WoW 1.12兼容方式）
SLASH_PVPmonitor1 = "/pvpmon"
SLASH_PVPmonitor2 = "/pvp监控"
SlashCmdList["PVPmonitor"] = PVPMonitor_Command

-- 初始化插件组件
local function InitializeComponents()
    -- 这里可以添加任何需要在插件加载时初始化的代码
    -- 保持为空以避免错误
end

-- 调用初始化函数
InitializeComponents()

-- 输出命令注册成功信息
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PVP监控] 简化版模块已加载，命令 '/pvpmon' 已注册|r")
DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[PVP监控] 使用 /pvpmon help 查看可用命令|r")