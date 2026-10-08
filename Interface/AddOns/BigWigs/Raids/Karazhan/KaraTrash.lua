local module, L = BigWigs:ModuleDeclaration("Kara Trash", "Karazhan")

module.revision = 30000
module.trashMod = true -- how does this affect things
module.enabletrigger = { "Shadowclaw Darkbringer", "Manascale Drake", "Unstable Arcane Elemental", "Disrupted Arcane Elemental", "Arcane Anomaly", "Crumbling Protector", "Lingering Magus", "Lingering Astrologist", "Lingering Arcanist", "影爪暗行者", "魔鳞巨龙", "不稳定的奥术元素", "破碎的奥术元素", "异常的法力", "摇摇欲坠的保护者", "徘徊的魔术师", "徘徊的占星家", "徘徊的魔法师" }
module.toggleoptions = { "call_of_darkness", "frigid_mana_breath", "draconic_thrash", "mana_buildup", "unstable_mana", "overflowing_arcana", "astrologist_insight", "protector_self_destruct", "golem_reflection", "magus_polymorph", "magus_flames" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
	"The Rock of Desolation",
	"荒芜巨岩",
	"外域",
}

local guid_patterns = {
    ["魔鳞巨龙"] = "^0xF13000F1F427",
}

local _, playerClass = UnitClass("player")
local BC = AceLibrary("Babble-Class-2.2")
local has_superwow = SUPERWOW_VERSION or SetAutoloot
local tracked_guids = {}

module.defaultDB = {
	call_of_darkness = true,
	frigid_mana_breath = true,
	draconic_thrash = true,
	mana_buildup = true,
	unstable_mana = true,
	overflowing_arcana = true,
	astrologist_insight = true,
	magus_polymorph = playerClass == BC["PRIEST"] or playerClass == BC["PALADIN"],
	magus_flames = true,
	golem_reflection = true,
	protector_self_destruct = true,
}

