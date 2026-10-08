local module, L = BigWigs:ModuleDeclaration("Ley-Watcher Incantagos", "Karazhan")

-- module variables
module.revision = 30006
module.enabletrigger = { module.translatedName, "魔网观察者因塔苟斯", "Ley-Watcher Incantagos" }
module.toggleoptions = { "leyline", "affinity", "targetBlack", "targetBlue", "targetCrystal", "targetGreen", "targetMana", "targetRed", -1, "surgewarning", "surgesay", "summonseeker", "summonwhelps", -1, "beam", "blizzard", "proximity", "cursewarning", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Tower of Karazhan"],
	AceLibrary("Babble-Zone-2.2")["Tower of Karazhan"],
}

local _, playerClass = UnitClass("player")
local BC = AceLibrary("Babble-Class-2.2")

-- module defaults
module.defaultDB = {
	leyline = true,
	affinity = true,
	targetBlack = false,
	targetBlue = false,
	targetCrystal = false,
	targetGreen = false,
	targetMana = false,
	targetRed = false,
	surgewarning = true,
	surgesay = true,
	summonseeker = true,
	summonwhelps = true,
	beam = true,
	blizzard = true,
	proximity = false,
	cursewarning = true,
}

-- localization
-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "Incantagos",

		leyline_cmd = "leyline",
		leyline_name = "Ley-Line Disturbance Alert",
		leyline_desc = "Warns when Ley-Watcher Incantagos casts Ley-Line Disturbance (Affinity summon)",

		affinity_cmd = "affinity",
		affinity_name = "Affinity Alert",
		affinity_desc = "Displays the type of the summoned Affinity",

		targetBlack_cmd = "targetBlack",
		targetBlack_name = "Auto-Target Shadow",
		targetBlack_desc = "Auto-target Black Affinity (Shadow)",

		targetBlue_cmd = "targetBlue",
		targetBlue_name = "Auto-Target Frost",
		targetBlue_desc = "Auto-target Blue Affinity (Frost)",

		targetCrystal_cmd = "targetCrystal",
		targetCrystal_name = "Auto-Target Physical",
		targetCrystal_desc = "Auto-target Crystal Affinity (Physical)",

		targetGreen_cmd = "targetGreen",
		targetGreen_name = "Auto-Target Nature",
		targetGreen_desc = "Auto-target Green Affinity (Nature)",

		targetMana_cmd = "targetMana",
		targetMana_name = "Auto-Target Arcane",
		targetMana_desc = "Auto-target Mana Affinity (Arcane)",

		targetRed_cmd = "targetRed",
		targetRed_name = "Auto-Target Fire",
		targetRed_desc = "Auto-target Red Affinity (Fire)",

		surgewarning_cmd = "surgewarning",
		surgewarning_name = "Surge of Mana Alert",
		surgewarning_desc = "Warns when you or another player gets Surge of Mana (beam attack from Ley-Seeker adds) with a message and a timer bar (click to target victim, if paladin also to cast Hand of Freedom)",

		surgesay_cmd = "surgesay",
		surgesay_name = "Surge of Mana Announce",
		surgesay_desc = "Call for help in /say when you get Surge of Mana",

		summonseeker_cmd = "summonseeker",
		summonseeker_name = "Ley-Seeker summon Alert and timer between summons",
		summonseeker_desc = "Warns when Ley-Watcher Incantagos summons a Manascale Ley-Seeker and displays the time until the next summon",

		summonwhelps_cmd = "summonwhelps",
		summonwhelps_name = "Whelps summon Alert and timer between summons",
		summonwhelps_desc = "Warns when Ley-Watcher Incantagos summons Manascale Whelps and displays the time until the next summon",

		beam_cmd = "beam",
		beam_name = "Guided Ley-Beam Alert",
		beam_desc = "Warns when players are affected by Guided Ley-Beam",

		blizzard_cmd = "blizzard",
		blizzard_name = "Blizzard Alert",
		blizzard_desc = "Warns when players are affected by Blizzard",

		proximity_cmd = "proximity",
		proximity_name = "Proximity Warning",
		proximity_desc = "Show Proximity Warning Frame",

		cursewarning_cmd = "cursewarning",
		cursewarning_name = "Curse of Manascale Warning",
		cursewarning_desc = "Warns when boss reaches 38%, as Curse of Manascale comes at 33%",



		trigger_leyLineCast = "Watcher Incantagos begins to cast (.+)Line Disturbance",
		bar_leyLineCast = "Next Affinity",
		bar_leyLineCD = "Next Possible Ley-Line Disturbance",
		msg_leyLine = "Affinity incoming!",
		warn_leyLine = "AFFINITY SOON",

		trigger_blackAffinity = "gains Black Affinity",
		trigger_blueAffinity = "gains Blue Affinity",
		trigger_crystalAffinity = "gains Crystal Affinity",
		trigger_greenAffinity = "gains Green Affinity",
		trigger_manaAffinity = "gains Mana Affinity",
		trigger_redAffinity = "gains Red Affinity",

		unit_blackAffinity = "Black Affinity",
		unit_blueAffinity = "Blue Affinity",
		unit_crystalAffinity = "Crystal Affinity",
		unit_greenAffinity = "Green Affinity",
		unit_manaAffinity = "Mana Affinity",
		unit_redAffinity = "Red Affinity",

		msg_blackAffinity = "BLACK AFFINITY - Priests and Warlocks handle this!",
		msg_blueAffinity = "BLUE AFFINITY - Mages handle this!",
		msg_crystalAffinity = "CRYSTAL AFFINITY - Warriors, Rogues, Paladins and Hunters handle this!",
		msg_greenAffinity = "GREEN AFFINITY - Shamans and Druids handle this!",
		msg_manaAffinity = "MANA AFFINITY - Mages and Druids handle this!",
		msg_redAffinity = "RED AFFINITY - Mages and Warlocks handle this!",

		bar_blackAffinity = "Shadow Affinity >target<",
		bar_blueAffinity = "Frost Affinity >target<",
		bar_crystalAffinity = "Physical Affinity >target<",
		bar_greenAffinity = "Nature Affinity >target<",
		bar_manaAffinity = "Arcane Affinity >target<",
		bar_redAffinity = "Fire Affinity >target<",

		warn_blackAffinity = "SHADOW",
		warn_blueAffinity = "FROST",
		warn_crystalAffinity = "PHYSICAL",
		warn_greenAffinity = "NATURE",
		warn_manaAffinity = "ARCANE",
		warn_redAffinity = "FIRE",

		trigger_surgeYou = "You are afflicted by Surge of Mana",
		trigger_surge = "(.+) is afflicted by Surge of Mana",
		trigger_surgeFade = "Surge of Mana fades from (.+)%.",
		trigger_surgeDeath = "(.+) die",
		msg_surgeYou = "Surge of Mana on YOU!",
		msg_surge = "Surge on %s",
		bar_surge = (playerClass=="PALADIN" and "Surge on %s >freedom<") or "Surge on %s >target<",
		spell_surge = (playerClass=="PALADIN" and "Hand of Freedom") or false,
		warn_surge = "SURGE OF MANA",
		yell_surge = "Help me! (Surge of Mana)",

		trigger_summonSeekerCast = "Watcher Incantagos begins to cast Summon Manascale Ley",
		bar_summonSeekerCast = "Ley-Seeker Summoning",
		bar_summonSeekerCD = "Next Ley-Seeker spawn",
		msg_summonSeeker = "Manascale Ley-Seeker spawning in 2 sec!",

		trigger_summonWhelpsCast = "Watcher Incantagos begins to cast Summon Manascale Whelps",
		bar_summonWhelpsCast = "Whelps Summoning",
		bar_summonWhelpsCD = "Next Whelps spawn",
		msg_summonWhelps = "Manascale Whelps spawning in 2 sec!",

		trigger_leyBeamGain = "(.+) gain.? Guided Ley",
		trigger_leyBeamAfflicted = "afflicted by Guided Ley",
		bar_leyBeam = "Guided Ley-Beam in",
		msg_leyBeam = "LEY-BEAM on %s - AVOID THEM!",
		msg_leyBeamYou = "LEY-BEAM on YOU - GET AWAY FROM OTHERS!",
		yell_leyBeam = "Guided Ley-Beam on me! STAY AWAY!",
		warn_leyBeam = "IN BEAM, MOVE",
		
		trigger_blizzard = "You are afflicted by Blizzard", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
		msg_blizzard = "Move out of Blizzard!",
		warn_blizzard = "MOVE",

		msg_curseWarning = "38% - CURSE OF MANASCALE coming at 33%!",
		
		trigger_berserk = "Watcher Incantagos gains Berserk",
		msg_berserk = "Ley-Watcher Incantagos goes Berserk!",
		warn_berserk = "BERSERK",
		
		trigger_seekerDeath = "Seeker dies",
		msg_seekerCount = "%d Ley-Seekers left.",
		msg_seekerDeath = "All Ley-Seekers dead.",
		msg_seekerWarn = "Kill all Ley-Seekers before 80% boss HP!",
	}
