-- PureDispel diagnostics: personal modifications maintained by StoneChyi & Codex.
-- Original hyx authorship and applicable licenses are retained.
-- Opt-in memory-only logs. No timer, file IO, network, or global error handler.
local D, U = XinDispel, XinDispel.UI
local B = { enabled = false, limit = 60, count = 0, cursor = 1, logs = {}, version = "2.2.0" }
D.Debug = B
local floor, min, max = math.floor, math.min, math.max
local typeOrder = { "Magic", "Curse", "Poison", "Disease" }
local unitPattern = { "^raid%d+$", "^party%d+$", "^raidpet%d+$", "^partypet%d+$" }
local knownReasons = {
    ["目标已更新"] = true, ["此目标已忽略"] = true, ["减益已变化"] = true,
    ["距离过远"] = true, ["视野之外"] = true, ["距离未知"] = true,
    ["冷却中"] = true, ["法力不足"] = true, ["技能不可用"] = true,
    ["宠物不可用"] = true, ["你已死亡"] = true,
    ["请先完成或取消当前的选取目标操作"] = true,
    ["请先在忽略名单恢复此人，再设为优先"] = true,
    ["请输入有效的角色名字"] = true, ["请输入有效的减益名称"] = true,
    ["未知名单规则"] = true, ["未知作用范围"] = true, ["未知减益规则"] = true,
    ["角色身份尚未就绪，请稍后再试"] = true
}

local function Bool(value) return value and true or false end
local function Yes(value) return value and "是" or "否" end
local function Number(value) return type(value) == "number" and value or 0 end
local function Token(value)
    if value == "player" or value == "pet" or value == "target" or value == "mouseover" then return value end
    if type(value) == "string" and string.len(value) <= 12 then
        for _, pattern in ipairs(unitPattern) do if string.find(value, pattern) then return value end end
    end
    return "单位未指定"
end

local function Reason(value)
    if type(value) == "string" and knownReasons[value] then return value end
    return value ~= nil and "原因已由原界面反馈" or "未提供原因"
end

-- Lua 5.0's implicit arg table includes its exact n, including trailing nils.
-- Recursive return expansion avoids relying on the later unpack(t, i, j) API.
local function Pack(...) return arg end
local function Values(values, index, count)
    if index > count then return end
    return values[index], Values(values, index + 1, count)
end

local function Record(action, detail, result)
    local time = type(GetTime) == "function" and GetTime() or 0
    local outcome = not result[1] and "运行错误（原错误继续抛出）"
        or result[2] and "成功" or ("失败：" .. Reason(result[3]))
    B.logs[B.cursor] = string.format("%.2f", time) .. " | " .. action .. " | " .. detail .. " | " .. outcome
    B.cursor = B.cursor + 1
    if B.cursor > B.limit then B.cursor = 1 end
    B.count = min(B.limit, B.count + 1)
end

local function Finish(result)
    if not result[1] then error(result[2], 0) end
    return Values(result, 2, result.n)
end

local originalCast, originalPolicy, originalRule = D.Cast, D.SetPolicy, D.SetIgnoreRule
D.Cast = function(entry)
    if not B.enabled then return originalCast(entry) end
    local kind = entry and entry.debuff and entry.debuff.type
    local typeName = kind and D.Types[kind] and D.Types[kind].name or "类型未知"
    local detail = Token(entry and entry.unit) .. " · " .. typeName
    local result = Pack(pcall(originalCast, entry))
    Record("驱散", detail, result)
    return Finish(result)
end
D.SetPolicy = function(name, state, scope)
    if not B.enabled then return originalPolicy(name, state, scope) end
    local states = { normal = "清除规则", priority = "设为优先", ignore = "设为忽略" }
    local scopes = { team = "本队", longterm = "长期" }
    local detail = (states[state] or "未知操作") .. " · " .. (scopes[scope or "team"] or "未知范围")
    local result = Pack(pcall(originalPolicy, name, state, scope))
    Record("名单", detail, result)
    return Finish(result)
