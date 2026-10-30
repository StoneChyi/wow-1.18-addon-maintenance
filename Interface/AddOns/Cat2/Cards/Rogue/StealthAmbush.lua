-- 潜行中固定尝试伏击，不自动改用绞喉。
local card = {
    id = "rogue_stealth_ambush",
    name = "潜行 伏击",
    description = "潜行中，不触发自动攻击，直接施放伏击",
    details = "自身存在潜行效果时停止自动攻击，并直接尝试施放伏击。不检查目标状态或主手武器，不自动改用绞喉；技能自身的武器、距离、能量等限制由游戏处理。尝试施放后阻断本轮后续卡片，未潜行时继续后续卡片。",
    sort = 10.2,
    category = "class",
    exclusiveGroup = "rogue_stealth_opener",
    canStopSequence = true,
    classes = { ROGUE = 3 },
    icons = { "Interface\\Icons\\Ability_Stealth", "Interface\\Icons\\Ability_Rogue_Ambush" },
    cooldown = { type = "spell", name = "潜行" },
}

function card.Execute(context)
    if not Cat2.PlayerInformation.temporary.buff["潜行"] then return false end
    Cat2.StopAttack()
    Cat2.Cast("伏击")
    return true
end

Cat2.RegisterCard(card)
