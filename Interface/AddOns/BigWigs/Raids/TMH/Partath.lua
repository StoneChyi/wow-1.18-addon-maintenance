local module, L = BigWigs:ModuleDeclaration("Chieftain Partath", "Timbermaw Hold")

module.revision = 30002
module.enabletrigger = module.translatedName
module.toggleoptions = {"immune", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Partath",

	immune_cmd = "immune",
	immune_name = "Immune (Shade of the Withermaw) Timer",
	immune_desc = "Shows a 15 second bar when Chieftain Partath gains Shade of the Withermaw",

	trigger_immuneGain = "Chieftain Partath gains Shade of the Withermaw",
	trigger_immuneFade = "Shade of the Withermaw fades from Chieftain Partath",

	bar_nextImmune = "Next Immune",

	msg_immune = "Chieftain Partath is immune - bring Illuminators to him!",
	msg_immuneOver = "Immune ended!",
} end )

L:RegisterTranslations("zhCN", function() return {
    cmd = "Partath",

    immune_cmd = "immune",
    immune_name = "免疫（枯萎复苏）计时器",
    immune_desc = "当大酋长帕塔斯获得枯萎复苏时警报",

    trigger_immuneGain = "大酋长帕萨斯获得了枯喉之影的效果",
    trigger_immuneFade = "枯喉之影效果从大酋长帕萨斯身上消失",

    bar_nextImmune = "下次免疫",

    msg_immune = "大酋长免疫了！带照明者到他身边！",
    msg_immuneOver = "免疫已结束！",
} end )

local timer = {
	immuneCycle = 52,
}

local icon = {
	immune = "Spell_Shadow_SummonVoidWalker",
	immuneCycle = "spell_cloaked_in_shadows_2",
}

local syncName = {
	startNextImmuneBar = "PartathStartBar"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")

end

function module:OnSetup()
end

function module:OnEngage()
	if self.db.profile.immune then
		self:Bar(L["bar_nextImmune"], timer.immuneCycle, icon.immuneCycle, true, "Blue")
	end
end


function module:OnDisengage()
	self:RemoveBar(L["bar_nextImmune"])
end

function module:Event(msg)
	if string.find(msg, L["trigger_immuneGain"]) then
		self:Message(L["msg_immune"], "Urgent", false, "Alarm")
		self:RemoveBar(L["bar_nextImmune"])
	    self:Bar(L["bar_nextImmune"], timer.immuneCycle, icon.immuneCycle, true, "Blue")
	elseif string.find(msg, L["trigger_immuneFade"]) then
		self:Message(L["msg_immuneOver"], "Positive")
	end
end
