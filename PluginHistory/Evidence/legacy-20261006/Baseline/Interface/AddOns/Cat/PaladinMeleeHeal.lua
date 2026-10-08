if MPPlayerClass ~= "PALADIN" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 近战奶骑一键宏
-- 更新日期：2026-04-11 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
--
-- 说明：
-- 
-- -------------------------------------

local MPHealTargetDelay = {}
local MPHealthUnit = nil


local HasTarget,SP,SZJ

-- 用于防止连续圣光术的buff消失时间延迟
MPCastHolyLightDelay = 0


local Mana

-- 默认配置
MPPaladinMeleeHealConfig = 1


-- 正义圣印
local function SealJustice()
	if Mana<170 then
		CastSpellByName("正义圣印(等级 1)")
	else
		CastSpellByName("正义圣印")
	end
end

-- 命令圣印
local function SealCommand()
	if Mana<178 then
		CastSpellByName("命令圣印(等级 1)")
	else
		CastSpellByName("命令圣印")
	end
end

-- 智慧圣印
local function SealWisdom()
	if Mana<170 then
		CastSpellByName("智慧圣印(等级 1)")
	else
		CastSpellByName("智慧圣印")
	end
end

-- 光明圣印
local function SealRight()
	if Mana<178 then
		CastSpellByName("光明圣印(等级 1)")
	else
		CastSpellByName("光明圣印")
	end
end

-- 十字军圣印
local function SealCrusader()
	if Mana<136 then
		CastSpellByName("十字军圣印(等级 1)")
	else
		CastSpellByName("十字军圣印")
	end
end


