-- Dispel engine and list UI are loaded from XinDispel.lua.
local ClassColors = RAID_CLASS_COLORS

-- 4. 配置界面框架 (XinSettingFrame)
-- ==========================================
local XinSettingFrame = CreateFrame("Frame", "XinSettingFrame", UIParent)
XinSettingFrame:SetWidth(200)
XinSettingFrame:SetHeight(400)
XinSettingFrame:SetPoint("CENTER", 0, 0) -- 默认放在屏幕正中央

-- 【核心UI美化】：改用 Tooltip 材质，实现极其纤细的高级边框
XinSettingFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, 
    tileSize = 16, 
    edgeSize = 16, -- 边框厚度从 32 大幅缩小到 16
    insets = { left = 4, right = 4, top = 4, bottom = 4 } -- 背景往外扩展，贴合细边框
})

-- 【进阶质感】：给背景和边框上色
-- 前三个参数是红绿蓝 (0,0,0为纯黑)，最后一个参数是透明度 (0.8表示80%不透明)
XinSettingFrame:SetBackdropColor(0, 0, 0, 0.8) 
-- 让边框带一点点暗金色或者灰色，显得不那么扎眼
XinSettingFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

-- 【交互优化】：让配置界面可以被鼠标左键按住拖动
XinSettingFrame:EnableMouse(true)
XinSettingFrame:SetMovable(true)
XinSettingFrame:RegisterForDrag("LeftButton")
XinSettingFrame:SetScript("OnDragStart", function() this:StartMoving() end)
XinSettingFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)

-- 创建顶部标题 “欣”
local titleText = XinSettingFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("TOP", XinSettingFrame, "TOP", 0, -15) -- 挂在顶部中心，往下偏移 15 像素以免被边框挡住
titleText:SetText("欣")
titleText:SetTextColor(1, 0.5, 0) -- 设置为橙色 (Red: 1, Green: 0.5, Blue: 0)

-- 初始化时让它处于隐藏状态
XinSettingFrame:Hide()


-- ==========================================
-- 在配置界面添加【锚点呼出】按钮
-- ==========================================

-- 按钮 1：呼出可施法锚点
local showAnchorBtn_InRange = CreateFrame("Button", nil, XinSettingFrame, "UIPanelButtonTemplate")
showAnchorBtn_InRange:SetWidth(120)
showAnchorBtn_InRange:SetHeight(24)
showAnchorBtn_InRange:SetPoint("TOP", XinSettingFrame, "TOP", 0, -40)
showAnchorBtn_InRange:SetText("锚点(可驱散)")

showAnchorBtn_InRange:SetScript("OnClick", function()
    XinMainFrame_InRange:Unlock()
end)

-- 按钮 2：呼出不可施法锚点 (排列在第一个按钮正下方)
local showAnchorBtn_OutRange = CreateFrame("Button", nil, XinSettingFrame, "UIPanelButtonTemplate")
showAnchorBtn_OutRange:SetWidth(120)
showAnchorBtn_OutRange:SetHeight(24)
showAnchorBtn_OutRange:SetPoint("TOP", XinSettingFrame, "TOP", 0, -70)
showAnchorBtn_OutRange:SetText("锚点(不可驱散)")

showAnchorBtn_OutRange:SetScript("OnClick", function()
    XinMainFrame_OutRange:Unlock()
end)














-- ==========================================
-- 5. 注册斜杠命令呼出/隐藏功能
-- ==========================================
-- 在 1.12 的 Lua API 中，注册斜杠命令必须用这种标准格式
SLASH_XINLOAD1 = "/xinload"
SlashCmdList["XINLOAD"] = function(msg)
    -- 判断当前面板是否可见，可见则隐藏，隐藏则显示
    if XinSettingFrame:IsVisible() then
        XinSettingFrame:Hide()
    else
        XinSettingFrame:Show()
    end
end

-- ==========================================
-- 6. 数据存储与滑动条 UI (xinDB版)
-- ==========================================

local XinEventFrame = CreateFrame("Frame")
XinEventFrame:RegisterEvent("VARIABLES_LOADED")
XinEventFrame:SetScript("OnEvent", function()
    -- 第一步：大前提保护。如果根本没有 xinDB，先给它建个“空房子”
    if not xinDB then
        xinDB = {}
    end
    -- 第二步：给所有的变量上独立保护锁（必须写在上面那个 if 的外面！）
    -- 这样不管是新用户刚建的空房子，还是老用户的旧房子，都会挨个接受检查
    if xinDB.enableOutRange == nil then xinDB.enableOutRange = true end
    if xinDB.maxInRange == nil then xinDB.maxInRange = 5 end
    if xinDB.maxOutRange == nil then xinDB.maxOutRange = 5 end
-- 【新增】：初始化自定义屏蔽表
    if not xinDB.IgnoreList then 
        xinDB.IgnoreList = {
            ["冰柱"] = 1,         -- 内置：屏蔽状态
        } 
    end

-- 【关键新增】：初始化团本战术手册的专用表
    if not xinDB.RaidSettings then
        xinDB.RaidSettings = {}
    end

    local XinRaid_CurrentSelectedDebuff = nil

-- 【修改处 1】：初始化读取数据时的文本格式
    XinSlider_InRange:SetValue(xinDB.maxInRange)
    getglobal(XinSlider_InRange:GetName() .. 'Text'):SetText('可驱散列表显示数量: ' .. xinDB.maxInRange .. '个')
    
    XinSlider_OutRange:SetValue(xinDB.maxOutRange)
    getglobal(XinSlider_OutRange:GetName() .. 'Text'):SetText('不可驱散列表显示数量: ' .. xinDB.maxOutRange .. '个')

    -- 【新增】：复选框同步
    XinCheck_OutRange:SetChecked(xinDB.enableOutRange)
end)

-- 【滑动条 1】：可施法数量
local XinSlider_InRange = CreateFrame("Slider", "XinSlider_InRange", XinSettingFrame, "OptionsSliderTemplate")
XinSlider_InRange:SetWidth(150)
XinSlider_InRange:SetHeight(16)
XinSlider_InRange:SetPoint("TOP", showAnchorBtn_OutRange, "BOTTOM", 0, -25)
XinSlider_InRange:SetMinMaxValues(3, 10)
XinSlider_InRange:SetValueStep(1) 

getglobal(XinSlider_InRange:GetName() .. 'Low'):SetText('3')
getglobal(XinSlider_InRange:GetName() .. 'High'):SetText('10')
getglobal(XinSlider_InRange:GetName() .. 'Text'):SetText('可驱散列表显示数量: 5')

XinSlider_InRange:SetScript("OnValueChanged", function()
    local val = math.floor(this:GetValue())
    -- 写入值改为 xinDB
    xinDB.maxInRange = val 
    getglobal(this:GetName() .. 'Text'):SetText('可驱散列表显示数量: ' .. val .. '个')
end)

-- 【滑动条 2】：不可施法数量
local XinSlider_OutRange = CreateFrame("Slider", "XinSlider_OutRange", XinSettingFrame, "OptionsSliderTemplate")
XinSlider_OutRange:SetWidth(150)
XinSlider_OutRange:SetHeight(16)
XinSlider_OutRange:SetPoint("TOP", XinSlider_InRange, "BOTTOM", 0, -35)
XinSlider_OutRange:SetMinMaxValues(3, 10)
XinSlider_OutRange:SetValueStep(1)

getglobal(XinSlider_OutRange:GetName() .. 'Low'):SetText('3')
getglobal(XinSlider_OutRange:GetName() .. 'High'):SetText('10')
getglobal(XinSlider_OutRange:GetName() .. 'Text'):SetText('不可驱散列表显示数量: 5')

XinSlider_OutRange:SetScript("OnValueChanged", function()
    local val = math.floor(this:GetValue())
    -- 写入值改为 xinDB
    xinDB.maxOutRange = val
-- 【修改处 3】：拖动滑动条时的文本格式
    getglobal(this:GetName() .. 'Text'):SetText('不可驱散列表显示数量: ' .. val .. '个')
end)

-- ==========================================
-- 2. 【新增】：在界面的最下方添加复选框 (接在两个滑动条后面)
-- ==========================================
local XinCheck_OutRange = CreateFrame("CheckButton", "XinCheck_OutRange", XinSettingFrame, "OptionsCheckButtonTemplate")
-- 定位在第二个滑动条的正下方，稍微偏左对齐
XinCheck_OutRange:SetPoint("TOP", XinSettingFrame, "TOP", -55, -200) 
-- 设置文字
getglobal(XinCheck_OutRange:GetName() .. "Text"):SetText("启用不可驱散列表")

-- 绑定点击事件：将状态实时写入 xinDB
XinCheck_OutRange:SetScript("OnClick", function()
    if not xinDB then return end
    
    -- 在 1.12 版本中，GetChecked() 选中时通常返回 1，未选中返回 nil
    local isChecked = this:GetChecked()
    if isChecked == 1 or isChecked == true then
        xinDB.enableOutRange = true
    else
        xinDB.enableOutRange = false
    end
end)


-- ==========================================
-- 7. 名单框架与黑/白名单数据 (XinListFrame)
-- ==========================================
PriorityList = {}
BlackList = {}

local XinListFrame = CreateFrame("Frame", "XinListFrame", UIParent)
XinListFrame:SetWidth(420)
-- 【微调】：为了适应大单选框和更大的行距，将整体高度提升到 580
XinListFrame:SetHeight(580)
XinListFrame:SetPoint("TOPLEFT", XinSettingFrame, "TOPRIGHT", 5, 0) 

XinListFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
XinListFrame:SetBackdropColor(0, 0, 0, 0.9) 
XinListFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) 
XinListFrame:Hide()

