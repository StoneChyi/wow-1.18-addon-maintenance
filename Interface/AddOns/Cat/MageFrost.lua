if MPPlayerClass ~= "MAGE" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 冰法一键宏
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


-- 冰锥术 距离
MPMageConeColdDist = 10

-- 寒冰护体
MPMageIceBarrier = 0

-- 冰柱
MPMageIcicle = 0

-- -------------------------------------

local MHP,DM,BZS,BZ,ASYD,BSXX,HBHT,HYCJ

-- 默认配置
MPMageFrostConfig = 1


local function MageArmor()
	CastSpellByName("魔甲术")
end

local function IceBarrier()
	CastSpellByName("寒冰护体")
end

local function Frostbolt()
	CastSpellByName("寒冰箭")
end

local function ConeCold()
	CastSpellByName("冰锥术")
end

local function FrostNova()
	CastSpellByName("冰霜新星(等级 1)")
end

local function Icicle()
	CastSpellByName("冰柱")
end

local function ArcaneSurge()
	CastSpellByName("奥术涌动")
end

local function MageFrost_FireBlast()
	if MP_UnitXP and UnitExists("target") then
		local inRange = UnitXP("distanceBetween", "player", "target")
		if MPMageFrostSaved[MPMageFrostConfig].FireBlast==1 and HYCJ and inRange<MPMageFireBlastDist then
			CastSpellByName("火焰冲击")
			return
		end
	else
		if MPMageFrostSaved[MPMageFrostConfig].FireBlast==1 and HYCJ then
			CastSpellByName("火焰冲击")
		end
	end
end


function MPMageFrostAuto()

	MHP = UnitHealth("player")
	DM = UnitMana("player")
	BZS = MPSpellReady("冰锥术")
	BSXX = MPSpellReady("冰霜新星")
	BZ = MPSpellReadyOffset("冰柱",1.5)
	ASYD = MPSpellReady("奥术涌动")
	HBHT = MPSpellReady("寒冰护体")
	HYCJ = MPSpellReady("火焰冲击")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100


	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPMageFrostSaved[MPMageFrostConfig].Target, 0)

	-- 开启自动攻击
	if MPMageFrostSaved[MPMageFrostConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPMageFrostSaved[MPMageFrostConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPMageFrostSaved[MPMageFrostConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPMageFrostSaved[MPMageFrostConfig].Trinket_Upper==1 then
			if MPMageFrostSaved[MPMageFrostConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPMageFrostSaved[MPMageFrostConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPMageFrostSaved[MPMageFrostConfig].Trinket_Below==1 then
			if MPMageFrostSaved[MPMageFrostConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPMageFrostSaved[MPMageFrostConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPMageFrostSaved[MPMageFrostConfig].Soulspeed==1 and GetMageArcaneMissiles()<=0 then
			if MPMageFrostSaved[MPMageFrostConfig].SoulspeedBoss==0 or (MPMageFrostSaved[MPMageFrostConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		if percent<MPMageFrostSaved[MPMageFrostConfig].HealthStone_Value and MPMageFrostSaved[MPMageFrostConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPMageFrostSaved[MPMageFrostConfig].HerbalTea_Value and MPMageFrostSaved[MPMageFrostConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPMageFrostSaved[MPMageFrostConfig].HerbalTeaMana_Value and MPMageFrostSaved[MPMageFrostConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPMageFrostSaved[MPMageFrostConfig].JewelMana_Value and MPMageFrostSaved[MPMageFrostConfig].JewelMana==1 then
			MPUseItemByName("法力红宝石")
			MPUseItemByName("法力黄水晶")
			MPUseItemByName("法力翡翠")
			MPUseItemByName("法力玛瑙")
		end

		-- 特定 种族天赋 --

		if MPMageFrostSaved[MPMageFrostConfig].RacialTraits==1 and GetMageArcaneMissiles()<=0 then
			if MPMageFrostSaved[MPMageFrostConfig].RacialTraitsBoss==0 or (MPMageFrostSaved[MPMageFrostConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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






	-- 魔甲术
	if MPMageFrostSaved[MPMageFrostConfig].MageArmor==1 and not MPBuff("魔甲术") and GetMageArcaneMissiles()<=0 then
		MageArmor()
		return
	end

	-- 寒冰护体
	if MPMageFrostSaved[MPMageFrostConfig].IceBarrier==1 and MPMageIceBarrier==1 and HBHT and not MPBuff("寒冰护体") and GetMageArcaneMissiles()<=0 then
		IceBarrier()
		return
	end

	-- 冰冷血脉
	if MPMageFrostSaved[MPMageFrostConfig].ColdBloodline==1 and MPMageIceBarrier==1 and HBHT and not MPBuff("冰冷血脉") and GetMageArcaneMissiles()<=0 then
		IceBarrier()
		return
	end

	-- 奥术涌动
	if MPMageFrostSaved[MPMageFrostConfig].ArcaneSurge==1 and MPGetMageArcaneSurge() and ASYD and GetMageArcaneMissiles()<=0 then
		ArcaneSurge()
		return
	end

	-- 保护 点燃
	if MPMageFrostSaved[MPMageFrostConfig].IgniteProtect==1 and GetNumRaidMembers()>5 then 
		if MPBuff("点燃", "target") or (GetTime()-MPInCombatTime)>12 then
			-- 火焰冲击
			if MageFrost_FireBlast() then
				return
			end
		end
	else
		-- 火焰冲击
		if MageFrost_FireBlast() then
			return
		end
	end

	if MPMageFrostSaved[MPMageFrostConfig].Frostbite==1 then

		-- 冰柱
		if MPMageFrostSaved[MPMageFrostConfig].Icicle==1 and MPMageIcicle==1 and BZ and GetMageArcaneMissiles()<=0 and MPBuff("冰霜速冻") then
			Icicle()
			return
		end

	else

		-- 冰柱
		if MPMageFrostSaved[MPMageFrostConfig].Icicle==1 and MPMageIcicle==1 and BZ and GetMageArcaneMissiles()<=0 then
			Icicle()
			return
		end

	end


	-- 冰锥术
	if MPMageFrostSaved[MPMageFrostConfig].ConeCold==1 and BZS and GetMageArcaneMissiles()<=0 then
		if MP_UnitXP and UnitExists("target") then
			local inMeleeRange = UnitXP("distanceBetween", "player", "target")
			if inMeleeRange and inMeleeRange<=MPMageConeColdDist then
				ConeCold()
				return
			end
		end
	end

	-- 冰霜新星
	if MPMageFrostSaved[MPMageFrostConfig].FrostNova==1 and BSXX and GetMageArcaneMissiles()<=0 then
		if MP_UnitXP and UnitExists("target") then
			local inMeleeRange = UnitXP("distanceBetween", "player", "target")
			if inMeleeRange and inMeleeRange<=MPMageConeColdDist then
				FrostNova()
				return
			end
		end
	end



	-- 寒冰箭 填充
	if GetMageArcaneMissiles()<=0 then
		Frostbolt()
	end

end

