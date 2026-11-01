-- Personal modifications: StoneChyi & Codex. Original client UI/authors retained.
-- Turtle 1.18.1: keep the native renderer, publish only complete target replies.
SCInspectTalents = { enabled = false, timeout = 12, cacheTime = 30 }
local S = SCInspectTalents
local pending, completed, timer, originals
local draining
local recent = {}
S.diagnostics = { state = "idle", tabs = 0, nodes = 0, ignored = 0, types = {} }
local function Now() return GetTime() end
local function Notice(text)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff80c8e7天赋观察：|r" .. text) end
end
local function Identity()
    if not InspectFrame or not InspectFrame.unit or not UnitExists("target")
        or not UnitIsPlayer("target") or not UnitIsUnit(InspectFrame.unit, "target") then return end
    local name = UnitName("target")
    local _, class = UnitClass("target")
    if not name or name == UNKNOWNOBJECT or not class then return end
    local exists, guid = UnitExists("target")
    return name, class, type(guid) == "string" and guid or name
end
local function Matches(record)
    local name, class, key = Identity()
    return record and record.name == name and record.class == class and record.key == key
end
local function Visible()
    return InspectFrame and InspectFrame:IsShown() and InspectTalentsFrame and InspectTalentsFrame:IsShown()
end
local function StopTimer() if timer then timer:SetScript("OnUpdate", nil) end end
function S.Cancel()
    if pending then
        draining = { name = pending.name, deadline = pending.deadline + 2 }
        S.diagnostics.state = "canceled"
    end
    pending = nil
    StopTimer()
    if TWTalentFrame then TWTalentFrame:Hide() end
    if S.status then S.status:Hide() end
end
local function ClosePage()
    S.Cancel()
    if InspectTalentsFrame then InspectTalentsFrame:Hide() end
    if InspectFrame and InspectFrame:IsShown() then
        PanelTemplates_SetTab(InspectFrame, 1)
        InspectFrame_ShowSubFrame("InspectPaperDollFrame")
    end
end
local function Fail(text)
    completed = nil
    ClosePage()
    S.diagnostics.state, S.diagnostics.reason = "failed", text
    Notice(text)
end
local function Fields(message)
    local fields = {}
    for field in string.gfind(message .. ";", "(.-);") do table.insert(fields, field) end
    return fields
end
local function Integer(value, low, high)
    local n = tonumber(value)
    return n and n == math.floor(n) and n >= low and n <= high and n or nil
end
local function Ready(record)
    for tree = 1, 3 do
        local tab = record.tabs[tree]
        if not tab then return false end
        local points = 0
        for index in pairs(record.talents[tree]) do if index > tab.count then return false end end
        for i = 1, tab.count do
            local info = record.talents[tree][i]
            if not info then return false end
            points = points + info.rank
        end
        if points ~= tab.points then return false end
    end
    return true
end
local function Publish(record)
    -- The native initializer owns private SPEC/class state. Suppress only its
    -- duplicate request during this synchronous call; restore even on failure.
    local send = SendAddonMessage
    local function Suppress(prefix, message, channel, target)
        if prefix == "TW_CHAT_MSG_WHISPER<" .. record.name .. ">" and message == "INSTalentShow" then return end
        return send(prefix, message, channel, target)
    end
    SendAddonMessage = Suppress
    local ok = pcall(originals.show)
    SendAddonMessage = send
    if not ok then Fail("天赋界面初始化失败，请重新点击天赋页。"); return end
    if not Matches(record) or not Visible() then S.Cancel(); return end
    local function Deliver()
        for tree = 1, 3 do
            originals.message(record.tabs[tree].message, record.name)
            for i = 1, record.tabs[tree].count do
                originals.message(record.talents[tree][i].message, record.name)
            end
        end
        originals.message("INSTalentEND;", record.name)
    end
    if not pcall(Deliver) then Fail("天赋数据无法显示，请稍后重新查询。"); return end
    completed = { name = record.name, class = record.class, key = record.key, time = Now() }
    S.diagnostics.state = "complete"
    pending = nil
    StopTimer()
    if S.status then S.status:Hide() end
