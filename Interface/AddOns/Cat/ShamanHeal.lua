if MPPlayerClass ~= "SHAMAN" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 奶萨一键宏
-- 更新日期：2026-04-10 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
--
-- 说明：
-- 
-- -------------------------------------
--[[
MPShamanTotem = {
    "大地之力图腾" = 120,
    "石肤图腾" = 120,
    "地缚图腾" = 45,
    "石爪图腾" = 15,
    "战栗图腾" = 120,

    "火焰新星图腾" = 5,
    "灼热图腾" = 55,
    "熔岩图腾" = 20,
    "抗寒图腾" = 120,
    "火舌图腾" = 120,

    "抗火图腾" = 120,
    "治疗之泉图腾" = 60,
    "法力之泉图腾" = 60,
    "清毒图腾" = 120,
    "祛病图腾" = 120,

    "岗哨图腾" = 300,
    "根基图腾" = 45,
    "自然抗性图腾" = 120,
    "风之优雅图腾" = 120,
    "风墙图腾" = 120,
    "风怒图腾" = 120,
    "宁静之风图腾" = 120,
}
]]


-- 治疗波
MPShamanWave = {}
MPShamanWaveEffect = {}
MPShamanWaveFactor = 0.6
MPShamanWaveMaxLevel = 10

-- 次级治疗波
MPShamanSecondaryWave = {}
MPShamanSecondaryWaveEffect = {}
MPShamanSecondaryWaveFactor = 0.55
MPShamanSecondaryWaveMaxLevel = 6

-- 治疗波
MPShamanChain = {}
MPShamanChainEffect = {}
MPShamanChainFactor = 0.7
MPShamanChainMaxLevel = 3

-- 水之护盾层数
MPShamanWaterApplications = 3

MPShamanCastHeal = -5
MPShamanCastHealTarget = nil
local MPHealTargetDelay = {}
local MPHealthUnit = nil


MPEarthTotemTimer = 0
MPEarthTotemDuration = 0
MPEarthTotemName = ""
MPEarthTotemX = 0
MPEarthTotemY = 0

MPFireTotemTimer = 0
MPFireTotemDuration = 0
MPFireTotemName = ""
MPFireTotemX = 0
MPFireTotemY = 0

MPWaterTotemTimer = 0
MPWaterTotemDuration = 0
MPWaterTotemName = ""
MPWaterTotemX = 0
MPWaterTotemY = 0

MPAirTotemTimer = 0
MPAirTotemDuration = 0
MPAirTotemName = ""
MPAirTotemX = 0
MPAirTotemY = 0

-- 默认配置
MPShamanHealConfig = 1


local function HealEarthTotemManager()

    -- 检测开关
    if MPShamanHealSaved[MPShamanHealConfig].EarthTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPEarthTotem() and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==0 then
    elseif MPEarthTotem() and MPEarthTotemName==MPShamanHealSaved[MPShamanHealConfig].EarthTotem_Value and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanHealSaved[MPShamanHealConfig].EarthTotem_Value)
        MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")
    end

end


local function HealFireTotemManager()

    -- 检测开关
    if MPShamanHealSaved[MPShamanHealConfig].FireTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPFireTotem() and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==0 then
    elseif MPFireTotem() and MPFireTotemName==MPShamanHealSaved[MPShamanHealConfig].FireTotem_Value and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanHealSaved[MPShamanHealConfig].FireTotem_Value)
        MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")
    end

end

local function HealWaterTotemManager()

    -- 检测开关
    if MPShamanHealSaved[MPShamanHealConfig].WaterTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPWaterTotem() and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==0 then
    elseif MPWaterTotem() and MPWaterTotemName==MPShamanHealSaved[MPShamanHealConfig].WaterTotem_Value and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanHealSaved[MPShamanHealConfig].WaterTotem_Value)
        MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")
    end

end


