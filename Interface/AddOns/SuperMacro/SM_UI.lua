--[[
    SM_UI.lua - 超级宏界面（纯 Lua 实现，GoubayuHeal 扁平风格，无 XML 控件）
    用 CreateFrame 动态创建原先由 SuperMacro.xml / SuperMacroOptions.xml 声明的
    全部命名控件，保持控件名、层级、脚本行为与原 XML 一致，以便其余业务 Lua 无需改动。
    by 武藤纯子酱 2026.9.10
--]]

-- ============================================================
-- 样式常量与扁平化工具（参照 GoubayuHeal）
-- ============================================================
local FLAT_EDGE = { 0.35, 0.35, 0.35, 0.9 }
local FONT = "Fonts\\FRIZQT__.TTF"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local function ApplyFlatBackdrop(frame, r, g, b, a)
    frame:SetBackdrop({
        bgFile = WHITE,
        edgeFile = WHITE,
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(r, g, b, a)
    frame:SetBackdropBorderColor(FLAT_EDGE[1], FLAT_EDGE[2], FLAT_EDGE[3], FLAT_EDGE[4])
end

-- 扁平按钮着色/悬停效果（不改变原按钮的 OnClick 行为）
local function SkinFlatButton(btn)
    if ( not btn ) then return end
    ApplyFlatBackdrop(btn, 0.055, 0.055, 0.055, 0.98)
    -- 清除 UIPanelButtonTemplate 默认贴图，使扁平底色可见（带存在性守卫）
    if ( btn.GetNormalTexture ) then
        local t = btn:GetNormalTexture(); if ( t ) then t:SetTexture(nil) end
    end
    if ( btn.GetPushedTexture ) then
        local t = btn:GetPushedTexture(); if ( t ) then t:SetTexture(nil) end
    end
    if ( btn.GetDisabledTexture ) then
        local t = btn:GetDisabledTexture(); if ( t ) then t:SetTexture(nil) end
    end
    if ( btn.GetHighlightTexture ) then
        local t = btn:GetHighlightTexture(); if ( t ) then t:SetTexture(WHITE); t:SetAlpha(0.12) end
    end
    btn:SetScript("OnEnter", function()
        this:SetBackdropColor(0.32, 0.19, 0.02, 1)
    end)
    btn:SetScript("OnLeave", function()
        this:SetBackdropColor(0.055, 0.055, 0.055, 0.98)
    end)
end

-- 兼容 OnLoad：Lua 动态创建的框架不会触发 OnLoad，需手动以 this 上下文执行
local function RunOnLoad(frame, fn)
    local oldThis = this
    this = frame
    fn()
    this = oldThis
end

-- 清空一个框架自身的所有纹理区域（保留文字），用于去除原版贴图、改扁平风格
local function BlankTextures(frame)
    if ( not frame or not frame.GetRegions ) then return end
    local regions = { frame:GetRegions() }
    for k = 1, table.getn(regions) do
        local r = regions[k]
        if ( r and r.SetTexture ) then
            r:SetTexture(nil)
        end
    end
end

-- 扁平化关闭按钮（清空原贴图，加边框与一个 X 文字）
local function SkinCloseButton(btn)
    if ( not btn ) then return end
    BlankTextures(btn)
    ApplyFlatBackdrop(btn, 0.08, 0.08, 0.08, 1)
    local x = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    x:SetPoint("CENTER", btn, "CENTER", 0, 0)
    x:SetText("X")
    x:SetTextColor(0.85, 0.85, 0.85)
    btn:SetScript("OnEnter", function()
        this:SetBackdropColor(0.32, 0.19, 0.02, 1)
    end)
    btn:SetScript("OnLeave", function()
        this:SetBackdropColor(0.08, 0.08, 0.08, 1)
    end)
end

-- 扁平化标签页（清空 CharacterFrameTabButtonTemplate 的贴图，加扁平底与高亮）
local function SkinTab(tab)
    if ( not tab ) then return end
    BlankTextures(tab)
    ApplyFlatBackdrop(tab, 0.055, 0.055, 0.055, 0.98)
    tab:SetScript("OnEnter", function()
        if ( not ( this.GetChecked and this:GetChecked() ) ) then this:SetBackdropColor(0.18, 0.12, 0.03, 1) end
    end)
    tab:SetScript("OnLeave", function()
        if ( not ( this.GetChecked and this:GetChecked() ) ) then this:SetBackdropColor(0.055, 0.055, 0.055, 0.98) end
    end)
end

-- 扁平化滚动条（清空原贴图，滑块用纯色线条）
local function SkinScrollBar(scrollFrame)
    if ( not scrollFrame or not scrollFrame.GetName ) then return end
    local n = scrollFrame:GetName()
    if ( not n ) then return end
    local sb = getglobal(n .. "ScrollBar")
    if ( not sb ) then return end
    BlankTextures(sb)
    local thumb = getglobal(n .. "ScrollBarThumbTexture") or getglobal(n .. "ScrollBarThumb")
    if ( thumb ) then
        thumb:SetTexture(WHITE)
        thumb:SetVertexColor(0.5, 0.5, 0.5, 0.95)
        thumb:SetWidth(10)
    end
    BlankTextures(getglobal(n .. "ScrollBarScrollUpButton"))
    BlankTextures(getglobal(n .. "ScrollBarScrollDownButton"))
end

-- ============================================================
-- 宏按钮图标/名称/编号的公共构造（复刻 SuperMacroFrameButtonTemplate）
-- ============================================================
local function BuildMacroButton(name, parent, kind)
    local btn = CreateFrame("CheckButton", name, parent)
    btn:SetWidth(36)
    btn:SetHeight(36)
    -- 图标边框：改用纯线条勾勒（1px 描边），去除原版 UI-EmptySlot 边框贴图 by 武藤纯子酱 2026.9.10
    btn:SetBackdrop({ edgeFile = WHITE, edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    btn:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)
    -- 图标（NormalTexture），全局名 <name>Icon（缩到 34 以露出 1px 描边）
    local icon = btn:CreateTexture(name .. "Icon", "ARTWORK")
    icon:SetWidth(34)
    icon:SetHeight(34)
    icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
    -- 名称文字，全局名 <name>Name
    local fsName = btn:CreateFontString(name .. "Name", "OVERLAY", "GameFontHighlightSmallOutline")
    fsName:SetWidth(36)
    fsName:SetHeight(10)
    fsName:SetPoint("BOTTOM", btn, "BOTTOM", 0, 2)
    -- 高亮/选中（沿用原 XML 贴图，避免 GetXxxTexture 兼容问题）
    btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    btn:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight", "ADD")
    if ( kind ~= "popup" ) then
        -- 编号文字，全局名 <name>ID
        local fsID = btn:CreateFontString(name .. "ID", "OVERLAY", "GameFontNormalLarge")
        fsID:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        fsID:SetShadowOffset(2, -1)
        fsID:SetShadowColor(0, 0, 0)
    end
    return btn
end

-- GoubayuHeal 风格扁平开关（保留 CheckButton 的 SetChecked/GetChecked 语义）
local function MakeFlatToggle(cb)
    BlankTextures(cb)
    ApplyFlatBackdrop(cb, 0.12, 0.12, 0.12, 1)
    local knob = cb:CreateTexture(nil, "OVERLAY")
    knob:SetTexture(WHITE)
    knob:SetWidth(11)
    knob:SetHeight(11)
    local function Refresh()
        local checked = cb:GetChecked()
        knob:ClearAllPoints()
        if ( checked ) then
            knob:SetPoint("LEFT", cb, "LEFT", 25, 0)
            knob:SetVertexColor(1, 0.6, 0.15, 1)
            cb:SetBackdropColor(0.32, 0.19, 0.02, 1)
        else
            knob:SetPoint("LEFT", cb, "LEFT", 3, 0)
            knob:SetVertexColor(0.55, 0.55, 0.55, 1)
            cb:SetBackdropColor(0.12, 0.12, 0.12, 1)
        end
    end
    cb.RefreshToggle = Refresh
    -- 覆盖 SetChecked，使设置面板 OnShow 里的 SetChecked 也能同步视觉
    local origSetChecked = cb.SetChecked
    cb.SetChecked = function(self, v)
        origSetChecked(self, v)
        Refresh()
    end
    Refresh()
end

-- 给开关绑定点击逻辑，并在其后刷新视觉
local function SetToggleClick(cb, fn)
    cb:SetScript("OnClick", function()
        fn()
        if ( this.RefreshToggle ) then this.RefreshToggle() end
    end)
end

-- ============================================================
-- 构建主界面
-- ============================================================
local function SuperMacro_BuildMainUI()
    -- ---------- 主窗口 ----------
    local f = CreateFrame("Frame", "SuperMacroFrame", UIParent)
    f:SetWidth(590)
    f:SetHeight(512)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
    f:SetFrameStrata("HIGH")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetHitRectInsets(12, 40, 12, 71)
    f:Hide()

    -- 外框：内缩 Shell 承载扁平底与描边
    -- 按反馈收边：左 6px、右 10px、下 20px by 武藤纯子酱 2026.9.10
    local shell = CreateFrame("Frame", "SuperMacroFrameShell", f)
    shell:SetPoint("TOPLEFT", f, "TOPLEFT", 6, 0)
    shell:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 20)
    shell:SetFrameLevel(0)
    ApplyFlatBackdrop(shell, 0.05, 0.05, 0.05, 0.96)

    local title = f:CreateFontString("SuperMacroFrameTitle", "BORDER", "GameFontNormal")
    title:SetPoint("TOP", f, "TOP", 0, -17)
    title:SetText(SUPERMACRO_TITLE or "SuperMacro")

    -- 选中宏大图标底：改由按钮自身的线条描边承担，这里不再使用原版边框贴图
    local selBg = f:CreateTexture("SuperMacroFrameSelectedMacroBackground", "ARTWORK")
    selBg:SetTexture(nil)
    selBg:SetWidth(64)
    selBg:SetHeight(64)
    selBg:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -228)

    local selName = f:CreateFontString("SuperMacroFrameSelectedMacroName", "ARTWORK", "GameFontNormalLarge")
    selName:SetWidth(511)
    selName:SetHeight(16)
    selName:SetJustifyH("LEFT")
    selName:SetPoint("TOPLEFT", selBg, "TOPLEFT", 57, -5)

    local enterMacro = f:CreateFontString("SuperMacroFrameEnterMacroText", "ARTWORK", "GameFontHighlightSmall")
    enterMacro:SetText(ENTER_MACRO_LABEL or "")
    enterMacro:SetPoint("TOPLEFT", selBg, "BOTTOMLEFT", 55, 20)

    -- 主背景（仅作为配置尺寸的参考框架，不再绘制，外框由 SuperMacroFrameShell 承担）
    local bg = CreateFrame("Frame", "SuperMacroFrameMainBackground", f)
    bg:SetWidth(555)
    bg:SetHeight(437)
    bg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -32, 72)
    bg:SetFrameLevel(0)

    -- ---------- 常规宏面板 ----------
    local reg = CreateFrame("Frame", "SuperMacroFrameRegularFrame", f)
    reg:SetAllPoints(f)

    local generalText = reg:CreateFontString("SuperMacroFrameGeneralMacroText", "OVERLAY", "GameFontNormal")
    generalText:SetWidth(256)
    generalText:SetHeight(16)
    generalText:SetJustifyH("CENTER")
    generalText:SetPoint("CENTER", f, "TOPLEFT", 162, -66)
    generalText:SetText(GENERAL_MACROS or "")

    local charText = reg:CreateFontString("SuperMacroFrameCharacterMacroText", "OVERLAY", "GameFontNormal")
    charText:SetWidth(256)
    charText:SetHeight(16)
    charText:SetJustifyH("CENTER")
    charText:SetPoint("CENTER", f, "TOPLEFT", 420, -66)
    charText:SetText(CHARACTER_SPECIFIC_MACROS or "")

    local charLimit = reg:CreateFontString("SuperMacroFrameCharLimitText", "OVERLAY", "GameFontHighlightSmall")
    charLimit:SetPoint("BOTTOMLEFT", reg, "BOTTOMLEFT", 25, 100)

    -- 选中宏大图标
    local selBtn = BuildMacroButton("SuperMacroFrameSelectedMacroButton", reg)
    selBtn:SetID(0)
    selBtn:SetPoint("TOPLEFT", selBg, "TOPLEFT", 14, -14)
    selBtn:RegisterForDrag("LeftButton")
    selBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown")
    selBtn:SetScript("OnClick", function()
        this:SetChecked(nil)
        local id = SuperMacroFrame.selectedMacro
        if ( arg1 == "RightButton" ) then
            RunMacro(id)
        elseif ( id ) then
            PickupMacro(id)
        end
    end)

    -- 36 个常规宏按钮（复刻原网格锚点）
    local b
    b = BuildMacroButton("SuperMacroButton1", reg); b:SetID(1); b:SetPoint("TOPLEFT", reg, "TOPLEFT", 25, -83)
    b = BuildMacroButton("SuperMacroButton2", reg); b:SetID(2); b:SetPoint("LEFT", getglobal("SuperMacroButton1"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton3", reg); b:SetID(3); b:SetPoint("LEFT", getglobal("SuperMacroButton2"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton4", reg); b:SetID(4); b:SetPoint("LEFT", getglobal("SuperMacroButton3"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton5", reg); b:SetID(5); b:SetPoint("LEFT", getglobal("SuperMacroButton4"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton6", reg); b:SetID(6); b:SetPoint("LEFT", getglobal("SuperMacroButton5"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton7", reg); b:SetID(7); b:SetPoint("TOP", getglobal("SuperMacroButton1"), "BOTTOM", 0, -10)
    b = BuildMacroButton("SuperMacroButton8", reg); b:SetID(8); b:SetPoint("LEFT", getglobal("SuperMacroButton7"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton9", reg); b:SetID(9); b:SetPoint("LEFT", getglobal("SuperMacroButton8"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton10", reg); b:SetID(10); b:SetPoint("LEFT", getglobal("SuperMacroButton9"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton11", reg); b:SetID(11); b:SetPoint("LEFT", getglobal("SuperMacroButton10"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton12", reg); b:SetID(12); b:SetPoint("LEFT", getglobal("SuperMacroButton11"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton13", reg); b:SetID(13); b:SetPoint("TOP", getglobal("SuperMacroButton7"), "BOTTOM", 0, -10)
    b = BuildMacroButton("SuperMacroButton14", reg); b:SetID(14); b:SetPoint("LEFT", getglobal("SuperMacroButton13"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton15", reg); b:SetID(15); b:SetPoint("LEFT", getglobal("SuperMacroButton14"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton16", reg); b:SetID(16); b:SetPoint("LEFT", getglobal("SuperMacroButton15"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton17", reg); b:SetID(17); b:SetPoint("LEFT", getglobal("SuperMacroButton16"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton18", reg); b:SetID(18); b:SetPoint("LEFT", getglobal("SuperMacroButton17"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton19", reg); b:SetID(19); b:SetPoint("LEFT", getglobal("SuperMacroButton6"), "RIGHT", 35, 0)
    b = BuildMacroButton("SuperMacroButton20", reg); b:SetID(20); b:SetPoint("LEFT", getglobal("SuperMacroButton19"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton21", reg); b:SetID(21); b:SetPoint("LEFT", getglobal("SuperMacroButton20"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton22", reg); b:SetID(22); b:SetPoint("LEFT", getglobal("SuperMacroButton21"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton23", reg); b:SetID(23); b:SetPoint("LEFT", getglobal("SuperMacroButton22"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton24", reg); b:SetID(24); b:SetPoint("LEFT", getglobal("SuperMacroButton23"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton25", reg); b:SetID(25); b:SetPoint("TOP", getglobal("SuperMacroButton19"), "BOTTOM", 0, -10)
    b = BuildMacroButton("SuperMacroButton26", reg); b:SetID(26); b:SetPoint("LEFT", getglobal("SuperMacroButton25"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton27", reg); b:SetID(27); b:SetPoint("LEFT", getglobal("SuperMacroButton26"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton28", reg); b:SetID(28); b:SetPoint("LEFT", getglobal("SuperMacroButton27"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton29", reg); b:SetID(29); b:SetPoint("LEFT", getglobal("SuperMacroButton28"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton30", reg); b:SetID(30); b:SetPoint("LEFT", getglobal("SuperMacroButton29"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton31", reg); b:SetID(31); b:SetPoint("TOP", getglobal("SuperMacroButton25"), "BOTTOM", 0, -10)
    b = BuildMacroButton("SuperMacroButton32", reg); b:SetID(32); b:SetPoint("LEFT", getglobal("SuperMacroButton31"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton33", reg); b:SetID(33); b:SetPoint("LEFT", getglobal("SuperMacroButton32"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton34", reg); b:SetID(34); b:SetPoint("LEFT", getglobal("SuperMacroButton33"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton35", reg); b:SetID(35); b:SetPoint("LEFT", getglobal("SuperMacroButton34"), "RIGHT", 5, 0)
    b = BuildMacroButton("SuperMacroButton36", reg); b:SetID(36); b:SetPoint("LEFT", getglobal("SuperMacroButton35"), "RIGHT", 5, 0)

    -- 常规宏按钮统一脚本
    for i = 1, 36 do
        local btn = getglobal("SuperMacroButton" .. i)
        btn:RegisterForDrag("LeftButton")
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown")
        btn:SetScript("OnClick", function() SuperMacroButton_OnClick(arg1) end)
        btn:SetScript("OnDragStart", function() PickupMacro(this:GetID()) end)
    end

    -- 常规宏编辑框
    local scroll = CreateFrame("ScrollFrame", "SuperMacroFrameScrollFrame", reg, "UIPanelScrollFrameTemplate")
    scroll:SetWidth(248)
    scroll:SetHeight(100)
    scroll:SetPoint("TOPLEFT", selBg, "BOTTOMLEFT", 9, 0)
    local edit = CreateFrame("EditBox", "SuperMacroFrameText", scroll)
    edit:SetWidth(246)
    edit:SetHeight(100)
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(511)
    edit:SetScript("OnTextChanged", function()
        SuperMacroFrame.textChanged = 1
        if ( SuperMacroPopupFrame.mode == "newaccount" or SuperMacroPopupFrame.mode == "newcharacter" ) then
            SuperMacroPopupFrame:Hide()
        end
        SuperMacroFrameCharLimitText:SetText(format(TEXT(SUPERMACROFRAME_REGULAR_CHAR_LIMIT), SM_utf8len(SuperMacroFrameText:GetText()), SuperMacro_GetRegularMacroMaxLetters()))
        SuperMacroHandleEditBox(this)
    end)
    edit:SetScript("OnEscapePressed", function()
        SuperMacroFrame_SaveMacro()
        this:ClearFocus()
    end)
    scroll:SetScrollChild(edit)
    SkinScrollBar(scroll)

    local editBg = CreateFrame("Frame", "SuperMacroFrameTextBackground", reg)
    editBg:SetWidth(285)
    editBg:SetHeight(112)
    editBg:SetPoint("TOPLEFT", scroll, "TOPLEFT", -6, 6)
    ApplyFlatBackdrop(editBg, 0.02, 0.02, 0.02, 0.9)
    editBg:SetFrameLevel(0)

    -- 新建按钮
    local newAcc = CreateFrame("Button", "SuperMacroNewAccountButton", reg, "UIPanelButtonTemplate")
    newAcc:SetWidth(160); newAcc:SetHeight(22)
    newAcc:SetPoint("TOPLEFT", f, "TOPLEFT", 82, -37)
    newAcc:SetText(SUPERMACRO_NEW_ACCOUNT or "")
    newAcc:SetScript("OnClick", function() SuperMacroNewAccountButton_OnClick() end)
    SkinFlatButton(newAcc)

    local newChar = CreateFrame("Button", "SuperMacroNewCharacterButton", reg, "UIPanelButtonTemplate")
    newChar:SetWidth(160); newChar:SetHeight(22)
    newChar:SetPoint("TOPLEFT", f, "TOPLEFT", 342, -37)
    newChar:SetText(SUPERMACRO_NEW_CHARACTER or "")
    newChar:SetScript("OnClick", function() SuperMacroNewCharacterButton_OnClick() end)
    SkinFlatButton(newChar)

    -- ---------- 超级宏面板 ----------
    local sup = CreateFrame("Frame", "SuperMacroFrameSuperFrame", f)
    sup:SetAllPoints(f)

    local supLimit = sup:CreateFontString("SuperMacroFrameSuperCharLimitText", "ARTWORK", "GameFontHighlightSmall")
    supLimit:SetPoint("BOTTOMLEFT", sup, "BOTTOMLEFT", 25, 100)

    local selSup = BuildMacroButton("SuperMacroFrameSelectedMacroSuperButton", sup, "super")
    selSup:SetID(0)
    selSup:SetPoint("TOPLEFT", selBg, "TOPLEFT", 14, -14)
    selSup:RegisterForDrag("LeftButton")
    selSup:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown")
    selSup:SetScript("OnClick", function()
        this:SetChecked(nil)
        local id = SuperMacroFrame.selectedSuper
        if ( arg1 == "RightButton" ) then
            RunSuperMacro(id)
        elseif ( id ) then
            local supername = GetOrderedSuperMacroInfo(id)
            PickupMacro(1, supername)
        end
    end)
    selSup:SetScript("OnDragStart", function()
        local supername = GetOrderedSuperMacroInfo(SuperMacroFrame.selectedSuper)
        if ( supername ) then PickupMacro(1, supername) end
    end)

    -- 60 个超级宏按钮（3 行 × 20 列）
    local firstOfRow = {}
    for i = 1, 60 do
        local btn = BuildMacroButton("SuperMacroSuperButton" .. i, sup, "super")
        btn:SetID(i)
        local row = math.floor((i - 1) / 20) + 1
        local col = math.mod(i - 1, 20) + 1
        if ( col == 1 ) then
            firstOfRow[row] = btn
            if ( row == 1 ) then
                btn:SetPoint("TOPLEFT", sup, "TOPLEFT", 47, -83)
            else
                btn:SetPoint("TOP", firstOfRow[row - 1], "BOTTOM", 0, -10)
            end
        else
            btn:SetPoint("LEFT", getglobal("SuperMacroSuperButton" .. (i - 1)), "RIGHT", 13, 0)
        end
        btn:RegisterForDrag("LeftButton")
        btn:RegisterForClicks("LeftButtonUp", "RightButtonUp", "LeftButtonDown")
        btn:SetScript("OnClick", function() SuperMacroSuperButton_OnClick(arg1) end)
        btn:SetScript("OnDragStart", function()
            local supername = GetOrderedSuperMacroInfo(this:GetID())
            PickupMacro(1, supername)
        end)
    end

    -- 超级宏列表滚动框（Faux）
    local superScroll = CreateFrame("ScrollFrame", "SuperMacroFrameSuperScrollFrame", sup, "FauxScrollFrameTemplate")
    superScroll:SetWidth(1000)
    superScroll:SetHeight(150)
    superScroll:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -74)
    superScroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(MACRO_ROW_HEIGHT, SuperMacroFrame_Update) end)
    superScroll:SetScript("OnMouseWheel", function() ScrollFrameTemplate_OnMouseWheel(arg1) end)
    SkinScrollBar(superScroll)

    -- 超级宏编辑框
    local supScroll = CreateFrame("ScrollFrame", "SuperMacroFrameSuperEditScrollFrame", sup, "UIPanelScrollFrameTemplate")
    supScroll:SetWidth(494)
    supScroll:SetHeight(100)
    supScroll:SetPoint("TOPLEFT", selBg, "BOTTOMLEFT", 9, 0)
    local supEdit = CreateFrame("EditBox", "SuperMacroFrameSuperText", supScroll)
    supEdit:SetWidth(493)
    supEdit:SetHeight(100)
    supEdit:SetMultiLine(true)
    supEdit:SetAutoFocus(false)
    supEdit:SetMaxLetters(50000)
    supEdit:SetScript("OnTextChanged", function()
        SuperMacroFrame.textChanged = 1
        if ( SuperMacroPopupFrame.mode == "newaccount" or SuperMacroPopupFrame.mode == "newcharacter" ) then
            SuperMacroPopupFrame:Hide()
        end
        SuperMacroFrameSuperCharLimitText:SetText(format(TEXT(SUPERMACROFRAME_SUPER_CHAR_LIMIT), SM_utf8len(SuperMacroFrameSuperText:GetText())))
        SuperMacroHandleEditBox(this)
        SuperMacroFrame_SaveSuperMacro()
    end)
    supEdit:SetScript("OnEscapePressed", function()
        SuperMacroFrame_SaveSuperMacro()
        this:ClearFocus()
    end)
    supScroll:SetScrollChild(supEdit)
    SkinScrollBar(supScroll)

    local supEditBg = CreateFrame("Frame", "SuperMacroFrameSuperTextBackground", sup)
    supEditBg:SetWidth(530)
    supEditBg:SetHeight(112)
    supEditBg:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -285)
    supEditBg:SetFrameLevel(0)
    ApplyFlatBackdrop(supEditBg, 0.02, 0.02, 0.02, 0.9)

    sup:Hide()

    -- ---------- Extend（Lua 代码）编辑器（主窗口共享） ----------
    local extScroll = CreateFrame("ScrollFrame", "SuperMacroFrameExtendScrollFrame", f, "UIPanelScrollFrameTemplate")
    extScroll:SetWidth(209)
    extScroll:SetHeight(138)
    extScroll:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 40, 0)
    local extEdit = CreateFrame("EditBox", "SuperMacroFrameExtendText", extScroll)
    extEdit:SetWidth(205)
    extEdit:SetHeight(138)
    extEdit:SetMultiLine(true)
    extEdit:SetAutoFocus(false)
    extEdit:SetScript("OnTextChanged", function() SuperMacroFrameExtendText_OnTextChanged() end)
    extEdit:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    extScroll:SetScrollChild(extEdit)
    SkinScrollBar(extScroll)

    local extBg = CreateFrame("Frame", "SuperMacroFrameExtendTextBackground", f)
    extBg:SetWidth(245)
    extBg:SetHeight(150)
    extBg:SetPoint("BOTTOMRIGHT", extScroll, "BOTTOMRIGHT", 27, -6)
    extBg:SetFrameLevel(0)
    ApplyFlatBackdrop(extBg, 0.02, 0.02, 0.02, 0.9)
    local enterExt = extBg:CreateFontString("SuperMacroFrameEnterExtendText", "ARTWORK", "GameFontHighlightSmall")
    enterExt:SetText(ENTER_EXTEND_LABEL or "")
    enterExt:SetPoint("TOPLEFT", extBg, "TOPLEFT", 8, 13)
    local extLimit = extBg:CreateFontString("SuperMacroFrameExtendCharLimitText", "ARTWORK", "GameFontHighlightSmall")
    extLimit:SetPoint("BOTTOMLEFT", extBg, "BOTTOMLEFT", 8, -15)

    -- ---------- 功能按钮 ----------
    local function MakeButton(name, w, h, text, anchorFrame, point, relPoint, x, y, onClick)
        local btn = CreateFrame("Button", name, f, "UIPanelButtonTemplate")
        btn:SetWidth(w); btn:SetHeight(h)
        if ( relPoint ) then
            btn:SetPoint(point, anchorFrame, relPoint, x, y)
        else
            btn:SetPoint(point, anchorFrame, x, y)
        end
        if ( text ) then btn:SetText(text) end
        if ( onClick ) then btn:SetScript("OnClick", onClick) end
        SkinFlatButton(btn)
        return btn
    end

    MakeButton("SuperMacroEditButton", 170, 22, CHANGE_MACRO_NAME_ICON, selBg, "TOPLEFT", "TOPLEFT", 51, -21,
        function() SuperMacroEditButton_OnClick() end)
    MakeButton("SuperMacroOptionsButton", 100, 22, SUPERMACRO_OPTIONS, f, "BOTTOMLEFT", "BOTTOMLEFT", 15, 74,
        function() SuperMacroOptionsButton_OnClick() end)
    MakeButton("SuperMacroDeleteButton", 80, 22, DELETE, f, "BOTTOMLEFT", "BOTTOMLEFT", 115, 74,
        function() SuperMacroDeleteButton_OnClick() end)
    MakeButton("SuperMacroSaveButton", 80, 22, SAVE_MACRO, f, "BOTTOMLEFT", "BOTTOMLEFT", 195, 74,
        function() SuperMacroFrame_SaveMacro() end)
    MakeButton("SuperMacroDeleteSuperButton", 100, 22, DELETE_SUPERMACRO, f, "BOTTOMLEFT", "BOTTOMLEFT", 115, 74,
        function() SuperMacroDeleteSuperButton_OnClick() end)
    MakeButton("SuperMacroSaveSuperButton", 100, 22, SAVE_SUPERMACRO, f, "BOTTOMLEFT", "BOTTOMLEFT", 215, 74,
        function() SuperMacroFrame_SaveSuperMacro() end)
    MakeButton("SuperMacroNewSuperButton", 100, 22, NEW_SUPERMACRO, f, "BOTTOMLEFT", "BOTTOMLEFT", 315, 74,
        function() SuperMacroNewSuperButton_OnClick() end)
    local exitSuper = MakeButton("SuperMacroExitSuperButton", 80, 22, EXIT, f, "BOTTOMRIGHT", "BOTTOMRIGHT", -36, 74,
        function() HideUIPanel(SuperMacroFrame) end)
    exitSuper:Hide()
    local exitBtn = MakeButton("SuperMacroExitButton", 80, 22, EXIT, f, "BOTTOMRIGHT", "BOTTOMRIGHT", -36, 74,
        function() HideUIPanel(SuperMacroFrame) end)
    MakeButton("SuperMacroSaveExtendButton", 100, 22, SAVE_EXTEND, exitBtn, "BOTTOMRIGHT", "BOTTOMLEFT", 0, 0,
        function() SuperMacroSaveExtendButton_OnClick() end)
    MakeButton("SuperMacroDeleteExtendButton", 100, 22, DELETE_EXTEND, getglobal("SuperMacroSaveExtendButton"), "BOTTOMRIGHT", "BOTTOMLEFT", 0, 0,
        function() SuperMacroDeleteExtendButton_OnClick() end)
    MakeButton("SuperMacroToggleExtendButton", 120, 22, HIDE_EXTEND, getglobal("SuperMacroDeleteExtendButton"), "BOTTOMRIGHT", "BOTTOMLEFT", 0, 0,
        function() SuperMacroToggleExtend() end)

    local close = CreateFrame("Button", "SuperMacroFrameCloseButton", f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -29, -8)
    SkinCloseButton(close)

    -- 标签页
    local tab1 = CreateFrame("Button", "SuperMacroFrameTab1", f, "CharacterFrameTabButtonTemplate")
    tab1:SetID(1)
    tab1:SetText(REGULAR or "")
    tab1:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 11, 30)
    tab1:SetScript("OnClick", function()
        SuperMacroFrame_SaveCurrentText()
        PanelTemplates_Tab_OnClick(SuperMacroFrame)
        PanelTemplates_SetTab(SuperMacroFrame, 1)
        SM_VARS.tabShown = "regular"
        SuperMacroFrame_Update()
        SuperMacroUpdateExtendSelection()
    end)
    local tab2 = CreateFrame("Button", "SuperMacroFrameTab2", f, "CharacterFrameTabButtonTemplate")
    tab2:SetID(2)
    tab2:SetText(SUPER or "")
    tab2:SetPoint("LEFT", tab1, "RIGHT", 2, 0)
    tab2:SetScript("OnClick", function()
        SuperMacroFrame_SaveCurrentText()
        PanelTemplates_Tab_OnClick(SuperMacroFrame)
        PanelTemplates_SetTab(SuperMacroFrame, 2)
        SM_VARS.tabShown = "super"
        SuperMacroFrame_Update()
        SuperMacroUpdateExtendSelection()
    end)
    SkinTab(tab1)
    SkinTab(tab2)

    -- 主窗口脚本
    f:SetScript("OnShow", function() SuperMacroFrame_OnShow() end)
    f:SetScript("OnHide", function() SuperMacroFrame_OnHide() end)
    f:SetScript("OnEvent", function() SuperMacroFrame_OnEvent(event) end)
    f:SetScript("OnMouseWheel", function() return end)
    RunOnLoad(f, SuperMacroFrame_OnLoad)

    -- ---------- 弹窗（新建/编辑） ----------
    local pop = CreateFrame("Frame", "SuperMacroPopupFrame", UIParent)
    pop:SetWidth(297)
    pop:SetHeight(378)
    pop:SetPoint("TOPLEFT", f, "TOPRIGHT", -40, -40)
    pop:SetFrameStrata("TOOLTIP")
    pop:SetToplevel(true)
    pop:SetMovable(true)
    pop:EnableMouse(true)
    pop:Hide()
    ApplyFlatBackdrop(pop, 0.05, 0.05, 0.05, 0.98)

    local popText = pop:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
    popText:SetText(MACRO_POPUP_TEXT or "")
    popText:SetPoint("TOPLEFT", pop, "TOPLEFT", 24, -21)
    local popIconText = pop:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
    popIconText:SetText(MACRO_POPUP_CHOOSE_ICON or "")
    popIconText:SetPoint("TOPLEFT", pop, "TOPLEFT", 24, -69)

    local popEdit = CreateFrame("EditBox", "SuperMacroPopupEditBox", pop)
    popEdit:SetWidth(200)
    popEdit:SetHeight(20)
    popEdit:SetPoint("TOPLEFT", pop, "TOPLEFT", 29, -35)
    popEdit:SetMaxLetters(16)
    popEdit:SetAutoFocus(false)
    ApplyFlatBackdrop(popEdit, 0.02, 0.02, 0.02, 1)
    popEdit:SetFontObject(ChatFontNormal)
    popEdit:SetScript("OnTextChanged", function()
        SuperMacroPopupOkayButton_Update()
        SuperMacroFrameSelectedMacroName:SetText(this:GetText())
    end)
    popEdit:SetScript("OnEscapePressed", function() SuperMacroPopupFrame:Hide() end)
    popEdit:SetScript("OnEnterPressed", function()
        if ( SuperMacroPopupOkayButton:IsEnabled() ~= 0 ) then
            SuperMacroPopupOkayButton_OnClick()
        end
    end)

    local popScroll = CreateFrame("ScrollFrame", "SuperMacroPopupScrollFrame", pop, "FauxScrollFrameTemplate")
    popScroll:SetWidth(266)
    popScroll:SetHeight(275)
    popScroll:SetPoint("TOPRIGHT", pop, "TOPRIGHT", -39, -67)
    popScroll:SetScript("OnVerticalScroll", function() FauxScrollFrame_OnVerticalScroll(MACRO_ICON_ROW_HEIGHT, SuperMacroPopupFrame_Update) end)
    SkinScrollBar(popScroll)

    for i = 1, 30 do
        local btn = BuildMacroButton("SuperMacroPopupButton" .. i, pop, "popup")
        btn:SetID(i)
        local col = math.mod(i - 1, 5) + 1
        local row = math.floor((i - 1) / 5) + 1
        if ( col == 1 ) then
            if ( row == 1 ) then
                btn:SetPoint("TOPLEFT", pop, "TOPLEFT", 24, -85)
            else
                btn:SetPoint("TOPLEFT", getglobal("SuperMacroPopupButton" .. (i - 5)), "BOTTOMLEFT", 0, -8)
            end
        else
            btn:SetPoint("LEFT", getglobal("SuperMacroPopupButton" .. (i - 1)), "RIGHT", 10, 0)
        end
        btn:SetScript("OnClick", function() SuperMacroPopupButton_OnClick() end)
    end

    local popCancel = CreateFrame("Button", "SuperMacroPopupCancelButton", pop, "UIPanelButtonTemplate")
    popCancel:SetWidth(78); popCancel:SetHeight(22)
    popCancel:SetPoint("BOTTOMRIGHT", pop, "BOTTOMRIGHT", -11, -1)
    popCancel:SetText(CANCEL or "")
    popCancel:SetScript("OnClick", function()
        this:GetParent():Hide()
        SuperMacroFrame_Update()
        PlaySound("gsTitleOptionOK")
    end)
    SkinFlatButton(popCancel)

    local popOkay = CreateFrame("Button", "SuperMacroPopupOkayButton", pop, "UIPanelButtonTemplate")
    popOkay:SetWidth(78); popOkay:SetHeight(22)
    popOkay:SetPoint("RIGHT", popCancel, "LEFT", -2, 0)
    popOkay:SetText(OKAY or "")
    popOkay:SetScript("OnClick", function()
        SuperMacroPopupOkayButton_OnClick()
        PlaySound("gsTitleOptionOK")
    end)
    SkinFlatButton(popOkay)

    pop:SetScript("OnShow", function() SuperMacroPopupFrame_OnShow() end)
    pop:SetScript("OnHide", function() SuperMacroPopupFrame_OnHide() end)
    pop:SetScript("OnDragStart", function() this:StartMoving() end)
    pop:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    pop:RegisterForDrag("LeftButton")

    -- ---------- 游戏主菜单按钮 ----------
    local menuBtn = CreateFrame("Button", "GameMenuButtonSuperMacro", GameMenuFrame, "GameMenuButtonTemplate")
    menuBtn:SetWidth(20)
    menuBtn:SetHeight(115)
    menuBtn:SetPoint("TOPLEFT", GameMenuButtonOptions, "TOPRIGHT", -4, -40)
    menuBtn:SetText(SUPERMACRO_BUTTON or "")
    menuBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOption")
        HideUIPanel(GameMenuFrame)
        ShowUIPanel(SuperMacroFrame)
    end)

    -- ---------- 小地图按钮 ----------
    local mini = CreateFrame("Button", "SuperMacroMinimapButton", Minimap)
    mini:SetWidth(33)
    mini:SetHeight(33)
    mini:SetPoint("BOTTOM", Minimap, "BOTTOM", 0, -30)
    mini:SetMovable(true)
    mini:SetToplevel(true)
    mini:EnableMouse(true)
    mini:Hide()
    local miniIcon = mini:CreateTexture("SuperMacroMinimapButtonIcon", "BACKGROUND")
    miniIcon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
    miniIcon:SetWidth(18)
    miniIcon:SetHeight(18)
    miniIcon:SetPoint("TOPLEFT", mini, "TOPLEFT", 7, -6)
    local miniBorder = mini:CreateTexture("SuperMacroMinimapButtonBorder", "OVERLAY")
    miniBorder:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder.tga")
    miniBorder:SetWidth(52)
    miniBorder:SetHeight(52)
    miniBorder:SetPoint("TOPLEFT", mini, "TOPLEFT", 0, 0)
    mini:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    mini:RegisterForDrag("LeftButton")
    mini:SetScript("OnLoad", nil)
    mini:SetScript("OnClick", function()
        if ( SuperMacroFrame:IsVisible() ) then HideUIPanel(SuperMacroFrame) else ShowUIPanel(SuperMacroFrame) end
    end)
    mini:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
        GameTooltip:SetText(SUPERMACRO_MINIMAP or "")
    end)
    mini:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mini:SetScript("OnDragStart", function() this:StartMoving(); this.isMoving = true end)
    mini:SetScript("OnDragStop", function() this:StopMovingOrSizing(); this.isMoving = false end)

    -- ---------- 内部 Tooltip ----------
    local tip = CreateFrame("GameTooltip", "SM_Tooltip", UIParent, "GameTooltipTemplate")
    tip:SetFrameStrata("TOOLTIP")
    tip:Hide()
    RunOnLoad(tip, function() this:SetOwner(WorldFrame, "ANCHOR_NONE") end)

    -- ---------- 计时器框架 ----------
    local inframe = CreateFrame("Frame", "SM_INFRAME", UIParent)
    inframe.events = {}
    inframe.events.n = 0
    inframe:SetScript("OnUpdate", function() SM_INFRAME_OnUpdate() end)

    -- ---------- 事件宏框架 ----------
    local events = CreateFrame("Frame", "SuperMacro_EventsFrame", UIParent)
    events.events = {}
    events:SetScript("OnEvent", function() SuperMacro_EventsFrame_OnEvent() end)
end

-- ============================================================
-- 构建选项面板
-- ============================================================
local function SuperMacro_BuildOptionsUI()
    local f = CreateFrame("Frame", "SuperMacroOptionsFrame", UIParent)
    f:SetWidth(384)
    f:SetHeight(360) -- 移除窗口宽/高设置项后降低面板高度 by 武藤纯子酱 2026.9.10
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
    f:SetFrameStrata("TOOLTIP")
    f:SetToplevel(true)
    f:SetMovable(true)
    f:SetHitRectInsets(12, 40, 12, 71)
    f:Hide()
    ApplyFlatBackdrop(f, 0.04, 0.04, 0.04, 0.98)

    local title = f:CreateFontString("SuperMacroOptionsTitleText", "ARTWORK", "GameFontNormal")
    title:SetText(SUPERMACRO_OPTIONS_TITLE or "")
    title:SetPoint("CENTER", f, "CENTER", 6, 160)

    local close = CreateFrame("Button", "SuperMacroOptionsCloseButton", f, "UIPanelCloseButton")
    close:SetPoint("CENTER", f, "TOPRIGHT", -44, -25)
    SkinCloseButton(close)

    local exit = CreateFrame("Button", "SuperMacroOptionsExitButton", f, "UIPanelButtonTemplate")
    exit:SetWidth(100); exit:SetHeight(22)
    exit:SetPoint("CENTER", f, "TOPRIGHT", -80, -335)
    exit:SetText(EXIT or "")
    exit:SetScript("OnClick", function() HideUIPanel(this:GetParent()) end)
    SkinFlatButton(exit)

    -- 7 个复选框（已移除“使用长句/等宽字体”两个无效选项） by 武藤纯子酱 2026.9.10
    local lastCB
    for i = 1, 7 do
        local cb = CreateFrame("CheckButton", "SuperMacroOptionsFrameCheckButton" .. i, f)
        cb:SetWidth(40); cb:SetHeight(20) -- 与 GoubayuHeal 开关同尺寸 by 武藤纯子酱 2026.9.10
        if ( i == 1 ) then
            cb:SetPoint("TOPLEFT", f, "TOPLEFT", 50, -70)
        else
            cb:SetPoint("TOP", lastCB, "BOTTOM", 0, -5) -- 每行间距 5px by 武藤纯子酱 2026.9.10
        end
        local t = cb:CreateFontString("SuperMacroOptionsFrameCheckButton" .. i .. "Text", "ARTWORK", "GameFontNormal")
        t:SetPoint("LEFT", cb, "RIGHT", 5, 0) -- 按钮与描述文本间距 5px by 武藤纯子酱 2026.9.10
        MakeFlatToggle(cb)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        lastCB = cb
    end
    -- 各复选框点击行为
    SetToggleClick(getglobal("SuperMacroOptionsFrameCheckButton1"), function()
        SM_VARS.hideAction = this:GetChecked() and 1 or 0; HideActionText()
    end)
    SetToggleClick(getglobal("SuperMacroOptionsFrameCheckButton2"), function()
        SM_VARS.macroTip1 = this:GetChecked() and 1 or 0
    end)
    SetToggleClick(getglobal("SuperMacroOptionsFrameCheckButton3"), function()
        SM_VARS.macroTip2 = this:GetChecked() and 1 or 0; GameTooltipTextLeft2:SetText('')
    end)
    SetToggleClick(getglobal("SuperMacroOptionsFrameCheckButton4"), function()
        SM_VARS.minimap = this:GetChecked() and 1 or 0; ToggleSMMinimap()
    end)
    SetToggleClick(getglobal("SuperMacroOptionsFrameCheckButton5"), function()
        SM_VARS.replaceIcon = this:GetChecked() and 1 or 0
    end)
    SetToggleClick(getglobal("SuperMacroOptionsFrameCheckButton6"), function()
        SM_VARS.checkCooldown = this:GetChecked() and 1 or 0
    end)
    SetToggleClick(getglobal("SuperMacroOptionsFrameCheckButton7"), function()
        SM_VARS.showMenu = this:GetChecked() and 1 or 0; ToggleSMMenu()
    end)

    -- 3 个输入框
    local lastVar
    -- 字体大小：GoubayuHeal 风格滑块（1..15，默认 12，越界回到 12）
    -- 同一行排布：描述文本 | 滑块 | 数值 by 武藤纯子酱 2026.9.10
    -- 控件名仍为 SuperMacroOptionsFrameEditBox1，以兼容 SM_Options 的 SetText 调用
    local t = f:CreateFontString("SuperMacroOptionsFrameEditBox1Text", "ARTWORK", "GameFontNormal")
    t:SetPoint("TOPLEFT", lastCB, "BOTTOMLEFT", 0, -10)
    local eb = CreateFrame("Slider", "SuperMacroOptionsFrameEditBox1", f)
    eb:SetWidth(140); eb:SetHeight(16)
    eb:SetPoint("LEFT", t, "RIGHT", 8, 0)
    eb:SetOrientation("HORIZONTAL")
    eb:SetMinMaxValues(1, 15)
    eb:SetValueStep(1)
    -- 轨道
    local track = eb:CreateTexture(nil, "BACKGROUND")
    track:SetTexture(WHITE)
    track:SetVertexColor(0.15, 0.15, 0.15, 1)
    track:SetHeight(4)
    track:SetPoint("LEFT", eb, "LEFT", 0, 0)
    track:SetPoint("RIGHT", eb, "RIGHT", 0, 0)
    -- 滑块
    local thumb = eb:CreateTexture(nil, "OVERLAY")
    thumb:SetTexture(WHITE)
    thumb:SetWidth(10); thumb:SetHeight(16)
    thumb:SetVertexColor(0.85, 0.55, 0.15, 1)
    pcall(eb.SetThumbTexture, eb, thumb)
    -- 数值显示
    local val = eb:CreateFontString("SuperMacroOptionsFrameEditBox1Value", "OVERLAY", "GameFontNormal")
    val:SetPoint("LEFT", eb, "RIGHT", 8, 0)
    -- 兼容 SM_Options.OnShow 的 SetText：按 1..15 归一，越界回到 12
    eb.SetText = function(self, v)
        local n = tonumber(v)
        if ( not n or n < 1 or n > 15 ) then n = 12 end
        self:SetValue(n)
    end
    eb:SetScript("OnValueChanged", function()
        local v = tonumber(this:GetValue()) or 12
        if ( v < 1 or v > 15 ) then v = 12 end
        SM_VARS.editBoxFontSize = v
        if ( val ) then val:SetText(tostring(v)) end
        SuperMacroUpdateConfig()
    end)
    local lastVar = eb

    -- 颜色选择样本（色块与其描述文字均左对齐到选项列 x=50） by 武藤纯子酱 2026.9.10
    local swatch = CreateFrame("Button", "SuperMacroOptionsFrameColorSwatch1", f)
    swatch:SetWidth(32); swatch:SetHeight(32)
    swatch:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -10)
    local swBg = swatch:CreateTexture("SuperMacroOptionsFrameColorSwatch1SwatchBg", "BACKGROUND")
    swBg:SetTexture(WHITE)
    swBg:SetWidth(32); swBg:SetHeight(32)
    swBg:SetPoint("CENTER", swatch, "CENTER", 0, 0)
    swBg:SetVertexColor(0.1, 0.1, 0.1, 1)
    local normal = swatch:CreateTexture("SuperMacroOptionsFrameColorSwatch1NormalTexture", "OVERLAY")
    normal:SetTexture("Interface\\ChatFrame\\ChatFrameColorSwatch")
    normal:SetWidth(32); normal:SetHeight(32)
    normal:SetPoint("CENTER", swatch, "CENTER", 0, 0)
    -- 命名纹理区域自身即可渲染，无需 SetNormalTexture(对象) by 武藤纯子酱 2026.9.10
    local swText = swatch:CreateFontString("SuperMacroOptionsFrameColorSwatch1Text", "ARTWORK", "GameFontNormal")
    swText:SetPoint("LEFT", swatch, "RIGHT", 5, 0) -- 与色块同一行，间隔 5px by 武藤纯子酱 2026.9.10
    local swExample = swatch:CreateFontString("SuperMacroOptionsFrameColorSwatch1ExampleText", "ARTWORK", "GameFontNormal")
    swExample:SetPoint("TOPLEFT", swText, "BOTTOMLEFT", 0, -5) -- 与上一行左对齐、间隔 5px by 武藤纯子酱 2026.9.10
    swatch:SetScript("OnClick", function()
        CloseMenus()
        SuperMacroOptions_OpenColorPicker(this)
    end)

    f:SetScript("OnShow", function() SuperMacroOptionsFrame_OnShow() end)
    f:SetScript("OnHide", function() SuperMacroOptionsFrame_OnHide() end)
end

-- ============================================================
-- 入口：构建全部界面
-- ============================================================
function SuperMacro_BuildUI()
    if ( SuperMacroFrame ) then return end
    SuperMacro_BuildMainUI()
    SuperMacro_BuildOptionsUI()
end

SuperMacro_BuildUI()
