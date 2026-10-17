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
local MAX_WAIT = 2.5        -- 允许等待起手的上限（超过则不预读该目标）
local MAX_LATE = 1.5        -- 读条允许晚于伤害落地的上限（秒）
local AUTO_EVAL_INTERVAL = 0.2  -- 自动预读评估间隔（秒，OnUpdate 轮询；不依赖按键）

Predict.enemies = {}    -- [enemyGuid] = { lastSwing, speed, lastActive }
Predict.incoming = {}   -- [allyGuid] = { enemyGuid, kind, dueTime, dmgHint, updateAt }
Predict.pending = nil   -- { unit, spell, rank, startAt, dueTime }
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
function Predict.ChooseSpell(unit, profile)
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
            table.insert(list, { pct = tonumber(pct) or 0, data = data })
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

-- by 武藤纯子酱 2026.10.15
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

    local cands = Predict.PickCandidates()
    if not cands or table.getn(cands) == 0 then
        return false
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
                    if attach == GoubayuHeal.Holy_nova or attach == GoubayuHeal.Prayer_of_healing
                        or attach == GoubayuHeal.Chain_heal then
                        local mainHeal = (GoubayuHeal.GetSpellHealing
                            and GoubayuHeal.GetSpellHealing(c.guid, spell, rank)) or 0
                        local attHeal = (GoubayuHeal.GetSpellHealing
                            and GoubayuHeal.GetSpellHealing(c.guid, attach, aRank)) or 0
                        if attHeal > mainHeal then
                            spell = attach
                            rank = aRank
                        end
                    else
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
                if Predict.CastPick(c.guid, spell, rank, attachFirst, attachRank, forceMax) then
                    return true
                end
            else
                local startAt = c.dueTime - castTime
                -- 能对齐（起手等待不超上限，且读条结束不晚于伤害太多）
                if startAt <= now + MAX_WAIT and now + castTime <= c.dueTime + MAX_LATE then
                    if startAt <= now then
                        if Predict.CastPick(c.guid, spell, rank, attachFirst, attachRank, forceMax) then
                            return true
                        end
                    else
                        Predict.pending = {
                            unit = c.guid, spell = spell, rank = rank,
                            profile = profile,
                            attach = attachFirst, attachRank = attachRank, forceMax = forceMax,
                            startAt = startAt, dueTime = c.dueTime,
                        }
                        return true
                    end
                end
                -- 来不及 → 试下一个目标
            end
        end
    end
    return false
end

-- ============================================================
-- OnUpdate：清理 + 待起手读条
-- ============================================================

function Predict.OnUpdate(elapsed)
    Predict.cleanupTimer = (Predict.cleanupTimer or 0) + (elapsed or 0)
    if Predict.cleanupTimer >= 0.5 then
        Predict.cleanupTimer = 0
        pcall(Predict.Cleanup)
    end

    -- 待起手读条
    local p = Predict.pending
    if p then
        local activeProfile = GoubayuHeal.current_action_profile or GoubayuHeal.current_class
        if not (GoubayuHeal.Config and GoubayuHeal.Config["predict_enabled"] == 1)
            or (p.profile and p.profile ~= activeProfile) then
            Predict.pending = nil
            return
        end
        local now = GetTime()
        if (not UnitExists(p.unit)) or UnitIsDeadOrGhost(p.unit)
            or (GoubayuHeal.IsMoving and GoubayuHeal.IsMoving())
            or GoubayuHeal.casting_spell
            or now > p.dueTime + MAX_LATE then
            Predict.pending = nil
        elseif now >= p.startAt then
            Predict.pending = nil
            Predict.CastPick(p.unit, p.spell, p.rank, p.attach, p.attachRank, p.forceMax)
        end
        return
    end

    -- 自动预读评估（不依赖按键）：每 AUTO_EVAL_INTERVAL 秒评估一次，让"预测的下一次伤害"
    -- 一到窗口就自动预读，提升灵敏度/一致性（不再只靠按键那一刻）
    -- by 武藤纯子酱 2026.10.15
    Predict.autoTimer = (Predict.autoTimer or 0) + (elapsed or 0)
    if Predict.autoTimer < AUTO_EVAL_INTERVAL then
        return
    end
    Predict.autoTimer = 0

    if not (GoubayuHeal.Config and GoubayuHeal.Config["predict_enabled"] == 1) then
        return
    end
    if GoubayuHeal.casting_spell then
        return
    end
    if GoubayuHeal.IsMoving and GoubayuHeal.IsMoving() then
        return
    end
    local profile = GoubayuHeal.current_action_profile or GoubayuHeal.current_class
    if profile and GoubayuHeal.Predict_TryPreHeal then
        pcall(GoubayuHeal.Predict_TryPreHeal, profile)
    end
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
