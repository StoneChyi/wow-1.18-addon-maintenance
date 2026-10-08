local _, playerClass = UnitClass("player")
if playerClass ~= "MAGE" then
    return  -- 终止文件执行
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")

frame:RegisterEvent("SPELLCAST_CHANNEL_START")
frame:RegisterEvent("SPELLCAST_CHANNEL_UPDATE")
frame:RegisterEvent("SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("SPELLCAST_DELAYED")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_START")
frame:RegisterEvent("SPELLS_CHANGED")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
frame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")


-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")

-- 自己的GUID
local PLAYER_GUID = 0

-- 等待技能反馈的等待时间
local BLEENCHECKDELAY = 0.3

-- 奥术涌动 状态
local MageArcaneSurgeNoSW = 0
local MageArcaneSurge = 0
local MageArcaneSurgeGUID = 0

-- 奥术飞弹 持续时间
local MageArcaneMissilesDuration = 0
local MageArcaneMissilesTimer = 0

-- 冰柱 持续时间
local MageIcicleDuration = 0
local MageIcicleTimer = 0

-- 火焰易伤层数
local FireVulnerabilityLayer = {}

-- 灼烧
local ScorchCheck = {}
local ScorchDelayTime = {}

-- 火焰冲击
local FireBlastCheck = {}
local FireBlastDelayTime = {}


local function ResetData()
    MageArcaneMissilesDuration = 0
    MageArcaneMissilesTimer = 0
    MageArcaneSurgeNoSW = 0
    MageArcaneSurge = 0
    MageArcaneSurgeGUID = 0
    MageIcicleDuration = 0
    MageIcicleTimer = 0
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

        -- 读条处理
        if arg1 == "炎爆术" then MPMageCastPyroblastTimer=GetTime()+(arg2/1000)+0.5 end

    elseif event == "SPELLCAST_CHANNEL_START" then
        MageArcaneMissilesDuration = arg1
        MageArcaneMissilesTimer = GetTime()

    elseif event == "SPELLCAST_CHANNEL_UPDATE" then
        MageArcaneMissilesDuration = arg1

    elseif event == "SPELLCAST_CHANNEL_STOP" then
        MageArcaneMissilesDuration = 0
        MageArcaneMissilesTimer = 0
--[[
    elseif event == "SPELLCAST_DELAYED" then
        message("SPELLCAST_DELAYED")

    elseif event == "SPELLCAST_START" then
        message("SPELLCAST_START")

    elseif event == "SPELLCAST_STOP" then
        message("SPELLCAST_STOP")

    elseif event == "SPELLCAST_INTERRUPTED" then
        message("SPELLCAST_INTERRUPTED")

    elseif event == "SPELLS_CHANGED" then
        message("SPELLS_CHANGED")
]]


    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then

        if string.find( arg1, ".*抵抗.*" ) then
            MageArcaneSurgeNoSW = GetTime()
        elseif string.find( arg1, ".*炎爆术.*" ) then
            MPMagePyromaniac = 0
        end

    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        --message(arg1)
        --message("---CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS-----")

        if string.find( arg1, "你获得了法术连击的效果.*" ) then
            local number = MPExtractNumber(arg1) 
            if number then
                MPMagePyromaniac = MPToNumber(number)
            else
                MPMagePyromaniac = 1
            end
        end

    ---------------------------
    -- SuperWoW事件 -----------
    ---------------------------

    -- 施法、攻击事件处理
    elseif event == "UNIT_CASTEVENT" then

        -- 施法事件监测
        if arg3 == "CAST" then

            -- 仅监控自己放出的技能
            if arg1 == PLAYER_GUID then

                --MPMsg(arg4)
                --message("-----------")

                -- 奥术涌动
                if arg4 == 51936 then
                    MageArcaneSurge = 0

                -- 灼烧
                elseif arg4==2948 or arg4==8444 or arg4==8445 or arg4==8446 or arg4==10205 or arg4==10206 or arg4==10207 then
                    ScorchDelayTime[arg2] = GetTime()

                -- 火焰冲击
                elseif arg4==2136 or arg4==2137 or arg4==2138 or arg4==8412 or arg4==8413 or arg4==10197 or arg4==10199 then
                    FireBlastDelayTime[arg2] = GetTime()

                end



            end

        end

    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then

        -- 自己的攻击
        if arg1 == "CHAT_MSG_SPELL_SELF_DAMAGE" then

            --message(arg2)

            if string.find( arg2, ".*抵抗.*" ) then
                local guid = MPMatchGUID(arg2)
                if guid then
                    MageArcaneSurge = GetTime()
                    MageArcaneSurgeGUID = guid
                end
            end

            -- 灼烧
            if string.find( arg2, "你的灼烧被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and ScorchDelayTime[targetGUID] then 
                    local timer = GetTime() - ScorchDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        ScorchDelayTime[targetGUID] = nil
                    end
                end
            end

            -- 火焰冲击
            if string.find( arg2, "你的火焰冲击被.*抵抗.*" ) then
                local targetGUID = MPMatchGUID(arg2)
                if targetGUID and FireBlastDelayTime[targetGUID] then 
                    local timer = GetTime() - FireBlastDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        FireBlastDelayTime[targetGUID] = nil
                    end
                end
            end

        end

    end


end

-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)


