-- =============== 拍卖模块 (xy_auction.lua) ===============
-- 依赖: paipaiDB (SavedVariable)
-- 功能: 团队拍卖系统, 包含拍卖界面、品质过滤、快拍列表、倒计时、拍卖通信
-- 指令: 常驻快捷按钮调用（无斜杠命令）
-- ====================================================

-- paipai.lua - 拍卖插件 for 魔兽世界1.12
-- 使用:
--   - Shift+左键: 输入物品链接
--   - 快拍按钮: 快速选择未拍卖物品进行拍卖
--   - 数秒按钮: 提前结束当前拍卖
--   - 界面按钮: 打开/关闭完整拍卖界面
--   - 右键拖动: 移动快拍界面和三个按钮的位置，重载后自动记忆
--   - 品质筛选: 白/绿/蓝/紫/橙五档，勾选状态重载后记忆
--   - 已拍筛选: 显示/隐藏已拍卖物品，勾选状态重载后记忆
--   - 拍卖列表: 点击物品自动填入并开始25秒拍卖，自动刷新已拍状态

paipaiDB = paipaiDB or { quality = {}, showSold = true, quickFramePos = nil, auctionResults = {} }  -- SavedVariables，WoW 在文件加载前注入

-- ========== 屏幕分辨率适配：以1920x1080为设计基准 ==========
-- 2K(2560x1440) 多是 VanillaFixes 类模组适配出来的，gxResolution 的格式/取值无法保证（很可能解析不出高度）。
-- 因此双保险：优先解析 gxResolution 高度；解析不出时用 GetScreenHeight()（虚拟高度）兜底。
-- 任一信号显示超过 1080p（>1300）即视为 2K，套用 2K 专用尺寸 x1.333。1080p 及以下走原逻辑。
local xyRes = GetCVar("gxResolution") or ""
local _, _, _, xyResH = string.find(xyRes, "(%d+)[xX%*](%d+)")
xyResH = tonumber(xyResH)
local xyScrH = GetScreenHeight() or 1080
if (xyResH and xyResH > 1080) or xyScrH > 1300 then
    XyScreenScale = 1440 / 1080  -- 2K 专用：设计尺寸 x 1.333
else
    XyScreenScale = xyScrH / 1080  -- 原逻辑，1080p 及以下保持不变
end

-- 拍卖结算结果队列 {winner=名字, itemLink=链接}，供增强拾取菜单"按拍卖分配"按物品匹配，最多保留20条
-- 存入 SavedVariables（paipaiDB.auctionResults），reload 后记录不丢失
XyLastAuctionResults = paipaiDB.auctionResults
if not XyLastAuctionResults then
    XyLastAuctionResults = {}
    paipaiDB.auctionResults = XyLastAuctionResults
end

local auctionAlertFrame = nil
local auctionAlertFrame2 = nil  -- 拍卖界面副本（位于原界面下方）

local bidData = {}  -- 记录出分: {name=xxx, score=xxx}
local directRollMode = false  -- 直接roll模式（跳过出分阶段），结算时不播报消费分数

local pMarkedItems = pMarkedItems or {}  -- P标记物品列表，拍这些物品时Frame1始终关闭
local auctionActive = false  -- 当前是否有拍卖进行中
local rollNames = {}  -- 需要roll点的玩家列表
local rollData = {}
local paiGetUnsoldItem  -- 前向声明，稍后定义（因 PlayLastItemSound 内联调用位置早于定义处）
local myRoll = nil  -- 存储自己的roll点数  -- 记录roll点结果: {name=xxx, roll=数字}
local wishBidTimer  -- 自动许愿出分定时器（拍卖开始后1秒自动出5分）
-- 美女播报声音节流：1秒内最多播放一个声音，防止重复触发
local _lastVoiceTime = 0
local function PlayVoice(path)
    local t = GetTime()
    if t - _lastVoiceTime >= 1 then
        _lastVoiceTime = t
        PlaySoundFile(path)
    end
end
-- 延迟播放声音，不受全局节流限制（用于最后一件装备的 xykf.ogg）
-- 互斥保护：同一时刻只允许一个延迟播放待触发；且与上次实际播放间隔>=3秒。
-- 防止拍卖结算的多个路径/多帧重复触发 PlayDelayedVoice，导致同一声音叠加播放产生"回声"。
local _pendingDelayedVoice = false
local _lastDelayedVoicePlay = 0
local function PlayDelayedVoice(path, delay)
    if _pendingDelayedVoice then return end  -- 已有待触发的延迟播放，忽略本次（只响一次）
    if GetTime() - _lastDelayedVoicePlay < 3 then return end  -- 3秒内刚播放过，忽略本次
    _pendingDelayedVoice = true
    local f = CreateFrame("Frame")
    f.startTime = GetTime()
    f:Hide()
    f:SetScript("OnUpdate", function()
        if GetTime() - this.startTime >= delay then
            _pendingDelayedVoice = false
            _lastDelayedVoicePlay = GetTime()
            PlaySoundFile(path)
            this:Hide()
        end
    end)
    f:Show()
end
-- pai浮标相关（forward声明，稍后赋值）
local XyPaiStopIcon, XyPaiStopLabel, XyPaiStopTimeText, XyPaiBidStopIcon, paiFloatLabel

local loothog_players = {}  -- 记录本轮已roll的玩家，只计第一个（类LootHog）
local preRollData = {}  -- 出分阶段玩家提前roll的记录，进入roll阶段时筛选采纳
local auctionSender = nil  -- 当前拍卖的发起者名字
local cnNum = {"零","一","二","三","四","五"}

-- ========== UTF-8 中文名单安全传输（hex 编码，纯 ASCII，绕过 SendAddonMessage 中文损坏） ==========
function XyHexEncode(s)
    if not s or s == "" then return "" end
    local t = {}
    for i = 1, string.len(s) do
        t[i] = string.format("%02x", string.byte(s, i))
    end
    return table.concat(t)
end
function XyHexDecode(s)
    if not s or s == "" then return "" end
    local t = {}
    for i = 1, string.len(s), 2 do
        local b = tonumber(string.sub(s, i, i + 1), 16)
        if b then table.insert(t, string.char(b)) end
    end
    return table.concat(t)
end

local function IsRaidLeaderOrAssistant()
    if IsRaidLeader() == 1 then return true end
    local n = GetNumRaidMembers()
    if n == 0 then return false end
    local myName = UnitName("player")
    for i = 1, n do
        local name, rank = GetRaidRosterInfo(i)
        if name == myName and rank >= 1 then
            return true
        end
    end
    return false
end

-- 获取当前最高出分
local function GetHighestBidScore()
    local highestBid = 0
    for i = 1, table.getn(bidData) do
        if bidData[i].score > highestBid then
            highestBid = bidData[i].score
        end
    end
    return highestBid
end

-- 获取玩家当前DKP
local function GetMyDkp()
    local player = UnitName("player")
    if XyArray then
        for i, data in pairs(XyArray) do
            if data["name"] == player then
                return tonumber(data["dkp"]) or 0
            end
        end
    end
    return 0
end

-- 检查玩家是否拥有活跃许愿（非未许愿、非已完成）
local function HasActiveWish()
    local player = UnitName("player")
    if XyArray then
        for i, data in pairs(XyArray) do
            if data["name"] == player then
                local xy = data["xy"] or ""
                if xy ~= "---未许愿---" and xy ~= "" and xy ~= "|cFF00FFFF已完成许愿|r" then
                    return true
                end
                return false
            end
        end
    end
    return false
end

-- 检查当前拍卖物品是否是玩家许愿的装备（许愿有效且装备匹配）
local function IsCurrentItemMyWish(playerName)
    if not XyArray or not timerFrame.currentAuctionLink then return false end
    local itemName = string.match(timerFrame.currentAuctionLink, "|h%[(.-)%]|h")
    if not itemName then return false end
    for i, data in pairs(XyArray) do
        if data["name"] == playerName then
            local xy = data["xy"] or ""
            -- xy非空、非未许愿、非已完成许愿，且精准许愿了当前拍卖物品名（全等比较，不做子串包含）
            if xy ~= "" and xy ~= "---未许愿---" and xy ~= "|cFF00FFFF已完成许愿|r" then
                return XYT_WishContainsItem(xy, itemName)
            end
            return false
        end
    end
    return false
end

-- 清除当前拍卖物品的P标记（有人出分时调用）
local function ClearPMarkForCurrentItem()
    if not pMarkedItems or not timerFrame.currentAuctionLink then return end
    local removed = false
    for i = table.getn(pMarkedItems), 1, -1 do
        if pMarkedItems[i] == timerFrame.currentAuctionLink then
            table.remove(pMarkedItems, i)
            removed = true
        end
    end
    if removed then
        paipaiDB.pMarkedItems = pMarkedItems
        -- 恢复显示Frame1
        if auctionAlertFrame then auctionAlertFrame:Show() end
        -- 清除P标记后隐藏Frame2
        if auctionAlertFrame2 then
            auctionAlertFrame2:Hide()
            if auctionAlertFrame2.showFrame1Btn then auctionAlertFrame2.showFrame1Btn:Hide() end
        end
    end
end

-- 检查当前拍卖物品是否被P标记
function IsCurrentItemPMarked()
    if not pMarkedItems or not timerFrame.currentAuctionLink then return false end
    local _, _, itemName = string.find(timerFrame.currentAuctionLink, "|h%[(.-)%]|h")
    if not itemName then return false end
    for i = 1, table.getn(pMarkedItems) do
        local _, _, pName = string.find(pMarkedItems[i], "|h%[(.-)%]|h")
        if pName and pName == itemName then return true end
    end
    return false
end

-- Roll阶段按钮配置：隐藏出分/P按钮，放大Roll按钮居中
function SetRollPhaseButtons(enabled)
    if not auctionAlertFrame then return end
    if enabled then
        if auctionAlertFrame.bid1Btn then auctionAlertFrame.bid1Btn:Hide() end
        if auctionAlertFrame.bid2Btn then auctionAlertFrame.bid2Btn:Hide() end
        if auctionAlertFrame.bid3Btn then auctionAlertFrame.bid3Btn:Hide() end
        if auctionAlertFrame.bid4Btn then auctionAlertFrame.bid4Btn:Hide() end
        if auctionAlertFrame.bid9Btn then auctionAlertFrame.bid9Btn:Hide() end
        if auctionAlertFrame.passBtn then auctionAlertFrame.passBtn:Hide() end
        if auctionAlertFrame.bidBtn then
            auctionAlertFrame.bidBtn._hasRolled = false  -- 新roll阶段重置
            auctionAlertFrame.bidBtn:SetWidth(208)
            auctionAlertFrame.bidBtn:SetHeight(36)
            auctionAlertFrame.bidBtn:SetText("点我开Roll")
            auctionAlertFrame.bidBtn:ClearAllPoints()
            auctionAlertFrame.bidBtn:SetPoint("CENTER", auctionAlertFrame, "CENTER", 0, -36)
            auctionAlertFrame.bidBtn:Show()
        end
    else
        if auctionAlertFrame.bid1Btn then auctionAlertFrame.bid1Btn:Show() end
        if auctionAlertFrame.bid2Btn then auctionAlertFrame.bid2Btn:Show() end
        if auctionAlertFrame.bid3Btn then auctionAlertFrame.bid3Btn:Show() end
        if auctionAlertFrame.bid4Btn then auctionAlertFrame.bid4Btn:Show() end
        if auctionAlertFrame.bid9Btn then auctionAlertFrame.bid9Btn:Show() end
        if auctionAlertFrame.passBtn then auctionAlertFrame.passBtn:Show() end
        if auctionAlertFrame.bidBtn then auctionAlertFrame.bidBtn:Hide() end
    end
end

-- 计算并返回最高出分文本
local function GetHighestBidText()
    if table.getn(bidData) == 0 then
        return "暂无出分"
    end
    -- 找出最高分
    local maxScore = 0
    local maxPlayers = {}
    for i = 1, table.getn(bidData) do
        local score = bidData[i].score
        if score > maxScore then
            maxScore = score
            maxPlayers = {bidData[i].name}
        elseif score == maxScore then
            table.insert(maxPlayers, bidData[i].name)
        end
    end
    -- 生成显示文本
    local result
    if table.getn(maxPlayers) == 1 then
        result = "最高出分: " .. maxPlayers[1] .. " (" .. maxScore .. "分)"
    else
        result = "最高出分: " .. table.getn(maxPlayers) .. "人出" .. maxScore .. "分"
    end
    local myScore = nil; for i = 1, table.getn(bidData) do if bidData[i].name == UnitName("player") then myScore = bidData[i].score; break end end
    if myScore then return result .. "  \124cFF00FF00我:" .. myScore .. "分\124r" else return result .. "  \124cFF888888我:未出分\124r" end
end

-- 计算并返回最高roll文本

-- 数字转汉字（0-99）
local function NumberToChinese(num)
    if num == 0 then return "零" end
    local cn = {"", "一", "二", "三", "四", "五", "六", "七", "八", "九"}
    local s = ""
    local tens = math.floor(num / 10)
    local ones = math.mod(num, 10)
    if tens > 0 then
        if tens == 1 then
            s = s .. "十"
        else
            s = s .. cn[tens+1] .. "十"
        end
    end
    if ones > 0 then
        s = s .. cn[ones+1]
    end
    return s
end

local function GetHighestRollText()
    if table.getn(rollData) == 0 then
        return ""
    end
    local maxRoll = 0
    local maxPlayers = {}
    for i = 1, table.getn(rollData) do
        local roll = rollData[i].roll
        if roll > maxRoll then
            maxRoll = roll
            maxPlayers = {rollData[i].name}
        elseif roll == maxRoll then
            table.insert(maxPlayers, rollData[i].name)
        end
    end
    if table.getn(maxPlayers) == 1 then
        return "最高roll: " .. maxPlayers[1] .. " (" .. maxRoll .. "点)"
    else
        return "最高roll: " .. table.getn(maxPlayers) .. "人roll " .. maxRoll .. "点"
    end
end

-- 更新roll显示
local function UpdateRollText()
    local text = GetHighestRollText()
    if myRoll then
        if text ~= "" then
            text = text .. "  我:" .. myRoll .. "点"
        else
            text = "我:" .. myRoll .. "点"
        end
    end
    if auctionAlertFrame and auctionAlertFrame:IsVisible() and auctionAlertFrame.rollText then
        auctionAlertFrame.rollText:SetText(text)
    end
    if auctionAlertFrame3 and auctionAlertFrame3.rollText then
        auctionAlertFrame3.rollText:SetText(text)
    end
end

-- 更新出分显示
local function UpdateBidText()
    local text = GetHighestBidText()
    if auctionAlertFrame and auctionAlertFrame:IsVisible() and auctionAlertFrame.bidText then
        auctionAlertFrame.bidText:SetText(text)
    end
    if auctionAlertFrame3 and auctionAlertFrame3.bidText then
        auctionAlertFrame3.bidText:SetText(text)
    end
end

local function GetItemIconFromLink(link)
    if not link or link == "" then return "", nil end
    local _, _, id = string.find(link, "item:(%d+):")
    if not id then return "", nil end
    local numId = tonumber(id)
    local itemString = "item:"..numId..":0:0:0"
    local _, _, _, _, _, _, _, _, icon = GetItemInfo(itemString)
    if icon and icon ~= "" then
        return icon, numId
    end
    return "", numId
end

-- auctionAlertFrame倒计时OnUpdate（可重复绑定的命名函数，供ShowAuctionAlert和PP_AUCTION_ROLL复用）
local function UpdateAuctionAlert()
    if not auctionAlertFrame or not auctionAlertFrame:IsVisible() then return end
    -- 图标重试：物品信息异步加载后刷新
    if auctionAlertFrame.icon and auctionAlertFrame.icon.itemLink then
        local icoTex, _ = GetItemIconFromLink(auctionAlertFrame.icon.itemLink)
        if icoTex and icoTex ~= "" then
            auctionAlertFrame.icon:SetNormalTexture(icoTex)
            auctionAlertFrame.icon.itemLink = nil
        end
    end
    local elapsed = GetTime() - auctionAlertFrame.startTime
    local remaining = auctionAlertFrame.totalTime - elapsed
    if remaining <= 0 then
        remaining = 0
        auctionAlertFrame:SetScript("OnUpdate", nil)
    end
    auctionAlertFrame.progressBar:SetValue(remaining)
    auctionAlertFrame.progressBar.timeText:SetText(string.format("%d", remaining + 0.5))
    if remaining <= 5 then
        auctionAlertFrame.progressBar:SetStatusBarColor(1, 0.2, 0.2)
    elseif remaining <= 10 then
        auctionAlertFrame.progressBar:SetStatusBarColor(1, 0.8, 0.2)
    else
        auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
    end
    -- bidText和rollText刷新（关键：恢复OnUpdate后继续更新文字）
    UpdateBidText()
    UpdateRollText()
end

local function ShowAuctionAlert(link, sender)
 if auctionDismissed then return end
    if not link or link == "" then return end
    -- 每次发起拍卖统一恢复出分布局：覆盖"直接roll结算state=5停留期发起新拍卖"时
    -- 界面残留roll布局（大Roll按钮）的场景，从源头杜绝下一次拍卖变成roll界面
    SetRollPhaseButtons(false)
    directRollMode = false  -- 默认按正常出分流程，直接roll入口会重新置true
    auctionSender = sender  -- 记录发起者
    -- 清空出分记录，标记拍卖开始
    bidData = {}
    rollData = {}
    myRoll = nil  -- 重置自己的roll
    loothog_players = {}
    preRollData = {}  -- 清空出分阶段预收集的roll
    auctionActive = true


    -- 允许自己看到自己发起的拍卖
    if not auctionAlertFrame then
        auctionAlertFrame = CreateFrame("Frame", nil, UIParent)
        auctionAlertFrame:SetWidth(360)
        auctionAlertFrame:SetHeight(195)
        auctionAlertFrame:SetScale(XyScreenScale)
        auctionAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        auctionAlertFrame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32,
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        auctionAlertFrame:SetFrameStrata("HIGH")
        auctionAlertFrame:Hide()
 auctionAlertFrame:SetMovable(true)
 auctionAlertFrame:EnableMouse(true)
 auctionAlertFrame:SetScript("OnMouseDown", function()
 if arg1 == "RightButton" then auctionAlertFrame:StartMoving() end
 end)
 auctionAlertFrame:SetScript("OnMouseUp", function()
 if arg1 == "RightButton" then
 auctionAlertFrame:StopMovingOrSizing()
 local point, _, relPoint, x, y = auctionAlertFrame:GetPoint()
 paipaiDB.alertPos = { point = point, relPoint = relPoint, x = x, y = y }
 end
 end)

