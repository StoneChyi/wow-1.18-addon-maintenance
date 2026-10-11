S_ChatBarDB = S_ChatBarDB or {
    showFrame = true,
    displayMode = "text",  -- text=文字按钮 / color=色块按钮
    colorBarWidth = 45,    -- 色块模式: 长条宽度 (可调)
    colorBarHeight = 8,    -- 色块模式: 长条高度 (可调, 默认8)
    buttons = {
        Say = true,
        Yell = true,
        Whisper = true,
        Party = true,
        Guild = true,
        Officer = false,
        Raid = true,
        RaidWarns = false,
        Battlefield = false,
        General = true,
        Trade = false,
        World = true,
        Zhong = false,
        HC = false,
        Meeting = false,
        RaidProgress = false, 
        XyTracker = false,
        AtlasLoot = false,
        SuperMacro = false,
        ActionBarProfiles = false,
        Outfitter = false, 
        TrinketMenu = false,
        RaidCheck = false,
        SpiritSenseRec = false,
        BetterCharacterStats = false,
        AutoMarker = false,
        SimpleRaidTargetIcons = true,
        Automatonex = false,
        Tracking = false,
        SilverDragonRadar = false,
        CatPotion = false,
        hyx = true,
		ReadyCheck = true,
        Countdown = true,
        Emote = true
    },
    rollGroupOnly = true,    -- Roll点仅统计团队/队伍成员（默认开）
    RollTopN = 3,            -- Roll点统计最高的前几名（默认前3名）
}

local BUTTON_ORDER = {
    "Say", "Yell", "Whisper", "Party", "Guild", "Officer", 
    "Raid", "RaidWarns", "Battlefield", "General", "Trade", 
    "World", "Zhong",
    "HC", "Meeting", 
    "RaidProgress", 
    "XyTracker", "AtlasLoot", 
    "SuperMacro", "ActionBarProfiles", "Outfitter", "TrinketMenu","RaidCheck","SpiritSenseRec",
    "BetterCharacterStats","AutoMarker","SimpleRaidTargetIcons","Automatonex","Tracking","SilverDragonRadar","CatPotion","hyx","ReadyCheck","Countdown","Emote"  
}


local buttonFrames      = {}
local lastVisibleButton = nil

-- Chatbar主框体 --
COLORSCHEME_BORDER      = { 0.3, 0.3, 0.3, 1 }

-- 表情菜单数据
local EmoteData = {
    {
        text = "常用表情",
        menuList = {
            {text = "跳舞", command = "/dance"},
            {text = "特殊跳舞", command = "/dancespecial"},
            {text = "好的", command = "/yes"},
            {text = "不", command = "/no"},
            {text = "否决", command = "/veto"},
            {text = "大笑", command = "/laugh"},
            {text = "咯咯笑", command = "/cackle"},
            {text = "哭泣", command = "/cry"},
            {text = "挥手", command = "/wave"},
            {text = "鞠躬", command = "/bow"},
            {text = "感谢", command = "/thank"},
            {text = "问候", command = "/hi"},
            {text = "性感", command = "/sexy"},
            {text = "法力不足", command = "/oom"},
            {text = "敌人", command = "/incoming"},
            {text = "开火", command = "/openfire"},
            {text = "再见", command = "/bye"},
            {text = "胜利", command = "/victory"},
            {text = "祝贺", command = "/cong"}
        }
    },
    {
        text = "社交表情", 
        menuList = {
            {text = "欢呼", command = "/cheer"},
            {text = "敬礼", command = "/salute"},
            {text = "问候", command = "/greet"},
            {text = "亲吻", command = "/kiss"}, 
            {text = "舔", command = "/lick"}, 
            {text = "咚", command = "/doh"}, 
            {text = "糊涂", command = "/confused"}, 
            {text = "鼓掌", command = "/applaud"},
            {text = "拥抱", command = "/hug"},
            {text = "按摩", command = "/massage"},
            {text = "欢迎", command = "/welcome"},
            {text = "赞扬", command = "/commend"},
            {text = "乞求", command = "/beg"},
            {text = "轻拍", command = "/pat"},
            {text = "小猫", command = "/cat"},
            {text = "眨眼", command = "/blink"}
        }
    },
    {
        text = "负面表情",
        menuList = {
            {text = "生气", command = "/angry"},
            {text = "放屁", command = "/fart"},
            {text = "耳光", command = "/slap"},
            {text = "哈欠", command = "/yawn"},
            {text = "嘲笑", command = "/mock"},
            {text = "威胁", command = "/threaten"},
            {text = "侮辱", command = "/rude"},
            {text = "咆哮", command = "/roar"},
            {text = "皱眉", command = "/frown"},
            {text = "叹气", command = "/sigh"},
            {text = "撕咬", command = "/bite"},
            {text = "退缩 ", command = "/cower"},
            {text = "嘲讽 ", command = "/taunt"},
            {text = "咳嗽 ", command = "/cough"},
            {text = "幸灾乐祸 ", command = "/gloat"},
            {text = "凌辱 ", command = "/insult"},
            {text = "哀悼 ", command = "/mourn"},
            {text = "打嗝", command = "/burp"}
        }
    },
    {
        text = "其他表情",
        menuList = {
            {text = "坐下", command = "/sit"},
            {text = "卑微", command = "/peon"},
            {text = "站立", command = "/stand"},
            {text = "睡觉", command = "/sleep"},
            {text = "吃东西", command = "/eat"},
            {text = "喝酒", command = "/drink"},
            {text = "工作", command = "/work"},
            {text = "失落", command = "/flop"},
            {text = "火车", command = "/train"},
            {text = "屁股", command = "/moon"},
            {text = "强壮", command = "/strong"},
            {text = "臭味", command = "/stink"},
            {text = "压关节", command = "/knuckles"},
            {text = "小鸡", command = "/chicken"}
        }
    }
}

-- 表情菜单创建函数
local function CreateEmoteMenu(level)
    if not level then return end
    
    local info = {}
    
    if level == 1 then
        -- 第一级菜单 - 显示分类
        for _, category in ipairs(EmoteData) do
            info = {}
            info.text = category.text
            info.notCheckable = 1
            info.hasArrow = 1
            info.value = category
            UIDropDownMenu_AddButton(info, level)
        end
    elseif level == 2 then
        -- 第二级菜单 - 显示具体表情
        local category = UIDROPDOWNMENU_MENU_VALUE
        if category and category.menuList then
            for _, e in ipairs(category.menuList) do
                local emote = e
                info = {}
                info.text = emote.text
                info.notCheckable = 1
                info.func = function()
                    local editBox = ChatFrame1.editBox
                    if editBox then
                        editBox:SetText(emote.command)
                        ChatEdit_SendText(editBox, 0)
                    else
                        if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox then
                            DEFAULT_CHAT_FRAME.editBox:SetText(emote.command)
                            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
                        else
                            message("无法找到聊天输入框。")
                        end
                    end
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    end
end

-- 创建表情下拉菜单框架
local EmoteDropdown = CreateFrame("Frame", "EmoteDropdown", UIParent, "UIDropDownMenuTemplate")


