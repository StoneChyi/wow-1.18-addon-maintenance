local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then
    return  -- 终止文件执行
end

-- 创建一个 Frame 并监听事件
local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("SPELLCAST_START")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_FAILED")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
frame:RegisterEvent("CHAT_MSG_COMBAT_FRIENDLY_DEATH")

-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")


-- 自己的GUID
local PLAYER_GUID = 0

-- 烈焰震击
local FlameShockCheck = {}
local FlameShockDelayTime = {}
-- 熔岩爆裂
local LavaBurstDelayTime = {}
local LavaBurstBeginTime = 0


-- 等待技能反馈的等待时间
local BLEENCHECKDELAY = 0.3

local function ResetData()
    MPShamanCastHeal = 0
    FlameShockCheck = {}
    FlameShockDelayTime = {}
    LavaBurstDelayTime = {}
    LavaBurstBeginTime = 0
    MPLightningBoltCount = 0
    MPBeginLavaBurstCastTimer = 0
end

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
        MPLeaveCombatTotem()
        ResetData()

    -- 玩家死亡，重置参数
    elseif event == "PLAYER_DEAD" then

        ResetData()

    -- 施法事件处理，读条类，读条也要处理GCD
    elseif event == "SPELLCAST_START" then

        -- 萨满治疗读条处理
        if arg1 == "次级治疗波" then MPShamanCastHeal=GetTime()
        elseif arg1 == "治疗波" then MPShamanCastHeal=GetTime()
        elseif arg1 == "治疗链" then MPShamanCastHeal=GetTime()
        elseif arg1 == "熔岩爆裂" then 
            MPBeginLavaBurstCastTimer=GetTime()
            MPLightningBoltCount=0
        elseif arg1 == "闪电箭" then 
            MPLightningBoltCount=MPLightningBoltCount+1
        elseif arg1 == "闪电链" then 
            MPLightningBoltCount=MPLightningBoltCount+1
        elseif arg1 == "地震术" then 
            MPLightningBoltCount=MPLightningBoltCount+2
        end

    elseif event == "SPELLCAST_STOP" then

        MPShamanCastHeal = 0

    elseif event == "SPELLCAST_FAILED" then

        MPShamanCastHeal = 0

    elseif event == "SPELLCAST_INTERRUPTED" then

        MPShamanCastHeal = 0

    -- 捕获图腾消失
    elseif event == "CHAT_MSG_COMBAT_FRIENDLY_DEATH" then
        --message("dead: "..arg1)

        if string.find( arg1, ".*根基图腾.*" ) then
            if MP_SuperWoW then
                local mainplayer = MPMatch(arg1, "%((.-)%)")
                if mainplayer == UnitName("player") then
                    MPAirTotemTimer = 0
                end
            else
                MPAirTotemTimer = 0
            end
        end

    elseif event == "CHAT_MSG_SPELL_SELF_BUFF" then

        if string.find( arg1, ".*图腾召回.*" ) then
            MPEarthTotemTimer = 0
            MPFireTotemTimer = 0
            MPWaterTotemTimer = 0
            MPAirTotemTimer = 0
        end

        if not MP_SuperWoW then
            local totemName = MPMatch(arg1, "你施放了(.+)。")

            if totemName=="地缚图腾" then
                MPEarthTotemDuration = 45
                MPEarthTotemTimer = GetTime()
                MPEarthTotemName = "地缚图腾"
            elseif totemName=="石爪图腾" then
                MPEarthTotemDuration = 15
                MPEarthTotemTimer = GetTime()
                MPEarthTotemName = "石爪图腾"
            elseif totemName=="大地之力图腾" then
                MPEarthTotemDuration = 120
                MPEarthTotemTimer = GetTime()
                MPEarthTotemName = "大地之力图腾"
            elseif totemName=="石肤图腾" then
                MPEarthTotemDuration = 120
                MPEarthTotemTimer = GetTime()
                MPEarthTotemName = "石肤图腾"
            elseif totemName=="战栗图腾" then
                MPEarthTotemDuration = 120
                MPEarthTotemTimer = GetTime()
                MPEarthTotemName = "战栗图腾"

            elseif totemName=="火焰新星图腾" then
                MPFireTotemDuration = 5
                MPFireTotemTimer = GetTime()
                MPFireTotemName = "火焰新星图腾"

            elseif totemName=="灼热图腾" then
                MPFireTotemDuration = 55
                MPFireTotemTimer = GetTime()
                MPFireTotemName = "灼热图腾"

            elseif totemName=="熔岩图腾" then
                MPFireTotemDuration = 20
                MPFireTotemTimer = GetTime()
                MPFireTotemName = "熔岩图腾"

            elseif totemName=="抗寒图腾" then
                MPFireTotemDuration = 120
                MPFireTotemTimer = GetTime()
                MPFireTotemName = "抗寒图腾"

            elseif totemName=="火舌图腾" then
                MPFireTotemDuration = 120
                MPFireTotemTimer = GetTime()
                MPFireTotemName = "火舌图腾"

            elseif totemName=="抗火图腾" then
                MPWaterTotemDuration = 120
                MPWaterTotemTimer = GetTime()
                MPWaterTotemName = "抗火图腾"

            elseif totemName=="治疗之泉图腾" then
                MPWaterTotemDuration = 60
                MPWaterTotemTimer = GetTime()
                MPWaterTotemName = "治疗之泉图腾"

            elseif totemName=="法力之泉图腾" then
                MPWaterTotemDuration = 60
                MPWaterTotemTimer = GetTime()
                MPWaterTotemName = "法力之泉图腾"

            elseif totemName=="清毒图腾" then
                MPWaterTotemDuration = 120
                MPWaterTotemTimer = GetTime()
                MPWaterTotemName = "清毒图腾"

            elseif totemName=="祛病图腾" then
                MPWaterTotemDuration = 120
                MPWaterTotemTimer = GetTime()
                MPWaterTotemName = "祛病图腾"

            elseif totemName=="岗哨图腾" then
                MPAirTotemDuration = 300
                MPAirTotemTimer = GetTime()
                MPAirTotemName = "岗哨图腾"

            elseif totemName=="根基图腾" then
                MPAirTotemDuration = 45
                MPAirTotemTimer = GetTime()
                MPAirTotemName = "根基图腾"

            elseif totemName=="自然抗性图腾" then
                MPAirTotemDuration = 120
                MPAirTotemTimer = GetTime()
                MPAirTotemName = "自然抗性图腾"

            elseif totemName=="风之优雅图腾" then
                MPAirTotemDuration = 120
                MPAirTotemTimer = GetTime()
                MPAirTotemName = "风之优雅图腾"

            elseif totemName=="风墙图腾" then
                MPAirTotemDuration = 120
                MPAirTotemTimer = GetTime()
                MPAirTotemName = "风墙图腾"

            elseif totemName=="风怒图腾" then
                MPAirTotemDuration = 120
                MPAirTotemTimer = GetTime()
                MPAirTotemName = "风怒图腾"

            elseif totemName=="宁静之风图腾" then
                MPAirTotemDuration = 120
                MPAirTotemTimer = GetTime()
                MPAirTotemName = "宁静之风图腾"




            end

        end

    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        --message(arg1)
        --message("---CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS-----")




    ---------------------------
    -- SuperWoW事件 -----------
    ---------------------------

    -- 施法、攻击事件处理
    elseif event == "UNIT_CASTEVENT" then

        --[[
        if arg1 == PLAYER_GUID then
            message(arg4)
            message("----"..arg3.."----")
        end
        ]]

        if arg3 == "CAST" then
            if arg1 == PLAYER_GUID then

                --message(arg4)
                
                -- 图腾召回
                if arg4 == 45513 then
                    MPEarthTotemTimer = 0
                    MPFireTotemTimer = 0
                    MPWaterTotemTimer = 0
                    MPAirTotemTimer = 0


                ----------------
                -- 大地图腾
                ----------------

                -- 地缚图腾
                elseif arg4 == 2484 then
                    MPEarthTotemDuration = 45
                    MPEarthTotemTimer = GetTime()
                    MPEarthTotemName = "地缚图腾"
                    MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")

                -- 石爪图腾
                elseif arg4 == 5730 or arg4==6390 or arg4==6391 or arg4==6392 or arg4==10427 or arg4==10428 then
                    MPEarthTotemDuration = 15
                    MPEarthTotemTimer = GetTime()
                    MPEarthTotemName = "石爪图腾"
                    MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")

                -- 大地之力图腾
                elseif arg4 == 8075 or arg4==8160 or arg4==8161 or arg4==10442 or arg4==25361 then
                    MPEarthTotemDuration = 120
                    MPEarthTotemTimer = GetTime()
                    MPEarthTotemName = "大地之力图腾"
                    MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")

                -- 石肤图腾
                elseif arg4 == 8071 or arg4==8154 or arg4==8155 or arg4==10406 or arg4==10407 or arg4==10408 then
                    MPEarthTotemDuration = 120
                    MPEarthTotemTimer = GetTime()
                    MPEarthTotemName = "石肤图腾"
                    MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")

                -- 战栗图腾
                elseif arg4 == 8143 then
                    MPEarthTotemDuration = 120
                    MPEarthTotemTimer = GetTime()
                    MPEarthTotemName = "战栗图腾"
                    MPEarthTotemX, MPEarthTotemY = GetPlayerMapPosition("player")

                ----------------
                -- 火焰图腾
                ----------------

                -- 火焰新星图腾
                elseif arg4==1535 or arg4==8498 or arg4==8499 or arg4==11314 or arg4==11315 then
                    MPFireTotemDuration = 5
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "火焰新星图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                -- 灼热图腾
                elseif arg4==3599 then-- arg4==6363 or arg4==6364 or arg4==6365 or arg4==10437 or arg4==10438 then
                    MPFireTotemDuration = 30
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "灼热图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                elseif arg4==6363 then--  arg4==6364 or arg4==6365 or arg4==10437 or arg4==10438 then
                    MPFireTotemDuration = 35
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "灼热图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                elseif arg4==6364 then--   arg4==6365 or arg4==10437 or arg4==10438 then
                    MPFireTotemDuration = 40
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "灼热图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                elseif arg4==6365 then--   arg4==10437 or arg4==10438 then
                    MPFireTotemDuration = 45
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "灼热图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                elseif arg4==10437 then--   arg4==10438 then
                    MPFireTotemDuration = 50
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "灼热图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                elseif arg4==10438 then
                    MPFireTotemDuration = 55
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "灼热图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                -- 熔岩图腾
                elseif arg4==8190 or arg4==10585 or arg4==10586 or arg4==10587 then
                    MPFireTotemDuration = 20
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "熔岩图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                -- 抗寒图腾
                elseif arg4==8181 or arg4==10478 or arg4==10479 then
                    MPFireTotemDuration = 120
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "抗寒图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")

                -- 火舌图腾
                elseif arg4==8227 or arg4==8249 or arg4==10526 or arg4==16387 then
                    MPFireTotemDuration = 120
                    MPFireTotemTimer = GetTime()
                    MPFireTotemName = "火舌图腾"
                    MPFireTotemX, MPFireTotemY = GetPlayerMapPosition("player")



                ----------------
                -- 水之图腾
                ----------------

                -- 抗火图腾
                elseif arg4==8184 or arg4==10537 or arg4==10538 then
                    MPWaterTotemDuration = 120
                    MPWaterTotemTimer = GetTime()
                    MPWaterTotemName = "抗火图腾"
                    MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")

                -- 治疗之泉图腾
                elseif arg4==5394 or arg4==6375 or arg4==6377 or arg4==10462 or arg4==10463 then
                    MPWaterTotemDuration = 60
                    MPWaterTotemTimer = GetTime()
                    MPWaterTotemName = "治疗之泉图腾"
                    MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")

                -- 法力之泉图腾
                elseif arg4==5675 or arg4==10495 or arg4==10496 or arg4==10497 then
                    MPWaterTotemDuration = 60
                    MPWaterTotemTimer = GetTime()
                    MPWaterTotemName = "法力之泉图腾"
                    MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")

                -- 清毒图腾
                elseif arg4==8166 then
                    MPWaterTotemDuration = 120
                    MPWaterTotemTimer = GetTime()
                    MPWaterTotemName = "清毒图腾"
                    MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")

                -- 祛病图腾
                elseif arg4==8170 then
                    MPWaterTotemDuration = 120
                    MPWaterTotemTimer = GetTime()
                    MPWaterTotemName = "祛病图腾"
                    MPWaterTotemX, MPWaterTotemY = GetPlayerMapPosition("player")

                ----------------
                -- 空气图腾
                ----------------

                -- 岗哨图腾
                elseif arg4 == 6495 then
                    MPAirTotemDuration = 300
                    MPAirTotemTimer = GetTime()
                    MPAirTotemName = "岗哨图腾"
                    MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")

                -- 根基图腾
                elseif arg4 == 8177 then
                    MPAirTotemDuration = 45
                    MPAirTotemTimer = GetTime()
                    MPAirTotemName = "根基图腾"
                    MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")

                -- 自然抗性图腾
                elseif arg4==10595 or arg4==10600 or arg4==10601 then
                    MPAirTotemDuration = 120
                    MPAirTotemTimer = GetTime()
                    MPAirTotemName = "自然抗性图腾"
                    MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")

                -- 风之优雅图腾
                elseif arg4==8835 or arg4==10627 or arg4==25359 then
                    MPAirTotemDuration = 120
                    MPAirTotemTimer = GetTime()
                    MPAirTotemName = "风之优雅图腾"
                    MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")

                -- 风墙图腾
                elseif arg4==15107 or arg4==15111 or arg4==15112 then
                    MPAirTotemDuration = 120
                    MPAirTotemTimer = GetTime()
                    MPAirTotemName = "风墙图腾"
                    MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")

                -- 风怒图腾
                elseif arg4==8512 then
                    MPAirTotemDuration = 120
                    MPAirTotemTimer = GetTime()
                    MPAirTotemName = "风怒图腾"
                    MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")

                -- 宁静之风图腾
                elseif arg4==25908 then
                    MPAirTotemDuration = 120
                    MPAirTotemTimer = GetTime()
                    MPAirTotemName = "宁静之风图腾"
                    MPAirTotemX, MPAirTotemY = GetPlayerMapPosition("player")


                -- 烈焰震击
                elseif arg4==8050 or arg4==8052 or arg4==8053 or arg4==10447 or arg4==10448 or arg4==29228 then
                    FlameShockDelayTime[arg2] = GetTime()

                -- 熔岩爆裂
                elseif arg4==36916 or arg4==36917 or arg4==36918 or arg4==36919 or arg4==36920 or arg4==36921 then
                    --LavaBurstDelayTime[arg2] = GetTime()
                    LavaBurstBeginTime = GetTime()

                end

            end
        end

    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then

        -- 自己的攻击
        if arg1 == "CHAT_MSG_SPELL_SELF_DAMAGE" then

            --message(arg2)
            -- 烈焰震击
            if string.find( arg2, "你的烈焰震击.*抵抗了.*" ) then
                local targetGUID = MPMatchGUID(arg2) 
                if targetGUID and FlameShockDelayTime[targetGUID] then 
                    local timer = GetTime() - FlameShockDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        FlameShockDelayTime[targetGUID] = nil
                    end
                end

            elseif string.find( arg2, "你的熔岩爆裂击中.*" ) or string.find( arg2, "你的熔岩爆裂致命一击.*" ) then
                if MPGetFlameShockDot() then
                    local targetGUID = MPMatchGUID(arg2) 
                    if targetGUID and FlameShockCheck[targetGUID] then
                        FlameShockCheck[targetGUID] = GetTime()-0.2
                    end
                end

            elseif string.find( arg2, "你的重燃烈火击中.*" ) or string.find( arg2, "你的重燃烈火致命一击.*" ) then
                if MPGetFlameShockDot() then
                    local targetGUID = MPMatchGUID(arg2) 
                    if targetGUID and FlameShockCheck[targetGUID] then
                        FlameShockCheck[targetGUID] = GetTime()-0.2
                    end
                end

            end

            --[[
            if string.find( arg2, "你的熔岩爆裂.*抵抗了.*" ) then
                local targetGUID = MPMatchGUID(arg2) 
                if LavaBurstDelayTime[targetGUID] then 
                    local timer = GetTime() - LavaBurstDelayTime[targetGUID]
                    if timer <= BLEENCHECKDELAY then
                        LavaBurstDelayTime[targetGUID] = nil
                    end
                end
            end
            ]]


        end

    end

