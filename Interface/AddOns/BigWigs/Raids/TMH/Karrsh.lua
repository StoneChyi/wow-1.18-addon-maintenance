
local module, L = BigWigs:ModuleDeclaration("Karrsh the Sentinel", "Timbermaw Hold")

module.revision = 30000
module.enabletrigger = module.translatedName
module.toggleoptions = {"roar", "seed", "bosskill"}
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
} end )

L:RegisterTranslations("zhCN", function() return {
    cmd = "Karrsh",

    roar_cmd = "roar",
    roar_name = "狂怒咆哮警报",
    roar_desc = "当卡什手持木喉之矛时，为狂怒咆哮技能提供计时器",

    seed_cmd = "seed",
    seed_name = "腐蚀之种警报",
    seed_desc = "当有人被施加腐蚀之种时发出警告并标记该玩家",

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
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_PARTY", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "Event")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "Event")

	self:ThrottleSync(5, syncName.spearGain)
	self:ThrottleSync(5, syncName.spearFade)
	self:ThrottleSync(5, syncName.roar)
	-- per-target payloads; dedupe is handled by self.seedTargets so any
	-- throttle here would drop syncs for different players sharing the key
	self:ThrottleSync(0, syncName.seedGain)
	self:ThrottleSync(0, syncName.seedFade)
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

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.spearGain and self.db.profile.roar then
		self:StartRoarBar()
	elseif sync == syncName.roar and self.db.profile.roar then
		self:StartRoarBar()
	elseif sync == syncName.spearFade then
		self:RemoveBar(L["bar_roar"])
	elseif sync == syncName.seedGain and rest and self.db.profile.seed then
		self:SeedGain(rest)
	elseif sync == syncName.seedFade and rest and self.db.profile.seed then
		self:SeedFade(rest)
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
		self:Message(L["msg_seedYou"], "Personal", true, "Alarm")
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
end