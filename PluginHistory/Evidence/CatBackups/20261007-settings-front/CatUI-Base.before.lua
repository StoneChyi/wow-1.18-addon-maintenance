
 function MPToBoolean(value)
    if value==1 then
        return true
    end

    return false
end

function MPCatUISliderRegionHide(slider)
    local region1, region2, region3, region4,region5,region6,region7,region8,region9 = slider:GetRegions()
    if region4 then region4:Hide() end
    if region5 then region5:Hide() end
    if region6 then region6:Hide() end
    if region7 then region7:Hide() end
    if region8 then region8:Hide() end
    if region9 then region9:Hide() end

    _G[slider:GetName().."Low"]:Hide()
    _G[slider:GetName().."High"]:Hide()

end


function MPCreateFrame(addonname, fwidth, fheight, titlestr)

    -- 创建主框架
    local valueWindow = CreateFrame("Frame", addonname, UIParent)
    valueWindow:Hide()

    --tinsert(UISpecialFrames, addonname)

    -- 设置窗口基本属性
    valueWindow:SetWidth(fwidth)   -- 520
    valueWindow:SetHeight(fheight)
    valueWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    valueWindow:SetFrameLevel(1)

    -- 创建Tooltip风格的背景和边框
    valueWindow:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    valueWindow:SetBackdropColor(0.1, 0.1, 0.2, 0.85)
    valueWindow:SetScale(0.9)

    -- 使窗口可移动
    valueWindow:EnableMouse(true)
    valueWindow:SetMovable(true)
    valueWindow:RegisterForDrag("LeftButton")
    valueWindow:SetScript("OnDragStart", function()
        valueWindow:StartMoving()
    end)
    valueWindow:SetScript("OnDragStop", function()
        valueWindow:StopMovingOrSizing()
    end)

    -- 添加标题文字
    local title = valueWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", valueWindow, "TOP", 0, -11)
    title:SetText(titlestr)
    title:SetJustifyH("CENTER")

    local cr = valueWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cr:SetPoint("TOPLEFT", valueWindow, "TOPLEFT", 10, -12)
    cr:SetFont("Fonts\\FRIZQT__.TTF", 12)
    cr:SetText(MPLanguage.UI_AddonTitle)

    -- 添加标准关闭按钮
    local closeButton = CreateFrame("Button", nil, valueWindow, "UIPanelCloseButton")
    closeButton:SetWidth(32)
    closeButton:SetHeight(32)
    closeButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -5, -2)

    local addButton = CreateFrame("Button", nil, valueWindow, "UIPanelButtonTemplate")
    addButton:SetWidth(54)
    addButton:SetHeight(20)
    addButton:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    addButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -55, -8)
    addButton:SetText(MPLanguage.UI_Mon_ScaleUp)
    addButton:SetScript("OnClick", function(self)
        local parent = this:GetParent()
        local scale = parent:GetScale()+0.1
        if scale < 2.0 then
            parent:SetScale( scale )
        end
    end)

    local decButton = CreateFrame("Button", nil, valueWindow, "UIPanelButtonTemplate")
    decButton:SetWidth(54)
    decButton:SetHeight(20)
    decButton:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    decButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -115, -8)
    decButton:SetText(MPLanguage.UI_Mon_ScaleDown)
    decButton:SetScript("OnClick", function(self)
        local parent = this:GetParent()
        local scale = parent:GetScale()-0.1
        if scale > 0.3 then
            parent:SetScale( scale )
        end
    end)


    -- 添加分隔线
    local divider = valueWindow:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetTexCoord(0.81, 0.94, 0.5, 1)
    divider:SetVertexColor(0.5, 0.5, 0.5)
    divider:SetWidth(fwidth-10)
    divider:SetHeight(4)
    divider:SetPoint("TOP", valueWindow, "TOP", 0, -30)

    return valueWindow
end



