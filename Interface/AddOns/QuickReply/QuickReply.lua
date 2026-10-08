
-- 快速回复 v1.0
QuickReply = {}
QuickReply.actionFrame = nil
QuickReply.configFrame = nil
QuickReply.buttons = {}
QuickReply.configRows = {}

-- 默认配置（首次加载时使用）
QuickReply.defaults = {
    replies = {
    },
    configFramePosition = {
        x = 0,
        y = 0
    }
}

-- 本地变量
local tmpReplies = {}
local rows = {}

if QuickReplyDBC == nil then
    QuickReplyDBC = QuickReply.defaults
end

-- ▼▼▼ 主按钮逻辑 ▼▼▼
local frame = CreateFrame("Frame", "QuickReplyFrame", UIParent)
frame:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "",
    tile = true, tileSize = 16, edgeSize = 0,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
frame:SetBackdropColor(0, 0, 0, 0)

function QuickReply:SendReply(content)
    if not content or content == "" then return end
    local user = QuickReply:GetCurrentWIMTarget()
    if not user then return end

    SendChatMessage(content, "WHISPER", nil, user)
end

function QuickReply:CreateButton()
    local btn = CreateFrame("Button", nil, frame)
    btn:SetWidth(72)
    btn:SetHeight(22)
    btn:SetText("")
    
    -- PFUI风格背景
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "",
        tile = true, tileSize = 8, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    
    -- 字体
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER", 0, 0)
    text:SetTextColor(0.9, 0.9, 0.9, 1)
    btn:SetFontString(text)
    
    -- 悬停效果
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
        btn:GetFontString():SetTextColor(1, 1, 1, 1)
    end)
    
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        btn:GetFontString():SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    
    btn:SetScript("OnMouseDown", function()
        btn:SetBackdropColor(0.15, 0.15, 0.15, 0.95)
    end)
    
    btn:SetScript("OnMouseUp", function()
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
    end)
    
    btn:SetScript("OnClick", function()
        QuickReply:SendReply(btn.content)
    end)
    return btn
end

function QuickReply:InitButton()
    QuickReply.buttons = {}
    for i = 1, 10 do
        local btn = QuickReply:CreateButton()
        btn:SetPoint("TOPLEFT", frame, "TOPLEFT", math.mod(i - 1, 5) * 80, i > 5 and -30 or 0)
        table.insert(QuickReply.buttons, btn)
    end
    QuickReply:UpdateButton()
end

function QuickReply:GetCurrentWIMTarget()
    if WIM_Windows == nil then return end
    for user, v in pairs(WIM_Windows) do
        if v.is_visible then
            return user
        end
    end
    return nil
end

function QuickReply:UpdateButton()
    local user = QuickReply:GetCurrentWIMTarget()
    if user == nil then
        frame:Hide()
        return
    end

    frame:Show()
    local wimFrame = getglobal('WIM_msgFrame'..user)
    frame:SetPoint("TOPLEFT", wimFrame, "BOTTOMLEFT", 10, -10)
    frame:SetWidth(wimFrame:GetWidth())
    frame:SetHeight(60)
    for i, btn in ipairs(QuickReply.buttons) do
        local reply = QuickReplyDBC.replies[i]
        if reply and reply.enabled then
            btn:Show()
            btn:SetText(reply.name)
            btn.content = reply.content
        else
            btn:Hide()
        end
    end
end