end)


L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Incantagos",

		leyline_cmd = "leyline",
		leyline_name = "魔线扰动警报",
		leyline_desc = "当魔网观察者因塔苟斯施放魔线扰动时发出警告",

		affinity_cmd = "affinity",
		affinity_name = "亲和警报",
		affinity_desc = "显示召唤的亲和类型",

		targetBlack_cmd = "targetBlack",
		targetBlack_name = "自动目标-暗影",
		targetBlack_desc = "自动目标黑色亲和（暗影）",

		targetBlue_cmd = "targetBlue",
		targetBlue_name = "自动目标-冰霜",
		targetBlue_desc = "自动目标蓝色亲和（冰霜）",

		targetCrystal_cmd = "targetCrystal",
		targetCrystal_name = "自动目标-物理",
		targetCrystal_desc = "自动目标水晶亲和（物理）",

		targetGreen_cmd = "targetGreen",
		targetGreen_name = "自动目标-自然",
		targetGreen_desc = "自动目标绿色亲和（自然）",

		targetMana_cmd = "targetMana",
		targetMana_name = "自动目标-奥术",
		targetMana_desc = "自动目标法力亲和（奥术）",

		targetRed_cmd = "targetRed",
		targetRed_name = "自动目标-火焰",
		targetRed_desc = "自动目标红色亲和（火焰）",

		surgewarning_cmd = "surgewarning",
        surgewarning_name = "法力涌动警报",
        surgewarning_desc = "当玩家获得发力涌动（来自魔鳞魔网搜寻者连线）时，通过消息和计时条发出警告（点击计时条可选中目标，如果是骑士还可施放自由祝福）",

        surgesay_cmd = "surgesay",
        surgesay_name = "法力涌动通报",
        surgesay_desc = "当你获得法力涌动时，在聊天频道中发信息求助",

		summonseeker_cmd = "summonseeker",
		summonseeker_name = "魔鳞观察者召唤警报和召唤间隔计时",
		summonseeker_desc = "召唤魔鳞观察者时发出警报并显示下次召唤的时间",

		summonwhelps_cmd = "summonwhelps",
		summonwhelps_name = "魔鳞幼龙召唤警报和召唤间隔计时",
		summonwhelps_desc = "召唤魔鳞幼龙时发出警报并显示下次召唤的时间",

		beam_cmd = "beam",
		beam_name = "魔能光束警报",
		beam_desc = "当魔能光束施放时进行警告",

		blizzard_cmd = "blizzard",
		blizzard_name = "暴风雪警报",
		blizzard_desc = "当玩家受到暴风雪影响时发出警报",

		proximity_cmd = "proximity",
		proximity_name = "距离警告",
		proximity_desc = "显示距离警告框架",

		cursewarning_cmd = "cursewarning",
		cursewarning_name = "魔鳞诅咒警告",
		cursewarning_desc = "当首领生命值达到38%时发出警告，因为魔鳞诅咒在33%时施放",

		trigger_leyLineCast = "魔网观察者因塔苟斯开始施放魔线扰动",
		bar_leyLineCast = "下次亲和",
		bar_leyLineCD = "下次可能的魔线扰动",
		msg_leyLine = "亲和即将到来！",
		warn_leyLine = "亲和即将到来",

		trigger_greenAffinity = "获得了绿色亲和的效果",
		trigger_blackAffinity = "获得了黑色亲和的效果",
		trigger_redAffinity = "获得了红色亲和的效果",
		trigger_blueAffinity = "获得了蓝色亲和的效果",
		trigger_manaAffinity = "获得了魔力亲和的效果",
		trigger_crystalAffinity = "获得了水晶亲和的效果",

		unit_blackAffinity = "黑色亲和",
		unit_blueAffinity = "蓝色亲和",
		unit_crystalAffinity = "水晶亲和",
		unit_greenAffinity = "绿色亲和",
		unit_manaAffinity = "法力亲和",
		unit_redAffinity = "红色亲和",

		msg_blackAffinity = "黑色亲和-牧师和术士处理！",
		msg_blueAffinity = "蓝色亲和-法师处理！",
		msg_crystalAffinity = "水晶亲和-战士、盗贼、圣骑士和猎人处理！",
		msg_greenAffinity = "绿色亲和-萨满和德鲁伊处理！",
		msg_manaAffinity = "法力亲和-法师和德鲁伊处理！",
		msg_redAffinity = "红色亲和-法师和术士处理！",

		bar_blackAffinity = "暗影亲和>点击选中<",
		bar_blueAffinity = "冰霜亲和>点击选中<",
		bar_crystalAffinity = "物理亲和>点击选中<",
		bar_greenAffinity = "自然亲和>点击选中<",
		bar_manaAffinity = "奥术亲和>点击选中<",
		bar_redAffinity = "火焰亲和>点击选中<",

		warn_blackAffinity = "暗影",
		warn_blueAffinity = "冰霜",
		warn_crystalAffinity = "物理",
		warn_greenAffinity = "自然",
		warn_manaAffinity = "奥术",
		warn_redAffinity = "火焰",

		trigger_surgeYou = "你受到了法力涌动效果的影响",
		trigger_surge = "(.+)受到了法力涌动效果的影响",
		trigger_surgeFade = "法力涌动效果从(.+)身上消失",
		trigger_surgeDeath = "(.+)死亡了",
		msg_surgeYou = "你身上有法力涌动！",
		msg_surge = "%s身上有法力涌动",
		bar_surge = "法力涌动在%s>点击选中<",
		warn_surge = "法力涌动",
		yell_surge = "救我！（法力涌动）",

		trigger_summonSeekerCast = "魔网观察者因塔苟斯开始施放召唤魔鳞观察者",
		bar_summonSeekerCast = "魔鳞观察者召唤中",
		bar_summonSeekerCD = "下次魔鳞观察者刷新",
		msg_summonSeeker = "魔鳞观察者将在2秒后刷新！",

		trigger_summonWhelpsCast = "魔网观察者因塔苟斯开始施放召唤魔鳞幼龙",
		bar_summonWhelpsCast = "魔鳞幼龙召唤中",
		bar_summonWhelpsCD = "下次魔鳞幼龙刷新",
		msg_summonWhelps = "魔鳞幼龙将在2秒后刷新！",

		trigger_leyBeamGain = "(.+)获得了引导魔能光束的效果",
		trigger_leyBeamAfflicted = "(.+)受到了引导魔能光束效果的影响",
		bar_leyBeam = "魔能光束计时条",
		msg_leyBeam = "%s中了魔能光束-远离他！",
		msg_leyBeamYou = "你中了魔能光束，远离人群！",
		yell_leyBeam = "我身上魔能光束！请远离！",
		warn_leyBeam = "光束中，快移动",
		
		trigger_blizzard = "你受到了暴风雪效果的影响",
		msg_blizzard = "离开暴风雪区域！",
		warn_blizzard = "快移动",

		msg_curseWarning = "38%-魔鳞诅咒将在33%时施放！",
		
		trigger_berserk = "魔网观察者因塔苟斯获得了狂暴",
		msg_berserk = "魔网观察者因塔苟斯狂暴了！",
		warn_berserk = "狂暴",
		
        trigger_seekerDeath = "魔鳞魔网搜寻者死亡了",
        msg_seekerCount = "剩余%d个魔鳞魔网搜寻者",
        msg_seekerDeath = "所有魔鳞魔网搜寻者已死亡。",
        msg_seekerWarn = "在首领血量降至80%前杀死所有魔鳞魔网搜寻者！",
	}
