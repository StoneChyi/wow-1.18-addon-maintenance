if MPPlayerClass ~= "DRUID" then
    return  -- 终止文件执行
end

-- -------------------------------------
-- 乌龟服 - 猫德一键宏
-- 更新日期：2026-07-29 （后面根据时间来判断版本）
-- 发布者：妖姬变 - 卡拉赞 - 亚服
-- 有问题游戏里或者kook-德鲁伊频道交流
--
-- 可选条件：SuperWoW
-- SuperWoW优势1可以更加准确获得扫击、撕扯的持续时间（特别是在团队副本，避免目标身上debuff过多时可能丢失的可能性），可支持多只猫的环境下计算自己的扫击、撕扯
--
-- -------------------------------------
--
-- 功能配置：
-- 注：修改以下配置，需要在游戏中/reload，或者小退让配置生效
-- 
-- 主开关

-- 以下功能开关：1开启 0关闭

local AUTO_Cat_Trinket_Delay = 0			-- 进入战斗后，3秒后才允许使用饰品


-- 进阶配置（非熟练，请勿使用）：


-- -------------------------------------


-- -------------------------------------
-- 全局变量，可以直接调用，不需要函数访问，以提高宏的性能
-- 以下参数请勿手动修改，插件会自动进行变化




MPDruidCatPVP = 0
MPDruidCatTest = 0

-- 临时变量 -------------------------------------

local myPower,DM,GCD,GCP,THP,MPRake,MPRip,BEHIND,PCD,WS,JLZH
local playerBuffs
local targetBuffs
local TargetDistance = false
local TargetBOSS = false

local Timer = 0
local SlowRun = 0

-- 默认配置
MPDruidCatConfig = 1

-------------------------------------------------

local function CatDotReset()

	if not MP_SuperWoW then
		return
	end

	-- 续杯保险丝
	if MPInCombat then

		-- 先检查目标是否存在
		local hasTarget,guid = UnitExists("target")
		if not hasTarget then
			return
		end

		-- 爪击保险
		if MPGetRakeDot() and MPDruidRateJumpTimer-Timer < -3.0 then
			MPResetRakeDot(guid)
			--DEFAULT_CHAT_FRAME:AddMessage("爪击续杯失败，重置计时！")
		end

		-- 撕扯保险
		if MPGetRipDot() and MPDruidRipJumpTimer-Timer < -2.0 then
			MPResetRipDot(guid)
			--DEFAULT_CHAT_FRAME:AddMessage("撕扯续杯失败，重置计时！")
		end

	end
end


