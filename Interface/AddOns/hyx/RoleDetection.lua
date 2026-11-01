-- PureDispel independent role hints. Maintained by StoneChyi & Codex.
-- WoW 1.12 / Lua 5.0. Talents are evidence of a build, not a raid assignment.
-- No current-health, inspect-cache, other-addon or CVar dependencies.
local D = XinDispel
local R = { enabled = false, visible = true }
D.Roles = R
local records, order, latestRoster, quarantine = {}, {}, nil, {}
local pending, paused, validation, transportLocked
local nextTick, nextRoster, nextRequest, nextHealth = 0, 0, 0, 0
local manualBatch, combat, combatSerial, validatedSerial = false, false, 0, -1
local hpBaseline = 0
local inactiveNext, inactiveIdentity, inactiveIndex = 0, {}, {}
local inactiveInitialized = false
local manualSeen = {}
local frame = CreateFrame("Frame")
local metrics = { requests = 0, packets = 0, rejected = 0, maxHealthReads = 0,
    ticks = 0, timeouts = 0, validationEvents = 0 }
local roles = { TANK = true, HEALER = true, MELEE = true, RANGED = true, UNKNOWN = true }
local tankClasses = { WARRIOR = true, DRUID = true, PALADIN = true, SHAMAN = true }
local prefix = "TW_CHAT_MSG_WHISPER"
local message = "尚未启用职责识别"

local function Now() return GetTime() end
local function Truth(value) return value ~= nil and value ~= false and value ~= 0 end
local function Clear(t) for k in pairs(t) do t[k] = nil end end
local function Active() return R.visible and (R.enabled or manualBatch) end
local function Overrides(create)
    if not D.teamOwnerReady or type(xinDB) ~= "table" or type(xinDB.teamOwner) ~= "string"
        or xinDB.teamOwner == "" then return nil end
    if xinDB.teamRoleOwner ~= xinDB.teamOwner then
        xinDB.teamRoleOverrides, xinDB.teamRoleOwner = {}, xinDB.teamOwner
        Clear(manualSeen)
    end
    if type(xinDB.teamRoleOverrides) ~= "table" then
        if not create then return nil end
        xinDB.teamRoleOverrides = {}
    end
    return xinDB.teamRoleOverrides
end
local function Changed()
    -- The driver's next normal update consumes this; never recurse into D.Update.
    D.dirty = true
    if type(R.OnChanged) == "function" then R.OnChanged() end
end
local function Valid(rec)
    if not rec or not rec.current or not rec.unit or UnitName(rec.unit) ~= rec.name then return false end
    local exists, guid = UnitExists(rec.unit)
    if not exists then return false end
    if type(guid) == "string" and rec.key ~= rec.name and rec.key ~= guid then return false end
    local _, class = UnitClass(rec.unit)
    return class == rec.class
end
local function Quarantine(name)
    if not quarantine[name] then quarantine[name] = true end
    local n = 0
    for _ in pairs(quarantine) do n = n + 1 end
    -- The protocol has no transaction ID. Never retry a cancelled sender in this
    -- login session: even a very late END must not finish a later transaction.
    if n > 80 then Clear(quarantine); transportLocked = true end
end
local function CancelPending(state)
    if pending then
        pending.rec.queryState = state or "paused"
        Quarantine(pending.name)
        pending = nil
    end
end
local function StopValidation()
    frame:UnregisterEvent("AUTO_ATTACK_OTHER")
    if not validation then return end
    for _, rec in ipairs(order) do
        local ev = validation.members[rec.name]
        if ev then
            rec.validation = { attacks = ev.attacks, damage = ev.damage, blocks = ev.blocks,
                dodges = ev.dodges, parries = ev.parries }
            if rec.candidate and not rec.manual and ev.attacks >= 4 and ev.repeated >= 3 then
                rec.role, rec.confidence, rec.provisional = "TANK", "medium", true
                rec.source = "talent+maxHealth+validation"
            end
        end
    end
    validation = nil
    Changed()