local listTitle = XinListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
listTitle:SetPoint("TOP", XinListFrame, "TOP", 0, -15)
listTitle:SetText("名单")
listTitle:SetTextColor(0, 1, 0)

local closeListBtn = CreateFrame("Button", nil, XinListFrame, "UIPanelCloseButton")
closeListBtn:SetPoint("TOPRIGHT", XinListFrame, "TOPRIGHT", -5, -5)

local refreshBtn = CreateFrame("Button", nil, XinListFrame, "UIPanelButtonTemplate")
refreshBtn:SetWidth(80)
refreshBtn:SetHeight(24)
refreshBtn:SetPoint("BOTTOM", XinListFrame, "BOTTOM", 0, 15)
refreshBtn:SetText("刷新")
refreshBtn:SetScript("OnClick", function()
    UpdateXinListFrame()
end)

local XinListFrameUnits = {}

for groupIndex = 1, 8 do
    local col = math.fmod((groupIndex - 1), 2)   
    local row = math.floor((groupIndex - 1) / 2) 

    local startX = 20 + col * 200
    -- 【微调】：加大了每个小队之间的垂直间隔 (从 105 增加到 125)
    local startY = -40 - row * 125 

    local groupTitle = XinListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupTitle:SetPoint("TOPLEFT", XinListFrame, "TOPLEFT", startX, startY)
    groupTitle:SetText("小队 " .. groupIndex)
    groupTitle:SetTextColor(1, 0.8, 0) 

    -- 【修改1：水平对齐】：标题和列名统一使用 startY，在同一水平线上
    local headerPrio = XinListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerPrio:SetPoint("TOPLEFT", XinListFrame, "TOPLEFT", startX + 80, startY)
    headerPrio:SetText("优先名单")
    headerPrio:SetTextColor(1, 0.8, 0)

    local headerBlack = XinListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    headerBlack:SetPoint("TOPLEFT", XinListFrame, "TOPLEFT", startX + 145, startY)
    headerBlack:SetText("黑名单")
    headerBlack:SetTextColor(1, 0.8, 0)

    for playerIndex = 1, 5 do
        -- 【微调】：加大每个玩家名字之间的垂直间距 (从 16 增加到 20)
        local playerY = startY - 24 - (playerIndex - 1) * 20
        
        local nameStr = XinListFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameStr:SetPoint("TOPLEFT", XinListFrame, "TOPLEFT", startX, playerY)
        nameStr:SetText("空")
        -- 【修改】：把原来的 65 改成 90，给 5~6 个字的名字留足空间
        nameStr:SetWidth(90) 
        nameStr:SetJustifyH("LEFT")
        nameStr:SetTextColor(0.5, 0.5, 0.5)

        -- 【修改2：大尺寸单选框】：宽高统一调至 22
        -- 【修改3：像素级对齐】：利用准星中心(CENTER)精准对齐上方表头的中心点
        local prioCheck = CreateFrame("CheckButton", "XinListFrame_Prio_"..groupIndex.."_"..playerIndex, XinListFrame, "UICheckButtonTemplate")
        prioCheck:SetWidth(22)
        prioCheck:SetHeight(22)
        -- startX + 104 刚好是 "优先名单" 四个字的几何中心位置
        prioCheck:SetPoint("CENTER", XinListFrame, "TOPLEFT", startX + 104, playerY - 5)

        local blackCheck = CreateFrame("CheckButton", "XinListFrame_Black_"..groupIndex.."_"..playerIndex, XinListFrame, "UICheckButtonTemplate")
        blackCheck:SetWidth(22)
        blackCheck:SetHeight(22)
        -- startX + 163 刚好是 "黑名单" 三个字的几何中心位置
        blackCheck:SetPoint("CENTER", XinListFrame, "TOPLEFT", startX + 163, playerY - 5)

        local unitId = "raid" .. ((groupIndex - 1) * 5 + playerIndex)
        
        local unitData = {
            nameStr = nameStr,
            prioCheck = prioCheck,
            blackCheck = blackCheck,
            unit = unitId
        }
        table.insert(XinListFrameUnits, unitData)

        prioCheck:SetScript("OnClick", function()
            local playerName = nameStr:GetText()
            if playerName == "空" or not playerName then 
                this:SetChecked(false) 
                return 
            end
            
            if this:GetChecked() then
                PriorityList[playerName] = true
                BlackList[playerName] = nil
                blackCheck:SetChecked(false) 
            else
                PriorityList[playerName] = nil
            end
        end)

        blackCheck:SetScript("OnClick", function()
            local playerName = nameStr:GetText()
            if playerName == "空" or not playerName then 
                this:SetChecked(false) 
                return 
            end
            
            if this:GetChecked() then
                BlackList[playerName] = true
                PriorityList[playerName] = nil
                prioCheck:SetChecked(false) 
            else
                BlackList[playerName] = nil
            end
        end)
    end
end

function UpdateXinListFrame()
    -- 1. 打扫战场：重置所有格子，并清空上一次绑定的数据
    for _, data in ipairs(XinListFrameUnits) do
        data.nameStr:SetText("空")
        data.nameStr:SetTextColor(0.5, 0.5, 0.5)
        data.prioCheck:SetChecked(false)
        data.blackCheck:SetChecked(false)
        data.unit = nil 
        data.playerName = nil   -- 【新增】：用于缓存名字
        data.englishClass = nil -- 【新增】：用于缓存职业
    end

    -- 2. 动态分配座位并抓取数据
    if GetNumRaidMembers() > 0 then
        local groupCounts = {0, 0, 0, 0, 0, 0, 0, 0}
        
        for i = 1, GetNumRaidMembers() do
            -- 【吸收治疗插件的精华】：直接从系统 roster 获取名字和职业，防掉线、防过远！
            local name, _, subgroup, _, _, englishClass = GetRaidRosterInfo(i)
            
            if subgroup and subgroup >= 1 and subgroup <= 8 then
                groupCounts[subgroup] = groupCounts[subgroup] + 1
                local slotIndex = (subgroup - 1) * 5 + groupCounts[subgroup]
                
                if slotIndex <= 40 and XinListFrameUnits[slotIndex] then
                    XinListFrameUnits[slotIndex].unit = "raid" .. i
                    XinListFrameUnits[slotIndex].playerName = name
                    XinListFrameUnits[slotIndex].englishClass = englishClass
                end
            end
        end
    else
        -- 【小队/单人模式合并】：不再写两个大分支，因为单人就是 0 个队友的小队
        XinListFrameUnits[1].unit = "player"
        XinListFrameUnits[1].playerName = UnitName("player")
        local _, myClass = UnitClass("player")
        XinListFrameUnits[1].englishClass = myClass
        
        for i = 1, GetNumPartyMembers() do
            if XinListFrameUnits[1 + i] then
                local pUnit = "party" .. i
                XinListFrameUnits[1 + i].unit = pUnit
                XinListFrameUnits[1 + i].playerName = UnitName(pUnit)
                local _, pClass = UnitClass(pUnit)
                XinListFrameUnits[1 + i].englishClass = pClass
            end
        end
    end

    -- 3. 统一渲染出图
    for _, data in ipairs(XinListFrameUnits) do
        -- 【优化】：只要分配了名字就渲染，取代了 UnitExists，即使队友掉线也能看到勾选状态
        if data.playerName then 
            data.nameStr:SetText(data.playerName)
            
            if data.englishClass and ClassColors[data.englishClass] then
                local c = ClassColors[data.englishClass]
                data.nameStr:SetTextColor(c.r, c.g, c.b)
            else
                data.nameStr:SetTextColor(1, 1, 1) -- 兜底白色
            end
            
            -- 读取个人数据里的勾选状态
            data.prioCheck:SetChecked(PriorityList[data.playerName] == true)
            data.blackCheck:SetChecked(BlackList[data.playerName] == true)
        end
    end
end

XinListFrame:SetScript("OnShow", function()
    UpdateXinListFrame()
end)

-- (请用以下代码替换掉你原来第7部分最末尾的 showListBtn 和 OnHide 代码)

local showListBtn = CreateFrame("Button", nil, XinSettingFrame, "UIPanelButtonTemplate")
showListBtn:SetWidth(120)
showListBtn:SetHeight(24)
showListBtn:SetPoint("TOP", XinSettingFrame, "TOP", 0, -240) 
showListBtn:SetText("黑白名单设置")
showListBtn:SetScript("OnClick", function()
    if XinListFrame:IsVisible() then
        XinListFrame:Hide()
    else
        -- 【互斥逻辑】：打开黑白名单时，强行关闭屏蔽面板
        if XinIgnoreFrame and XinIgnoreFrame:IsVisible() then XinIgnoreFrame:Hide() end
        XinListFrame:Show()
    end
end)

local showIgnoreBtn = CreateFrame("Button", nil, XinSettingFrame, "UIPanelButtonTemplate")
showIgnoreBtn:SetWidth(120)
showIgnoreBtn:SetHeight(24)
showIgnoreBtn:SetPoint("TOP", showListBtn, "BOTTOM", 0, -10) 
showIgnoreBtn:SetText("自定义屏蔽设置")
showIgnoreBtn:SetScript("OnClick", function()
    if XinIgnoreFrame:IsVisible() then
        XinIgnoreFrame:Hide()
    else
        -- 【互斥逻辑】：打开屏蔽面板时，强行关闭黑白名单
        if XinListFrame and XinListFrame:IsVisible() then XinListFrame:Hide() end
        XinIgnoreFrame:Show()
    end
end)

-- 【全局联动】：关闭欣设置主面板时，把另外两个子面板全部干掉
local oldHide = XinSettingFrame:GetScript("OnHide")
XinSettingFrame:SetScript("OnHide", function()
    if oldHide then oldHide() end
    if XinListFrame then XinListFrame:Hide() end
    if XinIgnoreFrame then XinIgnoreFrame:Hide() end
end)

