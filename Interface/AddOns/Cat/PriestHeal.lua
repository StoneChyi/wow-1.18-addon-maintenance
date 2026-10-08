if MPPlayerClass ~= "PRIEST" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 神牧一键宏
-- 更新日期：2026-07-17 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
--
-- 说明：
-- 
-- -------------------------------------
-- 功能配置：
-- 注：修改以下配置，需要在游戏中/reload，或者小退让配置生效
-- 
-- 主开关

-- 以下功能开关：1开启 0关闭


-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化

-- 恢复
MPPriestRenewMana = {}
MPPriestRenewEffect = {}
MPPriestRenewFactor = 0.6
MPPriestRenewManaMaxLevel = 10

-- 强效治疗术
MPPriestGreaterHealMana = {}
MPPriestGreaterHealEffect = {}
MPPriestGreaterHealFactor = 0.7
MPPriestGreaterHealManaMaxLevel = 5

-- 快速治疗
MPPriestFlashHealMana = {}
MPPriestFlashHealEffect = {}
MPPriestFlashHealFactor = 0.7
MPPriestFlashHealManaMaxLevel = 7

-- -------------------------------------

MPPriestCastHeal = -5
MPPriestCastHealTarget = nil
local MPHealTargetDelay = {}
local MPHealthUnit = nil
local PriestHealLoopTimer = 0

local DM

-- 默认配置
MPPriestHealConfig = 1