end)

-- timer and icon variables
local timer = {
	firstLeyLine = { 35, 45 }, -- from fourth add kill
	leyLineCD = { 45, 55 },
	leyLineCast = 3,
	summonSeekerCast = 2,
	summonSeekerCD = { 27, 37 },
	summonWhelpsCast = 2,
	summonWhelpsCD = { 30, 35 },
	affinity = 15,
	initalBeamCD = 28,
	beam = 13, -- 10 sec duration, starts 3 sec after initial targeting buff
	surge = 8,
}

local icon = {
	leyLine = "Spell_Arcane_PortalIronForge",
	greenAffinity = "Spell_Nature_AbolishMagic",
	blackAffinity = "Spell_Shadow_ShadowBolt",
	redAffinity = "Spell_Fire_FlameBolt",
	blueAffinity = "Spell_Frost_FrostBolt02",
	manaAffinity = "Spell_Nature_StarFall",
	crystalAffinity = "INV_Sword_04",
	surge = "Spell_Shadow_SiphonMana",
	beam = "Spell_Arcane_StarFire",
	blizzard = "Spell_Frost_IceStorm",
	summonSeekerCD = "Ability_Mount_WhiteDireWolf",
	summonWhelpsCD = "Ability_Mount_WhiteDireWolf",
	berserk = "Spell_Nature_Reincarnation"
}

