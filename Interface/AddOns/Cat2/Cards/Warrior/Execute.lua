-- 斩杀 技能卡片。
local card = {
    id = "warrior_execute",
    name = "斩杀",
    description = "怒气<=|cff6bc7e0{maximumRage}|r且目标血量进入斩杀线时，施放斩杀",
    details = "当前怒气不高于设定上限且满足原有斩杀条件时施放，怒气上限范围10–130，默认130。需要存在有效目标，并达到斩杀自身的最低怒气消耗。启用“斩杀时中断读条”后，施放前会中断猛击读条。成功执行时会阻断本轮后续卡片。",
    sort = 95,
    category = "class",
    classes = {
        WARRIOR = 2,
    },
    icons = {
        "Interface\\Icons\\INV_Sword_48",
    },
    optionSchema = {
        { key = "maximumRage", type = "number", label = "怒气上限", shortLabel = "怒", unit = "怒气",
            default = 130, minimum = 10, maximum = 130 },
    },
}

local powerExecute = 15

function card.RefreshRuntimeData()

    powerExecute = 15

    if Cat2.IsTalentLearned(2,13) == 1 then
        powerExecute = powerExecute - 2
    elseif Cat2.IsTalentLearned(2,13) == 2 then
        powerExecute = powerExecute - 5
    end

end

function card.Execute(context, step)

    local player = Cat2.PlayerInformation.temporary
    local maximumRage = context:GetStepOption(step, "maximumRage") or 130

    -- 没有目标时无需继续。
    if not player.targetExists then
        return false
    end

    if Cat2.GetShapeByName("防御姿态") then
        return false
    end

    if player.power>=powerExecute and player.power<=maximumRage and player.targetPercentHealth<19.9 then
        if context.parameters.warriorInterruptCastForExecute then
            if Cat2.GetIsCast() then
                SpellStopCasting()
            end
        end
        Cat2.Cast("斩杀")
        return true
    end

end

Cat2.RegisterCard(card)