-- 右上角关闭按钮
 auctionAlertFrame.closeBtn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelCloseButton")
 auctionAlertFrame.closeBtn:SetPoint("TOPRIGHT", -3, -3)
 auctionAlertFrame.closeBtn:SetScript("OnClick", function()
 if auctionAlertFrame then auctionAlertFrame:Hide() end
 if auctionAlertFrame2 then
 auctionAlertFrame2:Show()
 if auctionAlertFrame2.showFrame1Btn then auctionAlertFrame2.showFrame1Btn:Show() end
 end
 if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
    PlayVoice("Interface\\AddOns\\XyTracker\\voice\\jmgb.ogg")
 end
end)

        -- 缩放按钮（缩小、放大），位于关闭按钮左侧，排序为：缩小、放大、关闭
        auctionAlertFrame._scaleStep = auctionAlertFrame._scaleStep or 0  -- 0=100%，范围 -5(50%) ~ +5(150%)，步进10%
        local function applyAuctionScale()
            auctionAlertFrame:SetScale(XyScreenScale * (10 + auctionAlertFrame._scaleStep) / 10)
            -- 每次缩放后重置 Frame1 位置到屏幕中央默认位置
            auctionAlertFrame:ClearAllPoints()
            auctionAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
        end

        -- 放大按钮（+）
        auctionAlertFrame.zoomInBtn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.zoomInBtn:SetWidth(52)
        auctionAlertFrame.zoomInBtn:SetHeight(20)
        auctionAlertFrame.zoomInBtn:SetPoint("RIGHT", auctionAlertFrame.closeBtn, "LEFT", -2, 0)
        auctionAlertFrame.zoomInBtn:SetText("放大+")
        auctionAlertFrame.zoomInBtn:SetScript("OnClick", function()
            if auctionAlertFrame._scaleStep >= 5 then return end
            auctionAlertFrame._scaleStep = auctionAlertFrame._scaleStep + 1
            applyAuctionScale()
        end)

        -- 缩小按钮（-）
        auctionAlertFrame.zoomOutBtn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.zoomOutBtn:SetWidth(52)
        auctionAlertFrame.zoomOutBtn:SetHeight(20)
        auctionAlertFrame.zoomOutBtn:SetPoint("RIGHT", auctionAlertFrame.zoomInBtn, "LEFT", -2, 0)
        auctionAlertFrame.zoomOutBtn:SetText("缩小-")
        auctionAlertFrame.zoomOutBtn:SetScript("OnClick", function()
            if auctionAlertFrame._scaleStep <= -5 then return end
            auctionAlertFrame._scaleStep = auctionAlertFrame._scaleStep - 1
            applyAuctionScale()
        end)

        -- 左上角复选框：美女播报
        auctionAlertFrame.voiceCheck = CreateFrame("CheckButton", "XyPaiVoiceCheck", auctionAlertFrame, "UICheckButtonTemplate")
        auctionAlertFrame.voiceCheck:SetPoint("TOPLEFT", 8, -8)
        auctionAlertFrame.voiceCheck:SetScale(0.9)
        _G["XyPaiVoiceCheckText"]:SetText("美女播报")
        _G["XyPaiVoiceCheckText"]:SetTextColor(0.9, 0.7, 1.0)
        -- 恢复上次勾选状态
        if paipaiDB.voiceEnabled then
            auctionAlertFrame.voiceCheck:SetChecked(true)
        end
        auctionAlertFrame.voiceCheck:SetScript("OnClick", function()
            paipaiDB.voiceEnabled = this:GetChecked() and true or nil
        end)

        auctionAlertFrame.titleText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        auctionAlertFrame.titleText:SetPoint("TOP", 0, -15)
        auctionAlertFrame.hintText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        auctionAlertFrame.hintText:SetPoint("TOP", auctionAlertFrame.titleText, "BOTTOM", 0, -8)
        auctionAlertFrame.hintText:SetTextColor(0.8, 0.8, 0.8)
        -- 最高出分显示（放在hintText下方）
        auctionAlertFrame.bidText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        auctionAlertFrame.bidText:SetPoint("TOP", auctionAlertFrame.hintText, "BOTTOM", 0, -4)
        auctionAlertFrame.bidText:SetTextColor(1, 0.82, 0)  -- 金色
        auctionAlertFrame.bidText:SetJustifyH("CENTER")
        auctionAlertFrame.bidText:SetText("")
        -- 最高roll显示
        auctionAlertFrame.rollText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        auctionAlertFrame.rollText:SetPoint("TOP", auctionAlertFrame.bidText, "BOTTOM", 0, -4)
        auctionAlertFrame.rollText:SetJustifyH("CENTER")
        auctionAlertFrame.rollText:SetWidth(340)
        auctionAlertFrame.rollText:SetTextColor(0.5, 1, 0.5)  -- 浅绿色
        auctionAlertFrame.rollText:SetText("")
        -- 图标按钮
        auctionAlertFrame.icon = CreateFrame("Button", nil, auctionAlertFrame)
        auctionAlertFrame.icon:SetWidth(40)
        auctionAlertFrame.icon:SetHeight(40)
        auctionAlertFrame.icon:SetPoint("LEFT", 15, 0)
        auctionAlertFrame.icon:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        auctionAlertFrame.icon:SetScript("OnEnter", function()
            local itemId = auctionAlertFrame.icon.itemId
            if itemId then
                GameTooltip:SetOwner(auctionAlertFrame.icon, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink("item:"..itemId..":0:0:0")
                GameTooltip:Show()
            end
        end)
        auctionAlertFrame.icon:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        auctionAlertFrame.myDkpText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        auctionAlertFrame.myDkpText:SetPoint("TOP", auctionAlertFrame.rollText, "BOTTOM", 0, -4)
        auctionAlertFrame.myDkpText:SetTextColor(0.5, 1, 0.5)
        auctionAlertFrame.myDkpText:SetJustifyH("CENTER")
        auctionAlertFrame.myDkpText:SetText("")
        auctionAlertFrame.myDkpText:SetWidth(330)

        -- ========== 第一行：出分按钮 ==========
        -- 出1分按钮（行首锚点）
        auctionAlertFrame.bid1Btn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.bid1Btn:SetWidth(52)
        auctionAlertFrame.bid1Btn:SetHeight(18)
        auctionAlertFrame.bid1Btn:SetPoint("CENTER", auctionAlertFrame, "CENTER", -116, -36)

        -- 自定义错误提示（bid1Btn上方6px，需在bid1Btn之后创建）
        local bidErrorText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bidErrorText:SetPoint("BOTTOM", auctionAlertFrame, "CENTER", 0, -21)
        bidErrorText:SetTextColor(1, 0, 0, 1)
        bidErrorText:Hide()
        local bidErrorFade = 0
        local function ShowBidError(msg)
            bidErrorText:SetText(msg)
            bidErrorText:Show()
            bidErrorFade = 2  -- 显示2秒
            if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\enheng.ogg")
            end
            if not bidErrorText.ticker then
                bidErrorText.ticker = C_Timer.NewTicker(0.1, function()
                    bidErrorFade = bidErrorFade - 0.1
                    if bidErrorFade <= 0 then
                        bidErrorText:Hide()
                        bidErrorText.ticker:Cancel()
                        bidErrorText.ticker = nil
                    end
                end)
            end
        end
        auctionAlertFrame.bid1Btn:SetText("出1分")
        auctionAlertFrame.bid1Btn:SetScript("OnClick", function()
            local highestBid = GetHighestBidScore()
            if highestBid > 1 then
                ShowBidError("出分失败，已有更高出分！")
                return
            end
            if GetMyDkp() < 1 then
                ShowBidError("分数不足！")
                return
            end
            SendChatMessage("1", "RAID")
            if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\1fen.ogg")
            end
        end)

        -- 出2分按钮
        auctionAlertFrame.bid2Btn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.bid2Btn:SetWidth(52)
        auctionAlertFrame.bid2Btn:SetHeight(18)
        auctionAlertFrame.bid2Btn:SetPoint("LEFT", auctionAlertFrame.bid1Btn, "RIGHT", 6, 0)
        auctionAlertFrame.bid2Btn:SetText("出2分")
        auctionAlertFrame.bid2Btn:SetScript("OnClick", function()
            local highestBid = GetHighestBidScore()
            if highestBid > 2 then
                ShowBidError("出分失败，已有更高出分！")
                return
            end
            if GetMyDkp() < 2 then
                ShowBidError("分数不足！")
                return
            end
            SendChatMessage("2", "RAID")
            if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\2fen.ogg")
            end
        end)

        -- 出3分按钮
        auctionAlertFrame.bid3Btn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.bid3Btn:SetWidth(52)
        auctionAlertFrame.bid3Btn:SetHeight(18)
        auctionAlertFrame.bid3Btn:SetPoint("LEFT", auctionAlertFrame.bid2Btn, "RIGHT", 6, 0)
        auctionAlertFrame.bid3Btn:SetText("出3分")
        auctionAlertFrame.bid3Btn:SetScript("OnClick", function()
            local highestBid = GetHighestBidScore()
            if highestBid > 3 then
                ShowBidError("出分失败，已有更高出分！")
                return
            end
            if GetMyDkp() < 3 then
                ShowBidError("分数不足！")
                return
            end
            SendChatMessage("3", "RAID")
            if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\3fen.ogg")
            end
        end)

        -- 出4分按钮
        auctionAlertFrame.bid4Btn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.bid4Btn:SetWidth(52)
        auctionAlertFrame.bid4Btn:SetHeight(18)
        auctionAlertFrame.bid4Btn:SetPoint("LEFT", auctionAlertFrame.bid3Btn, "RIGHT", 6, 0)
        auctionAlertFrame.bid4Btn:SetText("出4分")
        auctionAlertFrame.bid4Btn:SetScript("OnClick", function()
            local highestBid = GetHighestBidScore()
            if highestBid > 4 then
                ShowBidError("出分失败，已有更高出分！")
                return
            end
            if GetMyDkp() < 4 then
                ShowBidError("分数不足！")
                return
            end
            SendChatMessage("4", "RAID")
            if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\4fen.ogg")
            end
        end)

        -- 出9分按钮（仅未完成许愿+有4分可用）
        auctionAlertFrame.bid9Btn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.bid9Btn:SetWidth(52)
        auctionAlertFrame.bid9Btn:SetHeight(18)
        auctionAlertFrame.bid9Btn:SetPoint("LEFT", auctionAlertFrame.bid4Btn, "RIGHT", 6, 0)
        auctionAlertFrame.bid9Btn:SetText("出9分")
        auctionAlertFrame.bid9Btn:SetScript("OnClick", function()
            local highestBid = GetHighestBidScore()
            if highestBid > 9 then
                ShowBidError("出分失败，已有更高出分！")
                return
            end
            if GetMyDkp() < 4 then
                ShowBidError("分数不足！")
                return
            end
            if not IsCurrentItemMyWish(UnitName("player")) then
                ShowBidError("出分失败，当前拍卖装备不是你的许愿装备！")
                return
            end
            SendChatMessage("9", "RAID")
            if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\9fen.ogg")
            end
        end)

        -- 进度条
        auctionAlertFrame.progressBar = CreateFrame("StatusBar", nil, auctionAlertFrame)
        auctionAlertFrame.progressBar:SetWidth(330)
        auctionAlertFrame.progressBar:SetHeight(6)
        auctionAlertFrame.progressBar:SetPoint("BOTTOM", 0, 6)
        auctionAlertFrame.progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
        auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
        auctionAlertFrame.progressBar:SetValue(10)
        auctionAlertFrame.progressBar.bg = auctionAlertFrame.progressBar:CreateTexture(nil, "BACKGROUND")
        auctionAlertFrame.progressBar.bg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
        auctionAlertFrame.progressBar.bg:SetAllPoints(auctionAlertFrame.progressBar)
        auctionAlertFrame.progressBar.bg:SetVertexColor(0.3, 0.3, 0.3, 0.5)
        auctionAlertFrame.progressBar.timeText = auctionAlertFrame.progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        auctionAlertFrame.progressBar.timeText:SetPoint("CENTER", 0, 0)
        auctionAlertFrame.progressBar.timeText:SetTextColor(1, 1, 1)

        -- ========== 第二行：不要按钮（必须在progressBar之后创建）==========
        -- 不要按钮：标记物品并关闭Frame1（不弹确认框、不输入P）
        auctionAlertFrame.passBtn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.passBtn:SetWidth(260)
        auctionAlertFrame.passBtn:SetHeight(36)
        auctionAlertFrame.passBtn:SetPoint("TOP", auctionAlertFrame, "TOP", 0, -148.5)
        auctionAlertFrame.passBtn:SetText("不要了/关闭界面/跳过这个装备")
        -- 文字放大1.5倍
        local passText = auctionAlertFrame.passBtn:GetFontString()
        if passText then
            local passFont, passSize = passText:GetFont()
            passText:SetFont(passFont, (passSize or 12) * 1.5)
        end
        auctionAlertFrame.passBtn:SetScript("OnClick", function()
            if timerFrame.currentAuctionLink and timerFrame.currentAuctionLink ~= "" then
                if not pMarkedItems then pMarkedItems = {} end
                local exists = false
                for i = 1, table.getn(pMarkedItems) do
                    if pMarkedItems[i] == timerFrame.currentAuctionLink then
                        exists = true
                        break
                    end
                end
                if not exists then
                    table.insert(pMarkedItems, timerFrame.currentAuctionLink)
                    paipaiDB.pMarkedItems = pMarkedItems
                end
                -- 立刻关闭Frame1，显示Frame2
                if auctionAlertFrame then auctionAlertFrame:Hide() end
                if auctionAlertFrame2 then
                    auctionAlertFrame2:Show()
                    if auctionAlertFrame2.showFrame1Btn then auctionAlertFrame2.showFrame1Btn:Show() end
                end
            end
            -- 美女播报：P按钮声音
            if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\jmgb.ogg")
            end
        end)

        -- Roll按钮（仅roll阶段通过SetRollPhaseButtons显示）
        auctionAlertFrame.bidBtn = CreateFrame("Button", nil, auctionAlertFrame, "UIPanelButtonTemplate")
        auctionAlertFrame.bidBtn:SetWidth(52)
        auctionAlertFrame.bidBtn:SetHeight(18)
        auctionAlertFrame.bidBtn:Hide()
        auctionAlertFrame.bidBtn:SetText("Roll")
        auctionAlertFrame.bidBtn._hasRolled = false
        auctionAlertFrame.bidBtn:SetScript("OnClick", function()
            if timerFrame.state ~= 4 then
                UIErrorsFrame:AddMessage("当前非roll点阶段！", 1.0, 0.0, 0.0, 1.0)
                return
            end
            if auctionAlertFrame.bidBtn._hasRolled then
                -- 已经roll过了：提示 + 播放enheng.ogg
                UIErrorsFrame:AddMessage("你已经roll过了哦", 1.0, 0.5, 0.0, 1.0)
                if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                    PlayVoice("Interface\\AddOns\\XyTracker\\voice\\enheng.ogg")
                end
                return
            end
            auctionAlertFrame.bidBtn._hasRolled = true
            RandomRoll(1, 100)
        end)

        -- 提前数秒通知文字（进度条下方）
        auctionAlertFrame.earlyNoticeText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        auctionAlertFrame.earlyNoticeText:SetPoint("TOP", auctionAlertFrame.progressBar, "BOTTOM", 0, -2)
        auctionAlertFrame.earlyNoticeText:SetTextColor(1, 0.5, 0.5)
        auctionAlertFrame.earlyNoticeText:SetText("")
    end

    -- ========== Frame2：始终只有"显示界面"按钮（透明背景）==========
    if not auctionAlertFrame2 then
        auctionAlertFrame2 = CreateFrame("Frame", nil, UIParent)
        auctionAlertFrame2:SetWidth(80)
        auctionAlertFrame2:SetHeight(22)
        auctionAlertFrame2:SetScale(XyScreenScale)
        auctionAlertFrame2:SetPoint("TOP", auctionAlertFrame, "TOP", 0, 0)
        auctionAlertFrame2:SetFrameStrata("HIGH")
        auctionAlertFrame2:Hide()

        -- "显示界面"按钮：P标记物品时显示，点击可显示Frame1
        auctionAlertFrame2.showFrame1Btn = CreateFrame("Button", nil, auctionAlertFrame2, "UIPanelButtonTemplate")
        auctionAlertFrame2.showFrame1Btn:SetWidth(80)
        auctionAlertFrame2.showFrame1Btn:SetHeight(22)
        auctionAlertFrame2.showFrame1Btn:SetPoint("CENTER", 0, -22)
        auctionAlertFrame2.showFrame1Btn:SetText("显示界面")
        auctionAlertFrame2.showFrame1Btn:SetScript("OnClick", function()
            if auctionAlertFrame then auctionAlertFrame:Show() end
            if auctionAlertFrame2 then auctionAlertFrame2:Hide() end
        end)
    end

-- 恢复拍卖弹窗位置
 if paipaiDB.alertPos then
 auctionAlertFrame:ClearAllPoints()
 auctionAlertFrame:SetPoint(paipaiDB.alertPos.point, UIParent, paipaiDB.alertPos.relPoint, paipaiDB.alertPos.x, paipaiDB.alertPos.y)
 end

    -- 启动倒计时
    if auctionAlertFrame.progressBar then
        auctionAlertFrame.totalTime = 10
        auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
        auctionAlertFrame.progressBar:SetValue(10)
        auctionAlertFrame.progressBar.timeText:SetText("10")
        auctionAlertFrame.startTime = GetTime()
        auctionAlertFrame:SetScript("OnUpdate", UpdateAuctionAlert)
    end

 -- 清理上一次拍卖残留的闪烁帧
 if auctionAlertFrame.flashFrame then
 auctionAlertFrame.flashFrame:SetScript("OnUpdate", nil)
 auctionAlertFrame.flashFrame = nil
 end

 -- ========== 许愿物品检测与闪光 ==========
 local playerName = UnitName("player")
 local isMyWish = false
 if XyArray then
 for idx = 1, table.getn(XyArray) do
 local entry = XyArray[idx]
 if entry and entry["name"] == playerName then
 local xy = entry["xy"] or ""
 local _, _, itemName = string.find(link, "|h%[(.-)%]|h")
 if itemName and XYT_WishContainsItem(xy, itemName) then
 isMyWish = true
 end
 break
 end
 end
 end
 auctionAlertFrame.isMyWish = isMyWish  -- 存储许愿状态供后续声音使用
 if isMyWish then
 auctionAlertFrame:SetBackdropBorderColor(1, 0, 0, 1)
 if not auctionAlertFrame.myWishText then
 auctionAlertFrame.myWishText = auctionAlertFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
 auctionAlertFrame.myWishText:SetPoint("TOP", 0, 15)
 auctionAlertFrame.myWishText:SetTextColor(1, 0.2, 0.2)
 end
 auctionAlertFrame.myWishText:SetText("★ 我的许愿物品 ★")
 local flashCount = 0
 local flashFrame = CreateFrame("Frame", nil, auctionAlertFrame)
 auctionAlertFrame.flashFrame = flashFrame -- 保存引用，方便清理
 flashFrame:SetScript("OnUpdate", function()
 local elapsed = arg1 or 0
 if not flashFrame.elapsed then flashFrame.elapsed = 0 end
 flashFrame.elapsed = flashFrame.elapsed + elapsed
 if flashFrame.elapsed >= 0.2 then
 flashFrame.elapsed = 0
 flashCount = flashCount + 1
 if math.mod(flashCount, 2) == 0 then
 auctionAlertFrame:SetBackdropBorderColor(1, 0, 0, 1)
 if auctionAlertFrame.myWishText then auctionAlertFrame.myWishText:SetTextColor(1, 0.2, 0.2) end
 if auctionAlertFrame.myWishTextBottom then auctionAlertFrame.myWishTextBottom:SetTextColor(1, 0.2, 0.2) end
 else
 auctionAlertFrame:SetBackdropBorderColor(0.5, 0.1, 0.1, 0.3)
 if auctionAlertFrame.myWishText then auctionAlertFrame.myWishText:SetTextColor(1, 0.2, 0.2, 0.3) end
 if auctionAlertFrame.myWishTextBottom then auctionAlertFrame.myWishTextBottom:SetTextColor(1, 0.2, 0.2, 0.3) end
 end
 end
 end)
 end


    auctionAlertFrame.titleText:SetText(link)
    if auctionAlertFrame.icon then
        local iconTexture, itemId = GetItemIconFromLink(link)
        auctionAlertFrame.icon.itemId = itemId
        auctionAlertFrame.icon.itemLink = link
        if iconTexture and iconTexture ~= "" then
            auctionAlertFrame.icon:SetNormalTexture(iconTexture)
        else
            auctionAlertFrame.icon:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end
    end
    if sender then
        auctionAlertFrame.hintText:SetText("拍卖中 —— 由 " .. sender .. " 发起")
    else
        auctionAlertFrame.hintText:SetText("拍卖中")
    end
    -- 初始化出分显示
    if auctionAlertFrame.bidText then
        auctionAlertFrame.bidText:SetText("暂无出分")
    end
    -- 清空提前数秒通知
    if auctionAlertFrame.earlyNoticeText then
        auctionAlertFrame.earlyNoticeText:SetText("")
    end
    -- 隐藏roll信息（非roll阶段不显示）
    if auctionAlertFrame.rollText then
        auctionAlertFrame.rollText:SetText("")
    end
    -- 显示我的分数和许愿状态
    if auctionAlertFrame.myDkpText then
        local player = UnitName("player")
        local myDkp = 0
        local wishStatus = "未许愿出分"
        if XyArray then
            for i, data in pairs(XyArray) do
                if data["name"] == player then
                    myDkp = tonumber(data["dkp"]) or 0
                    local xy = data["xy"] or ""
                    if xy ~= "---未许愿---" and xy ~= "" then
                        wishStatus = "出过许愿"
                    end
                    break
                end
            end
        end
        auctionAlertFrame.myDkpText:SetText("我的分数: " .. myDkp .. "    " .. wishStatus)
    end



    -- 应用 pfUI 皮肤（如果存在）
    if ApplyAuctionSkin then ApplyAuctionSkin(auctionAlertFrame) end


    auctionAlertFrame:Show()
    if auctionAlertFrame2 then auctionAlertFrame2:Hide() end
    -- P标记检测：如果物品在P标记列表中，关闭Frame1，显示Frame2
    local isPMarked = IsCurrentItemPMarked()
    if isPMarked then
        auctionAlertFrame:Hide()
        if auctionAlertFrame2 then auctionAlertFrame2:Show() end
    end
    -- ========== Frame2：P标记物品时显示按钮 ==========
    if auctionAlertFrame2 then
        auctionAlertFrame2:ClearAllPoints()
        auctionAlertFrame2:SetPoint("TOP", auctionAlertFrame, "TOP", 0, 0)
        if isPMarked then
            if auctionAlertFrame2.showFrame1Btn then auctionAlertFrame2.showFrame1Btn:Show() end
        else
            if auctionAlertFrame2.showFrame1Btn then auctionAlertFrame2.showFrame1Btn:Hide() end
        end
    end
    -- ========== 副本界面3内容同步（锚点paiFloatBtn上方，左对齐，内容同副本2）==========
    if auctionAlertFrame3 then
        if auctionAlertFrame3.bidText then auctionAlertFrame3.bidText:SetText("暂无出分") end
        if auctionAlertFrame3.rollText then auctionAlertFrame3.rollText:SetText("") end
    end
    -- 拍卖开始：显示浮动stop图标（仅拍卖发起者），切换为当前拍卖物品图标
    if XyPaiStopIcon and UnitName("player") == auctionSender and PaiFloatChainVisible() then
        if itemLink and itemLink ~= "" then
            local icon = GetItemIconFromLink(itemLink)
            if icon then
                XyPaiStopIcon.tex:SetTexture(icon)
            end
        end
        XyPaiStopIcon:Show()
        if XyPaiStopLabel then XyPaiStopLabel:Show() end
        if XyPaiStopTimeText then XyPaiStopTimeText:Show() end
        if paiFloatLabel then paiFloatLabel:Hide() end  -- 拍卖中隐藏"待拍"避免重叠
    end
    if XyPaiBidStopIcon and UnitName("player") == auctionSender and PaiFloatChainVisible() then
        XyPaiBidStopIcon:Show()
        -- 红光闪烁（照搬许愿闪烁逻辑）
        local flashCount = 0
        local flashFrame = CreateFrame("Frame", nil, XyPaiBidStopIcon)
        XyPaiBidStopIcon.flashFrame = flashFrame
        flashFrame:SetScript("OnUpdate", function()
            local elapsed = arg1 or 0
            if not flashFrame.elapsed then flashFrame.elapsed = 0 end
            flashFrame.elapsed = flashFrame.elapsed + elapsed
            if flashFrame.elapsed >= 0.2 then
                flashFrame.elapsed = 0
                flashCount = flashCount + 1
                if math.mod(flashCount, 2) == 0 then
                    if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Show() end
                else
                    if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Hide() end
                end
            end
        end)
    end
    -- 美女播报：拍卖开始声音
    if auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
        if not auctionAlertFrame.isMyWish then
            PlayVoice("Interface\\AddOns\\XyTracker\\voice\\pmks.ogg")
        else
            PlayVoice("Interface\\AddOns\\XyTracker\\voice\\ndxy.ogg")
        end
    end
    -- 自动许愿出分：拍卖开始后1秒自动出5分，2秒后播5fen.ogg（比出分晚1秒）
    if not wishBidTimer then
        wishBidTimer = CreateFrame("Frame")
        wishBidTimer:Hide()
        wishBidTimer:SetScript("OnUpdate", function()
            local elapsed = arg1 or 0
            if not wishBidTimer.elapsed then wishBidTimer.elapsed = 0 end
            wishBidTimer.elapsed = wishBidTimer.elapsed + elapsed
            -- 1秒：判定并自动出5分
            if wishBidTimer.elapsed >= 1 and not wishBidTimer.sent then
                wishBidTimer.sent = true
                -- 拍卖仍在进行（未被取消/结束）且当前装备是我的未完成许愿
                if auctionActive and IsCurrentItemMyWish(UnitName("player")) then
                    wishBidTimer.valid = true
                    SendChatMessage("5", "RAID")
                end
            end
            -- 2秒：播放5fen.ogg（比自动出分晚1秒）
            if wishBidTimer.elapsed >= 2 and not wishBidTimer.voiced then
                wishBidTimer.voiced = true
                if wishBidTimer.valid
                    and auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                    PlayVoice("Interface\\AddOns\\XyTracker\\voice\\5fen.ogg")
                end
                wishBidTimer:Hide()
            end
        end)
    end
    wishBidTimer.elapsed = 0
    wishBidTimer.sent = nil
    wishBidTimer.voiced = nil
    wishBidTimer.valid = nil
    wishBidTimer:Show()
end

-- 辅助函数：检查出分是否被超（仅美女播报勾选时生效）
-- 每次自己出分后重置检测，别人超我分时播放一次 yrgf.ogg
local function CheckBidBeat()
    if not auctionAlertFrame or not auctionAlertFrame.voiceCheck then return end
    if not auctionAlertFrame.voiceCheck:GetChecked() then return end
    local myName = UnitName("player")
    local myScore = nil
    for i = 1, table.getn(bidData) do
        if bidData[i].name == myName then myScore = bidData[i].score; break end
    end
    if not myScore then
        auctionAlertFrame._myLastBidScore = nil
        return
    end
    local prevMyScore = auctionAlertFrame._myLastBidScore
    if myScore ~= prevMyScore then
        -- 自己刚出分/改分，重置检测
        auctionAlertFrame._myLastBidScore = myScore
        auctionAlertFrame._bidBeatPlayed = false
        return
    end
    -- 分数未变，检查是否有人超我分
    if not auctionAlertFrame._bidBeatPlayed and myScore > 0 then
        for i = 1, table.getn(bidData) do
            if bidData[i].name ~= myName and bidData[i].score > myScore then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\yrgf.ogg")
                auctionAlertFrame._bidBeatPlayed = true
                break
            end
        end
    end
end

local function HideAuctionAlert()
    if not auctionAlertFrame then return end
    -- 重置边框颜色为默认
    auctionAlertFrame:SetBackdropBorderColor(1, 1, 1, 1)
    if auctionAlertFrame.myWishText then
 auctionAlertFrame.myWishText:SetText("")
 end
 if auctionAlertFrame.myWishTextBottom then
 auctionAlertFrame.myWishTextBottom:SetText("")
 end
    auctionActive = false
    rollData = {}
    loothog_players = {}
    preRollData = {}  -- 清空出分阶段预收集的roll
    if auctionAlertFrame then
        auctionAlertFrame:SetScript("OnUpdate", nil)

 -- 重置边框颜色
 auctionAlertFrame:SetBackdropBorderColor(1, 1, 1, 1)

 -- 清理许愿闪烁帧
 if auctionAlertFrame.flashFrame then
 auctionAlertFrame.flashFrame:SetScript("OnUpdate", nil)
 auctionAlertFrame.flashFrame = nil
 end
        auctionAlertFrame:Hide()
    end
    if auctionAlertFrame2 then auctionAlertFrame2:Hide() end
    if auctionAlertFrame3 then auctionAlertFrame3:Hide() end
    if XyPaiStopIcon then XyPaiStopIcon:Hide() end
    if XyPaiBidStopIcon then
        -- 清理红光闪烁帧
        if XyPaiBidStopIcon.flashFrame then
            XyPaiBidStopIcon.flashFrame:SetScript("OnUpdate", nil)
            XyPaiBidStopIcon.flashFrame = nil
        end
        if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Hide() end
        XyPaiBidStopIcon:Hide()
    end
end
DEFAULT_CHAT_FRAME:AddMessage("拍卖插件已加载（团长/助理可用拍卖界面）", 0.5, 1, 0.5)

-- 创建主框架
local AuctionFrame = CreateFrame("Frame", "XyAuctionFrame", UIParent)
AuctionFrame:SetWidth(340)
AuctionFrame:SetHeight(120)
AuctionFrame:SetScale(XyScreenScale)
AuctionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
AuctionFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
AuctionFrame:SetMovable(true)
AuctionFrame:EnableMouse(true)
AuctionFrame:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" then AuctionFrame:StartMoving() end
end)
AuctionFrame:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" then AuctionFrame:StopMovingOrSizing() end
end)
AuctionFrame:Hide()  -- 默认隐藏

