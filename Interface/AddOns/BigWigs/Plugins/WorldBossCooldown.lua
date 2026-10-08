--[[
WorldBossCooldown — 世界Boss冷却追踪
by WorkBugs

服务器限制：同一世界Boss（户外Boss）每 7 天只能「掉落」一次。
（乌龟服很多世界Boss可以重复击杀，但一周只掉一次战利品，游戏内看不到冷却时间。）
本插件用两种方式判定冷却：

  1) 掉落记录：BigWigs Victory → EndBossfight 钩子 → 记录精确 time()。
     · 若该 Boss 已有「仍在冷却期内」的记录 → 判定为重复击杀，**不刷新倒计时**
       （冷却按「掉落」计，不按「击杀」计）。
  2) 系统提示「你绝对不允许从 <Boss> 处获得战利品，因为你拥有个人锁定权限！」
     → 判定为「你本周已锁定」。此时：
     · 若本场战斗刚写过该 Boss 的时间戳（LOCKOUT_WINDOW 内）→ 这次没掉落，
       撤销刚写入的时间，恢复战前记录；战前无记录则标记为「冷却中·时间不明」。
     · 否则保留已有记录（说明早就掉了，只是又被判定一次锁定）。

记录存储：
  self.db.profile.worldBossKills  = { [bossName] = <time() 秒> }  -- 精确掉落时间
  self.db.profile.worldBossLocked = { [bossName] = true }         -- 仅知在 CD，时间不明
识别方式：module.zonename 包含 "Outdoor Raid Bosses Zone"（即户外/世界Boss）。

命令：
  /bwcd / /worldbosscd            打开 / 关闭面板
  /bwcd show | hide               显示 / 隐藏面板
  /bwcd reset <Boss名>            清除该 Boss 精确时间 → 标记「冷却中·时间不明」
  /bwcd reset all                 清空全部记录
  /bwcd debug                     开关调试输出（排查锁定提示事件/名字解析）
--]]

------------------------------
--      Are you local?      --
------------------------------
local LC = AceLibrary("AceLocale-2.2"):new("BigWigs")

local prefix = "|cff33ffcc[BigWigs]|r - "
local COOLDOWN = 7 * 24 * 3600 -- 7 天冷却（秒）

-- 锁定提示与本场战斗的时间关联窗口（秒）。
-- 玩家「开尸体 → 弹出锁定提示」通常发生在 Boss 死亡后数秒到数分钟，
-- 故窗口取 10 分钟：窗口内写入的时间戳视为「本场战斗刚写的」，可安全撤销。
local LOCKOUT_WINDOW = 600

-- 户外/世界Boss 标识
local OUTDOOR_ZONE = LC["Outdoor Raid Bosses Zone"]

-- 兼容：table.getn / # 运算符
local tgetn = table.getn
if not tgetn then
    tgetn = function(t)
        local n = 0
        while t[n + 1] ~= nil do n = n + 1 end
        return n
    end
end

