-- 暗言术：痛 技能卡片。
local card = {
    id = "priest_shadow_word_pain",
    name = "暗言术：痛",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，补暗言术：痛",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。对目标保持并施放暗言术：痛。需要存在有效目标；目标暗影免疫时不会施放。成功执行时会阻断本轮后续卡片。",
    sort = 20,
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
    },
}

local distance = 30

function card.RefreshRuntimeData()

    local PainDuration = 18 + Cat2.IsTalentLearned(3,4)*3
    if Cat2.CheckInventoryItemName(13,"休眠腐化之眼") then PainDuration=PainDuration+3 end
    if Cat2.CheckInventoryItemName(14,"休眠腐化之眼") then PainDuration=PainDuration+3 end

    Cat2.SetPainDuration(PainDuration)

    distance = tonumber(Cat2.Match(Cat2.GetSpellTooltip("暗言术：痛", "等级 1"), "(%d+)码距离"))
    if not distance then distance = 30 end
end

function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100
    if (context.playerInformation.temporary.targetHealth or 0) <= minimumTargetHealth then
        return false
    end


    local player = Cat2.PlayerInformation.temporary

    -- 没目标就无需继续
    if not player.targetExists then
        return false
    end

    -- 目标暗影免疫时，不再尝试施放暗影伤害技能。
    if Cat2.IsShadowImmune() then
        return false
    end

    if Cat2.UnitXP then
        local targetDistance = UnitXP("distanceBetween", "player", "target")
        if targetDistance and targetDistance > distance then
            return false
        end
    end

    if not Cat2.GetPainDot() then
        Cat2.Cast("暗言术：痛")
        return true
    end

    return false

end

Cat2.RegisterCard(card)
