-- ============================================================
-- 文件名: GoubayuHeal_Dispel.lua
-- 功能: 一键驱散模块
--       支持 Nampower / UnitXP，并提供非Nampower/UnitXP环境回退
--       包含职业驱散技能表、debuff扫描、驱散窗口UI、优先级管理等
-- ============================================================

local classFile = select(2, UnitClass("player"))
local bookType = BOOKTYPE_SPELL
if classFile == "WARLOCK" then
    bookType = BOOKTYPE_PET
end
local DispelHasUnitXP = pcall(UnitXP, "nop", "nop")

-- ============================================================
-- 职业驱散技能表
-- ============================================================

local dispelSpells = GoubayuHeal.DispelSpells

-- ============================================================
-- 驱散类型定义（显示名/颜色/短名）
-- ============================================================

local dispelTypeOrder = { "Magic", "Disease", "Poison", "Curse", "Snare" }

local dispelTypeShort = GoubayuHeal.DispelTypeShort

local dispelTypeColors = {
    Magic = { 0.2, 0.6, 1.0 },
    Disease = { 0.6, 0.4, 0.0 },
    Poison = { 0.0, 0.6, 0.0 },
    Curse = { 0.6, 0.0, 1.0 },
    Snare = { 0.8, 0.0, 0.0 },
}

-- 本地化类型名 → 键
local typeKeyMap = {
    [GoubayuHeal.DispelTypeShort.Magic] = "Magic",
    [GoubayuHeal.DispelTypeShort.Disease] = "Disease",
    [GoubayuHeal.DispelTypeShort.Poison] = "Poison",
    [GoubayuHeal.DispelTypeShort.Curse] = "Curse",
    [GoubayuHeal.DispelTypeShort.Snare] = "Snare",
    ["Magic"] = "Magic",
    ["Disease"] = "Disease",
    ["Poison"] = "Poison",
    ["Curse"] = "Curse",
    ["Snare"] = "Snare",
}

-- ============================================================
-- 默认防误驱散减益
-- ============================================================

local dispelDefaultDebuffs = GoubayuHeal.DispelDefaultDebuffs

function GoubayuHeal.Dispel_DefaultList()
    local t = {}
    for _, n in ipairs(dispelDefaultDebuffs) do
        t[n] = true
    end
    return t
end

-- 移动限制名单默认集（名字 + spell ID 合并为一个集合；ID 以字符串作键，判定时按数字比较）
-- by 武藤纯子酱 2026.10.13
function GoubayuHeal.Dispel_MovementDefaults()
    local t = {}
    for _, n in ipairs(GoubayuHeal.DispelMovementNames or {}) do
        t[n] = true
    end
    for _, id in ipairs(GoubayuHeal.DispelMovementIds or {}) do
        t[tostring(id)] = true
    end
    return t
end

-- ============================================================
-- 隐藏减益默认
-- ============================================================

local dispelFilterDebuffs = GoubayuHeal.DispelFilterDebuffs

function GoubayuHeal.Dispel_FilterDebuffDefaults()
    local t = {}
    for _, n in ipairs(dispelFilterDebuffs) do
        t[n] = true
    end
    return t
end

function GoubayuHeal.Dispel_CountKeys(t)
    local n = 0
    if type(t) == "table" then
        for _ in pairs(t) do
            n = n + 1
        end
    end
    return n
end

-- ============================================================
-- 职业列表与默认隐藏清单
-- ============================================================

local dispelClassList = {
    "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST",
    "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR"
}
GoubayuHeal.DispelClassList = dispelClassList

local dispelClassNames = GoubayuHeal.ClassDisplayName

function GoubayuHeal.Dispel_ClassName(cf)
    return dispelClassNames[cf] or cf
end

-- 职业总开关查询：nil/1 = 开，0 = 关（该职业整队不被驱散）
function GoubayuHeal.Dispel_ClassEnabled(cf)
    if not cf then
        return true
    end
    local C = GoubayuHeal.Config
    local m = C and C["dispel_class_enabled"]
    return not (m and m[cf] == 0)
end

-- 职业总开关设置
function GoubayuHeal.Dispel_SetClassEnabled(cf, on)
    if not cf or not GoubayuHeal.Config then
        return
    end
    GoubayuHeal.Config["dispel_class_enabled"] = GoubayuHeal.Config["dispel_class_enabled"] or {}
    GoubayuHeal.Config["dispel_class_enabled"][cf] = (on and 1) or 0
end

-- 职业隐藏默认（按职业隐藏精确的减益名称）
local dispelClassFilterDefaults = GoubayuHeal.DispelClassFilter

function GoubayuHeal.Dispel_ClassFilterDefaults(cf)
    local list = dispelClassFilterDefaults[cf]
    if not list then
        return {}
    end
    local t = {}
    for _, n in ipairs(list) do
        t[n] = true
    end
    return t
end

-- 某清单的重置默认
function GoubayuHeal.Dispel_DefaultFor(key, selectedClass)
    if key == "dispel_blacklist" then
        return GoubayuHeal.Dispel_DefaultList()
    elseif key == "dispel_movement" then
        return GoubayuHeal.Dispel_MovementDefaults()
    elseif key == "dispel_filter_debuffs" then
        return GoubayuHeal.Dispel_FilterDebuffDefaults()
    elseif key == "dispel_filter_class" then
        -- 兜底也要用"职业 token"：GoubayuHeal.my_class 是本地化职业名，不能当配置键
        -- by 武藤纯子酱 2026.9.21
        local cf = selectedClass or (UnitClass and select(2, UnitClass("player"))) or "PRIEST"
        return GoubayuHeal.Dispel_ClassFilterDefaults(cf)
    end
    return {}
end

-- ============================================================
-- 优先级列表管理
-- ============================================================

local DispelPrio = {}
local DispelSkipNames = {}
-- 已处理过的单位集合（含优先级0跳过的）：供"队友存在但不在候选表"的自愈检测用
local DispelPrioSet = {}
-- 自愈检测节流（1秒一次）
local DispelRosterCheckAt = 0

function GoubayuHeal.Dispel_BuildPrio()
    DispelPrio = {}
    DispelSkipNames = {}
    DispelPrioSet = {}

    local prioMap = {}
    if GoubayuHeal.Config and GoubayuHeal.Config["dispel_player_priority"] then
        for name, v in pairs(GoubayuHeal.Config["dispel_player_priority"]) do
            prioMap[name] = tonumber(v) or 4
        end
    end

    local units = {}

    local function addUnit(unit)
        -- 只扫描友方单位（自己/小队/团队/宠物）：敌对目标不进入驱散扫描，
        -- 避免把敌人身上的不可驱散/异类减益（爆炸陷阱/冲击波/钉刺等）误判为可驱散
        if not UnitExists(unit) or UnitCanAttack("player", unit) then
            return
        end
        local name = UnitName(unit)
        -- 注意：名字为空（首登名单事件早于名字同步）时不标记已处理，
        -- 留给 Dispel_Scan 的自愈检测稍后重建
        if name and name ~= "" then
            DispelPrioSet[unit] = true
            local p = prioMap[name]
            if p == nil then
                p = 4
            end
            if p < 0 then
                p = 0
            end
            if p > 8 then
                p = 8
            end

            if p == 0 then
                DispelSkipNames[name] = true
            else
                units[table.getn(units) + 1] = { unit = unit, prio = p, idx = table.getn(units) + 1 }
            end
        end
    end

    addUnit("player")

    for i = 1, 4 do
        addUnit("party" .. i)
    end
    for i = 1, 40 do
        addUnit("raid" .. i)
    end

    if GoubayuHeal.Config and GoubayuHeal.Config["dispel_pets"] == 1 then
        for i = 1, 40 do
            addUnit("raidpet" .. i)
        end
        for i = 1, 4 do
            addUnit("partypet" .. i)
        end
        addUnit("pet")
    end

    -- 稳定排序：优先级降序，同优先级保持默认顺序
    table.sort(units, function(a, b)
        if a.prio ~= b.prio then
            return a.prio > b.prio
        end
        return a.idx < b.idx
    end)

    for _, u in ipairs(units) do
        table.insert(DispelPrio, u.unit)
    end
end

GoubayuHeal.Dispel_BuildPrio()

-- ============================================================
-- 可用驱散法术（已学习）
-- ============================================================

local DispelUsable = {}

function GoubayuHeal.Dispel_UpdateUsable()
    DispelUsable = {}

    if (not classFile or not dispelSpells[classFile]) and UnitClass and UnitClass("player") then
        classFile = select(2, UnitClass("player"))
    end

    local classSpells = dispelSpells[classFile]
    if not classSpells then
        return
    end

    local allSpells = {}
    local tabs = GetNumSpellTabs()

    for tab = 1, tabs do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for slot = offset + 1, offset + numSpells do
            local sname = GetSpellName(slot, bookType)
            if sname then
                allSpells[sname] = slot
            end
        end
    end

    for dtype, spellNames in pairs(classSpells) do
        for _, sname in ipairs(spellNames) do
            if allSpells[sname] then
                DispelUsable[dtype] = { name = sname, slot = allSpells[sname] }
                break
            end
        end
    end
end

-- 该类型职业是否支持（不依赖是否已学）
function GoubayuHeal.Dispel_ClassCanDispelType(dtype)
    return (dispelSpells[classFile] and dispelSpells[classFile][dtype]) ~= nil
end

-- ============================================================
-- 配置默认值
-- ============================================================

-- 增量默认屏蔽：把"新增批次"（DispelDefaultDebuffsMerge）补进指定黑名单（只增不删）。
-- holder/holderKey 记录该黑名单已合并到的批次版本，按版本只执行一次。
-- 注意：dispel_blacklist 属于 per_scheme_keys，方案各自保存独立黑名单副本；必须对每个方案的
-- 副本分别用其自身的版本标记合并，否则方案加载时会把已合并的条目整体覆盖回旧副本
-- （表现为"黑名单里有、实际不生效"） by 武藤纯子酱 2026.9.21
function GoubayuHeal.Dispel_MergeNewDefaults(blacklist, holder, holderKey)
    if type(blacklist) ~= "table" then
        return
    end
    local mergeDef = GoubayuHeal.DispelDefaultDebuffsMerge
    if type(mergeDef) ~= "table" or type(mergeDef.Debuffs) ~= "table" then
        return
    end

    local tgt = tonumber(mergeDef.Version) or 0
    local cur = 0
    if holder and holderKey then
        cur = tonumber(holder[holderKey]) or 0
    end
    if cur >= tgt then
        return
    end

    for _, dn in ipairs(mergeDef.Debuffs) do
        if dn and dn ~= "" and not blacklist[dn] then
            blacklist[dn] = true
        end
    end

    if holder and holderKey then
        holder[holderKey] = tgt
    end
end

