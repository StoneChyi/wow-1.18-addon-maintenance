local module, L = BigWigs:ModuleDeclaration("Ormanos the Cracked", "Timbermaw Hold")

-- module variables
module.revision = 30138
module.enabletrigger = module.translatedName
module.toggleoptions = { "crushcast", "crushzone", -1, "charge", "chargesay", "chargemark", -1, "attunement", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

-- module defaults
module.defaultDB = {
	crushcast = true,
	crushzone = true,
	charge = true,
	chargesay = true,
	chargemark = true,
	attunement = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "Ormanos",

		crushcast_cmd = "crushcast",
		crushcast_name = "Crush Earth cast",
		crushcast_desc = "Timer bar for a new floor zone appearing (Crush Earth)",

		crushzone_cmd = "crushzone",
		crushzone_name = "Crush Earth zone",
		crushzone_desc = "Personal alert when you stand in a floor zone (Crush Earth)",

		charge_cmd = "charge",
		charge_name = "Charge alert",
		charge_desc = "Cast bar and personal alert if you are the target of Rampaging Earth (charge)",

		chargesay_cmd = "chargesay",
		chargesay_name = "Charge say",
		chargesay_desc = "Announce a charge targeting you to /say",

		chargemark_cmd = "chargemark",
		chargemark_name = "Charge mark",
		chargemark_desc = "Mark Charge target with Triangle",

		attunement_cmd = "attunement",
		attunement_name = "Attunement indicator",
		attunement_desc = "Show the current vulnerability and immunity on screen",

		trigger_engage = "Rock and Stone...",

		trigger_crushCast = "Ormanos the Cracked begins to cast Crush Earth.",
		bar_crushCast = "New AoE Zone",
		trigger_crushZone = "You are afflicted by Crush Earth",
		trigger_crushZoneTick = "You suffer .+ Nature damage from Ormanos the Cracked's Crush Earth.",
		warn_crushZone = "MOVE",
		trigger_crushZoneFade = "Crush Earth fades from you.",

		trigger_charge = "Ormanos is preparing to charge (.+)!",
		bar_charge = "Charge on %s",
		msg_chargeSelf = "Run away and stack with others!",
		msg_chargeOther = "Stack on %s far away from the boss!",
		say_charge = "Charge on Me!",

		trigger_attunement = "Ormanos attunes to .+, becoming immune to (.+) and vulnerable to (.+)!",
		bar_attunement = "%s, no %s",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Ormanos",

		crushcast_cmd = "crushcast",
		crushcast_name = "破碎大地施法",
		crushcast_desc = "地面伤害区域出现前的计时条（破碎大地）",

		crushzone_cmd = "crushzone",
		crushzone_name = "破碎大地区域",
		crushzone_desc = "当你站在地板区域内时的个人警报（破碎大地）",

		charge_cmd = "charge",
		charge_name = "冲锋警报",
		charge_desc = "当你成为冲锋目标时的施法条和个人警报",

		chargesay_cmd = "chargesay",
		chargesay_name = "冲锋喊话",
		chargesay_desc = "当冲锋指向你时在/say频道喊话",

		chargemark_cmd = "chargemark",
		chargemark_name = "冲锋标记",
		chargemark_desc = "用三角标记冲锋目标",

		attunement_cmd = "attunement",
		attunement_name = "共鸣指示器",
		attunement_desc = "在屏幕上显示当前的易伤和免疫状态",

		trigger_engage = "岩石与石头",  -- 请根据实际BOSS喊话调整

		trigger_crushCast = "裂地者欧曼诺斯开始施放破碎大地",
		bar_crushCast = "新地面伤害区域",
		trigger_crushZone = "你受到了破碎大地效果的影响",
		trigger_crushZoneTick = "裂地者欧曼诺斯的破碎大地击中你造成%d+点自然伤害",
		warn_crushZone = "快离开",
		trigger_crushZoneFade = "破碎大地效果从你身上消失了",

		trigger_charge = "欧曼诺斯准备向(.+)发起冲锋",
		bar_charge = "冲锋%s",
		msg_chargeSelf = "跑开并与其他玩家集合！",
		msg_chargeOther = "远离BOSS，在%s处集合！",
		say_charge = "冲锋在我身上！",

		trigger_attunement = "对(.+)伤害免疫，同时受到(.+)伤害加成",
		bar_attunement = "%s免疫，%s易伤",
	}
end)

