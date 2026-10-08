-- -------------------------------------
-- 乌龟服 - 多线Dot一键宏
-- 发布日期：2026-05-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 必要条件：SuperWoW
--
--
-- -------------------------------------
--
-- 功能配置：


-- -------------------------------------



function MPMuiltlineDot()

    -- 检测是否有SuperWow模组
    if not MP_SuperWoW then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."未加载SuperWow，自动多线Dot功能无效。|r")
        return 
    end

    if not MP_UnitXP then
        DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."未加载UnitXP，自动多线Dot功能无效。|r")
        return 
    end

	-- 非战斗中，不施放群体dot
	if not MPInCombat and MPMultilineDotSaved.InFight==1 then
		return
	end


    local list = {}
    local count = 0

    -- 主动索敌
    if MPMultilineDotSaved.ScanEnemy==1 then
        MPScanEnemy()
    end

    _,count,_,_,list = MPScanNearbyEnemiesCount()

    if count==0 then
        --pirnt("周围没有敌人")
        return
    end

    --[[
    -- 条件：目标是不是玩家
    if MPMultilineDotSaved.NOPlayer==1 and UnitIsPlayer(key) then
        return
    end
    ]]


    local _, englishClass = UnitClass("player")

	for key, value in pairs(list) do

        -- 条件：目标状态正常，未被CC
        if MPMultilineDotSaved.NoCC==1 and MPCheckAllowAttack(key) then

        -- 条件：目标血量符合设置量
        if UnitHealth(key)>MPMultilineDotSaved.BeginValue then

        -- 条件：目标是否在战斗状态
        if MPMultilineDotSaved.NoCombat==0 or (UnitAffectingCombat(key) and MPMultilineDotSaved.NoCombat==1) then -- 

        -- 条件：目标是不是玩家
        if MPMultilineDotSaved.NOPlayer==0 or (MPMultilineDotSaved.NOPlayer==1 and not UnitIsPlayer(key)) then

            -- 与目标距离
            local inRange = UnitXP("distanceBetween", "player", key)


            -- 全职业打断技能判断
            if englishClass == "PRIEST" then

		        if MPMultilineDotSaved.Pain==1 and not MPGetPainDot(key) then
                    if inRange<MPPainRange then
			            CastSpellByName("暗言术：痛", key)
                        return
                    end
		        end

            elseif englishClass == "WARLOCK" then

		        if MPMultilineDotSaved.Corruption==1 and not MPGetCorruptionDot(key) then
                    if inRange<MPWarlockCorruptionRange then
			            CastSpellByName("腐蚀术", key)
                        return
                    end
		        end


                if MPMultilineDotSaved.CurseDoom==1 and MPSpellReady("厄运诅咒") and not MPBuff("厄运诅咒",key) then
                    if inRange<MPCurseAgonyRange then
                        CastSpellByName("厄运诅咒", key)
                        return
                    end
                end

                if MPMultilineDotSaved.CurseRecklessness==1 and not MPBuff("鲁莽诅咒",key) then
                    if inRange<MPCurseAgonyRange then
                        CastSpellByName("鲁莽诅咒", key)
                        return
                    end
                end

                if MPMultilineDotSaved.CurseElements==1 and not MPBuff("元素诅咒",key) then
                    if inRange<MPCurseAgonyRange then
                        CastSpellByName("元素诅咒", key)
                        return
                    end
                end

                if MPMultilineDotSaved.CurseShadow==1 and not MPBuff("暗影诅咒",key) then
                    if inRange<MPCurseAgonyRange then
                        CastSpellByName("暗影诅咒", key)
                        return
                    end
                end

		        if MPMultilineDotSaved.CurseAgony==1 and not MPGetCurseAgonyDot(key) then
                    if inRange<MPCurseAgonyRange then
			            CastSpellByName("痛苦诅咒", key)
                        return
                    end
		        end

		        if MPMultilineDotSaved.SiphonLife==1 and not MPGetSiphonLifeDot(key) and MPIsDrain() then
                    if inRange<MPWarlockSiphonLifeRange then
			            CastSpellByName("生命虹吸", key)
                        return
                    end
		        end

		        if MPMultilineDotSaved.Immolate==1 and not MPGetImmolateDot(key) and GetTime()-MPImmolateTimer>2 then
                    -- 条件3：目标是否在身后
                    if not UnitXP("behind", key, "player") and inRange<MPWarlockImmolateRange then
			            CastSpellByName("献祭", key)
                        return
                    end
		        end

            elseif englishClass == "DRUID" then

		        if MPMultilineDotSaved.Moonfire==1 and not MPGetMoonfireDot(key) then
                    -- 条件3：目标是否在身后
                    if not UnitXP("behind", key, "player") and inRange<MPDruidMoonfireRange then
			            CastSpellByName("月火术", key)
                        return
                    end
		        end
		        if MPMultilineDotSaved.InsectSwarm==1 and not MPGetInsectSwarmDot(key) then
                    if inRange<MPDruidInsectSwarmRange then
			            CastSpellByName("虫群", key)
                        return
                    end
		        end

            else
                DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."本职业：暂无多线Dot|r")
            end


        end
        end
        end
        end

	end

end