-- ==========================================
-- 新增：呼出“团本驱散手册”大窗口的按钮
-- ==========================================
local showRaidBtn = CreateFrame("Button", nil, XinSettingFrame, "UIPanelButtonTemplate")
showRaidBtn:SetWidth(120)
showRaidBtn:SetHeight(24)
showRaidBtn:SetPoint("TOP", showIgnoreBtn, "BOTTOM", 0, -10) 
showRaidBtn:SetText("团本驱散手册")
showRaidBtn:SetScript("OnClick", function()
    if XinRaidFrame:IsVisible() then
        XinRaidFrame:Hide()
    else
        -- 【互斥逻辑】：打开团本手册时，关闭另外两个小设置面板
        if XinListFrame and XinListFrame:IsVisible() then XinListFrame:Hide() end
        if XinIgnoreFrame and XinIgnoreFrame:IsVisible() then XinIgnoreFrame:Hide() end
        XinRaidFrame:Show()
    end
end)

-- 别忘了更新一下 XinSettingFrame 的 OnHide 逻辑，把新窗口也绑进去
local oldHide2 = XinSettingFrame:GetScript("OnHide")
XinSettingFrame:SetScript("OnHide", function()
    if oldHide2 then oldHide2() end
    if XinListFrame then XinListFrame:Hide() end
    if XinIgnoreFrame then XinIgnoreFrame:Hide() end
    if XinRaidFrame then XinRaidFrame:Hide() end
end)



-- ==========================================
-- 8. 自定义屏蔽列表面板 (带下拉滚动条)
-- ==========================================
XinIgnoreFrame = CreateFrame("Frame", "XinIgnoreFrame", UIParent)
XinIgnoreFrame:SetWidth(300)
XinIgnoreFrame:SetHeight(450)
XinIgnoreFrame:SetPoint("TOPLEFT", XinSettingFrame, "TOPRIGHT", 5, 0) 

XinIgnoreFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
XinIgnoreFrame:SetBackdropColor(0, 0, 0, 0.9) 
XinIgnoreFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1) 
XinIgnoreFrame:Hide()

local ignoreTitle = XinIgnoreFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
ignoreTitle:SetPoint("TOP", XinIgnoreFrame, "TOP", 0, -15)
ignoreTitle:SetText("自定义屏蔽列表")
ignoreTitle:SetTextColor(1, 0.5, 0)

local closeIgnoreBtn = CreateFrame("Button", nil, XinIgnoreFrame, "UIPanelCloseButton")
closeIgnoreBtn:SetPoint("TOPRIGHT", XinIgnoreFrame, "TOPRIGHT", -5, -5)

-- 输入框与单选框
local ignoreEditBox = CreateFrame("EditBox", "XinIgnoreEditBox", XinIgnoreFrame, "InputBoxTemplate")
ignoreEditBox:SetWidth(150)
ignoreEditBox:SetHeight(20)
ignoreEditBox:SetPoint("TOPLEFT", XinIgnoreFrame, "TOPLEFT", 25, -50)
ignoreEditBox:SetAutoFocus(false)

local checkStatus = CreateFrame("CheckButton", "XinIgnoreCheckStatus", XinIgnoreFrame, "UICheckButtonTemplate")
checkStatus:SetWidth(20)
checkStatus:SetHeight(20)
checkStatus:SetPoint("TOPLEFT", ignoreEditBox, "BOTTOMLEFT", -5, -5)
local labelStatus = checkStatus:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
labelStatus:SetPoint("LEFT", checkStatus, "RIGHT", 2, 0)
labelStatus:SetText("单一屏蔽")
checkStatus:SetChecked(true) 

local checkPlayer = CreateFrame("CheckButton", "XinIgnoreCheckPlayer", XinIgnoreFrame, "UICheckButtonTemplate")
checkPlayer:SetWidth(20)
checkPlayer:SetHeight(20)
checkPlayer:SetPoint("LEFT", labelStatus, "RIGHT", 25, 0)
local labelPlayer = checkPlayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
labelPlayer:SetPoint("LEFT", checkPlayer, "RIGHT", 2, 0)
labelPlayer:SetText("完全屏蔽")

checkStatus:SetScript("OnClick", function() this:SetChecked(true); checkPlayer:SetChecked(false) end)
checkPlayer:SetScript("OnClick", function() this:SetChecked(true); checkStatus:SetChecked(false) end)

local addIgnoreBtn = CreateFrame("Button", nil, XinIgnoreFrame, "UIPanelButtonTemplate")
addIgnoreBtn:SetWidth(60)
addIgnoreBtn:SetHeight(22)
addIgnoreBtn:SetPoint("LEFT", ignoreEditBox, "RIGHT", 10, 0)
addIgnoreBtn:SetText("添加")

-- 【新增】：创建下拉滚动条控制器
local XinIgnoreScrollFrame = CreateFrame("ScrollFrame", "XinIgnoreScrollFrame", XinIgnoreFrame, "FauxScrollFrameTemplate")
XinIgnoreScrollFrame:SetWidth(240)
XinIgnoreScrollFrame:SetHeight(300) -- 12行 * 25像素
XinIgnoreScrollFrame:SetPoint("TOPLEFT", XinIgnoreFrame, "TOPLEFT", 15, -110)

-- 创建 12 行可视化UI池
local ignoreRows = {}
for i = 1, 12 do
    local row = CreateFrame("Frame", nil, XinIgnoreFrame)
    row:SetWidth(260)
    row:SetHeight(20)
    -- UI固定不动，由滚动条决定里面显示什么字
    row:SetPoint("TOPLEFT", XinIgnoreFrame, "TOPLEFT", 20, -110 - (i - 1) * 25)
    
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.nameText:SetPoint("LEFT", row, "LEFT", 5, 0)
    row.nameText:SetWidth(120)
    row.nameText:SetJustifyH("LEFT")
    
    row.typeText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.typeText:SetPoint("LEFT", row.nameText, "RIGHT", 10, 0)
    row.typeText:SetTextColor(1, 0.8, 0) -- 统一使用标准的魔兽黄色，取消红色
    
    row.delBtn = CreateFrame("Button", nil, row, "UIPanelCloseButton")
    row.delBtn:SetWidth(24)
    row.delBtn:SetHeight(24)
    row.delBtn:SetPoint("RIGHT", row, "RIGHT", -25, 0)
    row.delBtn:SetScript("OnClick", function()
        if this.debuffName and xinDB.IgnoreList then
            xinDB.IgnoreList[this.debuffName] = nil
            UpdateIgnoreListUI()
        end
    end)
    
    ignoreRows[i] = row
end

-- 【核心】：带滚动条的动态刷新逻辑
local IgnoreListData = {}
function UpdateIgnoreListUI()
    if not xinDB or not xinDB.IgnoreList then return end
    
    -- 1. 将字典转换为有序数组，方便滚动条计算行数
    IgnoreListData = {}
    for debuffName, level in pairs(xinDB.IgnoreList) do
        table.insert(IgnoreListData, {name = debuffName, level = level})
    end
    
    -- 【修复报错】：1.12 版本必须使用 table.getn() 来获取数组长度！
    local dataCount = table.getn(IgnoreListData)
    
    -- 2. 告诉系统：一共有多少条数据，屏幕上显示12条，每条高25像素
    FauxScrollFrame_Update(XinIgnoreScrollFrame, dataCount, 12, 25)
    
    -- 3. 获取当前滚动条滑动了多少行
    local offset = FauxScrollFrame_GetOffset(XinIgnoreScrollFrame)
    
    -- 4. 渲染对应的行数
    for i = 1, 12 do
        local dataIndex = offset + i
        local row = ignoreRows[i]
        
        if dataIndex <= dataCount then
            local data = IgnoreListData[dataIndex]
            row.nameText:SetText(data.name)
            
            -- 直接用简洁的文字
            if data.level == 1 then
                row.typeText:SetText("单一屏蔽")
            elseif data.level == 2 then
                row.typeText:SetText("完全屏蔽")
            end
            
            row.delBtn.debuffName = data.name
            row:Show()
        else
            row:Hide() -- 如果数据不够，把多余的空白行隐藏
        end
    end 
end

-- 绑定滚动事件
XinIgnoreScrollFrame:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(25, UpdateIgnoreListUI)
end)

addIgnoreBtn:SetScript("OnClick", function()
    local text = ignoreEditBox:GetText()
    text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    if text ~= "" and xinDB and xinDB.IgnoreList then
        local level = checkPlayer:GetChecked() and 2 or 1
        xinDB.IgnoreList[text] = level
        ignoreEditBox:SetText("")
        ignoreEditBox:ClearFocus()
        UpdateIgnoreListUI()
    end
end)

XinIgnoreFrame:SetScript("OnShow", function() UpdateIgnoreListUI() end)



-- ==========================================
-- 9. 团本驱散手册大面板 (XinRaidFrame)
-- ==========================================
XinRaidFrame = CreateFrame("Frame", "XinRaidFrame", UIParent)
XinRaidFrame:SetWidth(650)  
XinRaidFrame:SetHeight(560)
XinRaidFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) 

XinRaidFrame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
XinRaidFrame:SetBackdropColor(0, 0, 0, 0.95) 
XinRaidFrame:SetBackdropBorderColor(0.8, 0.6, 0.2, 1) 

XinRaidFrame:EnableMouse(true)
XinRaidFrame:SetMovable(true)
XinRaidFrame:RegisterForDrag("LeftButton")
XinRaidFrame:SetScript("OnDragStart", function() this:StartMoving() end)
XinRaidFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
XinRaidFrame:Hide()

