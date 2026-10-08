if MPPlayerClass ~= "WARRIOR" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 狂暴战DPS一键宏
-- 更新日期：2026-07-22（后面根据时间来判断版本）
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


local AUTO_WDPS_Trinket_Delay = 3			-- 进入战斗后，3秒后才允许使用饰品

-- -------------------------------------

-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化


---------------


local NQ,XFZ,XX,HPP,MENGJI,HS,DJ,FZ,SX=0
local YYNQ = 50
local waitHS=false
local waitSL=false
local waitYZ=false
local OtherExecute=false
local Strike,Once
local isAOE = false
local TargetDistance = false

-- 默认配置
MPWarriorFuryConfig = 1

function MPFuryDPS(o)
	Once = o or 0

	NQ = UnitMana("player")
	HPP = UnitHealth("target")/UnitHealthMax("target")*100
	if MPWarriorFurySaved[MPWarriorFuryConfig].Whirlwind==1 then XFZ = MPSpellReadyOffset("旋风斩",1.5) else XFZ=false end
	XX = MPSpellReady("血性狂暴")
	YZ = MPSpellReadyOffset("压制",1.5)
	TargetDistance = MPGetTargetDistance()

	if MPBloodthirst==1 then SX=MPSpellReadyOffset("嗜血",1.5) else SX=false end

	local YYNQOffset = 15

	isAOE = false
	if Once==0 then
		if MPScanNearbyEnemiesCount(MPWarriorFurySaved[MPWarriorFuryConfig].NearbyEnemies_Value-4) > 1 then
			isAOE = true
		end
	end

	if MPWarriorFurySaved[MPWarriorFuryConfig].NearbyEnemies==1 then
		if isAOE then
			Strike = "顺劈斩"
			YYNQOffset = MPWarriorCleave
		else
			Strike = "英勇打击"
			YYNQOffset = MPWarriorHeroicStrike
		end
	else
		Strike = "英勇打击"
		YYNQOffset = MPWarriorHeroicStrike
	end



	-- 确认目标的存活和转火，并开启自动攻击
	MPAutoSwitchTarget(MPWarriorFurySaved[MPWarriorFuryConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPWarriorFurySaved[MPWarriorFuryConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPWarriorFurySaved[MPWarriorFuryConfig].Power==1 then
		MPCatPower()
	end

	if MPBuff("放逐术", "target") then
		return
	end

	-- 自动打断
	if MPWarriorFurySaved[MPWarriorFuryConfig].Interrupt==1 then
		if MPINTCast() then
			return
		end
	end

	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if MPWarriorFurySaved[MPWarriorFuryConfig].Trinket_Upper==1 and TargetDistance and GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_WDPS_Trinket_Delay then
			if MPWarriorFurySaved[MPWarriorFuryConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPWarriorFurySaved[MPWarriorFuryConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if MPWarriorFurySaved[MPWarriorFuryConfig].Trinket_Below==1 and TargetDistance and GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_WDPS_Trinket_Delay then
			if MPWarriorFurySaved[MPWarriorFuryConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPWarriorFurySaved[MPWarriorFuryConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end
		if MPWarriorFurySaved[MPWarriorFuryConfig].Soulspeed==1 and TargetDistance then
			if MPWarriorFurySaved[MPWarriorFuryConfig].SoulspeedBoss==0 or (MPWarriorFurySaved[MPWarriorFuryConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if MPWarriorFurySaved[MPWarriorFuryConfig].HealthStone==1 and percent<MPWarriorFurySaved[MPWarriorFuryConfig].HealthStone_Value then
			MPUseItemByName("特效治疗石")
		end
		if MPWarriorFurySaved[MPWarriorFuryConfig].HerbalTea==1 and percent<MPWarriorFurySaved[MPWarriorFuryConfig].HerbalTea_Value then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if MPWarriorFurySaved[MPWarriorFuryConfig].Carrot==1 and percent<MPWarriorFurySaved[MPWarriorFuryConfig].Carrot_Value then
			MPUseItemByName("鞭根块茎")
		end

		-- 特定 种族天赋 --

		if MPWarriorFurySaved[MPWarriorFuryConfig].RacialTraits==1 and TargetDistance then
			if MPWarriorFurySaved[MPWarriorFuryConfig].RacialTraitsBoss==0 or (MPWarriorFurySaved[MPWarriorFuryConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

		-- 是否自动开启死亡之愿
		if MPWarriorFurySaved[MPWarriorFuryConfig].DeathWish==1 and MPWarriorDPSDeathWish==1 and TargetDistance then
			if MPWarriorFurySaved[MPWarriorFuryConfig].DeathWishBoss==0 or (MPWarriorFurySaved[MPWarriorFuryConfig].DeathWishBoss==1 and MPIsBossTarget()) then
				local SY = MPSpellReady("死亡之愿")
				if SY and NQ>=MPWarriorDPSDeathWishPower then CastSpellByName("死亡之愿") return end
			end
		end

		-- 是否自动开启鲁莽
		if MPWarriorFurySaved[MPWarriorFuryConfig].Recklessness==1 then
			local LM = MPSpellReady("鲁莽")
			if LM then CastSpellByName("鲁莽") return end
		end

	else
		-- 脱战时清除
		waitYZ=false
		waitSL=false
		waitHS=false
	end




	-- 压制
	if MPWarriorFurySaved[MPWarriorFuryConfig].Overpower==1 and MPWarriorOverpower() and YZ and NQ>4 then --and not MPBuff("乱舞") 
		if NQ<MPWarriorFurySaved[MPWarriorFuryConfig].Overpower_Value and not MPGetShape(1) then
			CastSpellByName("战斗姿态")
			waitYZ = true
		end

		-- 打压制
		if MPGetShape(1) then
			CastSpellByName("压制")
			return
		end
	else
		waitYZ=false
	end

	-- 补充 在战斗姿态下，允许直接压制
	if MPWarriorOverpower() and YZ and NQ>4 and MPGetShape(1) then
		CastSpellByName("压制")
		return
	end

	--[[
	-- 撕裂
	if MPWarriorFurySaved[MPWarriorFuryConfig].Rend==1 and not MPWarriorRend() and MPTargetBleed and NQ>9 and MP_SuperWoW then
		if NQ<MPWarriorFurySaved[MPWarriorFuryConfig].Rend_Value and not MPGetShape(1) then
			CastSpellByName("战斗姿态")
			waitSL = true
		end

		-- 打撕裂
		if MPGetShape(1) then
			CastSpellByName("撕裂")
			return
		end
	else
		waitSL=false
	end
	]]


	-- 是否自动开启横扫
	if MPWarriorFurySaved[MPWarriorFuryConfig].Sweeping==1 and MPWarriorDPSSweeping==1 then

		local HS = MPSpellReady("横扫攻击")

		if MPScanNearbyEnemiesCount(12)>1 and Once==0 and HS then
			if NQ>=MPWarriorDPSSweepingPower and NQ<MPWarriorFurySaved[MPWarriorFuryConfig].Sweeping_Value and not MPGetShape(1) then

				-- 正在猛击读条，断条
				MPWarriorSlamStop()

				CastSpellByName("战斗姿态")
				waitHS = true
			end

			-- 开启横扫
			if MPGetShape(1) and NQ>=MPWarriorDPSSweepingPower then CastSpellByName("横扫攻击") return end
		else
			waitHS=false
		end

		if not HS then waitHS=false end

	end


	-- 冲锋/拦截
	if MPWarriorFurySaved[MPWarriorFuryConfig].Charge==1 then

		if not MPInCombat then
			local CF = MPSpellReady("冲锋")
			if CF and not MPGetTargetDistance("target",8) then
				CastSpellByName("战斗姿态")
				CastSpellByName("冲锋")
				return
			end
		else
			local LJ = MPSpellReady("拦截")
			-- 目标增加非战斗中才进行拦截
			if LJ and not MPGetTargetDistance("target",8) and UnitAffectingCombat("target") then
				CastSpellByName("拦截")
				return
			end
		end

	end


	-- 保持战斗怒吼
	if not MPBuff("战斗怒吼") and NQ>9 and MPWarriorFurySaved[MPWarriorFuryConfig].BattleShout==1 then
		if MPGetBattleShout()<5.0 then
			CastSpellByName("战斗怒吼")
			return
		end
	end


	-- 确保在狂暴姿态下
	if not MPGetShape(MPWarriorBerserkerStanceID) and MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerStance==1 and not waitHS and not waitSL and not waitYZ and MPInCombat then
		CastSpellByName("狂暴姿态")
		return
	end


	-- 开启血性狂暴
	if MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerRage==1 and TargetDistance and XX and MPInCombat and (MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerStance==0 or MPGetShape(MPWarriorBerserkerStanceID)) then
		if SX and NQ<30 then MPCastWithNampower("血性狂暴") end
		if XFZ and NQ<25 then MPCastWithNampower("血性狂暴") end
	end


	-- 补足破甲
	if MPWarriorFurySaved[MPWarriorFuryConfig].SunderArmor==1 then

		local allow = false
		if MPWarriorFurySaved[MPWarriorFuryConfig].SunderArmorBOSS==1 and MPIsBossTarget() then
			allow = true
		elseif MPWarriorFurySaved[MPWarriorFuryConfig].SunderArmorBOSS==0 then
			allow = true
		end

		if allow then
			if MPWarriorFurySaved[MPWarriorFuryConfig].SunderArmorOnce==1 then
				-- 仅一破
				if not MPGetSunderArmorOnce() then
					CastSpellByName("破甲攻击")
					if NQ>=60 then CastSpellByName(Strike) end
					return
				end
			else
				-- 五破
				if MPGetBuffApplications("Interface\\Icons\\Ability_Warrior_Sunder", "target")<5 and NQ>=MPWarriorSunderArmor then
					CastSpellByName("破甲攻击")
					if NQ>=60 then CastSpellByName(Strike) end
					return
				end
			end
		end

	end

	-- 狂暴战

	-- 双手狂暴
	if MPWarriorTwoHand==1 then


		if MPWarriorFurySaved[MPWarriorFuryConfig].HeroicStrike==1 then
			YYNQ = MPWarriorFurySaved[MPWarriorFuryConfig].HeroicStrike_Value
		else
			-- 自动计算怒气阈值
			if isAOE then
				YYNQ = 15+YYNQOffset
				if XFZ then YYNQ = YYNQ+MPWarriorWhirlwind end
			else
				YYNQ = 15+YYNQOffset
				if SX then YYNQ = YYNQ+30 end
				if XFZ then YYNQ = YYNQ+MPWarriorWhirlwind end
			end

		end

		MPWarrorYYNQ = YYNQ

		-- 选择 英勇 or 顺劈
		if HPP>=20 and NQ>YYNQ then
			MPCastWithNampower(Strike)
		else
			--MPWarriorCancelHeroic()
		end

		MPFuryTwoHand()



	-- 双持狂暴
	else
		if MPWarriorFurySaved[MPWarriorFuryConfig].HeroicStrike==1 then
			YYNQ = MPWarriorFurySaved[MPWarriorFuryConfig].HeroicStrike_Value
		else
			-- 自动
			YYNQ = YYNQOffset+YYNQOffset
			if MPSpellReadyOffset("嗜血", 1.3) then YYNQ = YYNQ+30 end
			if MPWarriorFurySaved[MPWarriorFuryConfig].Whirlwind==1 and MPSpellReadyOffset("旋风斩",1.3) then YYNQ = YYNQ+MPWarriorWhirlwind end
		end

		-- 英勇打击 or 顺劈斩
		if isAOE then
			if NQ>YYNQ then MPCastWithNampower(Strike) end
		else
			if HPP>=20 and NQ>YYNQ then MPCastWithNampower(Strike) end
		end

		MPFuryDouble()
	end


end




-- 双手狂暴
function MPFuryTwoHand()

	-- 周围敌人"很多"时
	if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and isAOE and MPGetShape(MPWarriorBerserkerStanceID) then
		MPWarriorSlamStop()
		CastSpellByName("旋风斩")
		return
	end

	-- 进入斩杀线，打断猛击读条
	if not MPIsBossTarget() and HPP<20 and MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==1 and MPWarriorFurySaved[MPWarriorFuryConfig].ExecuteWithoutMonster==1 then
		MPWarriorSlamStop()
		CastSpellByName("斩杀")
		return
	end


	-- 练级特供
	-- 还没有学到乱舞
	if MPWarriorFlurry==0 then
		-- 卡猛击时间
		if MPGetMainHandLeft()<MPWarriorFurySaved[MPWarriorFuryConfig].Slam_Value then --or MPGetMainHandLeft()>(UnitAttackSpeed("player")-1.7) then

			if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then
				CastSpellByName("旋风斩")
				return
			end

			if SX and NQ>29 then
				CastSpellByName("嗜血")
				return
			end

			if HPP<20 and NQ>=MPWarriorExecute and MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==1 then -- 待测试 and not SX and not (XFZ and Once==0) then
				CastSpellByName("斩杀")
				return
			end

		elseif MPGetMainHandLeft()<2.0 then

			if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then
				CastSpellByName("旋风斩")
				return
			end

			if SX and NQ>29 then
				CastSpellByName("嗜血")
				return
			end

			if HPP<20 and NQ>=MPWarriorExecute and MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==1 then -- 待测试 and not SX and not (XFZ and Once==0) then
				CastSpellByName("斩杀")
				return
			end

			if NQ>=15 and (MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerStance==0 or MPGetShape(MPWarriorBerserkerStanceID)) then
				MPCastWithoutNampower("猛击")
				return
			end

		else

			if NQ>=15 and (MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerStance==0 or MPGetShape(MPWarriorBerserkerStanceID)) then
				MPCastWithoutNampower("猛击")
				return
			end

		end
	end


	if MPBuff("乱舞") then

		-- 卡猛击时间
		if MPGetMainHandLeft()<MPWarriorFurySaved[MPWarriorFuryConfig].Slam_Value then --or MPGetMainHandLeft()>(UnitAttackSpeed("player")-1.7) then

			if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then
				CastSpellByName("旋风斩")
				return
			end

			if SX and NQ>29 then
				CastSpellByName("嗜血")
				return
			end

			if HPP<20 and NQ>=MPWarriorExecute and MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==1 then -- 待测试 and not SX and not (XFZ and Once==0) then
				CastSpellByName("斩杀")
				return
			end

		elseif MPGetMainHandLeft()<2.0 then

			if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then
				CastSpellByName("旋风斩")
				return
			end

			if SX and NQ>29 then
				CastSpellByName("嗜血")
				return
			end

			if HPP<20 and NQ>=MPWarriorExecute and MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==1 then -- 待测试 and not SX and not (XFZ and Once==0) then
				CastSpellByName("斩杀")
				return
			end

			if NQ>=15 and (MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerStance==0 or MPGetShape(MPWarriorBerserkerStanceID)) then
				MPCastWithoutNampower("猛击")
				return
			end

		else

			if NQ>=15 and (MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerStance==0 or MPGetShape(MPWarriorBerserkerStanceID)) then
				MPCastWithoutNampower("猛击")
				return
			end

		end

	else

		if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then
			CastSpellByName("旋风斩")
			return
		end

		if SX and NQ>=(MPWarriorExecute+30) and HPP<20 then
			CastSpellByName("嗜血")
			return
		end

		if HPP<20 and NQ>=MPWarriorExecute and MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==1 then
			CastSpellByName("斩杀")
			return
		end

		if SX and NQ>=30 then
			CastSpellByName("嗜血")
			return
		end

		if MPWarriorFurySaved[MPWarriorFuryConfig].Hamstring==1 then
			if not SX and not XFZ and NQ>9 then
				CastSpellByName("断筋")
				return
			end
		end

		-- 没招了，猛击填一个
		if MPGetMainHandLeft()>2.0 then
			
			-- 锁定狂暴姿态
			if MPWarriorFurySaved[MPWarriorFuryConfig].BerserkerStance==1 then
				if NQ>=15 and MPGetShape(MPWarriorBerserkerStanceID) then
					MPCastWithoutNampower("猛击")
					return
				end
			else
				if NQ>=15 then
					MPCastWithoutNampower("猛击")
					return
				end
			end
		end

	end


end



-- 双持-狂暴战
function MPFuryDouble()

	if HPP>=20 or MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==0 then
		-- 正常阶段


		-- 嗜血
		if SX and NQ>29 then
			CastSpellByName("嗜血")
			return
		end

		-- 旋风斩
		if XFZ and NQ>=MPWarriorWhirlwind and MPWarriorFurySaved[MPWarriorFuryConfig].Whirlwind==1 and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then
			CastSpellByName("旋风斩")
			return
		end

		-- 双持断筋，特殊配置
		if MPWarriorFurySaved[MPWarriorFuryConfig].Hamstring==1 then

			if MPBloodthirst==1 then SX=MPSpellReadyOffset("嗜血", 1.4) else SX=false end
			XFZ=MPSpellReadyOffset("旋风斩", 1.4)
			if (not XFZ or MPWarriorFurySaved[MPWarriorFuryConfig].Whirlwind==0) and not SX and NQ>9 then
				CastSpellByName("断筋")
				return
			end
		end

	else
		-- 斩杀阶段

		-- 进入斩杀线，插入主技能，额外功能，需进行配置
		--if MPWarriorFurySaved[MPWarriorFuryConfig].Execute==1 then

			SX=MPSpellReady("嗜血")
			if MPBloodthirst==1 and SX and NQ>=(MPWarriorExecute+30) then CastSpellByName("嗜血") return end
			--XFZ=MPSpellReady("旋风斩")
			--if MPBloodthirst==1 and XFZ and NQ>=(MPWarriorExecute+MPWarriorWhirlwind) and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then CastSpellByName("旋风斩") return end

		--end

		if NQ>=MPWarriorExecute and MPWarriorFurySaved[MPWarriorFuryConfig].UseExecute==1 then CastSpellByName("斩杀") return end

	end

end



