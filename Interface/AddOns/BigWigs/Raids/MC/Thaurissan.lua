local module, L = BigWigs:ModuleDeclaration("Sorcerer-Thane Thaurissan", "Molten Core")

module.revision = 30003
module.enabletrigger = module.translatedName
module.toggleoptions = {"runetimers", "runeofdetonation", "runeofcombustion", "floorwarn", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Molten Core"],
	AceLibrary("Babble-Zone-2.2")["Molten Core"],
}

-- module defaults
module.defaultDB = {
	runetimers = true,
	runeofdetonation = true,
	runeofcombustion = true,
	floorwarn = true,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Thaurissan",

	runetimers_cmd = "runetimers",
	runetimers_name = "Rune Timers",
	runetimers_desc = "Warns about incoming and ongoing Rune of Detonation and Rune of Combustion",

	runeofdetonation_cmd = "runeofdetonation",
	runeofdetonation_name = "Rune of Detonation Alert",
	runeofdetonation_desc = "Personal alert for Rune of Detonation whether you are correctly outside of the Rune of Power (floor zone)",

	runeofcombustion_cmd = "runeofcombustion",
	runeofcombustion_name = "Rune of Combustion Alert",
	runeofcombustion_desc = "Personal alert for Rune of Combustion whether you are correctly inside of the Rune of Power (floor zone)",

	floorwarn_cmd = "floorwarn",
	floorwarn_name = "Rune of Power Warning",
	floorwarn_desc = "Warns shortly before Rune of Power (floor zone) is recast in a new location (every 25% of boss HP); must be enabled before pull",

	trigger_detonation = "afflicted by Rune of Detonation",
	trigger_combustion = "afflicted by Rune of Combustion",
	trigger_you = "You are afflicted",
	trigger_runeOfDetonationFade = "Rune of Detonation fades from you",
	trigger_runeOfCombustionFade = "Rune of Combustion fades from you",

	trigger_runeOfPowerYou = "You are afflicted by Rune of Power",
	trigger_runeOfPowerFade = "Rune of Power fades from you",

	msg_detonation = "Move out of the Zone - Rune of Detonation",
	msg_detonationSolved = "Stay out of the Zone - Rune of Detonation",
	msg_combustion = "Get into the Zone - Rune of Combustion",
	msg_combustionSolved = "Stay in the Zone - Rune of Combustion",
	bar_runeDetonation = "Detonation (move out)",
	bar_runeCombustion = "Combustion (get in)",
	bar_detonationNext = "next Detonation Rune",
	bar_combustionNext = "next Combustion Rune",
	warn_detonation = "MOVE OUT",
	warn_combustion = "GET IN",
	
	msg_floorwarn = "Floor Zone moving soon! %s%%",
} end)

L:RegisterTranslations("zhCN", function() return {
	cmd = "Thaurissan",

	runetimers_cmd = "runetimers",
	runetimers_name = "符文计时",
	runetimers_desc = "预警即将到来和正在进行的引爆符文与燃烧符文",

	runeofdetonation_cmd = "runeofdetonation",
	runeofdetonation_name = "爆裂符文警报",
	runeofdetonation_desc = "个人警报：你是否正确站在能量符文（地面区域）之外",

	runeofcombustion_cmd = "runeofcombustion",
	runeofcombustion_name = "燃烧符文警报",
	runeofcombustion_desc = "个人警报：你是否正确站在能量符文（地面区域）之内",

	floorwarn_cmd = "floorwarn",
	floorwarn_name = "能量符文预警",
	floorwarn_desc = "在能量符文（地面区域）即将刷新到新位置前发出警告（每消耗首领25%血量触发）；必须在战斗开始前启用",

    trigger_detonation = "受到了爆裂符文效果的影响",
    trigger_combustion = "受到了燃烧符文效果的影响",
    trigger_you = "你受到了",
    trigger_runeOfDetonationFade = "爆裂符文效果从你身上消失了",
    trigger_runeOfCombustionFade = "燃烧符文效果从你身上消失了",

    trigger_runeOfPowerYou = "你受到了能量符文效果的影响",
    trigger_runeOfPowerFade = "能量符文效果从你身上消失了",

	msg_detonation = "离开区域-爆裂符文",
	msg_detonationSolved = "待在区域外-爆裂符文",
	msg_combustion = "进入区域-燃烧符文",
	msg_combustionSolved = "待在区域内-燃烧符文",
	bar_runeDetonation = "爆裂符文（离开）",
	bar_runeCombustion = "燃烧符文（进入）",
	bar_detonationNext = "下一次爆裂符文",
	bar_combustionNext = "下一次燃烧符文",
	warn_detonation = "离开！",
	warn_combustion = "进入！",
	
	msg_floorwarn = "地面区域即将移动！%s%%",
} end)

local hasRuneOfDetonation = false
local hasRuneOfPower = false
local hasRuneOfCombustion = false
local nextFloorWarn = 75
local floorWarn = 3 -- how many % of HP before the recast the warning triggers

