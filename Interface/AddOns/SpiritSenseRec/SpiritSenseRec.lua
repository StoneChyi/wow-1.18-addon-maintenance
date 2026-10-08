-- 插件主体
SpiritSenseRec = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0")
-- 灵应录数据存储
SpiritSenseRecData = {}
-- 已发送消息记录
SpiritSenseRec.sentMessages = {}

-- 创建用于显示信息的框架和字体字符串
local infoFrame = CreateFrame("Frame", "SpiritSenseRecFrame", UIParent)
infoFrame:SetWidth(1000)
infoFrame:SetHeight(200)
infoFrame:SetPoint("CENTER", 0, 350)
infoFrame:SetMovable(true)


local infoText = infoFrame:CreateFontString(nil, "OVERLAY")
infoText:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
infoText:SetWidth(1000)
infoText:SetPoint("CENTER", 0, 0)
infoText:Hide()

-- 隐藏信息显示框
local function hideInfo()
    infoText:Hide()
    infoFrame:EnableMouse(false)
end

-- 显示信息并设置自动隐藏
local function showInfo(msg)
    infoText:SetText(msg)
    infoText:Show()
    infoFrame:EnableMouse(true)
    C_Timer.After(10, hideInfo)
end

-- 插件初始化函数
function SpiritSenseRec:OnInitialize()
    self.RosterLib = AceLibrary("RosterLib-2.0")
    
    -- 检查并转换数据格式
    if type(SpiritSenseRecData) == "table" then
        local needConvert = false
        for k, v in pairs(SpiritSenseRecData) do
            if type(k) == "number" and type(v) == "table" and v.name and v.impression then
                needConvert = true
                break
            end
        end
        
        if needConvert then
            local newData = {}
            for _, v in pairs(SpiritSenseRecData) do
                if type(v) == "table" and v.name and v.impression then
                    newData[v.name] = v.impression
                end
            end
            SpiritSenseRecData = newData
            DEFAULT_CHAT_FRAME:AddMessage("灵应录：旧数据格式已更新")
        end
    end
end

-- 插件启用函数
function SpiritSenseRec:OnEnable()
    self.ssr = SpiritSenseRecData
    -- 初始化时记录当前团队和队伍成员数量
    self.currentRaidMembers = GetNumRaidMembers()
    self.currentPartyMembers = GetNumPartyMembers()

    -- 仅注册队伍和团队成员变化事件
    self:RegisterEvent("PARTY_MEMBERS_CHANGED", "HandlePartyRaidChange")
    self:RegisterEvent("RAID_ROSTER_UPDATE", "HandlePartyRaidChange")
    -- 注册 PLAYER_ENTERING_WORLD 事件
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")

    -- 注册命令处理函数
    self:RegisterCommands()
end

-- 处理队伍和团队成员变化
function SpiritSenseRec:HandlePartyRaidChange()
    local newRaidMembers = GetNumRaidMembers()
    local newPartyMembers = GetNumPartyMembers()

    -- 检查是否有新成员加入
    if newRaidMembers > self.currentRaidMembers or 
       (newRaidMembers == 0 and newPartyMembers > self.currentPartyMembers) then
        self:CheckRecOnRosterChange()
    end

    -- 更新当前成员数量
    self.currentRaidMembers = newRaidMembers
    self.currentPartyMembers = newPartyMembers
end

-- 注册命令处理函数
function SpiritSenseRec:RegisterCommands()
    SLASH_RADD1 = "/radd"
    SlashCmdList.RADD = function(content, editbox)
        local name, impression = self:ParseAddCommand(content)
        if not name or not impression then
            return
        end

        local actionMsg = self:AddOrUpdateRecord(name, impression)
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：" .. actionMsg .. name .. " 的信息，印象: " .. impression)
    end

    SLASH_RDEL1 = "/rdel"
    SlashCmdList.RDEL = function(name, editbox)
        local removed = self:RemoveRecord(name)
        if removed then
            DEFAULT_CHAT_FRAME:AddMessage("灵应录：抹去 " .. removed.name)
        else
            DEFAULT_CHAT_FRAME:AddMessage("灵应录：记录中查无此人 " .. name)
        end
    end

    -- 修改 RSHOW 命令的显示逻辑
    SLASH_RSHOW1 = "/rshow"
    SlashCmdList.RSHOW = function(name, editbox)
        local count = 0
        for _ in pairs(SpiritSenseRec.ssr) do
            count = count + 1
        end
        
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("灵应录：空空如也")
            return
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：已记录 " .. count .. " 人")
        for name, impression in pairs(SpiritSenseRec.ssr) do
            DEFAULT_CHAT_FRAME:AddMessage("名称: " .. name .. ", 印象: " .. impression)
        end
    end

    SLASH_RCLEAN1 = "/rclean"
    SlashCmdList.RCLEAN = function(name, editbox)
        wipe(SpiritSenseRecData)
        wipe(SpiritSenseRec.sentMessages)
        self.ssr = SpiritSenseRecData
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：已清空")
    end