end
local function Events()
    if Active() then
        if type(UnitAffectingCombat) == "function" then
            local current = Truth(UnitAffectingCombat("player"))
            if current and not combat then combatSerial = combatSerial + 1 end
            combat = current
        end
        frame:RegisterEvent("CHAT_MSG_ADDON")
        frame:RegisterEvent("PLAYER_REGEN_DISABLED")
        frame:RegisterEvent("PLAYER_REGEN_ENABLED")
    else
        frame:UnregisterEvent("CHAT_MSG_ADDON")
        frame:UnregisterEvent("PLAYER_REGEN_DISABLED")
        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
        StopValidation()
    end
end
local function MaxHealth(rec)
    if not Valid(rec) then return end
    local value
    if type(GetUnitField) == "function" then
        metrics.maxHealthReads = metrics.maxHealthReads + 1
        local ok, result = pcall(GetUnitField, rec.unit, "maxHealth")
        if ok then value = result end
    end
    if (type(value) ~= "number" or value <= 100) and type(UnitHealthMax) == "function" then
        metrics.maxHealthReads = metrics.maxHealthReads + 1
        local ok, result = pcall(UnitHealthMax, rec.unit)
        if ok then value = result end
    end
    -- Old percentage-only APIs return 100; that cannot be an absolute HP sample.
    local old = rec.maxHealth
    if type(value) == "number" and value > 100 and value < 10000000 then
        rec.maxHealth = value
    else
        rec.maxHealth = nil
    end
    rec.needMax = nil
    return old ~= rec.maxHealth
end
local function Rank(rec, tree, index)
    return rec.talents and rec.talents[tree] and rec.talents[tree].ranks[index] or 0
end
local function Classify(rec)
    if rec.manual then
        rec.role, rec.confidence, rec.source, rec.provisional = rec.manual, "high", "manual", false
        rec.candidate = nil
        return
    end
    rec.role, rec.confidence, rec.source, rec.provisional = "UNKNOWN", "unknown", "unavailable", true
    rec.candidate = nil
    if not rec.talents then return end
    local a, b, c = rec.talents[1].points, rec.talents[2].points, rec.talents[3].points
    local tree, points, second = 1, a, math.max(b, c)
    if b > points then tree, points, second = 2, b, math.max(a, c) end
    if c > points then tree, points, second = 3, c, math.max(a, b) end
    rec.source = "talent"
    local class, role, confidence, provisional = rec.class, "UNKNOWN", "low", true
    local deep = points >= 31 and points > second
    if class == "MAGE" or class == "WARLOCK" then role, confidence, provisional = "RANGED", "high", false
    elseif class == "ROGUE" then role, confidence, provisional = "MELEE", "high", false
    elseif points >= 21 and points > second then
        confidence, provisional = "medium", true
        if class == "WARRIOR" then
            role = "MELEE"
            if tree == 3 then
                role = "TANK"
                if deep and Rank(rec, 3, 14) > 0 then confidence, provisional = "high", false end
            elseif deep then confidence, provisional = "high", false end
        elseif class == "PALADIN" then
            role = tree == 1 and "HEALER" or tree == 2 and "TANK" or "MELEE"
            if deep and (tree == 3 or (tree == 2 and Rank(rec, 2, 13) > 0 and Rank(rec, 2, 6) > 0)
                or (tree == 1 and Rank(rec, 1, 6) > 0 and Rank(rec, 1, 11) > 0)) then
                confidence, provisional = "high", false
            end
        elseif class == "PRIEST" then
            role = tree == 3 and "RANGED" or "HEALER"
            -- Discipline can also be damage-focused on Turtle; keep it provisional.
            if deep and ((tree == 3 and Rank(rec, 3, 17) > 0)
                or (tree == 2 and Rank(rec, 2, 16) > 0)) then confidence, provisional = "high", false end
        elseif class == "SHAMAN" then
            role = tree == 1 and "RANGED" or tree == 2 and "MELEE" or "HEALER"
            if deep then confidence, provisional = "high", false end
        elseif class == "DRUID" then
            role = tree == 1 and "RANGED" or tree == 2 and "MELEE" or "HEALER"
            -- Feral does not establish whether the player is a bear or a cat.
            if deep and tree ~= 2 then confidence, provisional = "high", false end
        elseif class == "HUNTER" then
            role = "RANGED"
            if tree == 3 then
                if deep and Rank(rec, 3, 17) > 0 then role, confidence, provisional = "MELEE", "high", false end
            elseif deep then confidence, provisional = "high", false end
        end
    end
    rec.role, rec.confidence, rec.provisional = role, confidence, provisional
    -- HP is only supporting evidence for a tank-capable, talent-qualified build.
    -- A high-HP character with no usable talents remains UNKNOWN.
    local hp = hpBaseline
    local tankBuild = (class == "WARRIOR" and tree == 2 and deep and Rank(rec, 3, 12) > 0)
        or (class == "DRUID" and tree == 2 and points >= 21 and Rank(rec, 2, 5) >= 2 and Rank(rec, 2, 10) > 0)
        or (class == "SHAMAN" and tree == 2 and points >= 21 and Rank(rec, 2, 2) >= 3 and Rank(rec, 2, 9) > 0)
    if tankBuild then
        -- Missing absolute HP or too small a comparison group cannot establish
        -- that a threat/defensive hybrid is definitely a damage dealer either.
        rec.confidence, rec.provisional, rec.source = "medium", true, "talent-ambiguous"
    end
    if tankBuild and hp > 0 and rec.maxHealth and rec.maxHealth >= hp * 1.15 then
        rec.role, rec.confidence, rec.provisional = "TANK", "low", true
        rec.source, rec.candidate = "talent+maxHealth", true
    end
