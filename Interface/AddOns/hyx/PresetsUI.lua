-- PureDispel / 净界驱散: maintained by StoneChyi & Codex.
-- Original hyx / 何雨欣 authorship and original licenses are retained.
-- Preset controls are created only on demand; no polling or addon integration.
local D = XinDispel
local U = D.UI
local Panel, Text, Button = U.CreatePanel, U.CreateText, U.CreateButton
local roleNames = { DAMAGER = "输出", TANK = "坦克", HEALER = "治疗", MELEE = "近战", RANGED = "远程", UNKNOWN = "未确认" }
local confidenceNames = { high = "高", medium = "中", low = "低", unknown = "未确认", confirmed = "已确认" }
local sourceNames = {
    manual = "本队修正", talent = "天赋", talents = "天赋", inspect = "天赋查询",
    maxHealth = "血量上限", maxhealth = "血量上限", health = "血量上限",
    damage = "短时承伤校验", validation = "短时承伤校验", combat = "短时承伤校验",
    class = "职业", cache = "已保存的识别结果", unknown = "待确认", none = "待确认", unavailable = "信息不足",
    ["talent+maxHealth"] = "天赋与血量上限", ["talent+maxHealth+validation"] = "天赋、血量上限与承伤辅助"
}
local queryNames = {
    idle = "尚未查询", pending = "等待回包", queued = "等待查询", requested = "等待回包",
    receiving = "正在接收", complete = "查询完成", completed = "查询完成", success = "查询完成",
    timeout = "回包超时，职责未确认", invalid = "回包不完整，职责未确认",
    unbound = "目标身份未核验", unavailable = "查询接口不可用", unsupported = "查询接口不可用",
    disabled = "尚未启用识别", unknown = "尚未确认", offline = "队友离线，等待上线", paused = "识别已暂停",
    querying = "正在查询天赋", ready = "识别已就绪", isolated = "回复无法安全关联，暂不确认职责"
}

local function Notify(message)
    if not message or message == "" then return end
    if U.presets and U.presets:IsVisible() then U.presets.feedback:SetText(message) end
    if D.Notify then D.Notify(message) end
end

