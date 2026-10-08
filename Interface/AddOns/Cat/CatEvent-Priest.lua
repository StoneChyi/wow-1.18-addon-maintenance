local _, playerClass = UnitClass("player")
if playerClass ~= "PRIEST" then
    return  -- 终止文件执行
end


-- 创建一个 Frame 并监听事件
local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("SPELLCAST_START")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_FAILED")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_DEAD")

frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
frame:RegisterEvent("SPELLCAST_CHANNEL_START")
frame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")


-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")



-- 自己的GUID
local PLAYER_GUID = 0

-- 真言术：痛事件管理
local PainCheck = {}
local PainDelayTime = {}

-- 吸血鬼的拥抱事件管理
local VampiricCheck = {}
local VampiricDelayTime = {}

-- 神圣之火事件管理
local HolyFireCheck = {}
local HolyFireDelayTime = {}


-- 等待技能反馈的等待时间
local BLEENCHECKDELAY = 0.3

-- 引导法术持续状态
local ChanneledDuration = 0
local ChanneledTimer = 0

-- 鞭笞 阶段
local MindFlayCount = 0

-- 祈祷之书
MPPriestPrayerBookCount = 0

local function OnEvent()

    -- 初始化
    if event == "PLAYER_LOGIN" then
        if SUPERWOW_STRING then
            -- 获取并保存自己的GUID
            local a,guid = UnitExists("player")
            PLAYER_GUID = guid
        end

    -- 离开战斗事件，重置参数
    elseif event == "PLAYER_REGEN_ENABLED" then
        ChanneledDuration = 0
        ChanneledTimer = 0
        MindFlayCount = 0
        MPPriestMindBlastReset = 0

    -- 进入游戏世界刷新常量值
    elseif event == "PLAYER_ENTERING_WORLD" then
        PainCheck = {}
        PainDelayTime = {}
        VampiricCheck = {}
        VampiricDelayTime = {}
        ChanneledDuration = 0
        ChanneledTimer = 0
        MindFlayCount = 0
        MPPriestMindBlastReset = 0

    -- 玩家死亡，重置参数
    elseif event == "PLAYER_DEAD" then
        PainCheck = {}
        PainDelayTime = {}
        VampiricCheck = {}
        VampiricDelayTime = {}
        ChanneledDuration = 0
        ChanneledTimer = 0
        MindFlayCount = 0
        MPPriestMindBlastReset = 0

    -- 施法事件处理，读条类，读条也要处理GCD
    elseif event == "SPELLCAST_START" then

        -- 牧师治疗读条处理
        if arg1 == "强效治疗术" then
            MPPriestCastHeal=GetTime() 
        elseif arg1 == "快速治疗" then
            MPPriestCastHeal=GetTime() 
        elseif arg1 == "神圣之火" then
            MPCastHolyFireTimer=GetTime()+(arg2/1000)+0.3
        end

    elseif event == "SPELLCAST_STOP" then

        MPPriestCastHeal = 0

    elseif event == "SPELLCAST_FAILED" then

        MPPriestCastHeal = 0

    elseif event == "SPELLCAST_INTERRUPTED" then

        MPPriestCastHeal = 0

        MPCastHolyFireTimer = -1

    elseif event == "SPELLCAST_CHANNEL_START" then
        ChanneledDuration = arg1
        ChanneledTimer = GetTime()
        MindFlayCount = 0

    elseif event == "SPELLCAST_CHANNEL_UPDATE" then
        ChanneledDuration = arg1

    elseif event == "SPELLCAST_CHANNEL_STOP" then
        ChanneledDuration = 0
        ChanneledTimer = 0
        MindFlayCount = 0

    elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
        --print(arg1)

        if string.find(arg1, "你的精神鞭笞使.*") then
            MindFlayCount = MindFlayCount + 1
        end

    ---------------------------
    -- SuperWoW事件 -----------
    ---------------------------

    -- 施法、攻击事件处理
    elseif event == "UNIT_CASTEVENT" then

        if arg3 == "CAST" then
            -- 仅监控自己放出的技能
            if arg1 == PLAYER_GUID then

                --MPMsg(arg4)
                

                -- 暗言术：痛
                if arg4==589 or arg4==594 or arg4==970 or arg4==992 or arg4==2767 or arg4==10892 or arg4==10893 or arg4==10894 then
                    PainDelayTime[arg2] = GetTime()

                -- 吸血鬼的拥抱
                elseif arg4==15286 then
                    VampiricDelayTime[arg2] = GetTime()

                -- 神圣之火
                elseif arg4==14914 or arg4==15262 or arg4==15263 or arg4==15264 or arg4==15265 or arg4==15266 or arg4==15267 or arg4==15261 then
                    HolyFireDelayTime[arg2] = GetTime()

                -- 恢复
                elseif arg4==139 or arg4==6074 or arg4==6075 or arg4==6076 or arg4==6077 or arg4==6078 or arg4==10927 or arg4==10928 or arg4==10929 or arg4==25315 then
                    MPPriestPrayerBookCount = 1

                -- 快速治疗
                elseif arg4==2061 or arg4==9472 or arg4==9473 or arg4==9474 or arg4==10915 or arg4==10916 or arg4==10917 then
                    MPPriestPrayerBookCount = 2

                -- 强效治疗术
                elseif arg4==2060 or arg4==10963 or arg4==10964 or arg4==10965 or arg4==25314 then
                    MPPriestPrayerBookCount = 3

                -- 治疗祷言
                elseif arg4==596 or arg4==996 or arg4==10960 or arg4==10961 or arg4==25316 then
                    MPPriestPrayerBookCount = 4

                end

            end
        end

    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then
        --[[
        if string.find(arg2, ".*鞭笞.*") then
        message(arg1)
        message(arg2)
        end
        ]]

        -- 自己的攻击
        if arg1 == "CHAT_MSG_SPELL_SELF_DAMAGE" then

            --message(arg2)

            -- 暗言术：痛
            if string.find( arg2, "你的暗言术：痛被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and PainDelayTime[targetGUID] then 
                    local timer = GetTime() - PainDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        PainDelayTime[targetGUID] = nil
                    end
                end
            end

            -- 吸血鬼的拥抱
            if string.find( arg2, "你的吸血鬼的拥抱被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and VampiricDelayTime[targetGUID] then 
                    local timer = GetTime() - VampiricDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        VampiricDelayTime[targetGUID] = nil
                    end
                end
            end

            -- 神圣之火
            if string.find( arg2, "你的神圣之火被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and HolyFireDelayTime[targetGUID] then 
                    local timer = GetTime() - HolyFireDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        HolyFireDelayTime[targetGUID] = nil
                    end
                end
            end

        end
    end

end

-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)




-- 获取当前目标是否有暗言术：痛
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetPainDot(unit)

    unit = unit or "target"

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("暗言术：痛",unit)
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if PainDelayTime[guid] then 
        local timer = GetTime() - PainDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return true
        else
            -- 已经过了认证期
            PainCheck[guid] = PainDelayTime[guid]
            PainDelayTime[guid] = nil
        end
    end

    return MPGetPainDOTCheck(guid)
end

function MPGetPainDOTCheck( guid )

    if PainCheck[guid] then
        local timer = GetTime() - PainCheck[guid]
        if timer < MPPainDuration then
            return true
        end
    end

    return false
end

function MPGetPainCheck()
    return PainCheck
end



-- 获取当前目标是否有吸血鬼的拥抱
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetVampiricDot(unit)

    unit = unit or "target"

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("吸血鬼的拥抱",unit)
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if VampiricDelayTime[guid] then 
        local timer = GetTime() - VampiricDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return true
        else
            -- 已经过了认证期
            VampiricCheck[guid] = VampiricDelayTime[guid]
            VampiricDelayTime[guid] = nil
        end
    end

    return MPGetVampiricDOTCheck(guid)
end

function MPGetVampiricDOTCheck( guid )

    if VampiricCheck[guid] then
        local timer = GetTime() - VampiricCheck[guid]
        if timer < 60 then
            return true
        end
    end

    return false
end

function MPGetVampiricCheck()
    return VampiricCheck
end



-- 获取当前目标是否有神圣之火
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetHolyFireDot(unit)

    unit = unit or "target"

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("神圣之火",unit)
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists(unit)
    if not guid then
        return false
    end

    if HolyFireDelayTime[guid] then 
        local timer = GetTime() - HolyFireDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return true
        else
            -- 已经过了认证期
            HolyFireCheck[guid] = HolyFireDelayTime[guid]
            HolyFireDelayTime[guid] = nil
        end
    end

    return MPGetHolyFireDOTCheck(guid)
end

function MPGetHolyFireDOTCheck( guid )

    if HolyFireCheck[guid] then
        local timer = GetTime() - HolyFireCheck[guid]
        if timer < 10 then
            return true
        end
    end

    return false
end

function MPGetHolyFireCheck( guid )

    if not guid then
        return HolyFireCheck
    end

    if HolyFireDelayTime[guid] then 
        local timer = GetTime() - HolyFireDelayTime[guid]
        -- 0.2秒监测期里
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return 9.9
        end

    else
        -- 已经过了认证期
        if HolyFireCheck[guid] then
            return 10-(GetTime()-HolyFireCheck[guid])
        else
            return 0
        end
    end

    return 0
end










-- 获取引导时间
function MPGetPriestChanneledDuration()
    return ChanneledDuration
end

-- 获取引导持续剩余时间
function MPGetPriestChanneled()

    -- 安全边界检查
    if ChanneledDuration and ChanneledDuration==0 then
        return 0
    end

    local timer = GetTime()-ChanneledTimer

    if timer > ChanneledDuration then
        return 0
    end


    return ChanneledDuration/1000 - timer
end

-- 获取鞭笞阶段
function MPGetPriestMindFlayCount()
    return MindFlayCount
end





-- 牧师特性状态
function MPPriestRefreshInfo()

    local MentalAgility = 1 - (MPIsTalentLearned(1, 3) * 0.05)

    local EffectPercent = 1 + (MPIsTalentLearned(2,1)*0.05) + (MPIsTalentLearned(2,15)*0.06)

    local GreaterHeal = 1 - (MPIsTalentLearned(2,11)*0.05)

    -- 恢复属性
    MPPriestRenewMana[1] = 26 * MentalAgility
    MPPriestRenewEffect[1] = (45+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[2] = 57 * MentalAgility
    MPPriestRenewEffect[2] = (100+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[3] = 92 * MentalAgility
    MPPriestRenewEffect[3] = (175+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[4] = 123 * MentalAgility
    MPPriestRenewEffect[4] = (245+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[5] = 149 * MentalAgility
    MPPriestRenewEffect[5] = (270+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[6] = 180 * MentalAgility
    MPPriestRenewEffect[6] = (340+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[7] = 220 * MentalAgility
    MPPriestRenewEffect[7] = (435+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[8] = 268 * MentalAgility
    MPPriestRenewEffect[8] = (555+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[9] = 321 * MentalAgility
    MPPriestRenewEffect[9] = (690+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent
    MPPriestRenewMana[10] = 360 * MentalAgility
    MPPriestRenewEffect[10] = (825+(MPHealingPower*MPPriestRenewFactor)) * EffectPercent

    MPPriestRenewManaMaxLevel = MPGetHighestRankOfSpell("恢复")

    -- 强效治疗术
    MPPriestGreaterHealMana[1] = 370 * GreaterHeal
    MPPriestGreaterHealEffect[1] = (840+(MPHealingPower*MPPriestGreaterHealFactor)) * EffectPercent
    MPPriestGreaterHealMana[2] = 455 * GreaterHeal
    MPPriestGreaterHealEffect[2] = (1070+(MPHealingPower*MPPriestGreaterHealFactor)) * EffectPercent
    MPPriestGreaterHealMana[3] = 545 * GreaterHeal
    MPPriestGreaterHealEffect[3] = (1320+(MPHealingPower*MPPriestGreaterHealFactor)) * EffectPercent
    MPPriestGreaterHealMana[4] = 655 * GreaterHeal
    MPPriestGreaterHealEffect[4] = (1640+(MPHealingPower*MPPriestGreaterHealFactor)) * EffectPercent
    MPPriestGreaterHealMana[5] = 710 * GreaterHeal
    MPPriestGreaterHealEffect[5] = (1700+(MPHealingPower*MPPriestGreaterHealFactor)) * EffectPercent

    MPPriestGreaterHealManaMaxLevel = MPGetHighestRankOfSpell("强效治疗术")

    -- 快速治疗
    MPPriestFlashHealMana[1] = 125
    MPPriestFlashHealEffect[1] = (220+(MPHealingPower*MPPriestFlashHealFactor)) * EffectPercent
    MPPriestFlashHealMana[2] = 155
    MPPriestFlashHealEffect[2] = (290+(MPHealingPower*MPPriestFlashHealFactor)) * EffectPercent
    MPPriestFlashHealMana[3] = 185
    MPPriestFlashHealEffect[3] = (320+(MPHealingPower*MPPriestFlashHealFactor)) * EffectPercent
    MPPriestFlashHealMana[4] = 215
    MPPriestFlashHealEffect[4] = (390+(MPHealingPower*MPPriestFlashHealFactor)) * EffectPercent
    MPPriestFlashHealMana[5] = 265
    MPPriestFlashHealEffect[5] = (500+(MPHealingPower*MPPriestFlashHealFactor)) * EffectPercent
    MPPriestFlashHealMana[6] = 315
    MPPriestFlashHealEffect[6] = (610+(MPHealingPower*MPPriestFlashHealFactor)) * EffectPercent
    MPPriestFlashHealMana[7] = 380
    MPPriestFlashHealEffect[7] = (770+(MPHealingPower*MPPriestFlashHealFactor)) * EffectPercent

    MPPriestFlashHealManaMaxLevel = MPGetHighestRankOfSpell("快速治疗")


    -- 暗言术：痛
    MPPainDuration = 18 + MPIsTalentLearned(3,4)*3
    if MPCheckInventoryItemName(13,"休眠腐化之眼") then MPPainDuration=MPPainDuration+3 end
    if MPCheckInventoryItemName(14,"休眠腐化之眼") then MPPainDuration=MPPainDuration+3 end

    -- 暗影形态 天赋
    MPPriestShadowform = MPIsTalentLearned(3,17)

    -- 吸血鬼的拥抱 天赋
    MPPriestVampiric = MPIsTalentLearned(3,14)

    -- 精神鞭笞 天赋
    MPPriestMindFlay = MPIsTalentLearned(3,9)

    -- 责罚 天赋
    MPPriestChastise = MPIsTalentLearned(1,18)

    -- 检测T3.5三件套
	local count = 0
	if MPCheckInventoryItemName(1,"疫医头冠") then count=count+1 end
	if MPCheckInventoryItemName(3,"疫医肩垫") then count=count+1 end
	if MPCheckInventoryItemName(5,"疫医外套") then count=count+1 end
	if MPCheckInventoryItemName(7,"疫医长裤") then count=count+1 end
	if MPCheckInventoryItemName(8,"疫医便鞋") then count=count+1 end
	if MPCheckInventoryItemName(2,"疫医坠饰") then count=count+1 end

    if count>2 then
        MPPriest3Fade = 1
    end

end

