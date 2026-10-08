if MPPlayerClass ~= "WARLOCK" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 痛苦术一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：无
--
-- 说明：
-- 
-- -------------------------------------


local MHP,DM,AYZS,AYSG,EYZZ

MPShadowTwilightTimer = 0

-- 默认配置
MPWarlockAffConfig = 1


local function MPCastCurseAgony()
	if DM>=MPCurseAgonyMana[6] then
		MPCast("痛苦诅咒")
	else
		MPCast("痛苦诅咒(等级 1)")
	end
end

local function MPCastCorruption()
	if DM>=MPWarlockCorruptionMana[7] then
		MPCast("腐蚀术")
	else
		MPCast("腐蚀术(等级 3)")
	end
end

local function MPCastImmolate()
	if DM>=MPWarlockImmolateMana[8] then
		MPCast("献祭")
	else
		MPCast("献祭(等级 1)")
	end
end

local function MPCastSiphonLife()
	if DM>=MPWarlockSiphonLifeMana[4] then
		MPCast("生命虹吸")
	else
		MPCast("生命虹吸(等级 1)")
	end
end

local function MPCastShadowburn()
	if DM>=MPWarlockShadowburnMana[6] then
		MPCast("暗影灼烧")
	else
		MPCast("暗影灼烧(等级 1)")
	end
end

local function MPCastShadowBolt()
	if DM>=MPWarlockShadowBoltMana[10] then
		MPCast("暗影箭")
	else
		MPCast("暗影箭(等级 1)")
	end
end

local function MPCastCurseRecklessness()
	MPCast("鲁莽诅咒")
end

local function MPCastCurseCurseElements()
	MPCast("元素诅咒")
end

local function MPCastCurseShadow()
	MPCast("暗影诅咒")
end

local function MPCastCurseTongues()
	MPCast("语言诅咒")
end

local function MPCastCurseWeakness()
	MPCast("虚弱诅咒")
end

local function MPCastCurseFatigue()
	MPCast("疲劳诅咒")
end

local function MPCastCurseDoom()
	MPCast("疲劳诅咒")
end





