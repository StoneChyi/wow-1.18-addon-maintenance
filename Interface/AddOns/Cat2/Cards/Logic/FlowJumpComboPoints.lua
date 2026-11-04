-- 当前目标的连击点命中任一勾选星级时跳转；五个选项彼此独立。
local comboPointOptions = { "comboPoints1", "comboPoints2", "comboPoints3", "comboPoints4", "comboPoints5" }
local card = {
    id = "logic_flow_jump_combo_points",
    name = "根据连击点 跳转",
    description = "连击点为|cff6bc7e0X|r星时，跳转到第|cff6bc7e0{targetIndex}|r张卡片",
    details = "一星、二星、三星、四星、五星可以分别勾选，也可以同时勾选多个；当前目标的连击点命中任一勾选星级时跳转。默认仅勾选五星。全部取消、没有目标、零星或星级未勾选时继续下一张卡片。摘要中的X代表可在参数中修改的星级。跳转编号为1至60的整数，默认60，允许向前或向后跳转。目标编号不存在时提示并终止本轮；每轮最多执行60步。",
    sort = 59.79,
    category = "logic",
    behavior = "logic",
    canStopSequence = true,
    icons = { "Interface\\Icons\\INV_Misc_Wrench_01", "Interface\\Icons\\Ability_Rogue_Eviscerate" },
    optionSchema = {
        { key = "comboPoints1", type = "boolean", control = "checkbox", label = "一星", default = false },
        { key = "comboPoints2", type = "boolean", control = "checkbox", label = "二星", default = false },
        { key = "comboPoints3", type = "boolean", control = "checkbox", label = "三星", default = false },
        { key = "comboPoints4", type = "boolean", control = "checkbox", label = "四星", default = false },
        { key = "comboPoints5", type = "boolean", control = "checkbox", label = "五星", default = true },
        { key = "targetIndex", type = "number", label = "跳转编号", shortLabel = "编号",
            default = 60, minimum = 1, maximum = 60, integer = true },
    },
}

function card.Execute(context, step)
    local player = context.playerInformation.temporary
    if not player.targetExists then return false end
    local comboPoints = player.targetCombo
    if type(comboPoints) ~= "number" or comboPoints < 1 or comboPoints > 5 then return false end
    local optionKey = comboPointOptions[comboPoints]
    if optionKey and context:GetStepOption(step, optionKey) == true then
        return Cat2.JumpTo(context:GetStepOption(step, "targetIndex"))
    end
    return false
end

Cat2.RegisterCard(card)