-- 命令入口
function MPCat(type)


	-- 无参数强制打法类型，则通过配置来决定
	-- 一键宏的技能模式，取值范围(1,2,3)
	if not type then
		type = 1
	else
		if type < 1 or type > 6 then
			DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."Cat()传递错误参数，将自动使用默认值！|r")
			type = 1
		end
	end

	-- 确保在豹子形态下
	if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and MPDruidCatShapeshiftID>0 then
		if not MPGetShape(MPDruidCatShapeshiftID) then
			CastShapeshiftForm(MPDruidCatShapeshiftID)
			return
		end
	end
	--[[
	if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 then
		if not MPBuff("猎豹形态") then
			CastSpellByName("猎豹形态")
		end
	end
	]]

	------------------

	playerBuffs = MPBuffList()
	targetBuffs = MPBuffList("target")

	myPower = UnitMana("player")
	Timer = GetTime()

	-- 在潜行状态
	if playerBuffs["潜行"] and MPDruidCatSaved[MPDruidCatConfig].Prowl==1 then

		if targetBuffs["放逐术"] then
			return
		end

		MPStopAttack()

		-- 潜行时，可以预先开启猛虎之怒
		if MPDruidCatSaved[MPDruidCatConfig].TigerFury==1 and (not MPMHTimer or Timer-MPMHTimer>10) and myPower>=80 then
			CastSpellByName("猛虎之怒")
			MPMHTimer=Timer
		end

		if MPTargetBleed then
			-- 目标可流血用突袭
			CastSpellByName("突袭")
			return
		else
			-- 目标不可流血就毁灭
			CastSpellByName("毁灭")
			return
		end

		-- 潜行下，无需后续流程
		return

	end

	if not MPInCombat then
		if MPDruidCatSaved[MPDruidCatConfig].TigerFury==1 and (not MPMHTimer or Timer-MPMHTimer>10) and myPower>=80 then
			CastSpellByName("猛虎之怒")
			MPMHTimer=Timer
		end
	end

	DM = MPDruidMana()
	GCD = MPGetGCD()
	GCP = GetComboPoints("target")
	BEHIND = MPCheckBehind(MPDruidCatSaved[MPDruidCatConfig].UnitXP)
	WS = MPSpellReady("畏缩")
	JLZH = MPSpellReady("精灵之火（野性）")
	THP = UnitHealth("target")
	TargetDistance = MPGetTargetDistance()
	TargetBOSS = MPIsBossTarget()

	-- 确认目标的存活和转火
	MPAutoSwitchTarget(MPDruidCatSaved[MPDruidCatConfig].Target)

	-- 开启自动攻击
	MPStartAttack()

	-- 自动拾取
	if MPDruidCatSaved[MPDruidCatConfig].Pick==1 then
		MPAutoLoot()
	end

	-- 功能药水
	if MPDruidCatSaved[MPDruidCatConfig].Power==1 then
		MPCatPower()
	end


	if targetBuffs["放逐术"] then
		return
	end


	-- 在战斗中
	if MPInCombat and (Timer-SlowRun>0) then


		if MPDruidCatSaved[MPDruidCatConfig].Ashamane==1 then
			if GCP>=(25-MPDruidPrimalFury-2) and MPDruidPrimalFury>=20 then
				-- 自动开启饰品
				if MP_Trinket_Upper==1 then
					if TargetDistance and MPDruidCatSaved[MPDruidCatConfig].Trinket_Upper==1 and GetInventoryItemCooldown("player",13)==0 then
						if MPDruidCatSaved[MPDruidCatConfig].TUBoss==1 and TargetBOSS then
							UseInventoryItem(13)
						elseif MPDruidCatSaved[MPDruidCatConfig].TUBoss==0 then
							UseInventoryItem(13)
						end
					end
				end
				if MP_Trinket_Below==1 then
					if TargetDistance and MPDruidCatSaved[MPDruidCatConfig].Trinket_Below==1 and GetInventoryItemCooldown("player",14)==0 then
						if MPDruidCatSaved[MPDruidCatConfig].TBBoss==1 and TargetBOSS then
							UseInventoryItem(14)
						elseif MPDruidCatSaved[MPDruidCatConfig].TBBoss==0 then
							UseInventoryItem(14)
						end
					end
				end
			end
		else
			-- 自动开启饰品
			if MP_Trinket_Upper==1 then
				if TargetDistance and MPDruidCatSaved[MPDruidCatConfig].Trinket_Upper==1 and Timer-MPInCombatTime>AUTO_Cat_Trinket_Delay and GetInventoryItemCooldown("player",13)==0 then
					if MPDruidCatSaved[MPDruidCatConfig].TUBoss==1 and TargetBOSS then
						UseInventoryItem(13)
						return
					elseif MPDruidCatSaved[MPDruidCatConfig].TUBoss==0 then
						UseInventoryItem(13)
						return
					end
				end
			end
			if MP_Trinket_Below==1 then
				if TargetDistance and MPDruidCatSaved[MPDruidCatConfig].Trinket_Below==1 and Timer-MPInCombatTime>AUTO_Cat_Trinket_Delay and GetInventoryItemCooldown("player",14)==0 then
					if MPDruidCatSaved[MPDruidCatConfig].TBBoss==1 and TargetBOSS then
						UseInventoryItem(14)
						return
					elseif MPDruidCatSaved[MPDruidCatConfig].TBBoss==0 then
						UseInventoryItem(14)
						return
					end
				end
			end
		end

		if MPDruidCatSaved[MPDruidCatConfig].Soulspeed==1 and TargetDistance then
			if MPDruidCatSaved[MPDruidCatConfig].SoulspeedBoss==1 and TargetBOSS then
				MPUseItemByNameToSelf("魂能之速")
			elseif MPDruidCatSaved[MPDruidCatConfig].SoulspeedBoss==0 then
				MPUseItemByNameToSelf("魂能之速")
			end
		end

		-- 血量危险时处理
		local percent = UnitHealth("player") / UnitHealthMax("player") * 100

		if MPDruidCatSaved[MPDruidCatConfig].Barkskin==1 then
			if percent<MPDruidCatSaved[MPDruidCatConfig].Barkskin_Value and MPGetShape(MPDruidCatShapeshiftID) then
				CastSpellByName("树皮术（野性）")
			end
		end
		if MPDruidCatSaved[MPDruidCatConfig].HealthStone==1 then
			if percent<MPDruidCatSaved[MPDruidCatConfig].HealthStone_Value then
				MPUseItemByName("特效治疗石")
			end
		end
		if MPDruidCatSaved[MPDruidCatConfig].HerbalTea==1 then
			if percent<MPDruidCatSaved[MPDruidCatConfig].HerbalTea_Value then
				MPUseItemByName("糖水茶")
				MPUseItemByName("诺达纳尔草药茶")
			end
		end

		-- 双流血 安全检测
		CatDotReset()

		SlowRun = Timer+0.5
	end

	-- 献祭之油
	--[[
	if MPDruidCatSaved[MPDruidCatConfig].Sacrificial==1 then
		if Timer-MPSacrificialTimer>0 and MPScanNearbyEnemiesCount(8)>3 then
			MPUseItemByName("献祭之油")
		end
	end
	]]


	-- 流派策略

	if MP_SuperWoW then

		--[[
		if MPDruidCatPVP==1 and UnitIsPlayer("target") then
			MPCatPVP()
			return
		end
		]]

		if type == 2 then
			MPCatBackstabNew()
		else

			if MPDruidCatSaved[MPDruidCatConfig].BOSS==1 and not TargetBOSS then
				MPCatBackstabNew()
			elseif MPDruidCatTest==1 then
				if MPTargetBleed then	-- 目标可流血
					MPCatBleedTest()
				else					-- 目标不可流血
					MPCatBackstabNew()
				end
			else

				if MPTargetBleed then	-- 目标可流血
					MPCatBleedNew()
				else					-- 目标不可流血
					MPCatBackstabNew()
				end

			end

		end

	else

		if type == 2 then
			MPCatBackstab()			-- 背刺流
		else
			if MPDruidCatSaved[MPDruidCatConfig].BOSS==1 and not TargetBOSS then
				MPCatBackstab()
			else
				if MPTargetBleed then	-- 目标可流血
					MPCatBleed()
				else					-- 目标不可流血
					MPCatBackstab()
				end
			end
		end

	end


	-- 远距离补精灵之火
	--MPFaerieFire()

