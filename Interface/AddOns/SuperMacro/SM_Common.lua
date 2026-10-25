--[[
    SM_Common.lua - 超级宏通用函数模块
    提供编辑框自定义处理、滚动处理
    以及窗口尺寸/字体配置更新等通用功能
--]]

-- 为编辑框添加自定义处理函数
-- 包括：Tab键插入空格、行号显示、光标位置跟踪
local function AddCustomHandlerForEditBox(editBox)
    if ( not editBox ) then
        return
    end
    -- 添加Tab键处理
    editBox:SetScript("OnTabPressed", function()
        this:Insert("  ")
    end)

    local scrollFrame = editBox:GetParent()
    if ( not scrollFrame ) then
        return
    end

    -- 创建行号显示文本（只创建一次）
    if ( not editBox.textLineNumber ) then
        editBox.textLineNumber = scrollFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        editBox.textLineNumber:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -50, -21) -- 底部与“xxx 字符已使用”对齐 by 武藤纯子酱 2026.10.12
        editBox.textLineNumber:SetJustifyH("LEFT")
    end

    -- 光标位置变化时更新行号显示
    editBox:SetScript("OnCursorChanged", function()
        if ( SuperMacroFrame_IsDragging and SuperMacroFrame_IsDragging() ) then
            return
        end
        local y = arg2
        local lineHeight = arg4
        if not lineHeight or lineHeight <= 0 then
            return
        end
        local lineNumber = math.abs(math.floor(y / lineHeight + 0.5)) + 1
        this.textLineNumber:SetText(string.format("Line: %4d", lineNumber))
    end)
end

-- 点击编辑区空白处也能聚焦输入
-- 移除 focusButton 参数：原透明焦点按钮已删除，点击聚焦完全由 OnMouseDown 处理 by 武藤纯子酱 2026.9.10
local function AddFocusHandlerForEditBox(editBox)
    if ( not editBox ) then
        return
    end

    editBox:EnableMouse(true)
    editBox:SetScript("OnMouseDown", function()
        this:SetFocus()
    end)

    local scrollFrame = editBox:GetParent()
    if ( scrollFrame ) then
        scrollFrame:EnableMouse(true)
        scrollFrame:SetScript("OnMouseDown", function()
            editBox:SetFocus()
        end)
    end
end

-- 超级宏框架初始化（加载后调用）
-- 更新配置并为所有编辑框添加自定义处理
function SuperMacroInitFrames()
    SuperMacroUpdateConfig()
    AddCustomHandlerForEditBox(SuperMacroFrameText)
    AddFocusHandlerForEditBox(SuperMacroFrameText)
    if ( SuperMacroFrameExtendText ) then
        AddCustomHandlerForEditBox(SuperMacroFrameExtendText)
        AddFocusHandlerForEditBox(SuperMacroFrameExtendText)
    end
    AddCustomHandlerForEditBox(SuperMacroFrameSuperText)
    AddFocusHandlerForEditBox(SuperMacroFrameSuperText)
end

-- 处理编辑框滚动条
-- 当文本变化时自动滚动到底部（如果用户之前在最底部）
function SuperMacroHandleEditBox(editBox)
    if ( not editBox or not editBox.GetParent or not editBox:GetParent() ) then
        return
    end
    local scrollBar = getglobal(editBox:GetParent():GetName().."ScrollBar")
    if ( not scrollBar ) then
        return
    end
    editBox:GetParent():UpdateScrollChildRect();

    local _, max = scrollBar:GetMinMaxValues();
    scrollBar.prevMaxValue = scrollBar.prevMaxValue or max

    -- 如果用户之前在底部附近，自动滚动到新的底部
    if math.abs(scrollBar.prevMaxValue - scrollBar:GetValue()) <= 1 then
        scrollBar:SetValue(max);
    end
    if max ~= scrollBar.prevMaxValue then
        scrollBar.prevMaxValue = max
    end
end

