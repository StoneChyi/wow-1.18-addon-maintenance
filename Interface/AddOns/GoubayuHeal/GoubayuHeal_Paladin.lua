-- ============================================================
-- 文件名: GoubayuHeal_Paladin.lua
-- 功能: 圣骑士功能扩展
--       近战奶骑一键宏（智慧圣印/审判维持、十字军打击、方案治疗）
-- ============================================================

-- ============================================================
-- 环境检测函数
-- ============================================================

-- 检查是否安装了 Nampower
function GoubayuHeal.Paladin_HasNampower()
    return GetNampowerVersion ~= nil
end

-- 检查是否安装了 UnitXP 插件
function GoubayuHeal.Paladin_HasUnitXP()
    return UnitXP and type(UnitXP) == "function"
end

-- ============================================================
-- 单位/目标工具函数
-- ============================================================

-- 获取单位标识（优先Nampower GUID；1.12 的 UnitExists 只有单返回值，回退直接用单位token，
-- UnitXP 的 distanceBetween/inSight 同样接受单位token）
function GoubayuHeal.Paladin_GetUnitID(unit)
    if GoubayuHeal.GetUnitGUID then
        return GoubayuHeal.GetUnitGUID(unit)
    end
    if UnitExists(unit) then
        return unit
    end
    return nil
end

-- 检查目标是否在近战范围内（适配UnitXP和非UnitXP环境）
function GoubayuHeal.Paladin_CheckMeleeRange(unit)
    if not UnitExists(unit) then
        return false
    end

    if GoubayuHeal.Paladin_HasUnitXP() then
        local unitID = GoubayuHeal.Paladin_GetUnitID(unit)
        if unitID then
            -- UnitXP("distanceBetween", a, b, "meleeAutoAttack") 为真正的近战距离判定
            --（实机验证存在，比手写数值阈值准确）；pcall 防个别版本参数差异报错
            local ok, inMelee = pcall(UnitXP, "distanceBetween", "player", unitID, "meleeAutoAttack")
            if ok and inMelee then
                return true
            end
            return false
        end
        return false
    else
        -- CheckInteractDistance(2) 为交易距离（约11.1码），作为宽松上界近似
        if CheckInteractDistance(unit, 2) then
            return true
        end
        -- 动作条槽位可配置（Config["paladin_melee_slot"]，默认12）：槽位因人而异，
        -- 摆放非攻击技能时该回退恒 false（近战奶在此类环境整体失效的兜底提示）
        local slot = tonumber(GoubayuHeal.Config and GoubayuHeal.Config["paladin_melee_slot"])
            or 12
        return IsActionInRange(slot) == 1
    end
end

-- 检查玩家是否正在施法
-- （GetCastInfo 有数据即正在施法/引导，无数据返回 nil——无需时间戳比较）
function GoubayuHeal.Paladin_IsCasting()
    if GetNampowerVersion then
        -- Nampower v2+：GetCastInfo 返回施法信息表
        if GetCastInfo then
            local info = GetCastInfo()
            if info then
                return true
            end
            return false
        end
        -- 旧版Nampower：GetCurrentCastingInfo
        if GetCurrentCastingInfo then
            -- Nampower签名：第4参=在读条(0/1)，第5参=在引导(0/1)
            local _, _, _, isCasting, isChanneling = GetCurrentCastingInfo()
            return (isCasting == 1) or (isChanneling == 1)
        end
    end
    return CastingBarFrame and CastingBarFrame:IsVisible() and CastingBarFrame.casting
end

-- ============================================================
-- 法术查找与目标管理
-- ============================================================

-- 查找法术书槽位ID（优先使用Nampower快速路径）
function GoubayuHeal.Paladin_FindSpellID(spellName)
    if GetNampowerVersion and GetSpellSlotTypeIdForName then
        local ok, slot, bookType, sid = pcall(GetSpellSlotTypeIdForName, spellName)
        if ok and type(slot) == "number" and slot > 0 then
            -- 有Nampower：返回真实法术ID（GetSpellIdCooldown/IsSpellUsable 需要真实ID而非槽位号）
            return (type(sid) == "number" and sid > 0 and sid) or slot
        end
    end
    -- 无Nampower：返回法术书槽位号（原生 GetSpellCooldown(slot, BOOKTYPE_SPELL) 语义）
    for i = 1, 300 do
        local name = GetSpellName(i, BOOKTYPE_SPELL)
        if not name then
            break
        end
        if name == spellName then
            return i
        end
    end
    return nil
