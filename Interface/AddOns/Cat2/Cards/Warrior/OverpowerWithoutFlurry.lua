-- 压制（无乱舞时）：复制原压制，仅增加乱舞状态限制。
local card = {
    id = "warrior_overpower_without_flurry",
    name = "压制（无乱舞时）",
    description = "无乱舞且怒气低于|cff6bc7e0{maximumRage}|r时切战斗姿态施放压制",
    details = "仅在没有乱舞Buff时执行原压制逻辑。怒气低于卡片设定值时，切换战斗姿态并施放压制。需要存在有效目标。会检查当前资源。仅在技能可用时尝试执行。成功执行时会阻断本轮后续卡片。",
    sort = 40.6,
    category = "class",
    classes = {
        WARRIOR = 1,
    },
    icons = {
        "Interface\\Icons\\Ability_MeleeDamage",
        "Interface\\Icons\\Ability_Warrior_OffensiveStance",
    },
    cooldown = {
        type = "spell",
        name = "压制",
    },
    optionSchema = {
        {
            key = "maximumRage",
            type = "number",
            label = "最高怒气",
            shortLabel = "怒",
            default = 30,
            minimum = 1,
            maximum = 130,
        },
    },
}

function card.RefreshRuntimeData()
end

function card.Execute(context, step)
    -- 沿用战士统一乱舞判断，包含可见Buff与事件兜底状态。
    if Cat2.WarriorFlurry() then return false end

    local player = Cat2.PlayerInformation.temporary
    local maximumRage = context:GetStepOption(step, "maximumRage") or 30

    -- 没有目标时无需继续。
    if not player.targetExists then
        return false
    end

    if Cat2.WarriorOverpower(3.2) and Cat2.SpellReadyOffset("压制",1.5) then
        if Cat2.GetShapeByName("战斗姿态") then
            Cat2.Cast("压制")
            return true
        end
    end

    -- 压制触发，CD满足
    if Cat2.WarriorOverpower(3.2) and Cat2.SpellReadyOffset("压制",1.5) and player.power>=5 and player.power<maximumRage then

        if Cat2.GetShapeByName("战斗姿态") then
            Cat2.Cast("压制")
        end

        if not Cat2.GetShapeByName("战斗姿态") then
            Cat2.Cast("战斗姿态")
        end

        return true
    end

    return false
end

Cat2.RegisterCard(card)