-- 更新按钮布局函数
function UpdateButtonLayout()
    lastVisibleButton = nil
    local totalWidth = 1 -- 初始边距

    -- 计算可见按钮总宽度
    for _, btnName in ipairs(BUTTON_ORDER) do
        local btn = buttonFrames[btnName]
        if btn and S_ChatBarDB.buttons[btnName] then
            totalWidth = totalWidth + btn:GetWidth() + 2 -- 按钮宽度 + 间距(放宽)
        end
    end

    -- 动态调整主框体宽度
    chatbar:SetWidth(totalWidth + 5) -- 留出骰子按钮空间

    -- 重新排列按钮
    for _, btnName in ipairs(BUTTON_ORDER) do
        local btn = buttonFrames[btnName]
        if btn then
            btn:ClearAllPoints()
            if S_ChatBarDB.buttons[btnName] then
                if lastVisibleButton then
                    btn:SetPoint("LEFT", lastVisibleButton, "RIGHT", 2, 0)
                else
                    btn:SetPoint("LEFT", chatbar, "LEFT", 2, 0)
                end
                btn:Show()
                lastVisibleButton = btn
            else
                btn:Hide()
            end
        end
    end
end

-- 应用显示模式: text=文字 / color=长条色块
local TEXTBAR_WIDTH = 22    -- 文字模式: 方块宽度 (够放一个中文字, 不挤)
local TEXTBAR_HEIGHT = 20   -- 文字模式: 方块高度
local COLOR_SAT_BOOST = 1.6 -- 色块饱和度提升倍数 (让浅色更鲜明, 不影响聊天文字)

-- 提饱和: 把颜色推离灰点(0.5), 保持色相, 仅用于色块显示
local function vividColor(c)
    local f = COLOR_SAT_BOOST
    local r = 0.5 + (c[1] - 0.5) * f
    local g = 0.5 + (c[2] - 0.5) * f
    local b = 0.5 + (c[3] - 0.5) * f
    return math.min(1, math.max(0, r)), math.min(1, math.max(0, g)), math.min(1, math.max(0, b))
end

local function ApplyDisplayMode()
    local mode = S_ChatBarDB.displayMode or "text"
    local cw = S_ChatBarDB.colorBarWidth or 45
    local ch = S_ChatBarDB.colorBarHeight or 20
    for _, btn in pairs(buttonFrames) do
        if btn and btn.text and btn.t and btn.color then
            if mode == "color" then
                btn.text:Hide()
                btn.t:Show()
                -- 提饱和后的纯色, 不透明 (alpha=1), 长条色块 (宽高可调)
                local r, g, b = vividColor(btn.color)
                btn.t:SetVertexColor(r, g, b, 1)
                btn:SetWidth(cw)
                btn:SetHeight(ch)
                -- 黑色边框 (仅色块模式)
                btn:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2,
                                  insets = { left = 0, right = 0, top = 0, bottom = 0 } })
                btn:SetBackdropBorderColor(0, 0, 0, 1)
                -- 颜色纹理向内缩进 2px, 避免盖住黑边 (子纹理渲染在 backdrop 之上)
                btn.t:ClearAllPoints()
                btn.t:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
                btn.t:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
            else
                btn.text:Show()
                btn.t:Hide()
                btn:SetWidth(TEXTBAR_WIDTH)
                btn:SetHeight(TEXTBAR_HEIGHT)
                btn:SetBackdrop(nil)  -- 文字模式去掉边框
            end
        end
    end
    UpdateButtonLayout()  -- 宽/高变化后重新排版
end

-- 切换显示模式: /cbmode
SLASH_SCBMODE1 = "/cbmode"
SlashCmdList["SCBMODE"] = function()
    S_ChatBarDB.displayMode = (S_ChatBarDB.displayMode == "color") and "text" or "color"
    ApplyDisplayMode()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00聊天栏显示模式: " .. (S_ChatBarDB.displayMode == "color" and "色块" or "文字") .. "|r")
end

-- 调整色块宽度: /cbw <数值>
SLASH_SCBW1 = "/cbw"
SlashCmdList["SCBW"] = function(msg)
    local n = tonumber(msg)
    if n and n >= 10 and n <= 200 then
        S_ChatBarDB.colorBarWidth = n
        ApplyDisplayMode()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00色块宽度: " .. n .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000用法: /cbw <10-200>|r")
    end
end

-- 调整色块高度: /cbh <数值>
SLASH_SCBH1 = "/cbh"
SlashCmdList["SCBH"] = function(msg)
    local n = tonumber(msg)
    if n and n >= 5 and n <= 100 then
        S_ChatBarDB.colorBarHeight = n
        ApplyDisplayMode()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00色块高度: " .. n .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000用法: /cbh <5-100>|r")
    end
end

-- Roll点仅统计团队/队伍成员开关: /cbrollgroup
SLASH_CBROLLGROUP1 = "/cbrollgroup"
SlashCmdList["CBROLLGROUP"] = function()
    S_ChatBarDB.rollGroupOnly = not (S_ChatBarDB.rollGroupOnly or false)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Roll点仅统计团队/队伍成员: " .. (S_ChatBarDB.rollGroupOnly and "开" or "关") .. "|r")
end

-- Roll点统计最高的前几名: /cbrolltop <N>
SLASH_CBROLLTOP1 = "/cbrolltop"
SlashCmdList["CBROLLTOP"] = function(msg)
    local n = tonumber(msg)
    if n and n >= 1 and n <= 20 then
        S_ChatBarDB.RollTopN = n
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Roll点统计前: " .. n .. " 名|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000用法: /cbrolltop <1-20>|r")
    end
end

function Getchannel_name()
    local localtime, servertime = tonumber(date("%H", time())), tonumber(format("%02d", GetGameTime()))
    local channel_name = "World"  -- 默认值
    if abs(localtime - servertime) > 2 then
        channel_name = "World"
    end
    return channel_name
end

local chatbar = CreateFrame("Frame", "chatbar", UIParent)
chatbar:SetWidth(420)
chatbar:SetHeight(40)
chatbar:SetPoint("BOTTOMLEFT", ChatFrame3, "TOPLEFT", 10, 24)
chatbar:RegisterEvent("PLAYER_LOGIN")
chatbar:SetMovable(true)    -- 启用移动
chatbar:SetUserPlaced(true) -- 允许用户放置


-- 在PLAYER_LOGIN事件中修改自动加入逻辑
chatbar:SetScript("OnEvent", function()
print("PLAYER_LOGIN 事件开始")
    S_ChatBarDB.buttons = S_ChatBarDB.buttons or {}
    if S_ChatBarDB.buttons.SimpleRaidTargetIcons == nil then
        S_ChatBarDB.buttons.SimpleRaidTargetIcons = IsAddOnLoaded("SimpleRaidTargetIcons") and true or false
    end
    if S_ChatBarDB.buttons.hyx == nil then
        S_ChatBarDB.buttons.hyx = IsAddOnLoaded("hyx") and true or false
    end
    -- 如果默认是显示状态,那么根据对应插件加载状态设置
    for k, btnName in ipairs(BUTTON_ORDER) do
    if k >= 15 and btnName ~= "Tracking" and btnName ~= "Emote"
       and btnName ~= "ReadyCheck" and btnName ~= "Countdown"
       and S_ChatBarDB.buttons[btnName] then
        if btnName == "AtlasLoot" then
            S_ChatBarDB.buttons[btnName] = IsAddOnLoaded("AtlasLoot") or IsAddOnLoaded("InstanceJournal")
        else
            S_ChatBarDB.buttons[btnName] = IsAddOnLoaded(btnName)
        end
    end
end
    
    -- 初始化离开频道标记
    S_ChatBarDB.leftWorldChannel = S_ChatBarDB.leftWorldChannel or false
    S_ChatBarDB.leftZhongChannel = S_ChatBarDB.leftZhongChannel or false

    -- 暂时注释掉可能出错的代码
    -- if S_MiniMap and MiniMapTrackingFrame then MiniMapTrackingFrame:SetScale(0.4) end
    -- if not S_ChatBarDB.leftWorldChannel then ... end
    -- ChatFrame_RemoveMessageGroup(ChatFrame1, "CHANNEL")
    -- 重新应用已保存的显示模式 (存档在 PLAYER_LOGIN 时才确定加载完成)
    ApplyDisplayMode()
    -- 延迟调用布局
    C_Timer.After(0.2, UpdateButtonLayout)
end)

