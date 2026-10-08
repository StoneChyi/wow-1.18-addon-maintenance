local _, playerClass = UnitClass("player")
if playerClass ~= "WARRIOR" then
    return  -- 终止文件执行
end

local frame = CreateFrame("Frame")

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
frame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES")
frame:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS")
frame:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")

frame:RegisterEvent("SPELLCAST_START")
frame:RegisterEvent("SPELLCAST_STOP")
frame:RegisterEvent("SPELLCAST_INTERRUPTED")
frame:RegisterEvent("SPELLCAST_FAILED")


-- SuperWow专有事件
frame:RegisterEvent("UNIT_CASTEVENT")
frame:RegisterEvent("RAW_COMBATLOG")

-- 自己的GUID
local PLAYER_GUID = 0


-- 1=武器战（双手） 2=狂暴战（双持）
MPWarriorDPSType = 1

-- 致死打击 标记
MPMortalStrike = 0

-- 嗜血 标记
MPBloodthirst = 0

-- 狂暴姿态
MPWarriorBerserkerStanceID = 3

-- 用于标记死愿和横扫天赋是否存在
MPWarriorDPSDeathWish = 0
MPWarriorDPSDeathWishPower = 10
MPWarriorDPSSweeping = 0
MPWarriorDPSSweepingPower = 20

-- 标记天赋中是否有反击
--MPWarriorCounter = 0

-- 标记当前的武器类型（双手、双持）
MPWarriorTwoHand = 1

-- 英勇打击怒气
MPWarriorHeroicStrike = 15
-- 顺劈斩怒气
MPWarriorCleave = 20
-- 旋风斩怒气
MPWarriorWhirlwind = 25
-- 破甲怒气
MPWarriorSunderArmor = 10
-- 斩杀怒气
MPWarriorExecute = 15

-- 战斗怒吼持续时间
MPWarriorBattleShoutDuration = 120

-- 乱舞
MPWarriorFlurry = 0

-- 猛击施法
MPWarriorSlamCast = 0
MPWarriorSlamCastTimer = 0

-- 冲锋 时间
MPWarrorCharge = 0

-- 当前英勇/顺劈 阈值
MPWarrorYYNQ = 50



-- 战士撕裂监测
local RendCheck = {}

-- 战士破甲监测
local SunderArmorCheck = {}

-- 记录压制时间
local OverpowerTimer = 0
local OverpowerTargetGUID = 0
local OverpowerTimerNoSW = 0

-- 记录反击时间
local CounterTimer = 0
local CounterTargetGUID = 0
local CounterTimerNoSW = 0

-- 战斗怒吼
local BattleShoutTimer = 0


