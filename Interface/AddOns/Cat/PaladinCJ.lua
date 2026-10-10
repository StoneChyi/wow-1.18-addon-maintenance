if MPPlayerClass ~= "PALADIN" then
    return  -- 终止文件执行
end


-- -------------------------------------
-- 乌龟服 - 惩戒骑一键宏
-- 更新日期：2026-07-22 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
--
-- -------------------------------------
--
-- 功能配置：
-- 注：修改以下配置，需要在游戏中/reload，或者小退让配置生效
-- 
-- 主开关

-- 以下功能开关：1开启 0关闭

local AUTO_CJ_Type = 1						-- 1=自动判断，2=法伤骑，3=力爆骑

local AUTO_CJ_Trinket_Delay = 3				-- 进入战斗后，3秒后才允许使用饰品


-- 输出流程辅助配置：


-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化

-- 圣洁光环ID
MPPaladinDevotionAura = 0
MPPaladinDevotionAuraID = 7

-- 天赋是否点出忏悔
MPPaladinRepentance = 0

-- 奉献等级对应的蓝耗
MPPaladinConsecrationLevel1 = 120
MPPaladinConsecrationLevel3 = 290
MPPaladinConsecrationLevel5 = 505

-- 驱邪术
MPPaladinExorcismLevel1 = 85
MPPaladinExorcismLevel3 = 180
MPPaladinExorcismLevel6 = 345

-- 神圣威能的持续时间
MPPaladinHolyStrikeDuration = 0
-- 狂热的持续时间
MPPaladinFrenzyLayer = 0
MPPaladinFrenzyDuration = 0

-- 目标的审判
MPPaladinTargetJudgment = ""

-- 正义圣印持续时间
MPPaladinSealJusticeDuration = 0
-- 智慧圣印持续时间
MPPaladinSealWisdomDuration = 0
-- 十字军圣印持续时间
MPPaladinSealCrusaderDuration = 0
-- 命令圣印持续时间
MPPaladinSealCommandDuration = 0
-- 光明圣印持续时间
MPPaladinSealRightDuration = 0

-- 命令圣印天赋是否点出
MPPaladinSealCommand = 0

-- 正义圣印天赋是否点满
MPPaladinSealJustice = 0

-- -------------------------------------

local Mana,ManaPercent,GCD,SP,QXS,SZJ,FX,CH,THP,HasTarget,FNZC


-- 默认配置
MPPaladinCJConfig = 1


-- 奉献
local function Consecration()
	if Mana<MPPaladinConsecrationLevel5 then
		CastSpellByName("奉献(等级 1)")
	else
		CastSpellByName("奉献")
	end
end

local function CastConsecration()
	local saved = MPPaladinCJSaved[MPPaladinCJConfig]
	if saved.Consecration~=1 or not MPGetTargetDistance() or not FX then return false end
	if saved.Consecration_Level==0 then
		Consecration()
	else
		CastSpellByName("奉献(等级 "..saved.Consecration_Level..")")
	end
	return true
end

local function Exorcism()
	if Mana<MPPaladinExorcismLevel6 then
		CastSpellByName("驱邪术(等级 1)")
	else
		CastSpellByName("驱邪术")
	end
end

-- 正义圣印
local function SealJustice()
	if Mana<170 then
		MPCastWithoutNampower("正义圣印(等级 1)")
	else
		MPCastWithoutNampower("正义圣印")
	end
end

-- 命令圣印
local function SealCommand()
	if Mana<178 then
		MPCastWithoutNampower("命令圣印(等级 1)")
	else
		MPCastWithoutNampower("命令圣印")
	end
end

-- 智慧圣印
local function SealWisdom()
	if Mana<170 then
		MPCastWithoutNampower("智慧圣印(等级 1)")
	else
		MPCastWithoutNampower("智慧圣印")
	end
end

-- 光明圣印
local function SealRight()
	if Mana<178 then
		MPCastWithoutNampower("光明圣印(等级 1)")
	else
		MPCastWithoutNampower("光明圣印")
	end
end

