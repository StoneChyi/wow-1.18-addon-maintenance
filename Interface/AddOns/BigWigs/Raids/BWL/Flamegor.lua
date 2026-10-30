local module, L = BigWigs:ModuleDeclaration("Flamegor", "Blackwing Lair")
local BC = AceLibrary("Babble-Class-2.2")

module.revision = 30141
module.enabletrigger = module.translatedName
module.toggleoptions = {"wingbuffet", "shadowflame", "frenzy", -1, "mcalert", "mcbar", "mcmark", "bosskill"}
module.defaultDB = {
	mcbar = false,
}

L:RegisterTranslations("enUS", function() return {
	cmd = "Flamegor",

	wingbuffet_cmd = "wingbuffet",
	wingbuffet_name = "Wing Buffet Alert",
	wingbuffet_desc = "Warn for Wing Buffet",

	shadowflame_cmd = "shadowflame",
	shadowflame_name = "Shadow Flame Alert",
	shadowflame_desc = "Warn for Shadow Flame",

	frenzy_cmd = "frenzy",
	frenzy_name = "Frenzy Alert",
	frenzy_desc = "Warn for Frenzy",

	mcalert_cmd = "mcalert",
	mcalert_name = "Overbearing Rage Alert",
	mcalert_desc = "Warn when Overbearing Rage (mind control) happens",

	mcbar_cmd = "mcbar",
	mcbar_name = "Overbearing Rage Health Bar",
	mcbar_desc = "Show a health bar for victims of Overbearing Rage (bring them to 25% HP to end the effect, they cannot be CCed)",

	mcmark_cmd = "mcmark",
	mcmark_name = "Overbearing Rage Mark",
	mcmark_desc = "Mark the victim of Overbearing Rage with Diamond",
	
	
	trigger_wingBuffet = "Flamegor begins to cast Wing Buffet.", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_wingBuffetCast = "Casting Wing Buffet!",
	bar_wingBuffetCd = "Wing Buffet CD",
	msg_wingBuffetCast = "Casting Wing Buffet!",
	msg_wingBuffetSoon = "Wing Buffet in 2 seconds - Taunt now!",
	
	trigger_shadowFlame = "Flamegor begins to cast Shadow Flame.", -- 修改：原 trigger_shadowFlameCast 改为 trigger_shadowFlame
	bar_shadowFlameCast = "Casting Shadow Flame!",
	msg_shadowFlameCast = "Casting Shadow Flame!",
	trigger_shadowFlameHit = "Flamegor's Shadow Flame hits", --CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE
	bar_shadowFlameCd = "Shadow Flame CD",
	
	trigger_frenzy = "Flamegor gains Frenzy.", --CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS
	trigger_frenzyFade = "Frenzy fades from Flamegor.", --CHAT_MSG_SPELL_AURA_GONE_OTHER
	bar_frenzyCd = "Frenzy CD",
	bar_frenzyDur = "Frenzy!",
	msg_frenzy = "Frenzy - Tranq now!",
	
	trigger_mcYou = "You are afflicted by Overbearing Rage", --CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE
	trigger_mcOther1 = "(.+) is afflicted by Overbearing Rage", --CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE
	trigger_mcOther2 = "(.+) %(Flamegor%) is afflicted by Overbearing Rage", --CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE
	trigger_mcFade = "Overbearing Rage fades from (.+)%.", --CHAT_MSG_SPELL_AURA_GONE_OTHER
	bar_mc = "%s Rage",
	msg_mc = "%s raging out! - bring to 25%% or kill boss",
	
	trigger_death = "(.+) dies%."
} end)


