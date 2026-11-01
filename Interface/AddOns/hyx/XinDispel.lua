-- PureDispel / 净界驱散: personal modifications maintained by StoneChyi & Codex.
-- Based on hyx by hyx; original authorship and applicable licenses retained.
-- WoW 1.12 / Lua 5.0 engine. UI lives in PureDispelUI.lua.
XinDispel = { ready = false, dirty = true, spellsDirty = true, spells = {},
    entries = { ready = {}, blocked = {} },
    metrics = { scanCycles = 0, tooltipReads = 0, rangeChecks = 0, notifications = 0 } }
local D = XinDispel
D.VERSION = "2.3.0"
D.Types = {
    Magic = { name = "魔法", r = .2, g = .6, b = 1 },
    Curse = { name = "诅咒", r = .65, g = .2, b = 1 },
    Poison = { name = "中毒", r = 0, g = .8, b = 0 },
    Disease = { name = "疾病", r = .8, g = .5, b = 0 }
}
D.ClassColors = {
    MAGE = { r = .41, g = .80, b = .94 }, HUNTER = { r = .67, g = .83, b = .45 },
    ROGUE = { r = 1, g = .96, b = .41 }, WARRIOR = { r = .78, g = .61, b = .43 },
    PRIEST = { r = 1, g = 1, b = 1 }, WARLOCK = { r = .58, g = .51, b = .79 },
    PALADIN = { r = .96, g = .55, b = .73 }, DRUID = { r = 1, g = .49, b = .04 },
    SHAMAN = { r = 0, g = .44, b = .87 }
}
local typeOrder = { "Magic", "Curse", "Poison", "Disease" }
local classNames = { WARRIOR = "战士", ROGUE = "盗贼", PRIEST = "牧师", DRUID = "小德",
    PALADIN = "骑士", HUNTER = "猎人", MAGE = "法师", WARLOCK = "术士", SHAMAN = "萨满" }