-- ========= 三个常驻快捷按钮（已注释） =========
--[[
local quickFrame = CreateFrame("Frame", nil, UIParent)
quickFrame:SetWidth(180)
quickFrame:SetHeight(30)
quickFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
quickFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
quickFrame:SetMovable(true)
quickFrame:EnableMouse(true)
quickFrame:Hide()  -- 默认隐藏，只有团长/助理才显示
_G["XyQuickFrame"] = quickFrame

quickFrame:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" then quickFrame:StartMoving() end
end)
quickFrame:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" then
        quickFrame:StopMovingOrSizing()
        local point, _, relPoint, x, y = quickFrame:GetPoint()
        paipaiDB.quickFramePos = { point = point, relPoint = relPoint, x = x, y = y }
    end
end)

-- 快拍按钮
local kpBtn = CreateFrame("Button", nil, quickFrame, "UIPanelButtonTemplate")
kpBtn:SetWidth(50)
kpBtn:SetHeight(22)
kpBtn:SetPoint("LEFT", quickFrame, "LEFT", 5, 0)
kpBtn:SetText("快拍")
kpBtn:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" then quickFrame:StartMoving() end
end)
kpBtn:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" then
            quickFrame:StopMovingOrSizing()
            local point, _, relPoint, x, y = quickFrame:GetPoint()
            paipaiDB.quickFramePos = { point = point, relPoint = relPoint, x = x, y = y }
        end
end)
kpBtn:SetScript("OnClick", function()
    ShowLinkList(quickFrame, true, true)
end)

-- 数秒按钮
local ssBtn = CreateFrame("Button", nil, quickFrame, "UIPanelButtonTemplate")
ssBtn:SetWidth(50)
ssBtn:SetHeight(22)
ssBtn:SetPoint("LEFT", kpBtn, "RIGHT", 5, 0)
ssBtn:SetText("数秒")
ssBtn:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" then quickFrame:StartMoving() end
end)
ssBtn:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" then
            quickFrame:StopMovingOrSizing()
            local point, _, relPoint, x, y = quickFrame:GetPoint()
            paipaiDB.quickFramePos = { point = point, relPoint = relPoint, x = x, y = y }
        end
end)
ssBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(ssBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText("立即开始3秒倒计时", 1, 1, 1)
    GameTooltip:Show()
end)
ssBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)
ssBtn:SetScript("OnClick", function()
    if UnitName("player") ~= auctionSender then
        UIErrorsFrame:AddMessage("只有拍卖发起者可以提前结束拍卖。", 1.0, 0.0, 0.0, 1.0)
        return
    end
    if timerFrame and timerFrame.state == 4 then
        StartRollCountdownNow()
    else
        StartCountdownNow()
    end
end)

-- 界面按钮
local jmBtn = CreateFrame("Button", nil, quickFrame, "UIPanelButtonTemplate")
jmBtn:SetWidth(50)
jmBtn:SetHeight(22)
jmBtn:SetPoint("LEFT", ssBtn, "RIGHT", 5, 0)
jmBtn:SetText("界面")
jmBtn:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" then quickFrame:StartMoving() end
end)
jmBtn:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" then
            quickFrame:StopMovingOrSizing()
            local point, _, relPoint, x, y = quickFrame:GetPoint()
            paipaiDB.quickFramePos = { point = point, relPoint = relPoint, x = x, y = y }
        end
end)
jmBtn:SetScript("OnClick", function()
    if not IsRaidLeaderOrAssistant() then return end
    if AuctionFrame:IsVisible() then AuctionFrame:Hide() else AuctionFrame:Show() end
end)





-- 关闭按钮
local qCloseBtn = CreateFrame("Button", nil, quickFrame, "UIPanelButtonTemplate")
qCloseBtn:SetWidth(16)
qCloseBtn:SetHeight(16)
qCloseBtn:SetPoint("RIGHT", quickFrame, "RIGHT", -2, 0)
qCloseBtn:SetText("X")
qCloseBtn:SetScript("OnClick", function()
    paipaiDB.quickFrameHidden = true
    quickFrame:Hide()
end)
--]]
local title = AuctionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -10)
title:SetText("拍卖插件")

-- 关闭按钮
local closeBtn = CreateFrame("Button", nil, AuctionFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)
closeBtn:SetScript("OnClick", function() AuctionFrame:Hide() end)
AuctionFrame.closeBtn = closeBtn   -- <-- 添加这行

-- 输入框
local input = CreateFrame("EditBox", nil, AuctionFrame)
input:SetWidth(180)
input:SetHeight(20)
input:SetPoint("TOP", 0, -35)
input:SetFontObject(GameFontNormal)
input:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\ChatFrame\\ChatFrameBorder",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
input:SetBackdropColor(0, 0, 0, 0.5)
input:SetBackdropBorderColor(1, 1, 1, 1)
input:SetAutoFocus(false)  -- 默认不自动获得焦点
input:SetText("在此输入物品")
input:SetTextColor(1, 1, 1)
input:SetScript("OnEscapePressed", function() this:ClearFocus() end)

-- ========== 品质勾选行 ==========
local FILTER_QUALITY = {}
-- 从 paipaiDB 恢复品质过滤状态
for q = 0, 5 do
    if paipaiDB.quality[q] ~= nil then
        FILTER_QUALITY[q] = paipaiDB.quality[q]
    else
        FILTER_QUALITY[q] = (q ~= 0)  -- 灰色默认 false，其他默认 true
    end
end
local FILTER_SOLD = true
if paipaiDB.showSold ~= nil then FILTER_SOLD = paipaiDB.showSold end

local filterRow = CreateFrame("Frame", nil, AuctionFrame)
filterRow:SetPoint("TOPLEFT", input, "BOTTOMLEFT", -40, 0)
filterRow:SetPoint("TOPRIGHT", input, "BOTTOMRIGHT", 0, -5)
filterRow:SetHeight(22)

local QUALITY_NAMES = {
    [1] = "白",
    [2] = "绿",
    [3] = "蓝",
    [4] = "紫",
    [5] = "橙",
}

local CB_WIDTH = 16
local CB_HEI = 16
local BTN_W = 35  -- 每个品质按钮总宽度（文字+间距+勾选框）
local BTN_HEI = 18

local filterCbs = {}
local function MakeQualityCb(q)
    local btn = CreateFrame("Button", nil, filterRow)
    btn:SetWidth(BTN_W)
    btn:SetHeight(BTN_HEI)

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("LEFT", btn, "LEFT", 0, 0)
    lbl:SetPoint("TOP", btn, "TOP", 0, 0)
    lbl:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)
    if q == 1 then lbl:SetTextColor(1, 1, 1)
    elseif q == 2 then lbl:SetTextColor(0.12, 0.82, 0)
    elseif q == 3 then lbl:SetTextColor(0, 0.44, 0.87)
    elseif q == 4 then lbl:SetTextColor(0.64, 0.21, 0.93)
    elseif q == 5 then lbl:SetTextColor(1, 0.5, 0)
    end
    lbl:SetText(QUALITY_NAMES[q] .. ":")

    -- 底框（始终显示），紧跟文字
    local boxOff = 15  -- 勾选框左边缘相对按钮左边缘的偏移
    local frameTex = btn:CreateTexture(nil, "BACKGROUND")
    frameTex:SetWidth(CB_WIDTH)
    frameTex:SetHeight(CB_HEI)
    frameTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
    frameTex:SetPoint("LEFT", btn, "LEFT", boxOff, 0)
    frameTex:SetPoint("TOP", btn, "TOP", 0, 0)
    frameTex:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)

    -- 勾✓（按状态显示/隐藏）
    local checkTex = btn:CreateTexture(nil, "ARTWORK")
    checkTex:SetWidth(CB_WIDTH)
    checkTex:SetHeight(CB_HEI)
    checkTex:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    checkTex:SetPoint("LEFT", btn, "LEFT", boxOff, 0)
    checkTex:SetPoint("TOP", btn, "TOP", 0, 0)
    checkTex:SetPoint("BOTTOM", btn, "BOTTOM", 0, 0)

    btn.checkTex = checkTex
        btn:SetScript("OnClick", function()
        FILTER_QUALITY[q] = not FILTER_QUALITY[q]
        -- FILTER_QUALITY[q] 已在上面翻转
        paipaiDB.quality[q] = FILTER_QUALITY[q]  -- 写回 SavedVariables
        if FILTER_QUALITY[q] then checkTex:Show() else checkTex:Hide() end
    
        if linkListFrame and linkListFrame:IsVisible() then linkListFrame:Refresh() else ShowLinkList(nil, false) end
    end)

    if FILTER_QUALITY[q] then checkTex:Show() else checkTex:Hide() end
    return btn
end

-- 已拍按钮
local soldBtn = CreateFrame("Button", nil, filterRow)
soldBtn:SetWidth(BTN_W)
soldBtn:SetHeight(BTN_HEI)
local soldLbl = soldBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
soldLbl:SetPoint("LEFT", soldBtn, "LEFT", 0, 0)
soldLbl:SetPoint("TOP", soldBtn, "TOP", 0, 0)
soldLbl:SetPoint("BOTTOM", soldBtn, "BOTTOM", 0, 0)
soldLbl:SetText("已拍:")
local soldOff = 25  -- 已拍文字略宽，用更大偏移
local soldFrame = soldBtn:CreateTexture(nil, "BACKGROUND")
soldFrame:SetWidth(CB_WIDTH)
soldFrame:SetHeight(CB_HEI)
soldFrame:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
soldFrame:SetPoint("LEFT", soldBtn, "LEFT", soldOff, 0)
soldFrame:SetPoint("TOP", soldBtn, "TOP", 0, 0)
soldFrame:SetPoint("BOTTOM", soldBtn, "BOTTOM", 0, 0)

