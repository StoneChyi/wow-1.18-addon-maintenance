-- 当前激活的姿态或形态名称符合设定时跳转。
local card = {
    id = "logic_flow_jump_stance",
    name = "根据姿态 跳转流程",
    description = "当前姿态为|cff6bc7e0{stanceName}|r时，跳转到第|cff6bc7e0{targetIndex}|r张卡片",
    details = "填写姿态或形态的完整名称，默认战斗姿态。支持战士的战斗姿态、防御姿态、狂暴姿态，以及德鲁伊的熊形态、巨熊形态、猎豹形态等；名称须与游戏姿态栏一致。当前激活的姿态名称完全符合时跳转，无需目标；名称为空、未激活姿态或名称不符合时继续下一张卡片。跳转编号为1至60的整数，默认60，允许向前或向后跳转。目标编号不存在时提示并终止本轮；每轮最多执行60步。",
    sort = 59.78,
    category = "logic",
    behavior = "logic",
    canStopSequence = true,
    icons = { "Interface\\Icons\\INV_Misc_Wrench_01", "Interface\\Icons\\Ability_Warrior_OffensiveStance" },
    optionSchema = {
        { key = "stanceName", type = "string", label = "姿态名称", shortLabel = "姿态", default = "战斗姿态" },
        { key = "targetIndex", type = "number", label = "跳转编号", shortLabel = "编号",
            default = 60, minimum = 1, maximum = 60, integer = true },
    },
}

function card.Execute(context, step)
    local stanceName = context:GetStepOption(step, "stanceName")
    if type(stanceName) ~= "string" or stanceName == "" then return false end
    for index = 1, GetNumShapeshiftForms() do
        local _, name, active = GetShapeshiftFormInfo(index)
        if active and name == stanceName then
            return Cat2.JumpTo(context:GetStepOption(step, "targetIndex"))
        end
    end
    return false
end

Cat2.RegisterCard(card)
