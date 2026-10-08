local _, playerClass = UnitClass("player")
if playerClass ~= "PALADIN" then
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
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
frame:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")

-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")



-- 圣骑士 十字军打击监测
local CrusaderStrikeCheck = 0

-- 自己的GUID
local PLAYER_GUID = 0

-- 正义圣印续存
local PaladinSealJustice = false
-- 命令圣印续存
local PaladinSealCommand = false
-- 智慧圣印续存
local PaladinSealWisdom = false
-- 十字军圣印续存
local PaladinSealCrusader = false
-- 光明圣印续存
local PaladinSealRight = false

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
        CrusaderStrikeCheck = 0

    -- 玩家死亡，重置参数
    elseif event == "PLAYER_DEAD" then
        CrusaderStrikeCheck = 0
        MPPaladinCastHeal = 0

        PaladinSealJustice = false
        PaladinSealCommand = false
        PaladinSealWisdom = false
        PaladinSealCrusader = false
        PaladinSealRight = false
        MPPaladinSealJusticeDuration = 0
        MPPaladinSealWisdomDuration = 0
        MPPaladinSealCrusaderDuration = 0
        MPPaladinSealCommandDuration = 0
        MPPaladinSealRightDuration = 0

    -- 施法事件处理，读条类，读条也要处理GCD
    elseif event == "SPELLCAST_START" then

        -- 圣骑士治疗读条处理
        if arg1 == "圣光闪现" then MPPaladinCastHeal=GetTime() end
        if arg1 == "圣光术" then
            MPPaladinCastHeal=GetTime()

            -- 近战奶，防止黏接圣光术
            MPCastHolyLightDelay=GetTime()+(arg2/1000)+0.3
        end

    elseif event == "SPELLCAST_STOP" then

        MPPaladinCastHeal = 0

    elseif event == "SPELLCAST_FAILED" then

        MPPaladinCastHeal = 0

    elseif event == "SPELLCAST_INTERRUPTED" then

        MPPaladinCastHeal = 0

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then

        -- 神圣打击 - 无论是否命中、招架、闪避，都能刷新威能
        if string.find( arg1, "你的神圣打击.*" ) then
            MPPaladinHolyStrikeDuration = GetTime()
        elseif string.find( arg1, "你的十字军打击.*" ) then
            MPPaladinFrenzyDuration = GetTime()
            CrusaderStrikeCheck = GetTime()
        elseif string.find( arg1, "你的.*审判.*" ) then
            PaladinSealJustice = false
            PaladinSealCommand = false
            PaladinSealWisdom = false
            PaladinSealCrusader = false
            PaladinSealRight = false
            gcdtimer = 0
        end

    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        --message(arg1)
        --message("---SPELLCAST_STOP-----")

        if string.find( arg1, "你获得了狂热的效果.*" ) then
            local number = MPExtractNumber(arg1) 
            if number then
                MPPaladinFrenzyLayer = MPToNumber(number)
            else
                MPPaladinFrenzyLayer = 1
            end
        elseif string.find( arg1, "你获得了正义圣印的效果.*" ) then
            PaladinSealJustice = true
            PaladinSealCommand = false
            PaladinSealWisdom = false
            PaladinSealCrusader = false
            PaladinSealRight = false

            MPPaladinSealJusticeDuration = GetTime()
            MPPaladinSealWisdomDuration = 0
            MPPaladinSealCrusaderDuration = 0
            MPPaladinSealCommandDuration = 0
            MPPaladinSealRightDuration = 0

        elseif string.find( arg1, "你获得了命令圣印的效果.*" ) then
            PaladinSealJustice = false
            PaladinSealCommand = true
            PaladinSealWisdom = false
            PaladinSealCrusader = false
            PaladinSealRight = false

            MPPaladinSealJusticeDuration = 0
            MPPaladinSealWisdomDuration = 0
            MPPaladinSealCrusaderDuration = 0
            MPPaladinSealCommandDuration = GetTime()
            MPPaladinSealRightDuration = 0

        elseif string.find( arg1, "你获得了智慧圣印的效果.*" ) then
            PaladinSealJustice = false
            PaladinSealCommand = false
            PaladinSealWisdom = true
            PaladinSealCrusader = false
            PaladinSealRight = false

            MPPaladinSealWisdomDuration = GetTime()
            MPPaladinSealJusticeDuration = 0
            MPPaladinSealCrusaderDuration = 0
            MPPaladinSealCommandDuration = 0
            MPPaladinSealRightDuration = 0

        elseif string.find( arg1, "你获得了十字军圣印的效果.*" ) then
            PaladinSealJustice = false
            PaladinSealCommand = false
            PaladinSealWisdom = false
            PaladinSealCrusader = true
            PaladinSealRight = false

            MPPaladinSealCrusaderDuration = GetTime()
            MPPaladinSealJusticeDuration = 0
            MPPaladinSealWisdomDuration = 0
            MPPaladinSealCommandDuration = 0
            MPPaladinSealRightDuration = 0

        elseif string.find( arg1, "你获得了光明圣印的效果.*" ) then
            PaladinSealJustice = false
            PaladinSealCommand = false
            PaladinSealWisdom = false
            PaladinSealCrusader = false
            PaladinSealRight = true

            MPPaladinSealCrusaderDuration = 0
            MPPaladinSealJusticeDuration = 0
            MPPaladinSealWisdomDuration = 0
            MPPaladinSealCommandDuration = 0
            MPPaladinSealRightDuration = GetTime()

        end

    elseif event == "CHAT_MSG_SPELL_AURA_GONE_SELF" then
        --message(arg1)
        --message("---CHAT_MSG_SPELL_AURA_GONE_SELF-----")

        if string.find( arg1, ".*狂热效果.*消失.*" ) then
            if not MP_SuperWoW then
                MPPaladinFrenzyLayer = 0
            end
        elseif string.find( arg1, ".*圣印.*消失.*" ) then

            PaladinSealJustice = false
            PaladinSealCommand = false
            PaladinSealWisdom = false
            PaladinSealCrusader = false
            PaladinSealRight = false
            
            MPPaladinSealJusticeDuration = 0
            MPPaladinSealWisdomDuration = 0
            MPPaladinSealCrusaderDuration = 0
            MPPaladinSealCommandDuration = 0
            MPPaladinSealRightDuration = 0
            
        end



    ---------------------------
    -- SuperWoW事件 -----------
    ---------------------------

    -- 施法、攻击事件处理
    elseif event == "UNIT_CASTEVENT" then

        if arg3 == "CAST" then

            -- 仅监控自己放出的技能
            if arg1 == PLAYER_GUID then

                --message(arg4)

                -- 正义圣印
                if arg4==21084 or arg4==20287 or arg4==20288 or arg4==20289 or arg4==20290 or arg4==20291 or arg4==20292 or arg4==20293 then
                    MPMsg("正义圣印")
                    MPPaladinSealJusticeDuration = GetTime()
                    MPPaladinSealWisdomDuration = 0
                    MPPaladinSealCrusaderDuration = 0
                    MPPaladinSealCommandDuration = 0
                    MPPaladinSealRightDuration = 0
                -- 命令圣印
                elseif arg4==20920 or arg4==20919 or arg4==20918 or arg4==20915 or arg4==20375 then
                    MPMsg("命令圣印")
                    MPPaladinSealJusticeDuration = 0
                    MPPaladinSealWisdomDuration = 0
                    MPPaladinSealCrusaderDuration = 0
                    MPPaladinSealCommandDuration = GetTime()
                    MPPaladinSealRightDuration = 0
                -- 智慧圣印
                elseif arg4==20166 or arg4==20356 or arg4==20357 or arg4==51745 or arg4 == 51746 then
                    MPMsg("智慧圣印")
                    MPPaladinSealWisdomDuration = GetTime()
                    MPPaladinSealJusticeDuration = 0
                    MPPaladinSealCrusaderDuration = 0
                    MPPaladinSealCommandDuration = 0
                    MPPaladinSealRightDuration = 0

                -- 十字军圣印
                elseif arg4==21082 or arg4==20162 or arg4==20305 or arg4==20306 or arg4==20307 or arg4==20308 then
                    MPMsg("十字军圣印")
                    MPPaladinSealCrusaderDuration = GetTime()
                    MPPaladinSealJusticeDuration = 0
                    MPPaladinSealWisdomDuration = 0
                    MPPaladinSealCommandDuration = 0
                    MPPaladinSealRightDuration = 0
                -- 光明圣印
                elseif arg4==20165 or arg4==20347 or arg4==20348 or arg4==20349 then
                    MPMsg("光明圣印")
                    MPPaladinSealCrusaderDuration = 0
                    MPPaladinSealJusticeDuration = 0
                    MPPaladinSealWisdomDuration = 0
                    MPPaladinSealCommandDuration = 0
                    MPPaladinSealRightDuration = GetTime()

                -- 审判
                elseif arg4 == 20271 then
                    MPMsg("审判")
                    MPPaladinSealJusticeDuration = 0
                    MPPaladinSealWisdomDuration = 0
                    MPPaladinSealCrusaderDuration = 0
                    MPPaladinSealCommandDuration = 0
                    MPPaladinSealRightDuration = 0
                    gcdtimer = 0        -- 审判不会触发GCD

                -- 十字军打击
                elseif arg4 == 10337 then
                    if MPGetCrusaderStrike() then
                        MPPaladinFrenzyLayer = MPPaladinFrenzyLayer +1
                        if MPPaladinFrenzyLayer>3 then MPPaladinFrenzyLayer=3 end
                    else
                        MPPaladinFrenzyLayer = 1
                    end
                    MPPaladinFrenzyDuration = GetTime()
                    CrusaderStrikeCheck = GetTime()

                -- 神圣打击
                elseif arg4 == 10333 then
                    MPPaladinHolyStrikeDuration = GetTime()
                end

            end
        end

    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then

    end

