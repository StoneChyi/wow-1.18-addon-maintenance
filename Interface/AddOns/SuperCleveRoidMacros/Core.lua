--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny / brian / Mewtiny
	License: MIT License
]]
-- 仅在调试模式下安装自定义错误处理器，否则保持原样 by 武藤纯子酱 2026.7.2
-- 修复：原分支引用的 originalErrorHandler 恒为未定义全局（只在注释块里定义过），
-- 导致调试处理器无法链回原处理器、elseif 分支恒假。改为先捕获原处理器 by 武藤纯子酱 2026.9.11
local _origErrorHandler = geterrorhandler and geterrorhandler()
if CleveRoids.debug and seterrorhandler then
    seterrorhandler(function(msg)
        if msg and string.find(msg, "index a function value") then
            local trace = debugstack and debugstack(2, 20, 0) or "no stack available"
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[SCRM DEBUG] index function error:|r " .. tostring(msg))
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Stack:|r " .. tostring(trace))
        end
        if _origErrorHandler then
            return _origErrorHandler(msg)
        end
    end)
end

-- Setup to wrap our stuff in a table so we don't pollute the global environment
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}
_G.CleveRoids = CleveRoids
CleveRoids.lastItemIndexTime = 0
CleveRoids.initializationTimer = nil
CleveRoids.isActionUpdateQueued = true
CleveRoids.lastEquipTime = CleveRoids.lastEquipTime or {}
CleveRoids.lastWeaponSwapTime = 0
CleveRoids.equipInProgress = false

-- PERFORMANCE: Event throttling to reduce spam from high-frequency events
CleveRoids.lastUnitAuraUpdate = 0
CleveRoids.lastUnitHealthUpdate = 0
CleveRoids.lastUnitPowerUpdate = 0
CleveRoids.EVENT_THROTTLE = 0.1  -- 100ms throttle for high-frequency events

-- PERFORMANCE: Spell ID cache to avoid repeated GetSpellIdForName lookups
CleveRoids.spellIdCache = {}

-- PERFORMANCE: Spell name construction cache
CleveRoids.spellNameCache = {}

-- PERFORMANCE: Upvalues for frequently called global functions (avoid global lookups)
local GetTime = GetTime
local UnitExists = UnitExists
local UnitAffectingCombat = UnitAffectingCombat
local GetContainerItemLink = GetContainerItemLink
local GetContainerItemInfo = GetContainerItemInfo
local GetContainerNumSlots = GetContainerNumSlots
local GetInventoryItemLink = GetInventoryItemLink
local GetItemInfo = GetItemInfo
local PickupContainerItem = PickupContainerItem
local PickupInventoryItem = PickupInventoryItem
local EquipCursorItem = EquipCursorItem
local CursorHasItem = CursorHasItem
local ClearCursor = ClearCursor
local TargetUnit = TargetUnit
local pcall = pcall
local pairs = pairs
local ipairs = ipairs
local type = type
local tonumber = tonumber
local tostring = tostring
local string_find = string.find
local string_lower = string.lower
local string_gsub = string.gsub
local table_insert = table.insert
local table_getn = table.getn

-- Deferred stop-attack system (CheapShot pattern)
-- Stops autoattack and clears target. OnUpdate keeps clearing target while
-- autoattack is queued to prevent any swing from landing. No retarget.
local _DeferStopFrame = CreateFrame("Frame")
local _deferStopActive = false
local _deferStartTime = 0
local DEFER_STOP_TIMEOUT = 0.5

_DeferStopFrame:SetScript("OnUpdate", function()
    if not _deferStopActive then
        _DeferStopFrame:Hide()
        return
    end

    -- 性能清理：删除了此处一次结果未被使用的 GetCurrentCastingInfo 调用（下方已有同调用） by 武藤纯子酱 2026.8.31

    -- Timeout: stop polling
    if (GetTime() - _deferStartTime) >= DEFER_STOP_TIMEOUT then
        _deferStopActive = false
        _DeferStopFrame:Hide()
        return
    end

    -- While autoattack is queued, keep clearing target to prevent swings
    -- 修复：无 Nampower 时 GetCurrentCastingInfo 为 nil，原直接调用会红字；改为先守卫
    -- （无 Nampower → autoattack 视为 nil → 走 else 分支直接停止轮询）by 武藤纯子酱 2026.9.11
    local autoattack
    if GetCurrentCastingInfo then
        local _,_,_,_,_,_,aa = GetCurrentCastingInfo()
        autoattack = aa
    end
    if autoattack == 1 then
        if UnitExists("target") then
            ClearTarget()
        end
    else
        -- Autoattack stopped, done
        _deferStopActive = false
        _DeferStopFrame:Hide()
    end
end)
_DeferStopFrame:Hide()

function CleveRoids.DeferStopAttack()
    CleveRoids.CurrentSpell.autoAttack = false
    CleveRoids.CurrentSpell.autoAttackLock = false
    _deferStartTime = GetTime()
    -- Only toggle auto-attack OFF if it's currently active (avoid turning it ON)
    local attackSlot = CleveRoids.GetProxyActionSlot(CleveRoids.Localized.Attack)
    if attackSlot and CleveRoids.Hooks.IsCurrentAction(attackSlot) then
        AttackTarget()
    end
    ClearTarget()
    _deferStopActive = true
    _DeferStopFrame:Show()
end

-- PERFORMANCE: Module-level constant for boolean conditionals (avoid per-call table creation)
local BOOLEAN_CONDITIONALS = {
    combat = true,
    nocombat = true,
    stealth = true,
    nostealth = true,
    channeled = true,
    nochanneled = true,
    checkchanneled = true,
    checkcasting = true,
    dead = true,
    alive = true,
    help = true,
    harm = true,
    exists = true,
    party = true,
    raid = true,
    resting = true,
    noresting = true,
    isplayer = true,
    isnpc = true,
    mhimbue = true,
    nomhimbue = true,
    ohimbue = true,
    noohimbue = true,
    group = true,
    nogroup = true,
    moving = true,
    nomoving = true,
    stopattack = true,
    pet = true,
    nopet = true,
    bg = true,
    nobg = true,
    move = true, -- 新增 by 武藤纯子酱 2026.1.25
    nomove = true, -- 新增 by 武藤纯子酱 2026.1.25
    mv = true, -- 修复：mv/nomv 是 moving/nomoving 的缩写别名，必须登记为布尔条件，否则裸写 [mv] 时值是动作名恒为 false by 武藤纯子酱 2026.8.31
    nomv = true,
    petdead = true, -- 新增：宠物死亡/存活布尔条件 by 武藤纯子酱 2026.8.31
    petalive = true,
    nopetdead = true, -- 取反版 by 武藤纯子酱 2026.8.31
    nopetalive = true,
    -- 修复：noparty/noraid 未登记为布尔条件，裸写时值是动作名字符串，会被当 unit 处理 →
    -- 条件恒真（静默失效）by 武藤纯子酱 2026.9.11
    noparty = true,
    noraid = true,
    indoors = true, -- 正式服拼法别名（→ indoor），裸写 [indoors] 需登记为布尔条件 by 武藤纯子酱 2026.9.3
    outdoors = true, -- 正式服拼法别名（→ outdoor）by 武藤纯子酱 2026.9.3
    cursor = true, -- 光标上有拖拽物（经 CursorHasItem/Spell/Macro 间接实现），裸写 [cursor] 需登记 by 武藤纯子酱 2026.9.3
    nocursor = true, -- 取反版 by 武藤纯子酱 2026.9.3
    bonusbar = true, -- 临时动作条显示中（BonusActionBarFrame:IsShown），裸写 [bonusbar] 需登记 by 武藤纯子酱 2026.9.3
    nobonusbar = true, -- 取反版 by 武藤纯子酱 2026.9.3
    -- 鼠标按键条件（[btn1]/[button1] 与 [btn:N]/[button:N] 冒号写法映射后的目标） by 武藤纯子酱 2026.9.23
    btn1 = true, btn2 = true, btn3 = true, btn4 = true, btn5 = true,
    button1 = true, button2 = true, button3 = true, button4 = true, button5 = true,
    nobtn1 = true, nobtn2 = true, nobtn3 = true, nobtn4 = true, nobtn5 = true,
    nobutton1 = true, nobutton2 = true, nobutton3 = true, nobutton4 = true, nobutton5 = true,
}

local requirementCheckFrame = CreateFrame("Frame")
requirementCheckFrame:RegisterEvent("ADDON_LOADED")
requirementCheckFrame:SetScript("OnEvent", function()
    if arg1 ~= "SuperCleveRoidMacros" then return end

    -- Check requirements immediately when our addon loads
    -- 修复：改用 Init.lua 已计算好的探测结果，避免在兼容层打桩后重新探测导致误判
    -- by 武藤纯子酱 2026.9.11
    local hasNampower = CleveRoids.hasNampower
    local hasUnitXP = CleveRoids.hasUnitXP
    local hasNampower30 = hasNampower and CleveRoids.NampowerAPI
        and CleveRoids.NampowerAPI.HasMinimumVersion(3, 0, 0)

    if not hasNampower30 or not hasUnitXP then
        -- Show warnings (don't disable — tearing down a partially-initialized addon causes hangs)
        if not hasNampower then
            CleveRoids.Print("|cFFFF9900WARNING:|r |cFF00FFFFAvitasia's Nampower v3.0.0+|r is required:")
            CleveRoids.Print("https://gitea.com/avitasia/nampower")
            CleveRoids.Print("Many features will be unavailable without Nampower.")
        elseif not hasNampower30 then
            local major, minor, patch = CleveRoids.NampowerAPI.GetVersion()
            CleveRoids.Print(format("|cFFFF9900WARNING:|r |cFF00FFFFNampower v3.0.0+|r is required (you have v%d.%d.%d):", major, minor, patch))
            CleveRoids.Print("https://gitea.com/avitasia/nampower")
        end
        if not hasUnitXP then
            CleveRoids.Print("|cFFFF9900WARNING:|r |cFF00FFFFKonaka's UnitXP_SP3|r is required:")
            CleveRoids.Print("https://codeberg.org/konaka/UnitXP_SP3")
        end
    end

    -- Requirements met - allow normal initialization
    CleveRoids.Print("|cFF4477FFSuperCleveR|r|cFFFFFFFFoid Macros|r |cFF00FF00Loaded|r - See the README.")

    -- Unregister this check frame
    this:UnregisterAllEvents()
end)

local SLOT_TO_INVID = {
    ["MainHandSlot"] = 16,
    ["SecondaryHandSlot"] = 17,
    ["RangedSlot"] = 18,
    ["HeadSlot"] = 1,
    ["NeckSlot"] = 2,
    ["ShoulderSlot"] = 3,
    ["ChestSlot"] = 5,
    ["WaistSlot"] = 6,
    ["LegsSlot"] = 7,
    ["FeetSlot"] = 8,
    ["WristSlot"] = 9,
    ["HandsSlot"] = 10,
    ["Finger0Slot"] = 11,
    ["Finger1Slot"] = 12,
    ["Trinket0Slot"] = 13,
    ["Trinket1Slot"] = 14,
    ["BackSlot"] = 15,
    ["ShirtSlot"] = 4,
    ["TabardSlot"] = 19,
}

local function GetInventoryIdFromSlot(slotName)
    return SLOT_TO_INVID[slotName] or GetInventorySlotInfo(slotName)
end

-- Check if slot 18 is a relic (no GCD) for current player class
local function IsRelicSlot(slot)
    if slot ~= 18 then return false end
    local playerClass = CleveRoids.playerClass
    return playerClass == "PALADIN" or playerClass == "DRUID" or playerClass == "SHAMAN"
end

-- PERFORMANCE: Cache GetTime() result for cooldown checks within same frame
-- Slot 18 (relic/idol/libram/totem) has no GCD for Paladin/Druid/Shaman
local function IsSlotOnCooldown(slot, now)
    -- Relics have no GCD - skip cooldown check entirely
    if IsRelicSlot(slot) then
        return false
    end

    now = now or GetTime()
    local slotTime = CleveRoids.lastEquipTime[slot] or 0
    local globalTime = CleveRoids.lastGlobalEquipTime or 0

    return (now - slotTime) < CleveRoids.EQUIP_COOLDOWN or
           (now - globalTime) < CleveRoids.EQUIP_GLOBAL_COOLDOWN
end

-- PERFORMANCE: Consolidated cursor handling, fewer CursorHasItem() calls
local function PerformEquipSwap(item, inventoryId, useQueueScript)
    if not item or not inventoryId then return false end

    -- Check if in combat and swapping weapons
    -- Slot 18 (ranged) is only a weapon for Hunter/Warrior/Rogue/Mage/Warlock/Priest
    -- For Druid/Paladin/Shaman, slot 18 is idol/libram/totem - can swap freely
    local isWeapon = (inventoryId == 16 or inventoryId == 17)
    if inventoryId == 18 then
        -- Use cached playerClass for performance
        local playerClass = CleveRoids.playerClass
        -- Only treat slot 18 as weapon for classes that use ranged weapons
        isWeapon = (playerClass == "HUNTER" or playerClass == "WARRIOR" or
                    playerClass == "ROGUE" or playerClass == "MAGE" or
                    playerClass == "WARLOCK" or playerClass == "PRIEST")
    end

    if isWeapon and UnitAffectingCombat("player") then
        -- Don't swap while casting
        if CleveRoids.CurrentSpell.type ~= "" then
            return false
        end

        -- Check for on-swing spells if available (Nampower)
        if GetCurrentCastingInfo then
            local castId, _, _, casting, channeling, onswing = GetCurrentCastingInfo()

            if onswing == 1 then
                return false
            end

            -- If casting/channeling and QueueScript available, queue the swap for after cast
            if (casting == 1 or channeling == 1) and QueueScript and useQueueScript and item.name then
                local script = string.format('EquipItemByName("%s",%d)', item.name, inventoryId)
                QueueScript(script, 3)  -- Priority 3 = after queued spells
                return true
            end
        end
    end

    -- PERFORMANCE: Try EquipItemByName first if available (handles everything internally)
    if item.name and EquipItemByName then
        local ok = pcall(EquipItemByName, item.name, inventoryId)
        if ok then return true end
    end

    -- Fallback: Manual pickup and equip
    if item.bagID and item.slot then
        PickupContainerItem(item.bagID, item.slot)
    elseif item.inventoryID then
        PickupInventoryItem(item.inventoryID)
    else
        return false
    end

    -- Single cursor check after pickup attempt
    if not CursorHasItem() then
        return false
    end

    EquipCursorItem(inventoryId)
    local success = not CursorHasItem()
    ClearCursor()
    return success
end

-- PERFORMANCE: Get a queue entry from pool or create new
local function GetQueueEntry()
    local pool = CleveRoids.queueEntryPool
    local n = pool and table_getn(pool) or 0
    if n > 0 then
        local entry = pool[n]
        pool[n] = nil
        return entry
    end
    return {}
end

-- PERFORMANCE: Return entry to pool for reuse
local function ReleaseQueueEntry(entry)
    if not entry then return end
    -- Clear the entry (set to nil, don't create new table)
    entry.item = nil
    entry.slotName = nil
    entry.inventoryId = nil
    entry.queueTime = nil
    entry.retries = nil
    entry.maxRetries = nil
    entry.itemId = nil
    -- Add to pool (max 10 pooled entries)
    local pool = CleveRoids.queueEntryPool
    if table_getn(pool) < 10 then
        table_insert(pool, entry)
    end
end

-- PERFORMANCE: Swap-and-pop removal (O(1) instead of O(n))
local function RemoveQueueEntry(i)
    local queue = CleveRoids.equipmentQueue
    local n = CleveRoids.equipmentQueueLen
    local entry = queue[i]

    if i < n then
        queue[i] = queue[n]
    end
    queue[n] = nil
    CleveRoids.equipmentQueueLen = n - 1

    ReleaseQueueEntry(entry)
end

-- Queue equipment swap function
function CleveRoids.QueueEquipItem(item, slotName)
    if not item or not slotName then return false end

    local inventoryId = GetInventoryIdFromSlot(slotName)
    if not inventoryId then return false end

    local now = GetTime()
    local itemId = item.id

    -- PERFORMANCE: Check for duplicate queue entries before adding
    local queue = CleveRoids.equipmentQueue
    local queueLen = CleveRoids.equipmentQueueLen
    for i = 1, queueLen do
        local q = queue[i]
        if q and q.inventoryId == inventoryId and q.itemId == itemId then
            return false  -- Already queued
        end
    end

    -- Try immediate equip if not on cooldown (use QueueScript for smoother mid-cast swaps)
    if not IsSlotOnCooldown(inventoryId, now) then
        local success = PerformEquipSwap(item, inventoryId, true)

        if success then
            -- Don't set cooldowns for relic slots (no GCD)
            if not IsRelicSlot(inventoryId) then
                CleveRoids.lastEquipTime[inventoryId] = now
                CleveRoids.lastGlobalEquipTime = now
            end
            return true
        end
    end

    -- Queue for later using pooled entry
    local entry = GetQueueEntry()
    entry.item = item
    entry.slotName = slotName
    entry.inventoryId = inventoryId
    entry.queueTime = now
    entry.retries = 0
    entry.maxRetries = 5
    entry.itemId = itemId

    CleveRoids.equipmentQueueLen = queueLen + 1
    queue[CleveRoids.equipmentQueueLen] = entry

    -- PERFORMANCE: Start the queue processing frame
    if CleveRoids.equipQueueFrame then
        CleveRoids.equipQueueFrame:Show()
    end

    return false
end

-- PERFORMANCE: Process equipment queue (called from self-disabling frame)
function CleveRoids.ProcessEquipmentQueue()
    local queueLen = CleveRoids.equipmentQueueLen
    if queueLen == 0 then return end

    local now = GetTime()
    local queue = CleveRoids.equipmentQueue
    local i = 1

    while i <= CleveRoids.equipmentQueueLen do
        local queued = queue[i]

        -- Remove expired entries first (>10 seconds old)
        if (now - queued.queueTime) > 10 then
            RemoveQueueEntry(i)
            -- Don't increment i, we swapped in the last element
        elseif not IsSlotOnCooldown(queued.inventoryId, now) then
            -- Try to equip (use QueueScript for smoother mid-cast swaps)
            local success = PerformEquipSwap(queued.item, queued.inventoryId, true)

            if success then
                -- Don't set cooldowns for relic slots (no GCD)
                if not IsRelicSlot(queued.inventoryId) then
                    CleveRoids.lastEquipTime[queued.inventoryId] = now
                    CleveRoids.lastGlobalEquipTime = now
                end
                RemoveQueueEntry(i)
            else
                queued.retries = queued.retries + 1
                if queued.retries >= queued.maxRetries then
                    RemoveQueueEntry(i)
                else
                    i = i + 1
                end
            end
        else
            i = i + 1
        end
    end
end

-- PERFORMANCE: Self-disabling frame for queue processing with throttling
-- Only processes every EQUIP_QUEUE_INTERVAL instead of every frame
CleveRoids.EQUIP_QUEUE_INTERVAL = 0.1  -- 100ms between queue checks (was 50ms)
CleveRoids.equipQueueLastUpdate = 0
CleveRoids.equipQueueFrame = CreateFrame("Frame")
CleveRoids.equipQueueFrame:Hide()

-- PERFORMANCE: Upvalue for faster access in OnUpdate
local equipQueueFrame = CleveRoids.equipQueueFrame
local equipQueueInterval = CleveRoids.EQUIP_QUEUE_INTERVAL

equipQueueFrame:SetScript("OnUpdate", function()
    -- Prevent operations during shutdown (crash prevention)
    if CleveRoids.isShuttingDown then return end

    -- PERFORMANCE: Use arg1 (elapsed time) if available, otherwise GetTime()
    local elapsed = arg1
    if elapsed then
        CleveRoids.equipQueueLastUpdate = (CleveRoids.equipQueueLastUpdate or 0) + elapsed
        if CleveRoids.equipQueueLastUpdate < equipQueueInterval then
            return  -- Throttle: skip this frame
        end
        CleveRoids.equipQueueLastUpdate = 0
    else
        local now = GetTime()
        if (now - (CleveRoids.equipQueueLastUpdate or 0)) < equipQueueInterval then
            return
        end
        CleveRoids.equipQueueLastUpdate = now
    end

    CleveRoids.ProcessEquipmentQueue()
    if CleveRoids.equipmentQueueLen == 0 then
        this:Hide()
    end
end)

-- Improved DisableAddon function
function CleveRoids.DisableAddon(reason)
    -- Prevent multiple disable calls
    if CleveRoids.disabled then return end

    -- Mark state
    CleveRoids.disabled = true

    -- Stop main frame activity
    if CleveRoids.Frame then
        if CleveRoids.Frame.UnregisterAllEvents then
            CleveRoids.Frame:UnregisterAllEvents()
        end
        if CleveRoids.Frame.SetScript then
            CleveRoids.Frame:SetScript("OnEvent", nil)
            CleveRoids.Frame:SetScript("OnUpdate", nil)
        end
    end

    -- Neuter all slash commands
    if SlashCmdList then
        local disabledMsg = function()
            CleveRoids.Print("|cffff0000SuperCleveRoidMacros is disabled|r" ..
                (reason and (": " .. tostring(reason)) or ""))
        end

        SlashCmdList.CLEVEROID = disabledMsg
        SlashCmdList.CAST = disabledMsg
        SlashCmdList.USE = disabledMsg
        SlashCmdList.EQUIP = disabledMsg
        SlashCmdList.EQUIPMH = disabledMsg
        SlashCmdList.EQUIPOH = disabledMsg
    end

    -- Try to disable for next login
    local addonName = "SuperCleveRoidMacros"
    if type(DisableAddOn) == "function" then
        pcall(DisableAddOn, addonName)
    end

    -- Final notice
    CleveRoids.Print("|cffff0000Disabled|r - " .. (reason or "Unknown reason"))
    CleveRoids.Print("Please install required dependencies and /reload")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("VARIABLES_LOADED")
frame:SetScript("OnEvent", function()
    if not CleveRoidMacros then CleveRoidMacros = {} end

    if type(CleveRoidMacros.realtime) ~= "number" then
        CleveRoidMacros.realtime = 0
    end

    if type(CleveRoidMacros.refresh) ~= "number" then
        -- 性能优化：默认 5→10（tick 0.2s→0.1s），与 TestForActiveAction 的 0.1s 求值缓存 TTL 对齐，
        -- 原配置下每次 tick 缓存必已过期、命中率恒为 0 by 武藤纯子酱 2026.8.31
        CleveRoidMacros.refresh = 10
    end

    if type(CleveRoidMacros.macrocheck) ~= "number" then
        CleveRoidMacros.macrocheck = 1  -- enabled by default
    end

    if type(CleveRoidMacros.projectileSpeed) ~= "number" then -- 默认速度 by 武藤纯子酱 2026.8.9
        CleveRoidMacros.projectileSpeed = 25
    end

    if type(CleveRoidMacros.fovCone) ~= "number" then -- @fov 视野锥 2-10（越小越窄）by 武藤纯子酱 2026.9.12
        CleveRoidMacros.fovCone = 2
    end
    if type(CleveRoidMacros.fovRange) ~= "number" then -- @fov 最大探测距离 by 武藤纯子酱 2026.9.12
        CleveRoidMacros.fovRange = 41
    end

    if type(CleveRoidMacros.clipMode) ~= "number" then -- 引导打断模式 1/2/3，默认 2 by 武藤纯子酱 2026.9.12
        CleveRoidMacros.clipMode = 2
    end

    if type(CleveRoidMacros.autoLearnImmunity) ~= "number" then -- 免疫自动学习 0/1，默认 0（静态免疫表已内置）by 武藤纯子酱 2026.9.16
        CleveRoidMacros.autoLearnImmunity = 0
    end
end)

-- Queues a full update of all action bars.
-- This is called by game event handlers to avoid running heavy logic inside the event itself.
function CleveRoids.QueueActionUpdate()
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.isActionUpdateQueued = true
    end
end

local function _StripColor(s)
  if not s then return s end
  if string.sub(s,1,2) == "|c" then return string.sub(s,11,-3) end
  return s
end

local _ReagentBySpell = {
  ["Vanish"] = "Flash Powder",    -- 5140
  ["Blind"]  = "Blinding Powder", -- 5530
}

-- Expose for use in Generic.lua (IndexSpells fallback)
CleveRoids.ReagentBySpell = _ReagentBySpell

-- Minimal map for rogue reagents; extend as needed
local _ReagentIdByName = {
    ["Flash Powder"]   = 5140, -- Vanish
    ["Blinding Powder"] = 5530, -- Blind
}

-- Lazy bag-scan tooltip (only if we need to scan a bag slot by name)
local function CRM_GetBagScanTip()
  local tip = _G.CleveRoidsBagScanTip
  if tip then return tip end
  local ok, created = pcall(CreateFrame, "GameTooltip", "CleveRoidsBagScanTip", UIParent, "GameTooltipTemplate")
  if ok and created then
    tip = created
  else
    tip = CreateFrame("GameTooltip", "CleveRoidsBagScanTip", UIParent)
    local L1 = tip:CreateFontString("$parentTextLeft1",  nil, "GameTooltipText")
    local R1 = tip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
    tip:AddFontStrings(L1, R1)
    for i=2,10 do
      tip:CreateFontString("$parentTextLeft"..i,  nil, "GameTooltipText")
      tip:CreateFontString("$parentTextRight"..i, nil, "GameTooltipText")
    end
  end
  tip:SetOwner(WorldFrame, "ANCHOR_NONE")
  _G.CleveRoidsBagScanTip = tip
  return tip
end

-- Return total in *bags only* (not bank), by id when possible; fallback to name
-- PERFORMANCE: Uses CleveRoids.Items cache for O(1) lookup when available
function CleveRoids.GetReagentCount(reagentName)
  if not reagentName or reagentName == "" then return 0 end

  -- Fast path: check cache first
  local Items = CleveRoids.Items
  if Items then
    local wantId = _ReagentIdByName[reagentName]

    -- Try by ID first if we have a mapping
    if wantId then
      local itemName = Items[wantId]
      if itemName then
        local itemData = Items[itemName]
        if itemData and itemData.count and not itemData.inventoryID then
          -- Item is in bags (not equipped), return cached count
          return itemData.count
        end
      end
    end

    -- Try by name
    local itemData = Items[reagentName]
    if type(itemData) == "string" then
      itemData = Items[itemData]  -- Resolve indirection
    end
    if itemData and type(itemData) == "table" and itemData.count and not itemData.inventoryID then
      return itemData.count
    end

    -- Try lowercase
    local lowerName = string.lower(reagentName)
    local resolved = Items[lowerName]
    if type(resolved) == "string" then
      itemData = Items[resolved]
    elseif type(resolved) == "table" then
      itemData = resolved
    end
    if itemData and type(itemData) == "table" and itemData.count and not itemData.inventoryID then
      return itemData.count
    end
  end

  -- Slow path fallback: full bag scan (only when cache miss)
  local wantId = _ReagentIdByName[reagentName]
  local total = 0

  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local _, count = GetContainerItemInfo(bag, slot)
      count = count or 0
      local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
      if link then
        local _, _, idstr = string.find(link, "item:(%d+)")
        local id = idstr and tonumber(idstr) or nil
        if (wantId and id == wantId) or (not wantId and string.find(link, "%["..reagentName.."%]")) then
          total = total + count
        end
      else
        -- Fallback: scan bag slot tooltip for the name (expensive, only when no link)
        local tip = CRM_GetBagScanTip()
        tip:ClearLines()
        tip:SetBagItem(bag, slot)
        local left1 = _G[tip:GetName().."TextLeft1"]
        local name = left1 and left1:GetText()
        if name and name == reagentName then
          total = total + count
        end
      end
    end
  end

  return total
end

-- Live bag scan for item count, bypassing Items cache to avoid stale counts
-- during bag moves (especially backpack ↔ other bag transitions)
-- 性能优化：0.1s TTL 按物品名缓存计数（原实现每次全背包扫，被 GetActionCount
-- 的每次按钮刷新 + [inbag:X] 条件求值反复调用）。BAG_UPDATE 时整体失效 by 武藤纯子酱 2026.8.31
local _liveItemCountCache = {}
function CleveRoids.GetLiveItemCount(itemName)
  if not itemName or itemName == "" then return 0 end

  local nowL = GetTime()
  local cached = _liveItemCountCache[itemName]
  if cached and (nowL - cached.t) < 0.1 then
    return cached.count
  end

  -- Escape Lua pattern special chars in item name to avoid crashes
  local escaped = string.gsub(itemName, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
  local pattern = "%[" .. escaped .. "%]"
  local lowerPattern = string.lower(pattern)
  local total = 0
  for bag = 0, 4 do
    local slots = GetContainerNumSlots(bag) or 0
    for slot = 1, slots do
      local link = GetContainerItemLink and GetContainerItemLink(bag, slot)
      if link and string.find(string.lower(link), lowerPattern) then
        local _, count = GetContainerItemInfo(bag, slot)
        total = total + (count or 0)
      end
    end
  end

  if not cached then
    cached = {}
    _liveItemCountCache[itemName] = cached
  end
  cached.t = nowL
  cached.count = total
  return total
end

function CleveRoids.InvalidateLiveItemCountCache()
  _liveItemCountCache = {}
end

function CleveRoids.GetSpellCost(spellSlot, bookType)
  -- Fast path: existing fixed-slot read
  CleveRoids.Frame:SetOwner(WorldFrame, "ANCHOR_NONE")
  CleveRoids.Frame:SetSpell(spellSlot, bookType)

  local cost, reagent
  local costText = CleveRoids.Frame.costFontString:GetText()
  if costText then
      _, _, cost = string.find(costText, "^(%d+)%s+[^yYsS]")
  end

  local reagentText = CleveRoids.Frame.reagentFontString:GetText()
  if reagentText then
      _, _, reagent = string.find(reagentText, "^Reagents?%s*:%s*(.*)")
  end
  reagent = _StripColor(reagent)
  if reagent == "" then reagent = nil end

  -- Fallback: scan all lines on a named tooltip (handles Vanish layout)
  if not reagent or not cost then
    local tip = CleveRoidsTooltipScan
    if not tip then
      -- belt & suspenders: create if somehow missing
      local ok,_ = pcall(CreateFrame, "GameTooltip", "CleveRoidsTooltipScan", UIParent, "GameTooltipTemplate")
      if not ok or not CleveRoidsTooltipScan then
        CleveRoidsTooltipScan = CreateFrame("GameTooltip", "CleveRoidsTooltipScan", UIParent)
        local L1 = CleveRoidsTooltipScan:CreateFontString("$parentTextLeft1",  nil, "GameTooltipText")
        local R1 = CleveRoidsTooltipScan:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
        CleveRoidsTooltipScan:AddFontStrings(L1, R1)
        for i=2,32 do
          CleveRoidsTooltipScan:CreateFontString("$parentTextLeft"..i,  nil, "GameTooltipText")
          CleveRoidsTooltipScan:CreateFontString("$parentTextRight"..i, nil, "GameTooltipText")
        end
      end
      CleveRoidsTooltipScan:SetOwner(WorldFrame, "ANCHOR_NONE")
      tip = CleveRoidsTooltipScan
    end

    tip:ClearLines()
    tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tip:SetSpell(spellSlot, bookType)

    local base = tip:GetName() or "CleveRoidsTooltipScan"
    local maxLines = (tip.NumLines and tip:NumLines()) or 32

    for i = 1, maxLines do
      local L = _G[base.."TextLeft"..i]
      local R = _G[base.."TextRight"..i]
      local lt = L and L:GetText() or ""
      local rt = R and R:GetText() or ""

      if not reagent then
        if string.find(lt, "^[Rr]eagents?%s*:") then
          reagent = _StripColor((rt ~= "" and rt) or (string.gsub(lt, "^[Rr]eagents?%s*:%s*", "")))
        elseif string.find(rt, "^[Rr]eagents?%s*:") then
          reagent = _StripColor((lt ~= "" and lt) or (string.gsub(rt, "^[Rr]eagents?%s*:%s*", "")))
        end
        if reagent == "" then reagent = nil end
      end

      if not cost and rt ~= "" then
          local _, _, num = string.find(rt, "^(%d+)%s+(Mana|Energy|Rage|Focus)")
          if num then cost = tonumber(num) end
      end

      if reagent and cost then break end
    end
  end

  if not reagent or reagent == "" then
    reagent = nil
    local name = GetSpellName(spellSlot, bookType)
    if name then
        name = CleveRoids.StripRank(name)
        reagent = _ReagentBySpell[name]
    end
  end

  return (cost and tonumber(cost) or 0), (reagent and reagent ~= "" and tostring(reagent) or nil)
end

function CleveRoids.GetProxyActionSlot(slot)
    if not slot then return end
    return CleveRoids.actionSlots[slot] or CleveRoids.actionSlots[slot.."()"]
end

-- Resolves nested macro references for #showtooltip propagation
-- If an action is a {MacroName} reference and that macro has #showtooltip,
-- returns the inner macro's active action; otherwise returns nil
-- depth parameter prevents infinite recursion
function CleveRoids.ResolveNestedMacroActive(action, depth)
    if not action or not action.action then return nil end
    depth = depth or 0
    if depth > 5 then return nil end  -- prevent infinite recursion

    -- Check if this action is a macro reference {MacroName}
    local macroName = CleveRoids.GetMacroNameFromAction(action.action)
    if not macroName then return nil end

    -- Get or parse the inner macro
    local innerMacro = CleveRoids.GetMacro(macroName)
    if not innerMacro then
        innerMacro = CleveRoids.ParseMacro(macroName)
    end
    if not innerMacro or not innerMacro.actions then return nil end

    -- Check if inner macro has #showtooltip (indicated by having a tooltip or action list)
    if not innerMacro.actions.tooltip and table.getn(innerMacro.actions.list or {}) == 0 then
        return nil
    end

    -- Run TestForActiveAction on inner macro to get its current active
    CleveRoids.TestForActiveAction(innerMacro.actions)

    -- If inner macro has an active action, check if it's also a nested macro
    if innerMacro.actions.active then
        local deeperActive = CleveRoids.ResolveNestedMacroActive(innerMacro.actions.active, depth + 1)
        if deeperActive then
            return deeperActive
        end
        return innerMacro.actions.active
    end

    return nil
end

-- ============================================================================
-- 图标路径专用：特殊单位（@mostwounded/@filter/@cursive 等）扫描结果缓存 by 武藤纯子酱 2026.8.31
-- 仅用于 TestAction/TestForActiveAction（图标状态）路径——按键路径不经过这里，
-- 永远实时扫描，宏准确性不受影响。缓存键 = 宏行参数串（字符串驻留，查表零分配），
-- TTL = 0.1 秒（同一宏行 0.1 秒内最多扫描 10 次，而非随事件频率 30+ 次/秒）。
-- ============================================================================
local _specialUnitTestCache = {}
-- 修复：缓存只按 0.1s TTL 限读取，但 bucket/cacheKey 从不清理会无限增长。
-- 按存储次数每满 200 次整体清空（纯 0.1s 优化缓存，清空零语义影响） by 武藤纯子酱 2026.8.31
local _specialUnitTestCacheStores = 0

local function GetCachedSpecialUnit(cacheKey, unitId, ctx)
    -- 修复：不带 @目标的宏（conditionals.target 为 nil）会走到这里，
    -- nil 不能作为表索引（table index is nil），直接透传原语义（返回 nil）不缓存 by 武藤纯子酱 2026.8.31
    if type(unitId) ~= "string" then
        return CleveRoids.ResolveSpecialUnit(unitId, ctx)
    end

    local now = GetTime()
    local bucket = _specialUnitTestCache[cacheKey]
    if bucket then
        local entry = bucket[unitId]
        if entry and (now - entry.t) < 0.1 then
            return entry.r
        end
    end

    local result = CleveRoids.ResolveSpecialUnit(unitId, ctx)
    if not bucket then
        bucket = {}
        _specialUnitTestCache[cacheKey] = bucket
    end
    _specialUnitTestCacheStores = _specialUnitTestCacheStores + 1
    if _specialUnitTestCacheStores >= 200 then
        _specialUnitTestCacheStores = 0
        _specialUnitTestCache = {}
        bucket = {}
        _specialUnitTestCache[cacheKey] = bucket
    end
    bucket[unitId] = { t = now, r = result }
    return result
end

-- ============================================================================
-- GUID 事件相关性过滤 by 武藤纯子酱 2026.8.31
-- Nampower 的 UNIT_*_GUID 事件会对周围每个单位触发（人堆场景每秒数百个），
-- 而图标刷新只关心玩家/目标/鼠标悬浮/宠物/队友团队。非相关单位（成群的怪物）
-- 的事件直接忽略，大幅降低战斗中的 TestForAllActiveActions 触发频率。
-- 队伍/团队 GUID 集合每 1 秒惰性重建；目标/悬浮/宠物因随选择变化，用 UnitIsUnit 兜底。
-- ============================================================================
local _relevantGuids = {}
local _relevantGuidsBuilt = 0

function CleveRoids.IsMacroRelevantGuid(guid)
    if not guid then return false end
    if guid == CleveRoids.playerGuid then return true end
    if _relevantGuids[guid] then return true end

    local now = GetTime()
    -- 性能优化：TTL 定为 1.0s —— 这是"队伍/团队人员名单"缓存而非战斗数据（0.1s 过度）：
    -- 40 人团每次重建 ≈ 80 组 API（UnitExists+GetGUID × raid+raidpet），0.1s TTL 下团战期间
    -- 每 0.1s 重建一次 ≈ 800 API/s。名单变动本身低频，1s 延迟无感知 by 武藤纯子酱 2026.8.31
    if (now - _relevantGuidsBuilt) >= 1.0 then
        _relevantGuidsBuilt = now
        local k = next(_relevantGuids)
        while k do _relevantGuids[k] = nil; k = next(_relevantGuids) end
        for i = 1, 4 do
            local u = "party" .. i
            if UnitExists(u) then local g = CleveRoids.GetGUID(u); if g then _relevantGuids[g] = true end end
            local pu = "partypet" .. i
            if UnitExists(pu) then local g = CleveRoids.GetGUID(pu); if g then _relevantGuids[g] = true end end
        end
        if UnitInRaid("player") then
            for i = 1, GetNumRaidMembers() do
                local u = "raid" .. i
                if UnitExists(u) then local g = CleveRoids.GetGUID(u); if g then _relevantGuids[g] = true end end
                local ru = "raidpet" .. i
                if UnitExists(ru) then local g = CleveRoids.GetGUID(ru); if g then _relevantGuids[g] = true end end
            end
        end
    end

    if UnitIsUnit(guid, "target") or UnitIsUnit(guid, "mouseover") or UnitIsUnit(guid, "pet") then
        _relevantGuids[guid] = true
        return true
    end
    return false
end

function CleveRoids.TestForActiveAction(actions)
    if not actions then return end

    -- 性能优化（P0-1）：图标路径的条件求值结果缓存，TTL 0.1 秒 by 武藤纯子酱 2026.8.31
    -- 动作条图标的状态刷新允许 ≤0.1 秒延迟；实际按键走 DoCast/DoWithConditionals，
    -- 不经过本函数，宏判定永远实时。TTL 过期或首次调用才重新求值。
    local nowT = GetTime()
    if actions._testCacheTime and (nowT - actions._testCacheTime) < 0.1 then
        return false
    end
    actions._testCacheTime = nowT

    local currentActive = actions.active
    local currentSequence = actions.sequence
    local hasActive = false
    local newActiveAction = nil
    local newSequence = nil
    local firstUnconditional = nil

    -- Use tooltip-only branch when:
    -- 1. #showtooltip has an explicit argument (explicitTooltip = true), OR
    -- 2. #showtooltip exists but action list is empty (bare "#showtooltip")
    -- This ensures explicit tooltips always show their icon/usability correctly.
    --if actions.tooltip and (actions.explicitTooltip or table.getn(actions.list) == 0) then -- 注释掉，actions.explicitTooltip会导致前面的条件参数失效 by 武藤纯子酱 2026.2.2
	    if actions.tooltip and table.getn(actions.list) == 0 then -- 换回原来的判断逻辑 by 武藤纯子酱 2026.2.2
        -- For explicit tooltips, directly use the tooltip as active action
        -- (actions.cmd/args are empty, so TestAction would fail)
        if actions.explicitTooltip then
            hasActive = true
            newActiveAction = actions.tooltip
        elseif CleveRoids.TestAction(actions.cmd or "", actions.args or "") then
            -- Bare #showtooltip (no arg) - validate with TestAction
            hasActive = true
            newActiveAction = actions.tooltip
        end

        -- Resolve nested macro references for #showtooltip propagation
        if hasActive and newActiveAction then
            local macroName = CleveRoids.GetMacroNameFromAction(actions.tooltip.action)
            if macroName then
                local resolved = CleveRoids.ResolveNestedMacroActive(actions.tooltip, 0)
                if resolved then
                    newActiveAction = resolved
                else
                    -- Inner macro didn't resolve - no active action
                    hasActive = false
                    newActiveAction = nil
                end
            end
        end
    else
        -- First pass: find first action with conditionals that passes
        for _, action in ipairs(actions.list) do
            local result = CleveRoids.TestAction(action.cmd, action.args)

            -- 性能优化：TestAction 内部已解析并缓存，直接复用其结果，避免第二次 GetParsedMsg
            -- by 武藤纯子酱 2026.9.11
            local conditionals = CleveRoids._lastParsedArgsConditionals

            -- Skip this action for icon display if it has the '?' prefix
            local shouldSkipForIcon = (type(conditionals) == "table" and conditionals.ignoretooltip == 1)
                or (CleveRoids._ignoretooltip == 1)

            -- break on first action that passes tests (unless it should be skipped for icon)
            if result and not shouldSkipForIcon then
                hasActive = true
                if action.sequence then
                    newSequence = action.sequence
                    newActiveAction = CleveRoids.GetCurrentSequenceAction(newSequence)
                    -- Check if current step is a stop step - if so, skip this sequence for icon
                    if newActiveAction and newActiveAction.action then
                        local stepLower = string.lower(CleveRoids.Trim(newActiveAction.action))
                        if stepLower == "nil" or stepLower == "null" or stepLower == "pass" or stepLower == "noop" then
                            hasActive = false
                            newActiveAction = nil
                            newSequence = nil
                        end
                    end
                    if not newActiveAction then hasActive = false end
                else
                    newActiveAction = action
                    -- Resolve nested macro references for #showtooltip propagation
                    -- If inner macro doesn't resolve, continue to next action
                    local macroName = CleveRoids.GetMacroNameFromAction(action.action)
                    if macroName then
                        local resolved = CleveRoids.ResolveNestedMacroActive(action, 0)
                        if resolved then
                            newActiveAction = resolved
                        else
                            -- Inner macro didn't resolve - try next action
                            hasActive = false
                            newActiveAction = nil
                        end
                    end
                end
                if hasActive then break end
            end
			
            -- Track first unconditional non-macro action as fallback
            if not conditionals and not firstUnconditional and not shouldSkipForIcon then
                -- Don't use unresolvable macro refs as fallback
                local macroName = CleveRoids.GetMacroNameFromAction(action.action)
                if not macroName then
                    firstUnconditional = action
                end
            end
        end

        -- If no conditional action passed, use first unconditional action
        if not hasActive and firstUnconditional then
            hasActive = true
            newActiveAction = firstUnconditional
        end
    end

    -- If the active action has no texture (item wasn't in bags at parse time),
    -- resolve it now via live bag lookup so the icon updates immediately
    if newActiveAction and not newActiveAction.texture
       and not newActiveAction.spell and not newActiveAction.petSpell then
        local freshItem = CleveRoids.GetItem(newActiveAction.action)
        if freshItem and freshItem.texture then
            newActiveAction.item = freshItem
            newActiveAction.texture = freshItem.texture
            newActiveAction.type = newActiveAction.type or "item"
        end
    end

    local changed = false
    if currentActive ~= newActiveAction or currentSequence ~= newSequence then
        actions.active = newActiveAction
        actions.sequence = newSequence
        changed = true
    end

    if not hasActive then
        if actions.active ~= nil or actions.sequence ~= nil then
             actions.active = nil
             actions.sequence = nil
             changed = true
        end
        return changed -- 缓存戳已在函数入口刷新 by 武藤纯子酱 2026.8.31
    end

    if actions.active then
        local previousUsable = actions.active.usable
        local previousOom = actions.active.oom
        local previousInRange = actions.active.inRange

        if actions.active.spell then
            -- Default to -1 (unknown) so we fall through to proxy slot or original function
            -- Only set to 1/0 when we have a definitive answer from IsSpellInRange
            actions.active.inRange = -1

            -- Enhanced nampower range check with spell ID support
			if IsSpellInRange then
                local unit = actions.active.conditionals and actions.active.conditionals.target or "target"
				if  unit == "cursor" then -- 判定是不是鼠标指向 by 武藤纯子酱 2025.11.28
					actions.active.inRange = true
				else
					-- 统一走特殊单位标识解析（focus/focustarget/cursive/mostwounded/filter/inherit 等） by 武藤纯子酱 2026.8.31
					-- 性能优化（P0-2）：图标路径扫描结果缓存 0.1 秒（按键路径不经此处，永远实时） by 武藤纯子酱 2026.8.31
					-- 修复：删除误写的全局 needRetarget（本作用域无此局部变量，纯全局污染且无读取者）
					-- by 武藤纯子酱 2026.9.11
					unit = GetCachedSpecialUnit(actions.active, unit, actions.active.conditionals)
					if unit == false then
						return false
					end
					local resolvedMark = CleveRoids.ResolveRaidMarkUnit(unit)
					if resolvedMark then unit = resolvedMark end

					-- PERFORMANCE: Cache spell name construction using two-level cache (no string concat for lookup)
					local castName = actions.active.action
					if actions.active.spell and actions.active.spell.name then
						local spellName = actions.active.spell.name
						local rank = actions.active.spell.rank
									 or (actions.active.spell.highest and actions.active.spell.highest.rank)
						if rank and rank ~= "" then
							-- Two-level cache: spellNameCache[spellName][rank] = "SpellName(Rank X)"
							local nameCache = CleveRoids.spellNameCache[spellName]
							if not nameCache then
								nameCache = {}
								CleveRoids.spellNameCache[spellName] = nameCache
							end
							castName = nameCache[rank]
							if not castName then
								castName = spellName .. "(" .. rank .. ")"
								nameCache[rank] = castName
							end
						end
					end

					-- PERFORMANCE: Try to get spell ID with caching
					local spellId = nil
					if GetSpellIdForName then
						-- Check cache first
						local cachedId = CleveRoids.spellIdCache[castName]
						if cachedId then
							spellId = cachedId
						else
							spellId = GetSpellIdForName(castName)
							if spellId and spellId > 0 then
								CleveRoids.spellIdCache[castName] = spellId
							end
						end
					end

					-- Check range using API wrapper (handles all cases properly)
					local API = CleveRoids.NampowerAPI
					local checkValue = spellId and spellId > 0 and spellId or castName

					if UnitExists(unit) then
						-- We have a target - use API wrapper for proper range checking
						-- API.IsSpellInRange handles: native check, -1 for self-cast, UnitXP fallback
						if API then
							local r = API.IsSpellInRange(checkValue, unit)
							if r ~= nil then
								actions.active.inRange = r
							end
						elseif IsSpellInRange then
							-- No API, use native directly
							local nativeResult = IsSpellInRange(checkValue, unit)
							if nativeResult == 0 or nativeResult == 1 then
								actions.active.inRange = nativeResult
							elseif nativeResult == -1 then
								-- Self-cast/ground-targeted spell, always in range
								actions.active.inRange = 1
							end
						end
					end
					-- No target: don't set inRange, let proxy slot / original behavior handle it
				end
			end

            -- Check if spell is usable first (handles forms, stances, and power type correctly)
            local isUsableBySpell, notEnoughPower = nil, nil
            if IsSpellUsable then
                -- pcall to handle spells not in spellbook (Nampower throws error)
                local ok, usable, oom = pcall(IsSpellUsable, actions.active.action)
                if ok then
                    isUsableBySpell, notEnoughPower = usable, oom
                end
            end

            -- For OOM check, use proper mana source
            if notEnoughPower ~= nil then
                -- Prefer IsSpellUsable result if available (Nampower)
                actions.active.oom = (notEnoughPower == 1)
            else
                -- Nampower：GetUnitPower(unit, 0) 直读原始法力字段（power1），与当前形态无关，
                -- 等价替代 SuperWoW UnitMana 的第二返回值（德鲁伊施法形态蓝量） by 武藤纯子酱 2026.9.1
                local manaToCheck = UnitMana("player")
                if CleveRoids.playerClass == "DRUID" and CleveRoids.NampowerAPI then
                    manaToCheck = CleveRoids.NampowerAPI.GetUnitPower("player", 0)
                end

                actions.active.oom = (manaToCheck < actions.active.spell.cost)
            end

            local start, duration = GetSpellCooldown(actions.active.spell.spellSlot, actions.active.spell.bookType)
            local onCooldown = (start > 0 and duration > 0)

            if actions.active.isReactive then
                -- For Overpower, Revenge, Riposte: ONLY use combat log tracking
                local spellName = actions.active.action
                local useCombatLogOnly = (spellName == CleveRoids.Localized.Spells["Overpower"] or spellName == CleveRoids.Localized.Spells["Revenge"] or spellName == CleveRoids.Localized.Spells["Riposte"]) -- 新增多语言支持 by 武藤纯子酱 2026.2.2

                if useCombatLogOnly then
                    -- Only trust HasReactiveProc for these spells
                    local hasProc = CleveRoids.HasReactiveProc and CleveRoids.HasReactiveProc(spellName)
                    if hasProc then
                        -- Proc is active, show as usable if in range and have enough rage/mana
                        if actions.active.inRange ~= 0 and not actions.active.oom then
                            actions.active.usable = 1
                        elseif pfUI and pfUI.bars and actions.active.oom then
                            actions.active.usable = 2  -- pfUI: out of mana/rage
                        else
                            actions.active.usable = nil
                        end
                    else
                        -- No proc = not usable
                        actions.active.usable = nil
                    end
                    CleveRoids.DebugChanged("usable_" .. spellName,
                        string.format("|cff00ff00[UPDATE USABLE]|r %s: hasProc=%s, usable=%s",
                            spellName, tostring(hasProc), tostring(actions.active.usable)))
                else
                    -- For other reactive spells, use the original fallback logic
                    -- Check combat log-based proc tracking first (stance-independent)
                    if CleveRoids.HasReactiveProc and CleveRoids.HasReactiveProc(actions.active.action) then
                        -- Proc is active, show as usable if in range and have enough rage/mana
                        if actions.active.inRange ~= 0 and not actions.active.oom then
                            actions.active.usable = 1
                        elseif pfUI and pfUI.bars and actions.active.oom then
                            actions.active.usable = 2  -- pfUI: out of mana/rage
                        else
                            actions.active.usable = nil
                        end
                    -- Use Nampower's IsSpellUsable if available (stance-aware fallback)
                    elseif IsSpellUsable then
                        -- pcall to handle spells not in spellbook (Nampower throws error)
                        local ok, usable, oom = pcall(IsSpellUsable, actions.active.action)
                        if ok and usable == 1 and oom ~= 1 then
                            if pfUI and pfUI.bars then
                                actions.active.usable = nil
                            else
                                actions.active.usable = 1
                            end
                        else
                            actions.active.usable = nil
                        end
                        actions.active.oom = false
                    elseif not CleveRoids.IsReactiveUsable(actions.active.action) then
                        actions.active.oom = false
                        actions.active.usable = nil
                    else
                        if pfUI and pfUI.bars then
                            actions.active.usable = nil
                        else
                            actions.active.usable = 1
                        end
                    end
                end
            elseif isUsableBySpell == 1 and actions.active.inRange ~= 0 then
                -- Use IsUsableSpell result if available (handles forms/stances correctly)
                actions.active.usable = 1
            elseif isUsableBySpell == 0 then
                -- IsSpellUsable returned 0 = wrong stance/form, not enough power type, etc.
                actions.active.usable = nil
            elseif actions.active.inRange ~= 0 and not actions.active.oom then
                -- Fallback to mana check ONLY if IsSpellUsable not available
                actions.active.usable = 1

            -- pfUI:actionbar.lua -- update usable [out-of-range = 1, oom = 2, not-usable = 3, default = 0]
            elseif pfUI and pfUI.bars and actions.active.oom then
                actions.active.usable = 2
            else
                actions.active.usable = nil
            end
			
            -- Check if this is a toggled buff ability (Prowl, Shadowmeld) and darken if buff is active
            -- This must come AFTER all other usability checks to have final say
            -- PERFORMANCE: Cache normalized spell name on the action object to avoid gsub per-frame
            local spellName = actions.active._normalizedName
            if not spellName then
                spellName = CleveRoids.StripRank(actions.active.action) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
                spellName = string.gsub(spellName, "_", " ")
                actions.active._normalizedName = spellName
            end

            -- PERFORMANCE: Use cached lookup instead of creating table per-call
            if CleveRoids.IsToggledBuffAbility(spellName) then
                if CleveRoids.ValidatePlayerBuff(spellName) then
                    -- Buff is active, darken the icon like "wrong stance" (grayed out, not red)
                    actions.active.usable = nil
                    actions.active.oom = false  -- Make sure we don't show red tint
                end
            end
        else
            actions.active.inRange = 1
            actions.active.usable = 1
        end
        if actions.active.usable ~= previousUsable or
           actions.active.oom ~= previousOom or
           actions.active.inRange ~= previousInRange then
            changed = true
            if CleveRoids.debug and actions.active.isReactive then
                DEFAULT_CHAT_FRAME:AddMessage(
                    string.format("|cffff00ff[STATE CHANGED]|r %s: usable %s->%s, will send ACTIONBAR_SLOT_CHANGED",
                        actions.active.action, tostring(previousUsable), tostring(actions.active.usable))
                )
            end
        end
    end
    return changed
end

-- PERFORMANCE: Static buffer references for hot path
local _actionsToSlotsBuffer = CleveRoids._actionsToSlotsBuffer
local _slotsBuffer = CleveRoids._slotsBuffer
local _actionsListBuffer = CleveRoids._actionsListBuffer

function CleveRoids.TestForAllActiveActions()
    -- PERFORMANCE: Reuse static buffers instead of creating new tables each call
    -- Group slots by their actions object to handle shared macro references
    local actionsToSlots = _actionsToSlotsBuffer
    local actionsList = _actionsListBuffer
    local actionsCount = 0

    -- PERFORMANCE: Use next() directly instead of pairs() to avoid iterator allocation
    local Actions = CleveRoids.Actions
    local slot, actions = next(Actions)
    while slot do
        if not actionsToSlots[actions] then
            -- Reuse or create slots array from pool
            local slots = _slotsBuffer[actions]
            if not slots then
                slots = {}
                _slotsBuffer[actions] = slots
            end
            slots[1] = slot
            slots._count = 1
            actionsToSlots[actions] = slots
            actionsCount = actionsCount + 1
            actionsList[actionsCount] = actions
        else
            local slots = actionsToSlots[actions]
            local count = slots._count + 1
            slots[count] = slot
            slots._count = count
        end
        slot, actions = next(Actions, slot)
    end

    -- Test each unique actions object once and send events to ALL slots that share it
    for i = 1, actionsCount do
        local actions = actionsList[i]
        local slots = actionsToSlots[actions]
        local stateChanged = CleveRoids.TestForActiveAction(actions)
        if stateChanged then
            -- Send event to ALL slots that use this macro
            local count = slots._count
            for j = 1, count do
                CleveRoids.SendEventForAction(slots[j], "ACTIONBAR_SLOT_CHANGED", slots[j])
            end
        end
        -- Clear for reuse (reset count and clear buffer reference)
        for j = 1, slots._count do
            slots[j] = nil
        end
        slots._count = 0
        actionsToSlots[actions] = nil
        actionsList[i] = nil  -- Clear actionsList entry for reuse
    end
end

function CleveRoids.ClearAction(slot)
    if not CleveRoids.Actions[slot] then return end
    CleveRoids.Actions[slot].active = nil
    CleveRoids.Actions[slot] = nil
end

function CleveRoids.GetAction(slot)
    if not slot or not CleveRoids.ready then return end

    local actions = CleveRoids.Actions[slot]
    if actions then return actions end

    local text = GetActionText(slot)

    if text then
        local macro = CleveRoids.GetMacro(text)
        if macro then
            actions = macro.actions

            CleveRoids.TestForActiveAction(actions)
            CleveRoids.Actions[slot] = actions
            CleveRoids.SendEventForAction(slot, "ACTIONBAR_SLOT_CHANGED", slot)
            return actions
        end
    end
end

function CleveRoids.GetActiveAction(slot)
    local action = CleveRoids.GetAction(slot)
    return action and action.active
end

-- PERFORMANCE: Static buffer for arg backup
local _originalArgsBuffer = CleveRoids._originalArgsBuffer

function CleveRoids.SendEventForAction(slot, event, ...)
    local old_this = this

    -- PERFORMANCE: Reuse static buffer instead of creating table each call
    -- 性能优化（P1-6）：直接读写全局 arg1..arg10，省去每次 20 次 _G["arg"..i] 字符串拼接 by 武藤纯子酱 2026.8.31
    local original_global_args = _originalArgsBuffer
    original_global_args[1] = arg1
    original_global_args[2] = arg2
    original_global_args[3] = arg3
    original_global_args[4] = arg4
    original_global_args[5] = arg5
    original_global_args[6] = arg6
    original_global_args[7] = arg7
    original_global_args[8] = arg8
    original_global_args[9] = arg9
    original_global_args[10] = arg10

    if type(arg) == "table" then

        local n_varargs_from_arg_table = arg.n or 0
        if n_varargs_from_arg_table >= 1 then arg1 = arg[1] else arg1 = nil end
        if n_varargs_from_arg_table >= 2 then arg2 = arg[2] else arg2 = nil end
        if n_varargs_from_arg_table >= 3 then arg3 = arg[3] else arg3 = nil end
        if n_varargs_from_arg_table >= 4 then arg4 = arg[4] else arg4 = nil end
        if n_varargs_from_arg_table >= 5 then arg5 = arg[5] else arg5 = nil end
        if n_varargs_from_arg_table >= 6 then arg6 = arg[6] else arg6 = nil end
        if n_varargs_from_arg_table >= 7 then arg7 = arg[7] else arg7 = nil end
        if n_varargs_from_arg_table >= 8 then arg8 = arg[8] else arg8 = nil end
        if n_varargs_from_arg_table >= 9 then arg9 = arg[9] else arg9 = nil end
        if n_varargs_from_arg_table >= 10 then arg10 = arg[10] else arg10 = nil end
    else
        arg1 = nil
        arg2 = nil
        arg3 = nil
        arg4 = nil
        arg5 = nil
        arg6 = nil
        arg7 = nil
        arg8 = nil
        arg9 = nil
        arg10 = nil
    end

    local button_to_call_event_on
    local page = floor((slot - 1) / NUM_ACTIONBAR_BUTTONS) + 1
    local pageSlot = slot - (page - 1) * NUM_ACTIONBAR_BUTTONS

    if slot >= 73 then
        button_to_call_event_on = _G["BonusActionButton" .. pageSlot]
    elseif slot >= 61 then
        button_to_call_event_on = _G["MultiBarBottomLeftButton" .. pageSlot]
    elseif slot >= 49 then
        button_to_call_event_on = _G["MultiBarBottomRightButton" .. pageSlot]
    elseif slot >= 37 then
        button_to_call_event_on = _G["MultiBarLeftButton" .. pageSlot]
    elseif slot >= 25 then
        button_to_call_event_on = _G["MultiBarRightButton" .. pageSlot]
    end

    if button_to_call_event_on then
        this = button_to_call_event_on
        ActionButton_OnEvent(event)
    end

    if page == CURRENT_ACTIONBAR_PAGE then
        local main_bar_button = _G["ActionButton" .. pageSlot]
        if main_bar_button and main_bar_button ~= button_to_call_event_on then
            this = main_bar_button
            ActionButton_OnEvent(event)
        elseif not button_to_call_event_on and main_bar_button then
             this = main_bar_button
             ActionButton_OnEvent(event)
        end
    end

    this = old_this

    -- 性能优化（P1-6）：恢复全局参数改为直接赋值（与上方备份方式一致） by 武藤纯子酱 2026.8.31
    arg1 = original_global_args[1]
    arg2 = original_global_args[2]
    arg3 = original_global_args[3]
    arg4 = original_global_args[4]
    arg5 = original_global_args[5]
    arg6 = original_global_args[6]
    arg7 = original_global_args[7]
    arg8 = original_global_args[8]
    arg9 = original_global_args[9]
    arg10 = original_global_args[10]

    -- FIX: Skip addon handler calls during initial indexing to prevent 120 rapid calls
    if CleveRoids._suppressActionHandlers then
        return
    end

    if type(arg) == "table" and arg.n then

        if arg.n == 0 then
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event) end
        elseif arg.n == 1 then
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event, arg[1]) end
        elseif arg.n == 2 then
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event, arg[1], arg[2]) end
        elseif arg.n == 3 then
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event, arg[1], arg[2], arg[3]) end
        elseif arg.n == 4 then
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event, arg[1], arg[2], arg[3], arg[4]) end
        elseif arg.n == 5 then
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event, arg[1], arg[2], arg[3], arg[4], arg[5]) end
        elseif arg.n == 6 then
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event, arg[1], arg[2], arg[3], arg[4], arg[5], arg[6]) end
        else
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do fn_h(slot, event, arg[1], arg[2], arg[3], arg[4], arg[5], arg[6], arg[7]) end
        end
    else

        for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do
            fn_h(slot, event)
        end
    end
end

-- Executes the given Macro's body
-- body: The Macro's body
-- Note on macro flags:
--   stopMacroFlag: Stops ALL remaining lines (propagates to parent macros)
--   skipMacroFlag: Stops only current macro (cleared on return, parent continues)
function CleveRoids.ExecuteMacroBody(body,inline)
    local lines = CleveRoids.splitString(body, "\n")
    if inline then lines = CleveRoids.splitString(body, "\\n"); end
	
    -- Save parent's stopMacroFlag state (in case we need to preserve it)
    local parentStopFlag = CleveRoids.stopMacroFlag

    -- Clear flags at start of this macro execution
    -- Note: We DON'T clear if parent already set stopMacroFlag (shouldn't execute at all)
    if not parentStopFlag then
        CleveRoids.stopMacroFlag = false
    end
    CleveRoids.skipMacroFlag = false  -- Always start fresh for skipmacro
    CleveRoids._castOutcomeHold = nil -- 结果确认门挂起信号：每轮宏执行开始时清零 by 武藤纯子酱 2026.8.31
    CleveRoids._castIssuedThisFrame = false -- 帧内施法护栏：每轮宏执行开始时复位 by 武藤纯子酱 2026.9.9

    if CleveRoids.macroRefDebug then
        CleveRoids.Print("|cff00ffff[MacroRef]|r ExecuteMacroBody called with " .. table.getn(lines) .. " lines")
    end

    -- 修复：pairs 对宏行遍历顺序未定义，改为数字遍历保证行序（优先级/stopmacro 依赖顺序） by 武藤纯子酱 2026.8.31
    for k = 1, table.getn(lines) do
        local v = lines[k]
        local trimmed = CleveRoids.Trim(v)
        local cmdHandled = false

        -- Skip #show / #showtooltip lines - they're only meaningful for action bar display,
        -- not for execution. This allows inner macros to have #showtooltip/#show without
        -- causing issues when called from other macros. by 武藤纯子酱 2026.9.3
        if string.find(trimmed, "^#show") then
            if CleveRoids.macroRefDebug then
                CleveRoids.Print("|cff888888[MacroRef]|r Skipping #showtooltip line in inner macro")
            end
            cmdHandled = true
        end

        -- 屏蔽/注释整行：/--cast、/--use、/--castsequence、/--follow
        -- 把命令写成 /--xxx 即临时禁用该行，便于调试宏 by 武藤纯子酱 2026.9.16
        if string.find(trimmed, "^/%-%-") then
            cmdHandled = true
        end

        -- IMPORTANT: Check for /nofirstaction BEFORE the stop flag check
        -- This allows /nofirstaction to clear the stopMacroFlag set by /firstaction
        local _, _, nofirstactionArgs = string.find(trimmed, "^/nofirstaction%s*(.*)")
        if nofirstactionArgs then
            -- Capture stopOnCastFlag BEFORE DoNoFirstAction clears it
            -- If it was true, stopMacroFlag was set by /firstaction, not /stopmacro
            local wasFirstActionActive = CleveRoids.stopOnCastFlag
            CleveRoids.DoNoFirstAction(nofirstactionArgs)
            -- Also clear stopMacroFlag if it was set by firstaction mechanism
            -- (but NOT if it was set by explicit /stopmacro)
            if wasFirstActionActive and CleveRoids.stopMacroFlag then
                -- stopOnCastFlag was true before we cleared it, and stopMacroFlag is set
                -- This means stopMacroFlag was set by the firstaction mechanism, clear it
                CleveRoids.stopMacroFlag = false
                if CleveRoids.macroRefDebug then
                    CleveRoids.Print("|cff00ff00[MacroRef]|r /nofirstaction cleared stopMacroFlag - resuming macro")
                end
            end
            if CleveRoids.macroRefDebug then
                CleveRoids.Print("|cff88ff88[MacroRef]|r Executing line " .. k .. ": " .. string.sub(v, 1, 60))
            end
            cmdHandled = true
        end

        -- Check both macro stop flags before each line (but skip if we just handled /nofirstaction)
        -- stopMacroFlag: stop this AND parent macros
        -- skipMacroFlag: stop only this macro (parent continues)
        if not cmdHandled and (CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag) then
            -- If stopOnCastFlag is true, the stop was caused by the firstaction mechanism
            -- Don't break the loop - just skip this line (allows /nofirstaction to be reached)
            if CleveRoids.stopOnCastFlag and CleveRoids.stopMacroFlag and not CleveRoids.skipMacroFlag then
                if CleveRoids.macroRefDebug then
                    CleveRoids.Print("|cffff8800[MacroRef]|r Skipping line " .. k .. " (firstaction mode)")
                end
                cmdHandled = true  -- Skip this line but continue loop to allow /nofirstaction
            else
                -- This is a /stopmacro or /skipmacro stop - actually break
                if CleveRoids.macroRefDebug then
                    local reason = CleveRoids.stopMacroFlag and "/stopmacro" or "/skipmacro"
                    CleveRoids.Print("|cffff8800[MacroRef]|r Stopped at line " .. k .. " due to " .. reason)
                end
                break
            end
        end
        if not cmdHandled then
            if CleveRoids.macroRefDebug then
                CleveRoids.Print("|cff88ff88[MacroRef]|r Executing line " .. k .. ": " .. string.sub(v, 1, 60))
            end

            -- IMPORTANT: Handle macro control commands directly to bypass Blizzard's built-in /stopmacro
            -- Blizzard intercepts bare /stopmacro before it reaches our SlashCmdList handler

            -- Check for /stopmacro (with or without conditionals)
            local _, _, stopmacroArgs = string.find(trimmed, "^/stopmacro%s*(.*)")
            if stopmacroArgs then
                CleveRoids.DoStopMacro(stopmacroArgs)
                cmdHandled = true
            end
            -- Check for /skipmacro (with or without conditionals)
            if not cmdHandled then
                local _, _, skipmacroArgs = string.find(trimmed, "^/skipmacro%s*(.*)")
                if skipmacroArgs then
                    CleveRoids.DoSkipMacro(skipmacroArgs)
                    cmdHandled = true
                end
            end
            -- Check for /firstaction (with or without conditionals)
            if not cmdHandled then
                local _, _, firstactionArgs = string.find(trimmed, "^/firstaction%s*(.*)")
                if firstactionArgs then
                    CleveRoids.DoFirstAction(firstactionArgs)
                    cmdHandled = true
                end
            end

            -- FIX: Handle /startattack directly - not a native vanilla WoW command
            -- Without SuperMacro, ChatEdit_SendText may not route addon slash commands properly
            if not cmdHandled then
                local _, _, startattackArgs = string.find(trimmed, "^/startattack%s*(.*)")
                if startattackArgs then
                    if SlashCmdList.STARTATTACK then
                        SlashCmdList.STARTATTACK(startattackArgs)
                    end
                    cmdHandled = true
                end
            end

            -- FIX: Handle /stopattack directly - not a native vanilla WoW command
            if not cmdHandled then
                local _, _, stopattackArgs = string.find(trimmed, "^/stopattack%s*(.*)")
                if stopattackArgs then
                    if SlashCmdList.STOPATTACK then
                        SlashCmdList.STOPATTACK(stopattackArgs)
                    end
                    cmdHandled = true
                end
            end
        end

        -- For all other commands, use ChatEdit_SendText
        if not cmdHandled then
            ChatFrameEditBox:SetText(v)
            ChatEdit_SendText(ChatFrameEditBox)
        end

        -- 结果确认门（挂起信号消费）：本行条件求值中触发了结果确认门（buff/debuff 类条件
        -- 判定"目标缺少效果"但同名施法结果未确认）→ 本轮宏挂起，不再执行后续行，
        -- 等待命中/抵抗结果事件（或 0.1s 超时）后的下一轮按键重新判定 by 武藤纯子酱 2026.8.31
        if CleveRoids._castOutcomeHold then
            if CleveRoids.debug then
                CleveRoids.Print("|cff00aaff[Outcome Gate]|r 宏执行挂起于第 " .. k .. " 行（等待施法结果确认）")
            end
            break
        end
    end

    -- Clear skipMacroFlag after this macro completes (don't propagate to parent)
    -- stopMacroFlag is intentionally LEFT SET so it propagates up
    CleveRoids.skipMacroFlag = false

    return true
end

-- Gets the body of the Macro with the given name
-- name: The name of the Macro
-- returns: The body of the macro
function CleveRoids.GetMacroBody(name)
    local macro = CleveRoids.GetMacro(name)
    return macro and macro.body
end


-- 优化宏递归深度判定 by 武藤纯子酱 2025.11.26
function CleveRoids.ExecuteMacroByName(name)
    -- 检查当前宏是否已在调用栈中（防止循环调用）
    for i = 1, table.getn(CleveRoids.MacroStack) do
        if CleveRoids.MacroStack[i] == name then
            CleveRoids.Print("警告: 宏 ["..name.."] 已被调用，不能递归调用自身")
            return false
        end
    end

    -- 检查调用栈深度
    if table.getn(CleveRoids.MacroStack) >= CleveRoids.MaxMacroDepth then
        CleveRoids.Print("警告: 宏调用深度超过限制 ("..CleveRoids.MaxMacroDepth..")")
        return false
    end

    -- 如果父级已设置 stopMacroFlag，阻止执行子宏（停止信号传播）
    if CleveRoids.stopMacroFlag then
        return false
    end

    -- 保存父级状态
    local parentStop = CleveRoids.stopMacroFlag
    local parentSkip = CleveRoids.skipMacroFlag

    -- 只隔离 skipMacroFlag（/skipmacro 不跨宏）；stopOnCastFlag（/firstaction 模式）不隔离——
    -- 跨宏共享、同一帧内有效：父宏的 /firstaction 对套娃子宏生效，子宏的 /nofirstaction 可清父宏 by 武藤纯子酱 2026.9.12
    CleveRoids.skipMacroFlag = false

    -- 将当前宏压入调用栈
    table.insert(CleveRoids.MacroStack, name)

    local success = false
    local body = CleveRoids.GetMacroBody(name)
    if body then
        -- 使用 pcall 捕获执行错误
        local status, result = pcall(function()
            return CleveRoids.ExecuteMacroBody(body)
        end)

        if status then
            success = result
        else
            if CleveRoids.debug then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Macro Error]|r " .. tostring(result))
            end
        end
    end

    -- 从调用栈中移除当前宏
    for i = table.getn(CleveRoids.MacroStack), 1, -1 do
        if CleveRoids.MacroStack[i] == name then
            table.remove(CleveRoids.MacroStack, i)
            break
        end
    end

    -- 只恢复 skipMacroFlag（/skipmacro 不跨宏）；stopOnCastFlag/stopMacroFlag 保留子宏执行后的值，
    -- 使 /firstaction 与 /stopmacro 的停止信号跨宏传播 by 武藤纯子酱 2026.9.12
    CleveRoids.skipMacroFlag = parentSkip

    -- stopMacroFlag 保留子宏执行后的值，以传播停止信号
    -- 如果子宏设置了 stopMacroFlag（如 /stopmacro），父级将停止；
    -- 否则为 false（父级原本为 false，已提前检查）
    -- 注意：不恢复 parentStop，因为若父级原本为 true 已提前返回

    return success
end

function CleveRoids.SetHelp(conditionals)
    if conditionals.harm then
        conditionals.help = false
    end
end

function CleveRoids.FixEmptyTarget(conditionals)
    if not conditionals.target then
        if UnitExists("target") then
            conditionals.target = "target"
	elseif GetCVar("autoSelfCast") == "1" and not (conditionals.target == "help") then -- 修复运算优先级：not (x == y)，原写法 (not x) == y 恒为 false by 武藤纯子酱 2026.8.31
            conditionals.target = "player"
        end
    end
    return false
end

-- Fixes the conditionals' target by targeting the target with the given name
-- conditionals: The conditionals containing the current target
-- name: The name of the player to target
-- hook: The target hook
-- returns: Whether or not we've changed the player's current target
function CleveRoids.FixEmptyTargetSetTarget(conditionals, name, hook)
    if not conditionals.target then
        hook(name)
        conditionals.target = "target"
        return true
    end
    return false
end

-- Returns the name of the focus target or nil
function CleveRoids.GetFocusName()
    local name

    -- 1. Add specific compatibility for pfUI.
    -- pfUI stores its focus unit information in a table.
    if pfUI and pfUI.uf and pfUI.uf.focus and pfUI.uf.focus.unitname then
        name = pfUI.uf.focus.unitname
    elseif ClassicFocus_CurrentFocus then
        name = ClassicFocus_CurrentFocus
    elseif (DFRLFocusCore or FocusCore) then -- 增加对FocusFrame插件的支持 by 武藤纯子酱 2025.11.28
        name = (DFRLFocusCore or FocusCore):GetName()
    elseif CURR_FOCUS_TARGET then
        name = CURR_FOCUS_TARGET
    end

    -- 修复：只接受"去空白后非空"的字符串名。1.12 引擎的 TargetByName 在参数为
    -- nil / "" / 布尔 / 数值 / 表等任何"非有效名字字符串"时都会抛 "Usage: TargetByName"，
    -- 而不同焦点插件把"未设置焦点"暴露成不同类型哨兵值（如 true、0、表），
    -- 原代码只挡 nil/"" 仍会漏网导致 /cast[@focus] 宏直接报错中断 by 武藤纯子酱 2026.9.9
    if type(name) == "string" then
        name = CleveRoids.Trim(name)
        if name ~= "" then
            return name
        end
    end

    return nil
end

-- Attempts to target the focus target.
-- returns: Whether or not it succeeded
function CleveRoids.TryTargetFocus()
    local name = CleveRoids.GetFocusName()

    -- 修复：GetFocusName 已保证只返回非空字符串；此处再加类型/空值双保险
    -- （防御未来新增焦点源返回非字符串），并 pcall 包裹引擎调用，
    -- 确保任何异常都不会以 "Usage: TargetByName" 红字中断宏 by 武藤纯子酱 2026.9.9
    if type(name) ~= "string" or name == "" then
        return false
    end

    local ok = pcall(TargetByName, name, true)
    if not ok then
        return false
    end

    -- 修复：单位存在但名字尚未从服务器同步时 UnitName 可返回 nil，
    -- string.lower(nil) 会抛错；且右侧 name 未 lower 会导致大小写不符时误判失败
    -- by 武藤纯子酱 2026.9.11
    if not UnitExists("target") or (string.lower(UnitName("target") or "") ~= string.lower(name)) then
        -- The target switch failed (out of range, LoS, etc.)
        return false
    end

    return true
end

-- Resolves pfUI's emulated focus to a real unit token (e.g., "party2", "raid5")
-- Returns the resolved token or nil if focus is not available
-- warn: if true, prints a chat message when no focus addon is installed
function CleveRoids.GetFocusUnitId(warn)
    if pfUI and pfUI.uf and pfUI.uf.focus and pfUI.uf.focus.label and pfUI.uf.focus.id
       and UnitExists(pfUI.uf.focus.label .. pfUI.uf.focus.id) then
        return pfUI.uf.focus.label .. pfUI.uf.focus.id
	elseif (DFRLFocusCore or FocusCore) then -- 新增对FocusFrame的支持 by 武藤纯子酱 2026.3.31
		-- 修复：FocusCore:GetName() 第二返回值为焦点 GUID，焦点未设置时为 nil——
		-- 原直接返回会以 nil 作为 conditionals.target 下传引发后续拼 token 异常，
		-- 且 warn 提示分支被短路；改为校验后返回 by 武藤纯子酱 2026.9.9
		local focusGuid = select(2, (DFRLFocusCore or FocusCore):GetName())
		if focusGuid and focusGuid ~= "" then
			return focusGuid
		end
    end
    if warn and not pfUI and not ClassicFocus_CurrentFocus and not CURR_FOCUS_TARGET then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff6600SuperCleveRoidMacros:|r [focus] target requires pfUI or a compatible focus addon.", 1, 0.4, 0)
    end
    return nil
end

function CleveRoids.GetMacroNameFromAction(text)
    if string.sub(text, 1, 1) == "{" and string.sub(text, -1) == "}" then
        local name
        if string.sub(text, 2, 2) == "\"" and string.sub(text, -2, -2) == "\"" then
            return string.sub(text, 3, -3)
        else
            return string.sub(text, 2, -2)
        end
    end
end

function CleveRoids.CreateActionInfo(action, conditionals)
    local _, _, text = string.find(action, "!?%??~?(.*)")
    local spell = CleveRoids.GetSpell(text)
    local petSpell  -- Add this line
    local item, macroName, macro, macroTooltip, actionType, texture

    -- NEW: Check if the action is a slot number
    local slotId = tonumber(text)
    if slotId and slotId >= 1 and slotId <= 19 then
        actionType = "item"
        local itemTexture = GetInventoryItemTexture("player", slotId)
        if itemTexture then
            texture = itemTexture
        else
            texture = CleveRoids.unknownTexture
        end
    else
        -- Original logic for named items and spells
        if not spell then
            petSpell = CleveRoids.GetPetSpell(text)  -- Add this line
        end
        if not spell and not petSpell then  -- Modify this line
            item = CleveRoids.GetItem(text)
        end
        if not item and not petSpell then  -- Modify this line
            macroName = CleveRoids.GetMacroNameFromAction(text)
            macro = CleveRoids.GetMacro(macroName)
            macroTooltip = (macro and macro.actions) and macro.actions.tooltip
        end

        if spell then
            actionType = "spell"
            texture = spell.texture or CleveRoids.unknownTexture
        elseif petSpell then  -- Add this block
            actionType = "petspell"
            texture = petSpell.texture or CleveRoids.unknownTexture
        elseif item then
            actionType = "item"
            texture = (item and item.texture) or CleveRoids.unknownTexture
        elseif macro then
            actionType = "macro"
            texture = (macro.actions and macro.actions.tooltip and macro.actions.tooltip.texture)
                        or (macro and macro.texture)
                        or CleveRoids.unknownTexture
        end
    end

    local info = {
        action = text,
        item = item,
        spell = spell,
        petSpell = petSpell,  -- Add this line
        macro = macroTooltip,
        type = actionType,
        texture = texture,
        conditionals = conditionals,
    }

    return info
end

function CleveRoids.SplitCommandAndArgs(text)
    local _, _, cmd, args = string.find(text, "(/%w+%s?)(.*)")
    if cmd and args then
        cmd = CleveRoids.Trim(cmd)
        text = CleveRoids.Trim(args)
    end
    return cmd, args
end

function CleveRoids.ParseSequence(text)
    if not text or text == "" then return end

    -- normalize commas
    local args = string.gsub(text, "(%s*,%s*)", ",")

    --[[ optional [conditionals] block
    local _, condEnd, condBlock = string.find(args, "(%[.*%])")]]

    -- accept reset= anywhere; no trailing space required; strip it out once
    local _, _, resetVal = string.find(args, "[Rr][Ee][Ss][Ee][Tt]=([%w/]+)")
    if resetVal then
      args = string.gsub(args, "%s*[Rr][Ee][Ss][Ee][Tt]=[%w/]+%s*", " ", 1)
    end

    -- optional [conditionals] block -- 将获取[]条件移动到后面，避免截取后定位错误 by 武藤纯子酱 2026.1.21
    local _, condEnd, condBlock = string.find(args, "(%[.*%])")

    -- actions are what's left after any ] (if present)
    local actionSeq = CleveRoids.Trim((condEnd and string.sub(args, condEnd + 1)) or args)
    args = (condBlock or "") .. actionSeq
    if actionSeq == "" then return end

    local sequence = {
        index      = 1,
        reset      = {},
        status     = 0,
        lastUpdate = 0,
        args       = args,
        cond       = condBlock,  -- Store conditional block for evaluation in DoCastSequence -- 删除 or "" by 武藤纯子酱 2026.2.6
        list       = {},
        perTargetState = {},  -- [guid] = {index = N, lastUpdate = T} for reset=target
    }

    -- fill reset rules: seconds or flags (target/combat/alt/ctrl/shift)
    if resetVal then
        for _, rule in pairs(CleveRoids.Split(resetVal, "/")) do
            rule = string.lower(CleveRoids.Trim(rule))
            local secs = tonumber(rule)
            if secs and secs > 0 then
                sequence.reset.secs = secs
            else
                sequence.reset[rule] = true
            end
        end
    end

    -- build steps
    for _, a in ipairs(CleveRoids.Split(actionSeq, ",")) do
        local sa = CleveRoids.CreateActionInfo(CleveRoids.GetParsedMsg(a))
        table.insert(sequence.list, sa)
    end

    CleveRoids.Sequences[text] = sequence
    return sequence
end

function CleveRoids.ParseMacro(name)
    if not name then return end

    local macroID = GetMacroIndexByName(name)

    local _, texture, body
    if macroID and macroID ~= 0 then
        _, texture, body = GetMacroInfo(macroID)
    end

    if (not body) and GetSuperMacroInfo then
        _, texture, body = GetSuperMacroInfo(name)
    end

    if not texture or not body then return end

    local macro = {
        id      = macroID,
        name    = name,
        texture = texture,
        body    = body,
        actions = {},
    }
    macro.actions.list = {}

    -- build a list of testable actions for the macro
    local hasShowTooltip = false
    local showTooltipHasArg = false

    for i, line in ipairs(CleveRoids.splitString(body, "\n")) do
        line = CleveRoids.Trim(line)
        local cmd, args = CleveRoids.SplitCommandAndArgs(line)

        -- check for #show / #showtooltip / #showtooltips on first line by 武藤纯子酱 2026.9.3
        if i == 1 then
            local _, _, st, _, tt = string.find(line, "(#showtooltips?)s?(%s?(.*))") -- 同时支持 #showtooltip/#showtooltips（既有写法不变）by 武藤纯子酱 2025.11.28
            if not st then
                -- 新增 #show 元命令（正式服语法）：仅指定动作条图标，1.12 无原生实现，
                -- 与 #showtooltip 共用图标解析（tooltip 文本仍由游戏按宏名显示）；
                -- Lua 模式无或运算，需两次匹配 by 武藤纯子酱 2026.9.3
                local _, _, s2, t2 = string.find(line, "^(#show)%s+(.*)$")
                if s2 then
                    st, tt = s2, t2
                elseif string.find(line, "^#show%s*$") then
                    st, tt = "#show", ""
                end
            end

            if st then
                hasShowTooltip = true
                tt = CleveRoids.Trim(tt)

                -- #showtooltip with explicit item/spell/macro specified
                if tt ~= "" then
                    showTooltipHasArg = true
                    for _, arg in ipairs(CleveRoids.splitStringIgnoringQuotes(tt)) do
                        -- Parse the arg to extract the spell name from any conditionals
                        local parsedArg = CleveRoids.GetParsedMsg(arg)
                        macro.actions.tooltip = CleveRoids.CreateActionInfo(parsedArg)
                        local action = CleveRoids.CreateActionInfo(parsedArg)
                        action.cmd = "/cast"
                        action.args = arg
                        action.isReactive = CleveRoids.reactiveSpells[action.action]
                        table.insert(macro.actions.list, action)
                    end
                end
                -- Continue parsing remaining lines for action list (needed for nested macro resolution)
            end
            -- No #showtooltip: still continue parsing to build action list for inner macro resolution
        else
            -- make sure we have a testable action
            if line ~= "" and args ~= "" and CleveRoids.dynamicCmds[cmd] then
                for _, arg in ipairs(CleveRoids.splitStringIgnoringQuotes(args)) do
                    local action = CleveRoids.CreateActionInfo(CleveRoids.GetParsedMsg(arg))

                    if cmd == "/castsequence" then
                        local sequence = CleveRoids.GetSequence(args)
                        if sequence then
                            action.sequence = sequence
                        end
                    end
                    action.cmd = cmd
                    action.args = arg
                    action.isReactive = CleveRoids.reactiveSpells[action.action]
                    table.insert(macro.actions.list, action)
                end
            end
        end
    end

    -- If #showtooltip was present but had no argument, use the first action as the tooltip
    if hasShowTooltip and not showTooltipHasArg and table.getn(macro.actions.list) > 0 then
        macro.actions.tooltip = macro.actions.list[1]
    end

    -- Store whether #showtooltip had an explicit argument (for icon fallback logic)
    macro.actions.explicitTooltip = showTooltipHasArg

    CleveRoids.Macros[name] = macro
    return macro
end

function CleveRoids.ParseMsg(msg)
    if not msg then return end
    local conditionals = {}

    -- reset side flag for this parse
    CleveRoids._ignoretooltip = 0

    -- strip optional leading '?' and remember how many we stripped
    local ignorecount
    msg, ignorecount = string.gsub(CleveRoids.Trim(msg), "^%?", "")
    conditionals.ignoretooltip = ignorecount
    CleveRoids._ignoretooltip  = ignorecount

    -- capture a single [...] conditional block if present
    local _, cbEnd, conditionBlock = string.find(msg, "%[(.*)%]")  -- 将"%[(.+)%]" 修改为 "%[(.*)%]" 支持[]空条件，该条件永远为true by 武藤纯子酱 2025.11.28
	
    -- 处理空条件块的情况 by 武藤纯子酱 2025.11.28
    if conditionBlock == "" then
        conditionBlock = nil
    end

    -- split off flags/action after the condition block (or from start if none)
    local _, _, noSpam, cancelAura, action = string.find(
        string.sub(msg, (cbEnd or 0) + 1),
        "^%s*(!?)(~?)([^!~]+.*)"
    )
    action = CleveRoids.Trim(action or "")

    -- Also check for ? at start of action (after conditional block)
    -- This handles "[cond] ?action" syntax where ? appears after conditionals
    if string.sub(action, 1, 1) == "?" then
        action = CleveRoids.Trim(string.sub(action, 2))
        conditionals.ignoretooltip = 1
        CleveRoids._ignoretooltip = 1
    end

    -- store the raw action for callers and strip trailing "(Rank X)" for comparisons
    conditionals.action = action
    action = CleveRoids.StripRank(action)

    -- IMPORTANT: if there's NO conditional block, return nil conditionals so
    -- DoWithConditionals will hit the {macroName} execution branch.
    if not conditionBlock then
        local hasFlag = (noSpam and noSpam ~= "") or (cancelAura and cancelAura ~= "")
        if hasFlag and action ~= "" then
            if noSpam ~= "" then
                local spamCond = CleveRoids.GetSpammableConditional(action)
                if spamCond then
                    conditionals[spamCond] = { action }
                    -- Also create _groups entry for consistency with Multi()
                    if not conditionals._groups then
                        conditionals._groups = {}
                    end
                    conditionals._groups[spamCond] = { { values = { action }, operator = "OR" } }
                end
            end
            if cancelAura ~= "" then
                conditionals.cancelaura = action
            end
            return conditionals.action, conditionals
        end
        return conditionals.action, nil
    end

    -- With a condition block present, build out the conditionals table

    -- ! prefix with explicit conditionals: store as a flag for execution-time anti-toggle,
    -- rather than injecting an implicit conditional that gets AND'd with user conditions.
    -- The anti-toggle check happens in DoWithConditionals before CastSpellByName.
    if noSpam and noSpam ~= "" then
        conditionals.noSpam = true
    end
    if cancelAura and cancelAura ~= "" then
        conditionals.cancelaura = action
    end

    -- Set the action's target to @unitid if found (e.g., @mouseover)
	-- 新增对target=unitid的支持 by 武藤纯子酱 2025.11.28
	local target
	if strfind(conditionBlock,"[tT][aA][rR][gG][eE][tT]=") then -- 实现大小写不敏感 by 武藤纯子酱 2025.11.28
		_, _, target = string.find(conditionBlock, "([tT][aA][rR][gG][eE][tT]=[^%s,]+)") -- 实现大小写不敏感 by 武藤纯子酱 2025.11.28
		if target then
			conditionBlock = CleveRoids.Trim(string.gsub(conditionBlock, target, ""))
			conditionals.target = string.sub(target, 8)
			conditionals.target = strlower(conditionals.target) -- 统一转换为小写 by 武藤纯子酱 2025.11.28
		end				
	else
		_, _, target = string.find(conditionBlock, "(@[^%s,]+)")
		if target then
			conditionBlock = CleveRoids.Trim(string.gsub(conditionBlock, target, ""))
			conditionals.target = string.sub(target, 2)
			conditionals.target = strlower(conditionals.target) -- 统一转换为小写 by 武藤纯子酱 2025.11.28
		end		
	end
	-- 以上为新增对target=unitid的支持 by 武藤纯子酱 2025.11.28

    if conditionBlock and conditionals.action then
        -- Split the conditional block by comma or space
        for _, conditionGroups in CleveRoids.splitStringIgnoringQuotes(conditionBlock, {",", " "}) do
            if conditionGroups ~= "" then
                -- Split conditional groups by colon (rejoin extra parts for multi-part args
                -- e.g., distance:30:facing>1 → condition="distance", args="30:facing>1")
                local conditionGroup = CleveRoids.splitStringIgnoringQuotes(conditionGroups, ":")
                local condition = conditionGroup[1]
                local args = conditionGroup[2]
                for _cgi = 3, table.getn(conditionGroup) do
                    args = (args or "") .. ":" .. conditionGroup[_cgi]
                end
				condition = string.lower(condition)	-- 新增：将条件关键字转换为小写，实现大小写不敏感 by 武藤纯子酱 2025.11.28
                -- [button:1]/[btn:1]/[nobutton:1]/[nobtn:1]（Classic 冒号写法）映射为内部 buttonN/btnN（无冒号）：
                -- 仅取首个数字（1-5，越界/无参回退 1=左键，与原版"[btn:1] 为默认"一致），映射后按布尔条件处理 by 武藤纯子酱 2026.9.23
                if condition == "button" or condition == "btn"
                   or condition == "nobutton" or condition == "nobtn" then
                    local num = tonumber(string.match(CleveRoids.Trim(args or ""), "^(%d+)"))
                    if not num or num < 1 or num > 5 then num = 1 end
                    condition = condition .. num
                    args = nil
                end
                -- No args → the action is the implicit argument
                if not args or args == "" then
                    if not conditionals[condition] then
                        -- PERFORMANCE: Use module-level constant instead of creating table per-call
                        if BOOLEAN_CONDITIONALS[condition] then
                            conditionals[condition] = true
                        else
                            conditionals[condition] = conditionals.action
                            -- Create first group for non-boolean conditionals
                            if not conditionals._groups then
                                conditionals._groups = {}
                            end
                            conditionals._groups[condition] = { { values = { conditionals.action }, n = 1, operator = "OR" }, n = 1 }
                        end
                    else
                        -- existing code for when conditionals[condition] already exists
                        if type(conditionals[condition]) ~= "table" then
                            conditionals[condition] = { conditionals[condition] }
                        end
                        table.insert(conditionals[condition], conditionals.action)
						
                        -- Multiple instances of same conditional = AND logic
                        if not conditionals._operators then
                            conditionals._operators = {}
                        end
                        conditionals._operators[condition] = "AND"
						
                        -- Add new group for this instance
                        if not conditionals._groups then
                            conditionals._groups = {}
                        end
                        if not conditionals._groups[condition] then
                            conditionals._groups[condition] = { n = 0 }
                        end
                        local grp = conditionals._groups[condition]
                        local newEntry = { values = { conditionals.action }, n = 1, operator = "OR" }
                        grp.n = grp.n + 1
                        grp[grp.n] = newEntry
                    end
                else
                    -- Has args. Ensure the key's value is a table and add new arguments.
                    -- Track if this conditional already existed (repeated via comma)
                    local conditionAlreadyExists = conditionals[condition] ~= nil
                    if not conditionals[condition] then
                        conditionals[condition] = {}
                    elseif type(conditionals[condition]) ~= "table" then
                        conditionals[condition] = { conditionals[condition] }
                    end

                    -- Detect which separator is used: / (OR) or & (AND)
                    -- Initialize metadata tables if needed
                    if not conditionals._operators then
                        conditionals._operators = {}
                    end
                    if not conditionals._groups then
                        conditionals._groups = {}
                    end

                    -- Check which separator is present in the CURRENT args
                    local hasSlash = string.find(args, "/")
                    local hasAmpersand = string.find(args, "&")
					
                    -- Detect if & is part of a multi-comparison pattern (e.g., >0&<10)
                    -- Pattern: operator+number followed by & (with optional whitespace) followed by operator
                    -- IMPORTANT: Only whitespace allowed around &, NOT letters (to distinguish from Rip>3&Rake>3)
                    local isMultiComparison = hasAmpersand and string.find(args, "[>~=<]+%d+%.?%d*%s*&%s*[>~=<]")
					
                    local separator = "/"
                    local operatorType = "OR"

                    if hasAmpersand and not hasSlash and not isMultiComparison then
                        separator = "&"
                        operatorType = "AND"
                    elseif hasAmpersand and hasSlash then
                        -- Both separators present - default to / (OR) and warn
                        -- Could add a warning here in the future
                        separator = "/"
                        operatorType = "OR"
                    end
					
                    -- Store the operator type for this conditional (for backwards compat)
                    -- Note: when groups exist, Multi/NegatedMulti will use per-group operators
                    conditionals._operators[condition] = operatorType

                    -- Create a new group for this conditional instance
                    -- Structure: { values = { ... }, operator = "OR" or "AND" }
                    if not conditionals._groups[condition] then
                        conditionals._groups[condition] = { n = 0 }
                    end
                    local currentGroup = { values = {}, n = 0, operator = operatorType }
                    local grp = conditionals._groups[condition]
                    grp.n = grp.n + 1
                    grp[grp.n] = currentGroup

                    -- Split args by the determined separator
                    -- 公式保护（严格语法：公式比较值必须用 "..." 包裹，如 end<"getchannel(奥术飞弹)/6"）：
                    -- 存在被引号包裹的公式段时，参数不按 "/" 拆分——引号内的 "/" 是除号而非 OR 分隔符，
                    -- 未加引号的公式不会被识别（/ 照常拆分），语义无歧义 by 武藤纯子酱 2026.9.1
                    local hasQuotedFormula = CleveRoids.QuotedFormulaPresent and CleveRoids.QuotedFormulaPresent(args)
                    local argIter, argState, argCtrl
                    if hasQuotedFormula then
                        local single = { args }
                        argIter, argState, argCtrl = ipairs(single)
                    else
                        argIter, argState, argCtrl = CleveRoids.splitString(args, separator)
                    end
                    for _, arg_item in argIter, argState, argCtrl do
                        local processed_arg = CleveRoids.Trim(arg_item)
                        -- 记录该参数是否带引号：公式量必须加引号才被识别（见下方 amount 逻辑）by 武藤纯子酱 2026.9.1
                        local hadQuotes = (string.find(arg_item, '"', 1, true) ~= nil)

                        processed_arg = string.gsub(processed_arg, '"', "")
                        processed_arg = string.gsub(processed_arg, "_", " ")
                        processed_arg = CleveRoids.Trim(processed_arg)

                        -- normalize "name#N" → "name=#N" and "#N" → "=#N"
                        local arg_for_find = processed_arg
                        arg_for_find = string.gsub(arg_for_find, "^#(%d+)$", "=#%1")
                        arg_for_find = string.gsub(arg_for_find, "([^>~=<]+)#(%d+)", "%1=#%2")

                        -- accept decimals too; capture name/op/amount
                        -- 公式支持：量部分扩展为 字母/数字/括号/四则运算符（如 getchannel(奥术飞弹)/6），
                        -- 并排除后续比较符与 & | 分隔符，保证 "a>50&<80" 多比较仍按原路径拆分
                        -- by 武藤纯子酱 2026.9.1
                        local _, _, name, operator, amount = string.find(arg_for_find, "([^>~=<]*)([>~=<]+)([#%d%.%a%(%)%*%/%+%-][^>~=<&|]*)")

                        if CleveRoids.debug then
                            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                "|cffff9900[Parse]|r cond=%s arg='%s' find='%s' name=%s op=%s amt=%s",
                                tostring(condition), tostring(processed_arg), tostring(arg_for_find),
                                tostring(name), tostring(operator), tostring(amount)
                            ))
                        end

                        if not operator or not amount then
                            -- No operator found, treat as simple string argument
                            table.insert(conditionals[condition], processed_arg)
                            currentGroup.n = currentGroup.n + 1
                            currentGroup.values[currentGroup.n] = processed_arg
                        else
                            local name_to_use = (name and name ~= "") and name or conditionals.action
                            local final_amount_str, num_replacements = string.gsub(amount, "#", "")
                            local should_check_stacks = (num_replacements == 1)

                            -- SPECIAL HANDLING FOR CONDITIONALS WITH MULTIPLE COMPARISONS
                            -- Detect if this conditional has multiple operators
                            -- Example: "ap>1800/<2200" or "Recently_Bandaged>0&<10" or "health>50&<80"
                            -- Works with ANY conditional that supports numeric operators
                            -- Pattern: only whitespace or separators allowed between comparisons, NOT letters
                            if string.find(processed_arg, "[>~=<]+%d+%.?%d*%s*[/&]%s*[>~=<]") then						
                                -- This arg has multiple comparisons, parse them all
                                local stat_name = name_to_use
                                local comparisons = {}

                                -- Extract all operator+number pairs
                                -- Pattern matches operator followed by optional decimal number
                                for op, num in string.gfind(processed_arg, "([>~=<]+)(#?%d*%.?%d+)") do
                                    local clean_num = string.gsub(num, "#", "")
                                    local check_stacks = (string.find(num, "#") ~= nil)
                                    table.insert(comparisons, {
                                        operator = op,
                                        amount = tonumber(clean_num),
                                        checkStacks = check_stacks
                                    })
                                end

                                if table.getn(comparisons) > 0 then
                                    local entry = {
                                        name = CleveRoids.Trim(stat_name),
                                        comparisons = comparisons  -- Store all comparisons
                                    }
                                    table.insert(conditionals[condition], entry)
                                    currentGroup.n = currentGroup.n + 1
                                    currentGroup.values[currentGroup.n] = entry
                                else
                                    -- Fallback to single comparison if parsing failed
                                    local entry = {
                                        name = CleveRoids.Trim(name_to_use),
                                        operator = operator,
                                        amount = tonumber(final_amount_str),
                                        checkStacks = should_check_stacks
                                    }
                                    table.insert(conditionals[condition], entry)
                                    currentGroup.n = currentGroup.n + 1
                                    currentGroup.values[currentGroup.n] = entry
                                end
                            else
                                -- Normal single-comparison conditional (existing behavior)
                                -- amount：数字优先；非数字时仅当"带引号包裹的施法时间公式"
                                -- （getcast(名)/getchannel(名)/getmh()…）原样保留字符串，由
                                -- Conditionals 的比较器包装层在比较时求值；未加引号的公式不识别
                                -- by 武藤纯子酱 2026.9.1
                                local numericAmount = tonumber(final_amount_str)
                                local entry = {
                                    name = CleveRoids.Trim(name_to_use),
                                    operator = operator,
                                    amount = numericAmount or (hadQuotes
                                        and CleveRoids.IsSpellTimeFormula
                                        and CleveRoids.IsSpellTimeFormula(final_amount_str)
                                        and final_amount_str or nil),
                                    checkStacks = should_check_stacks
                                }
                                table.insert(conditionals[condition], entry)
                                currentGroup.n = currentGroup.n + 1
                                currentGroup.values[currentGroup.n] = entry
                            end
                        end
                    end
                end
            end
        end
        return conditionals.action, conditionals
    end
end


-- Get previously parsed or parse, store and return
function CleveRoids.GetParsedMsg(msg)
    if not msg then return end

    -- 性能优化：缓存查询前移 —— 原实现每次都先做 1-3 次 find 检测多条件块
    -- 再查缓存；多条件块消息本就不会进入缓存（下方直接返回），单条件块消息命中时
    -- 省去全部 find。语义不变：多条件块消息在缓存未命中时仍走原检测路径 by 武藤纯子酱 2026.8.31
    -- PERFORMANCE: Check cache first before doing string operations
    local cached = CleveRoids.ParsedMsg[msg]
    if cached then
        -- Use cached ignoretooltip value (already computed during first parse)
        CleveRoids._ignoretooltip = cached.ignoretooltip or 0
        return cached.action, cached.conditionals
    end

    -- 新增：检查是否是多个条件块的情况 by 武藤纯子酱 2025.11.28
    local firstBracket = string.find(msg, "%[")
    if firstBracket then
        local secondBracket = string.find(msg, "%]", firstBracket + 1)
        if secondBracket and string.find(msg, "%[", secondBracket + 1) then
            -- 这是多个条件块的情况，直接返回原始消息让DoWithConditionals处理
            return msg, nil
        end
    end

    -- Only compute ignoretooltip for new messages (not cache hits)
    -- PERFORMANCE: Use string.sub for simple prefix check instead of gsub
    local trimmed = CleveRoids.Trim(msg)
    local ignorecount = (string.sub(trimmed, 1, 1) == "?") and 1 or 0
    CleveRoids._ignoretooltip = ignorecount

    local action, conditionals = CleveRoids.ParseMsg(msg)
    -- Use ParseMsg's final _ignoretooltip value for cache, not the pre-computed one.
    -- ParseMsg may detect ? after conditional blocks (e.g., "[cond] ?action")
    -- which the prefix check above would miss.
    local finalIgnore = CleveRoids._ignoretooltip
	if ( conditionals and conditionals.target and not CleveRoids.IsSpecialUnitTarget(conditionals.target) ) or not conditionals then -- 当conditionals.target为动态遍历标识（cursor/cursive/mostwounded/filter/inherit等）的时候，不缓存 by 武藤纯子酱 2026.2.6；判定统一走 IsSpecialUnitTarget
		CleveRoids.ParsedMsg[msg] = {
			action         = action,
			conditionals   = conditionals,
			ignoretooltip  = finalIgnore,
		}
		-- 性能优化：FIFO 上限 200 条。ParseMsg 是纯字符串解析（同输入同输出），
		-- 逐出后下次重新解析结果完全一致，零语义影响，仅控制内存 by 武藤纯子酱 2026.8.31
		if not CleveRoids._parsedMsgInOrder then
			CleveRoids._parsedMsgInOrder = {}
			CleveRoids._parsedMsgOrder = {}
		end
		if not CleveRoids._parsedMsgInOrder[msg] then
			local orderN = table.getn(CleveRoids._parsedMsgOrder)
			CleveRoids._parsedMsgOrder[orderN + 1] = msg
			CleveRoids._parsedMsgInOrder[msg] = true
			if orderN + 1 > 200 then
				local oldest = table.remove(CleveRoids._parsedMsgOrder, 1)
				CleveRoids._parsedMsgInOrder[oldest] = nil
				CleveRoids.ParsedMsg[oldest] = nil
			end
		end
	end
    return action, conditionals
end


function CleveRoids.GetMacro(name)
    return CleveRoids.Macros[name] or CleveRoids.ParseMacro(name)
end

function CleveRoids.GetSequence(args)
    return CleveRoids.Sequences[args] or CleveRoids.ParseSequence(args)
end

function CleveRoids.GetCurrentSequenceAction(sequence)
    return sequence.list[sequence.index]
end

function CleveRoids.ResetSequence(sequence)
    -- Save the GUID before clearing it
    local targetGuid = sequence.lastTargetGuid

    sequence.index = 1
    sequence.lastTargetGuid = nil  -- Clear stored GUID so next use captures fresh target

    -- Also reset per-target state for current target if tracking
    if sequence.reset and sequence.reset.target and targetGuid then
        if sequence.perTargetState then
            sequence.perTargetState[targetGuid] = nil
        end
    end
end

function CleveRoids.AdvanceSequence(sequence)
    if sequence.index < table.getn(sequence.list) then
        -- Not at the end yet, just advance normally
        local oldIndex = sequence.index
        sequence.index = sequence.index + 1

        if CleveRoids.debug then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
              "|cff00ff00[Sequence Advanced]|r %d -> %d (of %d)",
              oldIndex, sequence.index, table.getn(sequence.list)
            ))
        end

        -- Sync per-target state if tracking by target
        if sequence.reset and sequence.reset.target and sequence.lastTargetGuid then
            sequence.perTargetState = sequence.perTargetState or {}
            sequence.perTargetState[sequence.lastTargetGuid] = {
                index = sequence.index,
                lastUpdate = GetTime(),
            }
        end
    else
        -- Sequence completed all steps - always wrap back to step 1.
        -- reset=secs/target/combat only apply as mid-sequence idle resets
        -- (matching standard WoW castsequence behavior).
        CleveRoids.ResetSequence(sequence)
    end
end

function CleveRoids.TestAction(cmd, args)
    local msg, conditionals = CleveRoids.GetParsedMsg(args)
    CleveRoids._lastParsedArgsConditionals = conditionals -- 性能优化：供调用方复用解析结果，避免第二次 GetParsedMsg by 武藤纯子酱 2026.9.11
	
    if not msg then return nil end -- 添加空值检查，避免后续操作报错 by 武藤纯子酱 2025.11.28

    -- Nil-safe guards（#show 与 #showtooltip 同样不参与执行动作贡献）by 武藤纯子酱 2026.9.3
    local hasShowTooltip = (type(msg) == "string")
        and (string.find(msg, "#showtooltip") or string.find(msg, "#show"))
    local ignoreTooltip  = ((type(conditionals) == "table") and (conditionals.ignoretooltip == 1))
                           or (CleveRoids._ignoretooltip == 1)

    -- If the line is explicitly ignored for tooltip (via '?'),
    -- or it is a '#showtooltip' token, do not contribute icon/tooltip.
    if hasShowTooltip or ignoreTooltip then
        CleveRoids._ignoretooltip = 0 -- clear for next parse
        return
    end

    -- No [] block → return a testable token so the UI can pick a texture
    if not conditionals then
        if not msg or msg == "" then
            return
        else
            return CleveRoids.GetMacroNameFromAction(msg) or msg
        end
    end

    local origTarget = conditionals.target
    if cmd == "" or not CleveRoids.dynamicCmds[cmd] then
        return
    end

    if conditionals.target == "focus" then
        local focusUnitId = CleveRoids.GetFocusUnitId()
        if focusUnitId then
            conditionals.target = focusUnitId
        else
            if not CleveRoids.GetFocusName() then
                return
            end
            conditionals.target = "target"
        end
    elseif conditionals.target == "focustarget" then
        local focusUnitId = CleveRoids.GetFocusUnitId()
        if focusUnitId then
            conditionals.target = focusUnitId .. "target"
        else
            if not CleveRoids.GetFocusName() then
                return
            end
            conditionals.target = "targettarget"
        end
    end

    if conditionals.target == "mouseover" then
        if not CleveRoids.IsValidTarget("mouseover", conditionals.help) then
            return false
        end
    end

    if conditionals.target == "cursor" then -- 新增@cursor支持 by 武藤纯子酱 2025.11.28
        if not CleveRoids.IsValidTarget("mouseover", conditionals.help) then
            return false
        end
    elseif conditionals.target == "none" then
        -- @none：图标路径——不针对具体单位，置 nil 让后续条件按无目标求值 by 武藤纯子酱 2026.9.3
        conditionals.target = nil
    else
        -- 统一走特殊单位标识解析（cursive/mostwounded/filter/inherit 等）
        -- 性能优化（P0-2）：图标路径扫描结果缓存 0.1 秒，键为宏行参数串（按键路径不经此处） by 武藤纯子酱 2026.8.31
        local resolved = GetCachedSpecialUnit(args or "", conditionals.target, conditionals)
        -- 回归修复：本调用与执行路径（DoWithConditionals）不同——没有 IsSpecialUnitTarget 守卫，
        -- 普通宏（无 @目标）的 conditionals.target 为 nil 时 ResolveSpecialUnit(nil) 正常返回 nil 透传。
        -- 此前把 nil 一律判失败，导致所有"无 @目标但有条件"的宏在图标路径全部失败，
        -- 条件 #showtooltip 图标不再随条件切换。现恢复：false（硬失败）或
        -- "原目标确为特殊单位且解析为 nil（无候选，如 @cursive 无有效单位/@focus 未设置）"才判失败
        -- by 武藤纯子酱 2026.8.31
        if resolved == false then
            return false
        end
        if resolved == nil and conditionals.target and CleveRoids.IsSpecialUnitTarget(conditionals.target) then
            return false
        end
        conditionals.target = resolved
    end


    -- Resolve named raid marks (skull/cross/etc.) and mark1-mark8 to native mark# unit tokens
    if conditionals.target then
        local resolvedMark = CleveRoids.ResolveRaidMarkUnit(conditionals.target)
        if resolvedMark then conditionals.target = resolvedMark end
    end

    CleveRoids.FixEmptyTarget(conditionals)

    -- Flag for tooltip evaluation. CountEnemiesMatching skips expensive
    -- nameplate scan and known-enemy cache, using only target + unit tokens.
    CleveRoids._isTestingAction = true

    -- PERFORMANCE: Use next() directly instead of pairs() to avoid iterator allocation
    local k, v = next(conditionals)
    while k do
        if not CleveRoids.ignoreKeywords[k] then
            if not CleveRoids.Keywords[k] or not CleveRoids.Keywords[k](conditionals) then
                CleveRoids._isTestingAction = false
                conditionals.target = origTarget
                return
            end
        end
        k, v = next(conditionals, k)
    end

    CleveRoids._isTestingAction = false
    conditionals.target = origTarget
    return CleveRoids.GetMacroNameFromAction(msg) or msg
end

-- /firstaction 防卡死辅助：判断一次施法是否“明显不可能成功”（目标不存在 / 超出施法距离）。
-- 仅用于 /firstaction 场景：坏行（条件恒通过但施法恒失败）不应把整条宏卡死。
-- by 武藤纯子酱 2026.9.11
function CleveRoids.IsCastImpossible(spellName, target, conditionals)
    if not spellName or spellName == "" then return false end
    local unit = target
    if not unit or unit == "" then return false end -- 无目标法术（自我/区域）不在此判定
    if CleveRoids.IsSpecialUnitTarget and CleveRoids.IsSpecialUnitTarget(unit) then return false end
    if not UnitExists(unit) then return true end
    -- 目标已死亡/灵魂：仅对“敌对/伤害类”法术视为不可能（复活类法术可对死者施放，不能误判）
    -- by 武藤纯子酱 2026.9.11
    if conditionals and conditionals.harm and CleveRoids.IsUnitDeadOrGhost and CleveRoids.IsUnitDeadOrGhost(unit) then
        return true
    end
    local API = CleveRoids.NampowerAPI
    if API and API.IsSpellInRange then
        local ok, r = pcall(API.IsSpellInRange, CleveRoids.StripRank(spellName), unit)
        if ok and r == 0 then return true end
    end
    return false
end

-- ============================================================================
-- 引导打断（clipping）模式与判定 by 武藤纯子酱 2026.9.12
--   /cleveroid clip 1|2|3（默认 2）：
--   1 = 任何命令都不打断引导（不调用 SpellStopCasting）
--   2 = 仅“含引导计时条件”的行、且确认本次施法能成功，才打断引导
--   3 = 只要该行条件通过就打断引导（旧行为）
-- ============================================================================
CleveRoids.CHANNEL_TIMING_KEYS = { "channeltime", "selfchanneltime", "schtime", "getchannel" }

-- 该行是否算“引导计时行”：
--   1) 本行直接含 channeltime/selfchanneltime/schtime/getchannel；或
--   2) 本行引用的 tag（gettag/nogettag）由“含引导计时条件的 /settag”设置（标签传播）
function CleveRoids.LineHasChannelTiming(c)
    if type(c) ~= "table" then return false end
    for i = 1, table.getn(CleveRoids.CHANNEL_TIMING_KEYS) do
        if c[CleveRoids.CHANNEL_TIMING_KEYS[i]] ~= nil then return true end
    end
    local ct = CleveRoids._channelTimingTags
    if ct and next(ct) then
        local function refsTag(v)
            if v == nil then return false end
            if type(v) == "string" then
                if ct[v] then return true end
                for name in string.gmatch(v, "[%a%d_]+") do
                    if ct[name] then return true end
                end
                return false
            elseif type(v) == "table" then
                for _, val in pairs(v) do
                    if refsTag(val) then return true end
                end
            end
            return false
        end
        if refsTag(c.gettag) or refsTag(c.nogettag) then return true end
    end
    return false
end

-- 该法术当前是否真的能放出去（冷却 + 可用性/资源）；无法确认时保守返回 false
function CleveRoids.CanPerformCast(spell)
    if not spell or spell == "" then return false end
    local name = CleveRoids.StripRank(spell)
    if CleveRoids.GetSpellCooldown then
        local expires = CleveRoids.GetSpellCooldown(name, true) -- 返回到期 GetTime；0=就绪
        if expires and expires > GetTime() then return false end
    end
    if IsSpellUsable then
        local ok, usable, oom = pcall(IsSpellUsable, name)
        if not ok then return false end        -- 无法确认 → 不打断
        if usable ~= 1 or oom == 1 then return false end
    end
    return true
end

-- 当前引导中，本行是否允许调用 SpellStopCasting 打断引导
function CleveRoids.CanInterruptChannel(castMsg, conditionals)
    local mode = tonumber(CleveRoidMacros and CleveRoidMacros.clipMode) or 2
    if mode == 1 then return false end
    if mode == 3 then return true end
    -- mode 2：需该行含引导计时条件，且确认本次施法能成功
    if not CleveRoids.LineHasChannelTiming(conditionals) then return false end
    return CleveRoids.CanPerformCast(castMsg)
end

-- 统一的“玩家施法前引导打断”处理：/cast、/castsequence、/castrandom 共用。
-- 返回 false 表示本次施法应被跳过（保留当前引导）；true 表示可以继续施法。
-- 注：/castpet（宠物）与 /use（道具）不经过此处理——它们不会打断玩家的引导 by 武藤纯子酱 2026.9.12
function CleveRoids.ClipBeforeSpellCast(castMsg, conditionals)
    if CleveRoids.CurrentSpell.type ~= "channeled" then return true end
    if not (CleveRoids.CanInterruptChannel and CleveRoids.CanInterruptChannel(castMsg, conditionals)) then
        return true -- 该行不允许打断：不调用 SpellStopCasting（施法本身照旧）
    end
    if CleveRoids.IsCastImpossible and CleveRoids.IsCastImpossible(castMsg, conditionals and conditionals.target or nil, conditionals) then
        return false -- 明显不可能成功（目标缺失/死亡/超范围）→ 跳过、不打断
    end
    SpellStopCasting()
    return true
end

function CleveRoids.DoWithConditionals(msg, hook, fixEmptyTargetFunc, targetBeforeAction, action)
    -- Ensure TestAction flag is cleared for actual execution (safety net for error recovery)
    CleveRoids._isTestingAction = false

    -- Check macro stop flags (skip non-control commands when flag is set)
    -- This enables /stopmacro, /skipmacro, /firstaction, /nofirstaction to work without SuperMacro for vanilla macros
    if (CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag) and action ~= "STOPMACRO" and action ~= "SKIPMACRO" and action ~= "FIRSTACTION" and action ~= "NOFIRSTACTION" then
        return false
    end

	local tagUnits -- 惰性分配：仅 gettag 分支用到，避免每次宏执行都建表 by 武藤纯子酱 2026.9.11
    local msg, conditionals = CleveRoids.GetParsedMsg(msg)
	
    -- Debug: Log parsed msg and action type
    if CleveRoids.equipDebugLog and action and action ~= CastSpellByName then
        CleveRoids.Print("|cff888888[EquipLog] DoWithConditionals: parsed msg='" .. tostring(msg) .. "' action=" .. tostring(action) .. "|r")
    end

	local cursortarget -- 新增@cursor支持 by 武藤纯子酱 2025.11.28
	local selfCastOverride -- @none：本次施法临时禁用自动自我施放 by 武藤纯子酱 2026.9.3

    -- 新增：处理多个[]条件块的情况 by 武藤纯子酱 2025.11.28
    if not conditionals and type(msg) == "string" then
        -- 尝试解析多个条件块
        local conditionBlocks = {}
        local remainingMsg = msg

        -- 提取所有条件块
        while true do
            local _, blockEnd, conditionBlock = string.find(remainingMsg, "%[(.-)%]")
            if not conditionBlock then break end
            
            table.insert(conditionBlocks, conditionBlock)
            remainingMsg = string.sub(remainingMsg, blockEnd + 1)
        end
        
        -- 如果有多个条件块，尝试每个条件块直到有一个成功
        if table.getn(conditionBlocks) and table.getn(conditionBlocks) > 1 then
            local actionText = remainingMsg
            for _, block in ipairs(conditionBlocks) do
                local fullMsg = "["..block.."]"..actionText
                if CleveRoids.DoWithConditionals(fullMsg, hook, fixEmptyTargetFunc, targetBeforeAction, action) then
                    return true
                end
            end
            return false
        end
    end

    -- No conditionals. Just exit.
    if not conditionals then
        if not msg then -- if not even an empty string
            return false
        else
            if string.sub(msg, 1, 1) == "{" and string.sub(msg, -1) == "}" then
                if string.sub(msg, 2, 2) == "\"" and string.sub(msg, -2, -2) == "\"" then
                    return CleveRoids.ExecuteMacroBody(string.sub(msg, 3, -3), true)
                else
                    return CleveRoids.ExecuteMacroByName(string.sub(msg, 2, -2))
                end
            end

            -- Handle STOPMACRO/SKIPMACRO/FIRSTACTION/NOFIRSTACTION without conditionals (bare command)
            if action == "STOPMACRO" then
                CleveRoids.stopMacroFlag = true
                return true
            elseif action == "SKIPMACRO" then
                CleveRoids.skipMacroFlag = true
                return true
            elseif action == "FIRSTACTION" then
                CleveRoids.stopOnCastFlag = true
                return true
            elseif action == "NOFIRSTACTION" then
                -- Clear flags - same logic as DoNoFirstAction
                local wasFirstActionActive = CleveRoids.stopOnCastFlag
                CleveRoids.stopOnCastFlag = false
                if wasFirstActionActive and CleveRoids.stopMacroFlag then
                    CleveRoids.stopMacroFlag = false
                end
                return true
            end

            if hook then
                hook(msg)
            end
            return true
        end
    end

    local origTarget = conditionals.target

    -- Handle [message:文本] - resolve message target from addon message queue by 武藤纯子酱 2026.8.10
    if conditionals.message then
        local msgText = conditionals.message
        if msgText then
            local now = GetTime()
            local queue = CleveRoids.messageQueue
            local found = false
            local texts
            if type(msgText) == "table" then
                texts = msgText
            else
                texts = { msgText }
            end
            for _, text in ipairs(texts) do
                for i, entry in ipairs(queue) do
                    if now - entry.timestamp <= 1.5 and entry.text == text then
                        table.remove(queue, i)
                        conditionals.target = entry.guid
                        found = true
                        break
                    end
                end
                if found then break end
            end
            if not found then
                -- No matching message, fail this conditional line
                conditionals.target = origTarget
                return false
            end
            -- 修复：不再写回 conditionals.message = true —— message 已在 ignoreKeywords 中
            -- （Keywords 循环本就会跳过它），原写入会污染 GetParsedMsg 的缓存表，
            -- 导致 [target=party1,message:"x"] 类（普通单位目标被缓存）第二次按下永久失败
            -- by 武藤纯子酱 2026.8.31
        end
    end

    if not conditionals.target and not conditionals.multiscan and not conditionals.message and conditionals.gettag then -- 新增当没有通过@或target=或multiscan指定目标的时候，调用gettag会遍历TagUnits的目标 by 武藤纯子酱 2026.1.28
		-- 修复：裸写 [gettag]（无参数）时解析器把动作名存成字符串，统一包装成表，避免下方 pairs/table.getn 报错 by 武藤纯子酱 2026.8.31
		if type(conditionals.gettag) == "string" then
			conditionals.gettag = { conditionals.gettag }
		end
		if conditionals and conditionals._groups and conditionals._groups["gettag"] then
			local groups = conditionals._groups["gettag"]
			local groupunits = {}
			for num, group in ipairs(groups) do
				groupunits[num] = {}
				local groupOp = group.operator or "OR"

				if groupOp == "OR" then
					local seen = {}
					
					for k,v in pairs(conditionals.gettag) do
						if CleveRoids.TagUnits[v] then
							for k,v in pairs(CleveRoids.TagUnits[v]) do
								if v and v ~= "TAGMATCH" and not seen[v] then
									seen[v] = true
									table.insert(groupunits[num], v)
								end
							end
						end
					end
				else
					-- 多个标签的情况：找出所有标签中都存在的单位（交集）
					local validTags = {}
					
					-- 收集所有有效的标签对应的单位表
					for i = 1, table.getn(conditionals.gettag) do
						local tag = conditionals.gettag[i]
						if CleveRoids.TagUnits[tag] then
							local units = {}
							for _, unit in pairs(CleveRoids.TagUnits[tag]) do
								units[unit] = true
							end
							table.insert(validTags, units)
						end
					end

					-- 找出所有标签中都存在的单位
					local seen = {}

					-- 修复：引用的标签都没有跟踪单位时 validTags 为空表，
					-- pairs(validTags[1]) = pairs(nil) 抛错中断宏 by 武藤纯子酱 2026.9.9
					if table.getn(validTags) == 0 then
						conditionals.target = origTarget
						return false
					end

					-- 以第一个标签的单位为基准
					for unit, _ in pairs(validTags[1]) do
						local inAllTags = true

						-- 检查这个单位是否在所有标签中
						for j = 2, table.getn(validTags) do
							if not validTags[j][unit] and not validTags[j]["TAGMATCH"] then
								inAllTags = false
								break
							end
						end

						if inAllTags and not seen[unit] then
							seen[unit] = true
							table.insert(groupunits[num], unit)
						end
					end
				end
			end

			if table.getn(groupunits) >= 1 then
				-- 多个标签的情况：找出所有标签中都存在的单位（交集）
				local validTags = {}
	
				-- 收集所有有效的标签对应的单位表
				for i = 1, table.getn(groupunits) do
					if groupunits[i] then
						local units = {}
						for _, unit in pairs(groupunits[i]) do
							units[unit] = true
						end
						table.insert(validTags, units)
					end
				end
					
				-- 找出所有标签中都存在的单位
				local seen = {}
					
				-- 以第一个标签的单位为基准
				for unit, _ in pairs(validTags[1]) do
					local inAllTags = true
						
					-- 检查这个单位是否在所有标签中
					for j = 2, table.getn(validTags) do
						if not validTags[j][unit] and not validTags[j]["TAGMATCH"] then
							inAllTags = false
							break
						end
					end
						
					if inAllTags and not seen[unit] then
						seen[unit] = true
						tagUnits = tagUnits or {} -- 惰性分配 by 武藤纯子酱 2026.9.11
						table.insert(tagUnits, unit)
					end
				end
			end
		end

		if tagUnits and table.getn(tagUnits) > 0 then
			-- 遍历所有跟踪的单位
			for _, guid in pairs(tagUnits) do
				if guid ~= "TAGMATCH" and CleveRoids.IsGuidValid(guid, conditionals) then
					conditionals.target = guid
					break
				end
			end
		end

		if not conditionals.target then
			for k,v in pairs(conditionals.gettag) do
				if CleveRoids.TagUnits[v] then
					for k,v in pairs(CleveRoids.TagUnits[v]) do
						if v and v ~= "TAGMATCH" then return false end
					end
				end
			end
		end
	end

	if conditionals.nogettag then -- 新增调用nogettag会遍历TagUnits的目标 by 武藤纯子酱 2026.1.28
		-- 修复：裸写 [nogettag]（无参数）时解析器把动作名存成字符串，统一包装成表，避免下方 pairs/table.getn 报错 by 武藤纯子酱 2026.8.31
		if type(conditionals.nogettag) == "string" then
			conditionals.nogettag = { conditionals.nogettag }
		end
		if conditionals and conditionals._groups and conditionals._groups["nogettag"] then
			local groups = conditionals._groups["nogettag"]
			local groupunits = {}
			for num, group in ipairs(groups) do
				groupunits[num] = {}
				local groupOp = group.operator or "OR"

				if groupOp == "OR" then
					local seen = {}
					
					for k,v in pairs(conditionals.nogettag) do
						if CleveRoids.TagUnits[v] then
							for k,v in pairs(CleveRoids.TagUnits[v]) do
								if v and v ~= "TAGMATCH" and not seen[v] then
									seen[v] = true
									table.insert(groupunits[num], v)
								end
							end
						end
					end
				else
					-- 多个标签的情况：找出所有标签中都存在的单位（交集）
					local validTags = {}
					
					-- 收集所有有效的标签对应的单位表
					for i = 1, table.getn(conditionals.nogettag) do
						local tag = conditionals.nogettag[i]
						if CleveRoids.TagUnits[tag] then
							local units = {}
							for _, unit in pairs(CleveRoids.TagUnits[tag]) do
								units[unit] = true
							end
							table.insert(validTags, units)
						end
					end
					-- 修复：与 gettag 分支同源——引用的标签都没有跟踪单位时 validTags 为空表，
					-- pairs(validTags[1]) = pairs(nil) 抛错中断宏；置为含一个空表的表使交集遍历为空 by 武藤纯子酱 2026.9.12
					if table.getn(validTags) == 0 then
						validTags = { {} }
					end
					
					-- 找出所有标签中都存在的单位
					local seen = {}
					
					-- 以第一个标签的单位为基准
					for unit, _ in pairs(validTags[1]) do
						local inAllTags = true
						
						-- 检查这个单位是否在所有标签中
						for j = 2, table.getn(validTags) do
							if not validTags[j][unit] and not validTags[j]["TAGMATCH"] then
								inAllTags = false
								break
							end
						end
						
						if inAllTags and not seen[unit] then
							seen[unit] = true
							table.insert(groupunits[num], unit)
						end
					end
				end
			end

			if table.getn(groupunits) >= 1 then
				-- 多个标签的情况：找出所有标签中都存在的单位（交集）
				local validTags = {}
	
				-- 收集所有有效的标签对应的单位表
				for i = 1, table.getn(groupunits) do
					if groupunits[i] then
						local units = {}
						for _, unit in pairs(groupunits[i]) do
							units[unit] = true
						end
						table.insert(validTags, units)
					end
				end
					
				-- 找出所有标签中都存在的单位
				local seen = {}
					
				-- 以第一个标签的单位为基准
				for unit, _ in pairs(validTags[1]) do
					local inAllTags = true
						
					-- 检查这个单位是否在所有标签中
					for j = 2, table.getn(validTags) do
						if not validTags[j][unit] and not validTags[j]["TAGMATCH"] then
							inAllTags = false
							break
						end
					end
						
					if inAllTags and not seen[unit] then
						seen[unit] = true
						-- 删除：notagUnits 写入后从未被读取（死代码），不再分配 by 武藤纯子酱 2026.9.11
					end
				end
			end
		end
	end

    if conditionals.target == "mouseover" then
        if UnitExists("mouseover") then
            conditionals.target = "mouseover"
        elseif CleveRoids.mouseoverUnit and UnitExists(CleveRoids.mouseoverUnit) then
            conditionals.target = CleveRoids.mouseoverUnit
		elseif UnitExists("target") then -- 修复当mouseover不存在的时候的逻辑，如果mouseover不存在，则向当前目标施法，如果当前目标也不存在，则向自身施法 by 武藤纯子酱 2025.11.28
			conditionals.target = "target"
        else
            conditionals.target = "mouseover"
        end
    end

    local needRetarget = false
    if fixEmptyTargetFunc then
        needRetarget = fixEmptyTargetFunc(conditionals, msg, hook)
    end

    -- CleveRoids.SetHelp(conditionals)

    if conditionals.target == "focus" or conditionals.target == "focustarget" then
        local isFocusTarget = conditionals.target == "focustarget"
        local focusUnitId = CleveRoids.GetFocusUnitId(true)

        if focusUnitId then
            -- Use the resolved pfUI unit token directly (avoids changing the player's target)
            conditionals.target = focusUnitId .. (isFocusTarget and "target" or "")
            needRetarget = false
        else
            -- return false if pfUI is installed and no focus is set instead of "invalid target"
            if pfUI and pfUI.uf and (not pfUI.uf.focus or pfUI.uf.focus.label == nil or pfUI.uf.focus.label == "") then return false end
            -- Fall back to targeting focus by name
            if not CleveRoids.TryTargetFocus() then
                UIErrorsFrame:AddMessage(SPELL_FAILED_BAD_TARGETS, 1.0, 0.0, 0.0, 1.0)
                conditionals.target = origTarget
                return false
            end
            conditionals.target = isFocusTarget and "targettarget" or "target"
            needRetarget = true
        end
    end

    -- Resolve named raid marks (skull/cross/etc.) and mark1-mark8 to native mark# unit tokens
    if conditionals.target then
        local resolvedMark = CleveRoids.ResolveRaidMarkUnit(conditionals.target)
        if resolvedMark then conditionals.target = resolvedMark end
    end

    -- Handle [multiscan:priority] - scan enemies and find best target
    -- Must be processed BEFORE the Keywords loop since it sets conditionals.target
    -- Pass origTarget so @unit syntax makes that unit exempt from combat check
    if conditionals.multiscan then
        local scanResult = CleveRoids.ResolveMultiscanTarget(conditionals, origTarget)
        if not scanResult then
            -- No valid target found - fail this conditional line (try next)
            conditionals.target = origTarget
            return false
        end
        -- Set target to the found GUID for soft-casting via SuperWoW or Nampower v2.37+
        conditionals.target = scanResult
        -- Don't need to retarget since we're using GUID directly
        needRetarget = false
    end

    if conditionals.target == "cursor" then -- 新增@cursor支持 by 武藤纯子酱 2025.11.28
        conditionals.target = nil
		cursortarget = true
		needRetarget = false
    elseif conditionals.target == "none" then
        -- @none（正式服语法）：中断自动自我施放、强制出现瞄准光标 by 武藤纯子酱 2026.9.3
        -- ①目标置 nil：跳过选目标/记录 MacroTarget，条件（如 [help]）不再针对单位求值；
        -- ②needRetarget=false：不改当前目标；
        -- ③置 selfCastOverride 标志：施法瞬间临时关闭 autoSelfCast CVar（见下方 CastSpellByName 分支），
        --   1.12 引擎在无目标+自动自我施放关闭时会让目标型法术进入瞄准光标状态（SpellIsTargeting）
        conditionals.target = nil
        needRetarget = false
        selfCastOverride = true
    elseif CleveRoids.IsSpecialUnitTarget(conditionals.target) then
        -- 统一走特殊单位标识解析（cursive/mostwounded/filter/inherit 等） by 武藤纯子酱 2026.8.31
        -- 本函数中所有分支在解析失败（含 @inherit 无 MacroTarget）时都应中止本行 by 武藤纯子酱 2026.8.31
        local resolved = CleveRoids.ResolveSpecialUnit(conditionals.target, conditionals)
        if resolved == false or resolved == nil then
            return false
        end
        if conditionals.target == "inherit" then
            needRetarget = false
        end
        conditionals.target = resolved
    end


    -- 性能优化：循环外上提 Keywords/ignoreKeywords，避免每次条件求值重复索引 CleveRoids 全局
    -- by 武藤纯子酱 2026.9.11
    local Keywords = CleveRoids.Keywords
    local ignoreKeywords = CleveRoids.ignoreKeywords
    for k, v in pairs(conditionals) do
        if not ignoreKeywords[k] then
            local result = Keywords[k] and Keywords[k](conditionals)
            -- Debug logging for equipped conditional when equipDebugLog is enabled
            if CleveRoids.equipDebugLog and (k == "equipped" or k == "noequipped") then
                local valStr = type(v) == "table" and table.concat(v, ", ") or tostring(v)
                CleveRoids.Print("|cff888888[EquipLog] Conditional [" .. k .. ":" .. valStr .. "] = " ..
                    (result and "|cff00ff00PASS|r" or "|cffff0000FAIL|r") .. "|r")
            end
            -- Debug logging for macro reference debug
            if CleveRoids.macroRefDebug then
                local valStr = (v == true) and "" or (type(v) == "table" and table.concat(v, ", ") or tostring(v))
                CleveRoids.Print("|cff888888[MacroRef]|r [" .. k .. (valStr ~= "" and (":" .. valStr) or "") .. "] = " ..
                    (result and "|cff00ff00PASS|r" or "|cffff0000FAIL|r"))
            end
            if not result then
                if needRetarget then
                    TargetLastTarget()
                    needRetarget = false
                end
                conditionals.target = origTarget
                return false
            end
        end
    end

    -- 修复：~光环 的取消改到条件全部通过之后执行。原先在条件求值之前无条件取消，
    -- 会忽略 [cond]（如 [nocombat] ~潜行 在战斗中也会取消）by 武藤纯子酱 2026.9.11
    if conditionals.cancelaura then
        if CleveRoids.CancelAura(conditionals.cancelaura) then
            return true
        end
    end

	if CleveRoids.SetTags == true then -- 新增在settag命令中，将符合条件的目标GUID加入列表 by 武藤纯子酱 2026.1.28
		if not CleveRoids.TagUnits[conditionals.action] or type(CleveRoids.TagUnits[conditionals.action]) ~= "table" then 
			CleveRoids.TagUnits[conditionals.action] = {}
		end

		if origTarget == "cursive" then
			if not CleveRoids.RequireCursive("cursive") then
				return false
			end

			-- 遍历所有跟踪的单位
			for guid, _ in pairs(Cursive.core.guids) do
				if CleveRoids.IsGuidValid(guid, conditionals) then
					table.insert(CleveRoids.TagUnits[conditionals.action], guid)
				end
			end
		elseif origTarget == "filterparty" or origTarget == "mostwoundedparty" then
			-- 检查队伍成员
			if GetNumPartyMembers() > 0 then
				for i = 1, GetNumPartyMembers() do			
					-- 检查队员
					local unit = "party"..i	
					if UnitExists(unit) then
						if CleveRoids.IsGuidValid(unit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(unit))
						end
					end
						
					-- 检查宠物
					local petUnit = "partypet"..i
					if UnitExists(petUnit) then
						if CleveRoids.IsGuidValid(petUnit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(petUnit))
						end
					end			
				end
			end
				
			if CleveRoids.IsGuidValid("player", conditionals) then
				table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID("player"))
			end
					
			if UnitExists("pet") then
				if CleveRoids.IsGuidValid("pet", conditionals) then
					table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID("pet"))
				end
			end			
		elseif origTarget == "filterraid" or origTarget == "mostwoundedraid" then
			-- 检查团队成员
			if UnitInRaid("player") then
				for i = 1, GetNumRaidMembers() do			
					-- 检查队员
					local unit = "raid"..i			
					if UnitExists(unit) then
						if CleveRoids.IsGuidValid(unit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(unit))
						end
					end
						
					-- 检查宠物
					local petUnit = "raidpet"..i
					if UnitExists(petUnit) then
						if CleveRoids.IsGuidValid(petUnit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(petUnit))
						end
					end			
				end
			end
				
			if CleveRoids.IsGuidValid("player", conditionals) then
				table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID("player"))
			end
					
			if UnitExists("pet") then
				if CleveRoids.IsGuidValid("pet", conditionals) then
					table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID("pet"))
				end
			end				
		elseif origTarget == "filter" or origTarget == "mostwounded" then
			-- 检查团队成员
			if UnitInRaid("player") then
				for i = 1, GetNumRaidMembers() do			
					-- 检查队员
					local unit = "raid"..i			
					if UnitExists(unit) then
						if CleveRoids.IsGuidValid(unit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(unit))
						end
					end
						
					-- 检查宠物
					local petUnit = "raidpet"..i
					if UnitExists(petUnit) then
						if CleveRoids.IsGuidValid(petUnit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(petUnit))
						end
					end			
				end
			-- 没有团队则检查队伍
			elseif GetNumPartyMembers() > 0 then
				for i = 1, GetNumPartyMembers() do			
					-- 检查队员
					local unit = "party"..i			
					if UnitExists(unit) then
						if CleveRoids.IsGuidValid(unit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(unit))
						end
					end
						
					-- 检查宠物
					local petUnit = "partypet"..i
					if UnitExists(petUnit) then
						if CleveRoids.IsGuidValid(petUnit, conditionals) then
							table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(petUnit))
						end
					end			
				end
			end
				
			if CleveRoids.IsGuidValid("player", conditionals) then
				table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID("player"))
			end
					
			if UnitExists("pet") then
				if CleveRoids.IsGuidValid("pet", conditionals) then
					table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID("pet"))
				end
			end
		else
			table.insert(CleveRoids.TagUnits[conditionals.action], "TAGMATCH")
		end

		if conditionals.target and UnitExists(conditionals.target) then
			table.insert(CleveRoids.TagUnits[conditionals.action], CleveRoids.GetGUID(conditionals.target))
		end

		CleveRoids.SetTags = false
	end

	if CleveRoids.TrueTarget then conditionals.target = CleveRoids.TrueTarget end -- 新增CleveRoids.TrueTarget用于当判定条件用的目标和施法/使用道具目标不一致的时候，记录实际施法/使用道具目标 by 武藤纯子酱 2025.12.13
	if conditionals.target then -- 新增CleveRoids.MacroTarget用于记录上一个宏语句的目标 by 武藤纯子酱 2025.11.28
		local guid = CleveRoids.GetGUID(conditionals.target)
		CleveRoids.MacroTarget = guid
	end
    if conditionals.target ~= nil and targetBeforeAction and not (( action == CastSpellByName or action == CleveRoids.DoUse) and CleveRoids.hasCastSpellByNameUnitToken) then -- 新增/use /userandom 支持@条件使用 by 武藤纯子酱 2025.11.28
        if not UnitIsUnit("target", conditionals.target) then
            if SpellIsTargeting() then
                SpellStopCasting()
            end
            TargetUnit(conditionals.target)
            needRetarget = true
        else
             if needRetarget then needRetarget = false end
        end
    elseif needRetarget then
        TargetLastTarget()
        needRetarget = false
    end

    if action == "STOPMACRO" then
        -- Set flag to stop subsequent lines in current macro AND parent macros
        CleveRoids.stopMacroFlag = true
        return true
    elseif action == "SKIPMACRO" then
        -- Set flag to skip remaining lines in current submacro only
        CleveRoids.skipMacroFlag = true
        return true
    elseif action == "FIRSTACTION" then
        -- Set flag to stop on first successful cast/use
        CleveRoids.stopOnCastFlag = true
        return true
    elseif action == "NOFIRSTACTION" then
        -- Clear flags to re-enable multi-queue behavior
        -- Also clear stopMacroFlag if it was set by the firstaction mechanism
        local wasFirstActionActive = CleveRoids.stopOnCastFlag
        CleveRoids.stopOnCastFlag = false
        if wasFirstActionActive and CleveRoids.stopMacroFlag then
            CleveRoids.stopMacroFlag = false
        end
        return true
    end

	local NP_FastCursor = GetCVar("NP_QuickcastTargetingSpells") == "1" -- 新增：验证是否开启快速区域施法 by 武藤纯子酱 2026.1.9
	if cursortarget and not NP_FastCursor then -- 新增：处理@cursor逻辑 by 武藤纯子酱 2026.1.9
		SetCVar("NP_QuickcastTargetingSpells", "1")
		-- 队列感知：施法可能被 Nampower 排队，CVar 恢复延迟到 OnUpdate（队列弹出或超时后），见 _pendingCursorRestore by 武藤纯子酱 2026.8.31
		CleveRoids._pendingCursorRestore = { deadline = GetTime() + 8 }
	end

    local result = true
    if string.sub(msg, 1, 1) == "{" and string.sub(msg, -1) == "}" then
        if CleveRoids.macroRefDebug then
            CleveRoids.Print("|cff00ffff[MacroRef]|r Detected macro reference: " .. msg)
        end
        if string.sub(msg, 2, 2) == "\"" and string.sub(msg, -2,-2) == "\"" then
            result = CleveRoids.ExecuteMacroBody(string.sub(msg, 3, -3), true)
        else
            result = CleveRoids.ExecuteMacroByName(string.sub(msg, 2, -2))
        end
    elseif msg == "" or msg == nil then
        -- Empty action (conditionals passed but no spell to cast)
        -- For non-spell actions (pet commands, etc.), still execute the action
        if CleveRoids.equipDebugLog and action and action ~= CastSpellByName then
            CleveRoids.Print("|cffff8800[EquipLog] Empty msg branch - calling action() with no args|r")
        end
        if action and action ~= CastSpellByName then
            -- 修复：动作处理器（DoUse/CancelAura 等）期望字符串参数，传条件表会导致 gsub/find 报错；
            -- 与下方非空分支的 action(msg, conditionals) 调用约定保持一致 by 武藤纯子酱 2026.8.31
            action("", conditionals)
            result = true
        else
            result = false
        end
    else
        local castMsg = msg
        -- FLEXIBLY check for any rank text like "(Rank 9)" before adding the highest rank
        -- Use specific "(Rank" check instead of any parentheses, so spells like
        -- "Faerie Fire (Feral)" still get their rank appended automatically
        if action == CastSpellByName and not string.find(msg, CleveRoids.Localized.SpellRank) then  -- 修复多语言支持 by 武藤纯子酱 2025.12.29
            local sp = CleveRoids.GetSpell(msg)
            local rank = sp and (sp.rank or (sp.highest and sp.highest.rank))
            if rank and rank ~= "" then
                castMsg = msg .. "(" .. rank .. ")"
            end
        end
        if action == CastSpellByName then
            -- 方案#2 防卡死：/firstaction 下，若该行施法“明显不可能”（目标不存在/超出施法距离），
            -- 跳过本行、不计入 /firstaction，让宏继续执行后续行，避免坏行把整条宏卡死
            -- by 武藤纯子酱 2026.9.11
            if CleveRoids.stopOnCastFlag and CleveRoids.IsCastImpossible
               and CleveRoids.IsCastImpossible(castMsg, conditionals.target, conditionals) then
                conditionals.target = origTarget
                CleveRoids.TrueTarget = nil
                return false
            end
            -- ! prefix anti-toggle: prevent CastSpellByName from toggling off active spells.
            -- For Attack/AutoShot/Shoot, use the non-toggling AttackTarget() API.
            -- For self-buffs/shapeshifts, skip if already active on the player.
            if conditionals.noSpam then
                local spamType = CleveRoids.spamConditions[msg]
                if spamType == "checkchanneled" then
                    -- Attack/AutoShot/Shoot: use non-toggling API
                    if msg == CleveRoids.Localized.Attack then
                        AttackTarget()
                        if needRetarget then TargetLastTarget() end
                        conditionals.target = origTarget
                        return true
                    end
                    -- AutoShot/Shoot: skip cast if already active to prevent toggle-off
                    if not CleveRoids.CheckChanneled(msg) then
                        if needRetarget then TargetLastTarget() end
                        conditionals.target = origTarget
                        return false
                    end
                else
                    -- Self-buff/shapeshift: skip if already active on player
                    if CleveRoids.ValidatePlayerBuff(msg) then
                        if needRetarget then TargetLastTarget() end
                        conditionals.target = origTarget
                        return false
                    end
                end
            end
            -- Legacy path: !Attack without explicit conditionals (checkchanneled injected)
            if msg == CleveRoids.Localized.Attack and conditionals.checkchanneled then
                AttackTarget()
            elseif selfCastOverride then
                -- @none：施法瞬间临时关闭 autoSelfCast，1.12 引擎在无目标时让目标型法术
                -- 进入瞄准光标状态（SpellIsTargeting），不自动套用到自己/当前目标；
                -- 施法后立即恢复 CVar（同一帧内完成，其他宏行不受影响）by 武藤纯子酱 2026.9.3
                -- 帧内施法护栏：同 else 分支 by 武藤纯子酱 2026.9.9
                -- clipping：引导中再施放“条件已通过”的任何法术，都先打断当前引导再施放
                -- （含 [channeltime:>2] 读条技）；但“明显不可能成功”（目标缺失/死亡/超范围）时不打断，
                -- 避免白白丢失引导 by 武藤纯子酱 2026.9.11
                if CleveRoids.ClipBeforeSpellCast and not CleveRoids.ClipBeforeSpellCast(castMsg, conditionals) then
                    conditionals.target = origTarget
                    CleveRoids.TrueTarget = nil
                    return false
                end
                CleveRoids._castIssuedThisFrame = true
                local prevSelfCast = GetCVar("autoSelfCast")
                if prevSelfCast == "1" then SetCVar("autoSelfCast", "0") end
                CastSpellByName(castMsg)
                if prevSelfCast == "1" then SetCVar("autoSelfCast", "1") end
            else
                -- 帧内施法护栏：本行 /cast 已发起（立即施放或 Nampower 排队），
                -- 置位让同帧后续宏行的 [nochanneling]/[checkcasting] 等守卫能看到，
                -- 防止填充法术覆盖 CD 技的排队槽位 by 武藤纯子酱 2026.9.9
                -- clipping：引导中再施放“条件已通过”的任何法术，都先打断当前引导再施放
                -- （含 [channeltime:>2] 读条技）；但“明显不可能成功”（目标缺失/死亡/超范围）时不打断，
                -- 避免白白丢失引导 by 武藤纯子酱 2026.9.11
                if CleveRoids.ClipBeforeSpellCast and not CleveRoids.ClipBeforeSpellCast(castMsg, conditionals) then
                    conditionals.target = origTarget
                    CleveRoids.TrueTarget = nil
                    return false
                end
                CleveRoids._castIssuedThisFrame = true
                if CleveRoids.hasCastSpellByNameUnitToken and conditionals.target and (origTarget or conditionals.multiscan or conditionals.message) then -- 修复multiscan是自动筛选匹配的BUG，感谢kook的yikyo by 武藤纯子酱 2026.6.5
                    CastSpellByName(castMsg, conditionals.target)
                else
                    CastSpellByName(castMsg)
                end
            end
        else
            -- For other actions like UseContainerItem etc.
            if CleveRoids.equipDebugLog then
                CleveRoids.Print("|cff00ff00[EquipLog] Calling action('" .. tostring(msg) .. "')|r")
            end
            action(msg, conditionals) -- 改为 action(msg, conditionals) by 武藤纯子酱 2026.8.10
        end
    end

    -- [mouseuse] modifier: auto-click the AOE targeting circle at cursor position
    if conditionals.mouseuse then
        if SpellIsTargeting() then
            local wasAttacking = CleveRoids.CurrentSpell.autoAttack
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            -- CameraOrSelectOrMoveStart can start auto-attack as a side effect.
            -- Stop it immediately if it wasn't active before.
            if not wasAttacking then
                local slot = CleveRoids.GetProxyActionSlot(CleveRoids.Localized.Attack)
                if slot and CleveRoids.Hooks.IsCurrentAction(slot) then
                    AttackTarget()
                    CleveRoids.CurrentSpell.autoAttack = false
                end
            end
        else
            -- 队列感知：施法被 Nampower 排队时目标圈稍后才会出现，交给 OnUpdate 等圈出现后再点击（最多 3 秒） by 武藤纯子酱 2026.8.31
            CleveRoids._pendingMouseUse = { deadline = GetTime() + 3 }
        end
    end

	-- 原：此处立即恢复 NP_QuickcastTargetingSpells=0；队列感知后改由 OnUpdate 在队列弹出/超时后恢复（_pendingCursorRestore） by 武藤纯子酱 2026.8.31

	if conditionals.target and CleveRoids.hasUnitXP then
		local ok, unitxp = pcall(UnitXP, "version")
		if ok and unitxp and strfind(unitxp, "UnitXP_SP3_X") then
			if conditionals.target == "player" or UnitIsUnit(conditionals.target, "player") then
				if SpellIsTargeting() then
					pcall(UnitXP, "castAOE", "player")
				else
					-- 队列感知：目标圈可能稍后才出现（施法被排队），交给 OnUpdate 轮询（最多 3 秒） by 武藤纯子酱 2026.8.31
					CleveRoids._pendingCastAOE = { unit = conditionals.target, deadline = GetTime() + 3 }
				end
			elseif conditionals.target == "target" or UnitIsUnit(conditionals.target, "target") then
				if SpellIsTargeting() then
					pcall(UnitXP, "castAOE", "target")
				else
					-- 队列感知：目标圈可能稍后才出现（施法被排队），交给 OnUpdate 轮询（最多 3 秒） by 武藤纯子酱 2026.8.31
					CleveRoids._pendingCastAOE = { unit = conditionals.target, deadline = GetTime() + 3 }
				end
			end
		end
	end

    if needRetarget then
        TargetLastTarget()
    end

    -- [stopattack]: Deferred to OnUpdate (next frame) using CheapShot pattern.
    -- AttackTarget()+ClearTarget() on first frame, enforce clear for 0.2s,
    -- then retarget via stored GUID.
    if conditionals.stopattack then
        CleveRoids.DeferStopAttack()
    end

    conditionals.target = origTarget
	CleveRoids.TrueTarget = nil -- 当动作完成后，清除CleveRoids.TrueTarget by 武藤纯子酱 2025.12.13
    return result
end

function CleveRoids.DoCast(msg)
    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = parts[i]
        if CleveRoids.DoWithConditionals(v, CleveRoids.Hooks.CAST_SlashCmd, CleveRoids.FixEmptyTarget, false, CastSpellByName) then
            -- If /firstaction was used, stop macro evaluation after first successful cast
            if CleveRoids.stopOnCastFlag then
                CleveRoids.stopMacroFlag = true
            end
            return true
        end
    end
    return false
end

-- Resolve unit for /pfcast: mouseover → GetMouseFocus label+id → mouseoverUnit → target → player
-- Mirrors pfUI's own unit resolution order so /pfcast conditionals evaluate against the same unit
-- that pfUI would cast on.
local function ResolvePfCastUnit()
    if UnitExists("mouseover") then
        return "mouseover"
    end
    local frame = GetMouseFocus and GetMouseFocus()
    if frame and frame.label and frame.id then
        return frame.label .. frame.id
    elseif CleveRoids.mouseoverUnit and UnitExists(CleveRoids.mouseoverUnit) then
        return CleveRoids.mouseoverUnit
    elseif UnitExists("target") then
        return "target"
    elseif GetCVar and GetCVar("autoSelfCast") == "1" then
        return "player"
    end
    return nil
end

-- /pfcast with CleveRoids conditionals: evaluate conditionals then cast via pfUI's mouseover chain.
-- Called from the SlashCmdList.PFCAST hook (set up by Extensions/Mouseover/pfUI.lua after pfUI loads).
function CleveRoids.DoPfCast(msg)
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = parts[i]
        -- If conditionals are present but no explicit @unit, inject the pfUI-resolved unit so
        -- all conditionals ([help], [nodebuff:X], etc.) evaluate against the same unit pfUI
        -- would cast on, and the final CastSpellByName gets the correct unit token.
        if string.find(v, "%[") and not string.find(v, "@") then
            local unit = ResolvePfCastUnit()
            if unit then
                v = string.gsub(v, "%[", "[@" .. unit .. ",", 1)
            end
        end
        if CleveRoids.DoWithConditionals(v, CleveRoids.Hooks.PFCAST_SlashCmd, CleveRoids.FixEmptyTarget, false, CastSpellByName) then
            if CleveRoids.stopOnCastFlag then
                CleveRoids.stopMacroFlag = true
            end
            return true
        end
    end
    return false
end

-- PERFORMANCE: Module-level pet cast action to avoid closure allocation per call
local function _petCastAction(spellName)
    local petSpell = CleveRoids.GetPetSpell(spellName)
    if petSpell and petSpell.slot then
        CastPetAction(petSpell.slot)
        return true
    end
    return false
end

function CleveRoids.DoCastPet(msg)
    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = parts[i]
        if CleveRoids.DoWithConditionals(v, _petCastAction, CleveRoids.FixEmptyTarget, false, _petCastAction) then
            return true
        end
    end
    return false
end

function CleveRoids.DoTarget(msg)
    -- Check macro stop flags
    if CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag then
        return false
    end

    local action, conditionals = CleveRoids.GetParsedMsg(msg)

    if action ~= "" then -- 让/target 支持条件识别，如果有action则通过CleveRoids.DoWithConditionals匹配条件，满足条件则将action作为目标；如果没有action，则将conditionals.target作为条件识别目标，满足则切换conditionals.target为当前目标 by 武藤纯子酱 2025.12.10
		if type(conditionals) ~= "table" or not next(conditionals) then
			CleveRoids.Hooks.TARGET_SlashCmd(action)
			return true
		else
			local handled = false
			
			for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
				if CleveRoids.DoWithConditionals(v, CleveRoids.Hooks.TARGET_SlashCmd, CleveRoids.FixEmptyTarget, false, CleveRoids.Hooks.TARGET_SlashCmd) then
					handled = true
					break
				end
			end

			return handled			
		end
    end

    -- 修复：/target 无参数时 GetParsedMsg 返回 (action, nil)，conditionals 为 nil 会导致下方报错 by 武藤纯子酱 2026.8.31
    if type(conditionals) ~= "table" then
        return false
    end

    local function IsGuidValid(unitTok, conds)
        if not unitTok or not UnitExists(unitTok) or CleveRoids.IsUnitDeadOrGhost(unitTok) then
            return false
        end
        local orig = conds.target
        conds.target = unitTok
        local ok = true
        for k, _ in pairs(conds) do
            if not CleveRoids.ignoreKeywords[k] then
                local fn = CleveRoids.Keywords[k]
                if not fn or not fn(conds) then ok = false; break end
            end
        end
        conds.target = orig
        return ok
    end

    -- Save original target GUID for potential restoration (SuperWoW returns GUID as 2nd value)
    local originalTargetGuid = CleveRoids.GetGUID("target")

    -- Handle [multiscan:priority] - use ResolveMultiscanTarget for enemy scanning
    -- ResolveMultiscanTarget handles its own target save/restore internally
    if conditionals.multiscan then
        local scanResult = CleveRoids.ResolveMultiscanTarget(conditionals, conditionals.target)
        if scanResult then
            TargetUnit(scanResult)
            return true
        end
        -- No match found - restore original target if scanning changed it
        if originalTargetGuid and UnitExists(originalTargetGuid) then
            TargetUnit(originalTargetGuid)
        elseif not originalTargetGuid then
            ClearTarget()
        end
        return false
    end

    -- Track if an explicit target was specified via @unit syntax
    local explicitTarget = conditionals.target

    do
        local unitTok = conditionals.target

        if unitTok == "mouseover" then
            if UnitExists("mouseover") then
                unitTok = "mouseover"
            elseif CleveRoids.mouseoverUnit and UnitExists(CleveRoids.mouseoverUnit) then
                unitTok = CleveRoids.mouseoverUnit
            elseif pfUI and pfUI.uf and pfUI.uf.mouseover and pfUI.uf.mouseover.unit
               and UnitExists(pfUI.uf.mouseover.unit) then
                unitTok = pfUI.uf.mouseover.unit
            else
                unitTok = nil
            end
        end

        if unitTok == "focus" or unitTok == "focustarget" then
            local isFocusTarget = unitTok == "focustarget"
            local fTok = CleveRoids.GetFocusUnitId(true)
            if fTok then
                unitTok = fTok .. (isFocusTarget and "target" or "")
                if not UnitExists(unitTok) then unitTok = nil end
            else
                unitTok = nil
            end
        end

		if unitTok == "cursor" then -- 新增@cursor支持 by 武藤纯子酱 2025.12.10（/target 场景下解析为鼠标指向的单位） by 武藤纯子酱 2026.8.31
            if UnitExists("mouseover") then
                unitTok = "mouseover"
            elseif CleveRoids.mouseoverUnit and UnitExists(CleveRoids.mouseoverUnit) then
                unitTok = CleveRoids.mouseoverUnit
            elseif pfUI and pfUI.uf and pfUI.uf.mouseover and pfUI.uf.mouseover.unit
               and UnitExists(pfUI.uf.mouseover.unit) then
                unitTok = pfUI.uf.mouseover.unit
            else
                unitTok = nil
            end
		else
			-- 统一走特殊单位标识解析（cursive/mostwounded/filter/inherit 等） by 武藤纯子酱 2026.8.31
			local resolved = CleveRoids.ResolveSpecialUnit(unitTok, conditionals)
			if resolved == false then
				return false
			end
			unitTok = resolved
		end


        -- Resolve named raid marks (skull/cross/etc.) and mark1-mark8 to native mark# unit tokens
        local resolvedMark = CleveRoids.ResolveRaidMarkUnit(unitTok)
        if resolvedMark then unitTok = resolvedMark end

        if unitTok and UnitExists(unitTok) and IsGuidValid(unitTok, conditionals) then
            TargetUnit(unitTok)
            return true
        end
		
        -- If an explicit target was specified via @unit syntax but doesn't exist or isn't valid,
        -- return false instead of falling through to candidate search.
        -- This ensures "/target [@mouseover,harm,alive]" does nothing when mouse is over empty ground.
        if explicitTarget then
            return false
        end
    end

    if UnitExists("target") and IsGuidValid("target", conditionals) then
        return true
    end

    local candidates = {}
    local wantsHelp = conditionals.help
    local wantsHarm = conditionals.harm

    local function addCandidate(unitId)
        if not UnitExists(unitId) then return end

        if wantsHelp and not UnitCanAssist("player", unitId) then return end

        if wantsHarm and not UnitCanAttack("player", unitId) then return end

        table.insert(candidates, { unitId = unitId })
    end

    addCandidate("mouseover")

    addCandidate("target")

    if not wantsHarm then
        table.insert(candidates, { unitId = "player" })
    end

    addCandidate("pet")

    for i = 1, 4 do
        addCandidate("party"..i)
        addCandidate("partypet"..i)
        addCandidate("party"..i.."target")
    end

    for i = 1, 40 do
        addCandidate("raid"..i)
        addCandidate("raidpet"..i)
        addCandidate("raid"..i.."target")
    end

    addCandidate("targettarget")
    addCandidate("targettargettarget")

    addCandidate("pettarget")

    if pfUI and pfUI.uf and pfUI.uf.focus and pfUI.uf.focus.label and pfUI.uf.focus.id then
        local focusTok = pfUI.uf.focus.label .. pfUI.uf.focus.id
        addCandidate(focusTok)
        addCandidate(focusTok .. "target")
	elseif (DFRLFocusCore or FocusCore) then -- 新增对FocusFrame的支持 by 武藤纯子酱 2025.12.10
		local focusTok = select(2,(DFRLFocusCore or FocusCore):GetName())
		if focusTok then 
			addCandidate(focusTok)
			addCandidate(focusTok .. "target")			
		end
    end

    if CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.features.hasNameplateGUID then
        -- Nampower v2.28+：名牌框架 GetName(1) 返回所挂单位 GUID（替代 SuperWoW 名牌 GUID 读取） by 武藤纯子酱 2026.9.1
        local numChildren = WorldFrame:GetNumChildren()
        local children = { WorldFrame:GetChildren() }

        for i = 1, numChildren do
            local frame = children[i]
            if frame and frame:IsVisible() then
                local success, guid = pcall(frame.GetName, frame, 1)
                if success and guid and type(guid) == "string" and string.len(guid) > 0 then
                    if UnitExists(guid) then
                        addCandidate(guid)
                    end
                end
            end
        end
    end

    for _, c in ipairs(candidates) do
		if conditionals.target == "mouseover" or conditionals.target == "cursor" then return false end -- 新增当出现mouseover或cursor的时候，如果mouseover或cursor的目标不存在，则不主动匹配最近满足条件的目标 by 武藤纯子酱 2025.12.11
        if IsGuidValid(c.unitId, conditionals) then
            TargetUnit(c.unitId)
            return true
        end
    end
	
    -- UnitXP 3D enemy scanning: cycles through enemies in world space (no nameplate required)
    -- This is the most powerful scan - finds enemies by line of sight and distance
    -- Always enabled unless explicitly looking for friendlies only ([help] without [harm])
    -- UnitXP only finds enemies, so this is safe for any /target with conditionals
    local wantsFriendlyOnly = wantsHelp and not wantsHarm
    if not wantsFriendlyOnly and CleveRoids.hasUnitXP then
		if conditionals.target == "mouseover" or conditionals.target == "cursor" then return false end -- 新增当出现mouseover或cursor的时候，如果mouseover或cursor的目标不存在，则不主动匹配最近满足条件的目标 by 武藤纯子酱 2025.12.11
        -- Try nearestEnemy first - most common case and most efficient
        local found = CleveRoids.SafeUnitXP("target", "nearestEnemy")
        if found and UnitExists("target") and IsGuidValid("target", conditionals) then
            return true
        end

        -- Determine scan mode: use distance-priority for melee conditionals
        local wantsMelee = conditionals.meleerange or conditionals.nomeleerange
        local scanMode = wantsMelee and "nextEnemyConsideringDistance" or "nextEnemyInCycle"

        local seenGuids = {}
        local firstGuid = nil
        local maxIterations = 50  -- Safety limit

        for i = 1, maxIterations do
            found = CleveRoids.SafeUnitXP("target", scanMode)
            if not found then break end

            local currentGuid = CleveRoids.GetGUID("target")
            if not currentGuid then break end

            -- Check if we've cycled back to start
            if firstGuid == nil then
                firstGuid = currentGuid
            elseif currentGuid == firstGuid then
                break  -- Completed full cycle
            end

            -- Skip already-seen targets
            if not seenGuids[currentGuid] then
                seenGuids[currentGuid] = true

                -- Test this target against all conditionals
                if IsGuidValid("target", conditionals) then
                    return true  -- Found matching target
                end
            end
        end

        -- No match found via UnitXP scan - restore original target if we had one
        if originalTargetGuid and UnitExists(originalTargetGuid) then
            TargetUnit(originalTargetGuid)
        elseif not originalTargetGuid then
            ClearTarget()
        end
    end

    -- TargetNearestEnemy() fallback: cycles through enemies via tab-targeting
    -- Finds enemy players that UnitXP may miss (e.g. [class:Rogue harm])
    if not wantsFriendlyOnly then
        TargetNearestEnemy()
        if UnitExists("target") then
            local firstGuid2 = CleveRoids.GetGUID("target")
            if firstGuid2 then
                if IsGuidValid("target", conditionals) then
                    return true
                end

                for i = 1, 50 do
                    TargetNearestEnemy()
                    if not UnitExists("target") then break end

                    local guid = CleveRoids.GetGUID("target")
                    if not guid or guid == firstGuid2 then break end

                    if IsGuidValid("target", conditionals) then
                        return true
                    end
                end
            end
        end

        -- No match found - restore original target
        if originalTargetGuid and UnitExists(originalTargetGuid) then
            TargetUnit(originalTargetGuid)
        elseif not originalTargetGuid then
            ClearTarget()
        end
    end

    -- No matching target found after all scans - restore and fail
    if originalTargetGuid and UnitExists(originalTargetGuid) then
        TargetUnit(originalTargetGuid)
    elseif not originalTargetGuid then
        ClearTarget()
    end
    return false
end

-- Attempts to attack a unit by a set of conditionals
-- msg: The raw message intercepted from a /petattack command
function CleveRoids.DoPetAction(action, msg)
    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], action, CleveRoids.FixEmptyTarget, true, action) then
            return true
        end
    end
    return false
end

-- PERFORMANCE: Module-level action to avoid closure allocation per call
local function _startAttackAction()
    if not UnitExists("target") or CleveRoids.IsUnitDead("target") then TargetNearestEnemy() end
    -- Check both event-based flag AND action bar state for reliable detection
    local isAttacking = CleveRoids.CurrentSpell.autoAttack
    if not isAttacking then
        -- Fallback: check action bar state via IsCurrentAction
        local slot = CleveRoids.GetProxyActionSlot(CleveRoids.Localized.Attack)
        if slot and IsCurrentAction(slot) then
            CleveRoids.CurrentSpell.autoAttack = true
            isAttacking = true
        end
    end
    if not isAttacking and not CleveRoids.CurrentSpell.autoAttackLock and UnitExists("target") and UnitCanAttack("player", "target") then
        CleveRoids.CurrentSpell.autoAttackLock = true
        CleveRoids.autoAttackLockElapsed = GetTime()
        AttackTarget()
        -- FIX: Immediately set autoAttack flag so subsequent macro lines know attack started
        -- Don't wait for PLAYER_ENTER_COMBAT event which has a delay
        CleveRoids.CurrentSpell.autoAttack = true
        -- FIX: Queue icon update so action bars reflect the new state
        if CleveRoidMacros and CleveRoidMacros.realtime == 0 then
            CleveRoids.QueueActionUpdate()
        end
    end
end

-- Attempts to conditionally start an attack. Returns false if no conditionals are found.
function CleveRoids.DoConditionalStartAttack(msg)
    if not string.find(msg, "%[") then return false end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        -- We pass 'nil' for the hook, so DoWithConditionals does nothing if it fails to parse conditionals.
        if CleveRoids.DoWithConditionals(parts[i], nil, CleveRoids.FixEmptyTarget, false, _startAttackAction) then
            return true
        end
    end
    return false
end

-- PERFORMANCE: Module-level actions to avoid closure allocation per call
local function _stopAttackAction()
    CleveRoids.DeferStopAttack()
end

local function _stopCastingAction()
    SpellStopCasting()
end

-- Attempts to conditionally stop an attack. Returns false if no conditionals are found.
function CleveRoids.DoConditionalStopAttack(msg)
    if not string.find(msg, "%[") then return false end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], nil, CleveRoids.FixEmptyTarget, false, _stopAttackAction) then
            return true
        end
    end
    return false
end

-- Attempts to conditionally stop casting. Returns false if no conditionals are found.
function CleveRoids.DoConditionalStopCasting(msg)
    if not string.find(msg, "%[") then return false end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], nil, CleveRoids.FixEmptyTarget, false, _stopCastingAction) then
            return true
        end
    end
    return false
end

-- /stopspelltarget：取消当前正在瞄准（等待选目标）的法术 by 武藤纯子酱 2026.9.3
-- 1.12 原生 API SpellStopTargeting()（正式服同名宏命令的 1.12 对应实现）
local function _stopSpellTargetAction()
    SpellStopTargeting()
end

-- Attempts to conditionally stop spell targeting. Returns false if no conditionals are found.
function CleveRoids.DoConditionalStopSpellTarget(msg)
    if not string.find(msg, "%[") then return false end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], nil, CleveRoids.FixEmptyTarget, false, _stopSpellTargetAction) then
            return true
        end
    end
    return false
end

-- /petdismiss：解散野兽 by 武藤纯子酱 2026.9.3
-- 1.12 无 PetDismiss() API，经宠物技能"解散野兽"（CastPetAction 定位宠物动作条槽位，
-- 兜底 CastSpellByName 本地化名）实现
local function _petDismissAction()
    local petSpell = CleveRoids.GetPetSpell(CleveRoids.Localized.PetDismissSpell)
    if petSpell and petSpell.slot then
        CastPetAction(petSpell.slot)
        return
    end
    CastSpellByName(CleveRoids.Localized.PetDismissSpell)
end
CleveRoids._petDismissFallback = _petDismissAction -- Console.lua 无条件路径复用 by 武藤纯子酱 2026.9.3

-- Attempts to conditionally dismiss the pet. Returns false if no conditionals are found.
function CleveRoids.DoConditionalPetDismiss(msg)
    if not string.find(msg, "%[") then return false end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], nil, CleveRoids.FixEmptyTarget, false, _petDismissAction) then
            return true
        end
    end
    return false
end

local function _clearTargetAction()
    ClearTarget()
end

-- Attempts to conditionally clear target. Returns false if no conditionals are found.
function CleveRoids.DoConditionalClearTarget(msg)
    if not string.find(msg, "%[") then return false end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], nil, CleveRoids.FixEmptyTarget, false, _clearTargetAction) then
            return true
        end
    end
    return false
end

-- Attempts to use or equip an item by a set of conditionals
-- Also checks if a condition is a spell so that you can mix item and spell use
-- msg: The raw message intercepted from a /use or /equip command
function CleveRoids.DoUse(msg)
    -- 修复：nil 参数保护（无参 /use、/equip 时 msg 可能为 nil）by 武藤纯子酱 2026.9.11
    msg = msg or ""
    -- Check macro stop flags
    if CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag then
        return false
    end

    local handled = false
	local onself = string.find(msg, "@player") or string.find(msg, "target=player") -- 新增：检查是否存在@player条件 by 武藤纯子酱 2025.11.28
	local API = CleveRoids.NampowerAPI -- 调用NampowerAPI by 武藤纯子酱 2026.1.9
    local action = function(msg)
        -- Defensive: make sure we are not in "split stack" mode and nothing is on the cursor
        if type(CloseStackSplitFrame) == "function" then CloseStackSplitFrame() end
        --if CursorHasItem and CursorHasItem() then ClearCursor() end

        -- Try to interpret the message as a direct inventory slot ID first.
        local slotId = tonumber(msg)
        if slotId and slotId >= 1 and slotId <= 19 then -- Character slots are 1-19
            --ClearCursor() -- extra safety before using equipped items
			PickupInventoryItem(slotId) -- 支持盗贼正式服上毒宏写法 by 武藤纯子酱 2025.11.28
			if CursorHasItem() then
				EquipCursorItem(slotId)
			end	
			if API.HasFeature("UseItemIdOrName") then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
				local itemInfo
				local currentItemLink = GetInventoryItemLink("player", slotId)
				if currentItemLink then
					local _,_,itemId = string.find(currentItemLink,"item:(%d+)")
					-- 修复：string.find 捕获的是字符串，FindPlayerItemSlot 的数字串会按"物品名"查找，必须转成数字 by 武藤纯子酱 2026.8.31
					itemInfo = API.FindItemFast(tonumber(itemId) or itemId)
				end
				if itemInfo then
					if CleveRoids.MacroTarget then
						UseItemIdOrName(itemInfo.itemId, CleveRoids.MacroTarget)
					else
						UseItemIdOrName(itemInfo.itemId)
					end
				end
			else
				if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
					TargetUnit(CleveRoids.MacroTarget)
				end
				UseInventoryItem(slotId)
			end

            return
        end

        -- Try to interpret as item ID (numbers > 19)
        -- v2.18+: Use FindPlayerItemSlot directly for item IDs (no name resolution needed)
        if slotId and slotId > 19 then
            local API = CleveRoids.NampowerAPI
			
            -- v2.18+: Native lookup can find item directly by ID
            if API and API.features and API.features.hasFindPlayerItemSlot then
                local itemInfo = API.FindItemFast(slotId)
                if itemInfo then
                    --ClearCursor()
                    if itemInfo.inventoryID then
                        if CleveRoids.equipDebugLog then
                            CleveRoids.Print("|cff888888[UseLog] /use " .. slotId .. " via UseInventoryItem(" .. itemInfo.inventoryID .. ") [v2.18 ID lookup]|r")
                        end
						PickupInventoryItem(itemInfo.inventoryID) -- 支持盗贼正式服上毒宏写法 by 武藤纯子酱 2025.11.28
						if CursorHasItem() then
							EquipCursorItem(itemInfo.inventoryID)
						end						
						if API.HasFeature("UseItemIdOrName") then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
							if CleveRoids.MacroTarget then
								UseItemIdOrName(itemInfo.itemId, CleveRoids.MacroTarget)
							else
								UseItemIdOrName(itemInfo.itemId)
							end
						else
							if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
								TargetUnit(CleveRoids.MacroTarget)
							end
							UseInventoryItem(itemInfo.inventoryID)
						end

                        return
                    elseif itemInfo.bagID and itemInfo.slot then
                        if CleveRoids.equipDebugLog then
                            CleveRoids.Print("|cff888888[UseLog] /use " .. slotId .. " via UseContainerItem(" .. itemInfo.bagID .. "," .. itemInfo.slot .. ") [v2.18 ID lookup]|r")
                        end
						PickupContainerItem(itemInfo.bagID, itemInfo.slot) -- 支持猎人正式服喂宝宝宏写法 by 武藤纯子酱 2025.11.28
						if CursorHasItem() then
							PickupContainerItem(itemInfo.bagID, itemInfo.slot)
							if onself then -- 新增，当有@player时，对自己使用 by 武藤纯子酱 2025.11.28
								UseContainerItem(itemInfo.bagID, itemInfo.slot, 1)
							else
								if API.HasFeature("UseItemIdOrName") then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
									local inventoryType = GetItemStatsField(itemInfo.itemId, "inventoryType") -- 修复，当未装备该物品时，先装备物品 by 武藤纯子酱 2026.1.12
									
									if not inventoryType or inventoryType ~= 0 then -- 修复，当未装备该物品时，先装备物品 by 武藤纯子酱 2026.1.12
										UseContainerItem(itemInfo.bagID, itemInfo.slot)
									end

									if CleveRoids.MacroTarget then
										UseItemIdOrName(itemInfo.itemId, CleveRoids.MacroTarget)
									else
										UseItemIdOrName(itemInfo.itemId)
									end
								else
									if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
										TargetUnit(CleveRoids.MacroTarget)									
									end
									UseContainerItem(itemInfo.bagID, itemInfo.slot)
								end
							end
						end				

                        return
                    end
                end
                -- Item not found by ID - fail
                if CleveRoids.equipDebugLog then
                    CleveRoids.Print("|cffff8800[UseLog] Item ID " .. slotId .. " not found in inventory [v2.18]|r")
                end
                return
            end

            -- Fallback: Resolve item ID to name for legacy lookup
            local itemName = nil
            if API and API.GetItemName then
                itemName = API.GetItemName(slotId)
            end
            -- Fall back to GetItemInfo
            if not itemName and GetItemInfo then
                itemName = GetItemInfo(slotId)
            end
            if itemName then
                if CleveRoids.equipDebugLog then
                    CleveRoids.Print("|cff888888[UseLog] Resolved item ID " .. slotId .. " to '" .. itemName .. "'|r")
                end
                msg = itemName  -- Replace ID with name for subsequent lookups
            else
                if CleveRoids.equipDebugLog then
                    CleveRoids.Print("|cffff8800[UseLog] Could not resolve item ID " .. slotId .. " - item not in cache|r")
                end
                -- Item not in client cache - can't resolve without seeing it first
                return
            end
        end

        -- v2.18+: Use native fast lookup (much faster than Lua cache + scan)
        local API = CleveRoids.NampowerAPI
        if API and API.features and API.features.hasFindPlayerItemSlot then
            local itemInfo = API.FindItemFast(msg)
            if itemInfo then
                --ClearCursor()
                if itemInfo.inventoryID then
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " via UseInventoryItem(" .. itemInfo.inventoryID .. ") [v2.18 native]|r")
                    end
					PickupInventoryItem(itemInfo.inventoryID) -- 支持盗贼正式服上毒宏写法 by 武藤纯子酱 2025.11.28
					if CursorHasItem() then
						EquipCursorItem(itemInfo.inventoryID)
					end
					if API.HasFeature("UseItemIdOrName") then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
						if CleveRoids.MacroTarget then
							UseItemIdOrName(itemInfo.itemId, CleveRoids.MacroTarget)
						else
							UseItemIdOrName(itemInfo.itemId)
						end
					else
						if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
							TargetUnit(CleveRoids.MacroTarget)
						end
						UseInventoryItem(itemInfo.inventoryID)
					end

                    return
                elseif itemInfo.bagID and itemInfo.slot then
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " via UseContainerItem(" .. itemInfo.bagID .. "," .. itemInfo.slot .. ") [v2.18 native]|r")
                    end
					PickupContainerItem(itemInfo.bagID, itemInfo.slot) -- 支持猎人正式服喂宝宝宏写法 by 武藤纯子酱 2025.11.28
					if CursorHasItem() then
						PickupContainerItem(itemInfo.bagID, itemInfo.slot)
						if onself then -- 新增，当有@player时，对自己使用 by 武藤纯子酱 2025.11.28
							UseContainerItem(itemInfo.bagID, itemInfo.slot, 1)
						else
							if API.HasFeature("UseItemIdOrName") then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
								local inventoryType = GetItemStatsField(itemInfo.itemId, "inventoryType") -- 修复，当未装备该物品时，先装备物品 by 武藤纯子酱 2026.1.12
								
								if not inventoryType or inventoryType ~= 0 then -- 修复，当未装备该物品时，先装备物品 by 武藤纯子酱 2026.1.12
									UseContainerItem(itemInfo.bagID, itemInfo.slot)
								end
								
								if CleveRoids.MacroTarget then
									UseItemIdOrName(itemInfo.itemId, CleveRoids.MacroTarget)
								else
									UseItemIdOrName(itemInfo.itemId)
								end
							else
								if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
									TargetUnit(CleveRoids.MacroTarget)									
								end
								UseContainerItem(itemInfo.bagID, itemInfo.slot)
							end
						end
					end				

                    return
                end
            end
            -- v2.18 lookup didn't find item - fall through to legacy path
            -- (might be partial match or different case that native doesn't handle)
        end

        -- PERFORMANCE: Try cache lookup first (O(1) instead of O(n) scan)
        -- IMPORTANT: Validate cache hits to prevent stale data during combat
        -- (IndexItems() is skipped during combat, so cache may have old bag/slot locations)
        local location = CleveRoids.FindItemLocation(msg)
        if location then
            local cacheValid = false
            local qname = string_lower(msg)
			
            if location.type == "inventory" then
                -- Validate: check if this slot actually contains the item we want
                local link = GetInventoryItemLink("player", location.inventoryID)
                if link then
                    local _, _, nm = string_find(link, "|h%[(.-)%]|h")
                    if nm and string_lower(nm) == qname then
                        cacheValid = true
                    end
                end
            else
                -- Validate: check if this bag slot actually contains the item we want
                local link = GetContainerItemLink(location.bag, location.slot)
                if link then
                    local _, _, nm = string_find(link, "|h%[(.-)%]|h")
                    if nm and string_lower(nm) == qname then
                        cacheValid = true
                    end
                end
            end
			
            if cacheValid then
                --ClearCursor()
                if location.type == "inventory" then
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " via UseInventoryItem(" .. location.inventoryID .. ") [cached]|r")
                    end
					PickupInventoryItem(location.inventoryID) -- 支持盗贼正式服上毒宏写法 by 武藤纯子酱 2025.11.28
					if CursorHasItem() then
						EquipCursorItem(location.inventoryID)
					end

					if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
						TargetUnit(CleveRoids.MacroTarget)
					end
					UseInventoryItem(location.inventoryID)
                else
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " via UseContainerItem(" .. location.bag .. "," .. location.slot .. ") [cached]|r")
                    end					
					PickupContainerItem(location.bag, location.slot) -- 支持猎人正式服喂宝宝宏写法 by 武藤纯子酱 2025.11.28
					if CursorHasItem() then
						PickupContainerItem(location.bag, location.slot)
						if onself then -- 新增，当有@player时，对自己使用 by 武藤纯子酱 2025.11.28
							UseContainerItem(location.bag, location.slot, 1)
						else
							if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
								TargetUnit(CleveRoids.MacroTarget)									
							end
							UseContainerItem(location.bag, location.slot)
						end
					end				
                end
                return
            elseif CleveRoids.equipDebugLog then
                CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " - cache STALE, falling back to scan|r")
            end
        end

        -- Slow path fallback: full scan for substring matches or cache miss
        local qname = string_lower(msg)

        -- Search equipped inventory slots first (for trinkets, etc.)
        for slot = 0, 19 do -- 增加对已装备物品名称的支持 by 武藤纯子酱 2025.12.6
            local link = GetInventoryItemLink("player", slot)
            if link then
                local _, _, nm = string_find(link, "|h%[(.-)%]|h")
                if nm and string_lower(nm) == qname then
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " via UseInventoryItem(" .. slot .. ")|r")
                    end
					--ClearCursor()
					PickupInventoryItem(slot) -- 支持盗贼正式服上毒宏写法 by 武藤纯子酱 2025.11.28
					if CursorHasItem() then
						EquipCursorItem(slot)
					end
					
					if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
						TargetUnit(CleveRoids.MacroTarget)
					end
					UseInventoryItem(slot)
                    return
                end
            end
        end

        -- Then search bags
        for bag = 0, 4 do
            local numSlots = GetContainerNumSlots(bag) or 0
            for bagSlot = 1, numSlots do
                local link = GetContainerItemLink(bag, bagSlot)
                if link then
                    local _, _, nm = string_find(link, "|h%[(.-)%]|h")
                    if nm and string_lower(nm) == qname then
                        if CleveRoids.equipDebugLog then
                            CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " via UseContainerItem(" .. bag .. "," .. bagSlot .. ")|r")
                        end
                        --ClearCursor()
						PickupContainerItem(bag, bagSlot) -- 支持猎人正式服喂宝宝宏写法 by 武藤纯子酱 2025.11.28
						if CursorHasItem() then
							PickupContainerItem(bag, bagSlot)
							if onself then -- 新增，当有@player时，对自己使用 by 武藤纯子酱 2025.11.28
								UseContainerItem(bag, bagSlot, 1)
							else
								if CleveRoids.MacroTarget then -- 新增指向目标是用道具 by 武藤纯子酱 2026.1.8
									TargetUnit(CleveRoids.MacroTarget)									
								end
								UseContainerItem(bag, bagSlot)
							end
						end
                        return
                    end
                end
            end
        end

        if CleveRoids.equipDebugLog then
            CleveRoids.Print("|cff888888[UseLog] /use " .. msg .. " - not found in equipped slots or bags|r")
        end
    end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], action, CleveRoids.FixEmptyTarget, false, action) then
            -- If /firstaction was used, stop macro evaluation after first successful use
            if CleveRoids.stopOnCastFlag then
                CleveRoids.stopMacroFlag = true
            end
			CleveRoids.IndexItems()	-- 修复对魔法制造的单个物品使用后不刷新背包的BUG by 武藤纯子酱 2025.11.28
            return true
        end
    end
	CleveRoids.IndexItems()	-- 修复对魔法制造的单个物品使用后不刷新背包的BUG by 武藤纯子酱 2025.11.28
    return false
end

-- Find an item in bags by name (ignoring equipped items)
-- Used to prefer bag copies over swapping from paired equipped slots
-- (e.g., dual-wielding the same weapon with /equipmh + /equipoh)
local function FindItemInBagsByName(itemName)
    if not itemName then return nil, nil end
    local lowerName = string_lower(itemName)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, name = string_find(link, "|h%[(.-)%]|h")
                if name and string_lower(name) == lowerName then
                    return bag, slot
                end
            end
        end
    end
    return nil, nil
end

function CleveRoids.EquipBagItem(msg, slotOrOffhand)
    if CleveRoids.equipDebugLog then
        CleveRoids.Print("|cff00ffff[EquipLog] EquipBagItem called: '" .. tostring(msg) .. "' slot=" .. tostring(slotOrOffhand) .. "|r")
    end

    if CleveRoids.equipInProgress then
        if CleveRoids.equipDebugLog then
            CleveRoids.Print("|cffff0000[EquipLog] Equip already in progress, skipping|r")
        end
        return false
    end

    -- Accept slot number directly, or boolean for backward compatibility (false=16/MH, true=17/OH)
    local invslot
    if type(slotOrOffhand) == "number" then
        invslot = slotOrOffhand
    else
        invslot = slotOrOffhand and 17 or 16
    end
    local API = CleveRoids.NampowerAPI

    -- v2.18+: Use native fast lookup for item ID or name
    -- Guard against API being a function instead of table (addon conflict protection)
    if type(API) == "table" and type(API.features) == "table" and API.features.hasFindPlayerItemSlot then
        local searchTerm = msg
        local itemId = tonumber(msg)

        if CleveRoids.equipDebugLog then
            CleveRoids.Print("|cff888888[EquipLog] Searching for '" .. tostring(searchTerm) .. "' (slot " .. invslot .. ")|r")
        end

        -- Check if already equipped in target slot
        if API.IsItemInSlot(searchTerm, invslot) then
            if CleveRoids.equipDebugLog then
                CleveRoids.Print("|cff00ff00[EquipLog] '" .. tostring(searchTerm) .. "' already in slot " .. invslot .. "|r")
            end
            return true
        end

        -- Find the item (works with both ID and name)
        local itemInfo = API.FindItemFast(searchTerm)
        if CleveRoids.equipDebugLog then
            if itemInfo then
                CleveRoids.Print("|cff888888[EquipLog] FindItemFast found: invID=" .. tostring(itemInfo.inventoryID) .. " bag=" .. tostring(itemInfo.bagID) .. " slot=" .. tostring(itemInfo.slot) .. "|r")
            else
                CleveRoids.Print("|cffff8800[EquipLog] FindItemFast returned nil|r")
            end
        end
        if itemInfo then
            -- Already equipped in different slot - need to swap
            if itemInfo.inventoryID then
                if itemInfo.inventoryID == invslot then
                    return true  -- Already in correct slot
                end
                -- Before swapping from another equipped slot, check bags for another copy
                -- This handles dual-wielding the same weapon (e.g., /equipmh Scimitar + /equipoh Scimitar)
                local bagCopyBag, bagCopySlot = FindItemInBagsByName(itemInfo.name or searchTerm)
                if bagCopyBag then
                    ClearCursor()
                    PickupContainerItem(bagCopyBag, bagCopySlot)
                    if CursorHasItem and CursorHasItem() then
                        EquipCursorItem(invslot)
                        ClearCursor()
                        if CleveRoids.equipDebugLog then
                            CleveRoids.Print("|cff00ff00[EquipLog] Equipped bag copy of '" .. tostring(msg) .. "' from bag " .. bagCopyBag .. " slot " .. bagCopySlot .. " (preferred over swap)|r")
                        end
                        return true
                    end
                end
                -- No bag copy found - swap from equipped slot
                ClearCursor()
                PickupInventoryItem(itemInfo.inventoryID)
                if CursorHasItem and CursorHasItem() then
                    EquipCursorItem(invslot)
                    ClearCursor()
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff00ff00[EquipLog] Equipped '" .. tostring(msg) .. "' from bag " .. itemInfo.bagID .. " slot " .. itemInfo.slot .. "|r")
                    end
                    return true
                end
            elseif itemInfo.bagID and itemInfo.slot then
                -- In bag - equip to target slot
                ClearCursor()
                PickupContainerItem(itemInfo.bagID, itemInfo.slot)
                if CursorHasItem and CursorHasItem() then
                    EquipCursorItem(invslot)
                    ClearCursor()
                    return true
                end
            end
        end

        -- Item not found via v2.18 lookup - fall through to legacy path
        if CleveRoids.equipDebugLog then
            CleveRoids.Print("|cffff8800[EquipLog] Item '" .. tostring(msg) .. "' not found via v2.18 FindPlayerItemSlot, trying legacy fallback|r")
            -- Debug: Try direct FindPlayerItemSlot call
            if FindPlayerItemSlot then
                local bag, slot = FindPlayerItemSlot(msg)
                CleveRoids.Print("|cff888888[EquipLog] Direct FindPlayerItemSlot('" .. msg .. "') = bag:" .. tostring(bag) .. " slot:" .. tostring(slot) .. "|r")
            end
        end
    end

    -- Fallback for older Nampower versions
    -- Try to interpret as item ID (numbers > 19)
    local itemId = tonumber(msg)
    if itemId and itemId > 19 then
        local itemName = nil
        if API and API.GetItemName then
            itemName = API.GetItemName(itemId)
        end
        if not itemName and GetItemInfo then
            itemName = GetItemInfo(itemId)
        end
        if itemName then
            msg = itemName
        else
            if CleveRoids.equipDebugLog then
                CleveRoids.Print("|cffff8800[EquipLog] Can't resolve item ID " .. tostring(itemId) .. "|r")
            end
            return false  -- Can't resolve item ID
        end
    end

    -- PERFORMANCE: Fast check if already equipped (single function call)
    if CleveRoids.IsItemEquipped and CleveRoids.IsItemEquipped(msg, invslot) then
        return true
    end

    -- Note what's currently in the target slot so we can invalidate its cache
    local oldSlotLink = GetInventoryItemLink("player", invslot)
    local oldSlotName = nil
    if oldSlotLink then
        local _, _, name = string_find(oldSlotLink, "|h%[(.-)%]|h")
        oldSlotName = name
    end

    -- Helper to invalidate displaced item's cache
    local function InvalidateDisplacedItem()
        if oldSlotName and CleveRoids.Items then
            CleveRoids.Items[oldSlotName] = nil
            CleveRoids.Items[string_lower(oldSlotName)] = nil
        end
    end

    -- Check if item is already equipped in the paired slot (swap case)
    -- EquipItemByName doesn't handle swapping equipped items, so we must do it manually
    -- Paired slots: trinkets (13<->14), weapons (16<->17), rings (11<->12)
    -- BUT: check bags first for another copy (e.g., dual-wielding same weapon)
    local pairedSlots = {[13] = 14, [14] = 13, [16] = 17, [17] = 16, [11] = 12, [12] = 11}
    local checkSlot = pairedSlots[invslot]
    if checkSlot then
        local link = GetInventoryItemLink("player", checkSlot)
        if link then
            local _, _, slotItemName = string_find(link, "|h%[(.-)%]|h")
            if slotItemName and string_lower(slotItemName) == string_lower(msg) then
                -- Item found in paired slot - but prefer a bag copy if one exists
                local bagCopyBag, bagCopySlot = FindItemInBagsByName(msg)
                if bagCopyBag then
                    -- Bag copy available - equip from bag instead of swapping
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff00ffff[EquipLog] Found bag copy, equipping from bag " .. bagCopyBag .. " slot " .. bagCopySlot .. " instead of swapping from slot " .. checkSlot .. "|r")
                    end
                    ClearCursor()
                    PickupContainerItem(bagCopyBag, bagCopySlot)
                    if CursorHasItem and CursorHasItem() then
                        EquipCursorItem(invslot)
                        ClearCursor()
                        if CleveRoids.Items then
                            CleveRoids.Items[msg] = nil
                            CleveRoids.Items[string_lower(msg)] = nil
                        end
                        InvalidateDisplacedItem()
                        return true
                    end
                    ClearCursor()
                else
                    -- No bag copy - swap from paired slot
                    if CleveRoids.equipDebugLog then
                        CleveRoids.Print("|cff00ffff[EquipLog] Swapping from slot " .. checkSlot .. " to slot " .. invslot .. "|r")
                    end
                    ClearCursor()
                    PickupInventoryItem(checkSlot)
                    if CursorHasItem and CursorHasItem() then
                        EquipCursorItem(invslot)
                        ClearCursor()
                        if CleveRoids.Items then
                            CleveRoids.Items[msg] = nil
                            CleveRoids.Items[string_lower(msg)] = nil
                        end
                        InvalidateDisplacedItem()
                        return true
                    end
                    ClearCursor()
                end
            end
        end
    end

    -- PERFORMANCE: Try EquipItemByName for bag items (fast path)
    -- This is the fastest path - no item lookup, no cursor operations
    if EquipItemByName then
        local ok = pcall(EquipItemByName, msg, invslot)
        if ok then
            -- Verify the item actually landed in the target slot
            -- EquipItemByName may silently no-op for same-named items in paired slots
            -- (e.g., dual-wielding Scimitar: MH copy found first, "equipped" to same slot)
            local newLink = GetInventoryItemLink("player", invslot)
            if newLink then
                local _, _, newName = string_find(newLink, "|h%[(.-)%]|h")
                if newName and string_lower(newName) == string_lower(msg) then
                    if CleveRoids.Items then
                        CleveRoids.Items[msg] = nil
                        CleveRoids.Items[string_lower(msg)] = nil
                    end
                    InvalidateDisplacedItem()
                    return true
                end
            end
            -- Verification failed - EquipItemByName didn't place item in target slot
            if CleveRoids.equipDebugLog then
                CleveRoids.Print("|cffff8800[EquipLog] EquipItemByName('" .. msg .. "', " .. invslot .. ") succeeded but item not in target slot, trying fallback|r")
            end
        end
    end

    -- PERFORMANCE: Use fast lookup first, fall back to full scan
    -- Full scan is now optimized with GetNameFromLink() instead of GetItemInfo()
    local item = CleveRoids.GetItemFast and CleveRoids.GetItemFast(msg)
    if not item then
        -- Try quick targeted scan (stops when found)
        item = CleveRoids.FindItemQuick and CleveRoids.FindItemQuick(msg)
    end
    if not item then
        -- Full scan fallback (now optimized, safe during combat)
        item = CleveRoids.GetItem(msg)
    end

    if not item or not item.name then
        if CleveRoids.equipDebugLog then
            CleveRoids.Print("|cffff8800[EquipLog] Item '" .. tostring(msg) .. "' not found in bags or equipped|r")
        end
        return false
    end

    -- Already equipped check (by item ID from lookup)
    if item.inventoryID == invslot then
        return true
    end

    if not item.bagID and not item.inventoryID then
        return false
    end

    -- Try EquipItemByName with resolved name (in case msg was partial/different case)
    if item.name and EquipItemByName and item.name ~= msg then
        local ok = pcall(EquipItemByName, item.name, invslot)
        if ok then
            -- Verify the item actually landed in the target slot (same guard as above)
            local newLink = GetInventoryItemLink("player", invslot)
            if newLink then
                local _, _, newName = string_find(newLink, "|h%[(.-)%]|h")
                if newName and string_lower(newName) == string_lower(item.name) then
                    if CleveRoids.Items then
                        CleveRoids.Items[item.name] = nil
                        CleveRoids.Items[string_lower(item.name)] = nil
                    end
                    InvalidateDisplacedItem()
                    return true
                end
            end
            -- Verification failed - fall through to manual cursor-based equip
            if CleveRoids.equipDebugLog then
                CleveRoids.Print("|cffff8800[EquipLog] EquipItemByName('" .. item.name .. "', " .. invslot .. ") succeeded but item not in target slot, trying manual fallback|r")
            end
        end
    end

    -- Fallback: Manual pickup and equip
    CleveRoids.equipInProgress = true

    -- PERFORMANCE: Single cursor check at start
    if CursorHasItem and CursorHasItem() then
        ClearCursor()
    end

    local pickupSuccess = false
    if item.bagID and item.slot then
        PickupContainerItem(item.bagID, item.slot)
        pickupSuccess = CursorHasItem and CursorHasItem()
    elseif item.inventoryID then
        PickupInventoryItem(item.inventoryID)
        pickupSuccess = CursorHasItem and CursorHasItem()
    end

    if not pickupSuccess then
        ClearCursor()
        CleveRoids.equipInProgress = false
        return false
    end

    EquipCursorItem(invslot)
    ClearCursor()

    if CleveRoids.Items and item.name then
        CleveRoids.Items[item.name] = nil
        CleveRoids.Items[string_lower(item.name)] = nil
    end
    InvalidateDisplacedItem()
    CleveRoids.equipInProgress = false
    return true
end

-- PERFORMANCE: Module-level actions to avoid closure allocation per call
local function _equipMainhandAction(msg)
    return CleveRoids.EquipBagItem(msg, false)
end

local function _equipOffhandAction(msg)
    return CleveRoids.EquipBagItem(msg, true)
end

local function _equipTrinket1Action(msg)
    return CleveRoids.EquipBagItem(msg, 13)
end

local function _equipTrinket2Action(msg)
    return CleveRoids.EquipBagItem(msg, 14)
end

local function _equipRing1Action(msg)
    return CleveRoids.EquipBagItem(msg, 11)
end

local function _equipRing2Action(msg)
    return CleveRoids.EquipBagItem(msg, 12)
end

local function _unshiftAction()
    local currentShapeshiftIndex = CleveRoids.GetCurrentShapeshiftIndex()
    if currentShapeshiftIndex ~= 0 then
		if CleveRoids.playerClass == "PRIEST" or CleveRoids.playerClass == "ROGUE" then
			CancelPlayerBuff(currentShapeshiftIndex)	--修复 by 武藤纯子酱 2025.11.27	
		else
			CastShapeshiftForm(currentShapeshiftIndex)
		end
    end
end

function CleveRoids.DoEquipMainhand(msg)
    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = string.gsub(parts[i], "^%?", "")
        if CleveRoids.DoWithConditionals(v, _equipMainhandAction, CleveRoids.FixEmptyTarget, false, _equipMainhandAction) then
            return true
        end
    end
    return false
end

function CleveRoids.DoEquipOffhand(msg)
    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = string.gsub(parts[i], "^%?", "")
        if CleveRoids.DoWithConditionals(v, _equipOffhandAction, CleveRoids.FixEmptyTarget, false, _equipOffhandAction) then
            return true
        end
    end
    return false
end

function CleveRoids.DoEquipTrinket1(msg)
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = string.gsub(parts[i], "^%?", "")
        if CleveRoids.DoWithConditionals(v, _equipTrinket1Action, CleveRoids.FixEmptyTarget, false, _equipTrinket1Action) then
            return true
        end
    end
    return false
end

function CleveRoids.DoEquipTrinket2(msg)
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = string.gsub(parts[i], "^%?", "")
        if CleveRoids.DoWithConditionals(v, _equipTrinket2Action, CleveRoids.FixEmptyTarget, false, _equipTrinket2Action) then
            return true
        end
    end
    return false
end

function CleveRoids.DoEquipRing1(msg)
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = string.gsub(parts[i], "^%?", "")
        if CleveRoids.DoWithConditionals(v, _equipRing1Action, CleveRoids.FixEmptyTarget, false, _equipRing1Action) then
            return true
        end
    end
    return false
end

function CleveRoids.DoEquipRing2(msg)
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        local v = string.gsub(parts[i], "^%?", "")
        if CleveRoids.DoWithConditionals(v, _equipRing2Action, CleveRoids.FixEmptyTarget, false, _equipRing2Action) then
            return true
        end
    end
    return false
end

function CleveRoids.DoUnshift(msg)
    local handled
    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        handled = false
        if CleveRoids.DoWithConditionals(parts[i], _unshiftAction, CleveRoids.FixEmptyTarget, false, _unshiftAction) then
            handled = true
            break
        end
    end

    if handled == nil then
        _unshiftAction()
    end

    return handled
end

function CleveRoids.DoRetarget(msg) --新增条件支持 by 武藤纯子酱 2025.11.26
	local handled -- 修复：原初始化为 false 使 `handled == nil` 兜底分支永不执行（对照 DoUnshift），改为 nil by 武藤纯子酱 2026.9.11
	local action = function()
		-- 修复：GetUnitName 非标准 API（可能不存在），缺失时回退 UnitName
		-- by 武藤纯子酱 2026.9.11
		local tName = (GetUnitName and GetUnitName("target")) or UnitName("target")
		if tName == nil
			or CleveRoids.NampowerAPI.GetUnitHealth("target") == 0 -- 用CleveRoids.NampowerAPI.GetUnitHealth替代UnitHealth，识别假死等特殊情况 by 武藤纯子酱 2026.1.14
			or not UnitCanAttack("player", "target")
		then
			ClearTarget()
			TargetNearestEnemy()
		end
	end
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false -- 修复：每轮重置，条件不通过时不再误触发兜底 action()（否则 /retarget [cond] 会忽略条件） by 武藤纯子酱 2026.9.11
        v = string.gsub(v, "^%?", "")
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end
	
    if handled == nil then
        action()
    end
	
    return handled
end

-- Attempts to stop macro
-- Attempts to stop macro (stops ALL remaining lines including parent macros)
function CleveRoids.DoStopMacro(msg)
	local action = function() -- 若直接写/stopmacro，则之后的语句都不运行 by 武藤纯子酱 2025.12.16
		CleveRoids.stopMacroFlag = true
		return true
	end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(CleveRoids.Trim(msg))
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], action, nil, false, "STOPMACRO") then -- 修复/stopmacro必须加条件的BUG by 武藤纯子酱 2025.12.16
            return true
        end
    end
    return false
end

-- Attempts to skip remaining lines in current submacro ONLY (returns to parent)
function CleveRoids.DoSkipMacro(msg)
	local action = function() -- 若直接写/skipmacro，则之后的语句都跳过 by 武藤纯子酱 2026.1.16
		CleveRoids.skipMacroFlag = true
		return true
	end

    -- PERFORMANCE: Use numeric iteration to avoid pairs() iterator allocation
    local parts = CleveRoids.splitStringIgnoringQuotes(CleveRoids.Trim(msg))
    for i = 1, table.getn(parts) do
        if CleveRoids.DoWithConditionals(parts[i], action, nil, false, "SKIPMACRO") then -- 修复/skipmacro必须加条件的BUG by 武藤纯子酱 2026.1.16
            return true
        end
    end
    return false
end

-- Enables "stop on first successful cast" mode for the rest of the macro
-- When set, successful /cast or /use commands will set stopMacroFlag automatically
-- This allows priority-based macro evaluation: first matching cast wins
-- Example usage:
--   /firstaction
--   /cast [myrawpower:>48] Shred
--   /cast [myrawpower:>40] Claw
-- In this case, if Shred casts, Claw will NOT be queued
function CleveRoids.DoFirstAction(msg)
    -- Check if there are conditionals
    if msg and CleveRoids.Trim(msg) ~= "" then
        -- Has conditionals - use DoWithConditionals to evaluate them
        local parts = CleveRoids.splitStringIgnoringQuotes(CleveRoids.Trim(msg))
        for i = 1, table.getn(parts) do
            if CleveRoids.DoWithConditionals(parts[i], nil, nil, false, "FIRSTACTION") then
                return true
            end
        end
        return false
    else
        -- No conditionals - just set the flag
        CleveRoids.stopOnCastFlag = true
        return true
    end
end

-- Disables "stop on first successful cast" mode, re-enabling multi-queue behavior
-- Use this to restore normal evaluation after /firstaction
-- Example usage:
--   /firstaction
--   /cast [myrawpower:>48] Shred      -- Priority section
--   /cast [myrawpower:>40] Claw
--   /nofirstaction
--   /cast Tiger's Fury                -- Can queue alongside above
--   /startattack
function CleveRoids.DoNoFirstAction(msg)
    -- Check if there are conditionals
    if msg and CleveRoids.Trim(msg) ~= "" then
        -- Has conditionals - use DoWithConditionals to evaluate them
        local parts = CleveRoids.splitStringIgnoringQuotes(CleveRoids.Trim(msg))
        for i = 1, table.getn(parts) do
            if CleveRoids.DoWithConditionals(parts[i], nil, nil, false, "NOFIRSTACTION") then
                return true
            end
        end
        return false
    else
        -- No conditionals - clear the flags
        -- Capture stopOnCastFlag BEFORE clearing it to know if firstaction was active
        local wasFirstActionActive = CleveRoids.stopOnCastFlag
        CleveRoids.stopOnCastFlag = false
        -- Also clear stopMacroFlag if it was set by the firstaction mechanism
        -- (stopOnCastFlag being true means firstaction mode caused stopMacroFlag to be set)
        if wasFirstActionActive and CleveRoids.stopMacroFlag then
            CleveRoids.stopMacroFlag = false
        end
        return true
    end
end

function CleveRoids.DoCastSequence(sequence)
  if type(sequence) == "string" then
    sequence = CleveRoids.GetSequence(sequence)
    if not sequence then return end
  end

  if CleveRoids.currentSequence and not CleveRoids.CheckSpellCast("player") then
    CleveRoids.currentSequence = nil
  elseif CleveRoids.currentSequence then
    return
  end

  -- If sequence is complete, don't execute - let macro continue to next line
  if sequence.complete then
    return
  end

  if sequence and sequence.index and sequence.index > 1 and sequence.reset then -- 修复 by 武藤纯子酱 2025.11.28
    for k,_ in pairs(sequence.reset) do
      if CleveRoids.kmods[k] and CleveRoids.kmods[k]() then
        CleveRoids.ResetSequence(sequence)
        break
      end
    end
  end

  local active = CleveRoids.GetCurrentSequenceAction(sequence)
  if not (active and active.action) then return end

  -- Debug: Show sequence state
  if CleveRoids.debug then
    DEFAULT_CHAT_FRAME:AddMessage(string.format(
      "|cff00ffff[Sequence]|r Step %d/%d: '%s'",
      sequence.index, table.getn(sequence.list), active.action
    ))
  end

  -- Check for stop steps - does nothing, allows macro to fall through
  -- Sequence stays on this step until a reset condition fires (target/combat/time/modifier)
  -- Usage: /castsequence reset=target Sunder Armor, nil
  local actionLower = string.lower(CleveRoids.Trim(active.action))
  if actionLower == "nil" or actionLower == "null" or actionLower == "pass" or actionLower == "noop" then
    sequence.status = 0
    sequence.lastUpdate = GetTime()
    if CleveRoids.debug then
      DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff[Sequence]|r Hit stop step, falling through")
    end
    -- Don't cast anything, just return - allows macro to continue to next line
    return
  end

  sequence.status     = 0
  sequence.lastUpdate = GetTime()
  sequence.expires    = 0

  -- Capture target GUID for reset=target (only resets on NEW target, not same target)
  if sequence.reset and sequence.reset.target and UnitExists("target") then
    local targetGuid = CleveRoids.GetGUID("target")
    sequence.lastTargetGuid = targetGuid
  end

  local prevSeq = CleveRoids.currentSequence
  CleveRoids.currentSequence = sequence

  local actionText = (sequence.cond or "") .. active.action
  --local resolvedText, conds = CleveRoids.GetParsedMsg(actionText)
  local resolvedText = active.action -- 修复直接通过active.action获取当前技能序列 by 武藤纯子酱 2026.1.21
  local conds = sequence.cond -- 修复直接通过sequence.cond获取条件 by 武藤纯子酱 2026.1.21
  -- Check if this is a macro execution {macroname}
  local macroName = CleveRoids.GetMacroNameFromAction(active.action)
  if macroName then
    -- Execute the macro
    local success = CleveRoids.ExecuteMacroByName(macroName)
    if not success then
      CleveRoids.currentSequence = prevSeq
    end
    return
  end

  local function cast_by_name(msg)
    msg = msg or ""
    -- Check specifically for "(Rank" to allow spells like "Faerie Fire (Feral)"
    -- to still get their rank appended automatically
    if not string.find(msg, CleveRoids.Localized.SpellRank) then -- 修复多语言支持 by 武藤纯子酱 2025.12.29
      local sp = CleveRoids.GetSpell(msg)
      local r  = (sp and sp.rank) or (sp and sp.highest and sp.highest.rank)
      if r and r ~= "" then msg = msg .. "(" .. r .. ")" end
    end
    -- 统一引导打断：/castsequence（无条件的路径）也按 clip 模式处理 by 武藤纯子酱 2026.9.12
    if CleveRoids.ClipBeforeSpellCast and not CleveRoids.ClipBeforeSpellCast(msg, nil) then
      return false -- 保留引导，本次序列施法跳过
    end
    -- Let Nampower DLL handle queuing natively via its CastSpellByName hook
    CastSpellByName(msg)
    return true
  end

  local attempted = false
  if not conds then
    attempted = cast_by_name(resolvedText or active.action)
  else
    local final = CleveRoids.DoWithConditionals(actionText, nil, CleveRoids.FixEmptyTarget, false, CastSpellByName)
    if final then
      -- DoWithConditionals returns true (boolean) when it already cast the spell,
      -- or a string spell name when conditionals were skipped. Only call cast_by_name
      -- if we got a string back (spell wasn't cast yet).
      if type(final) == "string" then
        attempted = cast_by_name(final)
      else
        attempted = true  -- Spell was already cast inside DoWithConditionals
      end
    end
  end

  if not attempted then
    CleveRoids.currentSequence = prevSeq
  end
end

CleveRoids.DoConditionalCancelAura = function(msg)
  -- Check stopmacro flag
  if CleveRoids.stopMacroFlag then return false end

  local s = CleveRoids.Trim(msg or "")
  if s == "" then return false end

  -- No conditionals? cancel immediately.
  if not string.find(s, "%[") then
    return CleveRoids.CancelAura(s)
  end

  -- Has conditionals? Let the framework evaluate them, then run CancelAura.
  return CleveRoids.DoWithConditionals(s, nil, CleveRoids.FixEmptyTarget, false, CleveRoids.CancelAura) or false
end

-- PERFORMANCE: Separate periodic cleanup timer (runs every 5 seconds instead of every frame)
CleveRoids.lastCleanupTime = 0
CleveRoids.CLEANUP_INTERVAL = 5  -- Run cleanup every 5 seconds

-- PERFORMANCE: Upvalues for OnUpdate hot path
local GetTime = GetTime
local UnitAffectingCombat = UnitAffectingCombat
local pairs = pairs
local next = next
local IsAltKeyDown = IsAltKeyDown
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown

-- [moving] 条件的判定优先级（Conditionals.lua）：MonkeySpeed → Nampower PlayerIsMoving（v2.36+）
-- 原 100Hz UnitPosition("player") 轮询依赖 SuperWoW 专属 API，已移除——Nampower 环境下
-- PlayerIsMoving 直接查询移动标志（连跳跃/坠落/俯仰都能捕捉），能力覆盖且成本更低。
-- 无 MonkeySpeed 且 Nampower 过旧时 [moving] 返回 false（与原无 SuperWoW 环境一致）。 by 武藤纯子酱 2026.9.1

local SEQUENCE_STALE_TIME = 300  -- 5 minutes

function CleveRoids.OnUpdate(self)
    -- PERFORMANCE: Local alias for global namespace (saves ~80+ global lookups per frame)
    local CR = CleveRoids
    local CRM = CleveRoidMacros

    -- Prevent mod API calls during shutdown (crash prevention)
    if CR.isShuttingDown then return end

    -- Clear macro stop flags at the start of each frame
    -- This ensures /stopmacro and /skipmacro only affect commands in the same frame (same macro execution)
    -- Without SuperMacro, this is necessary because we can't hook into macro line execution
    if CR.stopMacroFlag then
        CR.stopMacroFlag = false
    end
    if CR.skipMacroFlag then
        CR.skipMacroFlag = false
    end
    if CR.stopOnCastFlag then
        CR.stopOnCastFlag = false
    end
    -- 帧内施法护栏：每帧复位（执行时由 DoWithConditionals 的 CastSpellByName 分支置位），
    -- 保证非宏执行路径（如 !前缀防抖）使用后不会永久卡住 by 武藤纯子酱 2026.9.9
    if CR._castIssuedThisFrame then
        CR._castIssuedThisFrame = false
    end

    -- 动作条页轮询（[actionbar:n]/[bar:n] 图标刷新）by 武藤纯子酱 2026.9.3
    -- 1.12 无 ACTIONBAR_PAGE_CHANGED 事件、无 GetActionBarPage()，只能定期比对
    -- FrameXML 全局变量 CURRENT_ACTIONBAR_PAGE；每帧一次全局读取+比较，开销可忽略
    local curActionBarPage = CURRENT_ACTIONBAR_PAGE
    if curActionBarPage ~= CR._lastActionBarPage then
        CR._lastActionBarPage = curActionBarPage
        if CRM.realtime == 0 then
            CR.QueueActionUpdate()
        end
    end

    for guid, _ in pairs(CleveRoids.PlayerSummons) do -- 新增myunit检测 by 武藤纯子酱 2026.4.27
        if UnitExists(guid) then
            local name = UnitName(guid)
            if name and name ~= "" and name ~= "未知目标" then
                CleveRoids.PlayerSummons[guid] = name
            end
        else
            CleveRoids.PlayerSummons[guid] = nil
        end
    end

	if not StaticPopupDialogs["SP_ST_Install"] and Abar_Mhr then -- 新增当未安装SP_SwingTimer可通过AttackBar监控挥砍时间 by 武藤纯子酱 2026.1.26
		-- 性能优化：原每帧调用 GetAttackState（每次分配 6 字段表）+ UnitAttackSpeed；节流到 ~0.05s
		-- 摆锤计时精度视觉无损、攻击速度极少变化 by 武藤纯子酱 2026.9.11
		local astNow = GetTime()
		if not CR._lastAttackStateTime or (astNow - CR._lastAttackStateTime) >= 0.05 then
			CR._lastAttackStateTime = astNow
			local attackState = CleveRoids.GetAttackState()
			st_timer = attackState.mhRemaining
			st_timerMax = UnitAttackSpeed("player")
		end
	end

	-- 性能优化（P1-5）：Tags/TagUnits 改为复用表 + 每帧清空——语义保持"仅单帧生效，
	-- 避免宏的数据污染其他宏"，但消除每帧 2 次表分配带来的 GC 抖动 by 武藤纯子酱 2026.8.31
	local tagKey = next(CR.Tags)
	while tagKey do CR.Tags[tagKey] = nil; tagKey = next(CR.Tags) end
	tagKey = next(CR.TagUnits)
	while tagKey do CR.TagUnits[tagKey] = nil; tagKey = next(CR.TagUnits) end
	CR.SetTags = false -- 新增每帧删除settag标签 by 武藤纯子酱 2026.1.28
	CR._mostWoundedGroupCache = nil -- 新增每帧删除_mostWoundedGroupCache by 武藤纯子酱 2026.3.21
	
    -- PERFORMANCE: Single GetTime() call per frame
    local time = GetTime()

    -- PERFORMANCE: Early exit if not ready (before any other checks)
    if not CR.ready then
        -- Handle initialization timer only when not ready
        if CR.initializationTimer and time >= CR.initializationTimer then
            CR.initializationTimer = nil
            CR.IndexItems()
            CR.IndexTalents() -- 新增在初始化的时候执行一次获取当前天赋 by 武藤纯子酱 2026.5.13
            -- FIX: Set ready=true BEFORE IndexActionBars so GetAction() works
            -- IndexActionSlot calls GetAction() which has an early-exit if ready=false,
            -- preventing TestForActiveAction from populating actions.active
            CR.ready = true

            -- FIX: Suppress action event handlers during initial indexing
            -- IndexActionBars sends ACTIONBAR_SLOT_CHANGED for each slot which triggers
            -- addon handlers (pfUI, Bongos). 120 rapid calls can cause issues.
            CR._suppressActionHandlers = true
            CR.IndexActionBars()
            CR._suppressActionHandlers = false

            CR.TestForAllActiveActions()
            CR.lastUpdate = time

            -- FIX: Force refresh ALL Blizzard action buttons after initialization
            -- Blizzard queries IsUsableAction during login before we're ready,
            -- caching the wrong state. We must force a re-query for all buttons.
            -- SKIP for pfUI users - pfUI handles its own button updates and this
            -- would trigger 120 rapid handler calls causing issues.
            if not (pfUI and pfUI.bars) then
                for slot = 1, 120 do
                    if CR.Actions[slot] then
                        CR.SendEventForAction(slot, "ACTIONBAR_SLOT_CHANGED", slot)
                    end
                end
            end
        end
        return
    end

    -- =========================================================================
    -- CONTINUOUS POSITION TRACKING 已移除
    -- =========================================================================
    -- 原实现以 100Hz 轮询 UnitPosition("player")（SuperWoW 专属 API）维护位置历史，
    -- 供 [moving] 条件兜底。现由 Nampower PlayerIsMoving（v2.36+，见 Conditionals.lua
    -- IsPlayerMoving）直接查询移动标志替代；无 MonkeySpeed 且 Nampower 过旧时
    -- [moving] 返回 false。CleveRoids._positionHistory 永为 nil，消费方已做 nil 防护。 by 武藤纯子酱 2026.9.1

    -- PERFORMANCE: Delayed WDB warmup after login (ensures GetItemInfo works after WDB clear)
    if CR.wdbWarmupTime and time >= CR.wdbWarmupTime then
        CR.wdbWarmupTime = nil
        CR.DoWDBWarmup()
    end

    -- PERFORMANCE: Cache refresh rate calculation (avoid per-frame division)
    local refreshRate = CR.cachedRefreshRate
    if not refreshRate then
        refreshRate = 1 / (CRM.refresh or 10) -- 与上方默认值保持一致 by 武藤纯子酱 2026.8.31
        CR.cachedRefreshRate = refreshRate
    end

    -- PERFORMANCE: Throttle check FIRST - skip most work on non-throttled frames
    local lastUpdate = CR.lastUpdate or 0
    local bypassThrottle = CR.isActionUpdateQueued and CRM.realtime == 0
    local shouldUpdate = bypassThrottle or (time - lastUpdate) >= refreshRate

    if not shouldUpdate then
        return  -- Early exit for non-throttled frames
    end

    CR.lastUpdate = time

    -- Process deferred equipment index updates (for throttled UNIT_INVENTORY_CHANGED)
    -- PERFORMANCE: Skip check entirely if no pending update
    local pendingTime = CR.equipIndexPendingTime
    if pendingTime and not UnitAffectingCombat("player") then
        if (time - (CR.lastEquipIndexTime or 0)) >= 0.2 then
            CR.lastEquipIndexTime = time
            CR.equipIndexPendingTime = nil
            CR.lastItemIndexTime = time
            -- 性能优化：装备变化时动作条布局/宏文本未变，IndexItems（内含 relink）足够，
            -- 不再全量清空 + IndexActionBars（120×tooltip SetAction）by 武藤纯子酱 2026.8.31
            CR.IndexItems()

            if CRM.realtime == 0 then
                CR.QueueActionUpdate()
            end
        end
    end

    -- PERFORMANCE: Check for expired reactive procs only if we have any
    -- Use statically allocated removal buffer to avoid per-frame allocation
    local reactiveProcs = CR.reactiveProcs
    if reactiveProcs then
        local hasExpiredProc = false
        local toRemove = CR._procRemovalBuffer
        local removeCount = 0

        -- PERFORMANCE: Use next() directly instead of pairs() to avoid iterator allocation
        local spellName, procData = next(reactiveProcs)
        while spellName do
            if procData and procData.expiry and time >= procData.expiry then
                removeCount = removeCount + 1
                toRemove[removeCount] = spellName
                hasExpiredProc = true
            end
            spellName, procData = next(reactiveProcs, spellName)
        end

        -- Remove expired procs using indexed array (no pairs() overhead)
        for i = 1, removeCount do
            reactiveProcs[toRemove[i]] = nil
            toRemove[i] = nil  -- Clear for next use
        end

        -- If any proc expired, immediately update all actions
        if hasExpiredProc then
            CR.TestForAllActiveActions()
            CR.isActionUpdateQueued = false
        end
    end
    -- PERFORMANCE: Check for modifier key state changes (no events for these in vanilla WoW)
    -- Only queue update if modifier state actually changed - avoids full TestForAllActiveActions
    -- Nampower v2.41+ fires KEY_DOWN/KEY_UP for all keys including modifiers, so skip polling
    if not CR.NampowerAPI.features.hasKeyEvents then
        local altDown = IsAltKeyDown()
        local shiftDown = IsShiftKeyDown()
        local ctrlDown = IsControlKeyDown()

        if altDown ~= CR._lastAltDown or
           shiftDown ~= CR._lastShiftDown or
           ctrlDown ~= CR._lastCtrlDown then
            CR._lastAltDown = altDown
            CR._lastShiftDown = shiftDown
            CR._lastCtrlDown = ctrlDown
            -- Modifier changed - queue update in event-driven mode, or just mark for realtime
            if CRM.realtime == 0 then
                CR.isActionUpdateQueued = true
            end
        end
    end

    -- Check the saved variable to decide which update mode to use.
    if CRM.realtime == 1 then
        -- Realtime Mode: Force an update on every throttled tick for maximum responsiveness.
        CR.TestForAllActiveActions()
    else
        -- Event-Driven Mode (Default): Only update if a relevant game event has queued it.
        if CR.isActionUpdateQueued then
            CR.TestForAllActiveActions()
            CR.isActionUpdateQueued = false
        end
    end

    -- The rest of this function handles time-based logic that must always run.
    if CR.CurrentSpell.autoAttackLock and (time - CR.autoAttackLockElapsed) > refreshRate then
        CR.CurrentSpell.autoAttackLock = false
        CR.autoAttackLockElapsed = nil
    end

    -- PERFORMANCE: Use next() directly instead of pairs() to avoid iterator allocation
    local Sequences = CR.Sequences
    local seqKey, sequence = next(Sequences)
    while seqKey do
        if sequence.index > 1 and sequence.reset.secs and (time - (sequence.lastUpdate or 0)) >= sequence.reset.secs then
            CR.ResetSequence(sequence)
        end
        seqKey, sequence = next(Sequences, seqKey)
    end

    -- PERFORMANCE: Use next() directly instead of pairs() to avoid iterator allocation
    local spell_tracking = CR.spell_tracking
    local guid, cast = next(spell_tracking)
    while guid do
        local nextGuid = next(spell_tracking, guid)  -- Get next before potential removal
        if cast.expires and time > cast.expires then
            spell_tracking[guid] = nil
        end
        guid, cast = nextGuid, nextGuid and spell_tracking[nextGuid]
    end

    -- ===== Nampower 队列/施法状态防卡死看门狗 by 武藤纯子酱 2026.8.31 =====
    -- 每 0.1 秒校准一次内部施法状态（TTL 对齐统一上限）。Nampower 队列会把技能延迟到 GCD/前一个施法结束才弹出，
    -- 若弹出时失败/被打断/玩家死亡，对应清理事件可能丢失，内部状态会永久卡死并卡住宏：
    --   1) CurrentSpell.type == "cast" 但客户端实际没有在施法（SPELLCAST_STOP/FAILED/INTERRUPTED 丢失）
    --      → 恢复（否则 [casting]/[nocasting] 恒真，/castsequence 与宏被卡住）
    --   2) CurrentSpell.type == "channeled" 但引导早已结束（SPELLCAST_CHANNEL_STOP 丢失）→ 恢复
    --      （否则 [nochanneling]/[channeling] 恒假，宏被卡住）
    --   3) queuedSpell 长时间未被弹出（死亡/上坐骑/换图等异常路径清空队列而 SPELL_QUEUE_EVENT POPPED 丢失）
    --      → 丢弃（否则 [queued]/[noqueued]/[queuedspell] 永久失真）
    --   4) /castsequence 状态机停在 status==1（"施法中"）但实际已无任何施法在跑 → 复位为 0
    --      （否则序列永久停在当前步不再前进）
    if (time - (CR._lastCastStateWatchdog or 0)) >= 0.1 then
        CR._lastCastStateWatchdog = time

        local okCast, _, _, _, castingNow, channelingNow = pcall(GetCurrentCastingInfo)

        -- 1) 普通施法状态校准（UpdateCastingState 只在队列/施法事件时被调用，事件丢失即卡死）
        if CR.CurrentSpell.type == "cast" and okCast and castingNow ~= 1 then
            CR.CurrentSpell.type = ""
            CR.CurrentSpell.spellName = ""
            CR.CurrentSpell.castingSpellId = nil
            CR.TestForAllActiveActions()
        end

        -- 2) 引导状态校准（客户端引导标志为权威；仅无客户端信息时才按记录的引导时长兜底）
        if CR.CurrentSpell.type == "channeled" then
            local elapsed = time - (CR.channelStartTime or 0)
            local stale = false
            if okCast then
                if channelingNow ~= 1 and elapsed > 0.5 then
                    stale = true
                end
            elseif (CR.channelDuration or 0) > 0 and elapsed > CR.channelDuration + 1.0 then
                stale = true
            end
            if stale then
                CR.CurrentSpell.type = ""
                CR.CurrentSpell.spellName = ""
                CR.CurrentSpell.castingSpellId = nil
                CR.channelStartTime = 0
                CR.channelDuration = 0
                CR.TestForAllActiveActions()
            end
        end

        -- 3) 队列条目过期（正常路径 POPPED 事件会清掉它，这里只兜异常丢失）
        if CR.queuedSpell and (time - (CR.queuedSpell.queueTime or 0)) > 15 then
            CR.queuedSpell = nil
            CR.QueueActionUpdate()
        end

        -- 4) castsequence 状态机复位（status==1 且确无施法在跑）
        local seq = CR.currentSequence
        if seq and seq.status == 1 then
            local busy = (CR.CurrentSpell.type ~= nil and CR.CurrentSpell.type ~= "")
            if not busy then
                local track = CR.spell_tracking and CR.spell_tracking["player"]
                busy = (track and track.expires and time < track.expires) or false
            end
            if not busy then
                seq.status = 0
            end
        end
    end

    -- ===== @cursor / [mouseuse] / castAOE 的队列感知延迟处理 by 武藤纯子酱 2026.8.31 =====
    -- 施法被 Nampower 排队时，地面目标圈要等队列弹出才会出现；
    -- 在按键当时立即点击/恢复 CVar 会全部落空（点空地、快速施法提前还原）。
    -- 这里轮询等目标圈真正出现后再执行，超时则放弃。
    if CR._pendingMouseUse then
        if SpellIsTargeting() then
            local wasAttacking = CR.CurrentSpell.autoAttack
            CameraOrSelectOrMoveStart()
            CameraOrSelectOrMoveStop()
            -- CameraOrSelectOrMoveStart 可能顺带开启自动攻击，非主动开启时立即关掉
            if not wasAttacking then
                local slot = CR.GetProxyActionSlot(CR.Localized.Attack)
                if slot and CR.Hooks.IsCurrentAction(slot) then
                    AttackTarget()
                    CR.CurrentSpell.autoAttack = false
                end
            end
            CR._pendingMouseUse = nil
        elseif time > (CR._pendingMouseUse.deadline or 0) then
            CR._pendingMouseUse = nil
        end
    end

    if CR._pendingCastAOE then
        if SpellIsTargeting() then
            pcall(UnitXP, "castAOE", CR._pendingCastAOE.unit)
            CR._pendingCastAOE = nil
        elseif time > (CR._pendingCastAOE.deadline or 0) then
            CR._pendingCastAOE = nil
        end
    end

    if CR._pendingCursorRestore then
        -- 队列已弹出（queuedSpell 清空）或超时，恢复快速区域施法 CVar
        if CR.queuedSpell == nil or time > (CR._pendingCursorRestore.deadline or 0) then
            SetCVar("NP_QuickcastTargetingSpells", "0")
            CR._pendingCursorRestore = nil
        end
    end

    -- Clean stale castTracking entries (standalone mode only, pfUI 7.6 manages its own)
    if not CR.hasPfUI76 then
        local ct = CR.castTracking
        local ctGuid, ctEntry = next(ct)
        while ctGuid do
            local nextCtGuid = next(ct, ctGuid)
            if ctEntry.endTime and time > ctEntry.endTime + 0.5 then
                ct[ctGuid] = nil
            end
            ctGuid = nextCtGuid
            ctEntry = nextCtGuid and ct[nextCtGuid]
        end
    end

    -- PERFORMANCE OPTIMIZATION: Run memory cleanup less frequently (every 5 seconds instead of every frame)
    -- This reduces CPU usage while maintaining effective memory management
    if (time - CR.lastCleanupTime) >= CR.CLEANUP_INTERVAL then
        CR.lastCleanupTime = time

        -- MEMORY: Clean up carnageDurationOverrides older than 30 seconds
        -- PERFORMANCE: Use next() directly instead of pairs() to avoid iterator allocation
        local carnageOverrides = CR.carnageDurationOverrides
        if carnageOverrides then
            local spellID, data = next(carnageOverrides)
            while spellID do
                local nextID = next(carnageOverrides, spellID)
                if data.timestamp and (time - data.timestamp) > 30 then
                    carnageOverrides[spellID] = nil
                end
                spellID, data = nextID, nextID and carnageOverrides[nextID]
            end
        end

        -- MEMORY: Clean up old ComboPointTracking entries (older than 60 seconds)
        -- PERFORMANCE: Use next() directly instead of pairs() to avoid iterator allocation
        local comboTracking = CR.ComboPointTracking
        if comboTracking then
            local trackName, data = next(comboTracking)
            while trackName do
                local nextName = next(comboTracking, trackName)
                if data.cast_time and (time - data.cast_time) > 60 then
                    comboTracking[trackName] = nil
                end
                trackName, data = nextName, nextName and comboTracking[nextName]
            end
        end

        -- MEMORY: 兜底清理过期的 castOutcomePending（正常由命中/抵抗事件或查询惰性清除；
        -- 事件丢失且从未查询时会残留，此处按时间戳兜底）by 武藤纯子酱 2026.9.11
        local cop = CR.castOutcomePending
        if cop then
            local copKey, copVal = next(cop)
            while copKey do
                local copNext = next(cop, copKey)
                if not copVal.t or (time - copVal.t) > 5 then
                    cop[copKey] = nil
                end
                copKey, copVal = copNext, copNext and cop[copNext]
            end
        end
		
        -- MEMORY: Clear spell name caches every 60 seconds (12 cleanup cycles)
        CR._spellCacheCleanupCounter = (CR._spellCacheCleanupCounter or 0) + 1
        if CR._spellCacheCleanupCounter >= 12 then
            CR._spellCacheCleanupCounter = 0
            if CR.ClearSpellNameCaches then
                CR.ClearSpellNameCaches()
            end
            if CR.ClearStripRankCache then
                CR.ClearStripRankCache()
            end
        end

        -- MEMORY: Clean up stale perTargetState entries in sequences (older than 5 minutes)
        -- This prevents memory bloat from tracking many targets over time
        -- PERFORMANCE: Use next() instead of pairs() to avoid iterator closure allocation
        local seqKey2, seq2 = next(CR.Sequences)
        while seqKey2 do
            if seq2.perTargetState then
                local ptGuid, ptState = next(seq2.perTargetState)
                while ptGuid do
                    local nextPtGuid = next(seq2.perTargetState, ptGuid)
                    if ptState.lastUpdate and (time - ptState.lastUpdate) > SEQUENCE_STALE_TIME then
                        seq2.perTargetState[ptGuid] = nil
                    end
                    ptGuid = nextPtGuid
                    ptState = nextPtGuid and seq2.perTargetState[nextPtGuid]
                end
            end
            seqKey2, seq2 = next(CR.Sequences, seqKey2)
        end
    end

    -- 清理过期消息（1.5秒存活）
    -- 修复：Lua 5.0.2 的 table.getn 在"尾部被置 nil、部分元素落入 hash 部"时可能误报长度，
    -- 原"定位首个未过期下标 + 前缀压缩 + 尾部置 nil"的写法会破坏数组连续性并制造空洞，
    -- 下一 tick 迭代到 nil 即崩溃（attempt to index field '?'）。改为 next() 遍历、
    -- 仅在确有过期/非法条目时重建干净数组，不使用 table.getn、不产生中间空洞
    -- by 武藤纯子酱 2026.9.9
    local now = GetTime()
    local oldQ = CleveRoids.messageQueue
    local hasExpired = false
    local k, entry = next(oldQ)
    while k do
        if type(entry) ~= "table" or not entry.timestamp or (now - entry.timestamp) > 1.5 then
            hasExpired = true
            break
        end
        k, entry = next(oldQ, k)
    end
    if hasExpired then
        local newQ = {}
        local n = 0
        k, entry = next(oldQ)
        while k do
            if type(entry) == "table" and entry.timestamp and (now - entry.timestamp) <= 1.5 then
                n = n + 1
                newQ[n] = entry
            end
            k, entry = next(oldQ, k)
        end
        CleveRoids.messageQueue = newQ
    end
end

-- Initialize the nested table for the GameTooltip hooks if it doesn't exist
if not CleveRoids.Hooks.GameTooltip then CleveRoids.Hooks.GameTooltip = {} end

-- Save the original GameTooltip.SetAction function before we override it
CleveRoids.Hooks.GameTooltip.SetAction = GameTooltip.SetAction

-- Now, define our custom version of the function
function GameTooltip.SetAction(self, slot)
    if not slot then return end
    local actions = CleveRoids.GetAction(slot)

    -- If this is our macro but has no active action, show just the macro name
    if actions and not actions.active then
        local macroName = GetActionText(slot)
        if macroName then
            GameTooltip:SetText(macroName)
            GameTooltip:Show()
            return
        end
    end

    local action_to_display_info = nil
    if actions then
        -- Only show spell/item tooltip when there's an active action
        if actions.active then
            action_to_display_info = actions.active
        end
    end

    if action_to_display_info and action_to_display_info.action then
        local action_name = action_to_display_info.action

        -- NEW: Check if action is a slot ID for tooltip
        local slotId = tonumber(action_name)
        if slotId and slotId >= 1 and slotId <= 19 then
            -- Use the more specific SetInventoryItem function to prevent conflicts with other addons.
            GameTooltip:SetInventoryItem("player", slotId)
            GameTooltip:Show()
            return
        end
        -- End new logic

        local current_spell_data = CleveRoids.GetSpell(action_name)
        if current_spell_data then
            GameTooltip:SetSpell(current_spell_data.spellSlot, current_spell_data.bookType)
            local rank_info = current_spell_data.rank or (current_spell_data.highest and current_spell_data.highest.rank)
            if rank_info and rank_info ~= "" then
                GameTooltipTextRight1:SetText("|cff808080" .. rank_info .. "|r")
            else
                GameTooltipTextRight1:SetText("")
            end
            GameTooltipTextRight1:Show()
            GameTooltip:Show()
            return
        end

        local current_item_data = CleveRoids.GetItem(action_name)
        if current_item_data then
            -- Use specific functions based on where the item is located.
            if current_item_data.inventoryID then
                GameTooltip:SetInventoryItem("player", current_item_data.inventoryID)
            elseif current_item_data.bagID and current_item_data.slot then
                GameTooltip:SetBagItem(current_item_data.bagID, current_item_data.slot)
            else
                -- Fallback to the original method if location is unknown.
                GameTooltip:SetHyperlink(current_item_data.link)
            end
            GameTooltip:Show()
            return
        end

        if action_to_display_info.macro and type(action_to_display_info.macro) == "table" then
            local nested_action_info = action_to_display_info.macro
            local nested_action_name = nested_action_info.action

            current_spell_data = CleveRoids.GetSpell(nested_action_name)
            if current_spell_data then
                GameTooltip:SetSpell(current_spell_data.spellSlot, current_spell_data.bookType)
                local rank_info = current_spell_data.rank or (current_spell_data.highest and current_spell_data.highest.rank)
                if rank_info and rank_info ~= "" then
                    GameTooltipTextRight1:SetText("|cff808080" .. rank_info .. "|r")
                else
                    GameTooltipTextRight1:SetText("")
                end
                GameTooltipTextRight1:Show()
                GameTooltip:Show()
                return
            end

            current_item_data = CleveRoids.GetItem(nested_action_name)
            if current_item_data then
                 if current_item_data.inventoryID then
                    GameTooltip:SetInventoryItem("player", current_item_data.inventoryID)
                elseif current_item_data.bagID and current_item_data.slot then
                    GameTooltip:SetBagItem(current_item_data.bagID, current_item_data.slot)
                else
                    GameTooltip:SetHyperlink(current_item_data.link)
                end
                GameTooltip:Show()
                return
            end
        end
    end

    -- If none of our custom logic handled it, call the original function we saved earlier.
    CleveRoids.Hooks.GameTooltip.SetAction(self, slot)
end

CleveRoids.Hooks.PickupAction = PickupAction
function PickupAction(slot)
    if not slot then return end
    CleveRoids.ClearAction(slot)
    CleveRoids.ClearSlot(CleveRoids.actionSlots, slot)
    CleveRoids.ClearSlot(CleveRoids.reactiveSlots, slot) -- 修复：原误用 ClearAction（单参签名），reactiveSlots 永不清理 by 武藤纯子酱 2026.9.11
    return CleveRoids.Hooks.PickupAction(slot)
end

CleveRoids.Hooks.ActionHasRange = ActionHasRange
function ActionHasRange(slot)
    if not slot then return nil end
    local actions = CleveRoids.GetAction(slot)
    -- Only override for our macros with #showtooltip
    if actions and actions.tooltip then
        -- If we have an active action with valid range data, use it
        if actions.active then
            if actions.active.inRange ~= -1 then
                return 1  -- Has range check with valid data
            else
                -- For channeled spells (inRange == -1), try proxy slot lookup
                local spellName = actions.active.spell and actions.active.spell.name
                local proxySlot = spellName and CleveRoids.GetProxyActionSlot(spellName)
                if proxySlot then
                    return CleveRoids.Hooks.ActionHasRange(proxySlot)
                end
            end
        end
        -- FIX: Even without actions.active, if the macro has potential spell actions,
        -- return 1 to ensure pfUI calls IsActionInRange (which will do proper checks)
        -- This fixes Super macros where actions.active might not be populated yet
        if actions.tooltip.spell or actions.tooltip.type == "spell" then
            return 1  -- Tooltip is a spell - has range
        end
        -- Check if any action in the list is a spell
        if actions.list then
            for i = 1, table.getn(actions.list) do
                local action = actions.list[i]
                if action and (action.spell or action.type == "spell") then
                    return 1  -- Has at least one spell action
                end
            end
        end
    end
    -- Not a macro we're tracking - pass through to original
    return CleveRoids.Hooks.ActionHasRange(slot)
end

CleveRoids.Hooks.IsActionInRange = IsActionInRange
function IsActionInRange(slot, unit)
    if not slot then return nil end
    local actions = CleveRoids.GetAction(slot)
    -- Only override for our macros with #showtooltip
    if actions and actions.tooltip then
        -- If we have an active spell action, use its range data
        if actions.active and actions.active.type == "spell" then
            if actions.active.inRange ~= -1 then
                return actions.active.inRange
            else
                -- For channeled spells (inRange == -1), try proxy slot lookup
                local spellName = actions.active.spell and actions.active.spell.name
                local proxySlot = spellName and CleveRoids.GetProxyActionSlot(spellName)
                if proxySlot then
                    return CleveRoids.Hooks.IsActionInRange(proxySlot, unit)
                end
            end
        end
        -- FIX: If no active action but macro has tooltip spell, check its range directly
        -- This ensures range coloring works even when actions.active hasn't been populated
        if not actions.active and actions.tooltip.spell then
            local spell = actions.tooltip.spell
            local spellName = spell.name
            if spellName and IsSpellInRange then
                local targetUnit = unit or "target"
                if UnitExists(targetUnit) then
                    -- FIX: Wrap in pcall - spell might not be in spellbook (items, other class spells, etc.)
                    local ok, result = pcall(IsSpellInRange, spellName, targetUnit)
                    if ok then
                        if result == 0 then
                            return 0  -- Out of range
                        elseif result == 1 then
                            return 1  -- In range
                        end
                    end
                end
            end
            -- Try proxy slot as fallback
            local proxySlot = spellName and CleveRoids.GetProxyActionSlot(spellName)
            if proxySlot then
                return CleveRoids.Hooks.IsActionInRange(proxySlot, unit)
            end
        end
    end
    -- Not a macro we're tracking - pass through to original
    return CleveRoids.Hooks.IsActionInRange(slot, unit)
end

CleveRoids.Hooks.OriginalIsUsableAction = IsUsableAction
CleveRoids.Hooks.IsUsableAction = IsUsableAction
function IsUsableAction(slot, unit)
    if not slot then return nil, nil end
    local actions = CleveRoids.GetAction(slot)

    -- If this is one of our macros AND it uses #showtooltip
    if actions and actions.tooltip then
        -- IMPORTANT: Only override usability when #showtooltip is present
        -- Macros without #showtooltip should use default game behavior
        if actions.active then
            -- We have an active action - return its usable state
            -- FIX: Convert oom boolean to number (1/nil) for Blizzard's button code
            local oomValue = actions.active.oom and 1 or nil
            return actions.active.usable, oomValue
        else
            -- FIX: If no active action but tooltip has a spell, check its usability directly
            -- This ensures usability coloring works even when actions.active hasn't been populated
            if actions.tooltip.spell then
                local spell = actions.tooltip.spell
                local spellName = spell.name
                if spellName and IsSpellUsable then
                    -- FIX: Wrap in pcall - spell might not be in spellbook (items, other class spells, etc.)
                    local ok, usable, notEnoughMana = pcall(IsSpellUsable, spellName)
                    if ok then
                        if usable == 1 then
                            return 1, nil  -- Usable
                        elseif notEnoughMana == 1 then
                            return nil, 1  -- Out of mana
                        else
                            return nil, nil  -- Not usable (wrong stance, etc.)
                        end
                    end
                end
                -- Fallback: check if spell has a cost and compare to current mana
                if spell.cost and spell.cost > 0 then
                    local currentMana = UnitMana("player")
                    if currentMana < spell.cost then
                        return nil, 1  -- Out of mana
                    end
                end
                -- Default to usable if we can't determine otherwise
                return 1, nil
            elseif actions.tooltip.item then
                -- FIX: Handle item tooltips - items are always usable unless on cooldown
                -- The cooldown is handled separately by GetActionCooldown hook
                return 1, nil
            end
            -- No tooltip spell or item - this macro's conditionals all failed
            -- Return nil to make the icon dark
            return nil, nil
        end
    else
        -- Not our macro OR no #showtooltip - use game's default behavior
        return CleveRoids.Hooks.IsUsableAction(slot, unit)
    end
end

CleveRoids.Hooks.IsCurrentAction = IsCurrentAction
function IsCurrentAction(slot)
    if not slot then return nil end
    local actions = CleveRoids.GetAction(slot)

    -- When no action is active (all conditionals failed), don't check tooltip's "current" status
    if actions and not actions.active and not actions.explicitTooltip and actions.list and table.getn(actions.list) > 0 then
        return CleveRoids.Hooks.IsCurrentAction(slot)
    end

    -- Use the same priority as GetActionTexture: active first, then tooltip
    local actionToCheck = (actions and actions.active) or (actions and actions.tooltip)

    if not actionToCheck then
        return CleveRoids.Hooks.IsCurrentAction(slot)
    else
        local name
        if actionToCheck.spell then
            -- 修复：无 Rank 法术（姿态/追踪/自动射击/暗影形态等）的索引条目没有 rank 字段，
            -- highest 指回自身时 rank 仍为 nil → 原代码 name..nil 拼接崩溃（IsCurrentAction
            -- 为图标高频调用，会连续刷红字）；highest 为 nil 时索引也崩溃 by 武藤纯子酱 2026.9.9
            local rank = actionToCheck.spell.rank
                or (actionToCheck.spell.highest and actionToCheck.spell.highest.rank)
            name = actionToCheck.spell.name..(rank and ("("..rank..")") or "")

            -- Check if this spell is currently queued or being cast via Nampower
            -- Get spell ID for comparison
            local spellId = actionToCheck.spell.id
            if not spellId and GetSpellIdForName then
                spellId = GetSpellIdForName(name)
            end

            if spellId then
                -- Prefer GetCastInfo (Nampower 2.18+) for cleaner API
                if GetCastInfo then
                    local ok, info = pcall(GetCastInfo)
                    if ok and info and info.spellId == spellId then
                        -- Spell is actively being cast/channeled
                        return true
                    end
                end

                -- Also check GetCurrentCastingInfo for queued spell detection
                if GetCurrentCastingInfo then
                    local castId, visId, autoId, casting, channeling = GetCurrentCastingInfo()

                    -- Show glow if actively casting/channeling this spell
                    if (casting == 1 and castId == spellId) or (channeling == 1 and visId == spellId) then
                        return true
                    end
                    -- Show glow if this spell is queued (castId set but not yet casting)
                    if casting == 0 and channeling == 0 and castId == spellId then
                        return true
                    end
                end
            end
        elseif actionToCheck.item then
            name = actionToCheck.item.name
        end

        return CleveRoids.Hooks.IsCurrentAction(CleveRoids.GetProxyActionSlot(name) or slot)
    end
end

-- 性能优化：GetActionTexture 热路径专用模块级表 by 武藤纯子酱 2026.8.31
-- 动作名 → 规范化名（StripRank+下划线替换）缓存，永久+256 上限
local _actionIconNameCache = {}
-- 切换型潜行类技能（键为原大小写 Localized 名；Localization 先于 Core 加载，此处取值安全）
local _toggledBuffAbilities = {
    [CleveRoids.Localized.Spells["Prowl"]] = true,
    [CleveRoids.Localized.Spells["Shadowmeld"]] = true,
}

CleveRoids.Hooks.GetActionTexture = GetActionTexture
function GetActionTexture(slot)
    if not slot then return nil end
    local actions = CleveRoids.GetAction(slot)

    -- Check if this is one of our macros
    if actions and (actions.active or actions.tooltip) then

        -- This block handles the case where all conditionals fail and no explicit
        -- #showtooltip was set. It defaults to the macro's chosen icon.
        if not actions.active and not actions.explicitTooltip and actions.list and table.getn(actions.list) > 0 then
            -- Get the macro's own icon as fallback
            local macroTexture = nil
            local macroName = GetActionText(slot)
            if macroName then
                local macroID = GetMacroIndexByName(macroName)
                if macroID and macroID > 0 then
                    local _, texture = GetMacroInfo(macroID)
                    macroTexture = texture
                end
            end

            -- When no conditionals pass, use macro icon (not first action's icon)
            -- The actions.tooltip is just the first action which didn't pass conditionals
            if macroTexture then
                return macroTexture
            end

            -- Should never reach here, but return unknown as last resort
            return CleveRoids.unknownTexture
        end

        -- Prioritize active action, fall back to tooltip
        local a = actions.active or actions.tooltip

        -- Handle numeric slot actions (e.g., /use 13)
        local slotId = tonumber(a.action)
        if slotId and slotId >= 1 and slotId <= 19 then
            local currentTexture = GetInventoryItemTexture("player", slotId)
            if currentTexture then
                return currentTexture
            end

            -- Slot is empty, fall back to macro icon
            local macroName = GetActionText(slot)
            if macroName then
                local macroID = GetMacroIndexByName(macroName)
                if macroID and macroID > 0 then
                    local _, macroTexture = GetMacroInfo(macroID)
                    if macroTexture then
                        return macroTexture
                    end
                end
            end
            return CleveRoids.unknownTexture
        end

        -- *** THIS IS THE FIX ***
        -- If an action is active, return its texture directly.
        -- If no action is active, return the tooltip's texture.
        -- If neither has a texture, fall back to the macro's icon.
        local texture = (actions.active and actions.active.texture) or (actions.tooltip and actions.tooltip.texture)

        -- 性能优化：本函数是 UI 每次按钮刷新都会查询的热路径。
        -- ①规范化名（StripRank+下划线替换）结果缓存（名字集合有限，永久缓存+上限，
        --   与代码库既有 _stripRankCache/spellNameCache 同模式）；
        -- ②toggledAbilities 提升为模块级常量（原每次调用新建表，键为原大小写技能名）；
        -- ③合并下方两段重复的规范化计算；④shapeshift 循环外预计算小写名
        -- by 武藤纯子酱 2026.8.31
        local normalized = nil
        if a and a.spell and a.action then
            normalized = _actionIconNameCache[a.action]
            if not normalized then
                normalized = string.gsub(CleveRoids.StripRank(a.action), "_", " ")
                if not _actionIconNameCache._size then _actionIconNameCache._size = 0 end
                if _actionIconNameCache._size < 256 then
                    _actionIconNameCache[a.action] = normalized
                    _actionIconNameCache._size = _actionIconNameCache._size + 1
                end
            end
        end
        local normalizedLower = normalized and string.lower(normalized) or nil

        -- Check if this is a shapeshift form spell and use active texture if toggled on
        if a and a.spell and a.action then
            -- Check all shapeshift forms to see if this spell matches and is active
            for i = 1, GetNumShapeshiftForms() do
                local icon, name, isActive, isCastable = GetShapeshiftFormInfo(i)
                if name and string.lower(name) == normalizedLower and isActive and icon then
                    texture = icon
                    break
                end
            end
        end

        -- Check if this is a toggled buff ability (Prowl, Shadowmeld) and swap icon based on buff state
        -- Note: Stealth is handled above by shapeshift form logic
        if a and a.spell and a.action then
            if _toggledBuffAbilities[normalized] then
                -- Check if the buff is active
                if CleveRoids.ValidatePlayerBuff(normalized) then
                    -- Buff is active, use the active texture from auraTextures
                    local activeTexture = CleveRoids.auraTextures[normalized]
                    if activeTexture then
                        texture = activeTexture
                    end
                end
            end
        end
		
        if texture then
            return texture
        end

        -- Final fallback: get the macro's icon
        local macroName = GetActionText(slot)
        if macroName then
            local macroID = GetMacroIndexByName(macroName)
            if macroID and macroID > 0 then
                local _, macroTexture = GetMacroInfo(macroID)
                if macroTexture then
                    return macroTexture
                end
            end
        end

        -- Should never reach here
        return CleveRoids.unknownTexture

    end

    -- Not one of our macros, use the original function
    return CleveRoids.Hooks.GetActionTexture(slot)
end

-- TODO: Look into https://github.com/Stanzilla/WoWUIBugs/issues/47 if needed
CleveRoids.Hooks.GetActionCooldown = GetActionCooldown
function GetActionCooldown(slot)
    -- Guard against nil/invalid slot
    if not slot then return 0, 0, 0 end

    local actions = CleveRoids.GetAction(slot)
    -- Check for actions.active OR actions.tooltip
    if actions and (actions.active or actions.tooltip) then

        -- When no action is active (all conditionals failed) but tooltip exists from #showtooltip,
        -- don't show the tooltip's cooldown - fall back to the original function (no cooldown)
        -- This matches the icon behavior in GetActionTexture (lines 3958-3977)
        if not actions.active and not actions.explicitTooltip and actions.list and table.getn(actions.list) > 0 then
            return CleveRoids.Hooks.GetActionCooldown(slot)
        end

        -- Prioritize the active action, but fall back to the tooltip action
        local a = actions.active or actions.tooltip

        local slotId = tonumber(a.action)
        if slotId and slotId >= 1 and slotId <= 19 then
            return GetInventoryItemCooldown("player", slotId)
        end

        if a.spell then
            return GetSpellCooldown(a.spell.spellSlot, a.spell.bookType)
        elseif a.item then
            if a.item.bagID and a.item.slot then
                return GetContainerItemCooldown(a.item.bagID, a.item.slot)
            elseif a.item.inventoryID then
                return GetInventoryItemCooldown("player", a.item.inventoryID)
            end
        end

        -- DEBUG: Log when we fall through without finding spell/item data (once per slot)
        if CleveRoids.cooldownDebug and not CleveRoids.cooldownDebugLogged[slot] then
            CleveRoids.cooldownDebugLogged[slot] = true
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cffff0000[CD Issue]|r Slot %d: No cooldown data! action='%s' type=%s spell=%s item=%s",
                slot,
                tostring(a.action),
                tostring(a.type),
                tostring(a.spell ~= nil),
                tostring(a.item ~= nil)
            ))
            DEFAULT_CHAT_FRAME:AddMessage("|cffff8800[CD Issue]|r This slot will show incorrect cooldown. Report macro text to developer.")
        end

        -- Fallback to original function (preserves SuperWoW's #showtooltip handling)
        return CleveRoids.Hooks.GetActionCooldown(slot)
    else
        return CleveRoids.Hooks.GetActionCooldown(slot)
    end
end

CleveRoids.Hooks.GetActionCount = GetActionCount
function GetActionCount(slot)
    -- Guard against nil/invalid slot
    if not slot then return 0 end

    local action = CleveRoids.GetAction(slot)
    local count

    -- When no action is active (all conditionals failed), don't show tooltip's count
    if action and not action.active and not action.explicitTooltip and action.list and table.getn(action.list) > 0 then
        return CleveRoids.Hooks.GetActionCount(slot)
    end

    -- Use the same priority as GetActionTexture: active first, then tooltip
    local actionToCheck = (action and action.active) or (action and action.tooltip)
    if actionToCheck then

        local slotId = tonumber(actionToCheck.action)
        if slotId and slotId >= 1 and slotId <= 19 then
            return GetInventoryItemCount("player", slotId)
        end

        if actionToCheck.item then
            count = CleveRoids.GetLiveItemCount(actionToCheck.item.name or actionToCheck.action)

        elseif actionToCheck.spell then
            local reagent = actionToCheck.spell.reagent
            if not reagent or reagent == "" then
                reagent = nil
                local ss, bt = actionToCheck.spell.spellSlot, actionToCheck.spell.bookType
                if ss and bt then
                    local _, r = CleveRoids.GetSpellCost(ss, bt)
                    reagent = r
                end
                if (not reagent) and _ReagentBySpell and actionToCheck.spell.name then
                    reagent = _ReagentBySpell[actionToCheck.spell.name]  -- e.g., Vanish → Flash Powder
                end
                actionToCheck.spell.reagent = reagent  -- cache it so we don't re-scan every frame
            end
            if reagent and reagent ~= "" then
                count = CleveRoids.GetReagentCount(reagent)  -- id-first bag scan, falls back to name/tooltip
            end
        end
    end

    return count or CleveRoids.Hooks.GetActionCount(slot)
end

CleveRoids.Hooks.IsConsumableAction = IsConsumableAction
function IsConsumableAction(slot)
    -- Guard against nil/invalid slot
    if not slot then return nil end

    local action = CleveRoids.GetAction(slot)

    -- When no action is active (all conditionals failed), don't show tooltip's consumable status
    if action and not action.active and not action.explicitTooltip and action.list and table.getn(action.list) > 0 then
        return CleveRoids.Hooks.IsConsumableAction(slot)
    end

    -- Use the same priority as GetActionTexture: active first, then tooltip
    local actionToCheck = (action and action.active) or (action and action.tooltip)
    if actionToCheck then

        local slotId = tonumber(actionToCheck.action)
        if slotId and slotId >= 1 and slotId <= 19 then
            -- 修复：GetInventoryItemCount 只有一个返回值，原 `local _, count =` 使 count 恒为 nil by 武藤纯子酱 2026.8.31
            local count = GetInventoryItemCount("player", slotId)
            if count and count > 0 then return 1 end
        end

        if actionToCheck.item and
            (CleveRoids.countedItemTypes[actionToCheck.item.type]
            or CleveRoids.countedItemTypes[actionToCheck.item.name])
        then
            return 1
        end


        if actionToCheck.spell then
            local reagent = actionToCheck.spell.reagent
            if (not reagent or reagent == "") and actionToCheck.spell.name then
                reagent = _ReagentBySpell[actionToCheck.spell.name]
                if reagent then
                    actionToCheck.spell.reagent = reagent
                end
            end
            if reagent and reagent ~= "" then
                return 1
            end
        end
    end

    return CleveRoids.Hooks.IsConsumableAction(slot)
end

-- ============================================================================
-- 动作条页切换 hook（[actionbar:n]/[bar:n] 图标刷新）by 武藤纯子酱 2026.9.3
-- 切页后 CURRENT_ACTIONBAR_PAGE 变化，但条件图标不会自动重算，需主动刷新
-- ============================================================================
if ChangeActionBarPage then
    CleveRoids.Hooks.ChangeActionBarPage = ChangeActionBarPage
    function ChangeActionBarPage(page)
        local result = CleveRoids.Hooks.ChangeActionBarPage(page)
        if CleveRoids.ready then
            CleveRoids.QueueActionUpdate()
        end
        return result
    end
end

-- ============================================================================
-- RunMacro Hook - Use our own macro execution system
-- ============================================================================
-- This allows /stopmacro, /skipmacro, /firstaction to work across parent/child
-- macro boundaries without requiring SuperMacro addon.
--
-- When SuperMacro is installed, its RunLine hook takes precedence for extended
-- macro features. This hook handles vanilla Blizzard macros.
-- ============================================================================
if not CleveRoids.RunMacroHooked then
    CleveRoids.Hooks.RunMacro = RunMacro

    function RunMacro(indexOrName)
        -- Skip if SuperMacro is handling macro execution (it has its own hooks)
        if CleveRoids.SM_RunLineHooked then
            return CleveRoids.Hooks.RunMacro(indexOrName)
        end

        -- Resolve macro index
        local macroIndex
        if type(indexOrName) == "number" then
            macroIndex = indexOrName
        elseif type(indexOrName) == "string" then
            -- Could be a name or a numeric string
            local num = tonumber(indexOrName)
            if num then
                macroIndex = num
            else
                macroIndex = GetMacroIndexByName(indexOrName)
            end
        end

        if not macroIndex or macroIndex == 0 then
            -- Fallback to original if we can't resolve
            return CleveRoids.Hooks.RunMacro(indexOrName)
        end

        -- Get macro body
        local name, icon, body = GetMacroInfo(macroIndex)
        if not body or body == "" then
            return CleveRoids.Hooks.RunMacro(indexOrName)
        end

        -- Clear macro flags at the start of top-level macro execution
        CleveRoids.stopMacroFlag = false
        CleveRoids.skipMacroFlag = false
        -- Note: stopOnCastFlag is intentionally NOT cleared here - it persists
        -- within a frame and is cleared by OnUpdate

        if CleveRoids.macroRefDebug then
            CleveRoids.Print("|cff00ff00[RunMacro Hook]|r Executing macro '" .. (name or macroIndex) .. "' via CleveRoids")
        end

        -- Execute through our system
        CleveRoids.ExecuteMacroBody(body)

        -- Don't call original - we've handled it
        return
    end

    CleveRoids.RunMacroHooked = true
end

-- Create a hidden tooltip frame to read buff names
if not AuraScanTooltip and not CleveRoids.hasAuraSpellIds then
    CreateFrame("GameTooltip", "AuraScanTooltip")
    AuraScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    AuraScanTooltip:EnableMouse(false)
    AuraScanTooltip:AddFontStrings(
        AuraScanTooltip:CreateFontString("$parentTextLeft1", nil, "GameTooltipText"),
        AuraScanTooltip:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
    )
end

-- Robust named tooltip for scanning spells/items
if not CleveRoidsTooltipScan then
  -- Try to create with the standard template first
  local ok, _ = pcall(CreateFrame, "GameTooltip", "CleveRoidsTooltipScan", UIParent, "GameTooltipTemplate")
  if not ok or not CleveRoidsTooltipScan then
    -- Fallback: manual tooltip with plenty of prebuilt lines
    CleveRoidsTooltipScan = CreateFrame("GameTooltip", "CleveRoidsTooltipScan", UIParent)
    local L1 = CleveRoidsTooltipScan:CreateFontString("$parentTextLeft1",  nil, "GameTooltipText")
    local R1 = CleveRoidsTooltipScan:CreateFontString("$parentTextRight1", nil, "GameTooltipText")
    CleveRoidsTooltipScan:AddFontStrings(L1, R1)
    for i = 2, 32 do
      CleveRoidsTooltipScan:CreateFontString("$parentTextLeft"..i,  nil, "GameTooltipText")
      CleveRoidsTooltipScan:CreateFontString("$parentTextRight"..i, nil, "GameTooltipText")
    end
  end
  CleveRoidsTooltipScan:SetOwner(WorldFrame, "ANCHOR_NONE")
  CleveRoidsTooltipScan:EnableMouse(false)
end

-- This single dummy frame handles events AND serves as our tooltip scanner.
CleveRoids.Frame = CreateFrame("GameTooltip")
CleveRoids.Frame:EnableMouse(false)  -- Prevent tooltip from capturing mouse input

-- Create the extra font strings needed for other functions like GetSpellCost.
CleveRoids.Frame.costFontString = CleveRoids.Frame:CreateFontString()
CleveRoids.Frame.rangeFontString = CleveRoids.Frame:CreateFontString()
CleveRoids.Frame.reagentFontString = CleveRoids.Frame:CreateFontString()
CleveRoids.Frame:AddFontStrings(CleveRoids.Frame:CreateFontString(), CleveRoids.Frame:CreateFontString())
CleveRoids.Frame:AddFontStrings(CleveRoids.Frame.costFontString, CleveRoids.Frame.rangeFontString)
CleveRoids.Frame:AddFontStrings(CleveRoids.Frame:CreateFontString(), CleveRoids.Frame:CreateFontString())
CleveRoids.Frame:AddFontStrings(CleveRoids.Frame.reagentFontString, CleveRoids.Frame:CreateFontString())

CleveRoids.Frame:SetScript("OnUpdate", CleveRoids.OnUpdate)
CleveRoids.Frame:SetScript("OnEvent", function(...)
    --CleveRoids.Frame[event](this,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
    local handler = CleveRoids.Frame[event]
    -- 修复nil报错 by 武藤纯子酱 2026.7.2
    if handler then
        handler(this, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
    elseif CleveRoids.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Event Warning]|r No handler for event: " .. tostring(event))
    end
end)

-- == SHUTDOWN PROTECTION ==
-- Flag to prevent SuperWoW API calls during logout (crash prevention)
CleveRoids.isShuttingDown = false

-- == CORE EVENT REGISTRATION ==
CleveRoids.Frame:RegisterEvent("PLAYER_LOGIN")
CleveRoids.Frame:RegisterEvent("ADDON_LOADED")
CleveRoids.Frame:RegisterEvent("PLAYER_LOGOUT")
CleveRoids.Frame:RegisterEvent("PLAYER_LEAVING_WORLD")
CleveRoids.Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
CleveRoids.Frame:RegisterEvent("UPDATE_MACROS")
CleveRoids.Frame:RegisterEvent("SPELLS_CHANGED")
CleveRoids.Frame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
CleveRoids.Frame:RegisterEvent("BAG_UPDATE")
CleveRoids.Frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
CleveRoids.Frame:RegisterEvent("UNIT_PET")

-- == STATE CHANGE EVENT REGISTRATION (for performance) ==
CleveRoids.Frame:RegisterEvent("PLAYER_TARGET_CHANGED")
CleveRoids.Frame:RegisterEvent("PLAYER_FOCUS_CHANGED") -- For focus addons
CleveRoids.Frame:RegisterEvent("PLAYER_ENTER_COMBAT")  -- Auto-attack started
CleveRoids.Frame:RegisterEvent("PLAYER_LEAVE_COMBAT")  -- Auto-attack stopped
CleveRoids.Frame:RegisterEvent("PLAYER_REGEN_DISABLED") -- Entered actual combat (has threat)
CleveRoids.Frame:RegisterEvent("PLAYER_REGEN_ENABLED")  -- Left actual combat (no threat)
CleveRoids.Frame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
CleveRoids.Frame:RegisterEvent("UPDATE_SHAPESHIFT_FORMS") -- 1.12 事件名（复数）；两者都注册以兼容 by 武藤纯子酱 2026.9.11
CleveRoids.Frame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
-- Use GUID events when available (v2.39+), fall back to standard per-token events
if CleveRoids.NampowerAPI.features.hasUnitGuidEvents then
    CleveRoids.Frame:RegisterEvent("UNIT_AURA_GUID")
    CleveRoids.Frame:RegisterEvent("UNIT_HEALTH_GUID")
    CleveRoids.Frame:RegisterEvent("UNIT_MANA_GUID")
    CleveRoids.Frame:RegisterEvent("UNIT_RAGE_GUID")
    CleveRoids.Frame:RegisterEvent("UNIT_ENERGY_GUID")
else
    CleveRoids.Frame:RegisterEvent("UNIT_AURA")
    CleveRoids.Frame:RegisterEvent("UNIT_HEALTH")
    CleveRoids.Frame:RegisterEvent("UNIT_POWER")
end
-- Nampower v2.25+ spell events（替代 SuperWoW UNIT_CASTEVENT）by 武藤纯子酱 2026.9.1：
--   SPELL_START_SELF/OTHER  → spell_tracking 填充（玩家 + 其他施法者）
--   SPELL_GO_SELF/OTHER     → 施法完成（[delay]/[unitdelay] 时钟 + spell_tracking 清理）
--   SPELL_FAILED_SELF/OTHER → 施法失败清理
if CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.features and CleveRoids.NampowerAPI.features.hasSpellStartEvents then
    CleveRoids.Frame:RegisterEvent("SPELL_START_SELF")
    CleveRoids.Frame:RegisterEvent("SPELL_START_OTHER")
    CleveRoids.Frame:RegisterEvent("SPELL_FAILED_SELF")
    CleveRoids.Frame:RegisterEvent("SPELL_FAILED_OTHER")
end
if CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.features and CleveRoids.NampowerAPI.features.hasSpellGoEvents then
    CleveRoids.Frame:RegisterEvent("SPELL_GO_SELF")
    CleveRoids.Frame:RegisterEvent("SPELL_GO_OTHER")
end
if QueueSpellByName then
    CleveRoids.Frame:RegisterEvent("SPELL_QUEUE_EVENT")
    CleveRoids.Frame:RegisterEvent("SPELL_CAST_EVENT")
end
CleveRoids.Frame:RegisterEvent("START_AUTOREPEAT_SPELL")
CleveRoids.Frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")
CleveRoids.Frame:RegisterEvent("SPELLCAST_CHANNEL_START")
CleveRoids.Frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
CleveRoids.Frame:RegisterEvent("SPELLCAST_START")
CleveRoids.Frame:RegisterEvent("SPELLCAST_STOP")
CleveRoids.Frame:RegisterEvent("SPELLCAST_FAILED")
CleveRoids.Frame:RegisterEvent("SPELLCAST_INTERRUPTED")

-- Nampower SPELL_CAST_EVENT for reliable channel tracking + cast sequence + spell_tracking
if GetCurrentCastingInfo then
    CleveRoids.Frame:RegisterEvent("SPELL_CAST_EVENT")
end

-- Nampower v2.25+ spell events for spell_tracking and cast sequence
-- （SPELL_START_SELF / SPELL_START_OTHER / SPELL_FAILED_SELF / SPELL_FAILED_OTHER 已在上方注册）

-- Nampower v2.41+: keyboard input events for [keydown:X] conditional
if CleveRoids.NampowerAPI.features.hasKeyEvents then
    CleveRoids.Frame:RegisterEvent("KEY_DOWN")
    CleveRoids.Frame:RegisterEvent("KEY_UP")
end

CleveRoids.Frame:RegisterEvent("CHAT_MSG_ADDON") -- 新增 by 武藤纯子酱 2026.8.10

-- NOTE: SuperMacro hook installation is handled by Compatibility/SuperMacro.lua
-- which has the complete implementation including the INTERCEPT path for all commands

function CleveRoids.Frame:UNIT_PET()
    if arg1 == "player" then
        CleveRoids.IndexPetSpells()
        if CleveRoidMacros.realtime == 0 then
            CleveRoids.QueueActionUpdate()
        end
    end
end

-- Handle shutdown to prevent SuperWoW API crashes during logout
function CleveRoids.Frame:PLAYER_LOGOUT()
    CleveRoids.isShuttingDown = true
    this:UnregisterAllEvents()
    this:SetScript("OnUpdate", nil)
    this:SetScript("OnEvent", nil)
    -- Disarm UnitXP timers (they run in a separate thread and survive /reload)
    if CleveRoids.hasUnitXP then
        if CleveRoids._cleanupTimerId then
            pcall(UnitXP, "timer", "disarm", CleveRoids._cleanupTimerId)
        end
        if CleveRoids._auraCleanupTimerId then
            pcall(UnitXP, "timer", "disarm", CleveRoids._auraCleanupTimerId)
        end
    end
    -- Clear spell caches to prevent stale data
    if CleveRoids.spellIdCache then
        for k in pairs(CleveRoids.spellIdCache) do
            CleveRoids.spellIdCache[k] = nil
        end
    end
end

function CleveRoids.Frame:PLAYER_LEAVING_WORLD()
    -- FIX: Only set loading flag, don't unregister events
    -- PLAYER_LEAVING_WORLD fires for both logout AND zone transitions
    -- We need to stay alive for zone transitions; PLAYER_LOGOUT handles actual logout
    CleveRoids.isLoading = true

    -- 队列感知：换图/离线会静默丢弃 Nampower 队列，清理瞬态施法/队列状态防卡死 by 武藤纯子酱 2026.8.31
    CleveRoids.queuedSpell = nil
    CleveRoids._pendingMouseUse = nil
    CleveRoids._pendingCastAOE = nil
    CleveRoids._pendingCursorRestore = nil
    if CleveRoids.CurrentSpell then
        CleveRoids.CurrentSpell.type = ""
        CleveRoids.CurrentSpell.spellName = ""
        CleveRoids.CurrentSpell.castingSpellId = nil
    end
    CleveRoids.channelStartTime = 0
    CleveRoids.channelDuration = 0
    if CleveRoids.spell_tracking then
        for k in pairs(CleveRoids.spell_tracking) do
            CleveRoids.spell_tracking[k] = nil
        end
    end
end

-- FIX: Handle zone transitions (instance entry, etc.)
-- Refresh action button state after loading screen completes
function CleveRoids.Frame:PLAYER_ENTERING_WORLD()
    CleveRoids.isLoading = false

    -- Skip if not yet initialized
    if not CleveRoids.ready then return end

    -- Refresh all action states after zone transition
    CleveRoids.TestForAllActiveActions()

    -- FIX: Force Blizzard buttons to re-query IsUsableAction
    -- Loading screen causes UI rebuild which can cache stale button states
    -- SKIP for pfUI users - pfUI handles its own button updates
    if not (pfUI and pfUI.bars) then
        for slot = 1, 120 do
            if CleveRoids.Actions[slot] then
                CleveRoids.SendEventForAction(slot, "ACTIONBAR_SLOT_CHANGED", slot)
            end
        end
    end
    -- Clear spell caches to prevent stale data
    if CleveRoids.spellIdCache then
        for k in pairs(CleveRoids.spellIdCache) do
            CleveRoids.spellIdCache[k] = nil
        end
    end
end

-- Simplified PLAYER_LOGIN - requirements already checked
function CleveRoids.Frame:PLAYER_LOGIN()
    -- Skip if already disabled
    if CleveRoids.disabled then return end

    _, CleveRoids.playerClass = UnitClass("player")
    _, CleveRoids.playerGuid = UnitExists("player")
    -- 兼容：部分环境 UnitExists 只返回 1 个值（不返回 GUID），回退用 GetGUID 取，避免 playerGuid 恒为 nil by 武藤纯子酱 2026.9.11
    if not CleveRoids.playerGuid and CleveRoids.GetGUID then
        CleveRoids.playerGuid = CleveRoids.GetGUID("player")
    end
    CleveRoids.IndexSpells()
    CleveRoids.IndexPetSpells()
    CleveRoids.initializationTimer = GetTime() + 1.5

    -- PERFORMANCE: Initialize event-driven cache states
    CleveRoids._cachedPlayerInCombat = UnitAffectingCombat("player") and true or false
	
    -- Schedule delayed WDB warmup (loads items into client cache via tooltip scan)
    -- This ensures GetItemInfo() works for all inventory items after a WDB clear
    CleveRoids.wdbWarmupTime = GetTime() + 3.0  -- 3 second delay after login
	CleveRoids.GetAllButtons() -- 新增 给全部动作条按钮添加鼠标按键识别 by 武藤纯子酱 2025.11.27	
end

-- PERFORMANCE: WDB warmup - tooltip scan all bag items to ensure they're cached
-- This prevents GetItemInfo() returning nil for items after a WDB clear
function CleveRoids.DoWDBWarmup()
    if CleveRoids.wdbWarmupDone then return end
    CleveRoids.wdbWarmupDone = true

    -- Create a hidden tooltip for scanning if it doesn't exist
    local tip = CleveRoidsWDBTip
    if not tip then
        tip = CreateFrame("GameTooltip", "CleveRoidsWDBTip", UIParent, "GameTooltipTemplate")
        tip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end

    local scanned = 0

    -- Scan all bag slots
    for bag = 0, 4 do
        local slots = GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                -- Tooltip scan loads the item into WDB
                tip:ClearLines()
                tip:SetBagItem(bag, slot)
                scanned = scanned + 1
            end
        end
    end

    -- Scan equipped items
    for slot = 0, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            tip:ClearLines()
            tip:SetInventoryItem("player", slot)
            scanned = scanned + 1
        end
    end

    -- Now trigger a full item index to populate the cache with valid data
    if CleveRoids.IndexItems then
        CleveRoids.IndexItems()
    end

    if CleveRoids.debug then
        CleveRoids.Print("|cff88ff88[WDB Warmup]|r Scanned " .. scanned .. " items into cache")
    end
end

function CleveRoids.Frame:ADDON_LOADED(addon)
    -- keep your existing init for CRM:
    if addon == "CleveRoidMacros" or addon == "SuperCleveRoidMacros" then
        CleveRoids.InitializeExtensions()
    end
    -- NOTE: SuperMacro hook installation is handled by Compatibility/SuperMacro.lua
end

-- ============================================================================
-- Nampower 施法事件处理器组（完整替代 SuperWoW UNIT_CASTEVENT）by 武藤纯子酱 2026.9.1
-- 事件参数依据 Nampower EVENTS.md：
--   SPELL_START_*     : itemId, spellId, casterGuid, targetGuid, castFlags, castTimeMs, durationMs, spellType
--   SPELL_GO_*        : itemId, spellId, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed
--   SPELL_FAILED_OTHER: casterGuid, spellId
-- ============================================================================

-- 性能优化：SpellTarget 清理由「每次施法 O(n)」改为按插件刷新设置节流（/cleveroid refresh＝
-- 1-10 次/秒，间隔 0.1-1.0s）；realtime 模式间隔为 0＝不节流（按事件/按帧处理）。条目仅用于
-- [delay]/[unitdelay] 目标匹配，陈旧条目最多滞留一个刷新周期，准确性几乎无损 by 武藤纯子酱 2026.9.11
function CleveRoids.PruneSpellTargets()
    local interval = CleveRoids.GetRefreshInterval()
    local now = GetTime()
    if interval > 0 and CleveRoids._spellTargetPruneTime and (now - CleveRoids._spellTargetPruneTime) < interval then return end
    CleveRoids._spellTargetPruneTime = now
    for guid, _ in pairs(CleveRoids.SpellTarget) do
        if not UnitExists(guid) or UnitIsDeadOrGhost(guid) then
            CleveRoids.SpellTarget[guid] = nil
        end
    end
end

-- SPELL_GO_SELF：玩家施法完成（瞬发出手 / 读条结束）
-- 迁移自 UNIT_CASTEVENT 的 CAST 完成时刻记录（[delay]/[unitdelay] 施法时钟 + spell_tracking 清理）by 武藤纯子酱 2026.9.1
function CleveRoids.Frame:SPELL_GO_SELF(itemId, spellId, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed, ...)
    if not spellId then return end

    local playerGuid = CleveRoids.playerGuid or CleveRoids.GetGUID("player")
    if casterGuid ~= playerGuid then return end

    -- spell_tracking 清理（等价 UNIT_CASTEVENT CAST：读条结束/瞬发出手即清除）
    local cast = CleveRoids.spell_tracking[playerGuid]
    if cast and (cast.spell_id == spellId or GetTime() > cast.expires) then
        CleveRoids.spell_tracking[playerGuid] = nil
        CleveRoids.spell_tracking["player"] = nil
    end

    -- [delay]/[unitdelay] 施法时钟：施法完成（出手）时刻 by 武藤纯子酱 2025.8.25
    local spellName = GetSpellRecField(spellId, "name")
    if spellName then
        CleveRoids.SpellCastTimes[spellName] = GetTime()

        -- 清理不存在的目标（节流 ~1s）
        CleveRoids.PruneSpellTargets()

        -- 更新目标技能记录
        if targetGuid and targetGuid ~= "0x0000000000000000" then
            local targetTable = CleveRoids.SpellTarget[targetGuid] or {}
            targetTable[spellName] = GetTime()
            CleveRoids.SpellTarget[targetGuid] = targetTable
        end
    end

    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

-- SPELL_START_OTHER：其他施法者开始读条/引导 → spell_tracking 填充（[casttime]/[nocasttime] 数据源）
function CleveRoids.Frame:SPELL_START_OTHER(itemId, spellId, casterGuid, targetGuid, castFlags, castTimeMs, durationMs, spellType, ...)
    if not spellId or not casterGuid then return end

    local playerGuid = CleveRoids.playerGuid or CleveRoids.GetGUID("player")
    if casterGuid == playerGuid then return end  -- 玩家自身由 SPELL_START_SELF 处理

    -- 等价 UNIT_CASTEVENT START/CHANNEL：引导法术时长在 durationMs（castTimeMs 对引导通常为 0）by 武藤纯子酱 2026.9.1
    local isChannel = (spellType == 1)
    local effectiveMs = isChannel and durationMs or castTimeMs

    if effectiveMs and effectiveMs > 0 then
        CleveRoids.spell_tracking[casterGuid] = {
            -- 修复：变量名拼写错误（原 spell_id，此作用域不存在 → 恒 nil），
            -- 导致他人施法的 spell_id/school 全为 nil、SPELL_FAILED_OTHER 无法清理
            -- by 武藤纯子酱 2026.9.11
            spell_id = spellId,
            expires = GetTime() + effectiveMs / 1000,
            type = isChannel and "CHANNEL" or "START",
            target = (targetGuid and targetGuid ~= "0x0000000000000000") and targetGuid or nil,
            start = GetTime(),
            school = CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetSpellSchool and CleveRoids.NampowerAPI.GetSpellSchool(spellId) or nil,
        }
    end

    -- 方案A（性能优化）：非玩家施法加 0.1s 节流（图标缓存规则允许 ≤0.1s 延迟）
    -- by 武藤纯子酱 2026.8.31
    local nowCast = GetTime()
    if (nowCast - (CleveRoids._npcCastQueueTime or 0)) >= 0.1 then
        CleveRoids._npcCastQueueTime = nowCast
        if CleveRoidMacros.realtime == 0 then
            CleveRoids.QueueActionUpdate()
        end
    end
end

-- SPELL_GO_OTHER：其他施法者施法完成 → 清理其 spell_tracking
function CleveRoids.Frame:SPELL_GO_OTHER(itemId, spellId, casterGuid, targetGuid, ...)
    if not casterGuid then return end

    local playerGuid = CleveRoids.playerGuid or CleveRoids.GetGUID("player")
    if casterGuid == playerGuid then return end

    local cast = CleveRoids.spell_tracking[casterGuid]
    if cast and (not spellId or cast.spell_id == spellId or GetTime() > cast.expires) then
        CleveRoids.spell_tracking[casterGuid] = nil
    end
end

-- SPELL_FAILED_OTHER：其他施法者施法失败/被打断 → 清理其 spell_tracking
function CleveRoids.Frame:SPELL_FAILED_OTHER(casterGuid, spellId, ...)
    if not casterGuid then return end

    local playerGuid = CleveRoids.playerGuid or CleveRoids.GetGUID("player")
    if casterGuid == playerGuid then return end

    local cast = CleveRoids.spell_tracking[casterGuid]
    if cast and (not spellId or cast.spell_id == spellId) then
        CleveRoids.spell_tracking[casterGuid] = nil
    end
end

-- 整合原来的两个CleveRoids.Frame:SPELL_CAST_EVENT函数 by 武藤纯子酱 2026.7.2
function CleveRoids.Frame:SPELL_CAST_EVENT(success, spellId, castType, targetGuid, itemId)
    -- ========================================================================
    -- 第一部分：原第二个定义（更新施法状态、pendingCasts、连击点捕获）
    -- ========================================================================

    -- 更新全局施法状态（供 [casting] 条件使用）
    if CleveRoids.UpdateCastingState then
        CleveRoids.UpdateCastingState()
    end

    if success == 1 then
        -- 施法成功发起即消费抵抗状态：抵抗补刀分支发起补读条后，
        -- resisted 条件立即失效，防止飞行期间被再次命中而连发 by 武藤纯子酱 2026.8.31
        CleveRoids.ClearResistState()

        -- 记录本次成功施法信息
        CleveRoids.lastCastSpell = {
            spellId = spellId,
            castType = castType,
            targetGuid = targetGuid,
            timestamp = GetTime()
        }
        if GetSpellRecField then
            local name = GetSpellRecField(spellId, "name")
            if name then
                CleveRoids.lastCastSpell.spellName = name
                -- 结果确认门（挂起点②）：Nampower SPELL_CAST_EVENT success=1 施法出手，
                -- 与 SPELL_GO_SELF 完成路径互为冗余（键相同自然去重）by 武藤纯子酱 2026.8.31
                if name ~= "" and targetGuid and CleveRoids.ArmCastOutcome then
                    CleveRoids.ArmCastOutcome(name, targetGuid)
                end
            end
        end

        -- 清理过期 pendingCasts 条目
        CleveRoids.pendingCasts = CleveRoids.pendingCasts or {}
        local cleanupTime = GetTime() - 5
        for id, entry in pairs(CleveRoids.pendingCasts) do
            if entry.consumed and entry.consumedAt and entry.consumedAt < cleanupTime then
                CleveRoids.pendingCasts[id] = nil
            end
        end

        -- 创建当前施法的 pending 记录（供 SPELL_GO 关联）
        CleveRoids.pendingCasts[spellId] = {
            castType = castType,
            targetGuid = targetGuid,
            timestamp = GetTime(),
            comboPoints = nil,
        }

        -- 捕获连击点（仅对组合技能）
        if (CleveRoids.IsComboScalingSpellID and CleveRoids.IsComboScalingSpellID(spellId)) or
           (CleveRoids.FerociousBiteSpellIDs and CleveRoids.FerociousBiteSpellIDs[spellId]) then
            local cp = CleveRoids.GetComboPoints and CleveRoids.GetComboPoints() or 0
            if cp > 0 then
                CleveRoids.pendingCasts[spellId].comboPoints = cp
                if CleveRoids.debug then
                    local castSpellName = GetSpellRecField and GetSpellRecField(spellId, "name") or "Unknown"
                    DEFAULT_CHAT_FRAME:AddMessage(
                        string.format("|cff00ff88[SPELL_CAST_EVENT]|r Captured %d CP for %s (ID:%d)",
                            cp, castSpellName, spellId)
                    )
                end
            end
        end
    else
        -- 施法失败 → 清除 pending 记录
        if CleveRoids.pendingCasts then
            CleveRoids.pendingCasts[spellId] = nil
        end
    end

    -- ========================================================================
    -- 第二部分：原第一个定义（通道追踪、spell_tracking 清理、castsequence 支持）
    -- ========================================================================

    -- 修复：按 EVENTS.md，SPELL_CAST_EVENT 的 castType 中 CHANNEL=3（4 是 TARGETING） by 武藤纯子酱 2026.8.31
    local CHANNEL = 3
    if castType == CHANNEL and success == 1 then
        -- 通道法术成功开始
        CleveRoids.CurrentSpell.type = "channeled"
        CleveRoids.CurrentSpell.castingSpellId = spellId

        local spellName = GetSpellRecField and GetSpellRecField(spellId, "name")
        if spellName then
            CleveRoids.CurrentSpell.spellName = spellName
        end

        -- 性能优化：直调改排队（见 SPELLCAST_CHANNEL_START 同注释） by 武藤纯子酱 2026.8.31
        CleveRoids.QueueActionUpdate()
    end

    -- Nampower 路径：负责 spell_tracking 的出手清理和 castsequence 推进 by 武藤纯子酱 2026.9.1
    if spellId then
        local playerGuid = CleveRoids.playerGuid or CleveRoids.GetGUID("player")

        -- 无论成功还是失败，清理 spell_tracking 中的当前施法记录
        if success == 1 or success == 0 then
            local cast = CleveRoids.spell_tracking[playerGuid]
            if cast and cast.spell_id == spellId then
                CleveRoids.spell_tracking[playerGuid] = nil
                CleveRoids.spell_tracking["player"] = nil
            end
        end

        -- castsequence：成功施法后推进到下一步
        -- 修复：仅在尚未由 SPELL_START_SELF（读条/引导开始时已推进并置 status=1）推进过时才推进，
        -- 避免同一发施法被两个事件各推进一次（相邻同名步骤会双跳）by 武藤纯子酱 2026.9.11
        if CleveRoids.currentSequence and success == 1 and CleveRoids.currentSequence.status == 0 then
            local active = CleveRoids.GetCurrentSequenceAction(CleveRoids.currentSequence)
            if active and active.action then
                local name = GetSpellRecField(spellId, "name")
                local rank = GetSpellRecField(spellId, "rank")
                local nameRank = (rank and rank ~= "") and (name .. "(" .. rank .. ")") or nil
                local isSeqSpell = (active.action == name or (nameRank and active.action == nameRank))

                if isSeqSpell then
                    CleveRoids.currentSequence.status = 2
                    CleveRoids.currentSequence.lastUpdate = GetTime()
                    CleveRoids.AdvanceSequence(CleveRoids.currentSequence)
                    CleveRoids.currentSequence = nil
                end
            end
        end

        -- castsequence：失败时重置状态以允许重试
        if CleveRoids.currentSequence and success == 0 then
            local active = CleveRoids.GetCurrentSequenceAction(CleveRoids.currentSequence)
            if active and active.action then
                local name = GetSpellRecField(spellId, "name")
                local isSeqSpell = (active.action == name)
                if isSeqSpell then
                    CleveRoids.currentSequence.status = 1  -- 重置为可重试
                end
            end
        end

        -- 仅在事件驱动模式下触发动作栏更新
        if CleveRoidMacros.realtime == 0 then
            CleveRoids.QueueActionUpdate()
        end
    end
end

-- Nampower SPELL_START_SELF handler (v2.25+)
-- Handles spell_tracking population and cast sequence START detection (primary path for player casting)
-- 修复事件参数顺序：按 EVENTS.md，SPELL_START_SELF 载荷为 (itemId, spellId, casterGuid, targetGuid, castFlags, castTime, duration, spellType, ...) by 武藤纯子酱 2026.8.31
function CleveRoids.Frame:SPELL_START_SELF(itemId, spellId, casterGuid, targetGuid, castFlags, castTimeMs, durationMs, spellType, ...)
    -- 施法开始即消费抵抗状态/响应法术 proc by 武藤纯子酱 2026.8.31
    if spellId then
        local castName = GetSpellRecField and GetSpellRecField(spellId, "name")
        CleveRoids.ClearReactiveProcOnCast(castName or spellId)
    end
    CleveRoids.ClearResistState()

    if not spellId then return end

    local playerGuid = CleveRoids.playerGuid or CleveRoids.GetGUID("player")
    if casterGuid ~= playerGuid then return end

    -- Populate spell_tracking (equivalent to UNIT_CASTEVENT START/CHANNEL)
    -- 修复：按 EVENTS.md，引导法术的时长在第 7 参 durationMs（第 6 参 castTime 对引导通常为 0），
    -- 原来用 castTimeMs 判断/计时会导致引导法术完全不被 spell_tracking 跟踪 by 武藤纯子酱 2026.8.31
    local isChannel = (spellType == 1)
    local action = isChannel and "CHANNEL" or "START"
    local effectiveMs = isChannel and durationMs or castTimeMs

    if effectiveMs and effectiveMs > 0 then
        CleveRoids.spell_tracking[casterGuid] = {
            spell_id = spellId,
            expires = GetTime() + effectiveMs / 1000,
            type = action,
            -- 增加 start/target/school：[casttime:start] 模式与技能匹配需要（对齐原 UNIT_CASTEVENT 字段）by 武藤纯子酱 2026.9.1
            start = GetTime(),
            target = (targetGuid and targetGuid ~= "0x0000000000000000") and targetGuid or nil,
            school = CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetSpellSchool and CleveRoids.NampowerAPI.GetSpellSchool(spellId) or nil,
        }
        CleveRoids.spell_tracking["player"] = CleveRoids.spell_tracking[casterGuid]

        -- Channel duration capture (equivalent to UNIT_CASTEVENT CHANNEL)
        if isChannel then
            CleveRoids.channelStartTime = GetTime()
            local tooltipDuration = CleveRoids.GetChannelDurationFromTooltipByID(spellId)
            if tooltipDuration then
                CleveRoids.channelDuration = tooltipDuration
            else
                CleveRoids.channelDuration = effectiveMs / 1000
            end
        else
            -- Cast duration capture (equivalent to UNIT_CASTEVENT START)
            CleveRoids.castStartTime = GetTime()
            CleveRoids.castDuration = effectiveMs / 1000
        end

        -- [delay]/[unitdelay] 施法时钟：迁移自 UNIT_CASTEVENT START/CHANNEL 路径 by 武藤纯子酱 2026.9.1
        -- （完成时刻 = 开始时刻 + 时长；瞬发出手的完成时刻由 SPELL_GO_SELF 记录）
        local spellName = GetSpellRecField(spellId, "name")
        if spellName then
            if isChannel then
                CleveRoids.SpellCastTimes[spellName] = GetTime() + (CleveRoids.channelDuration or effectiveMs / 1000)
            else
                CleveRoids.SpellCastTimes[spellName] = GetTime() + effectiveMs / 1000
            end

            -- 清理不存在的目标 + 更新目标技能记录（节流 ~1s）
            CleveRoids.PruneSpellTargets()
            if targetGuid and targetGuid ~= "0x0000000000000000" then
                local targetTable = CleveRoids.SpellTarget[targetGuid] or {}
                targetTable[spellName] = CleveRoids.SpellCastTimes[spellName]
                CleveRoids.SpellTarget[targetGuid] = targetTable
            end
        end
    end

    -- Cast sequence: set status=1 (casting) for cast-time/channel spells
    if CleveRoids.currentSequence and effectiveMs and effectiveMs > 0 then
        local active = CleveRoids.GetCurrentSequenceAction(CleveRoids.currentSequence)
        if active and active.action then
            local name = GetSpellRecField(spellId, "name")
            local rank = GetSpellRecField(spellId, "rank")
            local nameRank = (rank and rank ~= "") and (name .. "(" .. rank .. ")") or nil
            local isSeqSpell = (active.action == name or (nameRank and active.action == nameRank))

            if isSeqSpell and CleveRoids.currentSequence.status == 0 then
                CleveRoids.currentSequence.status = 1
                CleveRoids.currentSequence.expires = GetTime() + (effectiveMs / 1000) - 2
                CleveRoids.AdvanceSequence(CleveRoids.currentSequence) -- 修复引导法术在/castsequence中无法更新队列的BUG by 武藤纯子酱 2026.1.21
            end
        end
    end

    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

-- Nampower SPELL_FAILED_SELF handler (v2.25+)
-- Clears spell_tracking on failure
-- 修复事件参数顺序：按 EVENTS.md，SPELL_FAILED_SELF 载荷为 (spellId, spellResult, failedByServer) by 武藤纯子酱 2026.8.31
function CleveRoids.Frame:SPELL_FAILED_SELF(spellId, spellResult, failedByServer, ...)
    if not spellId then return end

    local playerGuid = CleveRoids.playerGuid or CleveRoids.GetGUID("player")

    -- Clear spell_tracking
    local cast = CleveRoids.spell_tracking[playerGuid]
    if cast and cast.spell_id == spellId then
        CleveRoids.spell_tracking[playerGuid] = nil
        CleveRoids.spell_tracking["player"] = nil
    end

    -- [delay] 施法时钟清理（迁移自 UNIT_CASTEVENT INTERRUPTED/FAILED 路径）by 武藤纯子酱 2026.9.1
    local spellName = GetSpellRecField and GetSpellRecField(spellId, "name")
    if spellName then
        CleveRoids.SpellCastTimes[spellName] = nil
    end

    -- Cast sequence failure handling
    if CleveRoids.currentSequence then
        local active = CleveRoids.GetCurrentSequenceAction(CleveRoids.currentSequence)
        if active and active.action then
            local name = GetSpellRecField(spellId, "name")
            local isSeqSpell = name and (active.action == name)
            if isSeqSpell then
                CleveRoids.currentSequence.status = 1  -- Reset to retry
            end
        end
    end

    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:SPELLCAST_CHANNEL_START(durationMs)
    -- Set channel state immediately when event fires
    -- Duration is captured by SPELL_START_SELF which fires earlier
    CleveRoids.CurrentSpell.type = "channeled"

    -- 兜底：若 SPELL_START_SELF 的引导分支未写入起点（或起点被重置为 0），在此补上，
    -- 避免 channelStartTime==0 被 Lua 的 0 真值蒙混过关、被误判成“引导已结束” by 武藤纯子酱 2026.9.12
    if (CleveRoids.channelStartTime or 0) <= 0 then
        CleveRoids.channelStartTime = GetTime()
    end

    -- Try to get spell info - prefer GetCastInfo (Nampower 2.18+) for better data
    local spellId = nil
    if GetCastInfo then
        local ok, info = pcall(GetCastInfo)
        if ok and info and info.spellId and info.spellId > 0 then
            spellId = info.spellId
            -- Also capture timing data
            CleveRoids.CurrentSpell.castRemainingMs = info.castRemainingMs
            CleveRoids.CurrentSpell.castEndTime = info.castEndS
        end
    end
    -- Fallback to GetCurrentCastingInfo for older Nampower
    if not spellId and GetCurrentCastingInfo then
        local _, visId = GetCurrentCastingInfo()
        if visId and visId > 0 then
            spellId = visId
        end
    end
    -- Update spell info
    if spellId then
        CleveRoids.CurrentSpell.castingSpellId = spellId
        local spellName = GetSpellRecField(spellId, "name")
        if spellName then
            CleveRoids.CurrentSpell.spellName = spellName
        end
    end

    -- v2.38+: Override channelDuration with the accurate server-provided value stored by
    -- SPELL_START_SELF (which fires before this event).  This beats the tooltip scan or
    -- SPELL_START_SELF duration, because the server already applied all modifiers.
    if CleveRoids._v238ChannelDuration then
        if not spellId or not CleveRoids._v238ChannelSpellId
            or CleveRoids._v238ChannelSpellId == spellId then
            CleveRoids.channelDuration = CleveRoids._v238ChannelDuration
        end
        CleveRoids._v238ChannelDuration = nil
        CleveRoids._v238ChannelSpellId  = nil
    end

    -- 性能优化：事件直调 TestForAllActiveActions 会同步全量重算动作条所有宏（6 处同类），
    -- 改为排队由 OnUpdate tick 处理（realtime=1 时 ≤0.1s 后刷新，图标允许 ≤0.1s 延迟）by 武藤纯子酱 2026.8.31
    CleveRoids.QueueActionUpdate()
end

function CleveRoids.Frame:SPELLCAST_CHANNEL_STOP()
    -- Channel ended - clear state immediately
    CleveRoids.CurrentSpell.type = ""
    CleveRoids.CurrentSpell.spellName = ""
    CleveRoids.CurrentSpell.castingSpellId = nil

    -- WARLOCK DARK HARVEST: Mark channeling as ended
    -- Credits: Avitasia / Cursive addon
    if CleveRoids.darkHarvestData and CleveRoids.darkHarvestData.isActive then
        CleveRoids.darkHarvestData.isActive = false
        CleveRoids.darkHarvestData.endTime = GetTime()

        -- Apply Dark Harvest end to all DoTs on target (finalizes reduction)
        if CleveRoids.libdebuff and CleveRoids.libdebuff.ApplyDarkHarvestEnd then
            CleveRoids.libdebuff.ApplyDarkHarvestEnd(CleveRoids.darkHarvestData.targetGUID)
        end

        if CleveRoids.debug then
            local activeTime = CleveRoids.darkHarvestData.endTime - CleveRoids.darkHarvestData.startTime
            DEFAULT_CHAT_FRAME:AddMessage(
                string.format("|cff9482c9[Dark Harvest]|r Channel ended after %.1fs (DoT acceleration stopped)",
                    activeTime)
            )
        end
    end

    -- 性能优化：直调改排队（见 SPELLCAST_CHANNEL_START 同注释） by 武藤纯子酱 2026.8.31
    CleveRoids.QueueActionUpdate()
end

function CleveRoids.Frame:SPELLCAST_START()
    -- Cast-time spell started
    -- Duration is captured by SPELL_START_SELF which fires earlier
    CleveRoids.CurrentSpell.type = "cast"

    -- Try to get spell info - prefer GetCastInfo (Nampower 2.18+) for better data
    local spellId = nil
    if GetCastInfo then
        local ok, info = pcall(GetCastInfo)
        if ok and info and info.spellId and info.spellId > 0 then
            spellId = info.spellId
            -- Also capture timing data
            CleveRoids.CurrentSpell.castRemainingMs = info.castRemainingMs
            CleveRoids.CurrentSpell.castEndTime = info.castEndS
            CleveRoids.CurrentSpell.gcdRemainingMs = info.gcdRemainingMs
            CleveRoids.CurrentSpell.gcdEndTime = info.gcdEndS
        end
    end
    -- Fallback to GetCurrentCastingInfo for older Nampower
    if not spellId and GetCurrentCastingInfo then
        local castId = GetCurrentCastingInfo()
        if castId and castId > 0 then
            spellId = castId
        end
    end
    -- Update spell info
    if spellId then
        CleveRoids.CurrentSpell.castingSpellId = spellId
        local spellName = GetSpellRecField(spellId, "name")
        if spellName then
            CleveRoids.CurrentSpell.spellName = spellName
        end
    end

    -- 性能优化：直调改排队（见 SPELLCAST_CHANNEL_START 同注释） by 武藤纯子酱 2026.8.31
    CleveRoids.QueueActionUpdate()
end

function CleveRoids.Frame:SPELLCAST_STOP()
    -- Cast finished - clear state immediately
    if CleveRoids.CurrentSpell.type == "cast" then
        CleveRoids.CurrentSpell.type = ""
        CleveRoids.CurrentSpell.spellName = ""
        CleveRoids.CurrentSpell.castingSpellId = nil

        -- 性能优化：直调改排队（见 SPELLCAST_CHANNEL_START 同注释） by 武藤纯子酱 2026.8.31
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:SPELLCAST_FAILED()
    -- Cast failed - clear state immediately
    if CleveRoids.CurrentSpell.type == "cast" then
        CleveRoids.CurrentSpell.type = ""
        CleveRoids.CurrentSpell.spellName = ""
        CleveRoids.CurrentSpell.castingSpellId = nil

        -- 性能优化：直调改排队（见 SPELLCAST_CHANNEL_START 同注释） by 武藤纯子酱 2026.8.31
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:SPELLCAST_INTERRUPTED()
    -- Cast interrupted - clear state immediately
    if CleveRoids.CurrentSpell.type == "cast" then
        CleveRoids.CurrentSpell.type = ""
        CleveRoids.CurrentSpell.spellName = ""
        CleveRoids.CurrentSpell.castingSpellId = nil

        -- 性能优化：直调改排队（见 SPELLCAST_CHANNEL_START 同注释） by 武藤纯子酱 2026.8.31
        CleveRoids.QueueActionUpdate()
    end
end

-- PLAYER_ENTER_COMBAT/PLAYER_LEAVE_COMBAT are for AUTO-ATTACK state (not actual combat)
function CleveRoids.Frame:PLAYER_ENTER_COMBAT()
    CleveRoids.CurrentSpell.autoAttack = true
    CleveRoids.CurrentSpell.autoAttackLock = false
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:PLAYER_LEAVE_COMBAT()
    CleveRoids.CurrentSpell.autoAttack = false
    CleveRoids.CurrentSpell.autoAttackLock = false

    -- Full item re-index after combat to refresh any items/bags that were skipped
    -- during combat for performance. Use a slight delay to avoid spam.
    local now = GetTime()
    if (now - (CleveRoids.lastItemIndexTime or 0)) > 0.5 then
        CleveRoids.lastItemIndexTime = now
        -- 性能优化：脱战只需要补齐战斗中跳过的背包/装备索引（IndexItems 内含 relink），
        -- 动作条布局未变，不再全量清空 + IndexActionBars（120×tooltip SetAction）by 武藤纯子酱 2026.8.31
        CleveRoids.IndexItems()
        if CleveRoidMacros.realtime == 0 then
            CleveRoids.QueueActionUpdate()
        end
    end

    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

-- PLAYER_REGEN_DISABLED/PLAYER_REGEN_ENABLED are for ACTUAL combat state (threat/aggro)
-- These events track what UnitAffectingCombat("player") reports
function CleveRoids.Frame:PLAYER_REGEN_DISABLED()
    -- PERFORMANCE: Cache actual combat state for event-driven [combat]/[nocombat] conditionals
    CleveRoids._cachedPlayerInCombat = true
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:PLAYER_REGEN_ENABLED()
    -- 退出战斗时清除上一次施法记录 by 武藤纯子酱 2026.5.15
    CleveRoids.lastSpellID = nil

    -- PERFORMANCE: Cache actual combat state for event-driven [combat]/[nocombat] conditionals
    CleveRoids._cachedPlayerInCombat = false

    -- Reset any sequence with reset=combat that has progressed past the first step
    -- Uses PLAYER_REGEN_ENABLED (actual combat ends) instead of PLAYER_LEAVE_COMBAT (auto-attack stops)
    for _, sequence in pairs(CleveRoids.Sequences) do
        if sequence.index > 1 and sequence.reset and sequence.reset.combat then
            CleveRoids.ResetSequence(sequence)
        end
    end

    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:PLAYER_TARGET_CHANGED()
    CleveRoids.CurrentSpell.autoAttack = false
    CleveRoids.CurrentSpell.autoAttackLock = false
	
    -- Clear resist state when target changes
    CleveRoids.ClearResistState()

    -- Handle sequences with reset=target - save/restore per-target state
    -- Instead of resetting, we remember each target's progress in the sequence
    local currentGuid = nil
    if UnitExists("target") then
        currentGuid = CleveRoids.GetGUID("target")
    end
    for _, sequence in pairs(CleveRoids.Sequences) do
        if sequence.reset and sequence.reset.target then
            local oldGuid = sequence.lastTargetGuid

            -- Only process if target actually changed
            if oldGuid ~= currentGuid then
                -- Save current state for the old target (if we had one and progressed)
                if oldGuid and sequence.index > 1 then
                    sequence.perTargetState = sequence.perTargetState or {}
                    sequence.perTargetState[oldGuid] = {
                        index = sequence.index,
                        lastUpdate = sequence.lastUpdate,
                    }
                end

                -- Restore state for the new target (or start fresh)
                if currentGuid and sequence.perTargetState and sequence.perTargetState[currentGuid] then
                    -- Restore saved state for this target
                    local saved = sequence.perTargetState[currentGuid]
                    sequence.index = saved.index
                    sequence.lastUpdate = saved.lastUpdate
                else
                    -- New target we haven't seen - start at step 1
                    sequence.index = 1
                    sequence.status = 0
                end

                -- Update the current target GUID
                sequence.lastTargetGuid = currentGuid
            end
        end
    end

    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:UPDATE_MACROS()
    CleveRoids.currentSequence = nil
    -- Explicitly nil tables before re-assignment
    CleveRoids.ParsedMsg = nil;
    CleveRoids.ParsedMsg = {}

    CleveRoids.Macros = nil;
    CleveRoids.Macros = {}

    CleveRoids.Actions = nil;
    CleveRoids.Actions = {}

    CleveRoids.Sequences = nil;
    CleveRoids.Sequences = {}

    CleveRoids.IndexSpells()
    CleveRoids.IndexTalents()
    CleveRoids.IndexPetSpells()
    CleveRoids.IndexActionBars()
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:SPELLS_CHANGED()
    -- PERFORMANCE: Clear spell caches when spells change (learn new ranks, etc.)
    CleveRoids.spellIdCache = {}
    CleveRoids.spellNameCache = {}

    -- 修复（回归）：移除此前加的 1s 节流，恢复 8.11 行为——每次 SPELLS_CHANGED 立即全量重建。
    -- 天赋切换时该事件会连发多次（法术书切换过程中），节流会让"首次事件"用未完成更新的
    -- 法术书重建 CleveRoids.Spells，随后法术书真正稳定后的后续事件又被节流跳过，
    -- 导致 [known:X] 等条件永久使用旧天赋数据（图标不刷新、按键用错技能）by 武藤纯子酱 2026.8.31
    CleveRoids.Frame:UPDATE_MACROS()
end

function CleveRoids.Frame:ACTIONBAR_SLOT_CHANGED()
    -- 修复：arg1 缺失时 HasAction(nil)/GetActionTexture(nil) 引擎报错 by 武藤纯子酱 2026.9.9
    if not arg1 or arg1 == 0 then return end
    CleveRoids.ClearAction(arg1)
    CleveRoids.IndexActionSlot(arg1)
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:BAG_UPDATE()
    -- 性能优化：背包变化立即失效 GetLiveItemCount 的 0.1s 缓存，
    -- 保证 [inbag:X]/物品计数在背包操作后立即反映真实状态 by 武藤纯子酱 2026.8.31
    CleveRoids.InvalidateLiveItemCountCache()

    -- In combat: Skip expensive indexing but still queue icon update
    -- so conditionals like [inbag] re-evaluate (they use live bag APIs)
    if UnitAffectingCombat("player") then
        if CleveRoidMacros.realtime == 0 then
            CleveRoids.QueueActionUpdate()
        end
        return
    end

    -- Out of combat: incremental item indexing with throttle
    local now = GetTime()
    if (now - (CleveRoids.lastItemIndexTime or 0)) > 1.0 then
        CleveRoids.lastItemIndexTime = now
        -- 性能优化：背包内容变化但动作条布局/宏文本未变，无需全量清空重建
        -- （原路径 = 清空 Actions/Macros + IndexActionBars 120×tooltip SetAction + 全宏重解析）。
        -- IndexItems 自带：①重扫背包/装备更新 Items 缓存；②relink 全部 Actions 的 item 引用
        -- （Generic.lua 尾部）。新拾取物品的图标由激活时 freshItem 路径（TestForActiveAction）
        -- 实时补全；图标状态由尾部 QueueActionUpdate 排队重算 by 武藤纯子酱 2026.8.31
        CleveRoids.IndexItems()
    end

    -- Always queue icon update so conditionals like [inbag] re-evaluate
    -- even when full indexing is throttled (they use live bag APIs)
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:UNIT_INVENTORY_CHANGED()
    if arg1 ~= "player" then return end
	
    -- PERFORMANCE: Invalidate equipment cache for HasGearEquipped
    if CleveRoids.InvalidateEquipmentCache then
        CleveRoids.InvalidateEquipmentCache()
    end

    -- In combat: Skip ALL processing - EquipBagItem already handles cache invalidation
    -- This eliminates lag from IndexEquippedItems during rapid gear swapping
    if UnitAffectingCombat("player") then
        return
    end

    -- Out of combat: Full indexing with throttle
    local now = GetTime()
    if (now - (CleveRoids.lastEquipIndexTime or 0)) < 0.2 then
        CleveRoids.equipIndexPendingTime = now
        return
    end

    CleveRoids.lastEquipIndexTime = now
    CleveRoids.equipIndexPendingTime = nil
    CleveRoids.lastItemIndexTime = now
    CleveRoids.IndexItems()
    CleveRoids.Actions = {}
    CleveRoids.Macros = {}
    CleveRoids.IndexActionBars()

    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:START_AUTOREPEAT_SPELL()
    local spells = CleveRoids.Spells[BOOKTYPE_SPELL]
    if spells and spells[CleveRoids.Localized.AutoShot] then
        CleveRoids.CurrentSpell.autoShot = true
    else
        CleveRoids.CurrentSpell.wand = true
    end
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

function CleveRoids.Frame:STOP_AUTOREPEAT_SPELL()
    local spells = CleveRoids.Spells[BOOKTYPE_SPELL]
    if spells and spells[CleveRoids.Localized.AutoShot] then
        CleveRoids.CurrentSpell.autoShot = false
    else
        CleveRoids.CurrentSpell.wand = false
    end
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end

-- Generic event handlers that just queue an update
function CleveRoids.Frame:PLAYER_FOCUS_CHANGED()
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end
function CleveRoids.Frame:UPDATE_SHAPESHIFT_FORM()
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end
end
function CleveRoids.Frame:UPDATE_SHAPESHIFT_FORMS() -- 1.12 实际事件名 by 武藤纯子酱 2026.9.11
    CleveRoids.Frame:UPDATE_SHAPESHIFT_FORM()
end
function CleveRoids.Frame:SPELL_UPDATE_COOLDOWN()
    if CleveRoidMacros.realtime == 0 then
        CleveRoids.QueueActionUpdate()
    end

    -- 性能优化：vanilla 中该事件高频（施法/冷却变化期间接近每帧级），
    -- UpdateAllManagedCooldowns 是 槽位×handler 双层循环。加 0.1s 时间门控，
    -- 冷却显示延迟 ≤0.1s（pfUI/Bongos 按钮自身也走 GetActionCooldown hook 实时刷新）by 武藤纯子酱 2026.8.31
    local nowCd = GetTime()
    if (nowCd - (CleveRoids._lastManagedCooldownUpdate or 0)) >= 0.1 then
        CleveRoids._lastManagedCooldownUpdate = nowCd
        CleveRoids.UpdateAllManagedCooldowns()
    end
end

-- Helper function to notify addon handlers about cooldown updates
-- NOTE: Blizzard action buttons are handled natively via ActionButton_OnEvent which calls
-- our GetActionCooldown hook. We do NOT call CooldownFrame_SetTimer directly to avoid
-- conflicts with SuperWoW's own GetActionCooldown handling for #showtooltip macros.
-- Track which slots have been logged to avoid spam
CleveRoids.cooldownDebugLogged = {}

function CleveRoids.UpdateAllManagedCooldowns()
    local Actions = CleveRoids.Actions
    if not Actions then return end

    -- Only notify third-party handlers (pfUI/Bongos)
    -- Blizzard buttons update themselves via GetActionCooldown hook
    local handlerCount = CleveRoids.actionEventHandlers and table.getn(CleveRoids.actionEventHandlers) or 0
    if handlerCount == 0 then return end

    for slot, actions in pairs(Actions) do
        if actions then
            -- Notify action event handlers (for pfUI/Bongos) about the cooldown update
            for _, fn_h in ipairs(CleveRoids.actionEventHandlers) do
                fn_h(slot, "ACTIONBAR_UPDATE_COOLDOWN")
            end
        end
    end
end
-- PERFORMANCE OPTIMIZATION: Throttled event handlers to reduce CPU spam
-- UNIT_AURA can fire dozens of times per second during combat
-- 100ms throttle reduces calls by 90%+ while maintaining responsiveness
function CleveRoids.Frame:UNIT_AURA()
    if CleveRoidMacros.realtime == 0 then
        local now = GetTime()
        if (now - CleveRoids.lastUnitAuraUpdate) >= CleveRoids.EVENT_THROTTLE then
            CleveRoids.lastUnitAuraUpdate = now
            CleveRoids.QueueActionUpdate()
        end
    end
end
function CleveRoids.Frame:UNIT_HEALTH()
    if CleveRoidMacros.realtime == 0 then
        local now = GetTime()
        if (now - CleveRoids.lastUnitHealthUpdate) >= CleveRoids.EVENT_THROTTLE then
            CleveRoids.lastUnitHealthUpdate = now
            CleveRoids.QueueActionUpdate()
        end
    end
end
function CleveRoids.Frame:UNIT_POWER()
    if CleveRoidMacros.realtime == 0 then
        local now = GetTime()
        if (now - CleveRoids.lastUnitPowerUpdate) >= CleveRoids.EVENT_THROTTLE then
            CleveRoids.lastUnitPowerUpdate = now
            CleveRoids.QueueActionUpdate()
        end
    end
end

-- GUID event handlers (v2.39+): fire once per unit state change instead of per-token
function CleveRoids.Frame:UNIT_AURA_GUID()
    if CleveRoidMacros.realtime == 0 then
        -- 性能优化（P1-4）：非相关单位（周围成群怪物）的 GUID 事件直接忽略 by 武藤纯子酱 2026.8.31
        if not CleveRoids.IsMacroRelevantGuid(arg1) then return end
        local now = GetTime()
        if (now - CleveRoids.lastUnitAuraUpdate) >= CleveRoids.EVENT_THROTTLE then
            CleveRoids.lastUnitAuraUpdate = now
            CleveRoids.QueueActionUpdate()
        end
    end
end
function CleveRoids.Frame:UNIT_HEALTH_GUID()
    if CleveRoidMacros.realtime == 0 then
        -- 性能优化（P1-4）：非相关单位的 GUID 事件直接忽略 by 武藤纯子酱 2026.8.31
        if not CleveRoids.IsMacroRelevantGuid(arg1) then return end
        local now = GetTime()
        if (now - CleveRoids.lastUnitHealthUpdate) >= CleveRoids.EVENT_THROTTLE then
            CleveRoids.lastUnitHealthUpdate = now
            CleveRoids.QueueActionUpdate()
        end
    end
end
-- All power GUID events share the same handler
local function OnPowerGuidEvent()
    if CleveRoidMacros.realtime == 0 then
        -- 性能优化（P1-4）：非相关单位的 GUID 事件直接忽略 by 武藤纯子酱 2026.8.31
        if not CleveRoids.IsMacroRelevantGuid(arg1) then return end
        local now = GetTime()
        if (now - CleveRoids.lastUnitPowerUpdate) >= CleveRoids.EVENT_THROTTLE then
            CleveRoids.lastUnitPowerUpdate = now
            CleveRoids.QueueActionUpdate()
        end
    end
end
CleveRoids.Frame.UNIT_MANA_GUID = OnPowerGuidEvent
CleveRoids.Frame.UNIT_RAGE_GUID = OnPowerGuidEvent
CleveRoids.Frame.UNIT_ENERGY_GUID = OnPowerGuidEvent

function CleveRoids.Frame:SPELL_QUEUE_EVENT()
    if event == "SPELL_QUEUE_EVENT" then
        local eventCode = arg1
        local spellId = arg2

        local NORMAL_QUEUED = 2
        local NON_GCD_QUEUED = 4
        local ON_SWING_QUEUED = 0
        local NORMAL_QUEUE_POPPED = 3
        local NON_GCD_QUEUE_POPPED = 5
        local ON_SWING_QUEUE_POPPED = 1

        if eventCode == NORMAL_QUEUED or eventCode == NON_GCD_QUEUED or eventCode == ON_SWING_QUEUED then
            CleveRoids.queuedSpell = {
                spellId = spellId,
                queueType = eventCode,
                queueTime = GetTime()
            }
            if GetSpellRecField then
                local name = GetSpellRecField(spellId, "name")
                if name then
                    CleveRoids.queuedSpell.spellName = name
                end
            end
            -- BUGFIX: Update casting state when spell is queued (for [casting] conditional)
            if CleveRoids.UpdateCastingState then
                CleveRoids.UpdateCastingState()
            end
            CleveRoids.QueueActionUpdate()
        elseif eventCode == NORMAL_QUEUE_POPPED or eventCode == NON_GCD_QUEUE_POPPED or eventCode == ON_SWING_QUEUE_POPPED then
            CleveRoids.queuedSpell = nil
            -- BUGFIX: Update casting state when spell queue pops (for [casting] conditional)
            if CleveRoids.UpdateCastingState then
                CleveRoids.UpdateCastingState()
            end
            CleveRoids.QueueActionUpdate()
        end
    end
end

-- Nampower v2.41+: KEY_DOWN/KEY_UP events
-- arg1=keyCode (int), arg2=metaKeyState (Shift=1,Ctrl=2,Alt=4), arg3=repeat, arg4=time
-- Meta key codes (0=Shift, 1=Ctrl, 2=Alt) are skipped — they are already tracked via IsXKeyDown()
function CleveRoids.Frame:KEY_DOWN()
    local keyCode = arg1
    if keyCode == 0 or keyCode == 1 or keyCode == 2 then return end
    -- 性能优化（去抖）：按住键时 Nampower 持续发重复 KEY_DOWN，状态已置位则不再刷
    -- isActionUpdateQueued（否则 bypassThrottle 使按住 WASD 期间每帧跑全量 tick）by 武藤纯子酱 2026.8.31
    if CleveRoids._keyState[keyCode] then return end
    CleveRoids._keyState[keyCode] = true
    CleveRoids.isActionUpdateQueued = true
end

function CleveRoids.Frame:KEY_UP()
    local keyCode = arg1
    if keyCode == 0 or keyCode == 1 or keyCode == 2 then return end
    -- 性能优化（去抖对称）：状态本就未置位时无需刷队列（键状态无变化，图标无需更新） by 武藤纯子酱 2026.8.31
    if not CleveRoids._keyState[keyCode] then return end
    CleveRoids._keyState[keyCode] = nil
    CleveRoids.isActionUpdateQueued = true
end

-- 新增 by 武藤纯子酱 2026.8.10
function CleveRoids.Frame:CHAT_MSG_ADDON()
    if arg1 == CleveRoids.MESSAGE_PREFIX then
        local data = arg2
        -- 修复：第三方插件发送空消息体（arg2 nil）时 string.match(nil,...) 抛错 by 武藤纯子酱 2026.9.9
        if type(data) ~= "string" then return end
        local guid, text = string.match(data, "^(.-)::(.*)$")
        if guid and text then
            table.insert(CleveRoids.messageQueue, {
                guid = guid,
                text = text,
                timestamp = GetTime()
            })
            -- 防止队列无限膨胀
            if table.getn(CleveRoids.messageQueue) > 100 then
                table.remove(CleveRoids.messageQueue, 1)
            end
        end
    end
end

CleveRoids.Hooks.SendChatMessage = SendChatMessage
function SendChatMessage(msg, ...)
    -- Filter out #show/#showtooltip lines by 武藤纯子酱 2026.9.3
    -- pfUI's macrotweak also does this, but our pattern is more specific
    if msg and string.find(msg, "^#show") then
        return
    end
    
    -- Call the original (or pfUI's hook if it's in the chain)
    CleveRoids.Hooks.SendChatMessage(msg, unpack(arg))
end

CleveRoids.RegisterActionEventHandler = function(fn)
    if type(fn) == "function" then
        table.insert(CleveRoids.actionEventHandlers, fn)
    end
end

CleveRoids.RegisterMouseOverResolver = function(fn)
    if type(fn) == "function" then
        table.insert(CleveRoids.mouseOverResolvers, fn)
    end
end

CleverMacro = true

do
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function()
        -- 修复：1.x 客户端的 OnEvent 处理器不接收 (self, event, arg1) 参数，event/arg1 是全局变量
        -- （原参数式写法中 event 恒为 nil，整段 pfUI /focus 集成从未执行） by 武藤纯子酱 2026.8.31
        if event == "PLAYER_LOGIN" then
            -- This ensures we wait until the player is fully in the world and all addons are loaded.
            this:UnregisterEvent("PLAYER_LOGIN")

            -- Ensure both pfUI and its focus module are loaded before attempting to hook.
            -- This also checks that the slash command we want to modify exists.
            if pfUI and pfUI.uf and pfUI.uf.focus and SlashCmdList.PFFOCUS then

                local original_PFFOCUS_Handler = SlashCmdList.PFFOCUS
                SlashCmdList.PFFOCUS = function(msg)
                    -- First, execute the original /focus command from pfUI to set the unit name.
                    original_PFFOCUS_Handler(msg)

                    local focus = pfUI.uf.focus

                    -- 修复：unitname 为 nil 有两种情况——①焦点已被清除；②pfUI superwow 模块的
                    -- GUID 焦点模式（unitname=nil 且 label=guid、id=""）。原代码此时一律清空
                    -- label/id，会把 pfUI 刚设置好的 GUID 焦点整个抹掉，焦点框体因 label 为空
                    -- 在 OnUpdate 中提前 return 永不刷新（focustarget 也会随之隐藏），
                    -- 表现为 pfUI 焦点框架失效 by 武藤纯子酱 2026.9.9
                    if not focus.unitname then return end

                    -- 名称焦点模式：立即做一次"名字→单位token"解析，供本插件 [focus] 条件直接施法
                    local focusName = focus.unitname

                    -- This function iterates through all known friendly units to find a
                    -- name match and return its specific unit token.
                    local function findUnitToken()
                        -- Check party members and their pets
                        for i = 1, GetNumPartyMembers() do
                            if strlower(UnitName("party"..i) or "") == focusName then
                                return "party"..i
                            end
                            if UnitExists("partypet"..i) and strlower(UnitName("partypet"..i) or "") == focusName then
                                return "partypet"..i
                            end
                        end

                        -- Check raid members and their pets
                        for i = 1, GetNumRaidMembers() do
                            if strlower(UnitName("raid"..i) or "") == focusName then
                                return "raid"..i
                            end
                            if UnitExists("raidpet"..i) and strlower(UnitName("raidpet"..i) or "") == focusName then
                                return "raidpet"..i
                            end
                        end

                        -- Check player and pet
                        if strlower(UnitName("player") or "") == focusName then return "player" end
                        if UnitExists("pet") and strlower(UnitName("pet") or "") == focusName then return "pet" end

                        return nil
                    end

                    local found_token = findUnitToken()

                    if found_token then
                        -- 按 pfUI 自身约定写入（label=完整单位token，id=""，与 pfUI OnUpdate
                        -- 自身的焦点检测写入格式一致）；本插件 [focus] 条件读取 label..id 语义不变，
                        -- focustarget 的 label.."target" 拼接也随之恢复为合法 token
                        focus.label = found_token
                        focus.id = ""
                    end
                    -- 找不到时不写任何字段：目标/怪物类焦点交给 pfUI OnUpdate 的焦点检测自行解析
                    -- （pfValidUnits 含 target、mouseover 等更多单位），避免破坏 pfUI 的解析状态
                end
            end
        end
    end)
    f:RegisterEvent("PLAYER_LOGIN")
end

SLASH_CLEVEROID1 = "/cleveroid"
SLASH_CLEVEROID2 = "/cleveroidmacros"
SlashCmdList["CLEVEROID"] = function(msg)
    if type(msg) ~= "string" then
        msg = ""
    end
    local cmd, val, val2
    local s, e, a, b, c = string.find(msg, "^(%S*)%s*(%S*)%s*(.*)$")
    if a then cmd = a else cmd = "" end
    if b then val = b else val = "" end
    if c then val2 = c else val2 = "" end

    -- No command: show current value and available commands
    if cmd == "" then
        CleveRoids.Print("Current Settings:")
        DEFAULT_CHAT_FRAME:AddMessage("realtime (force fast updates, CPU intensive) = " .. CleveRoidMacros.realtime .. " (Default: 0)")
        DEFAULT_CHAT_FRAME:AddMessage("refresh (updates per second) = " .. CleveRoidMacros.refresh .. " (Default: 10)")
        DEFAULT_CHAT_FRAME:AddMessage("macrocheck (syntax checker) = " .. CleveRoidMacros.macrocheck .. " (Default: 1)")
        DEFAULT_CHAT_FRAME:AddMessage("debug (show learning messages) = " .. (CleveRoids.debug and "1" or "0") .. " (Default: 0)")
        DEFAULT_CHAT_FRAME:AddMessage(" ")
        CleveRoids.Print("Available Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/cleveroid realtime 0 or 1 - Force realtime updates")
        DEFAULT_CHAT_FRAME:AddMessage("/cleveroid refresh X - Set refresh rate (1-10 updates/sec)")
        DEFAULT_CHAT_FRAME:AddMessage("/cleveroid macrocheck 0 or 1 - Enable/disable macro syntax checker")
        DEFAULT_CHAT_FRAME:AddMessage("/cleveroid learn <spellID> <duration> - Manually set spell duration")
        DEFAULT_CHAT_FRAME:AddMessage("/cleveroid forget <spellID|all> - Forget learned duration(s)")
        DEFAULT_CHAT_FRAME:AddMessage("/cleveroid debug [0|1] - Toggle learning debug messages")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Spell Schools:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid listschools - List all learned spell schools')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid clearschools - Clear learned spell school data')		
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Immunity Tracking:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid listimmune [school] - List immunity data')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid addimmune "<NPC>" <school> [buff] - Add immunity')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid removeimmune "<NPC>" <school> - Remove immunity')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid clearimmune [school] - Clear immunity data')
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00CC Immunity Tracking:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid listccimmune [type] - List CC immunity data')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid addccimmune "<NPC>" <type> [buff] - Add CC immunity')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid removeccimmune "<NPC>" <type> - Remove CC immunity')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid clearccimmune [type] - Clear CC immunity data')
        DEFAULT_CHAT_FRAME:AddMessage("  CC types: stun, fear, root, silence, sleep, charm, polymorph, banish, horror, disorient, snare")
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Combo Point Tracking:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid combotrack - Show combo point tracking info')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid comboclear - Clear combo tracking data')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid combolearn - Show learned combo durations (per CP)')
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Talent Modifiers:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid talenttabs - Show talent tab IDs for your class')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid listtab <tab> - List all talents in a tab with their IDs')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid talents - Show current talent ranks')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid testtalent <spellID> - Test talent modifier for a spell')
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Debuff Tracking Debug:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid debuffdebug [spell] - Debug debuff tracking on target')
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00pfUI Tank Integration:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid tankdebug - Debug tank targeting conditionals')
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00All-Caster Aura Tracking:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid auradebug - Debug buff/debuff time tracking from all casters')
        DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Overflow Buff Frame:|r")
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid overflowframe [on|off] - Enable/disable player overflow buff frame (default: off)')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid overflowtest - Toggle overflow buff frame test mode')
        DEFAULT_CHAT_FRAME:AddMessage('/cleveroid overflowreset - Reset overflow frame positions to defaults')
        DEFAULT_CHAT_FRAME:AddMessage("/cleveroid projectilespeed [10-40] - 设置远程技能弹道飞行速度（默认25）") -- by 武藤纯子酱 2026.8.9
        return
    end

    -- realtime
    if cmd == "realtime" then
        local num = tonumber(val)
        if num == 0 or num == 1 then
            CleveRoidMacros.realtime = num
            CleveRoids.Print("realtime set to " .. num)
        else
            CleveRoids.Print("Usage: /cleveroid realtime 0 or 1 - Force realtime updates rather than event based updates (Default: 0. 1 = on, increases CPU load.)")
            CleveRoids.Print("Current realtime = " .. tostring(CleveRoidMacros.realtime))
        end
        return
    end

    -- refresh
    if cmd == "refresh" then
        local num = tonumber(val)
        if num and num >= 1 and num <= 10 then
            CleveRoidMacros.refresh = num
            CleveRoids.cachedRefreshRate = nil  -- Invalidate cached rate
            CleveRoids.Print("refresh set to " .. num .. " times per second")
        else
            CleveRoids.Print("Usage: /cleveroid refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5)")
            CleveRoids.Print("Current refresh = " .. tostring(CleveRoidMacros.refresh) .. " times per second")
        end
        return
    end

    -- macrocheck
    if cmd == "macrocheck" then
        local num = tonumber(val)
        if num == 0 or num == 1 then
            CleveRoidMacros.macrocheck = num
            if num == 1 then
                CleveRoids.Print("Macro syntax checker |cff00ff00enabled|r")
            else
                CleveRoids.Print("Macro syntax checker |cffff0000disabled|r (reload UI to take effect)")
            end
        else
            CleveRoids.Print("Usage: /cleveroid macrocheck 0 or 1 - Enable/disable macro syntax checker (Default: 1)")
            CleveRoids.Print("Current macrocheck = " .. tostring(CleveRoidMacros.macrocheck))
        end
        return
    end

    -- learn (manual set duration)
    if cmd == "learn" then
        local spellID = tonumber(val)
        local duration = tonumber(val2)
        if spellID and duration then
            local playerGUID = CleveRoids.GetGUID("player")
            CleveRoids_LearnedDurations = CleveRoids_LearnedDurations or {}
            CleveRoids_LearnedDurations[spellID] = CleveRoids_LearnedDurations[spellID] or {}
            CleveRoids_LearnedDurations[spellID][playerGUID] = duration
            local spellName = GetSpellRecField(spellID, "name") or "Unknown"
            CleveRoids.Print("Set " .. spellName .. " (ID:" .. spellID .. ") duration to " .. duration .. "s")
        else
            CleveRoids.Print("Usage: /cleveroid learn <spellID> <duration> - Manually set spell duration")
            CleveRoids.Print("Example: /cleveroid learn 11597 30")
        end
        return
    end

    -- forget (delete learned duration)
    if cmd == "forget" or cmd == "unlearn" then
        if val == "all" then
            CleveRoids_LearnedDurations = {}
            CleveRoids.Print("Forgot all learned spell durations")
        else
            local spellID = tonumber(val)
            if spellID and CleveRoids_LearnedDurations and CleveRoids_LearnedDurations[spellID] then
                local spellName = GetSpellRecField(spellID, "name") or "Unknown"
                CleveRoids_LearnedDurations[spellID] = nil
                CleveRoids.Print("Forgot " .. spellName .. " (ID:" .. spellID .. ") duration")
            elseif spellID then
                CleveRoids.Print("No learned duration for spell ID " .. spellID)
            else
                CleveRoids.Print("Usage: /cleveroid forget <spellID> - Forget learned duration")
                CleveRoids.Print("       /cleveroid forget all - Forget all learned durations")
            end
        end
        return
    end

    -- debug (toggle learning messages)
    if cmd == "debug" then
        local num = tonumber(val)
        if num == 0 or num == 1 then
            CleveRoids.debug = (num == 1)
            CleveRoids.Print("debug set to " .. num)
        else
            CleveRoids.debug = not CleveRoids.debug
            CleveRoids.Print("debug " .. (CleveRoids.debug and "enabled" or "disabled"))
        end
        -- Clear keyed debug state so messages re-fire when debug is re-enabled
        CleveRoids._lastDebugState = {}
        return
    end

    -- listimmune (list immunity data)
    if cmd == "listimmune" or cmd == "immunelist" then
        CleveRoids.ListImmunities(val ~= "" and val or nil)
        return
    end

    -- clearimmune (clear immunity data)
    if cmd == "clearimmune" then
        CleveRoids.ClearImmunities(val ~= "" and val or nil)
        return
    end

    -- addimmune (manually add immunity)
    if cmd == "addimmune" then
        -- Parse: /cleveroid addimmune <NPC Name> <school> [buff]
        -- Example: /cleveroid addimmune "Golemagg the Incinerator" fire
        -- Example: /cleveroid addimmune Vaelastrasz fire "Burning Adrenaline"
        local npcName, school, buffName = nil, nil, nil

        -- Try to extract quoted NPC name
        local _, _, quotedNpc, rest = string.find(msg, '^addimmune%s+"([^"]+)"%s*(.*)$')
        if quotedNpc then
            npcName = quotedNpc
            -- Parse school and optional buff from rest
            local _, _, sch, buff = string.find(rest, "^(%S+)%s*(.*)$")
            school = sch
            if buff and buff ~= "" then
                -- Check if buff is quoted
                local _, _, quotedBuff = string.find(buff, '^"([^"]+)"$')
                buffName = quotedBuff or buff
            end
        else
            -- No quoted NPC, use simple parsing
            npcName = val
            school = val2
        end

        CleveRoids.AddImmunity(npcName, school, buffName)
        return
    end

    -- removeimmune (manually remove immunity)
    if cmd == "removeimmune" then
        -- Parse: /cleveroid removeimmune <NPC Name> <school>
        local npcName, school = nil, nil

        -- Try to extract quoted NPC name
        local _, _, quotedNpc, sch = string.find(msg, '^removeimmune%s+"([^"]+)"%s*(%S*)$')
        if quotedNpc then
            npcName = quotedNpc
            school = sch
        else
            npcName = val
            school = val2
        end

        CleveRoids.RemoveImmunity(npcName, school)
        return
    end

    -- ========== CC IMMUNITY COMMANDS ==========

    -- listccimmune (list CC immunity data)
    if cmd == "listccimmune" or cmd == "ccimmunelist" then
        CleveRoids.ListCCImmunities(val ~= "" and val or nil)
        return
    end

    -- clearccimmune (clear CC immunity data)
    if cmd == "clearccimmune" then
        CleveRoids.ClearCCImmunities(val ~= "" and val or nil)
        return
    end

    -- addccimmune (manually add CC immunity)
    if cmd == "addccimmune" then
        -- Parse: /cleveroid addccimmune <NPC Name> <cctype> [buff]
        -- Example: /cleveroid addccimmune "Stone Guardian" stun
        -- Example: /cleveroid addccimmune "Boss Name" fear "Enrage"
        local npcName, ccType, buffName = nil, nil, nil

        -- Try to extract quoted NPC name
        local _, _, quotedNpc, rest = string.find(msg, '^addccimmune%s+"([^"]+)"%s*(.*)$')
        if quotedNpc then
            npcName = quotedNpc
            -- Parse ccType and optional buff from rest
            local _, _, cct, buff = string.find(rest, "^(%S+)%s*(.*)$")
            ccType = cct
            if buff and buff ~= "" then
                -- Check if buff is quoted
                local _, _, quotedBuff = string.find(buff, '^"([^"]+)"$')
                buffName = quotedBuff or buff
            end
        else
            -- No quoted NPC, use simple parsing
            npcName = val
            ccType = val2
        end

        CleveRoids.AddCCImmunity(npcName, ccType, buffName)
        return
    end

    -- removeccimmune (manually remove CC immunity)
    if cmd == "removeccimmune" then
        -- Parse: /cleveroid removeccimmune <NPC Name> <cctype>
        local npcName, ccType = nil, nil

        -- Try to extract quoted NPC name
        local _, _, quotedNpc, cct = string.find(msg, '^removeccimmune%s+"([^"]+)"%s*(%S*)$')
        if quotedNpc then
            npcName = quotedNpc
            ccType = cct
        else
            npcName = val
            ccType = val2
        end

        CleveRoids.RemoveCCImmunityCommand(npcName, ccType)
        return
    end

    -- listschools (show learned spell schools)
    if cmd == "listschools" or cmd == "schools" then
        CleveRoids.Print("|cff88ff88=== Learned Spell Schools ===|r")
        if not CleveRoids_SpellSchools or not next(CleveRoids_SpellSchools) then
            CleveRoids.Print("No spell schools learned yet. Deal damage to enemies!")
            CleveRoids.Print("Nampower damage events will automatically track spell schools.")
        else
            local count = 0
            local bySchool = {}

            -- Group by school
            for spellID, school in pairs(CleveRoids_SpellSchools) do
                if not bySchool[school] then
                    bySchool[school] = {}
                end
                table.insert(bySchool[school], spellID)
                count = count + 1
            end

            CleveRoids.Print("Total spells tracked: " .. count)
            CleveRoids.Print(" ")

            -- Display by school
            for school, spellIDs in pairs(bySchool) do
                local schoolColor = "|cff88ff88"
                if school == "fire" then schoolColor = "|cffff4400"
                elseif school == "frost" then schoolColor = "|cff00ffff"
                elseif school == "nature" then schoolColor = "|cff00ff00"
                elseif school == "shadow" then schoolColor = "|cff8800ff"
                elseif school == "arcane" then schoolColor = "|cffff00ff"
                elseif school == "holy" then schoolColor = "|cffffff00"
                elseif school == "bleed" then schoolColor = "|cffff0000"
                end

                CleveRoids.Print(schoolColor .. string.upper(school) .. "|r (" .. table.getn(spellIDs) .. " spells):")
                for _, spellID in ipairs(spellIDs) do
                    local spellName = GetSpellRecField and GetSpellRecField(spellID, "name") or "Unknown"
                    CleveRoids.Print("  " .. spellName .. " (ID:" .. spellID .. ")")
                end
            end
        end
        return
    end

    -- clearschools (clear learned spell schools)
    if cmd == "clearschools" then
        local count = 0
        if CleveRoids_SpellSchools then
            for _ in pairs(CleveRoids_SpellSchools) do
                count = count + 1
            end
        end
        CleveRoids_SpellSchools = {}
        CleveRoids.spellSchoolMapping = CleveRoids_SpellSchools
        CleveRoids.Print("Cleared " .. count .. " learned spell schools")
        return
    end

    -- combotrack (show combo point tracking info)
    if cmd == "combotrack" or cmd == "combo" then
        CleveRoids.ShowComboTracking()
        return
    end

    -- comboclear (clear combo tracking data)
    if cmd == "comboclear" then
        CleveRoids.ComboPointTracking = {}
        CleveRoids.ComboPointTracking.byID = {}
        CleveRoids.Print("Combo point tracking data cleared")
        return
    end

    -- combolearn (show learned combo durations)
    if cmd == "combolearn" or cmd == "combodurations" then
        CleveRoids.Print("=== Learned Combo Durations ===")
        if not CleveRoids_ComboDurations or not next(CleveRoids_ComboDurations) then
            CleveRoids.Print("No learned combo durations yet. Cast finishers and let them expire!")
        else
            for spellID, cpData in pairs(CleveRoids_ComboDurations) do
                local spellName = GetSpellRecField(spellID, "name") or ("Spell " .. spellID)
                CleveRoids.Print(spellName .. " (ID:" .. spellID .. "):")
                for cp = 1, 5 do
                    if cpData[cp] then
                        CleveRoids.Print("  " .. cp .. " CP = " .. cpData[cp] .. "s")
                    end
                end
            end
        end
        return
    end

    -- talenttabs (show talent tab IDs)
    if cmd == "talenttabs" or cmd == "tabs" then
        CleveRoids.Print("=== Talent Tabs ===")
        for i = 1, GetNumTalentTabs() do
            local name, _, pointsSpent = GetTalentTabInfo(i)
            CleveRoids.Print("Tab " .. i .. ": " .. name .. " (" .. pointsSpent .. " points)")
        end
        return
    end

    -- listtab (show all talents in a specific tab with their IDs)
    if cmd == "listtab" or cmd == "tab" then
        local tabNum = tonumber(val)
        if not tabNum or tabNum < 1 or tabNum > GetNumTalentTabs() then
            CleveRoids.Print("Usage: /cleveroid listtab <tab number>")
            CleveRoids.Print("Example: /cleveroid listtab 2")
            CleveRoids.Print("Use /cleveroid talenttabs to see your tab numbers")
            return
        end

        local tabName = GetTalentTabInfo(tabNum)
        CleveRoids.Print("=== " .. tabName .. " (Tab " .. tabNum .. ") ===")

        local numTalents = GetNumTalents(tabNum)
        for i = 1, numTalents do
            local name, _, _, _, rank, maxRank = GetTalentInfo(tabNum, i)
            if name then
                local rankText = rank .. "/" .. maxRank
                CleveRoids.Print("ID " .. i .. ": " .. name .. " [" .. rankText .. "]")
            end
        end
        return
    end

    -- talents (show current talent ranks)
    if cmd == "talents" or cmd == "talent" then
        CleveRoids.Print("=== Current Talents ===")

        -- Ensure talents are indexed
        if not CleveRoids.Talents or table.getn(CleveRoids.Talents) == 0 then
            if CleveRoids.IndexTalents then
                CleveRoids.IndexTalents()
            end
        end

        local count = 0
        for name, rank in pairs(CleveRoids.Talents) do
            if type(name) == "string" and tonumber(rank) and tonumber(rank) > 0 then
                CleveRoids.Print(name .. ": Rank " .. rank)
                count = count + 1
            end
        end

        if count == 0 then
            CleveRoids.Print("No talents learned yet!")
        else
            CleveRoids.Print("Total: " .. count .. " talents")
        end
        return
    end

    -- testtalent (test talent modifier for a spell)
    if cmd == "testtalent" or cmd == "talenttest" then
        local spellID = tonumber(val)
        if not spellID then
            CleveRoids.Print("Usage: /cleveroid testtalent <spellID>")
            CleveRoids.Print("Example: /cleveroid testtalent 1943  (Rupture Rank 1)")
            return
        end

        local spellName = GetSpellRecField(spellID, "name") or ("Spell " .. spellID)
        local modifier = CleveRoids.talentModifiers and CleveRoids.talentModifiers[spellID]

        if not modifier then
            CleveRoids.Print(spellName .. " (ID:" .. spellID .. ") has no talent modifier configured")
            return
        end

        -- Get talent rank using position-based or name-based lookup
        local talentRank = 0
        local maxRank = 3
        local talentName = modifier.talent or ("Tab " .. tostring(modifier.tab) .. " ID " .. tostring(modifier.id))

        -- Position-based lookup (preferred)
        if modifier.tab and modifier.id then
            local name, _, _, _, rank, max = GetTalentInfo(modifier.tab, modifier.id)
            talentRank = tonumber(rank) or 0
            maxRank = tonumber(max) or 3
            if name then
                talentName = name
            end
        end

        -- Name-based fallback
        if talentRank == 0 and modifier.talent and CleveRoids.GetTalentRank then
            talentRank = CleveRoids.GetTalentRank(modifier.talent)
        end

        CleveRoids.Print("=== Talent Modifier Test ===")
        CleveRoids.Print("Spell: " .. spellName .. " (ID:" .. spellID .. ")")
        CleveRoids.Print("Talent: " .. talentName)
        CleveRoids.Print("Your Rank: " .. talentRank .. "/" .. maxRank)

        if talentRank == 0 then
            CleveRoids.Print("|cffff0000You don't have this talent!|r")
        else
            -- Test with a base duration (use 10s as example)
            local baseDur = 10
            local modDur = modifier.modifier(baseDur, talentRank)
            CleveRoids.Print("Example: 10s base -> " .. modDur .. "s modified (+" .. (modDur - baseDur) .. "s)")
        end
        return
    end

    -- debuffdebug (debug debuff tracking on target)
    if cmd == "debuffdebug" or cmd == "debuff" or cmd == "trackdebug" then
        local searchName = val
        if val2 and val2 ~= "" then
            searchName = val .. " " .. val2
        end
        -- Strip underscores and quotes
        if searchName and searchName ~= "" then
            searchName = string.gsub(searchName, "_", " ")
            searchName = string.gsub(searchName, '"', "")
        end

        CleveRoids.Print("|cff88ff88=== Debuff Tracking Debug ===|r")

        local guid = CleveRoids.GetGUID("target")
        if not guid then
            CleveRoids.Print("|cffff0000No target selected!|r")
            return
        end

        local targetName = UnitName("target") or "Unknown"
        CleveRoids.Print("Target: " .. targetName .. " (GUID: " .. tostring(guid) .. ")")

        -- Show tracking table for this target
        CleveRoids.Print(" ")
        CleveRoids.Print("|cff00ff00=== Tracked Debuffs (libdebuff.objects) ===|r")
        local lib = CleveRoids.libdebuff
        if lib and lib.objects and lib.objects[guid] then
            local count = 0
            for spellID, rec in pairs(lib.objects[guid]) do
                if rec and rec.start and rec.duration then
                    local timeRemaining = rec.duration + rec.start - GetTime()
                    local spellName = GetSpellRecField and GetSpellRecField(spellID, "name") or "Unknown"
                    local caster = rec.caster or "unknown"
                    local stacks = rec.stacks or 0
                    if timeRemaining > 0 then
                        CleveRoids.Print(string.format("  |cff00ff00[%d]|r %s: %.1fs left (caster: %s, stacks: %d)",
                            spellID, spellName, timeRemaining, caster, stacks))
                        count = count + 1
                    else
                        CleveRoids.Print(string.format("  |cffff0000[%d]|r %s: EXPIRED %.1fs ago (caster: %s)",
                            spellID, spellName, -timeRemaining, caster))
                    end
                end
            end
            if count == 0 then
                CleveRoids.Print("  (no active tracked debuffs)")
            end
        else
            CleveRoids.Print("  (no tracking data for this target)")
        end

        -- Show actual debuff slots (1-16 via UnitDebuff, 17-48 via overflow)
        CleveRoids.Print(" ")
        CleveRoids.Print("|cff00ff00=== Debuff Slots (UnitDebuff 1-16) ===|r")
        local debuffCount = 0
        for i = 1, 16 do
            local texture, stacks, debuffType, spellID = UnitDebuff("target", i)
            if texture then
                local spellName = GetSpellRecField and GetSpellRecField(spellID, "name") or "slot" .. i
                CleveRoids.Print(string.format("  Slot %d: [%d] %s (stacks: %d)",
                    i, spellID or 0, spellName, stacks or 0))
                debuffCount = debuffCount + 1
            end
        end
        if debuffCount == 0 then
            CleveRoids.Print("  (no debuffs in slots 1-16)")
        end

        -- Show overflow debuffs in buff slots (17-48)
        CleveRoids.Print(" ")
        CleveRoids.Print("|cff00ff00=== Overflow Debuffs (UnitBuff 1-32 as debuffs 17-48) ===|r")
        local overflowCount = 0
        for i = 1, 32 do
            local texture, stacks, spellID = UnitBuff("target", i)
            if texture and spellID then
                -- Check if this might be an overflow debuff by checking libdebuff durations
                local isDebuff = lib and lib.durations and lib.durations[spellID]
                if isDebuff then
                    local spellName = GetSpellRecField and GetSpellRecField(spellID, "name") or "slot" .. i
                    CleveRoids.Print(string.format("  Buff Slot %d (=Debuff %d): [%d] %s (stacks: %d) |cffff8800OVERFLOW|r",
                        i, i + 16, spellID, spellName, stacks or 0))
                    overflowCount = overflowCount + 1
                end
            end
        end
        if overflowCount == 0 then
            CleveRoids.Print("  (no overflow debuffs detected)")
        end

        -- If a specific debuff name was provided, test the conditional
        if searchName and searchName ~= "" then
            CleveRoids.Print(" ")
            CleveRoids.Print("|cff00ff00=== Testing [debuff:\"" .. searchName .. "\"] ===|r")

            -- Test ValidateUnitDebuff
            local result = CleveRoids.ValidateUnitDebuff("target", { name = searchName })
            CleveRoids.Print("ValidateUnitDebuff(target, {name='" .. searchName .. "'}): " ..
                (result and "|cff00ff00true|r" or "|cffff0000false|r"))

            -- Test with time conditional
            local resultTime = CleveRoids.ValidateUnitDebuff("target", { name = searchName, operator = "<", amount = 99999 })
            CleveRoids.Print("ValidateUnitDebuff(target, {name='" .. searchName .. "', operator='<', amount=99999}): " ..
                (resultTime and "|cff00ff00true|r" or "|cffff0000false|r"))

            -- Look for spell IDs matching this name
            CleveRoids.Print(" ")
            CleveRoids.Print("|cff00ff00=== Spell ID Lookup for \"" .. searchName .. "\" ===|r")
            local foundIDs = {}
            -- Check Spells table
            if CleveRoids.Spells then
                for id, name in pairs(CleveRoids.Spells) do
                    if type(name) == "string" and string.lower(name) == string.lower(searchName) then
                        table.insert(foundIDs, id)
                    end
                end
            end
            -- Also check GetSpellRecField
            -- 降级环境空桩会让 `if GetSpellRecField then` 误判可用并空跑 30000 次；改用特性标志 by 武藤纯子酱 2026.9.11
            if CleveRoids.hasGetSpellRec then
                for id = 1, 30000 do
                    local name = GetSpellRecField(id, "name")
                    if name and string.lower(name) == string.lower(searchName) then
                        local found = false
                        for _, existingID in ipairs(foundIDs) do
                            if existingID == id then found = true break end
                        end
                        if not found then
                            table.insert(foundIDs, id)
                        end
                    end
                    -- Stop early if we found some
                    if table.getn(foundIDs) > 10 then break end
                end
            end

            if table.getn(foundIDs) > 0 then
                for _, id in ipairs(foundIDs) do
                    local tracked = lib and lib.objects and lib.objects[guid] and lib.objects[guid][id]
                    local trackedStr = tracked and "|cff00ff00TRACKED|r" or "|cff888888not tracked|r"
                    CleveRoids.Print("  SpellID " .. id .. ": " .. trackedStr)
                    if tracked then
                        local remaining = tracked.duration + tracked.start - GetTime()
                        CleveRoids.Print("    -> " .. string.format("%.1fs remaining (caster: %s)", remaining, tracked.caster or "?"))
                    end
                end
            else
                CleveRoids.Print("  (no spell IDs found for this name)")
            end
        end

        return
    end

    -- tankdebug (debug pfUI tank integration)
    if cmd == "tankdebug" then
        CleveRoids.Print("=== Tank Debug ===")

        -- Check pfUI availability
        if not CleveRoids.HasPfUITanks() then
            CleveRoids.Print("|cffff0000pfUI tank system not available!|r")
            CleveRoids.Print("  pfUI loaded: " .. tostring(type(pfUI) == "table"))
            CleveRoids.Print("  pfUI_config: " .. tostring(type(pfUI_config) == "table"))
            return
        end

        CleveRoids.Print("|cff00ff00pfUI tank system available|r")

        -- List raid frame tanks
        CleveRoids.Print(" ")
        CleveRoids.Print("|cffffaa00Raid Frame Tanks (right-click toggle):|r")
        local raidTankCount = 0
        if type(pfUI) == "table" and type(pfUI.uf) == "table" and
           type(pfUI.uf.raid) == "table" and type(pfUI.uf.raid.tankrole) == "table" then
            for name, isTank in pairs(pfUI.uf.raid.tankrole) do
                if isTank then
                    CleveRoids.Print("  - " .. name)
                    raidTankCount = raidTankCount + 1
                end
            end
        end
        if raidTankCount == 0 then
            CleveRoids.Print("  (none)")
        end

        -- List nameplate off-tank names
        CleveRoids.Print(" ")
        CleveRoids.Print("|cffffaa00Nameplate Off-Tank Names (config setting):|r")
        local npTankCount = 0
        if type(pfUI_config) == "table" and type(pfUI_config.nameplates) == "table" then
            local list = pfUI_config.nameplates.combatofftanks or ""
            if list ~= "" then
                CleveRoids.Print("  Raw setting: \"" .. list .. "\"")
                -- pfUI uses # as separator
                for name in string.gfind(list, "[^#]+") do
                    name = string.gsub(name, "^%s*(.-)%s*$", "%1") -- trim
                    if name ~= "" then
                        CleveRoids.Print("  - " .. name .. " (lowercase: " .. string.lower(name) .. ")")
                        npTankCount = npTankCount + 1
                    end
                end
            end
        end
        if npTankCount == 0 then
            CleveRoids.Print("  (none)")
        end

        -- Check current target
        CleveRoids.Print(" ")
        CleveRoids.Print("|cffffaa00Current Target Check:|r")
        if not UnitExists("target") then
            CleveRoids.Print("  No target selected")
        else
            local targetName = UnitName("target") or "Unknown"
            CleveRoids.Print("  Your target: " .. targetName)

            if UnitExists("targettarget") then
                local ttName = UnitName("targettarget") or "Unknown"
                CleveRoids.Print("  Target's target: " .. ttName)
                local isTank = CleveRoids.IsPlayerTank(ttName)
                if isTank then
                    CleveRoids.Print("  |cff00ff00" .. ttName .. " IS marked as tank|r")
                else
                    CleveRoids.Print("  |cffff8800" .. ttName .. " is NOT marked as tank|r")
                    CleveRoids.Print("  (lowercase check: " .. string.lower(ttName) .. ")")
                end
            else
                CleveRoids.Print("  Target's target: (none)")
            end

            -- Test the conditional functions
            CleveRoids.Print(" ")
            CleveRoids.Print("|cffffaa00Conditional Results:|r")
            local isTargetingTank = CleveRoids.IsTargetingAnyTank("target")
            CleveRoids.Print("  IsTargetingAnyTank('target'): " .. tostring(isTargetingTank))
            CleveRoids.Print("  [targeting:tank] would be: " .. tostring(isTargetingTank))
            CleveRoids.Print("  [notargeting:tank] would be: " .. tostring(not isTargetingTank))
        end

        return
    end

    -- auradebug (debug all-caster aura tracking)
    if cmd == "auradebug" or cmd == "bufftracking" then
        CleveRoids.Print("=== All-Caster Aura Tracking Debug ===")

        -- Check CVar status
        local auraCastEnabled = GetCVar("NP_EnableAuraCastEvents")
        if auraCastEnabled == "1" then
            CleveRoids.Print("|cff00ff00NP_EnableAuraCastEvents = 1 (ENABLED)|r")
        else
            CleveRoids.Print("|cffff0000NP_EnableAuraCastEvents = " .. tostring(auraCastEnabled) .. " (DISABLED)|r")
            CleveRoids.Print("  Enable with: |cff00ffff/run SetCVar(\"NP_EnableAuraCastEvents\", \"1\")|r")
            CleveRoids.Print("  Then /reload")
        end

        -- Check Nampower version
        local API = CleveRoids.NampowerAPI
        if API and API.features then
            CleveRoids.Print("Nampower hasAuraCastEvents: " .. tostring(API.features.hasAuraCastEvents))
        else
            CleveRoids.Print("|cffff0000Nampower API not available|r")
        end

        -- Show tracking data for current target/mouseover
        CleveRoids.Print(" ")
        CleveRoids.Print("|cffffaa00Tracked Auras:|r")
        local trackingCount = 0
        local now = GetTime()
        -- Determine which backing table to iterate
        local isPfUI = CleveRoids.hasPfUI76 and pfUI and pfUI.libdebuff_all_auras
        local backingTable = isPfUI and pfUI.libdebuff_all_auras or CleveRoids.AllCasterAuraTracking or {}
        if isPfUI then
            CleveRoids.Print("  (reading from pfUI.libdebuff_all_auras)")
        end
        for targetGuid, spellNames in pairs(backingTable) do
            local unitName = nil
            -- Try to find unit name for this GUID (use pcall to handle invalid units like "focus")
            for _, testUnit in ipairs({"target", "mouseover", "party1", "party2", "party3", "party4"}) do
                local ok, exists, testGuid = pcall(UnitExists, testUnit)
                if ok and exists and testGuid == targetGuid then
                    unitName = UnitName(testUnit)
                    break
                end
            end

            for spellName, casters in pairs(spellNames) do
                for casterGuid, auraData in pairs(casters) do
                    local startTime = isPfUI and auraData.startTime or auraData.start
                    if startTime and auraData.duration then
                        local remaining = auraData.duration + startTime - now
                        if remaining > 0 then
                            local display = unitName or (string.sub(targetGuid, 1, 16) .. "...")
                            CleveRoids.Print(string.format("  %s on %s: %.1fs left (caster: %s)",
                                spellName, display, remaining, string.sub(tostring(casterGuid), 1, 16)))
                            trackingCount = trackingCount + 1
                        end
                    end
                end
            end
        end
        if trackingCount == 0 then
            CleveRoids.Print("  (no auras currently tracked)")
        end

        -- Check specific target
        if UnitExists("target") then
            CleveRoids.Print(" ")
            CleveRoids.Print("|cffffaa00Target Buff Check:|r")
            local targetGuid = CleveRoids.GetGUID("target")
            CleveRoids.Print("  Target GUID: " .. tostring(targetGuid))
            local targetData = CleveRoids.GetAuraTrackingData(targetGuid)
            if targetData then
                local count = 0
                for _, casters in pairs(targetData) do
                    for _ in pairs(casters) do count = count + 1 end
                end
                CleveRoids.Print("  Tracked aura entries on target: " .. count)
            else
                CleveRoids.Print("  |cffff9900No tracking data for this target|r")
            end
        end

        return
    end

    -- overflowframe (enable/disable player overflow buff frame)
    if cmd == "overflowframe" then
        CleveRoidMacros = CleveRoidMacros or {}
        if val == "on" or val == "1" then
            CleveRoidMacros.overflowPlayerEnabled = true
            CleveRoids.Print("Player overflow buff frame |cff00ff00enabled|r")
        elseif val == "off" or val == "0" then
            CleveRoidMacros.overflowPlayerEnabled = false
            CleveRoids.Print("Player overflow buff frame |cffff0000disabled|r")
        else
            CleveRoidMacros.overflowPlayerEnabled = not CleveRoidMacros.overflowPlayerEnabled
            if CleveRoidMacros.overflowPlayerEnabled then
                CleveRoids.Print("Player overflow buff frame |cff00ff00enabled|r")
            else
                CleveRoids.Print("Player overflow buff frame |cffff0000disabled|r")
            end
        end
        if CleveRoids.RebuildOverflowFrame then
            CleveRoids.RebuildOverflowFrame()
        end
        return
    end

    -- overflowtest (toggle overflow buff frame test mode)
    if cmd == "overflowtest" then
        if CleveRoids.ToggleOverflowTest then
            CleveRoids.ToggleOverflowTest()
        else
            CleveRoids.Print("|cffff0000OverflowBuffFrame extension not loaded|r")
        end
        return
    end

    -- overflowreset (reset frame positions to defaults)
    if cmd == "overflowreset" then
        if CleveRoids.ResetOverflowFramePositions then
            CleveRoids.ResetOverflowFramePositions()
        else
            CleveRoids.Print("|cffff0000OverflowBuffFrame extension not loaded|r")
        end
        return
    end

	-- 新增注册事件宏 by 武藤纯子酱 2026.1.15
	if cmd == "eventmacroadd" then
		if not b or not c then
			return
		end

		-- 解析参数：宏名字 是否超级宏标记 事件1,事件2,事件3…… (事件可选)
		local macroName = b
		local _, _, superFlag, eventStr = string.find(c, "^(%d*)%s*(%S*)%s*$");
		
		if not macroName or not superFlag or not eventStr then
			CleveRoids.Print("用法: /cleveroid eventmacroadd 宏名字 是否超级宏标记 事件1,事件2,事件3……")
			CleveRoids.Print("示例: /cleveroid eventmacroadd MyMacro 1 PLAYER_TARGET_CHANGED,UNIT_HEALTH")
			CleveRoids.Print("超级宏标记: 0=普通宏, 1=超级宏")
			return
		end
		
		-- 将超级宏标记转换为数字
		local super = tonumber(superFlag)
		if super ~= 0 and super ~= 1 then
			CleveRoids.Print("错误: 超级宏标记必须是 0 或 1")
			return
		end
		
		-- 解析事件列表
		local events = {}
		for event in string.gmatch(eventStr, "([^,]+)") do
			event = CleveRoids.Trim(event)
			if event ~= "" then
				table.insert(events, event)
			end
		end
		
		if table.getn(events) == 0 then
			CleveRoids.Print("错误: 必须指定至少一个事件")
			return
		end

		-- 调用本插件独立的注册函数（不再依赖 SuperMacro） by 武藤纯子酱 2026.9.3
		if not CleveRoids.RegisterEventMacro then
			CleveRoids.Print("错误: EventMacros 模块未加载")
			return
		end

		-- 事件宏注册为静默幂等：每次都确保注册，但仅首次注册时提示；
		-- 重复注册（如宏内反复执行）不再弹出消息 by 武藤纯子酱 2026.9.3
		-- （注册前先快照已注册事件，注册后对比差集即为本次新增，仅对新增部分提示）
		local before = {}
		for _, event in pairs(events) do
			if not CleveRoids.IsEventMacroRegistered(macroName, super, event) then
				before[event] = true
			end
		end
		for _, event in pairs(events) do
			CleveRoids.RegisterEventMacro(macroName, super, event)
		end
		local newEvents = {}
		for _, event in pairs(events) do
			if before[event] then
				table.insert(newEvents, event)
			end
		end

		if table.getn(newEvents) > 0 then
			-- 仅在本次有新注册时提示
			CleveRoids.Print(string.format("已注册事件宏: %s (超级宏: %s) - 事件: %s",
				macroName, super == 1 and "是" or "否", table.concat(newEvents, ", ")))
		end
		return
	end

	if cmd == "eventmacrodel" then
		if not b or not c then
			return
		end

		-- 解析参数：宏名字 是否超级宏标记 事件1,事件2,事件3…… (事件可选)
		local macroName = b
		local _, _, superFlag, eventStr = string.find(c, "^(%d*)%s*(%S*)%s*$");
		
		if not macroName or not superFlag then
			CleveRoids.Print("用法: /cleveroid eventmacrodel 宏名字 是否超级宏标记 [事件1,事件2,事件3……]")
			CleveRoids.Print("示例: /cleveroid eventmacrodel MyMacro 1 PLAYER_TARGET_CHANGED,UNIT_HEALTH")
			CleveRoids.Print("示例: /cleveroid eventmacrodel MyMacro 1 (删除所有事件)")
			return
		end
		
		-- 将超级宏标记转换为数字
		local super = tonumber(superFlag)
		if super ~= 0 and super ~= 1 then
			CleveRoids.Print("错误: 超级宏标记必须是 0 或 1")
			return
		end
		
		-- 解析事件列表（如果提供）
		local events = {}
		if eventStr and eventStr ~= "" then
			for event in string.gmatch(eventStr, "([^,]+)") do
				event = CleveRoids.Trim(event)
				if event ~= "" then
					table.insert(events, event)
				end
			end
		end
		
		-- 调用本插件独立的注销函数（不再依赖 SuperMacro） by 武藤纯子酱 2026.9.3
		if not CleveRoids.UnregisterEventMacro then
			CleveRoids.Print("错误: EventMacros 模块未加载")
			return
		end

		if table.getn(events) > 0 then
			-- 删除指定事件

			-- 调用函数
			for _, event in pairs(events) do
				CleveRoids.UnregisterEventMacro(macroName, super, event)
			end

			CleveRoids.Print(string.format("已注销事件宏: %s (超级宏: %s) - 事件: %s",
				macroName, super == 1 and "是" or "否", table.concat(events, ", ")))
		else
			-- 获取所有已注册的事件 by 武藤纯子酱 2026.9.3
			local allEvents = CleveRoids.GetEventMacroEvents(macroName, super)
			
			if table.getn(allEvents) > 0 then
				-- 删除所有事件
				for _, event in pairs(allEvents) do
					CleveRoids.UnregisterEventMacro(macroName, super, event)
				end

				CleveRoids.Print(string.format("已完全注销事件宏: %s (超级宏: %s) - 删除 %d 个事件", macroName, super == 1 and "是" or "否", table.getn(allEvents)))
			else
				CleveRoids.Print(string.format("未找到注册的事件宏: %s (超级宏: %s)", macroName, super == 1 and "是" or "否"))
			end
		end
		return
	end

	if cmd == "eventmacrolist" then
		CleveRoids.Print("=== 已注册的事件宏列表 ===")

		-- 改读本插件独立事件宏框架（不再依赖 SuperMacro_EventsFrame） by 武藤纯子酱 2026.9.3
		local evFrame = CleveRoids.EventMacrosFrame
		if not evFrame or not evFrame.events then
			CleveRoids.Print("没有注册的事件宏")
			return
		end

		for event, macros in pairs(evFrame.events) do
			for macroKey, _ in pairs(macros) do
				-- 修复：超级宏键使用控制字符前缀 \1（见 EventMacros.lua，避免与 SUPER 开头的普通宏冲突）by 武藤纯子酱 2026.9.11
				local isSuper = string.sub(macroKey, 1, 1) == "\1"
				local macroName = isSuper and string.sub(macroKey, 2) or macroKey

				CleveRoids.Print(string.format("%s (%s) - 事件: %s",
					macroName, isSuper and "超级宏" or "普通宏", event))
			end
		end
		return
	end

	-- 新增talent save/load/delete/list 命令 by 武藤纯子酱 2026.5.13
	if cmd == "talentsave" then
		local slot = tonumber(val)
		if not slot or slot < 1 or slot > 8 then
			CleveRoids.Print("用法: /cleveroid talentsave <编号> [套装名称]  (编号1-8)")
			return
		end
		local setName = val2
		if not setName or setName == "" then
			setName = "天赋套装" .. slot
		end
		-- 保存当前天赋
		CleveRoids.SaveCurrentTalentSet(slot, setName)
	end

	if cmd == "talentdelete" or cmd == "talentdel" then
		local slot = tonumber(val)
		if not slot or slot < 1 or slot > 8 then
			CleveRoids.Print("用法: /cleveroid talentdelete <编号>")
			return
		end
		CleveRoids.DeleteTalentSet(slot)
	end

	if cmd == "talentlist" then
		CleveRoids.ListTalentSets()
	end

	-- 新增projectilespeed / ps 命令 by 武藤纯子酱 2026.8.9
	if cmd == "projectilespeed" or cmd == "ps" then
		if val == "" then
			local current = CleveRoidMacros.projectileSpeed or 25
			CleveRoids.Print("当前远程技能弹道飞行速度: " .. current .. " (范围 10-40)")
		else
			local num = tonumber(val)
			if num and num >= 10 and num <= 40 then
				CleveRoidMacros.projectileSpeed = num
				CleveRoids.Print("远程技能弹道飞行速度设置为: " .. num)
			else
				CleveRoids.Print("无效数值，请输入 10-40 之间的整数")
			end
		end
		return
	end

	-- @fov 配置（瞄准射击智能选目标，UnitXP farthestInFOV）by 武藤纯子酱 2026.9.12
	if cmd == "fov" then
		if val ~= "" then
			local cone = tonumber(val)
			local range = tonumber(val2)
			if cone and cone >= 2 and cone <= 10 then CleveRoidMacros.fovCone = cone end
			if range and range >= 1 then CleveRoidMacros.fovRange = range end
		end
		CleveRoids.Print("|cffffaa00[@fov]|r farthestInFOV: cone=" .. tostring(CleveRoidMacros.fovCone) .. " (2-10, 越小越窄), range=" .. tostring(CleveRoidMacros.fovRange)
			.. (CleveRoids.hasUnitXPFOV and "  |cff00ff00(UnitXP_SP3_X 可用)|r" or "  |cffff0000(需 UnitXP_SP3_X，否则回退当前目标)|r"))
		CleveRoids.Print("用法: /cleveroid fov <cone 2-10> <range>   |   宏: /cast [@fov] 瞄准射击")
		return
	end

	-- 引导打断模式 by 武藤纯子酱 2026.9.12
	if cmd == "clip" then
		local m = tonumber(val)
		if m and m >= 1 and m <= 3 then CleveRoidMacros.clipMode = m end
		local mode = CleveRoidMacros.clipMode or 2
		CleveRoids.Print("|cffffaa00引导打断模式|r = " .. mode
			.. "   (1=不打断; 2=仅含引导计时的行且能成功才打断; 3=条件通过即打断)  |cff808080默认 2|r")
		CleveRoids.Print("用法: /cleveroid clip <1|2|3>   |   例: 宏 /cast [channeltime:>2] 心灵震爆 在模式 2 下可二段鞭")
		return
	end

	-- 免疫自动学习开关（默认关，使用内置静态免疫表）by 武藤纯子酱 2026.9.16
	if cmd == "immunitylearn" or cmd == "ilearn" then
		if val == "0" or val == "1" then
			CleveRoidMacros.autoLearnImmunity = tonumber(val)
		elseif val ~= "" then
			CleveRoids.Print("用法: /cleveroid immunitylearn 0|1")
			return
		end
		CleveRoids.Print("|cffffaa00免疫自动学习|r = " .. (CleveRoidMacros.autoLearnImmunity or 0)
			.. "   (0=关(默认,用内置静态免疫表); 1=开(战斗中从日志学习))")
		return
	end

    -- Delegate to extension console handlers (chain pattern)
    if CleveRoids.HandleConsoleCommand then
        CleveRoids.HandleConsoleCommand(msg)
        return
    end

    -- Unknown command fallback
    CleveRoids.Print("Usage:")
    DEFAULT_CHAT_FRAME:AddMessage("/cleveroid - Show current settings")
    DEFAULT_CHAT_FRAME:AddMessage("/cleveroid realtime 0 or 1 - Force realtime updates (Default: 0. 1 = on, increases CPU load)")
    DEFAULT_CHAT_FRAME:AddMessage("/cleveroid refresh X - Set refresh rate (1 to 10 updates per second. Default: 5)")
    DEFAULT_CHAT_FRAME:AddMessage("/cleveroid learn <spellID> <duration> - Manually set spell duration")
    DEFAULT_CHAT_FRAME:AddMessage("/cleveroid forget <spellID|all> - Forget learned duration(s)")
    DEFAULT_CHAT_FRAME:AddMessage("/cleveroid debug [0|1] - Toggle learning debug messages")
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Immunity Tracking:|r")
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid listimmune [school] - List immunity data')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid addimmune "<NPC>" <school> [buff] - Add immunity')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid removeimmune "<NPC>" <school> - Remove immunity')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid clearimmune [school] - Clear immunity data')
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00CC Immunity Tracking:|r")
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid listccimmune [type] - List CC immunity data')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid addccimmune "<NPC>" <type> [buff] - Add CC immunity')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid removeccimmune "<NPC>" <type> - Remove CC immunity')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid clearccimmune [type] - Clear CC immunity data')
    DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00Combo Point Tracking:|r")
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid combotrack - Show combo point tracking info')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid comboclear - Clear combo tracking data')
    DEFAULT_CHAT_FRAME:AddMessage('/cleveroid combolearn - Show learned combo durations (per CP)')
end

SLASH_CLEAREQUIPQUEUE1 = "/clearequipqueue"
SlashCmdList.CLEAREQUIPQUEUE = function()
    -- Release all entries back to pool
    for i = 1, CleveRoids.equipmentQueueLen do
        local entry = CleveRoids.equipmentQueue[i]
        if entry then
            CleveRoids.equipmentQueue[i] = nil
            -- Return to pool if space available
            if table.getn(CleveRoids.queueEntryPool) < 10 then
                entry.item = nil
                entry.slotName = nil
                entry.inventoryId = nil
                table.insert(CleveRoids.queueEntryPool, entry)
            end
        end
    end
    CleveRoids.equipmentQueueLen = 0
    if CleveRoids.equipQueueFrame then
        CleveRoids.equipQueueFrame:Hide()
    end
    CleveRoids.Print("Equipment queue cleared")
end

SLASH_EQUIPQUEUESTATUS1 = "/equipqueuestatus"
SlashCmdList.EQUIPQUEUESTATUS = function()
    local count = CleveRoids.equipmentQueueLen
    CleveRoids.Print("Equipment queue has " .. count .. " pending items")

    for i = 1, count do
        local entry = CleveRoids.equipmentQueue[i]
        if entry then
            local itemName = (entry.item and entry.item.name) or "Unknown"
            local slotName = entry.slotName or "Unknown"
            local retries = entry.retries or 0
            CleveRoids.Print(i .. ". " .. itemName .. " -> " .. slotName .. " (retries: " .. retries .. ")")
        end
    end
end

-- Apply temporary weapon enchants (poisons, oils, sharpening stones, etc.)
-- Usage: /applymain [conditionals] ItemName
-- Usage: /applyoff [conditionals] ItemName
-- Example: /applymain [nomhimbue] Instant Poison
-- Example: /applyoff [combat] Crippling Poison

local function FindItemInBags(itemName)
    -- Require a non-empty item name to prevent matching everything
    if not itemName or itemName == "" then
        return nil
    end

    local searchName = string.lower(itemName)
    for bag = 0, 4 do
        -- 修复：GetContainerNumSlots 对空容器可能返回 nil，加 or 0 兜底（与代码库他处一致） by 武藤纯子酱 2026.8.31
        for slot = 1, (GetContainerNumSlots(bag) or 0) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, foundName = string.find(link, "%[(.+)%]")
                if foundName and string.find(string.lower(foundName), searchName, 1, true) then
                    return bag, slot, foundName
                end
            end
        end
    end
    return nil
end

function CleveRoids.DoApply(hand, msg)
    local weaponSlots = {
        ["main"] = 16,
        ["off"] = 17,
    }

    local slot = weaponSlots[hand]
    if not slot then
        CleveRoids.Print("Invalid hand: " .. tostring(hand))
        return false
    end

    local action = function(itemName)
        local bag, bagSlot, foundName = FindItemInBags(itemName)
        if not bag then
            CleveRoids.Print("Item not found: " .. itemName)
            return false
        end

        -- Apply the item to the weapon
        UseContainerItem(bag, bagSlot)
        PickupInventoryItem(slot)
        ReplaceEnchant()
        ClearCursor()
        return true
    end

    local handled = false
    for _, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            -- If /firstaction was used, stop macro evaluation after first successful apply
            if CleveRoids.stopOnCastFlag then
                CleveRoids.stopMacroFlag = true
            end
            handled = true
            break
        end
    end
    return handled
end

SLASH_APPLYMAIN1 = "/applymain"
SlashCmdList.APPLYMAIN = function(msg)
    -- Require an item name argument
    if not msg or msg == "" or string.gsub(msg, "%s+", "") == "" then
        CleveRoids.Print("Usage: /applymain [conditionals] ItemName")
        return
    end
    CleveRoids.DoApply("main", msg)
end

SLASH_APPLYOFF1 = "/applyoff"
SlashCmdList.APPLYOFF = function(msg)
    -- Require an item name argument
    if not msg or msg == "" or string.gsub(msg, "%s+", "") == "" then
        CleveRoids.Print("Usage: /applyoff [conditionals] ItemName")
        return
    end
    CleveRoids.DoApply("off", msg)
end

-- 新增 by 武藤纯子酱 2025.11.26
-- /castrandom
function CleveRoids.DoConditionalCastRandom(action,msg)
    if not string.find(msg, "%[") then return false end

    local handled = false

    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        if CleveRoids.DoWithConditionals(v, nil, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end
    return handled
end

-- /switch
function CleveRoids.DoSwitch(msg)
    local handled

    local action = function()
        PickupInventoryItem(16)
        PickupInventoryItem(17)
    end

    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /equipslot
function CleveRoids.DoEquipSlot(msg)
    local handled -- 修复：原初始化为 false 使 `handled == nil` 兜底分支永不执行，改为 nil by 武藤纯子酱 2026.9.11
	
	local action = function(args)
		-- 修复：无参调用（如裸写 /equipslot，或兜底 action()）时 args 为 nil，string.match(nil,...) 会抛错 by 武藤纯子酱 2026.9.12
		if type(args) ~= "string" then return false end
		-- args是经过条件解析后的字符串（槽位编号和物品名）
		-- 将args拆分成槽位和物品名
		local slotId, itemName = string.match(args, "^(%d+)%s+(.+)")
		if slotId and itemName then
			slotId = tonumber(slotId)
			itemName = CleveRoids.Trim(itemName)
			if slotId < 1 or slotId > 19 then
				CleveRoids.Print("Invalid slot ID: "..tostring(slotId))
				return false
			end
			return CleveRoids.EquipItemToSlot(itemName, slotId)
		else
			return false
		end
	end
	
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false -- 修复：每轮重置，条件不通过时不再误触发兜底 action()（否则会以 nil 参数崩溃） by 武藤纯子酱 2026.9.11
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end
	
    if handled == nil then
        action()
    end
	
    return handled
end

-- /autoshoot、/shootattack：等价 /cast !自动射击、/cast !射击（! 反切换，支持 [条件]）by 武藤纯子酱 2026.9.16
function CleveRoids.DoBangCast(msg, spellName)
    local m = CleveRoids.Trim(msg or "")
    local line = ((m ~= "" and m .. " " or "") .. "!" .. spellName)
    return CleveRoids.DoCast(line)
end

-- /stopshoot：关闭自动射击/射击（不带 ! 施放即切换关闭）by 武藤纯子酱 2026.9.16
function CleveRoids.DoStopShoot(msg)
    local m = CleveRoids.Trim(msg or "")
    local prefix = (m ~= "" and (m .. " ") or "")
    if not CleveRoids.CheckChanneled(CleveRoids.Localized.AutoShot) then
        CleveRoids.DoCast(prefix .. CleveRoids.Localized.AutoShot)
    end
    if not CleveRoids.CheckChanneled(CleveRoids.Localized.Shoot) then
        CleveRoids.DoCast(prefix .. CleveRoids.Localized.Shoot)
    end
end

-- /pickup：拿起装备栏/背包物品（支持 [条件]）by 武藤纯子酱 2026.9.16
function CleveRoids.DoPickup(msg)
    msg = msg or ""
    local handled
    local action = function(args)
        args = CleveRoids.Trim(args or "")
        if args == "" then return false end
        local slot = tonumber(args)
        if slot and slot >= 0 and slot <= 19 then
            ClearCursor()
            PickupInventoryItem(slot)
            return true
        end
        local API = CleveRoids.NampowerAPI
        if type(API) == "table" and type(API.features) == "table" and API.features.hasFindPlayerItemSlot then
            local info = API.FindItemFast(tonumber(args) or args)
            if info then
                ClearCursor()
                if info.inventoryID then
                    PickupInventoryItem(info.inventoryID)
                elseif info.bagID and info.slot then
                    PickupContainerItem(info.bagID, info.slot)
                end
                return true
            end
        else
            local bag, bslot = FindItemInBagsByName(args)
            if bag then
                ClearCursor()
                PickupContainerItem(bag, bslot)
                return true
            end
        end
        return false
    end
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        handled = false
        if CleveRoids.DoWithConditionals(parts[i], action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end
    if handled == nil then action(msg) end
    return handled
end

-- /click：模拟点击有名字的 UI 按钮。1.12 客户端既无 /click 命令，也无全局 ClickButton()，
-- 但 Button/CheckButton 有 widget 方法 :Click([鼠标键])（本目录内多数 1.12 插件即此法），
-- 另以 GetScript("OnClick")() 兜底（个别按钮无 Click 方法）。
-- 用法：/click <按钮名> [鼠标键]；鼠标键可写 1/2/3/4/5 或 LeftButton/RightButton/MiddleButton by 武藤纯子酱 2026.9.23
function CleveRoids.DoClick(msg)
    msg = msg or ""
    local handled
    local action = function(args)
        args = CleveRoids.Trim(args or "")
        if args == "" then return false end

        local name, btnArg = string.match(args, "^(%S+)%s*(%S*)$")
        if not name then return false end

        local frame = getglobal(name)
        if not frame then return false end

        -- 鼠标键参数（可选）
        local button
        if btnArg and btnArg ~= "" then
            local n = tonumber(btnArg)
            if n == 1 then button = "LeftButton"
            elseif n == 2 then button = "RightButton"
            elseif n == 3 then button = "MiddleButton"
            elseif n and n >= 4 and n <= 5 then button = "Button" .. n
            elseif string.find(btnArg, "^%a") then button = btnArg end
        end

        -- 1) widget 方法：1.12 的“模拟点击”API
        if type(frame.Click) == "function" then
            frame:Click(button or "LeftButton")
            return true
        end
        -- 2) 兜底：直接调用 OnClick 脚本
        if frame.GetScript then
            local ok, fn = pcall(frame.GetScript, frame, "OnClick")
            if ok and type(fn) == "function" then
                fn()
                return true
            end
        end
        return false
    end
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        handled = false
        if CleveRoids.DoWithConditionals(parts[i], action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end
    if handled == nil then action(msg) end
    return handled
end

-- /threshold：设置/显示拾取品质门槛（0=灰 1=白 2=绿 3=蓝 4=紫 5=橙…），
-- 低于门槛的物品按队伍分配规则自动分配。1.12 客户端无 /threshold 命令，但
-- API SetLootThreshold/GetLootThreshold 存在。用法：/threshold <n>；无参显示当前值。支持 [条件] by 武藤纯子酱 2026.9.23
function CleveRoids.DoThreshold(msg)
    msg = msg or ""
    local handled
    local action = function(args)
        args = CleveRoids.Trim(args or "")
        if args == "" then
            local cur = (GetLootThreshold and GetLootThreshold()) or "?"
            CleveRoids.Print("当前拾取门槛 = " .. tostring(cur))
            return true
        end
        local n = tonumber(args)
        if not n or n < 0 or n > 7 then return false end
        local ok, err = pcall(SetLootThreshold, n)
        if not ok then
            CleveRoids.Print("|cffff0000设置拾取门槛失败：|r" .. tostring(err))
            return false
        end
        CleveRoids.Print("拾取门槛 → " .. tostring(n))
        return true
    end
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        handled = false
        if CleveRoids.DoWithConditionals(parts[i], action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end
    if handled == nil then action(msg) end
    return handled
end

-- 在已装备栏位(1-19)中按物品名或物品ID 查找，返回栏位号或 nil by 武藤纯子酱 2026.9.16
function CleveRoids.FindEquippedSlot(str)
    if not str or str == "" then return nil end
    local wantId = tonumber(str)
    local wantName = (not wantId) and string.lower(CleveRoids.Trim(str)) or nil
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            if wantId then
                local _, _, id = string.find(link, "item:(%d+)")
                if id and tonumber(id) == wantId then return slot end
            elseif wantName and wantName ~= "" then
                local _, _, name = string.find(link, "%[(.+)%]")
                if name and string.find(string.lower(name), wantName, 1, true) then return slot end
            end
        end
    end
    return nil
end

-- /unequip：卸下装备（支持栏位 1 / 1,2,3 / 1-10，或物品名 / 物品ID，支持 [条件]）by 武藤纯子酱 2026.9.16
function CleveRoids.DoUnequip(msg)
    msg = msg or ""
    local handled
    local action = function(args)
        args = CleveRoids.Trim(args or "")
        if args == "" then return false end

        -- 1) 栏位表达式（纯数字/逗号/范围）：单个值若 >19 则视为物品 ID
        local isSlotExpr = string.find(args, "^[%d,%-%s]+$") ~= nil
        if isSlotExpr then
            local num = tonumber(args)
            if num and (num < 1 or num > 19) then isSlotExpr = false end
        end
        if isSlotExpr then
            local slots = {}
            local from, to = string.match(args, "^(%d+)%s*%-%s*(%d+)$")
            if from and to then
                from, to = tonumber(from), tonumber(to)
                if from <= to then
                    for i = from, to do table.insert(slots, i) end
                end
            else
                for numStr in string.gmatch(args, "(%d+)") do
                    table.insert(slots, tonumber(numStr))
                end
            end
            for i = 1, table.getn(slots) do
                local s = slots[i]
                if s >= 1 and s <= 19 then
                    ClearCursor()
                    PickupInventoryItem(s)
                    PutItemInBackpack()
                end
            end
            return true
        end

        -- 2) 物品名 / 物品ID：在已装备栏位中查找后卸下
        local slot = CleveRoids.FindEquippedSlot(args)
        if slot then
            ClearCursor()
            PickupInventoryItem(slot)
            PutItemInBackpack()
            return true
        end
        CleveRoids.Print("|cffff0000[/unequip]|r 未找到已装备的物品: " .. args)
        return false
    end
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        handled = false
        if CleveRoids.DoWithConditionals(parts[i], action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end
    if handled == nil then action(msg) end
    return handled
end

-- /follow：跟随目标（支持 [条件]）by 武藤纯子酱 2026.9.16
function CleveRoids.DoFollow(msg)
    msg = msg or ""
    local function doFollow(name)
        name = CleveRoids.Trim(name or "")
        if name ~= "" and FollowByName then
            FollowByName(name) -- SuperWoW：按名字跟随
        elseif CleveRoids.Hooks.FOLLOW_SlashCmd then
            CleveRoids.Hooks.FOLLOW_SlashCmd(name)
        end
    end
    local handled
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)
    for i = 1, table.getn(parts) do
        handled = false
        if CleveRoids.DoWithConditionals(parts[i], doFollow, CleveRoids.FixEmptyTarget, false, doFollow) then
            handled = true
            break
        end
    end
    if handled == nil then doFollow("") end
    return handled
end

-- /assist
function CleveRoids.DoAssist(msg)
    return CleveRoids.DoConditionalTargeting(msg, function(name)
        if name and name ~= "" then
			if CleveRoids.hasNampowerGuidAPI then
				local targetguid = CleveRoids.GetGUID("target")
				if targetguid and CleveRoids.AssistsUnit[name] and CleveRoids.AssistsUnit[name] == targetguid then
					return
				end
			end
			
			if UnitName("target") ~= name and name ~= "" then
				TargetByName(name, true)
			end
			if not UnitCanAssist("player", "target") then
				TargetLastTarget()
			else
				if CleveRoids.hasNampowerGuidAPI then
					local assitsunitname = UnitName("target")
					local assitsunittarget = CleveRoids.GetGUID("targettarget")
					if assitsunitname and assitsunittarget then CleveRoids.AssistsUnit[assitsunitname] = assitsunittarget end
				end				
				TargetUnit("targettarget")
			end			
        else
			if UnitCanAssist("player", "target") and UnitExists("targettarget") then
				if CleveRoids.hasNampowerGuidAPI then
					local assitsunitname = UnitName("target")
					local assitsunittarget = CleveRoids.GetGUID("targettarget")
					if assitsunitname and assitsunittarget then CleveRoids.AssistsUnit[assitsunitname] = assitsunittarget end
				end	
				TargetUnit("targettarget")
			end
        end  
    end, false)
end
 
-- /targetenemy
function CleveRoids.DoTargetEnemy(msg)
    return CleveRoids.DoConditionalTargeting(msg, function(name)
        -- name ~= "" 防止 TargetByName("") 报 "Usage: TargetByName" by 武藤纯子酱 2026.9.9
        if name and name ~= "" then
            TargetByName(name, true)
        else
            TargetNearestEnemy()
        end
    end, false)
end
 
-- /targetenemyplayer
function CleveRoids.DoTargetEnemyPlayer(msg)
    return CleveRoids.DoConditionalTargeting(msg, function(name)
        if name and name ~= "" then
            TargetByName(name, true)
			if not UnitIsPlayer("target") then
				TargetLastTarget()
			end
        else

            local hasPlayers = false
            for i = 1, 20 do
                TargetNearestEnemy()
                if UnitExists("target") and UnitIsPlayer("target") then
                    hasPlayers = true
                    break
                end
            end
            
            if not hasPlayers then
                TargetLastTarget()
            end
        end
    end, false)
end
 
-- /targetfriend
function CleveRoids.DoTargetFriend(msg)
    return CleveRoids.DoConditionalTargeting(msg, function(name)
        -- name ~= "" 防止 TargetByName("") 报 "Usage: TargetByName" by 武藤纯子酱 2026.9.9
        if name and name ~= "" then
            TargetByName(name, true)
        else
            TargetNearestFriend()
        end
    end, true)
end
 
-- /targetfriendplayer
function CleveRoids.DoTargetFriendPlayer(msg)
    return CleveRoids.DoConditionalTargeting(msg, function(name)
        if name and name ~= "" then
            TargetByName(name, true)
			if not UnitIsPlayer("target") then
				TargetLastTarget()
			end			
        else

            local hasPlayers = false
            for i = 1, 20 do
                TargetNearestFriend()
                if UnitExists("target") and UnitIsPlayer("target") then
                    hasPlayers = true
                    break
                end
            end
            
            if not hasPlayers then
                TargetLastTarget()
            end
        end
    end, true)
end

-- /targetlastenemy
function CleveRoids.DoTargetLastEnemy(msg)
    local handled

    local action = TargetLastEnemy

    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end


-- /targetlastfriend
function CleveRoids.DoTargetLastFriend(msg)
    local handled

    local action = function()
		if CleveRoids.LastFriendTarget then
			TargetUnit(CleveRoids.LastFriendTarget)
		end
	end

    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end
 
-- /targetlasttarget
function CleveRoids.DoTargetLastTarget(msg)
    local handled

    local action = TargetLastTarget

    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end
 
-- /targetparty
function CleveRoids.DoTargetParty(msg)
    local handled

    local action = function(name)
        if not name or name == "" then return end
        TargetByName(name, true)
        
        -- Validate target is in party
        if not CleveRoids.IsTargetInGroupType("target", "party") then
            TargetLastTarget()
        end
    end

    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end
 
-- /targetraid
function CleveRoids.DoTargetRaid(msg)
    local handled

    local action = function(name)
        if not name or name == "" then return end
        TargetByName(name, true)
        
        -- Validate target is in raid
        if not CleveRoids.IsTargetInGroupType("target", "raid") then
            TargetLastTarget()
        end
    end

    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /targetexact
function CleveRoids.DoTargetExact(msg)
    local handled
    
    local action = function(name)
        if not name or name == "" then return end
		
        -- 保存当前目标
        local prevTarget = UnitExists("target") and UnitName("target")
        
        -- 尝试精确匹配目标
        TargetByName(name, true)
        
        -- 检查是否精确匹配
        if UnitExists("target") and UnitName("target") == name then
            return true
        else
            -- 恢复之前的目标
            if prevTarget then
                TargetLastTarget()
            else
                ClearTarget()
            end
            return false
        end
    end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /petautocastoff
function CleveRoids.DoPetAutoCastOff(msg)
    local handled
    
    local action = function(name)
        if not name or name == "" then 
			return 
		end

		for i=1,10 do 
			local spellname,_,_,_,_,_,autocast = GetPetActionInfo(i)
			
			if spellname == name and autocast then 
				TogglePetAutocast(i)
			end
		end

    end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /petautocaston
function CleveRoids.DoPetAutoCastOn(msg)
    local handled
    
    local action = function(name)
        if not name or name == "" then 
			return 
		end

		for i=1,10 do 
			local spellname,_,_,_,_,_,autocast = GetPetActionInfo(i)
			
			if spellname == name and not autocast then 
				TogglePetAutocast(i)
			end
		end

    end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /petautocasttoggle
function CleveRoids.DoPetAutoCastToggle(msg)
    local handled
    
    local action = function(name)
        if not name or name == "" then 
			return 
		end

		for i=1,10 do 
			local spellname,_,_,_,_,_,autocast = GetPetActionInfo(i)
			
			if spellname == name then 
				TogglePetAutocast(i)
			end
		end

    end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /mount
function CleveRoids.DoMount(msg)
    local handled
    
    local action = function(name)
        if not name or name == "" then 
			return 
		end
		
		for tabIndex = 1, GetNumSpellTabs() do
			local _, texture, offset, numSpells = GetSpellTabInfo(tabIndex)
			if texture and strfind(texture,"Ability_Mount_RidingHorse") then
				for spellIndex = offset + 1, offset + numSpells do
					-- 修复：GetSpellName 第二参应为法术书类型（此处 tabIndex 是页号，
					-- 法术名可能为 nil）→ strfind(name, nil) 崩溃；加守卫 + plain 匹配
					-- （技能名含模式字符时防 "malformed pattern"）by 武藤纯子酱 2026.9.9
					local spellname = GetSpellName(spellIndex,BOOKTYPE_SPELL)
					if spellname and strfind(name,spellname,1,true) then
						-- 修复：CastSpell 第二参应为法术书类型 BOOKTYPE_SPELL，不是页号 tabIndex
						-- by 武藤纯子酱 2026.9.11
						CastSpell(spellIndex,BOOKTYPE_SPELL)
						break
					end
				end
				break
			end
		end
		
    end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /dismount
function CleveRoids.DoDismount(msg)
    local handled
    
    local action = function()

		for i = 0, 31 do -- 遍历所有buff栏位
			local texture = GetPlayerBuffTexture(i)

			if texture then
				-- 通过工具提示检测坐骑
				
				CleveRoids.Scanner:ClearLines()
				CleveRoids.Scanner:SetPlayerBuff(i)
				local tipText = CleverDismountScannerTextLeft2:GetText()
				-- 匹配速度描述关键词
				for _, pattern in ipairs(CleveRoids.MountPatterns) do
					if tipText and string.find(tipText, pattern) then
						CancelPlayerBuff(i)
						return
					end
				end
				
			end
		end

    end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action()
    end

    return handled
end

-- /changeactionbar
function CleveRoids.DoChangeActionBar(msg)
    local handled
    
    local action = function(args)
		local page = tonumber(args)
		if page and page >= 1 and page <= 6 then
			CURRENT_ACTIONBAR_PAGE = page
			ChangeActionBarPage()
			return true
		end
		return false
	end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action(CleveRoids.GetParsedMsg(msg))
    end

    return handled
end

-- /swapactionbar
function CleveRoids.DoSwapActionBar(msg)
    local handled
    
    local action = function(args)
		-- 修复：无参调用（如裸写 /swapactionbar）时 args 为 nil，string.match(nil,...) 会抛错 by 武藤纯子酱 2026.9.12
		if type(args) ~= "string" then return false end
		local bar1, bar2 = string.match(args, "(%d+)%s+(%d+)")
		bar1, bar2 = tonumber(bar1), tonumber(bar2)
            
		if bar1 and bar2 and bar1 >= 1 and bar1 <= 6 and bar2 >= 1 and bar2 <= 6 then
			if CURRENT_ACTIONBAR_PAGE == bar1 then
				CURRENT_ACTIONBAR_PAGE = bar2
			else
				CURRENT_ACTIONBAR_PAGE = bar1
			end
			ChangeActionBarPage()
			return true
		end
		return false
	end
    
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, CleveRoids.FixEmptyTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action(CleveRoids.GetParsedMsg(msg))
    end

    return handled
end

-- /feed
function CleveRoids.DoFeed(msg)
    local handled = false
    
    -- 只有猎人可以喂养宠物
    if CleveRoids.playerClass ~= "HUNTER" then return false end
 
    local action = function(foodName)
        if UnitAffectingCombat("player") or UnitAffectingCombat("pet") or not UnitExists("pet") or UnitIsDead("pet") then
            return false
        end
        
        -- 使用指定的食物喂养宠物
        local item = CleveRoids.GetItem(foodName)

        -- 槽位缺失（如 GetItemInfo 兜底条目 / 索引未建）→ 强制重建索引后再取一次 by 武藤纯子酱 2026.9.28
        if (not item or (not item.bagID and not item.inventoryID)) and CleveRoids.IndexItems then
            CleveRoids.lastItemIndexTime = 0
            CleveRoids.IndexItems()
            item = CleveRoids.GetItem(foodName)
        end
        if not item or (not item.bagID and not item.inventoryID) then
            return false
        end
        
        -- 拾取食物并投放给宠物（背包物品先切到下一堆叠，避免当前堆用尽后一直拾空槽）
        if item.bagID then
            CleveRoids.GetNextBagSlotForUse(item, foodName)
            PickupContainerItem(item.bagID, item.slot)
        else
            PickupInventoryItem(item.inventoryID)
        end

        -- 没拾起任何东西 → 不算成功（原实现会假成功），并触发下次重建索引 by 武藤纯子酱 2026.9.28
        if not CursorHasItem() then
            CleveRoids.lastItemIndexTime = 0
            return false
        end

        DropItemOnUnit("pet")
        
        -- 检查是否成功投放
        if CursorHasItem() then
            -- 如果未能投放，将物品放回原处
            if item.bagID then
                PickupContainerItem(item.bagID, item.slot)
            else
                PickupInventoryItem(item.inventoryID)
            end
            return false
        else
            -- 成功喂养：本堆可能已用尽，触发下次尽快重建索引
            CleveRoids.lastItemIndexTime = 0
            return true
        end
    end
    
    -- 设置条件检查的默认目标为宠物
    local fixTarget = function(conditionals)
        conditionals.target = "pet"
        return false
    end
    
    -- 处理条件宏
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        handled = false
        if CleveRoids.DoWithConditionals(v, action, fixTarget, false, action) then
            handled = true
            break
        end
    end

    if handled == nil then
        action(CleveRoids.GetParsedMsg(msg))
    end

    return handled	
end

-- 执行一个命令字符串（以 / 开头）
function CleveRoids.ExecuteCommand(cmdText)
    if not cmdText or cmdText == "" then return false end
    cmdText = CleveRoids.Trim(cmdText)

    if string.sub(cmdText, 1, 1) ~= "/" then
        return false
    end

    local cmd, args = CleveRoids.SplitCommandAndArgs(cmdText)
    if not cmd then return false end

    local cmdName = string.sub(cmd, 2)

    -- 修复：防止递归调用自身必须在 handler 分派之前判断（原判断在分派之后，永不执行）
    -- by 武藤纯子酱 2026.9.11
    if cmdName == "crmrun" then
        return false
    end

    local handler = SlashCmdList and SlashCmdList[string.upper(cmdName)]
    if handler then
        handler(args or "")
        return true
    end

    -- 回退到聊天框发送（可能被其他插件捕获）
    ChatFrameEditBox:SetText(cmdText)
    ChatEdit_SendText(ChatFrameEditBox)
    return true
end

-- /crmrun 入口
function CleveRoids.DoCrmRun(msg)
    if not msg or msg == "" then return false end

    if CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag then
        return false
    end

    -- 按分号分割，忽略引号内的分号
    local parts = CleveRoids.splitStringIgnoringQuotes(msg, ";")
    if not parts or table.getn(parts) == 0 then
        return false
    end

    local anyExecuted = false

    for i = 1, table.getn(parts) do
        -- 每次循环检查停止标志
        if CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag then
            break
        end

        local part = parts[i]
        part = CleveRoids.Trim(part)
        if part ~= "" then
            local action = function(cmdText)
                if cmdText and cmdText ~= "" then
                    return CleveRoids.ExecuteCommand(cmdText)
                end
                return false
            end

            local result = CleveRoids.DoWithConditionals(part, action, CleveRoids.FixEmptyTarget, false, action)
            if result then
                anyExecuted = true
                -- 若 firstaction 模式启用，停止后续动作
                if CleveRoids.stopOnCastFlag then
                    CleveRoids.stopMacroFlag = true
                    break
                end
            end
        end
    end

    return anyExecuted
end

-- /sendmessage 命令处理 by 武藤纯子酱 2026.8.10
function CleveRoids.DoSendMessage(msg)
    if CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag then
        return false
    end
    if not msg or msg == "" then
        return false
    end

    local now = GetTime()
    if now - (CleveRoids.lastSendMessageTime or 0) < CleveRoids.SENDMESSAGE_CD then
        return false
    end

    local handled = false
    local parts = CleveRoids.splitStringIgnoringQuotes(msg)

    local function sendAction(actionText, conditionals)
        if not actionText or actionText == "" then
            return false
        end

        -- 确定发送类型
        local sendType
        if GetNumRaidMembers() > 0 then
            sendType = "RAID"
        elseif GetNumPartyMembers() > 0 then
            sendType = "PARTY"
        else
            sendType = "GUILD"
        end

        -- 获取目标 GUID
        local targetGuid = nil
        if conditionals.target then
            targetGuid = CleveRoids.GetGUID(conditionals.target)
        end
        if not targetGuid then
            targetGuid = CleveRoids.GetGUID("player")
        end

        -- 修复：targetGuid 均取不到时直接失败，避免 nil 拼接 by 武藤纯子酱 2026.9.11
        if not targetGuid then
            return false
        end

        local message = targetGuid .. "::" .. actionText
        SendAddonMessage(CleveRoids.MESSAGE_PREFIX, message, sendType)
        CleveRoids.lastSendMessageTime = GetTime()
        return true
    end

    for _, v in ipairs(parts) do
        -- 修复：将 sendAction 同时作为 hook 传入——无条件分支只调用 hook，原先 hook=nil
        -- 导致不带 [...] 的 /sendmessage 恒返回 true 却不发送 by 武藤纯子酱 2026.9.11
        if CleveRoids.DoWithConditionals(v, sendAction, CleveRoids.FixEmptyTarget, false, sendAction) then
            handled = true
            break
        end
    end

    return handled
end