L:RegisterTranslations("enUS", function()
	return {
		cmd = "UpperKaraTrash",

		call_of_darkness_cmd = "call_of_darkness",
		call_of_darkness_name = "Call of Darnkess Alert",
		call_of_darkness_desc = "Warns when a Shadowclaw Darkbringer begins to cast Call of Darkness",

		frigid_mana_breath_cmd = "frigid_mana_breath",
		frigid_mana_breath_name = "Manascale Drake Breath",
		frigid_mana_breath_desc = "Warn when Manascale Drake is able to cast Frigid Mana Breath",

		draconic_thrash_cmd = "draconic_thrash",
		draconic_thrash_name = "Manascale Threat Drop",
		draconic_thrash_desc = "Warn when Manascale Drake is about to wing buffet",

		mana_buildup_cmd = "mana_buildup",
		mana_buildup_name = "Mana Buildup Alert",
		mana_buildup_desc = "Warn to get out of raid if you have Mana Buildup bomb",

		unstable_mana_cmd = "unstable_mana",
		unstable_mana_name = "Unstable Mana Alert",
		unstable_mana_desc = "Warn to get out of raid if you have Unstable Mana bomb",

		overflowing_arcana_cmd = "overflowing_arcana",
		overflowing_arcana_name = "Overflowing Arcana Alert",
		overflowing_arcana_desc = "Warn when Overflowing Arcana stacks are near the limit",

		astrologist_insight_cmd = "astrologist_insight",
		astrologist_insight_name = "Astral Insight",
		astrologist_insight_desc = "Warn when you have to stop casting (Astral Insight from Lingering Astrologist)",

		magus_polymorph_cmd = "magus_polymorph",
		magus_polymorph_name = "Lingering Polymorph",
		magus_polymorph_desc = "Warn when someone has been polymorphed by Lingering Magus",

		magus_flames_cmd = "magus_flames",
		magus_flames_name = "Enveloped Flames",
		magus_flames_desc = "Warn when Lingering Magus forces someone to stop moving",

		golem_reflection_cmd = "golem_reflection",
		golem_reflection_name = "Reflection Protocol",
		golem_reflection_desc = "Warn when Karazhan Protector Golem gains spell reflect",

		protector_self_destruct_cmd = "protector_self_destruct",
		protector_self_destruct_name = "Self Destruction Protocol Alert",
		protector_self_destruct_desc = "Warn when Crumbling Protector is casting Self Destruction Protocol",

		trigger_call_of_darkness = "Shadowclaw Darkbringer begins to cast Call of Darkness",
		msg_call_of_darkness = "Call of Darkness - Interrupt Shadowclaw Darkbringer!",
		bar_call_of_darkness = "Call of Darkness",

		bar_frigid_mana_breath = "Drake Breath soon",
		bar_draconic_thrash = "Wing Buffet soon",

		trigger_mana_buildup = "(.+) ...? afflicted by Mana Buildup",
		trigger_remove_mana_buildup = "Your Mana Buildup is removed",
		msg_mana_buildup_you = "Mana Buildup - get dispelled or get out of the raid!",
		msg_mana_buildup = "Dispel %s - Mana Buildup!",
		bar_mana_buildup = "Mana Buildup blowing up",
		msg_mana_buildup_remove = "Mana Buildup dispelled",

		trigger_unstable_mana = "(.+) ...? afflicted by Unstable Mana",
		msg_unstable_mana_you = "Unstable Mana - wait for it to expire (no dispels!)",
		msg_unstable_mana = "DON'T dispel %s - Unstable Mana!",
		bar_unstable_mana = "Unstable Mana expires",

		trigger_overflowing_arcana = "(.+) ...? afflicted by Overflowing Arcana(.+)",
		trigger_overflowing_arcanaFade = "(.+) ...? afflicted by Overflowing Arcana(.+)",
		warn_overflowing_arcana = "Flee from Arcane Anomaly!",
		bar_overflowing_arcana = "Overflowing Arcana dot stacks",

		trigger_astrologist_insight = "You are afflicted by Astral Insight",
		msg_astrologist_insight = "Stop casting - Astral Insight!",
		warn_astrologist_insight = "NO CASTING",

		trigger_magus_polymorph = "(.+) ...? afflicted by Lingering Polymorph",
		msg_magus_polymorph = "Dispel %s - Lingering Polymorph",

		trigger_magus_flames = "(.+) ...? afflicted by Enveloped Flames",
		msg_magus_flames_self = "Stop moving until dispelled - Enveloped Flames!",
		warn_magus_flames = "FREEZE",
		msg_magus_flames_others = "%s has to stop moving - Enveloped Flames",
		msg_magus_flames_dispel = "Dispel %s - Enveloped Flames",

		trigger_golem_reflection = "Karazhan Protector Golem begins to perform Reflection Protocol.",
		msg_golem_reflection = "Spell Reflect on Karazhan Protector Golem",
		warn_golem_reflection = "GOLEM REFLECT",
		bar_golem_reflection = "Golem Spell Reflect",

		trigger_self_destruct = "Crumbling Protector begins to cast Self Destruction Protocol",
		warn_self_destruct = "BOOM!",
		bar_self_destruct = "Self Destruction Protocol",

		trigger_wumian = "影爪暗行者开始施放卡拉赞之幕",
		trigger_momian = "影爪暗行者开始施放沃根多尔之幕",

	    msg_wumian = "物理免疫-影爪暗行者！",
		bar_wumian = "物免-影爪暗行者",

	    msg_momian = "魔法免疫-影爪暗行者！",
		bar_momian = "魔免-影爪暗行者",

		bar_frigid_mana_breath = "即将冻结",
		bar_draconic_thrash = "即将击飞清仇恨",
	}
end)
L:RegisterTranslations("zhCN", function()
	return {
		cmd = "UpperKaraTrash",

		call_of_darkness_cmd = "call_of_darkness",
		call_of_darkness_name = "黑暗召唤警报",
		call_of_darkness_desc = "当影爪暗行者开始施放黑暗的召唤时发出警报",

		frigid_mana_breath_cmd = "frigid_mana_breath",
		frigid_mana_breath_name = "魔鳞巨龙吐息",
		frigid_mana_breath_desc = "当魔鳞巨龙即将施放寒霜气息时警告",

		draconic_thrash_cmd = "draconic_thrash",
		draconic_thrash_name = "魔鳞巨龙仇恨清除",
		draconic_thrash_desc = "当魔鳞巨龙即将施放龙之痛击时警告",

		mana_buildup_cmd = "mana_buildup",
		mana_buildup_name = "魔力积聚警报",
		mana_buildup_desc = "当你拥有魔力积聚炸弹时警告你离开团队",

		unstable_mana_cmd = "unstable_mana",
		unstable_mana_name = "不稳定法力警报",
		unstable_mana_desc = "当你拥有不稳定法力炸弹时警告你离开团队",

		overflowing_arcana_cmd = "overflowing_arcana",
		overflowing_arcana_name = "溢出的奥术能量警报",
		overflowing_arcana_desc = "当溢出的奥术能量层数接近上限时发出警告",

		astrologist_insight_cmd = "astrologist_insight",
		astrologist_insight_name = "星界洞察",
		astrologist_insight_desc = "警告你需要停止施法",

		magus_polymorph_cmd = "magus_polymorph",
		magus_polymorph_name = "挥之不去的变形术",
		magus_polymorph_desc = "当有人被徘徊的魔术师变形时发出警告",

		magus_flames_cmd = "magus_flames",
		magus_flames_name = "烈焰笼罩",
		magus_flames_desc = "当徘徊的魔术师使某人必须静止时发出警告",

		golem_reflection_cmd = "golem_reflection",
        golem_reflection_name = "反射协议",
        golem_reflection_desc = "当卡拉赞守护魔像获得法术反射时发出警告",

		protector_self_destruct_cmd = "protector_self_destruct",
		protector_self_destruct_name = "自毁协议警报",
		protector_self_destruct_desc = "当摇摇欲坠的保护者正在施放自毁协议时发出警报",

		trigger_call_of_darkness = "影爪暗行者开始施放黑暗的召唤",
		msg_call_of_darkness = "黑暗的召唤-打断影爪暗行者！",
		bar_call_of_darkness = "黑暗的召唤",

		trigger_wumian = "影爪暗行者获得了卡拉赞之幕的效果",
		trigger_momian = "影爪暗行者获得了沃根多尔之幕的效果",

	    msg_wumian = "物理免疫-影爪暗行者！",
		bar_wumian = "物免-影爪暗行者",

	    msg_momian = "魔法免疫-影爪暗行者！",
		bar_momian = "魔免-影爪暗行者",

		bar_frigid_mana_breath = "即将冻结",
		bar_draconic_thrash = "即将击飞清仇恨",

		trigger_mana_buildup = "(.+)受到了魔力积聚效果的影响",
		trigger_remove_mana_buildup = "魔力积聚效果从你身上消失",
		msg_mana_buildup_you = "魔力积聚-让队友驱散！",
		msg_mana_buildup = "驱散 %s - 魔力积聚！",
		bar_mana_buildup = "魔力积聚即将爆炸",
		msg_mana_buildup_remove = "魔力积聚已被驱散",

		trigger_unstable_mana = "(.+)受到了不稳定的法力效果的影响",
		msg_unstable_mana_you = "不稳定法力 - 等待其自然消失（切勿驱散）",
		msg_unstable_mana = "不要驱散%s - 不稳定法力！",
		bar_unstable_mana = "不稳定法力消失",
	
		trigger_overflowing_arcana = "你受到了溢出的奥术能量效果的影响（(%d+)）",
		trigger_overflowing_arcanaFade = "溢出的奥术能量效果从你身上消失了",
		warn_overflowing_arcana = "远离异常的法力！",
		bar_overflowing_arcana = "溢出的奥术能量(%d)层",

		trigger_astrologist_insight = "你受到了星界洞察效果的影响",
		msg_astrologist_insight = "停止施法-星界洞察！",
		warn_astrologist_insight = "停止施法！",

		trigger_magus_polymorph = "(.+)受到了挥之不去的变形术效果的影响",
		msg_magus_polymorph = "驱散%s-变形术",

		trigger_magus_flames = "(.+)受到了烈焰笼罩效果的影响",
		msg_magus_flames_self = "停止移动直到被驱散-烈焰笼罩！",
		warn_magus_flames = "静止！",
		msg_magus_flames_others = "%s停止移动-烈焰笼罩",
		msg_magus_flames_dispel = "驱散%s-烈焰笼罩",

        trigger_golem_reflection = "卡拉赞守护魔像开始施展反射法术协议",
        msg_golem_reflection = "卡拉赞守护魔像-法术反射",
        warn_golem_reflection = "法术反射",
        bar_golem_reflection = "法术反射",

		trigger_self_destruct = "摇摇欲坠的保护者开始施放自我毁灭协议",
		warn_self_destruct = "爆炸！",
		bar_self_destruct = "自毁协议",
	}
end)