local soldCheck = soldBtn:CreateTexture(nil, "ARTWORK")
soldCheck:SetWidth(CB_WIDTH)
soldCheck:SetHeight(CB_HEI)
soldCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
soldCheck:SetPoint("LEFT", soldBtn, "LEFT", soldOff, 0)
soldCheck:SetPoint("TOP", soldBtn, "TOP", 0, 0)
soldCheck:SetPoint("BOTTOM", soldBtn, "BOTTOM", 0, 0)
    _G.paipaiSoldCheck = soldCheck
soldBtn:SetScript("OnClick", function()
    FILTER_SOLD = not FILTER_SOLD
    paipaiDB.showSold = FILTER_SOLD  -- 写回 SavedVariables
    if FILTER_SOLD then soldCheck:Show() else soldCheck:Hide() end

    if linkListFrame and linkListFrame:IsVisible() then linkListFrame:Refresh() else ShowLinkList(nil, false) end
end)
if FILTER_SOLD then soldCheck:Show() else soldCheck:Hide() end

-- 布局
local x = 0
for q = 1, 5 do
    local btn = MakeQualityCb(q)
    btn:SetPoint("LEFT", filterRow, "LEFT", x, 0)
    x = x + BTN_W + 8
    filterCbs[q] = btn
end
soldBtn:SetPoint("LEFT", filterRow, "LEFT", x, 0)

-- 从物品链接颜色码提取品质（WoW 1.12 固定颜色）
-- 品质颜色表（数组保证遍历顺序）
local QUALITY_COLOR_LIST = {
    { q = 0, hex = "9d9d9d" },  -- 灰色
    { q = 1, hex = "ffffff" },  -- 白色
    { q = 2, hex = "1eff00" },  -- 绿色
    { q = 3, hex = "0070dd" },  -- 蓝色
    { q = 4, hex = "a335ee" },  -- 紫色
    { q = 5, hex = "ff8000" },  -- 橙色
}

local function GetLinkQuality(link)
    local hex = string.match(link, "|cff(%x%x%x%x%x%x)")
    if not hex then return 0 end
    hex = string.lower(hex)
    local q
    if      hex == "9d9d9d" then q = 0
    elseif  hex == "ffffff" then q = 1
    elseif  hex == "1eff00" then q = 2
    elseif  hex == "0070dd" then q = 3
    elseif  hex == "a335ee" then q = 4
    elseif  hex == "ff8000" then q = 5
    else                         q = 99
    end
    return q
end

-- 物品链接过滤函数
local function IsLinkVisible(link, sold)
    if sold then
        return FILTER_SOLD
    end
    local q = GetLinkQuality(link)
    local v = FILTER_QUALITY[q]
    return v
end

local linkListFrame = nil

-- 选择物品按钮（原链接按钮，文字改为"物品"）
local itemBtn = CreateFrame("Button", nil, AuctionFrame, "UIPanelButtonTemplate")
itemBtn:SetWidth(40)
itemBtn:SetHeight(22)
itemBtn:SetPoint("LEFT", input, "RIGHT", 5, 0)
itemBtn:SetText("物品")
itemBtn:SetScript("OnClick", function()
    ShowLinkList(itemBtn, false)
end)
-- 添加悬停提示
itemBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(itemBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText("点击选中你要拍卖的物品", 1, 1, 1)
    GameTooltip:Show()
end)
itemBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 计时器框架
timerFrame = CreateFrame("Frame", nil, UIParent)
timerFrame:Hide()
timerFrame.state = 0          -- 0:空闲 1:等待25秒 2:倒计时5秒 3:等待发送分割线
timerFrame.startTime = 0
timerFrame.countdown = 0
timerFrame.lastSent = 0
timerFrame.currentAuctionLink = nil  -- 当前正在拍卖的物品链接

-- 倒计时中文数字
local cn = {[3]="三",[2]="二",[1]="一"}

-- 倒计时立即开始函数
function StartCountdownNow()
    if timerFrame.state == 4 then
        return
    end
    if timerFrame.state ~= 1 then return end
    timerFrame:Hide()
    if GetNumRaidMembers() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("不在团队中,无法发送倒计时。", 1, 0.1, 0.1)
        return
    end
    -- 通知团员提前开始倒计时
    SendAddonMessage("PP_AUCTION_EARLY", UnitName("player"), "RAID")
    -- 团长自己也更新一次（SendAddonMessage 不回传发送者）
    if auctionAlertFrame and auctionAlertFrame:IsVisible() then
        auctionAlertFrame.totalTime = 3
        auctionAlertFrame.progressBar:SetMinMaxValues(0, 3)
        auctionAlertFrame.progressBar:SetValue(3)
        auctionAlertFrame.progressBar.timeText:SetText("3")
        auctionAlertFrame.startTime = GetTime()
        if auctionAlertFrame.earlyNoticeText then
            auctionAlertFrame.earlyNoticeText:SetText(UnitName("player") .. "提前开始了倒计时")
        end
    end
    timerFrame.state = 2
    timerFrame.startTime = GetTime()
    timerFrame.countdown = 3
    timerFrame.lastSent = timerFrame.startTime
    -- 美女播报：倒计时开始
    if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\3s.ogg")
    end
    -- 立即发送第一声"三"
    if UnitName("player") == auctionSender then
        SendChatMessage("三", "RAID", nil, nil)
    end
    timerFrame.countdown = 2
    timerFrame:Show()
end

-- roll点阶段提前倒计时
function StartRollCountdownNow()
    if timerFrame.state ~= 4 then return end
    if UnitName("player") ~= auctionSender then
        UIErrorsFrame:AddMessage("只有拍卖发起者可以提前开始roll点倒计时。", 1.0, 0.0, 0.0, 1.0)
        return
    end
    local now = GetTime()
    timerFrame.startTime = now - (auctionAlertFrame.totalTime - 3)
    auctionAlertFrame.startTime = timerFrame.startTime
    timerFrame.lastSent = now
    -- 立即发送第一声"三"（与出分阶段提前倒计时一致；否则lastSent刚设为now，
    -- OnUpdate首次检查不满足>=1，等1秒后remaining已掉到2，会漏掉"三"）
    if UnitName("player") == auctionSender then
        SendChatMessage("三", "RAID", nil, nil)
    end
    if auctionAlertFrame and auctionAlertFrame.earlyNoticeText then
        auctionAlertFrame.earlyNoticeText:SetText(UnitName("player") .. "提前开始了roll点倒计时")
    end
    -- 美女播报：倒计时开始
    if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\3s.ogg")
    end
    SendAddonMessage("PP_AUCTION_EARLY", UnitName("player"), "RAID")
end

-- 拍卖按钮
local auctionBtn = CreateFrame("Button", nil, AuctionFrame, "UIPanelButtonTemplate")
auctionBtn:SetWidth(120)
auctionBtn:SetHeight(25)
auctionBtn:SetPoint("TOPLEFT", input, "BOTTOMLEFT", -35, -20)
auctionBtn:SetText("拍卖")
-- 添加悬停提示
auctionBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(auctionBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText("开始拍卖当前输入的物品(30秒出分时间)", 1, 1, 1)
    GameTooltip:Show()
end)
auctionBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 提前结束按钮
local earlyBtn = CreateFrame("Button", nil, AuctionFrame, "UIPanelButtonTemplate")
earlyBtn:SetWidth(120)
earlyBtn:SetHeight(25)
earlyBtn:SetPoint("LEFT", auctionBtn, "RIGHT", 10, 0)
earlyBtn:SetText("提前结束")
-- 添加悬停提示
earlyBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(earlyBtn, "ANCHOR_RIGHT")
    if timerFrame.state == 4 then
        GameTooltip:SetText("roll点阶段禁止提前结束", 1, 0.1, 0.1)
    else
        GameTooltip:SetText("立即开始3秒倒计时并结束拍卖", 1, 1, 1)
    end
    GameTooltip:Show()
end)
earlyBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 拍卖按钮点击事件
auctionBtn:SetScript("OnClick", function()
 if timerFrame and timerFrame.state >= 1 and timerFrame.state <= 4 then
 UIErrorsFrame:AddMessage("当前有拍卖正在进行，请等待结束后再发起。", 1.0, 0.0, 0.0, 1.0)
 return
 end
 local itemText = input:GetText()
    if itemText == "" then
        UIErrorsFrame:AddMessage("请输入要拍卖的物品链接!", 1.0, 0.0, 0.0, 1.0)
        return
    end
    if GetNumRaidMembers() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("你不在一个团队中。", 1, 0.1, 0.1)
        return
    end
    SendChatMessage("现在开始拍卖" .. itemText, "RAID_WARNING", nil, nil)
    SendAddonMessage("PP_AUCTION_START", itemText, "RAID")
                        timerFrame.currentAuctionLink = itemText
    auctionSender = UnitName("player")  -- 标记自己为发起者

    -- 记录当前拍卖的物品链接
    timerFrame.currentAuctionLink = itemText

    -- 发起者也需要初始化拍卖界面（包括auctionAlertFrame2副本界面）
    auctionDismissed = false
    ShowAuctionAlert(itemText, UnitName("player"))

    timerFrame:Hide()
    timerFrame.state = 1
    timerFrame.startTime = GetTime()
    timerFrame:Show()
end)

-- 提前结束按钮点击事件
earlyBtn:SetScript("OnClick", function()
 if UnitName("player") ~= auctionSender then
 UIErrorsFrame:AddMessage("只有拍卖发起者可以提前结束拍卖。", 1.0, 0.0, 0.0, 1.0)
 return
 end
 if timerFrame and timerFrame.state == 4 then
        StartRollCountdownNow()
    else
        StartCountdownNow()
    end
end)

