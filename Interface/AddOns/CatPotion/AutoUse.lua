-- Optional per-character recovery items. No profile/window owns the scheduler.
local addon = CatPotionAddon
local definitions = {
    majorHealing = { id = 13446, health = 35, mana = 0 },
    majorMana = { id = 13444, health = 0, mana = 25 },
    nordanaarTea = { id = 61675, health = 35, mana = 25 },
}
local keys = { "majorHealing", "majorMana", "nordanaarTea" }
local configs, configDatabase, enabled = nil, nil, {}
local states, pending, internalRequest = {}, nil, false
local nextAttempt, nextCheck, dirty = 0, 0, false
local castingUntil, channelUntil = 0, 0
local driver = CreateFrame("Frame")
addon.AutoUseDriver = driver

local function Resolve(value)
    local key = type(value) == "table" and value.key or value
    local definition = definitions[key]
    if not definition then return end
    if type(value) == "table" and value.itemID ~= definition.id then return end
    return key
end

local function ConfigRoot()
    if configDatabase ~= CatPotionDB or not configs then
        local database = addon.GetDatabase()
        if type(database.autoUseItems) ~= "table" then database.autoUseItems = {} end
        configDatabase, configs = database, database.autoUseItems
    end
    return configs
end

local function Threshold(value, fallback)
    local number = tonumber(value)
    -- Lua 5.0 has no math.huge; NaN and either infinity fail this finite test.
    if not number or number-number ~= 0 then number = fallback end
    return math.max(0, math.min(100, math.floor(number + .5)))
end

function addon.IsAutoUseItem(value)
    return Resolve(value) ~= nil
end

function addon.GetAutoUseConfig(value)
    local key = Resolve(value)
    if not key then return end
    local root, definition = ConfigRoot(), definitions[key]
    if type(root[key]) ~= "table" then root[key] = {} end
    local config = root[key]
    config.enabled = addon.ToBoolean(config.enabled) and 1 or 0
    config.combatOnly = config.combatOnly == nil and 1 or (addon.ToBoolean(config.combatOnly) and 1 or 0)
    config.healthThreshold = definition.health > 0 and Threshold(config.healthThreshold, definition.health) or 0
    config.manaThreshold = definition.mana > 0 and Threshold(config.manaThreshold, definition.mana) or 0
    return config
end

local function State(key)
    if not states[key] then states[key] = { health = true, mana = true, status = "ready" } end
    return states[key]
end

local function Wake(delay)
    dirty = true
    local deadline = GetTime() + (delay or .2)
    if nextCheck == 0 or deadline < nextCheck then nextCheck = deadline end
    if table.getn(enabled) > 0 or pending then driver:Show() end
end

local function Rebuild()
    enabled = {}
    for _, key in ipairs(keys) do
        if addon.GetAutoUseConfig(key).enabled == 1 then table.insert(enabled, key) end
    end
    if table.getn(enabled) == 0 and not pending then
        dirty, nextCheck = false, 0
        driver:Hide()
    else
        Wake(.2)
    end
end

function addon.SetAutoUseConfig(value, values)
    local key = Resolve(value)
    if not key or type(values) ~= "table" then return false end
    local config = addon.GetAutoUseConfig(key)
    for _, field in ipairs({ "enabled", "combatOnly", "healthThreshold", "manaThreshold" }) do
        if values[field] ~= nil then config[field] = values[field] end
    end
    addon.GetAutoUseConfig(key)
    states[key] = nil
    -- A settings change must not cancel an already-issued request's mutex.
    Rebuild()
    return true
end

function addon.GetAutoUseStatus(value)
    local key = Resolve(value)
    if not key then return end
    local now = GetTime()
    if pending and pending.key == key then return "pending", math.max(0, pending.deadline-now) end
    local config = addon.GetAutoUseConfig(key)
    if config.enabled ~= 1 then return "disabled", 0 end
    local state = State(key)
    return state.status, math.max(0, math.max(state.cooldownEnd or 0, nextAttempt)-now)
end