end
local function RestoreSaved(rec)
    local saved = Overrides(false)
    local item = saved and saved[rec.name]
    if type(item) == "table" and roles[item.role] and item.key == rec.key and item.class == rec.class then
        rec.manual = item.role
        manualSeen[rec.name] = rec.key
        Classify(rec)
    end
end
local function Fail(state, text)
    if pending then pending.rec.queryState = state; Quarantine(pending.name); pending = nil end
    paused, message = true, text
    if state == "timeout" then metrics.timeouts = metrics.timeouts + 1 end
    Changed()
end
local function Structure(class) return D.RoleTalentData and D.RoleTalentData[class] end
local function Integer(text, low, high)
    local value = tonumber(text)
    if value and value == math.floor(value) and value >= low and value <= high then return value end
    return nil
end
local function Split(text)
    local result, start = {}, 1
    while true do
        local at = string.find(text, ";", start, true)
        if not at then table.insert(result, string.sub(text, start)); return result end
        table.insert(result, string.sub(text, start, at - 1)); start = at + 1
        if table.getn(result) > 12 then return result end
    end
end
local function Complete()
    local p = pending
    if not p or not Valid(p.rec) or p.rec.key ~= p.key then Fail("invalid", "队员身份已变化，查询已暂停"); return end
    local data, total = Structure(p.class), 0
    for tree = 1, 3 do
        local tab, sum = p.trees[tree], 0
        if not tab or tab.count ~= table.getn(data[tree]) then Fail("incomplete", "天赋数据不完整，已暂停查询"); return end
        for index = 1, table.getn(data[tree]) do
            local rank = tab.ranks[index]
            if rank == nil then Fail("incomplete", "天赋数据缺包，已暂停查询"); return end
            sum = sum + rank
        end
        if sum ~= tab.points then Fail("invalid", "天赋点数校验失败，已暂停查询"); return end
        total = total + sum
    end
    if total > 51 then Fail("invalid", "天赋总点数不合法，已暂停查询"); return end
    p.rec.talents, p.rec.queryState = p.trees, "complete"
    Classify(p.rec)
    pending, nextRequest, message = nil, Now() + 1, "天赋已完成校验"
    Changed()