function MPWarlockAff()

	MHP = UnitHealth("player")
	DM = UnitMana("player")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100
	if MPWarlockShadowburn==1 then AYZS = MPSpellReady("暗影灼烧") else AYZS=false end
	if MPWarlockShadowHarvest==1 then AYSG = MPSpellReadyOffset("暗影收割") else AYSG=false end
	EYZZ = MPSpellReady("厄运诅咒")

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPWarlockAffSaved[MPWarlockAffConfig].Target, 0)

	-- 开启自动攻击
	if MPWarlockAffSaved[MPWarlockAffConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPWarlockAffSaved[MPWarlockAffConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPWarlockAffSaved[MPWarlockAffConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 宠物攻击
	if MPWarlockAffSaved[MPWarlockAffConfig].PetAttack==1 and UnitAffectingCombat("target") then
		PetAttack()
	end

	-- 未进入战斗
	if not MPInCombat and MPWarlockAffSaved[MPWarlockAffConfig].FirstShadowBolt==1 then
		MPCastShadowBolt()
		return
	end

	-- 防护读条
	if MPGetWarlockChanneled()>0 then
		if MPWarlockAffSaved[MPWarlockAffConfig].ClipDrainSoul==1 then
			-- 保护暗影收割
			if MPGetWarlockChanneledSpellID()==52550 or MPGetWarlockChanneledSpellID()==52551 or MPGetWarlockChanneledSpellID()==52552 then
				return
			end
		else
			return
		end
	end


	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if MPWarlockAffSaved[MPWarlockAffConfig].Trinket_Upper==1 then
			if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 then
				if MPWarlockAffSaved[MPWarlockAffConfig].TUBoss==1 and MPIsBossTarget() then
					UseInventoryItem(13)
				elseif MPWarlockAffSaved[MPWarlockAffConfig].TUBoss==0 then
					UseInventoryItem(13)
				end
			end
		end

		if MPWarlockAffSaved[MPWarlockAffConfig].Trinket_Below==1 then
			if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 then
				if MPWarlockAffSaved[MPWarlockAffConfig].TBBoss==1 and MPIsBossTarget() then
					UseInventoryItem(14)
				elseif MPWarlockAffSaved[MPWarlockAffConfig].TBBoss==0 then
					UseInventoryItem(14)
				end
			end
		end

		if MPWarlockAffSaved[MPWarlockAffConfig].Soulspeed==1 then
			if MPWarlockAffSaved[MPWarlockAffConfig].SoulspeedBoss==0 or (MPWarlockAffSaved[MPWarlockAffConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		if percent<MPWarlockAffSaved[MPWarlockAffConfig].HealthStone_Value and MPWarlockAffSaved[MPWarlockAffConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPWarlockAffSaved[MPWarlockAffConfig].HerbalTea_Value and MPWarlockAffSaved[MPWarlockAffConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPWarlockAffSaved[MPWarlockAffConfig].HerbalTeaMana_Value and MPWarlockAffSaved[MPWarlockAffConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		-- 特定 种族天赋 --

		if MPWarlockAffSaved[MPWarlockAffConfig].RacialTraits==1 then
			if MPWarlockAffSaved[MPWarlockAffConfig].RacialTraitsBoss==0 or (MPWarlockAffSaved[MPWarlockAffConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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




	-- 暗影冥思、夜幕
	local at = GetTime()-MPShadowTwilightTimer
	if GetTime()-MPShadowTwilightTimer>2.5 then
		if MPBuffFromTex("Interface\\Icons\\Spell_Shadow_Twilight") then
			--MPMsg(at.." - "..MPShadowTwilightTimer)
			MPCast("暗影箭")
			if MP_UnitXP then
				local inRange = UnitXP("distanceBetween", "player", "target")
				if inRange <= 30 then
					return
				end
			end
		end
	end


	-- 疲劳诅咒
	if MPWarlockAffSaved[MPWarlockAffConfig].CurseFatigue==1 and not MPBuff("疲劳诅咒","target") then
		MPCastCurseFatigue()
		return
	end

	-- 厄运诅咒
	if MPWarlockAffSaved[MPWarlockAffConfig].CurseDoom==1 and EYZZ then
		MPCastCurseDoom()
		return
	end


	local bigdot = false
	if MPWarlockAffSaved[MPWarlockAffConfig].CurseBOSS==0 then
		bigdot = true
	else
		if MPIsBossTarget() then
			bigdot = true
		end
	end

	-- 大诅咒 BOSS
	if bigdot then

		if MPWarlockAffSaved[MPWarlockAffConfig].CurseRecklessness==1 and not MPBuff("鲁莽诅咒","target") then
			MPCastCurseRecklessness()
			return
		end

		if MPWarlockAffSaved[MPWarlockAffConfig].CurseElements==1 and not MPBuff("元素诅咒","target") then
			MPCastCurseCurseElements()
			return
		end

		if MPWarlockAffSaved[MPWarlockAffConfig].CurseShadow==1 and not MPBuff("暗影诅咒","target") then
			MPCastCurseShadow()
			return
		end

		if MPWarlockAffSaved[MPWarlockAffConfig].CurseTongues==1 and not MPBuff("语言诅咒","target") then
			MPCastCurseTongues()
			return
		end

		if MPWarlockAffSaved[MPWarlockAffConfig].CurseWeakness==1 and not MPBuff("虚弱诅咒","target") then
			MPCastCurseWeakness()
			return
		end

	end



	-- 痛苦诅咒、腐蚀术、生命虹吸
	if MPWarlockAffSaved[MPWarlockAffConfig].CurseAgony==1 and not MPGetCurseAgonyDot("target", 0) then
		if MPWarlockAffSaved[MPWarlockAffConfig].CurseAgonyBoss==0 or (MPWarlockAffSaved[MPWarlockAffConfig].CurseAgonyBoss==1 and MPIsBossTarget()) then
			-- 是否有大诅咒设定
			local count = MPWarlockAffSaved[MPWarlockAffConfig].CurseRecklessness+MPWarlockAffSaved[MPWarlockAffConfig].CurseElements+MPWarlockAffSaved[MPWarlockAffConfig].CurseShadow
			if count > 0 and MPWarlockAffSaved[MPWarlockAffConfig].CurseEvil==1 and MPWarlockCurseEvil==1 then

				-- 邪咒 启动
				if MPWarlockAffSaved[MPWarlockAffConfig].CurseRecklessness==1 then
					MPCastCurseRecklessness()
					return
				end

				if MPWarlockAffSaved[MPWarlockAffConfig].CurseElements==1 then
					MPCastCurseCurseElements()
					return
				end

				if MPWarlockAffSaved[MPWarlockAffConfig].CurseShadow==1 then
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

	-- 腐蚀术
	if MPWarlockAffSaved[MPWarlockAffConfig].Corruption==1 and not MPGetCorruptionDot("target", 0) then
		if MPWarlockAffSaved[MPWarlockAffConfig].CorruptionBoss==0 or (MPWarlockAffSaved[MPWarlockAffConfig].CorruptionBoss==1 and MPIsBossTarget()) then
			MPCastCorruption()
			return
		end
	end

	-- 生命虹吸
	if MPWarlockAffSaved[MPWarlockAffConfig].SiphonLife==1 and MPWarlockSiphonLife==1 and not MPGetSiphonLifeDot("target", 0) and MPIsDrain() then 
		if MPWarlockAffSaved[MPWarlockAffConfig].SiphonLifeBoss==0 or (MPWarlockAffSaved[MPWarlockAffConfig].SiphonLifeBoss==1 and MPIsBossTarget()) then
			MPCastSiphonLife()
			return
		end
	end

	-- 献祭
	if MPWarlockAffSaved[MPWarlockAffConfig].Immolate==1 and not MPGetImmolateDot() and GetTime()-MPImmolateTimer>2 then
		MPCastImmolate()
		return
	end



	-- 防护读条
	if MPGetWarlockChanneled()>0 then
		return
	end

	-- 生命分流
	if MPWarlockAffSaved[MPWarlockAffConfig].LifeTap==1 and percent>MPWarlockAffSaved[MPWarlockAffConfig].LifeTap_Value and percentMana<=MPWarlockAffSaved[MPWarlockAffConfig].LifeTap_Mana then
		local dec = UnitManaMax("player") - UnitMana("player")
		if dec > 2000 then
			CastSpellByName("生命分流")
			return
		end
	end

	-- 暗影灼烧
	if MPWarlockAffSaved[MPWarlockAffConfig].Shadowburn==1 and MPWarlockShadowburn==1 and AYZS and DM>=MPWarlockShadowburnMana[6] then
		if MPWarlockAffSaved[MPWarlockAffConfig].ShadowburnBoss==1 and MPIsBossTarget() then
			MPCastShadowburn()
			return
		elseif MPWarlockAffSaved[MPWarlockAffConfig].ShadowburnBoss==0 then
			MPCastShadowburn()
			return
		end
	end

	-- 暗影收割
	if MPWarlockAffSaved[MPWarlockAffConfig].ShadowHarvest==1 and MPWarlockShadowHarvest==1 and AYSG then
		MPCast("暗影收割")
		return
	end

	-- 吸取生命
	if MPWarlockAffSaved[MPWarlockAffConfig].DrainLife==1 and MPIsDrain() then
		CastSpellByName("吸取生命")
		return
	end

	-- 吸取灵魂
	if MPWarlockAffSaved[MPWarlockAffConfig].DrainSoul==1 then
		CastSpellByName("吸取灵魂")
		return
	end

	-- 暗影箭
	MPCastShadowBolt()


end

