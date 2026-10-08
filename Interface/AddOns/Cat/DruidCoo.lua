if MPPlayerClass ~= "DRUID" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 鸟德一键宏
-- 更新日期：2026-07-29 （后面根据时间来判断版本）
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
local AUTO_COO_Use_Trinket = 1				-- 饰品总开关，是否自动使用爆发饰品

-- -------------------------------------

-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化


-- -------------------------------------
local playerBuffs
local targetBuffs

local MHP,DM
local TargetBOSS = false

-- 默认配置
MPDruidCooConfig = 1


local function MPCastMoonfire()
	if MPDruidCOOSaved[MPDruidCooConfig].MILevel==0 then

		if DM>2000 then
			CastSpellByName("月火术")
		elseif DM>1000 then
			CastSpellByName("月火术(等级 6)")
		else
			CastSpellByName("月火术(等级 2)")
			--print("月火术(等级 2)")
		end

	elseif MPDruidCOOSaved[MPDruidCooConfig].MILevel==1 then
		CastSpellByName("月火术(等级 2)")
	elseif MPDruidCOOSaved[MPDruidCooConfig].MILevel==2 then
		CastSpellByName("月火术(等级 6)")
	elseif MPDruidCOOSaved[MPDruidCooConfig].MILevel==3 then
		CastSpellByName("月火术")
	end
end

local function MPCastInsectSwarm()
	if MPDruidCOOSaved[MPDruidCooConfig].MILevel==0 then

		if DM>2000 then
			CastSpellByName("虫群")
		elseif DM>1000 then
			CastSpellByName("虫群(等级 3)")
		else
			CastSpellByName("虫群(等级 1)")
			--print("虫群(等级 1)")
		end

	elseif MPDruidCOOSaved[MPDruidCooConfig].MILevel==1 then
		CastSpellByName("虫群(等级 1)")
	elseif MPDruidCOOSaved[MPDruidCooConfig].MILevel==2 then
		CastSpellByName("虫群(等级 3)")
	elseif MPDruidCOOSaved[MPDruidCooConfig].MILevel==3 then
		CastSpellByName("虫群")
	end

	--CastSpellByName("虫群")
end


local function MPCastWrath()

	-- 补 虫群
	if MPDruidCOOSaved[MPDruidCooConfig].InsectSwarm==1 and not MPGetInsectSwarmDot() then
		if MPDruidCOOSaved[MPDruidCooConfig].InsectSwarmBoss==0 or (MPDruidCOOSaved[MPDruidCooConfig].InsectSwarmBoss==1 and TargetBOSS) then
			MPCastInsectSwarm() -- 虫群
			return
		end
	end

	if DM>=MPDruidWrathMana then
		MPCastWithoutNampower("愤怒")
	else
		MPCastWithoutNampower("愤怒(等级 1)")
	end
end

local function MPCastStarfire()

	-- 补 月火术
	if MPDruidCOOSaved[MPDruidCooConfig].Moonfire==1 and not MPGetMoonfireDot() then
		if MPDruidCOOSaved[MPDruidCooConfig].MoonfireBoss==0 or (MPDruidCOOSaved[MPDruidCooConfig].MoonfireBoss==1 and TargetBOSS) then
			MPCastMoonfire() -- 月火术
			return
		end
	end

	if DM>=MPDruidStarfireMana then
		MPCastWithoutNampower("星火术")
	else
		MPCastWithoutNampower("星火术(等级 1)")
	end
end


function MPCoo()

	MHP = UnitHealth("player")
	DM = MPDruidMana()
	TargetBOSS = MPIsBossTarget()
	playerBuffs = MPBuffList()
	targetBuffs = MPBuffList("target")

	-- 确保在枭兽形态下
	if MPDruidCOOSaved[MPDruidCooConfig].Shapeshift==1 and MPDruidCooShapeshiftID>0 then
		if not MPGetShape(MPDruidCooShapeshiftID) then
			CastShapeshiftForm(MPDruidCooShapeshiftID)
		end
	end


	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPDruidCOOSaved[MPDruidCooConfig].Target, 2)

	-- 开启自动攻击
	if MPDruidCOOSaved[MPDruidCooConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPDruidCOOSaved[MPDruidCooConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPDruidCOOSaved[MPDruidCooConfig].Power==1 then
		MPCatPower()
	end

	if not UnitExists("target") then return end

	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if MP_Trinket_Upper==1 and MPDruidCOOSaved[MPDruidCooConfig].Trinket_Upper==1 and GetInventoryItemCooldown("player",13)==0 then
			if MPDruidCOOSaved[MPDruidCooConfig].TUBoss==1 and TargetBOSS then
				UseInventoryItem(13)
			elseif MPDruidCOOSaved[MPDruidCooConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if MP_Trinket_Below==1 and MPDruidCOOSaved[MPDruidCooConfig].Trinket_Below==1 and GetInventoryItemCooldown("player",14)==0 then
			if MPDruidCOOSaved[MPDruidCooConfig].TBBoss==1 and TargetBOSS then
				UseInventoryItem(14)
			elseif MPDruidCOOSaved[MPDruidCooConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPDruidCOOSaved[MPDruidCooConfig].Soulspeed==1 then
			if MPDruidCOOSaved[MPDruidCooConfig].SoulspeedBoss==1 and TargetBOSS then
				MPUseItemByNameToSelf("魂能之速")
			elseif MPDruidCOOSaved[MPDruidCooConfig].SoulspeedBoss==0 then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPDruidCOOSaved[MPDruidCooConfig].HealthStone_Value and MPDruidCOOSaved[MPDruidCooConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPDruidCOOSaved[MPDruidCooConfig].HerbalTea_Value and MPDruidCOOSaved[MPDruidCooConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPDruidCOOSaved[MPDruidCooConfig].HerbalTeaMana_Value and MPDruidCOOSaved[MPDruidCooConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

	end

	if not MPInCombat and MPDruidCOOSaved[MPDruidCooConfig].FirstStarfire==1 then
		MPCastStarfire()
		return
	end



	-- 补 精灵之火
	if MPDruidCOOSaved[MPDruidCooConfig].FaerieFire==1 and not targetBuffs["精灵之火（野性）"] and not targetBuffs["精灵之火"] then
		if MPDruidCOOSaved[MPDruidCooConfig].FaerieFireBOSS==0 or (MPDruidCOOSaved[MPDruidCooConfig].FaerieFireBOSS==1 and TargetBOSS) then
			CastSpellByName("精灵之火")
		end
	end


	if MPDruidCOOSaved[MPDruidCooConfig].Strategy==1 then

		-- 日月蚀触发，优先

		if playerBuffs["月蚀"] then

			MPCastStarfire() -- 星火术

		elseif playerBuffs["日蚀"] then

			MPCastWrath() -- 愤怒

		elseif playerBuffs["昼至"] then

			MPCastStarfire() -- 星火术

		elseif playerBuffs["夜至"] then

			MPCastWrath() -- 愤怒

		else

			MPCastWrath() -- 愤怒

		end

	else
	
		-- 愤怒偏向

		if playerBuffs["月蚀"] then

			MPCastStarfire() -- 星火术

		else

			MPCastWrath() -- 愤怒

		end

	end


end