end

-- 解析 /radd 命令参数
function SpiritSenseRec:ParseAddCommand(content)
    if not content or content == "" then
        -- 打印命令说明
        DEFAULT_CHAT_FRAME:AddMessage("灵应录 - 使用说明：")
        DEFAULT_CHAT_FRAME:AddMessage("/rgui - 一个简单的小窗口，把以下命令做成了按钮")
        DEFAULT_CHAT_FRAME:AddMessage("/radd <玩家名称> <印象> - 将玩家记录到灵应录")
        DEFAULT_CHAT_FRAME:AddMessage("/rdel <玩家名称> - 将玩家从灵应录抹除")
        DEFAULT_CHAT_FRAME:AddMessage("/rshow - 展示灵应录所有内容")
        DEFAULT_CHAT_FRAME:AddMessage("/rclean - 清空灵应录")
        DEFAULT_CHAT_FRAME:AddMessage("注意1：印象如果包含感叹号（不区分中英文），会在感应到玩家时将警告信息发布到队伍或团队频道。否则只在自己屏幕中央进行提醒")
        DEFAULT_CHAT_FRAME:AddMessage("注意2：配置文件（名单）存储在WTF\\Account\\你的账号\\SavedVariables\\SpiritSenseRec.lua")
        return nil, nil
    end

    local args = { strsplit(" ", content) }
    if table.getn(args) < 2 then
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：输入格式有误，请重新输入。格式：/radd <玩家名称> <印象>")
        return nil, nil
    end

    local name = args[1]
    local impression = table.concat(args, " ", 2)
    if impression == "" then
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：印象不能为空，请重新输入。格式：/radd <玩家名称> <印象>")
        return nil, nil
    end

    return name, impression
end

-- 添加或更新记录
function SpiritSenseRec:AddOrUpdateRecord(name, impression)
    local isNew = not self.ssr[name]
    self.ssr[name] = impression
    return isNew and "记录 " or "覆盖 "
end

-- 移除记录
function SpiritSenseRec:RemoveRecord(name)
    local impression = self.ssr[name]
    if impression then
        self.ssr[name] = nil
        return { name = name, impression = impression }
    else
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：记录中查无此人 " .. name)
        return nil
    end
end

-- 检查单个成员是否在记录中
function SpiritSenseRec:CheckRec(name)
    local impression = self.ssr[name]
    if impression then
        if not self.sentMessages[name] then
            if string.find(impression, "[！!]") then
                local channel = self:GetChatChannel()
                local msg = string.format("灵应录：感应到【%s】，印象：%s", name, impression)
                SendChatMessage(msg, channel)
            end
            self.sentMessages[name] = true
        end

        showInfo(self:FormatCheckMessage(name, impression))
    end
end

-- 格式化检查消息
function SpiritSenseRec:FormatCheckMessage(name, impression)
    local colorYellow = "|cFFFFFF00"
    local colorGreen = "|cFF00FF00"
    local colorWhite = "|cFFFFFFFF"
    local colorReset = "|r"

    return string.format("%s灵应录：感应到【%s%s%s%s】，印象：%s%s%s",
        colorWhite,
        colorGreen, name, colorReset,
        colorWhite,
        colorYellow, impression, colorReset)
end

-- 玩家进入世界时的处理函数
function SpiritSenseRec:OnPlayerEnteringWorld(isInitialLogin, isReloadingUi)
    -- 当玩家进入世界时检查灵应录名单
    self:CheckRecOnRosterChange()
end

