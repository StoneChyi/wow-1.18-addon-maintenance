if MPPlayerClass ~= "SHAMAN" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 增强萨一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
--
-- 说明：
-- 
-- -------------------------------------

local AUTO_Shaman_Trinket_Delay = 3

-- 闪电之盾层数
MPShamanLightningShield = 3

-- 风暴打击
MPShamanStormStrike = 0

-- 闪电打击
MPShamanLightningStrike = 0

-- 6T3套装特效
MPShaman6T3 = 0

-- 默认配置
MPShamanEnhanceConfig = 1


local function EnhanceEarthTotemManager()

    -- 检测开关
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPEarthTotem() and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==0 then
    elseif MPEarthTotem() and MPEarthTotemName==MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthTotem_Value and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthTotem_Value)
        MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")
    end

end


local function EnhanceFireTotemManager()

    -- 检测开关
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].FireTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPFireTotem() and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==0 then
    elseif MPFireTotem() and MPFireTotemName==MPShamanEnhanceSaved[MPShamanEnhanceConfig].FireTotem_Value and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].FireTotem_Value)
        MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")
    end

end

local function EnhanceWaterTotemManager()

    -- 检测开关
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].WaterTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPWaterTotem() and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==0 then
    elseif MPWaterTotem() and MPWaterTotemName==MPShamanEnhanceSaved[MPShamanEnhanceConfig].WaterTotem_Value and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].WaterTotem_Value)
        MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")
    end

end


local function EnhanceAirTotemManager()

    -- 检测开关
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].AirTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPAirTotem() and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==0 then
    elseif MPAirTotem() and MPAirTotemName==MPShamanEnhanceSaved[MPShamanEnhanceConfig].AirTotem_Value and MPShamanEnhanceSaved[MPShamanEnhanceConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].AirTotem_Value)
        MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")
    end

end


local GCD,SS,LS,DDZJ,LYZJ,BSZJ,Mana,SD,DT,RY

local function CheckCD()
    if MPSpellReady("风暴打击",1.0) and MPSpellReady("闪电打击",1.0) and MPSpellReady("大地震击",1.0) then
        return true
    end

    return false
end

-- 切换图腾逻辑
local function MPSwitchTotemItem()

    local StormCD = MPGetSpellCooldown("风暴打击")
    local ShockCD = MPGetSpellCooldown("大地震击")
    local LightningCD = MPGetSpellCooldown("闪电打击")
    local Flame = MPBuff("烈焰震击", "target")

    -- 公CD的时候才进行切换
    if GCD<0.5 then 

        -- 大地震击
        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthShockTotem==1 then

            -- 震击CD最小，且已经有烈焰buff，这时候排除续杯火震的可能
            if LightningCD>ShockCD and StormCD>ShockCD and Flame then
                --MPEquipItemByName("风暴图腾", 9)
                MPEquipItemByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthShockTotem_Value, 9)
                return
            end

        end

        -- 震击类
        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].ShockTotem==1 then
            if LightningCD>ShockCD and StormCD>ShockCD then
                --MPEquipItemByName("时光洪流图腾", 9)
                MPEquipItemByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].ShockTotem_Value, 9)
                return
            end
        end

        -- 风暴打击
        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].StormstrikeTotem==1 then

            -- 风暴打击CD最小
            if StormCD<=ShockCD and StormCD<=LightningCD then
                --MPEquipItemByName("裂雷图腾", 9)
                MPEquipItemByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].StormstrikeTotem_Value, 9)
                return
            end
        end

        -- 闪电打击
        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].LightningStrikeTotem==1 then
            if LightningCD<=ShockCD and LightningCD<=StormCD then
                MPEquipItemByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].LightningStrikeTotem_Value, 9)
                return
            end
        end

    end

    -- 默认图腾
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].DefaultTotem==1 and not MPInCombat then
        MPEquipItemByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].DefaultTotem_Value, 9)
    end

end



