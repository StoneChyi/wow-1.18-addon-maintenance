if MPPlayerClass ~= "ROGUE" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 破甲贼一键宏
-- 发布日期：2026-07-26 （后面根据时间来判断版本）
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


-- 能量消耗相关

-- 破甲星
MPExposeArmorCombo = 0

-- -------------------------------------


local QG,GCP,QX,THP,myPower,TX,XX,JRLW,DS,PJ,MoD,GMGJ

-- 默认配置
MPRogueArmorConfig = 1



function MPRoguePJZ()

	myPower = UnitMana("player")
	THP = UnitHealth("target")
	if MPRogueArmorSaved[MPRogueArmorConfig].SliceDiceTime==1 then
		QG = MPGetRogueSlice(MPRogueArmorSaved[MPRogueArmorConfig].SliceDiceTime_Value)
	else
		QG = MPBuff("切割")
	end
	QX = MPBuff("潜行")
	MoD = MPSpellReady("死亡标记")
	GMGJ = MPSpellReady("鬼魅攻击")
	PJ = MPGetExposeArmorDot(15) --MPBuff("破甲","target")
	GCP = GetComboPoints("target")
	BEHIND = MPCheckBehind(MPRogueArmorSaved[MPRogueArmorConfig].UnitXP)


	-- 补充毒药
	if MPRogueArmorSaved[MPRogueArmorConfig].LeaveFight==0 or (MPRogueArmorSaved[MPRogueArmorConfig].LeaveFight==1 and not MPInCombat) then

		-- 主手
		if MPRogueArmorSaved[MPRogueArmorConfig].MainHand==1 then

			-- 获取武器信息
			local main, mc, mn = MPGetMainHandCount()

			-- 覆盖
			if MPRogueArmorSaved[MPRogueArmorConfig].Cover==1 and main then
				if mn ~= MPRogueArmorSaved[MPRogueArmorConfig].MainHand_Value then
					MPPutonPostion(MPRogueArmorSaved[MPRogueArmorConfig].MainHand_Value, 16)
				end
			end

			if mc<MPRogueArmorSaved[MPRogueArmorConfig].MainHandCount then
				MPPutonPostion(MPRogueArmorSaved[MPRogueArmorConfig].MainHand_Value, 16)
			end

		end

		-- 副手
		if MPRogueArmorSaved[MPRogueArmorConfig].OffHand==1 then

			-- 获取武器信息
			local off, oc, on = MPGetOffHandCount()

			if MPRogueArmorSaved[MPRogueArmorConfig].Cover==1 and off then
				if on~=MPRogueArmorSaved[MPRogueArmorConfig].OffHand_Value then
					MPPutonPostion(MPRogueArmorSaved[MPRogueArmorConfig].OffHand_Value, 17)
				end
			end

			if oc<MPRogueArmorSaved[MPRogueArmorConfig].OffHandCount then
				MPPutonPostion(MPRogueArmorSaved[MPRogueArmorConfig].OffHand_Value, 17)
			end

		end

	end


	-- 在潜行状态
	if QX and MPRogueArmorSaved[MPRogueArmorConfig].Stealth==1 then

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
	MPAutoSwitchTarget(MPRogueArmorSaved[MPRogueArmorConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPRogueArmorSaved[MPRogueArmorConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPRogueArmorSaved[MPRogueArmorConfig].Power==1 then
		MPCatPower()
	end


	if MPBuff("放逐术", "target") then
		return
	end

	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and MPGetTargetDistance() and MPRogueArmorSaved[MPRogueArmorConfig].Trinket_Upper==1 then
			if MPRogueArmorSaved[MPRogueArmorConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPRogueArmorSaved[MPRogueArmorConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_RDPS_Trinket_Delay and MPGetTargetDistance() and MPRogueArmorSaved[MPRogueArmorConfig].Trinket_Below==1 then
			if MPRogueArmorSaved[MPRogueArmorConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPRogueArmorSaved[MPRogueArmorConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPRogueArmorSaved[MPRogueArmorConfig].Soulspeed==1 and MPGetTargetDistance() then
			if MPRogueArmorSaved[MPRogueArmorConfig].SoulspeedBoss==0 or (MPRogueArmorSaved[MPRogueArmorConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPRogueArmorSaved[MPRogueArmorConfig].HealthStone_Value and MPRogueArmorSaved[MPRogueArmorConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPRogueArmorSaved[MPRogueArmorConfig].HerbalTea_Value and MPRogueArmorSaved[MPRogueArmorConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if percent<MPRogueArmorSaved[MPRogueArmorConfig].Carrot_Value and MPRogueArmorSaved[MPRogueArmorConfig].Carrot==1 then
			MPUseItemByName("鞭根块茎")
		end

		-- 特定 种族天赋 --

		if MPRogueArmorSaved[MPRogueArmorConfig].RacialTraits==1 and MPGetTargetDistance() then
			if MPRogueArmorSaved[MPRogueArmorConfig].RacialTraitsBoss==0 or (MPRogueArmorSaved[MPRogueArmorConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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
	if MPRogueArmorSaved[MPRogueArmorConfig].Interrupt==1 then
		if MPINTCast() then
			return
		end
	end

	if not MP_SuperWoW then
		MPExposeArmorCombo = 5
	end


	if GCP==1 then

		-- 有SuperWoW才提前打低星破甲
		if MPRogueArmorSaved[MPRogueArmorConfig].FirstStar==1 and MPRogueArmorSaved[MPRogueArmorConfig].FirstStar_Value==GCP and MP_SuperWoW then
			if MPRogueArmorSaved[MPRogueArmorConfig].FirstStarNoBoss==0 or not MPIsBossTarget() then
				if not MPGetExposeArmorDot() then
					MPCastWithoutNampower("破甲")
					return
				end
			end
		end

		if not MPGetRogueSlice() and MPRogueArmorSaved[MPRogueArmorConfig].SliceDice==1 and MPExposeArmorCombo==5 then
			MPCastWithoutNampower("切割")
			return
		end

	elseif GCP==2 then

		-- 有SuperWoW才提前打低星破甲
		if MPRogueArmorSaved[MPRogueArmorConfig].FirstStar==1 and MPRogueArmorSaved[MPRogueArmorConfig].FirstStar_Value==GCP and MP_SuperWoW then
			if MPRogueArmorSaved[MPRogueArmorConfig].FirstStarNoBoss==0 or not MPIsBossTarget() then
				if not MPGetExposeArmorDot() then
					MPCastWithoutNampower("破甲")
					return
				end
			end
		end

		--[[
		if not MPGetRogueSlice() and MPRogueArmorSaved[MPRogueArmorConfig].SliceDice==1 and MPExposeArmorCombo==5 then
			MPCastWithoutNampower("切割")
			return
		end
		]]

	elseif GCP==3 then

		-- 有SuperWoW才提前打低星破甲
		if MPRogueArmorSaved[MPRogueArmorConfig].FirstStar==1 and MPRogueArmorSaved[MPRogueArmorConfig].FirstStar_Value==GCP and MP_SuperWoW then
			if MPRogueArmorSaved[MPRogueArmorConfig].FirstStarNoBoss==0 or not MPIsBossTarget() then
				if not MPGetExposeArmorDot() then
					MPCastWithoutNampower("破甲")
					return
				end
			end
		end

		--[[
		if MPGetExposeArmorDot(14) and MPExposeArmorCombo==5 then

			if not MPGetRogueSlice(1) and MPRogueArmorSaved[MPRogueArmorConfig].SliceDice==1 then
				MPCastWithoutNampower("切割")
				return
			end

		else
		end
		]]

	elseif GCP==4 then

		-- 有SuperWoW才提前打低星破甲
		if MPRogueArmorSaved[MPRogueArmorConfig].FirstStar==1 and MPRogueArmorSaved[MPRogueArmorConfig].FirstStar_Value==GCP and MP_SuperWoW then
			if MPRogueArmorSaved[MPRogueArmorConfig].FirstStarNoBoss==0 or not MPIsBossTarget() then
				if not MPGetExposeArmorDot() then
					MPCastWithoutNampower("破甲")
					return
				end
			end
		end

		--[[

		if MPGetExposeArmorDot(14) and MPExposeArmorCombo==5 then

			if not MPGetRogueSlice(2) and MPRogueArmorSaved[MPRogueArmorConfig].SliceDice==1 then
				MPCastWithoutNampower("切割")
				return
			end

		else

		end
		]]

	elseif GCP==5 then

		if not MPGetExposeArmorDot(8) or MPExposeArmorCombo<5 then
			MPCastWithoutNampower("破甲")
			return
		end

		--[[

		if MPGetExposeArmorDot(14) and MPExposeArmorCombo==5 then

			if not MPGetRogueSlice(3) and MPRogueArmorSaved[MPRogueArmorConfig].SliceDice==1 then
				MPCastWithoutNampower("切割")
				return
			end

		else


		end
		]]

	end





	-- 死亡标记
	if MPRogueArmorSaved[MPRogueArmorConfig].Marked==1 and MoD and MPGetTargetDistance() then
		if MPRogueArmorSaved[MPRogueArmorConfig].MarkedBoss==0 or (MPRogueArmorSaved[MPRogueArmorConfig].MarkedBoss==1 and MPIsBossTarget()) then
			CastSpellByName("死亡标记")
			return
		end
	end

	-- 尝试还击
	if MPRogueArmorSaved[MPRogueArmorConfig].Riposte==1 and myPower>9 then
		CastSpellByName("还击")
	end

	if GCP>=5 and myPower>=50 then

		-- 鬼魅攻击
		if MPRogueArmorSaved[MPRogueArmorConfig].GhostlyStrike==1 and GMGJ then
			if myPower>39 then
				CastSpellByName("鬼魅攻击")
				return
			end
			return
		end

		-- 出血，破甲贼
		if MPRogueHemorrhage==1 and myPower>=MPRogueHemorrhageEnergy then
			CastSpellByName("出血")
			return
		end

	elseif GCP<5 then

		-- 鬼魅攻击
		if MPRogueArmorSaved[MPRogueArmorConfig].GhostlyStrike==1 and GMGJ then
			if myPower>39 then
				CastSpellByName("鬼魅攻击")
				return
			end
			return
		end

		-- 出血，破甲贼
		if MPRogueHemorrhage==1 and myPower>=MPRogueHemorrhageEnergy then
			CastSpellByName("出血")
			return
		end

	end



end


-- 获取盗贼突袭状态
function MPRogueSurpriseStrike()

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW then
		if GetTime()-MPRogueSurpriseStrikeTimerNoSW<4 then
			return true
		end
        return false
    end

	if GetTime()-MPRogueSurpriseStrikeTimer<4 then

		-- 是否存在有效目标
		local a,guid=UnitExists("target")
		if not guid then
			return false
		end

		-- 校验GUID是否是触发压制的目标
		if guid == MPRogueSurpriseStrikeTargetGUID then
			return true
		end
	end

	return false
end