local raidTitle = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
raidTitle:SetPoint("TOP", XinRaidFrame, "TOP", 0, -15)
raidTitle:SetText("团本驱散手册")
raidTitle:SetTextColor(1, 0.8, 0)

local closeRaidBtn = CreateFrame("Button", nil, XinRaidFrame, "UIPanelCloseButton")
closeRaidBtn:SetPoint("TOPRIGHT", XinRaidFrame, "TOPRIGHT", -5, -5)

-- ==========================================
-- 《团本驱散手册》静态数据库 (你的干货区)
-- ==========================================
-- ==========================================
-- 《团本驱散手册》静态数据库 (扩充详情版)
-- ==========================================
-- ==========================================
-- 《团本驱散手册》静态数据库 (祖格13技能完整版)
-- ==========================================
XinRaidManualDB = {
    ["祖尔格拉布"] = {
        { 
            name = "毒液喷射", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "拉札什奎蛇", 
            effect = "每2秒受到一次自然伤害",
            note = "无" 
        },
        { 
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "古拉巴什狂暴者", 
            effect = "攻击间隔延长33%、移动速度降低61%",
            note = "无" 
        },
        { 
            -- 合并了 (3) 和 (9)
            name = "感染撕咬", icon = "Interface\\Icons\\Spell_Shadow_CallofBone", type = "Disease",
            caster = "古拉巴什蝙蝠骑士、拉札什迅猛龙", 
            effect = "[古拉巴什蝙蝠骑士]每10秒受到一次自然伤害、在受到物理攻击时承受更多伤害\n\n[拉札什迅猛龙]每10秒受到250点自然伤害、受到物理攻击时承受的伤害值提高100点",
            note = "无" 
        },
        { 
            name = "妖术", icon = "Interface\\Icons\\Spell_Shaman_Hex", type = "Magic",
            caster = "哈卡莱巫医、妖术师金度", 
            effect = "被变形",
            note = "无" 
        },
        { 
            name = "音爆", icon = "Interface\\Icons\\Spell_Nature_WispSplode", type = "Magic",
            caster = "高阶女祭司耶克里克", 
            effect = "不能施法",
            note = "无" 
        },
        { 
            -- 合并了 (6) 和 (12)
            name = "暗言术：痛", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", type = "Magic",
            caster = "高阶女祭司耶克里克、高阶女祭司娅尔罗", 
            effect = "[高阶女祭司耶克里克]每3秒受到422到478点暗影伤害\n\n[高阶女祭司娅尔罗]每3秒704到796点暗影伤害",
            note = "无" 
        },
        { 
            name = "中毒", icon = "Interface\\Icons\\Spell_Nature_NullifyDisease", type = "Poison",
            caster = "拉扎什眼镜蛇", 
            effect = "每3秒受到一次自然伤害",
            note = "无" 
        },
        { 
            name = "宁神毒药", icon = "Interface\\Icons\\Ability_Creature_Poison_03", type = "Poison",
            caster = "拉扎什毒蛇", 
            effect = "攻击间隔延长150%、移动速度降低70%、每秒吸取10点怒气值、越来越困……",
            note = "8秒持续时间结束时获得无法驱散、持续时间为10秒的<睡眠>效果(无法移动、操作)" 
        },
        { 
            name = "沉默", icon = "Interface\\Icons\\Spell_Holy_Silence", type = "Magic",
            caster = "高阶祭司塞卡尔", 
            effect = "不能施法",
            note = "无" 
        },
        { 
            name = "翼龙钉刺", icon = "Interface\\Icons\\INV_Spear_02", type = "Poison",
            caster = "哈卡莱暗影猎手", 
            effect = "沉睡",
            note = "无" 
        },
        { 
            name = "酸性毒液", icon = "Interface\\Icons\\Spell_Nature_Acid_01", type = "Poison",
            caster = "哈卡之子", 
            effect = "每3秒造成100点伤害",
            note = "无" 
        },
        { 
            name = "吸取生命", icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", type = "Magic",
            caster = "哈卡莱鲜血祭司", 
            effect = "在5秒内从敌人身上吸取总计1500点生命值，并将其转移给施法者",
            note = "无" 
        },
        { 
            name = "恐惧术", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "灵魂掠夺者", 
            effect = "因恐惧而逃跑",
            note = "无" 
        }
    },
    
    ["卡拉赞下层大厅"] = {
        {
            name = "幻影尖叫", icon = "Interface\\Icons\\Spell_Shadow_PsychicScream", type = "Magic",
            caster = "幻影仆从", 
            effect = "无法施展法术",
            note = "无" 
        },
        {
            name = "腐蚀箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "掠网毒牙蛛", 
            effect = "每3秒造成一次自然伤害",
            note = "无" 
        },
        {
            name = "巢毒齐射", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "掠网毒牙蛛、巢穴女王阿拉克萨娜", 
            effect = "每3秒造成自然伤害",
            note = "无" 
        },
        {
            name = "水蛭叮咬", icon = "Interface\\Icons\\Ability_PoisonSting", type = "Poison",
            caster = "掠网爬行者", 
            effect = "治疗效果降低25%",
            note = "无" 
        },
        {
            name = "暗牙毒液", icon = "Interface\\Icons\\Spell_Nature_SlowPoison", type = "Poison",
            caster = "掠网暗牙蛛", 
            effect = "移动速度降低10%、攻击和施法速度降低15%",
            note = "无" 
        },
        {
            name = "冰霜震击", icon = "Interface\\Icons\\Spell_Frost_FrostShock", type = "Magic",
            caster = "劣魔原猎者", 
            effect = "移动速度降低",
            note = "无" 
        },
        {
            name = "吸取法力", icon = "Interface\\Icons\\Spell_Shadow_SiphonMana", type = "Magic",
            caster = "劣魔影织者", 
            effect = "在5秒内吸取总计1540点法力值",
            note = "无" 
        },
        {
            name = "烟雾弹", icon = "Interface\\Icons\\Ability_Vanish", type = "Magic",
            caster = "莫罗斯", 
            effect = "无法施展法术",
            note = "无" 
        }
    },    
    
    ["安其拉废墟"] = {
        {
            name = "扎拉虫巢催化", icon = "Interface\\Icons\\Ability_Creature_Poison_02", type = "Poison",
            caster = "佐拉黄蜂", 
            effect = "移动速度降低50%、每2秒146点伤害、被扎拉钉刺攻击时承受更多伤害",
            note = "无" 
        },
        {
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "其拉战士", 
            effect = "攻击间隔延长33%、移动速度降低60%",
            note = "无" 
        }
    },
    
    ["奥妮克希亚的巢穴"] = {
        {
            name = "烈焰鞭笞", icon = "Interface\\Icons\\Spell_Fire_Fireball", type = "Magic",
            caster = "奥妮克希亚守卫", 
            effect = "火焰抗性降低70点",
            note = "无" 
        },
        {
            name = "烈焰打击", icon = "Interface\\Icons\\Spell_Fire_Fireball", type = "Magic",
            caster = "奥妮克希亚火嗣", 
            effect = "受到火焰攻击时多承受1000点伤害",
            note = "无" 
        },
        {
            name = "爆裂印记", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", type = "Magic",
            caster = "奥妮克希亚煽动者", 
            effect = "当被击中时对自己和盟友造成657到843点火焰伤害",
            note = "无" 
        }
    },
    
    ["熔火之心"] = {
        {
            name = "灵魂燃烧", icon = "Interface\\Icons\\Spell_Fire_SoulBurn", type = "Magic",
            caster = "火焰之王", 
            effect = "在16秒内受到4000点火焰伤害、物理伤害能力降低50%、沉默",
            note = "无" 
        },
        {
            name = "枯萎热浪", icon = "Interface\\Icons\\Spell_Fire_Fire", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "生命值上限降低35%",
            note = "无" 
        },
        {
            name = "灼烧之焰", icon = "Interface\\Icons\\Spell_Fire_Volcano", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "火焰抗性降低200点",
            note = "无" 
        },
        {
            name = "上古恐慌", icon = "Interface\\Icons\\Spell_Shadow_CurseOfTounges", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "施法速度降低50%、攻击间隔延长100%",
            note = "无" 
        },
        {
            name = "上古绝望", icon = "Interface\\Icons\\Spell_Shadow_MindSteal", type = "Magic",
            caster = "上古熔火恶犬", 
            effect = "困惑",
            note = "无" 
        },
        {
            name = "末日降临", icon = "Interface\\Icons\\Spell_Shadow_NightOfTheDead", type = "Magic",
            caster = "鲁西弗隆", 
            effect = "10秒后受到2000点暗影伤害",
            note = "无" 
        },
        {
            name = "统御意志", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate", type = "Magic",
            caster = "鲁西弗隆", 
            effect = "被魅惑",
            note = "无法被驱散" 
        },
        {
            name = "恐慌", icon = "Interface\\Icons\\Spell_Shadow_DeathScream", type = "Magic",
            caster = "玛格曼达", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "野火", icon = "Interface\\Icons\\Spell_Fire_SealOfFire", type = "Magic",
            caster = "暗炉织焰者", 
            effect = "每3秒450点火焰伤害",
            note = "造成伤害时有概率扩散到10码内附近的1名队友" 
        },
        {
            name = "暗言术：痛", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain", type = "Magic",
            caster = "暗炉圣职者、火妖祭司", 
            effect = "[暗炉圣职者]每3秒250点暗影伤害\n\n[火妖祭司]每3秒受到一次暗影伤害",
            note = "无" 
        },
        {
            name = "献祭", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "火誓者、火妖祭司", 
            effect = "每3秒380到420点火焰伤害",
            note = "无" 
        },
        {
            name = "熔岩镣铐", icon = "Interface\\Icons\\Spell_Nature_EarthBind", type = "Magic",
            caster = "加尔", 
            effect = "移动速度降低60%",
            note = "无" 
        },
        {
            name = "点燃法力", icon = "Interface\\Icons\\Spell_Fire_Incinerate", type = "Magic",
            caster = "迦顿男爵", 
            effect = "每3秒燃烧400点法力值",
            note = "无" 
        },
        {
            name = "煽动烈焰", icon = "Interface\\Icons\\Spell_Fire_FlameBlades", type = "Magic",
            caster = "火焰行者", 
            effect = "火焰抗性降低50点",
            note = "无" 
        },
    },
    
    ["黑翼之巢"] = {
        {
            name = "减速术", icon = "Interface\\Icons\\Spell_Nature_Slow", type = "Magic",
            caster = "黑翼控制者", 
            effect = "使敌人的攻击间隔延长54%、移动速度降低60%",
            note = "无" 
        },
        {
            name = "毒药瓶", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "黑翼技师", 
            effect = "每3秒造成180点自然伤害",
            note = "无" 
        },
        {
            name = "爆裂印记", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", type = "Magic",
            caster = "死爪龙人队长", 
            effect = "在被击中时对自己和盟友造成657到843点伤害",
            note = "无" 
        },
        {
            name = "强效变形术", icon = "Interface\\Icons\\Spell_Nature_Brilliance", type = "Magic",
            caster = "黑翼缚法者", 
            effect = "不能攻击或施法、生命值回复速度提高",
            note = "无" 
        },
        {
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "暴怒的恶魔守卫", 
            effect = "攻击间隔延长33%、移动速度降低60%",
            note = "无" 
        },
        {
            name = "龙血之痛：红", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", type = "Disease",
            caster = "克洛玛古斯", 
            effect = "每3秒造成50点伤害、死亡后为克洛玛古斯恢复生命值",
            note = "无" 
        },
        {
            name = "龙血之痛：蓝", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Blue", type = "Magic",
            caster = "克洛玛古斯", 
            effect = "每1秒燃烧50点法力值、施法速度降低50%、移动速度降低30%",
            note = "无" 
        },
        {
            name = "龙血之痛：绿", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Green", type = "Poison",
            caster = "克洛玛古斯", 
            effect = "每5秒造成250点伤害、治疗效果降低50%",
            note = "无" 
        },
        {
            name = "恐惧术", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "维克多·奈法里奥斯领主", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "沉默", icon = "Interface\\Icons\\Spell_Holy_Silence", type = "Magic",
            caster = "维克多·奈法里奥斯领主", 
            effect = "不能施法",
            note = "无" 
        }
    },

    ["翡翠圣殿"] = {
        {
            name = "梦境", icon = "Interface\\Icons\\Spell_Nature_Sleep", type = "Magic",
            caster = "圣所梦游者", 
            effect = "睡着了",
            note = "无" 
        },
        {
            name = "毒箭之雨", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "圣所巨龙、埃伦纽斯", 
            effect = "每2秒受到一次自然伤害",
            note = "无" 
        },
        {
            name = "龙族毒液", icon = "Interface\\Icons\\Ability_Creature_Poison_03", type = "Poison",
            caster = "圣所龙族", 
            effect = "攻击间隔增加25%、移动速度降低30%",
            note = "无" 
        },
        {
            name = "翡翠镇压", icon = "Interface\\Icons\\Spell_Nature_MagicImmunity", type = "Magic",
            caster = "圣所压制者", 
            effect = "12秒内损失5856到5868点法力值",
            note = "无" 
        },
        {
            name = "埃伦纽斯的哀嚎", icon = "Interface\\Icons\\Spell_Shadow_ShadeTrueSight", type = "Magic",
            caster = "埃伦纽斯", 
            effect = "睡眠",
            note = "无" 
        }, 
        {
            name = "腐蚀箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "索尔纽斯", 
            effect = "每3秒造成一次自然伤害",
            note = "无" 
        },     
        {
            name = "翡翠松懈", icon = "Interface\\Icons\\Spell_Nature_Purge", type = "Magic",
            caster = "索尔纽斯", 
            effect = "容易受到自然力量的影响、自然法术造成的伤害最多增加200",
            note = "无" 
        },
        {
            name = "翡翠腐烂", icon = "Interface\\Icons\\Spell_Nature_NatureTouchDecay", type = "Disease",
            caster = "索尔纽斯", 
            effect = "攻击间隔增加80%、施法速度降低80%",
            note = "驱散后获得不可驱散、持续时间为2分钟的<翡翠腐烂>效果(攻击间隔增加50%、施法速度降低50%)" 
        },
        {
            name = "圣心腐朽", icon = "Interface\\Icons\\Spell_Shadow_MindRot", type = "Disease",
            caster = "索尔纽斯", 
            effect = "每2秒损失135点法力值",
            note = "驱散后获得不可驱散、持续时间为30秒的<梦热>效果(施法速度降低75%)" 
        },
        {
            name = "梦热", icon = "Interface\\Icons\\Ability_Creature_Disease_03", type = "Poison",
            caster = "索尔纽斯", 
            effect = "攻击速度降低60%",
            note = "驱散后获得不可驱散、持续时间为10秒<狂热的梦>效果(睡着了)" 
        }
    },

    ["安其拉神殿"] = {
        {
            name = "毒箭之雨", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "维希度斯", 
            effect = "每2秒受到413到587点自然伤害",
            note = "无" 
        },
        {
            name = "致残毒药", icon = "Interface\\Icons\\Ability_PoisonSting", type = "Poison",
            caster = "维克尼斯爬行者", 
            effect = "移动速度降低50%",
            note = "无" 
        },
        {
            name = "麻痹毒药", icon = "Interface\\Icons\\Spell_Nature_NullifyDisease", type = "Poison",
            caster = "维克尼斯爬行者", 
            effect = "施法速度降低50%",
            note = "无" 
        },
        {
            name = "毒云之箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "维克尼斯爬行者", 
            effect = "每1秒造成500点自然伤害",
            note = "无" 
        },
        {
            name = "维克尼斯催化", icon = "Interface\\Icons\\Ability_Creature_Poison_02", type = "Poison",
            caster = "维克尼斯黄蜂", 
            effect = "移动速度降低50%、每2秒286点伤害、被维克尼钉刺攻击时承受更多伤害",
            note = "无" 
        },
        {
            name = "翼龙钉刺", icon = "Interface\\Icons\\INV_Spear_02", type = "Poison",
            caster = "哈霍兰公主", 
            effect = "沉睡",
            note = "被驱散后被驱散者受到大量自然伤害" 
        }
    },

    ["木喉要塞"] = {
        {
            name = "毒蛇钉刺", icon = "Interface\\Icons\\Ability_Hunter_Quickshot", type = "Poison",
            caster = "枯喉追踪者", 
            effect = "每3秒111点自然伤害",
            note = "无" 
        },
        {
            name = "毒根之毒", icon = "Interface\\Icons\\INV_Misc_Herb_16", type = "Poison",
            caster = "枯喉探路者", 
            effect = "受到伤害提高200%",
            note = "无" 
        },
        {
            name = "腐蚀之种", icon = "Interface\\Icons\\ability_warlock_shadowflame", type = "Magic",
            caster = "哨兵卡什", 
            effect = "造成伤害提高100%",
            note = "移除(8秒消失后或被驱散)时对附近的友军造成伤害，伤害的大小取决于期间玩家造成的伤害" 
        },
        {
            name = "腐蚀毒药", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "被污染的胶团", 
            effect = "每5秒受到657到843点自然伤害、护甲值降低5000点",
            note = "无" 
        },
        {
            name = "桀骜之炎", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "腐嚎", 
            effect = "每1秒200点火焰伤害",
            note = "腐嚎的火焰箭根据人数均摊伤害，被命中的目标获得<桀骜之炎>效果" 
        },
        {
            name = "麻痹之毒", icon = "Interface\\Icons\\Ability_PoisonSting", type = "Poison",
            caster = "落潭的腐根", 
            effect = "昏迷、持续8秒",
            note = "无" 
        },
        {
            name = "恶液烂芽", icon = "Interface\\Icons\\Spell_Shadow_CallofBone", type = "Disease",
            caster = "落潭的腐根", 
            effect = "移动速度降低15%、受到伤害提高100%",
            note = "无" 
        },
        {
            name = "黑脓疮", icon = "Interface\\Icons\\Spell_Shadow_CreepingPlague", type = "Disease",
            caster = "落潭的腐根", 
            effect = "皮肤上布满黑色肿胀的疖子、并滋生霉菌",
            note = "10秒持续时间结束时受到18500点伤害" 
        },
        {
            name = "恶心污泥", icon = "Interface\\Icons\\Ability_Creature_Poison_06", type = "Poison",
            caster = "腐化的脂滴", 
            effect = "每1秒造成50点自然伤害",
            note = "该效果会叠加层数" 
        },
        {
            name = "毒藤", icon = "Interface\\Icons\\Spell_Nature_StrangleVines", type = "Disease",
            caster = "落潭", 
            effect = "受到物理伤害提高500、且每3秒造成1000点自然伤害",
            note = "无" 
        },
        {
            name = "清醒梦魇", icon = "Interface\\Icons\\Spell_Nature_Sleep", type = "Magic",
            caster = "大德鲁伊科罗恩", 
            effect = "无法进行任何行动、周期性地受到500点暗影伤害",
            note = "被驱散时在梦境中生成1个萨维亚幻象" 
        },
        {
            name = "狂热梦境", icon = "Interface\\Icons\\Spell_Shadow_PlagueCloud", type = "Disease",
            caster = "萨维亚幻象", 
            effect = "造成的伤害降低50%、每6秒受到1000点伤害",
            note = "被驱散时会扩散到附近目标" 
        },
        {
            name = "黑暗虹吸", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", type = "Magic",
            caster = "大酋长帕萨斯", 
            effect = "效果结束后从目标身上吸取3000点生命值",
            note = "被驱散时伤害由驱散者和被驱散者均摊、各受到1500点暗影伤害" 
        },
        {
            name = "石化", icon = "Interface\\Icons\\Ability_Druid_Cower", type = "Magic",
            caster = "枯喉巨熊怪", 
            effect = "攻击速度降低50%、移动速度降低50%",
            note = "无" 
        },
        {
            name = "腐心虹吸", icon = "Interface\\Icons\\Spell_Shadow_Haunting", type = "Magic",
            caster = "腐心诡术师", 
            effect = "每1秒损失600点生命值和1200点法力值",
            note = "无" 
        },
        {
            name = "腐蚀术", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", type = "Magic",
            caster = "塞雷纳克斯·腐心", 
            effect = "每3秒600到800点暗影伤害",
            note = "BOSS会给当前目标施加<萨特污秽>效果(提高受到的暗影伤害)" 
        }
    },


    ["纳克萨玛斯"] = {
        {
            name = "雷霆一击", icon = "Interface\\Icons\\Spell_Nature_ThunderClap", type = "Magic",
            caster = "骷髅铁匠", 
            effect = "攻击间隔延长100%、移动速度降低60%",
            note = "无" 
        },
        {
            name = "冰霜新星", icon = "Interface\\Icons\\Spell_Frost_FrostNova", type = "Magic",
            caster = "邪恶法杖、死灵骑士、死灵骑士卫兵", 
            effect = "[邪恶法杖/死灵骑士]不能移动\n\n[死灵骑士卫兵]被定身",
            note = "无" 
        },
        {
            name = "变形术", icon = "Interface\\Icons\\Spell_Nature_Polymorph", type = "Magic",
            caster = "邪恶法杖", 
            effect = "不能攻击或施法、生命值回复速度提高",
            note = "无" 
        },
        {
            name = "吸取生命", icon = "Interface\\Icons\\Spell_Shadow_LifeDrain02", type = "Magic",
            caster = "鬼灵骑兵", 
            effect = "在5秒吸收总计4000点生命值",
            note = "无" 
        },
        {
            name = "恐惧", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "鬼灵训练师", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "寒冷之锥", icon = "Interface\\Icons\\Spell_Frost_Glacier", type = "Magic",
            caster = "死灵骑士卫兵", 
            effect = "移动速度降低",
            note = "无" 
        },
        {
            name = "残废术", icon = "Interface\\Icons\\Spell_Shadow_Cripple", type = "Magic",
            caster = "瘟疫使者诺斯", 
            effect = "攻击间隔延长100%、移动速度降低50%、力量降低50%",
            note = "无" 
        },
        {
            name = "腐烂撕咬", icon = "Interface\\Icons\\Ability_Creature_Disease_03", type = "Disease",
            caster = "疫病蝙蝠", 
            effect = "受到攻击时承受的伤害提高120点",
            note = "无" 
        },
        {
            name = "衰弱瘟疫", icon = "Interface\\Icons\\Ability_Creature_Disease_03", type = "Disease",
            caster = "肮脏的希尔盖", 
            effect = "生命值上限降低50%、每3秒造成500点自然伤害",
            note = "无" 
        },
        {
            name = "毒性光环", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "洛欧塞布", 
            effect = "每6秒受到196点自然伤害",
            note = "驱散后会获得<堕落心灵>效果(无法治疗，持续1分钟)" 
        },
        {
            name = "毒性充能", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "死灵捕猎者", 
            effect = "每3秒造成2500点自然伤害",
            note = "无" 
        },
        {
            name = "毒箭之雨", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "黑女巫法琳娜", 
            effect = "每2秒造成417到483点自然伤害",
            note = "无" 
        },
        {
            name = "死灵之毒", icon = "Interface\\Icons\\Ability_Creature_Poison_03", type = "Poison",
            caster = "迈克斯纳", 
            effect = "治疗效果降低90%",
            note = "无" 
        },
        {
            name = "软泥之箭", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "缝合喷吐者", 
            effect = "每5秒造成一次自然伤害",
            note = "无" 
        },
        {
            name = "变异注射", icon = "Interface\\Icons\\Spell_Shadow_CallofBone", type = "Disease",
            caster = "格罗布鲁斯", 
            effect = "你被注射了变异毒素",
            note = "移除(10秒持续时间结束或被驱散)时在原地留下一个逐渐扩散的毒圈" 
        },
        {
            name = "群体寒冰箭", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02", type = "Magic",
            caster = "克尔苏加德", 
            effect = "移动速度降低",
            note = "无" 
        }
    },

    ["卡拉赞之塔"] = {
        {
            name = "幻影尖叫", icon = "Interface\\Icons\\Spell_Shadow_PsychicScream", type = "Magic",
            caster = "幽灵工人", 
            effect = "无法施展法术",
            note = "无" 
        },
        {
            name = "吸血毒药", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "暮牙爬行者", 
            effect = "在15秒造成7500点伤害、在15秒内损失7500点法力值",
            note = "无" 
        },
        {
            name = "侵蚀毒药", icon = "Interface\\Icons\\Spell_Nature_CorrosiveBreath", type = "Poison",
            caster = "暮牙爬行者", 
            effect = "在4秒后造成13000伤害",
            note = "无" 
        },
        {
            name = "魔鳞冰箭", icon = "Interface\\Icons\\Spell_Nature_Slow", type = "Magic",
            caster = "魔鳞织法者、魔鳞幼龙、魔鳞魔网搜寻者", 
            effect = "攻击间隔增加50%、移动速度降低50%、施法速度降低50%",
            note = "无" 
        },
        {
            name = "法力箭", icon = "Interface\\Icons\\Spell_Shadow_SiphonMana", type = "Magic",
            caster = "魔鳞织法者、魔鳞幼龙", 
            effect = "抗性降低、受到法术伤害提高",
            note = "无" 
        },
        {
            name = "寒霜气息", icon = "Interface\\Icons\\Spell_Frost_FrostShock", type = "Magic",
            caster = "魔鳞巨龙", 
            effect = "被冻结",
            note = "无" 
        },
        {
            name = "巨龙怒吼", icon = "Interface\\Icons\\Ability_Devour", type = "Magic",
            caster = "魔鳞巨龙", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "祈求沉默", icon = "Interface\\Icons\\Spell_Holy_Silence", type = "Magic",
            caster = "魔鳞抑法者", 
            effect = "沉默",
            note = "无" 
        },
        {
            name = "因塔苟斯的凝视", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "魔网观察者因塔苟斯", 
            effect = "恐惧",
            note = "无" 
        },
        {
            name = "不稳定的法力", icon = "Interface\\Icons\\Spell_Shadow_Teleport", type = "Magic",
            caster = "魔鳞抑法者", 
            effect = "每1秒抽取600点法力值并造成599点伤害",
            note = "被驱散时被驱散者及其小队受到8000点伤害" 
        },
        {
            name = "奥术压力", icon = "Interface\\Icons\\Spell_Frost_IceShock", type = "Magic",
            caster = "溢出的法力", 
            effect = "移动速度降低80%、攻击速度降低80%",
            note = "无" 
        },
        {
            name = "魔力积聚", icon = "Interface\\Icons\\Spell_Nature_Lightning", type = "Magic",
            caster = "破碎的奥术元素", 
            effect = "奥术能量正在积聚...",
            note = "7秒持续时间结束时所在小队受到大量伤害" 
        },
        {
            name = "奥术监牢", icon = "Interface\\Icons\\INV_Misc_Gem_Amethyst_02", type = "Magic",
            caster = "阿诺玛鲁斯", 
            effect = "昏迷，每秒造成1200点伤害并消耗500法力值，持续10秒",
            note = "无" 
        },
        {
            name = "奥术超载", icon = "Interface\\Icons\\Spell_Nature_WispSplode", type = "Magic",
            caster = "阿诺玛鲁斯", 
            effect = "治疗效果提高100%、造成伤害提高100%、移动速度提高100%、造成的威胁值降低100%",
            note = "无法被驱散，15秒持续时间结束时对周围的目标造成伤害、并获得不可驱散且持续时间为45秒的<奥术抑制>效果(受到奥术伤害降低90%、受到物理伤害提高900%)" 
        },
        {
            name = "挥之不去的变羊术", icon = "Interface\\Icons\\Spell_Nature_Polymorph", type = "Magic",
            caster = "徘徊的魔法师", 
            effect = "变成绵羊、在30秒内造成15000伤害",
            note = "无" 
        },
        {
            name = "烈焰笼罩", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "徘徊的魔术师", 
            effect = "沉默，移动时对周围的目标造成7000点火焰伤害",
            note = "无" 
        },
        {
            name = "冰霜新星", icon = "Interface\\Icons\\Spell_Frost_FrostNova", type = "Magic",
            caster = "麦迪文的回响", 
            effect = "被冻结在原地",
            note = "无" 
        },
        {
            name = "奥术集中", icon = "Interface\\Icons\\Spell_Holy_FlashHeal", type = "Magic",
            caster = "麦迪文的回响", 
            effect = "受到的魔法伤害增加40%",
            note = "无" 
        },
        {
            name = "麦迪文的灾祸", icon = "Interface\\Icons\\Spell_Nature_Drowsy", type = "Magic",
            caster = "麦迪文的回响", 
            effect = "一股深深的恐惧充斥着你的内心……",
            note = "被驱散时驱散者受到1540点暗影伤害并生成1个徘徊的末日、5层时对周围的目标造成大量暗影伤害" 
        },
        {
            name = "恐惧", icon = "Interface\\Icons\\Spell_Shadow_Possession", type = "Magic",
            caster = "干枯的主教", 
            effect = "因恐惧而逃跑",
            note = "无" 
        },
        {
            name = "幽冥放逐", icon = "Interface\\Icons\\Spell_Shadow_Cripple", type = "Magic",
            caster = "桑夫·塔斯达尔", 
            effect = "无法移动",
            note = "无法被驱散" 
        },
        {
            name = "裂隙纠缠", icon = "Interface\\Icons\\spell_nature_astralrecalgroup", type = "Magic",
            caster = "桑夫·塔斯达尔", 
            effect = "受到所有伤害增加200%、造成暗影伤害增加100%",
            note = "无" 
        },
        {
            name = "相位转换", icon = "Interface\\Icons\\Spell_Shadow_AbominationExplosion", type = "Magic",
            caster = "桑夫·塔斯达尔", 
            effect = "每1秒造成240点暗影伤害、可以看到德莱尼虚无行者",
            note = "无" 
        },
        {
            name = "燃烧血肉", icon = "Interface\\Icons\\Spell_Fire_Immolation", type = "Magic",
            caster = "鲁普图兰的碎块", 
            effect = "每2秒造成2200点火焰伤害",
            note = "无" 
        },
        {
            name = "火焰之雨", icon = "Interface\\Icons\\spell_Holy_SearingLight", type = "Magic",
            caster = "末日守卫歼灭者", 
            effect = "每1秒对你附近10码内的所有玩家造成1400点伤害",
            note = "无" 
        },
        {
            name = "恐惧魔王的嚎叫", icon = "Interface\\Icons\\spell_shadow_deathcoil", type = "Magic",
            caster = "墨菲斯托斯", 
            effect = "惊恐地逃跑",
            note = "无" 
        },
        {
            name = "吸血鬼光环", icon = "Interface\\Icons\\SPELL_SHADOW_VAMPIRICAURA", type = "Magic",
            caster = "墨菲斯托斯", 
            effect = "每1秒消耗300点生命值",
            note = "无法被驱散，此效果为首领的光环效果，可被萨满驱散\n[感谢|cffF58CBA逐日光辉|r提供机制解读]" 
        },
        {
            name = "腐臭虫群", icon = "Interface\\Icons\\Spell_Shadow_Contagion", type = "Disease",
            caster = "墨菲斯托斯", 
            effect = "治疗效果降低25%、每1秒造成350点自然伤害",
            note = "无" 
        },
        {
            name = "沉睡麻痹", icon = "Interface\\Icons\\spell_holy_prayerofshadowprotection", type = "Magic",
            caster = "墨菲斯托斯", 
            effect = "噩梦正在袭来",
            note = "无法移动并且场地中央生成1颗眼球缓慢靠近，被驱散或眼球碰到玩家时眼球周围的目标受到5000点暗影伤害" 
        }
    },

}

