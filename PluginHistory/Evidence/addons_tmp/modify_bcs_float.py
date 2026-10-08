from pathlib import Path

path = Path(r'E:\1.18\Interface\AddOns\BetterCharacterStats\BCS_PropertiesPanel.lua')
source = path.read_text(encoding='utf-8-sig')

def section(start, end, replacement):
    global source
    assert source.count(start) == 1, start
    assert source.count(end) == 1, end
    a, b = source.index(start), source.index(end)
    source = source[:a] + replacement.strip() + '\n\n' + source[b:]

section('-- 更新悬浮窗显示（接收第一行和其余行）', '-- 获取移动速度显示字符串', r'''
-- 多列布局只在布局参数/行数变化时重排；移速仍走 0.2 秒节拍。
function P:UpdateDisplay(show, firstLine, restLines)
    if show ~= 1 then
        self.frame:Hide()
        if self.speedUpdater then self.speedUpdater:Cancel(); self.speedUpdater = nil end
        return
    end
    local lines = {}
    local iter = string.gfind or string.gmatch
    for line in iter(restLines or "", "[^\n]+") do Append(lines, line) end
    local count = ArrayCount(lines)
    local rows = self.rowsPerColumn or 0
    if rows == 0 then rows = math.max(1, count) end
    local columns = math.max(1, math.ceil(count / rows))
    local actualRows = math.min(rows, count)
    local width = self.columnWidth or 140
    local gap = self.lineGap or 3
    local titleSize = self.titleFontSize or 16
    local detailSize = self.detailFontSize or 13
    local signature = table.concat({self.align or "LEFT", rows, columns, actualRows,
        width, gap, titleSize, detailSize, self.scale or 1, self.colorMode or "label"}, ":")

    self.frame.columns = self.frame.columns or {self.frame.details}
    for i = 1, columns do
        if not self.frame.columns[i] then
            self.frame.columns[i] = self.frame:CreateFontString(nil, "ARTWORK")
        end
    end
    if self.layoutDirty or self.layoutSignature ~= signature then
        self.frame:SetScale(self.scale or 1)
        self.frame.title:SetFont("Fonts\\ARIALN.ttf", titleSize, "OUTLINE")
        self.frame.title:ClearAllPoints()
        self.frame.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -10)
        self.frame.title:SetJustifyH(self.align or "LEFT")
        local color = self.colorMode == "off" and RAID_CLASS_COLORS[select(2, UnitClass("player"))]
        if color then self.frame.title:SetTextColor(color.r, color.g, color.b)
        else self.frame.title:SetTextColor(1, 1, 1) end
        self.frame:SetWidth(columns * width + (columns - 1) * 12 + 20)
        self.frame:SetHeight(titleSize + 22 + actualRows * (detailSize + gap))
        self.frame.title:SetWidth(self.frame:GetWidth() - 20)
        for i = 1, ArrayCount(self.frame.columns) do
            local text = self.frame.columns[i]
            text:SetFont("Fonts\\ARIALN.ttf", detailSize, "OUTLINE")
            text:SetTextColor(1, 1, 1)
            text:SetJustifyH(self.align or "LEFT")
            text:SetJustifyV("TOP")
            if text.SetSpacing then text:SetSpacing(gap) end
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + (i - 1) * (width + 12), -(titleSize + 18))
            text:SetWidth(width)
        end
        self.layoutSignature, self.layoutDirty = signature, false
        self.lastFirstLine, self.lastColumnTexts = nil, {}
    end
    if self.lastFirstLine ~= firstLine then
        self.frame.title:SetText(firstLine or "（未选择属性）")
        self.lastFirstLine = firstLine
    end
    self.lastColumnTexts = self.lastColumnTexts or {}
    for i = 1, ArrayCount(self.frame.columns) do
        local text = self.frame.columns[i]
        if i <= columns and count > 0 then
            local values = {}
            for j = (i - 1) * rows + 1, math.min(i * rows, count) do Append(values, lines[j]) end
            local value = table.concat(values, "\n")
            if self.lastColumnTexts[i] ~= value then text:SetText(value); self.lastColumnTexts[i] = value end
            text:Show()
        else text:Hide() end
    end
    self.frame:EnableMouse(not self.locked)
    self.frame:Show()
    if not self.speedUpdater then
        self.speedUpdater = C_Timer.NewTicker(FAST_TICK, function() P:RefreshSpeedDisplay() end)
    end
end
''')

