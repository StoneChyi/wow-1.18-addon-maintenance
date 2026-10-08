local module, L = BigWigs:ModuleDeclaration("Loktanag the Vile", "Timbermaw Hold")

-- module variables
module.revision = 30138
module.enabletrigger = module.translatedName
module.toggleoptions = { "secretionhit", "secretionsay", "secretionmark", "secretioncd", "secretionzone", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}


-- module defaults
module.defaultDB = {
	secretionhit = true,
	secretionsay = true,
	secretionmark = true,
	secretioncd = true,
	secretionzone = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "Loktanag",

		secretionhit_cmd = "secretionhit",
		secretionhit_name = "Infected Secretion hit warning",
		secretionhit_desc = "Warning message about the target of Infected Secretion (spawns adds and a damage zone on the floor)",

		secretionsay_cmd = "secretionsay",
		secretionsay_name = "Infected Secretion hit say",
		secretionsay_desc = "Announce to /say if Infected Secretion targeted you (spawns adds and a damage zone on the floor on your location)",

		secretionmark_cmd = "secretionmark",
		secretionmark_name = "Infected Secretion hit mark",
		secretionmark_desc = "Mark the target of Infected Secretion with Square",

		secretioncd_cmd = "secretioncd",
		secretioncd_name = "Infected Secretion cd bar",
		secretioncd_desc = "Cooldown bar for Infected Secretion",

		secretionzone_cmd = "secretionzone",
		secretionzone_name = "Infected Secretion zone",
		secretionzone_desc = "Personal warning when you stand in Infected Secretion",

		trigger_secretionHit = "Loktanag the Vile's Infected Secretion hits (.+) for ",
		msg_secretionHit = "Adds and Zone on %s",
		say_secretionHit = "Adds and Zone on Me!",
		bar_secretionCd = "next Secretion",
		trigger_secretionZone = "You are afflicted by Infected Secretion",
		trigger_secretionZoneTick = "You suffer .+ Nature damage from Loktanag the Vile's Infected Secretion",
		warn_secretionZone = "MOVE",
		trigger_secretionZoneFade = "Infected Secretion fades from you.",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Loktanag",

		secretionhit_cmd = "secretionhit",
		secretionhit_name = "感染分泌物命中警告",
		secretionhit_desc = "被感染分泌物击中时的警告信息（会召唤小怪并在脚下生成伤害区域）",

		secretionsay_cmd = "secretionsay",
		secretionsay_name = "感染分泌物命中喊话",
		secretionsay_desc = "当你成为感染分泌物目标时向/say频道喊话（会在你位置召唤小怪和伤害区域）",

		secretionmark_cmd = "secretionmark",
		secretionmark_name = "感染分泌物命中标记",
		secretionmark_desc = "用方块标记感染分泌物的目标",

		secretioncd_cmd = "secretioncd",
		secretioncd_name = "感染分泌物冷却条",
		secretioncd_desc = "感染分泌物的冷却计时条",

		secretionzone_cmd = "secretionzone",
		secretionzone_name = "感染分泌物区域警告",
		secretionzone_desc = "当你站在感染分泌物区域内时的个人警告",

		trigger_secretionHit = "落潭的感染分泌击中(.+)造成",
		msg_secretionHit = "%s会出小怪和毒伤区域",
		say_secretionHit = "我会出小怪和毒伤区域！",
		bar_secretionCd = "下次感染分泌物",
		trigger_secretionZone = "你受到了感染分泌效果的影响",
		trigger_secretionZoneTick = "你受到.+点自然伤害（落潭的感染分泌）",
		warn_secretionZone = "快离开",
		trigger_secretionZoneFade = "感染分泌效果从你身上消失了",
	}
end)

-- timer and icon variables
local timer = {
	secretion = 3,
	secretionCd = {12, 14},
	secretionMarkDuration = 4,
}

local icon = {
	secretion = "Spell_Nature_NullifyDisease",
}

local syncName = {
	secretionHit = "THLoktanagSecretionHit" .. module.revision,
}

local guid = {
	loktanag = "0xF13000085B279753",
}

local spellId = {
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "FadesEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "SpellEvent")

	self:ThrottleSync(3, syncName.secretionHit)
end

function module:OnSetup()
end

function module:OnEngage()
end

function module:OnDisengage()
end

function module:AfflictionEvent(msg)
	if self.db.profile.secretionzone then
		if string.find(msg, L["trigger_secretionZone"]) then
			self:Sound("Info")
			self:WarningSign(icon.secretion, timer.secretion, false, L["warn_secretionZone"])
			return
		elseif string.find(msg, L["trigger_secretionZoneTick"]) then
			self:Sound("Info")
			return
		end
	end
end

function module:FadesEvent(msg)
	if self.db.profile.secretionzone and string.find(msg, L["trigger_secretionZoneFade"]) then
		self:RemoveWarningSign(icon.secretion)
		self:Sound("Long")
	end
end

function module:SpellEvent(msg)
	local _, _, player = string.find(msg, L["trigger_secretionHit"])
	if player then
		player = player == "你" and UnitName("player") or player
		self:Sync(syncName.secretionHit .. " " .. player) 
		return
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.secretionHit and rest then
		self:InfectedSecretionHit(rest)
	end
end

function module:InfectedSecretionHit(player)
	self:RemoveBar(L["bar_secretionCd"])

	if self.db.profile.secretionhit then
		self:Message(string.format(L["msg_secretionHit"],player), "Urgent")
	end

	if self.db.profile.secretionsay and player == UnitName("player") then
		SendChatMessage(L["say_secretionHit"], "SAY")
	end

	if self.db.profile.secretionmark then
		self:SetRaidTargetForPlayer(player, "Square")
		self:ScheduleEvent("RemoveSecretionMark"..player, self.RestoreInitialRaidTargetForPlayer, timer.secretionMarkDuration, self, player)
	end

	if self.db.profile.secretioncd then
		self:IntervalBar(L["bar_secretionCd"], timer.secretionCd[1], timer.secretionCd[2], icon.secretion)
	end
end
