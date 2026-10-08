BCS = BCS or {}
BCSConfig = BCSConfig or {}

local L, IndexLeft, IndexRight
L = BCS.L

local L_FORM = BCS.L_FORM
local _,class = UnitClass("player")

BCS.PLAYERSTAT_DROPDOWN_OPTIONS = {
	"PLAYERSTAT_BASE_STATS",
	"PLAYERSTAT_MELEE_COMBAT",
	"PLAYERSTAT_RANGED_COMBAT",
	"PLAYERSTAT_SPELL_COMBAT",
	"PLAYERSTAT_SPELL_SCHOOLS",
	"PLAYERSTAT_DEFENSES",
}

-- 根据职业返回角色面板默认的属性分类
-- 物理职业 → 近战属性；猎人 → 远程属性；法系/治疗职业 → 法术属性（治疗属性也归属法术面板）
function BCS:GetDefaultPanelStat()
	local _, class = UnitClass("player")
	if class == "HUNTER" then
		return "PLAYERSTAT_RANGED_COMBAT"
	elseif class == "WARRIOR" or class == "PALADIN" or class == "ROGUE" or class == "DEATHKNIGHT" then
		return "PLAYERSTAT_MELEE_COMBAT"
	elseif class == "MAGE" or class == "WARLOCK" then
		return "PLAYERSTAT_SPELL_COMBAT"
	elseif class == "PRIEST" or class == "SHAMAN" or class == "DRUID" then
		return "PLAYERSTAT_SPELL_COMBAT"
	else
		return BCS.PLAYERSTAT_DROPDOWN_OPTIONS[1]
	end
end

BCS.MELEEHIT = {
	["ROGUE"] = {
		5, -- pvp
		8, -- yellow cap
		24.6, -- white cap
	},
}

BCS.SPELLHIT = {
	-- soon(tm)
}

BCS.PaperDollFrame = PaperDollFrame

-- ===== 角色面板显示开关（由浮动面板 /mb 旁边的「角色面板」按钮控制）=====
-- 关闭后：按 C 只显示暴雪原生角色面板，BCS 不再向角色面板写入任何内容，
-- 属性只在浮动窗中显示；BCS 针对角色面板的取值扫描也会一并跳过（省开销）。
BCS.PAPERDOLL_EVENTS = {
	"UNIT_DAMAGE",
	"PLAYER_DAMAGE_DONE_MODS",
	"UNIT_ATTACK_SPEED",
	"UNIT_RANGEDDAMAGE",
	"UNIT_ATTACK",
	"UNIT_STATS",
	"UNIT_ATTACK_POWER",
	"UNIT_RANGED_ATTACK_POWER",
}

-- 当前是否在角色面板中显示 BCS 属性（配置项 BCSConfig.PropertiesPanel.characterPanelEnabled）
function BCS:IsCharacterPanelEnabled()
	if BCSConfig and BCSConfig.PropertiesPanel and BCSConfig.PropertiesPanel.characterPanelEnabled == false then
		return false
	end
	return true
end

-- 只切换「内容归属」：BCS 属性面板 / 暴雪原生属性区
function BCS:SyncCharacterPanelContent()
	if BCS:IsCharacterPanelEnabled() then
		if CharacterAttributesFrame then CharacterAttributesFrame:Hide() end
		if BetterCharacterAttributesFrame then BetterCharacterAttributesFrame:Show() end
	else
		if BetterCharacterAttributesFrame then BetterCharacterAttributesFrame:Hide() end
		if CharacterAttributesFrame then CharacterAttributesFrame:Show() end
	end
end

-- 应用开关状态：切换显示内容、接管/交还事件，并在面板已打开时立即刷新
function BCS:ApplyCharacterPanelState()
	local enabled = BCS:IsCharacterPanelEnabled()
	local changed = (BCS.characterPanelEnabled ~= enabled)
	BCS.characterPanelEnabled = enabled

	local i, e
	if enabled then
		-- BCS 接管：停用暴雪原生属性区（避免两套内容同时显示）
		for i = 1, getn(BCS.PAPERDOLL_EVENTS) do
			e = BCS.PAPERDOLL_EVENTS[i]
			pcall(function() PaperDollFrame:UnregisterEvent(e) end)
		end
		if CharacterAttributesFrame then CharacterAttributesFrame:Hide() end
	else
		-- 关闭 BCS：隐藏 BCS 面板，把事件还给 PaperDollFrame，恢复暴雪原生属性区
		if BetterCharacterAttributesFrame then BetterCharacterAttributesFrame:Hide() end
		for i = 1, getn(BCS.PAPERDOLL_EVENTS) do
			e = BCS.PAPERDOLL_EVENTS[i]
			pcall(function() PaperDollFrame:RegisterEvent(e) end)
		end
	end

	if PaperDollFrame and PaperDollFrame:IsVisible() then
		BCS:SyncCharacterPanelContent()
		if changed then
			-- 面板正开着：重新触发一次 OnShow，让切换后的数值按最新状态刷新
			PaperDollFrame:Hide()
			PaperDollFrame:Show()
		end
	end
end

-- 角色面板每次打开时同步一次，保证「BCS 内容 / 暴雪原生内容」与开关一致
local BCS_origPaperDollOnShow = PaperDollFrame and PaperDollFrame:GetScript("OnShow")
if PaperDollFrame then
	PaperDollFrame:SetScript("OnShow", function()
		if BCS_origPaperDollOnShow then BCS_origPaperDollOnShow() end
		BCS:SyncCharacterPanelContent()
	end)
end

BCS.Debug = false
BCS.DebugStack = {}

function BCS:DebugTrace(start, limit)
	BCS.Debug = nil
	local length = getn(BCS.DebugStack)
	if not start then start = 1 end
	if start > length then start = length end
	if not limit then limit = start + 30 end
	
	BCS:Print("length: " .. length)
	BCS:Print("start: " .. start)
	BCS:Print("limit: " .. limit)
	
	for i = start, length, 1 do
		BCS:Print("[" .. i .. "] Event: " .. BCS.DebugStack[i].E)
		BCS:Print(format(
			"[%d] `- Arguments: %s, %s, %s, %s, %s",
			i,
			BCS.DebugStack[i].arg1,
			BCS.DebugStack[i].arg2,
			BCS.DebugStack[i].arg3,
			BCS.DebugStack[i].arg4,
			BCS.DebugStack[i].arg5
		))
		if i >= limit then i = length end
	end
	
