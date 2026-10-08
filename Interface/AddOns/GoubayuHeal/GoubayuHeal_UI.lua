-- ============================================================
-- 文件名: GoubayuHeal_UI.lua
-- 功能: UI界面（Cat2风格，纯Lua，无XML）
--       包含主窗口、所有标签页（组合/设置/优先/团队/HOT/
--       复活/驱散/高级/使用说明）、拖拽卡片、下拉菜单、
--       图腾条、导入导出等全部界面元素
-- ============================================================

GoubayuHeal.UI = GoubayuHeal.UI or {}
local UI = GoubayuHeal.UI

-- ============================================================
-- 通用样式常量与工具函数
-- ============================================================

local FLAT_EDGE = { 0.35, 0.35, 0.35, 0.9 }
local FONT = "Fonts\\FRIZQT__.TTF"

-- 应用扁平深色背景（边框中性灰）
function UI.ApplyFlatBackdrop(frame, red, green, blue, alpha)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(red, green, blue, alpha)
    frame:SetBackdropBorderColor(FLAT_EDGE[1], FLAT_EDGE[2], FLAT_EDGE[3], FLAT_EDGE[4])
end

-- 创建带描边的文字
local function GoubayuHeal_UI_MakeFontString(parent, layer, size, r, g, b)
    local fs = parent:CreateFontString(nil, layer, "GameFontNormal")
    fs:SetFont(FONT, size, "OUTLINE")
    fs:SetTextColor(r, g, b)
    return fs
end

-- 设置悬停提示（使用插件自己的Tooltip，避免冲突）
function UI.SetTooltip(frame, title, description, anchoredRight)
    frame:SetScript("OnEnter", function()
        local tip = GoubayuHealDisplayTooltip
        if not tip or not frame:IsVisible() then
            return
        end
        -- 标题与描述都为空时不显示（空 tooltip 会渲染为一个空白小框）
        if (title == nil or title == "") and (description == nil or description == "") then
            return
        end
        tip:ClearLines()
        tip:SetOwner(frame, anchoredRight and "ANCHOR_RIGHT" or "ANCHOR_LEFT")
        tip:SetText(tostring(title or ""))
        if description and description ~= title then
            tip:AddLine(tostring(description), 0.82, 0.82, 0.82, 1)
        end
        tip:Show()
    end)
    frame:SetScript("OnLeave", function()
        if GoubayuHealDisplayTooltip then
            GoubayuHealDisplayTooltip:Hide()
        end
    end)
end

-- ============================================================
-- 自定义扁平按钮
-- ============================================================

local function GoubayuHeal_UI_CreateFlatButton(parent, name, width, height, text)
    local btn = CreateFrame("Button", name, parent)
    btn:SetWidth(width)
    btn:SetHeight(height)
    UI.ApplyFlatBackdrop(btn, 0.055, 0.055, 0.055, 0.98)

    local t = GoubayuHeal_UI_MakeFontString(btn, "OVERLAY", 10, 1, 1, 1)
    t:SetPoint("CENTER", btn, "CENTER", 0, 0)
    t:SetText(text or "")
    btn.text = t

    btn.SetText = function(self, value)
        self.text:SetText(value)
    end

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.32, 0.19, 0.02, 1)
        t:SetTextColor(1, 0.565, 0)
    end)

    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.055, 0.055, 0.055, 0.98)
        t:SetTextColor(1, 1, 1)
    end)

    btn:SetScript("OnMouseDown", function()
        btn:SetBackdropColor(0.02, 0.02, 0.02, 1)
        t:ClearAllPoints()
        t:SetPoint("CENTER", btn, "CENTER", 1, -1)
    end)

    btn:SetScript("OnMouseUp", function()
        btn:SetBackdropColor(0.32, 0.19, 0.02, 1)
        t:ClearAllPoints()
        t:SetPoint("CENTER", btn, "CENTER", 0, 0)
    end)

    return btn
end

-- ============================================================
-- 自定义开关（扁平化勾选框）
-- ============================================================

local function GoubayuHeal_UI_CreateToggle(parent, name, width, height)
    local sw = CreateFrame("Button", name, parent)
    sw:SetWidth(width or 40)
    sw:SetHeight(height or 20)
    sw.checked = false
    sw.disabled = false
    sw.disabledTip = nil

    local track = sw:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8X8")
    track:SetPoint("TOPLEFT", sw, "TOPLEFT", 1, -1)
    track:SetPoint("BOTTOMRIGHT", sw, "BOTTOMRIGHT", -1, 1)
    track:SetVertexColor(0.15, 0.15, 0.15, 1)

    local knob = sw:CreateTexture(nil, "OVERLAY")
    knob:SetTexture("Interface\\Buttons\\WHITE8X8")
    knob:SetWidth(14)
    knob:SetHeight(14)
    knob:SetPoint("LEFT", sw, "LEFT", 3, 0)
    knob:SetVertexColor(0.55, 0.55, 0.55, 1)

    local function RefreshSwitch(val)
        sw.checked = val and true or false
        if sw.disabled then
            track:SetVertexColor(0.10, 0.10, 0.10, 0.85)
            knob:SetVertexColor(0.22, 0.22, 0.22, 0.85)
        elseif sw.checked then
            track:SetVertexColor(0.78, 0.56, 0.25, 1)
            knob:SetVertexColor(0.90, 0.87, 0.80, 1)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", sw, "RIGHT", -3, 0)
        else
            track:SetVertexColor(0.15, 0.15, 0.15, 1)
            knob:SetVertexColor(0.55, 0.55, 0.55, 1)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", sw, "LEFT", 3, 0)
        end
    end

    sw.SetChecked = function(self, val)
        RefreshSwitch(val)
    end

    sw.GetChecked = function(self)
        return sw.checked
    end

    sw.SetDisabled = function(self, val)
        sw.disabled = val and true or false
        RefreshSwitch(sw.checked)
    end

    sw:SetScript("OnClick", function()
        if sw.disabled then
            return
        end
        sw.checked = not sw.checked
        RefreshSwitch(sw.checked)
        if sw.userOnClick then
            sw.userOnClick()
        end
    end)

    sw:SetScript("OnEnter", function()
        if sw.disabled then
            if sw.disabledTip then
                GameTooltip:SetOwner(sw, "ANCHOR_RIGHT")
                GameTooltip:SetText(sw.disabledTip, 0.9, 0.9, 0.9, 1, 1)
                GameTooltip:Show()
            end
            return
        end
        knob:SetVertexColor(1, 0.96, 0.88, 1)
        if sw.userOnEnter then
            sw.userOnEnter()
        end
    end)

    sw:SetScript("OnLeave", function()
        GameTooltip:Hide()
        RefreshSwitch(sw.checked)
    end)

    sw:SetScript("OnShow", function()
        if sw.userOnShow then
            sw.userOnShow()
        end
    end)

    UI.AllToggles = UI.AllToggles or {}
    table.insert(UI.AllToggles, sw)
    return sw
end

-- 供其他模块（如驱散职业开关）复用主框架同款开关样式 by 武藤纯子酱 2026.9.4
function UI.CreateSwitch(parent, name, width, height)
    return GoubayuHeal_UI_CreateToggle(parent, name, width, height)
end

-- ============================================================
-- 自定义扁平滑块
-- ============================================================

local function GoubayuHeal_UI_CreateSlider(parent, name, width, height, compact)
    local slider = CreateFrame("Slider", name, parent)
    local fh = height or 15
    if not compact and fh < 34 then
        fh = 34
    end
    slider:SetWidth(width or 150)
    slider:SetHeight(fh)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")

    local rail = slider:CreateTexture(nil, "BACKGROUND")
    rail:SetTexture("Interface\\Buttons\\WHITE8X8")
    rail:SetHeight(4)
    rail:SetPoint("LEFT", slider, "LEFT", 0, 0)
    rail:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    rail:SetPoint("CENTER", slider, "CENTER", 0, 0)
    rail:SetVertexColor(0.25, 0.25, 0.25, 0.8)

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    fill:SetHeight(4)
    fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    fill:SetPoint("CENTER", slider, "CENTER", 0, 0)
    fill:SetVertexColor(0.78, 0.56, 0.25, 1)

    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetWidth(14)
        thumb:SetHeight(14)
        thumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
    end

    local lowText = slider:CreateFontString(name .. "Low", "OVERLAY", "GameFontNormalSmall")
    lowText:SetTextColor(0.55, 0.55, 0.55)

    local highText = slider:CreateFontString(name .. "High", "OVERLAY", "GameFontNormalSmall")
    highText:SetTextColor(1, 1, 1)

    local text = slider:CreateFontString(name .. "Text", "OVERLAY", "GameFontNormalSmall")

    if compact then
        lowText:SetPoint("BOTTOMLEFT", slider, "BOTTOMLEFT", 0, -2)
        highText:SetPoint("BOTTOMRIGHT", slider, "BOTTOMRIGHT", 0, -2)
        text:SetPoint("BOTTOM", slider, "BOTTOM", 0, -2)
    else
        lowText:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
        highText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 4)
        text:SetPoint("BOTTOM", slider, "TOP", 0, 4)
    end

    slider.lowText = lowText
    slider.highText = highText
    slider.sliderText = text

    local function UpdateFill()
        local minV, maxV = slider:GetMinMaxValues()
        local v = slider:GetValue()
        local span = maxV - minV
        local ratio = 0
        if span > 0 then
            ratio = (v - minV) / span
        end
        if ratio < 0 then
            ratio = 0
        end
        if ratio > 1 then
            ratio = 1
        end
        local w = slider:GetWidth() - 14
        if w < 0 then
            w = 0
        end
        fill:SetWidth(w * ratio)
    end

    slider:SetScript("OnValueChanged", function()
        UpdateFill()
        if slider.userOnValueChanged then
            slider.userOnValueChanged()
        end
    end)

    slider:SetScript("OnShow", function()
        UpdateFill()
        if slider.userOnShow then
            slider.userOnShow()
        end
    end)

    UI.AllSliders = UI.AllSliders or {}
    table.insert(UI.AllSliders, slider)
    return slider
end

-- 滑块调整时同步方案独立配置（避免 UI 重开/切换方案时被旧值覆盖）
local function GoubayuHeal_UI_SavePerScheme(key, value)
    if not (GoubayuHeal.Config and GoubayuHeal.Config["per_scheme_enabled"] == 1
        and GoubayuHeal.current_class) then
        return
    end
    GoubayuHeal.Config["per_scheme"] = GoubayuHeal.Config["per_scheme"] or {}
    local ps = GoubayuHeal.Config["per_scheme"][GoubayuHeal.current_class]
    if not ps then
        ps = {}
        GoubayuHeal.Config["per_scheme"][GoubayuHeal.current_class] = ps
    end
    ps[key] = value
end

-- 判断鼠标是否位于指定框架内（拖拽检测用）
local function GoubayuHeal_UI_IsCursorInside(frame)
    if not frame or not frame:IsVisible() then
        return false
    end
    local scale = UIParent:GetScale()
    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale
    return x >= frame:GetLeft() and x <= frame:GetRight() and y >= frame:GetBottom() and y <= frame:GetTop()
end

-- ============================================================
-- 滚动区域创建
-- ============================================================

function UI.CreateScrollArea(parent, width, height)
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetWidth(width)
    scrollFrame:SetHeight(height)
    scrollFrame:EnableMouse(true)
    scrollFrame:EnableMouseWheel(true)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(width - 18)
    content:SetHeight(height)
    content:EnableMouse(true)

    local hitArea = content:CreateTexture(nil, "BACKGROUND")
    hitArea:SetAllPoints()
    hitArea:SetTexture("Interface\\Buttons\\WHITE8X8")
    hitArea:SetVertexColor(0, 0, 0, 0.01)

    content:SetScript("OnMouseDown", function() end)
    content:SetScript("OnMouseUp", function() end)

    scrollFrame:SetScrollChild(content)

    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation("VERTICAL")
    slider:SetWidth(10)
    slider:SetHeight(height)
    slider:SetFrameLevel(parent:GetFrameLevel() + 10)
    slider:SetMinMaxValues(0, 0)
    slider:SetValueStep(1)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8X8")
    track:SetAllPoints()
    track:SetVertexColor(0.05, 0.05, 0.05, 0.95)

    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    slider:SetScript("OnValueChanged", function()
        scrollFrame:SetVerticalScroll(arg1)
    end)

    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetWidth(10)
        thumb:SetHeight(34)
        thumb:SetVertexColor(0.90, 0.87, 0.80, 0.95)
    end

    scrollFrame:SetScript("OnMouseWheel", function()
        local value = scrollFrame:GetVerticalScroll() - arg1 * 60
        local minV, maxV = slider:GetMinMaxValues()
        if value < 0 then
            value = 0
        end
        if value > (maxV or 0) then
            value = maxV or 0
        end
        slider:SetValue(value)
        scrollFrame:SetVerticalScroll(value)
    end)

    return scrollFrame, content, slider
end

function UI.UpdateScrollBar(scrollFrame, slider, contentHeight)
    local maximum = contentHeight - scrollFrame:GetHeight()
    if maximum < 0 then
        maximum = 0
    end
    slider:SetMinMaxValues(0, maximum)
    if maximum <= 0 then
        slider:SetAlpha(0.25)
    else
        slider:SetAlpha(1)
    end
    slider:SetValue(scrollFrame:GetVerticalScroll())
end

-- ============================================================
-- Tooltip
-- ============================================================

GoubayuHeal_Tooltip = CreateFrame("GameTooltip", "GoubayuHealTooltip", UIParent,
    "GameTooltipTemplate")
GoubayuHeal_Tooltip:SetFrameStrata("TOOLTIP")
GoubayuHeal_Tooltip:SetClampedToScreen(true)
-- 查询tooltip全程透明（alpha=0）：它是离屏数据查询框，任何可见状态都是渲染残留
GoubayuHeal_Tooltip:SetAlpha(0)
GoubayuHeal_Tooltip:RegisterEvent("PLAYER_LOGIN")
GoubayuHeal_Tooltip:SetScript("OnEvent", function()
    GoubayuHeal_Tooltip:UnregisterEvent("PLAYER_LOGIN")
    GoubayuHeal_Tooltip:SetOwner(UIParent, "ANCHOR_NONE")
end)

-- 专用悬浮显示框：与查询框彻底分离。
-- 原因：此前显示(UI.SetTooltip, alpha=1)与后台数据查询(ClearTooltip, alpha=0)
-- 共用 GoubayuHeal_Tooltip，悬停控件期间查询周期性地把它清空/透明化，
-- 随后悬停路径又 SetAlpha(1)+Show → 以查询频率"显示一下又消失"的闪烁。
-- 分离后查询永不影响显示框，显示框仅由 OnEnter/OnLeave 控制。
GoubayuHealDisplayTooltip = CreateFrame("GameTooltip", "GoubayuHealDisplayTooltip", UIParent,
    "GameTooltipTemplate")
GoubayuHealDisplayTooltip:SetFrameStrata("TOOLTIP")
GoubayuHealDisplayTooltip:SetClampedToScreen(true)

-- ============================================================
-- 主事件帧
-- ============================================================

local mainFrame = CreateFrame("Frame", "GoubayuHealMainFrame", UIParent)
mainFrame:SetScript("OnEvent", function()
    GoubayuHeal.OnEvent()
end)

mainFrame:SetScript("OnUpdate", function()
    GoubayuHeal.OnUpdate(arg1)
end)

if GoubayuHeal.OnLoad then
    local oldThis = this
    this = mainFrame
    GoubayuHeal.OnLoad()
    this = oldThis
end

-- ============================================================
-- 自定义下拉菜单
-- ============================================================

function UI.CreateDropDown(parent, width, getEntries, onSelect)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(24)
    UI.ApplyFlatBackdrop(button, 0.07, 0.07, 0.07, 0.98)

    local text = GoubayuHeal_UI_MakeFontString(button, "OVERLAY", 10, 0.72, 0.72, 0.72)
    text:SetPoint("LEFT", button, "LEFT", 8, 0)
    text:SetWidth(width - 26)
    text:SetJustifyH("LEFT")

    local arrow = GoubayuHeal_UI_MakeFontString(button, "OVERLAY", 11, 1, 0.565, 0)
    arrow:SetPoint("RIGHT", button, "RIGHT", -7, 1)
    arrow:SetText("v")

    local menu = CreateFrame("Frame", nil, UIParent)
    menu:SetWidth(width + 4)
    menu:SetHeight(200)
    menu:SetFrameStrata("DIALOG")
    menu:SetFrameLevel(60)
    menu:EnableMouse(true)
    -- 1.12 必须显式 EnableMouseWheel(true) 才能收到滚轮事件：此前缺失导致
    -- 超过 maxVisible(9) 的列表第 10 项起永远无法滚动选择 by 武藤纯子酱 2026.9.4
    menu:EnableMouseWheel(true)
    UI.ApplyFlatBackdrop(menu, 0.035, 0.035, 0.035, 1)
    menu:Hide()

    local entries = {}
    local entryHeight = 26
    local maxVisible = 9
    local scrollOffset = 0

    button.text = text
    button.menu = menu

    local function GoubayuHeal_RefreshMenu()
        local list = getEntries and getEntries() or {}
        local n = table.getn(list)

        while n > table.getn(entries) do
            local idx = table.getn(entries) + 1
            local entry = CreateFrame("Button", nil, menu)
            entry:SetWidth(width - 2)
            entry:SetHeight(entryHeight)
            entry:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1 - (idx - 1) * entryHeight)
            entry:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            -- 悬停在条目上时滚轮事件发给条目，需同样开启（否则只能对着菜单缝隙滚动）
            -- by 武藤纯子酱 2026.9.4
            entry:EnableMouseWheel(true)

            local highlight = entry:CreateTexture(nil, "BACKGROUND")
            highlight:SetAllPoints()
            highlight:SetTexture("Interface\\Buttons\\WHITE8X8")
            highlight:SetVertexColor(0.32, 0.19, 0.02, 0.55)
            highlight:Hide()

            local t = GoubayuHeal_UI_MakeFontString(entry, "OVERLAY", 10, 1, 1, 1)
            t:SetPoint("LEFT", entry, "LEFT", 7, 0)
            t:SetWidth(width - 18)
            t:SetJustifyH("LEFT")

            entry.highlight = highlight
            entry.t = t

            entry:SetScript("OnEnter", function()
                this.highlight:Show()
            end)

            entry:SetScript("OnLeave", function()
                this.highlight:Hide()
            end)

            entry:SetScript("OnMouseWheel", function()
                local delta = arg1 or 0
                local list = getEntries and getEntries() or {}
                local count = table.getn(list)
                local visible = count
                if visible > maxVisible then
                    visible = maxVisible
                end
                local maxScroll = count - visible
                if maxScroll < 0 then
                    maxScroll = 0
                end
                scrollOffset = scrollOffset + delta
                if scrollOffset > maxScroll then
                    scrollOffset = maxScroll
                end
                if scrollOffset < 0 then
                    scrollOffset = 0
                end
                GoubayuHeal_RefreshMenu()
            end)

            entry:SetScript("OnClick", function()
                local info = this.info
                menu:Hide()
                if onSelect and info then
                    onSelect(info.text, arg1, info)
                end
            end)

            table.insert(entries, entry)
        end

        local count = table.getn(list)
        local visible = count
        if visible > maxVisible then
            visible = maxVisible
        end
        local maxScroll = count - visible
        if maxScroll < 0 then
            maxScroll = 0
        end
        if scrollOffset > maxScroll then
            scrollOffset = maxScroll
        end
        if scrollOffset < 0 then
            scrollOffset = 0
        end

        menu:SetHeight(visible * entryHeight + 4)

        for i, entry in ipairs(entries) do
            if i <= count and i > scrollOffset and i <= scrollOffset + visible then
                local info = list[i]
                entry.info = info
                entry.t:SetText(info.text)
                if info.color then
                    entry.t:SetTextColor(info.color[1], info.color[2], info.color[3])
                else
                    entry.t:SetTextColor(1, 1, 1)
                end
                entry:ClearAllPoints()
                entry:SetPoint("TOPLEFT", menu, "TOPLEFT", 1, -1 - (i - 1 - scrollOffset) * entryHeight)
                entry:Show()
            else
                entry:Hide()
            end
        end
    end

    button.GoubayuHeal_RefreshMenu = GoubayuHeal_RefreshMenu

    menu:SetScript("OnMouseWheel", function()
        local delta = arg1 or 0
        local list = getEntries and getEntries() or {}
        local count = table.getn(list)
        local visible = count
        if visible > maxVisible then
            visible = maxVisible
        end
        local maxScroll = count - visible
        if maxScroll < 0 then
            maxScroll = 0
        end
        scrollOffset = scrollOffset + delta
        if scrollOffset > maxScroll then
            scrollOffset = maxScroll
        end
        if scrollOffset < 0 then
            scrollOffset = 0
        end
        GoubayuHeal_RefreshMenu()
    end)

    button:SetScript("OnEnter", function()
        this:SetBackdropColor(0.32, 0.19, 0.02, 1)
    end)

    button:SetScript("OnLeave", function()
        this:SetBackdropColor(0.07, 0.07, 0.07, 0.98)
    end)

    button:SetScript("OnClick", function()
        if menu:IsVisible() then
            menu:Hide()
            return
        end
        scrollOffset = 0
        GoubayuHeal_RefreshMenu()
        menu:ClearAllPoints()

        local bBottom = button:GetBottom()
        local menuH = menu:GetHeight()
        if bBottom and (bBottom - menuH - 2) < 0 then
            menu:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 0, 2)
        else
            menu:SetPoint("TOPLEFT", button, "BOTTOMLEFT", 0, -2)
        end
        menu:Show()
    end)

    button.SetText = function(self, value, color)
        text:SetText(value or "")
        if color then
            text:SetTextColor(color[1], color[2], color[3])
        else
            text:SetTextColor(0.72, 0.72, 0.72)
        end
    end

    button.HideMenu = function()
        menu:Hide()
    end

    UI.DropDowns = UI.DropDowns or {}
    table.insert(UI.DropDowns, button)

    return button
end

-- ============================================================
-- 隐藏所有弹出菜单
-- ============================================================

function UI.HideAllMenus()
    if UI.DropDowns then
        for _, btn in ipairs(UI.DropDowns) do
            if btn.HideMenu then
                btn.HideMenu()
            end
        end
    end
    if GoubayuHeal_GUIRoleMenu then
        GoubayuHeal_GUIRoleMenu:Hide()
    end
    if GoubayuHeal_GUIHotMenu then
        GoubayuHeal_GUIHotMenu:Hide()
    end
end

-- ============================================================
-- 法术选择弹窗
-- ============================================================

GoubayuHeal_SpellSelectPopUpFrame = CreateFrame("Frame", "GoubayuHeal_SpellSelectPopUpFrame",
    UIParent)
local popup = GoubayuHeal_SpellSelectPopUpFrame
popup:SetWidth(300)
popup:SetHeight(250)
popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
popup:SetFrameStrata("DIALOG")
popup:SetFrameLevel(50)
popup:SetMovable(true)
popup:SetClampedToScreen(true)
popup:EnableMouse(true)
UI.ApplyFlatBackdrop(popup, 0.055, 0.055, 0.055, 0.98)
popup:Hide()
tinsert(UISpecialFrames, "GoubayuHeal_SpellSelectPopUpFrame")

-- 标题
local popupTitle = GoubayuHeal_UI_MakeFontString(popup, "OVERLAY", 14, 1, 0.565, 0)
popupTitle:SetPoint("TOP", popup, "TOP", 0, -10)
popupTitle:SetText(GoubayuHeal.UI.SpellSelect)

-- 百分比滑块
local popupPercent = GoubayuHeal_UI_CreateSlider(popup, "GoubayuHeal_SpellSelectPopUpFramePercentSlider",
    200, 15)
popupPercent:SetPoint("TOP", popup, "TOP", 0, -48)
popupPercent:SetMinMaxValues(0, 100)
popupPercent:SetValueStep(1)
popupPercent:SetValue(50)
getglobal("GoubayuHeal_SpellSelectPopUpFramePercentSliderLow"):SetText("0%")
getglobal("GoubayuHeal_SpellSelectPopUpFramePercentSliderHigh"):SetText("50%")

local popupPercentHigh = getglobal("GoubayuHeal_SpellSelectPopUpFramePercentSliderHigh")
if popupPercentHigh then
    popupPercentHigh:ClearAllPoints()
    popupPercentHigh:SetPoint("LEFT", popupPercent, "RIGHT", 4, 0)
end

popupPercent.userOnValueChanged = function()
    getglobal("GoubayuHeal_SpellSelectPopUpFramePercentSliderHigh"):SetText(math.floor(arg1) .. "%")
end

-- 等级滑块
local popupRank = GoubayuHeal_UI_CreateSlider(popup, "GoubayuHeal_SpellSelectPopUpFrameRankSlider",
    200, 15)
popupRank:SetPoint("TOP", popup, "TOP", 0, -90)
popupRank:SetValueStep(1)
getglobal("GoubayuHeal_SpellSelectPopUpFrameRankSliderLow"):SetText(GoubayuHeal.GUI_rank)

local popupRankHigh = getglobal("GoubayuHeal_SpellSelectPopUpFrameRankSliderHigh")
if popupRankHigh then
    popupRankHigh:ClearAllPoints()
    popupRankHigh:SetPoint("LEFT", popupRank, "RIGHT", 4, 0)
end

popupRank.userOnValueChanged = function()
    getglobal("GoubayuHeal_SpellSelectPopUpFrameRankSliderHigh"):SetText(math.floor(arg1))
end

-- 缩放复选框
local popupScale = GoubayuHeal_UI_CreateToggle(popup, "GoubayuHeal_SpellSelectPopUpFrameScaleCheckBox",
    40, 20)
popupScale:SetPoint("TOPLEFT", popup, "TOPLEFT", 30, -126)

local popupScaleLabel = GoubayuHeal_UI_MakeFontString(popup, "OVERLAY", 10, 1, 1, 1)
popupScaleLabel:SetPoint("LEFT", popupScale, "RIGHT", 4, 0)
popupScaleLabel:SetText(GoubayuHeal.UI.AutoScaleRank)

-- 挂接法术下拉
local function GoubayuHeal_UI_GetAvailableAttachments()
    local list = {}
    local learned = {}
    local spellid = 1
    local spellname = GetSpellName(spellid, BOOKTYPE_SPELL)

    while spellname do
        learned[spellname] = true
        spellid = spellid + 1
        spellname = GetSpellName(spellid, BOOKTYPE_SPELL)
    end

    for spell, one in GoubayuHeal.attachment_spells do
        if learned[spell] then
            table.insert(list, spell)
        end
    end

    for _, spell in ipairs({
        GoubayuHeal.Holy_nova,
        GoubayuHeal.Prayer_of_healing,
        GoubayuHeal.Chain_heal
    }) do
        if learned[spell] then
            table.insert(list, spell)
        end
    end

    return list
end

local function GoubayuHeal_UI_GetAttachmentEntries()
    local list = { { text = GoubayuHeal.UI.None, color = { 0.6, 0.6, 0.6 } } }
    local attachments = GoubayuHeal_UI_GetAvailableAttachments()

    for i, spell in ipairs(attachments) do
        table.insert(list, { text = spell, spell = spell, rank = nil })
    end

    return list
end

local popupAttachLabel = GoubayuHeal_UI_MakeFontString(popup, "OVERLAY", 10, 1, 1, 1)
popupAttachLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 30, -152)
popupAttachLabel:SetText(GoubayuHeal.UI.AttachSpellLabel)

local popupAttach
popupAttach = UI.CreateDropDown(popup, 150, function()
    return GoubayuHeal_UI_GetAttachmentEntries()
end, function(text, arg1, info)
    if text == GoubayuHeal.UI.None then
        popupAttach:SetText(text, { 0.6, 0.6, 0.6 })
        popupAttach.selected = nil
    elseif text and info then
        popupAttach:SetText(text)
        popupAttach.selected = { spell = info.spell, rank = info.rank }
    end
end)
popupAttach:SetPoint("TOPLEFT", popupAttachLabel, "TOPRIGHT", 8, 2)

-- 交替技能下拉（牧师专用）
GoubayuHeal.UI_alt_spells = {
    GoubayuHeal.Renew,
    GoubayuHeal.PriestHeal,
    GoubayuHeal.Flash_heal,
    GoubayuHeal.Greater_heal,
    GoubayuHeal.Lesser_heal
}

function GoubayuHeal.UI_GetAlternateEntries()
    local list = { { text = GoubayuHeal.UI.None, color = { 0.6, 0.6, 0.6 } } }
    local learned = {}
    local spellid = 1
    local spellname = GetSpellName(spellid, BOOKTYPE_SPELL)

    while spellname do
        learned[spellname] = true
        spellid = spellid + 1
        spellname = GetSpellName(spellid, BOOKTYPE_SPELL)
    end

    for _, spell in ipairs(GoubayuHeal.UI_alt_spells) do
        if learned[spell] then
            table.insert(list, { text = spell, spell = spell })
        end
    end

    return list
end

popup.altLabel = GoubayuHeal_UI_MakeFontString(popup, "OVERLAY", 10, 1, 1, 1)
popup.altLabel:SetPoint("TOPLEFT", popup, "TOPLEFT", 30, -178)
popup.altLabel:SetText(GoubayuHeal.UI.AltSpellLabel)

GoubayuHeal.popupAlternate = UI.CreateDropDown(popup, 150, function()
    return GoubayuHeal.UI_GetAlternateEntries()
end, function(text, arg1, info)
    if text == GoubayuHeal.UI.None then
        GoubayuHeal.popupAlternate:SetText(text, { 0.6, 0.6, 0.6 })
        GoubayuHeal.popupAlternate.selected = nil
    elseif text and info then
        GoubayuHeal.popupAlternate:SetText(text)
        GoubayuHeal.popupAlternate.selected = info.spell
    end
end)
GoubayuHeal.popupAlternate:SetPoint("TOPLEFT", popup.altLabel, "TOPRIGHT", 8, 2)

-- 确定/取消
local popupOK = GoubayuHeal_UI_CreateFlatButton(popup,
    "GoubayuHeal_SpellSelectPopUpFrameButtonOK", 90, 24, GoubayuHeal.UI.OK)
popupOK:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 24, 14)
UI.SetTooltip(popupOK, GoubayuHeal.UI.OK, GoubayuHeal.UI.OKTip, true)

local popupCancel = GoubayuHeal_UI_CreateFlatButton(popup,
    "GoubayuHeal_SpellSelectPopUpFrameButtonCancel", 90, 24, GoubayuHeal.UI.Cancel)
popupCancel:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -24, 14)
UI.SetTooltip(popupCancel, GoubayuHeal.UI.Cancel, nil, true)

popup:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
        this:StartMoving()
    end
end)

popup:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
end)

local popupState = nil

function GoubayuHeal_GetFreeFlowPercent(cfg)
    local used = {}
    if cfg then
        for p, d in pairs(cfg) do
            if type(d) == "table" and d["Spell"] then
                used[p] = true
            end
        end
    end

    for i = 19, 1, -1 do
        local p = i * 5
        if not used[p] then
            return p
        end
    end

    return nil
end

function UI.OpenSpellPicker(spellName, editPercent)
    if not spellName or not GoubayuHeal.Spells or not GoubayuHeal.Spells[spellName] then
        return
    end

    local maxRank = table.getn(GoubayuHeal.Spells[spellName])
    popupTitle:SetText(spellName)
    popupRank:SetMinMaxValues(1, maxRank)
    popupState = { spell = spellName, percent = editPercent, edit = (editPercent ~= nil) }

    if editPercent then
        local cfg = GoubayuHeal.Config["classes"][GoubayuHeal.current_class]
        local entry = cfg and cfg[editPercent] or nil
        local rank = 1
        local scale = 0
        local attachment = nil

        if entry then
            rank = entry["Rank"] or 1
            scale = entry["Scale"] or 0
            attachment = entry["Attachment"]
        end

        if rank < 1 then
            rank = 1
        end
        if rank > maxRank then
            rank = maxRank
        end

        popupPercent:SetValue(editPercent)
        popupRank:SetValue(rank)
        popupScale:SetChecked(scale == 1 or scale == true)
        popupAttach:SetText(GoubayuHeal.UI.None, { 0.6, 0.6, 0.6 })
        popupAttach.selected = nil
        GoubayuHeal.popupAlternate:SetText(GoubayuHeal.UI.None, { 0.6, 0.6, 0.6 })
        GoubayuHeal.popupAlternate.selected = nil

        local alternateSpell = entry and entry["Alternate"]
        if alternateSpell then
            GoubayuHeal.popupAlternate:SetText(alternateSpell)
            GoubayuHeal.popupAlternate.selected = alternateSpell
        end

        if attachment then
            local wantRank = entry["AttachmentRank"]
            if not wantRank and GoubayuHeal.Spells and GoubayuHeal.Spells[attachment] then
                wantRank = table.getn(GoubayuHeal.Spells[attachment])
            end

            local attList = GoubayuHeal_UI_GetAttachmentEntries()
            for i, info in ipairs(attList) do
                if info.spell == attachment and (info.rank == nil
                    or (info.rank or 0) == (wantRank or 0)) then
                    popupAttach:SetText(info.text, info.color)
                    popupAttach.selected = { spell = info.spell, rank = wantRank }
                    break
                end
            end
        end
    else
        local cfg = GoubayuHeal.Config and GoubayuHeal.Config["classes"]
            and GoubayuHeal.Config["classes"][GoubayuHeal.current_class]
        local freePct = GoubayuHeal_GetFreeFlowPercent(cfg)
        popupPercent:SetValue(freePct or 50)
        popupRank:SetValue(maxRank)
        popupScale:SetChecked(false)
        popupAttach:SetText(GoubayuHeal.UI.None, { 0.6, 0.6, 0.6 })
        popupAttach.selected = nil
        GoubayuHeal.popupAlternate:SetText(GoubayuHeal.UI.None, { 0.6, 0.6, 0.6 })
        GoubayuHeal.popupAlternate.selected = nil
    end

    getglobal("GoubayuHeal_SpellSelectPopUpFramePercentSliderHigh"):SetText(
        math.floor(popupPercent:GetValue()) .. "%")
    getglobal("GoubayuHeal_SpellSelectPopUpFrameRankSliderHigh"):SetText(
        math.floor(popupRank:GetValue()))

    local showAlt = (GoubayuHeal.my_class == GoubayuHeal.Priest)
        and (GoubayuHeal.Config and GoubayuHeal.Config["priest_alternate_spells"] == 1)

    if popup.altLabel then
        if showAlt then
            popup.altLabel:Show()
        else
            popup.altLabel:Hide()
        end
    end
    if GoubayuHeal.popupAlternate then
        if showAlt then
            GoubayuHeal.popupAlternate:Show()
        else
            GoubayuHeal.popupAlternate:Hide()
        end
    end

    popup:Show()
