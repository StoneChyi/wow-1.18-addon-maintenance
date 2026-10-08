local module, L = BigWigs:ModuleDeclaration("Sanv Tas'dal", "Karazhan")

-- module variables
module.revision = 30002
module.enabletrigger = { module.translatedName, "桑夫·塔斯达尔", "Sanv Tas'dal" }
module.toggleoptions = { "phaseshifted", "overflowinghatred", "addphase", "curseoftherift", "keepcurse", "riftfeedback", "cleave", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
    "The Rock of Desolation",
    "荒芜巨岩",
    "外域",
    "阿卡莎神庙",
}
-- module defaults

local _, playerClass = UnitClass("player")
local BC = AceLibrary("Babble-Class-2.2")

-- module defaults
module.defaultDB = {
	phaseshifted = true,
	overflowinghatred = true,
	addphase = true,
	cleave = true,
	curseoftherift = false,
	keepcurse = true,
	riftfeedback = false,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "SanvTasdal",

		phaseshifted_cmd = "phaseshifted",
		phaseshifted_name = "Phase Shifted Alert",
		phaseshifted_desc = "Warns when players get affected by Phase Shifted",

		overflowinghatred_cmd = "overflowinghatred",
		overflowinghatred_name = "Overflowing Hatred Alert",
		overflowinghatred_desc = "Warns when Sanv Tas'dal begins casting Overflowing Hatred",

		addphase_cmd = "addphase",
		addphase_name = "Add-Phase Timer",
		addphase_desc = "Shows a timer bar for the add phase at 40%",
		
		curseoftherift_cmd = "curseoftherift",
		curseoftherift_name = "Curse Timer",
		curseoftherift_desc = "Shows a timer for repeated Curse of the Rift applications",

		keepcurse_cmd = "keepcurse",
		keepcurse_name = "Curse Alert",
		keepcurse_desc = "Shows a message to maintain Curse of the Rift on the last Curse application before the next Rift Feedback",

		riftfeedback_cmd = "riftfeedback",
		riftfeedback_name = "Rift Feedback CD",
		riftfeedback_desc = "Shows a timer for the minimum CD of Rift Feedback",

		cleave_cmd = "cleavealert",
        cleave_name = "Cleave Alert",
        cleave_desc = "Alerts when you are hit by Cleave from a Deceiver's Scourgestone",

        trigger_shunpi = "Deceiver's Scourgestone's Cleave hits you",
        warn_shunpi = "Cleave",

		trigger_phaseShiftedYou = "You are afflicted by Phase Shifted",
		trigger_phaseShiftedOther = "(.+) is afflicted by Phase Shifted",
		trigger_phaseShiftedFade = "Phase Shifted fades from you",
		trigger_phaseShiftedFadeOther = "Phase Shifted fades from (.+)",
		msg_phaseShiftedYou = "Phase Shifted - Kill Netherwalkers!",
		msg_phaseShiftedOther = "%s has Phase Shifted.",
		bar_phaseShiftedExpires = "Phase Shifted",
		warn_phaseShifted = "KILL WALKERS",

		trigger_overflowingHatredCast = "Sanv Tas'dal begins to cast Overflowing Hatred",
		bar_overflowingHatredCast = "Overflowing Hatred",
		msg_overflowingHatred = "Get away from boss! - Overflowing Hatred casting",
		warn_overflowingHatred = "HIDE",

		msg_portalsOpen = "80% HP - Portals Opening",
		msg_addPhase = "40% HP - Add Phase",
		bar_addPhase = "Add Phase",

		trigger_Enrage = "Sanv Tas'dal gains Enrage",
		msg_Enrage = "Enrage - Tranq now!",

		trigger_curseRift = "afflicted by Curse of the Rift",
		trigger_curseRiftImmune = "Curse of the Rift fails%.", -- triggers only on raid member immunity messages. Does not account for "Sanv Tas'dal's Curse of the Rift failed. You are immune." but it shouldn't be necessary
		bar_curseRift = "next Curse",
		
		trigger_riftFeedback = "Sanv Tas'dal's Rift Feedback",
		bar_riftFeedback = "Rift Feedback CD",
		msg_keepCurse = "Keep the Curse - Feedback soon!",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "SanvTasdal",

		phaseshifted_cmd = "phaseshifted",
		phaseshifted_name = "相位转换警报",
		phaseshifted_desc = "当玩家受到相位转换效果影响时发出警告",

		overflowinghatred_cmd = "overflowinghatred",
		overflowinghatred_name = "仇恨溢出警报",
		overflowinghatred_desc = "当桑夫·塔斯达尔开始施放仇恨溢出时发出警告",

		addphase_cmd = "addphase",
		addphase_name = "小怪阶段计时器",
		addphase_desc = "在40%血量时显示小怪阶段的计时条",

        curseoftherift_cmd = "curseoftherift",
        curseoftherift_name = "诅咒计时器",
        curseoftherift_desc = "显示反复施加裂隙诅咒的计时器",

        keepcurse_cmd = "keepcurse",
        keepcurse_name = "诅咒警报",
        keepcurse_desc = "在下一次裂隙反馈前的最后一次诅咒施加时显示维持裂隙诅咒的信息",

        riftfeedback_cmd = "riftfeedback",
        riftfeedback_name = "裂隙反馈冷却",
        riftfeedback_desc = "显示裂隙反馈的最小冷却计时器",

		cleave_cmd = "cleavealert",
		cleave_name = "顺劈斩警报",
		cleave_desc = "当玩家被德莱尼裂隙追踪者顺劈击中时发出警报",

		trigger_shunpi = "德莱尼裂隙追踪者的顺劈斩击中你", 
		warn_shunpi = "顺劈斩",

		trigger_phaseShiftedYou = "^你受到了相位转换效果的影响",
		trigger_phaseShiftedOther = "(.+)受到了相位转换效果的影响",
		trigger_phaseShiftedFade = "相位转换效果从你身上消失了",
		trigger_phaseShiftedFadeOther = "相位转换效果从(.+)身上消失",
		msg_phaseShiftedYou = "你身上有相位转换 - 击杀虚无行者！",
		msg_phaseShiftedOther = "%s身上有相位转换！",
		bar_phaseShiftedExpires = "相位转换",
		warn_phaseShifted = "击杀虚无行者",

		trigger_overflowingHatredCast = "塔斯达尔开始施放仇恨溢出",
		bar_overflowingHatredCast = "仇恨溢出",
		msg_overflowingHatred = "远离BOSS！ - 正在施放仇恨溢出",
		warn_overflowingHatred = "快躲避",

		msg_portalsOpen = "80%血量 - 传送门开启",
		msg_addPhase = "40%血量 - 小怪阶段",
		bar_addPhase = "小怪阶段",
		
		trigger_Enrage = "桑夫·塔斯达尔获得了激怒的效果",
		msg_Enrage = "激怒-宁神射击！",

        trigger_curseRift = "受到了裂隙诅咒效果的影响",
        trigger_curseRiftImmune = "裂隙诅咒施放失败", -- 仅在团队成员免疫信息时触发。不包括"桑夫·塔斯达尔的裂隙诅咒失败。你免疫。"但应该不需要
        bar_curseRift = "下次诅咒",

        trigger_riftFeedback = "获得了裂隙反馈的效果",
        bar_riftFeedback = "裂隙反馈冷却中",
        msg_keepCurse = "保持诅咒-裂隙反馈即将来临！",
	}
