local _, playerClass = UnitClass("player")
if playerClass ~= "HUNTER" then
    return  -- 终止文件执行
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
--frame:RegisterEvent("CHAT_MSG_SPELL_PET_DAMAGE")
--frame:RegisterEvent("CHAT_MSG_COMBAT_PET_HITS")
frame:RegisterEvent("START_AUTOREPEAT_SPELL")
frame:RegisterEvent("STOP_AUTOREPEAT_SPELL")

frame:RegisterEvent("SPELLCAST_CHANNEL_START")
frame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("SPELLCAST_DELAYED")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_START")
frame:RegisterEvent("SPELLS_CHANGED")


-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")

-- 自己的GUID
local PLAYER_GUID = 0

-- 等待技能反馈的等待时间
local BLEENCHECKDELAY = 0.3

local SerpentCheck = {}
local SerpentDelayTime = {}
local ViperCheck = {}
local ViperDelayTime = {}

-- 割伤 激活时间
MPHunterGoreTimer = 0


-- 自动射击状态
MPHunterAutoShot = 0

local function ResetData()
    SerpentCheck = {}
    SerpentDelayTime = {}
    ViperCheck = {}
    ViperDelayTime = {}
end



local function OnEvent()

    if event == "PLAYER_LOGIN" then
        if SUPERWOW_STRING then
            -- 获取并保存自己的GUID
            local a,guid = UnitExists("player")
            PLAYER_GUID = guid
        end

    -- 进入游戏世界刷新常量值
    elseif event == "PLAYER_ENTERING_WORLD" then
        ResetData()

    -- 离开战斗事件
    elseif event == "PLAYER_REGEN_ENABLED" then
        ResetData()

    -- 玩家死亡，重置一些参数
    elseif event == "PLAYER_DEAD" then
        ResetData()


    -- 施法事件处理，读条类，读条也要处理GCD
    elseif event == "SPELLCAST_START" then

        --message(arg1)
        -- 牧师治疗读条处理
        --if arg1 == "自动射击" then print("自动射击") end

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then

        --message(arg1)
        if not MP_SuperWoW then
            if string.find( arg1, ".*你的自动射击.*" ) then
                MPHunterShotTimer = GetTime()
                MPHunterShotDuration = UnitRangedDamage("player")
            end
        end
        
        if string.find( arg1, ".*致命一击.*" ) then
            MPHunterGoreTimer = GetTime()+4

        -- 奥术射击 - 异常免疫目标记录
        elseif string.find( arg1, ".*奥术射击.*免疫.*" ) then

            local targetName = UnitName("target")
            if targetName then
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."发现["..targetName.."]免疫奥术射击。")
                -- 将该目标加入表（临时，重登后丢失）
                MPHunterArcaneShotBlcokList[targetName] = true
            end

        -- 猎人印记 - 异常免疫目标记录
        elseif string.find( arg1, ".*猎人印记.*免疫.*" ) then

            local targetName = UnitName("target")
            if targetName then
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."发现["..targetName.."]免疫猎人印记。")
                -- 将该目标加入表（临时，重登后丢失）
                MPHunterMarkBlcokList[targetName] = true
            end

        -- 毒蛇钉刺 - 异常免疫目标记录
        elseif string.find( arg1, ".*毒蛇钉刺.*免疫.*" ) then

            local targetName = UnitName("target")
            if targetName then
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."发现["..targetName.."]免疫毒蛇钉刺。")
                -- 将该目标加入表（临时，重登后丢失）
                MPPosionBlcokList[targetName] = true
            end

        end

        --print(arg1)

    elseif event == "CHAT_MSG_COMBAT_SELF_HITS" then

        if string.find( arg1, ".*致命一击.*" ) then
            MPHunterGoreTimer = GetTime()+4
        end

    --[[
    elseif event == "CHAT_MSG_SPELL_PET_DAMAGE" then

        if UnitExists("pet") and not UnitIsDead("pet") then
            if string.find( arg1, UnitName("pet") ) then
                if string.find( arg1, UnitName("player") ) then
                    if string.find( arg1, ".*致命一击.*" ) then
                        MPHunterBaitShotTimer = GetTime()+4
                    end
                end
            end
        end

    elseif event == "CHAT_MSG_COMBAT_PET_HITS" then

        if UnitExists("pet") and not UnitIsDead("pet") then
            if string.find( arg1, UnitName("pet") ) then
                if string.find( arg1, UnitName("player") ) then
                    if string.find( arg1, ".*致命一击.*" ) then
                        MPHunterBaitShotTimer = GetTime()+4
                    end
                end
            end
        end
    ]]

    elseif event == "START_AUTOREPEAT_SPELL" then

        MPHunterAutoShot = 1

    elseif event == "STOP_AUTOREPEAT_SPELL" then

        MPHunterAutoShot = 0

    ---------------------------
    -- SuperWoW事件 -----------
    ---------------------------

    -- 施法、攻击事件处理
    elseif event == "UNIT_CASTEVENT" then

        -- 仅监控自己
        if arg1 == PLAYER_GUID then

            -- 施法事件监测
            if arg3 == "CAST" then

                MPMsg(arg4)

                -- 毒蛇钉刺
                if arg4==1978 or arg4==13549 or arg4==13550 or arg4==13551 or arg4==13552 or arg4==13553 or arg4==13554 or arg4==13555 or arg4==25295 then
                    SerpentDelayTime[arg2] = GetTime()

                -- 蝰蛇钉刺
                elseif arg4==14280 then
                    ViperDelayTime[arg2] = GetTime()

                -- 自动射击
                elseif arg4==75 then
                    MPHunterShotTimer = GetTime()
                    MPHunterShotDuration = UnitRangedDamage("player")

                end

            end
        end

    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then

        -- 自己的攻击
        if arg1 == "CHAT_MSG_SPELL_SELF_DAMAGE" then

            --message(arg2)

            if string.find( arg2, "你的毒蛇钉刺.*招架.*" ) or string.find( arg2, "你的毒蛇钉刺.*躲闪.*" ) or string.find( arg2, "你的毒蛇钉刺.*格挡.*" ) or string.find( arg2, "你的毒蛇钉刺.*没有击中.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and SerpentDelayTime[targetGUID] then 
                    local timer = GetTime() - SerpentDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        SerpentDelayTime[targetGUID] = nil
                    end
                end
            elseif string.find( arg2, "你的蝰蛇钉刺.*招架.*" ) or string.find( arg2, "你的蝰蛇钉刺.*躲闪.*" ) or string.find( arg2, "你的蝰蛇钉刺.*格挡.*" ) or string.find( arg2, "你的蝰蛇钉刺.*没有击中.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and ViperDelayTime[targetGUID] then 
                    local timer = GetTime() - ViperDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        ViperDelayTime[targetGUID] = nil
                    end
                end
            end

        end

    end


end

-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)



-- 获取自动射击剩余时间
-- return 返回下一次自动射击的剩余时间
function MPGetHunterShotLeft()
    local t = GetTime() - MPHunterShotTimer
    local left = MPHunterShotDuration - t;

    if left < 0 then
        return 0
    end

    return left
end

-- 获取自动射击消耗掉的时间
function MPGetHunterShotTime()
    return GetTime() - MPHunterShotTimer
end




-- 获取当前目标是否有毒蛇钉刺
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetSerpentStingDot(unit)

    unit = unit or "target"

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("毒蛇钉刺","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if SerpentDelayTime[guid] then 
        local timer = GetTime() - SerpentDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return MPGetSerpentStingDOTCheck(guid)
        else
            -- 已经过了认证期
            SerpentCheck[guid] = SerpentDelayTime[guid]
            SerpentDelayTime[guid] = nil
        end
    end

    return MPGetSerpentStingDOTCheck(guid)
end

function MPGetSerpentStingDOTCheck( guid )

    if SerpentCheck[guid] then
        local timer = GetTime() - SerpentCheck[guid]
        if timer < 15 then
            return true
        end
    end

    return false
end

function MPGetSerpentStingCheck()
    return SerpentCheck
end





-- 获取当前目标是否有蝰蛇钉刺
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetViperStingDot(unit)

    unit = unit or "target"

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("蝰蛇钉刺","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if ViperDelayTime[guid] then 
        local timer = GetTime() - ViperDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return MPGetViperStingDOTCheck(guid)
        else
            -- 已经过了认证期
            ViperCheck[guid] = ViperDelayTime[guid]
            ViperDelayTime[guid] = nil
        end
    end

    return MPGetViperStingDOTCheck(guid)
end

function MPGetViperStingDOTCheck( guid )

    if ViperCheck[guid] then
        local timer = GetTime() - ViperCheck[guid]
        if timer < 8 then
            return true
        end
    end

    return false
end

function MPGetViperStingCheck()
    return ViperCheck
end


function MPGetHunterGoreAllow()
    if GetTime()-MPHunterGoreTimer<0 then
        return true
    end

    return false
end




-- 猎人特性状态
function MPHunterRefreshInfo()

    -- 瞄准射击 天赋
    MPHunterAimedShot = MPIsTalentLearned(2,6)

    -- 猎捕高手 天赋
    MPHunterAdvantage = MPIsTalentLearned(3,20)

    -- 切碎 天赋
    MPHunterRake = MPIsTalentLearned(3,10)

    -- 割伤 天赋
    MPHunterGore = MPIsTalentLearned(3,17)

    -- 杀戮命令 天赋
    MPHunterKillCommand = MPIsTalentLearned(1,19)

    -- 元素弹药
    MPHunterElement = MPIsTalentLearned(2,11)

end

