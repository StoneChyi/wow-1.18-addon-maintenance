if MPPlayerClass ~= "PALADIN" then
    return  -- 终止文件执行
end


-- -------------------------------------
-- 乌龟服 - 防骑一键宏
-- 更新日期：2026-07-29 （后面根据时间来判断版本）
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



-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化



-- 庇护祝福
MPPaladinSanctuary = 0

-- -------------------------------------

local Mana,ManaPercent,GCD,SP,QXS,SZJ,FX,CH,THP,HasTarget
local JudgmentDelay = 0

-- 默认配置
MPPaladinTankConfig = 1



-- 奉献
local function Consecration()
	if Mana<MPPaladinConsecrationLevel5 then
		CastSpellByName("奉献(等级 1)")
	else
		CastSpellByName("奉献")
	end
end

local function CastConsecration()

	-- 是否踩奉献
	if CatPaladinSeal:IsVisible() then
		if MPPaladinSealSaved.Consecration==1 and MPGetTargetDistance() and FX then
			if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Level==0 then
				if ManaPercent>0.8 then
					CastSpellByName("奉献(等级 5)")
				elseif ManaPercent>0.5 then
					CastSpellByName("奉献(等级 3)")
				elseif Mana>MPPaladinConsecrationLevel1 then
					CastSpellByName("奉献(等级 1)")
				end
			else
				CastSpellByName("奉献(等级 "..MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Level..")")
			end

			return true

		elseif MPPaladinSealSaved.Consecration==2 then
			-- 根据配置踩奉献
			if MPPaladinTankSaved[MPPaladinTankConfig].Consecration==1 and MPGetTargetDistance() and FX then

				if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Level==0 then
					if ManaPercent>0.8 then
						CastSpellByName("奉献(等级 5)")
					elseif ManaPercent>0.5 then
						CastSpellByName("奉献(等级 3)")
					elseif Mana>MPPaladinConsecrationLevel1 then
						CastSpellByName("奉献(等级 1)")
					end
				else
					CastSpellByName("奉献(等级 "..MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Level..")")
				end

				return true
			end
		end
	else
		-- 是否踩奉献
		if MPPaladinTankSaved[MPPaladinTankConfig].Consecration==1 and MPGetTargetDistance() and FX then

			if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Level==0 then
				if ManaPercent>0.8 then
					CastSpellByName("奉献(等级 5)")
				elseif ManaPercent>0.5 then
					CastSpellByName("奉献(等级 3)")
				elseif Mana>MPPaladinConsecrationLevel1 then
					CastSpellByName("奉献(等级 1)")
				end
			else
				CastSpellByName("奉献(等级 "..MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Level..")")
			end

			return true
		end
	end

	return false
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
		CastSpellByName("正义圣印(等级 1)")
	else
		CastSpellByName("正义圣印")
	end
end

-- 命令圣印
local function SealCommand()
	if Mana<178 then
		CastSpellByName("命令圣印(等级 1)")
	else
		CastSpellByName("命令圣印")
	end
end

-- 智慧圣印
local function SealWisdom()
	if Mana<170 then
		CastSpellByName("智慧圣印(等级 1)")
	else
		CastSpellByName("智慧圣印")
	end
end

-- 光明圣印
local function SealRight()
	if Mana<178 then
		CastSpellByName("光明圣印(等级 1)")
	else
		CastSpellByName("光明圣印")
	end
end

-- 十字军圣印
local function SealCrusader()
	if Mana<136 then
		CastSpellByName("十字军圣印(等级 1)")
	else
		CastSpellByName("十字军圣印")
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