local color = {
	leyLine = "Blue",
}

local syncName = {
	summonSeeker = "IncantagosSummonSeeker" .. module.revision,
	summonWhelps = "IncantagosSummonWhelps" .. module.revision,
	leyLine = "IncantagosLeyLine" .. module.revision,
	greenAffinity = "IncantagosGreenAffinity" .. module.revision,
	blackAffinity = "IncantagosBlackAffinity" .. module.revision,
	redAffinity = "IncantagosRedAffinity" .. module.revision,
	blueAffinity = "IncantagosBlueAffinity" .. module.revision,
	manaAffinity = "IncantagosManaAffinity" .. module.revision,
	crystalAffinity = "IncantagosCrystalAffinity" .. module.revision,
	beam = "IncantagosLeyBeam" .. module.revision,
	allSeekersDead = "IncantagosSeekersDead" .. module.revision,
}

local guid = {
	incantagos = "0xF13000F1FA276A32"
}

-- Proximity Plugin
module.proximityCheck = function(unit)
	return CheckInteractDistance(unit, 2)
end
module.proximitySilent = true

-- module functions
function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "BeginsCastEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "BeginsCastEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "BuffEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "DebuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "DebuffEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "FadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "FadeEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "FadeEvent")

	if SUPERWOW_VERSION then
		self:RegisterCastEventsForUnitName("Ley-Watcher Incantagos", "IncantagosCastEvent")
	end

	self:ThrottleSync(5, syncName.summonSeeker)
	self:ThrottleSync(5, syncName.summonWhelps)
	self:ThrottleSync(5, syncName.leyLine)
	self:ThrottleSync(20, syncName.greenAffinity)
	self:ThrottleSync(20, syncName.blackAffinity)
	self:ThrottleSync(20, syncName.redAffinity)
	self:ThrottleSync(20, syncName.blueAffinity)
	self:ThrottleSync(20, syncName.manaAffinity)
	self:ThrottleSync(20, syncName.crystalAffinity)
	self:ThrottleSync(2, syncName.beam)
	self:ThrottleSync(5, syncName.allSeekersDead)