end




-- 是否满足终结技条件
-- 阿莎曼之怒的星优先于配置星
local function AllowFerocious(Bite)

	--[[
	-- 阿莎曼之怒 特效补星
	--if MPDruidCatSaved[MPDruidCatConfig].Ashamane==1 then
		local last = 25-MPDruidPrimalFury
		if last < 5 then
			if GCP>=last then
				return true
			end
		end
	--end
	]]

	-- 怪即将死亡
	if THP<3000 and GCP>=2 then
		return true
	end


	if GCP>=Bite then
		return true
	end

	return false
end



function MPCatIdolDance(CombeValue)
	-- 检测开关，同时交互交互界面的安全检测
	if MPDruidCatSaved[MPDruidCatConfig].Idol_Dance==1 and not MPCheckUIStatus() and GCD<0.2 then
		-- 几星切换神像，根据撕咬的星数来决定
		if AllowFerocious(CombeValue) then
			MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Idol_Dance_High, 9)
		else
			MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Idol_Dance_Low, 9)
		end
	end
end


-- 德鲁伊切换目标神像事件
function MPDruidSwapIdol(value)

	value = value or 0

	-- 开关检测
	if MPDruidCatSaved[MPDruidCatConfig].Target_Swap_Idol == 0 then
		return
	end

	--[[
	-- 非德鲁伊，则无效执行
	local _, class = UnitClass("player")
	if class ~= "DRUID" then
		return
	end
	]]

	-- 天赋检测，野性
	if MPDruidTalent ~= 2 then
		return
	end



	-- 目标类型
	if not UnitExists("target") then
		return
	end

	if MPCheckUIStatus() then
		return
	end


	if value==0 then

		-- 熊形态下，神像固定
		if MPGetShape(MPDruidBearShapeshiftID) then
			MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Target_Swap_Idol_Bear, 9)
			return
		elseif MPGetShape(MPDruidCatShapeshiftID) then
			-- 流血状态，且没有打开银行等窗口
			if MPTargetBleed then
				MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Target_Swap_Idol_Bleed, 9)
			else
				MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Target_Swap_Idol_Shred, 9)
			end
		end

	-- 强制熊
	elseif value==1 then

		MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Target_Swap_Idol_Bear, 9)
		return

	-- 强制猫德
	elseif value==2 then
		-- 流血状态，且没有打开银行等窗口
		if MPTargetBleed then
			MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Target_Swap_Idol_Bleed, 9)
		else
			MPEquipItemByName(MPDruidCatSaved[MPDruidCatConfig].Target_Swap_Idol_Shred, 9)
		end
	end