-- 更新超级宏窗口配置
-- 根据SM_VARS中的设置调整窗口大小、字体和布局
function SuperMacroUpdateConfig()
    -- 如果正在拖动窗口，延迟配置更新
    if ( SuperMacroFrame_IsDragging and SuperMacroFrame_IsDragging() ) then
        SuperMacroFrame.updateConfigAfterDrag = 1;
        return;
    end

    -- 窗口尺寸限制
    local windowSizeXMin = 1090
    local windowSizeYMin = 512
    local windowSizeXMax = math.floor(UIParent:GetRight())
    local windowSizeYMax = math.floor(UIParent:GetTop())

    -- 宽高/字体做数值兜底，避免异常存档导致 math.max 报错 by 武藤纯子酱 2026.9.10
    SM_VARS.windowWidth = tonumber(SM_VARS.windowWidth) or windowSizeXMin
    SM_VARS.windowHeight = tonumber(SM_VARS.windowHeight) or windowSizeYMin
    SM_VARS.editBoxFontSize = tonumber(SM_VARS.editBoxFontSize) or 10

    -- 确保窗口宽度在有效范围内
    SM_VARS.windowWidth = math.max(SM_VARS.windowWidth, windowSizeXMin)
    SM_VARS.windowWidth = math.min(SM_VARS.windowWidth, windowSizeXMax)

    -- 确保窗口高度在有效范围内
    SM_VARS.windowHeight = math.max(SM_VARS.windowHeight, windowSizeYMin)
    SM_VARS.windowHeight = math.min(SM_VARS.windowHeight, windowSizeYMax)

    -- 字体统一使用默认字体（等宽字体功能已移除） by 武藤纯子酱 2026.9.10
    local editBoxFont = "Fonts\\FRIZQT__.TTF"
    local textFontSize = SM_VARS.editBoxFontSize or 10

    local sizeX = SM_VARS.windowWidth
    local sizeY = SM_VARS.windowHeight

    -- 计算各子框架的尺寸
    local scrollFrameSizeX = math.min((sizeX - 145) / 2 + 15, 1000)
    local scrollFrameSizeY = sizeY - 413

    local extendScrollFrameSizeX = sizeX - scrollFrameSizeX - 130
    local extendScrollFrameSizeY = scrollFrameSizeY + 40
    if sizeX > 1110 then
        extendScrollFrameSizeY = scrollFrameSizeY + 220
    end

    local superEditScrollFrameSizeX = sizeX - 92
    local superEditScrollFrameSizeY = scrollFrameSizeY

    -- 设置主框架尺寸
    SuperMacroFrame:SetWidth(sizeX)
    SuperMacroFrame:SetHeight(sizeY)

    -- 设置背景框架尺寸
    SuperMacroFrameMainBackground:SetWidth(sizeX - windowSizeXMin + 1046)
    SuperMacroFrameMainBackground:SetHeight(sizeY - windowSizeYMin + 430)

    -- 设置常规宏滚动框架和编辑框尺寸
    SuperMacroFrameScrollFrame:SetWidth(scrollFrameSizeX)
    SuperMacroFrameScrollFrame:SetHeight(scrollFrameSizeY)
    SuperMacroFrameTextBackground:SetWidth(scrollFrameSizeX + 36)
    SuperMacroFrameTextBackground:SetHeight(scrollFrameSizeY + 12)
    SuperMacroFrameText:SetWidth(scrollFrameSizeX - 2)
    SuperMacroFrameText:SetHeight(scrollFrameSizeY)
    SuperMacroFrameText:SetFont(editBoxFont, textFontSize)

    -- 设置扩展编辑框尺寸（存在性守卫） by 武藤纯子酱 2026.9.10
    if ( SuperMacroFrameExtendScrollFrame ) then
        SuperMacroFrameExtendScrollFrame:SetWidth(extendScrollFrameSizeX)
        SuperMacroFrameExtendScrollFrame:SetHeight(extendScrollFrameSizeY + 200)
    end
    if ( SuperMacroFrameExtendTextBackground ) then
        SuperMacroFrameExtendTextBackground:SetWidth(extendScrollFrameSizeX + 36)
        SuperMacroFrameExtendTextBackground:SetHeight(extendScrollFrameSizeY + 212)
    end
    if ( SuperMacroFrameExtendText ) then
        SuperMacroFrameExtendText:SetWidth(extendScrollFrameSizeX - 4)
        SuperMacroFrameExtendText:SetHeight(extendScrollFrameSizeY + 200 - 2)
        SuperMacroFrameExtendText:SetFont(editBoxFont, textFontSize)
    end

    -- 设置超级宏编辑框尺寸
    SuperMacroFrameSuperEditScrollFrame:SetWidth(superEditScrollFrameSizeX)
    SuperMacroFrameSuperEditScrollFrame:SetHeight(superEditScrollFrameSizeY)
    SuperMacroFrameSuperTextBackground:SetWidth(superEditScrollFrameSizeX + 36)
    SuperMacroFrameSuperTextBackground:SetHeight(superEditScrollFrameSizeY + 12)
    SuperMacroFrameSuperText:SetWidth(superEditScrollFrameSizeX - 1)
    SuperMacroFrameSuperText:SetHeight(superEditScrollFrameSizeY)
    SuperMacroFrameSuperText:SetFont(editBoxFont, textFontSize)

    -- 根据当前标签页切换扩展编辑框的父锚点（存在性守卫） by 武藤纯子酱 2026.9.10
    if ( SuperMacroFrameExtendScrollFrame ) then
        if SM_VARS.tabShown == "regular" then
            SuperMacroFrameExtendScrollFrame:ClearAllPoints()
            SuperMacroFrameExtendScrollFrame:SetPoint("BOTTOMLEFT", "SuperMacroFrameScrollFrame", "BOTTOMRIGHT", 40, 0)
        elseif SM_VARS.tabShown == "super" then
            SuperMacroFrameExtendScrollFrame:ClearAllPoints()
            -- 超级宏时锚定到超级宏编辑框右侧（右移 30px） by 武藤纯子酱 2026.9.10
            SuperMacroFrameExtendScrollFrame:SetPoint("BOTTOMLEFT", "SuperMacroFrameSuperEditScrollFrame", "BOTTOMRIGHT", 70, 0)
        end
    end
end