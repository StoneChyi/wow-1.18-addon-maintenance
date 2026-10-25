-- 暗言术：痛（多线DOT）：沿用术士多线卡的扫描与无目标施法机制。
local card = {
    id = "priest_shadow_word_pain_multi_dot",
    name = "暗言术：痛（多线DOT）",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，多目标补DOT",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。逐个检查扫描到的敌人，不受当前选中目标血量影响。扫描暗言术：痛射程内的敌人，并对其中没有暗言术：痛且不免疫暗影伤害的目标施放，无需预先选中目标，施法后恢复原目标。需要SuperWoW；引导期间跳过，每次执行最多成功提交一次施法，随后阻断本轮后续卡片。启用“多线DOT 仅战斗中敌人”被动卡后，只选择已处于战斗中的敌人；未启用时也可能选择未进入战斗的敌人。",
    sort = 157,
    category = "class",
    classes = {
        PRIEST = 3,
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
        "Interface\\Icons\\Spell_Shadow_ShadowWordPain",
        "Interface\\Icons\\Spell_Fire_Flare",
    },
}

local distance = 30

function card.RefreshRuntimeData()
    local painDuration = 18 + Cat2.IsTalentLearned(3, 4) * 3
    if Cat2.CheckInventoryItemName(13, "休眠腐化之眼") then painDuration = painDuration + 3 end
    if Cat2.CheckInventoryItemName(14, "休眠腐化之眼") then painDuration = painDuration + 3 end
    Cat2.SetPainDuration(painDuration)

    distance = tonumber(Cat2.Match(Cat2.GetSpellTooltip("暗言术：痛", "等级 1"), "(%d+)码距离")) or 30
end

function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100

    if not Cat2.SuperWoW then
        return false
    end

    -- 无目标施法入口直接调用 CastSpellByName，避免打断正在引导的精神鞭笞等技能。
    if Cat2.GetChanneled() >= 0.08 then
        return false
    end

    local count, _, enemyList = Cat2.ScanNearbyEnemies(distance)
    if count <= 0 then
        return false
    end

    local requireCombatTarget = context and context.parameters and context.parameters.multiDotOnlyCombatEnemies
    for guid, _ in pairs(enemyList) do
        if UnitExists(guid) and UnitCanAttack("player", guid) and not UnitIsDeadOrGhost(guid)
            and (UnitHealth(guid) or 0) > minimumTargetHealth
            and (not requireCombatTarget or UnitAffectingCombat(guid)) then
            if not Cat2.Buff("暗言术：痛", guid) and not Cat2.IsShadowImmune(guid) then
                if Cat2.CastSpellWithoutTarget("暗言术：痛", guid) then
                    return true
                end
            end
        end
    end

    return false
end

Cat2.RegisterCard(card)