end

-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)


function MPEarthTotem()
    if GetTime()-MPEarthTotemTimer<MPEarthTotemDuration then
        return true
    end

    return false
end

function MPFireTotem()
    if GetTime()-MPFireTotemTimer<MPFireTotemDuration then
        return true
    end

    return false
end

function MPWaterTotem()
    if GetTime()-MPWaterTotemTimer<MPWaterTotemDuration then
        return true
    end

    return false
end

function MPAirTotem()
    if GetTime()-MPAirTotemTimer<MPAirTotemDuration then
        return true
    end

    return false
end


local MPShamanTooltip = CreateFrame("GameTooltip", "MPShamanTooltip", UIParent, "GameTooltipTemplate")

function MPGetShamanEnchantName(slot)
	slot = slot or 16

    MPShamanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    MPShamanTooltip:ClearLines()
    
    -- 扫描武器栏位（16=主手，17=副手）
    MPShamanTooltip:SetInventoryItem("player", slot)
    
    -- 解析Tooltip
	-- 遍历所有行（最多20行）
    for i = 2, 20 do  -- 通常附魔信息从第2行开始

        local line = _G["MPShamanTooltipTextLeft"..i]
        if not line then break end  -- 无更多行时退出

        local text = line:GetText() or ""

        -- 匹配附魔名称（根据客户端语言调整关键词）
        if string.find(text, "分钟") then
            if string.find(text, "风怒") then
			    MPShamanTooltip:Hide()
                return "风怒武器"

            elseif string.find(text, "火舌") then
			    MPShamanTooltip:Hide()
                return "火舌武器"

            elseif string.find(text, "冰霜") then
			    MPShamanTooltip:Hide()
                return "冰封武器"
            elseif string.find(text, "冰封") then     -- 特殊情况，冰封(等级 3)的翻译情况
			    MPShamanTooltip:Hide()
                return "冰封武器"

            elseif string.find(text, "石化") then
			    MPShamanTooltip:Hide()
                return "石化武器"

            end
        end

    end
    
    MPShamanTooltip:Hide()
    return ""
