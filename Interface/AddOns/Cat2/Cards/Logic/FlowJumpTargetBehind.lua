-- 目标位于玩家背面时，跳转到指定流程编号。
local card = {
    id = "logic_flow_jump_target_behind",
    name = "目标处于背面 跳转流程",
    description = "目标处于玩家背面时，跳转到第|cff6bc7e0{targetIndex}|r张卡片",
    details = "需要UnitXP支持。存在目标且确认目标位于玩家背面时跳转；无目标、无法判定方位或目标位于玩家正面时继续下一张卡片。按玩家朝向判断目标所在方位。编号为1至60的整数，默认60，允许向前或向后跳转。目标编号不存在时提示并终止本轮；每轮最多执行60步。",
    sort = 61.2,
    category = "logic",
    behavior = "logic",
    canStopSequence = true,
    icons = {
        "Interface\\Icons\\INV_Misc_Wrench_01",
        "Interface\\Icons\\item_skin_token",
    },
    optionSchema = {
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
    local player = context.playerInformation.temporary
    if not player.targetExists or not Cat2.UnitXP then
        return false
    end
    if UnitXP("behind", "target", "player") == true then
        return Cat2.JumpTo(context:GetStepOption(step, "targetIndex"))
    end
    return false
end

Cat2.RegisterCard(card)
