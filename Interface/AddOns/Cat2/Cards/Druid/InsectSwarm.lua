-- 卡片数据定义。
local card = {
    -- 稳定唯一标识；用于后续保存流程与跨版本迁移。
    id = "druid_insect_swarm",
    -- 界面中显示的卡片标题。
    name = "虫群",
    -- 卡片标题下方显示的简短说明。
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，补虫群",
    -- 预留给后续详情面板或 Tooltip 的完整功能说明。
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。施放自然持续伤害。需要存在有效目标；目标自然免疫时不会施放。成功执行时会阻断本轮后续卡片。",
    -- 同一分类内按升序排列；建议留出间隙以便新增卡片。
    sort = 112,
    -- 仅能是 common、item、class 三种分类之一。
    category = "class",
    canStopSequence = true,
    -- 游戏职业文件代码；仅职业卡需要设置。
    classes = {
        DRUID = 1,
    },
    -- 魔兽客户端图标纹理路径。
    optionSchema = {
        {
            key = "minimumTargetHealth",
            type = "number",
            label = "目标血量",
            shortLabel = "血量",
            default = 100,
            minimum = 0,
            maximum = 1000000,
            integer = true,
        },
    },
    icons = {
        "Interface\\Icons\\Spell_Nature_InsectSwarm",
    },
}

-- 插件启动时注册卡片后调用一次。
function card.RefreshRuntimeData()
end

-- 返回后续流程执行器读取的动作描述。
function card.Execute(context, step)
    local minimumTargetHealth = context:GetStepOption(step, "minimumTargetHealth") or 100
    if (context.playerInformation.temporary.targetHealth or 0) <= minimumTargetHealth then
        return false
    end

    local player = Cat2.PlayerInformation.temporary

    -- 没目标就无需继续
    if not player.targetExists then
        return false
    end

    -- 目标自然免疫时，不再尝试施放自然伤害技能
    if Cat2.IsNatureImmune() then
        return false
    end

    if not Cat2.GetInsectSwarmDot() then
        Cat2.Cast("虫群")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
