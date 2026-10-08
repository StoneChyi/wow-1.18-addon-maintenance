local module, L = BigWigs:ModuleDeclaration("Mephistroth", "Karazhan")

module.revision = 30003
module.enabletrigger = module.translatedName
module.toggleoptions = { "shacklescast", "shacklesdebuff", "shacklescd",  "shackleshatter", -1, "shardscd", "shardschannel", "shardscount", -1, "doomduration", "markdoom", -1, "nightmare", "marknightmare", -1, "vampaura", "vampcorruption", -1, "fearcast", "raincast", "bosskill" }
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
    AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
    "The Rock of Desolation",
    "荒芜巨岩",
    "外域",
    "孟菲斯托斯之手",
}

local _, playerClass = UnitClass("player")
local BC = AceLibrary("Babble-Class-2.2")
-- module defaults
module.defaultDB = {
	shacklescast = true,
	shacklesdebuff = true,
	shacklescd = false,
	shackleshatter = true,
	shardscd = true,
	shardschannel = true,
	shardscount = false,
	doomduration = playerClass == BC["Mage"] or playerClass == BC["DRUID"],
	markdoom = false,
	nightmare = false,
	marknightmare = false,
	vampaura = playerClass == BC["SHAMAN"] or playerClass == BC["PRIEST"],
	vampcorruption = false,
	fearcast = playerClass == BC["SHAMAN"],
	raincast = true,
	bosskill = true,
}

