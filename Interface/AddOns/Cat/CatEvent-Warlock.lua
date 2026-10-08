local _, playerClass = UnitClass("player")
if playerClass ~= "WARLOCK" then
    return  -- 终止文件执行
end


-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化

-- 暗影收割
MPWarlockShadowHarvest = 0
MPWarlockShadowBeginTimer = 0

-- 献祭
MPImmolateTimer = 0

-- 灵魂之火 蓝量
MPWarlockSoulFireMana = {}

-- 燃烧 蓝量
MPWarlockConflagrate = 0
MPWarlockConflagrateMana = {}

-- 灼热之痛 蓝量
MPWarlockSearingPainMana = {}

-- 无情延伸 天赋
MPWarlockRuthlessExtend = 0

-- 毁灭延伸 天赋
MPWarlockDestructionExtend = 0

-- 生命虹吸
MPWarlockSiphonLife = 0

-- 暗影灼烧
MPWarlockShadowburn = 0

-- 邪咒
MPWarlockCurseEvil = 0

-- 超越之力
MPWarlockOverpowering = 0

-- 暗影灼烧、痛苦诅咒、腐蚀术、生命虹吸、暗影箭 蓝量
MPWarlockShadowburnMana = {}
MPCurseAgonyMana = {}
MPWarlockCorruptionMana = {}
MPWarlockImmolateMana = {}
MPWarlockSiphonLifeMana = {}
MPWarlockShadowBoltMana = {}

-- 痛苦诅咒持续时间
MPCurseAgonyDuration = 24
MPCurseAgonyRange = 30

-- 腐蚀术持续时间
MPWarlockCorruptionDuration = 18
MPWarlockCorruptionRange = 30

-- 生命虹吸持续时间
MPWarlockSiphonLifeDuration = 30
MPWarlockSiphonLifeRange = 30

-- 献祭持续时间
MPWarlockImmolateDuration = 15
MPWarlockImmolateRange = 30

-- 鲁莽诅咒持续时间
MPWarlockCurseRecklessnessDuration = 120
-- 元素诅咒持续时间
MPWarlockCurseElementsDuration = 300
-- 暗影诅咒持续时间
MPWarlockCurseShadowDuration = 300
-- 语言诅咒持续时间
MPWarlockCurseTonguesDuration = 300

-- -------------------------------------


local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
frame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")

frame:RegisterEvent("SPELLCAST_START")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_CHANNEL_START")
frame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")

-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")

-- Nampower专有事件
frame:RegisterEvent("SPELL_CHANNEL_START")



-- 自己的GUID
local PLAYER_GUID = 0

-- 痛苦诅咒事件管理
local CurseAgonyCheck = {}
local CurseAgonyDelayTime = {}

-- 腐蚀术事件管理
local CorruptionCheck = {}
local CorruptionDelayTime = {}

-- 生命虹吸事件管理
local SiphonLifeCheck = {}
local SiphonLifeDelayTime = {}

-- 献祭事件管理
local ImmolateCheck = {}
local ImmolateDelayTime = {}

-- 等待技能反馈的等待时间
local BLEENCHECKDELAY = 0.3


-- 引导法术持续状态
local ChanneledDuration = 0
local ChanneledSpellID = 0
local ChanneledTimer = 0


-- 施放潜力
local PotentialTimer = 0
local PotentialLayer = 0

-- 生命通道，特例处理，由于生命通道没有具体消息，故需要特例进行计算
local LifeChannel = false
local LifeChannelTimer = 0

local ManaChannel = false