function MPPallyTank()

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
	SZJ=MPSpellReady("十字军打击")
	FX=MPSpellReady("奉献")
	SSZD=MPSpellReady("神圣之盾")

	local creature = UnitCreatureType("target") or "其它"
    local position = string.find("亡灵,恶魔", creature)

	--保持正义之怒
	if not MPBuff("正义之怒") and MPPaladinTankSaved[MPPaladinTankConfig].RighteousFury==1 then
		CastSpellByName("正义之怒")
		return
	end


	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPPaladinTankSaved[MPPaladinTankConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPPaladinTankSaved[MPPaladinTankConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPPaladinTankSaved[MPPaladinTankConfig].Power==1 then
		MPCatPower()
	end


	if MPBuff("放逐术", "target") then
		return
	end

	-- 在战斗中
	if MPInCombat then
		-- 自动开启饰品
		if GetInventoryItemCooldown("player",13)==0 and MPGetTargetDistance() and MPPaladinTankSaved[MPPaladinTankConfig].Trinket_Upper==1 and MP_Trinket_Upper==1 then
			if MPPaladinTankSaved[MPPaladinTankConfig].TUBoss==1 and MPIsBossTarget() then
				UseInventoryItem(13)
			elseif MPPaladinTankSaved[MPPaladinTankConfig].TUBoss==0 then
				UseInventoryItem(13)
			end
		end
		if GetInventoryItemCooldown("player",14)==0 and MPGetTargetDistance() and MPPaladinTankSaved[MPPaladinTankConfig].Trinket_Below==1 and MP_Trinket_Below==1 then
			if MPPaladinTankSaved[MPPaladinTankConfig].TBBoss==1 and MPIsBossTarget() then
				UseInventoryItem(14)
			elseif MPPaladinTankSaved[MPPaladinTankConfig].TBBoss==0 then
				UseInventoryItem(14)
			end
		end

		if MPPaladinTankSaved[MPPaladinTankConfig].Soulspeed==1 and MPGetTargetDistance() then
			if MPPaladinTankSaved[MPPaladinTankConfig].SoulspeedBoss==0 or (MPPaladinTankSaved[MPPaladinTankConfig].SoulspeedBoss==1 and MPIsBossTarget()) then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理，潜行下不吃药
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100
		if percent<MPPaladinTankSaved[MPPaladinTankConfig].HealthStone_Value and MPPaladinTankSaved[MPPaladinTankConfig].HealthStone==1 then
			MPUseItemByName("特效治疗石")
		end
		if percent<MPPaladinTankSaved[MPPaladinTankConfig].HerbalTea_Value and MPPaladinTankSaved[MPPaladinTankConfig].HerbalTea==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end
		if percent<MPPaladinTankSaved[MPPaladinTankConfig].Righteous_Value and MPPaladinTankSaved[MPPaladinTankConfig].Righteous==1 then
			CastSpellByName("正义壁垒")
		end
		if percent<MPPaladinTankSaved[MPPaladinTankConfig].LayHands_Value and MPPaladinTankSaved[MPPaladinTankConfig].LayHands==1 then
			MPCastSpellWithoutTarget("圣疗术","player")
		end
		local percentMana = UnitMana("player") / UnitManaMax("player") * 100
		if percentMana<MPPaladinTankSaved[MPPaladinTankConfig].HerbalTeaMana_Value and MPPaladinTankSaved[MPPaladinTankConfig].HerbalTeaMana==1 then
			MPUseItemByName("糖水茶")
			MPUseItemByName("诺达纳尔草药茶")
		end

		-- 特定 种族天赋 --

		if MPPaladinTankSaved[MPPaladinTankConfig].RacialTraits==1 and MPGetTargetDistance() then
			if MPPaladinTankSaved[MPPaladinTankConfig].RacialTraitsBoss==0 or (MPPaladinTankSaved[MPPaladinTankConfig].RacialTraitsBoss==1 and MPIsBossTarget()) then
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

				-- 是否自动开启 矮人-石像形态
				if MPPlayerRace=="Dwarf" then
					local TF = MPSpellReady("石像形态")
					if TF then CastSpellByName("石像形态") end
				end
			end
		end


	end


	-- 是否自动取消拯救
	if MPPaladinTankSaved[MPPaladinTankConfig].UnSalvation==1 and ( MPBuff("强效拯救祝福") or MPBuff("拯救祝福") ) then
		MPCancelBuffByName("强效拯救祝福")
		MPCancelBuffByName("拯救祝福")
	end

	-- 自动 小庇护祝福
	if MPPaladinTankSaved[MPPaladinTankConfig].Sanctuary==1 and MPPaladinSanctuary==1 then
		if not MPBuff("强效庇护祝福") and not MPBuff("庇护祝福") then
			CastSpellByName("庇护祝福", "player")
			return
		end
	end

	-- 奉献：优先级高
	if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Priority==3 then
		if CastConsecration() then
			return
		end
	end

	-- 神圣之盾
	if SSZD and MPPaladinTankSaved[MPPaladinTankConfig].HolyShield==1 then

		if MPPaladinTankSaved[MPPaladinTankConfig].HolyShieldTarget==1 then
			local totName = UnitName("targettarget")
			if totName and totName==UnitName("player") then
				-- 距离
				if MP_UnitXP then 
					local Range = UnitXP("distanceBetween", "player", "target")
					if Range and Range<10 then
						CastSpellByName("神圣之盾")
					end
				else
					CastSpellByName("神圣之盾")
				end
			end
		else
			CastSpellByName("神圣之盾")
		end
	end



	if MPPaladinTankSaved[MPPaladinTankConfig].CrusaderStrike==1 and MPInCombat and GetTime()-MPInCombatTime>MPPaladinTankSaved[MPPaladinTankConfig].CrusaderStrikeTimer then
		-- 根据狂热的持续时间来选择主打技能
		if GetTime()-MPPaladinFrenzyDuration<22 and MPPaladinFrenzyLayer>=3 then
			if SZJ and Mana>=90 then CastSpellByName("神圣打击")  end
		else
			if SZJ and Mana>=120 then CastSpellByName("十字军打击")  end
		end
	else
		if SZJ and Mana>=120 then CastSpellByName("神圣打击")  end
	end

	if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Priority==2 and not SZJ then
		if CastConsecration() then
			return
		end
	end

	if HasTarget then

		-- 通过小窗参数 - 审判

		if THP>MPPaladinTankSaved[MPPaladinTankConfig].JudgementOutHP then
			if MPPaladinSealSaved.Justice==1 and not MPBuff("智慧审判", "target") then

				-- 打智慧圣印
				if not MPSeal("智慧圣印") then SealWisdom() return end
				if MPSeal("智慧圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end

				return

			elseif MPPaladinSealSaved.Justice==2 and not MPBuff("光明审判", "target") then

				-- 打光明圣印
				if not MPSeal("光明圣印") then SealRight() return end
				if MPSeal("光明圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end

				return

			elseif MPPaladinSealSaved.Justice==3 and not MPBuff("十字军审判", "target") then

				-- 打十字军圣印
				if not MPSeal("十字军圣印") then SealCrusader() return end
				if MPSeal("十字军圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end

				return

			end
		end

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

		elseif MPPaladinSealSaved.Seal==0 then

			-- 输出

			if MPPaladinSealSaved.Seal==0 then

				local type = 1   -- 1=正义，2=命令

				if MPPaladinTankSaved[MPPaladinTankConfig].Seal_Value==2 then
					type = 1
				elseif MPPaladinTankSaved[MPPaladinTankConfig].Seal_Value==3 then
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

			if SP and Mana>=76 and GCD>1.4 then
				if (MPSeal("正义圣印") or MPSeal("命令圣印")) then CastSpellByName("审判") return end
			end

		end


	--[[
		local J = MPPaladinTankSaved[MPPaladinTankConfig].Judgement
		local J_Value = MPPaladinTankSaved[MPPaladinTankConfig].Judgement_Value

		-- 动态调整审判，存在则强制进行前置审判
		if MPPaladinSealSaved.Justice>0 then
			J = 1
			J_Value = MPPaladinSealSaved.Justice
		end


		-- 前置策略，遇到血量多或Boss目标才上前置审判
		if J==1 then

			-- 是否使用前置圣印（正义圣印、智慧圣印、十字军圣印）
			if J_Value==1 then
				-- 打智慧圣印
				if not MPBuff("智慧审判", "target") and not MPSeal("智慧圣印") and THP>MPPaladinTankSaved[MPPaladinTankConfig].JudgementOutHP then CastSpellByName("智慧圣印")  return end
				if MPSeal("智慧圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
			elseif J_Value==2 then
				-- 打十字军圣印
				if not MPBuff("十字军审判", "target") and not MPSeal("十字军圣印") and THP>MPPaladinTankSaved[MPPaladinTankConfig].JudgementOutHP then CastSpellByName("十字军圣印")  return end
				if MPSeal("十字军圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
			elseif J_Value==3 then
				-- 打光明圣印
				if not MPBuff("光明审判", "target") and not MPSeal("光明圣印") and THP>MPPaladinTankSaved[MPPaladinTankConfig].JudgementOutHP then CastSpellByName("光明圣印") return end
				if MPSeal("光明圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
			end

		end

		-- 中段审判策略

		local M = MPPaladinTankSaved[MPPaladinTankConfig].MiddleJudgement
		local M_Value = MPPaladinTankSaved[MPPaladinTankConfig].MiddleJudgement_Value

		-- 动态调整审判，存在则强制进行前置审判
		if MPPaladinSealSaved.Justice>0 then
			M = 1
			M_Value = MPPaladinSealSaved.Justice
		else
			if (MPSeal("智慧圣印") or MPSeal("十字军圣印") or MPSeal("光明圣印")) and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
		end

		if M==1 and MPInCombat and GetTime()-MPInCombatTime>MPPaladinTankSaved[MPPaladinTankConfig].MiddleJudgementTimer then

			-- 是否使用前置圣印（智慧圣印、十字军圣印）
			if M_Value==1 then
				-- 打智慧圣印
				if not MPBuff("智慧审判", "target") and not MPSeal("智慧圣印") then CastSpellByName("智慧圣印") return end
				if MPSeal("智慧圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
			elseif M_Value==2 then
				-- 打十字军圣印
				if not MPBuff("十字军审判", "target") and not MPSeal("十字军圣印") then CastSpellByName("十字军圣印") return end
				if MPSeal("十字军圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
			elseif M_Value==3 then
				-- 打光明圣印
				if not MPBuff("光明审判", "target") and not MPSeal("光明圣印") then CastSpellByName("光明圣印") return end
				if MPSeal("光明圣印") and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
			end

		end

		if MPPaladinSealSaved.Seal==0 then

			if not MPSeal("正义圣印") and not MPSeal("智慧圣印") and not MPSeal("十字军圣印") and not MPSeal("光明圣印") and Mana>=1000 then
				CastSpellByName("正义圣印")
				return
			elseif not MPSeal("正义圣印") and not MPSeal("智慧圣印") and not MPSeal("十字军圣印") and not MPSeal("光明圣印") and Mana<1000 then
				CastSpellByName("正义圣印(等级 1)")
				return
			end

		elseif MPPaladinSealSaved.Seal==1 then

			if not MPSeal("智慧圣印") then CastSpellByName("智慧圣印") return end

		elseif MPPaladinSealSaved.Seal==2 then

			if not MPSeal("十字军圣印") then CastSpellByName("十字军圣印") return end

		elseif MPPaladinSealSaved.Seal==3 then

			if not MPSeal("光明圣印") then CastSpellByName("光明圣印") return end

		elseif MPPaladinSealSaved.Seal==4 then

			if not MPSeal("命令圣印") then CastSpellByName("命令圣印") return end

		elseif MPPaladinSealSaved.Seal==5 then

			if not MPSeal("正义圣印") then CastSpellByName("正义圣印") return end

		end

		-- 有圣印在身，直接打审判
		if (MPSeal("正义圣印") or MPSeal("命令圣印")) and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
		if MPSeal("智慧圣印") and not MPBuff("智慧审判", "target") and MPPaladinSealSaved.Seal==0 and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
		if MPSeal("十字军圣印") and not MPBuff("十字军审判", "target") and MPPaladinSealSaved.Seal==0 and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
		if MPSeal("光明圣印") and not MPBuff("光明审判", "target") and MPPaladinSealSaved.Seal==0 and SP and Mana>=76 and GCD>1.4 then CastSpellByName("审判") return end
		]]
	end





	-- 目标是亡灵、恶魔的时候才尝试使用驱邪术
	if QXS and not SZJ and position and MPPaladinTankSaved[MPPaladinTankConfig].Exorcism==1 then
		if Mana>=345 then
			CastSpellByName("驱邪术") return
		elseif Mana>=180 then
			CastSpellByName("驱邪术(等级 3)") return
		elseif Mana>=85 then
			CastSpellByName("驱邪术(等级 1)") return
		end
	end



	if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Priority==1 and not SZJ and not SP then
		if CastConsecration() then
			return
		end
	end



	if MP_Nampower then
		SetCVar("NP_QueueCastTimeSpells", 1)
	end

end