L:RegisterTranslations("zhCN", function() return {
	-- Sunelegy，Wind汉化修复Turtle-WOW中文数据
	-- Last update: 2024-06-22 (修复键名错误)
    cmd = "Flamegor",

    wingbuffet_cmd = "wingbuffet",
    wingbuffet_name = "龙翼打击警报",
    wingbuffet_desc = "龙翼打击出现时进行警告",

    shadowflame_cmd = "shadowflame",
    shadowflame_name = "暗影烈焰警报",
    shadowflame_desc = "暗影烈焰出现时进行警告",

    frenzy_cmd = "frenzy",
    frenzy_name = "狂暴警报",
    frenzy_desc = "狂暴出现时进行警告",

    mcalert_cmd = "mcalert",
	mcalert_name = "压迫怒气警报",
	mcalert_desc = "当压迫怒气（心控）发生时发出警告",

	mcbar_cmd = "mcbar",
	mcbar_name = "压迫怒气生命条",
	mcbar_desc = "显示压迫怒气受害者的生命条（将其生命值降至25%%可解除效果，无法被控制）",

	mcmark_cmd = "mcmark",
	mcmark_name = "压迫怒气标记",
	mcmark_desc = "将压迫怒气的受害者标记为钻石",
	
	
    trigger_wingBuffet = "弗莱格尔开始施放龙翼打击",
    bar_wingBuffetCast = "正在施放龙翼打击！",
    bar_wingBuffetCd = "龙翼打击冷却",
    msg_wingBuffetCast = "正在施放龙翼打击！",
    msg_wingBuffetSoon = "2秒后龙翼打击-现在嘲讽！",

    -- 修复：原 trigger_shadowFlameCast 改为 trigger_shadowFlame
    trigger_shadowFlame = "弗莱格尔开始施放暗影烈焰",
    bar_shadowFlameCast = "正在施放暗影烈焰！",
    msg_shadowFlameCast = "正在施放暗影烈焰！",
    trigger_shadowFlameHit = "弗莱格尔的暗影烈焰击中",
	bar_shadowFlameCd = "暗影烈焰冷却",

    trigger_frenzy = "弗莱格尔获得了疯狂的效果",
    trigger_frenzyFade = "疯狂效果从弗莱格尔身上消失",
    bar_frenzyCd = "狂暴冷却",
    bar_frenzyDur = "狂暴！",
    msg_frenzy = "狂暴-立即宁神！",

    trigger_mcYou = "你受到了怒火中烧效果的影响",
	trigger_mcOther1 = "(.+)受到了怒火中烧效果的影响",
	trigger_mcOther2 = "(.+) %(弗莱格尔%)受到压迫怒气效果的影响",
	trigger_mcFade = "怒火中烧效果从(.+)身上消失",
	bar_mc = "%s怒气",
	msg_mc = "%s狂暴失控！-将其生命值降至25%%或击杀首领",
	
	trigger_death = "(.+)死亡了"
} end)

local timer = {
	wingBuffetFirstCd = 30,
	wingBuffetCd = 29, --30sec - 1sec cast
	wingBuffetCast = 1,
	
	shadowFlameFirstCd = 16,
	shadowFlameCd = 14, --16 - 2sec cast
	shadowFlameCast = 2,
	
	frenzyCd = 10,
	frenzyDur = 10,
}
local icon = {
	wingBuffet = "INV_Misc_MonsterScales_14",
	shadowFlame = "Spell_Fire_Incinerate",
	frenzy = "Ability_Druid_ChallangingRoar",
	tranquil = "Spell_Nature_Drowsy",
}
local color = {
	wingBuffetCd = "Cyan",
	wingBuffetCast = "Blue",
	
	shadowFlameCd = "Orange",
	shadowFlameCast = "Red",
	
	frenzyCd = "Black",
	frenzyDur = "Magenta",
}
local syncName = {
	wingBuffet = "FlamegorWingBuffet"..module.revision,
	shadowFlame = "FlamegorShadowflame"..module.revision,
	frenzy = "FlamegorFrenzyStart"..module.revision,
	frenzyFade = "FlamegorFrenzyEnd"..module.revision,
}

local frenzyStartTime = 0
local frenzyEndTime = 0

