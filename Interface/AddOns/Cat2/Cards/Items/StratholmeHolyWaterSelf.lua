-- 斯坦索姆圣水（自己）消耗品卡片。
-- 使用与致密炸弹（自己）相同的 UnitXP 定点投掷机制。
local card = {
    id = "item_stratholme_holy_water_self",
    name = "斯坦索姆圣水（自己）",
    description = "周围敌人>=|cff6bc7e0{enemyThreshold}|r时，以自己为投掷位置使用圣水，需UnitXP202607以上",
    details = "物品冷却完成时，以自己为投掷位置使用斯坦索姆圣水。需要 UnitXP 202607 以上版本支持；成功执行时会阻断本轮后续卡片。使用前要求自己周围8码内敌人数达到设定值，默认1，范围1–40；敌人扫描需要SuperWoW支持。",
    sort = 1001,
    category = "item",
    exclusiveGroup = "stratholme_holy_water",
    canStopSequence = true,
    icons = {
        "Interface\\Icons\\INV_Potion_75",
    },
    cooldown = {
        type = "item",
        name = "斯坦索姆圣水",
    },
    optionSchema = {
        { key = "enemyThreshold", type = "number", label = "敌人数阈值", shortLabel = "敌",
            default = 1, minimum = 1, maximum = 40 },
    },
}

local allowUse = 0

function card.RefreshRuntimeData()

    if Cat2.UnitXP then

        local compileTime = UnitXP("version", "coffTimeDateStamp")
        if compileTime >= 1782864000 then
            allowUse = 1
        end

    end

end

function card.Execute(context, step)
    -- 引导期间跳过，避免使用物品或爆发技能打断当前引导。
    if Cat2.GetChanneled() > 0 then
        return false
    end


    if allowUse == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8000当前UnitXP模块版本不支持！|r")
        return false
    end

    if not Cat2.GetItemByNameCD("斯坦索姆圣水") then
        return false
    end

    local enemyThreshold = context:GetStepOption(step, "enemyThreshold") or 1
    if Cat2.ScanNearbyEnemies(8) < enemyThreshold then
        return false
    end

    if Cat2.UseItemByName("斯坦索姆圣水") then
        UnitXP("castAOE", "player")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