-- ==========================================
-- 分割线与下拉菜单调整
-- ==========================================
local topDivider = XinRaidFrame:CreateTexture(nil, "ARTWORK")
topDivider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
topDivider:SetWidth(630)
topDivider:SetHeight(1)
topDivider:SetPoint("TOP", XinRaidFrame, "TOP", 0, -75)
topDivider:SetVertexColor(0.5, 0.5, 0.5, 0.8)

local XinRaidList = {
    "请选择团本",
    "祖尔格拉布", 
    "卡拉赞下层大厅", 
    "安其拉废墟", 
    "奥妮克希亚的巢穴", 
    "熔火之心", 
    "黑翼之巢", 
    "翡翠圣殿", 
    "安其拉神殿", 
    "木喉要塞", 
    "纳克萨玛斯", 
    "卡拉赞之塔"
}

local raidDropDown = CreateFrame("Frame", "XinRaidDropDown", XinRaidFrame, "UIDropDownMenuTemplate")
raidDropDown:SetPoint("TOP", raidTitle, "BOTTOM", 0, -10)

UIDropDownMenu_Initialize(raidDropDown, function()
    for i, raidName in ipairs(XinRaidList) do
        local info = UIDropDownMenu_CreateInfo() 
        info.text = raidName
        info.value = raidName
        info.func = function()
            UIDropDownMenu_SetSelectedID(raidDropDown, this:GetID())
            UIDropDownMenu_SetText(this.value, raidDropDown)
            -- 选中团本后，刷新左侧列表
            UpdateRaidDebuffList(this.value)
        end
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_SetWidth(130, raidDropDown)
UIDropDownMenu_SetSelectedID(raidDropDown, 1)
UIDropDownMenu_SetText("请选择团本", raidDropDown)

-- ==========================================
-- 左侧：Debuff 技能滚动列表区
-- ==========================================
local XinRaidScrollFrame = CreateFrame("ScrollFrame", "XinRaidScrollFrame", XinRaidFrame, "FauxScrollFrameTemplate")
XinRaidScrollFrame:SetWidth(180)
XinRaidScrollFrame:SetHeight(450) 
XinRaidScrollFrame:SetPoint("TOPLEFT", XinRaidFrame, "TOPLEFT", 15, -90)

local verticalDivider = XinRaidFrame:CreateTexture(nil, "ARTWORK")
verticalDivider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
verticalDivider:SetWidth(1)
verticalDivider:SetHeight(380)
verticalDivider:SetPoint("TOPLEFT", XinRaidFrame, "TOPLEFT", 220, -85)
verticalDivider:SetVertexColor(0.5, 0.5, 0.5, 0.5)

-- ==========================================
-- 预先创建：右侧详情文本展示区 (必须在左侧列表上方)
-- ==========================================
-- 1. 顶部：大图标与技能名
local detailIcon = XinRaidFrame:CreateTexture(nil, "ARTWORK")
detailIcon:SetWidth(42)
detailIcon:SetHeight(42)
detailIcon:SetPoint("TOPLEFT", XinRaidFrame, "TOPLEFT", 240, -90)
detailIcon:Hide() 

local detailName = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
detailName:SetPoint("LEFT", detailIcon, "RIGHT", 15, 0)
detailName:SetJustifyH("LEFT")
detailName:SetTextColor(1, 0.82, 0)

-- 2. 使用者
local detailCasterLabel = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
detailCasterLabel:SetPoint("TOPLEFT", detailIcon, "BOTTOMLEFT", 0, -25)
detailCasterLabel:SetText("使用者：")
detailCasterLabel:Hide()

local detailCasterText = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
detailCasterText:SetPoint("TOPLEFT", detailCasterLabel, "TOPRIGHT", 5, 0)
detailCasterText:SetWidth(320)
detailCasterText:SetJustifyH("LEFT")

-- 3. 效果
local detailEffectLabel = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
detailEffectLabel:SetPoint("TOPLEFT", detailCasterLabel, "BOTTOMLEFT", 0, -20)
detailEffectLabel:SetText("效   果：")
detailEffectLabel:Hide()

local detailEffectText = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
detailEffectText:SetPoint("TOPLEFT", detailEffectLabel, "TOPRIGHT", 5, 0)
detailEffectText:SetWidth(320)
detailEffectText:SetJustifyH("LEFT")

-- 4. 注意事项 
local detailNoteLabel = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

-- 【关键修改】：把“注意事项”改为带有空格的“注   意”，完美匹配“效   果”的宽度
detailNoteLabel:SetText("注   意：") 

detailNoteLabel:Hide()

local detailNoteText = XinRaidFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
detailNoteText:SetWidth(320)
detailNoteText:SetJustifyH("LEFT")
detailNoteText:Hide()


-- ==========================================
-- 左侧：Debuff 技能滚动列表的按钮循环创建
-- ==========================================
local XinRaidRows = {}
for i = 1, 15 do
    local row = CreateFrame("Button", nil, XinRaidFrame)
    row:SetWidth(180)
    row:SetHeight(30)
    row:SetPoint("TOPLEFT", XinRaidFrame, "TOPLEFT", 20, -90 - (i - 1) * 30)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(24)
    row.icon:SetHeight(24)
    row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
    
    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 10, 0)
    row.nameText:SetJustifyH("LEFT")
    
