local module, L = BigWigs:ModuleDeclaration("Ezzel Darkbrewer", "Blackwing Lair")

-- module variables
module.revision = 30138
module.enabletrigger = module.translatedName
module.toggleoptions = { "charge", "chargemark", "precharge", "chemicalRage", "acid", "transmute", "tongues", "bosskill" }

-- module defaults
module.defaultDB = {
	charge = true,
	chargemark = true,
	precharge = true,
	chemicalRage = true,
	acid = true,
	transmute = true,
	tongues = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "EzzelDarkbrewer",

		charge_cmd = "charge",
		charge_name = "Charge Alert",
		charge_desc = "Alerts about incoming Charges",

		chargemark_cmd = "chargemark",
		chargemark_name = "Charge Mark",
		chargemark_desc = "Mark Charge victims with Triangle",

		precharge_cmd = "precharge",
		precharge_name = "Charge Soon Alert",
		precharge_desc = "Warns a few seconds before an upcoming Charge",

		chemicalRage_cmd = "chemicalRage",
		chemicalRage_name = "Chemical Rage",
		chemicalRage_desc = "Shows a bar while the boss has 80% damage reduction",

		acid_cmd = "acid",
		acid_name = "Acid Alert",
		acid_desc = "Warns when you are standing in Acid",

		transmute_cmd = "transmute",
		transmute_name = "Transmute to Gold Alert",
		transmute_desc = "Warns when the boss begins to cast Transmute to Gold (wipe mechanic)",

		tongues_cmd = "tongues",
		tongues_name = "Curse of Tongues Alert",
		tongues_desc = "Warns 5% before the boss begins to cast Transmute if Curse of Tongues is not on the boss",

		trigger_charge = "Raka begins charging (.+)!",
		bar_charge = "Charge on %s",
		say_charge = "Charge On Me!",
		warn_charge = "HIDE",
		msg_preCharge = "Charge soon!",

		trigger_concussion = "Ezzel Darkbrewer .+ Concussion%.",
		msg_chemicalRage = "Chemical Rage - 80% damage reduction until Ezzel hits a pillar",
		bar_chemicalRage = "Damage Reduction active",

		trigger_acid = "You are affliced by Acid Bomb",
		trigger_acidTick = "You suffer (.+) damage from Ezzel Darkbrewer's Acid Bomb",
		warn_acid = "ACID - MOVE",

		trigger_transmute = "Ezzel Darkbrewer begins to cast Transmute to Gold",
		bar_transmute = "Kill Boss",
		warn_tongues = "CoT missing!",
		trigger_chemicalRageFade = "Chemical Rage fades from (.+)",
		trigger_chemicalRageGain = "(.+) gains Chemical Rage",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "EzzelDarkbrewer",

		charge_cmd = "charge",
		charge_name = "冲锋警报",
		charge_desc = "提示即将到来的冲锋",

		chargemark_cmd = "chargemark",
		chargemark_name = "冲锋标记",
		chargemark_desc = "为冲锋目标标记三角图标",

		precharge_cmd = "precharge",
		precharge_name = "冲锋预警",
		precharge_desc = "在冲锋到来前几秒发出警告",

		chemicalRage_cmd = "chemicalRage",
		chemicalRage_name = "化学狂怒",
		chemicalRage_desc = "首领拥有80%减伤期间显示计时条",

		acid_cmd = "acid",
		acid_name = "酸液警报",
		acid_desc = "当你站在酸液中时发出警告",

		transmute_cmd = "transmute",
		transmute_name = "点金术警报",
		transmute_desc = "当首领开始施放金升（灭团机制）时发出警告",

		tongues_cmd = "tongues",
		tongues_name = "语言诅咒警报",
		tongues_desc = "在首领开始施放金升前5%血量时，若未上语言诅咒则发出警告",

		trigger_charge = "托恩拉卡开始向(.+)冲锋",
		bar_charge = "冲锋：%s",
		say_charge = "冲锋指向我！",
		warn_charge = "隐藏",
		msg_preCharge = "冲锋即将到来！",

		trigger_concussion = "伊泽尔·黑酿获得了地基震动的效果",
		msg_chemicalRage = "伊泽尔·黑酿撞到柱子前受到伤害降低80%",
		bar_chemicalRage = "减伤生效中",

		trigger_acid = "你受到了酸液炸弹效果的影响",
		trigger_acidTick = "伊泽尔·黑酿的酸液炸弹使你受到了(.+)点自然伤害",
		warn_acid = "酸液-立刻移动",

		trigger_transmute = "伊泽尔·黑酿开始施放金升",
		bar_transmute = "全力集火BOSS",
		warn_tongues = "缺少语言诅咒！",
		trigger_chemicalRageFade = "化学狂怒效果从伊泽尔·黑酿身上消失",
		trigger_chemicalRageGain = "伊泽尔·黑酿获得了化学狂怒的效果",
	}
