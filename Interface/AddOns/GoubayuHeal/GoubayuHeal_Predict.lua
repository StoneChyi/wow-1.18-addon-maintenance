-- ============================================================
-- 文件名: GoubayuHeal_Predict.lua
-- 功能: 预读（Pre-heal）——识别敌对单位的平砍/读条目标，提前对"即将受击"的队友
--       施放 HOT/盾（瞬发）或读条治疗（读条结束对齐在伤害落地之后），抢有效治疗。
-- 依赖: Nampower 的 AUTO_ATTACK_OTHER / SPELL_START_OTHER 事件 + UnitAttackSpeed。
-- by 武藤纯子酱 2026.10.13
-- ============================================================

GoubayuHeal.Predict = {}
local Predict = GoubayuHeal.Predict

local MAX_ENEMIES = 50      -- 敌方池上限（防卡顿）
local ENEMY_IDLE_TTL = 15   -- 敌方条目空闲多久后淘汰（秒）
local INCOMING_TTL = 4      -- 预计伤害有效期（秒）
local SWING_DEFAULT = 2.0   -- 攻速取不到时的兜底平砍间隔（秒）
local MAX_LATE = 1.5        -- 读条允许晚于伤害落地的上限（秒）
local AUTO_EVAL_INTERVAL = 0.2  -- 评估间隔（秒，OnUpdate 轮询；只更新标识，不施放）

Predict.enemies = {}    -- [enemyGuid] = { lastSwing, speed, lastActive }
Predict.incoming = {}   -- [allyGuid] = { enemyGuid, kind, dueTime, dmgHint, updateAt }
Predict.ready = nil     -- 预读标识：{ unit, spell, rank, attach, attachRank, forceMax, instant, startAt, profile, at }
Predict.frame = nil
Predict.cleanupTimer = 0

-- ============================================================
-- 工具
-- ============================================================

local function CountKeys(t)
    local n = 0
    for _ in pairs(t) do
        n = n + 1
    end
    return n
end

local function IsEnemyGuid(guid)
    if not guid or guid == "0x0000000000000000" then
        return false
    end
    if not UnitExists(guid) then
        return false
    end
    return UnitCanAttack and UnitCanAttack("player", guid)
end

local function IsFriendlyGuid(guid)
    if not guid or guid == "0x0000000000000000" then
        return false
    end
    if not UnitExists(guid) then
        return false
    end
    return UnitIsFriend and UnitIsFriend("player", guid)
end

-- 攻速（秒）：UnitAttackSpeed 取当前攻速（含加速/减速修正）；取不到退回兜底值
local function GetAttackSpeed(guid)
    if UnitAttackSpeed then
        local ok, main = pcall(UnitAttackSpeed, guid)
        if ok and type(main) == "number" and main > 0.1 then
            return main
        end
    end
    return SWING_DEFAULT
end

-- 敌方池：写入/刷新，超过上限按 lastActive LRU 淘汰
local function TouchEnemy(guid, now)
    local e = Predict.enemies[guid]
    if not e then
        if CountKeys(Predict.enemies) >= MAX_ENEMIES then
            local oldest, oldestT = nil, now + 1
            for g, d in pairs(Predict.enemies) do
                if d.lastActive and d.lastActive < oldestT then
                    oldest, oldestT = g, d.lastActive
                end
            end
            if oldest then
                Predict.enemies[oldest] = nil
            end
        end
        e = { lastSwing = 0, speed = SWING_DEFAULT, lastActive = now }
        Predict.enemies[guid] = e
    end
    e.lastActive = now
    return e
end

-- 写入"预计伤害"：同一敌人对同一目标的新预测 → 刷新；不同敌人 → 保留更早落地的那个
-- by 武藤纯子酱 2026.10.15
local function SetIncoming(allyGuid, enemyGuid, kind, dueTime, dmgHint, now)
    if not allyGuid then
        return
    end
    local cur = Predict.incoming[allyGuid]
    if cur then
        if cur.enemyGuid == enemyGuid and cur.kind == kind then
            -- 同一敌人+同一目标：刷新落地时刻与活跃时间。否则反复平砍时 dueTime 会停在第 1 次预测
            -- 不再前进，之后被过期清理出现空窗，表现为预读"时灵时不灵"
            cur.dueTime = dueTime
            cur.updateAt = now
            if dmgHint and dmgHint > (cur.dmgHint or 0) then
                cur.dmgHint = dmgHint
            end
            return
        end
        if cur.dueTime <= dueTime then
            -- 不同敌人：保留更早落地的那个，只补伤害提示
            if dmgHint and dmgHint > (cur.dmgHint or 0) then
                cur.dmgHint = dmgHint
            end
            return
        end
    end
    Predict.incoming[allyGuid] = {
        enemyGuid = enemyGuid, kind = kind, dueTime = dueTime,
        dmgHint = dmgHint or 0, updateAt = now,
    }