local timer = {
	call_of_darkness = 5,
	wumian = 3,
	momian = 3,
	frigid_mana_breath = {14, 19},
	draconic_thrash = {12, 14},
	mana_buildup = 7,
	unstable_mana = 10,
	overflowingMin = 7, -- warning icon and application delay
	overflowingMax = 8, -- warning icon and application delay
	golem_reflection = 11, -- 1s cast time + 10s duration
	self_destruct = 4,
}

local icon = {
	call_of_darkness = "Spell_Shadow_ShadowBolt",
	wumian = "Spell_Shadow_Sealofkings",
	momian = "spell_shadow_antimagicshell",
	frigid_mana_breath = "Spell_Frost_FrostShock",
	draconic_thrash = "INV_Misc_MonsterScales_05",
	mana_buildup = "Spell_Nature_Lightning",
	unstable_mana = "Spell_Shadow_Teleport",
	overflowing_arcana = "INV_Enchant_EssenceEternalLarge",
	astrologist_insight = "Spell_Holy_Silence",
	magus_flames = "Ability_Rogue_Trip",
	golem_reflection = "Spell_Shadow_Teleport",
	self_destruct = "Spell_Fire_SelfDestruct",
}

local syncName = {
	call_of_darkness = "K40CallOfDarkness" .. module.revision,
	suppressor_crystal = "K40SuppressorCrystal" .. module.revision,
	drake_engage = "DrakeEngage" .. module.revision,
	mana_buildup = "K40ManaBuildup" .. module.revision,
	unstable_mana = "K40UnstableMana" .. module.revision,
	overflowing_arcana = "K40OverflowingArcana" .. module.revision,
	magus_polymorph = "K40MagusPolymorph" .. module.revision,
	magus_flames = "K40MagusFlames" .. module.revision,
	golem_reflection = "K40GolemReflection" .. module.revision,
	self_destruct = "K40SelfDestruct" .. module.revision,
	wumian = "K40WuMian" .. module.revision,
    momian = "K40MoMian" .. module.revision,
}

