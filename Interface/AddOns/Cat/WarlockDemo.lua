if MPPlayerClass ~= "WARLOCK" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 恶魔术一键宏
-- 更新日期：2026-08-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：无
--
-- 说明：
-- 
-- -------------------------------------


local MHP,DM,AYZS,CYZL,EYZZ

-- 默认配置
MPWalockDemoConfig = 1


local function MPCastCurseAgony()
	if DM>=MPCurseAgonyMana[6] then
		MPCastWithoutNampower("痛苦诅咒")
	else
		MPCastWithoutNampower("痛苦诅咒(等级 1)")
	end
end

local function MPCastCorruption()
	if DM>=MPWarlockCorruptionMana[7] then
		MPCastWithoutNampower("腐蚀术")
	else
		MPCastWithoutNampower("腐蚀术(等级 3)")
	end
end

local function MPCastImmolate()
	if DM>=MPWarlockImmolateMana[8] then
		MPCastWithoutNampower("献祭")
	else
		MPCastWithoutNampower("献祭(等级 1)")
	end
end

local function MPCastSiphonLife()
	if DM>=MPWarlockSiphonLifeMana[4] then
		MPCastWithoutNampower("生命虹吸")
	else
		MPCastWithoutNampower("生命虹吸(等级 1)")
	end
end

local function MPCastShadowburn()
	if DM>=MPWarlockShadowburnMana[6] then
		CastSpellByName("暗影灼烧")
	else
		CastSpellByName("暗影灼烧(等级 1)")
	end
end

local function MPCastShadowBolt()
	if DM>=MPWarlockShadowBoltMana[10] then
		CastSpellByName("暗影箭")
	else
		CastSpellByName("暗影箭(等级 1)")
	end
end

local function MPCastCurseRecklessness()
	MPCastWithoutNampower("鲁莽诅咒")
end

local function MPCastCurseCurseElements()
	MPCastWithoutNampower("元素诅咒")
end

local function MPCastCurseShadow()
	MPCastWithoutNampower("暗影诅咒")
end

local function MPCastCurseTongues()
	MPCastWithoutNampower("语言诅咒")
end

local function MPCastCurseWeakness()
	MPCastWithoutNampower("虚弱诅咒")
end

local function MPCastCurseFatigue()
	MPCastWithoutNampower("疲劳诅咒")
end

local function MPCastCurseDoom()
	MPCastWithoutNampower("厄运诅咒")
end