end

-- 清理 spell_awaiting_target 状态（防止目标残留：只清Spell/Rank不清Target，
-- 残留的"player"目标会在SPELLCAST_START时把后续治疗劫持给自己）
function GoubayuHeal.Paladin_CleanSpellAwaitingTarget()
    GoubayuHeal.spell_awaiting_target_Spell = nil
    GoubayuHeal.spell_awaiting_target_Rank = nil
    GoubayuHeal.spell_awaiting_target_Target = nil
end

-- 对指定GUID施放法术（Nampower专用）
function GoubayuHeal.Paladin_CastSpellOnTarget(spellName, targetGUID)
    GoubayuHeal.Paladin_CleanSpellAwaitingTarget()
    if GoubayuHeal.Paladin_HasNampower() then
        if targetGUID then
            CastSpellByName(spellName, targetGUID)
        else
            CastSpellByName(spellName)
        end
    else
        -- 非Nampower：原生施放（作用于当前 target，调用方需确保目标已选中）
        CastSpellByName(spellName)
    end
end

-- ============================================================
-- 近战奶骑核心逻辑
-- 流程：智慧圣印/审判维持 → 十字军打击 → 神圣震击 → 治疗
-- ============================================================

-- 对单个目标执行近战奶治疗（返回 true=已施放）
-- 治疗遵循方案百分比档位配置（HealUsingClass：档位选技能/等级 + 缩放 + 挂接附件）
function GoubayuHeal.Paladin_MeleeHealUnit(unit, profileName)
    if not unit then
        return false
    end
    if not (profileName and GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][profileName]) then
        return false
    end

    local h, mh = GoubayuHeal.GetUnitHealth(unit)
    if mh <= 0 or h <= 0 or UnitIsDeadOrGhost(unit) or UnitCanAttack("player", unit) then
        return false
    end

    local percent = h / mh
    local threshold = GoubayuHeal.Config["min_heal_threshold"] or 0.8
    if percent >= threshold then
        return false
    end

    -- 遵循方案档位治疗（含等级选择、法术缩放、附件挂接）
    local ok = GoubayuHeal.HealUsingClass(unit, profileName)
    return ok == 1
end

-- 治疗循环：target → targettarget → 自己 → 全队按血量升序；返回 true=已施放
function GoubayuHeal.Paladin_MeleeHealUnitLoop(profileName)
    if not profileName then
        return false
    end
    if UnitExists("target") and GoubayuHeal.CanHeal("target") then
        if GoubayuHeal.Paladin_MeleeHealUnit("target", profileName) then
            return true
        end
    end
    if UnitExists("target") and UnitExists("targettarget") and GoubayuHeal.CanHeal("targettarget") then
        if GoubayuHeal.Paladin_MeleeHealUnit("targettarget", profileName) then
            return true
        end
    end
    if GoubayuHeal.CanHeal("player") then
        if GoubayuHeal.Paladin_MeleeHealUnit("player", profileName) then
            return true
        end
    end
    local units = {}
    local n = GetNumRaidMembers()
    local por = "raid"
    if n == 0 then
        n = GetNumPartyMembers()
        por = "party"
    end
    -- 自己的宠物（团队中会以 raidpetN 重复出现，循环里用 UnitIsUnit 去重）
    if UnitExists("pet") and GoubayuHeal.CanHeal("pet")
        and (GoubayuHeal.GetPriority("pet") or 0) > 0 then
        table.insert(units, "pet")
    end
    for a = 1, n do
        local u = por .. a
        -- 跟随方案：优先级为 0（忽略）的单位不作为治疗候选；队友宠物同样按 pet_priority 参与
        -- 去重：玩家在团队中同时是 player 与自己的 raidN，用 UnitIsUnit 排除重复token
        if GoubayuHeal.CanHeal(u) and not UnitIsUnit(u, "player")
            and (GoubayuHeal.GetPriority(u) or 0) > 0 then
            table.insert(units, u)
        end
        local p = por .. "pet" .. a
        if GoubayuHeal.CanHeal(p) and not UnitIsUnit(p, "pet")
            and (GoubayuHeal.GetPriority(p) or 0) > 0 then
            table.insert(units, p)
        end
    end
    -- 全队按方案优先级 + 缺口综合排序（遵循方案的优先级设置，而非固定血量升序）
    local function unitScore(u)
        local h, maxh = GoubayuHeal.GetUnitHealth(u)
        local miss = (maxh or 0) - (h or 0)
        if miss < 0 then miss = 0 end
        return miss * (GoubayuHeal.GetPriority(u) or 1)
    end
    table.sort(units, function(a, b)
        return unitScore(a) > unitScore(b)
    end)
    for _, u in ipairs(units) do
        if GoubayuHeal.Paladin_MeleeHealUnit(u, profileName) then
            return true
        end
    end
    return false