-- 创建按钮的通用函数
local function CreateChatButton(name, text, tooltip, color, onClick)
    local button = CreateFrame("Button", "Channel" .. name, chatbar)
    button:SetWidth(20)
    button:SetHeight(20)
    button:RegisterForClicks("LeftButtonUp")

    button.t = button:CreateTexture()
    button.t:SetAllPoints()
    button.t:SetTexture("Interface\\Buttons\\WHITE8X8")  -- 纯白实心, 不偏虚
    button.t:SetVertexColor(color[1], color[2], color[3], 1)  -- 纯色不透明
    button.t:Hide()            -- 默认文字模式, 色块先隐藏
    button.color = color       -- 记录频道颜色, 供色块模式使用

    button.text = button:CreateFontString(nil, "OVERLAY")
    button.text:SetFont(STANDARD_TEXT_FONT, 15, "OUTLINE")
    button.text:SetJustifyH("CENTER")
    button.text:SetWidth(25)
    button.text:SetHeight(25)
    button.text:SetPoint("CENTER", 0, 1)
    button.text:SetText(text)
    button.text:SetTextColor(unpack(color))
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- RaidCheck 按钮额外注册中键（触发补BUFF检查宏命令），其它按钮不受影响
    if name == "RaidCheck" then
        button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")
    end
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 6)
        GameTooltip:AddLine(tooltip)
        if name == "Tracking" then
            GameTooltip:AddLine("点击|cFF00CCFF 左键 |r可选择追踪类型", 1, 1, 0)
            GameTooltip:AddLine("点击|cFF00CCFF 右键 |r可选择启用/关闭/切换可移动追踪图标", 1, 1, 0)
        elseif name == "RaidCheck" then
            GameTooltip:AddLine("点击|cFF00CCFF 左键 |r打开BUFF检查界面", 1, 1, 0)
            GameTooltip:AddLine("点击|cFF00CCFF 右键 |r打开团队BUFF分配界面", 1, 1, 0)
            GameTooltip:AddLine("点击|cFF00CCFF 中键 |r集合刷BUFF（全团语音广播）+补BUFF检查", 1, 1, 0)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    buttonFrames[name] = button
    return button
end

-- 改进的 GetChannelID 函数，支持前缀匹配（默认）
local function GetChannelID(channelname, fuzzy)
    local targetLower = string.lower(channelname)
    for i = 1, 10 do
        local id, name = GetChannelName(i)
        if name then
            local nameLower = string.lower(name)
            -- 精确匹配或前缀匹配
            if nameLower == targetLower or string.sub(nameLower, 1, string.len(targetLower)) == targetLower then
                return id
            end
        end
    end
    return nil
end

-- 获取综合频道ID
local function GetGeneralChannelID()
    return GetChannelID("综合") or GetChannelID("General")
end

-- 获取交易频道ID
local function GetTradeChannelID()
    return GetChannelID("交易") or GetChannelID("Trade")
end

-- 专门处理综合频道的函数（修改：保留输入文字）
local function ChannelGeneral_OnClick()
    local chatFrame = SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME
    local channelID = GetGeneralChannelID()
    if channelID then
        chatFrame.editBox:Show()
        chatFrame.editBox.chatType = "CHANNEL"
        chatFrame.editBox.channelTarget = channelID
        ChatEdit_UpdateHeader(chatFrame.editBox)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到综合频道，请先加入综合频道|r")
    end
end

-- 专门处理交易频道的函数（修改：保留输入文字）
local function ChannelTrade_OnClick()
    local chatFrame = SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME
    local channelID = GetTradeChannelID()
    if channelID then
        chatFrame.editBox:Show()
        chatFrame.editBox.chatType = "CHANNEL"
        chatFrame.editBox.channelTarget = channelID
        ChatEdit_UpdateHeader(chatFrame.editBox)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到交易频道，请先加入交易频道|r")
    end
end


local function ChannelEmote_OnClick()
    -- 初始化表情下拉菜单
    UIDropDownMenu_Initialize(EmoteDropdown, CreateEmoteMenu)
    -- 显示菜单
    ToggleDropDownMenu(1, nil, EmoteDropdown, this, 0, 0)
end
local function ChannelReadyCheck_OnClick()
    if DoReadyCheck then
        DoReadyCheck()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000当前客户端不支持就位确认功能|r")
    end
end

-- 倒计时功能
local countdownFrame = CreateFrame("Frame")
countdownFrame:Hide()
local countdownRemaining = 0
local countdownElapsed = 0

local function SendCountdownMessage(msg)
    local isRaidLeader = IsRaidLeader and IsRaidLeader() == 1
    local isRaidOfficer = IsRaidOfficer and IsRaidOfficer() == 1
    if GetNumRaidMembers() > 0 and (isRaidLeader or isRaidOfficer) then
        SendChatMessage(msg, "RAID_WARNING")
    elseif GetNumRaidMembers() > 0 then
        SendChatMessage(msg, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(msg, "PARTY")
    else
        SendChatMessage(msg, "SAY")
    end
end

-- ===== Roll点统计（参考 D:\LootHog） =====
-- rollActive: roll点会话是否开启；rollData: {[玩家名]=最高点数}；rollCount: 参与人数
local rollActive = false
local rollData = {}
local rollCount = 0

-- 监听系统消息中的 /roll 结果（中英文客户端都支持）
local rollDetectFrame = CreateFrame("Frame")
rollDetectFrame:RegisterEvent("CHAT_MSG_SYSTEM")

-- 中文(Turtle/1.12): 玩家掷出85（1-100）；英文: Player rolls 85 (1-100)
local ROLL_PATTERNS = {
    "(.+)掷出(%d+)（(%d+)%-(%d+)）",
    "(.+) rolls (%d+) %((%d+)%-(%d+)%)",
}

local function ParseRollMessage(msg)
    if not msg then return nil end
    for _, pat in ipairs(ROLL_PATTERNS) do
        local _, _, p, r, lo, hi = string.find(msg, pat)
        if p and r then
            -- 只统计标准 /roll（1-100），过滤 /roll 1-2 之类的非标准 roll
            if tonumber(lo) == 1 and tonumber(hi) == 100 then
                return p, tonumber(r)
            end
            return nil
        end
    end
    return nil
end

-- 判断玩家是否在当前团队/队伍中
local function IsGroupMember(name)
    if UnitName("player") == name then return true end
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            if UnitName("raid" .. i) == name then return true end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == name then return true end
        end
    end
    return false
end

-- 根据玩家名取职业（本地化/英文）与所属团队/队伍信息
local function GetRollUnitInfo(name)
    local function probe(unit)
        if UnitName(unit) == name then
            local loc, eng = UnitClass(unit)
            return loc, eng
        end
        return nil
    end
    local loc, eng = probe("player")
    if loc then return loc, eng, nil end
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local loc, eng = probe("raid" .. i)
            if loc then
                local _, _, subgroup = GetRaidRosterInfo(i)
                return loc, eng, (subgroup or "?") .. "队"
            end
        end
    elseif GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            local loc, eng = probe("party" .. i)
            if loc then return loc, eng, i .. "队" end
        end
    end
    return nil, nil, nil
end

rollDetectFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        if not rollActive then return end
        local name, roll = ParseRollMessage(arg1)
        if name and roll then
            -- 仅统计团队成员开关：不在队伍/团队内的 roll 忽略
            if S_ChatBarDB.rollGroupOnly and not IsGroupMember(name) then
                return
            end
            -- 只统计每人第一次 roll 点，防止同一人多次 roll（重复 roll 直接忽略）
            if not rollData[name] then
                rollCount = rollCount + 1
                rollData[name] = roll
            end
        end
    end
end)