-- 获取奥术涌动状态
function MPGetMageArcaneSurge()
    -- 检测是否有SuperWow模组
    if not MP_SuperWoW then
        if GetTime()-MageArcaneSurgeNoSW<4 then
            return true
        end

        return false
    end

	if GetTime()-MageArcaneSurge<4 then

		-- 是否存在有效目标
		local a,guid=UnitExists("target")
		if not guid then
			return false
		end

		-- 校验GUID是否是触发奥术涌动的目标
		if guid == MageArcaneSurgeGUID then
			return true
		end
	end

	return false

end



-- 获取奥术飞弹持续时间
function GetMageArcaneMissilesDuration()
    return MageArcaneMissilesDuration
end

-- 获取奥术飞弹持续剩余时间
function GetMageArcaneMissiles()

    local timer = GetTime()-MageArcaneMissilesTimer

    if MageArcaneMissilesDuration <= 0 then
        return -1
    end

    --[[
    if timer > MageArcaneMissilesDuration then
        return -1
    end
    ]]

    return MageArcaneMissilesDuration/1000 - timer
end


-- 获取当前目标是否有火焰易伤效果
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPGetFireDot()

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW then
        return MPBuff("火焰易伤","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists("target")
    if not guid then
        return false
    end

        -- 0.2秒监测期里
    if ScorchDelayTime[guid] then 
        local timer = GetTime() - ScorchDelayTime[guid]
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return MPGetScorchDotCheck(guid)
        else
            -- 计算层数
            if not MPGetScorchDotCheck(guid) then
                FireVulnerabilityLayer[guid]=1
            else
                if FireVulnerabilityLayer[guid] < 5 then
                    FireVulnerabilityLayer[guid] = FireVulnerabilityLayer[guid] + 1
                end
            end

            -- 已经过了认证期
            ScorchCheck[guid] = ScorchDelayTime[guid]
            ScorchDelayTime[guid] = nil

        end
    end


    if FireBlastDelayTime[guid] then 
        local timer = GetTime() - FireBlastDelayTime[guid]
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return MPGetScorchDotCheck(guid)
        else
            -- 计算层数
            if not MPGetScorchDotCheck(guid) then
                FireVulnerabilityLayer[guid]=1
            else
                if FireVulnerabilityLayer[guid] < 5 then
                    FireVulnerabilityLayer[guid] = FireVulnerabilityLayer[guid] + 1
                end
            end

            -- 已经过了认证期
            ScorchCheck[guid] = FireBlastDelayTime[guid]
            FireBlastDelayTime[guid] = nil

        end
    end


    return MPGetScorchDotCheck(guid)
end

function MPGetScorchDotCheck( guid )
    if ScorchCheck[guid] then
        local timer = GetTime() - ScorchCheck[guid]
        if timer < 30 then
            return true
        end
    end

    return false
end

function MPGetScorchCheck()
    return ScorchCheck
end

function MPGetFireVulnerabilityLayer()
    return FireVulnerabilityLayer
end





-- 法师特性状态
function MPMageRefreshInfo()

    -- 检查奥术溃裂天赋
    MPMageArcaneExplosion = MPIsTalentLearned(1,9)

    -- 冰锥术距离
    MPMageConeColdDist = 10 + MPIsTalentLearned(3,11) - 1.5

    -- 寒冰护体
    MPMageIceBarrier = MPIsTalentLearned(3,19)

    -- 冰柱
    MPMageIcicle = MPIsTalentLearned(3,15)


    -- 烈焰投掷
    MPMageFireBlastDist = 20
    if MPIsTalentLearned(2,4)==1 then
        MPMageFireBlastDist = 23
    elseif MPIsTalentLearned(2,4)==2 then
        MPMageFireBlastDist = 26
    end

end

