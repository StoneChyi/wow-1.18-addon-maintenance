if MPPlayerClass ~= "WARRIOR" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 武器战士DPS一键宏
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

-- -------------------------------------



local NQ,XFZ,XX,HPP,MENGJI,HS,DJ,FZ,ZS=0
local YYNQ = 50
local waitHS=false
local waitSL=false
local waitYZ=false
local OtherExecute=false
local Strike,Once
local isAOE = false
local TargetDistance = false

-- 默认配置
MPWarrorArmsConfig = 1

function MPArmsDPS(o)
	Once = o or 0

	NQ = UnitMana("player")
	HPP = UnitHealth("target")/UnitHealthMax("target")*100
	if MPWarriorArmsSaved[MPWarrorArmsConfig].Whirlwind==1 then XFZ = MPSpellReadyOffset("旋风斩",2.0) else XFZ=false end
	XX=MPSpellReady("血性狂暴") 
	YZ=MPSpellReadyOffset("压制",1.5)
	TargetDistance = MPGetTargetDistance()

	if MPMortalStrike==1 then ZS=MPSpellReadyOffset("致死打击",2.0) else ZS=false end

	local YYNQOffset = 15

	isAOE = false
	if Once==0 then
		if MPScanNearbyEnemiesCount(MPWarriorArmsSaved[MPWarrorArmsConfig].NearbyEnemies_Value-4) > 1 then
			isAOE = true
		end
	end

	if MPWarriorArmsSaved[MPWarrorArmsConfig].NearbyEnemies==1 then
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
	MPAutoSwitchTarget(MPWarriorArmsSaved[MPWarrorArmsConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPWarriorArmsSaved[MPWarrorArmsConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPWarriorArmsSaved[MPWarrorArmsConfig].Power==1 then
		MPCatPower()
	end

	if MPBuff("放逐术", "target") then
		return
	end

	-- 自动打断
	if MPWarriorArmsSaved[MPWarrorArmsConfig].Interrupt==1 then
		if MPINTCast() then
			return
		end
	end

	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if MPWarriorArmsSaved[MPWarrorArmsConfig].Trinket_Upper==1 and TargetDistance and GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_WDPS_Trinket_Delay then
			if MPWarriorArmsSaved[MPWarrorArmsConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPWarriorArmsSaved[MPWarrorArmsConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if MPWarriorArmsSaved[MPWarrorArmsConfig].Trinket_Below==1 and TargetDistance and GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_WDPS_Trinket_Delay then
			if MPWarriorArmsSaved[MPWarrorArmsConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPWarriorArmsSaved[MPWarrorArmsConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end
		if MPWarriorArmsSaved[MPWarrorArmsConfig].Soulspeed==1 and TargetDistance then
			if MPWarriorArmsSaved[MPWarrorArmsConfig].SoulspeedBoss==0 or (MPWarriorArmsSaved[MPWarrorArmsConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if MPWarriorArmsSaved[MPWarrorArmsConfig].HealthStone==1 and percent<MPWarriorArmsSaved[MPWarrorArmsConfig].HealthStone_Value then
			MPUseItemByName("特效治疗石")
		end
		if MPWarriorArmsSaved[MPWarrorArmsConfig].HerbalTea==1 and percent<MPWarriorArmsSaved[MPWarrorArmsConfig].HerbalTea_Value then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if MPWarriorArmsSaved[MPWarrorArmsConfig].Carrot==1 and percent<MPWarriorArmsSaved[MPWarrorArmsConfig].Carrot_Value then
			MPUseItemByName("鞭根块茎")
		end

		-- 特定 种族天赋 --

		if MPWarriorArmsSaved[MPWarrorArmsConfig].RacialTraits==1 and TargetDistance then
			if MPWarriorArmsSaved[MPWarrorArmsConfig].RacialTraitsBoss==0 or (MPWarriorArmsSaved[MPWarrorArmsConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

		-- 是否自动开启鲁莽
		if MPWarriorArmsSaved[MPWarrorArmsConfig].Recklessness==1 then
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
	if MPWarriorArmsSaved[MPWarrorArmsConfig].Overpower==1 and MPWarriorOverpower() and YZ and NQ>4 then --and not MPBuff("乱舞") 
		if NQ<MPWarriorArmsSaved[MPWarrorArmsConfig].Overpower_Value and not MPGetShape(1) then
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


	-- 是否自动开启横扫
	if MPWarriorArmsSaved[MPWarrorArmsConfig].Sweeping==1 and MPWarriorDPSSweeping==1 then

		local HS = MPSpellReady("横扫攻击")

		if isAOE then
			if Once==0 and HS then
				if NQ>=MPWarriorDPSSweepingPower and NQ<MPWarriorArmsSaved[MPWarrorArmsConfig].Sweeping_Value and not MPGetShape(1) then

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
		else
			waitHS=false
		end

		if not HS then waitHS=false end

	end


	-- 冲锋/拦截
	if MPWarriorArmsSaved[MPWarrorArmsConfig].Charge==1 then

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
	if MPWarriorArmsSaved[MPWarrorArmsConfig].BattleShout==1 and not MPBuff("战斗怒吼") and NQ>9 then
		if MPGetBattleShout()<5.0 then
			CastSpellByName("战斗怒吼")
			return
		end
	end


	-- 确保在狂暴姿态下
	if MPWarriorArmsSaved[MPWarrorArmsConfig].BerserkerStance==1 and not MPGetShape(MPWarriorBerserkerStanceID) and not waitHS and not waitYZ and MPInCombat then
		CastSpellByName("狂暴姿态")
		return
	end


	-- 开启血性狂暴
	if MPWarriorArmsSaved[MPWarrorArmsConfig].BerserkerRage==1 and TargetDistance and XX and MPInCombat and (MPWarriorArmsSaved[MPWarrorArmsConfig].BerserkerStance==0 or MPGetShape(MPWarriorBerserkerStanceID)) then
		if ZS and NQ<30 then MPCastWithNampower("血性狂暴") end
		if XFZ and NQ<25 then MPCastWithNampower("血性狂暴") end
	end


	-- 补足破甲
	if MPWarriorArmsSaved[MPWarrorArmsConfig].SunderArmor==1 then

		local allow = false
		if MPWarriorArmsSaved[MPWarrorArmsConfig].SunderArmorBOSS==1 and MPIsBossTarget() then
			allow = true
		elseif MPWarriorArmsSaved[MPWarrorArmsConfig].SunderArmorBOSS==0 then
			allow = true
		end

		if allow then
			if MPWarriorArmsSaved[MPWarrorArmsConfig].SunderArmorOnce==1 then
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

	-- 武器战

	if MPWarriorArmsSaved[MPWarrorArmsConfig].HeroicStrike==1 then
		YYNQ = MPWarriorArmsSaved[MPWarrorArmsConfig].HeroicStrike_Value
	else
		-- 自动计算怒气阈值
		if isAOE then
			YYNQ = 15+YYNQOffset
			if XFZ then YYNQ = YYNQ+MPWarriorWhirlwind end
		else
			YYNQ = 15+YYNQOffset+15
			if ZS then YYNQ = YYNQ+30 end
			if XFZ then YYNQ = YYNQ+MPWarriorWhirlwind end
		end

		--[[
		if MPGetMainHandLeft()>1.0 and YYNQ<50 then
			YYNQ = YYNQ + 15
		end
		]]

	end

	MPWarrorYYNQ = YYNQ

	-- 选择 英勇 or 顺劈
	if HPP>=20 and NQ>YYNQ then
		MPCastWithNampower(Strike)
	else
		--MPWarriorCancelHeroic()
	end

	MPArmsTwoHand()

end




-- 双手-武器战
function MPArmsTwoHand()

	if MPWarriorArmsSaved[MPWarrorArmsConfig].Whirlwind==1 then XFZ = MPSpellReadyOffset("旋风斩",0.5) else XFZ=false end
	if MPMortalStrike==1 then ZS=MPSpellReadyOffset("致死打击",0.5) else ZS=false end


	-- 周围敌人"很多"时
	if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and isAOE and MPGetShape(MPWarriorBerserkerStanceID) then
		MPWarriorSlamStop()
		CastSpellByName("旋风斩")
		return
	end

	-- 进入斩杀线，插入主技能，额外功能，需进行配置
	if HPP<20 and MPWarriorArmsSaved[MPWarrorArmsConfig].ExecuteWithMortal==1 then

		if MPWarriorArmsSaved[MPWarrorArmsConfig].ExecuteWithoutMonster==0 or (MPWarriorArmsSaved[MPWarrorArmsConfig].ExecuteWithoutMonster==1 and MPIsBossTarget()) then
			if MPGetMainHandLeft()>2.5 then
				if NQ>=(MPWarriorArmsSaved[MPWarrorArmsConfig].ExecutePower+15) and (MPWarriorArmsSaved[MPWarrorArmsConfig].BerserkerStance==0 or MPGetShape(MPWarriorBerserkerStanceID)) then
					MPCastWithoutNampower("猛击")
					return
				end
			end
		end

		--if ZS and NQ>=(MPWarriorExecute+30) then CastSpellByName("致死打击") return end

	end

	-- 进入斩杀线，
	if HPP<20 and MPWarriorArmsSaved[MPWarrorArmsConfig].UseExecute==1 then
		
		if MPIsBossTarget() then

			if NQ>MPWarriorArmsSaved[MPWarrorArmsConfig].ExecutePower then
				CastSpellByName("斩杀")
			end
			return

		else

			if NQ>MPWarriorArmsSaved[MPWarrorArmsConfig].ExecutePower then

				-- 打断猛击读条，小怪 
				if MPWarriorArmsSaved[MPWarrorArmsConfig].ExecuteWithoutMonster==1 then
					MPWarriorSlamStop()
				end

				CastSpellByName("斩杀")
				return

			end

		end


	end




	-- 顺道斩杀
	if MP_SuperWoW and MPWarriorArmsSaved[MPWarrorArmsConfig].ExecuteOtherTarget==1 then
		local count,_,_,list = MPScanNearbyEnemiesCount()
		if count>1 then
			for guid, value in pairs(list) do
				if not guid then
					break
				end
				if NQ>MPWarriorArmsSaved[MPWarrorArmsConfig].ExecutePower then
					MPCastSpellWithoutTarget("斩杀", guid)
				end
			end
		end
	end

	-- 致死打击
	if ZS and NQ>29 then
		CastSpellByName("致死打击")
		return
	end

	-- 旋风斩
	if XFZ and NQ>=MPWarriorWhirlwind and TargetDistance and Once==0 and MPGetShape(MPWarriorBerserkerStanceID) then
		
		CastSpellByName("旋风斩")
		return
		
	end


	-- 锁定狂暴姿态
	if MPWarriorArmsSaved[MPWarrorArmsConfig].BerserkerStance==1 then
		if NQ>=15 and MPGetMainHandLeft()>MPWarriorArmsSaved[MPWarrorArmsConfig].Slam_Value and MPGetShape(MPWarriorBerserkerStanceID) then
			MPCastWithoutNampower("猛击")
			return
		end
	else
		if NQ>=15 and MPGetMainHandLeft()>MPWarriorArmsSaved[MPWarrorArmsConfig].Slam_Value then
			MPCastWithoutNampower("猛击")
			return
		end
	end




end