function GoubayuHeal.Dispel_SetupDefaults()
    local C = GoubayuHeal.Config

    C["dispel_enabled"] = C["dispel_enabled"] or 0
    C["dispel_queue"] = C["dispel_queue"] or 0
    C["dispel_interrupt"] = C["dispel_interrupt"] or 0
    C["dispel_hidden"] = C["dispel_hidden"] or 0
    C["dispel_priority"] = C["dispel_priority"] or 0.5
    C["dispel_filters"] = C["dispel_filters"] or {}

    -- 修复旧版本BUG：dispel_filters 可能被覆盖成数字
    if type(C["dispel_filters"]) ~= "table" then
        C["dispel_filters"] = {}
    end

    local DF = C["dispel_filters"]
    for _, t in ipairs(dispelTypeOrder) do
        if DF[t] == nil then
            DF[t] = (dispelSpells[classFile] and dispelSpells[classFile][t]) and 1 or 0
        end
    end

    -- 默认屏幕正中：保存的是窗口中心点的屏幕绝对坐标（拖动结束时 GetCenter 写回）
    C["dispel_window_pos"] = C["dispel_window_pos"] or {
        x = (UIParent:GetWidth() or 1024) / 2,
        y = (UIParent:GetHeight() or 768) / 2
    }
    C["dispel_window_scale"] = C["dispel_window_scale"] or 0.85

    C["dispel_scale"] = C["dispel_scale"] or 0.85
    C["dispel_opacity"] = C["dispel_opacity"] or 1.0
    C["dispel_print"] = C["dispel_print"] == nil and 1 or C["dispel_print"]
    C["dispel_lock"] = C["dispel_lock"] or 0
    C["dispel_backdrop"] = C["dispel_backdrop"] == nil and 1 or C["dispel_backdrop"]
    C["dispel_show_header"] = C["dispel_show_header"] == nil and 1 or C["dispel_show_header"]
    C["dispel_flip"] = C["dispel_flip"] or 0
    C["dispel_buttons"] = C["dispel_buttons"] or 5
    C["dispel_pets"] = C["dispel_pets"] or 0
    C["dispel_ignore_abolish"] = C["dispel_ignore_abolish"] == nil and 1 or C["dispel_ignore_abolish"]
    -- 保护式跳过：同目标同类型存在受保护减益（黑名单/过滤/职业过滤/专用开关任一命中）时，
    -- 该类型整批不驱散（避免群体驱散连带解掉受保护项）。默认开。by 武藤纯子酱 2026.10.20
    C["dispel_protect_same_type"] = C["dispel_protect_same_type"] == nil and 1 or C["dispel_protect_same_type"]
    C["dispel_shadowform"] = C["dispel_shadowform"] == nil and 1 or C["dispel_shadowform"]
    C["dispel_wyvern_sting"] = C["dispel_wyvern_sting"] or 0
    C["dispel_mutating_injection"] = C["dispel_mutating_injection"] or 0
    C["dispel_blacklist"] = C["dispel_blacklist"] or {}
    C["dispel_movement"] = C["dispel_movement"] or GoubayuHeal.Dispel_MovementDefaults()
    C["dispel_filter_debuffs"] = C["dispel_filter_debuffs"] or {}
    C["dispel_filter_class"] = C["dispel_filter_class"] or {}

    -- 职业总开关：dispel_class_enabled[职业] = 1 开 / 0 关；缺失按开处理（默认全开）
    -- 关闭的职业整队不进入驱散（不受优先级/黑名单/隐藏清单影响） by 武藤纯子酱 2026.9.4
    C["dispel_class_enabled"] = C["dispel_class_enabled"] or {}

    -- 版本<3：重填为新默认
    if (C["dispel_defaults_applied"] ~= 1) or ((C["dispel_defaults_version"] or 0) < 3) then
        C["dispel_blacklist"] = GoubayuHeal.Dispel_DefaultList()
        C["dispel_filter_debuffs"] = GoubayuHeal.Dispel_FilterDebuffDefaults()
        C["dispel_filter_class"] = {}
        for _, cf in ipairs(dispelClassList) do
            C["dispel_filter_class"][cf] = GoubayuHeal.Dispel_ClassFilterDefaults(cf)
        end
        C["dispel_defaults_applied"] = 1
        C["dispel_defaults_version"] = 3
    end

    -- 增量默认屏蔽合并：只补缺失项——不覆盖用户自己添加的条目，也不清除此前批次误加的条目
    -- （避免误删用户手动项）；当前 Config 黑名单用全局版本标记，方案副本各自在方案加载/保存时合并
    -- by 武藤纯子酱 2026.9.21
    if type(C["dispel_blacklist"]) ~= "table" then
        C["dispel_blacklist"] = {}
    end
    GoubayuHeal.Dispel_MergeNewDefaults(C["dispel_blacklist"], C, "dispel_blacklist_merge_version")

    -- 兼容旧版扁平结构
    local fcmap = C["dispel_filter_class"]
    if type(fcmap) == "table" then
        local flat = {}
        for k, v in pairs(fcmap) do
            if v == true then
                flat[k] = true
            end
        end
        if GoubayuHeal.Dispel_CountKeys(flat) > 0 then
            for k in pairs(flat) do
                fcmap[k] = nil
            end
            for _, cf in ipairs(dispelClassList) do
                fcmap[cf] = fcmap[cf] or {}
                for n in pairs(flat) do
                    fcmap[cf][n] = true
                end
            end
        end
    end

    C["dispel_prio"] = C["dispel_prio"] or {}
    C["dispel_skip"] = C["dispel_skip"] or {}
    C["dispel_player_priority"] = C["dispel_player_priority"] or {}

    if C["dispel_prio_migrated"] ~= 1 then
        if type(C["dispel_prio"]) == "table" then
            for _, pname in ipairs(C["dispel_prio"]) do
                if pname and C["dispel_player_priority"][pname] == nil then
                    C["dispel_player_priority"][pname] = 8
                end
            end
        end
        if type(C["dispel_skip"]) == "table" then
            for _, sname in ipairs(C["dispel_skip"]) do
                if sname and C["dispel_player_priority"][sname] == nil then
                    C["dispel_player_priority"][sname] = 0
                end
            end
        end
        C["dispel_prio_migrated"] = 1
    end

    GoubayuHeal.Dispel_BuildPrio()
end

-- ============================================================
-- 单位可驱散性 / 射程
-- ============================================================

function GoubayuHeal.Dispel_CanBeCleansed(unit)
    if unit == "player" or unit == "pet" then
        return true
    end

    if string.find(unit, "^party%d+$") or string.find(unit, "^raid%d+$")
        or string.find(unit, "^partypet%d+$") or string.find(unit, "^raidpet%d+$") then
        return true
    end

    if UnitIsFriend and UnitIsFriend("player", unit) then
        return true
    end

    return false
end

function GoubayuHeal.Dispel_CanCast(unit, dtype)
    if not unit or not UnitExists(unit) then
        return false
    end

    if (unit == "player") or (UnitIsUnit and UnitIsUnit(unit, "player")) then
        return true
    end

    -- 视野判定（范围判定通过后复用）
    local function hasSight()
        if DispelHasUnitXP then
            local ok, inSight = pcall(UnitXP, "inSight", "player", unit)
            if ok and inSight == false then
                return false
            end
            return true
        end
        return UnitIsVisible(unit)
    end

    -- 优先 Nampower IsSpellInRange(spellName, unit)：反映含天赋/装备修正的实际射程，
    -- 与治疗通道 CanCastAtUnit 口径一致（否则驱散会被固定 30 码截断，吃不到"增加驱散距离"天赋）
    -- by 武藤纯子酱 2026.10.13
    if GetNampowerVersion and IsSpellInRange and dtype then
        local sp = DispelUsable and DispelUsable[dtype]
        local sname = sp and sp.name
        if sname then
            local ok, r = pcall(IsSpellInRange, sname, unit)
            if ok and (r == 0 or r == 1) then
                if r == 0 then
                    return false
                end
                return hasSight()
            end
        end
    end

    -- 回退：固定范围（无 Nampower / 无名 / 非单目标法术时）
    local inRange

    if UnitIsFriend("player", unit) and not UnitCanAttack("player", unit) then
        if UnitPosition then
            local myX, myY, myZ = UnitPosition("player")
            local uX, uY, uZ = UnitPosition(unit)
            if myX and uX then
                local dx, dy, dz = uX - myX, uY - myY, uZ - myZ
                inRange = ((dx * dx) + (dy * dy) + (dz * dz)) <= 1089
            elseif DispelHasUnitXP then
                local d = UnitXP("distanceBetween", "player", unit)
                inRange = d ~= nil and d < 30
            else
                inRange = CheckInteractDistance(unit, 4)
            end
        elseif DispelHasUnitXP then
            local d = UnitXP("distanceBetween", "player", unit)
            inRange = d ~= nil and d < 30
        else
            inRange = CheckInteractDistance(unit, 4)
        end
    else
        inRange = CheckInteractDistance(unit, 4)
    end

    if inRange then
        return hasSight()
    end

    return false
end

-- ============================================================
-- debuff 信息获取
-- ============================================================

local DispelScanTooltip = CreateFrame("GameTooltip", "GoubayuHealDispelScanTooltip", nil,
    "GameTooltipTemplate")
DispelScanTooltip:SetOwner(DispelScanTooltip, "ANCHOR_NONE")
-- 离屏扫描框全程透明（alpha=0）：它只用来读取减益数据，任何可见状态都是渲染残留空框
DispelScanTooltip:SetAlpha(0)

-- 移动限制（减速/定身）判定：②名单(名字/ID) → ①DBC泛化 → ③描述关键词(API→tooltip正文)
-- 仅当职业有 Snare 驱散技能（如圣骑自由之手）时才需要调用；命中返回 true。
-- by 武藤纯子酱 2026.10.13
function GoubayuHeal.Dispel_IsMovementDebuff(unit, i, spellId, debuffName)
    if not DispelUsable.Snare then
        return false
    end

    -- ② 名单（最优先）：spellId（以字符串作键）或 debuff 名
    local list = GoubayuHeal.Config and GoubayuHeal.Config["dispel_movement"]
    if list then
        if spellId and list[tostring(spellId)] then
            return true
        end
        if debuffName and debuffName ~= "" and list[debuffName] then
            return true
        end
    end

    if not (GetNampowerVersion and GetSpellRecField and spellId) then
        return false
    end

    -- ① DBC 泛化：effectApplyAuraName 含 33(减速)/26(定身)
    local okA, auraNames = pcall(GetSpellRecField, spellId, "effectApplyAuraName")
    if okA and auraNames then
        if type(auraNames) == "table" then
            for _, a in pairs(auraNames) do
                if a == 33 or a == 26 then
                    return true
                end
            end
        elseif auraNames == 33 or auraNames == 26 then
            return true
        end
    end

    -- ③ 描述关键词：优先 DBC description/tooltip，读不到再扫 debuff tooltip 正文
    local function matchKw(s)
        if not s or s == "" then
            return false
        end
        for _, kw in ipairs(GoubayuHeal.DispelMovementKeywords or {}) do
            if string.find(s, kw, 1, true) then
                return true
            end
        end
        return false
    end

    local okD, desc = pcall(GetSpellRecField, spellId, "description")
    if okD and matchKw(desc) then
        return true
    end
    local okT, tip = pcall(GetSpellRecField, spellId, "tooltip")
    if okT and matchKw(tip) then
        return true
    end

    DispelScanTooltip:ClearLines()
    pcall(function() DispelScanTooltip:SetUnitDebuff(unit, i) end)
    for k = 1, 6 do
        local fs = getglobal("GoubayuHealDispelScanTooltipTextLeft" .. k)
        if fs and matchKw(fs:GetText()) then
            return true
        end
    end

    return false