end
local function Packet(receivedPrefix, body, channel, sender)
    if not Active() or not pending or type(body) ~= "string" or type(sender) ~= "string" then return end
    if sender ~= pending.name or quarantine[sender] then metrics.rejected = metrics.rejected + 1; return end
    local selfName = UnitName("player")
    if receivedPrefix ~= prefix and receivedPrefix ~= prefix .. "<" .. tostring(selfName) .. ">" then
        metrics.rejected = metrics.rejected + 1; return
    end
    if not Valid(pending.rec) or pending.rec.key ~= pending.key or Now() > pending.deadline then
        Fail("timeout", "查询已超时或队员身份变化，已暂停后续请求"); return
    end
    if body == "INSTalentEND;" then Complete(); return end
    local fields = Split(body)
    -- Native clients normally omit this terminator; tolerate exactly one.
    if fields[table.getn(fields)] == "" then table.remove(fields) end
    if fields[1] ~= "INSTalentTabInfo" and fields[1] ~= "INSTalentInfo" then return end
    metrics.packets = metrics.packets + 1
    if string.len(body) > 2048 then Fail("invalid", "天赋数据格式错误"); return end
    local tree = Integer(fields[2], 1, 3)
    local data = Structure(pending.class)
    if not tree or not data then Fail("invalid", "天赋结构不受支持"); return end
    if fields[1] == "INSTalentTabInfo" then
        local points, count = Integer(fields[4], 0, 51), Integer(fields[5], 1, 50)
        if table.getn(fields) ~= 5 or not fields[3] or fields[3] == "" or not points
            or count ~= table.getn(data[tree]) then Fail("invalid", "天赋树结构不匹配，已暂停查询"); return end
        local old = pending.trees[tree]
        if old and (old.points ~= points or old.count ~= count) then Fail("invalid", "天赋树数据冲突"); return end
        if not old then pending.trees[tree] = { points = points, count = count, ranks = {} } end
    else
        local index = Integer(fields[3], 1, table.getn(data[tree]))
        local expected = index and data[tree][index]
        local rank = Integer(fields[7], 0, expected and expected[1] or 0)
        if table.getn(fields) ~= 12 or not expected or not fields[4] or fields[4] == "" or not rank
            or tonumber(fields[5]) ~= expected[2] or tonumber(fields[6]) ~= expected[3]
            or tonumber(fields[8]) ~= expected[1] or not Integer(fields[9], 0, 1)
            or not Integer(fields[10], -1, 7) or not Integer(fields[11], -1, 4)
            or not Integer(fields[12], -1, 1) then Fail("invalid", "天赋等级或位置校验失败"); return end
        local tab = pending.trees[tree]
        if not tab then Fail("incomplete", "缺少天赋树信息，已暂停查询"); return end
        if tab.ranks[index] ~= nil and tab.ranks[index] ~= rank then Fail("invalid", "重复天赋数据冲突"); return end
        tab.ranks[index] = rank
    end
end
local function ReadSelf(rec)
    local data = Structure(rec.class)
    if not data or type(GetNumTalentTabs) ~= "function" or type(GetTalentInfo) ~= "function"
        or type(GetTalentTabInfo) ~= "function" or type(GetNumTalents) ~= "function" then
        rec.queryState = "unavailable"; return
    end
    local ok, tabs = pcall(GetNumTalentTabs)
    if not ok or tabs ~= 3 then rec.queryState = "unavailable"; return end
    local trees, total = {}, 0
    for tree = 1, 3 do
        local valid, count = pcall(GetNumTalents, tree)
        local tabOK, name, icon, points = pcall(GetTalentTabInfo, tree)
        if not valid or not tabOK or count ~= table.getn(data[tree]) or not Integer(points, 0, 51) then
            rec.queryState = "unavailable"; return
        end
        local ranks, sum = {}, 0
        for index = 1, count do
            local success, talentName, texture, tier, column, rank, maximum = pcall(GetTalentInfo, tree, index)
            local expected = data[tree][index]
            if not success or not Integer(rank, 0, expected[1]) or maximum ~= expected[1]
                or tier ~= expected[2] or column ~= expected[3] then rec.queryState = "unavailable"; return end
            ranks[index], sum = rank, sum + rank
        end
        if sum ~= points then rec.queryState = "unavailable"; return end
        total, trees[tree] = total + sum, { count = count, points = points, ranks = ranks }
    end
    if total > 51 then rec.queryState = "unavailable"; return end
    rec.talents, rec.queryState = trees, "complete"
    Classify(rec); Changed()