end

-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)




-- 圣骑士特性状态
function MPPaladinRefreshInfo()

	-- 查找圣洁光环ID
	for i = 1, 9 do
		local _, name, _, id = GetShapeshiftFormInfo(i)
        if name and name=="圣洁光环" then
            MPPaladinDevotionAuraID = i
            break
        end
        --[[
		local icon,_,a=GetShapeshiftFormInfo(i)
		if icon then
			if icon=="Interface\\Icons\\Spell_Holy_MindVision" then
				MPPaladinDevotionAuraID = i
			end
		end
        ]]
	end

    -- 检查天赋里有没有圣洁光环
    MPPaladinDevotionAura = MPIsTalentLearned(1, 7)

	-- 天赋中是否有忏悔
	MPPaladinRepentance = MPIsTalentLearned(3, 16)

	-- 命令圣印天赋是否点出
	MPPaladinSealCommand = MPIsTalentLearned(3, 14)

	-- 正义圣印天赋是否点满
	if MPIsTalentLearned(1, 5) >= 4 then
		MPPaladinSealJustice = 1
	else
		MPPaladinSealJustice = 0
	end

    MPPaladinFlashLight[1] = 35
    MPPaladinFlashLightEffect[1] = 72+(MPHealingPower*MPPaladinFlashLightFactor)
    MPPaladinFlashLight[2] = 50
    MPPaladinFlashLightEffect[2] = 109+(MPHealingPower*MPPaladinFlashLightFactor)
    MPPaladinFlashLight[3] = 70
    MPPaladinFlashLightEffect[3] = 162+(MPHealingPower*MPPaladinFlashLightFactor)
    MPPaladinFlashLight[4] = 90
    MPPaladinFlashLightEffect[4] = 219+(MPHealingPower*MPPaladinFlashLightFactor)
    MPPaladinFlashLight[5] = 115
    MPPaladinFlashLightEffect[5] = 295+(MPHealingPower*MPPaladinFlashLightFactor)
    MPPaladinFlashLight[6] = 140
    MPPaladinFlashLightEffect[6] = 365+(MPHealingPower*MPPaladinFlashLightFactor)
    MPPaladinFlashLight[7] = 180
    MPPaladinFlashLightEffect[7] = 460+(MPHealingPower*MPPaladinFlashLightFactor)

    MPPaladinFlashLightMaxLevel = MPGetHighestRankOfSpell("圣光闪现")

    MPPaladinHolyLight[1] = 35
    MPPaladinHolyLightEffect[1] = 46+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[2] = 60
    MPPaladinHolyLightEffect[2] = 89+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[3] = 110
    MPPaladinHolyLightEffect[3] = 184+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[4] = 190
    MPPaladinHolyLightEffect[4] = 350+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[5] = 275
    MPPaladinHolyLightEffect[5] = 538+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[6] = 365
    MPPaladinHolyLightEffect[6] = 758+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[7] = 465
    MPPaladinHolyLightEffect[7] = 1018+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[8] = 580
    MPPaladinHolyLightEffect[8] = 1342+(MPHealingPower*MPPaladinHolyLightFactor)
    MPPaladinHolyLight[9] = 660
    MPPaladinHolyLightEffect[9] = 1680+(MPHealingPower*MPPaladinHolyLightFactor)

    MPPaladinHolyLightMaxLevel = MPGetHighestRankOfSpell("圣光术")

    -- 治疗之光
    local ImprovedHolyLight = 1+MPIsTalentLearned(1, 6)*0.04
    if ImprovedHolyLight>0 then

        for i = 1, 7 do
            MPPaladinFlashLightEffect[i] = MPPaladinFlashLightEffect[i] * ImprovedHolyLight
        end

        for i = 1, 9 do
            MPPaladinHolyLightEffect[i] = MPPaladinHolyLightEffect[i] * ImprovedHolyLight
        end

    end

    -- 庇护祝福
    MPPaladinSanctuary = MPIsTalentLearned(2,7)