end

function module:OnSetup()
	self.started = nil
	self.curseWarned = nil
	self.hitEightyFive = nil
	self.seekersLeft = 4
end

function module:OnEngage()
	if self.db.profile.beam then
		self:Bar(L["bar_leyBeam"], timer.initalBeamCD, icon.beam, true, color.leyLine)
	end

	if self.db.profile.proximity then
		self:Proximity()
	end

	self.curseWarned = nil
	self.hitEightyFive = nil
	self.seekersLeft = 4

	-- Start health monitoring
	self:ScheduleRepeatingEvent("CheckBossHealth", self.CheckBossHealth, 0.5, self)
end

function module:OnDisengage()
	self:RemoveProximity()

	if self:IsEventScheduled("CheckBossHealth") then
		self:CancelScheduledEvent("CheckBossHealth")
	end
	self:CancelDelayedBar(L["bar_summonSeekerCD"])
	self:CancelDelayedBar(L["bar_summonWhelpsCD"])
end

function module:IncantagosCastEvent(casterGuid, targetGuid, eventType, spellId, castTime)
	if eventType == "CHANNEL" and spellId == 51187 then
		if IsRaidLeader() or IsRaidOfficer() then
			SetRaidTarget(targetGuid, 8)
		end
	end
end

function module:CheckBossHealth()
	if UnitExists(guid.incantagos) then
		local percent = UnitHealth(guid.incantagos)/UnitHealthMax(guid.incantagos) * 100

		if percent <= 85 and not self.hitEightyFive then
			if self.seekersLeft > 0 then
				self:Message(L["msg_seekerWarn"], "Important", nil, "Beware")
			end
			self.hitEightyFive = true
		end
		if percent <= 38 and not self.curseWarned then
			if self.db.profile.cursewarning then
				self:Message(L["msg_curseWarning"], "Important", nil, "Alarm")
			end
			self.curseWarned = true
			self:CancelScheduledEvent("CheckBossHealth")
		end
	end