function MPShamanAutoEnhance()

    if MPShamanStormStrike==1 then SS=MPSpellReady("风暴打击",1.5) else SS=false end
    if MPShamanLightningStrike==1 then LS=MPSpellReady("闪电打击",1.5) else LS=false end
    DDZJ = MPSpellReady("大地震击")
    LYZJ = MPSpellReady("烈焰震击")
    BSZJ = MPSpellReady("冰霜震击")
    Mana = UnitMana("player")
    GCD = MPGetGCD()

    if MPShaman6T3==1 then
        SD = MPBuff("霜冻")
        DT = MPBuff("冻土")
        RY = MPBuff("熔岩")
    else
        SD = false
        DT = false
        RY = false
    end


	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPShamanEnhanceSaved[MPShamanEnhanceConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPShamanEnhanceSaved[MPShamanEnhanceConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPShamanEnhanceSaved[MPShamanEnhanceConfig].Power==1 then
		MPCatPower()
	end



	if MPBuff("放逐术", "target") then
		return
	end


	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_Shaman_Trinket_Delay and MPGetTargetDistance() and MPShamanEnhanceSaved[MPShamanEnhanceConfig].Trinket_Upper==1 then
			if MPShamanEnhanceSaved[MPShamanEnhanceConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
				return
			elseif MPShamanEnhanceSaved[MPShamanEnhanceConfig].TUBoss==0 then
				UseInventoryItem(13)
				return
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_Shaman_Trinket_Delay and MPGetTargetDistance() and MPShamanEnhanceSaved[MPShamanEnhanceConfig].Trinket_Below==1 then
			if MPShamanEnhanceSaved[MPShamanEnhanceConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
				return
			elseif MPShamanEnhanceSaved[MPShamanEnhanceConfig].TBBoss==0 then
				UseInventoryItem(14)
				return
			end
		end

		if MPShamanEnhanceSaved[MPShamanEnhanceConfig].Soulspeed==1 and MPGetTargetDistance() then
			if MPShamanEnhanceSaved[MPShamanEnhanceConfig].SoulspeedBoss==0 or (MPShamanEnhanceSaved[MPShamanEnhanceConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

	    -- 血量危险时处理，潜行下不吃药
	    local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	    if percent<MPShamanEnhanceSaved[MPShamanEnhanceConfig].HealthStone_Value and MPShamanEnhanceSaved[MPShamanEnhanceConfig].HealthStone==1 then
		    MPUseItemByName("特效治疗石")
	    end
	    if percent<MPShamanEnhanceSaved[MPShamanEnhanceConfig].HerbalTea_Value and MPShamanEnhanceSaved[MPShamanEnhanceConfig].HerbalTea==1 then
		    MPUseItemByName("糖水茶")
		    MPUseItemByName("诺达纳尔草药茶")
	    end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPShamanEnhanceSaved[MPShamanEnhanceConfig].HerbalTeaMana_Value and MPShamanEnhanceSaved[MPShamanEnhanceConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

	    -- 特定 种族天赋 --

	    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].RacialTraits==1 and MPGetTargetDistance() then
			if MPShamanEnhanceSaved[MPShamanEnhanceConfig].RacialTraitsBoss==0 or (MPShamanEnhanceSaved[MPShamanEnhanceConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

    -- 图腾召回
    --[[
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].RecallTotems==1 then
        local recall = 0
        local x, y = GetPlayerMapPosition("player")
        if MPEarthTotem() and MPCalculateTotemDistance(x,y, MPEarthTotemX, MPEarthTotemY)>MPShamanEnhanceSaved[MPShamanEnhanceConfig].RecallTotems_Value then recall = recall+1 end
        if MPFireTotem() and MPCalculateTotemDistance(x,y, MPFireTotemX, MPFireTotemY)>MPShamanEnhanceSaved[MPShamanEnhanceConfig].RecallTotems_Value  then recall = recall+1 end
        if MPWaterTotem() and MPCalculateTotemDistance(x,y, MPWaterTotemX, MPWaterTotemY)>MPShamanEnhanceSaved[MPShamanEnhanceConfig].RecallTotems_Value  then recall = recall+1 end
        if MPAirTotem() and MPCalculateTotemDistance(x,y, MPAirTotemX, MPAirTotemY)>MPShamanEnhanceSaved[MPShamanEnhanceConfig].RecallTotems_Value  then recall = recall+1 end
        if recall > 0 then
            CastSpellByName("图腾召回")
            return
        end
    end
    ]]

    -- 图腾
    EnhanceEarthTotemManager()
    EnhanceFireTotemManager()
    EnhanceWaterTotemManager()
    EnhanceAirTotemManager()

    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].AutoWaterShield==1 then

        if Mana < MPShamanEnhanceSaved[MPShamanEnhanceConfig].AutoWaterShield_Value then
            if not MPBuff("水之护盾") then
                CastSpellByName("水之护盾")
            end
        elseif Mana > (MPShamanEnhanceSaved[MPShamanEnhanceConfig].AutoWaterShield_Value+1000) then

            -- 闪电之盾
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].LightningShield==1 then
                MPCancelBuffByName("水之护盾", "player")
                if not MPBuff("闪电之盾") then
                    CastSpellByName("闪电之盾")
                    return
                end
            end

            -- 大地之盾
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthShield==1 then
                MPCancelBuffByName("水之护盾", "player")
                if not MPBuff("大地之盾") then
                    CastSpellByName("大地之盾")
                    return
                end
            end

            -- 水之护盾
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].WaterShield==1 then
                if not MPBuff("水之护盾") then
                    CastSpellByName("水之护盾")
                end
            end

        else

            -- 闪电之盾
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].LightningShield==1 and not MPBuff("闪电之盾") and not MPBuff("水之护盾") then
                CastSpellByName("闪电之盾")
                return
            end

            -- 大地之盾
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthShield==1 and not MPBuff("大地之盾") and not MPBuff("水之护盾") then
                CastSpellByName("大地之盾")
                return
            end

            -- 水之护盾
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].WaterShield==1 and not MPBuff("水之护盾") then
                CastSpellByName("水之护盾")
            end

        end
    else
        -- 闪电之盾
        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].LightningShield==1 then
            MPCancelBuffByName("水之护盾", "player")
            if not MPBuff("闪电之盾") then
                CastSpellByName("闪电之盾")
                return
            end
        end

        -- 大地之盾
        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthShield==1 then
            MPCancelBuffByName("水之护盾", "player")
            if not MPBuff("大地之盾") then
                CastSpellByName("大地之盾")
                return
            end
        end

        -- 水之护盾
        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].WaterShield==1 then
            if not MPBuff("水之护盾") then
                CastSpellByName("水之护盾")
            end
        end
    end


    -- 武器附魔
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].WEnhance==1 then
        if not string.find(MPGetShamanEnchantName(),MPShamanEnhanceSaved[MPShamanEnhanceConfig].WEnhance_Value) then
            CastSpellByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].WEnhance_Value)
            return
        end
    end

    -- 尝试切换图腾装备
    MPSwitchTotemItem()

    --[[
    local timeleft = UnitAttackSpeed("player")
    timeleft = timeleft / 4
    ]]
    local timeleft = 0.5
    --print(timeleft)

    if MPShaman6T3==1 and MPShamanEnhanceSaved[MPShamanEnhanceConfig].SixT3==1 then

        -- 6T3 Buff 烈焰震击->霜冻->冰霜震击
        -- 6T3 Buff 冰霜震击->冻土->大地震击
        -- 6T3 Buff 大地震击->熔岩->烈焰震击

        if MPShamanEnhanceSaved[MPShamanEnhanceConfig].FlameShock==1 and LYZJ and not MPBuff("烈焰震击", "target") and not RY and not DT and not SD then
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].ShockTotem==1 and GCD<0.5 then
                MPEquipItemByName("裂石图腾", 9)
            end
            CastSpellByName("烈焰震击")
            return
        elseif MPShamanEnhanceSaved[MPShamanEnhanceConfig].FlameShock==1 and LYZJ and RY then
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].ShockTotem==1 and GCD<0.5 then
                MPEquipItemByName("裂石图腾", 9)
            end
            CastSpellByName("烈焰震击")
            return
        end

        if SS and MPGetMainHandLeft()>timeleft then
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].StormstrikeTotem==1 and GCD<0.5 then
                MPEquipItemByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].StormstrikeTotem_Value, 9)
            end
            CastSpellByName("风暴打击")
        end

        if LS and MPGetMainHandLeft()>timeleft then
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].LightningStrikeTotem==1 and GCD<0.5 then
                MPEquipItemByName(MPShamanEnhanceSaved[MPShamanEnhanceConfig].LightningStrikeTotem_Value, 9)
            end
            CastSpellByName("闪电打击")
        end

        -- 6T3的特效
        if DDZJ and DT then
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthShockTotem==1 and GCD<0.5 then
                MPEquipItemByName("破碎大地图腾", 9)
            end
            CastSpellByName("大地震击")
            return
        end

        if BSZJ and SD then
            if MPShamanEnhanceSaved[MPShamanEnhanceConfig].ShockTotem==1 and GCD<0.5 then
                MPEquipItemByName("裂石图腾", 9)
            end
            CastSpellByName("冰霜震击")
            return
        end

        return
    end

    -- 补烈焰震击
    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].FlameShock==1 and LYZJ and not MPBuff("烈焰震击", "target") then

        CastSpellByName("烈焰震击")
        return
    end


    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].EarthShock==1 and DDZJ then
        CastSpellByName("大地震击")
        return
    end

    if MPShamanEnhanceSaved[MPShamanEnhanceConfig].FrostShock==1 and DDZJ then
        CastSpellByName("冰霜震击")
        return
    end


    if SS then

        -- 等平A
        if MPGetMainHandLeft()>timeleft then
            CastSpellByName("风暴打击")
        end

        return
    end

    if not SS and LS then

        -- 等平A
        if MPGetMainHandLeft()>timeleft then
            CastSpellByName("闪电打击")
        end

        return
    end





end