-- 计时器的OnUpdate处理
timerFrame:SetScript("OnUpdate", function()
    local now = GetTime()

    -- 副本界面2&3：拍卖全程显示（state 1~5），空闲state 0时隐藏
    -- auctionAlertFrame3: 仅团长/助理可见
    if timerFrame.state ~= timerFrame._lastStopState then
        local prevState = timerFrame._lastStopState
        timerFrame._lastStopState = timerFrame.state
        -- Roll阶段按钮：进入时只显示大Roll按钮，离开到结算/空闲时恢复
        if timerFrame.state == 4 then
            SetRollPhaseButtons(true)
        elseif prevState == 4 and timerFrame.state ~= 5 then
            SetRollPhaseButtons(false)
        elseif timerFrame.state == 1 or timerFrame.state == 2 or timerFrame.state == 3 then
            -- 出分/倒计时阶段强制恢复出分布局（覆盖直接roll结算5→1跳转残留roll布局的路径）
            SetRollPhaseButtons(false)
        end
        if timerFrame.state == 0 then
            SetRollPhaseButtons(false)  -- 确保完全关闭时恢复出分按钮（覆盖4→5→0的跳过路径）
            if auctionAlertFrame2 then auctionAlertFrame2:Hide() end
            if auctionAlertFrame3 then auctionAlertFrame3:Hide() end
        else
            -- Frame2仅在Frame1隐藏且拍卖活跃时显示
            if auctionAlertFrame2 and (not auctionAlertFrame or not auctionAlertFrame:IsVisible()) then
                auctionAlertFrame2:Show()
            end
            if auctionAlertFrame3 and PaiFloatChainVisible() then
                auctionAlertFrame3:Show()
            end
        end
        -- stop图标: 出分(state 1)、倒计时(state 2)、roll(state 4)显示（仅拍卖发起者）
        if timerFrame.state == 1 or timerFrame.state == 2 or timerFrame.state == 4 then
            if XyPaiStopIcon and UnitName("player") == auctionSender and PaiFloatChainVisible() then
                -- state 1: 切换为当前拍卖物品图标
                if timerFrame.state == 1 and timerFrame.currentAuctionLink then
                    local icon = GetItemIconFromLink(timerFrame.currentAuctionLink)
                    if icon then
                        XyPaiStopIcon.tex:SetTexture(icon)
                    end
                end
                XyPaiStopIcon:Show()
                if XyPaiStopTimeText then XyPaiStopTimeText:Show() end
                if XyPaiStopLabel then XyPaiStopLabel:Show() end
                if paiFloatLabel then paiFloatLabel:Hide() end  -- 拍卖中隐藏"待拍"避免重叠
            end
        elseif timerFrame.state == 0 or timerFrame.state == 3 or timerFrame.state == 5 then
            if XyPaiStopIcon then XyPaiStopIcon:Hide() end
        end
        -- 右侧stop图标: state1和state4显示（仅拍卖发起者）
        if (timerFrame.state == 1 or timerFrame.state == 4) and UnitName("player") == auctionSender and PaiFloatChainVisible() then
            if XyPaiBidStopIcon then
                XyPaiBidStopIcon:Show()
                -- 红光闪烁（照搬许愿闪烁逻辑）
                if not XyPaiBidStopIcon.flashFrame then
                    local flashCount = 0
                    local flashFrame = CreateFrame("Frame", nil, XyPaiBidStopIcon)
                    XyPaiBidStopIcon.flashFrame = flashFrame
                    flashFrame:SetScript("OnUpdate", function()
                        local elapsed = arg1 or 0
                        if not flashFrame.elapsed then flashFrame.elapsed = 0 end
                        flashFrame.elapsed = flashFrame.elapsed + elapsed
                        if flashFrame.elapsed >= 0.2 then
                            flashFrame.elapsed = 0
                            flashCount = flashCount + 1
                            if math.mod(flashCount, 2) == 0 then
                                if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Show() end
                            else
                                if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Hide() end
                            end
                        end
                    end)
                end
            end
        else
            if XyPaiBidStopIcon then
                -- 清理红光闪烁帧
                if XyPaiBidStopIcon.flashFrame then
                    XyPaiBidStopIcon.flashFrame:SetScript("OnUpdate", nil)
                    XyPaiBidStopIcon.flashFrame = nil
                end
                if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Hide() end
                XyPaiBidStopIcon:Hide()
            end
        end
    end

    -- roll点阶段(state 4)与出分阶段(state 1/2)完全一致：
    -- 最后3秒右侧stop图标(XyPaiBidStopIcon)隐藏（等同出分阶段进入三二一倒计时state 2时右侧stop图标消失），
    -- pai.tga stop图标及中心数字保留继续显示；结束时随 state 转入 5/0 由上方显示逻辑自动隐藏。
    if timerFrame.state == 4 then
        local remaining = (auctionAlertFrame.totalTime or 10) - (now - timerFrame.startTime)
        if remaining <= 3 then
            if XyPaiBidStopIcon then
                if XyPaiBidStopIcon.flashFrame then
                    XyPaiBidStopIcon.flashFrame:SetScript("OnUpdate", nil)
                    XyPaiBidStopIcon.flashFrame = nil
                end
                if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Hide() end
                XyPaiBidStopIcon:Hide()
            end
        elseif XyPaiBidStopIcon and UnitName("player") == auctionSender and PaiFloatChainVisible() then
            -- 有人roll时间重置回10秒（remaining>3）：恢复被上方分支隐藏的右侧stop图标（含红光闪烁）。
            -- 因 state 仍为4未变化，1646行state变化分支不会重新执行，这里必须显式恢复。
            if not XyPaiBidStopIcon:IsShown() then
                XyPaiBidStopIcon:Show()
                if not XyPaiBidStopIcon.flashFrame then
                    local flashCount = 0
                    local flashFrame = CreateFrame("Frame", nil, XyPaiBidStopIcon)
                    XyPaiBidStopIcon.flashFrame = flashFrame
                    flashFrame:SetScript("OnUpdate", function()
                        local elapsed = arg1 or 0
                        if not flashFrame.elapsed then flashFrame.elapsed = 0 end
                        flashFrame.elapsed = flashFrame.elapsed + elapsed
                        if flashFrame.elapsed >= 0.2 then
                            flashFrame.elapsed = 0
                            flashCount = flashCount + 1
                            if math.mod(flashCount, 2) == 0 then
                                if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Show() end
                            else
                                if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Hide() end
                            end
                        end
                    end)
                end
            end
        end
    end

    -- 更新stop图标上的剩余时间（state 1用计时器差值，state 2与frame1进度条同源四舍五入，state 4用计时器差值）
    if XyPaiStopTimeText and (timerFrame.state == 1 or timerFrame.state == 2 or timerFrame.state == 4) then
        local remain = 0
        if timerFrame.state == 1 then
            remain = math.ceil(10 - (now - timerFrame.startTime))
        elseif timerFrame.state == 2 then
            -- 与frame1进度条同源（totalTime/startTime 四舍五入），保证数字一致（从3开始，而非countdown的2）
            remain = math.floor((auctionAlertFrame.totalTime or 10) - (now - auctionAlertFrame.startTime) + 0.5)
        elseif timerFrame.state == 4 then
            remain = math.ceil(10 - (now - timerFrame.startTime))
        end
        if remain < 0 then remain = 0 end
        XyPaiStopTimeText:SetText(remain)
    end

    if timerFrame.state == 1 then
        -- 等待出分阶段（总10秒，前7秒出分，后3秒倒计时）
        if now - timerFrame.startTime >= 7 then
            -- 剩余3秒,自动转入倒计时
            timerFrame.state = 2
            timerFrame.startTime = now
            timerFrame.countdown = 3
            timerFrame.lastSent = now
            -- 美女播报：倒计时开始
            if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                PlayVoice("Interface\\AddOns\\XyTracker\\voice\\3s.ogg")
            end
            if GetNumRaidMembers() == 0 then
                DEFAULT_CHAT_FRAME:AddMessage("不在团队中,倒计时终止。", 1, 0.1, 0.1)
                timerFrame:Hide()
                timerFrame.state = 0
                return
            end
            -- 立即发送第一声"三"
            if UnitName("player") == auctionSender then
                SendChatMessage("三", "RAID", nil, nil)
            end
            timerFrame.countdown = 2
 end

    elseif timerFrame.state == 2 then
        -- 倒计时5秒阶段
        if timerFrame.countdown > 0 then
            if now - timerFrame.lastSent >= 1 then
                timerFrame.lastSent = now
                if GetNumRaidMembers() == 0 then
                    DEFAULT_CHAT_FRAME:AddMessage("不在团队中,倒计时终止。", 1, 0.1, 0.1)
                    timerFrame:Hide()
                    timerFrame.state = 0
                    return
                end
                if UnitName("player") == auctionSender then
                SendChatMessage(cn[timerFrame.countdown], "RAID", nil, nil)
                end
                timerFrame.countdown = timerFrame.countdown - 1
            end
        else
            -- 倒计时结束,发送结束语并标记当前拍卖物品为已拍
            if GetNumRaidMembers() > 0 then
                if UnitName("player") == auctionSender then
                    SendChatMessage("出分结束!", "RAID_WARNING", nil, nil)
                end
            SendAddonMessage("PP_AUCTION_END", timerFrame.currentAuctionLink or "", "RAID")
            end
            -- 转入状态3:等待1秒发送分割线
            timerFrame.state = 3
            timerFrame.startTime = now
            -- 注意:不要隐藏timerFrame,继续显示以处理状态3
            if auctionAlertFrame and auctionAlertFrame.earlyNoticeText then
                auctionAlertFrame.earlyNoticeText:SetText("")
            end
        end

    elseif timerFrame.state == 3 then
        -- 检测多人同分
        if now - timerFrame.startTime >= 1 then
            timerFrame.state = 0  -- 立即退状态防止报错导致死循环
            local maxScore = 0
            local maxPlayers = {}
            for i = 1, table.getn(bidData) do
                local score = bidData[i].score
                if score > maxScore then
                    maxScore = score
                    maxPlayers = {bidData[i].name}
                elseif score == maxScore then
                    table.insert(maxPlayers, bidData[i].name)
                end
            end

            if table.getn(maxPlayers) >= 2 then
                -- 判断自己是否在roll名单中（拍卖人也要判断：不在名单就不显示roll界面）
                local myName = UnitName("player")
                local inRoll = false
                for _, n in ipairs(maxPlayers) do
                    if n == myName then inRoll = true; break end
                end
                -- 非拍卖者：不在roll名单中则直接退出，不进入roll流程
                if not inRoll and UnitName("player") ~= auctionSender then
                    HideAuctionAlert()
                    return  -- state已为0（line 1649），直接结束
                end
                -- 多人同分，发起roll点
                rollNames = maxPlayers
                rollData = {}  -- 清空roll记录
                loothog_players = {}  -- 清空已roll玩家（类LootHog）
                -- 采纳出分阶段玩家提前roll的记录（只保留名单内的，每人取最高）
                for i = 1, table.getn(preRollData) do
                    local p = preRollData[i]
                    local inList = false
                    for _, n in ipairs(rollNames) do
                        if n == p.name then inList = true; break end
                    end
                    if inList and not loothog_players[p.name] then
                        loothog_players[p.name] = true
                        table.insert(rollData, {name = p.name, roll = p.roll})
                    end
                end
                preRollData = {}
                local nameList = table.concat(maxPlayers, "、")
                if UnitName("player") == auctionSender then
                    SendChatMessage("现在请" .. nameList .. "进行roll点。", "RAID_WARNING", nil, nil)
                end
                timerFrame.state = 4
                timerFrame.startTime = now
                timerFrame.lastSent = now
                -- 美女播报：进入roll阶段
                if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                    PlayVoice("Interface\\AddOns\\XyTracker\\voice\\ksroll.ogg")
                end
                auctionAlertFrame._rollBgPlayed = false  -- 重置被超检测
                if auctionAlertFrame and auctionAlertFrame.earlyNoticeText then
                    auctionAlertFrame.earlyNoticeText:SetText("")
                end
                auctionAlertFrame.startTime = GetTime()
                auctionAlertFrame.totalTime = 10
                auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
                auctionAlertFrame.progressBar:SetValue(10)
                auctionAlertFrame.progressBar.timeText:SetText("10")
                auctionAlertFrame.rollText:SetText("")
                auctionAlertFrame.rollText:SetJustifyH("CENTER")
                -- 进入roll阶段说明已有出分，强制清除P标记
                ClearPMarkForCurrentItem()
                if inRoll then
                    -- 名单内：正常显示roll界面（P标记时隐藏，由frame2承接）
                    if IsCurrentItemPMarked() then
                        auctionAlertFrame:Hide()
                        if auctionAlertFrame2 then auctionAlertFrame2:Show() end
                    else
                        auctionAlertFrame:Show()
                    end
                else
                    -- 不在名单（如拍卖人未出分/非最高分）：不显示roll参与界面，只保留流程（喊话/广播/state=4照常）
                    auctionAlertFrame:Hide()
                end
                auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
                -- 恢复倒计时OnUpdate（可能被PP_AUCTION_END的HideAuctionAlert移除了）
                auctionAlertFrame:SetScript("OnUpdate", UpdateAuctionAlert)
                -- 重排按钮为roll阶段（隐藏出分/P按钮，只显示放大Roll按钮）
                SetRollPhaseButtons(true)
                -- 广播roll状态给全团（maxScore;hex名单：名单hex编码成纯ASCII传输，规避中文广播截断）
                if UnitName("player") == auctionSender then
                    local encNames = {}
                    for i = 1, table.getn(maxPlayers) do
                        table.insert(encNames, XyHexEncode(maxPlayers[i]))
                    end
                    SendAddonMessage("PP_AUCTION_ROLL", tostring(maxScore) .. ";" .. table.concat(encNames, ","), "RAID")
                end
            else
                -- 单人胜出或无出分，原逻辑
                if GetNumRaidMembers() > 0 then
                    -- 喊话宣布胜者
                    local auctionWinner = nil
                    if maxScore == 0 then
 local itemLink = timerFrame.currentAuctionLink or ""
 if UnitName("player") == auctionSender then
 -- 流拍不入结算队列（按物品匹配，流拍物品没有对应记录，不会被误分）
 SendChatMessage(itemLink .. "无人问津，流拍！", "RAID_WARNING", nil, nil)
 end
elseif table.getn(maxPlayers) == 1 and maxScore > 0 then
                        local winner = maxPlayers[1]
                        auctionWinner = winner
                        local itemLink = timerFrame.currentAuctionLink or ""
                        if UnitName("player") == auctionSender then
                            table.insert(XyLastAuctionResults, { winner = winner, itemLink = itemLink })
                            if table.getn(XyLastAuctionResults) > 20 then table.remove(XyLastAuctionResults, 1) end
                        end
                        local scoreCn = NumberToChinese(maxScore)
                        if UnitName("player") == auctionSender then
                            SendChatMessage("恭喜！" .. winner .. "赢得了" .. itemLink .. "，消费" .. scoreCn .. "分。请及时在许愿插件扣分！", "RAID_WARNING", nil, nil)
                        end

                        -- 许愿消耗由许愿插件管理，此处不跟踪
                    end
                    -- 美女播报：拍卖结束声音
                    if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                        if auctionWinner and UnitName("player") == auctionWinner then
                            PlayVoice("Interface\\AddOns\\XyTracker\\voice\\datisheng.ogg")
                        else
                            PlayVoice("Interface\\AddOns\\XyTracker\\voice\\pmjs.ogg")
                        end
                    end
                end
                if timerFrame.currentAuctionLink then
                    MarkLinkAsSold(timerFrame.currentAuctionLink)
                end
                -- 最后一件装备：拍卖结算后3秒播放xykf.ogg（美女播报开启时，标记已拍后再判定）
                if UnitName("player") == auctionSender
                    and auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked()
                    and paiGetUnsoldItem() == nil then
                    PlayDelayedVoice("Interface\\AddOns\\XyTracker\\voice\\xykf.ogg", 3)
                end
                timerFrame.currentAuctionLink = nil
                timerFrame:Hide()
            end
        end

    elseif timerFrame.state == 4 then
        -- 20秒倒计时(>5数字/<=5汉字)
        local remaining = auctionAlertFrame.totalTime - (now - timerFrame.startTime)
        if remaining <= 0 then
            -- 评估roll结果
            local maxRoll = 0
            local maxPlayers = {}
            for i = 1, table.getn(rollData) do
                local roll = rollData[i].roll
                if roll > maxRoll then
                    maxRoll = roll
                    maxPlayers = {rollData[i].name}
                elseif roll == maxRoll then
                    table.insert(maxPlayers, rollData[i].name)
                end
            end

            if table.getn(maxPlayers) == 1 then
                -- 单人胜出，结算（与出分结算格式一致）
                local winner = maxPlayers[1]
                local itemLink = timerFrame.currentAuctionLink or ""
                if UnitName("player") == auctionSender then
                    table.insert(XyLastAuctionResults, { winner = winner, itemLink = itemLink })
                    if table.getn(XyLastAuctionResults) > 20 then table.remove(XyLastAuctionResults, 1) end
                end
                if GetNumRaidMembers() > 0 and UnitName("player") == auctionSender then
                    if directRollMode then
                        -- 直接roll无出分，不播报消费分数，也无须登记
                        SendChatMessage("恭喜！" .. winner .. "赢得了" .. itemLink .. "（roll点高达" .. maxRoll .. "）！", "RAID_WARNING", nil, nil)
                    else
                        local bidScore = 1  for i = 1, table.getn(bidData) do if bidData[i].name == winner then bidScore = bidData[i].score end end
                        local bidScoreCn = NumberToChinese(bidScore)
                        SendChatMessage("恭喜！" .. winner .. "赢得了" .. itemLink .. "（roll点高达" .. maxRoll .. "），消费" .. bidScoreCn .. "分。请及时在许愿插件扣分！", "RAID_WARNING", nil, nil)
                    end
                end
                -- 美女播报：roll结束声音
                if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                    if UnitName("player") == winner then
                        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\niyingle.ogg")
                    else
                        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\pmjs.ogg")
                    end
                end
                if timerFrame.currentAuctionLink then
                    -- 许愿消耗由许愿插件管理，此处不跟踪
                    MarkLinkAsSold(timerFrame.currentAuctionLink)
                end
                -- 最后一件装备：拍卖结算后3秒播放xykf.ogg（美女播报开启时，标记已拍后再判定）
                if UnitName("player") == auctionSender
                    and auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked()
                    and paiGetUnsoldItem() == nil then
                    PlayDelayedVoice("Interface\\AddOns\\XyTracker\\voice\\xykf.ogg", 3)
                end
                -- 先广播带链接的结算消息，让全员标记已拍，再清空本地状态
                if GetNumRaidMembers() > 0 and UnitName("player") == auctionSender then
                    SendAddonMessage("PP_ROLL_SETTLED", itemLink, "RAID")
                end
                timerFrame.currentAuctionLink = nil
                directRollMode = false  -- 直接roll结算完毕，恢复正常模式
                -- 转入 state=5，3秒倒计时后关闭（全体统一）
                timerFrame.state = 5
                timerFrame.startTime = GetTime()
            elseif table.getn(maxPlayers) >= 2 then
                -- 判断自己是否在roll名单中（拍卖人也要判断：不在名单就不显示roll界面）
                local myName = UnitName("player")
                local inRoll = false
                for _, n in ipairs(maxPlayers) do
                    if n == myName then inRoll = true; break end
                end
                -- 非拍卖者：不在roll名单中则直接退出
                if not inRoll and UnitName("player") ~= auctionSender then
                    HideAuctionAlert()
                    return
                end
                -- 多人同分，继续下一轮roll点
                rollNames = maxPlayers
                rollData = {}
                loothog_players = {}
                preRollData = {}
                local nameList = table.concat(maxPlayers, "、")
                if UnitName("player") == auctionSender then
                    SendChatMessage("现在请" .. nameList .. "进行下一轮roll点。", "RAID_WARNING", nil, nil)
                end
                timerFrame.state = 4
                timerFrame.startTime = now
                timerFrame.lastSent = now
                -- 美女播报：进入roll阶段(再次)
                if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                    PlayVoice("Interface\\AddOns\\XyTracker\\voice\\ksroll.ogg")
                end
                auctionAlertFrame._rollBgPlayed = false  -- 重置被超检测
                if auctionAlertFrame and auctionAlertFrame.earlyNoticeText then
                    auctionAlertFrame.earlyNoticeText:SetText("")
                end
                auctionAlertFrame.startTime = GetTime()
                auctionAlertFrame.totalTime = 10
                auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
                auctionAlertFrame.progressBar:SetValue(10)
                auctionAlertFrame.progressBar.timeText:SetText("10")
                auctionAlertFrame.rollText:SetText("")
                auctionAlertFrame.rollText:SetJustifyH("CENTER")
                -- 进入roll阶段说明已有出分，强制清除P标记
                ClearPMarkForCurrentItem()
                if inRoll then
                    -- 名单内：正常显示roll界面（P标记时隐藏，由frame2承接）
                    if IsCurrentItemPMarked() then
                        auctionAlertFrame:Hide()
                        if auctionAlertFrame2 then auctionAlertFrame2:Show() end
                    else
                        auctionAlertFrame:Show()
                    end
                else
                    -- 不在名单（如拍卖人未出分/非最高分）：不显示roll参与界面，只保留流程（喊话/广播/state=4照常）
                    auctionAlertFrame:Hide()
                end
                auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
                -- 恢复倒计时OnUpdate（可能被PP_AUCTION_END的HideAuctionAlert移除了）
                auctionAlertFrame:SetScript("OnUpdate", UpdateAuctionAlert)
                -- 重排按钮为roll阶段（隐藏出分/P按钮，只显示放大Roll按钮）
                SetRollPhaseButtons(true)
                -- 广播roll状态给全团（maxScore;hex名单：名单hex编码成纯ASCII传输，规避中文广播截断）
                if UnitName("player") == auctionSender then
                    local encNames = {}
                    for i = 1, table.getn(maxPlayers) do
                        table.insert(encNames, XyHexEncode(maxPlayers[i]))
                    end
                    SendAddonMessage("PP_AUCTION_ROLL", tostring(maxScore) .. ";" .. table.concat(encNames, ","), "RAID")
                end
            else
                -- 没人roll点，流拍
                local itemLink = timerFrame.currentAuctionLink or ""
                if GetNumRaidMembers() > 0 and UnitName("player") == auctionSender then
                    -- 流拍不入结算队列（按物品匹配，流拍物品没有对应记录，不会被误分）
                    SendChatMessage(itemLink .. "无人roll点，流拍！", "RAID_WARNING", nil, nil)
                    SendAddonMessage("PP_ROLL_SETTLED", itemLink, "RAID")
                end
                MarkLinkAsSold(timerFrame.currentAuctionLink)
                timerFrame.currentAuctionLink = nil
                timerFrame.state = 5
                timerFrame.startTime = now
                -- 最后一件装备：拍卖结算后3秒播放xykf.ogg（美女播报开启时，标记已拍后再判定）
                if UnitName("player") == auctionSender
                    and auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked()
                    and paiGetUnsoldItem() == nil then
                    PlayDelayedVoice("Interface\\AddOns\\XyTracker\\voice\\xykf.ogg", 3)
                end
                if auctionAlertFrame and auctionAlertFrame.earlyNoticeText then
                    auctionAlertFrame.earlyNoticeText:SetText("")
                end
                auctionAlertFrame.progressBar:SetValue(0)
                auctionAlertFrame.progressBar.timeText:SetText("0")
            end
        else
            -- roll countdown: shout when <=3s remaining
            if remaining <= 3 and now - timerFrame.lastSent >= 1 then
                timerFrame.lastSent = now
                local shoutNum = math.ceil(remaining)
                if shoutNum > 0 and auctionSender and UnitName("player") == auctionSender then
                    SendChatMessage(cn[shoutNum], "RAID", nil, nil)
                end
            end
                        auctionAlertFrame.progressBar:SetValue(remaining)
            local intRem = math.ceil(remaining)
            auctionAlertFrame.progressBar.timeText:SetText(intRem)
            -- roll阶段变色：<=5红，<=10黄，否则绿
            if remaining <= 5 then
                auctionAlertFrame.progressBar:SetStatusBarColor(1, 0.2, 0.2)
            elseif remaining <= 10 then
                auctionAlertFrame.progressBar:SetStatusBarColor(1, 0.8, 0.2)
            else
                auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
            end
        end
    elseif timerFrame.state == 5 then
        -- 3秒居显示后自动关闭
        if now - timerFrame.startTime >= 3 then
            HideAuctionAlert()
            timerFrame.state = 0
        end
    end
end)

-- ========== 团队频道链接捕获与状态管理 ==========

local capturedLinks = {}
local MAX_LINKS = 20
local EXPIRE_TIME = 600  -- 10分钟(秒)

-- 标记指定链接为已拍
function MarkLinkAsSold(link)
    if not link or link == "" then return end
    capturedLinks = capturedLinks or {}
    local found = false
    -- 从链接中提取物品名称
    local itemName = nil
    local _, _, name = string.find(link, "%[(.-)%]")
    if name then itemName = name end
    for i, data in ipairs(capturedLinks) do
        if data.link == link then
            data.sold = true
            found = true
            break
        end
        -- 如果精确匹配失败，尝试物品名称匹配
        if not found and itemName then
            local _, _, storedName = string.find(data.link, "%[(.-)%]")
            if storedName and storedName == itemName then
                data.sold = true
                found = true
                break
            end
        end
    end
    -- 手动输入的物品不在列表中，添加新记录
    if not found then
        table.insert(capturedLinks, 1, {
            link = link,
            time = time(),
            sender = "手动输入",
            sold = true
        })
    end
end