end


-- 中间距离的精灵火
function MPFaerieFire()

	-- 开关
	if MPDruidCatSaved[MPDruidCatConfig].FaerieFire==0 then
		return
	end

	-- 先检查目标是否存在
	local hasTarget = UnitExists("target")
	if not hasTarget then
		return
	end

	-- 是不是敌人
    if not UnitCanAttack("player", "target") then
        return
    end

	-- 自己在战斗中，目标也在战斗中
	if MPInCombat and UnitAffectingCombat("target") then
		-- 不在近战范围
		if not MPGetTargetDistance("target",6) and MPIsFaerieFire() then
			CastSpellByName("精灵之火（野性）")
		end
	end

end




-- 爪击处理
local function MPCastClaw()

	if UnitExists("target") then
		local n = UnitExists("targettarget")
		if n and n==UnitName("player") then
			CastSpellByName("爪击")
		else
			if myPower>=(MPDruidShredEnergy+20) then
				CastSpellByName("爪击")
			elseif myPower>=MPDruidShredEnergy and playerBuffs["节能施法"] then
				CastSpellByName("爪击")
			end
		end
	end

end

-- 猫德填充技能
local function MPCatAttack(type)

	-- 技能安全检查，没有学撕碎，则强制用爪击
	if MPGetSpellID("撕碎") == 0 then
		type=1
	end

	-- 根据正反面撕碎/爪击填充空挡
	-- 基础技能
	if type==1 then
		if myPower>=MPDruidClawEnergy then
			-- 爪击流
			CastSpellByName("爪击")
			return
		end

	elseif type==2 then

		-- 均衡 朝向自动
		if BEHIND then
			if myPower>=MPDruidShredEnergy then
				CastSpellByName("撕碎")
				return
			end
		else
			if myPower>=MPDruidClawEnergy then
				CastSpellByName("爪击")
				return
			end
		end

	elseif type==3 then

		-- 均衡 偏向撕碎
		if BEHIND then
			if myPower>=MPDruidShredEnergy then
				CastSpellByName("撕碎")
				return
			end
		else
			if myPower>=MPDruidClawEnergy then
				MPCastClaw()
				return
			end
		end

	else
	
		if myPower>=MPDruidShredEnergy then
			-- 撕碎流
			CastSpellByName("撕碎")
			return
		end

	end

end



local function MPCheckShapeshift()

	local allow = 0

	-- 自动回能
	if MPGetRestoredEnergy()<1.3 then
		allow = allow + 4
	end

	-- 猛虎回能
	if (MPDruidTigerFuryTimer-Timer)>0.8 then
		allow = allow + 2
	end

	-- 扫击回能
	if (MPDruidRateJumpTimer-Timer)>0.8 then
		allow = allow + 1
	end

	-- 撕扯回能
	if (MPDruidRipJumpTimer-Timer)>0.8 then
		allow = allow + 1
	end

	return allow
end




