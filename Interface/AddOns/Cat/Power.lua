-- -------------------------------------
-- 乌龟服 - 功能药水一键宏
-- 发布日期：2026-01-01 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 必要条件：SuperWoW
--
-- 打断宏，必须开启SuperWoW
--
-- -------------------------------------
--
-- 功能配置：

-- 以下功能开关：1开启 0关闭

-- -------------------------------------

-- 献祭之油时间
MPSacrificialTimer = 0

function MPCatPower()

	-- 总开关
	if MPPowerSaved.Use==0 then
		return
	end

	-- 进战斗开关
	if MPPowerSaved.Combat==1 and not MPInCombat then
		return
	end


	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = 100

    if MPPlayerClass == "WARRIOR" then
    elseif MPPlayerClass == "ROGUE" then
    elseif MPPlayerClass == "MAGE" then
		local M = UnitMana("player")
		local Mmax = UnitManaMax("player")
		if M and Mmax then
			percentMana = M / Mmax * 100
		end
    elseif MPPlayerClass == "HUNTER" then
		local M = UnitMana("player")
		local Mmax = UnitManaMax("player")
		if M and Mmax then
			percentMana = M / Mmax * 100
		end
    elseif MPPlayerClass == "PRIEST" then
		local M = UnitMana("player")
		local Mmax = UnitManaMax("player")
		if M and Mmax then
			percentMana = M / Mmax * 100
		end
    elseif MPPlayerClass == "WARLOCK" then
		local M = UnitMana("player")
		local Mmax = UnitManaMax("player")
		if M and Mmax then
			percentMana = M / Mmax * 100
		end
    elseif MPPlayerClass == "DRUID" then
		local _,M = UnitMana("player")
		local _,Mmax = UnitManaMax("player")
		if M and Mmax then
			percentMana = M / Mmax * 100
		end
    elseif MPPlayerClass == "PALADIN" then
		local M = UnitMana("player")
		local Mmax = UnitManaMax("player")
		if M and Mmax then
			percentMana = M / Mmax * 100
		end
    elseif MPPlayerClass == "SHAMAN" then
		local M = UnitMana("player")
		local Mmax = UnitManaMax("player")
		if M and Mmax then
			percentMana = M / Mmax * 100
		end
    else
        return
    end
	



	-- 草药茶 HP
	if MPPowerSaved.HerbalTea==1 and percent<MPPowerSaved.HerbalTea_Value then
		MPUseItemByName("糖水茶")
		MPUseItemByName("诺达纳尔草药茶")
	end
	-- 草药茶 MP
	if MPPowerSaved.HerbalTeaMana==1 and percentMana<MPPowerSaved.HerbalTeaMana_Value then
		MPUseItemByName("糖水茶")
		MPUseItemByName("诺达纳尔草药茶")
	end

	-- 特效活力药水 HP
	if MPPowerSaved.Rejuven==1 and percent<MPPowerSaved.Rejuven_Value then
		MPUseItemByName("特效活力药水")
	end
	-- 特效活力药水 MP
	if MPPowerSaved.RejuvenMana==1 and percentMana<MPPowerSaved.RejuvenMana_Value then
		MPUseItemByName("特效活力药水")
	end

	-- 特效治疗药水 HP
	if MPPowerSaved.Healing==1 and percent<MPPowerSaved.Healing_Value then
		MPUseItemByName("特效治疗药水")
	end
	-- 特效法力药水 MP
	if MPPowerSaved.Mana==1 and percentMana<MPPowerSaved.Mana_Value then
		MPUseItemByName("特效法力药水")
	end

	-- 治疗石 HP
	if MPPowerSaved.HealthStone==1 and percent<MPPowerSaved.HealthStone_Value then
		MPUseItemByName("特效治疗石")
	end
	-- 鞭根块茎 HP
	if MPPowerSaved.Carrot==1 and percent<MPPowerSaved.Carrot_Value then
		MPUseItemByName("鞭根块茎")
	end

	-- 爆发饰品 上
	if MPPowerSaved.Trinket_Upper==1 and GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 then
		if MPPowerSaved.TUBoss==1 and MPIsBossTarget() then
			UseInventoryItem(13)
		elseif MPPowerSaved.TUBoss==0 then
			UseInventoryItem(13)
		end
	end
	-- 爆发饰品 下
	if MPPowerSaved.Trinket_Below==1 and GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 then
		if MPPowerSaved.TBBoss==1 and MPIsBossTarget() then
			UseInventoryItem(14)
		elseif MPPowerSaved.TBBoss==0 then
			UseInventoryItem(14)
		end
	end

	-- 强效怒气药水
	if MPPowerSaved.Powerful==1 then
		if MPPowerSaved.PowerfulBoss==1 and MPIsBossTarget() then
			MPUseItemByName("强效怒气药水")
		elseif MPPowerSaved.PowerfulBoss==0 then
			MPUseItemByName("强效怒气药水")
		end
	end

	-- 加速药水
	if MPPowerSaved.Swiftness==1 then
		if MPPowerSaved.SwiftnessBoss==1 and MPIsBossTarget() then
			MPUseItemByName("加速药水")
		elseif MPPowerSaved.SwiftnessBoss==0 then
			MPUseItemByName("加速药水")
		end
	end

	-- 魂能之速
	if MPPowerSaved.Soulspeed==1 then
		if MPPowerSaved.SoulspeedBoss==1 and MPIsBossTarget() then
			MPUseItemByName("魂能之速")
		elseif MPPowerSaved.SoulspeedBoss==0 then
			MPUseItemByName("魂能之速")
		end
	end

	-- 献祭之油
	if MPPowerSaved.Sacrificial==1 and MPScanNearbyEnemiesCount(8)>3 and GetTime()-MPSacrificialTimer>0 then
		MPUseItemByName("献祭之油")
	end

	-- 屠魔药剂
	if MPPowerSaved.Demon==1 and UnitExists("target") and not MPBuff("屠魔药剂") then
		local creature = UnitCreatureType("target") or "其它"
		local position = string.find("恶魔", creature)
		-- 目标是恶魔
		if position then
			if MPPowerSaved.DemonBoss==1 and MPIsBossTarget() then
				MPUseItemByName("屠魔药剂")
			elseif MPPowerSaved.DemonBoss==0 then
				MPUseItemByName("屠魔药剂")
			end
		end
	end

	-- 无敌
	if MPPowerSaved.Invincible==1 and UnitExists("target") then
		local _,TargetGuid = UnitExists("targettarget")
		local _,Guid = UnitExists("player")
		if TargetGuid then
			if TargetGuid == Guid then
				if MPPowerSaved.InvincibleBoss==1 and MPIsBossTarget() then
					MPUseItemByName("有限无敌药水")
				elseif MPPowerSaved.InvincibleBoss==0 then
					MPUseItemByName("有限无敌药水")
				end
			end
		end
	end

	-- 解毒
	if MPPowerSaved.Detoxify==1 then
		if MPIsDebuffType("Poison") then
			MPUseItemByName("解毒药水")
			MPUseItemByName("极效抗毒药剂")
		end
	end

end
