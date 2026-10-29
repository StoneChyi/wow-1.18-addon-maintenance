-- Optional per-character recovery items. No profile/window owns the scheduler.
local addon = CatPotionAddon
local definitions = {
    majorHealing = { id = 13446, health = 35, mana = 0 },
    majorMana = { id = 13444, health = 0, mana = 25 },
    nordanaarTea = { id = 61675, health = 35, mana = 25 },
    majorHealthstone = { id = 9421, alternateIDs = { 19012, 19013 }, health = 35, mana = 0 },
    majorRejuvenation = { id = 18253, health = 35, mana = 25 },
    superiorHealing = { id = 3928, health = 35, mana = 0 },
    superiorMana = { id = 13443, health = 0, mana = 25 },
    greaterMana = { id = 6149, health = 0, mana = 25 },
    greaterDreamlessSleep = { id = 20002, health = 35, mana = 25, needsRest = true },
    dreamlessSleep = { id = 12190, health = 35, mana = 25, needsRest = true },
    thistleTea = { id = 7676, health = 0, mana = 0, energy = 25, classFile = "ROGUE" },
    demonicRune = { id = 12662, health = 0, mana = 25, costsHealth = true, minHealthValue = 1101 },
    darkRune = { id = 20520, health = 0, mana = 25, costsHealth = true, minHealthValue = 1101 },
    conjuredManaOrange = { id = 83004, health = 35, mana = 25, outOfCombatOnly = true, needsRest = true },
}
local keys = { "majorHealing", "majorMana", "nordanaarTea", "majorHealthstone", "majorRejuvenation",
    "superiorHealing", "superiorMana", "greaterMana", "greaterDreamlessSleep", "dreamlessSleep",
    "thistleTea", "demonicRune", "darkRune", "conjuredManaOrange" }
local priorities = {
    health = { "majorHealthstone", "majorHealing", "nordanaarTea", "majorRejuvenation", "superiorHealing",
        "greaterDreamlessSleep", "dreamlessSleep", "conjuredManaOrange" },
    mana = { "majorMana", "nordanaarTea", "majorRejuvenation", "superiorMana", "greaterMana",
        "demonicRune", "darkRune", "greaterDreamlessSleep", "dreamlessSleep", "conjuredManaOrange" },
    energy = { "thistleTea" },
}
local defaultPriorities = { majorHealthstone = 10, majorHealing = 20, majorMana = 20, nordanaarTea = 30,
    majorRejuvenation = 40, superiorHealing = 50, superiorMana = 50, greaterMana = 60,
    demonicRune = 70, darkRune = 80, greaterDreamlessSleep = 85, dreamlessSleep = 90,
    conjuredManaOrange = 100, thistleTea = 10 }
local priorityRanks = {}
for resource, ordered in pairs(priorities) do
    priorityRanks[resource] = {}
    for index, key in ipairs(ordered) do priorityRanks[resource][key] = index end
end
local metadata = {}
for key, definition in pairs(definitions) do
    metadata[key] = { key = key, id = definition.id, health = definition.health > 0, mana = definition.mana > 0,
        energy = (definition.energy or 0) > 0, costsHealth = definition.costsHealth == true,
        outOfCombatOnly = definition.outOfCombatOnly == true, needsRest = definition.needsRest == true,
        minHealthValue = definition.minHealthValue or 0, classFile = definition.classFile }
end
local configs, configDatabase, enabled = nil, nil, {}
local activePriorities = { health = {}, mana = {}, energy = {} }
local policy, episodes, requestNumber = nil, {}, 0
local generations, lateRequests, lateDirty = { health = 0, mana = 0, energy = 0 }, {}, false
local Moving, ReadResources, BeginRequest, ConfirmRequest, ReleaseRequest, ObserveEpisodes, RememberLate, ObserveLateRequests
local states, pending, internalRequest = {}, nil, false
local nextAttempt, nextCheck, dirty = 0, 0, false
local castingUntil, channelUntil = 0, 0
local restAuraDirty, restAuraBlocked, restAuraUntil, restGuarded = true, false, nil, false
local driver = CreateFrame("Frame")
addon.AutoUseDriver = driver