end

-- 是否具备近战条件：当前目标为敌对、在近战范围（5码/攻击范围）、可攻击到
-- 只检查当前 target，不做自动找敌/切换目标（避免切目标干扰治疗）
function GoubayuHeal.Paladin_MeleeAvailable()
    return UnitExists("target") and UnitCanAttack("player", "target")
        and GoubayuHeal.Paladin_CheckMeleeRange("target")
end

-- 判断单位是否在玩家10码内（Nampower精确距离；非Nampower用CheckInteractDistance(2)≈11.1码近似）
function GoubayuHeal.Paladin_WithinRange10(u, range)
    if not UnitExists(u) then
        return false
    end
    if UnitIsUnit(u, "player") then
        return true
    end
    if GetNampowerVersion and UnitXP then
        local g1 = GoubayuHeal.GetUnitGUID("player")
        local g2 = GoubayuHeal.GetUnitGUID(u)
        if g1 and g2 then
            -- 与同文件 CheckMeleeRange 同口径：pcall 防个别版本参数差异报错
            local ok, d = pcall(UnitXP, "distanceBetween", g1, g2)
            if ok and d and type(d) == "number" and d <= (range or 10) then
                return true
            end
        end
    end
    if CheckInteractDistance and CheckInteractDistance(u, 2) then
        return true
    end
    return false
end

-- 神圣打击群疗触发条件参数（范围码/最少人数/最小掉血量）
-- 取值：技能编辑窗口"群疗条件覆盖"（按技能名 aoe_condition_override[Holy_Strike]）> 默认(10码/3人/200)
-- 近战奶 与 方案(Unified) 两级都走这里，统一采用技能编辑窗的条件 by 武藤纯子酱 2026.9.6
function GoubayuHeal.Paladin_HSAoeParams()
    local C = GoubayuHeal.Config
    local ovr = C and C["aoe_condition_override"]
        and C["aoe_condition_override"][GoubayuHeal.Holy_Strike]
    local function pick(key, def)
        if ovr and ovr[key] ~= nil then
            local n = tonumber(ovr[key])
            if n then
                return n
            end
        end
        return def
    end
    return {
        range = pick("range", 10),
        count = pick("count", 3),
        missing = pick("missing", 200),
    }
end

-- 统计范围内掉血超过阈值的队友数量（团队/小队成员 + 本人 + 宠物）——神圣打击群疗触发条件
-- 范围/掉血阈值/触发人数统一采用技能编辑窗口的"群疗条件覆盖"（默认 10码/200/3人）
-- pctFrac 非空时额外要求血量百分比低于该档位（方案档）；nil=仅按缺血量（近战奶4b）
function GoubayuHeal.Paladin_HolyStrikeAoECount(pctFrac)
    local aoe = GoubayuHeal.Paladin_HSAoeParams()
    local count = 0
    local function check(u)
        -- 排除不存在/死亡/不可见单位（不可见时 GetUnitField health 可能为0或异常导致误判）
        if not UnitExists(u) or UnitIsDeadOrGhost(u) or not UnitIsVisible(u) then
            return
        end
        -- 团队/小队中指向玩家自己的单位（如 raid2 是玩家本人）不重复计数（玩家已单独统计）
        if u ~= "player" and UnitIsUnit(u, "player") then
            return
        end
        -- 自己的宠物同时是 pet 与 raidpetN（团队中），同样只计一次
        if u ~= "pet" and UnitIsUnit(u, "pet") then
            return
        end
        local h, mh = GoubayuHeal.GetUnitHealth(u)
        -- pctFrac 非空时额外要求血量百分比低于该档位（方案档）；nil=仅按缺血量（近战奶4b）
        if mh and h and h > 0 and (mh - h) > aoe.missing
            and GoubayuHeal.Paladin_WithinRange10(u, aoe.range)
            and (not pctFrac or (h / mh) < pctFrac) then
            count = count + 1
        end
    end
    check("player")
    if UnitExists("pet") then
        check("pet")
    end
    local n = GetNumRaidMembers()
    local por = "raid"
    if n == 0 then
        n = GetNumPartyMembers()
        por = "party"
    end
    for a = 1, n do
        check(por .. a)
        check(por .. "pet" .. a)
    end
    return count
