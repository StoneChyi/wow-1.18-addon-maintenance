-- 被当前强敌注视时切换防御姿态。
local card = {
    id = "warrior_defensive_stance_boss_watching",
    name = "防御姿态（被强敌注视）",
    description = "战斗中被当前强敌注视时切换防御姿态",
    details = "战斗中，当前目标符合插件统一强敌判定，且目标的目标是自己时，切换至防御姿态。可与常驻姿态卡同时启用：本卡启用且注视条件成立时，战斗姿态和狂暴姿态保持卡跳过，不受排列先后影响；已经处于防御姿态时继续后续卡片。条件不再成立时，常驻姿态卡恢复执行。没有可配置参数。成功切换时会阻断本轮后续卡片。",
    sort = 10.1,
    category = "class",
    canStopSequence = true,
    classes = {
        WARRIOR = 3,
    },
    icons = {
        "Interface\\Icons\\Ability_Warrior_DefensiveStance",
    },
}

local ShapeshiftID = 0

function card.RefreshRuntimeData()
    ShapeshiftID = 0
	for i = 1, 4 do
		local _, name, _, id = GetShapeshiftFormInfo(i)
        if name and name=="防御姿态" then
            ShapeshiftID = i
            break
        end
	end
end

-- 常驻姿态卡与条件防御卡共用触发条件，已经处于防御姿态时仍应保持优先级。
function Cat2.IsWarriorBossWatchingPlayer()
    local player = Cat2.PlayerInformation.temporary
    if not player.inCombat or not player.targetExists or not Cat2.IsBossTarget() then
        return false
    end
    return UnitExists("targettarget") and UnitIsUnit("targettarget", "player") and true or false
end

function card.Execute(context)
    if not Cat2.IsWarriorBossWatchingPlayer() then return false end

    if ShapeshiftID > 0 then

		if not Cat2.GetShape(ShapeshiftID) then
			CastShapeshiftForm(ShapeshiftID)
			return true
		end

    else

        if not Cat2.GetShapeByName("防御姿态") then
            Cat2.Cast("防御姿态")
            return true
        end

    end

    return false
end

Cat2.RegisterCard(card)