-- 监听团队聊天(用于捕获链接和自动标记)
local eventFrame = CreateFrame("Frame", "paipaiEventFrame", UIParent)
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    eventFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
eventFrame:SetScript("OnEvent", function()
    -- ADDON_LOADED: SavedVariables 在此事件后注入
    if event == "ADDON_LOADED" and arg1 == "XyTracker" then
        paipaiDB = paipaiDB or { quality = {}, showSold = true, quickFramePos = nil }
        for q = 0, 5 do
            if paipaiDB.quality[q] ~= nil then
                FILTER_QUALITY[q] = paipaiDB.quality[q]
            elseif q ~= 0 then
                FILTER_QUALITY[q] = true
            else
                FILTER_QUALITY[q] = false
            end
        end
        if paipaiDB.showSold ~= nil then FILTER_SOLD = paipaiDB.showSold end
        -- 刷新品质勾选框
        for q = 1, 5 do
            if filterCbs[q] and filterCbs[q].checkTex then
                if FILTER_QUALITY[q] then filterCbs[q].checkTex:Show() else filterCbs[q].checkTex:Hide() end
            end
        end
        -- 刷新已拍勾选框
        if _G.paipaiSoldCheck then
            if FILTER_SOLD then _G.paipaiSoldCheck:Show() else _G.paipaiSoldCheck:Hide() end
        end
        -- restore capturedLinks with sold flags
        if paipaiDB.capturedLinks then
            capturedLinks = paipaiDB.capturedLinks
        end

        -- P标记列表恢复
        if paipaiDB.pMarkedItems then pMarkedItems = paipaiDB.pMarkedItems end
        -- checkbox defaults
        if paipaiDB.sameScoreEnabled == nil then paipaiDB.sameScoreEnabled = false end
        if paipaiDB.voiceEnabled == nil then paipaiDB.voiceEnabled = nil end  -- nil=未勾选，true=勾选

        -- 恢复快拍界面位置（ADDON_LOADED 时 SavedVariables 已注入）
        if paipaiDB.quickFramePos and paipaiDB.quickFramePos.point then
            quickFrame:ClearAllPoints()
            quickFrame:SetPoint(paipaiDB.quickFramePos.point, UIParent, paipaiDB.quickFramePos.relPoint, paipaiDB.quickFramePos.x, paipaiDB.quickFramePos.y)
        end
        if paipaiDB.quickFrameHidden == nil then paipaiDB.quickFrameHidden = false end
        if GetNumRaidMembers() > 0 and IsRaidLeaderOrAssistant() then
            if not paipaiDB.quickFrameHidden then quickFrame:Show() end
        end
        return
    end

    -- 插件通信：接收拍卖通知
    if event == "CHAT_MSG_ADDON" then
        if arg1 == "PP_AUCTION_START" and arg2 and arg2 ~= "" then
auctionDismissed = false
            ShowAuctionAlert(arg2, arg4)
            -- 启动接收端的计时器，同步状态机
            timerFrame.currentAuctionLink = arg2
            timerFrame.state = 1
            timerFrame.startTime = GetTime()
            timerFrame:Show()
        elseif arg1 == "PP_ROLL_DIRECT" then
            -- 跳过出分阶段，直接全团roll（arg2=装备链接）
            if timerFrame.state == 5 then return end
            if not arg2 or arg2 == "" then return end
            auctionDismissed = false
            ShowAuctionAlert(arg2, arg4)
            directRollMode = true  -- 直接roll模式：结算不播报消费分数
            timerFrame.currentAuctionLink = arg2
            timerFrame.state = 4
            timerFrame.startTime = GetTime()
            timerFrame.lastSent = GetTime()
            timerFrame:Show()
            -- 全团名单（*ALL*语义：所有人都可以roll）
            rollNames = {}
            for i = 1, GetNumRaidMembers() do
                local name = GetRaidRosterInfo(i)
                if name then table.insert(rollNames, name) end
            end
            rollData = {}
            loothog_players = {}
            preRollData = {}
            if auctionAlertFrame then
                auctionAlertFrame.startTime = GetTime()
                auctionAlertFrame.totalTime = 10
                auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
                auctionAlertFrame.progressBar:SetValue(10)
                auctionAlertFrame.progressBar.timeText:SetText("10")
                auctionAlertFrame.rollText:SetText("")
                auctionAlertFrame.rollText:SetJustifyH("CENTER")
                -- 强制清除P标记（与PP_AUCTION_ROLL一致）
                ClearPMarkForCurrentItem()
                if IsCurrentItemPMarked() then
                    auctionAlertFrame:Hide()
                    if auctionAlertFrame2 then auctionAlertFrame2:Show() end
                else
                    auctionAlertFrame:Show()
                end
                auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
                if auctionAlertFrame.earlyNoticeText then
                    auctionAlertFrame.earlyNoticeText:SetText("")
                end
                auctionAlertFrame:SetScript("OnUpdate", UpdateAuctionAlert)
                SetRollPhaseButtons(true)
            end
            ClearPMarkForCurrentItem()
            if IsCurrentItemPMarked() then
                if auctionAlertFrame2 then auctionAlertFrame2:Show() end
            else
                if auctionAlertFrame2 then auctionAlertFrame2:Hide() end
            end
            if auctionAlertFrame3 and PaiFloatChainVisible() then
                auctionAlertFrame3:Show()
            end
        elseif arg1 == "PP_AUCTION_CANCEL" then
            -- 拍卖取消，无条件关闭
            HideAuctionAlert()
        elseif arg1 == "PP_AUCTION_END" then
            -- PP_AUCTION_END由全员广播，网络延迟会导致在roll阶段仍收到，跳过以免隐藏roll界面
            if timerFrame.state < 4 then
                HideAuctionAlert()
            end
        elseif arg1 == "PP_ROLL_SETTLED" then
            -- roll点结算，所有人统一进入3秒倒计时，并标记已拍
            if arg2 and arg2 ~= "" then
                MarkLinkAsSold(arg2)
            end
            timerFrame.currentAuctionLink = arg2
            timerFrame.state = 5
            timerFrame.startTime = GetTime()
            -- 最后一件装备：拍卖结算后3秒播放xykf.ogg（美女播报开启时，标记已拍后再判定）
            if UnitName("player") == auctionSender
                and auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked()
                and paiGetUnsoldItem() == nil then
                PlayDelayedVoice("Interface\\AddOns\\XyTracker\\voice\\xykf.ogg", 3)
            end
        elseif arg1 == "PP_AUCTION_RESET" then
            -- 仅在出分/倒计时阶段重置，roll或结算阶段忽略（防网络延迟消息切回出分界面）
            if timerFrame.state ~= 1 and timerFrame.state ~= 2 then return end
            -- someone bid/roll: reset timer to 10s for everyone
            timerFrame.state = 1
            timerFrame.startTime = GetTime()
            if auctionAlertFrame then
                auctionAlertFrame.totalTime = 10
                auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
                auctionAlertFrame.progressBar:SetValue(10)
                auctionAlertFrame.progressBar.timeText:SetText("10")
                auctionAlertFrame.startTime = GetTime()
                if auctionAlertFrame.earlyNoticeText then
                    auctionAlertFrame.earlyNoticeText:SetText(arg2 ~= "" and "有人出分，重新开始倒计时" or "")
                end
                -- sync bidData from broadcast (skip auctioneer, they maintain bidData themselves)
                if UnitName("player") ~= auctionSender and arg2 and arg2 ~= "" then
                    bidData = {}
                    for part in string.gmatch(arg2, "[^,]+") do
                        local ci = string.find(part, ":")
                        if ci then
                            table.insert(bidData, {name = string.sub(part, 1, ci-1), score = tonumber(string.sub(part, ci+1)) or 0})
                        end
                    end
                    UpdateBidText()
                    CheckBidBeat()
                end
            end
        elseif arg1 == "PP_AUCTION_ROLL" then
            -- 结算阶段忽略积压的roll广播（防网络延迟切回roll界面）
            if timerFrame.state == 5 then return end
            -- 从广播解析roll名单（全团同步，供roll记录校验）
            rollNames = {}
            local isAllRaidRoll = (arg2 == "*ALL*")
            if isAllRaidRoll then
                -- 全团roll：名单=全团所有人（40人名单广播超长，用"*ALL*"标记代替）
                for i = 1, GetNumRaidMembers() do
                    local name = GetRaidRosterInfo(i)
                    if name then table.insert(rollNames, name) end
                end
            else
                -- 新版广播格式：maxScore;hex名,hex名,...（分号分隔分数，逗号分隔hex名单，纯ASCII防截断）
                local scorePart, namePart = string.match(arg2 or "", "^(%d+);(.+)$")
                if scorePart then
                    for encName in string.gmatch(namePart, "[^,]+") do
                        local n = XyHexDecode(encName)
                        if n and n ~= "" then table.insert(rollNames, n) end
                    end
                else
                    -- 旧格式广播（顿号分隔中文名）：兼容解析
                    for name in string.gmatch(arg2 or "", "[^、]+") do
                        table.insert(rollNames, name)
                    end
                end
            end
            -- 名单里没自己名字就不弹roll界面（名单已hex解码，精确比对）
            if not isAllRaidRoll then
                local myName = UnitName("player")
                local inRoll = false
                for _, n in ipairs(rollNames) do
                    if n == myName then inRoll = true break end
                end
                if not inRoll then return end
            end
            -- roll phase broadcast: sync state=4 for non-auctioneer
            timerFrame.state = 4
            timerFrame.startTime = GetTime()
            timerFrame.lastSent = GetTime()
            rollData = {}
            loothog_players = {}
            if auctionAlertFrame then
                auctionAlertFrame.startTime = GetTime()
                auctionAlertFrame.totalTime = 10
                auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
                auctionAlertFrame.progressBar:SetValue(10)
                auctionAlertFrame.progressBar.timeText:SetText("10")
                auctionAlertFrame.rollText:SetText("")
                auctionAlertFrame.rollText:SetJustifyH("CENTER")
                -- 进入roll阶段说明已有出分，强制清除P标记（解决非发起者P标记未被清除导致界面不显示）
                ClearPMarkForCurrentItem()
                if IsCurrentItemPMarked() then
                    auctionAlertFrame:Hide()
                    if auctionAlertFrame2 then auctionAlertFrame2:Show() end
                else
                    auctionAlertFrame:Show()
                end
                auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
                if auctionAlertFrame.earlyNoticeText then
                    auctionAlertFrame.earlyNoticeText:SetText("")
                end
                -- 恢复倒计时OnUpdate（可能被PP_AUCTION_END的HideAuctionAlert移除了）
                auctionAlertFrame:SetScript("OnUpdate", UpdateAuctionAlert)
                -- 直接重排按钮为roll阶段（防止_lastStopState检测存在时序问题）
                SetRollPhaseButtons(true)
            end
            -- 进入roll阶段说明已有出分，强制清除P标记（解决非发起者P标记未被清除导致界面不显示）
            ClearPMarkForCurrentItem()
            -- P标记检查：隐藏Frame1则显示Frame2，否则隐藏Frame2
            if IsCurrentItemPMarked() then
                if auctionAlertFrame2 then auctionAlertFrame2:Show() end
            else
                if auctionAlertFrame2 then auctionAlertFrame2:Hide() end
            end
            if auctionAlertFrame3 and PaiFloatChainVisible() then
                auctionAlertFrame3:Show()
            end
        elseif arg1 == "PP_AUCTION_EARLY" then
            if auctionAlertFrame and auctionAlertFrame:IsVisible() then
                if timerFrame.state == 4 then
                    -- roll点阶段: 同步跳转到最后3秒倒计时
                    local now = GetTime()
                    timerFrame.startTime = now - (auctionAlertFrame.totalTime - 3)
                    auctionAlertFrame.startTime = timerFrame.startTime
                    timerFrame.lastSent = now
                    if auctionAlertFrame.earlyNoticeText then
                        auctionAlertFrame.earlyNoticeText:SetText(arg2 .. "提前开始了roll点倒计时")
                    end
                    -- 美女播报：倒计时开始
                    if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\3s.ogg")
                    end
                else
                    -- 出分阶段提前结束：同步到倒计时阶段
                    timerFrame.state = 2
                    timerFrame.startTime = GetTime()
                    timerFrame.countdown = 2  -- 团长已经发了"三"，从二开始倒数
                    timerFrame.lastSent = timerFrame.startTime
                    timerFrame:Show()
                    -- 美女播报：倒计时开始
                    if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
                        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\3s.ogg")
                    end
                    -- 进度条同步
                    auctionAlertFrame.totalTime = 3
                    auctionAlertFrame.progressBar:SetMinMaxValues(0, 3)
                    auctionAlertFrame.progressBar:SetValue(3)
                    auctionAlertFrame.progressBar.timeText:SetText("3")
                    auctionAlertFrame.startTime = GetTime()
                    if auctionAlertFrame.earlyNoticeText then
                        auctionAlertFrame.earlyNoticeText:SetText(arg2 .. "提前开始了倒计时")
                    end
                end
            end
        elseif arg1 == "PP_AUCTION_SOLD" and arg2 and arg2 ~= "" then
            -- 其他助理标记已拍，本地同步
            MarkLinkAsSold(arg2)
        end
        return
    end

    -- 物品信息到达，刷新弹窗图标
    if event == "GET_ITEM_INFO_RECEIVED" then
        if auctionAlertFrame and auctionAlertFrame:IsVisible() and auctionAlertFrame.icon and auctionAlertFrame.icon.itemLink then
            local iconTexture, _ = GetItemIconFromLink(auctionAlertFrame.icon.itemLink)
            if iconTexture and iconTexture ~= "" then
                auctionAlertFrame.icon:SetNormalTexture(iconTexture)
                auctionAlertFrame.icon.itemLink = nil
            end
        end
        return
    end

    local msg = arg1
    local sender = arg2
    local currentTime = time()  -- 使用系统时间戳

    -- 记录出分（拍卖进行中时，检测纯数字）
 if auctionActive and sender then
 local number = tonumber(msg)
 -- P/p/0 = pass, remove bidder from bidData to avoid stale records triggering roll
 if msg == "P" or msg == "p" or msg == "0" then
 if UnitName("player") == auctionSender then
 for i = table.getn(bidData), 1, -1 do
 if bidData[i].name == sender then
 table.remove(bidData, i)
 end
 end
 UpdateBidText()
 -- broadcast updated bidData to all
 if timerFrame.state == 1 or timerFrame.state == 2 then
 timerFrame.state = 1; timerFrame.startTime = GetTime(); auctionAlertFrame.totalTime = 10; auctionAlertFrame.progressBar:SetMinMaxValues(0, 10); auctionAlertFrame.progressBar:SetValue(10); auctionAlertFrame.progressBar.timeText:SetText("10"); auctionAlertFrame.startTime = GetTime(); SendAddonMessage("PP_AUCTION_RESET",(function() local _p={};for _,b in ipairs(bidData) do table.insert(_p,b.name..":"..b.score) end;return table.concat(_p,",") end)(),"RAID")
 end
 end
 return
 end
 if number and (number >= 1 and number <= 9) then
 -- 检查分数是否有效，无效则直接丢弃（仅发起者执行检查）
 if UnitName("player") == auctionSender then
     -- 读取玩家dkp
     local playerDkp = 0
     if XyArray then
         for j = 1, table.getn(XyArray) do
             if XyArray[j]["name"] == sender then
                 playerDkp = tonumber(XyArray[j]["dkp"]) or 0
                 break
             end
         end
     end
     if number >= 5 then
         -- 许愿校验：当前拍卖装备必须是该玩家的许愿装备
         if not IsCurrentItemMyWish(sender) then
             SendChatMessage("警告，" .. sender .. "当前拍卖装备不是其许愿装备，出分" .. number .. "分无效", "RAID")
             return
         end
         if number > playerDkp + 5 then
             SendChatMessage("警告，" .. sender .. "分数仅剩" .. playerDkp .. "分，含许愿上限" .. (playerDkp + 5) .. "分，不足" .. number .. "分", "RAID")
             return
         end
         else
         if number > playerDkp then
             SendChatMessage("警告，" .. sender .. "分数仅剩" .. playerDkp .. "分，不足" .. number .. "分", "RAID")
             return
         end
     end
 end
 -- 仅拍卖者维护 bidData，其他人由 PP_AUCTION_RESET 广播同步面板
 if UnitName("player") == auctionSender then
 -- 检查是否已存在该玩家的出分记录，有则覆盖
 local found = false
 for i = 1, table.getn(bidData) do
 if bidData[i].name == sender then
 bidData[i].score = number
 found = true
 break
 end
 end
 -- 如果不存在，新增记录
 if not found then
 table.insert(bidData, {name = sender, score = number})
 end
 if timerFrame.state == 1 or timerFrame.state == 2 then timerFrame.state = 1; timerFrame.startTime = GetTime(); auctionAlertFrame.totalTime = 10; auctionAlertFrame.progressBar:SetMinMaxValues(0, 10); auctionAlertFrame.progressBar:SetValue(10); auctionAlertFrame.progressBar.timeText:SetText("10"); auctionAlertFrame.startTime = GetTime(); SendAddonMessage("PP_AUCTION_RESET",(function() local _p={};for _,b in ipairs(bidData) do table.insert(_p,b.name..":"..b.score) end;return table.concat(_p,",") end)(),"RAID") end
 UpdateBidText()
 if sender == UnitName("player") then
     ClearPMarkForCurrentItem()  -- 自己出分，清除P标记
 end
 CheckBidBeat()
  end
  end
  end

    capturedLinks = capturedLinks or {}

    -- 跳过许愿消息(XY ZZZ / xy ZZZ)，不记录进拍卖
    if not string.find(msg, "XY ") and not string.find(msg, "xy ") then
    -- 1. 捕获消息中的物品链接
    for link in string.gmatch(msg, "|c.-|Hitem:%d+.-|r") do
        -- 去重:删除相同链接(保留最新)
        for i = table.getn(capturedLinks), 1, -1 do
            if capturedLinks[i].link == link then
                table.remove(capturedLinks, i)
                break
            end
        end
        -- 插入新记录(默认未拍卖)
        table.insert(capturedLinks, 1, {
            link = link,
            time = currentTime,
            sender = sender,
            sold = false
        })

    -- 检测"恭喜！XXX赢得了[XXX]"并标记已拍
 if string.find(msg, "恭喜！.*赢得了") then
 local _, _, itemLink = string.find(msg, "赢得了(.-)，消费")
 if itemLink then
 MarkLinkAsSold(itemLink)
 end
 -- 发送者=拍卖发起者（可能是团长或助理），非发起者收到结算消息时补写本地结算记录，供"按拍卖分配"使用
 -- 发起者本人本地结算时已写入，这里跳过发送者自己防止重复
 if sender and sender ~= UnitName("player") then
    local _, _, winner = string.find(msg, "恭喜！(.+)赢得了")
    if winner and link then
        table.insert(XyLastAuctionResults, { winner = winner, itemLink = link })
        if table.getn(XyLastAuctionResults) > 20 then table.remove(XyLastAuctionResults, 1) end
    end
 end
 elseif string.find(msg, "无人问津") then
 local _, _, itemLink = string.find(msg, "(.-)无人问津")
 if itemLink then
 MarkLinkAsSold(itemLink)
 end
 end
    end
    end


    -- 限制数量并清理过期(新消息触发时顺便清理)
    while table.getn(capturedLinks) > MAX_LINKS do
        table.remove(capturedLinks)
    end
    for i = table.getn(capturedLinks), 1, -1 do
        local t = capturedLinks[i].time
        if not t or currentTime - t > EXPIRE_TIME then
            table.remove(capturedLinks, i)
        end
    end
end)

-- 定期清理过期链接(即使没有新消息,也每60秒清理一次)
local cleanupFrame = CreateFrame("Frame")
local cleanupTimer = 0
cleanupFrame:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0
    cleanupTimer = cleanupTimer + elapsed
    if cleanupTimer >= 60 then  -- 每分钟检查一次
        cleanupTimer = 0
        paipaiDB = paipaiDB or { quality = {}, showSold = true, quickFramePos = nil }
            paipaiDB.capturedLinks = capturedLinks  -- periodic save
            paipaiDB.pMarkedItems = pMarkedItems  -- periodic save
        local currentTime = time()
        capturedLinks = capturedLinks or {}
        for i = table.getn(capturedLinks), 1, -1 do
            local t = capturedLinks[i].time
            if not t or currentTime - t > EXPIRE_TIME then
                table.remove(capturedLinks, i)
            end
        end
    end
end)

-- 链接选择面板(宽度加大)
local function CreateLinkList()
    if linkListFrame then
        linkListFrame:Refresh()
        linkListFrame:Show()
        return
    end
    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetWidth(250)          -- 加大宽度
    frame:SetHeight(400)
    frame:SetScale(XyScreenScale)
    frame:SetPoint("TOPLEFT", itemBtn, "right", 0, 0)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:EnableMouse(true)
    frame:SetMovable(false)
    frame:Hide()

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)
    close:SetScript("OnClick", function() frame:Hide() end)
    frame.closeBtn = close   -- <-- 添加这行

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -10)
    title:SetText("团队频道物品链接")

    local content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", 10, -30)
    content:SetPoint("BOTTOMRIGHT", -10, 10)

    local function RefreshList()
        -- 销毁所有子对象
        for _, child in pairs({content:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        local offsetY = 0
        local itemHeight = 20
        local visibleCount = 0

                capturedLinks = capturedLinks or {}

        -- 第一轮：未拍物品
        for i, data in ipairs(capturedLinks) do
            repeat
                if data.sold then break end
                if not IsLinkVisible(data.link, false) then break end

            local itemFrame = CreateFrame("Frame", nil, content)
            itemFrame:SetWidth(220)
            itemFrame:SetHeight(itemHeight)
            itemFrame:SetPoint("TOPLEFT", 0, -offsetY)
            itemFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            })
            itemFrame:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
            itemFrame:EnableMouse(true)

            itemFrame.link = data.link

            local name = string.match(data.link, "%[(.+)%]") or data.link
            local timeStr = date("%m-%d %H:%M", data.time)
            local displayText = timeStr .. " " .. name

            local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", 5, 0)
            text:SetText(displayText)
            text:SetJustifyH("LEFT")

            itemFrame:SetScript("OnMouseDown", function()
                input:SetText(itemFrame.link)
                frame:Hide()
                -- 快拍模式才自动开始拍卖
                if timerFrame and timerFrame.state >= 1 and timerFrame.state <= 4 then
                    UIErrorsFrame:AddMessage("当前有拍卖正在进行，请等待结束后再发起。", 1.0, 0.0, 0.0, 1.0)
                    return
                end
                if linkListFrame.isQuickMode then
                    if GetNumRaidMembers() > 0 then
                        SendChatMessage("现在开始拍卖" .. itemFrame.link, "RAID_WARNING", nil, nil)
                        SendAddonMessage("PP_AUCTION_START", itemFrame.link, "RAID")
        auctionSender = UnitName("player")  -- 标记自己为发起者
                        timerFrame.currentAuctionLink = itemFrame.link
                        auctionDismissed = false
                        ShowAuctionAlert(itemFrame.link, UnitName("player"))
                        timerFrame:Hide()
                        timerFrame.state = 1
                        timerFrame.startTime = GetTime()
                        timerFrame:Show()
                    end
                end
            end)

            offsetY = offsetY + itemHeight
            visibleCount = visibleCount + 1
            until true
        end

        -- 第二轮：已拍物品（灰色显示，置于底部）
        for i, data in ipairs(capturedLinks) do
            repeat
                if not data.sold then break end
                if linkListFrame.hideSold then break end
                if not IsLinkVisible(data.link, true) then break end

            local itemFrame = CreateFrame("Frame", nil, content)
            itemFrame:SetWidth(220)
            itemFrame:SetHeight(itemHeight)
            itemFrame:SetPoint("TOPLEFT", 0, -offsetY)
            itemFrame:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            })
            itemFrame:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            itemFrame:EnableMouse(true)

            itemFrame.link = data.link

            local name = string.match(data.link, "%[(.+)%]") or data.link
            local timeStr = date("%m-%d %H:%M", data.time)
            local displayText = "(已拍) " .. timeStr .. " " .. name

            local text = itemFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", 5, 0)
            text:SetText(displayText)
            text:SetJustifyH("LEFT")
            text:SetTextColor(0.5, 0.5, 0.5)

 itemFrame:SetScript("OnMouseDown", function()
 input:SetText(itemFrame.link)
 frame:Hide()
                -- 快拍模式才自动开始拍卖
                if timerFrame and timerFrame.state >= 1 and timerFrame.state <= 4 then
                    UIErrorsFrame:AddMessage("当前有拍卖正在进行，请等待结束后再发起。", 1.0, 0.0, 0.0, 1.0)
                    return
                end
                if linkListFrame.isQuickMode then
                    if GetNumRaidMembers() > 0 then
                        SendChatMessage("现在开始拍卖" .. itemFrame.link, "RAID_WARNING", nil, nil)
                        SendAddonMessage("PP_AUCTION_START", itemFrame.link, "RAID")
        auctionSender = UnitName("player")  -- 标记自己为发起者
                        timerFrame.currentAuctionLink = itemFrame.link
                        auctionDismissed = false
                        ShowAuctionAlert(itemFrame.link, UnitName("player"))
                        timerFrame:Hide()
                        timerFrame.state = 1
                        timerFrame.startTime = GetTime()
                        timerFrame:Show()
                    end
                end
            end)

            offsetY = offsetY + itemHeight
            visibleCount = visibleCount + 1
            until true
        end

        if visibleCount == 0 then
            local text = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("TOPLEFT", 0, 0)
            --text:SetText("暂无符合条件的物品链接")
        end

        frame:SetHeight(math.min(300, 40 + visibleCount * itemHeight))
    end

    -- 应用 pfUI 皮肤（如果存在）
    if ApplyAuctionSkin then ApplyAuctionSkin(frame) end

    frame:SetScript("OnShow", RefreshList)

    linkListFrame = frame
    linkListFrame.Refresh = RefreshList