function MPPriestAutoHealth()

    -- 正在读条
    if GetTime()-MPPriestCastHeal<3 then

        -- 是否有治疗目标
        if MPHealthUnit and MPPriestHealSaved[MPPriestHealConfig].Overflow==1 then
            -- 被治疗目标状态
            local target_percent = UnitHealth(MPHealthUnit) / UnitHealthMax(MPHealthUnit) * 100
            if target_percent > MPPriestHealSaved[MPPriestHealConfig].Begin_Value then
                SpellStopCasting()
            end
        end

        return
    end

	DM = UnitMana("player")

	-- 自动拾取
	if MPPriestHealSaved[MPPriestHealConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPPriestHealSaved[MPPriestHealConfig].Power==1 then
		MPCatPower()
	end



	-- 在战斗中
	if MPInCombat then
	    -- 血量危险时处理，潜行下不吃药
	    local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	    if percent<MPPriestHealSaved[MPPriestHealConfig].HealthStone_Value and MPPriestHealSaved[MPPriestHealConfig].HealthStone==1 then
		    MPUseItemByName("特效治疗石")
	    end
	    if percent<MPPriestHealSaved[MPPriestHealConfig].HerbalTea_Value and MPPriestHealSaved[MPPriestHealConfig].HerbalTea==1 then
		    MPUseItemByName("糖水茶")
		    MPUseItemByName("诺达纳尔草药茶")
	    end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPPriestHealSaved[MPPriestHealConfig].HerbalTeaMana_Value and MPPriestHealSaved[MPPriestHealConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
    end

	local GCD = MPGetGCD()

    if GCD<1.3 then
        return
    end

    -- 目标
    if UnitExists("target") and MPPriestHealSaved[MPPriestHealConfig].TargetFirst==1 then
        if MPPriestHealth("target") then
            return
        end
    end

    -- 目标的目标
    if UnitExists("target") and UnitExists("targettarget") and MPPriestHealSaved[MPPriestHealConfig].TargetTarget==1 then
        if MPPriestHealth("targettarget") then
            return
        end
    end

    if MPPriestHealSaved[MPPriestHealConfig].PrayerHealing==1 and (GetTime()-PriestHealLoopTimer>0) then
    if MPPriestHealSaved[MPPriestHealConfig].PrayerBook==0 or (MPPriestHealSaved[MPPriestHealConfig].PrayerBook==1 and MPPriestPrayerBookCount~=4) then
        -- 祷言 本队优先
        if MPPriestHealSaved[MPPriestHealConfig].PrayerHealingPartyFirst==1 then
            MPPrayerHealthParty()
        end

        -- 祷言 团队
        MPPrayerHealthRaid()

        PriestHealLoopTimer = GetTime()+0.3
    end
    end

    -- 自己
    if MPPriestHealSaved[MPPriestHealConfig].SelfFirst==1 then
        if MPPriestHealth("player") then
            return
        end
    end

    -- 队伍里的其他人
    if MPPriestHealSaved[MPPriestHealConfig].ScanTeam==1 then

        if MPPriestHealSaved[MPPriestHealConfig].ScanTeam_Low==1 then
            local sortedMembers = MPGetSortedGroupByHealth()
            for i, member in ipairs(sortedMembers) do
                if MPPriestHealth(member.unit) then
                    return
                end
            end
        else
            local sortedMembers = MPShuffleTable(MPGetSortedGroupByHealth())
            for i, member in ipairs(sortedMembers) do
                if MPPriestHealth(member.unit) then
                    return
                end
            end
        end

    end
end



function MPPriestHealth(unit)

    if not unit then
        return false
    end

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    local percentHealth = 0
    local HealthDec = 0

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


    percentHealth = health/maxHealth * 100
    HealthDec = maxHealth - health
    --print(string.format("[查询] %s: %d/%d (%f%%)", name, health, maxHealth, percentHealth))

    if MPPriestHealSaved[MPPriestHealConfig].Begin_Value <= percentHealth then
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
    local targetName = UnitName(unit)
    MPPriestCastHealTarget = nil

    if MPHealTargetDelay[targetName] and MPHealTargetDelay[targetName]-GetTime() > 0 then
        return false
    end

    MPHealTargetDelay[targetName] = GetTime()+1.0

    -- 危机抢救
    if percentHealth < MPPriestHealSaved[MPPriestHealConfig].Desperate_Value and MPPriestHealSaved[MPPriestHealConfig].DesperatePrayer==1 and MPSpellReady("绝望祷言") then
        return MPCastSpellWithoutTarget("绝望祷言", unit, 1)
    end

    -- 套盾
    if percentHealth < MPPriestHealSaved[MPPriestHealConfig].Shield_Value and MPPriestHealSaved[MPPriestHealConfig].Shield==1 and not MPBuff("真言术：盾",unit) and MPSpellReady("真言术：盾") then
        return MPCastSpellWithoutTarget("真言术：盾", unit, 1)
    end

    MPHealthUnit = unit


    -- 恢复
    if (MPIsMoving() or MPPriestHealSaved[MPPriestHealConfig].FlashHeal==0) and MPPriestHealSaved[MPPriestHealConfig].MoveRenew==1 and MPPriestRenewManaMaxLevel>0 then
        -- 目标是否已经有恢复
        if not MPBuff("恢复",unit) then

            -- 根据配置等级和所学等级计算
            local RenewMaxLevel = MPPriestRenewManaMaxLevel
            if MPPriestHealSaved[MPPriestHealConfig].RenewMaxLevel < MPPriestRenewManaMaxLevel then
                RenewMaxLevel = MPPriestHealSaved[MPPriestHealConfig].RenewMaxLevel
            end

            for i = RenewMaxLevel, MPPriestHealSaved[MPPriestHealConfig].RenewMinLevel, -1 do
                if MPPriestRenewEffect[i] < HealthDec then

                    if DM >= MPPriestRenewMana[i] then
                        return MPCastSpellWithoutTarget("恢复(等级 "..i..")", unit, 1)
                    else
                        return MPCastSpellWithoutTarget("恢复(等级 1)", unit, 1)
                    end

                end
            end

            return MPCastSpellWithoutTarget("恢复(等级 "..MPPriestHealSaved[MPPriestHealConfig].RenewMinLevel..")", unit, 1)
        end
    end


    -- 治疗祷言



    -- 强效治疗术
    if percentHealth < MPPriestHealSaved[MPPriestHealConfig].GreaterHeal_Value and MPPriestHealSaved[MPPriestHealConfig].GreaterHeal==1 and MPPriestGreaterHealManaMaxLevel>0 then
    if MPPriestHealSaved[MPPriestHealConfig].PrayerBook==0 or (MPPriestHealSaved[MPPriestHealConfig].PrayerBook==1 and MPPriestPrayerBookCount~=3) then

        -- 根据配置等级和所学等级计算
        local GreaterHealMaxLevel = MPPriestGreaterHealManaMaxLevel
        if MPPriestHealSaved[MPPriestHealConfig].GreaterHealMaxLevel < MPPriestGreaterHealManaMaxLevel then
            GreaterHealMaxLevel = MPPriestHealSaved[MPPriestHealConfig].GreaterHealMaxLevel
        end

        for i = GreaterHealMaxLevel, MPPriestHealSaved[MPPriestHealConfig].GreaterHealMinLevel, -1 do
            if MPPriestGreaterHealEffect[i] < HealthDec then

                if DM >= MPPriestGreaterHealMana[i] then
                    return MPCastSpellWithoutTarget("强效治疗术(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("强效治疗术(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("强效治疗术(等级 "..MPPriestHealSaved[MPPriestHealConfig].GreaterHealMinLevel..")", unit, 1)

    end
    end

    -- 快速治疗
    if MPPriestHealSaved[MPPriestHealConfig].FlashHeal==1 and MPPriestFlashHealManaMaxLevel>0 then
    if MPPriestHealSaved[MPPriestHealConfig].PrayerBook==0 or (MPPriestHealSaved[MPPriestHealConfig].PrayerBook==1 and MPPriestPrayerBookCount~=2) then

        -- 根据配置等级和所学等级计算
        local FlashHealMaxLevel = MPPriestFlashHealManaMaxLevel
        if MPPriestHealSaved[MPPriestHealConfig].FlashHealMaxLevel < MPPriestFlashHealManaMaxLevel then
            FlashHealMaxLevel = MPPriestHealSaved[MPPriestHealConfig].FlashHealMaxLevel
        end

        for i = FlashHealMaxLevel, MPPriestHealSaved[MPPriestHealConfig].FlashHealMinLevel, -1 do
            if MPPriestFlashHealEffect[i] < HealthDec then

                if DM >= MPPriestFlashHealMana[i] then
                    return MPCastSpellWithoutTarget("快速治疗(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("快速治疗(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("快速治疗(等级 "..MPPriestHealSaved[MPPriestHealConfig].FlashHealMinLevel..")", unit, 1)
    end
    end


    return false
end



-- 洗牌
function MPShuffleTable(t)
    if not t or type(t) ~= "table" then
        return {}
    end
    
    local result = {}
    local n = table.getn(t)
    
    for i = 1, n do
        result[i] = t[i]
    end
    
    for i = n, 2, -1 do
        local j = math.random(1, i)
        result[i], result[j] = result[j], result[i]
    end
    
    return result
end


-- 获取团队成员并按血量降序排序
function MPGetSortedGroupByHealth()
    local members = MPGetGroupHealthList()
    return MPSortByHealthPercentAsc(members)
end

function MPSortByHealthPercentAsc(members)
    table.sort(members, function(a, b)
        local aPercent = a.health / a.maxHealth
        local bPercent = b.health / b.maxHealth
        return aPercent < bPercent
    end)
    return members
end


function MPGetGroupHealthList()
    local groupMembers = {}
    
    -- 先检查是否在团队（经典旧世团队和队伍互斥）
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers > 0 then
        -- 处理团队（最多40人）
        for i = 1, numRaidMembers do
            local unit = "raid" .. i
            if UnitExists(unit) and UnitIsVisible(unit) then
                table.insert(groupMembers, {
                    name = UnitName(unit),
                    health = UnitHealth(unit),
                    maxHealth = UnitHealthMax(unit),
                    unit = unit,
                    isPlayer = UnitIsUnit(unit, "player")
                })
            end
        end
    else
        -- 不在团队，检查是否在队伍
        local numPartyMembers = GetNumPartyMembers()
        
        -- 先添加玩家自己
        table.insert(groupMembers, {
            name = UnitName("player"),
            health = UnitHealth("player"),
            maxHealth = UnitHealthMax("player"),
            unit = "player",
            isPlayer = true
        })
        
        -- 添加队友（如果有）
        if numPartyMembers > 0 then
            for i = 1, numPartyMembers do
                local unit = "party" .. i
                if UnitExists(unit) and UnitIsVisible(unit) then
                    table.insert(groupMembers, {
                        name = UnitName(unit),
                        health = UnitHealth(unit),
                        maxHealth = UnitHealthMax(unit),
                        unit = unit,
                        isPlayer = false
                    })
                end
            end
        end
    end
    
    return groupMembers
end


-- 治疗祷言 算式

function MPGetUnitScore(unit)
    local HPP = 0
    if UnitExists(unit) and UnitIsVisible(unit) and not UnitIsDeadOrGhost(unit) then
        HPP = 10 - (UnitHealth(unit) / UnitHealthMax(unit) * 10)
        if HPP > 3 then HPP=3 end
    end

    return HPP
end

function MPPrayerHealthParty()

    local unit = "player"

    -- 检查是否在队伍
    local numPartyMembers = GetNumPartyMembers()
    if numPartyMembers>0 then

        local score = MPGetUnitScore("player")

        -- 收集权重
        for i = 1, numPartyMembers do
            unit = "party" .. i
            score = score+MPGetUnitScore(unit)
        end

        --MPMsg("祷言 本队评价:"..score)
        -- 评分
        if score >= MPPriestHealSaved[MPPriestHealConfig].PrayerHealing_Value then
            local Level = MPPriestHealSaved[MPPriestHealConfig].PrayerHealingMaxLevel
            if DM<500 then
                Level = 1
            end

            MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "party1", 1)
            MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "party2", 1)
            MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "party3", 1)
            MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "party4", 1)
            MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "player", 1)
            return
        end

    end

    return
end

function MPPrayerHealthRaid()

    local unit = "player"

    -- 先检查是否在团队（经典旧世团队和队伍互斥）
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers > 0 then
        local Party = 0
        local Score = {}

        -- 收集权重
        for i=1, 40, 5 do

            Party = Party + 1
            Score[Party] = 0

            for j=i, i+4 do
                unit = "raid" .. j
                Score[Party] = Score[Party]+MPGetUnitScore(unit)
            end

            --MPMsg("小队"..Party.." - ".. Score[Party])

        end

        -- 选择小队
        local targetParty = 0
        local temp = 0
        for i=1, 8 do
            if Score[i] > temp then
                temp = Score[i]
                targetParty = i
            end
        end



        --MPMsg("祷言 小队"..targetParty)
        -- 评分
        if temp >= MPPriestHealSaved[MPPriestHealConfig].PrayerHealing_Value then
            targetParty = targetParty-1
            --[[
            MPMsg("raid"..targetParty*5+1)
            MPMsg("raid"..targetParty*5+2)
            MPMsg("raid"..targetParty*5+3)
            MPMsg("raid"..targetParty*5+4)
            MPMsg("raid"..targetParty*5+5)
            ]]
            local Level = MPPriestHealSaved[MPPriestHealConfig].PrayerHealingMaxLevel
            if DM<500 then
                Level = 1
                MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "raid"..targetParty*5+1, 1)
                MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "raid"..targetParty*5+2, 1)
                MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "raid"..targetParty*5+3, 1)
                MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "raid"..targetParty*5+4, 1)
                MPCastSpellWithoutTarget("治疗祷言(等级 "..Level..")", "raid"..targetParty*5+5, 1)
                return
            end

            MPCastSpellWithoutTarget("治疗祷言", "raid"..targetParty*5+1, 1)
            MPCastSpellWithoutTarget("治疗祷言", "raid"..targetParty*5+2, 1)
            MPCastSpellWithoutTarget("治疗祷言", "raid"..targetParty*5+3, 1)
            MPCastSpellWithoutTarget("治疗祷言", "raid"..targetParty*5+4, 1)
            MPCastSpellWithoutTarget("治疗祷言", "raid"..targetParty*5+5, 1)
            return
        end

    end

    return
end