section('-- 真正重建属性内容（会触发 BCS 各重量级取值函数，属于节流对象）', '-- 以下为原有函数，保持不变', r'''
-- 一次重建内三项防御概率使用同一快照；聊天发送独立重新取值。
function P:BuildBody()
    local previousForce = BCS.ForceCalculate
    BCS.ForceCalculate = true
    self.defenseSnapshot = {
        dodge = ReadNumber(GetDodgeChance),
        parry = ReadNumber(GetParryChance),
        block = ReadNumber(GetBlockChance),
    }
    local keys = self:GetSelectedKeys()
    local entries = {}
    for i = 1, ArrayCount(keys) do
        local key = keys[i]
        -- 移速只存位置，实时数值在 GetDisplayLines 中拼接。
        Append(entries, {key=key, text=key ~= "speed" and self:GetPropertyText(key) or nil})
    end
    self.defenseSnapshot = nil
    BCS.ForceCalculate = previousForce
    self.bodyEntries = entries
    self.bodyTitleKey = self:GetTitleKey()
    self.lastBodyRefresh = GetTime()
    self.bodyDirty, self.forceNextBuild = false, false
end

function P:GetDisplayLines()
    local elapsed = GetTime() - (self.lastBodyRefresh or 0)
    if not self.bodyEntries or self.forceNextBuild
        or (self.bodyDirty and elapsed >= MIN_BODY_REFRESH)
        or elapsed >= MAX_BODY_REFRESH then self:BuildBody() end
    local firstLine, rest = nil, {}
    for i = 1, ArrayCount(self.bodyEntries) do
        local entry = self.bodyEntries[i]
        local text = entry.key == "speed" and self:DisplaySpeed() or entry.text
        text = self:FormatPropertyText(entry.key, text or "数据不可用")
        if entry.key == self.bodyTitleKey then firstLine = text
        else Append(rest, text) end
    end
    return firstLine or "（未选择属性）", table.concat(rest, "\n")
end
''')

