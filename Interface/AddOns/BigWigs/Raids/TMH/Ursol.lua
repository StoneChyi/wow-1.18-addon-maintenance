
local module, L = BigWigs:ModuleDeclaration("Ursol", "Timbermaw Hold")
local BC = AceLibrary("Babble-Class-2.2")
local _, playerClass = UnitClass("player")

module.revision = 30000
module.enabletrigger = module.translatedName
module.toggleoptions = {"transition", "roarofterror", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Ursol",

	transition_cmd = "transition",
	transition_name = "Phase Transition Timers",
	transition_desc = "Timers for the Ursol/Ursoc transition phases",

	roarofterror_cmd = "roarofterror",
	roarofterror_name = "Roar of Terror",
	roarofterror_desc = "Timer for Roar of Terror cast",

	trigger_transition = "Miserable insects like",
	trigger_bearGod = "You gain Blessing of the Bear God",
	trigger_presenceFadeUrsol = "Presence of the Wild God fades from Ursol",
	trigger_roarOfTerrorCast = "Ursol begins to cast Roar of Terror",

	bar_presenceOfWildGod = "RP - Immune",
	bar_blessingOfBearGod = "Add Phase",
	bar_roarOfTerror = "Roar of Terror",
	msg_roarOfTerror = "Roar of Terror - Touch a Pool!",
	warn_tremorTotem = "Cast tremorTotem",
} end )

L:RegisterTranslations("zhCN", function() return {
	cmd = "Ursol",

	transition_cmd = "transition",
	transition_name = "阶段转换计时器",
	transition_desc = "乌索尔/乌索克阶段转换计时器",

	roarofterror_cmd = "roarofterror",
	roarofterror_name = "恐惧怒吼",
	roarofterror_desc = "恐惧怒吼施法计时器",

	trigger_transition = "你们这些卑劣的蝼蚁",  -- 根据实际游戏文本可能需要调整
	trigger_bearGod = "你获得了熊神祝福的效果",
	trigger_presenceFadeUrsol = "荒野之神降临效果从乌索尔身上消失",
	trigger_roarOfTerrorCast = "发出了一声震耳欲聋的咆哮",

	bar_presenceOfWildGod = "角色扮演-免疫",
	bar_blessingOfBearGod = "小怪阶段（全团套反恐）",
	bar_roarOfTerror = "恐惧怒吼",
	msg_roarOfTerror = "恐惧怒吼-触碰地面花纹！",
	warn_tremorTotem = "插战栗",
} end)

local timer = {
	presenceOfWildGod = 30,
	blessingOfBearGod = 100,
	roarOfTerror      = 5,
}

local color = {
	presenceOfWildGod = "White",
	blessingOfBearGod = "Green",
	roarOfTerror      = "Orange",
}

local icon = {
	presenceOfWildGod = "Spell_Shadow_Cripple",
	blessingOfBearGod = "Spell_Holy_PowerInfusion",
	roarOfTerror      = "Ability_Druid_ChallangingRoar",
	tremorTotem       = "Spell_Nature_TremorTotem",
}

local syncName = {
	transition        = "UrsolTransition"..module.revision,
	blessingOfBearGod = "UrsolBlessingOfBearGod"..module.revision,
	presenceFadeUrsol = "UrsolPresenceFadeUrsol"..module.revision,
	roarOfTerror      = "UrsolRoarOfTerror"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
        -- self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent")  -- 已移除
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "FadeEvent")
	self:ThrottleSync(5, syncName.transition)
	self:ThrottleSync(120, syncName.blessingOfBearGod)
	self:ThrottleSync(5, syncName.presenceFadeUrsol)
	self:ThrottleSync(5, syncName.roarOfTerror)
end

function module:OnSetup()
end
function module:OnEngage() end
function module:OnDisengage() end

function module:CHAT_MSG_MONSTER_YELL(msg)
	if string.find(msg, L["trigger_transition"]) then
		self:Sync(syncName.transition)
	end
end

function module:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if string.find(msg, L["trigger_roarOfTerrorCast"]) then
		self:Sync(syncName.roarOfTerror)
	end
end

function module:BuffEvent(msg)
	if string.find(msg, L["trigger_bearGod"]) then
		self:Sync(syncName.blessingOfBearGod)
	end
end

function module:FadeEvent(msg)
	if string.find(msg, L["trigger_presenceFadeUrsol"]) then
		self:Sync(syncName.presenceFadeUrsol)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.transition and self.db.profile.transition then
		self:Bar(L["bar_presenceOfWildGod"], timer.presenceOfWildGod, icon.presenceOfWildGod, color.presenceOfWildGod)
	elseif sync == syncName.blessingOfBearGod and self.db.profile.transition then
		self:Bar(L["bar_blessingOfBearGod"], timer.blessingOfBearGod, icon.blessingOfBearGod, color.blessingOfBearGod)
	elseif sync == syncName.roarOfTerror and self.db.profile.roarofterror then
		self:Message(L["msg_roarOfTerror"], "Urgent")
		self:Bar(L["bar_roarOfTerror"], timer.roarOfTerror, icon.roarOfTerror, color.roarOfTerror)
		if UnitClass("Player") == BC["Shaman"] then
			self:WarningSign(icon.tremorTotem, 3, false, L["warn_tremorTotem"])
		end
	elseif sync == syncName.presenceFadeUrsol and self.db.profile.transition then
		self:RemoveBar(L["bar_blessingOfBearGod"])
	end
end