end

local function GoubayuHeal_UI_IsGroupSpell(s)
    return s == GoubayuHeal.Holy_nova or s == GoubayuHeal.Prayer_of_healing
        or s == GoubayuHeal.Chain_heal
end

popupOK:SetScript("OnClick", function()
    if not popupState or not GoubayuHeal.current_class
        or not GoubayuHeal.Config["classes"] then
        popup:Hide()
        return
    end

    local spell = popupState.spell
    local percent = math.floor(popupPercent:GetValue())
    local rank = math.floor(popupRank:GetValue())
    local scale = popupScale:GetChecked() and 1 or 0
    local attachment = popupAttach.selected and popupAttach.selected.spell
    local attachmentRank = popupAttach.selected and popupAttach.selected.rank
    local alternate = GoubayuHeal.popupAlternate and GoubayuHeal.popupAlternate.selected

    local cfg = GoubayuHeal.Config["classes"][GoubayuHeal.current_class]
    if not cfg then
        cfg = {}
        GoubayuHeal.Config["classes"][GoubayuHeal.current_class] = cfg
    end

    if popupState.edit and popupState.percent then
        if popupState.percent ~= percent then
            cfg[popupState.percent] = nil
        end
        cfg[percent] = {
            Spell = spell,
            Rank = rank,
            Scale = scale,
            Attachment = attachment,
            AttachmentRank = attachmentRank,
            Alternate = alternate
        }
    else
        local existing = cfg[percent]
        if not existing then
            cfg[percent] = {
                Spell = spell,
                Rank = rank,
                Scale = scale,
                Attachment = attachment,
                AttachmentRank = attachmentRank,
                Alternate = alternate
            }
        elseif GoubayuHeal.attachment_spells[spell] then
            existing["Attachment"] = spell
            existing["AttachmentRank"] = rank
        elseif GoubayuHeal_UI_IsGroupSpell(spell) then
            if GoubayuHeal_UI_IsGroupSpell(existing["Spell"]) then
                cfg[percent] = {
                    Spell = spell,
                    Rank = rank,
                    Scale = scale,
                    Attachment = attachment,
                    AttachmentRank = attachmentRank,
                    Alternate = alternate
                }
            else
                existing["Attachment"] = spell
                existing["AttachmentRank"] = rank
            end
        elseif GoubayuHeal_UI_IsGroupSpell(existing["Spell"]) then
            cfg[percent] = {
                Spell = spell,
                Rank = rank,
                Scale = scale,
                Attachment = existing["Spell"],
                AttachmentRank = existing["Rank"]
            }
        else
            cfg[percent] = {
                Spell = spell,
                Rank = rank,
                Scale = scale,
                Attachment = attachment,
                AttachmentRank = attachmentRank,
                Alternate = alternate
            }
        end
    end

    popup:Hide()
    if GoubayuHeal.ClassDropDownMenuUpdate then
        GoubayuHeal.ClassDropDownMenuUpdate(GoubayuHeal.current_class)
    end
end)

popupCancel:SetScript("OnClick", function()
    popup:Hide()
end)

-- ============================================================
-- 法术预估数据编辑框
-- ============================================================

local function GoubayuHeal_SpellDataDialog()
    GoubayuHeal_SpellDataFrame = CreateFrame("Frame", "GoubayuHeal_SpellDataFrame", UIParent)
    local sdf = GoubayuHeal_SpellDataFrame
    sdf:SetWidth(470)
    sdf:SetHeight(445)
    sdf:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    sdf:SetFrameStrata("DIALOG")
    sdf:SetFrameLevel(60)
    sdf:SetMovable(true)
    sdf:SetClampedToScreen(true)
    sdf:EnableMouse(true)
    UI.ApplyFlatBackdrop(sdf, 0.055, 0.055, 0.055, 0.98)
    sdf:Hide()
    tinsert(UISpecialFrames, "GoubayuHeal_SpellDataFrame")

    sdf:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then
            sdf:StartMoving()
        end
    end)

    sdf:SetScript("OnMouseUp", function()
        sdf:StopMovingOrSizing()
    end)

    local sdfTitle = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 14, 1, 0.565, 0)
    sdfTitle:SetPoint("TOP", sdf, "TOP", 0, -10)
    sdfTitle:SetText(GoubayuHeal.UI.EstTitle)

    -- 列标题
    local sdfColRank = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 11, 1, 0.565, 0)
    sdfColRank:SetPoint("TOPLEFT", sdf, "TOPLEFT", 24, -36)
    sdfColRank:SetText(GoubayuHeal.UI.ColRank)

    local sdfColHeal = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 11, 1, 1, 1)
    sdfColHeal:SetPoint("TOPLEFT", sdf, "TOPLEFT", 90, -36)
    sdfColHeal:SetText(GoubayuHeal.UI.ColHeal)

    local sdfColRatio = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 11, 1, 1, 1)
    sdfColRatio:SetPoint("TOPLEFT", sdf, "TOPLEFT", 220, -36)
    sdfColRatio:SetText(GoubayuHeal.UI.ColRatio)

    local sdfColScale = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 11, 1, 1, 1)
    sdfColScale:SetPoint("TOPLEFT", sdf, "TOPLEFT", 350, -36)
    sdfColScale:SetText(GoubayuHeal.UI.ColScale)

    local sdfHint = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 10, 0.6, 0.6, 0.6)
    sdfHint:SetPoint("TOPLEFT", sdf, "TOPLEFT", 24, -54)
    sdfHint:SetText(GoubayuHeal.UI.EstHint)

    local sdfScroll, sdfContent, sdfSlider = UI.CreateScrollArea(sdf, 430, 205)
    sdfScroll:SetPoint("TOPLEFT", sdf, "TOPLEFT", 20, -72)
    sdfSlider:SetPoint("TOPRIGHT", sdf, "TOPRIGHT", -10, -72)

    local sdfRows = {}
    local sdfSpell = nil
    local sdfData = nil
    local sdfWaitParse = false
    local sdfRescanLeft = 0
    local sdfRescanNext = 0

    local function sdfMakeEditBox(parent)
        local eb = CreateFrame("EditBox", nil, parent)
        eb:SetWidth(110)
        eb:SetHeight(22)
        eb:SetAutoFocus(false)
        eb:SetTextInsets(4, 4, 0, 0)
        UI.ApplyFlatBackdrop(eb, 0.025, 0.025, 0.025, 0.9)
        eb:SetFontObject(GameFontNormalSmall)
        eb:SetTextColor(1, 1, 1)
        return eb
    end

    local function sdfCommitField(rank, field, editbox)
        local txt = editbox:GetText() or ""
        txt = string.gsub(txt, "%s+", "")

        if txt == "" then
            if sdfData and sdfData[rank] then
                sdfData[rank][field] = nil
                if not next(sdfData[rank]) then
                    sdfData[rank] = nil
                end
            end
        else
            local num = tonumber(txt)
            if num then
                sdfData[rank] = sdfData[rank] or {}
                sdfData[rank][field] = num
            end
        end
    end

    local function sdfRefreshRow(row, rank)
        -- 优先显示本次会话已暂存（未点OK）的覆盖值，否则显示当前生效的基础值
        -- （此前恒显示基础值，输入后失焦编辑框会"跳回"，看起来像没保存）
        local ovr = sdfData and sdfData[rank]
        if ovr and ovr.Heal ~= nil then
            row.he:SetText(string.format("%.0f", tonumber(ovr.Heal) or 0))
        else
            local okH, vH = pcall(GoubayuHeal.GetSpellBaseHeal, sdfSpell, rank)
            row.he:SetText(string.format("%.0f", (okH and tonumber(vH)) or 0))
        end
        if ovr and ovr.Ratio ~= nil then
            row.re:SetText(string.format("%.3f", tonumber(ovr.Ratio) or 0))
        else
            local okR, vR = pcall(GoubayuHeal.GetSpellHealPowerRatio, sdfSpell, rank)
            row.re:SetText(string.format("%.3f", (okR and tonumber(vR)) or 0))
        end
        if ovr and ovr.Scale ~= nil then
            row.se:SetText(string.format("%.2f", tonumber(ovr.Scale) or 1))
        else
            local okS, vS = pcall(GoubayuHeal.GetSpellScale, sdfSpell, rank)
            row.se:SetText(string.format("%.2f", (okS and tonumber(vS)) or 1))
        end
    end

    local function sdfBuildRows(maxRank)
        while table.getn(sdfRows) < maxRank do
            local idx = table.getn(sdfRows) + 1
            local row = CreateFrame("Frame", nil, sdfContent)
            row:SetWidth(410)
            row:SetHeight(28)
            row:SetPoint("TOPLEFT", sdfContent, "TOPLEFT", 0, -2 - (idx - 1) * 30)

            local rl = GoubayuHeal_UI_MakeFontString(row, "OVERLAY", 11, 1, 1, 1)
            rl:SetPoint("LEFT", row, "LEFT", 4, 0)
            rl:SetWidth(50)

            local he = sdfMakeEditBox(row)
            he:SetPoint("LEFT", row, "LEFT", 68, 0)

            local re = sdfMakeEditBox(row)
            re:SetPoint("LEFT", row, "LEFT", 188, 0)

            local se = sdfMakeEditBox(row)
            se:SetPoint("LEFT", row, "LEFT", 318, 0)

            local r = idx

            he:SetScript("OnEditFocusLost", function()
                sdfCommitField(r, "Heal", he)
                sdfRefreshRow(row, r)
            end)

            he:SetScript("OnEnterPressed", function()
                sdfCommitField(r, "Heal", he)
                he:ClearFocus()
                sdfRefreshRow(row, r)
            end)

            re:SetScript("OnEditFocusLost", function()
                sdfCommitField(r, "Ratio", re)
                sdfRefreshRow(row, r)
            end)

            re:SetScript("OnEnterPressed", function()
                sdfCommitField(r, "Ratio", re)
                re:ClearFocus()
                sdfRefreshRow(row, r)
            end)

            se:SetScript("OnEditFocusLost", function()
                sdfCommitField(r, "Scale", se)
                sdfRefreshRow(row, r)
            end)

            se:SetScript("OnEnterPressed", function()
                sdfCommitField(r, "Scale", se)
                se:ClearFocus()
                sdfRefreshRow(row, r)
            end)

            row.rl = rl
            row.he = he
            row.re = re
            row.se = se
            table.insert(sdfRows, row)
        end
    end

    local function sdfRefresh()
        if not sdfSpell or not GoubayuHeal.Spells then
            return
        end

        local maxRank = table.getn(GoubayuHeal.Spells[sdfSpell])
        sdfBuildRows(maxRank)

        for i, row in ipairs(sdfRows) do
            if i <= maxRank then
                row.rl:SetText(GoubayuHeal.UI.RankPrefix .. i)
                sdfRefreshRow(row, i)
                row:Show()
            else
                row:Hide()
            end
        end

        local totalHeight = maxRank * 30 + 2
        sdfContent:SetHeight(totalHeight)

        if sdfSlider then
            local maximum = totalHeight - sdfScroll:GetHeight()
            if maximum < 0 then
                maximum = 0
            end
            sdfSlider:SetMinMaxValues(0, maximum)
            if maximum <= 0 then
                sdfSlider:SetAlpha(0.25)
            else
                sdfSlider:SetAlpha(1)
            end
        end
    end

    -- 基础值为0时打开窗口：开窗期间每2秒补扫一次默认数据（最多10次），扫到值立即刷新填写
    -- （窗口本地机制，不依赖全局解析完整性标记；必须放在 sdfRefresh 声明之后，闭包才能捕获局部变量）
    sdf:SetScript("OnUpdate", function()
        if not sdfWaitParse then
            return
        end
        local okH, vH = pcall(GoubayuHeal.GetSpellBaseHeal, sdfSpell, 1)
        if okH and (tonumber(vH) or 0) > 0 then
            -- 已扫到基础值：刷新一次并停止
            sdfWaitParse = false
            sdfRefresh()
            return
        end
        if GetTime() >= (sdfRescanNext or 0) then
            sdfRescanNext = GetTime() + 2
            if sdfRescanLeft <= 0 then
                sdfWaitParse = false
                return
            end
            sdfRescanLeft = sdfRescanLeft - 1
            if GoubayuHeal.SafeUpdateSpells then
                GoubayuHeal.SafeUpdateSpells()
            end
            sdfRefresh()
        end
    end)

    -- ============================================================
    -- 群疗条件覆盖（仅群疗技能显示：新星/祷言/神圣打击；治疗链不适用）
    -- 覆盖三要素：触发范围(码) / 触发人数 / 最小掉血量；留空=恢复默认
    -- ============================================================
    local AOE_OVERRIDE_SPELLS = {
        [GoubayuHeal.Holy_nova] = { range = 10, count = 5, missing = 300 },
        [GoubayuHeal.Prayer_of_healing] = { range = 30, count = 3, missing = 600 },
        [GoubayuHeal.Holy_Strike] = { range = 10, count = 3, missing = 200 },
    }
    sdf.aoeDefaults = nil

    local aoeTitle = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 11, 1, 0.565, 0)
    aoeTitle:SetPoint("TOPLEFT", sdf, "TOPLEFT", 24, -282)
    aoeTitle:SetText(GoubayuHeal.UI.AoeOverrideTitle)

    local aoeHint = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 10, 0.6, 0.6, 0.6)
    aoeHint:SetPoint("TOPLEFT", sdf, "TOPLEFT", 24, -298)
    aoeHint:SetText(GoubayuHeal.UI.AoeOverrideHint)

    local function sdfMakeNumBox(parent)
        local eb = sdfMakeEditBox(parent)
        eb:SetWidth(56)
        return eb
    end

    local aoeRangeLabel = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 10, 0.85, 0.85, 0.85)
    aoeRangeLabel:SetPoint("TOPLEFT", sdf, "TOPLEFT", 24, -318)
    aoeRangeLabel:SetText(GoubayuHeal.UI.AoeRangeLabel)

    local aoeRangeBox = sdfMakeNumBox(sdf)
    aoeRangeBox:SetPoint("LEFT", aoeRangeLabel, "RIGHT", 6, 0)

    local aoeCountLabel = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 10, 0.85, 0.85, 0.85)
    aoeCountLabel:SetPoint("LEFT", aoeRangeBox, "RIGHT", 14, 0)
    aoeCountLabel:SetText(GoubayuHeal.UI.AoeCountLabel)

    local aoeCountBox = sdfMakeNumBox(sdf)
    aoeCountBox:SetPoint("LEFT", aoeCountLabel, "RIGHT", 6, 0)

    local aoeMissingLabel = GoubayuHeal_UI_MakeFontString(sdf, "OVERLAY", 10, 0.85, 0.85, 0.85)
    aoeMissingLabel:SetPoint("LEFT", aoeCountBox, "RIGHT", 14, 0)
    aoeMissingLabel:SetText(GoubayuHeal.UI.AoeMissingLabel)

    local aoeMissingBox = sdfMakeNumBox(sdf)
    aoeMissingBox:SetPoint("LEFT", aoeMissingLabel, "RIGHT", 6, 0)

    local aoeReset = GoubayuHeal_UI_CreateFlatButton(sdf, nil, 70, 20, GoubayuHeal.UI.Reset)
    aoeReset:SetPoint("LEFT", aoeMissingBox, "RIGHT", 14, 3)

    -- 数值提交：空=恢复默认；非法输入恢复显示默认值
    local function aoeCommit(box, key)
        local txt = string.gsub(box:GetText() or "", "%s+", "")
        if txt == "" then
            if sdf.aoeDefaults then
                box:SetText(string.format("%.0f", sdf.aoeDefaults[key] or 0))
            end
            if GoubayuHeal.Config and GoubayuHeal.Config["aoe_condition_override"]
                and GoubayuHeal.Config["aoe_condition_override"][sdfSpell] then
                GoubayuHeal.Config["aoe_condition_override"][sdfSpell][key] = nil
            end
            return
        end
        local num = tonumber(txt)
        if not num then
            if sdf.aoeDefaults then
                box:SetText(string.format("%.0f", sdf.aoeDefaults[key] or 0))
            end
            return
        end
        GoubayuHeal.Config["aoe_condition_override"] =
            GoubayuHeal.Config["aoe_condition_override"] or {}
        GoubayuHeal.Config["aoe_condition_override"][sdfSpell] =
            GoubayuHeal.Config["aoe_condition_override"][sdfSpell] or {}
        GoubayuHeal.Config["aoe_condition_override"][sdfSpell][key] = num
    end

    local function aoeFill()
        local ovr = GoubayuHeal.Config and GoubayuHeal.Config["aoe_condition_override"]
            and GoubayuHeal.Config["aoe_condition_override"][sdfSpell]
        aoeRangeBox:SetText(string.format("%.0f",
            (ovr and ovr.range) or (sdf.aoeDefaults and sdf.aoeDefaults.range) or 0))
        aoeCountBox:SetText(string.format("%.0f",
            (ovr and ovr.count) or (sdf.aoeDefaults and sdf.aoeDefaults.count) or 0))
        aoeMissingBox:SetText(string.format("%.0f",
            (ovr and ovr.missing) or (sdf.aoeDefaults and sdf.aoeDefaults.missing) or 0))
    end

    aoeRangeBox:SetScript("OnEnterPressed", function()
        aoeCommit(aoeRangeBox, "range")
        aoeFill()
        aoeRangeBox:ClearFocus()
    end)
    aoeCountBox:SetScript("OnEnterPressed", function()
        aoeCommit(aoeCountBox, "count")
        aoeFill()
        aoeCountBox:ClearFocus()
    end)
    aoeMissingBox:SetScript("OnEnterPressed", function()
        aoeCommit(aoeMissingBox, "missing")
        aoeFill()
        aoeMissingBox:ClearFocus()
    end)

    -- 失焦即提交（点其他输入框/空白时落盘）；点“取消”关闭时被 sdfCancel 置 false，不落盘
    aoeRangeBox:SetScript("OnEditFocusLost", function()
        if sdf._aoeFocusOK then
            aoeCommit(aoeRangeBox, "range")
            aoeFill()
        end
    end)
    aoeCountBox:SetScript("OnEditFocusLost", function()
        if sdf._aoeFocusOK then
            aoeCommit(aoeCountBox, "count")
            aoeFill()
        end
    end)
    aoeMissingBox:SetScript("OnEditFocusLost", function()
        if sdf._aoeFocusOK then
            aoeCommit(aoeMissingBox, "missing")
            aoeFill()
        end
    end)

    aoeReset:SetScript("OnClick", function()
        if GoubayuHeal.Config and GoubayuHeal.Config["aoe_condition_override"] then
            GoubayuHeal.Config["aoe_condition_override"][sdfSpell] = nil
        end
        aoeFill()
    end)

    -- 群疗技能才显示覆盖区；其余技能隐藏
    function GoubayuHeal_SpellDataFrame_AoeSectionShow(show)
        local vis = show and AOE_OVERRIDE_SPELLS[sdfSpell] ~= nil
        if vis then
            aoeTitle:Show()
            aoeHint:Show()
            aoeRangeLabel:Show()
            aoeRangeBox:Show()
            aoeCountLabel:Show()
            aoeCountBox:Show()
            aoeMissingLabel:Show()
            aoeMissingBox:Show()
            aoeReset:Show()
        else
            aoeTitle:Hide()
            aoeHint:Hide()
            aoeRangeLabel:Hide()
            aoeRangeBox:Hide()
            aoeCountLabel:Hide()
            aoeCountBox:Hide()
            aoeMissingLabel:Hide()
            aoeMissingBox:Hide()
            aoeReset:Hide()
        end
    end

    local sdfReset = GoubayuHeal_UI_CreateFlatButton(sdf, nil, 90, 24, GoubayuHeal.UI.Reset)
    sdfReset:SetPoint("BOTTOMLEFT", sdf, "BOTTOMLEFT", 20, 14)
    sdfReset:SetScript("OnClick", function()
        if not sdfSpell then
            return
        end
        sdfData = {}
        -- 同时清除该技能已保存的手动覆盖（否则旧的0值存档会让基础值永远显示0）
        if GoubayuHeal.ResetSpellOverride then
            GoubayuHeal.ResetSpellOverride(sdfSpell)
        end
        sdfRefresh()
    end)

    local sdfOK = GoubayuHeal_UI_CreateFlatButton(sdf, nil, 90, 24, GoubayuHeal.UI.OK)
    sdfOK:SetPoint("BOTTOMRIGHT", sdf, "BOTTOMRIGHT", -110, 14)
    sdfOK:SetScript("OnClick", function()
        -- 先提交群疗条件覆盖区三个输入框：此前仅在框内回车才提交，
        -- 直接点“确认”不落盘导致重开仍显示默认 by 武藤纯子酱 2026.9.6
        if sdfSpell and sdf.aoeDefaults then
            aoeCommit(aoeRangeBox, "range")
            aoeCommit(aoeCountBox, "count")
            aoeCommit(aoeMissingBox, "missing")
        end
        if sdfSpell and GoubayuHeal.Config then
            GoubayuHeal.Config["spell_data_override"] = GoubayuHeal.Config[
                "spell_data_override"] or {}
            local saved = {}
            for rank, fields in pairs(sdfData) do
                saved[rank] = fields
            end
            GoubayuHeal.Config["spell_data_override"][sdfSpell] = saved
            GoubayuHeal.Print(string.format(GoubayuHeal.UI.EstSavedFmt, sdfSpell))
        end
        sdf:Hide()
    end)

    local sdfCancel = GoubayuHeal_UI_CreateFlatButton(sdf, nil, 90, 24, GoubayuHeal.UI.Cancel)
    sdfCancel:SetPoint("BOTTOMRIGHT", sdf, "BOTTOMRIGHT", -20, 14)
    sdfCancel:SetScript("OnClick", function()
        -- 取消：放弃本次改动，关闭后失焦提交不再落盘（下一次打开由 OpenSpellDataEditor 复位 _aoeFocusOK）
        sdf._aoeFocusOK = false
        sdf:Hide()
    end)

    function GoubayuHeal.OpenSpellDataEditor(spell)
        if not spell or not GoubayuHeal.Spells or not GoubayuHeal.Spells[spell] then
            return
        end

        -- 无治疗加成的技能不弹预估编辑框（自然迅捷/迅捷治愈/先祖迅捷/保护之手）
        if GoubayuHeal.no_editor_spells and GoubayuHeal.no_editor_spells[spell] then
            return
        end

        sdfSpell = spell
        sdfTitle:SetText(string.format(GoubayuHeal.UI.EstTitleFmt, spell))
        sdfData = {}
        sdf._aoeFocusOK = true

        -- 群疗条件覆盖：该技能有默认条件时显示覆盖区并填充（有存档用存档，否则用默认）
        sdf.aoeDefaults = AOE_OVERRIDE_SPELLS[spell]
        if GoubayuHeal_SpellDataFrame_AoeSectionShow then
            GoubayuHeal_SpellDataFrame_AoeSectionShow(true)
        end
        if sdf.aoeDefaults then
            aoeFill()
        end

        local ovr = GoubayuHeal.Config and GoubayuHeal.Config["spell_data_override"]
            and GoubayuHeal.Config["spell_data_override"][spell]
        if ovr then
            for rank, fields in pairs(ovr) do
                sdfData[rank] = {}
                for k, v in pairs(fields) do
                    sdfData[rank][k] = v
                end
            end
        end

        sdfRefresh()
        -- 基础值为0（法术书解析未就绪）：立即同步重扫一次并刷新；若仍为0，开窗期间每2秒继续补扫
        local sd1 = GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][1]
        local hasBase = sd1 and ((sd1["Heal"] or 0) > 0 or (sd1["HealMin"] or 0) > 0
            or (sd1["HealMax"] or 0) > 0 or (sd1["HealingOverTime"] or 0) > 0
            or (sd1["Absorb"] or 0) > 0)
        if not hasBase then
            if GoubayuHeal.SafeUpdateSpells then
                GoubayuHeal.SafeUpdateSpells()
            end
            sdfRefresh()
            sdfWaitParse = true
            sdfRescanLeft = 10
            sdfRescanNext = GetTime() + 2
        else
            sdfWaitParse = false
        end
        sdf:Show()
    end
end

GoubayuHeal_SpellDataDialog()

-- ============================================================
-- 文本输入框（新建方案/档案）
-- ============================================================

GoubayuHeal_GUITextBox = CreateFrame("Frame", "GoubayuHeal_GUITextBox", UIParent)
local textBox = GoubayuHeal_GUITextBox
textBox:SetWidth(300)
textBox:SetHeight(190)
textBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
textBox:SetFrameStrata("DIALOG")
textBox:SetFrameLevel(50)
textBox:SetMovable(true)
textBox:SetClampedToScreen(true)
textBox:EnableMouse(true)
UI.ApplyFlatBackdrop(textBox, 0.055, 0.055, 0.055, 0.98)
textBox:Hide()
tinsert(UISpecialFrames, "GoubayuHeal_GUITextBox")

local textBoxTitle = GoubayuHeal_UI_MakeFontString(textBox, "OVERLAY", 12, 1, 0.565, 0)
textBoxTitle:SetPoint("TOP", textBox, "TOP", 0, -12)
textBoxTitle:SetText(GoubayuHeal.GUI_new_class)

local textBoxEdit = CreateFrame("EditBox", "GoubayuHeal_GUITextBoxEditBox", textBox)
textBoxEdit:SetWidth(250)
textBoxEdit:SetHeight(24)
textBoxEdit:SetPoint("TOP", textBox, "TOP", 0, -40)
textBoxEdit:SetAutoFocus(false)
textBoxEdit:SetTextInsets(6, 6, 0, 0)
UI.ApplyFlatBackdrop(textBoxEdit, 0.04, 0.04, 0.04, 0.9)
textBoxEdit:SetFontObject(GameFontNormalSmall)

-- 复制来源方案下拉
GoubayuHeal.textBoxCopyLabel = GoubayuHeal_UI_MakeFontString(textBox, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.textBoxCopyLabel:SetPoint("TOPLEFT", textBox, "TOPLEFT", 24, -72)
GoubayuHeal.textBoxCopyLabel:SetText(GoubayuHeal.UI.CopySchemeLabel)

GoubayuHeal.copySchemeDropdown = UI.CreateDropDown(textBox, 180, function()
    local list = { { text = GoubayuHeal.UI.None, color = { 0.6, 0.6, 0.6 } } }
    if GoubayuHeal.Config and GoubayuHeal.Config["classes"] then
        for class, _ in GoubayuHeal.Config["classes"] do
            if not (string.find(class, "_D$") or string.find(class, "_S$")
                or string.find(class, "_T$") or string.find(class, "_Tank$")) then
                table.insert(list, { text = class })
            end
        end
    end
    return list
end, function(text, arg1, info)
    if text == GoubayuHeal.UI.None then
        GoubayuHeal.copySchemeDropdown:SetText(text, { 0.6, 0.6, 0.6 })
        GoubayuHeal.copySchemeDropdown.selected = nil
    elseif text and info then
        GoubayuHeal.copySchemeDropdown:SetText(text)
        GoubayuHeal.copySchemeDropdown.selected = text
    end
end)
GoubayuHeal.copySchemeDropdown:SetPoint("TOPLEFT", GoubayuHeal.textBoxCopyLabel, "TOPRIGHT", 8, -2)
GoubayuHeal.copySchemeDropdown:SetText(GoubayuHeal.UI.None, { 0.6, 0.6, 0.6 })
GoubayuHeal.copySchemeDropdown.selected = nil
UI.SetTooltip(GoubayuHeal.copySchemeDropdown, GoubayuHeal.UI.CopyScheme,
    GoubayuHeal.UI.CopySchemeTip)

local textBoxOK = GoubayuHeal_UI_CreateFlatButton(textBox, "GoubayuHeal_GUITextBoxButtonOK",
    90, 24, GoubayuHeal.UI.OK)
textBoxOK:SetPoint("BOTTOMLEFT", textBox, "BOTTOMLEFT", 24, 14)

local textBoxCancel = GoubayuHeal_UI_CreateFlatButton(textBox, "GoubayuHeal_GUITextBoxButtonCancel",
    90, 24, GoubayuHeal.UI.Cancel)
textBoxCancel:SetPoint("BOTTOMRIGHT", textBox, "BOTTOMRIGHT", -24, 14)

textBox:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
        this:StartMoving()
    end
end)

textBox:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
end)

textBoxOK:SetScript("OnClick", function()
    local t = textBoxEdit:GetText()
    if not t or t == "" then
        return
    end

    t = string.lower(t)
    if t == "load" or t == "save" or t == "delete" or t == "list" or t == "none" then
        GoubayuHeal.Print(GoubayuHeal.UI.BadClassName,
            "|cffff0000")
        return
    end

    if not GoubayuHeal.Config["classes"] then
        GoubayuHeal.Config["classes"] = {}
    end

    local copyFrom = GoubayuHeal.copySchemeDropdown and GoubayuHeal.copySchemeDropdown.selected

    if copyFrom and copyFrom ~= "" and GoubayuHeal.Config["classes"][copyFrom] then
        GoubayuHeal.Config["classes"][t] = GoubayuHeal.CopyTable(GoubayuHeal.Config["classes"][copyFrom])
    else
        GoubayuHeal.Config["classes"][t] = {}
    end

    if GoubayuHeal.Config["per_scheme_enabled"] == 1 and GoubayuHeal.Config["per_scheme"] then
        if copyFrom and copyFrom ~= "" and GoubayuHeal.Config["per_scheme"][copyFrom] then
            GoubayuHeal.Config["per_scheme"][t] = GoubayuHeal.CopyTable(
                GoubayuHeal.Config["per_scheme"][copyFrom])
        else
            local defs = GoubayuHeal.SchemeGetDefaults and GoubayuHeal.SchemeGetDefaults() or {}
            GoubayuHeal.Config["per_scheme"][t] = GoubayuHeal.CopyTable(defs)
        end
    end

    if GoubayuHeal.ClassDropDownMenuInitialize then
        GoubayuHeal.ClassDropDownMenuInitialize()
    end
    if GoubayuHeal.ClassDropDownMenuUpdate then
        GoubayuHeal.ClassDropDownMenuUpdate(t)
    end

    textBoxEdit:SetText("")
    textBox:Hide()
end)

textBoxCancel:SetScript("OnClick", function()
    textBoxEdit:SetText("")
    textBox:Hide()
end)

-- 档案名输入框
GoubayuHeal_GUIProfileTextBox = CreateFrame("Frame", "GoubayuHeal_GUIProfileTextBox", UIParent)
local profileBox = GoubayuHeal_GUIProfileTextBox
profileBox:SetWidth(260)
profileBox:SetHeight(140)
profileBox:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
profileBox:SetFrameStrata("DIALOG")
profileBox:SetFrameLevel(50)
profileBox:SetMovable(true)
profileBox:SetClampedToScreen(true)
profileBox:EnableMouse(true)
UI.ApplyFlatBackdrop(profileBox, 0.055, 0.055, 0.055, 0.98)
profileBox:Hide()
tinsert(UISpecialFrames, "GoubayuHeal_GUIProfileTextBox")

local profileBoxTitle = GoubayuHeal_UI_MakeFontString(profileBox, "OVERLAY", 12, 1, 0.565, 0)
profileBoxTitle:SetPoint("TOP", profileBox, "TOP", 0, -12)
profileBoxTitle:SetText(GoubayuHeal.GUI_new_profile)

local profileBoxEdit = CreateFrame("EditBox", "GoubayuHeal_GUIProfileTextBoxEditBox", profileBox)
profileBoxEdit:SetWidth(220)
profileBoxEdit:SetHeight(24)
profileBoxEdit:SetPoint("TOP", profileBox, "TOP", 0, -40)
profileBoxEdit:SetAutoFocus(false)
profileBoxEdit:SetTextInsets(6, 6, 0, 0)
UI.ApplyFlatBackdrop(profileBoxEdit, 0.04, 0.04, 0.04, 0.9)
profileBoxEdit:SetFontObject(GameFontNormalSmall)

local profileBoxOK = GoubayuHeal_UI_CreateFlatButton(profileBox,
    "GoubayuHeal_GUIProfileTextBoxButtonOK", 90, 24, GoubayuHeal.UI.OK)
profileBoxOK:SetPoint("BOTTOMLEFT", profileBox, "BOTTOMLEFT", 24, 14)

local profileBoxCancel = GoubayuHeal_UI_CreateFlatButton(profileBox,
    "GoubayuHeal_GUIProfileTextBoxButtonCancel", 90, 24, GoubayuHeal.UI.Cancel)