-- 光明圣印
local function SealCrusader()
	if Mana<136 then
		MPCastWithoutNampower("十字军圣印(等级 1)")
	else
		MPCastWithoutNampower("十字军圣印")
	end
end

-- 神圣打击
local function HolyStrike()
	if Mana<90 then
		CastSpellByName("神圣打击(等级 1)")
	else
		CastSpellByName("神圣打击")
	end
end

-- 十字军打击
local function CrusaderStrike()
	if Mana<120 then
		CastSpellByName("十字军打击(等级 1)")
	else
		CastSpellByName("十字军打击")
	end
end


-- 愤怒之锤
local function HammerWrath()
	if Mana<295 then
		CastSpellByName("愤怒之锤(等级 1)")
	else
		CastSpellByName("愤怒之锤")
	end
end




local function SelectedSealChoice()
    local choice = MPPaladinSealSaved.Seal
    if choice == 0 then
        local saved = MPPaladinCJSaved[MPPaladinCJConfig]
        if saved.Seal_Value == 2 then return 4 end
        if saved.Seal_Value == 3 then return 5 end
        if MPPaladinSealCommand == 0 or MPPaladinSealJustice ~= 0 then return 4 end
        return 5
    end
    return choice
end

local function PrepareSelectedSeal(manaBudget)
    local choice = SelectedSealChoice()
    local names = { [1] = "智慧圣印", [2] = "光明圣印", [3] = "十字军圣印", [4] = "正义圣印", [5] = "命令圣印", [6] = "公正圣印" }
    local name = names[choice]
    if not name then return false end
    Mana = math.min(UnitMana("player"), manaBudget)
    local threshold = (choice == 2 or choice == 5) and 178 or choice == 3 and 136 or choice == 6 and 0 or 170
    if not MPCatPaladinCanPrepareSeal(name, threshold, Mana) then return false end
    if choice == 1 then SealWisdom()
    elseif choice == 2 then SealRight()
    elseif choice == 3 then SealCrusader()
    elseif choice == 4 then SealJustice()
    elseif choice == 5 then SealCommand()
    else MPCastWithoutNampower(name) end
    return true
end

local function JudgeAndRestoreSeal()
    return MPCatPaladinJudgeAndReseal("RET:" .. MPPaladinCJConfig, SelectedSealChoice(), PrepareSelectedSeal)
end

local function PanelJudgementNeeded()
    local names = { [1] = "智慧", [2] = "光明", [3] = "十字军", [4] = "公正" }
    local prefix = names[MPPaladinSealSaved.Justice]
    return prefix and UnitHealth("target") > MPPaladinCJSaved[MPPaladinCJConfig].JudgementOutHP
        and not MPBuff(prefix .. "审判", "target")
end

local function CastPanelJudgement()
    local choice = MPPaladinSealSaved.Justice
    if not PanelJudgementNeeded() or not MPCatPaladinCanJudge() then return false end
    local prefixes = { [1] = "智慧", [2] = "光明", [3] = "十字军", [4] = "公正" }
    local prefix = prefixes[choice]
    if not prefix or MPBuff(prefix .. "审判", "target") then return false end
    local name = prefix .. "圣印"
    if not MPSeal(name) then
        Mana = UnitMana("player")
        local threshold = choice == 3 and 136 or choice == 4 and 0 or choice == 2 and 178 or 170
        if not MPCatPaladinCanPrepareSeal(name, threshold, Mana) then return false end
        if choice == 1 then SealWisdom()
        elseif choice == 2 then SealRight()
        elseif choice == 3 then SealCrusader()
        else MPCastWithoutNampower(name) end
        return true
    end
    return JudgeAndRestoreSeal()
end