end

function BCS:Print(message)
	ChatFrame2:AddMessage("[BCS] " .. message, 0.63, 0.86, 1.0)
end

function BCS:OnLoad()
	CharacterAttributesFrame:Hide()
	PaperDollFrame:UnregisterEvent('UNIT_DAMAGE')
	PaperDollFrame:UnregisterEvent('PLAYER_DAMAGE_DONE_MODS')
	PaperDollFrame:UnregisterEvent('UNIT_ATTACK_SPEED')
	PaperDollFrame:UnregisterEvent('UNIT_RANGEDDAMAGE')
	PaperDollFrame:UnregisterEvent('UNIT_ATTACK')
	PaperDollFrame:UnregisterEvent('UNIT_STATS')
	PaperDollFrame:UnregisterEvent('UNIT_ATTACK_POWER')
	PaperDollFrame:UnregisterEvent('UNIT_RANGED_ATTACK_POWER')
	
	self.Frame = BCSFrame
	self.needUpdate = nil

	self.Frame:RegisterEvent("ADDON_LOADED")
	self.Frame:RegisterEvent("UNIT_INVENTORY_CHANGED") -- fires when equipment changes
	self.Frame:RegisterEvent("CHARACTER_POINTS_CHANGED") -- fires when learning talent
	self.Frame:RegisterEvent("PLAYER_AURAS_CHANGED") -- buffs/warrior stances
	self.Frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- confirm data ready 
	
	local _, classFileName = UnitClass("Player")
	self.playerClass = strupper(classFileName)
end

function BCS:OnEvent()
	--[[if BCS.Debug then
		local t = {
			E = event,
			arg1 = arg1 or "nil",
			arg2 = arg2 or "nil",
			arg3 = arg3 or "nil",
			arg4 = arg4 or "nil",
			arg5 = arg5 or "nil",
		}
		tinsert(BCS.DebugStack, t)
	end]]
	
	if event == "PLAYER_ENTERING_WORLD" then
		BCS.needUpdate = true
		return
	end
	
	-- 角色面板中不显示 BCS 属性时，不再为它维护数值（省掉整轮装备/光环扫描）
	if not BCS:IsCharacterPanelEnabled() then
		return
	end
	
	if
		event == "PLAYER_AURAS_CHANGED" or
		event == "CHARACTER_POINTS_CHANGED"
	then
		if BCS.PaperDollFrame:IsVisible() then
			BCS:UpdateStats()
		else
			BCS.needUpdate = true
		end
	elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
		if BCS.PaperDollFrame:IsVisible() then
			BCS:UpdateStats()
		else
			BCS.needUpdate = true
		end
	elseif event == "ADDON_LOADED" and arg1 == "BetterCharacterStats" then
		BCSConfig = BCSConfig or {}
		-- 左侧保持原始默认（主属性）；右侧首次加载（无已保存的选择）时按职业设定默认属性分类
		IndexLeft = BCSConfig["DropdownLeft"] or BCS.PLAYERSTAT_DROPDOWN_OPTIONS[1]
		IndexRight = BCSConfig["DropdownRight"] or BCS:GetDefaultPanelStat()
		-- 将解析后的默认值写回 BCSConfig，供“按需计算(on-demand)”的各接口正确识别当前面板
		BCSConfig["DropdownLeft"] = IndexLeft
		BCSConfig["DropdownRight"] = IndexRight

		UIDropDownMenu_SetSelectedValue(PlayerStatFrameLeftDropDown, IndexLeft)
		UIDropDownMenu_SetSelectedValue(PlayerStatFrameRightDropDown, IndexRight)
		
		if BCS.PropertiesPanel then
			BCS.PropertiesPanel:Init()
		end
	end
end

function BCS:OnShow()
	if BCS.needUpdate then
		BCS.needUpdate = nil
	end
	BCS:UpdateStats()
end

-- debugging / profiling
--[[
local avgV = {}
local avg = 0
function BCS:UpdateStats()
	if BCS.Debug then
		local e = event or "nil"
		BCS:Print("Update due to " .. e)
	end
	local beginTime = debugprofilestop()
	
	BCS:UpdatePaperdollStats("PlayerStatFrameLeft", IndexLeft)
	BCS:UpdatePaperdollStats("PlayerStatFrameRight", IndexRight)

	local timeUsed = debugprofilestop()-beginTime
	table.insert(avgV, timeUsed)
	avg = 0
	
	for i,v in ipairs(avgV) do
		avg = avg + v
	end
	avg = avg / getn(avgV)
	
	BCS:Print(format("Average: %d (%d results), Exact: %d", avg, getn(avgV), timeUsed))
end
]]

function BCS:UpdateStats()
	if not BCS:IsCharacterPanelEnabled() then return end
	BCS:UpdatePaperdollStats("PlayerStatFrameLeft", IndexLeft)
	BCS:UpdatePaperdollStats("PlayerStatFrameRight", IndexRight)
end