end
D.SetIgnoreRule = function(name, level)
    if not B.enabled then return originalRule(name, level) end
    local levels = { [0] = "移除自定义规则", [1] = "不提示减益", [2] = "带减益时整人跳过" }
    local result = Pack(pcall(originalRule, name, level))
    Record("减益规则", levels[level] or "未知级别", result)
    return Finish(result)
end

function B.Clear()
    for key in pairs(B.logs) do B.logs[key] = nil end
    B.count, B.cursor = 0, 1
end

function B.SetEnabled(enabled) B.enabled = enabled and true or false end

function B.GetLogs()
    local list = {}
    local first = B.count == B.limit and B.cursor or 1
    for i = 0, B.count - 1 do
        local index = first + i
        if index > B.limit then index = index - B.limit end
        list[i + 1] = B.logs[index]
    end
    return list
end

function B.Snapshot()
    local db, ui = xinDB or {}, D.UI or {}
    local _, class = UnitClass("player")
    local metrics = D.GetMetrics and D.GetMetrics() or {}
    local seen, ignored = {}, 0
    for name, enabled in pairs(db.BlackList or {}) do if enabled then seen[name] = true; ignored = ignored + 1 end end
    if D.teamOwnerReady then
        for name, state in pairs(db.teamRules or {}) do
            if state == "ignore" and not seen[name] then seen[name] = true; ignored = ignored + 1 end
        end
    end
    local snapshot = {
        version = D.VERSION or B.version, class = class or "未知", ready = Bool(D.ready),
        teamOwnerReady = Bool(D.teamOwnerReady), ignoredCount = ignored,
        readyCount = table.getn(D.entries and D.entries.ready or {}),
        blockedCount = table.getn(D.entries and D.entries.blocked or {}),
        metrics = { scanCycles = Number(metrics.scanCycles), tooltipReads = Number(metrics.tooltipReads),
            rangeChecks = Number(metrics.rangeChecks), notifications = Number(metrics.notifications) },
        interfaces = { unitXP = type(UnitXP) == "function", superWoW = SUPERWOW_VERSION ~= nil,
            spellRange = type(IsSpellInRange) == "function", spellUsable = type(IsSpellUsable) == "function",
            directionalCast = type(CastSpellByName) == "function" },
        width = ui.frame and ui.frame:GetWidth() or 0, height = ui.frame and ui.frame:GetHeight() or 0,
        upper = ui.regions and ui.regions.ready and ui.regions.ready.limit or 0,
        lower = ui.regions and ui.regions.blocked and ui.regions.blocked.limit or 0,
        backgroundAlpha = tonumber(db.backgroundAlpha) or .75, borderAlpha = tonumber(db.borderAlpha) or .85,
        followPfUI = db.followPfUI ~= false, pfUILoaded = Bool(pfUI and pfUI.api),
        hidden = not (ui.frame and ui.frame:IsShown()), logging = B.enabled,
        logCount = B.count, logLimit = B.limit, spells = {}
    }
    for _, kind in ipairs(typeOrder) do
        local spell = D.spells and D.spells[kind]
        if spell then
            table.insert(snapshot.spells, { type = kind, name = spell.name, pet = Bool(spell.pet),
                slot = Number(spell.slot), book = spell.pet and "宠物" or "角色" })
        end
    end
    local summary = D.Presets and D.Presets.GetSummary() or {}
    snapshot.presets = { priority=summary.priorityLabel or "未启用", ignore=summary.ignoreLabel or "未启用",
        priorityCount=Number(summary.priorityCount), ignoredCount=Number(summary.ignoredCount) }
    local roles = D.Roles and D.Roles.GetDiagnostics() or {}
    snapshot.roles = { enabled=Bool(roles.enabled), total=Number(roles.total), completed=Number(roles.completed),
        unknown=Number(roles.unknown), validationActive=Bool(roles.validationActive),
        maxHealthReads=Number(roles.maxHealthReads), queryCount=Number(roles.requests),
        damageEvents=Number(roles.validationEvents), pending=Bool(roles.pending),
        timeouts=Number(roles.timeouts), rejected=Number(roles.rejected), isolated=Number(roles.isolated),
        state=({paused="已暂停",querying="查询中",ready="就绪"})[roles.state] or "未启用" }
    return snapshot
