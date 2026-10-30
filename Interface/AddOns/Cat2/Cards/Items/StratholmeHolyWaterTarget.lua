-- 斯坦索姆圣水（目标）消耗品卡片。
-- 使用与致密炸弹（目标）相同的 UnitXP 定点投掷机制。
local card = {
    id = "item_stratholme_holy_water_target",
    name = "斯坦索姆圣水（目标）",
    description = "以目标为投掷位置使用圣水，需UnitXP202607以上",
    details = "物品冷却完成且存在有效目标时，以目标为投掷位置使用斯坦索姆圣水。需要 UnitXP 202607 以上版本支持；成功执行时会阻断本轮后续卡片。",
    sort = 1002,
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

function card.Execute(context)
    -- 引导期间跳过，避免使用物品或爆发技能打断当前引导。
    if Cat2.GetChanneled() > 0 then
        return false
    end


    if allowUse == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8000当前UnitXP模块版本不支持！|r")
        return false
    end

    local player = Cat2.PlayerInformation.temporary
    if not player.targetExists then
        return false
    end

    if not Cat2.GetItemByNameCD("斯坦索姆圣水") then
        return false
    end

    if Cat2.UseItemByName("斯坦索姆圣水") then
        UnitXP("castAOE", "target")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