end

-- ============================================================
-- 事件采集
-- ============================================================

local function OnAutoAttackOther()
    -- arg1=attackerGuid, arg2=targetGuid, arg3=totalDamage, arg4=hitInfo ...
    local aGuid, tGuid, dmg = arg1, arg2, arg3
    if not (aGuid and tGuid) then
        return
    end
    if not (IsEnemyGuid(aGuid) and IsFriendlyGuid(tGuid)) then
        return
    end
    local now = GetTime()
    local e = TouchEnemy(aGuid, now)
    e.lastSwing = now
    e.speed = GetAttackSpeed(aGuid)
    -- 预测下次平砍 = 本次 + 攻速（UnitAttackSpeed 已含实时修正）
    SetIncoming(tGuid, aGuid, "swing", now + e.speed, tonumber(dmg) or 0, now)
end

local function OnSpellStartOther()
    -- arg2=spellId, arg3=casterGuid, arg4=targetGuid, arg6=castTime, arg7=duration, arg8=spellType
    local casterGuid, targetGuid = arg3, arg4
    local castTime, duration, spellType = arg6, arg7, arg8
    if not (casterGuid and targetGuid) then
        return
    end
    if not (IsEnemyGuid(casterGuid) and IsFriendlyGuid(targetGuid)) then
        return
    end
    local ms = (spellType == 1) and duration or castTime
    if not (ms and ms > 0) then
        return
    end
    local now = GetTime()
    TouchEnemy(casterGuid, now)
    SetIncoming(targetGuid, casterGuid, "cast", now + ms / 1000, 0, now)
end

local function OnSpellEndOther()
    -- GO_OTHER: arg3=casterGuid ；FAILED_OTHER: arg1=casterGuid
    local casterGuid = (event == "SPELL_GO_OTHER") and arg3 or arg1
    if not casterGuid then
        return
    end
    for allyGuid, inc in pairs(Predict.incoming) do
        if inc.enemyGuid == casterGuid and inc.kind == "cast" then
            Predict.incoming[allyGuid] = nil
        end
    end
end

local function OnUnitDied()
    local guid = arg1
    if not guid then
        return
    end
    Predict.enemies[guid] = nil
    Predict.incoming[guid] = nil
    for allyGuid, inc in pairs(Predict.incoming) do
        if inc.enemyGuid == guid then
            Predict.incoming[allyGuid] = nil
        end
    end
end

-- ============================================================
-- 清理（防卡顿）：敌方池去死/去无 + 过期条目
-- ============================================================

function Predict.Cleanup()
    local now = GetTime()
    local dead = nil
    for g, d in pairs(Predict.enemies) do
        if (not UnitExists(g)) or UnitIsDeadOrGhost(g)
            or (now - (d.lastActive or 0)) > ENEMY_IDLE_TTL then
            dead = dead or {}
            table.insert(dead, g)
        end
    end
    if dead then
        for _, g in ipairs(dead) do
            Predict.enemies[g] = nil
        end
    end

    local gone = nil
    for allyGuid, inc in pairs(Predict.incoming) do
        if (not UnitExists(allyGuid)) or UnitIsDeadOrGhost(allyGuid)
            or (now - (inc.updateAt or 0)) > INCOMING_TTL
            or (not Predict.enemies[inc.enemyGuid]) then
            gone = gone or {}
            table.insert(gone, allyGuid)
        end
    end
    if gone then
        for _, g in ipairs(gone) do
            Predict.incoming[g] = nil
        end
    end
end

-- ============================================================
-- 目标优先级 + 技能选择
-- ============================================================

