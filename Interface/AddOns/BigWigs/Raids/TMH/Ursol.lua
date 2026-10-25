
local module, L = BigWigs:ModuleDeclaration("Ursol", "Timbermaw Hold")
local BC = AceLibrary("Babble-Class-2.2")
local _, playerClass = UnitClass("player")

module.revision = 30000
module.enabletrigger = module.translatedName
module.toggleoptions = {"transition", "roarofterror", "decurse", "adds", "shock", "bosskill"}
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

	decurse_cmd = "decurse",
	decurse_name = "Painful Roar (Decurse)",
	decurse_desc = "Warn raid to remove curses when Ursol roars in pain",

	shock_cmd = "shock",
	shock_name = "Shattering Earth (stop healing)",
	shock_desc = "Warn when someone is afflicted by Shattering Earth (healing stopped)",

	trigger_shockYou = "^You are afflicted by Shattering Earth",
	trigger_shockOther = "(.+) is afflicted by Shattering Earth",
	msg_shockYou = "Shattering Earth on YOU - healers STOP healing you!",
	msg_shockOther = "Shattering Earth: %s - healers STOP! Mages/Druids decurse!",

	adds_cmd = "adds",
	adds_name = "Adds Spawn Warning",
	adds_desc = "Warn raid to switch to the adds when Ursol calls his children",

	trigger_transition = "Miserable insects like",
	trigger_bearGod = "You gain Blessing of the Bear God",
	trigger_presenceFadeUrsol = "Presence of the Wild God fades from Ursol",
	trigger_roarOfTerrorCast = "Ursol begins to cast Roar of Terror",
	trigger_painfulRoar = "roar of pain",
	trigger_callAdds = "protect your ancestors",

	bar_presenceOfWildGod = "RP - Immune",
	bar_blessingOfBearGod = "Add Phase",
	bar_roarOfTerror = "Roar of Terror",
	msg_roarOfTerror = "Roar of Terror - Touch a Pool!",
	msg_painfulRoar = "Painful Roar - Decurse!",
	msg_callAdds = "Adds! Switch Targets!",
	warn_tremorTotem = "Cast tremorTotem",
	warn_decurse = "Remove Curse",
} end )