function MPWarlockDemo()

	MHP = UnitHealth("player")
	DM = UnitMana("player")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100
	if MPWarlockShadowburn==1 then AYZS = MPSpellReady("暗影灼烧") else AYZS=false end
	if MPWarlockOverpowering==1 then CYZL = MPSpellReady("超越之力") else CYZL=false end
	EYZZ = MPSpellReady("厄运诅咒")

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPWarlockDemoSaved[MPWalockDemoConfig].Target, 0)

	-- 开启自动攻击
	if MPWarlockDemoSaved[MPWalockDemoConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPWarlockDemoSaved[MPWalockDemoConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPWarlockDemoSaved[MPWalockDemoConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 宠物攻击
	if MPWarlockDemoSaved[MPWalockDemoConfig].PetAttack==1 and UnitAffectingCombat("target") then
		PetAttack()
	end

	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPWarlockDemoSaved[MPWalockDemoConfig].Trinket_Upper==1 then
			if MPWarlockDemoSaved[MPWalockDemoConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPWarlockDemoSaved[MPWalockDemoConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPWarlockDemoSaved[MPWalockDemoConfig].Trinket_Below==1 then
			if MPWarlockDemoSaved[MPWalockDemoConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPWarlockDemoSaved[MPWalockDemoConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPWarlockDemoSaved[MPWalockDemoConfig].Soulspeed==1 then
			if MPWarlockDemoSaved[MPWalockDemoConfig].SoulspeedBoss==0 or (MPWarlockDemoSaved[MPWalockDemoConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		if percent<MPWarlockDemoSaved[MPWalockDemoConfig].HealthStone_Value and MPWarlockDemoSaved[MPWalockDemoConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPWarlockDemoSaved[MPWalockDemoConfig].HerbalTea_Value and MPWarlockDemoSaved[MPWalockDemoConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPWarlockDemoSaved[MPWalockDemoConfig].HerbalTeaMana_Value and MPWarlockDemoSaved[MPWalockDemoConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		-- 特定 种族天赋 --

		if MPWarlockDemoSaved[MPWalockDemoConfig].RacialTraits==1 then
			if MPWarlockDemoSaved[MPWalockDemoConfig].RacialTraitsBoss==0 or (MPWarlockDemoSaved[MPWalockDemoConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

	-- 生命分流
	if MPWarlockDemoSaved[MPWalockDemoConfig].LifeTap==1 and percent>MPWarlockDemoSaved[MPWalockDemoConfig].LifeTap_Value and percentMana<=MPWarlockDemoSaved[MPWalockDemoConfig].LifeTap_Mana then
		local dec = UnitManaMax("player") - UnitMana("player")
		if dec > 2000 then
			CastSpellByName("生命分流")
			return
		end
	end


	-- 未进入战斗
	if not MPInCombat and MPWarlockDemoSaved[MPWalockDemoConfig].FirstShadowBolt==1 then
		MPCastShadowBolt()
		return
	end

	-- 超越之力
	if MPWarlockDemoSaved[MPWalockDemoConfig].Overpowering==1 and CYZL then
		if UnitExists("pet") and not UnitIsDead("pet") then
			CastSpellByName("超越之力")
			return
		end
	end



	if MPWarlockDemoSaved[MPWalockDemoConfig].CurseFatigue==1 and not MPBuff("疲劳诅咒","target") then
		MPCastCurseFatigue()
		return
	end

	-- 厄运诅咒
	if MPWarlockDemoSaved[MPWalockDemoConfig].CurseDoom==1 and EYZZ then
		MPCastCurseDoom()
		return
	end


	-- 腐蚀术
	if MPWarlockDemoSaved[MPWalockDemoConfig].Corruption==1 and not MPGetCorruptionDot() then
		if MPWarlockDemoSaved[MPWalockDemoConfig].CorruptionBoss==0 or (MPWarlockDemoSaved[MPWalockDemoConfig].CorruptionBoss==1 and MPIsBossTarget()) then
			MPCastCorruption()
			return
		end
	end

	-- 大诅咒
	local bigdot = false
	if MPWarlockDemoSaved[MPWalockDemoConfig].CurseBOSS==0 then
		bigdot = true
	else
		if MPIsBossTarget() then
			bigdot = true
		end
	end
		
	if bigdot then

		if MPWarlockDemoSaved[MPWalockDemoConfig].CurseRecklessness==1 and not MPBuff("鲁莽诅咒","target") then
			MPCastCurseRecklessness()
			return
		end

		if MPWarlockDemoSaved[MPWalockDemoConfig].CurseElements==1 and not MPBuff("元素诅咒","target") then
			MPCastCurseCurseElements()
			return
		end

		if MPWarlockDemoSaved[MPWalockDemoConfig].CurseShadow==1 and not MPBuff("暗影诅咒","target") then
			MPCastCurseShadow()
			return
		end

		if MPWarlockDemoSaved[MPWalockDemoConfig].CurseTongues==1 and not MPBuff("语言诅咒","target") then
			MPCastCurseTongues()
			return
		end

		if MPWarlockDemoSaved[MPWalockDemoConfig].CurseWeakness==1 and not MPBuff("虚弱诅咒","target") then
			MPCastCurseWeakness()
			return
		end

	end


	-- 痛苦诅咒、腐蚀术

	if MPWarlockDemoSaved[MPWalockDemoConfig].CurseAgony==1 and not MPGetCurseAgonyDot() then
		if MPWarlockDemoSaved[MPWalockDemoConfig].CurseAgonyBoss==0 or (MPWarlockDemoSaved[MPWalockDemoConfig].CurseAgonyBoss==1 and MPIsBossTarget()) then
			-- 是否有大诅咒设定
			local count = MPWarlockDemoSaved[MPWalockDemoConfig].CurseRecklessness+MPWarlockDemoSaved[MPWalockDemoConfig].CurseElements+MPWarlockDemoSaved[MPWalockDemoConfig].CurseShadow+MPWarlockDemoSaved[MPWalockDemoConfig].CurseTongues
			if count > 0 and MPWarlockDemoSaved[MPWalockDemoConfig].CurseEvil==1 and MPWarlockCurseEvil==1 then

				-- 邪咒 启动
				if MPWarlockDemoSaved[MPWalockDemoConfig].CurseRecklessness==1 then
					MPCastCurseRecklessness()
					return
				end

				if MPWarlockDemoSaved[MPWalockDemoConfig].CurseElements==1 then
					MPCastCurseCurseElements()
					return
				end

				if MPWarlockDemoSaved[MPWalockDemoConfig].CurseShadow==1 then
					--print("替代痛苦")
					MPCastCurseShadow()
					return
				end

			end

			--print("原始 - 痛苦")
			MPCastCurseAgony()
			return
		end
	end

	-- 献祭
	if MPWarlockDemoSaved[MPWalockDemoConfig].Immolate==1 and not MPGetImmolateDot() then
		MPCastImmolate()
		return
	end


	-- 释放潜力
	if MPWarlockDemoSaved[MPWalockDemoConfig].Potential==1 and MPGetPotential() then

		local timer = 20-(GetTime()-MPGetPotentialTimer())

		-- 释放潜力 条件结束
		if timer < MPWarlockDemoSaved[MPWalockDemoConfig].Potential_Value then

			-- 法力通道
			if MPWarlockDemoSaved[MPWalockDemoConfig].ManaChannel==1 then

				CastSpellByName("法力通道")
				return

			-- 生命通道
			elseif MPWarlockDemoSaved[MPWalockDemoConfig].LifeChannel==1 then

				CastSpellByName("生命通道")
				return

			end

		else

			-- 打断通道
			if MPGetManaChannel() or MPGetLifeChannel() then
				SpellStopCasting()
			end

		end

	end


	-- 暗影灼烧
	if MPWarlockDemoSaved[MPWalockDemoConfig].Shadowburn==1 and MPWarlockShadowburn==1 and AYZS then
		local SoulShards = MPGetItemByNameID("灵魂碎片")
		if DM>=MPWarlockShadowburnMana[6] and SoulShards>0 then
			local t = UnitExists("target")
			if t and MP_UnitXP then
				local rang = UnitXP("distanceBetween", "player", "target")
				if rang and rang<=(20+MPWarlockDestructionExtend) then
					if MPWarlockDemoSaved[MPWalockDemoConfig].ShadowburnBoss==1 and MPIsBossTarget() then
						MPCastShadowburn()
						return
					elseif MPWarlockDemoSaved[MPWalockDemoConfig].ShadowburnBoss==0 then
						MPCastShadowburn()
						return
					end
				end
			else
				if MPWarlockDemoSaved[MPWalockDemoConfig].ShadowburnBoss==1 and MPIsBossTarget() then
					MPCastShadowburn()
				elseif MPWarlockDemoSaved[MPWalockDemoConfig].ShadowburnBoss==0 then
					MPCastShadowburn()
				end
			end
		end
	end


	-- 暗影箭
	MPCastShadowBolt()


end

