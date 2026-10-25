-- 周围敌人数量达到设定值时，跳转到指定流程编号。
local card = {
    id = "logic_flow_jump_nearby_enemy_count",
    name = "周围目标数 跳转流程",
    description = "周围8码敌人>=|cff6bc7e0{minimumEnemies}|r个时，跳转到第|cff6bc7e0{targetIndex}|r张卡片",
    details = "复用现有周围敌人扫描，数量大于或等于设定值时跳转，默认2个。需要SuperWoW；精确8码测距需要UnitXP，未启用UnitXP时沿用近距离交互判定。不要求选中当前目标；敌人数不足或未启用SuperWoW时继续下一张卡片。跳转编号为1至60的整数，默认60，允许向前或向后跳转。目标编号不存在时提示并终止本轮；每轮最多执行60步。",
    sort = 61.3,
    category = "logic",
    behavior = "logic",
    canStopSequence = true,
    icons = {
        "Interface\\Icons\\INV_Misc_Wrench_01",
        "Interface\\Icons\\Ability_Whirlwind",
    },
    optionSchema = {
        {
            key = "minimumEnemies",
            type = "number",
            label = "周围敌人数",
            shortLabel = "敌人",
            unit = "个",
            default = 2,
            minimum = 1,
            maximum = 100,
            integer = true,
        },
        {
            key = "targetIndex",
            type = "number",
            label = "跳转编号",
            shortLabel = "编号",
            default = 60,
            minimum = 1,
            maximum = 60,
            integer = true,
        },
    },
}

function card.RefreshRuntimeData()
end

function card.Execute(context, step)
    if not Cat2.SuperWoW then
        return false
    end
    local minimumEnemies = context:GetStepOption(step, "minimumEnemies") or 2
    local nearby = Cat2.ScanNearbyEnemies(8)
    if nearby >= minimumEnemies then
        return Cat2.JumpTo(context:GetStepOption(step, "targetIndex"))
    end
    return false
end

Cat2.RegisterCard(card)