end


function MPGetFlameShockDot()

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("烈焰震击","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists("target")
    if not guid then
        return false
    end

    -- BLEENCHECKDELAY秒监测期里
    if FlameShockDelayTime[guid] then 
        local timer = GetTime() - FlameShockDelayTime[guid]
        if timer <= BLEENCHECKDELAY then
            -- 还在等待认证期
            return true  --MPGetFlameShockDotCheck(guid)
        else
            -- 已经过了认证期
            FlameShockCheck[guid] = FlameShockDelayTime[guid]
            FlameShockDelayTime[guid] = nil
        end
    end

    --[[
    if LavaBurstDelayTime[guid] then
        local timer = GetTime() - LavaBurstDelayTime[guid]
        if timer > BLEENCHECKDELAY then
            -- 已经过了认证期
            FlameShockCheck[guid] = LavaBurstDelayTime[guid]
            LavaBurstDelayTime[guid] = nil
        end
    end
    ]]

    return MPGetFlameShockDotCheck(guid)
end

function MPGetFlameShockDotCheck( guid )
    if FlameShockCheck[guid] then
        local timer = GetTime() - FlameShockCheck[guid]
        if timer < MPShamanFlameShockDuration then
            return true
        else
            FlameShockCheck[guid] = nil
        end
    end

    return false
end

function MPGetFlameShockCheck()
    return FlameShockCheck
end



-- 萨满特性状态
function MPShamanRefreshInfo()

    -- 潮汐集中 天赋
    local TidalFocus = 1-MPIsTalentLearned(3, 2)*0.01

    MPShamanSecondaryWave[1] = 105 * TidalFocus
    MPShamanSecondaryWaveEffect[1] = 177+(MPHealingPower*MPShamanSecondaryWaveFactor)
    MPShamanSecondaryWave[2] = 145 * TidalFocus
    MPShamanSecondaryWaveEffect[2] = 274+(MPHealingPower*MPShamanSecondaryWaveFactor)
    MPShamanSecondaryWave[3] = 185 * TidalFocus
    MPShamanSecondaryWaveEffect[3] = 371+(MPHealingPower*MPShamanSecondaryWaveFactor)
    MPShamanSecondaryWave[4] = 235 * TidalFocus
    MPShamanSecondaryWaveEffect[4] = 501+(MPHealingPower*MPShamanSecondaryWaveFactor)
    MPShamanSecondaryWave[5] = 305 * TidalFocus
    MPShamanSecondaryWaveEffect[5] = 686+(MPHealingPower*MPShamanSecondaryWaveFactor)
    MPShamanSecondaryWave[6] = 380 * TidalFocus
    MPShamanSecondaryWaveEffect[6] = 871+(MPHealingPower*MPShamanSecondaryWaveFactor)

    MPShamanSecondaryWaveMaxLevel = MPGetHighestRankOfSpell("次级治疗波")


    MPShamanWave[1] = 25 * TidalFocus
    MPShamanWaveEffect[1] = 41+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[2] = 45 * TidalFocus
    MPShamanWaveEffect[2] = 76+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[3] = 80 * TidalFocus
    MPShamanWaveEffect[3] = 149+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[4] = 155 * TidalFocus
    MPShamanWaveEffect[4] = 303+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[5] = 200 * TidalFocus
    MPShamanWaveEffect[5] = 421+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[6] = 265 * TidalFocus
    MPShamanWaveEffect[6] = 595+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[7] = 340 * TidalFocus
    MPShamanWaveEffect[7] = 816+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[8] = 440 * TidalFocus
    MPShamanWaveEffect[8] = 1115+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[9] = 560 * TidalFocus
    MPShamanWaveEffect[9] = 1486+(MPHealingPower*MPShamanWaveFactor)
    MPShamanWave[10] = 620 * TidalFocus
    MPShamanWaveEffect[10] = 1735+(MPHealingPower*MPShamanWaveFactor)

    MPShamanWaveMaxLevel = MPGetHighestRankOfSpell("治疗波")


    MPShamanChain[1] = 260 * TidalFocus
    MPShamanChainEffect[1] = 356+(MPHealingPower*MPShamanChainFactor)
    MPShamanChain[2] = 315 * TidalFocus
    MPShamanChainEffect[2] = 449+(MPHealingPower*MPShamanChainFactor)
    MPShamanChain[3] = 405 * TidalFocus
    MPShamanChainEffect[3] = 606+(MPHealingPower*MPShamanChainFactor)

    MPShamanChainMaxLevel = MPGetHighestRankOfSpell("治疗链")


    -- 水之护盾层数
    MPShamanWaterApplications = 3+MPIsTalentLearned(2,5)*2
    -- 闪电之盾层数
    MPShamanLightningShield = 3+MPIsTalentLearned(2,5)*2

	local count = 0
    -- T2 奶萨套
	if MPCheckInventoryItemName(1,"无尽风暴角盔") then count=count+1 end
	if MPCheckInventoryItemName(3,"无尽风暴肩胄") then count=count+1 end
	if MPCheckInventoryItemName(5,"无尽风暴外衣") then count=count+1 end
	if MPCheckInventoryItemName(6,"无尽风暴束腰") then count=count+1 end
	if MPCheckInventoryItemName(7,"无尽风暴短裤") then count=count+1 end
	if MPCheckInventoryItemName(8,"无尽风暴长靴") then count=count+1 end
	if MPCheckInventoryItemName(9,"无尽风暴束腕") then count=count+1 end
	if MPCheckInventoryItemName(10,"无尽风暴手套") then count=count+1 end
	if count >= 3 then
		MPShamanWaterApplications = MPShamanWaterApplications + 2
        MPShamanLightningShield = MPShamanLightningShield + 2
	end


    count = 0
    MPShaman6T3 = 0
	if MPCheckInventoryItemName(1,"碎地者头冠") then count=count+1 end
	if MPCheckInventoryItemName(3,"碎地者肩铠") then count=count+1 end
	if MPCheckInventoryItemName(5,"碎地者胸甲") then count=count+1 end
	if MPCheckInventoryItemName(6,"碎地者束腰") then count=count+1 end
	if MPCheckInventoryItemName(7,"碎地者护腿") then count=count+1 end
	if MPCheckInventoryItemName(8,"碎地者战靴") then count=count+1 end
	if MPCheckInventoryItemName(9,"碎地者束腕") then count=count+1 end
	if MPCheckInventoryItemName(10,"碎地者手套") then count=count+1 end
	if MPCheckInventoryItemName(11,"碎地者印戒") then count=count+1 end
	if MPCheckInventoryItemName(12,"碎地者印戒") then count=count+1 end
	if count >= 6 then
		MPShaman6T3 = 1
	end

    -- 风暴打击
    MPShamanStormStrike = MPIsTalentLearned(2,14)

    -- 闪电打击
    MPShamanLightningStrike = MPIsTalentLearned(2,8)


    -- 地震术
    MPShamanEarthSpell = MPIsTalentLearned(1,17)

    -- 火震 持续时间
    MPShamanFlameShockDuration = 15
    if MPCheckInventoryItemName(18,"爆发图腾") then
        MPShamanFlameShockDuration = MPShamanFlameShockDuration * 1.2
    end

end