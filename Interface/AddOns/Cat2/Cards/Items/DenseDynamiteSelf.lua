-- 致密炸弹（自己）消耗品卡片。
local card = {
    id = "item_dense_dynamite_self",
    name = "致密炸弹（自己）",
    description = "周围敌人>=|cff6bc7e0{enemyThreshold}|r时，以自己为投掷位置使用致密炸弹，需UnitXP202607以上",
    details = "物品冷却完成时，以自己为投掷位置使用致密炸弹，成功执行时会阻断本轮后续卡片。使用前要求自己周围8码内敌人数达到设定值，默认1，范围1–40；敌人扫描需要SuperWoW支持。",
    sort = 999,
    category = "item",
    exclusiveGroup = "dense_dynamite",
    canStopSequence = true,
    icons = {
        "Interface\\Icons\\INV_Misc_Bomb_06",
    },
    cooldown = {
        type = "item",
        name = "致密炸弹",
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
        if compileTime>=1782864000 then
            allowUse = 1
        end

    end

end

function card.Execute(context, step)

    -- 不存在这个模组
    if allowUse==0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8000当前UnitXP模组版本不支持！|r")
        return false
    end

    if not Cat2.GetItemByNameCD("致密炸弹") then
        return false
    end

    local enemyThreshold = context:GetStepOption(step, "enemyThreshold") or 1
    if Cat2.ScanNearbyEnemies(8) < enemyThreshold then
        return false
    end

    if Cat2.UseItemByName("致密炸弹") then
        UnitXP("castAOE", "player")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
