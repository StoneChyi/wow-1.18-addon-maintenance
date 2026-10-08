if MPPlayerClass ~= "PRIEST" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 暗牧一键宏
-- 更新日期：2026-08-12 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：无
--
-- 说明：
-- 
-- -------------------------------------
--
-- 功能配置：

-- 以下功能开关：1开启 0关闭


-- -------------------------------------

-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化

-- 责罚 天赋
MPPriestChastise = 1

-- 神圣之火 施法状态
MPCastHolyFireTimer = 0

-- -------------------------------------

local MHP,DM,ZF,QF

-- 默认配置
MPPriestDConfig = 1


-- 神圣之火
local function MPCastHolyFire()
	MPCastWithoutNampower("神圣之火")
end

-- 心灵之火
local function MPCastInnerFire()
	MPCastWithoutNampower("心灵之火")
end



function MPPriestDiscipline()


	MHP = UnitHealth("player")
	DM = UnitMana("player")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100

	ZF = MPSpellReady("责罚")
	QF = MPSpellReady("启发")

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPPriestDisciplineSaved[MPPriestDConfig].Target, 0)

	-- 开启自动攻击
	if MPPriestDisciplineSaved[MPPriestDConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPPriestDisciplineSaved[MPPriestDConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPPriestDisciplineSaved[MPPriestDConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPPriestDisciplineSaved[MPPriestDConfig].Trinket_Upper==1 then
			if MPPriestDisciplineSaved[MPPriestDConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPPriestDisciplineSaved[MPPriestDConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPPriestDisciplineSaved[MPPriestDConfig].Trinket_Below==1 then
			if MPPriestDisciplineSaved[MPPriestDConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPPriestDisciplineSaved[MPPriestDConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPPriestDisciplineSaved[MPPriestDConfig].Soulspeed==1 then
			if MPPriestDisciplineSaved[MPPriestDConfig].SoulspeedBoss==0 or (MPPriestDisciplineSaved[MPPriestDConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		if percent<MPPriestDisciplineSaved[MPPriestDConfig].HealthStone_Value and MPPriestDisciplineSaved[MPPriestDConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPPriestDisciplineSaved[MPPriestDConfig].HerbalTea_Value and MPPriestDisciplineSaved[MPPriestDConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPPriestDisciplineSaved[MPPriestDConfig].HerbalTeaMana_Value and MPPriestDisciplineSaved[MPPriestDConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		-- 特定 种族天赋 --

		if MPPriestDisciplineSaved[MPPriestDConfig].RacialTraits==1 then
			if MPPriestDisciplineSaved[MPPriestDConfig].RacialTraitsBoss==0 or (MPPriestDisciplineSaved[MPPriestDConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
				-- 是否自动开启 人类-感知
				if MPPlayerRace=="Human" then
					local TF = MPSpellReady("感知")
					if TF then CastSpellByName("感知") end
				end

				-- 是否自动开启 兽人-血性狂怒
				if MPPlayerRace=="Orc" then
					local TF = MPSpellReady("血性狂怒")
					if TF then CastSpellByName("血性狂怒") end
				end
		
				-- 是否自动开启 巨魔-狂暴
				if MPPlayerRace=="Troll" then
					local TF = MPSpellReady("狂暴")
					if TF then CastSpellByName("狂暴") end
				end
			end
		end
	end

	-- 心灵之火
	if MPPriestDisciplineSaved[MPPriestDConfig].InnerFire==1 and not MPBuff("心灵之火") then
		MPCastInnerFire()
		return
	end

	-- 神圣之火
	if MPPriestDisciplineSaved[MPPriestDConfig].HolyFire==1 and (MPCastHolyFireTimer-GetTime())<0 then
		--MPMsg(MPCastHolyFireTimer)
		if not MPGetHolyFireDot() then
			MPCastHolyFire()
			return
		end

		-- 提前补
		local a,guid=UnitExists("target")
		if MP_SuperWoW and a then
			if MPGetHolyFireCheck(guid)<3.5 then
				MPCastHolyFire()
				return
			end
		end
	end

	-- 暗言术：痛
	if MPPriestDisciplineSaved[MPPriestDConfig].Pain==1 and not MPGetPainDot("target") then
		MPCast("暗言术：痛")
		return
	end

	-- 启发
	if MPPriestDisciplineSaved[MPPriestDConfig].InspireMyself==1 and QF then
		if not MPBuff("启发") then
			MPCastSpellWithoutTarget("启发","player")
			return
		end
	end

	-- 责罚
	if MPPriestDisciplineSaved[MPPriestDConfig].Chastise==1 and MPPriestChastise==1 and ZF then
		if MPPriestDisciplineSaved[MPPriestDConfig].ChastiseMyself==1 then
			if percent>=80 then
				MPCastSpellWithoutTarget("责罚","player")
				return
			end
		else
			CastSpellByName("责罚")
			return
		end
	end

	-- 惩击
	if MPPriestDisciplineSaved[MPPriestDConfig].Smite==1 then
		MPCastWithoutNampower("惩击")
		return
	end

end