local function Tooltip(button, title, hint)
    local enter, leave = button:GetScript("OnEnter"), button:GetScript("OnLeave")
    button.pdTipTitle, button.pdTipHint = title, hint
    button:SetScript("OnEnter", function()
        if enter then enter() end
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine(this.pdTipTitle or "", 1, 1, 1)
        GameTooltip:AddLine(this.pdTipHint or "", .75, .8, .85, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if leave then leave() end
        GameTooltip:Hide()
    end)
end

local function Item(kind, key)
    local options = D.Presets and D.Presets.Options and D.Presets.Options[kind]
    if options then
        for _, option in ipairs(options) do if option.key == key then return option end end
    end
    return { key = "none", label = "不启用", hint = "保留手动优先和忽略名单。" }
end

local function Count(value)
    return math.max(0, math.floor(tonumber(value) or 0))
end

local function SetTextChanged(text, value)
    value = value or ""
    if text.pdPresetValue == value then return false end
    text:SetText(value)
    text.pdPresetValue = value
    return true
end

local function RoleInfo(name)
    if D.Roles and D.Roles.Get then return D.Roles.Get(name) end
end

function U.AddPresetTooltip(name)
    local info = RoleInfo(name)
    if info then
        local role = roleNames[info.role] or "未确认"
        local source = sourceNames[info.source] or "自动识别"
        local confidence = confidenceNames[info.confidence]
        if type(info.confidence) == "number" then confidence = math.floor(info.confidence * 100) .. "%" end
        GameTooltip:AddLine("职责：" .. role .. " · " .. source .. (confidence and " · 可信度" .. confidence or ""), .75, .85, 1)
        if info.provisional then GameTooltip:AddLine("职责暂定；未达到可靠程度，不用于职责过滤。", 1, .75, .4, true) end
        local maxHealth = tonumber(info.maxHealth)
        if maxHealth and maxHealth > 0 then
            GameTooltip:AddLine("血量上限：" .. math.floor(maxHealth), .7, .7, .7)
        end
        if info.queryState and (not info.role or info.role == "UNKNOWN" or info.provisional) then
            GameTooltip:AddLine(queryNames[info.queryState] or "职责尚待确认", .8, .75, .6)
        end
    else
        GameTooltip:AddLine("职责：未确认", .7, .7, .7)
    end
    if D.Presets and D.Presets.GetReason then
        local reason = D.Presets.GetReason(name)
        if reason and reason ~= "" then GameTooltip:AddLine(reason, .8, .85, .7, true) end
    end
end

local function TextHeight(text, width)
    local value, lines, used, index = text:GetText() or "", 1, 0, 1
    -- UTF-8 glyph estimates keep long status text reachable on clients without
    -- GetStringHeight. The optional native measurement can only increase it.
    while index <= string.len(value) do
        local byte = string.byte(value, index)
        local step, advance = 1, 6
        if byte >= 240 then step, advance = 4, 11
        elseif byte >= 224 then step, advance = 3, 11
        elseif byte >= 192 then step, advance = 2, 11 end
        if byte == 10 then lines, used = lines + 1, 0
        else
            used = used + advance
            if used > width then lines, used = lines + 1, advance end
        end
        index = index + step
    end
    local height = lines * 13 + 3
    text:SetHeight(height)
    if text.GetStringHeight then
        local ok, actual = pcall(text.GetStringHeight, text)
        if ok and type(actual) == "number" and actual > height then height = actual + 3 end
    end
    text:SetHeight(height)
    return height
end

function U.RefreshPresets()
    local panel = U.presets
    if not panel or not panel:IsVisible() or not D.Presets then return end
    local config = D.Presets.GetConfig()
    local priority, ignore = Item("priority", config.priority), Item("ignore", config.ignore)
    SetTextChanged(panel.priority.label, priority.label)
    SetTextChanged(panel.ignore.label, ignore.label)
    SetTextChanged(panel.priorityHint, priority.hint)
    SetTextChanged(panel.ignoreHint, ignore.hint)
    panel.priority.pdTipHint, panel.ignore.pdTipHint = priority.hint, ignore.hint
    SetTextChanged(panel.selfFirst.label, (config.selfFirst and "[✓] " or "[ ] ") .. "优先照顾自己")
    local summary = D.Presets.GetSummary() or {}
    SetTextChanged(panel.matches, "优先匹配 " .. Count(summary.priorityCount) .. " 人 · 自动过滤 " .. Count(summary.ignoredCount) .. " 人")
    local diag = D.Roles and D.Roles.GetDiagnostics and D.Roles.GetDiagnostics() or {}
    local roles = summary.roles or {}
    local unknown = math.max(Count(diag.unknown), Count(roles.unknown))
    SetTextChanged(panel.roles, "坦克 " .. Count(roles.tank) .. " · 治疗 " .. Count(roles.healer) .. " · 近战 " .. Count(roles.melee) .. " · 远程 " .. Count(roles.ranged) .. "\n待确认 / 复核 " .. unknown .. " 人；不按暂定职责过滤。")
    local state = queryNames[diag.state] or (Count(diag.pending) > 0 and "识别中" or "按需识别，默认不持续查询")
    if diag.message and diag.message ~= "" then state = diag.message end
    if Count(diag.total) > 0 then state = state .. " · " .. Count(diag.completed) .. "/" .. Count(diag.total) end
    if diag.pending == true then state = state .. " · 等待回包"
    elseif Count(diag.pending) > 0 then state = state .. " · 等待 " .. Count(diag.pending) end
    if diag.validationActive then state = state .. "\n短时承伤校验正在进行，结果仅作临时参考。" end
    SetTextChanged(panel.progress, state)
    if panel.pdMeasureText ~= state then
        panel.pdMeasureText = state
        local height = TextHeight(panel.progress, 342)
        panel.statusContent:SetHeight(52 + height + 3)
        panel.statusMax = math.max(0, 52 + height + 3 - 81)
        panel.statusOffset = math.min(panel.statusOffset or 0, panel.statusMax)
        panel.statusScroll:SetVerticalScroll(panel.statusOffset)
        if panel.statusMax > 0 then
            if not panel.statusHint:IsShown() then panel.statusHint:Show() end
        elseif panel.statusHint:IsShown() then panel.statusHint:Hide() end
    end
end

local function Update()
    if U.Render then U.Render(true) end
    if U.manager and U.manager:IsVisible() then U.RefreshManager() end
    U.RefreshPresets()
end

local function SetPreset(key, value)
    local ok, reason = D.Presets.Set(key, value)
    if ok == false then Notify(reason or "无法修改预设") end
    Update()
end

function U.PositionPresetPicker(anchor)
    local picker = U.presetPicker
    if not picker then return end
    picker.anchor = anchor or picker.anchor
    anchor = picker.anchor
    if not anchor then return end
    local dock, viewport = U.managerDock, U.GetManagementViewport()
    local scale = dock and tonumber(dock:GetScale()) or 1
    if not scale or scale <= 0 or scale ~= scale then scale = 1 end
    if not viewport then
        picker:SetScale(scale); picker:ClearAllPoints()
        picker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)
        picker.direction = "down"
        return
    end
    local height = picker.designHeight or 281
    scale = math.max(.01, math.min(scale, (viewport.width - viewport.margin * 2) / (358 * viewport.rootScale),
        (viewport.height - viewport.margin * 2) / (height * viewport.rootScale)))
    picker:SetScale(scale)
    local effective = viewport.rootScale * scale
    local anchorScale = tonumber(anchor:GetEffectiveScale()) or effective
    local left, bottom, top = tonumber(anchor:GetLeft()), tonumber(anchor:GetBottom()), tonumber(anchor:GetTop())
    if not left or not bottom or not top or anchorScale <= 0 then return end
    left, bottom, top = left * anchorScale, bottom * anchorScale, top * anchorScale
    local width, physicalHeight, gap = 358 * effective, height * effective, 3 * effective
    local below = bottom - viewport.bottom - viewport.margin - gap
    local above = viewport.top - viewport.margin - top - gap
    if below >= physicalHeight or below >= above then
        bottom = bottom - gap - physicalHeight; picker.direction = "down"
    else bottom = top + gap; picker.direction = "up" end
    left = math.max(viewport.left + viewport.margin, math.min(left, viewport.right - viewport.margin - width))
    bottom = math.max(viewport.bottom + viewport.margin, math.min(bottom, viewport.top - viewport.margin - physicalHeight))
    picker:ClearAllPoints()
    picker:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", (left - viewport.left) / effective, (bottom - viewport.bottom) / effective)