local function Resolve(value)
    local key = type(value) == "table" and value.key or value
    local definition = definitions[key]
    if not definition then return end
    if type(value) == "table" and value.itemID ~= definition.id then
        local alternate
        for _, id in ipairs(definition.alternateIDs or {}) do if value.itemID == id then alternate = true end end
        if not alternate then return end
    end
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

function addon.GetAutoUseDefinition(value)
    local key = Resolve(value)
    return key and metadata[key] or nil
end

function addon.GetAutoUseConfig(value)
    local key = Resolve(value)
    if not key then return end
    local root, definition = ConfigRoot(), definitions[key]
    if type(root[key]) ~= "table" then root[key] = {} end
    local config = root[key]
    config.enabled = addon.ToBoolean(config.enabled) and 1 or 0
    config.combatOnly = config.combatOnly == nil and 1 or (addon.ToBoolean(config.combatOnly) and 1 or 0)
    if definition.outOfCombatOnly then config.combatOnly = 0 end
    config.healthThreshold = definition.health > 0 and Threshold(config.healthThreshold, definition.health) or 0
    config.manaThreshold = definition.mana > 0 and Threshold(config.manaThreshold, definition.mana) or 0
    config.energyThreshold = (definition.energy or 0) > 0 and Threshold(config.energyThreshold, definition.energy) or 0
    config.minHealthPercent = definition.costsHealth and Threshold(config.minHealthPercent, 60) or 0
    config.priority = math.max(1, Threshold(config.priority, defaultPriorities[key]))
    return config
end

function addon.GetAutoUsePolicy()
    ConfigRoot()
    if type(configDatabase.autoUsePolicy) ~= "table" then configDatabase.autoUsePolicy = {} end
    policy = configDatabase.autoUsePolicy
    policy.singlePerEpisode = policy.singlePerEpisode == nil and 1 or (addon.ToBoolean(policy.singlePerEpisode) and 1 or 0)
    return policy
end

local function State(key)
    if not states[key] then states[key] = { health = true, mana = true, energy = true, status = "ready" } end
    return states[key]
end

local function Wake(delay)
    dirty = true
    local deadline = GetTime() + (delay or .2)
    if nextCheck == 0 or deadline < nextCheck then nextCheck = deadline end
    if table.getn(enabled) > 0 or pending or (lateDirty and next(lateRequests)) then driver:Show() end
end

local function Rebuild()
    addon.GetAutoUsePolicy()
    enabled = {}
    for _, key in ipairs(keys) do
        if addon.GetAutoUseConfig(key).enabled == 1 then table.insert(enabled, key) end
    end
    activePriorities = { health = {}, mana = {}, energy = {} }
    for resource, ordered in pairs(priorities) do
        for _, key in ipairs(ordered) do
            if configs[key].enabled == 1 then table.insert(activePriorities[resource], key) end
        end
        local resourceName = resource
        table.sort(activePriorities[resource], function(a, b)
            if configs[a].priority ~= configs[b].priority then return configs[a].priority < configs[b].priority end
            return priorityRanks[resourceName][a] < priorityRanks[resourceName][b]
        end)
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
    for _, field in ipairs({ "enabled", "combatOnly", "healthThreshold", "manaThreshold", "energyThreshold", "minHealthPercent", "priority" }) do
        if values[field] ~= nil then config[field] = values[field] end
    end
    addon.GetAutoUseConfig(key)
    states[key] = nil
    -- A settings change must not cancel an already-issued request's mutex.
    Rebuild()
    return true
end

function addon.SetAutoUsePolicy(values)
    if type(values) ~= "table" then return false end
    local config = addon.GetAutoUsePolicy()
    if values.singlePerEpisode ~= nil then
        local value = addon.ToBoolean(values.singlePerEpisode) and 1 or 0
        if config.singlePerEpisode == value then return true end
        config.singlePerEpisode = value
        Wake(.2)
    end
    return true
end