L:RegisterTranslations("enUS", function()
	return {
		-- options
		cmd = "Mephistroth",

		shacklescast_cmd = "shacklescast",
		shacklescast_name = "Shackles Cast Alert",
		shacklescast_desc = "Warn when Mephistroth begins casting Shackles of the Legion.",

		shacklesdebuff_cmd = "shacklesdebuff",
		shacklesdebuff_name = "Shackles Debuff Alert",
		shacklesdebuff_desc = "Warning and duration timer when Shackles of the Legion lands",

		shacklescd_cmd = "shacklescd",
		shacklescd_name = "Shackles CD Timer",
		shacklescd_desc = "Show timer for the minimum Shackles CD",

		shackleshatter_cmd = "shackleshatter",
		shackleshatter_name = "Shackle Shatter Tattle",
		shackleshatter_desc = "Tell who failed standing still.",

		shardscd_cmd = "shardscd",
		shardscd_name = "Shards of Hellfury CD Timer",
		shardscd_desc = "Shows timers for the 90s CD window followed by the 30s spawn window for the next Shards of Hellfury.",

		shardschannel_cmd = "shardschannel",
		shardschannel_name = "Shards of Hellfury Channel Time",
		shardschannel_desc = "Show time left before Channel enrage.",

		shardscount_cmd = "shardscount",
		shardscount_name = "Shards of Hellfury Count",
		shardscount_desc = "Count down defeated Shards (count is based on combat log range and may be off for you).",

		doomduration_cmd = "doomduration",
		doomduration_name = "Doom Duration Bar",
		doomduration_desc = "Show duration bar for current Doom victim to time their decurse.",

		markdoom_cmd = "markdoom",
		markdoom_name = "Mark Doom Target",
		markdoom_desc = "Mark a Doomed player with Triangle.",

		nightmare_cmd = "nightmare",
		nightmare_name = "Waking Nightmare Alert",
		nightmare_desc = "Show a warning message when a player falls asleep to Waking Nightmare (for OTs to pick up incoming Nightmare Crawlers).",

		marknightmare_cmd = "marknightmare",
		marknightmare_name = "Mark Waking Nightmare Target",
		marknightmare_desc = "Mark the player sleeping due to Waking Nightmare with Moon (so OTs see where the next Nightmare Crawler will spawn).",

		vampaura_cmd = "vampaura",
		vampaura_name = "Vampiric Aura alert",
		vampaura_desc = "Shows a purge alert whenever Vampiric Aura is up.",

		vampcorruption_cmd = "vampcorruption",
		vampcorruption_name = "Vampiric Corruption bar",
		vampcorruption_desc = "Shows a duration bar for Vampiric Corruption (50% melee haste after Vampiric Aura purge).",

		fearcast_cmd = "fearcast",
		fearcast_name = "Nathrezim Terror cast",
		fearcast_desc = "Shows an alert and a cast bar for incoming Nathrezim Terror (fear).",

		raincast_cmd = "raincast",
        raincast_name = "Rain of outland cast",
        raincast_desc = "Shows an alert and a cast bar for incoming Rain of outland.",

		-- triggers
		trigger_engage = "I foresaw your arrival", -- CHAT_MSG_MONSTER_YELL

		trigger_shacklesDebuffYou = "You are afflicted by Shackles of the Legion",
		trigger_shacklesDebuffOther = "(.+) is afflicted by Shackles of the Legion",
		trigger_shacklesFadeYou = "Shackles of the Legion fades from you",

		trigger_shackleShatterYou = "Your Shackle Shatter .-its",
		trigger_shackleShatterOther = "(.+)'s Shackle Shatter .-its",

		trigger_doomDebuff = "(.+) ...? afflicted by Doom of Outland",
		trigger_doomDebuffFade = "Doom of Outland fades from (.+)%.",

		trigger_nightmareDebuff = "(.+) ...? afflicted by Waking Nightmare",
		trigger_nightmareDebuffFade = "Waking Nightmare fades from (.+)%.",

		trigger_vampiricAuraGain = "Mephistroth gains Vampiric Aura",
		trigger_vampiricAuraFade = "Vampiric Aura fades from Mephistroth",
		trigger_vampiricCorruption = "Mephistroth gains Vampiric Corruption",

		trigger_shacklesCast = "Mephistroth begins to cast Shackles of the Legion",
		trigger_shardsCast = "Mephistroth begins to cast Shards of Hellfury",
		trigger_shardsSummon = "My plan has long been in the making",
		trigger_shardsDeath = "Hellfury Shard dies",
		trigger_shardsFail = "Mephistroth gains Unfathomed Hatred",
		trigger_fearCast = "Mephistroth begins to cast Nathrezim Terror",
		trigger_rainCast = "Mephistroth begins to cast Rain of outland",

		-- messages & bars
		msg_shacklesCast = "Shackles of the Legion incoming! >>DO NOT MOVE<<",
		bar_shacklesCast = "Casting Shackles",
		msg_shacklesCastAlert = "Shackles Casting >>STOP MOVING<<",

		bar_shacklesDebuff = "Shackles of the Legion",
		msg_shacklesDebuffYou = "You are shackled! >>DO NOT MOVE<<",
		msg_shacklesDebuffOther = "%s is shackled!",
		bar_shacklesCD = "Shackles on CD",

		msg_shackleShatter = " didn't keep still.",

		bar_shardsChannel = "Shard Enrage",
		bar_shardsCD = "Shards on CD",
		bar_shardsWindow = "Shards Spawn Window",
		bar_shardsCast = "Shards Incoming!",
		msg_shardsCast = "Hellfire Shards casting, spread out!",
		msg_shardsRemaining = " Shards remaining",
		msg_shardsOver = "Shards Phase Over",
		msg_shardsFail = "Shards Phase Failed - Unfathomed Hatred triggered",

		bar_doom = "Doom on %s >Decurse<",

		msg_nightmare = "Crawler spawning on %s",

		warning_vampiricAura = "Purge!",
		bar_vampiricCorruption = "boss hasted",

		msg_fearCast = "Fear incoming!",
		bar_fearCast = "Fear casting!",

		msg_rainCast = "Rain incoming!",
        bar_rainCast = "Rain casting!",
        warn_rainCast = "Phase2",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		-- options
		cmd = "Mephistroth",

		shacklescast_cmd = "shacklescast",
		shacklescast_name = "军团镣铐施法警报",
		shacklescast_desc = "当孟菲斯托斯开始施放军团镣铐时发出警告",

		shacklesdebuff_cmd = "shacklesdebuff",
		shacklesdebuff_name = "军团镣铐警报",
		shacklesdebuff_desc = "当军团镣铐效果生效时的警告与持续时间计时器",

		shacklescd_cmd = "shacklescd",
        shacklescd_name = "军团镣铐冷却计时器",
        shacklescd_desc = "显示军团镣铐最小冷却时间的计时器",

		shackleshatter_cmd = "shackleshatter",
		shackleshatter_name = "镣铐碎裂通报",
		shackleshatter_desc = "提示未能保持静止的玩家",

		shardscd_cmd = "shardscd",
		shardscd_name = "地狱火碎片冷却计时器",
		shardscd_desc = "显示90秒硬性冷却期间和随后30秒生成窗口的计时器，用于下一个地狱火碎片",

		shardschannel_cmd = "shardschannel",
		shardschannel_name = "地狱之怒碎片引导时间",
		shardschannel_desc = "显示引导暴怒前的剩余时间",

        shardscount_cmd = "shardscount",
        shardscount_name = "地狱之怒碎片计数",
        shardscount_desc = "倒数已被击败的碎片数量（计数基于战斗日志范围，可能不准）",

        doomduration_cmd = "doomduration",
        doomduration_name = "末日诅咒持续时间条",
        doomduration_desc = "显示当前末日诅咒受害者的持续时间条，以安排驱散时机",

		markdoom_cmd = "markdoom",
		markdoom_name = "末日印记标记",
		markdoom_desc = "用三角标记被末日印记的玩家",

		nightmare_cmd = "nightmare",
        nightmare_name = "梦魇乍醒警报",
        nightmare_desc = "当玩家因梦魇乍醒陷入沉睡时显示警报（副坦接应即将生成的梦魇爬行者）",

        marknightmare_cmd = "marknightmare",
        marknightmare_name = "标记梦魇乍醒目标",
        marknightmare_desc = "为受梦魇乍醒影响而沉睡的玩家添加月亮标记（副坦预判梦魇爬行者生成位置）",

        vampaura_cmd = "vampaura",
        vampaura_name = "吸血鬼光环警报",
        vampaura_desc = "当吸血鬼光环出现时显示净化警报",

        vampcorruption_cmd = "vampcorruption",
        vampcorruption_name = "吸血鬼堕落计时条",
        vampcorruption_desc = "显示吸血鬼堕落的持续时间条（驱散后BOSS获得50%近战急速效果）",

        fearcast_cmd = "fearcast",
        fearcast_name = "群体恐惧施法警报",
        fearcast_desc = "显示即将到来的群体恐惧的警报和施法条",

        raincast_cmd = "raincast",
        raincast_name = "外域之雨施法警报",
        raincast_desc = "显示即将到来的外域之雨的警报和施法条（转阶段）",

		-- 触发条件
		trigger_engage = "我预见到了你的到来", -- CHAT_MSG_MONSTER_YELL

		trigger_shacklesDebuffYou = "你受到了军团镣铐效果的影响",
		trigger_shacklesDebuffOther = "(.+)受到了军团镣铐效果的影响",
		trigger_shacklesFadeYou = "军团镣铐效果从你身上消失了",

		trigger_shackleShatterYou = "你的挣脱镣铐击中",
		trigger_shackleShatterOther = "(.+)的挣脱镣铐击中",

		trigger_doomDebuff = "(.+)受到了外域的末日效果的影响",
		trigger_doomDebuffFade = "外域的末日效果从(.+)身上消失",

		trigger_nightmareDebuff = "(.+)受到了梦魇乍醒效果的影响",
        trigger_nightmareDebuffFade = "梦魇乍醒效果从(.+)身上消失",

        trigger_vampiricAuraGain = "孟菲斯托斯获得了吸血鬼光环的效果",
        trigger_vampiricAuraFade = "吸血鬼光环效果从孟菲斯托斯身上消失",
        trigger_vampiricCorruption = "孟菲斯托斯获得了吸血鬼腐蚀的效果",

        trigger_shacklesCast = "孟菲斯托斯开始施放军团镣铐",
        trigger_shardsCast = "孟菲斯托斯开始施放地狱之怒碎片",
        trigger_shardsSummon = "我的计划早已在酝酿中",
        trigger_shardsDeath = "地狱之怒碎片死亡了",
        trigger_shardsFail = "孟菲斯托斯获得了深渊之恨的效果",
        trigger_fearCast = "孟菲斯托斯开始施放恐惧魔王的嚎叫",
        trigger_rainCast = "孟菲斯托斯开始施放外域之雨",

		-- 消息和计时条
		msg_shacklesCast = "军团镣铐即将来袭！>>保持静止<<",
		bar_shacklesCast = "正在施放镣铐",
		msg_shacklesCastAlert = "正在施放镣铐>>停止移动<<",

		bar_shacklesDebuff = "军团镣铐",
		msg_shacklesDebuffYou = "你被镣铐束缚！>>保持静止<<",
		msg_shacklesDebuffOther = "%s被镣铐束缚！",
		bar_shacklesCD = "军团镣铐冷却中",

		msg_shackleShatter = "未能保持静止",

		bar_shardsChannel = "碎片激怒",
		bar_shardsCD = "碎片-强制冷却中", 
		msg_shardsCast = "地狱之怒碎片正在施放，分散就位！",
        bar_shardsWindow = "碎片-生成窗口期",
        bar_shardsCast = "碎片即将到来！",
        msg_shardsRemaining = "剩余碎片",
        msg_shardsOver = "碎片阶段结束",
        msg_shardsFail = "碎片阶段失败-深渊之恨",

        bar_doom = "%s的末日诅咒>点击驱散<",

        msg_nightmare = "%s即将生成噩梦爬行者", 

        warning_vampiricAura = "驱散！",
        bar_vampiricCorruption = "BOSS急速效果",

        msg_fearCast = "恐惧即将来袭！",
        bar_fearCast = "正在施放恐惧！",

        msg_rainCast = "外域之雨即将来袭！",
        bar_rainCast = "外域之雨",
        warn_rainCast = "转阶段",
	}
end)