end
local function Reconcile(now)
    if not latestRoster then return end
    local changed, healthChanged = false, false
    for _, rec in pairs(records) do rec.wasCurrent, rec.current = rec.current, false end
    Clear(order)
    local limit = math.min(table.getn(latestRoster), 40)
    for i = 1, limit do
        local item = latestRoster[i]
        if item and type(item.name) == "string" and item.name ~= "" and Structure(item.class) then
            local rec = records[item.name]
            local key = item.key or item.name
            if not rec or rec.key ~= key or rec.class ~= item.class then
                rec = { name = item.name, key = key, class = item.class, role = "UNKNOWN", confidence = "unknown",
                    source = "unavailable", provisional = true, queryState = "queued", needMax = true }
                records[item.name] = rec
                changed = true
            end
            if not rec.wasCurrent then changed = true end
            rec.unit, rec.self, rec.current = item.unit, item.self, true
            rec.lastSeen = now
            if not rec.manual then RestoreSaved(rec) end
            if rec.queryState == "offline" and type(UnitIsConnected) == "function"
                and Truth(UnitIsConnected(rec.unit)) then
                rec.queryState, changed = "queued", true
            end
            table.insert(order, rec)
        end
    end
    -- Keep a bounded team-session cache so a returning member is not re-queried.
    local recordCount = 0
    for _, rec in pairs(records) do
        recordCount = recordCount + 1
        if rec.wasCurrent and not rec.current then
            changed = true
            local saved = Overrides(false)
            if saved then saved[rec.name] = nil end
            manualSeen[rec.name] = nil
            rec.manual = nil
        end
    end
    while recordCount > 80 do
        local oldestName, oldest = nil, now + 1
        for name, rec in pairs(records) do
            if not rec.current and (rec.lastSeen or 0) < oldest then oldestName, oldest = name, rec.lastSeen or 0 end
        end
        if not oldestName then break end
        records[oldestName], recordCount = nil, recordCount - 1
    end
    if pending and not Valid(pending.rec) then Fail("departed", "查询中的队员已离队，已暂停后续请求") end
    local healthPass = now >= nextHealth
    if healthPass then nextHealth = now + 60 end
    for _, rec in ipairs(order) do
        if not combat and (rec.needMax or (healthPass and rec.provisional)) then
            if MaxHealth(rec) then healthChanged = true end
        end
    end
    if changed or healthChanged then
        local sample = {}
        for _, rec in ipairs(order) do if rec.maxHealth then table.insert(sample, rec.maxHealth) end end
        local count = table.getn(sample)
        hpBaseline = 0
        if count >= 3 then table.sort(sample); hpBaseline = sample[math.floor((count + 1) / 2)] end
        -- Stable conclusions survive the session; provisional builds are only
        -- reconsidered after changed evidence, never once per scan or tick.
        for _, rec in ipairs(order) do
            if rec.talents and rec.provisional and not rec.validation then Classify(rec) end
        end
        Changed()
    end
end