local function IsTankUnit(unit)
    if GoubayuHeal.Tank and GoubayuHeal.Tank["Name"] then
        local tn = GoubayuHeal.Tank["Name"]
        if UnitName(unit) == tn or (GoubayuHeal.UnitIsUnit and UnitIsUnit(unit, GoubayuHeal.Tank["Unit"])) then
            return true
        end
    end
    local roles = GoubayuHeal.Config and GoubayuHeal.Config["raid_roles"]
    local name = UnitName(unit)
    if roles and name then
        local r = roles[name]
        if r == "MT" or r == "8T" then
            return true
        end
    end
    return false
end

-- 返回按优先级排序的候选列表：预估伤害大 > 坦克 > dueTime 早 > 治疗优先级 > 血量低
function Predict.PickCandidates()
    local now = GetTime()
    local cands = {}
    for allyGuid, inc in pairs(Predict.incoming) do
        if IsFriendlyGuid(allyGuid) and not UnitIsDeadOrGhost(allyGuid)
            and (not GoubayuHeal.CanHeal or GoubayuHeal.CanHeal(allyGuid))
            and (not GoubayuHeal.CanCastAtUnit or GoubayuHeal.CanCastAtUnit(allyGuid, 40) ~= false) then
            local h, mh = GoubayuHeal.GetUnitHealth(allyGuid)
            local hp = (mh and mh > 0) and (h / mh) or 1
            table.insert(cands, {
                guid = allyGuid,
                dueTime = inc.dueTime,
                dmg = tonumber(inc.dmgHint) or 0,
                tank = IsTankUnit(allyGuid),
                prio = (GoubayuHeal.GetPriority and GoubayuHeal.GetPriority(allyGuid)) or 0,
                hp = hp,
            })
        end
    end
    table.sort(cands, function(a, b)
        if a.dmg ~= b.dmg then return a.dmg > b.dmg end
        if a.tank ~= b.tank then return a.tank end
        if a.dueTime ~= b.dueTime then return a.dueTime < b.dueTime end
        if a.prio ~= b.prio then return a.prio > b.prio end
        return a.hp < b.hp
    end)
    return cands
end

local function IsInstantSpell(spell)
    if spell == GoubayuHeal.Power_word_shield or spell == GoubayuHeal.Rejuvenation
        or spell == GoubayuHeal.Renew then
        return true
    end
    return false
end