profileBoxCancel:SetPoint("BOTTOMRIGHT", profileBox, "BOTTOMRIGHT", -24, 14)

profileBox:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
        this:StartMoving()
    end
end)

profileBox:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
end)

profileBoxOK:SetScript("OnClick", function()
    local t = profileBoxEdit:GetText()
    if not t or t == "" then
        GoubayuHeal.Print(GoubayuHeal.UI.NoProfileName)
        return
    end

    t = string.lower(t)
    if t == "load" or t == "save" or t == "delete" or t == "list" or t == "none" then
        GoubayuHeal.Print(GoubayuHeal.UI.BadProfileName,
            "|cffff0000")
        return
    end

    if GoubayuHeal.Save_Profile then
        GoubayuHeal.Save_Profile(t)
        GoubayuHeal.Print(string.format(GoubayuHeal.UI.ProfileSavedFmt, t))
    end

    if GoubayuHeal.ProfileDropDownMenuInitialize then
        GoubayuHeal.ProfileDropDownMenuInitialize()
    end
    if GoubayuHeal.ProfileDropDownMenuUpdate then
        GoubayuHeal.ProfileDropDownMenuUpdate(t)
    end

    profileBoxEdit:SetText("")
    profileBox:Hide()
end)

profileBoxCancel:SetScript("OnClick", function()
    profileBoxEdit:SetText("")
    profileBox:Hide()
end)

-- ============================================================
-- 配置导入导出窗口
-- ============================================================

local transferWindow = nil
local transferEditBox = nil
local transferMode = nil
local transferProtectedText = ""

local function GoubayuHeal_UI_HideTransfer()
    if transferEditBox and transferEditBox.ClearFocus then
        transferEditBox:ClearFocus()
    end
    if transferWindow then
        transferWindow:Hide()
    end
end

local function GoubayuHeal_UI_SelectExportText()
    if not transferEditBox then
        return
    end
    transferEditBox:SetFocus()
    transferEditBox:HighlightText(0, string.len(transferEditBox:GetText()))
end

local function GoubayuHeal_UI_CreateTransferWindow()
    if transferWindow then
        return
    end

    transferWindow = CreateFrame("Frame", "GoubayuHeal_TransferWindow", UIParent)
    transferWindow:SetWidth(470)
    transferWindow:SetHeight(360)
    transferWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    transferWindow:SetFrameStrata("FULLSCREEN_DIALOG")
    transferWindow:SetFrameLevel(120)
    transferWindow:SetMovable(true)
    transferWindow:SetClampedToScreen(true)
    transferWindow:EnableMouse(true)
    transferWindow:RegisterForDrag("LeftButton")
    UI.ApplyFlatBackdrop(transferWindow, 0.04, 0.04, 0.04, 0.99)

    transferWindow:SetScript("OnDragStart", function()
        transferWindow:StartMoving()
    end)

    transferWindow:SetScript("OnDragStop", function()
        transferWindow:StopMovingOrSizing()
    end)

    tinsert(UISpecialFrames, "GoubayuHeal_TransferWindow")

    local title = GoubayuHeal_UI_MakeFontString(transferWindow, "OVERLAY", 14, 1, 0.565, 0)
    title:SetPoint("TOPLEFT", transferWindow, "TOPLEFT", 16, -14)
    title:SetText(GoubayuHeal.UI.TransferTitle)
    transferWindow.title = title

    local closeBtn = GoubayuHeal_UI_CreateFlatButton(transferWindow, nil, 28, 24, "X")
    closeBtn:SetPoint("TOPRIGHT", transferWindow, "TOPRIGHT", -12, -10)
    closeBtn:SetScript("OnClick", GoubayuHeal_UI_HideTransfer)

    local hint = GoubayuHeal_UI_MakeFontString(transferWindow, "OVERLAY", 10, 0.6, 0.6, 0.6)
    hint:SetPoint("TOPLEFT", transferWindow, "TOPLEFT", 14, -40)
    hint:SetWidth(442)
    hint:SetJustifyH("LEFT")
    transferWindow.hint = hint

    local textPanel = CreateFrame("Frame", nil, transferWindow)
    textPanel:SetWidth(442)
    textPanel:SetHeight(250)
    textPanel:SetPoint("TOP", transferWindow, "TOP", 0, -62)
    UI.ApplyFlatBackdrop(textPanel, 0.025, 0.025, 0.025, 1)

    local scroll = CreateFrame("ScrollFrame", nil, textPanel)
    scroll:SetWidth(406)
    scroll:SetHeight(234)
    scroll:SetPoint("TOPLEFT", textPanel, "TOPLEFT", 9, -8)
    scroll:EnableMouse(true)
    scroll:EnableMouseWheel(true)

    local transferSlider = CreateFrame("Slider", nil, textPanel)
    transferSlider:SetOrientation("VERTICAL")
    transferSlider:SetWidth(10)
    transferSlider:SetHeight(234)
    transferSlider:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 6, 0)
    transferSlider:SetMinMaxValues(0, 0)
    transferSlider:SetValueStep(1)

    local strack = transferSlider:CreateTexture(nil, "BACKGROUND")
    strack:SetTexture("Interface\\Buttons\\WHITE8X8")
    strack:SetAllPoints()
    strack:SetVertexColor(0.05, 0.05, 0.05, 0.95)

    transferSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    -- 滑块需EnableMouse才能接收点击/拖动（缺失导致滑块无法滑动）
    transferSlider:EnableMouse(true)
    transferSlider:SetScript("OnValueChanged", function()
        scroll:SetVerticalScroll(arg1)
    end)

    local sthumb = transferSlider:GetThumbTexture()
    if sthumb then
        sthumb:SetWidth(10)
        sthumb:SetHeight(34)
        sthumb:SetVertexColor(0.90, 0.87, 0.80, 0.95)
    end

    local function GoubayuHeal_UI_TransferScroll(value)
        local _, max = transferSlider:GetMinMaxValues()
        if value < 0 then
            value = 0
        end
        if value > (max or 0) then
            value = max or 0
        end
        transferSlider:SetValue(value)
        scroll:SetVerticalScroll(value)
    end

    scroll:SetScript("OnMouseWheel", function()
        GoubayuHeal_UI_TransferScroll(scroll:GetVerticalScroll() - arg1 * 60)
    end)

    -- 编辑框覆盖整个滚动区域：滚轮事件转发给滚动条（否则编辑框区域滚轮无效）
    -- （在 transferEditBox 创建之后设置，见下方）
    transferWindow._transferSlider = transferSlider
    transferWindow._transferScrollFn = GoubayuHeal_UI_TransferScroll

    transferEditBox = CreateFrame("EditBox", nil, scroll)
    transferEditBox:SetWidth(406)
    transferEditBox:SetHeight(234)
    transferEditBox:SetPoint("TOPLEFT", scroll, "TOPLEFT", 0, 0)
    transferEditBox:SetAutoFocus(false)
    transferEditBox:SetMultiLine(true)
    transferEditBox:SetMaxLetters(0)
    transferEditBox:SetFont(FONT, 11, "OUTLINE")
    transferEditBox:SetTextColor(1, 1, 1)
    transferEditBox:SetTextInsets(2, 2, 2, 2)
    transferEditBox:SetJustifyH("LEFT")
    transferEditBox:SetJustifyV("TOP")
    scroll:SetScrollChild(transferEditBox)

    -- 编辑框覆盖整个滚动区域：滚轮事件转发给滚动条（否则编辑框区域滚轮无效）
    transferEditBox:EnableMouseWheel(true)
    transferEditBox:SetScript("OnMouseWheel", function()
        GoubayuHeal_UI_TransferScroll(scroll:GetVerticalScroll() - arg1 * 60)
    end)

    -- 依据文本长度估算编辑框高度并同步滑块范围（文本超出一屏时滑块才可用）
    local function GoubayuHeal_UI_UpdateTransferLayout()
        local textLen = string.len(transferEditBox:GetText() or "")
        -- 11号字体下每行约60字符（Base64无空格，编辑框按宽度硬换行）
        local estLines = math.max(1, math.ceil(textLen / 60))
        local h = math.max(234, estLines * 13 + 8)
        transferEditBox:SetHeight(h)
        local maximum = h - 234
        if maximum < 0 then
            maximum = 0
        end
        transferSlider:SetMinMaxValues(0, maximum)
    end
    transferWindow._updateTransferLayout = GoubayuHeal_UI_UpdateTransferLayout

    local copyBtn = GoubayuHeal_UI_CreateFlatButton(transferWindow, nil, 90, 26, GoubayuHeal.UI.Copy)
    copyBtn:SetPoint("BOTTOMLEFT", transferWindow, "BOTTOMLEFT", 20, 12)
    copyBtn:SetScript("OnClick", GoubayuHeal_UI_SelectExportText)

    local okBtn = GoubayuHeal_UI_CreateFlatButton(transferWindow, nil, 90, 26, GoubayuHeal.UI.Import)
    okBtn:SetPoint("BOTTOMRIGHT", transferWindow, "BOTTOMRIGHT", -20, 12)

    okBtn:SetScript("OnClick", function()
        if transferMode ~= "import" then
            return
        end
        local ok, msg = UI.ImportConfigText(transferEditBox:GetText())
        if ok then
            GoubayuHeal.Print(GoubayuHeal.UI.ImportOK)
            GoubayuHeal_UI_HideTransfer()
        else
            GoubayuHeal.Print(string.format(GoubayuHeal.UI.ImportFailFmt, tostring(msg)), "|cffff0000")
        end
    end)

    transferEditBox:SetScript("OnEscapePressed", GoubayuHeal_UI_HideTransfer)

    transferEditBox:SetScript("OnTextChanged", function()
        if transferMode == "export" and transferEditBox:GetText() ~= transferProtectedText then
            transferEditBox:SetText(transferProtectedText)
            GoubayuHeal_UI_SelectExportText()
        end

        if transferWindow and transferWindow._transferSlider then
            local max = scroll:GetVerticalScrollRange()
            if not max or max < 0 then
                max = 0
            end
            transferWindow._transferSlider:SetMinMaxValues(0, max)
            if max <= 0 then
                transferWindow._transferSlider:SetAlpha(0.25)
            else
                transferWindow._transferSlider:SetAlpha(1)
            end
        end
    end)

    transferWindow:Hide()
end

-- 导出当前配置为文本（GBYH:<版本>: 前缀的紧凑编码字符串，含校验与压缩）
function UI.ExportConfigText()
    if GoubayuHeal.ExportConfigText then
        local text, err = GoubayuHeal.ExportConfigText()
        if text then
            return text
        end
        return string.format(GoubayuHeal.UI.ExportFailFmt, tostring(err or ""))
    end
    return GoubayuHeal.UI.ExportUnavailable
end

-- 解析并应用导入文本
function UI.ImportConfigText(text)
    if not text or text == "" then
        return false, GoubayuHeal.UI.NoInput
    end
    -- 优先使用 Codec 解码（GBYH:<版本>: 前缀的紧凑编码）；也兼容旧的 Lua 结构文本
    local result, err = nil, nil
    if GoubayuHeal.Codec_Decode then
        local data, decodeErr = GoubayuHeal.Codec_Decode(text)
        if data then
            result = data
        elseif decodeErr and not string.find(tostring(decodeErr), GoubayuHeal.UI.PrefixErrPattern) then
            return false, string.format(GoubayuHeal.UI.ImportFailFmt, tostring(decodeErr))
        end
    end
    if not result then
        -- 回退：旧的 Lua 结构文本
        local f, ferr = loadstring(text)
        if not f then
            return false, string.format(GoubayuHeal.UI.ParseFailFmt, tostring(ferr or GoubayuHeal.UI.FormatError))
        end
        local ok, r = pcall(f)
        if not ok then
            return false, string.format(GoubayuHeal.UI.ParseErrorFmt, tostring(r))
        end
        if type(r) ~= "table" then
            return false, GoubayuHeal.UI.NotConfigTable
        end
        result = r
    end
    if type(result) ~= "table" then
        return false, GoubayuHeal.UI.NotConfigTable
    end
    if type(result["classes"]) ~= "table" then
        return false, GoubayuHeal.UI.MissingClasses
    end
    -- 清空旧配置，将导入结果复制到当前表（保持与 SavedVariables 的引用）
    for k in pairs(GoubayuHeal.Config) do GoubayuHeal.Config[k] = nil end
    for k, v in pairs(result) do GoubayuHeal.Config[k] = v end
    -- 补齐缺失的默认设置
    if GoubayuHeal.SetupSettings then
        GoubayuHeal.SetupSettings()
    end
    if GoubayuHeal.ClassDropDownMenuInitialize then
        GoubayuHeal.ClassDropDownMenuInitialize()
    end
    if GoubayuHeal.SetRaidChecked then
        GoubayuHeal.SetRaidChecked()
    end
    -- 立即刷新所有设置滑块/复选框的显示值，无需切换页面
    UI.RefreshAll()
    return true, "ok"
end

function UI.ShowExportWindow()
    GoubayuHeal_UI_CreateTransferWindow()
    transferMode = "export"
    transferProtectedText = UI.ExportConfigText()
    transferWindow.title:SetText(GoubayuHeal.UI.ExportTitle)
    transferWindow.hint:SetText(GoubayuHeal.UI.ExportHint)
    transferEditBox:SetText(transferProtectedText)
    -- 按文本长度抬高编辑框并同步滑块范围（长导出文本可滚动查看）
    if transferWindow._updateTransferLayout then
        transferWindow._updateTransferLayout()
    end
    transferWindow:Show()
    GoubayuHeal_UI_SelectExportText()

    if transferWindow._transferSlider then
        transferWindow._transferSlider:SetMinMaxValues(0, 0)
        transferWindow:SetScript("OnUpdate", function()
            transferWindow:SetScript("OnUpdate", nil)
            local max = scroll and scroll:GetVerticalScrollRange() or 0
            if not max or max < 0 then
                max = 0
            end
            transferWindow._transferSlider:SetMinMaxValues(0, max)
            if max <= 0 then
                transferWindow._transferSlider:SetAlpha(0.25)
            else
                transferWindow._transferSlider:SetAlpha(1)
            end
        end)
    end
end

function UI.ShowImportWindow()
    GoubayuHeal_UI_CreateTransferWindow()
    transferMode = "import"
    transferWindow.title:SetText(GoubayuHeal.UI.ImportTitle)
    transferWindow.hint:SetText(GoubayuHeal.UI.ImportHint)
    transferEditBox:SetText("")
    if transferWindow._updateTransferLayout then
        transferWindow._updateTransferLayout()
    end
    transferEditBox:SetFocus()
    transferWindow:Show()
end

-- ============================================================
-- 主窗口
-- ============================================================

GoubayuHeal_GUI = CreateFrame("Frame", "GoubayuHeal_GUI", UIParent)
local mainWindow = GoubayuHeal_GUI
mainWindow:SetWidth(880)
mainWindow:SetHeight(600)
mainWindow:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
mainWindow:SetFrameStrata("HIGH")
mainWindow:SetFrameLevel(20)
mainWindow:SetMovable(true)
mainWindow:SetClampedToScreen(true)
mainWindow:EnableMouse(true)
UI.ApplyFlatBackdrop(mainWindow, 0.04, 0.04, 0.04, 0.98)
mainWindow:Hide()
tinsert(UISpecialFrames, "GoubayuHeal_GUI")

mainWindow:SetScript("OnHide", function()
    -- 收起所有展开的下拉菜单/角色菜单（下拉菜单父窗口是UIParent，
    -- Esc经UISpecialFrames关窗不会触发HideAllMenus，菜单会残留在屏幕上）
    if UI.HideAllMenus then
        UI.HideAllMenus()
    end
    -- 取消进行中的方案流程拖拽（dragGhost 粘附光标问题）
    if UI.OnMainWindowClosed then
        UI.OnMainWindowClosed()
    end
    -- 关窗时收起显示框（1.12 隐藏悬停中的窗口不触发 OnLeave，否则悬浮说明残留）
    if GoubayuHealDisplayTooltip then
        GoubayuHealDisplayTooltip:Hide()
    end
end)

-- 标题栏
local titleBar = CreateFrame("Frame", nil, mainWindow)
titleBar:SetWidth(856)
titleBar:SetHeight(34)
titleBar:SetPoint("TOPLEFT", mainWindow, "TOPLEFT", 12, -8)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")

titleBar:SetScript("OnDragStart", function()
    mainWindow:Raise()
    mainWindow:StartMoving()
end)

titleBar:SetScript("OnDragStop", function()
    mainWindow:StopMovingOrSizing()
end)

local titleText = GoubayuHeal_UI_MakeFontString(titleBar, "OVERLAY", 16, 1, 0.565, 0)
titleText:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
    titleText:SetText("|cffFF9000Goubayu|r|cffffffffHeal|r")

    local titleVersion = GoubayuHeal_UI_MakeFontString(titleBar, "OVERLAY", 10, 1, 1, 1)
titleVersion:SetPoint("LEFT", titleText, "RIGHT", 10, -1)
titleVersion:SetText(GoubayuHeal.UI.Author)

local closeButton = CreateFrame("Button", nil, titleBar)
closeButton:SetWidth(26)
closeButton:SetHeight(26)
closeButton:SetPoint("TOPRIGHT", titleBar, "TOPRIGHT", -4, 4)
UI.ApplyFlatBackdrop(closeButton, 0.35, 0.08, 0.08, 0.98)

    local closeText = GoubayuHeal_UI_MakeFontString(closeButton, "OVERLAY", 13, 1, 0.4, 0.4)
    closeText:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
    closeText:SetText("X")
    -- 悬浮说明：显示路径已与查询框分离（见 GoubayuHealDisplayTooltip），
    -- 不再有查询抢占导致的闪烁，可安全恢复
    UI.SetTooltip(closeButton, GoubayuHeal.UI.Close, nil, true)

closeButton:SetScript("OnClick", function()
    if UI.HideAllMenus then
        UI.HideAllMenus()
    end
    mainWindow:Hide()
end)

-- ============================================================
-- 标签页
-- ============================================================

local tabNames = GoubayuHeal.GUI_tab_title
local tabButtons = {}
local panels = {}
local selectedTab = 1

local function GoubayuHeal_SetSelectedTab(index)
    if UI.HideAllMenus then
        UI.HideAllMenus()
    end

    selectedTab = index

    for i = 1, 9 do
        local tab = tabButtons[i]
        if i == index then
            tab:SetBackdropColor(0.16, 0.16, 0.16, 0.98)
            tab.text:SetTextColor(1, 0.565, 0)
        else
            tab:SetBackdropColor(0.065, 0.065, 0.065, 0.98)
            tab.text:SetTextColor(0.6, 0.6, 0.6)
        end

        if panels[i] then
            if i == index then
                panels[i]:Show()
            else
                panels[i]:Hide()
            end
        end
    end

    if index == 1 and UI.RedrawFlow then
        UI.RedrawFlow()
        UI.RedrawLibrary()
    end

    -- 兜底：1.12 面板级 Show/Hide 不会向子控件传播 OnShow，页签切换后需补一次
    -- 可见控件刷新（RefreshSettingsValues 已跳过隐藏控件，代价低） by 武藤纯子酱 2026.9.4
    if UI.RefreshSettingsValues then
        UI.RefreshSettingsValues()
    end
end

for i = 1, 9 do
    local idx = i
    local tab = CreateFrame("Button", nil, mainWindow)
    tab:SetWidth(90)
    tab:SetHeight(30)
    tab:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10 + (idx - 1) * 95, -8)
    UI.ApplyFlatBackdrop(tab, 0.065, 0.065, 0.065, 0.98)

    local t = GoubayuHeal_UI_MakeFontString(tab, "OVERLAY", 12, 0.6, 0.6, 0.6)
    t:SetPoint("CENTER", tab, "CENTER", 0, 0)
    t:SetText(tabNames[idx])
    tab.text = t

    tab:SetScript("OnEnter", function()
        this:SetBackdropColor(0.12, 0.12, 0.12, 0.98)
    end)

    tab:SetScript("OnLeave", function()
        if idx == selectedTab then
            this:SetBackdropColor(0.16, 0.16, 0.16, 0.98)
        else
            this:SetBackdropColor(0.065, 0.065, 0.065, 0.98)
        end
    end)

    tab:SetScript("OnClick", function()
        GoubayuHeal_SetSelectedTab(idx)
    end)

    tabButtons[i] = tab
end

mainWindow:SetScript("OnUpdate", function()
    if UI.DragUpdate then
        UI.DragUpdate()
    end
end)

-- ============================================================
-- 方案标签页（组合）
-- ============================================================

local classesPanel = CreateFrame("Frame", nil, mainWindow)
classesPanel:SetWidth(856)
classesPanel:SetHeight(500)
classesPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)
classesPanel:EnableMouse(true)
panels[1] = classesPanel

-- 顶部工具条
local toolbar = CreateFrame("Frame", nil, classesPanel)
toolbar:SetWidth(836)
toolbar:SetHeight(40)
toolbar:SetPoint("TOPLEFT", classesPanel, "TOPLEFT", 0, 0)
UI.ApplyFlatBackdrop(toolbar, 0.06, 0.06, 0.06, 0.95)

local schemeLabel = GoubayuHeal_UI_MakeFontString(toolbar, "OVERLAY", 11, 0.72, 0.72, 0.72)
schemeLabel:SetPoint("LEFT", toolbar, "LEFT", 10, 0)
schemeLabel:SetText(GoubayuHeal.UI.SchemeLabel)

GoubayuHeal_GUIClassDropDownMenu = UI.CreateDropDown(toolbar, 140, function()
    local list = {}
    if not GoubayuHeal.Config or not GoubayuHeal.Config["classes"] then
        return list
    end

    for class, data in GoubayuHeal.Config["classes"] do
        -- 与其他方案列表同口径排除 _Tank 坦克模式临时方案（原漏排导致其显示且可被选中）
        -- by 武藤纯子酱 2026.9.4
        if GoubayuHeal.Config["show_hidden_schemes"]
            or not (string.find(class, "_D$") or string.find(class, "_S$")
                or string.find(class, "_T$") or string.find(class, "_Tank$")) then
            table.insert(list, { text = class })
        end
    end

    return list
end, function(text, buttonClicked)
    if buttonClicked == "RightButton" then
        if text and GoubayuHeal.Config and GoubayuHeal.Config["classes"][text] then
            if GoubayuHeal.DeleteClassAndRelated then
                GoubayuHeal.DeleteClassAndRelated(text)
            end
            GoubayuHeal.Print(string.format(GoubayuHeal.UI.DeletedClassFmt, text))
        end
        return
    end

    if text and GoubayuHeal.ClassDropDownMenuUpdate then
        GoubayuHeal.ClassDropDownMenuUpdate(text)
    end
end)
GoubayuHeal_GUIClassDropDownMenu:SetPoint("LEFT", schemeLabel, "RIGHT", 6, 0)
UI.SetTooltip(GoubayuHeal_GUIClassDropDownMenu, GoubayuHeal.UI.ChooseScheme,
    GoubayuHeal.UI.ChooseSchemeTip)

local newClassButton = GoubayuHeal_UI_CreateFlatButton(toolbar, "GoubayuHeal_GUINewClassButton",
    80, 24, GoubayuHeal.GUI_new)
newClassButton:SetPoint("LEFT", GoubayuHeal_GUIClassDropDownMenu, "RIGHT", 10, 0)
newClassButton:SetScript("OnClick", function()
    GoubayuHeal_GUITextBox:Show()
end)
UI.SetTooltip(newClassButton, GoubayuHeal.UI.NewScheme, GoubayuHeal.UI.NewSchemeTip)

local deleteClassButton = GoubayuHeal_UI_CreateFlatButton(toolbar,
    "GoubayuHeal_GUIDeleteClassButton", 80, 24, GoubayuHeal.GUI_delete)
deleteClassButton:SetPoint("LEFT", newClassButton, "RIGHT", 8, 0)
deleteClassButton:SetScript("OnClick", function()
    if GoubayuHeal.current_class then
        if GoubayuHeal.DeleteClassAndRelated then
            GoubayuHeal.DeleteClassAndRelated(GoubayuHeal.current_class)
        end
    end
end)
UI.SetTooltip(deleteClassButton, GoubayuHeal.UI.DeleteScheme, GoubayuHeal.UI.DeleteSchemeTip)

-- 方案独立配置开关
GoubayuHeal.perSchemeToggle = GoubayuHeal_UI_CreateToggle(toolbar,
    "GoubayuHeal_GUIPerSchemeToggle", 40, 18)
GoubayuHeal.perSchemeToggle:SetPoint("LEFT", deleteClassButton, "RIGHT", 12, 0)

GoubayuHeal.perSchemeToggle.userOnShow = function()
    if GoubayuHeal.Config and GoubayuHeal.perSchemeToggle then
        GoubayuHeal.perSchemeToggle:SetChecked(GoubayuHeal.Config["per_scheme_enabled"] == 1)
    end
end

GoubayuHeal.perSchemeToggle.userOnClick = function()
    if not GoubayuHeal.Config then
        return
    end

    local checked = GoubayuHeal.perSchemeToggle:GetChecked()

    if checked and GoubayuHeal.Config["per_scheme_enabled"] ~= 1 then
        if GoubayuHeal.SchemeSaveGlobalSnapshot then
            GoubayuHeal.SchemeSaveGlobalSnapshot()
        end
        if GoubayuHeal.SchemeInitAll then
            GoubayuHeal.SchemeInitAll()
        end
        if GoubayuHeal.SchemeSaveSettings and GoubayuHeal.current_class then
            GoubayuHeal.SchemeSaveSettings(GoubayuHeal.current_class)
        end
    elseif not checked and GoubayuHeal.Config["per_scheme_enabled"] == 1 then
        if GoubayuHeal.SchemeLoadGlobalSnapshot then
            GoubayuHeal.SchemeLoadGlobalSnapshot()
        end
    end

    GoubayuHeal.Config["per_scheme_enabled"] = checked and 1 or 0
    if UI.RefreshSettingsValues then
        UI.RefreshSettingsValues()
    end
end

GoubayuHeal.perSchemeLabel = GoubayuHeal_UI_MakeFontString(toolbar, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.perSchemeLabel:SetPoint("LEFT", GoubayuHeal.perSchemeToggle, "RIGHT", 6, 0)
GoubayuHeal.perSchemeLabel:SetText(GoubayuHeal.UI.PerScheme)
UI.SetTooltip(GoubayuHeal.perSchemeToggle, GoubayuHeal.UI.PerScheme,
    GoubayuHeal.UI.PerSchemeTip)

-- 第二行：职业专用开关
local specialBar = CreateFrame("Frame", nil, classesPanel)
specialBar:SetWidth(836)
specialBar:SetHeight(34)
specialBar:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 0, -14)
UI.ApplyFlatBackdrop(specialBar, 0.05, 0.05, 0.05, 0.9)

local GoubayuHeal_ClassCbFlowX = nil

local function GoubayuHeal_MakeClassCheckBox(name, labelText, getValue, setValue, tooltipDesc,
        xOffset, yOffset)
    local cb = GoubayuHeal_UI_CreateToggle(specialBar, name, 40, 20)
    local cbX = GoubayuHeal_ClassCbFlowX or ((xOffset or 0) + 24)
    cb:SetPoint("TOPLEFT", specialBar, "TOPLEFT", cbX, yOffset or -7)

    local label = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(labelText)

    cb.disabledTip = GoubayuHeal.UI.NotThisClass

    cb.userOnClick = function()
        if setValue then
            setValue(cb.checked)
        end
    end

    cb.userOnShow = function()
        if getValue then
            cb:SetChecked(getValue())
        end
    end

    cb:SetScript("OnEnter", function()
        GameTooltip:SetOwner(cb, "ANCHOR_RIGHT")
        if cb.disabled then
            GameTooltip:SetText(GoubayuHeal.UI.NotThisClass, 0.9, 0.9, 0.9, 1, 1)
            if tooltipDesc then
                GameTooltip:AddLine(tooltipDesc, 0.82, 0.82, 0.82, 1)
            end
        else
            GameTooltip:SetText(labelText, 0.9, 0.9, 0.9, 1, 1)
            if tooltipDesc then
                GameTooltip:AddLine(tooltipDesc, 0.82, 0.82, 0.82, 1)
            end
        end
        GameTooltip:Show()
    end)

    cb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    cb.label = label

    local textW = (label.GetStringWidth and label:GetStringWidth())
    if not textW then
        local charCount = select(2, string.gsub(labelText, "[^\128-\191]", ""))
        textW = charCount * 10
    end

    GoubayuHeal_ClassCbFlowX = cbX + 40 + 4 + textW + 16
    return cb
end

local function GoubayuHeal_EnsureTotemConfig()
    if not GoubayuHeal.Config then
        return nil
    end
    if not GoubayuHeal.Config["shaman_totem"] then
        GoubayuHeal.Config["shaman_totem"] = { enabled = 0, onekey = 0, keep_water_shield = 0 }
    elseif type(GoubayuHeal.Config["shaman_totem"]) == "number" then
        local old = GoubayuHeal.Config["shaman_totem"]
        GoubayuHeal.Config["shaman_totem"] = { enabled = old, onekey = 0, keep_water_shield = 0 }
    end
    -- 旧存档兼容：补 onekey 字段（0=只显示窗口，不自动插图腾）
    if GoubayuHeal.Config["shaman_totem"].onekey == nil then
        GoubayuHeal.Config["shaman_totem"].onekey = 0
    end
    return GoubayuHeal.Config["shaman_totem"]
end

-- 萨满：图腾窗口（仅显示/隐藏窗口，不自动插图腾）
GoubayuHeal.GUIShamanTotem = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIShamanTotem", GoubayuHeal.UI.TotemWindow,
    function()
        local c = GoubayuHeal_EnsureTotemConfig()
        return c and c.enabled == 1 or false
    end,
    function(checked)
        local c = GoubayuHeal_EnsureTotemConfig()
        if c then
            c.enabled = checked and 1 or 0
            if GoubayuHeal.Totem_ToggleFrame then
                GoubayuHeal.Totem_ToggleFrame()
            end
        end
    end,
    GoubayuHeal.UI.TotemWindowTip, 0)

-- 萨满：一键图腾（开启后自动治疗时按当前预设自动插图腾；手动用 /gbyh totem）
GoubayuHeal.GUIShamanOneKeyTotem = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIShamanOneKeyTotem",
    GoubayuHeal.UI.OneKeyTotem,
    function()
        local c = GoubayuHeal_EnsureTotemConfig()
        return c and c.onekey == 1 or false
    end,
    function(checked)
        local c = GoubayuHeal_EnsureTotemConfig()
        if c then
            c.onekey = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.OneKeyTotemTip, 0)

-- 萨满：保持水盾
GoubayuHeal.GUIKeepWaterShield = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIKeepWaterShield",
    GoubayuHeal.UI.KeepWaterShield,
    function()
        local c = GoubayuHeal_EnsureTotemConfig()
        return c and c.keep_water_shield == 1 or false
    end,
    function(checked)
        local c = GoubayuHeal_EnsureTotemConfig()
        if c then
            c.keep_water_shield = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.KeepWaterShieldTip, 110)

-- 萨满：链无弹跳转波滑块（0=不转，1=转治疗波，2=转次级治疗波）
GoubayuHeal.cnbLabel = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.cnbLabel:SetText(GoubayuHeal.UI.CnbLabel)

GoubayuHeal.cnbSlider = GoubayuHeal_UI_CreateSlider(specialBar, "GoubayuHeal_GUIChainNoBounceWaveSlider",
    105, 15, true)

GoubayuHeal.cnbHigh = getglobal("GoubayuHeal_GUIChainNoBounceWaveSliderHigh")
if GoubayuHeal.cnbHigh then
    GoubayuHeal.cnbHigh:SetFont(FONT, 10, "OUTLINE")
    GoubayuHeal.cnbHigh:SetTextColor(1, 1, 1)
end
GoubayuHeal.cnbSlider:SetMinMaxValues(0, 2)
GoubayuHeal.cnbSlider:SetValueStep(1)

GoubayuHeal.cnbSlider.userOnValueChanged = function()
    if GoubayuHeal.Config then
        local v = math.floor(arg1)
        GoubayuHeal.Config["shaman_chain_nobounce_wave"] = v
        GoubayuHeal_UI_SavePerScheme("shaman_chain_nobounce_wave", v)
    end
    if GoubayuHeal.cnbHigh then
        local v = math.floor(arg1)
        local txt = (v == 1) and GoubayuHeal.Healing_wave or (v == 2) and GoubayuHeal.UI.LHW or GoubayuHeal.UI.Off
        GoubayuHeal.cnbHigh:SetText(txt)
    end
end

GoubayuHeal.cnbSlider.userOnShow = function()
    local v = GoubayuHeal.Config and (GoubayuHeal.Config["shaman_chain_nobounce_wave"] or 0) or 0
    this:SetValue(v)
    if GoubayuHeal.cnbHigh then
        local txt = (v == 1) and GoubayuHeal.Healing_wave or (v == 2) and GoubayuHeal.UI.LHW or GoubayuHeal.UI.Off
        GoubayuHeal.cnbHigh:SetText(txt)
    end
end

GoubayuHeal.cnbSlider:SetScript("OnEnter", function()
    GameTooltip:SetOwner(GoubayuHeal.cnbSlider, "ANCHOR_RIGHT")
    GameTooltip:SetText(GoubayuHeal.UI.CnbTitle, 0.9, 0.9, 0.9, 1, 1)
    GameTooltip:AddLine(
        GoubayuHeal.UI.CnbTip,
        0.82, 0.82, 0.82, 1)
    GameTooltip:Show()
end)

