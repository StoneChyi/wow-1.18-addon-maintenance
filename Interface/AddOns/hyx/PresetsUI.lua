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
    if U.presets and U.presets:IsShown() then U.presets.feedback:SetText(message) end
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

function U.RefreshPresets()
    local panel = U.presets
    if not panel or not panel:IsShown() or not D.Presets then return end
    local config = D.Presets.GetConfig()
    local priority, ignore = Item("priority", config.priority), Item("ignore", config.ignore)
    panel.priority.label:SetText(priority.label)
    panel.ignore.label:SetText(ignore.label)
    panel.priorityHint:SetText(priority.hint or "")
    panel.ignoreHint:SetText(ignore.hint or "")
    panel.selfFirst.label:SetText((config.selfFirst and "[✓] " or "[ ] ") .. "优先照顾自己")
    local summary = D.Presets.GetSummary() or {}
    panel.matches:SetText("优先匹配 " .. Count(summary.priorityCount) .. " 人 · 自动过滤 " .. Count(summary.ignoredCount) .. " 人")
    local diag = D.Roles and D.Roles.GetDiagnostics and D.Roles.GetDiagnostics() or {}
    local roles = summary.roles or {}
    local unknown = math.max(Count(diag.unknown), Count(roles.unknown))
    panel.roles:SetText("坦克 " .. Count(roles.tank) .. " · 治疗 " .. Count(roles.healer) .. " · 近战 " .. Count(roles.melee) .. " · 远程 " .. Count(roles.ranged) .. "\n待确认或复核 " .. unknown .. " 人；不按暂定职责过滤。")
    local state = queryNames[diag.state] or (Count(diag.pending) > 0 and "识别中" or "按需识别，默认不持续查询")
    if diag.message and diag.message ~= "" then state = diag.message end
    if Count(diag.total) > 0 then state = state .. " · " .. Count(diag.completed) .. "/" .. Count(diag.total) end
    if diag.pending == true then state = state .. " · 等待回包"
    elseif Count(diag.pending) > 0 then state = state .. " · 等待 " .. Count(diag.pending) end
    if diag.validationActive then state = state .. "\n短时承伤校验正在进行，结果仅作临时参考。" end
    panel.progress:SetText(state)
end

local function Update()
    if U.Render then U.Render(true) end
    if U.manager and U.manager:IsShown() then U.RefreshManager() end
    U.RefreshPresets()
end

local function SetPreset(key, value)
    local ok, reason = D.Presets.Set(key, value)
    if ok == false then Notify(reason or "无法修改预设") end
    Update()
end

local function OpenPicker(kind, anchor)
    if not U.presetPicker then
        local picker = Panel("PureDispelPresetPicker", "选择预设", 400, 280, true)
        U.presetPicker = picker
        picker:SetFrameStrata("TOOLTIP")
        picker.rows = {}
        local blocker = CreateFrame("Button", "PureDispelPresetBlocker", UIParent)
        blocker:SetAllPoints(UIParent); blocker:SetFrameStrata("FULLSCREEN_DIALOG")
        blocker:EnableMouse(true); blocker:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
        blocker:SetScript("OnClick", function() picker:Hide() end); blocker:Hide()
        picker.blocker = blocker
        picker:SetScript("OnHide", function() blocker:Hide(); GameTooltip:Hide() end)
    end
    local picker, options = U.presetPicker, D.Presets.Options[kind] or {}
    picker.kind = kind
    picker.title:SetText(kind == "priority" and "选择优先预设" or "选择忽略预设")
    picker:SetHeight(40 + table.getn(options) * 27)
    local config = D.Presets.GetConfig()
    for i, option in ipairs(options) do
        if not picker.rows[i] then
            local row = Button(picker, "", 376, 24, function()
                local selected = this.option
                if not selected then return end
                local key = picker.kind
                picker:Hide()
                SetPreset(key, selected.key)
            end)
            row:SetPoint("TOPLEFT", picker, "TOPLEFT", 12, -32 - (i - 1) * 27)
            row.label:ClearAllPoints(); row.label:SetPoint("LEFT", row, "LEFT", 7, 0)
            row.label:SetJustifyH("LEFT")
            Tooltip(row, "", "")
            picker.rows[i] = row
        end
        local row = picker.rows[i]
        row.option, row.pdTipTitle, row.pdTipHint = option, option.label, option.hint
        row.label:SetText((config[kind] == option.key and "✓ " or "   ") .. option.label)
        row:Show()
    end
    for i = table.getn(options) + 1, table.getn(picker.rows) do picker.rows[i]:Hide(); picker.rows[i].option = nil end
    picker:ClearAllPoints(); picker:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -3)
    picker.blocker:Show(); picker:Show()