-- 选技能：HOT维持（若开）→ 方案条目（阈值从高到低 = 治疗量从小到大）。
-- 对选中的方案条目应用方案的"技能变化"设置：
--   · 萨满 链转波（shaman_chain_nobounce_wave）：治疗链无弹跳目标 → 治疗波/次级治疗波
--   · 牧师 交替技能 / 8T2（priest_alternate_spells / priest_8t2）：上次放的是本技能 → 改放交替技能
-- 牧师 疾速只强效（priest_force_greater_heal）为独立提前返回（与正常流程 HealUsingClass 一致）
-- 返回 { spell, rank, instant, attachment, attachmentRank } 或 nil
-- by 武藤纯子酱 2026.10.15
function Predict.ChooseSpell(unit, profile, skipAOE)
    local name = UnitName(unit)
    local C = GoubayuHeal.Config

    -- 1) HOT 维持
    if C and C["raid_hots_enabled"] == 1 and name and GoubayuHeal.hot_maintain_spells then
        local cfg = C["raid_hots"] and C["raid_hots"][name]
        local spells = GoubayuHeal.hot_maintain_spells[GoubayuHeal.my_class]
        if cfg and spells then
            for _, sp in ipairs(spells) do
                local rank = tonumber(cfg[sp])
                if rank and GoubayuHeal.Spells and GoubayuHeal.Spells[sp] and GoubayuHeal.Spells[sp][rank] then
                    if sp == GoubayuHeal.Power_word_shield then
                        if not (GoubayuHeal.UnitHasWeakenedSoul(unit)
                            or GoubayuHeal.UnitGotBuff(unit, sp)) then
                            return { spell = sp, rank = rank, instant = true }
                        end
                    elseif not GoubayuHeal.UnitHasHOT(unit, sp) then
                        return { spell = sp, rank = rank, instant = true }
                    end
                end
            end
        end
    end

    local hh, hmh = GoubayuHeal.GetUnitHealth(unit)
    local hpPct = (hmh and hmh > 0) and (hh / hmh * 100) or 100

    -- 2) 牧师疾速只强效（独立提前返回，与正常流程 HealUsingClass 一致）
    if C and GoubayuHeal.my_class == GoubayuHeal.Priest
        and (tonumber(C["priest_force_greater_heal"]) or 0) == 1
        and GoubayuHeal.UnitGotBuff
        and GoubayuHeal.UnitGotBuff("player", GoubayuHeal.Rapid_healing)
        and GoubayuHeal.PickForceGreaterHealRank then
        local ghRank = GoubayuHeal.PickForceGreaterHealRank(profile, hpPct)
        if ghRank then
            return { spell = GoubayuHeal.Greater_heal, rank = ghRank,
                instant = IsInstantSpell(GoubayuHeal.Greater_heal) }
        end
        return nil
    end

    -- 3) 方案条目（阈值从高到低 = 治疗量从小到大）
    local cfg2 = C and C["classes"] and C["classes"][profile]
    if not cfg2 then
        return nil
    end
    local list = {}
    for pct, data in cfg2 do
        if type(data) == "table" and data["Spell"] then
            -- skipAOE：坦克在救急线以下时优先单体，跳过团刷条目
            -- by 武藤纯子酱 2026.10.23
            local sp = data["Spell"]
            local isAOE = (sp == GoubayuHeal.Holy_nova
                or sp == GoubayuHeal.Prayer_of_healing
                or sp == GoubayuHeal.Chain_heal
                or sp == GoubayuHeal.Tranquility)
            if not (skipAOE and isAOE) then
                table.insert(list, { pct = tonumber(pct) or 0, data = data })
            end
        end
    end
    table.sort(list, function(a, b) return a.pct > b.pct end)

    for _, e in ipairs(list) do
        local d = e.data
        local sp = d["Spell"]
        local rank = d["Rank"]
        if sp and rank and GoubayuHeal.Spells and GoubayuHeal.Spells[sp]
            and GoubayuHeal.Spells[sp][rank] then
            local present = false
            if sp == GoubayuHeal.Power_word_shield then
                present = (GoubayuHeal.UnitHasWeakenedSoul(unit) or GoubayuHeal.UnitGotBuff(unit, sp))
            elseif sp == GoubayuHeal.Rejuvenation or sp == GoubayuHeal.Renew
                or sp == GoubayuHeal.Regrowth then
                present = GoubayuHeal.UnitHasHOT(unit, sp)
            end

            if not present then
                local attach = d["Attachment"]
                local attRank = d["AttachmentRank"]

                -- 不纳入预估的附件：
                --  · 迅捷类（自然迅捷/先祖迅捷）：让读条技能变瞬发，属"救命"手段，预读不是救命场合，白烧CD
                --  · 神圣打击：瞬发、近战群疗（需可攻击的近战目标 + 附近多个受伤队友），非单体预判治疗
                if attach == GoubayuHeal.Natures_swiftness
                    or attach == GoubayuHeal.Shaman_Ancestral_swiftness
                    or attach == GoubayuHeal.Holy_Strike then
                    attach = nil
                    attRank = nil
                end

                -- 萨满链转波：治疗链无弹跳目标 → 改用等量治疗波/次级治疗波（省蓝）
                if sp == GoubayuHeal.Chain_heal and GoubayuHeal.my_class == GoubayuHeal.Shaman
                    and (tonumber(C["shaman_chain_nobounce_wave"]) or 0) > 0
                    and GoubayuHeal.ChainHeal_SelectBestTarget then
                    local _, hasBounce = GoubayuHeal.ChainHeal_SelectBestTarget(sp, rank)
                    if not hasBounce then
                        local waveSpell = ((tonumber(C["shaman_chain_nobounce_wave"]) or 0) == 2)
                            and GoubayuHeal.Lesser_healing_wave or GoubayuHeal.Healing_wave
                        local waveRank = GoubayuHeal.FindEquivalentWaveRank(sp, rank, waveSpell)
                        if waveRank then
                            sp = waveSpell
                            rank = waveRank
                            attach = nil
                            attRank = nil
                        end
                    end
                end

                -- 牧师交替技能 / 8T2："上一次施放的技能 == 本技能"（连续两次同技能，不限时间间隔）→
                -- 改放该条目的交替技能（满级）；8T2 且本技能为强效治疗术时保持连打强效，不交替
                if GoubayuHeal.my_class == GoubayuHeal.Priest
                    and (tonumber(C["priest_alternate_spells"]) or 0) == 1
                    and d["Alternate"] and GoubayuHeal.Spells[d["Alternate"]]
                    and GoubayuHeal.last_cast_spell == sp then
                    local noAlt = (sp == GoubayuHeal.Greater_heal
                        and (tonumber(C["priest_8t2"]) or 0) == 1)
                    if not noAlt then
                        local altMax = table.getn(GoubayuHeal.Spells[d["Alternate"]])
                        local acheck = altMax
                        if (tonumber(C["scale_spells"]) or 0) == 1 then
                            acheck = 1
                        end
                        if not GoubayuHeal.SpellRankOutOfMana(d["Alternate"], acheck) then
                            sp = d["Alternate"]
                            rank = altMax
                            attach = nil
                            attRank = nil
                        end
                    end
                end

                return { spell = sp, rank = rank, instant = IsInstantSpell(sp),
                    attachment = attach, attachmentRank = attRank }
            end
        end
    end
    return nil
