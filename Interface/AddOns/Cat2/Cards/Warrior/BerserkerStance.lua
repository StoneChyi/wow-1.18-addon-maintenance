-- 狂暴姿态 技能卡片。
local card = {
    id = "warrior_berserker_stance",
    name = "狂暴姿态",
    description = "切换并保持狂暴姿态",
    details = "切换并保持狂暴姿态。流程中启用“防御姿态（被强敌注视）”且其注视条件成立时跳过，条件解除后恢复保持狂暴姿态。成功执行时会阻断本轮后续卡片。",
    sort = 1,
    category = "class",
    exclusiveGroup = "warrior_stance",
    classes = {
        WARRIOR = 2,
    },
    icons = {
        "Interface\\Icons\\Ability_Racial_Avatar",
    },
}

local ShapeshiftID = 0

function card.RefreshRuntimeData()
	for i = 1, 4 do
		local _, name, _, id = GetShapeshiftFormInfo(i)
        if name and name=="狂暴姿态" then
            ShapeshiftID = i
            break
        end
	end
end

function card.Execute(context)
    if context and context.IsCardActive
        and context:IsCardActive("warrior_defensive_stance_boss_watching")
        and Cat2.IsWarriorBossWatchingPlayer() then
        return false
    end

    if ShapeshiftID > 0 then

		if not Cat2.GetShape(ShapeshiftID) then
			CastShapeshiftForm(ShapeshiftID)
			return true
		end

    else

        if not Cat2.GetShapeByName("狂暴姿态") then
            Cat2.Cast("狂暴姿态")
            return true
        end

    end

    return false
end

Cat2.RegisterCard(card)
