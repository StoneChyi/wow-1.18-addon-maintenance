
local module, L = BigWigs:ModuleDeclaration("Karrsh the Sentinel", "Timbermaw Hold")

module.revision = 30000
module.enabletrigger = module.translatedName
module.toggleoptions = {"roar", "seed", -1, "crush", "felstomp", "defenders", "phase", "bosskill"}
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Karrsh",

	roar_cmd = "roar",
	roar_name = "Furious Roar Alert",
	roar_desc = "Timer for Karrsh's Furious Roar while Spear of Timbermaw is active",

	seed_cmd = "seed",
	seed_name = "Seed of Corruption Alert",
	seed_desc = "Warn when someone is afflicted by Seed of Corruption and mark them",

	crush_cmd = "crush",
	crush_name = "Crushing Hammer alert",
	crush_desc = "Warn when Karrsh begins to cast Crushing Hammer (threat drop, priest shield)",

	felstomp_cmd = "felstomp",
	felstomp_name = "Fel Stomp alert",
	felstomp_desc = "Warn melee to move out when Karrsh casts Fel Stomp",

	defenders_cmd = "defenders",
	defenders_name = "Defenders spawn alert",
	defenders_desc = "Warn raid to switch to Timbermaw Defenders",

	phase_cmd = "phase",
	phase_name = "Phase yell alerts",
	phase_desc = "Announce phases from Karrsh's yells",

	trigger_crushCast = "Karrsh the Sentinel begins to cast Crushing Hammer",
	trigger_felStomp = "begins to cast Fel Stomp",
	trigger_defenders = "防御者",
	trigger_phase1 = "禁止前进",
	trigger_phase2 = "趁我还没彻底失去理智",
	trigger_phase3 = "我会亲手碾碎他们",

	msg_crush = "Crushing Hammer - priests shield the tank! Threat drops!",
	msg_felstomp = "Fel Stomp - melee move out!",
	msg_defenders = "Switch to Timbermaw Defenders! Prevent stacking damage reduction!",
	msg_phase1 = "P1: Crushing Hammer clears threat soon - switch to Defenders!",
	msg_phase2 = "P2: Boss +20% damage - grab threat, switch to Sentinels!",
	msg_phase3 = "P3 Rush: Boss attack speed rising - spread from seeds, burn him!",

	trigger_spearGain = "Karrsh the Sentinel gains Spear of Timbermaw",
	trigger_spearFade = "Spear of Timbermaw fades from Karrsh the Sentinel",
	trigger_roarCast = "Karrsh the Sentinel casts Furious Roar",

	trigger_seedYou = "^You are afflicted by Seed of Corruption",
	trigger_seedOther = "(.+) is afflicted by Seed of Corruption",
	trigger_seedFadeYou = "Seed of Corruption fades from you",
	trigger_seedFadeOther = "Seed of Corruption fades from (.+)%.",

	bar_roar = "Furious Roar",
	msg_roarSoon = "Threat drop incoming!",

	msg_seedYou = "SEED ON YOU - GET AWAY FROM OTHERS!",
	msg_seedBack = "Your Seed of Corruption is gone - you may return to the raid!",
} end )

