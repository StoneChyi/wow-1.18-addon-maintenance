if MPPlayerClass ~= "SHAMAN" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 元素萨一键宏
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


-- 地震术
MPShamanEarthSpell = 0

-- 熔岩爆裂 读条
MPBeginLavaBurstCastTimer = 0

-- 闪电箭 计数
MPLightningBoltCount = 0

-- 火震 持续时间
MPShamanFlameShockDuration = 15

-- 默认配置
MPShamanElementalConfig = 1


local function ElementalEarthTotemManager()

    -- 检测开关
    if MPShamanElementalSaved[MPShamanElementalConfig].EarthTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPEarthTotem() and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==0 then
    elseif MPEarthTotem() and MPEarthTotemName==MPShamanElementalSaved[MPShamanElementalConfig].EarthTotem_Value and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanElementalSaved[MPShamanElementalConfig].EarthTotem_Value)
        MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")
    end

end


local function ElementalFireTotemManager()

    -- 检测开关
    if MPShamanElementalSaved[MPShamanElementalConfig].FireTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPFireTotem() and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==0 then
    elseif MPFireTotem() and MPFireTotemName==MPShamanElementalSaved[MPShamanElementalConfig].FireTotem_Value and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanElementalSaved[MPShamanElementalConfig].FireTotem_Value)
        MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")
    end

end

local function ElementalWaterTotemManager()

    -- 检测开关
    if MPShamanElementalSaved[MPShamanElementalConfig].WaterTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPWaterTotem() and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==0 then
    elseif MPWaterTotem() and MPWaterTotemName==MPShamanElementalSaved[MPShamanElementalConfig].WaterTotem_Value and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanElementalSaved[MPShamanElementalConfig].WaterTotem_Value)
        MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")
    end

end


local function ElementalAirTotemManager()

    -- 检测开关
    if MPShamanElementalSaved[MPShamanElementalConfig].AirTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPAirTotem() and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==0 then
    elseif MPAirTotem() and MPAirTotemName==MPShamanElementalSaved[MPShamanElementalConfig].AirTotem_Value and MPShamanElementalSaved[MPShamanElementalConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanElementalSaved[MPShamanElementalConfig].AirTotem_Value)
        MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")
    end

end


local DDZJ,LYZJ,BSZJ,Mana,SDL,DZS