local timer = {
	shacklesInitialCD = { 68, 96 }, -- 60 to 120 ?
	shacklesCD = { 40, 60 },
	shacklesCast = 2.5,
	shacklesDebuff = 6,
	shardsCast = 6,
	shardsCD = 90, --lowest observed in logs: 92s cast-to-cast
	shardsWindow = 30, --highest observed in logs: 120s cast-to-cast
	shardsCD_bar_delay = 25,
	shardsChannel = 2.5 + 25, -- cast time + channel duration, logs: ~28s total
	doom = 8,
	vampiricAura = 15,
	vampiricCorruption = 15,
	fearCast = 2.5,
	rainCast = 1.0,
}

local icon = {
	shackles = "INV_Belt_18",
	shardsCD = "Spell_Fire_Fire",
	shardsChannel = "Spell_Fire_SoulBurn",
	doom = "Spell_Shadow_NightOfTheDead",
	vampiricAura = "Spell_Shadow_VampiricAura",
	vampiricCorruption = "Ability_Druid_ChallangingRoar",
	fear = "Spell_Shadow_DeathCoil",
	rain = "Spell_Shadow_RainOfFire",
}

local syncName = {
	shacklesCast = "MephistrothShacklesCast" .. module.revision,
	shacklesDebuff = "MephistrothShacklesDebuff" .. module.revision,
	shackleShatter = "MephistrothShackleShatter" .. module.revision,
	shardsCD = "MephistrothShardsOfHellfuryCD" .. module.revision,
	shardsChannel = "MephistrothShardsOfHellfuryChannel" .. module.revision,
	shardsChannelEnd = "MephistrothShardsOfHellfuryChannelEnd" .. module.revision,
	doomGain = "MephistrothDoomGain" .. module.revision,
	doomFade = "MephistrothDoomFade" .. module.revision,
	nightmareGain = "MephistrothNightmareGain" .. module.revision,
	nightmareFade = "MephistrothNightmareFade" .. module.revision,
	vampiricAuraGain = "MephistrothVAGain" .. module.revision,
	vampiricAuraFade = "MephistrothVAFade" .. module.revision,
	vampiricCorruptionGain = "MephistrothVCGain" .. module.revision,
	fearCast = "MephistrothFearCast" .. module.revision,
	rainCast = "MephistrothRainCast" .. module.revision,
}