L:RegisterTranslations("zhCN", function() return {
    cmd = "Karrsh",

    roar_cmd = "roar",
    roar_name = "狂怒咆哮警报",
    roar_desc = "当卡什手持木喉之矛时，为狂怒咆哮技能提供计时器",

    seed_cmd = "seed",
    seed_name = "腐蚀之种警报",
    seed_desc = "当有人被施加腐蚀之种时发出警告并标记该玩家",

    crush_cmd = "crush",
    crush_name = "粉碎重锤警报",
    crush_desc = "卡什开始施放粉碎重锤时发出警报（仇恨清空，MS给T上盾）——待实测校准",

    felstomp_cmd = "felstomp",
    felstomp_name = "邪能践踏警报",
    felstomp_desc = "卡什施放邪能践踏时提醒近战离开——待实测校准",

    defenders_cmd = "defenders",
    defenders_name = "木喉防御者转火警报",
    defenders_desc = "召唤木喉防御者时提醒转火，防止BOSS叠减伤——待实测校准",

    phase_cmd = "phase",
    phase_name = "阶段喊话警报",
    phase_desc = "根据卡什的喊话播报阶段切换——待实测校准",

    trigger_crushCast = "哨兵卡什开始施放粉碎重锤",
    trigger_felStomp = "开始施放邪能践踏",
    trigger_defenders = "防御者",
    trigger_phase1 = "禁止前进",
    trigger_phase2 = "趁我还没彻底失去理智",
    trigger_phase3 = "我会亲手碾碎他们",

    msg_crush = "粉碎重锤——MS给T上盾！注意仇恨清空！",
    msg_felstomp = "邪能践踏——近战离开BOSS！",
    msg_defenders = "转火木喉防御者！防止BOSS叠减伤！",
    msg_phase1 = "P1：粉碎重锤即将清仇恨——转火木喉防御者！",
    msg_phase2 = "P2：BOSS增伤20%——T抢仇恨防横扫，转火木喉哨兵！",
    msg_phase3 = "P3 Rush：BOSS攻速持续提升——腐蚀之种点名远离人群，全团爆发！",

    trigger_spearGain = "哨兵卡什获得了木喉之矛的效果",
    trigger_spearFade = "木喉之矛效果从哨兵卡什身上消失",
    trigger_roarCast = "哨兵卡什的狂怒咆哮击中",

    trigger_seedYou = "^你受到了腐蚀之种效果的影响",
    trigger_seedOther = "(.+)受到了腐蚀之种效果的影响",
    trigger_seedFadeYou = "腐蚀之种效果从你身上消失了",
    trigger_seedFadeOther = "腐蚀之种效果从(.+)身上消失",

    bar_roar = "狂怒咆哮",
    msg_roarSoon = "仇恨大幅度下降！",

    msg_seedYou = "你中了腐蚀之种-远离其他人！",
    msg_seedBack = "你的腐蚀之种已消失——可以回归大团位置！",
} end )


local timer = {
	roar = 12,
}

local icon = {
	roar = "Ability_Druid_DemoralizingRoar",
	seed = "ability_warlock_shadowflame",
}

local color = {
	roar = "Red",
	seed = "Purple",
}