local function tcount(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

----------------------------
--      Localization      --
----------------------------
local L = AceLibrary("AceLocale-2.2"):new("BigWigsWorldBossCooldown")
L:RegisterTranslations("zhCN", function() return {
    KILLED          = "%s 已掉落（本周首次）！下次可掉落：还剩 %d 天 %d 时",
    KILLED_REPEAT   = "%s 重复击杀（本周已掉落，倒计时不刷新）：还剩 %d 天 %d 时",
    READY           = "[OK] %s 已可击杀（%d天前掉落）",
    NOTREADY        = "[CD] %s 冷却中 -- 还需 %d 天 %d 时（%d天前掉落）",
    LOCKED_KEEP     = "[CD] %s 锁定确认 -- 还需 %d 天 %d 时（%d天前掉落）",
    LOCKED_UNKNOWN  = "[CD?] %s 冷却中 -- 时间不明（检测到锁定）",
    NORECORD        = "* %s：从未击杀（随时可打）",
    HEADER          = "世界Boss 冷却状态",
    EMPTY           = "暂无世界Boss记录。击杀世界Boss后自动记录。",
    PANEL_TITLE     = "世界Boss 冷却追踪",
    COL_BOSS        = "Boss 名称",
    COL_STATUS      = "状态",
    COL_KILLED      = "上次掉落 / 检测",
    CLOSE_TIP       = "关闭面板",
    REFRESH_TIP     = "刷新",
    LOCKED_TAG      = "时间不明",
    AGO             = "%d天 %d时前",
    DBG_ON          = "调试输出：开",
    DBG_OFF         = "调试输出：关",
    RESET_USAGE     = "用法：/bwcd reset <Boss名>  或  /bwcd reset all",
    RESET_DONE      = "%s 记录已重置：已标记为「冷却中·时间不明」",
    RESET_NONE      = "没有找到名为 %s 的记录。",
    RESET_ALL       = "已清空全部世界Boss记录。",
} end)

L:RegisterTranslations("enUS", function() return {
    KILLED          = "%s dropped (first this week)! Next drop in %d day(s) %d hr",
    KILLED_REPEAT   = "%s repeat kill (already dropped this week, timer not reset): %d day(s) %d hr left",
    READY           = "[OK] %s ready (dropped %d day(s) ago)",
    NOTREADY        = "[CD] %s on cooldown -- %d day(s) %d hr left (dropped %d day(s) ago)",
    LOCKED_KEEP     = "[CD] %s lockout confirmed -- %d day(s) %d hr left (dropped %d day(s) ago)",
    LOCKED_UNKNOWN  = "[CD?] %s on cooldown -- time unknown (lockout detected)",
    NORECORD        = "* %s: never killed (available anytime)",
    HEADER          = "WorldBoss Cooldown Status",
    EMPTY           = "No world boss records yet. Auto-records on kill.",
    PANEL_TITLE     = "WorldBoss Cooldown Tracker",
    COL_BOSS        = "Boss Name",
    COL_STATUS      = "Status",
    COL_KILLED      = "Last Drop / Detected",
    CLOSE_TIP       = "Close panel",
    REFRESH_TIP     = "Refresh",
    LOCKED_TAG      = "unknown",
    AGO             = "%dd %dh ago",
    DBG_ON          = "Debug output: ON",
    DBG_OFF         = "Debug output: OFF",
    RESET_USAGE     = "Usage: /bwcd reset <boss name>  or  /bwcd reset all",
    RESET_DONE      = "%s record reset: marked as 'on cooldown - time unknown'",
    RESET_NONE      = "No record found for %s.",
    RESET_ALL       = "All world boss records cleared.",
} end)

----------------------------------
--      Module Declaration      --
----------------------------------

BigWigsWorldBossCooldown = BigWigs:NewModule("WorldBossCooldown")
local mod = BigWigsWorldBossCooldown

-- 最近一次「本场战斗写入」的缓存：lastKill[name] = { time = <time()>, prev = <写入前的值> }
-- 用于锁定提示联动：若锁定提示紧随一次写入（LOCKOUT_WINDOW 内），说明这次击杀没有掉落。
local lastKill = {}

-- 锁定提示去重（同一条提示可能被多个事件重复投递）
local lastLockNotice = { name = nil, time = 0 }

-- 注册查询命令（放在模块作用域）
SLASH_BWCD1 = "/bwcd"
SLASH_BWCD2 = "/worldbosscd"
SlashCmdList["BWCD"] = function(msg)
    mod:HandleCommand(msg or "")
end

------------------------------
--      Local Helpers      --
------------------------------

local function IsWorldBoss(module)
    local zn = module and module.zonename
    if type(zn) == "table" then
        for _, z in pairs(zn) do
            if z == OUTDOOR_ZONE then return true end
        end
    elseif type(zn) == "string" then
        return zn == OUTDOOR_ZONE
    end
    return false
end

local function remaining(t)
    local left = t + COOLDOWN - time()
    if left <= 0 then return 0, 0 end
    local days = math.floor(left / 86400)
    local hours = math.floor(math.mod(left, 86400) / 3600)
    return days, hours
end

local function elapsed(t)
    local diff = time() - t
    if diff < 0 then diff = 0 end
    local days = math.floor(diff / 86400)
    local hours = math.floor(math.mod(diff, 86400) / 3600)
    return days, hours
end

local function trim(s)
    if type(s) ~= "string" then return s end
    s = string.gsub(s, "^%s+", "")
    s = string.gsub(s, "%s+$", "")
    return s
end

-- 从一条提示文本里解析 Boss 名（只在命中「锁定权限」关键词时才解析）
-- 中文：你绝对不允许从 卡扎克 处获得战利品，因为你拥有个人锁定权限！
-- 英文：You are not allowed to loot Lord Kazzak because you have a personal lockout on it.
local LOCK_KEY_ZH = "个人锁定权限"
local LOCK_KEY_EN = "personal lock"

local function ExtractBossName(msg)
    if type(msg) ~= "string" then return nil end
    if not (string.find(msg, LOCK_KEY_ZH, 1, true) or string.find(msg, LOCK_KEY_EN, 1, true)) then
        return nil
    end

    local name
    local _, _, a = string.find(msg, "从%s*(.-)%s*处获得")
    name = a
    if not name then
        local _, _, b = string.find(msg, "从%s*(.-)%s*处")
        name = b
    end
    if not name then
        local _, _, c = string.find(msg, "loot%s*(.-)%s*[Bb]ecause")
        name = c
    end
    if not name then
        local _, _, d = string.find(msg, "loot%s*(.-)%s*[%.%!]")
        name = d
    end
    if not name then return nil end

    name = trim(name)
    -- 去掉可能的颜色代码 / 物品链接包裹
    name = string.gsub(name, "|c%x%x%x%x%x%x%x%x", "")
    name = string.gsub(name, "|r", "")
    local _, _, inner = string.find(name, "%[(.-)%]")
    if inner then name = inner end
    name = trim(name)

    if name == "" then return nil end
    return name
end

------------------------------
--      Initialization      --
------------------------------

function BigWigsWorldBossCooldown:OnEnable()
    -- 确保存储表存在
    if not self.db.profile.worldBossKills then
        self.db.profile.worldBossKills = {}
    end
    if not self.db.profile.worldBossLocked then
        self.db.profile.worldBossLocked = {}
    end

    -- 进服时提醒已冷却的Boss
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "RemindOnLogin")

    -- 监听锁定提示：不同客户端/服务器可能走系统消息或 UI 错误提示，两处都收
    self:RegisterEvent("CHAT_MSG_SYSTEM", "OnSystemMessage")
    self:RegisterEvent("UI_ERROR_MESSAGE", "OnSystemMessage")
    self:RegisterEvent("CHAT_MSG_RAID_WARNING", "OnSystemMessage")

    -- 创建面板（只创建一次）
    self:EnsurePanel()

    -- 定时刷新（每分钟）。1.12 客户端没有 C_Timer，用 AceEvent 的调度器
    self:ScheduleRepeatingEvent("BigWigsWorldBossCooldown_Refresh", self.RefreshPanel, 60, self)
