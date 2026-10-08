--[[
    Author: Dennis Werner Garske (DWG) / brian / Mewtiny
    License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

-- Permanent cache for name normalization (underscores to spaces)
local _normalizedNames = {}

-- PERFORMANCE: Cache for lowercased normalized names (for case-insensitive comparisons)
local _lowerNormalizedNames = {}

-- Cached name normalization
function CleveRoids.NormalizeName(name)
    if not name then return name end
    local c = _normalizedNames[name]
    if c then return c end
    c = string.gsub(name, "_", " ")
    _normalizedNames[name] = c
    return c
end

-- PERFORMANCE: Cached lowercase normalization (underscores to spaces + lowercase)
local function GetLowerNormalizedName(name)
    if not name then return name end
    local c = _lowerNormalizedNames[name]
    if c then return c end
    c = string.lower(string.gsub(name, "_", " "))
    _lowerNormalizedNames[name] = c
    return c
end

-- PERFORMANCE: Cache for lowercased strings
local _lowercaseCache = {}
local function GetLowercaseString(str)
    if not str then return str end
    local c = _lowercaseCache[str]
    if c then return c end
    c = string.lower(str)
    _lowercaseCache[str] = c
    return c
end

-- Direct passthrough functions (no caching overhead for normal usage)
function CleveRoids.GetCachedTime()
    return GetTime()
end

function CleveRoids.GetCachedPlayerHealthPercent()
    local API = CleveRoids.NampowerAPI
    local hp = API and API.GetUnitHealth and API.GetUnitHealth("player") or UnitHealth("player")
    local max = API and API.GetUnitMaxHealth and API.GetUnitMaxHealth("player") or UnitHealthMax("player")
    return max > 0 and (100 * hp / max) or 0
end

function CleveRoids.GetCachedPlayerPowerPercent()
    local API = CleveRoids.NampowerAPI
    local power = API and API.GetUnitPower and API.GetUnitPower("player") or UnitMana("player")
    local max = API and API.GetUnitMaxPower and API.GetUnitMaxPower("player") or UnitManaMax("player")
    return max > 0 and (100 * power / max) or 0
end

function CleveRoids.GetCachedPlayerPower()
    local API = CleveRoids.NampowerAPI
    return API and API.GetUnitPower and API.GetUnitPower("player") or UnitMana("player")
end

function CleveRoids.GetCachedTargetHealthPercent()
    local API = CleveRoids.NampowerAPI
    local hp = API and API.GetUnitHealth and API.GetUnitHealth("target") or UnitHealth("target")
    local max = API and API.GetUnitMaxHealth and API.GetUnitMaxHealth("target") or UnitHealthMax("target")
    return max > 0 and (100 * hp / max) or 0
end

-- Cooldown uses original function directly
function CleveRoids.GetCachedCooldown(name, ignoreGCD)
    return CleveRoids._GetCooldownUncached(name, ignoreGCD)
end

-- No-ops for compatibility
function CleveRoids.ClearFrameCache() end
function CleveRoids.TrackButtonPress() end
function CleveRoids.GetCacheStats() return nil end
function CleveRoids.SetCacheTTL(ms) end
function CleveRoids.SetMacroThrottle(ms) end
function CleveRoids.GetMacroThrottle() return 0 end

-- ============================================================================
-- PERFORMANCE: Cache spell name -> spell ID mappings for debuff lookups
-- This avoids iterating personalDebuffs/sharedDebuffs and calling GetSpellRecField() repeatedly
local _spellNameToIDs = {}  -- [spellName] = { spellID1, spellID2, ... }
local _spellNameToIDsBuilt = false

-- Build the spell name to ID cache (called once on first debuff check)
local function BuildSpellNameCache()
    if _spellNameToIDsBuilt then return end
    _spellNameToIDsBuilt = true

    local lib = CleveRoids.libdebuff
    if not lib then return end

    local gsub = string.gsub

    if lib.personalDebuffs then
        for sid, _ in pairs(lib.personalDebuffs) do
            local name = GetSpellRecField(sid, "name")
            if name then
                name = CleveRoids.StripRank(name)
                if not _spellNameToIDs[name] then
                    _spellNameToIDs[name] = {}
                end
                table.insert(_spellNameToIDs[name], sid)
            end
        end
    end

    if lib.sharedDebuffs then
        for sid, _ in pairs(lib.sharedDebuffs) do
            local name = GetSpellRecField(sid, "name")
            if name then
                name = CleveRoids.StripRank(name)
                if not _spellNameToIDs[name] then
                    _spellNameToIDs[name] = {}
                end
                -- Avoid duplicates
                local found = false
                for _, existingId in ipairs(_spellNameToIDs[name]) do
                    if existingId == sid then found = true; break end
                end
                if not found then
                    table.insert(_spellNameToIDs[name], sid)
                end
            end
        end
    end
end

-- Get cached spell IDs for a spell name
local function GetSpellIDsForName(spellName)
    BuildSpellNameCache()
    -- Strip rank from input spell name to match cache keys
    -- This handles cases like "Faerie Fire (Feral)(Rank 4)" -> "Faerie Fire (Feral)"
    if spellName then
        spellName = CleveRoids.StripRank(spellName)
        -- Convert underscores to spaces for matching (e.g., "Thunder_Clap" -> "Thunder Clap")
        spellName = string.gsub(spellName, "_", " ")
    end
    return _spellNameToIDs[spellName]
end

-- Invalidate cache (call if debuff lists change)
function CleveRoids.InvalidateSpellNameCache()
    _spellNameToIDs = {}
    _spellNameToIDsBuilt = false
end

-- Get the specific spell ID for a given spell name and rank number
-- Returns: spellID or nil (if rank not found, caller falls back to rank-agnostic matching)
local function GetSpellIDForRank(baseName, rankNum)
    local matchIDs = GetSpellIDsForName(baseName)
    if not matchIDs then return nil end
    local targetRank = CleveRoids.Localized.SpellRanks["Rank "] .. rankNum -- 修复多语言支持 by 武藤纯子酱 2026.4.2
    for _, sid in ipairs(matchIDs) do
        local rank = GetSpellRecField and GetSpellRecField(sid, "rank")
        if rank and rank == targetRank then
            return sid
        end
    end
    return nil
end

-- Check if a debuff is shared by spell ID or by name (for custom/Turtle WoW IDs).
-- Falls back to checking if the debuff NAME matches any known shared debuff name
-- in the spell name cache, even if the specific spell ID is unregistered.
local function IsSharedDebuffByIdOrName(lib, spellID, debuffName)
    if not lib then return false end
    -- Direct ID check (fast path)
    if lib.IsPersonalDebuff and lib:IsPersonalDebuff(spellID) == false then
        return true
    end
    -- Name-based fallback: if ANY spell ID for this name is in sharedDebuffs, treat as shared.
    -- This handles custom server spell IDs (e.g., Turtle WoW Judgement variants) that have
    -- the same debuff name but different IDs from the hardcoded vanilla entries.
    if debuffName then
        local knownIDs = GetSpellIDsForName(debuffName)
        if knownIDs then
            for _, kid in ipairs(knownIDs) do
                if lib.sharedDebuffs and lib.sharedDebuffs[kid] then
                    -- Also register this new spell ID so future checks are fast
                    lib.sharedDebuffs[spellID] = lib.sharedDebuffs[kid]
                    return true
                end
            end
        end
    end
    return false
end

-- PERFORMANCE: Equipment cache for HasGearEquipped (avoids 19-slot scan per call)
-- Invalidated on UNIT_INVENTORY_CHANGED via CleveRoids.InvalidateEquipmentCache()
-- Enhanced with Nampower v2.18+ GetEquippedItems when available
local _equippedItemIDs = {}      -- [slot] = itemID (number)
local _equippedItemNames = {}    -- [slot] = itemName (lowercase string)
local _equipmentCacheValid = false

-- Track if we've warned about GetEquippedItems errors (warn once per session)
local _getEquippedItemsErrorWarned = false

local function BuildEquipmentCache()
    if _equipmentCacheValid then return end
    _equipmentCacheValid = true

    -- Clear old data
    for i = 1, 19 do
        _equippedItemIDs[i] = nil
        _equippedItemNames[i] = nil
    end

    local string_find = string.find
    local string_lower = string.lower

    -- Try Nampower GetEquippedItems for faster enumeration
    -- Requires v2.22+ because earlier versions (e.g., v2.19.1) have internal bug
    local API = CleveRoids.NampowerAPI
    local hasValidNampower = API and API.HasMinimumVersion and API.HasMinimumVersion(2, 22, 0)

    if hasValidNampower and GetEquippedItems then
        -- Use pcall to catch any internal Nampower errors and fall back gracefully
        local success, result = pcall(GetEquippedItems, "player")

        if not success then
            -- Log the error once per session for debugging
            if not _getEquippedItemsErrorWarned then
                _getEquippedItemsErrorWarned = true
                local errMsg = tostring(result)
                if CleveRoids.Print then
                    CleveRoids.Print("|cffff6600Warning:|r GetEquippedItems failed: " .. errMsg)
                    CleveRoids.Print("Using fallback equipment detection. Consider updating Nampower.")
                end
            end
            -- Fall through to manual enumeration
        elseif result and type(result) == "table" then
            local usedNampower = false
            for nampowerSlot, itemInfo in pairs(result) do
                -- Nampower uses 0-indexed slots, WoW API uses 1-indexed
                -- tonumber() handles both string and numeric keys from different Nampower versions
                -- Skip non-numeric keys (metadata fields, etc.)
                local slotNum = tonumber(nampowerSlot)
                if slotNum and type(itemInfo) == "table" and itemInfo.itemId then
                    -- GetEquippedItems 的键编号自动校准（不同 Nampower 版本可能 0-18 或 1-19），
                    -- 统一换算为 vanilla 槽位 1-19，避免战袍(19)丢失或整体错位 by 武藤纯子酱 2026.8.31
                    local slot = slotNum
                    if API and API.EquippedKeyToVanillaSlot then
                        slot = API.EquippedKeyToVanillaSlot(slotNum)
                    end
                    if slot >= 1 and slot <= 19 then
                        _equippedItemIDs[slot] = itemInfo.itemId
                        usedNampower = true

                        -- Get item name via Nampower API or GetItemInfo
                        local itemName = API and API.GetItemName and API.GetItemName(itemInfo.itemId)
                        if not itemName then
                            itemName = GetItemInfo(itemInfo.itemId)
                        end
                        if itemName then
                            _equippedItemNames[slot] = string_lower(itemName)
                        end
                    end
                end
            end
            if usedNampower then
                return  -- Done with Nampower path
            end
            -- Fall through to manual enumeration if Nampower returned userdata items
        end
    end

    -- Fallback: manual slot enumeration
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local _, _, id = string_find(link, "item:(%d+)")
            local _, _, nameInBrackets = string_find(link, "%[(.+)%]")

            if id then
                _equippedItemIDs[slot] = tonumber(id)
            end
            if nameInBrackets then
                _equippedItemNames[slot] = string_lower(nameInBrackets)
            elseif id then
                -- Fallback: resolve via GetItemInfo
                local itemName = GetItemInfo(tonumber(id))
                if itemName then
                    _equippedItemNames[slot] = string_lower(itemName)
                end
            end
        end
    end
end

-- Invalidate equipment cache (call on UNIT_INVENTORY_CHANGED)
function CleveRoids.InvalidateEquipmentCache()
    _equipmentCacheValid = false
end

-- ============================================================================
-- PERFORMANCE: Unified item location lookup using CleveRoids.Items cache
-- Returns: { type="inventory"|"bag", inventoryID=N } or { type="bag", bag=N, slot=N }
-- Returns nil if item not found
-- Enhanced with Nampower v2.18+ FindPlayerItemSlot when available
-- ============================================================================
local string_lower = string.lower
local string_find = string.find

-- Fast item lookup using cache - O(1) instead of O(n) scan
-- @param item: item ID (number) or item name (string)
-- @return table with location info, or nil if not found
function CleveRoids.FindItemLocation(item)
    -- Try Nampower v2.18+ native lookup first (much faster for item ID/name)
    if FindPlayerItemSlot and item then
        local numericItem = tonumber(item)

        -- Skip native lookup for equipment slot numbers (1-19)
        if not (numericItem and numericItem >= 1 and numericItem <= 19) then
            local bag, slot = FindPlayerItemSlot(item)

            if slot then
                if bag == nil then
                    -- Equipped item：装备槽编号自动校准（不同 Nampower 版本可能 0-18 或 1-19），
                    -- 最终换算为 GetInventoryItemCooldown 等 API 使用的 vanilla 槽位 1-19 by 武藤纯子酱 2026.8.31
                    local API = CleveRoids.NampowerAPI
                    local invSlot
                    if API and API.FindSlotToVanillaSlot then
                        invSlot = API.FindSlotToVanillaSlot(slot)
                    else
                        invSlot = slot + 1 -- 无校准能力时按文档（0-18，0 基）兜底 by 武藤纯子酱 2026.8.31
                    end
                    return { type = "inventory", inventoryID = invSlot }
                else
                    -- Bag item
                    return { type = "bag", bag = bag, slot = slot }
                end
            end
            -- Nampower authoritatively says item not found — return nil.
            -- Don't fall through to stale Items cache (consumed items would
            -- still appear there until the next IndexItems). Substring/alias
            -- matching is handled separately by HasItem's slow path.
            return nil
        end
    end

    -- Fallback to CleveRoids.Items cache (only when FindPlayerItemSlot unavailable)
    local Items = CleveRoids.Items
    if not Items then return nil end

    local itemData = nil

    -- Case 1: Numeric item ID
    local numericItem = tonumber(item)
    if numericItem then
        -- Check if it's an equipment slot (1-19)
        if numericItem >= 1 and numericItem <= 19 then
            local link = GetInventoryItemLink("player", numericItem)
            if link then
                return { type = "inventory", inventoryID = numericItem }
            end
            return nil
        end

        -- Look up by item ID in cache (Items[id] = name)
        local itemName = Items[numericItem]
        if itemName then
            itemData = Items[itemName]
        end
    else
        -- Case 2: String item name
        if type(item) == "string" and item ~= "" then
            -- Try exact match first, then lowercase
            itemData = Items[item]
            if not itemData or type(itemData) == "string" then
                local lowerItem = string_lower(item)
                local resolved = Items[lowerItem]
                if type(resolved) == "string" then
                    itemData = Items[resolved]
                elseif type(resolved) == "table" then
                    itemData = resolved
                end
            elseif type(itemData) == "string" then
                -- Resolve indirection (lowercase -> canonical name)
                itemData = Items[itemData]
            end
        end
    end

    if not itemData or type(itemData) ~= "table" then
        return nil
    end

    -- Return location info
    if itemData.inventoryID then
        return { type = "inventory", inventoryID = itemData.inventoryID, itemData = itemData }
    elseif itemData.bagID and itemData.slot then
        return { type = "bag", bag = itemData.bagID, slot = itemData.slot, itemData = itemData }
    end

    return nil
end

-- Fast item existence check using cache
-- @param item: item ID (number) or item name (string)
-- @return boolean
function CleveRoids.HasItemCached(item)
    return CleveRoids.FindItemLocation(item) ~= nil
end

-- Fast item cooldown lookup using cache
-- Enhanced with Nampower v2.18+ GetItemIdCooldown for detailed info
-- @param item: item ID (number) or item name (string)
-- @return remainingSeconds, totalDuration, enabled
function CleveRoids.GetItemCooldownCached(item)
    local location = CleveRoids.FindItemLocation(item)
    if not location then
        return 0, 0, 0
    end

    -- Try Nampower v2.18+ GetItemIdCooldown for more detailed info
    -- This requires knowing the item ID
    if GetItemIdCooldown then
        local itemId = nil

        -- Get item ID from location or input
        if location.itemData and location.itemData.id then
            itemId = location.itemData.id
        elseif type(item) == "number" and item > 19 then
            itemId = item
        else
            -- Extract item ID from inventory/bag link
            local link
            if location.type == "inventory" then
                link = GetInventoryItemLink("player", location.inventoryID)
            else
                link = GetContainerItemLink(location.bag, location.slot)
            end
            if link then
                local _, _, id = string.find(link, "item:(%d+)")
                if id then itemId = tonumber(id) end
            end
        end

        if itemId then
            local cdInfo = GetItemIdCooldown(itemId)
            if cdInfo then
                local remaining = (cdInfo.cooldownRemainingMs or 0) / 1000
                local duration = (cdInfo.individualDurationMs or cdInfo.categoryDurationMs or 0) / 1000
                local enabled = (cdInfo.isOnCooldown == 1) and 1 or 0
                return remaining, duration, enabled
            end
        end
    end

    -- Fallback to standard WoW API
    local start, duration, enable
    if location.type == "inventory" then
        start, duration, enable = GetInventoryItemCooldown("player", location.inventoryID)
    else
        start, duration, enable = GetContainerItemCooldown(location.bag, location.slot)
    end

    -- Normalize cooldown values
    start = tonumber(start) or 0
    duration = tonumber(duration) or 0
    enable = tonumber(enable) or 0

    if duration <= 0 or start <= 0 then
        return 0, 0, enable
    end

    local remaining = (start + duration) - GetTime()
    if remaining < 0 then remaining = 0 end

    return remaining, duration, enable
end

--This table maps stat keys to the functions that retrieve their values.
local stat_checks = {
    -- Base Stats (Corrected to use the 'effective' stat with gear)
    str = function() local _, effective = UnitStat("player", 1); return effective end,
    strength = function() local _, effective = UnitStat("player", 1); return effective end,
    agi = function() local _, effective = UnitStat("player", 2); return effective end,
    agility = function() local _, effective = UnitStat("player", 2); return effective end,
    stam = function() local _, effective = UnitStat("player", 3); return effective end,
    stamina = function() local _, effective = UnitStat("player", 3); return effective end,
    int = function() local _, effective = UnitStat("player", 4); return effective end,
    intellect = function() local _, effective = UnitStat("player", 4); return effective end,
    spi = function() local _, effective = UnitStat("player", 5); return effective end,
    spirit = function() local _, effective = UnitStat("player", 5); return effective end,

    -- Combat Ratings (Corrected to use UnitAttackPower and UnitRangedAttackPower)
    ap = function() local base, pos, neg = UnitAttackPower("player"); return base + pos + neg end,
    attackpower = function() local base, pos, neg = UnitAttackPower("player"); return base + pos + neg end,
    rap = function() local base, pos, neg = UnitRangedAttackPower("player"); return base + pos + neg end,
    rangedattackpower = function() local base, pos, neg = UnitRangedAttackPower("player"); return base + pos + neg end,
    healing = function() local _, h = CleveRoids.NampowerAPI.GetSpellPower(); return h or 0 end,
    healingpower = function() local _, h = CleveRoids.NampowerAPI.GetSpellPower(); return h or 0 end,

    -- Bonus Spell Damage by School (Nampower v2.31+ GetSpellPower)
    -- GetSpellPower() returns: physical, holy, fire, nature, frost, shadow, arcane
    arcane_power = function() return select(7, CleveRoids.NampowerAPI.GetSpellPower()) or 0 end,
    fire_power = function() return select(3, CleveRoids.NampowerAPI.GetSpellPower()) or 0 end,
    frost_power = function() return select(5, CleveRoids.NampowerAPI.GetSpellPower()) or 0 end,
    nature_power = function() return select(4, CleveRoids.NampowerAPI.GetSpellPower()) or 0 end,
    shadow_power = function() return select(6, CleveRoids.NampowerAPI.GetSpellPower()) or 0 end,

    -- Highest spell power across all schools
    spell_power = function()
        local p, h, fi, n, fr, s, a = CleveRoids.NampowerAPI.GetSpellPower()
        if p then
            return math.max(p, h, fi, n, fr, s, a)
        end
        return 0
    end,

    -- Defensive Stats
    armor = function() local _, effective = UnitArmor("player"); return effective end,
    defense = function()
        local base, modifier = UnitDefense("player")
        return (base or 0) + (modifier or 0)
    end,

    -- Resistances
    arcane_res = function() local _, val = UnitResistance("player", 7); return val end,
    fire_res = function() local _, val = UnitResistance("player", 3); return val end,
    frost_res = function() local _, val = UnitResistance("player", 5); return val end,
    nature_res = function() local _, val = UnitResistance("player", 4); return val end,
    shadow_res = function() local _, val = UnitResistance("player", 6); return val end
}

-- ============================================================================
-- PERFORMANCE: Specialized comparison functions to avoid closure allocation
-- These functions replace common patterns like:
--   return Or(t, function(v) return (i == tonumber(v)) end)
-- with:
--   return OrEqualsNumber(t, i)
-- ============================================================================

-- Or where any value equals target number (after tonumber conversion)
local function OrEqualsNumber(t, target)
    if type(t) ~= "table" then
        return tonumber(t) == target
    end
    local k, v = next(t)
    while k do
        if tonumber(v) == target then return true end
        k, v = next(t, k)
    end
    return false
end

-- 删除：OrEqualsStringLower / OrNotEqualsNumber 定义后从未被引用 by 武藤纯子酱 2026.9.11

-- And where ALL values do NOT equal target number (for negated conditionals with AND logic)
local function AndNotEqualsNumber(t, target)
    if type(t) ~= "table" then
        return tonumber(t) ~= target
    end
    local k, v = next(t)
    while k do
        if tonumber(v) == target then return false end
        k, v = next(t, k)
    end
    return true
end

-- PERFORMANCE: Avoid creating wrapper tables for single values
-- PERFORMANCE: All helpers use next() instead of pairs() to avoid iterator closure allocation.
-- In Lua 5.0 (WoW 1.12), pairs() creates a closure each call. These helpers are invoked
-- for every conditional keyword on every macro line during action evaluation.
local function And(t, func)
    if type(func) ~= "function" then return false end
    -- PERFORMANCE: Handle non-table case without allocation
    if type(t) ~= "table" then
        return func(t) and true or false
    end
    local k, v = next(t)
    while k do
        if not func(v) then return false end
        k, v = next(t, k)
    end
    return true
end

local function Or(t, func)
    if type(func) ~= "function" then return false end
    -- PERFORMANCE: Handle non-table case without allocation
    if type(t) ~= "table" then
        return func(t) and true or false
    end
    local k, v = next(t)
    while k do
        if func(v) then return true end
        k, v = next(t, k)
    end
    return false
end

-- ============================================================================
-- 施法时间/攻速公式支持 by 武藤纯子酱 2026.9.1
-- 数值比较位可直接写公式（独立命名，避免与 [casttime]/[channeltime] 等条件冲突）：
--   getcast(技能名) / getchannel(技能名) —— 实时施法/引导时间（0.1s TTL）
--   getmh() / getoh() / getranged()      —— 实时主手/副手/远程攻速（0.1s TTL）
-- 支持 + - * / 括号
-- 例：[casttime:end<getchannel(奥术飞弹)/6]、[delay:>=getcast(火球术)*2]
-- 数据源：NampowerAPI 的 CleveRoids_SpellCastInfo 信息表（未收录时惰性学习）；
-- 全部走 Nampower 实时 API 主路径（tooltip 字符串解析仅作一次性学习与兜底）
-- ============================================================================
-- 量解析：数字原样；公式字符串求值；普通字符串 tonumber（保持原行为）；失败返回 nil
local function ResolveConditionAmount(v)
    if type(v) ~= "string" then return v end
    if CleveRoids.IsSpellTimeFormula and CleveRoids.IsSpellTimeFormula(v) then
        if CleveRoids.EvaluateSpellTimeFormula then
            return CleveRoids.EvaluateSpellTimeFormula(v)
        end
        return nil
    end
    return tonumber(v)
end

-- 比较器包装（安全网）：量位置出现公式字符串时先求值再比较；
-- 公式求值失败 → 本次比较判 false；非公式字符串原样透传（字符串等值比较不受影响）
do
    local _wrapped = {}
    for _k, _fn in pairs(CleveRoids.comparators) do
        -- Lua 5.0.2 泛型 for 的循环变量在迭代间共享（闭包捕获到的是循环结束后的终态
        -- k=nil/v=nil），必须用 body 内 local 副本逐次捕获，否则所有比较器都变成 nil
        -- （曾导致 [getmh:...] 条件报 "attempt to call a nil value"）by 武藤纯子酱 2026.9.1
        local captured_fn = _fn
        _wrapped[_k] = function(a, b)
            if type(b) == "string" then
                if CleveRoids.IsSpellTimeFormula and CleveRoids.IsSpellTimeFormula(b) then
                    local v = CleveRoids.EvaluateSpellTimeFormula and CleveRoids.EvaluateSpellTimeFormula(b)
                    if not v then return false end
                    b = v
                end
            end
            return captured_fn(a, b)
        end
    end
    CleveRoids.comparators = _wrapped
end

-- Helper to choose And() or Or() based on operator metadata
-- For positive conditionals (hp, power, cooldown, etc.):
--   - OR separator (/) uses Or() logic -> ANY value can match
--   - AND separator (&) uses And() logic -> ALL values must match
local function Multi(t, func, conditionals, condition)
    if type(func) ~= "function" then return false end

    -- PERFORMANCE: Handle non-table case without allocation
    if type(t) ~= "table" then
        return func(t) and true or false
    end

    -- Check for grouped structure (multiple instances of same conditional)
    -- Groups are AND'd together, values within each group use group's operator
    if conditionals and conditionals._groups and conditionals._groups[condition] then
        local groups = conditionals._groups[condition]
        -- All groups must pass (AND between groups)
        -- PERFORMANCE: Use .n field (set at build time) instead of table.getn() O(n) scan
        local numGroups = groups.n or table.getn(groups)
        for gi = 1, numGroups do
            local group = groups[gi]
            local groupPassed = false
            local groupOp = group.operator or "OR"
            local values = group.values
            local numValues = group.n or table.getn(values)

            if groupOp == "AND" then
                -- AND within group: ALL values must match
                groupPassed = true
                for vi = 1, numValues do
                    if not func(values[vi]) then
                        groupPassed = false
                        break
                    end
                end
            else
                -- OR within group: ANY value can match
                for vi = 1, numValues do
                    if func(values[vi]) then
                        groupPassed = true
                        break
                    end
                end
            end

            -- If any group fails, the whole conditional fails (AND between groups)
            if not groupPassed then return false end
        end
        return true
    end

    -- Fallback: Check operator type from metadata (single group / backwards compat)
    local operatorType = "OR" -- default
    if conditionals and conditionals._operators and conditionals._operators[condition] then
        operatorType = conditionals._operators[condition]
    end

    if operatorType == "AND" then
        -- AND separator (&): ALL must match
        local k, v = next(t)
        while k do
            if not func(v) then return false end
            k, v = next(t, k)
        end
        return true
    else
        -- OR separator (/) [default]: ANY can match
        local k, v = next(t)
        while k do
            if func(v) then return true end
            k, v = next(t, k)
        end
        return false
    end
end

-- Helper to choose And() or Or() based on operator metadata
-- For negated conditionals (nomybuff, nozone, etc.), operators are FLIPPED (De Morgan's law):
--   - OR separator (/) [default]: ALL must be missing (e.g., nobuff:X/Y = no X AND no Y)
--   - AND separator (&): ANY can be missing (e.g., nobuff:X&Y = no X OR no Y)
-- This matches natural language: "no X or Y" intuitively means "neither X nor Y"
local function NegatedMulti(t, func, conditionals, condition)
    if type(func) ~= "function" then return false end

    -- PERFORMANCE: Handle non-table case without allocation
    if type(t) ~= "table" then
        return func(t) and true or false
    end

    -- Check for grouped structure (multiple instances of same conditional)
    -- Groups are AND'd together, values within each group use FLIPPED group operator (De Morgan)
    if conditionals and conditionals._groups and conditionals._groups[condition] then
        local groups = conditionals._groups[condition]
        -- All groups must pass (AND between groups)
        -- PERFORMANCE: Use .n field (set at build time) instead of table.getn() O(n) scan
        local numGroups = groups.n or table.getn(groups)
        for gi = 1, numGroups do
            local group = groups[gi]
            local groupPassed = false
            local groupOp = group.operator or "OR"
            local values = group.values
            local numValues = group.n or table.getn(values)

            -- FLIPPED from positive conditionals (De Morgan's law for intuitive behavior)
            if groupOp == "AND" then
                -- AND separator (&) FLIPPED: ANY negation can pass (missing at least one)
                for vi = 1, numValues do
                    if func(values[vi]) then
                        groupPassed = true
                        break
                    end
                end
            else
                -- OR separator (/) FLIPPED: ALL negations must pass (missing all)
                groupPassed = true
                for vi = 1, numValues do
                    if not func(values[vi]) then
                        groupPassed = false
                        break
                    end
                end
            end

            -- If any group fails, the whole conditional fails (AND between groups)
            if not groupPassed then return false end
        end
        return true
    end

    -- Fallback: Check operator type from metadata (single group / backwards compat)
    local operatorType = "OR" -- default
    if conditionals and conditionals._operators and conditionals._operators[condition] then
        operatorType = conditionals._operators[condition]
    end

    -- FLIPPED from positive conditionals (De Morgan's law for intuitive behavior)
    if operatorType == "AND" then
        -- AND separator (&): ANY negation can pass (missing at least one)
        local k, v = next(t)
        while k do
            if func(v) then return true end
            k, v = next(t, k)
        end
        return false
    else
        -- OR separator (/) [default]: ALL negations must pass (missing all)
        local k, v = next(t)
        while k do
            if not func(v) then return false end
            k, v = next(t, k)
        end
        return true
    end
end

-- ============================================================================
-- THREAT TRACKING (reads server data via CHAT_MSG_ADDON like TWThreat)
-- ============================================================================

-- Storage for threat data
CleveRoids.ThreatData = {
    playerName = UnitName("player"),
    threats = {},      -- [playerName] = { threat, perc, tank, melee }
    lastUpdate = 0,
}

-- Parse threat packet from server (same format as TWThreat)
-- Format: TWTv4=player1:tank:threat:perc:melee;player2:tank:threat:perc:melee;...
local function ParseThreatPacket(packet)
    local threatApi = "TWTv4="
    local startPos = string.find(packet, threatApi, 1, true)
    if not startPos then return end

    local playersString = string.sub(packet, startPos + string.len(threatApi))
    local playerName = CleveRoids.ThreatData.playerName

    -- Clear old data
    CleveRoids.ThreatData.threats = {}
    CleveRoids.ThreatData.lastUpdate = GetTime()

    -- Split by semicolon
    for playerData in string.gfind(playersString, "[^;]+") do
        -- Split by colon: player:tank:threat:perc:melee
        local parts = {}
        for part in string.gfind(playerData, "[^:]+") do
            table.insert(parts, part)
        end

        if parts[1] and parts[2] and parts[3] and parts[4] and parts[5] then
            local name = parts[1]
            local tank = parts[2] == "1"
            local threat = tonumber(parts[3]) or 0
            local perc = tonumber(parts[4]) or 0
            local melee = parts[5] == "1"

            CleveRoids.ThreatData.threats[name] = {
                threat = threat,
                perc = perc,
                tank = tank,
                melee = melee,
            }
        end
    end
end

-- Get player's threat percentage
function CleveRoids.GetPlayerThreatPercent()
    local playerName = CleveRoids.ThreatData.playerName
    -- 修复：playerName 在文件加载时抓取可能为 nil（角色名尚未就绪），且之后永不更新导致 [threat:*] 永远失败；
    -- 改为惰性补取 by 武藤纯子酱 2026.8.31
    if not playerName then
        playerName = UnitName("player")
        if playerName and playerName ~= "" then
            CleveRoids.ThreatData.playerName = playerName
        end
    end
    local data = playerName and CleveRoids.ThreatData.threats[playerName]
    if data then
        return data.perc
    end
    return nil
end

-- Create frame to listen for threat addon messages
local threatFrame = CreateFrame("Frame", "CleveRoidsThreatFrame")
threatFrame:RegisterEvent("CHAT_MSG_ADDON")
threatFrame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_ADDON" then
        -- arg1 = prefix, arg2 = message, arg3 = channel, arg4 = sender
        if arg2 and string.find(arg2, "TWTv4=", 1, true) then
            ParseThreatPacket(arg2)
        end
    end
end)

-- ============================================================================
-- AUTO-ATTACK EVENT TRACKING (Nampower v2.24+)
-- ============================================================================
-- Tracks player's melee swings and incoming attacks for conditionals:
--   [lastswing:crit/glancing/miss/dodge/parry/blocked/offhand]
--   [incominghit:crit/crushing/dodge/parry/blocked]
--   [buffcapped] / [debuffcapped]
-- Requires NP_EnableAutoAttackEvents=1 and NP_EnableAuraCastEvents=1 CVars

-- State tracking for player's outgoing melee swings
CleveRoids.LastSwing = {
    timestamp = 0,      -- GetTime() when swing occurred
    damage = 0,         -- Total damage dealt
    hitInfo = 0,        -- HitInfo bitfield
    victimState = 0,    -- VictimState enum
    blockedAmount = 0,  -- Amount blocked
    absorbAmount = 0,   -- Amount absorbed
    resistAmount = 0,   -- Amount resisted
    targetGuid = nil,   -- GUID of target hit
}

-- State tracking for incoming attacks on player
CleveRoids.LastIncomingHit = {
    timestamp = 0,
    damage = 0,
    hitInfo = 0,
    victimState = 0,
    blockedAmount = 0,
    absorbAmount = 0,
    resistAmount = 0,
    attackerGuid = nil,
}

-- Aura cap status tracking (from AURA_CAST events)
-- For player: 32 buff slots, 16 debuff slots
-- For enemy NPCs: 16 debuff slots + 32 overflow into buff slots = 48 total visual
CleveRoids.AuraCapStatus = {
    -- Player aura cap status
    playerBuffCapped = false,
    playerDebuffCapped = false,
    playerLastUpdate = 0,
    -- Target aura cap status (tracked per-GUID)
    targetCapStatus = {},  -- [guid] = { buffCapped, debuffCapped, timestamp }
    -- PERFORMANCE: Throttle cleanup to avoid O(n) scan on every aura event
    lastCleanupTime = 0,
}

-- Overflow buff tracking: buffs applied while buff-capped (v2.34+)
-- GetUnitField "aura" returns 48 slots: [1-32] = buff slots, [33-48] = debuff slots.
-- Beyond these 48 client slots, the server can hold additional overflow buffs with
-- no aura slot at all -- invisible to GetPlayerBuff and GetPlayerAuraDuration.
-- Populated from AURA_CAST_ON_SELF when auraCapStatus indicates buff bar full.
-- Format: [spellId] = { timestamp = GetTime(), durationSec = durationMs/1000 }
CleveRoids.OverflowBuffs = {}

-- All-caster aura duration tracking (from AURA_CAST events)
-- Tracks buff/debuff durations from ANY caster, not just player
-- Structure: [targetGuid][spellName][casterGuid] = { start, duration, spellId }
-- Aligned with pfUI's allAuraCasts multi-caster architecture
-- When pfUI 7.6+ is active, this table is unused — GetAuraTrackingData() reads
-- from pfUI.libdebuff_all_auras instead (which has full downrank protection).
CleveRoids.AllCasterAuraTracking = {}

-- Tracks spells that libdebuff has identified as downrank-blocked for the current target.
-- Populated via pfUI.libdebuff_downrank_blocked_hooks, cleared implicitly by time.
-- Structure: [targetGuid][spellName] = { castRank, activeRank, time }
CleveRoids.DownrankBlocked = CleveRoids.DownrankBlocked or {}

-- Unified accessor: returns per-spell caster table for a target GUID.
-- When pfUI 7.6+ is active, reads from pfUI.libdebuff_all_auras (field: .startTime)
-- and translates to our field names (.start). Falls back to AllCasterAuraTracking.
-- Returns: targetData table [spellName][casterGuid] = {...}, or nil
-- usePfUI: true if the returned data uses pfUI field names (.startTime instead of .start)
function CleveRoids.GetAuraTrackingData(targetGuid)
    if not targetGuid then return nil, false end

    -- pfUI path: read directly from pfUI's table (has downrank protection built-in)
    if CleveRoids.hasPfUI76 and pfUI and pfUI.libdebuff_all_auras then
        local data = pfUI.libdebuff_all_auras[targetGuid]
        if data then return data, true end
        -- Fall through: our table may have test entries even when pfUI is active
    end

    -- Standalone path (or pfUI had no data for this GUID)
    local data = CleveRoids.AllCasterAuraTracking[targetGuid]
    if data then return data, false end
    return nil, false
end

-- Read start time from an aura entry (handles pfUI .startTime vs our .start)
local function AuraStart(auraData, isPfUI)
    if isPfUI then return auraData.startTime end
    return auraData.start
end

-- Helper: check if a spell is personal using lib:IsPersonalDebuff + name fallback
local function IsPersonalAura(spellId, spellName)
    local lib = CleveRoids.libdebuff
    if not lib then return true end  -- Default personal (safer)
    -- Direct ID check
    if spellId and lib.IsPersonalDebuff then
        return lib:IsPersonalDebuff(spellId)
    end
    -- Name-based fallback via IsSharedDebuffByIdOrName
    if spellName and spellId then
        return not IsSharedDebuffByIdOrName(lib, spellId, spellName)
    end
    return true  -- Default personal
end

-- Helper to get time remaining from all-caster tracking (by spellId)
-- Returns player's entry for personal debuffs, any caster for shared auras.
-- Reads from pfUI.libdebuff_all_auras when pfUI 7.6+ is active.
function CleveRoids.GetAllCasterAuraTimeRemaining(targetGuid, spellId)
    if not targetGuid or not spellId then return nil end
    local targetData, isPfUI = CleveRoids.GetAuraTrackingData(targetGuid)
    if not targetData then return nil end

    local spellName = CleveRoids.GetSpellNameCached(spellId) -- 性能优化：走 name 缓存 by 武藤纯子酱 2026.9.11
    if not spellName then return nil end

    local casters = targetData[spellName]
    if not casters then return nil end

    local now = GetTime()
    local playerGuid = CleveRoids.GetGUID("player")

    -- Always check player's own entry first
    if playerGuid and casters[playerGuid] then
        local auraData = casters[playerGuid]
        local startTime = AuraStart(auraData, isPfUI)
        if startTime and auraData.duration then
            local remaining = auraData.duration + startTime - now
            if remaining > 0 then return remaining end
        end
    end

    -- Personal debuff and player has no active entry → don't use other players' data
    if IsPersonalAura(spellId, spellName) then return nil end

    -- Shared aura: return any active caster's entry
    for _, auraData in pairs(casters) do
        local startTime = AuraStart(auraData, isPfUI)
        if startTime and auraData.duration then
            local remaining = auraData.duration + startTime - now
            if remaining > 0 then return remaining end
        end
    end
    return nil
end

-- Helper to find aura by name (or spell ID string) for a target
-- Returns player's entry for personal debuffs, any caster for shared auras.
-- Reads from pfUI.libdebuff_all_auras when pfUI 7.6+ is active.
function CleveRoids.FindAllCasterAuraByName(targetGuid, searchName)
    if not targetGuid or not searchName then return nil, nil end
    local targetData, isPfUI = CleveRoids.GetAuraTrackingData(targetGuid)
    if not targetData then return nil, nil end

    -- Resolve spell ID to name for direct lookup
    local searchID = tonumber(searchName)
    if searchID then
        local resolvedName = CleveRoids.GetSpellNameCached(searchID) -- 性能优化：走 name 缓存 by 武藤纯子酱 2026.9.11
        if not resolvedName then return nil, nil end
        searchName = resolvedName
    end

    local now = GetTime()

    -- Try exact match first (O(1) hash lookup)
    local casters = targetData[searchName]

    -- Case-insensitive fallback
    if not casters then
        local searchLower = string.lower(searchName)
        for spellName, c in pairs(targetData) do
            local baseName = CleveRoids.StripRank(spellName)
            if string.lower(baseName) == searchLower then
                casters = c
                break
            end
        end
    end

    if not casters then return nil, nil end

    local playerGuid = CleveRoids.GetGUID("player")

    -- Always check player's own entry first
    if playerGuid and casters[playerGuid] then
        local auraData = casters[playerGuid]
        local startTime = AuraStart(auraData, isPfUI)
        if startTime and auraData.duration then
            local remaining = auraData.duration + startTime - now
            if remaining > 0 then return remaining, playerGuid end
        end
    end

    -- Get a spellId from any entry to check personal vs shared
    local anySpellId = nil
    for _, aData in pairs(casters) do
        anySpellId = aData.spellId
        break
    end

    -- Personal debuff and player has no active entry → don't use other players' data
    if IsPersonalAura(anySpellId, searchName) then return nil, nil end

    -- Shared aura: return any active caster's entry
    for cGuid, auraData in pairs(casters) do
        local startTime = AuraStart(auraData, isPfUI)
        if startTime and auraData.duration then
            local remaining = auraData.duration + startTime - now
            if remaining > 0 then return remaining, cGuid end
        end
    end
    return nil, nil
end

-- HitInfo bitfield values (from NampowerAPI.lua, duplicated for local access)
-- Converted to decimal for Lua 5.0 compatibility (no hex literals)
local HITINFO_MISS = 16          -- 0x10
local HITINFO_CRITICALHIT = 128  -- 0x80
local HITINFO_GLANCING = 16384   -- 0x4000
local HITINFO_CRUSHING = 32768   -- 0x8000
local HITINFO_LEFTSWING = 4      -- 0x4 (Off-hand attack)

-- VictimState values (from AUTO_ATTACK / SPELL_GO events)
local VICTIMSTATE_UNAFFECTED = 0  -- Generic miss (seen with HITINFO_MISS)
local VICTIMSTATE_NORMAL = 1      -- Hit landed
local VICTIMSTATE_DODGE = 2
local VICTIMSTATE_PARRY = 3
local VICTIMSTATE_INTERRUPT = 4
local VICTIMSTATE_BLOCKS = 5
local VICTIMSTATE_EVADES = 6
local VICTIMSTATE_IS_IMMUNE = 7
local VICTIMSTATE_DEFLECTS = 8

-- Aura cap status bitfield
local AURA_CAP_BUFF_FULL = 1
local AURA_CAP_DEBUFF_FULL = 2

-- Helper: Check if a HitInfo bitfield contains a specific flag
local function HasHitFlag(hitInfo, flag)
    if not hitInfo or not flag then return false end
    if bit and bit.band then
        return bit.band(hitInfo, flag) ~= 0
    end
    -- Fallback for environments without bit library
    return false
end

-- Process AUTO_ATTACK_SELF 事件（玩家是攻击者 → 记录出刀；修复原注释把 SELF/OTHER 语义写反的问题）
-- 注意：事件路由见下方 OnEvent 分派（SELF→OnAutoAttackOther / OTHER→OnAutoAttackSelf） by 武藤纯子酱 2026.8.31
local function OnAutoAttackOther(attackerGuid, targetGuid, totalDamage, hitInfo, victimState,
                                  subDamageCount, blockedAmount, totalAbsorb, totalResist)
    -- Check if player is the attacker
    local playerGuid = CleveRoids.GetGUID("player")
    if not playerGuid or attackerGuid ~= playerGuid then
        return  -- Not player's attack, ignore
    end

    CleveRoids.LastSwing.timestamp = GetTime()
    CleveRoids.LastSwing.damage = totalDamage or 0
    CleveRoids.LastSwing.hitInfo = hitInfo or 0
    CleveRoids.LastSwing.victimState = victimState or 0
    CleveRoids.LastSwing.blockedAmount = blockedAmount or 0
    CleveRoids.LastSwing.absorbAmount = totalAbsorb or 0
    CleveRoids.LastSwing.resistAmount = totalResist or 0
    CleveRoids.LastSwing.targetGuid = targetGuid

    -- Paladin: refresh active Judgements on melee hit (Nampower AUTO_ATTACK events) by 武藤纯子酱 2026.9.1
    if CleveRoids.playerClass == "PALADIN" and targetGuid then
        local lib = type(CleveRoids.libdebuff) == "table" and CleveRoids.libdebuff or nil
        if lib and lib.objects then
            local normalizedTarget = CleveRoids.NormalizeGUID(targetGuid)
            if normalizedTarget and lib.objects[normalizedTarget] then
                for spellID, rec in pairs(lib.objects[normalizedTarget]) do
                    if lib.judgementSpells and lib.judgementSpells[spellID] and rec.start and rec.duration then
                        local remaining = rec.duration + rec.start - GetTime()
                        if remaining > 0 and rec.caster == "player" then
                            rec.start = GetTime()

                            if CleveRoids.debug then
                                local spellName = GetSpellRecField and GetSpellRecField(spellID, "name") or "Unknown"
                                local baseName = CleveRoids.StripRank(spellName) or "Unknown"
                                DEFAULT_CHAT_FRAME:AddMessage(
                                    string.format("|cff00ffaa[Judgement Refresh]|r Refreshed %s (ID:%d) on melee hit - new duration: %ds",
                                        baseName, spellID, rec.duration)
                                )
                            end

                            -- Sync to pfUI if loaded (pre-7.6 only)
                            if not CleveRoids.hasPfUI76 and pfUI and pfUI.api and pfUI.api.libdebuff then
                                local spellName = GetSpellRecField and GetSpellRecField(spellID, "name") or nil
                                local baseName = CleveRoids.StripRank(spellName)
                                local targetName = (lib.guidToName and lib.guidToName[normalizedTarget]) or UnitName("target")
                                local targetLevel = UnitLevel("target") or 0
                                if targetName and baseName then
                                    pfUI.api.libdebuff:AddEffect(targetName, targetLevel, baseName, rec.duration, "player")
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Process AUTO_ATTACK_OTHER 事件（他人是攻击者 → 记录玩家受到的攻击）
local function OnAutoAttackSelf(attackerGuid, targetGuid, totalDamage, hitInfo, victimState,
                                 subDamageCount, blockedAmount, totalAbsorb, totalResist)
    CleveRoids.LastIncomingHit.timestamp = GetTime()
    CleveRoids.LastIncomingHit.damage = totalDamage or 0
    CleveRoids.LastIncomingHit.hitInfo = hitInfo or 0
    CleveRoids.LastIncomingHit.victimState = victimState or 0
    CleveRoids.LastIncomingHit.blockedAmount = blockedAmount or 0
    CleveRoids.LastIncomingHit.absorbAmount = totalAbsorb or 0
    CleveRoids.LastIncomingHit.resistAmount = totalResist or 0
    CleveRoids.LastIncomingHit.attackerGuid = attackerGuid
end

-- 性能优化：OverflowBuffs 清理时的 visibleSpells 集合复用同一张表，避免每次 AURA_CAST 分配
-- by 武藤纯子酱 2026.9.11
local _visibleSpellsScratch = {}

-- Process AURA_CAST events for cap status tracking
-- Parameters: spellId, casterGuid, targetGuid, effect, effectAuraName,
--             effectAmplitude, effectMiscValue, durationMs, auraCapStatus
local function OnAuraCastSelf(spellId, casterGuid, targetGuid, effect, effectAuraName,
                               effectAmplitude, effectMiscValue, durationMs, auraCapStatus)
    if not auraCapStatus then return end

    local now = GetTime()
    CleveRoids.AuraCapStatus.playerLastUpdate = now

    local buffCapped = HasHitFlag(auraCapStatus, AURA_CAP_BUFF_FULL)

    -- Check buff bar full (bit 1)
    CleveRoids.AuraCapStatus.playerBuffCapped = buffCapped
    -- Check debuff bar full (bit 2)
    CleveRoids.AuraCapStatus.playerDebuffCapped = HasHitFlag(auraCapStatus, AURA_CAP_DEBUFF_FULL)

    -- Determine if this aura is a buff (not debuff) — debuffs land in GetPlayerAuraDuration
    -- slots 32-47, so checking those slots identifies them regardless of cap status.
    local isBuffNotDebuff = false
    if spellId and spellId > 0 and effectAuraName and effectAuraName > 0 then
        local isDebuff = false
        if _G.GetPlayerAuraDuration then
            for slot = 32, 47 do
                local sid = _G.GetPlayerAuraDuration(slot)
                if sid and sid == spellId then
                    isDebuff = true
                    break
                end
            end
        end
        isBuffNotDebuff = not isDebuff

        -- Track overflow buffs: if buff bar is full, this buff has no client aura slot.
        -- Store spellId + duration so /cancelaura and [mybuff] can find it.
        -- Guard: verify the buff is NOT already in a visible slot (0-31).
        -- This handles the 32nd-buff edge case (fills the cap but HAS a slot)
        -- and buff refreshes while capped.
        if buffCapped and isBuffNotDebuff then
            local inVisibleSlot = false
            if _G.GetPlayerAuraDuration then
                for slot = 0, 31 do
                    local sid = _G.GetPlayerAuraDuration(slot)
                    if sid and sid == spellId then
                        inVisibleSlot = true
                        break
                    end
                end
            end
            if not inVisibleSlot then
                local entry = CleveRoids.OverflowBuffs[spellId]
                if not entry then
                    entry = { stacks = 1 }
                    CleveRoids.OverflowBuffs[spellId] = entry
                else
                    -- Increment stacks on repeated AURA_CAST for the same overflow spell.
                    -- Cap at DBC stackAmount to handle refresh-at-max-stacks correctly.
                    local maxStacks
                    if _G.GetSpellRecField then
                        maxStacks = _G.GetSpellRecField(spellId, "stackAmount")
                    end
                    if maxStacks and maxStacks > 0 then
                        -- Stacking spell: increment up to cap
                        local cur = (entry.stacks or 1)
                        if cur < maxStacks then
                            entry.stacks = cur + 1
                        end
                    elseif not maxStacks then
                        -- No DBC data: increment without cap (assume stacking)
                        entry.stacks = (entry.stacks or 1) + 1
                    end
                    -- maxStacks == 0: non-stacking spell, leave stacks at 1
                end
                entry.timestamp = now
                entry.durationSec = durationMs and (durationMs / 1000) or 0
            end
        end
    end

    if next(CleveRoids.OverflowBuffs) then
        -- Clean up overflow entries that now appear in a visible aura slot.
        -- Check both buff slots (0-31) and debuff slots (32-47) — debuffs can
        -- be incorrectly added due to AURA_CAST_ON_SELF race condition (debuff
        -- slot not yet assigned when the event fired).
        -- When not buff-capped: some overflow buffs may have gotten real slots.
        -- The server does NOT auto-migrate overflow buffs into freed slots,
        -- so we can't blindly clear everything — only remove visible ones.
        if _G.GetPlayerAuraDuration then
            local visibleSpells = _visibleSpellsScratch
            local vk = next(visibleSpells)
            while vk do visibleSpells[vk] = nil; vk = next(visibleSpells) end
            for slot = 0, 47 do
                local sid = _G.GetPlayerAuraDuration(slot)
                if sid and sid > 0 then
                    visibleSpells[sid] = true
                end
            end
            for k in pairs(CleveRoids.OverflowBuffs) do
                if visibleSpells[k] then
                    CleveRoids.OverflowBuffs[k] = nil
                end
            end
        end
        -- Also prune expired entries
        for k, entry in pairs(CleveRoids.OverflowBuffs) do
            if entry.durationSec and entry.durationSec > 0 then
                local elapsed = now - (entry.timestamp or 0)
                if elapsed > entry.durationSec then
                    CleveRoids.OverflowBuffs[k] = nil
                end
            end
        end
    end

    -- NEW: Populate ownBuffCasts and allBuffAuras for all player buffs (not just overflow)
    -- Use the isBuffNotDebuff result determined above (avoids redundant slot scanning)
    local lib = CleveRoids.libdebuff
    if isBuffNotDebuff and spellId and durationMs and durationMs > 0 and lib and not lib.hasPfUIEnhanced then
        local spellName = CleveRoids.GetSpellNameCached(spellId) -- 性能优化：走 name 缓存 by 武藤纯子酱 2026.9.11
        if spellName then
            local playerGuid = CleveRoids.GetGUID("player")
            if playerGuid then
                lib.ownBuffCasts[playerGuid] = lib.ownBuffCasts[playerGuid] or {}
                lib.ownBuffCasts[playerGuid][spellName] = {
                    startTime  = now,
                    duration   = durationMs / 1000,
                    spellId    = spellId,
                    casterGuid = casterGuid,
                }
                lib.allBuffAuras[playerGuid] = lib.allBuffAuras[playerGuid] or {}
                lib.allBuffAuras[playerGuid][spellName] = lib.allBuffAuras[playerGuid][spellName] or {}
                lib.allBuffAuras[playerGuid][spellName][casterGuid or "unknown"] = {
                    startTime = now,
                    duration  = durationMs / 1000,
                    rank      = 0,
                }
            end
        end
    end
end

local function OnAuraCastOther(spellId, casterGuid, targetGuid, effect, effectAuraName,
                                effectAmplitude, effectMiscValue, durationMs, auraCapStatus)
    if not targetGuid then return end

    local now = GetTime()

    -- Store aura duration for all-caster tracking (even without auraCapStatus)
    -- When pfUI enhanced is active, pfUI writes to pfUI.libdebuff_all_auras with
    -- full downrank protection — we read from that table via GetAuraTrackingData().
    if spellId and durationMs and durationMs > 0 then
        local spellName = GetSpellRecField and GetSpellRecField(spellId, "name")
        if spellName and not CleveRoids.hasPfUI76 then
            CleveRoids._allCasterAuraDirty = true
            if not CleveRoids.AllCasterAuraTracking[targetGuid] then
                CleveRoids.AllCasterAuraTracking[targetGuid] = {}
            end
            if not CleveRoids.AllCasterAuraTracking[targetGuid][spellName] then
                CleveRoids.AllCasterAuraTracking[targetGuid][spellName] = {}
            end
            local casterKey = casterGuid or "unknown"
            -- Downrank protection: don't let a lower rank overwrite a higher rank with time remaining
            local existing = CleveRoids.AllCasterAuraTracking[targetGuid][spellName][casterKey]
            if existing and existing.spellId and existing.spellId ~= spellId then
                local lib = CleveRoids.libdebuff
                if lib and lib.GetSpellRank then
                    local newRank = lib:GetSpellRank(spellId)
                    local existingRank = lib:GetSpellRank(existing.spellId)
                    if newRank > 0 and existingRank > 0 and newRank < existingRank then
                        local timeleft = (existing.start + existing.duration) - now
                        if timeleft > 0 then
                            CleveRoids.DebugChanged("AuraTrack_rankblock_" .. spellName .. "_" .. casterKey,
                                string.format("|cffff6600[AuraTrack]|r %s Rank %d blocked by Rank %d (%.1fs left) on %s",
                                    spellName, newRank, existingRank, timeleft,
                                    string.sub(tostring(targetGuid), 1, 16)))
                            spellName = nil  -- skip pendingBuffCasts below too
                        end
                    end
                end
            end

            -- Write/update tracking entry (skipped if downrank blocked above)
            if spellName then
                if existing then
                    existing.start = now
                    existing.duration = durationMs / 1000
                    existing.spellId = spellId
                else
                    CleveRoids.AllCasterAuraTracking[targetGuid][spellName][casterKey] = {
                        start = now,
                        duration = durationMs / 1000,
                        spellId = spellId,
                    }
                end
            end
        end

        -- Debug output when enabled
        if spellName then
            CleveRoids.DebugChanged("AuraTrack_" .. tostring(spellId) .. "_" .. string.sub(tostring(targetGuid), 1, 16),
                string.format("|cff00ffff[AuraTrack]|r %s (ID:%d) on %s by %s, dur=%.1fs",
                    spellName, spellId, string.sub(tostring(targetGuid), 1, 16),
                    string.sub(tostring(casterGuid), 1, 16), durationMs / 1000))
        end

        -- Store in pendingBuffCasts for BUFF_ADDED_OTHER to confirm as buff
        -- (AURA_CAST_ON_OTHER fires for both buffs and debuffs; BUFF_ADDED_OTHER confirms buff)
        local lib = CleveRoids.libdebuff
        if lib and not lib.hasPfUIEnhanced then
            local spellNameForPending = GetSpellRecField and GetSpellRecField(spellId, "name")
            if spellNameForPending then
                local normTargetGuid = CleveRoids.NormalizeGUID(targetGuid)
                if normTargetGuid then
                    lib.pendingBuffCasts[normTargetGuid] = lib.pendingBuffCasts[normTargetGuid] or {}
                    lib.pendingBuffCasts[normTargetGuid][spellId] = {
                        casterGuid = CleveRoids.NormalizeGUID(casterGuid),
                        duration   = durationMs / 1000,
                        spellName  = spellNameForPending,
                        time       = now,
                    }
                end
            end
        end
    end

    -- Store cap status for this target GUID (if available)
    if auraCapStatus then
        -- PERFORMANCE: Reuse existing entry table when possible
        local entry = CleveRoids.AuraCapStatus.targetCapStatus[targetGuid]
        if not entry then
            entry = {}
            CleveRoids.AuraCapStatus.targetCapStatus[targetGuid] = entry
        end
        entry.buffCapped = HasHitFlag(auraCapStatus, AURA_CAP_BUFF_FULL)
        entry.debuffCapped = HasHitFlag(auraCapStatus, AURA_CAP_DEBUFF_FULL)
        entry.timestamp = now
    end

    -- Cleanup moved to CleveRoids.CleanupAuraTracking(), called by UnitXP timer when available
    -- Fallback: inline throttled cleanup when UnitXP is not present
    if not CleveRoids.hasUnitXP then
        if (now - CleveRoids.AuraCapStatus.lastCleanupTime) >= 5 then
            CleveRoids.AuraCapStatus.lastCleanupTime = now
            CleveRoids.CleanupAuraTracking(now)
        end
    end
end

--- Periodic cleanup of AuraCapStatus and AllCasterAuraTracking tables
--- Called by UnitXP timer (5s) or inline from OnAuraCastOther when UnitXP absent
function CleveRoids.CleanupAuraTracking(now)
    if not now then now = GetTime() end

    -- Cleanup old cap status entries (older than 60 seconds)
    local guid, data = next(CleveRoids.AuraCapStatus.targetCapStatus)
    while guid do
        local nextGuid = next(CleveRoids.AuraCapStatus.targetCapStatus, guid)
        if now - data.timestamp > 60 then
            CleveRoids.AuraCapStatus.targetCapStatus[guid] = nil
        end
        guid = nextGuid
        data = nextGuid and CleveRoids.AuraCapStatus.targetCapStatus[nextGuid]
    end

    -- Cleanup old aura tracking entries (3-level: targetGuid → spellName → casterGuid)
    -- Skip cleanup if nothing was written since last cleanup
    if not CleveRoids._allCasterAuraDirty then return end
    CleveRoids._allCasterAuraDirty = false
    local tGuid, spellNames = next(CleveRoids.AllCasterAuraTracking)
    while tGuid do
        local nextTGuid = next(CleveRoids.AllCasterAuraTracking, tGuid)
        local hasActiveTarget = false
        local sName, casters = next(spellNames)
        while sName do
            local nextSName = next(spellNames, sName)
            local hasActiveCaster = false
            local cGuid, auraData = next(casters)
            while cGuid do
                local nextCGuid = next(casters, cGuid)
                if auraData.start and auraData.duration then
                    if auraData.duration + auraData.start - now <= 0 then
                        casters[cGuid] = nil
                    else
                        hasActiveCaster = true
                    end
                end
                cGuid = nextCGuid
                auraData = nextCGuid and casters[nextCGuid]
            end
            if hasActiveCaster then
                hasActiveTarget = true
            else
                spellNames[sName] = nil
            end
            sName = nextSName
            casters = nextSName and spellNames[nextSName]
        end
        if not hasActiveTarget then
            CleveRoids.AllCasterAuraTracking[tGuid] = nil
        end
        tGuid = nextTGuid
        spellNames = nextTGuid and CleveRoids.AllCasterAuraTracking[nextTGuid]
    end
end

-- UnitXP threaded timer for aura tracking cleanup (5s interval)
-- Replaces inline cleanup that ran on every aura event
if CleveRoids.hasUnitXP then
    function CleveRoids_AuraTrackingCleanupTimer()
        if CleveRoids.isShuttingDown then return end
        CleveRoids.CleanupAuraTracking()
    end

    CleveRoids._auraCleanupTimerId = CleveRoids.SafeUnitXP("timer", "arm", 5000, 5000, "CleveRoids_AuraTrackingCleanupTimer")
end

-- Create frame to listen for Nampower auto-attack and aura events
local autoAttackFrame = CreateFrame("Frame", "CleveRoidsAutoAttackFrame")

-- Register for events on PLAYER_ENTERING_WORLD (after CVars are applied)
autoAttackFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
autoAttackFrame:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        -- Check if Nampower v2.24+ is available for auto-attack events
        local API = CleveRoids.NampowerAPI
        if API and API.features and API.features.hasAutoAttackEvents then
            -- Register for auto-attack events (requires NP_EnableAutoAttackEvents=1)
            this:RegisterEvent("AUTO_ATTACK_OTHER")
            this:RegisterEvent("AUTO_ATTACK_SELF")
        end

        -- Check for aura cast events (v2.20+, requires NP_EnableAuraCastEvents=1)
        if API and API.features and API.features.hasAuraCastEvents then
            this:RegisterEvent("AURA_CAST_ON_SELF")
            this:RegisterEvent("AURA_CAST_ON_OTHER")

            -- Register removal events for instant AllCasterAuraTracking cleanup
            this:RegisterEvent("BUFF_REMOVED_OTHER")
            this:RegisterEvent("DEBUFF_REMOVED_OTHER")
        end

        -- Check for aura duration update events (v2.30+)
        if API and API.features and API.features.hasAuraDurationEvents then
            this:RegisterEvent("BUFF_UPDATE_DURATION_SELF")
            this:RegisterEvent("DEBUFF_UPDATE_DURATION_SELF")
        end

    elseif event == "BUFF_UPDATE_DURATION_SELF" or event == "DEBUFF_UPDATE_DURATION_SELF" then
        -- v2.30+: Player aura duration was refreshed
        -- arg1 = auraSlot (0-based raw slot index)
        -- arg2 = durationMs, arg3 = expirationTimeMs, arg4 = spellId (v2.33+)
        local auraSlot = arg1
        local spellId, durationMs, expirationTimeMs

        -- v2.33+: spellId provided directly as arg4, with duration info in arg2/arg3
        if arg4 and arg4 > 0 then
            spellId = arg4
            durationMs = arg2
            expirationTimeMs = arg3
        elseif auraSlot and API and API.GetPlayerAuraDuration then
            -- Pre-v2.33 fallback: query duration by aura slot
            spellId, durationMs, expirationTimeMs = API.GetPlayerAuraDuration(auraSlot)
        end

        if spellId and spellId > 0 and durationMs and durationMs > 0 then
            local playerGUID = CleveRoids.GetGUID("player")
            local durSpellName = GetSpellRecField and GetSpellRecField(spellId, "name")
            if playerGUID and durSpellName and not CleveRoids.hasPfUI76 then
                CleveRoids._allCasterAuraDirty = true
                if not CleveRoids.AllCasterAuraTracking[playerGUID] then
                    CleveRoids.AllCasterAuraTracking[playerGUID] = {}
                end
                if not CleveRoids.AllCasterAuraTracking[playerGUID][durSpellName] then
                    CleveRoids.AllCasterAuraTracking[playerGUID][durSpellName] = {}
                end
                local durationSec = durationMs / 1000
                -- Use GetTime() for start time. expirationTimeMs uses GetWowTimeMs()
                -- basis which is different from GetTime() and causes drift.
                -- This event fires at refresh time, so now IS the start.
                local now = GetTime()
                CleveRoids.AllCasterAuraTracking[playerGUID][durSpellName][playerGUID] = {
                    duration = durationSec,
                    spellId = spellId,
                    start = now, -- 修复：删除了引用未定义全局 startTime 的死键（原本被后面的 start=now 覆盖） by 武藤纯子酱 2026.8.31
                }
            end

            if durSpellName then
                CleveRoids.DebugChanged("AuraDurUpdate_" .. tostring(spellId),
                    string.format("|cff88ff88[AuraDurUpdate]|r %s (slot:%d, ID:%d) dur=%.1fs",
                        durSpellName, auraSlot, spellId, durationMs / 1000))
            end
        end

    elseif event == "AUTO_ATTACK_OTHER" then
        -- arg1=attackerGuid, arg2=targetGuid, arg3=totalDamage, arg4=hitInfo, arg5=victimState,
        -- arg6=subDamageCount, arg7=blockedAmount, arg8=totalAbsorb, arg9=totalResist
        -- 修复：按 EVENTS.md，OTHER=他人是攻击者 → 记录为玩家"受到的攻击"（LastIncomingHit）；
        -- 原来接反了：OTHER 被当成出刀（且被 attackerGuid~=playerGuid 守卫直接丢弃），SELF 被当成被打 by 武藤纯子酱 2026.8.31
        OnAutoAttackSelf(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)

    elseif event == "AUTO_ATTACK_SELF" then
        -- 修复：SELF=玩家是攻击者 → 记录为玩家的出刀（LastSwing） by 武藤纯子酱 2026.8.31
        OnAutoAttackOther(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)

    elseif event == "AURA_CAST_ON_SELF" then
        -- arg1=spellId, arg2=casterGuid, arg3=targetGuid, arg4=effect, arg5=effectAuraName,
        -- arg6=effectAmplitude, arg7=effectMiscValue, arg8=durationMs, arg9=auraCapStatus
        OnAuraCastSelf(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)

    elseif event == "AURA_CAST_ON_OTHER" then
        OnAuraCastOther(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)

    elseif event == "BUFF_REMOVED_OTHER" or event == "DEBUFF_REMOVED_OTHER" then
        -- Instant cleanup of AllCasterAuraTracking when auras are removed
        -- arg1=targetGuid, arg2=luaSlot, arg3=spellId, arg4=stackCount, arg5=auraLevel, arg6=auraSlot, arg7=state (v2.32+: 0=added, 1=removed, 2=modified)
        local guid = arg1
        local spellId = arg3
        local state = arg7
        if state == 2 then return end  -- Stack change, not full removal
        if guid and spellId and CleveRoids.AllCasterAuraTracking[guid] then
            local removedName = GetSpellRecField and GetSpellRecField(spellId, "name")
            if removedName and CleveRoids.AllCasterAuraTracking[guid][removedName] then
                CleveRoids.AllCasterAuraTracking[guid][removedName] = nil
                if not next(CleveRoids.AllCasterAuraTracking[guid]) then
                    CleveRoids.AllCasterAuraTracking[guid] = nil
                end
            end
        end
    end
end)

-- ============================================================================
-- VALIDATION FUNCTIONS FOR AUTO-ATTACK CONDITIONALS
-- ============================================================================

-- Validate lastswing conditional
-- swingType: "crit", "glancing", "miss", "dodge", "parry", "blocked", "offhand", or time comparison
function CleveRoids.ValidateLastSwing(swingType, operator, amount)
    local swing = CleveRoids.LastSwing
    if swing.timestamp == 0 then
        return false  -- No swing recorded yet
    end

    local swingTypeLower = swingType and string.lower(swingType)

    -- Time-based check (e.g., [lastswing:<2] = within last 2 seconds)
    if operator and amount then
        local elapsed = GetTime() - swing.timestamp
        if CleveRoids.operators[operator] then
            return CleveRoids.comparators[operator](elapsed, amount)
        end
        return false
    end

    -- Type-based checks (all require the swing to be within 5 seconds)
    local isRecent = (GetTime() - swing.timestamp) < 5
    if not isRecent then
        return false  -- Swing too old, don't report any type
    end

    if swingTypeLower == "crit" or swingTypeLower == "critical" then
        return HasHitFlag(swing.hitInfo, HITINFO_CRITICALHIT)
    elseif swingTypeLower == "glancing" then
        return HasHitFlag(swing.hitInfo, HITINFO_GLANCING)
    elseif swingTypeLower == "miss" then
        return HasHitFlag(swing.hitInfo, HITINFO_MISS)
    elseif swingTypeLower == "dodge" or swingTypeLower == "dodged" then
        return swing.victimState == VICTIMSTATE_DODGE
    elseif swingTypeLower == "parry" or swingTypeLower == "parried" then
        return swing.victimState == VICTIMSTATE_PARRY
    elseif swingTypeLower == "blocked" or swingTypeLower == "block" then
        return swing.victimState == VICTIMSTATE_BLOCKS or swing.blockedAmount > 0
    elseif swingTypeLower == "offhand" or swingTypeLower == "oh" then
        return HasHitFlag(swing.hitInfo, HITINFO_LEFTSWING)
    elseif swingTypeLower == "mainhand" or swingTypeLower == "mh" then
        return not HasHitFlag(swing.hitInfo, HITINFO_LEFTSWING)
    elseif swingTypeLower == "hit" then
        -- A successful hit (not miss, not dodged, not parried)
        return not HasHitFlag(swing.hitInfo, HITINFO_MISS) and
               swing.victimState ~= VICTIMSTATE_DODGE and
               swing.victimState ~= VICTIMSTATE_PARRY
    end

    -- Default: already checked isRecent above, so return true for any recent swing
    return true
end

-- Validate incominghit conditional
function CleveRoids.ValidateIncomingHit(hitType, operator, amount)
    local hit = CleveRoids.LastIncomingHit
    if hit.timestamp == 0 then
        return false  -- No incoming hit recorded
    end

    local hitTypeLower = hitType and string.lower(hitType)

    -- Time-based check
    if operator and amount then
        local elapsed = GetTime() - hit.timestamp
        if CleveRoids.operators[operator] then
            return CleveRoids.comparators[operator](elapsed, amount)
        end
        return false
    end

    -- Type-based checks (all require the hit to be within 5 seconds)
    local isRecent = (GetTime() - hit.timestamp) < 5
    if not isRecent then
        return false  -- Hit too old, don't report any type
    end

    if hitTypeLower == "crit" or hitTypeLower == "critical" then
        return HasHitFlag(hit.hitInfo, HITINFO_CRITICALHIT)
    elseif hitTypeLower == "crushing" then
        return HasHitFlag(hit.hitInfo, HITINFO_CRUSHING)
    elseif hitTypeLower == "glancing" then
        return HasHitFlag(hit.hitInfo, HITINFO_GLANCING)
    elseif hitTypeLower == "miss" or hitTypeLower == "missed" then
        return HasHitFlag(hit.hitInfo, HITINFO_MISS)
    elseif hitTypeLower == "dodge" or hitTypeLower == "dodged" then
        return hit.victimState == VICTIMSTATE_DODGE
    elseif hitTypeLower == "parry" or hitTypeLower == "parried" then
        return hit.victimState == VICTIMSTATE_PARRY
    elseif hitTypeLower == "blocked" or hitTypeLower == "block" then
        return hit.victimState == VICTIMSTATE_BLOCKS or hit.blockedAmount > 0
    elseif hitTypeLower == "hit" then
        -- A successful incoming hit (not miss, not dodged, not parried by us)
        return not HasHitFlag(hit.hitInfo, HITINFO_MISS) and
               hit.victimState ~= VICTIMSTATE_DODGE and
               hit.victimState ~= VICTIMSTATE_PARRY
    end

    -- Default: already checked isRecent above, so return true for any recent hit
    return true
end

-- Check if player's buff bar is capped (32 slots)
function CleveRoids.IsPlayerBuffCapped()
    -- First check from AURA_CAST events (most accurate)
    -- 修复：AURA_CAST 只在增益事件时刷新，光环自然消退不会触发——缓存会永久过期；
    -- 加上 10 秒新鲜度限制，过期后走下方实时统计 by 武藤纯子酱 2026.8.31
    if CleveRoids.AuraCapStatus.playerLastUpdate > 0
       and (GetTime() - CleveRoids.AuraCapStatus.playerLastUpdate) < 10 then
        return CleveRoids.AuraCapStatus.playerBuffCapped
    end

    -- v2.30+ fast path: use raw slot counting via GetPlayerAuraDuration
    local API = CleveRoids.NampowerAPI
    if API then
        local count = API.CountPlayerBuffSlots()
        if count then
            return count >= 32
        end
    end

    -- Fallback: count player buffs manually
    local count = 0
    for i = 0, 31 do
        if GetPlayerBuffTexture(GetPlayerBuff(i, "HELPFUL")) then
            count = count + 1
        end
    end
    return count >= 32
end

-- Check if player's debuff bar is capped (16 slots)
function CleveRoids.IsPlayerDebuffCapped()
    -- 修复：同 IsPlayerBuffCapped，加新鲜度限制 by 武藤纯子酱 2026.8.31
    if CleveRoids.AuraCapStatus.playerLastUpdate > 0
       and (GetTime() - CleveRoids.AuraCapStatus.playerLastUpdate) < 10 then
        return CleveRoids.AuraCapStatus.playerDebuffCapped
    end

    -- v2.30+ fast path: use raw slot counting via GetPlayerAuraDuration
    local API = CleveRoids.NampowerAPI
    if API then
        local count = API.CountPlayerDebuffSlots()
        if count then
            return count >= 16
        end
    end

    -- Fallback: count player debuffs
    local count = 0
    for i = 0, 15 do
        if GetPlayerBuffTexture(GetPlayerBuff(i, "HARMFUL")) then
            count = count + 1
        end
    end
    return count >= 16
end

-- Check if target's debuff bar is capped
-- For NPCs: 16 debuff slots + 32 overflow = 48 total visual debuff capacity
function CleveRoids.IsTargetDebuffCapped(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end

    -- Check cached AURA_CAST data by GUID
    local guid = CleveRoids.GetGUID(unit)
    if guid then
        local capData = CleveRoids.AuraCapStatus.targetCapStatus[guid]
        if capData and (GetTime() - capData.timestamp) < 30 then
            return capData.debuffCapped
        end
    end

    -- Fallback: count debuffs on target manually
    -- For NPCs: check up to 48 slots (16 debuff + 32 overflow in buff slots)
    local debuffCount = 0

    -- Count regular debuff slots (1-16, dense)
    for i = 1, 16 do
        local texture, _, _, spellId = UnitDebuff(unit, i)
        if texture then
            debuffCount = debuffCount + 1
        else
            break  -- Dense, stop at first nil
        end
    end

    -- Count overflow debuffs in buff slots (sparse, check all 32)
    -- Overflow debuffs appear in buff slots but are filtered by UnitDebuff
    -- We need to use libdebuff or check buff slots for debuff-like effects
    -- For simplicity, consider 16 regular debuffs = capped for most use cases
    return debuffCount >= 16
end

-- Check if target's buff bar is capped (32 slots for NPCs)
function CleveRoids.IsTargetBuffCapped(unit)
    unit = unit or "target"
    if not UnitExists(unit) then return false end

    local guid = CleveRoids.GetGUID(unit)
    if guid then
        local capData = CleveRoids.AuraCapStatus.targetCapStatus[guid]
        if capData and (GetTime() - capData.timestamp) < 30 then
            return capData.buffCapped
        end
    end

    -- Fallback: count buffs
    local count = 0
    for i = 1, 32 do
        if UnitBuff(unit, i) then
            count = count + 1
        else
            break
        end
    end
    return count >= 32
end

-- ============================================================================

-- 提升：原 onenemytarget/noonenemytarget 内各定义一份完全相同的 countEnemiesTargetingMe，
-- 统一为共享函数（原 PFUI_HasLibDebuff 已删除，从未被调用）by 武藤纯子酱 2026.9.11
function CleveRoids.CountEnemiesTargetingMe(maxDistance)
    local count = 0
    for guid, _ in pairs(CleveRoids.knownEnemyGuids) do
        if UnitExists(guid) and UnitCanAttack("player", guid) then
            local inRange = true
            if maxDistance and maxDistance > 0 and CleveRoids.hasUnitXP then
                local dist = CleveRoids.SafeUnitXP("distanceBetween", guid, "player")
                inRange = dist and dist <= maxDistance
            end
            if inRange then
                if UnitExists(guid.."target") and UnitIsUnit(guid.."target", "player") then
                    count = count + 1
                end
            end
        end
    end
    return count
end


-- ============================================================================
-- PENDING DEBUFF CAST DETECTION
-- ============================================================================
-- Prevents double-application when spamming [nodebuff] macros with spell queue.
-- If we're currently casting or have queued a spell that applies this debuff,
-- treat the debuff as "pending" so [nodebuff] returns false.

-- Helper: Normalize spell name for comparison (strip rank, lowercase)
local function NormalizeSpellNameForComparison(spellName)
    if not spellName then return nil end
    -- Strip rank suffix: "Faerie Fire (Feral)(Rank 4)" -> "Faerie Fire (Feral)"
    local normalized = CleveRoids.StripRank(spellName)
    -- Convert underscores to spaces and lowercase
    normalized = string.lower(string.gsub(normalized, "_", " "))
    return normalized
end

-- Check if player is currently casting or has queued a spell that would apply this debuff
-- This prevents [nodebuff] from returning true while the cast is in-flight
-- @param spellName string - The debuff spell name to check
-- @param targetUnit string - The target unit (to verify we're casting AT this target)
-- @return boolean - True if this debuff is pending (being cast/queued to this target)
local function IsPendingDebuffCast(spellName, targetUnit)
    if not spellName then return false end

    local normalizedCheck = NormalizeSpellNameForComparison(spellName)
    if not normalizedCheck then return false end

    -- Get target GUID for verification (only count as pending if casting AT this target)
    local targetGuid = nil
    if targetUnit and UnitExists(targetUnit) then
        targetGuid = CleveRoids.GetGUID(targetUnit)
    end

    -- 结果确认门（最优先、最廉价检查）：玩家刚对该目标出手了同名法术，但命中/抵抗
    -- 结果事件尚未到达（实测 0.002~0.005s 的事件回传偏差窗口）。此时目标身上必然
    -- 还没有效果，必须挂起判定，否则 Nampower 排队机制会连出两发。任一结果事件
    -- 到达或 0.1s 超时后自动放行 by 武藤纯子酱 2026.8.31
    if targetGuid and CleveRoids.IsCastOutcomePending
        and CleveRoids.IsCastOutcomePending(normalizedCheck, targetGuid) then
        CleveRoids.DebugChanged("PendingDebuff_outcome_" .. normalizedCheck,
            string.format("|cffff00ff[Outcome Gate]|r %s 对 %s 的施法结果未确认，判定挂起", spellName, tostring(targetGuid)))
        CleveRoids._castOutcomeHold = true -- 挂起信号：ExecuteMacroBody 据此停止本轮后续行
        return true
    end

    -- Check if currently CASTING this spell
    -- CleveRoids.CurrentSpell tracks the spell being cast with time-based duration
    if CleveRoids.CurrentSpell and CleveRoids.CurrentSpell.type == "cast" then
        local castingName = CleveRoids.CurrentSpell.spellName
        if castingName then
            local normalizedCasting = NormalizeSpellNameForComparison(castingName)
            if normalizedCasting == normalizedCheck then
                -- If libdebuff flagged this as downrank-blocked, don't treat as pending
                local blocked = targetGuid and CleveRoids.DownrankBlocked[targetGuid] and
                    CleveRoids.DownrankBlocked[targetGuid][castingName]
                if not blocked then
                    if CleveRoids.castStartTime and CleveRoids.castDuration then
                        local remaining = CleveRoids.castDuration - (GetTime() - CleveRoids.castStartTime)
                        if remaining > 0.1 then
                            CleveRoids.DebugChanged("pending_" .. normalizedCheck,
                                string.format("|cffff00ff[PendingDebuff]|r %s pending via CurrentSpell", spellName))
                            return true
                        end
                    else
                        CleveRoids.DebugChanged("pending_" .. normalizedCheck,
                            string.format("|cffff00ff[PendingDebuff]|r %s pending via CurrentSpell", spellName))
                        return true
                    end
                end
            end
        end
    end

    -- Check if this spell is QUEUED via Nampower
    -- CleveRoids.queuedSpell tracks the spell waiting to fire after GCD/cast
    if CleveRoids.queuedSpell and CleveRoids.queuedSpell.spellName then
        local queuedName = CleveRoids.queuedSpell.spellName
        local normalizedQueued = NormalizeSpellNameForComparison(queuedName)
        if normalizedQueued == normalizedCheck then
            local blocked = targetGuid and CleveRoids.DownrankBlocked[targetGuid] and
                CleveRoids.DownrankBlocked[targetGuid][queuedName]
            if not blocked then
                CleveRoids.DebugChanged("PendingDebuff_" .. spellName,
                    string.format("|cffff00ff[PendingDebuff]|r %s pending via queuedSpell", spellName))
                return true
            end
        end
    end

    -- Check in-flight debuffs: use pfUI's pending table when available (shared data,
    -- avoids duplicate tracking), otherwise fall back to our own pending arrays
    local lib = CleveRoids.libdebuff
    if lib and targetGuid then
        if pfUI and pfUI.libdebuff_pending then
            -- pfUI.libdebuff_pending[guid][spellName] = {casterGuid, rank, time, downrankBlocked}
            -- libdebuff sets downrankBlocked=true when the cast was identified as a downrank —
            -- read that field directly instead of re-implementing the check here.
            local pendingForTarget = pfUI.libdebuff_pending[targetGuid]
            if pendingForTarget then
                local playerGuid = CleveRoids.GetGUID("player")
                for pendingSpell, pendingData in pairs(pendingForTarget) do
                    local normalizedPending = NormalizeSpellNameForComparison(pendingSpell)
                    if normalizedPending == normalizedCheck then
                        local casterGuid = type(pendingData) == "table" and pendingData.casterGuid or nil
                        if casterGuid and casterGuid == playerGuid then
                            if type(pendingData) == "table" and pendingData.downrankBlocked then
                                CleveRoids.DebugChanged("PendingDebuff_downrank_" .. spellName,
                                    string.format("|cffff00ff[PendingDebuff]|r %s skipped - downrank blocked by libdebuff", spellName))
                            else
                                CleveRoids.DebugChanged("PendingDebuff_" .. spellName,
                                    string.format("|cffff00ff[PendingDebuff]|r %s pending via pfUI.libdebuff_pending (ours)", spellName))
                                return true
                            end
                        elseif casterGuid then
                            CleveRoids.DebugChanged("PendingDebuff_other_" .. spellName,
                                string.format("|cffff00ff[PendingDebuff]|r %s in pfUI pending but caster=%s (not ours) - skipping",
                                    spellName, string.sub(tostring(casterGuid), 1, 16)))
                        end
                    end
                end
            end
        else
            -- Standalone mode (no pfUI): check our own pending arrays
            -- These are player-only, populated from SPELL_GO_SELF / SPELL_START_SELF by 武藤纯子酱 2026.9.1
            local pendingArrays = { lib.pendingPersonalDebuffs, lib.pendingSharedDebuffs, lib.pendingCCDebuffs }
            for _, arr in ipairs(pendingArrays) do
                if arr then
                    for _, pending in pairs(arr) do
                        if pending and pending.targetGUID == targetGuid and pending.spellID then
                            local pendingName = GetSpellRecField and GetSpellRecField(pending.spellID, "name")
                            if pendingName then
                                local normalizedPending = NormalizeSpellNameForComparison(pendingName)
                                if normalizedPending == normalizedCheck then
                                    CleveRoids.DebugChanged("PendingDebuff_" .. spellName,
                                        string.format("|cffff00ff[PendingDebuff]|r %s pending via libdebuff pending array (ID:%d)",
                                            spellName, pending.spellID))
                                    return true
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- Expose for use in nodebuff conditional
CleveRoids.IsPendingDebuffCast = IsPendingDebuffCast

-- Helper: Get debuff time-left (seconds) from CleveRoids.libdebuff only
local function _get_debuff_timeleft(unitToken, auraName)
    -- Defensive: verify libdebuff is a table before accessing properties
    local lib = type(CleveRoids.libdebuff) == "table" and CleveRoids.libdebuff or nil

    -- Strip rank suffix for consistent matching (e.g., "Rake(Rank 4)" -> "Rake")
    if auraName then
        auraName = CleveRoids.StripRank(auraName)
        -- Convert underscores to spaces for matching (e.g., "Thunder_Clap" -> "Thunder Clap")
        auraName = string.gsub(auraName, "_", " ")
    end

    -- GUID-based debuff lookup via libdebuff (works with SuperWoW or Nampower)
    if lib and lib.UnitDebuff then
        for idx = 1, 48 do
            local effect, _, _, _, _, duration, timeleft = lib:UnitDebuff(unitToken, idx)
            -- Only break for slots 1-16 (regular debuffs are dense)
            -- For overflow slots 17-48, nil means "regular buff filtered out", not "end of list"
            if not effect and idx <= 16 then break end
            -- Strip rank from effect name for comparison
            local effectBase = CleveRoids.StripRank(effect)
            if effectBase and effectBase == auraName and timeleft and timeleft >= 0 then
                return timeleft, duration
            end
        end
    end

    return nil, nil
end

-- Validates that the given target is either friend (if [help]) or foe (if [harm])
-- target: The unit id to check
-- help: Optional. If set to 1 then the target must be friendly. If set to 0 it must be an enemy.
-- remarks: Will always return true if help is not given
-- returns: Whether or not the given target can either be attacked or supported, depending on help
function CleveRoids.CheckHelp(target, help)
    if help == nil then return true end
    if help then
        return UnitCanAssist("player", target)
    else
        return UnitCanAttack("player", target)
    end
end

-- Ensures the validity of the given target
-- target: The unit id to check
-- help: Optional. If set to 1 then the target must be friendly. If set to 0 it must be an enemy
-- returns: Whether or not the target is a viable target
function CleveRoids.IsValidTarget(target, help)

    if CleveRoids.IsSpecialUnitTarget(target) then -- 特殊标识（@cursor/@cursive/@mostwounded 等）不需要固定 UnitId，直接视为有效（清单统一见 Init.lua）
        return true
    end

    -- If the conditional is not for @mouseover, use the existing logic.
    if target ~= "mouseover" then
        if not UnitExists(target) or not CleveRoids.CheckHelp(target, help) then
            return false
        end
        return true
    end

    -- --- START OF PATCH ---
    -- New logic to handle [@mouseover] with pfUI compatibility.

    local effectiveMouseoverUnit = "mouseover" -- Start with the default game token.

    -- Check if the default mouseover exists. If not, check pfUI's internal data,
    -- which is necessary because pfUI frames don't always update the default token.
    if not UnitExists(effectiveMouseoverUnit) then
        if pfUI and pfUI.uf and pfUI.uf.mouseover and pfUI.uf.mouseover.unit and UnitExists(pfUI.uf.mouseover.unit) then
            -- If pfUI has a valid mouseover unit recorded, use that instead.
            effectiveMouseoverUnit = pfUI.uf.mouseover.unit
        elseif CleveRoids.mouseoverUnit and UnitExists (CleveRoids.mouseoverUnit) then -- 新增 by 武藤纯子酱 2026.7.17
            effectiveMouseoverUnit = CleveRoids.mouseoverUnit
        else
            -- If neither the default token nor the pfUI unit exists, there's no valid mouseover.
            return false
        end
    end
    -- --- END OF PATCH ---

    -- Finally, perform the help/harm check on the determined mouseover unit (either from the game or from pfUI).
    if not UnitExists(effectiveMouseoverUnit) or not CleveRoids.CheckHelp(effectiveMouseoverUnit, help) then
        return false
    end

    return true
end

-- 修复：GetPlayerAuraIndex 原先未定义 anywhere，牧师/盗贼使用 [stance]/[form]/[nostance] 时直接报错。
-- 牧师/盗贼没有形态栏，用玩家身上是否存在对应光环判定（存在=1，不存在=0），与形态序号语义一致 by 武藤纯子酱 2026.8.31
local function GetPlayerAuraIndex(spellName)
    if spellName and CleveRoids.ValidatePlayerBuff and CleveRoids.ValidatePlayerBuff(spellName) then
        return 1
    end
    return 0
end

-- Returns the current shapeshift / stance index
-- returns: The index of the current shapeshift form / stance. 0 if in no shapeshift form / stance
function CleveRoids.GetCurrentShapeshiftIndex()
    if CleveRoids.playerClass == "PRIEST" then
        return GetPlayerAuraIndex(CleveRoids.Localized.Spells["Shadowform"]) or 0 -- 修改识别形态序号 by 武藤纯子酱 2025.11.27
    elseif CleveRoids.playerClass == "ROGUE" then
        return GetPlayerAuraIndex(CleveRoids.Localized.Spells["Stealth"]) or 0 -- 修改识别形态序号 by 武藤纯子酱 2025.11.27
    end
    for i=1, GetNumShapeshiftForms() do
        _, _, active = GetShapeshiftFormInfo(i)
        if active then
            return i
        end
    end

    return 0
end

function CleveRoids.CancelAura(auraName)
    local ix = 0
    auraName = string.lower(string.gsub(auraName, "_"," "))

    -- v2.34+ path: cancel by spell ID (works for buff-capped overflow auras too)
    local API = CleveRoids.NampowerAPI
    if API and API.features.hasCancelPlayerAuraSpellId then
        -- Nampower path: scan buff aura slots 0-31 for spell IDs
        if API.features.hasGetPlayerAuraDuration and _G.GetPlayerAuraDuration then
            for slot = 0, 31 do
                local spellId = _G.GetPlayerAuraDuration(slot)
                if spellId and spellId > 0 then
                    local name = GetSpellRecField(spellId, "name")
                    if name and string.lower(name) == auraName then
                        _G.CancelPlayerAuraSpellId(spellId, 1)
                        return true
                    end
                end
            end
        end

        -- Not found in visible buffs - scan all 32 raw aura slots
        -- GetPlayerAuraDuration reads unit data fields directly (same 32 slots but bypasses UI filtering)
        if API.features.hasGetPlayerAuraDuration and _G.GetPlayerAuraDuration then
            for slot = 0, 31 do
                local spellId = _G.GetPlayerAuraDuration(slot)
                if spellId and spellId > 0 then
                    local name = GetSpellRecField(spellId, "name")
                    if name and string.lower(name) == auraName then
                        _G.CancelPlayerAuraSpellId(spellId, 1)
                        return true
                    end
                end
            end
        end

        -- Final fallback: check overflow buff tracking (buffs applied while buff-capped
        -- that have NO client aura slot - tracked via AURA_CAST_ON_SELF events)
        for spellId, entry in pairs(CleveRoids.OverflowBuffs) do
            -- Skip expired overflow entries
            local elapsed = GetTime() - (entry.timestamp or 0)
            if entry.durationSec and entry.durationSec > 0 and elapsed > entry.durationSec then
                CleveRoids.OverflowBuffs[spellId] = nil
            else
                local name = GetSpellRecField(spellId, "name")
                if name and string.lower(name) == auraName then
                    _G.CancelPlayerAuraSpellId(spellId, 1)
                    CleveRoids.OverflowBuffs[spellId] = nil
                    return true
                end
            end
        end
        return false
    end

    -- Legacy path for older Nampower versions (no GetPlayerAuraDuration) by 武藤纯子酱 2026.9.1
    while true do
        local aura_ix = GetPlayerBuff(ix,"HELPFUL")
        ix = ix + 1
        if aura_ix == -1 then break end

        AuraScanTooltip:SetPlayerBuff(aura_ix)
        -- 修复：空提示行时 GetText() 返回 nil，string.lower(nil) 抛错 by 武藤纯子酱 2026.9.12
        local name = string.lower(getglobal("AuraScanTooltipTextLeft1"):GetText() or "")
        if name == auraName then
            CancelPlayerBuff(aura_ix)
            break
        end

    end
    return false
end

function CleveRoids.HasGearEquipped(gearId)
    if not gearId then return false end

    -- PERFORMANCE: Build/refresh equipment cache if needed
    BuildEquipmentCache()

    -- Handle both numeric IDs and string IDs like "5196"
    local wantId = tonumber(gearId)
    local wantName = (type(gearId) == "string" and not wantId) and string.lower(gearId) or nil

    -- PERFORMANCE: Use cached data instead of scanning all slots
    for slot = 1, 19 do
        if wantId and _equippedItemIDs[slot] == wantId then
            return true
        end
        if wantName and _equippedItemNames[slot] == wantName then
            return true
        end
    end
    return false
end


-- Checks whether or not the given weaponType is currently equipped
-- weaponType: The name of the weapon's type (e.g. Axe, Shield, etc.)
-- returns: True when equipped, otherwhise false
function CleveRoids.HasWeaponEquipped(weaponType) -- 修复中文支持 by 武藤纯子酱 2025.11.27

    if not weaponType then
        return false
    end
    -- 修复：非字符串（条件值带比较符被解析成表）直接返回 false；用户值改用 plain 查找，
    -- 避免含 %()[].+ 等模式字符时抛 "malformed pattern" by 武藤纯子酱 2026.9.11
    if type(weaponType) ~= "string" then
        return false
    end

    for i=16,18 do        
        local slotLink = GetInventoryItemLink("player",i)        
        local itemId
        local _name,_link,_,_lvl,_type,subtype
        if slotLink then
            _,_,itemId = string.find(slotLink,"item:(%d+)")
        end
        
        if itemId then
            _name,_link,_,_lvl,_type,subtype = GetItemInfo(itemId)
        end

        if subtype then
            -- 修复：subtype 为空串时下方 string.find 匹配失败会令其变 nil，strfind(nil,...) 抛错 by 武藤纯子酱 2026.9.12
            local _,_,newSubtype = string.find(subtype,"%s?(%S+)$")

            if (newSubtype and (strfind(newSubtype,weaponType,1,true) or newSubtype == weaponType)) or _name == weaponType then -- plain 查找 by 武藤纯子酱 2026.9.11
                return true
            end            
        end
    end
    
    return false
end

-- Checks whether or not the given UnitId is in your party or your raid
-- target: The UnitId of the target to check
-- groupType: The name of the group type your target has to be in ("party" or "raid")
-- returns: True when the given target is in the given groupType, otherwhise false
function CleveRoids.IsTargetInGroupType(target, groupType)
    -- 修复：target 为 nil（宏不带 @token 时 conditionals.target 为 nil）→
    -- UnitIsUnit("party1", nil) 引擎报错；nil 视作当前目标 by 武藤纯子酱 2026.9.9
    if not target then target = "target" end
    local groupSize = (groupType == "raid") and 40 or 5

    for i = 1, groupSize do
        if UnitIsUnit(groupType..i, target) then
            return true
        end
    end

    return false
end

function CleveRoids.GetSpammableConditional(name)
    return CleveRoids.spamConditions[name] or "nomybuff"
end

-- PERFORMANCE: Cache for stripped spell names (removes rank suffix)
local _strippedNameCache = {}
local _strippedCacheSize = 0
local _STRIPPED_CACHE_MAX = 128

local function GetStrippedSpellName(name)
    if not name or name == "" then return "" end
    local cached = _strippedNameCache[name]
    if cached then return cached end

    local stripped = CleveRoids.StripRank(name) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
    if _strippedCacheSize < _STRIPPED_CACHE_MAX then
        _strippedNameCache[name] = stripped
        _strippedCacheSize = _strippedCacheSize + 1
    end
    return stripped
end

-- Checks whether or not we're currently casting a spell with cast time
-- Returns TRUE if we should allow the cast (not casting, or not casting the specified spell)
-- Returns FALSE if we should block the cast (currently casting)
function CleveRoids.CheckCasting(castingSpell)
    -- No parameter: check if we're casting ANYTHING
    if not castingSpell or castingSpell == "" then
        -- Time-based prediction: if we know cast duration, check if it should be done
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local elapsed = GetTime() - CleveRoids.castStartTime
            local remaining = CleveRoids.castDuration - elapsed

            -- If cast should be done (with 0.1s grace period), treat as not casting
            if remaining <= 0.1 then
                CleveRoids.CurrentSpell.type = ""
                return true
            end
        end

        return CleveRoids.CurrentSpell.type ~= "cast"
    end

    -- With parameter: check if we're casting a specific spell
    -- PERFORMANCE: Use cached stripped names to avoid string.gsub per call
    local spellName = GetStrippedSpellName(CleveRoids.CurrentSpell.spellName)
    local casting = GetStrippedSpellName(castingSpell)

    -- If we're casting this specific spell, block the recast
    if CleveRoids.CurrentSpell.type == "cast" and spellName == casting then
        return false
    end

    -- Not casting the specified spell, allow the cast
    return true
end

-- Checks whether or not we're currently casting a channeled spell
-- Returns TRUE if we should allow the cast (not channeling, or not channeling the specified spell)
-- Returns FALSE if we should block the cast (currently channeling)
function CleveRoids.CheckChanneled(channeledSpell)
    -- No parameter: check if we're channeling ANYTHING
    if not channeledSpell or channeledSpell == "" then
        -- Time-based prediction: if we know channel duration, check if it should be done
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local elapsed = GetTime() - CleveRoids.channelStartTime
            local remaining = CleveRoids.channelDuration - elapsed

            -- If channel should be done (with 0.1s grace period), treat as not channeling
            if remaining <= 0.1 then
                CleveRoids.CurrentSpell.type = ""
                return true
            end
        end

        -- 修复：与 [nochanneling] 无参分支同源——正在读条或已有排队法术时返回 false，
        -- 防止 Nampower 排队环境下的引导连发循环 by 武藤纯子酱 2026.9.9
        -- 帧内护栏：本帧前一行 /cast 已发起施法/排队（SPELL_QUEUE_EVENT 帧末才派发）同上 by 武藤纯子酱 2026.9.9
        if CleveRoids.CurrentSpell.type == "cast" or CleveRoids.queuedSpell or CleveRoids._castIssuedThisFrame then
            return false
        end

        return CleveRoids.CurrentSpell.type ~= "channeled"
    end

    -- Remove the "(Rank X)" part from the spells name in order to allow downranking
    -- PERFORMANCE: Use cached stripped names to avoid string.gsub per call
    local spellName = GetStrippedSpellName(CleveRoids.CurrentSpell.spellName)
    local channeled = GetStrippedSpellName(channeledSpell)

    -- If we're channeling this specific spell, block the recast
    if CleveRoids.CurrentSpell.type == "channeled" and spellName == channeled then
        return false
    end

    -- Special cases for auto-attacks
    if channeled == CleveRoids.Localized.Attack then
        -- ALWAYS check action bar state first - it's the authoritative source
        -- Event-based tracking can get stale if PLAYER_LEAVE_COMBAT doesn't fire properly
        local slot = CleveRoids.GetProxyActionSlot(CleveRoids.Localized.Attack)
        if slot then
            local isActive = IsCurrentAction(slot)
            -- Sync the event-based flag with actual game state
            CleveRoids.CurrentSpell.autoAttack = isActive
            if isActive then
                return false
            end
        elseif CleveRoids.CurrentSpell.autoAttack then
            -- No slot found but flag is set - trust event-based tracking
            -- (Attack not on action bar, but event says it's active)
            return false
        end
        return true
    end

    if channeled == CleveRoids.Localized.AutoShot then
        -- ALWAYS check action bar state first - it's the authoritative source
        -- Event-based tracking can get stale if STOP_AUTOREPEAT_SPELL doesn't fire
        local slot = CleveRoids.GetProxyActionSlot(CleveRoids.Localized.AutoShot)
        if slot then
            local isActive = IsAutoRepeatAction(slot)
            -- Sync the event-based flag with actual game state
            CleveRoids.CurrentSpell.autoShot = isActive
            if isActive then
                return false
            end
        elseif CleveRoids.CurrentSpell.autoShot then
            -- No slot found but flag is set - trust event-based tracking
            -- (Auto Shot not on action bar, but event says it's active)
            return false
        end
        return true
    end

    if channeled == CleveRoids.Localized.Shoot then
        -- ALWAYS check action bar state first - it's the authoritative source
        -- Event-based tracking can get stale if STOP_AUTOREPEAT_SPELL doesn't fire
        local slot = CleveRoids.GetProxyActionSlot(CleveRoids.Localized.Shoot)
        if slot then
            local isActive = IsAutoRepeatAction(slot)
            -- Sync the event-based flag with actual game state
            CleveRoids.CurrentSpell.wand = isActive
            if isActive then
                return false
            end
        elseif CleveRoids.CurrentSpell.wand then
            -- No slot found but flag is set - trust event-based tracking
            -- (Shoot not on action bar, but event says it's active)
            return false
        end
        return true
    end

    -- If none of the special cases matched, allow the cast (not channeling the specified spell)
    return true
end

function CleveRoids.ValidateComboPoints(operator, amount)
    if not operator or not amount then return false end
    local points = GetComboPoints()

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](points, amount)
    end

    return false
end

-- Returns percent of swing elapsed (0-100) from best available source, or nil
-- Priority: 1) SP_SwingTimer, 2) pfUI swing timer module
function CleveRoids.GetSwingPercentElapsed()
    -- Priority 1: SP_SwingTimer
    if st_timer ~= nil then
        local attackSpeed = st_timerMax or UnitAttackSpeed("player")
        if attackSpeed and attackSpeed > 0 then
            return ((attackSpeed - st_timer) / attackSpeed) * 100
        end
    end

    -- Priority 2: pfUI swing timer
    if pfUI and pfUI.swingtimer and pfUI.swingtimer.mainhand
       and pfUI.swingtimer.mainhand:IsShown() then
        return pfUI.swingtimer.mainhand:GetValue() * 100
    end

    return nil
end

-- Returns timeRemaining, swingSpeed from best available source, or nil, nil
-- Priority: 1) SP_SwingTimer, 2) pfUI swing timer + GetUnitField
function CleveRoids.GetSwingTimerRaw()
    -- Priority 1: SP_SwingTimer
    if st_timer ~= nil and st_timerMax ~= nil then
        return st_timer, st_timerMax
    end

    -- Priority 2: pfUI swing timer + GetUnitField
    if pfUI and pfUI.swingtimer and pfUI.swingtimer.mainhand
       and pfUI.swingtimer.mainhand:IsShown() and GetUnitField then
        local mhSpeed = GetUnitField("player", "baseAttackTime")
        if mhSpeed and mhSpeed > 0 then
            local swingSpeed = mhSpeed / 1000
            local progress = pfUI.swingtimer.mainhand:GetValue()
            local timeRemaining = (1 - progress) * swingSpeed
            return timeRemaining, swingSpeed
        end
    end

    return nil, nil
end

-- Validates swing timer percentage for SP_SwingTimer / pfUI integration
-- operator: Comparison operator (>, <, =, >=, <=, ~=)
-- amount: Percentage of swing time elapsed (e.g., 20 means 20% of swing has elapsed)
-- returns: True if percentElapsed [operator] amount
function CleveRoids.ValidateSwingTimer(operator, amount)
    if not operator or not amount then return false end

    local percentElapsed = CleveRoids.GetSwingPercentElapsed()
    if percentElapsed == nil then
        -- Only show error once per session
        if not CleveRoids._swingTimerErrorShown then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swingtimer] conditional requires SP_SwingTimer or pfUI (swing timer module). Get SP_SwingTimer at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
            CleveRoids._swingTimerErrorShown = true
        end
        return false
    end

    -- Compare percent elapsed against threshold
    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](percentElapsed, amount)
    end

    return false
end

-- Constants for Slam window calculations
local GCD_DURATION = 1.5  -- Global cooldown in seconds
local DEFAULT_SLAM_CAST = 2.5  -- Default Slam cast time in Turtle WoW

-- Cache for Slam cast time from tooltip
local cachedSlamCastTime = nil
local slamCastTimeLastUpdate = 0
local SLAM_CACHE_DURATION = 2  -- Re-scan tooltip every 2 seconds

-- Hidden tooltip for scanning spell info
local SlamScanTooltip = nil

-- Create hidden tooltip for scanning (once)
local function GetSlamScanTooltip()
    if not SlamScanTooltip then
        SlamScanTooltip = CreateFrame("GameTooltip", "CleveRoidsSlamScanTooltip", nil, "GameTooltipTemplate")
        SlamScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return SlamScanTooltip
end

-- Parse cast time from tooltip text (e.g., "1.5 sec cast" or "1.59 sec cast")
local function ParseCastTimeFromText(text)
    if not text then return nil end
    -- Match patterns like "1.5 sec cast", "1.59 sec cast", "2 sec cast"
    -- Use string.find for Lua 5.0 compatibility (string.match is Lua 5.1+)
    local _, _, castTime = string.find(text, CleveRoids.Localized.SpellDuration["(%d+%.?%d*) sec cast"]) -- 修复多语言支持 by 武藤纯子酱 2026.2.10
    if castTime then
        return tonumber(castTime)
    end
    return nil
end

-- Get Slam's spellbook slot
local function GetSlamSpellSlot()
    -- Search through spellbook for Slam
    local i = 1
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then break end
        if spellName == CleveRoids.Localized.Spells["Slam"] then -- 修复多语言支持 by 武藤纯子酱 2026.2.10
            return i, BOOKTYPE_SPELL
        end
        i = i + 1
    end
    return nil, nil
end
-- Expose for debug command
CleveRoids.GetSlamSpellSlot = GetSlamSpellSlot

-- Scan Slam tooltip for cast time
local function ScanSlamCastTime()
    local slot, bookType = GetSlamSpellSlot()
    if not slot then return nil end

    local tooltip = GetSlamScanTooltip()
    tooltip:ClearLines()
    tooltip:SetSpell(slot, bookType)

    -- Scan tooltip lines for cast time
    for i = 1, tooltip:NumLines() do
        local leftText = getglobal("CleveRoidsSlamScanTooltipTextLeft" .. i)
        if leftText then
            local text = leftText:GetText()
            local castTime = ParseCastTimeFromText(text)
            if castTime then
                return castTime
            end
        end
        local rightText = getglobal("CleveRoidsSlamScanTooltipTextRight" .. i)
        if rightText then
            local text = rightText:GetText()
            local castTime = ParseCastTimeFromText(text)
            if castTime then
                return castTime
            end
        end
    end

    return nil
end

-- Get Slam's cast time in seconds (with caching)
-- Reads from spellbook tooltip to get accurate cast time with haste/talents
function CleveRoids.GetSlamCastTime()
    local now = GetTime()

    -- Use cached value if still valid
    if cachedSlamCastTime and (now - slamCastTimeLastUpdate) < SLAM_CACHE_DURATION then
        return cachedSlamCastTime
    end

    -- Try to scan tooltip for cast time
    local castTime = ScanSlamCastTime()
    if castTime and castTime > 0 then
        cachedSlamCastTime = castTime
        slamCastTimeLastUpdate = now
        return castTime
    end

    -- Fall back to default
    return DEFAULT_SLAM_CAST
end

-- Force refresh of cached Slam cast time (call when buffs change)
function CleveRoids.RefreshSlamCastTime()
    cachedSlamCastTime = nil
    slamCastTimeLastUpdate = 0
end

-- Calculate maximum elapsed swing timer % to cast Slam without clipping auto-attack
-- Formula: MaxSlamPercent = (SwingTimer - SlamCastTime) / SwingTimer * 100
-- IMPORTANT: Uses st_timerMax (SP_SwingTimer's adjusted swing timer) not UnitAttackSpeed
-- because Flurry and other buffs modify st_timerMax but not UnitAttackSpeed
function CleveRoids.GetSlamWindowPercent()
    -- Use swing speed from best available source (SP_SwingTimer or pfUI)
    -- Fall back to UnitAttackSpeed if neither available
    local _, swingSpeed = CleveRoids.GetSwingTimerRaw()
    local attackSpeed = swingSpeed or UnitAttackSpeed("player")
    if not attackSpeed or attackSpeed <= 0 then return 0 end

    local slamCastTime = CleveRoids.GetSlamCastTime()
    local maxSlamStart = attackSpeed - slamCastTime

    if maxSlamStart <= 0 then return 0 end  -- Slam cast time exceeds swing timer

    return (maxSlamStart / attackSpeed) * 100
end

-- Calculate maximum elapsed swing timer % to cast instant without clipping NEXT Slam
-- Scenario: No Slam this swing, cast instant, then Slam next swing without clipping
-- Formula: MaxInstantPercent = (2 * SwingTimer - SlamCastTime - GCD) / SwingTimer * 100
function CleveRoids.GetInstantWindowPercent()
    -- Use swing speed from best available source (SP_SwingTimer or pfUI)
    local _, swingSpeed = CleveRoids.GetSwingTimerRaw()
    local attackSpeed = swingSpeed or UnitAttackSpeed("player")
    if not attackSpeed or attackSpeed <= 0 then return 0 end

    local slamCastTime = CleveRoids.GetSlamCastTime()
    local maxInstantStart = (2 * attackSpeed) - slamCastTime - GCD_DURATION

    if maxInstantStart <= 0 then return 0 end  -- Window is impossible with current timings

    return (maxInstantStart / attackSpeed) * 100
end

-- Returns timeRemaining, rangedSpeed from SP_SwingTimer, or nil, nil
function CleveRoids.GetRangedTimerRaw()
    if st_timerRange ~= nil and st_timerRangeMax ~= nil and st_timerRangeMax > 0 then
        return st_timerRange, st_timerRangeMax
    end

    if Abar_Mhr and ( Abar_Mhr:IsShown() or CleveRoids.Localized.AutoShot ) and Abar_Mhr.txt and string.find(Abar_Mhr.txt, "自动射击") then -- 新增通过AttackBar插件识别自动射击 by 武藤纯子酱 2026.3.24
        local now = GetTime()
        local remaining = Abar_Mhr.et - now
        if remaining and remaining < 0 then
            remaining = 0
        end
        local speed = Abar_Mhr.et - Abar_Mhr.st
        if speed > 0 then
            return remaining, speed
        end
    end

    return nil, nil
end

-- Returns percent of ranged swing elapsed (0-100) from SP_SwingTimer, or nil
function CleveRoids.GetRangedPercentElapsed()
    local remaining, speed = CleveRoids.GetRangedTimerRaw() -- 新增通过AttackBar插件识别自动射击 by 武藤纯子酱 2026.3.24
    if remaining ~= nil and speed ~= nil and speed > 0 then
        return ((speed - remaining) / speed) * 100
    end
    return nil
end

-- Validates ranged swing timer percentage for SP_SwingTimer integration
-- operator: Comparison operator (>, <, =, >=, <=, ~=)
-- amount: Percentage of ranged swing time elapsed (e.g., 80 means 80% has elapsed)
-- returns: True if percentElapsed [operator] amount
function CleveRoids.ValidateRangedTimer(operator, amount)
    if not operator or not amount then return false end

    local percentElapsed = CleveRoids.GetRangedPercentElapsed()
    if percentElapsed == nil then
        -- 修复：AttackBar 存在但计时器未激活时 percentElapsed 仍为 nil，
        -- 原守卫（`and not Abar_Mhr`）被绕过后直接比较 nil 报错；无数据一律返回 false by 武藤纯子酱 2026.8.31
        if not Abar_Mhr then
            if not CleveRoids._rangedTimerErrorShown then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [rangedtimer] conditional requires SP_SwingTimer. Get it at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                CleveRoids._rangedTimerErrorShown = true
            end
        end
        return false
    end

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](percentElapsed, amount)
    end

    return false
end

-- Validate if casting the action's spell NOW will NOT clip the ranged auto-shot
-- Returns true if rangedTimeRemaining >= spellCastTime (enough time to finish cast before next auto)
-- If ranged timer is not active, returns true (nothing to clip)
function CleveRoids.ValidateNoRangedClip(conditionals)
    local remaining, rangedSpeed = CleveRoids.GetRangedTimerRaw()

    if remaining == nil then
        -- No ranged timer available — either no addon or timer not active (nothing to clip)
        if st_timerRangeMax == nil and not CleveRoids._rangedClipErrorShown and not Abar_Mhr then -- 新增通过AttackBar插件识别自动射击 by 武藤纯子酱 2026.3.24
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [norangedclip] conditional requires SP_SwingTimer. Get it at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
            CleveRoids._rangedClipErrorShown = true
        end
        return true
    end

    -- Get the cast time of the action spell
    local actionName = conditionals and conditionals.action
    if not actionName then return true end

    local castTime = CleveRoids.GetSpellCastTime(actionName)
    if not castTime or castTime <= 0 then
        return true  -- Instant cast, no clip possible
    end

    return remaining >= castTime
end

-- Validate if current swing timer is within the Slam window (no clip)
-- Returns true if casting Slam NOW will NOT clip the auto-attack
function CleveRoids.ValidateNoSlamClip()
    local percentElapsed = CleveRoids.GetSwingPercentElapsed()
    if percentElapsed == nil then
        if not CleveRoids._slamClipErrorShown then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [noslamclip] conditional requires SP_SwingTimer or pfUI (swing timer module). Get SP_SwingTimer at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
            CleveRoids._slamClipErrorShown = true
        end
        return false
    end

    local maxPercent = CleveRoids.GetSlamWindowPercent()
    return percentElapsed <= maxPercent
end

-- Validate if current swing timer is within the instant window for next Slam
-- Returns true if casting an instant NOW will NOT cause the NEXT Slam to clip
function CleveRoids.ValidateNoNextSlamClip()
    local percentElapsed = CleveRoids.GetSwingPercentElapsed()
    if percentElapsed == nil then
        if not CleveRoids._slamClipErrorShown then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [nonextslamclip] conditional requires SP_SwingTimer or pfUI (swing timer module). Get SP_SwingTimer at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
            CleveRoids._slamClipErrorShown = true
        end
        return false
    end

    local maxPercent = CleveRoids.GetInstantWindowPercent()
    return percentElapsed <= maxPercent
end

-- ============================================================================
-- SPELL CAST TIME CONDITIONAL
-- ============================================================================
-- Checks a spell's cast time from tooltip (guaranteed accurate with all buffs)
-- Usage: [spellcasttime:>2] - action's spell has cast time > 2 seconds
--        [spellcasttime:Frostbolt>2] - Frostbolt has cast time > 2 seconds

-- Cache for spell cast times
local spellCastTimeCache = {}
local spellCastTimeCacheTime = {}
local SPELL_CAST_TIME_CACHE_DURATION = 0.5  -- Cache for 0.5 seconds (buffs can change)

-- Hidden tooltip for scanning spell cast time
local SpellCastTimeScanTooltip = nil

-- Create hidden tooltip for scanning (once)
local function GetSpellCastTimeScanTooltip()
    if not SpellCastTimeScanTooltip then
        SpellCastTimeScanTooltip = CreateFrame("GameTooltip", "CleveRoidsSpellCastTimeScanTooltip", nil, "GameTooltipTemplate")
        SpellCastTimeScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    end
    return SpellCastTimeScanTooltip
end

-- Get spell slot in spellbook by name (returns highest rank)
local function GetSpellSlotByName(spellName)
    if not spellName then return nil, nil end

    -- Check indexed spells first for performance
    if CleveRoids.Spells and CleveRoids.Spells[BOOKTYPE_SPELL] then
        local spellData = CleveRoids.Spells[BOOKTYPE_SPELL][spellName]
        if spellData then
            -- Prefer highest rank's slot
            if spellData.highest and spellData.highest.spellSlot then
                return spellData.highest.spellSlot, BOOKTYPE_SPELL
            end
            if spellData.spellSlot then
                return spellData.spellSlot, BOOKTYPE_SPELL
            end
        end
    end

    -- Fallback: search spellbook directly for highest rank
    local foundSlot = nil
    local i = 1
    while true do
        local name, rank = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then break end
        if name == spellName then
            foundSlot = i  -- Keep updating to get highest rank (last match)
        end
        i = i + 1
    end

    if foundSlot then
        return foundSlot, BOOKTYPE_SPELL
    end

    return nil, nil
end

-- Scan spell tooltip for cast time
-- Returns cast time in seconds, or nil if not found
local function ScanSpellCastTime(spellName)
    local slot, bookType = GetSpellSlotByName(spellName)
    if not slot then return nil end

    local tooltip = GetSpellCastTimeScanTooltip()
    tooltip:ClearLines()
    tooltip:SetSpell(slot, bookType)

    -- Scan tooltip lines for cast time
    for i = 1, tooltip:NumLines() do
        local leftText = getglobal("CleveRoidsSpellCastTimeScanTooltipTextLeft" .. i)
        if leftText then
            local text = leftText:GetText()
            if text then
                -- Match patterns like "1.5 sec cast", "2 sec cast"
                -- Use string.find for Lua 5.0 compatibility
                local _, _, castTime = string.find(text, CleveRoids.Localized.SpellDuration["(%d+%.?%d*) sec cast"]) -- 修复多语言支持 by 武藤纯子酱 2026.2.10
                if castTime then
                    return tonumber(castTime)
                end
                -- Check for instant cast
                if string.find(text, CleveRoids.Localized.SpellDuration["Instant"]) then -- 修复多语言支持 by 武藤纯子酱 2026.2.10
                    return 0
                end
                -- 新增攻击速度 by 武藤纯子酱 2026.3.24
                if string.find(text, CleveRoids.Localized.SpellDuration["Attack Speed"]) then
                    return 0.5
                end
            end
        end
        local rightText = getglobal("CleveRoidsSpellCastTimeScanTooltipTextRight" .. i)
        if rightText then
            local text = rightText:GetText()
            if text then
                local _, _, castTime = string.find(text, CleveRoids.Localized.SpellDuration["(%d+%.?%d*) sec cast"]) -- 修复多语言支持 by 武藤纯子酱 2026.2.10
                if castTime then
                    return tonumber(castTime)
                end
                if string.find(text, CleveRoids.Localized.SpellDuration["Instant"]) then -- 修复多语言支持 by 武藤纯子酱 2026.2.10
                    return 0
                end
                -- 新增攻击速度 by 武藤纯子酱 2026.3.24
                if string.find(text, CleveRoids.Localized.SpellDuration["Attack Speed"]) then
                    return 0.5
                end
            end
        end
    end

    return nil
end

-- Get spell cast time (includes all modifiers when possible)
-- Returns cast time in seconds, or nil if spell not found
-- Priority: 1) Tooltip (accurate with haste/talents), 2) Nampower DBC (base cast time, works for all spells)
function CleveRoids.GetSpellCastTime(spellName)
    if not spellName then return nil end

    -- Normalize spell name (underscores to spaces)
    spellName = CleveRoids.NormalizeName(spellName)

    local now = GetTime()

    -- Check cache first
    if spellCastTimeCache[spellName] ~= nil then
        local cacheAge = now - (spellCastTimeCacheTime[spellName] or 0)
        if cacheAge < SPELL_CAST_TIME_CACHE_DURATION then
            return spellCastTimeCache[spellName]
        end
    end

    -- Try tooltip first (most accurate — reflects haste, talents, overflow buffs)
    local castTime = ScanSpellCastTime(spellName)

    -- Fallback: Nampower DBC cast time (base value, no modifiers — better than nil)
    if castTime == nil and CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetSpellCastTime then
        local spellId = nil
        if GetSpellIdForName then
            spellId = GetSpellIdForName(spellName)
        end
        if spellId then
            castTime = CleveRoids.NampowerAPI.GetSpellCastTime(spellId)
        end
    end

    -- Cache the result (even nil to avoid repeated lookups)
    spellCastTimeCache[spellName] = castTime
    spellCastTimeCacheTime[spellName] = now

    return castTime
end

-- Validate spell cast time conditional
-- spellName: Spell to check (or nil to use action's spell)
-- operator: Comparison operator (>, <, =, etc.)
-- amount: Time threshold in seconds
function CleveRoids.ValidateSpellCastTime(spellName, operator, amount)
    if not operator or not amount then return false end

    local castTime = CleveRoids.GetSpellCastTime(spellName)
    if castTime == nil then
        return false  -- Spell not found in spellbook
    end

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](castTime, amount)
    end

    return false
end

-- Clear spell cast time cache (call when buffs/haste changes)
function CleveRoids.ClearSpellCastTimeCache()
    spellCastTimeCache = {}
    spellCastTimeCacheTime = {}
end

-- ============================================================================

function CleveRoids.ValidateLevel(unit, operator, amount)
    if not unit or not operator or not amount then return false end
    local level = UnitLevel(unit)

    -- Treat skull/boss mobs (??) as level 63
    if level == -1 then
        level = 63
    end

    if level and CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](level, amount)
    end

    return false
end

--- Validates a threat percentage conditional using server threat data.
--- Usage: [threat:>80] [threat:<50] [threat:=100]
--- operator: Comparison operator (>, <, =, >=, <=, ~=)
--- amount: Threat percentage (0-100+, where 100 = will pull aggro)
--- returns: True if playerThreat [operator] amount
--- Note: Requires TWThreat addon to be running (sends threat requests to server)
function CleveRoids.ValidateThreat(operator, amount)
    if not operator or not amount then return false end

    -- Get threat percentage from parsed server data
    local threatpct = CleveRoids.GetPlayerThreatPercent()

    -- No threat data available
    if threatpct == nil then
        return false
    end

    -- Compare threat percentage against threshold
    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](threatpct, amount)
    end

    return false
end

--- Validates a Time-To-Kill conditional using TimeToKill addon.
--- Usage: [ttk:<10] [ttk:>30] [ttk:=5]
--- operator: Comparison operator (>, <, =, >=, <=, ~=)
--- amount: Time in seconds until target death
--- returns: True if TTK [operator] amount
function CleveRoids.ValidateTTK(operator, amount, conditionals)
    if not operator or not amount then return false end
    local ttk  -- 修复：ttk/tte 原为全局泄漏，且 conditionals 需由调用方传入（原直接引用不存在的全局导致报错） by 武藤纯子酱 2026.8.31
    -- Check if TimeToKill is loaded
    if type(TimeToKill) ~= "table" or type(TimeToKill.GetTTK) ~= "function" then
        ttk = CleveRoids.GetTargetDeathTime((conditionals and conditionals.target) or "target")
    else
        ttk = TimeToKill.GetTTK()
    end

    --local ttk = TimeToKill.GetTTK()
    if ttk == nil then
        return false -- Not tracking TTK
    end

    -- Compare TTK against threshold
    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](ttk, amount)
    end

    return false
end

--- Validates a Time-To-Execute conditional using TimeToKill addon.
--- Usage: [tte:<5] [tte:>10]
--- operator: Comparison operator (>, <, =, >=, <=, ~=)
--- amount: Time in seconds until target reaches 20% HP
--- returns: True if TTE [operator] amount
function CleveRoids.ValidateTTE(operator, amount, conditionals)
    if not operator or not amount then return false end
    local tte  -- 将tte提前定义 by 武藤纯子酱 2026.1.27（修复：原引用不存在的全局 conditionals，改为由调用方传入 by 武藤纯子酱 2026.8.31）
    -- Check if TimeToKill is loaded
    if type(TimeToKill) ~= "table" or type(TimeToKill.GetTTE) ~= "function" then
        tte = CleveRoids.GetTargetPercent20Time((conditionals and conditionals.target) or "target")
    else
        tte = TimeToKill.GetTTE()
    end

    --local tte = TimeToKill.GetTTE()
    if tte == nil then
        return false -- Not tracking or already in execute phase
    end

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](tte, amount)
    end

    return false
end

-- ============================================================================
-- MONKEYSPEED ADDON INTEGRATION
-- ============================================================================
-- Integrates with MonkeySpeed addon for accurate movement speed detection
-- MonkeySpeed uses SuperWoW's UnitPosition to calculate actual movement speed

--- Check if MonkeySpeed addon is available and loaded
--- @return boolean True if MonkeySpeed is available with speed data
function CleveRoids.HasMonkeySpeed()
    return type(MonkeySpeed) == "table" and
           MonkeySpeed.m_bLoaded == true and
           MonkeySpeed.m_fSpeed ~= nil
end

--- Require MonkeySpeed for a feature, warn once if missing
--- @param feature string Feature name for warning message
--- @return boolean True if MonkeySpeed is available
function CleveRoids.RequireMonkeySpeed(feature)
    if CleveRoids.HasMonkeySpeed() then
        return true
    end
    if not CleveRoids._monkeySpeedErrorShown then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [moving] speed conditional requires the MonkeySpeed addon.", 1, 0.5, 0.5)
        CleveRoids._monkeySpeedErrorShown = true
    end
    return false
end

--- Get current player movement speed as percentage (100 = normal run speed)
--- @return number|nil Speed percentage, or nil if MonkeySpeed not available
function CleveRoids.GetPlayerSpeed()
    if not CleveRoids.HasMonkeySpeed() then
        return nil
    end
    return MonkeySpeed.m_fSpeed or 0
end

--- Check if player is currently moving (speed > 0)
--- Falls back to basic position checking if MonkeySpeed isn't available
--- @return boolean True if player is moving
function CleveRoids.IsPlayerMoving()
    -- If MonkeySpeed is available, use it for accurate speed-based detection
    if CleveRoids.HasMonkeySpeed() then
        return (MonkeySpeed.m_fSpeed or 0) > 0
    end

    -- Nampower 2.36+ provides direct movement flag query (catches jumping, falling, pitching)
    if CleveRoids.NampowerAPI.features.hasPlayerIsMoving then
        return PlayerIsMoving() == 1
    end

    -- Fallback: use continuously tracked position history from OnUpdate
    -- Core.lua tracks position at ~100 Hz with 4-sample circular buffer (matches MonkeySpeed's 0.01s).
    -- Movement is detected if ANY consecutive pair of samples shows movement.
    -- This gives instant start-of-movement detection (first sample shows delta).
    local history = CleveRoids._positionHistory
    local count = CleveRoids._posHistoryCount or 0
    local headIdx = CleveRoids._posHistoryIndex or 0

    if history and count >= 2 then
        -- Compare the most recent pair: headIdx (newest) vs. the slot before it.
        -- Use (headIdx - 2 + 4) mod 4 to safely wrap backwards in the 1-based ring.
        -- This avoids Lua 5.0 math.mod returning negative values for negative inputs.
        local prevIdx = math.mod((headIdx - 2 + 4), 4) + 1
        local curr = history[headIdx]
        local prev = history[prevIdx]
        if curr and prev then
            -- 修复：原代码直接使用未定义的 dx/dy 全局（必然为 nil → 算术报错），补上应有的位移计算 by 武藤纯子酱 2026.8.31
            local dx = curr.x - prev.x
            local dy = curr.y - prev.y
            return math.sqrt(dx * dx + dy * dy) > 0.001
        end
        return false
    end

    -- Legacy fallback for code that might not have history yet
    local current = CleveRoids._currentPlayerPos
    local previous = CleveRoids._previousPlayerPos

    if current and previous then
        local dx = current.x - previous.x
        local dy = current.y - previous.y
        local dist = math.sqrt(dx * dx + dy * dy)
        return dist > 0.001
    end

    -- Not enough data yet (first 0.15s after login) - assume not moving
    return false
end

--- Validates a movement speed conditional.
--- Usage: [moving:>100] [moving:<50] [moving:=0]
--- operator: Comparison operator (>, <, =, >=, <=, ~=)
--- amount: Speed percentage (100 = normal run speed)
--- returns: True if speed [operator] amount
function CleveRoids.ValidateMovingSpeed(operator, amount)
    if not operator or not amount then return false end

    -- Check if MonkeySpeed is available for speed comparisons
    if not CleveRoids.RequireMonkeySpeed("moving speed comparison") then
        return false
    end

    local speed = CleveRoids.GetPlayerSpeed()
    if speed == nil then
        return false
    end

    -- Compare speed against threshold
    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](speed, amount)
    end

    return false
end

-- ============================================================================
-- ENEMY COUNTING FOR MULTI-UNIT CONDITIONALS
-- ============================================================================
-- Enables conditionals like [meleerange:>1], [behind:>=2], [inrange:Spell>1]
-- Uses UnitXP to enumerate nearby enemies and count those matching a condition

--- Persistent set of known enemy GUIDs.
--- Populated by nameplate scans, unit token checks, and PLAYER_TARGET_CHANGED.
--- Cleaned up on UNIT_DIED and ZONE_CHANGED_NEW_AREA.
--- Stale entries are naturally filtered by UnitExists(guid) at query time.
CleveRoids.knownEnemyGuids = {}

-- ============================================================================
-- 敌对目标候选列表缓存 by 武藤纯子酱 2026.8.31
-- 修复"带遍历的条件（尤其敌对目标遍历）偶尔卡死数秒，必须松手才能恢复"：
--   1) 原先每次条件求值都各自做一遍全量敌对枚举（目标+队友目标+名牌+缓存），
--      一次宏求值里有多个遍历条件（[inrange:技能>N]、[melee_enemies] 等）时重复枚举；
--   2) knownEnemyGuids 只增不减，长时间战斗/刷怪后积累大量失效 GUID，每次求值
--      都要对全部陈旧 GUID 逐个 UnitExists/CanAttack/死亡判定/checkFunc；
--   3) 按住宏连打时每次按键都要 0.5~2 秒，输入队列积压表现为游戏卡死、松手后
--      等当前求值跑完才恢复。
-- 现在候选列表按 baseUnit+testing 缓存 0.1 秒（同一求值内多个遍历条件共享一次
-- 枚举）；knownEnemyGuids 的值改为"最近出现时间"并在构建候选时剪枝
-- （对象不存在 / 已死亡 / 60 秒未再出现的 GUID 直接移除）。
-- ============================================================================

local _enemyCandidateCache = { list = {}, n = 0, baseUnit = nil, testing = false, expires = 0 }

--- Build (or fetch cached) list of nearby enemy candidates.
--- @param baseUnit string - Unit to check hostility against (usually "player")
--- @return table list, number count - candidate units/GUIDs (deduped)
-- 性能优化：把原先每次重建都新建的 addCandidate/tryUnit 闭包提升为模块级，
-- 通过 _enemyCandState 传递状态（list/n/seen），避免每次枚举的分帧 GC by 武藤纯子酱 2026.9.11
local _enemyCandState = { list = nil, n = 0, seen = nil }

-- 校验单位 token 字符串是否可用：只做“非 nil、非空串、字符串”的语法层面判断，用于避免
-- UnitCanAttack(nil, …) 这类 "Usage:UnitCanAttack" 报错。
-- 注意：不能用 UnitExists 判定——它对“语法合法但当前不存在”的（无宠物时的 "pet"、无焦点时的 "focus"）
-- 同样返回 nil，会把合法基准单位误判为非法而改变语义 by 武藤纯子酱 2026.9.23
function CleveRoids.IsValidUnitToken(unit)
    return type(unit) == "string" and unit ~= ""
end

-- UnitCanAttack 对非法单位 token 会直接抛 "Usage" 错，统一包一层 pcall 防崩 by 武藤纯子酱 2026.9.23
local function _safeCanAttack(a, b)
    local ok, res = pcall(UnitCanAttack, a, b)
    return (ok and res) and true or false
end

local function _addCandidate(unit, guid)
    local st = _enemyCandState
    if guid then st.seen[guid] = true end
    st.n = st.n + 1
    st.list[st.n] = unit
end

local function _tryEnemyUnit(baseUnit, now, unit)
    if not UnitExists(unit) then return end
    if not _safeCanAttack(baseUnit, unit) then return end
    if CleveRoids.IsUnitDeadOrGhost(unit) then return end
    local guid = CleveRoids.GetGUID(unit)
    local st = _enemyCandState
    if not guid or st.seen[guid] then return end
    CleveRoids.knownEnemyGuids[guid] = now
    _addCandidate(unit, guid)
end

function CleveRoids.BuildEnemyCandidateList(baseUnit)
    -- 防御：baseUnit 非法时回退 player，否则下方 _safeCanAttack(baseUnit, "target") 会报
    -- "Usage:UnitCanAttack("unit","otherUnit")" by 武藤纯子酱 2026.9.23
    if not CleveRoids.IsValidUnitToken(baseUnit) then baseUnit = "player" end

    local now = GetTime()
    local cache = _enemyCandidateCache
    local testing = CleveRoids._isTestingAction and true or false
    if cache.baseUnit == baseUnit and cache.testing == testing and now < cache.expires then
        return cache.list, cache.n
    end

    local list = cache.list
    local seen = {}
    _enemyCandState.list = list
    _enemyCandState.n = 0
    _enemyCandState.seen = seen

    -- 1. Current target
    if UnitExists("target") and _safeCanAttack(baseUnit, "target") and not CleveRoids.IsUnitDeadOrGhost("target") then
        local guid = CleveRoids.GetGUID("target")
        if guid then
            CleveRoids.knownEnemyGuids[guid] = now
        end
        _addCandidate("target", guid)
    end

    -- 2. Nearby unit tokens (no target switching)
    _tryEnemyUnit(baseUnit, now, "targettarget")
    _tryEnemyUnit(baseUnit, now, "targettargettarget")
    _tryEnemyUnit(baseUnit, now, "pettarget")
    if pfUI and pfUI.uf and pfUI.uf.focus and pfUI.uf.focus.label and pfUI.uf.focus.id then
        local focusUnit = pfUI.uf.focus.label .. pfUI.uf.focus.id
        _tryEnemyUnit(baseUnit, now, focusUnit)
        _tryEnemyUnit(baseUnit, now, focusUnit .. "target")
    elseif (DFRLFocusCore or FocusCore) then -- 新增对FocusFrame的支持 by 武藤纯子酱 2026.3.31
        local focusUnit = select(2, (DFRLFocusCore or FocusCore):GetName())
        if focusUnit and UnitExists(focusUnit) then
            _tryEnemyUnit(baseUnit, now, focusUnit)
            _tryEnemyUnit(baseUnit, now, focusUnit .. "target")
        end
    end
    for i = 1, 4 do
        _tryEnemyUnit(baseUnit, now, "party" .. i .. "target")
    end
    if GetNumRaidMembers() > 0 then
        for i = 1, 40 do
            _tryEnemyUnit(baseUnit, now, "raid" .. i .. "target")
        end
    end

    -- 3. Nameplate scan: visible nameplates give live GUIDs without target switching
    --    Requires Nampower v2.28+ (hasNameplateGUID) by 武藤纯子酱 2026.9.1
    local API = CleveRoids.NampowerAPI
    if API and API.features.hasNameplateGUID then
        local numChildren = WorldFrame:GetNumChildren()
        local children = { WorldFrame:GetChildren() }
        for i = 1, numChildren do
            local frame = children[i]
            if frame and frame:IsVisible() then
                local success, guid = pcall(frame.GetName, frame, 1)
                if success and guid and type(guid) == "string" and string.len(guid) > 0 and not seen[guid] then
                    if UnitExists(guid) and _safeCanAttack(baseUnit, guid) and not CleveRoids.IsUnitDeadOrGhost(guid) then -- 排除死亡或灵魂状态目标 by 武藤纯子酱 2026.5.6
                        CleveRoids.knownEnemyGuids[guid] = now
                        _addCandidate(guid, guid)
                    end
                end
            end
        end
    end

    -- 4. Previously-seen enemies (stealthed units, enemies that left nameplate range, etc.)
    --    During tooltip evaluation, skip known-enemy cache iteration (keep original semantics)
    if not testing then
        for guid, lastSeen in pairs(CleveRoids.knownEnemyGuids) do
            if not seen[guid] then
                if not UnitExists(guid) then
                    CleveRoids.knownEnemyGuids[guid] = nil -- 对象已不存在，剪枝 by 武藤纯子酱 2026.8.31
                elseif CleveRoids.IsUnitDeadOrGhost(guid) then
                    CleveRoids.knownEnemyGuids[guid] = nil -- 已死亡/灵魂状态，剪枝 by 武藤纯子酱 2026.8.31
                elseif _safeCanAttack(baseUnit, guid) then
                    CleveRoids.knownEnemyGuids[guid] = now
                    _addCandidate(guid, guid)
                elseif type(lastSeen) == "number" and now - lastSeen > 60 then
                    CleveRoids.knownEnemyGuids[guid] = nil -- 60 秒未再出现，剪枝（仅对数字时间戳做算术，防布尔值崩溃）by 武藤纯子酱 2026.9.28
                end
            end
        end
    end

    local n = _enemyCandState.n
    cache.list = list
    cache.n = n
    cache.baseUnit = baseUnit
    cache.testing = testing
    cache.expires = now + 0.1
    return list, n
end

--- Count enemies matching a condition function.
--- Enumerates nearby enemies via nameplate GUIDs, unit tokens (party/raid targets,
--- focus, targettarget, etc.), and previously-seen GUIDs. Never switches the
--- player's target, so combo points and target state are preserved.
--- @param checkFunc function(unit) -> boolean - Returns true if unit matches condition
--- @return number - Count of matching enemies (0 if no detection method available)
function CleveRoids.CountEnemiesMatching(checkFunc, baseUnit) -- 新增baseUnit参数 by 武藤纯子酱 2026.4.13
    -- 修复：原 pcall(UnitExists, baseUnit) 拦不住 nil/未知 token（UnitExists 返回 nil 而不抛错），
    -- 导致 baseUnit 仍是 nil/非法，随后 UnitCanAttack 抛 Usage 错 by 武藤纯子酱 2026.9.23
    if not CleveRoids.IsValidUnitToken(baseUnit) then
        baseUnit = "player"
    end

    -- 使用缓存的候选列表（0.1 秒内多个遍历条件共享一次枚举） by 武藤纯子酱 2026.8.31
    local candidates, n = CleveRoids.BuildEnemyCandidateList(baseUnit)

    local count = 0
    for i = 1, n do
        if checkFunc(candidates[i]) then
            count = count + 1
        end
    end

    return count
end

--- Check if conditional arguments contain count mode (operator + amount)
--- @param conditionalValue any - The value from conditionals[name]
--- @return table|nil - The args table with operator/amount if count mode, nil otherwise
function CleveRoids.GetCountModeArgs(conditionalValue)
    if type(conditionalValue) ~= "table" then return nil end

    local args = conditionalValue[1]
    if type(args) == "table" and ( ( args.operator and args.amount ) or args.comparisons ) then -- 新增对多重比较的支持 by 武藤纯子酱 2026.1.25
        return args
    end
    return nil
end

-- ============================================================================
-- PFUI TANK INTEGRATION
-- ============================================================================
-- Integrates with pfUI's tank systems for targeting loose mobs
-- Checks BOTH:
--   1. pfUI.uf.raid.tankrole (raid frame right-click toggle)
--   2. pfUI_config.nameplates.combatofftanks (nameplate off-tank names setting)

-- Cache for parsed nameplate off-tank names (lowercase)
local pfUIOfftankCache = nil
local pfUIOfftankCacheTime = 0

--- Parse pfUI nameplate off-tank names setting into a lookup table
--- @return table Lowercase name -> true lookup
local function GetPfUIOfftanks()
    -- Cache for 5 seconds to avoid repeated string parsing
    local now = GetTime()
    if pfUIOfftankCache and (now - pfUIOfftankCacheTime) < 5 then
        return pfUIOfftankCache
    end

    pfUIOfftankCache = {}
    pfUIOfftankCacheTime = now

    -- Check pfUI_config.nameplates.combatofftanks (# separated list)
    if type(pfUI_config) == "table" and
       type(pfUI_config.nameplates) == "table" and
       type(pfUI_config.nameplates.combatofftanks) == "string" then
        local list = pfUI_config.nameplates.combatofftanks
        -- pfUI uses # as separator: "#Name1#Name2#Name3"
        for name in string.gfind(list, "[^#]+") do
            name = string.gsub(name, "^%s*(.-)%s*$", "%1") -- trim whitespace
            if name ~= "" then
                pfUIOfftankCache[string.lower(name)] = true
            end
        end
    end

    return pfUIOfftankCache
end

--- Check if pfUI tank data is available (either source)
--- @return boolean True if any pfUI tank system is accessible
function CleveRoids.HasPfUITanks()
    -- Check raid frame tankrole
    local hasRaidTanks = type(pfUI) == "table" and
                         type(pfUI.uf) == "table" and
                         type(pfUI.uf.raid) == "table" and
                         type(pfUI.uf.raid.tankrole) == "table"

    -- Check nameplate off-tank config
    local hasNameplateTanks = type(pfUI_config) == "table" and
                              type(pfUI_config.nameplates) == "table" and
                              type(pfUI_config.nameplates.combatofftanks) == "string" and
                              pfUI_config.nameplates.combatofftanks ~= ""

    return hasRaidTanks or hasNameplateTanks
end

--- Check if a player is marked as a tank in pfUI (either source)
--- @param name string - Player name to check
--- @return boolean True if player is marked as tank
function CleveRoids.IsPlayerTank(name)
    if not name then return false end

    -- Check raid frame tankrole (exact case)
    if type(pfUI) == "table" and
       type(pfUI.uf) == "table" and
       type(pfUI.uf.raid) == "table" and
       type(pfUI.uf.raid.tankrole) == "table" and
       pfUI.uf.raid.tankrole[name] then
        return true
    end

    -- Check nameplate off-tank names (lowercase comparison)
    local offtanks = GetPfUIOfftanks()
    if offtanks[string.lower(name)] then
        return true
    end

    return false
end

--- Check if a unit is targeting any player marked as tank
--- @param unit string - Unit token to check (e.g., "target")
--- @return boolean True if unit's target is a tank
function CleveRoids.IsTargetingAnyTank(unit)
    -- Default to "target" if unit is nil
    unit = unit or "target"

    -- Get the unit's target
    local targetOfUnit = unit .. "target"
    if not UnitExists(targetOfUnit) then
        return false
    end

    local targetName = UnitName(targetOfUnit)
    if not targetName then
        return false
    end

    return CleveRoids.IsPlayerTank(targetName)
end

-- ============================================================================
-- CURSIVE ADDON INTEGRATION
-- ============================================================================
-- Integrates with Cursive addon for accurate debuff time tracking
-- Cursive tracks debuffs by GUID with precise timing (accounts for Dark Harvest, etc.)

--- Check if Cursive addon is available and enabled
--- @return boolean True if Cursive is available
function CleveRoids.HasCursive()
    return type(Cursive) == "table" and
           type(Cursive.curses) == "table" and
           type(Cursive.curses.HasCurse) == "function"
end

--- Require Cursive for a feature, warn once if missing
--- @param feature string Feature name for warning message
--- @return boolean True if Cursive is available
function CleveRoids.RequireCursive(feature)
    if CleveRoids.HasCursive() then
        return true
    end
    if not CleveRoids._cursiveErrorShown then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [cursive] conditional requires the Cursive addon.", 1, 0.5, 0.5)
        CleveRoids._cursiveErrorShown = true
    end
    return false
end

--- Get time remaining on a Cursive-tracked debuff
--- @param unit string Unit to check (will be converted to GUID)
--- @param spellName string Spell name to check (will be lowercased and rank-stripped)
--- @return number|nil Time remaining in seconds, or nil if not found
function CleveRoids.GetCursiveTimeRemaining(unit, spellName)
    if not CleveRoids.HasCursive() then return nil end
    if not unit or not UnitExists(unit) then return nil end

    local guid = CleveRoids.GetGUID(unit)
    if not guid then return nil end

    -- Normalize spell name (lowercase, no rank) to match Cursive's format
    local lowercaseName = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

    local curseData = Cursive.curses:GetCurseData(lowercaseName, guid)
    if not curseData then return nil end

    return Cursive.curses:TimeRemaining(curseData)
end

--- Check if unit has a Cursive-tracked debuff with optional time comparison
--- @param unit string Unit to check
--- @param spellName string Spell name to check
--- @param operator string|nil Comparison operator (>, <, =, >=, <=, ~=)
--- @param amount number|nil Time threshold in seconds
--- @return boolean True if debuff exists and passes time check
function CleveRoids.ValidateCursiveDebuff(unit, spellName, operator, amount)
    if not CleveRoids.HasCursive() then return false end
    if not unit or not UnitExists(unit) then return false end

    local guid = CleveRoids.GetGUID(unit)
    if not guid then return false end

    -- Normalize spell name for Cursive lookup
    local lowercaseName = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

    -- If no operator, just check if debuff exists with any time remaining
    if not operator then
        return Cursive.curses:HasCurse(lowercaseName, guid, 0) == true
    end

    -- With operator, check time remaining
    local timeRemaining = CleveRoids.GetCursiveTimeRemaining(unit, spellName)
    -- If debuff not found, treat as 0 seconds remaining (matches [debuff] behavior)
    -- This makes [cursive:Rake<5] true when Rake is missing (0 < 5 = true)
    if not timeRemaining then timeRemaining = 0 end

    if CleveRoids.operators[operator] and amount then
        return CleveRoids.comparators[operator](timeRemaining, amount)
    end

    return false
end

--- Check if ANY Cursive-tracked debuff exists on unit
--- @param unit string Unit to check
--- @return boolean True if unit has any tracked debuffs
function CleveRoids.HasAnyCursiveDebuff(unit)
    if not CleveRoids.HasCursive() then return false end
    if not unit or not UnitExists(unit) then return false end

    local guid = CleveRoids.GetGUID(unit)
    if not guid then return false end

    return Cursive.curses:HasAnyCurse(guid) == true
end

function CleveRoids.ValidateKnown(args)
    if not args then
        return false
    end
    if table.getn(CleveRoids.Talents) == 0 then
        CleveRoids.IndexTalents()
    end

    local effective_name_to_check
    local original_args_for_rank_check = args

    if type(args) ~= "table" then
        effective_name_to_check = args
        args = { name = args }
    else
        effective_name_to_check = args.name
    end

    local spell = CleveRoids.GetSpell(effective_name_to_check)
    local talent_points = nil

    if not spell then
        talent_points = CleveRoids.GetTalent(effective_name_to_check)
    end

    if not spell and talent_points == nil then
        return false
    end

    local arg_amount = nil
    local arg_operator = nil
    if type(original_args_for_rank_check) == "table" then
        arg_amount = original_args_for_rank_check.amount
        arg_operator = original_args_for_rank_check.operator
    end

    if spell then
        local spell_rank_str = spell.rank or (spell.highest and spell.highest.rank) or ""
        -- FLEXIBLY extract just the number from the rank string
        local _, _, spell_rank_num_str = string.find(spell_rank_str, "(%d+)")

        if not arg_amount and not arg_operator then
            return true
        elseif arg_amount and arg_operator and CleveRoids.operators[arg_operator] and spell_rank_num_str and spell_rank_num_str ~= "" then
            local numeric_rank = tonumber(spell_rank_num_str)
            if numeric_rank then
                return CleveRoids.comparators[arg_operator](numeric_rank, arg_amount)
            else
                return false
            end
        else
            return false
        end
    elseif talent_points ~= nil then
        if not arg_amount and not arg_operator then
            return talent_points > 0
        elseif arg_amount and arg_operator and CleveRoids.operators[arg_operator] then
            return CleveRoids.comparators[arg_operator](talent_points, arg_amount)
        else
            return false
        end
    end

    return false
end

function CleveRoids.ValidateResting()
    return IsResting()
end


-- TODO: refactor numeric comparisons...

-- Checks whether or not the given unit has power in percent vs the given amount
-- unit: The unit we're checking
-- operator: valid comparitive operator symbol
-- amount: The required amount
-- returns: True or false
function CleveRoids.ValidatePower(unit, operator, amount)
    if not unit or not operator or not amount then return false end
    local API = CleveRoids.NampowerAPI
    local power = API and API.GetUnitPower and API.GetUnitPower(unit) or UnitMana(unit)
    local maxPower = API and API.GetUnitMaxPower and API.GetUnitMaxPower(unit) or UnitManaMax(unit)
    local powerPercent = maxPower > 0 and (100 * power / maxPower) or 0

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](powerPercent, amount)
    end

    return false
end

-- Checks whether or not the given unit has current power vs the given amount
-- unit: The unit we're checking
-- operator: valid comparitive operator symbol
-- amount: The required amount
-- returns: True or false
function CleveRoids.ValidateRawPower(unit, operator, amount)
    if not unit or not operator or not amount then return false end
    local API = CleveRoids.NampowerAPI
    local power = API and API.GetUnitPower and API.GetUnitPower(unit) or UnitMana(unit)

    if power and CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](power, amount)
    end

    return false
end

-- Raw caster-form mana for druids（Nampower：GetUnitPower(unit,0) 直读原始法力字段 power1）by 武藤纯子酱 2026.9.1
function CleveRoids.ValidateDruidRawMana(unit, operator, amount)
    unit = unit or "player"
    if not operator or amount == nil then return false end
    if (CleveRoids.playerClass ~= "DRUID") then return false end

    -- Nampower：GetUnitPower(unit, 0) 直读原始法力字段（power1），与当前形态无关——
    -- 等价替代 SuperWoW UnitMana 的第二返回值（施法形态蓝量）
    local casterMana = nil
    if CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetUnitPower then
        casterMana = CleveRoids.NampowerAPI.GetUnitPower(unit, 0)
    end

    -- Fallback: if for some reason we didn't get a value and we're in caster form now
    if type(casterMana) ~= "number" then
        if UnitPowerType and UnitPowerType(unit) == 0 then
            casterMana = UnitMana(unit)
        else
            return false
        end
    end

    local cmp = CleveRoids.comparators and CleveRoids.comparators[operator]
    return cmp and cmp(casterMana, amount) or false
end

-- Checks whether or not the given unit has a power deficit vs the amount specified
-- unit: The unit we're checking
-- operator: valid comparitive operator symbol
-- amount: The required amount
-- returns: True or false
function CleveRoids.ValidatePowerLost(unit, operator, amount)
    if not unit or not operator or not amount then return false end
    local API = CleveRoids.NampowerAPI
    local maxPower = API and API.GetUnitMaxPower and API.GetUnitMaxPower(unit) or UnitManaMax(unit)
    local power = API and API.GetUnitPower and API.GetUnitPower(unit) or UnitMana(unit)
    local powerLost = maxPower - power

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](powerLost, amount)
    end

    return false
end

-- Checks whether or not the given unit has hp in percent vs the given amount
-- unit: The unit we're checking
-- operator: valid comparitive operator symbol
-- amount: The required amount
-- returns: True or false
function CleveRoids.ValidateHp(unit, operator, amount)
    if not unit or not operator or not amount then return false end
    local API = CleveRoids.NampowerAPI
    local hp = API and API.GetUnitHealth and API.GetUnitHealth(unit) or UnitHealth(unit)
    local maxHp = API and API.GetUnitMaxHealth and API.GetUnitMaxHealth(unit) or UnitHealthMax(unit)
    local hpPercent = maxHp > 0 and (100 * hp / maxHp) or 0

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](hpPercent, amount)
    end

    return false
end

-- Checks whether or not the given unit has hp vs the given amount
-- unit: The unit we're checking
-- operator: valid comparitive operator symbol
-- amount: The required amount
-- returns: True or false
function CleveRoids.ValidateRawHp(unit, operator, amount)
    if not unit or not operator or not amount then return false end
    local API = CleveRoids.NampowerAPI
    local rawhp = API and API.GetUnitHealth and API.GetUnitHealth(unit) or UnitHealth(unit)

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](rawhp, amount)
    end

    return false
end

-- Checks whether or not the given unit has an hp deficit vs the amount specified
-- unit: The unit we're checking
-- operator: valid comparitive operator symbol
-- amount: The required amount
-- returns: True or false
function CleveRoids.ValidateHpLost(unit, operator, amount)
    if not unit or not operator or not amount then return false end
    local API = CleveRoids.NampowerAPI
    local maxHp = API and API.GetUnitMaxHealth and API.GetUnitMaxHealth(unit) or UnitHealthMax(unit)
    local hp = API and API.GetUnitHealth and API.GetUnitHealth(unit) or UnitHealth(unit)
    local hpLost = maxHp - hp

    if CleveRoids.operators[operator] then
        return CleveRoids.comparators[operator](hpLost, amount)
    end

    return false
end

-- Checks whether the given creatureType is the same as the target's creature type
-- creatureType: The type to check
-- target: The target's unitID
-- returns: True or false
-- remarks: Allows for both localized and unlocalized type names
function CleveRoids.ValidateCreatureType(creatureType, target)
    if not target then return false end
    -- 修复：非字符串（条件值带比较符被解析成表）直接返回 false，避免 string.lower(表) 崩溃
    -- by 武藤纯子酱 2026.9.11
    if type(creatureType) ~= "string" then return false end
    local targetType = UnitCreatureType(target)
    if not targetType then return false end -- ooze or silithid etc
    local ct = string.lower(creatureType)
    local cl = UnitClassification(target)
    -- Check classification: "boss" matches both "boss" and "worldboss"
    if ct == "boss" then
        if cl == "boss" or cl == "worldboss" then
            return true
        end
    elseif ct == "rare" then -- 新增 稀有、精英和普通怪识别 by 武藤纯子酱 2026.6.8
        if cl == "rareelite" or cl == "rare" then
            return true
        end
    elseif ct == "elite" then
        if cl == "rareelite" or cl == "elite" then
            return true
        end
    elseif ct == "normal" then
        if cl == "normal" then
            return true
        end
    elseif ct == cl then
        return true
    end
    if ct == "boss" then creatureType = "worldboss" end
    local englishType = CleveRoids.Localized.CreatureTypes[targetType]
    return ct == string.lower(targetType) or creatureType == englishType
end

-- TODO: Look into https://github.com/Stanzilla/WoWUIBugs/issues/47 if needed
function CleveRoids.ValidateCooldown(args, ignoreGCD)
    if not args then return false end

    local name
    if type(args) ~= "table" then
        -- PERFORMANCE: Use cached normalization
        name = CleveRoids.NormalizeName(args)

        -- If this is a numeric slot (1-19), resolve to the equipped item's name
        local slotNum = tonumber(name)
        if slotNum and slotNum >= 1 and slotNum <= 19 then
            local link = GetInventoryItemLink("player", slotNum)
            if link then
                local _, _, itemName = string.find(link, "%[(.+)%]")
                if itemName then name = itemName end
            end
        end
        args = {name = name}
    else
        if args.name then
            -- PERFORMANCE: Use cached normalization
            name = CleveRoids.NormalizeName(args.name)

            -- If this is a numeric slot (1-19), resolve to the equipped item's name
            local slotNum = tonumber(name)
            if slotNum and slotNum >= 1 and slotNum <= 19 then
                local link = GetInventoryItemLink("player", slotNum)
                if link then
                    local _, _, itemName = string.find(link, "%[(.+)%]")
                    if itemName then name = itemName end
                end
            end
            args.name = name
        else
            name = args.name
        end
    end

    -- PERFORMANCE: GetCooldown is now cached per-frame
    local expires = CleveRoids.GetCooldown(args.name, ignoreGCD)
    local now = CleveRoids.GetCachedTime()

    if not args.operator and not args.amount then
        return expires > now
    elseif CleveRoids.operators[args.operator] then
        -- 修复：比较量非数字（[cooldown:X>abc]）时直接判失败，避免 number > nil 崩溃
        -- by 武藤纯子酱 2026.9.11
        if args.amount == nil then
            return false
        end
        return CleveRoids.comparators[args.operator](expires - now, args.amount)
    end
end

function CleveRoids.GetPlayerAura(index, isbuff)
    if not index then return false end

    local buffType = isbuff and "HELPFUL" or "HARMFUL"
    local bid = GetPlayerBuff(index, buffType)
    if bid < 0 then return end

    local buffTexture = GetPlayerBuffTexture(bid)

    local spellID
    if _G.GetPlayerAuraDuration then
        -- 修复：按 SCRIPTS.md，GetPlayerAuraDuration 使用原始 aura 槽位（0-31 buff / 32-47 debuff），
        -- 而 GetPlayerBuff 返回的 id 有自己的排序，文档明确两者不是同一编号——
        -- 存在隐藏光环时直接传 bid 会映射到错误技能。
        -- 改为：遍历原始槽位取 spellId，用技能图标纹理与当前 buff 的纹理匹配。 by 武藤纯子酱 2026.8.31
        if buffTexture then
            for slot = 0, 31 do
                local sid = _G.GetPlayerAuraDuration(slot)
                if sid and sid > 0 then
                    local icon = GetSpellIconTexture and GetSpellIconTexture(GetSpellRecField(sid, "spellIconID"))
                    if icon and icon == buffTexture then
                        spellID = sid
                        break
                    end
                end
            end
        end
    end

    return buffTexture, GetPlayerBuffApplications(bid), spellID, GetPlayerBuffTimeLeft(bid)
end

-- PERFORMANCE: Local function refs and reusable pattern for buff checking
local _string_lower = string.lower
local _string_gsub = string.gsub
local _RANK_PATTERN = "%s*"..CleveRoids.Localized.SpellRank -- 修复多语言支持 by 武藤纯子酱 2025.12.18

-- PERFORMANCE: Simple cache for lowercase spell names (cleared periodically)
local _spellNameCache = {}
local _spellNameCacheSize = 0
local _MAX_SPELL_CACHE = 200

-- PERFORMANCE: Cache for base spell names (rank stripped, not lowercased)
local _baseNameCache = {}
local _baseNameCacheSize = 0

local function GetLowercaseSpellName(spellID)
    local cached = _spellNameCache[spellID]
    if cached then return cached end

    local name = GetSpellRecField(spellID, "name")
    if not name then return nil end

    -- Strip rank and lowercase
    local baseName = _string_gsub(name, _RANK_PATTERN, "")
    local lowerName = _string_lower(baseName)

    -- Cache if not too large
    if _spellNameCacheSize < _MAX_SPELL_CACHE then
        _spellNameCache[spellID] = lowerName
        _spellNameCacheSize = _spellNameCacheSize + 1
    end

    return lowerName
end

-- PERFORMANCE: Get base spell name (rank stripped) and full name - cached
local function GetSpellNames(spellID)
    local cached = _baseNameCache[spellID]
    if cached then
        return cached.base, cached.full
    end

    local fullName = GetSpellRecField(spellID, "name")
    if not fullName then return nil, nil end

    local baseName = _string_gsub(fullName, _RANK_PATTERN, "")

    -- Cache if not too large
    if _baseNameCacheSize < _MAX_SPELL_CACHE then
        _baseNameCache[spellID] = { base = baseName, full = fullName }
        _baseNameCacheSize = _baseNameCacheSize + 1
    end

    return baseName, fullName
end

-- Clear spell name caches (called periodically from Core.lua cleanup)
function CleveRoids.ClearSpellNameCaches()
    for k in pairs(_spellNameCache) do
        _spellNameCache[k] = nil
    end
    _spellNameCacheSize = 0

    for k in pairs(_baseNameCache) do
        _baseNameCache[k] = nil
    end
    _baseNameCacheSize = 0
end

function CleveRoids.ValidateAura(unit, args, isbuff)
    if not args or not UnitExists(unit) then return false end

    if type(args) ~= "table" then
        args = {name = args}
    end

    local isPlayer = UnitIsUnit(unit, "player")
    local found = false
    local stacks, remaining
    local i = isPlayer and 0 or 1

    -- Extract rank before stripping (for rank-specific matching)
    local rankNum
    if args.name then
        local _, _, rn = string.find(args.name, CleveRoids.Localized.SpellRank2) -- 修复多语言支持 by 武藤纯子酱 2026.3.14
        rankNum = rn
    end

    -- Strip rank suffix for consistent matching (e.g., "Faerie Fire (Feral)(Rank 4)" -> "Faerie Fire (Feral)")
    if args.name then
        args.name = CleveRoids.StripRank(args.name)
        -- Convert underscores to spaces for matching (e.g., "Thunder_Clap" -> "Thunder Clap")
        args.name = string.gsub(args.name, "_", " ")
    end

    -- PERFORMANCE: Cache lowercased search name to avoid repeated string.lower calls
    -- Support spell ID matching: [mybuff:17941] matches by spell ID instead of name
    local searchID = args.name and tonumber(args.name)

    -- Rank-specific matching: [mybuff:Mark_of_the_Wild(Rank 9)] only matches that exact rank
    if rankNum and not searchID then
        local rankSpecificID = GetSpellIDForRank(args.name, rankNum)
        if rankSpecificID then
            searchID = rankSpecificID
        end
    end

    local searchName = not searchID and args.name and _string_lower(args.name) or nil

    -- Fast path: Use GetUnitField to search all 48 aura slots in 2 C-to-Lua calls
    -- Works for both player and non-player units (GetUnitField supports "player" token)
    local skipSlowSearch = false
    local API = CleveRoids.NampowerAPI
    if API and API.FindUnitAuraInfo then
        local gufResult, gufSpellId, gufStacks, gufSlot = API.FindUnitAuraInfo(unit, searchID, searchName)
        if gufResult ~= nil then  -- GetUnitField was available and searched
            skipSlowSearch = true
            if gufResult then
                if isbuff then
                    -- For buff checks: only accept buff slots (1-32)
                    if gufSlot <= 32 then
                        found = true
                        if isPlayer then
                            local buffIndex = gufSlot - 1 -- 原始 aura 槽（0 基），仅用于 GetPlayerAuraDuration
                            -- 修复：GetPlayerBuffApplications 使用 GetPlayerBuff 的排序 id 空间，
                            -- 与原始槽位编号不同（见 SCRIPTS.md），混用会取错层数；
                            -- FindUnitAuraInfo 已基于 auraApplications 算好 stacks，直接采用 by 武藤纯子酱 2026.8.31
                            stacks = gufStacks or 0
                            -- GetPlayerBuffApplications may not reflect charges for
                            -- some spells (e.g., Lightning Shield on Turtle WoW).
                            -- UnitBuff (spell ID hook via Nampower GetUnitField) can return by 武藤纯子酱 2026.9.1
                            -- the correct charge count. Scan by spell ID to find the right index.
                            if (not stacks or stacks <= 1) and gufSpellId then
                                for si = 1, 32 do
                                    local ubTex, ubStacks, ubSpellId = UnitBuff("player", si)
                                    if not ubTex then break end
                                    if ubSpellId and ubSpellId == gufSpellId then
                                        if ubStacks and ubStacks > (stacks or 0) then
                                            stacks = ubStacks
                                        end
                                        break
                                    end
                                end
                            end
                            -- GetPlayerAuraDuration (Nampower) is primary for remaining
                            -- time. Returns remainingDurationMs directly (2nd return value).
                            -- expirationTimeMs uses GetWowTimeMs() basis, NOT GetTime(),
                            -- so computing from it drifts over time.
                            if _G.GetPlayerAuraDuration then
                                local _, remainingMs = _G.GetPlayerAuraDuration(buffIndex)
                                if remainingMs and remainingMs > 0 then
                                    remaining = remainingMs / 1000
                                elseif remainingMs == 0 then
                                    remaining = 0  -- Expired or permanent aura
                                end
                            end
                            -- 注意：不再回退 GetPlayerBuffTimeLeft(buffIndex)——原始槽位与
                            -- GetPlayerBuff 的 id 空间不同，结果不可靠；取不到就保持 nil（视为无时长数据） by 武藤纯子酱 2026.8.31
                        else
                            stacks = gufStacks or 0
                        end
                    end
                else
                    -- For debuff checks: accept any slot (debuffs overflow to buff slots)
                    found = true
                    if isPlayer then
                        local buffIndex = gufSlot - 1 -- 原始 aura 槽（0 基）
                        -- 修复：同 buff 路径，GetPlayerBuffApplications 与原始槽位编号不同，直接用 gufStacks by 武藤纯子酱 2026.8.31
                        stacks = gufStacks or 0
                        -- UnitBuff/UnitDebuff fallback for correct charge counts (see buff path)
                        if (not stacks or stacks <= 1) and gufSpellId then
                            if gufSlot > 32 then
                                for si = 1, 16 do
                                    local ubTex, ubStacks, _, ubSpellId = UnitDebuff("player", si)
                                    if not ubTex then break end
                                    if ubSpellId and ubSpellId == gufSpellId then
                                        if ubStacks and ubStacks > (stacks or 0) then
                                            stacks = ubStacks
                                        end
                                        break
                                    end
                                end
                            else
                                for si = 1, 32 do
                                    local ubTex, ubStacks, ubSpellId = UnitBuff("player", si)
                                    if not ubTex then break end
                                    if ubSpellId and ubSpellId == gufSpellId then
                                        if ubStacks and ubStacks > (stacks or 0) then
                                            stacks = ubStacks
                                        end
                                        break
                                    end
                                end
                            end
                        end
                        if _G.GetPlayerAuraDuration then
                            local _, remainingMs = _G.GetPlayerAuraDuration(buffIndex)
                            if remainingMs and remainingMs > 0 then
                                remaining = remainingMs / 1000
                            elseif remainingMs == 0 then
                                remaining = 0  -- Expired or permanent aura
                            end
                        end
                        -- 修复：不再回退 GetPlayerBuffTimeLeft(buffIndex)（槽位空间不同，结果不可靠） by 武藤纯子酱 2026.8.31
                    else
                        stacks = gufStacks or 0
                    end
                end
            end
        end
    end

    -- Slow path: Per-slot iteration (player always, non-player when GetUnitField unavailable)
    if not skipSlowSearch then
        -- Primary search: BUFFS if isbuff==true, DEBUFFS if isbuff==false
        while true do
            local texture
            local current_spellID = nil

            if isPlayer then
                -- GetPlayerAura(index, isbuff) => texture, stacks, spellID, timeLeft
                texture, stacks, current_spellID, remaining = CleveRoids.GetPlayerAura(i, isbuff)
            else
                if isbuff then
                    -- UnitBuff => texture, stacks, spellID
                    texture, stacks, current_spellID = UnitBuff(unit, i)
                else
                    -- UnitDebuff => texture, stacks, debuffType, spellID
                    texture, stacks, _, current_spellID = UnitDebuff(unit, i)
                end
                remaining = nil
            end

            if not texture then break end

            if current_spellID then
                if searchID then
                    -- Spell ID matching: [mybuff:17941]
                    if current_spellID == searchID then
                        found = true
                        break
                    end
                elseif searchName then
                    -- PERFORMANCE: Use cached lowercase spell name lookup
                    local lowerName = GetLowercaseSpellName(current_spellID)
                    if lowerName and lowerName == searchName then
                        found = true
                        break
                    end
                end
            end

            i = i + 1
        end

        -- Overflow handling: when searching DEBUFFS on non-players, also scan BUFFS
        if not isbuff and not isPlayer and not found and (searchID or searchName) then
            i = 1
            while true do
                local texture
                local current_spellID = nil

                -- UnitBuff => texture, stacks, spellID
                texture, stacks, current_spellID = UnitBuff(unit, i)
                if not texture then break end

                if current_spellID then
                    if searchID then
                        if current_spellID == searchID then
                            found = true
                            break
                        end
                    elseif searchName then
                        -- PERFORMANCE: Use cached lowercase spell name lookup
                        local lowerName = GetLowercaseSpellName(current_spellID)
                        if lowerName and lowerName == searchName then
                            found = true
                            break
                        end
                    end
                end

                i = i + 1
            end
        end
    end

    -- Overflow buff fallback: player buffs in server slots 33-48 (no client slot)
    -- Check AURA_CAST_ON_SELF tracked overflow data for presence + duration
    if not found and isPlayer and isbuff and next(CleveRoids.OverflowBuffs) then
        local now = GetTime()
        for spellId, entry in pairs(CleveRoids.OverflowBuffs) do
            -- Prune expired entries
            local elapsed = now - (entry.timestamp or 0)
            if entry.durationSec and entry.durationSec > 0 and elapsed > entry.durationSec then
                CleveRoids.OverflowBuffs[spellId] = nil
            else
                local match = false
                if searchID then
                    match = (spellId == searchID)
                elseif searchName then
                    local lowerName = GetLowercaseSpellName(spellId)
                    match = (lowerName and lowerName == searchName)
                end
                if match then
                    found = true
                    stacks = entry.stacks or 1
                    -- Compute remaining time from apply timestamp + duration
                    if entry.durationSec and entry.durationSec > 0 then
                        remaining = entry.durationSec - elapsed
                        if remaining < 0 then remaining = 0 end
                    else
                        remaining = -1  -- Unknown duration (permanent buff)
                    end
                    break
                end
            end
        end
    end

    -- allBuffAuras fallback for player buff timing: when slow path found the buff but
    -- returned no remaining time, check lib.allBuffAuras for cached AURA_CAST timing.
    if found and remaining == nil and isPlayer and isbuff and searchName then
        local lib = type(CleveRoids.libdebuff) == "table" and CleveRoids.libdebuff or nil
        if lib and lib.allBuffAuras then
            local playerGuid = CleveRoids.GetGUID("player")
            if playerGuid and lib.allBuffAuras[playerGuid] then
                -- Try exact name match first
                local casters = lib.allBuffAuras[playerGuid][args.name]
                -- Try lowercase match if exact didn't work
                if not casters then
                    for bName, c in pairs(lib.allBuffAuras[playerGuid]) do
                        if _string_lower(bName) == searchName then
                            casters = c
                            break
                        end
                    end
                end
                if casters then
                    for _, cData in pairs(casters) do
                        local elapsed = GetTime() - (cData.startTime or 0)
                        remaining = cData.duration > 0 and (cData.duration - elapsed) or -1
                        break
                    end
                end
            end
        end
    end

    -- Non-player overflow fallback: buff exists in server slots 33-48 (no client slot)
    -- AllCasterAuraTracking already has data from AURA_CAST_ON_OTHER for all aura applications.
    -- If the normal scan didn't find the buff, check there for presence + duration.
    -- Guard: verify the spell isn't a visible debuff on the target (AllCasterAuraTracking
    -- stores both buffs and debuffs, so without this check [buff:DebuffName] could false-positive).
    if not found and not isPlayer and isbuff and (searchID or searchName) then
        local targetGuid = CleveRoids.GetGUID(unit)
        if targetGuid then
            -- Check if the spell is in a visible debuff slot — if so, it's a debuff, not a buff
            local isDebuff = false
            local di = 1
            while true do
                local dtex, _, _, dspellId = UnitDebuff(unit, di)
                if not dtex then break end
                if dspellId then
                    if searchID then
                        if dspellId == searchID then
                            isDebuff = true
                            break
                        end
                    elseif searchName then
                        local lowerName = GetLowercaseSpellName(dspellId)
                        if lowerName and lowerName == searchName then
                            isDebuff = true
                            break
                        end
                    end
                end
                di = di + 1
            end

            if not isDebuff then
                local trackRemaining = CleveRoids.FindAllCasterAuraByName(targetGuid,
                    searchID and tostring(searchID) or args.name)
                if trackRemaining then
                    found = true
                    stacks = 0
                    remaining = trackRemaining
                end
            end
        end
    end

    local ops = CleveRoids.operators
    local cmp = CleveRoids.comparators

    -- For non-player units with time comparisons, try to get time from tracking systems
    local nonPlayerAuraTimeRemaining = nil
    if not isPlayer and args.name then
        -- NOTE: libdebuff's UnitBuff has a bug where timeleft returns incorrect values
        -- (showing ~1000s instead of actual remaining time). Skip it for buff time checks
        -- and rely on all-caster tracking from AURA_CAST events instead.

        -- Fast path: Check lib.allBuffAuras (spellName-indexed, O(1) lookup)
        -- More efficient than FindAllCasterAuraByName which does ID→name translation
        if nonPlayerAuraTimeRemaining == nil and isbuff then
            local lib = type(CleveRoids.libdebuff) == "table" and CleveRoids.libdebuff or nil
            if lib and lib.allBuffAuras then
                local targetGuid = CleveRoids.GetGUID(unit)
                if targetGuid then
                    local buffEntries = lib.allBuffAuras[targetGuid]
                    if buffEntries then
                        -- Try exact name match first
                        local casters = buffEntries[args.name]
                        -- Try lowercase match if exact didn't work
                        if not casters and searchName then
                            for bName, c in pairs(buffEntries) do
                                if _string_lower(bName) == searchName then
                                    casters = c
                                    break
                                end
                            end
                        end
                        if casters then
                            for _, cData in pairs(casters) do
                                local elapsed = GetTime() - (cData.startTime or 0)
                                local rem = cData.duration > 0 and (cData.duration - elapsed) or -1
                                if rem == nil or rem > 0 or cData.duration <= 0 then
                                    nonPlayerAuraTimeRemaining = rem
                                    if not found then
                                        found = true
                                        stacks = 0
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Second try: All-caster tracking from AURA_CAST events (works for any caster)
        -- Only use if libdebuff didn't find it (libdebuff has more accurate timing for player casts)
        if nonPlayerAuraTimeRemaining == nil then
            local targetGuid = CleveRoids.GetGUID(unit)
            if targetGuid then
                local remaining, casterGuid = CleveRoids.FindAllCasterAuraByName(targetGuid, args.name)

                -- Debug output when enabled
                if CleveRoids.debug then
                    local hasData = CleveRoids.AllCasterAuraTracking[targetGuid] ~= nil
                    DEFAULT_CHAT_FRAME:AddMessage(string.format(
                        "|cffff9900[AuraLookup]|r %s on GUID %s: hasData=%s, remaining=%s",
                        tostring(args.name), string.sub(tostring(targetGuid), 1, 16),
                        tostring(hasData), tostring(remaining)
                    ))
                end

                if remaining then
                    nonPlayerAuraTimeRemaining = remaining
                end
            end
        end
    end

    -- Handle multi-comparison (e.g., >0&<10)
    if args.comparisons and type(args.comparisons) == "table" then
        if CleveRoids.debug then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cffff9900[MultiComp]|r %s: found=%s, remaining=%s, stacks=%s, isPlayer=%s, isbuff=%s",
                tostring(args.name), tostring(found), tostring(remaining),
                tostring(stacks), tostring(isPlayer), tostring(isbuff)
            ))
        end
        -- ALL comparisons must pass (AND logic)
        for _, comp in ipairs(args.comparisons) do
            if not ops[comp.operator] then
                if CleveRoids.debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[MultiComp] Invalid operator: " .. tostring(comp.operator) .. "|r")
                end
                return false  -- Invalid operator
            end

            local value_to_check
            if comp.checkStacks then
                value_to_check = stacks or -1
            elseif isPlayer then
                value_to_check = remaining or -1
            elseif nonPlayerAuraTimeRemaining ~= nil then
                -- Non-player aura with tracked time remaining (from libdebuff or AURA_CAST events)
                value_to_check = nonPlayerAuraTimeRemaining
            else
                -- Non-player units without tracked time: treat missing/unknown as 0
                -- This matches behavior of [mybuff:X<2] returning true when buff is missing
                value_to_check = found and 0 or -1
            end

            local compResult = cmp[comp.operator](value_to_check, comp.amount)
            if CleveRoids.debug then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "|cffff9900[MultiComp]|r   %s %s %s = %s",
                    tostring(value_to_check), comp.operator, tostring(comp.amount),
                    compResult and "|cff00ff00PASS|r" or "|cffff0000FAIL|r"
                ))
            end
            if not compResult then
                return false  -- One comparison failed
            end
        end
        return true  -- All comparisons passed
    end

    -- Single comparison (backward compatibility)
    if not args.amount and not args.operator and not args.checkStacks then
        return found
    elseif isPlayer and not args.checkStacks and args.amount and ops[args.operator] then
        return cmp[args.operator](remaining or -1, args.amount)
    elseif args.amount and args.checkStacks and ops[args.operator] then
        if CleveRoids.debug and isPlayer then
            -- Dump all visible buff slots to find where charges are reported
            local dumpParts = {}
            for di = 0, 31 do
                local dbid = GetPlayerBuff(di, "HELPFUL")
                if dbid < 0 then break end
                local dApps = GetPlayerBuffApplications(dbid)
                local dSid = _G.GetPlayerAuraDuration and _G.GetPlayerAuraDuration(dbid) or nil
                table.insert(dumpParts, string.format("%d:id=%s,apps=%s", dbid, tostring(dSid), tostring(dApps)))
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[BuffDump]|r " .. table.concat(dumpParts, " | "))
            -- Also show raw auraApplications from GetUnitField
            local rawApps = CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetUnitAuraApplications and CleveRoids.NampowerAPI.GetUnitAuraApplications("player")
            if rawApps then
                local appParts = {}
                for ai = 1, 32 do
                    if rawApps[ai] and rawApps[ai] > 0 then
                        table.insert(appParts, string.format("[%d]=%d", ai, rawApps[ai]))
                    end
                end
                if table.getn(appParts) > 0 then
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[AuraApps]|r " .. table.concat(appParts, " "))
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[AuraApps]|r all zero")
                end
            end
        end
        if CleveRoids.debug then
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cffff9900[StackCheck]|r %s: found=%s, stacks=%s, %s %s = %s",
                tostring(args.name), tostring(found), tostring(stacks),
                args.operator, tostring(args.amount),
                cmp[args.operator](stacks or -1, args.amount) and "|cff00ff00PASS|r" or "|cffff0000FAIL|r"
            ))
        end
        return cmp[args.operator](stacks or -1, args.amount)
    elseif not isPlayer and not args.checkStacks and args.amount and ops[args.operator] then
        -- Non-player aura time comparison: use tracked time or treat as 0 if found/-1 if missing
        local timeToCheck = nonPlayerAuraTimeRemaining
        if timeToCheck == nil then
            timeToCheck = found and 0 or -1
        end
        return cmp[args.operator](timeToCheck, args.amount)
    else
        return false
    end
end

function CleveRoids.ValidateUnitBuff(unit, args)
    return CleveRoids.ValidateAura(unit, args, true)
end

function CleveRoids.ValidateUnitDebuff(unit, args)
    if not args or not UnitExists(unit) then return false end
    if type(args) ~= "table" then
        args = { name = args }
    end
    if not args.name then return false end

    -- Extract rank before stripping (for rank-specific matching)
    -- e.g., "Moonfire(Rank 10)" → rankNum = "10", then StripRank → "Moonfire"
    local rankNum
    do
        local _, _, rn = string.find(args.name, CleveRoids.Localized.SpellRank2) -- 修复多语言支持 by 武藤纯子酱 2026.3.14
        rankNum = rn
    end

    -- Strip rank suffix for consistent matching (e.g., "Faerie Fire (Feral)(Rank 4)" -> "Faerie Fire (Feral)")
    args.name = CleveRoids.StripRank(args.name)
    -- Convert underscores to spaces for matching (e.g., "Thunder_Clap" -> "Thunder Clap")
    args.name = string.gsub(args.name, "_", " ")

    -- Support spell ID matching: [debuff:9904] matches by spell ID instead of name
    local searchID = tonumber(args.name)

    -- Rank-specific matching: [debuff:Moonfire(Rank 10)] only matches that exact rank
    if rankNum and not searchID then
        local rankSpecificID = GetSpellIDForRank(args.name, rankNum)
        if rankSpecificID then
            searchID = rankSpecificID
        end
    end

    local found = false
    local texture, stacks, spellID, remaining
    local i

    -- For non-player units: timer-first for personal debuffs, GetUnitField for shared
    -- 1. Check tracking table for player's own debuffs (authoritative for personal debuffs)
    -- 2. Name-based fallback for custom/Turtle WoW spells not in ID cache
    -- 3. Shared debuff check via GetUnitField (fast) or UnitDebuff scan (slow)
    -- 4. Stale cleanup: if GetUnitField available and aura not present, clean tracking entries
    local lib = type(CleveRoids.libdebuff) == "table" and CleveRoids.libdebuff or nil
    if unit ~= "player" and lib and lib.objects then
        local guid = CleveRoids.GetGUID(unit)
        if not guid then return false end

        -- Resolve spell name to known spell IDs
        local matchingSpellIDs
        if searchID then
            matchingSpellIDs = {searchID}
        else
            matchingSpellIDs = GetSpellIDsForName(args.name) or {}
        end

        local foundSpellId  -- Track which spell ID was found (for texture lookup)

        -- STEP 1: TIMER-FIRST — check tracking table for player's own debuffs
        -- Personal debuffs require caster verification; tracking table is authoritative
        if matchingSpellIDs and table.getn(matchingSpellIDs) > 0 then
            for _, sid in ipairs(matchingSpellIDs) do
                local rec = lib.objects[guid] and lib.objects[guid][sid]
                local isShared = lib.IsPersonalDebuff and lib:IsPersonalDebuff(sid) == false
                if rec and rec.duration and rec.start and (isShared or rec.caster == "player") then
                    local timeRemaining = rec.duration + rec.start - GetTime()
                    if timeRemaining > 0 then
                        found = true
                        remaining = timeRemaining
                        stacks = rec.stacks or 0
                        foundSpellId = sid

                        CleveRoids.DebugChanged("tracking_" .. sid .. "_" .. tostring(guid),
                            string.format("|cff00ff00[Tracking]|r %s (ID:%d) active on %s",
                                args.name, sid, tostring(guid)))
                        break
                    else
                        -- Timer expired — clean up
                        CleveRoids.DebugChanged("tracking_" .. sid .. "_" .. tostring(guid),
                            string.format("|cffff6600[Tracking]|r %s (ID:%d) expired",
                                args.name, sid))
                        lib.objects[guid][sid] = nil
                    end
                end
            end

            -- STEP 1b: EXISTENCE VERIFICATION — if timer says debuff exists,
            -- verify with GetUnitField that the aura is actually on the target.
            -- Catches early-break CCs (e.g., Sap broken by damage) where the
            -- tracking timer still shows positive but the debuff is already gone.
            if found then
                local API = CleveRoids.NampowerAPI
                if API and API.FindUnitAuraInfo then
                    local searchNameLower = not searchID and args.name and _string_lower(args.name) or nil
                    local gufResult = API.FindUnitAuraInfo(unit, searchID, searchNameLower)
                    if gufResult == false then
                        CleveRoids.DebugChanged("tracking_" .. foundSpellId .. "_" .. tostring(guid),
                            string.format("|cffff6600[Tracking]|r %s (ID:%d) stale (not on target)",
                                args.name, foundSpellId))
                        lib.objects[guid][foundSpellId] = nil
                        found = false
                        remaining = nil
                        stacks = nil
                        foundSpellId = nil
                    end
                end
            end

            if not found and CleveRoids.debugVerbose then
                CleveRoids.DebugChanged("tracking_miss_" .. args.name .. "_" .. tostring(guid),
                    string.format("|cffff0000[Tracking]|r %s not in tracking table (checked %d ranks)",
                        args.name, table.getn(matchingSpellIDs)))
            end
        elseif CleveRoids.debug then
            CleveRoids.DebugChanged("tracking_unknown_" .. args.name,
                string.format("|cffff0000[Tracking]|r Unknown spell: %s", args.name))
        end

        -- STEP 2: NAME-BASED FALLBACK for custom/Turtle WoW spells not in ID cache
        if not found and (not matchingSpellIDs or table.getn(matchingSpellIDs) == 0) and lib.objects[guid] and not searchID then
            local fallbackNameLower = _string_lower(args.name)
            for sid, rec in pairs(lib.objects[guid]) do
                if rec and rec.caster == "player" then
                    local n = GetSpellRecField and GetSpellRecField(sid, "name")
                    if n then
                        n = CleveRoids.StripRank(n)
                        if _string_lower(n) == fallbackNameLower then
                            local timeRemaining = rec.duration + rec.start - GetTime()
                            if timeRemaining > 0 then
                                found = true
                                remaining = timeRemaining
                                stacks = rec.stacks or 0
                                foundSpellId = sid
                            else
                                lib.objects[guid][sid] = nil
                            end
                            break
                        end
                    end
                end
            end

            -- Verify existence for name-based matches (same early-break CC protection)
            if found then
                local API = CleveRoids.NampowerAPI
                if API and API.FindUnitAuraInfo then
                    local searchNameLower = args.name and _string_lower(args.name) or nil
                    local gufResult = API.FindUnitAuraInfo(unit, nil, searchNameLower)
                    if gufResult == false then
                        if CleveRoids.debug then
                            DEFAULT_CHAT_FRAME:AddMessage(
                                string.format("|cffff6600[Tracking]|r %s (ID:%d) stale (not on target per GetUnitField)",
                                    args.name, foundSpellId)
                            )
                        end
                        lib.objects[guid][foundSpellId] = nil
                        found = false
                        remaining = nil
                        stacks = nil
                        foundSpellId = nil
                    end
                end
            end
        end

        -- STEP 3: SHARED DEBUFF CHECK + STALE CLEANUP
        -- For shared debuffs (Sunder, Faerie Fire, etc.) from any caster — check actual aura state.
        -- Also cleans stale tracking entries when GetUnitField confirms aura is gone.
        if not found then
            -- Fast path: GetUnitField via FindUnitAuraInfo
            local API = CleveRoids.NampowerAPI
            local searchNameLower = not searchID and args.name and _string_lower(args.name) or nil
            local usedFastPath = false
            if API and API.FindUnitAuraInfo then
                local gufResult, gufSpellId, gufStacks, gufSlot = API.FindUnitAuraInfo(unit, searchID, searchNameLower)
                if gufResult ~= nil then
                    usedFastPath = true
                    if gufResult then
                        local isSimpleExistenceCheck = not args.operator and not args.amount -- 新增判定 by 武藤纯子酱 2026.2.20

                        local isStackCheck = false -- 新增简单层数判定 by 武藤纯子酱 2026.2.20
                        if args.checkStacks then
                            isStackCheck = true
                        elseif args.comparisons then
                            for _, comp in ipairs(args.comparisons) do 
                                if comp.checkStacks then
                                    isStackCheck = true
                                    break
                                end
                            end
                        end

                        -- Step 1 (tracking) already ran and didn't find this debuff as ours.
                        -- Only accept shared debuffs (Sunder, Faerie Fire, etc.) from any caster.
                        -- Personal debuffs not in our tracking table = another player's cast → skip.
                        local isShared = IsSharedDebuffByIdOrName(lib, gufSpellId, args.name)
                        if isShared or isStackCheck or isSimpleExistenceCheck then -- 新增isSimpleExistenceCheck和isStackCheck by 武藤纯子酱 2026.2.20
                            found = true
                            stacks = gufStacks or 0
                            spellID = gufSpellId
                            foundSpellId = gufSpellId
                            remaining = nil
                        end
                    elseif lib.objects[guid] then
                        -- gufResult == false: aura definitively not on target
                        -- Clean any stale tracking entries
                        if matchingSpellIDs then
                            for _, sid in ipairs(matchingSpellIDs) do
                                if lib.objects[guid][sid] then
                                    if CleveRoids.debug then
                                        DEFAULT_CHAT_FRAME:AddMessage(
                                            string.format("|cffff6600[Tracking]|r %s (ID:%d) removed (not on target)",
                                                args.name, sid)
                                        )
                                    end
                                    lib.objects[guid][sid] = nil
                                end
                            end
                        end
                        -- Also clean name-based entries (Turtle WoW custom spells)
                        if not searchID then
                            local cleanupNameLower = _string_lower(args.name)
                            for sid, rec in pairs(lib.objects[guid]) do
                                if rec and rec.caster == "player" then
                                    local n = GetSpellRecField and GetSpellRecField(sid, "name")
                                    if n then
                                        n = CleveRoids.StripRank(n)
                                        if _string_lower(n) == cleanupNameLower then
                                            if CleveRoids.debug then
                                                DEFAULT_CHAT_FRAME:AddMessage(
                                                    string.format("|cffff6600[Tracking]|r %s (ID:%d) removed (not on target)",
                                                        args.name, sid)
                                                )
                                            end
                                            lib.objects[guid][sid] = nil
                                            break
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Slow path: per-slot UnitDebuff + UnitBuff scan (GetUnitField unavailable)
            if not found and not usedFastPath then
                for i = 1, 16 do
                    local tex, debuffStacks, _, debuffSpellID = UnitDebuff(unit, i)
                    if not tex then break end

                    if debuffSpellID then
                        local matched = false
                        if searchID then
                            matched = (debuffSpellID == searchID)
                        else
                            local baseName, fullName = GetSpellNames(debuffSpellID)
                            matched = baseName and (baseName == args.name or fullName == args.name)
                        end
                        if matched then
                            -- Only accept shared debuffs here — personal debuffs not in
                            -- our tracking table (Step 1) are another player's cast
                            local isShared = IsSharedDebuffByIdOrName(lib, debuffSpellID, args.name)
                            if isShared then
                                found = true
                                texture = tex
                                stacks = debuffStacks or 0
                                spellID = debuffSpellID
                                foundSpellId = debuffSpellID
                                remaining = nil
                                break
                            end
                        end
                    end
                end

                -- Check buff slots (overflow debuffs)
                if not found then
                    for i = 1, 32 do
                        local tex, buffStacks, buffSpellID = UnitBuff(unit, i)
                        if not tex then break end

                        if buffSpellID then
                            local matched = false
                            if searchID then
                                matched = (buffSpellID == searchID)
                            else
                                local baseName, fullName = GetSpellNames(buffSpellID)
                                matched = baseName and (baseName == args.name or fullName == args.name)
                            end
                            if matched then
                                local isShared = IsSharedDebuffByIdOrName(lib, buffSpellID, args.name)
                                if isShared then
                                    found = true
                                    texture = tex
                                    stacks = buffStacks or 0
                                    spellID = buffSpellID
                                    foundSpellId = buffSpellID
                                    remaining = nil
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        -- STEP 4: TEXTURE LOOKUP for found debuff (if not already set by slow path)
        if found and not texture and foundSpellId then
            for i = 1, 16 do
                local _, _, _, sid = UnitDebuff(unit, i)
                if sid == foundSpellId then
                    texture = UnitDebuff(unit, i)
                    break
                end
            end
            if not texture then
                for i = 1, 32 do
                    local _, _, sid = UnitBuff(unit, i)
                    if sid == foundSpellId then
                        texture = UnitBuff(unit, i)
                        break
                    end
                end
            end
        end
    -- For player unit, use standard search (player only sees own debuffs on self)
    elseif unit == "player" then
        -- Search DEBUFFS first
        i = 0
        while true do
            texture, stacks, spellID, remaining = CleveRoids.GetPlayerAura(i, false)
            if not texture then break end

            if searchID then
                if spellID == searchID then
                    found = true
                    break
                end
            elseif spellID then
                local baseName, fullName = GetSpellNames(spellID)
                if baseName and (baseName == args.name or fullName == args.name) then
                    found = true
                    break
                end
            elseif texture == CleveRoids.auraTextures[args.name] then
                found = true
                break
            end
            i = i + 1
        end

        -- If not found, search BUFFS (overflow debuffs shown as buffs on some servers)
        if not found then
            i = 0
            while true do
                texture, stacks, spellID, remaining = CleveRoids.GetPlayerAura(i, true)
                if not texture then break end

                if searchID then
                    if spellID == searchID then
                        found = true
                        break
                    end
                elseif spellID then
                    local baseName, fullName = GetSpellNames(spellID)
                    if baseName and (baseName == args.name or fullName == args.name) then
                        found = true
                        break
                    end
                elseif texture == CleveRoids.auraTextures[args.name] then
                    found = true
                    break
                end
                i = i + 1
            end
        end
    end

    -- Step 3: Perform conditional validation
    local ops = CleveRoids.operators
    local cmp = CleveRoids.comparators

    -- Handle multi-comparison (e.g., >0&<10)
    if args.comparisons and type(args.comparisons) == "table" then
        -- Check if ALL comparisons are stack-based
        local allStackChecks = true
        for _, comp in ipairs(args.comparisons) do
            if not comp.checkStacks then
                allStackChecks = false
                break
            end
        end

        -- If debuff not found: stack checks treat as 0 stacks, time checks fail
        if not found then
            if not allStackChecks then
                return false  -- Time-based comparisons require debuff to exist
            end
            -- For pure stack checks, treat missing debuff as 0 stacks
            stacks = 0
        end

        -- For non-player units, get time remaining once (used for all time comparisons)
        local nonPlayerTimeRemaining = nil
        if unit ~= "player" and found then
            nonPlayerTimeRemaining = _get_debuff_timeleft(unit, args.name) or 0
        end

        -- ALL comparisons must pass (AND logic)
        for _, comp in ipairs(args.comparisons) do
            if not ops[comp.operator] then
                return false  -- Invalid operator
            end

            local value_to_check
            if comp.checkStacks then
                value_to_check = stacks or 0
            elseif unit == "player" then
                value_to_check = remaining or 0
            else
                -- Non-player units: use time remaining from libdebuff
                value_to_check = nonPlayerTimeRemaining or 0
            end

            if not cmp[comp.operator](value_to_check, comp.amount) then
                return false  -- One comparison failed
            end
        end
        return true  -- All comparisons passed
    end

    local hasNumCheck = (args.amount ~= nil) and (args.operator ~= nil) and ops[args.operator]

    -- Case A: No numeric/stack condition, just check for existence.
    if not hasNumCheck and not args.checkStacks then
        return found
    end

    -- Case B: Numeric/stack condition exists.
    if hasNumCheck then
        -- Stacks compare path
        if args.checkStacks then
            if found then
                return cmp[args.operator](stacks or 0, args.amount)
            else
                return cmp[args.operator](0, args.amount)
            end
        end

        -- Time-left compare path
        if unit == "player" then
            if not found then
                return false  -- debuff doesn't exist, fail the check
            end
            local tl = remaining or 0
            return cmp[args.operator](tl, args.amount)
        else
            -- Non-player: try pfUI → internal libdebuff → 0s
            local tl = _get_debuff_timeleft(unit, args.name)
            if tl ~= nil then
                return cmp[args.operator](tl or 0, args.amount)
            end

            -- Defensive: verify libdebuff is a table before accessing properties
            if type(CleveRoids.libdebuff) == "table" and CleveRoids.libdebuff.UnitDebuff then
                local atl = nil
                local caster = nil

                -- Auto-detect if this is a personal debuff (unless explicitly overridden)
                local filterCaster = nil
                if args.mine == true then
                    -- User explicitly requested player-only filtering
                    filterCaster = "player"
                elseif args.mine == false then
                    -- User explicitly requested no filtering
                    filterCaster = nil
                else
                    -- Auto-detect based on spell type (if available and personal, filter to player)
                    -- We'll determine this during the search
                    filterCaster = nil
                end

                -- Check 1-48: debuff slots 1-16 + overflow debuffs in buff slots 1-32
                for idx = 1, 48 do
                    local effect, _, _, _, _, duration, timeleft, effectCaster = CleveRoids.libdebuff:UnitDebuff(unit, idx, filterCaster)
                    -- Only break for slots 1-16 (regular debuffs are dense)
                    -- For overflow slots 17-48, nil means "regular buff filtered out", not "end of list"
                    if not effect and idx <= 16 then break end
                    -- Strip rank from effect name for comparison
                    local effectBase = CleveRoids.StripRank(effect)
                    if effectBase and effectBase == args.name then
                        local shouldSkip = false

                        -- Auto-detect: If args.mine not specified and this is a personal debuff, only match player casts
                        if args.mine == nil and spellID and CleveRoids.libdebuff.IsPersonalDebuff then
                            if CleveRoids.libdebuff:IsPersonalDebuff(spellID) and effectCaster ~= "player" then
                                -- This is a personal debuff from another player, skip it
                                shouldSkip = true
                            end
                        end

                        if not shouldSkip then
                            atl = (timeleft and timeleft >= 0) and timeleft or 0
                            caster = effectCaster
                            break
                        end
                    end
                end
                if atl ~= nil then
                    return cmp[args.operator](atl, args.amount)
                end
            end

           -- No timers at all: treat missing/unknown as 0s and compare
            if not found then
                -- If debuff doesn't exist, treat as 0 seconds and compare
                return cmp[args.operator](0, args.amount)
            end
            -- If we reach here with no timer data, treat as 0
            return cmp[args.operator](0, args.amount)
        end
    end

    -- If we get here, nothing matched
    return false
end

function CleveRoids.ValidatePlayerBuff(args)
    -- First check regular buffs
    local found = CleveRoids.ValidateAura("player", args, true)
    if found then return true end

    -- Also check shapeshift forms (Cat Form, Bear Form, etc. are not regular buffs)
    -- This is needed for !Cat Form syntax to work correctly
    local searchName = type(args) == "table" and args.name or args
    if searchName then
        -- PERFORMANCE: Use cached lowercase normalization to avoid per-call string allocation
        searchName = GetLowerNormalizedName(searchName)
        local numForms = GetNumShapeshiftForms()
        for i = 1, numForms do
            local icon, name, isActive, isCastable = GetShapeshiftFormInfo(i)
            -- PERFORMANCE: Use cached lowercase to avoid per-iteration string allocation
            if name and isActive and GetLowercaseString(name) == searchName then
                return true
            end
        end
    end

    return false
end

function CleveRoids.ValidatePlayerDebuff(args)
    return CleveRoids.ValidateAura("player", args, false)
end

function CleveRoids.ValidateWeaponImbue(slot, args)
    -- Check if weapon has enchant via API
    local hasMainEnchant, mainExpiration, mainCharges, hasOffEnchant, offExpiration, offCharges = GetWeaponEnchantInfo()

    local hasEnchant, expiration, charges
    if slot == "mh" then
        hasEnchant = hasMainEnchant
        expiration = mainExpiration
        charges = mainCharges
    else
        hasEnchant = hasOffEnchant
        expiration = offExpiration
        charges = offCharges
    end

    -- Only consider temporary enchants (with time or charges)
    -- This filters out permanent enchants like Crusader, Lifestealing, etc.
    local hasTemporaryEnchant = hasEnchant and (expiration and expiration > 0 or charges and charges > 0)

    -- Convert expiration from milliseconds to seconds
    local remaining = expiration and (expiration / 1000) or -1
    local stacks = charges or 0

    -- Normalize args to table format
    if type(args) ~= "table" then
        args = { name = args }
    end

    local imbueName = args.name

    -- If no specific imbue requested and no comparison operators, return temporary enchant status
    if (not imbueName or imbueName == "") and not args.operator and not args.comparisons then
        return hasTemporaryEnchant
    end

    -- If no temporary enchant, don't bother with further checks
    if not hasTemporaryEnchant then
        return false
    end

    -- If we have a specific imbue name, verify it via tooltip scan
    if imbueName and imbueName ~= "" then
        local nameFound = CleveRoids.CheckWeaponImbueByName(slot, imbueName)
        if not nameFound then
            return false  -- Specific imbue not found
        end
    end

    -- Handle numeric comparisons (time remaining or charges)
    local ops = CleveRoids.operators

    -- Handle multi-comparison (e.g., >60&<300)
    if args.comparisons and type(args.comparisons) == "table" then
        -- ALL comparisons must pass (AND logic)
        for _, comp in ipairs(args.comparisons) do
            if not ops[comp.operator] then
                return false  -- Invalid operator
            end

            local value_to_check
            if comp.checkStacks then
                value_to_check = stacks
            else
                value_to_check = remaining
            end

            if not CleveRoids.comparators[comp.operator](value_to_check, comp.amount) then
                return false  -- One comparison failed
            end
        end
        return true  -- All comparisons passed
    end

    -- Single comparison (backward compatibility)
    if not args.amount and not args.operator and not args.checkStacks then
        return true  -- Name matched (or no name required), no numeric check needed
    elseif not args.checkStacks and args.amount and ops[args.operator] then
        -- Time remaining check
        return CleveRoids.comparators[args.operator](remaining, args.amount)
    elseif args.amount and args.checkStacks and ops[args.operator] then
        -- Charge count check
        return CleveRoids.comparators[args.operator](stacks, args.amount)
    else
        return false
    end
end

-- Helper function: Parse imbue conditional arguments into a normalized args table
-- Handles: boolean, string, or table with name/operator/amount/checkStacks/comparisons
function CleveRoids.ParseImbueArgs(value, conditionals)
    -- Boolean true means check for any imbue
    if value == true then
        return nil
    end

    -- Simple string means just check for name
    if type(value) == "string" then
        return { name = value }
    end

    -- Table format - could be array of values or parsed args with operator
    if type(value) == "table" then
        -- Check if it's already a parsed args table (has operator or comparisons)
        if value.operator or value.comparisons or value.checkStacks then
            return value
        end

        -- It's an array of values - use the first one
        if table.getn(value) > 0 then
            local first = value[1]
            -- First element could be a string or a parsed args table
            if type(first) == "string" then
                return { name = first }
            elseif type(first) == "table" then
                return first  -- Already parsed (has name, operator, amount, etc.)
            end
        end
    end

    return nil  -- Default: check for any imbue
end

-- Helper function: Check if specific imbue name is on weapon via tooltip scan
function CleveRoids.CheckWeaponImbueByName(slot, imbueName)
    if not imbueName or imbueName == "" then
        return true  -- No name to check
    end

    -- Create tooltip scanner if needed
    if not CleveRoidsTooltip then
        CreateFrame("GameTooltip", "CleveRoidsTooltip", nil, "GameTooltipTemplate")
    end

    -- Scan weapon tooltip
    CleveRoidsTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    CleveRoidsTooltip:ClearLines()
    CleveRoidsTooltip:SetInventoryItem("player", slot == "mh" and 16 or 17)

    -- PERFORMANCE: Use cached normalization to avoid per-call string allocation
    local searchTerm = GetLowerNormalizedName(imbueName)

    -- Look for green text with time markers - check ALL green lines with time
    for i = 1, CleveRoidsTooltip:NumLines() do
        local text = _G["CleveRoidsTooltipTextLeft"..i]
        if text then
            local line = text:GetText()
            if line then
                local r, g, b = text:GetTextColor()
                -- Green text indicates enchant
                if g > 0.8 and r < 0.2 and b < 0.2 then
                    local lowerLine = string.lower(line)
                    -- Only check lines with time markers (temporary enchants)
                    -- This skips permanent weapon stats like "Equip: ... critical strike ..."
                    -- 新增多语言支持 by 武藤纯子酱 2026.1.9
                    if string.find(lowerLine, CleveRoids.Localized.Enchantment["%("]) and (string.find(lowerLine, CleveRoids.Localized.Enchantment[" min%)"]) or string.find(lowerLine, CleveRoids.Localized.Enchantment[" sec%)"]) or string.find(lowerLine, CleveRoids.Localized.Enchantment[" charge"])) then
                        -- This is a temporary enchant line, check if it matches
                        if string.find(lowerLine, searchTerm, 1, true) then
                            return true  -- Found it!
                        end
                    end
                end
            end
        end
    end

    -- Checked all lines, didn't find it
    return false
end

-- TODO: Look into https://github.com/Stanzilla/WoWUIBugs/issues/47 if needed
-- PERFORMANCE: Uncached version - called by GetCachedCooldown
function CleveRoids._GetCooldownUncached(name, ignoreGCD)
    if not name then return 0 end

    -- Check if it's a spell first
    local spell = CleveRoids.GetSpell(name)
    if spell then
        local expires = CleveRoids.GetSpellCooldown(name, ignoreGCD)
        return expires  -- GetSpellCooldown already returns absolute time
    end

    -- Not a spell, check if it's an item
    -- GetItemCooldown returns (remainingSeconds, totalDuration, enabled)
    local remaining, duration, enabled = CleveRoids.GetItemCooldown(name, ignoreGCD)

    -- Convert remaining seconds to absolute expiry time
    if remaining and remaining > 0 then
        return CleveRoids.GetCachedTime() + remaining
    end

    return 0
end

-- PERFORMANCE: Cached wrapper - use this for conditional checks
function CleveRoids.GetCooldown(name, ignoreGCD)
    return CleveRoids.GetCachedCooldown(name, ignoreGCD)
end

-- TODO: Look into https://github.com/Stanzilla/WoWUIBugs/issues/47 if needed
-- Returns the cooldown of the given spellName or nil if no such spell was found
function CleveRoids.GetSpellCooldown(spellName, ignoreGCD)
    if not spellName then return 0 end

    local spell = CleveRoids.GetSpell(spellName)
    if not spell then return 0 end

    local start, cd = GetSpellCooldown(spell.spellSlot, spell.bookType)
    if ignoreGCD and cd and cd > 0 and cd <= 1.5 then
        return 0
    else
        return (start + cd)
    end
end

-- Check if an item exists in bags or equipped
-- Returns: true if found, false otherwise
-- PERFORMANCE: Uses CleveRoids.Items cache for O(1) lookup, with fallback for substring matches
function CleveRoids.HasItem(item)
  -- Fast path: check cache first (O(1) lookup)
  if CleveRoids.HasItemCached(item) then
    return true
  end

  -- Slow path fallback: only needed for substring matching on strings
  -- The cache handles exact matches by ID and name, but not partial/substring matches
  if type(item) == "string" and item ~= "" then
    local itemLower = string.lower(item)

    -- Check equipped slots for substring match
    for slot = 0, 19 do
      local link = GetInventoryItemLink("player", slot)
      if link then
        if string.find(string.lower(link), itemLower, 1, true) then
          return true
        end
      end
    end

    -- Check bags for substring match
    for bag = 0, 4 do
      local size = GetContainerNumSlots(bag)
      if size and size > 0 then
        for slotIndex = 1, size do
          local link = GetContainerItemLink(bag, slotIndex)
          if link then
            if string.find(string.lower(link), itemLower, 1, true) then
              return true
            end
          end
        end
      end
    end
  end

  return false
end

-- TODO: Look into https://github.com/Stanzilla/WoWUIBugs/issues/47 if needed
-- Hardened item cooldown resolver (Vanilla 1.12.1 / Lua 5.0)
-- Returns: remainingSeconds, totalDuration, enabled
-- PERFORMANCE: Uses CleveRoids.Items cache for O(1) lookup, with fallback for substring matches
-- 性能优化：_norm 提升为模块级，避免每次调用 GetItemCooldown 都新建闭包 by 武藤纯子酱 2026.9.11
local function GetItemCooldownNorm(s, d, e)
  s = tonumber(s) or 0
  d = tonumber(d) or 0
  e = tonumber(e) or 0
  if d <= 0 or s <= 0 then
    return 0, 0, e
  end
  local rem = (s + d) - GetTime()
  if rem < 0 then rem = 0 end
  return rem, d, e
end

function CleveRoids.GetItemCooldown(item)
  -- Fast path: check cache first (O(1) lookup)
  local remaining, duration, enable = CleveRoids.GetItemCooldownCached(item)
  if duration > 0 or remaining > 0 then
    return remaining, duration, enable
  end

  -- If cache found the item but cooldown is 0, that's a valid result
  local location = CleveRoids.FindItemLocation(item)
  if location then
    return 0, 0, enable or 0
  end

  -- Slow path fallback: only needed for substring matching on strings
  if type(item) == "string" and item ~= "" then
    local itemLower = string.lower(item)
    local start, dur, en

    -- Check equipped slots for substring match
    for slot = 0, 19 do
      local link = GetInventoryItemLink("player", slot)
      if link then
        if string.find(string.lower(link), itemLower, 1, true) then
          start, dur, en = GetInventoryItemCooldown("player", slot)
          return GetItemCooldownNorm(start, dur, en)
        end
      end
    end

    -- Check bags for substring match
    for bag = 0, 4 do
      local size = GetContainerNumSlots(bag)
      if size and size > 0 then
        for slotIndex = 1, size do
          local link = GetContainerItemLink(bag, slotIndex)
          if link then
            if string.find(string.lower(link), itemLower, 1, true) then
              start, dur, en = GetContainerItemCooldown(bag, slotIndex)
              return GetItemCooldownNorm(start, dur, en)
            end
          end
        end
      end
    end
  end

  -- Fallback: unknown item → no cooldown
  return 0, 0, 0
end

function CleveRoids.ValidatePlayerAuraCount(operatorOrBigger, amount)
    -- Count player buffs
    local count

    -- v2.30+ fast path: use raw slot counting via GetPlayerAuraDuration
    local API = CleveRoids.NampowerAPI
    if API then
        count = API.CountPlayerBuffSlots()
    end

    -- Fallback: iterate all 32 slots manually
    if not count then
        count = 0
        for i = 0, 31 do
            if GetPlayerBuffTexture(GetPlayerBuff(i, "HELPFUL")) then
                count = count + 1
            end
        end
    end

    -- 计入无可见槽的溢出 buff（buff 栏满时应用、服务器侧无 aura 槽，位于可见槽 0-31 之外）：
    -- 数据来自 AURA_CAST_ON_SELF 的 OverflowBuffs；仅在 GetPlayerAuraDuration（v2.30+）
    -- 可用时统计——低版本无法判定“是否已有可见槽”，OverflowBuffs 不可靠 by 武藤纯子酱 2026.9.23
    if _G.GetPlayerAuraDuration and CleveRoids.OverflowBuffs then
        local now = GetTime()
        for spellId, entry in pairs(CleveRoids.OverflowBuffs) do
            if entry.durationSec and entry.durationSec > 0
               and (now - (entry.timestamp or 0)) > entry.durationSec then
                CleveRoids.OverflowBuffs[spellId] = nil  -- 过期清理
            else
                count = count + 1
            end
        end
    end

    amount = tonumber(amount)
    -- 修复：amount 无法转数字（如 [mybuffcount:>abc] 或裸值缺失）时，
    -- 原 else 分支 count > nil 抛 "attempt to compare number with nil" by 武藤纯子酱 2026.9.9
    if not amount then
        return false
    end
    if type(operatorOrBigger) == "string" and CleveRoids.comparators and CleveRoids.comparators[operatorOrBigger] then
        -- 修复：解析条目只有 operator/amount 字段（没有 bigger），支持直接传比较符 by 武藤纯子酱 2026.8.31
        return CleveRoids.comparators[operatorOrBigger](count, amount)
    elseif operatorOrBigger == 0 then
        return count < amount
    else
        return count > amount
    end
end

function CleveRoids.IsReactive(spellName) -- 修复 by 武藤纯子酱 2025.11.27
    return CleveRoids.reactiveSpells[spellName] ~= nil
end

function CleveRoids.GetActionButtonInfo(slot)
    -- 修复：1.12 的 GetActionText 只返回宏文本一个值（无 actionType/actionID，那是 2.x GetActionInfo 的行为），
    -- 原代码按 3 返回值解构导致 SPELL/ITEM 分支永远不可达；
    -- 本实现随后会被 Extensions/Tooltip/Generic.lua 的基于 tooltip 的版本覆盖（.toc 加载顺序在后） by 武藤纯子酱 2026.8.31
    local macroText = GetActionText(slot)
    if macroText and macroText ~= "" then
        return "MACRO", nil, macroText
    end
    return nil
end


-- 修改reactive条件 by 武藤纯子酱 2026.5.29
function CleveRoids.IsReactiveUsable(spellName)
    -- 1. Combat log 跟踪（招架/闪避/格挡等触发）
    local hasProc = false
    if CleveRoids.HasReactiveProc and CleveRoids.HasReactiveProc(spellName) then
        hasProc = true
    end

    -- 2. Nampower 的 IsSpellUsable（考虑姿态、法力、冷却等）
    local isUsableBySpell = false
    if IsSpellUsable then
        local ok, usable, oom = pcall(IsSpellUsable, spellName)
        if ok and usable == 1 and oom ~= 1 then
            isUsableBySpell = true
        end
    end

    -- 3. 动作条按钮检测（备用，不依赖 combat log）
    local isUsableByActionBar = false
    if CleveRoids.reactiveSlots and CleveRoids.reactiveSlots[spellName] then
        local actionSlot = CleveRoids.reactiveSlots[spellName]
        local isUsable, oom = CleveRoids.Hooks.OriginalIsUsableAction(actionSlot)
        local start, duration = GetActionCooldown(actionSlot)
        if isUsable and (start == 0 or duration == 1.5) then
            isUsableByActionBar = true
        end
    end

    -- 只要任一条件成立，即认为可用
    if hasProc or isUsableBySpell or isUsableByActionBar then
        return 1
    else
        return nil
    end
end

-- Check if any spell is usable (not just reactive)
function CleveRoids.CheckSpellUsable(spellName)
    if not spellName then return false end

    -- Use Nampower's IsSpellUsable if available
    if IsSpellUsable then
        -- pcall to handle spells not in spellbook (Nampower throws error)
        local ok, usable, oom = pcall(IsSpellUsable, spellName)
        if ok then
            return (usable == 1 and oom ~= 1)
        end
        -- If pcall failed, spell not in spellbook - fall through to fallback
    end

    -- Fallback: check if spell exists and player has mana/rage/energy
    local spell = CleveRoids.GetSpell(spellName)
    if not spell then return false end

    -- Check mana cost
    local currentPower = UnitMana("player")
    if spell.cost and currentPower < spell.cost then
        return false
    end

    -- Check cooldown (ignore GCD)
    local start, duration = GetSpellCooldown(spell.spellSlot, spell.bookType)
    if start > 0 and duration > 1.5 then
        return false
    end

    return true
end

function CleveRoids.CheckSpellCast(unit, spell)
    local spell = spell or ""
    local guid = CleveRoids.GetGUID(unit)
    if not guid then return false end

    -- Player: check CurrentSpell (event-driven, most reliable for self)
    if unit == "player" then
        if CleveRoids.CurrentSpell and CleveRoids.CurrentSpell.type ~= "" then
            if spell == "" then
                return true
            end
            if CleveRoids.CurrentSpell.spellName and CleveRoids.CurrentSpell.spellName == spell then
                return true
            end
        end
        -- Fallback to GUID-based tracking and spell_tracking below
    end

    -- GUID-based cast tracking (pfUI 7.6 or standalone SPELL_START events)
    local ct = CleveRoids.castTracking
    if ct then
        local normalizedGuid = CleveRoids.NormalizeGUID(guid)
        local castEntry = normalizedGuid and ct[normalizedGuid]
        if castEntry and castEntry.endTime and GetTime() < castEntry.endTime then
            if spell == "" then
                return true
            end
            if castEntry.spellName then
                -- Strip rank suffix for comparison: "Heal(Rank 4)" -> "Heal"
                local baseName = CleveRoids.StripRank(castEntry.spellName)
                if baseName == spell or castEntry.spellName == spell then
                    return true
                end
            end
        end
    end

    -- Legacy fallback: spell_tracking-based cast tracking (Nampower SPELL_START_SELF/OTHER) by 武藤纯子酱 2026.9.1
    if not CleveRoids.spell_tracking[guid] then
        return false
    else
        if spell == GetSpellRecField(CleveRoids.spell_tracking[guid].spell_id, "name") or (spell == CleveRoids.SpellSchoolName[CleveRoids.spell_tracking[guid].school]) or (spell == "") then -- 新增 spellschool 判定 by 武藤纯子酱 2026.3.5
            return true
        end
        return false
    end
end

-- ============================================================================
-- CC (Crowd Control) Mechanic Detection
-- Uses BuffLib if available, otherwise uses built-in spell database
-- ============================================================================

-- Maps CC type names to mechanic constants (matches DBC mechanic IDs)
-- Note: Some types map to multiple mechanics via CCMechanicGroups below
CleveRoids.CCMechanics = {
    -- Movement/control impairment
    charm       = 1,   -- Mind Control, Seduction
    disoriented = 2,   -- Scatter Shot, Blind (disorient component)
    disorient   = 2,   -- Alias for disoriented
    disarm      = 3,   -- Disarm, Riposte disarm
    distract    = 4,   -- Distract (Rogue ability)
    fear        = 5,   -- Fear, Psychic Scream, Howl of Terror
    grip        = 6,   -- Grip effects
    root        = 7,   -- Entangling Roots, Frost Nova, Improved Hamstring
    pacify      = 8,   -- Pacify effects
    silence     = 9,   -- Silence, Kick, Counterspell (lockout)
    sleep       = 10,  -- Hibernate, Wyvern Sting sleep
    snare       = 11,  -- Hamstring, Wing Clip, Crippling Poison
    slow        = 11,  -- Alias for snare
    stun        = 12,  -- Consolidated: Stun(12) + Knockout(14) + Sap(30)
    freeze      = 13,  -- Freeze effects (Frost Nova freeze)
    bleed       = 15,  -- Rend, Garrote, Deep Wounds
    polymorph   = 17,  -- Polymorph (all variants)
    banish      = 18,  -- Banish (Warlock)
    shackle     = 20,  -- Shackle Undead
    horror      = 24,  -- Death Coil (Warlock), Intimidating Shout (horror)
    daze        = 27,  -- Dazed effects
}

-- Mechanic groups: CC types that check multiple DBC mechanics
-- Used when a single conditional should match several related effects
CleveRoids.CCMechanicGroups = {
    stun = {12, 14, 30},  -- Stun(12), Knockout/Gouge(14), Sap(30)
}

-- CC types that count as "crowd controlled" (loss of control)
-- Note: Mechanics 12, 14, 30 are all consolidated under "stun" for conditionals
CleveRoids.CCTypesLossOfControl = {
    [1] = true,   -- charm
    [2] = true,   -- disoriented
    [5] = true,   -- fear
    [7] = true,   -- root (Entangling Roots, Frost Nova, etc.)
    [10] = true,  -- sleep
    [12] = true,  -- stun (Cheap Shot, Kidney Shot, etc.)
    [13] = true,  -- freeze
    [14] = true,  -- knockout/gouge (now part of stun group)
    [17] = true,  -- polymorph
    [18] = true,  -- banish
    [20] = true,  -- shackle
    [24] = true,  -- horror
    [30] = true,  -- sap (now part of stun group)
}

-- Complete spell ID to mechanic mapping from DBC data
-- Extracted from BuffLib SpellData - 785 spells with mechanics
-- Mechanic IDs: 1=Charm, 2=Disorient, 3=Disarm, 5=Fear, 7=Root, 9=Silence,
--               10=Sleep, 11=Snare, 12=Stun, 13=Freeze, 14=Knockout,
--               15=Bleed, 17=Polymorph, 18=Banish, 20=Shackle, 21=Mount,
--               23=Turn, 24=Horror, 25=Invuln, 27=Daze
CleveRoids.CCSpellMechanics = {
    [17] = 19, [56] = 12, [89] = 11, [113] = 7, [118] = 17, [228] = 17,
    [246] = 11, [339] = 7, [408] = 12, [451] = 9, [458] = 21, [459] = 21,
    [468] = 21, [470] = 21, [471] = 21, [472] = 21, [474] = 6, [498] = 25,
    [507] = 6, [512] = 7, [578] = 21, [579] = 21, [580] = 21, [581] = 21,
    [592] = 19, [593] = 6, [600] = 19, [605] = 1, [642] = 25, [676] = 3,
    [700] = 10, [703] = 15, [710] = 18, [745] = 7, [746] = 16, [771] = 1,
    [772] = 15, [835] = 12, [851] = 17, [853] = 12, [861] = 9, [867] = 6,
    [998] = 6, [1020] = 25, [1022] = 25, [1062] = 7, [1079] = 15, [1090] = 10,
    [1098] = 1, [1159] = 16, [1513] = 5, [1776] = 14, [1777] = 14, [1833] = 12,
    [1943] = 15, [2070] = 14, [2094] = 2, [2637] = 10, [2878] = 23, [2880] = 12,
    [2937] = 10, [3109] = 5, [3143] = 12, [3147] = 15, [3242] = 12, [3263] = 12,
    [3267] = 16, [3268] = 16, [3355] = 13, [3363] = 21, [3409] = 11, [3410] = 11,
    [3446] = 12, [3542] = 7, [3551] = 12, [3589] = 9, [3600] = 11, [3604] = 11,
    [3609] = 12, [3635] = 12, [3636] = 10, [3747] = 19, [4060] = 17, [4064] = 12,
    [4065] = 12, [4066] = 12, [4067] = 12, [4068] = 12, [4069] = 12, [4102] = 15,
    [4244] = 15, [4962] = 7, [5106] = 12, [5116] = 11, [5134] = 5, [5159] = 11,
    [5164] = 12, [5195] = 7, [5196] = 7, [5211] = 12, [5246] = 5, [5259] = 3,
    [5276] = 12, [5376] = 4, [5403] = 12, [5484] = 5, [5530] = 12, [5531] = 12,
    [5567] = 7, [5573] = 25, [5588] = 12, [5589] = 12, [5597] = 15, [5598] = 15,
    [5599] = 25, [5627] = 23, [5648] = 12, [5649] = 12, [5703] = 12, [5708] = 12,
    [5782] = 5, [5784] = 21, [5917] = 6, [5918] = 12, [6065] = 19, [6066] = 19,
    [6136] = 11, [6146] = 11, [6213] = 5, [6215] = 5, [6253] = 12, [6266] = 12,
    [6304] = 12, [6358] = 1, [6388] = 11, [6409] = 12, [6435] = 12, [6466] = 12,
    [6524] = 12, [6533] = 7, [6546] = 15, [6547] = 15, [6548] = 15, [6605] = 5,
    [6607] = 12, [6608] = 3, [6648] = 21, [6653] = 21, [6654] = 21, [6713] = 3,
    [6726] = 9, [6728] = 12, [6730] = 12, [6749] = 12, [6770] = 14, [6777] = 21,
    [6788] = 19, [6798] = 12, [6896] = 21, [6897] = 21, [6898] = 21, [6899] = 21,
    [6927] = 12, [6942] = 9, [6945] = 12, [6982] = 12, [6984] = 11, [6985] = 11,
    [7074] = 9, [7093] = 5, [7139] = 12, [7279] = 11, [7321] = 11, [7399] = 5,
    [7645] = 1, [7803] = 12, [7922] = 12, [7926] = 16, [7927] = 16, [7964] = 12,
    [7967] = 10, [7992] = 11, [8040] = 10, [8122] = 5, [8124] = 5, [8142] = 7,
    [8150] = 12, [8208] = 12, [8225] = 5, [8242] = 12, [8281] = 9, [8285] = 12,
    [8312] = 7, [8346] = 7, [8377] = 7, [8379] = 3, [8391] = 12, [8394] = 21,
    [8395] = 21, [8396] = 21, [8399] = 10, [8629] = 14, [8631] = 15, [8632] = 15,
    [8633] = 15, [8639] = 15, [8640] = 15, [8643] = 12, [8646] = 12, [8715] = 5,
    [8716] = 11, [8818] = 15, [8901] = 10, [8902] = 10, [8980] = 21, [8983] = 12,
    [8988] = 9, [8994] = 18, [9005] = 12, [9007] = 15, [9080] = 11, [9159] = 10,
    [9484] = 20, [9485] = 20, [9552] = 9, [9823] = 12, [9824] = 15, [9826] = 15,
    [9827] = 12, [9852] = 7, [9853] = 7, [9896] = 15, [9915] = 7, [10017] = 7,
    [10234] = 10, [10253] = 17, [10266] = 15, [10278] = 25, [10308] = 12,
    [10326] = 23, [10787] = 21, [10788] = 21, [10789] = 21, [10790] = 21,
    [10792] = 21, [10793] = 21, [10795] = 21, [10796] = 21, [10798] = 21,
    [10799] = 21, [10800] = 21, [10801] = 21, [10802] = 21, [10803] = 21,
    [10804] = 21, [10838] = 16, [10839] = 16, [10851] = 3, [10852] = 7,
    [10855] = 11, [10856] = 12, [10873] = 21, [10888] = 5, [10890] = 5,
    [10898] = 19, [10899] = 19, [10900] = 19, [10901] = 19, [10911] = 1,
    [10912] = 1, [10955] = 20, [10969] = 21, [10987] = 11, [11020] = 12,
    [11201] = 11, [11264] = 7, [11273] = 15, [11274] = 15, [11275] = 15,
    [11285] = 14, [11286] = 14, [11289] = 15, [11290] = 15, [11297] = 14,
    [11428] = 12, [11430] = 12, [11436] = 11, [11446] = 1, [11572] = 15,
    [11573] = 15, [11574] = 15, [11578] = 12, [11579] = 12, [11641] = 17, [11650] = 12, [11725] = 1,
    [11726] = 1, [11820] = 7, [11831] = 7, [11836] = 12, [11876] = 12,
    [11879] = 3, [11922] = 7, [11958] = 13, [11977] = 15, [12023] = 7,
    [12024] = 7, [12054] = 15, [12096] = 5, [12098] = 10, [12252] = 7,
    [12323] = 11, [12355] = 12, [12421] = 12, [12461] = 12, [12484] = 11,
    [12485] = 11, [12486] = 11, [12494] = 7, [12528] = 9, [12531] = 11,
    [12540] = 14, [12542] = 5, [12543] = 12, [12551] = 11, [12562] = 12,
    [12674] = 7, [12705] = 11, [12721] = 15, [12730] = 5, [12734] = 12,
    [12747] = 7, [12748] = 7, [12798] = 12, [12809] = 12, [12824] = 17,
    [12825] = 17, [12826] = 17, [12946] = 9, [13005] = 12, [13099] = 7,
    [13119] = 7, [13138] = 7, [13181] = 1, [13237] = 12, [13318] = 15,
    [13323] = 17, [13327] = 14, [13443] = 15, [13445] = 15, [13534] = 3,
    [13579] = 14, [13608] = 7, [13704] = 5, [13738] = 15, [13747] = 11,
    [13808] = 12, [13810] = 11, [13819] = 21, [13902] = 12, [14030] = 7,
    [14087] = 15, [14100] = 5, [14102] = 12, [14118] = 15, [14180] = 3,
    [14207] = 11, [14308] = 13, [14309] = 13, [14326] = 5, [14327] = 5,
    [14331] = 15, [14515] = 1, [14621] = 17, [14874] = 15, [14897] = 11,
    [14902] = 12, [14903] = 15, [14907] = 7, [15063] = 7, [15091] = 14,
    [15269] = 12, [15283] = 12, [15398] = 12, [15471] = 7, [15474] = 7,
    [15487] = 9, [15531] = 7, [15532] = 7, [15534] = 17, [15535] = 12,
    [15583] = 15, [15593] = 12, [15609] = 7, [15618] = 12, [15621] = 12,
    [15652] = 12, [15655] = 12, [15744] = 14, [15752] = 3, [15753] = 12,
    [15779] = 21, [15780] = 21, [15781] = 21, [15822] = 10, [15859] = 1,
    [15878] = 12, [15970] = 10, [15976] = 15, [16045] = 18, [16046] = 14,
    [16050] = 11, [16053] = 1, [16055] = 21, [16056] = 21, [16058] = 21,
    [16059] = 21, [16060] = 21, [16075] = 12, [16080] = 21, [16081] = 21,
    [16082] = 21, [16083] = 21, [16084] = 21, [16095] = 15, [16096] = 5,
    [16097] = 17, [16104] = 12, [16350] = 12, [16393] = 15, [16403] = 15,
    [16406] = 15, [16451] = 18, [16469] = 7, [16497] = 12, [16508] = 5,
    [16509] = 15, [16566] = 7, [16568] = 11, [16600] = 12, [16707] = 17,
    [16708] = 17, [16709] = 17, [16727] = 12, [16790] = 12, [16798] = 10,
    [16803] = 12, [16838] = 9, [16869] = 12, [16922] = 12, [17011] = 12,
    [17145] = 14, [17153] = 15, [17165] = 11, [17172] = 17, [17174] = 11,
    [17229] = 21, [17276] = 12, [17277] = 14, [17286] = 12, [17293] = 12,
    [17308] = 12, [17405] = 1, [17450] = 21, [17453] = 21, [17454] = 21,
    [17455] = 21, [17456] = 21, [17458] = 21, [17459] = 21, [17460] = 21,
    [17461] = 21, [17462] = 21, [17463] = 21, [17464] = 21, [17465] = 21,
    [17481] = 21, [17500] = 12, [17504] = 15, [17738] = 17, [17928] = 5,
    [18075] = 15, [18078] = 15, [18093] = 12, [18103] = 12, [18106] = 15,
    [18118] = 11, [18144] = 12, [18200] = 15, [18202] = 15, [18223] = 11,
    [18278] = 9, [18327] = 9, [18328] = 11, [18363] = 21, [18395] = 12,
    [18425] = 9, [18431] = 5, [18469] = 9, [18498] = 9, [18503] = 17,
    [18608] = 16, [18610] = 16, [18647] = 18, [18657] = 10, [18658] = 10,
    [18763] = 12, [18802] = 11, [18812] = 12, [18972] = 11, [18989] = 21,
    [18990] = 21, [18991] = 21, [18992] = 21, [19128] = 12, [19134] = 5,
    [19136] = 12, [19137] = 11, [19185] = 7, [19229] = 7, [19364] = 12,
    [19386] = 10, [19393] = 9, [19408] = 5, [19410] = 12, [19469] = 1,
    [19482] = 12, [19496] = 11, [19501] = 2, [19503] = 2, [19641] = 12,
    [19718] = 3, [19769] = 12, [19771] = 15, [19780] = 12, [19784] = 12,
    [19821] = 9, [19970] = 7, [19971] = 7, [19972] = 7, [19973] = 7,
    [19974] = 7, [19975] = 7, [20066] = 14, [20170] = 12, [20253] = 12,
    [20276] = 12, [20277] = 12, [20310] = 12, [20511] = 5, [20549] = 12,
    [20604] = 1, [20614] = 12, [20615] = 12, [20654] = 7, [20663] = 10,
    [20669] = 10, [20683] = 12, [20685] = 12, [20699] = 7, [20706] = 19,
    [20740] = 1, [20882] = 1, [20907] = 15, [20908] = 15, [20989] = 10,
    [21099] = 12, [21152] = 12, [21330] = 5, [21331] = 7, [21748] = 12,
    [21749] = 12, [21869] = 5, [21898] = 5, [21949] = 15, [21990] = 12,
    [22127] = 7, [22274] = 17, [22289] = 12, [22356] = 11, [22415] = 7,
    [22419] = 3, [22424] = 14, [22427] = 12, [22519] = 7, [22566] = 17,
    [22570] = 14, [22592] = 12, [22639] = 11, [22645] = 7, [22666] = 9,
    [22678] = 5, [22686] = 5, [22691] = 3, [22692] = 12, [22717] = 21,
    [22718] = 21, [22719] = 21, [22720] = 21, [22721] = 21, [22722] = 21,
    [22723] = 21, [22724] = 21, [22744] = 7, [22752] = 19, [22800] = 7,
    [22884] = 5, [22914] = 11, [22915] = 12, [22919] = 11, [22924] = 7,
    [22994] = 7, [23039] = 14, [23103] = 12, [23113] = 14, [23161] = 21,
    [23207] = 9, [23214] = 21, [23219] = 21, [23220] = 21, [23221] = 21,
    [23222] = 21, [23223] = 21, [23225] = 21, [23227] = 21, [23228] = 21,
    [23229] = 21, [23238] = 21, [23239] = 21, [23240] = 21, [23241] = 21,
    [23242] = 21, [23243] = 21, [23246] = 21, [23247] = 21, [23248] = 21,
    [23249] = 21, [23250] = 21, [23251] = 21, [23252] = 21, [23275] = 5,
    [23338] = 21, [23364] = 12, [23365] = 3, [23454] = 12, [23509] = 21,
    [23510] = 21, [23567] = 16, [23568] = 16, [23569] = 16, [23600] = 11,
    [23603] = 17, [23618] = 12, [23694] = 7, [23696] = 16, [23918] = 9,
    [23919] = 12, [23953] = 11, [24004] = 10, [24053] = 17, [24110] = 7,
    [24118] = 15, [24119] = 15, [24120] = 15, [24132] = 10, [24133] = 10,
    [24152] = 7, [24192] = 15, [24213] = 12, [24225] = 11, [24242] = 21,
    [24252] = 21, [24259] = 9, [24327] = 1, [24331] = 15, [24332] = 15,
    [24333] = 12, [24335] = 10, [24360] = 10, [24375] = 12, [24394] = 12,
    [24412] = 16, [24413] = 16, [24414] = 16, [24415] = 11, [24576] = 21,
    [24600] = 12, [24648] = 7, [24664] = 10, [24671] = 12, [24687] = 9,
    [24698] = 14, [24712] = 17, [24713] = 17, [24735] = 17, [24736] = 17,
    [24778] = 10, [25022] = 11, [25049] = 14, [25056] = 12, [25057] = 3,
    [25187] = 11, [25189] = 12, [25260] = 5, [25654] = 12, [25655] = 3,
    [25675] = 21, [25771] = 25, [25809] = 11, [25815] = 5, [25852] = 12,
    [25858] = 21, [25859] = 21, [25863] = 21, [25953] = 21, [25999] = 7,
    [26042] = 5, [26054] = 21, [26055] = 21, [26056] = 21, [26069] = 9,
    [26070] = 5, [26071] = 7, [26078] = 11, [26108] = 2, [26141] = 11,
    [26143] = 11, [26157] = 17, [26180] = 10, [26211] = 11, [26272] = 17,
    [26273] = 17, [26274] = 17, [26379] = 11, [26580] = 5, [26641] = 5,
    [26655] = 21, [26740] = 1, [27555] = 15, [27556] = 15, [27559] = 9,
    [27565] = 18, [27581] = 3, [27607] = 19, [27610] = 5, [27615] = 12,
    [27619] = 13, [27634] = 11, [27638] = 15, [27640] = 11, [27641] = 5,
    [27758] = 12, [27760] = 17, [27880] = 12, [27990] = 5, [27993] = 11,
    [28270] = 17, [28271] = 17, [28272] = 17, [28314] = 12, [28315] = 5,
    [28445] = 12, [28456] = 14, [28725] = 12, [28858] = 7, [28911] = 15,
    [28913] = 15, [28991] = 7, [29059] = 21, [29168] = 5, [29407] = 11,
    [29419] = 5, [29544] = 5, [29685] = 5, [29848] = 17, [29849] = 7,
    [29915] = 15, [29943] = 9, [30001] = 5, [30002] = 5, [30020] = 16,
    [30094] = 7, [30174] = 21, [30225] = 9, [30285] = 15, [31365] = 5,
    [31700] = 21,
}

-- Check if BuffLib is available with full mechanic support
function CleveRoids.HasBuffLib()
    -- Defensive: ensure BuffLib.SpellData is a table, not a function
    return BuffLib and BuffLib.GetUnitDebuffsByMechanic
        and type(BuffLib.SpellData) == "table"
        and BuffLib.SpellData.GetMechanic
end

-- Get mechanic for a spell ID (uses BuffLib if available, otherwise built-in table)
function CleveRoids.GetSpellMechanic(spellID)
    if not spellID or spellID <= 0 then return 0 end

    -- Try BuffLib first (has complete DBC data)
    -- Defensive: verify SpellData is a table before indexing
    if BuffLib and type(BuffLib.SpellData) == "table" and BuffLib.SpellData.GetMechanic then
        local mechanic = BuffLib.SpellData:GetMechanic(spellID)
        if mechanic and mechanic > 0 then
            return mechanic
        end
    end

    -- Fall back to built-in table
    return CleveRoids.CCSpellMechanics[spellID] or 0
end

-- Validate CC on a unit (target, focus, player, etc.)
-- Returns true if the unit has the specified CC mechanic active
function CleveRoids.ValidateUnitCC(unit, ccType)
    if not unit or not UnitExists(unit) then return false end
    -- 修复：非字符串（条件值带比较符被解析成表）直接返回 false，避免 string.lower(表) 崩溃
    -- by 武藤纯子酱 2026.9.11
    if type(ccType) ~= "string" then return false end

    local ccTypeLower = string.lower(ccType or "")

    -- Special case: "cc" means any loss-of-control effect
    if ccTypeLower == "cc" or ccTypeLower == "any" then
        return CleveRoids.ValidateUnitAnyCrowdControl(unit)
    end
    
    -- Check if this CC type maps to a group of mechanics
    local mechanicGroup = CleveRoids.CCMechanicGroups[ccTypeLower]
    if mechanicGroup then
        -- Check all mechanics in the group (e.g., stun checks 12, 14, 30)
        for _, mechanic in ipairs(mechanicGroup) do
            if CleveRoids.ValidateUnitCCSingleMechanic(unit, mechanic) then
                return true
            end
        end
        return false
    end

    -- Single mechanic lookup
    local mechanic = CleveRoids.CCMechanics[ccTypeLower]
    if not mechanic then return false end

    return CleveRoids.ValidateUnitCCSingleMechanic(unit, mechanic)
end

-- Validate a single CC mechanic on a unit (helper function)
function CleveRoids.ValidateUnitCCSingleMechanic(unit, mechanic)
    -- Use BuffLib if available (most accurate - tracks overflow debuffs and hidden auras)
    if CleveRoids.HasBuffLib() then
        local guid = CleveRoids.GetGUID(unit)
        if not guid then return false end

        if unit == "player" then
            return BuffLib:HasDebuffOfMechanic(mechanic)
        else
            local debuffs = BuffLib:GetUnitDebuffsByMechanic(guid, mechanic)
            return debuffs and table.getn(debuffs) > 0
        end
    end

    -- Fallback: scan unit debuffs directly
    return CleveRoids.ValidateUnitCCDirect(unit, mechanic)
end

-- Check if unit has any crowd control (loss of control) effect
function CleveRoids.ValidateUnitAnyCrowdControl(unit)
    if not unit or not UnitExists(unit) then return false end

    -- Use BuffLib if available
    if CleveRoids.HasBuffLib() then
        local guid = CleveRoids.GetGUID(unit)
        if not guid then return false end

        if unit == "player" then
            for mechanic, _ in pairs(CleveRoids.CCTypesLossOfControl) do
                if BuffLib:HasDebuffOfMechanic(mechanic) then
                    return true
                end
            end
        else
            for mechanic, _ in pairs(CleveRoids.CCTypesLossOfControl) do
                local debuffs = BuffLib:GetUnitDebuffsByMechanic(guid, mechanic)
                if debuffs and table.getn(debuffs) > 0 then
                    return true
                end
            end
        end
        return false
    end

    -- Fallback: check all loss-of-control mechanics directly
    for mechanic, _ in pairs(CleveRoids.CCTypesLossOfControl) do
        if CleveRoids.ValidateUnitCCDirect(unit, mechanic) then
            return true
        end
    end
    return false
end

-- Direct CC check - scans unit debuffs for spell IDs to determine CC mechanics
-- Works without BuffLib by using built-in spell mechanic table
function CleveRoids.ValidateUnitCCDirect(unit, mechanic)
    -- UnitDebuff 第 4 返回值 spellID 依赖 Nampower 的 GetUnitField spellID hook
    -- （NampowerAPI.lua 加载时安装，替代 SuperWoW 的 aura spellID 扩展返回值） by 武藤纯子酱 2026.9.1
    if not CleveRoids.hasAuraSpellIds then return false end

    -- Players only have 16 debuff slots, no overflow
    -- Non-player units can have overflow debuffs in buff slots (17-48)
    local isPlayer = (unit == "player")
    local maxDebuffSlots = 16
    local maxOverflowSlots = isPlayer and 0 or 32

    -- Scan regular debuff slots (1-16)
    for i = 1, maxDebuffSlots do
        local texture, stacks, debuffType, spellID = UnitDebuff(unit, i)
        if not texture then break end

        if spellID and spellID > 0 then
            local spellMechanic = CleveRoids.GetSpellMechanic(spellID)
            if spellMechanic == mechanic then
                return true
            end
        end
    end

    -- Scan overflow slots in buff bar (non-player units only)
    if maxOverflowSlots > 0 then
        for i = 1, maxOverflowSlots do
            local texture, stacks, spellID = UnitBuff(unit, i)
            if not texture then break end

            if spellID and spellID > 0 then
                local spellMechanic = CleveRoids.GetSpellMechanic(spellID)
                if spellMechanic == mechanic then
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================================
-- MELEE RANGE CHECK VIA IsSpellInRange
-- ============================================================================
-- Uses Nampower's IsSpellInRange with a melee-range spell from the player's
-- spellbook for reliable game-engine range checking (avoids UnitXP issues).

local meleeRangeSpellId = nil -- cached spell ID, false = searched but none found

--- Find a melee-range spell (rangeIndex == 1) with unit targeting from the
--- player's spellbook. Caches the result for subsequent calls.
local function FindMeleeRangeSpell()
    if meleeRangeSpellId then return meleeRangeSpellId end
    if meleeRangeSpellId == false then return nil end

    local API = CleveRoids.NampowerAPI
    if not API or not IsSpellInRange then return nil end
    if not CleveRoids.Spells or not CleveRoids.Spells[BOOKTYPE_SPELL] then return nil end

    for name, data in pairs(CleveRoids.Spells[BOOKTYPE_SPELL]) do
        local spellId = API.GetSpellIdFromName(name)
        if spellId then
            local rangeIndex = API.GetSpellField(spellId, "rangeIndex")
            if rangeIndex == 1 then -- Melee range (5 yards)
                if API.IsUnitTargetedSpell(spellId) then
                    meleeRangeSpellId = spellId
                    return spellId
                end
            end
        end
    end

    meleeRangeSpellId = false -- No suitable spell found
    return nil
end

--- Check if a unit is in melee range.
--- @param unit string Unit token or GUID to check
--- @param cleaveRange boolean? When true, uses 5-yard threshold (cleave/splash range)
---   instead of 2-yard threshold (auto-attack melee range). Used by count mode to
---   detect enemies within cleave distance.
--- @return boolean
function CleveRoids.IsUnitInMeleeRange(unit, cleaveRange, baseUnit) -- 新增baseUnit参数 by 武藤纯子酱 2026.4.13
    if not UnitExists(unit) then return false end
    if CleveRoids.IsUnitDead(unit) then return false end
    if not CleveRoids.IsValidUnitToken(baseUnit) then baseUnit = "player" end -- 校验非法基准单位 by 武藤纯子酱 2026.9.23

    local threshold = cleaveRange and 0 or 2 -- 0才是近战距离 by 武藤纯子酱 2026.3.9

    if CleveRoids.hasUnitXP then
        local distance = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit, "meleeAutoAttack") -- 用 meleeAutoAttack 精确检测近战攻击距离 by 武藤纯子酱 2026.3.9，改用baseUnit by 武藤纯子酱 2026.4.13
        if distance then return distance <= threshold end
    end

    -- Fallback: IsSpellInRange with a melee-range spell (works with GUID tokens)
    local spellId = FindMeleeRangeSpell()
    if spellId and IsSpellInRange then -- 修复：无 Nampower 时 IsSpellInRange 为 nil，原直接调用会红字 by 武藤纯子酱 2026.9.11
        local result = IsSpellInRange(spellId, unit)
        if result == 1 then return true end
        if result == 0 then return false end
    end

    -- Last resort (~10 yards, less accurate)
    return CheckInteractDistance(unit, 3)
end

-- Count mode filter functions for compound conditionals.
-- Allows count mode to combine checks: [meleerange:facing>1] counts enemies
-- in melee range AND facing. The filter name is the "name" field in count args.
local countModeFilters = {
    facing = function(unit, baseUnit) -- 新增baseUnit参数 by 武藤纯子酱 2026.4.13
        if not CleveRoids.hasUnitXP then return false end -- 修复：无 UnitXP 时 UnitXP() 为空桩，`~= true` 会恒真 by 武藤纯子酱 2026.9.11
        return CleveRoids.SafeUnitXP("behind", unit, baseUnit) ~= true
    end,
    behind = function(unit, baseUnit) -- 新增baseUnit参数 by 武藤纯子酱 2026.4.13
        if not CleveRoids.hasUnitXP then return false end
        return CleveRoids.SafeUnitXP("behind", baseUnit, unit) == true
    end,
    meleerange = function(unit, baseUnit) -- 新增baseUnit参数 by 武藤纯子酱 2026.4.13
        return CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit)
    end,
}

-- Parse the name field of count mode args for optional filter and distance threshold.
-- Supports: "facing", "behind", "meleerange" (filter only),
--           "30" (distance only),
--           "30:facing" or "30facing" (distance + filter)
-- Returns: filterFunc or nil, distanceThreshold or nil
-- name 位若就是宏动作名（说明用户没写过滤器/基准单位，是解析器用动作名填的），视为"未指定"，
-- 否则会被当成基准单位 → 计数恒为 0（[meleerange:>=1] 这类无显式名字的计数条件直接失效）
-- by 武藤纯子酱 2026.9.28
local function ParseCountModeFilter(name, actionName)
    if actionName ~= nil and name ~= nil and name == actionName then name = nil end
    if not name then return nil, nil, "player" end

    local lower = string.lower(name)
    local filter = countModeFilters[lower]
    if filter then return filter, nil, "player" end

    local dist = tonumber(name)
    if dist then return nil, dist, "player" end

    -- Compound with colon: "30:facing" (from distance:30:facing>1)
    local _, _, num, qualifier = string.find(name, "^(%d+%.?%d*):(%a+)$")
    if num and qualifier then
        return countModeFilters[string.lower(qualifier)], tonumber(num), "player"
    end

    -- Compound without separator: "30facing"
    _, _, num, qualifier = string.find(name, "^(%d+%.?%d*)(%a+)$")
    if num and qualifier then
        return countModeFilters[string.lower(qualifier)], tonumber(num), "player"
    end

    -- 新增解析基准单位：格式如 "pet" 或 "30:pet" 或 "30:pet|facing" 或 "pet|facing" by 武藤纯子酱 2026.4.13
    local baseUnit = "player"
    local filterFunc = nil
    local distThreshold = nil
    local remaining = name

    -- 先提取距离（如果存在）
    local _, _, maybeNum, restAfterNum = string.find(remaining, "^(%d+%.?%d*):(.+)$")
    if maybeNum then
        distThreshold = tonumber(maybeNum)
        remaining = restAfterNum
    else
        -- 尝试无冒号的距离+基准单位组合，如 "30pet"
        _, _, maybeNum, restAfterNum = string.find(remaining, "^(%d+%.?%d*)(%a+.*)$")
        if maybeNum then
            distThreshold = tonumber(maybeNum)
            remaining = restAfterNum
        end
    end

    -- 剩余部分可能包含基准单位和过滤器，用 | 分隔
    local pipePos = string.find(remaining, "|", 1, true)
    if pipePos then
        baseUnit = string.sub(remaining, 1, pipePos - 1)
        local filterPart = string.sub(remaining, pipePos + 1)
        filterFunc = countModeFilters[string.lower(filterPart)]
    else
        -- 没有 |，则整个剩余部分视为基准单位（如果为空则默认player）
        if remaining ~= "" then
            -- 验证剩余部分是否为有效单位
			local ok = CleveRoids.IsValidUnitToken(remaining) -- 修复：原 pcall(UnitExists) 对未知 token 也返回 ok=true，会把非法 token 当基准单位 by 武藤纯子酱 2026.9.23
            if ok then
                baseUnit = remaining
            else
                baseUnit = "player"
            end
        end
    end

    -- 如果基准单位不是有效的UnitToken，回退到player（但保留尝试）
    if baseUnit == "" then baseUnit = "player" end

    return filterFunc, distThreshold, baseUnit
end

-- Resolve virtual unit tokens (focus, focustarget) to real WoW 1.12 unit tokens.
-- pfUI emulates focus via label+id (e.g. "party2").
-- Returns resolved token or nil if the unit cannot be resolved.
local function ResolveFocusUnit(unit)
    if unit == "focus" then
        return CleveRoids.GetFocusUnitId()
    elseif unit == "focustarget" then
        local fid = CleveRoids.GetFocusUnitId()
        return fid and (fid .. "target") or nil
    end
    return unit
end

-- 新增函数，识别平射推迟多久 by 武藤纯子酱 2026.4.7
-- Get the delay (in seconds) that casting a spell would cause to the ranged auto-shot timer
-- Returns castTime - remaining, or 0 if no timer or instant cast
function CleveRoids.GetSpellRangedClipDelay(spellName)
    if not spellName then return nil end
    local remaining, rangedSpeed = CleveRoids.GetRangedTimerRaw()

    -- No ranged auto-shot active → nothing to clip
    if remaining == nil then
        return 0
    end
    local castTime = CleveRoids.GetSpellCastTime(spellName)
    if not castTime or castTime <= 0 then
        return 0  -- Instant cast → no clip
    end
    return castTime - remaining
end

-- 新增函数，识别平射推迟多久 by 武藤纯子酱 2026.4.7
-- Helper: check if casting a spell would clip ranged auto-shot (with safety buffer)
-- Returns true if the spell would clip (i.e., castTime > remaining - threshold)
-- For multi-comparison, returns true only if ALL comparisons are satisfied.
function CleveRoids.IsRangedClipSpell(spellName, operator, threshold, comparisons)
    if not spellName then return false end
    local remaining, _ = CleveRoids.GetRangedTimerRaw()
    if remaining == nil then
        return false
    end
    local castTime = CleveRoids.GetSpellCastTime(spellName)
    if not castTime or castTime <= 0 then
        return false
    end

    -- Helper for a single comparison using existing comparators
    local function compareSingle(op, thresh)
        if not op or thresh == nil then return false end
        local cmp = CleveRoids.comparators[op]
        if not cmp then return false end
        local safeWindow = remaining - thresh
        if safeWindow < 0 then safeWindow = 0 end
        return cmp(castTime, safeWindow)
    end

    -- Multi-comparison (AND logic)
    if comparisons and type(comparisons) == "table" then
        for _, comp in ipairs(comparisons) do
            if not compareSingle(comp.operator, comp.amount) then
                return false
            end
        end
        return true
    end

    -- Single comparison
    if operator and threshold ~= nil then
        return compareSingle(operator, threshold)
    end

    -- No operator/threshold: default behavior (clip if castTime > remaining)
    return castTime > remaining
end

-- 新增函数，获取宠物的Buff by 武藤纯子酱 2025.12.11
function CleveRoids.ValidatePetBuff(args)
    return CleveRoids.ValidateAura("pet", args, true)
end

-- 新增函数，获取宠物的Debuff by 武藤纯子酱 2025.12.11
function CleveRoids.ValidatePetDebuff(args)
    return CleveRoids.ValidateAura("pet", args, false)
end

-- [petcd]/[petcooldown] 宠物技能冷却查询 by 武藤纯子酱 2026.8.31
-- 遍历宠物动作条（1..NUM_PET_ACTION_SLOTS），按技能名匹配后用 GetPetActionCooldown 读冷却。
-- 返回：指定技能的剩余冷却秒数（就绪=0）；技能未找到/无宠物返回 nil。
function CleveRoids.GetPetActionCooldownRemaining(searchName)
    if not GetPetActionInfo or not GetPetActionCooldown then return nil end
    if not UnitExists("pet") then return nil end

    local search
    if searchName then
        search = string.lower(string.gsub(CleveRoids.StripRank(tostring(searchName)), "_", " "))
    end

    local maxSlot = tonumber(NUM_PET_ACTION_SLOTS) or 10
    for slot = 1, maxSlot do
        local name = GetPetActionInfo(slot)
        if name then
            local slotName = string.lower(CleveRoids.StripRank(name))
            if not search or slotName == search then
                local start, duration = GetPetActionCooldown(slot)
                if start and start > 0 and duration and duration > 0 then
                    local remaining = (start + duration) - GetTime()
                    if remaining < 0 then remaining = 0 end
                    return remaining
                end
                return 0
            end
        end
    end
    return nil
end

-- [petcd] 辅助：遍历宠物动作条全部技能，任意一个技能的剩余冷却满足 matchFn 即返回 true by 武藤纯子酱 2026.8.31
function CleveRoids.ScanPetActionCooldowns(matchFn)
    if not GetPetActionInfo or not GetPetActionCooldown then return false end
    if not UnitExists("pet") then return false end

    local maxSlot = tonumber(NUM_PET_ACTION_SLOTS) or 10
    for slot = 1, maxSlot do
        -- GetPetActionInfo 返回 name, subtext, texture, isToken, ... —— isToken 是第4个返回值，
        -- 之前取第3个（texture）恒为真导致裸 [petcd]/[nopetcd] 永远 false by 武藤纯子酱 2026.8.31
        local name, _, _, isToken = GetPetActionInfo(slot)
        if name and not isToken then
            local start, duration = GetPetActionCooldown(slot)
            local remaining = 0
            if start and start > 0 and duration and duration > 0 then
                remaining = (start + duration) - GetTime()
                if remaining < 0 then remaining = 0 end
            end
            if matchFn(remaining) then return true end
        end
    end
    return false
end

-- [petcd] 单条目求值（petcd/nopetcd 共享）：返回 true/false；无法判定（技能未找到/无宠物）返回 nil by 武藤纯子酱 2026.8.31
-- args：字符串（仅技能名，无比较符）或解析条目表 {name, operator, amount, comparisons}
function CleveRoids.EvaluatePetCdEntry(args)
    local name, op, amount, comparisons
    if type(args) == "table" then
        name = args.name
        op = args.operator
        amount = tonumber(args.amount)
        comparisons = args.comparisons
    else
        name = args
    end

    -- 多重比较（如 <2&>0）：全部通过才算true（指定技能或任意技能） by 武藤纯子酱 2026.8.31
    if comparisons and type(comparisons) == "table" then
        local remaining = CleveRoids.GetPetActionCooldownRemaining(name)
        if remaining == nil then return nil end
        for _, comp in ipairs(comparisons) do
            if not CleveRoids.comparators[comp.operator] then return false end
            if not CleveRoids.comparators[comp.operator](remaining, tonumber(comp.amount)) then return false end
        end
        return true
    end

    if name and name ~= "" then
        -- 指定技能
        local remaining = CleveRoids.GetPetActionCooldownRemaining(name)
        if remaining == nil then return nil end
        if op and amount ~= nil then
            if not CleveRoids.comparators[op] then return false end
            return CleveRoids.comparators[op](remaining, amount) and true or false
        end
        return remaining > 0
    end

    -- 无技能名（[petcd:<2]）：任意宠物技能的剩余冷却满足比较 by 武藤纯子酱 2026.8.31
    if op and amount ~= nil then
        if not CleveRoids.comparators[op] then return false end
        return CleveRoids.ScanPetActionCooldowns(function(remaining)
            return CleveRoids.comparators[op](remaining, amount)
        end)
    end

    -- 无任何参数：任意宠物技能冷却中 by 武藤纯子酱 2026.8.31
    return CleveRoids.ScanPetActionCooldowns(function(remaining) return remaining > 0 end)
end

-- 新增函数，获取宠物的生命值百分比 by 武藤纯子酱 2025.12.11
function CleveRoids.GetCachedPetHealthPercent()
    local API = CleveRoids.NampowerAPI
    local hp = API and API.GetUnitHealth and API.GetUnitHealth("pet") or UnitHealth("pet")
    local max = API and API.GetUnitMaxHealth and API.GetUnitMaxHealth("pet") or UnitHealthMax("pet")
    return max > 0 and (100 * hp / max) or 0
end

-- 新增函数，获取宠物的集中值百分比 by 武藤纯子酱 2025.12.11
function CleveRoids.GetCachedPetPowerPercent()
    local API = CleveRoids.NampowerAPI
    local power = API and API.GetUnitPower and API.GetUnitPower("pet") or UnitMana("pet")
    local max = API and API.GetUnitMaxPower and API.GetUnitMaxPower("pet") or UnitManaMax("pet")
    return max > 0 and (100 * power / max) or 0
end

-- 新增函数，获取宠物的集中值 by 武藤纯子酱 2025.12.11
function CleveRoids.GetCachedPetPower()
    local API = CleveRoids.NampowerAPI
    return API and API.GetUnitPower and API.GetUnitPower("pet") or UnitMana("pet")
end

-- 新增函数，直接调用其他函数，并以函数运行结果作为条件进行判断 by 武藤纯子酱 2025.12.13
function CleveRoids.ExecuteConditionalFunction(funcCall)
    if type(funcCall) == "table" then
        -- Handle multi-comparison (e.g., >50&<80)
        if funcCall.comparisons and type(funcCall.comparisons) == "table" then
            -- ALL comparisons must pass (AND logic)
            for _, comp in ipairs(funcCall.comparisons) do
                if not CleveRoids.operators[comp.operator] then
                    return false
                end
                
                if not funcCall.name or funcCall.name == "" then
                    return false
                end
                -- 使用管道符 | 分割函数名和参数
                local parts = CleveRoids.splitString(funcCall.name, "|")
                if table.getn(parts) == 0 then
                    return false
                end
                
                local funcName = CleveRoids.Trim(parts[1])
                if funcName == "" then
                    return false
                end
                
                -- 收集参数
                local args = {}
                for i = 2, table.getn(parts) do
                    local arg = CleveRoids.Trim(parts[i])
                    if arg ~= "" then
                        -- 判断参数类型
                        local num = tonumber(arg)
                        if num then
                            table.insert(args, num)
                        elseif arg == "true" then
                            table.insert(args, true)
                        elseif arg == "false" then
                            table.insert(args, false)
                        elseif arg == "nil" then
                            table.insert(args, nil)
                        else
                            -- 字符串参数，去除可能的引号
                            if string.sub(arg, 1, 1) == '"' and string.sub(arg, -1) == '"' then
                                arg = string.sub(arg, 2, -2)
                            elseif string.sub(arg, 1, 1) == "'" and string.sub(arg, -1) == "'" then
                                arg = string.sub(arg, 2, -2)
                            end
                            table.insert(args, arg)
                        end
                    end
                end
                
                -- 查找函数（支持带前缀的函数名）
                local func = nil
                
                -- 检查是否有前缀（包含点号）
                if string.find(funcName, "%.") then
                    -- 带前缀的函数，如 "CleveRoids.GetTargetDeathTime"
                    -- 按点号分割
                    local pathParts = {}
                    for part in string.gfind(funcName, "([^%.]+)") do
                        table.insert(pathParts, part)
                    end
                    
                    if table.getn(pathParts) > 0 then
                        -- 从全局表开始查找
                        local current = _G[pathParts[1]]
                        for i = 2, table.getn(pathParts) do
                            if current and type(current) == "table" then
                                current = current[pathParts[i]]
                            else
                                current = nil
                                break
                            end
                        end
                        
                        if type(current) == "function" then
                            func = current
                        end
                    end
                else
                    -- 无前缀的函数，使用原来的查找逻辑
                    func = _G[funcName]                    
                    if type(func) ~= "function" then
                        -- 尝试在CleveRoids表中查找
                        if CleveRoids[funcName] and type(CleveRoids[funcName]) == "function" then
                            func = CleveRoids[funcName]
                        end
                    end
                end
                
                if type(func) ~= "function" then
                    if CleveRoids.debug then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SuperCleveRoidMacros]|r Function '%s' not found", funcName))
                    end
                    return false
                end
                
                -- 执行函数
                local success, result
                if table.getn(args) > 0 then
                    success, result = pcall(func, unpack(args))
                else
                    success, result = pcall(func)
                end
                if not success then
                    if CleveRoids.debug then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SuperCleveRoidMacros]|r Error executing function '%s': %s", funcName, result))
                    end
                    return false
                end
                -- 检查返回值：nil、false、0为假，其他为真
                if result == nil or result == false then
                    return false
                end
                
                -- 修复：比较量非数字（如 [func:x>abc] 解析出 amount=nil）时直接判失败，
                -- 避免 "attempt to compare number with nil" by 武藤纯子酱 2026.9.11
                if comp.amount == nil then
                    return false
                end
                if not CleveRoids.comparators[comp.operator](result, comp.amount) then
                    return false
                end
            end
            
            return true
        else
            -- 处理单个比较的情况...
            if not CleveRoids.operators[funcCall.operator] then
                return false
            end
            if not funcCall.name or funcCall.name == "" then
                return false
            end
            
            -- 使用管道符 | 分割函数名和参数
            local parts = CleveRoids.splitString(funcCall.name, "|")
            if table.getn(parts) == 0 then
                return false
            end
            
            local funcName = CleveRoids.Trim(parts[1])
            if funcName == "" then
                return false
            end
            
            -- 收集参数
            local args = {}
            for i = 2, table.getn(parts) do
                local arg = CleveRoids.Trim(parts[i])
                if arg ~= "" then
                    -- 判断参数类型
                    local num = tonumber(arg)
                    if num then
                        table.insert(args, num)
                    elseif arg == "true" then
                        table.insert(args, true)
                    elseif arg == "false" then
                        table.insert(args, false)
                    elseif arg == "nil" then
                        table.insert(args, nil)
                    else
                        -- 字符串参数，去除可能的引号
                        if string.sub(arg, 1, 1) == '"' and string.sub(arg, -1) == '"' then
                            arg = string.sub(arg, 2, -2)
                        elseif string.sub(arg, 1, 1) == "'" and string.sub(arg, -1) == "'" then
                            arg = string.sub(arg, 2, -2)
                        end
                        table.insert(args, arg)
                    end
                end
            end
            
            -- 查找函数（支持带前缀的函数名）
            local func = nil
            
            -- 检查是否有前缀（包含点号）
            if string.find(funcName, "%.") then
                -- 带前缀的函数，如 "CleveRoids.GetTargetDeathTime"
                -- 按点号分割
                local pathParts = {}
                for part in string.gfind(funcName, "([^%.]+)") do
                    table.insert(pathParts, part)
                end
                
                if table.getn(pathParts) > 0 then
                    -- 从全局表开始查找
                    local current = _G[pathParts[1]]
                    for i = 2, table.getn(pathParts) do
                        if current and type(current) == "table" then
                            current = current[pathParts[i]]
                        else
                            current = nil
                            break
                        end
                    end
                    
                    if type(current) == "function" then
                        func = current
                    end
                end
            else
                -- 无前缀的函数，使用原来的查找逻辑
                func = _G[funcName]
                if type(func) ~= "function" then
                    -- 尝试在CleveRoids表中查找
                    if CleveRoids[funcName] and type(CleveRoids[funcName]) == "function" then
                        func = CleveRoids[funcName]
                    end
                end
            end
            if type(func) ~= "function" then
                if CleveRoids.debug then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SuperCleveRoidMacros]|r Function '%s' not found", funcName))
                end
                return false
            end
            
            -- 执行函数
            local success, result
            if table.getn(args) > 0 then
                success, result = pcall(func, unpack(args))
            else
                success, result = pcall(func)
            end
            if not success then
                if CleveRoids.debug then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SuperCleveRoidMacros]|r Error executing function '%s': %s", funcName, result))
                end
                return false
            end
            
            -- 检查返回值：nil、false、0为假，其他为真
            if result == nil or result == false then
                return false
            end            
            
            -- 修复：比较量非数字时直接判失败，避免 "attempt to compare number with nil"
            -- by 武藤纯子酱 2026.9.11
            if funcCall.amount == nil then
                return false
            end
            if not CleveRoids.comparators[funcCall.operator](result, funcCall.amount) then
                return false
            end
                    
            return true
        end
    else
        -- 处理无比较的情况...
        if not funcCall or funcCall == "" then
            return false
        end
        
        -- 使用管道符 | 分割函数名和参数
        local parts = CleveRoids.splitString(funcCall, "|")
        if table.getn(parts) == 0 then
            return false
        end
        
        local funcName = CleveRoids.Trim(parts[1])
        if funcName == "" then
            return false
        end
        
        -- 收集参数
        local args = {}
        for i = 2, table.getn(parts) do
            local arg = CleveRoids.Trim(parts[i])
            if arg ~= "" then
                -- 判断参数类型
                local num = tonumber(arg)
                if num then
                    table.insert(args, num)
                elseif arg == "true" then
                    table.insert(args, true)
                elseif arg == "false" then
                    table.insert(args, false)
                elseif arg == "nil" then
                    table.insert(args, nil)
                else
                    -- 字符串参数，去除可能的引号
                    if string.sub(arg, 1, 1) == '"' and string.sub(arg, -1) == '"' then
                        arg = string.sub(arg, 2, -2)
                    elseif string.sub(arg, 1, 1) == "'" and string.sub(arg, -1) == "'" then
                        arg = string.sub(arg, 2, -2)
                    end
                    table.insert(args, arg)
                end
            end
        end
        
        -- 查找函数（支持带前缀的函数名）
        local func = nil
        
        -- 检查是否有前缀（包含点号）
        if string.find(funcName, "%.") then
            -- 带前缀的函数，如 "CleveRoids.GetTargetDeathTime"
            -- 按点号分割
            local pathParts = {}
            for part in string.gfind(funcName, "([^%.]+)") do
                table.insert(pathParts, part)
            end
            
            if table.getn(pathParts) > 0 then
                -- 从全局表开始查找
                local current = _G[pathParts[1]]
                for i = 2, table.getn(pathParts) do
                    if current and type(current) == "table" then
                        current = current[pathParts[i]]
                    else
                        current = nil
                        break
                    end
                end
                
                if type(current) == "function" then
                    func = current
                end
            end
        else
            -- 无前缀的函数，使用原来的查找逻辑
            func = _G[funcName]
            if type(func) ~= "function" then
                -- 尝试在CleveRoids表中查找
                if CleveRoids[funcName] and type(CleveRoids[funcName]) == "function" then
                    func = CleveRoids[funcName]
                end
            end
        end
        
        if type(func) ~= "function" then
            if CleveRoids.debug then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SuperCleveRoidMacros]|r Function '%s' not found", funcName))
            end
            return false
        end
        
        -- 执行函数
        local success, result
        if table.getn(args) > 0 then
            success, result = pcall(func, unpack(args))
        else
            success, result = pcall(func)
        end
        if not success then
            if CleveRoids.debug then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cffff0000[SuperCleveRoidMacros]|r Error executing function '%s': %s", funcName, result))
            end
            return false
        end
        
        -- 检查返回值：nil、false、0为假，其他为真
        if result == nil or result == false or result == 0 then
            return false
        end
        
        return true
    end
end

-- 新增辅助函数：从动作字符串中获取 spellID by 武藤纯子酱 2026.5.15
local function GetSpellIDFromAction(action)
    if not action then return nil end
    -- 直接尝试将动作作为技能名获取 spellID
    local spellID = nil
    if GetSpellIdForName then
        spellID = GetSpellIdForName(action)
    end
    -- 如果失败，尝试用 CleveRoids 的 spell 缓存
    if not spellID then
        local spell = CleveRoids.GetSpell(action)
        if spell and spell.id then
            spellID = spell.id
        end
    elseif spellID == 0 then
        return nil
    end
    return spellID
end

-- 性能优化：团队/小队距离内人数扫描缓存（TTL 0.1s） by 武藤纯子酱 2026.8.31
-- 40 人团单次扫描 = 40×(UnitExists+UnitIsDeadOrGhost→GetUnitHealth+UnitXP inSight+distanceBetween)；
-- 多重比较（>5&<100）原实现会把整段扫描按比较数重复跑。同 0.1s 窗口内同参数直接复用。
-- 语义：在团队/有小队时 = 1（自己）+ 范围内存活可见成员；不在团队/无小队 = 0（与各单比较分支一致）
local _groupRangeCountCache = {}
function CleveRoids.GetGroupRangeCount(groupType, distance)
    local key = groupType .. ":" .. tostring(distance)
    local nowG = GetTime()
    local cached = _groupRangeCountCache[key]
    if cached and (nowG - cached.t) < 0.1 then
        return cached.count
    end

    local count = 0
    if groupType == "raid" then
        if UnitInRaid("player") then
            count = 1
            for i = 1, GetNumRaidMembers() do
                if not UnitIsUnit("raid"..i, "player") and UnitExists("raid"..i) and not UnitIsDeadOrGhost("raid"..i) and CleveRoids.SafeUnitXP("inSight", "player", "raid"..i) and CleveRoids.SafeUnitXP("distanceBetween", "player", "raid"..i) <= distance then
                    count = count + 1
                end
            end
        end
    else
        if GetNumPartyMembers() > 0 then
            count = 1
            for i = 1, GetNumPartyMembers() do
                if UnitExists("party"..i) and not UnitIsDeadOrGhost("party"..i) and CleveRoids.SafeUnitXP("inSight", "player", "party"..i) and CleveRoids.SafeUnitXP("distanceBetween", "player", "party"..i) <= distance then
                    count = count + 1
                end
            end
        end
    end

    if not cached then
        cached = {}
        _groupRangeCountCache[key] = cached
    end
    cached.t = nowG
    cached.count = count
    return count
end

-- 性能优化：受伤成员计数扫描缓存（TTL 0.1s） by 武藤纯子酱 2026.8.31
-- 键含 operator/hpThreshold/distance（woundednum 的伤害比较符与距离过滤都来自宏参数）。
-- 语义与原实现逐条一致：party 前缀额外统计玩家自己；raid 前缀不统计自己；distance 为 nil 时不做距离过滤
local _woundedCountCache = {}
function CleveRoids.GetWoundedCount(groupType, operator, hpThreshold, distance)
    local key = groupType .. ":" .. tostring(operator) .. ":" .. tostring(hpThreshold) .. ":" .. tostring(distance)
    local nowW = GetTime()
    local cached = _woundedCountCache[key]
    if cached and (nowW - cached.t) < 0.1 then
        return cached.count
    end

    local unitPrefix = (groupType == "raid") and "raid" or "party"
    local maxMembers = (groupType == "raid") and GetNumRaidMembers() or GetNumPartyMembers()
    local comparator = CleveRoids.comparators and CleveRoids.comparators[operator]
    local count = 0

    for i = 1, maxMembers do
        local unit = unitPrefix .. i
        if UnitExists(unit) and not UnitIsDeadOrGhost(unit) then
            local hpLost = UnitHealthMax(unit) - CleveRoids.NampowerAPI.GetUnitHealth(unit)
            if comparator and comparator(hpLost, hpThreshold) then
                if distance then
                    local testdst = CleveRoids.SafeUnitXP("distanceBetween", "player", CleveRoids.GetGUID(unit))
                    if testdst and testdst < distance then
                        count = count + 1
                    end
                else
                    count = count + 1
                end
            end
        end
    end

    if unitPrefix == "party" and not UnitIsDeadOrGhost("player") then
        local hpLost = UnitHealthMax("player") - CleveRoids.NampowerAPI.GetUnitHealth("player")
        if comparator and comparator(hpLost, hpThreshold) then
            count = count + 1
        end
    end

    if not cached then
        cached = {}
        _woundedCountCache[key] = cached
    end
    cached.t = nowW
    cached.count = count
    return count
end

-- A list of Conditionals and their functions to validate them
-- ============================================================================
-- 实时施法/引导时间与攻速的独立条件（getcast/getchannel/getmh/getoh/getranged）
-- by 武藤纯子酱 2026.9.1
-- 语法：[getmh:>2.5]、[getcast:火球术>3]、[getchannel:奥术飞弹<"getcast(火球术)"]
--   省略技能名时默认当前宏动作技能（conditionals.action，如 [getcast:>3]）
--   公式量必须用 "..." 包裹（如 end<"getchannel(奥术飞弹)/6"），经比较器包装层求值
--   数据走 Nampower 实时 API 主路径，0.1s TTL 实时值
-- ============================================================================
-- 性能优化：原每次求值都新建 (arg) 闭包；改为模块级回调 + 上下文（save/restore 保证可重入）
-- by 武藤纯子酱 2026.9.11
local _cmpCtx = { kind = nil, conditionals = nil }
local function _compareArgEval(arg)
    local kind = _cmpCtx.kind
    local conditionals = _cmpCtx.conditionals
    if type(arg) ~= "table" then return false end  -- 裸引用（无比较符）无意义

    local current
    if kind == "getcast" or kind == "getchannel" then
        local spellName = arg.name
        if not spellName or spellName == "" then
            spellName = conditionals.action  -- 默认当前宏动作技能
        end
        if not spellName or spellName == "" then return false end
        current = CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetEffectiveSpellCastTime
            and CleveRoids.NampowerAPI.GetEffectiveSpellCastTime(spellName, kind)
    else
        current = CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetEffectiveAttackSpeed
            and CleveRoids.NampowerAPI.GetEffectiveAttackSpeed(kind)
    end
    if not current then return false end

    -- 多比较
    if arg.comparisons and type(arg.comparisons) == "table" then
        for _, comp in ipairs(arg.comparisons) do
            if not CleveRoids.operators[comp.operator] or comp.amount == nil then return false end
            if not CleveRoids.comparators[comp.operator](current, comp.amount) then return false end
        end
        return true
    end

    -- 单一比较（数值位支持公式）
    local op = arg.operator
    if not op or not CleveRoids.operators[op] then return false end
    local amt = arg.amount
    if type(amt) == "string" and not (CleveRoids.IsSpellTimeFormula and CleveRoids.IsSpellTimeFormula(amt)) then
        return false
    end
    return CleveRoids.comparators[op](current, amt)
end

local function MakeCompareCondition(kind)
    return function(conditionals)
        local savedKind, savedConds = _cmpCtx.kind, _cmpCtx.conditionals
        _cmpCtx.kind = kind
        _cmpCtx.conditionals = conditionals
        local r = Multi(conditionals[kind], _compareArgEval, conditionals, kind)
        _cmpCtx.kind, _cmpCtx.conditionals = savedKind, savedConds
        return r
    end
end

CleveRoids.Keywords = {
    -- 实时施法/引导时间与攻速比较（独立条件，0.1s TTL 实时值）by 武藤纯子酱 2026.9.1
    getcast = MakeCompareCondition("getcast"),
    getchannel = MakeCompareCondition("getchannel"),
    getmh = MakeCompareCondition("getmh"),
    getoh = MakeCompareCondition("getoh"),
    getranged = MakeCompareCondition("getranged"),

    exists = function(conditionals)
        -- target 为 nil（宏不带 @token）时按当前目标处理，防 UnitXXX(nil) 引擎报错 by 武藤纯子酱 2026.9.9
        return UnitExists(conditionals.target or "target")
    end,

    noexists = function(conditionals)
        return not UnitExists(conditionals.target or "target")
    end,
    
    -- Check if player has NO current target (target frame is empty)
    -- Different from noexists: notarget checks player's target, noexists checks @unit
    -- Usage: /target [notarget,@mouseover] - target mouseover only if no current target
    notarget = function(conditionals)
        return not UnitExists("target")
    end,

    -- Check if player HAS a current target (target frame is occupied)
    -- Usage: /cast [hastarget] Spell - only cast if player has a target selected
    hastarget = function(conditionals)
        return UnitExists("target")
    end,

    help = function(conditionals)
        return conditionals.help and conditionals.target and UnitExists(conditionals.target or "target") and UnitCanAssist("player", conditionals.target)
    end,

    -- [nohelp] - Target is NOT friendly (cannot assist)
    nohelp = function(conditionals)
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            return true
        end
        return not UnitCanAssist("player", conditionals.target)
    end,

    harm = function(conditionals)
        return conditionals.harm and conditionals.target and UnitExists(conditionals.target or "target") and UnitCanAttack("player", conditionals.target)
    end,

    -- [noharm] - Target is NOT hostile (cannot attack)
    noharm = function(conditionals)
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            return true
        end
        return not UnitCanAttack("player", conditionals.target)
    end,

    stance = function(conditionals)
        local i = CleveRoids.GetCurrentShapeshiftIndex()
        -- 修复：原误读 conditionals.form（[stance] 裸写时值存在 .stance），导致裸写 [stance] 永不成立
        -- by 武藤纯子酱 2026.9.11
        if type(conditionals.stance) == "string" then -- 新增不带变形编号，只判断是否处于变形状态 by 武藤纯子酱 2026.1.11
            if i ~= 0 then
                return true
            else
                return false
            end
        end
        -- PERFORMANCE: Use specialized function to avoid closure allocation
        return OrEqualsNumber(conditionals.stance, i)
    end,

    nostance = function(conditionals)
        local i = CleveRoids.GetCurrentShapeshiftIndex()
        local forbiddenStances = conditionals.nostance
        if type(forbiddenStances) ~= "table" then
            return i == 0
        end
        -- PERFORMANCE: Use specialized function to avoid closure allocation
        return AndNotEqualsNumber(forbiddenStances, i)
    end,

    noform = function(conditionals)
        local i = CleveRoids.GetCurrentShapeshiftIndex()
        local forbiddenForms = conditionals.noform
        if type(forbiddenForms) ~= "table" then
            return i == 0
        end
        -- PERFORMANCE: Use specialized function to avoid closure allocation
        return AndNotEqualsNumber(forbiddenForms, i)
    end,

    form = function(conditionals)
        local i = CleveRoids.GetCurrentShapeshiftIndex()
        if type(conditionals.form) == "string" then -- 新增不带变形编号，只判断是否处于变形状态 by 武藤纯子酱 2026.1.11
            if i ~= 0 then
                return true
            else
                return false
            end
        end
        -- PERFORMANCE: Use specialized function to avoid closure allocation
        return OrEqualsNumber(conditionals.form, i)
    end,

    -- [actionbar:n] / [bar:n] — 当前动作条页判断（正式服语法）by 武藤纯子酱 2026.9.3
    -- 1.12 无 GetActionBarPage()（实测不存在），读 FrameXML 全局变量 CURRENT_ACTIONBAR_PAGE
    -- （SHIFT+1~6 切换页时由引擎更新，实测可用）；OR 多值/AND 分组沿用 form 的 OrEqualsNumber 模式
    actionbar = function(conditionals)
        local page = tonumber(_G.CURRENT_ACTIONBAR_PAGE)
        if not page then return false end
        return OrEqualsNumber(conditionals.actionbar, page)
    end,

    -- bar:n → actionbar:n 同义（正式服别名；值键不同，直接复用比较逻辑）by 武藤纯子酱 2026.9.3
    bar = function(conditionals)
        local page = tonumber(_G.CURRENT_ACTIONBAR_PAGE)
        if not page then return false end
        return OrEqualsNumber(conditionals.bar, page)
    end,

    -- [bonusbar] — 临时动作条显示中（潜行/德鲁伊形态/战士姿态/暗影形态）by 武藤纯子酱 2026.9.3
    -- 1.12 无 HasBonusActionBar()（实测不存在），读 BonusActionBarFrame:IsShown()（实测可用）
    bonusbar = function(conditionals)
        -- 裸写 [bonusbar]（BOOLEAN_CONDITIONALS 登记，值为 true）；[bonusbar:n] 值为参数表
        if type(conditionals.bonusbar) == "table" then
            -- [bonusbar:n]：1.12 临时条变体与形态/姿态序号一一对应 → 直接映射形态序号判断
            local i = CleveRoids.GetCurrentShapeshiftIndex()
            return OrEqualsNumber(conditionals.bonusbar, i)
        end
        if BonusActionBarFrame and BonusActionBarFrame.IsShown then
            return BonusActionBarFrame:IsShown() and true or false
        end
        return false
    end,

    nobonusbar = function(conditionals)
        if type(conditionals.nobonusbar) == "table" then
            local i = CleveRoids.GetCurrentShapeshiftIndex()
            return not OrEqualsNumber(conditionals.nobonusbar, i)
        end
        if BonusActionBarFrame and BonusActionBarFrame.IsShown then
            return not BonusActionBarFrame:IsShown() and true or false
        end
        return true
    end,

    mod = function(conditionals)
        if type(conditionals.mod) ~= "table" then
            return CleveRoids.kmods.mod()
        end
        return Multi(conditionals.mod, function(mod)
            if type(mod) ~= "string" then return false end -- 值误带比较符时解析成表，防 strlower(表) 崩溃 by 武藤纯子酱 2026.9.9
            mod = strlower(mod) -- 统一转换为小写 by 武藤纯子酱 2025.11.27
            local fn = CleveRoids.kmods[mod] -- 修复：非法修饰键（如 [mod:foo]）不再 nil() 报错 by 武藤纯子酱 2026.8.31
            if not fn then return false end
            return fn()
        end, conditionals, "mod")
    end,

    nomod = function(conditionals)
        if type(conditionals.nomod) ~= "table" then
            return CleveRoids.kmods.nomod()
        end
        return NegatedMulti(conditionals.nomod, function(mod)
            if type(mod) ~= "string" then return false end -- 同 mod 的表值防护 by 武藤纯子酱 2026.9.9
            mod = strlower(mod) -- 统一转换为小写 by 武藤纯子酱 2025.11.27
            local fn = CleveRoids.kmods[mod] -- 修复：非法修饰键不再 nil() 报错 by 武藤纯子酱 2026.8.31
            if not fn then return true end -- 修复：未知修饰键按严格取反处理（与 nokeydown 一致） by 武藤纯子酱 2026.9.12
            return not fn()
        end, conditionals, "nomod")
    end,

    -- [keydown:X] — true while key X is held (Nampower v2.41+ KEY_DOWN/KEY_UP events)
    -- [keydown] with no argument — true if any non-meta key is currently held
    keydown = function(conditionals)
        if type(conditionals.keydown) ~= "table" then
            for _, v in pairs(CleveRoids._keyState) do
                if v then return true end
            end
            return false
        end
        return Multi(conditionals.keydown, function(keyname)
            if type(keyname) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local code = CleveRoids.KEY_NAMES[string.lower(keyname)]
            if not code then return false end
            return CleveRoids._keyState[code] == true
        end, conditionals, "keydown")
    end,

    nokeydown = function(conditionals)
        if type(conditionals.nokeydown) ~= "table" then
            for _, v in pairs(CleveRoids._keyState) do
                if v then return false end
            end
            return true
        end
        return NegatedMulti(conditionals.nokeydown, function(keyname)
            if type(keyname) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local code = CleveRoids.KEY_NAMES[string.lower(keyname)]
            if not code then return true end
            return not (CleveRoids._keyState[code] == true)
        end, conditionals, "nokeydown")
    end,

    target = function(conditionals)
        return CleveRoids.IsValidTarget(conditionals.target, conditionals.help)
    end,

    combat = function(conditionals)
        -- Check if an argument like :target or :focus was provided. The parser turns this into a table.
        if type(conditionals.combat) == "table" then
            -- If so, run the check on the provided unit(s).
            return Multi(conditionals.combat, function(unit)
                unit = ResolveFocusUnit(unit)
                if not unit then return false end
                if UnitExists(unit) and UnitAffectingCombat(unit) and UnitExists(conditionals.target or "target") then -- 如果有条件单位，则需要同时判断测试目标和条件单位是否都进入战斗 by 武藤纯子酱 2025.11.27
                    return UnitAffectingCombat(conditionals.target)
                else
                    return UnitExists(unit) and UnitAffectingCombat(unit)
                end
            end, conditionals, "combat")
        else
            -- Otherwise, this is a bare [combat]. The value might be 'true' or a spell name.
            -- PERFORMANCE: Use event-driven cache for player combat state
            local cached = CleveRoids._cachedPlayerInCombat
            if cached ~= nil then
                if UnitExists(conditionals.target or "target") then -- 如果有条件单位，则需要同时判断玩家和条件单位是否都进入战斗 by 武藤纯子酱 2025.11.27
                    return ( cached or UnitAffectingCombat("player") ) and UnitAffectingCombat(conditionals.target)
                else
                    return cached or UnitAffectingCombat("player")
                end
            end
            -- Fallback if cache not yet initialized
            if UnitAffectingCombat("player") and UnitExists(conditionals.target or "target") then -- 如果有条件单位，则需要同时判断玩家和条件单位是否都进入战斗 by 武藤纯子酱 2025.11.27
                return UnitAffectingCombat(conditionals.target)
            else
                return UnitAffectingCombat("player")
            end
        end
    end,

    nocombat = function(conditionals)
        -- Check if an argument like :target or :focus was provided.
        if type(conditionals.nocombat) == "table" then
            -- If so, run the check on the provided unit(s).
            return NegatedMulti(conditionals.nocombat, function(unit)
                unit = ResolveFocusUnit(unit)
                if not unit or not UnitExists(unit) then
                    return true
                end
                return not UnitAffectingCombat(unit)
            end, conditionals, "nocombat")
        else
            -- Otherwise, this is a bare [nocombat]. Default to checking the player.
            -- PERFORMANCE: Use event-driven cache for player combat state
            local cached = CleveRoids._cachedPlayerInCombat
            if cached ~= nil then
                return not cached or not UnitAffectingCombat("player") -- 优化，需要同时判断玩家没有被禁止回复及没有仇恨 by 武藤纯子酱 2026.2.4
            end
            -- Fallback if cache not yet initialized
            return not UnitAffectingCombat("player")
        end
    end,

    stealth = function(conditionals)
        return (
            (CleveRoids.playerClass == "ROGUE" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Stealth"]))
            or (CleveRoids.playerClass == "DRUID" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Prowl"]))
        )
    end,

    nostealth = function(conditionals)
        -- 修复：非盗贼/德鲁伊职业两个操作数都为 false → [nostealth] 恒 false；
        -- 正确语义是"未处于潜行/猎豹形态潜行"，对其他职业应恒为 true by 武藤纯子酱 2026.8.31
        return not (
            (CleveRoids.playerClass == "ROGUE" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Stealth"]))
            or (CleveRoids.playerClass == "DRUID" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Prowl"]))
        )
    end,

    casting = function(conditionals)
        if type(conditionals.casting) ~= "table" then return CleveRoids.CheckSpellCast(conditionals.target, "") end
        return Or(conditionals.casting, function (spell)
            return CleveRoids.CheckSpellCast(conditionals.target, spell)
        end)
    end,

    nocasting = function(conditionals)
        if type(conditionals.nocasting) ~= "table" then return not CleveRoids.CheckSpellCast(conditionals.target, "") end
        return NegatedMulti(conditionals.nocasting, function (spell)
            return not CleveRoids.CheckSpellCast(conditionals.target, spell)
        end, conditionals, "nocasting")
    end,

    -- NEW: Direct player casting check with time-based prediction
    -- Uses our accurate state tracking instead of GetCurrentCastingInfo polling
    selfcasting = function(conditionals)
        -- Check for cast with time-based prediction
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local remaining = CleveRoids.castDuration - (GetTime() - CleveRoids.castStartTime)
            if remaining <= 0.1 then
                return false -- Cast is done
            end
        end

        -- Check for channel with time-based prediction
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then
                return false -- Channel is done
            end
        end

        return CleveRoids.CurrentSpell.type == "cast" or CleveRoids.CurrentSpell.type == "channeled"
    end,

    noselfcasting = function(conditionals)
        -- Inverse of selfcasting with same prediction logic
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local remaining = CleveRoids.castDuration - (GetTime() - CleveRoids.castStartTime)
            if remaining <= 0.1 then
                return true -- Cast is done
            end
        end

        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then
                return true -- Channel is done
            end
        end

        return CleveRoids.CurrentSpell.type ~= "cast" and CleveRoids.CurrentSpell.type ~= "channeled"
    end,

    zone = function(conditionals)
        local zone = GetRealZoneText()
        local sub_zone = GetSubZoneText()
        return Multi(conditionals.zone, function (v) -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
            return ((sub_zone ~= "" and v == sub_zone) or v == zone) -- 修复 by 武藤纯子酱 2025.12.1
        end, conditionals, "zone") -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
    end,

    nozone = function(conditionals)
        local zone = GetRealZoneText()
        local sub_zone = GetSubZoneText()
        return NegatedMulti(conditionals.nozone, function (v) -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
            return not ((sub_zone ~= "" and v == sub_zone) or v == zone) -- 修复 by 武藤纯子酱 2025.12.1
        end, conditionals, "nozone") -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
    end,

    equipped = function(conditionals)
        -- PERFORMANCE: Or()/And() handle non-table values natively, so pass strings directly
        -- instead of wrapping in a temporary table (avoids allocation per evaluation)
        local itemsToCheck

        -- Case 1: conditionals.equipped is a string (e.g., [equipped]ItemName)
        if type(conditionals.equipped) == "string" then
            itemsToCheck = conditionals.equipped
        -- Case 2: conditionals.equipped is a table (e.g., [equipped:Shields])
        elseif type(conditionals.equipped) == "table" and table.getn(conditionals.equipped) > 0 then
            itemsToCheck = conditionals.equipped
        -- Case 3: No value provided, check the action
        elseif conditionals.action then
            itemsToCheck = conditionals.action
        else
            return false
        end

        -- Check all items
        return Multi(itemsToCheck, function(v) -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
            return (CleveRoids.HasWeaponEquipped(v) or CleveRoids.HasGearEquipped(v))
        end, conditionals, "equipped") -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
    end,

    noequipped = function(conditionals)
        -- PERFORMANCE: Or()/And() handle non-table values natively, so pass strings directly
        -- instead of wrapping in a temporary table (avoids allocation per evaluation)
        local itemsToCheck

        -- Case 1: conditionals.noequipped is a string (e.g., [noequipped]ItemName)
        if type(conditionals.noequipped) == "string" then
            itemsToCheck = conditionals.noequipped
        -- Case 2: conditionals.noequipped is a table (e.g., [noequipped:Shields])
        elseif type(conditionals.noequipped) == "table" and table.getn(conditionals.noequipped) > 0 then
            itemsToCheck = conditionals.noequipped
        -- Case 3: No value provided, check the action
        elseif conditionals.action then
            itemsToCheck = conditionals.action
        else
            return false
        end

        -- Check all items - ALL must be NOT equipped for this to pass
        return NegatedMulti(itemsToCheck, function(v) -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
            return not (CleveRoids.HasWeaponEquipped(v) or CleveRoids.HasGearEquipped(v))
        end, conditionals, "noequipped") -- 新增同时支持/和& by 武藤纯子酱 2025.12.17
    end,

    -- [set:SetName>=N] — true if equipped piece count of named set meets comparison
    -- [set:SetName] — true if any pieces of that set are equipped (count > 0)
    -- [set:123>=3] — numeric IDs also supported (Nampower only, no Reliquary needed)
    -- Name lookup requires Reliquary (for DBC set name); ID lookup requires Nampower
    set = function(conditionals)
        return Multi(conditionals.set, function(args)
            if type(args) == "table" and args.operator and args.amount then
                -- Comparison mode: [set:Judgement_Battlegear>=3]
                local count = CleveRoids.GetEquippedSetPieceCount(args.name)
                if CleveRoids.operators[args.operator] then
                    return CleveRoids.comparators[args.operator](count, args.amount)
                end
                return false
            elseif type(args) == "table" and args.comparisons then
                -- Multi-comparison: [set:Judgement_Battlegear>=3&<8]
                local count = CleveRoids.GetEquippedSetPieceCount(args.name)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return false end
                    if not CleveRoids.comparators[comp.operator](count, comp.amount) then
                        return false
                    end
                end
                return true
            elseif type(args) == "string" then
                -- Existence mode: [set:Judgement_Battlegear] — any pieces equipped
                local count = CleveRoids.GetEquippedSetPieceCount(args)
                return count > 0
            end
            return false
        end, conditionals, "set")
    end,

    -- [noset:SetName] — true if NO pieces of that set are equipped
    -- [noset:SetName>=3] — true if count does NOT meet comparison (negated)
    noset = function(conditionals)
        return NegatedMulti(conditionals.noset, function(args)
            if type(args) == "table" and args.operator and args.amount then
                local count = CleveRoids.GetEquippedSetPieceCount(args.name)
                if CleveRoids.operators[args.operator] then
                    return not CleveRoids.comparators[args.operator](count, args.amount)
                end
                return true
            elseif type(args) == "table" and args.comparisons then
                local count = CleveRoids.GetEquippedSetPieceCount(args.name)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return true end
                    if not CleveRoids.comparators[comp.operator](count, comp.amount) then
                        return true
                    end
                end
                return false
            elseif type(args) == "string" then
                local count = CleveRoids.GetEquippedSetPieceCount(args)
                return count == 0
            end
            return true
        end, conditionals, "noset")
    end,

    -- [inbag:Item] — true if item exists in bags or equipped
    -- [inbag:Item<12] — true if bag count of Item is less than 12
    -- Supports multi-value: [inbag:Item1/Item2 inbag:Item3] = (Item1 OR Item2) AND Item3
    inbag = function(conditionals)
        return Multi(conditionals.inbag, function(v)
            if type(v) == "table" and v.operator and v.amount then
                local count = CleveRoids.GetLiveItemCount(v.name)
                local cmp = CleveRoids.comparators[v.operator]
                if not cmp then return false end
                return cmp(count, v.amount)
            end
            return CleveRoids.HasItem(v)
        end, conditionals, "inbag")
    end,

    -- [noinbag:Item] — true if item is NOT in bags or equipped
    -- [noinbag:Item<12] — true if bag count of Item is NOT less than 12 (i.e. >= 12)
    -- [noinbag:X/Y] = X not in bags AND Y not in bags (De Morgan's)
    noinbag = function(conditionals)
        return NegatedMulti(conditionals.noinbag, function(v)
            if type(v) == "table" and v.operator and v.amount then
                local count = CleveRoids.GetLiveItemCount(v.name)
                local cmp = CleveRoids.comparators[v.operator]
                if not cmp then return true end
                return not cmp(count, v.amount)
            end
            return not CleveRoids.HasItem(v)
        end, conditionals, "noinbag")
    end,

    dead = function(conditionals)
        if not conditionals.target then return false end
        return CleveRoids.IsUnitDeadOrGhost(conditionals.target)
    end,

    alive = function(conditionals)
        if not conditionals.target then return false end
        return not CleveRoids.IsUnitDeadOrGhost(conditionals.target)
    end,

    noalive = function(conditionals)
        if not conditionals.target then return false end
        return CleveRoids.IsUnitDeadOrGhost(conditionals.target)
    end,

    nodead = function(conditionals)
        if not conditionals.target then return false end
        return not CleveRoids.IsUnitDeadOrGhost(conditionals.target)
    end,

    reactive = function(conditionals)
        return Multi(conditionals.reactive, function (v)
            return CleveRoids.IsReactiveUsable(v)
        end, conditionals, "reactive")
    end,

    noreactive = function(conditionals)
        return NegatedMulti(conditionals.noreactive, function (v)
            return not CleveRoids.IsReactiveUsable(v)
        end, conditionals, "noreactive")
    end,

    usable = function(conditionals)
        return Multi(conditionals.usable, function(name)
            -- If checking a reactive spell, use reactive logic
            if CleveRoids.reactiveSpells[name] then
                return CleveRoids.IsReactiveUsable(name)
            end

            -- Check if it's a spell first
            local spell = CleveRoids.GetSpell(name)
            if spell then
                return CleveRoids.CheckSpellUsable(name)
            end

            -- Not a spell - check if it's an item or slot number
            local itemName = name
            local slotNum = tonumber(name)
            if slotNum and slotNum >= 1 and slotNum <= 19 then
                -- Resolve slot number to item name
                local link = GetInventoryItemLink("player", slotNum)
                if link then
                    local _, _, extractedName = string.find(link, "%[(.+)%]")
                    if extractedName then
                        itemName = extractedName
                    end
                end
            end

            -- Check if item exists in bags/equipped first
            if not CleveRoids.HasItem(itemName) then
                return false
            end

            -- Check item cooldown (0 remaining = usable)
            local remaining = CleveRoids.GetItemCooldown(itemName)
            return remaining == 0
        end, conditionals, "usable")
    end,

    nousable = function(conditionals)
        return NegatedMulti(conditionals.nousable, function(name)
            -- If checking a reactive spell, use reactive logic
            if CleveRoids.reactiveSpells[name] then
                return not CleveRoids.IsReactiveUsable(name)
            end

            -- Check if it's a spell first
            local spell = CleveRoids.GetSpell(name)
            if spell then
                return not CleveRoids.CheckSpellUsable(name)
            end

            -- Not a spell - check if it's an item or slot number
            local itemName = name
            local slotNum = tonumber(name)
            if slotNum and slotNum >= 1 and slotNum <= 19 then
                -- Resolve slot number to item name
                local link = GetInventoryItemLink("player", slotNum)
                if link then
                    local _, _, extractedName = string.find(link, "%[(.+)%]")
                    if extractedName then
                        itemName = extractedName
                    end
                end
            end

            -- Item not existing counts as "not usable"
            if not CleveRoids.HasItem(itemName) then
                return true
            end

            -- Check item cooldown (>0 remaining = not usable)
            local remaining = CleveRoids.GetItemCooldown(itemName)
            return remaining > 0
        end, conditionals, "nousable")
    end,

    member = function(conditionals)
        return Or(conditionals.member, function(v)
            return
                CleveRoids.IsTargetInGroupType(conditionals.target, "party")
                or CleveRoids.IsTargetInGroupType(conditionals.target, "raid")
        end)
    end,

    -- [nomember] - check if target is NOT in party or raid
    nomember = function(conditionals)
        return not (
            CleveRoids.IsTargetInGroupType(conditionals.target, "party")
            or CleveRoids.IsTargetInGroupType(conditionals.target, "raid")
        )
    end,

    -- [party] or [party:unitid] - check if unit is in your party
    -- Default unit is conditionals.target
    party = function(conditionals)
        local unit = conditionals.party
        -- 修复：带参形式 [party:party1] 解析器存成表 {"party1"}，需解包首个元素 by 武藤纯子酱 2026.8.31
        if type(unit) == "table" then unit = unit[1] end
        if unit == true or unit == nil then
            unit = conditionals.target
        end
        return CleveRoids.IsTargetInGroupType(unit, "party")
    end,

    -- [noparty] or [noparty:unitid] - check if unit is NOT in your party
    noparty = function(conditionals)
        local unit = conditionals.noparty
        if type(unit) == "table" then unit = unit[1] end
        if unit == true or unit == nil then
            unit = conditionals.target
        end
        return not CleveRoids.IsTargetInGroupType(unit, "party")
    end,

    -- [raid] or [raid:unitid] - check if unit is in your raid
    -- Default unit is conditionals.target
    raid = function(conditionals)
        local unit = conditionals.raid
        if type(unit) == "table" then unit = unit[1] end
        if unit == true or unit == nil then
            unit = conditionals.target
        end
        return CleveRoids.IsTargetInGroupType(unit, "raid")
    end,

    -- [noraid] or [noraid:unitid] - check if unit is NOT in your raid
    noraid = function(conditionals)
        local unit = conditionals.noraid
        if type(unit) == "table" then unit = unit[1] end
        if unit == true or unit == nil then
            unit = conditionals.target
        end
        return not CleveRoids.IsTargetInGroupType(unit, "raid")
    end,

    -- [tag] - target is tapped (tagged) by anyone
    tag = function(conditionals)
        return conditionals.target and UnitIsTapped(conditionals.target)
    end,

    -- [notag] - target is not tapped
    notag = function(conditionals)
        return conditionals.target and not UnitIsTapped(conditionals.target)
    end,

    -- [mytag] - target is tapped by the player
    mytag = function(conditionals)
        return conditionals.target and UnitIsTappedByPlayer(conditionals.target)
    end,

    -- [nomytag] - target is not tapped by the player
    nomytag = function(conditionals)
        return conditionals.target and not UnitIsTappedByPlayer(conditionals.target)
    end,

    -- [othertag] - target is tapped by someone else (not the player)
    othertag = function(conditionals)
        return conditionals.target and UnitIsTapped(conditionals.target) and not UnitIsTappedByPlayer(conditionals.target)
    end,

    -- [noothertag] - target is not tapped by someone else (not tapped, or tapped by player)
    noothertag = function(conditionals)
        return conditionals.target and (not UnitIsTapped(conditionals.target) or UnitIsTappedByPlayer(conditionals.target))
    end,

    -- [group] or [group:party] or [group:raid] or [group:party/raid]
    -- Checks if the PLAYER is in a group (not unit membership)
    group = function(conditionals)
        local groupVal = conditionals.group
        -- Boolean form [group] - check if in any group
        if groupVal == true then
            return GetNumPartyMembers() > 0 or GetNumRaidMembers() > 0
        end
        -- Value form [group:party] or [group:raid] or [group:party/raid]
        return Multi(groupVal, function(groupType)
            if not groupType or type(groupType) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local groupType = strlower(groupType) -- 统一转换为小写 by 武藤纯子酱 2025.11.27
            if groupType == "party" then
                return GetNumPartyMembers() > 0
            elseif groupType == "raid" then
                return GetNumRaidMembers() > 0
            end
            return false
        end, conditionals, "group")
    end,

    -- [nogroup] or [nogroup:party] or [nogroup:raid] or [nogroup:party/raid]
    -- Checks if the PLAYER is NOT in a group
    nogroup = function(conditionals)
        local groupVal = conditionals.nogroup
        -- Boolean form [nogroup] - check if not in any group
        if groupVal == true then
            return GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0
        end
        -- Value form with De Morgan's law via NegatedMulti
        return NegatedMulti(groupVal, function(groupType)
            if not groupType or type(groupType) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local groupType = strlower(groupType) -- 统一转换为小写 by 武藤纯子酱 2025.11.27
            if groupType == "party" then
                return GetNumPartyMembers() == 0
            elseif groupType == "raid" then
                return GetNumRaidMembers() == 0
            end
            return true
        end, conditionals, "nogroup")
    end,

    checkchanneled = function(conditionals)
        if conditionals.checkchanneled == true then
            -- Boolean form [checkchanneled] - check if NOT channeling anything
            return CleveRoids.CheckChanneled(nil)
        else
            -- String form [checkchanneled:SpellName] - check if NOT channeling that spell
            -- 修复：与 [nochanneling:X] 同源——读条中/已排队时视为"不可引导"（CheckChanneled
            -- 是被 [channeling:X] 取反共享的函数，不能在里面加，只能在 wrapper 层拦）by 武藤纯子酱 2026.9.9
            return Multi(conditionals.checkchanneled, function(channeledSpells)
                if CleveRoids.CurrentSpell.type == "cast" or CleveRoids.queuedSpell or CleveRoids._castIssuedThisFrame then
                    return false
                end
                return CleveRoids.CheckChanneled(channeledSpells)
            end, conditionals, "checkchanneled")
        end
    end,
    
    checkcasting = function(conditionals)
        if conditionals.checkcasting == true then
            -- Boolean form [checkcasting] - check if NOT casting anything
            -- 修复：镜像同类 BUG——正在引导/已排队时同样视为"不可施放读条技"，
            -- 防止 [checkcasting] 在多行宏里把读条填充技排队、顶掉排队中的引导技 by 武藤纯子酱 2026.9.9
            if CleveRoids.CurrentSpell.type == "channeled" or CleveRoids.queuedSpell or CleveRoids._castIssuedThisFrame then
                return false
            end
            return CleveRoids.CheckCasting(nil)
        else
            -- String form [checkcasting:SpellName] - check if NOT casting that spell
            return Multi(conditionals.checkcasting, function(castingSpells)
                if CleveRoids.CurrentSpell.type == "channeled" or CleveRoids.queuedSpell or CleveRoids._castIssuedThisFrame then
                    return false
                end
                return CleveRoids.CheckCasting(castingSpells)
            end, conditionals, "checkcasting")
        end
    end,

    buff = function(conditionals)
        return Multi(conditionals.buff, function(v)
            return CleveRoids.ValidateUnitBuff(conditionals.target, v)
        end, conditionals, "buff")
    end,

    nobuff = function(conditionals)
        return NegatedMulti(conditionals.nobuff, function(v)
            -- 结果确认门（用户确认：给自己/队友上 buff 同样适用）——目标缺少该 buff 且
            -- 同名施法结果未确认时挂起判定（含读条中/已排队/结果未到达三种窗口）by 武藤纯子酱 2026.8.31
            local pendingName = type(v) == "table" and v.name or v
            if pendingName and CleveRoids.IsPendingDebuffCast(pendingName, conditionals.target) then
                return false
            end
            return not CleveRoids.ValidateUnitBuff(conditionals.target, v)
        end, conditionals, "nobuff")
    end,

    debuff = function(conditionals)
        return Multi(conditionals.debuff, function(v)
            return CleveRoids.ValidateUnitDebuff(conditionals.target, v)
        end, conditionals, "debuff")
    end,

    nodebuff = function(conditionals)
        return NegatedMulti(conditionals.nodebuff, function(v)
            -- Extract spell name from args (could be string or table with name/operator/amount)
            local spellName = type(v) == "table" and v.name or v

            -- Check if this debuff is PENDING (being cast or queued)
            -- This prevents double-application when spamming macros with spell queue
            if CleveRoids.IsPendingDebuffCast(spellName, conditionals.target) then
                return false  -- Treat as if debuff exists (nodebuff returns false)
            end

            -- Debuff not pending, check if it actually exists on target
            return not CleveRoids.ValidateUnitDebuff(conditionals.target, v)
        end, conditionals, "nodebuff")
    end,

    mybuff = function(conditionals)
        return Multi(conditionals.mybuff, function(v)
            return CleveRoids.ValidatePlayerBuff(v)
        end, conditionals, "mybuff")
    end,

    nomybuff = function(conditionals)
        return NegatedMulti(conditionals.nomybuff, function(v)
            -- 结果确认门：自身 buff（目标恒为 player）缺少且同名施法结果未确认时挂起 by 武藤纯子酱 2026.8.31
            local pendingName = type(v) == "table" and v.name or v
            if pendingName and CleveRoids.IsPendingDebuffCast(pendingName, "player") then
                return false
            end
            return not CleveRoids.ValidatePlayerBuff(v)
        end, conditionals, "nomybuff")
    end,

    mydebuff = function(conditionals)
        return Multi(conditionals.mydebuff, function(v)
            return CleveRoids.ValidatePlayerDebuff(v)
        end, conditionals, "mydebuff")
    end,

    nomydebuff = function(conditionals)
        return NegatedMulti(conditionals.nomydebuff, function(v)
            -- 结果确认门：自身 debuff（目标恒为 player）缺少且相关施法结果未确认时挂起 by 武藤纯子酱 2026.8.31
            local pendingName = type(v) == "table" and v.name or v
            if pendingName and CleveRoids.IsPendingDebuffCast(pendingName, "player") then
                return false
            end
            return not CleveRoids.ValidatePlayerDebuff(v)
        end, conditionals, "nomydebuff")
    end,

    power = function(conditionals)
        return Multi(conditionals.power, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                local unit = conditionals.target or "target"
                if not UnitExists(unit) then return false end
                local powerPercent = 100 / UnitManaMax(unit) * UnitMana(unit)

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](powerPercent, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidatePower(conditionals.target or "target", args.operator, args.amount)
        end, conditionals, "power")
    end,

    mypower = function(conditionals)
        return Multi(conditionals.mypower, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                -- PERFORMANCE: Use cached player power
                local powerPercent = CleveRoids.GetCachedPlayerPowerPercent()

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](powerPercent, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidatePower("player", args.operator, args.amount)
        end, conditionals, "mypower")
    end,

    rawpower = function(conditionals)
        return Multi(conditionals.rawpower, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >500&<1000)
            if args.comparisons and type(args.comparisons) == "table" then
                local unit = conditionals.target or "target"
                if not UnitExists(unit) then return false end
                local power = UnitMana(unit)

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](power, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateRawPower(conditionals.target or "target", args.operator, args.amount)
        end, conditionals, "rawpower")
    end,

    myrawpower = function(conditionals)
        return Multi(conditionals.myrawpower, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >500&<1000)
            if args.comparisons and type(args.comparisons) == "table" then
                -- PERFORMANCE: Use cached player power
                local power = CleveRoids.GetCachedPlayerPower()

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](power, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateRawPower("player", args.operator, args.amount)
        end, conditionals, "myrawpower")
    end,

    druidmana = function(conditionals)
        return Multi(conditionals.druidmana, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidateDruidRawMana("player", args.operator, args.amount)
        end, conditionals, "druidmana")
    end,

    powerlost = function(conditionals)
        return Multi(conditionals.powerlost, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidatePowerLost(conditionals.target, args.operator, args.amount)
        end, conditionals, "powerlost")
    end,

    mypowerlost = function(conditionals)
        return Multi(conditionals.mypowerlost, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidatePowerLost("player", args.operator, args.amount)
        end, conditionals, "mypowerlost")
    end,

    hp = function(conditionals)
        return Multi(conditionals.hp, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                local unit = conditionals.target or "target"
                if not UnitExists(unit) then return false end

                -- PERFORMANCE: Use cached health for target
                local hp
                if unit == "target" then
                    hp = CleveRoids.GetCachedTargetHealthPercent()
                else
                    local maxHp = UnitHealthMax(unit)
                    hp = maxHp > 0 and (100 * CleveRoids.NampowerAPI.GetUnitHealth(unit) / maxHp) or 0 -- 用CleveRoids.NampowerAPI.GetUnitHealth替代UnitHealth，识别假死等特殊情况 by 武藤纯子酱 2026.1.14
                end

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](hp, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateHp(conditionals.target or "target", args.operator, args.amount)
        end, conditionals, "hp")
    end,

    level = function(conditionals)
        return Multi(conditionals.level, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<60)
            if args.comparisons and type(args.comparisons) == "table" then
                local unit = conditionals.target or "target"
                if not UnitExists(unit) then return false end
                local level = UnitLevel(unit)

                -- Treat skull/boss mobs (??) as level 63
                if level == -1 then
                    level = 63
                end

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](level, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateLevel(conditionals.target or "target", args.operator, args.amount)
        end, conditionals, "level")
    end,

    mylevel = function(conditionals)
        return Multi(conditionals.mylevel, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<60)
            if args.comparisons and type(args.comparisons) == "table" then
                local level = UnitLevel("player")

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](level, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateLevel("player", args.operator, args.amount)
        end, conditionals, "mylevel")
    end,

    myhp = function(conditionals)
        return Multi(conditionals.myhp, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                -- PERFORMANCE: Use cached player health
                local hp = CleveRoids.GetCachedPlayerHealthPercent()

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](hp, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateHp("player", args.operator, args.amount)
        end, conditionals, "myhp")
    end,

    rawhp = function(conditionals)
        return Multi(conditionals.rawhp, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidateRawHp(conditionals.target or "target", args.operator, args.amount)
        end, conditionals, "rawhp")
    end,

    myrawhp = function(conditionals)
        return Multi(conditionals.myrawhp, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidateRawHp("player", args.operator, args.amount)
        end, conditionals, "myrawhp")
    end,

    hplost = function(conditionals)
        return Multi(conditionals.hplost, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidateHpLost(conditionals.target, args.operator, args.amount)
        end, conditionals, "hplost")
    end,

    myhplost = function(conditionals)
        return Multi(conditionals.myhplost, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidateHpLost("player", args.operator, args.amount)
        end, conditionals, "myhplost")
    end,

    type = function(conditionals)
        return Or(conditionals.type, function(unittype)
            return CleveRoids.ValidateCreatureType(unittype, conditionals.target)
        end)
    end,

    notype = function(conditionals)
        return NegatedMulti(conditionals.notype, function(unittype)
            return not CleveRoids.ValidateCreatureType(unittype, conditionals.target)
        end, conditionals, "notype")
    end,

    cooldown = function(conditionals)
        return Multi(conditionals.cooldown,function (v)
            return CleveRoids.ValidateCooldown(v, true)
        end, conditionals, "cooldown")
    end,

    nocooldown = function(conditionals)
        return NegatedMulti(conditionals.nocooldown,function (v)
            return not CleveRoids.ValidateCooldown(v, true)
        end, conditionals, "nocooldown")
    end,

    cdgcd = function(conditionals)
        return Multi(conditionals.cdgcd,function (v)
            return CleveRoids.ValidateCooldown(v, false)
        end, conditionals, "cdgcd")
    end,

    nocdgcd = function(conditionals)
        return NegatedMulti(conditionals.nocdgcd,function (v)
            return not CleveRoids.ValidateCooldown(v, false)
        end, conditionals, "nocdgcd")
    end,

    -- GCD conditional - check if GCD is active/remaining
    -- Usage: [gcd] - true if GCD is active
    --        [gcd:<1] - true if GCD has less than 1 second remaining
    --        [nogcd] - true if GCD is not active
    gcd = function(conditionals)
        return Multi(conditionals.gcd, function(args)
            -- Get GCD remaining in seconds
            local gcdRemaining = 0

            -- Try Nampower API first (handles GetCastInfo + GetSpellIdCooldown)
            if CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetGCDRemainingMs then
                local gcdMs = CleveRoids.NampowerAPI.GetGCDRemainingMs()
                if gcdMs and gcdMs > 0 then
                    gcdRemaining = gcdMs / 1000
                end
            end

            -- Fallback: scan spellbook for GCD cooldown (pre-v2.18 or if API returned 0)
            if gcdRemaining == 0 then
                for i = 1, 200 do
                    local spellName = GetSpellName(i, BOOKTYPE_SPELL)
                    if not spellName then break end
                    local start, duration = GetSpellCooldown(i, BOOKTYPE_SPELL)
                    if start and duration and duration > 0 and duration <= 1.5 then
                        gcdRemaining = (start + duration) - GetTime()
                        if gcdRemaining < 0 then gcdRemaining = 0 end
                        break
                    end
                end
            end

            -- No args or just [gcd] - check if GCD is active
            if not args or args == "" or (type(args) == "table" and not args.operator) then
                return gcdRemaining > 0
            end

            -- With operator: [gcd:<1] etc
            if type(args) == "table" and args.operator and args.amount then
                if CleveRoids.operators[args.operator] then
                    return CleveRoids.comparators[args.operator](gcdRemaining, args.amount)
                end
            end

            return gcdRemaining > 0
        end, conditionals, "gcd")
    end,

    nogcd = function(conditionals)
        return NegatedMulti(conditionals.nogcd, function(args)
            -- Get GCD remaining in seconds
            local gcdRemaining = 0

            -- Try Nampower API first (handles GetCastInfo + GetSpellIdCooldown)
            if CleveRoids.NampowerAPI and CleveRoids.NampowerAPI.GetGCDRemainingMs then
                local gcdMs = CleveRoids.NampowerAPI.GetGCDRemainingMs()
                if gcdMs and gcdMs > 0 then
                    gcdRemaining = gcdMs / 1000
                end
            end

            -- Fallback: scan spellbook for GCD cooldown (pre-v2.18 or if API returned 0)
            if gcdRemaining == 0 then
                for i = 1, 200 do
                    local spellName = GetSpellName(i, BOOKTYPE_SPELL)
                    if not spellName then break end
                    local start, duration = GetSpellCooldown(i, BOOKTYPE_SPELL)
                    if start and duration and duration > 0 and duration <= 1.5 then
                        gcdRemaining = (start + duration) - GetTime()
                        if gcdRemaining < 0 then gcdRemaining = 0 end
                        break
                    end
                end
            end

            -- [nogcd] - true if GCD is NOT active
            if not args or args == "" or (type(args) == "table" and not args.operator) then
                return gcdRemaining <= 0
            end

            -- With operator: [nogcd:<1] means NOT (gcd < 1), i.e., gcd >= 1
            if type(args) == "table" and args.operator and args.amount then
                if CleveRoids.operators[args.operator] then
                    return not CleveRoids.comparators[args.operator](gcdRemaining, args.amount)
                end
            end

            return gcdRemaining <= 0
        end, conditionals, "nogcd")
    end,

    channeled = function(conditionals)
        -- Use time-based prediction for accuracy
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then
                return false -- Channel is done
            end
        end
        return CleveRoids.CurrentSpell.type == "channeled"
    end,

    nochanneled = function(conditionals)
        -- Use time-based prediction for accuracy
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then
                return true -- Channel is done
            end
        end
        return CleveRoids.CurrentSpell.type ~= "channeled"
    end,
    
    selfchanneltime = function(conditionals) -- 为了避免冲突，将channeltime改为selfchanneltime by 武藤纯子酱 2026.1.2
        -- Calculate remaining time (0 if not channeling)
        local timeLeft = 0

        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local elapsed = GetTime() - CleveRoids.channelStartTime
            timeLeft = CleveRoids.channelDuration - elapsed
            -- Don't allow negative time
            if timeLeft < 0 then timeLeft = 0 end
        end

        local check = conditionals.selfchanneltime

        -- selfchanneltime is stored as an array by the parser, get the first element
        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end

        if type(check) == "table" and check.operator and check.amount then
            -- Now compare: if not channeling, timeLeft is 0, so [selfchanneltime:<0.5] returns true
            return CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end

        return false
    end,

    -- [nochanneltime] - Negated channel time comparison
    -- Usage: [nochanneltime:<0.5] = true if NOT (channeltime < 0.5), i.e., >= 0.5 seconds remaining
    noselfchanneltime = function(conditionals) -- 为了避免冲突，将channeltime改为selfchanneltime by 武藤纯子酱 2026.1.4
        -- Calculate remaining time (0 if not channeling)
        local timeLeft = 0

        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local elapsed = GetTime() - CleveRoids.channelStartTime
            timeLeft = CleveRoids.channelDuration - elapsed
            if timeLeft < 0 then timeLeft = 0 end
        end

        local check = conditionals.noselfchanneltime

        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end

        if type(check) == "table" and check.operator and check.amount then
            return not CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end

        return true
    end,
    
    selfcasttime = function(conditionals) -- 为了避免冲突，将casttime改为selfcasttime by 武藤纯子酱 2026.1.2
        -- Calculate remaining time (0 if not casting)
        local timeLeft = 0

        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local elapsed = GetTime() - CleveRoids.castStartTime
            timeLeft = CleveRoids.castDuration - elapsed
            -- Don't allow negative time
            if timeLeft < 0 then timeLeft = 0 end
        end

        local check = conditionals.selfcasttime

        -- selfcasttime is stored as an array by the parser, get the first element
        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end

        if type(check) == "table" and check.operator and check.amount then
            -- Now compare: if not casting, timeLeft is 0, so [selfcasttime:<0.5] returns true
            return CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end

        return false
    end,

    -- [nocasttime] - Negated cast time comparison
    -- Usage: [nocasttime:<0.5] = true if NOT (casttime < 0.5), i.e., >= 0.5 seconds remaining
    noselfcasttime = function(conditionals) -- 为了避免冲突，将casttime改为selfcasttime by 武藤纯子酱 2026.1.2
        -- Calculate remaining time (0 if not casting)
        local timeLeft = 0

        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local elapsed = GetTime() - CleveRoids.castStartTime
            timeLeft = CleveRoids.castDuration - elapsed
            if timeLeft < 0 then timeLeft = 0 end
        end

        local check = conditionals.noselfcasttime

        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end

        if type(check) == "table" and check.operator and check.amount then
            return not CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end

        return true
    end,

    -- [spellcasttime] - Check a spell's total cast time from tooltip (includes haste/talents)
    -- Usage: [spellcasttime:>2] - action's spell has cast time > 2 seconds
    --        [spellcasttime:Frostbolt>2] - specific spell has cast time > 2 seconds
    --        [spellcasttime:=0] - spell is instant cast
    spellcasttime = function(conditionals)
        local check = conditionals.spellcasttime

        -- Handle array format from parser
        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end

        if type(check) == "table" and check.operator and check.amount then
            -- Use spell name from conditional, or fall back to action's spell
            local spellName = check.name
            if not spellName or spellName == "" then
                spellName = conditionals.action
            end

            return CleveRoids.ValidateSpellCastTime(spellName, check.operator, check.amount)
        end

        return false
    end,

    -- [nospellcasttime] - Negated spell cast time check
    -- Usage: [nospellcasttime:>2] = true if NOT (cast time > 2), i.e., <= 2 seconds
    nospellcasttime = function(conditionals)
        local check = conditionals.nospellcasttime

        -- Handle array format from parser
        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end

        if type(check) == "table" and check.operator and check.amount then
            local spellName = check.name
            if not spellName or spellName == "" then
                spellName = conditionals.action
            end

            return not CleveRoids.ValidateSpellCastTime(spellName, check.operator, check.amount)
        end

        return true
    end,

    -- [targeting:unit] - Target is targeting specified unit
    -- [targeting:tank] - Target is targeting ANY player marked as tank in pfUI
    targeting = function(conditionals) -- 修复 by 武藤纯子酱 2025.12.8
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            return false
        end
        
        if not UnitExists(conditionals.target.."target") then
            return false
        end

        local target = conditionals.target or "target"

        -- Handle single "tank" keyword directly (most common case)
        local val = conditionals.targeting
        if val == "tank" or (type(val) == "table" and val[1] == "tank" and not val[2]) then
            return CleveRoids.IsTargetingAnyTank(target)
        end

        return Or(val, function (unit)
            if not unit or unit == conditionals.action then
                if UnitExists(conditionals.target.."target") then
                    return true
                else
                    return false
                end
            end

            if unit == "tank" then
                return CleveRoids.IsTargetingAnyTank(target)
            end
            return (UnitIsUnit(target .. "target", unit) == 1)
        end)
    end,

    -- [notargeting:unit] - Target is NOT targeting specified unit
    -- [notargeting:tank] - Target is NOT targeting ANY tank (loose mob!)
    notargeting = function(conditionals) -- 修复 by 武藤纯子酱 2025.12.8
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            -- 修复：严格取反——无目标时正向 targeting=false，notargeting 应为 true（与 nohelp/noharm 一致） by 武藤纯子酱 2026.9.12
            return true
        end
        
        if not UnitExists(conditionals.target.."target") then
            return true
        end

        local target = conditionals.target or "target"

        -- Handle single "tank" keyword directly (most common case)
        local val = conditionals.notargeting
        if val == "tank" or (type(val) == "table" and val[1] == "tank" and not val[2]) then
            return not CleveRoids.IsTargetingAnyTank(target)
        end

        return NegatedMulti(val, function (unit)
            if not unit or unit == conditionals.action then
                if UnitExists(conditionals.target.."target") then
                    return false
                else
                    return true
                end
            end

            if unit == "tank" then
                return not CleveRoids.IsTargetingAnyTank(target)
            end
            return UnitIsUnit(target .. "target", unit) ~= 1
        end, conditionals, "notargeting")
    end,

    isplayer = function(conditionals)
        -- target nil 兜底为当前目标 by 武藤纯子酱 2026.9.9
        return UnitIsPlayer(conditionals.target or "target")
    end,

    -- [noisplayer] - Target is NOT a player (same as isnpc)
    noisplayer = function(conditionals)
        return not UnitIsPlayer(conditionals.target or "target")
    end,

    isnpc = function(conditionals)
        return not UnitIsPlayer(conditionals.target or "target")
    end,

    -- [noisnpc] - Target is NOT an NPC (same as isplayer)
    noisnpc = function(conditionals)
        return UnitIsPlayer(conditionals.target or "target")
    end,

    -- [playercontrolled] - Target is controlled by a player (players, pets, mind controlled units)
    playercontrolled = function(conditionals)
        return UnitPlayerControlled(conditionals.target or "target")
    end,

    -- [noplayercontrolled] - Target is NOT controlled by a player (wild mobs, NPCs)
    noplayercontrolled = function(conditionals)
        return not UnitPlayerControlled(conditionals.target or "target")
    end,

    -- [istank] - Target unit is marked as tank in pfUI
    -- [istank:unit] - Specified unit is marked as tank
    istank = function(conditionals)
        if conditionals.istank and type(conditionals.istank) == "table" then
            -- Check specific unit: [istank:focus]
            return Or(conditionals.istank, function(unit)
                unit = ResolveFocusUnit(unit)
                if not unit then return false end
                local name = UnitName(unit)
                return CleveRoids.IsPlayerTank(name)
            end)
        end
        -- Check target: [istank]
        local target = conditionals.target or "target"
        local name = UnitName(target)
        return CleveRoids.IsPlayerTank(name)
    end,

    -- [noistank] - Target unit is NOT marked as tank in pfUI
    noistank = function(conditionals)
        if conditionals.noistank and type(conditionals.noistank) == "table" then
            -- Check specific unit: [noistank:focus]
            return NegatedMulti(conditionals.noistank, function(unit)
                unit = ResolveFocusUnit(unit)
                if not unit then return true end
                return not CleveRoids.IsPlayerTank(UnitName(unit))
            end, conditionals, "noistank")
        end
        -- Check target: [noistank]
        local target = conditionals.target or "target"
        local name = UnitName(target)
        return not CleveRoids.IsPlayerTank(name)
    end,

    -- [inrange] or [inrange:Spell] - Target is in range of spell
    -- [inrange:Spell>N] - More than N enemies are in range of spell (count mode)
    inrange = function(conditionals)
        if not IsSpellInRange then return end
        local API = CleveRoids.NampowerAPI
        return Multi(conditionals.inrange, function(args)
            -- Check for count mode: [inrange:Multi-Shot>1]
            if type(args) == "table" and args.operator and args.amount then
                local spellName = args.name or conditionals.action
                local spellId = API.GetSpellIdFromName(spellName)
                local spellRange = spellId and API.GetSpellRange(spellId)
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    if spellRange and spellRange > 0 and CleveRoids.hasUnitXP then
                        local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
                        if distance then
                            return distance <= spellRange
                        end
                    end
                    return API.IsSpellInRange(spellName, unit) == 1
                end)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- Original single-target behavior
            local target = conditionals.target or "target"
            local checkValue = (type(args) == "string" and args) or conditionals.action
            return API.IsSpellInRange(checkValue, target) == 1
        end, conditionals, "inrange")
    end,

    -- [noinrange] or [noinrange:Spell] - Target is NOT in range of spell
    -- [noinrange:Spell>N] - More than N enemies are NOT in range of spell (count mode)
    noinrange = function(conditionals)
        if not IsSpellInRange then return end
        local API = CleveRoids.NampowerAPI
        return NegatedMulti(conditionals.noinrange, function(args)
            -- Check for count mode: [noinrange:Multi-Shot>1]
            if type(args) == "table" and args.operator and args.amount then
                local spellName = args.name or conditionals.action
                local spellId = API.GetSpellIdFromName(spellName)
                local spellRange = spellId and API.GetSpellRange(spellId)
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    if spellRange and spellRange > 0 and CleveRoids.hasUnitXP then
                        local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
                        if distance then
                            return distance > spellRange
                        end
                    end
                    return API.IsSpellInRange(spellName, unit) == 0
                end)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- Original single-target behavior
            local target = conditionals.target or "target"
            local checkValue = (type(args) == "string" and args) or conditionals.action
            return API.IsSpellInRange(checkValue, target) == 0
        end, conditionals, "noinrange")
    end,

    -- [outrange] or [outrange:Spell] - Target is out of range of spell
    -- [outrange:Spell>N] - More than N enemies are out of range of spell (count mode)
    outrange = function(conditionals)
        if not IsSpellInRange then return end
        local API = CleveRoids.NampowerAPI
        return Multi(conditionals.outrange, function(args)
            -- Check for count mode: [outrange:Multi-Shot>1]
            if type(args) == "table" and args.operator and args.amount then
                local spellName = args.name or conditionals.action
                local spellId = API.GetSpellIdFromName(spellName)
                local spellRange = spellId and API.GetSpellRange(spellId)
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    if spellRange and spellRange > 0 and CleveRoids.hasUnitXP then
                        local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
                        if distance then
                            return distance > spellRange
                        end
                    end
                    return API.IsSpellInRange(spellName, unit) == 0
                end)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- Original single-target behavior
            local target = conditionals.target or "target"
            local checkValue = (type(args) == "string" and args) or conditionals.action
            return API.IsSpellInRange(checkValue, target) == 0
        end, conditionals, "outrange")
    end,

    -- [nooutrange] or [nooutrange:Spell] - Target is NOT out of range (same as inrange)
    -- [nooutrange:Spell>N] - More than N enemies are NOT out of range (count mode)
    nooutrange = function(conditionals)
        if not IsSpellInRange then return end
        local API = CleveRoids.NampowerAPI
        return NegatedMulti(conditionals.nooutrange, function(args)
            -- Check for count mode: [nooutrange:Multi-Shot>1]
            if type(args) == "table" and args.operator and args.amount then
                local spellName = args.name or conditionals.action
                local spellId = API.GetSpellIdFromName(spellName)
                local spellRange = spellId and API.GetSpellRange(spellId)
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    if spellRange and spellRange > 0 and CleveRoids.hasUnitXP then
                        local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
                        if distance then
                            return distance <= spellRange
                        end
                    end
                    return API.IsSpellInRange(spellName, unit) == 1
                end)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- Original single-target behavior
            local target = conditionals.target or "target"
            local checkValue = (type(args) == "string" and args) or conditionals.action

            local result = API.IsSpellInRange(checkValue, target)
            return result == 1  -- In range = nooutrange passes
        end, conditionals, "nooutrange")
    end,

    combo = function(conditionals)
        return Multi(conditionals.combo, function(args)
            if type(args) == "string" then -- 新增：对于没有比较数值的，只要有连击点则返回true，否则返回false by 武藤纯子酱 2026.1.9
                local points = GetComboPoints()
                if points and points > 0 then
                    return true
                else
                    return false
                end
            end
            return CleveRoids.ValidateComboPoints(args.operator, args.amount)
        end, conditionals, "combo")
    end,

    nocombo = function(conditionals)
        return NegatedMulti(conditionals.nocombo, function(args)
            if type(args) == "string" then -- 新增：对于没有比较数值的，只要没有连击点则返回true，否则返回false by 武藤纯子酱 2026.1.9
                local points = GetComboPoints()
                if not points or points == 0 then
                    return true
                else
                    return false
                end
            end
            return not CleveRoids.ValidateComboPoints(args.operator, args.amount)
        end, conditionals, "nocombo")
    end,

    known = function(conditionals)
        return Multi(conditionals.known, function(args)
            return CleveRoids.ValidateKnown(args)
        end, conditionals, "known")
    end,

    noknown = function(conditionals)
        return NegatedMulti(conditionals.noknown, function(args)
            return not CleveRoids.ValidateKnown(args)
        end, conditionals, "noknown")
    end,

    resting = function()
        return IsResting() == 1
    end,

    noresting = function()
        return IsResting() == nil
    end,

    bg = function()
        for i = 1, MAX_BATTLEFIELD_QUEUES do
            if GetBattlefieldStatus(i) == "active" then
                return true
            end
        end
        return false
    end,

    nobg = function()
        for i = 1, MAX_BATTLEFIELD_QUEUES do
            if GetBattlefieldStatus(i) == "active" then
                return false
            end
        end
        return true
    end,

    stat = function(conditionals)
        return Multi(conditionals.stat, function(args)
            if type(args) ~= "table" or not args.name then
                return false -- Malformed arguments from the parser.
            end

            local stat_key = string.lower(args.name)
            local get_stat_func = stat_checks[stat_key]

            if not get_stat_func then
                return false -- The requested stat key is invalid.
            end

            local current_value = get_stat_func()
            if not current_value then return false end

            -- Check if this is a multi-comparison stat conditional
            -- args.comparisons will be a table of {operator=, amount=} if multiple
            if args.comparisons and type(args.comparisons) == "table" then
                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.comparators[comp.operator] then
                        return false -- Invalid operator
                    end
                    if not CleveRoids.comparators[comp.operator](current_value, comp.amount) then
                        return false -- One comparison failed, so the whole conditional fails
                    end
                end
                return true -- All comparisons passed
            else
                -- Single comparison (backward compatibility)
                if not args.operator or not args.amount then
                    return false
                end
                return CleveRoids.comparators[args.operator](current_value, args.amount)
            end
        end, conditionals, "stat")
    end,

    -- [nostat] - Negated stat comparison
    -- Usage: [nostat:agi>100] = true if NOT (agi > 100), i.e., agi <= 100
    nostat = function(conditionals)
        return NegatedMulti(conditionals.nostat, function(args)
            if type(args) ~= "table" or not args.name then
                return true -- Malformed = negation passes
            end

            local stat_key = string.lower(args.name)
            local get_stat_func = stat_checks[stat_key]

            if not get_stat_func then
                return true -- Invalid stat = negation passes
            end

            local current_value = get_stat_func()
            if not current_value then return true end

            -- Handle multi-comparison
            if args.comparisons and type(args.comparisons) == "table" then
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.comparators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](current_value, comp.amount) then
                        return true -- One failed = negation passes
                    end
                end
                return false -- All passed = negation fails
            else
                if not args.operator or not args.amount then
                    return true
                end
                return not CleveRoids.comparators[args.operator](current_value, args.amount)
            end
        end, conditionals, "nostat")
    end,

    class = function(conditionals)
        -- Determine which unit to check. Defaults to 'target' if no @unitid was specified.
        local unitToCheck = conditionals.target or "target"

        -- The conditional must fail if the unit doesn't exist OR is not a player.
        if not UnitExists(unitToCheck) or not UnitIsPlayer(unitToCheck) then
            return false
        end

        -- Get the player's class.
        local localizedClass, englishClass = UnitClass(unitToCheck)
        if not localizedClass then return false end -- Failsafe for unusual cases

        -- The "Or" helper handles multiple values like [class:Warrior/Druid].
        return Or(conditionals.class, function(requiredClass)
            if type(requiredClass) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            return string.lower(requiredClass) == string.lower(localizedClass) or string.lower(requiredClass) == string.lower(englishClass)
        end)
    end,

    noclass = function(conditionals)
        -- Determine which unit to check. Defaults to 'target' if no @unitid was specified.
        local unitToCheck = conditionals.target or "target"

        -- A unit that doesn't exist cannot have a specific player class.
        if not UnitExists(unitToCheck) then
            return true
        end

        -- An NPC cannot have a specific player class.
        if not UnitIsPlayer(unitToCheck) then
            return true
        end

        -- If we get here, the unit is a player. Now check their class.
        local localizedClass, englishClass = UnitClass(unitToCheck)
        -- A player should always have a class, but if not, this condition is still met.
        if not localizedClass then return true end

        -- The "NegatedMulti" helper ensures the player's class is not any of the forbidden classes.
        return NegatedMulti(conditionals.noclass, function(forbiddenClass)
            -- 修复：补类型守卫（此前只修了 class，noclass 漏了）by 武藤纯子酱 2026.9.11
            if type(forbiddenClass) ~= "string" then return false end
            return string.lower(forbiddenClass) ~= string.lower(localizedClass) and string.lower(forbiddenClass) ~= string.lower(englishClass)
        end, conditionals, "noclass")
    end,

    pet = function(conditionals)
        if not UnitExists("pet") then
            return false
        end

        -- Bare [pet] with no type argument: just check pet exists (already passed above)
        if conditionals.pet == true then
            return true
        end


        return Or(conditionals.pet, function(petType)
            if type(petType) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local currentPet = UnitCreatureFamily("pet")
            if not currentPet then
                return false
            end
            return string.lower(currentPet) == string.lower(petType)
        end)
    end,

    nopet = function(conditionals)
        if not UnitExists("pet") then
            return true
        end

        -- Bare [nopet] with no type argument: pet exists so nopet is false
        if conditionals.nopet == true then
            return false
        end

        return NegatedMulti(conditionals.nopet, function(petType)
            if type(petType) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local currentPet = UnitCreatureFamily("pet")
            if not currentPet then
                return true
            end
            return string.lower(currentPet) ~= string.lower(petType)
        end, conditionals, "nopet")
    end,

    -- [swimming] - Player is currently swimming (Nampower v2.36+)
    swimming = function(conditionals)
        if not CleveRoids.NampowerAPI.features.hasPlayerIsSwimming then
            if not CleveRoids._swimmingErrorShown then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swimming] conditional requires Nampower v2.36.0 or newer.", 1, 0.5, 0.5)
                CleveRoids._swimmingErrorShown = true
            end
            return false
        end
        return PlayerIsSwimming() == 1
    end,

    -- [noswimming] - Player is NOT swimming (Nampower v2.36+)
    noswimming = function(conditionals)
        if not CleveRoids.NampowerAPI.features.hasPlayerIsSwimming then
            if not CleveRoids._swimmingErrorShown then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swimming] conditional requires Nampower v2.36.0 or newer.", 1, 0.5, 0.5)
                CleveRoids._swimmingErrorShown = true
            end
            return false
        end
        return PlayerIsSwimming() ~= 1
    end,

    -- [rooted] - Player is currently rooted (Nampower v2.36+)
    rooted = function(conditionals)
        if not CleveRoids.NampowerAPI.features.hasPlayerIsRooted then
            if not CleveRoids._rootedErrorShown then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [rooted] conditional requires Nampower v2.36.0 or newer.", 1, 0.5, 0.5)
                CleveRoids._rootedErrorShown = true
            end
            return false
        end
        return PlayerIsRooted() == 1
    end,

    -- [norooted] - Player is NOT rooted (Nampower v2.36+)
    norooted = function(conditionals)
        if not CleveRoids.NampowerAPI.features.hasPlayerIsRooted then
            if not CleveRoids._rootedErrorShown then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [rooted] conditional requires Nampower v2.36.0 or newer.", 1, 0.5, 0.5)
                CleveRoids._rootedErrorShown = true
            end
            return false
        end
        return PlayerIsRooted() ~= 1
    end,

    -- [distance:<30] - Target is within 30 yards
    -- [distance:30>1] - More than 1 enemy within 30 yards (count mode)
    -- [distance:30facing>1] - More than 1 enemy within 30 yards AND facing (compound count)
    distance = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        return Multi(conditionals.distance, function(args)
            if type(args) ~= "table" or not args.operator or not args.amount then
                return false
            end

            -- Count mode: name encodes distance threshold + optional filter + optional baseUnit
            local filter, distThreshold, baseUnit = ParseCountModeFilter(args.name, conditionals.action)
            if distThreshold then
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if not dist or dist > distThreshold then return false end
                    if filter and not filter(unit, baseUnit) then return false end
                    return true
                end, baseUnit)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- 单目标基准单位：若 args.name 等于 action（即未显式指定）则默认 player
            local singleBaseUnit = args.name
            if not CleveRoids.IsValidUnitToken(singleBaseUnit) or singleBaseUnit == conditionals.action then
                singleBaseUnit = "player"
            end

            -- Single-target: [distance:<30]
            local unit = conditionals.target or "target"
            if not UnitExists(unit) then return false end

            local distance = CleveRoids.SafeUnitXP("distanceBetween", singleBaseUnit, unit)
            if not distance then return false end

            return CleveRoids.comparators[args.operator](distance, args.amount)
        end, conditionals, "distance")
    end,

    -- [nodistance:<30] - Target is NOT within 30 yards
    -- [nodistance:30>1] - More than 1 enemy NOT within 30 yards (count mode)
    -- [nodistance:30facing>1] - More than 1 enemy NOT within 30 yards AND facing (compound count)
    nodistance = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        return NegatedMulti(conditionals.nodistance, function(args)
            if type(args) ~= "table" or not args.operator or not args.amount then
                return false
            end

            -- Count mode: name encodes distance threshold + optional filter + optional baseUnit
            local filter, distThreshold, baseUnit = ParseCountModeFilter(args.name, conditionals.action)
            if distThreshold then
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if dist and dist <= distThreshold then return false end
                    if filter and not filter(unit, baseUnit) then return false end
                    return true
                end, baseUnit)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- 单目标基准单位：若 args.name 等于 action（即未显式指定）则默认 player
            local singleBaseUnit = args.name
            if not CleveRoids.IsValidUnitToken(singleBaseUnit) or singleBaseUnit == conditionals.action then
                singleBaseUnit = "player"
            end

            -- Single-target: [nodistance:<30]
            local unit = conditionals.target or "target"
            if not UnitExists(unit) then return false end

            local distance = CleveRoids.SafeUnitXP("distanceBetween", singleBaseUnit, unit)
            if not distance then return false end

            return not CleveRoids.comparators[args.operator](distance, args.amount)
        end, conditionals, "nodistance")
    end,

    -- [behind] - Player is behind target
    -- [behind:>N] - Player is behind more than N enemies (count mode)
    -- [behind:meleerange>N] - Behind more than N enemies AND in melee range (compound count)
    -- [behind:10>N] - Behind more than N enemies AND within 10 yards (compound count)
    behind = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        local countArgs = CleveRoids.GetCountModeArgs(conditionals.behind)
        if countArgs then
            local filter, distThreshold, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if CleveRoids.SafeUnitXP("behind", baseUnit, unit) ~= true then return false end
                if distThreshold then
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if not dist or dist > distThreshold then return false end
                end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.behind) == "string" then
            baseUnit = conditionals.behind
        elseif type(conditionals.behind) == "table" and table.getn(conditionals.behind) > 0 then
            baseUnit = conditionals.behind[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("behind", baseUnit, unit) == true
    end,

    -- [nobehind] - Player is NOT behind target
    -- [nobehind:>N] - NOT behind more than N enemies (count mode)
    -- [nobehind:meleerange>N] - NOT behind more than N enemies AND in melee range (compound count)
    nobehind = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        local countArgs = CleveRoids.GetCountModeArgs(conditionals.nobehind)
        if countArgs then
            local filter, distThreshold, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if CleveRoids.SafeUnitXP("behind", baseUnit, unit) == true then return false end
                if distThreshold then
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if not dist or dist > distThreshold then return false end
                end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.nobehind) == "string" then
            baseUnit = conditionals.nobehind
        elseif type(conditionals.nobehind) == "table" and table.getn(conditionals.nobehind) > 0 then
            baseUnit = conditionals.nobehind[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("behind", baseUnit, unit) ~= true
    end,

    -- [facing] - Player is facing target (target is not behind player)
    -- [facing:>N] - Player is facing more than N enemies (count mode)
    -- [facing:meleerange>N] - Facing more than N enemies AND in melee range (compound count)
    -- [facing:10>N] - Facing more than N enemies AND within 10 yards (compound count)
    facing = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        local countArgs = CleveRoids.GetCountModeArgs(conditionals.facing)
        if countArgs then
            local filter, distThreshold, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if CleveRoids.SafeUnitXP("behind", unit, baseUnit) == true then return false end
                if distThreshold then
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if not dist or dist > distThreshold then return false end
                end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.facing) == "string" then
            baseUnit = conditionals.facing
        elseif type(conditionals.facing) == "table" and table.getn(conditionals.facing) > 0 then
            baseUnit = conditionals.facing[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("behind", unit, baseUnit) ~= true
    end,

    -- [nofacing] - Player is NOT facing target (target is behind player)
    -- [nofacing:>N] - NOT facing more than N enemies (count mode)
    -- [nofacing:meleerange>N] - NOT facing more than N enemies AND in melee range (compound count)
    nofacing = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        local countArgs = CleveRoids.GetCountModeArgs(conditionals.nofacing)
        if countArgs then
            local filter, distThreshold, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if CleveRoids.SafeUnitXP("behind", unit, baseUnit) ~= true then return false end
                if distThreshold then
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if not dist or dist > distThreshold then return false end
                end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.nofacing) == "string" then
            baseUnit = conditionals.nofacing
        elseif type(conditionals.nofacing) == "table" and table.getn(conditionals.nofacing) > 0 then
            baseUnit = conditionals.nofacing[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end

        return CleveRoids.SafeUnitXP("behind", unit, baseUnit) == true
    end,

    -- [insight] - Target is in line of sight
    -- [insight:>N] - More than N enemies are in line of sight (count mode)
    insight = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        -- Check for count mode: [insight:>1]
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.insight)
        if countArgs then
            local baseUnit = countArgs.name or "player"
            if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then baseUnit = "player" end
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) == true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.insight) == "string" then
            baseUnit = conditionals.insight
        elseif type(conditionals.insight) == "table" and table.getn(conditionals.insight) > 0 then
            baseUnit = conditionals.insight[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) == true
    end,

    -- [noinsight] - Target is NOT in line of sight
    -- [noinsight:>N] - More than N enemies are NOT in line of sight (count mode)
    noinsight = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        -- Check for count mode: [noinsight:>1]
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.noinsight)
        if countArgs then
            local baseUnit = countArgs.name or "player"
            if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then baseUnit = "player" end
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) ~= true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.noinsight) == "string" then
            baseUnit = conditionals.noinsight
        elseif type(conditionals.noinsight) == "table" and table.getn(conditionals.noinsight) > 0 then
            baseUnit = conditionals.noinsight[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) ~= true
    end,

    -- [meleerange] - Target is in melee range
    -- [meleerange:>N] - More than N enemies are in melee range (count mode)
    -- [meleerange:facing>N] - More than N enemies in melee range AND facing (compound count)
    meleerange = function(conditionals)
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.meleerange)
        if countArgs then
            local filter, _, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if not CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit) then return false end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.meleerange) == "string" then
            baseUnit = conditionals.meleerange
        elseif type(conditionals.meleerange) == "table" and table.getn(conditionals.meleerange) > 0 then
            baseUnit = conditionals.meleerange[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit)
    end,

    -- [nomeleerange] - Target is NOT in melee range
    -- [nomeleerange:>N] - More than N enemies are NOT in melee range (count mode)
    -- [nomeleerange:facing>N] - More than N enemies NOT in melee range AND facing (compound count)
    nomeleerange = function(conditionals)
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.nomeleerange)
        if countArgs then
            local filter, _, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit) then return false end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.nomeleerange) == "string" then
            baseUnit = conditionals.nomeleerange
        elseif type(conditionals.nomeleerange) == "table" and table.getn(conditionals.nomeleerange) > 0 then
            baseUnit = conditionals.nomeleerange[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return true end
        return not CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit)
    end,

    queuedspell = function(conditionals)
        if not CleveRoids.hasNampower then return false end
        if not CleveRoids.queuedSpell then return false end

        -- If no specific spell name provided, check if ANY spell is queued
        if not conditionals.queuedspell or (type(conditionals.queuedspell) == "table" and table.getn(conditionals.queuedspell) == 0) then
            return true
        end

        -- Check if specific spell is queued
        return Or(conditionals.queuedspell, function(spellName)
            if type(spellName) ~= "string" then return false end -- 修复：比较语法解析成表时 StripRank 返回 nil → string.lower(nil) 抛错 by 武藤纯子酱 2026.9.12
            if not CleveRoids.queuedSpell.spellName then return false end
            local queuedName = CleveRoids.StripRank(CleveRoids.queuedSpell.spellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
            local checkName = CleveRoids.StripRank(spellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
            return string.lower(queuedName) == string.lower(checkName)
        end)
    end,

    noqueuedspell = function(conditionals)
        if not CleveRoids.hasNampower then return false end

        -- If no specific spell name, check if NO spell is queued
        if not conditionals.noqueuedspell or (type(conditionals.noqueuedspell) == "table" and table.getn(conditionals.noqueuedspell) == 0) then
            return CleveRoids.queuedSpell == nil
        end

        -- Check if specific spell is NOT queued
        if not CleveRoids.queuedSpell or not CleveRoids.queuedSpell.spellName then
            return true
        end

        return NegatedMulti(conditionals.noqueuedspell, function(spellName)
            if type(spellName) ~= "string" then return false end -- 修复：非字符串时 StripRank 返回 nil → string.lower(nil) 抛错 by 武藤纯子酱 2026.9.12
            local queuedName = CleveRoids.StripRank(CleveRoids.queuedSpell.spellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
            local checkName = CleveRoids.StripRank(spellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
            return string.lower(queuedName) ~= string.lower(checkName)
        end, conditionals, "noqueuedspell")
    end,

    onswingpending = function(conditionals)
        if not GetCurrentCastingInfo then return false end

        local _, _, _, _, _, onswing = GetCurrentCastingInfo()
        return onswing == 1
    end,

    noonswingpending = function(conditionals)
        if not GetCurrentCastingInfo then return true end

        local _, _, _, _, _, onswing = GetCurrentCastingInfo()
        return onswing ~= 1
    end,

    mybuffcount = function(conditionals)
        -- 修复：解析条目里没有 bigger 字段（恒 nil → 一律按 count>amount 处理，[mybuffcount:<N] 方向反转），
        -- 改为把 operator 传给比较器 by 武藤纯子酱 2026.8.31
        -- 修复：值兼容——[mybuffcount:3]（无比较符）解析为纯字符串 "3"（无 operator/amount 字段），
        -- 裸写 [mybuffcount] 时 Multi 直传动作名；原代码对两者都取 v.operator/v.amount（恒 nil）
        -- 导致 count > nil 崩溃。字符串值按历史语义 count > N 处理，非数值一律 false by 武藤纯子酱 2026.9.9
        return Multi(conditionals.mybuffcount,function (v)
            if type(v) == "string" then
                return CleveRoids.ValidatePlayerAuraCount(">", v)
            end
            if type(v) ~= "table" then return false end
            -- 修复：支持多重比较 [mybuffcount:>5&<10]（此前只有 comparisons 无 operator/amount，
            -- 传入 ValidatePlayerAuraCount(nil,nil) 恒 false）by 武藤纯子酱 2026.9.11
            if v.comparisons and type(v.comparisons) == "table" then
                for _, comp in ipairs(v.comparisons) do
                    if comp.amount == nil or not CleveRoids.ValidatePlayerAuraCount(comp.operator, comp.amount) then
                        return false
                    end
                end
                return true
            end
            return CleveRoids.ValidatePlayerAuraCount(v.operator, v.amount)
        end, conditionals, "mybuffcount")
    end,

    -- [nomybuffcount] - Negated buff count comparison
    -- Usage: [nomybuffcount:>15] = true if NOT (buffcount > 15), i.e., buffcount <= 15
    nomybuffcount = function(conditionals)
        return NegatedMulti(conditionals.nomybuffcount, function(v)
            if type(v) == "string" then
                return not CleveRoids.ValidatePlayerAuraCount(">", v)
            end
            if type(v) ~= "table" then return true end
            -- 修复：支持多重比较（同 mybuffcount）by 武藤纯子酱 2026.9.11
            if v.comparisons and type(v.comparisons) == "table" then
                for _, comp in ipairs(v.comparisons) do
                    if comp.amount == nil or not CleveRoids.ValidatePlayerAuraCount(comp.operator, comp.amount) then
                        return true
                    end
                end
                return false
            end
            return not CleveRoids.ValidatePlayerAuraCount(v.operator, v.amount)
        end, conditionals, "nomybuffcount")
    end,

    -- [mhimbue] - Check main hand has temporary imbue (poison, oil, sharpening stone, etc.)
    -- [mhimbue:Name] - Check for specific imbue name
    -- [mhimbue:<300] - Check imbue time remaining < 300 seconds
    -- [mhimbue:Name<300] - Specific imbue with time check
    -- [mhimbue:>#5] - Check imbue charges > 5
    mhimbue = function(conditionals)
        local args = CleveRoids.ParseImbueArgs(conditionals.mhimbue, conditionals)
        return CleveRoids.ValidateWeaponImbue("mh", args)
    end,

    nomhimbue = function(conditionals)
        local args = CleveRoids.ParseImbueArgs(conditionals.nomhimbue, conditionals)
        return not CleveRoids.ValidateWeaponImbue("mh", args)
    end,

    -- [ohimbue] - Check off hand has temporary imbue
    -- Same syntax as mhimbue
    ohimbue = function(conditionals)
        local args = CleveRoids.ParseImbueArgs(conditionals.ohimbue, conditionals)
        return CleveRoids.ValidateWeaponImbue("oh", args)
    end,

    noohimbue = function(conditionals)
        local args = CleveRoids.ParseImbueArgs(conditionals.noohimbue, conditionals)
        return not CleveRoids.ValidateWeaponImbue("oh", args)
    end,

    immune = function(conditionals)
        -- Check if target is immune to the spell being cast or damage school
        -- Usage: [immune] SpellName  OR  [immune:SpellName]  OR  [immune:fire]
        local checkValue = nil

        -- Case 1: [immune:SpellName] or [immune:fire]
        if type(conditionals.immune) == "table" and table.getn(conditionals.immune) > 0 then
            checkValue = conditionals.immune[1]
        elseif type(conditionals.immune) == "string" then
            checkValue = conditionals.immune
        -- Case 2: [immune] SpellName (check the action being cast)
        elseif conditionals.action then
            checkValue = conditionals.action
        end

        if not checkValue then
            return false
        end

        return CleveRoids.CheckImmunity(conditionals.target or "target", checkValue)
    end,

    noimmune = function(conditionals)
        -- Check if target is NOT immune to the spell being cast or damage school
        -- Usage: [noimmune] SpellName  OR  [noimmune:SpellName]  OR  [noimmune:fire]
        local checkValue = nil

        -- Case 1: [noimmune:SpellName] or [noimmune:fire]
        if type(conditionals.noimmune) == "table" and table.getn(conditionals.noimmune) > 0 then
            checkValue = conditionals.noimmune[1]
        elseif type(conditionals.noimmune) == "string" then
            checkValue = conditionals.noimmune
        -- Case 2: [noimmune] SpellName (check the action being cast)
        elseif conditionals.action then
            checkValue = conditionals.action
        end

        if not checkValue then
            return true  -- If we can't determine spell/school, assume not immune
        end

        local isImmune = CleveRoids.CheckImmunity(conditionals.target or "target", checkValue)
        return not isImmune
    end,

    -- SP_SwingTimer integration conditionals
    -- Checks percentage of swing time that has elapsed
    -- Usage: [swingtimer:<15] = less than 15% of swing has elapsed (early in swing)
    --        [swingtimer:>80] = more than 80% of swing has elapsed (late in swing)
    swingtimer = function(conditionals)
        return Multi(conditionals.swingtimer, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetSwingPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._swingTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swingtimer] conditional requires SP_SwingTimer or pfUI (swing timer module). Get SP_SwingTimer at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._swingTimerErrorShown = true
                    end
                    return false
                end

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateSwingTimer(args.operator, args.amount)
        end, conditionals, "swingtimer")
    end,

    -- Alias for swingtimer
    stimer = function(conditionals)
        return Multi(conditionals.stimer, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetSwingPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._swingTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swingtimer] conditional requires SP_SwingTimer or pfUI (swing timer module). Get SP_SwingTimer at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._swingTimerErrorShown = true
                    end
                    return false
                end

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateSwingTimer(args.operator, args.amount)
        end, conditionals, "stimer")
    end,

    -- Negated swingtimer
    noswingtimer = function(conditionals)
        return NegatedMulti(conditionals.noswingtimer, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison by checking positive and negating
            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetSwingPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._swingTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swingtimer] conditional requires SP_SwingTimer or pfUI (swing timer module). Get SP_SwingTimer at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._swingTimerErrorShown = true
                    end
                    return true
                end

                -- Check if ALL comparisons pass
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return true  -- One failed, so positive=false, negated=true
                    end
                end
                return false  -- All passed, so positive=true, negated=false
            end

            return not CleveRoids.ValidateSwingTimer(args.operator, args.amount)
        end, conditionals, "noswingtimer")
    end,

    -- Alias for noswingtimer
    nostimer = function(conditionals)
        return NegatedMulti(conditionals.nostimer, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison by checking positive and negating
            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetSwingPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._swingTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swingtimer] conditional requires SP_SwingTimer or pfUI (swing timer module). Get SP_SwingTimer at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._swingTimerErrorShown = true
                    end
                    return true
                end

                -- 修复：改用 GetSwingTimerRaw() 获取剩余时间与总时长（内部同时支持
                -- SP_SwingTimer 的 st_timer/st_timerMax 与 pfUI 摆动计时器），
                -- 原代码直接用 attackSpeed - st_timer 重算百分比，pfUI 路径下 st_timer
                -- 全局为 nil 会触发算术错误 by 武藤纯子酱 2026.8.31
                local timeRemaining, swingSpeed = CleveRoids.GetSwingTimerRaw()
                if not timeRemaining or not swingSpeed or swingSpeed <= 0 then return true end
                percentElapsed = ((swingSpeed - timeRemaining) / swingSpeed) * 100

                -- Check if ALL comparisons pass
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return true  -- One failed, so positive=false, negated=true
                    end
                end
                return false  -- All passed, so positive=true, negated=false
            end

            return not CleveRoids.ValidateSwingTimer(args.operator, args.amount)
        end, conditionals, "nostimer")
    end,

    -- SP_SwingTimer ranged swing timer conditional
    -- Checks percentage of ranged swing time that has elapsed
    -- Usage: [rangedtimer:>80] = more than 80% of ranged swing has elapsed
    --        [rangedtimer:<20] = less than 20% of ranged swing has elapsed
    rangedtimer = function(conditionals)
        return Multi(conditionals.rangedtimer, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetRangedPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._rangedTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [rangedtimer] conditional requires SP_SwingTimer. Get it at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._rangedTimerErrorShown = true
                    end
                    return false
                end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateRangedTimer(args.operator, args.amount)
        end, conditionals, "rangedtimer")
    end,

    -- Alias for rangedtimer
    rtimer = function(conditionals)
        return Multi(conditionals.rtimer, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetRangedPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._rangedTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [rangedtimer] conditional requires SP_SwingTimer. Get it at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._rangedTimerErrorShown = true
                    end
                    return false
                end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateRangedTimer(args.operator, args.amount)
        end, conditionals, "rtimer")
    end,

    -- Negated rangedtimer
    norangedtimer = function(conditionals)
        return NegatedMulti(conditionals.norangedtimer, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetRangedPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._rangedTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [rangedtimer] conditional requires SP_SwingTimer. Get it at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._rangedTimerErrorShown = true
                    end
                    return true
                end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return true
                    end
                end
                return false
            end

            return not CleveRoids.ValidateRangedTimer(args.operator, args.amount)
        end, conditionals, "norangedtimer")
    end,

    -- Alias for norangedtimer
    nortimer = function(conditionals)
        return NegatedMulti(conditionals.nortimer, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local percentElapsed = CleveRoids.GetRangedPercentElapsed()
                if percentElapsed == nil then
                    if not CleveRoids._rangedTimerErrorShown then
                        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [rangedtimer] conditional requires SP_SwingTimer. Get it at: https://github.com/jrc13245/SP_SwingTimer", 1, 0.5, 0.5)
                        CleveRoids._rangedTimerErrorShown = true
                    end
                    return true
                end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](percentElapsed, comp.amount) then
                        return true
                    end
                end
                return false
            end

            return not CleveRoids.ValidateRangedTimer(args.operator, args.amount)
        end, conditionals, "nortimer")
    end,

    -- Threat percentage conditional (reads server data via CHAT_MSG_ADDON)
    -- Usage: [threat:>80] - true if threat is above 80%
    -- 100% = will pull aggro
    -- Note: Requires TWThreat addon to request threat data from server
    threat = function(conditionals)
        return Multi(conditionals.threat, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<90)
            if args.comparisons and type(args.comparisons) == "table" then
                local threatpct = CleveRoids.GetPlayerThreatPercent()
                if threatpct == nil then return false end

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](threatpct, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateThreat(args.operator, args.amount)
        end, conditionals, "threat")
    end,

    -- Negated threat conditional
    nothreat = function(conditionals)
        return NegatedMulti(conditionals.nothreat, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local threatpct = CleveRoids.GetPlayerThreatPercent()
                if threatpct == nil then return true end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](threatpct, comp.amount) then
                        return true
                    end
                end
                return false
            end

            return not CleveRoids.ValidateThreat(args.operator, args.amount)
        end, conditionals, "nothreat")
    end,

    -- Time-To-Kill conditional (requires TimeToKill addon)
    -- Usage: [ttk:<10] - true if target will die in less than 10 seconds
    ttk = function(conditionals)
        return Multi(conditionals.ttk, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >5&<15)
            if args.comparisons and type(args.comparisons) == "table" then
                local ttk -- 将ttk提前定义 by 武藤纯子酱 2026.1.27
                if type(TimeToKill) ~= "table" or type(TimeToKill.GetTTK) ~= "function" then
                    ttk = CleveRoids.GetTargetDeathTime(conditionals.target or "target")
                else
                    ttk = TimeToKill.GetTTK()
                end

                --local ttk = TimeToKill.GetTTK()
                if ttk == nil then return false end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](ttk, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateTTK(args.operator, args.amount, conditionals)
        end, conditionals, "ttk")
    end,

    -- Negated TTK conditional
    nottk = function(conditionals)
        return NegatedMulti(conditionals.nottk, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local ttk -- 将ttk提前定义 by 武藤纯子酱 2026.1.27
                if type(TimeToKill) ~= "table" or type(TimeToKill.GetTTK) ~= "function" then
                    ttk = CleveRoids.GetTargetDeathTime(conditionals.target or "target")
                else
                    ttk = TimeToKill.GetTTK()
                end

                --local ttk = TimeToKill.GetTTK()
                if ttk == nil then return true end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](ttk, comp.amount) then
                        return true
                    end
                end
                return false
            end

            return not CleveRoids.ValidateTTK(args.operator, args.amount, conditionals)
        end, conditionals, "nottk")
    end,

    -- Time-To-Execute conditional (requires TimeToKill addon)
    -- Usage: [tte:<5] - true if target will reach 20% HP in less than 5 seconds
    tte = function(conditionals)
        return Multi(conditionals.tte, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local tte -- 将tte提前定义 by 武藤纯子酱 2026.1.27
                if type(TimeToKill) ~= "table" or type(TimeToKill.GetTTE) ~= "function" then
                    tte = CleveRoids.GetTargetPercent20Time(conditionals.target or "target")
                else
                    tte = TimeToKill.GetTTE()
                end

                --local tte = TimeToKill.GetTTE()
                if tte == nil then return false end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](tte, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateTTE(args.operator, args.amount, conditionals)
        end, conditionals, "tte")
    end,

    -- Negated TTE conditional
    notte = function(conditionals)
        return NegatedMulti(conditionals.notte, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local tte -- 将tte提前定义 by 武藤纯子酱 2026.1.27
                if type(TimeToKill) ~= "table" or type(TimeToKill.GetTTE) ~= "function" then
                    tte = CleveRoids.GetTargetPercent20Time(conditionals.target or "target")
                else
                    tte = TimeToKill.GetTTE()
                end

                --local tte = TimeToKill.GetTTE()
                if tte == nil then return true end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](tte, comp.amount) then
                        return true
                    end
                end
                return false
            end

            return not CleveRoids.ValidateTTE(args.operator, args.amount, conditionals)
        end, conditionals, "notte")
    end,

    -- =========================================================================
    -- CURSIVE ADDON INTEGRATION
    -- =========================================================================
    -- Checks debuffs using Cursive's GUID-based tracking for accurate time remaining
    -- Supports time comparisons: [cursive:Rake>3] [cursive:Rip<5]
    -- Works with multiscan for intelligent target selection

    -- [cursive] - Check if target has ANY Cursive-tracked debuff
    -- [cursive:SpellName] - Check if target has specific debuff tracked by Cursive
    -- [cursive:SpellName>3] - Check if debuff has more than 3 seconds remaining
    -- [cursive:SpellName<5] - Check if debuff has less than 5 seconds remaining
    -- Examples: [cursive:Rake] [@focus,cursive:Rip>5] [cursive:Corruption<3]
    cursive = function(conditionals)
        -- Check if Cursive addon is available
        if not CleveRoids.RequireCursive("cursive") then
            return false
        end

        local target = conditionals.target or "target"

        -- Boolean form [cursive] - check if target has ANY tracked debuff
        if not conditionals.cursive or
           conditionals.cursive == true or
           (type(conditionals.cursive) == "table" and table.getn(conditionals.cursive) == 0) then
            return CleveRoids.HasAnyCursiveDebuff(target)
        end

        -- Spell name form with optional time comparison
        return Multi(conditionals.cursive, function(args)
            if type(args) == "string" then
                -- Simple spell name check: [cursive:Rake]
                return CleveRoids.ValidateCursiveDebuff(target, args, nil, nil)
            elseif type(args) == "table" then
                -- Time comparison: [cursive:Rake>3] or multi-comparison [cursive:Rake>3&<10]
                local spellName = args.name

                -- Handle multi-comparison (e.g., >3&<10)
                if args.comparisons and type(args.comparisons) == "table" then
                    local timeRemaining = CleveRoids.GetCursiveTimeRemaining(target, spellName)
                    -- If debuff not found, treat as 0 seconds remaining (matches [debuff] behavior)
                    if not timeRemaining then timeRemaining = 0 end

                    -- ALL comparisons must pass (AND logic)
                    for _, comp in ipairs(args.comparisons) do
                        if not CleveRoids.operators[comp.operator] then
                            return false
                        end
                        if not CleveRoids.comparators[comp.operator](timeRemaining, comp.amount) then
                            return false
                        end
                    end
                    return true
                end

                -- Single comparison: [cursive:Rake>3]
                return CleveRoids.ValidateCursiveDebuff(target, spellName, args.operator, args.amount)
            end
            return false
        end, conditionals, "cursive")
    end,

    -- [nocursive] - Check if target does NOT have any Cursive-tracked debuff
    -- [nocursive:SpellName] - Check if target does NOT have specific debuff
    -- [nocursive:SpellName>3] - Check if debuff does NOT exist with >3 seconds remaining
    --                          (true if missing OR has <=3 seconds)
    nocursive = function(conditionals)
        local target = conditionals.target or "target"

        -- 结果确认门（前置）：同 nomydot，先于 Cursive 可用性早退 by 武藤纯子酱 2026.8.31
        local gateArgs = conditionals.nocursive
        if type(gateArgs) == "table" and table.getn(gateArgs) > 0 then
            local firstArg = gateArgs[1]
            local gateName = type(firstArg) == "string" and firstArg or (type(firstArg) == "table" and firstArg.name)
            if gateName and CleveRoids.IsPendingDebuffCast(gateName, target) then
                return false
            end
        end

        -- Check if Cursive addon is available (return true if missing = treat as "no debuff")
        if not CleveRoids.HasCursive() then
            return true
        end

        -- Boolean form [nocursive] - check if target has NO tracked debuffs
        if not conditionals.nocursive or
           conditionals.nocursive == true or
           (type(conditionals.nocursive) == "table" and table.getn(conditionals.nocursive) == 0) then
            return not CleveRoids.HasAnyCursiveDebuff(target)
        end

        -- Negated spell name form
        return NegatedMulti(conditionals.nocursive, function(args)
            -- Extract spell name from args
            local spellName = type(args) == "string" and args or (type(args) == "table" and args.name)

            -- Check if this debuff is PENDING (being cast or queued)
            -- This prevents double-application when spamming macros with spell queue
            if spellName and CleveRoids.IsPendingDebuffCast(spellName, target) then
                return false  -- Treat as if debuff exists (nocursive returns false)
            end

            if type(args) == "string" then
                -- Simple spell name check: [nocursive:Rake] = true if Rake is missing
                return not CleveRoids.ValidateCursiveDebuff(target, args, nil, nil)
            elseif type(args) == "table" then
                spellName = args.name

                -- Handle multi-comparison negation
                if args.comparisons and type(args.comparisons) == "table" then
                    local timeRemaining = CleveRoids.GetCursiveTimeRemaining(target, spellName)
                    -- If debuff missing, negation passes
                    if not timeRemaining then return true end

                    -- Negated: true if ANY comparison fails
                    for _, comp in ipairs(args.comparisons) do
                        if not CleveRoids.operators[comp.operator] then
                            return true
                        end
                        if not CleveRoids.comparators[comp.operator](timeRemaining, comp.amount) then
                            return true
                        end
                    end
                    return false
                end

                -- Single comparison negation
                return not CleveRoids.ValidateCursiveDebuff(target, spellName, args.operator, args.amount)
            end
            return true
        end, conditionals, "nocursive")
    end,
    
    -- Slam clip window conditionals for Warrior Slam rotation optimization
    -- Based on math: MaxSlamPercent = (SwingTimer - SlamCastTime) / SwingTimer * 100
    -- Requires SP_SwingTimer addon and Nampower for cast time lookup

    -- [noslamclip] - True if casting Slam NOW will NOT clip the auto-attack
    -- Usage: /cast [noslamclip] Slam
    noslamclip = function(conditionals)
        return CleveRoids.ValidateNoSlamClip()
    end,

    -- [slamclip] - True if casting Slam NOW WILL clip the auto-attack (negated)
    -- Usage: /cast [slamclip] Heroic Strike  -- Use HS instead when past slam window
    slamclip = function(conditionals)
        return not CleveRoids.ValidateNoSlamClip()
    end,

    -- [nonextslamclip] - True if casting an instant NOW will NOT cause NEXT Slam to clip
    -- Scenario: Skip Slam this swing, cast instant, then Slam next swing without clipping
    -- Formula: MaxInstantPercent = (2 * SwingTimer - SlamCastTime - GCD) / SwingTimer * 100
    -- Usage: /cast [nonextslamclip] Bloodthirst
    nonextslamclip = function(conditionals)
        return CleveRoids.ValidateNoNextSlamClip()
    end,

    -- [nextslamclip] - True if casting an instant NOW WILL cause NEXT Slam to clip (negated)
    -- Usage: Use this when you want to know you're past the instant window
    nextslamclip = function(conditionals)
        return not CleveRoids.ValidateNoNextSlamClip()
    end,

    -- Ranged clip window conditionals
    -- Checks if there is enough time remaining on the ranged auto-shot timer
    -- for the action's cast time to complete without delaying the next auto-shot.
    -- Requires SP_SwingTimer addon for ranged timer data.

    -- [rangedclip] or [rangedclip:SpellName] or [rangedclip:SpellName>0.5] or [rangedclip:SpellName>0.3&<0.5]
    rangedclip = function(conditionals) -- 修改支持指定技能和延迟时间 by 武藤纯子酱 2026.4.7
        return Multi(conditionals.rangedclip, function(args)
            local spellName, operator, amount, comparisons
            if type(args) == "string" then
                spellName = args
            elseif type(args) == "table" then
                spellName = args.name or conditionals.action
                operator = args.operator
                amount = args.amount
                comparisons = args.comparisons
            else
                spellName = conditionals.action
            end
            return CleveRoids.IsRangedClipSpell(spellName, operator, amount, comparisons)
        end, conditionals, "rangedclip")
    end,

    -- [norangedclip] or [norangedclip:SpellName] or [norangedclip:SpellName>0.5] or [norangedclip:SpellName>0.3&<0.5]
    norangedclip = function(conditionals) -- 修改支持指定技能和延迟时间 by 武藤纯子酱 2026.4.7
        return NegatedMulti(conditionals.norangedclip, function(args)
            local spellName, operator, amount, comparisons
            if type(args) == "string" then
                spellName = args
            elseif type(args) == "table" then
                spellName = args.name or conditionals.action
                operator = args.operator
                amount = args.amount
                comparisons = args.comparisons
            else
                spellName = conditionals.action
            end
            -- norangedclip is true when the spell does NOT clip
            return not CleveRoids.IsRangedClipSpell(spellName, operator, amount, comparisons)
        end, conditionals, "norangedclip")
    end,

    -- Checks if the target uses a specific power type (mana, rage, energy)
    powertype = function(conditionals)
        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end

        return Or(conditionals.powertype, function(powerTypeName)
            if type(powerTypeName) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local powerType = UnitPowerType(unit)
            local powerTypeLower = string.lower(powerTypeName or "")

            if powerTypeLower == "mana" then
                return powerType == 0
            elseif powerTypeLower == "rage" then
                return powerType == 1
            elseif powerTypeLower == "focus" then
                return powerType == 2
            elseif powerTypeLower == "energy" then
                return powerType == 3
            end

            return false
        end)
    end,

    -- Checks if the target does NOT use a specific power type
    nopowertype = function(conditionals)
        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return true end

        return NegatedMulti(conditionals.nopowertype, function(powerTypeName)
            if type(powerTypeName) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            local powerType = UnitPowerType(unit)
            local powerTypeLower = string.lower(powerTypeName or "")

            if powerTypeLower == "mana" then
                return powerType ~= 0
            elseif powerTypeLower == "rage" then
                return powerType ~= 1
            elseif powerTypeLower == "focus" then
                return powerType ~= 2
            elseif powerTypeLower == "energy" then
                return powerType ~= 3
            end

            return true
        end, conditionals, "nopowertype")
    end,
    
    -- ========================================================================
    -- CC (Crowd Control) Conditionals - Requires BuffLib for full functionality
    -- ========================================================================

    -- [cc:type] - Check if target has a specific CC effect
    -- Types: stun, fear, root, snare/slow, sleep, charm, polymorph, banish, horror,
    --        disarm, silence, daze, sap, freeze, knockout/incap, disorient, shackle
    -- Special: [cc] or [cc:any] checks for any loss-of-control effect
    -- Examples: [cc:stun] [@focus,cc:fear] [cc:stun/fear/root]
    cc = function(conditionals)
        local target = conditionals.target or "target"

        -- If no specific CC type, check for ANY loss-of-control
        if not conditionals.cc or (type(conditionals.cc) == "table" and table.getn(conditionals.cc) == 0) or type(conditionals.cc) == "string" then -- 修复，不接类型时默认所有类型 by 武藤纯子酱 2025.12.25
            return CleveRoids.ValidateUnitAnyCrowdControl(target)
        end

        -- Check for specific CC type(s) - OR logic
        return Or(conditionals.cc, function(ccType)
            return CleveRoids.ValidateUnitCC(target, ccType)
        end)
    end,

    -- [nocc:type] - Check if target does NOT have a specific CC effect
    -- Uses AND logic for negation: [nocc:stun/fear] = not stunned AND not feared
    nocc = function(conditionals)
        local target = conditionals.target or "target"

        -- If no specific CC type, check for NO loss-of-control
        -- 修复：守卫误查正向的 conditionals.cc（复制粘贴错误），裸写 [nocc] 时值是字符串永远匹配不上 by 武藤纯子酱 2026.8.31
        if not conditionals.nocc or (type(conditionals.nocc) == "table" and table.getn(conditionals.nocc) == 0) or type(conditionals.nocc) == "string" then -- 修复，不接类型时默认所有类型 by 武藤纯子酱 2025.12.25
            return not CleveRoids.ValidateUnitAnyCrowdControl(target)
        end

        -- Check for absence of specific CC type(s) - AND logic (must be missing ALL)
        return NegatedMulti(conditionals.nocc, function(ccType)
            return not CleveRoids.ValidateUnitCC(target, ccType)
        end, conditionals, "nocc")
    end,

    -- [mycc:type] - Check if PLAYER has a specific CC effect
    -- Same types as [cc], but always checks the player
    -- Examples: [mycc:stun] [mycc:fear/charm] [mycc] (any CC)
    mycc = function(conditionals)
        -- If no specific CC type, check for ANY loss-of-control on player
        -- 修复：守卫误查 conditionals.cc，改为检查自己的键 by 武藤纯子酱 2026.8.31
        if not conditionals.mycc or (type(conditionals.mycc) == "table" and table.getn(conditionals.mycc) == 0) or type(conditionals.mycc) == "string" then -- 修复，不接类型时默认所有类型 by 武藤纯子酱 2025.12.25
            return CleveRoids.ValidateUnitAnyCrowdControl("player")
        end

        -- Check for specific CC type(s) - OR logic
        return Or(conditionals.mycc, function(ccType)
            return CleveRoids.ValidateUnitCC("player", ccType)
        end)
    end,

    -- [nomycc:type] - Check if PLAYER does NOT have a specific CC effect
    -- Uses AND logic for negation: [nomycc:stun/fear] = not stunned AND not feared
    nomycc = function(conditionals)
        -- If no specific CC type, check for NO loss-of-control on player
        -- 修复：守卫误查 conditionals.cc，改为检查自己的键 by 武藤纯子酱 2026.8.31
        if not conditionals.nomycc or (type(conditionals.nomycc) == "table" and table.getn(conditionals.nomycc) == 0) or type(conditionals.nomycc) == "string" then -- 修复，不接类型时默认所有类型 by 武藤纯子酱 2025.12.25
            return not CleveRoids.ValidateUnitAnyCrowdControl("player")
        end

        -- Check for absence of specific CC type(s) - AND logic
        return NegatedMulti(conditionals.nomycc, function(ccType)
            return not CleveRoids.ValidateUnitCC("player", ccType)
        end, conditionals, "nomycc")
    end,
    
    -- ========================================================================
    -- RESIST TRACKING CONDITIONALS
    -- ========================================================================

    -- [resisted] - Check if last spell was resisted by current target
    -- [resisted:type] - Check for specific resist type (full, partial)
    -- [resisted:full/partial] - OR logic for multiple types
    -- [resisted:法术名] / [resisted:full:法术名] - 按被抵抗的法术匹配（法术名或法术ID）
    --   新增：法术维度由 Nampower SPELL_MISS_SELF 的 spellId / 战斗日志解析提供 by 武藤纯子酱 2026.8.31
    -- Examples: [resisted] [@target,resisted:full] [resisted:partial] [resisted:献祭] [resisted:full:献祭]
    resisted = function(conditionals)
        -- If no specific resist type, check for ANY resist on current target
        if not conditionals.resisted or
           conditionals.resisted == true or
           (type(conditionals.resisted) == "table" and table.getn(conditionals.resisted) == 0) or type(conditionals.resisted) == "string" then -- 修复当没有后缀时候同时判定full/partial by 武藤纯子酱 2025.12.25（原误查 noresisted 键，裸写 [resisted] 恒 false）
            return CleveRoids.CheckResistState(nil)
        end

        -- Check for specific resist type(s)/spell - OR logic
        -- 值格式："full" / "partial" / "法术名" / "full:法术名"（解析器把多段冒号参数并回 args）by 武藤纯子酱 2026.8.31
        return Multi(conditionals.resisted, function(resistArg)
            -- 用 plain find 拆分（兼容 Lua 5.0，不用 string.match）by 武藤纯子酱 2026.8.31
            local t, sp = tostring(resistArg), ""
            local colon = string.find(t, ":", 1, true)
            if colon then
                sp = string.sub(t, colon + 1)
                t = string.sub(t, 1, colon - 1)
            end
            t = CleveRoids.Trim(t)
            sp = CleveRoids.Trim(sp)
            if t == "full" or t == "partial" then
                return CleveRoids.CheckResistState(t, sp ~= "" and sp or nil)
            end
            -- 非类型前缀：整个值视为法术名/ID
            return CleveRoids.CheckResistState(nil, t .. (sp ~= "" and (":" .. sp) or ""))
        end, conditionals, "resisted")
    end,

    -- [noresisted] - Check if last spell was NOT resisted by current target
    -- [noresisted:type] - Check target does NOT have specific resist type
    -- [noresisted:full/partial] - AND logic: not full AND not partial
    -- [noresisted:法术名] / [noresisted:full:法术名] - 按被抵抗的法术匹配（取反）by 武藤纯子酱 2026.8.31
    noresisted = function(conditionals)
        -- If no specific resist type, check for NO resist on current target
        if not conditionals.noresisted or
           conditionals.noresisted == true or
           (type(conditionals.noresisted) == "table" and table.getn(conditionals.noresisted) == 0) or type(conditionals.noresisted) == "string" then -- 修复当没有后缀时候同时判定full/partial by 武藤纯子酱 2025.12.25
            return not CleveRoids.CheckResistState(nil)
        end

        -- Check for absence of specific resist type(s)/spell - AND logic
        return NegatedMulti(conditionals.noresisted, function(resistArg)
            -- 用 plain find 拆分（兼容 Lua 5.0）by 武藤纯子酱 2026.8.31
            local t, sp = tostring(resistArg), ""
            local colon = string.find(t, ":", 1, true)
            if colon then
                sp = string.sub(t, colon + 1)
                t = string.sub(t, 1, colon - 1)
            end
            t = CleveRoids.Trim(t)
            sp = CleveRoids.Trim(sp)
            if t == "full" or t == "partial" then
                return not CleveRoids.CheckResistState(t, sp ~= "" and sp or nil)
            end
            return not CleveRoids.CheckResistState(nil, t .. (sp ~= "" and (":" .. sp) or ""))
        end, conditionals, "noresisted")
    end,

    -- ========================================================================
    -- EXACT NAME MATCHING CONDITIONALS
    -- ========================================================================

    -- [name:UnitName] - Check if target's name EXACTLY matches (case-insensitive)
    -- Unlike /target which fuzzy-matches, this requires an exact match
    -- Supports underscores for spaces: [name:Onyxia] or [name:Kor_kron_Elite]
    -- Multi-value OR: [name:Onyxia/Nefarian] = Onyxia OR Nefarian
    -- Examples: [name:Onyxia] [@focus,name:Ragnaros] [name:"Kor'kron Elite"]
    name = function(conditionals)
        local target = conditionals.target or "target"

        -- Unit must exist
        if not UnitExists(target) then
            return false
        end

        local unitName = UnitName(target)
        if not unitName then
            return false
        end

        -- Lowercase for case-insensitive comparison
        local unitNameLower = string.lower(unitName)

        -- Check for exact match with any provided name (OR logic)
        return Or(conditionals.name, function(requiredName)
            if type(requiredName) ~= "string" then return false end -- 表值防护（NormalizeName 内部 gsub 非字符串会崩溃）by 武藤纯子酱 2026.9.9
            -- Normalize underscores to spaces and lowercase
            local normalizedRequired = string.lower(CleveRoids.NormalizeName(requiredName))
            return unitNameLower == normalizedRequired
        end)
    end,

    -- [noname:UnitName] - Check if target's name does NOT match (case-insensitive)
    -- Uses AND logic: [noname:Onyxia/Nefarian] = not Onyxia AND not Nefarian
    -- Examples: [noname:Onyxia] [@mouseover,noname:"Training Dummy"]
    noname = function(conditionals)
        local target = conditionals.target or "target"

        -- No unit = no name = passes the "not this name" check
        if not UnitExists(target) then
            return true
        end

        local unitName = UnitName(target)
        if not unitName then
            return true
        end

        -- Lowercase for case-insensitive comparison
        local unitNameLower = string.lower(unitName)

        -- Check that name does NOT match any provided name (AND logic - must not match ALL)
        return NegatedMulti(conditionals.noname, function(forbiddenName)
            if type(forbiddenName) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            -- Normalize underscores to spaces and lowercase
            local normalizedForbidden = string.lower(CleveRoids.NormalizeName(forbiddenName))
            return unitNameLower ~= normalizedForbidden
        end, conditionals, "noname")
    end,

    -- ========================================================================
    -- AUTO-ATTACK CONDITIONALS (Nampower v2.24+)
    -- ========================================================================
    -- Requires NP_EnableAutoAttackEvents=1 CVar

    -- [lastswing:type] - Check result of player's last melee swing
    -- Types: crit, glancing, miss, dodge, parry, blocked, offhand/oh, mainhand/mh, hit
    -- Time check: [lastswing:<2] = last swing was within 2 seconds
    -- Multi-value: [lastswing:crit/glancing] = was crit OR glancing (OR logic)
    -- Examples: [lastswing:dodge] [@target,lastswing:crit] [lastswing:offhand]
    lastswing = function(conditionals)
        -- Boolean form [lastswing] - any recent swing
        if not conditionals.lastswing or
           conditionals.lastswing == true or
           (type(conditionals.lastswing) == "table" and table.getn(conditionals.lastswing) == 0) then
            return CleveRoids.ValidateLastSwing(nil, nil, nil)
        end

        -- Check for specific swing type(s) - OR logic
        return Or(conditionals.lastswing, function(args)
            if type(args) == "string" then
                return CleveRoids.ValidateLastSwing(args, nil, nil)
            elseif type(args) == "table" then
                return CleveRoids.ValidateLastSwing(args.name, args.operator, args.amount)
            end
            return false
        end)
    end,

    -- [nolastswing:type] - Check that last swing was NOT a specific type
    -- Uses AND logic: [nolastswing:crit/glancing] = was NOT crit AND NOT glancing
    nolastswing = function(conditionals)
        -- Boolean form [nolastswing] - no recent swing
        if not conditionals.nolastswing or
           conditionals.nolastswing == true or
           (type(conditionals.nolastswing) == "table" and table.getn(conditionals.nolastswing) == 0) then
            return not CleveRoids.ValidateLastSwing(nil, nil, nil)
        end

        -- Check that swing was NOT any of the specified types - AND logic
        return NegatedMulti(conditionals.nolastswing, function(args)
            if type(args) == "string" then
                return not CleveRoids.ValidateLastSwing(args, nil, nil)
            elseif type(args) == "table" then
                return not CleveRoids.ValidateLastSwing(args.name, args.operator, args.amount)
            end
            return true
        end, conditionals, "nolastswing")
    end,

    -- [incominghit:type] - Check result of last attack received by player
    -- Types: crit, crushing, glancing, miss, dodge, parry, blocked, hit
    -- Time check: [incominghit:<1] = received hit within last 1 second
    -- Examples: [incominghit:crushing] [incominghit:crit/crushing] [incominghit:dodge]
    incominghit = function(conditionals)
        -- Boolean form [incominghit] - any recent incoming hit
        if not conditionals.incominghit or
           conditionals.incominghit == true or
           (type(conditionals.incominghit) == "table" and table.getn(conditionals.incominghit) == 0) then
            return CleveRoids.ValidateIncomingHit(nil, nil, nil)
        end

        -- Check for specific hit type(s) - OR logic
        return Or(conditionals.incominghit, function(args)
            if type(args) == "string" then
                return CleveRoids.ValidateIncomingHit(args, nil, nil)
            elseif type(args) == "table" then
                return CleveRoids.ValidateIncomingHit(args.name, args.operator, args.amount)
            end
            return false
        end)
    end,

    -- [noincominghit:type] - Check that last incoming hit was NOT a specific type
    noincominghit = function(conditionals)
        -- Boolean form [noincominghit] - no recent incoming hit
        if not conditionals.noincominghit or
           conditionals.noincominghit == true or
           (type(conditionals.noincominghit) == "table" and table.getn(conditionals.noincominghit) == 0) then
            return not CleveRoids.ValidateIncomingHit(nil, nil, nil)
        end

        -- Check that hit was NOT any of the specified types - AND logic
        return NegatedMulti(conditionals.noincominghit, function(args)
            if type(args) == "string" then
                return not CleveRoids.ValidateIncomingHit(args, nil, nil)
            elseif type(args) == "table" then
                return not CleveRoids.ValidateIncomingHit(args.name, args.operator, args.amount)
            end
            return true
        end, conditionals, "noincominghit")
    end,

    -- ========================================================================
    -- AURA CAP CONDITIONALS (Nampower v2.20+ with AURA_CAST events)
    -- ========================================================================
    -- Requires NP_EnableAuraCastEvents=1 CVar for accurate tracking
    -- Falls back to manual counting if events unavailable

    -- [mybuffcapped] - Player's buff bar is at capacity (32 buffs)
    -- Usage: [mybuffcapped] to prevent buff waste
    mybuffcapped = function(conditionals)
        return CleveRoids.IsPlayerBuffCapped()
    end,

    -- [nomybuffcapped] - Player's buff bar has room
    nomybuffcapped = function(conditionals)
        return not CleveRoids.IsPlayerBuffCapped()
    end,

    -- [mydebuffcapped] - Player's debuff bar is at capacity (16 debuffs)
    mydebuffcapped = function(conditionals)
        return CleveRoids.IsPlayerDebuffCapped()
    end,

    -- [nomydebuffcapped] - Player's debuff bar has room
    nomydebuffcapped = function(conditionals)
        return not CleveRoids.IsPlayerDebuffCapped()
    end,

    -- [debuffcapped] - Target's debuff bar is at capacity
    -- For NPCs: 16 debuff slots (+ 32 overflow into buff slots = 48 visual total)
    -- Usage: [debuffcapped] to stop DoT spam when target is capped
    debuffcapped = function(conditionals)
        local target = conditionals.target or "target"
        return CleveRoids.IsTargetDebuffCapped(target)
    end,

    -- [nodebuffcapped] - Target's debuff bar has room
    nodebuffcapped = function(conditionals)
        local target = conditionals.target or "target"
        return not CleveRoids.IsTargetDebuffCapped(target)
    end,

    -- [buffcapped] - Target's buff bar is at capacity (32 buffs)
    buffcapped = function(conditionals)
        local target = conditionals.target or "target"
        return CleveRoids.IsTargetBuffCapped(target)
    end,

    -- [nobuffcapped] - Target's buff bar has room
    nobuffcapped = function(conditionals)
        local target = conditionals.target or "target"
        return not CleveRoids.IsTargetBuffCapped(target)
    end,

    -- =========================================================================
    -- MOVEMENT SPEED CONDITIONALS (MonkeySpeed integration)
    -- =========================================================================
    -- [moving] - Player is moving (speed > 0)
    -- [moving:>100] - Player speed is above 100% (faster than normal run)
    -- [moving:<50] - Player speed is below 50% (slower than half speed)
    -- Requires MonkeySpeed addon for speed comparisons (basic moving check uses fallback)
    moving = function(conditionals)
        -- Boolean form [moving] - just check if moving at all
        if conditionals.moving == true then
            return CleveRoids.IsPlayerMoving()
        end

        -- Operator form [moving:>100] - check speed percentage
        return Multi(conditionals.moving, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<150)
            if args.comparisons and type(args.comparisons) == "table" then
                local speed = CleveRoids.GetPlayerSpeed()
                if speed == nil then
                    CleveRoids.RequireMonkeySpeed("moving speed comparison")
                    return false
                end

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](speed, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateMovingSpeed(args.operator, args.amount)
        end, conditionals, "moving")
    end,

    -- [nomoving] - Player is NOT moving (speed == 0)
    -- [nomoving:>100] - Player speed is NOT above 100% (at or below normal run)
    nomoving = function(conditionals)
        -- Boolean form [nomoving] - check if NOT moving
        if conditionals.nomoving == true then
            return not CleveRoids.IsPlayerMoving()
        end

        -- Operator form [nomoving:>100] - negate speed comparison
        return NegatedMulti(conditionals.nomoving, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local speed = CleveRoids.GetPlayerSpeed()
                if speed == nil then
                    -- If MonkeySpeed not available, negated returns true (fail-safe)
                    return true
                end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](speed, comp.amount) then
                        return true
                    end
                end
                return false
            end

            return not CleveRoids.ValidateMovingSpeed(args.operator, args.amount)
        end, conditionals, "nomoving")
    end,


    -- =========================================================================
    -- ALIASES — short forms for commonly-used conditionals to save macro chars
    -- =========================================================================

    -- cd / nocd → cooldown / nocooldown (saves 6/8 chars)
    cd = function(conditionals)
        return Multi(conditionals.cd, function(v)
            return CleveRoids.ValidateCooldown(v, true)
        end, conditionals, "cd")
    end,
    nocd = function(conditionals)
        return NegatedMulti(conditionals.nocd, function(v)
            return not CleveRoids.ValidateCooldown(v, true)
        end, conditionals, "nocd")
    end,

    -- react / noreact → reactive / noreactive (saves 3/5 chars)
    react = function(conditionals)
        return Multi(conditionals.react, function(v)
            return CleveRoids.IsReactiveUsable(v)
        end, conditionals, "react")
    end,
    noreact = function(conditionals)
        return NegatedMulti(conditionals.noreact, function(v)
            return not CleveRoids.IsReactiveUsable(v)
        end, conditionals, "noreact")
    end,

    -- chan / nochan → channeled / nochanneled (saves 5/7 chars)
    chan = function(conditionals)
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then return false end
        end
        return CleveRoids.CurrentSpell.type == "channeled"
    end,
    nochan = function(conditionals)
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then return true end
        end
        return CleveRoids.CurrentSpell.type ~= "channeled"
    end,

    -- eq / noeq → equipped / noequipped (saves 6/8 chars)
    eq = function(conditionals)
        local itemsToCheck
        if type(conditionals.eq) == "string" then
            itemsToCheck = conditionals.eq
        elseif type(conditionals.eq) == "table" and table.getn(conditionals.eq) > 0 then
            itemsToCheck = conditionals.eq
        elseif conditionals.action then
            itemsToCheck = conditionals.action
        else
            return false
        end
        return Multi(itemsToCheck, function(v) -- 新增同时支持/和& by 武藤纯子酱 2026.3.29
            return (CleveRoids.HasWeaponEquipped(v) or CleveRoids.HasGearEquipped(v))
        end, conditionals, "eq") -- 新增同时支持/和& by 武藤纯子酱 2026.3.29
    end,
    noeq = function(conditionals)
        local itemsToCheck
        if type(conditionals.noeq) == "string" then
            itemsToCheck = conditionals.noeq
        elseif type(conditionals.noeq) == "table" and table.getn(conditionals.noeq) > 0 then
            itemsToCheck = conditionals.noeq
        elseif conditionals.action then
            itemsToCheck = conditionals.action
        else
            return false
        end
        return NegatedMulti(itemsToCheck, function(v) -- 新增同时支持/和& by 武藤纯子酱 2026.3.29
            return not (CleveRoids.HasWeaponEquipped(v) or CleveRoids.HasGearEquipped(v))
        end, conditionals, "noeq") -- 新增同时支持/和& by 武藤纯子酱 2026.3.29
    end,

    -- dist / nodist → distance / nodistance (saves 4/6 chars)
    dist = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end
        return Multi(conditionals.dist, function(args)
            if type(args) ~= "table" or not args.operator or not args.amount then
                return false
            end

            -- Count mode: name encodes distance threshold + optional filter + optional baseUnit
            local filter, distThreshold, baseUnit = ParseCountModeFilter(args.name, conditionals.action)
            if distThreshold then
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if not dist or dist > distThreshold then return false end
                    if filter and not filter(unit, baseUnit) then return false end
                    return true
                end, baseUnit)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- 单目标基准单位：若 args.name 等于 action（即未显式指定）则默认 player
            local singleBaseUnit = args.name
            if not CleveRoids.IsValidUnitToken(singleBaseUnit) or singleBaseUnit == conditionals.action then
                singleBaseUnit = "player"
            end

            -- Single-target: [dist:<30]
            local unit = conditionals.target or "target"
            if not UnitExists(unit) then return false end

            local distance = CleveRoids.SafeUnitXP("distanceBetween", singleBaseUnit, unit)
            if not distance then return false end

            return CleveRoids.comparators[args.operator](distance, args.amount)
        end, conditionals, "dist")
    end,
    nodist = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end
        return NegatedMulti(conditionals.nodist, function(args)
            if type(args) ~= "table" or not args.operator or not args.amount then
                return false
            end

            -- Count mode: name encodes distance threshold + optional filter + optional baseUnit
            local filter, distThreshold, baseUnit = ParseCountModeFilter(args.name, conditionals.action)
            if distThreshold then
                local count = CleveRoids.CountEnemiesMatching(function(unit)
                    local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                    if dist and dist <= distThreshold then return false end
                    if filter and not filter(unit, baseUnit) then return false end
                    return true
                end, baseUnit)
                return CleveRoids.comparators[args.operator](count, args.amount)
            end

            -- 单目标基准单位：若 args.name 等于 action（即未显式指定）则默认 player
            local singleBaseUnit = args.name
            if not CleveRoids.IsValidUnitToken(singleBaseUnit) or singleBaseUnit == conditionals.action then
                singleBaseUnit = "player"
            end

            -- Single-target: [nodist:<30]
            local unit = conditionals.target or "target"
            if not UnitExists(unit) then return false end

            local distance = CleveRoids.SafeUnitXP("distanceBetween", singleBaseUnit, unit)
            if not distance then return false end

            return not CleveRoids.comparators[args.operator](distance, args.amount)
        end, conditionals, "nodist")
    end,

    -- melee / nomelee → meleerange / nomeleerange (saves 5/7 chars)
    melee = function(conditionals)
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.melee)
        if countArgs then
            local filter, _, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if not CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit) then return false end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.melee) == "string" then
            baseUnit = conditionals.melee
        elseif type(conditionals.melee) == "table" and table.getn(conditionals.melee) > 0 then
            baseUnit = conditionals.melee[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit)
    end,
    nomelee = function(conditionals)
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.nomelee)
        if countArgs then
            local filter, _, baseUnit = ParseCountModeFilter(countArgs.name, conditionals.action)
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit) then return false end
                if filter and not filter(unit, baseUnit) then return false end
                return true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.nomelee) == "string" then
            baseUnit = conditionals.nomelee
        elseif type(conditionals.nomelee) == "table" and table.getn(conditionals.nomelee) > 0 then
            baseUnit = conditionals.nomelee[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return true end
        return not CleveRoids.IsUnitInMeleeRange(unit, true, baseUnit)
    end,

    -- mv / nomv → moving / nomoving (saves 4/6 chars)
    mv = function(conditionals)
        if conditionals.mv == true then
            return CleveRoids.IsPlayerMoving()
        end
        return Multi(conditionals.mv, function(args)
            if type(args) ~= "table" then return false end
            if args.comparisons and type(args.comparisons) == "table" then
                local speed = CleveRoids.GetPlayerSpeed()
                if speed == nil then return false end
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return false end
                    if not CleveRoids.comparators[comp.operator](speed, comp.amount) then return false end
                end
                return true
            end
            return CleveRoids.ValidateMovingSpeed(args.operator, args.amount)
        end, conditionals, "mv")
    end,
    nomv = function(conditionals)
        if conditionals.nomv == true then
            return not CleveRoids.IsPlayerMoving()
        end
        return NegatedMulti(conditionals.nomv, function(args)
            if type(args) ~= "table" then return false end
            if args.comparisons and type(args.comparisons) == "table" then
                local speed = CleveRoids.GetPlayerSpeed()
                if speed == nil then return true end
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return true end
                    if not CleveRoids.comparators[comp.operator](speed, comp.amount) then return true end
                end
                return false
            end
            return not CleveRoids.ValidateMovingSpeed(args.operator, args.amount)
        end, conditionals, "nomv")
    end,

    -- sct / nosct → spellcasttime / nospellcasttime (saves 10/12 chars)
    sct = function(conditionals)
        local check = conditionals.sct
        if type(check) == "table" and type(check[1]) == "table" then check = check[1] end
        if type(check) == "table" and check.operator and check.amount then
            local spellName = check.name
            if not spellName or spellName == "" then spellName = conditionals.action end
            return CleveRoids.ValidateSpellCastTime(spellName, check.operator, check.amount)
        end
        return false
    end,
    nosct = function(conditionals)
        local check = conditionals.nosct
        if type(check) == "table" and type(check[1]) == "table" then check = check[1] end
        if type(check) == "table" and check.operator and check.amount then
            local spellName = check.name
            if not spellName or spellName == "" then spellName = conditionals.action end
            return not CleveRoids.ValidateSpellCastTime(spellName, check.operator, check.amount)
        end
        return true
    end,

    -- ct / noct → selfcasttime / noselfcasttime (saves 6/8 chars)
    mct = function(conditionals) -- 为了避免冲突，将ct改为mct by 武藤纯子酱 2026.3.29
        local timeLeft = 0
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local elapsed = GetTime() - CleveRoids.castStartTime
            timeLeft = CleveRoids.castDuration - elapsed
            if timeLeft < 0 then timeLeft = 0 end
        end
        local check = conditionals.mct -- 修复：改名后仍读旧键 ct，导致 [mct:X] 恒 false by 武藤纯子酱 2026.8.31
        if type(check) == "table" and type(check[1]) == "table" then check = check[1] end
        if type(check) == "table" and check.operator and check.amount then
            return CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end
        return false
    end,
    nomct = function(conditionals) -- 为了避免冲突，将noct改为nomct by 武藤纯子酱 2026.3.29
        local timeLeft = 0
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local elapsed = GetTime() - CleveRoids.castStartTime
            timeLeft = CleveRoids.castDuration - elapsed
            if timeLeft < 0 then timeLeft = 0 end
        end
        local check = conditionals.nomct -- 修复：改名后仍读旧键 noct by 武藤纯子酱 2026.8.31
        if type(check) == "table" and type(check[1]) == "table" then check = check[1] end
        if type(check) == "table" and check.operator and check.amount then
            return not CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end
        return true
    end,

    -- chtime / nochtime → selfchanneltime / noselfchanneltime (saves 5/5 chars)
    schtime = function(conditionals) -- 为了避免冲突，将selfchanneltime改为schtime by 武藤纯子酱 2026.3.29
        local timeLeft = 0
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local elapsed = GetTime() - CleveRoids.channelStartTime
            timeLeft = CleveRoids.channelDuration - elapsed
            if timeLeft < 0 then timeLeft = 0 end
        end
        local check = conditionals.schtime -- 修复：改名后仍读旧键 chtime by 武藤纯子酱 2026.8.31
        if type(check) == "table" and type(check[1]) == "table" then check = check[1] end
        if type(check) == "table" and check.operator and check.amount then
            return CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end
        return false
    end,
    noschtime = function(conditionals) -- 为了避免冲突，将noselfchanneltime改为noschtime by 武藤纯子酱 2026.3.29
        local timeLeft = 0
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local elapsed = GetTime() - CleveRoids.channelStartTime
            timeLeft = CleveRoids.channelDuration - elapsed
            if timeLeft < 0 then timeLeft = 0 end
        end
        local check = conditionals.noschtime -- 修复：改名后仍读旧键 nochtime by 武藤纯子酱 2026.8.31
        if type(check) == "table" and type(check[1]) == "table" then check = check[1] end
        if type(check) == "table" and check.operator and check.amount then
            return not CleveRoids.comparators[check.operator](timeLeft, check.amount)
        end
        return true
    end,

    -- tgt / notgt → targeting / notargeting (saves 6/8 chars)
    tgt = function(conditionals) -- 修复 by 武藤纯子酱 2026.3.29
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            return false
        end
        
        if not UnitExists(conditionals.target.."target") then
            return false
        end

        local target = conditionals.target or "target"

        -- Handle single "tank" keyword directly (most common case)
        local val = conditionals.tgt
        if val == "tank" or (type(val) == "table" and val[1] == "tank" and not val[2]) then
            return CleveRoids.IsTargetingAnyTank(target)
        end

        return Or(val, function (unit)
            if not unit or unit == conditionals.action then
                if UnitExists(conditionals.target.."target") then
                    return true
                else
                    return false
                end
            end

            if unit == "tank" then
                return CleveRoids.IsTargetingAnyTank(target)
            end
            return (UnitIsUnit(target .. "target", unit) == 1)
        end)
    end,
    notgt = function(conditionals) -- 修复 by 武藤纯子酱 2026.3.29
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            -- 修复：严格取反——无目标时正向 tgt=false，notgt 应为 true（与 nohelp/noharm 一致） by 武藤纯子酱 2026.9.12
            return true
        end
        
        if not UnitExists(conditionals.target.."target") then
            return true
        end

        local target = conditionals.target or "target"

        -- Handle single "tank" keyword directly (most common case)
        local val = conditionals.notgt
        if val == "tank" or (type(val) == "table" and val[1] == "tank" and not val[2]) then
            return not CleveRoids.IsTargetingAnyTank(target)
        end

        return NegatedMulti(val, function (unit)
            if not unit or unit == conditionals.action then
                if UnitExists(conditionals.target.."target") then
                    return false
                else
                    return true
                end
            end

            if unit == "tank" then
                return not CleveRoids.IsTargetingAnyTank(target)
            end
            return UnitIsUnit(target .. "target", unit) ~= 1
        end, conditionals, "notgt")
    end,

    -- los / nolos → insight / noinsight (saves 4/6 chars)
    los = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        -- Check for count mode: [los:>1]
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.los)
        if countArgs then
            local baseUnit = countArgs.name or "player"
            if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then baseUnit = "player" end
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) == true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.los) == "string" then
            baseUnit = conditionals.los
        elseif type(conditionals.los) == "table" and table.getn(conditionals.los) > 0 then
            baseUnit = conditionals.los[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) == true
    end,
    nolos = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end

        -- Check for count mode: [nolos:>1]
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.nolos)
        if countArgs then
            local baseUnit = countArgs.name or "player"
            if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then baseUnit = "player" end
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) ~= true
            end, baseUnit)
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        -- 单目标基准单位：若未显式指定或为 action 则默认 player
        local baseUnit = "player"
        if type(conditionals.nolos) == "string" then
            baseUnit = conditionals.nolos
        elseif type(conditionals.nolos) == "table" and table.getn(conditionals.nolos) > 0 then
            baseUnit = conditionals.nolos[1]
        end
        if not CleveRoids.IsValidUnitToken(baseUnit) or baseUnit == conditionals.action then
            baseUnit = "player"
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("inSight", baseUnit, unit) ~= true
    end,

    -- queued / noqueued → queuedspell / noqueuedspell (saves 5/7 chars)
    queued = function(conditionals)
        if not CleveRoids.hasNampower then return false end
        if not CleveRoids.queuedSpell then return false end
        if not conditionals.queued or (type(conditionals.queued) == "table" and table.getn(conditionals.queued) == 0) then
            return true
        end
        return Or(conditionals.queued, function(spellName)
            if type(spellName) ~= "string" then return false end -- 修复：非字符串时 StripRank 返回 nil → string.lower(nil) 抛错 by 武藤纯子酱 2026.9.12
            if not CleveRoids.queuedSpell.spellName then return false end
            local queuedName = CleveRoids.StripRank(CleveRoids.queuedSpell.spellName) -- 修复多语言支持 by 武藤纯子酱 2026.3.29
            local checkName = CleveRoids.StripRank(spellName) -- 修复多语言支持 by 武藤纯子酱 2026.3.29
            return string.lower(queuedName) == string.lower(checkName)
        end)
    end,
    noqueued = function(conditionals)
        if not CleveRoids.hasNampower then return false end
        if not conditionals.noqueued or (type(conditionals.noqueued) == "table" and table.getn(conditionals.noqueued) == 0) then
            return CleveRoids.queuedSpell == nil
        end
        if not CleveRoids.queuedSpell or not CleveRoids.queuedSpell.spellName then return true end
        return NegatedMulti(conditionals.noqueued, function(spellName)
            if type(spellName) ~= "string" then return false end -- 修复：非字符串时 StripRank 返回 nil → string.lower(nil) 抛错 by 武藤纯子酱 2026.9.12
            local queuedName = CleveRoids.StripRank(CleveRoids.queuedSpell.spellName) -- 修复多语言支持 by 武藤纯子酱 2026.3.29
            local checkName = CleveRoids.StripRank(spellName) -- 修复多语言支持 by 武藤纯子酱 2026.3.29
            return string.lower(queuedName) ~= string.lower(checkName)
        end, conditionals, "noqueued")
    end,

    -- swim / noswim → swimming / noswimming (saves 4/6 chars)
    swim = function(conditionals)
        if not CleveRoids.NampowerAPI.features.hasPlayerIsSwimming then
            if not CleveRoids._swimmingErrorShown then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swimming] conditional requires Nampower v2.36.0 or newer.", 1, 0.5, 0.5)
                CleveRoids._swimmingErrorShown = true
            end
            return false
        end
        return PlayerIsSwimming() == 1
    end,
    noswim = function(conditionals)
        if not CleveRoids.NampowerAPI.features.hasPlayerIsSwimming then
            if not CleveRoids._swimmingErrorShown then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The [swimming] conditional requires Nampower v2.36.0 or newer.", 1, 0.5, 0.5)
                CleveRoids._swimmingErrorShown = true
            end
            return false
        end
        return PlayerIsSwimming() ~= 1
    end,

    -- osp / noosp → onswingpending / noonswingpending (saves 11/13 chars)
    osp = function(conditionals)
        if not GetCurrentCastingInfo then return false end
        local _, _, _, _, _, onswing = GetCurrentCastingInfo()
        return onswing == 1
    end,
    noosp = function(conditionals)
        if not GetCurrentCastingInfo then return true end
        local _, _, _, _, _, onswing = GetCurrentCastingInfo()
        return onswing ~= 1
    end,

    -- ihit / noihit → incominghit / noincominghit (saves 7/9 chars)
    ihit = function(conditionals)
        if not conditionals.ihit or conditionals.ihit == true or
           (type(conditionals.ihit) == "table" and table.getn(conditionals.ihit) == 0) then
            return CleveRoids.ValidateIncomingHit(nil, nil, nil)
        end
        return Or(conditionals.ihit, function(args)
            if type(args) == "string" then
                return CleveRoids.ValidateIncomingHit(args, nil, nil)
            elseif type(args) == "table" then
                return CleveRoids.ValidateIncomingHit(args.name, args.operator, args.amount)
            end
            return false
        end)
    end,
    noihit = function(conditionals)
        if not conditionals.noihit or conditionals.noihit == true or
           (type(conditionals.noihit) == "table" and table.getn(conditionals.noihit) == 0) then
            return not CleveRoids.ValidateIncomingHit(nil, nil, nil)
        end
        return NegatedMulti(conditionals.noihit, function(args)
            if type(args) == "string" then
                return not CleveRoids.ValidateIncomingHit(args, nil, nil)
            elseif type(args) == "table" then
                return not CleveRoids.ValidateIncomingHit(args.name, args.operator, args.amount)
            end
            return true
        end, conditionals, "noihit")
    end,

    -- scast / noscast → selfcasting / noselfcasting (saves 6/8 chars)
    scast = function(conditionals)
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local remaining = CleveRoids.castDuration - (GetTime() - CleveRoids.castStartTime)
            if remaining <= 0.1 then return false end
        end
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then return false end
        end
        return CleveRoids.CurrentSpell.type == "cast" or CleveRoids.CurrentSpell.type == "channeled"
    end,
    noscast = function(conditionals)
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local remaining = CleveRoids.castDuration - (GetTime() - CleveRoids.castStartTime)
            if remaining <= 0.1 then return true end
        end
        if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
            local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
            if remaining <= 0.1 then return true end
        end
        return CleveRoids.CurrentSpell.type ~= "cast" and CleveRoids.CurrentSpell.type ~= "channeled"
    end,

    -- stl / nostl → stealth / nostealth (saves 4/6 chars)
    stl = function(conditionals)
        return (
            (CleveRoids.playerClass == "ROGUE" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Stealth"]))
            or (CleveRoids.playerClass == "DRUID" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Prowl"]))
        )
    end,
    nostl = function(conditionals)
        -- 修复：同 nostealth，非盗贼/德鲁伊恒 false 的问题 by 武藤纯子酱 2026.8.31
        return not (
            (CleveRoids.playerClass == "ROGUE" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Stealth"]))
            or (CleveRoids.playerClass == "DRUID" and CleveRoids.ValidatePlayerBuff(CleveRoids.Localized.Spells["Prowl"]))
        )
    end,

    -- ic / ooc → combat / nocombat (saves 4/5 chars)
    ic = function(conditionals)
        -- Check if an argument like :target or :focus was provided. The parser turns this into a table.
        -- 修复：带参数时解析器把值存到 conditionals.ic，原代码查的是 conditionals.combat（复制粘贴错误） by 武藤纯子酱 2026.8.31
        if type(conditionals.ic) == "table" then
            -- If so, run the check on the provided unit(s).
            return Multi(conditionals.ic, function(unit)
                unit = ResolveFocusUnit(unit)
                if not unit then return false end
                if UnitExists(unit) and UnitAffectingCombat(unit) and UnitExists(conditionals.target or "target") then -- 如果有条件单位，则需要同时判断测试目标和条件单位是否都进入战斗 by 武藤纯子酱 2025.11.27
                    return UnitAffectingCombat(conditionals.target)
                else
                    return UnitExists(unit) and UnitAffectingCombat(unit)
                end
            end, conditionals, "ic")
        else
            -- Otherwise, this is a bare [combat]. The value might be 'true' or a spell name.
            -- PERFORMANCE: Use event-driven cache for player combat state
            local cached = CleveRoids._cachedPlayerInCombat
            if cached ~= nil then
                if UnitExists(conditionals.target or "target") then -- 如果有条件单位，则需要同时判断玩家和条件单位是否都进入战斗 by 武藤纯子酱 2025.11.27
                    return ( cached or UnitAffectingCombat("player") ) and UnitAffectingCombat(conditionals.target)
                else
                    return cached or UnitAffectingCombat("player")
                end
            end
            -- Fallback if cache not yet initialized
            if UnitAffectingCombat("player") and UnitExists(conditionals.target or "target") then -- 如果有条件单位，则需要同时判断玩家和条件单位是否都进入战斗 by 武藤纯子酱 2025.11.27
                return UnitAffectingCombat(conditionals.target)
            else
                return UnitAffectingCombat("player")
            end
        end
    end,
    ooc = function(conditionals)
        -- Check if an argument like :target or :focus was provided.
        -- 修复：带参数时解析器把值存到 conditionals.ooc，原代码查的是 conditionals.nocombat（复制粘贴错误） by 武藤纯子酱 2026.8.31
        if type(conditionals.ooc) == "table" then
            -- If so, run the check on the provided unit(s).
            return NegatedMulti(conditionals.ooc, function(unit)
                unit = ResolveFocusUnit(unit)
                if not unit or not UnitExists(unit) then return true end
                return not UnitAffectingCombat(unit)
            end, conditionals, "ooc")
        else
            -- Otherwise, this is a bare [nocombat]. Default to checking the player.
            -- PERFORMANCE: Use event-driven cache for player combat state
            local cached = CleveRoids._cachedPlayerInCombat
            if cached ~= nil then
                return not cached or not UnitAffectingCombat("player") -- 优化，需要同时判断玩家没有被禁止恢复及没有仇恨 by 武藤纯子酱 2026.2.4
            end
            -- Fallback if cache not yet initialized
            return not UnitAffectingCombat("player")
        end
    end,

    --新增 by 武藤纯子酱 2025.11.27
    
    move = function(conditionals)    
        -- Boolean form [move] - just check if move at all
        if conditionals.move == true then
            return CleveRoids.IsPlayerMoving()
        end

        -- Operator form [move:>100] - check speed percentage
        return Multi(conditionals.move, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<150)
            if args.comparisons and type(args.comparisons) == "table" then
                local speed = CleveRoids.GetPlayerSpeed()
                if speed == nil then
                    CleveRoids.RequireMonkeySpeed("moving speed comparison")
                    return false
                end

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](speed, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateMovingSpeed(args.operator, args.amount)
        end, conditionals, "move")
    end,

    nomove = function(conditionals)
        -- Boolean form [nomove] - check if NOT moving
        if conditionals.nomove == true then
            return not CleveRoids.IsPlayerMoving()
        end

        -- Operator form [nomove:>100] - negate speed comparison
        return NegatedMulti(conditionals.nomove, function(args)
            if type(args) ~= "table" then return false end

            if args.comparisons and type(args.comparisons) == "table" then
                local speed = CleveRoids.GetPlayerSpeed()
                if speed == nil then
                    -- If MonkeySpeed not available, negated returns true (fail-safe)
                    return true
                end

                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](speed, comp.amount) then
                        return true
                    end
                end
                return false
            end

            return not CleveRoids.ValidateMovingSpeed(args.operator, args.amount)
        end, conditionals, "nomove")
    end,

    channeling = function(conditionals)
        if type(conditionals.channeling) == "string" then
            -- Use time-based prediction for accuracy
            if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
                local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
                if remaining <= 0.1 then
                    return false -- Channel is done
                end
            end
            return CleveRoids.CurrentSpell.type == "channeled"
        else
            -- String form [channeling:SpellName] - check if channeling that spell
            return Multi(conditionals.channeling, function(channeledSpells)
                return not CleveRoids.CheckChanneled(channeledSpells)
            end, conditionals, "channeling")
        end
    end,

    nochanneling = function(conditionals)
        if type(conditionals.nochanneling) == "string" then
            -- Use time-based prediction for accuracy
            if CleveRoids.CurrentSpell.type == "channeled" and (CleveRoids.channelStartTime or 0) > 0 and (CleveRoids.channelDuration or 0) > 0 then
                local remaining = CleveRoids.channelDuration - (GetTime() - CleveRoids.channelStartTime)
                if remaining <= 0.1 then
                    return true -- Channel is done
                end
            end
            -- 修复：Nampower 排队环境下的"无限奥术飞弹"循环 by 武藤纯子酱 2026.9.9
            -- 场景：/cast 读条技 + /cast [nochanneling]引导技 两行宏，读条期间本条件
            -- 只挡"引导"不挡"读条"→ 引导技被排队，读条一结束立即弹出开始引导；
            -- 同时 CD 中的读条技也被排队（NP_QueueSpellsOnCooldown），两条排队在单槽
            -- 队列里互相顶替 → 引导技永远抢先、读条技永远排不上 → 无限引导循环。
            -- 修复：正在"读条"或有"Nampower 排队中的法术"时同样视为不可再引导——
            -- 与该条件的实际用途（防止施法叠加）一致
            -- 帧内护栏：本帧前一行 /cast 已发起施法/排队（SPELL_QUEUE_EVENT 帧末才派发，
            -- queuedSpell 此刻看不到），同样视为不可再引导 by 武藤纯子酱 2026.9.9
            if CleveRoids.CurrentSpell.type == "cast" then
                return false
            end
            if CleveRoids.queuedSpell then
                return false
            end
            if CleveRoids._castIssuedThisFrame then
                return false
            end
            return CleveRoids.CurrentSpell.type ~= "channeled"
        else
            -- String form [nochanneling:SpellName] - check if NOT channeling that spell
            -- 修复：CheckChanneled 本身就是"允许施放=未引导该法术"语义（返回 true 表示可以施放），
            -- 再取 not 就反转成了"正在引导才为 true"；NegatedMulti 不做额外取反，应直接传 CheckChanneled by 武藤纯子酱 2026.8.31
            -- 修复：与无参分支同源——读条中/已排队时同样视为"不可引导"，防止 [nochanneling:X]
            -- 在多行宏里把引导填充法术排队、顶掉 CD 技的排队槽位 by 武藤纯子酱 2026.9.9
            return NegatedMulti(conditionals.nochanneling, function(channeledSpells)
                if CleveRoids.CurrentSpell.type == "cast" or CleveRoids.queuedSpell or CleveRoids._castIssuedThisFrame then
                    return false
                end
                return CleveRoids.CheckChanneled(channeledSpells)
            end, conditionals, "nochanneling")
        end
    end,
    
    modifier = function(conditionals)
        -- 修复：读取 conditionals.modifier（解析器按 [modifier:...] 关键字名存 key），
        -- 原代码读 conditionals.mod 导致 [modifier:ctrl] 退化为"任意修饰键" by 武藤纯子酱 2026.8.31
        if type(conditionals.modifier) ~= "table" then
            return CleveRoids.kmods.mod()
        end
        return Or(conditionals.modifier, function(mod)
            if type(mod) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            mod = strlower(mod) -- 统一转换为小写 by 武藤纯子酱 2025.11.27
            local fn = CleveRoids.kmods[mod] -- 修复：非法修饰键不再 nil() 报错 by 武藤纯子酱 2026.8.31
            if not fn then return false end
            return fn()
        end)
    end,

    nomodifier = function(conditionals)
        if type(conditionals.nomodifier) ~= "table" then
            return CleveRoids.kmods.nomod()
        end
        return NegatedMulti(conditionals.nomodifier, function(mod)
            if type(mod) ~= "string" then return false end -- 表值防护 by 武藤纯子酱 2026.9.9
            mod = strlower(mod) -- 统一转换为小写 by 武藤纯子酱 2025.11.27
            local fn = CleveRoids.kmods[mod] -- 修复：非法修饰键不再 nil() 报错 by 武藤纯子酱 2026.8.31
            if not fn then return true end -- 修复：未知修饰键按严格取反处理（与 nokeydown 一致） by 武藤纯子酱 2026.9.12
            return not fn()
        end, conditionals, "nomodifier")
    end,

    btn1 = function() 
        return CleveRoids.MouseDown == "LeftButton" 
    end,
    
    btn2 = function() 
        return CleveRoids.MouseDown == "RightButton" 
    end,
    
    btn3 = function() 
        return CleveRoids.MouseDown == "MiddleButton" 
    end,
    
    btn4 = function() 
        return CleveRoids.MouseDown == "Button4" 
    end,
    
    btn5 = function() 
        return CleveRoids.MouseDown == "Button5" 
    end,

    button1 = function()    
        return CleveRoids.MouseDown == "LeftButton" 
    end,
    
    button2 = function() 
        return CleveRoids.MouseDown == "RightButton" 
    end,
    
    button3 = function() 
        return CleveRoids.MouseDown == "MiddleButton" 
    end,
    
    button4 = function() 
        return CleveRoids.MouseDown == "Button4" 
    end,
    
    button5 = function()    
        return CleveRoids.MouseDown == "Button5" 
    end,
    
    nobtn1 = function()
        return CleveRoids.MouseDown ~= "LeftButton" -- 修复：not x == y 优先级错误（解析为 (not x)==y 恒 false） by 武藤纯子酱 2026.8.31
    end,
    
    nobtn2 = function()
        return CleveRoids.MouseDown ~= "RightButton"
    end,

    nobtn3 = function()
        return CleveRoids.MouseDown ~= "MiddleButton"
    end,

    nobtn4 = function()
        return CleveRoids.MouseDown ~= "Button4" -- 修复：not x == y 优先级错误（解析为 (not x)==y 恒 false） by 武藤纯子酱 2026.8.31
    end,

    nobtn5 = function()
        return CleveRoids.MouseDown ~= "Button5"
    end,

    nobutton1 = function()
        return CleveRoids.MouseDown ~= "LeftButton"
    end,

    nobutton2 = function()
        return CleveRoids.MouseDown ~= "RightButton"
    end,

    nobutton3 = function()
        return CleveRoids.MouseDown ~= "MiddleButton"
    end,

    nobutton4 = function()
        return CleveRoids.MouseDown ~= "Button4"
    end,

    nobutton5 = function()
        return CleveRoids.MouseDown ~= "Button5"
    end,

    channeltime = function(conditionals)
        if (CleveRoids.channelStartTime or 0) <= 0 or CleveRoids.CurrentSpell.type ~= "channeled" then
            CleveRoids.channelStartTime = 0
            CleveRoids.channelDuration = 0
        end

        return Multi(conditionals.channeltime, function(arg)
            -- 解析参数
            local op, value, name, duration

            if arg.name ~= "start" and arg.name ~= "end" then
                name = "start"
            else
                name = arg.name
            end

            -- 未引导 → true（独立引导宏靠它“开始引导”）；引导中 → 用引导计时
            if CleveRoids.CurrentSpell.type ~= "channeled" then
                return true
            end
            if name == "start" then
                duration = GetTime() - CleveRoids.channelStartTime
            else
                duration = CleveRoids.channelStartTime + CleveRoids.channelDuration - GetTime()
            end

            -- 公式支持：数值位可写施法时间公式（如 getchannel(奥术飞弹)/6）by 武藤纯子酱 2026.9.1
            if arg.comparisons and type(arg.comparisons) == "table" then                
                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    op = comp.operator
                    value = ResolveConditionAmount(comp.amount)

                    -- 处理无效值
                    if not value or not op then return false end

                    -- 根据操作符比较距离
                    if CleveRoids.operators[op] and not CleveRoids.comparators[op](duration, value) then
                        return false
                    end    
                end
                return true
            end

            if type(arg) == "table" then
                op = arg.operator
                value = ResolveConditionAmount(arg.amount)
            end

            -- 处理无效值
            if not value or not op then return false end

            -- 根据操作符比较距离
            if CleveRoids.operators[op] then
                return CleveRoids.comparators[op](duration, value)
            end    
        end, conditionals, "channeltime")
    end,

    -- 主手攻击开始时间
    mhstarted = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return Multi(conditionals.mhstarted, function(arg)
            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](attackState.mhStarted, comp.amount) then
                        return false
                    end
                end
                return true
            end
            
            -- 原有单一比较
            local op = arg.operator or "<"
            local value = arg.amount; if value == nil then value = 0 end -- 保留公式字符串，由比较器包装层求值 by 武藤纯子酱 2026.9.24
            return CleveRoids.comparators[op](attackState.mhStarted, value)
        end, conditionals, "mhstarted")
    end,
    
    -- 主手攻击剩余时间
    mhremaining = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return Multi(conditionals.mhremaining, function(arg)
            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](attackState.mhRemaining, comp.amount) then
                        return false
                    end
                end
                return true
            end
            
            -- 原有单一比较
            local op = arg.operator or "<"
            local value = arg.amount; if value == nil then value = 0 end -- 保留公式字符串，由比较器包装层求值 by 武藤纯子酱 2026.9.24
            return CleveRoids.comparators[op](attackState.mhRemaining, value)
        end, conditionals, "mhremaining")
    end,
    
    -- 副手攻击开始时间
    ohstarted = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return Multi(conditionals.ohstarted, function(arg)
            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](attackState.ohStarted, comp.amount) then
                        return false
                    end
                end
                return true
            end
            
            -- 原有单一比较
            local op = arg.operator or "<"
            local value = arg.amount; if value == nil then value = 0 end -- 保留公式字符串，由比较器包装层求值 by 武藤纯子酱 2026.9.24
            return CleveRoids.comparators[op](attackState.ohStarted, value)
        end, conditionals, "ohstarted")
    end,
    
    -- 副手攻击剩余时间
    ohremaining = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return Multi(conditionals.ohremaining, function(arg)
            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](attackState.ohRemaining, comp.amount) then
                        return false
                    end
                end
                return true
            end
            
            -- 原有单一比较
            local op = arg.operator or "<"
            local value = arg.amount; if value == nil then value = 0 end -- 保留公式字符串，由比较器包装层求值 by 武藤纯子酱 2026.9.24
            return CleveRoids.comparators[op](attackState.ohRemaining, value)
        end, conditionals, "ohremaining")
    end,
    
    -- 攻击类型判断
    ismelee = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return attackState.isMelee
    end,
    
    noismelee = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return not attackState.isMelee
    end,
    
    isranged = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return attackState.isRanged
    end,

    noisranged = function(conditionals)
        local attackState = CleveRoids.GetAttackState()
        return not attackState.isRanged
    end,    

    mydot = function(conditionals)
        -- Check if Cursive addon is available
        if not CleveRoids.RequireCursive("cursive") then
            return false
        end

        local target = conditionals.target or "target"

        -- Boolean form [cursive] - check if target has ANY tracked debuff
        if not conditionals.mydot or
           conditionals.mydot == true or
           (type(conditionals.mydot) == "table" and table.getn(conditionals.mydot) == 0) then
            return CleveRoids.HasAnyCursiveDebuff(target)
        end

        -- Spell name form with optional time comparison
        return Multi(conditionals.mydot, function(args)
            if type(args) == "string" then
                -- Simple spell name check: [cursive:Rake]
                return CleveRoids.ValidateCursiveDebuff(target, args, nil, nil)
            elseif type(args) == "table" then
                -- Time comparison: [cursive:Rake>3] or multi-comparison [cursive:Rake>3&<10]
                local spellName = args.name

                -- Handle multi-comparison (e.g., >3&<10)
                if args.comparisons and type(args.comparisons) == "table" then
                    local timeRemaining = CleveRoids.GetCursiveTimeRemaining(target, spellName)
                    if not timeRemaining then return false end

                    -- ALL comparisons must pass (AND logic)
                    for _, comp in ipairs(args.comparisons) do
                        if not CleveRoids.operators[comp.operator] then
                            return false
                        end
                        if not CleveRoids.comparators[comp.operator](timeRemaining, comp.amount) then
                            return false
                        end
                    end
                    return true
                end

                -- Single comparison: [cursive:Rake>3]
                return CleveRoids.ValidateCursiveDebuff(target, spellName, args.operator, args.amount)
            end
            return false
        end, conditionals, "mydot")
    end,

    nomydot = function(conditionals)
        local target = conditionals.target or "target"

        -- 结果确认门（前置）：命名形式的挂起检查必须先于 Cursive 可用性早退——
        -- 出手结果未确认的窗口内无论 Cursive 是否安装都应挂起，否则 Nampower 会
        -- 连出两发 by 武藤纯子酱 2026.8.31
        local gateArgs = conditionals.nomydot
        if type(gateArgs) == "table" and table.getn(gateArgs) > 0 then
            local firstArg = gateArgs[1]
            local gateName = type(firstArg) == "string" and firstArg or (type(firstArg) == "table" and firstArg.name)
            if gateName and CleveRoids.IsPendingDebuffCast(gateName, target) then
                return false
            end
        end

        -- Check if Cursive addon is available (return true if missing = treat as "no debuff")
        if not CleveRoids.HasCursive() then
            return true
        end

        -- Boolean form [nocursive] - check if target has NO tracked debuffs
        if not conditionals.nomydot or
           conditionals.nomydot == true or
           (type(conditionals.nomydot) == "table" and table.getn(conditionals.nomydot) == 0) then
            return not CleveRoids.HasAnyCursiveDebuff(target)
        end

        -- Negated spell name form
        return NegatedMulti(conditionals.nomydot, function(args)
            -- Extract spell name from args
            local spellName = type(args) == "string" and args or (type(args) == "table" and args.name)

            -- Check if this debuff is PENDING (being cast or queued)
            -- This prevents double-application when spamming macros with spell queue
            if spellName and CleveRoids.IsPendingDebuffCast(spellName, target) then
                return false  -- Treat as if debuff exists (nocursive returns false)
            end

            if type(args) == "string" then
                -- Simple spell name check: [nocursive:Rake] = true if Rake is missing
                return not CleveRoids.ValidateCursiveDebuff(target, args, nil, nil)
            elseif type(args) == "table" then
                spellName = args.name

                -- Handle multi-comparison negation
                if args.comparisons and type(args.comparisons) == "table" then
                    local timeRemaining = CleveRoids.GetCursiveTimeRemaining(target, spellName)
                    -- If debuff missing, negation passes
                    if not timeRemaining then return true end

                    -- Negated: true if ANY comparison fails
                    for _, comp in ipairs(args.comparisons) do
                        if not CleveRoids.operators[comp.operator] then
                            return true
                        end
                        if not CleveRoids.comparators[comp.operator](timeRemaining, comp.amount) then
                            return true
                        end
                    end
                    return false
                end

                -- Single comparison negation
                return not CleveRoids.ValidateCursiveDebuff(target, spellName, args.operator, args.amount)
            end
            return true
        end, conditionals, "nomydot")
    end,

    enemynum = function(conditionals)
        if not conditionals.enemynum or type(conditionals.enemynum) ~= "table" then return false end

        return Multi(conditionals.enemynum, function(arg)
            if type(arg) == "string" then return false end

            -- 解析 baseUnit 和距离阈值
            local nameRaw = arg.name or ""
            local unitToken, restName = "player", nameRaw
            local pipePos = string.find(nameRaw, "|", 1, true)
            if pipePos then
                unitToken = string.sub(nameRaw, 1, pipePos - 1)
                if not CleveRoids.IsValidUnitToken(unitToken) then unitToken = "player" end
                restName = string.sub(nameRaw, pipePos + 1)
            end
            local distance = tonumber(string.match(restName, "dst(%d+)") or 5)

            -- 使用 CountEnemiesMatching 统计距离内的敌人
            local baseUnit = unitToken  -- 可自定义基准单位
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                if not CleveRoids.hasUnitXP then return false end
                local dist = CleveRoids.SafeUnitXP("distanceBetween", baseUnit, unit)
                return dist and dist <= distance
            end, baseUnit)

            -- 处理多重比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return false end
                    if not CleveRoids.comparators[comp.operator](count, comp.amount) then return false end
                end
                return true
            end

            -- 单次比较
            local operator = arg.operator
            local value = tonumber(arg.amount)
            if not value or not operator then return false end
            if CleveRoids.operators[operator] then
                return CleveRoids.comparators[operator](count, value)
            end
            return false
        end, conditionals, "enemynum")
    end,

    woundednum = function(conditionals)
        if not conditionals.woundednum or type(conditionals.woundednum) ~= "table" then return false end

        return Multi(conditionals.woundednum, function(arg)
            if type(arg) == "string" then return false end
            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                -- 解析参数格式：group类型-人数阈值-条件-伤害阈值
                local groupType, countThreshold, distance
                local patternWithDistance = "^(%a+)(%d+)dst(%d+)"
                local patternNoDistance = "^(%a+)(%d+)"

                if arg.name and strfind(arg.name, "dst") then
                    groupType, countThreshold, distance = string.match(arg.name, patternWithDistance)
                else
                    groupType, countThreshold = string.match(arg.name, patternNoDistance)
                end

                if not groupType or not countThreshold then
                    return false
                end

                countThreshold = tonumber(countThreshold)

                if not countThreshold then
                    return false
                end

                -- 所有比较必须通过（这里可能只有数量比较）
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] or not comp.amount then
                        return false
                    end

                    -- 性能优化：扫描走 0.1s 缓存 by 武藤纯子酱 2026.8.31
                    local woundedCount = CleveRoids.GetWoundedCount(
                        (groupType == "raid") and "raid" or "party",
                        comp.operator, tonumber(comp.amount), distance and tonumber(distance) or nil)

                    if not CleveRoids.comparators[">="](woundedCount, countThreshold) then
                        return false
                    end
                end
                return true
            end

            -- 解析参数格式：group类型-人数阈值-条件-伤害阈值
            local groupType, countThreshold, distance
            local patternWithDistance = "^(%a+)(%d+)dst(%d+)"
            local patternNoDistance = "^(%a+)(%d+)"

            if arg.name and strfind(arg.name, "dst") then
                groupType, countThreshold, distance = string.match(arg.name, patternWithDistance)
            else
                groupType, countThreshold = string.match(arg.name, patternNoDistance)
            end

            local operator = arg.operator

            local hpThreshold = tonumber(arg.amount)

            if not groupType or not countThreshold or not operator or not hpThreshold then
                return false
            end

            countThreshold = tonumber(countThreshold)

            if not countThreshold or not hpThreshold then
                return false
            end

            -- 性能优化：扫描走 0.1s 缓存 by 武藤纯子酱 2026.8.31
            local woundedCount = CleveRoids.GetWoundedCount(
                (groupType == "raid") and "raid" or "party",
                operator, hpThreshold, distance and tonumber(distance) or nil)

            -- 根据运算符比较
            if CleveRoids.operators[">="] then
                return CleveRoids.comparators[">="](woundedCount, countThreshold)
            end

            return false
        end, conditionals, "woundednum")
    end,
    
    mycasting = function(conditionals)
        if conditionals.mycasting == true then
            return not CleveRoids.CheckCasting(nil)
        else
            return Multi(conditionals.mycasting, function(castingSpells)
                return not CleveRoids.CheckCasting(castingSpells)
            end, conditionals, "mycasting")
        end
    end,

    nomycasting = function(conditionals)
        if conditionals.nomycasting == true then
            return CleveRoids.CheckCasting(nil)
        else
            return NegatedMulti(conditionals.nomycasting, function(castingSpells)
                return CleveRoids.CheckCasting(castingSpells)
            end, conditionals, "nomycasting")
        end
    end,

    mydotcount = function(conditionals)
        -- 确保Cursive插件已加载
        if not CleveRoids.RequireCursive("cursive") then return false end

        return Multi(conditionals.mydotcount, function(arg)
            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                local unit = conditionals.target or "target"
                local guid = CleveRoids.GetGUID(unit)
                if not guid then return false end
                -- 分割法术列表
                local spells = {}
                
                local remaining = arg.name

                while string.len(remaining) > 0 do
                    -- 查找第一个竖杠的位置
                    local slashPos = string.find(remaining, "|", 1, true)  -- plain=true表示普通字符串匹配
                    
                    local currentSpell
                    if slashPos then
                        -- 提取当前技能并截断剩余字符串
                        currentSpell = string.sub(remaining, 1, slashPos - 1)
                        remaining = string.sub(remaining, slashPos + 1)
                    else
                        -- 最后一个技能
                        currentSpell = remaining
                        remaining = ""
                    end

                    -- 清理并保存技能名称
                    currentSpell = CleveRoids.Trim(currentSpell)
                    if currentSpell ~= "" then
                        table.insert(spells, currentSpell)
                    end
                end
                
                -- 统计匹配的DOT数量
                local matchCount = 0
                for _, spellName in ipairs(spells) do
                    -- 去除法术名称中的等级信息
                    local spellNameNoRank = CleveRoids.StripRank(spellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
                    spellNameNoRank = CleveRoids.Trim(spellNameNoRank)

                    if Cursive.curses:HasCurse(spellNameNoRank, guid, 0) then
                        matchCount = matchCount + 1
                    end
                end

                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] or not comp.amount then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](matchCount, comp.amount) then
                        return false
                    end
                end
                return true
            end

            local count = arg.amount
            local operator = arg.operator
            
            if not count or not operator then return false end            
            
            local unit = conditionals.target or "target"
            local guid = CleveRoids.GetGUID(unit)
            if not guid then return false end

            -- 分割法术列表
            local spells = {}
            
            local remaining = arg.name  -- 保存剩余的字符串

            while string.len(remaining) > 0 do
                -- 查找第一个竖杠的位置
                local slashPos = string.find(remaining, "|", 1, true)  -- plain=true表示普通字符串匹配
                
                local currentSpell
                if slashPos then
                    -- 提取当前技能并截断剩余字符串
                    currentSpell = string.sub(remaining, 1, slashPos - 1)
                    remaining = string.sub(remaining, slashPos + 1)
                else
                    -- 最后一个技能
                    currentSpell = remaining
                    remaining = ""
                end

                -- 清理并保存技能名称
                currentSpell = CleveRoids.Trim(currentSpell)
                if currentSpell ~= "" then
                    table.insert(spells, currentSpell)
                end
            end
            
            -- 统计匹配的DOT数量
            local matchCount = 0
            for _, spellName in ipairs(spells) do
                -- 去除法术名称中的等级信息
                local spellNameNoRank = CleveRoids.StripRank(spellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7
                spellNameNoRank = CleveRoids.Trim(spellNameNoRank)

                if Cursive.curses:HasCurse(spellNameNoRank, guid, 0) then
                    matchCount = matchCount + 1
                end
            end

            -- 根据运算符比较数量
            if CleveRoids.operators[operator] then
                return CleveRoids.comparators[operator](matchCount, count)
            end
            
            return false
        end, conditionals, "mydotcount")
    end,

    mpowa = function(conditionals)
        -- 确保MPOWA插件已加载
        if not MPOWA then return false end

        return Multi(conditionals.mpowa, function(arg)
            -- 修复：纯索引形式 [mpowa:5] 时解析器把 "5" 存为普通字符串（arg.amount 仅在带比较符时才有值） by 武藤纯子酱 2026.8.31
            local idx = arg.amount or tonumber(arg.name or arg)
            if idx and MPOWA.active[idx] and MPOWA.active[idx] ~= false then
                return true
            else
                return false
            end
        end, conditionals, "mpowa")
    end,

    nompowa = function(conditionals)
        -- 确保MPOWA插件已加载
        if not MPOWA then return false end

        -- 修复：与 noinbag 模式一致——func 返回"该条目的否定"（未激活），外层不再套 not。
        -- 原代码 func 返回"已激活"再套 not NegatedMulti，单值恰好正确，
        -- 但 [nompowa:1/2] 变成"至少一个未激活"而非"两个都未激活" by 武藤纯子酱 2026.8.31
        return NegatedMulti(conditionals.nompowa, function(arg)
            -- 修复：同 mpowa，兼容纯索引形式 by 武藤纯子酱 2026.8.31
            local idx = arg.amount or tonumber(arg.name or arg)
            if idx and MPOWA.active[idx] and MPOWA.active[idx] ~= false then
                return false
            else
                return true
            end
        end, conditionals, "nompowa")
    end,

    onspelltarget = function(conditionals)
        if not conditionals.onspelltarget then return false end
        local unit = conditionals.target or "player"
        local unitguid = CleveRoids.GetGUID(unit)
        if not unitguid then return false end

        -- 无参数：检查是否有任意单位以当前目标为施法目标
        if type(conditionals.onspelltarget) == "string" then
            for casterGuid, data in pairs(CleveRoids.spell_tracking) do
                if data.target == unitguid and not (data.expires and GetTime() > data.expires) then
                    -- 可选：检查施法者是否仍然存在
                    if UnitExists(casterGuid) then
                        return true
                    end
                end
            end
            return false
        end

        -- 带参数：检查是否有单位正在对目标施放指定法术
        return Multi(conditionals.onspelltarget, function(arg)
            local checkSpellName = CleveRoids.StripRank(arg)
            for casterGuid, data in pairs(CleveRoids.spell_tracking) do
                if data.target == unitguid and not (data.expires and GetTime() > data.expires) then
                    local castSpellName = GetSpellRecField(data.spell_id, "name")
                    if castSpellName and CleveRoids.StripRank(castSpellName) == checkSpellName then
                        return true
                    end
                end
            end
            return false
        end, conditionals, "onspelltarget")
    end,
        
    noonspelltarget = function(conditionals)
        if not conditionals.noonspelltarget then return false end
        local unit = conditionals.target or "player"
        local unitguid = CleveRoids.GetGUID(unit)
        if not unitguid then return false end

        if type(conditionals.noonspelltarget) == "string" then
            for casterGuid, data in pairs(CleveRoids.spell_tracking) do
                if data.target == unitguid and not (data.expires and GetTime() > data.expires) then
                    if UnitExists(casterGuid) then
                        return false
                    end
                end
            end
            return true
        end

        return NegatedMulti(conditionals.noonspelltarget, function(arg)
            local checkSpellName = CleveRoids.StripRank(arg)
            for casterGuid, data in pairs(CleveRoids.spell_tracking) do
                if data.target == unitguid and not (data.expires and GetTime() > data.expires) then
                    local castSpellName = GetSpellRecField(data.spell_id, "name")
                    if castSpellName and CleveRoids.StripRank(castSpellName) == checkSpellName then
                        return false
                    end
                end
            end
            return true
        end, conditionals, "noonspelltarget")
    end,
    
    spelltargetnum = function(conditionals)
        if not conditionals.spelltargetnum then return false end
        local unit = conditionals.target or "player"
        local unitguid = CleveRoids.GetGUID(unit)
        if not unitguid then return false end

        -- 修复：裸 [spelltargetnum] 时必须带参数，守卫应读 conditionals.spelltargetnum，
        -- 原代码读 conditionals.onspelltarget（nil）导致守卫永不触发 by 武藤纯子酱 2026.8.31
        if type(conditionals.spelltargetnum) == "string" then return false end

        return Multi(conditionals.spelltargetnum, function(arg)
            local count = 0
            for casterGuid, data in pairs(CleveRoids.spell_tracking) do
                if data.target == unitguid and not (data.expires and GetTime() > data.expires) then
                    if not UnitExists(casterGuid) then
                        -- 清理过期的施法者记录
                        CleveRoids.spell_tracking[casterGuid] = nil
                    else
                        -- 根据参数筛选敌我
                        if arg.name == "help" then
                            if UnitIsFriend(casterGuid, "player") then count = count + 1 end
                        elseif arg.name == "harm" then
                            if UnitIsEnemy(casterGuid, "player") then count = count + 1 end
                        else
                            count = count + 1
                        end
                    end
                end
            end

            -- 处理多重比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return false end
                    if not CleveRoids.comparators[comp.operator](count, comp.amount) then return false end
                end
                return true
            end

            -- 单次比较
            local operator = arg.operator
            local value = tonumber(arg.amount)
            if not value or not operator then return false end
            if CleveRoids.operators[operator] then
                return CleveRoids.comparators[operator](count, value)
            end
            return false
        end, conditionals, "spelltargetnum")
    end,

    mounted = function()
        if CleveRoids.hasSuperwow then
            local version = tonumber(SUPERWOW_VERSION)
            if version and version > 2 then
                local Mounted = IsMounted()
                if Mounted then 
                    return true
                else
                    return false
                end
            end
        end

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
                        return true
                    end
                end
                
                for _, pattern in ipairs(CleveRoids.FlyMountPatterns) do
                    if tipText and string.find(tipText, pattern) then
                        return true
                    end
                end
                          
            end
        end    
        return false
    end,
    
    nomounted = function()
        if CleveRoids.hasSuperwow then
            local version = tonumber(SUPERWOW_VERSION)
            if version and version > 2 then
                local Mounted = IsMounted()
                if Mounted then 
                    return false
                else
                    return true
                end
            end
        end

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
                        return false
                    end
                end
                
                for _, pattern in ipairs(CleveRoids.FlyMountPatterns) do
                    if tipText and string.find(tipText, pattern) then
                        return false
                    end
                end
                          
            end
        end
        return true
    end,
    
    flying = function()
        local flying = nil
        
        for i = 0, 31 do -- 遍历所有buff栏位
            local texture = GetPlayerBuffTexture(i)

            if texture then
                -- 通过工具提示检测坐骑

                CleveRoids.Scanner:ClearLines()
                CleveRoids.Scanner:SetPlayerBuff(i)
                local tipText = CleverDismountScannerTextLeft2:GetText()
                -- 匹配速度描述关键词
                for _, pattern in ipairs(CleveRoids.FlyMountPatterns) do
                    if tipText and string.find(tipText, pattern) then
                        flying = true
                        break
                    end
                end
                          
            end
        end        
    
        if flying then
            return true
        else
            return UnitOnTaxi("player")
        end
    end,    
    
    noflying = function()
        local flying = nil
        
        for i = 0, 31 do -- 遍历所有buff栏位
            local texture = GetPlayerBuffTexture(i)

            if texture then
                -- 通过工具提示检测坐骑

                CleveRoids.Scanner:ClearLines()
                CleveRoids.Scanner:SetPlayerBuff(i)
                local tipText = CleverDismountScannerTextLeft2:GetText()
                -- 匹配速度描述关键词
                for _, pattern in ipairs(CleveRoids.FlyMountPatterns) do
                    if tipText and string.find(tipText, pattern) then
                        flying = true
                        break
                    end
                end
                          
            end
        end        
    
        if flying then
            return false
        else
            return not UnitOnTaxi("player")
        end
    end,

    owner = function(conditionals)
        -- Nampower v2.41+ 扩展 token：原生 UnitExists/UnitName 支持 <unit>owner 后缀 by 武藤纯子酱 2026.9.1
        if not CleveRoids.hasNampowerGuidAPI then
            return false
        end    

        return Or(conditionals.owner, function(arg)                        
            if not arg or type(arg) ~= "string" then return false end
            if not conditionals.target then return false end
            if not UnitExists(conditionals.target.."owner") then return false end
            if UnitName(conditionals.target.."owner") == arg then
                return true 
            else
                return false        
            end
        end)        
    end,
    
    noowner = function(conditionals)
        -- Nampower v2.41+ 扩展 token：原生 UnitExists/UnitName 支持 <unit>owner 后缀 by 武藤纯子酱 2026.9.1
        if not CleveRoids.hasNampowerGuidAPI then
            return false
        end    

        return NegatedMulti(conditionals.noowner, function(arg)                        
            if not arg or type(arg) ~= "string" then return false end
            if not conditionals.target then return false end
            if not UnitExists(conditionals.target.."owner") then return true end
            if UnitName(conditionals.target.."owner") == arg then
                return false
            else
                return true
            end
        end, conditionals, "noowner")        
    end,
    
    myunit = function(conditionals)
        return Multi(conditionals.myunit, function(arg)
            if not arg or type(arg) ~= "string" then return false end
        
            -- 遍历所有跟踪的单位
            for guid, name in pairs(CleveRoids.PlayerSummons) do
                if name == arg then
                    return true 
                end
            end

            return false
        end, conditionals, "myunit")
    end,
    
    nomyunit = function(conditionals)
        return NegatedMulti(conditionals.nomyunit, function(arg)
            if not arg or type(arg) ~= "string" then return false end
        
            -- 遍历所有跟踪的单位
            for guid, name in pairs(CleveRoids.PlayerSummons) do
                if name == arg then
                    return false
                end
            end

            return true
        end, conditionals, "nomyunit")        
    end,

    deathtime = function(conditionals)
        if not conditionals.deathtime then return false end
        
        return Multi(conditionals.deathtime, function(arg)
            if not arg or type(arg) == "string" then return false end
            
            local unit = conditionals.target or "target"
            
            if not unit then return false end
            
            local deathtime = CleveRoids.GetTargetDeathTime(unit)

            -- 根据运算符进行比较
            if CleveRoids.operators[arg.operator] then
                return CleveRoids.comparators[arg.operator](deathtime, arg.amount)
            end    
        end, conditionals, "deathtime")        
    end,
    
    mark = function(conditionals)
        if type(conditionals.mark) == "string" and GetRaidTargetIndex(conditionals.target or "target") then
            return true
        end

        return Or(conditionals.mark, function(arg)
            if not arg or type(arg) ~= "string" then return false end

            -- 修复：GetRaidTargetIndex 无标记时返回 0（Lua 中 truthy），
            -- 原代码查 RaidTargetIndex[0] 得 nil 后 strfind(nil,...) 崩溃；
            -- 同时 conditionals.target 可能为 nil（宏不带 @token） by 武藤纯子酱 2026.9.9
            local markIndex = GetRaidTargetIndex(conditionals.target or "target")
            if markIndex and markIndex >= 1 then
                local markName = CleveRoids.Localized.RaidTargetIndex[markIndex]
                -- plain 匹配：用户值含 %()[].+-*?^$ 等模式字符时不再抛 "malformed pattern"
                if markName and strfind(markName, arg, 1, true) then
                    return true
                end
            end
            return false
        end)
    end,

    nomark = function(conditionals)
        -- 修复：裸 [nomark] 时解析器把值存 conditionals.nomark（字符串），
        -- 原代码读 conditionals.mark（nil）导致"无标记直接为真"的捷径永不触发 by 武藤纯子酱 2026.8.31
        if type(conditionals.nomark) == "string" and not GetRaidTargetIndex(conditionals.target or "target") then
            return true
        end

        return NegatedMulti(conditionals.nomark, function(arg)

            if not arg or type(arg) ~= "string" then return false end

            -- 同 mark：标记序号 0 值守卫 + plain 匹配 by 武藤纯子酱 2026.9.9
            local markIndex = GetRaidTargetIndex(conditionals.target or "target")
            if markIndex and markIndex >= 1 then
                local markName = CleveRoids.Localized.RaidTargetIndex[markIndex]
                if markName and strfind(markName, arg, 1, true) then
                    return false
                end
            end
            return true
        end, conditionals, "nomark")
    end,

    delay = function(conditionals)
        -- 施法时钟由 Nampower SPELL_GO_SELF / SPELL_START_SELF 事件写入（见 Core.lua）by 武藤纯子酱 2026.9.1
        if not CleveRoids.hasNampowerGuidAPI then return false end
        
        return Multi(conditionals.delay, function(args)
            local SpellName
            if type(args) == "table" and args.name then
                SpellName = args.name
            elseif conditionals.action then
                SpellName = conditionals.action
            end
            -- 清理技能名称（移除等级信息）
            SpellName = CleveRoids.StripRank(SpellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7

            if not SpellName or not CleveRoids.SpellCastTimes[SpellName] then
                return true
            end

            -- 移除在途守卫：弹道/在途方案已被"结果确认门"取代——施法出手即刷新
            -- SpellCastTimes 时钟（CAST 事件），延迟门从出手时刻起算；连发防护由
            -- buff/debuff 族条件的结果确认门承担 by 武藤纯子酱 2026.8.31

            local currentTime = GetTime()

            if not args.operator and args.comparisons and type(args.comparisons) == "table" then
                -- 检查是否有延迟记录
                local timeSinceCast = 9999  -- 默认无限大
                timeSinceCast = currentTime - CleveRoids.SpellCastTimes[SpellName]

                
                -- 所有比较必须通过
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] or not comp.amount then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](timeSinceCast, comp.amount) then
                        return false
                    end
                end
                return true
            end

            local DelayTime
            local Operator
            if type(args) == "string" and tonumber(args) then
                DelayTime =  tonumber(args)
                Operator = ">="
            elseif type(args) == "table" then 
                DelayTime = args.amount or 0.5
                Operator = args.operator or ">="
            else
                return false
            end

            if not Operator or not DelayTime then
                return false
            end            

            -- 检查是否有延迟记录，并根据运算符进行比较
            local timeSinceCast = currentTime - CleveRoids.SpellCastTimes[SpellName]

            return CleveRoids.comparators[Operator](timeSinceCast, DelayTime)
        end, conditionals, "delay")
    end,

    unitdelay = function(conditionals)
        -- 施法时钟由 Nampower SPELL_GO_SELF / SPELL_START_SELF 事件写入（见 Core.lua）by 武藤纯子酱 2026.9.1
        if not CleveRoids.hasNampowerGuidAPI then return false end
        
        return Multi(conditionals.unitdelay, function(args)
            local SpellName
            if type(args) == "table" and args.name then
                SpellName = args.name
            elseif conditionals.action then
                SpellName = conditionals.action
            end
            -- 清理技能名称（移除等级信息）
            SpellName = CleveRoids.StripRank(SpellName) -- 修复多语言支持 by 武藤纯子酱 2026.1.7

            -- 目标 GUID：Nampower GetUnitGUID（替代 SuperWoW 的 select(2, UnitExists) 第二返回值）by 武藤纯子酱 2026.9.1
            local targetGuid = CleveRoids.GetGUID(conditionals.target)

            -- 无延迟记录（新目标/未施放过）：直接放行 by 武藤纯子酱 2026.8.31
            if not targetGuid or not CleveRoids.SpellTarget[targetGuid] or not CleveRoids.SpellTarget[targetGuid][SpellName] then
                return true
            end

            -- 移除在途守卫：弹道/在途方案已被"结果确认门"取代——施法出手即刷新
            -- SpellTarget 时钟（CAST 事件），延迟门从出手时刻起算；连发防护由
            -- buff/debuff 族条件的结果确认门承担 by 武藤纯子酱 2026.8.31

            local currentTime = GetTime()

            if not args.operator and args.comparisons and type(args.comparisons) == "table" then
                -- 检查是否有延迟记录
                local timeSinceCast = 9999  -- 默认无限大
                timeSinceCast = currentTime - CleveRoids.SpellTarget[targetGuid][SpellName]

                
                -- 所有比较必须通过
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] or not comp.amount then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](timeSinceCast, comp.amount) then
                        return false
                    end
                end
                return true
            end

            local DelayTime
            local Operator
            if type(args) == "string" and tonumber(args) then
                DelayTime =  tonumber(args)
                Operator = ">="
            elseif type(args) == "table" then 
                DelayTime = args.amount or 0.5
                Operator = args.operator or ">="
            else
                return false
            end

            if not Operator or not DelayTime then
                return false
            end            

            -- 检查是否有延迟记录，并根据运算符进行比较
            local timeSinceCast = currentTime - CleveRoids.SpellTarget[targetGuid][SpellName]

            return CleveRoids.comparators[Operator](timeSinceCast, DelayTime)
        end, conditionals, "unitdelay")
    end,

    mycasttime = function(conditionals)
        -- 计算剩余时间（如果不施法则为0）
        local timeLeft = 0
        local timeStart = 0 -- 新增timeStart by 武藤纯子酱 2025.12.4
        
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local elapsed = GetTime() - CleveRoids.castStartTime
            timeLeft = CleveRoids.castDuration - elapsed
            timeStart = elapsed -- 新增 by 武藤纯子酱 2025.12.4
            -- 不允许负时间
            if timeLeft < 0 then timeLeft = 0 end
        end
        local check = conditionals.mycasttime
        -- 如果check是数组，获取第一个元素
        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end
        -- 处理多比较
        if type(check) == "table" and check.comparisons and type(check.comparisons) == "table" then
            local timetype = check.name or "start"
            timetype = strlower(timetype)
            
            if timetype ~= "start" and timetype ~= "end" then
                timetype = "start"
            end
            
            local valueToCheck = (timetype == "start") and timeStart or timeLeft
            
            -- 所有比较必须通过
            for _, comp in ipairs(check.comparisons) do
                if not CleveRoids.operators[comp.operator] then
                    return false
                end
                if not CleveRoids.comparators[comp.operator](valueToCheck, comp.amount) then
                    return false
                end
            end
            return true
        end
        
        -- 原有单一比较逻辑
        if type(check) == "table" and check.operator and check.amount then
            local timetype = check.name or "start"
            timetype = strlower(timetype)
            
            if timetype ~= "start" and timetype ~= "end" then
                timetype = "start"
            end
            
            -- Now compare: if not casting, timeLeft is 0, so [casttime:<0.5] returns true
            if timetype == "start" then -- 修改同时支持start和end两种模式 by 武藤纯子酱 2025.12.4
                return CleveRoids.comparators[check.operator](timeStart, check.amount)
            else
                return CleveRoids.comparators[check.operator](timeLeft, check.amount)
            end
        end
        return false
    end,

    nomycasttime = function(conditionals)
        -- 计算剩余时间（如果不施法则为0）
        local timeLeft = 0
        local timeStart = 0 -- 新增timeStart by 武藤纯子酱 2025.12.4
        
        if CleveRoids.CurrentSpell.type == "cast" and CleveRoids.castStartTime and CleveRoids.castDuration then
            local elapsed = GetTime() - CleveRoids.castStartTime
            timeLeft = CleveRoids.castDuration - elapsed
            timeStart = elapsed -- 新增 by 武藤纯子酱 2025.12.4
            -- 不允许负时间
            if timeLeft < 0 then timeLeft = 0 end
        end
        local check = conditionals.nomycasttime
        -- 如果check是数组，获取第一个元素
        if type(check) == "table" and type(check[1]) == "table" then
            check = check[1]
        end
        -- 处理多比较
        if type(check) == "table" and check.comparisons and type(check.comparisons) == "table" then
            local timetype = check.name or "start"
            timetype = strlower(timetype)
            
            if timetype ~= "start" and timetype ~= "end" then
                timetype = "start"
            end
            
            local valueToCheck = (timetype == "start") and timeStart or timeLeft
            
            -- 修复：否定语义应为“任一比较失败→true、全部通过→false”（原为全部失败才 true，方向反了） by 武藤纯子酱 2026.9.12
            for _, comp in ipairs(check.comparisons) do
                if not CleveRoids.operators[comp.operator] then
                    return false
                end
                if not CleveRoids.comparators[comp.operator](valueToCheck, comp.amount) then
                    return true
                end
            end
            return false
        end
        
        -- 原有单一比较逻辑
        if type(check) == "table" and check.operator and check.amount then
            local timetype = check.name or "start"
            timetype = strlower(timetype)
            
            if timetype ~= "start" and timetype ~= "end" then
                timetype = "start"
            end
            
            -- Now compare: if not casting, timeLeft is 0, so [casttime:<0.5] returns true
            if timetype == "start" then -- 修改同时支持start和end两种模式 by 武藤纯子酱 2025.12.4
                return not CleveRoids.comparators[check.operator](timeStart, check.amount)
            else
                return not CleveRoids.comparators[check.operator](timeLeft, check.amount)
            end
        end
        return false
    end,

    casttime = function(conditionals)
        -- spell_tracking 由 Nampower SPELL_START_SELF/OTHER 写入（见 Core.lua）by 武藤纯子酱 2026.9.1
        if not CleveRoids.hasNampowerGuidAPI then return false end
        return Multi(conditionals.casttime, function(arg)
            local mode, spellIdentifier = CleveRoids.ParseCasttimeArg(arg)

            local unit = conditionals.target or "target"
            local guid = CleveRoids.GetGUID(unit)
            local currentTime = GetTime()

            -- 单位不存在或没有在施法
            if not guid or not CleveRoids.spell_tracking[guid] then
                return false
            end
            local cast = CleveRoids.spell_tracking[guid]

            -- 技能匹配检查
            if spellIdentifier and spellIdentifier ~= "" then
                local spellId = tonumber(spellIdentifier)
                local matched = false
                if spellId then
                    matched = (cast.spell_id == spellId)
                else
                    local castSpellName = GetSpellRecField(cast.spell_id, "name") -- 已有函数，返回去等级小写名
                    if castSpellName then
                        local searchName = string.lower(CleveRoids.StripRank(spellIdentifier))
                        matched = (string.lower(castSpellName) == searchName)
                    end
                end
                if not matched then
                    return false
                end
            end

            -- 计算剩余时间
            local remaining
            if mode == "start" then
                remaining = currentTime - cast.start
            else
                remaining = cast.expires - currentTime
            end
            if remaining < 0 then remaining = 0 end

            -- 处理多比较 (e.g., >5&<10)
            if arg.comparisons and type(arg.comparisons) == "table" then
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](remaining, comp.amount) then
                        return false
                    end
                end
                return true
            end

            -- 单一比较（数值位支持施法时间公式，如 getchannel(奥术飞弹)/6）by 武藤纯子酱 2026.9.1
            local op, value
            if type(arg) == "table" then
                op = arg.operator
                value = ResolveConditionAmount(arg.amount)
            end
            if not value or not op then return false end
            if CleveRoids.operators[op] then
                return CleveRoids.comparators[op](remaining, value)
            end
            return false
        end, conditionals, "casttime")
    end,

    nocasttime = function(conditionals)
        -- spell_tracking 由 Nampower SPELL_START_SELF/OTHER 写入（见 Core.lua）by 武藤纯子酱 2026.9.1
        if not CleveRoids.hasNampowerGuidAPI then return false end
        return NegatedMulti(conditionals.nocasttime, function(arg)
            local mode, spellIdentifier = CleveRoids.ParseCasttimeArg(arg)

            local unit = conditionals.target or "target"
            local guid = CleveRoids.GetGUID(unit)
            local currentTime = GetTime()

            -- 单位不存在或没有施法 → 原条件为假 → 否定返回 true
            if not guid or not CleveRoids.spell_tracking[guid] then
                return true
            end
            local cast = CleveRoids.spell_tracking[guid]

            -- 技能匹配检查
            if spellIdentifier and spellIdentifier ~= "" then
                local spellId = tonumber(spellIdentifier)
                local matched = false
                if spellId then
                    matched = (cast.spell_id == spellId)
                else
                    local castSpellName = GetSpellRecField(cast.spell_id, "name")
                    if castSpellName then
                        local searchName = string.lower(CleveRoids.StripRank(spellIdentifier))
                        matched = (string.lower(castSpellName) == searchName)
                    end
                end
                if not matched then
                    -- 技能不匹配 → 原条件为假 → 否定返回 true
                    return true
                end
            end

            -- 计算剩余时间
            local remaining
            if mode == "start" then
                remaining = currentTime - cast.start
            else
                remaining = cast.expires - currentTime
            end
            if remaining < 0 then remaining = 0 end

            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return true
                    end
                    if not CleveRoids.comparators[comp.operator](remaining, comp.amount) then
                        return true
                    end
                end
                return false   -- 所有比较都通过 → 原条件为真 → 否定返回 false
            end

            -- 单一比较（数值位支持施法时间公式，否定语义不变）by 武藤纯子酱 2026.9.1
            local op, value
            if type(arg) == "table" then
                op = arg.operator
                value = ResolveConditionAmount(arg.amount)
            end
            if not value or not op then return true end
            if CleveRoids.operators[op] then
                -- 如果原条件为真（剩余时间满足条件），则否定返回 false
                if CleveRoids.comparators[op](remaining, value) then
                    return false
                else
                    return true
                end
            end
            return true
        end, conditionals, "nocasttime")
    end,
    
    raidnum = function(conditionals)
        -- 如果没有安装UnitXP，总是返回false
        if not CleveRoids.hasUnitXP then
            return false
        end

        if not conditionals.raidnum or type(conditionals.raidnum) ~= "table" then return false end
        return Multi(conditionals.raidnum, function(arg)
            -- 修复：裸值 [raidnum:3]（无比较符）时 arg 是纯字符串，arg.name/arg.amount 均取不到，
            -- 原代码 value 回落为 0 → 语义变成"范围内人数>0"；改为把字符串值当作数量 by 武藤纯子酱 2026.9.9
            if type(arg) == "string" then
                arg = { amount = arg }
            end
            if type(arg) ~= "table" then return false end
            -- 解析参数格式：dst距离-条件-数量
            local distance = tonumber(string.match(arg.name or "", "dst(%d+)") or 30)

            -- 性能优化：距离内人数扫描走 0.1s 缓存（多重比较不再重复整段扫描）。
            -- 语义与单比较分支一致：在团队 = 1（自己）+ 范围内存活可见成员；无团队 = 0
            -- （同时修正此前多比较分支在无团队时也计 1 的不一致）by 武藤纯子酱 2026.8.31
            local Count = CleveRoids.GetGroupRangeCount("raid", distance)

            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](Count, comp.amount) then
                        return false
                    end
                end
                return true
            end

            -- 原有单一比较逻辑
            local operator = arg.operator or ">"
            local value = arg.amount; if value == nil then value = 0 end -- 保留公式字符串，由比较器包装层求值 by 武藤纯子酱 2026.9.24

            if not distance or not value or not operator then
                return false
            end

            -- 根据运算符进行比较
            if CleveRoids.operators[operator] then
                return CleveRoids.comparators[operator](Count, value)
            end
            return false
        end, conditionals, "raidnum")
    end,

    partynum = function(conditionals)
        -- 如果没有安装UnitXP，总是返回false
        if not CleveRoids.hasUnitXP then
            return false
        end

        if not conditionals.partynum or type(conditionals.partynum) ~= "table" then return false end
        return Multi(conditionals.partynum, function(arg)
            -- 同 raidnum：裸值字符串按数量处理 by 武藤纯子酱 2026.9.9
            if type(arg) == "string" then
                arg = { amount = arg }
            end
            if type(arg) ~= "table" then return false end
            -- 解析参数格式：dst距离-条件-数量
            local distance = tonumber(string.match(arg.name or "", "dst(%d+)") or 30)

            -- 性能优化：距离内人数扫描走 0.1s 缓存（多重比较不再重复整段扫描） by 武藤纯子酱 2026.8.31
            local Count = CleveRoids.GetGroupRangeCount("party", distance)

            -- 处理多比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                -- 所有比较必须通过
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](Count, comp.amount) then
                        return false
                    end
                end
                return true
            end

            -- 原有单一比较逻辑
            local operator = arg.operator or ">"
            local value = arg.amount; if value == nil then value = 0 end -- 保留公式字符串，由比较器包装层求值 by 武藤纯子酱 2026.9.24

            if not distance or not value or not operator then
                return false
            end

            -- 根据运算符进行比较
            if CleveRoids.operators[operator] then
                return CleveRoids.comparators[operator](Count, value)
            end
            return false
        end, conditionals, "partynum")
    end,

    petbuff = function(conditionals)
        return Multi(conditionals.petbuff, function(v)
            return CleveRoids.ValidatePetBuff(v)
        end, conditionals, "petbuff")
    end,

    nopetbuff = function(conditionals)
        return NegatedMulti(conditionals.nopetbuff, function(v)
            return not CleveRoids.ValidatePetBuff(v)
        end, conditionals, "nopetbuff")
    end,

    petdebuff = function(conditionals)
        return Multi(conditionals.petdebuff, function(v)
            return CleveRoids.ValidatePetDebuff(v)
        end, conditionals, "petdebuff")
    end,

    nopetdebuff = function(conditionals)
        return NegatedMulti(conditionals.nopetdebuff, function(v)
            return not CleveRoids.ValidatePetDebuff(v)
        end, conditionals, "nopetdebuff")
    end,

    petpower = function(conditionals)
        return Multi(conditionals.petpower, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                -- PERFORMANCE: Use cached player power
                local powerPercent = CleveRoids.GetCachedPetPowerPercent()

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](powerPercent, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidatePower("pet", args.operator, args.amount)
        end, conditionals, "petpower")
    end,
    
    petrawpower = function(conditionals)
        return Multi(conditionals.petrawpower, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >500&<1000)
            if args.comparisons and type(args.comparisons) == "table" then
                -- PERFORMANCE: Use cached player power
                local power = CleveRoids.GetCachedPetPower()

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](power, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateRawPower("pet", args.operator, args.amount)
        end, conditionals, "petrawpower")
    end,
    
    petpowerlost = function(conditionals)
        return Multi(conditionals.petpowerlost, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidatePowerLost("pet", args.operator, args.amount)
        end, conditionals, "petpowerlost")
    end,

    petlevel = function(conditionals)
        return Multi(conditionals.petlevel, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<60)
            if args.comparisons and type(args.comparisons) == "table" then
                local level = UnitLevel("pet")

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](level, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateLevel("pet", args.operator, args.amount)
        end, conditionals, "petlevel")
    end,
    
    pethp = function(conditionals)
        return Multi(conditionals.pethp, function(args)
            if type(args) ~= "table" then return false end

            -- Handle multi-comparison (e.g., >50&<80)
            if args.comparisons and type(args.comparisons) == "table" then
                -- PERFORMANCE: Use cached player health
                local hp = CleveRoids.GetCachedPetHealthPercent()

                -- ALL comparisons must pass (AND logic)
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.operators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](hp, comp.amount) then
                        return false
                    end
                end
                return true
            end

            return CleveRoids.ValidateHp("pet", args.operator, args.amount)
        end, conditionals, "pethp")
    end,
    
    petrawhp = function(conditionals)
        return Multi(conditionals.petrawhp, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidateRawHp("pet", args.operator, args.amount)
        end, conditionals, "petrawhp")
    end,
    
    pethplost = function(conditionals)
        return Multi(conditionals.pethplost, function(args)
            if type(args) ~= "table" then return false end
            return CleveRoids.ValidateHpLost("pet", args.operator, args.amount)
        end, conditionals, "pethplost")
    end,
    
    pethappiness = function(conditionals)
        if select(2,UnitClass("player")) ~= "HUNTER" or not UnitExists("pet") then
            return false
        end

        return Multi(conditionals.pethappiness, function(args)
            local happiness = GetPetHappiness()
            if type(args) == "table" then
                -- Handle multi-comparison (e.g., >50&<80)
                if args.comparisons and type(args.comparisons) == "table" then
                    -- ALL comparisons must pass (AND logic)
                    for _, comp in ipairs(args.comparisons) do
                        if not CleveRoids.operators[comp.operator] then
                            return false
                        end
                        -- 修复：比较量非数字时直接判失败 by 武藤纯子酱 2026.9.11
                        if comp.amount == nil then
                            return false
                        end
                        if not CleveRoids.comparators[comp.operator](happiness, comp.amount) then
                            return false
                        end
                    end
                    return true
                else
                    if not CleveRoids.operators[args.operator] then
                        return false
                    end
                    -- 修复：比较量非数字时直接判失败 by 武藤纯子酱 2026.9.11
                    if args.amount == nil then
                        return false
                    end
                    if not CleveRoids.comparators[args.operator](happiness, args.amount) then
                        return false
                    end
                    
                    return true
                end
            else
                if args and tonumber(args) == tonumber(happiness) then
                    return true
                end
                return false
            end
        end, conditionals, "pethappiness")
    end,
    
    -- [petcc:type] - Check if PLAYER has a specific CC effect
    -- Same types as [cc], but always checks the player
    -- Examples: [petcc:stun] [petcc:fear/charm] [petcc] (any CC)
    petcc = function(conditionals)
        -- If no specific CC type, check for ANY loss-of-control on player
        if not conditionals.petcc or (type(conditionals.petcc) == "table" and table.getn(conditionals.petcc) == 0) or type(conditionals.petcc) == "string" then -- 修复，不接类型时默认所有类型 by 武藤纯子酱 2025.12.25（原误查 cc 键 by 武藤纯子酱 2026.8.31）
            return CleveRoids.ValidateUnitAnyCrowdControl("pet")
        end

        -- Check for specific CC type(s) - OR logic
        return Or(conditionals.petcc, function(ccType)
            return CleveRoids.ValidateUnitCC("pet", ccType)
        end)
    end,

    -- [nopetcc:type] - Check if PLAYER does NOT have a specific CC effect
    -- Uses AND logic for negation: [nopetcc:stun/fear] = not stunned AND not feared
    nopetcc = function(conditionals)
        -- If no specific CC type, check for NO loss-of-control on player
        if not conditionals.nopetcc or (type(conditionals.nopetcc) == "table" and table.getn(conditionals.nopetcc) == 0) or type(conditionals.nopetcc) == "string" then -- 修复，不接类型时默认所有类型 by 武藤纯子酱 2025.12.25（原误查 cc 键 by 武藤纯子酱 2026.8.31）
            return not CleveRoids.ValidateUnitAnyCrowdControl("pet")
        end

        -- Check for absence of specific CC type(s) - AND logic
        return NegatedMulti(conditionals.nopetcc, function(ccType)
            return not CleveRoids.ValidateUnitCC("pet", ccType)
        end, conditionals, "nopetcc")
    end,

    -- ============================================================================
    -- [petdead] / [petalive] / [nopetdead] / [nopetalive] - 宠物死亡/存活检测 by 武藤纯子酱 2026.8.31
    -- 用途：自动复活宠物宏 /cast [nopet,petdead] 复活; /cast [petalive] 喂食
    -- 语义：petdead/petalive 在无宠物时为 false；
    --       nopetdead/nopetalive 为纯取反（无宠物时 nopetdead=true、nopetalive=true）
    -- ============================================================================
    petdead = function(conditionals)
        if not UnitExists("pet") then return false end
        return (CleveRoids.IsUnitDeadOrGhost("pet") or false)
    end,

    petalive = function(conditionals)
        if not UnitExists("pet") then return false end
        return not (CleveRoids.IsUnitDeadOrGhost("pet") or false)
    end,

    nopetdead = function(conditionals)
        if not UnitExists("pet") then return true end
        return not (CleveRoids.IsUnitDeadOrGhost("pet") or false)
    end,

    nopetalive = function(conditionals)
        if not UnitExists("pet") then return true end
        return (CleveRoids.IsUnitDeadOrGhost("pet") or false)
    end,

    -- ============================================================================
    -- [petcd:技能名] / [petcd:技能名<秒] / [petcd:<秒] / [petcd]
    -- [petcooldown:*] 为同义完整拼写；[nopetcd:*] / [nopetcooldown:*] 为否定版
    -- 宠物技能冷却检测（宠物动作条 GetPetActionInfo + GetPetActionCooldown）by 武藤纯子酱 2026.8.31
    -- 语义：
    --   [petcd:Growl]        Growl 冷却中（剩余 > 0）
    --   [petcd:Growl<2]      Growl 剩余冷却 < 2 秒
    --   [petcd:Growl<2&>0]   多重比较（全部通过）
    --   [petcd:<2]           任意宠物技能剩余冷却 < 2 秒
    --   [petcd]              任意宠物技能冷却中
    --   技能未找到/无宠物    一律 false（无法判定）
    -- ============================================================================
    -- [petcd:Growl] - Growl is on cooldown
    petcd = function(conditionals)
        local v = conditionals.petcd
        -- 裸 [petcd]：任意宠物技能冷却中 by 武藤纯子酱 2026.8.31
        if v == true or type(v) == "string" then
            return CleveRoids.ScanPetActionCooldowns(function(remaining) return remaining > 0 end)
        end
        return Multi(v, function(args)
            return CleveRoids.EvaluatePetCdEntry(args)
        end, conditionals, "petcd")
    end,

    -- [nopetcd:Growl] - Growl is ready (not on cooldown)
    nopetcd = function(conditionals)
        local v = conditionals.nopetcd
        -- 裸 [nopetcd]：全部宠物技能就绪（无宠物时 false） by 武藤纯子酱 2026.8.31
        if v == true or type(v) == "string" then
            if not UnitExists("pet") then return false end
            return not CleveRoids.ScanPetActionCooldowns(function(remaining) return remaining > 0 end)
        end
        return NegatedMulti(v, function(args)
            local r = CleveRoids.EvaluatePetCdEntry(args)
            if r == nil then return false end
            return not r
        end, conditionals, "nopetcd")
    end,

    -- [petcooldown:*] - [petcd:*] 的完整拼写别名 by 武藤纯子酱 2026.8.31
    petcooldown = function(conditionals)
        -- 修复：别名不能直接转发 Keywords.petcd（它读 conditionals.petcd，而解析器把
        -- [petcooldown:X] 存在 conditionals.petcooldown 下），否则指定技能名会被忽略退化成
        -- "任意宠物技能冷却中"。改为复用同名求值逻辑但读自己的 key by 武藤纯子酱 2026.8.31
        local v = conditionals.petcooldown
        if v == true or type(v) == "string" then
            return CleveRoids.ScanPetActionCooldowns(function(remaining) return remaining > 0 end)
        end
        return Multi(v, function(args)
            return CleveRoids.EvaluatePetCdEntry(args)
        end, conditionals, "petcooldown")
    end,

    nopetcooldown = function(conditionals)
        local v = conditionals.nopetcooldown
        if v == true or type(v) == "string" then
            if not UnitExists("pet") then return false end
            return not CleveRoids.ScanPetActionCooldowns(function(remaining) return remaining > 0 end)
        end
        return NegatedMulti(v, function(args)
            local r = CleveRoids.EvaluatePetCdEntry(args)
            if r == nil then return false end
            return not r
        end, conditionals, "nopetcooldown")
    end,
    
    mytargeting = function(conditionals)
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            return false
        end
        
        if not UnitExists("target") then
            return false
        end
        
        return Or(conditionals.mytargeting, function (unit)
            if not unit or unit == conditionals.action then
                if UnitExists("target") then
                    return true
                else
                    return false
                end
            end
            return (UnitIsUnit("target", unit) == 1)
        end)
    end,

    nomytargeting = function(conditionals)
        if not conditionals.target or not UnitExists(conditionals.target or "target") then
            -- 修复：严格取反——无目标时正向 mytargeting=false，nomytargeting 应为 true（与 nohelp/noharm 一致） by 武藤纯子酱 2026.9.12
            return true
        end
        
        if not UnitExists("target") then
            return true
        end
    
        return NegatedMulti(conditionals.nomytargeting, function (unit)
            if not unit or unit == conditionals.action then
                if UnitExists("target") then
                    return false
                else
                    return true
                end
            end

            return UnitIsUnit("target", unit) ~= 1
        end, conditionals, "nomytargeting")
    end,
    
    addcheck = function(conditionals)
        if not conditionals.addcheck or type(conditionals.addcheck) ~= "table" then return false end

        return Multi(conditionals.addcheck, function(arg)
            local cont = conditionals.target or "target"
            if not cont or not UnitExists(cont) then return false end

            local testdistance = tonumber(arg) or 5

            -- 遍历所有已知的敌对 GUID
            for guid, _ in pairs(CleveRoids.knownEnemyGuids) do
                if not UnitExists(guid) then
                    -- 移除过期的 GUID
                    CleveRoids.knownEnemyGuids[guid] = nil
                else
                    -- 检查距离
                    if CleveRoids.hasUnitXP then
                        local distance = CleveRoids.SafeUnitXP("distanceBetween", guid, cont)
                        if distance and distance <= testdistance then
                            -- 检查是否未进战斗、敌对且可攻击
                            if not UnitAffectingCombat(guid) and UnitCanAttack("player", guid) then
                                return false  -- 发现潜在的ADD，条件失败
                            end
                        end
                    end
                end
            end
            return true  -- 安全
        end, conditionals, "addcheck")
    end,
    
    func = function(conditionals)
        if type(conditionals.func) == "string" then return false end
    
        if type(conditionals.func) == "table" then
            return Multi(conditionals.func, function(funcCall)
                return CleveRoids.ExecuteConditionalFunction(funcCall)
            end, conditionals, "func")
        end
    end,
    
    nofunc = function(conditionals)
        if type(conditionals.nofunc) == "string" then return false end
    
        if type(conditionals.nofunc) == "table" then
            return NegatedMulti(conditionals.nofunc, function(funcCall)
                return not CleveRoids.ExecuteConditionalFunction(funcCall)
            end, conditionals, "nofunc")
        end
    end,
    
    truetarget = function(conditionals)
        if type(conditionals.truetarget) == "string" then return false end
    
        if type(conditionals.truetarget) == "table" then
            return Multi(conditionals.truetarget, function(args)
                
                if type(args) == "table" then return false end  -- 修复：原代码 args == "table" 比较表与字符串恒 false by 武藤纯子酱 2026.8.31
                
                local target = args
                
                if strfind(target,"^cont") then 
                    if conditionals.target then
                        target = string.gsub(target, "cont", conditionals.target)
                    else
                        target = string.gsub(target, "cont", "target")
                    end
                end

                if UnitExists(target) then 
                    CleveRoids.TrueTarget = CleveRoids.GetGUID(target)
                    return true
                else
                    return false
                end
                
            end, conditionals, "truetarget")
        end
    end,
    
    boss = function(conditionals)
        return CleveRoids.ValidateCreatureType("worldboss", conditionals.target)
    end,
    
    noboss = function(conditionals)
        return not CleveRoids.ValidateCreatureType("worldboss", conditionals.target)
    end,
    
    onenemytarget = function(conditionals)
        if not conditionals.onenemytarget then return false end

        -- 使用共享的 CleveRoids.CountEnemiesTargetingMe（页面上方）by 武藤纯子酱 2026.9.11

        -- 无参数形式：存在即返回 true
        if type(conditionals.onenemytarget) == "string" then
            return CleveRoids.CountEnemiesTargetingMe(nil) > 0
        end

        -- 带参数形式：统计数量并比较
        return Multi(conditionals.onenemytarget, function(arg)
            if type(arg) ~= "table" then return false end
            local maxDistance = tonumber(string.match(arg.name or "", "dst(%d+)") or 5)
            local operator = arg.operator
            local threshold = tonumber(arg.amount)
            if not threshold or not operator then return false end

            local enemyCount = CleveRoids.CountEnemiesTargetingMe(maxDistance)

            -- 处理多重比较
            if arg.comparisons and type(arg.comparisons) == "table" then
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return false end
                    if not CleveRoids.comparators[comp.operator](enemyCount, comp.amount) then return false end
                end
                return true
            end

            if CleveRoids.operators[operator] then
                return CleveRoids.comparators[operator](enemyCount, threshold)
            end
            return false
        end, conditionals, "onenemytarget")
    end,

    noonenemytarget = function(conditionals)
        if not conditionals.noonenemytarget then return false end

        -- 使用共享的 CleveRoids.CountEnemiesTargetingMe（页面上方）by 武藤纯子酱 2026.9.11

        -- 无参数形式
        if type(conditionals.noonenemytarget) == "string" then
            return CleveRoids.CountEnemiesTargetingMe(nil) == 0
        end

        -- 带参数形式
        return NegatedMulti(conditionals.noonenemytarget, function(arg)
            if type(arg) ~= "table" then return false end
            local maxDistance = tonumber(string.match(arg.name or "", "dst(%d+)") or 5) -- 修复：补 arg.name 判空 by 武藤纯子酱 2026.9.11
            local operator = arg.operator
            local threshold = tonumber(arg.amount)
            if not threshold or not operator then return false end

            local enemyCount = CleveRoids.CountEnemiesTargetingMe(maxDistance)

            -- 多重比较时的否定逻辑
            if arg.comparisons and type(arg.comparisons) == "table" then
                for _, comp in ipairs(arg.comparisons) do
                    if not CleveRoids.operators[comp.operator] then return true end
                    if not CleveRoids.comparators[comp.operator](enemyCount, comp.amount) then return true end
                end
                return false
            end

            if CleveRoids.operators[operator] then
                return not CleveRoids.comparators[operator](enemyCount, threshold)
            end
            return true
        end, conditionals, "noonenemytarget")
    end,
    
    setscan = function(conditionals)
        if type(StatScanner_ScanAll) ~= "function" or type(conditionals.setscan) == "string" then
            return false
        end
        
        local currentTime = GetTime()
        if not CleveRoids.SetScan or ( currentTime - CleveRoids.SetScan ) > 1 then
            StatScanner_ScanAll()
            CleveRoids.SetScan = currentTime
        end
        
        return Multi(conditionals.setscan, function(args)
            if type(args) == "string" then
                local set = 0

                for k,v in pairs(StatScanner_setcount) do 
                    -- plain 匹配：用户值含 %()[].+ 等模式字符时不再抛 "malformed pattern" by 武藤纯子酱 2026.9.9
                    if k and strfind(k,args,1,true) then
                        return true
                    end
                end
                
                return false
            elseif type(args) == "table" then
                if not args.name then return false end
                
                local set = 0
                
                for k,v in pairs(StatScanner_setcount) do 
                    if k and strfind(k,args.name,1,true) then -- plain 匹配 by 武藤纯子酱 2026.9.9
                        set = tonumber(v.count)
                        break
                    end
                end
                
                -- Handle multi-comparison (e.g., >50&<80)
                if args.comparisons and type(args.comparisons) == "table" then
                    -- ALL comparisons must pass (AND logic)
                    for _, comp in ipairs(args.comparisons) do
                        if not CleveRoids.operators[comp.operator] then
                            return false
                        end
                        if comp.amount == nil then return false end -- 修复：比较量非数字 by 武藤纯子酱 2026.9.11
                        if not CleveRoids.comparators[comp.operator](set, comp.amount) then
                            return false
                        end
                    end
                    return true
                else
                    if not CleveRoids.operators[args.operator] then
                        return false
                    end
                    if args.amount == nil then return false end -- 修复：比较量非数字 by 武藤纯子酱 2026.9.11
                    if not CleveRoids.comparators[args.operator](set, args.amount) then
                        return false
                    end

                    return true
                end
            end
        end, conditionals, "setscan")
    end,
    
    nosetscan = function(conditionals)
        if type(StatScanner_ScanAll) ~= "function" or type(conditionals.nosetscan) == "string" then
            return false
        end
        
        local currentTime = GetTime()
        if not CleveRoids.SetScan or ( currentTime - CleveRoids.SetScan ) > 1 then
            StatScanner_ScanAll()
            CleveRoids.SetScan = currentTime
        end
        
        -- 修复：与其余 no* 条件保持一致——改用 NegatedMulti，使 / 表示 AND（全部缺失）、& 表示 OR（至少一个缺失） by 武藤纯子酱 2026.9.12
        return NegatedMulti(conditionals.nosetscan, function(args)
            if type(args) == "string" then
                local set = 0

                for k,v in pairs(StatScanner_setcount) do
                    if k and strfind(k,args,1,true) then -- plain 匹配 by 武藤纯子酱 2026.9.9
                        return false
                    end
                end

                return true
            elseif type(args) == "table" then
                if not args.name then return false end

                local set = 0

                for k,v in pairs(StatScanner_setcount) do
                    if k and strfind(k,args.name,1,true) then -- plain 匹配 by 武藤纯子酱 2026.9.9
                        set = tonumber(v.count)
                        break
                    end
                end

                -- Handle multi-comparison (e.g., >50&<80)
                if args.comparisons and type(args.comparisons) == "table" then
                    -- 修复：否定语义应为“任一比较失败→true、全部通过→false” by 武藤纯子酱 2026.9.12
                    for _, comp in ipairs(args.comparisons) do
                        if not CleveRoids.operators[comp.operator] then
                            return false
                        end
                        if comp.amount == nil then return false end -- 修复：比较量非数字 by 武藤纯子酱 2026.9.11
                        if not CleveRoids.comparators[comp.operator](set, comp.amount) then
                            return true
                        end
                    end
                    return false
                else
                    if not CleveRoids.operators[args.operator] then
                        return false
                    end
                    if args.amount == nil then return false end -- 修复：比较量非数字 by 武藤纯子酱 2026.9.11
                    if CleveRoids.comparators[args.operator](set, args.amount) then
                        return false
                    end

                    return true
                end
            end
        end, conditionals, "nosetscan")
    end,

    gettag = function(conditionals)
        if type(conditionals.gettag) == "string" then return false end

        if type(conditionals.gettag) == "table" then
            return Multi(conditionals.gettag, function(args)
                if not args or type(args) ~= "string" then return false end
                return CleveRoids.Tags[args]
            end, conditionals, "gettag")
        end
    end,
    
    nogettag = function(conditionals)
        if type(conditionals.nogettag) == "string" then return false end
    
        if type(conditionals.nogettag) == "table" then
            return NegatedMulti(conditionals.nogettag, function(args)
                if not args or type(args) ~= "string" then return false end
                return not CleveRoids.Tags[args]
            end, conditionals, "nogettag")
        end
    end,

    dispel = function(conditionals)
        if type(conditionals.dispel) == "string" then return false end
        if not conditionals.target then return false end
        return Multi(conditionals.dispel, function(args)
            if type(args) ~= "string" then return false end

            local searchNameLower = args and _string_lower(args) or nil

            local API = CleveRoids.NampowerAPI
            if API.FindUnitAuraDispel then
                return API.FindUnitAuraDispel(conditionals.target, searchNameLower)
            else
                for i = 1, 16 do
                    local texture, _, dispel, spellid = UnitDebuff(conditionals.target, i)
                    
                    if not texture then
                        return false
                    end
                    
                    if dispel and _string_lower(dispel) == searchNameLower then
                        return true
                    end
                end
                
                return false
            end
        end, conditionals, "dispel")
    end,

    nodispel = function(conditionals)
        if type(conditionals.nodispel) == "string" then return false end
        if not conditionals.target then return false end
        return NegatedMulti(conditionals.nodispel, function(args)
            if type(args) ~= "string" then return false end

            local searchNameLower = args and _string_lower(args) or nil

            local API = CleveRoids.NampowerAPI
            if API.FindUnitAuraDispel then
                return not API.FindUnitAuraDispel(conditionals.target, searchNameLower)
            else
                for i = 1, 16 do
                    local texture, _, dispel, spellid = UnitDebuff(conditionals.target, i)
                    
                    if not texture then
                        return true
                    end
                    
                    if dispel and _string_lower(dispel) == searchNameLower then
                        return false
                    end
                end
                
                return true
            end
        end, conditionals, "nodispel")
    end,

    mydispel = function(conditionals)
        if type(conditionals.mydispel) == "string" then return false end

        return Multi(conditionals.mydispel, function(args)
            if type(args) ~= "string" then return false end

            local searchNameLower = args and _string_lower(args) or nil

            local API = CleveRoids.NampowerAPI
            if API.FindUnitAuraDispel then
                return API.FindUnitAuraDispel(CleveRoids.GetGUID("player"), searchNameLower)
            else
                for i = 1, 16 do
                    local texture, _, dispel, spellid = UnitDebuff("player", i)
                    
                    if not texture then
                        return false
                    end
                    
                    if dispel and _string_lower(dispel) == searchNameLower then
                        return true
                    end
                end
                
                return false
            end
        end, conditionals, "mydispel")
    end,

    nomydispel = function(conditionals)
        if type(conditionals.nomydispel) == "string" then return false end

        return NegatedMulti(conditionals.nomydispel, function(args)
            if type(args) ~= "string" then return false end

            local searchNameLower = args and _string_lower(args) or nil

            local API = CleveRoids.NampowerAPI
            if API.FindUnitAuraDispel then
                return not API.FindUnitAuraDispel(CleveRoids.GetGUID("player"), searchNameLower)
            else
                for i = 1, 16 do
                    local texture, _, dispel, spellid = UnitDebuff("player", i)
                    
                    if not texture then
                        return true
                    end
                    
                    if dispel and _string_lower(dispel) == searchNameLower then
                        return false
                    end
                end
                
                return true
            end
        end, conditionals, "nomydispel")
    end,
    
    -- 新增条件：目标是否属于受伤最重的小队（支持受伤人数比较，缓存每帧结果） by 武藤纯子酱 2026.3.21
    mostwoundedgroup = function(conditionals)
        -- 修复：UnitXP 未安装时直接返回 false，避免 "attempt to call global 'UnitXP'"
        -- by 武藤纯子酱 2026.9.11
        if not CleveRoids.hasUnitXP then return false end
        return Multi(conditionals.mostwoundedgroup, function(args)
            local unit = conditionals.target
            if not unit or not UnitExists(unit) then return false end

            -- 解析 lost 阈值
            local lostThreshold = nil
            if args and type(args) == "table" and args.name and type(args.name) == "string" then
                local name = args.name
                local _, _, lostVal = string.find(name, "lost(%d+)")
                if lostVal then
                    lostThreshold = tonumber(lostVal)
                end
            end

            -- 生成缓存键（包含 lost 阈值和所有比较条件）
            local cacheKey = ""
            if args and type(args) == "table" then
                if lostThreshold then
                    cacheKey = cacheKey .. "lost" .. lostThreshold .. "|"
                end
                if args.comparisons and type(args.comparisons) == "table" then
                    for _, comp in ipairs(args.comparisons) do
                        cacheKey = cacheKey .. (comp.operator or "") .. tostring(comp.amount) .. "|"
                    end
                elseif args.operator then
                    cacheKey = cacheKey .. (args.operator or "") .. tostring(args.amount) .. "|"
                end
            end

            local cache = CleveRoids._mostWoundedGroupCache
            if not cache then
                cache = {}
                CleveRoids._mostWoundedGroupCache = cache
            end

            local bestGroupIdx = nil
            local cached = cache[cacheKey]
            if cached then
                bestGroupIdx = cached.bestGroupIdx
            else
                -- 分组统计
                local groupData = {}
                local hasRaid = UnitInRaid("player")
                local hasParty = not hasRaid and UnitInParty("player")

                local function addUnitToGroup(unitToken, groupIdx, lostHp)
                    if not unitToken or not UnitExists(unitToken) then return end
                    local hpLost = lostHp or (UnitHealthMax(unitToken) - CleveRoids.NampowerAPI.GetUnitHealth(unitToken))
                    if hpLost <= 0 then return end
                    if not groupData[groupIdx] then
                        groupData[groupIdx] = { total = 0, wounded = 0, minLost = math.huge }
                    end
                    groupData[groupIdx].total = groupData[groupIdx].total + hpLost
                    groupData[groupIdx].wounded = groupData[groupIdx].wounded + 1
                    groupData[groupIdx].minLost = math.min(groupData[groupIdx].minLost, hpLost)
                end

                if hasRaid then
                    for i = 1, GetNumRaidMembers() do
                        local unitToken = "raid" .. i
                        if UnitExists(unitToken) and not UnitIsDeadOrGhost(unitToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", unitToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", unitToken) < 40 then
                            local hpLost = UnitHealthMax(unitToken) - CleveRoids.NampowerAPI.GetUnitHealth(unitToken)
                            local _, _, groupIdx = GetRaidRosterInfo(i)
                            if not groupIdx then groupIdx = 1 end
                            addUnitToGroup(unitToken, groupIdx, hpLost)
                            local petToken = "raidpet" .. i
                            if UnitExists(petToken) and not UnitIsDeadOrGhost(petToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", petToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", petToken) < 40 then
                                local petHpLost = UnitHealthMax(petToken) - CleveRoids.NampowerAPI.GetUnitHealth(petToken)
                                addUnitToGroup(petToken, groupIdx, petHpLost)
                            end
                        end
                    end
                elseif hasParty then
                    for i = 1, GetNumPartyMembers() do
                        local unitToken = "party" .. i
                        if UnitExists(unitToken) and not UnitIsDeadOrGhost(unitToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", unitToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", unitToken) < 40 then
                            local hpLost = UnitHealthMax(unitToken) - CleveRoids.NampowerAPI.GetUnitHealth(unitToken)
                            addUnitToGroup(unitToken, 1, hpLost)
                            local petToken = "partypet" .. i
                            if UnitExists(petToken) and not UnitIsDeadOrGhost(petToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", petToken) and CleveRoids.SafeUnitXP("distanceBetween", "player", petToken) < 40 then
                                local petHpLost = UnitHealthMax(petToken) - CleveRoids.NampowerAPI.GetUnitHealth(petToken)
                                addUnitToGroup(petToken, 1, petHpLost)
                            end
                        end
                    end
                else
                    addUnitToGroup("player", 1, nil)
                    if UnitExists("pet") and not UnitIsDeadOrGhost("pet") then
                        local petHpLost = UnitHealthMax("pet") - CleveRoids.NampowerAPI.GetUnitHealth("pet")
                        addUnitToGroup("pet", 1, petHpLost)
                    end
                end

                -- 筛选满足所有条件的队伍
                local candidateGroups = {}
                for idx, data in pairs(groupData) do
                    local wounded = data.wounded
                    local minLost = data.minLost
                    local eligible = true

                    -- 检查最小失血阈值
                    if lostThreshold and minLost < lostThreshold then
                        eligible = false
                    end

                    -- 检查人数比较条件（支持多比较）
                    if eligible and args.comparisons and type(args.comparisons) == "table" then
                        for _, comp in ipairs(args.comparisons) do
                            local op = comp.operator
                            local amt = comp.amount
                            if op and amt and CleveRoids.comparators[op] then
                                if not CleveRoids.comparators[op](wounded, amt) then
                                    eligible = false
                                    break
                                end
                            end
                        end
                    end

                    -- 兼容旧的单比较语法
                    if eligible and args.operator and args.amount then
                        if CleveRoids.comparators[args.operator] then
                            eligible = CleveRoids.comparators[args.operator](wounded, args.amount)
                        else
                            eligible = false
                        end
                    end

                    if eligible then
                        table.insert(candidateGroups, { idx = idx, total = data.total, wounded = wounded })
                    end
                end

                if table.getn(candidateGroups) > 0 then
                    -- 选择受伤最重的小队（评分 = 总受伤量 × 受伤人数²）
                    local bestScore = -1
                    for _, g in ipairs(candidateGroups) do
                        local score = g.total * (g.wounded * g.wounded)
                        if score > bestScore then
                            bestScore = score
                            bestGroupIdx = g.idx
                        end
                    end
                end

                cache[cacheKey] = { bestGroupIdx = bestGroupIdx }
            end

            if not bestGroupIdx then return false end

            -- 确定目标所属的小队索引
            local targetGroupIdx = nil
            local unitName = UnitName(unit)
            if not unitName then return false end

            if UnitInRaid("player") then
                for i = 1, GetNumRaidMembers() do
                    local name, _, groupIdx = GetRaidRosterInfo(i)
                    if name and name == unitName then
                        targetGroupIdx = groupIdx or 1
                        break
                    end
                end
            elseif UnitInParty("player") then
                targetGroupIdx = 1
            else
                targetGroupIdx = 1
            end

            if not targetGroupIdx then return false end

            return targetGroupIdx == bestGroupIdx
        end, conditionals, "mostwoundedgroup")
    end,

    -- 新增条件spec by 武藤纯子酱 2026.5.13
    -- [spec:1] - 当前天赋与保存的套装1完全相同
    -- [spec:射击] - 当前天赋与名称为“射击”的套装完全相同
    -- [spec:1/2] - OR 逻辑：匹配套装1或套装2
    -- [spec:1&2] - AND 逻辑：同时匹配套装1和套装2（通常无意义，但语法支持）
    spec = function(conditionals)
        return Multi(conditionals.spec, function(identifier)
            return CleveRoids.IsCurrentTalentSetMatch(identifier)
        end, conditionals, "spec")
    end,

    -- [nospec:1] - 当前天赋不与套装1完全相同
    -- [nospec:射击] - 当前天赋不与名称为“射击”的套装完全相同
    -- [nospec:1/2] - NOR 逻辑：不和套装1匹配且不和套装2匹配
    -- [nospec:1&2] - NAND 逻辑：至少有一个不匹配（即不是同时匹配两个，等价于 OR 不匹配）
    nospec = function(conditionals)
        return NegatedMulti(conditionals.nospec, function(identifier)
            return not CleveRoids.IsCurrentTalentSetMatch(identifier)
        end, conditionals, "nospec")
    end,

    -- 新增条件samespell by 武藤纯子酱 2026.5.15
    samespell = function(conditionals)
        local lastID = CleveRoids.lastSpellID
        if not lastID then return false end

        local currentAction = conditionals.action
        if not currentAction then return false end

        local currentID = GetSpellIDFromAction(currentAction)
        if not currentID then return false end

        return currentID == lastID
    end,

    nosamespell = function(conditionals)
        -- 直接取反
        local lastID = CleveRoids.lastSpellID
        if not lastID then return true end  -- 从未施法，则视为不同

        local currentAction = conditionals.action
        if not currentAction then return true end

        local currentID = GetSpellIDFromAction(currentAction)
        if not currentID then return true end

        return currentID ~= lastID
    end,

    -- 新增条件indoor/outdoor by 武藤纯子酱 2026.5.22
    indoor = function(conditionals)
        if CleveRoids.hasSuperwow then
            local version = tonumber(SUPERWOW_VERSION)
            if version and version > 2 and IsIndoors and type(IsIndoors) == "function" then
                local Indoors = IsIndoors()
                if Indoors then 
                    return true
                else
                    return false
                end
            end
        end

        if not CleveRoids.hasUnitXP then return false end
        local ok, unitxp = pcall(UnitXP, "version")

        if ok and unitxp and strfind(unitxp, "UnitXP_SP3_X") then
            return CleveRoids.SafeUnitXP("isOutdoors") == 1
        end
    end,

    outdoor = function(conditionals)
        if CleveRoids.hasSuperwow then
            local version = tonumber(SUPERWOW_VERSION)
            if version and version > 2 and IsIndoors and type(IsIndoors) == "function" then
                local Indoors = IsIndoors()
                if Indoors then 
                    return false
                else
                    return true
                end
            end
        end

        if not CleveRoids.hasUnitXP then return false end
        local ok, unitxp = pcall(UnitXP, "version")

        if ok and unitxp and strfind(unitxp, "UnitXP_SP3_X") then
            return CleveRoids.SafeUnitXP("isOutdoors") == 0
        end
    end,

    -- 新增条件mycombat/nomycombat by 武藤纯子酱 2026.5.22
    mycombat = function(conditionals)
        -- PERFORMANCE: Use event-driven cache for player combat state
        local cached = CleveRoids._cachedPlayerInCombat
        if cached ~= nil then
            return cached
        end
        -- Fallback if cache not yet initialized
        return UnitAffectingCombat("player")
    end,

    nomycombat = function(conditionals)
        -- PERFORMANCE: Use event-driven cache for player combat state
        local cached = CleveRoids._cachedPlayerInCombat
        if cached ~= nil then
            return not cached
        end
        -- Fallback if cache not yet initialized
        return not UnitAffectingCombat("player")
    end,

    -- [inscreen] - Target is in line of screen
    -- [inscreen:>N] - More than N enemies are in line of screen (count mode)
    inscreen = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end
        local _, unitxp = pcall(UnitXP, "version")

        if not unitxp or not strfind(unitxp, "UnitXP_SP3_X") then return false end
        -- Check for count mode: [inscreen:>1]
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.inscreen)
        if countArgs then
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                return CleveRoids.SafeUnitXP("screenPos", unit, 100)
            end, "player")
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return CleveRoids.SafeUnitXP("screenPos", unit, 100)
    end,

    -- [noinscreen] - Target is NOT in line of screen
    -- [noinscreen:>N] - More than N enemies are NOT in line of screen (count mode)
    noinscreen = function(conditionals)
        if not CleveRoids.hasUnitXP then return false end
        local _, unitxp = pcall(UnitXP, "version")

        if not unitxp or not strfind(unitxp, "UnitXP_SP3_X") then return false end
        -- Check for count mode: [noinscreen:>1]
        local countArgs = CleveRoids.GetCountModeArgs(conditionals.noinscreen)
        if countArgs then
            local count = CleveRoids.CountEnemiesMatching(function(unit)
                return not CleveRoids.SafeUnitXP("screenPos", unit, 100)
            end, "player")
            return CleveRoids.comparators[countArgs.operator](count, countArgs.amount)
        end

        local unit = conditionals.target or "target"
        if not UnitExists(unit) then return false end
        return not CleveRoids.SafeUnitXP("screenPos", unit, 100)
    end,

    -- 新增条件durability by 武藤纯子酱 2026.7.1
    durability = function(conditionals)
        if not CleveRoids.hasNampower then return false end
        return Multi(conditionals.durability, function(args)
            -- 如果 args 是纯字符串，转为表格形式
            if type(args) == "string" then
                args = { name = args }
            end

            if type(args) ~= "table" or not args.name then
                return false
            end

            local slotId = CleveRoids.GetSlotIdFromName(args.name)
            if not slotId then
                return false
            end

            local percent = CleveRoids.GetSlotDurabilityPercent(slotId)
            if percent == nil then
                return false
            end

            -- 处理多比较（例如 >50&<80）
            if args.comparisons and type(args.comparisons) == "table" then
                for _, comp in ipairs(args.comparisons) do
                    if not CleveRoids.comparators[comp.operator] then
                        return false
                    end
                    if not CleveRoids.comparators[comp.operator](percent, comp.amount) then
                        return false
                    end
                end
                return true
            end

            -- 处理单一比较（例如 >50）
            if args.operator and args.amount then
                return CleveRoids.comparators[args.operator](percent, args.amount)
            end

            -- 无运算符：仅检查耐久度是否存在（即装备了有耐久的物品）
            return true
        end, conditionals, "durability")
    end,

    -- [message:文本] - 匹配来自其他玩家的消息 by 武藤纯子酱 2026.8.10
    message = function(conditionals)
        local msgText = conditionals.message
        if not msgText then return false end

        local now = GetTime()
        local queue = CleveRoids.messageQueue
        if not queue or table.getn(queue) == 0 then return false end

        -- 支持 [message:文本1/文本2] 的多值 OR 匹配
        local texts
        if type(msgText) == "table" then
            texts = msgText
        else
            texts = { msgText }
        end

        for _, text in ipairs(texts) do
            for i, entry in ipairs(queue) do
                if now - entry.timestamp <= 1.5 and entry.text == text then
                    table.remove(queue, i)      -- 消费该消息
                    conditionals.target = entry.guid
                    return true
                end
            end
        end
        return false
    end,

    -- 新增 petknown条件 by 武藤纯子酱 2026.8.10
    petknown = function(conditionals)
        return Multi(conditionals.petknown, function(args)
            if not args or type(args) ~= "string" then return false end

            local baseName = CleveRoids.StripRank(args)
            local rankNum = string.match(args, CleveRoids.Localized.SpellRank2)
            if rankNum then rankNum = tonumber(rankNum) end

            local petSpell = CleveRoids.GetPetSpell(baseName)
            if not petSpell then
                return false
            end

            if not rankNum then
                return true
            end

            local actualRank = nil
            if petSpell.subtext then
                actualRank = tonumber(string.match(petSpell.subtext, "(%d+)"))
            end

            return actualRank and actualRank == rankNum
        end, conditionals, "petknown")
    end,

    nopetknown = function(conditionals)
        return NegatedMulti(conditionals.nopetknown, function(args)
            if not args or type(args) ~= "string" then return false end

            local baseName = CleveRoids.StripRank(args)
            local rankNum = string.match(args, CleveRoids.Localized.SpellRank2)
            if rankNum then rankNum = tonumber(rankNum) end

            local petSpell = CleveRoids.GetPetSpell(baseName)
            if not petSpell then
                return true
            end

            if not rankNum then
                return false
            end

            local actualRank = nil
            if petSpell.subtext then
                actualRank = tonumber(string.match(petSpell.subtext, "(%d+)"))
            end

            return not actualRank or actualRank ~= rankNum
        end, conditionals, "nopetknown")
    end,

    -- [cursor] 光标上有拖拽物（正式服语义：GetCursorInfo 非空）by 武藤纯子酱 2026.9.3
    -- 1.12 无 GetCursorInfo，经原生布尔探测 API 间接实现：
    --   CursorHasItem()（拖拽背包物品）/ CursorHasSpell()（拖拽法术书技能）/ CursorHasMacro()（拖拽宏图标）
    -- （1.12 无 CursorHasMoney——金币不可拖入动作条；CursorHasItem 覆盖 1.12 全部剩余拖拽类型）
    -- 注意与 @cursor（地面指向施放）语义无关，互不冲突
    cursor = function(conditionals)
        if CursorHasItem and CursorHasItem() then return true end
        if CursorHasSpell and CursorHasSpell() then return true end
        if CursorHasMacro and CursorHasMacro() then return true end
        return false
    end,

    nocursor = function(conditionals)
        return not CleveRoids.Keywords.cursor(conditionals)
    end,

    -- 正式服拼法别名：indoors/outdoors → indoor/outdoor（室内外检测逻辑完全一致）；
    -- worn/noworn → equipped/noequipped（正式服 equipped 的官方别名）by 武藤纯子酱 2026.9.3
    -- worn 透传需同步移植 _groups/_operators 元数据（parser 按条件名分组存储，
    -- equipped 实现按 "equipped" 键查组），否则 [worn:a],[worn:b] 多实例分组失效
    indoors = function(conditionals)
        return CleveRoids.Keywords.indoor(conditionals)
    end,
    outdoors = function(conditionals)
        return CleveRoids.Keywords.outdoor(conditionals)
    end,
}

-- worn/noworn → equipped/noequipped 透传：把源键的值与分组元数据移植到目标键，
-- 调用目标实现后还原，避免污染 conditionals 表 by 武藤纯子酱 2026.9.3
local function PassthroughEquippedAlias(conditionals, srcKey, dstKey)
    -- 修复：原实现在调用方 `for k,v in pairs(conditionals)` 遍历期间直接增删 conditionals
    -- 的键（含 _groups/_operators），属 Lua 未定义行为（可能 "invalid key to 'next'" 或
    -- 跳过/重复求值）。改为在浅拷贝的 proxy 上完成移植与求值，绝不改原表 by 武藤纯子酱 2026.9.11
    local proxy = {}
    for k, v in pairs(conditionals) do proxy[k] = v end
    proxy[dstKey] = conditionals[srcKey]

    if conditionals._groups then
        local g = {}
        for k, v in pairs(conditionals._groups) do g[k] = v end
        if g[srcKey] then g[dstKey] = g[srcKey] end
        proxy._groups = g
    end
    if conditionals._operators then
        local o = {}
        for k, v in pairs(conditionals._operators) do o[k] = v end
        if o[srcKey] then o[dstKey] = o[srcKey] end
        proxy._operators = o
    end

    local ok, res = pcall(CleveRoids.Keywords[dstKey], proxy)
    if ok then return res end
    return false
end

CleveRoids.Keywords.worn = function(conditionals)
    return PassthroughEquippedAlias(conditionals, "worn", "equipped")
end
CleveRoids.Keywords.noworn = function(conditionals)
    return PassthroughEquippedAlias(conditionals, "noworn", "noequipped")
end

-- =============================================================================
-- MULTISCAN SYSTEM
-- =============================================================================
-- [multiscan:priority] - Scan nearby enemies and find best target matching priority
-- Requires UnitXP_SP3 for enemy enumeration
-- Uses SuperWoW for soft-casting (CastSpellByName with GUID)

-- Raid mark indices (WoW API GetRaidTargetIndex values)
CleveRoids.RAID_MARKS = {
    star = 1, circle = 2, diamond = 3, triangle = 4,
    moon = 5, square = 6, cross = 7, skull = 8,
}

-- Resolve any raid mark identifier to its native "mark#" unit token.
-- Accepts named marks (skull, cross, etc.) or direct mark# tokens (mark1-mark8).
-- Returns: "mark#" string if valid, nil otherwise.
function CleveRoids.ResolveRaidMarkUnit(unitStr)
    if not unitStr then return nil end
    local namedIdx = CleveRoids.RAID_MARKS[unitStr]
    if namedIdx then return "mark" .. namedIdx end
    local _, _, markNum = string.find(unitStr, "^mark(%d+)$")
    local n = markNum and tonumber(markNum)
    if n and n >= 1 and n <= 8 then return "mark" .. n end
    return nil
end

-- Priority types for multiscan
-- String values = custom handling, number values = raid mark index
CleveRoids.MULTISCAN_PRIORITIES = {
    -- Distance-based (use UnitXP direct targeting where possible)
    nearest   = "nearest",
    farthest  = "farthest",
    -- Health percentage
    highesthp = "highesthp",
    lowesthp  = "lowesthp",
    -- Raw health value
    highestrawhp = "highestrawhp",
    lowestrawhp  = "lowestrawhp",
    -- Raid mark order (skull → cross → square → moon → triangle → diamond → circle → star)
    markorder = "markorder",
    -- Reverse mark order (star → circle → diamond → triangle → moon → square → cross → skull)
    rmarkorder = "rmarkorder",
    -- Individual raid marks by name (direct unit reference via SuperWoW "mark#" tokens)
    skull    = 8, cross = 7, square = 6, moon = 5,
    triangle = 4, diamond = 3, circle = 2, star = 1,
    -- Individual raid marks by number (mark1=star through mark8=skull)
    mark8 = 1, mark7 = 2, mark6 = 3, mark5 = 4,
    mark4 = 5, mark3 = 6, mark2 = 7, mark1 = 8,

    -- 新增排序条件 by 武藤纯子酱 2026.2.4
    highestarmor = "highestarmor",
    lowestarmor = "lowestarmor",
    highestholyresist = "highestholyresist",
    lowestholyresist = "lowestholyresist",
    highestfireresist = "highestfireresist",
    lowestfireresist = "lowestfireresist",
    highestnatureresist = "highestnatureresist",
    lowestnatureresist = "lowestnatureresist",
    highestfrostresist = "highestfrostresist",
    lowestfrostresist = "lowestfrostresist",
    highestshadowresist = "highestshadowresist",
    lowestshadowresist = "lowestshadowresist",
    highestarcaneresist = "highestarcaneresist",
    lowestarcaneresist = "lowestarcaneresist",
    highestttk = "highestttk",
    lowestttk = "lowestttk",
}

-- Static conditionals that don't depend on target (checked before scanning)
CleveRoids.STATIC_CONDITIONALS = {
    group = true, nogroup = true,
    combat = true, nocombat = true, ic = true, ooc = true,
    zone = true, nozone = true,
    stealth = true, nostealth = true, stl = true, nostl = true,
    form = true, noform = true, stance = true, nostance = true,
    equipped = true, noequipped = true, eq = true, noeq = true,
    set = true, noset = true,
    inbag = true, noinbag = true,
    mod = true, nomod = true,
    keydown = true, nokeydown = true,
    swimming = true, noswimming = true, swim = true, noswim = true,
    rooted = true, norooted = true,
    resting = true, noresting = true,
    mycombat = true, nomycombat = true, -- 新增 by 武藤纯子酱 2026.5.22
    actionbar = true, bar = true, -- 动作条页判断（1.12 经 CURRENT_ACTIONBAR_PAGE 实现）by 武藤纯子酱 2026.9.3
    bonusbar = true, nobonusbar = true, -- 临时动作条（BonusActionBarFrame/形态映射）by 武藤纯子酱 2026.9.3
}

--- Calculate score for a unit based on priority type
--- @param unit string Unit token or GUID
--- @param priority string Priority type (e.g., "nearest", "highesthp")
--- @param currentTargetGuid string|nil GUID of player's current target (exempt from combat check)
--- @param specifiedUnitGuid string|nil GUID of @unit specified in macro (also exempt from combat check)
--- @param friendly boolean|nil If true, scan friendly units instead of enemies
--- @return number|nil Score (lower = better) or nil if invalid candidate
function CleveRoids.GetMultiscanScore(unit, priority, currentTargetGuid, specifiedUnitGuid, friendly)
    if not unit or not UnitExists(unit) then return nil end
    if UnitIsDeadOrGhost(unit) then return nil end

    if friendly then
        -- Must be friendly
        if not UnitIsFriend("player", unit) then return nil end
    else
        -- Must be attackable
        if not UnitCanAttack("player", unit) then return nil end

        -- Combat check: must be in combat with player, UNLESS it's current target OR specified @unit
        local unitGuid = CleveRoids.GetGUID(unit)
        local isCurrentTarget = currentTargetGuid and unitGuid == currentTargetGuid
        local isSpecifiedUnit = specifiedUnitGuid and unitGuid == specifiedUnitGuid
        if not isCurrentTarget and not isSpecifiedUnit and not UnitAffectingCombat(unit) then
            return nil
        end
    end

    -- Calculate score based on priority
    if priority == "nearest" then
        if CleveRoids.hasUnitXP then
            local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
            return distance or 9999
        end
        return 0  -- No distance info, treat as equal

    elseif priority == "farthest" then
        if CleveRoids.hasUnitXP then
            local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
            return distance and -distance or -9999
        end
        return 0

    elseif priority == "highesthp" then
        local maxHp = UnitHealthMax(unit)
        if maxHp <= 0 then return nil end
        local hpPct = 100 * CleveRoids.NampowerAPI.GetUnitHealth(unit) / maxHp -- 用CleveRoids.NampowerAPI.GetUnitHealth替代UnitHealth，识别假死等特殊情况 by 武藤纯子酱 2026.1.14
        return -hpPct  -- Negative so highest becomes lowest score

    elseif priority == "lowesthp" then
        local maxHp = UnitHealthMax(unit)
        if maxHp <= 0 then return nil end
        local hpPct = 100 * CleveRoids.NampowerAPI.GetUnitHealth(unit) / maxHp -- 用CleveRoids.NampowerAPI.GetUnitHealth替代UnitHealth，识别假死等特殊情况 by 武藤纯子酱 2026.1.14
        return hpPct

    elseif priority == "highestrawhp" then
        local rawHp = CleveRoids.NampowerAPI.GetUnitHealth(unit) -- 用CleveRoids.NampowerAPI.GetUnitHealth替代UnitHealth，识别假死等特殊情况 by 武藤纯子酱 2026.1.14
        return -rawHp  -- Negative so highest becomes lowest score

    elseif priority == "lowestrawhp" then
        local rawHp = CleveRoids.NampowerAPI.GetUnitHealth(unit) -- 用CleveRoids.NampowerAPI.GetUnitHealth替代UnitHealth，识别假死等特殊情况 by 武藤纯子酱 2026.1.14
        return rawHp

    -- 新增排序条件 by 武藤纯子酱 2026.2.4
    elseif priority == "highestarmor" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return -resistances[1]
    elseif priority == "lowestarmor" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return resistances[1]

    elseif priority == "highestholyresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return -resistances[2]
    elseif priority == "lowestholyresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return resistances[2]

    elseif priority == "highestfireresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return -resistances[3]
    elseif priority == "lowestfireresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return resistances[3]

    elseif priority == "highestnatureresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return -resistances[4]
    elseif priority == "lowestnatureresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return resistances[4]

    elseif priority == "highestfrostresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return -resistances[5]
    elseif priority == "lowestfrostresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return resistances[5]

    elseif priority == "highestshadowresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return -resistances[6]
    elseif priority == "lowestshadowresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return resistances[6]

    elseif priority == "highestarcaneresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return -resistances[7]
    elseif priority == "lowestarcaneresist" then
        local resistances = CleveRoids.NampowerAPI.GetUnitFieldValue(unit, "resistances"); if type(resistances) ~= "table" then return 0 end -- 修复：单位数据未加载时 GetUnitField 返回 nil，直接取 [N] 会报错（resistances 不在 party_member_fields 回退范围内） by 武藤纯子酱 2026.8.31
        return resistances[7]

    elseif priority == "highestttk" then
        local ttk = CleveRoids.GetTargetDeathTime(unit)
        return -ttk
    elseif priority == "lowestttk" then
        local ttk = CleveRoids.GetTargetDeathTime(unit)
        return ttk
    end

    return 0  -- Unknown priority, treat as equal
end

--- Check if a candidate passes all target-dependent conditionals
--- @param conditionals table The conditionals table
--- @param candidateUnit string Unit token or GUID to test
--- @return boolean True if candidate passes all conditionals
function CleveRoids.ValidateMultiscanCandidate(conditionals, candidateUnit)
    local originalTarget = conditionals.target
    conditionals.target = candidateUnit

    local passes = true
    for k, _ in pairs(conditionals) do
        -- Skip static conditionals (already checked) and metadata
        if not CleveRoids.ignoreKeywords[k] and not CleveRoids.STATIC_CONDITIONALS[k] then
            local fn = CleveRoids.Keywords[k]
            if fn and not fn(conditionals) then
                passes = false
                break
            end
        end
    end

    conditionals.target = originalTarget
    return passes
end

--- Check static conditionals before scanning
--- @param conditionals table The conditionals table
--- @return boolean True if all static conditionals pass
function CleveRoids.CheckStaticConditionals(conditionals)
    for k, _ in pairs(conditionals) do
        if CleveRoids.STATIC_CONDITIONALS[k] then
            local fn = CleveRoids.Keywords[k]
            if fn and not fn(conditionals) then
                return false
            end
        end
    end
    return true
end

--- Main multiscan resolution function
--- Scans enemies using UnitXP, finds best target matching priority and conditionals
--- @param conditionals table The conditionals table containing multiscan value
--- @param specifiedUnit string|nil The @unit specified in the macro (exempt from combat check)
--- @return string|nil GUID of best target, or nil if none found
function CleveRoids.ResolveMultiscanTarget(conditionals, specifiedUnit)
    -- Require UnitXP for enemy scanning (friendly mode doesn't need it)
    local friendly = conditionals.help and true or false
    if not friendly and not CleveRoids.hasUnitXP then
        return nil
    end

    -- Parse priority from conditionals.multiscan
    local priority = nil
    if type(conditionals.multiscan) == "table" then
        priority = conditionals.multiscan[1]
        -- 修复：带比较符时该值是表条目（{name,operator,amount}），取 .name，
        -- 否则下方 Trim(表) 会崩 by 武藤纯子酱 2026.9.11
        if type(priority) == "table" then
            priority = priority.name
        end
    elseif type(conditionals.multiscan) == "string" then
        priority = conditionals.multiscan
    end

    if not priority then return nil end
    priority = string.lower(CleveRoids.Trim(priority))

    -- Parse custom mark order: "markorder:876" → base="markorder", customOrder="876"
    -- Also supports "rmarkorder:876" for reverse base with custom order
    local customMarkOrder = nil
    local basePriority = priority
    local _, _, base, order = string.find(priority, "^(r?markorder):(%d+)$")
    if base then
        basePriority = base
        customMarkOrder = order
    end

    -- Validate priority type
    local priorityType = CleveRoids.MULTISCAN_PRIORITIES[basePriority]
    if not priorityType then
        CleveRoids.Print("|cffff0000[multiscan]|r Unknown priority: " .. priority)
        return nil
    end

    -- Check static conditionals first (group, combat, zone, etc.)
    if not CleveRoids.CheckStaticConditionals(conditionals) then
        return nil
    end

    -- Save current target for restoration and combat-check exemption
    local currentTargetGuid = nil
    if UnitExists("target") then
        currentTargetGuid = CleveRoids.GetGUID("target")
    end

    -- Resolve specified @unit GUID (also exempt from combat check)
    local specifiedUnitGuid = nil
    if specifiedUnit and not CleveRoids.IsSpecialUnitTarget(specifiedUnit) and UnitExists(specifiedUnit) then -- 新增遍历关键字的过滤 by 武藤纯子酱 2026.6.5（特殊标识清单统一见 Init.lua）
        specifiedUnitGuid = CleveRoids.GetGUID(specifiedUnit)
    end

    -- Friendly mode: scan party/raid members instead of enemies
    if friendly then
        local candidates = {}
        local seenGuids = {}

        local function evaluateFriendly(unit)
            if not UnitExists(unit) then return end
            local guid = CleveRoids.GetGUID(unit)
            if not guid or seenGuids[guid] then return end
            seenGuids[guid] = true

            local score = CleveRoids.GetMultiscanScore(unit, priorityType, currentTargetGuid, specifiedUnitGuid, true)
            if not score then return end

            if CleveRoids.ValidateMultiscanCandidate(conditionals, guid) then
                table.insert(candidates, { guid = guid, score = score })
            end
        end

        -- Exclude player — distance 0 always wins nearest, and self-targeting
        -- is better served by @player; raid# tokens include the player already
        -- when in a raid group, so seenGuids will deduplicate

        -- Scan party or raid members
        if GetNumRaidMembers() > 0 then
            for i = 1, 40 do
                local unit = "raid" .. i
                if not UnitIsUnit(unit, "player") then
                    evaluateFriendly(unit)
                    evaluateFriendly("raidpet" .. i)
                end
            end
        else
            for i = 1, 4 do
                evaluateFriendly("party" .. i)
                evaluateFriendly("partypet" .. i)
            end
        end

        if table.getn(candidates) == 0 then
            return nil
        end

        table.sort(candidates, function(a, b) return a.score < b.score end)
        return candidates[1].guid
    end

    -- Handle raid mark priorities (direct unit reference)
    if type(priorityType) == "number" then
        local markUnit = "mark" .. priorityType
        if UnitExists(markUnit) then
            local isValid
            if friendly then
                isValid = UnitIsFriend("player", markUnit)
            else
                isValid = UnitCanAttack("player", markUnit)
            end
            if isValid and CleveRoids.ValidateMultiscanCandidate(conditionals, markUnit) then
                return CleveRoids.GetGUID(markUnit)
            end
        end
        return nil  -- Raid mark not found or doesn't pass conditionals
    end

    -- Handle markorder / rmarkorder priority
    -- markorder: skull(8) → star(1) default, or custom order via "markorder:876"
    -- rmarkorder: star(1) → skull(8) default, or custom order via "rmarkorder:138"
    if priorityType == "markorder" or priorityType == "rmarkorder" then
        -- Build mark iteration order
        local markIndices
        if customMarkOrder then
            -- Custom order: each digit is a raid mark index (1=star, 8=skull)
            markIndices = {}
            for i = 1, string.len(customMarkOrder) do
                local digit = tonumber(string.sub(customMarkOrder, i, i))
                if digit and digit >= 1 and digit <= 8 then
                    table.insert(markIndices, digit)
                end
            end
        elseif priorityType == "rmarkorder" then
            -- Reverse: star(1) → skull(8)
            markIndices = { 1, 2, 3, 4, 5, 6, 7, 8 }
        else
            -- Default: skull(8) → star(1)
            markIndices = { 8, 7, 6, 5, 4, 3, 2, 1 }
        end

        for _, markIndex in ipairs(markIndices) do
            local markUnit = "mark" .. markIndex
            if UnitExists(markUnit) then
                local isValid
                if friendly then
                    isValid = UnitIsFriend("player", markUnit)
                else
                    isValid = UnitCanAttack("player", markUnit)
                end
                if isValid and CleveRoids.ValidateMultiscanCandidate(conditionals, markUnit) then
                    return CleveRoids.GetGUID(markUnit)
                end
            end
        end
        return nil  -- No valid marked target found
    end

    -- Handle UnitXP direct targeting for simple priorities
    if priorityType == "nearest" then
        -- If no specified unit, try UnitXP's nearestEnemy directly for efficiency
        if not specifiedUnitGuid then
            local found = CleveRoids.SafeUnitXP("target", "nearestEnemy")
            if found and UnitExists("target") then
                local foundGuid = CleveRoids.GetGUID("target")
                -- Restore original target
                if currentTargetGuid then
                    TargetUnit(currentTargetGuid)
                else
                    ClearTarget()
                end
                -- Validate the found target
                if CleveRoids.ValidateMultiscanCandidate(conditionals, foundGuid) then
                    return foundGuid
                end
            else
                -- Restore target if nearestEnemy failed
                if currentTargetGuid then
                    TargetUnit(currentTargetGuid)
                else
                    ClearTarget()
                end
            end
        end
        -- Fall through to custom scan if nearest didn't pass validation
    end

    if priorityType == "highesthp" then
        -- If no specified unit, try UnitXP's mostHP directly for efficiency
        if not specifiedUnitGuid then
            local found = CleveRoids.SafeUnitXP("target", "mostHP")
            if found and UnitExists("target") then
                local foundGuid = CleveRoids.GetGUID("target")
                -- Restore original target
                if currentTargetGuid then
                    TargetUnit(currentTargetGuid)
                else
                    ClearTarget()
                end
                -- Validate the found target
                if CleveRoids.ValidateMultiscanCandidate(conditionals, foundGuid) then
                    return foundGuid
                end
            end
            -- Restore target if mostHP failed validation
            if currentTargetGuid then
                TargetUnit(currentTargetGuid)
            else
                ClearTarget()
            end
        end
        -- Fall through to custom scan if there's a specified unit or built-in didn't pass validation
    end

    -- Custom scan for complex priorities (lowesthp, highestrawhp, lowestrawhp, farthest)
    -- Also used as fallback if UnitXP direct targeting didn't pass validation
    local candidates = {}  -- { { guid = X, score = Y }, ... }
    local seenGuids = {}

    -- Helper to evaluate a candidate
    local function evaluateCandidate(unit)
        if not UnitExists(unit) then return end

        local guid = CleveRoids.GetGUID(unit)
        if not guid or seenGuids[guid] then return end
        seenGuids[guid] = true

        -- Cache GUID -> name mapping for immunity checks
        -- This is needed because immune enemies may never have debuffs tracked,
        -- but we still need their name for immunity lookups
        local unitName = UnitName(unit)
        if unitName and unitName ~= "" and unitName ~= "Unknown" then
            local lib = CleveRoids.libdebuff
            if lib and lib.guidToName then
                local normalizedGuid = CleveRoids.NormalizeGUID(guid)
                if normalizedGuid then
                    lib.guidToName[normalizedGuid] = unitName
                end
            end
        end

        local score = CleveRoids.GetMultiscanScore(unit, priorityType, currentTargetGuid, specifiedUnitGuid)
        if not score then return end

        -- Validate against target-dependent conditionals
        if CleveRoids.ValidateMultiscanCandidate(conditionals, guid) then
            table.insert(candidates, { guid = guid, score = score })
        end
    end

    -- Always consider current target (exempt from combat check via GetMultiscanScore)
    if currentTargetGuid then
        evaluateCandidate("target")
    end

    -- Also consider specified @unit (exempt from combat check via GetMultiscanScore)
    if specifiedUnitGuid and specifiedUnitGuid ~= currentTargetGuid then
        evaluateCandidate(specifiedUnit)
    end

    -- Include all raid-marked enemies as candidates (mark1-mark8)
    -- These may be outside nextEnemyConsideringDistance range/cone
    for markIdx = 1, 8 do
        local markUnit = "mark" .. markIdx
        if UnitExists(markUnit) then
            evaluateCandidate(markUnit)
        end
    end

    if specifiedUnit == "filterparty" then -- 新增@filterparty支持 by 武藤纯子酱 2026.2.5
        -- 检查小队成员
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do            
                -- 检查队员
                local unit = "party"..i            
                if UnitExists(unit) then
                    local guid = CleveRoids.GetGUID(unit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end
                    
                -- 检查宠物
                local petUnit = "partypet"..i
                if UnitExists(petUnit) then
                    local guid = CleveRoids.GetGUID(petUnit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end            
            end
        end
            
        if UnitExists("player") then
            local guid = CleveRoids.GetGUID("player")
            if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                evaluateCandidate(guid)
            end
        end
                
        if UnitExists("pet") then
            local guid = CleveRoids.GetGUID("pet")
            if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                evaluateCandidate(guid)
            end
        end
        
        -- 如果有合适的候选者，选择分数最好的
        if table.getn(candidates) > 0 then
            table.sort(candidates, function(a, b) return a.score < b.score end)
            return candidates[1].guid
        end
    elseif specifiedUnit == "filterraid" then -- 新增@filterraid支持 by 武藤纯子酱 2026.2.5
        -- 检查团队成员
        if UnitInRaid("player") then
            for i = 1, GetNumRaidMembers() do            
                -- 检查队员
                local unit = "raid"..i            
                if UnitExists(unit) then
                    local guid = CleveRoids.GetGUID(unit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end
                    
                -- 检查宠物
                local petUnit = "raidpet"..i
                if UnitExists(petUnit) then
                    local guid = CleveRoids.GetGUID(petUnit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end            
            end
        end
            
        if UnitExists("player") then
            local guid = CleveRoids.GetGUID("player")
            if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                evaluateCandidate(guid)
            end
        end
                
        if UnitExists("pet") then
            local guid = CleveRoids.GetGUID("pet")
            if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                evaluateCandidate(guid)
            end
        end
        
        -- 如果有合适的候选者，选择分数最好的
        if table.getn(candidates) > 0 then
            table.sort(candidates, function(a, b) return a.score < b.score end)
            return candidates[1].guid
        end
    elseif specifiedUnit == "filter" then -- 新增@filter支持 by 武藤纯子酱 2026.2.5
        -- 检查团队成员
        if UnitInRaid("player") then
            for i = 1, GetNumRaidMembers() do            
                -- 检查队员
                local unit = "raid"..i            
                if UnitExists(unit) then
                    local guid = CleveRoids.GetGUID(unit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end
                    
                -- 检查宠物
                local petUnit = "raidpet"..i
                if UnitExists(petUnit) then
                    local guid = CleveRoids.GetGUID(petUnit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end                    
            end
        -- 没有团队则检查队伍
        elseif GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do            
                -- 检查队员
                local unit = "party"..i            
                if UnitExists(unit) then
                    local guid = CleveRoids.GetGUID(unit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end
                    
                -- 检查宠物
                local petUnit = "partypet"..i
                if UnitExists(petUnit) then
                    local guid = CleveRoids.GetGUID(petUnit)
                    if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end        
            end
        end
            
        if UnitExists("player") then
            local guid = CleveRoids.GetGUID("player")
            if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                evaluateCandidate(guid)
            end
        end
                
        if UnitExists("pet") then
            local guid = CleveRoids.GetGUID("pet")
            if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                evaluateCandidate(guid)
            end
        end
    
        -- 如果有合适的候选者，选择分数最好的
        if table.getn(candidates) > 0 then
            table.sort(candidates, function(a, b) return a.score < b.score end)
            return candidates[1].guid
        end
    elseif not specifiedUnit then
        if conditionals.gettag then -- 新增当没有通过@或target=指定目标的时候，调用gettag会遍历TagUnits的目标 by 武藤纯子酱 2026.2.5
            local tagUnits = {}

            -- 修复：裸写 [gettag]（无值）时解析器把值存成动作名字符串，
            -- 与 Core.lua:3255 的归一化保持一致，否则下方 pairs(字符串) 崩溃 by 武藤纯子酱 2026.9.9
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
                        -- pairs(validTags[1]) = pairs(nil) 抛错 by 武藤纯子酱 2026.9.9
                        if table.getn(validTags) > 0 then
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
                            table.insert(tagUnits, unit)
                        end
                    end
                end
            end

            if table.getn(tagUnits) > 0 then
                -- 遍历所有跟踪的单位
                for _, guid in pairs(tagUnits) do
                    -- 跳过已处理的目标
                    if guid ~= "TAGMATCH" and guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                        evaluateCandidate(guid)
                    end
                end
            end
            
            -- 如果有合适的候选者，选择分数最好的
            if table.getn(candidates) > 0 then
                table.sort(candidates, function(a, b) return a.score < b.score end)
                return candidates[1].guid
            end
        end
    end

    -- 默认使用CleveRoids.knownEnemyGuids进行遍历 by 武藤纯子酱 2026.4.30
    if CleveRoids.knownEnemyGuids and type(CleveRoids.knownEnemyGuids) then        
        -- 遍历CleveRoids.knownEnemyGuids的所有单位 - 与TimerFrame中的逻辑保持一致
        for guid, lastSeen in pairs(CleveRoids.knownEnemyGuids) do
            -- 跳过已处理的目标
            if guid ~= currentTargetGuid and guid ~= specifiedUnitGuid then
                -- 剪枝：对象不存在/已死亡的 GUID 直接移除，避免长期积累拖慢遍历 by 武藤纯子酱 2026.8.31
                if not UnitExists(guid) or CleveRoids.IsUnitDeadOrGhost(guid) then
                    CleveRoids.knownEnemyGuids[guid] = nil
                else
                    evaluateCandidate(guid)
                end
            end
        end
        
        -- 如果有合适的候选者，选择分数最好的
        if table.getn(candidates) > 0 then
            table.sort(candidates, function(a, b) return a.score < b.score end)
            return candidates[1].guid
        end
    end

    -- Scan via UnitXP enemy iteration
    local firstGuid = nil
    local maxIterations = 50

    for i = 1, maxIterations do
        local found = CleveRoids.SafeUnitXP("target", "nextEnemyConsideringDistance")
        if not found then break end

        if not UnitExists("target") then break end
        local currentGuid = CleveRoids.GetGUID("target")
        if not currentGuid then break end

        if firstGuid == nil then
            firstGuid = currentGuid
        elseif currentGuid == firstGuid then
            break  -- Completed full cycle
        end

        evaluateCandidate("target")
    end

    -- Restore original target
    if currentTargetGuid then
        TargetUnit(currentTargetGuid)
    else
        ClearTarget()
    end

    -- Find best candidate (lowest score wins)
    if table.getn(candidates) == 0 then
        return nil
    end

    table.sort(candidates, function(a, b) return a.score < b.score end)
    return candidates[1].guid
end