-- 开始/重置一次 Roll点统计
local function StartRollSession()
    rollData = {}
    rollCount = 0
    rollActive = true
    SendCountdownMessage(">> 开始Roll点！倒计时结束前请使用 /roll <<")
end

-- 倒计时结束后公布前5名最高点数（参考 LootHog 的排序与公布逻辑）
local function AnnounceRollTop5()
    local list = {}
    for name, roll in pairs(rollData) do
        table.insert(list, { name = name, roll = roll })
    end
    if table.getn(list) == 0 then
        SendCountdownMessage(">> Roll点：无人参与 <<")
        return
    end
    table.sort(list, function(a, b) return a.roll > b.roll end)
    local n = math.min(S_ChatBarDB.RollTopN or 5, table.getn(list))
    -- 标题单独一条，避免过长被截断
    SendCountdownMessage(string.format(">> Roll点前%d名（共%d人参与）<<", n, rollCount))
    for i = 1, n do
        local e = list[i]
        local locClass, engClass, groupInfo = GetRollUnitInfo(e.name)
        -- 取职业颜色（用于名字与职业文字）
        local cc = nil
        if engClass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[engClass] then
            local c = RAID_CLASS_COLORS[engClass]
            cc = string.format("%02x%02x%02x",
                math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
        end
        local nameColored = cc and ("|cff" .. cc .. e.name .. "|r") or e.name
        local classColored = locClass and (cc and ("|cff" .. cc .. locClass .. "|r") or locClass) or ""
        -- 队伍/团信息 + 职业：格式为「{组号}队{职业}」，职业用职业色
        local info = ""
        if groupInfo then info = groupInfo end
        info = info .. classColored
        local line
        if info ~= "" then
            line = string.format("%d. %s %s - %d", i, nameColored, info, e.roll)
        else
            line = string.format("%d. %s - %d", i, nameColored, e.roll)
        end
        -- 每位玩家单独一条消息，避免单条过长被截断
        SendCountdownMessage(line)
    end
end

countdownFrame:SetScript("OnUpdate", function()
    countdownElapsed = countdownElapsed + arg1
    if countdownElapsed >= 1 then
        countdownElapsed = countdownElapsed - 1
        countdownRemaining = countdownRemaining - 1
        if countdownRemaining > 0 then
            SendCountdownMessage("倒计时 " .. countdownRemaining)
        elseif countdownRemaining == 0 then
            if rollActive then
                -- 统计 Roll点：显示 ROLL点结束 并公布前5名
                SendCountdownMessage(">> ROLL点结束 <<")
                AnnounceRollTop5()
                rollActive = false
            else
                -- 不统计 Roll点：正常显示开怪
                SendCountdownMessage(">> 开怪 <<")
            end
            countdownFrame:Hide()
        end
    end
end)

local function StartCountdown(seconds)
    if countdownFrame:IsShown() then return end
    seconds = seconds or S_ChatBarDB.CountdownLen or 5
    countdownRemaining = seconds
    countdownElapsed = 0
    SendCountdownMessage("倒计时 " .. seconds)
    countdownFrame:Show()
end

local function StopCountdown()
    if countdownFrame:IsShown() then
        countdownFrame:Hide()
        SendCountdownMessage("倒计时取消")
    end
end

local function ChannelCountdown_OnClick()
    if arg1 == "LeftButton" then
        -- 左键：开始/取消倒计时（倒计时进行中再次左键则取消）
        if countdownFrame:IsShown() then
            StopCountdown()
        else
            StartCountdown(S_ChatBarDB.CountdownLen or 5)
        end
    else
        -- 右键：开始 Roll点统计（参考 LootHog）
        StartRollSession()
    end
end
local function ChannelRaidProgress_OnClick()
    -- 优先使用新的表格界面
    if _G.RealTableUI and _G.RealTableUI.Show then
        -- 使用新的状态检查函数
        if _G.RealTableUI.IsVisible and _G.RealTableUI.IsVisible() then
            _G.RealTableUI.Hide()
        else
            _G.RealTableUI.Show()
        end
    elseif RaidProgressUI and RaidProgressUI.mainFrame then
        -- 备选：使用旧界面
        if RaidProgressUI.mainFrame:IsShown() then
            RaidProgressUI:HideCombinedInfo()
        else
            RaidProgressUI:ShowCombinedInfo()
        end
    else
        -- 如果都不可用，使用命令行方式
        ChatFrame_OpenChat("/rp", DEFAULT_CHAT_FRAME)
    end
end


local function ChannelMeeting_OnClick()
    if arg1 == "LeftButton" then
        if Meeting then
            Meeting:Toggle()
        end
    elseif arg1 == "RightButton" then
        if LFT_Toggle then
            LFT_Toggle()
        else
            print("LFT功能未加载")
        end
    end
end

local function Automatonex_OnClick()
    if Automaton and Automaton.OnClick then
        Automaton.OnClick()
    else
        ChatFrame_OpenChat("/AUTO ", chatFrame)
    end
end

local function ChannelXyTracker_OnClick()
    if XyTrackerFrame then
        if not XyTrackerFrame:IsShown() then
            XyTracker_ShowXyWindow()
        else
            XyTracker_HideXyWindow()
        end
    end
end

local function AtlasLoot_OnClick()
    local button = arg1
    if button == "LeftButton" then
        -- 左键：优先 AtlasLoot，若未加载则尝试 InstanceJournal
        if IsAddOnLoaded("AtlasLoot") and AtlasLootDefaultFrame then
            if not AtlasLootDefaultFrame:IsShown() then
                AtlasLootDefaultFrame:Show()
            else
                AtlasLootDefaultFrame:Hide()
            end
        elseif IsAddOnLoaded("InstanceJournal") and _G["IJ_InstanceJournalFrame"] then
            -- 备选：切换到 InstanceJournal
            local frame = _G["IJ_InstanceJournalFrame"]
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 AtlasLoot 或 InstanceJournal 插件|r")
        end
    elseif button == "RightButton" then
        -- 右键：始终尝试打开 InstanceJournal（若已加载）
        if IsAddOnLoaded("InstanceJournal") and _G["IJ_InstanceJournalFrame"] then
            local frame = _G["IJ_InstanceJournalFrame"]
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000InstanceJournal 插件未加载或界面不存在|r")
        end
    end
end

local function SuperMacro_OnClick()
    if SuperMacroFrame then
        if not SuperMacroFrame:IsShown() then
            SuperMacroFrame:Show()
        else
            SuperMacroFrame:Hide()
        end
    else
        if not MacroFrame:IsShown() then
            MacroFrame:Show()
        else
            MacroFrame:Hide()
        end
    end
end

function RaidCheck_OnClick()
    local button = arg1
    if button == "MiddleButton" then
        -- 中键：集合刷BUFF（BigWigs sync 全团广播：全员立刻播放 goforbuff 语音）+ 补BUFF检查
        if BigWigsPulltimer and BigWigsPulltimer.BigWigs_BuffCommand and GetNumRaidMembers() > 0 and (IsRaidLeader() or IsRaidOfficer()) then
            BigWigsPulltimer:BigWigs_BuffCommand()
            SendChatMessage("全团集合刷BUFF！", "RAID_WARNING")
        else
            -- 兜底：BigWigs 未加载或无团队权限，仅本地播放语音
            PlaySoundFile("Interface\\AddOns\\BigWigs\\Sounds\\goforbuff.wav")
        end
        if RCBA_BuffCheckAndReport then
            RCBA_BuffCheckAndReport()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000RaidCheck 的补BUFF检查未加载，请确认 RaidCheck 插件已更新|r")
        end
        return
    end
    if button == "RightButton" then
        -- 右键：打开/关闭团队BUFF分配界面（RaidCheckBuffAssign）
        if RCBA_Toggle then
            RCBA_Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000RaidCheck 的分配功能未加载，请确认 RaidCheck 插件已更新|r")
        end
        return
    end
    -- 左键：BUFF检查主窗口
    if RC_MainFrame then
        if RC_MainFrame:IsShown() then
            RC_MainFrame:Hide()
        else
            RC_MainFrame:Show()
        end
    else
        if not RC_MainFrame:IsShown() then
        ChatFrame_OpenChat("/RC ", chatFrame)
        end
    end
end

local function ChannelSilverDragonRadar_OnClick()
    local button = arg1
    if button == "LeftButton" then
        if SunRadar_MainFrame then
            if SunRadar_MainFrame:IsShown() then
                SunRadar_MainFrame:Hide()
            else
                SunRadar_MainFrame:Show()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 SunRadar_MainFrame，请确认 SunRadar 插件已正确加载|r")
        end
    end
end

function SpiritSenseRec_OnClick()
    if SpiritSenseRecMainFrame then
        if not SpiritSenseRecMainFrame:IsShown() then
            SpiritSenseRecMainFrame:Show()
        else
            SpiritSenseRecMainFrame:Hide()
        end
    end
end

function BetterCharacterStats_OnClick()
    if arg1 == "LeftButton" then
        if BCS and BCS.PropertiesPanel and BCS.PropertiesPanel.mainFrame then
            local frame = BCS.PropertiesPanel.mainFrame
            if frame:IsShown() then
                frame:Hide()
            else
                frame:Show()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000属性面板模块未加载|r")
        end
    elseif arg1 == "RightButton" then
        if BCS and BCS.PropertiesPanel and BCS.PropertiesPanel.GetPropertiesForChat then
            local propertiesText = BCS.PropertiesPanel:GetPropertiesForChat()
            
            local targetName = UnitName("target")
            if targetName then
                SendChatMessage(propertiesText, "WHISPER", nil, targetName)
            else
                if WIM_EditBoxInFocus then
                    WIM_EditBoxInFocus:SetText(propertiesText)
                    WIM_EditBoxInFocus:HighlightText()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000属性面板: 没有选择目标且WIM未加载|r")
                end
            end
            
            if BCS.PropertiesPanel.mainFrame then
                BCS.PropertiesPanel.mainFrame:Hide()
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000属性面板模块未加载|r")
        end
    end
end

function AutoMarker_OnClick()
    if AutoMarkerUIFrame then
        if not AutoMarkerUIFrame:IsShown() then
            AutoMarkerUIFrame:Show()
        else
            AutoMarkerUIFrame:Hide()
        end
    end
end

local function TrackingButton_OnClick()
    local button = arg1 -- 使用arg1获取点击按钮
    if button == "LeftButton" then
        if TrackingFrame or MiniMapTrackingFrame then
            TrackingFrame:InitMenu()
            ToggleDropDownMenu(1, nil, TrackingFrame.menu, this, 0, 0)
        end
    elseif button == "RightButton" then
        -- 三种模式循环切换: native → modern → hide → native
        if S_ChatBarDB.trackingMode == "native" then
            S_ChatBarDB.trackingMode = "modern"
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 现代 (modern)|r")
        elseif S_ChatBarDB.trackingMode == "modern" then
            S_ChatBarDB.trackingMode = "hide"
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 隐藏 (hide)|r")
        else
            S_ChatBarDB.trackingMode = "native"
            DEFAULT_CHAT_FRAME:AddMessage("|cffffff00追踪按钮模式: 原生 (native)|r")
        end

        -- 根据新模式立即刷新显示
        if S_ChatBarDB.trackingMode == "native" then
            TrackingFrame:Hide()
            MiniMapTrackingFrame:Show()
        elseif S_ChatBarDB.trackingMode == "modern" then
            TrackingFrame:Show()
            MiniMapTrackingFrame:Hide()
        elseif S_ChatBarDB.trackingMode == "hide" then
            TrackingFrame:Hide()
            MiniMapTrackingFrame:Hide()
        end
    end
end


local function TrinketMenu_OnClick()
    if TrinketMenu_OptFrame then
        if not TrinketMenu_OptFrame:IsShown() then
            TrinketMenu_OptFrame:Show()
        else
            TrinketMenu_OptFrame:Hide()
        end
    end
end

local function ActionBarProfiles_OnClick()
    if ABP_SlashCommand then
        ToggleDropDownMenu(1, nil, ABP_DropDownMenu, this, 0, 0)
    end
end

local function Outfitter_OnClick()
    -- 右键：显示 / 关闭 Outfitter 快速换装栏（QuickSwapBar）
    if arg1 == "RightButton" then
        if OutfitterQuickSwap_Toggle then
            OutfitterQuickSwap_Toggle()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 Outfitter 快速换装栏（QuickSwap），请确认 Outfitter 已加载|r")
        end
        return
    end
    -- 左键：原行为，打开 Outfitter 小地图下拉菜单
    if OutfitterMinimapButton then
        if OutfitterMinimapDropDown_OnLoad then
            OutfitterMinimapDropDown_OnLoad() 
        end
        this.ChangedValueFunc = OutfitterMinimapButton_ItemSelected
        if OutfitterMinimapDropDown_Initialize then
            UIDropDownMenu_Initialize(this, OutfitterMinimapDropDown_Initialize)
        end
        ToggleDropDownMenu(1, nil, this, this, 0, 0)
        if OutfitterMinimapDropDown_AdjustScreenPosition then
            OutfitterMinimapDropDown_AdjustScreenPosition(this)
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000Outfitter 小地图按钮未找到|r")
    end
end

-- 重写的按钮点击事件的函数(切换频道时编辑框中的文本不会消失)--夜晨
local function Channel_OnClick(chatType, isChannel)
    local chatFrame = SELECTED_DOCK_FRAME

    local ButtonName = this:GetName()

    if (not chatFrame) then
        chatFrame = DEFAULT_CHAT_FRAME;
    end
    if not isChannel then
        chatFrame.editBox:Show();
        if (chatFrame.editBox.chatType == chatType) then
            ChatFrame_OpenChat("", chatFrame);
        else
            chatFrame.editBox.chatType = chatType;
        end
    else
        if arg1 == "LeftButton" then
            if type(chatType) == "number" then
                chatFrame.editBox.chatType = "CHANNEL";
                chatFrame.editBox.channelTarget = chatType
            else
                local id, name = GetChannelName(chatType)
                if id and name == chatType then
                    ChatFrameEditBox:Show()
                    ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, chatType)
                    if (chatFrame.editBox.chatType == "CHANNEL") and (chatFrame.editBox.channelTarget == id) then
                        ChatFrame_OpenChat("", chatFrame);
                    else
                        chatFrame.editBox.chatType = "CHANNEL";
                        chatFrame.editBox.channelTarget = id
                    end
                else
                    JoinChannelByName(chatType, nil, 1)
                end
            end
        end
    end
    local text = chatFrame.editBox:GetText()
    text = processString(text)
    chatFrame.editBox:SetText(text)
    ChatEdit_UpdateHeader(chatFrame.editBox);