local spellIds = {
	shacklesCast = 51916,
	shackleShatter = 51917,
	shardsCast = 51942,
	shardsChannel = 51947,
	shardsFinish = 51948,
	fear = 51907,
	rain = 52672,
}

local fail_shards = 6

module:RegisterYellEngage(L.trigger_engage)

--------------------------------------------------------------------------------
--  Module OnEnable
--------------------------------------------------------------------------------

function module:OnSetup()
	self.started = nil

end

-- should sync enables
function module:OnEnable()
	if SUPERWOW_STRING or SetAutoloot then
		self:RegisterEvent("UNIT_CASTEVENT", "MephistrothCastEvent")
	else
		self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "CastEvent") --Shackles
		self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "CastEvent") --Shards Phase
		self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent") --Nathrezim Terror cast
		self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "CastEvent") --Shards of Hellfury cast
		self:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE", "CastEvent") --Shackle Shatter hits
	end

	-- Debuff landing
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "DebuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "DebuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "DebuffEvent")
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "EnemyBuffEvent")

	-- Debuff fading
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "FadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "FadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "FadeEvent")

	self:ThrottleSync(2, syncName.shacklesCast)
	self:ThrottleSync(2, syncName.shacklesDebuff)
	self:ThrottleSync(0.1, syncName.shackleShatter)
	self:ThrottleSync(5, syncName.shardsCD)
	self:ThrottleSync(5, syncName.shardsChannel)
	self:ThrottleSync(5, syncName.shardsChannelEnd)
	self:ThrottleSync(5, syncName.doomGain)
	self:ThrottleSync(5, syncName.doomFade)
	self:ThrottleSync(5, syncName.nightmareGain)
	self:ThrottleSync(5, syncName.nightmareFade)
	self:ThrottleSync(5, syncName.vampiricAuraGain)
	self:ThrottleSync(5, syncName.vampiricAuraFade)
	self:ThrottleSync(5, syncName.vampiricCorruptionGain)
	self:ThrottleSync(5, syncName.fearCast)
	self:ThrottleSync(5, syncName.rainCast)
	self:Message("Boss血量55%停手", "Important", false, nil, false)