-- 背刺猫攻击流程
function MPCatBackstab()
	PCD = MPGetRestoredEnergy()

	-- 神像舞
	MPCatIdolDance(MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Bite)

	if MPDruidCatSaved[MPDruidCatConfig].TigerFury==1 then
		if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==0 then
			-- 走地猫的开启猛虎优化
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=MPDruidTigerFury then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		else
			-- 变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>17) and myPower>=MPDruidTigerFury then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		end
	end

	if AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Bite) and myPower<MPDruidCatSaved[MPDruidCatConfig].ShredModeShapeshift and playerBuffs["节能施法"] then
		MPCastWithoutNampower("凶猛撕咬")
		return
	end

	-- 清晰预兆触发时，根据正反面选择撕碎/爪击
	if playerBuffs["节能施法"] then
		if MPDruidCatSaved[MPDruidCatConfig].Style==1 then
			CastSpellByName("爪击")
			return
		else
			if BEHIND then
				CastSpellByName("撕碎")
				return
			else
				CastSpellByName("爪击")
				return
			end
		end
	end

	-- 仇恨高的时候畏缩
	-- 仇恨高于80
	if MPDruidCatSaved[MPDruidCatConfig].Cower==1 and WS and myPower>=20 and MPGetHatredFromTWT()>=80 then
		CastSpellByName("畏缩")
		return
	end

	-- 无清晰预兆，再撕咬
	if AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Bite) and myPower<MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Value and not playerBuffs["节能施法"] then
		MPCastWithoutNampower("凶猛撕咬")
		return
	end

	if Timer-MPMHTimer>15 then

			if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and DM>=MPDruidShapeshiftMana and GCD>0.9 and not playerBuffs["狂暴"] then
				if myPower<30 then
					CastSpellByName("重整")
					MPMHTimer=0
					return
				end
			end

	elseif Timer-MPMHTimer>8 then

		--if not MPBuff("裂隙诅咒") then -- 防御村长的诅咒意外变身解除
			if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and DM>=MPDruidShapeshiftMana and GCD>0.8 and not playerBuffs["狂暴"] and MPGetRestoredEnergy()<1.5 then
				if myPower<MPDruidCatSaved[MPDruidCatConfig].ShredModeShapeshift then
					CastSpellByName("重整")
					MPMHTimer=0
					return
				end
			end

			if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and DM>=MPDruidShapeshiftMana and  myPower<30 and GCD>0.9 then
				CastSpellByName("重整")
				MPMHTimer=0
				return
			end

	else
		-- 空挡仇恨高于70
		if MPDruidCatSaved[MPDruidCatConfig].Cower==1 and WS and myPower>=20 and MPGetHatredFromTWT()>=70 then
			CastSpellByName("畏缩")
			return
		end

		-- 空挡时补精灵之火
		if MPDruidCatSaved[MPDruidCatConfig].FaerieFire==1 and MPIsFaerieFire() then
			if MPGetShape(MPDruidCatShapeshiftID) and MPInCombat and TargetDistance and not playerBuffs["节能施法"] and JLZH then
				if myPower<=MPDruidCatSaved[MPDruidCatConfig].ShredModeShapeshift then
					CastSpellByName("精灵之火（野性）")
					return
				end
			end
		end
	end

	MPCatAttack(MPDruidCatSaved[MPDruidCatConfig].Style)

end





-- 流血猫攻击流程
function MPCatBleed()

	local BeginShapeshift = 8

	MPRake = MPGetRakeDot()
	MPRip = MPGetRipDot()
	MPRavage = MPGetRavageDot()
	local _,guid = UnitExists("target")

	-- 神像舞
	MPCatIdolDance(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite)

	if MPDruidCatSaved[MPDruidCatConfig].TigerFury==1 then

		if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==0 then
			-- 走地猫的开启猛虎优化
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=MPDruidTigerFury then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		else
			-- 变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>17) and myPower>=MPDruidTigerFury then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		end
	end


	-- 非BOSS 禁用撕扯
	if MPDruidCatSaved[MPDruidCatConfig].BOSS==1 and not TargetBOSS then
		MPRip = true
	else

		-- 补撕扯
		if not MPRip and GCP>=5 and THP>MPDruidCatSaved[MPDruidCatConfig].OutHPRip and (myPower>=30 or playerBuffs["节能施法"]) then
			CastSpellByName("撕扯")
			return
		end

	end


	if AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite) and myPower<MPDruidCatSaved[MPDruidCatConfig].BleedModeShapeshift and playerBuffs["节能施法"] and MPRip then
		MPCastWithoutNampower("凶猛撕咬")
		return
	end

	if playerBuffs["节能施法"] then
		if MPDruidCatSaved[MPDruidCatConfig].Style==1 then
			CastSpellByName("爪击")
			return
		else
			if BEHIND then
				CastSpellByName("撕碎")
				return
			end
		end
	end

	-- 补扫击
	if not MPRake and not AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite) and myPower>=MPDruidRakeEnergy then 
		CastSpellByName("扫击")
		return
	end

	-- 仇恨高的时候畏缩
	-- 仇恨高于80
	if MPDruidCatSaved[MPDruidCatConfig].Cower==1 and WS and MPGetHatredFromTWT()>=80 then
		CastSpellByName("畏缩")
		return
	end

	-- 撕咬
	if MPRip and AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite) and myPower<MPDruidCatSaved[MPDruidCatConfig].Ferocious_Value then
		MPCastWithoutNampower("凶猛撕咬")
		return
	end
	

	if Timer-MPMHTimer>BeginShapeshift then

		--if not MPBuff("裂隙诅咒") then -- 防御村长的诅咒意外变身解除

			-- 变身基本条件
			if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and DM>=MPDruidShapeshiftMana and not playerBuffs["狂暴"] and GCD>0.8 then

				if AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite) then
					if myPower<15 then
						CastSpellByName("重整")
						MPMHTimer=0
						return
					end
				else
					if myPower<MPDruidCatSaved[MPDruidCatConfig].BleedModeShapeshift then
						CastSpellByName("重整")
						MPMHTimer=0
						return
					end

					if Timer-MPMHTimer>15 and myPower<35 then
						CastSpellByName("重整")
						MPMHTimer=0
						return
					end
				end
			end

		--end

	end

	-- 补充畏缩
	if MPDruidCatSaved[MPDruidCatConfig].Cower==1 and WS and MPGetHatredFromTWT()>=70 then
		CastSpellByName("畏缩")
		return
	end

	-- 允许精灵之火
	if MPDruidCatSaved[MPDruidCatConfig].FaerieFire==1 and MPIsFaerieFire() then


		-- 必要条件
		if TargetDistance and MPGetShape(MPDruidCatShapeshiftID) and MPInCombat and not playerBuffs["节能施法"] and JLZH then

			if myPower<15 then
				CastSpellByName("精灵之火（野性）")
				return
			end

			if myPower<(MPDruidClawEnergy-20) and GCP<MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite then
				CastSpellByName("精灵之火（野性）")
				return
			end

		end

	end

	MPCatAttack(MPDruidCatSaved[MPDruidCatConfig].Style)