GoubayuHeal.cnbSlider:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 圣骑士：近战奶
GoubayuHeal.GUIPaladinMeleeHeal = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIPaladinMeleeHeal",
    GoubayuHeal.UI.MeleeHeal,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["paladin_melee_heal"] == 1
    end,
    function(checked)
        if not GoubayuHeal.Config then
            return
        end
        GoubayuHeal.Config["paladin_melee_heal"] = checked and 1 or 0
    end,
    GoubayuHeal.UI.MeleeHealTip, 450)

-- 圣骑士：近战奶维持审判滑块（0=无 1=智慧 2=十字军 3=光明；与"链转波"滑块同款）
GoubayuHeal.meleeJudgmentLabel = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.meleeJudgmentLabel:SetText(GoubayuHeal.UI.MeleeJudgmentLabel)

GoubayuHeal.meleeJudgmentSlider = GoubayuHeal_UI_CreateSlider(specialBar,
    "GoubayuHeal_GUIMeleeJudgmentSlider", 105, 15, true)

GoubayuHeal.meleeJudgmentHigh = getglobal("GoubayuHeal_GUIMeleeJudgmentSliderHigh")
if GoubayuHeal.meleeJudgmentHigh then
    GoubayuHeal.meleeJudgmentHigh:SetFont(FONT, 10, "OUTLINE")
    GoubayuHeal.meleeJudgmentHigh:SetTextColor(1, 1, 1)
end
GoubayuHeal.meleeJudgmentSlider:SetMinMaxValues(0, 3)
GoubayuHeal.meleeJudgmentSlider:SetValueStep(1)

function GoubayuHeal.UI_MeleeJudgmentText(v)
    if v == 1 then
        return GoubayuHeal.UI.JwText
    elseif v == 2 then
        return GoubayuHeal.UI.JcText
    elseif v == 3 then
        return GoubayuHeal.UI.JlText
    end
    return GoubayuHeal.UI.NoneText
end

-- 滑块值 → 审判debuff名（与 Paladin.lua 的 Paladin_MeleeJudgmentChoice 同口径；0=不打审判）
function GoubayuHeal.UI_MeleeJudgmentName(v)
    if v == 2 then
        return GoubayuHeal.Judgment_of_Crusader
    elseif v == 3 then
        return GoubayuHeal.Judgment_of_Light
    elseif v == 1 then
        return GoubayuHeal.Judgment_of_Wisdom
    end
    return "none"
end

-- 审判debuff名 → 滑块值（读档回显用；旧档"none"历史上表示智慧，现语义为不审判，
-- 测试期数据量极小可接受；默认/未知值归位到智慧=1）
function GoubayuHeal.UI_MeleeJudgmentValue(v)
    if v == "none" then
        return 0
    elseif v == GoubayuHeal.Judgment_of_Crusader then
        return 2
    elseif v == GoubayuHeal.Judgment_of_Light then
        return 3
    end
    return 1
end

GoubayuHeal.meleeJudgmentSlider.userOnValueChanged = function()
    local v = math.floor(arg1 or 0)
    if GoubayuHeal.Config then
        GoubayuHeal.Config["paladin_melee_judgment"] = GoubayuHeal.UI_MeleeJudgmentName(v)
    end
    if GoubayuHeal.meleeJudgmentHigh then
        GoubayuHeal.meleeJudgmentHigh:SetText(GoubayuHeal.UI_MeleeJudgmentText(v))
    end
end

GoubayuHeal.meleeJudgmentSlider.userOnShow = function()
    local v = GoubayuHeal.UI_MeleeJudgmentValue(GoubayuHeal.Config
        and GoubayuHeal.Config["paladin_melee_judgment"] or "none")
    this:SetValue(v)
    if GoubayuHeal.meleeJudgmentHigh then
        GoubayuHeal.meleeJudgmentHigh:SetText(GoubayuHeal.UI_MeleeJudgmentText(v))
    end
end

GoubayuHeal.meleeJudgmentSlider:SetScript("OnEnter", function()
    GameTooltip:SetOwner(GoubayuHeal.meleeJudgmentSlider, "ANCHOR_RIGHT")
    GameTooltip:SetText(GoubayuHeal.UI.MeleeJudgmentTitle, 0.9, 0.9, 0.9, 1, 1)
    GameTooltip:AddLine(GoubayuHeal.UI.MeleeJudgmentTip, 0.82, 0.82, 0.82, 1)
    GameTooltip:Show()
end)

GoubayuHeal.meleeJudgmentSlider:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 圣骑士：T3.5 套装件数滑块（0=无 1=3T3.5 2=5T3.5）
function GoubayuHeal.UI_T35Text(v)
    if v == 1 then
        return GoubayuHeal.UI.T35Three
    elseif v == 2 then
        return GoubayuHeal.UI.T35Five
    end
    return GoubayuHeal.UI.T35None
end

GoubayuHeal.t35Label = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.t35Label:SetText(GoubayuHeal.UI.T35Label)

GoubayuHeal.t35Slider = GoubayuHeal_UI_CreateSlider(specialBar, "GoubayuHeal_GUIT35Slider",
    105, 15, true)

GoubayuHeal.t35High = getglobal("GoubayuHeal_GUIT35SliderHigh")
if GoubayuHeal.t35High then
    GoubayuHeal.t35High:SetFont(FONT, 10, "OUTLINE")
    GoubayuHeal.t35High:SetTextColor(1, 1, 1)
end
GoubayuHeal.t35Slider:SetMinMaxValues(0, 2)
GoubayuHeal.t35Slider:SetValueStep(1)

GoubayuHeal.t35Slider.userOnValueChanged = function()
    local v = math.floor(arg1 or 0)
    if GoubayuHeal.Config then
        GoubayuHeal.Config["paladin_tier35"] = v
    end
    if GoubayuHeal.t35High then
        GoubayuHeal.t35High:SetText(GoubayuHeal.UI_T35Text(v))
    end
end

GoubayuHeal.t35Slider.userOnShow = function()
    local v = tonumber(GoubayuHeal.Config and GoubayuHeal.Config["paladin_tier35"]) or 0
    this:SetValue(v)
    if GoubayuHeal.t35High then
        GoubayuHeal.t35High:SetText(GoubayuHeal.UI_T35Text(v))
    end
end

GoubayuHeal.t35Slider:SetScript("OnEnter", function()
    GameTooltip:SetOwner(GoubayuHeal.t35Slider, "ANCHOR_RIGHT")
    GameTooltip:SetText(GoubayuHeal.UI.T35Title, 0.9, 0.9, 0.9, 1, 1)
    GameTooltip:AddLine(GoubayuHeal.UI.T35Tip, 0.82, 0.82, 0.82, 1)
    GameTooltip:Show()
end)

GoubayuHeal.t35Slider:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 圣骑士：十字军打击开关（关闭后近战填充只剩震击与神圣打击群疗）
GoubayuHeal.GUIPaladinMeleeCS = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIPaladinMeleeCS",
    GoubayuHeal.UI.MeleeCSToggle,
    function()
        return not GoubayuHeal.Config
            or GoubayuHeal.Config["paladin_melee_crusader_strike"] ~= 0
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["paladin_melee_crusader_strike"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.MeleeCSToggleTip, 0)

-- 圣骑士：智慧圣印维持开关（关闭后近战循环不再给自己挂智慧圣印；审判所需的对应圣印不受影响）
GoubayuHeal.GUIPaladinSeal = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIPaladinSeal",
    GoubayuHeal.UI.MeleeSealToggle,
    function()
        return not GoubayuHeal.Config
            or GoubayuHeal.Config["paladin_melee_keep_wisdom_seal"] ~= 0
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["paladin_melee_keep_wisdom_seal"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.MeleeSealToggleTip, 0)

-- 圣骑士：保持1级奉献（近战循环中奉献不在冷却即施放1级奉献，无需加入技能库）
GoubayuHeal.GUIPaladinConsec = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIPaladinConsec",
    GoubayuHeal.UI.ConsecToggle,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["paladin_consecration"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["paladin_consecration"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.ConsecToggleTip, 0)

-- 圣骑士：断条打神圣打击（群疗条件满足时打断当前读条并立即施放神圣打击）
GoubayuHeal.GUIPaladinHSInterrupt = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIPaladinHSInterrupt",
    GoubayuHeal.UI.HSInterruptToggle,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["paladin_holy_strike_interrupt"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["paladin_holy_strike_interrupt"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.HSInterruptToggleTip, 0)

-- 圣骑士：圣盾术/圣佑术自救阈值滑块（仅对自身，需判断CD与自律debuff）
GoubayuHeal.dsLabel = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.dsLabel:SetText(GoubayuHeal.UI.DsLabel)

GoubayuHeal.dsSlider = GoubayuHeal_UI_CreateSlider(specialBar, "GoubayuHeal_GUIDivineShieldSlider",
    105, 15, true)

GoubayuHeal.dsHigh = getglobal("GoubayuHeal_GUIDivineShieldSliderHigh")
GoubayuHeal.dsSlider:SetMinMaxValues(0, 100)
GoubayuHeal.dsSlider:SetValueStep(5)

GoubayuHeal.dsSlider.userOnValueChanged = function()
    if GoubayuHeal.Config then
        local v = math.floor(arg1)
        GoubayuHeal.Config["paladin_divine_shield_pct"] = v
        GoubayuHeal_UI_SavePerScheme("paladin_divine_shield_pct", v)
    end
    if GoubayuHeal.dsHigh then
        GoubayuHeal.dsHigh:SetText(math.floor(arg1) .. "%")
    end
end

GoubayuHeal.dsSlider.userOnShow = function()
    if GoubayuHeal.Config and GoubayuHeal.Config["paladin_divine_shield_pct"] then
        this:SetValue(GoubayuHeal.Config["paladin_divine_shield_pct"])
    else
        this:SetValue(0)
    end
end

GoubayuHeal.dsSlider:SetScript("OnEnter", function()
    GameTooltip:SetOwner(GoubayuHeal.dsSlider, "ANCHOR_RIGHT")
    GameTooltip:SetText(GoubayuHeal.UI.DsTitle, 0.9, 0.9, 0.9, 1, 1)
    GameTooltip:AddLine(
        GoubayuHeal.UI.DsTip,
        0.82, 0.82, 0.82, 1)
    GameTooltip:Show()
end)

GoubayuHeal.dsSlider:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

GoubayuHeal.dp2Label = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.dp2Label:SetText(GoubayuHeal.UI.Dp2Label)

GoubayuHeal.dp2Slider = GoubayuHeal_UI_CreateSlider(specialBar, "GoubayuHeal_GUIDivineProtectionSlider",
    105, 15, true)

GoubayuHeal.dp2High = getglobal("GoubayuHeal_GUIDivineProtectionSliderHigh")
GoubayuHeal.dp2Slider:SetMinMaxValues(0, 100)
GoubayuHeal.dp2Slider:SetValueStep(5)

GoubayuHeal.dp2Slider.userOnValueChanged = function()
    if GoubayuHeal.Config then
        local v = math.floor(arg1)
        GoubayuHeal.Config["paladin_divine_protection_pct"] = v
        GoubayuHeal_UI_SavePerScheme("paladin_divine_protection_pct", v)
    end
    if GoubayuHeal.dp2High then
        GoubayuHeal.dp2High:SetText(math.floor(arg1) .. "%")
    end
end

GoubayuHeal.dp2Slider.userOnShow = function()
    if GoubayuHeal.Config and GoubayuHeal.Config["paladin_divine_protection_pct"] then
        this:SetValue(GoubayuHeal.Config["paladin_divine_protection_pct"])
    else
        this:SetValue(0)
    end
end

GoubayuHeal.dp2Slider:SetScript("OnEnter", function()
    GameTooltip:SetOwner(GoubayuHeal.dp2Slider, "ANCHOR_RIGHT")
    GameTooltip:SetText(GoubayuHeal.UI.Dp2Title, 0.9, 0.9, 0.9, 1, 1)
    GameTooltip:AddLine(
        GoubayuHeal.UI.Dp2Tip,
        0.82, 0.82, 0.82, 1)
    GameTooltip:Show()
end)

GoubayuHeal.dp2Slider:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 一级无视过量
GoubayuHeal.GUIAllowFirstRankIgnoreOverheal = GoubayuHeal_MakeClassCheckBox(
    "GoubayuHeal_GUIAllowFirstRankIgnoreOverheal", GoubayuHeal.UI.AllowFirstRank,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["allow_first_rank_ignore_overheal"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["allow_first_rank_ignore_overheal"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.AllowFirstRankTip, 690)

-- 德鲁伊：保持生命之树形态
GoubayuHeal.GUIDruidKeepTree = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIDruidKeepTree",
    GoubayuHeal.UI.KeepTree,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["druid_keep_tree_of_life"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["druid_keep_tree_of_life"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.KeepTreeTip, 130)

-- 德鲁伊：5T2.5（治疗之触对受回春术/愈合影响的目标 +10%）
GoubayuHeal.GUIDruidT25Five = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIDruidT25Five",
    GoubayuHeal.UI.T25Five,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["druid_5t25"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["druid_5t25"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.T25FiveTip, 0)

-- 允许覆盖愈合（默认开）：愈合不再被 HoT 门槛阻挡，残血时可用同级/低级愈合覆盖刷新
-- by 武藤纯子酱 2026.9.27
GoubayuHeal.GUIRegrowthOverwrite = GoubayuHeal_MakeClassCheckBox(
    "GoubayuHeal_GUIRegrowthOverwrite", GoubayuHeal.UI.AllowRegrowthOverwrite,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["allow_regrowth_overwrite"] ~= 0
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["allow_regrowth_overwrite"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.AllowRegrowthOverwriteTip, 60)

-- 牧师：疾速只用强效
GoubayuHeal.GUIPriestForceGreaterHeal = GoubayuHeal_MakeClassCheckBox(
    "GoubayuHeal_GUIPriestForceGreaterHeal", GoubayuHeal.UI.ForceGreater,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["priest_force_greater_heal"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["priest_force_greater_heal"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.ForceGreaterTip, 120)

-- 牧师：交替技能
GoubayuHeal.GUIPriestAlternateSpells = GoubayuHeal_MakeClassCheckBox(
    "GoubayuHeal_GUIPriestAlternateSpells", GoubayuHeal.UI.AlternateSpells,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["priest_alternate_spells"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["priest_alternate_spells"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.AlternateSpellsTip, 120)

-- 牧师：保持心灵之火
GoubayuHeal.GUIPriestKeepInnerFire = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIPriestKeepInnerFire",
    GoubayuHeal.UI.KeepInnerFire,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["priest_keep_inner_fire"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["priest_keep_inner_fire"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.KeepInnerFireTip, 120)

-- 牧师：8T2（强效治疗术附带5级恢复HOT；团刷对比计入+连续强效不交替）
GoubayuHeal.GUIPriestT8Two = GoubayuHeal_MakeClassCheckBox("GoubayuHeal_GUIPriestT8Two",
    GoubayuHeal.UI.T8Two,
    function()
        return GoubayuHeal.Config and GoubayuHeal.Config["priest_8t2"] == 1
    end,
    function(checked)
        if GoubayuHeal.Config then
            GoubayuHeal.Config["priest_8t2"] = checked and 1 or 0
        end
    end,
    GoubayuHeal.UI.T8TwoTip, 120)

-- 艾森娜之花优先级滑块
local essenceLabel = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
essenceLabel:SetText(GoubayuHeal.UI.EssenceLabel)

local essenceSlider = GoubayuHeal_UI_CreateSlider(specialBar, "GoubayuHeal_GUIEssenceOfEluneSlider",
    105, 15, true)

local essenceHigh = getglobal("GoubayuHeal_GUIEssenceOfEluneSliderHigh")
if essenceHigh then
    essenceHigh:ClearAllPoints()
    essenceHigh:SetPoint("RIGHT", specialBar, "RIGHT", -10, 20)
end

essenceSlider:SetPoint("RIGHT", (essenceHigh or specialBar), "LEFT", -4, 0)
essenceLabel:SetPoint("RIGHT", essenceSlider, "LEFT", -4, 0)
essenceSlider:SetMinMaxValues(0, 100)
essenceSlider:SetValueStep(5)

essenceSlider.userOnValueChanged = function()
    if GoubayuHeal.Config then
        GoubayuHeal.Config["essence_of_elune_bonus"] = math.floor(arg1)
    end
    getglobal("GoubayuHeal_GUIEssenceOfEluneSliderHigh"):SetText(math.floor(arg1) .. "%")
end

essenceSlider.userOnShow = function()
    if GoubayuHeal.Config and GoubayuHeal.Config["essence_of_elune_bonus"] then
        this:SetValue(GoubayuHeal.Config["essence_of_elune_bonus"])
    else
        this:SetValue(20)
    end
end

essenceSlider:SetScript("OnEnter", function()
    GameTooltip:SetOwner(essenceSlider, "ANCHOR_RIGHT")
    if essenceSlider.disabled then
        GameTooltip:SetText(GoubayuHeal.UI.NotThisClass, 0.9, 0.9, 0.9, 1, 1)
        GameTooltip:AddLine(GoubayuHeal.UI.EssenceTipDruid, 0.82, 0.82, 0.82, 1)
    else
        GameTooltip:SetText(GoubayuHeal.UI.EssenceTip, 0.9, 0.9, 0.9, 1, 1)
        GameTooltip:AddLine(GoubayuHeal.UI.EssenceTipBody, 0.82, 0.82, 0.82, 1)
    end
    GameTooltip:Show()
end)

essenceSlider:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 绝望祷言滑块
GoubayuHeal.dpLabel = GoubayuHeal_UI_MakeFontString(specialBar, "OVERLAY", 10, 1, 1, 1)
GoubayuHeal.dpLabel:SetText(GoubayuHeal.UI.DpLabel)

GoubayuHeal.dpSlider = GoubayuHeal_UI_CreateSlider(specialBar, "GoubayuHeal_GUIDesperatePrayerSlider",
    105, 15, true)

GoubayuHeal.dpHigh = getglobal("GoubayuHeal_GUIDesperatePrayerSliderHigh")
GoubayuHeal.dpSlider:SetMinMaxValues(0, 100)
GoubayuHeal.dpSlider:SetValueStep(5)

GoubayuHeal.dpSlider.userOnValueChanged = function()
    if GoubayuHeal.Config then
        local v = math.floor(arg1)
        GoubayuHeal.Config["priest_desperate_prayer_pct"] = v
        GoubayuHeal_UI_SavePerScheme("priest_desperate_prayer_pct", v)
    end
    if GoubayuHeal.dpHigh then
        GoubayuHeal.dpHigh:SetText(math.floor(arg1) .. "%")
    end
end

GoubayuHeal.dpSlider.userOnShow = function()
    if GoubayuHeal.Config and GoubayuHeal.Config["priest_desperate_prayer_pct"] then
        this:SetValue(GoubayuHeal.Config["priest_desperate_prayer_pct"])
    else
        this:SetValue(0)
    end
end

GoubayuHeal.dpSlider:SetScript("OnEnter", function()
    GameTooltip:SetOwner(GoubayuHeal.dpSlider, "ANCHOR_RIGHT")
    GameTooltip:SetText(GoubayuHeal.UI.DpTitle, 0.9, 0.9, 0.9, 1, 1)
    GameTooltip:AddLine(
        GoubayuHeal.UI.DpTip,
        0.82, 0.82, 0.82, 1)
    GameTooltip:Show()
end)

GoubayuHeal.dpSlider:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 左右两栏（流程卡片 + 法术库）
local flowPanel = CreateFrame("Frame", nil, classesPanel)
flowPanel:SetWidth(420)
flowPanel:SetHeight(400)
flowPanel:SetPoint("TOPLEFT", specialBar, "BOTTOMLEFT", 0, -4)
UI.ApplyFlatBackdrop(flowPanel, 0.05, 0.05, 0.05, 0.95)

local libraryPanel = CreateFrame("Frame", nil, classesPanel)
libraryPanel:SetWidth(412)
libraryPanel:SetHeight(400)
libraryPanel:SetPoint("TOPLEFT", flowPanel, "TOPRIGHT", 4, 0)
UI.ApplyFlatBackdrop(libraryPanel, 0.05, 0.05, 0.05, 0.95)

local flowHeader = GoubayuHeal_UI_MakeFontString(flowPanel, "OVERLAY", 12, 1, 0.565, 0)
flowHeader:SetPoint("TOPLEFT", flowPanel, "TOPLEFT", 10, -6)
flowHeader:SetText(GoubayuHeal.UI.FlowHeader)

local libraryHeader = GoubayuHeal_UI_MakeFontString(libraryPanel, "OVERLAY", 12, 1, 0.565, 0)
libraryHeader:SetPoint("TOPLEFT", libraryPanel, "TOPLEFT", 10, -6)
libraryHeader:SetText(GoubayuHeal.UI.LibraryHeader)

-- 滚动区域
local flowScroll, flowContent, flowSlider = UI.CreateScrollArea(flowPanel, 410, 366)
flowScroll:SetPoint("TOPLEFT", flowPanel, "TOPLEFT", 5, -24)
flowSlider:SetPoint("TOPRIGHT", flowPanel, "TOPRIGHT", -4, -24)
flowSlider:SetPoint("BOTTOMRIGHT", flowPanel, "BOTTOMRIGHT", -4, 8)

local libraryScroll, libraryContent, librarySlider = UI.CreateScrollArea(libraryPanel, 402, 366)
libraryScroll:SetPoint("TOPLEFT", libraryPanel, "TOPLEFT", 5, -24)
librarySlider:SetPoint("TOPRIGHT", libraryPanel, "TOPRIGHT", -4, -24)
librarySlider:SetPoint("BOTTOMRIGHT", libraryPanel, "BOTTOMRIGHT", -4, 8)

-- ============================================================
-- 卡片系统（流程卡片 + 法术库卡片）
-- ============================================================

local CARD_H = 44
local CARD_GAP = 4
local CARD_PITCH = CARD_H + CARD_GAP

local flowCards = {}
local libraryCards = {}
local flowEntries = {}
local libraryEntries = {}
local selectedFlowIndex = nil

local dragging = nil
local dragGhost = nil
local dropIndicator = nil

local function GoubayuHeal_CreateDragGhost()
    dragGhost = CreateFrame("Frame", nil, UIParent)
    dragGhost:SetWidth(360)
    dragGhost:SetHeight(44)
    dragGhost:SetFrameStrata("TOOLTIP")
    dragGhost:SetFrameLevel(20)
    dragGhost:EnableMouse(false)
    UI.ApplyFlatBackdrop(dragGhost, 0.09, 0.09, 0.09, 0.96)

    local icon = dragGhost:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(28)
    icon:SetHeight(28)
    icon:SetPoint("LEFT", dragGhost, "LEFT", 8, 0)
    dragGhost.icon = icon

    local name = GoubayuHeal_UI_MakeFontString(dragGhost, "OVERLAY", 13, 1, 0.565, 0)
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    dragGhost.name = name

    local desc = GoubayuHeal_UI_MakeFontString(dragGhost, "OVERLAY", 10, 0.82, 0.82, 0.82)
    desc:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
    dragGhost.desc = desc

    dragGhost:Hide()
end

local function GoubayuHeal_CreateDropIndicator()
    dropIndicator = CreateFrame("Frame", nil, flowContent)
    dropIndicator:SetWidth(360)
    dropIndicator:SetHeight(2)

    local line = dropIndicator:CreateTexture(nil, "ARTWORK")
    line:SetAllPoints()
    line:SetTexture("Interface\\Buttons\\WHITE8X8")
    line:SetVertexColor(1, 0.565, 0, 1)

    dropIndicator:Hide()
end

local function GoubayuHeal_GetFlowInsertIndex()
    if not flowContent:IsVisible() then
        return 1
    end

    local scale = UIParent:GetScale()
    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale
    local relativeY = flowContent:GetTop() - y
    local index = math.floor(relativeY / CARD_PITCH) + 1
    local total = table.getn(flowEntries)

    if index < 1 then
        index = 1
    end
    if index > total + 1 then
        index = total + 1
    end

    return index
end

-- 拖拽重排去抖：记录上次位置/插入序号，无变化时跳过 ClearAllPoints+SetPoint
-- （拖拽中每帧两次重排纯浪费）。状态挂 frame 字段而非新增文件级 local——
-- UI.lua 顶层局部变量已逼近 Lua 5.0 的 200 上限 by 武藤纯子酱 2026.9.4

local function GoubayuHeal_UpdateDropIndicator()
    if not dropIndicator or not dragging then
        dropIndicator.LIndex = nil
        return
    end

    if not GoubayuHeal_UI_IsCursorInside(flowScroll) then
        dropIndicator:Hide()
        dropIndicator.LIndex = nil
        return
    end

    local index = GoubayuHeal_GetFlowInsertIndex()
    if index ~= dropIndicator.LIndex then
        dropIndicator.LIndex = index
        dropIndicator:ClearAllPoints()
        dropIndicator:SetPoint("TOPLEFT", flowContent, "TOPLEFT", 0, -2 - (index - 1) * CARD_PITCH)
    end
    dropIndicator:Show()
end

function UI.DragUpdate()
    if not dragging or not dragGhost or not dragGhost:IsVisible() then
        dragGhost.LX, dragGhost.LY = nil, nil
        return
    end

    local scale = UIParent:GetScale()
    local x, y = GetCursorPosition()
    x = x / scale
    y = y / scale

    if x ~= dragGhost.LX or y ~= dragGhost.LY then
        dragGhost.LX, dragGhost.LY = x, y
        dragGhost:ClearAllPoints()
        dragGhost:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end

    GoubayuHeal_UpdateDropIndicator()
end

local function GoubayuHeal_GetSortedFlowEntries()
    local entries = {}
    local cfg = GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][GoubayuHeal.current_class]

    if cfg then
        for percent, data in pairs(cfg) do
            if type(data) == "table" and data["Spell"] then
                table.insert(entries, {
                    percent = tonumber(percent) or 0,
                    spell = data["Spell"],
                    rank = data["Rank"],
                    scale = data["Scale"],
                    attachment = data["Attachment"],
                    attachmentRank = data["AttachmentRank"]
                })
            end
        end
    end

    table.sort(entries, function(a, b)
        return a.percent > b.percent
    end)

    return entries
end

local function GoubayuHeal_GetLibraryEntries()
    local entries = {}
    if not GoubayuHeal.Spells then
        return entries
    end

    -- 圣盾术/圣佑术/绝望祷言由独立滑块控制；复活技能由一键复活功能管理——
    -- 以上不进入法术库。自然迅捷/迅捷治愈/先祖迅捷/保护之手 保留在法术库，
    -- 但点击时不弹预估编辑框（见 GoubayuHeal.no_editor_spells）
    local excluded = {}
    if GoubayuHeal.Divine_protection then excluded[GoubayuHeal.Divine_protection] = true end
    if GoubayuHeal.Divine_shield then excluded[GoubayuHeal.Divine_shield] = true end
    if GoubayuHeal.Desperate_prayer then excluded[GoubayuHeal.Desperate_prayer] = true end
    if GoubayuHeal.Resurrection then excluded[GoubayuHeal.Resurrection] = true end
    if GoubayuHeal.Redemption then excluded[GoubayuHeal.Redemption] = true end
    if GoubayuHeal.Rebirth then excluded[GoubayuHeal.Rebirth] = true end
    if GoubayuHeal.Ancestral_Spirit then excluded[GoubayuHeal.Ancestral_Spirit] = true end

    for spell, data in pairs(GoubayuHeal.Spells) do
        if type(data) == "table" and data["Texture"] and not excluded[spell] then
            table.insert(entries, {
                spell = spell,
                texture = data["Texture"],
                ranks = table.getn(GoubayuHeal.Spells[spell])
            })
        end
    end

    table.sort(entries, function(a, b)
        return a.spell < b.spell
    end)

    return entries
end

local function GoubayuHeal_LayoutCards(cards, count, content)
    local totalHeight = count * CARD_PITCH + 4
    content:SetHeight(totalHeight)

    for i, card in ipairs(cards) do
        if i <= count then
            card:ClearAllPoints()
            if i == 1 then
                card:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -2)
            else
                card:SetPoint("TOPLEFT", cards[i - 1], "BOTTOMLEFT", 0, -CARD_GAP)
            end
            card:Show()
        else
            card:Hide()
        end
    end
end

local function GoubayuHeal_GetSpellIcon(spell)
    if GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
        and GoubayuHeal.Spells[spell]["Texture"] then
        return GoubayuHeal.Spells[spell]["Texture"]
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GoubayuHeal_CreateFlowCard()
    local block = CreateFrame("Button", nil, flowContent)
    block:SetWidth(360)
    block:SetHeight(CARD_H)
    UI.ApplyFlatBackdrop(block, 0.09, 0.09, 0.09, 0.95)
    block:EnableMouse(true)
    block:RegisterForDrag("LeftButton")

    local icon = block:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(28)
    icon:SetHeight(28)
    icon:SetPoint("LEFT", block, "LEFT", 8, 0)

    local attIcon = block:CreateTexture(nil, "OVERLAY")
    attIcon:SetWidth(12)
    attIcon:SetHeight(12)
    attIcon:SetPoint("TOPRIGHT", icon, "TOPRIGHT")

    local title = GoubayuHeal_UI_MakeFontString(block, "OVERLAY", 13, 1, 0.565, 0)
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    title:SetWidth(200)
    title:SetJustifyH("LEFT")

    local desc = GoubayuHeal_UI_MakeFontString(block, "OVERLAY", 10, 0.82, 0.82, 0.82)
    desc:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
    desc:SetWidth(200)
    desc:SetJustifyH("LEFT")

    local pct = GoubayuHeal_UI_MakeFontString(block, "OVERLAY", 14, 1, 0.565, 0)
    pct:SetPoint("RIGHT", block, "RIGHT", -12, 0)

    -- 编辑按钮
    local editButton = CreateFrame("Button", nil, block)
    editButton:SetWidth(26)
    editButton:SetHeight(24)
    editButton:SetPoint("RIGHT", block, "RIGHT", -52, 0)
    UI.ApplyFlatBackdrop(editButton, 0.3, 0.18, 0.02, 0.98)

    local editText = GoubayuHeal_UI_MakeFontString(editButton, "OVERLAY", 12, 1, 0.565, 0)
    editText:SetPoint("CENTER", editButton, "CENTER", 0, 0)
    editText:SetText("E")
    UI.SetTooltip(editButton, GoubayuHeal.UI.Edit, GoubayuHeal.UI.EditTip)

    editButton:SetScript("OnClick", function()
        local entry = block.entry
        if entry and UI.OpenSpellPicker then
            UI.OpenSpellPicker(entry.spell, entry.percent)
        end
    end)

    -- 删除按钮
    local delButton = CreateFrame("Button", nil, block)
    delButton:SetWidth(26)
    delButton:SetHeight(24)
    delButton:SetPoint("RIGHT", block, "RIGHT", -24, 0)
    UI.ApplyFlatBackdrop(delButton, 0.35, 0.08, 0.08, 0.98)

    local delText = GoubayuHeal_UI_MakeFontString(delButton, "OVERLAY", 12, 1, 0.4, 0.4)
    delText:SetPoint("CENTER", delButton, "CENTER", 0, 0)
    delText:SetText("X")
    UI.SetTooltip(delButton, GoubayuHeal.GUI_delete, GoubayuHeal.UI.DeleteTip)

    delButton:SetScript("OnClick", function()
        local entry = block.entry
        if entry and GoubayuHeal.Config and GoubayuHeal.Config["classes"]
            and GoubayuHeal.current_class then
            local cfg = GoubayuHeal.Config["classes"][GoubayuHeal.current_class]
            if cfg then
                cfg[entry.percent] = nil
                selectedFlowIndex = nil
                UI.RedrawFlow()
            end
        end
    end)

    block.editButton = editButton
    block.delButton = delButton

    block:SetScript("OnClick", function()
        if this.dragEndedAt and GetTime() - this.dragEndedAt < 0.2 then
            return
        end
        if selectedFlowIndex == this.index then
            selectedFlowIndex = nil
        else
            selectedFlowIndex = this.index
        end
        UI.RedrawFlow()
    end)

    block:SetScript("OnDragStart", function()
        if not this.entry then
            return
        end
        if dragGhost then
            dragGhost.icon:SetTexture(GoubayuHeal_GetSpellIcon(this.entry.spell))
            dragGhost.name:SetText(this.entry.spell)
            dragGhost.desc:SetText(this.entry.percent .. "%")
            dragGhost:Show()
        end
        dragging = { fromFlow = true, index = this.index, entry = this.entry }
        this:SetAlpha(0.25)
        UI.DragUpdate()
    end)

    block:SetScript("OnDragStop", function()
        this.dragEndedAt = GetTime()
        this:SetAlpha(1)
        if dragGhost then
            dragGhost:Hide()
        end
        if dropIndicator then
            dropIndicator:Hide()
        end

        if not dragging or not dragging.fromFlow then
            dragging = nil
            return
        end

        if GoubayuHeal_UI_IsCursorInside(flowScroll) and GoubayuHeal.current_class then
            local insertIndex = GoubayuHeal_GetFlowInsertIndex()
            local cfg = GoubayuHeal.Config["classes"][GoubayuHeal.current_class]
            local entries = GoubayuHeal_GetSortedFlowEntries()
            local fromIndex = this.index

            if insertIndex > fromIndex then
                insertIndex = insertIndex - 1
            end

            if insertIndex ~= fromIndex and cfg and entries[fromIndex] and entries[insertIndex] then
                local pA = entries[fromIndex].percent
                local pB = entries[insertIndex].percent
                local a = cfg[pA]
                local b = cfg[pB]
                cfg[pB] = a
                cfg[pA] = b
            end

            selectedFlowIndex = nil
            UI.RedrawFlow()
        end

        dragging = nil
    end)

    block:SetScript("OnEnter", function()
        this:SetBackdropColor(0.16, 0.16, 0.16, 0.98)
    end)

    block:SetScript("OnLeave", function()
        if this.index == selectedFlowIndex then
            this:SetBackdropColor(0.16, 0.16, 0.16, 0.98)
        else
            this:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
        end
    end)

    block.Refresh = function(self, entry, index)
        self.entry = entry
        self.index = index
        self.icon = icon
        self.attIcon = attIcon
        self.title = title
        self.desc = desc
        self.pct = pct
    end

    return block
end

local function GoubayuHeal_CreateLibraryCard()
    local block = CreateFrame("Button", nil, libraryContent)
    block:SetWidth(352)
    block:SetHeight(CARD_H)
    UI.ApplyFlatBackdrop(block, 0.09, 0.09, 0.09, 0.95)
    block:EnableMouse(true)
    block:RegisterForDrag("LeftButton")

    -- 拖拽起点光标位置：用于抑制拖拽结束后的误触 OnClick
    local dragStartX, dragStartY = nil, nil

    local icon = block:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(28)
    icon:SetHeight(28)
    icon:SetPoint("LEFT", block, "LEFT", 8, 0)

    local title = GoubayuHeal_UI_MakeFontString(block, "OVERLAY", 13, 1, 0.565, 0)
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -2)
    title:SetJustifyH("LEFT")

    local desc = GoubayuHeal_UI_MakeFontString(block, "OVERLAY", 10, 0.82, 0.82, 0.82)
    desc:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 2)
    desc:SetJustifyH("LEFT")

    block.icon = icon
    block.title = title
    block.desc = desc

    block:SetScript("OnClick", function()
        -- 拖拽后误触抑制：光标相对拖拽起点有明显位移 → 视为拖拽收尾，不打开编辑器
        if dragStartX then
            local cx, cy = GetCursorPosition()
            local dx, dy = cx - dragStartX, cy - dragStartY
            dragStartX, dragStartY = nil, nil
            if dx * dx + dy * dy > 400 then
                return
            end
        end
        if this.entry and GoubayuHeal.OpenSpellDataEditor then
            GoubayuHeal.OpenSpellDataEditor(this.entry.spell)
        end
    end)

    block:SetScript("OnDragStart", function()
        if not this.entry then
            return
        end
        dragStartX, dragStartY = GetCursorPosition()
        if dragGhost then
            dragGhost.icon:SetTexture(this.entry.texture)
            dragGhost.name:SetText(this.entry.spell)
            dragGhost.desc:SetText(this.entry.ranks .. GoubayuHeal.UI.RanksSuffix)
            dragGhost:Show()
        end
        dragging = { fromFlow = false, entry = this.entry }
        this:SetAlpha(0.25)
        UI.DragUpdate()
    end)

    block:SetScript("OnDragStop", function()
        this:SetAlpha(1)
        if dragGhost then
            dragGhost:Hide()
        end
        if dropIndicator then
            dropIndicator:Hide()
        end

        -- 拖拽在卡片外松手时 OnClick 不会触发：清掉起点标志，
        -- 防止陈旧坐标吞掉下一次正常点击
        if not GoubayuHeal_UI_IsCursorInside(block) then
            dragStartX, dragStartY = nil, nil
        end

        local wasFromLibrary = dragging and not dragging.fromFlow
        local spellName = this.entry and this.entry.spell
        dragging = nil

        if wasFromLibrary and GoubayuHeal_UI_IsCursorInside(flowScroll)
            and spellName and UI.OpenSpellPicker then
            UI.OpenSpellPicker(spellName, nil)
        end
    end)

    block:SetScript("OnEnter", function()
        this:SetBackdropColor(0.16, 0.16, 0.16, 0.98)
    end)

    block:SetScript("OnLeave", function()
        this:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
    end)

    return block
end

-- 主窗口关闭时的附加清理（OnHide 回调；定义于拖拽局部变量之后）
function UI.OnMainWindowClosed()
    dragging = nil
    if dragGhost then
        dragGhost:Hide()
    end
    if dropIndicator then
        dropIndicator:Hide()
    end
    -- 拖拽中关窗时 OnDragStop 不会再触发：恢复被拖卡片的不透明度
    for _, c in ipairs(flowCards) do
        c:SetAlpha(1)
    end
    for _, c in ipairs(libraryCards) do
        c:SetAlpha(1)
    end
end

-- 清除流程卡片选中态（方案切换/增删入口调用；RedrawFlow 内不重置——
-- 否则点击选中→重绘→索引被清，编辑/删除按钮永不出现）
function UI.ResetFlowSelection()
    selectedFlowIndex = nil
end

function UI.RedrawFlow()
    flowEntries = GoubayuHeal_GetSortedFlowEntries()
    local count = table.getn(flowEntries)

    while count > table.getn(flowCards) do
        table.insert(flowCards, GoubayuHeal_CreateFlowCard())
    end

    for i = 1, table.getn(flowCards) do
        local card = flowCards[i]
        if i <= count then
            local entry = flowEntries[i]
            card.Refresh(card, entry, i)
            card.icon:SetTexture(GoubayuHeal_GetSpellIcon(entry.spell))

            if entry.attachment and GoubayuHeal.Spells and GoubayuHeal.Spells[entry.attachment] then
                card.attIcon:SetTexture(GoubayuHeal_GetSpellIcon(entry.attachment))
                card.attIcon:Show()
            else
                card.attIcon:SetTexture(nil)
                card.attIcon:Hide()
            end

            card.title:SetText(entry.spell)
            local descText = GoubayuHeal.UI.RankPrefix .. (entry.rank or 1)
            if entry.scale == 1 or entry.scale == true then
                descText = descText .. GoubayuHeal.UI.ScaleMark
            end
            if entry.attachment then
                descText = descText .. string.format(GoubayuHeal.UI.AttachMarkFmt, entry.attachment)
                    .. (entry.attachmentRank and ("(" .. entry.attachmentRank .. ")") or "")
            end
            card.desc:SetText(descText)
            card.pct:SetText(entry.percent .. "%")

            if i == selectedFlowIndex then
                card:SetBackdropColor(0.16, 0.16, 0.16, 0.98)
                card.editButton:Show()
                card.delButton:Show()
            else
                card:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
                card.editButton:Hide()
                card.delButton:Hide()
            end
        else
            card:Hide()
        end
    end

    GoubayuHeal_LayoutCards(flowCards, count, flowContent)
    UI.UpdateScrollBar(flowScroll, flowSlider, flowContent:GetHeight())

    if flowContent:GetHeight() > flowScroll:GetHeight() then
        flowSlider:Show()
    else
        flowSlider:Hide()
    end
end

function UI.RedrawLibrary()
    libraryEntries = GoubayuHeal_GetLibraryEntries()
    local count = table.getn(libraryEntries)

    while count > table.getn(libraryCards) do
        table.insert(libraryCards, GoubayuHeal_CreateLibraryCard())
    end

    for i = 1, table.getn(libraryCards) do
        local card = libraryCards[i]
        if i <= count then
            local entry = libraryEntries[i]
            card.entry = entry
            card.icon:SetTexture(entry.texture)
            card.title:SetText(entry.spell)
            card.desc:SetText(entry.ranks .. GoubayuHeal.UI.RanksSuffix)
        else
            card:Hide()
        end
    end

    GoubayuHeal_LayoutCards(libraryCards, count, libraryContent)
    UI.UpdateScrollBar(libraryScroll, librarySlider, libraryContent:GetHeight())

    if libraryContent:GetHeight() > libraryScroll:GetHeight() then
        librarySlider:Show()
    else
        librarySlider:Hide()
    end
end

function UI.RefreshSchemeDropDown()
    if not GoubayuHeal_GUIClassDropDownMenu then
        return
    end
    if GoubayuHeal.current_class then
        GoubayuHeal_GUIClassDropDownMenu:SetText(GoubayuHeal.current_class)
    end
end

-- ============================================================
-- 设置标签页
-- ============================================================

local settingsPanel = CreateFrame("Frame", nil, mainWindow)
settingsPanel:SetWidth(856)
settingsPanel:SetHeight(520)
settingsPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)
panels[2] = settingsPanel

local function GoubayuHeal_MakeSettingsSlider(parent, name, labelText, minVal, maxVal, step,
        variable, valueGetter)
    local slider = GoubayuHeal_UI_CreateSlider(parent, name, 150, 15)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider.variable = variable

    slider.userOnValueChanged = function()
        GoubayuHeal.UpdateSettings()
    end

    local low = getglobal(name .. "Low")
    if low then
        low:SetText(labelText)
    end

    local high = getglobal(name .. "High")
    if high then
        high:ClearAllPoints()
        high:SetPoint("LEFT", slider, "RIGHT", 4, 0)
    end

    slider.userOnShow = function()
        if valueGetter then
            local v = valueGetter()
            if v ~= nil then
                this:SetValue(v)
            end
        end
    end

    UI.SetTooltip(slider, labelText, (GoubayuHeal.GUI_desc and GoubayuHeal.GUI_desc[labelText])
        or labelText)

    return slider
end

local function GoubayuHeal_MakeSettingsCheckBox(parent, name, labelText, variable, valueGetter)
    local cb = GoubayuHeal_UI_CreateToggle(parent, name, 40, 20)
    cb.variable = variable

    cb.userOnClick = function()
        GoubayuHeal.UpdateSettings()
    end

    cb.userOnShow = function()
        if valueGetter then
            cb:SetChecked(valueGetter())
        end
    end

    local label = GoubayuHeal_UI_MakeFontString(parent, "OVERLAY", 10, 1, 1, 1)
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(labelText)

    UI.SetTooltip(cb, labelText, (GoubayuHeal.GUI_desc and GoubayuHeal.GUI_desc[labelText])
        or labelText)

    return cb, label
end

local settingsInset1 = CreateFrame("Frame", nil, settingsPanel)
settingsInset1:SetWidth(400)
settingsInset1:SetHeight(470)
settingsInset1:SetPoint("TOPLEFT", settingsPanel, "TOPLEFT", 10, -10)
UI.ApplyFlatBackdrop(settingsInset1, 0.05, 0.05, 0.05, 0.9)

local settingsInset2 = CreateFrame("Frame", nil, settingsPanel)
settingsInset2:SetWidth(420)
settingsInset2:SetHeight(470)
settingsInset2:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT", -10, -10)
UI.ApplyFlatBackdrop(settingsInset2, 0.05, 0.05, 0.05, 0.9)

-- Inset1 滑块
GoubayuHeal_MakeSettingsSlider(settingsInset1,
    "GoubayuHeal_GUIHOTMinCancelThresholdSlider",
    GoubayuHeal.GUI_hot_cancel, 0, 1, 0.01,
    'GoubayuHeal.Config["hot_heal_threshold"]',
    function() return GoubayuHeal.Config["hot_heal_threshold"] end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -24)

GoubayuHeal_MakeSettingsSlider(settingsInset1, "GoubayuHeal_GUIHOTMultiplySlider",
    GoubayuHeal.GUI_hot_value, 0, 4, 0.05,
    'GoubayuHeal.Config["hot_multiply"]',
    function() return GoubayuHeal.Config["hot_multiply"] end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -80)

GoubayuHeal_MakeSettingsSlider(settingsInset1, "GoubayuHeal_GUIHOTMultiplyBattleSlider",
    GoubayuHeal.GUI_hot_value_battle, 0, 4, 0.05,
    'GoubayuHeal.Config["hot_multiply_battle"]',
    function() return GoubayuHeal.Config["hot_multiply_battle"] end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -136)

GoubayuHeal_MakeSettingsSlider(settingsInset1, "GoubayuHeal_GUIMaxOverhealSlider",
    GoubayuHeal.GUI_max_overheal, 0, 1, 0.01,
    'GoubayuHeal.Config["max_overheal"]',
    function() return GoubayuHeal.Config["max_overheal"] end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -192)

GoubayuHeal_MakeSettingsSlider(settingsInset1, "GoubayuHeal_GUIMinHealThresholdSlider",
    GoubayuHeal.GUI_min_heal_threshold, 0, 1, 0.01,
    'GoubayuHeal.Config["min_heal_threshold"]',
    function() return GoubayuHeal.Config["min_heal_threshold"] end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -248)

GoubayuHeal_MakeSettingsSlider(settingsInset1, "GoubayuHeal_GUIHealPowerSlider",
    GoubayuHeal.GUI_heal_power, 0, 2, 0.05,
    'GoubayuHeal.Config["heal_power"]',
    function() return GoubayuHeal.Config["heal_power"] end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -304)

GoubayuHeal_MakeSettingsSlider(settingsInset1, "GoubayuHeal_GUIUpdatePlayerDataTimeSlider",
    GoubayuHeal.GUI_update_time, 1, 100, 1,
    'GoubayuHeal.Config["update_player_data_time"]',
    function() return (GoubayuHeal.Config["update_player_data_time"] or 2.5) * 10 end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -360)

GoubayuHeal_MakeSettingsSlider(settingsInset1, "GoubayuHeal_GUIHealStrategySlider",
    GoubayuHeal.GUI_heal_strategy, 1, 4, 1,
    'GoubayuHeal.Config["heal_strategy"]',
    function() return GoubayuHeal.Config["heal_strategy"] end
):SetPoint("TOPLEFT", settingsInset1, "TOPLEFT", 12, -416)

-- Nampower专用设置项
GoubayuHeal.NampowerOnlySettings = GoubayuHeal.NampowerOnlySettings or {}

-- Inset2 复选框 + 滑块
local healCharmed, healCharmedLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUIHealCharmedCheckButton",
    GoubayuHeal.GUI_heal_charmed,
    'GoubayuHeal.Config["heal_charmed"]',
    function() return GoubayuHeal.Config["heal_charmed"] == 1 end)
healCharmed:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -14)

GoubayuHeal_MakeSettingsSlider(settingsInset2, "GoubayuHeal_GUIHealerCountLimitSlider",
    GoubayuHeal.GUI_heal_count, 1, 10, 1,
    'GoubayuHeal.Config["healer_count_limit"]',
    function() return GoubayuHeal.Config["healer_count_limit"] end
):SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 12, -70)

table.insert(GoubayuHeal.NampowerOnlySettings, {
    c = getglobal("GoubayuHeal_GUIHealerCountLimitSlider"),
    l = getglobal("GoubayuHeal_GUIHealerCountLimitSliderLow")
})

local blockFaster, blockFasterLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUIBlockFasterHealersCheckButton",
    GoubayuHeal.GUI_Im_the_fastest,
    'GoubayuHeal.Config["block_faster_healers"]',
    function() return GoubayuHeal.Config["block_faster_healers"] == 1 end)
blockFaster:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -112)

table.insert(GoubayuHeal.NampowerOnlySettings, {
    c = blockFaster,
    l = blockFasterLabel
})

local scaleHot, scaleHotLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUIScaleHotCheckButton",
    GoubayuHeal.GUI_scale_hots,
    'GoubayuHeal.Config["scale_hots"]',
    function() return GoubayuHeal.Config["scale_hots"] == 1 end)
scaleHot:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -154)

