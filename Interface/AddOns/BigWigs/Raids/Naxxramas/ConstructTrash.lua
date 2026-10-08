local module, L = BigWigs:ModuleDeclaration("Patchwork Golem", "Naxxramas")
local bbPatchworkGoleme = AceLibrary("Babble-Boss-2.2")["Patchwork Golem"]

module.revision = 20002
module.trashMod = true
module.enabletrigger = { "Patchwork Golem", "缝补傀儡" }
module.toggleoptions = { "warstomp" }

L:RegisterTranslations("enUS", function()
	return {
		cmd = "ConstructTrash",

		warstomp_cmd = "warstomp",
		warstomp_name = "War Stomp",
		warstomp_desc = "Displays a cooldown and an icon for the initial synchronised warstomp.",

		bar_timeToStomp = "Warstomp",
	}
end)

L:RegisterTranslations("zhCN", function()
	return {
		cmd = "ConstructTrash",

		warstomp_cmd = "warstomp",
		warstomp_name = "战争践踏",
		warstomp_desc = "显示首次同步战争践踏的冷却时间和图标.",

		bar_timeToStomp = "战争践踏",
	}
end)

local timer = {
	warstomp = 8,
}

local icon = {
	warstomp = "ability_bullrush"
}

local color = {
	warstomp = "Red",
}

local deathCount = 0
local stompNumber = 1
local lastStomp = 0

function module:OnEnable()
end

function module:OnSetup()
	-- self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
	-- deathCount = 0
	-- stompNumber = 1
	-- lastStomp = 0
end

function module:OnEngage()
	if self.db.profile.warstomp then
		self:Bar(L["bar_timeToStomp"], timer.warstomp, icon.warstomp, true, color.warstomp)
	end
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
	-- if msg == string.format(UNITDIESOTHER, "Patchwork Golem") then
	-- 	deathCount = deathCount + 1
	-- 	if deathCount == 4 then
	-- 		self:SendBossDeathSync()
	-- 	end
	-- end
end

function module:Event(msg)
end