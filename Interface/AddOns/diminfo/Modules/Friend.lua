local diminfo_Friend = CreateFrame("Button", "diminfo_Friend", UIParent)
local Text = diminfo_Friend:CreateFontString(nil, "OVERLAY")
Text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
Text:SetPoint("RIGHT", diminfo_pos, "LEFT", -20, 0)
diminfo_Friend:SetAllPoints(Text)

-- ========== 构建职业颜色映射 ==========
local classColorMap = {}
local locale = GetLocale()

if locale == "zhCN" or locale == "zhTW" then
    local classMap = {
        ["战士"]      = "WARRIOR",
        ["圣骑士"]    = "PALADIN",
        ["猎人"]      = "HUNTER",
        ["盗贼"]      = "ROGUE",
        ["牧师"]      = "PRIEST",
        ["萨满祭司"]  = "SHAMAN",
        ["法师"]      = "MAGE",
        ["术士"]      = "WARLOCK",
        ["德鲁伊"]    = "DRUID",
    }
    for loc, eng in pairs(classMap) do
        local color = RAID_CLASS_COLORS[eng]
        if color then
            classColorMap[loc] = color
        end
    end
else
    for eng, color in pairs(RAID_CLASS_COLORS) do
        classColorMap[eng] = color
    end
end
-- ==================================================

local function GetNumberFriends()
    local onlineF, numF = 0, GetNumFriends()
    for i = 1, numF do
        if select(5, GetFriendInfo(i)) then onlineF = onlineF + 1 end
    end
    return onlineF, numF
end

local function OnEvent()
    local onlineF = GetNumberFriends()
    Text:SetText(FRIENDS..onlineF)
end

-- ========== 鼠标提示 ==========
-- 使用独立的自定义 Tooltip：ztip 等插件会 hook 全局 GameTooltip 的默认锚点，
-- 把 tooltip 强制拉到屏幕右下角；独立 tooltip 不受其影响，可保持锚定在按钮旁。
local friendTip = CreateFrame("GameTooltip", "diminfo_FriendTip", UIParent, "GameTooltipTemplate")

-- 创建独立的 Alt 监测 Frame（不会干扰 Tooltip 的 OnUpdate）
local altMonitor = CreateFrame("Frame")
altMonitor:Hide()

-- 悬停状态标记：仅在悬停时才刷新提示
local isHovering = false
local currentAlt = nil

-- 刷新提示内容（好友 / 公会成员列表）
local function RefreshTooltip()
    local onlineF, numF = GetNumberFriends()
    local guildName, guildRank = GetGuildInfo("player")
    local guildonline, guildtotal = 0, GetNumGuildMembers(true)

    for i = 1, guildtotal do 
        local guildconnected = select(9, GetGuildRosterInfo(i)) 
        if guildconnected then 
            guildonline = guildonline + 1 
        end 
    end

    friendTip:ClearLines()

    -- 左键/右键信息
    friendTip:AddLine("好友")
    friendTip:AddLine("|CFF4CFF99左键:好友|R".." [在线"..onlineF.."  总数"..numF.."]")
    if guildName then
        friendTip:AddLine("|CFF4CFF99右键:公会|R".." [在线"..guildonline.."  总数"..guildtotal.."]")
    end

    friendTip:AddLine("按住 Alt 显示公会成员", 0.8, 0.8, 1)  -- 淡蓝色

    -- 根据 Alt 键决定显示好友还是公会
    if IsAltKeyDown() then
        -- ====== 显示公会成员 ======
        friendTip:AddLine(" ")
        friendTip:AddLine("在线公会成员:")

        if not guildName then
            friendTip:AddLine("|cffaaaaaa您还没有公会|r")
        else
            local displayed = 0
            for i = 1, guildtotal do
                local name, rank, rankIndex, level, class, zone, note, officerNote, connected = GetGuildRosterInfo(i)
                if connected then
                    local color = classColorMap[class] or {r=1, g=1, b=1}
                    local zoneText = zone or "未知"
                    local nameWithClass = name .. "  (" .. class .. ")"
                    friendTip:AddDoubleLine(
                        nameWithClass,
                        zoneText .. " lv." .. level,
                        color.r, color.g, color.b,
                        1, 1, 1
                    )
                    displayed = displayed + 1
                    if displayed >= 23 then
                        friendTip:AddLine("|cffaaaaaa... 更多公会成员请打开公会面板|r")
                        break
                    end
                end
            end
            if displayed == 0 then
                friendTip:AddLine("|cffaaaaaa当前无在线公会成员|r")
            end
        end
    else
        -- ====== 显示好友列表 ======
        friendTip:AddLine(" ")
        friendTip:AddLine("在线好友:")

        local displayed = 0
        for i = 1, numF do
            local name, level, class, area, connected = GetFriendInfo(i)
            if connected then
                local color = classColorMap[class] or {r=1, g=1, b=1}
                local areaText = area or "未知"
                local nameWithClass = name .. "  (" .. class .. ")"
                friendTip:AddDoubleLine(
                    nameWithClass,
                    areaText .. " lv." .. level,
                    color.r, color.g, color.b,
                    1, 1, 1
                )
                displayed = displayed + 1
                if displayed >= 23 then
                    friendTip:AddLine("|cffaaaaaa... 更多好友请打开好友面板|r")
                    break
                end
            end
        end
        if displayed == 0 then
            friendTip:AddLine("|cffaaaaaa当前无在线好友|r")
        end
    end

    friendTip:Show()
end

-- 强制向服务器拉取最新的好友与公会数据
local function RequestFreshData()
    ShowFriends()                       -- 请求最新好友信息（含好友所在区域）
    if IsInGuild() then
        GuildRoster()                   -- 请求最新公会名单（含在线状态/所在区域）
    end
end

-- 好友/公会数据更新时，若正在悬停则自动刷新提示
altMonitor:SetScript("OnEvent", function()
    if isHovering then
        RefreshTooltip()
    end
end)
altMonitor:RegisterEvent("FRIENDLIST_UPDATE")
altMonitor:RegisterEvent("GUILD_ROSTER_UPDATE")

diminfo_Friend:SetScript("OnEnter", function()
    isHovering = true
    currentAlt = IsAltKeyDown()

    friendTip:SetOwner(this, "ANCHOR_BOTTOMRIGHT", 0, -10)

    -- 强制拉取最新数据，先用缓存内容立即显示，数据返回后由事件自动刷新
    RequestFreshData()
    RefreshTooltip()

    -- ========== 使用独立的 Alt 监测（不影响 Tooltip 的 OnUpdate）==========
    altMonitor:SetScript("OnUpdate", function(monitor, elapsed)
        local altDown = IsAltKeyDown()
        if altDown ~= currentAlt then
            currentAlt = altDown
            RefreshTooltip()
        end
    end)
    altMonitor:Show()
end)

diminfo_Friend:SetScript("OnLeave", function()
    isHovering = false
    friendTip:Hide()
    altMonitor:Hide()
    altMonitor:SetScript("OnUpdate", nil)
end)

-- 左键好友，右键公会
diminfo_Friend:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" then 
        ToggleFriendsFrame(1)
    else
        if IsInGuild() then
            if not GuildFrame then
                LoadAddOn("Blizzard_GuildUI")
            end
            ToggleFriendsFrame(3)
        end
    end
end)

diminfo_Friend:RegisterEvent("PLAYER_ENTERING_WORLD")
diminfo_Friend:RegisterEvent("FRIENDLIST_UPDATE")
diminfo_Friend:SetScript("OnEvent", OnEvent)