end

function B.Report()
    local s = B.Snapshot()
    local lines = {
        "净界驱散 · PureDispel 诊断报告", "版本：" .. s.version,
        "个人修改与维护：StoneChyi & Codex", "原作：hyx / 何雨欣；保留原作者与适用许可。", "",
        "角色职业：" .. s.class, "引擎就绪：" .. Yes(s.ready), "本队规则身份就绪：" .. Yes(s.teamOwnerReady),
        "可驱散人数：" .. s.readyCount, "暂不可驱散人数：" .. s.blockedCount,
        "已忽略人数：" .. s.ignoredCount, "窗口隐藏：" .. Yes(s.hidden), "",
        "已识别技能："
    }
    if table.getn(s.spells) == 0 then table.insert(lines, "  暂无当前角色或宠物可用的友方驱散技能") end
    for _, spell in ipairs(s.spells) do
        local info = D.Types[spell.type]
        table.insert(lines, "  " .. (info and info.name or spell.type) .. "：" .. tostring(spell.name) .. "（" .. spell.book .. "技能书）")
    end
    table.insert(lines, "")
    table.insert(lines, "接口存在状态（不代表 DLL 或实际施法已验证）：")
    table.insert(lines, "  UnitXP：" .. Yes(s.interfaces.unitXP))
    table.insert(lines, "  SuperWoW 标识：" .. Yes(s.interfaces.superWoW))
    table.insert(lines, "  法术范围查询：" .. Yes(s.interfaces.spellRange))
    table.insert(lines, "  技能可用性查询：" .. Yes(s.interfaces.spellUsable))
    table.insert(lines, "  施法函数：" .. Yes(s.interfaces.directionalCast))
    table.insert(lines, "")
    table.insert(lines, "累计工作计数：")
    table.insert(lines, "  扫描轮数：" .. s.metrics.scanCycles .. "；Tooltip 读名：" .. s.metrics.tooltipReads)
    table.insert(lines, "  距离检查：" .. s.metrics.rangeChecks .. "；界面通知：" .. s.metrics.notifications)
    table.insert(lines, "")
    table.insert(lines, "实际窗口：" .. floor(s.width) .. " × " .. floor(s.height))
    table.insert(lines, "实际可见行数：上区 " .. s.upper .. "，下区 " .. s.lower)
    table.insert(lines, "背景不透明度：" .. floor(s.backgroundAlpha * 100 + .5) .. "%")
    table.insert(lines, "边框不透明度：" .. floor(s.borderAlpha * 100 + .5) .. "%")
    table.insert(lines, "字体跟随 pfUI：" .. Yes(s.followPfUI) .. "；pfUI 接口存在：" .. Yes(s.pfUILoaded))
    table.insert(lines, "")
    table.insert(lines, "优先预设：" .. s.presets.priority .. "；忽略预设：" .. s.presets.ignore)
    table.insert(lines, "预设优先人数：" .. s.presets.priorityCount .. "；预设忽略人数：" .. s.presets.ignoredCount)
    table.insert(lines, "统一职责服务：" .. Yes(s.roles.enabled) .. "；队员 " .. s.roles.total .. "；完成查询 " .. s.roles.completed .. "；未知 " .. s.roles.unknown)
    table.insert(lines, "查询状态：" .. s.roles.state .. "；等待回复：" .. Yes(s.roles.pending))
    table.insert(lines, "超时：" .. s.roles.timeouts .. "；拒收：" .. s.roles.rejected .. "；隔离目标数：" .. s.roles.isolated)
    table.insert(lines, "最大生命读取：" .. s.roles.maxHealthReads .. "；天赋请求：" .. s.roles.queryCount)
    table.insert(lines, "职责不读取当前血量，不读取其他插件的职责或名单；协议与事件仍需实服验收。")
    table.insert(lines, "")
    table.insert(lines, "详细日志：" .. (s.logging and "开启" or "关闭") .. "；内存记录 " .. s.logCount .. "/" .. s.logLimit)
    table.insert(lines, "日志仅含单位代号、减益类型、规则类别和状态；不含角色姓名、服务器或账号。")
    for _, line in ipairs(B.GetLogs()) do table.insert(lines, line) end
    return table.concat(lines, "\n")