end

local function OpenPicker(kind, anchor)
    if U.menu then U.menu:Hide() end
    if not U.presetPicker then
        local picker = Panel("PureDispelPresetPicker", "选择预设", 358, 281, nil, true)
        U.presetPicker = picker
        picker:SetFrameStrata("FULLSCREEN_DIALOG"); picker:SetFrameLevel(42)
        picker:SetMovable(false); picker:SetScript("OnDragStart", nil); picker:SetScript("OnDragStop", nil)
        picker.rows = {}
        local blocker = CreateFrame("Button", "PureDispelPresetBlocker", UIParent)
        blocker:SetAllPoints(UIParent); blocker:SetFrameStrata("FULLSCREEN_DIALOG"); blocker:SetFrameLevel(40)
        blocker:EnableMouse(true); blocker:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        blocker:SetScript("OnClick", function() picker:Hide() end); blocker:Hide()
        picker.blocker = blocker
        picker:SetScript("OnHide", function()
            blocker:Hide(); GameTooltip:Hide()
            if picker.escapeHeld then
                picker.escapeHeld = nil
                local dock = U.managerDock
                -- A suspended host is returning through the external role
                -- window. Its own close callback restores the Escape entries.
                if not dock or not dock.suspended then U.SetManagementEscape(true) end
            end
        end)
    end
    local picker, options = U.presetPicker, D.Presets.Options[kind] or {}
    picker.kind = kind
    picker.title:SetText(kind == "priority" and "选择优先预设" or "选择忽略预设")
    picker.designHeight = 40 + table.getn(options) * 27
    picker:SetHeight(picker.designHeight)
    local config = D.Presets.GetConfig()
    for i, option in ipairs(options) do
        if not picker.rows[i] then
            local row = Button(picker, "", 334, 24, function()
                local selected = this.option
                if not selected then return end
                local key = picker.kind
                picker:Hide()
                SetPreset(key, selected.key)
            end)
            row:SetPoint("TOPLEFT", picker, "TOPLEFT", 12, -32 - (i - 1) * 27)
            row.label:ClearAllPoints(); row.label:SetPoint("LEFT", row, "LEFT", 7, 0)
            row.label:SetJustifyH("LEFT"); row.label:SetWidth(320)
            Tooltip(row, "", "")
            picker.rows[i] = row
        end
        local row = picker.rows[i]
        row.option, row.pdTipTitle, row.pdTipHint = option, option.label, option.hint
        row.label:SetText((config[kind] == option.key and "✓ " or "   ") .. option.label)
        row:Show()
    end
    for i = table.getn(options) + 1, table.getn(picker.rows) do picker.rows[i]:Hide(); picker.rows[i].option = nil end
    U.PositionPresetPicker(anchor)
    if not picker.escapeHeld then U.SetManagementEscape(false); picker.escapeHeld = true end
    picker.blocker:Show(); picker:Show()