local scaleSpells, scaleSpellsLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUIScaleSpellsCheckButton",
    GoubayuHeal.GUI_scale_spells,
    'GoubayuHeal.Config["scale_spells"]',
    function() return GoubayuHeal.Config["scale_spells"] == 1 end)
scaleSpells:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -196)

local safeCancel, safeCancelLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUISafeCancelCheckButton",
    GoubayuHeal.GUI_safe_cancel,
    'GoubayuHeal.Config["safe_cancel"]',
    function() return GoubayuHeal.Config["safe_cancel"] == 1 end)
safeCancel:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -238)

local tankTarget, tankTargetLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUITankTargetCheckButton",
    GoubayuHeal.GUI_always_tank_target,
    'GoubayuHeal.Config["always_tank_target"]',
    function() return GoubayuHeal.Config["always_tank_target"] == 1 end)
tankTarget:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -280)

local shapeshifted, shapeshiftedLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUIShapeshiftedDruidsCheckButton",
    GoubayuHeal.GUI_shapeshifted_druids,
    'GoubayuHeal.Config["shapeshifted_druids"]',
    function() return GoubayuHeal.Config["shapeshifted_druids"] == 1 end)
shapeshifted:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -322)

local scanCache, scanCacheLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUIScanCacheCheckButton",
    GoubayuHeal.GUI_scan_cache,
    'GoubayuHeal.Config["scan_cache"]',
    function() return GoubayuHeal.Config["scan_cache"] == 1 end)
scanCache:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -364)

local antiStarvation, antiStarvationLabel = GoubayuHeal_MakeSettingsCheckBox(settingsInset2,
    "GoubayuHeal_GUIAntiStarvationCheckButton",
    GoubayuHeal.GUI_anti_starvation,
    'GoubayuHeal.Config["heal_anti_starvation"]',
    function() return GoubayuHeal.Config["heal_anti_starvation"] == 1 end)
antiStarvation:SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 20, -448)

GoubayuHeal_MakeSettingsSlider(settingsInset2, "GoubayuHeal_GUINPQueueTimeoutSlider",
    GoubayuHeal.GUI_np_queue_timeout, 0.1, 3, 0.1,
    'GoubayuHeal.Config["nampower_queue_timeout"]',
    function() return GoubayuHeal.Config["nampower_queue_timeout"] or 1.0 end
):SetPoint("TOPLEFT", settingsInset2, "TOPLEFT", 12, -406)

table.insert(GoubayuHeal.NampowerOnlySettings, {
    c = getglobal("GoubayuHeal_GUINPQueueTimeoutSlider"),
    l = getglobal("GoubayuHeal_GUINPQueueTimeoutSliderLow")
})

-- ============================================================
-- 优先级标签页
-- ============================================================

local priorityPanel = CreateFrame("Frame", nil, mainWindow)
priorityPanel:SetWidth(856)
priorityPanel:SetHeight(500)
priorityPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)
panels[3] = priorityPanel

local function GoubayuHeal_MakePrioritySlider(parent, name, labelText, variable, color)
    local slider = GoubayuHeal_UI_CreateSlider(parent, name, 130, 15)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(0.01)
    slider.variable = variable

    slider.userOnValueChanged = function()
        GoubayuHeal.UpdateSettings()
    end

    local low = getglobal(name .. "Low")
    if low then
        low:SetText(labelText)
        if color then
            low:SetTextColor(color[1], color[2], color[3])
        end
    end

    local high = getglobal(name .. "High")
    if high then
        high:ClearAllPoints()
        high:SetPoint("LEFT", slider, "RIGHT", 4, 0)
    end

    slider.userOnShow = function()
        local cfgKey, constName = string.match(variable,
            'GoubayuHeal%.Config%["([^"]+)"%]%[GoubayuHeal%.([^%]]+)%]')
        if cfgKey and constName and GoubayuHeal.Config and GoubayuHeal.Config[cfgKey] then
            local classKey = GoubayuHeal[constName]
            this:SetValue(classKey and GoubayuHeal.Config[cfgKey][classKey] or 0)
        else
            cfgKey = string.match(variable, 'GoubayuHeal%.Config%["([^"]+)"%]')
            if cfgKey and GoubayuHeal.Config then
                this:SetValue(GoubayuHeal.Config[cfgKey] or 0)
            end
        end
    end

    UI.SetTooltip(slider, labelText, (GoubayuHeal.GUI_desc and GoubayuHeal.GUI_desc[labelText])
        or labelText)

    return slider
end

-- 左侧：玩家/小队/团队/宠物/MT
local playersInset = CreateFrame("Frame", nil, priorityPanel)
playersInset:SetWidth(300)
playersInset:SetHeight(250)
playersInset:SetPoint("TOPLEFT", priorityPanel, "TOPLEFT", 10, -10)
UI.ApplyFlatBackdrop(playersInset, 0.05, 0.05, 0.05, 0.9)

GoubayuHeal_MakePrioritySlider(playersInset, "GoubayuHeal_GUIPlayerPrioritySlider",
    GoubayuHeal.GUI_player_priority,
    'GoubayuHeal.Config["player_priority"]'):SetPoint("TOPLEFT", playersInset, "TOPLEFT", 12, -24)

GoubayuHeal_MakePrioritySlider(playersInset, "GoubayuHeal_GUIPartyPrioritySlider",
    GoubayuHeal.GUI_party_priority,
    'GoubayuHeal.Config["party_priority"]'):SetPoint("TOPLEFT", playersInset, "TOPLEFT", 12, -68)

GoubayuHeal_MakePrioritySlider(playersInset, "GoubayuHeal_GUIRaidPrioritySlider",
    GoubayuHeal.GUI_raid_priority,
    'GoubayuHeal.Config["raid_priority"]'):SetPoint("TOPLEFT", playersInset, "TOPLEFT", 12, -112)

GoubayuHeal_MakePrioritySlider(playersInset, "GoubayuHeal_GUIPetPrioritySlider",
    GoubayuHeal.GUI_pet_priority,
    'GoubayuHeal.Config["pet_priority"]'):SetPoint("TOPLEFT", playersInset, "TOPLEFT", 12, -156)

GoubayuHeal_MakePrioritySlider(playersInset, "GoubayuHeal_GUIMTPrioritySlider",
    GoubayuHeal.GUI_MT_priority,
    'GoubayuHeal.Config["MT_priority"]', { 0.9, 0.2, 0.1 }
):SetPoint("TOPLEFT", playersInset, "TOPLEFT", 12, -200)

-- 右侧：buff/debuff
local buffInset = CreateFrame("Frame", nil, priorityPanel)
buffInset:SetWidth(300)
buffInset:SetHeight(250)
buffInset:SetPoint("TOPLEFT", playersInset, "TOPRIGHT", 10, 0)
UI.ApplyFlatBackdrop(buffInset, 0.05, 0.05, 0.05, 0.9)

GoubayuHeal_MakePrioritySlider(buffInset, "GoubayuHeal_GUIBOPPrioritySlider",
    GoubayuHeal.GUI_bop_priority,
    'GoubayuHeal.Config["buff_affect_priority"][GoubayuHeal.Blessing_of_protection]',
    { 0.2, 0.9, 0.1 }
):SetPoint("TOPLEFT", buffInset, "TOPLEFT", 12, -24)

GoubayuHeal_MakePrioritySlider(buffInset, "GoubayuHeal_GUIPWSPrioritySlider",
    GoubayuHeal.GUI_pws_priority,
    'GoubayuHeal.Config["buff_affect_priority"][GoubayuHeal.Power_word_shield]',
    { 0.2, 0.9, 0.1 }
):SetPoint("TOPLEFT", buffInset, "TOPLEFT", 12, -68)

GoubayuHeal_MakePrioritySlider(buffInset, "GoubayuHeal_GUIRBPrioritySlider",
    GoubayuHeal.GUI_rb_priority,
    'GoubayuHeal.Config["debuff_affect_priority"][GoubayuHeal.Recently_bandaged]',
    { 0.9, 0.2, 0.1 }
):SetPoint("TOPLEFT", buffInset, "TOPLEFT", 12, -112)

GoubayuHeal_MakePrioritySlider(buffInset, "GoubayuHeal_GUIWSPrioritySlider",
    GoubayuHeal.GUI_ws_priority,
    'GoubayuHeal.Config["debuff_affect_priority"][GoubayuHeal.Weakened_soul]',
    { 0.9, 0.2, 0.1 }
):SetPoint("TOPLEFT", buffInset, "TOPLEFT", 12, -156)

GoubayuHeal_MakePrioritySlider(buffInset, "GoubayuHeal_GUIMSPrioritySlider",
    GoubayuHeal.GUI_ms_priority,
    'GoubayuHeal.Config["debuff_affect_priority"][GoubayuHeal.Mortal_strike]',
    { 0.9, 0.2, 0.1 }
):SetPoint("TOPLEFT", buffInset, "TOPLEFT", 12, -200)

-- 下方：职业优先级
local classesInset = CreateFrame("Frame", nil, priorityPanel)
classesInset:SetWidth(836)
classesInset:SetHeight(230)
classesInset:SetPoint("TOPLEFT", playersInset, "BOTTOMLEFT", 0, -10)
UI.ApplyFlatBackdrop(classesInset, 0.05, 0.05, 0.05, 0.9)

local classColorMap = {
    DRUID = { 1, 0.49, 0.04 },
    HUNTER = { 0.67, 0.83, 0.45 },
    MAGE = { 0.41, 0.8, 0.94 },
    PALADIN = { 0.96, 0.55, 0.73 },
    PRIEST = { 1, 1, 1 },
    ROGUE = { 1, 0.96, 0.41 },
    SHAMAN = { 0, 0.44, 0.87 },
    WARLOCK = { 0.58, 0.51, 0.79 },
    WARRIOR = { 0.78, 0.61, 0.43 }
}

local classPriorityList = {
    { key = "GoubayuHeal_GUIDruidPrioritySlider", label = GoubayuHeal.GUI_druid_priority,
        c = classColorMap.DRUID },
    { key = "GoubayuHeal_GUIHunterPrioritySlider", label = GoubayuHeal.GUI_hunter_priority,
        c = classColorMap.HUNTER },
    { key = "GoubayuHeal_GUIMagePrioritySlider", label = GoubayuHeal.GUI_mage_priority,
        c = classColorMap.MAGE },
    { key = "GoubayuHeal_GUIPaladinPriestPrioritySlider", label = GoubayuHeal.GUI_paladin_priority,
        c = classColorMap.PALADIN },
    { key = "GoubayuHeal_GUIPriestRoguePrioritySlider", label = GoubayuHeal.GUI_priest_priority,
        c = classColorMap.PRIEST },
    { key = "GoubayuHeal_GUIRoguePrioritySlider", label = GoubayuHeal.GUI_rogue_priority,
        c = classColorMap.ROGUE },
    { key = "GoubayuHeal_GUIShamanPrioritySlider", label = GoubayuHeal.GUI_shaman_priority,
        c = classColorMap.SHAMAN },
    { key = "GoubayuHeal_GUIWarlockPrioritySlider", label = GoubayuHeal.GUI_warlock_priority,
        c = classColorMap.WARLOCK },
    { key = "GoubayuHeal_GUIWarriorPrioritySlider", label = GoubayuHeal.GUI_warrior_priority,
        c = classColorMap.WARRIOR }
}

local classVarList = {
    'GoubayuHeal.Config["class_priority"]["DRUID"]',
    'GoubayuHeal.Config["class_priority"]["HUNTER"]',
    'GoubayuHeal.Config["class_priority"]["MAGE"]',
    'GoubayuHeal.Config["class_priority"]["PALADIN"]',
    'GoubayuHeal.Config["class_priority"]["PRIEST"]',
    'GoubayuHeal.Config["class_priority"]["ROGUE"]',
    'GoubayuHeal.Config["class_priority"]["SHAMAN"]',
    'GoubayuHeal.Config["class_priority"]["WARLOCK"]',
    'GoubayuHeal.Config["class_priority"]["WARRIOR"]'
}

for i = 1, 9 do
    local item = classPriorityList[i]
    local classVarStr = classVarList[i]
    local slider = GoubayuHeal_UI_CreateSlider(classesInset, item.key, 180, 15)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(0.01)
    slider.variable = classVarStr

    slider.userOnValueChanged = function()
        local cfgKey, classFile = string.match(classVarStr,
            'GoubayuHeal%.Config%["([^"]+)"%]%["([^"]+)"%]')
        if cfgKey and classFile and GoubayuHeal.Config then
            GoubayuHeal.Config[cfgKey] = GoubayuHeal.Config[cfgKey] or {}
            GoubayuHeal.Config[cfgKey][classFile] = slider:GetValue()
        end
        local high = getglobal(item.key .. "High")
        if high then
            high:SetText(math.floor(slider:GetValue() * 100 + 0.5) .. "%")
        end
    end

    local low = getglobal(item.key .. "Low")
    if low then
        low:SetText(item.label)
        low:SetTextColor(item.c[1], item.c[2], item.c[3])
    end

    local high = getglobal(item.key .. "High")
    if high then
        high:ClearAllPoints()
        high:SetPoint("LEFT", slider, "RIGHT", 4, 0)
    end

    slider.userOnShow = function()
        local cfgKey, classFile = string.match(classVarStr,
            'GoubayuHeal%.Config%["([^"]+)"%]%["([^"]+)"%]')
        if cfgKey and classFile and GoubayuHeal.Config and GoubayuHeal.Config[cfgKey] then
            slider:SetValue(GoubayuHeal.Config[cfgKey][classFile] or 0)
        end
    end

    UI.SetTooltip(slider, item.label, (GoubayuHeal.GUI_desc and GoubayuHeal.GUI_desc[item.label])
        or item.label)

    local col = math.mod(i - 1, 3)
    local row = math.floor((i - 1) / 3)
    slider:SetPoint("TOPLEFT", classesInset, "TOPLEFT", 20 + col * 270, -24 - row * 46)
end

-- ============================================================
-- 团队标签页
-- ============================================================

local raidPanel = CreateFrame("Frame", "GoubayuHeal_GUIRaid", mainWindow)
raidPanel:SetWidth(856)
raidPanel:SetHeight(500)
raidPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)

raidPanel:SetScript("OnShow", function()
    if GoubayuHeal.SetRaidChecked then
        GoubayuHeal.SetRaidChecked()
    end
end)

panels[4] = raidPanel

-- 精细化优先级开关
local refinedCb, refinedCbLabel = GoubayuHeal_MakeSettingsCheckBox(raidPanel,
    "GoubayuHeal_GUIRaidRefinedPriorityCheckButton",
    GoubayuHeal.GUI_refined_priority,
    'GoubayuHeal.Config["raid_refined_priority"]',
    function() return GoubayuHeal.Config["raid_refined_priority"] == 1 end)
refinedCb:SetPoint("TOPLEFT", raidPanel, "TOPLEFT", 20, -10)

local refinedOrigClick = refinedCb.userOnClick
refinedCb.userOnClick = function()
    if refinedOrigClick then
        refinedOrigClick()
    end
    if GoubayuHeal.SetRaidChecked then
        GoubayuHeal.SetRaidChecked()
    end
end
UI.SetTooltip(refinedCb, GoubayuHeal.GUI_refined_priority,
    GoubayuHeal.UI.PerSchemeTip_Refined)

-- 重置按钮
local resetButton = GoubayuHeal_UI_CreateFlatButton(raidPanel,
    "GoubayuHeal_GUIRaidResetPriorityButton", 100, 26,
    GoubayuHeal.GUI_reset_priority)
resetButton:SetPoint("LEFT", refinedCbLabel, "RIGHT", 12, 0)

resetButton:SetScript("OnClick", function()
    if not GoubayuHeal.Config then
        return
    end
    if not GoubayuHeal.Config["raid_priorities"] then
        GoubayuHeal.Config["raid_priorities"] = {}
    end
    if GoubayuHeal.raid_members then
        for name in pairs(GoubayuHeal.raid_members) do
            GoubayuHeal.Config["raid_priorities"][name] = 0.5
        end
    end
    GoubayuHeal.SetRaidChecked()
end)
UI.SetTooltip(resetButton, GoubayuHeal.GUI_reset_priority, GoubayuHeal.UI.ResetTip)

-- 反向按钮
local invertButton = GoubayuHeal_UI_CreateFlatButton(raidPanel,
    "GoubayuHeal_GUIRaidInvertPriorityButton", 80, 26,
    GoubayuHeal.GUI_invert_priority)
invertButton:SetPoint("LEFT", resetButton, "RIGHT", 12, 0)

invertButton:SetScript("OnClick", function()
    if not GoubayuHeal.Config then
        return
    end
    if not GoubayuHeal.Config["raid_priorities"] then
        GoubayuHeal.Config["raid_priorities"] = {}
    end
    if GoubayuHeal.raid_members then
        for name in pairs(GoubayuHeal.raid_members) do
            GoubayuHeal.Config["raid_priorities"][name] = 1 - (GoubayuHeal.Config["raid_priorities"][name]
                or 0.5)
        end
    end
    GoubayuHeal.SetRaidChecked()
end)
UI.SetTooltip(invertButton, GoubayuHeal.GUI_invert_priority, GoubayuHeal.UI.InvertTip)

-- 清空坦克标记
local clearRolesButton = GoubayuHeal_UI_CreateFlatButton(raidPanel,
    "GoubayuHeal_GUIRaidClearRolesButton", 120, 26,
    GoubayuHeal.GUI_clear_roles)
clearRolesButton:SetPoint("LEFT", invertButton, "RIGHT", 12, 0)

clearRolesButton:SetScript("OnClick", function()
    if not GoubayuHeal.Config then
        return
    end
    if not GoubayuHeal.Config["raid_roles"] then
        GoubayuHeal.Config["raid_roles"] = {}
    end
    for name in pairs(GoubayuHeal.Config["raid_roles"]) do
        GoubayuHeal.Config["raid_roles"][name] = nil
    end
    GoubayuHeal.Tank = { ["Unit"] = nil, ["Name"] = nil }
    GoubayuHeal.SetRaidChecked()
end)
UI.SetTooltip(clearRolesButton, GoubayuHeal.GUI_clear_roles, GoubayuHeal.UI.ClearRolesTip)

-- 角色标记菜单
local roleMenu = CreateFrame("Frame", nil, UIParent)
roleMenu:SetWidth(64)
roleMenu:SetHeight(9 * 20 + 4)
roleMenu:SetFrameStrata("DIALOG")
roleMenu:SetFrameLevel(60)
roleMenu:EnableMouse(true)
UI.ApplyFlatBackdrop(roleMenu, 0.035, 0.035, 0.035, 1)
roleMenu:Hide()
GoubayuHeal_GUIRoleMenu = roleMenu