end)

-- timer and icon variables
local timer = {
	phaseShiftedDuration = 25,
	overflowingHatredCast = 6,
	addPhase = 50,
	curseRift = 15, -- very reliable 15-16s interval
	riftFeedback = 45, -- lots of 47s and 53s cast-to-cast observed in logs; going with minimum CD because the only relevant info is when to keep Curse
}

local icon = {
	phaseShifted = "Spell_Shadow_AbominationExplosion",
	overflowingHatred = "Spell_Fire_Incinerate",
	addPhase = "Spell_Arcane_TeleportOrgrimmar",
	curseRift = "Spell_Shadow_GrimWard",
	riftFeedback = "Spell_Nature_Wispsplode",
	cleave = "Ability_Warrior_Cleave",
}

local syncName = {
	phaseShifted = "SanvTasdalPhaseShifted" .. module.revision,
	phaseShiftedFade = "SanvTasdalPhaseShiftedFade" .. module.revision,
	overflowingHatred = "SanvTasdalOverflowingHatred" .. module.revision,
	curseRift = "SanvTasdalCurseRift" .. module.revision,
	riftFeedback = "SanvTasdalRiftFeedback" .. module.revision,
}

local guid = {
	sanv = "0xF13000EA4D05DA44",
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "CastEvent")
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")

	self:ThrottleSync(3, syncName.phaseShifted)
	self:ThrottleSync(3, syncName.phaseShiftedFade)
	self:ThrottleSync(3, syncName.overflowingHatred)
	self:ThrottleSync(3, syncName.curseRift)
	self:ThrottleSync(3, syncName.riftFeedback)
	self:Message("起手自由药剂/佩戴勇士印记/恶魔套装", "Important", false, nil, false)
end

function module:OnSetup()
	self.hitEighty = nil
	self.hitForty = nil
	self.nextFeedback = nil
end

function module:OnEngage()
	self.hitEighty = nil
	self.hitForty = nil
	self.nextFeedback = nil
	
	-- Start health monitoring
	self:ScheduleRepeatingEvent("CheckBossHealth", self.CheckBossHealth, 0.5, self)
end

function module:OnDisengage()
	if self:IsEventScheduled("CheckBossHealth") then
		self:CancelScheduledEvent("CheckBossHealth")
	end
end