end

local function ChannelWhisper_OnClick()
    local chatFrame = SELECTED_DOCK_FRAME
    if (not chatFrame) then
        chatFrame = DEFAULT_CHAT_FRAME;
    end
    if arg1 == "LeftButton" then
        local lastTell = ChatEdit_GetLastTellTarget(chatFrame.editBox)
        ChatFrame_OpenChat("/w " .. lastTell, chatFrame)
    else
        if IsAddOnLoaded("wim") then
            -- 检查WIM相关帧是否存在，避免nil错误
            local wimToggleFrame = WIM_Icon_ToggleDropDown and WIM_Icon_ToggleDropDown()
            if wimToggleFrame then
                ToggleFrame(wimToggleFrame)
            else
                -- 备选方案：如果找不到下拉框，尝试直接打开WIM主窗口
                if WIM_MainWindow then
                    ToggleFrame(WIM_MainWindow)
                end
            end
        end
    end
end

-- 修改世界频道按钮逻辑（支持中英文频道名，保留输入文字）
local function ChannelWorld_OnClick()
    local button = arg1
    
    if button == "LeftButton" then
        local chatFrame = SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME
        local channelID, channelName = nil, nil
        
        -- 1. 精确匹配
        for i = 1, 10 do
            local id, name = GetChannelName(i)
            if name then
                local nameLower = string.lower(name)
                if nameLower == "世界" or nameLower == "world" then
                    channelID, channelName = id, name
                    break
                end
            end
        end
        
        -- 2. 前缀匹配（排除防务）
        if not channelID then
            for i = 1, 10 do
                local id, name = GetChannelName(i)
                if name then
                    local nameLower = string.lower(name)
                    if (string.find(nameLower, "^世界") or string.find(nameLower, "^world")) then
                        if not string.find(nameLower, "防务") and not string.find(nameLower, "defense") then
                            channelID, channelName = id, name
                            break
                        end
                    end
                end
            end
        end
        
        if channelID then
            chatFrame.editBox:Show()
            chatFrame.editBox.chatType = "CHANNEL"
            chatFrame.editBox.channelTarget = channelID
            ChatEdit_UpdateHeader(chatFrame.editBox)
        else
            -- 未加入，先尝试加入
            JoinChannelByName("世界", nil, 3)
            JoinChannelByName("世界频道", nil, 3)
            JoinChannelByName("world", nil, 3)
            ChatFrame_OpenChat("/世界 ", chatFrame)
        end
        
    elseif button == "RightButton" then
        -- 右键：离开所有世界频道（排除防务）
        local leftAny = false
        for i = 1, 10 do
            local id, name = GetChannelName(i)
            if name then
                local nameLower = string.lower(name)
                local isWorld = false
                -- 精确匹配或前缀匹配排除防务
                if nameLower == "世界" or nameLower == "world" then
                    isWorld = true
                elseif (string.find(nameLower, "^世界") or string.find(nameLower, "^world")) then
                    if not string.find(nameLower, "防务") and not string.find(nameLower, "defense") then
                        isWorld = true
                    end
                end
                if isWorld then
                    LeaveChannelByName(name)
                    leftAny = true
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00已离开频道: " .. name .. "|r")
                end
            end
        end
        
        if leftAny then
            S_ChatBarDB.leftWorldChannel = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00已离开世界频道，不再自动加入|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00未在任何世界频道中|r")
        end
    end
