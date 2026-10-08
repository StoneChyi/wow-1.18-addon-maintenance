local module, L = BigWigs:ModuleDeclaration("Peroth'arn", "Timbermaw Hold")

-- module variables
module.revision = 30139
module.enabletrigger = module.translatedName
module.toggleoptions = { "flames", "flamesothers", "flamesmark", "flamessay", -1, "disarm", "dirk", "burst", "nightmarishAbsorption", "summon", "bosskill"}

module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

local _, playerClass = UnitClass("player")

-- module defaults
module.defaultDB = {
	flames = true,
	flamesothers = true,
	flamesmark = true,
	flamessay = true,
	disarm = true,
	dirk = true,
	burst = true,
	nightmarishAbsorption = true,
	summon = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "Perotharn",

		flames_cmd = "flames",
		flames_name = "Flames of Purgation alert",
		flames_desc = "Personal alert about being afflicted by Flames of Purgation",

		flamesothers_cmd = "flamesothers",
		flamesothers_name = "Flames of Purgation warning",
		flamesothers_desc = "Warning messages about all 4 victims of Flames of Purgation",

		flamesmark_cmd = "flamesmark",
		flamesmark_name = "Flames of Purgation marks",
		flamesmark_desc = "Mark all 4 victims of Flames of Purgation with available raid targets",

		flamessay_cmd = "flamessay",
		flamessay_name = "Flames of Purgation say",
		flamessay_desc = "Announce in /say when you are afflicted by Flames of Purgation",

		say_flames = "I have Flames of Purgation - run away from me!",

	    nightmarishAbsorption_cmd = "nightmarishAbsorption",
	    nightmarishAbsorption_name = "Nightmarish Absorption Shield",
	    nightmarishAbsorption_desc = "Show a bar tracking damage absorbed by Nightmarish Absorption",

	    trigger_shieldGain = "Nightmarish Absorption",
	    trigger_shieldFade = "Nightmarish Absorption fades from Peroth'arn",

	    bar_shield = "Absorption",

		disarm_cmd = "disarm",
		disarm_name = "Disarm alert",
		disarm_desc = "Alert when Peroth'arn becomes vulnerable",

		dirk_cmd = "dirk",
		dirk_name = "Dirk alert",
		dirk_desc = "Personal alert when you stand in the mind-control zone/beam (Dirk of the Beast)",

		burst_cmd = "burst",
		burst_name = "Nightmare Burst cast bar",
		burst_desc = "Shows a cast bar for incoming knockback (Nightmare Burst)",

		summon_cmd = "summon",
		summon_name = "Summon alert",
		summon_desc = "Alert when Vile Corruptor is summoned",
		bar_summon = "Summon Vile Corruptor",
		bar_ksummon = "Summon Vile Corruptor",
		msg_yellSummon = "Vile Corruptor has been summoned!",
		trigger_summon = "Submit to my master's glory",

		trigger_flames = "(.+) ...? afflicted by Flames of Purgation",
		msg_flames = "%s has Flames of Purgation",
		msg_flamesYou = "YOU have Flames - don't be near people when it expires",
		
		trigger_dirk = "^You are afflicted by Dirk of the Beast",
		trigger_dirkFade = "Dirk of the Beast fades from you.",
		warn_dirk = "MOVE",
		warn_summon = "MOVE",
		
		trigger_shield = "Wretched pests! You shall join the ranks of the enlightened!",
		trigger_disarm = "becomes vulnerable!",
		warn_disarm = "DISARM",
		warn_burst = "kick！",
		trigger_disarmed = "Insolent vermin! You will regret this!",
		
		
		trigger_burst = "Peroth'arn begins to perform Nightmare Burst.",
		bar_burst = "incoming Knockback",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Perotharn",

		flames_cmd = "flames",
		flames_name = "净化火焰警报",
		flames_desc = "被净化火焰影响时的个人警报",

		flamesothers_cmd = "flamesothers",
		flamesothers_name = "涤净化火焰提醒",
		flamesothers_desc = "显示所有4名净化火焰受害者的提醒信息",

		flamesmark_cmd = "flamesmark",
		flamesmark_name = "净化火焰标记",
		flamesmark_desc = "为所有4名净化火焰受害者标记团队图标",

		flamessay_cmd = "flamessay",
		flamessay_name = "净化火焰喊话",
		flamessay_desc = "当你中了净化火焰时向/say频道喊话，提醒周围人跑开",

		say_flames = "我中了净化火焰，快跑开人群！",


	    nightmarishAbsorption_cmd = "nightmarishAbsorption",
	    nightmarishAbsorption_name = "噩梦吸收护盾",
	    nightmarishAbsorption_desc = "显示噩梦吸收护盾吸收伤害的进度条",

	    trigger_shieldGain = "噩梦吸收",
	    trigger_shieldFade = "噩梦吸收效果从佩罗萨恩身上消失",

	    bar_shield = "吸收盾",

		disarm_cmd = "disarm",
		disarm_name = "缴械警报",
		disarm_desc = "佩罗萨恩进入易伤状态时发出警报",

		dirk_cmd = "dirk",
		dirk_name = "野蛮短刃警报",
		dirk_desc = "当你站在心控区域/光束中（野蛮短刃）时的个人警报",

		burst_cmd = "burst",
		burst_name = "噩梦降临施法条",
		burst_desc = "显示即将到来的击飞（噩梦降临）施法条",

		summon_cmd = "summon",
		summon_name = "召唤警报",
		summon_desc = "召唤腐心操纵者时进行警告",
		bar_summon = "召唤腐心操纵者",
		bar_ksummon = "可能 召唤腐心操纵者",
		msg_yellSummon = "萨特出现！打断诱惑之力！",
		trigger_summon = "臣服于我主人的荣光",

		trigger_flames = "(.+)受到了净化之焰效果的影响",
		msg_flames = "%s中了净化火焰",
		msg_flamesYou = "你中了净化火焰-效果结束时远离人群",
		
		trigger_dirk = "^你受到了野蛮短刃效果的影响",
		trigger_dirkFade = "野蛮短刃效果从你身上消失",
		warn_dirk = "离开光束",
		warn_summon = "召唤萨特！",

		trigger_shield = "可悲的蝼蚁",
		trigger_disarm = "佩罗萨恩陷入虚弱",
		warn_disarm = "缴械",
		warn_burst = "击飞",
		trigger_disarmed = "狂妄的虫子",
		
		trigger_burst = "佩罗萨恩开始施放噩梦降临",
		bar_burst = "远离BOSS，即将击飞",
	}