-- 【点击事件】：此时它已经能完全认识上面创建好的 detailIcon 等变量了
    row:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        
        local data = this.debuffData
        if not data then return end
        
        -- 1. 更新图标和名字
        detailIcon:SetTexture(data.icon)
        detailIcon:Show()
        
        local typeCn = (data.type == "Magic" and "魔法") or (data.type == "Poison" and "中毒") or (data.type == "Disease" and "疾病") or "未知"
        detailName:SetText(data.name .. " (" .. typeCn .. ")")
        
        -- 2. 更新使用者
        detailCasterLabel:Show()
        detailCasterText:SetText(data.caster or "未知")
        
        -- 3. 更新效果
        detailEffectLabel:Show()
        detailEffectText:SetText(data.effect or "未知")
        
        -- 4. 动态判定“注意事项”是否显示
        if data.note and data.note ~= "" then
            detailNoteText:ClearAllPoints()
            detailNoteLabel:ClearAllPoints()
            
            -- 【核心排版 1】：让“注意事项文本”严格对齐“效果文本”的正下方
            detailNoteText:SetPoint("TOPLEFT", detailEffectText, "BOTTOMLEFT", 0, -20)
            
            -- 【核心排版 2】：让“金色标签”反向锚定在文本左边。实现所有冒号完美对齐！
            detailNoteLabel:SetPoint("TOPRIGHT", detailNoteText, "TOPLEFT", -5, 0)
            
            detailNoteText:SetText(data.note)
            detailNoteLabel:Show()
            detailNoteText:Show()
        else
            detailNoteLabel:Hide()
            detailNoteText:Hide()
        end

        -- ==========================================
        -- 【第三步新增】：读取当前技能的战术设置并刷新复选框
        -- ==========================================
        XinRaid_CurrentSelectedDebuff = data.name
        
        -- 从笔记本里翻出这个技能的设置（没记过就是空表）
        local settings = xinDB.RaidSettings[data.name] or {}
        
        -- (1). 根据数据刷新“按类型屏蔽”复选框
        -- 【关键修改】：读取数字 1 和 2
        if settings.ignoreType == 1 then
            XinRaidCB_Status:SetChecked(1)
            XinRaidCB_Player:SetChecked(nil)
        elseif settings.ignoreType == 2 then
            XinRaidCB_Status:SetChecked(nil)
            XinRaidCB_Player:SetChecked(1)
        else
            XinRaidCB_Status:SetChecked(nil)
            XinRaidCB_Player:SetChecked(nil)
        end
        
        -- (2). 根据数据刷新“按职业屏蔽” 9 个复选框
        for j = 1, 9 do
            -- 通过之前定义的全局名字 XinRaidCB_Class_1 到 9 来获取控件
            local cb = _G["XinRaidCB_Class_"..j]
            if cb then
                local cName = _G[cb:GetName().."Text"]:GetText()
                if settings.ignoreClasses and settings.ignoreClasses[cName] then
                    cb:SetChecked(1)
                else
                    cb:SetChecked(nil)
                end
            end
        end
        
        -- 【新增】：数据加载完毕，把整个右下角的文件夹显示出来！
        XinRaidSettingsContainer:Show()


    end)
    
    row:Hide()
    XinRaidRows[i] = row