L:RegisterTranslations("zhCN", function() return {
	cmd = "Ursol",

	transition_cmd = "transition",
	transition_name = "阶段转换计时器",
	transition_desc = "乌索尔/乌索克阶段转换计时器",

	roarofterror_cmd = "roarofterror",
	roarofterror_name = "恐惧怒吼",
	roarofterror_desc = "恐惧怒吼施法计时器",

	decurse_cmd = "decurse",
	decurse_name = "痛苦的咆哮（解诅咒）",
	decurse_desc = "乌索尔发出痛苦的咆哮时提示全团解诅咒",

	shock_cmd = "shock",
	shock_name = "震天撼地（治疗停手）",
	shock_desc = "当有人中了震天撼地时提示治疗停手、法师/德鲁伊解诅咒",

	trigger_shockYou = "^你受到了震天撼地效果的影响",
	trigger_shockOther = "(.+)受到了震天撼地效果的影响",
	msg_shockYou = "你中了震天撼地——治疗对你停手！",
	msg_shockOther = "震天撼地：%s——治疗停手！FS/XD解诅咒！",

	adds_cmd = "adds",
	adds_name = "召唤小怪提示",
	adds_desc = "乌索尔召唤子嗣时提示全团转火小怪",

	trigger_transition = "你们这些卑劣的蝼蚁",  -- 根据实际游戏文本可能需要调整
	trigger_bearGod = "你获得了熊神祝福的效果",
	trigger_presenceFadeUrsol = "荒野之神降临效果从乌索尔身上消失",
	trigger_roarOfTerrorCast = "发出了一声震耳欲聋的咆哮",
	trigger_painfulRoar = "发出痛苦的咆哮",
	trigger_callAdds = "快来保护汝之先祖",

	bar_presenceOfWildGod = "角色扮演-免疫",
	bar_blessingOfBearGod = "小怪阶段（全团套反恐）",
	bar_roarOfTerror = "恐惧怒吼",
	msg_roarOfTerror = "恐惧怒吼-触碰地面花纹！",
	msg_painfulRoar = "痛苦的咆哮-快解诅咒！",
	msg_callAdds = "小怪出现-快转火小怪！",
	warn_tremorTotem = "插战栗",
	warn_decurse = "解诅咒",
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
	decurse           = "Spell_Holy_RemoveCurse",
}

local syncName = {
	transition        = "UrsolTransition"..module.revision,
	blessingOfBearGod = "UrsolBlessingOfBearGod"..module.revision,
	presenceFadeUrsol = "UrsolPresenceFadeUrsol"..module.revision,
	roarOfTerror      = "UrsolRoarOfTerror"..module.revision,
	painfulRoar       = "UrsolPainfulRoar"..module.revision,
	callAdds          = "UrsolCallAdds"..module.revision,
	shock             = "UrsolShock"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "CHAT_MSG_RAID_BOSS_EMOTE")
        -- self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent")  -- 已移除
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "FadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "ShockEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "ShockEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "ShockEvent")
	self:ThrottleSync(5, syncName.transition)
	self:ThrottleSync(120, syncName.blessingOfBearGod)
	self:ThrottleSync(5, syncName.presenceFadeUrsol)
	self:ThrottleSync(5, syncName.roarOfTerror)
	self:ThrottleSync(5, syncName.painfulRoar)
	self:ThrottleSync(5, syncName.callAdds)
	-- 名字烤进 sync 名，各玩家互不节流
	self:ThrottleSync(0, syncName.shock)
end

function module:OnSetup()
end
function module:OnEngage() end
function module:OnDisengage() end

function module:CHAT_MSG_MONSTER_YELL(msg)
	if string.find(msg, L["trigger_transition"]) then
		self:Sync(syncName.transition)
	elseif string.find(msg, L["trigger_callAdds"]) then
		self:Sync(syncName.callAdds)
	end
end

function module:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if string.find(msg, L["trigger_roarOfTerrorCast"]) then
		self:Sync(syncName.roarOfTerror)
	elseif string.find(msg, L["trigger_painfulRoar"]) then
		self:Sync(syncName.painfulRoar)
	elseif string.find(msg, L["trigger_callAdds"]) then
		self:Sync(syncName.callAdds)
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

-- 震天撼地：自身 trigger 必须 ^ 锚定；他人分支捕获到「你」时归一为本地玩家名
function module:ShockEvent(msg)
	if string.find(msg, L["trigger_shockYou"]) then
		self:Sync(syncName.shock .. " " .. UnitName("player"))
		return
	end
	local _, _, target = string.find(msg, L["trigger_shockOther"])
	if target then
		if target == "你" then target = UnitName("player") end
		self:Sync(syncName.shock .. " " .. target)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.transition and self.db.profile.transition then
		self:Bar(L["bar_presenceOfWildGod"], timer.presenceOfWildGod, icon.presenceOfWildGod, color.presenceOfWildGod)
	elseif sync == syncName.blessingOfBearGod and self.db.profile.transition then
		self:Bar(L["bar_blessingOfBearGod"], timer.blessingOfBearGod, icon.blessingOfBearGod, color.blessingOfBearGod)
	elseif sync == syncName.roarOfTerror and self.db.profile.roarofterror then
		self:Message(L["msg_roarOfTerror"], "Urgent", nil, "voiceFear")
		self:Bar(L["bar_roarOfTerror"], timer.roarOfTerror, icon.roarOfTerror, color.roarOfTerror)
		if UnitClass("Player") == BC["Shaman"] then
			self:WarningSign(icon.tremorTotem, 3, false, L["warn_tremorTotem"])
		end
	elseif sync == syncName.painfulRoar and self.db.profile.decurse then
		self:Message(L["msg_painfulRoar"], "Urgent")
		if UnitClass("Player") == BC["Mage"] or UnitClass("Player") == BC["Druid"] then
			self:WarningSign(icon.decurse, 3, false, L["warn_decurse"])
		end
	elseif sync == syncName.callAdds and self.db.profile.adds then
		self:Message(L["msg_callAdds"], "Urgent", nil, "voiceSwitch")
	elseif sync == syncName.presenceFadeUrsol and self.db.profile.transition then
		self:RemoveBar(L["bar_blessingOfBearGod"])
	elseif sync == syncName.shock and rest and self.db.profile.shock then
		self:Sound("voiceStopheal")
		if rest == UnitName("player") then
			self:Message(L["msg_shockYou"], "Personal", true)
		else
			self:Message(string.format(L["msg_shockOther"], rest), "Urgent")
		end
	end
end