function BCS:SetStat(statFrame, statIndex)
	local label = getglobal(statFrame:GetName().."Label")
	local text = getglobal(statFrame:GetName().."StatText")
	local stat
	local effectiveStat
	local posBuff
	local negBuff
	local statIndexTable = {
		"STRENGTH",
		"AGILITY",
		"STAMINA",
		"INTELLECT",
		"SPIRIT",
	}
	
	statFrame:SetScript("OnEnter", function()
		PaperDollStatTooltip("player", statIndexTable[statIndex])
	end)
	
	statFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	label:SetText(TEXT(getglobal("SPELL_STAT"..(statIndex-1).."_NAME"))..":")
	local stat, effectiveStat, posBuff, negBuff = UnitStat("player", statIndex)
	
	-- Set the tooltip text
	local tooltipText = HIGHLIGHT_FONT_COLOR_CODE..getglobal("SPELL_STAT"..(statIndex-1).."_NAME").." "

	if ( ( posBuff == 0 ) and ( negBuff == 0 ) ) then
		text:SetText(effectiveStat)
		statFrame.tooltip = tooltipText..effectiveStat..FONT_COLOR_CODE_CLOSE
	else 
		tooltipText = tooltipText..effectiveStat
		--[[
		if ( posBuff > 0 or negBuff < 0 ) then
			--tooltipText = tooltipText.." ("..(effectiveStat)..FONT_COLOR_CODE_CLOSE
		end
		if ( posBuff > 0 ) then
			--tooltipText = tooltipText..FONT_COLOR_CODE_CLOSE..GREEN_FONT_COLOR_CODE.."+"..effectiveStat..FONT_COLOR_CODE_CLOSE
		end
		if ( negBuff < 0 ) then
			--tooltipText = tooltipText..RED_FONT_COLOR_CODE.." "..negBuff..FONT_COLOR_CODE_CLOSE
		end
		if ( posBuff > 0 or negBuff < 0 ) then
			--tooltipText = tooltipText..HIGHLIGHT_FONT_COLOR_CODE..")"..FONT_COLOR_CODE_CLOSE
		end
		]]
		statFrame.tooltip = tooltipText

		-- If there are any negative buffs then show the main number in red even if there are
		-- positive buffs. Otherwise show in green.
		if ( negBuff < 0 ) then
			text:SetText(RED_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE)
		else
			text:SetText(GREEN_FONT_COLOR_CODE..effectiveStat..FONT_COLOR_CODE_CLOSE)
		end
	end
	
	
	if negBuff < 0 then
		text:SetText(RED_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE)
	elseif posBuff > 0 then
		text:SetText(GREEN_FONT_COLOR_CODE .. effectiveStat .. FONT_COLOR_CODE_CLOSE)
	else
		text:SetText(effectiveStat)
	end
	
end