end

local function Card(panel, title, y, height)
    local card = CreateFrame("Frame", nil, panel)
    card:SetWidth(382); card:SetHeight(height)
    card:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, y)
    U.StyleManagement(card)
    card.title = Text(card, title, 11); card.title:SetPoint("TOPLEFT", card, "TOPLEFT", 12, -9)
    return card
end

local function Selector(parent, kind)
    local button = Button(parent, "", 358, 25, function() OpenPicker(kind, this) end)
    button:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -30)
    button.label:ClearAllPoints(); button.label:SetPoint("LEFT", button, "LEFT", 8, 0)
    button.label:SetJustifyH("LEFT"); button.label:SetWidth(304)
    local choose = Text(button, "选择", 10); choose:SetPoint("RIGHT", button, "RIGHT", -8, 0); choose:SetTextColor(.55, .65, .7)
    Tooltip(button, kind == "priority" and "优先预设" or "过滤预设", "")
    return button
end

local function CreatePresets()
    if U.presets then return end
    local panel = Panel("PureDispelPresets", "优先与忽略预设", 410, 505, nil, true)
    U.presets = panel
    U.AttachManagementPane(panel, "presets")
    U.SetManagementEscape(true)
    panel.priorityCard = Card(panel, "优先规则", -40, 92)
    panel.priority = Selector(panel.priorityCard, "priority")
    panel.priorityHint = Text(panel.priorityCard, "", 10)
    panel.priorityHint:SetPoint("TOPLEFT", panel.priorityCard, "TOPLEFT", 12, -63)
    panel.priorityHint:SetWidth(358); panel.priorityHint:SetHeight(24); panel.priorityHint:SetTextColor(.7, .75, .8)
    panel.ignoreCard = Card(panel, "过滤规则", -140, 92)
    local hint = Text(panel.ignoreCard, "匹配者从双区隐藏", 10)
    hint:SetPoint("TOPRIGHT", panel.ignoreCard, "TOPRIGHT", -12, -10); hint:SetTextColor(.6, .65, .7)
    panel.ignore = Selector(panel.ignoreCard, "ignore")
    panel.ignoreHint = Text(panel.ignoreCard, "", 10)
    panel.ignoreHint:SetPoint("TOPLEFT", panel.ignoreCard, "TOPLEFT", 12, -63)
    panel.ignoreHint:SetWidth(358); panel.ignoreHint:SetHeight(24); panel.ignoreHint:SetTextColor(.7, .75, .8)
    panel.selfFirst = Button(panel, "", 382, 24, function() SetPreset("selfFirst", not D.Presets.GetConfig().selfFirst) end)
    panel.selfFirst:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -244)
    Tooltip(panel.selfFirst, "优先照顾自己", "作为独立排序项；手动忽略和减益禁驱规则仍然生效。")
    panel.statusCard = Card(panel, "职责状态", -278, 119)
    panel.statusHint = Text(panel.statusCard, "滚轮查看", 10)
    panel.statusHint:SetPoint("TOPRIGHT", panel.statusCard, "TOPRIGHT", -12, -9)
    panel.statusHint:SetTextColor(.55, .65, .7); panel.statusHint:Hide()
    panel.statusScroll = CreateFrame("ScrollFrame", nil, panel.statusCard)
    panel.statusScroll:SetPoint("TOPLEFT", panel.statusCard, "TOPLEFT", 12, -27)
    panel.statusScroll:SetWidth(358); panel.statusScroll:SetHeight(81)
    panel.statusScroll:EnableMouseWheel(true)
    panel.statusScroll:SetScript("OnMouseWheel", function()
        panel.statusOffset = math.max(0, math.min(panel.statusMax or 0, (panel.statusOffset or 0) + (arg1 > 0 and -26 or 26)))
        panel.statusScroll:SetVerticalScroll(panel.statusOffset)
    end)
    panel.statusContent = CreateFrame("Frame", nil, panel.statusScroll)
    panel.statusContent:SetPoint("TOPLEFT", panel.statusScroll, "TOPLEFT", 0, 0)
    panel.statusContent:SetWidth(350); panel.statusContent:SetHeight(81)
    panel.statusScroll:SetScrollChild(panel.statusContent)
    panel.matches = Text(panel.statusContent, "", 11)
    panel.matches:SetPoint("TOPLEFT", panel.statusContent, "TOPLEFT", 0, 0); panel.matches:SetWidth(342); panel.matches:SetHeight(15)
    panel.roles = Text(panel.statusContent, "", 10)
    panel.roles:SetPoint("TOPLEFT", panel.statusContent, "TOPLEFT", 0, -20)
    panel.roles:SetWidth(342); panel.roles:SetHeight(28); panel.roles:SetTextColor(.7, .75, .8)
    panel.progress = Text(panel.statusContent, "", 10)
    panel.progress:SetPoint("TOPLEFT", panel.statusContent, "TOPLEFT", 0, -52)
    panel.progress:SetWidth(342); panel.progress:SetJustifyV("TOP"); panel.progress:SetTextColor(.7, .7, .7)
    panel.identify = Button(panel, "重新识别", 186, 23, function()
        local ok, reason = D.Roles.Refresh()
        if ok == false then Notify(reason or "暂时无法重新识别") elseif reason then Notify(reason) end
        U.RefreshPresets()
    end)
    panel.identify:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -407)
    Tooltip(panel.identify, "重新识别当前队友", "使用统一查询队列刷新队友天赋；不完整或无可靠回包的队友保留为未确认。")
    panel.manageRoles = Button(panel, "统一职责管理", 186, 23, function() U.OpenRoleEditor() end)
    panel.manageRoles:SetPoint("LEFT", panel.identify, "RIGHT", 10, 0)
    Tooltip(panel.manageRoles, "团队职责", "在pfUI统一管理本队职责，所有关联插件共享修正结果；关闭后返回当前名单。")
    panel.reset = Button(panel, "恢复默认", 186, 23, function()
        local ok, reason = D.Presets.Reset()
        Notify(ok == false and (reason or "无法恢复默认") or "已恢复默认预设；保留手动名单。")
        Update()
    end)
    panel.reset:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -440)
    panel.undo = Button(panel, "撤销上次操作", 186, 23, function()
        local ok, reason = D.Undo()
        Notify(ok and "已撤销上次操作" or reason or "没有可撤销的操作")
        Update()
    end)
    panel.undo:SetPoint("LEFT", panel.reset, "RIGHT", 10, 0)
    panel.feedback = Text(panel, "手工名单优先；设本队优先可作为过滤的单人例外。", 10)
    panel.feedback:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -475)
    panel.feedback:SetWidth(382); panel.feedback:SetHeight(24); panel.feedback:SetTextColor(.65, .7, .6)
    panel.close:SetScript("OnClick", function() U.SetPresetsExpanded(false) end)
    panel:SetScript("OnShow", function() U.RefreshPresets() end)
    panel:SetScript("OnHide", function()
        if U.presetPicker then U.presetPicker:Hide() end
        local dock = U.managerDock
        if dock and dock:IsShown() and not dock.busy and not dock.suspended then U.SetPresetsExpanded(false) end
    end)
