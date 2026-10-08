if MPPlayerClass ~= "HUNTER" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 射击猎一键宏
-- 发布日期：2026-07-22 （后面根据时间来判断版本）
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

local AUTO_SJDPS_Trinket_Delay = 3				-- 进入战斗后，3秒后才允许使用饰品


-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化


-- 强击光环
MPHunterTrueshot = 1

-- 稳固射击
MPHunterSteadyShot = 1

-- 瞄准射击
MPHunterAimedShot = 0

-- 元素弹药
MPHunterElement = 0

-- 自动射击 周期
MPHunterShotDuration = 3
MPHunterShotTimer = 100

-- -------------------------------------


local DCSJ,KSDC,ASSJ,MZSJ

-- 默认配置
MPHunterShotConfig = 1


-- 检测自动射击是否拖出来
local function MPCheckAutoShot()
	for A=1,172 do
		local _,_,id = GetActionText(A)
		if id==75 then
			return
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."请将【自动射击】拖到技能条的任意位置！")
end

local function MPAutoShot()

	--[[
	for A=1,172 do
		if IsAutoRepeatAction(A)  then
			return
		end
	end
	]]

	if MPHunterAutoShot==0 then
		CastSpellByName("自动射击")
	end
end


function MPHunterShotDPS()

	DCSJ = MPSpellReady("多重射击")
	KSDC = MPSpellReady("蝰蛇钉刺")
	ASSJ = MPSpellReady("奥术射击")
	MZSJ = MPSpellReadyOffset("瞄准射击",1.5)


	-- 自动拾取
	if MPHunterShotSaved[MPHunterShotConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPHunterShotSaved[MPHunterShotConfig].Power==1 then
		MPCatPower()
	end

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPHunterShotSaved[MPHunterShotConfig].Target, 0)
	MPSwitchDistantTarget(MPHunterShotSaved[MPHunterShotConfig].Distant)

	-- 瞄准射击
	if MPHunterShotSaved[MPHunterShotConfig].FirstAimedShot==1 and MPHunterShotSaved[MPHunterShotConfig].AimedShot==1 and MPHunterAimedShot==1 and MZSJ and not MPInCombat then
		CastSpellByName("瞄准射击")
		return
	end


	if MPBuff("放逐术", "target") then
		return
	end

	-- 自动攻击/自动射击
	if MPGetTargetDistance() then
		MPStartAttack()
	else
		MPAutoShot()
	end

	-- 宠物攻击
	if MPHunterShotSaved[MPHunterShotConfig].PetAttack==1 and UnitAffectingCombat("target") then
		PetAttack()
	end

	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_SJDPS_Trinket_Delay and MPHunterShotSaved[MPHunterShotConfig].Trinket_Upper==1 then
			if MPHunterShotSaved[MPHunterShotConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPHunterShotSaved[MPHunterShotConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_SJDPS_Trinket_Delay and MPHunterShotSaved[MPHunterShotConfig].Trinket_Below==1 then
			if MPHunterShotSaved[MPHunterShotConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPHunterShotSaved[MPHunterShotConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end
		if MPHunterShotSaved[MPHunterShotConfig].Soulspeed==1 then
			if MPHunterShotSaved[MPHunterShotConfig].SoulspeedBoss==0 or (MPHunterShotSaved[MPHunterShotConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPHunterShotSaved[MPHunterShotConfig].HealthStone_Value and MPHunterShotSaved[MPHunterShotConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPHunterShotSaved[MPHunterShotConfig].HerbalTea_Value and MPHunterShotSaved[MPHunterShotConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPHunterShotSaved[MPHunterShotConfig].HerbalTeaMana_Value and MPHunterShotSaved[MPHunterShotConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end


		-- 特定 种族天赋 --

		if MPHunterShotSaved[MPHunterShotConfig].RacialTraits==1 then
			if MPHunterShotSaved[MPHunterShotConfig].RacialTraitsBoss==0 or (MPHunterShotSaved[MPHunterShotConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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
		if MPHunterShotSaved[MPHunterShotConfig].RapidFire==1 and MPSpellReady("急速射击") then
			if MPHunterShotSaved[MPHunterShotConfig].RapidFireBoss==0 or (MPHunterShotSaved[MPHunterShotConfig].RapidFireBoss==1 and MPIsBossTarget()) then
				CastSpellByName("急速射击")
			end
		end

	end




	-- 补buff
	if MPHunterShotSaved[MPHunterShotConfig].ViperGuardian==1 then
		local mana = UnitMana("player")
		if mana < MPHunterShotSaved[MPHunterShotConfig].Viper_Value then
			if not MPBuff("蝰蛇守护") then
				CastSpellByName("蝰蛇守护")
				return
			end
		elseif mana > (MPHunterShotSaved[MPHunterShotConfig].Viper_Value+1000) then
			if MPHunterShotSaved[MPHunterShotConfig].Hawk==1 and not MPBuff("雄鹰守护") then
				CastSpellByName("雄鹰守护")
				return
			end
		else
			-- 介于回蓝中间
			if MPHunterShotSaved[MPHunterShotConfig].Hawk==1 and not MPBuff("雄鹰守护") and not MPBuff("蝰蛇守护") then
				CastSpellByName("雄鹰守护")
				return
			end

		end
	else
		if MPHunterShotSaved[MPHunterShotConfig].Hawk==1 and not MPBuff("雄鹰守护") then
			CastSpellByName("雄鹰守护")
			return
		end
	end

	if MPHunterShotSaved[MPHunterShotConfig].Trueshot==1 and not MPBuff("强击光环") then
		CastSpellByName("强击光环")
	end

	if MPHunterShotSaved[MPHunterShotConfig].Mark==1 then
		if MPHunterShotSaved[MPHunterShotConfig].MarkBossOnly==0 or (MPHunterShotSaved[MPHunterShotConfig].MarkBossOnly==1 and MPIsBossTarget()) then
			if not MPBuff("猎人印记","target") and MPIsHunterMark() then
				CastSpellByName("猎人印记")
			end
		end
	end


	-- 被近身处理
	if MPGetTargetDistance("target",2.8) then

		if MPHunterShotSaved[MPHunterShotConfig].RaptorStrike==1 then
			CastSpellByName("猛禽一击")
		end

		if MPHunterShotSaved[MPHunterShotConfig].MeerkatsBiting==1 then
			CastSpellByName("猫鼬撕咬")
		end

	end

	-- 射击

	if MPIsMoving() then
		if MPHunterShotSaved[MPHunterShotConfig].ArcaneShot==1 and ASSJ then
			CastSpellByName("奥术射击")
		end
		if MPHunterShotSaved[MPHunterShotConfig].Serpent==1 and not MPGetSerpentStingDot() and MPIsPosion() then
			CastSpellByName("毒蛇钉刺")
		end
	end

	-- 瞄准射击 旗下条件
	if MPHunterShotSaved[MPHunterShotConfig].AimedShot==1 and MPHunterElement==1 then

		if MPGetHunterShotLeft()<1.1 and not MZSJ then

			-- 瞄准射击->火焰弹药
			if MPHunterShotSaved[MPHunterShotConfig].MultiShot==1 then
				if MPBuff("爆炸弹药") and DCSJ then
					CastSpellByName("多重射击")
					return
				end
			end

			-- 瞄准射击->奥术弹药
			if MPHunterShotSaved[MPHunterShotConfig].ArcaneShot==1 then
				if MPBuff("魔力弹药") and ASSJ and MPIsHunterArcaneShot() then
					CastSpellByName("奥术射击")
					return
				end
			end

			-- 瞄准射击->自然弹药
			if MPHunterShotSaved[MPHunterShotConfig].Serpent==1 then
				if MPBuff("剧毒弹药") and not MPGetSerpentStingDot() and MPIsPosion() then
					CastSpellByName("毒蛇钉刺")
					return
				end
			end

		end

	else

		-- 未开启瞄准射击的情况

		if MPGetHunterShotLeft()<1.1 then

			-- 瞄准射击->火焰弹药
			if MPHunterShotSaved[MPHunterShotConfig].MultiShot==1 and DCSJ then
				CastSpellByName("多重射击")
				return
			end

			-- 瞄准射击->奥术弹药
			if MPHunterShotSaved[MPHunterShotConfig].ArcaneShot==1 and ASSJ and MPIsHunterArcaneShot() then
				CastSpellByName("奥术射击")
				return
			end

			-- 瞄准射击->自然弹药
			if MPHunterShotSaved[MPHunterShotConfig].Serpent==1 and not MPGetSerpentStingDot() and MPIsPosion() then
				CastSpellByName("毒蛇钉刺")
				return
			end

		end

	end

	-- 瞄准射击
	if MPHunterShotSaved[MPHunterShotConfig].AimedShot==1 and MZSJ and MPHunterAimedShot==1 then
		if MPBuff("荷枪实弹") then
			if MPGetHunterShotLeft()>1.1 then
				MPCastWithoutNampower("瞄准射击")
				return
			end
		elseif MPBuff("急速射击") then
			if MPGetHunterShotLeft()>1.5 then
				MPCastWithoutNampower("瞄准射击")
				return
			end
		else
			if MPHunterShotSaved[MPHunterShotConfig].FullyArmed==0 then
				local range_speed = UnitRangedDamage("player")
				if MPGetHunterShotLeft()>(range_speed/2) then
					MPCastWithoutNampower("瞄准射击")
					return
				end
			end
		end
	end


	-- 蝰蛇钉刺
	if MPHunterShotSaved[MPHunterShotConfig].Viper==1 then
		local TMP = 0
		if UnitExists("target") then
			TMP = UnitManaMax("target")
		end
		if KSDC and not MPGetViperStingDot() and TMP>200 then
			CastSpellByName("蝰蛇钉刺")
			return
		end
	end


	-- 稳固射击
	if MPBuff("急速射击") then
		if MPHunterSteadyShot==1 and MPHunterShotSaved[MPHunterShotConfig].SteadyShot==1 and MPGetHunterShotLeft()>(MPHunterShotSaved[MPHunterShotConfig].SteadyShot_Value-0.4) then
			MPCastWithoutNampower("稳固射击")
			return
		end

		if MPHunterShotSaved[MPHunterShotConfig].ArcaneShot==1 and ASSJ and MPIsHunterArcaneShot() then
			CastSpellByName("奥术射击")
			return
		end
	end

	if MPHunterSteadyShot==1 and MPHunterShotSaved[MPHunterShotConfig].SteadyShot==1 and MPGetHunterShotLeft()>MPHunterShotSaved[MPHunterShotConfig].SteadyShot_Value then
		MPCastWithoutNampower("稳固射击")
		return
	end

	if not MZSJ then
		if MPHunterShotSaved[MPHunterShotConfig].ArcaneShot==1 and ASSJ and MPIsHunterArcaneShot() then
			CastSpellByName("奥术射击")
			return
		end
	end



end