function BCS:SetArmor(statFrame)

	local base, effectiveArmor, armor, posBuff, negBuff = UnitArmor("player")
	local totalBufs = posBuff + negBuff
	local frame = statFrame
	local label = getglobal(frame:GetName() .. "Label")
	local text = getglobal(frame:GetName() .. "StatText")

	PaperDollFormatStat(ARMOR, base, posBuff, negBuff, frame, text)
	label:SetText(TEXT(ARMOR_COLON))
	
	local playerLevel = UnitLevel("player")
	local armorReduction = effectiveArmor/((85 * playerLevel) + 400)
	armorReduction = 100 * (armorReduction/(armorReduction + 1))
	
	frame.tooltipSubtext = format(ARMOR_TOOLTIP, playerLevel, armorReduction)
	
	frame:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(this.tooltip)
		GameTooltip:AddLine(this.tooltipSubtext, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
end

function BCS:SetDamage(statFrame)
	local label = getglobal(statFrame:GetName() .. "Label")
	label:SetText(TEXT(DAMAGE_COLON))
	local damageText = getglobal(statFrame:GetName() .. "StatText")
	local damageFrame = statFrame
	
	damageFrame:SetScript("OnEnter", CharacterDamageFrame_OnEnter)
	damageFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	local speed, offhandSpeed = UnitAttackSpeed("player")
	
	local minDamage
	local maxDamage 
	local minOffHandDamage
	local maxOffHandDamage 
	local physicalBonusPos
	local physicalBonusNeg
	local percent
	minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage("player")
	local displayMin = max(floor(minDamage),1)
	local displayMax = max(ceil(maxDamage),1)

	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg

	local baseDamage = (minDamage + maxDamage) * 0.5
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent
	local totalBonus = (fullDamage - baseDamage)
	local damagePerSecond = (max(fullDamage,1) / speed)
	local damageTooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1)
	
	local colorPos = "|cff20ff20"
	local colorNeg = "|cffff2020"
	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText:SetText(displayMin.." - "..displayMax)	
		else
			damageText:SetText(displayMin.."-"..displayMax)
		end
	else
		
		local color
		if ( totalBonus > 0 ) then
			color = colorPos
		else
			color = colorNeg
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText:SetText(color..displayMin.." - "..displayMax.."|r")	
		else
			damageText:SetText(color..displayMin.."-"..displayMax.."|r")
		end
		if ( physicalBonusPos > 0 ) then
			damageTooltip = damageTooltip..colorPos.." +"..physicalBonusPos.."|r"
		end
		if ( physicalBonusNeg < 0 ) then
			damageTooltip = damageTooltip..colorNeg.." "..physicalBonusNeg.."|r"
		end
		if ( percent > 1 ) then
			damageTooltip = damageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r"
		elseif ( percent < 1 ) then
			damageTooltip = damageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r"
		end
		
	end
	damageFrame.damage = damageTooltip
	damageFrame.attackSpeed = speed
	damageFrame.dps = damagePerSecond
	
	-- If there's an offhand speed then add the offhand info to the tooltip
	if ( offhandSpeed ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent
		local offhandDamagePerSecond = (max(offhandFullDamage,1) / offhandSpeed)
		local offhandDamageTooltip = max(floor(minOffHandDamage),1).." - "..max(ceil(maxOffHandDamage),1)
		if ( physicalBonusPos > 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." +"..physicalBonusPos.."|r"
		end
		if ( physicalBonusNeg < 0 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." "..physicalBonusNeg.."|r"
		end
		if ( percent > 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorPos.." x"..floor(percent*100+0.5).."%|r"
		elseif ( percent < 1 ) then
			offhandDamageTooltip = offhandDamageTooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r"
		end
		damageFrame.offhandDamage = offhandDamageTooltip
		damageFrame.offhandAttackSpeed = offhandSpeed
		damageFrame.offhandDps = offhandDamagePerSecond
	else
		damageFrame.offhandAttackSpeed = nil
	end
	
end

function BCS:SetAttackSpeed(statFrame)
	local speed, offhandSpeed = UnitAttackSpeed("player")
	speed = format("%.2f", speed)
	if ( offhandSpeed ) then
		offhandSpeed = format("%.2f", offhandSpeed)
	end
	local text	
	if ( offhandSpeed ) then
		text = speed.." / "..offhandSpeed
	else
		text = speed
	end
	
	local label = getglobal(statFrame:GetName() .. "Label")
	local value = getglobal(statFrame:GetName() .. "StatText")
	
	label:SetText(TEXT(SPEED)..":")
	value:SetText(text)

	--[[statFrame.tooltip = HIGHLIGHT_FONT_COLOR_CODE..format(PAPERDOLLFRAME_TOOLTIP_FORMAT, ATTACK_SPEED).." "..text..FONT_COLOR_CODE_CLOSE;
	statFrame.tooltip2 = format(CR_HASTE_RATING_TOOLTIP, GetCombatRating(CR_HASTE_MELEE), GetCombatRatingBonus(CR_HASTE_MELEE));]]
	
	statFrame:Show()
end

function BCS:SetAttackPower(statFrame)	
	local base, posBuff, negBuff = UnitAttackPower("player")

	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	label:SetText(TEXT(ATTACK_POWER_COLON))

	PaperDollFormatStat(MELEE_ATTACK_POWER, base, posBuff, negBuff, frame, text)
	frame.tooltipSubtext = format(MELEE_ATTACK_POWER_TOOLTIP, max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER)
end

function BCS:SetSpellPower(statFrame, school,return_spellPower,return_secondaryPower,return_secondaryPowerName,return_damagePower,return_arcanePower,return_firePower,return_frostPower,return_holyPower,return_naturePower,return_shadowPower)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	local colorPos = "|cff20ff20"
	local colorNeg = "|cffff2020"
	--use nampower first
	if BCS:IsNampowerReady() then
		local physical, holy, fire, nature, frost, shadow, arcane = GetSpellPower()
		if school then
			local schoolPower = 0
            if school == "Arcane" then
                schoolPower = arcane or 0
            elseif school == "Fire" then
                schoolPower = fire or 0
            elseif school == "Frost" then
                schoolPower = frost or 0
            elseif school == "Holy" then
                schoolPower = holy or 0
            elseif school == "Nature" then
                schoolPower = nature or 0
            elseif school == "Shadow" then
                schoolPower = shadow or 0
            end
            label:SetText(L["SPELL_SCHOOL_"..strupper(school)])
            text:SetText(schoolPower)
		else
			local totalPower = math.max(holy, fire, nature, frost, shadow, arcane)
            label:SetText(L.SPELL_POWER_COLON)
            text:SetText(format("%.0f", totalPower))
        end
        return
    end
	if school then
		label:SetText(L["SPELL_SCHOOL_"..strupper(school)])
		local base = return_spellPower
		if school == "Fire" then 
			fromSchool = return_firePower
		elseif school == "Arcane" then
			fromSchool = return_arcanePower
		elseif school == "Frost" then
			fromSchool = return_frostPower
		elseif school == "Holy" then
			fromSchool = return_holyPower
		elseif school == "Nature" then
			fromSchool = return_naturePower
		elseif school == "Shadow" then
			fromSchool = return_shadowPower
		else 
			fromSchool = 0
		end
		local output = base + fromSchool
		output = floor(output,0)
		if fromSchool > 0 then
			output = colorPos .. output .. "|r"
		end
		text:SetText(output)
	else
		local power, secondaryPower, secondaryName = return_spellPower, return_secondaryPower, return_secondaryPowerName
		label:SetText(L.SPELL_POWER_COLON)
		text:SetText(format("%.0f",power+secondaryPower))
		if secondaryPower > 0 then
			frame.tooltip = format(L.SPELL_POWER_SECONDARY_TOOLTIP, (power+secondaryPower), power, secondaryPower, secondaryName)
			
			frame:SetScript("OnEnter", function()
				GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
				GameTooltip:SetText(this.tooltip)
				GameTooltip:Show()
			end)
			frame:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)
		end
		
	end
end

function BCS:SetRating(statFrame, ratingType)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	label:SetText(L.MELEE_HIT_RATING_COLON)
	
	local colorPos = "|cff20ff20"
	local colorNeg = "|cffff2020"
	
	if ratingType == "MELEE" then
		local rating = BCS:GetHitRating()
		if BCS.MELEEHIT[BCS.playerClass] then
			if rating < BCS.MELEEHIT[BCS.playerClass][1] then
				rating = colorNeg .. rating .. ".00%|r"
			elseif rating >= BCS.MELEEHIT[BCS.playerClass][2] then
				rating = colorPos .. rating .. ".00%|r"
			else
				rating = rating .. ".00%"
			end
		else
			rating = rating .. ".00%"
		end
		if rating == nil then
			text:SetText("--")
		else
			text:SetText(rating)
		end
		
		frame.tooltip = L.MELEE_HIT_TOOLTIP
		if L[BCS.playerClass .. "_MELEE_HIT_TOOLTIP"] then
			frame.tooltipSubtext = L[BCS.playerClass .. "_MELEE_HIT_TOOLTIP"]
		end
	elseif ratingType == "RANGED" then

		if class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
			text:SetText(L.NONE)
		else
			local rating = BCS:GetRangedHitRating()
			if BCS.MELEEHIT[BCS.playerClass] then
				if rating < BCS.MELEEHIT[BCS.playerClass][1] then
					rating = colorNeg .. rating .. ".00%|r"
				elseif rating >= BCS.MELEEHIT[BCS.playerClass][2] then
					rating = colorPos .. rating .. ".00%|r"
				else
					rating = rating .. ".00%"
				end
			else
				rating = rating .. ".00%"
			end
			if rating == nil then
				text:SetText("--")
			else
				text:SetText(rating)
			end
		end
		frame.tooltip = L.MELEE_HIT_TOOLTIP
		if L[BCS.playerClass .. "_MELEE_HIT_TOOLTIP"] then
			frame.tooltipSubtext = L[BCS.playerClass .. "_MELEE_HIT_TOOLTIP"]
		end
	elseif ratingType == "SPELL" then
		local spell_hit, spell_hit_fire, spell_hit_frost, spell_hit_arcane, spell_hit_shadow ,spell_hit_holy = BCS:GetSpellHitRating()
		-- 防御性兜底：on-demand 接口在面板未识别时可能只返回单值，需避免 nil 比较
		spell_hit = spell_hit or 0
		spell_hit_fire = spell_hit_fire or 0
		spell_hit_frost = spell_hit_frost or 0
		spell_hit_arcane = spell_hit_arcane or 0
		spell_hit_shadow = spell_hit_shadow or 0
		spell_hit_holy = spell_hit_holy or 0
		--[[if BCS.SPELLHIT[BCS.playerClass] then
			if spell_hit < BCS.SPELLHIT[BCS.playerClass][1] then
				spell_hit = colorNeg .. spell_hit .. ".00%|r"
			elseif spell_hit >= BCS.SPELLHIT[BCS.playerClass][2] then
				spell_hit = colorPos .. spell_hit .. ".00%|r"
			else
				spell_hit = spell_hit .. ".00%"
			end
		else
			spell_hit = spell_hit .. ".00%"
		end]]

		if spell_hit_fire > 0 or spell_hit_frost > 0 or spell_hit_arcane > 0 or spell_hit_shadow > 0 or spell_hit_holy >0 then
			-- got spell hit from talents
			local spell_hit_other, spell_hit_other_type
			
			spell_hit_other = 0 
			spell_hit_other_type = ""
			
			if spell_hit_fire > spell_hit_other then
				spell_hit_other = spell_hit_fire
				spell_hit_other_type = L.SPELL_SCHOOL_FIRE
			end
			if spell_hit_frost > spell_hit_other then
				spell_hit_other = spell_hit_frost
				spell_hit_other_type = L.SPELL_SCHOOL_FROST
			end
			if spell_hit_arcane > spell_hit_other then
				spell_hit_other = spell_hit_arcane
				spell_hit_other_type = L.SPELL_SCHOOL_ARCANE
			end
			if spell_hit_shadow > spell_hit_other then
				spell_hit_other = spell_hit_shadow
				spell_hit_other_type = L.SPELL_SCHOOL_SHADOW
			end
			if spell_hit_holy > spell_hit_other then
				spell_hit_other = spell_hit_holy
				spell_hit_other_type = L.SPELL_SCHOOL_HOLY
			end
			
			frame.tooltip = format(L.SPELL_HIT_SECONDARY_TOOLTIP, spell_hit+spell_hit_other, spell_hit, spell_hit_other, spell_hit_other_type)
			text:SetText(spell_hit+spell_hit_other..".00%")
		else
			frame.tooltip = L.SPELL_HIT_TOOLTIP
			text:SetText(spell_hit..".00%")
		end
		
		-- class specific tooltip
		if L[BCS.playerClass .. "_SPELL_HIT_TOOLTIP"] then
			frame.tooltipSubtext = L[BCS.playerClass .. "_SPELL_HIT_TOOLTIP"]
		end
	end
	
	if frame.tooltip then
		frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(this.tooltip)
			GameTooltip:AddLine(this.tooltipSubtext, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
			GameTooltip:Show()
		end)
		frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	
end

function BCS:SetMeleeCritChance(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	label:SetText(L.MELEE_CRIT_COLON)

	local crit = BCS:GetCritChance()
	if crit == nil then 
		text:SetText("--")
	else
		text:SetText(format("%.2f%%", crit))
	end
end

function BCS:SetSpellCritChance(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	local spellcrit, spellCritBySchool = BCS:GetSpellCritChance()
	label:SetText(L.SPELL_CRIT_COLON)
	text:SetText(format("%.2f%%", spellcrit))
	--frame.tooltip = "|cffffffff伤害和治疗法术暴击的概率.|r\n"
	frame.tooltip = (L.SPELL_CRIT_TOOLTIP)
	if next(spellCritBySchool) ~= nil then
		local stringtooltip = ""
		for k,v in pairs(spellCritBySchool) do
			stringtooltip = stringtooltip .. "\n" .. k .. " |cff20ff20+" .. v .."%|r"
		end
		frame.tooltip = frame.tooltip .. stringtooltip
	end
	--frame.tooltip = format(L.SPELL_HEALING_POWER_TOOLTIP, (power+heal), power, heal)
	--frame.tooltip = format(L.SPELL_CRIT_TOOLTIP, (power+heal), power, heal)
	frame:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(this.tooltip)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

function BCS:SetRangedCritChance(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	label:SetText(L.RANGED_CRIT_COLON)
	if class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
		text:SetText(L.NONE)
	else
		text:SetText(format("%.2f%%", BCS:GetRangedCritChance()))
	end
end

function BCS:SetHealing(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	local power, _, _, dmg = BCS:GetSpellPower()
	local heal = BCS:GetHealingPower()
	
	power = power - dmg
	
	label:SetText(L.HEAL_POWER_COLON)
	text:SetText(format("%.0f",power+heal))
	
	frame.tooltip = format(L.SPELL_HEALING_POWER_TOOLTIP, (power+heal), power, heal)
	
	frame:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(this.tooltip)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

function BCS:SetManaRegen(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	local base, casting, mp5, cast_percent = BCS:GetManaRegen()
	
	label:SetText(L.MANA_REGEN_COLON)
	text:SetText(format("%d", (base + mp5 / 2.5 )))
	
	--frame.tooltip = format(L.SPELL_MANA_REGEN_TOOLTIP, (base+mp5), base, mp5)
	if casting > base then
		frame.tooltip = format(L.SPELL_MANA_REGEN_TOOLTIP, ( base + mp5 / 2.5 ), ( base + mp5 / 2.5 ), cast_percent, mp5)
	else
		frame.tooltip = format(L.SPELL_MANA_REGEN_TOOLTIP, ( base + mp5 / 2.5 ), (casting + mp5 / 2.5 ), cast_percent, mp5)
	end
	
	frame:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:SetText(this.tooltip)
		GameTooltip:Show()
	end)
	frame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

function BCS:SetDodge(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	label:SetText(L.DODGE_COLON)
	text:SetText(format("%.2f%%", GetDodgeChance()))
end

function BCS:SetParry(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	label:SetText(L.PARRY_COLON)
	if class == "PRIEST" or class == "WARLOCK" or  class == "MAGE" or class == "DRUID" then
		text:SetText(L.NONE)
	else
		text:SetText(format("%.2f%%", GetParryChance()))
	end
	
end

function BCS:SetBlock(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	label:SetText(L.BLOCK_COLON)
	if class == "WARRIOR" or class == "PALADIN" or  class == "SHAMAN" then
		local blockvalue = BCS:GetBlockValue()
		text:SetText(format("%.2f%%", GetBlockChance()))
		frame.tooltip = format(L.BLOCK_TOOLTIP, blockvalue)
		
		frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(this.tooltip)
			GameTooltip:Show()
		end)
		frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	else
		text:SetText(L.NONE)
	end
end

function BCS:SetDefense(statFrame)
	local base, modifier = UnitDefense("player")

	local frame = statFrame
	local label = getglobal(statFrame:GetName() .. "Label")
	local text = getglobal(statFrame:GetName() .. "StatText")
	
	label:SetText(TEXT(DEFENSE_COLON))
	
	local posBuff = 0
	local negBuff = 0
	if ( modifier > 0 ) then
		posBuff = modifier
	elseif ( modifier < 0 ) then
		negBuff = modifier
	end
	PaperDollFormatStat(DEFENSE_COLON, base, posBuff, negBuff, frame, text)
end

function BCS:SetRangedDamage(statFrame)
	local label = getglobal(statFrame:GetName() .. "Label")
	local damageText = getglobal(statFrame:GetName() .. "StatText")
	local damageFrame = statFrame
	
	label:SetText(TEXT(DAMAGE_COLON))
	
	damageFrame:SetScript("OnEnter", CharacterRangedDamageFrame_OnEnter)
	damageFrame:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)

	-- If no ranged attack then set to n/a
	if ( PaperDollFrame.noRanged ) then
		damageText:SetText(NOT_APPLICABLE)
		damageFrame.damage = nil
		return
	end

	local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = UnitRangedDamage("player")
	local displayMin = max(floor(minDamage),1)
	local displayMax = max(ceil(maxDamage),1)

	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg

	local baseDamage = (minDamage + maxDamage) * 0.5
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent
	local totalBonus = (fullDamage - baseDamage)
	local damagePerSecond = (max(fullDamage,1) / rangedAttackSpeed)
	local tooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1)

	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText:SetText(displayMin.." - "..displayMax)	
		else
			damageText:SetText(displayMin.."-"..displayMax)
		end
	else
		local colorPos = "|cff20ff20"
		local colorNeg = "|cffff2020"
		local color
		if ( totalBonus > 0 ) then
			color = colorPos
		else
			color = colorNeg
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText:SetText(color..displayMin.." - "..displayMax.."|r")	
		else
			damageText:SetText(color..displayMin.."-"..displayMax.."|r")
		end
		if ( physicalBonusPos > 0 ) then
			tooltip = tooltip..colorPos.." +"..physicalBonusPos.."|r"
		end
		if ( physicalBonusNeg < 0 ) then
			tooltip = tooltip..colorNeg.." "..physicalBonusNeg.."|r"
		end
		if ( percent > 1 ) then
			tooltip = tooltip..colorPos.." x"..floor(percent*100+0.5).."%|r"
		elseif ( percent < 1 ) then
			tooltip = tooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r"
		end
		damageFrame.tooltip = tooltip.." "..format(TEXT(DPS_TEMPLATE), damagePerSecond)
	end
	damageFrame.attackSpeed = rangedAttackSpeed
	damageFrame.damage = tooltip
	damageFrame.dps = damagePerSecond
end

function BCS:SetRangedAttackSpeed(startFrame)
	local label = getglobal(startFrame:GetName() .. "Label")
	local damageText = getglobal(startFrame:GetName() .. "StatText")
	local damageFrame = startFrame
	
	label:SetText(TEXT(SPEED)..":")

	-- If no ranged attack then set to n/a
	if ( PaperDollFrame.noRanged ) then
		damageText:SetText(NOT_APPLICABLE)
		damageFrame.damage = nil
		return
	end

	local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = UnitRangedDamage("player")
	local displayMin = max(floor(minDamage),1)
	local displayMax = max(ceil(maxDamage),1)

	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg

	local baseDamage = (minDamage + maxDamage) * 0.5
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent
	local totalBonus = (fullDamage - baseDamage)
	local damagePerSecond = (max(fullDamage,1) / rangedAttackSpeed)
	local tooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1)

	if ( totalBonus == 0 ) then
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText:SetText(displayMin.." - "..displayMax)	
		else
			damageText:SetText(displayMin.."-"..displayMax)
		end
	else
		local colorPos = "|cff20ff20"
		local colorNeg = "|cffff2020"
		local color
		if ( totalBonus > 0 ) then
			color = colorPos
		else
			color = colorNeg
		end
		if ( ( displayMin < 100 ) and ( displayMax < 100 ) ) then 
			damageText:SetText(color..displayMin.." - "..displayMax.."|r")	
		else
			damageText:SetText(color..displayMin.."-"..displayMax.."|r")
		end
		if ( physicalBonusPos > 0 ) then
			tooltip = tooltip..colorPos.." +"..physicalBonusPos.."|r"
		end
		if ( physicalBonusNeg < 0 ) then
			tooltip = tooltip..colorNeg.." "..physicalBonusNeg.."|r"
		end
		if ( percent > 1 ) then
			tooltip = tooltip..colorPos.." x"..floor(percent*100+0.5).."%|r"
		elseif ( percent < 1 ) then
			tooltip = tooltip..colorNeg.." x"..floor(percent*100+0.5).."%|r"
		end
		damageFrame.tooltip = tooltip.." "..format(TEXT(DPS_TEMPLATE), damagePerSecond)
	end
	
	damageText:SetText(format("%.2f", rangedAttackSpeed))
	
	damageFrame.attackSpeed = rangedAttackSpeed
	damageFrame.damage = tooltip
	damageFrame.dps = damagePerSecond
end

function BCS:SetRangedAttackPower(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	label:SetText(TEXT(ATTACK_POWER_COLON))
	
	-- If no ranged attack then set to n/a
	if ( PaperDollFrame.noRanged ) then
		text:SetText(NOT_APPLICABLE)
		frame.tooltip = nil
		return
	end
	if ( HasWandEquipped() ) then
		text:SetText("--")
		frame.tooltip = nil
		return
	end

	local base, posBuff, negBuff = UnitRangedAttackPower("player")
	PaperDollFormatStat(RANGED_ATTACK_POWER, base, posBuff, negBuff, frame, text)
	frame.tooltipSubtext = format(RANGED_ATTACK_POWER_TOOLTIP, base/ATTACK_POWER_MAGIC_NUMBER)
end

function BCS:UpdatePaperdollStats(prefix, index)
	local stat1 = getglobal(prefix..1)
	local stat2 = getglobal(prefix..2)
	local stat3 = getglobal(prefix..3)
	local stat4 = getglobal(prefix..4)
	local stat5 = getglobal(prefix..5)
	local stat6 = getglobal(prefix..6)

	stat1:SetScript("OnEnter", nil)
	stat2:SetScript("OnEnter", nil)
	stat3:SetScript("OnEnter", nil)
	stat4:SetScript("OnEnter", nil)
	stat4:SetScript("OnEnter", nil)
	stat5:SetScript("OnEnter", nil)
	stat6:SetScript("OnEnter", nil)
	
	stat1.tooltip = nil
	stat2.tooltip = nil
	stat3.tooltip = nil
	stat4.tooltip = nil
	stat4.tooltip = nil
	stat5.tooltip = nil
	stat6.tooltip = nil

	stat4:Show()
	stat5:Show()
	stat6:Show()

	local return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower
	
	if ( index == "PLAYERSTAT_SPELL_COMBAT" ) or ( index == "PLAYERSTAT_SPELL_SCHOOLS" ) then
		if BCS:IsNampowerReady() then
			return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, 
            arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower = 0, 0, "", 0, 0, 0, 0, 0, 0, 0
		else
		return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower = BCS:GetSpellPower(school)
		end
	end

	if ( index == "PLAYERSTAT_BASE_STATS" ) then
		BCS:SetStat(stat1, 1)
		BCS:SetStat(stat2, 2)
		BCS:SetStat(stat3, 3)
		BCS:SetStat(stat4, 4)
		BCS:SetStat(stat5, 5)
		BCS:SetArmor(stat6)
	elseif ( index == "PLAYERSTAT_MELEE_COMBAT" ) then
		BCS:SetDamage(stat1)
		BCS:SetAttackSpeed(stat2)
		BCS:SetAttackPower(stat3)
		BCS:SetRating(stat4, "MELEE")
		BCS:SetMeleeCritChance(stat5)
		BCS:SetMeleeAttackSpeed(stat6)
	elseif ( index == "PLAYERSTAT_RANGED_COMBAT" ) then
		BCS:SetRangedDamage(stat1)
		BCS:SetRangedAttackSpeed(stat2)
		BCS:SetRangedAttackPower(stat3)
		BCS:SetRating(stat4, "RANGED")
		BCS:SetRangedCritChance(stat5)
		BCS:SetRangedAttackSpeed6(stat6)
	elseif ( index == "PLAYERSTAT_SPELL_COMBAT" ) then
		BCS:SetSpellPower(stat1,nil,return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower)
		BCS:SetRating(stat2, "SPELL")
		BCS:SetSpellCritChance(stat3)
		BCS:SetHealing(stat4)
		BCS:SetManaRegen(stat5)
		BCS:SetHaste(stat6,index)
	elseif ( index == "PLAYERSTAT_SPELL_SCHOOLS" ) then
		BCS:SetSpellPower(stat1, "Arcane",return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower)
		BCS:SetSpellPower(stat2, "Fire",  return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower)
		BCS:SetSpellPower(stat3, "Frost", return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower)
		BCS:SetSpellPower(stat4, "Holy",  return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower)
		BCS:SetSpellPower(stat5, "Nature",return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower)
		BCS:SetSpellPower(stat6, "Shadow",return_spellPower, return_secondaryPower, return_secondaryPowerName, return_damagePower, arcanePower, firePower, frostPower, holyPower, naturePower, shadowPower)
	elseif ( index == "PLAYERSTAT_DEFENSES" ) then
		BCS:SetArmor(stat1)
		BCS:SetDefense(stat2)
		BCS:SetDodge(stat3)
		BCS:SetParry(stat4)
		BCS:SetBlock(stat5)
		stat6:Hide()
	end
end

local function PlayerStatFrameLeftDropDown_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(this.owner), this.value)
	IndexLeft = this.value
	BCSConfig["DropdownLeft"] = IndexLeft
	BCS:UpdatePaperdollStats("PlayerStatFrameLeft", this.value)
end

local function PlayerStatFrameRightDropDown_OnClick()
	UIDropDownMenu_SetSelectedValue(getglobal(this.owner), this.value)
	IndexRight = this.value
	BCSConfig["DropdownRight"] = IndexRight
	BCS:UpdatePaperdollStats("PlayerStatFrameRight", this.value)
end

local function PlayerStatFrameLeftDropDown_Initialize()
	local info = {}
	local checked = nil
	for i=1, getn(BCS.PLAYERSTAT_DROPDOWN_OPTIONS) do
		info.text = BCS.L[BCS.PLAYERSTAT_DROPDOWN_OPTIONS[i]]
		info.func = PlayerStatFrameLeftDropDown_OnClick
		info.value = BCS.PLAYERSTAT_DROPDOWN_OPTIONS[i]
		info.checked = checked
		info.owner = UIDROPDOWNMENU_OPEN_MENU
		UIDropDownMenu_AddButton(info)
	end
end

local function PlayerStatFrameRightDropDown_Initialize()
	local info = {}
	local checked = nil
	for i=1, getn(BCS.PLAYERSTAT_DROPDOWN_OPTIONS) do
		info.text = BCS.L[BCS.PLAYERSTAT_DROPDOWN_OPTIONS[i]]
		info.func = PlayerStatFrameRightDropDown_OnClick
		info.value = BCS.PLAYERSTAT_DROPDOWN_OPTIONS[i]
		info.checked = checked
		info.owner = UIDROPDOWNMENU_OPEN_MENU
		UIDropDownMenu_AddButton(info)
	end
end

function PlayerStatFrameLeftDropDown_OnLoad()
	RaiseFrameLevel(this)
	RaiseFrameLevel(getglobal(this:GetName() .. "Button"))
	UIDropDownMenu_Initialize(this, PlayerStatFrameLeftDropDown_Initialize)
	UIDropDownMenu_SetWidth(99, this)
	UIDropDownMenu_JustifyText("LEFT")
end

function PlayerStatFrameRightDropDown_OnLoad()
	RaiseFrameLevel(this)
	RaiseFrameLevel(getglobal(this:GetName() .. "Button"))
	UIDropDownMenu_Initialize(this, PlayerStatFrameRightDropDown_Initialize)
	UIDropDownMenu_SetWidth(99, this)
	UIDropDownMenu_JustifyText("LEFT")
end

function BCS:SetHaste(statFrame,index)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	
	local showSchool
	local haste
	local extend_str
	local val1 = nil
	local val2 = nil
	
	if self:IsNampowerReady() then
		local castSpeed = GetUnitField("player", "modCastSpeed")
		if castSpeed then
			haste = (1 / castSpeed - 1) * 100
		end
	end
	
	if not haste then
		local val1,val2 = BCS:EstimateHaste()
		if val1 == nil then
			haste = BCS:GetHaste()
		else
			haste = val1
		end
	end
	local haste_str = format("%.2f%%", haste)
	local reduce = (1 - 1/(1 + haste/100)) * 100
	local reduce_str = format("%.2f%%", math.abs(reduce))
	
	if haste < -0.0001 then
		extend_str = "延长"
	else 
		extend_str = "缩短"
	end
	
	label:SetText(L.HASTE_COLON)
	
	if val1 ~=nil and val2 ~= "general" then
		frame.tooltip = format(L.HASTE_TOOLTIP_3, val2 , extend_str, reduce_str)
	else
		frame.tooltip = format(L.HASTE_TOOLTIP_4, extend_str, reduce_str)
	end
	text:SetText(format("%.2f%%", haste))
	statFrame:Show()
	
	if frame.tooltip then
		frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(this.tooltip)
			GameTooltip:Show()
		end)
		frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

function BCS:SetRangedAttackSpeed6(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	label:SetText(L.HASTE_COLON)
	local range_attack_speed_str
	if class == "PALADIN" or class == "SHAMAN" or class == "DRUID" then
		range_attack_speed = L.NONE
		range_attack_speed_str = L.NONE
		frame.tooltip = format(L.HASTE_RANGE_TOOLTIP,range_attack_speed_str)
		text:SetText(range_attack_speed)
	else 
		local rangedAttackSpeed = UnitRangedDamage("player")
		local RangedOriWeaponSpeed = BCS:GetOriWeaponSpeed(18)
		local range_attack_speed = (RangedOriWeaponSpeed / rangedAttackSpeed -1 ) *100
		if range_attack_speed > -0.001 and range_attack_speed <0 then
			range_attack_speed = 0
		end
		range_attack_speed_str = format("%.2f%%", range_attack_speed)
		frame.tooltip = format(L.HASTE_RANGE_TOOLTIP,range_attack_speed_str)
		text:SetText(format("%.2f%%", range_attack_speed))
	end
	
	
	statFrame:Show()
	if frame.tooltip then
		frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(this.tooltip)
			GameTooltip:Show()
		end)
		frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

function BCS:SetMeleeAttackSpeed(statFrame)
	local frame = statFrame 
	local text = getglobal(statFrame:GetName() .. "StatText")
	local label = getglobal(statFrame:GetName() .. "Label")
	label:SetText(L.HASTE_COLON)
	local melee_attack_speed_str
	local mainHandWeaponSpeed
	local mainHandSpeed,_ = UnitAttackSpeed("player")
	if class == "DRUID" then
		if BCS:GetDruidForm() == L_FORM.BEAR then
			mainHandWeaponSpeed = 2.5
		elseif BCS:GetDruidForm() == L_FORM.CAT then
			mainHandWeaponSpeed = 1.0
		else mainHandWeaponSpeed = BCS:GetOriWeaponSpeed(16)
		end
	else 
		mainHandWeaponSpeed = BCS:GetOriWeaponSpeed(16)
	end
	local melee_attack_speed = (mainHandWeaponSpeed / mainHandSpeed - 1 ) * 100
	if melee_attack_speed > -0.001 and melee_attack_speed <0 then
		melee_attack_speed = 0
	end
	melee_attack_speed_str = format("%.2f%%", melee_attack_speed)
	frame.tooltip = format(L.HASTE_MELEE_TOOLTIP,melee_attack_speed_str)
	text:SetText(format("%.2f%%", melee_attack_speed))
	statFrame:Show()
	if frame.tooltip then
		frame:SetScript("OnEnter", function()
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
			GameTooltip:SetText(this.tooltip)
			GameTooltip:Show()
		end)
		frame:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
end

function BCS:GetDruidForm()
	local forms = {
		[5487] = L_FORM.BEAR,
		[9634] = L_FORM.BEAR,
		[768] = L_FORM.CAT,
		[1066] = L_FORM.AQUATIC,
		[783] = L_FORM.TRAVEL,
		[45705] = L_FORM.TREEOFLIFE,
		[24858] = L_FORM.MOONKIN,
	}
	for i= 1, 32 do
		local _, _, spellID = UnitBuff("player",i)
		if spellID and forms[spellID] then
			return forms[spellID]
		end
	end
	return L_FORM.OTHER
end

function BCS:IsNampowerReady()
	if not GetNampowerVersion then
		return false
	end
	local a, b, _ = GetNampowerVersion()
	return a > 2 or ( a == 2 and b >= 31)
end