function addon.NotifyAutoUseManual(item, beforeCount)
    if internalRequest or table.getn(enabled) == 0 then return end
    local now = GetTime()
    nextAttempt = math.max(nextAttempt, now + 2)
    local key = Resolve(item)
    if key then
        local count = tonumber(beforeCount)
        if not count then local _, _, current = addon.FindBagItem(item.item); count = current end
        pending = { key = key, item = item, count = count or 0, deadline = now+2 }
        local state = State(key)
        state.health, state.mana, state.status = false, false, "pending"
    end
    Wake(.2)
end

local function ObservePending(now)
    if not pending then return end
    local request = pending
    local remaining, kind = addon.GetCooldownInfo(request.item.item)
    local _, _, count = addon.FindBagItem(request.item.item)
    remaining = tonumber(remaining) or 0
    local state = State(request.key)
    if (count or 0) < request.count or (remaining > 0 and kind ~= "gcd") then
        -- Confirmation comes from existing bag/native cooldown data, never UseItem(true).
        state.status = remaining > 0 and "cooldown" or "await_resource"
        state.cooldownEnd = remaining > 0 and now+remaining or nil
        pending = nil
    elseif now >= request.deadline then
        state.health, state.mana, state.status = true, true, "unconfirmed"
        nextAttempt = math.max(nextAttempt, now+2)
        pending = nil
    end
end

local function Unsafe(now)
    if (type(UnitIsDeadOrGhost) == "function" and addon.ToBoolean(UnitIsDeadOrGhost("player")))
        or (type(UnitIsDead) == "function" and addon.ToBoolean(UnitIsDead("player")))
        or (type(UnitIsGhost) == "function" and addon.ToBoolean(UnitIsGhost("player"))) then
        castingUntil, channelUntil = 0, 0
        return true
    end
    if addon.AutoUseSettings and addon.AutoUseSettings:IsVisible() then return true end
    if now < castingUntil or now < channelUntil then return true end
    if type(UnitCastingInfo) == "function" and UnitCastingInfo("player") then return true end
    if type(UnitChannelInfo) == "function" and UnitChannelInfo("player") then return true end
    if type(SpellIsTargeting) == "function" and SpellIsTargeting() then return true end
    return false
end

local function TryItem(key, resource, percent, inCombat, now)
    local config = configs[key]
    if not config or config.enabled ~= 1 or (config.combatOnly == 1 and not inCombat) then return false end
    local threshold = config[resource == "health" and "healthThreshold" or "manaThreshold"]
    local state = State(key)
    if not percent or threshold <= 0 or percent >= threshold or not state[resource] then return false end
    if state.cooldownEnd and state.cooldownEnd > now then return false end
    local item = addon.ItemsByID[definitions[key].id]
    if not item then return false end
    local remaining, kind, unavailable = addon.GetCooldownInfo(item.item)
    if unavailable then state.status = "unavailable"; return false end
    if remaining > 0 then
        state.cooldownEnd = now+remaining
        state.status = "cooldown"
        return false
    end
    local bag, slot, count = addon.FindBagItem(item.item)
    if bag == nil or not count or count <= 0 then state.status = "missing"; return false end
    if type(GetContainerItemInfo) == "function" then
        local _, _, locked = GetContainerItemInfo(bag, slot)
        if locked == true or locked == 1 then state.status = "locked"; return false end
    end

    internalRequest = true
    local ok, requested = pcall(addon.UseItem, item.item, item)
    internalRequest = false
    nextAttempt = now+2
    if ok and requested then
        pending = { key = key, item = item, count = count, deadline = now+2 }
        state.health, state.mana, state.status = false, false, "pending"
    else
        state.status = "blocked"
    end
    return true -- One attempted request per evaluation, including a rejected one.
end