end)


-- timer and icon variables
local timer = {
	charge = 8,
	transmute = 8,
}

local icon = {
	charge = "ABILITY_MOUNT_MOUNTAINRAM",
	chemicalRage = "Spell_Nature_AncestralGuardian",
	acid = "ABILITY_CREATURE_POISON_06",
	transmute = "SPELL_HOLY_HARMUNDEADAURA",
	tongues = "Spell_Shadow_CurseOfTounges",
}

local syncName = {
	charge = "EzzelCharge" .. module.revision,
	concussion = "EzzelConcussion" .. module.revision,
	transmute = "EzzelTransmute" .. module.revision,
}

local spellId = {
	tongues = 11719,
}

local guid = {
	ezzel = "0xF13000FE7C279933",
}

local nextHealthThreshold = 80

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "CastEvent")

	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "EnemyDebuffEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "EnemyDebuffEvent")
	
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")

	self:ThrottleSync(3, syncName.charge)
	self:ThrottleSync(3, syncName.concussion)
	self:ThrottleSync(3, syncName.transmute)
end

function module:OnSetup()
end

function module:OnEngage()
	if self.core:IsModuleActive("Blackwing Alchemist", "Blackwing Lair") then
		self.core:DisableModule("Blackwing Alchemist", "Blackwing Lair")
	end
	self.chemicalRageActive = false

	nextHealthThreshold = 80
	-- Start health monitoring
	self:ScheduleRepeatingEvent("CheckBossHealth", self.CheckBossHealth, 0.5, self)
end

function module:OnDisengage()
end

function module:AfflictionEvent(msg)
	if self.db.profile.acid and (string.find(msg, L["trigger_acid"]) or string.find(msg, L["trigger_acidTick"]) )then
		self:Sound("Info")
		self:WarningSign(icon.acid, 1, false, L["warn_acid"])
	end
end

function module:CastEvent(msg)
	if string.find(msg, L["trigger_transmute"]) then
		self:Sync(syncName.transmute)
	end
end

function module:EnemyDebuffEvent(msg)
    -- 获得化学狂怒 → 显示计时条
    if string.find(msg, L["trigger_chemicalRageGain"]) then
        if self.db.profile.chemicalRage and not self.chemicalRageActive then
            self.chemicalRageActive = true
            self:Bar(L["bar_chemicalRage"], nil, icon.chemicalRage, true, "Cyan")
            self:Message(L["msg_chemicalRage"], "Core", nil, false)
        end
    end  
    -- 化学狂怒消失 → 移除计时条
    if string.find(msg, L["trigger_chemicalRageFade"]) then
        self:Sync(syncName.concussion)
    end
end

function module:CHAT_MSG_RAID_BOSS_EMOTE(msg)
	local _, _, player = string.find(msg, L["trigger_charge"])
	if player then
		self:Sync(syncName.charge .. " " .. player)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.transmute then
		self:TransmuteToGold()
	elseif sync == syncName.concussion then
		self:RemoveBar(L["bar_chemicalRage"])
	elseif sync == syncName.charge and rest then
		self:Charge(rest)
	end
end

function module:TransmuteToGold()
	if not self.db.profile.transmute then return end

	self:Bar(L["bar_transmute"], timer.transmute * BigWigs:GetCastTimeCoefficient(guid.ezzel), icon.transmute)
	self:Sound("Beware")
end

function module:Charge(player)
	if self.db.profile.charge then
		self:Bar(string.format(L["bar_charge"],player), timer.charge * BigWigs:GetCastTimeCoefficient(guid.ezzel), icon.charge)
		if player == UnitName("player") then
			self:WarningSign(icon.charge, 4, true, L["warn_charge"])
			self:Sound("RunAway")
			SendChatMessage(L["say_charge"], "SAY")
		else
			self:Sound("Alarm")
		end
	end

	if self.db.profile.chargemark then
		self:SetRaidTargetForPlayer(player, "Triangle")
		self:ScheduleEvent("RemoveChargeMark", self.RestoreInitialRaidTargetForPlayer, timer.charge * BigWigs:GetCastTimeCoefficient(guid.ezzel), self, player)
	end

end

function module:CheckBossHealth(testValue)
	local percent = BigWigs:GetHealthPercent(guid.ezzel) or testValue or 100
	if percent < 15 then
		if self.db.profile.tongues and not BigWigs:AuraIsPresent(guid.ezzel, spellId.tongues) then
			self:WarningSign(icon.tongues, 1, false, L["warn_tongues"])
			self:Sound("Alert")
		end
		self:CancelScheduledEvent("CheckBossHealth")
	end
	if percent < nextHealthThreshold then
		if self.db.profile.precharge then
			self:Message(L["msg_preCharge"], "Attention")
		end
		nextHealthThreshold = nextHealthThreshold - 25
	end
end