local function OnEvent()

    if event == "PLAYER_LOGIN" then
        if SUPERWOW_STRING then
            -- 获取并保存自己的GUID
            local a,guid = UnitExists("player")
            PLAYER_GUID = guid
        end

    -- 进入战斗事件
    elseif event == "PLAYER_REGEN_DISABLED" then

    -- 离开战斗事件，重置参数
    elseif event == "PLAYER_REGEN_ENABLED" then
        RendCheck = {}
        SunderArmorCheck = {}
        MPWarriorSlamCast = 0

    -- 玩家死亡，重置参数
    elseif event == "PLAYER_DEAD" then
        RendCheck = {}
        MPWarriorSlamCast = 0
        BattleShoutTimer = 0

    -- 施法事件处理，读条类，读条也要处理GCD
    elseif event == "SPELLCAST_START" then

        if arg1=="猛击" then
            MPWarriorSlamCast=1
            MPWarriorSlamCastTimer = GetTime()+(arg2/1000)
        end

    elseif event == "SPELLCAST_STOP" then

        MPWarriorSlamCastTimer = 0
        MPWarriorSlamCast = 0

    elseif event == "SPELLCAST_INTERRUPTED" then

        --message("SPELLCAST_INTERRUPTED")
        MPWarriorSlamCastTimer = 0
        MPWarriorSlamCast = 0

    elseif event == "SPELLCAST_FAILED" then

        --message("SPELLCAST_FAILED")
        MPWarriorSlamCastTimer = 0
        MPWarriorSlamCast = 0

    elseif event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        if string.find( arg1, "你发起了攻击.*闪开了.*" ) then
            OverpowerTimerNoSW = GetTime()
        end

    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        --print(arg1)
        if string.find( arg1, ".*躲闪.*" ) then
            OverpowerTimerNoSW = GetTime()
        elseif string.find( arg1, ".*压制.*" ) then
            OverpowerTimerNoSW = 0
        elseif string.find( arg1, ".*你的反击对.*" ) then        --这里要完整，反击有个同名反击风暴
            CounterTimerNoSW = 0
        end

    elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" then
        --MPMsg("SELF_MISSES - "..arg1)
        if string.find( arg1, ".*你招架住了.*" ) then
            CounterTimerNoSW = GetTime()
        elseif string.find( arg1, ".*你闪躲开了.*" ) then
            CounterTimerNoSW = GetTime()
        elseif string.find( arg1, ".*你格挡开了.*" ) then
            CounterTimerNoSW = GetTime()
        end

    elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" then
        --MPMsg("SELF_HITS - "..arg1)
        if string.find( arg1, ".*被格挡.*" ) then
            CounterTimerNoSW = GetTime()
        end

    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        if string.find( arg1, "你获得了战斗怒吼的效果.*" ) then
            BattleShoutTimer = GetTime()
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

                -- 撕裂 主动
                if arg4 == 11574 then
                    MPMsg("撕裂")
                    RendCheck[arg2] = GetTime()
                    --print(arg2)

                -- 旋风斩
                elseif arg4 == 1680 then
                    MPMsg("旋风斩")

                -- 嗜血
                elseif arg4 == 23894 then
                    MPMsg("嗜血")

                -- 致死打击
                elseif arg4==12294 or arg4==21551 or arg4==21552 or arg4==21553 then
                    MPMsg("致死打击")

                -- 猛击
                elseif arg4 == 45961 then
                    MPMsg("猛击")

                -- 英勇打击
                elseif arg4 == 25286 then
                    MPMsg("英勇打击")

                -- 顺劈斩
                elseif arg4 == 20569 then
                    MPMsg("顺劈斩")

                -- 压制
                elseif arg4 == 11585 then
                    MPMsg("压制")
			        OverpowerTimer=0

                -- 反击
                elseif arg4 == 51630 then
                    MPMsg("反击")
			        CounterTimer=0

                -- 复仇
                elseif arg4 == 25288 then
                    MPMsg("复仇")

                -- 战斗怒吼 7级
                elseif arg4==25289 then
                    MPMsg("战斗怒吼(等级 7)")
                    BattleShoutTimer = GetTime()

                elseif arg4==12292 then
                    MPMsg("横扫")

                elseif arg4==11597 then
                    MPMsg("破甲")

                    SunderArmorCheck[arg2] = GetTime()

                elseif arg4==7922 then -- 11578
                    MPMsg("冲锋(等级 3)")

                    MPWarrorCharge = GetTime()

                end

            end

        end

    -- 战斗日志事件处理
    elseif event == "RAW_COMBATLOG" then
         --message(arg2)
         --message("---------"..arg1.."----------")
         --MPMsg(arg2)

        if arg1 == "CHAT_MSG_COMBAT_SELF_MISSES" then
            if string.find( arg2, "你发起了攻击.*闪开了.*" ) then
                local guid = MPMatchGUID(arg2)
                if guid then
                    OverpowerTimer = GetTime()
                    OverpowerTargetGUID = guid
                end
            end

        elseif arg1 == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" then
            if string.find( arg2, ".*你招架住了.*" ) then
                local guid = MPMatchGUID(arg2)
                if guid then
                    CounterTimer = GetTime()
                    CounterTargetGUID = guid
                end
            elseif string.find( arg2, ".*你闪躲开了.*" ) then
                local guid = MPMatchGUID(arg2)
                if guid then
                    CounterTimer = GetTime()
                    CounterTargetGUID = guid
                end
            elseif string.find( arg1, ".*你格挡开了.*" ) then
                local guid = MPMatchGUID(arg2)
                if guid then
                    CounterTimer = GetTime()
                    CounterTargetGUID = guid
                end
            end

        elseif arg1 == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS" then
            if string.find( arg2, ".*被格挡.*" ) then
                local guid = MPMatchGUID(arg2)
                if guid then
                    CounterTimer = GetTime()
                    CounterTargetGUID = guid
                end
            end

        -- 自己的攻击
        elseif arg1 == "CHAT_MSG_SPELL_SELF_DAMAGE" then

            if string.find( arg2, ".*躲闪.*" ) then
                local guid = MPMatchGUID(arg2)
                if guid then
                    OverpowerTimer = GetTime()
                    OverpowerTargetGUID = guid
                end
            end

        elseif arg1 == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" then
            --message(arg2)
            --message("---------"..arg1.."----------")
            if string.find( arg2, "你的撕裂.*" ) or string.find( arg2, ".*your 撕裂.*" ) then
                local targetGUID = MPMatchGUID(arg2) 
                if targetGUID then
                    RendCheck[targetGUID] = GetTime()
                end
            end

        end

    end