end


-- 获取自己是否有圣印效果
-- 注：SuperWow支持更加准确
-- return 存在返回真
function MPSeal(name)

    --[[
    -- 检测是否有SuperWow模组
    if not MP_SuperWoW then
	    if name=="正义圣印" then
			return PaladinSealJustice
	    elseif name=="智慧圣印" then
			return PaladinSealWisdom
	    elseif name=="十字军圣印" then
			return PaladinSealCrusader
	    elseif name=="命令圣印" then
			return PaladinSealCommand
	    elseif name=="光明圣印" then
			return PaladinSealRight
	    end

        return false
    end
    ]]

	if name=="正义圣印" then
		if GetTime()-MPPaladinSealJusticeDuration<30 then
			return true
		end
	elseif name=="智慧圣印" then
		if GetTime()-MPPaladinSealWisdomDuration<30 then
			return true
		end
	elseif name=="十字军圣印" then
		if GetTime()-MPPaladinSealCrusaderDuration<30 then
			return true
		end
	elseif name=="命令圣印" then
		if GetTime()-MPPaladinSealCommandDuration<30 then
			return true
		end
	elseif name=="光明圣印" then
		if GetTime()-MPPaladinSealRightDuration<30 then
			return true
		end
	end

	return false
end

-- 获取十字军打击的狂热时间
function MPGetCrusaderStrike()

	if (GetTime()-MPPaladinFrenzyDuration)<30 then
		return true
	end

    MPPaladinFrenzyLayer = 0
	return false

end
