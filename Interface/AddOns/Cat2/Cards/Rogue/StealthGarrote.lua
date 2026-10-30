-- 潜行中固定尝试绞喉。
local card = {
    id = "rogue_stealth_garrote",
    name = "潜行 绞喉",
    description = "潜行中，不触发自动攻击，直接施放绞喉",
    details = "自身存在潜行效果时停止自动攻击，并直接尝试施放绞喉。不检查目标是否存在或是否吃流血，技能自身的距离、能量等限制由游戏处理；尝试施放后阻断本轮后续卡片。未潜行时继续后续卡片。",
    sort = 10.1,
    category = "class",
    exclusiveGroup = "rogue_stealth_opener",
    canStopSequence = true,
    classes = { ROGUE = 3 },
    icons = { "Interface\\Icons\\Ability_Stealth", "Interface\\Icons\\Ability_Rogue_Garrote" },
    cooldown = { type = "spell", name = "潜行" },
}

function card.Execute(context)
    if not Cat2.PlayerInformation.temporary.buff["潜行"] then return false end
    Cat2.StopAttack()
    Cat2.Cast("绞喉")
    return true
end

Cat2.RegisterCard(card)