end

local function SpellCastTime(spell, rank)
    local sd = GoubayuHeal.Spells and GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][rank]
    local ct = (sd and sd["CastTime"]) or 0
    return ct
end

-- ============================================================
-- 主入口：一键治疗里调用。返回 true = 已处理（本次动作结束）
-- ============================================================

-- 附件的"最高等级"取值（方案未指定附件等级时用满级）
-- by 武藤纯子酱 2026.10.15
function Predict.AttachMaxRank(attach)
    if not (GoubayuHeal.Spells and GoubayuHeal.Spells[attach]) then
        return nil
    end
    local hr = 1
    for r, _ in pairs(GoubayuHeal.Spells[attach]) do
        local rn = tonumber(r) or 1
        if rn > hr then hr = rn end
    end
    return hr
end

-- 施放一次预读：先单体附件（保护之手/真言盾/神圣震击…）再主技能；计时由调用方负责。
-- 返回主技能 Heal 的结果。by 武藤纯子酱 2026.10.15
function Predict.CastPick(unit, spell, rank, attach, attRank, forceMax)
    local noscale = forceMax
    if attach then
        local attTarget = unit
        if not (GoubayuHeal.attachment_has_target
            and GoubayuHeal.attachment_has_target[attach]) then
            attTarget = "player"
        end
        local skip = false
        if attach == GoubayuHeal.Blessing_of_protection
            and GoubayuHeal.UnitGotDebuff
            and GoubayuHeal.UnitGotDebuff(attTarget, GoubayuHeal.Forbearance) then
            skip = true
        end
        if not skip then
            GoubayuHeal.Heal(attTarget, attach, attRank, nil, noscale, forceMax)
        end
    end
    return GoubayuHeal.Heal(unit, spell, rank, nil, noscale, forceMax)
end