end
















-- 新-流血猫攻击流程
-- New A
function MPCatBleedNew()

	local AF = AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite)

	MPRake = MPGetRakeDot()
	MPRip = MPGetRipDot()
	MPRavage = MPGetRavageDot()
	local _,guid = UnitExists("target")

	-- 变身基本条件
	if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and DM>=MPDruidShapeshiftMana and GCD>0.8 then --

		if Timer-MPMHTimer>17 and myPower<=30 then
			CastSpellByName("重整")
			MPMsg("猛虎即将结束")
			return
		end
		
		if not playerBuffs["节能施法"] and not playerBuffs["狂暴"] then

			if MPCheckShapeshift()>=7 and myPower<MPDruidCatSaved[MPDruidCatConfig].BleedModeShapeshift then
				CastSpellByName("重整")
				return
			end

			if MPCheckShapeshift()>=4 and myPower<10 then
				CastSpellByName("重整")
				return
			end

		end

	end

	-- 神像舞
	MPCatIdolDance(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite)

	if MPDruidCatSaved[MPDruidCatConfig].TigerFury==1 then

		if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 then
			-- 变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=60 then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		else
			-- 不变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=MPDruidTigerFury then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		end
	end

	-- 非BOSS 禁用撕扯
	if MPDruidCatSaved[MPDruidCatConfig].BOSS==1 and not TargetBOSS then
		MPRip = true
	else

		-- 补撕扯
		if not MPRip and GCP>=MPDruidCatSaved[MPDruidCatConfig].Rip_Bite and THP>MPDruidCatSaved[MPDruidCatConfig].OutHPRip and myPower>=30 then
			CastSpellByName("撕扯")
			return
		end

	end

	-- 凶猛撕咬存在
	if MPGetSpellID("凶猛撕咬") > 0 then
		-- 抢救 撕扯
		if AF and MPRip and (myPower>=35 or playerBuffs["节能施法"]) then
			local check = MPGetRipCheck()
			if check[guid] then
				local timer = MPDruidRipDuration-(Timer-check[guid])
				if timer < 3 then 
					MPCastWithoutNampower("凶猛撕咬")
					MPMsg("|cFFee1111抢救 撕扯|r")
					return
				end
			end
		end
	end

	--清晰预兆
	if playerBuffs["节能施法"] then
		if MPDruidCatSaved[MPDruidCatConfig].Style==1 then
			CastSpellByName("爪击")
			return
		else
			if BEHIND then
				CastSpellByName("撕碎")
				return
			end
		end
	end


	-- 仇恨高的时候畏缩
	-- 仇恨高于80
	if MPDruidCatSaved[MPDruidCatConfig].Cower==1 then
		if WS and myPower>=20 and MPGetHatredFromTWT()>=80 then
			CastSpellByName("畏缩")
			return
		end
	end

	-- 凶猛撕咬存在
	if MPGetSpellID("凶猛撕咬") > 0 then
		-- 撕咬
		if AF and myPower<MPDruidCatSaved[MPDruidCatConfig].Ferocious_Value and MPRip and not playerBuffs["节能施法"] and myPower>=35 then
			MPCastWithoutNampower("凶猛撕咬")
			return
		end
	end

	-- 扫击存在
	if MPGetSpellID("扫击") > 0 then

		-- 补扫击
		if MPDruidCatSaved[MPDruidCatConfig].BOSS==1 and not TargetBOSS then
			if not BEHIND and not MPRake and myPower>=MPDruidRakeEnergy then 

				CastSpellByName("扫击")
				return
			end
		else
			if not MPRake and myPower>=MPDruidRakeEnergy then 

				CastSpellByName("扫击")
				return
			end
		end

	end

	

	if MPDruidCatSaved[MPDruidCatConfig].FaerieFire==1 then

		-- 允许精灵之火
		if MPCheckShapeshift()<4 and GCD>0.8 and MPIsFaerieFire() then

			-- 必要条件
			if MPGetShape(MPDruidCatShapeshiftID) and MPInCombat and not playerBuffs["节能施法"] and JLZH then

				if myPower<35 then
					CastSpellByName("精灵之火（野性）")
					return
				end

			end

		end

	end

	MPCatAttack(MPDruidCatSaved[MPDruidCatConfig].Style)

