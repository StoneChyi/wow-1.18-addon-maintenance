-- 虫群（日蚀）：仅在玩家拥有日蚀 Buff 时执行原虫群逻辑。
local card = {
    id = "druid_insect_swarm_solar_eclipse",
    name = "虫群（日蚀）",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，日蚀时补虫群",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。仅在日蚀生效时执行虫群的原有逻辑。需要存在有效目标；目标自然免疫或已有虫群效果时不会施放。成功执行时会阻断本轮后续卡片。",
    -- 紧随原“虫群”卡片。
    sort = 113,
    category = "class",
    canStopSequence = true,
    classes = {
        DRUID = 1,
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
        "Interface\\Icons\\Spell_Nature_InsectSwarm",
        "Interface\\Icons\\Spell_Nature_AbolishMagic",
    },
}

function card.RefreshRuntimeData()
end

function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100
    if (context.playerInformation.temporary.targetHealth or 0) <= minimumTargetHealth then
        return false
    end

    local player = Cat2.PlayerInformation.temporary

    if not player.targetExists then
        return false
    end

    if not player.buff["日蚀"] then
        return false
    end

    if Cat2.IsNatureImmune() then
        return false
    end

    if not Cat2.GetInsectSwarmDot() then
        Cat2.Cast("虫群")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
