local module, L = BigWigs:ModuleDeclaration("Twin Golems", "Molten Core")

-- module variables
module.revision = 30000
local Smoldaris = AceLibrary("Babble-Boss-2.2")["Smoldaris"]
local Basalthar = AceLibrary("Babble-Boss-2.2")["Basalthar"]
local boss = AceLibrary("Babble-Boss-2.2")["Twin Golems"]
module.enabletrigger = {Smoldaris, Basalthar}
module.toggleoptions = { "bulwark", "bosskill" }
module.zonename = {
	AceLibrary("AceLocale-2.2"):new("BigWigs")["Molten Core"],
	AceLibrary("Babble-Zone-2.2")["Molten Core"],
}

-- module defaults
module.defaultDB = {
	bulwark = true,
}

-- localization
L:RegisterTranslations("enUS", function()
	return {
		cmd = "TwinGolems",

		bulwark_cmd = "bulwark",
		bulwark_name = "Molten Bulwark Alert",
		bulwark_desc = "Timer bar and target switch alert for Molten Bulwark (-95% damage taken, fire thorns)",

		trigger_bulwarkGain = "(.+) gains Molten Bulwark",
		trigger_bulwarkFade = "Molten Bulwark fades from (.+)%.",
		msg_switch = "SWITCH to %s",
		bar_bulwark = "%s Bulwark",

		trigger_victory = "Smoldaris dies.",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "TwinGolems",

		bulwark_cmd = "bulwark",
		bulwark_name = "熔火壁垒警报",
		bulwark_desc = "显示熔火壁垒计时条和目标切换警报（-95%减伤，火焰荆棘效果）",

		trigger_bulwarkGain = "(.+)获得了熔火壁垒的效果",
		trigger_bulwarkFade = "熔火壁垒效果从(.+)身上消失",
		msg_switch = "切换到攻击%s",
		bar_bulwark = "%s的熔火壁垒",
		
		trigger_victory = "斯摩达利斯死亡了",
	}
end)

-- timer and icon variables
local timer = {
	bulwark = 15,
}

local icon = {
	bulwark = "ability_mage_moltenarmor",
}

local color = {
	bulwark = "Red",
}

local syncName = {
	bulwarkGain = "MCTwinGolemsBulwarkGain" .. module.revision,
	bulwarkFade = "MCTwinGolemsBulwarkFade" .. module.revision,
}

function module:OnEnable()
	self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
	self:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_OTHER")

	self:ThrottleSync(4, syncName.bulwarkGain)
	self:ThrottleSync(4, syncName.bulwarkFade)
end

function module:OnSetup()
	self.started = nil
end

function module:OnEngage()
end

function module:OnDisengage()
end

function module:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
	-- Bulwark gain
	local _, _, mob = string.find(msg, L["trigger_bulwarkGain"])
	if mob then
		self:Sync(syncName.bulwarkGain .. " " .. mob)
	end
end

function module:CHAT_MSG_SPELL_AURA_GONE_OTHER(msg)
	-- Bulwark fade
	local _, _, mob = string.find(msg, L["trigger_bulwarkFade"])
	if mob then
		self:Sync(syncName.bulwarkFade .. " " .. mob)
	end
end

function module:BigWigs_RecvSync(sync, rest, nick)
	if sync == syncName.bulwarkGain and rest then
		self:BulwarkGain(rest)
	elseif sync == syncName.bulwarkFade and rest then
		self:BulwarkFade(rest)
	end
end

function module:BulwarkGain(mob)
	-- display timer bar with mob name
	if self.db.profile.bulwark then
		self:Bar(string.format(L["bar_bulwark"], mob), timer.bulwark, icon.bulwark, true, color.bulwark)
	end
end

function module:BulwarkFade(mob)
	-- remove timer bar in case it's still up
	self:RemoveBar(string.format(L["bar_bulwark"], mob))
	
	-- tell people to switch targets because Bulwark will go on the other golem in 2-4 seconds
	if self.db.profile.bulwark then
		self:Message(string.format(L["msg_switch"], mob), "Attention", true, "Alert")
	end
end

function module:OnEnemyDeath(msg)
	if string.find(msg, L["trigger_victory"]) then
		self:SendBossDeathSync()
	end
end