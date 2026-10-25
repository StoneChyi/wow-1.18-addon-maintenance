-- 按填写的技能名称，在冷却就绪时施放。
local card = {
    id = "common_custom_spell",
    name = "「自定义」技能",
    description = "冷却后施放|cff6bc7e0{spellName}|r",
    details = "填写完整技能名称，技能冷却就绪时尝试施放。名称为空、未学习该技能或正在引导时跳过。沿用通用施法接口，不额外限制是否存在目标；目标、距离和资源要求由技能自身决定。尝试施放后阻断本轮后续卡片。",
    sort = 48.9,
    category = "common",
    canStopSequence = true,
    icons = {
        "Interface\\Icons\\INV_Misc_Book_09",
    },
    optionSchema = {
        {
            key = "spellName",
            type = "string",
            label = "技能名称",
            shortLabel = "技能",
            default = "空",
        },
    },
}

function card.Execute(context, step)
    local spellName = context:GetStepOption(step, "spellName")
    if type(spellName) ~= "string" or spellName == "" then
        return false
    end
    if Cat2.GetChanneled() >= 0.08 then
        return false
    end
    if Cat2.SpellReady(spellName) then
        Cat2.Cast(spellName)
        return true
    end
    return false
end

Cat2.RegisterCard(card)