-- timer and icon variables
local timer = {
	crushCast = 2.5,
	crushDuration = 25,
	charge = 6,
	attunementCast = 2,
}

local icon = {
	crush = "Spell_Nature_Earthquake",
	charge = "Ability_Warrior_Charge",
	attunement = "Spell_Nature_AstralRecalGroup",
}

local syncName = {
}

local guid = {
	ormanos = "0xF13000F5D72794D4",
}

local spellId = {
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "FadesEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "SpellEvent")
	
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function module:OnSetup()
end

function module:OnEngage()
end

function module:OnDisengage()
end

function module:AfflictionEvent(msg)
	if self.db.profile.crushzone then
		if string.find(msg, L["trigger_crushZone"]) then
			self:Sound("Info")
			self:WarningSign(icon.crush, 3, false, L["warn_crushZone"])
			return
		elseif self.db.profile.crushzone and string.find(msg, L["trigger_crushZoneTick"]) then
			self:Sound("Info")
			return
		end
	end
end

function module:FadesEvent(msg)
	if msg == L["trigger_crushZoneFade"] then
		self:RemoveWarningSign(icon.crush)
		self:Sound("Long")
	end
end

function module:SpellEvent(msg)
	if self.db.profile.crushcast and string.find(msg, L["trigger_crushCast"]) then
		self:Bar(L["bar_crushCast"], timer.crushCast * BigWigs:GetCastTimeCoefficient(guid.ormanos), icon.crush, true, "Yellow")
	end
end

function module:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	local _, _, player = string.find(msg, L["trigger_charge"])
	if player then
		self:Charge(player)
	end

	local _, _, imm, vuln = string.find(msg, L["trigger_attunement"])
	if imm and vuln then
		self:ScheduleEvent("NewAttunement", self.Attunement, timer.attunementCast * BigWigs:GetCastTimeCoefficient(guid.ormanos), self, imm, vuln)
	end
end

function module:Charge(player)
	local adjustedTimer = timer.charge * BigWigs:GetCastTimeCoefficient(guid.ormanos)

	if self.db.profile.charge then
		self:Bar(string.format(L["bar_charge"], player), adjustedTimer, icon.charge)

		if player == UnitName("player") then
			-- 自己是被冲目标
			self:Message(L["msg_chargeSelf"], "Important", true, "RunAway")

			-- 职业特定保命提醒（不含萨满，因为萨满由全局统一提示）
			local _, class = UnitClass("player")
			if class == "PALADIN" then
				self:Message("使用无敌！", "Important", true, "Alert")
			elseif class == "HUNTER" then
				self:Message("使用假死！", "Important", true, "Alert")
			elseif class == "ROGUE" then
				self:Message("使用消失！", "Important", true, "Alert")
			elseif class == "MAGE" then
				self:Message("使用冰箱！", "Important", true, "Alert")
			end
		else
			-- 别人被冲：提示集合
			self:Message(string.format(L["msg_chargeOther"], player), "Attention", nil, "Alarm")
		end

		-- ★ 全局萨满提醒：只要有人被冲锋，当前玩家是萨满就提示使用根基图腾
		local _, class = UnitClass("player")
		if class == "SHAMAN" then
			self:Message("使用根基图腾！", "Important", true, "Alert")
		end
	end

	-- 原有喊话
	if self.db.profile.chargesay and player == UnitName("player") then
		SendChatMessage(L["say_charge"], "SAY")
	end

	-- 原有标记
	if self.db.profile.chargemark then
		self:SetRaidTargetForPlayer(player, "Triangle")
		self:ScheduleEvent("RemoveChargeMark"..player, self.RestoreInitialRaidTargetForPlayer, adjustedTimer, self, player)
	end
end

function module:Attunement(immunity, vulnerability)
    if self.db.profile.attunement then
        local barKey = "Attunement"
        
        if self:BarStatus(barKey) then
            self:RemoveBar(barKey)
        end
        
        local barText = string.format(L["bar_attunement"], immunity, vulnerability)
        self:Bar(barText, 30, icon.attunement, true, "White")
    else
        self:RemoveBar("Attunement")
    end
end