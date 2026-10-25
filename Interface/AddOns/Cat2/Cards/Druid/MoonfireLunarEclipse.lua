-- 月火术（月蚀）：仅在玩家拥有月蚀 Buff 时执行原月火术逻辑。
local card = {
    id = "druid_moonfire_lunar_eclipse",
    name = "月火术（月蚀）",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，月蚀时补月火术",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。仅在月蚀生效时执行月火术的原有逻辑。需要存在有效目标；目标奥术免疫或已有月火术效果时不会施放。成功执行时会阻断本轮后续卡片。",
    -- 紧随原“月火术”卡片。
    sort = 111,
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
        "Interface\\Icons\\Spell_Nature_StarFall",
        "Interface\\Icons\\Spell_Nature_WispSplode",
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

    if not player.buff["月蚀"] then
        return false
    end

    if Cat2.IsArcaneImmune() then
        return false
    end

    if not Cat2.GetMoonfireDot() then
        Cat2.Cast("月火术")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