end

function BigWigsWorldBossCooldown:OnDisable()
    self:CancelScheduledEvent("BigWigsWorldBossCooldown_Refresh")
    if self.ui and self.ui.panel then
        self.ui.panel:Hide()
    end
end

------------------------------
--      Name Resolution     --
------------------------------

-- 把日志/提示里的名字对到已记录的名字上（处理「卡扎克」/「魔王卡扎克」这类差异）
function BigWigsWorldBossCooldown:ResolveKnownName(raw)
    if type(raw) ~= "string" or raw == "" then return nil end
    local kills = self.db.profile.worldBossKills or {}
    local locked = self.db.profile.worldBossLocked or {}

    if kills[raw] or locked[raw] then return raw end

    for k in pairs(kills) do
        if string.find(k, raw, 1, true) or string.find(raw, k, 1, true) then
            return k
        end
    end
    for k in pairs(locked) do
        if string.find(k, raw, 1, true) or string.find(raw, k, 1, true) then
            return k
        end
    end

    return raw -- 未知名字也接受，作为新键
end

------------------------------
--      Kill Recording      --
------------------------------

-- 记录一次「掉落」。返回 true = 记为本周首次掉落；false = 重复击杀（不刷新倒计时）
function BigWigsWorldBossCooldown:RecordKill(name, silent)
    if type(name) ~= "string" or name == "" then return false end

    local kills = self.db.profile.worldBossKills
    local locked = self.db.profile.worldBossLocked
    local now = time()
    local existing = kills[name]

    if type(existing) == "number" and (existing + COOLDOWN) > now then
        -- 本周已掉落：重复击杀不刷新倒计时
        lastKill[name] = { time = now, prev = existing }
        locked[name] = nil
        if not silent then
            local d, h = remaining(existing)
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["KILLED_REPEAT"], name, d, h))
        end
        self:RefreshPanel()
        return false
    end

    lastKill[name] = { time = now, prev = existing }
    kills[name] = now
    locked[name] = nil

    if not silent then
        local d, h = remaining(now)
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["KILLED"], name, d, h))
    end

    self:RefreshPanel()
    return true