local cleanse = { "清洁术", "淨化術", "Cleanse" }
local purify = { "纯净术", "純淨術", "Purify" }
local curePoison = { "消毒术", "消毒術", "Cure Poison" }
local abolishPoison = { "驱毒术", "驅毒術", "Abolish Poison" }
local cureDisease = { "祛病术", "祛病術", "Cure Disease" }
local abolishDisease = { "驱除疾病", "驅除疾病", "Abolish Disease" }
local spellRules = {
    PALADIN = { Magic = { cleanse }, Poison = { cleanse, purify }, Disease = { cleanse, purify } },
    PRIEST = { Magic = { { "驱散魔法", "驅散魔法", "Dispel Magic" } }, Disease = { cureDisease, abolishDisease } },
    DRUID = { Curse = { { "解除诅咒", "解除詛咒", "Remove Curse" } }, Poison = { abolishPoison, curePoison } },
    MAGE = { Curse = { { "解除次级诅咒", "解除次級詛咒", "Remove Lesser Curse" } } },
    SHAMAN = { Poison = { curePoison }, Disease = { cureDisease } },
    WARLOCK = { Magic = { { "吞噬魔法", "Devour Magic" } } }
}
local scanner = CreateFrame("GameTooltip", "XinTooltipScanner", nil, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")
local driver = CreateFrame("Frame", "PureDispelEngine", UIParent)
D.driver = driver
local roster, rosterPool, rosterNames, ordered = {}, {}, {}, {}
local entryPool, spellPool, known = {}, {}, {}
local rawTokens = { "player" }
for i = 1, 4 do rawTokens[1 + i] = "party" .. i end
for i = 1, 40 do rawTokens[5 + i] = "raid" .. i end
local castAura, scratchAura = {}, {}
local initializedDB, fullBlockRules, rulesDirty, revision = nil, false, true, 0
local elapsed, awaySince, settleUntil = 0, nil, 0
local undoRecord

local function Clear(t) for k in pairs(t) do t[k] = nil end end
local function TrimArray(t, n) for i = table.getn(t), n + 1, -1 do t[i] = nil end end
local function Truth(v) return v ~= nil and v ~= false and v ~= 0 end
local function Clock() return GetTime and GetTime() or 0 end
local function CleanName(name)
    if type(name) ~= "string" then return nil end
    name = string.gsub(name, "^%s*(.-)%s*$", "%1")
    if name == "" or string.len(name) > 100 or string.find(name, "|", 1, true) then return nil end
    return name
end
local function KnownIdentity(value)
    local name = CleanName(value)
    if not name or name == UNKNOWNOBJECT or name == UNKNOWN or name == "Unknown"
        or name == "UNKNOWN" or name == "未知" or name == "未知目标" then return nil end
    return name
end
local function EnsureTeamOwner(force)
    if D.teamOwnerReady and not force then return true, false end
    local name = KnownIdentity(UnitName("player"))
    local realm
    if not name then D.teamOwnerReady = false; return false, false end
    if type(GetRealmName) == "function" then
        local ok, value = pcall(GetRealmName)
        realm = ok and KnownIdentity(value) or nil
        if not realm then D.teamOwnerReady = false; return false, false end
    end
    local owner = realm and (realm .. "::" .. name) or name
    local changed = not D.teamOwnerReady
    if xinDB.teamOwner and xinDB.teamOwner ~= owner then
        -- SavedVariables is account-wide. Only temporary rules/context belong
        -- to this character; permanent lists retain the existing shared scope.
        if D.Presets then D.Presets.ResetTeam() elseif D.Roles then D.Roles.ResetTeam() end
        Clear(xinDB.teamRules); Clear(xinDB.teamContext)
        undoRecord, awaySince, settleUntil = nil, nil, Clock() + 4
        D.spellsDirty = true
        changed = true
    end
    xinDB.teamOwner, D.teamOwnerReady = owner, true
    if changed then D.dirty = true end
    return true, changed
end
function D.Notify(message)
    if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage then
        DEFAULT_CHAT_FRAME:AddMessage("|cff80cfff净界驱散|r " .. tostring(message))
    end
end
local function SafeXP(command, source, unit)
    if type(UnitXP) ~= "function" then return nil end
    local ok, value = pcall(UnitXP, command, source, unit)
    if ok then return value end
    return nil
end
local function Identity(unit, name)
    local exists, guid = UnitExists(unit)
    if exists and type(guid) == "string" and guid ~= "" then return guid end
    return name
end
D.Identity = Identity

function D.GetManualPolicy(name)
    local db = xinDB or {}
    local team = D.teamOwnerReady and db.teamRules and db.teamRules[name]
    if team == "ignore" then return "ignore", "team" end
    if db.BlackList and db.BlackList[name] then return "ignore", "longterm" end
    if team == "priority" then return "priority", "team" end
    if db.PriorityList and db.PriorityList[name] then return "priority", "longterm" end
    return "normal", "none"
end

function D.GetPolicy(name)
    if D.Presets then return D.Presets.GetPolicy(name) end
    return D.GetManualPolicy(name)
end

local function RebuildRoster()
    Clear(rosterNames)
    local raidCount = math.min(GetNumRaidMembers(), 40)
    local count = raidCount > 0 and raidCount or math.min(GetNumPartyMembers(), 4) + 1
    local tokenStart = raidCount > 0 and 5 or 0
    local n = 0
    for i = 1, count do
        local unit = rawTokens[tokenStart + i]
        local name = UnitName(unit)
        if name and UnitExists(unit) then
            n = n + 1
            local item = rosterPool[n]
            if not item then item = {}; rosterPool[n] = item end
            local _, class = UnitClass(unit)
            item.name, item.unit, item.class = name, unit, class
            item.order = n
            item.key = Identity(unit, name)
            item.self = Truth(UnitIsUnit("player", unit))
            item.state, item.scope = D.GetPolicy(name)
            item.rank = item.self and 0 or item.state == "priority" and 1 or 2
            item.eligible = Truth(UnitIsConnected(unit)) and not Truth(UnitIsDeadOrGhost(unit))
                and Truth(UnitIsFriend("player", unit)) and not Truth(UnitCanAttack("player", unit))
            roster[n], rosterNames[name] = item, unit
        end
    end
    TrimArray(roster, n)
    if D.Presets then D.Presets.UpdateRoster(roster) end
    return roster
end
function D.GetRoster()
    if not D.ready then D.Init() end
    return RebuildRoster()
end

local function RebuildRuleFlags()
    fullBlockRules = false
    for _, level in pairs(xinDB.IgnoreList) do
        if level == 2 then fullBlockRules = true; break end
    end
    if not fullBlockRules then
        for _, rule in pairs(xinDB.RaidSettings) do
            if type(rule) == "table" and rule.ignoreType == 2 then fullBlockRules = true; break end
        end
    end
    rulesDirty = false
end
function D.GetRuleLevel(name, unit)
    local db = xinDB or {}
    local level = db.IgnoreList and db.IgnoreList[name]
    if level and level ~= 0 then return level, "custom" end
    local rule = db.RaidSettings and db.RaidSettings[name]
    if type(rule) == "table" then
        local _, class = UnitClass(unit)
        if rule.ignoreClasses and rule.ignoreClasses[classNames[class]] then return 1, "raid-class" end
        return rule.ignoreType or 0, "raid"
    end
    return 0, "none"
end

function D.RefreshSpells()
    Clear(known); Clear(D.spells)
    local _, class = UnitClass("player")
    local pet = class == "WARLOCK"
    local book = pet and (BOOKTYPE_PET or "pet") or (BOOKTYPE_SPELL or "spell")
    D.playerClass = class
    D.petReady = not pet or (Truth(UnitExists("pet")) and not Truth(UnitIsDeadOrGhost("pet")))
    if D.petReady then
        for slot = 1, 1024 do
            local name = GetSpellName(slot, book)
            if not name then break end
            known[name] = slot
        end
        for dispelType, candidates in pairs(spellRules[class] or {}) do
            for _, names in ipairs(candidates) do
                for _, name in ipairs(names) do
                    if known[name] then
                        local spell = spellPool[dispelType]
                        if not spell then spell = {}; spellPool[dispelType] = spell end
                        spell.name, spell.slot, spell.book = name, known[name], book
                        spell.pet, spell.range = pet, 30
                        D.spells[dispelType] = spell
                        break
                    end
                end
                if D.spells[dispelType] then break end
            end
        end
    end
    D.spellsDirty = false
end

function D.FindDebuff(unit, output)
    if not D.ready then D.Init() end
    if rulesDirty then RebuildRuleFlags() end
    local candidate = output or scratchAura
    local found = false
    for index = 1, 16 do
        local texture, stacks, dispelType = UnitDebuff(unit, index)
        if not texture then break end
        if fullBlockRules or D.spells[dispelType] then
            D.metrics.tooltipReads = D.metrics.tooltipReads + 1
            scanner:ClearLines(); scanner:SetUnitDebuff(unit, index)
            local text = XinTooltipScannerTextLeft1 and XinTooltipScannerTextLeft1:GetText()
            -- A missing tooltip name cannot safely satisfy name-based ignore
            -- rules. Retry next scan instead of recommending an unknown aura.
            if not text or text == "" then return nil end
            local name = text
            local level = D.GetRuleLevel(name, unit)
            if level == 2 then return nil end
            if not found and level ~= 1 and D.spells[dispelType] then
                candidate.index, candidate.texture, candidate.stacks = index, texture, stacks or 0
                candidate.type, candidate.name, candidate.nameStr = dispelType, name, name
                candidate.spell = D.spells[dispelType]
                found = true
                -- No whole-unit block rule: later aura names cannot change the
                -- first valid candidate, so avoid unnecessary tooltip work.
                if not fullBlockRules then break end
            end
        end
    end
    if found then return candidate end
    return nil
end

function D.Availability(unit, spell)
    if not spell then return false, "技能不可用" end
    D.metrics.rangeChecks = D.metrics.rangeChecks + 1
    local source = spell.pet and "pet" or "player"
    if spell.pet and (not UnitExists("pet") or Truth(UnitIsDeadOrGhost("pet"))) then return false, "宠物不可用" end
    local inRange
    if UnitIsUnit(source, unit) then inRange = true
    elseif not spell.pet and type(IsSpellInRange) == "function" then
        local ok, result = pcall(IsSpellInRange, spell.name, unit)
        if ok and (result == 0 or result == 1) then inRange = result == 1 end
    end
    if inRange == nil then
        local distance = SafeXP("distanceBetween", source, unit)
        if type(distance) == "number" and distance >= 0 then inRange = distance <= spell.range end
    end
    if inRange == false then return false, "距离过远" end
    if not UnitIsUnit(source, unit) then
        local sight = SafeXP("inSight", source, unit)
        if sight ~= nil and not Truth(sight) then return false, "视野之外" end
    end
    if inRange == nil then return false, "距离未知" end
    if Truth(UnitIsDeadOrGhost("player")) then return false, "你已死亡" end
    local ok, start, duration, enabled = pcall(GetSpellCooldown, spell.slot, spell.book)
    if not ok or enabled == 0 then return false, "技能不可用" end
    if start and duration and duration > 1.5 and start + duration > Clock() then return false, "冷却中" end
    if not spell.pet and type(IsSpellUsable) == "function" then
        local usableOK, usable, oom = pcall(IsSpellUsable, spell.name)
        if usableOK and Truth(oom) then return false, "法力不足" end
        if usableOK and usable ~= nil and not Truth(usable) then return false, "技能不可用" end
    end
    return true, ""
end

local function TeamState()
    if not D.ready then return end
    local ownerReady, ownerChanged = EnsureTeamOwner(false)
    if not ownerReady then return end
    if ownerChanged and D.OnChanged then D.OnChanged(true) end
    local grouped = GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
    if grouped then xinDB.teamContext.hadGroup = true; awaySince = nil
    elseif xinDB.teamContext.hadGroup and Clock() >= settleUntil then
        if not awaySince then awaySince = Clock() end
        if Clock() - awaySince >= 3 then
            local hadRules, hadUndo = next(xinDB.teamRules) ~= nil, undoRecord ~= nil
            -- Even an empty current table can have an undo snapshot containing
            -- the previous group's ignore. Never let Undo resurrect it later.
            undoRecord = nil
            if D.Presets then D.Presets.ResetTeam() elseif D.Roles then D.Roles.ResetTeam() end
            if hadRules or hadUndo then
                Clear(xinDB.teamRules)
                D.dirty, rulesDirty = true, true
                if D.OnChanged then D.OnChanged(true) end
            end
            xinDB.teamContext.hadGroup = false; awaySince = nil
        end
    end
end
local function NotifyChange(force)
    if D.OnChanged then
        D.metrics.notifications = D.metrics.notifications + 1
        D.OnChanged(force)
    end
end

function D.Init()
    if type(xinDB) ~= "table" then xinDB = {} end
    if initializedDB == xinDB and D.ready then EnsureTeamOwner(true); return end
    local defaults = { maxInRange = 6, maxOutRange = 3, listsVisible = true, locked = true,
        width = 290, height = 0, rowHeight = 34, followPfUI = true, backgroundAlpha = .75,
        borderAlpha = .85, fontSize = 12, rightClickDispel = false }
    for key, value in pairs(defaults) do if xinDB[key] == nil then xinDB[key] = value end end
    if type(xinDB.PriorityList) ~= "table" then xinDB.PriorityList = type(PriorityList) == "table" and PriorityList or {} end
    if type(xinDB.BlackList) ~= "table" then xinDB.BlackList = type(BlackList) == "table" and BlackList or {} end
    if type(xinDB.teamRules) ~= "table" then xinDB.teamRules = {} end
    if type(xinDB.teamContext) ~= "table" then xinDB.teamContext = {} end
    if type(xinDB.IgnoreList) ~= "table" then xinDB.IgnoreList = { ["冰柱"] = 1 } end
    if type(xinDB.RaidSettings) ~= "table" then xinDB.RaidSettings = {} end
    PriorityList, BlackList = xinDB.PriorityList, xinDB.BlackList
    D.teamOwnerReady = false
    EnsureTeamOwner(true)
    initializedDB, D.ready, D.dirty, D.spellsDirty, rulesDirty = xinDB, true, true, true, true
    settleUntil, awaySince = Clock() + 4, nil
    D.RefreshSpells()
    if D.Roles then D.Roles.SetVisible(xinDB.listsVisible ~= false) end
    if D.OnReady then D.OnReady() end
    if D.OnVisibility then D.OnVisibility(xinDB.listsVisible ~= false) end
end
function D.MarkDirty()
    D.dirty, rulesDirty = true, true
    if D.ready and not D.updating then
        if xinDB.listsVisible ~= false then D.Update(true) else NotifyChange(true) end
    end
end
function D.SetListsVisible(visible)
    if type(xinDB) ~= "table" then xinDB = {} end
    xinDB.listsVisible = visible and true or false
    if D.Roles then D.Roles.SetVisible(xinDB.listsVisible) end
    if D.OnVisibility then D.OnVisibility(xinDB.listsVisible) end
    if D.ready and xinDB.listsVisible then D.Update(true) end
end
function D.ToggleLists() D.SetListsVisible(not (xinDB and xinDB.listsVisible ~= false)) end

function D.Update(force)
    if not D.ready or D.updating then return end
    TeamState()
    if xinDB.listsVisible == false then return end
    D.updating = true
    -- Pet resurrection need not change the player's spell book. Detect it
    -- cheaply so losing the pet cannot leave its cleansing spell cached away.
    if D.playerClass == "WARLOCK" then
        local petReady = Truth(UnitExists("pet")) and not Truth(UnitIsDeadOrGhost("pet"))
        if petReady ~= D.petReady then D.spellsDirty = true end
    end
    if D.spellsDirty then D.RefreshSpells(); force = true end
    if rulesDirty then RebuildRuleFlags() end
    D.metrics.scanCycles = D.metrics.scanCycles + 1
    local changed = force or D.dirty
    local inCount, outCount = 0, 0
    if next(D.spells) then
        RebuildRoster()
        local n = 0
        for _, item in ipairs(roster) do
            if item.eligible and item.state ~= "ignore" then n = n + 1; ordered[n] = item end
        end
        TrimArray(ordered, n)
        table.sort(ordered, function(a, b)
            if a.rank ~= b.rank then return a.rank < b.rank end
            return (a.order or 0) < (b.order or 0)
        end)
        for _, item in ipairs(ordered) do
            local entry = entryPool[item.unit]
            if not entry then entry = { debuff = {} }; entryPool[item.unit] = entry end
            local aura = entry.debuff
            local oldIndex, oldTexture, oldStacks, oldType, oldAuraName = aura.index, aura.texture, aura.stacks, aura.type, aura.name
            local oldSpellName = aura.spell and aura.spell.name
            local found = D.FindDebuff(item.unit, aura)
            if found then
                local available, reason = D.Availability(item.unit, aura.spell)
                if entry.name ~= item.name or entry.key ~= item.key or entry.class ~= item.class
                    or entry.available ~= available or entry.reason ~= reason or entry.policy ~= item.state
                    or oldIndex ~= aura.index or oldTexture ~= aura.texture or oldStacks ~= aura.stacks
                    or oldType ~= aura.type or oldAuraName ~= aura.name or oldSpellName ~= aura.spell.name then changed = true end
                entry.unit, entry.name, entry.class, entry.key = item.unit, item.name, item.class, item.key
                entry.available, entry.reason, entry.policy, entry.scope = available, reason, item.state, item.scope
                if available then
                    inCount = inCount + 1
                    if D.entries.ready[inCount] ~= entry then changed = true end
                    D.entries.ready[inCount] = entry
                else
                    outCount = outCount + 1
                    if D.entries.blocked[outCount] ~= entry then changed = true end
                    D.entries.blocked[outCount] = entry
                end
            end
        end
    end
    if table.getn(D.entries.ready) ~= inCount or table.getn(D.entries.blocked) ~= outCount then changed = true end
    TrimArray(D.entries.ready, inCount); TrimArray(D.entries.blocked, outCount)
    D.dirty, D.updating = false, false
    if changed then revision = revision + 1; D.revision = revision; NotifyChange(force) end
end
UpdateXinList = function() D.Update(true) end

local function PolicyChanged() D.MarkDirty() end
function D.SetPolicy(name, state, scope)
    if not D.ready then D.Init() end
    name = CleanName(name)
    if not name then return false, "请输入有效的角色名字" end
    if state ~= "normal" and state ~= "priority" and state ~= "ignore" then return false, "未知名单规则" end
    scope = scope or "team"
    if scope ~= "team" and scope ~= "longterm" then return false, "未知作用范围" end
    if scope == "team" and not EnsureTeamOwner(false) then return false, "角色或服务器信息尚未就绪，请稍后再试" end
    if state == "priority" then
        local existing = D.GetManualPolicy(name)
        if existing == "ignore" then return false, "请先在忽略名单恢复此人，再设为优先" end
    end
    undoRecord = { kind = "policy", name = name, team = xinDB.teamRules[name], priority = PriorityList[name], ignored = BlackList[name] }
    if scope == "team" then xinDB.teamRules[name] = state ~= "normal" and state or nil
    else PriorityList[name] = state == "priority" and true or nil; BlackList[name] = state == "ignore" and true or nil end
    PolicyChanged()
    return true
end
function D.ClearPolicy(name, scope) return D.SetPolicy(name, "normal", scope) end
function D.ListPolicies(kind)
    if not D.ready then D.Init() end
    RebuildRoster()
    local list = {}
    for name, state in pairs(xinDB.teamRules) do
        if D.teamOwnerReady and (state == "priority" or state == "ignore") and (not kind or kind == state) then
            table.insert(list, { name = name, state = state, scope = "team", current = rosterNames[name] ~= nil })
        end
    end
    for name, enabled in pairs(PriorityList) do
        if enabled and (not kind or kind == "priority") then table.insert(list, { name = name, state = "priority", scope = "longterm", current = rosterNames[name] ~= nil }) end
    end
    for name, enabled in pairs(BlackList) do
        if enabled and (not kind or kind == "ignore") then table.insert(list, { name = name, state = "ignore", scope = "longterm", current = rosterNames[name] ~= nil }) end
    end
    if D.Presets then
        for _, member in ipairs(roster) do
            local state, scope = D.GetPolicy(member.name)
            if scope == "preset" and (not kind or kind == state) then
                table.insert(list, { name = member.name, state = state, scope = scope, current = true })
            end
        end
    end
    table.sort(list, function(a, b) if a.name ~= b.name then return a.name < b.name end; return a.scope < b.scope end)
    return list
end
function D.RecordUndo(kind, value) undoRecord = { kind = kind, value = value } end
function D.InvalidateUndo() undoRecord = nil end
function D.Undo()
    if not undoRecord then return false, "没有可以撤销的操作" end
    local saved = undoRecord; undoRecord = nil
    if saved.kind == "policy" then
        xinDB.teamRules[saved.name] = saved.team
        PriorityList[saved.name], BlackList[saved.name] = saved.priority, saved.ignored
    elseif saved.kind == "rule" then xinDB.IgnoreList[saved.name] = saved.level
    elseif saved.kind == "preset" and D.Presets then D.Presets.Restore(saved.value)
    elseif saved.kind == "role" and D.Roles then D.Roles.RestoreManual(saved.value.name, saved.value.role) end
    PolicyChanged()
    return true
end
function D.CanUndo() return undoRecord ~= nil end
function D.SetIgnoreRule(name, level)
    if not D.ready then D.Init() end
    name = CleanName(name)
    if not name then return false, "请输入有效的减益名称" end
    if level ~= 0 and level ~= 1 and level ~= 2 then return false, "未知减益规则" end
    undoRecord = { kind = "rule", name = name, level = xinDB.IgnoreList[name] }
    xinDB.IgnoreList[name] = level ~= 0 and level or nil
    PolicyChanged()
    return true
end
function D.GetIgnoreRules()
    if not D.ready then D.Init() end
    local list = {}
    for name, level in pairs(xinDB.IgnoreList) do table.insert(list, { name = name, level = level, source = "custom" }) end
    for name, rule in pairs(xinDB.RaidSettings) do
        if type(rule) == "table" and (rule.ignoreType or (rule.ignoreClasses and next(rule.ignoreClasses))) then
            table.insert(list, { name = name, level = rule.ignoreType or 0, source = "raid", classes = rule.ignoreClasses })
        end
    end
    table.sort(list, function(a, b) if a.name ~= b.name then return a.name < b.name end; return a.source < b.source end)
    return list
end

function D.Cast(entry)
    if not entry or not entry.debuff then return false, "目标已更新" end
    local unit, name, key = entry.unit, entry.name, entry.key
    local expectedName, expectedType = entry.debuff.name, entry.debuff.type
    if not unit or UnitName(unit) ~= name or (key and Identity(unit, name) ~= key)
        or not UnitExists(unit) or not Truth(UnitIsConnected(unit)) or Truth(UnitIsDeadOrGhost(unit))
        or not Truth(UnitIsFriend("player", unit)) or Truth(UnitCanAttack("player", unit)) then return false, "目标已更新" end
    if D.Presets and D.Presets.GetConfig().ignore == "outsideGroup" then RebuildRoster() end
    if D.GetPolicy(name) == "ignore" then return false, "此目标已忽略" end
    D.RefreshSpells(); RebuildRuleFlags()
    local aura = D.FindDebuff(unit, castAura)
    if not aura or aura.name ~= expectedName or aura.type ~= expectedType then return false, "减益已变化" end
    local available, reason = D.Availability(unit, aura.spell)
    if not available then return false, reason end
    if SpellIsTargeting and Truth(SpellIsTargeting()) then return false, "请先完成或取消当前的选取目标操作" end
    if SUPERWOW_VERSION then CastSpellByName(aura.spell.name, unit)
    else
        local hadTarget, sameTarget = UnitExists("target"), UnitIsUnit("target", unit)
        if not sameTarget then TargetUnit(unit) end
        CastSpell(aura.spell.slot, aura.spell.book, false)
        if SpellIsTargeting and Truth(SpellIsTargeting()) then
            SpellTargetUnit(unit)
            if Truth(SpellIsTargeting()) then SpellStopTargeting() end
        end
        if not sameTarget then if hadTarget then TargetLastTarget() else ClearTarget() end end
    end
    return true
end
function D.GetMetrics() return D.metrics end
function D.Status()
    if not D.ready then D.Init() end
    D.RefreshSpells()
    local found = {}
    for _, dispelType in ipairs(typeOrder) do
        if D.spells[dispelType] then table.insert(found, D.Types[dispelType].name .. "=" .. D.spells[dispelType].name) end
    end
    D.Notify(table.getn(found) > 0 and table.concat(found, "，") or "当前角色/宠物没有已学习的友方驱散技能")
    D.Notify("UnitXP=" .. (type(UnitXP) == "function" and "接口存在" or "未加载") ..
        "；定向施法=" .. (SUPERWOW_VERSION and "SuperWoW" or "选中后还原") ..
        "；扫描=" .. D.metrics.scanCycles .. "；减益读名=" .. D.metrics.tooltipReads)
end

for _, eventName in ipairs({ "VARIABLES_LOADED", "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED",
    "LEARNED_SPELL_IN_TAB", "UNIT_PET", "PET_BAR_UPDATE", "PARTY_MEMBERS_CHANGED", "RAID_ROSTER_UPDATE" }) do driver:RegisterEvent(eventName) end
driver:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD" then
        D.Init()
        if event == "PLAYER_ENTERING_WORLD" then settleUntil, awaySince = Clock() + 4, nil end
    elseif event == "SPELLS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" or event == "UNIT_PET" or event == "PET_BAR_UPDATE" then D.spellsDirty, D.dirty = true, true
    else D.dirty = true; TeamState() end
end)
driver:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed >= .25 then
        elapsed = 0
        if D.ready then
            D.Update(false)
        end
    end
end)