end

function module:OnEngage()
	fail_shards = 6
end

--------------------------------------------------------------------------------
--  Cast Event
--------------------------------------------------------------------------------
function module:MephistrothCastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
	-- if not self.db.profile.shacklescast then return end
	-- todo: I believe shackles is a channel but don't know for sure yet
	if spellId == spellIds.shacklesCast and (eventType == "START" or eventType == "CHANNEL") then
		self:Sync(syncName.shacklesCast .. " " .. (castTime / 1000))
	elseif spellId == spellIds.shackleShatter then
		self:Sync(syncName.shackleShatter .. " " .. UnitName(casterGuid))
	elseif spellId == spellIds.shardsCast and eventType == "START" then
		self:Sync(syncName.shardsCD)
	elseif spellId == spellIds.shardsChannel then
		if eventType == "CHANNEL" then
			self:Sync(syncName.shardsChannel .. " " .. (castTime / 1000))
		end
	elseif spellId == spellIds.shardsFinish and eventType == "CAST" then
		-- todo: shard completed, good spot for an enrage indication
	elseif spellId == spellIds.fear and eventType == "START" then
		self:Sync(syncName.fearCast)
	elseif spellId == spellIds.rain and eventType == "START" then
		self:Sync(syncName.rainCast)
	end
end

