-- 暗影诅咒（邪咒，多线DOT）技能卡片。
local card = {
    id = "warlock_curse_of_shadow_hex_multi_dot",
    name = "暗影诅咒（邪咒，多线DOT）",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，多目标补DOT",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。逐个检查扫描到的敌人，不受当前选中目标血量影响。扫描暗影诅咒射程内的敌人，并对其中没有痛苦诅咒的目标无目标施放暗影诅咒。需要邪咒天赋和 SuperWoW；每轮最多选择一个敌人施放。",
    sort = 154,
    exclusiveGroup = "warlock_major_curse",
    category = "class",
    classes = {
        WARLOCK = 1,
    },
    optionSchema = {
        {
            key = "minimumTargetHealth",
            type = "number",
            label = "目标血量",
            shortLabel = "血量",
            default = 100,
            minimum = 0,
            maximum = 1000000,
            integer = true,
        },
    },
    icons = {
        "Interface\\Icons\\Spell_Shadow_CurseOfAchimonde",
        "Interface\\Icons\\Spell_Shadow_CurseOfSargeras",
        "Interface\\Icons\\Spell_Fire_Flare",
    },
}

local allowUse = 0
local distance = 30

function card.RefreshRuntimeData()
    allowUse = Cat2.IsTalentLearned(1,16)
    distance = tonumber(Cat2.Match(Cat2.GetSpellTooltip("暗影诅咒", "等级 1"), "(%d+)码距离"))
    if not distance then
        distance = 30
    end
end

function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100

    if allowUse == 0 or not Cat2.SuperWoW then
        return false
    end

    -- 无目标施法入口会直接调用 CastSpellByName，因此在这里补齐普通 Cat2.Cast 的引导保护。
    if Cat2.GetChanneled() >= 0.08 then
        return false
    end

    local count, _, enemyList = Cat2.ScanNearbyEnemies(distance)
    if count <= 0 then
        return false
    end

    local requireCombatTarget = context and context.parameters and context.parameters.warlockMultiDotOnlyCombatEnemies
    for guid, _ in pairs(enemyList) do
        if UnitExists(guid) and UnitCanAttack("player", guid) and not UnitIsDeadOrGhost(guid)
            and (UnitHealth(guid) or 0) > minimumTargetHealth
            and (not requireCombatTarget or UnitAffectingCombat(guid)) then
            local hasCurseOfAgony = Cat2.Buff("痛苦诅咒", guid)
            if not hasCurseOfAgony and not Cat2.IsShadowImmune(guid) then
                if Cat2.CastSpellWithoutTarget("暗影诅咒", guid) then
                    return true
                end
            end
        end
    end

    return false
end

Cat2.RegisterCard(card)
