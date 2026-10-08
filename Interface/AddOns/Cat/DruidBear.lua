if MPPlayerClass ~= "DRUID" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 熊德一键宏
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
local AUTO_BEAR_Use_Trinket = 1					-- 饰品总开关，是否自动使用爆发饰品


-- 输出流程辅助配置：

local BEAR_DemoralizingDelay = 9				-- 进入战斗后，9秒后开始补挫志咆哮

-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化


-- -------------------------------------

local myPower,MHP,GCD,XMSY,KN
local playerBuffs
local targetBuffs

-- 默认配置
MPDruidBearConfig = 1


function MPBear(value)

	value = value or 0

	myPower = UnitMana("player")
	MHP = UnitHealth("player")
	GCD = MPGetGCD()
	XMSY=MPSpellReadyOffset("野蛮撕咬")
	KN = MPSpellReady("狂怒")
	playerBuffs = MPBuffList()
	targetBuffs = MPBuffList("target")

	-- 确保在巨熊形态下
	if MPDruidBearSaved[MPDruidBearConfig].Bear==1 and MPDruidBearShapeshiftID>0 then
		if not MPGetShape(MPDruidBearShapeshiftID) then
			CastShapeshiftForm(MPDruidBearShapeshiftID)
		end
	end

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPDruidBearSaved[MPDruidBearConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPDruidBearSaved[MPDruidBearConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPDruidBearSaved[MPDruidBearConfig].Power==1 then
		MPCatPower()
	end


	if targetBuffs["放逐术"] then
		return
	end


	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPGetTargetDistance() and MPDruidBearSaved[MPDruidBearConfig].Trinket_Upper==1 then
			if MPDruidBearSaved[MPDruidBearConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPDruidBearSaved[MPDruidBearConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPGetTargetDistance() and MPDruidBearSaved[MPDruidBearConfig].Trinket_Below==1 then
			if MPDruidBearSaved[MPDruidBearConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPDruidBearSaved[MPDruidBearConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPDruidBearSaved[MPDruidBearConfig].Soulspeed==1 and TargetDistance then
			if MPDruidBearSaved[MPDruidBearConfig].SoulspeedBoss==0 or (MPDruidBearSaved[MPDruidBearConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPDruidBearSaved[MPDruidBearConfig].HealthStone_Value and MPDruidBearSaved[MPDruidBearConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPDruidBearSaved[MPDruidBearConfig].HerbalTea_Value and MPDruidBearSaved[MPDruidBearConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if percent<MPDruidBearSaved[MPDruidBearConfig].Frenzied_Value and MPDruidBearSaved[MPDruidBearConfig].Frenzied==1 and MPGetShape(MPDruidBearShapeshiftID) then
			CastSpellByName("狂暴回复")
		end
		if percent<MPDruidBearSaved[MPDruidBearConfig].Berserk_Value and MPDruidBearSaved[MPDruidBearConfig].Berserk==1 and MPDruidBerserk==1 and MPGetShape(MPDruidBearShapeshiftID) then
			CastSpellByName("狂暴")
		end
		if percent<MPDruidBearSaved[MPDruidBearConfig].Barkskin_Value and MPDruidBearSaved[MPDruidBearConfig].Barkskin==1 and MPGetShape(MPDruidBearShapeshiftID) then
			CastSpellByName("树皮术（野性）")
		end


	end

	-- 是否自动取消拯救
	if MPDruidBearSaved[MPDruidBearConfig].UnSalvation==1 and (playerBuffs["强效拯救祝福"] or playerBuffs["拯救祝福"]) then
		MPCancelBuffByName("强效拯救祝福")
		MPCancelBuffByName("拯救祝福")
		MPMsg("MPCancelBuffByName")
	end

	-- 清晰预兆在，则优先使用野蛮撕咬
	if playerBuffs["节能施法"] and XMSY then
		CastSpellByName("野蛮撕咬")
	end

	if myPower >= MPDruidFerociousBitePower and XMSY then
		CastSpellByName("野蛮撕咬")
	end


	-- 根据周围的敌人数量来选择策略
	if MPScanNearbyEnemiesCount() > 1 and MPDruidBearSaved[MPDruidBearConfig].SwipeFirst==1 then

		-- 群拉
		if myPower >= MPDruidSwipePower and MPDruidBearSaved[MPDruidBearConfig].Swipe==1 and value==0 then
			CastSpellByName("挥击")
		end
		if myPower >= MPDruidSwipePower+MPDruidManglePower then
			CastSpellByName("槌击")
		end

		-- 能量空挡时用精灵之火填补GCD
		if myPower<MPDruidSwipePower and MPIsFaerieFire() and not XMSY and MPDruidBearSaved[MPDruidBearConfig].FaerieFire==1 then 
			if MPGetTargetDistance() and MPGetShape(MPDruidBearShapeshiftID) then
				CastSpellByName("精灵之火（野性）")
			end
		end

	else

		if MPDruidBearSaved[MPDruidBearConfig].MangleFirst==1 and myPower>=MPDruidManglePower then
			CastSpellByName("槌击")
		end

		-- 单拉
		if myPower >= MPDruidSwipePower+MPDruidFerociousBitePower+MPDruidManglePower then
			CastSpellByName("槌击")
		end

		if myPower >= MPDruidSwipePower+MPDruidFerociousBitePower and not playerBuffs["节能施法"] and not XMSY and MPDruidBearSaved[MPDruidBearConfig].Swipe==1 and value==0 then  --  +MPDruidManglePower
			CastSpellByName("挥击")
		end

		if myPower >= 80 and not XMSY and MPDruidBearSaved[MPDruidBearConfig].Swipe==1 and value==0 then  --  +MPDruidManglePower
			CastSpellByName("挥击")
		end

		-- 能量空挡时用精灵之火填补GCD
		if myPower<MPDruidFerociousBitePower and MPIsFaerieFire() and not XMSY and MPDruidBearSaved[MPDruidBearConfig].FaerieFire==1 then 
			if MPGetTargetDistance() and MPGetShape(MPDruidBearShapeshiftID) then
				CastSpellByName("精灵之火（野性）")
			end
		end

	end

	-- 是否自动开启狂怒
	if MPDruidBearSaved[MPDruidBearConfig].Fury==1 and KN and MPInCombat then
		if not playerBuffs["血之狂暴"] then
			if MPDruidBearSaved[MPDruidBearConfig].FuryBoss==1 then
				if MPIsBossTarget() then
					CastSpellByName("狂怒")
				end
			else
				CastSpellByName("狂怒")
			end
		end
	end

	-- 保持 精灵之火
	if MPDruidBearSaved[MPDruidBearConfig].FaerieFire==1 and MPIsFaerieFire() and not XMSY and not targetBuffs["精灵之火（野性）"] and not targetBuffs["精灵之火"] then
		if MPGetTargetDistance() and MPGetShape(MPDruidBearShapeshiftID) then
			CastSpellByName("精灵之火（野性）")
		end
	end


	-- 是否要补挫志咆哮
	if MPDruidBearSaved[MPDruidBearConfig].Demoralizing==1 and GetTime()-MPInCombatTime>BEAR_DemoralizingDelay and value==0 then
		if UnitExists("target") and (not MPCZTimer or GetTime()-MPCZTimer>30) and GCD>1.5 then
			if myPower>9 and not targetBuffs["挫志咆哮"] and not targetBuffs["挫志怒吼"] and not XMSY then
				CastSpellByName("挫志咆哮")
				MPCZTimer=GetTime()
			end
		end
	end

	-- 远距离补精灵之火
	MPFaerieFire()


end