end

-- 修改中文频道按钮逻辑（保留输入文字）
local function ChannelZhong_OnClick()
    local button = arg1
    local channelName = "世界频道"
    
    if button == "LeftButton" then
        local chatFrame = SELECTED_DOCK_FRAME or DEFAULT_CHAT_FRAME
        local channelID = GetChannelID(channelName)
        if not channelID then
            JoinChannelByName(channelName, nil, 3)
            channelID = GetChannelID(channelName)
        end
        
        if channelID then
            chatFrame.editBox:Show()
            chatFrame.editBox.chatType = "CHANNEL"
            chatFrame.editBox.channelTarget = channelID
            ChatEdit_UpdateHeader(chatFrame.editBox)
        end
    elseif button == "RightButton" then
        local channelID = GetChannelID(channelName)
        if channelID then
            LeaveChannelByName(channelName)
            S_ChatBarDB.leftZhongChannel = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00已离开世界频道，不再自动加入|r")
            return
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00未在世界频道中|r")
    end
end


CreateChatButton("Say", "说", "说", {1,1,1}, function() Channel_OnClick("SAY") end)
CreateChatButton("Yell", "喊", "喊话", {255/255,64/255,64/255}, function() Channel_OnClick("YELL") end)
CreateChatButton("Whisper", "密", "悄悄话", { 240 / 255, 128 / 255, 128 / 255 }, function() ChannelWhisper_OnClick() end)
CreateChatButton("Party", "队", "队伍", {170/255,170/255,255/255}, function() Channel_OnClick("PARTY") end)
CreateChatButton("Guild", "会", "公会", {64/255,255/255,64/255}, function() Channel_OnClick("GUILD") end)
CreateChatButton("Officer", "官", "官员", {64/255,255/255,64/255}, function() Channel_OnClick("OFFICER") end)
CreateChatButton("Raid", "团", "团队", {255/255,127/255,0}, function() 
    local button = arg1
    if button == "LeftButton" then
        -- 左键：切换到团队聊天，保留输入文字
        Channel_OnClick("RAID", false)
    elseif button == "RightButton" then
        -- 右键：切换pfUI团队框架显示
        RunScript("if pfUI_config then if pfUI_config.unitframes.raid.visible==\"1\" then pfUI_config.unitframes.raid.visible=\"0\" else pfUI_config.unitframes.raid.visible=\"1\" end end")
    end
end)
CreateChatButton("RaidWarns", "告", "团队通知", {1,.8,.6}, function() Channel_OnClick("RAID_WARNING") end)
CreateChatButton("Battlefield", "战", "战场频道", {255/255,127/255,0}, function() Channel_OnClick("BATTLEGROUND") end)
CreateChatButton("General", "综", "综合", {1,.6,.5}, ChannelGeneral_OnClick)
CreateChatButton("Trade", "易", "交易频道", {1,.6,.6}, ChannelTrade_OnClick)
CreateChatButton("World", "世", "world频道", {1,.8,.6}, ChannelWorld_OnClick)
CreateChatButton("Zhong", "世", "世界频道", {1,.9,.7}, ChannelZhong_OnClick)
CreateChatButton("HC", "硬", "硬核", {230/255,204/255,100/255}, function() ChatFrame_OpenChat("/h ", chatFrame) end)
CreateChatButton("Meeting", "集", "集合石", {255/255,165/255,0}, ChannelMeeting_OnClick)
CreateChatButton("RaidProgress", "副", "副本CD", {1, 1, 0}, ChannelRaidProgress_OnClick)
CreateChatButton("XyTracker", "愿", "许愿", {147/255,112/255,219/255}, ChannelXyTracker_OnClick)
-- 为“愿”按钮增加右键打开拍卖模块的功能
local xyBtn = buttonFrames["XyTracker"]
if xyBtn then
    -- 注册左右键点击
    xyBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    -- 覆盖点击处理
    xyBtn:SetScript("OnClick", function()
        if arg1 == "LeftButton" then
            -- 原有左键逻辑：切换许愿窗口
            if XyTrackerFrame then
                if not XyTrackerFrame:IsShown() then
                    XyTracker_ShowXyWindow()
                else
                    XyTracker_HideXyWindow()
                end
            end
        elseif arg1 == "RightButton" then
            -- 右键：模拟点击拍卖模块按钮
            local auctionBtn = getglobal("XyTrackerFrameAuctionButton")
            if auctionBtn then
                auctionBtn:Click()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000拍卖模块按钮未找到，请确认 XyTracker 已加载|r")
            end
        end
    end)
    -- 更新悬停提示，告知右键功能
    xyBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 6)
        GameTooltip:AddLine("许愿")
        GameTooltip:Show()
    end)