local roleTarget = nil
local roleOptions = { GoubayuHeal.Msg.RoleNone, "MT", "2T", "3T", "4T", "5T", "6T", "7T", "8T" }

for i = 1, 9 do
    local opt = roleOptions[i]
    local b = CreateFrame("Button", nil, roleMenu)
    b:SetWidth(62)
    b:SetHeight(18)
    b:SetPoint("TOPLEFT", roleMenu, "TOPLEFT", 1, -1 - (i - 1) * 20)

    local hl = b:CreateTexture(nil, "BACKGROUND")
    hl:SetAllPoints()
    hl:SetTexture("Interface\\Buttons\\WHITE8X8")
    hl:SetVertexColor(0.32, 0.19, 0.02, 0.55)
    hl:Hide()

    local t = GoubayuHeal_UI_MakeFontString(b, "OVERLAY", 10, 1, 1, 1)
    t:SetPoint("LEFT", b, "LEFT", 6, 0)
    t:SetText(opt)

    if opt == "MT" then
        t:SetTextColor(1, 0.35, 0.2)
    elseif opt ~= GoubayuHeal.Msg.RoleNone then
        t:SetTextColor(1, 0.7, 0.3)
    else
        t:SetTextColor(0.6, 0.6, 0.6)
    end

    b:SetScript("OnEnter", function()
        hl:Show()
    end)

    b:SetScript("OnLeave", function()
        hl:Hide()
    end)

    b:SetScript("OnClick", function()
        if roleTarget then
            GoubayuHeal.SetRaidRole(roleTarget, opt)
            roleTarget = nil
        end
        roleMenu:Hide()
    end)
end

-- ============================================================
-- 防护恐惧结界优先级菜单（仅牧师）：无 / 1..10
-- by 武藤纯子酱 2026.9.21
-- ============================================================

local isPriestUI = (select(2, UnitClass("player")) == "PRIEST")
local fwMenu = nil
local fwTarget = nil

if isPriestUI then
    fwMenu = CreateFrame("Frame", nil, UIParent)
    fwMenu:SetWidth(56)
    fwMenu:SetHeight(11 * 20 + 4)
    fwMenu:SetFrameStrata("DIALOG")
    fwMenu:SetFrameLevel(60)
    fwMenu:EnableMouse(true)
    UI.ApplyFlatBackdrop(fwMenu, 0.035, 0.035, 0.035, 1)
    fwMenu:Hide()
    GoubayuHeal_GUIFWMenu = fwMenu

    for i = 1, 11 do
        local fwValue = nil
        local label = GoubayuHeal.Msg.RoleNone
        if i > 1 then
            -- 菜单按优先级从高到低排列：10 最高、1 最低
            fwValue = 12 - i
            label = tostring(fwValue)
        end

        local b = CreateFrame("Button", nil, fwMenu)
        b:SetWidth(54)
        b:SetHeight(18)
        b:SetPoint("TOPLEFT", fwMenu, "TOPLEFT", 1, -1 - (i - 1) * 20)

        local hl = b:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetVertexColor(0.12, 0.22, 0.32, 0.55)
        hl:Hide()

        local t = GoubayuHeal_UI_MakeFontString(b, "OVERLAY", 10, 1, 1, 1)
        t:SetPoint("LEFT", b, "LEFT", 6, 0)
        t:SetText(label)
        if fwValue then
            t:SetTextColor(0.55, 0.8, 1)
        else
            t:SetTextColor(0.6, 0.6, 0.6)
        end

        b:SetScript("OnEnter", function() hl:Show() end)
        b:SetScript("OnLeave", function() hl:Hide() end)
        b:SetScript("OnClick", function()
            if fwTarget then
                GoubayuHeal.SetFearWardPriority(fwTarget, fwValue)
                fwTarget = nil
            end
            fwMenu:Hide()
        end)
    end
end

-- 8组队伍
for group = 1, 8 do
    local gf = CreateFrame("Frame", "GoubayuHeal_GUIRaidGroup" .. group, raidPanel)
    gf:SetWidth(180)
    gf:SetHeight(195)
    gf:SetID(group)
    UI.ApplyFlatBackdrop(gf, 0.05, 0.05, 0.05, 0.9)

    local label = CreateFrame("Button", "GoubayuHeal_GUIRaidGroup" .. group .. "Label", gf)
    label:SetWidth(160)
    label:SetHeight(16)
    label:SetPoint("TOP", gf, "TOP", 0, -2)

    local lt = GoubayuHeal_UI_MakeFontString(label, "OVERLAY", 11, 1, 0.565, 0)
    lt:SetPoint("CENTER", label, "CENTER", 0, 0)
    lt:SetText(GoubayuHeal.Msg.GroupPrefix .. group)

    UI.SetTooltip(label, GoubayuHeal.Msg.GroupPrefix .. group,
        GoubayuHeal.UI.MemberSliderTip)

    for slot = 1, 5 do
        local g2 = group
        local s2 = slot
        local slotFrame = CreateFrame("Frame", "GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot,
            gf)
        slotFrame:SetWidth(176)
        slotFrame:SetHeight(33)
        slotFrame:SetID(slot)
        slotFrame:SetPoint("TOPLEFT", gf, "TOPLEFT", 4, -20 - (slot - 1) * 34)

        local nm = slotFrame:CreateFontString(
            "GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot .. "Name",
            "OVERLAY", "GameFontNormal")
        nm:SetFont(FONT, 10, "OUTLINE")
        nm:SetTextColor(0.72, 0.72, 0.72)
        nm:SetJustifyH("LEFT")
        nm:SetText("")

        -- 角色标记按钮
        local roleBtn = CreateFrame("Button", "GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
            .. "RoleButton", slotFrame)
        roleBtn:SetWidth(38)
        roleBtn:SetHeight(14)
        UI.ApplyFlatBackdrop(roleBtn, 0.055, 0.055, 0.055, 0.95)

        local rt = GoubayuHeal_UI_MakeFontString(roleBtn, "OVERLAY", 9, 0.6, 0.6, 0.6)
        rt:SetPoint("CENTER", roleBtn, "CENTER", 0, 0)
        rt:SetText(GoubayuHeal.Msg.RoleNone)
        roleBtn.roleText = rt

        roleBtn.SetText = function(self, value)
            self.roleText:SetText(value)
            if value == "MT" then
                self.roleText:SetTextColor(1, 0.35, 0.2)
            elseif value and value ~= GoubayuHeal.Msg.RoleNone then
                self.roleText:SetTextColor(1, 0.7, 0.3)
            else
                self.roleText:SetTextColor(0.6, 0.6, 0.6)
            end
        end

        -- 左侧标记框用途提示（此前无提示，用户不知道这个下拉是做什么的）
        -- by 武藤纯子酱 2026.9.21
        UI.SetTooltip(roleBtn, GoubayuHeal.UI.RoleBoxTitle, GoubayuHeal.UI.RoleBoxTip)

        roleBtn:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 12, 0)
        nm:ClearAllPoints()
        nm:SetPoint("LEFT", roleBtn, "RIGHT", 6, 0)

        -- 牧师：名字右侧再加一个"防护恐惧结界优先级"下拉（无/1..10），名字相应收窄
        -- by 武藤纯子酱 2026.9.21
        if isPriestUI then
            nm:SetWidth(84)

            local fwBtn = CreateFrame("Button", "GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                .. "FWButton", slotFrame)
            fwBtn:SetWidth(28)
            fwBtn:SetHeight(14)
            UI.ApplyFlatBackdrop(fwBtn, 0.055, 0.055, 0.055, 0.95)

            local ft = GoubayuHeal_UI_MakeFontString(fwBtn, "OVERLAY", 9, 0.6, 0.6, 0.6)
            ft:SetPoint("CENTER", fwBtn, "CENTER", 0, 0)
            ft:SetText(GoubayuHeal.Msg.RoleNone)
            fwBtn.fwText = ft

            fwBtn.SetText = function(self, value)
                self.fwText:SetText(value)
                if (value and value ~= GoubayuHeal.Msg.RoleNone) then
                    self.fwText:SetTextColor(0.55, 0.8, 1)
                else
                    self.fwText:SetTextColor(0.5, 0.5, 0.5)
                end
            end

            fwBtn:SetPoint("TOPRIGHT", slotFrame, "TOPRIGHT", -2, 0)
            UI.SetTooltip(fwBtn, GoubayuHeal.Fear_ward, GoubayuHeal.UI.FearWardTip)

            fwBtn:SetScript("OnClick", function()
                if not fwMenu then
                    return
                end
                if fwMenu:IsVisible() then
                    fwMenu:Hide()
                    fwTarget = nil
                    return
                end

                local nmf = getglobal("GoubayuHeal_GUIRaidGroup" .. g2 .. "Slot" .. s2 .. "Name")
                local memberName = nmf and nmf:GetText() or ""
                if memberName == "" then
                    return
                end

                fwTarget = memberName
                fwMenu:ClearAllPoints()
                fwMenu:SetPoint("TOPRIGHT", fwBtn, "BOTTOMRIGHT", 0, -2)

                local bBottom = fwBtn:GetBottom()
                local mH = fwMenu:GetHeight()
                if bBottom and (bBottom - mH - 2) < 0 then
                    fwMenu:ClearAllPoints()
                    fwMenu:SetPoint("BOTTOMRIGHT", fwBtn, "TOPRIGHT", 0, 2)
                end

                fwMenu:Show()
            end)
        else
            nm:SetWidth(118)
        end

        roleBtn:SetScript("OnClick", function()
            if roleMenu:IsVisible() then
                roleMenu:Hide()
                roleTarget = nil
                return
            end

            local nmf = getglobal("GoubayuHeal_GUIRaidGroup" .. g2 .. "Slot" .. s2 .. "Name")
            local memberName = nmf and nmf:GetText() or ""
            if memberName == "" then
                return
            end

            roleTarget = memberName
            roleMenu:ClearAllPoints()
            roleMenu:SetPoint("TOPRIGHT", roleBtn, "BOTTOMRIGHT", 0, -2)

            local bBottom = roleBtn:GetBottom()
            local mH = roleMenu:GetHeight()
            if bBottom and (bBottom - mH - 2) < 0 then
                roleMenu:ClearAllPoints()
                roleMenu:SetPoint("BOTTOMRIGHT", roleBtn, "TOPRIGHT", 0, 2)
            end

            roleMenu:Show()
        end)

        -- 个人优先级滑块
        local slider = CreateFrame("Slider",
            "GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot .. "PrioritySlider", slotFrame)
        slider:SetWidth(128)
        slider:SetHeight(10)
        slider:SetOrientation("HORIZONTAL")
        slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")

        local rail = slider:CreateTexture(nil, "BACKGROUND")
        rail:SetTexture("Interface\\Buttons\\WHITE8X8")
        rail:SetHeight(4)
        rail:SetPoint("LEFT", slider, "LEFT", 0, 0)
        rail:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
        rail:SetPoint("CENTER", slider, "CENTER", 0, 0)
        rail:SetVertexColor(0.25, 0.25, 0.25, 0.8)
        slider.railTex = rail

        local fill = slider:CreateTexture(nil, "ARTWORK")
        fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        fill:SetHeight(4)
        fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
        fill:SetPoint("CENTER", slider, "CENTER", 0, 0)
        fill:SetVertexColor(0.78, 0.56, 0.25, 1)
        slider.fillTex = fill

        local thumb = slider:GetThumbTexture()
        if thumb then
            thumb:SetWidth(12)
            thumb:SetHeight(12)
            thumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
        end

        local pct = slotFrame:CreateFontString(
            "GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot .. "PriorityPct",
            "OVERLAY", "GameFontNormalSmall")
        pct:SetPoint("LEFT", slider, "RIGHT", 3, 0)
        pct:SetTextColor(1, 1, 1)
        pct:SetText("50%")

        local function UpdatePriorityFill()
            local minV, maxV = slider:GetMinMaxValues()
            local v = slider:GetValue()
            local span = maxV - minV
            local ratio = 0
            if span > 0 then
                ratio = (v - minV) / span
            end
            if ratio < 0 then
                ratio = 0
            end
            if ratio > 1 then
                ratio = 1
            end
            local w = slider:GetWidth() - 12
            if w < 0 then
                w = 0
            end
            fill:SetWidth(w * ratio)
        end

        slider:SetScript("OnValueChanged", function()
            UpdatePriorityFill()
            local val = slider:GetValue()
            pct:SetText(math.floor(val * 100 + 0.5) .. "%")

            local nmf2 = getglobal("GoubayuHeal_GUIRaidGroup" .. g2 .. "Slot" .. s2 .. "Name")
            local memberName = nmf2 and nmf2:GetText() or ""

            if memberName == "" then
                if math.floor(slider:GetValue() * 100 + 0.5) ~= 50 then
                    slider:SetValue(0.5)
                end
                pct:SetText("50%")
                return
            end

            if not GoubayuHeal.Config["raid_priorities"] then
                GoubayuHeal.Config["raid_priorities"] = {}
            end
            GoubayuHeal.Config["raid_priorities"][memberName] = val
        end)

        slider:SetScript("OnShow", function()
            UpdatePriorityFill()
            pct:SetText(math.floor(slider:GetValue() * 100 + 0.5) .. "%")
        end)

        slider:SetMinMaxValues(0, 1)
        slider:SetValueStep(0.01)
        slider:SetValue(0.5)
        slider:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 12, -17)
    end

    local col = math.mod(group - 1, 4)
    local row = math.floor((group - 1) / 4)
    gf:SetPoint("TOPLEFT", raidPanel, "TOPLEFT", 20 + col * 205, -48 - row * 200)
end

-- ============================================================
-- HOT标签页
-- ============================================================

local hotPanel = CreateFrame("Frame", "GoubayuHeal_GUIHot", mainWindow)
hotPanel:SetWidth(856)
hotPanel:SetHeight(500)
hotPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)

hotPanel:SetScript("OnShow", function()
    if GoubayuHeal.SetHotMaintain then
        GoubayuHeal.SetHotMaintain()
    end
    if UI.HotRefresh then
        UI.HotRefresh()
    end
end)

panels[5] = hotPanel

-- 启用HOT维持开关
local hotEnabledCb, hotEnabledLabel = GoubayuHeal_MakeSettingsCheckBox(hotPanel,
    "GoubayuHeal_GUIHotEnabledCheckButton",
    GoubayuHeal.GUI_hot_enabled,
    'GoubayuHeal.Config["raid_hots_enabled"]',
    function() return GoubayuHeal.Config["raid_hots_enabled"] == 1 end)
hotEnabledCb:SetPoint("TOPLEFT", hotPanel, "TOPLEFT", 20, -10)
UI.SetTooltip(hotEnabledCb, GoubayuHeal.GUI_hot_enabled,
    GoubayuHeal.UI.HotEnabledTip)

-- 清空按钮
local hotClearButton = GoubayuHeal_UI_CreateFlatButton(hotPanel, "GoubayuHeal_GUIHotClearButton",
    80, 26, GoubayuHeal.GUI_hot_clear)
hotClearButton:SetPoint("LEFT", hotEnabledLabel, "RIGHT", 12, 0)

hotClearButton:SetScript("OnClick", function()
    if not GoubayuHeal.Config then
        return
    end
    if not GoubayuHeal.Config["raid_hots"] then
        GoubayuHeal.Config["raid_hots"] = {}
    end
    for name in pairs(GoubayuHeal.Config["raid_hots"]) do
        GoubayuHeal.Config["raid_hots"][name] = nil
    end
    if GoubayuHeal.SetHotMaintain then
        GoubayuHeal.SetHotMaintain()
    end
end)
UI.SetTooltip(hotClearButton, GoubayuHeal.GUI_hot_clear, GoubayuHeal.UI.HotClearTip)

-- HOT维持阈值
local hotPrioLabel = GoubayuHeal_UI_MakeFontString(hotPanel, "OVERLAY", 10, 1, 1, 1)
hotPrioLabel:SetPoint("LEFT", hotClearButton, "RIGHT", 40, 0)
hotPrioLabel:SetWidth(72)
hotPrioLabel:SetText(GoubayuHeal.UI.HotPrioLabel)

local hotPrioritySlider = CreateFrame("Slider", "GoubayuHeal_GUIHotPrioritySlider", hotPanel)
hotPrioritySlider:SetWidth(120)
hotPrioritySlider:SetHeight(12)
hotPrioritySlider:SetOrientation("HORIZONTAL")
hotPrioritySlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
hotPrioritySlider:SetPoint("LEFT", hotPrioLabel, "RIGHT", 8, 0)

local hpRail = hotPrioritySlider:CreateTexture(nil, "BACKGROUND")
hpRail:SetTexture("Interface\\Buttons\\WHITE8X8")
hpRail:SetHeight(4)
hpRail:SetPoint("LEFT", hotPrioritySlider, "LEFT", 0, 0)
hpRail:SetPoint("RIGHT", hotPrioritySlider, "RIGHT", 0, 0)
hpRail:SetPoint("CENTER", hotPrioritySlider, "CENTER", 0, 0)
hpRail:SetVertexColor(0.25, 0.25, 0.25, 0.8)

local hpFill = hotPrioritySlider:CreateTexture(nil, "ARTWORK")
hpFill:SetTexture("Interface\\Buttons\\WHITE8X8")
hpFill:SetHeight(4)
hpFill:SetPoint("LEFT", hotPrioritySlider, "LEFT", 0, 0)
hpFill:SetPoint("CENTER", hotPrioritySlider, "CENTER", 0, 0)
hpFill:SetVertexColor(0.78, 0.56, 0.25, 1)

local hpThumb = hotPrioritySlider:GetThumbTexture()
if hpThumb then
    hpThumb:SetWidth(12)
    hpThumb:SetHeight(12)
    hpThumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
end

local hotPrioPct = GoubayuHeal_UI_MakeFontString(hotPanel, "OVERLAY", 10, 1, 1, 1)
hotPrioPct:SetPoint("LEFT", hotPrioritySlider, "RIGHT", 8, 0)
hotPrioPct:SetWidth(36)
hotPrioPct:SetText("80%")

local function UpdateHotPrioFill()
    local minV, maxV = hotPrioritySlider:GetMinMaxValues()
    local v = hotPrioritySlider:GetValue()
    local span = maxV - minV
    local ratio = 0
    if span > 0 then
        ratio = (v - minV) / span
    end
    if ratio < 0 then
        ratio = 0
    end
    if ratio > 1 then
        ratio = 1
    end
    local w = hotPrioritySlider:GetWidth() - 12
    if w < 0 then
        w = 0
    end
    hpFill:SetWidth(w * ratio)
end

hotPrioritySlider:SetScript("OnValueChanged", function()
    UpdateHotPrioFill()
    local v = hotPrioritySlider:GetValue()
    hotPrioPct:SetText(math.floor(v * 100 + 0.5) .. "%")
    if GoubayuHeal.Config then
        GoubayuHeal.Config["raid_hots_priority"] = v
    end
end)

hotPrioritySlider:SetScript("OnShow", function()
    local v = GoubayuHeal.Config and GoubayuHeal.Config["raid_hots_priority"] or 0.8
    hotPrioritySlider:SetValue(v)
    hotPrioPct:SetText(math.floor(v * 100 + 0.5) .. "%")
end)

hotPrioritySlider:SetMinMaxValues(0, 1)
hotPrioritySlider:SetValueStep(0.01)
hotPrioritySlider:SetValue(0.8)
UI.SetTooltip(hotPrioritySlider, GoubayuHeal.UI.HotPrioLabel,
    GoubayuHeal.UI.HotPrioTip)

-- HOT菜单
local hotSpells = (GoubayuHeal.hot_maintain_spells and GoubayuHeal.hot_maintain_spells[
    GoubayuHeal.my_class]) or {}
local hotCount = table.getn(hotSpells)

local hotHint = GoubayuHeal_UI_MakeFontString(hotPanel, "OVERLAY", 12, 0.72, 0.72, 0.72)
hotHint:SetPoint("TOP", hotPanel, "TOP", 0, -24)
hotHint:SetText(GoubayuHeal.UI.HotNoHots)

-- 共享HOT等级菜单
local hotMenu = CreateFrame("Frame", nil, UIParent)
hotMenu:SetWidth(72)
hotMenu:SetHeight(60)
hotMenu:SetFrameStrata("DIALOG")
hotMenu:SetFrameLevel(60)
hotMenu:EnableMouse(true)
UI.ApplyFlatBackdrop(hotMenu, 0.035, 0.035, 0.035, 1)
hotMenu:Hide()
GoubayuHeal_GUIHotMenu = hotMenu

local hotMenuData = nil
local hotMenuButtons = {}

local function OpenHotMenu(data, anchor)
    hotMenuData = data
    local maxRank = 0
    if GoubayuHeal.Spells and GoubayuHeal.Spells[data.spell] then
        maxRank = table.getn(GoubayuHeal.Spells[data.spell])
    end

    local options = { GoubayuHeal.Msg.RoleNone }
    for r = 1, maxRank do
        table.insert(options, tostring(r))
    end

    while table.getn(hotMenuButtons) < table.getn(options) do
        local i = table.getn(hotMenuButtons) + 1
        local b = CreateFrame("Button", nil, hotMenu)
        b:SetWidth(70)
        b:SetHeight(18)
        b:SetPoint("TOPLEFT", hotMenu, "TOPLEFT", 1, -1 - (i - 1) * 20)

        local hl = b:CreateTexture(nil, "BACKGROUND")
        hl:SetAllPoints()
        hl:SetTexture("Interface\\Buttons\\WHITE8X8")
        hl:SetVertexColor(0.32, 0.19, 0.02, 0.55)
        hl:Hide()

        local t = GoubayuHeal_UI_MakeFontString(b, "OVERLAY", 10, 1, 1, 1)
        t:SetPoint("LEFT", b, "LEFT", 6, 0)

        b.hl = hl
        b.t = t

        b:SetScript("OnEnter", function()
            this.hl:Show()
        end)

        b:SetScript("OnLeave", function()
            this.hl:Hide()
        end)

        b:SetScript("OnClick", function()
            if hotMenuData then
                GoubayuHeal.SetHotRank(hotMenuData.name, hotMenuData.spell, this.opt)
                hotMenuData = nil
            end
            hotMenu:Hide()
        end)

        table.insert(hotMenuButtons, b)
    end

    hotMenu:SetHeight(table.getn(options) * 20 + 4)

    for i, b in ipairs(hotMenuButtons) do
        if i <= table.getn(options) then
            b.opt = options[i]
            b.t:SetText(options[i])
            b:Show()
        else
            b:Hide()
        end
    end

    hotMenu:ClearAllPoints()
    hotMenu:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)

    local bBottom = anchor:GetBottom()
    local mH = hotMenu:GetHeight()
    if bBottom and (bBottom - mH - 2) < 0 then
        hotMenu:ClearAllPoints()
        hotMenu:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    end

    hotMenu:Show()
end

-- 8组队伍
local hotGroups = {}

for group = 1, 8 do
    local gf = CreateFrame("Frame", "GoubayuHeal_GUIHotGroup" .. group, hotPanel)
    gf:SetWidth(180)
    gf:SetHeight(195)
    gf:SetID(group)
    UI.ApplyFlatBackdrop(gf, 0.05, 0.05, 0.05, 0.9)

    local label = GoubayuHeal_UI_MakeFontString(gf, "OVERLAY", 11, 1, 0.565, 0)
    label:SetPoint("TOP", gf, "TOP", 0, -2)
    label:SetText(GoubayuHeal.Msg.GroupPrefix .. group)

    for slot = 1, 5 do
        local g2 = group
        local s2 = slot
        local slotFrame = CreateFrame("Frame", "GoubayuHeal_GUIHotGroup" .. group .. "Slot" .. slot,
            gf)
        slotFrame:SetWidth(176)
        slotFrame:SetHeight(33)
        slotFrame:SetID(slot)
        slotFrame:SetPoint("TOPLEFT", gf, "TOPLEFT", 4, -20 - (slot - 1) * 34)

        local nm = slotFrame:CreateFontString(
            "GoubayuHeal_GUIHotGroup" .. group .. "Slot" .. slot .. "Name",
            "OVERLAY", "GameFontNormal")
        nm:SetFont(FONT, 10, "OUTLINE")
        nm:SetTextColor(0.72, 0.72, 0.72)
        nm:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 12, 0)
        nm:SetWidth(150)
        nm:SetText("")

        for hi = 1, hotCount do
            local hs = hotSpells[hi]
            local short = GoubayuHeal.hot_short_name and GoubayuHeal.hot_short_name[hs] or hs

            local hb = CreateFrame("Button",
                "GoubayuHeal_GUIHotGroup" .. group .. "Slot" .. slot .. "Hot" .. hi .. "Button",
                slotFrame)
            hb:SetWidth(76)
            hb:SetHeight(14)
            UI.ApplyFlatBackdrop(hb, 0.055, 0.055, 0.055, 0.95)

            local ht = GoubayuHeal_UI_MakeFontString(hb, "OVERLAY", 9, 1, 1, 1)
            ht:SetPoint("CENTER", hb, "CENTER", 0, 0)
            ht:SetText(short .. ":" .. GoubayuHeal.Msg.RoleNone)
            hb.t = ht

            hb.SetText = function(self, value)
                self.t:SetText(value)
            end

            hb:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 12 + (hi - 1) * 82, -16)

            hb:SetScript("OnClick", function()
                if hotMenu:IsVisible() then
                    hotMenu:Hide()
                    hotMenuData = nil
                    return
                end

                local nmf = getglobal("GoubayuHeal_GUIHotGroup" .. g2 .. "Slot" .. s2 .. "Name")
                local memberName = nmf and nmf:GetText() or ""
                if memberName == "" then
                    return
                end

                OpenHotMenu({ name = memberName, spell = hs }, hb)
            end)
        end
    end

    local col = math.mod(group - 1, 4)
    local row = math.floor((group - 1) / 4)
    gf:SetPoint("TOPLEFT", hotPanel, "TOPLEFT", 20 + col * 205, -48 - row * 200)
    hotGroups[group] = gf
end

function UI.HotRefresh()
    local spells = (GoubayuHeal.hot_maintain_spells and GoubayuHeal.hot_maintain_spells[
        GoubayuHeal.my_class]) or {}
    local hasHot = (table.getn(spells) > 0)

    local ctrls = { hotEnabledCb, hotEnabledLabel, hotClearButton, hotPrioLabel,
        hotPrioritySlider, hotPrioPct }

    for _, c in ipairs(ctrls) do
        if c then
            if hasHot then
                c:Show()
            else
                c:Hide()
            end
        end
    end

    for _, gf in ipairs(hotGroups) do
        if gf then
            if hasHot then
                gf:Show()
            else
                gf:Hide()
            end
        end
    end

    if hotHint then
        if hasHot then
            hotHint:Hide()
        else
            hotHint:Show()
        end
    end
end

-- ============================================================
-- 复活标签页
-- ============================================================

local rezPanel = CreateFrame("Frame", nil, mainWindow)
rezPanel:SetWidth(856)
rezPanel:SetHeight(500)
rezPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)
panels[6] = rezPanel

local function GoubayuHeal_RezMsg()
    local msg = GoubayuHeal.Config and GoubayuHeal.Config["rez_message"]
    if not msg or msg == "" then
        return GoubayuHeal.Msg.RezMessageDefault
    end
    return msg
end

local rezInset = CreateFrame("Frame", nil, rezPanel)
rezInset:SetWidth(816)
rezInset:SetHeight(120)
rezInset:SetPoint("TOPLEFT", rezPanel, "TOPLEFT", 20, -14)
UI.ApplyFlatBackdrop(rezInset, 0.05, 0.05, 0.05, 0.9)

local rezButton = GoubayuHeal_UI_CreateFlatButton(rezInset, "GoubayuHeal_GUIRezButton", 180, 30,
    GoubayuHeal.UI.RezButton)
rezButton:SetPoint("TOPLEFT", rezInset, "TOPLEFT", 20, -20)
UI.SetTooltip(rezButton, GoubayuHeal.UI.RezButton,
    GoubayuHeal.UI.RezButtonTip)
rezButton:SetScript("OnClick", function()
    GoubayuHeal.DoRez()
end)

local rezHint = GoubayuHeal_UI_MakeFontString(rezInset, "OVERLAY", 10, 0.6, 0.6, 0.6)
rezHint:SetPoint("TOPLEFT", rezButton, "BOTTOMLEFT", 0, -8)
rezHint:SetWidth(300)
rezHint:SetJustifyH("LEFT")
rezHint:SetText(GoubayuHeal.UI.RezHint)

-- 喊话内容
local rezMsgLabel = GoubayuHeal_UI_MakeFontString(rezInset, "OVERLAY", 11, 0.72, 0.72, 0.72)
rezMsgLabel:SetPoint("TOPLEFT", rezInset, "TOPLEFT", 240, -24)
rezMsgLabel:SetText(GoubayuHeal.UI.RezMsgLabel)

local rezMsgBox = CreateFrame("EditBox", "GoubayuHeal_GUIRezMessageBox", rezInset)
rezMsgBox:SetWidth(300)
rezMsgBox:SetHeight(22)
rezMsgBox:SetPoint("TOPLEFT", rezMsgLabel, "BOTTOMLEFT", 0, -4)
rezMsgBox:SetAutoFocus(false)
rezMsgBox:SetTextInsets(6, 6, 0, 0)
UI.ApplyFlatBackdrop(rezMsgBox, 0.04, 0.04, 0.04, 0.9)
rezMsgBox:SetFontObject(GameFontNormalSmall)
rezMsgBox:SetText(GoubayuHeal_RezMsg())

rezMsgBox:SetScript("OnEscapePressed", function()
    this:ClearFocus()
end)

rezMsgBox:SetScript("OnEnterPressed", function()
    GoubayuHeal.Config["rez_message"] = this:GetText()
    this:ClearFocus()
end)

rezMsgBox:SetScript("OnEditFocusLost", function()
    GoubayuHeal.Config["rez_message"] = this:GetText()
end)

UI.SetTooltip(rezMsgBox, GoubayuHeal.UI.RezMsgLabel, GoubayuHeal.UI.RezMsgTip)

-- 喊话频道
local rezChanLabel = GoubayuHeal_UI_MakeFontString(rezInset, "OVERLAY", 11, 0.72, 0.72, 0.72)
rezChanLabel:SetPoint("TOPLEFT", rezInset, "TOPLEFT", 560, -24)
rezChanLabel:SetText(GoubayuHeal.UI.RezChanLabel)

local rezChanDrop
rezChanDrop = UI.CreateDropDown(rezInset, 130, function()
    return { { text = "SAY" }, { text = "PARTY" }, { text = "RAID" }, { text = "NONE" } }
end, function(text)
    GoubayuHeal.Config["rez_message_channel"] = text
    rezChanDrop:SetText(text)
end)
rezChanDrop:SetPoint("TOPLEFT", rezChanLabel, "BOTTOMLEFT", 0, -4)
rezChanDrop:SetText((GoubayuHeal.Config and GoubayuHeal.Config["rez_message_channel"]) or "SAY")
UI.SetTooltip(rezChanDrop, GoubayuHeal.UI.RezChanLabel, GoubayuHeal.UI.RezChanTip)

rezPanel:SetScript("OnShow", function()
    if GoubayuHeal.Config then
        rezMsgBox:SetText(GoubayuHeal_RezMsg())
        rezChanDrop:SetText(GoubayuHeal.Config["rez_message_channel"] or "SAY")
    end
end)

-- 复活优先级
local rezPriInset = CreateFrame("Frame", nil, rezPanel)
rezPriInset:SetWidth(816)
rezPriInset:SetHeight(300)
rezPriInset:SetPoint("TOPLEFT", rezInset, "BOTTOMLEFT", 0, -10)
UI.ApplyFlatBackdrop(rezPriInset, 0.05, 0.05, 0.05, 0.9)

local rezPriTitle = GoubayuHeal_UI_MakeFontString(rezPriInset, "OVERLAY", 12, 1, 0.565, 0)
rezPriTitle:SetPoint("TOPLEFT", rezPriInset, "TOPLEFT", 10, -6)
rezPriTitle:SetText(GoubayuHeal.UI.RezPriTitle)

local rezClassList = {
    { key = "GoubayuHeal_GUIRezDruidSlider", label = GoubayuHeal.Druid, c = classColorMap.DRUID,
        cf = "DRUID" },
    { key = "GoubayuHeal_GUIRezHunterSlider", label = GoubayuHeal.Hunter, c = classColorMap.HUNTER,
        cf = "HUNTER" },
    { key = "GoubayuHeal_GUIRezMageSlider", label = GoubayuHeal.Mage, c = classColorMap.MAGE,
        cf = "MAGE" },
    { key = "GoubayuHeal_GUIRezPaladinSlider", label = GoubayuHeal.Paladin, c = classColorMap.PALADIN,
        cf = "PALADIN" },
    { key = "GoubayuHeal_GUIRezPriestSlider", label = GoubayuHeal.Priest, c = classColorMap.PRIEST,
        cf = "PRIEST" },
    { key = "GoubayuHeal_GUIRezRogueSlider", label = GoubayuHeal.Rogue, c = classColorMap.ROGUE,
        cf = "ROGUE" },
    { key = "GoubayuHeal_GUIRezShamanSlider", label = GoubayuHeal.Shaman, c = classColorMap.SHAMAN,
        cf = "SHAMAN" },
    { key = "GoubayuHeal_GUIRezWarlockSlider", label = GoubayuHeal.Warlock, c = classColorMap.WARLOCK,
        cf = "WARLOCK" },
    { key = "GoubayuHeal_GUIRezWarriorSlider", label = GoubayuHeal.Warrior, c = classColorMap.WARRIOR,
        cf = "WARRIOR" }
}

