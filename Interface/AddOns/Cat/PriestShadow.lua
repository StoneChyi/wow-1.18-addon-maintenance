if MPPlayerClass ~= "PRIEST" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 暗牧一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：无
--
-- 说明：
-- 
-- -------------------------------------
--
-- 功能配置：

-- 以下功能开关：1开启 0关闭


-- -------------------------------------

-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化


-- 暗影形态
MPPriestShadowform = 0

-- 吸血鬼的拥抱
MPPriestVampiric = 0

-- 精神鞭笞
MPPriestMindFlay = 0

-- 心灵震爆，重置标记
MPPriestMindBlastReset = 0

-- 暗言术：痛 持续时间
MPPainDuration = 18
MPPainRange = 30

-- 3T3.5
MPPriest3Fade = 0

-- -------------------------------------

local MHP,DM,JYS,XXG,TKJC


-- 默认配置
MPPriestShadowConfig = 1


function MPPriestShadow()


	MHP = UnitHealth("player")
	DM = UnitMana("player")
	local percent = UnitHealth("player") / UnitHealthMax("player") * 100
	local percentMana = UnitMana("player") / UnitManaMax("player") * 100
	JYS = MPSpellReady("渐隐术")
	XXG = MPSpellReady("吸血鬼的拥抱")
	TKJC = MPSpellReady("痛苦尖刺")

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPPriestShadowSaved[MPPriestShadowConfig].Target, 0)

	-- 开启自动攻击
	if MPPriestShadowSaved[MPPriestShadowConfig].Target==1 then
		MPStartAttack()
	end

	-- 自动拾取
	if MPPriestShadowSaved[MPPriestShadowConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPPriestShadowSaved[MPPriestShadowConfig].Power==1 then
		MPCatPower()
	end


	if not UnitExists("target") then return end

	-- 在战斗中
	if MPInCombat then

		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and MPPriestShadowSaved[MPPriestShadowConfig].Trinket_Upper==1 then
			if MPPriestShadowSaved[MPPriestShadowConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
				return
			elseif MPPriestShadowSaved[MPPriestShadowConfig].TUBoss==0 then
				UseInventoryItem(13)
				return
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and MPPriestShadowSaved[MPPriestShadowConfig].Trinket_Below==1 then
			if MPPriestShadowSaved[MPPriestShadowConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
				return
			elseif MPPriestShadowSaved[MPPriestShadowConfig].TBBoss==0 then
				UseInventoryItem(14)
				return
			end
		end

		if MPPriestShadowSaved[MPPriestShadowConfig].Soulspeed==1 then
			if MPPriestShadowSaved[MPPriestShadowConfig].SoulspeedBoss==0 or (MPPriestShadowSaved[MPPriestShadowConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		if percent<MPPriestShadowSaved[MPPriestShadowConfig].HealthStone_Value and MPPriestShadowSaved[MPPriestShadowConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPPriestShadowSaved[MPPriestShadowConfig].HerbalTea_Value and MPPriestShadowSaved[MPPriestShadowConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percentMana<MPPriestShadowSaved[MPPriestShadowConfig].HerbalTeaMana_Value and MPPriestShadowSaved[MPPriestShadowConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		-- 特定 种族天赋 --

		if MPPriestShadowSaved[MPPriestShadowConfig].RacialTraits==1 then
			if MPPriestShadowSaved[MPPriestShadowConfig].RacialTraitsBoss==0 or (MPPriestShadowSaved[MPPriestShadowConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
				-- 是否自动开启 人类-感知
				if MPPlayerRace=="Human" then
					local TF = MPSpellReady("感知")
					if TF then CastSpellByName("感知") end
				end

				-- 是否自动开启 兽人-血性狂怒
				if MPPlayerRace=="Orc" then
					local TF = MPSpellReady("血性狂怒")
					if TF then CastSpellByName("血性狂怒") end
				end
		
				-- 是否自动开启 巨魔-狂暴
				if MPPlayerRace=="Troll" then
					local TF = MPSpellReady("狂暴")
					if TF then CastSpellByName("狂暴") end
				end
			end
		end
	end


	local StopMindFlay = MPGetPriestChanneled()

	if MPPriestShadowSaved[MPPriestShadowConfig].MindFlay==1 and MPPriestShadowSaved[MPPriestShadowConfig].SecondMindFlay==1 and MPGetPriestMindFlayCount()>=2 and MPGetBuffApplications("Interface\\Icons\\Spell_Shadow_BlackPlague")<5 then
		StopMindFlay = 0
	end

	if StopMindFlay<=0 then
		-- 暗影形态
		if MPPriestShadowSaved[MPPriestShadowConfig].Shadowform==1 and MPPriestShadowform==1 and not MPBuff("暗影形态") then
			MPCastWithoutNampower("暗影形态")
			return
		end

		-- 心灵之火
		if MPPriestShadowSaved[MPPriestShadowConfig].InnerFire==1 and not MPBuff("心灵之火") then
			MPCast("心灵之火")
			return
		end

		-- 暗言术：痛
		if MPPriestShadowSaved[MPPriestShadowConfig].Pain==1 and not MPGetPainDot("target") then
			MPCast("暗言术：痛")
			return
		end

		-- 吸血鬼的拥抱
		if MPPriestShadowSaved[MPPriestShadowConfig].Vampiric==1 and MPPriestVampiric==1 then
			if XXG and not MPGetVampiricDot() then
				if MPPriestShadowSaved[MPPriestShadowConfig].VampiricBOSS==1 and MPIsBossTarget() then
					MPCast("吸血鬼的拥抱")
					return
				elseif MPPriestShadowSaved[MPPriestShadowConfig].VampiricBOSS==0 then
					MPCast("吸血鬼的拥抱")
					return
				end
			end
		end

		-- 痛苦尖刺
		if MPPriestShadowSaved[MPPriestShadowConfig].MindSpike==1 and TKJC then
			MPCast("痛苦尖刺")
			return
		end




		-- 心灵震爆
		if MPPriestShadowSaved[MPPriestShadowConfig].MindBlast==1 and MPSpellReady("心灵震爆") then -- and MPPriestMindBlastReset==1
			MPCast("心灵震爆")
			return
		end

		-- 渐隐术
		if MPPriest3Fade==0 then

			if MPPriestShadowSaved[MPPriestShadowConfig].Fade==1 and JYS and MPGetBuffLevel("暗影之波","player")>4 then
				MPCast("渐隐术(等级 "..MPPriestShadowSaved[MPPriestShadowConfig].Fade_Value..")")
				return
			end

		else

			if MPPriestShadowSaved[MPPriestShadowConfig].Fade==1 and JYS then
				MPCast("渐隐术(等级 "..MPPriestShadowSaved[MPPriestShadowConfig].Fade_Value..")")
				return
			end

		end


		-- 精神鞭笞
		if MPPriestShadowSaved[MPPriestShadowConfig].MindFlay==1 and MPPriestMindFlay==1 then
			MPCast("精神鞭笞")
			return
		end

	else
		MPPriestMindBlastReset = 1

	end





end