end

function GoubayuHeal.Dispel_GetDebuffInfo(unit, i)
    -- 类型识别统一用原版 UnitDebuff：其 debuffType 只有可驱散类型（魔法/中毒/疾病/诅咒）才有值，
    -- 不可驱散的返回 nil，天然满足"只有有驱散标记的才能驱散"
    -- （不再使用 Nampower GetUnitField/GetSpellRecField：其"dispel"字段类型判定存在BUG，会把虚弱灵魂/钉刺等误判为中毒）
    local texture, applications, debuffType, spellId = UnitDebuff(unit, i)
    if not texture then
        return nil
    end

    local name
    if spellId and GetSpellNameAndRankForId then
        local ok, nm = pcall(GetSpellNameAndRankForId, spellId)
        if ok and nm then
            name = nm
        end
    end

    if not name or name == "" then
        DispelScanTooltip:ClearLines()
        -- 与主工具库一致 pcall 保护（个别客户端对无效单位/槽位可能报错）
        local okSet = pcall(function() DispelScanTooltip:SetUnitDebuff(unit, i) end)
        local left1 = getglobal("GoubayuHealDispelScanTooltipTextLeft1")
        local right1 = getglobal("GoubayuHealDispelScanTooltipTextRight1")
        if okSet then
            name = left1 and left1:GetText() or ""
            if not debuffType and right1 then
                debuffType = right1:GetText()
            end
        end
    end

    local key = typeKeyMap[debuffType]
    -- 标准类型判不出时，尝试移动限制判定（仅圣骑等有 Snare 技能的职业；其余职业 DispelUsable.Snare 为空直接跳过）
    -- by 武藤纯子酱 2026.10.13
    if not key and GoubayuHeal.Dispel_IsMovementDebuff
        and GoubayuHeal.Dispel_IsMovementDebuff(unit, i, spellId, name) then
        key = "Snare"
    end
    -- 第5返回值 spellId：供驱散按钮 OnEnter 走 SetSpellByID（槽位在扫描间隙可能被顶掉，
    -- 按槽位显示会错位） by 武藤纯子酱 2026.9.4
    return name, key, texture, applications, spellId
end

-- ============================================================
-- 扫描：收集可驱散 debuff
-- ============================================================

local DispelList = {}
-- 扫描时按"强制优先 / 普通"分桶，扫描结束再拼成 DispelList（强制优先在前）
local DispelForceList = {}
local DispelNormalList = {}
-- 强制优先驱散名单集合（代码内维护，见 Locale 的 DispelForcePriority）
local Dispel_ForcePriority_set = {}
for _, n in ipairs(GoubayuHeal.DispelForcePriority or {}) do Dispel_ForcePriority_set[n] = true end

-- 是否有"驱散免疫"类buff（消毒术/祛病术的周期性驱散）
function GoubayuHeal.Dispel_HasAbolish(unit, dtype)
    if not UnitExists(unit) or not (dtype == "Poison" or dtype == "Disease") then
        return false
    end

    local icon = (dtype == "Poison") and "Spell_Nature_NullifyPoison_02"
        or "Spell_Nature_NullifyDisease"

    -- 与主模块一致扫描 32 个光环槽（Nampower 暴露 32 槽，只扫 16 会漏掉高槽位的消毒/祛病）
    for i = 1, 32 do
        local buff = UnitBuff(unit, i)
        if not buff then
            break
        end
        if string.find(buff, icon) then
            return true
        end
    end

    return false
end

function GoubayuHeal.Dispel_HasShadowform()
    for i = 0, 31 do
        local index = GetPlayerBuff(i, "HELPFUL")
        if index > -1 then
            if GetPlayerBuffTexture(index) == "Interface\\Icons\\Spell_Shadow_Shadowform" then
                return true
            end
        end
    end
    return false
end

-- 该单位/该debuff是否应被隐藏
function GoubayuHeal.Dispel_IsHidden(unit, name, dtype, class)
    local C = GoubayuHeal.Config

    -- 职业总开关：被整体关闭的职业永远不驱散（无论优先级/黑名单/隐藏清单如何设置）
    -- by 武藤纯子酱 2026.9.4
    if class and not GoubayuHeal.Dispel_ClassEnabled(class) then
        return true
    end

    local uname = UnitName(unit)
    if uname and DispelSkipNames[uname] then
        return true
    end

    -- 专用开关优先
    if name == GoubayuHeal.Msg.WyvernSting then
        if not C or C["dispel_wyvern_sting"] ~= 1 then
            return true
        end
    elseif name == GoubayuHeal.Msg.MutatingInjection then
        if not C or C["dispel_mutating_injection"] ~= 1 then
            return true
        end
    end

    if C and C["dispel_blacklist"] and C["dispel_blacklist"][name] then
        return true
    end

    if C and C["dispel_filter_debuffs"] and C["dispel_filter_debuffs"][name] then
        return true
    end

    if C and C["dispel_filter_class"] then
        if class and C["dispel_filter_class"][class]
            and type(C["dispel_filter_class"][class]) == "table" then
            local fc = C["dispel_filter_class"][class]
            if fc[name] then
                return true
            end
            if dtype and fc[dispelTypeShort[dtype]] then
                return true
            end
        end
        if C["dispel_filter_class"][name] then
            return true
        end
    end

    return false
end

-- 队伍变动
function GoubayuHeal.Dispel_OnRosterChange()
    GoubayuHeal.Dispel_BuildPrio()
end

-- ============================================================
-- 扫描
-- ============================================================

function GoubayuHeal.Dispel_Scan()
    DispelList = {}
    DispelForceList = {}
    DispelNormalList = {}

    if not GoubayuHeal.Config or GoubayuHeal.Config["dispel_enabled"] ~= 1 then
        return
    end

    -- 首登自愈：登录期的名单事件早于队友名字同步触发，BuildPrio 因空名字漏掉所有队友，
    -- 且之后不再有名单事件 → 整个会话扫不到队友（/reload 后名字缓存温热，故只在首登出现）。
    -- 每1秒检测一次：本职业可驱散类型表为空则补扫；队友/团员存活但不在候选表则重建候选表
    local now = GetTime()
    if now >= DispelRosterCheckAt then
        DispelRosterCheckAt = now + 1

        if dispelSpells[classFile] and not (DispelUsable.Magic or DispelUsable.Curse
            or DispelUsable.Disease or DispelUsable.Poison or DispelUsable.Snare) then
            GoubayuHeal.Dispel_UpdateUsable()
        end

        local missing = false
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            for i = 1, numRaid do
                local u = "raid" .. i
                if UnitExists(u) and not DispelPrioSet[u] then
                    missing = true
                    break
                end
            end
        else
            for i = 1, GetNumPartyMembers() do
                local u = "party" .. i
                if UnitExists(u) and not DispelPrioSet[u] then
                    missing = true
                    break
                end
            end
        end
        if missing then
            GoubayuHeal.Dispel_BuildPrio()
        end
    end

    -- 统一走原版 UnitDebuff 周期性扫描
    local C = GoubayuHeal.Config
    local DF = C["dispel_filters"]
    if not DF then
        DF = {}
    end

    local shadowform = (classFile == "PRIEST" and C["dispel_shadowform"] == 1)
        and GoubayuHeal.Dispel_HasShadowform()

    local seenUnits = {}

    for _, unit in ipairs(DispelPrio) do
        if UnitExists(unit) and UnitIsVisible(unit)
            and GoubayuHeal.Dispel_CanBeCleansed(unit) then
            -- 去重：同一单位可通过 player/raidN 等多个token访问（UnitIsUnit 为同一单位），
            -- 用GUID做键（同一单位恒等、不同单位互异），保证每单位只扫描一次、只显示一个
            -- GUID 同时持久化进条目：unit token 只在扫描时刻有效，名单变动/索引重排后同一 token
            -- 可能指向另一名玩家，施放前用 entry.guid 校验身份（见 Dispel_ResyncEntry）
            -- by 武藤纯子酱 2026.9.21
            local guid = GoubayuHeal.GetUnitGUID and GoubayuHeal.GetUnitGUID(unit)
            local ug = guid or unit
            if ug and not seenUnits[ug] then
                seenUnits[ug] = true

                local _, class = UnitClass(unit)
                local i = 1
                local protDtype = {}
                local forceDtype = {}
                local unitEntries = {}

                -- 与主模块一致扫描 32 个光环槽（Nampower 暴露 32 槽，只扫 16 会漏掉高槽位的减益）
                while i <= 32 do
                    local name, dtype, texture, applications, spellId =
                        GoubayuHeal.Dispel_GetDebuffInfo(unit, i)

                    if not texture then
                        break
                    end

                    if name and name ~= "" and GoubayuHeal.Dispel_IsHidden(unit, name, dtype, class) then
                        -- 受保护减益（黑名单/防误驱散/职业过滤/专用开关等，任一命中）：
                        -- 记录其类型，该类型整批不驱散（群体驱散一次解多条时可能连带解掉它）
                        -- by 武藤纯子酱 2026.10.20
                        if dtype and C["dispel_protect_same_type"] ~= 0 then
                            protDtype[dtype] = true
                        end
                    elseif name and name ~= "" and dtype and DispelUsable[dtype] and DF[dtype] == 1 then
                        if C["dispel_ignore_abolish"] ~= 1 and GoubayuHeal.Dispel_HasAbolish(unit, dtype)
                            then
                            -- 有Abolish且未强制驱散 → 跳过
                        elseif shadowform and dtype ~= "Disease" then
                            -- 暗影形态过滤
                        else
                            local forced = Dispel_ForcePriority_set[name] and true or false
                            if forced and dtype then
                                forceDtype[dtype] = true
                            end
                            table.insert(unitEntries, {
                                unit = unit,
                                guid = guid,
                                unitName = UnitName(unit) or "",
                                debuffName = name,
                                debuffIndex = i,
                                dtype = dtype,
                                texture = texture,
                                stacks = applications or 0,
                                spellId = (spellId and spellId > 0) and spellId or nil,
                                force = forced,
                            })
                        end
                    end

                    i = i + 1
                end

                -- 强制优先项永远入列（即使同类型有受保护项）；其余项同类型受保护 → 跳过
                for _, e in ipairs(unitEntries) do
                    if e.force then
                        table.insert(DispelForceList, e)
                    elseif not protDtype[e.dtype] then
                        table.insert(DispelNormalList, e)
                    end
                end
            end
        end
    end

    -- 汇总：强制优先项排最前（第一时间驱散）
    DispelList = {}
    for _, e in ipairs(DispelForceList) do
        table.insert(DispelList, e)
    end
    for _, e in ipairs(DispelNormalList) do
        table.insert(DispelList, e)
    end
end