local function ResetData()
    CurseAgonyCheck = {}
    CurseAgonyDelayTime = {}

    CorruptionCheck = {}
    CorruptionDelayTime = {}

    SiphonLifeCheck = {}
    SiphonLifeDelayTime = {}

    ImmolateCheck = {}
    ImmolateDelayTime = {}

    ChanneledDuration = 0
    ChanneledTimer = 0

    PotentialTimer = 0
    PotentialLayer = 0

    LifeChannel = false
    LifeChannelTimer = 0
    ManaChannel = false
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

    elseif event == "SPELLCAST_CHANNEL_START" then
        ChanneledDuration = arg1
        if not MP_SuperWoW then
            ChanneledTimer = GetTime()
        end

    elseif event == "SPELLCAST_CHANNEL_UPDATE" then
        ChanneledDuration = arg1

    elseif event == "SPELLCAST_CHANNEL_STOP" then
        ChanneledDuration = 0
        ChanneledTimer = 0
        ChanneledSpellID = 0


    -- 施法事件处理，读条类
    elseif event == "SPELLCAST_START" then

        if arg1 == "献祭" then MPImmolateTimer=GetTime() end
        --if arg1 == "暗影箭" then 
        --    MPShadowTwilightTimer = GetTime()
        --end

    elseif event == "SPELLCAST_STOP" then


    -- buff获得
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then

        if string.find( arg1, "获得了释放潜力的效果" ) then
            if string.find( arg1, UnitName("player") ) then
                PotentialTimer = GetTime()
                local number = MPExtractNumber(arg1) 
                if number then
                    PotentialLayer = MPToNumber(number)
                    if PotentialLayer==0 then
                        PotentialLayer=1
                    end
                else
                    PotentialLayer = 1
                end
            end

        elseif string.find( arg1, "从法力通道获得" ) then
            if string.find( arg1, UnitName("player") ) then
                ManaChannel = true
                if MPGetPotential() and PotentialLayer>0 then
                    PotentialTimer = GetTime()
                end
            end

        elseif string.find( arg1, "获得了生命通道的效果" ) then
            if string.find( arg1, UnitName("player") ) then
                LifeChannel = true
                LifeChannelTimer = GetTime()
            end
        end

    -- buff 消失
    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then

        if string.find( arg1, "生命通道效果从" ) then
            if string.find( arg1, UnitName("player") ) then
                LifeChannel = false
            end
        elseif string.find( arg1, "法力通道效果从" ) then
            if string.find( arg1, UnitName("player") ) then
                ManaChannel = false
            end
        end

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then

        if string.find( arg1, ".*致命一击.*" ) then
            if MPGetPotential() and PotentialLayer>0 then
                PotentialTimer = GetTime()
            end
        end

    ---------------------------
    -- SuperWoW事件 -----------
    ---------------------------

    -- 施法、攻击事件处理
    elseif event == "UNIT_CASTEVENT" then

        if arg3 == "CHANNEL" then

            if arg1 == PLAYER_GUID then
            
                MPMsg(arg4)

                ChanneledTimer = GetTime()
                ChanneledSpellID = arg4

                if not MP_Nampower4 then
                    if arg4==52550 or arg4==52551 or arg4==52552 then

                        MPMsg("施放 [暗影收割]，持续时间"..string.format("%.2f",arg5/1000).."重新计算DOT持续时间")

                        -- 痛苦诅咒
                        if MPGetCurseAgonyDot() then
                            if CurseAgonyCheck[arg2] then
                                CurseAgonyCheck[arg2] = CurseAgonyCheck[arg2] - (arg5/2000) + 0.6
                            end
                        end

                        -- 腐蚀术
                        if MPGetCorruptionDot() then
                            if CorruptionCheck[arg2] then
                                CorruptionCheck[arg2] = CorruptionCheck[arg2] - (arg5/2000) + 0.6
                            end
                        end

                        -- 生命虹吸
                        if MPGetSiphonLifeDot() then
                            if SiphonLifeCheck[arg2] then
                                SiphonLifeCheck[arg2] = SiphonLifeCheck[arg2] - (arg5/2000) + 0.6
                            end
                        end
                    end
                end

            end

        -- 施法事件监测
        elseif arg3 == "CAST" then

            -- 仅监控自己放出的技能
            if arg1 == PLAYER_GUID then

                --MPMsg(arg4)

                -- 痛苦诅咒
                if arg4==980 or arg4==1014 or arg4==6217 or arg4==11711 or arg4==11712 or arg4 == 11713 then
                    -- 计算应该持续时间
                    CurseAgonyDelayTime[arg2] = GetTime()

                -- 腐蚀术
                elseif arg4==172 or arg4==6222 or arg4==6223 or arg4==7648 or arg4==11671 or arg4==11672 or arg4==25311 then
                    CorruptionDelayTime[arg2] = GetTime()

                -- 生命虹吸
                elseif arg4==18265 or arg4==18879 or arg4==18880 or arg4==18881 then
                    SiphonLifeDelayTime[arg2] = GetTime()

                -- 献祭
                elseif arg4==348 or arg4==707 or arg4==1094 or arg4==2941 or arg4==11665 or arg4==11667 or arg4==11668 or arg4==25309 then
                    --MPMsg("献祭 目标="..arg2)
                    ImmolateDelayTime[arg2] = GetTime()

                -- 燃烧
                elseif arg4==17962 or arg4==18930 or arg4==18931 or arg4==18932 then
                    if ImmolateDelayTime[arg2] then 
                        local timer = GetTime() - ImmolateDelayTime[arg2]
                        -- 0.2秒监测期里
                        if timer <= BLEENCHECKDELAY then
                            ImmolateDelayTime[arg2] = ImmolateDelayTime[arg2] - 3.0
                        end
                    else
                        if ImmolateCheck[arg2] then
                            ImmolateCheck[arg2] = ImmolateCheck[arg2] - 3.0
                        end
                    end

                -- 顺发 暗影箭
                elseif arg4==686 or arg4==11660 or arg4==11661 or arg4==25307 then
                    MPShadowTwilightTimer = GetTime()

                end
            end

        end

    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then

        -- 自己的攻击
        if arg1 == "CHAT_MSG_SPELL_SELF_DAMAGE" then

            --message(arg2)

            -- 痛苦诅咒
            if string.find( arg2, "你的痛苦诅咒被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and CurseAgonyDelayTime[targetGUID] then 
                    local timer = GetTime() - CurseAgonyDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        CurseAgonyDelayTime[targetGUID] = nil
                    end
                end
            elseif string.find( arg2, "你的腐蚀术被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and CorruptionDelayTime[targetGUID] then 
                    local timer = GetTime() - CorruptionDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        CorruptionDelayTime[targetGUID] = nil
                    end
                end
            elseif string.find( arg2, "你的生命虹吸被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and SiphonLifeDelayTime[targetGUID] then 
                    local timer = GetTime() - SiphonLifeDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        SiphonLifeDelayTime[targetGUID] = nil
                    end
                end
            elseif string.find( arg2, "你的献祭被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and ImmolateDelayTime[targetGUID] then 
                    local timer = GetTime() - ImmolateDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        ImmolateDelayTime[targetGUID] = nil
                    end
                end
            end

        end

    -- Nampower专有事件

    elseif event == "SPELL_CHANNEL_START" then

        if arg1==52550 or arg1==52551 or arg1==52552 then
            MPMsg("施放 [暗影收割]，持续时间"..string.format("%.2f",arg3/1000).."重新计算DOT持续时间")

            -- 痛苦诅咒
            if MPGetCurseAgonyDot() then
                if CurseAgonyCheck[arg2] then
                    CurseAgonyCheck[arg2] = CurseAgonyCheck[arg2] - (arg3/2000) + 0.4
                end
            end

            -- 腐蚀术
            if MPGetCorruptionDot() then
                if CorruptionCheck[arg2] then
                    CorruptionCheck[arg2] = CorruptionCheck[arg2] - (arg3/2000) + 0.4
                end
            end

            -- 生命虹吸
            if MPGetSiphonLifeDot() then
                if SiphonLifeCheck[arg2] then
                    SiphonLifeCheck[arg2] = SiphonLifeCheck[arg2] - (arg3/2000) + 0.4
                end
            end

        end

    end


end


local function OnUpdate()

    -- 特例计算生命通道
    if LifeChannel then
        if GetTime()-LifeChannelTimer >= 1 then
            LifeChannelTimer = GetTime()
            if MPGetPotential() and PotentialLayer>0 then
                PotentialTimer = GetTime()
            end
        end
    end

end


-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)
frame:SetScript("OnUpdate", OnUpdate)





-- 获取当前目标是否有痛苦诅咒
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetCurseAgonyDot(unit, value)

    unit = unit or "target"
    value = value or 0

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("痛苦诅咒","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if CurseAgonyDelayTime[guid] then 
        local timer = GetTime() - CurseAgonyDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return true
        else
            -- 已经过了认证期
            CurseAgonyCheck[guid] = CurseAgonyDelayTime[guid]
            CurseAgonyDelayTime[guid] = nil
        end
    end

    return MPGetCurseAgonyDOTCheck(guid, value)
end

function MPGetCurseAgonyDOTCheck( guid, value )

    if CurseAgonyCheck[guid] then
        local timer = GetTime() - CurseAgonyCheck[guid]
        if timer < (MPCurseAgonyDuration-value) then
            return true
        end
    end

    return false
end

function MPGetCurseAgonyCheck()
    return CurseAgonyCheck
end


-- 获取当前目标是否有腐蚀术
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetCorruptionDot(unit, value)

    unit = unit or "target"
    value = value or 0

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("腐蚀术","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if CorruptionDelayTime[guid] then 
        local timer = GetTime() - CorruptionDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return true
        else
            -- 已经过了认证期
            CorruptionCheck[guid] = CorruptionDelayTime[guid]
            CorruptionDelayTime[guid] = nil
        end
    end

    return MPGetCorruptionDOTCheck(guid, value)
end

function MPGetCorruptionDOTCheck( guid, value )

    if CorruptionCheck[guid] then
        local timer = GetTime() - CorruptionCheck[guid]
        if timer < (MPWarlockCorruptionDuration-value) then
            return true
        end
    end

    return false
end

function MPGetCorruptionCheck()
    return CorruptionCheck
end



-- 获取当前目标是否有生命虹吸
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetSiphonLifeDot(unit, value)

    unit = unit or "target"
    value = value or 0

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("生命虹吸","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if SiphonLifeDelayTime[guid] then 
        local timer = GetTime() - SiphonLifeDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return true
        else
            -- 已经过了认证期
            SiphonLifeCheck[guid] = SiphonLifeDelayTime[guid]
            SiphonLifeDelayTime[guid] = nil
        end
    end

    return MPGetSiphonLifeDOTCheck(guid, value)
end

function MPGetSiphonLifeDOTCheck( guid, value )

    if SiphonLifeCheck[guid] then
        local timer = GetTime() - SiphonLifeCheck[guid]
        if timer < (MPWarlockSiphonLifeDuration-value) then
            return true
        end
    end

    return false
end

function MPGetSiphonLifeCheck()
    return SiphonLifeCheck
end






-- 获取当前目标是否有献祭
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetImmolateDot(unit, value)

    unit = unit or "target"
    value = value or 0

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("献祭","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if ImmolateDelayTime[guid] then 
        local timer = GetTime() - ImmolateDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期

            --[[ 读条dot类专属处理
            local has = MPGetImmolateDOTCheck(guid)
            if not has then
            end
            ]]
            return true
        else
            -- 已经过了认证期
            ImmolateCheck[guid] = ImmolateDelayTime[guid]
            ImmolateDelayTime[guid] = nil
        end
    end

    return MPGetImmolateDOTCheck(guid, value)
end

function MPGetImmolateDOTCheck( guid, value )

    if ImmolateCheck[guid] then
        local timer = GetTime() - ImmolateCheck[guid]
        if timer < (MPWarlockImmolateDuration-value) then
            return true
        end
    end

    return false
end

function MPGetImmolateCheck()
    return ImmolateCheck
end


-- 获取引导时间
function MPGetWarlockChanneledDuration()
    return ChanneledDuration
end

-- 获取引导持续剩余时间
function MPGetWarlockChanneled()
    local timer = GetTime()-ChanneledTimer

    if timer > ChanneledDuration then
        return 0
    end

    return ChanneledDuration/1000 - timer
end

-- 获取当前读条技能id
function MPGetWarlockChanneledSpellID()
    return ChanneledSpellID
end

-- 获取施放潜力
function MPGetPotential()
    if GetTime()-PotentialTimer<20 then
        return true
    end

    return false
end

function MPGetPotentialTimer()
    return PotentialTimer
end
function MPGetPotentialLayer()
    return PotentialLayer
end

function MPGetManaChannel()
    return ManaChannel
end

function MPGetLifeChannel()
    return LifeChannel
end




-- 术士特性状态
function MPWarlockRefreshInfo()

    -- 检查生命虹吸天赋
    MPWarlockSiphonLife = MPIsTalentLearned(1,14)

    -- 检查暗影灼烧天赋
    MPWarlockShadowburn = MPIsTalentLearned(3,7)

    -- 检查超越之力天赋
    MPWarlockOverpowering = MPIsTalentLearned(2,14)

    --[[
    -- 计算持续时间
    local dec = 0
    if MPIsTalentLearned(1,14) == 0 then

        -- 痛苦诅咒持续时间
        MPCurseAgonyDuration = 24
        -- 腐蚀术持续时间
        MPWarlockCorruptionDuration = 18
        -- 生命虹吸持续时间
        MPWarlockSiphonLifeDuration = 30

    elseif MPIsTalentLearned(1,14) == 1 then

        dec = 1 - ((0.06 - (MPHasteRating/100))/2)
        -- 痛苦诅咒持续时间
        MPCurseAgonyDuration = 24 * dec
        -- 腐蚀术持续时间
        MPWarlockCorruptionDuration = 18 * dec
        -- 生命虹吸持续时间
        MPWarlockSiphonLifeDuration = 30 * dec

    elseif MPIsTalentLearned(1,14) == 2 then

        dec = 1 - (0.06 + (MPHasteRating/100))
        -- 痛苦诅咒持续时间
        MPCurseAgonyDuration = 24 * dec
        -- 腐蚀术持续时间
        MPWarlockCorruptionDuration = 18 * dec
        -- 生命虹吸持续时间
        MPWarlockSiphonLifeDuration = 30 * dec

    end

    -- 腐蚀术持续时间 
    if MPCheckInventoryItemName(13,"休眠腐化之眼") then MPWarlockCorruptionDuration=MPWarlockCorruptionDuration+3 end
    if MPCheckInventoryItemName(14,"休眠腐化之眼") then MPWarlockCorruptionDuration=MPWarlockCorruptionDuration+3 end
    ]]

    -- 痛苦诅咒持续时间
    MPCurseAgonyDuration = tonumber(MPMatch(MPGetSpellTooltip("痛苦诅咒","等级 5"), "使其在(%d+%.%d+)"))
    if not MPCurseAgonyDuration then MPCurseAgonyDuration=24 end
    -- 腐蚀术持续时间
    MPWarlockCorruptionDuration = tonumber(MPMatch(MPGetSpellTooltip("腐蚀术","等级 5"), "腐蚀目标，在(%d+%.%d+)"))
    if not MPWarlockCorruptionDuration then MPWarlockCorruptionDuration=18 end
    -- 生命虹吸持续时间
    MPWarlockSiphonLifeDuration = tonumber(MPMatch(MPGetSpellTooltip("生命虹吸","等级 1"), "在(%d+%.%d+)"))
    if not MPWarlockSiphonLifeDuration then MPWarlockSiphonLifeDuration=30 end


    -- 无情延伸
    MPWarlockRuthlessExtend = 0
    if MPIsTalentLearned(1,10)==1 then
        MPWarlockRuthlessExtend = 3
    elseif MPIsTalentLearned(1,10)==2 then
        MPWarlockRuthlessExtend = 6
    end
    MPWarlockCorruptionRange = 30 + MPWarlockRuthlessExtend
    MPCurseAgonyRange = 30 + MPWarlockRuthlessExtend
    MPWarlockSiphonLifeRange = 30 + MPWarlockRuthlessExtend

    -- 毁灭延伸
    MPWarlockDestructionExtend = 0
    if MPIsTalentLearned(3,10)==1 then
        MPWarlockDestructionExtend = 3
    elseif MPIsTalentLearned(3,10)==2 then
        MPWarlockDestructionExtend = 6
    end
    MPWarlockImmolateRange = 30 + MPWarlockDestructionExtend

    -- 邪咒
    MPWarlockCurseEvil = MPIsTalentLearned(1,16)

    local manadec = 1-MPIsTalentLearned(3, 2)*0.02

    MPCurseAgonyMana[1] = 25
    MPCurseAgonyMana[2] = 50
    MPCurseAgonyMana[3] = 90
    MPCurseAgonyMana[4] = 130
    MPCurseAgonyMana[5] = 170
    MPCurseAgonyMana[6] = 215

    MPWarlockCorruptionMana[1] = 35
    MPWarlockCorruptionMana[2] = 55
    MPWarlockCorruptionMana[3] = 100
    MPWarlockCorruptionMana[4] = 160
    MPWarlockCorruptionMana[5] = 225
    MPWarlockCorruptionMana[6] = 290
    MPWarlockCorruptionMana[7] = 340

    MPWarlockImmolateMana[1] = 25
    MPWarlockImmolateMana[2] = 45
    MPWarlockImmolateMana[3] = 90
    MPWarlockImmolateMana[4] = 155
    MPWarlockImmolateMana[5] = 220
    MPWarlockImmolateMana[6] = 295
    MPWarlockImmolateMana[7] = 370
    MPWarlockImmolateMana[8] = 380

    MPWarlockSiphonLifeMana[1] = 150
    MPWarlockSiphonLifeMana[2] = 205
    MPWarlockSiphonLifeMana[3] = 285
    MPWarlockSiphonLifeMana[4] = 365

    MPWarlockShadowBoltMana[1] = 25 * manadec
    MPWarlockShadowBoltMana[2] = 40 * manadec
    MPWarlockShadowBoltMana[3] = 70 * manadec
    MPWarlockShadowBoltMana[4] = 110 * manadec
    MPWarlockShadowBoltMana[5] = 160 * manadec
    MPWarlockShadowBoltMana[6] = 210 * manadec
    MPWarlockShadowBoltMana[7] = 265 * manadec
    MPWarlockShadowBoltMana[8] = 315 * manadec
    MPWarlockShadowBoltMana[9] = 370 * manadec
    MPWarlockShadowBoltMana[10] = 380 * manadec

    MPWarlockShadowburnMana[1] = 105 * manadec
    MPWarlockShadowburnMana[2] = 130 * manadec
    MPWarlockShadowburnMana[3] = 190 * manadec
    MPWarlockShadowburnMana[4] = 245 * manadec
    MPWarlockShadowburnMana[5] = 305 * manadec
    MPWarlockShadowburnMana[6] = 365 * manadec

    MPWarlockSoulFireMana[1] = 175 * manadec
    MPWarlockSoulFireMana[2] = 260 * manadec
    MPWarlockSoulFireMana[3] = 305 * manadec
    MPWarlockSoulFireMana[4] = 335 * manadec

    MPWarlockConflagrateMana[1] = 148
    MPWarlockConflagrateMana[2] = 180
    MPWarlockConflagrateMana[3] = 207
    MPWarlockConflagrateMana[4] = 229

    MPWarlockSearingPainMana[1] = 45 * manadec
    MPWarlockSearingPainMana[2] = 68 * manadec
    MPWarlockSearingPainMana[3] = 91 * manadec
    MPWarlockSearingPainMana[4] = 118 * manadec
    MPWarlockSearingPainMana[5] = 141 * manadec
    MPWarlockSearingPainMana[6] = 168 * manadec

    -- 暗影收割 天赋
    MPWarlockShadowHarvest = MPIsTalentLearned(1,18)

    -- 燃烧 天赋
    MPWarlockConflagrate = MPIsTalentLearned(3,16)

end