local overflowingCount = 0

function module:OnSetup()
	overflowingCount = 0
end

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")

	self:RegisterEvent("CHAT_MSG_SPELL_BREAK_AURA", "RemoveEvent")
	self:RegisterEvent("CHAT_MSG_COMBAT_CREATURE_DEATH", "OnEnemyDeath")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "BuffEvent")

	if has_superwow then
		self:RegisterEvent("UNIT_CASTEVENT")
		self:RegisterEvent("UNIT_FLAGS")
	else
		self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "EnemyCastEvent") -- not sure which of these it is
		self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "EnemyCastEvent")  -- not sure which of these it is
	end

	self:ThrottleSync(1, syncName.call_of_darkness)
	self:ThrottleSync(1, syncName.wumian)
	self:ThrottleSync(1, syncName.momian)
	self:ThrottleSync(10, syncName.drake_engage)
	self:ThrottleSync(1, syncName.mana_buildup)
	self:ThrottleSync(1, syncName.unstable_mana)
	self:ThrottleSync(1, syncName.overflowing_arcana)
	self:ThrottleSync(1, syncName.magus_polymorph)
	self:ThrottleSync(1, syncName.magus_flames)
	self:ThrottleSync(2, syncName.golem_reflection)
	self:ThrottleSync(1, syncName.self_destruct)
end

function module:OnEngage()
	if not has_superwow and self.db.profile.frigid_mana_breath then
		-- start checking for drake changing targets
		self:ScheduleRepeatingEvent("bwdraketargetcheck", self.CheckDrakeTarget, 0.2, self)
		-- don't run forever if this isn't a drake pack
		self:ScheduleEvent("disable_bwdraketargetcheck", "CancelScheduledEvent", 5, "bwdraketargetcheck")
	end
end

function module:OnDisengage()
	tracked_guids = {}
end

-- todo: replace this with a proper top level flags detection feature for pull detection
function module:UNIT_FLAGS(unit)
	if not UnitAffectingCombat(unit) then return end
	if not tracked_guids[unit] and string.find(unit, guid_patterns["魔鳞巨龙"]) then
		tracked_guids[unit] = true
		self:Sync(syncName.drake_engage)
	end
end

