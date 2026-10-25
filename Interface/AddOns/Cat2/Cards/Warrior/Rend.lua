-- 撕裂 技能卡片。
local card = {
    id = "warrior_rend",
    name = "撕裂",
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，补撕裂",
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。对目标施放并保持撕裂。需要存在有效目标。会检查当前资源。成功执行时会阻断本轮后续卡片。",
    sort = 30,
    category = "class",
    classes = {
        WARRIOR = 1,
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
        "Interface\\Icons\\Ability_Gouge",
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

    -- 没有目标时无需继续。
    if not player.targetExists then
        return false
    end

    if Cat2.GetShapeByName("狂暴姿态") then
        return false
    end


    if player.power>=10 and not Cat2.WarriorRend() then
        Cat2.Cast("撕裂")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