end

local CurrentRaidData = {}

-- ==========================================
-- 【新增】：用于记忆当前选中的副本，防止滑动时误清空
-- ==========================================
local XinRaid_LastSelectedRaidName = nil



function UpdateRaidDebuffList(raidName)
    CurrentRaidData = XinRaidManualDB[raidName] or {}
    local dataCount = table.getn(CurrentRaidData)
    
    -- ==========================================
    -- 【第一步修复】：强制接管滑动条容器的可见性
    -- ==========================================
    if dataCount > 12 then
        XinRaidScrollFrame:Show()
    else
        XinRaidScrollFrame:Hide()
    end

    -- ==========================================
    -- 【核心修复】：判断是不是真正的“切换了副本”
    -- ==========================================
    if XinRaid_LastSelectedRaidName ~= raidName then
        
        -- 只有切换了新副本（或者初次打开），才清空右侧详情
        XinRaid_CurrentSelectedDebuff = nil
        if XinRaidSettingsContainer then XinRaidSettingsContainer:Hide() end
        
        if detailIcon then detailIcon:Hide() end
        if detailName then detailName:SetText("") end
        if detailCasterLabel then detailCasterLabel:Hide() end
        if detailCasterText then detailCasterText:SetText("") end
        if detailEffectLabel then detailEffectLabel:Hide() end
        if detailEffectText then detailEffectText:SetText("") end
        if detailNoteLabel then detailNoteLabel:Hide() end
        if detailNoteText then detailNoteText:Hide() end
        
        -- 记录下当前选中的副本名，上锁！
        XinRaid_LastSelectedRaidName = raidName
    end


    -- 【关键修复 1】：把这里的 12 改成 15。告诉引擎一屏能显示 15 个，不够 15 个就自动隐藏滑动条！
    FauxScrollFrame_Update(XinRaidScrollFrame, dataCount, 15, 30)
    local offset = FauxScrollFrame_GetOffset(XinRaidScrollFrame)
    
    -- 【关键修复 2】：循环次数也要改成 15
    for i = 1, 15 do
        local dataIndex = offset + i
        local row = XinRaidRows[i]
        
        if row then -- 加个小安全判定
            if dataIndex <= dataCount then
                local data = CurrentRaidData[dataIndex]
                
                row.icon:SetTexture(data.icon)
                
                local typeCn = (data.type == "Magic" and "魔法") or (data.type == "Poison" and "中毒") or (data.type == "Disease" and "疾病") or "未知"
                row.nameText:SetText(data.name .. "(" .. typeCn .. ")")
                row.nameText:SetTextColor(1, 0.82, 0)
                
                row.debuffName = data.name
                row.debuffData = data 
                row:Show()
            else
                row:Hide()
            end
        end
    end
