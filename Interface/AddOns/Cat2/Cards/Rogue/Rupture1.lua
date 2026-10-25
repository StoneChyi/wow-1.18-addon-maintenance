-- 割裂（一星）技能卡片。
local card = {
    id = "rogue_rupture_1",
    name = "割裂（一星）",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，割裂余|cff6bc7e0{refreshRemainingSeconds}秒|r时补",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。目标拥有1连击点，目标身上的割裂不存在或剩余时间低于卡片设定值时施放割裂。默认续杯时间为1秒，需要存在有效目标；目标不吃流血时不会施放。未加载SuperWoW或角色低于60级时，无法按精确剩余秒数续杯。成功执行时会阻断本轮后续卡片。",
    sort = 41,
    category = "class",
    classes = {
        ROGUE = 1,
    },
    icons = {
        "Interface\\Icons\\Ability_Rogue_Rupture",
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
            default = 1,
            minimum = 0,
            maximum = 30,
            integer = false,
        },
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
    local refreshSeconds = context:GetStepOption(step, "refreshRemainingSeconds") or 1

    if not player.targetExists then
        return false
    end

    if not player.targetBleed then
        return false
    end

    if player.targetCombo == 1 and not Cat2.GetRuptureDot(refreshSeconds) then
        Cat2.Cast("割裂")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
