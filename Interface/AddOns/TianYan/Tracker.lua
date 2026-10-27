-- ========== TianYan: Summon tracker with history records ==========

local TY = {}
TY.summonCache = {}

local scanTip = nil
local function initScanTip()
	if not scanTip then
		scanTip = CreateFrame("GameTooltip", "TYScanTip", UIParent, "GameTooltipTemplate")
		scanTip:SetOwner(UIParent, "ANCHOR_NONE")
	end
end

local EXCLUDE_NAMES = {
	"疲倦的骡子",
	"修理机器人75B型",
	"拍卖师德雷兹比特",
	"车队科多兽",
	"机械拍卖师",
}

local function isExcluded(unitName)
	if not unitName then return false end
	for _, excl in ipairs(EXCLUDE_NAMES) do
		if string.find(unitName, excl) then return true end
	end
	return false
end

-- GUIDs identify real units; temporary entries are keyed by the frame object.
local SCAN_INTERVAL = 0.3
local UNKNOWN_GRACE = 0.9
local OWNER_CACHE_TIME = 2
local temporary = {}
local ownerCache = {}
local deadUntil = {}
local playerName, playerGuid
local diagnostics = { scans = 0, tooltips = 0, events = 0, discovered = 0, retry = 0, rejected = 0 }
local pending = {}
local eventCounts, registrations = {}, {}
local lastCount, lastGroups, lastUncertain = 0, {}, 0

local function safeCall(fn, unit)
    if type(fn) ~= "function" then return nil end
    local ok, result = pcall(fn, unit)
    if ok then return result end
    return nil
end

local function validGuid(guid)
    return type(guid) == "string" and string.len(guid) == 18 and string.find(guid, "^0x%x+$") and
        not string.find(guid, "^0x0+$")
end

local function getGuid(unit)
    local guid = safeCall(GetUnitGUID, unit) or safeCall(UnitGUID, unit)
    if not validGuid(guid) then guid = safeCall(UnitGUID, unit) end
    if validGuid(guid) then return guid end
    if unit and type(UnitExists) == "function" then
        local ok, exists, fallback = pcall(UnitExists, unit)
        if ok and exists and validGuid(fallback) then return fallback end
    end
    return nil
end

local function cleanText(text)
    if type(text) ~= "string" then return nil end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    text = string.gsub(text, "^%s+", "")
    return string.gsub(text, "%s+$", "")
end

local function ownerTextMatches(text)
    text = cleanText(text)
    if not text or not playerName or playerName == "" then return false end
    -- Whole owner lines only: a guild name or a longer character name is not ownership.
    if text == playerName then return true end
    local suffixes = {"的宠物", "的仆从", "的守护者", "的召唤物", "的图腾", "的随从",
        "'s Pet", "'s Minion", "'s Guardian", "'s Totem", "'s Summon"}
    for _, suffix in ipairs(suffixes) do
        if text == playerName .. suffix or text == "<" .. playerName .. suffix .. ">" then return true end
    end
    return false
end

local function eligible(unit)
    if not unit or not safeCall(UnitExists, unit) then return false end
    if safeCall(UnitIsDead, unit) or safeCall(UnitIsDeadOrGhost, unit) then return false end
    if UnitCanAttack and UnitCanAttack("player", unit) then return false end
    if UnitIsUnit and UnitIsUnit(unit, "player") then return false end
    if safeCall(UnitIsPlayer, unit) then return false end
    local name = safeCall(UnitName, unit)
    return name and name ~= "" and not isExcluded(name)
end

