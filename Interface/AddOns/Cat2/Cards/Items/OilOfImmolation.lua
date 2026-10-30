-- 献祭之油：敌人数达标且自身没有火焰之盾时使用。
local card = {
    id = "item_oil_of_immolation",
    name = "献祭之油",
    description = "周围敌人>=|cff6bc7e0{enemyThreshold}|r且没有火焰之盾时使用，需SuperWoW",
    details = "自身周围8码内敌人数达到设定值，且自己身上没有火焰之盾Buff、物品冷却就绪时使用献祭之油。敌人数阈值默认1，范围1–40。敌人扫描需要SuperWoW支持。成功使用时会阻断本轮后续卡片。",
    sort = 149.9,
    category = "item",
    canStopSequence = true,
    icons = { "Interface\\Icons\\INV_Potion_11" },
    cooldown = { type = "item", name = "献祭之油" },
    optionSchema = {
        { key = "enemyThreshold", type = "number", label = "敌人数阈值", shortLabel = "敌",
            default = 1, minimum = 1, maximum = 40 },
    },
}

function card.Execute(context, step)
    -- 引导期间跳过，避免使用物品或爆发技能打断当前引导。
    if Cat2.GetChanneled() > 0 then
        return false
    end

    local player = Cat2.PlayerInformation.temporary
    if player.buff["火焰之盾"] then return false end

    local enemyThreshold = context:GetStepOption(step, "enemyThreshold") or 1
    if Cat2.ScanNearbyEnemies(8) < enemyThreshold then return false end

    if Cat2.GetItemByNameCD("献祭之油") and Cat2.UseItemByName("献祭之油") then
        return true
    end
    return false
end

Cat2.RegisterCard(card)