function module:AfflictionEvent(msg)
	-- Phase Shifted
	if string.find(msg, L["trigger_phaseShiftedYou"]) then
		self:Sync(syncName.phaseShifted .. " " .. UnitName("player"))
	else
		local _, _, player = string.find(msg, L["trigger_phaseShiftedOther"])
		if player then
			self:Sync(syncName.phaseShifted .. " " .. player)
		end
	end
	
	-- Curse of the Rift
	if string.find(msg, L["trigger_curseRift"]) or string.find(msg, L["trigger_curseRiftImmune"])then
		self:Sync(syncName.curseRift)
	end
end

function module:CastEvent(msg)
	if string.find(msg, L["trigger_overflowingHatredCast"]) then
		self:Sync(syncName.overflowingHatred)
	elseif string.find(msg, L["trigger_riftFeedback"]) then
		self:Sync(syncName.riftFeedback)
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_SELF(msg)
	if string.find(msg, L["trigger_phaseShiftedFade"]) then
		self:Sync(syncName.phaseShiftedFade .. " " .. UnitName("player"))
		self:RemoveBar(L["bar_phaseShiftedExpires"])
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_OTHER(msg)
	local _, _, player = string.find(msg, L["trigger_phaseShiftedFadeOther"])
	if player then
		self:Sync(syncName.phaseShiftedFade .. " " .. player)
	end
end

function module:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
	if string.find(msg, L["trigger_Enrage"]) then
		self:Message(L["msg_Enrage"], "Important", nil, false)
		local _, playerClass = UnitClass("player")
		if playerClass == BC["HUNTER"] then
			self:Sound("Alert")
		end
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.phaseShifted and rest then
		self:PhaseShifted(rest)
	elseif sync == syncName.phaseShiftedFade and rest then
		self:PhaseShiftedFade(rest)
	elseif sync == syncName.overflowingHatred then
		self:OverflowingHatred()
	elseif sync == syncName.curseRift then
		self:CurseOfTheRift()
	elseif sync == syncName.riftFeedback then
		self:RiftFeedback()
	end
end

function module:Event(msg)
	if string.find(msg, L["trigger_shunpi"]) and self.db.profile.cleave then
		self:Cleave()
	end	
end

function module:PhaseShifted(player)
	if self.db.profile.phaseshifted and self.hitEighty then
		if player == UnitName("player") then
			self:Message(L["msg_phaseShiftedYou"], "Important", true, "Alarm")
			self:WarningSign(icon.phaseShifted, 5, false, L["warn_phaseShifted"])
			-- Add personal expiration bar with yellow color
			self:Bar(L["bar_phaseShiftedExpires"], timer.phaseShiftedDuration, icon.phaseShifted, true, "yellow")
		else
			self:Message(string.format(L["msg_phaseShiftedOther"], player), "Urgent", nil, false)
		end
	end
end

function module:PhaseShiftedFade(player)
	-- Removed raid mark functionality
end

function module:OverflowingHatred()
	if self.db.profile.overflowinghatred then
		self:Message(L["msg_overflowingHatred"], "Important", nil, "Alarm")
		self:WarningSign(icon.overflowingHatred, 3, true, L["warn_overflowingHatred"])
		self:Bar(L["bar_overflowingHatredCast"], timer.overflowingHatredCast, icon.overflowingHatred, true, "Red")
	end
end

function module:CheckBossHealth()
	if UnitExists(guid.sanv) then
		local percent = UnitHealth(guid.sanv)/UnitHealthMax(guid.sanv) * 100

		if percent <= 80 and not self.hitEighty then
			self:Message(L["msg_portalsOpen"], "Attention")
			self.hitEighty = true
		end
		if percent <= 40 and not self.hitForty then
			self:AddPhase()
			self.hitForty = true
			self:CancelScheduledEvent("CheckBossHealth")
		end
	end
end

function module:AddPhase()
	self:Message(L["msg_addPhase"], "Attention")
	self:RemoveBar(L["bar_curseRift"])
	self:RemoveBar(L["bar_overflowingHatredCast"])
	if self.db.profile.addphase then
		self:Bar(L["bar_addPhase"], timer.addPhase, icon.addPhase, true, "blue")
	end
	self.nextFeedback = GetTime() + timer.addPhase + 10
end

function module:CurseOfTheRift()
	if self.db.profile.curseoftherift then
		self:RemoveBar(L["bar_curseRift"])
		self:Bar(L["bar_curseRift"], timer.curseRift, icon.curseRift, true, "White")
	end

	if self.nextFeedback and self.db.profile.keepcurse and self.nextFeedback - GetTime() < timer.curseRift then
		self:Message(L["msg_keepCurse"], "Positive", nil, "Info")
	end
end

function module:RiftFeedback()
	self.nextFeedback = GetTime() + timer.riftFeedback
	
	if self.db.profile.riftfeedback then
		self:RemoveBar(L["bar_riftFeedback"])
		self:Bar(L["bar_riftFeedback"], timer.riftFeedback, icon.riftFeedback, true, "Blue")	
	end
end

function module:Cleave()
	self:WarningSign(icon.cleave, 2, true, L["warn_shunpi"])
	self:Sound("cleave")
end