function module:CastEvent(msg)
	if string.find(msg, L.trigger_shacklesCast) then
		self:Sync(syncName.shacklesCast .. " " .. timer.shacklesCast)
		return
	end

	if string.find(msg, L.trigger_fearCast) then
		self:Sync(syncName.fearCast)
		return
	end

	if string.find(msg, L.trigger_rainCast) then
		self:Sync(syncName.rainCast)
		return
	end
	
	if string.find(msg, L.trigger_shardsSummon) then
		self:Sync(syncName.shardsChannel .. " " .. timer.shardsChannel)
		return
	end
end

function module:OnEnemyDeath(msg)
	if string.find(msg, L.trigger_shardsDeath) then
		fail_shards = fail_shards - 1
		if fail_shards == 0 then
			fail_shards = 6
			self:Sync(syncName.shardsChannelEnd)
		elseif self.db.profile.shardscount then
			self:Message(fail_shards..L.msg_shardsRemaining, "Positive", true, false)
		end
	end
end

--------------------------------------------------------------------------------
--  Debuff landing
--------------------------------------------------------------------------------
function module:DebuffEvent(msg)
	-- Shackle debuff
	if string.find(msg, L.trigger_shacklesDebuffYou) then
		local player = UnitName("player")
		self:ShacklesDebuff(player) -- let's not miss a sync
		self:Sync(syncName.shacklesDebuff .. " " .. player)
		return
	end
	local _, _, player = string.find(msg, L.trigger_shacklesDebuffOther)
	if player then
		self:Sync(syncName.shacklesDebuff .. " " .. player)
		return
	end

	-- Doom of Outland debuff
	local _, _, player = string.find(msg, L.trigger_doomDebuff)
	if player then
		player = player == "你" and UnitName("player") or player
		self:Sync(syncName.doomGain .. " " .. player)
		return
	end

	-- Waking Nightmare debuff
	local _, _, player = string.find(msg, L.trigger_nightmareDebuff)
	if player then
		player = player == "你" and UnitName("player") or player
		self:Sync(syncName.nightmareGain .. " " .. player)
		return
	end
end

function module:EnemyBuffEvent(msg)
	-- Vampiric Aura
	if string.find(msg, L.trigger_vampiricAuraGain) then
		self:Sync(syncName.vampiricAuraGain)
	end
	
	-- Vampiric Corruption
	if string.find(msg, L.trigger_vampiricCorruption) then
		self:Sync(syncName.vampiricCorruptionGain)
	end
	
	-- Unfathomed Hatred (shard fail)
	if string.find(msg, L.trigger_shardsFail) then
		if self.db.profile.shardschannel then
			self:Message(L.msg_shardsFail, "Important", true, "Run")
		end
	end
end

--------------------------------------------------------------------------------
--  Debuff fades
--------------------------------------------------------------------------------
function module:FadeEvent(msg)
	-- Shackles fade from You
	if string.find(msg, L.trigger_shacklesFadeYou) then
		-- fear will remove shackles, best to keep the bar for calls as some people will not get feared
		-- self:RemoveBar(L.bar_shacklesDebuff)
		---self:RemoveWarningSign(icon.shackles)
		if self.db.profile.shacklesdebuff then
			self:Sound("anquan")
		end
	end
	
	-- Doom fades from any player
	local _, _, player = string.find(msg, L.trigger_doomDebuffFade)
	if player then
		player = player == "你" and UnitName("player") or player
		self:Sync(syncName.doomFade .. " " .. player)
	end

	-- Waking Nightmare fades from any player
	local _, _, player = string.find(msg, L.trigger_nightmareDebuffFade)
	if player then
		player = player == "你" and UnitName("player") or player
		self:Sync(syncName.nightmareFade .. " " .. player)
	end
	
	-- Vampiric Aura fades from boss
	if string.find(msg, L.trigger_vampiricAuraFade) then
		self:Sync(syncName.vampiricAuraFade)
	end