for i = 1, 9 do
    local item = rezClassList[i]
    local slider = GoubayuHeal_UI_CreateSlider(rezPriInset, item.key, 200, 15)
    slider:SetMinMaxValues(0, 1)
    slider:SetValueStep(0.01)

    slider.userOnValueChanged = function()
        GoubayuHeal.Config["rez_priority"] = GoubayuHeal.Config["rez_priority"] or {}
        GoubayuHeal.Config["rez_priority"][item.cf] = slider:GetValue()
        local high = getglobal(item.key .. "High")
        if high then
            high:SetText(math.floor(slider:GetValue() * 100 + 0.5) .. "%")
        end
    end

    local low = getglobal(item.key .. "Low")
    if low then
        low:SetText(item.label)
        low:SetTextColor(item.c[1], item.c[2], item.c[3])
    end

    local high = getglobal(item.key .. "High")
    if high then
        high:ClearAllPoints()
        high:SetPoint("LEFT", slider, "RIGHT", 4, 0)
    end

    slider.userOnShow = function()
        local rp = GoubayuHeal.Config and GoubayuHeal.Config["rez_priority"]
        slider:SetValue((rp and rp[item.cf]) or 0)
    end

    UI.SetTooltip(slider, item.label, GoubayuHeal.UI.RezSliderTip)

    local col = math.mod(i - 1, 3)
    local row = math.floor((i - 1) / 3)
    slider:SetPoint("TOPLEFT", rezPriInset, "TOPLEFT", 20 + col * 270, -58 - row * 46)
end

-- ============================================================
-- 驱散标签页
-- ============================================================

local function GoubayuHeal_UIDispelTab()
    local dispelPanel = CreateFrame("Frame", "GoubayuHeal_GUIDispel", mainWindow)
    dispelPanel:SetWidth(856)
    dispelPanel:SetHeight(545)
    dispelPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)

    dispelPanel:SetScript("OnShow", function()
        if GoubayuHeal.Dispel_RefreshAllEmbeddedLists then
            GoubayuHeal.Dispel_RefreshAllEmbeddedLists()
        end
    end)

    panels[7] = dispelPanel

    -- 驱散优先级按钮：驱散面板标题被隐藏时也能进入优先级设置
    local dispelPrioBtn = GoubayuHeal_UI_CreateFlatButton(dispelPanel, nil, 96, 22, GoubayuHeal.DispelUI.ButtonPriority)
    -- 移到左列"驱散优先阈值"下方，右上角留给"行为开关"分区
    -- by 武藤纯子酱 2026.9.21
    dispelPrioBtn:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 20, -216)
    dispelPrioBtn:SetScript("OnClick", function()
        if GoubayuHeal.Dispel_TogglePrioWindow then
            GoubayuHeal.Dispel_TogglePrioWindow()
        elseif GoubayuHeal.Dispel_CreatePrioWindow then
            GoubayuHeal.Dispel_CreatePrioWindow()
        end
    end)
    UI.SetTooltip(dispelPrioBtn, GoubayuHeal.UI.DispelPrioTipTitle, GoubayuHeal.UI.DispelPrioTipBody)

    local function MakeDispelToggle(key, label, x, y, onChange)
        local cb, cbl = GoubayuHeal_MakeSettingsCheckBox(dispelPanel,
            "GoubayuHeal_GUIDispel" .. key .. "CheckButton",
            label,
            'GoubayuHeal.Config["' .. key .. '"]',
            function() return GoubayuHeal.Config[key] == 1 end)
        cb:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", x, y)

        if onChange then
            local orig = cb.userOnClick
            cb.userOnClick = function()
                if orig then
                    orig()
                end
                onChange()
            end
        end
    end

    local function MakeDispelSlider(key, label, minV, maxV, step, x, y, onChange)
        -- 尺寸收紧：右列要放两列滑条（缩放/透明度同排），标签+滑条+百分比的整组宽度 ≤ 176
        -- by 武藤纯子酱 2026.9.21
        local lbl = GoubayuHeal_UI_MakeFontString(dispelPanel, "OVERLAY", 10, 1, 1, 1)
        lbl:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", x, y)
        lbl:SetWidth(76)
        lbl:SetText(label)

        local sl = CreateFrame("Slider", nil, dispelPanel)
        sl:SetWidth(62)
        sl:SetHeight(12)
        sl:SetOrientation("HORIZONTAL")
        sl:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
        sl:SetPoint("LEFT", lbl, "RIGHT", 6, 0)

        local rail = sl:CreateTexture(nil, "BACKGROUND")
        rail:SetTexture("Interface\\Buttons\\WHITE8X8")
        rail:SetHeight(4)
        rail:SetPoint("LEFT", sl, "LEFT", 0, 0)
        rail:SetPoint("RIGHT", sl, "RIGHT", 0, 0)
        rail:SetPoint("CENTER", sl, "CENTER", 0, 0)
        rail:SetVertexColor(0.25, 0.25, 0.25, 0.8)

        local fill = sl:CreateTexture(nil, "ARTWORK")
        fill:SetTexture("Interface\\Buttons\\WHITE8X8")
        fill:SetHeight(4)
        fill:SetPoint("LEFT", sl, "LEFT", 0, 0)
        fill:SetPoint("CENTER", sl, "CENTER", 0, 0)
        fill:SetVertexColor(0.78, 0.56, 0.25, 1)

        local thumb = sl:GetThumbTexture()
        if thumb then
            thumb:SetWidth(12)
            thumb:SetHeight(12)
            thumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
        end

        local pct = GoubayuHeal_UI_MakeFontString(dispelPanel, "OVERLAY", 10, 1, 1, 1)
        pct:SetPoint("LEFT", sl, "RIGHT", 4, 0)
        pct:SetWidth(40)

        local function UpdateFill()
            local mv = sl:GetValue()
            local span = maxV - minV
            local ratio = 0
            if span > 0 then
                ratio = (mv - minV) / span
            end
            if ratio < 0 then
                ratio = 0
            end
            if ratio > 1 then
                ratio = 1
            end
            local w = sl:GetWidth() - 12
            if w < 0 then
                w = 0
            end
            fill:SetWidth(w * ratio)
        end

        sl:SetScript("OnValueChanged", function()
            UpdateFill()
            local v = sl:GetValue()
            if step == 1 then
                v = math.floor(v + 0.5)
                pct:SetText(v)
            else
                -- 统一保留 2 位小数（先归整到 2 位，避免浮点尾差把显示挤成 "0..."）
                v = math.floor(v * 100 + 0.5) / 100
                pct:SetText(string.format("%.2f", v))
            end

            if GoubayuHeal.Config then
                GoubayuHeal.Config[key] = v
            end
            if onChange then
                onChange()
            end
        end)

        sl:SetScript("OnShow", function()
            local v = (GoubayuHeal.Config and GoubayuHeal.Config[key]) or minV
            sl:SetValue(v)
        end)

        sl:SetMinMaxValues(minV, maxV)
        sl:SetValueStep(step)
        sl:SetValue((GoubayuHeal.Config and GoubayuHeal.Config[key]) or minV)
    end

    -- 设置页分区标题（暗淡小标题，用于把开关按功能分组）
    -- by 武藤纯子酱 2026.9.21
    local function MakeSectionTitle(x, y, text)
        local t = GoubayuHeal_UI_MakeFontString(dispelPanel, "OVERLAY", 11, 0.72, 0.72, 0.72)
        t:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", x, y)
        t:SetText(text)
        return t
    end

    MakeSectionTitle(20, -8, GoubayuHeal.UI.DispelSecBasic)
    MakeSectionTitle(460, -8, GoubayuHeal.UI.DispelSecBehavior)

    -- 驱散开关
    local dispelEnabledCb, dispelEnabledLabel = GoubayuHeal_MakeSettingsCheckBox(dispelPanel,
        "GoubayuHeal_GUIDispelEnabledCheckButton",
        GoubayuHeal.GUI_dispel_enabled,
        'GoubayuHeal.Config["dispel_enabled"]',
        function() return GoubayuHeal.Config["dispel_enabled"] == 1 end)
    dispelEnabledCb:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 20, -28)

    local dispelEnabledOrig = dispelEnabledCb.userOnClick
    dispelEnabledCb.userOnClick = function()
        if dispelEnabledOrig then
            dispelEnabledOrig()
        end
        if GoubayuHeal.Dispel_ApplyEnabled then
            GoubayuHeal.Dispel_ApplyEnabled()
        end
    end
    UI.SetTooltip(dispelEnabledCb, GoubayuHeal.GUI_dispel_enabled, GoubayuHeal.UI.DispelEnabledTip)

    -- 驱散加入队列
    local dispelQueueCb, dispelQueueLabel = GoubayuHeal_MakeSettingsCheckBox(dispelPanel,
        "GoubayuHeal_GUIDispelQueueCheckButton",
        GoubayuHeal.GUI_dispel_queue,
        'GoubayuHeal.Config["dispel_queue"]',
        function() return GoubayuHeal.Config["dispel_queue"] == 1 end)
    dispelQueueCb:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 200, -28)
    UI.SetTooltip(dispelQueueCb, GoubayuHeal.GUI_dispel_queue,
    GoubayuHeal.UI.DispelQueueTip)

    -- 允许断条驱散
    local dispelInterruptCb, dispelInterruptLabel = GoubayuHeal_MakeSettingsCheckBox(dispelPanel,
        "GoubayuHeal_GUIDispelInterruptCheckButton",
        GoubayuHeal.GUI_dispel_interrupt,
        'GoubayuHeal.Config["dispel_interrupt"]',
        function() return GoubayuHeal.Config["dispel_interrupt"] == 1 end)
    dispelInterruptCb:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 20, -62)
    UI.SetTooltip(dispelInterruptCb, GoubayuHeal.GUI_dispel_interrupt, GoubayuHeal.UI.DispelInterruptTip)

    -- 隐藏驱散窗口
    local dispelHiddenCb, dispelHiddenLabel = GoubayuHeal_MakeSettingsCheckBox(dispelPanel,
        "GoubayuHeal_GUIDispelHiddenCheckButton",
        GoubayuHeal.GUI_dispel_hidden,
        'GoubayuHeal.Config["dispel_hidden"]',
        function() return GoubayuHeal.Config["dispel_hidden"] == 1 end)
    dispelHiddenCb:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 200, -62)

    local dispelHiddenOrig = dispelHiddenCb.userOnClick
    dispelHiddenCb.userOnClick = function()
        if dispelHiddenOrig then
            dispelHiddenOrig()
        end
        if GoubayuHeal.Dispel_ApplyHidden then
            GoubayuHeal.Dispel_ApplyHidden()
        end
    end
    UI.SetTooltip(dispelHiddenCb, GoubayuHeal.GUI_dispel_hidden, GoubayuHeal.UI.DispelHiddenTip)

    -- 驱散优先阈值
    local dispelPrioLabel = GoubayuHeal_UI_MakeFontString(dispelPanel, "OVERLAY", 10, 1, 1, 1)
    dispelPrioLabel:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 20, -184)
    dispelPrioLabel:SetWidth(72)
    dispelPrioLabel:SetText(GoubayuHeal.UI.DispelPrioThreshold)

    local dispelPrioSlider = CreateFrame("Slider", "GoubayuHeal_GUIDispelPrioritySlider",
        dispelPanel)
    dispelPrioSlider:SetWidth(130)
    dispelPrioSlider:SetHeight(12)
    dispelPrioSlider:SetOrientation("HORIZONTAL")
    dispelPrioSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    dispelPrioSlider:SetPoint("LEFT", dispelPrioLabel, "RIGHT", 8, 0)

    local dpRail = dispelPrioSlider:CreateTexture(nil, "BACKGROUND")
    dpRail:SetTexture("Interface\\Buttons\\WHITE8X8")
    dpRail:SetHeight(4)
    dpRail:SetPoint("LEFT", dispelPrioSlider, "LEFT", 0, 0)
    dpRail:SetPoint("RIGHT", dispelPrioSlider, "RIGHT", 0, 0)
    dpRail:SetPoint("CENTER", dispelPrioSlider, "CENTER", 0, 0)
    dpRail:SetVertexColor(0.25, 0.25, 0.25, 0.8)

    local dpFill = dispelPrioSlider:CreateTexture(nil, "ARTWORK")
    dpFill:SetTexture("Interface\\Buttons\\WHITE8X8")
    dpFill:SetHeight(4)
    dpFill:SetPoint("LEFT", dispelPrioSlider, "LEFT", 0, 0)
    dpFill:SetPoint("CENTER", dispelPrioSlider, "CENTER", 0, 0)
    dpFill:SetVertexColor(0.78, 0.56, 0.25, 1)

    local dpThumb = dispelPrioSlider:GetThumbTexture()
    if dpThumb then
        dpThumb:SetWidth(12)
        dpThumb:SetHeight(12)
        dpThumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
    end

    local dispelPrioPct = GoubayuHeal_UI_MakeFontString(dispelPanel, "OVERLAY", 10, 1, 1, 1)
    dispelPrioPct:SetPoint("LEFT", dispelPrioSlider, "RIGHT", 8, 0)
    dispelPrioPct:SetWidth(36)
    dispelPrioPct:SetText("50%")

    local function UpdateDispelPrioFill()
        local minV, maxV = dispelPrioSlider:GetMinMaxValues()
        local v = dispelPrioSlider:GetValue()
        local span = maxV - minV
        local ratio = 0
        if span > 0 then
            ratio = (v - minV) / span
        end
        if ratio < 0 then
            ratio = 0
        end
        if ratio > 1 then
            ratio = 1
        end
        local w = dispelPrioSlider:GetWidth() - 12
        if w < 0 then
            w = 0
        end
        dpFill:SetWidth(w * ratio)
    end

    dispelPrioSlider:SetScript("OnValueChanged", function()
        UpdateDispelPrioFill()
        local v = dispelPrioSlider:GetValue()
        dispelPrioPct:SetText(math.floor(v * 100 + 0.5) .. "%")
        if GoubayuHeal.Config then
            GoubayuHeal.Config["dispel_priority"] = v
        end
    end)

    dispelPrioSlider:SetScript("OnShow", function()
        local v = GoubayuHeal.Config and GoubayuHeal.Config["dispel_priority"] or 0.5
        dispelPrioSlider:SetValue(v)
        dispelPrioPct:SetText(math.floor(v * 100 + 0.5) .. "%")
    end)

    dispelPrioSlider:SetMinMaxValues(0, 1)
    dispelPrioSlider:SetValueStep(0.01)
    dispelPrioSlider:SetValue(0.5)
    UI.SetTooltip(dispelPrioSlider, GoubayuHeal.UI.DispelPrioThreshold,
    GoubayuHeal.UI.DispelPrioThresholdTip)

    -- 驱散类型过滤
    local dispelFilterLabel = GoubayuHeal_UI_MakeFontString(dispelPanel, "OVERLAY", 11, 0.72, 0.72,
        0.72)
    dispelFilterLabel:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 20, -96)
    dispelFilterLabel:SetText(GoubayuHeal.UI.DispelFilterLabel)

    local dispelShortMap = GoubayuHeal.DispelTypeShort

    for i = 1, 5 do
        local t = ({ "Magic", "Disease", "Poison", "Curse", "Snare" })[i]
        local label = (GoubayuHeal.GUI_dispel_type and GoubayuHeal.GUI_dispel_type[t]) or t
        local cb, cbLabel = GoubayuHeal_MakeSettingsCheckBox(dispelPanel,
            "GoubayuHeal_GUIDispelFilter" .. t .. "CheckButton",
            label,
            'GoubayuHeal.Config["dispel_filters"]["' .. t .. '"]',
            function() return GoubayuHeal.Config["dispel_filters"][t] == 1 end)

        local fcol = math.mod(i - 1, 3)
        local frow = math.floor((i - 1) / 3)
        cb:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", 20 + fcol * 150, -116 - frow * 34)

        local usable = GoubayuHeal.Dispel_ClassCanDispelType and GoubayuHeal.Dispel_ClassCanDispelType(
            t)
        if not usable then
            cb:Disable()
            cbLabel:SetTextColor(0.5, 0.5, 0.5)
            UI.SetTooltip(cb, label, string.format(GoubayuHeal.UI.CantDispelFmt, (dispelShortMap[t] or t)))
        end
    end

    -- 行为开关（右侧分区：两列五行）
    MakeDispelToggle("dispel_pets", GoubayuHeal.UI.DispelPets, 460, -28, nil)
    MakeDispelToggle("dispel_wyvern_sting", GoubayuHeal.UI.DispelWyvern, 660, -28, nil)
    MakeDispelToggle("dispel_mutating_injection", GoubayuHeal.UI.DispelMutating, 460, -60, nil)
    MakeDispelToggle("dispel_ignore_abolish", GoubayuHeal.UI.ForceDispel, 660, -60, nil)
    MakeDispelToggle("dispel_shadowform", GoubayuHeal.UI.ShadowformFilter, 460, -92, nil)
    MakeDispelToggle("dispel_print", GoubayuHeal.UI.DispelPrint, 660, -92, nil)
    MakeDispelToggle("dispel_backdrop", GoubayuHeal.UI.ShowBackdrop, 460, -124, function()
        if GoubayuHeal.Dispel_ApplyWindowStyle then
            GoubayuHeal.Dispel_ApplyWindowStyle()
        end
    end)
    MakeDispelToggle("dispel_show_header", GoubayuHeal.UI.ShowHeader, 660, -124, function()
        if GoubayuHeal.Dispel_ApplyWindowStyle then
            GoubayuHeal.Dispel_ApplyWindowStyle()
        end
    end)
    MakeDispelToggle("dispel_lock", GoubayuHeal.UI.LockWindow, 460, -156, function()
        if GoubayuHeal.Dispel_ApplyWindowStyle then
            GoubayuHeal.Dispel_ApplyWindowStyle()
        end
    end)
    MakeDispelToggle("dispel_flip", GoubayuHeal.UI.FlipUI, 660, -156, function()
        if GoubayuHeal.Dispel_ApplyWindowStyle then
            GoubayuHeal.Dispel_ApplyWindowStyle()
        end
        if GoubayuHeal.Dispel_UpdateWindow then
            GoubayuHeal.Dispel_UpdateWindow()
        end
    end)

    -- 窗口外观（右侧分区下半）
    MakeSectionTitle(460, -190, GoubayuHeal.UI.DispelSecAppearance)
    -- 两行布局：每行行首与"窗口外观"标题左对齐（第一行两列）
    -- by 武藤纯子酱 2026.9.21
    MakeDispelSlider("dispel_scale", GoubayuHeal.UI.Scale, 0.5, 1.25, 0.01, 460, -210, function()
        if GoubayuHeal.Dispel_ApplyWindowStyle then
            GoubayuHeal.Dispel_ApplyWindowStyle()
        end
    end)
    MakeDispelSlider("dispel_opacity", GoubayuHeal.UI.Opacity, 0, 1, 0.01, 648, -210, function()
        if GoubayuHeal.Dispel_ApplyWindowStyle then
            GoubayuHeal.Dispel_ApplyWindowStyle()
        end
    end)
    MakeDispelSlider("dispel_buttons", GoubayuHeal.UI.ShowDebuffs, 1, 15, 1, 460, -244, function()
        if GoubayuHeal.Dispel_ApplyWindowStyle then
            GoubayuHeal.Dispel_ApplyWindowStyle()
        end
    end)

    -- 内嵌键值列表（宽度/高度可配：现在三个列表并排放在页面底部）
    -- by 武藤纯子酱 2026.9.21
    local function MakeEmbeddedList(key, title, x, y, tooltip, classList, width, height)
        local boxW = width or 370
        local boxH = height or 128
        local innerW = boxW - 16
        local btnW = (innerW >= 300) and 52 or 46
        local editW = innerW - btnW * 2 - 8
        local scrollW = innerW - 6
        local scrollH = boxH - 46
        local rowW = scrollW
        local rowTextW = rowW - 34

        local box = CreateFrame("Frame", nil, dispelPanel)
        box:SetWidth(boxW)
        box:SetHeight(boxH)
        box:SetPoint("TOPLEFT", dispelPanel, "TOPLEFT", x, y)
        box:EnableMouse(true)
        UI.ApplyFlatBackdrop(box, 0.05, 0.05, 0.05, 0.9)

        local t = GoubayuHeal_UI_MakeFontString(box, "OVERLAY", 10, 1, 0.565, 0)
        t:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -4)
        t:SetText(title)
        box.titleText = t
        box.baseTitle = title

        if classList then
            -- selectedClass 必须用"职业 token"（如 WARRIOR）：配置键是 token，
            -- 而 GoubayuHeal.my_class 是 UnitClass 第1返回值=本地化职业名（如"战士"），
            -- 用它会让初始刷新查不到该职业的隐藏清单（必须手动点一次下拉才显示）
            -- by 武藤纯子酱 2026.9.21
            box.selectedClass = select(2, UnitClass("player")) or classList[1]

            local classDD
            classDD = UI.CreateDropDown(box, 84, function()
                local list = {}
                for _, cf in ipairs(classList) do
                    table.insert(list, { text = GoubayuHeal.Dispel_ClassName(cf) or cf, class = cf })
                end
                return list
            end, function(text, button, info)
                local cf = info and info.class
                if cf then
                    box.selectedClass = cf
                end
                if classDD then
                    classDD:SetText(text)
                end
                GoubayuHeal.Dispel_RefreshEmbeddedList(box)
            end)

            classDD:SetPoint("TOPLEFT", t, "TOPRIGHT", 6, 2)
            classDD:SetHeight(18)
            classDD:SetText(GoubayuHeal.Dispel_ClassName(box.selectedClass))
            box.classDD = classDD
        end

        local function boxTarget()
            local cfg = GoubayuHeal.Config or {}
            local tbl = cfg[key] or {}
            cfg[key] = tbl

            if box.selectedClass then
                if not tbl[box.selectedClass] then
                    tbl[box.selectedClass] = {}
                end
                tbl = tbl[box.selectedClass]
            end

            return tbl
        end

        local edit = CreateFrame("EditBox", nil, box)
        edit:SetWidth(editW)
        edit:SetHeight(20)
        edit:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -22)
        edit:SetAutoFocus(false)
        edit:SetTextInsets(4, 4, 0, 0)
        UI.ApplyFlatBackdrop(edit, 0.025, 0.025, 0.025, 0.9)
        edit:SetFontObject(GameFontNormalSmall)
        edit:SetTextColor(1, 1, 1)

        local addBtn = GoubayuHeal_UI_CreateFlatButton(box, nil, btnW, 18, GoubayuHeal.UI.Add)
        addBtn:SetPoint("LEFT", edit, "RIGHT", 4, 0)

        addBtn:SetScript("OnClick", function()
            local txt = edit:GetText()
            if txt and txt ~= "" then
                boxTarget()[txt] = true
                edit:SetText("")
                GoubayuHeal.Dispel_RefreshEmbeddedList(box)
            end
        end)

        local resetBtn = GoubayuHeal_UI_CreateFlatButton(box, nil, btnW, 18, GoubayuHeal.UI.Reset)
        resetBtn:SetPoint("LEFT", addBtn, "RIGHT", 4, 0)

        resetBtn:SetScript("OnClick", function()
            local defaults = GoubayuHeal.Dispel_DefaultFor and GoubayuHeal.Dispel_DefaultFor(key,
                box.selectedClass) or {}
            if box.selectedClass then
                local cfg = GoubayuHeal.Config or {}
                cfg[key] = cfg[key] or {}
                cfg[key][box.selectedClass] = defaults
            else
                GoubayuHeal.Config[key] = defaults
            end
            GoubayuHeal.Dispel_RefreshEmbeddedList(box)
        end)

        local listScroll, listContent, listSlider = UI.CreateScrollArea(box, scrollW, scrollH)
        listScroll:SetPoint("TOPLEFT", box, "TOPLEFT", 8, -44)
        listSlider:SetPoint("TOPRIGHT", box, "TOPRIGHT", -4, -44)
        -- 底端锚在框内（此前 -2 让滑块底部探出框外） by 武藤纯子酱 2026.9.21
        listSlider:SetPoint("BOTTOMRIGHT", box, "BOTTOMRIGHT", -4, 2)

        box.key = key
        box.edit = edit
        box.scroll = listScroll
        box.content = listContent
        box.slider = listSlider
        box.rows = {}

        -- 行按需创建（上限 box.maxRows）：此前固定 20 行，条目更多时只在标题显示 (N/20)，
        -- 列表里看不到（黑名单条目一多就会漏显，例如"腐蚀之种"）
        -- by 武藤纯子酱 2026.9.21
        box.maxRows = 200

        local function createRow(i)
            local row = CreateFrame("Button", nil, listContent)
            row:SetWidth(rowW)
            row:SetHeight(18)
            row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -2 - (i - 1) * 18)
            -- OnClick 里有右键删除分支，必须显式注册右键（1.12 默认只响应左键）
            row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            UI.ApplyFlatBackdrop(row, 0.03, 0.03, 0.03, 0.6)

            local hl = row:CreateTexture(nil, "BACKGROUND")
            hl:SetAllPoints()
            hl:SetTexture("Interface\\Buttons\\WHITE8X8")
            hl:SetVertexColor(0.32, 0.19, 0.02, 0.4)
            hl:Hide()

            local txt = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            txt:SetPoint("LEFT", row, "LEFT", 4, 0)
            txt:SetWidth(rowTextW)
            txt:SetJustifyH("LEFT")
            txt:SetTextColor(1, 1, 1)

            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetWidth(16)
            delBtn:SetHeight(16)
            delBtn:SetPoint("RIGHT", row, "RIGHT", -2, 0)

            delBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                tile = true,
                tileSize = 8,
                edgeSize = 1,
                insets = { left = 1, right = 1, top = 1, bottom = 1 }
            })
            delBtn:SetBackdropColor(0.35, 0.08, 0.08, 0.98)
            delBtn:SetBackdropBorderColor(0.55, 0.3, 0.3, 0.9)

            local dt = delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            dt:SetPoint("CENTER", delBtn, "CENTER", 0, 0)
            dt:SetTextColor(1, 0.7, 0.7)
            dt:SetText("X")
            delBtn:Hide()

            row:SetScript("OnEnter", function()
                hl:Show()
                if not row.selected then
                    row:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
                end
            end)

            row:SetScript("OnLeave", function()
                hl:Hide()
                if not row.selected then
                    row:SetBackdropColor(0.03, 0.03, 0.03, 0.6)
                end
            end)

            row:SetScript("OnClick", function()
                if arg1 == "RightButton" then
                    if row.name then
                        boxTarget()[row.name] = nil
                        GoubayuHeal.Dispel_RefreshEmbeddedList(box)
                    end
                    return
                end

                if row.selected then
                    row.selected = false
                    row.delBtn:Hide()
                    row:SetBackdropColor(0.03, 0.03, 0.03, 0.6)
                else
                    for _, r in ipairs(box.rows) do
                        r.selected = false
                        r.delBtn:Hide()
                        if r:IsShown() then
                            r:SetBackdropColor(0.03, 0.03, 0.03, 0.6)
                        end
                    end
                    row.selected = true
                    row.delBtn:Show()
                    row:SetBackdropColor(0.16, 0.16, 0.16, 0.98)
                end
            end)

            delBtn:SetScript("OnClick", function()
                if row.name then
                    boxTarget()[row.name] = nil
                    GoubayuHeal.Dispel_RefreshEmbeddedList(box)
                end
            end)

            row.delBtn = delBtn
            row.text = txt
            row:Hide()
            box.rows[i] = row
        end

        box.createRow = createRow

        for i = 1, 20 do
            createRow(i)
        end

        UI.SetTooltip(box, title, tooltip)

        GoubayuHeal.Dispel_EmbeddedBoxes = GoubayuHeal.Dispel_EmbeddedBoxes or {}
        GoubayuHeal.Dispel_EmbeddedBoxes[key] = box
        GoubayuHeal.Dispel_RefreshEmbeddedList(box)
    end

    function GoubayuHeal.Dispel_RefreshEmbeddedList(box)
        if not box or not box.key then
            return
        end

        local tbl
        if box.selectedClass then
            local fc = (GoubayuHeal.Config and GoubayuHeal.Config[box.key]) or {}
            if type(fc[box.selectedClass]) == "table" then
                tbl = fc[box.selectedClass]
            else
                tbl = {}
            end
        else
            tbl = (GoubayuHeal.Config and GoubayuHeal.Config[box.key]) or {}
        end

        local names = {}
        for name in pairs(tbl) do
            table.insert(names, name)
        end
        table.sort(names)

        -- 行数不足则按需补建（最多 maxRows），让所有条目都能在列表里看到（可滚动）
        -- by 武藤纯子酱 2026.9.21
        if box.createRow then
            local maxRows = box.maxRows or 200
            while table.getn(box.rows) < table.getn(names)
                and table.getn(box.rows) < maxRows do
                box.createRow(table.getn(box.rows) + 1)
            end
        end

        -- 行数按需创建后，仅当条目超过 maxRows 才需要标题计数提示
        local visibleMax = table.getn(box.rows)
        if box.titleText then
            if table.getn(names) > visibleMax then
                box.titleText:SetText(box.baseTitle .. " (" .. table.getn(names) .. "/" .. visibleMax .. ")")
            else
                box.titleText:SetText(box.baseTitle)
            end
        end

        local n = 0
        for _, name in ipairs(names) do
            n = n + 1
            if n > visibleMax then
                break
            end
            local row = box.rows[n]
            if row then
                row.name = name
                row.selected = false
                if row.delBtn then
                    row.delBtn:Hide()
                end
                row.text:SetText(name)
                row:Show()
            end
        end

        for i = n + 1, table.getn(box.rows) do
            if box.rows[i] then
                box.rows[i].selected = false
                if box.rows[i].delBtn then
                    box.rows[i].delBtn:Hide()
                end
                box.rows[i]:Hide()
            end
        end

        if box.content then
            local totalHeight = math.min(n, visibleMax) * 18 + 2
            box.content:SetHeight(totalHeight)

            if box.slider and box.scroll then
                local maximum = totalHeight - box.scroll:GetHeight()
                if maximum < 0 then
                    maximum = 0
                end
                box.slider:SetMinMaxValues(0, maximum)
                if maximum <= 0 then
                    box.slider:SetAlpha(0.25)
                else
                    box.slider:SetAlpha(1)
                end
            end
        end
    end

    function GoubayuHeal.Dispel_RefreshAllEmbeddedLists()
        if not GoubayuHeal.Dispel_EmbeddedBoxes then
            return
        end
        for _, box in pairs(GoubayuHeal.Dispel_EmbeddedBoxes) do
            if GoubayuHeal.Dispel_RefreshEmbeddedList then
                GoubayuHeal.Dispel_RefreshEmbeddedList(box)
            end
        end
    end

    -- 三个列表并排放在页面底部（各 255 宽 × 220 高，横向排列；整体上移 20px）
    -- by 武藤纯子酱 2026.9.21
    MakeEmbeddedList("dispel_blacklist", GoubayuHeal.UI.Blacklist, 20, -298,
        GoubayuHeal.UI.BlacklistTip, nil, 255, 220)
    MakeEmbeddedList("dispel_filter_class", GoubayuHeal.UI.ClassHide, 300, -298,
        GoubayuHeal.UI.ClassHideTip, GoubayuHeal.DispelClassList, 255, 220)
    MakeEmbeddedList("dispel_filter_debuffs", GoubayuHeal.UI.HideDebuffs, 580, -298,
        GoubayuHeal.UI.HideDebuffsTip, nil, 255, 220)
end

pcall(GoubayuHeal_UIDispelTab)

-- ============================================================
-- 高级标签页
-- ============================================================

local advPanel = CreateFrame("Frame", nil, mainWindow)
advPanel:SetWidth(856)
advPanel:SetHeight(500)
advPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)
panels[8] = advPanel

local advInset1 = CreateFrame("Frame", nil, advPanel)
advInset1:SetWidth(400)
advInset1:SetHeight(200)
advInset1:SetPoint("TOPLEFT", advPanel, "TOPLEFT", 20, -14)
UI.ApplyFlatBackdrop(advInset1, 0.05, 0.05, 0.05, 0.9)

GoubayuHeal_MakeSettingsSlider(advInset1, "GoubayuHeal_GUICastTimeDebuff_ValueSlider",
    GoubayuHeal.GUI_CastTime_Debuff, 0, 500, 5,
    'GoubayuHeal.Config["CastTime_Debuff"]',
    function() return GoubayuHeal.Config["CastTime_Debuff"] end
):SetPoint("TOPLEFT", advInset1, "TOPLEFT", 20, -36)

GoubayuHeal_MakeSettingsSlider(advInset1, "GoubayuHeal_GUIMTCastTimeDebuff_ValueSlider",
    GoubayuHeal.GUI_MTCastTime_Debuff, 0, 1000, 10,
    'GoubayuHeal.Config["MTCastTime_Debuff"]',
    function() return GoubayuHeal.Config["MTCastTime_Debuff"] end
):SetPoint("TOPLEFT", advInset1, "TOPLEFT", 20, -92)

-- 档案管理
local profileLabel = GoubayuHeal_UI_MakeFontString(advPanel, "OVERLAY", 11, 0.72, 0.72, 0.72)
profileLabel:SetPoint("BOTTOMLEFT", advPanel, "BOTTOMLEFT", 30, 30)
profileLabel:SetText(GoubayuHeal.UI.ProfileLabel)

