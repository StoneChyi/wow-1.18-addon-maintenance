local diminfo_Quest = CreateFrame("Button", "diminfo_Quest", UIParent)
local Text = diminfo_Quest:CreateFontString(nil, "OVERLAY")
Text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
Text:SetPoint("RIGHT", diminfo_RaidCD, "LEFT", -20, 0)
diminfo_Quest:SetAllPoints(Text)

-- 状态变量
local isUpdating = false
local ignoreQuestLogUpdate = false
local headerStates = {}

--延迟执行函数
local function DelayedCall(func, delay)
    local frame = CreateFrame("Frame")
    frame.elapsed = 0
    frame:SetScript("OnUpdate", function()
        frame.elapsed = frame.elapsed + arg1
        if frame.elapsed >= delay then
            func()
            frame:SetScript("OnUpdate", nil)
        end
    end)
end

-- 核心：安全展开/恢复分组 + 统计任务
local function GetQuestCount()
    if isUpdating then return 0, 20 end
    
    isUpdating = true
    ignoreQuestLogUpdate = true
    
    local originalNumEntries = GetNumQuestLogEntries()
    local questCount = 0
    
    -- 第一步：保存分组状态并展开
    headerStates = {}
    for i = 1, originalNumEntries do
        local _, _, _, isHeader, isCollapsed = GetQuestLogTitle(i)
        if isHeader then
            headerStates[i] = isCollapsed
            if isCollapsed then
                ExpandQuestHeader(i)
            end
        end
    end
    
    -- 第二步：统计任务
    local newNumEntries = GetNumQuestLogEntries()
    for i = 1, newNumEntries do
        local title, _, _, isHeader = GetQuestLogTitle(i)
        if not isHeader and title then
            questCount = questCount + 1
        end
    end
    
    -- 第三步：恢复分组状态
    local restoreIndex = {}
    for idx, _ in pairs(headerStates) do
        table.insert(restoreIndex, idx)
    end
    table.sort(restoreIndex, function(a, b) return a > b end)
    
    for _, i in ipairs(restoreIndex) do
        if headerStates[i] then
            CollapseQuestHeader(i)
        end
    end    
    
    DelayedCall(function()
        ignoreQuestLogUpdate = false
        isUpdating = false
    end, 0.1)
    
    return questCount, 20
end

-- 安全更新显示
local function UpdateQuestDisplay()
    if isUpdating then return end
    local current, max = GetQuestCount()
    Text:SetText("任务"..current.."/"..max)
end

-- 鼠标提示
diminfo_Quest:SetScript("OnEnter", function()
    local current, max = GetQuestCount()
    
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("任务信息")
    GameTooltip:AddLine("左键：打开任务日志", 0.3, 1, 0.6)
    GameTooltip:AddLine("右键：打开数据库查询", 0.3, 1, 0.6)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("任务状态："..current.." 个 / "..max.." 个")
    
    -- 临时展开分组获取任务列表
    ignoreQuestLogUpdate = true
    local originalNumEntries = GetNumQuestLogEntries()
    local tempHeaderStates = {}
    
    for i = 1, originalNumEntries do
        local _, _, _, isHeader, isCollapsed = GetQuestLogTitle(i)
        if isHeader then
            tempHeaderStates[i] = isCollapsed
            if isCollapsed then
                ExpandQuestHeader(i)
            end
        end
    end
    
    local newNumEntries = GetNumQuestLogEntries()
    local displayed = 0
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("所有任务：")
    
    for i = 1, newNumEntries do
        if displayed >= 20 then break end
        local title, _, _, isHeader, _, isComplete = GetQuestLogTitle(i)
        if not isHeader and title then
            local color = isComplete and "|cff00ff00" or "|cffff0000"
            local status = isComplete and "[完成]" or "[进行中]"
            GameTooltip:AddLine(color..title.." "..status.."|r")
            displayed = displayed + 1
        end
    end
    
    -- 恢复分组状态
    local restoreIndex = {}
    for idx, _ in pairs(tempHeaderStates) do
        table.insert(restoreIndex, idx)
    end
    table.sort(restoreIndex, function(a, b) return a > b end)
    
    for _, i in ipairs(restoreIndex) do
        if tempHeaderStates[i] then
            CollapseQuestHeader(i)
        end
    end
    
    ignoreQuestLogUpdate = false
    GameTooltip:Show()
end)

diminfo_Quest:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 鼠标点击事件
diminfo_Quest:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
        ignoreQuestLogUpdate = true
        ToggleQuestLog()
        DelayedCall(function()
            ignoreQuestLogUpdate = false
            UpdateQuestDisplay()
        end, 0.5)
    elseif arg1 == "RightButton" then
        if pfQuestBrowser then
            if pfQuestBrowser:IsShown() then
                pfQuestBrowser:Hide()
            else
                pfQuestBrowser:Show()
            end
        else
            if DEFAULT_CHAT_FRAME then
                DEFAULT_CHAT_FRAME:AddMessage("提示：请先加载 pfQuest 插件")
            end
        end
    end
end)

-- 事件处理
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_LOG_UPDATE")
eventFrame:RegisterEvent("QUEST_WATCH_UPDATE")
eventFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")

eventFrame:SetScript("OnEvent", function()
    if not ignoreQuestLogUpdate and not isUpdating then
        DelayedCall(UpdateQuestDisplay, 0.2)
    end
end)

-- 初始更新
UpdateQuestDisplay()