end

function U.SetPresetsExpanded(expanded)
    if expanded then
        if not D.Presets or not D.Roles then Notify("预设模块尚未加载，请重载界面"); return end
        U.OpenManager(nil, nil, true)
        CreatePresets()
    end
    local dock = U.managerDock
    if not dock then return end
    dock.busy, dock.expanded = true, expanded and true or false
    if U.presetPicker then U.presetPicker:Hide() end
    if U.presets then if dock.expanded then U.presets:Show() else U.presets:Hide() end end
    dock.busy = false
    U.LayoutManagerDock(); U.RefreshPresets()
end

function U.TogglePresets() U.SetPresetsExpanded(not (U.managerDock and U.managerDock.expanded)) end
function U.OpenPresets() U.SetPresetsExpanded(true) end

function U.RestoreManagerDock()
    local dock = U.managerDock
    if not dock or not dock.suspended then return end
    dock.suspended, dock.externalFrame, dock.busy = nil, nil, true
    U.SetManagementEscape(true)
    dock:Show(); U.manager:Show()
    if U.presets then if dock.expanded then U.presets:Show() else U.presets:Hide() end end
    dock.busy = false
    U.LayoutManagerDock(); U.RefreshManager(); U.RefreshPresets()
end

function U.OpenRoleEditor(name)
    if U.menu then U.menu:Hide() end
    if not pfUI or type(pfUI.OpenTeamRoles) ~= "function" then
        Notify("请启用pfUI团队职责模块；统一识别仍可在后台运行。")
        return
    end
    local dock = U.managerDock
    if dock and dock:IsVisible() then
        dock.suspended = true
        U.SetManagementEscape(false)
        dock:Hide()
    end
    local ok, reason = pcall(pfUI.OpenTeamRoles, pfUI, name)
    if not ok then U.RestoreManagerDock(); error(reason); return end
    local external = pfUI.teamroles and pfUI.teamroles.frame or pfTeamRoles
    if not external or not external:IsShown() then U.RestoreManagerDock(); return end
    if dock and dock.suspended then dock.externalFrame = external end
    if not external.pdManagementLayer then
        external.pdManagementLayer = { strata = external:GetFrameStrata(), level = external:GetFrameLevel() }
    end
    local level = math.max(external:GetFrameLevel(), (dock and dock:GetFrameLevel() or 1) + 20,
        (U.settings and U.settings:GetFrameLevel() or 1) + 20)
    external:SetFrameStrata("DIALOG"); external:SetFrameLevel(level)
    if not external.pdManagementReturn then
        local previous = external:GetScript("OnHide")
        external.pdManagementReturn = true
        external:SetScript("OnHide", function()
            if previous then previous() end
            local saved = external.pdManagementLayer
            external.pdManagementLayer = nil
            if saved then external:SetFrameStrata(saved.strata); external:SetFrameLevel(saved.level) end
            U.RestoreManagerDock()
        end)
    end
end

-- Reuse the engine's change notification; no idle update loop is added.
local onChanged = D.OnChanged
D.OnChanged = function(force)
    if onChanged then onChanged(force) end
    U.RefreshPresets()
end