local function HealAirTotemManager()

    -- 检测开关
    if MPShamanHealSaved[MPShamanHealConfig].AirTotem==0 then
        return
    end

    -- 图腾是否存在
    if MPAirTotem() and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==0 then
    elseif MPAirTotem() and MPAirTotemName==MPShamanHealSaved[MPShamanHealConfig].AirTotem_Value and MPShamanHealSaved[MPShamanHealConfig].ForceTotem==1 then

    else
        CastSpellByName(MPShamanHealSaved[MPShamanHealConfig].AirTotem_Value)
        MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")
    end

end


local PartyNeedHealth = 0

-- 团队需要治疗的成员数量
local GroupHealthCount = 0


function MPShamanAutoHealth()

    -- 正在读条
    if GetTime()-MPShamanCastHeal<3 then

        -- 是否有治疗目标
        if MPHealthUnit and MPShamanHealSaved[MPShamanHealConfig].Overflow==1 then
            -- 被治疗目标状态
            local target_percent = UnitHealth(MPHealthUnit) / UnitHealthMax(MPHealthUnit) * 100
            if target_percent > MPShamanHealSaved[MPShamanHealConfig].Begin_Value then
                SpellStopCasting()
            end
        end

        return
    end

	-- 自动拾取
	if MPShamanHealSaved[MPShamanHealConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPShamanHealSaved[MPShamanHealConfig].Power==1 then
		MPCatPower()
	end



	-- 在战斗中
	if MPInCombat then
	    -- 血量危险时处理，潜行下不吃药
	    local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	    if percent<MPShamanHealSaved[MPShamanHealConfig].HealthStone_Value and MPShamanHealSaved[MPShamanHealConfig].HealthStone==1 then
		    MPUseItemByName("特效治疗石")
	    end
	    if percent<MPShamanHealSaved[MPShamanHealConfig].HerbalTea_Value and MPShamanHealSaved[MPShamanHealConfig].HerbalTea==1 then
		    MPUseItemByName("糖水茶")
		    MPUseItemByName("诺达纳尔草药茶")
	    end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPShamanHealSaved[MPShamanHealConfig].HerbalTeaMana_Value and MPShamanHealSaved[MPShamanHealConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
    end

    --[[
    -- 图腾召回
    if MPShamanHealSaved[MPShamanHealConfig].RecallTotems==1 and MPSpellReady("图腾召回") then
        local recall = 0
        local x, y = GetPlayerMapPosition("player")
        local EarthTotemDist = MPCalculateTotemDistance(x,y, MPEarthTotemX, MPEarthTotemY)
        local FireTotemDist = MPCalculateTotemDistance(x,y, MPFireTotemX, MPFireTotemY)
        local WaterTotemDist = MPCalculateTotemDistance(x,y, MPWaterTotemX, MPWaterTotemY)
        local AirTotemDist = MPCalculateTotemDistance(x,y, MPAirTotemX, MPAirTotemY)
        if MPEarthTotem() and EarthTotemDist>MPShamanHealSaved[MPShamanHealConfig].RecallTotems_Value then recall = recall+1 end
        if MPFireTotem() and FireTotemDist>MPShamanHealSaved[MPShamanHealConfig].RecallTotems_Value  then recall = recall+1 end
        if MPWaterTotem() and WaterTotemDist>MPShamanHealSaved[MPShamanHealConfig].RecallTotems_Value  then recall = recall+1 end
        if MPAirTotem() and AirTotemDist>MPShamanHealSaved[MPShamanHealConfig].RecallTotems_Value  then recall = recall+1 end
        if recall > 0 then
            CastSpellByName("图腾召回")
            return
        end
    end
    ]]

    -- 图腾
    HealEarthTotemManager()
    HealFireTotemManager()
    HealWaterTotemManager()
    HealAirTotemManager()

	local GCD = MPGetGCD()
    if GCD<1.3 then
        -- 水之护盾


        -- 图腾是否存在
        if MPShamanHealSaved[MPShamanHealConfig].EarthTotem==0 or (MPShamanHealSaved[MPShamanHealConfig].EarthTotem==1 and MPEarthTotem() and MPEarthTotemName==MPShamanHealSaved[MPShamanHealConfig].EarthTotem_Value) then
        if MPShamanHealSaved[MPShamanHealConfig].FireTotem==0 or (MPShamanHealSaved[MPShamanHealConfig].FireTotem==1 and MPFireTotem() and MPFireTotemName==MPShamanHealSaved[MPShamanHealConfig].FireTotem_Value) then
        if MPShamanHealSaved[MPShamanHealConfig].WaterTotem==0 or (MPShamanHealSaved[MPShamanHealConfig].WaterTotem==1 and MPWaterTotem() and MPWaterTotemName==MPShamanHealSaved[MPShamanHealConfig].WaterTotem_Value) then
        if MPShamanHealSaved[MPShamanHealConfig].AirTotem==0 or (MPShamanHealSaved[MPShamanHealConfig].AirTotem==1 and MPAirTotem() and MPAirTotemName==MPShamanHealSaved[MPShamanHealConfig].AirTotem_Value) then

            if MPShamanHealSaved[MPShamanHealConfig].WaterShieldLevel==1 and MPShamanHealSaved[MPShamanHealConfig].WaterShield==1 then
                if MPGetBuffApplications("Interface\\Icons\\Ability_Shaman_WaterShield")<MPShamanWaterApplications then
                    CastSpellByName("水之护盾")
                    --return
                end
            elseif MPShamanHealSaved[MPShamanHealConfig].WaterShield==1 then
                if not MPBuff("水之护盾") then
                    CastSpellByName("水之护盾")
                    --return
                end
            end

        end
        end
        end
        end

    end

    -- 萨满必须
    local sortedMembers = MPShamanGetSortedGroupByHealth()

    -- 目标
    if UnitExists("target") and MPShamanHealSaved[MPShamanHealConfig].TargetFirst==1 then
        if MPShamanHealth("target") then
            return
        end
    end

    -- 目标的目标
    if UnitExists("target") and UnitExists("targettarget") and MPShamanHealSaved[MPShamanHealConfig].TargetTarget==1 then
        if MPShamanHealth("targettarget") then
            return
        end
    end

    -- 自己
    if MPShamanHealSaved[MPShamanHealConfig].SelfFirst==1 then
        if MPShamanHealth("player") then
            return
        end
    end

    -- 水之护盾
    if MPShamanHealSaved[MPShamanHealConfig].WaterShieldLevel==1 and MPShamanHealSaved[MPShamanHealConfig].WaterShield==1 then
        if MPGetBuffApplications("Interface\\Icons\\Ability_Shaman_WaterShield")<MPShamanWaterApplications then
            CastSpellByName("水之护盾")
        end
    elseif MPShamanHealSaved[MPShamanHealConfig].WaterShield==1 then
        if not MPBuff("水之护盾") then
            CastSpellByName("水之护盾")
        end
    end

    -- 队伍里的其他人
    if MPShamanHealSaved[MPShamanHealConfig].ScanTeam==1 then

        if MPShamanHealSaved[MPShamanHealConfig].ScanTeam_Low==1 then
            for i, member in ipairs(sortedMembers) do
                if MPShamanHealth(member.unit) then
                    return
                end
            end
        else
            sortedMembers = MPShuffleTable(sortedMembers)
            for i, member in ipairs(sortedMembers) do
                if MPShamanHealth(member.unit) then
                    return
                end
            end
        end

    end

end


function MPShamanHealth(unit)

    if not unit then
        return false
    end

	local DM = UnitMana("player")
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


    -- 计算目标生命值比例
    percentHealth = health/maxHealth*100
    HealthDec = maxHealth - health

    if MPShamanHealSaved[MPShamanHealConfig].Begin_Value <= percentHealth then
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
    MPShamanCastHealTarget = nil

    if MPHealTargetDelay[targetName] and GetTime()-MPHealTargetDelay[targetName] < 1.2 then
        return false
    end


    -- 尝试治疗 --

    MPHealthUnit = unit

    -- 开启治疗链 + 群体掉血，优先级最高
    if MPShamanHealSaved[MPShamanHealConfig].Chain==1 and GroupHealthCount>1 and MPShamanChainMaxLevel>0 then

        MPHealTargetDelay[targetName] = GetTime()

        -- 根据配置等级和所学等级计算
        local ChainMaxLevel = MPShamanChainMaxLevel
        if MPShamanHealSaved[MPShamanHealConfig].ChainMaxLevel < MPShamanChainMaxLevel then
            ChainMaxLevel = MPShamanHealSaved[MPShamanHealConfig].ChainMaxLevel
        end

        for i = ChainMaxLevel, MPShamanHealSaved[MPShamanHealConfig].ChainMinLevel, -1 do
            if MPShamanChainEffect[i] < HealthDec then

                if DM >= MPShamanChain[i] then
                    return MPCastSpellWithoutTarget("治疗链(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("治疗链(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("治疗链(等级 "..MPShamanHealSaved[MPShamanHealConfig].ChainMinLevel..")", unit, 1)

    end

    -- 仅仅开启治疗链， 治疗波和次级治疗波都没开
    if MPShamanHealSaved[MPShamanHealConfig].Chain==1 and MPShamanHealSaved[MPShamanHealConfig].Wave==0 and MPShamanHealSaved[MPShamanHealConfig].SecondaryWave==0 and MPShamanChainMaxLevel>0 then

        MPHealTargetDelay[targetName] = GetTime()

        -- 根据配置等级和所学等级计算
        local ChainMaxLevel = MPShamanChainMaxLevel
        if MPShamanHealSaved[MPShamanHealConfig].ChainMaxLevel < MPShamanChainMaxLevel then
            ChainMaxLevel = MPShamanHealSaved[MPShamanHealConfig].ChainMaxLevel
        end

        for i = ChainMaxLevel, MPShamanHealSaved[MPShamanHealConfig].ChainMinLevel, -1 do
            if MPShamanChainEffect[i] < HealthDec then

                if DM >= MPShamanChain[i] then
                    return MPCastSpellWithoutTarget("治疗链(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("治疗链(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("治疗链(等级 "..MPShamanHealSaved[MPShamanHealConfig].ChainMinLevel..")", unit, 1)

    end


    -- 治疗波
    if percentHealth < MPShamanHealSaved[MPShamanHealConfig].Wave_Value and MPShamanHealSaved[MPShamanHealConfig].Wave==1 and MPShamanWaveMaxLevel>0 then
        MPHealTargetDelay[targetName] = GetTime()

        -- 根据配置等级和所学等级计算
        local WaveMaxLevel = MPShamanWaveMaxLevel
        if MPShamanHealSaved[MPShamanHealConfig].WaveMaxLevel < MPShamanWaveMaxLevel then
            WaveMaxLevel = MPShamanHealSaved[MPShamanHealConfig].WaveMaxLevel
        end

        for i = WaveMaxLevel, MPShamanHealSaved[MPShamanHealConfig].WaveMinLevel, -1 do
            if MPShamanWaveEffect[i] < HealthDec then

                if DM >= MPShamanWave[i] then
                    return MPCastSpellWithoutTarget("治疗波(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("治疗波(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("治疗波(等级 "..MPShamanHealSaved[MPShamanHealConfig].WaveMinLevel..")", unit, 1)
    end

    -- 次级治疗波
    if percentHealth < MPShamanHealSaved[MPShamanHealConfig].SecondaryWave_Value and MPShamanHealSaved[MPShamanHealConfig].SecondaryWave==1 and MPShamanSecondaryWaveMaxLevel>0 then
        MPHealTargetDelay[targetName] = GetTime()

        -- 根据配置等级和所学等级计算
        local SecondaryWaveMaxLevel = MPShamanSecondaryWaveMaxLevel
        if MPShamanHealSaved[MPShamanHealConfig].SecondaryWaveMaxLevel < MPShamanSecondaryWaveMaxLevel then
            SecondaryWaveMaxLevel = MPShamanHealSaved[MPShamanHealConfig].SecondaryWaveMaxLevel
        end

        for i = SecondaryWaveMaxLevel, MPShamanHealSaved[MPShamanHealConfig].SecondaryWaveMinLevel, -1 do
            if MPShamanSecondaryWaveEffect[i] < HealthDec then

                if DM >= MPShamanSecondaryWave[i] then
                    return MPCastSpellWithoutTarget("次级治疗波(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("次级治疗波(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("次级治疗波(等级 "..MPShamanHealSaved[MPShamanHealConfig].SecondaryWaveMinLevel..")", unit, 1)
    end

    -- 开启治疗链
    if MPShamanHealSaved[MPShamanHealConfig].Chain==1 and MPShamanChainMaxLevel>0 then

        MPHealTargetDelay[targetName] = GetTime()

        -- 根据配置等级和所学等级计算
        local ChainMaxLevel = MPShamanChainMaxLevel
        if MPShamanHealSaved[MPShamanHealConfig].ChainMaxLevel < MPShamanChainMaxLevel then
            ChainMaxLevel = MPShamanHealSaved[MPShamanHealConfig].ChainMaxLevel
        end

        for i = ChainMaxLevel, MPShamanHealSaved[MPShamanHealConfig].ChainMinLevel, -1 do
            if MPShamanChainEffect[i] < HealthDec then

                if DM >= MPShamanChain[i] then
                    return MPCastSpellWithoutTarget("治疗链(等级 "..i..")", unit, 1)
                else
                    return MPCastSpellWithoutTarget("治疗链(等级 1)", unit, 1)
                end

            end
        end

        return MPCastSpellWithoutTarget("治疗链(等级 "..MPShamanHealSaved[MPShamanHealConfig].ChainMinLevel..")", unit, 1)

    end

    return false
end



function MPLeaveCombatTotem()
    --CastSpellByName("图腾召回")
    --print("图腾召回")
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
function MPShamanGetSortedGroupByHealth()
    local members = MPShamanGetGroupHealthList()
    return MPShamanSortByHealthPercentAsc(members)
end

function MPShamanSortByHealthPercentAsc(members)
    table.sort(members, function(a, b)
        local aPercent = a.health / a.maxHealth
        local bPercent = b.health / b.maxHealth
        return aPercent < bPercent
    end)
    return members
end


function MPShamanGetGroupHealthList()
    local groupMembers = {}

    GroupHealthCount = 0

    local Health = UnitHealth("player")
    if Health and Health>0 then
        local percentHealth = UnitHealth("player")/UnitHealthMax("player")*100
        if percentHealth < MPShamanHealSaved[MPShamanHealConfig].SecondaryWave_Value then
            GroupHealthCount = GroupHealthCount + 1
        end
    end

    -- 先检查是否在团队（经典旧世团队和队伍互斥）
    local numRaidMembers = GetNumRaidMembers()
    if numRaidMembers > 0 then
        -- 处理团队（最多40人）
        for i = 1, numRaidMembers do
            local unit = "raid" .. i
            if UnitExists(unit) and UnitIsVisible(unit) then
                -- 累积掉血者
                Health = UnitHealth(unit)
                if Health and Health>0 then
                    local percentHealth = UnitHealth(unit)/UnitHealthMax(unit)*100
                    if percentHealth < MPShamanHealSaved[MPShamanHealConfig].SecondaryWave_Value then
                        GroupHealthCount = GroupHealthCount + 1
                    end
                end


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
                    -- 累积掉血者
                    Health = UnitHealth(unit)
                    if Health and Health>0 then
                        local percentHealth = UnitHealth(unit)/UnitHealthMax(unit)*100
                        if percentHealth < MPShamanHealSaved[MPShamanHealConfig].SecondaryWave_Value then
                            GroupHealthCount = GroupHealthCount + 1
                        end
                    end
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