end

-- 设置事件处理函数
frame:SetScript("OnEvent", OnEvent)


-- 战士撕裂状态
function MPWarriorRend()
    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        return MPBuff("撕裂","target")
    end

    -- 获取目标GUID，并确保其存在
    local a,guid=UnitExists("target")
    if not guid then
        return false
    end

    if RendCheck[guid] then
        if GetTime()-RendCheck[guid] < 3.4 then
            return true
        end
    end

    return false
end

function MPGetWarriorRendValue( GUID )
    if RendCheck[GUID] then
        return RendCheck[GUID]
    end

    return 0
end



-- 获取反击、复仇状态
function MPWarriorCounterAttack()
    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        if GetTime()-CounterTimerNoSW<4 then
            return true
        end

        return false
    end

	if GetTime()-CounterTimer<4 then

		-- 是否存在有效目标
		local a,guid=UnitExists("target")
		if not guid then
			return false
		end

		-- 校验GUID是否是触发压制的目标
		if guid == CounterTargetGUID then
			return true
		end
	end

	return false
end



-- 获取压制状态
function MPWarriorOverpower(LeftTime)
    LeftTime = LeftTime or 4

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        if GetTime()-OverpowerTimerNoSW<LeftTime then
            return true
        end

        return false
    end

	if GetTime()-OverpowerTimer<LeftTime then

		-- 是否存在有效目标
		local a,guid=UnitExists("target")
		if not guid then
			return false
		end

		-- 校验GUID是否是触发压制的目标
		if guid == OverpowerTargetGUID then
			return true
		end
	end

	return false
end


function MPGetBattleShout()
    -- 检测是否有SuperWow模组
    if not MP_SuperWoW or MPPlayerLevel<60 then
        if MPBuff("战斗怒吼") then
            return MPWarriorBattleShoutDuration
        else
            return 0
        end
    end

    return MPWarriorBattleShoutDuration-(GetTime()-BattleShoutTimer)
end

-- 一破的监测
function MPGetSunderArmorOnce()

    local _,guid=UnitExists("target")
	if not guid then
		return false
	end

    if SunderArmorCheck[guid] then
        return true
    end

    return false

end


-- 猛击中断机制
function MPWarriorSlamStop()

	if MPWarriorSlamCast==1 then --and GetTime()-MPWarriorSlamCastTimer > 0 then

		-- 正在读条
		SpellStopCasting()

	end

end


-- 英勇打击 顺劈斩 是否激活
function MPWarriorHeroicAction()

    -- print(GetActionText(25))
    -- 我的炉石位置
    -- 用于获取id

	for A=1,172 do
		local _,_,id = GetActionText(A)

        -- 英勇打击 顺劈斩
		if id==25286 or id==20569 or id==45961 then
            --print(A)
            if IsCurrentAction(A) then
                return true
            end
		end
	end

    return false
end

-- 英勇打击类取消
function MPWarriorCancelHeroic()

	-- 这里要先确认英勇打击类已经被激活

    if MPWarriorHeroicAction() then

 	    -- 有目标才处理
	    local _,guid = UnitExists("target")
	    if guid then
		    ClearTarget()
		    TargetUnit(guid)
	    end

    end

	MPStartAttack()

end