end

function BigWigsWorldBossCooldown:EndBossfight(module)
    if not IsWorldBoss(module) then return end
    self:RecordKill(module:ToString())
end

------------------------------
--   Lockout Message Hook     --
------------------------------

-- 注意：AceEvent-2.0 的回调签名是 (self, 事件参数...)，**不含事件名**。
-- 所以这里第一个参数就是消息文本本身（曾经写成 (event, msg) 导致永远读不到 msg）。
function BigWigsWorldBossCooldown:OnSystemMessage(a1, a2, a3)
    if not self.db or not self.db.profile then return end

    local raw = nil
    local name = nil
    local args = { a1, a2, a3 }
    for i = 1, 3 do
        local v = args[i]
        if type(v) == "string" then
            local n = ExtractBossName(v)
            if n then
                raw = v
                name = n
                break
            end
        end
    end
    if not name then return end

    local kills = self.db.profile.worldBossKills
    local locked = self.db.profile.worldBossLocked
    local now = time()

    -- 调试输出：确认到底是哪个事件、解析出什么名字
    if self.db.profile.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00[BWCD debug]|r " .. (raw or "") .. "  => " .. name)
    end

    local key = self:ResolveKnownName(name)
    if not key then return end

    -- 同一提示去重（多事件重复投递）
    if lastLockNotice.name == key and (now - lastLockNotice.time) <= 3 then return end
    lastLockNotice.name = key
    lastLockNotice.time = now

    local recent = lastKill[key]
    local existing = kills[key]

    if recent and (now - recent.time) <= LOCKOUT_WINDOW then
        -- 本场战斗刚写过时间戳 → 这次没有掉落，撤销这笔写入
        lastKill[key] = nil

        if type(recent.prev) == "number" then
            -- 战前有记录 → 恢复，并确认锁定
            kills[key] = recent.prev
            locked[key] = nil
            local d, h = remaining(recent.prev)
            local ed = elapsed(recent.prev)
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["LOCKED_KEEP"], key, d, h, ed))
        else
            -- 战前无记录 → 撤销为「时间不明」
            kills[key] = nil
            locked[key] = true
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["LOCKED_UNKNOWN"], key))
        end
    else
        -- 没有近期写入：保留已有精确记录，仅在完全无记录时标记「时间不明」
        if type(existing) == "number" then
            local d, h = remaining(existing)
            local ed = elapsed(existing)
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["LOCKED_KEEP"], key, d, h, ed))
        else
            locked[key] = true
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["LOCKED_UNKNOWN"], key))
        end
    end

    self:RefreshPanel()
end

function BigWigsWorldBossCooldown:RemindOnLogin()
    local kills = self.db.profile.worldBossKills
    local locked = self.db.profile.worldBossLocked
    local ready = {}

    -- 检查精确记录中已冷却的
    for name, last in pairs(kills) do
        if type(last) == "number" then
            local d, h = remaining(last)
            if d == 0 and h == 0 then
                table.insert(ready, {name = name, last = last})
            end
        end
    end

    if tgetn(ready) == 0 then return end
    table.sort(ready, function(a, b) return a.name < b.name end)
    DEFAULT_CHAT_FRAME:AddMessage(prefix .. L["HEADER"])
    for _, entry in ipairs(ready) do
        local ed = elapsed(entry.last)
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["READY"], entry.name, ed))
    end