-- 预读评估（只计算"现在该不该预读、放什么"，绝不施放）。
-- 由 OnUpdate 每 0.2 秒调用一次，结果存 Predict.ready；真正施放只在按键时由
-- GoubayuHeal.Predict_TryPreHeal 消费该标识。by 武藤纯子酱 2026.10.23
function Predict.Evaluate(profile)
    local C = GoubayuHeal.Config
    if not (C and C["predict_enabled"] == 1) then
        return nil
    end
    if not (GetNampowerVersion and GetUnitGUID) then
        return nil
    end

    local cands = Predict.PickCandidates()
    if not cands or table.getn(cands) == 0 then
        return nil
    end

    -- 满级修饰键 / always_tank_target：与正常流程一致，强制最高等级
    local forceMax = false
    if (GoubayuHeal.IsHealModifierKeyDown and GoubayuHeal.IsHealModifierKeyDown("heal_max_modifier"))
        or (tonumber(C["always_tank_target"]) or 0) == 1 then
        forceMax = true
    end

    local now = GetTime()
    for _, c in ipairs(cands) do
        local pick = Predict.ChooseSpell(c.guid, profile)
        -- 救援：已设置的坦克（MT/8T）在救急线以下且选中的是团刷主技能 →
        -- 优先换成单体条目；没有单体条目时才继续用团刷。
        -- by 武藤纯子酱 2026.10.23
        if pick and GoubayuHeal.TankInRescue and GoubayuHeal.TankInRescue() then
            local psp = pick.spell
            if psp == GoubayuHeal.Holy_nova or psp == GoubayuHeal.Prayer_of_healing
                or psp == GoubayuHeal.Chain_heal or psp == GoubayuHeal.Tranquility then
                local alt = Predict.ChooseSpell(c.guid, profile, true)
                if alt then
                    pick = alt
                end
            end
        end
        if pick then
            local spell = pick.spell
            local rank = pick.rank
            local attachFirst = nil
            local attachRank = nil

            -- 附件：团刷类（新星/祷言/链）与主技能比治疗量取高者；
            -- 单体类（保护之手/真言盾/神圣震击）先手施放，再走主技能的计时
            local attach = pick.attachment
            if attach and GoubayuHeal.Spells and GoubayuHeal.Spells[attach] then
                local aRank = pick.attachmentRank or Predict.AttachMaxRank(attach)
                if aRank and GoubayuHeal.Spells[attach][aRank] then
                    local isAOE = (attach == GoubayuHeal.Holy_nova
                        or attach == GoubayuHeal.Prayer_of_healing
                        or attach == GoubayuHeal.Chain_heal)
                    -- 坦克（MT/8T）在救急线以下：预读也不用团刷挂接（专注单体）
                    -- by 武藤纯子酱 2026.10.23
                    local skipAOE = isAOE and (GoubayuHeal.tankheal_mode
                        or (GoubayuHeal.TankInRescue and GoubayuHeal.TankInRescue()))
                    if isAOE and not skipAOE then
                        local mainHeal = (GoubayuHeal.GetSpellHealing
                            and GoubayuHeal.GetSpellHealing(c.guid, spell, rank)) or 0
                        local attHeal = (GoubayuHeal.GetSpellHealing
                            and GoubayuHeal.GetSpellHealing(c.guid, attach, aRank)) or 0
                        if attHeal > mainHeal then
                            spell = attach
                            rank = aRank
                        end
                    elseif not isAOE then
                        attachFirst = attach
                        attachRank = aRank
                    end
                end
            end

            if forceMax and GoubayuHeal.Spells and GoubayuHeal.Spells[spell] then
                rank = table.getn(GoubayuHeal.Spells[spell])
            end

            local instant = IsInstantSpell(spell)
            local castTime = SpellCastTime(spell, rank)
            if instant or castTime <= 0 then
                return { unit = c.guid, spell = spell, rank = rank,
                    attach = attachFirst, attachRank = attachRank,
                    forceMax = forceMax, instant = true, startAt = now,
                    profile = profile, at = now }
            end
            local startAt = c.dueTime - castTime
            -- 到起手时机（读条结束不晚于伤害落地太多）才算 ready；
            -- 太早 → 等下一轮评估；太晚 → 试下一个目标
            if startAt <= now and now + castTime <= c.dueTime + MAX_LATE then
                return { unit = c.guid, spell = spell, rank = rank,
                    attach = attachFirst, attachRank = attachRank,
                    forceMax = forceMax, instant = false, startAt = startAt,
                    dueTime = c.dueTime, profile = profile, at = now }
            end
        end
    end
    return nil
end

-- 按键时消费"预读标识"：只在玩家按下 GBYH 治疗命令时被调用（ActionHeal）。
-- 标识由 OnUpdate 维护；没有标识/标识过期/方案不一致时，在本次按键内即时算一次。
-- by 武藤纯子酱 2026.10.23
function GoubayuHeal.Predict_TryPreHeal(profile)
    local C = GoubayuHeal.Config
    if not (C and C["predict_enabled"] == 1) then
        return false
    end
    if not (GetNampowerVersion and GetUnitGUID) then
        return false
    end
    if GoubayuHeal.IsMoving and GoubayuHeal.IsMoving() then
        return false
    end
    if GoubayuHeal.casting_spell then
        return false
    end
    -- 全局中止（沉默/昏迷等）期间不做预读 by 武藤纯子酱 2026.10.19
    if GoubayuHeal._abortAction then
        return false
    end

    local r = Predict.ready
    if (not r) or (profile and r.profile and r.profile ~= profile)
        or (GetTime() - (r.at or 0)) > 1.0 then
        r = Predict.Evaluate(profile)
    end
    Predict.ready = nil
    if not r then
        return false
    end
    if not (UnitExists(r.unit) and not UnitIsDeadOrGhost(r.unit)) then
        return false
    end
    if (not r.instant) and GetTime() < (r.startAt or 0) then
        return false
    end
    -- 读条类：已过"允许晚到"上限就不再放（避免 1 秒后才按下时白读一次条）
    if (not r.instant) and r.dueTime and GetTime() > r.dueTime + MAX_LATE then
        return false
    end
    return (Predict.CastPick(r.unit, r.spell, r.rank, r.attach, r.attachRank, r.forceMax))
        and true or false