-- 施放前身份校验/重建候选表。
-- unit token 只在扫描时刻有效：名单变动/索引重排后，同一 token 可能已指向另一名玩家
-- （条目里的 unitName 是旧名字，实际施放会落到错误的人 → 客户端报"无可供驱散的法术"）。
-- 用扫描时持久化的 GUID 校验 token 当前解析出的 GUID：不一致（含 token 已失效）则重建候选表，
-- 在新表中按 GUID（无GUID时按 unit token）找同一玩家的同一减益，返回新条目；找不到返回 nil。
-- by 武藤纯子酱 2026.9.21
function GoubayuHeal.Dispel_ResyncEntry(entry)
    if not entry then
        return nil
    end

    GoubayuHeal.Dispel_Scan()

    for _, e in ipairs(DispelList) do
        if e.debuffName == entry.debuffName then
            if entry.guid then
                if e.guid == entry.guid then
                    return e
                end
            elseif e.unit == entry.unit then
                return e
            end
        end
    end

    return nil
end

-- ============================================================
-- 施法
-- ============================================================

function GoubayuHeal.Dispel_CastSpell(unit, spellName, guid)
    if not unit or not spellName then
        return false
    end

    -- 1秒/目标驱散节流：优先用 GUID 做键（身份稳定），无 GUID 回退目标名
    local uname = UnitName(unit)
    local tkey = guid or uname
    if tkey and GoubayuHeal.dispel_target_delay
        and GoubayuHeal.dispel_target_delay[tkey]
        and GoubayuHeal.dispel_target_delay[tkey] > GetTime() then
        return false
    end

    if GetNampowerVersion then
        -- Nampower：优先传目标 GUID（扫描时确认的那名玩家，身份精确）；无 GUID 回退 unit token
        -- by 武藤纯子酱 2026.9.21
        local g = guid or (GoubayuHeal.GetUnitGUID and GoubayuHeal.GetUnitGUID(unit))
        if g then
            CastSpellByName(spellName, g)
        else
            CastSpellByName(spellName, unit)
        end
        if tkey then
            GoubayuHeal.dispel_target_delay = GoubayuHeal.dispel_target_delay or {}
            GoubayuHeal.dispel_target_delay[tkey] = GetTime() + 1.0
        end
        return true
    end

    -- 非Nampower：切目标施法再切回
    local selfcast = GetCVar("autoSelfCast")
    local lastTarget = UnitName("target")

    SetCVar("autoSelfCast", 0)
    TargetUnit(unit)

    if UnitExists("target") and UnitIsUnit("target", unit) then
        CastSpellByName(spellName)
        if tkey then
            GoubayuHeal.dispel_target_delay = GoubayuHeal.dispel_target_delay or {}
            GoubayuHeal.dispel_target_delay[tkey] = GetTime() + 1.0
        end
    end

    if lastTarget and UnitName("target") ~= lastTarget then
        TargetLastTarget()
    end

    SetCVar("autoSelfCast", selfcast)
    return true
end

-- 传染诅咒警告节流：目标名/单位 → 上次警告时间
local Dispel_CurseWarnCooldown = {}

-- ============================================================
-- 需远离人群的诅咒（中招者周围有玩家时不驱散并警告，避免传染/炸到队友）
-- 可在此列表追加其他需远离人群的诅咒名
-- ============================================================
local Dispel_NearbyCurseTargets_set = {}
for _, n in ipairs(GoubayuHeal.DispelNearbyCurseTargets) do Dispel_NearbyCurseTargets_set[n] = true end

-- 检测指定单位周围 DCR_DISTANCE_THRESHOLD 码内是否有其他玩家
-- Nampower：用 GetUnitGUID + UnitXP("distanceBetween") 精确距离；无Nampower回退 CheckInteractDistance(4)
-- 返回 true, 附近玩家unit 或 false, nil
local Dispel_NearbyDistance = 8
local function Dispel_CheckNearbyPlayers(unit)
    local function distNear(a, b)
        if not UnitExists(b) then return false end
        if GetNampowerVersion and UnitXP then
            local ga = GoubayuHeal.GetUnitGUID and GoubayuHeal.GetUnitGUID(a)
            local gb = GoubayuHeal.GetUnitGUID and GoubayuHeal.GetUnitGUID(b)
            if ga and gb then
                local ok, d = pcall(UnitXP, "distanceBetween", ga, gb)
                if ok and d and d < Dispel_NearbyDistance then
                    return true
                end
            end
        end
        -- 无Nampower/距离不可用：CheckInteractDistance 无源单位参数，只能测"玩家↔b"，
        -- 仅当中招者就是玩家本人时结果才等价于 a↔b；否则无精确信息，保守放行（正常驱散）
        if a == "player" and CheckInteractDistance and CheckInteractDistance(b, 4) then
            return true
        end
        return false
    end

    local n = GetNumRaidMembers()
    if n > 0 then
        for i = 1, n do
            local u = "raid" .. i
            if not UnitIsUnit(unit, u) and UnitExists(u) and not UnitIsDeadOrGhost(u) then
                if distNear(unit, u) then
                    return true, u
                end
            end
        end
    else
        -- 小队模式 party1-4 不含玩家自己：驱散者本人靠近中招者也算"有人靠近"，
        -- 否则自己会被传染却不预警
        if not UnitIsUnit(unit, "player") and not UnitIsDeadOrGhost("player") then
            if distNear(unit, "player") then
                return true, "player"
            end
        end
        for i = 1, 4 do
            local u = "party" .. i
            if not UnitIsUnit(unit, u) and UnitExists(u) and not UnitIsDeadOrGhost(u) then
                if distNear(unit, u) then
                    return true, u
                end
            end
        end
    end
    return false, nil
end

-- 判断单位是否在指定码数内（Nampower精确距离；非Nampower用CheckInteractDistance(4)=28码近似）
function GoubayuHeal.Dispel_IsWithinRange(u, range)
    if not UnitExists(u) then
        return false
    end
    if GetNampowerVersion and UnitXP then
        local g1 = GoubayuHeal.GetUnitGUID("player")
        local g2 = GoubayuHeal.GetUnitGUID(u)
        if g1 and g2 then
            local d = UnitXP("distanceBetween", g1, g2)
            if d and type(d) == "number" then
                -- 精确距离已测得：以它为准（此前超range仍落到28码回退，26-28码会被误判在范围内）
                return d <= range
            end
        end
    end
    if CheckInteractDistance and CheckInteractDistance(u, 4) then
        return true
    end
    return false
end

-- 萨满图腾驱散：毒/病目标在26码内时优先用清毒/祛病图腾（图腾自动覆盖驱散，节省法力）
local Dispel_TotemNames = {
    Poison = GoubayuHeal.Totem.TotemPoison,
    Disease = GoubayuHeal.Totem.TotemDisease
}

-- 目标是否被该图腾覆盖：用 UnitXP 直接测"图腾GUID ↔ 目标"距离（与图腾覆盖统计同口径）；
-- 无 Nampower/UnitXP 时退回"玩家↔目标"距离近似
function GoubayuHeal.Dispel_TotemCoversUnit(totemGuid, unit, radius)
    if not (totemGuid and unit and UnitExists(unit)) then
        return false
    end
    radius = radius or 26
    if GetNampowerVersion and UnitXP then
        local ok, dist = pcall(UnitXP, "distanceBetween", totemGuid, unit)
        if ok and dist and type(dist) == "number" then
            return dist <= radius
        end
    end
    return GoubayuHeal.Dispel_IsWithinRange(unit, radius)
end

-- 判断目标是否在萨满本小队（清毒/祛病图腾只净化本小队成员，含本队宠物）
function GoubayuHeal.Dispel_InOwnSubgroup(unit)
    if not unit then
        return false
    end
    if UnitIsUnit(unit, "player") or UnitIsUnit(unit, "pet") then
        return true
    end
    if GetNumRaidMembers() > 0 then
        -- 团队：比较目标与玩家所在小队编号（含团队宠物，按主人小队归属）
        local mySubgroup = nil
        for i = 1, GetNumRaidMembers() do
            if UnitIsUnit("raid" .. i, "player") then
                local _, _, sub = GetRaidRosterInfo(i)
                mySubgroup = sub
                break
            end
        end
        if not mySubgroup then
            return false
        end
        local raidIndex = nil
        for i = 1, GetNumRaidMembers() do
            if UnitIsUnit(unit, "raid" .. i) or UnitIsUnit(unit, "raidpet" .. i) then
                raidIndex = i
                break
            end
        end
        if not raidIndex then
            return false
        end
        local _, _, sub = GetRaidRosterInfo(raidIndex)
        return sub == mySubgroup
    end
    -- 小队/单机：本队成员与队宠
    for i = 1, 4 do
        if UnitIsUnit(unit, "party" .. i) or UnitIsUnit(unit, "partypet" .. i) then
            return true
        end
    end
    return false
end

function GoubayuHeal.Dispel_ShamanTotem(entry)
    if not entry or not entry.unit then
        return false
    end
    local totemName = Dispel_TotemNames[entry.dtype]
    if not totemName then
        return false
    end

    -- 图腾只净化本小队成员：其他小队目标不走进图腾分支（既不跳过驱散也不为此插图腾），
    -- 返回 false 交回正常解毒/祛病法术（修复：本队已插图腾时其他队成员无法被驱散）
    if not GoubayuHeal.Dispel_InOwnSubgroup(entry.unit) then
        return false
    end

    local radius = GoubayuHeal.Totem_CleanseRange or 26

    -- ① 图腾已插且确实覆盖该目标（UnitXP 测 图腾GUID↔目标 距离）→ 交给图腾，不动作
    --    （范围内的等图腾脉冲净化，即使是新进入范围的也一样）
    if GoubayuHeal.Totem_ActivePlacedTotems then
        for guid, data in pairs(GoubayuHeal.Totem_ActivePlacedTotems) do
            if data and data.name and string.find(data.name, totemName) then
                if GoubayuHeal.Dispel_TotemCoversUnit(guid, entry.unit, radius) then
                    return true
                end
            end
        end
    end

    -- ② 图腾覆盖不到该目标：
    --    目标在自身26码内 → 重插/补插对应图腾（图腾插在脚下，可覆盖之），落到下面的插图腾逻辑
    --    目标超出自身26码 → 够不着，交回单体清毒术/祛病术
    if not GoubayuHeal.Dispel_IsWithinRange(entry.unit, 26) then
        return false
    end

    -- 查找图腾技能槽并检查CD
    local tslot = nil
    local tabs = GetNumSpellTabs()
    for tab = 1, tabs do
        local _, _, offset, numSpells = GetSpellTabInfo(tab)
        for slot = offset + 1, offset + numSpells do
            local sname = GetSpellName(slot, BOOKTYPE_SPELL)
            if sname == totemName then
                tslot = slot
                break
            end
        end
        if tslot then
            break
        end
    end
    if not tslot then
        return false
    end

    local start, duration = GetSpellCooldown(tslot, BOOKTYPE_SPELL)
    if start and duration and duration > 0 then
        return false
    end

    -- 插图腾（自动驱散范围内目标的毒/病）
    CastSpellByName(totemName)
    if GoubayuHeal.Config and GoubayuHeal.Config["dispel_print"] == 1 then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(GoubayuHeal.Msg.DispelTotemCast,
            entry.debuffName or "", entry.unitName or ""))
    end
    return true