end
function S.Request()
    if not S.enabled or not Visible() then return end
    local name, class, key = Identity()
    if not name or not CanInspect("target") then Fail("请先观察一个有效的玩家目标。"); return end
    if not IsAddOnLoaded("Blizzard_TalentUI") then
        local ok, loaded = pcall(LoadAddOn, "Blizzard_TalentUI")
        if not ok or not loaded or not IsAddOnLoaded("Blizzard_TalentUI") then
            Fail("原生天赋模块未能加载，请重新打开观察窗口。"); return
        end
    end
    if not Turtle_TalentsData or not Turtle_TalentsData[class]
        or not Turtle_TalentsData[class][1] or not Turtle_TalentsData[class][2]
        or not Turtle_TalentsData[class][3] then
        Fail("当前客户端缺少此职业的天赋数据。"); return
    end
    if pending and Matches(pending) then return end
    if completed and Matches(completed) and Now() - completed.time < S.cacheTime
        and not (IsControlKeyDown and IsControlKeyDown()) then
        S.diagnostics.state = "cached"
        TWTalentFrame:Show(); return
    end
    if recent[name] and recent[name] > Now() then
        if completed and Matches(completed) then TWTalentFrame:Show() else ClosePage() end
        if not S.lastWaitNotice or Now() - S.lastWaitNotice >= 2 then
            Notice("上一查询尚在收尾，请 " .. math.ceil(recent[name] - Now()) .. " 秒后重试。")
            S.lastWaitNotice = Now()
        end
        return
    end
    S.Cancel()
    for who, deadline in pairs(recent) do if deadline <= Now() then recent[who] = nil end end
    -- Bounded cancellation quarantine; the wire protocol has no request ID.
    local count, oldest, oldestTime = 0, nil, nil
    for who, deadline in pairs(recent) do
        count = count + 1
        if not oldestTime or deadline < oldestTime then oldest, oldestTime = who, deadline end
    end
    if count >= 16 then recent[oldest] = nil end
    local record = { name = name, class = class, key = key, deadline = Now() + S.timeout,
        tabs = {}, talents = { {}, {}, {} } }
    recent[name] = record.deadline + 2
    pending = record
    S.diagnostics = { state = "waiting", tabs = 0, nodes = 0, ignored = 0, types = {} }
    S.lastWaitNotice = nil
    if not S.status then
        S.status = InspectTalentsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        S.status:SetPoint("CENTER", InspectTalentsFrame, "CENTER", -10, 0)
        S.status:SetWidth(260)
        S.status:SetTextColor(.8, .8, .8)
    end
    S.status:SetText("正在查询天赋…")
    S.status:Show()
    if not timer then timer = CreateFrame("Frame") end
    timer:SetScript("OnUpdate", function()
        if not pending or not Visible() then S.Cancel()
        elseif not Matches(pending) then S.Cancel(); HideUIPanel(InspectFrame)
        elseif Now() >= pending.deadline then Fail("查询超时，请稍后重新点击天赋页重试。") end
    end)
    if not pcall(SendAddonMessage, "TW_CHAT_MSG_WHISPER<" .. name .. ">", "INSTalentShow", "GUILD") then
        Fail("天赋请求未能发送，请稍后重试。")
    end
end
local function Message(native, message, sender)
    if type(message) ~= "string" or not string.find(message, "INSTalent", 1, true) then
        return native(message, sender)
    end
    local receivedLength = string.len(message)
    -- Realm replies may prefix the protocol token with a TAB (0x09).
    -- Strip framing whitespace only; preserve every payload field verbatim.
    message = string.gsub(message, "^%s+", "")
    local delimiter = string.find(message, ";", 1, true)
    local kind = delimiter and string.sub(message, 1, delimiter - 1) or message
    -- Native handlers accept optional tail fields; classify the token before
    -- reading a tree index (END and extension controls have no tree contract).
    if kind == "INSTalentShow" then return native("INSTalentShow", sender) end
    if kind == "INSTalentEND" and draining and sender == draining.name
        and Now() <= draining.deadline and (not pending or sender ~= pending.name) then
        recent[sender], draining = Now() + 2, nil
        return
    end
    local record = pending
    if not record or sender ~= record.name or not Visible() or not Matches(record) then return end
    if Now() >= record.deadline then Fail("查询超时，请稍后重试。"); return end
    if kind ~= "INSTalentEND" and kind ~= "INSTalentTabInfo" and kind ~= "INSTalentInfo" then
        local d = S.diagnostics
        d.ignored = d.ignored + 1
        -- Keep protocol tokens only, never talent names or complete packets.
        local token = string.sub(kind, 1, 48)
        token = string.gsub(token, "[^%w_]", function(c) return string.format("\\x%02X", string.byte(c)) end)
        local seen = false
        for _, value in ipairs(d.types) do if value == token then seen = true end end
        if not seen and table.getn(d.types) < 6 then table.insert(d.types, token) end
        return
    end
    S.diagnostics.lastType = kind
    if receivedLength > 2048 then Fail("收到无效天赋数据，请重新查询。"); return end
    if kind == "INSTalentEND" then
        recent[sender] = Now() + 2
        if Ready(record) then Publish(record)
        else Fail("天赋数据未收齐，请稍后重新查询。") end
        return
    end
    local f = Fields(message)
    local tree = Integer(f[2], 1, 3)
    if not tree then Fail("收到无效天赋树数据。"); return end
    if kind == "INSTalentTabInfo" then
        local points, count = Integer(f[4], 0, 100), Integer(f[5], 0, 20)
        if not points or not count then Fail("收到无效天赋页数据。"); return end
        if not record.tabs[tree] then S.diagnostics.tabs = S.diagnostics.tabs + 1 end
        record.tabs[tree] = { points = points, count = count, message = message }
    elseif kind == "INSTalentInfo" then
        local i = Integer(f[3], 1, 20)
        local tier, column = Integer(f[5], 1, 8), Integer(f[6], 1, 4)
        local rank, maximum = Integer(f[7], 0, 10), Integer(f[8], 1, 10)
        local data = i and Turtle_TalentsData[record.class][tree][i]
        local pt, pc = Integer(f[10], -1, 8), Integer(f[11], -1, 4)
        if not data or not tier or not column or not rank or not maximum or rank > maximum
            or not pt or not pc or (pt ~= -1 and pt < 1) or (pc ~= -1 and pc < 1)
            or (f[9] ~= "0" and f[9] ~= "1") or (f[12] ~= "-1" and f[12] ~= "1") then
            Fail("收到不完整或不兼容的天赋数据。"); return
        end
        if not record.talents[tree][i] then S.diagnostics.nodes = S.diagnostics.nodes + 1 end
        record.talents[tree][i] = { rank = rank, message = message }
    end