end

--------------------------------------------------------------------------------
--  Sync handler
--------------------------------------------------------------------------------
function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.shacklesCast then
		local castTime = tonumber(rest)
		self:ShacklesCast(castTime)
	elseif sync == syncName.shacklesDebuff and rest and rest ~= UnitName("player") then
		self:ShacklesDebuff(rest)
	elseif sync == syncName.shackleShatter and rest then
		self:ShackleShatter(rest)

	elseif sync == syncName.shardsCD then
		self:ShardsCD()
	elseif sync == syncName.shardsChannel and rest then
		local castTime = tonumber(rest)
		self:ShardsChannel(castTime)
	elseif sync == syncName.shardsChannelEnd then
		self:RemoveBar(L.bar_shardsChannel)
		if self.db.profile.shardschannel then
			self:Message(L.msg_shardsOver, "Positive", nil, "Long")
		end
	elseif sync == syncName.doomGain and rest then
		self:DoomGain(rest)
	elseif sync == syncName.doomFade and rest then
		self:DoomFade(rest)

	elseif sync == syncName.nightmareGain and rest then
		self:NightmareGain(rest)
	elseif sync == syncName.nightmareFade and rest then
		self:NightmareFade(rest)


	elseif sync == syncName.vampiricAuraGain then
		if self.db.profile.vampaura then
			self:WarningSign(icon.vampiricAura, timer.vampiricAura, false, L.warning_vampiricAura)
		end
	elseif sync == syncName.vampiricAuraFade then
		self:RemoveWarningSign(icon.vampiricAura)
	elseif sync == syncName.vampiricCorruptionGain then
		if self.db.profile.vampcorruption then
			self:Bar(L.bar_vampiricCorruption, timer.vampiricCorruption, icon.vampiricCorruption, true, "Yellow")
		end

	elseif sync == syncName.fearCast then
		if self.db.profile.fearcast then
			self:Message(L.msg_fearCast, "Core", nil, false)
			self:Bar(L.bar_fearCast, timer.fearCast, icon.fear, true, "Cyan")
		end
    elseif sync == syncName.rainCast then
		if self.db.profile.raincast then
		    self:Sound("zjd")
	        self:WarningSign(icon.rain, 3, false, L["warn_rainCast"])
			self:Bar(L.bar_rainCast, timer.rainCast, icon.rain, true, "Cyan")
		end
	end
end

--------------------------------------------------------------------------------
--  Alerts & Bars
--------------------------------------------------------------------------------
function module:ShacklesCast(castTime)
	-- remove any current or future CD bars
	self:CancelDelayedBar(L.bar_shacklesCD)
	self:RemoveBar(L.bar_shacklesCD)
	
	if self.db.profile.shacklescast then
		self:Sound("AirHorn")
		self:WarningSign(icon.shackles, castTime, true, L.msg_shacklesCastAlert)
		self:Bar(L.bar_shacklesCast, castTime, icon.shackles, true, "Red")
	end
	if self.db.profile.shacklescd then
		local delay = timer.shacklesCast + timer.shacklesDebuff + 1
		self:DelayedIntervalBar(delay, L.bar_shacklesCD, timer.shacklesCD[1]-delay, timer.shacklesCD[2]-delay, icon.shackles, true, "Black")
	end
end

function module:ShacklesDebuff(player)
	if not self.db.profile.shacklesdebuff then
		return
	end
	-- 0.5 leeway added to encourage people not to move too early
	if player == UnitName("player") then
		self:WarningSign(icon.shackles, timer.shacklesDebuff + 0.5, true, L.msg_shacklesDebuffYou)
		self:Sound("buyaodong")
	end
	self:Bar(L.bar_shacklesDebuff, timer.shacklesDebuff + 0.5, icon.shackles)