end

function GoubayuHeal.Dispel_Cleanse(entry, manual)
    if not entry or not entry.unit then
        return false
    end

    -- 身份校验：token 当前解析出的 GUID 与条目内持久化的 GUID 不符（含 token 已失效/名单重排后
    -- 指向了另一名玩家）→ 重建候选表，用新表中的同玩家同减益条目继续（找不到则放弃）
    -- by 武藤纯子酱 2026.9.21
    if entry.guid then
        local cur = GoubayuHeal.GetUnitGUID and GoubayuHeal.GetUnitGUID(entry.unit)
        if cur ~= entry.guid then
            entry = GoubayuHeal.Dispel_ResyncEntry(entry)
            if not entry then
                return false
            end
        end
    end

    local spell = DispelUsable[entry.dtype]
    if not spell or not spell.name then
        return false
    end

    -- GCD检查
    local _, duration = GetSpellCooldown(spell.slot, bookType)
    if duration ~= nil and duration > 0 and duration < 1.6 then
        return false
    end

    -- 需远离人群的减益：中招者周围8码内有其他玩家时不驱散并警告（避免传染/炸到队友）。
    -- 不再限定 dtype=="Curse"：名单里还有移动限制类（如"恶液烂芽"）等非诅咒减益
    -- by 武藤纯子酱 2026.9.21
    if entry.debuffName and Dispel_NearbyCurseTargets_set[entry.debuffName] then
        local nearby, nearbyUnit = Dispel_CheckNearbyPlayers(entry.unit)
        if nearby then
            -- 警告节流：同一目标 5 秒内不重复 YELL/密语（此前无冷却，条件持续时每次按键都发）
            local now = GetTime()
            local warnKey = entry.unitName or entry.unit
            if (now - (Dispel_CurseWarnCooldown[warnKey] or 0)) > 5 then
                Dispel_CurseWarnCooldown[warnKey] = now
                local targetName = UnitName(entry.unit) or ""
                if GetNumRaidMembers() > 0 then
                    SendChatMessage(string.format(GoubayuHeal.Msg.CurseAwayRaid, targetName, entry.debuffName), "YELL")
                else
                    SendChatMessage(string.format(GoubayuHeal.Msg.CurseAwayWhisper, entry.debuffName), "WHISPER", nil, targetName)
                end
            end
            return false -- 不执行驱散
        end
    end

    if not GoubayuHeal.Dispel_CanCast(entry.unit, entry.dtype) then
        return false
    end

    -- 萨满图腾驱散：毒/病目标26码内优先用清毒/祛病图腾（图腾自动覆盖驱散，节省法力）
    -- 但"手动驱散"（点击框架 / /gbyh dispel）不等图腾脉冲，直接单体驱散（急驱场景）
    -- by 武藤纯子酱 2026.9.21
    if (not manual) and GoubayuHeal.my_class == GoubayuHeal.Shaman
        and (entry.dtype == "Poison" or entry.dtype == "Disease")
        and GoubayuHeal.Dispel_ShamanTotem(entry) then
        return true
    end

    -- 断条
    if GoubayuHeal.Config and GoubayuHeal.Config["dispel_interrupt"] == 1
        and GetCurrentCastingInfo then
        local _, _, _, casting, channeling = GetCurrentCastingInfo()
        if (casting or 0) > 0 or (channeling or 0) > 0 then
            SpellStopCasting()
        end
    end

    local ok = GoubayuHeal.Dispel_CastSpell(entry.unit, spell.name, entry.guid)

    if ok and GoubayuHeal.Config["dispel_print"] == 1 then
        DEFAULT_CHAT_FRAME:AddMessage(string.format(GoubayuHeal.Msg.DispelCast,
            entry.debuffName or "", entry.unitName or ""))
    end

    return ok
end

-- ============================================================
-- 一键驱散（顶部优先）
-- ============================================================

function GoubayuHeal.Dispel(manual)
    if not GoubayuHeal.Config or GoubayuHeal.Config["dispel_enabled"] ~= 1 then
        return false
    end

    GoubayuHeal.Dispel_Scan()

    for _, entry in ipairs(DispelList) do
        if GoubayuHeal.Dispel_Cleanse(entry, manual) then
            return true
        end
    end

    return false
end

-- ============================================================
-- 驱散优先判定（队列集成）
-- ============================================================

function GoubayuHeal.Dispel_Priority()
    if not GoubayuHeal.Config or GoubayuHeal.Config["dispel_enabled"] ~= 1 then
        return false
    end

    local threshold = tonumber(GoubayuHeal.Config["dispel_priority"]) or 0.5

    if threshold <= 0 then
        return GoubayuHeal.Dispel()
    end

    local minPct = 101
    local numRaid = GetNumRaidMembers()
    local por = "raid"

    if numRaid == 0 then
        numRaid = GetNumPartyMembers()
        por = "party"
    end

    local units = {}
    table.insert(units, "player")

    for a = 1, numRaid do
        table.insert(units, por .. a)
    end

    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitIsFriend("player", unit)
            and not UnitIsDeadOrGhost(unit) then
            local h, maxh = GoubayuHeal.GetUnitHealth(unit)
            if maxh and maxh > 0 then
                local pct = h / maxh
                if pct < minPct then
                    minPct = pct
                end
            end
        end
    end

    if minPct >= threshold then
        return GoubayuHeal.Dispel()
    end

    return false
end

-- 自由之手独立通道（/gbyh freedom 或 /gbyh 自由）：
-- 不管"驱散移动限制"复选框是否勾选，都对"驱散优先级"里最高优先级、且带移动限制的目标施放。
-- 目标选择复用 DispelPrio（dispel_prio 权重）。 by 武藤纯子酱 2026.10.13
function GoubayuHeal.Dispel_Freedom()
    local spell = DispelUsable.Snare
    if not (spell and spell.name) then
        return false
    end

    GoubayuHeal.Dispel_BuildPrio()

    for _, unit in ipairs(DispelPrio) do
        if UnitExists(unit) and UnitIsVisible(unit)
            and GoubayuHeal.Dispel_CanBeCleansed(unit)
            and GoubayuHeal.Dispel_CanCast(unit, "Snare") then
            local _, class = UnitClass(unit)
            local i = 1
            while i <= 32 do
                local nm, dtype, tex, apps, sid = GoubayuHeal.Dispel_GetDebuffInfo(unit, i)
                if not tex then
                    break
                end
                -- 与自动驱散一致：黑名单/隐藏减益/职业隐藏命中的移动限制也不驱散
                -- （黑名单里的某技能可能就是"限制移动但不能驱散"的） by 武藤纯子酱 2026.10.13
                if dtype == "Snare"
                    and not GoubayuHeal.Dispel_IsHidden(unit, nm, dtype, class) then
                    local guid = GoubayuHeal.GetUnitGUID and GoubayuHeal.GetUnitGUID(unit)
                    GoubayuHeal.Dispel_CastSpell(unit, spell.name, guid)
                    return true
                end
                i = i + 1
            end
        end
    end

    return false
end

-- ============================================================
-- 更新窗口显示
-- ============================================================

local DispelButtons = {}
local DispelWindow = nil
local DispelUpdateTimer = 0

function GoubayuHeal.Dispel_UpdateWindow()
    if not DispelWindow then
        return
    end

    GoubayuHeal.Dispel_Scan()

    -- 钳制到实际创建的按钮数（防外部导入超限配置导致 nil 索引）
    local num = GoubayuHeal.Config["dispel_buttons"] or 5
    if num > 15 then
        num = 15
    end

    for i = 1, num do
        local btn = DispelButtons[i]
        local entry = DispelList[i]

        if entry then
            btn.icon:SetTexture(entry.texture)
            btn.name:SetText(entry.debuffName)

            local color = dispelTypeColors[entry.dtype]
            if color then
                btn.border:SetVertexColor(color[1], color[2], color[3])
            end

            if entry.stacks and entry.stacks >= 1 then
                btn.count:SetText(entry.stacks)
                btn.count:Show()
            else
                btn.count:SetText("")
                btn.count:Hide()
            end

            btn.player:SetText(entry.unitName)

            if btn.typeText then
                local short = dispelTypeShort[entry.dtype]
                if short then
                    btn.typeText:SetText(short)
                    local tc = dispelTypeColors[entry.dtype]
                    if tc then
                        btn.typeText:SetTextColor(tc[1], tc[2], tc[3])
                    end
                    btn.typeText:Show()
                else
                    btn.typeText:SetText("")
                    btn.typeText:Hide()
                end
            end

            if GoubayuHeal.Dispel_CanCast(entry.unit, entry.dtype) then
                btn:SetAlpha(1)
            else
                btn:SetAlpha(0.5)
            end

            btn.entry = entry
            btn:Show()
        else
            btn.entry = nil
            btn:Hide()
        end
    end

    for i = num + 1, 15 do
        local btn = DispelButtons[i]
        if btn then
            btn.entry = nil
            btn:Hide()
        end
    end

    if DispelWindow.hidden == 1 then
        DispelWindow:Hide()
    else
        DispelWindow:Show()
    end
end

function GoubayuHeal.Dispel_OnUpdate(elapsed)
    elapsed = elapsed or 0.1
    DispelUpdateTimer = DispelUpdateTimer + elapsed

    if DispelUpdateTimer < 0.1 then
        return
    end

    DispelUpdateTimer = 0

    if GoubayuHeal.Config and GoubayuHeal.Config["dispel_enabled"] == 1 then
        -- 窗口隐藏（hidden=1）时无 UI 可刷新，跳过 0.1s 全团扫描——
        -- 此前启用功能即恒定 10Hz 全团扫（与窗口显隐无关），是常驻 CPU 大头；
        -- 一键驱散 Dispel() 自带按需 Dispel_Scan，不受影响 by 武藤纯子酱 2026.9.4
        if DispelWindow and DispelWindow.hidden == 1 then
            return
        end
        GoubayuHeal.Dispel_UpdateWindow()
    end
end

-- ============================================================
-- UI 样式辅助函数
-- ============================================================

function GoubayuHeal.Dispel_FlatBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    frame:SetBackdropColor(0.035, 0.035, 0.035, 0.96)
    frame:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
end

function GoubayuHeal.Dispel_FlatButton(btn, width, height)
    btn:SetWidth(width)
    btn:SetHeight(height)

    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    btn:SetBackdropColor(0.055, 0.055, 0.055, 0.98)
    btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

    local oldEnter = btn:GetScript("OnEnter")
    local oldLeave = btn:GetScript("OnLeave")

    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(0.32, 0.19, 0.02, 1)
        if oldEnter then
            oldEnter()
        end
    end)

    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(0.055, 0.055, 0.055, 0.98)
        if oldLeave then
            oldLeave()
        end
    end)

    return btn
end