end

------------------------------
--      Command Handler      --
------------------------------

function BigWigsWorldBossCooldown:ResetRecord(rest)
    local kills = self.db.profile.worldBossKills
    local locked = self.db.profile.worldBossLocked

    if type(rest) ~= "string" or rest == "" then
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. L["RESET_USAGE"])
        return
    end

    if string.lower(rest) == "all" then
        for k in pairs(kills) do kills[k] = nil end
        for k in pairs(locked) do locked[k] = nil end
        lastKill = {}
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. L["RESET_ALL"])
    else
        local key = self:ResolveKnownName(rest)
        if not key or (not kills[key] and not locked[key]) then
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["RESET_NONE"], rest))
        else
            kills[key] = nil
            locked[key] = true
            lastKill[key] = nil
            DEFAULT_CHAT_FRAME:AddMessage(prefix .. string.format(L["RESET_DONE"], key))
        end
    end

    self:RefreshPanel()
end

function BigWigsWorldBossCooldown:HandleCommand(msg)
    msg = msg or ""
    msg = trim(msg)
    local lower = string.lower(msg)

    -- reset 子命令（Boss 名不做小写化，保留原名参与匹配）
    if string.lower(string.sub(msg, 1, 5)) == "reset" then
        self:ResetRecord(trim(string.gsub(msg, "^%S+", "")))
        return
    end

    if lower == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. (self.db.profile.debug and L["DBG_ON"] or L["DBG_OFF"]))
        return
    end

    if lower == "show" or lower == "" then
        self:ShowPanel()
    elseif lower == "hide" then
        if self.ui and self.ui.panel then self.ui.panel:Hide() end
    else
        self:TogglePanel()
    end
end

------------------------------
--      Visual Panel      --
------------------------------

function BigWigsWorldBossCooldown:EnsurePanel()
    if self.ui and self.ui.panel then return end
    self.ui = {}
    self:CreatePanel()
end