function module:OnEnable()
	--self:RegisterEvent("CHAT_MSG_SAY", "Event") --Debug
	
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "Event") --trigger_frenzy
	
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER", "Event") --trigger_frenzyFade
	
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "Event") --trigger_wingBuffet, trigger_shadowFlame
	
	
	self:ThrottleSync(3, syncName.wingBuffet)
	self:ThrottleSync(3, syncName.shadowFlame)
	self:ThrottleSync(5, syncName.frenzy)
	self:ThrottleSync(1, syncName.frenzyFade)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
	frenzyStartTime = 0
	frenzyEndTime = 0
	
	if self.db.profile.wingbuffet then
		self:Bar(L["bar_wingBuffetCd"], timer.wingBuffetFirstCd, icon.wingBuffet, true, color.wingBuffetCd)
		self:DelayedMessage(timer.wingBuffetFirstCd - 2, L["msg_wingBuffetSoon"], "Attention", false, nil, false)
	end
	
	if self.db.profile.shadowflame then
		self:Bar(L["bar_shadowFlameCd"], timer.shadowFlameFirstCd, icon.shadowFlame, true, color.shadowFlameCd)
	end
	
	if self.db.profile.frenzy then
		self:Bar(L["bar_frenzyCd"], timer.frenzyCd, icon.frenzy, true, color.frenzyCd)
	end
end

function module:OnDisengage()
end


function module:Event(msg)
	if msg == L["trigger_wingBuffet"] then
		self:Sync(syncName.wingBuffet)
	
	elseif msg == L["trigger_shadowFlame"] then
		self:Sync(syncName.shadowFlame)
	
	elseif msg == L["trigger_frenzy"] then
		self:Sync(syncName.frenzy)
	elseif msg == L["trigger_frenzyFade"] then
		self:Sync(syncName.frenzyFade)
	end
end


function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.wingBuffet and self.db.profile.wingbuffet then
		self:WingBuffet()
	elseif sync == syncName.shadowFlame and self.db.profile.shadowflame then
		self:ShadowFlame()
	elseif sync == syncName.frenzy and self.db.profile.frenzy then
		self:Frenzy()
	elseif sync == syncName.frenzyFade and self.db.profile.frenzy then
		self:FrenzyFade()
	end
end


function module:WingBuffet()
	self:CancelDelayedMessage(L["msg_wingBuffetSoon"])
	self:RemoveBar(L["bar_wingBuffetCd"])
	
	self:Bar(L["bar_wingBuffetCast"], timer.wingBuffetCast, icon.wingBuffet, true, color.wingBuffetCast)
	
	self:DelayedBar(timer.wingBuffetCast, L["bar_wingBuffetCd"], timer.wingBuffetCd, icon.wingBuffet, true, color.wingBuffetCd)
	self:DelayedMessage(timer.wingBuffetCast + timer.wingBuffetCd - 2, L["msg_wingBuffetSoon"], "Attention", false, nil, false)
end

function module:ShadowFlame()
	self:RemoveBar(L["bar_shadowFlameCd"])
	
	self:Bar(L["bar_shadowFlameCast"], timer.shadowFlameCast, icon.shadowFlame, true, color.shadowFlameCast)
	self:Message(L["msg_shadowFlameCast"], "Urgent", false, nil, false)
	
	self:DelayedBar(timer.shadowFlameCast, L["bar_shadowFlameCd"], timer.shadowFlameCd, icon.shadowFlame, true, color.shadowFlameCd)
end

function module:Frenzy()
	self:RemoveBar(L["bar_frenzyCd"])
	
	if UnitClass("Player") == BC["Hunter"] then
		self:Message(L["msg_frenzy"], "Urgent", false, nil, false)
		self:Sound("Info")
		self:WarningSign(icon.tranquil, 1)
	end
	
	self:Bar(L["bar_frenzyDur"], timer.frenzyDur, icon.frenzy, true, color.frenzyDur)
	frenzyStartTime = GetTime()
end

function module:FrenzyFade()
	self:RemoveBar(L["bar_frenzyDur"])
	self:RemoveWarningSign(icon.tranquil)
	
	frenzyEndTime = GetTime()
	
	self:Bar(L["bar_frenzyCd"], timer.frenzyCd - (frenzyEndTime - frenzyStartTime), icon.frenzy, true, color.frenzyCd)
end