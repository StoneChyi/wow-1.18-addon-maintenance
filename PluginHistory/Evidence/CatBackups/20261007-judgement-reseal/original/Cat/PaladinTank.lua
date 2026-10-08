function MPCatPaladinTankEnsureManaConfig(saved)
    local function percent(value, default, minimum, maximum)
        if type(value) ~= "number" or value ~= value then value = default end
        return math.max(minimum, math.min(maximum, math.floor(value + 0.5)))
    end
    saved.AutoWisdom = saved.AutoWisdom == 1 and 1 or 0
    saved.WisdomEconomy = saved.WisdomEconomy == 1 and 1 or 0
    saved.WisdomEnter = percent(saved.WisdomEnter, 25, 5, 80)
    saved.WisdomExit = percent(saved.WisdomExit, 40, 10, 95)
    if saved.WisdomExit <= saved.WisdomEnter then saved.WisdomExit = saved.WisdomEnter + 5 end
end

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
local tankState = { openingDone = false, recovering = false, manualOverride = false }

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
	local saved = MPPaladinTankSaved[MPPaladinTankConfig]
	if saved.Consecration~=1 or not MPGetTargetDistance() or not FX then return false end
	if saved.Consecration_Level==0 then
        if tankState.recovering and saved.WisdomEconomy==1 then
            if Mana < MPPaladinConsecrationLevel1 then return false end
            CastSpellByName("奉献(等级 1)")
            return true
        end
		if ManaPercent>0.8 then
			CastSpellByName("奉献(等级 5)")
		elseif ManaPercent>0.5 then
			CastSpellByName("奉献(等级 3)")
		elseif Mana>MPPaladinConsecrationLevel1 then
			CastSpellByName("奉献(等级 1)")
		else
			return false
		end
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





-- 防骑起手与低蓝状态只保存在本次会话，不改写公共圣印选择。
local sealManaCache = {}

local function SetRecovery(value)
    if tankState.recovering == value then return end
    tankState.recovering = value
    MPCatPaladinTankRecoveryActive = value
    if type(MPCatPaladinSealApplyAppearance) == "function" then MPCatPaladinSealApplyAppearance() end
end

function MPCatPaladinTankManualSealChanged()
    tankState.manualOverride = true
    tankState.pending = nil
    SetRecovery(false)
end

function MPCatPaladinTankManaOptionsChanged()
    tankState.manualOverride = false
    SetRecovery(false)
end

function MPCatPaladinTankLeave()
    -- 在同一场战斗中尊重主动切换宏；再次使用防骑宏不会立刻夺回圣印。
    tankState.manualOverride = true
    tankState.pending = nil
    tankState.active = false
    SetRecovery(false)
end

local function ResetTankState()
    tankState.openingDone = false
    tankState.manualOverride = false
    tankState.pending = nil
    tankState.config = nil
    tankState.active = false
    SetRecovery(false)
end

local function HostileTarget()
    return UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDead("target")
end

local function SealManaCost(name, rank, fallback)
    local key = name .. (rank or "最高等级")
    if sealManaCache[key] == nil then
        local cost
        if type(MPGetSpellTooltip) == "function" then
            -- MPGetSpellTooltip 不指定等级会取法术书第一个等级，必须显式读取最高等级。
            local tooltipRank = rank
            if not tooltipRank and type(MPGetHighestRankOfSpell) == "function" then
                local highest = MPGetHighestRankOfSpell(name)
                if highest and highest > 0 then tooltipRank = "等级 " .. highest end
            end
            local text = MPGetSpellTooltip(name, tooltipRank)
            if type(text) == "string" then
                local _, _, value = string.find(text, "(%d+)%s*法力")
                if not value then _, _, value = string.find(text, "(%d+)%s*[Mm]ana") end
                cost = tonumber(value)
            end
        end
        -- 无法读取提示时沿用旧循环的保守蓝量界限，不连续尝试未知蓝耗。
        sealManaCache[key] = cost or fallback
    end
    return sealManaCache[key]
end

local function PreparingSealCost(name, threshold)
    local rank
    if Mana < threshold then rank = "等级 1" end
    return SealManaCost(name, rank, threshold > 0 and threshold or 170)
end

local function CanPrepareSeal(name, threshold)
    return MPGetGCD() > 1.4 and MPSpellReady(name) and Mana >= PreparingSealCost(name, threshold)
end

local function CanJudge()
    if not HostileTarget() or not MPSpellReady("审判") or Mana < 76 or MPGetGCD() <= 1.4 then return false end
    if type(IsSpellInRange) == "function" and IsSpellInRange("审判", "target") == 0 then return false end
    if MP_UnitXP and type(UnitXP) == "function" then
        local distance = UnitXP("distanceBetween", "player", "target")
        if distance and distance > 10 then return false end
    end
    return true
end

local function CanCompleteOpening()
    if tankState.openingDone or MPPaladinSealSaved.Seal ~= 4 or not HostileTarget() then return false end
    if MPSeal("正义圣印") then return Mana >= 76 end
    return Mana >= PreparingSealCost("正义圣印", 170) + 76
