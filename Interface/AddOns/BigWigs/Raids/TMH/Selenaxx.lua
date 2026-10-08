local module, L = BigWigs:ModuleDeclaration("Selenaxx Foulheart", "Timbermaw Hold")

-- module variables
module.revision = 30138
module.enabletrigger = module.translatedName
module.toggleoptions = {"Doom", "Corruption", "rainoffire", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

-- module defaults
module.defaultDB = {
	Doom = true,
	Corruption = true,
	rainoffire = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "Selenaxx",

		Doom_cmd = "Doom",
		Doom_name = "Satyr Defilement Alert",
        Doom_desc = "Alert for Satyr Defilement stacks (Shadow Vulnerability)",

        Corruption_cmd = "Corruption",
        Corruption_name = "Corruption Alert",
        Corruption_desc = "Alert when Corruption appears",

		rainoffire_cmd = "rainoffire",
		rainoffire_name = "Rain of Destruction zone",
		rainoffire_desc = "Personal warning when you stand in Rain of Destruction",

		trigger_engage = "The master's plan shall not be interrupted!",

		trigger_rainoffire = "You are afflicted by Rain of Destruction",
		trigger_rainoffireTick = "You suffer .+ Fire damage from Selenaxx Foulheart's Rain of Destruction",
		warn_rainoffire = "MOVE",
		trigger_rainoffireFade = "Rain of Destruction fades from you.",
		msg_Hp1 = "当前血量<85%-准备换T（80%触发机制）",
		msg_Hp2 = "当前血量<65%-准备换T（60%触发机制）",
		msg_Hp3 = "当前血量<45%-准备换T（40%触发机制）",
		msg_Hp4 = "当前血量<25%-准备换T（20%触发机制）",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "Selenaxx",

		rainoffire_cmd = "rainoffire",
		rainoffire_name = "毁灭之雨区域",
		rainoffire_desc = "当你站在毁灭之雨中时的个人警报",

		Doom_cmd = "Doom",
        Doom_name = "萨特污秽警报",
        Doom_desc = "萨特污秽层数警告（暗影易伤）",

        Corruption_cmd = "Corruption",
        Corruption_name = "腐蚀术警报",
        Corruption_desc = "腐蚀术出现时进行警告",

		trigger_engage = "主人的计划，绝不容许被打断",

		trigger_rainoffire = "你受到了毁灭之雨效果的影响",
		trigger_rainoffireTick = "塞雷纳克斯·腐心的毁灭之雨使你受到",
		warn_rainoffire = "快离开",
		trigger_rainoffireFade = "毁灭之雨效果从你身上消失了",
		msg_Hp1 = "首领血量<85%-准备换T（80%触发机制）",
		msg_Hp2 = "首领血量<65%-准备换T（60%触发机制）",
		msg_Hp3 = "首领血量<45%-准备换T（40%触发机制）",
		msg_Hp4 = "首领血量<25%-准备换T（20%触发机制）",
	}
end)

-- timer and icon variables
local timer = {
	rainoffire = 10,
}

local icon = {
	rainoffire = "Spell_Shadow_RainOfFire",
}

local syncName = {
}

local guid = {
	selenaxx = "0xF13000F5DC279589",
}

local spellId = {
}

module:RegisterYellEngage(L["trigger_engage"])

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF", "FadesEvent")
	self:Message("友情提示：佩戴勇士印记/恶魔套装/DPS远离水晶", "Important", false, nil, false)
end

function module:OnSetup()
	self.hp85 = nil
	self.hp65 = nil
	self.hp45 = nil
	self.hp25 = nil
end

function module:OnEngage()
    self.hp85 = nil
    self.hp65 = nil
    self.hp45 = nil
    self.hp25 = nil
    self:ScheduleRepeatingEvent("CheckBossHealth", self.CheckBossHealth, 0.5, self)
end

function module:OnDisengage()
    if self:IsEventScheduled("CheckBossHealth") then
        self:CancelScheduledEvent("CheckBossHealth")
    end
    self.hp85 = nil
    self.hp65 = nil
    self.hp45 = nil
    self.hp25 = nil
end
function module:AfflictionEvent(msg)
	if self.db.profile.rainoffire then
		if string.find(msg, L["trigger_rainoffire"]) then
			self:Sound("Info")
			self:WarningSign(icon.rainoffire, timer.rainoffire, false, L["warn_rainoffire"])
			return
		elseif string.find(msg, L["trigger_rainoffireTick"]) then
			self:Sound("Info")
			return
		end
	end
end

function module:FadesEvent(msg)
	if self.db.profile.rainoffire and tring.find(msg, L["trigger_rainoffireFade"]) then
		self:RemoveWarningSign(icon.rainoffire)
		self:Sound("Long")
	end
end

function module:CheckBossHealth()
    if UnitExists(guid.selenaxx) then
        local percent = UnitHealth(guid.selenaxx) / UnitHealthMax(guid.selenaxx) * 100

        if percent <= 85 and not self.hp85 then
            self.hp85 = true
            self:Message(L["msg_Hp1"], "Important", nil, "Alarm")
        end

        if percent <= 65 and not self.hp65 then
            self.hp65 = true
            self:Message(L["msg_Hp2"], "Important", nil, "Alarm")
        end

        if percent <= 45 and not self.hp45 then
            self.hp45 = true
            self:Message(L["msg_Hp3"], "Important", nil, "Alarm")
        end

        if percent <= 25 and not self.hp25 then
            self.hp25 = true
            self:Message(L["msg_Hp4"], "Important", nil, "Alarm")
            self:CancelScheduledEvent("CheckBossHealth")
        end
    end
end