end

function ShowLinkList(anchorFrame, hideSold, isQuickMode)
    -- set attrs before CreateLinkList to fix refresh lag
    if linkListFrame then
        linkListFrame.hideSold = hideSold
        linkListFrame.isQuickMode = isQuickMode
    end
    CreateLinkList()
    -- linkListFrame now exists, set attrs again for first-time init
    linkListFrame.hideSold = hideSold
    linkListFrame.isQuickMode = isQuickMode
    linkListFrame:ClearAllPoints()
    if anchorFrame then
        if linkListFrame.isQuickMode then
            linkListFrame:SetPoint("TOPLEFT", anchorFrame, "LEFT", 0, -5)
        else
            linkListFrame:SetPoint("TOPLEFT", anchorFrame, "RIGHT", 0, 0)
        end
    else
        linkListFrame:SetPoint("TOPLEFT", itemBtn, "RIGHT", 0, 0)
    end
    linkListFrame:Show()
end

-- 斜杠命令

-- 插件加载完成提示

-- ========= 拍卖提示框（插件通信）=========


-- 监听roll点结果
local rollEventFrame = CreateFrame("Frame")
local loothog_rollPattern = "(.+)掷出(%d+)（(%d+)-(%d+)）"
-- loothog_players 已移到文件顶部定义

rollEventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
rollEventFrame:SetScript("OnEvent", function()
    if timerFrame.state ~= 1 and timerFrame.state ~= 2 and timerFrame.state ~= 4 then return end
    local msg = arg1
    local player, rollNum, minRoll, maxRoll
    if string.find(msg, loothog_rollPattern) then
        _, _, player, rollNum, minRoll, maxRoll = string.find(msg, loothog_rollPattern)
    else
        return
    end
    -- 验证范围(1-100)
    rollNum = tonumber(rollNum)
    minRoll = tonumber(minRoll)
    maxRoll = tonumber(maxRoll)
    if not rollNum or not minRoll or not maxRoll then return end
    if rollNum < 1 or rollNum > 100 then return end
    if minRoll ~= 1 or maxRoll ~= 100 then return end

    -- 出分阶段（state 1/2）：玩家常提前roll（抢跑），先预收集每人第一次roll，进入roll阶段时再筛选采纳
    if timerFrame.state == 1 or timerFrame.state == 2 then
        for i = 1, table.getn(preRollData) do
            if preRollData[i].name == player then
                return  -- 只认第一次roll，重复roll一律忽略
            end
        end
        table.insert(preRollData, {name = player, roll = rollNum})
        return
    end

    -- 只接受在roll名单内的玩家
    local inRollList = false
    for _, v in ipairs(rollNames) do if v == player then inRollList = true; break end end
    if not inRollList then return end
    -- 已记录过（含出分阶段预roll迁移）：每人只认第一次roll，重复roll一律忽略（防止反复roll刷高分）
    if loothog_players[player] then
        return
    end
    -- 记录（每个玩家只记第一次roll）
    loothog_players[player] = true
    table.insert(rollData, {name = player, roll = rollNum})
        -- 新roll重置10秒倒计时（重复roll不重置，loothog已在上方拦截）
        if timerFrame.state == 4 then
            timerFrame.startTime = GetTime()
            timerFrame.lastSent = GetTime()
            auctionAlertFrame.totalTime = 10
            auctionAlertFrame.startTime = GetTime()
            auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
            auctionAlertFrame.progressBar:SetValue(10)
            auctionAlertFrame.progressBar.timeText:SetText("10")
            auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
        end
        -- 记录自己的roll
        if player == UnitName("player") then
            myRoll = rollNum
            -- 我roll了：检查是否已有人roll得更高，是则直接播rollbg.ogg
            if not auctionAlertFrame._rollBgPlayed
                and auctionAlertFrame and auctionAlertFrame.voiceCheck
                and auctionAlertFrame.voiceCheck:GetChecked() then
                for _, v in ipairs(rollData) do
                    if v.name ~= UnitName("player") and v.roll > myRoll then
                        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\rollbg.ogg")
                        auctionAlertFrame._rollBgPlayed = true
                        break
                    end
                end
            end
        end
    -- 美女播报：被超roll（别人roll时我的点数已被碾压，每阶段仅一次）
    if player ~= UnitName("player") and myRoll and rollNum > myRoll
            and auctionAlertFrame and auctionAlertFrame.voiceCheck
            and auctionAlertFrame.voiceCheck:GetChecked()
            and not auctionAlertFrame._rollBgPlayed then
        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\rollbg.ogg")
        auctionAlertFrame._rollBgPlayed = true
    end
    UpdateRollText()
end)

-- 拍卖权限检测：仅团长/助理可见 quickFrame 和 AuctionFrame
local auctionPermFrame = CreateFrame("Frame")
auctionPermFrame:RegisterEvent("RAID_ROSTER_UPDATE")
auctionPermFrame:RegisterEvent("UNIT_FLAGS")  -- 权限变更（如被设为助理）
auctionPermFrame:RegisterEvent("PARTY_LEADER_CHANGED")
auctionPermFrame:SetScript("OnEvent", function()
    -- UNIT_FLAGS 只处理玩家自己
    if event == "UNIT_FLAGS" and arg1 ~= "player" then return end
    if GetNumRaidMembers() == 0 then
        if quickFrame then quickFrame:Hide() end
        AuctionFrame:Hide()
    elseif IsRaidLeaderOrAssistant() then
        if quickFrame and not paipaiDB.quickFrameHidden then quickFrame:Show() end
    else
        if quickFrame then quickFrame:Hide() end
        AuctionFrame:Hide()
    end
end)



-- =========================================================================
-- /pp quick auction command: reuse auctionBtn's click flow, zero intrusion
-- Type /pp or /PP, auto-auction the first unsold item in capturedLinks
-- Does NOT affect existing UI/manual button behavior; only adds a text entry
-- =========================================================================
local function paipai_quick_auction(msg)
    -- /xypm reset：所有图标回归默认位置
    if msg then
        local m = string.gsub(msg, "^%s*(.-)%s*$", "%1")
        if m == "reset" then
            ResetAllIconPositions()
            return
        end
    end
    -- 0. Guard: only raid leader or assistant
    if not IsRaidLeaderOrAssistant() then
        UIErrorsFrame:AddMessage("你不是团长或者助理，没有权限", 1.0, 0.0, 0.0, 1.0)
        return
    end
    -- 1. Guard: refuse if an auction is already running
    if timerFrame and timerFrame.state and timerFrame.state >= 1 and timerFrame.state <= 4 then
        UIErrorsFrame:AddMessage("拍卖进行中，请等待当前拍卖结束！", 1.0, 0.0, 0.0, 1.0)
    DEFAULT_CHAT_FRAME:AddMessage("[拍卖] 拍卖进行中，请等待当前拍卖结束！", 1.0, 0.82, 0.0)
        return
    end

    -- 2. Check captured list is not empty
    capturedLinks = capturedLinks or {}
    if table.getn(capturedLinks) == 0 then
        UIErrorsFrame:AddMessage("暂无未拍物品！", 1.0, 0.0, 0.0, 1.0)
    DEFAULT_CHAT_FRAME:AddMessage("[拍卖] 暂无未拍物品！", 1.0, 0.82, 0.0)
        return
    end

    -- 3. Walk from the head, pick first entry where sold is not true
    local target = nil
    for i = table.getn(capturedLinks), 1, -1 do
        local data = capturedLinks[i]
        if data and data.link and data.sold ~= true then
            target = data
            break
        end
    end

    if not target then
        UIErrorsFrame:AddMessage("暂无未拍物品！", 1.0, 0.0, 0.0, 1.0)
        return
    end

    -- 4. Write link into input box and trigger existing auctionBtn click.
    --    === Reuse existing logic, no code duplication, no drift risk ===
    input:SetText(target.link)
    auctionBtn:Click()
end

SLASH_PP1 = "/xypm"
SLASH_PP2 = "/XYPM"
SLASH_PP3 = "/拍装备"
SlashCmdList["PP"] = paipai_quick_auction


-- =============================================================
-- ========= 拍卖浮动图标 ======================================
-- =============================================================
local paiFloatBtn = CreateFrame("Button", nil, UIParent)
paiFloatBtn:SetWidth(64)
paiFloatBtn:SetHeight(64)
paiFloatBtn:SetScale(XyScreenScale)
paiFloatBtn:SetPoint("CENTER", 0, 0)
paiFloatBtn:SetMovable(true)
paiFloatBtn:SetFrameStrata("DIALOG")
paiFloatBtn:Hide()  -- 默认隐藏，仅通过小地图按钮或权限+未隐藏时显示

-- 贴图标，清空默认背景
paiFloatBtn:SetNormalTexture(nil)
paiFloatBtn:SetHighlightTexture(nil)
paiFloatBtn:SetPushedTexture(nil)

local paiFloatIcon = paiFloatBtn:CreateTexture(nil, "ARTWORK")
paiFloatIcon:SetTexture("Interface\\AddOns\\XyTracker\\Images\\pai")
paiFloatIcon:SetAllPoints(paiFloatBtn)

-- "拍"字叠层（有物品时显示；已forward声明，此处不再local）
paiFloatLabel = paiFloatBtn:CreateFontString(nil, "OVERLAY")
paiFloatLabel:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
paiFloatLabel:SetText("待拍")
paiFloatLabel:SetTextColor(1, 0.5, 0, 1)
paiFloatLabel:SetPoint("TOP", paiFloatBtn, "TOP", 0, -4)
paiFloatLabel:Hide()

-- 追踪当前显示的物品
paiFloatBtn.currentItemLink = nil
paiFloatBtn.currentItemId = nil

-- ========== 直接roll按钮（跳过出分阶段，直接全团roll） ==========
-- 与pai.tga左对齐，底部距离pai.tga顶部3像素（即按钮位于图标上方）；作为paiFloatBtn子帧，跟随显隐与拖动
local directRollBtn = CreateFrame("Button", nil, paiFloatBtn, "UIPanelButtonTemplate")
directRollBtn:SetWidth(64)
directRollBtn:SetHeight(20)
directRollBtn:SetPoint("BOTTOM", paiFloatBtn, "TOP", 0, 3)
directRollBtn:SetText("直接roll")
-- 悬停提示
directRollBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(directRollBtn, "ANCHOR_RIGHT")
    GameTooltip:SetText("点击直接roll此件装备", 1, 1, 1)
    GameTooltip:Show()
end)
directRollBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- 跳过出分阶段，直接对当前待拍装备发起全团roll点（40人全团roll，不按名单逐个播报）
function StartAllRaidRoll()
    -- 按钮只在非拍卖阶段显示，此处防御：拍卖进行中不可再发起
    if timerFrame and timerFrame.state and timerFrame.state >= 1 and timerFrame.state <= 5 then
        UIErrorsFrame:AddMessage("拍卖进行中，无法直接roll。", 1.0, 0.0, 0.0, 1.0)
        return
    end
    if not IsRaidLeaderOrAssistant() then
        UIErrorsFrame:AddMessage("你不是团长或者助理，没有权限", 1.0, 0.0, 0.0, 1.0)
        return
    end
    if GetNumRaidMembers() == 0 then
        UIErrorsFrame:AddMessage("不在团队中，无法全团roll。", 1.0, 0.0, 0.0, 1.0)
        return
    end
    -- 当前待拍装备（第一个未拍物品）
    local itemLink = paiGetUnsoldItem()
    if not itemLink or itemLink == "" then
        UIErrorsFrame:AddMessage("暂无待拍装备，无法直接roll。", 1.0, 0.0, 0.0, 1.0)
        return
    end
    local now = GetTime()
    -- 建立完整拍卖上下文（发起者、清空出分/roll记录、创建并显示拍卖界面）
    auctionDismissed = false
    ShowAuctionAlert(itemLink, UnitName("player"))
    directRollMode = true  -- 直接roll模式：结算不播报消费分数
    timerFrame.currentAuctionLink = itemLink
    -- 全团名单（直接取团队名单，40人）
    rollNames = {}
    for i = 1, GetNumRaidMembers() do
        local name = GetRaidRosterInfo(i)
        if name then table.insert(rollNames, name) end
    end
    rollData = {}
    loothog_players = {}
    preRollData = {}
    -- 全团roll喊话：不按名单逐个播报（40人太多）
    SendChatMessage("现在开始全团roll" .. itemLink .. "装备，有需要的roll", "RAID_WARNING", nil, nil)
    timerFrame.state = 4
    timerFrame.startTime = now
    timerFrame.lastSent = now
    timerFrame:Show()
    -- 美女播报：进入roll阶段
    if auctionAlertFrame and auctionAlertFrame.voiceCheck and auctionAlertFrame.voiceCheck:GetChecked() then
        PlayVoice("Interface\\AddOns\\XyTracker\\voice\\ksroll.ogg")
    end
    if auctionAlertFrame then
        auctionAlertFrame._rollBgPlayed = false
        if auctionAlertFrame.earlyNoticeText then
            auctionAlertFrame.earlyNoticeText:SetText("")
        end
        auctionAlertFrame.startTime = GetTime()
        auctionAlertFrame.totalTime = 10
        auctionAlertFrame.progressBar:SetMinMaxValues(0, 10)
        auctionAlertFrame.progressBar:SetValue(10)
        auctionAlertFrame.progressBar.timeText:SetText("10")
        auctionAlertFrame.rollText:SetText("")
        auctionAlertFrame.rollText:SetJustifyH("CENTER")
        -- 进入roll阶段说明已有出分，强制清除P标记
        ClearPMarkForCurrentItem()
        if IsCurrentItemPMarked() then
            auctionAlertFrame:Hide()
            if auctionAlertFrame2 then auctionAlertFrame2:Show() end
        else
            auctionAlertFrame:Show()
        end
        auctionAlertFrame.progressBar:SetStatusBarColor(0.2, 0.8, 0.2)
        -- 恢复倒计时OnUpdate（可能被PP_AUCTION_END的HideAuctionAlert移除了）
        auctionAlertFrame:SetScript("OnUpdate", UpdateAuctionAlert)
        -- 重排按钮为roll阶段（隐藏出分/P按钮，只显示放大Roll按钮）
        SetRollPhaseButtons(true)
    end
    -- 广播全团roll：跳过出分直接roll（携带装备链接，接收端据此建立拍卖上下文）
    SendAddonMessage("PP_ROLL_DIRECT", itemLink, "RAID")
end

directRollBtn:SetScript("OnClick", function()
    StartAllRaidRoll()
end)

-- ========= 浮动图标链可见性判定与整体隐藏 =========
-- 可见性规则：
--   1) 不在团队或非团长/助理 → 不可见
--   2) 用户主动隐藏（shift+左键 或 小地图点击隐藏）→ 不可见
--   3) 团长/助理具有许愿权（XyTracker_GetLeaderName() == 玩家名）→ 可见
--   4) 团长/助理无许愿权 → 默认隐藏，仅当点击过小地图按钮(paiFloatShown)才可见
function PaiFloatChainVisible()
    if GetNumRaidMembers() == 0 or not IsRaidLeaderOrAssistant() then return false end
    paipaiDB = paipaiDB or {}
    if paipaiDB.paiFloatHidden then return false end
    if XyTracker_GetLeaderName and XyTracker_GetLeaderName() == UnitName("player") then
        return true
    end
    return paipaiDB.paiFloatShown == true
end

-- 隐藏浮动图标及其全部联动元素（frame3、拍卖中stop图标、右侧stop图标）
-- paiFloatBtn 隐藏后其子帧（直接roll按钮、待拍文字）自动跟随隐藏
function HidePaiFloatChain()
    if auctionAlertFrame3 then auctionAlertFrame3:Hide() end
    if XyPaiStopIcon then XyPaiStopIcon:Hide() end
    if XyPaiBidStopIcon then
        if XyPaiBidStopIcon.flashFrame then
            XyPaiBidStopIcon.flashFrame:SetScript("OnUpdate", nil)
            XyPaiBidStopIcon.flashFrame = nil
        end
        if XyPaiBidStopIcon.redOverlay then XyPaiBidStopIcon.redOverlay:Hide() end
        XyPaiBidStopIcon:Hide()
    end
    if paiFloatBtn then paiFloatBtn:Hide() end
end

-- ========== 拍卖界面副本3（锚点paiFloatBtn上方6px左对齐，内容同副本2）==========
if not auctionAlertFrame3 then
    auctionAlertFrame3 = CreateFrame("Frame", nil, UIParent)
    auctionAlertFrame3:SetWidth(250)
    auctionAlertFrame3:SetHeight(40)
    auctionAlertFrame3:SetScale(XyScreenScale)
    auctionAlertFrame3:SetPoint("BOTTOMLEFT", paiFloatBtn, "TOPLEFT", 0, 6)
    auctionAlertFrame3:SetFrameStrata("HIGH")
    auctionAlertFrame3:Hide()

    auctionAlertFrame3.bidText = auctionAlertFrame3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    auctionAlertFrame3.bidText:SetPoint("TOPLEFT", 5, -12)
    auctionAlertFrame3.bidText:SetWidth(240)
    auctionAlertFrame3.bidText:SetTextColor(1, 0.82, 0)
    auctionAlertFrame3.bidText:SetJustifyH("LEFT")
    auctionAlertFrame3.bidText:SetText("")
    auctionAlertFrame3.rollText = auctionAlertFrame3:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    auctionAlertFrame3.rollText:SetPoint("TOPLEFT", auctionAlertFrame3.bidText, "BOTTOMLEFT", 0, -4)
    auctionAlertFrame3.rollText:SetJustifyH("LEFT")
    auctionAlertFrame3.rollText:SetWidth(240)
    auctionAlertFrame3.rollText:SetTextColor(0.5, 1, 0.5)
    auctionAlertFrame3.rollText:SetText("")
