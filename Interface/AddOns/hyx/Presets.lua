-- PureDispel presets, maintained by StoneChyi & Codex.
-- Original hyx authorship and applicable licenses retained.
-- Dynamic rules never write a roster snapshot into the personal name lists.
local D = XinDispel
local P = { members = {}, roster = {}, ignored = {}, revision = 0 }
D.Presets = P
local mana = { MAGE=true, PRIEST=true, WARLOCK=true, HUNTER=true, PALADIN=true, SHAMAN=true, DRUID=true }
local caster = { MAGE=true, WARLOCK=true }
local roleNames = { TANK="坦克", HEALER="治疗", MELEE="近战", RANGED="远程", UNKNOWN="未知" }
local roleKeys = { TANK="tank", HEALER="healer", MELEE="melee", RANGED="ranged", UNKNOWN="unknown" }
P.Options = {
    priority = {
        { key="none", label="不使用优先预设", hint="保留手工优先和队伍原顺序" },
        { key="smart", label="智能团队", hint="坦克优先，其次治疗，最后其他队员" },
        { key="tanks", label="坦克优先", hint="按统一职责识别结果匹配坦克" },
        { key="healers", label="治疗优先", hint="按统一职责识别结果匹配治疗" },
        { key="mana", label="有蓝职业优先", hint="按法力职业匹配，变形中的德鲁伊也包括在内" },
        { key="melee", label="近战优先", hint="近战职责优先，坦克也归入近战组" },
        { key="ranged", label="远程输出优先", hint="远程输出优先，不包括治疗" },
        { key="casters", label="法系输出优先", hint="法师、术士及已识别的施法输出，不包括猎人" },
        { key="ownGroup", label="本小队优先", hint="团队中先处理自己所在的小队" }
    },
    ignore = {
        { key="none", label="不使用忽略预设", hint="只按原有手工忽略和减益规则过滤" },
        { key="outsideGroup", label="只负责本小队", hint="过滤其他小队；小队信息未知者保留" },
        { key="nonMana", label="忽略无蓝职业", hint="过滤战士和盗贼；手工优先者作为例外" },
        { key="melee", label="忽略近战输出", hint="只过滤已确认的近战输出，坦克和未知者保留" },
        { key="ranged", label="忽略远程输出", hint="只过滤已确认的远程输出，未知者保留" },
        { key="damage", label="只负责坦克和治疗", hint="过滤已确认的近战及远程输出，未知者保留" }
    }
}
local optionMap = { priority = {}, ignore = {} }
for kind, list in pairs(P.Options) do for _, item in ipairs(list) do optionMap[kind][item.key] = item end end
local fallback = { priority="none", ignore="none", selfFirst=true }
local function Copy(config) return { priority=config.priority, ignore=config.ignore, selfFirst=config.selfFirst } end
function P.GetConfig()
    if not D.teamOwnerReady or type(xinDB) ~= "table" or not xinDB.teamOwner then return fallback end
    if type(xinDB.presetProfiles) ~= "table" then xinDB.presetProfiles = {} end
    local config = xinDB.presetProfiles[xinDB.teamOwner]
    if type(config) ~= "table" then config = Copy(fallback); xinDB.presetProfiles[xinDB.teamOwner] = config end
    if not optionMap.priority[config.priority] then config.priority = "none" end
    if not optionMap.ignore[config.ignore] then config.ignore = "none" end
    if type(config.selfFirst) ~= "boolean" then config.selfFirst = true end
    return config
end
function P.NeedsRoles()
    local config = P.GetConfig()
    return (config.priority ~= "none" and config.priority ~= "mana" and config.priority ~= "ownGroup")
        or config.ignore == "melee" or config.ignore == "ranged" or config.ignore == "damage"
end
local function SyncRoles()
    if D.Roles then
        D.Roles.SetEnabled(P.NeedsRoles())
        D.Roles.SetVisible(not xinDB or xinDB.listsVisible ~= false)
    end
end
function P.Restore(config)
    if not D.teamOwnerReady then return end
    local current = P.GetConfig()
    current.priority, current.ignore, current.selfFirst = config.priority, config.ignore, config.selfFirst
    SyncRoles()
end
function P.Set(key, value)
    if not D.ready then D.Init() end
    if not D.teamOwnerReady then return false, "角色或服务器信息尚未就绪，请稍后再试" end
    if key == "selfFirst" then
        if type(value) ~= "boolean" then return false, "未知预设选项" end
    elseif not optionMap[key] or not optionMap[key][value] then return false, "未知预设选项" end
    local current = P.GetConfig()
    if current[key] == value then return true end
    D.RecordUndo("preset", Copy(current))
    current[key] = value
    SyncRoles(); D.GetRoster(); D.MarkDirty()
    return true
end
function P.Reset()
    if not D.ready then D.Init() end
    if not D.teamOwnerReady then return false, "角色或服务器信息尚未就绪，请稍后再试" end
    local current = P.GetConfig()
    D.RecordUndo("preset", Copy(current))
    P.Restore(fallback); D.GetRoster(); D.MarkDirty()
    return true
end
function P.ResetTeam()
    -- Priority templates belong to the character; restrictive assignments are
    -- only for this group and must not silently exclude the next group's members.
    local profiles = xinDB and xinDB.presetProfiles
    local previous = profiles and profiles[xinDB.teamOwner]
    if previous then previous.ignore = "none" end
    for key in pairs(P.members) do P.members[key] = nil end
    for key in pairs(P.ignored) do P.ignored[key] = nil end
    P.roster = {}
    if P.summary then
        P.summary.priorityCount, P.summary.ignoredCount = 0, 0
        for key in pairs(P.summary.roles) do P.summary.roles[key] = 0 end
    end
    if D.Roles then D.Roles.ResetTeam() end