local function ownership(unit, guid, now, force)
    if not playerGuid then playerName, playerGuid = UnitName("player"), getGuid("player") end
    -- Nampower owner suffix is authoritative when it resolves (including another owner).
    local owner = getGuid(unit .. "owner")
    if not owner and type(GetUnitField) == "function" and type(GetNampowerVersion) == "function" then
        local major, minor = GetNampowerVersion()
        if type(major) == "number" and (major > 2 or (major == 2 and (minor or 0) >= 35)) then
            local ok, value = pcall(GetUnitField, unit, "summonedBy")
            if ok and validGuid(value) then owner = value end
            if not owner then
                ok, value = pcall(GetUnitField, unit, "createdBy")
                if ok and validGuid(value) then owner = value end
            end
        end
    end
    if owner and playerGuid then
        ownerCache[guid or unit] = {mine = owner == playerGuid, name = UnitName(unit), time = now}
        return owner == playerGuid
    end
    local key = guid or unit
    local name = UnitName(unit)
    local cached = ownerCache[key]
    if not force and cached and cached.name == name and now - cached.time < OWNER_CACHE_TIME then
        return cached.mine and true or nil
    end
    initScanTip()
    scanTip:ClearLines()
    scanTip:SetUnit(unit)
    diagnostics.tooltips = diagnostics.tooltips + 1
    local mine = false
    for i = 1, 30 do
        local left = getglobal("TYScanTipTextLeft" .. i)
        local right = getglobal("TYScanTipTextRight" .. i)
        if not left and not right then break end
        if (left and ownerTextMatches(left:GetText())) or
            (right and ownerTextMatches(right:GetText())) then mine = true; break end
    end
    ownerCache[key] = {mine = mine, name = name, time = now}
    return mine and true or nil
end

local function observeUnit(unit, now, force)
    local guid = getGuid(unit)
    if guid and deadUntil[guid] and now < deadUntil[guid] then return nil end
    if not eligible(unit) then
        if guid then TY.summonCache[guid] = nil; ownerCache[guid] = nil end
        return nil
    end
    local mine = ownership(unit, guid, now, force)
    if mine ~= true then
        if mine == false and guid then TY.summonCache[guid] = nil; pending[guid] = nil end
        return nil, nil, mine == nil and "unknown" or "other"
    end
    local name = UnitName(unit)
    if guid then
        if not TY.summonCache[guid] then diagnostics.discovered = diagnostics.discovered + 1 end
        TY.summonCache[guid] = {name = name, time = now, state = "alive", source = unit}
        pending[guid] = nil
    end
    return guid, name
end

local function frameGuid(frame)
    -- Never associate a WorldFrame child index with nameplateN: those indices are unrelated.
    if frame.GetName then
        local ok, guid = pcall(frame.GetName, frame, 1)
        if ok and validGuid(guid) and string.find(guid, "^0x%x+$") then return guid end
    end
    if type(frame.unit) == "string" then return getGuid(frame.unit) end
    return nil
end

local function plateText(frame)
    if not frame.GetRegions then return nil end
    local regions = {frame:GetRegions()}
    local isPlate = frame._pfNamePlate or frame.nameplate
    local owned, name = false, nil
    for _, region in ipairs(regions) do
        local kind = region.GetObjectType and region:GetObjectType()
        if kind == "Texture" and region.GetTexture and
            region:GetTexture() == "Interface\\Tooltips\\Nameplate-Border" then isPlate = true end
        if kind == "FontString" and region.GetText then
            local text = cleanText(region:GetText())
            if ownerTextMatches(text) then owned = true
            elseif text and text ~= "" and not tonumber(text) and
                not string.find(text, "^[<>]") and text ~= "??" and not name then name = text end
        end
    end
    -- pfUI retains the original text regions even after hiding/replacing them.
    local original = frame.nameplate and frame.nameplate.original
    if original and original.name then name = cleanText(original.name:GetText()) or name end
    if isPlate then
        local health = original and original.healthbar
        if not health and frame.GetChildren then
            local children = {frame:GetChildren()}
            health = children[1]
        end
        if health and health.GetValue and health.GetMinMaxValues then
            local ok, minimum, maximum = pcall(health.GetMinMaxValues, health)
            local value = safeCall(function() return health:GetValue() end)
            -- Zero with an initialized health range is death, unlike a hidden plate.
            if ok and type(maximum) == "number" and maximum > 0 and
                type(value) == "number" and value <= 0 then owned = false end
        end
    end
    return isPlate and owned, name
