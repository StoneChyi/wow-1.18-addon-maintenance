-- 潜行中固定尝试毁灭，不根据目标状态选择技能。
local card = {
    id = "druid_stealth_ravage",
    name = "潜行 毁灭",
    description = "潜行中，不触发自动攻击，直接施放毁灭",
    details = "自身存在潜行效果时停止自动攻击，并直接尝试施放毁灭。不检查目标是否存在或是否吃流血，技能自身的距离、能量等限制由游戏处理；尝试施放后阻断本轮后续卡片。未潜行时继续后续卡片。",
    sort = 410.2,
    category = "class",
    exclusiveGroup = "druid_stealth_opener",
    canStopSequence = true,
    classes = { DRUID = 2 },
    icons = { "Interface\\Icons\\Ability_Ambush", "Interface\\Icons\\Ability_Druid_Ravage" },
}

function card.Execute(context)
    if not Cat2.PlayerInformation.temporary.buff["潜行"] then return false end
    Cat2.StopAttack()
    Cat2.Cast("毁灭")
    return true
end

Cat2.RegisterCard(card)