end

local function UpdateTankState(saved)
    tankState.active = true
    if tankState.config ~= MPPaladinTankConfig then
        tankState.config = MPPaladinTankConfig
        tankState.manualOverride = false
        SetRecovery(false)
    end
    if tankState.pending then
        -- 无 SuperWoW 时可由审判冷却及圣印消耗交叉确认；公共冷却不足以确认。
        if type(MPGetSpellCooldown) == "function" and MPGetSpellCooldown("审判") > 1.5 and not MPSeal("正义圣印") then
            tankState.openingDone = true
            tankState.pending = nil
        elseif GetTime() - tankState.pending.time > 3 then
            tankState.pending = nil
        end
    end
    if not MPInCombat or saved.AutoWisdom ~= 1 or tankState.manualOverride then
        SetRecovery(false)
    elseif tankState.recovering then
        if ManaPercent * 100 >= saved.WisdomExit then SetRecovery(false) end
    elseif ManaPercent * 100 < saved.WisdomEnter then
        -- 只为足够蓝量且审判已经可用的首次起手保留正义；不能一直等待审判冷却。
        local openingReady = CanCompleteOpening() and MPSpellReady("审判")
        if not openingReady then SetRecovery(true) end
    end
end

local function TryOpeningJudgement()
    if tankState.recovering or not CanCompleteOpening() then return false end
    if not MPSpellReady("审判") then return false end
    if not MPSeal("正义圣印") then
        if CanPrepareSeal("正义圣印", 170) then SealJustice() return true end
        return false
    end
    if CanJudge() then
        local _, guid = UnitExists("target")
        tankState.pending = { time = GetTime(), target = guid }
        CastSpellByName("审判")
        return true
    end
    return false
end

local function ConfirmOpening(targetGuid)
    local pending = tankState.pending
    if not pending or not tankState.active or GetTime() - pending.time > 3 then return end
    if pending.target and targetGuid and pending.target ~= targetGuid then return end
    tankState.openingDone = true
    tankState.pending = nil
end

local tankEvents = CreateFrame("Frame", "MPCatPaladinTankRuntime", UIParent)
tankEvents:RegisterEvent("PLAYER_REGEN_ENABLED")
tankEvents:RegisterEvent("PLAYER_DEAD")
tankEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
tankEvents:RegisterEvent("SPELLS_CHANGED")
tankEvents:RegisterEvent("CHARACTER_POINTS_CHANGED")
tankEvents:RegisterEvent("UNIT_CASTEVENT")
tankEvents:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
tankEvents:SetScript("OnEvent", function()
    if event == "PLAYER_REGEN_ENABLED" or event == "PLAYER_DEAD" or event == "PLAYER_ENTERING_WORLD" then
        ResetTankState()
        sealManaCache = {}
    elseif event == "SPELLS_CHANGED" or event == "CHARACTER_POINTS_CHANGED" then
        sealManaCache = {}
    elseif event == "UNIT_CASTEVENT" and arg3 == "CAST" and arg4 == 20271 then
        local _, guid = UnitExists("player")
        if guid and arg1 == guid then ConfirmOpening(arg2) end
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" and type(arg1) == "string" then
        if string.find(arg1, "你的正义审判") then ConfirmOpening() end
    end
end)

local function CastPanelJudgement()
    local choice = MPPaladinSealSaved.Justice
    if THP <= MPPaladinTankSaved[MPPaladinTankConfig].JudgementOutHP or not CanJudge() then return false end
    local names = { [1] = "智慧", [2] = "光明", [3] = "十字军", [4] = "公正" }
    local prefix = names[choice]
    if not prefix or MPBuff(prefix .. "审判", "target") then return false end
    local seal = prefix .. "圣印"
    if not MPSeal(seal) then
        local threshold = choice == 3 and 136 or choice == 4 and 0 or choice == 2 and 178 or 170
        if CanPrepareSeal(seal, threshold) then
            if choice == 1 then SealWisdom()
            elseif choice == 2 then SealRight()
            elseif choice == 3 then SealCrusader()
            else MPCastWithoutNampower(seal) end
            return true
        end
        return false
    end
    CastSpellByName("审判")
    return true
end

local function CastSelectedSeal()
    local choice = tankState.recovering and 1 or MPPaladinSealSaved.Seal
    local names = { [1] = "智慧圣印", [2] = "光明圣印", [3] = "十字军圣印", [4] = "正义圣印", [5] = "命令圣印", [6] = "公正圣印" }
    local name = names[choice]
    if not name then return false end
    if not MPSeal(name) then
        local threshold = (choice == 2 or choice == 5) and 178 or choice == 3 and 136 or choice == 6 and 0 or 170
        if not CanPrepareSeal(name, threshold) then return false end
        if choice == 1 then SealWisdom()
        elseif choice == 2 then SealRight()
        elseif choice == 3 then SealCrusader()
        elseif choice == 4 then SealJustice()
        elseif choice == 5 then SealCommand()
        else MPCastWithoutNampower(name) end
        return true
    end
    if not tankState.recovering and (choice == 4 or choice == 5) and CanJudge() then
        CastSpellByName("审判")
        return true
    end
    return false