end

function module:BeginsCastEvent(msg)
	if string.find(msg, L["trigger_summonSeekerCast"]) then
		self:Sync(syncName.summonSeeker)
	elseif string.find(msg, L["trigger_summonWhelpsCast"]) then
		self:Sync(syncName.summonWhelps)
	elseif string.find(msg, L["trigger_leyLineCast"]) then
		self:Sync(syncName.leyLine)
	end
end

function module:BuffEvent(msg)
	if string.find(msg, L["trigger_greenAffinity"]) then
		self:Sync(syncName.greenAffinity)
	elseif string.find(msg, L["trigger_blackAffinity"]) then
		self:Sync(syncName.blackAffinity)
	elseif string.find(msg, L["trigger_redAffinity"]) then
		self:Sync(syncName.redAffinity)
	elseif string.find(msg, L["trigger_blueAffinity"]) then
		self:Sync(syncName.blueAffinity)
	elseif string.find(msg, L["trigger_manaAffinity"]) then
		self:Sync(syncName.manaAffinity)
	elseif string.find(msg, L["trigger_crystalAffinity"]) then
		self:Sync(syncName.crystalAffinity)
	elseif string.find(msg, L["trigger_berserk"]) then
		self:WarningSign(icon.berserk, 2, true, L["warn_berserk"])
		self:Message(L["msg_berserk"], "Urgent", nil, "Murloc")
	end
end

function module:CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS(msg)
	local _, _, player = string.find(msg, L["trigger_leyBeamGain"])
	if player then
		if player == "你" then
			player = UnitName("player")
			self:LeyBeamStarted(player) -- let's not miss a sync
		end
		self:Sync(syncName.beam .. " " .. player)
	end
end

function module:CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE(msg)
	if string.find(msg, L["trigger_leyBeamAfflicted"]) then
		self:WarningSign(icon.beam, 5, true, L["warn_leyBeam"])
	elseif self.db.profile.blizzard and string.find(msg, L["trigger_blizzard"]) then
		self:WarningSign(icon.blizzard, 2, true, L["warn_blizzard"])
		self:Message(L["msg_blizzard"], "Important", true, "Info")
	elseif string.find(msg, L["trigger_surgeYou"]) then
		self:SurgeBar(UnitName("player"))
		if self.db.profile.surgewarning then
			self:WarningSign(icon.surge, 2, false, L["warn_surge"])
			self:Message(L["msg_surgeYou"], "Attention", true, "Info")
		end
		if self.db.profile.surgesay then
			SendChatMessage(L["yell_surge"], "SAY")
		end
	end
end

function module:DebuffEvent(msg)
	local _, _, player = string.find(msg, L["trigger_surge"])
	if player then
		self:SurgeBar(player)
		if self.db.profile.surgewarning then
			self:Message(string.format(L["msg_surge"], player), "Attention", nil, "Info")			
		end
	end
end