function BigWigsWorldBossCooldown:CreatePanel()
    local ui = self.ui

    -- 主面板
    local panel = CreateFrame("Frame", "BigWigs_WorldBossCD_Panel", UIParent)
    panel:SetWidth(480)
    panel:SetHeight(320)
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function() panel:StartMoving() end)
    panel:SetScript("OnDragStop", function() panel:StopMovingOrSizing() end)
    panel:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    panel:SetBackdropColor(0.06, 0.08, 0.12, 0.95)
    panel:SetBackdropBorderColor(0.3, 0.35, 0.45, 1.0)
    panel:Hide()

    -- 标题栏背景
    local titleBg = panel:CreateTexture(nil, "ARTWORK")
    titleBg:SetTexture(0.15, 0.18, 0.25, 1.0)
    titleBg:SetHeight(24)
    titleBg:SetPoint("TOPLEFT", panel, "TOPLEFT", 2, -2)
    titleBg:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -2, -2)

    -- 标题文字
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    title:SetTextColor(1.0, 0.85, 0.2)
    title:SetPoint("CENTER", titleBg, "CENTER", 0, 0)
    title:SetText(L["PANEL_TITLE"])

    -- 关闭按钮
    local closeBtn = CreateFrame("Button", nil, panel)
    closeBtn:SetWidth(20)
    closeBtn:SetHeight(20)
    closeBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -8)
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Quickslot-Depress",
        edgeFile = "Interface\\Buttons\\UI-Quickslot-Border",
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    closeBtn:SetBackdropColor(0.6, 0.1, 0.1, 0.9)
    closeBtn:EnableMouse(true)
    closeBtn:RegisterForClicks("LeftButtonUp")
    closeBtn:SetScript("OnClick", function() panel:Hide() end)
    closeBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(closeBtn, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText(L["CLOSE_TIP"])
        GameTooltip:Show()
    end)
    closeBtn:SetScript("OnLeave", function()
        if GameTooltip:IsOwned(closeBtn) then
            GameTooltip:Hide()
        end
    end)
    local closeLabel = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeLabel:SetFont(STANDARD_TEXT_FONT, 13)
    closeLabel:SetTextColor(1, 0.7, 0.7)
    closeLabel:SetText("X")
    closeLabel:SetAllPoints(closeBtn)

    -- 刷新按钮
    local refreshBtn = CreateFrame("Button", nil, panel)
    refreshBtn:SetWidth(50)
    refreshBtn:SetHeight(18)
    refreshBtn:SetPoint("TOPRIGHT", closeBtn, "TOPLEFT", -4, 2)
    refreshBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\UI-Quickslot-Depress",
        edgeFile = "Interface\\Buttons\\UI-Quickslot-Border",
        tile = false, tileSize = 0, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    refreshBtn:SetBackdropColor(0.15, 0.25, 0.35, 0.9)
    refreshBtn:EnableMouse(true)
    refreshBtn:RegisterForClicks("LeftButtonUp")
    local refreshLabel = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    refreshLabel:SetFont(STANDARD_TEXT_FONT, 11)
    refreshLabel:SetTextColor(0.9, 0.9, 0.9)
    refreshLabel:SetText(L["REFRESH_TIP"])
    refreshLabel:SetAllPoints(refreshBtn)

    -- 点击刷新 + 短暂文字反馈（确认按钮有响应）
    local refreshFlashUntil = 0
    refreshBtn:SetScript("OnClick", function()
        BigWigsWorldBossCooldown:RefreshPanel()
        refreshLabel:SetText("已刷新!")
        refreshFlashUntil = GetTime() + 1
    end)
    refreshBtn:SetScript("OnUpdate", function()
        if refreshFlashUntil > 0 and GetTime() >= refreshFlashUntil then
            refreshLabel:SetText(L["REFRESH_TIP"])
            refreshFlashUntil = 0
        end
    end)

    -- 列头
    local headerY = -38
    local colX_boss = 20
    local colX_status = 200
    local colX_killed = 370
    local rowH = 22
    local firstRowY = -60

    local h_boss = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h_boss:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    h_boss:SetTextColor(1.0, 0.82, 0.2)
    h_boss:SetPoint("TOPLEFT", panel, "TOPLEFT", colX_boss, headerY)
    h_boss:SetText(L["COL_BOSS"])

    local h_status = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h_status:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    h_status:SetTextColor(1.0, 0.82, 0.2)
    h_status:SetPoint("TOPLEFT", panel, "TOPLEFT", colX_status, headerY)
    h_status:SetText(L["COL_STATUS"])

    local h_killed = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    h_killed:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    h_killed:SetTextColor(1.0, 0.82, 0.2)
    h_killed:SetPoint("TOPLEFT", panel, "TOPLEFT", colX_killed, headerY)
    h_killed:SetText(L["COL_KILLED"])

    -- 空状态提示
    local emptyText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    emptyText:SetFont(STANDARD_TEXT_FONT, 12)
    emptyText:SetTextColor(0.6, 0.6, 0.6)
    emptyText:SetPoint("CENTER", panel, "CENTER", 0, 10)
    emptyText:SetText(L["EMPTY"])
    emptyText:Hide()

    -- 数据行容器（动态创建）
    ui.panel = panel
    ui.emptyText = emptyText
    ui.rows = {}
    ui.rowPool = {} -- 对象池复用 FontString

    -- 预创建行对象池（最多12个Boss够用）
    for i = 1, 12 do
        local row = {}
        row.bossText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.bossText:SetFont(STANDARD_TEXT_FONT, 11)
        row.bossText:SetTextColor(1.0, 1.0, 1.0)
        row.bossText:SetPoint("TOPLEFT", panel, "TOPLEFT", colX_boss, firstRowY - ((i - 1) * rowH))
        row.bossText:SetWidth(colX_status - colX_boss - 10)
        row.bossText:SetJustifyH("LEFT")
        row.bossText:Hide()

        row.statusText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.statusText:SetFont(STANDARD_TEXT_FONT, 11)
        row.statusText:SetTextColor(1.0, 1.0, 1.0)
        row.statusText:SetPoint("TOPLEFT", panel, "TOPLEFT", colX_status, firstRowY - ((i - 1) * rowH))
        row.statusText:SetWidth(colX_killed - colX_status - 10)
        row.statusText:SetJustifyH("LEFT")
        row.statusText:Hide()

        row.killedText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        row.killedText:SetFont(STANDARD_TEXT_FONT, 11)
        row.killedText:SetTextColor(0.75, 0.75, 0.75)
        row.killedText:SetPoint("TOPLEFT", panel, "TOPLEFT", colX_killed, firstRowY - ((i - 1) * rowH))
        row.killedText:SetJustifyH("LEFT")
        row.killedText:Hide()

        table.insert(ui.rowPool, row)
    end
