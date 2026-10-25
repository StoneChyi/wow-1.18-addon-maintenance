-- 卡片数据定义。
local card = {
    -- 稳定唯一标识；用于后续保存流程与跨版本迁移。
    id = "druid_rip4",
    -- 界面中显示的卡片标题。
    name = "撕扯（四星）",
    -- 卡片标题下方显示的简短说明。
    description = "目标血量>|cff6bc7e0{minimumTargetHealth}|r，补撕扯",
    -- 预留给后续详情面板或 Tooltip 的完整功能说明。
    details = "仅当施法对象当前实际血量严格大于本卡“目标血量”参数时执行，默认100；等于或低于阈值时跳过。消耗4连击点造成流血，自动识别是否吃流血。需要存在有效目标。会检查当前资源。成功执行时会阻断本轮后续卡片。",
    -- 同一分类内按升序排列；建议留出间隙以便新增卡片。
    sort = 427,
    -- 仅能是 common、item、class 三种分类之一。
    category = "class",
    canStopSequence = true,
    -- 游戏职业文件代码；仅职业卡需要设置。
    classes = {
        DRUID = 2,
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
        "Interface\\Icons\\Ability_GhoulFrenzy",
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

    local ripOnlyBoss = context and context.parameters and context.parameters.druidRipOnlyBoss
    if ripOnlyBoss and not Cat2.IsBossTarget() then
        return false
    end


    -- 不吃流血忽略
    if not player.targetBleed then
        return false
    end

    local rip = Cat2.GetRipDot()

	-- 撕扯保险
    if Cat2.SuperWoW and Cat2.PlayerInformation.basic.level==60 then
	    if rip and Cat2.GetDruidRipJumpTimer()-GetTime() < -0.5 then
		    Cat2.ResetRipDot(player.targetGUID)
            rip = false
		    DEFAULT_CHAT_FRAME:AddMessage("撕扯续杯失败，重置计时！")
	    end
    end

    if (player.power>=30 or player.buff["节能施法"]) and not rip and player.targetCombo==4 then
        Cat2.Cast("撕扯")
        return true
    end

    return false
end

Cat2.RegisterCard(card)