function MPShamanAutoElemental()

    if MPShamanElementalSaved[MPShamanElementalConfig].LavaBurst==1 then
        MPShamanAutoFireSM()
        return
    end

    SDL = MPSpellReady("闪电链")
    DZS = MPSpellReady("地震术")
    DDZJ = MPSpellReady("大地震击")
    LYZJ = MPSpellReady("烈焰震击")
    BSZJ = MPSpellReady("冰霜震击")
    Mana = UnitMana("player")


	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPShamanElementalSaved[MPShamanElementalConfig].Target, 0)

	-- 目标确认
	if not UnitExists("target") then return end

	-- 开启自动攻击
    if MPShamanElementalSaved[MPShamanElementalConfig].Target==1 then
	    MPStartAttack()
    end

	-- 自动拾取
	if MPShamanElementalSaved[MPShamanElementalConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPShamanElementalSaved[MPShamanElementalConfig].Power==1 then
		MPCatPower()
	end



	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_Shaman_Trinket_Delay and MPGetTargetDistance() and MPShamanElementalSaved[MPShamanElementalConfig].Trinket_Upper==1 then
			if MPShamanElementalSaved[MPShamanElementalConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPShamanElementalSaved[MPShamanElementalConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_Shaman_Trinket_Delay and MPGetTargetDistance() and MPShamanElementalSaved[MPShamanElementalConfig].Trinket_Below==1 then
			if MPShamanElementalSaved[MPShamanElementalConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPShamanElementalSaved[MPShamanElementalConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPShamanElementalSaved[MPShamanElementalConfig].Soulspeed==1  then
			if MPShamanElementalSaved[MPShamanElementalConfig].SoulspeedBoss==0 or (MPShamanElementalSaved[MPShamanElementalConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

	    -- 血量危险时处理，潜行下不吃药
	    local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	    if percent<MPShamanElementalSaved[MPShamanElementalConfig].HealthStone_Value and MPShamanElementalSaved[MPShamanElementalConfig].HealthStone==1 then
		    MPUseItemByName("特效治疗石")
	    end
	    if percent<MPShamanElementalSaved[MPShamanElementalConfig].HerbalTea_Value and MPShamanElementalSaved[MPShamanElementalConfig].HerbalTea==1 then
		    MPUseItemByName("糖水茶")
		    MPUseItemByName("诺达纳尔草药茶")
	    end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPShamanElementalSaved[MPShamanElementalConfig].HerbalTeaMana_Value and MPShamanElementalSaved[MPShamanElementalConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

	    -- 特定 种族天赋 --

	    if MPShamanElementalSaved[MPShamanElementalConfig].RacialTraits==1 then
			if MPShamanElementalSaved[MPShamanElementalConfig].RacialTraitsBoss==0 or (MPShamanElementalSaved[MPShamanElementalConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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
    if MPShamanElementalSaved[MPShamanElementalConfig].RecallTotems==1 then
        local recall = 0
        local x, y = GetPlayerMapPosition("player")
        if MPEarthTotem() and MPCalculateDistance(x,y, MPEarthTotemX, MPEarthTotemY)>MPShamanElementalSaved[MPShamanElementalConfig].RecallTotems_Value then recall = recall+1 end
        if MPFireTotem() and MPCalculateDistance(x,y, MPFireTotemX, MPFireTotemY)>MPShamanElementalSaved[MPShamanElementalConfig].RecallTotems_Value  then recall = recall+1 end
        if MPWaterTotem() and MPCalculateDistance(x,y, MPWaterTotemX, MPWaterTotemY)>MPShamanElementalSaved[MPShamanElementalConfig].RecallTotems_Value  then recall = recall+1 end
        if MPAirTotem() and MPCalculateDistance(x,y, MPAirTotemX, MPAirTotemY)>MPShamanElementalSaved[MPShamanElementalConfig].RecallTotems_Value  then recall = recall+1 end
        if recall > 0 then
            CastSpellByName("图腾召回")
            return
        end
    end
    ]]

    -- 图腾
    ElementalEarthTotemManager()
    ElementalFireTotemManager()
    ElementalWaterTotemManager()
    ElementalAirTotemManager()

    -- 闪电之盾
    if MPShamanElementalSaved[MPShamanElementalConfig].LightningShield==1 then
        MPCancelBuffByName("水之护盾", "player")
        if not MPBuff("闪电之盾") then
            CastSpellByName("闪电之盾")
            return
        end
    end

    -- 大地之盾
    if MPShamanElementalSaved[MPShamanElementalConfig].EarthShield==1 then
        MPCancelBuffByName("水之护盾", "player")
        if not MPBuff("大地之盾") then
            CastSpellByName("大地之盾")
            return
        end
    end

    -- 水之护盾
    if MPShamanElementalSaved[MPShamanElementalConfig].WaterShield==1 then
        if not MPBuff("水之护盾") then
            CastSpellByName("水之护盾")
            return
        end
    end

    -- 武器附魔
    if MPShamanElementalSaved[MPShamanElementalConfig].WEnhance==1 then
        if not string.find(MPGetShamanEnchantName(),MPShamanElementalSaved[MPShamanElementalConfig].WEnhance_Value) then
            CastSpellByName(MPShamanElementalSaved[MPShamanElementalConfig].WEnhance_Value)
            return
        end
    end


    if MP_SuperWoW then
        -- 要考虑弹道时间
        if GetTime()-MPBeginLavaBurstCastTimer > 2.5 then

            local check = MPGetFlameShockCheck()
            local a,guid=UnitExists("target")
            if check[guid] then
                local timer = 15-(GetTime()-check[guid])
                if MPShamanElementalSaved[MPShamanElementalConfig].FlameShockFromLavaBurst==1 and timer>0 and timer<7 then
                    CastSpellByName("熔岩爆裂")
                    return
                end
            end

        end
    else
        if MPLightningBoltCount>2 then
            -- 要考虑弹道时间
            if GetTime()-MPBeginLavaBurstCastTimer > 2.5 then

                if MPShamanElementalSaved[MPShamanElementalConfig].FlameShockFromLavaBurst==1 then
                    CastSpellByName("熔岩爆裂")
                    return
                end

            end
        end

    end


    local rang = -1
    local t = UnitExists("target")
    if t and MP_UnitXP then
        rang = UnitXP("distanceBetween", "player", "target")
    end


    if rang>=0 then

        if MPShamanElementalSaved[MPShamanElementalConfig].FlameShock==1 and LYZJ and not MPGetFlameShockDot() and rang<=30 then
            CastSpellByName("烈焰震击")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].EarthSpell==1 and MPShamanEarthSpell==1 and DZS then
            CastSpellByName("地震术")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].ChainLightning==1 and SDL then
            CastSpellByName("闪电链")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].EarthShock==1 and DDZJ and rang<=20 then
            CastSpellByName("大地震击")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].FrostShock==1 and BSZJ and rang<=20 then
            CastSpellByName("冰霜震击")
            return
        end

    else

        if MPShamanElementalSaved[MPShamanElementalConfig].FlameShock==1 and LYZJ and not MPGetFlameShockDot() then
            CastSpellByName("烈焰震击")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].EarthSpell==1 and MPShamanEarthSpell==1 and DZS then
            CastSpellByName("地震术")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].ChainLightning==1 and SDL then
            CastSpellByName("闪电链")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].EarthShock==1 and DDZJ then
            CastSpellByName("大地震击")
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].FrostShock==1 and BSZJ then
            CastSpellByName("冰霜震击")
        end

    end


    if MPShamanElementalSaved[MPShamanElementalConfig].LightningBolt==1 then
        CastSpellByName("闪电箭")
    end


