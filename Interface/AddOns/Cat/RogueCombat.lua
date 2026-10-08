if MPPlayerClass ~= "ROGUE" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 战斗贼一键宏
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
-- 主开关
-- 以下功能开关：1开启 0关闭


local AUTO_RDPS_Trinket_Delay = 3			-- 进入战斗后，3秒后才允许使用饰品


-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化


-- -------------------------------------


local QG,GCP,THP,myPower,TX,XX,JRLW,DS,PJ,YG
local TargetDistance = false
local playerBuffs
local targetBuffs

-- 默认配置
MPRogueCombatConfig = 1


-- 战斗贼
function MPRogueCombatDPS()


	myPower = UnitMana("player")
	THP = UnitHealth("target")

	GCP = GetComboPoints("target")
	--JRLW = MPSpellReady("剑刃乱舞")
	BEHIND = MPCheckBehind(MPRogueCombatSaved[MPRogueCombatConfig].UnitXP)
	TX = MPSpellReady("突袭")
	YG = MPSpellReady("佯攻")
	TargetDistance = MPGetTargetDistance()
	playerBuffs = MPBuffList()
	targetBuffs = MPBuffList("target")


	-- 补充毒药
	if MPRogueCombatSaved[MPRogueCombatConfig].LeaveFight==0 or (MPRogueCombatSaved[MPRogueCombatConfig].LeaveFight==1 and not MPInCombat) then

		-- 主手
		if MPRogueCombatSaved[MPRogueCombatConfig].MainHand==1 then

			-- 获取武器信息
			local main, mc, mn = MPGetMainHandCount()

			-- 覆盖
			if MPRogueCombatSaved[MPRogueCombatConfig].Cover==1 and main then
				if mn ~= MPRogueCombatSaved[MPRogueCombatConfig].MainHand_Value then
					MPPutonPostion(MPRogueCombatSaved[MPRogueCombatConfig].MainHand_Value, 16)
				end
			end

			if mc<MPRogueCombatSaved[MPRogueCombatConfig].MainHandCount then
				MPPutonPostion(MPRogueCombatSaved[MPRogueCombatConfig].MainHand_Value, 16)
			end

		end

		-- 副手
		if MPRogueCombatSaved[MPRogueCombatConfig].OffHand==1 then

			-- 获取武器信息
			local off, oc, on = MPGetOffHandCount()

			if MPRogueCombatSaved[MPRogueCombatConfig].Cover==1 and off then
				if on~=MPRogueCombatSaved[MPRogueCombatConfig].OffHand_Value then
					MPPutonPostion(MPRogueCombatSaved[MPRogueCombatConfig].OffHand_Value, 17)
				end
			end

			if oc<MPRogueCombatSaved[MPRogueCombatConfig].OffHandCount then
				MPPutonPostion(MPRogueCombatSaved[MPRogueCombatConfig].OffHand_Value, 17)
			end

		end

	end

	-- 在潜行状态
	if playerBuffs["潜行"] and MPRogueCombatSaved[MPRogueCombatConfig].Stealth==1 then

		if targetBuffs["放逐术"] then
			return
		end

		MPStopAttack()

		if MPTargetBleed then
			CastSpellByName("绞喉")
			return
		else
			if MPRogueMainHand==2 then
				CastSpellByName("伏击")
				return
			else
				CastSpellByName("偷袭")
				return
			end
		end

	end



	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPRogueCombatSaved[MPRogueCombatConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPRogueCombatSaved[MPRogueCombatConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPRogueCombatSaved[MPRogueCombatConfig].Power==1 then
		MPCatPower()
	end


	if targetBuffs["放逐术"] then
		return
	end


	-- 在战斗中
	if MPInCombat then


		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and TargetDistance and MPRogueCombatSaved[MPRogueCombatConfig].Trinket_Upper==1 then
			if MPRogueCombatSaved[MPRogueCombatConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPRogueCombatSaved[MPRogueCombatConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and TargetDistance and MPRogueCombatSaved[MPRogueCombatConfig].Trinket_Below==1 then
			if MPRogueCombatSaved[MPRogueCombatConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPRogueCombatSaved[MPRogueCombatConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPRogueCombatSaved[MPRogueCombatConfig].Soulspeed==1 and TargetDistance then
			if MPRogueCombatSaved[MPRogueCombatConfig].SoulspeedBoss==0 or (MPRogueCombatSaved[MPRogueCombatConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPRogueCombatSaved[MPRogueCombatConfig].HealthStone_Value and MPRogueCombatSaved[MPRogueCombatConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPRogueCombatSaved[MPRogueCombatConfig].HerbalTea_Value and MPRogueCombatSaved[MPRogueCombatConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if percent<MPRogueCombatSaved[MPRogueCombatConfig].Carrot_Value and MPRogueCombatSaved[MPRogueCombatConfig].Carrot==1 then
			MPUseItemByName("鞭根块茎")
		end

		-- 冲动
		if MPRogueCombatSaved[MPRogueCombatConfig].Impulse==1 and MPRogueImpulse==1 and TargetDistance and MPSpellReady("冲动") then
			if MPRogueCombatSaved[MPRogueCombatConfig].ImpulseBoss==0 or (MPRogueCombatSaved[MPRogueCombatConfig].ImpulseBoss==1 and MPIsBossTarget()) then
				CastSpellByName("冲动")
			end
		end

		-- 特定 种族天赋 --

		if MPRogueCombatSaved[MPRogueCombatConfig].RacialTraits==1 and TargetDistance then
			if MPRogueCombatSaved[MPRogueCombatConfig].RacialTraitsBoss==0 or (MPRogueCombatSaved[MPRogueCombatConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

	-- 自动打断
	if MPRogueCombatSaved[MPRogueCombatConfig].Interrupt==1 then
		if MPINTCast() then
			return
		end
	end

	-- 保护剑刃乱舞
	if MPRogueCombatSaved[MPRogueCombatConfig].Protect==1 and GetTime()-MPRogueProtectTimer>3.0 then

		MPCancelBuffByName("奥术光辉")
		MPCancelBuffByName("奥术智慧")
		MPCancelBuffByName("精神祷言")
		MPCancelBuffByName("神圣之灵")
		MPCancelBuffByName("智慧祝福")
		MPCancelBuffByName("强效智慧祝福")

		MPRogueProtectTimer = GetTime()

	end

	-- 剑刃乱舞
	if MPRogueCombatSaved[MPRogueCombatConfig].BladeFlurry==1 and myPower>24 then
		local aoe = MPScanNearbyEnemiesCount(MPRogueCombatSaved[MPRogueCombatConfig].BladeFlurry_Value-4)
		if aoe>1 and not playerBuffs["剑刃乱舞"] then
			MPCastWithoutNampower("剑刃乱舞")
		elseif aoe<=1 and playerBuffs["剑刃乱舞"] and TargetDistance then
			MPCancelBuffByName("剑刃乱舞")
		end
	end

	-- 仇恨高的时候佯攻
	-- 仇恨高于80
	if MPRogueCombatSaved[MPRogueCombatConfig].Feint==1 and YG and myPower>=20 and MPGetHatredFromTWT()>=80 then
		MPCastWithNampower("佯攻")
		return
	end

	if GCP>=1 and GCP<=2 then

		-- 保持切割
		if MPRogueCombatSaved[MPRogueCombatConfig].SliceDice==1 and not MPGetRogueSlice(2) and myPower>=MPRogueSliceEnergy then
			MPCastWithoutNampower("切割")
			return
		end

		-- 保持毒伤
		if MPRogueCombatSaved[MPRogueCombatConfig].Envenom==1 and MPRogueEnvenom==1 and not MPGetRogueEnvenom(2) and myPower>=20 then
			MPCastWithoutNampower("毒伤")
			return
		end

	elseif GCP==3 then

		if MPGetRogueBloody(10) or MPRogueBloody==0 or MPRogueCombatSaved[MPRogueCombatConfig].Bloody==0 then

			-- 保持切割
			if MPRogueCombatSaved[MPRogueCombatConfig].SliceDice==1 and not MPGetRogueSlice(4) and myPower>=MPRogueSliceEnergy then
				MPCastWithoutNampower("切割")
				return
			end

			-- 保持毒伤
			if MPRogueCombatSaved[MPRogueCombatConfig].Envenom==1 and MPRogueEnvenom==1 and not MPGetRogueEnvenom(4) and myPower>=20 then
				MPCastWithoutNampower("毒伤")
				return
			end

		end

	elseif GCP==4 then

		if MPGetRogueBloody(10) or MPRogueBloody==0 or MPRogueCombatSaved[MPRogueCombatConfig].Bloody==0 then

			--[[
			-- 保持切割
			if MPRogueCombatSaved[MPRogueCombatConfig].SliceDice==1 and not MPGetRogueSlice(2) and myPower>=MPRogueSliceEnergy then
				MPCastWithoutNampower("切割")
				return
			end

			-- 保持毒伤
			if MPRogueCombatSaved[MPRogueCombatConfig].Envenom==1 and MPRogueEnvenom==1 and  not MPGetRogueEnvenom(2) and myPower>=20 then
				MPCastWithoutNampower("毒伤")
				return
			end
			]]

			if MPRogueCombatSaved[MPRogueCombatConfig].Eviscerate==1 and myPower>29 then
				MPCastWithoutNampower("剔骨")
				return
			end

		end

	elseif GCP==5 then

		if MPGetRogueBloody(10) or MPRogueBloody==0 or MPRogueCombatSaved[MPRogueCombatConfig].Bloody==0 then

			--[[
			-- 保持切割
			if MPRogueCombatSaved[MPRogueCombatConfig].SliceDice==1 and not MPGetRogueSlice(3) and myPower>=MPRogueSliceEnergy then
				MPCastWithoutNampower("切割")
				return
			end

			-- 保持毒伤
			if MPRogueCombatSaved[MPRogueCombatConfig].Envenom==1 and MPRogueEnvenom==1 and  not MPGetRogueEnvenom(3) and myPower>=20 then
				MPCastWithoutNampower("毒伤")
				return
			end
			]]

			if MPRogueCombatSaved[MPRogueCombatConfig].Eviscerate==1 and myPower>29 then
				MPCastWithoutNampower("剔骨")
				return
			end


		else

			if MPRogueCombatSaved[MPRogueCombatConfig].Bloody==1 and MPRogueBloody==1 and not MPGetRogueBloody(5) and myPower>=20 then
				MPCastWithoutNampower("割裂")
				return
			end

			if MPRogueCombatSaved[MPRogueCombatConfig].Bloody==1 and MPRogueBloody==1 and myPower>=20 then
				if not MPGetRogueSlice(3) or not MPGetRogueEnvenom(3) then
					MPCastWithoutNampower("割裂")
					return
				end
			end

		end

	end





	-- 填充技能



	-- 尝试还击
	if MPRogueCombatSaved[MPRogueCombatConfig].Riposte==1 and myPower>9 then
		CastSpellByName("还击")
	end


	if MPRogueCombatSaved[MPRogueCombatConfig].Backstab==1 and MPRogueMainHand==2 then

		-- 背刺贼
		if BEHIND then
			if myPower>59 then
				CastSpellByName("背刺")
			end
		else
			if myPower>39 and MPRogueCombatSaved[MPRogueCombatConfig].GhostlyStrike==1 and MPSpellReady("鬼魅攻击") then
				CastSpellByName("鬼魅攻击")
				return
			end

			if MPRogueCombatSaved[MPRogueCombatConfig].SinisterStrike==1 and myPower>39 then
				CastSpellByName("邪恶攻击")
			end

		end

	else

		-- 战斗贼
		if myPower>39 and MPRogueCombatSaved[MPRogueCombatConfig].GhostlyStrike==1 and MPSpellReady("鬼魅攻击") then
			CastSpellByName("鬼魅攻击")
			return
		end

		if myPower>39 then
			CastSpellByName("邪恶攻击")
		end


	end

	-- 突袭
	if MPRogueCombatSaved[MPRogueCombatConfig].SurpriseStrike==1 and MPRogueRiposte==1 and myPower>9 and MPRogueSurpriseStrike() and TX then
		CastSpellByName("突袭")
		return
	end


end