function MPPaladinAutoMeleeHealth()

    if UnitExists("target") and UnitCanAttack("player", "target") then
        HasTarget = true
    else
        HasTarget = false
    end

	Mana = UnitMana("player")
    SP=MPSpellReady("审判")
    SZJ=MPSpellReadyOffset("十字军打击", 1.0)
    SSZZ=MPSpellReady("神圣震击")

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Power==1 then
		MPCatPower()
	end



	-- 在战斗中
	if MPInCombat then
	    -- 血量危险时处理，潜行下不吃药
	    local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	    if percent<MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HealthStone_Value and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HealthStone==1 then
		    MPUseItemByName("特效治疗石")
	    end
	    if percent<MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HerbalTea_Value and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HerbalTea==1 then
		    MPUseItemByName("糖水茶")
		    MPUseItemByName("诺达纳尔草药茶")
	    end

		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HerbalTeaMana_Value and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percent<MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Protection_Value and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Protection==1 then
			MPCastSpellWithoutTarget("保护之手","player")
		end
		if percent<MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].DivineShield_Value and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].DivineShield==1 then
			CastSpellByName("圣盾术")
		end

    end

	local GCD = MPGetGCD()

    if GCD<1.3 then
        return
    end

    --[[
    if MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Justice==1 then

        -- 上智慧审判
        if not MPBuff("智慧审判", "target") and not MPBuff("智慧圣印") then
            CastSpellByName("智慧圣印")
            return
        end

        if not MPBuff("智慧审判", "target") and MPBuff("智慧圣印") and SP then
            CastSpellByName("审判")
            return
        end

    end

    if not MPBuff("正义圣印") then
        CastSpellByName("正义圣印(等级 1)")
        return
    end
    ]]



	-- 通过小窗参数 - 审判

	if MPPaladinSealSaved.Justice==1 and not MPBuff("智慧审判", "target") then

		-- 打智慧圣印
		if not MPSeal("智慧圣印") then SealWisdom() return end
		if MPSeal("智慧圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end

		return

	elseif MPPaladinSealSaved.Justice==2 and not MPBuff("光明审判", "target") then

		-- 打光明圣印
		if not MPSeal("光明圣印") then SealRight() return end
		if MPSeal("光明圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end

		return

	elseif MPPaladinSealSaved.Justice==3 and not MPBuff("十字军审判", "target") then

		-- 打十字军圣印
		if not MPSeal("十字军圣印") then SealCrusader() return end
		if MPSeal("十字军圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end

		return

	end

	-- 通过小窗参数 - 圣印

	if MPPaladinSealSaved.Seal==1 then

		-- 保持智慧圣印
		if not MPSeal("智慧圣印") then SealWisdom() return end

	elseif MPPaladinSealSaved.Seal==2 then

		-- 保持光明圣印
		if not MPSeal("光明圣印") then SealRight() return end

	elseif MPPaladinSealSaved.Seal==3 then

		-- 保持十字军圣印
		if not MPSeal("十字军圣印") then SealCrusader() return end

	elseif MPPaladinSealSaved.Seal==0 then

		-- 输出

		if MPPaladinSealSaved.Seal==0 then

			if not MPSeal("正义圣印") then
				SealJustice()
			end

		end

	end


    if SP and MPBuff("正义圣印") and not MPBuff("神圣制裁") then
        CastSpellByName("审判")
        return
    end

    if MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].CrusaderStrike==1 and not SSZZ and SZJ then
        CastSpellByName("十字军打击")
        return
    end

    if MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HolyStrike==1 and SZJ then
        CastSpellByName("神圣打击")
        return
    end


    -- 目标
    if UnitExists("target") and MPPaladinHealSaved.TargetFirst==1 then
        if MPPaladinMeleeHealth("target") then
            return
        end
    end

    -- 目标
    if UnitExists("target") and UnitExists("targettarget") and MPPaladinHealSaved.TargetTarget==1 then
        if MPPaladinMeleeHealth("targettarget") then
            return
        end
    end

    -- 自己
    if MPPaladinHealSaved.SelfFirst==1 then
        if MPPaladinMeleeHealth("player") then
            return
        end
    end

    -- 队伍里的其他人
    if MPPaladinHealSaved.ScanTeam==1 then

        local sortedMembers = MPGetSortedGroupByHealth()
        for i, member in ipairs(sortedMembers) do
            if MPPaladinMeleeHealth(member.unit) then
                return
            end
        end

    end





end


function MPPaladinMeleeHealth(unit)

    if not unit then
        return false
    end


	local DM = UnitMana("player")
    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local percentHealth = 0
    local HealthDec = 0
    SLS = MPSpellReady("圣疗术")
    SSZJ = MPSpellReady("神圣震击")

    if UnitIsDeadOrGhost(unit) then
        return false
    end

    if health==0 or maxHealth == 0 then
        -- 离线忽略 死亡忽略
        return false
    end

       -- 敌人
    if UnitCanAttack("player", unit) then
        return false
    end

    -- 计算目标生命值比例
    percentHealth = health/maxHealth*100
    HealthDec = maxHealth - health

    if MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Begin_Value <= percentHealth then
        return false
    end

    -- 视野
    if MP_UnitXP then
        if unit ~= "player" then
            local inRange = UnitXP("distanceBetween", "player", unit)
            if inRange and inRange>40 then
                MPMsg("|cFFee1111["..UnitName(unit).."] 不在有效距离|r")
                return false
            else
                local inS = UnitXP("inSight", "player", unit)
                if not inS then
                    MPMsg("|cFFee1111["..UnitName(unit).."] 不在视野中|r")
                    return false
                end
            end
        end
    end

    -- 用于防止同一目标多次治疗
    --if MPDruidCastHealTarget == unit then
        local targetName = UnitName(unit)
        MPPaladinCastHealTarget = nil
    --end

    if MPHealTargetDelay[targetName] and GetTime()-MPHealTargetDelay[targetName] < 1.2 then
        --print("return "..targetName)
        return false
    else
        --print(targetName)
        --MPHealTargetDelay[targetName] = GetTime()
    end


    --MPPaladinCastHealTarget = unit


    -- 治疗 --

    if percentHealth < MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].LayHands_Value and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].LayHands==1 and SLS then
        MPHealTargetDelay[targetName] = GetTime()
        return MPCastSpellWithoutTarget("圣疗术", unit, 1)
    end


    if percentHealth < MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HolyShock_Value and SSZZ and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HolyShock==1 then
        --print(unit)
        if MP_UnitXP then
            if UnitXP("distanceBetween", "player", unit)<=20 then
                MPHealTargetDelay[targetName] = GetTime()
                if MPCastSpellWithoutTarget("神圣震击", unit, 1) then
                    return
                end
            end
        else
            MPHealTargetDelay[targetName] = GetTime()
            if MPCastSpellWithoutTarget("神圣震击", unit, 1) then
                return
            end
        end
    end


    MPHealthUnit = unit

    if percentHealth < MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HolyLight_Value and MPBuff("神圣制裁") and MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].HolyLight==1 and GetTime()-MPCastHolyLightDelay>0 then

        MPHealTargetDelay[targetName] = GetTime()

        if MPPaladinHolyLightEffect[9]<HealthDec or MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Force==1 then

            if DM >= MPPaladinHolyLight[9] then
                return MPCastSpellWithoutTarget("圣光术(等级 9)", unit, 1)
            elseif DM >= MPPaladinHolyLight[6] then
                return MPCastSpellWithoutTarget("圣光术(等级 6)", unit, 1)
            elseif DM >= MPPaladinHolyLight[3] then
                return MPCastSpellWithoutTarget("圣光术(等级 3)", unit, 1)
            else
                return MPCastSpellWithoutTarget("圣光术(等级 1)", unit, 1)
            end

        end

        for i = 9, 2, -1 do
            if MPPaladinHolyLightEffect[i] < HealthDec then

                if DM >= MPPaladinHolyLight[i] then
                    return MPCastSpellWithoutTarget("圣光术(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("圣光术(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("圣光术(等级 1)", unit, 1)
    end



    if MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].FlashLight==1 then

        MPHealTargetDelay[targetName] = GetTime()

        if MPPaladinFlashLightEffect[7]<HealthDec or MPPaladinMeleeHealSaved[MPPaladinMeleeHealConfig].Force==1 then

            if DM >= MPPaladinFlashLight[7] then
                return MPCastSpellWithoutTarget("圣光闪现(等级 7)", unit, 1)
            elseif DM >= MPPaladinFlashLight[4] then
                return MPCastSpellWithoutTarget("圣光闪现(等级 4)", unit, 1)
            else
                return MPCastSpellWithoutTarget("圣光闪现(等级 1)", unit, 1)
            end

        end

        for i = 7, 2, -1 do
            if MPPaladinFlashLightEffect[i] < HealthDec then

                if DM >= MPPaladinFlashLight[i] then
                    return MPCastSpellWithoutTarget("圣光闪现(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("圣光闪现(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("圣光闪现(等级 1)", unit, 1)
    end


    return false
end