section('-- ===== 自定义属性勾选窗口 =====', '-- 事件处理', r'''
-- ===== 当前预设属性编辑器 =====
local CBOX_ROW_H, CBOX_COLS, CBOX_COL_W = 20, 2, 166
local itemCount = ArrayCount(PROPERTY_LIST)
local rowCount = math.ceil(itemCount / CBOX_COLS)

P.customFrame = CreateFrame("Frame", "BCSPropertiesPanelCustomFrame", UIParent)
P.customFrame:SetWidth(CBOX_COL_W * CBOX_COLS + 28)
P.customFrame:SetHeight(192 + rowCount * CBOX_ROW_H)
P.customFrame:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", tile=true, tileSize=16})
P.customFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.94)
P.customFrame:SetMovable(true)
P.customFrame:EnableMouse(true)
P.customFrame:RegisterForDrag("LeftButton")
P.customFrame:SetScript("OnDragStart", function() P.customFrame:StartMoving() end)
P.customFrame:SetScript("OnDragStop", function() P.customFrame:StopMovingOrSizing() end)
P.customFrame:SetFrameStrata("DIALOG")
P.customFrame:Hide()

local function EditorLabel(text, x, y, size)
    local label = P.customFrame:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, size or 12)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end
P.editorTitle = EditorLabel("编辑预设", 14, -10, 14)
P.editorTitle:SetTextColor(1, 0.82, 0)
EditorLabel("各预设分别保存，标题项不重复显示", 14, -32, 11):SetTextColor(0.75, 0.75, 0.75)
EditorLabel("大字标题", 14, -61)
EditorLabel("排序属性", 14, -91)
EditorLabel("减伤参照", 14, -122)
EditorLabel("0=同级；指定攻击者等级，仅估算护甲减伤", 106, -122, 10)

local editorClose = CreateButton("关闭", P.customFrame, "TOPRIGHT", P.customFrame, -12, -8,
    function() P.customFrame:Hide() end)
editorClose:SetWidth(46)

function P:SetTitleKey(key)
    local profile = self:EnsureProfile()
    if key ~= "auto" and not profile.props[key] then return end
    profile.titleKey = key
    self:RefreshCustomRows()
    self:RefreshNow()
end

function P:MoveProperty(key, direction)
    local profile = self:EnsureProfile()
    local keys = self:GetSelectedKeys()
    for i = 1, ArrayCount(keys) do
        if keys[i] == key then
            local nextIndex = i + direction
            if nextIndex < 1 or nextIndex > ArrayCount(keys) then return end
            keys[i], keys[nextIndex] = keys[nextIndex], keys[i]
            -- 未选项保留在尾部，之后重新勾选时可恢复。
            local seen = {}
            for j = 1, ArrayCount(keys) do seen[keys[j]] = true end
            for j = 1, ArrayCount(profile.order) do
                if not seen[profile.order[j]] then Append(keys, profile.order[j]) end
            end
            profile.order = keys
            self:RefreshCustomRows()
            self:RefreshNow()
            return
        end
    end
end

local function CreateEditorMenu(name, y, titleMenu)
    local menu = CreateFrame("Frame", name, P.customFrame, "UIDropDownMenuTemplate")
    menu:SetPoint("TOPLEFT", P.customFrame, "TOPLEFT", 86, y)
    UIDropDownMenu_SetWidth(130, menu)
    UIDropDownMenu_Initialize(menu, function()
        local profile = P:EnsureProfile()
        if titleMenu then
            local info = {text="自动（第一项）", value="auto", checked=profile.titleKey == "auto"}
            info.func = function() P:SetTitleKey("auto") end
            UIDropDownMenu_AddButton(info)
        end
        local keys = P:GetSelectedKeys()
        for i = 1, ArrayCount(keys) do
            local key = keys[i]
            local info = {text=PROPERTY_BY_KEY[key].label, value=key}
            if titleMenu then
                info.checked = profile.titleKey == key
                info.func = function() P:SetTitleKey(key) end
            else
                info.checked = P.sortKey == key
                info.func = function() P.sortKey = key; P:RefreshCustomRows() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    return menu
end
P.titleMenu = CreateEditorMenu("BCSPropertiesTitleMenu", -51, true)
P.sortMenu = CreateEditorMenu("BCSPropertiesSortMenu", -81, false)
local upButton = CreateButton("上移", P.customFrame, "TOPLEFT", P.customFrame, 254, -84,
    function() if P.sortKey then P:MoveProperty(P.sortKey, -1) end end)
upButton:SetWidth(40)
local downButton = CreateButton("下移", P.customFrame, "TOPLEFT", P.customFrame, 304, -84,
    function() if P.sortKey then P:MoveProperty(P.sortKey, 1) end end)
downButton:SetWidth(40)

P.reductionEdit = CreateFrame("EditBox", "BCSPropertiesReductionLevel", P.customFrame, "InputBoxTemplate")
P.reductionEdit:SetWidth(40)
P.reductionEdit:SetHeight(20)
P.reductionEdit:SetPoint("TOPLEFT", P.customFrame, "TOPLEFT", 82, -146)
P.reductionEdit:SetAutoFocus(false)
P.reductionEdit:SetNumeric(true)
P.reductionEdit:SetMaxLetters(3)
EditorLabel("级（输入后回车生效）", 132, -151, 11)
local function ApplyReductionLevel()
    local value = tonumber(P.reductionEdit:GetText())
    if not IsFiniteNumber(value) or value < 0 or value > 100 then
        P.reductionEdit:SetText(tostring(P.reductionLevel or 0))
        return
    end
    P:SetPanelOption("reductionLevel", math.floor(value))
    P.reductionEdit:ClearFocus()
end
P.reductionEdit:SetScript("OnEnterPressed", ApplyReductionLevel)
P.reductionEdit:SetScript("OnEscapePressed", function()
    P.reductionEdit:SetText(tostring(P.reductionLevel or 0))
    P.reductionEdit:ClearFocus()
end)
P.reductionEdit:SetScript("OnEditFocusLost", ApplyReductionLevel)

local function PositionCustomWindow()
    local f = P.customFrame
    local screenW = UIParent:GetWidth()
    local right, left = P.mainFrame:GetRight(), P.mainFrame:GetLeft()
    f:ClearAllPoints()
    if right and right + f:GetWidth() + 10 <= screenW - 4 then
        f:SetPoint("TOPLEFT", P.mainFrame, "TOPRIGHT", 10, 0)
    elseif left and left - f:GetWidth() - 10 >= 4 then
        f:SetPoint("TOPRIGHT", P.mainFrame, "TOPLEFT", -10, 0)
    else f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
end

local function CreateCheckRow(item, x, y)
    local key = item.key
    local row = CreateFrame("Button", nil, P.customFrame)
    row:SetWidth(CBOX_COL_W)
    row:SetHeight(CBOX_ROW_H)
    row:SetPoint("TOPLEFT", P.customFrame, "TOPLEFT", x, y)
    row.box = row:CreateTexture(nil, "ARTWORK")
    row.box:SetWidth(14)
    row.box:SetHeight(14)
    row.box:SetPoint("LEFT", 0, 0)
    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    row.text:SetPoint("LEFT", row.box, "RIGHT", 3, 0)
    row.text:SetText(item.label)
    row.key = key
    function row:Refresh()
        local selected = P:EnsureProfile().props[key]
        row.box:SetTexture(selected and "Interface\\Buttons\\UI-CheckBox-Check" or "Interface\\Buttons\\UI-CheckBox-Up")
        local label = item.label
        if P:GetTitleKey() == key then label = label .. "（标题）" end
        row.text:SetText(label)
        if selected then
            local color = PROPERTY_COLORS[key]
            if P.colorMode ~= "off" and color then row.text:SetText("|cFF" .. color .. label .. "|r") end
            row.text:SetTextColor(1, 1, 1)
        else row.text:SetTextColor(0.6, 0.6, 0.6) end
    end
    row:SetScript("OnClick", function()
        local profile = P:EnsureProfile()
        profile.props[key] = not profile.props[key] or nil
        if profile.props[key] then
            local found = false
            for i = 1, ArrayCount(profile.order) do if profile.order[i] == key then found = true end end
            if not found then Append(profile.order, key) end
        elseif profile.titleKey == key then profile.titleKey = "auto" end
        P:RefreshCustomRows()
        P:MarkDirty()
    end)
    row:SetScript("OnEnter", function()
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        if key == "three" then
            GameTooltip:SetText("三维：躲闪概率 + 招架概率 + 格挡概率")
            GameTooltip:AddLine("使用原始百分比求和后保留两位小数。", 0.8, 0.8, 0.8, 1)
        elseif key == "armorDR" then
            GameTooltip:SetText("护甲减伤（经典规则估算）")
            GameTooltip:AddLine("按有效护甲与指定攻击者等级计算，上限 75%。", 0.8, 0.8, 0.8, 1)
            GameTooltip:AddLine("不包含姿态、天赋、技能减伤或魔法抗性。", 0.8, 0.8, 0.8, 1)
        else GameTooltip:SetText(item.label) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

P.customRows = {}
for i = 1, itemCount do
    local r = math.floor((i - 1) / CBOX_COLS)
    local col = (i - 1) - r * CBOX_COLS
    P.customRows[i] = CreateCheckRow(PROPERTY_LIST[i], 14 + col * CBOX_COL_W, -(180 + r * CBOX_ROW_H))
end

function P:ResetCurrentProfile()
    local panel = PanelConfig()
    local name = self.displayConfig
    panel.profiles[name] = nil
    if name == "自定义" then panel.customProps = nil end
    self:EnsureProfile(name)
    self.sortKey = nil
    self:RefreshCustomRows()
    self:RefreshNow()
end

local selectAll = CreateButton("全选", P.customFrame, "BOTTOM", P.customFrame, -126, 10, function()
    local profile = P:EnsureProfile()
    for i = 1, itemCount do profile.props[PROPERTY_LIST[i].key] = true end
    P:RefreshCustomRows()
    P:MarkDirty()
end)
selectAll:SetWidth(56)
local clearAll = CreateButton("清空", P.customFrame, "BOTTOM", P.customFrame, -52, 10, function()
    local profile = P:EnsureProfile()
    for key in pairs(profile.props) do profile.props[key] = nil end
    profile.titleKey = "auto"
    P:RefreshCustomRows()
    P:MarkDirty()
end)
clearAll:SetWidth(56)
local reset = CreateButton("恢复预设", P.customFrame, "BOTTOM", P.customFrame, 32, 10,
    function() P:ResetCurrentProfile() end)
reset:SetWidth(76)
local done = CreateButton("完成", P.customFrame, "BOTTOM", P.customFrame, 126, 10, function()
    ApplyReductionLevel()
    P:RefreshNow()
    P.customFrame:Hide()
end)
done:SetWidth(56)
P.customButtons = {selectAll=selectAll, clearAll=clearAll, reset=reset, done=done}

function P:RefreshCustomRows()
    local profile = self:EnsureProfile()
    self.editorTitle:SetText("编辑预设：" .. (self.displayConfig or "自定义"))
    for i = 1, ArrayCount(self.customRows) do self.customRows[i]:Refresh() end
    local title = profile.titleKey == "auto" and "自动（第一项）" or PROPERTY_BY_KEY[profile.titleKey].label
    UIDropDownMenu_SetText(title, self.titleMenu)
    local keys = self:GetSelectedKeys()
    if not self.sortKey or not profile.props[self.sortKey] then self.sortKey = keys[1] end
    UIDropDownMenu_SetText(self.sortKey and PROPERTY_BY_KEY[self.sortKey].label or "未选择属性", self.sortMenu)
    self.reductionEdit:SetText(tostring(self.reductionLevel or 0))
end

function P:ShowCustomWindow(show)
    if show then
        self:RefreshCustomRows()
        PositionCustomWindow()
        self.customFrame:Show()
    else self.customFrame:Hide() end
end
''')