function addon.GetAutoUseStatus(value)
    local key = Resolve(value)
    if not key then return end
    local now = GetTime()
    if pending and pending.key == key then return "pending", math.max(0, pending.deadline-now) end
    local config = addon.GetAutoUseConfig(key)
    if config.enabled ~= 1 then return "disabled", 0 end
    if policy and policy.singlePerEpisode == 1 then
        for _, resource in ipairs({ "health", "mana", "energy" }) do
            if episodes[resource] and (definitions[key][resource] or 0) > 0 and config[resource .. "Threshold"] > 0 then
                return "episode_locked", 0
            end
        end
    end
    local state = State(key)
    local status = state.status == "episode_locked" and "ready" or state.status
    return status, math.max(0, math.max(state.cooldownEnd or 0, nextAttempt)-now)
end

function addon.NotifyAutoUseManual(item, beforeCount, beforeResources)
    if internalRequest or table.getn(enabled) == 0 then return end
    local now = GetTime()
    nextAttempt = math.max(nextAttempt, now + 2)
    local key = Resolve(item)
    if key then
        local count = tonumber(beforeCount)
        if not count then local _, _, current = addon.FindBagItem(item.item); count = current end
        BeginRequest(item, count or 0, beforeResources or ReadResources(), now)
        local state = State(key)
        state.health, state.mana, state.energy, state.status = false, false, false, "pending"
    elseif pending then
        -- A different manual item can start a shared cooldown. That alone is
        -- not confirmation of the automatic item that is still outstanding.
        pending.foreignUse = true
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
    if (count or 0) < request.count or (remaining > 0 and kind == "item" and not request.foreignUse) then
        -- Confirmation comes from existing bag/native cooldown data, never UseItem(true).
        state.status = remaining > 0 and "cooldown" or "await_resource"
        state.cooldownEnd = remaining > 0 and now+remaining or nil
        ConfirmRequest(request, now)
        nextAttempt = math.max(nextAttempt, now+2)
        pending = nil
    elseif now >= request.deadline then
        state.health, state.mana, state.energy, state.status = true, true, true, "unconfirmed"
        nextAttempt = math.max(nextAttempt, now+2)
        RememberLate(request, now)
        ReleaseRequest(request)
        pending = nil
    end
end

local function Recovering(now)
    if restAuraUntil and now >= restAuraUntil then restAuraBlocked, restAuraUntil = false, nil end
    if restAuraDirty then
        restAuraDirty, restAuraBlocked, restAuraUntil = false, false, nil
        local untimed = false
        -- Dreamless Sleep can be a harmful aura outside Core's normal buff cache.
        -- Read actual HARMFUL handles once per aura event, not every evaluation.
        if type(GetPlayerBuff) == "function" and type(GetPlayerBuffTexture) == "function" then
            for index = 0, 63 do
                local handle = GetPlayerBuff(index, "HARMFUL")
                if not handle or handle < 0 then break end
                local texture = GetPlayerBuffTexture(handle)
                if type(texture) == "string" and string.lower(texture) == "interface\\icons\\spell_nature_sleep" then
                    restAuraBlocked = true
                    local remaining = type(GetPlayerBuffTimeLeft) == "function" and GetPlayerBuffTimeLeft(handle)
                    if remaining and remaining > 0 then
                        restAuraUntil = math.max(restAuraUntil or 0, now+remaining)
                    else
                        untimed = true
                    end
                end
            end
        end
        if untimed then restAuraUntil = nil end
    end
    if restAuraBlocked then return true end
    if type(addon.PlayerIsEating) == "function" and addon.PlayerIsEating() then return true end
    if type(addon.GetBuffTime) == "function" then
        for _, name in ipairs({ "喝水", "饮水", "Food", "Drink", "无梦睡眠", "昏睡", "强效昏睡",
            "Dreamless Sleep", "Greater Dreamless Sleep" }) do
            if addon.GetBuffTime(name) > 0 then return true end
        end
    end
    return false
end