end





function MPShamanAutoFireSM()
    SDL = MPSpellReady("闪电链")
    DZS = MPSpellReady("地震术")
    DDZJ = MPSpellReady("大地震击")
    LYZJ = MPSpellReady("烈焰震击")
    BSZJ = MPSpellReady("冰霜震击")
    Mana = UnitMana("player")


	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPShamanElementalSaved[MPShamanElementalConfig].Target, 0)

	-- 开启自动攻击
	MPStartAttack()

	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_Shaman_Trinket_Delay and MPGetTargetDistance() and MPShamanElementalSaved[MPShamanElementalConfig].Trinket_Upper==1 then
			UseInventoryItem(13)
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_Shaman_Trinket_Delay and MPGetTargetDistance() and MPShamanElementalSaved[MPShamanElementalConfig].Trinket_Below==1 then
			UseInventoryItem(14)
		end

	    -- 血量危险时处理，潜行下不吃药
	    local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	    if percent<MPShamanElementalSaved[MPShamanElementalConfig].HealthStone_Value and MPShamanElementalSaved[MPShamanElementalConfig].HealthStone==1 then
		    MPUseItemByName("特效治疗石")
	    end
	    if percent<MPShamanElementalSaved[MPShamanElementalConfig].HerbalTea_Value and MPShamanElementalSaved[MPShamanElementalConfig].HerbalTea==1 then
		    MPUseItemByName("糖水茶")
		    MPUseItemByName("诺达纳尔草药茶")
	    end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPShamanElementalSaved[MPShamanElementalConfig].HerbalTeaMana_Value and MPShamanElementalSaved[MPShamanElementalConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

	    -- 特定 种族天赋 --

	    if MPShamanElementalSaved[MPShamanElementalConfig].RacialTraits==1 and MPInCombat then

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


    -- 图腾
    ElementalEarthTotemManager()
    ElementalFireTotemManager()
    ElementalWaterTotemManager()
    ElementalAirTotemManager()

    -- 闪电之盾
    if MPShamanElementalSaved[MPShamanElementalConfig].LightningShield==1 then
        MPCancelBuffByName("水之护盾", "player")
        if not MPBuff("闪电之盾") then
            CastSpellByName("闪电之盾")
            return
        end
    end

    -- 大地之盾
    if MPShamanElementalSaved[MPShamanElementalConfig].EarthShield==1 then
        MPCancelBuffByName("水之护盾", "player")
        if not MPBuff("大地之盾") then
            CastSpellByName("大地之盾")
            return
        end
    end

    -- 水之护盾
    if MPShamanElementalSaved[MPShamanElementalConfig].WaterShield==1 then
        if not MPBuff("水之护盾") then
            CastSpellByName("水之护盾")
            return
        end
    end

    -- 武器附魔
    if MPShamanElementalSaved[MPShamanElementalConfig].WEnhance==1 then
        if not string.find(MPGetShamanEnchantName(),MPShamanElementalSaved[MPShamanElementalConfig].WEnhance_Value) then
            CastSpellByName(MPShamanElementalSaved[MPShamanElementalConfig].WEnhance_Value)
            return
        end
    end


    local t = UnitExists("target")
    local rang = 0
    if t and MP_UnitXP then
        local rang = UnitXP("distanceBetween", "player", "target")
        if MPShamanElementalSaved[MPShamanElementalConfig].LavaBurst==1 and LYZJ and not MPGetFlameShockDot() and rang<=30 then
            CastSpellByName("烈焰震击")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].ChainLightning==1 and SDL then
            CastSpellByName("闪电链")
            return
        end

    else

        if MPShamanElementalSaved[MPShamanElementalConfig].LavaBurst==1 and LYZJ and not MPGetFlameShockDot() then
            CastSpellByName("烈焰震击")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].EarthSpell==1 and MPShamanEarthSpell==1 and DZS then
            CastSpellByName("地震术")
            return
        end

        if MPShamanElementalSaved[MPShamanElementalConfig].ChainLightning==1 and SDL then
            CastSpellByName("闪电链")
            return
        end

    end

    CastSpellByName("熔岩爆裂")

end