-- 检查成员列表变化
function SpiritSenseRec:CheckRecOnRosterChange()
    local numRaidMembers = GetNumRaidMembers()
    local numPartyMembers = GetNumPartyMembers()
    -- 当自己离队时，清空已发送消息记录
    if numRaidMembers == 0 and numPartyMembers == 0 then
        wipe(self.sentMessages)
    end

    local function checkMembers(unitPrefix, numMembers)
        for i = 1, numMembers do
            local unitid = unitPrefix .. i
            if UnitExists(unitid) then
                local name = UnitName(unitid)
                self:CheckRec(name)
            end
        end
    end

    -- 遍历团队成员
    if numRaidMembers > 0 then
        checkMembers("raid", numRaidMembers)
    -- 遍历队伍成员
    elseif numPartyMembers > 0 then
        checkMembers("party", numPartyMembers)
    end
end

-- 获取聊天频道
function SpiritSenseRec:GetChatChannel()
    if GetNumRaidMembers() > 0 then
        return "RAID"
    elseif GetNumPartyMembers() > 0 then
        return "PARTY"
    end
    return "SAY"
end

-- 创建主窗口
local mainFrame = CreateFrame("Frame", "SpiritSenseRecMainFrame", UIParent)
mainFrame:SetWidth(400)
mainFrame:SetHeight(180)
mainFrame:SetPoint("CENTER", 0, 0)
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function() mainFrame:StartMoving() end)
mainFrame:SetScript("OnDragStop", function() mainFrame:StopMovingOrSizing() end)

-- 设置窗口背景
mainFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
})
mainFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
mainFrame:SetBackdropBorderColor(0.5, 0.5, 0.5)

-- 创建标题背景
local titleBg = mainFrame:CreateTexture(nil, "OVERLAY")
titleBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
titleBg:SetPoint("TOPLEFT", 4, -4)
titleBg:SetPoint("TOPRIGHT", -4, -4)
titleBg:SetHeight(24)
titleBg:SetVertexColor(0.2, 0.2, 0.2, 1)

-- 创建标题
local titleText = mainFrame:CreateFontString(nil, "OVERLAY")
titleText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
titleText:SetPoint("TOP", 0, -15)
titleText:SetText("灵应录")

-- 创建关闭按钮
local closeButton = CreateFrame("Button", nil, mainFrame)
closeButton:SetPoint("TOPRIGHT", -8, -8)
closeButton:SetWidth(16)
closeButton:SetHeight(16)

local closeTexture = closeButton:CreateTexture()
closeTexture:SetAllPoints()
closeTexture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")

closeButton:SetScript("OnClick", function() mainFrame:Hide() end)
closeButton:SetScript("OnEnter", function() closeTexture:SetVertexColor(1, 0, 0) end)
closeButton:SetScript("OnLeave", function() closeTexture:SetVertexColor(1, 1, 1) end)

-- 创建输入区域背景
local inputBg = CreateFrame("Frame", nil, mainFrame)
inputBg:SetPoint("TOPLEFT", 12, -40)
inputBg:SetPoint("BOTTOMRIGHT", -12, 40)
inputBg:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
})
inputBg:SetBackdropColor(0.1, 0.1, 0.1, 0.1)
inputBg:SetBackdropBorderColor(0.4, 0.4, 0.4)

-- 创建玩家名称输入框
local nameEditBox = CreateFrame("EditBox", nil, inputBg)
nameEditBox:SetPoint("TOPLEFT", 15, -20)
nameEditBox:SetWidth(150)
nameEditBox:SetHeight(20)
nameEditBox:SetAutoFocus(false)
nameEditBox:SetFont(STANDARD_TEXT_FONT, 12)
nameEditBox:SetTextColor(1, 1, 1)
nameEditBox:SetJustifyH("LEFT")

-- 设置输入框背景
nameEditBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
    edgeFile = "Interface\\Buttons\\WHITE8X8",  -- 添加边框
    edgeSize = 1,                               -- 设置边框宽度为1px
})
nameEditBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)  -- 修改为与主窗口相同的背景色
nameEditBox:SetBackdropBorderColor(0, 0, 0, 1)

local nameLabel = inputBg:CreateFontString(nil, "OVERLAY")
nameLabel:SetFont(STANDARD_TEXT_FONT, 12)
nameLabel:SetPoint("BOTTOMLEFT", nameEditBox, "TOPLEFT", 0, 5)
nameLabel:SetText("玩家名称")

-- 创建印象输入框
local impressionEditBox = CreateFrame("EditBox", nil, inputBg)
impressionEditBox:SetPoint("TOPLEFT", nameEditBox, "TOPRIGHT", 20, 0)
impressionEditBox:SetWidth(180)
impressionEditBox:SetHeight(20)
impressionEditBox:SetAutoFocus(false)
impressionEditBox:SetFont(STANDARD_TEXT_FONT, 12)
impressionEditBox:SetTextColor(1, 1, 1)
impressionEditBox:SetJustifyH("LEFT")