end)

-- timer and icon variables
local timer = {
	flames = 8,
	dirk = 3,
	burst = 3,
	firstSummon = 30,
	summon = 50,
}
local shieldMax = 300000
local color = {
	nightmarishAbsorption = "Red",
	summon = "Cyan",
}

local icon = {
	flames = "Spell_Fire_Immolation",
	dirk = "Spell_Holy_InnerFire",
	disarm = "Ability_Warrior_Disarm",
	burst = "Ability_Kick",
	nightmarishAbsorption = "Spell_Shadow_AntiShadow",
	summon = "Spell_Shadow_SiphonMana",
}

local shieldSyncStep = shieldMax * 0.05 -- sync every 5% of shield

local syncName = {
	flames = "THPerotharnFlames" .. module.revision,
	burst = "THPerotharnBurst" .. module.revision,
	shieldGain    = "PerothShieldGain"..module.revision,
	shieldFade    = "PerothShieldFade"..module.revision,
	shieldAbsorbed = "PerothShieldAbs"..module.revision,
	summon = "PerothSummon"..module.revision,
	resetSummonTimer = "PerothResetSummon"..module.revision,
}

local spellId = {
}

local absorbPatternHit = "佩罗萨恩造成%d+点.*%((%d+)点被吸收%)"
local absorbPatternSelf = "你.-佩罗萨恩造成%d+点.*%((%d+)点被吸收%)"
local absorbPatternDot  = "佩罗萨恩受到了%d+点.*%((%d+)点被吸收%)"