Moving = function()
    local known = false
    -- These optional providers are already used by the local Cat2 movement path.
    if type(PlayerIsMoving) == "function" then
        local ok, value = pcall(PlayerIsMoving)
        if ok and (value == true or value == 1) then return true end
        if ok and (value == false or value == 0) then known = true end
    end
    if type(UnitXP) == "function" then
        local ok, speed = pcall(UnitXP, "speed", "player")
        if ok and type(speed) == "number" and speed >= 0 and speed-speed == 0 then
            if speed > .01 then return true end
            known = true
        end
    end
    -- Not assumed to exist on a 1.12 client.
    if type(GetUnitSpeed) == "function" then
        local ok, speed = pcall(GetUnitSpeed, "player")
        if ok and type(speed) == "number" and speed >= 0 and speed-speed == 0 then
            if speed > .01 then return true end
            known = true
        end
    end
    if known then return false end
    return nil -- Map position (0,0) cannot prove that the player is stationary.
end

ReadResources = function()
    local maximum, current = UnitHealthMax("player"), UnitHealth("player")
    local sample = { currentHealth = current, health = maximum and maximum > 0 and current*100/maximum or nil,
        powerType = type(UnitPowerType) == "function" and UnitPowerType("player"), time = GetTime() }
    if sample.powerType == 0 or sample.powerType == 3 then
        local maxPower = UnitManaMax("player")
        if maxPower and maxPower > 0 then
            local value = UnitMana("player")*100/maxPower
            if sample.powerType == 0 then sample.mana = value else sample.energy = value end
        end
    end
    sample.inCombat = type(UnitAffectingCombat) == "function" and addon.ToBoolean(UnitAffectingCombat("player"))
    if type(UnitClass) == "function" then local _, class = UnitClass("player"); sample.classFile = class end
    return sample
end

function addon.CaptureAutoUseResources(item)
    if internalRequest or table.getn(enabled) == 0 or not Resolve(item) then return end
    return ReadResources()
end

local function Applicable(definition, config, sample)
    if definition.outOfCombatOnly and sample.inCombat then return false end
    if config.combatOnly == 1 and not sample.inCombat then return false end
    if definition.classFile and definition.classFile ~= sample.classFile then return false end
    if definition.costsHealth and (not sample.health or sample.health <= config.minHealthPercent
        or sample.currentHealth < definition.minHealthValue) then return false end
    if definition.needsRest then
        if not sample.motionChecked then sample.moving, sample.motionChecked = Moving(), true end
        if sample.moving ~= false then return false end
    end
    return true
end

local function ResourceBounds(resource, sample)
    local bounds, highest = {}, 0
    if sample[resource] == nil then return bounds, highest end
    for _, key in ipairs(activePriorities[resource]) do
        local config, definition = configs[key], definitions[key]
        local threshold = config[resource .. "Threshold"]
        if threshold > 0 and Applicable(definition, config, sample) then
            bounds[key] = { threshold = threshold, combatOnly = config.combatOnly, minHealthPercent = config.minHealthPercent }
            highest = math.max(highest, threshold)
        end
    end
    return bounds, highest
end

local function RecoveryLine(episode, resource, sample)
    local _, highest = ResourceBounds(resource, sample)
    -- A live round keeps the thresholds that were applicable when requested.
    -- Walking away or leaving combat cannot manufacture a completed recovery.
    -- New requests still exclude inapplicable food/class/resource settings.
    for _, bound in pairs(episode.bounds) do highest = math.max(highest, bound.threshold) end
    local active = episodes[resource]
    if active and active.generation == episode.generation then
        for _, bound in pairs(active.bounds) do highest = math.max(highest, bound.threshold) end
    end
    return math.min(100, highest+5)
end

local function Recovered(resource)
    generations[resource] = generations[resource]+1
    episodes[resource] = nil
    for _, state in pairs(states) do state[resource] = true end
end

ObserveEpisodes = function(sample, now)
    for resource, episode in pairs(episodes) do
        local value = sample[resource]
        if value then episode.peak = math.max(episode.peak, value) end
        if episode.confirmed then
            if value ~= nil and episode.peak > episode.before + .000001 and episode.peak >= RecoveryLine(episode, resource, sample) then
                Recovered(resource)
                -- Recovery may have been a brief peak between two resource
                -- events; do not lose the item's own five-point rearm either.
            end
        elseif (not pending or pending.token ~= episode.owner) and now >= episode.deadline then
            episodes[resource] = nil
        end
    end
    -- Timed-out requests retain only a bounded, event-checked count receipt.
    -- A real recovery advances generation even while all auto items are off,
    -- so a late receipt cannot lock a later low-resource round.
    for key, request in pairs(lateRequests) do
        if now > request.expires then
            lateRequests[key] = nil
        else
            for resource, round in pairs(request.rounds or {}) do
                if round.generation == generations[resource] then
                    local value = sample[resource]
                    if value then round.peak = math.max(round.peak, value) end
                    if value ~= nil and round.peak > round.before+.000001 and round.peak >= RecoveryLine(round, resource, sample) then
                        Recovered(resource)
                    end
                end
            end
        end
    end
