-- Personal modifications: StoneChyi & Codex. Original client UI/authors retained.
-- Native display adapter only. Shared service owns transport and talent cache.
SCInspectTalents = { enabled = false, cacheTime = 30 }
local S = SCInspectTalents
local OWNER = "StatCompareInspect"
local pending, displayed, originals
local serial = 0
S.diagnostics = { state = "idle", tabs = 0, nodes = 0 }
local function Now() return GetTime() end
local function Service()
    local service = SC_TeamRolesService
    if type(service) == "table" and type(service.Request) == "function"
        and type(service.GetInfo) == "function" and type(service.Cancel) == "function" then return service end
end
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
function S.Cancel()
    serial = serial + 1
    if pending then S.diagnostics.state = "canceled" end
    pending, displayed = nil, nil
    local service = Service()
    if service then service:Cancel(OWNER) end
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
    ClosePage()
    S.diagnostics.state, S.diagnostics.reason = "failed", text
    Notice(text)
end
local function FailureReason(reason)
    local text = {
        timeout = "天赋查询超时，请稍后重试。",
        isolated = "上一查询尚在收尾，请稍后重试。",
        identity = "观察目标身份已变化，请重新观察。",
        departed = "观察对象已离开队伍。",
        replaced = "观察对象已变化，请重新观察。",
        incomplete = "天赋数据未收齐，请稍后重新查询。",
        points = "天赋点数校验未通过，请稍后重新查询。",
        structure = "天赋结构与本机数据不兼容。",
        invalid = "收到无效天赋数据，请稍后重新查询。",
        unavailable = "当前天赋查询不可用，请稍后重试。",
        offline = "观察对象暂时不在线。",
        owner = "当前角色身份已变化，请重新观察。"
    }
    return text[reason] or (type(reason) == "string" and reason) or "天赋查询未完成，请稍后重试。"
end
local function Renderable(record)
    if not record or type(record.tabs) ~= "table" or type(record.talents) ~= "table" then return false end
    local data = Turtle_TalentsData and Turtle_TalentsData[record.class]
    if not data then return false end
    for tree = 1, 3 do
        local tab, nodes = record.tabs[tree], record.talents[tree]
        if type(tab) ~= "table" or type(nodes) ~= "table" or type(tab.message) ~= "string"
            or type(tab.count) ~= "number" or tab.count < 0 or tab.count > 20
            or tab.count ~= math.floor(tab.count) or not data[tree] then return false end
        for i = 1, tab.count do
            if not data[tree][i] or type(nodes[i]) ~= "table" or type(nodes[i].message) ~= "string" then return false end
        end
    end
    return true
end
local function Publish(record, stateName)
    local state = originals
    local service = Service()
    if not S.enabled or not state or not state.active or not Visible() or not Matches(record) then return false end
    if not service or type(service.EnsureNativeGuard) ~= "function"
        or type(service.GetNativeMessageHandler) ~= "function" then
        Fail("统一天赋显示通道尚未就绪。"); return false
    end
    service:EnsureNativeGuard()
    local nativeMessage = service:GetNativeMessageHandler()
    if type(nativeMessage) ~= "function" then Fail("原生天赋显示通道尚未就绪。"); return false end
    if not Renderable(record) then Fail("当前天赋结果不适合本机原生界面显示。"); return false end
    -- Initialize the original private display state, suppressing only its
    -- synchronous duplicate request. Restore the sender even on native errors.
    local send = SendAddonMessage
    SendAddonMessage = function(prefix, message, channel, target)
        if prefix == "TW_CHAT_MSG_WHISPER<" .. record.name .. ">" and message == "INSTalentShow" then return end
        return send(prefix, message, channel, target)
    end
    -- Do not draw the old same-player private cache before the replay finishes.
    local show = TWTalentFrame and TWTalentFrame.Show
    if show then TWTalentFrame.Show = function() end end
    local ok = pcall(state.show)
    if show then TWTalentFrame.Show = show end
    SendAddonMessage = send
    if not ok then Fail("天赋界面初始化失败，请重新点击天赋页。"); return false end
    if not S.enabled or not state.active or not Matches(record) or not Visible() then S.Cancel(); return false end
    local function Deliver()
        for tree = 1, 3 do
            nativeMessage(record.tabs[tree].message, record.name)
            for i = 1, record.tabs[tree].count do nativeMessage(record.talents[tree][i].message, record.name) end
        end
        nativeMessage("INSTalentEND;", record.name)
    end
    if not pcall(Deliver) then Fail("天赋数据无法显示，请稍后重新查询。"); return false end
    local nodes = 0
    for tree = 1, 3 do nodes = nodes + record.tabs[tree].count end
    displayed = { name = record.name, class = record.class, key = record.key }
    pending = nil
    S.diagnostics = { state = stateName or "complete", tabs = 3, nodes = nodes }
    if S.status then S.status:Hide() end
    return true
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
    local force = IsControlKeyDown and IsControlKeyDown() and true or false
    if pending and Matches(pending) and not force then return end
    local service = Service()
    if not service then Fail("统一天赋查询服务尚未就绪。"); return end
    S.Cancel()
    if not force then
        local cached = service:GetInfo("target")
        if Matches(cached) and type(cached.time) == "number" and Now() >= cached.time
            and Now() - cached.time <= S.cacheTime and Renderable(cached) then
            Publish(cached, "cached"); return
        end
    end
    local ticket = { name = name, class = class, key = key, serial = serial }
    pending = ticket
    S.diagnostics = { state = "waiting", tabs = 0, nodes = 0 }
    if not S.status then
        S.status = InspectTalentsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        S.status:SetPoint("CENTER", InspectTalentsFrame, "CENTER", -10, 0)
        S.status:SetWidth(260)
        S.status:SetTextColor(.8, .8, .8)
    end
    S.status:SetText("已加入统一天赋查询队列…")
    S.status:Show()
    local function Complete(record, reason)
        if pending ~= ticket or ticket.serial ~= serial or not S.enabled then return end
        if not Visible() or not Matches(ticket) then
            local close = Visible() and not Matches(ticket)
            S.Cancel()
            if close then HideUIPanel(InspectFrame) end
            return
        end
        if not record then Fail(FailureReason(reason)); return end
        if not Matches(record) then S.Cancel(); return end
        Publish(record)
    end
    local ok, accepted, reason = pcall(service.Request, service, "target", OWNER, Complete, force, 100)
    if (not ok or (accepted ~= true and accepted ~= 1)) and pending == ticket then
        Fail((ok and type(reason) == "string" and reason) or "统一天赋查询服务暂不可用。")
    end