-- 战士刷新特性状态
function MPWarriorRefreshInfo()

    MPWarriorBerserkerStanceID = 1
	for i = 1, 4 do
		local _, name, _, id = GetShapeshiftFormInfo(i)
        if name and name=="狂暴姿态" then
            MPWarriorBerserkerStanceID = i
            break
        end
	end


	-- 检测 武器战 or 狂暴战
    MPWarriorSunderArmor = 10
    MPWarriorWhirlwind = 25
    MPWarriorHeroicStrike = 15

	

	-- 武器战
	if MPIsTalentLearned(1, 18)==1 then
		MPWarriorDPSType = 1
	-- 狂暴战
	elseif MPIsTalentLearned(2, 17)==1 then
		MPWarriorDPSType = 2
	-- 盾猛
	elseif MPIsTalentLearned(3, 14)==1 then
		MPWarriorDPSType = 3
	-- 未发现
	else
		MPWarriorDPSType = 0
	end

	-- 检查致死打击天赋
	MPMortalStrike = MPIsTalentLearned(1, 18)

	-- 检查嗜血天赋
	MPBloodthirst = MPIsTalentLearned(2, 17)

	-- 检查死愿天赋
	MPWarriorDPSDeathWish = MPIsTalentLearned(2, 12)

	-- 检查横扫天赋
	MPWarriorDPSSweeping = MPIsTalentLearned(1, 13)

    -- 斩杀怒气天赋
    if MPIsTalentLearned(2,13)==1 then
        MPWarriorExecute = 15 - 2
    elseif MPIsTalentLearned(2,13)==2 then
        MPWarriorExecute = 15 - 5
    else
        MPWarriorExecute = 15
    end

    -- 检查乱舞天赋
    if MPIsTalentLearned(2,15)>0 then
        MPWarriorFlurry = 1
    else
        MPWarriorFlurry = 0
    end


    -- 检查反击天赋
    --MPWarriorCounter = MPIsTalentLearned(1, 8)

	-- 统计T3套装，计算死愿和横扫的怒气消耗
	count = 0
	if MPCheckInventoryItemName(1,"无畏头冠") then count=count+1 end
	if MPCheckInventoryItemName(3,"无畏肩甲") then count=count+1 end
	if MPCheckInventoryItemName(5,"无畏胸铠") then count=count+1 end
	if MPCheckInventoryItemName(6,"无畏束腰") then count=count+1 end
	if MPCheckInventoryItemName(7,"无畏腿甲") then count=count+1 end
	if MPCheckInventoryItemName(8,"无畏战靴") then count=count+1 end
	if MPCheckInventoryItemName(9,"无畏腕甲") then count=count+1 end
	if MPCheckInventoryItemName(10,"无畏护手") then count=count+1 end
	if MPCheckInventoryItemName(11,"无畏指环") then count=count+1 end
	if MPCheckInventoryItemName(12,"无畏指环") then count=count+1 end
	if count >= 2 then
		MPWarriorDPSDeathWishPower = 0
		MPWarriorDPSSweepingPower = 10
	end

	-- 统计T3.5套装，计算英勇打击、破甲、旋风斩的怒气消耗
    count = 0
	if MPCheckInventoryItemName(1,"兄弟会头盔") then count=count+1 end
	if MPCheckInventoryItemName(2,"兄弟会项链") then count=count+1 end
	if MPCheckInventoryItemName(3,"兄弟会肩甲") then count=count+1 end
	if MPCheckInventoryItemName(5,"兄弟会胸甲") then count=count+1 end
	if MPCheckInventoryItemName(7,"兄弟会护腿") then count=count+1 end
	if MPCheckInventoryItemName(8,"兄弟会胫甲") then count=count+1 end
    if count >= 3 then
        MPWarriorSunderArmor = MPWarriorSunderArmor - 5
        MPWarriorWhirlwind = MPWarriorWhirlwind - 5
        MPWarriorHeroicStrike = MPWarriorHeroicStrike - 5
    end
    
    MPWarriorHeroicStrike = MPWarriorHeroicStrike - MPIsTalentLearned(1, 1)

	-- 是否有点出震荡猛击
	MPWarriorTankConcussion = MPIsTalentLearned(3, 19)
	-- 是否有点出盾牌猛击
	MPWarriorTankShieldSlam = MPIsTalentLearned(3, 14)

	-- 获取当前的武器状态
	if MPIsTwoHand() then
		MPWarriorTwoHand = 1
	else
		MPWarriorTwoHand = 2
	end

    -- 生命宝石标记
	if MPCheckInventoryItemName(13,"生命宝石") then MPWarriorLifeJewel=13 end
	if MPCheckInventoryItemName(14,"生命宝石") then MPWarriorLifeJewel=14 end

    -- 战斗怒吼持续时间
    MPWarriorBattleShoutDuration = 120
    MPWarriorBattleShoutDuration = MPWarriorBattleShoutDuration * (1+(MPIsTalentLearned(2,1)*0.12))

    --[[
    -- 顺劈斩怒气 1.18.1
    MPWarriorCleave = 20 - MPIsTalentLearned(2,11)
    ]]

end

