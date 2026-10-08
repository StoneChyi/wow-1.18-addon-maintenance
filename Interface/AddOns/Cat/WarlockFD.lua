if MPPlayerClass ~= "WARLOCK" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 火毁术一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：无
--
-- 说明：
-- 
-- -------------------------------------


local MHP,DM,AYZS,RS,LHZH,CYZL,EYZZ

-- 默认配置
MPWarlockFDConfig = 1


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
		CastSpellByName("生命虹吸")
	else
		CastSpellByName("生命虹吸(等级 1)")
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

local function MPCastSoulFire()
	if DM>=MPWarlockSoulFireMana[4] then
		CastSpellByName("灵魂之火")
	else
		CastSpellByName("灵魂之火(等级 1)")
	end
end

local function MPCastConflagrate()
	if DM>=MPWarlockConflagrateMana[4] then
		CastSpellByName("燃烧")
	else
		CastSpellByName("燃烧(等级 1)")
	end
end

local function MPCastSearingPain()
	if DM>=MPWarlockSearingPainMana[6] then
		CastSpellByName("灼热之痛")
	else
		CastSpellByName("灼热之痛(等级 1)")
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
	MPCastWithoutNampower("疲劳诅咒")
end



function MPWarlockFD()

	MHP = UnitHealth("player")
	DM = UnitMana("player")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100
	if MPWarlockShadowburn==1 then AYZS = MPSpellReady("暗影灼烧") else AYZS=false end
	RS = MPSpellReadyOffset("燃烧",1.0)
	LHZH = MPSpellReadyOffset("灵魂之火",1.0)
	EYZZ = MPSpellReady("厄运诅咒")
	if MPWarlockOverpowering==1 then CYZL = MPSpellReady("超越之力") else CYZL=false end

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPWarlockFDSaved[MPWarlockFDConfig].Target, 0)

	-- 开启自动攻击
	if MPWarlockFDSaved[MPWarlockAffConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPWarlockFDSaved[MPWarlockFDConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPWarlockFDSaved[MPWarlockFDConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 宠物攻击
	if MPWarlockFDSaved[MPWarlockFDConfig].PetAttack==1 and UnitAffectingCombat("target") then
		PetAttack()
	end


	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPWarlockFDSaved[MPWarlockFDConfig].Trinket_Upper==1 then
			if MPWarlockFDSaved[MPWarlockFDConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPWarlockFDSaved[MPWarlockFDConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPWarlockFDSaved[MPWarlockFDConfig].Trinket_Below==1 then
			if MPWarlockFDSaved[MPWarlockFDConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPWarlockFDSaved[MPWarlockFDConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPWarlockFDSaved[MPWarlockFDConfig].Soulspeed==1 then
			if MPWarlockFDSaved[MPWarlockFDConfig].SoulspeedBoss==0 or (MPWarlockFDSaved[MPWarlockFDConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		if percent<MPWarlockFDSaved[MPWarlockFDConfig].HealthStone_Value and MPWarlockFDSaved[MPWarlockFDConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPWarlockFDSaved[MPWarlockFDConfig].HerbalTea_Value and MPWarlockFDSaved[MPWarlockFDConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPWarlockFDSaved[MPWarlockFDConfig].HerbalTeaMana_Value and MPWarlockFDSaved[MPWarlockFDConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		-- 特定 种族天赋 --

		if MPWarlockFDSaved[MPWarlockFDConfig].RacialTraits==1 then
			if MPWarlockFDSaved[MPWarlockFDConfig].RacialTraitsBoss==0 or (MPWarlockFDSaved[MPWarlockFDConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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
	if MPWarlockFDSaved[MPWarlockFDConfig].LifeTap==1 and percent>MPWarlockFDSaved[MPWarlockFDConfig].LifeTap_Value and percentMana<=MPWarlockFDSaved[MPWarlockFDConfig].LifeTap_Mana then
		local dec = UnitManaMax("player") - UnitMana("player")
		if dec > 2000 then
			CastSpellByName("生命分流")
			return
		end
	end


	-- 未进入战斗
	if not MPInCombat and MPWarlockFDSaved[MPWarlockFDConfig].First==1 and LHZH then
		MPCastSoulFire()
		return
	end

	-- 超越之力
	if MPWarlockFDSaved[MPWarlockFDConfig].Overpowering==1 and CYZL then
		if UnitExists("pet") and not UnitIsDead("pet") then
			CastSpellByName("超越之力")
			return
		end
	end


	if MPWarlockFDSaved[MPWarlockFDConfig].CurseFatigue==1 and not MPBuff("疲劳诅咒","target") then
		MPCastCurseFatigue()
		return
	end

	-- 厄运诅咒
	if MPWarlockFDSaved[MPWarlockFDConfig].CurseDoom==1 and EYZZ then
		MPCastCurseDoom()
		return
	end


	-- 大诅咒
	
	local bigdot = false
	if MPWarlockFDSaved[MPWarlockFDConfig].CurseBOSS==0 then
		bigdot = true
	else
		if MPIsBossTarget() then
			bigdot = true
		end
	end


	if bigdot then


		if MPWarlockFDSaved[MPWarlockFDConfig].CurseRecklessness==1 and not MPBuff("鲁莽诅咒","target") and MPGetTargetDistance("target", 30+MPWarlockRuthlessExtend) then
			MPCastCurseRecklessness()
			if MP_UnitXP then
				return
			end
		end

		if MPWarlockFDSaved[MPWarlockFDConfig].CurseElements==1 and not MPBuff("元素诅咒","target") and MPGetTargetDistance("target", 30+MPWarlockRuthlessExtend) then
			MPCastCurseCurseElements()
			if MP_UnitXP then
				return
			end
		end

		if MPWarlockFDSaved[MPWarlockFDConfig].CurseShadow==1 and not MPBuff("暗影诅咒","target") and MPGetTargetDistance("target", 30+MPWarlockRuthlessExtend) then
			MPCastCurseShadow()
			if MP_UnitXP then
				return
			end
		end

		if MPWarlockFDSaved[MPWarlockFDConfig].CurseTongues==1 and not MPBuff("语言诅咒","target") and MPGetTargetDistance("target", 30+MPWarlockRuthlessExtend) then
			MPCastCurseTongues()
			if MP_UnitXP then
				return
			end
		end

		if MPWarlockFDSaved[MPWarlockFDConfig].CurseWeakness==1 and not MPBuff("虚弱诅咒","target") and MPGetTargetDistance("target", 30+MPWarlockRuthlessExtend) then
			MPCastCurseWeakness()
			return
		end

	end



	-- 痛苦诅咒
	if MPWarlockFDSaved[MPWarlockFDConfig].CurseAgony==1 and not MPGetCurseAgonyDot() and MPGetTargetDistance("target", 30+MPWarlockRuthlessExtend) then
		if MPWarlockFDSaved[MPWarlockFDConfig].CurseAgonyBoss==0 or (MPWarlockFDSaved[MPWarlockFDConfig].CurseAgonyBoss==1 and MPIsBossTarget()) then
			MPCastCurseAgony()
			return
		end
	end


	-- 腐蚀术
	if MPWarlockFDSaved[MPWarlockFDConfig].Corruption==1 and not MPGetCorruptionDot() and MPGetTargetDistance("target", 30+MPWarlockRuthlessExtend) then
		if MPWarlockFDSaved[MPWarlockFDConfig].CorruptionBoss==0 or (MPWarlockFDSaved[MPWarlockFDConfig].CorruptionBoss==1 and MPIsBossTarget()) then
			MPCastCorruption()
			return
		end
	end





	-- 燃烧
	if MPWarlockFDSaved[MPWarlockFDConfig].Conflagrate==1 and MPWarlockConflagrate==1 and RS and MPGetImmolateDot("target", 4) then
		MPCastConflagrate()
		return
	end



	-- 灵魂之火
	if MPWarlockFDSaved[MPWarlockFDConfig].SoulFireBoss==1 and not MPIsBossTarget() then
	else
		if MPWarlockFDSaved[MPWarlockFDConfig].SoulFire==1 and LHZH then
			MPCastSoulFire()
			return
		end
	end

	-- 献祭
	if MPWarlockFDSaved[MPWarlockFDConfig].Immolate==1 and not MPGetImmolateDot("target", 1.5) and GetTime()-MPImmolateTimer>1.6 then
		MPCastImmolate()
		return
	end



	-- 暗影灼烧
	if MPWarlockFDSaved[MPWarlockFDConfig].Shadowburn==1 and MPWarlockShadowburn==1 and AYZS then
		local SoulShards = MPGetItemByNameID("灵魂碎片")
		if DM>=MPWarlockShadowburnMana[6] and SoulShards>0 then
			local t = UnitExists("target")
			if t and MP_UnitXP then
				local rang = UnitXP("distanceBetween", "player", "target")
				if rang and rang<=(20+MPWarlockDestructionExtend) then
					if MPWarlockFDSaved[MPWarlockFDConfig].ShadowburnBoss==1 and MPIsBossTarget() then
						MPCastShadowburn()
						return
					elseif MPWarlockFDSaved[MPWarlockFDConfig].ShadowburnBoss==0 then
						MPCastShadowburn()
						return
					end
				end
			else
				if MPWarlockFDSaved[MPWarlockFDConfig].ShadowburnBoss==1 and MPIsBossTarget() then
					MPCastShadowburn()
				elseif MPWarlockFDSaved[MPWarlockFDConfig].ShadowburnBoss==0 then
					MPCastShadowburn()
				end
			end
		end
	end


	-- 灼热之痛
	if MPWarlockFDSaved[MPWarlockFDConfig].SearingPain==1 then
		MPCastSearingPain()
	end

	-- 暗影箭
	if MPWarlockFDSaved[MPWarlockFDConfig].ShadowBolt==1 then
		MPCastShadowBolt()
	end


end