end
local function Role(member)
    if D.Roles then
        if D.Roles.Peek then return D.Roles.Peek(member.name, member.key, member.class) end
        return D.Roles.Get(member.name)
    end
end
local function Kind(info)
    if not info then return "UNKNOWN" end
    if info.role == "DAMAGER" then return info.style or "UNKNOWN" end
    return info.role or "UNKNOWN"
end
local function PriorityGroup(member, config, role)
    local key, kind = config.priority, Kind(role)
    if key == "smart" then return kind == "TANK" and 0 or kind == "HEALER" and 1 or 2 end
    local match = key == "tanks" and kind == "TANK" or key == "healers" and kind == "HEALER"
        or key == "mana" and mana[member.class]
        or key == "melee" and (kind == "MELEE" or kind == "TANK")
        or key == "ranged" and kind == "RANGED"
        or key == "casters" and (caster[member.class] or (kind == "RANGED" and member.class ~= "HUNTER"))
        or key == "ownGroup" and P.ownGroup and member.subgroup == P.ownGroup
    return match and 0 or 2
end
local function AutoIgnored(member, config, role)
    if config.ignore == "outsideGroup" then return P.ownGroup and member.subgroup and member.subgroup ~= P.ownGroup end
    if config.ignore == "nonMana" then return member.class == "WARRIOR" or member.class == "ROGUE" end
    if not role or role.confidence ~= "high" or role.provisional then return false end
    return config.ignore == "melee" and Kind(role) == "MELEE"
        or config.ignore == "ranged" and Kind(role) == "RANGED"
        or config.ignore == "damage" and (Kind(role) == "MELEE" or Kind(role) == "RANGED")
end
function P.GetPolicy(name)
    local state, scope = D.GetManualPolicy(name)
    if state ~= "normal" then return state, scope end
    local member = P.members[name]
    if not member then return "normal", "none" end
    local config, role = P.GetConfig(), Role(member)
    if AutoIgnored(member, config, role) then return "ignore", "preset" end
    if config.priority ~= "none" and PriorityGroup(member, config, role) < 2 then return "priority", "preset" end
    return "normal", "none"
end
function P.UpdateRoster(roster)
    local config = P.GetConfig()
    SyncRoles()
    for name in pairs(P.members) do P.members[name] = nil end
    for name in pairs(P.ignored) do P.ignored[name] = nil end
    P.roster, P.ownGroup = roster, nil
    local groups = config.priority == "ownGroup" or config.ignore == "outsideGroup"
    for i, member in ipairs(roster) do
        member.order, member.subgroup = i, nil
        if groups then
            if GetNumRaidMembers() > 0 then
                local index = tonumber(string.sub(member.unit, 5))
                if index and GetRaidRosterInfo then
                    local _, _, group = GetRaidRosterInfo(index)
                    member.subgroup = group
                end
            else member.subgroup = 1 end
            if member.self then P.ownGroup = member.subgroup end
        end
        P.members[member.name] = member
    end
    if D.Roles then D.Roles.UpdateRoster(roster) end
    local summary = P.summary
    if not summary then
        summary = { roles={} }; P.summary = summary
    end
    summary.priorityCount, summary.ignoredCount = 0, 0
    for _, key in pairs(roleKeys) do summary.roles[key] = 0 end
    for _, member in ipairs(roster) do
        local manual = D.GetManualPolicy(member.name)
        local role = Role(member)
        member.state, member.scope = P.GetPolicy(member.name)
        if member.state == "ignore" then P.ignored[member.name] = true end
        if member.scope == "preset" then
            if member.state == "priority" then summary.priorityCount = summary.priorityCount + 1
            elseif member.state == "ignore" then summary.ignoredCount = summary.ignoredCount + 1 end
        end
        local key = roleKeys[Kind(role)] or "unknown"
        summary.roles[key] = summary.roles[key] + 1
        member.rank = config.selfFirst and member.self and 0 or manual == "priority" and 1
            or 2 + PriorityGroup(member, config, role)
    end
end
function P.GetReason(name)
    local state, scope = P.GetPolicy(name)
    if scope == "preset" then
        local config = P.GetConfig()
        local option = state == "ignore" and optionMap.ignore[config.ignore] or optionMap.priority[config.priority]
        return (state == "ignore" and "忽略预设：" or "优先预设：") .. option.label
    elseif state ~= "normal" then
        return (scope == "team" and "本队手工" or "长期手工") .. (state == "ignore" and "忽略" or "优先")
    end
    return ""
end
function P.GetSummary()
    local config = P.GetConfig()
    if not P.summary then
        P.summary = { priorityCount=0, ignoredCount=0, roles={tank=0,healer=0,melee=0,ranged=0,unknown=0} }
    end
    P.summary.priorityLabel, P.summary.ignoreLabel = optionMap.priority[config.priority].label, optionMap.ignore[config.ignore].label
    return P.summary
end
-- Keep all user operations in the engine's one-step undo chain. Automatic
-- inference, query replies and roster changes never replace that history.
if D.Roles then
    local original = D.Roles.SetManual
    D.Roles.SetManual = function(name, role)
        local ok, reason, previous = original(name, role)
        if ok then
            D.RecordUndo("role", { name=name, role=previous })
            D.MarkDirty()
        end
        return ok, reason, previous
    end
end
