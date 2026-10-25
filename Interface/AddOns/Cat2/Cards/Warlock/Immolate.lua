local card = {
    id = "warlock_immolate",
    name = "献祭",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，剩余|cff6bc7e0{refreshRemainingSeconds}秒|r补献祭",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。目标身上的献祭剩余时间低于设定值时重新施放，并保留现有的引导保护机制。需要存在有效目标；目标火焰免疫时不会施放。成功执行时会阻断本轮后续卡片。",
    sort = 20,
    category = "class",
    classes = {
        WARLOCK = 3,
    },
    icons = {
        "Interface\\Icons\\Spell_Fire_Immolation",
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
        {
            key = "refreshRemainingSeconds",
            type = "number",
            label = "剩余时间",
            shortLabel = "剩余",
            unit = "秒",
            default = 1.5,
            minimum = 0,
            maximum = 15,
            integer = false,
        },
    },
}

local distance = 30

function card.RefreshRuntimeData()
    distance = tonumber(Cat2.Match(Cat2.GetSpellTooltip("献祭", "等级 1"), "(%d+)码距离"))
    if not distance then
        distance = 30
    end
end

function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100
    if (context.playerInformation.temporary.targetHealth or 0) <= minimumTargetHealth then
        return false
    end

    local player = Cat2.PlayerInformation.temporary
    local refreshSeconds = context:GetStepOption(step, "refreshRemainingSeconds") or 1.5

    if not player.targetExists then
        return false
    end

    -- 目标火焰免疫时，不再尝试施放火焰伤害技能。
    if Cat2.IsFireImmune() then
        return false
    end

    if Cat2.UnitXP then
        local targetDistance = UnitXP("distanceBetween", "player", "target")
        if targetDistance and targetDistance > distance then
            return false
        end
    end

    if not Cat2.GetImmolateDot("target", refreshSeconds) and (GetTime() - Cat2.GetImmolateTimer()) > 0 then
        Cat2.Cast("献祭")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