-- 设置印象输入框背景
impressionEditBox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
    edgeFile = "Interface\\Buttons\\WHITE8X8",  -- 添加边框
    edgeSize = 1,                               -- 设置边框宽度为1px
})
impressionEditBox:SetBackdropColor(0.1, 0.1, 0.1, 0.9)  -- 修改为与主窗口相同的背景色
impressionEditBox:SetBackdropBorderColor(0, 0, 0, 1)

local impressionLabel = inputBg:CreateFontString(nil, "OVERLAY")
impressionLabel:SetFont(STANDARD_TEXT_FONT, 12)
impressionLabel:SetPoint("BOTTOMLEFT", impressionEditBox, "TOPLEFT", 0, 5)
impressionLabel:SetText("印象")

-- 创建按钮
local function CreateButton(text, parent, point, relativePoint, x, y, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(80)
    button:SetHeight(22)
    button:SetPoint(point, relativePoint, x, y)
    
    -- 设置按钮背景
    button:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        tileSize = 16,
    })
    button:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    button:SetBackdropBorderColor(0, 0, 0, 1)      -- 设置黑色边框
    
    -- 创建并设置按钮文字
    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 12)
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text)
    label:SetTextColor(1, 0.82, 0) -- 设置文字为黄色
    button.label = label
    
    -- 按钮效果
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function() 
        button:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    end)
    button:SetScript("OnLeave", function()
        button:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    end)
    button:SetScript("OnMouseDown", function()
        label:SetPoint("CENTER", 1, -1)
    end)
    button:SetScript("OnMouseUp", function()
        label:SetPoint("CENTER", 0, 0)
    end)
    
    return button
end

-- 添加按钮
local addButton = CreateButton("添加", mainFrame, "TOPLEFT", nameEditBox, 0, -40, function()
    local name = nameEditBox:GetText()
    local impression = impressionEditBox:GetText()
    if name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：请输入玩家名称")
        return
    end
    if impression ~= "" then
        local actionMsg = SpiritSenseRec:AddOrUpdateRecord(name, impression)
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：" .. actionMsg .. name .. " 的信息，印象: " .. impression)
        nameEditBox:SetText("")
        impressionEditBox:SetText("")
    end
end)

-- 删除按钮
local deleteButton = CreateButton("删除", mainFrame, "LEFT", addButton, 90, 0, function()
    local name = nameEditBox:GetText()
    if name == "" then
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：请输入要删除的玩家名称")
        return
    end
    local removed = SpiritSenseRec:RemoveRecord(name)
    if removed then
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：抹去 " .. removed.name)
        nameEditBox:SetText("")
        impressionEditBox:SetText("")
    end
end)

-- 显示按钮
local showButton = CreateButton("显示", mainFrame, "LEFT", deleteButton, 90, 0, function()
    SlashCmdList.RSHOW()
end)

-- 清空按钮
local cleanButton = CreateButton("清空", mainFrame, "LEFT", showButton, 90, 0, function()
    StaticPopup_Show("SPIRIT_SENSE_REC_CONFIRM_CLEAN")
end)

-- 创建提示文字
local tipText = mainFrame:CreateFontString(nil, "OVERLAY")
tipText:SetFont(STANDARD_TEXT_FONT, 9)
tipText:SetPoint("TOP", addButton, "BOTTOM", 135, -25)
tipText:SetWidth(400) -- 设置宽度以便自动换行
tipText:SetJustifyH("CENTER")
tipText:SetText("|cFFFFD100！印象如果包含感叹号，会在感应到玩家时将警告信息发布到队伍或团队频道！|r")

-- 创建确认清空的弹窗
StaticPopupDialogs["SPIRIT_SENSE_REC_CONFIRM_CLEAN"] = {
    text = "确定要清空灵应录吗？",
    button1 = "确定",
    button2 = "取消",
    OnAccept = function()
        wipe(SpiritSenseRecData)
        wipe(SpiritSenseRec.sentMessages)
        SpiritSenseRec.ssr = SpiritSenseRecData
        DEFAULT_CHAT_FRAME:AddMessage("灵应录：已清空")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- 添加显示/隐藏主窗口的命令
SLASH_RGUI1 = "/rgui"
SlashCmdList.RGUI = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end

-- 初始化时隐藏主窗口
mainFrame:Hide()