local function PruneInactive(now)
    local saved = Overrides(false)
    if (next(records) == nil and (not saved or next(saved) == nil)) or now < inactiveNext then return end
    inactiveNext = now + 1
    local count = math.min(table.getn(latestRoster or {}), 40)
    local changed = not inactiveInitialized or count ~= table.getn(inactiveIdentity)
    inactiveInitialized = true
    for i = 1, count do
        local item, old = latestRoster[i], inactiveIdentity[i]
        if not old then old = {}; inactiveIdentity[i] = old end
        if old.name ~= item.name or old.key ~= item.key or old.class ~= item.class or old.unit ~= item.unit then
            changed = true
            old.name, old.key, old.class, old.unit = item.name, item.key, item.class, item.unit
        end
    end
    for i = table.getn(inactiveIdentity), count + 1, -1 do inactiveIdentity[i] = nil end
    if not changed then return end
    Clear(inactiveIndex)
    for i = 1, count do
        local item = latestRoster[i]
        inactiveIndex[item.name] = item
        if saved and type(saved[item.name]) == "table" and saved[item.name].key == (item.key or item.name)
            and saved[item.name].class == item.class then manualSeen[item.name] = item.key or item.name end
    end
    for name, rec in pairs(records) do
        local item = inactiveIndex[name]
        local current = item and item.class == rec.class and (item.key or name) == rec.key
        rec.current = current and true or false
        if current then rec.unit, rec.self = item.unit, item.self
        elseif rec.manual then rec.manual = nil; Classify(rec) end
    end
    if saved then
        for name, item in pairs(saved) do
            local current = inactiveIndex[name]
            -- A saved member not yet seen this login may simply be waiting for
            -- the initial group roster; the engine confirms whole-team departure.
            local departed = not current and type(item) == "table" and manualSeen[name] == item.key
            local mismatch = current and (type(item) ~= "table" or item.key ~= (current.key or name) or item.class ~= current.class)
            if departed or mismatch then
                saved[name] = nil
                manualSeen[name] = nil
            end
        end
    end
    local n, previous = 0, table.getn(order)
    for i = 1, previous do
        if order[i].current then n = n + 1; order[n] = order[i] end
    end
    for i = previous, n + 1, -1 do order[i] = nil end
    Changed()
end

function R.UpdateRoster(roster)
    latestRoster = roster
    local now = Now()
    if not Active() then PruneInactive(now); return end
    if now < nextRoster then return end
    nextRoster = now + 1
    Reconcile(now)
end
function R.Tick(now)
    now = now or Now()
    if not Active() or now < nextTick then return end
    nextTick, metrics.ticks = now + 1, metrics.ticks + 1
    if now >= nextRoster then nextRoster = now + 1; Reconcile(now) end
    if validation and now >= validation.ends then StopValidation() end
    if combat then return end
    if pending then
        if now > pending.deadline then Fail("timeout", "天赋查询超时，后续查询已暂停；可刷新继续其他队员") end
        return
    end
    if paused or transportLocked or now < nextRequest then return end
    for _, rec in ipairs(order) do
        if rec.queryState == "queued" and Valid(rec) then
            if quarantine[rec.name] then rec.queryState = "isolated"
            elseif type(UnitIsConnected) == "function" and not Truth(UnitIsConnected(rec.unit)) then
                rec.queryState = "offline"
                Changed()
            elseif rec.self then
                ReadSelf(rec)
                if rec.queryState == "complete" then nextRequest = now + 1; return end
            elseif type(SendAddonMessage) ~= "function" then rec.queryState = "unavailable"
            else
                pending = { name = rec.name, key = rec.key, class = rec.class, rec = rec, trees = {}, deadline = now + 6 }
                rec.queryState, message = "pending", "正在串行查询天赋"
                local ok = pcall(SendAddonMessage, prefix .. "<" .. rec.name .. ">", "INSTalentShow", "GUILD")
                if not ok then Fail("unavailable", "当前客户端无法发出天赋查询"); return end
                metrics.requests = metrics.requests + 1
                Changed(); return
            end
        end
    end
    if manualBatch then manualBatch = false; Events() end
end
function R.Get(name)
    local rec = records[name]
    if rec and Valid(rec) then return rec end
    return nil