end

-- ============================================================
-- OnUpdate：清理 + 只维护"是否预读"标识（绝不施放）
-- ============================================================

function Predict.OnUpdate(elapsed)
    Predict.cleanupTimer = (Predict.cleanupTimer or 0) + (elapsed or 0)
    if Predict.cleanupTimer >= 0.5 then
        Predict.cleanupTimer = 0
        pcall(Predict.Cleanup)
    end

    -- 死亡/灵魂状态（救赎之魂除外）：不评估预读
    -- by 武藤纯子酱 2026.10.23
    if GoubayuHeal.PlayerDeadBlocked and GoubayuHeal.PlayerDeadBlocked() then
        Predict.ready = nil
        return
    end

    -- 每 AUTO_EVAL_INTERVAL 秒评估一次，只更新 Predict.ready（是否预读 + 放什么）；
    -- 真正施放只发生在玩家按下 GBYH 治疗命令时（GoubayuHeal.Predict_TryPreHeal）。
    -- by 武藤纯子酱 2026.10.23
    Predict.autoTimer = (Predict.autoTimer or 0) + (elapsed or 0)
    if Predict.autoTimer < AUTO_EVAL_INTERVAL then
        return
    end
    Predict.autoTimer = 0

    if not (GoubayuHeal.Config and GoubayuHeal.Config["predict_enabled"] == 1) then
        Predict.ready = nil
        return
    end
    if GoubayuHeal.casting_spell or GoubayuHeal._abortAction
        or (GoubayuHeal.IsMoving and GoubayuHeal.IsMoving()) then
        Predict.ready = nil
        return
    end
    local profile = GoubayuHeal.current_action_profile or GoubayuHeal.current_class
    if not profile then
        Predict.ready = nil
        return
    end
    Predict.ready = Predict.Evaluate(profile)
end

-- ============================================================
-- 初始化
-- ============================================================

function GoubayuHeal.Predict_Init()
    if Predict.frame then
        return
    end

    local f = CreateFrame("Frame")
    Predict.frame = f
    pcall(f.RegisterEvent, f, "PLAYER_LOGIN")
    pcall(f.RegisterEvent, f, "PLAYER_ENTERING_WORLD")
    pcall(f.RegisterEvent, f, "AUTO_ATTACK_OTHER")
    pcall(f.RegisterEvent, f, "SPELL_START_OTHER")
    pcall(f.RegisterEvent, f, "SPELL_GO_OTHER")
    pcall(f.RegisterEvent, f, "SPELL_FAILED_OTHER")
    pcall(f.RegisterEvent, f, "UNIT_DIED")

    f:SetScript("OnEvent", function()
        if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
            if GetNampowerVersion and SetCVar then
                pcall(SetCVar, "NP_EnableAutoAttackEvents", 1)
                pcall(SetCVar, "NP_EnableSpellStartEvents", 1)
            end
        elseif event == "AUTO_ATTACK_OTHER" then
            OnAutoAttackOther()
        elseif event == "SPELL_START_OTHER" then
            OnSpellStartOther()
        elseif event == "SPELL_GO_OTHER" or event == "SPELL_FAILED_OTHER" then
            OnSpellEndOther()
        elseif event == "UNIT_DIED" then
            OnUnitDied()
        end
    end)

    local uf = CreateFrame("Frame")
    uf:SetScript("OnUpdate", function() Predict.OnUpdate(arg1) end)
    Predict.updateFrame = uf
end

GoubayuHeal.Predict_Init()