end




-- 新-背刺猫攻击流程
-- New A
function MPCatBackstabNew()


	-- 变身基本条件
	if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and DM>=MPDruidShapeshiftMana and GCD>0.8 then 

		if Timer-MPMHTimer>17 then
			if myPower<30 then
				CastSpellByName("重整")
				return
			end
		end

		if MPCheckShapeshift()>4 and not playerBuffs["节能施法"] and not playerBuffs["狂暴"] then

			if myPower<MPDruidCatSaved[MPDruidCatConfig].ShredModeShapeshift then
				CastSpellByName("重整")
				return
			end

		end

	end

	-- 神像舞
	MPCatIdolDance(MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Bite)

	if MPDruidCatSaved[MPDruidCatConfig].TigerFury==1 then
		if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 then
			-- 变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=60 then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		else
			-- 不变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=MPDruidTigerFury then
				CastSpellByName("猛虎之怒")
				MPMHTimer=Timer
			end
		end
	end

	-- 凶猛撕咬存在
	if MPGetSpellID("凶猛撕咬") > 0 then

		if GCP>=5 and myPower<15 and playerBuffs["节能施法"] and MPRip then   -- AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite)
			MPCastWithNampower("凶猛撕咬")
			return
		end

	end

	-- 清晰预兆触发时，根据正反面选择撕碎/爪击
	if playerBuffs["节能施法"] then
		if MPDruidCatSaved[MPDruidCatConfig].Style==1 then
			CastSpellByName("爪击")
			return
		else
			if BEHIND then
				CastSpellByName("撕碎")
				return
			end
		end
	end

	-- 仇恨高的时候畏缩
	-- 仇恨高于80
	if MPDruidCatSaved[MPDruidCatConfig].Cower==1 and WS and myPower>=20 and MPGetHatredFromTWT()>=80 then
		CastSpellByName("畏缩")
		return
	end


	-- 凶猛撕咬存在
	if MPGetSpellID("凶猛撕咬") > 0 then
		-- 无清晰预兆，再撕咬
		if AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Bite) and myPower<MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Value and not playerBuffs["节能施法"] and myPower>=35 then
			CastSpellByName("凶猛撕咬")
			return
		end
	end


	if MPCheckShapeshift()<4 and GCD>0.8 then

		-- 变身保护期

		if MPDruidCatSaved[MPDruidCatConfig].Cower==1 and WS and myPower>=20 and MPGetHatredFromTWT()>=70 then
			CastSpellByName("畏缩")
			return
		end

		-- 允许精灵之火
		if MPDruidCatSaved[MPDruidCatConfig].FaerieFire==1 and MPIsFaerieFire() then

			-- 必要条件
			if TargetDistance and MPGetShape(MPDruidCatShapeshiftID) and MPInCombat and not playerBuffs["节能施法"] and JLZH then

				if AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].ShredFerocious_Bite) then
					if myPower>=MPDruidCatSaved[MPDruidCatConfig].ShredModeShapeshift and myPower<35 then
						CastSpellByName("精灵之火（野性）")
						return
					end

				else
					if myPower>=MPDruidCatSaved[MPDruidCatConfig].ShredModeShapeshift and myPower<MPDruidShredEnergy then
						CastSpellByName("精灵之火（野性）")
						return
					end

				end


			end

		end

	end

	MPCatAttack(MPDruidCatSaved[MPDruidCatConfig].Style)