-- 应用窗口样式
function GoubayuHeal.Dispel_ApplyWindowStyle()
    if not DispelWindow or not GoubayuHeal.Config then
        return
    end

    local C = GoubayuHeal.Config

    DispelWindow:SetScale(C["dispel_scale"] or 0.85)
    DispelWindow:SetAlpha(C["dispel_opacity"] or 1.0)
    DispelWindow:SetMovable(C["dispel_lock"] ~= 1)
    DispelWindow:EnableMouse(C["dispel_lock"] ~= 1)

    if C["dispel_backdrop"] == 1 then
        GoubayuHeal.Dispel_FlatBackdrop(DispelWindow)

        for _b = 1, 15 do
            local btn = DispelButtons[_b]
            if btn then
                btn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    tile = true,
                    tileSize = 8,
                    edgeSize = 1,
                    insets = { left = 2, right = 2, top = 2, bottom = 2 }
                })
                btn:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
                btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)
            end
        end
    else
        DispelWindow:SetBackdrop(nil)
        for _b = 1, 15 do
            local btn = DispelButtons[_b]
            if btn then
                btn:SetBackdrop(nil)
            end
        end
    end

    local num = C["dispel_buttons"] or 5
    if num < 1 then
        num = 1
    end
    if num > 15 then
        num = 15
    end

    local showHeader = (C["dispel_show_header"] == 1)

    if showHeader then
        DispelWindow:SetHeight(num * 42 + 40)
    else
        DispelWindow:SetHeight(num * 42 + 10)
    end

    local bottomPad = showHeader and 40 or 5

    for i = 1, 15 do
        local btn = DispelButtons[i]
        if not btn then
            break
        end

        btn:ClearAllPoints()

        if C["dispel_flip"] == 1 then
            if i == 1 then
                btn:SetPoint("BOTTOM", DispelWindow, "BOTTOM", 0, bottomPad)
            else
                btn:SetPoint("BOTTOM", DispelButtons[i - 1], "TOP", 0, 0)
            end
        else
            if i == 1 then
                btn:SetPoint("TOP", DispelWindow, "TOP", 0, -35)
            else
                btn:SetPoint("TOP", DispelButtons[i - 1], "BOTTOM", 0, 0)
            end
        end
    end

    if DispelWindow.title then
        DispelWindow.title:ClearAllPoints()
        DispelWindow.hit:ClearAllPoints()

        if C["dispel_flip"] == 1 then
            DispelWindow.title:SetPoint("BOTTOM", DispelWindow, "BOTTOM", 0, 12)
            DispelWindow.hit:SetPoint("BOTTOMLEFT", DispelWindow, "BOTTOMLEFT", 10, 2)
        else
            DispelWindow.title:SetPoint("TOP", DispelWindow, "TOP", 0, -10)
            DispelWindow.hit:SetPoint("TOPLEFT", DispelWindow, "TOPLEFT", 10, -2)
        end

        if DispelWindow.prioBtn then
            DispelWindow.prioBtn:ClearAllPoints()
            if C["dispel_flip"] == 1 then
                DispelWindow.prioBtn:SetPoint("BOTTOMRIGHT", DispelWindow, "BOTTOMRIGHT", -6, 2)
            else
                DispelWindow.prioBtn:SetPoint("TOPRIGHT", DispelWindow, "TOPRIGHT", -6, -2)
            end
        end

        if showHeader then
            DispelWindow.title:Show()
            DispelWindow.hit:Show()
            if DispelWindow.prioBtn then
                DispelWindow.prioBtn:Show()
            end
        else
            DispelWindow.title:Hide()
            DispelWindow.hit:Hide()
            if DispelWindow.prioBtn then
                DispelWindow.prioBtn:Hide()
            end
        end
    end
end

-- ============================================================
-- 驱散优先级窗口（团队样式）
-- ============================================================

local DispelPrioWin = nil

function GoubayuHeal.Dispel_PrioMakeSlider(parent, name)
    local slider = CreateFrame("Slider", name, parent)
    slider:SetWidth(128)
    slider:SetHeight(10)
    slider:SetOrientation("HORIZONTAL")
    slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")

    local rail = slider:CreateTexture(nil, "BACKGROUND")
    rail:SetTexture("Interface\\Buttons\\WHITE8X8")
    rail:SetHeight(4)
    rail:SetPoint("LEFT", slider, "LEFT", 0, 0)
    rail:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    rail:SetPoint("CENTER", slider, "CENTER", 0, 0)
    rail:SetVertexColor(0.25, 0.25, 0.25, 0.8)
    slider.railTex = rail

    local fill = slider:CreateTexture(nil, "ARTWORK")
    fill:SetTexture("Interface\\Buttons\\WHITE8X8")
    fill:SetHeight(4)
    fill:SetPoint("LEFT", slider, "LEFT", 0, 0)
    fill:SetPoint("CENTER", slider, "CENTER", 0, 0)
    fill:SetVertexColor(0.78, 0.56, 0.25, 1)
    slider.fillTex = fill

    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetWidth(12)
        thumb:SetHeight(12)
        thumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
    end

    return slider
end

function GoubayuHeal.Dispel_PrioUpdateFill(slider)
    local minV, maxV = slider:GetMinMaxValues()
    local v = slider:GetValue()
    local span = maxV - minV
    local ratio = 0

    if span > 0 then
        ratio = (v - minV) / span
    end
    if ratio < 0 then
        ratio = 0
    end
    if ratio > 1 then
        ratio = 1
    end

    local w = slider:GetWidth() - 12
    if w < 0 then
        w = 0
    end

    slider.fillTex:SetWidth(w * ratio)
end

function GoubayuHeal.Dispel_PrioSetSliderGray(sl, gray)
    if not sl then
        return
    end

    sl:EnableMouse(not gray)

    if sl.railTex then
        if gray then
            sl.railTex:SetVertexColor(0.20, 0.20, 0.20, 0.8)
        else
            sl.railTex:SetVertexColor(0.25, 0.25, 0.25, 0.8)
        end
    end

    if sl.fillTex then
        if gray then
            sl.fillTex:SetVertexColor(0.28, 0.28, 0.28, 1)
        else
            sl.fillTex:SetVertexColor(0.78, 0.56, 0.25, 1)
        end
    end
end

function GoubayuHeal.Dispel_CurrentNames()
    local set = {}
    local numRaid = GetNumRaidMembers()

    if numRaid > 0 then
        for i = 1, numRaid do
            local name = GetRaidRosterInfo(i)
            if name then
                set[name] = true
            end
        end
    else
        if UnitExists("player") then
            set[UnitName("player")] = true
        end
        for a = 1, GetNumPartyMembers() do
            local unit = "party" .. a
            if UnitExists(unit) and UnitIsFriend("player", unit) then
                set[UnitName(unit)] = true
            end
        end
    end

    return set
end