-- ▼▼▼ 配置界面 ▼▼▼
function QuickReply:CreateConfigFrame()
    if self.configFrame then return end

    local frame = FlowUI:CreateDraggableFrame("QuickReplyConfig", "设置快捷回复", 600, 426, QuickReplyDBC.configFramePosition)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:Hide()
    self.configFrame = frame

    -- 列标题
    local header0 = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    header0:SetPoint("TOPLEFT", frame, "TOPLEFT", 103, -40)
    header0:SetText("启用")
    local header1 = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    header1:SetPoint("LEFT", header0, "RIGHT", 33, 0)
    header1:SetText("按钮")
    local header2 = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    header2:SetPoint("LEFT", header1, "RIGHT", 200, 0)
    header2:SetText("回复")

    -- 内容区域
    local bodyFrame = CreateFrame("ScrollFrame", nil, frame)
    bodyFrame:SetWidth(580)
    bodyFrame:SetHeight(360)
    bodyFrame:SetPoint("TOP", frame, "TOP", 10, -60)
    self.bodyFrame = bodyFrame

    -- 按钮：添加 / 保存 / 关闭
    local function createPFUIButton(parent, text)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetWidth(60)
        btn:SetHeight(22)
        btn:SetText(text)
        
        -- PFUI风格按钮
        btn:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "",
            tile = true, tileSize = 8, edgeSize = 0,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        
        local textObj = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textObj:SetPoint("CENTER", 0, 0)
        textObj:SetText(text)
        textObj:SetTextColor(0.9, 0.9, 0.9, 1)
        btn:SetFontString(textObj)
        
        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
            btn:GetFontString():SetTextColor(1, 1, 1, 1)
        end)
        
        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            btn:GetFontString():SetTextColor(0.9, 0.9, 0.9, 1)
        end)
        
        btn:SetScript("OnMouseDown", function()
            btn:SetBackdropColor(0.15, 0.15, 0.15, 0.95)
        end)
        
        btn:SetScript("OnMouseUp", function()
            btn:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
        end)
        
        return btn
    end

    local btnAdd = createPFUIButton(frame, "添加")
    btnAdd:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 20, 20)
    btnAdd:SetScript("OnClick", function() QuickReply:NewConfigRow() end)

    local btnSave = createPFUIButton(frame, "保存")
    btnSave:SetPoint("BOTTOM", frame, "BOTTOM", 0, 20)
    btnSave:SetScript("OnClick", function()
        -- 1. 校验
        local errors = {}
        for i, data in ipairs(tmpReplies) do
            if strtrim(data.name) == "" or strtrim(data.content) == "" then
                table.insert(errors, { index = i, name = data.name, conent = data.content })
            end
        end

        -- 2. 存在错误 → 阻止保存
        if table.getn(errors) > 0 then
            -- 红框闪烁效果（兼容 1.12）
            local flashFrame = CreateFrame("Frame")
            flashFrame.count = 0
            flashFrame:SetScript("OnUpdate", function()
                flashFrame.elapsed = (flashFrame.elapsed or 0)
                if flashFrame.elapsed < 0.15 then return end
                flashFrame.elapsed = 0
                if flashFrame.count >= 6 then
                    flashFrame:SetScript("OnUpdate", nil)
                    return
                end
                local isVisible = (math.mod(flashFrame.count, 2) == 0)
                for _, err in ipairs(errors) do
                    for _, row in ipairs(QuickReply.configRows) do
                        if row.contentEdit and row.nameEdit.index == err.index then
                            if isVisible then
                                row.contentEdit:SetBackdrop({
                                    edgeFile = "",
                                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                                    tile = true, tileSize = 8, edgeSize = 0,
                                })
                                row.contentEdit:SetBackdropColor(1, 0.2, 0.2, 0.3)
                            else
                                row.contentEdit:SetBackdrop({
                                    edgeFile = "",
                                    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                                    tile = true, tileSize = 8, edgeSize = 0,
                                })
                                row.contentEdit:SetBackdropColor(0, 0, 0, 0.5)
                            end
                        end
                    end
                end
                flashFrame.count = flashFrame.count + 1
            end)

            -- 错误提示
            local msg = "保存失败！以下内容设置错误："
            for _, err in ipairs(errors) do
                msg = msg .. "\n  • 第" .. err.index .. "行"
            end
            msg = msg .. "\n请确认按钮和回复内容都不为空"
            UIErrorsFrame:AddMessage(msg, 1, 0.2, 0.2, 1, 5)
            return
        end

        -- 3.保存成功 → 更新按钮 + 关闭
        QuickReplyDBC.replies = tmpReplies
        QuickReply:UpdateButton()
        frame:Hide()
    end)

    local btnClose = createPFUIButton(frame, "关闭")
    btnClose:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -20, 20)
    btnClose:SetScript("OnClick", function() frame:Hide() end)

    -- ESC 关闭
    frame:SetScript("OnKeyDown", function(_, key)
        if key == "ESCAPE" then frame:Hide() end
    end)
end

function QuickReply:Init()
    QuickReplyDBC = QuickReplyDBC or QuickReply.defaults
    QuickReply:InitButton()
end

-- 刷新配置列表
function QuickReply:RefreshConfig(r)
    tmpReplies = DeepCopy(r)
    for i, row in ipairs(rows) do
        row:Hide()
        row = nil
    end
    rows = {}
    for i, data in ipairs(tmpReplies) do
        local row = QuickReply:AddConfigRow(i, data)
        table.insert(rows, row)
    end
end

function QuickReply:NewConfigRow()
    if (table.getn(tmpReplies) >= 10) then return end
    local data = { name = "", enabled = true, content = "" }
    table.insert(tmpReplies, data)
    return QuickReply:RefreshConfig(tmpReplies)
end

local function setButton(btn, offset)
    btn:SetWidth(24)
    btn:SetHeight(24)
    
    -- PFUI风格按钮
    btn:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "",
        tile = true, tileSize = 8, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    local buttonText = btn:GetFontString()
    if buttonText then
        buttonText:ClearAllPoints()
        buttonText:SetPoint("CENTER", btn, "CENTER", offset, 0)
        buttonText:SetJustifyH("CENTER")
        buttonText:SetTextColor(0.9, 0.9, 0.9, 1)
    end
    
    -- 悬停效果
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
        btn:GetFontString():SetTextColor(1, 1, 1, 1)
    end)
    
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        btn:GetFontString():SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    
    btn:SetScript("OnMouseDown", function()
        btn:SetBackdropColor(0.15, 0.15, 0.15, 0.95)
    end)
    
    btn:SetScript("OnMouseUp", function()
        btn:SetBackdropColor(0.2, 0.2, 0.2, 0.9)
    end)