end
CreateChatButton("AtlasLoot", "落", "掉落查询", {180/255,160/255,230/255}, AtlasLoot_OnClick)
CreateChatButton("SuperMacro", "宏", "宏设置", { 120 / 255, 160 / 255, 230 / 255 }, SuperMacro_OnClick)
CreateChatButton("ActionBarProfiles", "动", "动作条配置", {200/255,160/255,230/255}, ActionBarProfiles_OnClick)
CreateChatButton("Outfitter", "装", "一键换装 |cFF00CCFF左键|r 换装菜单 / |cFF00CCFF右键|r 开关快速换装栏", {200/255, 180/255, 100/255}, Outfitter_OnClick)
CreateChatButton("TrinketMenu", "饰", "饰品设置", {120/255,200/255,200/255}, TrinketMenu_OnClick)
CreateChatButton("RaidCheck", "查", "检查Buff及药剂", {1, 1, 0},RaidCheck_OnClick)
CreateChatButton("SpiritSenseRec", "灵", "灵应录", {60/255,160/255,250/255}, SpiritSenseRec_OnClick)
CreateChatButton("BetterCharacterStats", "属", "属性面板", {180/255,160/255,230/255}, BetterCharacterStats_OnClick)
CreateChatButton("AutoMarker", "自", "自动标记（AutoMarker）", {60/255,160/255,250/255}, AutoMarker_OnClick)
CreateChatButton("SimpleRaidTargetIcons", "标", "标记助手设置（SimpleRaidTargetIcons）", {1, .85, .35}, function()
    if Banana_Toggle and BananaConfigFrame then
        Banana_Toggle()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000请先启用 SimpleRaidTargetIcons 标记助手。|r")
    end
end)
CreateChatButton("Automatonex", "箱", "自动工具箱", {1,.8,.6}, Automatonex_OnClick)
CreateChatButton("SilverDragonRadar", "精", "稀有精英追踪", { 255 / 255, 215 / 255, 0 }, ChannelSilverDragonRadar_OnClick)

local function ChannelCatPotion_OnClick()
    if arg1 == "RightButton" then
        if CatPotionAddon and CatPotionAddon.ShowSettings then
            if CatPotionAddon.HidePotionProfileMenus then CatPotionAddon.HidePotionProfileMenus() end
            GameTooltip:Hide()
            CatPotionAddon.ShowSettings()
            return
        end
    elseif arg1 == "LeftButton" then
        if CatPotionAddon and CatPotionAddon.TogglePotionWindowPicker then
            CatPotionAddon.TogglePotionWindowPicker(this)
            return
        end
    else
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 CatPotion 药剂窗口选择功能，请确认插件已加载并更新|r")
end

CreateChatButton("CatPotion", "药", "药剂：左键选择打开/关闭具体窗口，右键打开设置", { 80 / 255, 220 / 255, 120 / 255 }, ChannelCatPotion_OnClick)
local function ChannelHyx_OnClick()
    GameTooltip:Hide()
    if arg1 == "LeftButton" and XinDispel and XinDispel.ToggleLists then
        XinDispel.ToggleLists()
    elseif arg1 == "RightButton" and XinSettingFrame then
        XinSettingFrame:Show()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 hyx 一键驱散，请确认插件已加载并更新|r")
    end
end
CreateChatButton("hyx", "驱", "一键驱散：左键显示/隐藏驱散列表，右键打开设置", { 80 / 255, 200 / 255, 255 / 255 }, ChannelHyx_OnClick)
CreateChatButton("ReadyCheck", "位", "就位确认", { 100 / 255, 230 / 255, 100 / 255 }, ChannelReadyCheck_OnClick)
CreateChatButton("Countdown", "倒", "倒计时（左键开始/取消，右键开始Roll点）", { 255 / 255, 200 / 255, 80 / 255 }, ChannelCountdown_OnClick)
CreateChatButton("Tracking", "追", "追踪设置", { 60 / 255, 160 / 255, 250 / 255 }, TrackingButton_OnClick)

-- 应用当前显示模式 (文字/色块)
ApplyDisplayMode()

-- 创建表情按钮（使用图标，类似Roll按钮）
local emoteButton = CreateFrame("Button", "ChannelEmote", chatbar)
emoteButton:SetWidth(20)
emoteButton:SetHeight(20)
emoteButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

emoteButton.t = emoteButton:CreateTexture()
emoteButton.t:SetPoint("TOP", emoteButton, "TOP", 0, 2)  -- 向上移动2像素
emoteButton.t:SetPoint("BOTTOM", emoteButton, "BOTTOM", 0, 2)  -- 向上移动2像素
emoteButton.t:SetPoint("LEFT", emoteButton, "LEFT")
emoteButton.t:SetPoint("RIGHT", emoteButton, "RIGHT")
emoteButton.t:SetTexture("Interface\\AddOns\\S_ChatBar\\Friends") -- 使用Friends.tga图标

emoteButton:SetScript("OnClick", ChannelEmote_OnClick)
emoteButton:SetScript("OnEnter", function() 
    GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 6)
    GameTooltip:AddLine("表情菜单")
    GameTooltip:Show()
end)
emoteButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

buttonFrames["Emote"] = emoteButton

-- Roll按钮和配置菜单
local roll = CreateFrame("Button", "rollMacro", chatbar)
roll:SetWidth(20)
roll:SetHeight(20)
roll:SetPoint("LEFT", chatbar, "RIGHT", 2, 0)
roll:RegisterForClicks("LeftButtonUp", "RightButtonUp")

roll.t = roll:CreateTexture()
roll.t:SetAllPoints()
roll.t:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")