end
function R.Peek(name, key, class)
    -- For the engine's already-validated roster; no native API reads.
    local rec = records[name]
    if rec and rec.current and rec.key == key and rec.class == class then return rec end
    return nil
end
local function Manual(name, role)
    local rec = records[name]
    -- A deliberate correction is also available with the default preset off.
    -- Only this member is materialized; no health read or network query occurs.
    if not Valid(rec) and latestRoster then
        for i = 1, math.min(table.getn(latestRoster), 40) do
            local item = latestRoster[i]
            if item.name == name and Structure(item.class) then
                rec = { name = name, unit = item.unit, key = item.key or name, class = item.class,
                    self = item.self, current = true, queryState = "queued", needMax = true }
                if not Valid(rec) then rec = nil; break end
                records[name] = rec; table.insert(order, rec)
                RestoreSaved(rec)
                break
            end
        end
    end
    if not Valid(rec) then return false, "目标已不在当前队伍" end
    if role ~= nil and not roles[role] then return false, "职责类型无效" end
    local old = rec.manual
    rec.manual = role; Classify(rec)
    inactiveInitialized, inactiveNext = false, 0
    local saved = Overrides(true)
    if saved then
        saved[name] = role and { role = role, key = rec.key, class = rec.class } or nil
        manualSeen[name] = role and rec.key or nil
    end
    Changed()
    return true, nil, old
end
R.SetManual = Manual
function R.RestoreManual(name, role)
    return Manual(name, role)
end
function R.Refresh()
    if not R.visible then return false, "请先打开驱散窗口" end
    if combat or (type(UnitAffectingCombat) == "function" and Truth(UnitAffectingCombat("player"))) then
        return false, "战斗中仅使用缓存，请在脱战后重新识别"
    end
    CancelPending("isolated")
    manualBatch, paused, nextTick, nextRoster, nextRequest, nextHealth = true, false, 0, 0, 0, 0
    Reconcile(Now())
    for _, rec in ipairs(order) do
        rec.queryState, rec.needMax = quarantine[rec.name] and "isolated" or "queued", true
        rec.talents, rec.validation, rec.candidate = nil, nil, nil
        if not rec.manual then Classify(rec) end
    end
    message = transportLocked and "本次登录的查询已安全暂停，请重新载入后重试" or "准备重新识别职责"
    Events(); Changed()
    return not transportLocked, transportLocked and message or nil
end
function R.SetVisible(value)
    value = value and true or false
    if R.visible == value then return end
    R.visible = value
    if not R.visible then CancelPending("isolated"); manualBatch = false; StopValidation() end
    Events()
end
function R.SetEnabled(value)
    value = value and true or false
    if R.enabled == value then return end
    R.enabled = value
    if not R.enabled then manualBatch = false; CancelPending("isolated"); StopValidation()
    else nextTick, nextRoster = 0, 0; message = "等待职责识别" end
    Events()
end
function R.ResetTeam()
    CancelPending("isolated"); StopValidation()
    Clear(records); Clear(order); latestRoster = nil
    Clear(inactiveIdentity); Clear(inactiveIndex); Clear(manualSeen); inactiveNext, inactiveInitialized = 0, false
    if type(xinDB) == "table" then
        xinDB.teamRoleOverrides = {}
        xinDB.teamRoleOwner = D.teamOwnerReady and xinDB.teamOwner or nil
    end
    manualBatch, paused, nextTick, nextRoster, nextRequest, nextHealth = false, false, 0, 0, 0, 0
    validatedSerial, message, hpBaseline = -1, "本队职责已清除", 0
    Events(); Changed()
