if MPPlayerClass ~= "WARLOCK" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 暗毁术一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
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
MPWarlockSDConfig = 1

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
	MPCastWithoutNampower("疲劳诅咒")
end




function MPWarlockSD()

	MHP = UnitHealth("player")
	DM = UnitMana("player")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100
	if MPWarlockShadowburn==1 then AYZS = MPSpellReady("暗影灼烧") else AYZS=false end
	if MPWarlockOverpowering==1 then CYZL = MPSpellReady("超越之力") else CYZL=false end
	EYZZ = MPSpellReady("厄运诅咒")

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPWarlockSDSaved[MPWarlockSDConfig].Target, 0)

	-- 开启自动攻击
	if MPWarlockSDSaved[MPWarlockAffConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPWarlockSDSaved[MPWarlockSDConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPWarlockSDSaved[MPWarlockSDConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 宠物攻击
	if MPWarlockSDSaved[MPWarlockSDConfig].PetAttack==1 and UnitAffectingCombat("target") then
		PetAttack()
	end


	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPWarlockSDSaved[MPWarlockSDConfig].Trinket_Upper==1 then
			if MPWarlockSDSaved[MPWarlockSDConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPWarlockSDSaved[MPWarlockSDConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPWarlockSDSaved[MPWarlockSDConfig].Trinket_Below==1 then
			if MPWarlockSDSaved[MPWarlockSDConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPWarlockSDSaved[MPWarlockSDConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPWarlockSDSaved[MPWarlockSDConfig].Soulspeed==1 then
			if MPWarlockSDSaved[MPWarlockSDConfig].SoulspeedBoss==0 or (MPWarlockSDSaved[MPWarlockSDConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		if percent<MPWarlockSDSaved[MPWarlockSDConfig].HealthStone_Value and MPWarlockSDSaved[MPWarlockSDConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPWarlockSDSaved[MPWarlockSDConfig].HerbalTea_Value and MPWarlockSDSaved[MPWarlockSDConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPWarlockSDSaved[MPWarlockSDConfig].HerbalTeaMana_Value and MPWarlockSDSaved[MPWarlockSDConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		-- 特定 种族天赋 --

		if MPWarlockSDSaved[MPWarlockSDConfig].RacialTraits==1 then
			if MPWarlockSDSaved[MPWarlockSDConfig].RacialTraitsBoss==0 or (MPWarlockSDSaved[MPWarlockSDConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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
	if MPWarlockSDSaved[MPWarlockSDConfig].LifeTap==1 and percent>MPWarlockSDSaved[MPWarlockSDConfig].LifeTap_Value and percentMana<=MPWarlockSDSaved[MPWarlockSDConfig].LifeTap_Mana then
		local dec = UnitManaMax("player") - UnitMana("player")
		if dec > 2000 then
			CastSpellByName("生命分流")
			return
		end
	end


	-- 未进入战斗
	if not MPInCombat and MPWarlockSDSaved[MPWarlockSDConfig].FirstShadowBolt==1 then
		MPCastShadowBolt()
		return
	end

	-- 超越之力
	if MPWarlockSDSaved[MPWarlockSDConfig].Overpowering==1 and CYZL then
		if UnitExists("pet") and not UnitIsDead("pet") then
			CastSpellByName("超越之力")
			return
		end
	end



	if MPWarlockSDSaved[MPWarlockSDConfig].CurseFatigue==1 and not MPBuff("疲劳诅咒","target") then
		MPCastCurseFatigue()
		return
	end

	-- 厄运诅咒
	if MPWarlockSDSaved[MPWarlockSDConfig].CurseDoom==1 and EYZZ then
		MPCastCurseDoom()
		return
	end

	-- 痛苦诅咒、腐蚀术、生命虹吸

	-- 大诅咒
	local bigdot = false
	if MPWarlockSDSaved[MPWarlockSDConfig].CurseBOSS==0 then
		bigdot = true
	else
		if MPIsBossTarget() then
			bigdot = true
		end
	end
		
	if bigdot then

		if MPWarlockSDSaved[MPWarlockSDConfig].CurseRecklessness==1 and not MPBuff("鲁莽诅咒","target") then
			MPCastCurseRecklessness()
			return
		end

		if MPWarlockSDSaved[MPWarlockSDConfig].CurseElements==1 and not MPBuff("元素诅咒","target") then
			MPCastCurseCurseElements()
			return
		end

		if MPWarlockSDSaved[MPWarlockSDConfig].CurseShadow==1 and not MPBuff("暗影诅咒","target") then
			MPCastCurseShadow()
			return
		end

		if MPWarlockSDSaved[MPWarlockSDConfig].CurseTongues==1 and not MPBuff("语言诅咒","target") then
			MPCastCurseTongues()
			return
		end

		if MPWarlockSDSaved[MPWarlockSDConfig].CurseWeakness==1 and not MPBuff("虚弱诅咒","target") then
			MPCastCurseWeakness()
			return
		end

	end



	-- 腐蚀术
	if MPWarlockSDSaved[MPWarlockSDConfig].Corruption==1 and not MPGetCorruptionDot() then
		if MPWarlockSDSaved[MPWarlockSDConfig].CorruptionBoss==0 or (MPWarlockSDSaved[MPWarlockSDConfig].CorruptionBoss==1 and MPIsBossTarget()) then
			MPCastCorruption()
			return
		end
	end

	-- 痛苦诅咒
	if MPWarlockSDSaved[MPWarlockSDConfig].CurseAgony==1 and not MPGetCurseAgonyDot() then

		-- BOSS状态
		if MPWarlockSDSaved[MPWarlockSDConfig].CurseAgonyBoss==0 or (MPWarlockSDSaved[MPWarlockSDConfig].CurseAgonyBoss==1 and MPIsBossTarget()) then

			-- 是否有大诅咒设定
			local count = MPWarlockSDSaved[MPWarlockSDConfig].CurseRecklessness+MPWarlockSDSaved[MPWarlockSDConfig].CurseElements+MPWarlockSDSaved[MPWarlockSDConfig].CurseShadow+MPWarlockSDSaved[MPWarlockSDConfig].CurseTongues
			if count > 0 and MPWarlockSDSaved[MPWarlockSDConfig].CurseEvil==1 and MPWarlockCurseEvil==1 then


				-- 邪咒 启动
				if MPWarlockSDSaved[MPWarlockSDConfig].CurseRecklessness==1 then
					MPCastCurseRecklessness()
					return
				end

				if MPWarlockSDSaved[MPWarlockSDConfig].CurseElements==1 then
					MPCastCurseCurseElements()
					return
				end

				if MPWarlockSDSaved[MPWarlockSDConfig].CurseShadow==1 then
					--print("替代痛苦")
					MPCastCurseShadow()
					return
				end

			end

			-- 不开启邪咒，痛苦组织直接补
			MPCastCurseAgony()
			return

		end
	end

	-- 生命虹吸
	if MPWarlockSDSaved[MPWarlockSDConfig].SiphonLife==1 and MPWarlockSiphonLife==1 and not MPGetSiphonLifeDot() and MPIsDrain() then 
		if MPWarlockSDSaved[MPWarlockSDConfig].SiphonLifeBoss==0 or (MPWarlockSDSaved[MPWarlockSDConfig].SiphonLifeBoss==1 and MPIsBossTarget()) then
			MPCastSiphonLife()
			return
		end
	end

	-- 献祭
	if MPWarlockSDSaved[MPWarlockSDConfig].Immolate==1 and not MPGetImmolateDot() then
		MPCastImmolate()
		return
	end


	-- 暗影灼烧
	if MPWarlockSDSaved[MPWarlockSDConfig].Shadowburn==1 and MPWarlockShadowburn==1 and AYZS then
		local SoulShards = MPGetItemByNameID("灵魂碎片")
		if DM>=MPWarlockShadowburnMana[6] and SoulShards>0 then
			local t = UnitExists("target")
			if t and MP_UnitXP then
				local rang = UnitXP("distanceBetween", "player", "target")
				if rang and rang<=(20+MPWarlockDestructionExtend) then
					if MPWarlockSDSaved[MPWarlockSDConfig].ShadowburnBoss==1 and MPIsBossTarget() then
						MPCastShadowburn()
						return
					elseif MPWarlockSDSaved[MPWarlockSDConfig].ShadowburnBoss==0 then
						MPCastShadowburn()
						return
					end
				end
			else
				if MPWarlockSDSaved[MPWarlockSDConfig].ShadowburnBoss==1 and MPIsBossTarget() then
					MPCastShadowburn()
				elseif MPWarlockSDSaved[MPWarlockSDConfig].ShadowburnBoss==0 then
					MPCastShadowburn()
				end
			end
		end
	end


	-- 暗影箭
	MPCastShadowBolt()


end