local timer = {
	runeCooldown = { 18, 22 }, -- average of 20
	runeDuration = 6,
}
local icon = {
	runeDetonation = "Spell_Shadow_Teleport",
	runeCombustion = "Spell_Fire_SealOfFire",
}
local color = {
	runeDetonation = "Blue",
	runeCombustion = "Orange",
	runeUpcoming = "Gray",
}
local syncName = {
	runeDetonation = "MCThaurissanDetonation" .. module.revision,
	runeCombustion = "MCThaurissanCombusion" .. module.revision,
}
local guid = {
	thaurissan = "0xF13000E12A278C49",
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event")

	self:ThrottleSync(10, syncName.runeDetonation)
	self:ThrottleSync(10, syncName.runeCombustion)
end

function module:OnSetup()
	hasRuneOfDetonation = false
	hasRuneOfPower = false
	hasRuneOfCombustion = false
	nextFloorWarn = 75
end

function module:OnEngage()
	hasRuneOfDetonation = false
	hasRuneOfPower = false
	hasRuneOfCombustion = false
	nextFloorWarn = 75

	if self.db.profile.runetimers then
		self:IntervalBar(L["bar_detonationNext"], timer.runeCooldown[1], timer.runeCooldown[2], icon.runeDetonation, true, color.runeUpcoming)
	end
	if self.db.profile.floorwarn then
		self:ScheduleRepeatingEvent("ThaurissanHealthCheck", self.CheckHealth, 0.25, self)
	end
end

function module:OnDisengage()
	hasRuneOfDetonation = false
	hasRuneOfPower = false
	hasRuneOfCombustion = false
	nextFloorWarn = 75
	self:CancelScheduledEvent("ThaurissanHealthCheck")
end

function module:Event(msg)
	-- Rune of Detonation
	if string.find(msg, L["trigger_detonation"]) then
		self:Sync(syncName.runeDetonation)
		if string.find(msg, L["trigger_you"]) then
			hasRuneOfDetonation = true
			self:CheckRuneCombination()
		end
		return
	elseif string.find(msg, L["trigger_runeOfDetonationFade"]) then
		hasRuneOfDetonation = false
		self:CheckRuneCombination()
		return

	-- Rune of Combustion
	elseif string.find(msg, L["trigger_combustion"]) then
		self:Sync(syncName.runeCombustion)
		if string.find(msg, L["trigger_you"]) then
			hasRuneOfCombustion = true
			self:CheckRuneCombination()
		end
		return
	elseif string.find(msg, L["trigger_runeOfCombustionFade"]) then
		hasRuneOfCombustion = false
		self:CheckRuneCombination()
		return

	-- Rune of Power (floor zone)
	elseif string.find(msg, L["trigger_runeOfPowerYou"]) then
		hasRuneOfPower = true
		self:CheckRuneCombination()
		return
	elseif string.find(msg, L["trigger_runeOfPowerFade"]) then
		hasRuneOfPower = false
		self:CheckRuneCombination()
		return
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.runeDetonation then
		self:DetonationCast()
	elseif sync == syncName.runeCombustion then
		self:CombustionCast()
	end
end

function module:CheckRuneCombination()
	--print("DEBUG: check with detonation "..tostring(hasRuneOfDetonation)..", combustion "..tostring(hasRuneOfCombustion)..", power "..tostring(hasRuneOfPower))

	if hasRuneOfDetonation and self.db.profile.runeofdetonation then
		if hasRuneOfPower then
			self:Message(L["msg_detonation"], "Personal", nil, "RunAway")
			self:WarningSign(icon.runeDetonation, timer.runeDuration, false, L["warn_detonation"])
		else
			self:Message(L["msg_detonationSolved"], "Positive", nil, "Long")
			self:RemoveWarningSign(icon.runeDetonation)
		end
	else
		self:RemoveWarningSign(icon.runeDetonation)
	end

	if hasRuneOfCombustion and self.db.profile.runeofcombustion then
		if not hasRuneOfPower then
			self:Message(L["msg_combustion"], "Personal", nil, "Beware")
			self:WarningSign(icon.runeCombustion, timer.runeDuration, false, L["warn_combustion"])
		else
			self:Message(L["msg_combustionSolved"], "Positive", nil, "Long")
			self:RemoveWarningSign(icon.runeCombustion)
		end
	else
		self:RemoveWarningSign(icon.runeCombustion)
	end
end

function module:CombustionCast()
	-- remove CD bar in case of early cast
	self:RemoveBar(L["bar_combustionNext"])
	if self.db.profile.runetimers then
		-- accurate timer for current rune
		self:Bar(L["bar_runeCombustion"], timer.runeDuration, icon.runeCombustion, true, color.runeCombustion)
		-- schedule next opposite rune
		self:DelayedIntervalBar(timer.runeDuration, L["bar_detonationNext"], timer.runeCooldown[1] - timer.runeDuration, timer.runeCooldown[2] - timer.runeDuration, icon.runeDetonation, true, color.runeUpcoming)
	end
end

function module:DetonationCast()
	-- remove CD bar in case of early cast
	self:RemoveBar(L["bar_detonationNext"])
	if self.db.profile.runetimers then
		-- accurate timer for current rune
		self:Bar(L["bar_runeDetonation"], timer.runeDuration, icon.runeDetonation, true, color.runeDetonation)
		-- schedule next opposite rune
		self:DelayedIntervalBar(timer.runeDuration, L["bar_combustionNext"], timer.runeCooldown[1] - timer.runeDuration, timer.runeCooldown[2] - timer.runeDuration, icon.runeCombustion, true, color.runeUpcoming)
	end
end

function module:CheckHealth()
	if UnitExists(guid.thaurissan) and nextFloorWarn > 0 then
		local percent = math.ceil(100*(UnitHealth(guid.thaurissan)/UnitHealthMax(guid.thaurissan)))
		if percent <= (nextFloorWarn + floorWarn) then
			if self.db.profile.floorwarn then
				self:Message(string.format(L["msg_floorwarn"], nextFloorWarn), "Attention")
			end
			nextFloorWarn = nextFloorWarn - 25
		end
	else
		self:CancelScheduledEvent("ThaurissanHealthCheck")
	end
end