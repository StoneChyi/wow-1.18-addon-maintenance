-- 根据目标效果名称判断是否跳转，复用本轮目标快照。
local card = {
    id = "logic_flow_jump_target_no_buff",
    name = "根据目标无Buff 跳转流程",
    description = "目标不存在|cff6bc7e0{buffName}|r时，跳转到第|cff6bc7e0{targetIndex}|r张卡片",
    details = "填写Buff完整名称，默认放逐术；沿用目标快照，包含增益和减益效果。存在目标且目标不存在该效果时跳转，无目标、名称为空或快照不可用时继续下一张卡片。跳转编号为1至60的整数，默认60，允许向前或向后跳转。目标编号不存在时提示并终止本轮；每轮最多执行60步。",
    sort = 59.82,
    category = "logic",
    behavior = "logic",
    canStopSequence = true,
    icons = { "Interface\\Icons\\INV_Misc_Wrench_01", "Interface\\Icons\\Spell_Holy_SearingLightPriest" },
    optionSchema = {
        { key = "buffName", type = "string", label = "Buff名称", shortLabel = "Buff", default = "放逐术" },
        { key = "targetIndex", type = "number", label = "跳转编号", shortLabel = "编号",
            default = 60, minimum = 1, maximum = 60, integer = true },
    },
}

function card.Execute(context, step)
    local player = context.playerInformation.temporary
    if not player.targetExists or type(player.targetBuff) ~= "table" then return false end
    local buffName = context:GetStepOption(step, "buffName")
    if type(buffName) ~= "string" or buffName == "" then return false end
    if not player.targetBuff[buffName] then
        return Cat2.JumpTo(context:GetStepOption(step, "targetIndex"))
    end
    return false
end

Cat2.RegisterCard(card)