end

function U.OpenPresets()
    if not D.Presets or not D.Roles then Notify("预设模块尚未加载，请重载界面"); return end
    if U.menu then U.menu:Hide() end
    if not U.presets then
        local panel = Panel("PureDispelPresets", "净界驱散 · 优先与忽略预设", 430, 454, true)
        U.presets = panel
        local label = Text(panel, "优先预设", 11); label:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -42)
        panel.priority = Button(panel, "", 396, 25, function() OpenPicker("priority", this) end)
        panel.priority:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -61)
        panel.priorityHint = Text(panel, "", 10)
        panel.priorityHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -93)
        panel.priorityHint:SetWidth(394); panel.priorityHint:SetHeight(28); panel.priorityHint:SetTextColor(.7, .75, .8)
        label = Text(panel, "忽略预设（匹配目标从双区隐藏）", 11)
        label:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -125)
        panel.ignore = Button(panel, "", 396, 25, function() OpenPicker("ignore", this) end)
        panel.ignore:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -144)
        panel.ignoreHint = Text(panel, "", 10)
        panel.ignoreHint:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -176)
        panel.ignoreHint:SetWidth(394); panel.ignoreHint:SetHeight(28); panel.ignoreHint:SetTextColor(.7, .75, .8)
        panel.selfFirst = Button(panel, "", 396, 23, function()
            SetPreset("selfFirst", not D.Presets.GetConfig().selfFirst)
        end)
        panel.selfFirst:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -211)
        Tooltip(panel.selfFirst, "优先照顾自己", "作为独立排序项；手动忽略和减益禁驱规则仍然生效。")
        panel.matches = Text(panel, "", 11); panel.matches:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -247)
        panel.roles = Text(panel, "", 10); panel.roles:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -270)
        panel.roles:SetWidth(394); panel.roles:SetHeight(30); panel.roles:SetTextColor(.7, .75, .8)
        panel.progress = Text(panel, "", 10); panel.progress:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -307)
        panel.progress:SetWidth(394); panel.progress:SetHeight(30); panel.progress:SetTextColor(.7, .7, .7)
        panel.identify = Button(panel, "重新识别", 190, 23, function()
            local ok, reason = D.Roles.Refresh()
            if ok == false then Notify(reason or "暂时无法重新识别") elseif reason then Notify(reason) end
            U.RefreshPresets()
        end)
        panel.identify:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -345)
        Tooltip(panel.identify, "重新识别当前队友", "使用统一查询队列刷新队友天赋；不完整或无可靠回包的队友保留为未确认。")
        panel.manageRoles = Button(panel, "统一职责管理", 196, 23, function() U.OpenRoleEditor() end)
        panel.manageRoles:SetPoint("LEFT", panel.identify, "RIGHT", 10, 0)
        Tooltip(panel.manageRoles, "团队职责", "在pfUI统一管理本队职责，所有关联插件共享修正结果。")
        panel.reset = Button(panel, "恢复默认", 190, 23, function()
            local ok, reason = D.Presets.Reset()
            Notify(ok == false and (reason or "无法恢复默认") or "已恢复默认预设；保留手动名单。")
            Update()
        end)
        panel.reset:SetPoint("TOPLEFT", panel, "TOPLEFT", 17, -382)
        panel.undo = Button(panel, "撤销上次操作", 196, 23, function()
            local ok, reason = D.Undo()
            Notify(ok and "已撤销上次操作" or reason or "没有可撤销的操作")
            Update()
        end)
        panel.undo:SetPoint("LEFT", panel.reset, "RIGHT", 10, 0)
        panel.feedback = Text(panel, "手工名单优先；设本队优先可作为自动过滤的单人例外。", 10)
        panel.feedback:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -419)
        panel.feedback:SetWidth(394); panel.feedback:SetHeight(25); panel.feedback:SetTextColor(.65, .7, .6)
        panel:SetScript("OnShow", function() U.RefreshPresets() end)
        panel:SetScript("OnHide", function() if U.presetPicker then U.presetPicker:Hide() end end)
    end
    U.presets:Show(); U.RefreshPresets()
end

function U.OpenRoleEditor(name)
    if U.menu then U.menu:Hide() end
    if pfUI and type(pfUI.OpenTeamRoles) == "function" then
        pfUI:OpenTeamRoles(name)
    else
        Notify("请启用pfUI团队职责模块；统一识别仍可在后台运行。")
    end
end

-- Reuse the engine's change notification; do not introduce a UI update loop.
local onChanged = D.OnChanged
D.OnChanged = function(force)
    if onChanged then onChanged(force) end
    U.RefreshPresets()
end
