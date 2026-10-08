if MPPlayerClass ~= "ROGUE" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 盗贼自配置一键宏
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


local QG,GCP,QX,THP,myPower,TX,XX,JRLW,DS,PJ,XF,YG,SJ
local TargetDistance = false
local playerBuffs
local targetBuffs


-- 默认配置
MPRogueConfig = 1


function MPGetMoreStar(Value, Point)

	-- 边际检查
	if not Point then
		return 0
	end
	if Point<1 or Point>5 then
		return 0
	end
	if not Value then
		return 0
	end

	local count = 0
	if Point==1 then
		count = Value[1] + Value[2] + Value[3] + Value[4] + Value[5]
	elseif Point==2 then
		count = Value[2] + Value[3] + Value[4] + Value[5]
	elseif Point==3 then
		count = Value[3] + Value[4] + Value[5]
	elseif Point==4 then
		count = Value[4] + Value[5]
	elseif Point==5 then
		count = Value[5]
	end
	
	return count
end



function MPRogueDPS()

	myPower = UnitMana("player")
	THP = UnitHealth("target")

	DS = MPGetRogueEnvenom(MPRogueSaved[MPRogueConfig].LeftTime_Value)	-- 毒伤
	XX = MPGetRogueBloody(MPRogueSaved[MPRogueConfig].LeftTime_Value)	-- 血腥气息
	QG = MPGetRogueSlice(MPRogueSaved[MPRogueConfig].LeftTime_Value)	-- 切割
	PJ = MPGetExposeArmorDot(MPRogueSaved[MPRogueConfig].LeftTime_Value) -- 破甲

	GCP = GetComboPoints("target")
	--JRLW = MPSpellReady("剑刃乱舞")
	BEHIND = MPCheckBehind(MPRogueSaved[MPRogueConfig].UnitXP)
	TX = MPSpellReady("突袭")
	XF = MPSpellReady("兴奋")
	YG = MPSpellReady("佯攻")
	SJ = MPSpellReady("肾击")
	TargetDistance = MPGetTargetDistance()
	playerBuffs = MPBuffList()
	targetBuffs = MPBuffList("target")


	-- 补充毒药

	if MPRogueSaved[MPRogueConfig].LeaveFight==0 or (MPRogueSaved[MPRogueConfig].LeaveFight==1 and not MPInCombat) then

		-- 主手
		if MPRogueSaved[MPRogueConfig].MainHand==1 then

			-- 获取武器信息
			local main, mc, mn = MPGetMainHandCount()

			-- 覆盖
			if MPRogueSaved[MPRogueConfig].Cover==1 and main then
				if mn ~= MPRogueSaved[MPRogueConfig].MainHand_Value then
					MPPutonPostion(MPRogueSaved[MPRogueConfig].MainHand_Value, 16)
				end
			end

			if mc<MPRogueSaved[MPRogueConfig].MainHandCount then
				MPPutonPostion(MPRogueSaved[MPRogueConfig].MainHand_Value, 16)
			end

		end

		-- 副手
		if MPRogueSaved[MPRogueConfig].OffHand==1 then

			-- 获取武器信息
			local off, oc, on = MPGetOffHandCount()

			if MPRogueSaved[MPRogueConfig].Cover==1 and off then
				if on~=MPRogueSaved[MPRogueConfig].OffHand_Value then
					MPPutonPostion(MPRogueSaved[MPRogueConfig].OffHand_Value, 17)
				end
			end

			if oc<MPRogueSaved[MPRogueConfig].OffHandCount then
				MPPutonPostion(MPRogueSaved[MPRogueConfig].OffHand_Value, 17)
			end

		end

	end


	-- 更换武器，毒药切换
	if MPRogueSaved[MPRogueConfig].SwitchWeapon==1 then

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
	if playerBuffs["潜行"] and MPRogueSaved[MPRogueConfig].Stealth==1 then

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
	MPAutoSwitchTarget(MPRogueSaved[MPRogueConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPRogueSaved[MPRogueConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPRogueSaved[MPRogueConfig].Power==1 then
		MPCatPower()
	end


	if targetBuffs["放逐术"] then
		return
	end

	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and TargetDistance and MPRogueSaved[MPRogueConfig].Trinket_Upper==1 then
			if MPRogueSaved[MPRogueConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPRogueSaved[MPRogueConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and TargetDistance and MPRogueSaved[MPRogueConfig].Trinket_Below==1 then
			if MPRogueSaved[MPRogueConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPRogueSaved[MPRogueConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPRogueSaved[MPRogueConfig].Soulspeed==1 and TargetDistance then
			if MPRogueSaved[MPRogueConfig].SoulspeedBoss==0 or (MPRogueSaved[MPRogueConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPRogueSaved[MPRogueConfig].HealthStone_Value and MPRogueSaved[MPRogueConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPRogueSaved[MPRogueConfig].HerbalTea_Value and MPRogueSaved[MPRogueConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if percent<MPRogueSaved[MPRogueConfig].Carrot_Value and MPRogueSaved[MPRogueConfig].Carrot==1 then
			MPUseItemByName("鞭根块茎")
		end

		if MPRogueSaved[MPRogueConfig].Impulse==1 then
			-- 冲动
			if MPRogueImpulse==1 and TargetDistance and MPSpellReady("冲动") then
				if MPRogueSaved[MPRogueConfig].ImpulseBoss==0 or (MPRogueSaved[MPRogueConfig].ImpulseBoss==1 and MPIsBossTarget()) then
					CastSpellByName("冲动")
				end
			end
			-- 冷血
			if MPRogueColdBlood==1 and MPRogueColdBloodReady() then
				if MPRogueSaved[MPRogueCombatConfig].ImpulseBoss==0 or (MPRogueSaved[MPRogueCombatConfig].ImpulseBoss==1 and MPIsBossTarget()) then
					CastSpellByName("冷血")
				end
			end
		end

		-- 特定 种族天赋 --

		if MPRogueSaved[MPRogueConfig].RacialTraits==1 and TargetDistance then
			if MPRogueSaved[MPRogueConfig].RacialTraitsBoss==0 or (MPRogueSaved[MPRogueConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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
	if MPRogueSaved[MPRogueConfig].Interrupt==1 then
		if MPINTCast() then
			return
		end
	end

	-- 保护剑刃乱舞
	if MPRogueSaved[MPRogueConfig].Protect==1 and GetTime()-MPRogueProtectTimer>3.0 then

		MPCancelBuffByName("奥术光辉")
		MPCancelBuffByName("奥术智慧")
		MPCancelBuffByName("精神祷言")
		MPCancelBuffByName("神圣之灵")
		MPCancelBuffByName("智慧祝福")
		MPCancelBuffByName("强效智慧祝福")

		MPRogueProtectTimer = GetTime()

	end

	-- 剑刃乱舞
	if MPRogueSaved[MPRogueConfig].BladeFlurry==1 and myPower>24 then
		if MPScanNearbyEnemiesCount(MPRogueSaved[MPRogueConfig].BladeFlurry_Value-4)>1 and not playerBuffs["剑刃乱舞"] then
			MPCastWithoutNampower("剑刃乱舞")
		elseif MPScanNearbyEnemiesCount(MPRogueSaved[MPRogueConfig].BladeFlurry_Value-4)<=1 and playerBuffs["剑刃乱舞"] then
			MPCastWithoutNampower("剑刃乱舞")
		end
	end

	-- 仇恨高的时候佯攻
	-- 仇恨高于80
	if MPRogueSaved[MPRogueConfig].Feint==1 and YG and myPower>=20 and MPGetHatredFromTWT()>=80 then
		MPCastWithNampower("佯攻")
		return
	end


	-- 有效连击点数范围
	if GCP>=1 and GCP<=5 then

		if MPRogueSaved[MPRogueConfig].KidneyStrikeStar[GCP]==1 and myPower>=20 and SJ then
			MPCastWithoutNampower("肾击")
			return
		end

		if MPRogueSaved[MPRogueConfig].SliceDiceStar[GCP]==1 and myPower>=MPRogueSliceEnergy and not QG then
			MPCastWithoutNampower("切割")
			return
		end
		if MPRogueSaved[MPRogueConfig].EnvenomStar[GCP]==1 then
			if myPower>=20 and not DS and MPRogueEnvenom==1 then
				MPCastWithoutNampower("毒伤")
				return
			end
		end
		if MPRogueSaved[MPRogueConfig].BloodyStar[GCP]==1 and myPower>=20 and not XX then
			MPCastWithoutNampower("割裂")
			return
		end
		if MPRogueSaved[MPRogueConfig].ExposeArmorStar[GCP]==1 and myPower>=20 and not PJ then
			CastSpellByName("破甲")
			return
		end
		if MPRogueSaved[MPRogueConfig].AdrenalineStar[GCP]==1 and myPower>=20 and XF then
			CastSpellByName("兴奋")
			return
		end

		if MPRogueSaved[MPRogueConfig].EviscerateStar[GCP]==1 and myPower>=30 then

			local allow = 1
			if MPGetMoreStar(MPRogueSaved[MPRogueConfig].BloodyStar, GCP)>0 and not XX then
				allow = 0
			end

			if MPGetMoreStar(MPRogueSaved[MPRogueConfig].EnvenomStar, GCP)>0 and not DS then
				allow = 0
			end

			if MPGetMoreStar(MPRogueSaved[MPRogueConfig].SliceDiceStar, GCP)>0 and not QG then
				allow = 0
			end

			if MPGetMoreStar(MPRogueSaved[MPRogueConfig].ExposeArmorStar, GCP)>0 and not PJ then
				allow = 0
			end

			if MPGetMoreStar(MPRogueSaved[MPRogueConfig].AdrenalineStar, GCP)>0 and XF then
				allow = 0
			end

			if allow==1 then
				MPCastWithoutNampower("剔骨")
				return
			end
			
		end

	end




	-- 填充技能




	-- 还击
	if MPRogueSaved[MPRogueConfig].Riposte==1 and myPower>9 then
		CastSpellByName("还击")
	end

	-- 鬼魅攻击
	if MPRogueSaved[MPRogueConfig].GhostlyStrike==1 and MPSpellReady("鬼魅攻击") then
		if myPower>39 then
			CastSpellByName("鬼魅攻击")
		end
		return
	end

	-- 突袭
	if MPRogueSaved[MPRogueConfig].SurpriseStrike==1 and MPRogueRiposte==1 and myPower>9 and MPRogueSurpriseStrike() and TX then
		CastSpellByName("突袭")
		return
	end

	-- 背刺
	if MPRogueSaved[MPRogueConfig].Backstab==1 then

		-- 背刺
		if BEHIND then
			if MPRogueMainHand==2 then
				if myPower>59 then
					CastSpellByName("背刺")
					return
				end
			else
				if MPRogueSaved[MPRogueConfig].SinisterStrike==1 and myPower>39 then
					CastSpellByName("邪恶攻击")
					return
				end
			end
		else

			if MPRogueSaved[MPRogueConfig].SinisterStrike==1 and myPower>39 then
				CastSpellByName("邪恶攻击")
				return
			end

		end

	end



	-- 出血
	if MPRogueSaved[MPRogueConfig].Hemo==1 then
		if myPower>34 then
			CastSpellByName("出血")
			return
		end
	end

	-- 双刃毒袭
	if MPRogueSaved[MPRogueConfig].Poison==1 then
		if myPower>44 then
			CastSpellByName("双刃毒袭")
			return
		end
	end

	if MPRogueSaved[MPRogueConfig].Sinister==1 and myPower>39 then
		CastSpellByName("邪恶攻击")
		return
	end


end