function module:CheckDrakeTarget()
	local drakeTarget = nil

	if UnitName("target") == "魔鳞巨龙" then
		drakeTarget = UnitName("targettarget")
	else
		-- loop through raid to find someone targeting the drake
		for i = 1, GetNumRaidMembers() do
			if UnitName("raid" .. i .. "target") == "魔鳞巨龙" then
				drakeTarget = UnitName("raid" .. i .. "targettarget")
				break
			end
		end
	end
	if drakeTarget then
		self:Sync(syncName.drake_engage)
		self:Message("集火目标：魔鳞巨龙", "Important", false, nil, false)
	end
end

function module:UNIT_CASTEVENT(caster, target, action, spell_id, cast_time)
	if caster and spell_id == 57645 and action == "START" then
		self:Sync(syncName.call_of_darkness)
	end
	if caster and spell_id == 57654 and action == "START" then
		self:Sync(syncName.golem_reflection)
	end
	if caster and spell_id == 57652 and action == "START" then
		self:Sync(syncName.self_destruct)
	end
end

function module:EnemyCastEvent(msg)
	if string.find(msg, L["trigger_call_of_darkness"]) then
		self:Sync(syncName.call_of_darkness)
		return
	end

	if string.find(msg, L["trigger_golem_reflection"]) then
		self:Sync(syncName.golem_reflection)
		return
	end
	if string.find(msg, L["trigger_self_destruct"]) then
		self:Sync(syncName.self_destruct)
		return
	end
end


function module:BuffEvent(msg)
	if string.find(msg, L["trigger_wumian"]) then
		self:Bar(L["bar_wumian"], timer.wumian, icon.momian)
		return
	end

	if string.find(msg, L["trigger_momian"]) then
		self:Bar(L["bar_momian"], timer.momian, icon.momian)
		return
	end
end


function module:OnEnemyDeath(msg)
    -- 检查中文或英文的死亡消息
    if string.find(msg, "异常的法力") or string.find(msg, "Arcane Anomaly") then
        self:TriggerEvent("BigWigs_StopCounterBar", self, L["bar_overflowing_arcana"])
    end
end

function module:AfflictionEvent(msg)
	local _, _, playerMB = string.find(msg, L["trigger_mana_buildup"])
	if playerMB then
		if playerMB == "你" then
			playerMB = UnitName("player")
		end
		self:Sync(syncName.mana_buildup .. " " .. playerMB)
		return
	end
	local _, _, playerUM = string.find(msg, L["trigger_unstable_mana"])
	if playerUM then
		if playerUM == "你" then
			playerUM = UnitName("player")
		end
		self:Sync(syncName.unstable_mana .. " " .. playerUM)
		return
	end
	local _, _, count = string.find(msg, L["trigger_overflowing_arcana"])
	if count then
		self:OverflowingOfArcana(tonumber(count))
	end
	local _, _, playerLP = string.find(msg, L["trigger_magus_polymorph"])
	if playerLP then
		if playerLP == "你" then
			playerLP = UnitName("player")
		end
		self:Sync(syncName.magus_polymorph .. " " .. playerLP)
		return
	end
	local _, _, playerEF = string.find(msg, L["trigger_magus_flames"])
	if playerEF then
		if playerEF == "你" then
			playerEF = UnitName("player")
			module:EnvelopedFlames(playerEF) -- let's not miss a sync
		end
		self:Sync(syncName.magus_flames .. " " .. playerEF)
		return
	end
	if string.find(msg, L["trigger_astrologist_insight"]) then
		self:Message(L["msg_astrologist_insight"], "Important", nil, "tizhishifa")
		self:WarningSign(icon.astrologist_insight, 7, true, L["warn_astrologist_insight"])
	end
end