end

-- 近战奶：评估神圣震击（Holy Shock，瞬发治疗技能）的方案施放条件（不施放）。
-- 返回状态表：{ met=条件是否满足, remainingCD=震击剩余CD秒, target=候选目标, rank=等级 }
-- met 与 CD 独立给出，供两处消费：
--   HolyShockFirst = met 且 CD就绪(==0) → 施放
--   十字军打击 = met 且 剩余CD≤1.5秒时让位等待（震击即将就绪），否则正常打CS
function GoubayuHeal.Paladin_HolyShockState(profileName)
    if not (profileName and GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][profileName]) then
        return { met = false }
    end
    -- 正在施法时让出，避免打断/并发
    if GoubayuHeal.Paladin_IsCasting() then
        return { met = false }
    end
    -- 周围玩家满足神圣打击群疗条件时，群疗优先，不打震击
    local aoeCond = GoubayuHeal.Paladin_HSAoeParams()
    if GoubayuHeal.Paladin_HolyStrikeAoECount() >= aoeCond.count then
        return { met = false }
    end
    -- 方案血量百分比：找方案中 Holy_shock 档位阈值（技能本身）
    local classConfig = GoubayuHeal.Config["classes"][profileName]
    if type(classConfig) ~= "table" then
        return { met = false }
    end
    local hsRank, hsThreshold
    for percent, data in pairs(classConfig) do
        if type(data) == "table" and data["Spell"] == GoubayuHeal.Holy_shock then
            local pct = tonumber(percent)
            if pct and pct > 0 and (not hsThreshold or pct < hsThreshold) then
                hsThreshold = pct
                hsRank = data["Rank"]
            end
        end
    end
    if not hsThreshold then
        return { met = false }
    end
    -- 神圣震击 spellid（用于 CD 检查 + 射程检查）
    if not GoubayuHeal.Spells or not GoubayuHeal.Spells[GoubayuHeal.Holy_shock] then
        return { met = false }
    end
    local sid = nil
    for r, data in pairs(GoubayuHeal.Spells[GoubayuHeal.Holy_shock]) do
        if type(data) == "table" and (data["SpellId"] or data["ID"]) then
            sid = GoubayuHeal.GetSpellCDId(data)
            break
        end
    end
    if not sid then
        return { met = false }
    end
    local cd = GoubayuHeal.GetSpellCooldown(sid) or 0
    -- 找血量<阈值的单位：自己/宠物（含队友宠物）/小队/团队统一按缺口×方案优先级排序（最需要治疗的优先）
    -- 候选跟随方案：优先级为 0（忽略）的单位跳过，与主治疗扫描口径一致
    local threshold = hsThreshold / 100
    local units = {}
    local function pushIfBelow(u)
        if not UnitExists(u) or UnitIsDeadOrGhost(u) or not UnitIsFriend("player", u) then
            return
        end
        -- 去重：同一单位可经多个token进入（自己的宠物同时是 pet 与 raidpetN、
        -- 玩家同时是 player 与自己的 raidN），避免候选重复计数
        for _, existing in ipairs(units) do
            if UnitIsUnit(existing, u) then
                return
            end
        end
        if (GoubayuHeal.GetPriority(u) or 0) <= 0 then
            return
        end
        local h, mh = GoubayuHeal.GetUnitHealth(u)
        if mh and h and mh > 0 and (h / mh) < threshold then
            table.insert(units, u)
        end
    end
    pushIfBelow("player")
    if UnitExists("pet") then
        pushIfBelow("pet")
    end
    local n = GetNumRaidMembers()
    local por = "raid"
    if n == 0 then
        n = GetNumPartyMembers()
        por = "party"
    end
    for a = 1, n do
        pushIfBelow(por .. a)
        pushIfBelow(por .. "pet" .. a)
    end
    if table.getn(units) == 0 then
        return { met = false, remainingCD = cd }
    end
    table.sort(units, function(a, b)
        local ha, mha = GoubayuHeal.GetUnitHealth(a)
        local hb, mhb = GoubayuHeal.GetUnitHealth(b)
        local missA = (mha or 0) - (ha or 0)
        local missB = (mhb or 0) - (hb or 0)
        return missA * (GoubayuHeal.GetPriority(a) or 1)
            > missB * (GoubayuHeal.GetPriority(b) or 1)
    end)
    local target = units[1]
    -- 补全等级：方案未配 Rank 时用最高等级（必须先确定 hsRank，避免 t[nil] 报错）
    if not hsRank then
        local hr = "1"
        local hrNum = 0
        for r, _ in pairs(GoubayuHeal.Spells[GoubayuHeal.Holy_shock]) do
            local rn = tonumber(r) or 0
            if rn > hrNum then
                hrNum = rn
                hr = r
            end
        end
        hsRank = hr
    end
    -- 射程/视野预检：有Nampower时优先用IsSpellInRange精确判断（神圣震击距离20码）
    if GetNampowerVersion and IsSpellInRange then
        local okR, inR = pcall(IsSpellInRange, sid, target)
        if okR and inR == 0 then
            return { met = false, remainingCD = cd }
        end
    end
    -- 无Nampower时回退到CanCastAtUnit（UnitXP距离判断；神圣震击默认距离20码）
    local range = 20
    if GoubayuHeal.Spells[GoubayuHeal.Holy_shock][hsRank]
        and GoubayuHeal.Spells[GoubayuHeal.Holy_shock][hsRank]["Range"]
        and GoubayuHeal.Spells[GoubayuHeal.Holy_shock][hsRank]["Range"] > 0 then
        range = GoubayuHeal.Spells[GoubayuHeal.Holy_shock][hsRank]["Range"]
    end
    if GoubayuHeal.CanCastAtUnit(target, range, sid) == false then
        return { met = false, remainingCD = cd }
    end
    return { met = true, remainingCD = cd, target = target, rank = hsRank }
