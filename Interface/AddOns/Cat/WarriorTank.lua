if MPPlayerClass ~= "WARRIOR" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 战士Tank一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
-- SuperWoW优势1可以更加准确获得扫击、撕扯的持续时间（特别是在团队副本，避免目标身上debuff过多时可能丢失的可能性），可支持多只猫的环境下计算自己的扫击、撕扯
--
-- -------------------------------------
--
-- 功能配置：
-- 注：修改以下配置，需要在游戏中/reload，或者小退让配置生效
-- 
-- 主开关
-- 以下功能开关：1开启 0关闭


local WTANK_DemoralizingDelay = 9				-- 进入战斗后，9秒后开始补挫志怒吼

-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化

-- 震荡猛击 标记
MPWarriorTankConcussion = 0
-- 盾牌猛击 标记
MPWarriorTankShieldSlam = 0

-- 生命宝石标记
MPWarriorLifeJewel = 0

-- -------------------------------------



local NQ,XX,DPMJ,ZDMJ,DPGD,FC,GCD,FZ,ZS,SX,HPP
local waitYZ=false
local TargetDistance = false

MPWarriorCZTimer=0
MPWarriorLTTimer=0

-- 默认配置
MPWarriorTankConfig = 1


local function MPWarriorTankPart()

end

function MPWarriorTank()

	NQ=UnitMana("player")
	GCD = MPGetGCD()

	if MPWarriorTankShieldSlam==1 then
		DPMJ=MPSpellReadyOffset("盾牌猛击")
	else
		DPMJ=false
	end

	if MPWarriorTankConcussion==1 then
		ZDMJ=MPSpellReadyOffset("震荡猛击")
	else
		ZDMJ=false
	end

	--[[
	if MPWarriorCounter==1 then
		FZ=MPSpellReady("反击")
	else
		FZ=false
	end
	]]

	DPGD=MPSpellReady("盾牌格挡")
	FC=MPSpellReadyOffset("复仇",1.5)
	XX=MPSpellReady("血性狂暴")
	YZ = MPSpellReadyOffset("压制",1.5)
	TargetDistance = MPGetTargetDistance()
	if UnitExists("target") then
		HPP = UnitHealth("target")/UnitHealthMax("target")*100
	else
		HPP = 100
	end

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPWarriorTankSaved[MPWarriorTankConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPWarriorTankSaved[MPWarriorTankConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPWarriorTankSaved[MPWarriorTankConfig].Power==1 then
		MPCatPower()
	end

	if MPBuff("放逐术", "target") then
		return
	end


	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and TargetDistance and MPWarriorTankSaved[MPWarriorTankConfig].Trinket_Upper==1 then
			if MPWarriorTankSaved[MPWarriorTankConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPWarriorTankSaved[MPWarriorTankConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and TargetDistance and MPWarriorTankSaved[MPWarriorTankConfig].Trinket_Below==1 then
			if MPWarriorTankSaved[MPWarriorTankConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPWarriorTankSaved[MPWarriorTankConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPWarriorTankSaved[MPWarriorTankConfig].Soulspeed==1 and TargetDistance then
			if MPWarriorTankSaved[MPWarriorTankConfig].SoulspeedBoss==0 or (MPWarriorTankSaved[MPWarriorTankConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPWarriorTankSaved[MPWarriorTankConfig].HealthStone_Value and MPWarriorTankSaved[MPWarriorTankConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPWarriorTankSaved[MPWarriorTankConfig].HerbalTea_Value and MPWarriorTankSaved[MPWarriorTankConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if percent<MPWarriorTankSaved[MPWarriorTankConfig].Carrot_Value and MPWarriorTankSaved[MPWarriorTankConfig].Carrot==1 then
			MPUseItemByName("鞭根块茎")
		end
		-- 盾牌格挡的开启血线
		if percent<=MPWarriorTankSaved[MPWarriorTankConfig].ShieldBlock_Value and MPWarriorTankSaved[MPWarriorTankConfig].ShieldBlock==1 then
			local totName = UnitName("targettarget")
			if totName and totName==UnitName("player") then
				if NQ>9 and DPGD and MPGetShape(2) and not DPMJ and not MPBuff("强化盾牌猛击") then
					CastSpellByName("盾牌格挡")
				end
			end
		end
		-- 破釜沉舟的开启血线
		if percent<MPWarriorTankSaved[MPWarriorTankConfig].LastStand_Value and MPWarriorTankSaved[MPWarriorTankConfig].LastStand==1 then
			CastSpellByName("破釜沉舟")
		end
		-- 盾墙的开启血线
		if percent<MPWarriorTankSaved[MPWarriorTankConfig].ShieldWall_Value and MPWarriorTankSaved[MPWarriorTankConfig].ShieldWall==1 then
			if MPGetShape(2) then
				CastSpellByName("盾墙")
			end
		end
		-- 生命宝石的开启血线
		if percent<MPWarriorTankSaved[MPWarriorTankConfig].LifeJewel_Value and MPWarriorTankSaved[MPWarriorTankConfig].LifeJewel==1 then

			-- 该饰品是否存在
			if MPWarriorLifeJewel>0 then
				UseInventoryItem(MPWarriorLifeJewel)
			end
		end

		-- 特定 种族天赋 --

		if MPWarriorTankSaved[MPWarriorTankConfig].RacialTraits==1 and TargetDistance then
			if MPWarriorTankSaved[MPWarriorTankConfig].RacialTraitsBoss==0 or (MPWarriorTankSaved[MPWarriorTankConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

				-- 是否自动开启 矮人-石像形态
				if MPPlayerRace=="Dwarf" then
					local TF = MPSpellReady("石像形态")
					if TF then CastSpellByName("石像形态") end
				end
			end
		end

		-- 是否自动开启死亡之愿
		if MPWarriorTankSaved[MPWarriorTankConfig].DeathWish==1 and MPWarriorDPSDeathWish==1 and TargetDistance then
			if MPWarriorTankSaved[MPWarriorTankConfig].DeathWishBoss==0 or (MPWarriorTankSaved[MPWarriorTankConfig].DeathWishBoss==1 and MPIsBossTarget()) then
				local SY = MPSpellReady("死亡之愿")
				if SY and NQ>=MPWarriorDPSDeathWishPower then CastSpellByName("死亡之愿") return end
			end
		end

	end

	-- 是否自动取消拯救
	if MPWarriorTankSaved[MPWarriorTankConfig].UnSalvation==1 and ( MPBuff("强效拯救祝福") or MPBuff("拯救祝福") ) then
		MPCancelBuffByName("强效拯救祝福")
		MPCancelBuffByName("拯救祝福")
	end

	-- 压制
	if MPWarriorTankSaved[MPWarriorTankConfig].Overpower==1 and MPWarriorOverpower() and YZ and NQ>4 then
		if NQ<MPWarriorTankSaved[MPWarriorTankConfig].Overpower_Value and not MPGetShape(1) then
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

	-- 确保在防御姿态下
	if MPWarriorTankSaved[MPWarriorTankConfig].Defensive==1 and not MPGetShape(2) then
		CastSpellByName("防御姿态")
	end

	-- 自动打断
	if MPWarriorTankSaved[MPWarriorTankConfig].Interrupt==1 then
		if MPINTCast() then
			return
		end
	end


	-- 英勇打击 顺劈斩
	if MPWarriorTankSaved[MPWarriorTankConfig].NearbyEnemies==1 then
		if NQ>MPWarriorTankSaved[MPWarriorTankConfig].HeroicStrike and MPScanNearbyEnemiesCount(6) > 1 then
			MPCastWithNampower("顺劈斩")
		elseif NQ>MPWarriorTankSaved[MPWarriorTankConfig].HeroicStrike then
			MPCastWithNampower("英勇打击")
		end
	else
		if NQ>MPWarriorTankSaved[MPWarriorTankConfig].HeroicStrike then
			MPCastWithNampower("英勇打击")
		end
	end


	if NQ<30 and MPWarriorTankSaved[MPWarriorTankConfig].BerserkerRage==1 and XX and TargetDistance and MPInCombat then CastSpellByName("血性狂暴") end

	if MPWarriorTankConcussion==1 and MPWarriorTankSaved[MPWarriorTankConfig].Shockwave==1 and ZDMJ then CastSpellByName("震荡猛击") return end

	-- 主技能

	if MPWarriorTankSaved[MPWarriorTankConfig].MainSkill==1 then
		-- 用于武器战临时切换的技能输出
		if MPWarriorDPSType==1 then
			if MPMortalStrike==1 then ZS=MPSpellReadyOffset("致死打击") else ZS=false end
			if ZS and NQ>29 then
				CastSpellByName("致死打击")
				return
			end

		-- 用于狂暴战临时切换的技能输出
		elseif MPWarriorDPSType==2 then
			if MPBloodthirst==1 then SX=MPSpellReadyOffset("嗜血") else SX=false end
			if SX and NQ>29 then
				CastSpellByName("嗜血")
				return
			end

		else

			if MPWarriorTankShieldSlam==1 and DPMJ and NQ>19 then
				CastSpellByName("盾牌猛击")
				return
			end
	
		end
	end

	-- 旋风斩
	if MPWarriorTankSaved[MPWarriorTankConfig].Whirlwind==1 then
		if NQ>24 and MPSpellReadyOffset("旋风斩",1.5) and MPGetShape(MPWarriorBerserkerStanceID) then
			CastSpellByName("旋风斩")
			return
		end
	end

	-- 复仇
	if FC and MPWarriorTankSaved[MPWarriorTankConfig].Revenge==1 and MPWarriorCounterAttack() and NQ>4 and MPGetShape(2) then
		CastSpellByName("复仇") 
		return
	end 

	-- 斩杀
	if MPWarriorTankSaved[MPWarriorTankConfig].Execute==1 and NQ>14 and HPP<20 and not MPGetShape(2) then
		CastSpellByName("斩杀") 
		return
	end

	-- 保持战斗怒吼
	if not MPBuff("战斗怒吼") and NQ>9 and MPWarriorTankSaved[MPWarriorTankConfig].BattleShout==1 then CastSpellByName("战斗怒吼") return end


	-- 是否要补挫志怒吼
	if MPWarriorTankSaved[MPWarriorTankConfig].Demoralizing==1 then
		if NQ>9 and UnitExists("target") and GetTime()-MPWarriorCZTimer>10 and TargetDistance then
			if not MPBuff("挫志咆哮","target") and not MPBuff("挫志怒吼","target") then
				CastSpellByName("挫志怒吼")
				return
			else
				MPWarriorCZTimer=GetTime()
			end
		end
	end

	-- 是否要补雷霆一击
	if MPWarriorTankSaved[MPWarriorTankConfig].ThunderClap==1 then
		if NQ>19 and UnitExists("target") and GetTime()-MPWarriorLTTimer>10 and TargetDistance then
			if not MPBuff("雷霆一击","target") then
				CastSpellByName("雷霆一击")
				return
			else
				MPWarriorLTTimer=GetTime()
			end
		end
	end

	if MPWarriorTankSaved[MPWarriorTankConfig].SunderArmor==1 and NQ>MPWarriorTankSaved[MPWarriorTankConfig].SunderArmor_Value then CastSpellByName("破甲攻击") end

end