function GoubayuHeal.Dispel_CreatePrioWindow()
    if DispelPrioWin then
        return DispelPrioWin
    end

    local w = CreateFrame("Frame", "GoubayuHealDispelPrioFrame", UIParent)
    w:SetWidth(850)
    -- 高度 540→580：队伍网格（8组×2行）下缘约在距顶490px，底部预留两行
    -- 职业开关（约90px）的显示空间；职业行按第8队框架实际下缘动态定位，不重叠
    -- by 武藤纯子酱 2026.9.4
    w:SetHeight(580)
    w:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    w:SetFrameStrata("DIALOG")
    w:SetFrameLevel(60)
    w:SetMovable(true)
    w:EnableMouse(true)

    GoubayuHeal.Dispel_FlatBackdrop(w)

    -- 标题栏
    local titleBar = CreateFrame("Button", "GoubayuHealDispelPrioTitleBar", w)
    titleBar:SetWidth(810)
    titleBar:SetHeight(32)
    titleBar:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -6)

    titleBar:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then
            w:StartMoving()
        end
    end)

    titleBar:SetScript("OnMouseUp", function()
        w:StopMovingOrSizing()
    end)

    local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    title:SetTextColor(1, 0.565, 0)
    title:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
    title:SetText(GoubayuHeal.DispelUI.PrioWindowTitle)

    -- 关闭按钮
    local close = CreateFrame("Button", nil, titleBar)
    close:SetWidth(22)
    close:SetHeight(22)
    close:SetPoint("RIGHT", titleBar, "RIGHT", -4, 0)

    close:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = true,
        tileSize = 8,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    close:SetBackdropColor(0.6, 0.12, 0.12, 0.98)
    close:SetBackdropBorderColor(0.8, 0.35, 0.35, 0.9)

    close.text = close:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    close.text:SetPoint("CENTER", close, "CENTER", 0, 0)
    close.text:SetTextColor(1, 0.85, 0.85)
    close.text:SetText("X")
    close:SetScript("OnClick", function()
        w:Hide()
    end)

    -- 重置按钮
    local resetBtn = CreateFrame("Button", nil, w)
    resetBtn:SetWidth(100)
    resetBtn:SetHeight(26)
    resetBtn:SetPoint("TOPLEFT", w, "TOPLEFT", 16, -46)
    resetBtn.text = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetBtn.text:SetPoint("CENTER", resetBtn, "CENTER", 0, 0)
    resetBtn.text:SetText(GoubayuHeal.DispelUI.Reset50)
    GoubayuHeal.Dispel_FlatButton(resetBtn, 100, 26)

    resetBtn:SetScript("OnClick", function()
        if not GoubayuHeal.Config then
            return
        end
        GoubayuHeal.Config["dispel_player_priority"] = GoubayuHeal.Config[
            "dispel_player_priority"] or {}

        for name in pairs(GoubayuHeal.Dispel_CurrentNames()) do
            GoubayuHeal.Config["dispel_player_priority"][name] = 4
        end

        GoubayuHeal.Dispel_BuildPrio()
        GoubayuHeal.Dispel_PrioRefresh()
    end)

    -- 反向按钮
    local invertBtn = CreateFrame("Button", nil, w)
    invertBtn:SetWidth(80)
    invertBtn:SetHeight(26)
    invertBtn:SetPoint("LEFT", resetBtn, "RIGHT", 10, 0)
    invertBtn.text = invertBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    invertBtn.text:SetPoint("CENTER", invertBtn, "CENTER", 0, 0)
    invertBtn.text:SetText(GoubayuHeal.DispelUI.Invert)
    GoubayuHeal.Dispel_FlatButton(invertBtn, 80, 26)

    invertBtn:SetScript("OnClick", function()
        if not GoubayuHeal.Config then
            return
        end
        GoubayuHeal.Config["dispel_player_priority"] = GoubayuHeal.Config[
            "dispel_player_priority"] or {}

        for name in pairs(GoubayuHeal.Dispel_CurrentNames()) do
            local v = GoubayuHeal.Config["dispel_player_priority"][name]
            if v == nil then
                v = 4
            end
            GoubayuHeal.Config["dispel_player_priority"][name] = 8 - v
        end

        GoubayuHeal.Dispel_BuildPrio()
        GoubayuHeal.Dispel_PrioRefresh()
    end)

    -- 重置0%按钮：所有成员优先级设为0
    local zeroBtn = CreateFrame("Button", nil, w)
    zeroBtn:SetWidth(90)
    zeroBtn:SetHeight(26)
    zeroBtn:SetPoint("LEFT", invertBtn, "RIGHT", 10, 0)
    zeroBtn.text = zeroBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    zeroBtn.text:SetPoint("CENTER", zeroBtn, "CENTER", 0, 0)
    zeroBtn.text:SetText(GoubayuHeal.DispelUI.Reset0)
    GoubayuHeal.Dispel_FlatButton(zeroBtn, 90, 26)

    zeroBtn:SetScript("OnClick", function()
        if not GoubayuHeal.Config then
            return
        end
        GoubayuHeal.Config["dispel_player_priority"] = GoubayuHeal.Config[
            "dispel_player_priority"] or {}

        for name in pairs(GoubayuHeal.Dispel_CurrentNames()) do
            GoubayuHeal.Config["dispel_player_priority"][name] = 0
        end

        GoubayuHeal.Dispel_BuildPrio()
        GoubayuHeal.Dispel_PrioRefresh()
    end)

    -- 只驱散小队按钮：非玩家所在小队的成员优先级设为0
    local partyBtn = CreateFrame("Button", nil, w)
    partyBtn:SetWidth(110)
    partyBtn:SetHeight(26)
    partyBtn:SetPoint("LEFT", zeroBtn, "RIGHT", 10, 0)
    partyBtn.text = partyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    partyBtn.text:SetPoint("CENTER", partyBtn, "CENTER", 0, 0)
    partyBtn.text:SetText(GoubayuHeal.DispelUI.PartyOnly)
    GoubayuHeal.Dispel_FlatButton(partyBtn, 110, 26)

    partyBtn:SetScript("OnClick", function()
        if not GoubayuHeal.Config then
            return
        end
        GoubayuHeal.Config["dispel_player_priority"] = GoubayuHeal.Config[
            "dispel_player_priority"] or {}

        -- 玩家所在小队
        local mySubgroup = 1
        if GetNumRaidMembers() > 0 then
            local myName = UnitName("player")
            for i = 1, GetNumRaidMembers() do
                local rname, _, subgroup = GetRaidRosterInfo(i)
                if rname == myName then
                    mySubgroup = subgroup
                    break
                end
            end
        end

        -- 非玩家所在小队（能在团队中确定小队）→ 优先级0
        for name in pairs(GoubayuHeal.Dispel_CurrentNames()) do
            local sg = nil
            for i = 1, GetNumRaidMembers() do
                local rname, _, subgroup = GetRaidRosterInfo(i)
                if rname == name then
                    sg = subgroup
                    break
                end
            end
            if sg ~= nil and sg ~= mySubgroup then
                GoubayuHeal.Config["dispel_player_priority"][name] = 0
            end
        end

        GoubayuHeal.Dispel_BuildPrio()
        GoubayuHeal.Dispel_PrioRefresh()
    end)

    -- 8组队伍
    for group = 1, 8 do
        local gf = CreateFrame("Frame", "GoubayuHealDispelPrioGroup" .. group, w)
        gf:SetWidth(196)
        gf:SetHeight(200)
        gf:SetID(group)
        GoubayuHeal.Dispel_FlatBackdrop(gf)

        local label = gf:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        label:SetTextColor(1, 0.565, 0)
        label:SetPoint("TOP", gf, "TOP", 0, -5)
        label:SetText(GoubayuHeal.DispelUI.GroupPrefix .. group)

        for slot = 1, 5 do
            local g2 = group
            local s2 = slot

            local slotFrame = CreateFrame("Frame", "GoubayuHealDispelPrioGroup" .. group .. "Slot"
                .. slot, gf)
            slotFrame:SetWidth(188)
            slotFrame:SetHeight(32)
            slotFrame:SetID(slot)
            slotFrame:SetPoint("TOPLEFT", gf, "TOPLEFT", 4, -20 - (slot - 1) * 34)

            local nm = slotFrame:CreateFontString(
                "GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot .. "Name",
                "OVERLAY", "GameFontNormal")
            nm:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
            nm:SetTextColor(0.72, 0.72, 0.72)
            nm:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 6, 0)
            nm:SetWidth(150)
            nm:SetJustifyH("LEFT")

            local slider = GoubayuHeal.Dispel_PrioMakeSlider(slotFrame,
                "GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot .. "PrioritySlider")
            slider:SetMinMaxValues(0, 8)
            slider:SetValueStep(1)
            slider:SetValue(4)
            slider:SetPoint("TOPLEFT", slotFrame, "TOPLEFT", 6, -15)

            local pct = slotFrame:CreateFontString(
                "GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot .. "PriorityPct",
                "OVERLAY", "GameFontNormalSmall")
            pct:SetPoint("LEFT", slider, "RIGHT", 3, 0)
            pct:SetTextColor(1, 1, 1)
            pct:SetText("4")

            slider:SetScript("OnValueChanged", function()
                GoubayuHeal.Dispel_PrioUpdateFill(slider)

                local v = math.floor(slider:GetValue() + 0.5)
                if v < 0 then
                    v = 0
                end
                if v > 8 then
                    v = 8
                end

                pct:SetText(v)

                if v == 0 then
                    pct:SetTextColor(1, 0.35, 0.2)
                else
                    pct:SetTextColor(1, 1, 1)
                end

                local nmf = getglobal("GoubayuHealDispelPrioGroup" .. g2 .. "Slot" .. s2 .. "Name")
                local memberName = nmf and nmf:GetText() or ""

                if memberName == "" or memberName == GoubayuHeal.Msg.RoleNone then
                    if math.floor(slider:GetValue() + 0.5) ~= 4 then
                        slider:SetValue(4)
                    end
                    return
                end

                GoubayuHeal.Config["dispel_player_priority"] = GoubayuHeal.Config[
                    "dispel_player_priority"] or {}
                GoubayuHeal.Config["dispel_player_priority"][memberName] = v
                GoubayuHeal.Dispel_BuildPrio()
            end)

            slider:SetScript("OnShow", function()
                GoubayuHeal.Dispel_PrioUpdateFill(slider)
                pct:SetText(math.floor(slider:GetValue() + 0.5))
            end)
        end

        local col = math.mod(group - 1, 4)
        local row = math.floor((group - 1) / 4)
        gf:SetPoint("TOPLEFT", w, "TOPLEFT", 16 + col * 205, -82 - row * 208)
    end

    -- 职业过滤：主框架同款开关（复选框样式）+ 职业色名字，直接挂在窗口上
    -- 默认全开；关闭的职业整队不参与驱散，与上方优先级设置无关
    -- 布局：标题一行、开关一行，均左对齐（窗口高580、网格下缘约490）
    -- by 武藤纯子酱 2026.9.6
    local rowH = 20
    local dyRow = 46   -- 开关行底边距窗口底边

    local flLabel = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    flLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    flLabel:SetTextColor(1, 0.565, 0)
    flLabel:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 12, dyRow + rowH + 6)
    flLabel:SetText(GoubayuHeal.DispelUI.ClassFilterLabel)

    w.classFilterLabel = flLabel
    w.classFilterLabelW = 60
    w.classFilterButtons = {}

    local function bindToggle(cell, sw, cf)
        -- 主框架开关内置翻转逻辑，此处仅在翻转后同步配置
        sw.userOnClick = function()
            local on = sw:GetChecked()
            GoubayuHeal.Dispel_SetClassEnabled(cf, on)
            GoubayuHeal.Dispel_PrioClassFilterRefresh()
        end
        cell.sw = sw
    end

    local function classColor(cf)
        local rcc = RAID_CLASS_COLORS and RAID_CLASS_COLORS[cf]
        if rcc then
            return rcc.r, rcc.g, rcc.b
        end
        return 1, 0.82, 0.55
    end

    local xStep = 84
    for i, cf in ipairs(dispelClassList) do
        local cell = CreateFrame("Frame", nil, w)
        cell:SetWidth(xStep)
        cell:SetHeight(rowH)
        cell.cf = cf

        local gUI = GoubayuHeal.UI
        local sw
        if gUI and gUI.CreateSwitch then
            sw = gUI.CreateSwitch(cell, nil, 30, rowH - 4)
            bindToggle(cell, sw, cf)
        else
            -- 兜底：UI 模块不可用时用原生勾选框（补默认贴图保证可见）
            sw = CreateFrame("CheckButton", nil, cell)
            sw:SetWidth(20)
            sw:SetHeight(rowH - 4)
            sw:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
            sw:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
            sw:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
            sw:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
            sw:SetChecked(false)
            sw:SetScript("OnClick", function()
                GoubayuHeal.Dispel_SetClassEnabled(cf, this:GetChecked())
                GoubayuHeal.Dispel_PrioClassFilterRefresh()
            end)
            cell.sw = sw
        end

        sw:SetPoint("LEFT", cell, "LEFT", 2, 0)

        local name = cell:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        name:SetPoint("LEFT", sw, "RIGHT", 3, 0)
        name:SetText(GoubayuHeal.Dispel_ClassName(cf))
        cell.name = name

        cell.cr, cell.cg, cell.cb = classColor(cf)

        -- 悬停提示挂在开关上（UI.SetTooltip 会覆盖开关原有 hover 高亮，仅此样式损失）
        if gUI and gUI.SetTooltip then
            gUI.SetTooltip(sw, GoubayuHeal.Dispel_ClassName(cf),
                GoubayuHeal.DispelUI.ClassFilterTip)
        end

        -- 单行左对齐（与标题行同左起点 12）
        cell:SetPoint("BOTTOMLEFT", w, "BOTTOMLEFT", 12 + (i - 1) * xStep, dyRow)

        w.classFilterButtons[i] = cell
    end

    w:SetScript("OnShow", function()
        GoubayuHeal.Dispel_PrioRefresh()
    end)

    w:Hide()
    DispelPrioWin = w
    GoubayuHeal.Dispel_PrioClassFilterRefresh()

    return w
end

-- 刷新职业过滤开关：仅更新勾选状态与名字颜色（位置已在创建时按固定偏移定好）
-- by 武藤纯子酱 2026.9.4
function GoubayuHeal.Dispel_PrioClassFilterRefresh()
    local w = DispelPrioWin
    if not w or not w.classFilterButtons then
        return
    end
    for i, cf in ipairs(dispelClassList) do
        local c = w.classFilterButtons[i]
        if c then
            local on = GoubayuHeal.Dispel_ClassEnabled(cf)
            if c.sw and c.sw.SetChecked then
                c.sw:SetChecked(on)
            end
            if on then
                c.name:SetTextColor(c.cr, c.cg, c.cb)
            else
                c.name:SetTextColor(0.45, 0.45, 0.45)
            end
        end
    end
end

