-- ======================== UI 工具函数库 ================================
-- 提取 UI.lua 中的重复逻辑为公共函数，减少代码冗余

-- ======================== Lua 全局工具本地化（性能优化）===============================
local GameTooltip = GameTooltip
local CreateFrame = CreateFrame
local getglobal = getglobal
local math_floor = math.floor
local STANDARD_TEXT_FONT = STANDARD_TEXT_FONT

local addon = PTURTLE_Combat

-- ==================== 滑块工厂函数 ====================
-- 创建配置滑块的通用函数
function addon:CreateConfigSlider(parent, config)
    local s = CreateFrame("Slider", config.name, parent, "OptionsSliderTemplate")
    s:SetWidth(config.width or 170)
    s:SetHeight(config.height or 20)
    
    -- 设置位置
    if config.anchorFrom and config.anchorTo then
        s:SetPoint(config.anchorFrom, config.anchorTo, config.anchorRelPoint or "BOTTOMLEFT", config.offsetX or 0, config.offsetY or -22)
    end
    
    -- 设置范围和步进
    s:SetMinMaxValues(config.minValue, config.maxValue)
    s:SetValueStep(config.valueStep or 1)
    
    -- 读取初始值
    local savedValue = PTURTLE_Combat_DB and PTURTLE_Combat_DB[config.dbKey]
    local initValue = savedValue or config.defaultValue
    s:SetValue(initValue)
    
    -- 设置文本
    local t = getglobal(s:GetName().."Text")
    t:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    t:SetTextColor(1, 1, 1)
    t:SetText(config.title)
    
    getglobal(s:GetName().."Low"):SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    getglobal(s:GetName().."High"):SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    
    -- 显示当前值
    local val = s:CreateFontString(nil, "OVERLAY")
    val:SetPoint("RIGHT", s, "LEFT", -5, 0)
    val:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
    val:SetTextColor(1, 1, 1)
    val:SetText(tostring(initValue))
    s.val = val
    s.idx = config.index
    
    -- 值变化回调
    s:SetScript("OnValueChanged", function()
        local vv = math_floor(this:GetValue())
        this.val:SetText(tostring(vv))
        
        -- 同步到数据库
        if config.dbKey then
            addon.db[config.dbKey] = vv
            PTURTLE_Combat_DB[config.dbKey] = vv
        end
        
        -- 执行自定义回调
        if config.onValueChanged then
            config.onValueChanged(vv)
        end
    end)
    
    -- Tooltip
    if config.tooltipTitle then
        s:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOPRIGHT")
            GameTooltip:SetText(config.tooltipTitle, 1, 1, 1)
            if config.tooltipDesc then
                GameTooltip:AddLine(config.tooltipDesc, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        s:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return s
end

-- ==================== 复选框工厂函数 ====================
-- 创建开关复选框的通用函数
function addon:CreateToggleCheckbox(parent, config)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetWidth(24)
    cb:SetHeight(24)
    
    -- 设置位置
    if config.anchorFrom and config.anchorTo then
        cb:SetPoint(config.anchorFrom, config.anchorTo, config.anchorRelPoint or "TOPLEFT", config.offsetX or 0, config.offsetY or 0)
    end
    
    cb:SetChecked(config.checked or false)
    
    -- 创建文本标签
    if config.labelText then
        local label = cb:CreateFontString(nil, "OVERLAY")
        label:SetFont(STANDARD_TEXT_FONT, 13, "OUTLINE")
        label:SetPoint("LEFT", cb, "RIGHT", 5, 0)
        label:SetText(config.labelText)
        if config.labelColor then
            label:SetTextColor(unpack(config.labelColor))
        else
            label:SetTextColor(1, 1, 1)
        end
    end
    
    -- 点击事件
    cb:SetScript("OnClick", function()
        local isChecked = cb:GetChecked() and 1 or 0
        if config.dbKey then
            addon.db[config.dbKey] = isChecked
            PTURTLE_Combat_DB[config.dbKey] = isChecked
        end
        
        if config.onClick then
            config.onClick(isChecked)
        end
    end)
    
    -- Tooltip
    if config.tooltipTitle then
        cb:SetScript("OnEnter", function()
            GameTooltip:SetOwner(cb, config.tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetText(config.tooltipTitle, 1, 1, 1)
            if config.tooltipDesc then
                GameTooltip:AddLine(config.tooltipDesc, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return cb
end

-- ==================== 按钮工厂函数 ====================
-- 创建标准按钮的通用函数
function addon:CreateStandardButton(parent, config)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetWidth(config.width or 60)
    btn:SetHeight(config.height or 20)
    
    -- 设置位置
    if config.anchorFrom and config.anchorTo then
        btn:SetPoint(config.anchorFrom, config.anchorTo, config.anchorRelPoint or "LEFT", config.offsetX or 10, config.offsetY or 0)
    end
    
    btn:SetText(config.text or "按钮")
    
    -- 点击事件
    if config.onClick then
        btn:SetScript("OnClick", config.onClick)
    end
    
    -- Tooltip
    if config.tooltipTitle then
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, config.tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetText(config.tooltipTitle, 1, 1, 1)
            if config.tooltipDesc then
                GameTooltip:AddLine(config.tooltipDesc, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return btn
end

-- ==================== 可编辑框架设置 ====================
-- 设置受伤/受治疗/输出治疗框体的通用函数
function addon:SetupEditableFrame(frame, handle, label, startPoint, endPoint, resizeHandle, labelText, colorR, colorG, colorB)
    -- 设置背景和边框
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(colorR, colorG, colorB, 1)
    frame:EnableMouse(true)
    
    -- 显示手柄和标签
    if handle then handle:Show() end
    if label then 
        label:SetText(labelText)
        label:Show() 
    end
    if startPoint then startPoint:Show() end
    if endPoint then endPoint:Show() end
    if resizeHandle then resizeHandle:Show() end
end

-- ==================== EditBox 工厂函数 ====================
-- 创建标准输入框的通用函数
function addon:CreateEditBox(parent, config)
    local editBox = CreateFrame("EditBox", nil, parent)
    editBox:SetWidth(config.width or 150)
    editBox:SetHeight(config.height or 20)
    
    -- 设置位置
    if config.anchorFrom and config.anchorTo then
        editBox:SetPoint(config.anchorFrom, config.anchorTo, config.anchorRelPoint or "TOPLEFT", config.offsetX or 0, config.offsetY or 0)
    end
    
    -- 基本属性
    editBox:SetAutoFocus(config.autoFocus or false)
    editBox:SetJustifyH(config.justifyH or "CENTER")
    
    -- 字体设置
    if config.font then
        editBox:SetFont(config.font, config.fontSize or 12, config.fontFlags or "OUTLINE")
    else
        editBox:SetFont(STANDARD_TEXT_FONT, config.fontSize or 12, config.fontFlags or "OUTLINE")
    end
    
    -- 文本颜色
    if config.textColor then
        editBox:SetTextColor(unpack(config.textColor))
    else
        editBox:SetTextColor(1, 1, 1, 1)
    end
    
    -- 最大字符数
    if config.maxLetters then
        editBox:SetMaxLetters(config.maxLetters)
    end
    
    -- 是否只允许数字
    if config.numeric then
        editBox:SetNumeric(true)
    end
    
    -- 边框样式（可选）
    if config.hasBorder then
        editBox:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = config.edgeSize or 12,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        editBox:SetBackdropBorderColor(
            config.borderColorR or 0.6,
            config.borderColorG or 0.6,
            config.borderColorB or 0.6,
            config.borderColorA or 1
        )
    end
    
    -- 背景占位符文字（可选）
    if config.placeholder then
        local placeholder = editBox:CreateFontString(nil, "BACKGROUND", "GameFontDisableSmall")
        placeholder:SetAllPoints(editBox)
        placeholder:SetJustifyH(config.justifyH or "CENTER")
        placeholder:SetText(config.placeholder)
        placeholder:SetTextColor(
            config.placeholderColorR or 0.5,
            config.placeholderColorG or 0.5,
            config.placeholderColorB or 0.5
        )
        editBox.placeholder = placeholder
        
        -- 监听输入框内容变化，控制占位符显示/隐藏
        editBox:SetScript("OnTextChanged", function()
            if this:GetText() == "" then
                editBox.placeholder:Show()
            else
                editBox.placeholder:Hide()
            end
        end)
    end
    
    -- 失去焦点回调（用于验证和保存）
    if config.onEditFocusLost then
        editBox:SetScript("OnEditFocusLost", config.onEditFocusLost)
    end
    
    -- 回车键确认（默认清除焦点）
    editBox:SetScript("OnEnterPressed", function()
        if config.onEnterPressed then
            config.onEnterPressed()
        else
            editBox:ClearFocus()
        end
    end)
    
    -- Tooltip（可选）
    if config.tooltipTitle then
        editBox:SetScript("OnEnter", function()
            GameTooltip:SetOwner(editBox, config.tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetText(config.tooltipTitle, 1, 1, 1)
            if config.tooltipDesc then
                GameTooltip:AddLine(config.tooltipDesc, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        editBox:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    return editBox
end

-- ==================== 切换按钮工厂函数 ====================
-- 创建带状态显示的切换按钮（绿色T/红色X）
function addon:CreateToggleButton(parent, config)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(config.width or 24)
    btn:SetHeight(config.height or 24)
    
    -- 设置位置
    if config.anchorFrom and config.anchorTo then
        btn:SetPoint(config.anchorFrom, config.anchorTo, config.anchorRelPoint or "LEFT", config.offsetX or 5, config.offsetY or 0)
    end
    
    -- 设置按钮背景
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- 创建文本显示
    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, config.fontSize or 14, "OUTLINE")
    text:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn.text = text
    
    -- 获取状态的函数（返回布尔值）
    local getState = config.getState or function()
        return false
    end
    
    -- 更新按钮状态函数
    local function updateState()
        local isEnabled = getState()
        if isEnabled then
            -- 开启状态：绿色边框，显示开启文本
            btn:SetBackdropBorderColor(
                config.enabledBorderR or 0,
                config.enabledBorderG or 1,
                config.enabledBorderB or 0,
                config.enabledBorderA or 1
            )
            btn:SetBackdropColor(
                config.enabledBgR or 0,
                config.enabledBgG or 0.3,
                config.enabledBgB or 0,
                config.enabledBgA or 0.5
            )
            text:SetText(config.enabledText or "T")
            text:SetTextColor(
                config.enabledTextR or 0,
                config.enabledTextG or 1,
                config.enabledTextB or 0,
                config.enabledTextA or 1
            )
        else
            -- 关闭状态：红色边框，显示关闭文本
            btn:SetBackdropBorderColor(
                config.disabledBorderR or 1,
                config.disabledBorderG or 0,
                config.disabledBorderB or 0,
                config.disabledBorderA or 1
            )
            btn:SetBackdropColor(
                config.disabledBgR or 0.3,
                config.disabledBgG or 0,
                config.disabledBgB or 0,
                config.disabledBgA or 0.5
            )
            text:SetText(config.disabledText or "X")
            text:SetTextColor(
                config.disabledTextR or 1,
                config.disabledTextG or 0,
                config.disabledTextB or 0,
                config.disabledTextA or 1
            )
        end
    end
    
    -- 初始化按钮状态
    updateState()
    
    -- 点击切换
    btn:SetScript("OnClick", function()
        if config.onClick then
            config.onClick()
        end
        -- 点击后更新状态
        updateState()
    end)
    
    -- Tooltip（可选）
    if config.tooltipTitle then
        btn:SetScript("OnEnter", function()
            GameTooltip:SetOwner(btn, config.tooltipAnchor or "ANCHOR_BOTTOMRIGHT")
            GameTooltip:SetText(config.tooltipTitle, 1, 1, 1)
            if config.tooltipDesc then
                GameTooltip:AddLine(config.tooltipDesc, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end
    
    -- 暴露更新函数，供外部调用
    btn.updateState = updateState
    
    return btn
end

-- ==================== 面板工厂函数 ====================
-- 创建标准面板的通用函数（带标题、关闭按钮、拖动）
function addon:CreatePanel(parent, config)
    local panel = CreateFrame("Frame", config.name or nil, parent or UIParent)
    panel:SetWidth(config.width or 500)
    panel:SetHeight(config.height or 400)
    panel:SetFrameStrata(config.frameStrata or "HIGH")
    panel:EnableMouse(true)
    
    -- 是否可拖动
    if config.movable ~= false then
        panel:SetMovable(true)
        panel:RegisterForDrag("LeftButton")
    end
    
    -- 设置位置
    if config.anchorFrom and config.anchorTo then
        panel:SetPoint(config.anchorFrom, config.anchorTo, config.anchorRelPoint or "CENTER", config.offsetX or 0, config.offsetY or 0)
    elseif config.point then
        panel:SetPoint(config.point, config.relativeTo or UIParent, config.relativePoint or "CENTER", config.x or 0, config.y or 0)
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    
    -- 设置背景和边框
    panel:SetBackdrop({
        bgFile = config.bgFile or "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = config.edgeFile or "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = config.edgeSize or 16,
        insets = config.insets or {left = 4, right = 4, top = 4, bottom = 4}
    })
    panel:SetBackdropColor(
        config.bgColorR or 0,
        config.bgColorG or 0,
        config.bgColorB or 0,
        config.bgColorA or 0.9
    )
    panel:SetBackdropBorderColor(
        config.borderColorR or 0.5,
        config.borderColorG or 0.5,
        config.borderColorB or 0.5,
        config.borderColorA or 1
    )
    
    -- 创建标题
    if config.title then
        local title = panel:CreateFontString(nil, "OVERLAY")
        title:SetFont(STANDARD_TEXT_FONT, config.titleFontSize or 14, "OUTLINE")
        title:SetPoint("TOP", panel, "TOP", 0, config.titleOffsetY or -8)
        title:SetText(config.title)
        title:SetTextColor(
            config.titleColorR or 1,
            config.titleColorG or 1,
            config.titleColorB or 1,
            config.titleColorA or 1
        )
        panel.title = title
    end
    
    -- 创建关闭按钮
    if config.showCloseBtn ~= false then
        local closeBtn = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
        closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", config.closeBtnOffsetX or -5, config.closeBtnOffsetY or -5)
        
        if config.onClose then
            closeBtn:SetScript("OnClick", function()
                config.onClose(panel)
            end)
        else
            closeBtn:SetScript("OnClick", function()
                panel:Hide()
            end)
        end
        
        panel.closeBtn = closeBtn
    end
    
    -- 拖动脚本
    if config.movable ~= false then
        panel:SetScript("OnDragStart", function()
            panel:StartMoving()
        end)
        panel:SetScript("OnDragStop", function()
            panel:StopMovingOrSizing()
            
            -- 保存位置（如果提供回调）
            if config.onDragStop then
                config.onDragStop(panel)
            end
        end)
    end
    
    return panel
end