end

local function setEditor(edit) 
    edit:SetWidth(80)
    edit:SetHeight(22)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlight")
    edit:SetJustifyH("CENTER")
    edit:SetTextColor(0.9, 0.9, 0.9, 1)

    -- PFUI风格输入框
    edit:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "",
        tile = true, tileSize = 8, edgeSize = 0,
    })
    edit:SetBackdropColor(0, 0, 0, 0.5)
end

-- 添加一行配置
function QuickReply:AddConfigRow(index, data)
    local row = CreateFrame("Frame", nil, self.bodyFrame)
    row:SetWidth(560)
    row:SetHeight(32)
    row:SetPoint("TOPLEFT", self.bodyFrame, "TOPLEFT", 0, (index - 1) * -32)

    -- 上移 / 下移 / 删除
    local btnUp = CreateFrame("Button", nil, row)
    btnUp:SetPoint("LEFT", row, "LEFT", 2, 0)
    btnUp:SetText("▲")
    setButton(btnUp, -2)
    btnUp:SetScript("OnClick", function()
        if index > 1 then
            tmpReplies[index], tmpReplies[index - 1] = tmpReplies[index - 1], tmpReplies[index]
            QuickReply:RefreshConfig(tmpReplies)
        end
    end)

    local btnDown = CreateFrame("Button", nil, row)
    btnDown:SetPoint("LEFT", btnUp, "RIGHT", 2, 0)
    btnDown:SetText("▼")
    setButton(btnDown, -2)
    btnDown:SetScript("OnClick", function()
        if index < table.getn(QuickReplyDBC.replies) then
            tmpReplies[index], tmpReplies[index + 1] = tmpReplies[index + 1], tmpReplies[index]
            QuickReply:RefreshConfig(tmpReplies)
        end
    end)

    local btnDel = CreateFrame("Button", nil, row)
    btnDel:SetPoint("LEFT", btnDown, "RIGHT", 2, 0)
    btnDel:SetText("-")
    setButton(btnDel)
    btnDel:SetScript("OnClick", function()
        table.remove(tmpReplies, index)
        QuickReply:RefreshConfig(tmpReplies)
    end)

    -- 启用复选框
    local check = CreateFrame("CheckButton", nil, row, "OptionsCheckButtonTemplate")
    check:SetHitRectInsets(0, 0, 0, 0)
    check:SetPoint("LEFT", btnDel, "RIGHT", 4, -1)
    check:SetChecked(data.enabled)
    check:SetScript("OnClick", function(self)
        tmpReplies[index].enabled = check:GetChecked()
    end)

    -- 按钮名称输入
    local nameEdit = CreateFrame("EditBox", nil, row)
    setEditor(nameEdit)
    nameEdit:SetPoint("LEFT", check, "RIGHT", 6, 1)
    nameEdit:SetText(data.name or "")
    nameEdit:SetScript("OnTextChanged", function()
        if tmpReplies[index] ~= nil then
            tmpReplies[index].name = nameEdit:GetText()
        end
    end)

    -- 回答内容输入
    local contentEdit = CreateFrame("EditBox", nil, row)
    setEditor(contentEdit)
    contentEdit:SetWidth(350)
    contentEdit:SetPoint("LEFT", nameEdit, "RIGHT", 10, 0)
    contentEdit:SetText(data.content or "")
    contentEdit:SetScript("OnTextChanged", function()
        if tmpReplies[index] ~= nil then
            tmpReplies[index].content = contentEdit:GetText()
        end
    end)

    return row
end

-- 打开配置界面
function QuickReply:OpenConfig()
    if not self.configFrame then
        self:CreateConfigFrame()
    end
    self.configFrame:Show()
    QuickReply:RefreshConfig(QuickReplyDBC.replies)
end

-- ▲▲▲

-- ▼▼▼ 初始化与事件 ▼▼▼

-- 注册命令：/qr, /quickreply
SLASH_QUICKREPLY1 = "/qr"
SLASH_QUICKREPLY2 = "/quickreply"
SlashCmdList["QUICKREPLY"] = function(command)
    if command == "init" then
        QuickReply:Init()
        return
    end
    QuickReply:OpenConfig()
end

-- 初始化插件
local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnUpdate", function() 
    eventFrame:SetScript("OnUpdate", nil)
    QuickReply:Init()
end)

-- 创建计时器帧
local timerFrame = CreateFrame("Frame", "MyTimerFrame", UIParent)
local elapsedTime = GetTime()

timerFrame:SetScript("OnUpdate", function()
    if GetTime() - elapsedTime >= 1 then
        elapsedTime = GetTime()
        QuickReply:UpdateButton()
    end
end)