GoubayuHeal_GUIProfileDropDownMenu = UI.CreateDropDown(advPanel, 150, function()
    local list = {}
    if not GoubayuHeal.SavedProfiles then
        return list
    end

    for profile, data in GoubayuHeal.SavedProfiles do
        if not (string.find(profile, "_D$") or string.find(profile, "_S$")
            or string.find(profile, "_T$")) then
            table.insert(list, { text = profile })
        end
    end

    if table.getn(list) == 0 then
        table.insert(list, { text = "None", color = { 0.6, 0.6, 0.6 } })
    end

    return list
end, function(text, buttonClicked)
    if buttonClicked == "RightButton" then
        if GoubayuHeal.SavedProfiles and GoubayuHeal.SavedProfiles[text] then
            GoubayuHeal.SavedProfiles[text] = nil
            GoubayuHeal.Print(string.format(GoubayuHeal.UI.DeletedProfileFmt, text))
            if GoubayuHeal.ProfileDropDownMenuInitialize then
                GoubayuHeal.ProfileDropDownMenuInitialize()
            end
        end
        return
    end

    if text and text ~= "None" then
        if GoubayuHeal.Load_Profile then
            GoubayuHeal.Load_Profile(text)
        end
        GoubayuHeal.Print(string.format(GoubayuHeal.UI.ProfileLoadedFmt, text))
    end
end)
GoubayuHeal_GUIProfileDropDownMenu:SetPoint("LEFT", profileLabel, "RIGHT", 6, 0)

local newProfileButton = GoubayuHeal_UI_CreateFlatButton(advPanel, "GoubayuHeal_GUINewProfileButton",
    100, 24, GoubayuHeal.UI.SaveConfig)
newProfileButton:SetPoint("LEFT", GoubayuHeal_GUIProfileDropDownMenu, "RIGHT", 10, 0)
newProfileButton:SetScript("OnClick", function()
    GoubayuHeal_GUIProfileTextBox:Show()
end)

-- 导入/导出按钮
local importExportLabel = GoubayuHeal_UI_MakeFontString(advPanel, "OVERLAY", 11, 0.72, 0.72, 0.72)
importExportLabel:SetPoint("TOPRIGHT", advPanel, "TOPRIGHT", -30, -40)
importExportLabel:SetText(GoubayuHeal.UI.ImportExportLabel)

local exportButton = GoubayuHeal_UI_CreateFlatButton(advPanel, "GoubayuHeal_GUIExportButton",
    100, 26, GoubayuHeal.UI.ExportTitle)
exportButton:SetPoint("TOPLEFT", importExportLabel, "BOTTOMLEFT", 0, -12)
exportButton:SetScript("OnClick", function()
    UI.ShowExportWindow()
end)
UI.SetTooltip(exportButton, GoubayuHeal.UI.ExportTitle, GoubayuHeal.UI.ExportTip)

local importButton = GoubayuHeal_UI_CreateFlatButton(advPanel, "GoubayuHeal_GUIImportButton",
    100, 26, GoubayuHeal.UI.ImportTitle)
importButton:SetPoint("TOPLEFT", exportButton, "BOTTOMLEFT", 0, -8)
importButton:SetScript("OnClick", function()
    UI.ShowImportWindow()
end)
UI.SetTooltip(importButton, GoubayuHeal.UI.ImportTitle, GoubayuHeal.UI.ImportTip)

-- 档案下拉刷新
function UI.RefreshProfileDropDown()
    if not GoubayuHeal_GUIProfileDropDownMenu then
        return
    end
    if GoubayuHeal.current_profile then
        GoubayuHeal_GUIProfileDropDownMenu:SetText(GoubayuHeal.current_profile)
    else
        GoubayuHeal_GUIProfileDropDownMenu:SetText("None", { 0.6, 0.6, 0.6 })
    end
end

function GoubayuHeal.ProfileDropDownMenuInitialize()
    if UI.RefreshProfileDropDown then
        UI.RefreshProfileDropDown()
    end
end

function GoubayuHeal.ProfileDropDownMenuUpdate(profile)
    GoubayuHeal.current_profile = profile
    if UI.RefreshProfileDropDown then
        UI.RefreshProfileDropDown()
    end
end

-- ============================================================
-- 图腾条
-- ============================================================

GoubayuHeal_TotemFrame = CreateFrame("Frame", "GoubayuHeal_TotemFrame", UIParent)
local totemFrame = GoubayuHeal_TotemFrame
    totemFrame:SetWidth(256)
totemFrame:SetHeight(54)
totemFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
totemFrame:SetFrameStrata("MEDIUM")
totemFrame:SetMovable(true)
totemFrame:EnableMouse(true)
totemFrame:EnableMouseWheel(true)
totemFrame:SetClampedToScreen(true)
totemFrame:Hide()
UI.ApplyFlatBackdrop(totemFrame, 0.1, 0.1, 0.1, 0.8)
totemFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

local totemElements = { "Fire", "Water", "Earth", "Air" }
local totemCounts = { Fire = 7, Water = 7, Earth = 7, Air = 9 }

-- 创建图腾按钮
for _, element in ipairs(totemElements) do
    local maxN = totemCounts[element]
    for n = 1, maxN do
        local el = element
        local nn = n
        local bname = "GoubayuHeal_TotemButton_" .. element .. n
        local b = CreateFrame("Button", bname, totemFrame)
        b:SetWidth(40)
        b:SetHeight(40)
        b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        b:SetScript("OnClick", function()
            if nn == 1 then
                if GoubayuHeal.Totem_OnClick then
                    GoubayuHeal.Totem_OnClick(el == "Fire" and 1 or (el == "Water" and 2
                        or (el == "Earth" and 3 or 4)), arg1)
                end
            else
                if GoubayuHeal.Totem_SelectSpell then
                    GoubayuHeal.Totem_SelectSpell(el, nn)
                end
            end
        end)

        b:SetScript("OnEnter", function()
            if nn == 1 then
                if GoubayuHeal.Totem_OnEnter then
                    GoubayuHeal.Totem_OnEnter(el == "Fire" and 1 or (el == "Water" and 2
                        or (el == "Earth" and 3 or 4)))
                end
            else
                if GoubayuHeal.Totem_AltButton_OnEnter then
                    GoubayuHeal.Totem_AltButton_OnEnter(el, nn)
                end
            end
        end)

        b:SetScript("OnLeave", function()
            if nn == 1 then
                if GoubayuHeal.Totem_OnLeave then
                    GoubayuHeal.Totem_OnLeave(el == "Fire" and 1 or (el == "Water" and 2
                        or (el == "Earth" and 3 or 4)))
                end
            else
                if GoubayuHeal.Totem_AltButton_OnLeave then
                    GoubayuHeal.Totem_AltButton_OnLeave()
                end
            end
        end)

        local texture = b:CreateTexture(bname .. "Texture", "BACKGROUND")
        texture:SetPoint("TOPLEFT", b, "TOPLEFT", -2, 0)
        texture:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 0)

        local dur = b:CreateFontString(bname .. "DurationText", "OVERLAY", "GameFontHighlight")
        dur:SetPoint("CENTER", b, "CENTER", -4, 0)

        local cd = b:CreateFontString(bname .. "CooldownText", "OVERLAY", "GameFontHighlight")
        cd:SetPoint("CENTER", b, "CENTER", -2, 0)

        -- 覆盖数字（元素主按钮上方，显示 已覆盖人数/小队人数）
        local cov = b:CreateFontString(bname .. "CoverageText", "OVERLAY", "GameFontHighlight")
        cov:SetPoint("TOP", b, "TOP", 0, 2)
        cov:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        cov:Hide()

        if n > 1 then
            b:Hide()
        end
    end
end

-- 放置与设置按钮
local function GoubayuHeal_CreateTotemSpecialButton(bname, isSettings)
    local b = CreateFrame("Button", bname, totemFrame)
    b:SetWidth(40)
    b:SetHeight(40)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local texture = b:CreateTexture(bname .. "Texture", "BACKGROUND")
    texture:SetPoint("TOPLEFT", b, "TOPLEFT", -2, 0)
    texture:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 0)

    local dur = b:CreateFontString(bname .. "DurationText", "OVERLAY", "GameFontHighlight")
    dur:SetPoint("CENTER", b, "CENTER", -4, 0)

    local cd = b:CreateFontString(bname .. "CooldownText", "OVERLAY", "GameFontHighlight")
    cd:SetPoint("CENTER", b, "CENTER", -2, 0)

    b:SetScript("OnClick", function()
        if GoubayuHeal.Totem_OnClick then
            GoubayuHeal.Totem_OnClick(isSettings and 6 or 5, arg1)
        end
    end)

    b:SetScript("OnEnter", function()
        if GoubayuHeal.Totem_OnEnter then
            GoubayuHeal.Totem_OnEnter(isSettings and 6 or 5)
        end
    end)

    b:SetScript("OnLeave", function()
        GameTooltip:Hide()
        if isSettings then
            if GoubayuHeal.Totem_SchedulePresetHide then
                GoubayuHeal.Totem_SchedulePresetHide()
            end
        elseif GoubayuHeal.Totem_OnLeave then
            GoubayuHeal.Totem_OnLeave(5)
        end
    end)

    return b
end

GoubayuHeal_CreateTotemSpecialButton("GoubayuHeal_TotemButton_Place", false)
GoubayuHeal_CreateTotemSpecialButton("GoubayuHeal_TotemButton_Settings", true)

totemFrame:SetScript("OnEvent", function()
    if GoubayuHeal.Totem_OnEvent then
        GoubayuHeal.Totem_OnEvent(event, arg1)
    end
end)

totemFrame:SetScript("OnShow", function()
    if GoubayuHeal.Totem_OnShow then
        GoubayuHeal.Totem_OnShow()
    end
end)

totemFrame:SetScript("OnMouseDown", function()
    -- 锁定图腾框架：勾选后不可拖动（精细图腾管理窗口里的开关）
    -- by 武藤纯子酱 2026.9.21
    if GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
        and GoubayuHeal.Config["shaman_totem"].locked then
        return
    end
    if arg1 == "LeftButton" then
        local x, y = GetCursorPosition()
        local left, top = this:GetLeft(), this:GetTop()
        if not left or not top then
            return
        end
        -- 一次性把锚点固定到 TOPLEFT（位置不变），后续 OnUpdate 只更新偏移，无需 ClearAllPoints
        this:ClearAllPoints()
        this:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
        -- GetCursorPosition 返回物理像素（原点左下、y 向上）；拖动位移须除以 UI 缩放（1.12 用 UIParent:GetScale()）
        this.isMoving = true
        this.dragStartX = x
        this.dragStartY = y
        this.dragLeft = left
        this.dragTop = top
        this.dragLastLeft = nil
        this.dragLastTop = nil
    end
end)

totemFrame:SetScript("OnUpdate", function()
    if not this.isMoving then
        return
    end
    -- 1.12 无 GetEffectiveScale（TBC+ 才有），与文件内其他拖动代码一致用 UIParent:GetScale()
    local scale = UIParent:GetScale()
    local x, y = GetCursorPosition()
    local newLeft = this.dragLeft + (x - this.dragStartX) / scale
    local newTop = this.dragTop + (y - this.dragStartY) / scale
    -- 位置实际变化时才 SetPoint：锚点已固定到 TOPLEFT，原地更新偏移，开销最小
    if this.dragLastLeft ~= newLeft or this.dragLastTop ~= newTop then
        this:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", newLeft, newTop)
        this.dragLastLeft = newLeft
        this.dragLastTop = newTop
    end
end)

totemFrame:SetScript("OnMouseUp", function()
    if this.isMoving then
        this.isMoving = false
        this.dragLastLeft = nil
        this.dragLastTop = nil
        if GoubayuHeal.Totem_SaveFramePosition then
            GoubayuHeal.Totem_SaveFramePosition()
        end
    end
end)

totemFrame:SetScript("OnHide", function()
    this.isMoving = false
    this.dragLastLeft = nil
    this.dragLastTop = nil
    -- 隐藏图腾条时收掉残留 tooltip（1.12 隐藏悬停中的窗口不触发 OnLeave）
    if GameTooltip then
        GameTooltip:Hide()
    end
    if GoubayuHeal_Tooltip then
        GoubayuHeal_Tooltip:Hide()
    end
end)

if GoubayuHeal.Totem_OnLoad then
    GoubayuHeal.Totem_OnLoad()
end

-- ============================================================
-- 初始化 / 刷新
-- ============================================================

function GoubayuHeal.ClassDropDownMenuInitialize()
    if not GoubayuHeal.Config then
        return
    end
    if not GoubayuHeal.Config["classes"] then
        GoubayuHeal.Config["classes"] = {}
    end

    local found = nil
    for class, data in GoubayuHeal.Config["classes"] do
        if not (string.find(class, "_D$") or string.find(class, "_S$")
            or string.find(class, "_T$") or string.find(class, "_Tank$")) then
            found = class
            break
        end
    end

    if not found then
        GoubayuHeal.Config["classes"]["standard"] = {}
        found = "standard"
    end

    if not GoubayuHeal.current_class or not GoubayuHeal.Config["classes"][GoubayuHeal.current_class] then
        GoubayuHeal.current_class = found
    end

    if GoubayuHeal.Config["per_scheme_enabled"] == 1 and GoubayuHeal.SchemeLoadSettings then
        GoubayuHeal.SchemeLoadSettings(GoubayuHeal.current_class)
    end

    UI.RefreshSchemeDropDown()
    if UI.RedrawFlow then
        UI.RedrawFlow()
    end
    if UI.RedrawLibrary then
        UI.RedrawLibrary()
    end
end

function GoubayuHeal.ClassDropDownMenuUpdate(class)
    if not GoubayuHeal.Config or not GoubayuHeal.Config["classes"] then
        return
    end
    if not GoubayuHeal.Config["classes"][class] then
        return
    end

    -- 方案切换：清除上一方案的流程选中残留（防止误删新方案条目）
    if UI.ResetFlowSelection then
        UI.ResetFlowSelection()
    end

    local prev = GoubayuHeal.current_class
    if GoubayuHeal.Config["per_scheme_enabled"] == 1 and prev and prev ~= class then
        if GoubayuHeal.SchemeSaveSettings then
            GoubayuHeal.SchemeSaveSettings(prev)
        end
        GoubayuHeal.current_class = class
        if GoubayuHeal.SchemeLoadSettings then
            GoubayuHeal.SchemeLoadSettings(class)
        end
        if UI.RefreshSettingsValues then
            UI.RefreshSettingsValues()
        end
    else
        GoubayuHeal.current_class = class
    end

    UI.RefreshSchemeDropDown()
    if UI.RedrawFlow then
        UI.RedrawFlow()
    end
    if UI.RedrawLibrary then
        UI.RedrawLibrary()
    end
end

local function GoubayuHeal_TextWidth(fs, text)
    if fs and fs.GetStringWidth then
        local w = fs:GetStringWidth()
        if w and w > 0 then
            return w
        end
    end
    local charCount = select(2, string.gsub(text or "", "[^\128-\191]", ""))
    return charCount * 10
end

local function GoubayuHeal_ReflowClassBar()
    local isShaman = (GoubayuHeal.my_class == GoubayuHeal.Shaman)
    local isPaladin = (GoubayuHeal.my_class == GoubayuHeal.Paladin)
    local isDruid = (GoubayuHeal.my_class == GoubayuHeal.Druid)
    local isPriest = (GoubayuHeal.my_class == GoubayuHeal.Priest)

    local all = {
        GoubayuHeal.GUIShamanTotem,
        GoubayuHeal.GUIShamanOneKeyTotem,
        GoubayuHeal.GUIKeepWaterShield,
        GoubayuHeal.GUIPaladinMeleeHeal,
        GoubayuHeal.GUIPaladinSeal,
        GoubayuHeal.GUIPaladinMeleeCS,
        GoubayuHeal.GUIPaladinConsec,
        GoubayuHeal.GUIPaladinHSInterrupt,
        GoubayuHeal.GUIDruidKeepTree,
        GoubayuHeal.GUIDruidT25Five,
        GoubayuHeal.GUIRegrowthOverwrite,
        GoubayuHeal.GUIPriestForceGreaterHeal,
        GoubayuHeal.GUIPriestAlternateSpells,
        GoubayuHeal.GUIPriestKeepInnerFire,
        GoubayuHeal.GUIPriestT8Two,
        GoubayuHeal.GUIAllowFirstRankIgnoreOverheal,
    }

    for _, cb in ipairs(all) do
        if cb then
            cb:Hide()
            if cb.label then
                cb.label:Hide()
            end
        end
    end

    if essenceSlider then
        essenceSlider:Hide()
    end
    if essenceLabel then
        essenceLabel:Hide()
    end
    if GoubayuHeal.dpSlider then
        GoubayuHeal.dpSlider:Hide()
    end
    if GoubayuHeal.dpLabel then
        GoubayuHeal.dpLabel:Hide()
    end
    if GoubayuHeal.dsSlider then
        GoubayuHeal.dsSlider:Hide()
    end
    if GoubayuHeal.dsLabel then
        GoubayuHeal.dsLabel:Hide()
    end
    if GoubayuHeal.dp2Slider then
        GoubayuHeal.dp2Slider:Hide()
    end
    if GoubayuHeal.dp2Label then
        GoubayuHeal.dp2Label:Hide()
    end
    if GoubayuHeal.cnbSlider then
        GoubayuHeal.cnbSlider:Hide()
    end
    if GoubayuHeal.cnbLabel then
        GoubayuHeal.cnbLabel:Hide()
    end
    if GoubayuHeal.meleeJudgmentSlider then
        GoubayuHeal.meleeJudgmentSlider:Hide()
    end
    if GoubayuHeal.meleeJudgmentLabel then
        GoubayuHeal.meleeJudgmentLabel:Hide()
    end
    if GoubayuHeal.meleeJudgmentHigh then
        GoubayuHeal.meleeJudgmentHigh:Hide()
    end
    if GoubayuHeal.t35Slider then
        GoubayuHeal.t35Slider:Hide()
    end
    if GoubayuHeal.t35Label then
        GoubayuHeal.t35Label:Hide()
    end
    if GoubayuHeal.t35High then
        GoubayuHeal.t35High:Hide()
    end

    local list = {}

    local function pushCb(cb, text)
        if cb then
            table.insert(list, { t = "cb", cb = cb, text = text })
        end
    end

    if isShaman then
        pushCb(GoubayuHeal.GUIShamanTotem, GoubayuHeal.UI.TotemWindow)
        pushCb(GoubayuHeal.GUIShamanOneKeyTotem, GoubayuHeal.UI.OneKeyTotem)
        pushCb(GoubayuHeal.GUIKeepWaterShield, GoubayuHeal.UI.KeepWaterShield)
        table.insert(list, { t = "chainno" })
    elseif isPaladin then
        pushCb(GoubayuHeal.GUIPaladinMeleeHeal, GoubayuHeal.UI.MeleeHeal)
        pushCb(GoubayuHeal.GUIPaladinSeal, GoubayuHeal.UI.MeleeSealToggle)
        pushCb(GoubayuHeal.GUIPaladinMeleeCS, GoubayuHeal.UI.MeleeCSToggle)
        pushCb(GoubayuHeal.GUIPaladinConsec, GoubayuHeal.UI.ConsecToggle)
        pushCb(GoubayuHeal.GUIPaladinHSInterrupt, GoubayuHeal.UI.HSInterruptToggle)
        table.insert(list, { t = "meleeJudgment" })
        table.insert(list, { t = "tier35" })
        table.insert(list, { t = "divineShield" })
        table.insert(list, { t = "divineProtection" })
    end

    if isDruid then
        table.insert(list, { t = "essence" })
        pushCb(GoubayuHeal.GUIDruidKeepTree, GoubayuHeal.UI.KeepTree)
        pushCb(GoubayuHeal.GUIDruidT25Five, GoubayuHeal.UI.T25Five)
        -- 允许覆盖愈合：仅德鲁伊（愈合是德鲁伊技能）
        -- by 武藤纯子酱 2026.9.27
        pushCb(GoubayuHeal.GUIRegrowthOverwrite, GoubayuHeal.UI.AllowRegrowthOverwrite)
    end

    if isPriest then
        pushCb(GoubayuHeal.GUIPriestForceGreaterHeal, GoubayuHeal.UI.ForceGreater)
        pushCb(GoubayuHeal.GUIPriestAlternateSpells, GoubayuHeal.UI.AlternateSpells)
        pushCb(GoubayuHeal.GUIPriestKeepInnerFire, GoubayuHeal.UI.KeepInnerFire)
        pushCb(GoubayuHeal.GUIPriestT8Two, GoubayuHeal.UI.T8Two)
        table.insert(list, { t = "desperate" })
    end

    pushCb(GoubayuHeal.GUIAllowFirstRankIgnoreOverheal, GoubayuHeal.UI.AllowFirstRank)

    -- 两排布局：第一排全部复选框，第二排全部滑块；每排内部超宽仍自动折行
    -- 复选框锚 TOPLEFT、滑块标签锚 LEFT（垂直居中），各自保持原生偏移不混用
    local maxW = 836

    -- 第一排：复选框
    local x = 24
    local yTop = -7
    local cbRows = 1
    for _, item in ipairs(list) do
        if item.t == "cb" then
            local cb = item.cb
            local itemW = 40 + 4 + GoubayuHeal_TextWidth(cb and cb.label, item.text) + 16
            if x + itemW > maxW and x > 24 then
                x = 24
                yTop = yTop - 28
                cbRows = cbRows + 1
            end
            cb:Show()
            cb:ClearAllPoints()
            cb:SetPoint("TOPLEFT", specialBar, "TOPLEFT", x, yTop)
            if cb.label then
                cb.label:Show()
            end
            x = x + itemW
        end
    end

    -- 第二排：滑块（基线在复选框排之下；yMid 上收 16px 防滑块刻度溢出背景框底边）
    local x2 = 24
    local yMid = -34 + 16
    local sliderRows = 1
    local hasSliderItems = false
    for _, item in ipairs(list) do
        if item.t ~= "cb" then
            hasSliderItems = true
            local lblText = (item.t == "essence" and GoubayuHeal.UI.EssenceLabel)
                or (item.t == "desperate" and GoubayuHeal.UI.DpLabel)
                or (item.t == "divineShield" and GoubayuHeal.UI.DsLabel)
                or (item.t == "divineProtection" and GoubayuHeal.UI.Dp2Label)
                or (item.t == "chainno" and GoubayuHeal.UI.CnbLabel)
                or (item.t == "meleeJudgment" and GoubayuHeal.UI.MeleeJudgmentLabel)
                or (item.t == "tier35" and GoubayuHeal.UI.T35Label)
            local lbl = (item.t == "essence" and essenceLabel)
                or (item.t == "desperate" and GoubayuHeal.dpLabel)
                or (item.t == "divineShield" and GoubayuHeal.dsLabel)
                or (item.t == "divineProtection" and GoubayuHeal.dp2Label)
                or (item.t == "chainno" and GoubayuHeal.cnbLabel)
                or (item.t == "meleeJudgment" and GoubayuHeal.meleeJudgmentLabel)
                or (item.t == "tier35" and GoubayuHeal.t35Label)
            local highW = (item.t == "meleeJudgment" or item.t == "tier35") and 45 or 30
            -- 组间距 8px（原 16px 过大，导致圣骑 4 个滑块换行）；
            -- 4 组合计约 802px + 起始 24px < 836px 可容于一行
            local itemW = GoubayuHeal_TextWidth(nil, lblText) + 6 + 105 + 4 + highW + 8

            if x2 + itemW > maxW and x2 > 24 then
                x2 = 24
                yMid = yMid - 28
                sliderRows = sliderRows + 1
            end

            if lbl then
                lbl:Show()
                lbl:ClearAllPoints()
                lbl:SetPoint("LEFT", specialBar, "LEFT", x2, yMid)
            end
            local slider = (item.t == "essence" and essenceSlider)
                or (item.t == "desperate" and GoubayuHeal.dpSlider)
                or (item.t == "divineShield" and GoubayuHeal.dsSlider)
                or (item.t == "divineProtection" and GoubayuHeal.dp2Slider)
                or (item.t == "chainno" and GoubayuHeal.cnbSlider)
                or (item.t == "meleeJudgment" and GoubayuHeal.meleeJudgmentSlider)
                or (item.t == "tier35" and GoubayuHeal.t35Slider)
            local high = (item.t == "essence" and essenceHigh)
                or (item.t == "desperate" and GoubayuHeal.dpHigh)
                or (item.t == "divineShield" and GoubayuHeal.dsHigh)
                or (item.t == "divineProtection" and GoubayuHeal.dp2High)
                or (item.t == "chainno" and GoubayuHeal.cnbHigh)
                or (item.t == "meleeJudgment" and GoubayuHeal.meleeJudgmentHigh)
                or (item.t == "tier35" and GoubayuHeal.t35High)
            if slider then
                slider:Show()
                slider:ClearAllPoints()
                slider:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
            end
            if high then
                high:ClearAllPoints()
                high:SetPoint("LEFT", slider, "RIGHT", 4, 0)
                high:Show()
            end
            -- 主动刷新回显文字：reflow 时 slider 可能已在显示状态（再 Show 不触发 OnShow），
            -- 回显会停留在旧值/空值；按滑块类型直接重读配置写入。
            -- userOnShow 内部用 `this` 引用滑块（OnShow 事件约定），直接调用前必须绑定 this，
            -- 否则 `this` 是上一个事件残留的全局值 → SetValue 报 nil
            if slider and slider.userOnShow then
                local savedThis = this
                this = slider
                slider.userOnShow()
                this = savedThis
            end
            x2 = x2 + itemW
        end
    end

    -- 高度自适应：基础=复选框1行(36px)；有滑块的职业滑块排固定再占一行(+30，滑块含
    -- 刻度标签实际纵向约30px)；任一排内部折行时每多一行再 +28。
    -- 之前滑块排侵入方案/法术库区域，正是因为公式漏算了滑块排自身高度
    local extraRows = (cbRows - 1) + (math.max(sliderRows - 1, hasSliderItems and 1 or 0))
    local newBarH = 36 + extraRows * 28 + (hasSliderItems and 2 or 0)
    if specialBar:GetHeight() ~= newBarH then
        specialBar:SetHeight(newBarH)
        classesPanel:SetHeight(500 + (newBarH - 34))
        mainWindow:SetHeight(600 + (newBarH - 34))
    end
end

function UI.UpdateClassVisibility()
    if not GoubayuHeal.my_class then
        return
    end
    GoubayuHeal_ReflowClassBar()
end

function UI.UpdateNampowerSettings()
    local hasNP = not not (GetNampowerVersion)
    local settings = GoubayuHeal.NampowerOnlySettings or {}

    for _, item in ipairs(settings) do
        if item.c then
            if hasNP then
                item.c:Show()
            else
                item.c:Hide()
            end
        end
        if item.l then
            if hasNP then
                item.l:Show()
            else
                item.l:Hide()
            end
        end
    end
end

function UI.RefreshAll()
    if UI.RefreshSchemeDropDown then
        UI.RefreshSchemeDropDown()
    end
    if UI.RefreshProfileDropDown then
        UI.RefreshProfileDropDown()
    end
    if UI.UpdateClassVisibility then
        UI.UpdateClassVisibility()
    end
    if UI.UpdateNampowerSettings then
        UI.UpdateNampowerSettings()
    end
    if UI.RedrawFlow then
        UI.RedrawFlow()
    end
    if UI.RedrawLibrary then
        UI.RedrawLibrary()
    end
    if GoubayuHeal.Dispel_RefreshAllEmbeddedLists then
        GoubayuHeal.Dispel_RefreshAllEmbeddedLists()
    end
    UI.RefreshSettingsValues()
end

function UI.RefreshSettingsValues()
    -- 只刷新当前可见的控件：窗口打开时 9 个页签仅 1 个可见，
    -- 隐藏页签的滑块/开关由页签切换/自身 OnShow 兜底刷新（见 SetSelectedTab）
    -- by 武藤纯子酱 2026.9.4
    if UI.AllSliders then
        for _, s in ipairs(UI.AllSliders) do
            if s:IsVisible() then
                this = s
                if s.userOnShow then
                    s.userOnShow()
                end
            end
        end
    end

    if UI.AllToggles then
        for _, t in ipairs(UI.AllToggles) do
            if t:IsVisible() then
                this = t
                if t.userOnShow then
                    t.userOnShow()
                end
            end
        end
    end

    this = nil
end

-- 初始化拖拽幽灵与插入线
GoubayuHeal_CreateDragGhost()
GoubayuHeal_CreateDropIndicator()

-- 登录后刷新
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function()
    UI.RefreshAll()
    loginFrame:UnregisterEvent("PLAYER_LOGIN")
end)

-- 主窗口显示初始化
mainWindow:SetScript("OnShow", function()
    if not GoubayuHeal.spellbook_checked then
        if GoubayuHeal.UpdateSpells then
            GoubayuHeal.UpdateSpells()
        end
        GoubayuHeal.spellbook_checked = true
    end

    if not GoubayuHeal.current_class and GoubayuHeal.Config and GoubayuHeal.Config["classes"] then
        for class, data in GoubayuHeal.Config["classes"] do
            if not (string.find(class, "_D$") or string.find(class, "_S$")
                or string.find(class, "_T$") or string.find(class, "_Tank$")) then
                GoubayuHeal.current_class = class
                break
            end
        end
    end

    UI.RefreshAll()
    GoubayuHeal_SetSelectedTab(selectedTab)
end)

-- ============================================================
-- 使用说明标签页
-- ============================================================

pcall(function()
    local helpPanel = CreateFrame("Frame", nil, mainWindow)
    helpPanel:SetWidth(856)
    helpPanel:SetHeight(460)
    helpPanel:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 10, -42)
    panels[9] = helpPanel

    local helpBackdrop = CreateFrame("Frame", nil, helpPanel)
    helpBackdrop:SetWidth(816)
    helpBackdrop:SetHeight(460)
    helpBackdrop:SetPoint("TOPLEFT", helpPanel, "TOPLEFT", 20, -14)
    UI.ApplyFlatBackdrop(helpBackdrop, 0.05, 0.05, 0.05, 0.9)

    local helpTitle = GoubayuHeal_UI_MakeFontString(helpBackdrop, "OVERLAY", 14, 1, 0.565, 0)
    helpTitle:SetPoint("TOPLEFT", helpBackdrop, "TOPLEFT", 14, -10)
    helpTitle:SetText(GoubayuHeal.UI.HelpTitle)

    -- 整个使用说明放进一个大编辑框（高度固定+滚动条；可手动选择复制；关闭再打开本页自动恢复原样）
    local helpLines = GoubayuHeal.GUI_help_lines or {}
    local helpText = table.concat(helpLines, "\n")

    local helpScroll = CreateFrame("ScrollFrame", nil, helpBackdrop)
    helpScroll:SetWidth(766)
    helpScroll:SetHeight(410)
    helpScroll:SetPoint("TOPLEFT", helpBackdrop, "TOPLEFT", 16, -40)
    helpScroll:EnableMouse(true)
    helpScroll:EnableMouseWheel(true)

    local helpEdit = CreateFrame("EditBox", "GoubayuHeal_GUIHelpEditBox", helpScroll)
    helpEdit:SetWidth(760)
    helpEdit:SetMultiLine(true)
    helpEdit:SetAutoFocus(false)
    helpEdit:SetFont(FONT, 11, "OUTLINE")
    helpEdit:SetTextColor(0.9, 0.9, 0.9)
    helpEdit:SetText(helpText)

    -- EditBox 高度 = 内容总高，由 ScrollFrame 滚动显示
    local lineH = 14
    local contentH = table.getn(helpLines) * lineH + 10
    helpEdit:SetHeight(contentH)
    helpScroll:SetScrollChild(helpEdit)

    -- 垂直滚动条：高度固定，内容用滚动条查看
    local helpSlider = CreateFrame("Slider", nil, helpBackdrop)
    helpSlider:SetOrientation("VERTICAL")
    helpSlider:SetWidth(12)
    helpSlider:SetHeight(410)
    helpSlider:SetPoint("TOPLEFT", helpScroll, "TOPRIGHT", 6, 0)
    helpSlider:SetValueStep(1)
    helpSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")

    local rail = helpSlider:CreateTexture(nil, "BACKGROUND")
    rail:SetTexture("Interface\\Buttons\\WHITE8X8")
    rail:SetWidth(4)
    rail:SetPoint("TOP", helpSlider, "TOP", 0, 0)
    rail:SetPoint("BOTTOM", helpSlider, "BOTTOM", 0, 0)
    rail:SetVertexColor(0.25, 0.25, 0.25, 0.8)

    local thumb = helpSlider:GetThumbTexture()
    if thumb then
        thumb:SetWidth(12)
        thumb:SetHeight(40)
        thumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
    end

    helpSlider:SetScript("OnValueChanged", function()
        if helpScroll then
            helpScroll:SetVerticalScroll(arg1)
        end
    end)

    helpScroll:SetScript("OnMouseWheel", function()
        local value = (helpScroll:GetVerticalScroll() or 0) - arg1 * 40
        local maxV = contentH - 424
        if value < 0 then
            value = 0
        end
        if value > maxV then
            value = maxV
        end
        helpScroll:SetVerticalScroll(value)
        helpSlider:SetValue(value)
    end)

    UI.UpdateScrollBar(helpScroll, helpSlider, contentH)

    -- 每次打开使用说明页时重置为原始内容（防止被改坏）
    helpPanel:SetScript("OnShow", function()
        helpEdit:SetText(helpText)
        helpScroll:SetVerticalScroll(0)
        helpSlider:SetValue(0)
    end)
end)