end
function S.ShowDiagnostics()
    local d = S.diagnostics
    Notice("模块=" .. tostring(S.enabled) .. "；界面状态=" .. d.state .. "；天赋树=" .. d.tabs .. "/3；节点=" .. d.nodes)
    local service = Service()
    if service and type(service.GetDiagnostics) == "function" then
        local info = service:GetDiagnostics()
        Notice("统一服务：请求=" .. tostring(info.requests or 0) .. "；已完成=" .. tostring(info.completed or 0)
            .. "；等待=" .. tostring(info.queued or 0) .. "；忽略扩展=" .. tostring(info.ignored or 0)
            .. "；最后类型=" .. tostring(info.lastType or "无")
            .. "；队列接收树/节点=" .. tostring(info.tabs or 0) .. "/" .. tostring(info.nodes or 0))
        if type(info.types) == "table" and table.getn(info.types) > 0 then
            Notice("扩展类型：" .. table.concat(info.types, ", "))
        end
    end
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
        if InspectFrameTalentsTab_OnClick == originals.openWrapper then InspectFrameTalentsTab_OnClick = originals.open end
        for _, h in ipairs(originals.scripts) do
            if h.frame:GetScript(h.script) == h.wrapper then h.frame:SetScript(h.script, h.previous) end
        end
        originals = nil
        return
    end
    if S.enabled then return end
    if not InspectTalentsFrame or type(InspectTalentsFrame_OnShow) ~= "function"
        or type(InspectTalentsFrame_HandleMessage) ~= "function" then return end
    originals = { show = InspectTalentsFrame_OnShow,
        open = InspectFrameTalentsTab_OnClick, scripts = {}, active = true }
    local state = originals
    S.enabled = true
    local service = Service()
    if service and type(service.EnsureNativeGuard) == "function" then service:EnsureNativeGuard() end
    state.showWrapper = function()
        if state.active then return S.Request() end
        return state.show()
    end
    state.openWrapper = function()
        if state.active then return S.Open() end
        if state.open then return state.open() end
    end
    InspectTalentsFrame_OnShow = state.showWrapper
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
    Hook(InspectTalentsFrame, "OnHide", function(previous) S.Cancel(); if previous then previous() end end)
    Hook(InspectFrame, "OnHide", function(previous) S.Cancel(); if previous then previous() end end)
    Hook(InspectFrame, "OnEvent", function(previous)
        if Visible() and (event == "PLAYER_TARGET_CHANGED" or event == "PARTY_MEMBERS_CHANGED") then
            if not Matches(pending or displayed) then S.Cancel(); HideUIPanel(InspectFrame) end
            return
        end
        if previous then previous() end
    end)
end