end


function MPPallyTank()
	local primaryAttempted = false
	MPCatPaladinApplyControl("TANK", MPPaladinTankConfig)

	-- 下一次防骑宏按键先取消免疫，再继续正常输出；无需目标或进入战斗。
	local saved = MPPaladinTankSaved and MPPaladinTankSaved[MPPaladinTankConfig]
	if not saved then return end
	MPCatPaladinTankEnsureManaConfig(saved)
	if saved and saved.AutoCancelImmunity==1 then
		if MPBuff("圣盾术") then MPCancelBuffByName("圣盾术") end
		if MPBuff("保护之手") then MPCancelBuffByName("保护之手") end
		if MPBuff("保护祝福") then MPCancelBuffByName("保护祝福") end
	end

	if MP_Nampower then
		SetCVar("NP_QueueCastTimeSpells", 0)
	end

	HasTarget = UnitExists("target")
	Mana = UnitMana("player")
	local maxMana = UnitManaMax("player")
	ManaPercent = maxMana > 0 and Mana / maxMana or 0
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
    HasTarget = UnitExists("target")
    THP = UnitHealth("target")
    creature = UnitCreatureType("target") or "其它"
    position = string.find("亡灵,恶魔", creature)
    UpdateTankState(saved)

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

    -- 战斗前准备面板选择的正义圣印；回蓝切换在耗蓝输出前执行。
    if not MPInCombat and MPPaladinSealSaved.Seal == 4 and not MPSeal("正义圣印") then
        if CanPrepareSeal("正义圣印", 170) then SealJustice() return end
    end
    if tankState.recovering and not MPSeal("智慧圣印") and CanPrepareSeal("智慧圣印", 170) then
        SealWisdom()
        return
    end

	-- 奉献：优先级高
	if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Priority==3 then
		if CastConsecration() then
			return
		end
	end

    -- 高优先级奉献仍先执行，其余情况下优先完成首次正义审判。
    if TryOpeningJudgement() then return end

	-- 神圣之盾
	if SSZD and MPPaladinTankSaved[MPPaladinTankConfig].HolyShield==1 then

		if MPPaladinTankSaved[MPPaladinTankConfig].HolyShieldTarget==1 then
			local totName = UnitName("targettarget")
			if totName and totName==UnitName("player") then
				-- 距离
				if MP_UnitXP then 
					local Range = UnitXP("distanceBetween", "player", "target")
					if Range and Range<10 then
						primaryAttempted = true; CastSpellByName("神圣之盾")
					end
				else
					primaryAttempted = true; CastSpellByName("神圣之盾")
				end
			end
		else
			primaryAttempted = true; CastSpellByName("神圣之盾")
		end
	end



	if MPPaladinTankSaved[MPPaladinTankConfig].CrusaderStrike==1 and MPInCombat and GetTime()-MPInCombatTime>MPPaladinTankSaved[MPPaladinTankConfig].CrusaderStrikeTimer then
		-- 根据狂热的持续时间来选择主打技能
		if GetTime()-MPPaladinFrenzyDuration<22 and MPPaladinFrenzyLayer>=3 then
			if SZJ and Mana>=90 then primaryAttempted = true; CastSpellByName("神圣打击")  end
		else
			if SZJ and Mana>=120 then primaryAttempted = true; CastSpellByName("十字军打击")  end
		end
	else
		if SZJ and Mana>=120 then primaryAttempted = true; CastSpellByName("神圣打击")  end
	end

    -- 审判可用时才准备目标审判；冷却或条件不满足不会阻断其他输出。
    if HostileTarget() then
        if CastPanelJudgement() then return end
        if CastSelectedSeal() then return end
    end

	if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Priority==2 and not SZJ then
		if CastConsecration() then
			return
		end
	end

	-- 目标是亡灵、恶魔的时候才尝试使用驱邪术
	if QXS and not SZJ and position and MPPaladinTankSaved[MPPaladinTankConfig].Exorcism==1 and not (tankState.recovering and saved.WisdomEconomy==1) then
		if Mana>=345 then
			CastSpellByName("驱邪术") return
		elseif Mana>=180 then
			CastSpellByName("驱邪术(等级 3)") return
		elseif Mana>=85 then
			CastSpellByName("驱邪术(等级 1)") return
		end
	end



	if MPPaladinTankSaved[MPPaladinTankConfig].Consecration_Priority==1 and not SZJ and not (
        SP and not tankState.recovering and (MPPaladinSealSaved.Seal==4 or MPPaladinSealSaved.Seal==5)
    ) then
		if CastConsecration() then
			return
		end
	end



	-- 种族天赋：主技能之后的空档使用，开战前 3 秒不使用。

	if MPInCombat and GetTime()-MPInCombatTime >= 3 and not primaryAttempted and MPGetGCD()>1.4
		and MPPaladinTankSaved[MPPaladinTankConfig].RacialTraits==1 and MPGetTargetDistance() then
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

	if MP_Nampower then
		SetCVar("NP_QueueCastTimeSpells", 1)
	end

end