roll:SetScript("OnClick", function()
    local button = arg1
    if button == "LeftButton" then
        DEFAULT_CHAT_FRAME.editBox:SetText("/roll")
        ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox,0)
    else
        ToggleDropDownMenu(1, nil, S_ChatBar_Menu, this:GetName(), 0, 0) -- 修正锚点参数
    end
end)
roll:SetScript("OnEnter", function() 
    GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 6)
    GameTooltip:AddLine("Roll")
    GameTooltip:AddLine("按住|cFF00CCFF Shift |r可移动聊天快捷按钮", 1, 1, 0)
    GameTooltip:AddLine("点击|cFF00CCFF 右键 |r可选择关闭/显示部分快捷按钮", 1, 1, 0)
    GameTooltip:Show()
end)
roll:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)
roll:SetScript("OnDragStart", function()
    if IsShiftKeyDown() then
        chatbar:StartMoving()
    end
end)
roll:SetScript("OnDragStop", function()
    chatbar:StopMovingOrSizing()
end)
roll:RegisterForDrag("LeftButton")

-- 修改 AtlasLoot 按钮的鼠标提示，根据加载的插件动态显示
local atlasButton = buttonFrames["AtlasLoot"]
if atlasButton then
    atlasButton:SetScript("OnEnter", function()
        local hasAtlas = IsAddOnLoaded("AtlasLoot")
        local hasIJ = IsAddOnLoaded("InstanceJournal")
        GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 6)
        if hasAtlas and hasIJ then
            GameTooltip:AddLine("左键 掉落查询，右键 副本手册")
        elseif hasAtlas then
            GameTooltip:AddLine("掉落查询")
        elseif hasIJ then
            GameTooltip:AddLine("副本手册")
        else
            GameTooltip:AddLine("未加载 AtlasLoot 或 InstanceJournal")
        end
        GameTooltip:Show()
    end)
end

--是否乌龟服
local function IsTurtleServer()
    local _, build = GetBuildInfo()
    if build and tonumber(build) > 6141 then
        return true
    end
    return false
end


-- 创建配置菜单
S_ChatBar_Menu = CreateFrame("Frame", "S_ChatBar_Menu", UIParent, "UIDropDownMenuTemplate")
UIDropDownMenu_Initialize(S_ChatBar_Menu, function()
    -- 显示模式切换 (文字 / 色块)
    UIDropDownMenu_AddButton {
        text = "显示模式: " .. (S_ChatBarDB.displayMode == "color" and "色块" or "文字"),
        notCheckable = true,
        func = function()
            S_ChatBarDB.displayMode = (S_ChatBarDB.displayMode == "color") and "text" or "color"
            ApplyDisplayMode()
            CloseDropDownMenus()
            ToggleDropDownMenu(1, nil, S_ChatBar_Menu, "cursor", 0, 0)
        end
    }
    -- 色块尺寸 (宽 x 高), 提示可用 /cbw /cbh 调整
    UIDropDownMenu_AddButton {
        text = string.format("色块尺寸: %dx%d  (/cbw /cbh)", S_ChatBarDB.colorBarWidth or 45, S_ChatBarDB.colorBarHeight or 20),
        notCheckable = true,
        func = function()
            CloseDropDownMenus()
            ToggleDropDownMenu(1, nil, S_ChatBar_Menu, "cursor", 0, 0)
        end
    }
    -- Roll点仅统计团队成员开关
    UIDropDownMenu_AddButton {
        text = "Roll点仅统计团队/队伍成员",
        checked = S_ChatBarDB.rollGroupOnly,
        func = function()
            S_ChatBarDB.rollGroupOnly = not S_ChatBarDB.rollGroupOnly
            CloseDropDownMenus()
            ToggleDropDownMenu(1, nil, S_ChatBar_Menu, "cursor", 0, 0)
        end
    }
    -- Roll点统计最高的前几名（点击在常用档位间循环切换）
    local rollTopN = S_ChatBarDB.RollTopN or 5
    UIDropDownMenu_AddButton {
        text = string.format("统计前 %d 名  (/cbrolltop <N>)", rollTopN),
        notCheckable = true,
        func = function()
            local presets = { 3, 5, 8, 10 }
            local cur = S_ChatBarDB.RollTopN or 5
            local idx = 1
            for i, v in ipairs(presets) do
                if v == cur then idx = i end
            end
            idx = idx + 1
            if idx > table.getn(presets) then idx = 1 end
            S_ChatBarDB.RollTopN = presets[idx]
            CloseDropDownMenus()
            ToggleDropDownMenu(1, nil, S_ChatBar_Menu, "cursor", 0, 0)
        end
    }
    UIDropDownMenu_AddButton {
        text = "显示频道按钮",
        isTitle = true,
        notCheckable = true
    }
    for k, btnName in ipairs(BUTTON_ORDER) do
        if buttonFrames[btnName] then
            -- 判断对应名字的插件是否加载，如果没有加载，不显示此项的菜单选项
            local shouldShow = false
            local isPluginButton = k >= 15  -- 从第15个按钮开始是插件按钮
            
            if k <= 13 then
                -- 前13个是基础聊天按钮，总是显示
                shouldShow = true
            elseif k == 14 and IsTurtleServer() then
                -- 第14个按钮(HC)只在乌龟服显示
                shouldShow = true
            elseif isPluginButton then
                -- 插件按钮：如果插件已加载或按钮名称为Emote/Tracking则显示
                if btnName == "Emote" or btnName == "Tracking" or btnName == "ReadyCheck" or btnName == "Countdown" then
                    shouldShow = true  -- Emote、Tracking、ReadyCheck和Countdown总是显示
                elseif btnName == "AtlasLoot" then
                    -- 特殊处理：AtlasLoot或InstanceJournal任一加载即显示
                    if IsAddOnLoaded("AtlasLoot") or IsAddOnLoaded("InstanceJournal") then
                        shouldShow = true
                    end
                elseif IsAddOnLoaded(btnName) then
                    shouldShow = true
                end
            end
            
            if shouldShow then
                local displayText = ""
                local r, g, b = 1, 1, 1  -- 默认白色
                
                -- 获取按钮显示文本和颜色
                if buttonFrames[btnName].text then
                    displayText = buttonFrames[btnName].text:GetText() or btnName
                    r, g, b = buttonFrames[btnName].text:GetTextColor()
                else
                    -- 对于没有文本的按钮（如表情按钮），使用固定显示
                    if btnName == "Emote" then
                        displayText = "表"
                        r, g, b = 200/255, 230/255, 100/255  -- 使用表情按钮的颜色
                    else
                        displayText = btnName
                    end
                end
                
                -- 使用闭包捕获当前按钮名称
                local currentBtnName = btnName
                UIDropDownMenu_AddButton {
                    text = displayText,
                    colorCode = string.format("|cFF%02x%02x%02x",
                        math.floor(r * 255 + 0.5),
                        math.floor(g * 255 + 0.5),
                        math.floor(b * 255 + 0.5)),
                    checked = S_ChatBarDB.buttons[currentBtnName],
                    func = function()
                        -- 切换状态并强制立即保存
                        S_ChatBarDB.buttons[currentBtnName] = not S_ChatBarDB.buttons[currentBtnName]
                        UpdateButtonLayout()
                        CloseDropDownMenus()
                        -- 强制刷新菜单
                        ToggleDropDownMenu(1, nil, S_ChatBar_Menu, "cursor", 0, 0)
                    end
                }
            end
        end
    end
end, "MENU")