end

function module:ShackleShatter(player)
    if not self.db.profile.shackleshatter then
        return
    end
    
    -- 使用时间窗口过滤：0.5秒内同一个玩家不重复提示
    local now = GetTime()
    
    -- 如果有上次记录且是同一个玩家，且在0.5秒内，则跳过
    if self.lastShatterPlayer == player and 
       self.lastShatterTime and 
       (now - self.lastShatterTime) < 1 then
        return
    end
    
    -- 更新记录
    self.lastShatterPlayer = player
    self.lastShatterTime = now
    
    player = player == UnitName("player") and "你" or player
    local message = player .. L.msg_shackleShatter
    self:Message(message, "Important", nil, "Alert")
    SendChatMessage(message, "RAID")
end

function module:ShardsCD()
	fail_shards = 6
	
	if not self.db.profile.shardscd then
		return
	end
	-- clean up any left-over bars relating to shard CD
	self:RemoveBar(L.bar_shardsCD)
	self:CancelDelayedBar(L.bar_shardsWindow)
	self:RemoveBar(L.bar_shardsWindow)
	-- warn and cast bar
	self:Message(L.msg_shardsCast, "Important", false, nil, false)
	self:Bar(L.bar_shardsCast, timer.shardsCast, icon.shardsCD)
	-- schedule new CD bars
	self:DelayedBar(timer.shardsCD_bar_delay, L.bar_shardsCD, timer.shardsCD-timer.shardsCD_bar_delay, icon.shardsCD, true, "ItemQuality0")
	self:DelayedBar(timer.shardsCD, L.bar_shardsWindow, timer.shardsWindow, icon.shardsCD, true, "Orange")
end

function module:ShardsChannel(castTime)
	if not self.db.profile.shardschannel then
		return
	end
	self:Sound("Alarm")
	self:Bar(L.bar_shardsChannel, castTime, icon.shardsChannel, true, "Red")
end

function module:DoomGain(player)
	if self.db.profile.markdoom then
		self:SetRaidTargetForPlayer(player, 4) -- green triangle
	end
	
	if self.db.profile.doomduration then
		local barText = string.format(L.bar_doom, player)
		self:Bar(barText, timer.doom, icon.doom, true, "Purple")
		
		-- Set the bar to target player and cast Remove Curse when clicked
		local raidIndex = nil
		for i = 1,40 do
			local unit = "raid"..i
			if UnitExists(unit) and UnitName(unit) == player then
				raidIndex = unit
				break
			end
		end
		
		self:SetCandyBarOnClick("BigWigsBar " .. barText, function(name, button, playerName, target)
			if SUPERWOW_VERSION or SetAutoloot then
				if playerClass == BC["MAGE"] then
					CastSpellByName("解除次级诅咒", target)
				elseif playerClass == BC["DRUID"] then
					CastSpellByName("解除诅咒", target)
				end
			else
				TargetByName(playerName, true)
				if playerClass == BC["MAGE"] then
					CastSpellByName("解除次级诅咒")
				elseif playerClass == BC["DRUID"] then
					CastSpellByName("解除诅咒")
				end
			end
		end, player, raidIndex)
	end
end

function module:DoomFade(player)
	if self.db.profile.markdoom then
		self:RestorePreviousRaidTargetForPlayer(player)
	end
	
	self:RemoveBar(string.format(L.bar_doom, player))
end

function module:NightmareGain(player)
	if self.db.profile.marknightmare then
		self:SetRaidTargetForPlayer(player, 5) -- white moon
	end
	
	if self.db.profile.nightmare then
		self:Message(string.format(L.msg_nightmare, player), "Magenta", true, "Murloc")
	end
end

function module:NightmareFade(player)
	if self.db.profile.marknightmare then
		self:RestorePreviousRaidTargetForPlayer(player)
	end
end