end














-- 流血猫攻击流程
-- Test版
function MPCatBleedTest()

	local AF = AllowFerocious(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite)

	MPRake = MPGetRakeDot()
	MPRip = MPGetRipDot()
	MPRavage = MPGetRavageDot()
	local _,guid = UnitExists("target")



	-- 变身基本条件
	if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 and DM>=MPDruidShapeshiftMana and GCD>0.8 then --

		if Timer-MPMHTimer>17 then
			if myPower<30 then
				CastSpellByName("重整")
				return
			end
		else
			if Timer-MPMHTimer>10 then
				if myPower<=MPDruidCatSaved[MPDruidCatConfig].BleedModeShapeshift and MPCheckShapeshift()>4 then
					CastSpellByName("重整")
					return
				end
			end
			if MPDruidCatSaved[MPDruidCatConfig].FaerieFire==1 then
				if MPGetShape(MPDruidCatShapeshiftID) and MPInCombat and not playerBuffs["节能施法"] and JLZH then
					CastSpellByName("精灵之火（野性）")
					return
				end
			end
		end
		
	end

	-- 神像舞
	MPCatIdolDance(MPDruidCatSaved[MPDruidCatConfig].Ferocious_Bite)

	if MPDruidCatSaved[MPDruidCatConfig].TigerFury==1 then

		if MPDruidCatSaved[MPDruidCatConfig].Shapeshift==1 then
			-- 变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=60 then
				CastSpellByName("猛虎之怒")
			end
		else
			-- 不变身猫的猛虎策略
			if (not MPMHTimer or Timer-MPMHTimer>18) and myPower>=MPDruidTigerFury then
				CastSpellByName("猛虎之怒")
			end
		end
	end

	-- 非BOSS 禁用撕扯
	if MPDruidCatSaved[MPDruidCatConfig].BOSS==1 and not TargetBOSS then
		MPRip = true
	else

		-- 补撕扯
		if not MPRip and GCP>=5 and THP>MPDruidCatSaved[MPDruidCatConfig].OutHPRip and myPower>29 then
			MPCastWithNampower("撕扯")
			return
		end

	end

	-- 抢救 撕扯
	if AF and MPRip and (myPower>=35 or playerBuffs["节能施法"]) then
		local check = MPGetRipCheck()
        if check[guid] then
			local timer = MPDruidRipDuration-(Timer-check[guid])
			if timer < 3 then 
				MPCastWithoutNampower("凶猛撕咬")
				MPMsg("|cFFee1111抢救 撕扯|r")
				return
			end
		end
	end

	--清晰预兆
	if playerBuffs["节能施法"] then
		if BEHIND then
			CastSpellByName("撕碎")
			return
		end
	end


	-- 仇恨高的时候畏缩
	-- 仇恨高于80
	if MPDruidCatSaved[MPDruidCatConfig].Cower==1 then
		if WS and myPower>=20 and MPGetHatredFromTWT()>=80 then
			CastSpellByName("畏缩")
			return
		end
	end

	-- 撕咬
	if AF and myPower<MPDruidCatSaved[MPDruidCatConfig].Ferocious_Value and MPRip and not playerBuffs["节能施法"] and myPower>=35 then
		MPCastWithoutNampower("凶猛撕咬")
		return
	elseif myPower>=MPDruidRakeEnergy then

		-- 补扫击
		if MPDruidCatSaved[MPDruidCatConfig].BOSS==1 and not TargetBOSS then
			if not BEHIND and not MPRake then 

				CastSpellByName("扫击")
				return
			end
		else
			if not MPRake then 

				CastSpellByName("扫击")
				return
			end
		end

	end
	
	-- 三流血
	if MPRake and MPRip and MPRavage then
		if myPower>=MPDruidClawEnergy then
			CastSpellByName("爪击")
			return
		end
	end

	-- 均衡 朝向自动
	if BEHIND then
		CastSpellByName("撕碎")
		return
	else
		CastSpellByName("爪击")
		return
	end
	--[[
	-- 均衡 朝向自动 能量不够打爪击
	if BEHIND and myPower>=MPDruidShredEnergy then
		CastSpellByName("撕碎")
		return
	elseif myPower>=MPDruidClawEnergy then
		CastSpellByName("爪击")
		return
	end
	]]
end