function module:RemoveEvent(msg)
	-- Check for Mana Buildup removal
	if string.find(msg, L["trigger_remove_mana_buildup"]) then
		self:RemoveBar(L["bar_mana_buildup"])
		self:Message(L["msg_mana_buildup_remove"], "Positive", true, "Long")
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.call_of_darkness then
		if self.db.profile.call_of_darkness then
			self:Message(L["msg_call_of_darkness"], "Important", nil, "daduan")
			self:Bar(L["bar_call_of_darkness"], timer.call_of_darkness, icon.call_of_darkness)
		end
	elseif sync == syncName.drake_engage then
		if self.db.profile.frigid_mana_breath then
			self:IntervalBar(L["bar_frigid_mana_breath"], timer.frigid_mana_breath[1], timer.frigid_mana_breath[2], icon.frigid_mana_breath)
		end
		if self.db.profile.draconic_thrash then
			self:IntervalBar(L["bar_draconic_thrash"], timer.draconic_thrash[1], timer.draconic_thrash[2], icon.draconic_thrash)
		end
	elseif sync == syncName.mana_buildup then
		if self.db.profile.mana_buildup and rest == UnitName("player") then
			self:Bar(L["bar_mana_buildup"], timer.mana_buildup, icon.mana_buildup)
			self:Message(L["msg_mana_buildup_you"], "Urgent", true, "Info")
		elseif self.db.profile.mana_buildup then
			self:Message(string.format(L["msg_mana_buildup"], rest), "Attention", nil, "Info")
		end
	elseif sync == syncName.unstable_mana then
		if self.db.profile.unstable_mana and rest == UnitName("player") then
			self:Message(L["msg_unstable_mana_you"], "Urgent", true, "Info")
			self:Bar(L["bar_unstable_mana"], timer.unstable_mana, icon.unstable_mana)
		elseif self.db.profile.unstable_mana then
			self:Message(string.format(L["msg_unstable_mana"], rest), "Attention", nil, "Info")
		end
	elseif sync == syncName.magus_polymorph and rest then
		if self.db.profile.magus_polymorph then
			self:Message(string.format(L["msg_magus_polymorph"], rest), "Urgent", nil, "Info")
		end
	elseif sync == syncName.magus_flames and rest and rest ~= UnitName("player") then
		self:EnvelopedFlames(rest)
	elseif sync == syncName.golem_reflection then
		if self.db.profile.golem_reflection then
			self:Message(L["msg_golem_reflection"], "Attention", nil, "Info")
			self:Bar(L["bar_golem_reflection"], timer.golem_reflection, icon.golem_reflection)
			self:WarningSign(icon.golem_reflection, 3, false, L["warn_golem_reflection"])
		end
	elseif sync == syncName.self_destruct then
		if self.db.profile.protector_self_destruct then
			self:Sound("Beware")
			self:Bar(L["bar_self_destruct"], timer.self_destruct, icon.self_destruct)
		end
	end
end

function module:EnvelopedFlames(player)
	if self.db.profile.magus_flames then
		if player == UnitName("player") then
			self:Message(L["msg_magus_flames_self"], "Important", nil, "tingzhiyidong")
			self:RemoveWarningSign(icon.astrologist_insight, true) --cancel other forced sign since this is more important
			self:WarningSign(icon.magus_flames, 3, true, L["warn_magus_flames"])
		elseif playerClass == BC["PRIEST"] or playerClass == BC["PALADIN"] then
			self:Message(string.format(L["msg_magus_flames_dispel"], player), "Urgent", nil, "Alarm")
		else
			self:Message(string.format(L["msg_magus_flames_others"], player), "Attention", nil, "Info")
		end
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_SELF(msg)
	if string.find(msg, L["trigger_overflowing_arcanaFade"]) then
		self:RemoveBar(string.format(L["bar_overflowing_arcana"], overflowingCount))
		overflowingCount = 0
	end
end

function module:OverflowingOfArcana(count)
	if not self.db.profile.overflowing_arcana then
		return
	end

	overflowingCount = count

	-- Remove existing bar (注意这里要匹配之前创建的bar名称)
	self:RemoveBar(string.format(L["bar_overflowing_arcana"], count - 1))

	-- 创建新的进度条
	local barColor = "white" -- Default color
	if count >= 4 then
		barColor = "red"
		self:Sound("RunAway")
		self:WarningSign(icon.overflowing_arcana, 8, true, L["warn_overflowing_arcana"])
	elseif count >= 3 then
		barColor = "yellow"
		self:Sound("RunAway")
		self:WarningSign(icon.overflowing_arcana, 8, true, L["warn_overflowing_arcana"])
	end
	
	-- 关键修复：确保使用正确的API调用
	-- 根据EchoOfMedivh的doom实现，应该使用Bar而不是IntervalBar
	-- 因为层数是明确的，不需要随机间隔
	local barDuration = 8 -- 溢出的奥术能量持续时间通常是8秒
	self:Bar(string.format(L["bar_overflowing_arcana"], count), barDuration, icon.overflowing_arcana, true, barColor)
end