local absorbEvents = {
	-- Melee hits
	"CHAT_MSG_COMBAT_SELF_HITS",
	"CHAT_MSG_COMBAT_PARTY_HITS",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
	"CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
	"CHAT_MSG_COMBAT_PET_HITS",
	-- Spell hits
	"CHAT_MSG_SPELL_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PET_DAMAGE",
	-- Damage shields (thorns, ret aura, etc.)
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS",
	-- DoT/periodic ticks
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE",
}

function module:RegisterAbsorbEvents()
	for _, event in ipairs(absorbEvents) do
		self:RegisterEvent(event, "AbsorbEvent")
	end
end

function module:UnregisterAbsorbEvents()
	for _, event in ipairs(absorbEvents) do
		if self:IsEventRegistered(event) then
			self:UnregisterEvent(event)
		end
	end
end

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE", "AfflictionEvent") -- for mind-control
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "AfflictionEvent") -- for pets

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent")
	--self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "CastEvent")

	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "BuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "FadeEvent")

	self:ThrottleSync(5, syncName.shieldGain)
	self:ThrottleSync(5, syncName.shieldFade)
	self:ThrottleSync(3, syncName.burst)
	self:ThrottleSync(5, syncName.summon)
	self:ThrottleSync(5, syncName.resetSummonTimer)
	self:Message("友情提示：佩戴勇士印记/恶魔套装", "Important", false, nil, false)
end

function module:OnSetup()
	self.shieldAbsorbed = 0
	self.shieldActive = false
	self.lastSyncThreshold = 0
end

function module:OnEngage()
	self.shieldAbsorbed = 0
	self.shieldActive = false
	self.lastSyncThreshold = 0
    self:Bar(L["bar_summon"], timer.firstSummon, icon.summon, true, color.summon)

end

function module:OnDisengage()
    self:UnregisterAbsorbEvents()
    self.shieldAbsorbed = 0
    self.shieldActive = false
    self.lastSyncThreshold = 0
end


function module:BuffEvent(msg)
	if string.find(msg, L["trigger_shieldGain"]) then
		self:Sync(syncName.shieldGain)
	end
end

function module:FadeEvent(msg)
	if self.db.profile.dirk and string.find(msg, L["trigger_dirkFade"]) then
		self:RemoveWarningSign(icon.dirk)
		self:Sound("Long")
	end
end

function module:AfflictionEvent(msg)
	if self.db.profile.dirk and string.find(msg, L["trigger_dirk"]) then
		self:Sound("Beware")
		self:WarningSign(icon.dirk, timer.dirk, true, L["warn_dirk"])
		return
	end

	local _, _, player = string.find(msg, L["trigger_flames"])
	if player then
		player = player == "你" and UnitName("player") or player
		self:Sync(syncName.flames .. player) -- bake player into sync name to throttle per player
		return
	end
end

function module:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	if string.find(msg, L["trigger_disarm"]) then
		self:Sync(syncName.shieldFade)
	end
end

function module:CastEvent(msg)
	if string.find(msg, L["trigger_burst"]) then
		self:Sync(syncName.burst)
	end
end

function module:CHAT_MSG_MONSTER_YELL(msg)
	if string.find(msg, L["trigger_disarmed"]) then
		self:RemoveWarningSign(icon.disarm)
        self:Bar(L["bar_ksummon"], 20, icon.summon, true, color.summon)
	end
	if self.db.profile.summon and string.find(msg, L["trigger_summon"]) then
		self:Sync(syncName.summon)
	end
end


function module:UpdateShieldBar()
	self:TriggerEvent("BigWigs_SetHPBar", self, L["bar_shield"], self.shieldAbsorbed)
	local remaining = shieldMax - self.shieldAbsorbed
	local barId = "BigWigsBar "..L["bar_shield"]
	self:SetCandyBarText(barId,
		string.format("%s - %.1f万 / 30万", L["bar_shield"], remaining / 10000))