function module:OnEnemyDeath(msg)
	if string.find(msg, L["trigger_seekerDeath"]) then
		self.seekersLeft = self.seekersLeft -1
		if self.seekersLeft == 0 then
			self:Sync(syncName.allSeekersDead)
		elseif self.seekersLeft > 0 then
			self:Message(string.format(L["msg_seekerCount"], self.seekersLeft), "Positive")	
		end
	end
end

function module:FadeEvent(msg)
	local _, _, player = string.find(msg, L["trigger_surgeFade"])
	if player then
		player = player == "你" and UnitName("player") or player
		self:RemoveBar(string.format(L["bar_surge"], player))
	end
end

function module:OnFriendlyDeath(msg)
	local _, _, player = string.find(msg, L["trigger_surgeDeath"])
	if player then
		player = player == "你" and UnitName("player") or player
		self:RemoveBar(string.format(L["bar_surge"], player))
	end
end


function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.summonSeeker then
		self:SummonSeeker()
	elseif sync == syncName.summonWhelps then
		self:SummonWhelps()
	elseif sync == syncName.leyLine then
		self:LeyLine()
	elseif sync == syncName.greenAffinity then
		self:GreenAffinity()
	elseif sync == syncName.blackAffinity then
		self:BlackAffinity()
	elseif sync == syncName.redAffinity then
		self:RedAffinity()
	elseif sync == syncName.blueAffinity then
		self:BlueAffinity()
	elseif sync == syncName.manaAffinity then
		self:ManaAffinity()
	elseif sync == syncName.crystalAffinity then
		self:CrystalAffinity()
	elseif sync == syncName.beam and rest and rest ~= UnitName("player") then
		self:LeyBeamStarted(rest)
	elseif sync == syncName.allSeekersDead then
		self:AllSeekersDead()
	end
end

function module:SummonSeeker()
	self:CancelDelayedBar(L["bar_summonSeekerCD"])
	self:RemoveBar(L["bar_summonSeekerCD"])
	if self.db.profile.summonseeker then
		self:Message(L["msg_summonSeeker"], "Attention")
		local delay = timer.summonSeekerCast
		local nextMin = timer.summonSeekerCD[1] - delay
		local nextMax = timer.summonSeekerCD[2] - delay
		self:DelayedIntervalBar(delay, L["bar_summonSeekerCD"], nextMin, nextMax, icon.summonSeekerCD, true, "White")
	end
end

function module:SummonWhelps()
	self:CancelDelayedBar(L["bar_summonWhelpsCD"])
	self:RemoveBar(L["bar_summonWhelpsCD"])
	if self.db.profile.summonwhelps then
		self:Message(L["msg_summonWhelps"], "Attention")
		local delay = timer.summonWhelpsCast
		local nextMin = timer.summonWhelpsCD[1] - delay
		local nextMax = timer.summonWhelpsCD[2] - delay
		self:DelayedIntervalBar(delay, L["bar_summonWhelpsCD"], nextMin, nextMax, icon.summonWhelpsCD, true, "White")
	end
end

function module:LeyLine()
	if self.db.profile.leyline then
		self:Message(L["msg_leyLine"], "Important", nil, "Beware")
		self:WarningSign(icon.leyLine, 3, false, L["warn_leyLine"])
		self:RemoveBar(L["bar_leyLineCD"])
		self:Bar(L["bar_leyLineCast"], timer.leyLineCast, icon.leyLine, true, color.leyLine)
		self:IntervalBar(L["bar_leyLineCD"], timer.leyLineCD[1], timer.leyLineCD[2], icon.leyLine, true, color.leyLine)
	end
end

function module:BlackAffinity()
	if self.db.profile.affinity then
		self:Message(L["msg_blackAffinity"], "Important", nil, "Alarm")
		self:WarningSign(icon.blackAffinity, 5, true, L["warn_blackAffinity"])
		self:ClickBar(L["bar_blackAffinity"], timer.affinity, icon.blackAffinity, L["unit_blackAffinity"])
	end
	if self.db.profile.targetBlack then
		TargetByName(L["unit_blackAffinity"],true)
	end
end

function module:BlueAffinity()
	if self.db.profile.affinity then
		self:Message(L["msg_blueAffinity"], "Important", nil, "Alarm")
		self:WarningSign(icon.blueAffinity, 5, true, L["warn_blueAffinity"])
		self:ClickBar(L["bar_blueAffinity"], timer.affinity, icon.blueAffinity, L["unit_blueAffinity"])
	end
	if self.db.profile.targetBlue then
		TargetByName(L["unit_blueAffinity"],true)
	end
