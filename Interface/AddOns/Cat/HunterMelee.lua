if MPPlayerClass ~= "HUNTER" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 生存猎一键宏
-- 发布日期：2026-04-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
--
-- -------------------------------------
--
-- 功能配置：
-- 注：修改以下配置，需要在游戏中/reload，或者小退让配置生效
-- 

local AUTO_HMDPS_Trinket_Delay = 3				-- 进入战斗后，3秒后才允许使用饰品


-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化

-- 天赋 - 猎捕高手
MPHunterAdvantage = 1

-- 天赋 - 割伤
MPHunterGore = 1

-- 天赋 - 切碎
MPHunterRake = 1


-- -------------------------------------

-- 默认配置
MPHunterMeleeConfig = 1



function MPHunterMeleeDPS()

	local GS = MPSpellReady("割伤")
	local SY = MPSpellReady("猫鼬撕咬")
	local QS = MPSpellReady("切碎")
	local XJ = MPSpellReady("爆炸陷阱")
	local SB = MPSpellReady("摔绊")

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPHunterMeleeSaved[MPHunterMeleeConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 宠物攻击
	if MPHunterMeleeSaved[MPHunterMeleeConfig].PetAttack==1 and MPGetTargetDistance() then
		PetAttack()
	end

	-- 自动拾取
	if MPHunterMeleeSaved[MPHunterMeleeConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPHunterMeleeSaved[MPHunterMeleeConfig].Power==1 then
		MPCatPower()
	end


	if MPBuff("放逐术", "target") then
		return
	end


	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_HMDPS_Trinket_Delay and MPGetTargetDistance() and MPHunterMeleeSaved[MPHunterMeleeConfig].Trinket_Upper==1 then
			if MPHunterMeleeSaved[MPHunterMeleeConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPHunterMeleeSaved[MPHunterMeleeConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_HMDPS_Trinket_Delay and MPGetTargetDistance() and MPHunterMeleeSaved[MPHunterMeleeConfig].Trinket_Below==1 then
			if MPHunterMeleeSaved[MPHunterMeleeConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPHunterMeleeSaved[MPHunterMeleeConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end
		if MPHunterMeleeSaved[MPHunterMeleeConfig].Soulspeed==1 then
			if MPHunterMeleeSaved[MPHunterMeleeConfig].SoulspeedBoss==0 or (MPHunterMeleeSaved[MPHunterMeleeConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPHunterMeleeSaved[MPHunterMeleeConfig].HealthStone_Value and MPHunterMeleeSaved[MPHunterMeleeConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPHunterMeleeSaved[MPHunterMeleeConfig].HerbalTea_Value and MPHunterMeleeSaved[MPHunterMeleeConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPHunterMeleeSaved[MPHunterMeleeConfig].HerbalTeaMana_Value and MPHunterMeleeSaved[MPHunterMeleeConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end


		-- 特定 种族天赋 --

		if MPHunterMeleeSaved[MPHunterMeleeConfig].RacialTraits==1 and MPGetTargetDistance() then
			if MPHunterMeleeSaved[MPHunterMeleeConfig].RacialTraitsBoss==0 or (MPHunterMeleeSaved[MPHunterMeleeConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

		-- 急速射击
		if MPHunterMeleeSaved[MPHunterMeleeConfig].RapidFire==1 and MPSpellReady("急速射击") then
			if MPHunterMeleeSaved[MPHunterMeleeConfig].RapidFireBoss==0 or (MPHunterMeleeSaved[MPHunterMeleeConfig].RapidFireBoss==1 and MPIsBossTarget()) then
				CastSpellByName("急速射击")
			end
		end
	end




	-- 补buff
	-- 这里可能会出现buff位问题

	if MPHunterMeleeSaved[MPHunterMeleeConfig].ViperGuardian==1 then
		local mana = UnitMana("player")
		if mana < MPHunterMeleeSaved[MPHunterMeleeConfig].Viper_Value then
			if not MPBuff("蝰蛇守护") then
				CastSpellByName("蝰蛇守护")
				return
			end
		elseif mana > (MPHunterMeleeSaved[MPHunterMeleeConfig].Viper_Value+1000) then
			if MPHunterMeleeSaved[MPHunterMeleeConfig].LoneWolf==1 and not MPBuff("孤狼守护") then
				CastSpellByName("孤狼守护")
				return
			end
		else
			if MPHunterMeleeSaved[MPHunterMeleeConfig].LoneWolf==1 and not MPBuff("孤狼守护") and not MPBuff("蝰蛇守护") then
				CastSpellByName("孤狼守护")
				return
			end
		end
	else
		if MPHunterMeleeSaved[MPHunterMeleeConfig].LoneWolf==1 and not MPBuff("孤狼守护") then
			CastSpellByName("孤狼守护")
			return
		end
	end

	if MPHunterMeleeSaved[MPHunterMeleeConfig].Trueshot==1 and not MPBuff("强击光环") then
		CastSpellByName("强击光环")
	end

	if MP_UnitXP then
		if MPHunterMeleeSaved[MPHunterMeleeConfig].Rake==1 and MPHunterRake==1 and QS and MPGetTargetDistance("target", 8) then
			if UnitExists("target") and not UnitIsDeadOrGhost("target") then
				CastSpellByName("切碎")
				return
			end
		end
	else
		if MPHunterMeleeSaved[MPHunterMeleeConfig].Rake==1 and MPHunterRake==1 and QS then
			if UnitExists("target") and not UnitIsDeadOrGhost("target") then
				CastSpellByName("切碎")
				return
			end
		end
	end

	if MPHunterMeleeSaved[MPHunterMeleeConfig].Gore==1 and MPHunterGore==1 and GS and MPGetHunterGoreAllow() then
		CastSpellByName("割伤")
		return
	end

	if MPHunterMeleeSaved[MPHunterMeleeConfig].RaptorStrike==1 then
		CastSpellByName("猛禽一击")
	end


	-- 是否开启陷阱了
	if MPHunterMeleeSaved[MPHunterMeleeConfig].Trap==1 and MPHunterAdvantage==1 and MPGetTargetDistance("target", 8) and XJ then

		if UnitExists("target") and not UnitIsDeadOrGhost("target") then

			if MPHunterMeleeSaved[MPHunterMeleeConfig].ExplosiveTrap==1 then
				-- 爆炸陷阱
				CastSpellByName("爆炸陷阱")
				return

			end

			if MPHunterMeleeSaved[MPHunterMeleeConfig].ImmolationTrap==1 then
				-- 献祭陷阱
				CastSpellByName("献祭陷阱")
				return

			end
		
			if MPHunterMeleeSaved[MPHunterMeleeConfig].AutoTrap==1 then
				-- 自动陷阱
				if MPScanNearbyEnemiesCount(5) > 1 then
					CastSpellByName("爆炸陷阱")
					return
				else
					CastSpellByName("献祭陷阱")
					return
				end
			end

		end

	end

	if MPHunterMeleeSaved[MPHunterMeleeConfig].MeerkatsBiting==1 and SY then
		CastSpellByName("猫鼬撕咬")
		return
	end

	if MPHunterMeleeSaved[MPHunterMeleeConfig].Rake==1 and MPHunterRake==1 and QS then
		if UnitExists("target") and not UnitIsDeadOrGhost("target") and MPGetTargetDistance("target", 9) then
			CastSpellByName("切碎")
			return
		end
	end



	if MPHunterMeleeSaved[MPHunterMeleeConfig].WingClip==1 and SB then
		CastSpellByName("摔绊")
	end


end