function MPPaladinCJSpell()
	if type(MPCatPaladinTankLeave) == "function" then MPCatPaladinTankLeave() end
	MPCatPaladinApplyControl("RET", MPPaladinCJConfig)
	if MP_Nampower then
		SetCVar("NP_QueueCastTimeSpells", 0)
	end

	HasTarget = UnitExists("target")
	Mana = UnitMana("player")
	ManaPercent = UnitMana("player") / UnitManaMax("player")
	THP = UnitHealth("target")
	GCD = MPGetGCD()
	SP=MPSpellReady("审判")
	QXS=MPSpellReady("驱邪术")
	SZJ=MPPaladinCJSaved[MPPaladinCJConfig].Strike==1 and MPSpellReadyOffset("十字军打击", 1.0)
	FX=MPSpellReadyOffset("奉献",1.0)
	FNZC=MPSpellReady("愤怒之锤")
	if MPPaladinRepentance==1 then CH=MPSpellReady("忏悔") end

	local creature = UnitCreatureType("target") or "其它"
    local position = string.find("亡灵,恶魔", creature)


	--保持圣洁光环，如果存在的话
	if not MPGetShape(MPPaladinDevotionAuraID) and MPPaladinCJSaved[MPPaladinCJConfig].HolinessAura==1 and MPPaladinDevotionAura==1 then
		CastShapeshiftForm(MPPaladinDevotionAuraID)
		return
	end

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPPaladinCJSaved[MPPaladinCJConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPPaladinCJSaved[MPPaladinCJConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPPaladinCJSaved[MPPaladinCJConfig].Power==1 then
		MPCatPower()
	end


	if MPBuff("放逐术", "target") then
		return
	end


	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MP_Trinket_Upper==1 and GetTime()-MPInCombatTime>AUTO_CJ_Trinket_Delay and MPGetTargetDistance() and MPPaladinCJSaved[MPPaladinCJConfig].Trinket_Upper==1 then
			if MPPaladinCJSaved[MPPaladinCJConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPPaladinCJSaved[MPPaladinCJConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MP_Trinket_Below==1 and GetTime()-MPInCombatTime>AUTO_CJ_Trinket_Delay and MPGetTargetDistance() and MPPaladinCJSaved[MPPaladinCJConfig].Trinket_Below==1 then
			if MPPaladinCJSaved[MPPaladinCJConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPPaladinCJSaved[MPPaladinCJConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPPaladinCJSaved[MPPaladinCJConfig].Soulspeed==1 and MPGetTargetDistance() then
			if MPPaladinCJSaved[MPPaladinCJConfig].SoulspeedBoss==0 or (MPPaladinCJSaved[MPPaladinCJConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPPaladinCJSaved[MPPaladinCJConfig].HealthStone_Value and MPPaladinCJSaved[MPPaladinCJConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPPaladinCJSaved[MPPaladinCJConfig].HerbalTea_Value and MPPaladinCJSaved[MPPaladinCJConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPPaladinCJSaved[MPPaladinCJConfig].HerbalTeaMana_Value and MPPaladinCJSaved[MPPaladinCJConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		if percent<MPPaladinCJSaved[MPPaladinCJConfig].Protection_Value and MPPaladinCJSaved[MPPaladinCJConfig].Protection==1 then
			MPCastSpellWithoutTarget("保护之手","player")
		end
		if percent<MPPaladinCJSaved[MPPaladinCJConfig].DivineShield_Value and MPPaladinCJSaved[MPPaladinCJConfig].DivineShield==1 then
			CastSpellByName("圣盾术")
		end

		-- 特定 种族天赋 --

		if MPPaladinCJSaved[MPPaladinCJConfig].RacialTraits==1 and MPGetTargetDistance() then
			if MPPaladinCJSaved[MPPaladinCJConfig].RacialTraitsBoss==0 or (MPPaladinCJSaved[MPPaladinCJConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

	else

		-- 脱战

		-- 圣契复位

		if MPPaladinCJSaved[MPPaladinCJConfig].Relic==1 then
			MPEquipItemByName(MPPaladinCJSaved[MPPaladinCJConfig].Relic_Normal, 9)
		end

	end


    -- 审判后尚未补印时，先完成补印，再执行主攻技能。
    if MPCatPaladinFinishReseal("RET:" .. MPPaladinCJConfig, SelectedSealChoice(), PrepareSelectedSeal) then return end

	if MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Priority==3 then
		if CastConsecration() then
			return
		end
	end

    -- 辅助审判就绪时先准备/释放，不能让正义或命令消耗它的冷却。
    if CastPanelJudgement() then return end

	-- 主攻技能策略
	if SZJ then

		if MPPaladinCJSaved[MPPaladinCJConfig].Strike_Value == 1 then

			-- 只打神圣打击
			HolyStrike()

		elseif MPPaladinCJSaved[MPPaladinCJConfig].Strike_Value == 2 then

			-- 主打神圣打击
			if GetTime()-MPPaladinHolyStrikeDuration>7 then
				HolyStrike()
			elseif not MPGetCrusaderStrike() or MPPaladinFrenzyLayer<3 then
				CrusaderStrike()
			elseif MPGetCrusaderStrike() and MPPaladinFrenzyLayer==3 and (GetTime()-MPPaladinFrenzyDuration)>20 then
				CrusaderStrike()
			else
				HolyStrike()
			end

		elseif MPPaladinCJSaved[MPPaladinCJConfig].Strike_Value == 3 then

			-- 主打十字军打击
			if not MPGetCrusaderStrike() then
				CrusaderStrike()
			elseif MPGetCrusaderStrike() and MPPaladinFrenzyLayer<2 then
				CrusaderStrike()
			else
				if GetTime()-MPPaladinHolyStrikeDuration>13 then
					HolyStrike()
				else
					CrusaderStrike()
				end
			end

		elseif MPPaladinCJSaved[MPPaladinCJConfig].Strike_Value == 4 then

			-- 只打十字军打击
			CrusaderStrike()


		elseif MPPaladinCJSaved[MPPaladinCJConfig].Strike_Value == 5 then

			-- 先叠满三层狂热，之后主打神圣打击；剩余十秒时优先补狂热。
			if not MPGetCrusaderStrike() or MPPaladinFrenzyLayer < 3
				or (GetTime() - MPPaladinFrenzyDuration) >= 20 then
				CrusaderStrike()
			else
				HolyStrike()
			end
		end


	end


	if MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Priority==2 and not SZJ then
		if CastConsecration() then
			return
		end
	end


	-- 支持远距离的技能
    if UnitExists("target") and MP_UnitXP then

		local rang = UnitXP("distanceBetween", "player", "target")
		if rang>3 then
			if rang<=20 then

				-- 目标是BOSS级别使用忏悔
				if MPPaladinCJSaved[MPPaladinCJConfig].Repentance==1 and MPIsBossTarget() and CH and Mana>=60 then
					CastSpellByName("忏悔")
				end

			elseif rang<=30 then

				-- 愤怒之锤
				if MPPaladinCJSaved[MPPaladinCJConfig].HammerWrath==1 and (UnitHealth("target") / UnitHealthMax("target"))<0.2 and FNZC and MPIsBossTarget() then
					HammerWrath()
					return
				end

				-- 目标是亡灵、恶魔的时候才尝试使用驱邪术
				if QXS and position and MPPaladinCJSaved[MPPaladinCJConfig].Exorcism==1 and not SZJ then
					Exorcism()
				end

			end

		end


    end

	-- 有目标才准备圣印
	if HasTarget then

		-- 圣契

		if MPPaladinCJSaved[MPPaladinCJConfig].Relic==1 and GCD<0.3 then
			if MPPaladinCJSaved[MPPaladinCJConfig].RelicBoss==0 or (MPPaladinCJSaved[MPPaladinCJConfig].RelicBoss==1 and MPIsBossTarget()) then
				local percentHealth = UnitHealth("target") / UnitHealthMax("target") * 100
				if percentHealth < 35 then
					MPEquipItemByName(MPPaladinCJSaved[MPPaladinCJConfig].Relic_Low, 9)
				else
					MPEquipItemByName(MPPaladinCJSaved[MPPaladinCJConfig].Relic_Normal, 9)
				end
			end
		end

        -- 辅助审判冷却时继续正常输出，不反复切换圣印或空等。

		-- 通过小窗参数 - 圣印

		if MPPaladinSealSaved.Seal==1 then

			-- 保持智慧圣印
			if not MPSeal("智慧圣印") then SealWisdom() return end

		elseif MPPaladinSealSaved.Seal==2 then

			-- 保持光明圣印
			if not MPSeal("光明圣印") then SealRight() return end

		elseif MPPaladinSealSaved.Seal==3 then

			-- 保持十字军圣印
			if not MPSeal("十字军圣印") then SealCrusader() return end

		elseif MPPaladinSealSaved.Seal==4 then

			-- 保持正义圣印
			if not MPSeal("正义圣印") then SealJustice() return end
			if not PanelJudgementNeeded() and MPCatPaladinCanJudge() then
				if (MPSeal("正义圣印") or MPSeal("命令圣印")) then JudgeAndRestoreSeal() return end
			end

		elseif MPPaladinSealSaved.Seal==5 then

			-- 保持命令圣印
			if not MPSeal("命令圣印") then SealCommand() return end
			if not PanelJudgementNeeded() and MPCatPaladinCanJudge() then
				if (MPSeal("正义圣印") or MPSeal("命令圣印")) then JudgeAndRestoreSeal() return end
			end

		elseif MPPaladinSealSaved.Seal==6 then
			-- 保持公正圣印；是否施放公正审判由上面的审判选项决定。
			if not MPSeal("公正圣印") then MPCastWithoutNampower("公正圣印") return end

		elseif MPPaladinSealSaved.Seal==0 then

			-- 输出

			if MPPaladinSealSaved.Seal==0 then

				local type = 1   -- 1=正义，2=命令

				if MPPaladinCJSaved[MPPaladinCJConfig].Seal_Value==2 then
					type = 1
				elseif MPPaladinCJSaved[MPPaladinCJConfig].Seal_Value==3 then
					type = 2
				else
					if MPPaladinSealCommand==0 then
						-- 未点出命令圣印
						type = 1
					elseif MPPaladinSealJustice==0 and MPPaladinSealCommand==1 then
						-- 未点出强化正义圣印，并有命令圣印
						type = 2
					end
				end

				if type==1 then
					-- 法伤骑
					if not MPSeal("正义圣印") then
						SealJustice()
					end

				else
					-- 力爆骑
					if not MPSeal("命令圣印") then
						SealCommand()
					end

				end

			end

			if not PanelJudgementNeeded() and MPCatPaladinCanJudge() then
				if (MPSeal("正义圣印") or MPSeal("命令圣印")) then JudgeAndRestoreSeal() return end
			end

		end

	end


	-- 愤怒之锤
	if MPPaladinCJSaved[MPPaladinCJConfig].HammerWrath==1 and (UnitHealth("target") / UnitHealthMax("target"))<0.2 and FNZC and MPIsBossTarget() then
		if MPPaladinCJSaved[MPPaladinCJConfig].HammerWrathBoss==0 or (MPPaladinCJSaved[MPPaladinCJConfig].HammerWrathBoss==1 and MPIsBossTarget()) then
			HammerWrath()
			return
		end
	end

	-- 目标是亡灵、恶魔的时候才尝试使用驱邪术
	if QXS and position and MPPaladinCJSaved[MPPaladinCJConfig].Exorcism==1 and not SZJ then
		Exorcism()
	end

	-- 目标是BOSS级别使用忏悔
	if MPPaladinCJSaved[MPPaladinCJConfig].Repentance==1 and CH and Mana>=60 then
		if MPPaladinCJSaved[MPPaladinCJConfig].RepentanceBoss==0 or (MPPaladinCJSaved[MPPaladinCJConfig].RepentanceBoss==1 and MPIsBossTarget()) then
			if (UnitAttackSpeed("player")-MPGetMainHandLeft())<0.6 then
				CastSpellByName("忏悔")
			end
		end
	end

	if MPPaladinCJSaved[MPPaladinCJConfig].Consecration_Priority==1 and not SZJ and not SP then
		if CastConsecration() then
			return
		end
	end

	if MP_Nampower then
		SetCVar("NP_QueueCastTimeSpells", 1)
	end

end



