local Message = {}

Meeting.Message = Message
Meeting.blockWords = MEETING_DB.blockWords

local EVENTS = {
    CREATE = "C",
    REQUEST = "R",
    DECLINE = "D",
    MEMBERS = "M",
    CLOSE = "L",
    VERSION = "V",
}

local function CheckBlockWords(playerName, message)
    if playerName == Meeting.player then
        return false
    end
    if not message or message == "" or message == "_" then
        return false
    end
    if not Meeting.blockWords or table.getn(Meeting.blockWords) == 0 then
        return false
    end
    local lowerMessage = string.lower(message)
    for _, word in ipairs(Meeting.blockWords) do
        if word and word ~= "" then
            local lowerWord = string.lower(word)
            -- 纯文本匹配，避免屏蔽词含 ( % + 等模式元字符时报 malformed pattern 错误
            if string.find(lowerMessage, lowerWord, 1, true) then
                return true
            end
        end
    end
    return false
end

Meeting.CheckBlockWords = CheckBlockWords

local function IsEmptyField(v)
    return v == nil or v == ""
end

function Message.OnRecv(playerName, data)
    local _, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 = string.meetingsplit(data, ":")
    if event == EVENTS.CREATE then
        -- 报文被服务器截断（超255字节）或格式异常时字段缺失，直接丢弃，避免 nil 入库导致列表渲染报错
        if IsEmptyField(arg1) or IsEmptyField(arg2) or IsEmptyField(arg3) or IsEmptyField(arg4) or IsEmptyField(arg5) or IsEmptyField(arg6) then
            return
        end
        if CheckBlockWords(playerName, arg2) then return end
        if CheckBlockWords(playerName, playerName) then return end
        Meeting:OnCreate(playerName, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    elseif event == EVENTS.REQUEST then
        Meeting:OnRequest(playerName, arg1, arg2, arg3, arg4, arg5, arg6)
    elseif event == EVENTS.DECLINE then
        Meeting:OnDecline(playerName, arg1)
    elseif event == EVENTS.MEMBERS then
        Meeting:OnMembers(playerName, arg1, arg2)
    elseif event == EVENTS.CLOSE then
        Meeting:OnClose(playerName)
    elseif event == EVENTS.VERSION then
        Meeting:OnVersion(arg1)
    end
end

function Message.OnRecvFormChat(channel, playerName, message)
    if type(message) ~= "string" or type(playerName) ~= "string" or type(channel) ~= "string"
        or message == "" or playerName == "" or string.len(message) > 4096 then return end
    local activity = Meeting:FindActivity(playerName)
    if activity and not activity:IsChat() then return end
    if CheckBlockWords(playerName, message) then return end
    local sourceCode = string.upper(channel)
    -- Identical confirmed advertisements only refresh expiry; no parse/sort/UI churn.
    if activity and activity.raidChat and not activity.raidChat.partial
        and activity.comment == message and activity.code == sourceCode then
        activity.updated = time()
        return
    end
    local raid = Meeting.RaidChat.Parse(message)
    if raid then
        if raid.status == "recruit" then
            Meeting:OnCreate(playerName, sourceCode, message, "0", "0", "0",
                channel == "hardcore" and "1" or "0", nil, nil, raid)
        elseif raid.status == "closed" and activity and activity.raidChat
            and Meeting.RaidChat.Overlaps(raid, activity.raidChat) then
            -- A partial close cannot discard the other half of a combined raid advert.
            local remaining = {}
            for code in pairs(activity.raidChat.codes) do
                if not Meeting.RaidChat.Overlaps(raid, { codes = { [code] = true } }) then remaining[code] = true end
            end
            if not next(remaining) then Meeting:OnClose(playerName)
            else
                activity.raidChat = { status = "recruit", codes = remaining, partial = true }
                Meeting.BrowserFrame:UpdateList()
            end
        end
        return -- A rejected raid message must not re-enter the old keyword-only path.
    end
end

function Message.Send(event, msg)
    local channel = GetChannelName(Meeting.channel)
    if channel ~= 0 then
        SendChatMessage("Meeting:" .. event .. ":" .. msg, "CHANNEL", nil, channel)
    else
        print("请先加入" .. Meeting.channel .. "频道")
    end
end

local function TruncateUtf8(s, maxBytes)
    if string.len(s) <= maxBytes then
        return s
    end
    s = string.sub(s, 1, maxBytes)
    -- 回退尾部不完整的 UTF-8 多字节字符（续字节为 10xxxxxx）
    while string.len(s) > 0 do
        local b = string.byte(s, string.len(s))
        if b < 128 or b >= 192 then
            break
        end
        s = string.sub(s, 1, string.len(s) - 1)
    end
    return s
end

function Message.CreateActivity(code, comment, targetMembers)
    if not Meeting.IsSupportedActivity(code) then return end
    local maxMembers = targetMembers or Meeting.GetActivityMaxMembers(code)
    -- 频道消息上限255字节："Meeting:C:"(10) + 7个冒号 + level/class/members(各≤2) + hc(1) + classnum(9) + targetMembers(≤2) ≈ 34 + code长度
    local budget = 255 - 34 - string.len(code)
    if budget > 200 then
        budget = 200
    end
    if budget < 0 then
        budget = 0
    end
    local safeComment = TruncateUtf8(string.isempty(comment) and "_" or comment, budget)
    local data = string.format("%s:%s:%d:%d:%d:%d:%s:%d", code,
        safeComment, UnitLevel("player"),
        Meeting.ClassToNumber(Meeting.playerClass),
        table.getn(Meeting.members) + 1, Meeting.playerIsHC and 1 or 0,
        Meeting.EncodeGroupClass(), maxMembers)
    MEETING_DB.activity = {
        code = code,
        comment = comment,
        targetMembers = maxMembers,
        lastTime = time()
    }
    Message.InvokeSyncActivityTimer()
    Message.Send(EVENTS.CREATE, data)
end

function Message.Request(id, comment, role)
    local data = string.format("%s:%d:%d:%d:%s:%d", id, UnitLevel("player"),
        Meeting.ClassToNumber(Meeting.playerClass), Meeting.GetPlayerScore(), string.isempty(comment) and "_" or comment,
        role)
    Message.Send(EVENTS.REQUEST, data)
end

function Message.Decline(name)
    Message.Send(EVENTS.DECLINE, string.format("%s", name))
end

function Message.SyncMembers(members)
    Message.Send(EVENTS.MEMBERS, string.format("%d:%s", members, Meeting.EncodeGroupClass()))
end

local syncTimer = nil

function Message.CloseActivity(leave)
    Message.Send(EVENTS.CLOSE, "")
    if not leave then
        MEETING_DB.activity = nil
        -- 活动已彻底关闭，取消60秒同步定时器
        if syncTimer then
            syncTimer:Cancel()
            syncTimer = nil
        end
    end
end

function Message.SendVersion()
    Message.Send(EVENTS.VERSION, Meeting.VERSION.MAJOR .. "." .. Meeting.VERSION.MINOR .. "." .. Meeting.VERSION.PATCH)
end

function Message.InvokeSyncActivityTimer()
    if syncTimer then
        syncTimer:Cancel()
    end
    syncTimer = C_Timer.NewTicker(60, function()
        if Meeting.isAFK then
            return
        end
        local activity = Meeting:FindActivity(Meeting.player)
        if activity then
            Message.CreateActivity(activity.code, activity.comment, activity.targetMembers)
        end
    end, -1)
end