end

XinRaidScrollFrame:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(30, function() UpdateRaidDebuffList(UIDropDownMenu_GetText(raidDropDown)) end)
end)
UpdateRaidDebuffList("请选择团本")

-- ==========================================
-- 右下角：战术设置区 (UI构建与数据写入)
-- ==========================================
-- 【新增】：创建一个透明的“文件夹”容器，并默认合上（隐藏）
local XinRaidSettingsContainer = CreateFrame("Frame", "XinRaidSettingsContainer", XinRaidFrame)
XinRaidSettingsContainer:SetAllPoints(XinRaidFrame)
XinRaidSettingsContainer:Hide() -- 初始隐藏

-- 1. 按类型屏蔽
local filterTypeLabel = XinRaidSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterTypeLabel:SetPoint("TOPLEFT", XinRaidFrame, "TOPLEFT", 240, -360)
filterTypeLabel:SetText("按类型屏蔽：")
filterTypeLabel:SetTextColor(1, 0.8, 0) 

local cbStatus = CreateFrame("CheckButton", "XinRaidCB_Status", XinRaidSettingsContainer, "UICheckButtonTemplate")
cbStatus:SetWidth(26)
cbStatus:SetHeight(26)
cbStatus:SetPoint("LEFT", filterTypeLabel, "RIGHT", 10, 0)
_G[cbStatus:GetName().."Text"]:SetText("单一屏蔽")
_G[cbStatus:GetName().."Text"]:SetTextColor(1, 1, 1)

local cbPlayer = CreateFrame("CheckButton", "XinRaidCB_Player", XinRaidSettingsContainer, "UICheckButtonTemplate")
cbPlayer:SetWidth(26)
cbPlayer:SetHeight(26)
cbPlayer:SetPoint("LEFT", cbStatus, "RIGHT", 90, 0)
_G[cbPlayer:GetName().."Text"]:SetText("完全屏蔽")
_G[cbPlayer:GetName().."Text"]:SetTextColor(1, 1, 1)

-- 互斥与写入逻辑 (按类型)
cbStatus:SetScript("OnClick", function()
    if not XinRaid_CurrentSelectedDebuff then this:SetChecked(nil); return end
    
    xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff] = xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff] or {}
    
    if this:GetChecked() then
        cbPlayer:SetChecked(nil)
        -- 【关键修改】：存入数字 1 (单一屏蔽)
        xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreType = 1 
    else
        xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreType = nil
    end
end)

cbPlayer:SetScript("OnClick", function()
    if not XinRaid_CurrentSelectedDebuff then this:SetChecked(nil); return end
    
    xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff] = xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff] or {}
    
    if this:GetChecked() then
        cbStatus:SetChecked(nil)
        -- 【关键修改】：存入数字 2 (完全屏蔽)
        xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreType = 2 
    else
        xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreType = nil
    end
end)

-- 2. 按职业屏蔽
local filterClassLabel = XinRaidSettingsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
filterClassLabel:SetPoint("TOPLEFT", XinRaidFrame, "TOPLEFT", 240, -400) 
filterClassLabel:SetText("按职业屏蔽：")
filterClassLabel:SetTextColor(1, 0.8, 0) 

local classList = {"战士", "盗贼", "牧师", "小德", "骑士", "猎人", "法师", "术士", "萨满"}
local classCBs = {} 

for i, className in ipairs(classList) do
    local cb = CreateFrame("CheckButton", "XinRaidCB_Class_"..i, XinRaidSettingsContainer, "UICheckButtonTemplate")
    cb:SetWidth(26)
    cb:SetHeight(26)
    
    _G[cb:GetName().."Text"]:SetText(className)
    _G[cb:GetName().."Text"]:SetTextColor(1, 1, 1)

    if i == 1 then
        cb:SetPoint("LEFT", filterClassLabel, "RIGHT", 10, 0)
    elseif i == 5 then
        cb:SetPoint("TOPLEFT", classCBs[1], "BOTTOMLEFT", 0, -8)
    else
        cb:SetPoint("LEFT", classCBs[i-1], "RIGHT", 35, 0)
    end
    
    -- 写入逻辑 (按职业)
    cb:SetScript("OnClick", function()
        if not XinRaid_CurrentSelectedDebuff then this:SetChecked(nil); return end
        
        xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff] = xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff] or {}
        if not xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreClasses then
            xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreClasses = {}
        end
        
        local cName = _G[this:GetName().."Text"]:GetText()
        if this:GetChecked() then
            xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreClasses[cName] = true
        else
            xinDB.RaidSettings[XinRaid_CurrentSelectedDebuff].ignoreClasses[cName] = nil
        end
    end)
    
    classCBs[i] = cb
end



    --作者
    local ShowAuthor = 1
    if ShowAuthor == 1 then
        local AuthorText = XinSettingFrame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
        AuthorText:SetPoint("CENTER", XinSettingFrame, "BOTTOM", 0, 30)
        AuthorText:SetText("作者: 何雨欣    版本: 1.1\n全职业驱散 / 滚轮列表")
    end




-- Keep the original settings command; add short aliases and diagnostics.
local XinOriginalSlash = SlashCmdList["XINLOAD"]
SLASH_XINLOAD2 = "/xin"
SLASH_XINLOAD3 = "/hyx"
SlashCmdList["XINLOAD"] = function(msg)
    if msg == "status" then XinDispel.Status()
    elseif msg == "top" then
        XinMainFrame_InRange.offset = 0
        XinMainFrame_OutRange.offset = 0
        UpdateXinList()
    else XinOriginalSlash(msg) end
end