function MPCreateCheckButton(father, name, x, y, str)
    -- 创建单选框 - 狂怒
    local valueButon = CreateFrame("CheckButton", name, father, "UICheckButtonTemplate")
    valueButon:SetPoint("TOPLEFT", father, "TOPLEFT", x, y)
    valueButon:SetScale(0.8)

    -- 添加文字标签
    local checkText_Fury = valueButon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    checkText_Fury:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    checkText_Fury:SetTextColor(1, 1, 1)
    checkText_Fury:SetPoint("LEFT", valueButon, "LEFT", 34, 1)
    checkText_Fury:SetText(str)

    return valueButon
end



function MPCreateCheckButtonSmall(father, name, x, y, str)
    -- 创建单选框 - 狂怒
    local valueButon = CreateFrame("CheckButton", name, father, "UICheckButtonTemplate")
    valueButon:SetPoint("TOPLEFT", father, "TOPLEFT", x, y)
    valueButon:SetScale(0.8)

    -- 添加文字标签
    local checkText_Fury = valueButon:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    checkText_Fury:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    checkText_Fury:SetTextColor(0.8, 0.8, 0.8)
    checkText_Fury:SetPoint("LEFT", valueButon, "LEFT", 34, 1)
    checkText_Fury:SetText(str)

    return valueButon
end


function MPCreateButton(father, name, text, x, y, w, h)
    local myButton = CreateFrame("Button", name, father, "UIPanelButtonTemplate")
    myButton:SetPoint("TOPLEFT", father, "TOPLEFT", x, y)
    myButton:SetWidth(w)
    myButton:SetHeight(h)
    myButton:SetFont("Fonts\\FRIZQT__.TTF", 12)
    myButton:SetText(text)

    -- 调整按钮纹理
    myButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    myButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    myButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    myButton:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
    return myButton
end


function MPBottomLine(father)
    local bottomline = father:CreateTexture(nil, "ARTWORK")
    bottomline:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    bottomline:SetTexCoord(0.81, 0.94, 0.5, 1)
    bottomline:SetVertexColor(0.5, 0.5, 0.5)
    bottomline:SetWidth(510)
    bottomline:SetHeight(4)
    bottomline:SetPoint("BOTTOM", father, "BOTTOM", 0, 60)
end


function MPPublicCheckButton(father, name, x, y, str)
    local checkButton = CreateFrame("CheckButton", name, father, "UICheckButtonTemplate")
    checkButton:SetPoint("BOTTOMLEFT", father, "BOTTOMLEFT", x, y)
    checkButton:SetScale(0.8)
    local checkText = checkButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    checkText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    checkText:SetTextColor(1, 1, 1)
    checkText:SetPoint("LEFT", checkButton, "LEFT", 34, 1)
    checkText:SetText(str)
    return checkButton
end


function MPPublicButton(father, name, text, x, y, w, h)
    local Button = CreateFrame("Button", name, father, "UIPanelButtonTemplate")
    Button:SetPoint("BOTTOMLEFT", father, "BOTTOMLEFT", x, y)
    Button:SetWidth(w)
    Button:SetHeight(h)
    Button:SetFont("Fonts\\FRIZQT__.TTF", 12)
    Button:SetText(text)
    Button:SetNormalTexture("Interface\\Buttons\\UI-Panel-Button-Up")
    Button:SetHighlightTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    Button:SetPushedTexture("Interface\\Buttons\\UI-Panel-Button-Down")
    Button:SetDisabledTexture("Interface\\Buttons\\UI-Panel-Button-Disabled")
    return Button
end


-- ======= mini ========