end
function S.ShowDiagnostics()
    local d = S.diagnostics
    Notice("模块=" .. tostring(S.enabled) .. "；状态=" .. d.state .. "；天赋树=" .. d.tabs
        .. "/3；节点=" .. d.nodes .. "；忽略扩展=" .. d.ignored
        .. "；最后数据类型=" .. (d.lastType or "无"))
    if table.getn(d.types) > 0 then Notice("扩展类型：" .. table.concat(d.types, ", ")) end
    if d.reason then Notice("上次停止原因：" .. d.reason) end
end
function S.Open()
    if not S.enabled then return end
    if InspectTalentsFrame:IsShown() then S.Request()
    else
        PanelTemplates_SetTab(InspectFrame, InspectTalentsFrame:GetID())
        InspectFrame_ShowSubFrame("InspectTalentsFrame")
    end
end
function S.SetEnabled(enabled)
    if not enabled then
        if not S.enabled then return end
        S.enabled = false
        ClosePage()
        if not originals then return end
        originals.active = false
        if InspectTalentsFrame_OnShow == originals.showWrapper then InspectTalentsFrame_OnShow = originals.show end
        if InspectTalentsFrame_HandleMessage == originals.messageWrapper then InspectTalentsFrame_HandleMessage = originals.message end
        if InspectFrameTalentsTab_OnClick == originals.openWrapper then InspectFrameTalentsTab_OnClick = originals.open end
        for _, h in ipairs(originals.scripts) do
            if h.frame:GetScript(h.script) == h.wrapper then h.frame:SetScript(h.script, h.previous) end
        end
        originals = nil; completed = nil
        return
    end
    if S.enabled then return end
    if not InspectTalentsFrame or type(InspectTalentsFrame_OnShow) ~= "function"
        or type(InspectTalentsFrame_HandleMessage) ~= "function" then return end
    originals = { show = InspectTalentsFrame_OnShow, message = InspectTalentsFrame_HandleMessage,
        open = InspectFrameTalentsTab_OnClick, scripts = {}, active = true }
    local state = originals
    S.enabled = true
    state.showWrapper = function()
        if state.active then return S.Request() end
        return state.show()
    end
    state.messageWrapper = function(message, sender)
        if state.active then return Message(state.message, message, sender) end
        return state.message(message, sender)
    end
    state.openWrapper = function()
        if state.active then return S.Open() end
        if state.open then return state.open() end
    end
    InspectTalentsFrame_OnShow = state.showWrapper
    InspectTalentsFrame_HandleMessage = state.messageWrapper
    InspectFrameTalentsTab_OnClick = state.openWrapper
    local function Hook(frame, script, callback)
        local h = { frame = frame, script = script, previous = frame:GetScript(script) }
        h.wrapper = function()
            if state.active then return callback(h.previous) end
            if h.previous then return h.previous() end
        end
        table.insert(originals.scripts, h)
        frame:SetScript(script, h.wrapper)
    end
    Hook(InspectTalentsFrame, "OnHide", function(previous)
        S.Cancel(); if previous then previous() end
    end)
    Hook(InspectFrame, "OnHide", function(previous)
        S.Cancel(); if previous then previous() end
    end)
    Hook(InspectFrame, "OnEvent", function(previous)
        if Visible() and (event == "PLAYER_TARGET_CHANGED" or event == "PARTY_MEMBERS_CHANGED") then
            if not Matches(pending or completed) then S.Cancel(); HideUIPanel(InspectFrame) end
            return
        end
        if previous then previous() end
    end)
end