end
function R.StartValidation()
    if not Active() then return false, "请先启用职责预设并显示驱散窗口" end
    if not combat then return false, "请在战斗中启动短时校验" end
    if validation or validatedSerial == combatSerial then return false, "本场战斗已进行过短时校验" end
    if type(GetNampowerVersion) ~= "function" then return false, "当前缺少可用的战斗扩展接口" end
    local members, guids, allGuids, found = {}, {}, {}, false
    for _, rec in ipairs(order) do
        if Valid(rec) then
            local exists, guid = UnitExists(rec.unit)
            if exists and type(guid) == "string" then allGuids[guid] = true end
        end
        if Valid(rec) and not rec.manual and tankClasses[rec.class] and (rec.candidate or rec.role == "UNKNOWN") then
            local exists, guid = UnitExists(rec.unit)
            if exists and type(guid) == "string" and guid ~= "" then
                members[rec.name] = { attacks = 0, damage = 0, blocks = 0, dodges = 0, parries = 0,
                    repeated = 0, attacker = nil }
                guids[guid], found = rec, true
            end
        end
    end
    if not found then return false, "没有可校验的坦克候选或未知队员" end
    validation = { ends = Now() + 8, members = members, guids = guids, allGuids = allGuids }
    validatedSerial = combatSerial
    frame:RegisterEvent("AUTO_ATTACK_OTHER")
    message = "短时校验进行中（8秒）；结果仅作辅助"
    Changed(); return true
end
function R.OnEvent(name, a1, a2, a3, a4, a5, a6, a7, a8, a9)
    if not Active() then return end
    if name == "CHAT_MSG_ADDON" then Packet(a1, a2, a3, a4)
    elseif name == "PLAYER_REGEN_DISABLED" then
        if not combat then combat, combatSerial = true, combatSerial + 1 end
        CancelPending("isolated")
        message = "战斗中仅使用已缓存职责"
    elseif name == "PLAYER_REGEN_ENABLED" then combat = false; StopValidation()
    elseif name == "AUTO_ATTACK_OTHER" and validation then
        if Now() >= validation.ends then StopValidation(); return end
        local rec = validation.guids[a2]
        if not rec or not Valid(rec) or type(a1) ~= "string" or validation.allGuids[a1] then return end
        -- GUID text alone does not establish hostility. Require a currently
        -- resolvable enemy NPC (target or this victim's target); otherwise abstain.
        local hostile = false
        if type(UnitIsEnemy) == "function" and type(UnitIsPlayer) == "function" then
            local tokens = { "target", rec.unit .. "target" }
            for _, token in ipairs(tokens) do
                local exists, guid = UnitExists(token)
                if exists and guid == a1 and Truth(UnitIsEnemy("player", token)) and not Truth(UnitIsPlayer(token)) then
                    hostile = true; break
                end
            end
        end
        if not hostile then return end
        local amount = tonumber(a3)
        if not amount or amount < 0 or amount > 10000000 then return end
        local ev = validation.members[rec.name]
        ev.attacks, ev.damage = ev.attacks + 1, ev.damage + amount
        if ev.attacker == a1 then ev.repeated = ev.repeated + 1 else ev.attacker, ev.repeated = a1, 1 end
        if a5 == 2 then ev.dodges = ev.dodges + 1 elseif a5 == 3 then ev.parries = ev.parries + 1 end
        if a5 == 5 or (tonumber(a7) or 0) > 0 then ev.blocks = ev.blocks + 1 end
        metrics.validationEvents = metrics.validationEvents + 1
    end
end
function R.GetDiagnostics()
    local result = { pending = pending ~= nil, completed = 0, total = table.getn(order), unknown = 0,
        state = not Active() and "paused" or paused and "paused" or pending and "querying" or "ready",
        message = message, enabled = R.enabled, visible = R.visible, validationActive = validation ~= nil,
        isolated = 0 }
    for _, rec in ipairs(order) do
        if rec.queryState == "complete" then result.completed = result.completed + 1 end
        if rec.role == "UNKNOWN" or rec.provisional then result.unknown = result.unknown + 1 end
        if quarantine[rec.name] then result.isolated = result.isolated + 1 end
    end
    for key, value in pairs(metrics) do result[key] = value end
    return result
end
frame:SetScript("OnEvent", function() R.OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end)