end

function BigWigsWorldBossCooldown:ShowPanel()
    self:EnsurePanel()
    if self.ui.panel then
        self.ui.panel:Show()
    end
    self:RefreshPanel()  -- 必须在 Show() 之后调用，否则面板未显示会被跳过渲染
end

function BigWigsWorldBossCooldown:TogglePanel()
    self:EnsurePanel()
    if not self.ui.panel then return end
    if self.ui.panel:IsShown() then
        self.ui.panel:Hide()
    else
        self:ShowPanel()
    end
end

function BigWigsWorldBossCooldown:RefreshPanel()
    if not self.ui or not self.ui.panel then return end
    if not self.ui.panel:IsShown() then return end

    local kills = self.db.profile.worldBossKills or {}
    local locked = self.db.profile.worldBossLocked or {}

    -- 合并两个来源：精确掉落时间 + 锁定检测（去重）
    local allNames = {}
    for k in pairs(kills) do
        if type(kills[k]) == "number" then
            table.insert(allNames, k)
        end
    end
    for k in pairs(locked) do
        if locked[k] and not kills[k] then
            table.insert(allNames, k)
        end
    end
    table.sort(allNames)

    -- 隐藏所有行
    for _, row in ipairs(self.ui.rowPool) do
        row.bossText:Hide()
        row.statusText:Hide()
        row.killedText:Hide()
    end

    local count = tgetn(allNames)

    if count == 0 then
        self.ui.emptyText:Show()
        return
    end

    self.ui.emptyText:Hide()

    -- 填充数据行
    for i, name in ipairs(allNames) do
        local row = self.ui.rowPool[i]
        if not row then break end

        row.bossText:SetText(name)
        row.bossText:Show()

        local killTime = kills[name]
        local isLockedOnly = locked[name] and (not killTime)

        if isLockedOnly then
            -- 仅知在CD，时间不明
            row.statusText:SetText(string.format(L["LOCKED_UNKNOWN"], name))
            row.statusText:SetTextColor(1.0, 0.5, 0.2) -- 橙色=CD中
            row.statusText:Show()
            row.killedText:SetText(L["LOCKED_TAG"])
            row.killedText:SetTextColor(0.8, 0.5, 0.2)
            row.killedText:Show()
        elseif type(killTime) == "number" then
            -- 有精确掉落时间
            local d, h = remaining(killTime)
            local ed, eh = elapsed(killTime)

            if d == 0 and h == 0 then
                row.statusText:SetText(string.format(L["READY"], name, ed))
                row.statusText:SetTextColor(0.2, 1.0, 0.3) -- 绿色=可打
            else
                row.statusText:SetText(string.format(L["NOTREADY"], name, d, h, ed))
                row.statusText:SetTextColor(1.0, 0.5, 0.2) -- 橙色=冷却中
            end
            row.statusText:Show()

            row.killedText:SetText(string.format(L["AGO"], ed, eh))
            row.killedText:SetTextColor(0.75, 0.75, 0.75)
            row.killedText:Show()
        end
    end
end