end

local function mergePromotedFrames(guid)
    for frame, info in pairs(temporary) do
        if info.guid == guid or frameGuid(frame) == guid then temporary[frame] = nil end
    end
end

local function countTracked(now)
    local count, groups, uncertain = 0, {}, 0
    local function add(name, estimated)
        count = count + 1
        groups[name] = (groups[name] or 0) + 1
        if estimated then uncertain = uncertain + 1 end
    end
    for guid, info in pairs(TY.summonCache) do
        if deadUntil[guid] and now < deadUntil[guid] then
            TY.summonCache[guid] = nil
        else
            local unit = guid
            if not safeCall(UnitExists, guid) and type(info.source) == "string" and
                getGuid(info.source) == guid and safeCall(UnitExists, info.source) then unit = info.source end
            local exists = safeCall(UnitExists, unit)
            local mine = exists and ownership(unit, guid, now, false)
            if exists and (not eligible(unit) or mine == false) then
                TY.summonCache[guid] = nil
            elseif exists and mine == true then
                info.name = UnitName(unit); info.state = "alive"; info.unknownSince = nil
                add(info.name, false)
            else
                info.unknownSince = info.unknownSince or now
                info.state = "unobserved"
                if now - info.unknownSince < UNKNOWN_GRACE then add(info.name, true)
                else TY.summonCache[guid] = nil; ownerCache[guid] = nil end
            end
        end
    end
    local temporaryGuids = {}
    for frame, info in pairs(temporary) do
        if not frame:IsShown() then info.state = "unobserved" end
        if info.guid and (TY.summonCache[info.guid] or (deadUntil[info.guid] and now < deadUntil[info.guid])) then
            temporary[frame] = nil
        elseif now - info.time < UNKNOWN_GRACE then
            if not info.guid or not temporaryGuids[info.guid] then add(info.name, true) end
            if info.guid then temporaryGuids[info.guid] = true end
        else temporary[frame] = nil end
    end
    for key, info in pairs(ownerCache) do
        if now - info.time > OWNER_CACHE_TIME and not TY.summonCache[key] then ownerCache[key] = nil end
    end
    for guid, deadline in pairs(deadUntil) do
        if now >= deadline then deadUntil[guid] = nil end
    end
    lastCount, lastGroups, lastUncertain = count, groups, uncertain
    return count, groups, uncertain
end

local function scanForSummons()
    local now = GetTime()
    playerName, playerGuid = UnitName("player"), getGuid("player")
    diagnostics.scans = diagnostics.scans + 1
    local seen = {}
    local units = {"pet", "target", "mouseover"}
    for i = 1, 40 do table.insert(units, "nameplate" .. i) end
    for _, unit in ipairs(units) do
        if safeCall(UnitExists, unit) then
            local guid = getGuid(unit)
            if not guid or not seen[guid] then
                observeUnit(unit, now, false)
                if guid then seen[guid] = true end
            end
        end
    end
    if WorldFrame and WorldFrame.GetChildren then
        local children = {WorldFrame:GetChildren()}
        for _, frame in ipairs(children) do
            if frame.IsShown and frame:IsShown() then
                local guid = frameGuid(frame)
                if guid then
                    local accepted, name, reason
                    if not seen[guid] then accepted, name, reason = observeUnit(guid, now, false); seen[guid] = true end
                    if TY.summonCache[guid] then
                        temporary[frame] = nil
                    elseif reason == "other" or (safeCall(UnitExists, guid) and not eligible(guid)) then
                        temporary[frame] = nil
                    else
                        local owned, plateName = plateText(frame)
                        if owned and plateName and not isExcluded(plateName) then
                            temporary[frame] = {name = plateName, time = now, state = "observed", guid = guid}
                        else temporary[frame] = nil end
                    end
                elseif type(frame.unit) == "string" and safeCall(UnitExists, frame.unit) then
                    local _, name = observeUnit(frame.unit, now, false)
                    if name then temporary[frame] = {name = name, time = now, state = "observed"}
                    else temporary[frame] = nil end
                else
                    local owned, name = plateText(frame)
                    if owned and name and not isExcluded(name) then
                        temporary[frame] = {name = name, time = now, state = "observed"}
                    else temporary[frame] = nil end
                end
            end
        end
    end
    return countTracked(now)