end

function module:AbsorbEvent(msg)
	if not self.shieldActive then return end
	local _, _, absorbed = string.find(msg, absorbPatternHit)
	if not absorbed then
		_, _, absorbed = string.find(msg, absorbPatternSelf)
	end
	if not absorbed then
		_, _, absorbed = string.find(msg, absorbPatternDot)
	end
	if absorbed then
		self.shieldAbsorbed = self.shieldAbsorbed + tonumber(absorbed)
		if self.shieldAbsorbed > shieldMax then
			self.shieldAbsorbed = shieldMax
		end
		self:UpdateShieldBar()

		local threshold = math.floor(self.shieldAbsorbed / shieldSyncStep)
		if threshold > self.lastSyncThreshold then
			self.lastSyncThreshold = threshold
			self:Sync(syncName.shieldAbsorbed .. " " .. self.shieldAbsorbed)
		end
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	local _, _, player = string.find(sync, syncName.flames .. "(.+)")
	if player then
		self:FlamesOfPurgation(player)
		return
	end
	if self.db.profile.burst and sync == syncName.burst then
		self:Bar(L["bar_burst"], timer.burst, icon.burst, true, color.summon)
		self:WarningSign(icon.burst, 3, true, L["warn_burst"])
		return
	end
	if self.db.profile.summon and sync == syncName.summon then
		self:Message(L["msg_yellSummon"], "Attention", nil, "Alert")
		self:WarningSign(icon.summon, 3, true, L["warn_summon"])
		self:Bar(L["bar_summon"], timer.summon, icon.summon, true, color.summon)
		return
	end
	if sync == syncName.shieldGain and self.db.profile.nightmarishAbsorption then
		self.shieldAbsorbed = 0
		self.shieldActive = true
		self.lastSyncThreshold = 0
		self:RegisterAbsorbEvents()
		self:TriggerEvent("BigWigs_StartHPBar", self, L["bar_shield"], shieldMax,
			"Interface\\Icons\\"..icon.nightmarishAbsorption, true, color.nightmarishAbsorption)
		-- Hide the timer text (too narrow for 6-digit numbers) and show value in the label
		self:PauseCandyBar("BigWigsBar "..L["bar_shield"], true)
		self:UpdateShieldBar()
		self:RemoveBar(L["bar_summon"])
	elseif sync == syncName.shieldFade and self.db.profile.nightmarishAbsorption then
		self:UnregisterAbsorbEvents()
		self.shieldActive = false
		self:TriggerEvent("BigWigs_StopHPBar", self, L["bar_shield"])
		self:WarningSign(icon.disarm, 3, true, L["warn_disarm"])
		self:Sound("jiaoxie")
	elseif sync == syncName.shieldAbsorbed and rest and self.shieldActive then
		local val = tonumber(rest)
		if val and val > self.shieldAbsorbed then
			self.shieldAbsorbed = val
			self.lastSyncThreshold = math.floor(val / shieldSyncStep)
			self:UpdateShieldBar()
		end
	end
end

function module:FlamesOfPurgation(player)
    if player == UnitName("player") and self.db.profile.flames then
        self:WarningSign(icon.flames, 1)
        self:Message(string.format(L["msg_flamesYou"], player), "Urgent", true, "Beware")
    elseif self.db.profile.flamesothers then
        self:Message(string.format(L["msg_flames"], player), "Urgent")
    end
    if self.db.profile.flamessay and player == UnitName("player") then
        SendChatMessage(L["say_flames"], "SAY")
    end
    if self.db.profile.flamesmark then
        local markToUse = self:GetAvailableRaidMark(nil, true)
        if markToUse then
            self:SetRaidTargetForPlayer(player, markToUse)
            self:ScheduleEvent("RemoveFlamesMark"..player, self.RestoreInitialRaidTargetForPlayer, timer.flames, self, player)
        end
    end
end