# Speed is now an ordinary registry entry; do not append it a second time in chat.
start = source.index('    -- 移速行：预设恒显示，自定义由勾选项决定', source.index('function P:GetPropertiesForChat()'))
end = source.index('    -- 还原按需计算开关', start)
source = source[:start] + source[end:]

# Use the same lock setter for buttons and slash commands, including hidden panels.
start = source.index('    elseif arg == "lock" then')
end = source.index('    elseif arg == "togglelock" then', start)
source = source[:start] + '''    elseif arg == "lock" then
        P:SetLocked(true, true)
    elseif arg == "unlock" then
        P:SetLocked(false, true)
''' + source[end:]

source = source.replace('    P.frame:StartMoving()\n', '    P.dragging = true\n    P.frame:StartMoving()\n', 1)
source = source.replace('    P.frame:StopMovingOrSizing()\n', '    P.frame:StopMovingOrSizing()\n    P.dragging = false\n', 1)
source = source.replace('    elseif arg:match("^align ") then', '    elseif string.find(arg, "^align ") then')
source = source.replace('用法：/mb 打开配置窗口，/mb custom 自定义属性勾选窗口', '用法：/mb 打开设置，编辑当前预设可增减属性/设置标题/排序；/mb custom 打开独立自定义')
source = source.replace('已切换到自定义属性，请在勾选窗口中勾选要显示的条目', '已切换到自定义属性，可勾选属性、选择大字标题和调整顺序')
path.write_text(source, encoding='utf-8', newline='\r\n')
print('Updated floating panel module:', path)