-- 刷新优先级窗口
function GoubayuHeal.Dispel_PrioRefresh()
    if not DispelPrioWin or not DispelPrioWin:IsShown() then
        return
    end

    if not GoubayuHeal.Config then
        return
    end

    GoubayuHeal.Config["dispel_player_priority"] = GoubayuHeal.Config[
        "dispel_player_priority"] or {}
    local pp = GoubayuHeal.Config["dispel_player_priority"]

    local names = {}
    local numRaid = GetNumRaidMembers()

    if numRaid > 0 then
        for i = 1, numRaid do
            local name, _, group = GetRaidRosterInfo(i)
            if name and group then
                names[table.getn(names) + 1] = { name = name, group = group }
            end
        end
    else
        if UnitExists("player") then
            names[table.getn(names) + 1] = { name = UnitName("player"), group = 1 }
        end
        for a = 1, GetNumPartyMembers() do
            local unit = "party" .. a
            if UnitExists(unit) and UnitIsFriend("player", unit) then
                names[table.getn(names) + 1] = { name = UnitName(unit), group = 1 }
            end
        end
    end

    local temp = {}
    for i = 1, 8 do
        temp[i] = 1
    end

    local filled = {}

    for _, member in ipairs(names) do
        local name = member.name
        local group = member.group

        if group and group >= 1 and group <= 8 then
            local slot = temp[group]
            temp[group] = temp[group] + 1

            if slot and slot <= 5 then
                filled[group .. "_" .. slot] = true

                local nm = getglobal("GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot .. "Name")
                local sl = getglobal("GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot
                    .. "PrioritySlider")
                local pct = getglobal("GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot
                    .. "PriorityPct")

                if nm then
                    nm:SetText(name)
                    nm:SetTextColor(0.9, 0.9, 0.9)
                end

                if sl then
                    local v = pp[name]
                    if v == nil then
                        v = 4
                        pp[name] = 4
                    end
                    v = tonumber(v) or 4

                    if v < 0 then
                        v = 0
                    end
                    if v > 8 then
                        v = 8
                    end

                    GoubayuHeal.Dispel_PrioSetSliderGray(sl, false)
                    sl:SetValue(v)

                    if pct then
                        pct:SetText(math.floor(v + 0.5))
                        if v == 0 then
                            pct:SetTextColor(1, 0.35, 0.2)
                        else
                            pct:SetTextColor(1, 1, 1)
                        end
                    end
                end
            end
        end
    end

    -- 空位
    for group = 1, 8 do
        for slot = 1, 5 do
            if not filled[group .. "_" .. slot] then
                local nm = getglobal("GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot .. "Name")
                local sl = getglobal("GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot
                    .. "PrioritySlider")
                local pct = getglobal("GoubayuHealDispelPrioGroup" .. group .. "Slot" .. slot
                    .. "PriorityPct")

                if nm then
                    nm:SetText(GoubayuHeal.Msg.RoleNone)
                    nm:SetTextColor(0.35, 0.35, 0.35)
                end

                if sl then
                    GoubayuHeal.Dispel_PrioSetSliderGray(sl, true)
                    sl:SetValue(4)
                    if pct then
                        pct:SetText("—")
                        pct:SetTextColor(0.45, 0.45, 0.45)
                    end
                end
            end
        end
    end

    GoubayuHeal.Dispel_BuildPrio()
    GoubayuHeal.Dispel_PrioClassFilterRefresh()
end

-- 开关优先级窗口
function GoubayuHeal.Dispel_TogglePrioWindow()
    if not DispelPrioWin then
        GoubayuHeal.Dispel_CreatePrioWindow()
    end

    if DispelPrioWin:IsShown() then
        DispelPrioWin:Hide()
    else
        DispelPrioWin:Show()
    end
end

-- ============================================================
-- 创建驱散窗口
-- ============================================================

function GoubayuHeal.Dispel_CreateWindow()
    if DispelWindow then
        return DispelWindow
    end

    local w = CreateFrame("Frame", "GoubayuHealDispelFrame", UIParent)
    w:SetWidth(200)
    w:SetHeight(5 * 42 + 40)
    local pos = GoubayuHeal.Config["dispel_window_pos"] or {}
    local posX = tonumber(pos.x)
    local posY = tonumber(pos.y)
    -- 未设置或旧版默认(0,0=窗口中心钉在左下角)时，归一化为屏幕正中
    if not posX or not posY or (posX == 0 and posY == 0) then
        posX = (UIParent:GetWidth() or 1024) / 2
        posY = (UIParent:GetHeight() or 768) / 2
        GoubayuHeal.Config["dispel_window_pos"] = { x = posX, y = posY }
    end
    w:SetPoint("CENTER", UIParent, "BOTTOMLEFT", posX, posY)
    w:SetClampedToScreen(true)

    -- 隐藏驱散窗口时收掉残留 tooltip（1.12 隐藏悬停中的窗口不触发 OnLeave）
    w:SetScript("OnHide", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
        if GoubayuHealDisplayTooltip then
            GoubayuHealDisplayTooltip:Hide()
        end
    end)

    DispelWindow = w

    -- 标题栏
    local title = w:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    title:SetTextColor(1, 0.565, 0)
    title:SetPoint("TOP", w, "TOP", 0, -10)
    title:SetText(GoubayuHeal.DispelUI.WindowTitle)
    w.title = title

    local hit = CreateFrame("Button", nil, w)
    hit:SetWidth(120)
    hit:SetHeight(30)
    hit:SetPoint("TOPLEFT", w, "TOPLEFT", 10, -2)
    hit:RegisterForClicks("LeftButtonDown")

    hit:SetScript("OnMouseDown", function()
        if w:IsMovable() then
            w:StartMoving()
        end
    end)

    hit:SetScript("OnMouseUp", function()
        if not w:IsMovable() then
            return
        end
        w:StopMovingOrSizing()
        local x, y = w:GetCenter()
        GoubayuHeal.Config["dispel_window_pos"].x = x or 0
        GoubayuHeal.Config["dispel_window_pos"].y = y or 0
    end)
    w.hit = hit

    -- 扁平小按钮
    local function GoubayuHealDispel_SmallBtn(parent, text)
        local btn = CreateFrame("Button", nil, parent)
        btn:SetWidth(20)
        btn:SetHeight(20)

        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        btn:SetBackdropColor(0.055, 0.055, 0.055, 0.98)
        btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

        local t = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        t:SetTextColor(1, 1, 1)
        t:SetPoint("CENTER", btn, "CENTER", 0, 0)
        t:SetText(text)
        btn.text = t

        btn:SetScript("OnEnter", function()
            btn:SetBackdropColor(0.32, 0.19, 0.02, 1)
            t:SetTextColor(1, 0.565, 0)
        end)

        btn:SetScript("OnLeave", function()
            btn:SetBackdropColor(0.055, 0.055, 0.055, 0.98)
            t:SetTextColor(1, 1, 1)
        end)

        return btn
    end

    -- 优先级按钮
    local prioBtn = GoubayuHealDispel_SmallBtn(w, GoubayuHeal.DispelUI.ButtonPriority)
    prioBtn:SetWidth(46)
    prioBtn:SetPoint("TOPRIGHT", w, "TOPRIGHT", -6, -2)

    prioBtn:SetScript("OnClick", function()
        if GoubayuHeal.Dispel_TogglePrioWindow then
            GoubayuHeal.Dispel_TogglePrioWindow()
        end
    end)
    w.prioBtn = prioBtn

    -- debuff 按钮（最多15个）
    for i = 1, 15 do
        local b = CreateFrame("Button", "GoubayuHealDispelDebuff" .. i, w)
        b:SetWidth(190)
        b:SetHeight(42)

        b:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = true,
            tileSize = 8,
            edgeSize = 1,
            insets = { left = 2, right = 2, top = 2, bottom = 2 }
        })
        b:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
        b:SetBackdropBorderColor(0.35, 0.35, 0.35, 0.9)

        local icon = b:CreateTexture(nil, "BORDER")
        icon:SetWidth(32)
        icon:SetHeight(32)
        icon:SetPoint("LEFT", b, "LEFT", 10, 0)

        local border = b:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-Debuff-Overlays")
        border:SetWidth(34)
        border:SetHeight(32)
        border:SetPoint("CENTER", icon, "CENTER", 0, 0)
        border:SetTexCoord(0.296875, 0.5703125, 0, 0.515625)

        local player = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        player:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        player:SetTextColor(0.9, 0.9, 0.9)
        player:SetPoint("TOPLEFT", icon, "TOPRIGHT", 5, 2)
        player:SetJustifyH("LEFT")

        local name = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        name:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        name:SetTextColor(1, 1, 1)
        name:SetPoint("LEFT", icon, "RIGHT", 5, -10)
        name:SetJustifyH("LEFT")

        local count = b:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
        count:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        count:SetTextColor(1, 0, 0)

        local typeText = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        typeText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        typeText:SetPoint("RIGHT", b, "RIGHT", -8, 0)
        typeText:SetJustifyH("RIGHT")

        b.icon = icon
        b.border = border
        b.player = player
        b.name = name
        b.count = count
        b.typeText = typeText

        b:SetScript("OnClick", function()
            GoubayuHeal.Dispel_Cleanse(this.entry, true)
        end)

        b:SetScript("OnEnter", function()
            this:SetBackdropColor(0.16, 0.16, 0.16, 0.98)

            if this.entry then
                GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
                if this.entry.spellId and this.entry.spellId > 0 and GameTooltip.SetSpellByID then
                    GameTooltip:SetSpellByID(this.entry.spellId)
                elseif this.entry.debuffIndex and this.entry.debuffIndex > 0 then
                    GameTooltip:SetUnitDebuff(this.entry.unit, this.entry.debuffIndex)
                else
                    GameTooltip:SetText(this.entry.debuffName or "")
                end
                GameTooltip:Show()
            end
        end)

        b:SetScript("OnLeave", function()
            GameTooltip:Hide()
            this:SetBackdropColor(0.09, 0.09, 0.09, 0.95)
        end)

        DispelButtons[i] = b
        b:Hide()
    end

    w:SetScript("OnUpdate", function()
        -- 1.12 的 OnUpdate 回调无参数，elapsed 通过全局 arg1 传入；
        -- 不能写成 function(arg1)，形参会遮蔽全局 arg1 导致恒为 nil（扫描退化为每帧全量执行）
        GoubayuHeal.Dispel_OnUpdate(arg1)
    end)

    GoubayuHeal.Dispel_ApplyWindowStyle()

    w.hidden = GoubayuHeal.Config["dispel_hidden"] or 0
    if w.hidden == 1 then
        w:Hide()
    end

    return w
end

-- ============================================================
-- 启用/隐藏窗口
-- ============================================================

function GoubayuHeal.Dispel_ApplyEnabled()
    if not GoubayuHeal.Config then
        return
    end

    if GoubayuHeal.Config["dispel_enabled"] == 1 then
        GoubayuHeal.Dispel_CreateWindow()

        if DispelWindow then
            DispelWindow.hidden = GoubayuHeal.Config["dispel_hidden"] or 0
            if DispelWindow.hidden ~= 1 then
                DispelWindow:Show()
            end
        end
    elseif DispelWindow then
        DispelWindow:Hide()
    end
end

function GoubayuHeal.Dispel_ApplyHidden()
    if not DispelWindow or not GoubayuHeal.Config then
        return
    end

    DispelWindow.hidden = GoubayuHeal.Config["dispel_hidden"] or 0

    if DispelWindow.hidden == 1 then
        DispelWindow:Hide()
    elseif GoubayuHeal.Config["dispel_enabled"] == 1 then
        DispelWindow:Show()
    end
end