end

function module:CrystalAffinity()
	if self.db.profile.affinity then
		self:Message(L["msg_crystalAffinity"], "Important", nil, "Alarm")
		self:WarningSign(icon.crystalAffinity, 5, true, L["warn_crystalAffinity"])
		self:ClickBar(L["bar_crystalAffinity"], timer.affinity, icon.crystalAffinity, L["unit_crystalAffinity"])
	end
	if self.db.profile.targetCrystal then
		TargetByName(L["unit_crystalAffinity"],true)
	end
end

function module:GreenAffinity()
	if self.db.profile.affinity then
		self:Message(L["msg_greenAffinity"], "Important", nil, "Alarm")
		self:WarningSign(icon.greenAffinity, 5, true, L["warn_greenAffinity"])
		self:ClickBar(L["bar_greenAffinity"], timer.affinity, icon.greenAffinity, L["unit_greenAffinity"])
	end
	if self.db.profile.targetGreen then
		TargetByName(L["unit_greenAffinity"],true)
	end
end

function module:ManaAffinity()
	if self.db.profile.affinity then
		self:Message(L["msg_manaAffinity"], "Important", nil, "Alarm")
		self:WarningSign(icon.manaAffinity, 5, true, L["warn_manaAffinity"])
		self:ClickBar(L["bar_manaAffinity"], timer.affinity, icon.manaAffinity, L["unit_manaAffinity"])
	end
	if self.db.profile.targetMana then
		TargetByName(L["unit_manaAffinity"],true)
	end
end

function module:RedAffinity()
	if self.db.profile.affinity then
		self:Message(L["msg_redAffinity"], "Important", nil, "Alarm")
		self:WarningSign(icon.redAffinity, 5, true, L["warn_redAffinity"])
		self:ClickBar(L["bar_redAffinity"], timer.affinity, icon.redAffinity, L["unit_redAffinity"])
	end
	if self.db.profile.targetRed then
		TargetByName(L["unit_redAffinity"],true)
	end
end

function module:LeyBeamStarted(player)
	if not self.db.profile.beam then return end
	-- Combined self and other beam handling into one function
	if player == UnitName("player") then
		self:Message(L["msg_leyBeamYou"], "Important", true, "yuanlidatuan")
		self:WarningSign(icon.beam, 5, true, L["msg_leyBeamYou"])
		SendChatMessage(L["yell_leyBeam"], "SAY")
	else
		self:Message(string.format(L["msg_leyBeam"], player), "Important", nil, "AirHorn")
	end

	-- Add a timer bar for the beam duration
	self:Bar(player .. ": " .. L["beam_name"], timer.beam, icon.beam)
end

function module:AllSeekersDead()
	self.seekersLeft = 0
	self:Message(L["msg_seekerDeath"], "Positive", nil, "Long")
	
	if self.db.profile.leyline then
		self:IntervalBar(L["bar_leyLineCD"], timer.firstLeyLine[1], timer.firstLeyLine[2], icon.leyLine, true, color.leyLine)
	end
end

function module:SurgeBar(player)
	if self.db.profile.surgewarning then
		self:ClickBar(string.format(L["bar_surge"], player), timer.surge, icon.surge, player, L["spell_surge"], true, "Cyan")
		
		local barText = string.format(L["bar_surge"], player)
		self:Bar(barText, timer.surge, icon.surge, true, "Cyan")
		
		-- Set the bar to target player and cast Hand of Freedom
		local raidIndex = nil
		for i = 1,40 do
			local unit = "raid"..i
			if UnitExists(unit) and UnitName(unit) == player then
				raidIndex = unit
				break
			end
		end
		
		self:SetCandyBarOnClick("BigWigsBar " .. barText, function(name, button, playerName, target)
			TargetByName(playerName, true)
			if playerClass == BC["PALADIN"] then
				if SUPERWOW_VERSION or SetAutoloot then
					CastSpellByName("自由祝福", target)
				else
					CastSpellByName("自由祝福")
				end
			end
		end, player, raidIndex)
	end
end

