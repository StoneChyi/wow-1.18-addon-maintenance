-- 新增密语历史功能 --
local whisperHistory = {}
local MAX_WHISPER_HISTORY = 10

-- 监听密语事件
local f = CreateFrame("Frame")
f:RegisterEvent("CHAT_MSG_WHISPER")
f:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
f:SetScript("OnEvent", function()
    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
        -- 去重处理(逆序循环避免索引错位)
        for i = table.getn(whisperHistory), 1, -1 do
            if whisperHistory[i] == arg2 then
                table.remove(whisperHistory, i)
            end
        end

        -- 插入到开头并限制长度
        table.insert(whisperHistory, 1, arg2)
        while table.getn(whisperHistory) > MAX_WHISPER_HISTORY do
            table.remove(whisperHistory)
        end
    end
end)

local battlegroundZones = {
    ["奥特兰克山谷"] = true,
    ["战歌峡谷"] = true,
    ["阿拉希盆地"] = true,
    ["阳光林地"] = true,
    ["血环竞技场"] = true,
    ["荆棘峡谷"] = true,
    -- 可以根据需要添加更多战场区域名称
}

-- 检查玩家是否处于战场中
local function IsInBattleground()
    local zoneName = GetZoneText()
    return battlegroundZones[zoneName]
end

function processString(input)
    -- 检查字符串是否以 "/" 开头
    if not string.match(input, "^/") then
        return input
    end

    -- 检查字符串是否以 "/w " 开头
    if string.match(input, "^/w ") then
        local firstSpace = string.find(input, " ", 3)
        if firstSpace then
            local secondSpace = string.find(input, " ", firstSpace + 1)
            if secondSpace then
                return string.sub(input, secondSpace + 1)
            end
        end
        -- 如果没有第二个空格或没有内容，返回空字符串
        return ""
        -- 检查字符串是否以 "/+其他字符+空格" 开头
    elseif string.match(input, "^/.- ") then
        local firstSpace = string.find(input, " ")
        if firstSpace then
            return string.sub(input, firstSpace + 1)
        end
    end
    return ""
end

ChatFrameEditBox:SetScript("OnTabPressed", function()
    if not ChatFrameEditBox:IsVisible() then return end
    local chatFrame = SELECTED_DOCK_FRAME
    if (not chatFrame) then
        chatFrame = DEFAULT_CHAT_FRAME;
    end

    -- 密语频道特殊处理
    if chatFrame.editBox.chatType == "WHISPER" then
        local currentTarget = chatFrame.editBox.tellTarget
        local foundIndex = 0
        local historyCount = table.getn(whisperHistory)

        -- 查找当前目标位置
        for i = 1, historyCount do
            if whisperHistory[i] == currentTarget then
                foundIndex = i
                break
            end
        end

        -- 获取下一个目标(使用math.mod)
        local newTarget
        if historyCount > 0 then
            newTarget = whisperHistory[math.mod(foundIndex, historyCount) + 1]
        end

        if newTarget then
            chatFrame.editBox.tellTarget = newTarget
            chatFrame.editBox:SetText("/w " .. newTarget .. " ")
            -- chatFrame.editBox:HighlightText(3 + string.len(newTarget))
        end
        return
    end

    local channel = { ["世界频道"] = 0, ["世界"] = 0,["中国"] = 0, ["World"] = 0, ["China"] = 0 }
    local keys = { "世界频道", "世界","中国", "World", "China" }
    local JoinedChannel = false
    for channelName, channelID in pairs(channel) do
        local id, _ = GetChannelName(channelName)
        if id > 0 then
            JoinedChannel = true
            channel[channelName] = id
        end
    end

    -- 对 keys 进行降序排序
    table.sort(keys, function(a, b)
        return channel[a] > channel[b]
    end)

    -- 说 --> 战场 --> 队伍 --> 团队 --> 公会 --> 自定义频道 （这几个频道循环显示，在对应频道不能发言的自动跳过（比如不在战场/队伍/团队/公会））
    if (chatFrame.editBox.chatType == "SAY") then
        if IsInBattleground() then
            chatFrame.editBox.chatType = "BATTLEGROUND";
        elseif (GetNumPartyMembers() > 0) then
            chatFrame.editBox.chatType = "PARTY";
        elseif (GetNumRaidMembers() > 0) then
            chatFrame.editBox.chatType = "RAID";
        elseif (IsInGuild()) then
            chatFrame.editBox.chatType = "GUILD";
        elseif JoinedChannel then
            for i = 4, 1, -1 do
                if channel[keys[i]] > 0 then
                    chatFrame.editBox.chatType = "CHANNEL"
                    chatFrame.editBox.channelTarget = channel[keys[i]]
                    break
                end
            end
        end
    elseif (chatFrame.editBox.chatType == "BATTLEGROUND") then
        if (IsInGuild()) then
            chatFrame.editBox.chatType = "GUILD";
        elseif JoinedChannel then
            for i = 4, 1, -1 do
                if channel[keys[i]] > 0 then
                    chatFrame.editBox.chatType = "CHANNEL"
                    chatFrame.editBox.channelTarget = channel[keys[i]]
                    break
                end
            end
        else
            chatFrame.editBox.chatType = "SAY";
        end
    elseif (chatFrame.editBox.chatType == "PARTY") then
        if (GetNumRaidMembers() > 0) then
            chatFrame.editBox.chatType = "RAID";
        elseif (IsInGuild()) then
            chatFrame.editBox.chatType = "GUILD";
        elseif JoinedChannel then
            for i = 4, 1, -1 do
                if channel[keys[i]] > 0 then
                    chatFrame.editBox.chatType = "CHANNEL"
                    chatFrame.editBox.channelTarget = channel[keys[i]]
                    break
                end
            end
        else
            chatFrame.editBox.chatType = "SAY";
        end
    elseif (chatFrame.editBox.chatType == "RAID") then
        if (IsInGuild()) then
            chatFrame.editBox.chatType = "GUILD";
        elseif JoinedChannel then
            for i = 4, 1, -1 do
                if channel[keys[i]] > 0 then
                    chatFrame.editBox.chatType = "CHANNEL"
                    chatFrame.editBox.channelTarget = channel[keys[i]]
                    break
                end
            end
        else
            chatFrame.editBox.chatType = "SAY";
        end
    elseif (chatFrame.editBox.chatType == "GUILD") then
        if JoinedChannel then
            for i = 4, 1, -1 do
                if channel[keys[i]] > 0 then
                    chatFrame.editBox.chatType = "CHANNEL"
                    chatFrame.editBox.channelTarget = channel[keys[i]]
                    break
                end
            end
        else
            chatFrame.editBox.chatType = "SAY";
        end
    elseif (chatFrame.editBox.chatType == "CHANNEL") then
        local currentChannelId, currentChannelName = GetChannelName(chatFrame.editBox.channelTarget);
        -- 定义一个标识，判断是否找到下一个自定义频道
        local found = false
        for i = 4, 1, -1 do
            if channel[keys[i]] > currentChannelId then
                chatFrame.editBox.chatType = "CHANNEL"
                chatFrame.editBox.channelTarget = channel[keys[i]]
                found = true
                break
            end
        end
        if not found then
            chatFrame.editBox.chatType = "SAY";
        end
    else
        -- 当前为未列出的频道时切换为"说"频道
        chatFrame.editBox.chatType = "SAY";
    end
    ChatEdit_UpdateHeader(chatFrame.editBox);

    -- 历史消息切换频道时去掉前面的频道命令
    local text = this:GetText();
    text = processString(text)
    chatFrame.editBox:SetText(text)
end)
