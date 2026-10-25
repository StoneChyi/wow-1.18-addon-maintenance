-- 仅对恶魔强敌补充屠魔药剂。
local card = {
    id = "item_elixir_of_demonslaying_boss",
    name = "屠魔药剂 仅强敌时",
    description = "目标是恶魔强敌且自身没有屠魔药剂时使用",
    details = "当前目标存在、符合插件统一强敌判定且类型为恶魔，同时自己身上没有屠魔药剂Buff时，使用背包中的屠魔药剂。物品未就绪或不存在时跳过。成功使用时会阻断本轮后续卡片。",
    sort = 149.8,
    category = "item",
    canStopSequence = true,
    icons = { "Interface\\Icons\\INV_Potion_27" },
    cooldown = { type = "item", name = "屠魔药剂" },
}

function card.Execute(context)
    local player = Cat2.PlayerInformation.temporary
    if not player.targetExists or not Cat2.IsBossTarget() then return false end
    if player.targetCreatureType ~= "恶魔" then return false end
    if player.buff["屠魔药剂"] then return false end

    if Cat2.GetItemByNameCD("屠魔药剂") and Cat2.UseItemByName("屠魔药剂") then
        return true
    end
    return false
end

Cat2.RegisterCard(card)