end



-- Routing verified against Nampower's event signatures and the local Lost capture.
local routes = {
    UNIT_COMBAT_GUID = {1}, UNIT_MODEL_CHANGED_GUID = {1},
    UNIT_CASTEVENT = {1}, SPELL_GO_OTHER = {3}, SPELL_START_OTHER = {3},
    SPELL_DAMAGE_EVENT_OTHER = {2, 1}, SPELL_DAMAGE_EVENT_SELF = {2, 1},
    AUTO_ATTACK_OTHER = {1, 2}, AUTO_ATTACK_SELF = {1, 2},
    SPELL_MISS_OTHER = {1, 2},
}
local function observeEvent(unit, now)
    if not validGuid(unit) then return false end
    local guid, name, reason = observeUnit(unit, now, true)
    if guid then mergePromotedFrames(guid); return true end
    -- Only retry unresolved objects or friendly units with unknown ownership.
    if (not safeCall(UnitExists, unit) or reason == "unknown") and not pending[unit] then
        local size = 0; for _ in pairs(pending) do size = size + 1 end
        if size < 64 then pending[unit] = now + 2 end
    end
    return false
end
local function retryPending(now)
    for guid, deadline in pairs(pending) do
        if now > deadline then pending[guid] = nil
        else
            diagnostics.retry = diagnostics.retry + 1
            local found, name, reason = observeUnit(guid, now, true)
            if found then mergePromotedFrames(found)
            elseif reason == "other" or (safeCall(UnitExists, guid) and not eligible(guid)) then pending[guid] = nil end
        end
    end
end
local api = {}
function api.Scan()
    retryPending(GetTime())
    return scanForSummons()
end
function api.Totals() return countTracked(GetTime()) end
function api.Reset()
    TY.summonCache = {}; temporary = {}; ownerCache = {}; deadUntil = {}; pending = {}
    playerName, playerGuid = UnitName("player"), getGuid("player")
end
function api.Register(frame)
    for name in pairs(routes) do registrations[name] = pcall(frame.RegisterEvent, frame, name) end
    registrations.UNIT_DIED = pcall(frame.RegisterEvent, frame, "UNIT_DIED")
end
function api.Event(name, a1, a2, a3)
    local now = GetTime()
    if name == "UNIT_DIED" and validGuid(a1) then
        eventCounts[name] = (eventCounts[name] or 0) + 1
        local had = TY.summonCache[a1] ~= nil
        for _, info in pairs(temporary) do if info.guid == a1 then had = true end end
        if not had then return false end
        deadUntil[a1] = now + 2; TY.summonCache[a1] = nil; ownerCache[a1] = nil; pending[a1] = nil
        mergePromotedFrames(a1)
    elseif routes[name] then
        local args = {a1, a2, a3}; local changed = false
        for _, index in ipairs(routes[name]) do
            local unit = args[index]
            local had = unit and TY.summonCache[unit]
            if observeEvent(unit, now) or had then changed = true end
        end
        eventCounts[name] = (eventCounts[name] or 0) + 1
        if not changed then return false end
    else return false end
    diagnostics.events = diagnostics.events + 1
    return true
end
function api.Diagnostics() return diagnostics, eventCounts, registrations, TY.summonCache, temporary end
api.IsExcluded = isExcluded
TianYanTracker = api
