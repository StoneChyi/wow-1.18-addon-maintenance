local module, L = BigWigs:ModuleDeclaration("Loktanag the Vile", "Timbermaw Hold")

-- module variables
module.revision = 30138
module.enabletrigger = module.translatedName
module.toggleoptions = { "secretionhit", "secretionsay", "secretionmark", "secretioncd", "secretionzone", -1, "poisonvine", "spores", "bosskill" }
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
	poisonvine = true,
	spores = true,
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

		poisonvine_cmd = "poisonvine",
		poisonvine_name = "Poison Vine (Disease) alert",
		poisonvine_desc = "Warn when someone is afflicted by Poison Vine so it can be dispelled quickly",

		spores_cmd = "spores",
		spores_name = "Corrupted Spores (Curse) alert",
		spores_desc = "Warn when someone is afflicted by Corrupted Spores so it can be decursed",

		trigger_vineYou = "^You are afflicted by Poison Vine",
		trigger_vineOther = "(.+) is afflicted by Poison Vine",
		trigger_sporesYou = "^You are afflicted by Corrupted Spores",
		trigger_sporesOther = "(.+) is afflicted by Corrupted Spores",
		msg_vineYou = "Poison Vine (Disease) on YOU - call for dispel!",
		msg_vineOther = "Poison Vine on %s - dispel NOW!",
		msg_sporesYou = "Corrupted Spores (Curse) on YOU - get it removed!",
		msg_sporesOther = "Corrupted Spores curse - decurse then AoE adds!",

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

		poisonvine_cmd = "poisonvine",
		poisonvine_name = "毒藤（疾病）警报",
		poisonvine_desc = "当有人中了毒藤时发出警报以便第一时间驱散",

		spores_cmd = "spores",
		spores_name = "腐化孢子（诅咒）警报",
		spores_desc = "当有人中了腐化孢子时发出警报以便解咒",

		trigger_vineYou = "^你受到了毒藤效果的影响",
		trigger_vineOther = "(.+)受到了毒藤效果的影响",
		trigger_sporesYou = "^你受到了腐化孢子效果的影响",
		trigger_sporesOther = "(.+)受到了腐化孢子效果的影响",
		msg_vineYou = "你中了毒藤（疾病）——立刻呼喊驱散！",
		msg_vineOther = "%s 中了毒藤——MS/NQ第一时间驱散！",
		msg_sporesYou = "你中了腐化孢子（诅咒）——FS/XD解咒！",
		msg_sporesOther = "腐化孢子诅咒——FS/XD优先解咒，然后A小怪！",

		trigger_secretionHit = "落潭的感染分泌击中(.+)造成",
		msg_secretionHit = "%s会出小怪和毒伤区域",
		say_secretionHit = "我会出小怪和毒伤区域！",
		bar_secretionCd = "下次感染分泌物",
		trigger_secretionZone = "^你受到了感染分泌效果的影响",
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
	vine = "THLoktanagVine" .. module.revision,
	spores = "THLoktanagSpores" .. module.revision,
}

local guid = {
	loktanag = "0xF13000085B279753",
}

local spellId = {
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "FadesEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE", "SpellEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "SpellEvent")

	self:ThrottleSync(3, syncName.secretionHit)
	self:ThrottleSync(3, syncName.vine)
	self:ThrottleSync(3, syncName.spores)
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
			self:Sound("voiceOut")
			self:WarningSign(icon.secretion, timer.secretion, false, L["warn_secretionZone"])
			return
		elseif string.find(msg, L["trigger_secretionZoneTick"]) then
			self:Sound("voiceOut")
			return
		end
	end

	-- 毒藤（疾病）：自身 trigger 必须 ^ 锚定（防止「王你受到了…」子串误命中）；
	-- 他人分支捕获到「你」时归一为本地玩家名，禁止把字面量当玩家名广播
	if self.db.profile.poisonvine and string.find(msg, L["trigger_vineYou"]) then
		self:Sync(syncName.vine .. " " .. UnitName("player"))
		return
	end
	local _, _, vineTarget = string.find(msg, L["trigger_vineOther"])
	if vineTarget then
		if vineTarget == "你" then vineTarget = UnitName("player") end
		self:Sync(syncName.vine .. " " .. vineTarget)
		return
	end

	-- 腐化孢子（诅咒）
	if self.db.profile.spores and string.find(msg, L["trigger_sporesYou"]) then
		self:Sync(syncName.spores .. " " .. UnitName("player"))
		return
	end
	local _, _, sporeTarget = string.find(msg, L["trigger_sporesOther"])
	if sporeTarget then
		if sporeTarget == "你" then sporeTarget = UnitName("player") end
		self:Sync(syncName.spores .. " " .. sporeTarget)
		return
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.secretionHit and rest then
		self:InfectedSecretionHit(rest)
	elseif sync == syncName.vine and rest and self.db.profile.poisonvine then
		self:Sound("voiceDispel")
		if rest == UnitName("player") then
			self:Message(L["msg_vineYou"], "Personal", true)
		else
			self:Message(string.format(L["msg_vineOther"], rest), "Urgent")
		end
	elseif sync == syncName.spores and rest and self.db.profile.spores then
		if rest == UnitName("player") then
			self:Message(L["msg_sporesYou"], "Personal", true, "Alert")
		else
			self:Message(L["msg_sporesOther"], "Attention")
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