local function MPCreateMiniFrame(addonname, fwidth, fheight, titlestr)
    -- 创建主框架
    local valueWindow = CreateFrame("Frame", addonname, UIParent)
    valueWindow:Hide()

    --tinsert(UISpecialFrames, addonname)

    -- 设置窗口基本属性
    valueWindow:SetWidth(fwidth)   -- 520
    valueWindow:SetHeight(fheight)
    valueWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    valueWindow:SetFrameLevel(1)

    -- 创建Tooltip风格的背景和边框
    valueWindow:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    valueWindow:SetBackdropColor(0.1, 0.1, 0.2, 0.85)
    valueWindow:SetScale(0.9)

    -- 使窗口可移动
    valueWindow:EnableMouse(true)
    valueWindow:SetMovable(true)
    valueWindow:RegisterForDrag("LeftButton")
    valueWindow:SetScript("OnDragStart", function()
        valueWindow:StartMoving()
    end)
    valueWindow:SetScript("OnDragStop", function()
        valueWindow:StopMovingOrSizing()
    end)

    local cr = valueWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cr:SetPoint("TOPLEFT", valueWindow, "TOPLEFT", 10, -12)
    cr:SetFont("Fonts\\FRIZQT__.TTF", 12)
    cr:SetText(titlestr)

    -- 添加标准关闭按钮
    local closeButton = CreateFrame("Button", nil, valueWindow, "UIPanelCloseButton")
    closeButton:SetWidth(32)
    closeButton:SetHeight(32)
    closeButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -5, -2)

    local MoreButton = CreateFrame("Button", nil, valueWindow, "UIPanelButtonTemplate")
    MoreButton:SetWidth(40)
    MoreButton:SetHeight(20)
    MoreButton:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    MoreButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -40, -8)
    MoreButton:SetText("More")

    -- 添加分隔线
    local divider = valueWindow:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetTexCoord(0.81, 0.94, 0.5, 1)
    divider:SetVertexColor(0.5, 0.5, 0.5)
    divider:SetWidth(fwidth-10)
    divider:SetHeight(4)
    divider:SetPoint("TOP", valueWindow, "TOP", 0, -30)

    return valueWindow, MoreButton
end


function MPCreateMainFrame(addonname, fwidth, fheight, titlestr)


    local Mini,MoreButton = MPCreateMiniFrame(addonname.."Mini", 134, 250, titlestr)

    -- 创建主框架
    local valueWindow = CreateFrame("Frame", addonname, Mini)
    valueWindow:Hide()

    --tinsert(UISpecialFrames, addonname)

    -- 设置窗口基本属性
    valueWindow:SetWidth(fwidth)
    valueWindow:SetHeight(fheight)
    valueWindow:SetPoint("TOPRIGHT", Mini, "TOPRIGHT", fwidth, 0)
    valueWindow:SetFrameLevel(1)

    -- 创建Tooltip风格的背景和边框
    valueWindow:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    valueWindow:SetBackdropColor(0.1, 0.1, 0.2, 0.85)
    valueWindow:SetScale(0.9)

    -- 添加标题文字
    local title = valueWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", valueWindow, "TOP", 0, -11)
    title:SetText("更多设置")
    title:SetJustifyH("CENTER")

    local cr = valueWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cr:SetPoint("TOPLEFT", valueWindow, "TOPLEFT", 10, -12)
    cr:SetFont("Fonts\\FRIZQT__.TTF", 12)
    cr:SetText(MPLanguage.UI_AddonTitle)

    -- 添加标准关闭按钮
    local closeButton = CreateFrame("Button", nil, valueWindow, "UIPanelCloseButton")
    closeButton:SetWidth(32)
    closeButton:SetHeight(32)
    closeButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -5, -2)

    local addButton = CreateFrame("Button", nil, valueWindow, "UIPanelButtonTemplate")
    addButton:SetWidth(54)
    addButton:SetHeight(20)
    addButton:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    addButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -55, -8)
    addButton:SetText(MPLanguage.UI_Mon_ScaleUp)
    addButton:SetScript("OnClick", function(self)
        local parent = this:GetParent()
        local scale = parent:GetScale()+0.1
        if scale < 2.0 then
            parent:SetScale( scale )
            Mini:SetScale( scale )
        end
    end)

    local decButton = CreateFrame("Button", nil, valueWindow, "UIPanelButtonTemplate")
    decButton:SetWidth(54)
    decButton:SetHeight(20)
    decButton:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    decButton:SetPoint("TOPRIGHT", valueWindow, "TOPRIGHT", -115, -8)
    decButton:SetText(MPLanguage.UI_Mon_ScaleDown)
    decButton:SetScript("OnClick", function(self)
        local parent = this:GetParent()
        local scale = parent:GetScale()-0.1
        if scale > 0.3 then
            parent:SetScale( scale )
            Mini:SetScale( scale )
        end
    end)


    -- 添加分隔线
    local divider = valueWindow:CreateTexture(nil, "ARTWORK")
    divider:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
    divider:SetTexCoord(0.81, 0.94, 0.5, 1)
    divider:SetVertexColor(0.5, 0.5, 0.5)
    divider:SetWidth(fwidth-10)
    divider:SetHeight(4)
    divider:SetPoint("TOP", valueWindow, "TOP", 0, -30)

    MoreButton:SetScript("OnClick", function(self)
        if valueWindow:IsVisible() then
            valueWindow:Hide()
        else
            valueWindow:Show()
        end
    end)

    return Mini,valueWindow
