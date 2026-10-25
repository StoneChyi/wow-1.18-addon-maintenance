-- 防护暗影结界 技能卡片。
local card = {
    id = "warlock_shadow_ward",
    name = "防护暗影结界",
    description = "冷却后，施放防护暗影结界",
    details = "冷却后，施放防护暗影结界。仅在技能可用时尝试执行。成功执行时会阻断本轮后续卡片。",
    sort = 50.09,
    category = "class",
    classes = {
        WARLOCK = 2,
    },
    icons = {
        "Interface\\Icons\\Spell_Shadow_AntiShadow",
    },
    cooldown = {
        type = "spell",
        name = "防护暗影结界",
    },
}

function card.RefreshRuntimeData()
end

function card.Execute(context)

    if Cat2.SpellReady("防护暗影结界") then
        Cat2.Cast("防护暗影结界")
        return true
    end

    return false

end

Cat2.RegisterCard(card)
