-- ============================================================
-- 文件名: GoubayuHeal.lua
-- 功能: 插件主逻辑
--       包含天赋缓存、法术查询、单位数据查询等
--       统一治疗决策核心、Nampower门控等
--       治疗执行函数、优先级计算、法术缩放等
--       命令系统、事件处理、UI刷新等
-- ============================================================

-- ============================================================
-- 天赋信息缓存
-- ============================================================

local _talent_cache = {}
local GoubayuHeal_has_unitxp

-- 获取指定天赋栏位的当前点数（带缓存）
local function GoubayuHeal_GetTalentRank(tab, index)
    local key = tab * 100 + index
    if not _talent_cache[key] then
        -- 冷启动登录时天赋数据可能未就绪，GetTalentInfo 抛错会中断整个解析流程
        local ok, _, _, _, _, rank = pcall(GetTalentInfo, tab, index)
        _talent_cache[key] = (ok and rank) or 0
    end
    return _talent_cache[key]
end

-- 清空天赋缓存（天赋变更后调用）
local function GoubayuHeal_ClearTalentCache()
    _talent_cache = {}
end

-- 德鲁伊"庇佑"天赋等级（3树13号）：供施放愈合时打标（Hooks.lua）与迅捷治愈换算
function GoubayuHeal.GetBenevolenceRank()
    return GoubayuHeal_GetTalentRank(3, 13)
end

-- 施放愈合时打标：记录 目标是否有回春 + 自身是否有庇佑天赋（该愈合HOT是否被+30%）
-- 迅捷治愈吃愈合时无法从 buff 判断（庇佑是隐藏效果），故按本次施放的状态换算
function GoubayuHeal.MarkRegrowthCast(unit)
    if not unit then
        return
    end
    local tname = GoubayuHeal.UnitName(unit)
    if not tname then
        return
    end
    local amp = (GoubayuHeal.GetBenevolenceRank() > 0
        and GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Rejuvenation)) and true or false
    GoubayuHeal.regrowth_mark = GoubayuHeal.regrowth_mark or {}
    GoubayuHeal.regrowth_mark[tname] = { amp = amp, t = GetTime() }
end

-- 目标身上的愈合是否被庇佑强化（按施放时的打标；30秒内有效，超过视为过期）
function GoubayuHeal.IsRegrowthAmplified(unit)
    local mark = GoubayuHeal.regrowth_mark
    if not (mark and unit) then
        return false
    end
    local tname = GoubayuHeal.UnitName(unit)
    local m = tname and mark[tname]
    if not m then
        return false
    end
    if (GetTime() - (m.t or 0)) > 30 then
        return false
    end
    return m.amp == true
end

-- ============================================================
-- 法术冷却查询
-- ============================================================

-- 获取用于CD查询的法术ID：优先真实SpellId（有Nampower时优先用spellid），槽位号作为回退
function GoubayuHeal.GetSpellCDId(rankData)
    if type(rankData) == "table" then
        if rankData["SpellId"] and type(rankData["SpellId"]) == "number" and rankData["SpellId"] > 0 then
            return rankData["SpellId"]
        end
        return rankData["ID"]
    end
    return rankData
end

function GoubayuHeal.GetSpellCooldown(spellId)
    if not spellId then
        return 0
    end

    -- Nampower优先：GetSpellIdCooldown 需要真实法术ID（槽位号），GetSpellBookItemInfo 转真实ID；已是真实ID则直接使用
    if GetSpellIdCooldown then
        local realId = spellId
        if type(spellId) == "number" and GetSpellBookItemInfo then
            local ok, stype, sid = pcall(GetSpellBookItemInfo, spellId, BOOKTYPE_SPELL)
            if ok and stype == "SPELL" and type(sid) == "number" and sid > 0 then
                realId = sid
            end
            -- 转换失败：原值可能是真实ID（如 Paladin FindSpellID），直接用原值；若为无效槽位号，GetSpellIdCooldown 会返回无效值，回退原生
        end
        local ok, cd = pcall(GetSpellIdCooldown, realId)
        if ok and cd and cd.isOnCooldown and cd.isOnCooldown == 1
            and cd.cooldownRemainingMs and cd.cooldownRemainingMs > 0 then
            return cd.cooldownRemainingMs / 1000
        end
    end

    -- 原生回退：GetSpellCooldown(槽位号)；pcall 防止传入真实ID时报错
    local okN, start, duration = pcall(GetSpellCooldown, spellId, BOOKTYPE_SPELL)
    if okN and start and duration and duration > 0 then
        return start + duration - GetTime()
    end
    return 0
end

-- 法术书槽位缓存：spellName → 槽位（false=未找到）
local GoubayuHeal_SpellSlotCache = {}
function GoubayuHeal.GetSpellBookSlot(spellName)
    if not spellName then
        return nil
    end
    if GoubayuHeal_SpellSlotCache[spellName] ~= nil then
        return GoubayuHeal_SpellSlotCache[spellName]
    end
    local j = 1
    while true do
        local s = GetSpellName(j, BOOKTYPE_SPELL)
        if not s then
            break
        end
        if s == spellName then
            GoubayuHeal_SpellSlotCache[spellName] = j
            return j
        end
        j = j + 1
    end
    GoubayuHeal_SpellSlotCache[spellName] = false
    return nil
end

-- GCD/公共冷却预检：法术当前在GCD/冷却中时返回true（此时施放会失败，施放前应跳过/不施放）
-- 用原生 GetSpellCooldown(槽位) 判定：1.12 中公共冷却会反映在槽位冷却上（与心灵之火修复同口径）
function GoubayuHeal.IsSpellOnCooldown(spellName)
    local slot = GoubayuHeal.GetSpellBookSlot(spellName)
    if not slot then
        return false
    end
    local okN, start, duration = pcall(GetSpellCooldown, slot, BOOKTYPE_SPELL)
    if okN and start and duration and duration > 0 then
        return true
    end
    return false
end

-- ============================================================
-- 单位GUID查询（1.12无UnitGUID，用Nampower GetUnitGUID）
-- ============================================================

function GoubayuHeal.GetUnitGUID(unit)
    if GetNampowerVersion and GetUnitGUID then
        return GetUnitGUID(unit)
    end
    return nil
end

-- 从GUID反查单位名
function GoubayuHeal.UnitNameFromGUID(guid)
    if not guid then
        return nil
    end
    if GetNampowerVersion and UnitName then
        local name = UnitName(guid)
        if name and name ~= "" then
            return name
        end
    end
    return nil
end

-- ============================================================
-- GCD/施法模型（事件驱动，非Nampower不逐帧轮询）
-- ============================================================

function GoubayuHeal.GetGCDDuration()
    if GoubayuHeal.my_class == GoubayuHeal.Rogue then
        return 1.0
    end
    if GoubayuHeal.my_class == GoubayuHeal.Druid
        and UnitPowerType and UnitPowerType("player") ~= 0 then
        return 1.0
    end
    return 1.5
end

function GoubayuHeal.GetLeftGCD()
    if GoubayuHeal.gcd_start and GoubayuHeal.gcd_duration then
        return GoubayuHeal.gcd_start + GoubayuHeal.gcd_duration - GetTime()
    end
    return 0
end

function GoubayuHeal.IsCasting()
    return (GoubayuHeal.casting_spell ~= nil) or (GoubayuHeal.GetLeftGCD() > 0)
end

-- ============================================================
-- 位与运算（兼容Lua 5.0）
-- ============================================================

local function GoubayuHeal_BitAnd(a, b)
    if bit and bit.band then
        return bit.band(a, b)
    end
    local mod = math.mod
    local r = 0
    local i = 0
    while a > 0 or b > 0 do
        if mod(a, 2) == 1 and mod(b, 2) == 1 then
            r = r + 2 ^ i
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        i = i + 1
    end
    return r
end

-- ============================================================
-- 法术最高等级查询
-- ============================================================

local function GoubayuHeal_GetHighestRankStr(spell)
    local ranks = GoubayuHeal.Spells[spell]
    if not ranks then
        return "1"
    end
    local bestNum, bestStr = 0, nil
    for r, _ in pairs(ranks) do
        local rn = tonumber(r) or 0
        if rn > bestNum then
            bestNum, bestStr = rn, r
        end
    end
    return bestStr or "1"
end

-- ============================================================
-- 单位生命值查询
-- ============================================================

function GoubayuHeal.GetUnitHealth(unit)
    if not unit then
        return 0, 0
    end
    if (GetNampowerVersion and GetUnitField) then
        local health = GetUnitField(unit, "health")
        local maxHealth = GetUnitField(unit, "maxHealth")
        if (health and maxHealth and maxHealth > 0) then
            return health, maxHealth
        end
    end
    return UnitHealth(unit), UnitHealthMax(unit)
end

-- ============================================================
-- 玩家移动检测
-- ============================================================

function GoubayuHeal.IsMoving()
    if (GetNampowerVersion and PlayerIsMoving) then
        return (PlayerIsMoving() == 1)
    end
    return (GoubayuHeal.MPPlayerIsMoving == true)
end

-- ============================================================
-- Buff/Debuff检测（按名称）
-- ============================================================

-- 法术ID→名称统一缓存（会话内，不持久化；Nampower GetSpellNameAndRankForId）
function GoubayuHeal.GetSpellNameFromId(id)
    if not id then
        return nil
    end
    if not GetNampowerVersion then
        return nil
    end
    local cache = GoubayuHeal.spell_id_name_cache or {}
    GoubayuHeal.spell_id_name_cache = cache
    local v = cache[id]
    if v == nil then
        local ok, nm = pcall(GetSpellNameAndRankForId, id)
        v = ok and nm or false
        cache[id] = v
    end
    return v or nil
end

function GoubayuHeal.HasBuffByName(unit, buffName, checkDebuff)
    if not unit or not buffName then
        return false
    end

    if GetNampowerVersion and GetUnitField and GetSpellNameAndRankForId then
        local nameCache = GoubayuHeal.spell_id_name_cache or {}
        GoubayuHeal.spell_id_name_cache = nameCache

        local auras = GetUnitField(unit, "aura")
        if auras then
            local limit = checkDebuff and 48 or 32
            for i = 1, limit do
                local id = auras[i]
                if id and id ~= 0 then
                    local name = nameCache[id]
                    if name == nil then
                        local ok, nm = pcall(GetSpellNameAndRankForId, id)
                        name = ok and nm or false
                        nameCache[id] = name
                    end
                    if name == buffName then
                        return true
                    end
                end
            end
            return false
        end
    end

    -- 原生API遍历buff
    if UnitBuff then
        for i = 1, 32 do
            local texture = UnitBuff(unit, i)
            if not texture then
                break
            end
            local name = GoubayuHeal.GetBuffData(unit, i)
            if name and name == buffName then
                return true
            end
        end
    end

    -- 原生API遍历debuff
    if checkDebuff and UnitDebuff then
        for i = 1, 32 do
            local texture = UnitDebuff(unit, i)
            if not texture then
                break
            end
            local name = GoubayuHeal.GetDebuffData(unit, i)
            if name and name == buffName then
                return true
            end
        end
    end

    return false
end

-- ============================================================
-- 萨满：保持水之护盾
-- ============================================================

function GoubayuHeal.EnsureWaterShield()
    if not (GoubayuHeal.my_class == GoubayuHeal.Shaman
        and GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
        and GoubayuHeal.Config["shaman_totem"].keep_water_shield == 1) then
        return false
    end

    -- 读条中不放（施放会失败却写10秒节流）
    if GoubayuHeal.casting_spell then
        return false
    end

    if GoubayuHeal.HasBuffByName("player", GoubayuHeal.Msg.WaterShieldZH)
        or GoubayuHeal.HasBuffByName("player", GoubayuHeal.Msg.WaterShieldEN) then
        return true
    end

    -- buff栏满且刚发生过加buff动作、之后无buff移除（无空槽）：施放水盾会无效，不再重复施放
    if GoubayuHeal.IsBuffBarFull("player") then
        local ba = GoubayuHeal._buff_add_time or 0
        local br = GoubayuHeal._buff_remove_time or 0
        if ba > br then
            return false
        end
    end

    -- 施放节流：刚放过（10秒内）不再重复，避免施放后buff尚未注册到aura时反复上
    if GoubayuHeal._water_shield_last and (GetTime() - GoubayuHeal._water_shield_last) < 10 then
        return false
    end

    local spellName = GoubayuHeal._water_shield_spell
    if not spellName then
        if GetNampowerVersion and GetSpellSlotTypeIdForName then
            local ok, slotType, spellId = pcall(GetSpellSlotTypeIdForName, GoubayuHeal.Msg.WaterShieldZH)
            if ok and spellId then
                spellName = GoubayuHeal.Msg.WaterShieldZH
            else
                local ok2, st2, id2 = pcall(GetSpellSlotTypeIdForName, GoubayuHeal.Msg.WaterShieldEN)
                if ok2 and id2 then
                    spellName = GoubayuHeal.Msg.WaterShieldEN
                end
            end
        end

        if not spellName then
            local j = 1
            while true do
                local spell = GetSpellName(j, BOOKTYPE_SPELL)
                if not spell then
                    break
                end
                if spell == GoubayuHeal.Msg.WaterShieldEN or spell == GoubayuHeal.Msg.WaterShieldZH then
                    spellName = spell
                    break
                end
                j = j + 1
            end
        end
        GoubayuHeal._water_shield_spell = spellName
    end

    -- GCD/冷却未就绪：不施放也不进节流（与心灵之火同理，防止"其他技能占GCD时
    -- 水盾施放失败却仍锁10秒"）
    if spellName and GoubayuHeal.IsSpellOnCooldown(spellName) then
        return false
    end

    if spellName then
        CastSpellByName(spellName)
        GoubayuHeal._water_shield_last = GetTime()
        return true
    end
    return false
end

-- ============================================================
-- 牧师：保持心灵之火
-- ============================================================

function GoubayuHeal.EnsureInnerFire()
    if not (GoubayuHeal.my_class == GoubayuHeal.Priest
        and GoubayuHeal.Config and GoubayuHeal.Config["priest_keep_inner_fire"] == 1) then
        return false
    end

    -- 读条中不放（施放会失败却写10秒节流）
    if GoubayuHeal.casting_spell then
        return false
    end

    if GoubayuHeal.HasBuffByName("player", GoubayuHeal.Inner_fire) then
        return true
    end

    -- buff栏满且刚发生过加buff动作、之后无buff移除（无空槽）：施放心灵之火会无效，
    -- 不再重复施放（反复上的根因）；一旦识别到buff移除（空出槽位）才允许施放
    if GoubayuHeal.IsBuffBarFull("player") then
        local ba = GoubayuHeal._buff_add_time or 0
        local br = GoubayuHeal._buff_remove_time or 0
        if ba > br then
            return false
        end
    end

    -- 施放节流：刚放过（10秒内）不再重复，避免施放后buff尚未注册到aura时反复上
    -- （心灵之火持续30分钟，10秒空窗无影响）
    if GoubayuHeal._inner_fire_last and (GetTime() - GoubayuHeal._inner_fire_last) < 10 then
        return false
    end

    local spellName = GoubayuHeal._inner_fire_spell
    if not spellName then
        -- 扫描法术书找到心灵之火的槽位（同时缓存名字与槽位供GCD检查）
        local j = 1
        while true do
            local s = GetSpellName(j, BOOKTYPE_SPELL)
            if not s then
                break
            end
            if s == GoubayuHeal.Inner_fire then
                spellName = s
                GoubayuHeal._inner_fire_slot = j
                break
            end
            j = j + 1
        end
        GoubayuHeal._inner_fire_spell = spellName
    end

    -- GCD/冷却未就绪：不施放也不进节流。
    -- 否则宏里先放其他技能（占GCD）时，本次施放会被GCD拒绝而失败，
    -- 但旧的逻辑仍记录节流时间 → 白白锁10秒（"先反恐后等10秒才上心灵之火"的根因）
    local slot = GoubayuHeal._inner_fire_slot
    if slot and GetSpellCooldown then
        local _, duration = GetSpellCooldown(slot, BOOKTYPE_SPELL)
        if duration and duration > 0 then
            return false
        end
    end

    if spellName then
        CastSpellByName(spellName)
        GoubayuHeal._inner_fire_last = GetTime()
        return true
    end
    return false
end

-- ============================================================
-- 牧师：绝望祷言自动施放
-- ============================================================

function GoubayuHeal.TryDesperatePrayer()
    if not (GoubayuHeal.my_class == GoubayuHeal.Priest and GoubayuHeal.Config) then
        return false
    end

    local pct = GoubayuHeal.Config["priest_desperate_prayer_pct"] or 0
    if not (pct and pct > 0) then
        return false
    end

    if not (GoubayuHeal.Spells and GoubayuHeal.Spells[GoubayuHeal.Desperate_prayer]) then
        return false
    end

    local h, mh = GoubayuHeal.GetUnitHealth("player")
    if not mh or mh <= 0 then
        return false
    end
    if (h / mh) * 100 >= pct then
        return false
    end

    local rank = table.getn(GoubayuHeal.Spells[GoubayuHeal.Desperate_prayer])
    if rank <= 0 or not GoubayuHeal.Spells[GoubayuHeal.Desperate_prayer][rank] then
        return false
    end
    if GoubayuHeal.SpellRankOutOfMana(GoubayuHeal.Desperate_prayer, rank) then
        return false
    end

    local cd = (GoubayuHeal.GetSpellCooldown(
        GoubayuHeal.GetSpellCDId(GoubayuHeal.Spells[GoubayuHeal.Desperate_prayer][rank])) or 0)
    if cd > 0 then
        return false
    end

    -- GCD未就绪时不施放也不打断（否则打断当前施法后，施放仍会因GCD失败，白白打断）
    if GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Desperate_prayer) then
        return false
    end

    if GoubayuHeal.casting_spell then
        SpellStopCasting()
    end

    local spell_with_rank = GoubayuHeal.BuildSpellWithRank(GoubayuHeal.Desperate_prayer, rank)
    if GetNampowerVersion then
        CastSpellByName(spell_with_rank, GoubayuHeal.GetUnitGUID("player"))
    else
        CastSpellByName(spell_with_rank)
    end
    GoubayuHeal.last_cast_spell = GoubayuHeal.Desperate_prayer
    return true
end

-- ============================================================
-- 圣骑士自救技能：圣佑术/ 圣盾术（仅对自身）
-- 血量低于各自滑块阈值时施放；施放前需判断技能CD与自律(Forbearance)debuff
-- ============================================================

function GoubayuHeal.TryDivineSelfSpell(spellVar, pctConfig)
    if not (GoubayuHeal.Config) then
        return false
    end
    local pct = tonumber(GoubayuHeal.Config[pctConfig]) or 0
    if pct <= 0 then
        return false
    end

    local spell = GoubayuHeal[spellVar]
    if not (spell and GoubayuHeal.Spells and GoubayuHeal.Spells[spell]) then
        return false
    end

    local h, mh = GoubayuHeal.GetUnitHealth("player")
    if not mh or mh <= 0 then
        return false
    end
    if (h / mh) * 100 >= pct then
        return false
    end

    -- 自律debuff：圣佑/圣盾/保护之手使用后进入自律，期间不能再施放
    if GoubayuHeal.UnitGotDebuff and GoubayuHeal.UnitGotDebuff("player", GoubayuHeal.Forbearance) then
        return false
    end

    local rank = table.getn(GoubayuHeal.Spells[spell])
    if rank <= 0 or not GoubayuHeal.Spells[spell][rank] then
        return false
    end
    if GoubayuHeal.SpellRankOutOfMana(spell, rank) then
        return false
    end

    local cd = (GoubayuHeal.GetSpellCooldown(
        GoubayuHeal.GetSpellCDId(GoubayuHeal.Spells[spell][rank])) or 0)
    if cd > 0 then
        return false
    end

    -- GCD未就绪时不施放也不打断（否则打断当前施法后，施放仍会因GCD失败，白白打断）
    if GoubayuHeal.IsSpellOnCooldown(spell) then
        return false
    end

    if GoubayuHeal.casting_spell then
        SpellStopCasting()
    end

    local spell_with_rank = GoubayuHeal.BuildSpellWithRank(spell, rank)
    if GetNampowerVersion then
        CastSpellByName(spell_with_rank, GoubayuHeal.GetUnitGUID("player"))
    else
        CastSpellByName(spell_with_rank)
    end
    GoubayuHeal.last_cast_spell = spell
    return true
end

function GoubayuHeal.TryDivineShield()
    return GoubayuHeal.TryDivineSelfSpell("Divine_shield", "paladin_divine_shield_pct")
end

function GoubayuHeal.TryDivineProtection()
    return GoubayuHeal.TryDivineSelfSpell("Divine_protection", "paladin_divine_protection_pct")
end

-- ============================================================
-- 拼"技能名(等级 N)"施法串（统一口径）
-- ============================================================

-- 拼"技能名(等级 N)"施法串（统一口径，不做白名单）
-- 规则：按法术书识别——该技能在法术书里只有一条等级条目时（无等级天赋：迅捷治愈/自然迅捷/
-- 先祖迅捷；以及高等级自动覆盖、只剩最高级的圣疗术），裸名施放；有多个同名等级条目时才带
-- "(等级 N)"后缀，按方案选的等级施放。
-- by 武藤纯子酱 2026.9.21
function GoubayuHeal.BuildSpellWithRank(spell, rank, nameOverride)
    if not spell then
        return nil
    end

    local name = nameOverride or spell
    local rankCount = (GoubayuHeal.Spells and GoubayuHeal.Spells[spell])
        and table.getn(GoubayuHeal.Spells[spell]) or 0

    if rankCount <= 1 then
        return name
    end

    return name .. "(" .. GoubayuHeal.RANK .. " " .. rank .. ")"
end

-- ============================================================
-- 自然迅捷/祖先迅捷附件施放
-- ============================================================

function GoubayuHeal.CastSwiftnessAttachment(attachment)
    if not (attachment and GoubayuHeal.Spells and GoubayuHeal.Spells[attachment]) then
        return
    end

    -- 已有迅捷buff（尚未被下一次法术消耗）时不重复施放，避免白白消耗3分钟CD
    -- by 武藤纯子酱 2026.9.21
    if GoubayuHeal.HasBuffByName and GoubayuHeal.HasBuffByName("player", attachment) then
        return
    end

    local spellID = nil
    for r, data in pairs(GoubayuHeal.Spells[attachment]) do
        if type(data) == "table" and (data["SpellId"] or data["ID"]) then
            spellID = GoubayuHeal.GetSpellCDId(data)
            break
        end
    end

    if spellID and ((GoubayuHeal.GetSpellCooldown(spellID) or 0) == 0) then
        CastSpellByName(attachment)
    elseif not spellID then
        -- spellId 未取到（无等级技能反查失败）：按名字直接施放，由客户端判定CD/未就绪
        CastSpellByName(attachment)
    end
end

-- ============================================================
-- 德鲁伊：保持生命之树形态
-- ============================================================

function GoubayuHeal.FindTreeFormIndex()
    if GoubayuHeal.TreeFormIndex then
        return GoubayuHeal.TreeFormIndex
    end

    local idx = 0
    if GetShapeshiftFormInfo then
        for i = 1, 9 do
            local icon, name = GetShapeshiftFormInfo(i)
            if name then
                if name == GoubayuHeal.Tree_of_life
                    or name == GoubayuHeal.Tree_of_life_short
                    or (icon and icon == "Interface\\Icons\\Ability_Druid_TreeofLife") then
                    idx = i
                    break
                end
            end
        end
    end
    GoubayuHeal.TreeFormIndex = idx
    return idx
end

function GoubayuHeal.EnsureTreeOfLife()
    if GoubayuHeal.my_class ~= GoubayuHeal.Druid then
        return
    end

    if not (GoubayuHeal.Config and GoubayuHeal.Config["druid_keep_tree_of_life"] == 1) then
        return
    end

    -- 已处于任意形态时，不干扰
    if GetShapeshiftFormInfo then
        for i = 1, 9 do
            local _, _, active = GetShapeshiftFormInfo(i)
            if active then
                return
            end
        end
    end

    -- 施法者形态时切换生命之树（GCD未就绪不施放，静默跳过待下轮）
    local idx = GoubayuHeal.FindTreeFormIndex()
    if idx > 0 and CastShapeshiftForm then
        if GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Tree_of_life) then
            return
        end
        CastShapeshiftForm(idx)
    elseif GoubayuHeal.Spells and GoubayuHeal.Spells[GoubayuHeal.Tree_of_life] then
        if GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Tree_of_life) then
            return
        end
        CastSpellByName(GoubayuHeal.Tree_of_life)
    end
end

-- ============================================================
-- 治疗链辅助函数
-- ============================================================

-- 按目标血量选择治疗链目标
function GoubayuHeal.PickChainEntryForHP(chainEntries, hpPercent)
    if not chainEntries then
        return nil
    end
    local best = nil
    local bestThreshold = 999
    for pct, data in chainEntries do
        local p = tonumber(pct) or 0
        if p > hpPercent and p < bestThreshold then
            best = data
            bestThreshold = p
        end
    end
    return best
end

-- 牧师"疾速只强效"：按血量选择强效治疗术等级
function GoubayuHeal.PickForceGreaterHealRank(class, hpPercent)
    local cfg = GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][class]
    if not cfg then
        return 1
    end

    local best = nil
    local bestThreshold = 999
    for pct, data in cfg do
        if type(data) == "table" and data["Spell"] == GoubayuHeal.Greater_heal then
            local p = tonumber(pct) or 0
            if p > hpPercent and p < bestThreshold then
                best = tonumber(data["Rank"]) or 1
                bestThreshold = p
            end
        end
    end
    return best or 1
end

-- 找与治疗链同等治疗量的治疗波/次级治疗波等级（waveSpell 缺省为治疗波）
function GoubayuHeal.FindEquivalentWaveRank(chainSpell, chainRank, waveSpell)
    if not (GoubayuHeal.Spells and GoubayuHeal.Spells[chainSpell]
        and GoubayuHeal.Spells[chainSpell][chainRank]) then
        return nil
    end

    local chainData = GoubayuHeal.Spells[chainSpell][chainRank]
    local chainHeal = ((chainData["HealMin"] or 0) + (chainData["HealMax"] or 0)) / 2
    if chainHeal <= 0 then
        chainHeal = chainData["Heal"] or 0
    end

    waveSpell = waveSpell or GoubayuHeal.Healing_wave
    if not (GoubayuHeal.Spells and GoubayuHeal.Spells[waveSpell]) then
        return nil
    end

    -- 治疗波各级数值可能缺失（tooltip 解析失败时 Heal/HealMin/HealMax 全为 0）：
    -- 缺失等级不能参与"最接近"比较（否则差值为常数、恒选 1 级），应忽略；若全部缺失则退回最高级
    -- by 武藤纯子酱 2026.9.21
    local bestRank = nil
    local bestDiff = 999999
    local maxRank = nil
    local maxRankNum = -1
    for r, data in pairs(GoubayuHeal.Spells[waveSpell]) do
        if type(data) == "table" then
            local rNum = tonumber(r) or 1
            if rNum > maxRankNum then
                maxRankNum = rNum
                maxRank = r
            end
            local wHeal = ((data["HealMin"] or 0) + (data["HealMax"] or 0)) / 2
            if wHeal <= 0 then
                wHeal = data["Heal"] or 0
            end
            if wHeal > 0 then
                local diff = math.abs(wHeal - chainHeal)
                if diff < bestDiff then
                    bestDiff = diff
                    bestRank = r
                end
            end
        end
    end
    return bestRank or maxRank
end

-- ============================================================
-- 统一治疗决策核心
-- ============================================================

-- 群疗条件覆盖：返回指定群疗技能的 { range, count, missing }（用户覆盖优先，否则内置默认）
-- 新星(10码/天赋至12、5人、>300)、祷言(30码、3人、>600)、神圣打击(10码、3人、>200)
function GoubayuHeal.GetAoECondition(spell, defaults)
    local d = defaults or { range = 10, count = 5, missing = 300 }
    local ovr = GoubayuHeal.Config and GoubayuHeal.Config["aoe_condition_override"]
        and GoubayuHeal.Config["aoe_condition_override"][spell]
    if ovr then
        return {
            range = tonumber(ovr.range) or d.range,
            count = tonumber(ovr.count) or d.count,
            missing = tonumber(ovr.missing) or d.missing,
        }
    end
    return d
end

-- 8T2套装：强效治疗术自带5级恢复HOT（HOT名"强效治疗术"，数值/时长/法伤加成与5级恢复一致）。
-- 返回强效治疗术该等级的总治疗量（直接治疗+5级恢复HOT×hotFactor）；
-- 非8T2开启或库中没有强效治疗术/恢复时返回 nil
-- hotFactor：HOT 跳不完的折算比例（团刷对比用 0.5）
function GoubayuHeal.GetGHPlusRenewHeal(unit, rank, hotFactor)
    if not (GoubayuHeal.Config and GoubayuHeal.Config["priest_8t2"] == 1) then
        return nil
    end
    if not (GoubayuHeal.Spells and GoubayuHeal.Spells[GoubayuHeal.Greater_heal]
        and GoubayuHeal.Spells[GoubayuHeal.Greater_heal][rank]
        and GoubayuHeal.Spells[GoubayuHeal.Renew]
        and GoubayuHeal.Spells[GoubayuHeal.Renew][5]) then
        return nil
    end
    local gh, _, _, ghHot = GoubayuHeal.GetSpellHealing(unit, GoubayuHeal.Greater_heal, rank)
    local _, _, _, r5Hot = GoubayuHeal.GetSpellHealing(unit, GoubayuHeal.Renew, 5)
    local factor = hotFactor or 0.5
    return (gh or 0) + (r5Hot or 0) * factor
end

function GoubayuHeal.HealMostWoundedUnified(profileName, contextUnit)
    local cfg = GoubayuHeal.Config["classes"][profileName]
    if not cfg then
        return
    end

    -- 按法术类型分类配置条目
    local hasNova, hasPrayer, hasChain, hasTranquility = false, false, false, false
    local hasHolyStrike = false
    local novaThreshold, prayerThreshold = 0, 0
    local novaEntries, prayerEntries, singleEntries, chainEntries = {}, {}, {}, {}
    local tranquilityEntries = {}
    local hsEntries = {}

    for percent, data in cfg do
        if type(data) == "table" then
            local spell = data["Spell"]
            if spell == GoubayuHeal.Holy_nova then
                hasNova = true
                novaEntries[percent] = data
                if (percent / 100) > novaThreshold then
                    novaThreshold = percent / 100
                end
            elseif spell == GoubayuHeal.Holy_Strike then
                -- 神圣打击群疗：条目百分比=本档触发血线（评估处升序取最低满足档）；需近战可攻击目标
                hasHolyStrike = true
                hsEntries[percent] = data
            elseif spell == GoubayuHeal.Prayer_of_healing then
                hasPrayer = true
                prayerEntries[percent] = data
                if (percent / 100) > prayerThreshold then
                    prayerThreshold = percent / 100
                end
            elseif spell == GoubayuHeal.Chain_heal then
                hasChain = true
                chainEntries[percent] = data
                -- 同时作为单体条目：链评估(ChainHeal_SelectBestTarget)失败时不阻塞治疗链的按档位施放
                singleEntries[percent] = data
            elseif spell == GoubayuHeal.Tranquility then
                -- 宁静为大范围引导AOE：不按单体施放，按团队大掉血条件触发
                hasTranquility = true
                tranquilityEntries[percent] = data
            else
                singleEntries[percent] = data
            end
        end
    end

    -- 处理单体条目中的Attachment（自动注册为群疗条目）
    for pct, data in pairs(singleEntries) do
        local att = data["Attachment"]
        if att and GoubayuHeal.Spells[att] then
            local pnum = tonumber(pct) or 0
            local pctKey = tostring(pnum)

            if att == GoubayuHeal.Prayer_of_healing then
                hasPrayer = true
                if not (prayerEntries[pctKey] and prayerEntries[pctKey]["Spell"] == att) then
                    prayerEntries[pctKey] = {
                        Spell = att,
                        Rank = data["AttachmentRank"] or GoubayuHeal_GetHighestRankStr(att),
                        Scale = 0,
                        Attachment = nil
                    }
                end
                if (pnum / 100) > prayerThreshold then
                    prayerThreshold = pnum / 100
                end
            elseif att == GoubayuHeal.Holy_nova then
                hasNova = true
                if not (novaEntries[pctKey] and novaEntries[pctKey]["Spell"] == att) then
                    novaEntries[pctKey] = {
                        Spell = att,
                        Rank = data["AttachmentRank"] or GoubayuHeal_GetHighestRankStr(att),
                        Scale = 0,
                        Attachment = nil
                    }
                end
                if (pnum / 100) > novaThreshold then
                    novaThreshold = pnum / 100
                end
            elseif att == GoubayuHeal.Holy_Strike then
                -- 挂接神圣打击：像新星挂接一样注册为群疗条目（触发另需近战可攻击目标）
                hasHolyStrike = true
                if not (hsEntries[pctKey] and hsEntries[pctKey]["Spell"] == att) then
                    hsEntries[pctKey] = {
                        Spell = att,
                        Rank = data["AttachmentRank"] or GoubayuHeal_GetHighestRankStr(att),
                        Scale = 0,
                        Attachment = nil
                    }
                end
            elseif att == GoubayuHeal.Chain_heal then
                hasChain = true
                if not (chainEntries[pctKey] and chainEntries[pctKey]["Spell"] == att) then
                    chainEntries[pctKey] = {
                        Spell = att,
                        Rank = data["AttachmentRank"] or GoubayuHeal_GetHighestRankStr(att),
                        Scale = 0,
                        Attachment = nil
                    }
                end
            elseif att == GoubayuHeal.Tranquility then
                hasTranquility = true
                if not (tranquilityEntries[pctKey] and tranquilityEntries[pctKey]["Spell"] == att) then
                    tranquilityEntries[pctKey] = {
                        Spell = att,
                        Rank = data["AttachmentRank"] or GoubayuHeal_GetHighestRankStr(att),
                        Scale = 0,
                        Attachment = nil
                    }
                end
            end
        end
    end

    -- 无新星/祷言/宁静/神圣打击类群疗配置时：直接按方案档位施放（治疗链也按档位，不做链评估评分）
    if not (hasNova or hasPrayer or hasTranquility or hasHolyStrike) then
        if contextUnit then
            return GoubayuHeal.HealUsingClass(contextUnit, profileName,
                GoubayuHeal.GetHealValue(contextUnit))
        end
        return GoubayuHeal.HealMostWoundedTB(profileName, nil)
    end

    -- 不创建 _T/_S/_D 临时子方案，评分决策后直接施放对应技能

    local function distBetween(u1, u2)
        if (UnitIsUnit and UnitIsUnit(u1, u2)) or u1 == u2 then
            return 0
        end
        if UnitXP and type(UnitXP) == "function" then
            local g1 = GoubayuHeal.GetUnitGUID(u1)
            local g2 = GoubayuHeal.GetUnitGUID(u2)
            if g1 and g2 then
                local d = UnitXP("distanceBetween", g1, g2)
                if d and type(d) == "number" then
                    return d
                end
            end
        end
        if CheckInteractDistance(u2, 4) then
            return 27
        elseif CheckInteractDistance(u2, 2) then
            return 8
        elseif CheckInteractDistance(u2, 1) then
            return 7
        end
        return 100
    end

    local function partyIndex(unit)
        local raidIndex = string.match(unit, "^raid(%d+)$")
        if raidIndex then
            raidIndex = tonumber(raidIndex)
            local name, rank, subgroup = GetRaidRosterInfo(raidIndex)
            if subgroup then
                return subgroup
            end
            return math.floor((raidIndex - 1) / 5) + 1
        end
        if UnitIsUnit(unit, "player") then
            local myName = GoubayuHeal.my_name or UnitName("player")
            for i = 1, GetNumRaidMembers() do
                local name, rank, subgroup = GetRaidRosterInfo(i)
                if name and name == myName then
                    return subgroup
                end
            end
            return 1
        end
        return nil
    end

    local targets = {}
    if GoubayuHeal.CanHeal("player") then
        table.insert(targets, "player")
    end

    local n = GetNumRaidMembers()
    local por = "raid"
    if n == 0 then
        n = GetNumPartyMembers()
        por = "party"
    end
    for a = 1, n do
        local u = por .. a
        if UnitExists(u) and GoubayuHeal.CanHeal(u) then
            table.insert(targets, u)
        end
    end

    local function prio(u)
        return GoubayuHeal.GetPriority(u) or 1
    end

    local function deficit(u)
        local h, maxh = GoubayuHeal.GetUnitHealth(u)
        local miss = maxh - h
        -- 减去自身在读治疗对目标的恢复量：在读治疗落地后缺口减小，避免对快满目标重复治疗
        local tname = GoubayuHeal.UnitName(u)
        if GoubayuHeal.healing and GoubayuHeal.healing[tname]
            and GoubayuHeal.healing[tname][GoubayuHeal.my_name]
            and GoubayuHeal.healing[tname][GoubayuHeal.my_name]["Status"] == "Active" then
            local rec = GoubayuHeal.healing[tname][GoubayuHeal.my_name]
            miss = miss - (rec["Heal"] or 0) - (rec["HealingOverTime"] or 0) / 4
            if miss < 0 then
                miss = 0
            end
        end
        return miss
    end

    local function highestEntry(tbl)
        local best, bestPct = nil, 0
        for pct, data in tbl do
            local p = tonumber(pct) or 0
            if p >= bestPct then
                best, bestPct = data, p
            end
        end
        return best
    end

    local bestSingleScore = 0
    local bestSingleUnit = nil
    if contextUnit then
        bestSingleUnit = contextUnit
    else
        local bestMissing = -1
        for _, u in ipairs(targets) do
            local miss = deficit(u)
            if miss > 0 and miss > bestMissing then
                bestMissing = miss
                bestSingleUnit = u
            end
        end
    end

    if bestSingleUnit then
        local h, maxh = GoubayuHeal.GetUnitHealth(bestSingleUnit)
        local hpPct = h / maxh

        local best = nil
        local bestPct = 999
        for pct, data in singleEntries do
            local p = tonumber(pct) or 0
            if p / 100 > hpPct and p < bestPct then
                best, bestPct = data, p
            end
        end

        if best then
            local heal = GoubayuHeal.GetSpellHealing(bestSingleUnit, best["Spell"], best["Rank"])
            -- 8T2：条目是强效治疗术时，单体分按 强效治疗+5级恢复HOT×50% 计入
            if best["Spell"] == GoubayuHeal.Greater_heal then
                local gh2 = GoubayuHeal.GetGHPlusRenewHeal(bestSingleUnit,
                    tonumber(best["Rank"]) or 1, 0.5)
                if gh2 and gh2 > (heal or 0) then
                    heal = gh2
                end
            end
            bestSingleScore = math.min(heal, deficit(bestSingleUnit)) * prio(bestSingleUnit)
        end
    end

    -- 治疗之环（Holy Nova）评估
    local novaScore = 0
    if hasNova then
        local entry = highestEntry(novaEntries)
        if entry then
            local heal = GoubayuHeal.GetSpellHealing("player", entry["Spell"], entry["Rank"])
            -- 触发条件可被技能编辑窗口覆盖（范围/人数/最小掉血）
            local aoe = GoubayuHeal.GetAoECondition(GoubayuHeal.Holy_nova,
                { range = 10, count = 5, missing = 300 })
            local maxDist = aoe.range
            local reach = GoubayuHeal_GetTalentRank(2, 6) or 0
            if reach > 0 then
                maxDist = maxDist + reach
            end
            if maxDist > 12 then
                maxDist = 12
            end

            local inRange = {}
            for _, u in ipairs(targets) do
                if distBetween("player", u) <= maxDist then
                    table.insert(inRange, u)
                end
            end

            local countInRange = table.getn(inRange)
            if countInRange > 0 then
                local below = 0
                local totalRec = 0
                for _, u in ipairs(inRange) do
                    local h, maxh = GoubayuHeal.GetUnitHealth(u)
                    local miss = maxh - h
                    local rec = 0
                    if (h / maxh) < novaThreshold and miss > aoe.missing then
                        below = below + 1
                        rec = math.min(heal, miss)
                    end
                    totalRec = totalRec + rec
                end

                if below >= aoe.count then
                    local avgRec = totalRec / countInRange
                    for _, u in ipairs(inRange) do
                        local h, maxh = GoubayuHeal.GetUnitHealth(u)
                        local miss = maxh - h
                        if miss > 0 and (h / maxh) < novaThreshold then
                            local recoverable = math.min(heal, miss)
                            novaScore = novaScore + math.min(recoverable, avgRec) * prio(u)
                        end
                    end
                end
            end
        end
    end

    -- 治疗祷言（Prayer of Healing）评估
    local prayerScore = 0
    local prayerTarget = nil
    if hasPrayer then
        local entry = highestEntry(prayerEntries)
        if entry then
            local heal = GoubayuHeal.GetSpellHealing("player", entry["Spell"], entry["Rank"])
            -- 触发条件可被技能编辑窗口覆盖（范围/人数/最小掉血）
            local aoe = GoubayuHeal.GetAoECondition(GoubayuHeal.Prayer_of_healing,
                { range = 30, count = 3, missing = 600 })

            local parties = {}
            -- 有UnitXP(Nampower)才做覆盖范围评估，否则回退原逻辑
            local hasUnitXP = (UnitXP and type(UnitXP) == "function")
            for _, u in ipairs(targets) do
                local h, maxhp = GoubayuHeal.GetUnitHealth(u)
                if maxhp > 0 then
                    local idx = partyIndex(u) or 1
                    parties[idx] = parties[idx] or { members = {} }
                    table.insert(parties[idx].members, {
                        unit = u,
                        missing = maxhp - h,
                        pct = h / maxhp
                    })
                end
            end

            local bestParty, bestScore, bestTarget = nil, -1, nil
            for _, party in pairs(parties) do
                local elig = {}
                for _, m in ipairs(party.members) do
                    if m.pct < prayerThreshold and m.missing > aoe.missing then
                        table.insert(elig, m)
                    end
                end

                if table.getn(elig) >= aoe.count then
                    if hasUnitXP then
                        -- 乌龟服: 治疗祷言只治疗"距目标aoe.range码内"的小队成员
                        -- 逐个候选目标评估,只统计距候选目标范围内受伤队友
                        for _, cand in ipairs(elig) do
                            if distBetween("player", cand.unit) <= aoe.range then
                                local inRange = {}
                                for _, m in ipairs(elig) do
                                    if distBetween(cand.unit, m.unit) <= aoe.range then
                                        table.insert(inRange, m)
                                    end
                                end
                                if table.getn(inRange) >= aoe.count then
                                    local score = 0
                                    for _, m in ipairs(inRange) do
                                        score = score + math.min(heal, m.missing) * prio(m.unit)
                                    end
                                    if score > bestScore then
                                        bestScore = score
                                        bestParty = party
                                        bestTarget = cand.unit
                                    end
                                end
                            end
                        end
                    else
                        -- 无UnitXP精确测距：整队计分（回退路径）
                        local score = 0
                        for _, m in ipairs(elig) do
                            score = score + math.min(heal, m.missing) * prio(m.unit)
                        end
                        if score > bestScore then
                            bestScore = score
                            bestParty = party
                        end
                    end
                end
            end

            if bestParty then
                if bestTarget then
                    -- 有UnitXP: 已按30码覆盖选出最优目标
                    prayerScore = bestScore
                    prayerTarget = bestTarget
                else
                    -- 无UnitXP回退: 选离玩家最近的达标成员
                    local bestUnit = nil
                    local bestDist = 99999
                    for _, m in ipairs(bestParty.members) do
                        if m.pct < prayerThreshold then
                            local d = distBetween("player", m.unit)
                            if d < bestDist then
                                bestDist = d
                                bestUnit = m.unit
                            end
                        end
                    end
                    if bestUnit then
                        prayerScore = bestScore
                        prayerTarget = bestUnit
                    end
                end
            end
        end
    end

    -- 神圣打击（Holy Strike）群疗评估：以玩家为中心统计 aoe.range 内、血线低于该档且
    -- 掉血>aoe.missing 的队友数≥aoe.count 时计分。多档时取“满足条件的最低档”优先；
    -- 计分按最多 4 名（技能描述“最多4名”）封顶 by 武藤纯子酱 2026.9.6
    local hsScore = 0
    local hsCastEntry = nil
    if hasHolyStrike then
        -- 统计池：本人 + 宠物 + 团/队成员及成员宠物（用 UnitIsUnit 去重，避免 player/raidN、pet/raidpetN 重复）
        local hsPool = {}
        local function hsAdd(u)
            if not UnitExists(u) then
                return
            end
            if u ~= "player" and UnitIsUnit(u, "player") then
                return
            end
            if u ~= "pet" and UnitIsUnit(u, "pet") then
                return
            end
            table.insert(hsPool, u)
        end
        hsAdd("player")
        if UnitExists("pet") then
            hsAdd("pet")
        end
        local hsN = GetNumRaidMembers()
        local hsPor = "raid"
        if hsN == 0 then
            hsN = GetNumPartyMembers()
            hsPor = "party"
        end
        for a = 1, hsN do
            hsAdd(hsPor .. a)
            hsAdd(hsPor .. "pet" .. a)
        end

        -- 档位按百分比升序遍历：先命中的最低档优先
        local sorted = {}
        for pct, data in hsEntries do
            table.insert(sorted, { pct = tonumber(pct) or 0, data = data })
        end
        table.sort(sorted, function(a, b) return a.pct < b.pct end)

        for _, cand in ipairs(sorted) do
            local entry = cand.data
            local heal = GoubayuHeal.GetSpellHealing("player", entry["Spell"], entry["Rank"])
            local aoe = GoubayuHeal.GetAoECondition(GoubayuHeal.Holy_Strike,
                { range = 10, count = 3, missing = 200 })
            local frac = cand.pct / 100
            local inRange = {}
            local below = 0
            for _, u in ipairs(hsPool) do
                local h, maxh = GoubayuHeal.GetUnitHealth(u)
                if maxh and maxh > 0 and h and (maxh - h) > aoe.missing
                    and (h / maxh) < frac
                    and distBetween("player", u) <= aoe.range then
                    below = below + 1
                    local miss = maxh - h
                    if miss > 0 then
                        table.insert(inRange, { u = u, gain = math.min(heal, miss) * prio(u) })
                    end
                end
            end
            if below >= aoe.count then
                -- 按贡献降序取前 4 名参与计分（最多4名封顶）
                table.sort(inRange, function(a, b) return a.gain > b.gain end)
                local cap = math.min(table.getn(inRange), 4)
                for k = 1, cap do
                    hsScore = hsScore + inRange[k].gain
                end
                hsCastEntry = entry
                break
            end
        end
    end

    -- 宁静（Tranquility）大范围引导AOE评估
    -- 条件：①在团队中 ②团队中掉血>40%（血量<60%）的成员 人数>8 且 占比≥50%
    -- 触发时对自身施放并引导；引导期间 casting_spell 保持为真，不会施放其他技能
    local tranquilityScore = 0
    local tranquilityEntry = nil
    if hasTranquility then
        local numRaid = GetNumRaidMembers()
        if numRaid > 0 then
            local below = 0
            for a = 1, numRaid do
                local u = "raid" .. a
                if UnitExists(u) then
                    local h, maxh = GoubayuHeal.GetUnitHealth(u)
                    if maxh and maxh > 0 and h and h > 0 and (h / maxh) < 0.60 then
                        below = below + 1
                    end
                end
            end
            if below > 8 and below >= (0.5 * numRaid) then
                local entry = highestEntry(tranquilityEntries)
                if entry then
                    tranquilityScore = 1
                    tranquilityEntry = entry
                end
            end
        end
    end

    -- 治疗链（Chain Heal）评估
    local chainScore = 0
    local chainTarget = nil
    local chainEntry = nil
    local chainHasBounce = true

    if hasChain then
        chainEntry = highestEntry(chainEntries)
        if chainEntry then
            local ordered, hasBounce = GoubayuHeal.ChainHeal_SelectBestTarget(
                chainEntry["Spell"], chainEntry["Rank"])
            chainHasBounce = (hasBounce ~= false)

            if ordered and table.getn(ordered) > 0 then
                chainTarget = ordered[1]
                local heal = GoubayuHeal.GetSpellHealing(chainTarget, chainEntry["Spell"],
                    chainEntry["Rank"])
                local decay = { 1.0, 0.5, 0.25 }
                local taken = 0

                for _, u in ipairs(ordered) do
                    if taken < 3 then
                        local miss = deficit(u)
                        if miss > 0 then
                            chainScore = chainScore + math.min(heal * decay[taken + 1], miss)
                                * prio(u)
                        end
                        taken = taken + 1
                    end
                end
            end
        end
    end

    -- 最终决策：选择最高评分
    -- 各选项施法被竞争拦截/门检查拒绝时，依次落到下一优先级，最终走单体路径的强制兜底（绝不观望）
    -- 牧师"疾速只用强效"：疾速治疗buff期间清零所有AOE评分（祷言/新星/链/宁静），
    -- 强制走单体路径（单体经 HealUsingClass 的疾速检查→只读强效治疗术），
    -- 避免挂接的祷言/链在疾速期间仍被施放
    if GoubayuHeal.my_class == GoubayuHeal.Priest
        and GoubayuHeal.Config and GoubayuHeal.Config["priest_force_greater_heal"] == 1
        and GoubayuHeal.UnitGotBuff and GoubayuHeal.UnitGotBuff("player",
            GoubayuHeal.Rapid_healing) then
        prayerScore = 0
        novaScore = 0
        chainScore = 0
        tranquilityScore = 0
        hsScore = 0
    end
    GoubayuHeal.PrayerTarget = nil

    -- 神圣打击施放前提：需当前目标存在、可攻击且在近战范围（施法者就绪）
    -- 不满足则评分归零，落到方案的其他群疗/单体 by 武藤纯子酱 2026.9.6
    if hasHolyStrike and hsScore > 0 then
        local meleeOK = (GoubayuHeal.my_class == GoubayuHeal.Paladin)
            and UnitExists("target") and UnitCanAttack("player", "target")
            and GoubayuHeal.Paladin_CheckMeleeRange
            and GoubayuHeal.Paladin_CheckMeleeRange("target")
            and not GoubayuHeal.Paladin_IsCasting()
            and not GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Holy_Strike)
        if not meleeOK then
            hsScore = 0
        end
    end

    -- 宁静：大范围引导AOE，团队大掉血时最高优先级
    -- （healvalue传nil：按方案配置等级施放；传0会被ScaleSpell缩到1级，与评分口径矛盾）
    if tranquilityScore > 0 and tranquilityEntry and not GoubayuHeal.IsMoving() then
        if GoubayuHeal.Heal("player", tranquilityEntry["Spell"], tranquilityEntry["Rank"]) then
            return 1
        end
    end

    if prayerScore > 0 and not GoubayuHeal.IsMoving()
        and prayerScore >= novaScore and prayerScore >= chainScore
        and prayerScore >= bestSingleScore then
        GoubayuHeal.PrayerTarget = prayerTarget
        local pentry = highestEntry(prayerEntries)
        if pentry and prayerTarget then
            if GoubayuHeal.Heal(prayerTarget, pentry["Spell"], pentry["Rank"]) then
                GoubayuHeal.PrayerTarget = nil
                return 1
            end
        end
        GoubayuHeal.PrayerTarget = nil
    end

    if novaScore > 0 and novaScore >= chainScore and novaScore >= bestSingleScore then
        local nentry = highestEntry(novaEntries)
        if nentry then
            if GoubayuHeal.Heal("player", nentry["Spell"], nentry["Rank"]) then
                return 1
            end
        end
    end

    -- 神圣打击群疗：优先级与新星同档（评分为最高且不移动即打），
    -- 不满足/施放不了时自然落到后续链/单体 by 武藤纯子酱 2026.9.6
    if hsScore > 0 and not GoubayuHeal.IsMoving()
        and hsScore >= novaScore and hsScore >= prayerScore
        and hsScore >= chainScore and hsScore >= bestSingleScore then
        local hentry = hsCastEntry
        if hentry and GoubayuHeal.Paladin_CastSpellOnTarget then
            local gHS = GoubayuHeal.Paladin_GetUnitID
                and GoubayuHeal.Paladin_GetUnitID("target")
            GoubayuHeal.Paladin_CastSpellOnTarget(GoubayuHeal.Holy_Strike, gHS)
            return 1
        end
    end

    if chainScore > 0 and chainScore >= bestSingleScore and chainTarget then
        local chainH, chainMH = GoubayuHeal.GetUnitHealth(chainTarget)
        local chainTargetPct = 0
        if chainMH and chainMH > 0 then
            chainTargetPct = (chainH / chainMH) * 100
        end

        local castChainEntry = GoubayuHeal.PickChainEntryForHP(chainEntries, chainTargetPct)
            or chainEntry

        local chainAtt = castChainEntry and castChainEntry["Attachment"]
        if chainAtt and (chainAtt == GoubayuHeal.Natures_swiftness
            or chainAtt == GoubayuHeal.Shaman_Ancestral_swiftness) then
            GoubayuHeal.CastSwiftnessAttachment(chainAtt)
        end

        -- 萨满链转波（滑块）：无弹跳目标时改用等量治疗波(1)/次级治疗波(2)
        local cnbU = GoubayuHeal.Config
            and (GoubayuHeal.Config["shaman_chain_nobounce_wave"] or 0) or 0
        if GoubayuHeal.my_class == GoubayuHeal.Shaman
            and cnbU > 0 and not chainHasBounce then
            local waveSpellU = (cnbU == 2) and GoubayuHeal.Lesser_healing_wave
                or GoubayuHeal.Healing_wave
            local waveRank = GoubayuHeal.FindEquivalentWaveRank(castChainEntry["Spell"],
                castChainEntry["Rank"], waveSpellU)
            if waveRank then
                if GoubayuHeal.Heal(chainTarget, waveSpellU, waveRank,
                    deficit(chainTarget)) then
                    return 1
                end
            end
        end

        if GoubayuHeal.Heal(chainTarget, castChainEntry["Spell"], castChainEntry["Rank"],
            deficit(chainTarget)) then
            return 1
        end
    end

    -- 单体：用原方案名，临时 tankheal_mode 排除AOE档位（AOE 全被拦截时的最终兜底，
    -- HealMostWoundedTB 内部还有"强制治疗最大失血目标"的兜底，保证绝不观望）
    local savedTankMode = GoubayuHeal.tankheal_mode
    GoubayuHeal.tankheal_mode = true
    local result
    if contextUnit then
        result = GoubayuHeal.HealUsingClass(contextUnit, profileName,
            GoubayuHeal.GetHealValue(contextUnit))
    else
        result = GoubayuHeal.HealMostWoundedTB(profileName, nil)
    end
    GoubayuHeal.tankheal_mode = savedTankMode
    return result
end

-- ============================================================
-- Nampower 插件门控机制
-- ============================================================

local GoubayuHeal_NP_EARLY = 0.2
local GoubayuHeal_NP_STALE_CAP = 5.0
local GoubayuHeal_nampower_resume_at = nil
local GoubayuHeal_nampower_pending = nil
local GoubayuHeal_np_allow_queue = nil
local GoubayuHeal_np_force_cast = nil

-- 读取Nampower队列超时
local function GoubayuHeal_QueueTimeout()
    local t = GoubayuHeal.Config and GoubayuHeal.Config["nampower_queue_timeout"]
    if type(t) ~= "number" or t <= 0 then
        return 1.0
    end
    return t
end

-- 取法术最大预估读条时间
local function GoubayuHeal_SpellCastTime(spell)
    if not spell or not GoubayuHeal.Spells or not GoubayuHeal.Spells[spell] then
        return 0
    end
    local ct = 0
    for r, d in GoubayuHeal.Spells[spell] do
        if type(d) == "table" and d["CastTime"] and d["CastTime"] > ct then
            ct = d["CastTime"]
        end
    end
    return ct
end

-- 有效超时 = 预估读条时间 + 队列超时缓冲
local function GoubayuHeal_EffectiveQueueTimeout(pendingSpell)
    return GoubayuHeal_SpellCastTime(pendingSpell) + GoubayuHeal_QueueTimeout()
end

-- 判断玩家是否被控制（Nampower专用）
function GoubayuHeal.PlayerIsCCd()
    if not (GetNampowerVersion and GetUnitField) then
        return nil
    end

    local charm = GetUnitField("player", "charm") or GetUnitField("player", "charmedBy")
    if charm and charm ~= 0 and charm ~= "" and charm ~= "0x0000000000000000" then
        return true
    end

    local flags = GetUnitField("player", "flags")
    if flags and flags ~= 0 then
        local ccMask = 8192 + 16384 + 262144
        if GoubayuHeal_BitAnd(flags, ccMask) ~= 0 then
            return true
        end
    end
    return false
end

-- 牧师"救赎之魂"：死亡后约 10 秒内仍可施法，死亡拦截必须排除
-- by 武藤纯子酱 2026.10.23
function GoubayuHeal.IsSpiritOfRedemption()
    if GoubayuHeal.HasBuffByName and GoubayuHeal.Spirit_of_Redemption
        and GoubayuHeal.HasBuffByName("player", GoubayuHeal.Spirit_of_Redemption) then
        return true
    end
    -- 兜底：按 aura spellId 识别（27827 = Spirit of Redemption / 救赎之魂）
    if GetNampowerVersion and GetUnitField then
        local auras = GetUnitField("player", "aura")
        if auras then
            for i = 1, 32 do
                if auras[i] == 27827 then
                    return true
                end
            end
        end
    end
    return false
end

-- 清掉"死亡瞬间"可能卡住的瞬态锁（不动配置/存档）
-- by 武藤纯子酱 2026.10.23
function GoubayuHeal.ResetTransientLocks()
    GoubayuHeal._abortAction = nil
    GoubayuHeal.casting_spell = nil
    GoubayuHeal.casting_spell_time = nil
    GoubayuHeal.only_instant_spells = nil
    GoubayuHeal.only_instant_spells_time = nil
    GoubayuHeal.i_am_healing = nil
    GoubayuHeal._lastAttempt = nil
    GoubayuHeal.last_interrupted_spell = nil
    GoubayuHeal.competition_fallback = nil
    GoubayuHeal.tankheal_mode = nil
    GoubayuHeal.heal_target_delay = nil
    if GoubayuHeal.clean_spell_awaiting_target then
        GoubayuHeal.clean_spell_awaiting_target()
    end
    -- Nampower 队列（本文件局部变量）
    GoubayuHeal_nampower_resume_at = nil
    GoubayuHeal_nampower_pending = nil
    GoubayuHeal_np_allow_queue = nil
    GoubayuHeal_np_force_cast = nil
end

-- 玩家是否处于"死亡/灵魂且不能施法"状态（救赎之魂除外）。
-- 返回 true 时顺带清掉卡住的瞬态锁：死亡/复活后不用 /reload 也能恢复。
-- by 武藤纯子酱 2026.10.23
function GoubayuHeal.PlayerDeadBlocked()
    if not (UnitIsDeadOrGhost and UnitIsDeadOrGhost("player")) then
        return false
    end
    if GoubayuHeal.IsSpiritOfRedemption() then
        return false
    end
    GoubayuHeal.ResetTransientLocks()
    return true
end

-- 检查当前是否可以执行施法
function GoubayuHeal.NampowerCanAct()
    if not (GetNampowerVersion and GetCastInfo) then
        return true
    end

    local info = GetCastInfo()
    if not info then
        return true
    end

    local now = GetTime()
    local readyAt = 0

    if info.castEndS and info.castEndS > now then
        readyAt = info.castEndS
    end
    if info.gcdEndS and info.gcdEndS > readyAt then
        readyAt = info.gcdEndS
    end

    if readyAt <= now or (readyAt - now) <= (GoubayuHeal_NP_EARLY + 0.001) then
        return true
    end

    if (readyAt - now) > GoubayuHeal_NP_STALE_CAP then
        return true
    end

    GoubayuHeal_nampower_resume_at = readyAt - GoubayuHeal_NP_EARLY
    return false
end

-- 注册待执行操作
function GoubayuHeal.NampowerSetPending(kind, arg)
    GoubayuHeal_nampower_pending = { kind, arg, GetTime() }
end

-- 每帧检查：到恢复时间则执行待处理操作
function GoubayuHeal.NampowerUpdate()
    if not GoubayuHeal_nampower_resume_at or not GoubayuHeal_nampower_pending then
        return
    end

    local now = GetTime()
    local pending = GoubayuHeal_nampower_pending
    local timeout = GoubayuHeal_EffectiveQueueTimeout(pending and pending[2])

    if pending and pending[3] and (now - pending[3]) > timeout then
        local timedOutArg = pending[2]

        -- 若入队后方案已切换（如按了另一个/gbyh 方案），丢弃旧队列，避免执行旧方案
        if GoubayuHeal.current_action_profile
            and GoubayuHeal.current_action_profile ~= timedOutArg then
            GoubayuHeal_nampower_resume_at = nil
            GoubayuHeal_nampower_pending = nil
            return
        end

        local info = GetCastInfo and GetCastInfo()
        local realBusy = info and ((info.castEndS and info.castEndS > now)
            or (info.gcdEndS and info.gcdEndS > now))

        if GoubayuHeal.casting_spell or realBusy then
            return
        end

        GoubayuHeal_nampower_resume_at = nil
        GoubayuHeal_nampower_pending = nil

        if timedOutArg then
            local savedHealing = GoubayuHeal.i_am_healing
            GoubayuHeal_np_allow_queue = true
            GoubayuHeal_np_force_cast = true
            GoubayuHeal.HealMostWounded(timedOutArg)
            GoubayuHeal_np_force_cast = nil
            GoubayuHeal_np_allow_queue = nil
            GoubayuHeal.i_am_healing = savedHealing
        end
        return
    end

    if now < GoubayuHeal_nampower_resume_at then
        return
    end

    GoubayuHeal_nampower_resume_at = nil
    GoubayuHeal_nampower_pending = nil

    if pending and pending[1] == "HealMostWounded" and pending[2] then
        -- 若入队后方案已切换，丢弃旧队列，避免执行旧方案
        if GoubayuHeal.current_action_profile
            and GoubayuHeal.current_action_profile ~= pending[2] then
            return
        end
        local savedHealing = GoubayuHeal.i_am_healing
        GoubayuHeal_np_allow_queue = true
        GoubayuHeal.HealMostWounded(pending[2])
        GoubayuHeal_np_allow_queue = nil
        GoubayuHeal.i_am_healing = savedHealing
    end
end

-- 技能入队前可行性预检
function GoubayuHeal.NampowerQueueFeasible(spell, rank)
    if not (GoubayuHeal.last_scan_time and (GetTime() - GoubayuHeal.last_scan_time) <= 0.2) then
        GoubayuHeal.ScanWoundedData()
        GoubayuHeal.last_scan_time = GetTime()
    end

    local mw = GoubayuHeal.most_wounded
    if not mw or table.getn(mw) == 0 then
        return false
    end

    local candidateSpells = {}
    if rank and GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
        and GoubayuHeal.Spells[spell][rank] then
        table.insert(candidateSpells, { spell = spell, rank = rank })
    elseif GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][spell] then
        for curpercent, data in GoubayuHeal.Config["classes"][spell] do
            if type(data) == "table" and data["Spell"] and data["Rank"]
                and GoubayuHeal.Spells and GoubayuHeal.Spells[data["Spell"]]
                and GoubayuHeal.Spells[data["Spell"]][data["Rank"]] then
                table.insert(candidateSpells, { spell = data["Spell"], rank = data["Rank"] })
            end
        end
    else
        return false
    end

    if table.getn(candidateSpells) == 0 then
        return false
    end

    for id = 1, table.getn(mw) do
        local unit = mw[id] and mw[id]["Unit"]
        if unit and UnitExists(unit) then
            for _, cs in ipairs(candidateSpells) do
                local sdata = GoubayuHeal.Spells[cs.spell] and GoubayuHeal.Spells[cs.spell][cs.rank]
                if sdata then
                    local range = 40
                    if sdata["Range"] and sdata["Range"] > 0 then
                        range = sdata["Range"]
                    end

                    if GoubayuHeal.CanCastAtUnit(unit, range, sdata["SpellId"]) ~= false then
                        local cd = (GoubayuHeal.GetSpellCooldown(GoubayuHeal.GetSpellCDId(sdata)) or 0)
                        if cd == 0 then
                            local checkRank = cs.rank
                            if GoubayuHeal.Config and GoubayuHeal.Config["scale_spells"] == 1 then
                                checkRank = 1
                            end
                            if not GoubayuHeal.SpellRankOutOfMana(cs.spell, checkRank) then
                                return true
                            end
                        end
                    end
                end
            end
        end
    end

    return false
end

-- ============================================================
-- 治疗最伤者入口函数
-- ============================================================

function GoubayuHeal.HealMostWounded(spell, rank)
    -- 死亡/灵魂状态（救赎之魂除外）：直接返回；顺带清理死亡时卡住的锁
    -- by 武藤纯子酱 2026.10.23
    if GoubayuHeal.PlayerDeadBlocked() then
        return
    end

    if GoubayuHeal.PlayerIsCCd() == true then
        return
    end

    -- 脱战后回收图腾（主动按键路径，与 ActionHeal 同口径）
    -- by 武藤纯子酱 2026.9.24
    if GoubayuHeal.Totem_TryRecallAfterCombat and GoubayuHeal.Totem_TryRecallAfterCombat() then
        return 1
    end

    -- 自救步骤（与 ActionHeal 同口径，保证 /script HealMostWounded 直接调用时一致）：
    -- 牧师绝望祷言 / 圣骑圣盾术·圣佑术——低于各自滑块阈值时断条施放（函数内部自带CD/自律/debuff检查）
    if GoubayuHeal.TryDesperatePrayer then
        if GoubayuHeal.TryDesperatePrayer() then
            return 1
        end
    end
    if GoubayuHeal.my_class == GoubayuHeal.Paladin then
        if GoubayuHeal.TryDivineShield then
            if GoubayuHeal.TryDivineShield() then
                return 1
            end
        end
        if GoubayuHeal.TryDivineProtection then
            if GoubayuHeal.TryDivineProtection() then
                return 1
            end
        end
    end

    if not (GetNampowerVersion and GetCastInfo) then
        if GoubayuHeal.IsCasting() then
            return
        end
    end

    -- 保持心灵之火（与 ActionHeal 同口径；此前 HealMostWounded 漏了这一步，
    -- 导致 /script GoubayuHeal.HealMostWounded(...) 不维持心灵之火）
    if GoubayuHeal.EnsureInnerFire then
        GoubayuHeal.EnsureInnerFire()
    end

    if GoubayuHeal.EnsureTreeOfLife then
        GoubayuHeal.EnsureTreeOfLife()
    end

    if GoubayuHeal.NampowerCanAct() == false and not GoubayuHeal_np_force_cast then
        if GoubayuHeal.NampowerQueueFeasible(spell, rank) == true then
            GoubayuHeal.NampowerSetPending("HealMostWounded", spell)
        end
        return
    end

    -- 萨满：放置图腾（仅"一键图腾"选项开启时；图腾窗口开关只控制窗口显示）
    if GoubayuHeal.my_class == GoubayuHeal.Shaman
        and GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
        and GoubayuHeal.Config["shaman_totem"].onekey == 1
        and (not GoubayuHeal.Totem_GroupInCombat or GoubayuHeal.Totem_GroupInCombat()) then
        if GoubayuHeal.Totem_PlaceAll then
            GoubayuHeal.Totem_PlaceAll()
        end
    end

    GoubayuHeal.EnsureWaterShield()

    -- 防护恐惧结界维持（牧师，按团队框架右侧优先级）：成功施放则本次动作结束
    -- by 武藤纯子酱 2026.9.21
    if GoubayuHeal.MaintainFearWard and GoubayuHeal.MaintainFearWard() then
        return 1
    end

    if GoubayuHeal.my_class == GoubayuHeal.Paladin and GoubayuHeal.Paladin then
        if GoubayuHeal.Config and GoubayuHeal.Config["paladin_melee_heal"] == 1 then
            local meleeProfile = (type(spell) == "string" and GoubayuHeal.Config["classes"]
                and GoubayuHeal.Config["classes"][spell]) and spell or GoubayuHeal.current_class
            if GoubayuHeal.Paladin_MeleeHeal(meleeProfile) then
                return
            end
            -- 无近战条件：回退原始治疗方案（继续向下执行）
        end
    end

    -- 将驱散加入治疗队列（与 ActionHeal 一致：开启后治疗动作会优先处理可驱散减益）
    if GoubayuHeal.Config and GoubayuHeal.Config["dispel_queue"] == 1
        and GoubayuHeal.Dispel_Priority then
        if GoubayuHeal.Dispel_Priority() then
            return
        end
    end

    -- HOT 自动维持（与 ActionHeal 一致；此前 HealMostWounded 漏了，直接 /script 调用不补 HOT）
    if GoubayuHeal.Config and GoubayuHeal.Config["raid_hots_enabled"] == 1
        and GoubayuHeal.HotMaintenancePriority then
        if GoubayuHeal.HotMaintenancePriority() then
            return
        end
    end

    -- 带后缀的分组名直接走TB路由
    if spell and (string.find(spell, "_D$") or string.find(spell, "_S$")
        or string.find(spell, "_T$")) then
        return GoubayuHeal.HealMostWoundedTB(spell, rank)
    end

    -- 职业配置名：方案含新增祷言（牧师智能团刷）保留 Unified 评分；否则统一按方案百分比档位施放（治疗最伤者）
    if GoubayuHeal.Config["classes"][spell] then
        -- 方案切换：清除跨方案残留的施法状态，避免上一个方案的被打断技能/交替记录污染当前方案
        if GoubayuHeal.current_action_profile ~= spell then
            GoubayuHeal.current_action_profile = spell
            -- 切换方案前先回滚上一次施法的残留（含 hot_cast_cd），避免旧目标被锁
            -- by 武藤纯子酱 2026.10.22
            if GoubayuHeal.RollbackLastAttempt then
                GoubayuHeal.RollbackLastAttempt()
            end
            GoubayuHeal.last_interrupted_spell = nil
            GoubayuHeal.last_cast_spell = nil
            GoubayuHeal.i_am_healing = nil
            GoubayuHeal.only_instant_spells = nil
        end
        local hasAoE = false
        for _, data in pairs(GoubayuHeal.Config["classes"][spell]) do
            if type(data) == "table" then
                if data["Spell"] == GoubayuHeal.Holy_nova
                    or data["Spell"] == GoubayuHeal.Prayer_of_healing
                    or data["Spell"] == GoubayuHeal.Chain_heal
                    or data["Spell"] == GoubayuHeal.Tranquility
                    or data["Attachment"] == GoubayuHeal.Holy_nova
                    or data["Attachment"] == GoubayuHeal.Prayer_of_healing
                    or data["Attachment"] == GoubayuHeal.Chain_heal
                    or data["Attachment"] == GoubayuHeal.Tranquility then
                    hasAoE = true
                    break
                end
            end
        end
        if hasAoE then
            return GoubayuHeal.HealMostWoundedUnified(spell)
        end
        return GoubayuHeal.HealMostWoundedTB(spell, rank)
    end

    return GoubayuHeal.HealMostWoundedTB(spell, rank)
end

-- ============================================================
-- 治疗最伤者（TB版本）
-- ============================================================

function GoubayuHeal.HealMostWoundedTB(spell, rank)
    -- 正在施法时检查安全取消
    if (GoubayuHeal.casting_spell) then
        local healingtarget = GoubayuHeal.i_am_healing
        local isFirstRank = false

        if (healingtarget and GoubayuHeal.healing[healingtarget]
            and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]
            and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Rank"] == 1) then
            local spell = GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Spell"]
            if spell == GoubayuHeal.Flash_heal or spell == GoubayuHeal.Healing_touch
                or spell == GoubayuHeal.Regrowth or spell == GoubayuHeal.Flash_of_light
                or spell == GoubayuHeal.Lesser_healing_wave or spell == GoubayuHeal.Chain_heal then
                isFirstRank = true
            end
        end

        local unit = GoubayuHeal.GetUnitID(healingtarget)
        local isFullHealth = false
        local _gh, _gmh = GoubayuHeal.GetUnitHealth(unit)
        if (unit and _gh == _gmh) then
            isFullHealth = true
        end

        if (GoubayuHeal.Config["safe_cancel"] == 1) then
            local canceled = false
            if (isFirstRank and GoubayuHeal.Config["allow_first_rank_ignore_overheal"] == 1) then
                if (isFullHealth) then
                    SpellStopCasting()
                    canceled = true
                end
            else
                if (GoubayuHeal.GetOverheal() > GoubayuHeal.Config["max_overheal"]) then
                    SpellStopCasting()
                    canceled = true
                end
            end

            if canceled then
                if healingtarget and GoubayuHeal.healing
                    and GoubayuHeal.healing[healingtarget]
                    and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name] then
                    GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Status"] = "Inactive"
                end
                if GoubayuHeal_np_allow_queue then
                    -- 继续执行新决策
                else
                    return 1
                end
            else
                return 1
            end
        else
            return 1
        end
    end

    if (not GoubayuHeal.Spells) then
        if type(GoubayuHeal.UpdateSpells) == "function" then
            GoubayuHeal.UpdateSpells()
        end
    end

    if (not ((rank and GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][rank])
        or (not rank and GoubayuHeal.Config["classes"][spell]))) then
        return
    end

    if (rank and (GoubayuHeal.GetSpellCooldown(GoubayuHeal.GetSpellCDId(GoubayuHeal.Spells[spell][rank])) or 0) ~= 0) then
        return
    elseif (not rank) then
        local allcooldown = 1
        for thisclass, data in GoubayuHeal.Config["classes"][spell] do
            if GoubayuHeal.Spells[data["Spell"]] and GoubayuHeal.Spells[data["Spell"]][1]
                and (GoubayuHeal.Spells[data["Spell"]][1]["SpellId"]
                    or GoubayuHeal.Spells[data["Spell"]][1]["ID"]) then
                if ((GoubayuHeal.GetSpellCooldown(GoubayuHeal.GetSpellCDId(
                    GoubayuHeal.Spells[data["Spell"]][1])) or 0) == 0) then
                    allcooldown = nil
                end
            else
                GoubayuHeal.missing_spell_warnings = GoubayuHeal.missing_spell_warnings or 0
                if GoubayuHeal.missing_spell_warnings < 5 then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format(GoubayuHeal.Msg.MissingTalent, data["Spell"]), 1, 0, 0)
                    GoubayuHeal.missing_spell_warnings = GoubayuHeal.missing_spell_warnings + 1
                end
            end
        end
        if (allcooldown) then
            return
        end
    end

    if rank and spell == GoubayuHeal.Chain_heal and GoubayuHeal_has_unitxp then
        local targets = GoubayuHeal.ChainHeal_SelectBestTarget(spell, rank)
        if targets then
            for i = 1, table.getn(targets) do
                if GoubayuHeal.Heal(targets[i], spell, rank, nil) then
                    return 1
                end
            end
        end
    end

    local scanCacheOk = GoubayuHeal.Config and GoubayuHeal.Config["scan_cache"] == 1
    if not (scanCacheOk and GoubayuHeal.last_scan_time
        and (GetTime() - GoubayuHeal.last_scan_time) <= 0.2) then
        GoubayuHeal.ScanWoundedData()
        GoubayuHeal.last_scan_time = GetTime()
    end

    -- 治疗祷言分组
    if string.find(spell, "_T$") then
        local unit = GoubayuHeal.PrayerTarget
        if unit and UnitExists(unit) and GoubayuHeal.CanHeal(unit) then
            if (not rank) then
                if (GoubayuHeal.HealUsingClass(unit, spell, 0, true)) then
                    return 1
                end
            elseif ((not GoubayuHeal.OnlyInstantActive()
                or (GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][rank]
                    and GoubayuHeal.Spells[spell][rank]["CastTime"] == 0))) then
                local scaledRank = rank
                if (not GoubayuHeal.dont_scale[spell]) then
                    scaledRank = GoubayuHeal.ScaleSpell(unit, spell, rank, 0)
                end
                if GoubayuHeal.Heal(unit, spell, scaledRank, 0) then
                    GoubayuHeal.only_instant_spells = nil
                    return 1
                end
            end
            GoubayuHeal.only_instant_spells = nil
            return
        end
        GoubayuHeal.PrayerTarget = nil
    end

    for id = 1, table.getn(GoubayuHeal.most_wounded) do
        if GoubayuHeal._abortAction then
            break
        end
        local unit = GoubayuHeal.most_wounded[id]["Unit"]

        if (not rank) then
            if (GoubayuHeal.HealUsingClass(unit, spell, GoubayuHeal.most_wounded[id]["Heal"],
                true)) then
                return 1
            end
        elseif ((not GoubayuHeal.OnlyInstantActive()
            or GoubayuHeal.Spells[spell][rank]["CastTime"] == 0)) then
            local scaledRank = rank
            if (not GoubayuHeal.dont_scale[spell]) then
                scaledRank = GoubayuHeal.ScaleSpell(unit, spell, rank,
                    GoubayuHeal.most_wounded[id]["Heal"])
            end
            if GoubayuHeal.Heal(unit, spell, scaledRank, GoubayuHeal.most_wounded[id]["Heal"]) then
                GoubayuHeal.only_instant_spells = nil
                return 1
            end
        end
    end

    GoubayuHeal.only_instant_spells = nil

    -- 兜底：强制治疗"距离+视野内最大失血"的目标
    local fbUnit = nil
    local fbHeal = 0
    for id = 1, table.getn(GoubayuHeal.most_wounded) do
        if GoubayuHeal._abortAction then
            break
        end
        local u = GoubayuHeal.most_wounded[id] and GoubayuHeal.most_wounded[id]["Unit"]
        if u and GoubayuHeal.CanCastAtUnit(u, 40) ~= false then
            fbUnit = u
            fbHeal = GoubayuHeal.most_wounded[id]["Heal"] or 0
            break
        end
    end

    if fbUnit then
        GoubayuHeal.competition_fallback = true
        local fbOk
        if (not rank) then
            fbOk = GoubayuHeal.HealUsingClass(fbUnit, spell, fbHeal, true)
        else
            local fr = rank
            if (not GoubayuHeal.dont_scale[spell]) then
                fr = GoubayuHeal.ScaleSpell(fbUnit, spell, rank, fbHeal)
            end
            fbOk = GoubayuHeal.Heal(fbUnit, spell, fr, fbHeal)
        end
        GoubayuHeal.competition_fallback = nil
        -- 兜底施放成功即结束本次动作（原先无条件 return nil，上层会再走预读/二次尝试）
        -- by 武藤纯子酱 2026.10.22
        if fbOk then
            return 1
        end
    end

    return
end

-- ============================================================
-- 排序比较函数
-- ============================================================

function GoubayuHeal.SortMostWoundedAlgorithm(a, b)
    return (a["PriorityValue"] > b["PriorityValue"])
end

-- ============================================================
-- 设置最伤者数量
-- ============================================================

function GoubayuHeal.SetMostWoundedData(unit)
    -- 便宜检查前置：血量/阈值判断先行（GetUnitHealth 为纯字段读取），
    -- 满血/空数据的多数候选直接排除，不再白付 UnitIsVisible（重）、距离检测等重调用；
    -- 各检查均为纯过滤器，先后顺序只影响开销不影响结果 by 武藤纯子酱 2026.9.4
    local currentHealth, maxHealth = GoubayuHeal.GetUnitHealth(unit)
    if not maxHealth or maxHealth <= 0 then
        return
    end

    if (currentHealth / maxHealth) >= GoubayuHeal.Config["min_heal_threshold"] then
        return
    end

    if (not GoubayuHeal.CanHeal(unit)
        or (string.find(unit, "pet") and UnitIsCharmed(unit)
            and GoubayuHeal.Config["heal_charmed"] == 0)) then
        return
    end

    -- 距离/视野优先：够不到/看不见就不进候选（比"竞争人数/缺口预估"更早排除，避免白算）
    -- by 武藤纯子酱 2026.10.20
    local castable = GoubayuHeal.CanCastAtUnit(unit, 40)
    if (castable == false) then
        return
    end

    -- 救急线分诊：救急线以下的目标，若已有 >=2 个治疗者正在读条 → 让给别人（优先其他救急目标）；
    -- 若所有救急目标都有 >=2 人在治，则这些目标都不救，自然落到方案的其他目标。
    -- by 武藤纯子酱 2026.10.20
    local rescuePct = tonumber(GoubayuHeal.Config["rescue_hp_threshold"]) or 40
    if rescuePct > 0 and (currentHealth / maxHealth * 100) < rescuePct then
        local rg = GoubayuHeal.GetUnitGUID and GoubayuHeal.GetUnitGUID(unit)
        local rcnt = 0
        if rg and GoubayuHeal.CastingSpeed and GoubayuHeal.CastingSpeed.GetHealerCount then
            rcnt = GoubayuHeal.CastingSpeed:GetHealerCount(rg)
        end
        if rcnt >= 2 then
            return
        end
    end

    if not (GetNampowerVersion and GetCastInfo) then
        local uname = GoubayuHeal.UnitName(unit)
        if uname and GoubayuHeal.heal_target_delay
            and GoubayuHeal.heal_target_delay[uname]
            and GoubayuHeal.heal_target_delay[uname] > GetTime() then
            return
        end
    end

    -- 迅捷治愈豁免：本职业德鲁伊、当前方案含迅捷治愈、目标带可消耗 HOT 时，
    -- 不要把“他人/自身在读治疗量”当作已到账而从候选池剔除——
    -- 迅捷治愈是瞬发“让 HOT 立刻跳完”，不等待其他人的读条 by 武藤纯子酱 2026.9.6
    -- 方案含迅捷的判定缓存到 GoubayuHeal._swiftScheme*（cfg 表引用变化才重扫，避免每单位遍历方案）
    if GoubayuHeal.my_class == GoubayuHeal.Druid and GoubayuHeal.current_class
        and GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][GoubayuHeal.current_class] then
        local curCfg = GoubayuHeal.Config["classes"][GoubayuHeal.current_class]
        if GoubayuHeal._swiftSchemeCfg ~= curCfg then
            GoubayuHeal._swiftSchemeCfg = curCfg
            GoubayuHeal._swiftSchemeHas = false
            for _, d in curCfg do
                if type(d) == "table" and d["Spell"] == GoubayuHeal.Swiftmend then
                    GoubayuHeal._swiftSchemeHas = true
                    break
                end
            end
        end
    else
        GoubayuHeal._swiftSchemeCfg = nil
        GoubayuHeal._swiftSchemeHas = false
    end

    local healvalue = GoubayuHeal.GetHealValue(unit)
    -- 仅在“会被在读治疗挤掉(healvalue≤0)”且方案含迅捷时，才做 HOT 检查并豁免；
    -- 其余目标不触发任何额外 UnitHasHOT 查询（多数目标是满血/已在途覆盖，先被阈值排除）
    if healvalue <= 0 and GoubayuHeal._swiftSchemeHas == true then
        if GoubayuHeal.UnitHasHOT(unit, GoubayuHeal.Rejuvenation)
            or GoubayuHeal.UnitHasHOT(unit, GoubayuHeal.Regrowth) then
            local rawDef = maxHealth - currentHealth
            if rawDef < 0 then
                rawDef = 0
            end
            healvalue = rawDef
        end
    end

    local priority = GoubayuHeal.GetPriority(unit)
    if (priority <= 0 or healvalue <= 0) then
        return
    end

    local priorityvalue
    if (GoubayuHeal.Config["heal_strategy"] == 2) then
        priorityvalue = priority * (healvalue / maxHealth)
    elseif (GoubayuHeal.Config["heal_strategy"] == 3) then
        priorityvalue = priority * healvalue
    elseif (GoubayuHeal.Config["heal_strategy"] == 4) then
        local rawDeficit = maxHealth - currentHealth
        if (rawDeficit < 0) then
            rawDeficit = 0
        end
        priorityvalue = priority * rawDeficit
    else
        local divideby = (maxHealth - healvalue)
        if (divideby < 1) then
            divideby = 1
        end
        priorityvalue = priority * (666 / divideby)
    end

    GoubayuHeal.most_wounded[GoubayuHeal.most_wounded_id] =
        (GoubayuHeal.most_wounded[GoubayuHeal.most_wounded_id] or {})
    GoubayuHeal.most_wounded[GoubayuHeal.most_wounded_id]["Heal"] = healvalue
    GoubayuHeal.most_wounded[GoubayuHeal.most_wounded_id]["PriorityValue"] = priorityvalue
    GoubayuHeal.most_wounded[GoubayuHeal.most_wounded_id]["Unit"] = unit
    GoubayuHeal.most_wounded_id = GoubayuHeal.most_wounded_id + 1
end

-- ============================================================
-- 全团掉血扫描
-- ============================================================

function GoubayuHeal.ScanWoundedData()
    GoubayuHeal.most_wounded_id = 1
    GoubayuHeal.most_wounded = (GoubayuHeal.most_wounded or {})

    local lastRefresh = GoubayuHeal.last_player_data_time or 0
    if (GetTime() - lastRefresh) > 2.0 then
        GoubayuHeal.UpdatePlayerData()
        GoubayuHeal.last_player_data_time = GetTime()
    end

    local players = GetNumRaidMembers()
    local por = "raid"
    if (players == 0) then
        players = GetNumPartyMembers()
        por = "party"
        GoubayuHeal.SetMostWoundedData("player")
        GoubayuHeal.SetMostWoundedData("pet")
    end

    for a = 1, players do
        GoubayuHeal.SetMostWoundedData(por .. a)
        GoubayuHeal.SetMostWoundedData(por .. "pet" .. a)
    end

    for id = GoubayuHeal.most_wounded_id, table.getn(GoubayuHeal.most_wounded) do
        GoubayuHeal.most_wounded[id] = nil
    end

    table.sort(GoubayuHeal.most_wounded, GoubayuHeal.SortMostWoundedAlgorithm)

    -- 防饥饿打乱：仅打乱同优先级（PriorityValue 相同）的并列目标，保持整体优先级排序
    if GoubayuHeal.Config and GoubayuHeal.Config["heal_anti_starvation"] == 1 then
        local n = table.getn(GoubayuHeal.most_wounded)
        local start = 1
        while start <= n do
            local last = start
            while (last < n
                and GoubayuHeal.most_wounded[last + 1]["PriorityValue"]
                    == GoubayuHeal.most_wounded[start]["PriorityValue"]) do
                last = last + 1
            end
            if last > start then
                for i = last, start + 1, -1 do
                    local j = math.random(start, i)
                    GoubayuHeal.most_wounded[i], GoubayuHeal.most_wounded[j] =
                        GoubayuHeal.most_wounded[j], GoubayuHeal.most_wounded[i]
                end
            end
            start = last + 1
        end
    end
end

-- ============================================================
-- 获取治疗天赋加成系数
-- ============================================================

local function GoubayuHeal_GetTalentBonus()
    if GoubayuHeal.my_class == GoubayuHeal.Druid then
        local rank = GoubayuHeal_GetTalentRank(3, 9)
        if rank and rank > 0 then
            return 1 + rank * 0.02
        end
    elseif GoubayuHeal.my_class == GoubayuHeal.Priest then
        local rank = GoubayuHeal_GetTalentRank(2, 16)
        if rank and rank > 0 then
            return 1 + rank * 0.06
        end
    end
    return 1.0
end

-- ============================================================
-- 蓝量检查
-- ============================================================

function GoubayuHeal.SpellRankOutOfMana(spell, rank)
    -- 圣疗术豁免：其"消耗全部法力"是效果而非费用，IsSpellUsable 可能因蓝量
    -- 不足误判为不可用，导致方案中的圣疗术永远无法施放
    if spell == GoubayuHeal.Lay_on_hands then
        return false
    end

    local rankData = GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
        and GoubayuHeal.Spells[spell][rank]
    if not rankData then
        return false
    end

    if GetNampowerVersion and IsSpellUsable then
        local id = rankData["SpellId"]
        if id then
            -- 短时缓存 IsSpellUsable 结果（0.2s），避免每候选每次 pcall（不持久化）
            -- 注意：Nampower 的 IsSpellUsable 的返回中 outOfMana 才是"蓝不够"，第1返回的 isUsable=0
            -- 表示不可用（含施法中/GCD/距离/目标无效等），不能用作蓝量判断，否则战斗中会误判蓝不够而跳过治疗
            GoubayuHeal.spell_usable_cache = GoubayuHeal.spell_usable_cache or {}
            local c = GoubayuHeal.spell_usable_cache[id]
            local now = GetTime()
            if c and (now - c.t) < 0.2 then
                return c.usable
            end
            local ok, isUsable, outOfMana = pcall(IsSpellUsable, id)
            if ok then
                local usable = (outOfMana == 1)
                GoubayuHeal.spell_usable_cache[id] = { usable = usable, t = now }
                return usable
            end
        end
    end

    local m = rankData["Mana"]
    if (GetNampowerVersion and GetUnitField) then
        local mana = GetUnitField("player", "power1")
        if mana then
            return (m and m > mana)
        end
    end
    return (m and m > UnitMana("player"))
end

-- ============================================================
-- 智能法术等级缩放
-- ============================================================

function GoubayuHeal.ScaleSpell(unit, spell, rank, heal)
    if (not unit or not spell or not rank or GoubayuHeal.dont_scale[spell]
        or (GoubayuHeal.dont_scale_hots[spell] and GoubayuHeal.Config["scale_hots"] == 0)) then
        return rank
    end

    -- 缺口为 0/未传（统一决策、AoE 通道会传 heal=0）时不能把 0 当期望值：
    -- 各级实际治疗量与 0 的差值随等级单调增大 → 恒选 1 级；改用目标真实缺口
    -- by 武藤纯子酱 2026.9.21
    if (not heal) or heal == 0 then
        local hh, hmh = GoubayuHeal.GetUnitHealth(unit)
        if hmh and hh and hmh > hh then
            heal = hmh - hh
        else
            return rank
        end
    elseif heal < 0 then
        heal = heal * 0.3
    end

    local max_rank_limit = rank
    local expected_heal = heal
    local is_aoe_spell = (spell == GoubayuHeal.Holy_nova or spell == GoubayuHeal.Prayer_of_healing)

    local hot_multiply = GoubayuHeal.Config["hot_multiply"]
    if (GoubayuHeal.player_in_combat) then
        hot_multiply = GoubayuHeal.Config["hot_multiply_battle"]
    end

    local is_hot_spell = false
    local spell_props = GoubayuHeal.heal_spells_text[spell]
    if spell_props then
        for _, prop in ipairs(spell_props) do
            if prop == "HealingOverTime" then
                is_hot_spell = true
                break
            end
        end
    end

    if is_hot_spell then
        expected_heal = expected_heal * hot_multiply
    end

    if is_aoe_spell then
        -- AOE法术不乘系数
    elseif not is_hot_spell then
        expected_heal = expected_heal * GoubayuHeal.Config["heal_power"]
    end

    local talent_bonus = GoubayuHeal_GetTalentBonus()

    local best_rank = rank
    local min_diff = 999999
    local best_actual_heal = 0
    local found_base = false

    local penaltyTbl = nil
    local scaleBaseBonus = 0
    local pen1 = 1

    if GoubayuHeal.Spells and GoubayuHeal.Spells[spell] then
        penaltyTbl = GoubayuHeal.low_level_spell_bonus_penalty[spell]
        scaleBaseBonus = GoubayuHeal.GetHealBonus(unit, spell, 1)
        pen1 = (penaltyTbl and penaltyTbl[1]) or 1
    end

    if GoubayuHeal.Spells and GoubayuHeal.Spells[spell] then
        local actual_max_rank = table.getn(GoubayuHeal.Spells[spell])
        local limited_max_rank = math.min(max_rank_limit, actual_max_rank)

        for i = 1, limited_max_rank do
            local base_heal = (GoubayuHeal.Spells[spell][i]["Heal"] or 0)
            local base_healmin = (GoubayuHeal.Spells[spell][i]["HealMin"] or 0)
            local base_healmax = (GoubayuHeal.Spells[spell][i]["HealMax"] or 0)
            local base_hot = (GoubayuHeal.Spells[spell][i]["HealingOverTime"] or 0)

            if spell == GoubayuHeal.Renew then
                local default_hot_values = {
                    [1] = 55, [2] = 115, [3] = 205, [4] = 285, [5] = 315,
                    [6] = 395, [7] = 505, [8] = 640, [9] = 795, [10] = 950
                }
                base_hot = default_hot_values[i] or base_hot
                local r1 = GoubayuHeal_GetTalentRank(2, 1)
                local r2 = GoubayuHeal_GetTalentRank(2, 10)
                if r1 and r1 > 0 then
                    base_hot = base_hot * (1 + 0.05 * r1)
                end
                if r2 and r2 > 0 then
                    base_hot = base_hot * 6 / 5
                end
            elseif spell == GoubayuHeal.Rejuvenation then
                local default_hot_values = {
                    [1] = 36, [2] = 60, [3] = 120, [4] = 180, [5] = 246,
                    [6] = 306, [7] = 390, [8] = 492, [9] = 612, [10] = 756, [11] = 888
                }
                base_hot = default_hot_values[i] or base_hot
            end

            if base_healmin == 0 and base_healmax == 0 and base_heal > 0 then
                base_healmin = base_heal
                base_healmax = base_heal
            end

            local base_direct_heal = base_heal
            if (GoubayuHeal.player_in_combat) then
                base_direct_heal = base_direct_heal + base_healmin
            else
                base_direct_heal = base_direct_heal + base_healmax
            end

            if base_direct_heal > 0 or base_hot > 0 then
                found_base = true
            end

            local peni = (penaltyTbl and penaltyTbl[i]) or 1
            local healbonus = scaleBaseBonus * peni / pen1

            local originalCastTime = GoubayuHeal.GetSpellBaseCastTime(spell, i,
                GoubayuHeal.Spells[spell][i]["CastTime"] or 0)

            local bonusCastTime = originalCastTime
            if (bonusCastTime > GoubayuHeal.bonus_divide) then
                bonusCastTime = GoubayuHeal.bonus_divide
            end

            local direct_bonus
            local coeff = GoubayuHeal.GetSpellHealCoeff(spell, originalCastTime, i)
            if (coeff) then
                direct_bonus = healbonus * coeff
            else
                direct_bonus = healbonus * bonusCastTime / GoubayuHeal.bonus_divide
            end
            if (spell == GoubayuHeal.Holy_nova) then
                direct_bonus = healbonus * 0.106
            end

            local final_hot = base_hot
            local hot_bonus = 0
            -- Turtle 172 HoT 加成系数：恢复 0.85（1级 0.442、2级 0.646）、回春术 0.8、愈合 HoT 部分 0.5
            local hotCoeff = 0.85
            if (spell == GoubayuHeal.Renew) then
                if (i == 1) then
                    hotCoeff = 0.442
                elseif (i == 2) then
                    hotCoeff = 0.646
                end
            elseif (spell == GoubayuHeal.Rejuvenation) then
                hotCoeff = 0.8
            elseif (spell == GoubayuHeal.Regrowth) then
                hotCoeff = 0.5
            end
            hot_bonus = healbonus * hotCoeff
            final_hot = final_hot + hot_bonus

            local final_direct_heal = (base_direct_heal + direct_bonus) * talent_bonus
            final_hot = final_hot * talent_bonus

            local actual_heal = final_direct_heal + final_hot
            local diff = math.abs(actual_heal - expected_heal)

            if diff < min_diff then
                min_diff = diff
                best_rank = i
                best_actual_heal = actual_heal
            end
        end
    end

    if GoubayuHeal.Spells and GoubayuHeal.Spells[spell] and not found_base then
        return max_rank_limit
    end

    local max_rank = 1
    local limited_max_rank = max_rank_limit
    if GoubayuHeal.Spells and GoubayuHeal.Spells[spell] then
        max_rank = table.getn(GoubayuHeal.Spells[spell])
        limited_max_rank = math.min(max_rank_limit, max_rank)
    end

    if GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
        and best_rank < limited_max_rank and best_actual_heal < expected_heal then
        for i = best_rank + 1, limited_max_rank do
            local base_heal = (GoubayuHeal.Spells[spell][i]["Heal"] or 0)
            local base_healmin = (GoubayuHeal.Spells[spell][i]["HealMin"] or 0)
            local base_healmax = (GoubayuHeal.Spells[spell][i]["HealMax"] or 0)
            local base_hot = (GoubayuHeal.Spells[spell][i]["HealingOverTime"] or 0)

            if spell == GoubayuHeal.Renew then
                local default_hot_values = {
                    [1] = 55, [2] = 115, [3] = 205, [4] = 285, [5] = 315,
                    [6] = 395, [7] = 505, [8] = 640, [9] = 795, [10] = 950
                }
                base_hot = default_hot_values[i] or base_hot
                local r1 = GoubayuHeal_GetTalentRank(2, 1)
                local r2 = GoubayuHeal_GetTalentRank(2, 10)
                if r1 and r1 > 0 then
                    base_hot = base_hot * (1 + 0.05 * r1)
                end
                if r2 and r2 > 0 then
                    base_hot = base_hot * 6 / 5
                end
            elseif spell == GoubayuHeal.Rejuvenation then
                local default_hot_values = {
                    [1] = 36, [2] = 60, [3] = 120, [4] = 180, [5] = 246,
                    [6] = 306, [7] = 390, [8] = 492, [9] = 612, [10] = 756, [11] = 888
                }
                base_hot = default_hot_values[i] or base_hot
            end

            if base_healmin == 0 and base_healmax == 0 and base_heal > 0 then
                base_healmin = base_heal
                base_healmax = base_heal
            end

            local base_direct_heal = base_heal
            if (GoubayuHeal.player_in_combat) then
                base_direct_heal = base_direct_heal + base_healmin
            else
                base_direct_heal = base_direct_heal + base_healmax
            end

            local peni = (penaltyTbl and penaltyTbl[i]) or 1
            local healbonus = scaleBaseBonus * peni / pen1
            local originalCastTime = GoubayuHeal.GetSpellBaseCastTime(spell, i,
                GoubayuHeal.Spells[spell][i]["CastTime"] or 0)

            local bonusCastTime = originalCastTime
            if (bonusCastTime > GoubayuHeal.bonus_divide) then
                bonusCastTime = GoubayuHeal.bonus_divide
            end

            local direct_bonus
            local coeff = GoubayuHeal.GetSpellHealCoeff(spell, originalCastTime, i)
            if (coeff) then
                direct_bonus = healbonus * coeff
            else
                direct_bonus = healbonus * bonusCastTime / GoubayuHeal.bonus_divide
            end
            if (spell == GoubayuHeal.Holy_nova) then
                direct_bonus = healbonus * 0.106
            end

            local final_hot = base_hot
            local hot_bonus = 0
            -- Turtle 172 HoT 加成系数：恢复 0.85（1级 0.442、2级 0.646）、回春术 0.8、愈合 HoT 部分 0.5
            local hotCoeff = 0.85
            if (spell == GoubayuHeal.Renew) then
                if (i == 1) then
                    hotCoeff = 0.442
                elseif (i == 2) then
                    hotCoeff = 0.646
                end
            elseif (spell == GoubayuHeal.Rejuvenation) then
                hotCoeff = 0.8
            elseif (spell == GoubayuHeal.Regrowth) then
                hotCoeff = 0.5
            end
            hot_bonus = healbonus * hotCoeff
            final_hot = final_hot + hot_bonus

            local final_direct_heal = (base_direct_heal + direct_bonus) * talent_bonus
            final_hot = final_hot * talent_bonus

            local actual_heal = final_direct_heal + final_hot

            if actual_heal >= expected_heal then
                best_rank = i
                best_actual_heal = actual_heal
                break
            end
        end
    end

    return best_rank
end

-- ============================================================
-- 获取单位治疗优先级
-- ============================================================

GoubayuHeal.class_power_cache = GoubayuHeal.class_power_cache or {}

local function GoubayuHeal_GetClassPower(unit)
    local cpc = GoubayuHeal.class_power_cache
    local now = GetTime()
    local e = cpc[unit]

    if e and (now - e.time) < 2.0 then
        return e.class, e.powerType
    end

    local _, classFile = UnitClass(unit)
    local pt = UnitPowerType(unit)
    if not classFile then
        classFile = ""
    end

    cpc[unit] = { class = classFile, powerType = pt, time = now }
    return classFile, pt
end

function GoubayuHeal.GetPriority(unit)
    local priority = 1
    local hasEssenceOfEluneBonus = false

    local bonusPercentage = (GoubayuHeal.Config and GoubayuHeal.Config["essence_of_elune_bonus"]) or 0
    if GoubayuHeal.my_class == GoubayuHeal.Druid and bonusPercentage > 0 then
        if GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Regrowth)
            or GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Rejuvenation) then
            hasEssenceOfEluneBonus = true
        end
    end

    if (GetNumRaidMembers() > 0 and not string.find(unit, "pet")
        and GoubayuHeal.Config and GoubayuHeal.Config["raid_refined_priority"] == 1) then
        local pv = GoubayuHeal.Config["raid_priorities"]
            and GoubayuHeal.Config["raid_priorities"][GoubayuHeal.UnitName(unit)]
        priority = priority * (pv or 0.5)
    end

    if (UnitIsUnit("player", unit)) then
        priority = priority * (GoubayuHeal.Config["player_priority"] or 1.0)
    elseif (UnitInParty(unit) and not string.find(unit, "pet")) then
        priority = priority * (GoubayuHeal.Config["party_priority"] or 0.8)
    elseif (not string.find(unit, "pet") and UnitInRaid(unit)) then
        priority = priority * (GoubayuHeal.Config["raid_priority"] or 0.5)
    else
        priority = priority * (GoubayuHeal.Config["pet_priority"] or 0.2)
    end

    if (not UnitIsUnit("player", unit)) then
        local classFile, powerType = GoubayuHeal_GetClassPower(unit)
        local classPri = GoubayuHeal.Config["class_priority"]

        if (GoubayuHeal.Config["shapeshifted_druids"] == 1 and classFile == "DRUID") then
            if (powerType == 0) then
                priority = priority * (classPri["DRUID"] or 1)
            elseif (powerType == 1) then
                priority = priority * (classPri["WARRIOR"] or 1)
            else
                priority = priority * (classPri["ROGUE"] or 1)
            end
        else
            priority = priority * (classPri[classFile] or 1)
        end
    end

    if (priority <= 0) then
        return 0
    end

    local uname = GoubayuHeal.UnitName(unit)
    local role = uname and GoubayuHeal.Config["raid_roles"]
        and GoubayuHeal.Config["raid_roles"][uname]

    local tankBonus = 0
    if (role == "MT") then
        tankBonus = GoubayuHeal.Config["MT_priority"]
    elseif (role and string.find(role, "^%d+T$")) then
        local tier = tonumber(string.match(role, "^(%d+)T$")) or 0
        if (tier >= 2 and tier <= 8) then
            tankBonus = GoubayuHeal.Config["MT_priority"] * (9 - tier) / 8
        end
    end

    if (tankBonus > 0) then
        priority = priority + tankBonus
    elseif (GoubayuHeal.IsMT(unit)) then
        priority = priority + GoubayuHeal.Config["MT_priority"]
    end

    for buff, prioritychange in GoubayuHeal.Config["buff_affect_priority"] do
        if (GoubayuHeal.UnitGotBuff(unit, buff)) then
            priority = priority - prioritychange
        end
    end

    for debuff, prioritychange in GoubayuHeal.Config["debuff_affect_priority"] do
        if (GoubayuHeal.UnitGotDebuff(unit, debuff)) then
            priority = priority + prioritychange
        end
    end

    if hasEssenceOfEluneBonus then
        local bonusFactor = 1 + bonusPercentage / 100
        priority = priority * bonusFactor
    end

    return priority
end

-- ============================================================
-- 法术预估数据自定义
-- ============================================================

function GoubayuHeal.GetSpellOverride(spell, rank)
    if (not GoubayuHeal.Config) then
        return nil
    end
    local ovr = GoubayuHeal.Config["spell_data_override"]
    if (not ovr or not ovr[spell]) then
        return nil
    end
    return ovr[spell][rank]
end

function GoubayuHeal.GetSpellBaseHeal(spell, rank)
    local ovr = GoubayuHeal.GetSpellOverride(spell, rank)
    if (ovr and ovr["Heal"]) then
        return tonumber(ovr["Heal"]) or 0
    end

    local sd = GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
        and GoubayuHeal.Spells[spell][rank]
    if (not sd) then
        return 0
    end

    -- 宁静：基础治疗量 = 每秒恢复 × 引导持续秒数（如 1级 123×4，满级 123×10）
    if (spell == GoubayuHeal.Tranquility) then
        local perSec = sd["Heal"] or 0
        local ch = sd["ChannelTime"] or 0
        if perSec > 0 and ch > 0 then
            return perSec * ch
        end
    end

    local h = sd["Heal"] or 0
    local hm = sd["HealMin"] or 0
    local hx = sd["HealMax"] or 0

    if (hm > 0 or hx > 0) then
        return (hm + hx) / 2
    end
    if (h > 0) then
        return h
    end
    -- 纯HoT技能（恢复/回春术：仅 HealingOverTime）与吸收技能（真言术：盾：仅 Absorb）
    local hot = sd["HealingOverTime"] or 0
    if (hot > 0) then
        return hot
    end
    local ab = sd["Absorb"] or 0
    if (ab > 0) then
        return ab
    end
    return 0
end

function GoubayuHeal.GetSpellHealPowerRatio(spell, rank)
    local ovr = GoubayuHeal.GetSpellOverride(spell, rank)
    if (ovr and ovr["Ratio"]) then
        return tonumber(ovr["Ratio"]) or 0
    end

    if (spell == GoubayuHeal.Holy_nova) then
        return 0.106
    end

    -- 神圣打击（Holy Strike）法伤加成系数 0.05（实测修正） by 武藤纯子酱 2026.9.6
    if (spell == GoubayuHeal.Holy_Strike) then
        return 0.05
    end

    -- 表值优先（Turtle 172 系数表，含瞬发技能如盾/震/绝望祷言）
    local sd = GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
        and GoubayuHeal.Spells[spell][rank]
    if (not sd) then
        return 0
    end

    local coeff = GoubayuHeal.GetSpellHealCoeff(spell, sd["CastTime"], rank)
    if (coeff) then
        return coeff
    end

    -- 无表值：按基础施法时间连续比例（不受减时天赋影响），上限3.5s
    local realcast = GoubayuHeal.GetSpellBaseCastTime(spell, rank, sd["CastTime"])
    local r = realcast
    if (r > GoubayuHeal.bonus_divide) then
        r = GoubayuHeal.bonus_divide
    end

    local ratio = r / (GoubayuHeal.bonus_divide or 3.5)
    if (ratio > 1) then
        ratio = 1
    end
    return ratio
end

function GoubayuHeal.GetSpellScale(spell, rank)
    local ovr = GoubayuHeal.GetSpellOverride(spell, rank)
    if (ovr and ovr["Scale"]) then
        return tonumber(ovr["Scale"]) or 1
    end
    return 1
end

function GoubayuHeal.ResetSpellOverride(spell)
    if (not GoubayuHeal.Config or not GoubayuHeal.Config["spell_data_override"]) then
        return
    end
    GoubayuHeal.Config["spell_data_override"][spell] = nil
end

-- ============================================================
-- 计算法术实际治疗量
-- ============================================================

-- 目标身上"治疗之道"buff的层数（0-3）：萨满治疗波命中后给目标叠加，每层使其受到的治疗波/
-- 治疗链治疗量 +6%（最多3层=18%）。从 player_data（覆盖全队/团队成员的 buff 记录，含层数）读取。
function GoubayuHeal.GetHealingWayStacks(unit)
    if not (unit and GoubayuHeal.player_data) then
        return 0
    end
    local name = GoubayuHeal.UnitName(unit)
    if not name then
        return 0
    end
    local pd = GoubayuHeal.player_data[name]
    if not (pd and pd["Buff"]) then
        return 0
    end
    for _, data in pairs(pd["Buff"]) do
        if data and data["Name"] == GoubayuHeal.Healing_way then
            local c = tonumber(data["Count"]) or 1
            if c > 3 then c = 3 end
            if c < 0 then c = 0 end
            return c
        end
    end
    return 0
end

function GoubayuHeal.GetSpellHealing(unit, spell, rank)
    if (not GoubayuHeal.Spells) then
        if type(GoubayuHeal.UpdateSpells) == "function" then
            GoubayuHeal.UpdateSpells()
        else
            return 0, 0, 0, 0
        end
    end

    if (not spell or not rank or not GoubayuHeal.Spells[spell]
        or not GoubayuHeal.Spells[spell][rank]) then
        return 0, 0, 0, 0
    end

    local healbonus = GoubayuHeal.GetHealBonus(unit, spell, rank)

    -- 迅捷治愈特殊处理
    if (spell == GoubayuHeal.Swiftmend) then
        local data = GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Rejuvenation)
        if (data) then
            local start, stop
            GoubayuHeal.temp_table = (GoubayuHeal.temp_table or {})
            GoubayuHeal.temp_table2 = (GoubayuHeal.temp_table2 or {})
            start, stop, GoubayuHeal.temp_table[1], GoubayuHeal.temp_table[2] =
                string.find(data["Text"], GoubayuHeal.hot_search)

            if (not start) then
                return 0, 0, 0, 0
            end

            for index, value in GoubayuHeal.hot_text do
                GoubayuHeal.temp_table2 = (GoubayuHeal.temp_table2 or {})
                local tval = GoubayuHeal.temp_table[index]
                GoubayuHeal.temp_table2[value] = (tval and tval / 1.0) or 0
            end

            -- 迅捷治愈吞噬回春：治疗量 = 12秒的回春量（每跳×4，回春3秒一跳）
            local heal = (GoubayuHeal.temp_table2["Heal"] or 0) * 4
                + healbonus * 12 / GoubayuHeal.bonus_instant_divide
            return heal, heal, heal, 0
        end

        data = GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Regrowth)
        if (data) then
            local start, stop
            GoubayuHeal.temp_table = (GoubayuHeal.temp_table or {})
            GoubayuHeal.temp_table2 = (GoubayuHeal.temp_table2 or {})
            start, stop, GoubayuHeal.temp_table[1], GoubayuHeal.temp_table[2] =
                string.find(data["Text"], GoubayuHeal.hot_search)

            if (not start) then
                return 0, 0, 0, 0
            end

            for index, value in GoubayuHeal.hot_text do
                GoubayuHeal.temp_table2 = (GoubayuHeal.temp_table2 or {})
                local tval = GoubayuHeal.temp_table[index]
                GoubayuHeal.temp_table2[value] = (tval and tval / 1.0) or 0
            end

            -- 迅捷治愈治疗量 = 目标身上该愈合HOT的18秒量（每跳×6）。
            -- 庇佑(3,13)是隐藏天赋效果（不显示在 buff/技能上）：按"施放愈合时"打的标换算
            -- （该次施放时目标有回春 + 自身有天赋 → 该愈合HOT +30%）
            local wayM = 1
            if GoubayuHeal.IsRegrowthAmplified and GoubayuHeal.IsRegrowthAmplified(unit) then
                local wayR = GoubayuHeal.GetBenevolenceRank and GoubayuHeal.GetBenevolenceRank() or 0
                if wayR > 0 then
                    wayM = 1 + 0.10 * wayR
                end
            end
            local heal = (GoubayuHeal.temp_table2["Heal"] or 0) * 6 * wayM
                + healbonus * 15 / GoubayuHeal.bonus_instant_divide
            return heal, heal, heal, 0
        end

        if (GetNampowerVersion) then
            local rejuRank = GoubayuHeal.GetUnitHOTRank(unit, GoubayuHeal.Rejuvenation)
            local regRank = GoubayuHeal.GetUnitHOTRank(unit, GoubayuHeal.Regrowth)
            local hotSpell, hotRank, tickBonus

            if (rejuRank) then
                hotSpell, hotRank, tickBonus = GoubayuHeal.Rejuvenation, rejuRank, 12
            elseif (regRank) then
                hotSpell, hotRank, tickBonus = GoubayuHeal.Regrowth, regRank, 15
            end

            if (hotSpell and GoubayuHeal.Spells and GoubayuHeal.Spells[hotSpell]
                and GoubayuHeal.Spells[hotSpell][hotRank]) then
                local hotTotal = GoubayuHeal.Spells[hotSpell][hotRank]["HealingOverTime"] or 0
                -- 庇佑(3,13)：消耗的是愈合时，按"施放愈合时"打的标补乘隐藏放大
                if hotSpell == GoubayuHeal.Regrowth
                    and GoubayuHeal.IsRegrowthAmplified and GoubayuHeal.IsRegrowthAmplified(unit) then
                    local wayR = GoubayuHeal.GetBenevolenceRank and GoubayuHeal.GetBenevolenceRank() or 0
                    if wayR > 0 then
                        hotTotal = hotTotal * (1 + 0.10 * wayR)
                    end
                end
                if (hotTotal > 0) then
                    local heal = hotTotal + healbonus * tickBonus / GoubayuHeal.bonus_instant_divide
                    return heal, heal, heal, 0
                end
            end
        end
    end

    local heal = (GoubayuHeal.Spells[spell][rank]["Heal"] or 0)
    local healmin = (GoubayuHeal.Spells[spell][rank]["HealMin"] or 0)
    local healmax = (GoubayuHeal.Spells[spell][rank]["HealMax"] or 0)
    local hot = (GoubayuHeal.Spells[spell][rank]["HealingOverTime"] or 0)

    if healmin == 0 and healmax == 0 and heal > 0 then
        healmin = heal
        healmax = heal
    end

    local spellOverride = GoubayuHeal.GetSpellOverride(spell, rank)
    if spellOverride and spellOverride["Heal"] then
        local b = tonumber(spellOverride["Heal"]) or 0
        heal = 0
        healmin = b
        healmax = b
    end

    local originalCastTime = GoubayuHeal.GetSpellBaseCastTime(spell, rank,
        GoubayuHeal.Spells[spell][rank]["CastTime"] or 0)

    -- 表值优先（Turtle 172 系数表），无表值按基础施法时间连续比例（不受减时天赋影响），上限3.5s
    local bonus
    local coeff = GoubayuHeal.GetSpellHealCoeff(spell, originalCastTime, rank)
    if (coeff) then
        bonus = healbonus * coeff
    else
        local bonusCastTime = originalCastTime
        if (bonusCastTime > GoubayuHeal.bonus_divide) then
            bonusCastTime = GoubayuHeal.bonus_divide
        end
        bonus = healbonus * bonusCastTime / GoubayuHeal.bonus_divide
    end
    if (spell == GoubayuHeal.Holy_nova) then
        bonus = healbonus * 0.106
    end

    if spellOverride and spellOverride["Ratio"] then
        bonus = healbonus * (tonumber(spellOverride["Ratio"]) or 0)
    end

    if (GoubayuHeal.player_in_combat) then
        heal = heal + healmin
    else
        heal = heal + healmax
    end
    heal = heal + bonus
    healmin = healmin + bonus
    healmax = healmax + bonus

    local duration = (GoubayuHeal.hot_duration[spell] or 0)
    local hot_bonus = 0

    if (spell == GoubayuHeal.Renew) then
        local default_hot_values = {
            [1] = 55, [2] = 115, [3] = 205, [4] = 285, [5] = 315,
            [6] = 395, [7] = 505, [8] = 640, [9] = 795, [10] = 950
        }
        hot = default_hot_values[rank] or hot
    elseif (spell == GoubayuHeal.Rejuvenation) then
        local default_hot_values = {
            [1] = 36, [2] = 60, [3] = 120, [4] = 180, [5] = 246,
            [6] = 306, [7] = 390, [8] = 492, [9] = 612, [10] = 756, [11] = 888
        }
        hot = default_hot_values[rank] or hot
    end

    if (spell == GoubayuHeal.Renew) then
        local r1 = GoubayuHeal_GetTalentRank(2, 1)
        local r2 = GoubayuHeal_GetTalentRank(2, 10)
        if r1 and r1 > 0 then
            hot = hot * (1 + 0.05 * r1)
        end
        if r2 and r2 > 0 then
            hot = hot * 6 / 5
        end
    end

    if (hot > 0) then
        -- Turtle 172 HoT 加成系数：恢复 0.85（1级 0.442、2级 0.646）、回春术 0.8、愈合 HoT 部分 0.5
        local hotCoeff = 0.85
        if (spell == GoubayuHeal.Renew) then
            if (rank == 1) then
                hotCoeff = 0.442
            elseif (rank == 2) then
                hotCoeff = 0.646
            end
        elseif (spell == GoubayuHeal.Rejuvenation) then
            hotCoeff = 0.8
        elseif (spell == GoubayuHeal.Regrowth) then
            hotCoeff = 0.5
        end
        hot_bonus = healbonus * hotCoeff
        hot = hot + hot_bonus
    end

    -- 德鲁伊天赋"庇佑"(3,13)：目标身上有回春效果时，愈合的持续治疗(HOT)部分提升 10%/天赋等级
    -- （最多3级=30%）；仅作用于 HOT 分量（直接治疗段不变）
    if GoubayuHeal.my_class == GoubayuHeal.Druid and spell == GoubayuHeal.Regrowth
        and hot > 0 and GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Rejuvenation) then
        local r = GoubayuHeal_GetTalentRank(3, 13)
        if r > 0 then
            hot = hot * (1 + 0.10 * r)
        end
    end

    heal = heal + hot

    local talentBonus = GoubayuHeal_GetTalentBonus()
    if talentBonus > 1.0 then
        heal = heal * talentBonus
        healmin = healmin * talentBonus
        healmax = healmax * talentBonus
    end

    if (GoubayuHeal.my_class == GoubayuHeal.Paladin
        and (spell == GoubayuHeal.Flash_of_light or spell == GoubayuHeal.Holy_light)
        and GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Divine_favor)) then
        heal = heal * GoubayuHeal.critical_bonus
        healmin = healmin * GoubayuHeal.critical_bonus
        healmax = healmax * GoubayuHeal.critical_bonus
    end

    if (GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Power_infusion)) then
        heal = heal * 1.2
        healmin = healmin * 1.2
        healmax = healmax * 1.2
        hot = hot * 1.2
    end

    if (GoubayuHeal.player_in_combat) then
        if GoubayuHeal.UnitName(unit) == GoubayuHeal.Tank["Name"] then
            heal = heal - (GoubayuHeal.Spells[spell][rank]["CastTime"] or 0)
                * (GoubayuHeal.Config["MTCastTime_Debuff"] or 0)
        else
            heal = heal - (GoubayuHeal.Spells[spell][rank]["CastTime"] or 0)
                * (GoubayuHeal.Config["CastTime_Debuff"] or 0)
        end
    end

    -- 天赋(2,10)第二效果：目标身上有"恢复"HOT时（不论是谁上的），你对他的所有治疗法术
    -- 治疗量提升 3%/天赋等级（含次级治疗术/治疗术/强效治疗术/治疗祷言/快速治疗/恢复/神圣新星
    -- 等一切治疗法术；HOT 分量一并计入）
    if GoubayuHeal.my_class == GoubayuHeal.Priest
        and GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Renew) then
        local r2 = GoubayuHeal_GetTalentRank(2, 10)
        if r2 and r2 > 0 then
            local m = 1 + 0.03 * r2
            heal = heal * m
            healmin = healmin * m
            healmax = healmax * m
            hot = hot * m
        end
    end

    -- 萨满"治疗之道"：目标身上每层 +6% 治疗量（最多3层=18%），仅对治疗波/治疗链生效
    if GoubayuHeal.my_class == GoubayuHeal.Shaman
        and (spell == GoubayuHeal.Healing_wave or spell == GoubayuHeal.Chain_heal) then
        local stacks = GoubayuHeal.GetHealingWayStacks and GoubayuHeal.GetHealingWayStacks(unit) or 0
        if stacks > 0 then
            local m = 1 + 0.06 * stacks
            heal = heal * m
            healmin = healmin * m
            healmax = healmax * m
            hot = hot * m
        end
    end

    -- 圣骑士 T3.5 套装（手动档位）：3件 → 神圣震击治疗量 +192；5件 → 附加神圣打击治疗量 +10%
    if GoubayuHeal.my_class == GoubayuHeal.Paladin then
        local t35 = tonumber(GoubayuHeal.Config and GoubayuHeal.Config["paladin_tier35"]) or 0
        if t35 >= 1 and spell == GoubayuHeal.Holy_shock then
            heal = heal + 192
            healmin = healmin + 192
            healmax = healmax + 192
        end
        if t35 >= 2 and spell == GoubayuHeal.Holy_Strike then
            heal = heal * 1.10
            healmin = healmin * 1.10
            healmax = healmax * 1.10
            hot = hot * 1.10
        end
    end

    -- 德鲁伊 T2.5（5件，手动勾选）：治疗之触对受回春术或愈合影响的目标治疗量 +10%
    if GoubayuHeal.my_class == GoubayuHeal.Druid and spell == GoubayuHeal.Healing_touch
        and GoubayuHeal.Config and GoubayuHeal.Config["druid_5t25"] == 1 then
        if GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Rejuvenation)
            or GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Regrowth) then
            heal = heal * 1.10
            healmin = healmin * 1.10
            healmax = healmax * 1.10
            hot = hot * 1.10
        end
    end

    if spellOverride and spellOverride["Scale"] then
        local s = tonumber(spellOverride["Scale"]) or 1
        if s ~= 1 then
            heal = heal * s
            healmin = healmin * s
            healmax = healmax * s
            hot = hot * s
        end
    end

    return heal, healmin, healmax, hot
end

-- ============================================================
-- 计算过量治疗比例
-- ============================================================

function GoubayuHeal.GetOverheal()
    local healingtarget = GoubayuHeal.i_am_healing
    if (not healingtarget or not GoubayuHeal.healing[healingtarget]
        or not GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]) then
        return 0
    end

    local unit = GoubayuHeal.GetUnitID(healingtarget)
    if (not unit) then
        return 0
    end

    local uh, uhm = GoubayuHeal.GetUnitHealth(unit)

    if (uhm == 100) then
        local perLevel = GoubayuHeal.class_hp_per_level
            and GoubayuHeal.class_hp_per_level[UnitClass(unit)] or 0
        uhm = uhm * UnitLevel(unit) * perLevel / 100
        uh = uh * UnitLevel(unit) * perLevel / 100
    end

    local heal = GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Heal"]
    if (heal == 0) then
        heal = 1
    end

    local overheal = (uh + heal - uhm) / heal
    if (overheal > 1) then
        overheal = 1
    elseif (overheal < 0) then
        overheal = 0
    end
    return overheal
end

-- ============================================================
-- 计算治疗缺口量
-- ============================================================

-- 跨职业基础治疗量：读 DBC 里 effect==10(HEAL) 的 effectBasePoints/effectDieSides，返回均值；
-- 读不到/无 HEAL 效果 → nil（不估算）。by 武藤纯子酱 2026.10.20
function GoubayuHeal.GetDBCBaseHeal(spellId)
    if not (GetNampowerVersion and GetSpellRecField and spellId) then
        return nil
    end
    local okE, effs = pcall(GetSpellRecField, spellId, "effect")
    local okB, bases = pcall(GetSpellRecField, spellId, "effectBasePoints")
    local okD, dices = pcall(GetSpellRecField, spellId, "effectDieSides")
    if not (okE and effs and okB and bases) then
        return nil
    end
    local function at(v, i)
        if type(v) == "table" then
            return v[i]
        end
        if i == 1 then
            return v
        end
        return nil
    end
    for i = 1, 3 do
        if tonumber(at(effs, i)) == 10 then
            local b = tonumber(at(bases, i))
            if b then
                local d = tonumber(at(dices, i)) or 1
                if d < 1 then
                    d = 1
                end
                -- DBC 基础量实际为 basePoints+1，波动 dieSides（取均值）
                return (b + 1) + (d - 1) / 2
            end
        end
    end
    return nil
end

-- 非救急：他者正在读的治疗量预估（数据源 CastingSpeed.castData；治疗量按我方治疗强度估算）。
-- 我方技能表里有的按 GetSpellHealing 精确估；跨职业的用 DBC 基础量 + 我方治疗强度×系数。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.GetOtherCastingHealing(unit)
    local total = 0
    local CS = GoubayuHeal.CastingSpeed
    if not (CS and CS.castData and CS.GetPlayerGUID and GetSpellNameAndRankForId
        and GoubayuHeal.GetUnitGUID) then
        return 0
    end
    local guid = GoubayuHeal.GetUnitGUID(unit)
    if not guid or not CS.castData[guid] then
        return 0
    end
    local playerGUID = CS:GetPlayerGUID()
    local now = GetTime()
    for casterGUID, info in pairs(CS.castData[guid]) do
        if casterGUID ~= playerGUID and info and info.endTime and info.endTime > now
            and info.spellID then
            local ok, nm = pcall(GetSpellNameAndRankForId, info.spellID)
            if ok and nm then
                local base = string.gsub(nm, "%s*%(.*%)", "")
                local rk = tonumber(string.match(nm, "(%d+)%)"))
                if base and base ~= "" then
                    if rk and GoubayuHeal.Spells[base] and GoubayuHeal.Spells[base][rk] then
                        local h = GoubayuHeal.GetSpellHealing(unit, base, rk)
                        if h then
                            total = total + h
                        end
                    else
                        -- 跨职业：DBC 基础治疗量 + 我方治疗强度 × 系数
                        local bh = GoubayuHeal.GetDBCBaseHeal(info.spellID)
                        if bh then
                            local coeff = (GoubayuHeal.spell_heal_coeffs
                                and GoubayuHeal.spell_heal_coeffs[base]) or 0
                            local sp = (GoubayuHeal.GetSelfHealPower
                                and GoubayuHeal.GetSelfHealPower()) or 0
                            total = total + bh + sp * coeff
                        end
                    end
                end
            end
        end
    end
    return total
end

function GoubayuHeal.GetHealValue(unit)
    local currentHealth, maxHealth = GoubayuHeal.GetUnitHealth(unit)
    local hpmissing = maxHealth - currentHealth

    if (maxHealth == 100) then
        local perLevel = GoubayuHeal.class_hp_per_level
            and GoubayuHeal.class_hp_per_level[UnitClass(unit)] or 0
        local mult = UnitLevel(unit) * perLevel / 100
        hpmissing = hpmissing * mult
        currentHealth = currentHealth * mult
        maxHealth = maxHealth * mult
    end

    local tname = GoubayuHeal.UnitName(unit)
    -- 自身直接治疗在途（不含 HOT；HOT 统一走 trackedHOTs 的折减公式）
    local selfDirect = 0
    local rec = GoubayuHeal.healing and GoubayuHeal.healing[tname]
        and GoubayuHeal.healing[tname][GoubayuHeal.my_name]
    if rec and rec["Status"] == "Active" then
        selfDirect = rec["Heal"] or 0
    end
    local hp = (maxHealth > 0) and (currentHealth / maxHealth) or 0
    local hotEst = GoubayuHeal.TrackedHOTEstimate(tname, hp, hpmissing)

    -- 非救急（hp >= 救急线）才把"他者正在读的治疗量"计入缺口；救急线以下按分诊设计不等他人。
    -- by 武藤纯子酱 2026.10.20
    local otherDirect = 0
    if hp * 100 >= (tonumber(GoubayuHeal.Config["rescue_hp_threshold"]) or 40) then
        otherDirect = GoubayuHeal.GetOtherCastingHealing(unit)
    end

    -- 实际剩余缺口 = 当前缺口 - 他者在读直接治疗 - 自身在读直接治疗 - HOT 预估
    local actualHealValue = hpmissing - otherDirect - selfDirect - hotEst
    if actualHealValue < 0 then
        actualHealValue = 0
    end
    return actualHealValue
end

-- ============================================================
-- 自身BUFF法术强度（武器油等）
-- ============================================================

GoubayuHeal.weapon_oil_values = {
    [GoubayuHeal.Msg.WeaponOil1] = 25,
    [GoubayuHeal.Msg.WeaponOil2] = 25,
}

function GoubayuHeal.GetSelfBuffSpellPower()
    local bonus = 0
    local name = GoubayuHeal.my_name or UnitName("player")

    if GoubayuHeal.player_data and GoubayuHeal.player_data[name]
        and GoubayuHeal.player_data[name]["Buff"] then
        for texture, data in pairs(GoubayuHeal.player_data[name]["Buff"]) do
            local buffName = data and data["Name"]

            -- 跳过：①武器油（另有独立数值表）②名字表(my_buff_affect_healing_text)里已有的 buff
            -- ——后者由 GetHealBonus 的名字路径按 buff 名单独计入，此处通用文本扫描再算一次会重复
            if not (buffName and (GoubayuHeal.weapon_oil_values[buffName]
                or (GoubayuHeal.my_buff_affect_healing_text
                    and GoubayuHeal.my_buff_affect_healing_text[buffName]))) then
                local text = data and data["Text"]
                if text then
                    local found = false
                    for _, pat in ipairs(GoubayuHeal.self_heal_power_text) do
                        local s, e, val = string.find(text, pat)
                        if val then
                            bonus = bonus + (tonumber(val) or 0)
                            found = true
                            break
                        end
                    end
                    if not found then
                        for _, pat in ipairs(GoubayuHeal.self_spell_power_text) do
                            local s, e, val = string.find(text, pat)
                            if val then
                                bonus = bonus + (tonumber(val) or 0)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    return bonus
end

-- ============================================================
-- 插件自带的治疗强度计算
-- ============================================================

function GoubayuHeal.GetSelfHealPower()
    -- 2秒缓存：治疗决策频繁调用，避免每次重扫20个装备槽
    if GoubayuHeal.self_heal_power_time and (GetTime() - GoubayuHeal.self_heal_power_time) < 2 then
        return GoubayuHeal.self_heal_power or 0
    end

    local healPower = 0
    local spellPower = 0
    local spiritBonus = 0
    local set_seen = {}

    -- 离屏查询规范：填充前重建owner（冷启动首扫不SetOwner会填充失败并缓存全0）
    GoubayuHeal.ClearTooltip()

    for slot = 0, 19 do
        if GoubayuHeal_Tooltip:SetInventoryItem("player", slot) then
            for line = 1, GoubayuHeal_Tooltip:NumLines() do
                local left = getglobal("GoubayuHealTooltipTextLeft" .. line)
                local text = left and left:GetText() or nil

                if text then
                    if not (string.find(text, GoubayuHeal.TooltipPattern.Use[1])
                        or string.find(text, GoubayuHeal.TooltipPattern.Use[2])
                        or string.find(text, GoubayuHeal.TooltipPattern.Radius[1])
                        or string.find(text, GoubayuHeal.TooltipPattern.Radius[2])) then
                        local start, stop, v

                        local skipLine = false
                        if string.find(text, GoubayuHeal.TooltipPattern.Set[1])
                            or string.find(text, GoubayuHeal.TooltipPattern.Set[2]) then
                            local setSig = string.gsub(text, "%d", "#")
                            if set_seen[setSig] then
                                skipLine = true
                            else
                                set_seen[setSig] = true
                            end
                        end

                        local oilMatched = false
                        for oilName, oilValue in pairs(GoubayuHeal.weapon_oil_values) do
                            if string.find(text, oilName) then
                                spellPower = spellPower + oilValue
                                oilMatched = true
                                break
                            end
                        end

                        if not oilMatched and not skipLine then
                            for _, pat in ipairs(GoubayuHeal.self_heal_power_text) do
                                start, stop, v = string.find(text, pat)
                                if v then
                                    healPower = healPower + (tonumber(v) or 0)
                                    break
                                end
                            end

                            for _, pat in ipairs(GoubayuHeal.self_spell_power_text) do
                                start, stop, v = string.find(text, pat)
                                if v then
                                    spellPower = spellPower + (tonumber(v) or 0)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if GoubayuHeal.my_class == GoubayuHeal.Priest then
        local crank = GoubayuHeal_GetTalentRank(2, 12)
        local base, cur = UnitStat("player", 5)
        spiritBonus = crank * 0.05 * cur
    end

    local buffBonus = GoubayuHeal.GetSelfBuffSpellPower()
    local result = healPower + spellPower + spiritBonus + buffBonus

    GoubayuHeal.self_heal_power = result
    GoubayuHeal.self_heal_power_time = GetTime()
    return result
end

-- ============================================================
-- BCS治疗强度查询
-- ============================================================

GoubayuHeal._bcs_heal_power_cache = { time = 0, value = nil }

function GoubayuHeal.GetBCSHealPower()
    local now = GetTime()
    local c = GoubayuHeal._bcs_heal_power_cache

    if c.time and (now - c.time) < 0.5 then
        return c.value
    end

    c.time = now

    if not (BCS and BCS.GetHealingPower and BCS.GetSpellPower) then
        c.value = nil
        return nil
    end

    local ok1, healPower = pcall(BCS.GetHealingPower, BCS)
    if not ok1 then
        c.value = nil
        return nil
    end

    local ok2, spellPower, _, _, dmg = pcall(BCS.GetSpellPower, BCS)
    if not ok2 or not spellPower then
        c.value = nil
        return nil
    end

    local v = (healPower or 0) + (spellPower or 0) - (dmg or 0)
    c.value = v
    return v
end

-- ============================================================
-- 计算治疗强度加成总量
-- ============================================================

function GoubayuHeal.GetHealBonus(unit, spell, rank)
    local healbonus = 0
    GoubayuHeal.temp_table = (GoubayuHeal.temp_table or {})
    GoubayuHeal.temp_table2 = (GoubayuHeal.temp_table2 or {})
    GoubayuHeal.temp_table2[spell] = 0
    GoubayuHeal.temp_table2["HealUp"] = 0
    GoubayuHeal.temp_table2["HealDown"] = 0

    GoubayuHeal.buff_heal_bonus["TargetBuffs"] = 0
    GoubayuHeal.buff_heal_bonus["MyBuffs"] = 0
    GoubayuHeal.buff_heal_bonus["Debuffs"] = 0

    if (spell == GoubayuHeal.Flash_of_light or spell == GoubayuHeal.Holy_light) then
        local data = GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Blessing_of_light)
        data = (data or GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Greater_blessing_of_light))

        if (data and data["Text"]) then
            local start, stop
            start, stop, GoubayuHeal.temp_table[1], GoubayuHeal.temp_table[2] =
                string.find(data["Text"], GoubayuHeal.blessing_of_light_search)

            if (start) then
                for index, value in GoubayuHeal.blessing_of_light_text do
                    local bonus = (GoubayuHeal.temp_table2[value] or 0)
                        * (GoubayuHeal.bonus_divide / (GoubayuHeal.Spells[spell][rank]["CastTime"] or 1))
                        + GoubayuHeal.temp_table[index]
                    GoubayuHeal.temp_table2[value] = bonus
                    GoubayuHeal.buff_heal_bonus["TargetBuffs"] = GoubayuHeal.buff_heal_bonus["TargetBuffs"]
                        + GoubayuHeal.temp_table[index]
                end
            end
        end
    end

    for buff, search in GoubayuHeal.buff_affect_healing_search do
        local data = GoubayuHeal.UnitGotBuff(unit, buff)
        if (data and data["Text"]) then
            local start, stop
            start, stop, GoubayuHeal.temp_table[1], GoubayuHeal.temp_table[2] =
                string.find(data["Text"], search)

            if (start) then
                for index, value in (GoubayuHeal.buff_affect_healing_text[buff] or {}) do
                    local bonus = (GoubayuHeal.temp_table[index] or 0)
                    GoubayuHeal.temp_table2[value] = (GoubayuHeal.temp_table2[value] or 0) + bonus
                    GoubayuHeal.buff_heal_bonus["TargetBuffs"] = GoubayuHeal.buff_heal_bonus["TargetBuffs"]
                        + bonus
                end
            end
        end
    end

    for debuff, search in GoubayuHeal.debuff_affect_healing_search do
        local data = GoubayuHeal.UnitGotDebuff(unit, debuff)
        if (data and data["Text"]) then
            local start, stop
            start, stop, GoubayuHeal.temp_table[1], GoubayuHeal.temp_table[2] =
                string.find(data["Text"], search)

            if (start) then
                for index, value in (GoubayuHeal.debuff_affect_healing_text[debuff] or {}) do
                    local bonus = (GoubayuHeal.temp_table[index] or 0)
                    GoubayuHeal.temp_table2[value] = (GoubayuHeal.temp_table2[value] or 0) + bonus
                    GoubayuHeal.buff_heal_bonus["Debuffs"] = GoubayuHeal.buff_heal_bonus["Debuffs"]
                        + bonus
                end
            end
        end
    end

    for buff, search in GoubayuHeal.my_buff_affect_healing_search do
        local data = GoubayuHeal.UnitGotBuff("player", buff)
        if (data and data["Text"]) then
            local start, stop
            start, stop, GoubayuHeal.temp_table[1], GoubayuHeal.temp_table[2] =
                string.find(data["Text"], search)

            if (start) then
                for index, value in (GoubayuHeal.my_buff_affect_healing_text[buff] or {}) do
                    local bonus = (GoubayuHeal.temp_table[index] or 0)
                    GoubayuHeal.temp_table2[value] = (GoubayuHeal.temp_table2[value] or 0) + bonus
                    GoubayuHeal.buff_heal_bonus["MyBuffs"] = GoubayuHeal.buff_heal_bonus["MyBuffs"]
                        + bonus
                end
            end
        end
    end

    healbonus = healbonus + (GoubayuHeal.temp_table2[spell] or 0)
    healbonus = healbonus + (GoubayuHeal.temp_table2["HealUp"] or 0)
    healbonus = healbonus - (GoubayuHeal.temp_table2["HealDown"] or 0)

    local bcsPower = GoubayuHeal.GetBCSHealPower()
    if bcsPower and bcsPower > 0 then
        healbonus = healbonus + bcsPower
    else
        local equipmentBonus = GoubayuHeal.GetSelfHealPower()
        healbonus = healbonus + equipmentBonus
    end

    if (GoubayuHeal.low_level_spell_bonus_penalty[spell]
        and GoubayuHeal.low_level_spell_bonus_penalty[spell][rank]) then
        healbonus = healbonus * GoubayuHeal.low_level_spell_bonus_penalty[spell][rank]
    end

    return healbonus
end

-- ============================================================
-- 单位可治疗性判断
-- ============================================================

function GoubayuHeal.CanHeal(unit)
    if (not UnitExists(unit) or UnitIsDeadOrGhost(unit)
        or not UnitIsFriend("player", unit) or not UnitIsVisible(unit)) then
        return
    else
        GoubayuHeal.debuff_unable_to_heal = GoubayuHeal.debuff_unable_to_heal or {}

        for buff, one in GoubayuHeal.buff_unable_to_heal do
            if (GoubayuHeal.UnitGotBuff(unit, buff)) then
                return
            end
        end

        for debuff, one in GoubayuHeal.debuff_unable_to_heal do
            if (GoubayuHeal.UnitGotDebuff(unit, debuff)) then
                return
            end
        end

        return 1
    end
end

-- ============================================================
-- 单位可复活性判断
-- ============================================================

function GoubayuHeal.CanRez(unit)
    if (not UnitExists(unit) or not UnitIsDead(unit)
        or not UnitIsFriend("player", unit) or not UnitIsConnected(unit)) then
        return
    else
        return 1
    end
end

-- ============================================================
-- 检查是否有人正在复活目标
-- ============================================================

function GoubayuHeal.GetOtherRezing(player)
    local name = GoubayuHeal.UnitName(player)

    if (GoubayuHeal.healing[name]) then
        for rezer, data in GoubayuHeal.healing[name] do
            if (GoubayuHeal.rez_spells[GoubayuHeal.healing[name][rezer]["Spell"]]
                and GoubayuHeal.healing[name][rezer]["Status"] == "Active") then
                return 1
            end
        end
    end
    -- 以下两项与上面的判断相互独立（原先用 elseif：healing 里有该目标的任何记录时
    -- 会跳过 CT_RA/oRA 的"他人正在复活"检测，导致重复复活）
    -- by 武藤纯子酱 2026.10.21
    if (CT_RA_Ressers) then
        for rezer, data in CT_RA_Ressers do
            if data == name then
                return 1
            end
        end
    end
    if oRA_Resurrection then
        for rezer, data in oRA_Resurrection.ressers do
            if data == name then
                return 1
            end
        end
    end

    -- Nampower 通道：healing 表只记录本地玩家自己的施法、CT_RA/oRA 未装时无数据，
    -- 上面的检测对"别人"恒为空；靠 SPELL_START_OTHER 跟踪的他人复活读条做竞速避让，
    -- 避免别人先起手复活同一目标时一键复活宏重复施放（白费蓝与技能）
    -- by 武藤纯子酱 2026.9.4
    local guid = GoubayuHeal.GetUnitGUID(player)
    if (guid and GoubayuHeal.CastingSpeed
        and GoubayuHeal.CastingSpeed.IsOtherRezing
        and GoubayuHeal.CastingSpeed:IsOtherRezing(guid)) then
        return 1
    end

    return
end

-- ============================================================
-- 发送复活喊话
-- ============================================================

function GoubayuHeal.SendRezMessage(targetName, channel)
    if (not channel or channel == "NONE") then
        return
    end

    local msg = GoubayuHeal.Config["rez_message"] or ""
    local name = targetName or ""
    msg = string.gsub(msg, "%$t", name)

    if (channel == "RAID" and GetNumRaidMembers() <= 0) then
        channel = "PARTY"
    end

    SendChatMessage(msg, channel)
end

-- ============================================================
-- 复活施法开始处理
-- ============================================================

function GoubayuHeal.OnRezCastStart(spellName, arg3)
    if not spellName then
        return
    end
    if not (GoubayuHeal.rez_spells and GoubayuHeal.rez_spells[spellName]) then
        return
    end

    local channel = GoubayuHeal.Config and GoubayuHeal.Config["rez_message_channel"]
    local targetName = nil

    if GetNampowerVersion and GetCastInfo and GoubayuHeal.UnitNameFromGUID then
        local ci = GetCastInfo()
        if ci and ci.guid then
            targetName = GoubayuHeal.UnitNameFromGUID(ci.guid)
        end
    end

    if not targetName then
        targetName = arg3
        if targetName and (targetName == "player" or string.find(targetName, "^party")
            or string.find(targetName, "^raid")) then
            targetName = GoubayuHeal.UnitName(targetName)
        end
    end

    if not targetName then
        targetName = GoubayuHeal.i_am_healing
    end

    GoubayuHeal.SendRezMessage(targetName, channel)
end

-- ============================================================
-- 一键复活
-- ============================================================

function GoubayuHeal.DoRez()
    -- 首登自愈：SetupSettings 在 PLAYER_LOGIN 跑，法术书未就绪时 Spells 里没有复活技能，
    -- rez_spell/rez_rank 留空且整个会话不再补算 → /gbyh rez 静默失败。
    -- 惰性补算：库已重建而配置仍缺时，按当前职业重建（与 SetupSettings 同口径）
    if GoubayuHeal.Spells and not GoubayuHeal.Config["rez_spell"] then
        local classRez
        if GoubayuHeal.my_class == GoubayuHeal.Shaman then
            classRez = GoubayuHeal.Ancestral_Spirit
        elseif GoubayuHeal.my_class == GoubayuHeal.Druid then
            classRez = GoubayuHeal.Rebirth
        elseif GoubayuHeal.my_class == GoubayuHeal.Priest then
            classRez = GoubayuHeal.Resurrection
        elseif GoubayuHeal.my_class == GoubayuHeal.Paladin then
            classRez = GoubayuHeal.Redemption
        end
        if classRez and GoubayuHeal.Spells[classRez] then
            GoubayuHeal.Config["rez_spell"] = classRez
        else
            for spell, data in GoubayuHeal.Spells do
                if GoubayuHeal.rez_spells[spell] then
                    GoubayuHeal.Config["rez_spell"] = spell
                end
            end
        end
        local rezspell = GoubayuHeal.Config["rez_spell"]
        if rezspell and GoubayuHeal.Spells[rezspell] then
            GoubayuHeal.Config["rez_rank"] = (GoubayuHeal.Config["rez_rank"]
                or table.getn(GoubayuHeal.Spells[rezspell]))
        end
    end

    -- rez_rank 兜底：rez_spell 已存在但 rank 缺失（法术书晚就绪）时按库补算
    if GoubayuHeal.Config["rez_spell"] and not GoubayuHeal.Config["rez_rank"]
        and GoubayuHeal.Spells and GoubayuHeal.Spells[GoubayuHeal.Config["rez_spell"]] then
        GoubayuHeal.Config["rez_rank"] = table.getn(GoubayuHeal.Spells[GoubayuHeal.Config["rez_spell"]])
    end

    if (not GoubayuHeal.Config["rez_spell"]) then
        GoubayuHeal.Print(GoubayuHeal.Msg.RezNotFound)
        return
    end

    if UnitAffectingCombat and UnitAffectingCombat("player")
        and GoubayuHeal.Config["rez_spell"] ~= GoubayuHeal.Rebirth then
        GoubayuHeal.Print(GoubayuHeal.Msg.RezInCombat)
        return
    end

    local channel = GoubayuHeal.Config["rez_message_channel"]

    -- 同一目标复活节流：复活成功后，目标在接受复活前仍处于"尸体"状态（如复活术需点确认），
    -- 不加节流会导致每次按键都对同一个人重复施放复活（白耗蓝）。成功后锁定 20 秒。
    -- by 武藤纯子酱 2026.10.21
    local function RezAttemptBlocked(tname)
        local t = tname and GoubayuHeal._rez_block_until and GoubayuHeal._rez_block_until[tname]
        return (t and GetTime() < t) and true or false
    end
    local function RezAttemptDone(tname)
        if not tname then
            return
        end
        GoubayuHeal._rez_block_until = GoubayuHeal._rez_block_until or {}
        GoubayuHeal._rez_block_until[tname] = GetTime() + 20
    end

    if UnitExists("target") and GoubayuHeal.CanRez("target") then
        local target = GoubayuHeal.AKA("target")
        local tname = GoubayuHeal.UnitName("target")
        -- 施法中不重复发起（Heal 在施法中会直接返回 1，不能当作"刚放过"来打标记）
        if (not GoubayuHeal.casting_spell) and (not RezAttemptBlocked(tname)) then
            if GoubayuHeal.Heal(target, GoubayuHeal.Config["rez_spell"],
                GoubayuHeal.Config["rez_rank"]) then
                RezAttemptDone(tname)
            end
        end
        return
    end

    if GoubayuHeal.awaiting_rez then
        local candidates = {}
        local n = 0

        if not GoubayuHeal.casting_spell then
            for player, data in GoubayuHeal.awaiting_rez do
                if (data["is_dead"] and (not data["waiting_time"])
                    and (not GoubayuHeal.GetOtherRezing(player))
                    and (not RezAttemptBlocked(GoubayuHeal.UnitName(player)))) then
                    n = n + 1
                    candidates[n] = { unit = player, priority = data["priority"] or 0 }
                end
            end
        end

        table.sort(candidates, function(a, b) return a.priority > b.priority end)

        for i = 1, n do
            local player = candidates[i].unit
            if GoubayuHeal.Heal(player, GoubayuHeal.Config["rez_spell"],
                GoubayuHeal.Config["rez_rank"]) then
                RezAttemptDone(GoubayuHeal.UnitName(player))
                GoubayuHeal.awaiting_rez[player]["status"] = "start"
                GoubayuHeal.awaiting_rez[player]["cast"] = nil
                return
            end
        end
    end

    -- 兜底盲发守卫：目标存活/离线时施放必报错，仅在确实是可战复目标时才施放
    if UnitExists("target") and GoubayuHeal.CanRez("target") then
        CastSpellByName(GoubayuHeal.Config["rez_spell"])
    end
end

-- ============================================================
-- 修饰键判断
-- ============================================================

function GoubayuHeal.IsHealModifierKeyDown(modifier)
    if (not modifier or not GoubayuHeal.Config[modifier]) then
        return
    end

    if (GoubayuHeal.Config[modifier] == 1) then
        return
    elseif (GoubayuHeal.Config[modifier] == 2) then
        return 1
    elseif (GoubayuHeal.Config[modifier] == 3 and IsAltKeyDown()) then
        return 1
    elseif (GoubayuHeal.Config[modifier] == 4 and IsControlKeyDown()) then
        return 1
    elseif (GoubayuHeal.Config[modifier] == 5 and IsShiftKeyDown()) then
        return 1
    elseif (GoubayuHeal.Config[modifier] == 6 and IsAltKeyDown() and IsControlKeyDown()) then
        return 1
    elseif (GoubayuHeal.Config[modifier] == 7 and IsAltKeyDown() and IsShiftKeyDown()) then
        return 1
    elseif (GoubayuHeal.Config[modifier] == 8 and IsControlKeyDown() and IsShiftKeyDown()) then
        return 1
    elseif (GoubayuHeal.Config[modifier] == 9 and IsAltKeyDown() and IsControlKeyDown()
        and IsShiftKeyDown()) then
        return 1
    end
end

-- ============================================================
-- 全局变量初始化
-- ============================================================

GoubayuHeal.buff_heal_bonus = {
    ["TargetBuffs"] = 0,
    ["MyBuffs"] = 0,
    ["Debuffs"] = 0
}
-- ============================================================
-- 扫描装备治疗加成
-- ============================================================

function GoubayuHeal.UpdateItemHealBonus()
    GoubayuHeal.set_bonus_applied = {}

    for slot = 1, 19 do
        local item = GetInventoryItemLink("player", slot)

        if (item and GoubayuHeal.item_heal_bonus_cache[item] and (slot == 16 or slot == 17)) then
            local a, b, c, d, e, f = GetWeaponEnchantInfo()
            if (slot == 16 and ((a and not GoubayuHeal.main_hand_enchant)
                or (not a and GoubayuHeal.main_hand_enchant))) then
                GoubayuHeal.item_heal_bonus_cache[item] = nil
                GoubayuHeal.main_hand_enchant = a
            end
            if (slot == 17 and ((d and not GoubayuHeal.off_hand_enchant)
                or (not d and GoubayuHeal.off_hand_enchant))) then
                GoubayuHeal.item_heal_bonus_cache[item] = nil
                GoubayuHeal.off_hand_enchant = d
            end
        end

        local slotBonus = 0
        if (item and GoubayuHeal.item_heal_bonus_cache[item]) then
            slotBonus = GoubayuHeal.item_heal_bonus_cache[item]
        else
            GoubayuHeal.ClearTooltip()
            if (GoubayuHeal_Tooltip:SetInventoryItem("player", slot)) then
                for line = 1, GoubayuHeal_Tooltip:NumLines() do
                    local leftFont = getglobal("GoubayuHealTooltipTextLeft" .. line)
                    local itemtext = leftFont and leftFont:GetText() or nil

                    if (itemtext and itemtext ~= ""
                        and not GoubayuHeal.set_bonus_applied[itemtext]
                        and not (GoubayuHeal.set_bonus_inactive_text
                            and string.find(itemtext, GoubayuHeal.set_bonus_inactive_text))) then
                        for index, healtext in GoubayuHeal.item_heal_bonus_text do
                            local start, stop, bonus = string.find(itemtext, healtext)
                            if bonus then
                                slotBonus = slotBonus + bonus
                            end
                        end
                        if (string.find(itemtext, GoubayuHeal.set_bonus_active_text)) then
                            GoubayuHeal.set_bonus_applied[itemtext] = 1
                        end
                    end
                end
                GoubayuHeal.item_heal_bonus_cache[item] = slotBonus
            end
        end
    end
end

-- ============================================================
-- 更新死亡玩家列表
-- ============================================================

function GoubayuHeal.UpdateDead(elapsed)
    if not GoubayuHeal.awaiting_rez then
        GoubayuHeal.awaiting_rez = {}
    end

    local players = GetNumRaidMembers()
    local por = "raid"
    if (players <= 0) or (GoubayuHeal.Config and GoubayuHeal.Config["rez_party_only"] == 1) then
        players = GetNumPartyMembers()
        por = "party"
    end

    for a = 1, players do
        local unit = por .. a
        if UnitIsDead(unit) then
            -- 复用已有条目（status/waiting_time/cast 由 DoRez/事件路径维护，天然保留）：
            -- 原写法每轮"or {} 新表→立即被字面量覆盖"，每具尸体每次产生2个垃圾表
            -- by 武藤纯子酱 2026.9.4
            local entry = GoubayuHeal.awaiting_rez[unit]
            if not entry then
                entry = {}
                GoubayuHeal.awaiting_rez[unit] = entry
            end
            entry["is_dead"] = 1
            entry["priority"] = tonumber((GoubayuHeal.Config and GoubayuHeal.Config["rez_priority"]
                and GoubayuHeal.Config["rez_priority"][select(2, UnitClass(unit))]) or 0.5)
        else
            GoubayuHeal.awaiting_rez[por .. a] = nil
        end
    end

    if GoubayuHeal.awaiting_rez then
        for player, data in GoubayuHeal.awaiting_rez do
            if (GoubayuHeal.awaiting_rez[player]["is_dead"]
                and GoubayuHeal.awaiting_rez[player]["waiting_time"])
                and UnitIsDead(player) then
                if not (GoubayuHeal.awaiting_rez[player]["waiting_time"] <= 0) then
                    GoubayuHeal.awaiting_rez[player]["waiting_time"] =
                        GoubayuHeal.awaiting_rez[player]["waiting_time"] - elapsed
                else
                    GoubayuHeal.awaiting_rez[player]["waiting_time"] = nil
                end
            elseif (GoubayuHeal.awaiting_rez[player]["is_dead"] and not (UnitIsDead(player))) then
                GoubayuHeal.awaiting_rez[player]["is_dead"] = nil
                GoubayuHeal.awaiting_rez[player]["waiting_time"] = nil
                GoubayuHeal.awaiting_rez[player]["priority"] = 0
            end

            if (data["status"] and (data["cast"])) then
                data["cast"] = data["cast"] - elapsed
                if (data["cast"] <= 0) then
                    if (data["status"] == "stop") then
                        -- 施放结束后 20 秒内不再重试同一具尸体（等对方接受；拒绝/超时后 20 秒可重试）
                        -- by 武藤纯子酱 2026.10.21
                        GoubayuHeal.awaiting_rez[player]["waiting_time"] = 20
                        GoubayuHeal.awaiting_rez[player]["status"] = nil
                        GoubayuHeal.awaiting_rez[player]["cast"] = nil
                    else
                        GoubayuHeal.awaiting_rez[player]["waiting_time"] = nil
                        GoubayuHeal.awaiting_rez[player]["status"] = nil
                        GoubayuHeal.awaiting_rez[player]["cast"] = nil
                    end
                end
            end
        end
    end
end

-- ============================================================
-- 检测是否有虚弱灵魂debuff
-- ============================================================

function GoubayuHeal.UnitHasWeakenedSoul(unit)
    if (not unit) then
        return false
    end

    if (GetNampowerVersion and GetUnitField and GetSpellRecField) then
        local auras = GetUnitField(unit, "aura")
        if auras then
            for i = 33, 48 do
                local id = auras[i]
                if (id and id ~= 0) then
                    local name = GoubayuHeal.GetSpellNameFromId and GoubayuHeal.GetSpellNameFromId(id)
                    if (name and name == GoubayuHeal.Weakened_soul) then
                        return true
                    end
                end
            end
        end
    end

    if (GoubayuHeal.UnitGotDebuff and GoubayuHeal.UnitGotDebuff(unit, GoubayuHeal.Weakened_soul)) then
        return true
    end

    for i = 1, 16 do
        local texture = UnitDebuff(unit, i)
        if (not texture) then
            break
        end
        if (string.find(texture, "Spell_Holy_AshesToAshes")
            or string.find(texture, "Spell_Holy_WeakenedSoul")) then
            return true
        end
    end

    return false
end

-- ============================================================
-- 自动补HOT（维持优先）
-- ============================================================

function GoubayuHeal.MaintainHots()
    if (not GoubayuHeal.Config or GoubayuHeal.Config["raid_hots_enabled"] ~= 1
        or not GoubayuHeal.Config["raid_hots"]) then
        return false
    end

    local hotSpells = GoubayuHeal.hot_maintain_spells and GoubayuHeal.hot_maintain_spells[
        GoubayuHeal.my_class] or {}
    if (table.getn(hotSpells) == 0) then
        return false
    end

    if (GoubayuHeal.casting_spell) then
        return false
    end

    if (GoubayuHeal.NampowerCanAct and GoubayuHeal.NampowerCanAct() == false) then
        return false
    end

    local units = {}
    local numRaid = GetNumRaidMembers()
    local por = "raid"

    if (numRaid == 0) then
        numRaid = GetNumPartyMembers()
        por = "party"
        table.insert(units, "player")
    end

    for a = 1, numRaid do
        local unit = por .. a
        if (UnitExists(unit)) then
            table.insert(units, unit)
        end
    end

    for _, unit in ipairs(units) do
        -- 射程/视野过滤：不可施放的单位不计入，避免对无视野/超距目标反复尝试而白白占掉动作
        -- by 武藤纯子酱 2026.9.21
        -- 离线成员同样排除：掉线的人永远补不上，反复尝试只会白占动作 by 武藤纯子酱 2026.10.20
        if (UnitExists(unit) and UnitIsFriend("player", unit)
            and not UnitIsDeadOrGhost(unit)
            and not GoubayuHeal.UnitIsOffline(unit)
            and (not GoubayuHeal.CanCastAtUnit
                or GoubayuHeal.CanCastAtUnit(unit, 40) ~= false)) then
            local name = GoubayuHeal.UnitName(unit)
            local cfg = GoubayuHeal.Config["raid_hots"][name]

            if (cfg) then
                for spell, rankStr in pairs(cfg) do
                    local rank = tonumber(rankStr)
                    if (rank and GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
                        and GoubayuHeal.Spells[spell][rank]) then
                        if (spell == GoubayuHeal.Power_word_shield
                            and GoubayuHeal.UnitHasWeakenedSoul(unit)) then
                            -- 虚弱灵魂期间无法套盾
                        elseif (not GoubayuHeal.UnitHasHOT(unit, spell)) then
                            if (not GoubayuHeal.IsBuffBarFull(unit)) then
                                -- 只有真的放出去才结束本次动作；被拒（P0 已回滚）就继续，
                                -- 不能把"补 HOT 失败"当成已处理而吞掉主治疗 by 武藤纯子酱 2026.10.20
                                if (GoubayuHeal.Heal(unit, spell, rank, 0, 1)) then
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

-- ============================================================
-- HOT维持优先判定
-- ============================================================

function GoubayuHeal.HotMaintenancePriority()
    if (not GoubayuHeal.Config or GoubayuHeal.Config["raid_hots_enabled"] ~= 1) then
        return false
    end

    -- 读条中不判断 HOT 维持：判断出来也放不出去，还白扫全团血量
    -- by 武藤纯子酱 2026.10.21
    if (GoubayuHeal.casting_spell) then
        return false
    end

    -- 0.5 秒节流：HOT 维持是慢节奏维护（恢复 15 秒 / 盾 30 秒 CD），
    -- 100ms 狂按时没必要每次都全团判断 by 武藤纯子酱 2026.10.21
    local now = GetTime()
    if GoubayuHeal._hot_maint_at and (now - GoubayuHeal._hot_maint_at) < 0.5 then
        return false
    end
    GoubayuHeal._hot_maint_at = now

    local threshold = tonumber(GoubayuHeal.Config["raid_hots_priority"]) or 0.8
    local minPct = 101

    local units = {}
    local numRaid = GetNumRaidMembers()
    local por = "raid"

    if (numRaid == 0) then
        numRaid = GetNumPartyMembers()
        por = "party"
        table.insert(units, "player")
    end

    for a = 1, numRaid do
        table.insert(units, por .. a)
    end

    for _, unit in ipairs(units) do
        if (UnitExists(unit) and UnitIsFriend("player", unit)
            and not UnitIsDeadOrGhost(unit)) then
            local h, maxh = GoubayuHeal.GetUnitHealth(unit)
            if (maxh and maxh > 0) then
                local pct = h / maxh
                if (pct < minPct) then
                    minPct = pct
                end
            end
        end
    end

    if (minPct < threshold) then
        return false
    end

    return (GoubayuHeal.MaintainHots() == true)
end

-- ============================================================
-- 删除职业配置及衍生配置
-- ============================================================

function GoubayuHeal.DeleteClassAndRelated(classToDelete)
    if classToDelete then
        GoubayuHeal.Config["classes"][classToDelete] = nil

        if GoubayuHeal.Config["per_scheme"] then
            GoubayuHeal.Config["per_scheme"][classToDelete] = nil
        end

        if not string.find(classToDelete, "_D$") and not string.find(classToDelete, "_S$")
            and not string.find(classToDelete, "_T$") then
            if GoubayuHeal.Config["classes"][classToDelete .. "_D"] then
                GoubayuHeal.Config["classes"][classToDelete .. "_D"] = nil
            end
            if GoubayuHeal.Config["classes"][classToDelete .. "_S"] then
                GoubayuHeal.Config["classes"][classToDelete .. "_S"] = nil
            end
            if GoubayuHeal.Config["classes"][classToDelete .. "_T"] then
                GoubayuHeal.Config["classes"][classToDelete .. "_T"] = nil
            end
        end

        GoubayuHeal.current_class = nil
        GoubayuHeal.ClassDropDownMenuInitialize()
    end
end

-- ============================================================
-- 治疗链选择最佳目标
-- ============================================================

function GoubayuHeal.ChainHeal_SelectBestTarget(spell, rank)
    if GoubayuHeal_has_unitxp == nil then
        GoubayuHeal_has_unitxp = (pcall and pcall(UnitXP, "nop", "nop")) or false
    end
    local hasUnitXP = GoubayuHeal_has_unitxp

    local spellData = GoubayuHeal.Spells and GoubayuHeal.Spells[spell]
        and GoubayuHeal.Spells[spell][rank]

    if (not spellData) and GoubayuHeal.Spells and GoubayuHeal.Spells[spell] then
        local maxR = table.getn(GoubayuHeal.Spells[spell])
        if maxR > 0 then
            rank = maxR
            spellData = GoubayuHeal.Spells[spell][maxR]
        end
    end

    if not spellData then
        return nil
    end

    local baseHeal = ((spellData["HealMin"] or 0) + (spellData["HealMax"] or 0)) / 2
    if baseHeal <= 0 then
        baseHeal = spellData["Heal"] or 0
    end

    local healDecay = { 1.0, 0.5, 0.25 }
    local maxRange = spellData["Range"]
    if not (maxRange and maxRange > 0) then
        maxRange = 30
    end

    local unitsToCheck = {}
    local nUnits = 0

    local players = GetNumRaidMembers()
    local por = "raid"
    if players == 0 then
        players = GetNumPartyMembers()
        por = "party"
        nUnits = nUnits + 1
        unitsToCheck[nUnits] = "player"
        if UnitExists("pet") then
            nUnits = nUnits + 1
            unitsToCheck[nUnits] = "pet"
        end
    end

    for a = 1, players do
        nUnits = nUnits + 1
        unitsToCheck[nUnits] = por .. a
        nUnits = nUnits + 1
        unitsToCheck[nUnits] = por .. "pet" .. a
    end

    if UnitExists("target") then
        nUnits = nUnits + 1
        unitsToCheck[nUnits] = "target"
    end
    if UnitExists("targettarget") then
        nUnits = nUnits + 1
        unitsToCheck[nUnits] = "targettarget"
    end
    if UnitExists("mouseover") then
        nUnits = nUnits + 1
        unitsToCheck[nUnits] = "mouseover"
    end

    local candidates = {}
    local count = 0
    local chainSpellId = spellData and spellData["SpellId"]

    for i = 1, nUnits do
        local unit = unitsToCheck[i]
        local castable = false

        if unit == "player" then
            castable = true
        elseif hasUnitXP then
            castable = (GoubayuHeal.CanCastAtUnit(unit, maxRange, chainSpellId) ~= false)
        else
            castable = (CheckInteractDistance and CheckInteractDistance(unit, 4))
        end

        if UnitExists(unit) and GoubayuHeal.CanHeal(unit) and castable then
            local unitGUID = GoubayuHeal.GetUnitGUID(unit)
            local h, maxh = GoubayuHeal.GetUnitHealth(unit)
            local missing = maxh - h

            if missing > 0 then
                local dup = false
                if unitGUID then
                    for k = 1, count do
                        if candidates[k].guid and candidates[k].guid == unitGUID then
                            dup = true
                            break
                        end
                    end
                end

                if not dup then
                    count = count + 1
                    candidates[count] = { unit = unit, missing = missing, guid = unitGUID }
                end
            end
        end
    end

    if count == 0 then
        return nil
    end

    local dist = {}
    for i = 1, count do
        dist[i] = {}
        local di = dist[i]
        local ci = candidates[i]

        for j = 1, count do
            if i == j then
                di[j] = 0
            elseif hasUnitXP and UnitXP and ci.guid and candidates[j].guid then
                -- guid 取不到（无 Nampower）时不调用，避免 UnitXP 抛错中断治疗链选靶
                local d = UnitXP("distanceBetween", ci.guid, candidates[j].guid)
                di[j] = (d or 9999)
            else
                di[j] = 9999
            end
        end
    end

    local function GoubayuHeal_getBestBounce(i, excludeSet, maxDistance)
        local bestIdx = nil
        local bestMissing = 0
        local di = dist[i]

        for j = 1, count do
            if not excludeSet[j] and di[j] <= maxDistance then
                local missing = candidates[j].missing
                if missing > bestMissing then
                    bestMissing = missing
                    bestIdx = j
                end
            end
        end

        return bestIdx, bestMissing
    end

    local results = {}
    local candidateHasBounce = {}

    for i = 1, count do
        local totalHeal = 0
        local jumped = {}
        jumped[i] = true

        local heal1 = baseHeal * healDecay[1]
        if heal1 > candidates[i].missing then
            heal1 = candidates[i].missing
        end
        totalHeal = totalHeal + heal1

        local j1, m1 = GoubayuHeal_getBestBounce(i, jumped, 7.5)
        candidateHasBounce[i] = (j1 ~= nil)

        if j1 then
            jumped[j1] = true
            local heal2 = baseHeal * healDecay[2]
            if heal2 > m1 then
                heal2 = m1
            end
            totalHeal = totalHeal + heal2

            local j2 = GoubayuHeal_getBestBounce(j1, jumped, 7.5)
            if j2 then
                local heal3 = baseHeal * healDecay[3]
                if heal3 > candidates[j2].missing then
                    heal3 = candidates[j2].missing
                end
                totalHeal = totalHeal + heal3
            end
        end

        results[i] = { unit = candidates[i].unit, totalHeal = totalHeal, idx = i }
    end

    table.sort(results, function(a, b) return a.totalHeal > b.totalHeal end)

    local ordered = {}
    for i = 1, count do
        ordered[i] = results[i].unit
    end

    local hasBounce = false
    if results[1] and results[1].idx and candidateHasBounce[results[1].idx] then
        hasBounce = true
    end

    return ordered, hasBounce
end

-- ============================================================
-- 斜杠命令：删除职业配置
-- ============================================================

SLASH_DELETEGoubayuHealCLASS1 = "/deleteGoubayuHealclass"
SLASH_DELETEGoubayuHealCLASS2 = "/dhc"
SlashCmdList["DELETEGoubayuHealCLASS"] = function(msg)
    if msg and GoubayuHeal.Config["classes"] and GoubayuHeal.Config["classes"][msg] then
        GoubayuHeal.DeleteClassAndRelated(msg)
    end
end

-- ============================================================
-- 刷新团队界面复选框
-- ============================================================

-- 获取团队/小队成员列表（含 name/group/filename）——供方案优先级、HOT维护等使用
function GoubayuHeal.GetRaidPartyUnits()
    local names = {}
    local numRaid = GetNumRaidMembers()

    if numRaid > 0 then
        for raidindex = 1, numRaid do
            local name, rank, group, level, class, filename = GetRaidRosterInfo(raidindex)
            if name and group then
                names[table.getn(names) + 1] = { name = name, group = group, filename = filename }
            end
        end
    else
        if UnitExists("player") then
            local _, playerClass = UnitClass("player")
            names[table.getn(names) + 1] = {
                name = GoubayuHeal.UnitName("player"),
                group = 1,
                filename = playerClass
            }
        end

        for a = 1, GetNumPartyMembers() do
            local unit = "party" .. a
            if UnitExists(unit) and UnitIsFriend("player", unit) then
                local _, memberClass = UnitClass(unit)
                names[table.getn(names) + 1] = {
                    name = GoubayuHeal.UnitName(unit),
                    group = 1,
                    filename = memberClass
                }
            end
        end
    end

    return names
end

function GoubayuHeal.SetRaidChecked()
    if not GoubayuHeal.Config then
        return
    end

    GoubayuHeal.temp_table = (GoubayuHeal.temp_table or {})

    for group = 1, 8 do
        GoubayuHeal.temp_table[group] = 1
    end

    if (not GoubayuHeal.Config["raid_priorities"]) then
        GoubayuHeal.Config["raid_priorities"] = {}
    end

    local names = GoubayuHeal.GetRaidPartyUnits()
    local numRaid = GetNumRaidMembers()

    GoubayuHeal.raid_members = {}
    for _, member in ipairs(names) do
        GoubayuHeal.raid_members[member.name] = true
    end

    local refined = (GoubayuHeal.Config["raid_refined_priority"] == 1)

    -- 清理离队成员
    if (numRaid > 0) then
        -- 两阶段删除（Lua 5.0 pairs 遍历中删键会导致遍历提前终止，离队成员残留）
        if (GoubayuHeal.Config["raid_priorities"]) then
            local removeList = {}
            for storedName in pairs(GoubayuHeal.Config["raid_priorities"]) do
                if (not GoubayuHeal.raid_members[storedName]) then
                    table.insert(removeList, storedName)
                end
            end
            for _, storedName in ipairs(removeList) do
                GoubayuHeal.Config["raid_priorities"][storedName] = nil
            end
        end

        if (GoubayuHeal.Config["raid_roles"]) then
            local removeList = {}
            for storedName in pairs(GoubayuHeal.Config["raid_roles"]) do
                if (not GoubayuHeal.raid_members[storedName]) then
                    if (GoubayuHeal.Tank and GoubayuHeal.Tank["Name"] == storedName) then
                        GoubayuHeal.Tank = { ["Unit"] = nil, ["Name"] = nil }
                    end
                    table.insert(removeList, storedName)
                end
            end
            for _, storedName in ipairs(removeList) do
                GoubayuHeal.Config["raid_roles"][storedName] = nil
            end
        end

        if (GoubayuHeal.Config["raid_hots"]) then
            local removeList = {}
            for storedName in pairs(GoubayuHeal.Config["raid_hots"]) do
                if (not GoubayuHeal.raid_members[storedName]) then
                    table.insert(removeList, storedName)
                end
            end
            for _, storedName in ipairs(removeList) do
                GoubayuHeal.Config["raid_hots"][storedName] = nil
            end
        end
    end

    for _, member in ipairs(names) do
        local name = member.name
        local group = member.group
        local filename = member.filename
        local slot = GoubayuHeal.temp_table[group]
        GoubayuHeal.temp_table[group] = GoubayuHeal.temp_table[group] + 1

        if (GoubayuHeal.Config["raid_priorities"][name] == nil) then
            GoubayuHeal.Config["raid_priorities"][name] = 0.5
        end

        if (GoubayuHeal_GUIRaid:IsVisible()) then
            local nm = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot .. "Name")
            local sl = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                .. "PrioritySlider")
            local rb = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot .. "RoleButton")

            if nm then
                nm:SetText(name)
                if filename and RAID_CLASS_COLORS[filename] then
                    nm:SetTextColor(RAID_CLASS_COLORS[filename].r,
                        RAID_CLASS_COLORS[filename].g,
                        RAID_CLASS_COLORS[filename].b)
                end
            end

                if rb then
                    local role = GoubayuHeal.Config["raid_roles"] and GoubayuHeal.Config["raid_roles"][name]
                    rb:SetText(role or GoubayuHeal.Msg.RoleNone)
                    rb:Enable()
                end

                -- 防护恐惧结界优先级（仅牧师会创建该按钮） by 武藤纯子酱 2026.9.21
                local fwb = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                    .. "FWButton")
                if fwb then
                    local fwMap = GoubayuHeal.Config["priest_fear_ward_priority"]
                    local fwp = fwMap and fwMap[name]
                    fwb:SetText(fwp and tostring(fwp) or GoubayuHeal.Msg.RoleNone)
                    fwb:Enable()
                end

            if sl then
                local pv = GoubayuHeal.Config["raid_priorities"][name]
                pv = pv or 0.5
                sl:SetValue(pv)

                local pct = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                    .. "PriorityPct")
                if pct then
                    pct:SetText(math.floor(pv * 100 + 0.5) .. "%")
                end

                sl:EnableMouse(refined)
                if sl.railTex then
                    if refined then
                        sl.railTex:SetVertexColor(0.25, 0.25, 0.25, 0.8)
                    else
                        sl.railTex:SetVertexColor(0.20, 0.20, 0.20, 0.8)
                    end
                end
                if sl.fillTex then
                    if refined then
                        sl.fillTex:SetVertexColor(0.78, 0.56, 0.25, 1)
                    else
                        sl.fillTex:SetVertexColor(0.28, 0.28, 0.28, 1)
                    end
                end
            end
        end
    end

    if (GoubayuHeal_GUIRaid:IsVisible()) then
        for group = 1, 8 do
            local startSlot = GoubayuHeal.temp_table[group] or 1
            for slot = startSlot, 5 do
                getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot .. "Name"):SetText(EMPTY)
                getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot .. "Name")
                    :SetTextColor(0.3, 0.3, 0.3)
                -- 此前引用的是上方成员循环遗留的局部 sl（作用域外恒 nil），空槽滑块从不重置
                local sl = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                    .. "PrioritySlider")
                if sl then
                    sl:SetValue(0.5)
                    sl:EnableMouse(false)
                    if sl.railTex then
                        sl.railTex:SetVertexColor(0.20, 0.20, 0.20, 0.8)
                    end
                    if sl.fillTex then
                        sl.fillTex:SetVertexColor(0.28, 0.28, 0.28, 1)
                    end
                end

                local pct = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                    .. "PriorityPct")
                if pct then
                    pct:SetText("50%")
                end

                local rb = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                    .. "RoleButton")
                if rb then
                    rb:SetText(GoubayuHeal.Msg.RoleNone)
                    rb:Disable()
                end

                local fwb = getglobal("GoubayuHeal_GUIRaidGroup" .. group .. "Slot" .. slot
                    .. "FWButton")
                if fwb then
                    fwb:SetText(GoubayuHeal.Msg.RoleNone)
                    fwb:Disable()
                end
            end
        end
    end
end

-- ============================================================
-- 设置团队成员角色
-- ============================================================

function GoubayuHeal.SetRaidRole(name, role)
    if (not name or not GoubayuHeal.Config) then
        return
    end

    if (not GoubayuHeal.Config["raid_roles"]) then
        GoubayuHeal.Config["raid_roles"] = {}
    end

    if (role and role ~= GoubayuHeal.Msg.RoleNone) then
        for otherName, otherRole in pairs(GoubayuHeal.Config["raid_roles"]) do
            if (otherName ~= name and otherRole == role) then
                GoubayuHeal.Config["raid_roles"][otherName] = nil
            end
        end
    end

    if (role == GoubayuHeal.Msg.RoleNone) then
        GoubayuHeal.Config["raid_roles"][name] = nil
    else
        GoubayuHeal.Config["raid_roles"][name] = role
    end

    if (role == "MT") then
        local unit = GoubayuHeal.GetUnitID(name)
        GoubayuHeal.Tank = { ["Unit"] = unit, ["Name"] = name }
    elseif (GoubayuHeal.Tank and GoubayuHeal.Tank["Name"] == name) then
        GoubayuHeal.Tank = { ["Unit"] = nil, ["Name"] = nil }
    end

    if (GoubayuHeal.SetRaidChecked) then
        GoubayuHeal.SetRaidChecked()
    end
end

-- ============================================================
-- 防护恐惧结界优先级（牧师专用）
-- ============================================================

-- 设置某成员的结界优先级：1 最高 … 10 最低，nil/0 = 无。
-- 同一优先级只能有一个人：给某人设置后，原先占用该优先级的人自动变"无"
-- by 武藤纯子酱 2026.9.21
function GoubayuHeal.SetFearWardPriority(name, value)
    if (not name or not GoubayuHeal.Config) then
        return
    end

    if (not GoubayuHeal.Config["priest_fear_ward_priority"]) then
        GoubayuHeal.Config["priest_fear_ward_priority"] = {}
    end

    local map = GoubayuHeal.Config["priest_fear_ward_priority"]
    local v = tonumber(value)

    if (not v) or v < 1 then
        map[name] = nil
    else
        for otherName, otherValue in pairs(map) do
            if (otherName ~= name and tonumber(otherValue) == v) then
                map[otherName] = nil
            end
        end
        map[name] = v
    end

    if (GoubayuHeal.SetRaidChecked) then
        GoubayuHeal.SetRaidChecked()
    end
end

-- 维持防护恐惧结界：按优先级（10 最高、1 最低）找出已设定优先级但身上没有结界的成员，
-- 补一个（技能自身 30 秒冷却由客户端判定，CD 中不施放）。仅牧师生效
-- by 武藤纯子酱 2026.9.21
-- 单位是否离线（掉线的玩家）：UnitIsConnected 返回 nil/false 即视为离线。
-- 用于"按名字配置的自动补 buff"（反恐、HOT 维持）等场景：
-- 离线成员永远放不上，若不排除会反复尝试、并把整次治疗动作吞掉。
-- 仅用于玩家单位（raidN/partyN/player）；宠物/图腾不要用本函数判断。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.UnitIsOffline(unit)
    if (not unit or not UnitIsConnected) then
        return false
    end
    return (not UnitIsConnected(unit))
end

-- 是否有已设置的坦克（MT/8T，含 Tank 目标）处于"救急线"以下。
-- 用于：救急期间暂停挂接的团刷技能（团刷会把治疗摊开/延后，坦克等不起）。
-- 结果缓存 0.2 秒：同一次按键内多处判断不重复扫全团。by 武藤纯子酱 2026.10.23
function GoubayuHeal.TankInRescue()
    local now = GetTime()
    if GoubayuHeal._tankRescueAt and (now - GoubayuHeal._tankRescueAt) < 0.2 then
        return GoubayuHeal._tankRescueVal
    end

    local res = false
    local C = GoubayuHeal.Config
    local pct = tonumber(C and C["rescue_hp_threshold"]) or 40
    if C and pct > 0 then
        local roles = C["raid_roles"]
        local tankName = GoubayuHeal.Tank and GoubayuHeal.Tank["Name"]

        local function isTank(n)
            if not n then
                return false
            end
            if tankName and n == tankName then
                return true
            end
            local rd = roles and roles[n]
            return rd == "MT" or rd == "8T"
        end

        local function check(u)
            if not (u and UnitExists(u) and not UnitIsDeadOrGhost(u)) then
                return false
            end
            if GoubayuHeal.UnitIsOffline and GoubayuHeal.UnitIsOffline(u) then
                return false
            end
            if not isTank(GoubayuHeal.UnitName(u)) then
                return false
            end
            local h, mh = GoubayuHeal.GetUnitHealth(u)
            if not (mh and mh > 0) then
                return false
            end
            return (h / mh * 100) < pct
        end

        if check("player") then
            res = true
        else
            local n = GetNumRaidMembers()
            local por = "raid"
            if n == 0 then
                n = GetNumPartyMembers()
                por = "party"
            end
            for i = 1, n do
                if check(por .. i) then
                    res = true
                    break
                end
            end
        end
    end

    GoubayuHeal._tankRescueAt = now
    GoubayuHeal._tankRescueVal = res
    return res
end

-- 反恐（防护恐惧结界）可施放判定：优先 CanCastAtUnit（UnitXP 距离+视野）。
-- 返回 nil（缺 UnitXP/数据）时用 Nampower IsSpellInRange 兜底；仍判定不了 → 视为不可施放。
-- 宁可跳过也不盲放：盲放失败会占掉整次动作，表现为"卡在这个目标上不跳过"。
-- by 武藤纯子酱 2026.10.20
-- 反恐真实 spellId（射程判定用），按法术书槽位缓存；法术书变化时清空
-- by 武藤纯子酱 2026.10.22
function GoubayuHeal.FearWardSpellId(slot)
    if not slot then
        return nil
    end
    local c = GoubayuHeal._fw_spellid_cache
    if not c then
        c = {}
        GoubayuHeal._fw_spellid_cache = c
    end
    local v = c[slot]
    if v ~= nil then
        return v or nil
    end
    local sid
    if GetSpellBookItemInfo then
        local ok, stype, id = pcall(GetSpellBookItemInfo, slot, BOOKTYPE_SPELL)
        if ok and stype == "SPELL" and type(id) == "number" and id > 0 then
            sid = id
        end
    end
    if not sid and GetNampowerVersion and GetSpellIdForName then
        local ok2, id2 = pcall(GetSpellIdForName, GoubayuHeal.Fear_ward)
        if ok2 and id2 and id2 > 0 then
            sid = id2
        end
    end
    c[slot] = sid or false
    return sid
end

function GoubayuHeal.FearWardCastable(unit, slot)
    if (not unit) then
        return false
    end
    -- 离线成员：放不上，直接跳过（否则会反复尝试）
    if GoubayuHeal.UnitIsOffline(unit) then
        return false
    end
    -- 传真实 spellId：Nampower 的 IsSpellInRange 优先（含天赋/装备射程修正）
    local sid = GoubayuHeal.FearWardSpellId and GoubayuHeal.FearWardSpellId(slot) or nil
    if GoubayuHeal.CanCastAtUnit then
        local c = GoubayuHeal.CanCastAtUnit(unit, 30, sid)
        if (c ~= nil) then
            return c and true or false
        end
    end
    -- 无法判断（无 UnitXP 且无 Nampower IsSpellInRange）：放行，交给客户端与 30 秒 CD；
    -- 否则这类环境会永远不施放反恐。by 武藤纯子酱 2026.10.22
    return true
end

function GoubayuHeal.MaintainFearWard()
    if (GoubayuHeal.my_class ~= GoubayuHeal.Priest) then
        return false
    end

    local cfg = GoubayuHeal.Config and GoubayuHeal.Config["priest_fear_ward_priority"]
    if (not cfg) then
        return false
    end

    local list = {}
    for name, prio in pairs(cfg) do
        local p = tonumber(prio)
        if (name and p and p >= 1) then
            table.insert(list, { name = name, prio = p })
        end
    end
    if (table.getn(list) == 0) then
        return false
    end

    -- 0.5 秒节流：反恐是 30 秒 CD 的缓慢维持，100ms 狂按时没必要每次都逐个名字判断
    -- by 武藤纯子酱 2026.10.21
    local _fwNow = GetTime()
    if GoubayuHeal._fw_check_at and (_fwNow - GoubayuHeal._fw_check_at) < 0.5 then
        return false
    end
    GoubayuHeal._fw_check_at = _fwNow

    -- 未学会反恐（法术书里找不到槽位）→ 不处理：继续盲放必然失败，又会把整次动作吞掉
    -- by 武藤纯子酱 2026.10.20
    local slot = GoubayuHeal.GetSpellBookSlot and GoubayuHeal.GetSpellBookSlot(GoubayuHeal.Fear_ward)
    if (not slot) then
        return false
    end

    -- 正在施法（含读条治疗中）：本次不插手，避免打断/白占一次动作
    -- by 武藤纯子酱 2026.10.20
    if (GoubayuHeal.casting_spell) then
        return false
    end

    -- 技能冷却未就绪：直接返回（防护恐惧结界 30 秒 CD，冷却由槽位查询）
    local okS, _, duration = pcall(GetSpellCooldown, slot, BOOKTYPE_SPELL)
    if (okS and duration and duration > 0) then
        return false
    end

    -- 10 最高、1 最低：降序排列，先补高优先级
    table.sort(list, function(a, b) return a.prio > b.prio end)

    -- 预备：反恐 CD 很长（30 秒），要留给最高优先级的人。
    -- 若最高优先级目标"身上没有结界"且当前不可施放（超距/无视野）→ 本次不给自己以外的任何人，
    -- 保留 CD 等他进入范围/视野（最高优先级即列表首项，不一定是 10，取决于实际设置）
    -- by 武藤纯子酱 2026.9.23
    local top = list[1]
    if top then
        local topUnit = GoubayuHeal.GetUnitID(top.name)
        -- 离线/不存在/死亡的最高优先级不占 CD：否则整轮都给他"留着 CD"，谁也补不上
        -- by 武藤纯子酱 2026.10.20
        if (topUnit and UnitExists(topUnit) and not UnitIsDeadOrGhost(topUnit)
            and not GoubayuHeal.UnitIsOffline(topUnit)) then
            local topHasWard
            if (GoubayuHeal.HasBuffByName) then
                topHasWard = GoubayuHeal.HasBuffByName(topUnit, GoubayuHeal.Fear_ward)
            else
                topHasWard = GoubayuHeal.UnitGotBuff(topUnit, GoubayuHeal.Fear_ward)
            end
            if (not topHasWard) and (not GoubayuHeal.FearWardCastable(topUnit, slot)) then
                return false
            end
        end
    end

    for _, e in ipairs(list) do
        local unit = GoubayuHeal.GetUnitID(e.name)
        if (unit and UnitExists(unit) and not UnitIsDeadOrGhost(unit)) then
            -- 距离/视野过滤：够不着/看不见/判定不了的直接跳过，避免反复尝试失败而卡住本次治疗动作。
            -- 统一走 FearWardCastable（CanCastAtUnit 为 nil 时用 IsSpellInRange 兜底，仍未知按不可施放处理）。
            -- by 武藤纯子酱 2026.10.20
            if GoubayuHeal.FearWardCastable(unit, slot) then
                -- 已有结界则跳过：HasBuffByName 走光环字段/原生扫描（不依赖贴图映射表，
                -- UnitGotBuff 对尚未见过的buff会因缺映射而误判为"没有"）
                -- by 武藤纯子酱 2026.9.21
                local hasWard
                if (GoubayuHeal.HasBuffByName) then
                    hasWard = GoubayuHeal.HasBuffByName(unit, GoubayuHeal.Fear_ward)
                else
                    hasWard = GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Fear_ward)
                end

                if (not hasWard) then
                    -- 记录本次施放尝试：被客户端拒绝时由 UI_ERROR_MESSAGE → RollbackLastAttempt 回滚，
                    -- 下次按键可重试；不会把"放失败"当成已处理而连累治疗动作。
                    -- by 武藤纯子酱 2026.10.20
                    GoubayuHeal.error_message = nil
                    GoubayuHeal._lastAttempt = {
                        spell = GoubayuHeal.Fear_ward,
                        name = GoubayuHeal.UnitName(unit) or e.name,
                        time = GetTime(),
                    }
                    if (GetNampowerVersion and GoubayuHeal.GetUnitGUID) then
                        local guid = GoubayuHeal.GetUnitGUID(unit)
                        if (guid) then
                            CastSpellByName(GoubayuHeal.Fear_ward, guid)
                        else
                            CastSpellByName(GoubayuHeal.Fear_ward, unit)
                        end
                    else
                        local prev = UnitName("target")
                        TargetUnit(unit)
                        CastSpellByName(GoubayuHeal.Fear_ward)
                        if (prev and UnitName("target") ~= prev) then
                            TargetLastTarget()
                        end
                    end
                    return true
                end
            end
        end
    end

    return false
end

-- ============================================================
-- HOT维持配置
-- ============================================================

GoubayuHeal.hot_maintain_spells = {
    [GoubayuHeal.Druid] = { GoubayuHeal.Rejuvenation, GoubayuHeal.Regrowth },
    [GoubayuHeal.Priest] = { GoubayuHeal.Renew, GoubayuHeal.Power_word_shield },
}

function GoubayuHeal.SetHotRank(name, spell, rankStr)
    if (not name or not spell or not GoubayuHeal.Config) then
        return
    end

    if (not GoubayuHeal.Config["raid_hots"]) then
        GoubayuHeal.Config["raid_hots"] = {}
    end

    if (not GoubayuHeal.Config["raid_hots"][name]) then
        GoubayuHeal.Config["raid_hots"][name] = {}
    end

    if (rankStr and rankStr ~= "") then
        GoubayuHeal.Config["raid_hots"][name][spell] = rankStr
    else
        GoubayuHeal.Config["raid_hots"][name][spell] = nil
    end

    if (GoubayuHeal.SetHotMaintain) then
        GoubayuHeal.SetHotMaintain()
    end
end

-- ============================================================
-- 刷新HOT标签栏
-- ============================================================

function GoubayuHeal.SetHotMaintain()
    if (not GoubayuHeal.Config) then
        return
    end

    local hotSpells = GoubayuHeal.hot_maintain_spells and GoubayuHeal.hot_maintain_spells[
        GoubayuHeal.my_class] or {}
    local hotCount = table.getn(hotSpells)

    GoubayuHeal.temp_table = (GoubayuHeal.temp_table or {})
    for group = 1, 8 do
        GoubayuHeal.temp_table[group] = 1
    end

    local names = GoubayuHeal.GetRaidPartyUnits()
    local numRaid = GetNumRaidMembers()

    if (GoubayuHeal_GUIHot and GoubayuHeal_GUIHot:IsVisible()) then
        for _, member in ipairs(names) do
            local name = member.name
            local group = member.group
            local filename = member.filename
            local slot = GoubayuHeal.temp_table[group]

            GoubayuHeal.temp_table[group] = GoubayuHeal.temp_table[group] + 1

            local nm = getglobal("GoubayuHeal_GUIHotGroup" .. group .. "Slot" .. slot .. "Name")
            if nm then
                nm:SetText(name)
                if filename and RAID_CLASS_COLORS[filename] then
                    nm:SetTextColor(RAID_CLASS_COLORS[filename].r,
                        RAID_CLASS_COLORS[filename].g,
                        RAID_CLASS_COLORS[filename].b)
                end
            end

            for hi = 1, hotCount do
                local hs = hotSpells[hi]
                local btn = getglobal("GoubayuHeal_GUIHotGroup" .. group .. "Slot" .. slot
                    .. "Hot" .. hi .. "Button")

                if btn then
                    local short = GoubayuHeal.hot_short_name and GoubayuHeal.hot_short_name[hs] or hs
                    local rk = GoubayuHeal.Config["raid_hots"] and GoubayuHeal.Config["raid_hots"][name]
                        and GoubayuHeal.Config["raid_hots"][name][hs]

                    if (not GoubayuHeal.Spells or not GoubayuHeal.Spells[hs]) then
                        btn:SetText(short .. ":" .. GoubayuHeal.Msg.HotUnlearned)
                        btn:Disable()
                    else
                        btn:SetText(short .. ":" .. (rk or GoubayuHeal.Msg.HotUnset))
                        btn:Enable()
                    end
                end
            end
        end

        for group = 1, 8 do
            local startSlot = GoubayuHeal.temp_table[group] or 1
            for slot = startSlot, 5 do
                local nm = getglobal("GoubayuHeal_GUIHotGroup" .. group .. "Slot" .. slot .. "Name")
                if nm then
                    nm:SetText(EMPTY)
                    nm:SetTextColor(0.3, 0.3, 0.3)
                end

                for hi = 1, hotCount do
                    local hs = hotSpells[hi]
                    local btn = getglobal("GoubayuHeal_GUIHotGroup" .. group .. "Slot" .. slot
                        .. "Hot" .. hi .. "Button")

                    if btn then
                        local short = GoubayuHeal.hot_short_name and GoubayuHeal.hot_short_name[hs] or hs
                        btn:SetText(short .. ":" .. GoubayuHeal.Msg.HotUnset)
                        btn:Disable()
                    end
                end
            end
        end
    end
end

-- ============================================================
-- 更新在途治疗
-- ============================================================

function GoubayuHeal.UpdateHealing(elapsed)
    local toRemove = {}

    for who, data in GoubayuHeal.healing do
        for author, moredata in GoubayuHeal.healing[who] do
            GoubayuHeal.healing[who][author]["TimeLeft"] = (moredata["TimeLeft"] or 0) - elapsed

            GoubayuHeal.warned_missing_spells = GoubayuHeal.warned_missing_spells or {}

            if moredata["Spell"] and not GoubayuHeal.Spells[moredata["Spell"]] then
                GoubayuHeal.cast_warnings = GoubayuHeal.cast_warnings or 0
                if GoubayuHeal.cast_warnings < 5
                    and not GoubayuHeal.warned_missing_spells[moredata["Spell"]] then
                    GoubayuHeal.Print(string.format(GoubayuHeal.Msg.MissingTalentCast, moredata["Spell"]))
                    GoubayuHeal.cast_warnings = GoubayuHeal.cast_warnings + 1
                    GoubayuHeal.warned_missing_spells[moredata["Spell"]] = true
                end
            end

            if (GoubayuHeal.healing[who][author]["TimeLeft"] <= -3) then
                if (GoubayuHeal.i_am_healing == who) then
                    GoubayuHeal.i_am_healing = nil
                end
                toRemove[table.getn(toRemove) + 1] = { who, author }
            end
        end
    end

    -- 遍历后统一删除（Lua 5.0 中 pairs 遍历中删除键会导致遍历提前终止）
    for _, rec in ipairs(toRemove) do
        if GoubayuHeal.healing[rec[1]] then
            GoubayuHeal.healing[rec[1]][rec[2]] = nil
        end
    end

    -- HOT 记账按时间递减/过期（自身+他人统一表）
    -- by 武藤纯子酱 2026.10.20
    if GoubayuHeal.trackedHOTs then
        local gone = {}
        for tname, tracks in pairs(GoubayuHeal.trackedHOTs) do
            for sp, t in pairs(tracks) do
                t.timeLeft = (t.timeLeft or 0) - elapsed
                if t.timeLeft <= 0 then
                    gone[table.getn(gone) + 1] = { tname, sp }
                end
            end
        end
        for _, g in ipairs(gone) do
            if GoubayuHeal.trackedHOTs[g[1]] then
                GoubayuHeal.trackedHOTs[g[1]][g[2]] = nil
                if next(GoubayuHeal.trackedHOTs[g[1]]) == nil then
                    GoubayuHeal.trackedHOTs[g[1]] = nil
                end
            end
        end
    end
end

-- ============================================================
-- 全局变量声明
-- ============================================================

GoubayuHeal.last_update = 0
GoubayuHeal.MPPlayerIsMoving = false
GoubayuHeal.prevX, GoubayuHeal.prevY = 0, 0
GoubayuHeal.cast_warnings = 0

GoubayuHeal.Tank = {
    ["Unit"] = nil,
    ["Name"] = nil
}
GoubayuHeal.i_am_healing = nil
GoubayuHeal.awaiting_rez = {}

GoubayuHeal.bonus_divide = 3.5
GoubayuHeal.bonus_instant_divide = 15

-- ============================================================
-- Turtle 172 技能治疗加成系数表（来源：4大奶分析图表，表值优先于 施法时间/3.5 公式）
-- HoT 技能（恢复/回春/愈合持续）在 HoT 加成计算处单独引用本表
-- ============================================================
GoubayuHeal.spell_heal_coeffs = {
    -- 牧师（172 修改：治疗术/强效治疗术/快速治疗/次级治疗术/治疗祷言/绝望祷言/恢复/光明之泉 加成降低15%）
    [GoubayuHeal.Heal] = 0.728571,
    [GoubayuHeal.Greater_heal] = 0.728571,
    [GoubayuHeal.Flash_heal] = 0.364286,
    [GoubayuHeal.Lesser_heal] = 0.607143,
    [GoubayuHeal.Prayer_of_healing] = 0.242857,
    [GoubayuHeal.Renew] = 0.85,
    [GoubayuHeal.Power_word_shield] = 0.35,
    -- 德鲁伊
    [GoubayuHeal.Rejuvenation] = 0.8,
    [GoubayuHeal.Regrowth] = 0.207792,
    [GoubayuHeal.Tranquility] = 0.333,
    -- 萨满
    [GoubayuHeal.Chain_heal] = 0.714285,
    [GoubayuHeal.Lesser_healing_wave] = 0.428571,
    -- 圣骑士（神圣震击瞬发，公式会给 0，表值 0.428571）
    [GoubayuHeal.Holy_shock] = 0.428571,
    [GoubayuHeal.Holy_light] = 0.714286,
    [GoubayuHeal.Flash_of_light] = 0.428571,
}

-- 基础施法时间兜底表（来源：4大奶图表 M列 / 1.12 DBC 基础值；DBC castTime 读取失败时用于 施法时间/3.5 兜底）
-- 治疗之触按等级 2.5 / 3 / 3.5（3级起固定3.5）；其余为标量
GoubayuHeal.spell_base_cast_time = {
    [GoubayuHeal.Healing_touch] = { 2.5, 3, 3.5 },
    [GoubayuHeal.Holy_light] = 2.5,
    [GoubayuHeal.Flash_of_light] = 1.5,
    [GoubayuHeal.Lesser_healing_wave] = 1.5,
    [GoubayuHeal.Healing_wave] = 3,
    [GoubayuHeal.Chain_heal] = 3,
    [GoubayuHeal.Heal] = 3,
    [GoubayuHeal.Greater_heal] = 3,
    [GoubayuHeal.Flash_heal] = 1.5,
    [GoubayuHeal.Lesser_heal] = 2,
    [GoubayuHeal.Prayer_of_healing] = 3,
    [GoubayuHeal.Regrowth] = 2,
}

-- 取有效基础施法时间：优先已解析值，否则用硬编码兜底（解决 Nampower castTime 读取失败导致加成=0）
function GoubayuHeal.GetSpellBaseCastTime(spell, rank, castTime)
    if castTime and castTime > 0 then
        return castTime
    end
    local t = GoubayuHeal.spell_base_cast_time and GoubayuHeal.spell_base_cast_time[spell]
    if type(t) == "table" then
        return t[rank] or t[table.getn(t)]
    end
    return t or 0
end

-- 查询技能治疗加成系数：表值优先；治疗之触按 施法时间/3.5（<3s 有低级惩罚 ×0.8）
function GoubayuHeal.GetSpellHealCoeff(spell, castTime, rank)
    -- 施法时间兜底：DBC读取失败(0/nil)时用硬编码基础施法时间
    castTime = GoubayuHeal.GetSpellBaseCastTime(spell, rank, castTime)
    local c = GoubayuHeal.spell_heal_coeffs[spell]
    if c then
        -- 恢复低级降级惩罚：1级 0.442、2级 0.646（0.85×0.52 / 0.85×0.76）
        if (spell == GoubayuHeal.Renew and rank) then
            if (rank == 1) then
                return 0.442
            elseif (rank == 2) then
                return 0.646
            end
        end
        return c
    end
    -- 治疗波降级惩罚：1级 42.86%、2级 57.14%、3级 71.43%，4级起 85.71%
    if (spell == GoubayuHeal.Healing_wave and rank) then
        if (rank == 1) then
            return 0.4286
        elseif (rank == 2) then
            return 0.5714
        elseif (rank == 3) then
            return 0.7143
        end
        return 0.8571
    end
    if (spell == GoubayuHeal.Healing_touch) then
        local ct = castTime or 0
        if (ct > GoubayuHeal.bonus_divide) then
            ct = GoubayuHeal.bonus_divide
        end
        local r = ct / GoubayuHeal.bonus_divide
        if (ct < 3) then
            r = r * 0.8
        end
        return r
    end
    return nil
end

GoubayuHeal.buff_affect_healing_search = {}
GoubayuHeal.buff_unable_to_heal = {
    [GoubayuHeal.Divine_intervention] = 1,
    [GoubayuHeal.Phase_shift] = 1
}

GoubayuHeal.class_hp_per_level = {
    [GoubayuHeal.Druid] = 60,
    [GoubayuHeal.Hunter] = 65,
    [GoubayuHeal.Mage] = 50,
    [GoubayuHeal.Paladin] = 70,
    [GoubayuHeal.Priest] = 50,
    [GoubayuHeal.Rogue] = 65,
    [GoubayuHeal.Shaman] = 70,
    [GoubayuHeal.Warlock] = 65,
    [GoubayuHeal.Warrior] = 90
}

GoubayuHeal.critical_bonus = 1.5

GoubayuHeal.debuff_affect_healing_search = {}
GoubayuHeal.debuff_unable_to_heal = {
    [GoubayuHeal.Banish] = 1,
    [GoubayuHeal.Deep_slumber] = 1
}

GoubayuHeal.dont_scale_hots = {
    [GoubayuHeal.Rejuvenation] = 1,
    [GoubayuHeal.Renew] = 1
}

GoubayuHeal.dont_scale = {
    [GoubayuHeal.Power_word_shield] = 1,
    [GoubayuHeal.Tranquility] = 1,
    [GoubayuHeal.Resurrection] = 1,
    [GoubayuHeal.Redemption] = 1,
    [GoubayuHeal.Rebirth] = 1,
    [GoubayuHeal.Ancestral_Spirit] = 1,
    [GoubayuHeal.Swiftmend] = 1
}

GoubayuHeal.error_moving = {
    [SPELL_FAILED_MOVING] = 1
}

GoubayuHeal.rez_spells = {
    [GoubayuHeal.Resurrection] = 1,
    [GoubayuHeal.Redemption] = 1,
    [GoubayuHeal.Rebirth] = 1,
    [GoubayuHeal.Ancestral_Spirit] = 1
}

GoubayuHeal.attachment_spells = {
    [GoubayuHeal.Natures_swiftness] = 1,
    [GoubayuHeal.Shaman_Ancestral_swiftness] = 1,
    [GoubayuHeal.Blessing_of_protection] = 1,
    [GoubayuHeal.Power_word_shield] = 1,
    [GoubayuHeal.Holy_shock] = 1,
    [GoubayuHeal.Chain_heal] = 1,
    [GoubayuHeal.Holy_nova] = 1,
    [GoubayuHeal.Prayer_of_healing] = 1,
    [GoubayuHeal.Holy_Strike] = 1 -- 神圣打击：经近战奶专用通道施放（见 HealUsingClass 附件分支）
}

-- 非治疗技能（给自己的buff/防护类）：施放后不阻塞后续治疗技能，且已有buff时不重复施放
-- （圣疗术为治疗技能但无可配置数值，与该组同为"无预估数据"技能）
GoubayuHeal.non_heal_spells = {
    [GoubayuHeal.Natures_swiftness] = 1,
    [GoubayuHeal.Shaman_Ancestral_swiftness] = 1,
    [GoubayuHeal.Divine_protection] = 1,
    [GoubayuHeal.Divine_shield] = 1,
    [GoubayuHeal.Blessing_of_protection] = 1
}

GoubayuHeal.attachment_has_target = {
    [GoubayuHeal.Blessing_of_protection] = 1,
    [GoubayuHeal.Power_word_shield] = 1,
    [GoubayuHeal.Holy_shock] = 1,
    [GoubayuHeal.Chain_heal] = 1,
    [GoubayuHeal.Holy_nova] = 1,
    [GoubayuHeal.Prayer_of_healing] = 1
}

GoubayuHeal.error_unable = {
    SPELL_FAILED_AFFECTING_COMBAT,
    SPELL_FAILED_CASTER_DEAD,
    SPELL_FAILED_CONFUSED,
    SPELL_FAILED_FLEEING,
    SPELL_FAILED_NOT_IN_CONTROL,
    SPELL_FAILED_NOT_MOUNTED,
    SPELL_FAILED_NOT_STANDING,
    SPELL_FAILED_OUT_OF_RANGE,
    SPELL_FAILED_PACIFIED,
    SPELL_FAILED_POSSESSED,
    string.gsub(SPELL_FAILED_REAGENTS, "%%s", ""),
    SPELL_FAILED_SILENCED,
    SPELL_FAILED_SPELL_IN_PROGRESS,
    SPELL_FAILED_STUNNED,
    SPELL_FAILED_TARGETS_DEAD,
    SPELL_FAILED_TARGET_NOT_DEAD
}

-- "全局中止"错误：当前根本无法施法（沉默/昏迷/恐惧/被控/死亡）的状态。
-- 命中后没必要再逐档、逐目标重试 → 直接结束本次治疗动作（无蓝等"仅部分技能受影响"的不在此列）。
-- by 武藤纯子酱 2026.10.19
GoubayuHeal.error_global_abort = {
    [SPELL_FAILED_SILENCED] = 1,
    [SPELL_FAILED_STUNNED] = 1,
    [SPELL_FAILED_CONFUSED] = 1,
    [SPELL_FAILED_FLEEING] = 1,
    [SPELL_FAILED_NOT_IN_CONTROL] = 1,
    [SPELL_FAILED_POSSESSED] = 1,
    [SPELL_FAILED_CASTER_DEAD] = 1
}

function GoubayuHeal.IsGlobalAbortError(msg)
    if not msg then
        return false
    end
    for m, _ in pairs(GoubayuHeal.error_global_abort) do
        if m and string.find(msg, m) then
            return true
        end
    end
    return false
end

GoubayuHeal.heal_spells_search = {}

GoubayuHeal.hot_duration = {
    [GoubayuHeal.Crystal_restore] = 15,
    [GoubayuHeal.First_aid] = 8,
    [GoubayuHeal.Greater_heal] = 15,
    [GoubayuHeal.Lightwell] = 10,
    [GoubayuHeal.Regrowth] = 21,
    [GoubayuHeal.Rejuvenation] = 12,
    [GoubayuHeal.Renew] = 15
}

-- 可独立施放的HOT技能：对同一目标在持续时间内只接一次（避免目标取消HOT后重复上）
GoubayuHeal.hot_cast_cd_spells = {
    [GoubayuHeal.Regrowth] = 1,
    [GoubayuHeal.Rejuvenation] = 1,
    [GoubayuHeal.Renew] = 1
}
-- HOT 施放冷却记录：[spell][unitName] = 上次施放时间（运行时初始化）
GoubayuHeal.hot_cast_cd = GoubayuHeal.hot_cast_cd or {}

GoubayuHeal.my_buff_affect_healing_search = {}

GoubayuHeal.spell_level = {
    [GoubayuHeal.Blessing_of_protection] = { 0, 14, 28 },
    [GoubayuHeal.Power_word_shield] = { -4, 2, 8, 14, 20, 26, 32, 38, 44, 50 },
    [GoubayuHeal.Regrowth] = { 2, 8, 14, 20, 26, 32, 38, 44, 50 },
    [GoubayuHeal.Rejuvenation] = { -6, 0, 6, 12, 18, 24, 30, 36, 42, 48, 50 },
    [GoubayuHeal.Renew] = { -2, 4, 10, 16, 22, 28, 34, 40, 46, 50 }
}

GoubayuHeal.low_level_spell_bonus_penalty = {
    [GoubayuHeal.Heal] = { 0.0375 * 16 + 0.25 },
    [GoubayuHeal.Healing_touch] = { 0.0375 * 1 + 0.25, 0.0375 * 8 + 0.25, 0.0375 * 14 + 0.25 },
    [GoubayuHeal.Healing_wave] = { 0.0375 * 1 + 0.25, 0.0375 * 6 + 0.25, 0.0375 * 12 + 0.25,
        0.0375 * 18 + 0.25 },
    [GoubayuHeal.Holy_light] = { 0.0375 * 1 + 0.25, 0.0375 * 6 + 0.25, 0.0375 * 14 + 0.25 },
    [GoubayuHeal.Lesser_heal] = { 0.0375 * 1 + 0.25, 0.0375 * 4 + 0.25, 0.0375 * 10 + 0.25 },
    [GoubayuHeal.Regrowth] = { 0.0375 * 12 + 0.25, 0.0375 * 18 + 0.25 },
    [GoubayuHeal.Rejuvenation] = { 0.0375 * 4 + 0.25, 0.0375 * 10 + 0.25, 0.0375 * 16 + 0.25 },
    [GoubayuHeal.Renew] = { 0.0375 * 8 + 0.25, 0.0375 * 14 + 0.25 }
}

GoubayuHeal.supported_classes = {
    [GoubayuHeal.Druid] = 1,
    [GoubayuHeal.Paladin] = 1,
    [GoubayuHeal.Priest] = 1,
    [GoubayuHeal.Shaman] = 1
}

GoubayuHeal.blessing_of_light_text = {
    GoubayuHeal.Holy_light,
    GoubayuHeal.Flash_of_light
}

GoubayuHeal.buff_affect_healing_text = {
    [GoubayuHeal.Amplify_magic] = { "DamageUp", "HealUp" },
    [GoubayuHeal.Dampen_magic] = { "DamageDown", "HealDown" }
}

GoubayuHeal.debuff_affect_healing_text = {
    [GoubayuHeal.Gehennas_curse] = { "HealDown", "Duration" },
    [GoubayuHeal.Curse_ot_deadwood] = { "HealDown", "Duration" }
}

GoubayuHeal.my_buff_affect_healing_text = {
    [GoubayuHeal.Unstable_power] = { "DamageUp", "HealUp" },
    [GoubayuHeal.HotA] = { "HealUp", "Duration" },
    [GoubayuHeal.Msg.EyeOfTheDead] = { "HealUp" },
}

GoubayuHeal.heal_spells_text = {
    [GoubayuHeal.Blessing_of_protection] = { "Duration", "Delay" },
    [GoubayuHeal.Chain_heal] = { "HealMin", "HealMax", "EffectLoss", "Targets" },
    [GoubayuHeal.Divine_protection] = { "Duration" },
    [GoubayuHeal.Divine_shield] = { "Duration", "AttackSpeedLoss" },
    [GoubayuHeal.Flash_heal] = { "HealMin", "HealMax" },
    [GoubayuHeal.Flash_of_light] = { "HealMin", "HealMax" },
    [GoubayuHeal.Greater_heal] = { "HealMin", "HealMax" },
    [GoubayuHeal.Heal] = { "HealMin", "HealMax" },
    [GoubayuHeal.Healing_touch] = { "HealMin", "HealMax" },
    [GoubayuHeal.Healing_wave] = { "HealMin", "HealMax" },
    [GoubayuHeal.Holy_light] = { "HealMin", "HealMax" },
    [GoubayuHeal.Holy_nova] = { "DamageMin", "DamageMax", "DamageRange", "HealRange",
        "HealMin", "HealMax" },
    [GoubayuHeal.Holy_Strike] = { "Heal" },
    [GoubayuHeal.Holy_shock] = { "DamageMin", "DamageMax", "HealMin", "HealMax" },
    [GoubayuHeal.Lay_on_hands] = { "text" },
    [GoubayuHeal.Lesser_heal] = { "HealMin", "HealMax" },
    [GoubayuHeal.Lesser_healing_wave] = { "HealMin", "HealMax" },
    [GoubayuHeal.Power_word_shield] = { "Absorb", "Duration", "Delay" },
    [GoubayuHeal.Prayer_of_healing] = { "HealMin", "HealMax" },
    [GoubayuHeal.Regrowth] = { "HealMin", "HealMax", "Duration", "HealingOverTime" },
    [GoubayuHeal.Rejuvenation] = { "Duration", "HealingOverTime" },
    [GoubayuHeal.Renew] = { "Duration", "HealingOverTime" },
    [GoubayuHeal.Swiftmend] = { "RejuvenationTime", "RegrowthTime" },
    [GoubayuHeal.Tranquility] = { "Heal", "ChannelTime" },
    [GoubayuHeal.Resurrection] = { "Heal", "ManaRestored" },
    [GoubayuHeal.Redemption] = { "Heal", "ManaRestored" },
    [GoubayuHeal.Rebirth] = { "Heal", "ManaRestored" },
    [GoubayuHeal.Ancestral_Spirit] = { "Heal", "ManaRestored" },
    [GoubayuHeal.Natures_swiftness] = { "text" },
    [GoubayuHeal.Shaman_Ancestral_swiftness] = { "text" },
    [GoubayuHeal.Desperate_prayer] = { "Heal" }
}

-- 无治疗加成、点击法术库卡片时不弹出预估编辑框的技能
-- （自然迅捷/迅捷治愈/先祖迅捷/保护之手：仅作挂接/瞬发/自保用途，无可配置数值）
GoubayuHeal.no_editor_spells = {
    [GoubayuHeal.Natures_swiftness] = 1,
    [GoubayuHeal.Swiftmend] = 1,
    [GoubayuHeal.Shaman_Ancestral_swiftness] = 1,
    [GoubayuHeal.Blessing_of_protection] = 1,
    [GoubayuHeal.Lay_on_hands] = 1
}

-- ============================================================
-- 默认职业治疗配置
-- ============================================================

GoubayuHeal.fools_classes_set = {
    [GoubayuHeal.Druid] = {
        [35] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Regrowth,
            ["Rank"] = 9,
        },
        [80] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Rejuvenation,
            ["Rank"] = 10,
        },
        [75] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Healing_touch,
            ["Rank"] = 10,
        }
    },
    [GoubayuHeal.Priest] = {
        [30] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Flash_heal,
            ["Rank"] = 7,
        },
        [20] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Power_word_shield,
            ["Rank"] = 10,
        },
        [90] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Renew,
            ["Rank"] = 9,
        },
        [80] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Heal,
            ["Rank"] = 4,
        },
        [50] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Greater_heal,
            ["Rank"] = 5,
        },
    },
    [GoubayuHeal.Paladin] = {
        [90] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Flash_of_light,
            ["Rank"] = 6,
        },
        [70] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Holy_light,
            ["Rank"] = 8,
        }
    },
    [GoubayuHeal.Shaman] = {
        [80] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Lesser_healing_wave,
            ["Rank"] = 6,
        },
        [60] = {
            ["Scale"] = 0,
            ["Spell"] = GoubayuHeal.Healing_wave,
            ["Rank"] = 9,
        }
    }
}

GoubayuHeal.set_bonus_active_text = "Set:"
GoubayuHeal.set_bonus_inactive_text = "%(%d%) Set:"

-- ============================================================
-- 正则表达式构建
-- ============================================================

-- 光明祝福
for index, value in GoubayuHeal.blessing_of_light_text do
    GoubayuHeal.blessing_of_light_search = (GoubayuHeal.blessing_of_light_search or "[^%d]+")
        .. "(%d+%.?%d*)[^%d]+"
end

-- 增益影响治疗
for buff, data in GoubayuHeal.buff_affect_healing_text do
    for index, value in data do
        GoubayuHeal.buff_affect_healing_search[buff] = (GoubayuHeal.buff_affect_healing_search[buff]
            or "[^%d]+") .. "(%d+%.?%d*)[^%d]+"
    end
end

-- 减益影响治疗
for debuff, data in GoubayuHeal.debuff_affect_healing_text do
    for index, value in data do
        GoubayuHeal.debuff_affect_healing_search[debuff] =
            (GoubayuHeal.debuff_affect_healing_search[debuff] or "[^%d]+")
            .. "(%d+%.?%d*)[^%d]+"
    end
end

-- 技能说明文本
for spell, data in GoubayuHeal.heal_spells_text do
    for index, value in data do
        GoubayuHeal.heal_spells_search[spell] = (GoubayuHeal.heal_spells_search[spell]
            or "[^%d]+") .. "(%d+%.?%d*)[^%d]+"
    end
end

GoubayuHeal.heal_spells_search[GoubayuHeal.Rejuvenation] = GoubayuHeal.HotRegex
GoubayuHeal.heal_spells_search[GoubayuHeal.Renew] = GoubayuHeal.HotRegex

-- 锚定模式并入：锚定在前优先匹配，原自动生成模式兜底放最后
for spell, pats in pairs(GoubayuHeal.HealSpellPatterns or {}) do
    local list = {}
    for _, p in ipairs(pats) do
        list[table.getn(list) + 1] = p
    end
    local old = GoubayuHeal.heal_spells_search[spell]
    if old then
        list[table.getn(list) + 1] = old
    end
    GoubayuHeal.heal_spells_search[spell] = list
end

-- HOT文本正则
GoubayuHeal.hot_search = nil
for index, value in GoubayuHeal.hot_text do
    GoubayuHeal.hot_search = (GoubayuHeal.hot_search or "[^%d]+") .. "(%d+%.?%d*)[^%d]+"
end

-- 自身增益影响治疗
for buff, data in GoubayuHeal.my_buff_affect_healing_text do
    for index, value in data do
        GoubayuHeal.my_buff_affect_healing_search[buff] =
            (GoubayuHeal.my_buff_affect_healing_search[buff] or "[^%d]+")
            .. "(%d+%.?%d*)[^%d]+"
    end
end

-- ============================================================
-- 配置初始化
-- ============================================================

function GoubayuHeal.CopyTable(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = GoubayuHeal.CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

GoubayuHeal.per_scheme_keys = {
    "allow_first_rank_ignore_overheal", "predict_enabled", "paladin_holy_strike", "paladin_wisdom_judgment",
    "paladin_melee_heal", "paladin_crusader_strike", "druid_keep_tree_of_life",
    "priest_force_greater_heal", "priest_alternate_spells", "priest_keep_inner_fire",
    "shaman_chain_nobounce_wave", "essence_of_elune_bonus", "priest_desperate_prayer_pct",
    "paladin_divine_shield_pct", "paladin_divine_protection_pct",
    "shaman_totem",
    "hot_heal_threshold", "hot_multiply", "hot_multiply_battle", "max_overheal",
    "min_heal_threshold", "rescue_hp_threshold", "heal_power", "update_player_data_time", "heal_strategy",
    "heal_charmed", "block_faster_healers", "scale_hots", "scale_spells", "safe_cancel",
    "allow_regrowth_overwrite_pct",
    "always_tank_target", "shapeshifted_druids", "scan_cache", "heal_anti_starvation",
    "healer_count_limit", "nampower_queue_timeout",
    "player_priority", "party_priority", "raid_priority", "pet_priority", "MT_priority",
    "buff_affect_priority", "debuff_affect_priority", "class_priority",
    "raid_refined_priority", "raid_priorities", "raid_roles",
    "priest_fear_ward_priority",
    "raid_hots_enabled", "raid_hots", "raid_hots_priority",
    "rez_message", "rez_message_channel", "rez_priority",
    "dispel_enabled", "dispel_queue", "dispel_interrupt", "dispel_hidden", "dispel_priority",
    "dispel_filters", "dispel_pets", "dispel_wyvern_sting", "dispel_mutating_injection",
    "dispel_ignore_abolish", "dispel_shadowform", "dispel_print", "dispel_backdrop",
    "dispel_show_header", "dispel_lock", "dispel_flip", "dispel_scale", "dispel_opacity",
    "dispel_buttons", "dispel_blacklist", "dispel_movement", "dispel_filter_class", "dispel_filter_debuffs",
    "CastTime_Debuff", "MTCastTime_Debuff",
}

function GoubayuHeal.SchemeGetDefaults()
    local d = {}
    d["allow_first_rank_ignore_overheal"] = 1
    d["predict_enabled"] = 0
    d["paladin_holy_strike"] = 0
    d["paladin_wisdom_judgment"] = 0
    d["paladin_melee_heal"] = 0
    d["paladin_divine_shield_pct"] = 0
    d["paladin_divine_protection_pct"] = 0
    d["paladin_crusader_strike"] = 0
    d["druid_keep_tree_of_life"] = 0
    d["priest_force_greater_heal"] = 0
    d["priest_alternate_spells"] = 0
    d["priest_keep_inner_fire"] = 0
    d["shaman_chain_nobounce_wave"] = 0
    d["essence_of_elune_bonus"] = 20
    d["priest_desperate_prayer_pct"] = 0
    d["shaman_totem"] = { enabled = 0, keep_water_shield = 0 }

    d["hot_heal_threshold"] = 0.4
    d["hot_multiply"] = 1.0
    d["hot_multiply_battle"] = 0.5
    d["max_overheal"] = 0.2
    d["min_heal_threshold"] = 0.95
    d["rescue_hp_threshold"] = 40
    d["heal_power"] = 1.0
    d["update_player_data_time"] = 2.5
    d["heal_strategy"] = 1
    d["heal_charmed"] = 1
    d["block_faster_healers"] = 0
    d["scale_hots"] = 0
    d["allow_regrowth_overwrite_pct"] = 100
    d["scale_spells"] = 1
    d["safe_cancel"] = 1
    d["always_tank_target"] = 0
    d["shapeshifted_druids"] = 1
    d["scan_cache"] = 1
    d["heal_anti_starvation"] = 0
    d["healer_count_limit"] = 3
    d["nampower_queue_timeout"] = 1.0

    d["player_priority"] = 1.0
    d["party_priority"] = 0.8
    d["raid_priority"] = 0.5
    d["pet_priority"] = 0.2
    d["MT_priority"] = 0.5
    d["buff_affect_priority"] = {
        [GoubayuHeal.Blessing_of_protection] = 0.2,
        [GoubayuHeal.Power_word_shield] = 0.4,
    }
    d["debuff_affect_priority"] = {
        [GoubayuHeal.Recently_bandaged] = 0.15,
        [GoubayuHeal.Weakened_soul] = 0.15,
        [GoubayuHeal.Mortal_strike] = 0.3,
    }
    d["class_priority"] = {
        ["DRUID"] = 0.5, ["HUNTER"] = 0.4, ["MAGE"] = 0.8, ["PALADIN"] = 0.5,
        ["PRIEST"] = 0.7, ["ROGUE"] = 0.7, ["SHAMAN"] = 0.6, ["WARLOCK"] = 0.6,
        ["WARRIOR"] = 1.0,
    }

    d["raid_refined_priority"] = 0
    d["raid_priorities"] = {}
    d["raid_roles"] = {}
    d["priest_fear_ward_priority"] = {}

    d["raid_hots_enabled"] = 0
    d["raid_hots"] = {}
    d["raid_hots_priority"] = 0.8

    d["rez_message"] = GoubayuHeal.Msg.RezMessageDefault
    d["rez_message_channel"] = "SAY"
    d["rez_priority"] = {
        ["DRUID"] = 0.7, ["HUNTER"] = 0.5, ["MAGE"] = 0.6, ["PALADIN"] = 0.5,
        ["PRIEST"] = 0.8, ["ROGUE"] = 0.5, ["SHAMAN"] = 0.6, ["WARLOCK"] = 0.5,
        ["WARRIOR"] = 1.0,
    }

    d["dispel_enabled"] = 0
    d["dispel_queue"] = 0
    d["dispel_interrupt"] = 0
    d["dispel_hidden"] = 0
    d["dispel_priority"] = 0.5
    d["dispel_filters"] = {}
    for _, dt in ipairs({ "Magic", "Disease", "Poison", "Curse", "Snare" }) do
        d["dispel_filters"][dt] = (GoubayuHeal.Dispel_ClassCanDispelType
            and GoubayuHeal.Dispel_ClassCanDispelType(dt)) and 1 or 0
    end
    d["dispel_pets"] = 0
    d["dispel_wyvern_sting"] = 0
    d["dispel_mutating_injection"] = 0
    d["dispel_ignore_abolish"] = 1
    d["dispel_shadowform"] = 1
    d["dispel_print"] = 1
    d["dispel_backdrop"] = 1
    d["dispel_show_header"] = 1
    d["dispel_lock"] = 0
    d["dispel_flip"] = 0
    d["dispel_scale"] = 0.85
    d["dispel_opacity"] = 1.0
    d["dispel_buttons"] = 5
    d["dispel_blacklist"] = (GoubayuHeal.Dispel_DefaultList and GoubayuHeal.Dispel_DefaultList())
        or {}
    d["dispel_filter_debuffs"] = (GoubayuHeal.Dispel_FilterDebuffDefaults
        and GoubayuHeal.Dispel_FilterDebuffDefaults()) or {}
    d["dispel_filter_class"] = {}
    if GoubayuHeal.Dispel_ClassFilterDefaults then
        for _, cf in ipairs({ "DRUID", "HUNTER", "MAGE", "PALADIN", "PRIEST", "ROGUE",
            "SHAMAN", "WARLOCK", "WARRIOR" }) do
            d["dispel_filter_class"][cf] = GoubayuHeal.Dispel_ClassFilterDefaults(cf)
        end
    end
    d["dispel_movement"] = (GoubayuHeal.Dispel_MovementDefaults
        and GoubayuHeal.Dispel_MovementDefaults()) or {}

    d["CastTime_Debuff"] = 0
    d["MTCastTime_Debuff"] = 0
    return d
end

function GoubayuHeal.SchemeSaveSettings(scheme)
    if not scheme or not GoubayuHeal.Config or not GoubayuHeal.Config["per_scheme"] then
        return
    end
    GoubayuHeal.Config["per_scheme"][scheme] = GoubayuHeal.Config["per_scheme"][scheme] or {}
    local dst = GoubayuHeal.Config["per_scheme"][scheme]

    for _, k in ipairs(GoubayuHeal.per_scheme_keys) do
        if GoubayuHeal.Config[k] ~= nil then
            dst[k] = GoubayuHeal.CopyTable(GoubayuHeal.Config[k])
        else
            dst[k] = nil
        end
    end

    -- 方案副本保存时同步批次版本标记：副本刚由 Config 拷入，与 Config 状态一致；
    -- 此处只记版本、不补条目（避免把用户已删除的批次项又加回去）
    -- by 武藤纯子酱 2026.9.21
    if dst["dispel_blacklist"] then
        dst["_dispel_blacklist_merge_version"] =
            tonumber(GoubayuHeal.Config["dispel_blacklist_merge_version"]) or 0
    end
end

function GoubayuHeal.SchemeLoadSettings(scheme)
    if not GoubayuHeal.Config then
        return
    end
    local src = GoubayuHeal.Config["per_scheme"] and GoubayuHeal.Config["per_scheme"][scheme]

    -- 方案各自保存独立的黑名单副本：加载前先把"新增批次"补进该方案副本，再复制回 Config。
    -- 否则方案里的旧黑名单会整体覆盖掉登录时合并进 Config 的新条目（黑名单有、实际不生效）
    -- by 武藤纯子酱 2026.9.21
    if src and src["dispel_blacklist"] and GoubayuHeal.Dispel_MergeNewDefaults then
        GoubayuHeal.Dispel_MergeNewDefaults(src["dispel_blacklist"], src,
            "_dispel_blacklist_merge_version")
    end

    for _, k in ipairs(GoubayuHeal.per_scheme_keys) do
        if src and src[k] ~= nil then
            GoubayuHeal.Config[k] = GoubayuHeal.CopyTable(src[k])
        end
    end
end

function GoubayuHeal.SchemeInitAll()
    if not GoubayuHeal.Config or not GoubayuHeal.Config["classes"]
        or not GoubayuHeal.Config["per_scheme"] then
        return
    end

    for class, _ in GoubayuHeal.Config["classes"] do
        if not (string.find(class, "_D$") or string.find(class, "_S$")
            or string.find(class, "_T$") or string.find(class, "_Tank$")) then
            if not GoubayuHeal.Config["per_scheme"][class] then
                GoubayuHeal.Config["per_scheme"][class] = {}
                local dst = GoubayuHeal.Config["per_scheme"][class]

                for _, k in ipairs(GoubayuHeal.per_scheme_keys) do
                    if GoubayuHeal.Config[k] ~= nil then
                        dst[k] = GoubayuHeal.CopyTable(GoubayuHeal.Config[k])
                    end
                end

                -- 新方案副本从当前 Config 拷入（状态一致）：只同步批次版本标记，不补条目
                -- by 武藤纯子酱 2026.9.21
                if dst["dispel_blacklist"] then
                    dst["_dispel_blacklist_merge_version"] =
                        tonumber(GoubayuHeal.Config["dispel_blacklist_merge_version"]) or 0
                end
            end
        end
    end
end

function GoubayuHeal.SchemeSaveGlobalSnapshot()
    if not GoubayuHeal.Config or not GoubayuHeal.per_scheme_keys then
        return
    end
    GoubayuHeal.Config["per_scheme_global"] = {}
    local dst = GoubayuHeal.Config["per_scheme_global"]

    for _, k in ipairs(GoubayuHeal.per_scheme_keys) do
        if GoubayuHeal.Config[k] ~= nil then
            dst[k] = GoubayuHeal.CopyTable(GoubayuHeal.Config[k])
        end
    end
end

function GoubayuHeal.SchemeLoadGlobalSnapshot()
    if not GoubayuHeal.Config or not GoubayuHeal.per_scheme_keys then
        return
    end
    local src = GoubayuHeal.Config["per_scheme_global"]
    local has = false
    if src then
        for _ in pairs(src) do
            has = true
            break
        end
    end
    if not has then
        return
    end

    -- 全局快照里的黑名单副本同样先补"新增批次"再复制回 Config
    -- by 武藤纯子酱 2026.9.21
    if src["dispel_blacklist"] and GoubayuHeal.Dispel_MergeNewDefaults then
        GoubayuHeal.Dispel_MergeNewDefaults(src["dispel_blacklist"], src,
            "_dispel_blacklist_merge_version")
    end

    for _, k in ipairs(GoubayuHeal.per_scheme_keys) do
        if src[k] ~= nil then
            GoubayuHeal.Config[k] = GoubayuHeal.CopyTable(src[k])
        end
    end
end

-- ============================================================
-- 设置初始化
-- ============================================================

function GoubayuHeal.SetupSettings()
    -- 与 VARIABLES_LOADED 一致走安全封装：法术书未就绪时不中断后续配置初始化
    GoubayuHeal.SafeUpdateSpells()

    if GoubayuHeal_Data and GoubayuHeal.Config ~= GoubayuHeal_Data then
        GoubayuHeal.Config = GoubayuHeal_Data
    elseif not GoubayuHeal_Data then
        GoubayuHeal.Config = GoubayuHeal.Config or {}
        GoubayuHeal_Data = GoubayuHeal.Config
    end

    if GoubayuHeal.Dispel_SetupDefaults then
        GoubayuHeal.Dispel_SetupDefaults()
    end
    if GoubayuHeal.Dispel_UpdateUsable then
        GoubayuHeal.Dispel_UpdateUsable()
    end

    GoubayuHeal.SavedProfiles = GoubayuHeal.SavedProfiles or {}
    GoubayuHeal.Config["update_player_data_time"] = GoubayuHeal.Config["update_player_data_time"] or 2.5
    GoubayuHeal.Config["per_scheme_enabled"] = (GoubayuHeal.Config["per_scheme_enabled"] or 0)
    GoubayuHeal.Config["per_scheme"] = (GoubayuHeal.Config["per_scheme"] or {})
    GoubayuHeal.Config["per_scheme_global"] = (GoubayuHeal.Config["per_scheme_global"] or {})

    GoubayuHeal.Config["MTCastTime_Debuff"] = (GoubayuHeal.Config["MTCastTime_Debuff"] or 0)
    GoubayuHeal.Config["CastTime_Debuff"] = (GoubayuHeal.Config["CastTime_Debuff"] or 0)
    GoubayuHeal.Config["mm"] = (GoubayuHeal.Config["mm"] or {})
    GoubayuHeal.Config["allow_first_rank_ignore_overheal"] = (GoubayuHeal.Config[
        "allow_first_rank_ignore_overheal"] or 1)
    GoubayuHeal.Config["paladin_holy_strike"] = (GoubayuHeal.Config["paladin_holy_strike"] or 0)
    GoubayuHeal.Config["paladin_wisdom_judgment"] = (GoubayuHeal.Config["paladin_wisdom_judgment"]
        or 0)
    GoubayuHeal.Config["paladin_melee_heal"] = (GoubayuHeal.Config["paladin_melee_heal"] or 0)
    -- 近战奶审判选择（"none"/审判debuff名）与十字军打击开关（0=关，1=开）
    GoubayuHeal.Config["paladin_melee_judgment"] = (GoubayuHeal.Config["paladin_melee_judgment"]
        or GoubayuHeal.Judgment_of_Wisdom)
    GoubayuHeal.Config["paladin_melee_crusader_strike"] =
        (GoubayuHeal.Config["paladin_melee_crusader_strike"] ~= 0 and 1 or 0)
    GoubayuHeal.Config["paladin_melee_keep_wisdom_seal"] =
        (GoubayuHeal.Config["paladin_melee_keep_wisdom_seal"] ~= 0 and 1 or 0)
    GoubayuHeal.Config["paladin_consecration"] = (GoubayuHeal.Config["paladin_consecration"] or 0)
    GoubayuHeal.Config["paladin_holy_strike_interrupt"] =
        (GoubayuHeal.Config["paladin_holy_strike_interrupt"] or 0)
    -- 套装档位：圣骑 T3.5（0=无 1=3件 2=5件）/ 德鲁伊 5T2.5 开关
    GoubayuHeal.Config["paladin_tier35"] = (GoubayuHeal.Config["paladin_tier35"] or 0)
    GoubayuHeal.Config["druid_5t25"] = (GoubayuHeal.Config["druid_5t25"] or 0)
    GoubayuHeal.Config["paladin_divine_shield_pct"] = (GoubayuHeal.Config[
        "paladin_divine_shield_pct"] or 0)
    GoubayuHeal.Config["paladin_divine_protection_pct"] = (GoubayuHeal.Config[
        "paladin_divine_protection_pct"] or 0)
    GoubayuHeal.Config["paladin_crusader_strike"] = (GoubayuHeal.Config["paladin_crusader_strike"]
        or 0)
    GoubayuHeal.Config["shaman_chain_nobounce_wave"] = (GoubayuHeal.Config[
        "shaman_chain_nobounce_wave"] or 0)
    GoubayuHeal.Config["druid_keep_tree_of_life"] = (GoubayuHeal.Config["druid_keep_tree_of_life"]
        or 0)
    GoubayuHeal.Config["priest_force_greater_heal"] = (GoubayuHeal.Config[
        "priest_force_greater_heal"] or 0)
    GoubayuHeal.Config["priest_alternate_spells"] = (GoubayuHeal.Config["priest_alternate_spells"]
        or 0)
    GoubayuHeal.Config["priest_8t2"] = (GoubayuHeal.Config["priest_8t2"] or 0)
    GoubayuHeal.Config["priest_keep_inner_fire"] = (GoubayuHeal.Config["priest_keep_inner_fire"]
        or 0)
    GoubayuHeal.Config["priest_desperate_prayer_pct"] = (GoubayuHeal.Config[
        "priest_desperate_prayer_pct"] or 0)
    GoubayuHeal.Config["heal_anti_starvation"] = (GoubayuHeal.Config["heal_anti_starvation"] or 0)

    if (not GoubayuHeal.Config["buff_affect_priority"]) then
        GoubayuHeal.Config["buff_affect_priority"] = {
            [GoubayuHeal.Blessing_of_protection] = 0.2,
            [GoubayuHeal.Power_word_shield] = 0.4
        }
    end

    if (not GoubayuHeal.Config["class_priority"]) then
        GoubayuHeal.Config["class_priority"] = {
            ["DRUID"] = 0.5,
            ["HUNTER"] = 0.4,
            ["MAGE"] = 0.8,
            ["PALADIN"] = 0.5,
            ["PRIEST"] = 0.7,
            ["ROGUE"] = 0.7,
            ["SHAMAN"] = 0.6,
            ["WARLOCK"] = 0.6,
            ["WARRIOR"] = 1.0
        }
    end

    if (not GoubayuHeal.Config["rez_priority"]) then
        GoubayuHeal.Config["rez_priority"] = {
            ["DRUID"] = 0.7,
            ["HUNTER"] = 0.5,
            ["MAGE"] = 0.6,
            ["PALADIN"] = 0.5,
            ["PRIEST"] = 0.8,
            ["ROGUE"] = 0.5,
            ["SHAMAN"] = 0.6,
            ["WARLOCK"] = 0.5,
            ["WARRIOR"] = 1.0
        }
    end

    if not GoubayuHeal.Config["classes"] then
        GoubayuHeal.Config["classes"] = {}
        if GoubayuHeal.fools_classes_set[GoubayuHeal.my_class] then
            GoubayuHeal.Config["classes"]["standard"] = GoubayuHeal.fools_classes_set[
                GoubayuHeal.my_class]
        end
    end

    -- 清理坦克模式残留的 _Tank 临时配置（运行时生成，不应持久化）
    for class in pairs(GoubayuHeal.Config["classes"]) do
        if type(class) == "string" and string.find(class, "_Tank$") then
            GoubayuHeal.Config["classes"][class] = nil
        end
    end

    if (not GoubayuHeal.Config["debuff_affect_priority"]) then
        GoubayuHeal.Config["debuff_affect_priority"] = {
            [GoubayuHeal.Recently_bandaged] = 0.15,
            [GoubayuHeal.Weakened_soul] = 0.15,
            [GoubayuHeal.Mortal_strike] = 0.3
        }
    end

    -- 已有复活技能但与当前职业不匹配（如换职业或之前误检），清空让其重新按职业选择
    if GoubayuHeal.Config["rez_spell"] then
        local classRez
        if GoubayuHeal.my_class == GoubayuHeal.Shaman then
            classRez = GoubayuHeal.Ancestral_Spirit
        elseif GoubayuHeal.my_class == GoubayuHeal.Druid then
            classRez = GoubayuHeal.Rebirth
        elseif GoubayuHeal.my_class == GoubayuHeal.Priest then
            classRez = GoubayuHeal.Resurrection
        elseif GoubayuHeal.my_class == GoubayuHeal.Paladin then
            classRez = GoubayuHeal.Redemption
        end
        if classRez and GoubayuHeal.Config["rez_spell"] ~= classRez then
            GoubayuHeal.Config["rez_spell"] = nil
            GoubayuHeal.Config["rez_rank"] = nil
        end
    end

    if (not GoubayuHeal.Config["rez_spell"]) then
        -- 按玩家职业优先选择对应的复活技能（避免选错其他职业的复活，如萨满选到德鲁伊的复生）
        local classPriority
        if GoubayuHeal.my_class == GoubayuHeal.Shaman then
            classPriority = GoubayuHeal.Ancestral_Spirit
        elseif GoubayuHeal.my_class == GoubayuHeal.Druid then
            classPriority = GoubayuHeal.Rebirth
        elseif GoubayuHeal.my_class == GoubayuHeal.Priest then
            classPriority = GoubayuHeal.Resurrection
        elseif GoubayuHeal.my_class == GoubayuHeal.Paladin then
            classPriority = GoubayuHeal.Redemption
        end
        if classPriority and GoubayuHeal.Spells[classPriority] then
            GoubayuHeal.Config["rez_spell"] = classPriority
        else
            for spell, data in GoubayuHeal.Spells do
                if GoubayuHeal.rez_spells[spell] then
                    GoubayuHeal.Config["rez_spell"] = spell
                end
            end
        end
    end

    local rezspell = GoubayuHeal.Config["rez_spell"]
    if rezspell and GoubayuHeal.Spells[rezspell] then
        GoubayuHeal.Config["rez_rank"] = (GoubayuHeal.Config["rez_rank"]
            or table.getn(GoubayuHeal.Spells[rezspell]))
    end

    GoubayuHeal.Config["MT_priority"] = (GoubayuHeal.Config["MT_priority"] or 0.5)
    GoubayuHeal.Config["rez_message"] = (GoubayuHeal.Config["rez_message"] or GoubayuHeal.Msg.RezMessageDefault)
    GoubayuHeal.Config["rez_message_channel"] = (GoubayuHeal.Config["rez_message_channel"] or "SAY")

    -- 小地图按钮：治疗职业与非治疗职业统一行为（非治疗职业主要用一键驱散）
    -- 左键：显示/隐藏选项面板；右键：打开/关闭驱散优先级窗口（与 /gbyh dispelprio 相同入口）
    local layout = {
        icon = "Interface\\Icons\\Spell_Holy_FlashHeal",
        drag = "CIRCLE",
        left = function()
            if GoubayuHeal_GUI:IsShown() then
                GoubayuHeal_GUI:Hide()
            else
                GoubayuHeal_GUI:Show()
            end
        end,
        right = function()
            if GoubayuHeal.Dispel_TogglePrioWindow then
                GoubayuHeal.Dispel_TogglePrioWindow()
            elseif GoubayuHeal.Dispel_CreatePrioWindow then
                GoubayuHeal.Dispel_CreatePrioWindow()
            end
        end,
        tooltip = GoubayuHeal.minimap_tip,
        enabled = 0
    }
    MyMinimapButton:Create("GoubayuHeal", GoubayuHeal.Config["mm"], layout)

    GoubayuHeal.Config["hide_mm"] = (GoubayuHeal.Config["hide_mm"] or 0)
    if GoubayuHeal.Config["hide_mm"] == 0 then
        MyMinimapButton:SetEnable("GoubayuHeal", 1)
    end

    GoubayuHeal.Config["always_tank_target"] = (GoubayuHeal.Config["always_tank_target"] or 0)
    GoubayuHeal.Config["rez_party_only"] = (GoubayuHeal.Config["rez_party_only"] or 0)
    GoubayuHeal.Config["heal_max_modifier"] = (GoubayuHeal.Config["heal_max_modifier"] or 5)
    GoubayuHeal.Config["heal_power"] = (GoubayuHeal.Config["heal_power"] or 1.0)
    GoubayuHeal.Config["heal_self_modifier"] = (GoubayuHeal.Config["heal_self_modifier"] or 3)
    GoubayuHeal.Config["heal_charmed"] = (GoubayuHeal.Config["heal_charmed"] or 1)
    GoubayuHeal.Config["heal_strategy"] = (GoubayuHeal.Config["heal_strategy"] or 1)
    GoubayuHeal.Config["spell_data_override"] = (GoubayuHeal.Config["spell_data_override"] or {})
    GoubayuHeal.Config["heal_targettarget_modifier"] = (GoubayuHeal.Config[
        "heal_targettarget_modifier"] or 1)
    GoubayuHeal.Config["hot_heal_threshold"] = (GoubayuHeal.Config["hot_heal_threshold"] or 0.4)
    -- "允许覆盖愈合"复选框已移除，改为"覆盖愈合阈值"滑块（0% = 不覆盖）。
    -- 旧存档迁移：原复选框若为关(=0) 且阈值还是默认 100 → 阈值置 0（保持"不覆盖"）
    -- by 武藤纯子酱 2026.10.19
    if GoubayuHeal.Config["allow_regrowth_overwrite_pct"] == nil then
        GoubayuHeal.Config["allow_regrowth_overwrite_pct"] = 100
    end
    if GoubayuHeal.Config["allow_regrowth_overwrite"] == 0
        and GoubayuHeal.Config["allow_regrowth_overwrite_pct"] == 100 then
        GoubayuHeal.Config["allow_regrowth_overwrite_pct"] = 0
    end
    GoubayuHeal.Config["hot_multiply"] = (GoubayuHeal.Config["hot_multiply"] or 1.0)
    GoubayuHeal.Config["hot_multiply_battle"] = (GoubayuHeal.Config["hot_multiply_battle"] or 0.5)
    GoubayuHeal.Config["max_overheal"] = (GoubayuHeal.Config["max_overheal"] or 0.2)
    GoubayuHeal.Config["min_heal_threshold"] = (GoubayuHeal.Config["min_heal_threshold"] or 0.95)
    -- 救急线（百分比）：目标低于它时忽略 HOT 预估、默认忽略他人直接读条。
    -- 读档也夹取 rescue <= min_heal_threshold。by 武藤纯子酱 2026.10.20
    GoubayuHeal.Config["rescue_hp_threshold"] = (tonumber(GoubayuHeal.Config["rescue_hp_threshold"]) or 40)
    local _minPct = (tonumber(GoubayuHeal.Config["min_heal_threshold"]) or 0.95) * 100
    if GoubayuHeal.Config["rescue_hp_threshold"] > _minPct then
        GoubayuHeal.Config["rescue_hp_threshold"] = _minPct
    end
    GoubayuHeal.Config["party_priority"] = (GoubayuHeal.Config["party_priority"] or 0.8)
    GoubayuHeal.Config["pet_priority"] = (GoubayuHeal.Config["pet_priority"] or 0.2)
    GoubayuHeal.Config["player_priority"] = (GoubayuHeal.Config["player_priority"] or 1.0)
    GoubayuHeal.Config["raid_refined_priority"] = (GoubayuHeal.Config["raid_refined_priority"] or 0)
    GoubayuHeal.Config["raid_priorities"] = (GoubayuHeal.Config["raid_priorities"] or {})
    GoubayuHeal.Config["raid_roles"] = (GoubayuHeal.Config["raid_roles"] or {})
    GoubayuHeal.Config["priest_fear_ward_priority"] =
        (GoubayuHeal.Config["priest_fear_ward_priority"] or {})
    GoubayuHeal.Config["raid_hots"] = (GoubayuHeal.Config["raid_hots"] or {})
    GoubayuHeal.Config["raid_hots_enabled"] = (GoubayuHeal.Config["raid_hots_enabled"] or 0)
    GoubayuHeal.Config["raid_hots_priority"] = (GoubayuHeal.Config["raid_hots_priority"] or 0.8)
    GoubayuHeal.Config["shapeshifted_druids"] = (GoubayuHeal.Config["shapeshifted_druids"] or 1)
    GoubayuHeal.Config["scan_cache"] = (GoubayuHeal.Config["scan_cache"] or 1)
    GoubayuHeal.Config["raid_priority"] = (GoubayuHeal.Config["raid_priority"] or 0.5)
    GoubayuHeal.Config["safe_cancel"] = (GoubayuHeal.Config["safe_cancel"] or 1)
    GoubayuHeal.Config["scale_spells"] = (GoubayuHeal.Config["scale_spells"] or 1)
    GoubayuHeal.Config["scale_hots"] = (GoubayuHeal.Config["scale_hots"] or 0)
    GoubayuHeal.Config["essence_of_elune_bonus"] = (GoubayuHeal.Config["essence_of_elune_bonus"]
        or 20)
    GoubayuHeal.Config["healer_count_limit"] = (GoubayuHeal.Config["healer_count_limit"] or 3)
    GoubayuHeal.Config["block_faster_healers"] = (GoubayuHeal.Config["block_faster_healers"] or 0)
    GoubayuHeal.Config["nampower_queue_timeout"] = (GoubayuHeal.Config["nampower_queue_timeout"]
        or 1.0)
    -- 预读开关（默认关） by 武藤纯子酱 2026.10.13
    GoubayuHeal.Config["predict_enabled"] = (GoubayuHeal.Config["predict_enabled"] or 0)
end

-- ============================================================
-- GUI控件值变更回调
-- ============================================================

function GoubayuHeal.UpdateSettings()
    if (not this) then
        return
    end

    local variable = this.variable
    if (not variable) then
        return
    end

    if (string.find(variable, "GoubayuHeal.Config") and this.GetChecked) then
        local checked = this:GetChecked()
        -- 仅处理"单层"键 Config["key"]；带二级键的（Config["a"]["b"]，如 dispel_filters["Magic"]）
        -- 不能在这里把 a 整个覆盖成 0/1，否则同表的其它键被清空（表现为勾选互相覆盖、重开只剩一个）。
        -- 二级键由下方按 args 逐层写入。 by 武藤纯子酱 2026.10.10
        local configKey = string.match(variable, '^GoubayuHeal%.Config%["([^"]+)"%]$')
        if configKey then
            GoubayuHeal.Config[configKey] = (checked and 1) or 0
        end
    end

    local start, stop, pre = string.find(variable, "^([%w%s:_%-.]+)")
    if (not pre) then
        return
    end

    local value
    if this.GetName then
        local name = this:GetName()
        if (string.find(name, "^GoubayuHeal_GUI.*Slider$") and this.GetValue) then
            value = math.floor(this:GetValue() * 100 + 0.5) / 100

            if (name == "GoubayuHeal_GUIAutocancelTimeSlider") then
                getglobal(name .. "High"):SetText(value * 1000 .. " ms")
            elseif (name == "GoubayuHeal_GUINPQueueTimeoutSlider") then
                getglobal(name .. "High"):SetText(value .. " s")
            elseif (name == "GoubayuHeal_GUIUpdatePlayerDataTimeSlider") then
                value = value / 10
                getglobal(name .. "High"):SetText(value .. " s")
            elseif (name == "GoubayuHeal_GUIHealStrategySlider") then
                getglobal(name .. "High"):SetText(GoubayuHeal.GUI_heal_strategies[value])
            elseif (name == "GoubayuHeal_GUIHealerCountLimitSlider") then
                getglobal(name .. "High"):SetText(value .. GoubayuHeal.Msg.SlUnitsSuffix)
            elseif (string.find(name, "CastTimeDebuff")) then
                getglobal(name .. "High"):SetText(value .. GoubayuHeal.Msg.SlMsSuffix)
            elseif (string.find(name, "GoubayuHeal_GUIHeal.+ModifierSlider")) then
                getglobal(name .. "High"):SetText(GoubayuHeal.GUI_keys[value])
            elseif (string.find(name, "RankSlider")) then
                getglobal(name .. "High"):SetText(value)
            elseif (string.find(name, "Value")) then
                getglobal(name .. "High"):SetText(value)
            elseif (name == "GoubayuHeal_GUIEssenceOfEluneSlider") then
                value = math.floor(this:GetValue() + 0.5)
                getglobal(name .. "High"):SetText(value .. "%")
            else
                getglobal(name .. "High"):SetText(value * 100 .. "%")
            end
        elseif (string.find(name, "^GoubayuHeal_GUI.*CheckButton$") and this.GetChecked) then
            if (this:GetChecked()) then
                value = 1
            else
                value = 0
            end
        else
            return
        end
    else
        return
    end

    local args = {}
    for index in string.gfind(variable, "%[\"?([^%[%]\"]+)\"?%]") do
        if (string.find(index, "^GoubayuHeal%.")) then
            index = GoubayuHeal[string.sub(index, 13)]
        end
        table.insert(args, index)
    end

    local root = nil
    if (pre == "GoubayuHeal.Config") then
        root = GoubayuHeal.Config
    elseif (pre == "GoubayuHeal.SavedProfiles") then
        root = GoubayuHeal.SavedProfiles
    elseif (pre == "GoubayuHeal") then
        root = GoubayuHeal
    end

    local nargs = table.getn(args)
    if root and nargs > 0 then
        local node = root
        local ok = true

        for i = 1, nargs - 1 do
            if type(node[args[i]]) ~= "table" then
                node[args[i]] = {}
            end
            node = node[args[i]]
        end

        if node then
            node[args[nargs]] = value
        end
    end
end

-- ============================================================
-- 保存/加载档案
-- ============================================================

function GoubayuHeal.Save_Profile(profile)
    GoubayuHeal.SavedProfiles[profile] = {}

    for key, value in GoubayuHeal.Config do
        if (type(value) == "table") then
            GoubayuHeal.SavedProfiles[profile][key] = {}
            for key2, value2 in value do
                if (type(value2) == "table") then
                    GoubayuHeal.SavedProfiles[profile][key][key2] = {}
                    for key3, value3 in value2 do
                        if (type(value3) == "table") then
                            -- 超过3层的嵌套表不保存
                        else
                            GoubayuHeal.SavedProfiles[profile][key][key2][key3] = value3
                        end
                    end
                else
                    GoubayuHeal.SavedProfiles[profile][key][key2] = value2
                end
            end
        else
            GoubayuHeal.SavedProfiles[profile][key] = value
        end
    end
end

function GoubayuHeal.Load_Profile(profile)
    local classes = {}
    for class, data in GoubayuHeal.Config["classes"] do
        classes[class] = {}
        for spell, settings in data do
            classes[class][spell] = {}
            for key, value in settings do
                classes[class][spell][key] = value
            end
        end
    end

    for k in pairs(GoubayuHeal.Config) do
        GoubayuHeal.Config[k] = nil
    end

    for k, v in pairs(GoubayuHeal.SavedProfiles[profile]) do
        GoubayuHeal.Config[k] = v
    end

    GoubayuHeal.Config["classes"] = classes

    -- 档案加载会整体重建 Config（含黑名单副本）：补一次"新增批次"
    -- by 武藤纯子酱 2026.9.21
    if GoubayuHeal.Dispel_MergeNewDefaults then
        GoubayuHeal.Dispel_MergeNewDefaults(GoubayuHeal.Config["dispel_blacklist"],
            GoubayuHeal.Config, "dispel_blacklist_merge_version")
    end

    if (GoubayuHeal_GUI:IsVisible()) then
        GoubayuHeal_GUI:Hide()
        GoubayuHeal_GUI:Show()
        if (GoubayuHeal_GUIRaid:IsVisible()) then
            GoubayuHeal.SetRaidChecked()
        end
    end
end

-- ============================================================
-- 更新法术列表（从法术书扫描）
-- ============================================================

function GoubayuHeal.UpdateSpells()
    -- 进入即置位"未完整"：中途任何报错中止也不会漏标，补扫机制据此重试
    GoubayuHeal._spell_parse_incomplete = true
    GoubayuHeal.Spells = {}
    GoubayuHeal._spell_id_set_cache = {}
    GoubayuHeal._spell_parse_missing = 0

    local spellid = 1
    local spellname = GetSpellName(spellid, BOOKTYPE_SPELL)

    while (spellname) do
        local baseName = spellname
        local rank

        if (GoubayuHeal.heal_spells_text[baseName]) then
            if (not GoubayuHeal.Spells[baseName]) then
                GoubayuHeal.Spells[baseName] = {}
                rank = 1
            else
                rank = table.getn(GoubayuHeal.Spells[baseName]) + 1
            end

            GoubayuHeal.Spells[baseName][rank] = (GoubayuHeal.Spells[baseName][rank] or {})
            GoubayuHeal.Spells[baseName][rank]["ID"] = spellid

            local realSpellId
            if GetSpellBookItemInfo then
                local okSBI, stype, sid = pcall(GetSpellBookItemInfo, spellid, BOOKTYPE_SPELL)
                if okSBI and stype == "SPELL" then
                    realSpellId = sid
                end
            end

            if (not realSpellId) and GetNampowerVersion and GetSpellIdForName then
                local ok1, sid1 = pcall(GetSpellIdForName, baseName .. "("
                    .. GoubayuHeal.RANK .. " " .. rank .. ")")
                if ok1 and sid1 and sid1 > 0 then
                    realSpellId = sid1
                else
                    local ok2, sid2 = pcall(GetSpellIdForName, baseName .. "(Rank " .. rank .. ")")
                    if ok2 and sid2 and sid2 > 0 then
                        realSpellId = sid2
                    else
                        -- 无等级技能（如瞬发buff/迅捷）：直接用基础名
                        local ok3, sid3 = pcall(GetSpellIdForName, baseName)
                        if ok3 and sid3 and sid3 > 0 then
                            realSpellId = sid3
                        end
                    end
                end
            end

            if realSpellId then
                GoubayuHeal.Spells[baseName][rank]["SpellId"] = realSpellId
            end

            local mana, range, casttime, text
            if GetNampowerVersion and GetSpellRecField and realSpellId then
                local ok_m, val_m = pcall(GetSpellRecField, realSpellId, "manaCost")
                mana = (ok_m and val_m) or 0

                range = 0
                local ok_ri, val_ri = pcall(GetSpellRecField, realSpellId, "rangeIndex")
                if ok_ri and val_ri and val_ri > 0 and GetSpellRangeData then
                    local ok_rr, _, maxR = pcall(GetSpellRangeData, val_ri)
                    if ok_rr and maxR then
                        range = maxR
                    end
                end

                -- 施法时间放弃Nampower API（该版本castTime字段返回"Unknown field name"且字符串算术会报错），
                -- 统一从tooltip第3行解析（"2.5秒施法时间"/"2秒"/"1秒"均支持）
                local tm, tr, tt, npText = GoubayuHeal.GetSpellData(spellid, BOOKTYPE_SPELL)
                text = npText or ""
                casttime = tt or 0
            else
                mana, range, casttime, text = GoubayuHeal.GetSpellData(spellid, BOOKTYPE_SPELL)
            end

            -- 基础施法时间：表内有该技能的用图表基础值（tooltip显示的是天赋修正后的时间，不能用于加成系数）；
            -- 表内没有的用tooltip解析值（瞬发技能为0属正常）
            local baseCT = GoubayuHeal.spell_base_cast_time
                and GoubayuHeal.spell_base_cast_time[baseName]
            if baseCT then
                if type(baseCT) == "table" then
                    casttime = baseCT[rank] or baseCT[table.getn(baseCT)]
                else
                    casttime = baseCT
                end
            end

            -- 仅当tooltip文本为空（填充失败）时重探测一次；
            -- 瞬发技能casttime=0是正常值，不再因此重复扫描（原逻辑瞬发法术每级都白扫一次）
            if text == "" then
                local _, r2, t2, text2 = GoubayuHeal.GetSpellData(spellid, BOOKTYPE_SPELL)
                if range == 0 then
                    range = r2 or 0
                end
                if casttime == 0 then
                    casttime = t2 or 0
                end
                if text == "" then
                    text = text2 or ""
                end
            end

            -- 解析失败字段兜底（tooltip 未就绪时可能为 nil；nil 进表会导致后续 nil 算术报错）
            -- by 武藤纯子酱 2026.10.22
            mana = tonumber(mana) or 0
            casttime = tonumber(casttime) or 0
            range = tonumber(range) or 0

            GoubayuHeal.Spells[baseName][rank]["Mana"] = mana
            GoubayuHeal.Spells[baseName][rank]["CastTime"] = casttime

            local realcasttime = casttime
            if (GoubayuHeal.my_class == GoubayuHeal.Druid and baseName == GoubayuHeal.Healing_touch) then
                local crank = GoubayuHeal_GetTalentRank(3, 3)
                realcasttime = realcasttime - crank * 0.1
            elseif (GoubayuHeal.my_class == GoubayuHeal.Priest
                and (baseName == GoubayuHeal.PriestHeal or baseName == GoubayuHeal.Greater_heal)) then
                local crank = GoubayuHeal_GetTalentRank(2, 5)
                realcasttime = realcasttime - crank * 0.1
            elseif (GoubayuHeal.my_class == GoubayuHeal.Shaman and baseName == GoubayuHeal.Healing_wave) then
                local crank = GoubayuHeal_GetTalentRank(3, 1)
                realcasttime = realcasttime - crank * 0.1
            end

            GoubayuHeal.Spells[baseName][rank]["RealCastTime"] = realcasttime

            if GetNampowerVersion and GetSpellDuration and realSpellId
                and GoubayuHeal.hot_duration[baseName] then
                local ok_d, durMs = pcall(GetSpellDuration, realSpellId, 1)
                if ok_d and durMs and durMs > 0 then
                    GoubayuHeal.hot_duration[baseName] = durMs / 1000
                end
            end

            local final_range = range

            if range == 0 then
                if baseName == GoubayuHeal.Prayer_of_healing then
                    final_range = 27.5
                elseif baseName == GoubayuHeal.Holy_nova then
                    final_range = 7.8
                end
            end

            if (GoubayuHeal.my_class == GoubayuHeal.Priest) then
                local holy_reach_rank = 0
                local crank = GoubayuHeal_GetTalentRank(2, 6)
                if crank then
                    holy_reach_rank = crank
                end

                if baseName == GoubayuHeal.Prayer_of_healing then
                    final_range = final_range + (holy_reach_rank * 3)
                elseif baseName == GoubayuHeal.Holy_nova then
                    final_range = final_range + holy_reach_rank
                end
            end

            GoubayuHeal.Spells[baseName][rank]["Range"] = final_range
            -- 图标各等级相同，只在1级取一次（原逻辑每等级都调一次GetSpellTexture）
            if rank == 1 then
                local okTx, tex = pcall(GetSpellTexture, spellid, BOOKTYPE_SPELL)
                GoubayuHeal.Spells[baseName]["Texture"] = okTx and tex or nil
            end

            local a = {}
            local start, stop, cooldown
            local pats = GoubayuHeal.heal_spells_search[baseName]
            if type(pats) ~= "table" then
                pats = { pats }
            end
            -- 锚定模式：裸匹配，捕获即值；最后一个为原自动生成模式（保留原 concat→bare 行为兜底）
            local np = table.getn(pats)
            for pi = 1, np do
                if pi < np then
                    start, stop, a[1], a[2], a[3], a[4], a[5], a[6] = string.find(text, pats[pi])
                else
                    start, stop, cooldown, a[1], a[2], a[3], a[4], a[5], a[6] =
                        string.find(text, pats[pi] .. "(%d+%.?%d*)[^%d]+")
                    if (not start) then
                        start, stop, a[1], a[2], a[3], a[4], a[5], a[6] =
                            string.find(text, pats[pi])
                    end
                end
                if start then
                    break
                end
            end

            if (start) then
                local ci = 0
                for index, value in GoubayuHeal.heal_spells_text[baseName] do
                    if value == "HealingOverTime" then
                        local hot_min = (tonumber(a[ci + 1]) or 0) / 1.0
                        local hot_max = (tonumber((string.gsub(a[ci + 2] or "", "[^%d]", ""))) or 0) / 1.0

                        if hot_max > 0 then
                            GoubayuHeal.Spells[baseName][rank][value] = (hot_min + hot_max) / 2.0
                        else
                            GoubayuHeal.Spells[baseName][rank][value] = hot_min
                        end
                        ci = ci + 2
                    else
                        ci = ci + 1
                        GoubayuHeal.Spells[baseName][rank][value] = (tonumber(a[ci]) or 0) / 1.0
                    end
                end
            end

            if (baseName == GoubayuHeal.Prayer_of_healing or baseName == GoubayuHeal.Holy_nova) then
                local default_heal_values = {}

                if baseName == GoubayuHeal.Prayer_of_healing then
                    default_heal_values = {
                        [1] = 300,
                        [2] = 380,
                        [3] = 560,
                        [4] = 800,
                        [5] = 890
                    }
                elseif baseName == GoubayuHeal.Holy_nova then
                    default_heal_values = {
                        [1] = 63,
                        [2] = 101,
                        [3] = 143,
                        [4] = 192,
                        [5] = 276,
                        [6] = 350
                    }
                end

                GoubayuHeal.Spells[baseName][rank]["Heal"] = 0
                GoubayuHeal.Spells[baseName][rank]["HealMin"] = default_heal_values[rank] or 0
                GoubayuHeal.Spells[baseName][rank]["HealMax"] = default_heal_values[rank] or 0
            end

            -- 解析完整性：有数值字段的技能等级一个数值都没解析到 → 法术书未就绪，供登录重试补扫
            -- （含 ManaRestored 的复活类技能除外，其提示文本本就无数值）
            local rd = GoubayuHeal.Spells[baseName][rank]
            local hasNumKey, hasNumVal, isRezSpell = nil, nil, nil
            for vi, vkey in GoubayuHeal.heal_spells_text[baseName] do
                if vkey == "ManaRestored" then
                    isRezSpell = 1
                elseif vkey == "Heal" or vkey == "HealMin" or vkey == "HealMax"
                    or vkey == "HealingOverTime" or vkey == "Absorb"
                    or vkey == "DamageMin" or vkey == "DamageMax" then
                    hasNumKey = 1
                    local vv = rd[vkey]
                    if vv and vv ~= 0 then
                        hasNumVal = 1
                    end
                end
            end
            if hasNumKey and not isRezSpell and not hasNumVal then
                GoubayuHeal._spell_parse_missing = GoubayuHeal._spell_parse_missing + 1
            end
        end

        spellid = spellid + 1
        spellname = GetSpellName(spellid, BOOKTYPE_SPELL)
    end

    GoubayuHeal._spell_parse_incomplete = (GoubayuHeal._spell_parse_missing > 0) or nil
end

-- ============================================================
-- 判断是否为坦克（通过CT_RA/oRA）
-- ============================================================

function GoubayuHeal.IsMT(unit)
    for key, value in pairs(CT_RA_MainTanks or (oRA_MainTank and oRA_MainTank.MainTankTable or nil)
        or {}) do
        if value == GoubayuHeal.UnitName(unit) then
            return true
        end
    end
    return
end

-- ============================================================
-- 获取技能SpellId集合
-- ============================================================

function GoubayuHeal.GetSpellIdSet(spell)
    GoubayuHeal._spell_id_set_cache = GoubayuHeal._spell_id_set_cache or {}
    local cached = GoubayuHeal._spell_id_set_cache[spell]
    if cached then
        return cached
    end

    local set = {}
    if (GoubayuHeal.Spells and GoubayuHeal.Spells[spell]) then
        for rank = 1, table.getn(GoubayuHeal.Spells[spell]) do
            local rankData = GoubayuHeal.Spells[spell][rank]
            if (rankData and rankData["SpellId"]) then
                set[rankData["SpellId"]] = true
            end
        end
    end

    GoubayuHeal._spell_id_set_cache[spell] = set
    return set
end

-- ============================================================
-- 判断增益栏是否已满
-- ============================================================

function GoubayuHeal.IsBuffBarFull(unit)
    if not unit then
        return nil
    end

    if (GetNampowerVersion and GetUnitField) then
        local auras = GetUnitField(unit, "aura")
        if auras then
            local count = 0
            for i = 1, 32 do
                local v = auras[i]
                -- 空槽哨兵在不同版本可能是 0 / "0" / "0x0000000000000000" / nil，
                -- 统一按空处理，避免把空槽误计为已占导致"满栏"误判
                if v and v ~= 0 and v ~= "0" and v ~= "0x0000000000000000" then
                    count = count + 1
                end
            end
            if count < 32 then
                return false
            end
            -- 声称满栏时用原生 UnitBuff 交叉验证（空槽返回 nil，语义权威），防哨兵误判
            for i = 1, 32 do
                if not UnitBuff(unit, i) then
                    return false
                end
            end
            return true
        end
    end

    if not UnitExists(unit) then
        return nil
    end

    for i = 1, 32 do
        if not UnitBuff(unit, i) then
            return false
        end
    end
    return true
end

-- ============================================================
-- 光环 id → 技能名/等级（Nampower 优先，其次 SuperWoW）
-- ============================================================

-- 解析光环 id 对应的技能名与等级：Nampower GetSpellNameAndRankForId → SuperWoW SpellInfo。
-- 等级取等级字符串尾部数字（"Rank 5"/"等级 5" 均可），无数字则视为未知（nil）。
-- 结果按 id 缓存；取不到名字时不缓存（避免插件加载早期把失败结果固化）。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.ResolveAuraNameRank(id)
    -- 空槽哨兵在不同版本可能是 0 / "0" / "0x0000000000000000" / nil，非数字一律按无光环处理
    if type(id) ~= "number" or id == 0 then
        return nil, nil
    end
    local cache = GoubayuHeal._aura_info_cache
    if not cache then
        cache = {}
        GoubayuHeal._aura_info_cache = cache
    end
    local c = cache[id]
    if c then
        return c.name, c.rank
    end
    -- 失败结果只做 30 秒负缓存：登录早期 DBC 可能尚未就绪，永久缓存会让该光环 id
    -- 在整个会话都判不出来（HOT 检测/等级全失效）by 武藤纯子酱 2026.10.22
    local neg = GoubayuHeal._aura_info_neg
    if neg and neg[id] and (GetTime() - neg[id]) < 30 then
        return nil, nil
    end

    local name, rankStr
    if GetSpellNameAndRankForId then
        local ok, nm, rk = pcall(GetSpellNameAndRankForId, id)
        if ok then
            name, rankStr = nm, rk
        end
    end
    if (not name or name == "") and SpellInfo then
        local ok, nm, rk = pcall(SpellInfo, id)
        if ok then
            name, rankStr = nm, rk
        end
    end
    if not name or name == "" then
        -- 30 秒负缓存（见上）：避免每次调用都反复 pcall
        if not GoubayuHeal._aura_info_neg then
            GoubayuHeal._aura_info_neg = {}
        end
        GoubayuHeal._aura_info_neg[id] = GetTime()
        return nil, nil
    end

    local rank
    if type(rankStr) == "number" then
        rank = rankStr
    elseif type(rankStr) == "string" and rankStr ~= "" then
        local _, _, num = string.find(rankStr, "(%d+)%s*$")
        rank = tonumber(num or "")
    end

    cache[id] = { name = name, rank = rank }
    return name, rank
end

-- 光环 id 属于本技能的哪个等级：先查我们会的等级表（精确匹配，最快），
-- 未命中再按名字+等级兜底（能识别我们没学的高等级光环）。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.RankForAuraId(spell, id)
    if not (spell and type(id) == "number" and id ~= 0) then
        return nil
    end
    local rk = GoubayuHeal.RankForSpellId(spell, id)
    if rk then
        return rk
    end
    local nm, rank = GoubayuHeal.ResolveAuraNameRank(id)
    if nm == spell then
        return rank or 1
    end
    return nil
end

-- 光环 id 属本技能的哪个等级（带 (技能,id) 结果缓存，失败记 false）：
-- 高频调用点（UnitHasHOT/GetUnitHOTRank/ScanTargetHOTs）重复解析降为 O(1) 查表。
-- by 武藤纯子酱 2026.10.21
function GoubayuHeal.RankForAuraIdCached(spell, id)
    if not (spell and type(id) == "number" and id ~= 0) then
        return nil
    end
    local c = GoubayuHeal._aura_rank_cache
    if not c then
        c = {}
        GoubayuHeal._aura_rank_cache = c
    end
    local per = c[spell]
    if not per then
        per = {}
        c[spell] = per
    end
    local v = per[id]
    if v ~= nil then
        if v == false then
            return nil
        end
        return v
    end
    -- 只有"名字解析成功且与本技能不符"才写 false 负缓存；解析失败（未知）不缓存，
    -- 避免登录早期一次失败把该光环永久判死。by 武藤纯子酱 2026.10.22
    local rk = GoubayuHeal.RankForSpellId(spell, id)
    if not rk then
        local nm, rank = GoubayuHeal.ResolveAuraNameRank(id)
        if nm == spell then
            rk = rank or 1
        elseif not nm then
            return nil
        end
    end
    per[id] = rk or false
    return rk
end

-- ============================================================
-- 检测单位是否已有同类HOT
-- ============================================================

-- 识别顺序：Nampower（aura id 精确 + 名字/等级）→ SuperWoW（UnitBuff 第3值 id + 名字/等级）
-- → 纯图标（纹理 + 增益名必须同时匹配）。
-- 有 Nampower / SuperWoW 时一律不用图标：野性印记、自然抗性与愈合共用图标，
-- 靠图标判断会把"只有爪子/自然抗性"的目标误判为有愈合，进而让迅捷治愈被服务端拒绝、连刷报错。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.UnitHasHOT(unit, spell)
    if not unit or not spell then
        return false
    end

    -- HOT 只可能是增益（1-32 槽）；命中结果按 (技能,id) 缓存，重复调用只剩查表
    -- by 武藤纯子酱 2026.10.21
    -- 1) Nampower：aura 数组的 spellId 精确/名字判定；有光环数据就不回退图标
    if GetNampowerVersion and GetUnitField then
        local auras = GetUnitField(unit, "aura")
        if auras then
            for i = 1, 32 do
                local id = auras[i]
                if id and id ~= 0 and GoubayuHeal.RankForAuraIdCached(spell, id) then
                    return true
                end
            end
            return false
        end
    end

    -- 2) SuperWoW：UnitBuff 第 3 个返回值是光环 id，同样不用图标
    -- （若该版本 UnitBuff 不返回 id，本档拿不到任何数据，落到下面的图标+名字兜底）
    if SpellInfo then
        local sawSid = false
        for i = 1, 32 do
            local texture, _, sid = UnitBuff(unit, i)
            if not texture then
                break
            end
            if sid and sid ~= 0 then
                sawSid = true
                if GoubayuHeal.RankForAuraIdCached(spell, sid) then
                    return true
                end
            end
        end
        if sawSid then
            return false
        end
    end

    -- 3) 两者都没有：图标纹理 + 增益名必须同时匹配（名字取不到视为没有）
    local isRenew = (spell == GoubayuHeal.Renew)
    local isReju = (spell == GoubayuHeal.Rejuvenation)
    local isRegrowth = (spell == GoubayuHeal.Regrowth)
    local isPWS = (spell == GoubayuHeal.Power_word_shield)
    for i = 1, 32 do
        local texture = UnitBuff(unit, i)
        if not texture then
            break
        end
        local matched = false
        if isRenew then
            matched = (string.find(texture, "Spell_Holy_Renew") ~= nil)
        elseif isReju then
            matched = (string.find(texture, "Spell_Nature_Rejuvenation") ~= nil)
        elseif isRegrowth then
            matched = (string.find(texture, "Spell_Nature_ResistNature") ~= nil)
        elseif isPWS then
            matched = (string.find(texture, "Spell_Holy_PowerWordShield") ~= nil)
        end
        if matched then
            if GoubayuHeal.GetBuffData(unit, i) == spell then
                return true
            end
        end
    end

    return false
end

-- ============================================================
-- 获取目标身上已有HOT的等级
-- ============================================================

-- Nampower / SuperWoW 环境：id 精确命中或名字+等级解析（未知等级也能给出数值，取最大者）。
-- 纯图标环境无法取得等级，返回 nil（调用方按"无等级"处理）。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.GetUnitHOTRank(unit, spell)
    if not unit or not spell or not (GoubayuHeal.Spells and GoubayuHeal.Spells[spell]) then
        return nil
    end

    local best = nil
    if GetNampowerVersion and GetUnitField then
        local auras = GetUnitField(unit, "aura")
        if auras then
            for i = 1, 32 do
                local id = auras[i]
                if id and id ~= 0 then
                    local rk = GoubayuHeal.RankForAuraIdCached(spell, id)
                    if rk and (not best or rk > best) then
                        best = rk
                    end
                end
            end
            return best
        end
    end

    if SpellInfo then
        for i = 1, 32 do
            local texture, _, sid = UnitBuff(unit, i)
            if not texture then
                break
            end
            if sid and sid ~= 0 then
                local rk = GoubayuHeal.RankForAuraIdCached(spell, sid)
                if rk and (not best or rk > best) then
                    best = rk
                end
            end
        end
        return best
    end

    return nil
end

-- ============================================================
-- 综合施法可行性检查
-- ============================================================

function GoubayuHeal.CanCastAtUnit(unit, maxRange, spellId)
    if not UnitExists(unit) then
        return nil
    end

    if (unit == "player") or (UnitIsUnit and UnitIsUnit(unit, "player")) then
        return true
    end

    -- Nampower：IsSpellInRange 按真实技能 ID 判定（含天赋/装备射程修正）。
    -- 0=超距 → 直接不可施放；1=在范围内 → 记下 true（无 UnitXP 时据此兜底）；其余视为未知。
    -- by 武藤纯子酱 2026.10.20
    local npInRange = nil
    if spellId and GetNampowerVersion and IsSpellInRange then
        local ok, inRange = pcall(IsSpellInRange, spellId, unit)
        if ok then
            if inRange == 0 then
                return false
            end
            if inRange == 1 then
                npInRange = true
            end
        end
    end

    if GoubayuHeal_has_unitxp == nil then
        GoubayuHeal_has_unitxp = pcall(UnitXP, "nop", "nop")
    end

    -- 无 UnitXP：若 Nampower 的 IsSpellInRange 已明确"在范围内"，就按可施放处理
    -- （此时无法判视野，交给客户端；被拒由 Heal() 的 P0 回滚兜底）
    -- by 武藤纯子酱 2026.10.20
    if not GoubayuHeal_has_unitxp then
        return npInRange
    end

    local inSight = UnitXP("inSight", unit, "player")
    if (inSight ~= nil and not inSight) then
        return false
    end

    local distance = UnitXP("distanceBetween", "player", unit)
    if (distance ~= nil and maxRange and distance > maxRange) then
        return false
    end

    return true
end

-- ============================================================
-- 执行治疗
-- ============================================================

-- ============================================================
-- 施放尝试辅助：副作用回滚 + "只瞬发"标记超时
-- by 武藤纯子酱 2026.10.19
-- ============================================================

-- 置"只瞬发"标记并记录时间（超时后自动失效，避免卡在"只尝试瞬发"）
function GoubayuHeal.SetOnlyInstant()
    GoubayuHeal.only_instant_spells = 1
    GoubayuHeal.only_instant_spells_time = GetTime()
end

-- "只瞬发"标记是否仍有效（超过 1.5s 自动清除）
function GoubayuHeal.OnlyInstantActive()
    if not GoubayuHeal.only_instant_spells then
        return false
    end
    if GoubayuHeal.only_instant_spells_time
        and (GetTime() - GoubayuHeal.only_instant_spells_time) > 1.5 then
        GoubayuHeal.only_instant_spells = nil
        GoubayuHeal.only_instant_spells_time = nil
        return false
    end
    return true
end

-- 撤销"本次未真正施放"的副作用：HOT 内置冷却 + 本次写入的在途治疗记录（+ i_am_healing）。
-- 仅当在途记录确实是本次技能（Spell 匹配）时才删，避免误删旧记录。
function GoubayuHeal.RollbackCastAttempt(spell, name)
    if not name then
        return
    end
    if spell and GoubayuHeal.hot_cast_cd and GoubayuHeal.hot_cast_cd[spell] then
        GoubayuHeal.hot_cast_cd[spell][name] = nil
    end
    local t = GoubayuHeal.healing and GoubayuHeal.healing[name]
    local rec = t and t[GoubayuHeal.my_name]
    if rec and (not spell or rec["Spell"] == spell) then
        t[GoubayuHeal.my_name] = nil
        if next(t) == nil then
            GoubayuHeal.healing[name] = nil
        end
        if GoubayuHeal.i_am_healing == name then
            GoubayuHeal.i_am_healing = nil
        end
    end
    -- 本次施放失败：删掉刚写入的我方 HOT 记账
    if spell then
        local tr = GoubayuHeal.trackedHOTs and GoubayuHeal.trackedHOTs[name]
            and GoubayuHeal.trackedHOTs[name][spell]
        if tr and tr.isMine then
            GoubayuHeal.ClearTrackedHOT(name, spell)
        end
    end
end

-- 若"本次施放尝试"在极短时间内被拒（同步路径读不到错误时的事件兜底），回滚其副作用。
-- 覆盖瞬发技能（不触发 SPELLCAST_FAILED）被拒的场景；幂等（已回滚则 _lastAttempt 为空）。
function GoubayuHeal.RollbackLastAttempt(spellName)
    local a = GoubayuHeal._lastAttempt
    if not (a and a.time and (GetTime() - a.time) <= 0.5) then
        return
    end
    if spellName and a.spell and spellName ~= a.spell then
        return
    end
    GoubayuHeal._lastAttempt = nil
    GoubayuHeal.RollbackCastAttempt(a.spell, a.name)
    if GoubayuHeal.last_cast_spell == a.spell then
        GoubayuHeal.last_cast_spell = nil
    end
end

-- 该错误串是否属于"施放被拒"（移动失败 / error_unable / 目标不满足）。
-- 用于 UI_ERROR_MESSAGE 侧的白名单判定，避免把无关 UI 消息误当施放失败。
function GoubayuHeal.IsRejectionError(msg)
    if not msg then
        return false
    end
    if GoubayuHeal.error_moving[msg] then
        return true
    end
    for _, m in GoubayuHeal.error_unable do
        if string.find(msg, m) then
            return true
        end
    end
    if SPELL_FAILED_TARGET_AURASTATE and string.find(msg, SPELL_FAILED_TARGET_AURASTATE) then
        return true
    end
    return false
end

-- ============================================================
-- HOT 记账与预估（统一表：目标→技能，含他人 HOT）
-- 同一 HOT 在一个目标上只存在一条（后上覆盖先上；低级盖不过高级会被客户端拒）。
-- trackedHOTs[目标名][技能] = { total, rank, ticks, timeLeft, isMine }
-- by 武藤纯子酱 2026.10.20
-- ============================================================

-- HOT 每跳间隔（秒）：回春 3、愈合 2、恢复 3、8T2 强效附带恢复 3
GoubayuHeal.hot_tick_interval = {
    [GoubayuHeal.Rejuvenation] = 3,
    [GoubayuHeal.Regrowth] = 2,
    [GoubayuHeal.Renew] = 3,
    [GoubayuHeal.Greater_heal] = 3
}

-- 跳数 = 持续时间 / 每跳间隔（四舍五入，至少 1）
function GoubayuHeal.HotTicks(spell)
    local dur = GoubayuHeal.hot_duration and GoubayuHeal.hot_duration[spell]
    if not dur then
        return 1
    end
    local intv = (GoubayuHeal.hot_tick_interval and GoubayuHeal.hot_tick_interval[spell]) or 3
    if intv <= 0 then
        intv = 3
    end
    local t = math.floor(dur / intv + 0.5)
    if t < 1 then
        t = 1
    end
    return t
end

-- spellId → 本技能等级（他人 HOT 落地时识别等级）
function GoubayuHeal.RankForSpellId(spell, spellId)
    if not (spell and spellId and GoubayuHeal.Spells and GoubayuHeal.Spells[spell]) then
        return nil
    end
    for r = 1, table.getn(GoubayuHeal.Spells[spell]) do
        local d = GoubayuHeal.Spells[spell][r]
        if d and d["SpellId"] == spellId then
            return r
        end
    end
    return nil
end

-- 写入/替换一条 HOT 记账（同目标同技能覆盖即替换）
-- 实扫目标光环里的回春/愈合，返回 { [回春]=等级, [愈合]=等级 }（无则不含该键）。
-- 识别顺序与 UnitHasHOT 一致：Nampower → SuperWoW → 纯图标（纹理+名字，等级记 1）；
-- Nampower 下一次取 spellId 数组，开销远低于 UnitBuff×32。by 武藤纯子酱 2026.10.20
function GoubayuHeal.ScanTargetHOTs(u)
    local out = {}
    local rjName = GoubayuHeal.Rejuvenation
    local rgName = GoubayuHeal.Regrowth

    local function add(id)
        if not (id and id ~= 0) then
            return
        end
        -- 命中结果走 (技能,id) 缓存，重复扫描不再做名字解析
        -- by 武藤纯子酱 2026.10.21
        local rj = GoubayuHeal.RankForAuraIdCached(rjName, id)
        if rj then
            if not out[rjName] or rj > out[rjName] then
                out[rjName] = rj
            end
            return
        end
        local rg = GoubayuHeal.RankForAuraIdCached(rgName, id)
        if rg and (not out[rgName] or rg > out[rgName]) then
            out[rgName] = rg
        end
    end

    if GetNampowerVersion and GetUnitField then
        local auras = GetUnitField(u, "aura")
        if auras then
            -- HOT 只可能是增益（1-32 槽）
            for i = 1, 32 do
                add(auras[i])
            end
            return out
        end
    end

    if SpellInfo then
        local sawSid = false
        for i = 1, 32 do
            local tex, _, sid = UnitBuff(u, i)
            if not tex then
                break
            end
            if sid and sid ~= 0 then
                sawSid = true
                add(sid)
            end
        end
        if sawSid then
            return out
        end
    end

    -- 纯图标环境：纹理 + 增益名双条件（愈合图标与"自然抗性"共用，必须靠名字区分），等级未知记 1
    for i = 1, 32 do
        local tex = UnitBuff(u, i)
        if not tex then
            break
        end
        local cand = nil
        if string.find(tex, "Spell_Nature_Rejuvenation") then
            cand = rjName
        elseif string.find(tex, "Spell_Nature_ResistNature") then
            cand = rgName
        end
        if cand and GoubayuHeal.GetBuffData(u, i) == cand then
            out[cand] = out[cand] or 1
        end
    end
    return out
end

-- 最终兜底：对"本档百分比以下 + 距离/视野可达"的目标实扫 HOT 并刷新 trackedHOTs，
-- 再据此选 HOT 等级最高的目标（主扫描因缓存/判错漏掉时用）。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.SwiftmendRescanUnit(maxPercent)
    -- 节流：结果缓存 0.5s（键含 maxPercent）。100ms 鼠标宏狂点时不会每次都全团实扫。
    -- by 武藤纯子酱 2026.10.20
    local now = GetTime()
    local cacheKey = tostring(maxPercent)
    local rc = GoubayuHeal._swiftRescanCache
    if rc and rc.key == cacheKey and (now - rc.time) <= 0.5 then
        return rc.unit
    end
    local n = GetNumRaidMembers()
    local por = "raid"
    if n == 0 then
        n = GetNumPartyMembers()
        por = "party"
    end
    local units = { "player" }
    if UnitExists("pet") then
        units[table.getn(units) + 1] = "pet"
    end
    for a = 1, n do
        units[table.getn(units) + 1] = por .. a
        if UnitExists(por .. "pet" .. a) then
            units[table.getn(units) + 1] = por .. "pet" .. a
        end
    end
    local best, bestRank, bestMiss = nil, -1, -1
    for _, u in ipairs(units) do
        if UnitExists(u) and (not GoubayuHeal.CanHeal or GoubayuHeal.CanHeal(u))
            and not (GoubayuHeal.CanCastAtUnit and GoubayuHeal.CanCastAtUnit(u, 40) == false) then
            local h, mh = GoubayuHeal.GetUnitHealth(u)
            if mh and mh > 0 and (not maxPercent or (h / mh * 100) < maxPercent) then
                local uname = GoubayuHeal.UnitName(u)
                if uname then
                    local hots = GoubayuHeal.ScanTargetHOTs(u)
                    local rk = 0
                    local sps = { GoubayuHeal.Rejuvenation, GoubayuHeal.Regrowth }
                    for _, sp in ipairs(sps) do
                        local r = hots[sp]
                        if r then
                            if r > rk then
                                rk = r
                            end
                            local total = (GoubayuHeal.Spells[sp] and GoubayuHeal.Spells[sp][r]
                                and GoubayuHeal.Spells[sp][r]["HealingOverTime"]) or 0
                            if total > 0 then
                                local prev = GoubayuHeal.trackedHOTs and GoubayuHeal.trackedHOTs[uname]
                                    and GoubayuHeal.trackedHOTs[uname][sp]
                                GoubayuHeal.SetTrackedHOT(uname, sp, total, r,
                                    (prev and prev.isMine) and true or false)
                            end
                        else
                            GoubayuHeal.ClearTrackedHOT(uname, sp)
                        end
                    end
                    local miss = mh - h
                    if rk > 0 and (rk > bestRank or (rk == bestRank and miss > bestMiss)) then
                        best, bestRank, bestMiss = u, rk, miss
                    end
                end
            end
        end
    end
    GoubayuHeal._swiftRescanCache = { key = cacheKey, unit = best, time = now }
    return best
end

function GoubayuHeal.SetTrackedHOT(name, spell, total, rank, isMine)
    if not (name and spell and total and total > 0) then
        return
    end
    GoubayuHeal.trackedHOTs = GoubayuHeal.trackedHOTs or {}
    GoubayuHeal.trackedHOTs[name] = GoubayuHeal.trackedHOTs[name] or {}
    GoubayuHeal.trackedHOTs[name][spell] = {
        total = total,
        rank = rank,
        ticks = GoubayuHeal.HotTicks(spell),
        timeLeft = (GoubayuHeal.hot_duration and GoubayuHeal.hot_duration[spell]) or 12,
        isMine = (isMine == true)
    }
end

-- 删除一条 HOT 记账
function GoubayuHeal.ClearTrackedHOT(name, spell)
    if not (name and spell and GoubayuHeal.trackedHOTs and GoubayuHeal.trackedHOTs[name]) then
        return
    end
    GoubayuHeal.trackedHOTs[name][spell] = nil
    if next(GoubayuHeal.trackedHOTs[name]) == nil then
        GoubayuHeal.trackedHOTs[name] = nil
    end
end

-- HOT 预估：救急线以下=0；否则 max(总量×(1-hp), 总量×min(2,跳数,剩余跳数)/跳数)，
-- 再乘 HOT 放大（战斗用 hot_multiply_battle）。调用方再把总和夹到真实缺口。
function GoubayuHeal.HOT_est(total, hp, ticks, remainingTicks)
    if not total or total <= 0 then
        return 0
    end
    local rescue = tonumber(GoubayuHeal.Config and GoubayuHeal.Config["rescue_hp_threshold"]) or 40
    if hp * 100 < rescue then
        return 0
    end
    if not ticks or ticks < 1 then
        ticks = 1
    end
    local n2 = 2
    if remainingTicks and remainingTicks < n2 then
        n2 = remainingTicks
    end
    if ticks < n2 then
        n2 = ticks
    end
    if n2 < 0 then
        n2 = 0
    end
    local a = total * (1 - hp)
    local b = total * n2 / ticks
    local e = (a > b) and a or b
    local mult = 1
    if GoubayuHeal.Config then
        if GoubayuHeal.player_in_combat then
            mult = tonumber(GoubayuHeal.Config["hot_multiply_battle"]) or 0.5
        else
            mult = tonumber(GoubayuHeal.Config["hot_multiply"]) or 1.0
        end
    end
    e = e * mult
    return e
end

-- 目标身上所有已记账 HOT 的预估总量（自身+他人同一公式；总和不超过真实缺口）
function GoubayuHeal.TrackedHOTEstimate(tname, hp, hpmissing)
    local est = 0
    local tracks = GoubayuHeal.trackedHOTs and GoubayuHeal.trackedHOTs[tname]
    if tracks then
        for sp, t in pairs(tracks) do
            if type(t) == "table" then
                local ticks = t.ticks or GoubayuHeal.HotTicks(sp)
                local intv = (GoubayuHeal.hot_tick_interval and GoubayuHeal.hot_tick_interval[sp]) or 3
                local remain = math.ceil((t.timeLeft or 0) / intv)
                est = est + GoubayuHeal.HOT_est(t.total, hp, ticks, remain)
            end
        end
    end
    if hpmissing and est > hpmissing then
        est = hpmissing
    end
    return est
end

-- 迅捷治愈吞噬 HOT：删掉该 HOT 记账（避免"剩余预跳 + 迅捷全额"双算），并归零单槽记录里的 HOT 部分。
function GoubayuHeal.CancelConsumedHot(targetName, hotSpell)
    if not (targetName and hotSpell) then
        return
    end
    GoubayuHeal.ClearTrackedHOT(targetName, hotSpell)
    local rec = GoubayuHeal.healing and GoubayuHeal.healing[targetName]
        and GoubayuHeal.healing[targetName][GoubayuHeal.my_name]
    if rec and rec["Spell"] == hotSpell then
        rec["HealingOverTime"] = 0
    end
end

-- buff spellId → 纯 HOT 技能名（回春/愈合/恢复）；非 HOT 返回 nil。
-- by 武藤纯子酱 2026.10.19
function GoubayuHeal.HotSpellNameForId(spellId)
    if not (spellId and spellId ~= 0 and GoubayuHeal.GetSpellIdSet) then
        return nil
    end
    local sp = GoubayuHeal.Rejuvenation
    if sp and GoubayuHeal.GetSpellIdSet(sp)[spellId] then
        return sp
    end
    sp = GoubayuHeal.Regrowth
    if sp and GoubayuHeal.GetSpellIdSet(sp)[spellId] then
        return sp
    end
    sp = GoubayuHeal.Renew
    if sp and GoubayuHeal.GetSpellIdSet(sp)[spellId] then
        return sp
    end
    return nil
end

-- 从 HOT 跟踪表清除某目标的某纯 HOT 的"标签/预估"：只归零该 HOT 的预估在途贡献，**不清重施锁**。
-- 原因：手动/宏取消 HOT、BUFF 位被挤、被驱散、被覆盖等场景都走这里——若清锁，会导致我们
-- 反复给一个主动取消 HOT 的目标再上 HOT（刷屏/浪费）。只有"迅捷治愈吞噬 HOT"才需要清锁，
-- 那条在 Heal() 里单独处理。by 武藤纯子酱 2026.10.19
function GoubayuHeal.ClearHotTrackingByName(name, hotSpell)
    if not (name and hotSpell) then
        return
    end
    GoubayuHeal.ClearTrackedHOT(name, hotSpell)
    local rec = GoubayuHeal.healing and GoubayuHeal.healing[name]
        and GoubayuHeal.healing[name][GoubayuHeal.my_name]
    if rec and rec["Spell"] == hotSpell and (rec["TimeLeft"] or 0) > 0 then
        rec["HealingOverTime"] = 0
    end
end

function GoubayuHeal.ClearHotTracking(guid, hotSpell)
    local name = GoubayuHeal.UnitNameFromGUID and GoubayuHeal.UnitNameFromGUID(guid)
    if not name then
        return
    end
    GoubayuHeal.ClearHotTrackingByName(name, hotSpell)
end

-- 回春/愈合光环消失（手动取消 / BUFF 位被挤 / 被驱散 / 被迅捷治愈吃掉）→ 即时清跟踪
-- by 武藤纯子酱 2026.10.19
function GoubayuHeal.OnHotAuraRemoved(guid, spellId)
    local sp = GoubayuHeal.HotSpellNameForId(spellId)
    if sp then
        GoubayuHeal.ClearHotTracking(guid, sp)
    end
end

-- 其他施法者的 HOT 成功落地（SPELL_GO_OTHER）：HOT 只有一条，对方覆盖了我们那条 →
-- 记账替换为对方（含等级/总量），供预估与迅捷选目标；覆盖必然伴随成功 SPELL_GO。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.OnOtherHotApplied(targetGuid, hotSpell, spellId)
    local name = GoubayuHeal.UnitNameFromGUID and GoubayuHeal.UnitNameFromGUID(targetGuid)
    if not name then
        return
    end
    local rank = GoubayuHeal.RankForSpellId(hotSpell, spellId)
    local total = 0
    if rank and GoubayuHeal.Spells[hotSpell] and GoubayuHeal.Spells[hotSpell][rank] then
        total = GoubayuHeal.Spells[hotSpell][rank]["HealingOverTime"] or 0
    end
    if total > 0 then
        GoubayuHeal.SetTrackedHOT(name, hotSpell, total, rank, false)
    else
        GoubayuHeal.ClearTrackedHOT(name, hotSpell)
    end
end

-- 定期核对：记账的 HOT 与目标实际光环不符（被吞噬/驱散/提前到期等）→ 删记账。
-- 只核对 hot_cast_cd_spells（回春/愈合/恢复）；8T2 附带恢复等 UnitHasHOT 不适用，交给时效过期。
-- 不清重施锁（只有迅捷治愈吞噬才清锁，见 Heal()）。by 武藤纯子酱 2026.10.20
function GoubayuHeal.ReconcileTrackedHOTs()
    if not GoubayuHeal.trackedHOTs then
        return
    end
    for tname, tracks in pairs(GoubayuHeal.trackedHOTs) do
        local u = GoubayuHeal.GetUnitID and GoubayuHeal.GetUnitID(tname)
        if u and UnitExists(u) then
            local gone = {}
            for sp, t in pairs(tracks) do
                if GoubayuHeal.hot_cast_cd_spells and GoubayuHeal.hot_cast_cd_spells[sp]
                    and not GoubayuHeal.UnitHasHOT(u, sp) then
                    gone[table.getn(gone) + 1] = sp
                end
            end
            for _, sp in ipairs(gone) do
                tracks[sp] = nil
            end
            if next(tracks) == nil then
                GoubayuHeal.trackedHOTs[tname] = nil
            end
        end
    end
end

function GoubayuHeal.Heal(unit, spell, rank, healvalue, noscale, forceMax)
    -- 死亡/灵魂状态（救赎之魂除外）：不发起施放（避免 CASTER_DEAD 错误把 _abortAction 置位）
    -- by 武藤纯子酱 2026.10.23
    if GoubayuHeal.PlayerDeadBlocked() then
        return false
    end
    local selfcasting = GetCVar("autoSelfCast")

    if (not unit or not spell or not rank or not UnitExists(unit)
        or not GoubayuHeal.Spells or not GoubayuHeal.Spells[spell]
        or not GoubayuHeal.Spells[spell][rank]) then
        SetCVar("autoSelfCast", selfcasting)
        return
    end

    -- 全局中止（沉默/昏迷/恐惧等，当前根本无法施法）期间不再尝试任何施法
    -- by 武藤纯子酱 2026.10.19
    if GoubayuHeal._abortAction then
        SetCVar("autoSelfCast", selfcasting)
        return false
    end

    -- 神圣打击(HS)只经近战奶专用施法通道（Paladin_CastSpellOnTarget）或未来的群疗决策通道施放，
    -- 需要近战可攻击目标，禁止被通用单体 Heal 通道误施（误施会打到友方/目标错误）
    -- by 武藤纯子酱 2026.9.6
    if spell == GoubayuHeal.Holy_Strike then
        SetCVar("autoSelfCast", selfcasting)
        return
    end

    -- 已有施法在途（非Nampower队列模式）：不再写入新的在途治疗记录/覆盖 i_am_healing，
    -- 仅按需对真正在途的目标做安全打断检查，避免污染当前施法的目标跟踪
    if (GoubayuHeal.casting_spell and not GoubayuHeal_np_allow_queue) then
        local healingtarget = GoubayuHeal.i_am_healing
        local isFirstRank = false

        if (healingtarget and GoubayuHeal.healing[healingtarget]
            and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]
            and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Rank"] == 1) then
            local spell = GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Spell"]
            if spell == GoubayuHeal.Flash_heal or spell == GoubayuHeal.Healing_touch
                or spell == GoubayuHeal.Regrowth or spell == GoubayuHeal.Flash_of_light
                or spell == GoubayuHeal.Lesser_healing_wave or spell == GoubayuHeal.Chain_heal
                or spell == GoubayuHeal.PriestHeal or spell == GoubayuHeal.Lesser_heal then
                isFirstRank = true
            end
        end

        local unit = GoubayuHeal.GetUnitID(healingtarget)
        local isFullHealth = false
        local _gh, _gmh = GoubayuHeal.GetUnitHealth(unit)
        if (unit and _gh == _gmh) then
            isFullHealth = true
        end

        if (GoubayuHeal.Config["safe_cancel"] == 1) then
            if (isFirstRank and GoubayuHeal.Config["allow_first_rank_ignore_overheal"] == 1) then
                if (isFullHealth) then
                    SpellStopCasting()
                end
            else
                local overheal = GoubayuHeal.GetOverheal()
                if (overheal > GoubayuHeal.Config["max_overheal"]) then
                    SpellStopCasting()
                end
            end
        end

        return 1
    end

    if (not noscale and not GoubayuHeal.dont_scale[spell]) then
        local h, maxh = GoubayuHeal.GetUnitHealth(unit)
        local neededHeal = maxh - h
        local scaleHealValue = healvalue or neededHeal
        rank = GoubayuHeal.ScaleSpell(unit, spell, rank, scaleHealValue)
    end

    local name = GoubayuHeal.UnitName(unit)
    if (string.find(unit, "pet")) then
        if (unit == "pet") then
            name = GoubayuHeal.UnitName("player") .. "-" .. name
        else
            name = GoubayuHeal.UnitName(string.gsub(unit, "pet", "")) .. "-" .. name
        end
    end

    -- HOT 冷却：愈合/回春/恢复 对同一目标在持续时间内只接一次（避免目标取消HOT后重复上）
    -- 例外：德鲁伊"覆盖愈合阈值">0 时，愈合跳过该锁——愈合是读条直接治疗，重放目的是那口直接治疗；
    -- 是否真的覆盖再由后面的阈值(hp<pct)判定。by 武藤纯子酱 2026.10.19
    local roPct = tonumber(GoubayuHeal.Config and GoubayuHeal.Config["allow_regrowth_overwrite_pct"]) or 100
    local allowRegrowthRecast = (spell == GoubayuHeal.Regrowth)
        and (GoubayuHeal.my_class == GoubayuHeal.Druid)
        and (roPct > 0)
    if (not allowRegrowthRecast) and GoubayuHeal.hot_cast_cd_spells
        and GoubayuHeal.hot_cast_cd_spells[spell] then
        GoubayuHeal.hot_cast_cd = GoubayuHeal.hot_cast_cd or {}
        GoubayuHeal.hot_cast_cd[spell] = GoubayuHeal.hot_cast_cd[spell] or {}
        local lastT = GoubayuHeal.hot_cast_cd[spell][name] or 0
        local cdDur = GoubayuHeal.hot_duration[spell] or 15
        if (GetTime() - lastT) < cdDur then
            SetCVar("autoSelfCast", selfcasting)
            return false
        end
    end

    GoubayuHeal.i_am_healing = name

    if not (GetNampowerVersion and GetCastInfo) then
        GoubayuHeal.heal_target_delay = GoubayuHeal.heal_target_delay or {}
        GoubayuHeal.heal_target_delay[name] = GetTime() + 1.0
    end

    local casttime = GoubayuHeal.Spells[spell][rank]["CastTime"]
    -- 迅捷 buff 判定统一用 HasBuffByName（直读 Nampower aura，不依赖可能未预热的 buff_texture_map）
    -- by 武藤纯子酱 2026.10.19
    if GoubayuHeal.HasBuffByName("player", GoubayuHeal.Natures_swiftness)
        or GoubayuHeal.HasBuffByName("player", GoubayuHeal.Shaman_Ancestral_swiftness) then
        casttime = 0
    end

    local heal, healmin, healmax, hot = GoubayuHeal.GetSpellHealing(unit, spell, rank)
    local cancelheal = heal
    if (healvalue and healvalue < heal) then
        cancelheal = healvalue
    end

    GoubayuHeal.healing[name] = GoubayuHeal.healing[name] or {}
    GoubayuHeal.healing[name][GoubayuHeal.my_name] = {
        ["CancelHeal"] = cancelheal,
        ["CastTime"] = casttime,
        ["Heal"] = (healmin + healmax) / 2,
        ["HealingOverTime"] = hot,
        ["Rank"] = rank,
        ["Spell"] = spell,
        ["Status"] = "Active",
        ["TankHealing"] = (not healvalue),
        ["TimeLeft"] = casttime
    }

    -- 我方 HOT 记账（统一表：目标→技能，覆盖即替换；他者 HOT 由 SPELL_GO_OTHER 记账）
    -- by 武藤纯子酱 2026.10.20
    if hot and hot > 0 then
        GoubayuHeal.SetTrackedHOT(name, spell, hot, rank, true)
    end

    -- 门检查失败时清除刚写入的在途治疗记录（复用 RollbackCastAttempt：含在途记录 + hot_cast_cd + 我方 HOT 记账）
    -- by 武藤纯子酱 2026.10.20
    local function cancelHealingEntry()
        GoubayuHeal.RollbackCastAttempt(spell, name)
    end

    if (not unit or not spell or not rank or not UnitExists(unit)) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    local gateRange = 40
    local gateSpellId = nil
    if (GoubayuHeal.Spells and GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][rank]
        and GoubayuHeal.Spells[spell][rank]["Range"]
        and GoubayuHeal.Spells[spell][rank]["Range"] > 0) then
        gateRange = GoubayuHeal.Spells[spell][rank]["Range"]
        gateSpellId = GoubayuHeal.Spells[spell][rank]["SpellId"]
    end

    local isSelfCast = (unit == "player") or (UnitIsUnit and UnitIsUnit(unit, "player"))
    if (not isSelfCast and GoubayuHeal.CanCastAtUnit(unit, gateRange, gateSpellId) == false) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if (not GoubayuHeal.Spells or not GoubayuHeal.Spells[spell]
        or not GoubayuHeal.Spells[spell][rank]) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if GetNampowerVersion then
        local playerGUID = GoubayuHeal.GetUnitGUID("player")
        local targetGUID = GoubayuHeal.GetUnitGUID(unit)
        GoubayuHeal.CastingSpeed:CleanExpiredCastData()

        -- 预测完成时间：优先用自己最近一次实测的施法时间（SPELL_START_SELF 快照，
        -- 反映当前加速/减速状态，如加速药水/饰品/增益）；无实测值时退回治疗库基础读条时间。
        -- 自然迅捷等瞬发（casttime=0）保持 0，恒最快放行
        local predictedCastSec = casttime or 0
        if predictedCastSec > 0 then
            local observedMs = GoubayuHeal.CastingSpeed.selfObservedCastMs
                and GoubayuHeal.CastingSpeed.selfObservedCastMs[GoubayuHeal.Spells[spell][rank]["SpellId"]]
            if observedMs and observedMs > 0 then
                predictedCastSec = observedMs / 1000
            end
        end

        if not GoubayuHeal.CastingSpeed:ShouldHealTarget(targetGUID, playerGUID,
            GetTime() + predictedCastSec, (casttime or 0) == 0) then
            SetCVar("autoSelfCast", selfcasting)
            cancelHealingEntry()
            return
        end
    end

    if (not GoubayuHeal.Spells) then
        GoubayuHeal.UpdateSpells()
    end

    if (not GoubayuHeal.Spells[spell] or not GoubayuHeal.Spells[spell][rank]) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if ((GoubayuHeal.GetSpellCooldown(GoubayuHeal.GetSpellCDId(GoubayuHeal.Spells[spell][rank])) or 0) > 0) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    GoubayuHeal.UpdatePlayerData(0, unit)

    if ((not (GoubayuHeal.rez_spells[spell])) and (not GoubayuHeal.CanHeal(unit))) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if (GoubayuHeal.rez_spells[spell]) and (not GoubayuHeal.CanRez(unit)) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if (spell == GoubayuHeal.Power_word_shield and (GoubayuHeal.UnitHasWeakenedSoul(unit)
        or GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Ice_barrier)
        or GoubayuHeal.UnitGotBuff(unit, GoubayuHeal.Power_word_shield))) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if ((spell == GoubayuHeal.Divine_shield or spell == GoubayuHeal.Divine_protection
        or spell == GoubayuHeal.Blessing_of_protection)
        and GoubayuHeal.UnitGotDebuff(unit, GoubayuHeal.Forbearance)) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if spell == GoubayuHeal.Renew or spell == GoubayuHeal.Rejuvenation
        or spell == GoubayuHeal.Regrowth then
        local buffFull = GoubayuHeal.IsBuffBarFull(unit)
        if buffFull == true then
            SetCVar("autoSelfCast", selfcasting)
            cancelHealingEntry()
            return false
        end

        local hasBuff = GoubayuHeal.UnitHasHOT(unit, spell)
        if hasBuff then
            local hh, hmh = GoubayuHeal.GetUnitHealth(unit)
            local hp = 0
            if hmh and hmh > 0 then
                hp = hh / hmh
            end

            local ht = tonumber(GoubayuHeal.Config["hot_heal_threshold"]) or 0.4
            local appliedRank = GoubayuHeal.GetUnitHOTRank(unit, spell)
            local cr = tonumber(rank) or 0

            -- 允许覆盖愈合（默认开，仅德鲁伊）：目标是残血（低于 hot_heal_threshold）或该法术不是愈合时，
            -- 允许用同级/更低级愈合覆盖已有愈合，避免"目标快死了却因身上有旧愈合而不加血"
            -- by 武藤纯子酱 2026.9.27
            -- 仅德鲁伊愈合：目标血量低于阈值才允许覆盖（阈值 0% = 从不覆盖，等价旧"关闭"）
            local allowOverwrite = (GoubayuHeal.my_class == GoubayuHeal.Druid)
                and (spell == GoubayuHeal.Regrowth)
                and (hp * 100 < (tonumber(GoubayuHeal.Config["allow_regrowth_overwrite_pct"]) or 100))

            if allowOverwrite or (appliedRank and cr and cr > appliedRank and hp < ht) then
                -- 允许覆盖
            else
                SetCVar("autoSelfCast", selfcasting)
                cancelHealingEntry()
                return false
            end
        end
    end

    if (spell == GoubayuHeal.Swiftmend and not (GoubayuHeal.UnitHasHOT(unit,
        GoubayuHeal.Rejuvenation) or GoubayuHeal.UnitHasHOT(unit, GoubayuHeal.Regrowth))) then
        -- 目标实际无回春/愈合：从 HOT 跟踪表清除（避免后续反复空跑），顺延到下一目标/下一档
        -- by 武藤纯子酱 2026.10.19
        GoubayuHeal.ClearHotTrackingByName(name, GoubayuHeal.Rejuvenation)
        GoubayuHeal.ClearHotTrackingByName(name, GoubayuHeal.Regrowth)
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return false
    end

    -- 记录迅捷治愈将消耗哪个 HOT（施放成功后需重置其“内置冷却”以便立刻补回）
    -- by 武藤纯子酱 2026.9.6
    local swiftmendConsumedHot = nil
    if spell == GoubayuHeal.Swiftmend then
        if GoubayuHeal.UnitHasHOT(unit, GoubayuHeal.Rejuvenation) then
            swiftmendConsumedHot = GoubayuHeal.Rejuvenation
        elseif GoubayuHeal.UnitHasHOT(unit, GoubayuHeal.Regrowth) then
            swiftmendConsumedHot = GoubayuHeal.Regrowth
        end
    end

    if (forceMax) then
        -- 强制满级：保持调用方给的最高等级，不做蓝量/等级降级
        -- （否则"强制满级法术"会被静默压回 1 级） by 武藤纯子酱 2026.9.21
    elseif ((GoubayuHeal.my_class == GoubayuHeal.Druid
        and GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Clearcasting))
        or (GoubayuHeal.my_class == GoubayuHeal.Priest
            and GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Inner_focus))) then
        rank = table.getn(GoubayuHeal.Spells[spell])
    else
        if (GoubayuHeal.Config["scale_spells"] == 1) then
            while (rank > 0 and GoubayuHeal.SpellRankOutOfMana(spell, rank)) do
                rank = rank - 1
            end
        else
            if (rank > 0 and GoubayuHeal.SpellRankOutOfMana(spell, rank)) then
                rank = 0
            end
        end
    end

    if (not forceMax) then
        while (GoubayuHeal.spell_level[spell] and rank > 0
            and GoubayuHeal.spell_level[spell][rank]
            and UnitLevel(unit) < GoubayuHeal.spell_level[spell][rank]) do
            rank = rank - 1
        end
    end

    if (rank == 0) then
        SetCVar("autoSelfCast", selfcasting)
        cancelHealingEntry()
        return
    end

    if (healvalue and not GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Clearcasting)
        and not GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Inner_focus)
        and (not noscale)) then
        local scaleHealValue = healvalue
        rank = GoubayuHeal.ScaleSpell(unit, spell, rank, scaleHealValue)
    end

    -- 等级缩放/天赋最大化后，同步在途治疗记录（避免按旧等级虚标治疗量/施法时间）
    local entry = GoubayuHeal.healing[name] and GoubayuHeal.healing[name][GoubayuHeal.my_name]
    if entry and entry["Rank"] ~= rank then
        local sd = GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][rank]
        if sd then
            local h2, hmin2, hmax2, hot2 = GoubayuHeal.GetSpellHealing(unit, spell, rank)
            entry["Rank"] = rank
            if h2 then
                entry["CancelHeal"] = healvalue and math.min(h2, healvalue) or h2
            end
            if hmin2 and hmax2 then
                entry["Heal"] = (hmin2 + hmax2) / 2
            end
            if hot2 then
                entry["HealingOverTime"] = hot2
            end
            if casttime and casttime > 0 and sd["CastTime"] then
                entry["CastTime"] = sd["CastTime"]
                entry["TimeLeft"] = sd["CastTime"]
            end
        end
    end

    GoubayuHeal.error_message = nil

    local spellData = GoubayuHeal.Spells[spell][rank]
    local spell_with_rank

    local checkname = GetSpellName(spellData["ID"], BOOKTYPE_SPELL)
    -- 无等级法术（迅捷治愈/自然迅捷/先祖迅捷）与特殊处理的圣疗术裸名施放，见 BuildSpellWithRank
    -- by 武藤纯子酱 2026.9.21
    spell_with_rank = GoubayuHeal.BuildSpellWithRank(spell, rank, checkname)

    local previousTarget = nil
    local targetGUID = GoubayuHeal.GetUnitGUID(unit)

    if GoubayuHeal.spell_awaiting_target_Spell then
        GoubayuHeal.clean_spell_awaiting_target()
    end

    -- 记录本次施放尝试：供事件侧在"同步读不到错误"时回滚（覆盖瞬发技能被拒的场景）
    -- by 武藤纯子酱 2026.10.19
    GoubayuHeal._lastAttempt = { spell = spell, name = name, rank = rank, time = GetTime() }

    if GetNampowerVersion then
        CastSpellByName(spell_with_rank, targetGUID)
    else
        if UnitExists("target") then
            previousTarget = UnitName("target")
        else
            previousTarget = nil
        end

        if UnitExists(unit) then
            TargetUnit(unit)
        end

        CastSpellByName(spell_with_rank)

        if previousTarget then
            TargetByName(previousTarget, 1)
        else
            ClearTarget()
        end
    end

    -- HOT 冷却：记录本次对该目标施放的 HOT 时间
    if GoubayuHeal.hot_cast_cd_spells and GoubayuHeal.hot_cast_cd_spells[spell] then
        GoubayuHeal.hot_cast_cd = GoubayuHeal.hot_cast_cd or {}
        GoubayuHeal.hot_cast_cd[spell] = GoubayuHeal.hot_cast_cd[spell] or {}
        GoubayuHeal.hot_cast_cd[spell][name] = GetTime()
    end

    SetCVar("autoSelfCast", selfcasting)

    if (GoubayuHeal.error_message) then
        -- error_message 在施放前刚被清空（见上方），同一调用栈内不可能有别的来源 →
        -- 这里出现的任何错误都来自本次施放。判定：
        --  · 唯一"算成功"的例外：动作进行中(SPELL_FAILED_SPELL_IN_PROGRESS) 且本技能自身确实在
        --    CD(GCD) 上 —— 说明我们自己的施法在途 → 终态 return 1
        --  · 其余（移动失败 / 命中 error_unable / 迅捷治愈无 HOT 等目标不满足）：本次没放出去 →
        --    回滚副作用并 return false（交上层顺延到下一档；旧逻辑在此 return 1 = 本次按键不出手）
        -- by 武藤纯子酱 2026.10.19
        if (GoubayuHeal.error_moving[GoubayuHeal.error_message]) then
            GoubayuHeal.SetOnlyInstant()
        else
            GoubayuHeal.only_instant_spells = nil
            GoubayuHeal.only_instant_spells_time = nil
        end

        if SPELL_FAILED_SPELL_IN_PROGRESS
            and string.find(GoubayuHeal.error_message, SPELL_FAILED_SPELL_IN_PROGRESS)
            and GoubayuHeal.IsSpellOnCooldown(spell) then
            SetCVar("autoSelfCast", selfcasting)
            GoubayuHeal.only_instant_spells = nil
            GoubayuHeal.only_instant_spells_time = nil
            return 1
        end

        if GoubayuHeal.IsGlobalAbortError(GoubayuHeal.error_message) then
            GoubayuHeal._abortAction = true
        end
        SetCVar("autoSelfCast", selfcasting)
        GoubayuHeal.RollbackCastAttempt(spell, name)
        return false
    end

    if (SpellIsTargeting()) then
        SpellStopTargeting()
        -- 目标选择阶段取消：施法未发生，清掉在途治疗记录（否则假"Active"状态压缺口）
        cancelHealingEntry()
        return
    end

    GoubayuHeal.last_cast_spell = spell
    -- 迅捷治愈成功吃掉该 HOT 后，重置该 HOT 对目标的内置冷却，允许马上补回
    -- by 武藤纯子酱 2026.9.6
    if swiftmendConsumedHot and GoubayuHeal.hot_cast_cd
        and GoubayuHeal.hot_cast_cd[swiftmendConsumedHot] then
        GoubayuHeal.hot_cast_cd[swiftmendConsumedHot][name] = nil
    end
    -- 迅捷治愈吞噬 HOT：一并取消该目标身上"被吞噬 HOT"的预估在途贡献
    -- （否则其剩余治疗量会继续计入最长一个 HOT 时长，目标虚高导致后续不出手）
    -- by 武藤纯子酱 2026.10.19
    if swiftmendConsumedHot then
        GoubayuHeal.CancelConsumedHot(name, swiftmendConsumedHot)
    end
    return 1
end

-- ============================================================
-- 按职业配置自动选择治疗技能
-- ============================================================

function GoubayuHeal.HealUsingClass(unit, class, healvalue, allowAoE)
    if (not unit or not class or not GoubayuHeal.Config["classes"][class]) then
        return
    end

    if not UnitExists(unit) or not UnitIsFriend("player", unit) then
        return
    end

    -- 全局中止（沉默/昏迷等）期间直接不做事
    -- by 武藤纯子酱 2026.10.19
    if GoubayuHeal._abortAction then
        return
    end

    local currentHealth, maxHealth = GoubayuHeal.GetUnitHealth(unit)
    if currentHealth >= maxHealth then
        return
    end

    local percent = (currentHealth / maxHealth) * 100
    local neededHeal = maxHealth - currentHealth

    if not healvalue or healvalue <= 0 then
        healvalue = neededHeal
    end

    if (percent / 100) >= GoubayuHeal.Config["min_heal_threshold"] then
        return
    end

    -- 牧师：疾速治疗buff期间只使用强效治疗术
    if GoubayuHeal.my_class == GoubayuHeal.Priest
        and GoubayuHeal.Config and GoubayuHeal.Config["priest_force_greater_heal"] == 1
        and GoubayuHeal.UnitGotBuff and GoubayuHeal.UnitGotBuff("player",
            GoubayuHeal.Rapid_healing) then
        local ghRank = GoubayuHeal.PickForceGreaterHealRank(class, percent)
        if ghRank then
            GoubayuHeal.Heal(unit, GoubayuHeal.Greater_heal, ghRank, healvalue)
            return 1
        end
        return
    end

    local validSpells = {}
    local classConfig = GoubayuHeal.Config["classes"][class]

    -- 迅捷治愈辅助：在团/队/自身/宠物中找“另一个有回春或愈合 HOT 且受伤”的目标
    -- by 武藤纯子酱 2026.9.6
    local function swiftmendAltUnit(originUnit, maxPercent)
        -- 在所有"低于本档百分比 + 有回春/愈合"的目标里选 HOT 等级最高的（同级取更残）。
        -- 结果短时缓存（~0.3s）：避免每次按键/每档重复全团扫描。by 武藤纯子酱 2026.10.20
        -- 结果与 originUnit 无关（不再排除它），缓存键只用 maxPercent：同档共享一次扫描
        local cacheKey = tostring(maxPercent)
        local sc = GoubayuHeal._swiftAltCache
        if sc and sc.key == cacheKey and (GetTime() - sc.time) <= 0.3 then
            return sc.unit
        end
        local n = GetNumRaidMembers()
        local por = "raid"
        if n == 0 then
            n = GetNumPartyMembers()
            por = "party"
        end
        local best, bestRank, bestMiss = nil, -1, -1
        local function consider(u)
            if not UnitExists(u) then
                return
            end
            if GoubayuHeal.CanHeal and not GoubayuHeal.CanHeal(u) then
                return
            end
            local h, mh = GoubayuHeal.GetUnitHealth(u)
            if not (mh and mh > 0) then
                return
            end
            -- 只考虑"低于本档百分比"的目标（严格小于）
            if maxPercent and (h / mh * 100) >= maxPercent then
                return
            end
            if not (GoubayuHeal.UnitHasHOT(u, GoubayuHeal.Rejuvenation)
                or GoubayuHeal.UnitHasHOT(u, GoubayuHeal.Regrowth)) then
                return
            end
            -- 距离/视野：挑中却够不到会被 Heal 的 CanCastAtUnit 拒绝 → 本档空转（卡住）。
            -- 旧版"当前目标有 HOT 就直接放"因当前目标已过距离检查而不会踩到，故本次必须补上。
            -- by 武藤纯子酱 2026.10.20
            if GoubayuHeal.CanCastAtUnit and GoubayuHeal.CanCastAtUnit(u, 40) == false then
                return
            end
            -- 优先 HOT 等级最高者（同等时取更残）：迅捷吞噬量随 HOT 等级提高
            -- by 武藤纯子酱 2026.10.20
            local rj = GoubayuHeal.GetUnitHOTRank and GoubayuHeal.GetUnitHOTRank(u, GoubayuHeal.Rejuvenation)
            local rg = GoubayuHeal.GetUnitHOTRank and GoubayuHeal.GetUnitHOTRank(u, GoubayuHeal.Regrowth)
            local rk = rj or 0
            if (rg or 0) > rk then
                rk = rg or 0
            end
            local miss = mh - h
            if rk > bestRank or (rk == bestRank and miss > bestMiss) then
                best, bestRank, bestMiss = u, rk, miss
            end
        end
        consider("player")
        if UnitExists("pet") then
            consider("pet")
        end
        for a = 1, n do
            consider(por .. a)
        end
        GoubayuHeal._swiftAltCache = { key = cacheKey, unit = best, time = GetTime() }
        return best
    end

    if type(classConfig) == "table" then
        for curpercent, data in classConfig do
            if GoubayuHeal._abortAction then
                break
            end
            if type(data) == "table" then
                local curspell = data["Spell"]
                local rank = data["Rank"]
                local isInstant = false

                if GoubayuHeal.Spells[curspell] and GoubayuHeal.Spells[curspell][rank] then
                    isInstant = (GoubayuHeal.Spells[curspell][rank]["CastTime"] == 0)
                    if curspell == GoubayuHeal.Holy_nova then
                        isInstant = true
                    elseif curspell == GoubayuHeal.Prayer_of_healing then
                        isInstant = false
                    end
                end

                local isAoESpell = (curspell == GoubayuHeal.Holy_nova
                    or curspell == GoubayuHeal.Prayer_of_healing
                    or curspell == GoubayuHeal.Chain_heal)

                local isAllowed = true
                if GoubayuHeal.IsMoving() then
                    isAllowed = isInstant
                else
                    isAllowed = true
                end

                -- tank/单体模式：跳过AOE档位（新增祷言/链）
                if not (GoubayuHeal.tankheal_mode and isAoESpell)
                    and (not isAoESpell or allowAoE or isInstant) and isAllowed then
                    table.insert(validSpells, {
                        percent = curpercent,
                        spell = curspell,
                        rank = rank,
                        scale = data["Scale"],
                        attachment = data["Attachment"],
                        attachmentRank = data["AttachmentRank"],
                        alternate = data["Alternate"]
                    })
                end
            end
        end
    end

    local eligibleSpells = {}
    for _, spellData in ipairs(validSpells) do
        if tonumber(spellData.percent) > percent then
            table.insert(eligibleSpells, spellData)
        end
    end

    local eligibleSpellsCount = 0
    for _ in ipairs(eligibleSpells) do
        eligibleSpellsCount = eligibleSpellsCount + 1
    end

    if eligibleSpellsCount > 0 then
        table.sort(eligibleSpells, function(a, b) return a.percent < b.percent end)
        validSpells = eligibleSpells
    else
        validSpells = {}
    end

    -- 救急暂停团刷主技能：已设置的坦克（MT/8T）在救急线以下时，只要本方案在"当前目标血量"
    -- 下还有其它（单体）档位可用，就跳过团刷主技能，让循环落到单体档；
    -- 若本档只剩团刷技能（没有可用单体档），仍照常施放团刷。
    -- by 武藤纯子酱 2026.10.23
    local aoeMainSpells = {
        [GoubayuHeal.Holy_nova] = 1,
        [GoubayuHeal.Prayer_of_healing] = 1,
        [GoubayuHeal.Chain_heal] = 1,
        [GoubayuHeal.Tranquility] = 1,
    }
    local pauseAoeMain = false
    if GoubayuHeal.TankInRescue and GoubayuHeal.TankInRescue() then
        for _, sd in ipairs(validSpells) do
            if not aoeMainSpells[sd.spell] then
                pauseAoeMain = true
                break
            end
        end
    end

    for _, spellData in ipairs(validSpells) do
        local curspell = spellData.spell
        local curpercent = spellData.percent
        local rank = spellData.rank
        local noscale = (spellData.scale ~= 1)
        local forceMaxForCast = false
        local attachment = spellData.attachment
        local attachmentRank = spellData.attachmentRank

        local checkRank = rank
        if (GoubayuHeal.Config["scale_spells"] == 1) then
            checkRank = 1
        end

        if not GoubayuHeal.SpellRankOutOfMana(curspell, checkRank) then
            local hasRenew = false
            local hasRejuvenation = false
            local hasRegrowth = false
            local skipSpell = false

            -- 救急暂停团刷主技能（坦克在救急线以下且本方案还有单体档可用）
            -- by 武藤纯子酱 2026.10.23
            if pauseAoeMain and aoeMainSpells[curspell] then
                skipSpell = true
            end

            if curspell == GoubayuHeal.Renew or curspell == GoubayuHeal.Rejuvenation
                or curspell == GoubayuHeal.Regrowth then
                local buffFull = GoubayuHeal.IsBuffBarFull(unit)
                if buffFull == true then
                    skipSpell = true
                end

                local hasHOT = GoubayuHeal.UnitHasHOT(unit, curspell)
                if curspell == GoubayuHeal.Renew then
                    hasRenew = hasHOT
                elseif curspell == GoubayuHeal.Rejuvenation then
                    hasRejuvenation = hasHOT
                else
                    hasRegrowth = hasHOT
                end
            end

            local swiftmendAttached = (attachment == GoubayuHeal.Swiftmend)
            if (curspell == GoubayuHeal.Renew and hasRenew)
                or (curspell == GoubayuHeal.Rejuvenation and hasRejuvenation)
                or (curspell == GoubayuHeal.Regrowth and hasRegrowth) then
                if swiftmendAttached then
                    -- 挂靠迅捷治愈：目标有HOT时由迅捷吃掉
                else
                    local hh, hmh = GoubayuHeal.GetUnitHealth(unit)
                    local hp = 0
                    if hmh and hmh > 0 then
                        hp = hh / hmh
                    end

                    local ht = tonumber(GoubayuHeal.Config["hot_heal_threshold"]) or 0.4
                    local appliedRank = GoubayuHeal.GetUnitHOTRank(unit, curspell)
                    local cr = tonumber(rank) or 0

                    -- 允许覆盖愈合（默认开，仅德鲁伊）：愈合不阻止同级/低级覆盖，避免残血目标因旧愈合而不加血
                    -- by 武藤纯子酱 2026.9.27
                    -- 仅德鲁伊愈合：目标血量低于阈值才允许覆盖（0% = 不覆盖）
                    -- by 武藤纯子酱 2026.10.19
                    local allowOverwrite2 = (GoubayuHeal.my_class == GoubayuHeal.Druid)
                        and (curspell == GoubayuHeal.Regrowth)
                        and (hp * 100 < (tonumber(GoubayuHeal.Config["allow_regrowth_overwrite_pct"]) or 100))

                    if allowOverwrite2 or (appliedRank and cr and cr > appliedRank and hp < ht) then
                        -- 允许覆盖
                    else
                        skipSpell = true
                    end
                end
            end

            -- 迅捷治愈（档位主技能）：在本档百分比以下、身上有回春/愈合的目标里，
            -- 选 HOT 等级最高的（同级取更残）施放；一个都没有则本档跳过，落到下一档。
            -- by 武藤纯子酱 2026.10.20
            if curspell == GoubayuHeal.Swiftmend then
                local altU = swiftmendAltUnit and swiftmendAltUnit(unit, tonumber(curpercent))
                if not altU and GoubayuHeal.SwiftmendRescanUnit then
                    -- 最终兜底：实扫刷新 HOT 表后再选目标
                    altU = GoubayuHeal.SwiftmendRescanUnit(tonumber(curpercent))
                end
                if altU then
                    local altRank = rank
                    if altRank == 0 then altRank = 1 end
                    if GoubayuHeal.Heal(altU, curspell, altRank,
                        GoubayuHeal.GetHealValue and GoubayuHeal.GetHealValue(altU) or 0,
                        (noscale or forceMaxForCast), forceMaxForCast) then
                        GoubayuHeal.only_instant_spells = nil
                        return 1
                    end
                end
                skipSpell = true
            end

            if not skipSpell then
                if tonumber(curpercent) > percent then
                    local currentHealth, maxHealth = GoubayuHeal.GetUnitHealth(unit)
                    local targetHealth = maxHealth * GoubayuHeal.Config["min_heal_threshold"]
                    local healthToThreshold = targetHealth - currentHealth
                    local targetHealValue = math.max(healvalue, healthToThreshold)

                    local forceMaxRank = false
                    if GoubayuHeal.IsHealModifierKeyDown("heal_max_modifier")
                        or GoubayuHeal.Config["always_tank_target"] == 1 then
                        forceMaxRank = true
                        forceMaxForCast = true
                    end

                    if forceMaxRank then
                        if GoubayuHeal.Spells and GoubayuHeal.Spells[curspell] then
                            local maxRank = table.getn(GoubayuHeal.Spells[curspell])
                            rank = maxRank
                        end
                    else
                         if (not GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Clearcasting)
                             and not GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Inner_focus)
                             and (not noscale)) then
                             local scaleHealValue = healvalue
                             rank = GoubayuHeal.ScaleSpell(unit, curspell, rank,
                                 scaleHealValue)
                         end
                    end

                    if rank ~= 0 then
                        if GoubayuHeal.Spells[curspell] and GoubayuHeal.Spells[curspell][rank] then
                            local cooldown = (GoubayuHeal.GetSpellCooldown(
                                GoubayuHeal.GetSpellCDId(GoubayuHeal.Spells[curspell][rank])) or 0)

                            if cooldown == 0 then
                                -- 团刷附件（新增祷言/链）：与主技能对比治疗量，选高者施放；tankheal 模式跳过团刷
                                local attIsAOE = attachment and (attachment == GoubayuHeal.Holy_nova
                                    or attachment == GoubayuHeal.Prayer_of_healing
                                    or attachment == GoubayuHeal.Chain_heal)
                                if attIsAOE then
                                    -- 有已设置的坦克（MT/8T）在救急线以下：暂停团刷挂接，优先单体治疗
                                    -- by 武藤纯子酱 2026.10.23
                                    if GoubayuHeal.tankheal_mode
                                        or (GoubayuHeal.TankInRescue and GoubayuHeal.TankInRescue()) then
                                        attachment = nil
                                        attachmentRank = nil
                                    else
                                        local attRank = attachmentRank
                                        if not attRank then
                                            local hr = 1
                                            for r, _ in pairs(GoubayuHeal.Spells[attachment]) do
                                                local rn = tonumber(r) or 1
                                                if rn > hr then hr = rn end
                                            end
                                            attRank = hr
                                        end
                                        if GoubayuHeal.Spells[attachment]
                                            and GoubayuHeal.Spells[attachment][attRank] then
                                            local mainHeal = GoubayuHeal.GetSpellHealing(
                                                unit, curspell, rank) or 0
                                            local attHeal = GoubayuHeal.GetSpellHealing(
                                                unit, attachment, attRank) or 0
                                            if attHeal > mainHeal then
                                                -- 附件团刷治疗量更高：用它替代主技能施放
                                                curspell = attachment
                                                rank = attRank
                                                attachment = nil
                                                attachmentRank = nil
                                            end
                                        end
                                    end
                                elseif attachment and GoubayuHeal.attachment_spells
                                    and GoubayuHeal.attachment_spells[attachment]
                                    and GoubayuHeal.Spells[attachment] then
                                    -- 附件未学习/CD时只跳过附件本身，主技能不受影响（独立判定）

                                    if attachment == GoubayuHeal.Holy_Strike then
                                        -- 神圣打击挂接：需近战可攻击目标 + 本档群疗条件满足（与方案档同判据）；
                                        -- 只能走近战奶专用通道（通用 Heal 通道会拒绝神圣打击）
                                        -- by 武藤纯子酱 2026.9.21
                                        local hsAoeX = GoubayuHeal.Paladin_HSAoeParams()
                                        local hsPctFrac = tonumber(curpercent)
                                        if hsPctFrac then
                                            hsPctFrac = hsPctFrac / 100
                                        end
                                        if GoubayuHeal.my_class == GoubayuHeal.Paladin
                                            and UnitExists("target")
                                            and UnitCanAttack("player", "target")
                                            and GoubayuHeal.Paladin_CheckMeleeRange
                                            and GoubayuHeal.Paladin_CheckMeleeRange("target")
                                            and not GoubayuHeal.Paladin_IsCasting()
                                            and not GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Holy_Strike)
                                            and GoubayuHeal.Paladin_HolyStrikeAoECount(hsPctFrac)
                                                >= hsAoeX.count then
                                            local gHS = GoubayuHeal.Paladin_GetUnitID
                                                and GoubayuHeal.Paladin_GetUnitID("target")
                                            GoubayuHeal.Paladin_CastSpellOnTarget(
                                                GoubayuHeal.Holy_Strike, gHS)
                                        end
                                    elseif attachment == GoubayuHeal.Natures_swiftness
                                        or attachment == GoubayuHeal.Shaman_Ancestral_swiftness then
                                        -- 已有迅捷buff（尚未被消耗）时不重复施放，避免白烧3分钟CD
                                        -- by 武藤纯子酱 2026.9.21
                                        local hasSwift = GoubayuHeal.HasBuffByName
                                            and GoubayuHeal.HasBuffByName("player", attachment)
                                        if not hasSwift then
                                            local spellID = nil
                                            for r, data in pairs(GoubayuHeal.Spells[attachment]) do
                                                if type(data) == "table"
                                                    and (data["SpellId"] or data["ID"]) then
                                                    spellID = GoubayuHeal.GetSpellCDId(data)
                                                    break
                                                end
                                            end

                                            if spellID then
                                                local attachmentCooldown =
                                                    (GoubayuHeal.GetSpellCooldown(spellID) or 0)
                                                if attachmentCooldown == 0 then
                                                    CastSpellByName(attachment)
                                                end
                                            else
                                                -- spellId 未取到（无等级技能反查失败）：按名字直接施放，
                                                -- 由客户端判定CD/未就绪
                                                CastSpellByName(attachment)
                                            end
                                        end
                                    else
                                        local castRank = attachmentRank
                                        if not castRank then
                                            local highestRankNum = 1
                                            local highestRankStr = "1"
                                            for r, _ in pairs(GoubayuHeal.Spells[attachment]) do
                                                local rNum = tonumber(r) or 1
                                                if rNum > highestRankNum then
                                                    highestRankNum = rNum
                                                    highestRankStr = r
                                                end
                                            end
                                            castRank = tonumber(highestRankStr) or 1
                                        end

                                        local attachmentCooldown = 0
                                        if GoubayuHeal.Spells[attachment]
                                            and GoubayuHeal.Spells[attachment][castRank] then
                                            attachmentCooldown =
                                                (GoubayuHeal.GetSpellCooldown(
                                                    GoubayuHeal.Spells[attachment][castRank]["ID"])
                                                or 0)
                                        end

                                        if attachmentCooldown == 0 then
                                            local attachmentTarget = unit
                                            if not GoubayuHeal.attachment_has_target[attachment] then
                                                attachmentTarget = "player"
                                            end

                                            -- 保护之手：目标有自律(Forbearance)debuff 时不能施放（与圣佑/圣盾一致）
                                            local skipAttachment = false
                                            if attachment == GoubayuHeal.Blessing_of_protection
                                                and GoubayuHeal.UnitGotDebuff
                                                and GoubayuHeal.UnitGotDebuff(
                                                    attachmentTarget, GoubayuHeal.Forbearance) then
                                                skipAttachment = true
                                            end

                                            if not skipAttachment then
                                                GoubayuHeal.Heal(attachmentTarget, attachment,
                                                    castRank)
                                            end
                                        end
                                    end
                                end

                                -- 迅捷（自然迅捷/先祖迅捷）没有公共冷却：放完直接继续用同一 Heal 施放主治疗（一次按键完成）。
                                -- 主治疗若被拒，Heal() 的回滚会清掉在途记录/hot_cast_cd，不会锁目标。
                                -- by 武藤纯子酱 2026.10.20

                                local finalSpell = curspell
                                local finalRank = rank

                                -- 非治疗技能（自然迅捷/先祖迅捷/圣盾/圣佑/保护之手）失败后不强制重试：
                                -- 它们不是治疗技能，强制重试会占掉本次动作（且该技能常在CD中→本次不施放任何技能），
                                -- 表现为"迅捷施放后方案里的其他技能都不再施放" by 武藤纯子酱 2026.9.21
                                if GoubayuHeal.last_interrupted_spell
                                    and GoubayuHeal.non_heal_spells
                                    and GoubayuHeal.non_heal_spells[GoubayuHeal.last_interrupted_spell] then
                                    GoubayuHeal.last_interrupted_spell = nil
                                end

                                if GoubayuHeal.last_interrupted_spell
                                    and GoubayuHeal.Spells
                                    and GoubayuHeal.Spells[GoubayuHeal.last_interrupted_spell] then
                                    finalSpell = GoubayuHeal.last_interrupted_spell
                                    finalRank = table.getn(GoubayuHeal.Spells[
                                        GoubayuHeal.last_interrupted_spell])
                                    GoubayuHeal.last_interrupted_spell = nil
                                else
                                    local shouldAlternate = (GoubayuHeal.my_class == GoubayuHeal.Priest)
                                        and (GoubayuHeal.Config
                                            and GoubayuHeal.Config["priest_alternate_spells"] == 1)
                                        and (spellData.alternate and GoubayuHeal.Spells
                                            and GoubayuHeal.Spells[spellData.alternate])
                                        and (GoubayuHeal.last_cast_spell
                                            and GoubayuHeal.last_cast_spell == curspell)
                                    -- 8T2：强效治疗术连续施放自带5级恢复HOT即触发祈祷之书，无需交替
                                    if shouldAlternate and curspell == GoubayuHeal.Greater_heal
                                        and GoubayuHeal.Config
                                        and GoubayuHeal.Config["priest_8t2"] == 1 then
                                        shouldAlternate = false
                                    end

                                    if shouldAlternate then
                                        local altMax = table.getn(GoubayuHeal.Spells[
                                            spellData.alternate])
                                        local acheck = altMax
                                        if GoubayuHeal.Config["scale_spells"] == 1 then
                                            acheck = 1
                                        end

                                        if not GoubayuHeal.SpellRankOutOfMana(
                                            spellData.alternate, acheck) then
                                            finalSpell = spellData.alternate
                                            finalRank = altMax
                                        end
                                    end
                                end

                                local castTime = GoubayuHeal.Spells[finalSpell][finalRank]["CastTime"]
                                    or 0

                                if GoubayuHeal.HasBuffByName("player",
                                    GoubayuHeal.Natures_swiftness)
                                    or GoubayuHeal.HasBuffByName("player",
                                        GoubayuHeal.Shaman_Ancestral_swiftness) then
                                    castTime = 0
                                end

                                -- 非治疗技能（迅捷/圣盾/圣佑/保护之手）：给自己或目标上buff
                                -- 施放后不阻塞后续治疗技能；已有buff或CD中时跳过
                                if GoubayuHeal.non_heal_spells[finalSpell] then
                                    local hasNonHealBuff
                                    if finalSpell == GoubayuHeal.Blessing_of_protection then
                                        hasNonHealBuff = GoubayuHeal.HasBuffByName(unit, finalSpell)
                                    else
                                        hasNonHealBuff = GoubayuHeal.HasBuffByName("player", finalSpell)
                                    end
                                    if not hasNonHealBuff then
                                        -- Nampower优先用真实法术ID(GetSpellIdCooldown高效)；非Nampower用槽位号(原生)
                                        local swiftID = nil
                                        for r, d in pairs(GoubayuHeal.Spells[finalSpell]) do
                                            if type(d) == "table" then
                                                if GetNampowerVersion then
                                                    swiftID = d["SpellId"] or d["ID"]
                                                else
                                                    swiftID = d["ID"]
                                                end
                                                break
                                            end
                                        end
                                        local cdVal = swiftID and (GoubayuHeal.GetSpellCooldown(swiftID) or 0) or -1
                                        if swiftID and cdVal == 0 then
                                            if finalSpell == GoubayuHeal.Blessing_of_protection then
                                                GoubayuHeal.Heal(unit, finalSpell, finalRank)
                                            else
                                                CastSpellByName(finalSpell)
                                            end
                                        end
                                    end
                                elseif (not GoubayuHeal.OnlyInstantActive() or castTime == 0) then
                                    -- 萨满链转波：治疗链目标周围无弹跳目标时改用等量治疗波/次级治疗波（省蓝）
                                    -- 滑块：0=不转，1=转治疗波，2=转次级治疗波
                                    local cnb = GoubayuHeal.Config
                                        and (GoubayuHeal.Config["shaman_chain_nobounce_wave"] or 0) or 0
                                    if finalSpell == GoubayuHeal.Chain_heal
                                        and GoubayuHeal.my_class == GoubayuHeal.Shaman
                                        and cnb > 0 then
                                        local _, hasBounce = GoubayuHeal.ChainHeal_SelectBestTarget(
                                            finalSpell, finalRank)
                                        if not hasBounce then
                                            local waveSpell = (cnb == 2)
                                                and GoubayuHeal.Lesser_healing_wave
                                                or GoubayuHeal.Healing_wave
                                            local waveRank = GoubayuHeal.FindEquivalentWaveRank(
                                                finalSpell, finalRank, waveSpell)
                                            if waveRank then
                                                if GoubayuHeal.Heal(unit, waveSpell,
                                                    waveRank, targetHealValue,
                                                    (noscale or forceMaxForCast), forceMaxForCast) then
                                                    GoubayuHeal.only_instant_spells = nil
                                                    return 1
                                                end
                                            end
                                        end
                                    end

                                    -- 迅捷治愈：已在 curspell 命中时统一处理（见上方），此处不再重复

                                    -- 方案档神圣打击：需满足本档群疗条件且可近战攻击目标，才施放；
                                    -- 不满足则落到下一档（其他治疗技能）
                                    -- by 武藤纯子酱 2026.9.6
                                    if finalSpell == GoubayuHeal.Holy_Strike then
                                        local hsAoeX = GoubayuHeal.Paladin_HSAoeParams()
                                        local hsPctFrac = tonumber(curpercent)
                                        if hsPctFrac then
                                            hsPctFrac = hsPctFrac / 100
                                        end
                                        local canHS = GoubayuHeal.my_class == GoubayuHeal.Paladin
                                            and UnitExists("target")
                                            and UnitCanAttack("player", "target")
                                            and GoubayuHeal.Paladin_CheckMeleeRange
                                            and GoubayuHeal.Paladin_CheckMeleeRange("target")
                                            and not GoubayuHeal.Paladin_IsCasting()
                                            and not GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Holy_Strike)
                                            and GoubayuHeal.Paladin_HolyStrikeAoECount(hsPctFrac) >= hsAoeX.count
                                        if canHS then
                                            local gHS2 = GoubayuHeal.Paladin_GetUnitID
                                                and GoubayuHeal.Paladin_GetUnitID("target")
                                            GoubayuHeal.Paladin_CastSpellOnTarget(GoubayuHeal.Holy_Strike, gHS2)
                                            GoubayuHeal.only_instant_spells = nil
                                            return 1
                                        end
                                    end

                                    if GoubayuHeal.Heal(unit, finalSpell, finalRank,
                                        targetHealValue, (noscale or forceMaxForCast),
                                        forceMaxForCast) then
                                        GoubayuHeal.only_instant_spells = nil
                                        return 1
                                    elseif finalSpell ~= curspell then
                                        if GoubayuHeal.Heal(unit, curspell, rank,
                                            targetHealValue, (noscale or forceMaxForCast),
                                            forceMaxForCast) then
                                            GoubayuHeal.only_instant_spells = nil
                                            return 1
                                        end
                                    end
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

-- ============================================================
-- 一键治疗主入口
-- ============================================================

-- 坦克模式治疗：从方案临时生成 _Tank 配置（排除祷言/新星），治疗坦克与自己后立即清理
-- 避免 _Tank 残留于 Config["classes"] 并被 SavedVariables 持久化
function GoubayuHeal.TankHealProfile(spell)
    if not (GoubayuHeal.Tank and GoubayuHeal.Tank["Name"]) then
        return nil
    end
    if not (GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][spell]) then
        return nil
    end

    local tankUnit = GoubayuHeal.Tank["Unit"]
    local tankValid = false

    if (GoubayuHeal.Tank["Name"] ~= GoubayuHeal.UnitName(tankUnit)) then
        local aka = GoubayuHeal.GetUnitID(GoubayuHeal.Tank["Name"])
        if (aka) then
            GoubayuHeal.Tank["Unit"] = aka
            tankUnit = aka
            tankValid = true
        else
            GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankNotInGroup, GoubayuHeal.Tank["Name"]))
            GoubayuHeal.Tank = {
                ["Name"] = nil,
                ["Unit"] = nil
            }
        end
    else
        tankValid = true
    end

    if not tankValid then
        return nil
    end

    local tankProfileName = spell .. "_Tank"
    GoubayuHeal.Config["classes"][tankProfileName] = {}

    for curpercent, data in GoubayuHeal.Config["classes"][spell] do
        if data["Spell"] ~= GoubayuHeal.Holy_nova
            and data["Spell"] ~= GoubayuHeal.Prayer_of_healing then
            GoubayuHeal.Config["classes"][tankProfileName][curpercent] = {
                ["Scale"] = data["Scale"],
                ["Spell"] = data["Spell"],
                ["Rank"] = data["Rank"],
                ["Attachment"] = data["Attachment"],
                ["AttachmentRank"] = data["AttachmentRank"],
                ["Alternate"] = data["Alternate"]
            }
        end
    end

    local myHealth, myMaxHealth = GoubayuHeal.GetUnitHealth("player")
    local myPercent = (myHealth / myMaxHealth) * 100

    local tankHealth, tankMaxHealth = GoubayuHeal.GetUnitHealth(tankUnit)
    local tankPercent = (tankHealth / tankMaxHealth) * 100

    -- tankheal 模式：HealUsingClass 内跳过团刷附件（仅单体）
    local savedTankMode = GoubayuHeal.tankheal_mode
    GoubayuHeal.tankheal_mode = true

    local result
    if myPercent < tankPercent then
        result = GoubayuHeal.HealUsingClass("player", tankProfileName)
        if result ~= 1 then
            result = GoubayuHeal.HealUsingClass(tankUnit, tankProfileName)
        end
    else
        result = GoubayuHeal.HealUsingClass(tankUnit, tankProfileName)
        if result ~= 1 then
            result = GoubayuHeal.HealUsingClass("player", tankProfileName)
        end
    end

    GoubayuHeal.tankheal_mode = savedTankMode

    -- 用完即删，避免 _Tank 残留并被 SavedVariables 持久化
    GoubayuHeal.Config["classes"][tankProfileName] = nil

    return result
end

function GoubayuHeal.ActionHeal(spell, rank, isUserAction)
    -- 死亡/灵魂状态（救赎之魂除外）：直接返回，不做任何计算
    -- by 武藤纯子酱 2026.10.23
    if GoubayuHeal.PlayerDeadBlocked() then
        return
    end
    -- 每次动作开始清"全局中止"：上一次施法被沉默等中止后，本次重新评估
    -- by 武藤纯子酱 2026.10.19
    GoubayuHeal._abortAction = nil

    if GoubayuHeal.PlayerIsCCd() == true then
        return
    end

    -- 脱战后回收图腾（主动按键路径）：/gbyh <方案> 按下时，若已脱战且开关要求回收、
    -- 且自己仍有图腾存活 → 先召回（用户主动施法上下文，不会被自动拦截），本次动作到此结束
    -- by 武藤纯子酱 2026.9.24
    if GoubayuHeal.Totem_TryRecallAfterCombat and GoubayuHeal.Totem_TryRecallAfterCombat() then
        return 1
    end

    if GoubayuHeal.TryDesperatePrayer then
        if GoubayuHeal.TryDesperatePrayer() then
            return 1
        end
    end

    -- 圣骑士自救：圣盾术/圣佑术（血量低于各自滑块阈值时断条施放，需判断CD与自律debuff）
    if GoubayuHeal.my_class == GoubayuHeal.Paladin then
        if GoubayuHeal.TryDivineShield then
            if GoubayuHeal.TryDivineShield() then
                return 1
            end
        end
        if GoubayuHeal.TryDivineProtection then
            if GoubayuHeal.TryDivineProtection() then
                return 1
            end
        end
    end

    if not (GetNampowerVersion and GetCastInfo) then
        if GoubayuHeal.IsCasting() then
            return
        end
    end

    -- EnsureInnerFire/EnsureWaterShield 内部自带 casting_spell/GCD 预检（施放失败不进节流）
    if GoubayuHeal.EnsureInnerFire then
        GoubayuHeal.EnsureInnerFire()
    end

    if GoubayuHeal.EnsureTreeOfLife then
        GoubayuHeal.EnsureTreeOfLife()
    end

    if GoubayuHeal.my_class == GoubayuHeal.Shaman and GoubayuHeal.Config
        and GoubayuHeal.Config["shaman_totem"]
        and GoubayuHeal.Config["shaman_totem"].onekey == 1
        and (not GoubayuHeal.Totem_GroupInCombat or GoubayuHeal.Totem_GroupInCombat()) then
        if GoubayuHeal.Totem_PlaceAll then
            GoubayuHeal.Totem_PlaceAll()
        end
    end

    GoubayuHeal.EnsureWaterShield()

    -- 防护恐惧结界维持（牧师，按团队框架右侧优先级）：成功施放则本次动作结束
    -- by 武藤纯子酱 2026.9.21
    if GoubayuHeal.MaintainFearWard and GoubayuHeal.MaintainFearWard() then
        return 1
    end

    if GoubayuHeal.my_class == GoubayuHeal.Paladin then
        if GoubayuHeal.Config and GoubayuHeal.Config["paladin_melee_heal"] == 1 then
            local meleeProfile = (type(spell) == "string" and GoubayuHeal.Config["classes"]
                and GoubayuHeal.Config["classes"][spell]) and spell or GoubayuHeal.current_class
            if GoubayuHeal.Paladin_MeleeHeal(meleeProfile) then
                return 1
            end
            -- 无近战条件：回退原始治疗方案（继续向下执行）
        end
    end

    if GoubayuHeal.Config and GoubayuHeal.Config["dispel_queue"] == 1
        and GoubayuHeal.Dispel_Priority then
        if GoubayuHeal.Dispel_Priority() then
            return 1
        end
    end

    if GoubayuHeal.Config and GoubayuHeal.Config["raid_hots_enabled"] == 1
        and GoubayuHeal.HotMaintenancePriority then
        if GoubayuHeal.HotMaintenancePriority() then
            return 1
        end
    end

    local selfcasting = GetCVar("autoSelfCast")

    if (spell and not rank and GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][spell]) then
        local useProfile = spell

        -- 方案切换：清除跨方案残留的施法状态（last_interrupted_spell/last_cast_spell）
        -- 避免上一个方案的被打断技能/交替记录污染当前方案（技能串、等级错乱）
        if GoubayuHeal.current_action_profile ~= spell then
            GoubayuHeal.current_action_profile = spell
            -- 切换方案前先回滚上一次施法的残留（含 hot_cast_cd），避免旧目标被锁
            -- by 武藤纯子酱 2026.10.22
            if GoubayuHeal.RollbackLastAttempt then
                GoubayuHeal.RollbackLastAttempt()
            end
            GoubayuHeal.last_interrupted_spell = nil
            GoubayuHeal.last_cast_spell = nil
            GoubayuHeal.i_am_healing = nil
            GoubayuHeal.only_instant_spells = nil
        end

        -- 方案含新增祷言（牧师智能团刷）保留 Unified 评分；否则统一按方案百分比档位施放
        -- 坦克优先级由 GetPriority（raid_roles 中 MT/8T）天然处理；纯坦克模式用 /gbyh tankheal [方案]
        local hasAoE = false
        for _, data in pairs(GoubayuHeal.Config["classes"][useProfile]) do
            if type(data) == "table" then
                if data["Spell"] == GoubayuHeal.Holy_nova
                    or data["Spell"] == GoubayuHeal.Prayer_of_healing
                    or data["Spell"] == GoubayuHeal.Chain_heal
                    or data["Spell"] == GoubayuHeal.Tranquility
                    or data["Attachment"] == GoubayuHeal.Holy_nova
                    or data["Attachment"] == GoubayuHeal.Prayer_of_healing
                    or data["Attachment"] == GoubayuHeal.Chain_heal
                    or data["Attachment"] == GoubayuHeal.Tranquility then
                    hasAoE = true
                    break
                end
            end
        end
        local res
        if hasAoE then
            res = GoubayuHeal.HealMostWoundedUnified(useProfile)
        else
            res = GoubayuHeal.HealMostWoundedTB(useProfile, rank)
        end
        -- 正常治疗未触发（目标都在最高档阈值之上）→ 预读 by 武藤纯子酱 2026.10.13
        if not res and GoubayuHeal.Config and GoubayuHeal.Config["predict_enabled"] == 1
            and GoubayuHeal.Predict_TryPreHeal then
            if GoubayuHeal.Predict_TryPreHeal(useProfile) then
                return 1
            end
        end
        return res
    end

    if (not spell or not rank or not GoubayuHeal.Spells[spell]
        or not GoubayuHeal.Spells[spell][rank]) then
        if spell == GoubayuHeal.Renew or spell == GoubayuHeal.Rejuvenation then
            local targetUnit = nil
            if (UnitExists("target")) then
                targetUnit = "target"
            else
                targetUnit = "player"
            end

            local hotRank = rank
            if not hotRank and GoubayuHeal.Spells and GoubayuHeal.Spells[spell] then
                hotRank = GoubayuHeal_GetHighestRankStr(spell)
            end

            local result = GoubayuHeal.Heal(targetUnit, spell, hotRank)
            return result
        end
        return 1
    end

    if (GoubayuHeal.casting_spell) then
        local healingtarget = GoubayuHeal.i_am_healing
        local isFirstRank = false

        if (healingtarget and GoubayuHeal.healing[healingtarget]
            and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]
            and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Rank"] == 1) then
            local spell = GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Spell"]
            if spell == GoubayuHeal.Flash_heal or spell == GoubayuHeal.Healing_touch
                or spell == GoubayuHeal.Regrowth or spell == GoubayuHeal.Flash_of_light
                or spell == GoubayuHeal.Lesser_healing_wave or spell == GoubayuHeal.Chain_heal
                or spell == GoubayuHeal.PriestHeal or spell == GoubayuHeal.Lesser_heal then
                isFirstRank = true
            end
        end

        local unit = GoubayuHeal.GetUnitID(healingtarget)
        local isFullHealth = false
        local _gh, _gmh = GoubayuHeal.GetUnitHealth(unit)
        if (unit and _gh == _gmh) then
            isFullHealth = true
        end

        if (GoubayuHeal.Config["safe_cancel"] == 1) then
            if (isFirstRank and GoubayuHeal.Config["allow_first_rank_ignore_overheal"] == 1) then
                if (isFullHealth) then
                    SpellStopCasting()
                end
            else
                if (GoubayuHeal.GetOverheal() > GoubayuHeal.Config["max_overheal"]) then
                    SpellStopCasting()
                end
            end
        end
        return 1
    end

    local unit = nil
    local healvalue = nil

    if (GoubayuHeal.Tank and GoubayuHeal.Tank["Name"]) then
        unit = GoubayuHeal.Tank["Unit"]
        if (GoubayuHeal.Tank["Name"] ~= GoubayuHeal.UnitName(GoubayuHeal.Tank["Unit"])) then
            -- 用名字反查单位 token（UnitName 对玩家名恒返回 nil，此前恒失败导致坦克治疗静默失效）
            local aka = GoubayuHeal.GetUnitID(GoubayuHeal.Tank["Name"])
            if (aka) then
                GoubayuHeal.Tank["Unit"] = aka
                unit = aka
            else
                GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankNotInGroup2, GoubayuHeal.Tank["Name"]))
                GoubayuHeal.Tank = {
                    ["Name"] = nil,
                    ["Unit"] = nil
                }
                unit = nil
            end
        end
    end

    if not unit and ((UnitExists("target") and UnitIsUnit("target", "player"))
        or GoubayuHeal.IsHealModifierKeyDown("heal_self_modifier")) then
        unit = "player"
    end

    if not unit and UnitExists("target") then
        if (UnitIsEnemy("player", "target") and UnitExists("targettarget")
            and GoubayuHeal.CanHeal("targettarget")) then
            unit = GoubayuHeal.AKA("targettarget")
        elseif (UnitIsFriend("player", "target")) then
            unit = GoubayuHeal.AKA("target")
        end

        if (GoubayuHeal.IsHealModifierKeyDown("heal_targettarget_modifier")
            and UnitExists("targettarget") and GoubayuHeal.CanHeal("targettarget")) then
            unit = GoubayuHeal.AKA("targettarget")
        end
    end

    if not unit and GoubayuHeal.enemy_with_friendtarget() and UnitExists("targettarget")
        and GoubayuHeal.CanHeal("targettarget") then
        unit = GoubayuHeal.AKA("targettarget")
    end

    if not unit then
        GoubayuHeal.HealMostWounded(spell, rank)
        return 1
    end

    if (not rank) then
        if (GoubayuHeal.IsHealModifierKeyDown("heal_max_modifier")
            or GoubayuHeal.Config["always_tank_target"] == 1) then
            GoubayuHeal.HealUsingClass(unit, spell, nil)
        else
            healvalue = GoubayuHeal.GetHealValue(unit)
            GoubayuHeal.HealUsingClass(unit, spell, healvalue)
        end
    else
        if (GoubayuHeal.IsHealModifierKeyDown("heal_max_modifier")
            or GoubayuHeal.Config["always_tank_target"] == 1) then
            local maxRank = rank
            if GoubayuHeal.Spells and GoubayuHeal.Spells[spell] then
                maxRank = table.getn(GoubayuHeal.Spells[spell])
            end
            GoubayuHeal.Heal(unit, spell, maxRank, nil, true, true)
        else
            healvalue = GoubayuHeal.GetHealValue(unit)
            local scaledRank = GoubayuHeal.ScaleSpell(unit, spell, rank, healvalue)
            GoubayuHeal.Heal(unit, spell, scaledRank, healvalue)
        end
    end

    return 1
end

-- ============================================================
-- 检查敌对目标及其目标
-- ============================================================

function GoubayuHeal.enemy_with_friendtarget()
    if UnitExists("target") and UnitIsEnemy("player", "target") then
        if UnitExists("targettarget") then
            return UnitIsFriend("player", "targettarget")
        end
    end
    return nil
end

-- ============================================================
-- 插件加载初始化
-- ============================================================

function GoubayuHeal.OnLoad()
    GoubayuHeal.healing = {}
    GoubayuHeal.item_heal_bonus_cache = {}

    GoubayuHeal.last_update = 0
    GoubayuHeal.MPPlayerIsMoving = false
    GoubayuHeal.prevX, GoubayuHeal.prevY = 0, 0

    GoubayuHeal.my_class = UnitClass("player")
    GoubayuHeal.my_name = GoubayuHeal.UnitName("player")

    this:RegisterEvent("PLAYER_LOGIN")
    this:RegisterEvent("VARIABLES_LOADED")

    SLASH_GoubayuHeal1 = "/gbyh"
    SLASH_GoubayuHeal2 = "/gbyheal"
    SlashCmdList["GoubayuHeal"] = function(msg)
        GoubayuHeal.Command(msg)
    end
end

-- ============================================================
-- 主事件处理器
-- ============================================================

-- 法术书签名：槽位数 + 逐名滚动哈希（不拼接整串，避免大字符串分配与每5秒抖动）
-- 变化检测只需"是否变了"，无需可逆；逐字节 33 进制滚动哈希碰撞概率可忽略
-- by 武藤纯子酱 2026.10.19
function GoubayuHeal.SpellBookSignature()
    local count = 0
    local h = 5381
    local j = 1
    while true do
        local s = GetSpellName(j, BOOKTYPE_SPELL)
        if not s then
            break
        end
        count = count + 1
        local n = string.len(s)
        for k = 1, n do
            -- Lua 5.0 无取模运算符 %：用乘法 + 单次减法归约（h 恒 < 2147483647，乘积仍在 double 精度内）
            h = h * 33 + string.byte(s, k)
            if h >= 2147483647 then
                h = h - 2147483647 * math.floor(h / 2147483647)
            end
        end
        j = j + 1
    end
    -- 乘子取 2^31（> 哈希上界 2147483647）：各 count 分段不重叠，count 与哈希互不干扰
    return count * 2147483648 + h
end

-- 签名是否变化：首次（未知）只记录基线不重扫；变化返回 true。
-- by 武藤纯子酱 2026.10.19
function GoubayuHeal.SpellBookChanged()
    local sig = GoubayuHeal.SpellBookSignature()
    if GoubayuHeal._book_sig == nil then
        GoubayuHeal._book_sig = sig
        return false
    end
    if sig ~= GoubayuHeal._book_sig then
        GoubayuHeal._book_sig = sig
        return true
    end
    return false
end

-- 法术书变化统一入口：签名未变化则直接跳过重扫（槽位缓存也不清，仅真变化时才需要）。
-- SPELLS_CHANGED（含"按 P 开书"触发的）/ LEARNED_SPELL_IN_TAB / CHARACTER_POINTS_CHANGED 共用。
-- by 武藤纯子酱 2026.10.19
function GoubayuHeal.HandleSpellBookEvent()
    if GoubayuHeal.SpellBookChanged() then
        GoubayuHeal_SpellSlotCache = {}
        GoubayuHeal._inner_fire_slot = nil
        GoubayuHeal.TreeFormIndex = nil
        -- 法术库变化：清 (技能,id)→等级缓存，避免沿用旧等级表的结果
        -- by 武藤纯子酱 2026.10.21
        GoubayuHeal._aura_rank_cache = nil
        GoubayuHeal._fw_spellid_cache = nil
        GoubayuHeal.SafeUpdateSpells()
    end
end

-- 安全重扫：原子替换（先建新表；报错或重建成空表则回滚旧表）+ 施法中延后 + 失败持续重试
-- 背景：UpdateSpells 会先清空 GoubayuHeal.Spells 再重建，中途报错会留下半残表，
-- 导致 Heal() 直接 return（表现"按宏不加血"），只能 /reload 恢复。
-- by 武藤纯子酱 2026.10.22
function GoubayuHeal.SafeUpdateSpells(force)
    -- 施法中不重扫（解析 tooltip 又慢又容易失败），等空闲再做
    if (not force) and GoubayuHeal.casting_spell then
        GoubayuHeal._book_rescan_pending = true
        return
    end
    -- 1秒内刚完成过完整扫描时跳过重复扫描（登录瞬间多事件连发的去重）
    if (not force) and (not GoubayuHeal._spell_parse_incomplete) and GoubayuHeal._spell_parse_last
        and (GetTime() - GoubayuHeal._spell_parse_last) < 1 then
        return
    end

    local backup = GoubayuHeal.Spells
    local backupSet = GoubayuHeal._spell_id_set_cache
    local ok = pcall(GoubayuHeal.UpdateSpells)
    GoubayuHeal._spell_parse_last = GetTime()
    GoubayuHeal._book_rescan_pending = nil

    local usable = ok and GoubayuHeal.Spells and next(GoubayuHeal.Spells) ~= nil
    if (not ok) or (not usable and backup and next(backup) ~= nil) then
        -- 报错，或重建成空表（法术书未就绪）→ 回滚旧库，稍后重试
        GoubayuHeal.Spells = backup
        GoubayuHeal._spell_id_set_cache = backupSet
        GoubayuHeal._spell_parse_incomplete = true
        GoubayuHeal._spell_parse_error = (not ok) or nil
        GoubayuHeal._spell_parse_tries = (GoubayuHeal._spell_parse_tries or 0) + 1
        GoubayuHeal._spell_parse_retry_next = GetTime() + 10
        if (not (backup and next(backup))) and not GoubayuHeal._spells_missing_warned then
            GoubayuHeal._spells_missing_warned = true
            GoubayuHeal.Print("法术库重建失败，正在自动重试（长时间无效请 /reload）")
        end
        return
    end

    GoubayuHeal._spell_parse_error = nil
    if GoubayuHeal._spell_parse_incomplete then
        -- 成功但数值缺失：累计次数供"暖法术书"触发（>=2 次才试一次）
        GoubayuHeal._spell_parse_tries = (GoubayuHeal._spell_parse_tries or 0) + 1
        -- 重扫成功但个别技能数值解析不出：缺失数连续两轮不变就停止重试（避免每 4 秒重扫卡顿）
        local missingNow = GoubayuHeal._spell_parse_missing or 0
        if missingNow > 0 and missingNow == (GoubayuHeal._spell_parse_missing_prev or -1) then
            GoubayuHeal._spell_parse_retry_next = nil
        else
            GoubayuHeal._spell_parse_retry_next = GetTime() + 4
        end
        GoubayuHeal._spell_parse_missing_prev = missingNow
    else
        GoubayuHeal._spell_parse_tries = 0
        GoubayuHeal._spell_parse_retry_next = nil
        GoubayuHeal._spell_parse_missing_prev = 0
    end
end

function GoubayuHeal.OnEvent()
    if (event == "LEARNED_SPELL_IN_TAB") then
        -- 学新法术：槽位号整体移位；经统一入口判定签名是否真变再重扫
        GoubayuHeal.HandleSpellBookEvent()

    elseif (event == "CHARACTER_POINTS_CHANGED") then
        GoubayuHeal_ClearTalentCache()
        GoubayuHeal.HandleSpellBookEvent()

    elseif (event == "SPELLS_CHANGED") then
        -- 法术书变动（"按 P 开书"也会发此事件）：走签名单入口，
        -- 签名未变化则不再整库重扫（修复开书卡 0.7 秒） by 武藤纯子酱 2026.10.19
        GoubayuHeal.HandleSpellBookEvent()

    elseif (event == "PLAYER_ENTERING_WORLD") then
        GoubayuHeal.player_in_combat = nil
        GoubayuHeal.casting_spell = nil
        if GoubayuHeal.BuildUnitMap then
            GoubayuHeal.BuildUnitMap()
        end
        if GoubayuHeal.Dispel_OnRosterChange then
            GoubayuHeal.Dispel_OnRosterChange()
        end

    elseif (event == "PLAYER_LOGIN") then
        -- 重取兜底：加载期 UnitName 可能尚未同步（空串），登录后补取最新值
        GoubayuHeal.my_class = UnitClass("player")
        GoubayuHeal.my_name = GoubayuHeal.UnitName("player")
        -- 首次登录法术书可能延迟就绪：失败/不完整时由 SafeUpdateSpells 自动安排补扫
        GoubayuHeal.SafeUpdateSpells()
        -- 记录法术书基线签名：避免登录后首个 SPELLS_CHANGED/轮询再触发一次全扫
        -- by 武藤纯子酱 2026.10.19
        GoubayuHeal._book_sig = GoubayuHeal.SpellBookSignature()
        this:RegisterEvent("SPELLS_CHANGED")
        GoubayuHeal.SetupSettings()

        if (not GoubayuHeal.supported_classes[GoubayuHeal.my_class]) then
            GoubayuHeal.OnUpdate = function(elapsed)
                if GoubayuHeal.UpdateHealing then
                    GoubayuHeal.UpdateHealing(elapsed)
                end
            end
            return
        else
            Sea.util.hook("CastSpellByName", "GoubayuHeal.CastSpellByName", "before")
            Sea.util.hook("CastSpell", "GoubayuHeal.CastSpell", "before")
            Sea.util.hook("SpellStopCasting", "GoubayuHeal.SpellStopCasting", "before")
            Sea.util.hook("SpellStopTargeting", "GoubayuHeal.SpellStopTargeting", "before")

            this:RegisterEvent("LEARNED_SPELL_IN_TAB")
            this:RegisterEvent("CHARACTER_POINTS_CHANGED")
            this:RegisterEvent("PLAYER_ENTERING_WORLD")
            this:RegisterEvent("PLAYER_LEAVING_WORLD")
            this:RegisterEvent("PLAYER_REGEN_DISABLED")
            this:RegisterEvent("PLAYER_REGEN_ENABLED")
            this:RegisterEvent("RAID_ROSTER_UPDATE")
            this:RegisterEvent("PARTY_MEMBERS_CHANGED")
            this:RegisterEvent("SPELLCAST_DELAYED")
            this:RegisterEvent("SPELLCAST_FAILED")
            this:RegisterEvent("SPELLCAST_INTERRUPTED")
            this:RegisterEvent("SPELLCAST_START")
            this:RegisterEvent("SPELLCAST_STOP")
            this:RegisterEvent("UI_ERROR_MESSAGE")
            this:RegisterEvent("UNIT_INVENTORY_CHANGED")
            this:RegisterEvent("SPELL_FAILED_SELF")
            this:RegisterEvent("SPELL_GO_SELF")

            if GetNampowerVersion and SetCVar then
                pcall(SetCVar, "NP_EnableSpellGoEvents", 1)
            end
        end

    elseif (event == "PLAYER_REGEN_DISABLED") then
        GoubayuHeal.player_in_combat = 1

    elseif (event == "PLAYER_REGEN_ENABLED") then
        GoubayuHeal.player_in_combat = nil

    elseif (event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED") then
        if GoubayuHeal.BuildUnitMap then
            GoubayuHeal.BuildUnitMap()
        end
        GoubayuHeal.SetRaidChecked()
        if GoubayuHeal.SetHotMaintain then
            GoubayuHeal.SetHotMaintain()
        end
        if GoubayuHeal.Dispel_PrioRefresh then
            GoubayuHeal.Dispel_PrioRefresh()
        end
        if GoubayuHeal.Dispel_OnRosterChange then
            GoubayuHeal.Dispel_OnRosterChange()
        end

    elseif (event == "SPELLCAST_DELAYED" and GoubayuHeal.i_am_healing and arg1) then
        local healingtarget = GoubayuHeal.i_am_healing
        if (not GoubayuHeal.healing[healingtarget]
            or not GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]
            or GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Complete"]) then
            return
        end
        GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["TimeLeft"] =
            GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["TimeLeft"] + arg1 / 1000

    elseif (event == "SPELL_FAILED_SELF") then
        -- Nampower 精确中断：arg1=spellId，直接反查被中断/失败的法术名写入待重试，比上次施放法术更可靠
        local failedSpell = nil
        if arg1 and GetNampowerVersion and GetSpellNameAndRankForId then
            local ok, nm = pcall(GetSpellNameAndRankForId, arg1)
            if ok and nm then
                failedSpell = string.gsub(nm, "%s*%(.*%)", "")
            end
        end
        if failedSpell then
            GoubayuHeal.last_interrupted_spell = failedSpell
        elseif GoubayuHeal.last_cast_spell then
            GoubayuHeal.last_interrupted_spell = GoubayuHeal.last_cast_spell
        end
        GoubayuHeal.last_cast_spell = nil

    elseif (event == "SPELL_GO_SELF") then
        GoubayuHeal.last_interrupted_spell = nil
        GoubayuHeal.casting_spell = nil
        GoubayuHeal.casting_spell_time = nil

    elseif (event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED"
        or event == "SPELLCAST_STOP") then
        local wascasting = GoubayuHeal.casting_spell
        GoubayuHeal.casting_spell = nil
        GoubayuHeal.casting_spell_time = nil

        -- 被打断/失败：按 _lastAttempt（spell+name）回滚，清 hot_cast_cd 与在途记录。
        -- 这里不受"0.5 秒同步回滚窗口"限制（长读条被打断时已远超 0.5 秒），
        -- 也不依赖 i_am_healing 是否还指向该目标（切方案/被清时同样能解锁）。
        -- by 武藤纯子酱 2026.10.22
        if (event ~= "SPELLCAST_STOP") and GoubayuHeal._lastAttempt then
            local _a = GoubayuHeal._lastAttempt
            GoubayuHeal._lastAttempt = nil
            if GoubayuHeal.RollbackCastAttempt then
                GoubayuHeal.RollbackCastAttempt(_a.spell, _a.name)
            end
            if GoubayuHeal.last_cast_spell == _a.spell then
                GoubayuHeal.last_cast_spell = nil
            end
        end

        if (event == "SPELLCAST_STOP") and GoubayuHeal.supported_classes
            and GoubayuHeal.supported_classes[GoubayuHeal.my_class] then
            GoubayuHeal.gcd_start = GetTime()
            GoubayuHeal.gcd_duration = GoubayuHeal.GetGCDDuration()
            -- 施放正常结束：清掉本次尝试标记，避免之后别的技能失败时误回滚
            -- by 武藤纯子酱 2026.10.22
            GoubayuHeal._lastAttempt = nil
        end

        if (not (GetNampowerVersion and GetUnitField))
            and (event == "SPELLCAST_INTERRUPTED" or event == "SPELLCAST_FAILED") then
            -- 无Nampower：用原生事件猜测被中断技能写入待重试
            -- （有Nampower时由 SPELL_FAILED_SELF 精确处理，禁用此分支避免覆盖）
            if GoubayuHeal.last_cast_spell then
                GoubayuHeal.last_interrupted_spell = GoubayuHeal.last_cast_spell
            end
            GoubayuHeal.last_cast_spell = nil
        end

        local healingtarget = GoubayuHeal.i_am_healing
        if (not healingtarget or not GoubayuHeal.healing[healingtarget]
            or not GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]) then
            return
        end

        -- 施法失败/被打断：回滚刚写入的 HOT 内置冷却。该冷却是在施放调用之后立即写入的（无法同步
        -- 得知成败），失败也照样写；不回滚会把同一目标锁住整个 HOT 时长，表现为"十几秒内不再治疗"
        -- by 武藤纯子酱 2026.9.21
        if (event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED") then
            local rec = GoubayuHeal.healing[healingtarget]
                and GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]
            local sp = rec and rec["Spell"]
            if (sp and GoubayuHeal.hot_cast_cd and GoubayuHeal.hot_cast_cd[sp]) then
                GoubayuHeal.hot_cast_cd[sp][healingtarget] = nil
            end
        end

        if (event == "SPELLCAST_FAILED") then
            GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Status"] = "Failed"
            if ((GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)])) then
                GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)]["status"] = "int"
            end
        elseif (event == "SPELLCAST_INTERRUPTED") then
            if ((GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)])) then
                GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)]["status"] = "int"
            end
            GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Status"] = "Interrupted"
        elseif (not wascasting) then
            return
        elseif (event == "SPELLCAST_STOP") then
            if ((GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)])
                and (GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)]["status"] == "start")) then
                GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)]["cast"] = 0.5
                GoubayuHeal.awaiting_rez[GoubayuHeal.GetUnitID(healingtarget)]["status"] = "stop"
            end
            GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Status"] = "Stop"
        end

        GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Complete"] = 1

    elseif (event == "SPELLCAST_START" and arg2) then
        GoubayuHeal.casting_spell = 1
        GoubayuHeal.casting_spell_time = GetTime()

        if GoubayuHeal.OnRezCastStart then
            GoubayuHeal.OnRezCastStart(arg1, arg3)
        end

        local healingtarget = GoubayuHeal.i_am_healing

        if GoubayuHeal.spell_awaiting_target_Spell then
            if GoubayuHeal.spell_awaiting_target_Target then
                SpellTargetUnit(GoubayuHeal.spell_awaiting_target_Target, false)
            elseif UnitExists("target") then
                SpellTargetUnit("target", false)
            elseif UnitExists("mouseover") then
                SpellTargetUnit("mouseover", false)
            end
            -- 消费后一律清理：原逻辑仅"无目标可选"分支清理，读条正常完成后状态残留，
            -- 会使其后任意施法（用户宏/法术书光标选目标等）被重定向到旧目标
            -- by 武藤纯子酱 2026.9.4
            GoubayuHeal.clean_spell_awaiting_target()
        end

        if (not healingtarget or not GoubayuHeal.healing[healingtarget]
            or not GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]
            or GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["Complete"]) then
            return
        end

        local castTimeSec = arg2 / 1000

        if (castTimeSec == GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["CastTime"]) then
            return
        end

        GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["TimeLeft"] =
            GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["TimeLeft"] + castTimeSec
            - GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["CastTime"]
        GoubayuHeal.healing[healingtarget][GoubayuHeal.my_name]["CastTime"] = castTimeSec

    elseif (event == "UI_ERROR_MESSAGE") then
        GoubayuHeal.error_message = arg1
        -- 事件兜底：本次施放尝试在极短时间内被拒（同步路径读不到错误时），回滚其副作用
        -- by 武藤纯子酱 2026.10.19
        if GoubayuHeal._lastAttempt and GoubayuHeal.IsRejectionError(arg1) then
            GoubayuHeal.RollbackLastAttempt()
        end

    elseif (event == "UNIT_INVENTORY_CHANGED" and arg1 and arg1 == "player") then
        GoubayuHeal.UpdateItemHealBonus()
        -- 预热：登录/换装时提前做一次20槽治疗强度扫描（此时客户端加载物品数据冷启动最慢）。
        -- 之后治疗决策中的扫描因客户端已缓存物品数据而变快，消除"进游戏首次加血前/两次加血间
        -- 卡1到几秒"的问题（首次扫描提前到登录时刻，不占用治疗时序）
        GoubayuHeal.GetSelfHealPower()

    elseif (event == "VARIABLES_LOADED") then
        GoubayuHeal.SafeUpdateSpells()

        if GoubayuHeal_DataBackup and type(GoubayuHeal_DataBackup) == "table"
            and next(GoubayuHeal_DataBackup) ~= nil
            and (not GoubayuHeal_Data or next(GoubayuHeal_Data) == nil) then
            GoubayuHeal_Data = GoubayuHeal_DataBackup
        end

        GoubayuHeal.SetupSettings()

        if GoubayuHeal_Data and type(GoubayuHeal_Data) == "table" then
            GoubayuHeal_DataBackup = GoubayuHeal.CopyTable(GoubayuHeal_Data)
        end

        if GoubayuHeal.Dispel_ApplyEnabled then
            GoubayuHeal.Dispel_ApplyEnabled()
        end
    end
end

-- ============================================================
-- Nampower buff/debuff事件跟踪：buff栏满时不重复施放心灵之火/水盾的判定依据
--   BUFF_ADDED_SELF   → 有新buff加入（若此时buff栏满，施放心灵之火会无效 → 不再施放）
--   BUFF_REMOVED_SELF → 有buff被移除（空出槽位 → 可重新施放）
-- ============================================================
if GetNampowerVersion then
    local auraFrame = CreateFrame("Frame")
    pcall(auraFrame.RegisterEvent, auraFrame, "BUFF_ADDED_SELF",
        function(guid, luaSlot, spellId, stacks, auraLevel, auraSlot, state)
            GoubayuHeal._buff_add_time = GetTime()
        end)
    pcall(auraFrame.RegisterEvent, auraFrame, "BUFF_REMOVED_SELF",
        function(guid, luaSlot, spellId, stacks, auraLevel, auraSlot, state)
            GoubayuHeal._buff_remove_time = GetTime()
            -- 自己的回春/愈合消失 → 即时清 HOT 跟踪
            if state == 1 and GoubayuHeal.OnHotAuraRemoved then
                GoubayuHeal.OnHotAuraRemoved(guid, spellId)
            end
        end)
    -- 其他单位（含队友）的回春/愈合消失：手动取消 / BUFF 位被挤 / 被驱散 / 被迅捷治愈吃掉
    -- → 即时清除我们的 HOT 跟踪 by 武藤纯子酱 2026.10.19
    pcall(auraFrame.RegisterEvent, auraFrame, "BUFF_REMOVED_OTHER",
        function(guid, luaSlot, spellId, stacks, auraLevel, auraSlot, state)
            if state == 1 and GoubayuHeal.OnHotAuraRemoved then
                GoubayuHeal.OnHotAuraRemoved(guid, spellId)
            end
        end)
end

-- ============================================================
-- 每帧更新
-- ============================================================

function GoubayuHeal.OnUpdate(elapsed)
    -- 天赋切换/法术书变动检测：乌龟服切换天赋不触发 SPELLS_CHANGED/LEARNED_SPELL_IN_TAB，
    -- 法术库会滞留（学习/遗忘的技能不增不减）。定期比对法术书签名，变化时重建法术库并刷新UI。
    -- 签名改用"槽位数+逐名滚动哈希"（不再拼接整串，消除每5秒的大字符串分配抖动）
    -- by 武藤纯子酱 2026.10.19
    GoubayuHeal._book_sig_timer = (GoubayuHeal._book_sig_timer or 0) + (elapsed or 0)
    if GoubayuHeal._book_sig_timer >= 5 and not GoubayuHeal.casting_spell then
        GoubayuHeal._book_sig_timer = 0
        if GoubayuHeal.SpellBookChanged() then
            GoubayuHeal.SafeUpdateSpells()
            if UI and UI.RedrawLibrary then
                pcall(UI.RedrawLibrary)
            end
        end
    end

    -- 原版（无Nampower）回退：解析连续失败时"暖"一次法术书（显示后立即隐藏），
    -- 强制客户端构建法术书数据（冷启动会话tooltip可能因法术书未初始化而填充失败）
    -- by 武藤纯子酱 2026.10.22
    if GoubayuHeal._spell_parse_incomplete and (GoubayuHeal._spell_parse_tries or 0) >= 2
        and not GoubayuHeal._sb_warmup_done
        and SpellBookFrame and not SpellBookFrame:IsVisible() then
        GoubayuHeal._sb_warmup_done = true
        ShowUIPanel(SpellBookFrame)
        GoubayuHeal._sb_warmup_hide = GetTime() + 0.3
    end
    if GoubayuHeal._sb_warmup_hide and GetTime() >= GoubayuHeal._sb_warmup_hide then
        if SpellBookFrame and SpellBookFrame:IsVisible() then
            HideUIPanel(SpellBookFrame)
        end
        GoubayuHeal._sb_warmup_hide = nil
    end

    -- 法术库重扫：只在非施法状态执行（施法中挂起，等空闲）；报错回滚旧表并由
    -- SafeUpdateSpells 内部调度重试 by 武藤纯子酱 2026.10.22
    if (GoubayuHeal._book_rescan_pending or GoubayuHeal._spell_parse_retry_next)
        and (not GoubayuHeal.casting_spell)
        and GetTime() >= (GoubayuHeal._spell_parse_retry_next or 0) then
        GoubayuHeal.SafeUpdateSpells(true)
    end

    if GoubayuHeal.NampowerUpdate then
        GoubayuHeal.NampowerUpdate()
    end

    -- 施法标记看门狗：SPELLCAST_START后若STOP/FAILED事件丢失（如Nampower吞事件）会卡死施法标记）
    -- Nampower下先通过 GetCurrentCastingInfo 判定是否仍在读条/GCD，空闲即清除（比死等事件更可靠）；再以5秒超时兜底
    if GoubayuHeal.casting_spell then
        local stillBusy = false
        if GetNampowerVersion and GetCurrentCastingInfo then
            local _, _, _, isCasting, isChanneling = GetCurrentCastingInfo()
            if (isCasting == 1) or (isChanneling == 1) then
                stillBusy = true
            end
        end
        if not stillBusy then
            GoubayuHeal.casting_spell = nil
            GoubayuHeal.casting_spell_time = nil
        elseif GoubayuHeal.casting_spell_time and (GetTime() - GoubayuHeal.casting_spell_time) > 5 then
            -- 5秒兜底：即使GetCurrentCastingInfo仍报忙（异常/陈旧时间戳），超过最长读条缓冲也强制清除
            GoubayuHeal.casting_spell = nil
            GoubayuHeal.casting_spell_time = nil
        end
    end

    -- 状态看门狗（P5）：清理可能卡住的"只瞬发"标记与已消失目标的在途跟踪
    -- by 武藤纯子酱 2026.10.19
    if GoubayuHeal.only_instant_spells and GoubayuHeal.only_instant_spells_time
        and (GetTime() - GoubayuHeal.only_instant_spells_time) > 1.5 then
        GoubayuHeal.only_instant_spells = nil
        GoubayuHeal.only_instant_spells_time = nil
    end
    GoubayuHeal._wd_timer = (GoubayuHeal._wd_timer or 0) + (elapsed or 0)
    if GoubayuHeal._wd_timer >= 1 then
        GoubayuHeal._wd_timer = 0
        if GoubayuHeal.i_am_healing and GoubayuHeal.GetUnitID then
            local u = GoubayuHeal.GetUnitID(GoubayuHeal.i_am_healing)
            if not (u and UnitExists(u)) then
                GoubayuHeal.i_am_healing = nil
            end
        end
        -- HOT 记录与目标实际光环核对（被别人的迅捷治愈/驱散/提前到期消耗掉）
        if GoubayuHeal.ReconcileTrackedHOTs then
            pcall(GoubayuHeal.ReconcileTrackedHOTs)
        end
    end

    -- 移动检测（仅原版回退路径）：GetPlayerMapPosition 每帧调用无谓，节流到 0.1s
    -- （移动状态只用于阻止移动读条，0.1s 延迟无感知） by 武藤纯子酱 2026.9.4
    if not (GetNampowerVersion and PlayerIsMoving) then
        GoubayuHeal._map_move_timer = (GoubayuHeal._map_move_timer or 0) + elapsed
        if GoubayuHeal._map_move_timer >= 0.1 then
            GoubayuHeal._map_move_timer = 0
            local x, y = GetPlayerMapPosition("player")
            if x and y then
                if x ~= GoubayuHeal.prevX or y ~= GoubayuHeal.prevY then
                    GoubayuHeal.MPPlayerIsMoving = true
                else
                    GoubayuHeal.MPPlayerIsMoving = false
                end
                GoubayuHeal.prevX, GoubayuHeal.prevY = x, y
            else
                -- 无地图区域（副本内某些场景/大地图边界）返回nil：沿用上次移动状态，不误判为移动
                GoubayuHeal.MPPlayerIsMoving = false
            end
        end
    end

    GoubayuHeal.last_update = GoubayuHeal.last_update + elapsed
    if (GoubayuHeal.last_update > 0.1) then
        if GoubayuHeal.UpdateHealing then
            GoubayuHeal.UpdateHealing(GoubayuHeal.last_update)
        end
        GoubayuHeal.last_update = 0
    end

    -- 尸体扫描独立降频到 0.25s：UpdateDead 只服务复活列表（尸体出现延迟≤0.25s 无感知），
    -- waiting_time/cast 倒计时改用累计 elapsed 传入，精度不受降频影响
    -- by 武藤纯子酱 2026.9.4
    GoubayuHeal.dead_update_timer = (GoubayuHeal.dead_update_timer or 0) + elapsed
    if (GoubayuHeal.dead_update_timer > 0.25) then
        if GoubayuHeal.UpdateDead then
            GoubayuHeal.UpdateDead(GoubayuHeal.dead_update_timer)
        end
        GoubayuHeal.dead_update_timer = 0
    end

    GoubayuHeal.update_timer = (GoubayuHeal.update_timer or 0) + elapsed
    if (GoubayuHeal.update_timer > ((GoubayuHeal.Config
        and GoubayuHeal.Config["update_player_data_time"]) or 2.5)) then
        GoubayuHeal.UpdatePlayerData(GoubayuHeal.update_timer)
        GoubayuHeal.last_player_data_time = GetTime()
        GoubayuHeal.update_timer = 0
    end

    if GoubayuHeal.Config and GoubayuHeal.Config["scan_cache"] == 1
        and UnitAffectingCombat("player") and not GoubayuHeal.casting_spell then
        GoubayuHeal.scan_timer = (GoubayuHeal.scan_timer or 0) + elapsed
        if GoubayuHeal.scan_timer >= 0.2 then
            GoubayuHeal.scan_timer = 0
            GoubayuHeal.ScanWoundedData()
            GoubayuHeal.last_scan_time = GetTime()
        end
    else
        GoubayuHeal.scan_timer = 0
    end
end

-- ============================================================
-- 斜杠命令处理
-- ============================================================

function GoubayuHeal.Command(msg)
    if (not msg or msg == "") then
        if (GoubayuHeal_GUI:IsShown()) then
            GoubayuHeal_GUI:Hide()
        else
            GoubayuHeal_GUI:Show()
        end
        return
    end

    msg = string.lower(msg)

    if (string.find(msg, "^save")) then
        local start, stop, profile = string.find(msg, "^save (.+)$")
        if (not profile) then
            GoubayuHeal.Print(GoubayuHeal.Msg.SaveNeedName)
            return
        end
        GoubayuHeal.Save_Profile(profile)
        GoubayuHeal.Print(string.format(GoubayuHeal.Msg.SaveOK, profile))

    elseif (string.find(msg, "^load")) then
        local start, stop, profile = string.find(msg, "^load (.+)$")
        if (not profile) then
            GoubayuHeal.Print(GoubayuHeal.Msg.LoadNeedName)
            return
        end
        if (not GoubayuHeal.SavedProfiles[profile]) then
            GoubayuHeal.Print(string.format(GoubayuHeal.Msg.LoadNotFound, profile), "|cffff0000")
            return
        end
        GoubayuHeal.Load_Profile(profile)
        GoubayuHeal.Print(string.format(GoubayuHeal.Msg.LoadOK, profile))

    elseif (string.find(msg, "^delete")) then
        local start, stop, profile = string.find(msg, "^delete (.+)$")
        if (not profile) then
            GoubayuHeal.Print(GoubayuHeal.Msg.DeleteNeedName)
            return
        end
        if (not GoubayuHeal.SavedProfiles[profile]) then
            GoubayuHeal.Print(string.format(GoubayuHeal.Msg.DeleteNotFound, profile), "|cffff0000")
            return
        end
        GoubayuHeal.SavedProfiles[profile] = nil
        GoubayuHeal.Print(string.format(GoubayuHeal.Msg.DeleteOK, profile))
        GoubayuHeal_GUIProfileDropDownMenu:Hide()
        GoubayuHeal_GUIProfileDropDownMenu:Show()

    elseif (msg == "list") then
        GoubayuHeal.Print(GoubayuHeal.Msg.ListTitle)
        local found
        for profile, data in GoubayuHeal.SavedProfiles do
            GoubayuHeal.Print(profile)
            found = 1
        end
        if (not found) then
            GoubayuHeal.Print(GoubayuHeal.Msg.ListEmpty)
        end

    elseif (msg == "opt") then
        if GoubayuHeal_GUI:IsVisible() then
            GoubayuHeal_GUI:Hide()
        else
            GoubayuHeal_GUI:Show()
        end

    elseif (msg == "reset") then
        GoubayuHeal_GUI:ClearAllPoints()
        GoubayuHeal_GUI:SetPoint("CENTER", UIParent, "CENTER")
        GoubayuHeal.Print(GoubayuHeal.Msg.ResetWindow)

    elseif (msg == "totemreset") then
        if GoubayuHeal_TotemFrame then
            GoubayuHeal_TotemFrame:ClearAllPoints()
            GoubayuHeal_TotemFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            if GoubayuHeal.Totem_SaveFramePosition then
                GoubayuHeal.Totem_SaveFramePosition()
            end
            GoubayuHeal.Print(GoubayuHeal.Msg.TotemResetWindow)
        end

    elseif (msg == "totem" or msg == "totemplace") then
        -- 非萨满无图腾数据（Config["shaman_totem"]为nil），直接访问会报空表错误
        if GoubayuHeal.my_class == GoubayuHeal.Shaman and GoubayuHeal.Totem_PlaceAll then
            -- 脱战后回收（主动按键路径）：回收过则本次不再放置
            if GoubayuHeal.Totem_TryRecallAfterCombat and GoubayuHeal.Totem_TryRecallAfterCombat() then
                return
            end
            GoubayuHeal.Totem_PlaceAll()
        end

    elseif (msg == "totemrecall") then
        if GoubayuHeal.my_class == GoubayuHeal.Shaman then
            CastSpellByName(GoubayuHeal.Spell.TotemRecall)
            if GoubayuHeal.Totem_ResetAllTimers then
                GoubayuHeal.Totem_ResetAllTimers()
            end
            GoubayuHeal.Print(GoubayuHeal.Msg.TotemRecallDone)
        end

    elseif (msg == "mm") then
        if GoubayuHealMinimapButton:IsVisible() then
            MyMinimapButton:SetEnable("GoubayuHeal", 0)
            GoubayuHeal.Config["hide_mm"] = 1
        else
            MyMinimapButton:SetEnable("GoubayuHeal", 1)
            GoubayuHeal.Config["hide_mm"] = 0
        end

    elseif (msg == "showall") then
        GoubayuHeal.Print(GoubayuHeal.Msg.ShowAllTitle)
        local found
        for class, data in GoubayuHeal.Config["classes"] do
            GoubayuHeal.Print(class)
            found = 1
        end
        if (not found) then
            GoubayuHeal.Print(GoubayuHeal.Msg.ShowAllEmpty)
        end

    elseif (msg == "togglehidden") then
        GoubayuHeal.Config["show_hidden_schemes"] = not GoubayuHeal.Config["show_hidden_schemes"]
        local status = GoubayuHeal.Config["show_hidden_schemes"]
            and GoubayuHeal.Msg.HiddenSchemesOn
            or GoubayuHeal.Msg.HiddenSchemesOff
        GoubayuHeal.Print(string.format(GoubayuHeal.Msg.HiddenSchemesToggle, status))
        GoubayuHeal.ClassDropDownMenuInitialize()
        GoubayuHeal.ClassDropDownMenuUpdate(GoubayuHeal.current_class)

    elseif (string.find(msg, "^tankheal")) then
        local profile = string.match(msg, "^tankheal%s+(.+)$")
            or GoubayuHeal.current_class or "standard"
        if not (GoubayuHeal.Config["classes"] and GoubayuHeal.Config["classes"][profile]) then
            GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankNotExist, profile))
        elseif not (GoubayuHeal.Tank and GoubayuHeal.Tank["Name"]) then
            -- 仅未设置MT时反馈（5秒节流防刷屏）；MT已设置后即使满血/无可治疗目标
            -- 也属正常待机，静默处理绝不刷屏
            if not GoubayuHeal._tank_none_msg_time
                or (GetTime() - GoubayuHeal._tank_none_msg_time) > 5 then
                GoubayuHeal._tank_none_msg_time = GetTime()
                GoubayuHeal.Print(GoubayuHeal.Msg.TankModeNone)
            end
        else
            local result = GoubayuHeal.TankHealProfile(profile)
            if result then
                GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankModeHeal,
                    tostring(GoubayuHeal.Tank and GoubayuHeal.Tank["Name"])))
            end
            -- MT已设置：本轮满血/无可治疗目标属正常待机，静默
        end

    elseif (msg == "tank") then
        local aka = nil
        if (UnitExists("target") and UnitIsFriend("player", "target")) then
            aka = GoubayuHeal.AKA("target")
        end

        if (aka) then
            if (aka ~= "target" or UnitIsUnit("player", aka)) then
                GoubayuHeal.SetRaidRole(GoubayuHeal.UnitName(aka), "MT")
                GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankSet, GoubayuHeal.UnitName(aka)))
            else
                GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankMustInGroup, GoubayuHeal.UnitName(aka)))
                if (GoubayuHeal.Tank and GoubayuHeal.Tank["Name"]) then
                    GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankKeep, GoubayuHeal.Tank["Name"]))
                else
                    GoubayuHeal.Print(GoubayuHeal.Msg.NoTank)
                end
            end
        else
            if (GoubayuHeal.Tank and GoubayuHeal.Tank["Name"]) then
                -- 先取名字再清角色：SetRaidRole 取消分支会同步清空 Tank，
                -- 之后 Tank["Name"] 已是 nil，format 会报错并中断宏的后续行
                local tankName = GoubayuHeal.Tank["Name"]
                GoubayuHeal.SetRaidRole(tankName, GoubayuHeal.Msg.RoleNone)
                GoubayuHeal.Print(string.format(GoubayuHeal.Msg.TankUnset, tankName))
            else
                GoubayuHeal.Print(GoubayuHeal.Msg.NoTank)
            end
        end
        return

    elseif (msg == "rez") then
        GoubayuHeal.DoRez()

    elseif (msg == "dispel") then
        GoubayuHeal.Dispel(true)

    elseif (msg == "freedom" or msg == "自由") then
        -- 自由之手独立通道：不管"驱散移动限制"是否勾选都驱散（复用驱散优先级）
        -- by 武藤纯子酱 2026.10.13
        if not (GoubayuHeal.Dispel_Freedom and GoubayuHeal.Dispel_Freedom()) then
            GoubayuHeal.Print(GoubayuHeal.Msg.FreedomNone)
        end

    elseif (msg == "dispelprio") then
        -- 打开驱散优先级窗口（驱散面板标题被隐藏时也能进入）
        if GoubayuHeal.Dispel_TogglePrioWindow then
            GoubayuHeal.Dispel_TogglePrioWindow()
        elseif GoubayuHeal.Dispel_CreatePrioWindow then
            GoubayuHeal.Dispel_CreatePrioWindow()
        end

    elseif (msg == "help") then
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpUsage)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpSave)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpLoad)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpList)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpDelete)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpGui)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpMm)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpOpt)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpReset)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpShowAll)
        GoubayuHeal.Print(GoubayuHeal.Msg.HelpToggleHidden)
    else
        GoubayuHeal.ActionHeal(msg, nil)
    end
end