end


function MPSKillButton(father, offset_y, icon, skillname)

    local MainButton = CreateFrame("Button", "MySkillButton", father, "ActionButtonTemplate")

    -- 设置按钮大小和位置
    MainButton:SetWidth(110)  -- 标准技能按钮大小
    MainButton:SetHeight(36)
    MainButton:SetPoint("TOPLEFT", father, "TOPLEFT", 12, offset_y)

    -- 设置技能图标
    MainButton.icon = MainButton:CreateTexture("MySkillButtonIcon", "BACKGROUND")
    MainButton.icon:SetWidth(32)
    MainButton.icon:SetHeight(32)
    MainButton.icon:SetPoint("TOPLEFT", MainButton, "TOPLEFT", 2, -2)
    MainButton.icon:SetTexture(icon) -- 替换为你想要的技能图标路径
    MainButton:SetAlpha(1.0)

    local texture_highlight = MainButton:CreateTexture(nil, "BACKGROUND")
    texture_highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture_highlight:SetAllPoints()
    texture_highlight:SetVertexColor(0.5, 0.5, 0.5, 0.1)

    -- 添加高亮效果
    MainButton:SetHighlightTexture(texture_highlight)--"Interface\\Buttons\\ButtonHilight-Square", "ADD")

    -- 添加按下效果
    local texture_pushed = MainButton:CreateTexture(nil, "BACKGROUND")
    texture_pushed:SetTexture("Interface\\Buttons\\WHITE8X8")
    texture_pushed:SetAllPoints()
    texture_pushed:SetVertexColor(1, 1, 1, 0.1)
    MainButton:SetPushedTexture(texture_pushed) --"Interface\\Buttons\\ButtonHilight-Square","ALPHAKEY")
    MainButton:SetNormalTexture("")
    

    -- 添加按钮文本(可选)
    MainButton.text = MainButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    MainButton.text:SetPoint("TOPLEFT", MainButton, "TOPLEFT", 40, -6)
    MainButton.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    MainButton.text:SetTextColor(1, 1, 1)
    MainButton.text:SetText(skillname)

    -- 添加按钮文本(可选)
    MainButton.state = MainButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    MainButton.state:SetPoint("TOPLEFT", MainButton, "TOPLEFT", 40, -21)
    MainButton.state:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    MainButton.state:SetTextColor(1, 1, 1)
    MainButton.state:SetText("|cFF77DD22开启|r")

    return MainButton
end

function MPSKillButtonClose(button, skillname)
    button.text:SetText("|cFFaaaaaa"..skillname.."|r")
    button.state:SetText("|cFF666666关闭|r")
    button.icon:SetAlpha(0.4)
end

function MPSKillButtonOpen(button, skillname)
    button.text:SetText("|cFFFFFFFF"..skillname.."|r")
    button.state:SetText("|cFF77DD22开启|r")
    button.icon:SetAlpha(1.0)
end


