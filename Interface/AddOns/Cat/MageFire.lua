if MPPlayerClass ~= "MAGE" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 火法一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
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


-- -------------------------------------

-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化

-- 火焰冲击距离
MPMageFireBlastDist = 20

-- 法术连击
MPMagePyromaniac = 0
MPMagePyromaniacTimer = 0

-- 炎爆术读条缓存
MPMageCastPyroblastTimer = 0

-- -------------------------------------

local MHP,DM,ASYD,HYCJ

-- 默认配置
MPMageFireConfig = 1


local function MageArmor()
	CastSpellByName("魔甲术")
end

local function ArcaneSurge()
	CastSpellByName("奥术涌动")
end

local function MageFire_FireBlast()
	if MP_UnitXP and UnitExists("target") then
		local inRange = UnitXP("distanceBetween", "player", "target")
		if MPMageFireSaved[MPMageFireConfig].FireBlast==1 and HYCJ and inRange<MPMageFireBlastDist then
			CastSpellByName("火焰冲击")
			return true
		end
	else
		if MPMageFireSaved[MPMageFireConfig].FireBlast==1 and HYCJ then
			CastSpellByName("火焰冲击")
		end
	end

	return false
end

local function MageFire_Scorch()
	if MPMageFireSaved[MPMageFireConfig].Scorch==1 then

		if MPGetDebuffApplications("Interface\\Icons\\Spell_Fire_SoulBurn", "target")<5 then
			if MP_SuperWoW then
				if MPGetFireDot() then
					local check = MPGetScorchCheck()
					local layer = MPGetFireVulnerabilityLayer()
					local a,guid=UnitExists("target")
					if layer[guid]<5 then
						CastSpellByName("灼烧")
						return true
					end
					if (30-(GetTime()-check[guid])) < 8 then
						CastSpellByName("灼烧")
						return true
					end
				else
					CastSpellByName("灼烧")
					return true
				end
			else
				CastSpellByName("灼烧")
				return true
			end
		end

	end

	return false
end


function MPMageFireAuto()

	MHP = UnitHealth("player")
	DM = UnitMana("player")
	ASYD = MPSpellReady("奥术涌动")
	HYCJ = MPSpellReadyOffset("火焰冲击")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100


	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPMageFireSaved[MPMageFireConfig].Target, 0)

	-- 开启自动攻击
	if MPMageFireSaved[MPMageFireConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPMageFireSaved[MPMageFireConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPMageFireSaved[MPMageFireConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPMageFireSaved[MPMageFireConfig].Trinket_Upper==1 then
			if MPMageFireSaved[MPMageFireConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPMageFireSaved[MPMageFireConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPMageFireSaved[MPMageFireConfig].Trinket_Below==1 then
			if MPMageFireSaved[MPMageFireConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPMageFireSaved[MPMageFireConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPMageFireSaved[MPMageFireConfig].Soulspeed==1 then
			if MPMageFireSaved[MPMageFireConfig].SoulspeedBoss==0 or (MPMageFireSaved[MPMageFireConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		if percent<MPMageFireSaved[MPMageFireConfig].HealthStone_Value and MPMageFireSaved[MPMageFireConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPMageFireSaved[MPMageFireConfig].HerbalTea_Value and MPMageFireSaved[MPMageFireConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPMageFireSaved[MPMageFireConfig].HerbalTeaMana_Value and MPMageFireSaved[MPMageFireConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPMageFireSaved[MPMageFireConfig].JewelMana_Value and MPMageFireSaved[MPMageFireConfig].JewelMana==1 then
			MPUseItemByName("法力红宝石")
			MPUseItemByName("法力黄水晶")
			MPUseItemByName("法力翡翠")
			MPUseItemByName("法力玛瑙")
		end

		-- 特定 种族天赋 --

		if MPMageFireSaved[MPMageFireConfig].RacialTraits==1 then
			if MPMageFireSaved[MPMageFireConfig].RacialTraitsBoss==0 or (MPMageFireSaved[MPMageFireConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

	--[[
	if MP_Nampower then
		SetCVar("NP_QueueCastTimeSpells", 0)
	end
	]]


	-- buff
	if MPMageFireSaved[MPMageFireConfig].MageArmor==1 and not MPBuff("魔甲术") then
		MageArmor()
	end


	-- 未进入战斗
	if not MPInCombat then
		if MPMageFireSaved[MPMageFireConfig].FirstPyroblast==1 then
			CastSpellByName("炎爆术")
			return
		else
			if MPMageFireSaved[MPMageFireConfig].Scorch==1 and MPGetDebuffApplications("Interface\\Icons\\Spell_Fire_SoulBurn", "target")<5 then
				CastSpellByName("灼烧")
				return
			else
				CastSpellByName("火球术")
				return
			end
		end
	end


	-- 奥术涌动
	if MPMageFireSaved[MPMageFireConfig].ArcaneSurge==1 and MPGetMageArcaneSurge() and ASYD then
		ArcaneSurge()
		return
	end

	-- 保护 点燃
	if MPMageFireSaved[MPMageFireConfig].IgniteProtect==1 and GetNumRaidMembers()>5 then 
		if MPBuff("点燃", "target") or (GetTime()-MPInCombatTime)>12 then
			-- 火焰冲击
			if MageFire_FireBlast() then
				return
			end

			-- 灼烧
			if MageFire_Scorch() then
				return
			end
		end
	else
		-- 火焰冲击
		if MageFire_FireBlast() then
			return
		end

		-- 灼烧
		if MageFire_Scorch() then
			return
		end
	end
	


	-- 填充

	if MPMageFireSaved[MPMageFireConfig].Pyroblast==1 and GetTime()-MPMageCastPyroblastTimer>0 then
		if MPGetBuffApplications("Interface\\Icons\\Ability_Mage_Firestarter") >= MPMageFireSaved[MPMageFireConfig].Pyromaniac then
			MPCastWithoutNampower("炎爆术")
			return
		end
	end

	if MPMageFireSaved[MPMageFireConfig].Fireball==1 then
		CastSpellByName("火球术")
	end

end

