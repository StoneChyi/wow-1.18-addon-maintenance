local module, L = BigWigs:ModuleDeclaration("Selenaxx Foulheart", "Timbermaw Hold")

-- module variables
module.revision = 30138
module.enabletrigger = module.translatedName
module.toggleoptions = {"Doom", "Corruption", "rainoffire", -1, "fear", "adds", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
	AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}

-- module defaults
module.defaultDB = {
	Doom = true,
	Corruption = true,
	rainoffire = true,
	fear = true,
	adds = true,
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

		fear_cmd = "fear",
		fear_name = "Fear alert",
		fear_desc = "Warn when someone is afflicted by Fear",

		adds_cmd = "adds",
		adds_name = "Adds spawn alert",
		adds_desc = "Warn raid to switch to the summoned adds (Foulheart Warlock) first",

		trigger_fearYou = "^You are afflicted by Fear",
		trigger_fearOther = "(.+) is afflicted by Fear",
		msg_fearSelf = "You are Feared!",
		msg_fearOther = "%s is Feared - tremor totem / WoTF!",

		trigger_engage = "The master's plan shall not be interrupted!",

		trigger_adds = "Foulheart Warlock",
		msg_adds = "Adds summoned - switch and kill the Foulheart Warlock first!",

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

		fear_cmd = "fear",
		fear_name = "恐惧术警报",
		fear_desc = "当有人中了恐惧术时发出警报，注意解控",

		adds_cmd = "adds",
		adds_name = "召唤小怪警报",
		adds_desc = "BOSS召唤小怪时提醒转火（优先击杀腐心术士）——待实测校准",

		Doom_cmd = "Doom",
        Doom_name = "萨特污秽警报",
        Doom_desc = "萨特污秽层数警告（暗影易伤）",

        Corruption_cmd = "Corruption",
        Corruption_name = "腐蚀术警报",
        Corruption_desc = "腐蚀术出现时进行警告",

		trigger_engage = "主人的计划，绝不容许被打断",

		trigger_adds = "腐心术士",
		msg_adds = "转火小怪——优先击杀腐心术士！",

		trigger_rainoffire = "^你受到了毁灭之雨效果的影响",
		trigger_rainoffireTick = "塞雷纳克斯·腐心的毁灭之雨使你受到",
		warn_rainoffire = "快离开",
		trigger_rainoffireFade = "毁灭之雨效果从你身上消失了",
		trigger_fearYou = "^你受到了恐惧术效果的影响",
		trigger_fearOther = "(.+)受到了恐惧术效果的影响",
		msg_fearSelf = "你被恐惧了！",
		msg_fearOther = "%s 中了恐惧术——注意解控（战栗/亡灵意志）！",
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
	fear = "THSelenaxxFear" .. module.revision,
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
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")

	-- 服内自定义 boss emote 的通道不固定（实测 RAID_BOSS_EMOTE / MONSTER_EMOTE 都出现过）
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "EmoteEvent")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "EmoteEvent")

	self:ThrottleSync(0, syncName.fear)
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
			self:Sound("voiceOut")
			self:WarningSign(icon.rainoffire, timer.rainoffire, false, L["warn_rainoffire"])
			return
		elseif string.find(msg, L["trigger_rainoffireTick"]) then
			self:Sound("voiceOut")
			return
		end
	end

	-- 恐惧术：自身 trigger 必须 ^ 锚定（「王你受到了…」子串误命中坑），
	-- 他人捕获到「你」时归一为本地玩家名（禁止字面量广播）
	if self.db.profile.fear and string.find(msg, L["trigger_fearYou"]) then
		self:Sync(syncName.fear .. " " .. UnitName("player"))
		return
	end
	local _, _, p = string.find(msg, L["trigger_fearOther"])
	if p then
		if p == "你" then p = UnitName("player") end
		self:Sync(syncName.fear .. " " .. p)
		return
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.fear and rest and self.db.profile.fear then
		self:Sound("voiceFear")
		if rest == UnitName("player") then
			self:Message(L["msg_fearSelf"], "Personal", true)
		else
			self:Message(string.format(L["msg_fearOther"], rest), "Attention")
		end
	end
end

function module:EmoteEvent(msg)
	-- 召唤小怪（RCA 标注待实测校准，独立开关可关）
	if self.db.profile.adds and string.find(msg, L["trigger_adds"]) then
		self:Message(L["msg_adds"], "Urgent", true, "voiceSwitch")
	end
end

function module:FadesEvent(msg)
	if self.db.profile.rainoffire and string.find(msg, L["trigger_rainoffireFade"]) then
		self:RemoveWarningSign(icon.rainoffire)
		self:Sound("Long")
	end
end

-- 硬编码 GUID 是本次生成的，换场次/重开会失效；GUID 取不到时按 BOSS 名扫目标做回退，
-- 保证 85/65/45/25 的换 T 提醒不会因为取不到单位而整体静默（参考 Kronn.lua PollHp 的扫描写法）
function module:GetBossUnit()
    if UnitExists(guid.selenaxx) then return guid.selenaxx end

    local bossName = module.enabletrigger
    if UnitName("target") == bossName then return "target" end

    local num = GetNumRaidMembers()
    local i
    for i = 1, num do
        local unit = "raid" .. i .. "target"
        if UnitName(unit) == bossName then return unit end
    end
    return nil
end

function module:CheckBossHealth()
    local unit = self:GetBossUnit()
    if unit then
        local maxHealth = UnitHealthMax(unit)
        if not maxHealth or maxHealth == 0 then return end
        local percent = UnitHealth(unit) / maxHealth * 100

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