end

BeginRequest = function(item, count, sample, now)
    if type(sample) ~= "table" then sample = ReadResources() end
    ObserveEpisodes(sample, now)
    if pending then RememberLate(pending, now) end
    requestNumber = requestNumber+1
    pending = { key = item.key, item = item, count = count, deadline = now+2, token = requestNumber, resources = {}, rounds = {} }
    local definition = definitions[item.key]
    for _, resource in ipairs({ "health", "mana", "energy" }) do
        local value = sample[resource]
        if (definition[resource] or 0) > 0 and value then
            local bounds, highest = ResourceBounds(resource, sample)
            -- A dual restore item must not lock an already-healthy/full pool.
            if highest > 0 and value < highest then
                local episode = episodes[resource]
                if not episode then
                    episode = { before = value, peak = value, bounds = bounds, generation = generations[resource] }
                    episodes[resource] = episode
                else
                    for key, bound in pairs(bounds) do
                        if not episode.bounds[key] or episode.bounds[key].threshold < bound.threshold then episode.bounds[key] = bound end
                    end
                end
                if not episode.confirmed then episode.owner, episode.deadline = pending.token, pending.deadline end
                pending.resources[resource] = episode.generation
                pending.rounds[resource] = episode
            end
        end
    end
end

ConfirmRequest = function(request, now)
    for resource, generation in pairs(request.resources or {}) do
        local episode = episodes[resource]
        if episode and episode.owner == request.token and generation == generations[resource] then episode.confirmed = true end
    end
end

RememberLate = function(request, now)
    request.expires = now+30
    lateRequests[request.key] = request -- At most one record per supported item.
end

ObserveLateRequests = function(now)
    if not lateDirty then return end
    lateDirty = false
    for key, request in pairs(lateRequests) do
        if now > request.expires then
            lateRequests[key] = nil
        else
            local _, _, count = addon.FindBagItem(request.item.item)
            if (count or 0) < request.count then
                for resource, round in pairs(request.rounds or {}) do
                    if round.generation == generations[resource] then
                        local episode = episodes[resource] or round
                        episode.confirmed = true
                        episodes[resource] = episode
                    end
                end
                local remaining = addon.GetCooldownInfo(request.item.item)
                local state = State(key)
                state.health, state.mana, state.energy = false, false, false
                state.cooldownEnd = remaining > 0 and now+remaining or nil
                state.status = remaining > 0 and "cooldown" or "await_resource"
                nextAttempt = math.max(nextAttempt, now+2)
                lateRequests[key] = nil
            end
        end
    end
end

ReleaseRequest = function(request)
    for resource in pairs(request.resources or {}) do
        local episode = episodes[resource]
        if episode and not episode.confirmed and episode.owner == request.token then episodes[resource] = nil end
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
    if Recovering(now) then return true end
    return false
end

local function TryItem(key, resource, percent, health, currentHealth, inCombat, now, sample)
    local config = configs[key]
    if not config or config.enabled ~= 1 or (config.combatOnly == 1 and not inCombat) then return false end
    local definition = definitions[key]
    if definition.outOfCombatOnly and inCombat then return false end
    local threshold = config[resource .. "Threshold"]
    local state = State(key)
    if not percent or threshold <= 0 or percent >= threshold or not state[resource] then return false end
    if policy.singlePerEpisode == 1 and episodes[resource] then state.status = "episode_locked"; return false end
    if definition.classFile then
        local classFile
        if type(UnitClass) == "function" then local _, class = UnitClass("player"); classFile = class end
        if classFile ~= definition.classFile then state.status = "unavailable"; return false end
    end
    if definition.costsHealth and (health <= config.minHealthPercent or currentHealth < definition.minHealthValue) then
        state.status = "health_guard"
        return false
    end
    if definition.needsRest then
        local moving = Moving()
        if moving ~= false then
            state.status = moving and "moving" or "stationary_unknown"
            restGuarded = true
            return false
        end
    end
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
        BeginRequest(item, count, sample, now)
        state.health, state.mana, state.energy, state.status = false, false, false, "pending"
    else
        state.status = "blocked"
    end
    return true -- One attempted request per evaluation, including a rejected one.