end

-- ========= 拍卖进行中Stop图标（浮动图标右侧2像素） =========
XyPaiStopIcon = CreateFrame("Frame", nil, UIParent)
XyPaiStopIcon:SetWidth(64)
XyPaiStopIcon:SetHeight(64)
XyPaiStopIcon:SetScale(XyScreenScale)  -- 与待拍/右侧stop图标一致，2K下保持同尺寸
XyPaiStopIcon:SetFrameStrata("DIALOG")
XyPaiStopIcon:SetPoint("CENTER", paiFloatBtn, "CENTER", 0, 0)
XyPaiStopIcon:Hide()

-- stop背景图（覆盖在paiFloatBtn同一位置）
local paiStopTex = XyPaiStopIcon:CreateTexture(nil, "ARTWORK")
paiStopTex:SetTexture("Interface\\AddOns\\XyTracker\\Images\\pai")
paiStopTex:SetAllPoints(XyPaiStopIcon)
XyPaiStopIcon.tex = paiStopTex  -- 保存引用以便动态切换

-- "拍卖中"文字（顶部居中，样式与"待拍"一致）
XyPaiStopLabel = XyPaiStopIcon:CreateFontString(nil, "OVERLAY")
XyPaiStopLabel:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
XyPaiStopLabel:SetText("拍卖中")
XyPaiStopLabel:SetTextColor(1, 0.5, 0, 1)
XyPaiStopLabel:SetPoint("TOP", XyPaiStopIcon, "TOP", 0, -4)
XyPaiStopLabel:Hide()

-- 中心: 剩余时间数字（白色，字号大一倍）
XyPaiStopTimeText = XyPaiStopIcon:CreateFontString(nil, "OVERLAY")
XyPaiStopTimeText:SetFont("Fonts\\FRIZQT__.TTF", 32, "OUTLINE")
XyPaiStopTimeText:SetPoint("CENTER", XyPaiStopIcon, "CENTER", 0, 0)
XyPaiStopTimeText:SetText("10")
XyPaiStopTimeText:SetTextColor(1, 1, 1, 1)
XyPaiStopTimeText:Hide()

-- 左键点击stop图标：提前倒计时（仅拍卖发起者）
XyPaiStopIcon:EnableMouse(true)
XyPaiStopIcon:SetScript("OnMouseDown", function()
    if arg1 ~= "LeftButton" then return end
    if UnitName("player") ~= auctionSender then
        UIErrorsFrame:AddMessage("只有拍卖发起者可以提前倒计时。", 1.0, 0.0, 0.0, 1.0)
        return
    end
    if timerFrame.state == 4 then
        StartRollCountdownNow()
    elseif timerFrame.state == 1 then
        StartCountdownNow()
    end
end)

-- 右侧stop浮动图标 (拍卖中显示，倒计时隐藏)
local paiFloatBtnRight = CreateFrame("Button", nil, UIParent)
paiFloatBtnRight:SetWidth(64)
paiFloatBtnRight:SetHeight(64)
paiFloatBtnRight:SetScale(XyScreenScale)
paiFloatBtnRight:SetPoint("CENTER", paiFloatBtn, "CENTER", 66, 0)
paiFloatBtnRight:SetMovable(true)
paiFloatBtnRight:SetFrameStrata("DIALOG")
paiFloatBtnRight:SetNormalTexture(nil)
paiFloatBtnRight:SetHighlightTexture(nil)
paiFloatBtnRight:SetPushedTexture(nil)
paiFloatBtnRight:Hide()

local paiFloatIconR = paiFloatBtnRight:CreateTexture(nil, "ARTWORK")
paiFloatIconR:SetTexture("Interface\\AddOns\\XyTracker\\Images\\stop")
paiFloatIconR:SetAllPoints(paiFloatBtnRight)

-- 红色闪烁覆盖层
local redOverlay = paiFloatBtnRight:CreateTexture(nil, "OVERLAY")
redOverlay:SetTexture("Interface\\AddOns\\XyTracker\\Images\\stop")
redOverlay:SetAllPoints(paiFloatBtnRight)
redOverlay:SetBlendMode("ADD")
redOverlay:SetVertexColor(1, 0, 0, 0.6)
redOverlay:Hide()
paiFloatBtnRight.redOverlay = redOverlay

XyPaiBidStopIcon = paiFloatBtnRight

-- 左键点击右侧stop图标：提前倒计时（仅拍卖发起者）
XyPaiBidStopIcon:SetScript("OnClick", function()
    if UnitName("player") ~= auctionSender then
        UIErrorsFrame:AddMessage("只有拍卖发起者可以提前倒计时。", 1.0, 0.0, 0.0, 1.0)
        return
    end
    if timerFrame.state == 4 then
        StartRollCountdownNow()
    elseif timerFrame.state == 1 then
        StartCountdownNow()
    end
end)

-- 从 capturedLinks 获取第一个未拍物品
function paiGetUnsoldItem()
    capturedLinks = capturedLinks or {}
    for i = table.getn(capturedLinks), 1, -1 do
        local data = capturedLinks[i]
        if data.sold ~= true and data.link and data.link ~= "" then
            return data.link
        end
    end
    return nil
end

-- 左键：快拍
paiFloatBtn:SetScript("OnClick", function()
    -- shift+左键：隐藏浮动图标及联动元素（等同小地图点击隐藏）
    if arg1 == "LeftButton" and IsShiftKeyDown() then
        paipaiDB = paipaiDB or {}
        paipaiDB.paiFloatHidden = true
        paipaiDB.paiFloatShown = nil
        HidePaiFloatChain()
        return
    end
    if arg1 == "LeftButton" then
        if not IsRaidLeaderOrAssistant() then
            UIErrorsFrame:AddMessage("你不是团长或者助理，没有权限", 1.0, 0.0, 0.0, 1.0)
            return
        end
        paipai_quick_auction()
    end
end)

-- 中键：标记已拍
paiFloatBtn:SetScript("OnMouseDown", function()
    if arg1 == "MiddleButton" then
        if not IsRaidLeaderOrAssistant() then
            UIErrorsFrame:AddMessage("你不是团长或者助理，没有权限", 1.0, 0.0, 0.0, 1.0)
            return
        end
        if paiFloatBtn.currentItemLink then
            MarkLinkAsSold(paiFloatBtn.currentItemLink)
            SendAddonMessage("PP_AUCTION_SOLD", paiFloatBtn.currentItemLink, "RAID")
        else
            UIErrorsFrame:AddMessage("现在没有待拍物品", 1.0, 0.82, 0.0, 1.0)
        end
        return
    end
    if arg1 == "RightButton" then
        this.dragStartX, this.dragStartY = GetCursorPosition()
        this:StartMoving()
    end
end)

paiFloatBtn:SetScript("OnMouseUp", function()
    if arg1 == "RightButton" then
        this:StopMovingOrSizing()
        local cx, cy = GetCursorPosition()
        local dx = cx - (this.dragStartX or 0)
        local dy = cy - (this.dragStartY or 0)
        if dx < 0 then dx = -dx end
        if dy < 0 then dy = -dy end
        if dx <= 3 and dy <= 3 then
            -- 没拖动 = 切换拍卖界面（仅团长/助理）
            if not IsRaidLeaderOrAssistant() then
                UIErrorsFrame:AddMessage("你不是团长或者助理，没有权限", 1.0, 0.0, 0.0, 1.0)
                return
            end
            if AuctionFrame:IsVisible() then
                AuctionFrame:Hide()
            else
                AuctionFrame:Show()
            end
        else
            -- 拖动结束 = 保存位置
            local point, _, relPoint, x, y = paiFloatBtn:GetPoint()
            paipaiDB = paipaiDB or {}
            paipaiDB.floatPos = { point = point, relPoint = relPoint, x = x, y = y }
        end
    end
end)

-- 权限+物品更新 OnUpdate（挂在独立 Frame，宿主 Hidden 时 OnUpdate 不触发）
local paiUpdateFrame = CreateFrame("Frame")
paiUpdateFrame.paiCheckTimer = 0
paiUpdateFrame.paiFirstRun = true
paiUpdateFrame:SetScript("OnUpdate", function()
    local elapsed = arg1 or 0
    -- 首帧恢复位置（SavedVariables 此时已加载）
    if this.paiFirstRun then
        this.paiFirstRun = nil
        paipaiDB = paipaiDB or {}
        if paipaiDB.floatPos and paipaiDB.floatPos.point then
            paiFloatBtn:ClearAllPoints()
            paiFloatBtn:SetPoint(paipaiDB.floatPos.point, UIParent, paipaiDB.floatPos.relPoint, paipaiDB.floatPos.x, paipaiDB.floatPos.y)
        end
    end
    this.paiCheckTimer = (this.paiCheckTimer or 0) + elapsed
    if this.paiCheckTimer < 2 then return end
    this.paiCheckTimer = 0
    -- 可见性检测：非团长/助理隐藏；团长/助理默认隐藏，具有许愿权或点击过小地图才显示
    if not PaiFloatChainVisible() then
        HidePaiFloatChain()
        return
    end
    paiFloatBtn:Show()
    local link = paiGetUnsoldItem()
    -- 直接roll按钮：非拍卖阶段且有待拍装备时显示，拍卖阶段或无待拍装备时隐藏
    if directRollBtn then
        local inAuction = timerFrame and timerFrame.state and timerFrame.state >= 1 and timerFrame.state <= 5
        if link and not inAuction then
            directRollBtn:Show()
        else
            directRollBtn:Hide()
        end
    end
    -- "待拍"文字：拍卖中隐藏（避免与"拍卖中"重叠），拍卖结束自动恢复（有待拍物品时）
    local inAuction2 = timerFrame and timerFrame.state and timerFrame.state >= 1 and timerFrame.state <= 5
    if inAuction2 then
        if paiFloatLabel then paiFloatLabel:Hide() end
    elseif link then
        if paiFloatLabel then paiFloatLabel:Show() end
    end
    if link and link ~= paiFloatBtn.currentItemLink then
        -- 有新未拍物品 → 换图标
        paiFloatBtn.currentItemLink = link
        local icon, itemId = GetItemIconFromLink(link)
        if icon and icon ~= "" then
            paiFloatBtn.currentItemId = itemId
            paiFloatIcon:SetTexture(icon)
            paiFloatLabel:Show()
        else
            paiFloatBtn.currentItemId = nil
            paiFloatLabel:Hide()
        end
    elseif not link and paiFloatBtn.currentItemLink then
        -- 无未拍物品 → 恢复默认图标
        paiFloatBtn.currentItemLink = nil
        paiFloatBtn.currentItemId = nil
        paiFloatIcon:SetTexture("Interface\\AddOns\\XyTracker\\Images\\pai")
        paiFloatLabel:Hide()
    end
end)

-- Tooltip：有物品时显示装备信息，无物品时显示提示
-- 位置：与 pai.tga 左对齐（左对左），提示顶部距按钮底部 3 像素；锚定在按钮上，拖动跟随移动
paiFloatBtn:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_NONE")
    GameTooltip:SetText("快速拍卖（中键跳过此装备）", 1, 0.82, 0, 1)
    GameTooltip:AddLine("左键快拍 | 中键跳过 | 右键界面")
    GameTooltip:AddLine("右键拖动 | shift+左键隐藏")
    -- 左对齐 + 顶部距按钮底部 3 像素（锚定按钮，拖动时提示相对跟随）
    GameTooltip:ClearAllPoints()
    GameTooltip:SetPoint("TOPLEFT", this, "BOTTOMLEFT", 0, -3)
    GameTooltip:Show()
end)
paiFloatBtn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)


-- ========= 小地图拍卖按钮 =========
local function CreatePaiMinimapButton()
    local btn = CreateFrame("Button", "XyPaiMinimapButton", Minimap)
    btn:SetFrameStrata("HIGH")
    btn:SetWidth(26)
    btn:SetHeight(26)
    btn:EnableMouse(true)
    btn:SetMovable(true)
    btn:RegisterForDrag("LeftButton", "RightButton")
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    -- 贴 pai.tga 图标
    btn:SetNormalTexture("Interface\\AddOns\\XyTracker\\Images\\pai")
    local normalTex = btn:GetNormalTexture()
    normalTex:SetWidth(20)
    normalTex:SetHeight(20)
    normalTex:SetPoint("CENTER", 0, 0)

    -- 悬停高亮
    btn:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")
    local hlTex = btn:GetHighlightTexture()
    hlTex:SetBlendMode("ADD")
    hlTex:SetWidth(26)
    hlTex:SetHeight(26)
    hlTex:SetPoint("CENTER", 0, 0)

    -- 标准小地图圆环边框（53px 画布锚 TOPLEFT 同款，26 按钮等比 43）
    local borderTex = btn:CreateTexture("XyPaiMinimapButtonBorder", "OVERLAY")
    borderTex:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
    borderTex:SetWidth(43)
    borderTex:SetHeight(43)
    borderTex:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)

    -- Tooltip
    btn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("快速拍卖：", 1, 0.82, 0, 1)
        GameTooltip:AddLine("点击：显示/隐藏拍卖图标", 1, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- 拖动开始
    btn:SetScript("OnDragStart", function()
        this.isDragging = true
        this.dragButton = arg1
        if arg1 == "LeftButton" then
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = UIParent:GetScale()
            px = px / scale
            py = py / scale
            local angle = math.atan2(py - my, px - mx)
            local x = math.cos(angle) * 80
            local y = math.sin(angle) * 80
            this:ClearAllPoints()
            this:SetPoint("CENTER", Minimap, "CENTER", x, y)
            paipaiDB = paipaiDB or {}
            paipaiDB.paiMinimapPos = {x = x, y = y}
            paipaiDB.paiMinimapFree = nil
        else
            local px, py = GetCursorPosition()
            local scale = UIParent:GetScale()
            px = px / scale
            py = py / scale
            this:ClearAllPoints()
            this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)
            paipaiDB = paipaiDB or {}
            paipaiDB.paiMinimapFree = {x = px, y = py}
            paipaiDB.paiMinimapPos = nil
        end
    end)

    -- 拖动中更新
    btn:SetScript("OnUpdate", function()
        if not this.isDragging then return end
        local px, py = GetCursorPosition()
        local scale = UIParent:GetScale()
        px = px / scale
        py = py / scale
        if this.dragButton == "LeftButton" then
            local mx, my = Minimap:GetCenter()
            local angle = math.atan2(py - my, px - mx)
            local x = math.cos(angle) * 80
            local y = math.sin(angle) * 80
            this:ClearAllPoints()
            this:SetPoint("CENTER", Minimap, "CENTER", x, y)
            paipaiDB = paipaiDB or {}
            paipaiDB.paiMinimapPos = {x = x, y = y}
            paipaiDB.paiMinimapFree = nil
        else
            this:ClearAllPoints()
            this:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py)
            paipaiDB = paipaiDB or {}
            paipaiDB.paiMinimapFree = {x = px, y = py}
            paipaiDB.paiMinimapPos = nil
        end
    end)

    -- 拖动结束
    btn:SetScript("OnDragStop", function()
        this.isDragging = nil
    end)

    -- 点击：切换浮动图标及联动元素显隐（非团长/助理无效；隐藏效果与shift+左键一致）
    btn:SetScript("OnClick", function()
        if this.isDragging then return end
        if arg1 == "LeftButton" then
            paipaiDB = paipaiDB or {}
            if PaiFloatChainVisible() then
                -- 当前可见 → 隐藏（连同frame3、stop等联动元素）
                paipaiDB.paiFloatHidden = true
                paipaiDB.paiFloatShown = nil
                HidePaiFloatChain()
            else
                -- 当前隐藏 → 显示（仅团长/助理）
                if not IsRaidLeaderOrAssistant() then
                    UIErrorsFrame:AddMessage("你不是团长或者助理，没有权限", 1.0, 0.0, 0.0, 1.0)
                    return
                end
                paipaiDB.paiFloatHidden = nil
                paipaiDB.paiFloatShown = true
                paiFloatBtn:Show()
            end
        end
    end)

    -- 恢复上次位置
    paipaiDB = paipaiDB or {}
    if paipaiDB.paiMinimapFree and paipaiDB.paiMinimapFree.x then
        btn:SetPoint("CENTER", UIParent, "BOTTOMLEFT", paipaiDB.paiMinimapFree.x, paipaiDB.paiMinimapFree.y)
    elseif paipaiDB.paiMinimapPos and paipaiDB.paiMinimapPos.x then
        btn:SetPoint("CENTER", Minimap, "CENTER", paipaiDB.paiMinimapPos.x, paipaiDB.paiMinimapPos.y)
    else
        btn:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
    end
end

CreatePaiMinimapButton()

-- =============================================================
-- /xypm reset：所有图标回归默认位置
-- 覆盖全部可移动/可拖动图标：待拍浮动图标、拍卖弹窗(Frame1)、
-- 拍卖界面副本(Frame2)、主拍卖面板、小地图按钮，
-- 以及跟随主图标的联动元素（拍卖中stop、右侧stop、副本3、直接roll按钮）。
-- =============================================================
function ResetAllIconPositions()
    paipaiDB = paipaiDB or {}

    -- 1. 拍卖浮动主图标（待拍图标）→ 屏幕中心
    if paiFloatBtn then
        paiFloatBtn:ClearAllPoints()
        paiFloatBtn:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    paipaiDB.floatPos = nil

    -- 2. 拍卖弹窗 Frame1 → 屏幕中心上方200
    if auctionAlertFrame then
        auctionAlertFrame:ClearAllPoints()
        auctionAlertFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
    paipaiDB.alertPos = nil

    -- 3. 拍卖界面副本 Frame2 → 跟随 Frame1 顶部
    if auctionAlertFrame2 and auctionAlertFrame then
        auctionAlertFrame2:ClearAllPoints()
        auctionAlertFrame2:SetPoint("TOP", auctionAlertFrame, "TOP", 0, 0)
    end

    -- 4. 主拍卖面板 → 屏幕中心
    if XyAuctionFrame then
        XyAuctionFrame:ClearAllPoints()
        XyAuctionFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- 5. 小地图按钮 → 小地图右侧默认点
    if XyPaiMinimapButton then
        XyPaiMinimapButton:ClearAllPoints()
        XyPaiMinimapButton:SetPoint("CENTER", Minimap, "CENTER", 80, 0)
    end
    paipaiDB.paiMinimapPos = nil
    paipaiDB.paiMinimapFree = nil

    -- 6. 联动元素重新锚定（跟随主图标；directRollBtn 为主图标子帧自动跟随）
    if XyPaiStopIcon and paiFloatBtn then
        XyPaiStopIcon:ClearAllPoints()
        XyPaiStopIcon:SetPoint("CENTER", paiFloatBtn, "CENTER", 0, 0)
    end
    if XyPaiBidStopIcon and paiFloatBtn then
        XyPaiBidStopIcon:ClearAllPoints()
        XyPaiBidStopIcon:SetPoint("CENTER", paiFloatBtn, "CENTER", 66, 0)
    end
    if auctionAlertFrame3 and paiFloatBtn then
        auctionAlertFrame3:ClearAllPoints()
        auctionAlertFrame3:SetPoint("BOTTOMLEFT", paiFloatBtn, "TOPLEFT", 0, 6)
    end

    DEFAULT_CHAT_FRAME:AddMessage("[拍卖] 所有图标已重置到默认位置。", 0.5, 1, 0.5)
end