end

-- 近战奶：方案设定了神圣震击血线时，条件满足且震击无CD则优先打神圣震击
-- state：可选传入已评估的 HolyShockState 结果（避免同轮重复评估）
function GoubayuHeal.Paladin_HolyShockFirst(profileName, state)
    state = state or GoubayuHeal.Paladin_HolyShockState(profileName)
    if not (state and state.met and (state.remainingCD or 0) == 0) then
        return false
    end
    -- 施放神圣震击（瞬发治疗；noscale=true 不缩放等级）；施法被门检查拒绝时如实返回 false，
    -- 让上层继续尝试十字军打击等后续动作
    return GoubayuHeal.Heal(state.target, GoubayuHeal.Holy_shock, state.rank, nil, true) or false
end

-- 近战奶审判配置：返回 所选审判debuff名/对应圣印名/是否完全不审判
-- "none"=不打任何审判；nil=智慧审判（原行为）；其余=对应审判
local function Paladin_MeleeJudgmentChoice()
    local v = GoubayuHeal.Config and GoubayuHeal.Config["paladin_melee_judgment"]
        or GoubayuHeal.Judgment_of_Wisdom
    if v == "none" then
        return nil, nil, true
    elseif v == GoubayuHeal.Judgment_of_Crusader then
        return GoubayuHeal.Judgment_of_Crusader, GoubayuHeal.Seal_of_Crusader
    elseif v == GoubayuHeal.Judgment_of_Light then
        return GoubayuHeal.Judgment_of_Light, GoubayuHeal.Seal_of_Light
    end
    return nil, nil
end