local function Evaluate(now)
    ObservePending(now)
    if pending or now < nextAttempt or table.getn(enabled) == 0 then return end
    if Unsafe(now) then return true end
    local maximum = UnitHealthMax("player")
    local health = maximum and maximum > 0 and UnitHealth("player") * 100 / maximum or nil
    if not health or health <= 0 then return end
    local mana
    if type(UnitPowerType) == "function" and UnitPowerType("player") == 0 then
        local manaMaximum = UnitManaMax("player")
        if manaMaximum and manaMaximum > 0 then mana = UnitMana("player") * 100 / manaMaximum end
    end
    local inCombat = type(UnitAffectingCombat) == "function" and addon.ToBoolean(UnitAffectingCombat("player"))
    for _, key in ipairs(enabled) do
        local config, state = configs[key], State(key)
        if health >= math.min(100, config.healthThreshold+5) then state.health = true end
        if mana and mana >= math.min(100, config.manaThreshold+5) then state.mana = true end
        if state.cooldownEnd and now >= state.cooldownEnd then
            local item = addon.ItemsByID[definitions[key].id]
            local remaining = item and addon.GetCooldownInfo(item.item) or 0
            if remaining <= 0 then
                state.health, state.mana, state.cooldownEnd = true, true, nil
            else
                state.cooldownEnd = now+remaining
            end
        end
    end
    if TryItem("majorHealing", "health", health, inCombat, now) then return end
    if TryItem("nordanaarTea", "health", health, inCombat, now) then return end
    if TryItem("majorMana", "mana", mana, inCombat, now) then return end
    TryItem("nordanaarTea", "mana", mana, inCombat, now)
end

driver:SetScript("OnUpdate", function()
    local now = GetTime()
    if not dirty and nextCheck == 0 then driver:Hide(); return end
    if now < nextCheck then return end
    if table.getn(enabled) == 0 and not pending then driver:Hide(); return end
    -- Unit events coalesce into one evaluation. Poll only a pending request or
    -- a temporary safety guard; a known cooldown sleeps until its real end.
    dirty, nextCheck = false, 0
    local guarded = Evaluate(now)
    if table.getn(enabled) == 0 and not pending then driver:Hide(); return end
    local deadline = pending and now+.2 or nil
    if nextAttempt > now and (not deadline or nextAttempt < deadline) then deadline = nextAttempt end
    if guarded and (not deadline or now+.5 < deadline) then deadline = now+.5 end
    for _, key in ipairs(enabled) do
        local expiry = State(key).cooldownEnd
        if expiry and expiry > now and (not deadline or expiry < deadline) then deadline = expiry end
    end
    if deadline then nextCheck = deadline else driver:Hide() end
end)

for _, name in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_ALIVE", "PLAYER_UNGHOST", "PLAYER_DEAD",
    "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_MANA", "UNIT_MAXMANA", "UNIT_DISPLAYPOWER",
    "BAG_UPDATE", "BAG_UPDATE_COOLDOWN", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "SPELLCAST_START", "SPELLCAST_STOP", "SPELLCAST_FAILED", "SPELLCAST_INTERRUPTED", "SPELLCAST_DELAYED",
    "SPELLCAST_CHANNEL_START", "SPELLCAST_CHANNEL_UPDATE", "SPELLCAST_CHANNEL_STOP" }) do
    driver:RegisterEvent(name)
end
driver:SetScript("OnEvent", function()
    local now = GetTime()
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        castingUntil, channelUntil = 0, 0
        Rebuild()
    elseif string.sub(event, 1, 5) == "UNIT_" then
        if arg1 == "player" then Wake(.2) end
    elseif event == "SPELLCAST_START" then
        castingUntil = now + (tonumber(arg2) or 10000)/1000 + .1
        Wake(.2)
    elseif event == "SPELLCAST_DELAYED" then
        castingUntil = math.max(now, castingUntil) + (tonumber(arg1) or 0)/1000
        Wake(.2)
    elseif event == "SPELLCAST_STOP" or event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        castingUntil = 0 -- Failed other spells must not end an active channel.
        Wake(.2)
    elseif event == "SPELLCAST_CHANNEL_START" or event == "SPELLCAST_CHANNEL_UPDATE" then
        channelUntil = now + math.max(0, tonumber(arg1) or 0)/1000
        Wake(.2)
    elseif event == "SPELLCAST_CHANNEL_STOP" then
        channelUntil = 0
        Wake(.2)
    else
        Wake(.2)
    end
end)
Rebuild()