end

function U.OpenDebug()
    if not B.frame then
        local panel = U.CreatePanel("PureDispelDebug", "净界驱散 · 调试 / 诊断", 540, 470)
        B.frame = panel
        U.debugPanel = panel
        panel.refresh = U.CreateButton(panel, "刷新报告", 100, 24, function() B.RefreshPanel() end)
        panel.refresh:SetPoint("TOPLEFT", panel, "TOPLEFT", 15, -40)
        panel.toggle = U.CreateButton(panel, "详细日志：关", 132, 24, function()
            B.SetEnabled(not B.enabled); B.RefreshPanel()
        end)
        panel.toggle:SetPoint("LEFT", panel.refresh, "RIGHT", 10, 0)
        panel.clear = U.CreateButton(panel, "清空日志", 100, 24, function() B.Clear(); B.RefreshPanel() end)
        panel.clear:SetPoint("LEFT", panel.toggle, "RIGHT", 10, 0)
        panel.select = U.CreateButton(panel, "全选复制", 120, 24, function()
            if panel.report.SetFocus then panel.report:SetFocus() end
            panel.report:HighlightText()
        end)
        panel.select:SetPoint("LEFT", panel.clear, "RIGHT", 10, 0)
        panel.scroll = CreateFrame("ScrollFrame", nil, panel)
        panel.scroll:SetPoint("TOPLEFT", panel, "TOPLEFT", 15, -78)
        panel.scroll:SetWidth(508); panel.scroll:SetHeight(344)
        panel.report = U.CreateEdit(panel.scroll, "PureDispelDebugReport", 495)
        panel.report:SetMultiLine(true); panel.report:SetAutoFocus(false)
        panel.report:SetMaxLetters(65535)
        panel.report:SetFontObject(GameFontHighlightSmall)
        U.SetFont(panel.report, 11)
        if panel.report.SetTextInsets then panel.report:SetTextInsets(5, 5, 5, 5) end
        panel.report:SetHeight(344)
        panel.scroll:SetScrollChild(panel.report)
        local function Wheel()
            panel.offset = max(0, min((panel.offset or 0) + (arg1 > 0 and -40 or 40), max(0, panel.report:GetHeight() - 344)))
            panel.scroll:SetVerticalScroll(panel.offset)
        end
        panel.scroll:EnableMouseWheel(true); panel.scroll:SetScript("OnMouseWheel", Wheel)
        panel.report:EnableMouseWheel(true); panel.report:SetScript("OnMouseWheel", Wheel)
        panel.report:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        panel.hint = U.CreateText(panel, "手动刷新；详细日志默认关闭。全选后按 Ctrl+C 复制。", 10)
        panel.hint:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 15, 18)
        panel.hint:SetTextColor(.65, .65, .65)
        panel:SetScript("OnHide", function() panel.report:ClearFocus() end)
    end
    B.frame:Show(); B.RefreshPanel()
end

function B.RefreshPanel()
    local panel = B.frame
    if not panel then return end
    local report = B.Report()
    U.SetFont(panel.report, 11)
    panel.report:SetText(report)
    local _, lines = string.gsub(report, "\n", "\n")
    panel.report:SetHeight(max(344, (floor(string.len(report) / 65) + lines + 4) * 15))
    panel.offset = 0; panel.scroll:SetVerticalScroll(0)
    panel.toggle.label:SetText(B.enabled and "详细日志：开" or "详细日志：关")
end