-- 近战奶骑一键主逻辑（被 ActionHeal / HealMostWounded 调用）；profileName 为治疗遵循的方案名
function GoubayuHeal.Paladin_MeleeHeal(profileName)
    if GoubayuHeal.my_class ~= GoubayuHeal.Paladin then
        return false
    end
    if not (profileName and GoubayuHeal.Config and GoubayuHeal.Config["classes"]
        and GoubayuHeal.Config["classes"][profileName]) then
        profileName = GoubayuHeal.current_class or "standard"
    end

    -- 无近战条件（无敌对目标/目标不在近战范围）：返回 false，调用方回退原始治疗方案
    if not GoubayuHeal.Paladin_MeleeAvailable() then
        return false
    end

    local meleeJudgment, meleeSeal, meleeNoJudge = Paladin_MeleeJudgmentChoice()
    -- 智慧圣印维持开关（默认开；关闭后除审判所需的对应圣印外不再给自己挂智慧圣印）
    local keepWisdom = not GoubayuHeal.Config
        or GoubayuHeal.Config["paladin_melee_keep_wisdom_seal"] ~= 0

    -- 1. 圣印维持：
    --    选了非智慧审判 → 分两种情形：
    --      a) 目标缺对应审判debuff（或目标无敌对，如刚切换目标）→ 需要上对应圣印准备审判
    --      b) 目标已有对应审判 → 回到智慧圣印正常回蓝（"挂智慧圣印"开关关闭时不回挂）
    --    未选审判（默认）→ 只保持智慧圣印（开关关闭则完全不挂圣印）
    -- 读条中跳过圣印分支（施法中放圣印会失败却吞掉本轮），落到后续治疗/审判
    if not GoubayuHeal.Paladin_IsCasting() then
        local needJudgment = meleeJudgment ~= nil
            and not (UnitExists("target") and UnitCanAttack("player", "target")
                and GoubayuHeal.UnitGotDebuff
                and GoubayuHeal.UnitGotDebuff("target", meleeJudgment))
        local wantSeal
        if needJudgment then
            wantSeal = meleeSeal
        elseif keepWisdom then
            wantSeal = GoubayuHeal.Seal_of_Wisdom
        end
        if wantSeal and not GoubayuHeal.HasBuffByName("player", wantSeal) then
            if not GoubayuHeal.IsSpellOnCooldown(wantSeal) then
                GoubayuHeal.Paladin_CleanSpellAwaitingTarget()
                CastSpellByName(wantSeal)
                return true
            end
            -- GCD占用：跳过圣印分支，落到后续治疗/审判逻辑（它们同样受GCD门控，无害）
        end
    end

    -- 2. 治疗优先：存在血线低于阈值的目标时先救人（避免被近战饿死）
    if GoubayuHeal.Paladin_MeleeHealUnitLoop(profileName) then
        return true
    end

    -- 3. 审判：两个独立触发条件，满足任一即打审判（读条中/GCD期间阻塞）：
    --    ① 自身有目标所需的圣印、且目标身上没有所选审判减益（维持目标的审判）
    --    ② 自身有目标所需的圣印、但没有"神圣制裁"buff（神圣制裁使治疗技能读条缩短1秒）
    --    滑块选"不审判"时完全跳过；十字军/光明模式下只在自己挂着对应圣印时才审判
    --    （智慧圣印状态审判会用智慧审判覆盖掉维持中的审判，禁止）
    if not meleeNoJudge and UnitExists("target") and UnitCanAttack("player", "target")
        and not GoubayuHeal.Paladin_IsCasting()
        and not GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Judgment)
        and GoubayuHeal.Paladin_CheckMeleeRange("target") then
        local wantJudgment = meleeJudgment or GoubayuHeal.Judgment_of_Wisdom
        local wantSeal = meleeSeal or GoubayuHeal.Seal_of_Wisdom
        if GoubayuHeal.HasBuffByName("player", wantSeal)
            and GoubayuHeal.UnitGotDebuff
            and (not GoubayuHeal.UnitGotDebuff("target", wantJudgment)
                or not GoubayuHeal.HasBuffByName("player", GoubayuHeal.Holy_judgement)) then
            local jid = GoubayuHeal.Paladin_FindSpellID(GoubayuHeal.Judgment)
            if jid and GoubayuHeal.GetSpellCooldown(jid) == 0 then
                local g = GoubayuHeal.Paladin_GetUnitID("target")
                if g then
                    GoubayuHeal.Paladin_CastSpellOnTarget(GoubayuHeal.Judgment, g)
                    return true
                end
            end
        end
    end

    -- 4. 神圣震击 / 神圣打击群疗 / 十字军打击（优先级：方案判定可打神圣震击 > 神圣打击群疗 > 十字军打击）
    local hsid = GoubayuHeal.Paladin_FindSpellID(GoubayuHeal.Holy_Strike)
    local cid = GoubayuHeal.Paladin_FindSpellID(GoubayuHeal.Crusader_strike)
    -- 震击状态每轮只评估一次（内含全队距离查询），4a/4c 共用
    local hsState = GoubayuHeal.Paladin_HolyShockState(profileName)
    -- 4a. 神圣震击优先：方案设了神圣震击血线且有单位掉到阈值以下时，只要周围玩家不满足神圣打击群疗
    --     且震击无CD，就优先打神圣震击（瞬发治疗）；震击进CD后才轮到十字军打击
    if GoubayuHeal.Paladin_HolyShockFirst(profileName, hsState) then
        return true
    end
    -- 4b. 神圣打击群疗：触发范围内≥N名队友（含本人/宠物）掉血超阈值时打（群疗，优先级高于十字军）
    --     触发条件由"群疗条件覆盖"/近战奶设置控制（默认10码/3人/掉血>200）
    --     "断条神圣打击"开启时：条件满足且正在读条 → 打断当前施法并本轮立即施放神圣打击
    --     （打断后若客户端仍判定施法中，本轮落空、下一轮条件仍满足会再次尝试）
    --     关闭断条时保持原行为：读条中不打群疗，落到治疗兜底
    local hsAoe = GoubayuHeal.Paladin_HSAoeParams()
    local hsReady = hsid and GoubayuHeal.GetSpellCooldown(hsid) == 0
        and not GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Holy_Strike)
        and GoubayuHeal.Paladin_CheckMeleeRange("target")
        and GoubayuHeal.Paladin_HolyStrikeAoECount() >= hsAoe.count
    if hsReady and GoubayuHeal.Paladin_IsCasting() then
        if GoubayuHeal.Config and GoubayuHeal.Config["paladin_holy_strike_interrupt"] == 1 then
            SpellStopCasting()
        else
            hsReady = false
        end
    end
    if hsReady then
        if GoubayuHeal.Paladin_HasNampower() then
            local g = GoubayuHeal.Paladin_GetUnitID("target")
            if g then
                GoubayuHeal.Paladin_CastSpellOnTarget(GoubayuHeal.Holy_Strike, g)
                return true
            end
        else
            GoubayuHeal.Paladin_CastSpellOnTarget(GoubayuHeal.Holy_Strike)
            return true
        end
    end
    -- 4c-prime. 保持1级奉献（可选）：奉献不在冷却即施放1级奉献（自中心范围填充，优先于十字军打击）
    if GoubayuHeal.Config and GoubayuHeal.Config["paladin_consecration"] == 1
        and not GoubayuHeal.Paladin_IsCasting()
        and not GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Consecration) then
        GoubayuHeal.Paladin_CleanSpellAwaitingTarget()
        CastSpellByName(GoubayuHeal.Consecration .. "(" .. GoubayuHeal.RANK .. " 1)")
        return true
    end
    -- 4c. 十字军打击（目标已可近战，直接用当前目标，避免 FindMeleeEnemy 切换目标）；近战奶固定用1级省蓝
    --     可由"十字军打击"开关关闭（关闭后只保留震击与神圣打击群疗填充）
    --     让位规则：震击方案条件满足且CD剩余≤1.5秒（即将就绪）时先等震击，不打CS；
    --     震击CD>1.5秒 或 震击条件不满足 → 正常打CS
    local csEnabled = not GoubayuHeal.Config
        or GoubayuHeal.Config["paladin_melee_crusader_strike"] ~= 0
    local shockImminent = hsState and hsState.met
        and (hsState.remainingCD or 0) > 0 and (hsState.remainingCD or 0) <= 1.5
    local csRank1 = GoubayuHeal.Crusader_strike .. "(" .. GoubayuHeal.RANK .. " 1)"
    if csEnabled and cid and GoubayuHeal.GetSpellCooldown(cid) == 0 and not GoubayuHeal.Paladin_IsCasting()
        and not GoubayuHeal.IsSpellOnCooldown(GoubayuHeal.Crusader_strike)
        and not shockImminent
        and GoubayuHeal.Paladin_CheckMeleeRange("target") then
        -- 十字军打击
        if GoubayuHeal.Paladin_HasNampower() then
            local g = GoubayuHeal.Paladin_GetUnitID("target")
            if g then
                GoubayuHeal.Paladin_CastSpellOnTarget(csRank1, g)
                return true
            end
        else
            GoubayuHeal.Paladin_CastSpellOnTarget(csRank1)
            return true
        end
    end

    -- 5. 治疗兜底（近战动作后血线仍低则补治）
    if GoubayuHeal.Paladin_MeleeHealUnitLoop(profileName) then
        return true
    end

    return false
end