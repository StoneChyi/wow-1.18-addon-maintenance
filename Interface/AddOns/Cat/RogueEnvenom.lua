if MPPlayerClass ~= "ROGUE" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 毒伤贼一键宏
-- 发布日期：2026-07-29 （后面根据时间来判断版本）
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


local QG,GCP,QX,THP,myPower,TX,XX,JRLW,DS,PJ,YG
local TargetDistance = false
local playerBuffs
local targetBuffs


-- 默认配置
MPRogueEnvenomConfig = 1



-- 毒伤贼
function MPRogueEnvenomDPS()


	myPower = UnitMana("player")
	THP = UnitHealth("target")

	DS = MPGetRogueEnvenom(0)	-- 毒伤
	XX = MPGetRogueBloody(0)	-- 血腥气息
	QG = MPGetRogueSlice(0)	-- 切割

	GCP = GetComboPoints("target")
	--JRLW = MPSpellReady("剑刃乱舞")
	BEHIND = MPCheckBehind(MPRogueEnvenomSaved[MPRogueEnvenomConfig].UnitXP)
	TX = MPSpellReady("突袭")
	YG = MPSpellReady("佯攻")
	TargetDistance = MPGetTargetDistance()
	playerBuffs = MPBuffList()
	targetBuffs = MPBuffList("target")


	-- 补充毒药
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].LeaveFight==0 or (MPRogueEnvenomSaved[MPRogueEnvenomConfig].LeaveFight==1 and not MPInCombat) then

		-- 主手
		if MPRogueEnvenomSaved[MPRogueEnvenomConfig].MainHand==1 then

			-- 获取武器信息
			local main, mc, mn = MPGetMainHandCount()

			-- 覆盖
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Cover==1 and main then
				if mn ~= MPRogueEnvenomSaved[MPRogueEnvenomConfig].MainHand_Value then
					MPPutonPostion(MPRogueEnvenomSaved[MPRogueEnvenomConfig].MainHand_Value, 16)
				end
			end

			if mc<MPRogueEnvenomSaved[MPRogueEnvenomConfig].MainHandCount then
				MPPutonPostion(MPRogueEnvenomSaved[MPRogueEnvenomConfig].MainHand_Value, 16)
			end

		end

		-- 副手
		if MPRogueEnvenomSaved[MPRogueEnvenomConfig].OffHand==1 then

			-- 获取武器信息
			local off, oc, on = MPGetOffHandCount()

			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Cover==1 and off then
				if on~=MPRogueEnvenomSaved[MPRogueEnvenomConfig].OffHand_Value then
					MPPutonPostion(MPRogueEnvenomSaved[MPRogueEnvenomConfig].OffHand_Value, 17)
				end
			end

			if oc<MPRogueEnvenomSaved[MPRogueEnvenomConfig].OffHandCount then
				MPPutonPostion(MPRogueEnvenomSaved[MPRogueEnvenomConfig].OffHand_Value, 17)
			end

		end

	end


	-- 更换武器，毒药切换
	if MPRogueEnvenomSaved[MPRogueConfig].SwitchWeapon==1 then
		local t = UnitExists("target")
		local postion_text
		if t and not MPCheckUIStatus() then
			local creature = UnitCreatureType("target") or "其它"
			local position = string.find("元素生物,机械,巨人,亡灵", creature)
			if position then
				-- 切换至溶解毒药
				-- 主手
				postion_text = MPGetMainHandPostion()
				if not postion_text or not string.find( postion_text, "溶解毒药" ) then
					MPRogueSwitchWeapon("溶解毒药", 16)
				else

					-- 副手
					postion_text = MPGetOffHandPostion()
					if not postion_text or not string.find( postion_text, "溶解毒药" ) then
						MPRogueSwitchWeapon("溶解毒药", 17)
					end
				end
			else
				-- 切换至速效毒药

				-- 主手
				postion_text = MPGetMainHandPostion()
				if not postion_text or not string.find( postion_text, "速效毒药" ) then
					MPRogueSwitchWeapon("速效毒药", 16)
				else

					-- 副手
					postion_text = MPGetOffHandPostion()
					if not postion_text or not string.find( postion_text, "速效毒药" ) then
						MPRogueSwitchWeapon("速效毒药", 17)
					end
				end
			end
		end
	end


	-- 在潜行状态
	if playerBuffs["潜行"] and MPRogueEnvenomSaved[MPRogueEnvenomConfig].Stealth==1 then

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
	MPAutoSwitchTarget(MPRogueEnvenomSaved[MPRogueEnvenomConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Power==1 then
		MPCatPower()
	end


	if targetBuffs["放逐术"] then
		return
	end


	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and TargetDistance and MPRogueEnvenomSaved[MPRogueEnvenomConfig].Trinket_Upper==1 then
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPRogueEnvenomSaved[MPRogueEnvenomConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and TargetDistance and MPRogueEnvenomSaved[MPRogueEnvenomConfig].Trinket_Below==1 then
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPRogueEnvenomSaved[MPRogueEnvenomConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Soulspeed==1 and TargetDistance then
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].SoulspeedBoss==0 or (MPRogueEnvenomSaved[MPRogueEnvenomConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPRogueEnvenomSaved[MPRogueEnvenomConfig].HealthStone_Value and MPRogueEnvenomSaved[MPRogueEnvenomConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPRogueEnvenomSaved[MPRogueEnvenomConfig].HerbalTea_Value and MPRogueEnvenomSaved[MPRogueEnvenomConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if percent<MPRogueEnvenomSaved[MPRogueEnvenomConfig].Carrot_Value and MPRogueEnvenomSaved[MPRogueEnvenomConfig].Carrot==1 then
			MPUseItemByName("鞭根块茎")
		end

		-- 冷血
		if MPRogueEnvenomSaved[MPRogueCombatConfig].ColdBlood==1 and MPRogueColdBlood==1 and MPRogueColdBloodReady() then
			if MPRogueEnvenomSaved[MPRogueCombatConfig].ColdBloodBoss==0 or (MPRogueEnvenomSaved[MPRogueCombatConfig].ColdBloodBoss==1 and MPIsBossTarget()) then
				CastSpellByName("冷血")
			end
		end

		-- 特定 种族天赋 --

		if MPRogueEnvenomSaved[MPRogueEnvenomConfig].RacialTraits==1 and TargetDistance then
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].RacialTraitsBoss==0 or (MPRogueEnvenomSaved[MPRogueEnvenomConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Interrupt==1 then
		if MPINTCast() then
			return
		end
	end

	-- 保护剑刃乱舞
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Protect==1 and GetTime()-MPRogueProtectTimer>3.0 then

		MPCancelBuffByName("奥术光辉")
		MPCancelBuffByName("奥术智慧")
		MPCancelBuffByName("精神祷言")
		MPCancelBuffByName("神圣之灵")
		MPCancelBuffByName("智慧祝福")
		MPCancelBuffByName("强效智慧祝福")

		MPRogueProtectTimer = GetTime()

	end

	-- 剑刃乱舞
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].BladeFlurry==1 and myPower>24 then
		if MPScanNearbyEnemiesCount(MPRogueEnvenomSaved[MPRogueEnvenomConfig].BladeFlurry_Value-4)>1 and not playerBuffs["剑刃乱舞"] then
			MPCastWithoutNampower("剑刃乱舞")
		elseif MPScanNearbyEnemiesCount(MPRogueEnvenomSaved[MPRogueEnvenomConfig].BladeFlurry_Value-4)<=1 and playerBuffs["剑刃乱舞"] then
			MPCastWithoutNampower("剑刃乱舞")
		end
	end

	-- 仇恨高的时候佯攻
	-- 仇恨高于80
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Feint==1 and YG and myPower>=20 and MPGetHatredFromTWT()>=80 then
		MPCastWithNampower("佯攻")
		return
	end

	if GCP>=1 and GCP<=2 then

		-- 保持毒伤
		if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Envenom==1 and MPRogueEnvenom==1 and not MPGetRogueEnvenom(1) and myPower>=20 then
			MPCastWithoutNampower("毒伤")
			return
		end
		-- 保持切割
		if MPRogueEnvenomSaved[MPRogueEnvenomConfig].SliceDice==1 and not MPGetRogueSlice(1) and myPower>=MPRogueSliceEnergy then
			MPCastWithoutNampower("切割")
			return
		end

	elseif GCP==3 then

		if MPGetRogueBloody(8) or MPRogueBloody==0 or MPRogueEnvenomSaved[MPRogueEnvenomConfig].Bloody==0 then

			-- 保持毒伤
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Envenom==1 and MPRogueEnvenom==1 and not MPGetRogueEnvenom(2) and myPower>=20 then
				MPCastWithoutNampower("毒伤")
				return
			end
			-- 保持切割
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].SliceDice==1 and not MPGetRogueSlice(2) and myPower>=MPRogueSliceEnergy then
				MPCastWithoutNampower("切割")
				return
			end

		end

	elseif GCP==4 then

		if MPGetRogueBloody(10) or MPRogueBloody==0 or MPRogueEnvenomSaved[MPRogueEnvenomConfig].Bloody==0 then

			-- 保持毒伤
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Envenom==1 and MPRogueEnvenom==1 and  not MPGetRogueEnvenom(3) and myPower>=20 then
				MPCastWithoutNampower("毒伤")
				return
			end
			-- 保持切割
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].SliceDice==1 and not MPGetRogueSlice(3) and myPower>=MPRogueSliceEnergy then
				MPCastWithoutNampower("切割")
				return
			end


			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Eviscerate==1 and myPower>29 and (not MPGetRogueSlice(5) or not MPGetRogueEnvenom(5)) then
				MPCastWithoutNampower("剔骨")
				return
			end


		end

	elseif GCP==5 then

		if MPGetRogueBloody(10) or MPRogueBloody==0 or MPRogueEnvenomSaved[MPRogueEnvenomConfig].Bloody==0 then

			-- > 10

			-- 保持毒伤
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Envenom==1 and MPRogueEnvenom==1 and  not MPGetRogueEnvenom(4) and myPower>=20 then
				MPCastWithoutNampower("毒伤")
				return
			end
			-- 保持切割
			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].SliceDice==1 and not MPGetRogueSlice(4) and myPower>=MPRogueSliceEnergy then
				MPCastWithoutNampower("切割")
				return
			end

			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Eviscerate==1 and myPower>29 and (not MPGetRogueSlice(5) or not MPGetRogueEnvenom(5)) then
				MPCastWithoutNampower("剔骨")
				return
			end


		else

			-- < 10

			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Bloody==1 and MPRogueBloody==1 and not MPGetRogueBloody(4) and myPower>=20 then
				MPCastWithoutNampower("割裂")
				return
			end

			if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Bloody==1 and MPRogueBloody==1 and (not MPGetRogueSlice(2) or not MPGetRogueEnvenom(2)) and myPower>=20 then
				--print("紧急-割裂")
				MPCastWithoutNampower("割裂")
				return
			end


		end

	end


	-- 填充技能


	-- 尝试还击
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].Riposte==1 and myPower>9 then
		CastSpellByName("还击")
	end

	if  MPRogueEnvenomSaved[MPRogueEnvenomConfig].GhostlyStrike==1 and MPSpellReady("鬼魅攻击") then
		if myPower>39 then
			CastSpellByName("鬼魅攻击")
		end
		return
	end

	-- 突袭
	if MPRogueEnvenomSaved[MPRogueEnvenomConfig].SurpriseStrike==1 and MPRogueRiposte==1 and myPower>9 and MPRogueSurpriseStrike() and TX then
		CastSpellByName("突袭")
		return
	end

	if myPower>44 then
		CastSpellByName("双刃毒袭")
		return
	end

end