local syncName = {
	spearGain = "KarrshSpearGain"..module.revision,
	spearFade = "KarrshSpearFade"..module.revision,
	roar = "KarrshRoar"..module.revision,
	seedGain = "KarrshSeedGain"..module.revision,
	seedFade = "KarrshSeedFade"..module.revision,
	crush = "KarrshCrush"..module.revision,
	felstomp = "KarrshFelStomp"..module.revision,
	defenders = "KarrshDefenders"..module.revision,
	phase1 = "KarrshPhase1"..module.revision,
	phase2 = "KarrshPhase2"..module.revision,
	phase3 = "KarrshPhase3"..module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL", "YellEvent")

	self:ThrottleSync(5, syncName.spearGain)
	self:ThrottleSync(5, syncName.spearFade)
	self:ThrottleSync(5, syncName.roar)
	-- per-target payloads; dedupe is handled by self.seedTargets so any
	-- throttle here would drop syncs for different players sharing the key
	self:ThrottleSync(0, syncName.seedGain)
	self:ThrottleSync(0, syncName.seedFade)
	self:ThrottleSync(10, syncName.crush)
	self:ThrottleSync(10, syncName.felstomp)
	self:ThrottleSync(15, syncName.defenders)
	self:ThrottleSync(15, syncName.phase1)
	self:ThrottleSync(15, syncName.phase2)
	self:ThrottleSync(15, syncName.phase3)
end

function module:OnSetup()
	self.seedTargets = {}
end
function module:OnEngage()
	self.seedTargets = {}
end
function module:OnDisengage()
	self:RemoveBar(L["bar_roar"])
	-- Framework auto-restores initialPlayerMarks on disengage (Core.lua:484-488),
	-- so seeds left applied will revert to the raid's original marks automatically.
	self.seedTargets = {}
end

function module:Event(msg)
	if string.find(msg, L["trigger_spearGain"]) then
		self:Sync(syncName.spearGain)
		return
	elseif string.find(msg, L["trigger_spearFade"]) then
		self:Sync(syncName.spearFade)
		return
	elseif string.find(msg, L["trigger_roarCast"]) then
		self:Sync(syncName.roar)
		return
	elseif self.db.profile.crush and string.find(msg, L["trigger_crushCast"]) then
		self:Sync(syncName.crush)
		return
	elseif self.db.profile.felstomp and string.find(msg, L["trigger_felStomp"]) then
		self:Sync(syncName.felstomp)
		return
	end

	-- Seed of Corruption gains
	if string.find(msg, L["trigger_seedYou"]) then
		self:Sync(syncName.seedGain.." "..UnitName("player"))
		return
	end
	local _, _, target = string.find(msg, L["trigger_seedOther"])
	if target then
		self:Sync(syncName.seedGain.." "..target)
		return
	end

	-- Seed of Corruption fades
	if string.find(msg, L["trigger_seedFadeYou"]) then
		self:Sync(syncName.seedFade.." "..UnitName("player"))
		return
	end
	local _, _, fadeTarget = string.find(msg, L["trigger_seedFadeOther"])
	if fadeTarget then
		self:Sync(syncName.seedFade.." "..fadeTarget)
		return
	end
end

-- 阶段喊话 + 防御者转火（待实测校准的触发串，均可通过选项关闭）
function module:YellEvent(msg)
	if self.db.profile.defenders and string.find(msg, L["trigger_defenders"]) then
		self:Sync(syncName.defenders)
		return
	end
	if self.db.profile.phase then
		if string.find(msg, L["trigger_phase1"]) then
			self:Sync(syncName.phase1)
		elseif string.find(msg, L["trigger_phase2"]) then
			self:Sync(syncName.phase2)
		elseif string.find(msg, L["trigger_phase3"]) then
			self:Sync(syncName.phase3)
		end
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.spearGain and self.db.profile.roar then
		self:StartRoarBar()
	elseif sync == syncName.roar and self.db.profile.roar then
		-- RCA 规则：狂怒咆哮 = 注意仇恨（T 仇恨大幅下降）
		self:Sound("voiceThreat")
		self:StartRoarBar()
	elseif sync == syncName.spearFade then
		self:RemoveBar(L["bar_roar"])
	elseif sync == syncName.seedGain and rest and self.db.profile.seed then
		self:SeedGain(rest)
	elseif sync == syncName.seedFade and rest and self.db.profile.seed then
		self:SeedFade(rest)
	elseif sync == syncName.crush and self.db.profile.crush then
		self:Message(L["msg_crush"], "Urgent", true, "Alarm")
	elseif sync == syncName.felstomp and self.db.profile.felstomp then
		self:Message(L["msg_felstomp"], "Urgent", true, "Alarm")
	elseif sync == syncName.defenders and self.db.profile.defenders then
		self:Message(L["msg_defenders"], "Urgent", true, "voiceSwitch")
	elseif sync == syncName.phase1 and self.db.profile.phase then
		self:Message(L["msg_phase1"], "Urgent", true, "voicePhase")
	elseif sync == syncName.phase2 and self.db.profile.phase then
		self:Message(L["msg_phase2"], "Urgent", true, "voicePhase")
	elseif sync == syncName.phase3 and self.db.profile.phase then
		self:Message(L["msg_phase3"], "Urgent", true, "voicePhase")
	end
end

function module:StartRoarBar()
	self:RemoveBar(L["bar_roar"])
	self:CancelDelayedMessage(L["msg_roarSoon"])
	-- pass otherc=nil so BigWigsColors drives the time-based gradient
	self:Bar(L["bar_roar"], timer.roar, icon.roar)
	-- fire the warning only in the final 3 seconds
	self:DelayedMessage(timer.roar - 4, L["msg_roarSoon"], "Important", false, "Alert")
end

function module:SeedGain(target)
	if self.seedTargets[target] then return end
	self.seedTargets[target] = true

	if target == UnitName("player") then
		self:Message(L["msg_seedYou"], "Personal", true, "voiceOut")
		self:WarningSign(icon.seed, 3, true)
	end

	local mark = self:GetAvailableRaidMark()
	if mark then
		self:SetRaidTargetForPlayer(target, mark)
	end
end

function module:SeedFade(target)
	if not self.seedTargets[target] then return end
	self.seedTargets[target] = nil
	self:RestorePreviousRaidTargetForPlayer(target)
	-- 归位提醒：腐蚀之种消掉后远离人群的人可以回大团了
	if target == UnitName("player") then
		self:Message(L["msg_seedBack"], "Positive", false, "Long")
	end
end