end

local function Evaluate(now)
    ObserveLateRequests(now)
    ObservePending(now)
    local sample = ReadResources()
    ObserveEpisodes(sample, now)
    if pending or now < nextAttempt or table.getn(enabled) == 0 then return end
    if Unsafe(now) then return true end
    restGuarded = false
    local currentHealth, health = sample.currentHealth, sample.health
    if not health or health <= 0 then return end
    local mana, energy, inCombat = sample.mana, sample.energy, sample.inCombat
    for _, key in ipairs(enabled) do
        local config, state = configs[key], State(key)
        if health >= math.min(100, config.healthThreshold+5) then state.health = true end
        if mana and mana >= math.min(100, config.manaThreshold+5) then state.mana = true end
        if energy and energy >= math.min(100, config.energyThreshold+5) then state.energy = true end
        if state.cooldownEnd and now >= state.cooldownEnd then
            local item = addon.ItemsByID[definitions[key].id]
            local remaining = item and addon.GetCooldownInfo(item.item) or 0
            if remaining <= 0 then
                state.health, state.mana, state.energy, state.cooldownEnd = true, true, true, nil
            else
                state.cooldownEnd = now+remaining
            end
        end
    end
    for _, resource in ipairs({ "health", "mana", "energy" }) do
        local percent
        if resource == "health" then percent = health elseif resource == "mana" then percent = mana else percent = energy end
        for _, key in ipairs(activePriorities[resource]) do
            if TryItem(key, resource, percent, health, currentHealth, inCombat, now, sample) then return end
        end
    end
    return restGuarded
end

driver:SetScript("OnUpdate", function()
    local now = GetTime()
    if not dirty and nextCheck == 0 then driver:Hide(); return end
    if now < nextCheck then return end
    if table.getn(enabled) == 0 and not pending and not (lateDirty and next(lateRequests)) then driver:Hide(); return end
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
    "UNIT_HEALTH", "UNIT_MAXHEALTH", "UNIT_MANA", "UNIT_MAXMANA", "UNIT_ENERGY", "UNIT_MAXENERGY", "UNIT_DISPLAYPOWER",
    "PLAYER_AURAS_CHANGED",
    "BAG_UPDATE", "BAG_UPDATE_COOLDOWN", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "SPELLCAST_START", "SPELLCAST_STOP", "SPELLCAST_FAILED", "SPELLCAST_INTERRUPTED", "SPELLCAST_DELAYED",
    "SPELLCAST_CHANNEL_START", "SPELLCAST_CHANNEL_UPDATE", "SPELLCAST_CHANNEL_STOP" }) do
    driver:RegisterEvent(name)
end
driver:SetScript("OnEvent", function()
    local now = GetTime()
    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        castingUntil, channelUntil = 0, 0
        restAuraDirty = true
        Rebuild()
    elseif event == "PLAYER_AURAS_CHANGED" then
        restAuraDirty = true
        Wake(.2)
    elseif string.sub(event, 1, 5) == "UNIT_" then
        if arg1 == "player" then
            -- Preserve a real recovery peak even if damage follows before the
            -- coalesced tick, while the popup is open, or while auto is disabled.
            -- With no live round this adds no resource or inventory reads.
            if next(episodes) or next(lateRequests) then ObserveEpisodes(ReadResources(), now) end
            Wake(.2)
        end
    elseif event == "BAG_UPDATE" or event == "BAG_UPDATE_COOLDOWN" then
        lateDirty = true
        Wake(.2)
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
