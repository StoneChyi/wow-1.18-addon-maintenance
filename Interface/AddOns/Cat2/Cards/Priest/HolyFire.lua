local card = {
    id = "priest_holy_fire",
    name = "神圣之火",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，剩余|cff6bc7e0{refreshRemainingSeconds}秒|r补神圣之火",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。目标身上的神圣之火不存在或剩余时间低于卡片设定值时重新施放。默认续杯时间为3.5秒，需要存在有效目标，并保留现有的施法间隔保护。成功执行时会阻断本轮后续卡片。",
    sort = 50,
    category = "class",
    classes = {
        PRIEST = 1,
    },
    icons = {
        "Interface\\Icons\\Spell_Holy_SearingLight",
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
            default = 3.5,
            minimum = 0,
            maximum = 10,
            integer = false,
        },
    },
}

local distance = 30

function card.RefreshRuntimeData()
    distance = tonumber(Cat2.Match(Cat2.GetSpellTooltip("神圣之火", "等级 1"), "(%d+)码距离"))
    if not distance then distance = 30 end
end

function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100
    if (context.playerInformation.temporary.targetHealth or 0) <= minimumTargetHealth then
        return false
    end

    local player = Cat2.PlayerInformation.temporary
    local refreshSeconds = context:GetStepOption(step, "refreshRemainingSeconds") or 3.5

    if not player.targetExists then
        return false
    end

    if Cat2.UnitXP then
        local targetDistance = UnitXP("distanceBetween", "player", "target")
        if targetDistance and targetDistance > distance then
            return false
        end
    end

    if not Cat2.GetHolyFireDot("target", refreshSeconds) and (Cat2.GetCastHolyFireTimer() - GetTime()) < 0 then
        Cat2.Cast("神圣之火")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
