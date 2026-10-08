-- No PerfBoost v2, no need for settings
local has_perf_boost = pcall(GetCVar, "PB_Enabled")
if not has_perf_boost then
	DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost|cffffaaaa 未找到，隐藏设置选项。")
	return
end

PerfBoost = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "AceDebug-2.0", "AceModuleCore-2.0", "AceConsole-2.0", "AceDB-2.0", "AceHook-2.1")
PerfBoost:RegisterDB("PerfBoostSettingsDB")
PerfBoost:RegisterDefaults("profile", {
	per_character_settings = false,
	previous_player_render_dist = nil,
	previous_player_render_dist_in_combat = nil,
	previous_doodad_render_dist = nil,
})
PerfBoost.frame = CreateFrame("Frame", "PerfBoost", UIParent)

BINDING_HEADER_PERFBOOST = "PerfBoost";
BINDING_NAME_PERFBOOSTENABLE = "性能提升功能已开启/关闭";
BINDING_NAME_PBHIDEALLPLAYERS = "玩家渲染距离为0 (覆盖其他设置)";
BINDING_NAME_PBTOGGLEPLAYERRENDERIST = "玩家渲染距离为0 (遵循其他设置并隐藏所有玩家)";
BINDING_NAME_PBSHOWALLPLAYERS = "显示所有玩家 (覆盖其他设置)";
BINDING_NAME_PBCYCLEPLAYERVISIBILITY = "循环切换玩家可见性：显示所有 -> 隐藏所有 -> 正常";
BINDING_NAME_PBCYCLEDOODADVISIBILITY = "循环切换装饰物可见性：当前 -> 隐藏 -> 始终渲染";

-- used when turning on per character settings
function PerfBoost:SavePerCharacterSettings()
	local function saveNestedSettings(args)
		for settingKey, settingData in pairs(args) do
			if string.find(settingKey, "PB_") == 1 and settingData.get and settingData.set then
				settingData.set(settingData.get()) -- trigger the set function for each setting with the current value
			elseif settingData.args then
				saveNestedSettings(settingData.args)
			end
		end
	end
	saveNestedSettings(PerfBoost.cmdtable.args)
end

function PerfBoost:ApplySavedSettings()
	local function applyNestedSettings(args)
		for settingKey, settingData in pairs(args) do
			if string.find(settingKey, "PB_") == 1 and settingData.set then
				if PerfBoost.db.profile[settingKey] ~= nil then
					settingData.set(PerfBoost.db.profile[settingKey])
				end
			elseif settingData.args then
				applyNestedSettings(settingData.args)
			end
		end
	end
	applyNestedSettings(PerfBoost.cmdtable.args)
end

function PerfBoost:OnEnable()
	-- if per character settings are enabled, apply them
	if PerfBoost.db.profile.per_character_settings then
		PerfBoost:ApplySavedSettings()
	end
end

PerfBoost.cmdtable = {
	type = "group",
	handler = PerfBoost,
	args = {
		per_character_settings = {
			type = "toggle",
			name = "启用角色独立设置",
			desc = "是否为所有 PB_ 设置使用角色独立设置。这将导致角色 PerfBoostSettings.lua 中的保存设置覆盖 Config.wtf 中的全局设置。",
			order = 1,
			get = function()
				return PerfBoost.db.profile.per_character_settings
			end,
			set = function(v)
				if v ~= PerfBoost.db.profile.per_character_settings then
					PerfBoost.db.profile.per_character_settings = v
					if v == true then
						PerfBoost:SavePerCharacterSettings()
					end
				end
			end,
		},
		PB_Enabled = {
			type = "toggle",
			name = "启用性能提升",
			desc = "启用/禁用所有性能提升功能",
			order = 5,
			get = function()
				return GetCVar("PB_Enabled") == "1"
			end,
			set = function(v)
				PerfBoost.db.profile.PB_Enabled = v
				if v == true then
					SetCVar("PB_Enabled", "1")
				else
					SetCVar("PB_Enabled", "0")
				end
			end,
		},

		PB_ShowAllPlayers = {
			type = "toggle",
			name = "显示所有玩家 (覆盖其他设置)",
			desc = "无视距离和其他渲染设置，显示所有玩家。优先级高于隐藏所有玩家。",
			order = 6,
			get = function()
				return GetCVar("PB_ShowAllPlayers") == "1"
			end,
			set = function(v)
				PerfBoost.db.profile.PB_ShowAllPlayers = v
				if v == true then
					SetCVar("PB_ShowAllPlayers", "1")
				else
					SetCVar("PB_ShowAllPlayers", "0")
				end
			end,
		},

		PB_HideAllPlayers = {
			type = "toggle",
			name = "隐藏所有玩家 (覆盖其他设置)",
			desc = "忽略其他渲染设置，隐藏所有玩家",
			order = 7,
			get = function()
				return GetCVar("PB_HideAllPlayers") == "1"
			end,
			set = function(v)
				PerfBoost.db.profile.PB_HideAllPlayers = v
				if v == true then
					SetCVar("PB_HideAllPlayers", "1")
				else
					SetCVar("PB_HideAllPlayers", "0")
				end
			end,
		},

		spacera = {
			type = "header",
			name = " ",
			order = 10,
		},

		rendering = {
			type = "group",
			name = "渲染设置",
			desc = "配置所有渲染和可见性选项",
			order = 15,
			args = {
				PB_AlwaysRenderRaidMarks = {
					type = "toggle",
					name = "始终渲染团队标记",
					desc = "是否始终渲染团队标记",
					order = 1,
					get = function()
						return GetCVar("PB_AlwaysRenderRaidMarks") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_AlwaysRenderRaidMarks = v
						if v == true then
							SetCVar("PB_AlwaysRenderRaidMarks", "1")
						else
							SetCVar("PB_AlwaysRenderRaidMarks", "0")
						end
					end,
				},

				PB_AlwaysRenderPVP = {
					type = "toggle",
					name = "始终渲染 PVP 玩家",
					desc = "是否始终渲染标记为 PVP 的玩家",
					order = 2,
					get = function()
						return GetCVar("PB_AlwaysRenderPVP") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_AlwaysRenderPVP = v
						if v == true then
							SetCVar("PB_AlwaysRenderPVP", "1")
						else
							SetCVar("PB_AlwaysRenderPVP", "0")
						end
					end,
				},

				PB_AlwaysRenderPlayersWithAggro = {
					type = "toggle",
					name = "始终渲染获得仇恨的玩家",
					desc = "是否始终渲染从敌人那里获得仇恨的玩家",
					order = 3,
					get = function()
						return GetCVar("PB_AlwaysRenderPlayersWithAggro") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_AlwaysRenderPlayersWithAggro = v
						if v == true then
							SetCVar("PB_AlwaysRenderPlayersWithAggro", "1")
						else
							SetCVar("PB_AlwaysRenderPlayersWithAggro", "0")
						end
					end,
				},

				PB_AlwaysRenderPlayers = {
					type = "text",
					name = "始终渲染的玩家(按回车保存)",
					desc = "始终渲染的玩家名单 (英文","分隔)，忽略其他设置",
					usage = "名称1,名称2,名称3",
					order = 4,
					get = function()
						return GetCVar("PB_AlwaysRenderPlayers") or ""
					end,
					set = function(v)
						PerfBoost.db.profile.PB_AlwaysRenderPlayers = v
						SetCVar("PB_AlwaysRenderPlayers", v)
					end,
				},

				PB_NeverRenderPlayers = {
					type = "text",
					name = "从不渲染的玩家(按回车保存)",
					desc = "从不渲染的玩家名单(英文","分隔)，忽略其他设置",
					usage = "名称1,名称2,名称3",
					order = 5,
					get = function()
						return GetCVar("PB_NeverRenderPlayers") or ""
					end,
					set = function(v)
						PerfBoost.db.profile.PB_NeverRenderPlayers = v
						SetCVar("PB_NeverRenderPlayers", v)
					end,
				},

				spacer_player = {
					type = "header",
					name = "玩家距离",
					order = 10,
				},

				PB_PlayerRenderDist = {
					type = "range",
					name = "默认玩家渲染距离",
					desc = "非战斗状态下渲染玩家的最大距离",
					order = 11,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_PlayerRenderDist")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_PlayerRenderDist = v
						SetCVar("PB_PlayerRenderDist", tostring(v))
					end,
				},
				PB_PlayerRenderDistInCombat = {
					type = "range",
					name = "战斗中玩家渲染距离",
					desc = "战斗中渲染玩家的最大距离",
					order = 12,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_PlayerRenderDistInCombat")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_PlayerRenderDistInCombat = v
						SetCVar("PB_PlayerRenderDistInCombat", tostring(v))
					end,
				},
				PB_PlayerRenderDistInCities = {
					type = "range",
					name = "城市中玩家渲染距离",
					desc = "城市中渲染玩家的最大距离",
					order = 13,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_PlayerRenderDistInCities")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_PlayerRenderDistInCities = v
						SetCVar("PB_PlayerRenderDistInCities", tostring(v))
					end,
				},

				spacer_trash = {
					type = "header",
					name = "垃圾单位",
					order = 20,
				},

				PB_TrashUnitRenderDist = {
					type = "range",
					name = "默认非BOSS(等级 < 63)渲染距离",
					desc = "非战斗中渲染非BOSS的最大距离",
					order = 21,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_TrashUnitRenderDist")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_TrashUnitRenderDist = v
						SetCVar("PB_TrashUnitRenderDist", tostring(v))
					end,
				},
				PB_TrashUnitRenderDistInCombat = {
					type = "range",
					name = "战斗中非BOSS(等级 < 63)渲染距离",
					desc = "战斗中渲染非BOSS的最大距离",
					order = 22,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_TrashUnitRenderDistInCombat")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_TrashUnitRenderDistInCombat = v
						SetCVar("PB_TrashUnitRenderDistInCombat", tostring(v))
					end,
				},

				spacer_pets = {
					type = "header",
					name = "宠物与召唤物",
					order = 30,
				},

				PB_PetRenderDist = {
					type = "range",
					name = "默认宠物渲染距离",
					desc = "非战斗中渲染宠物的最大距离。你的宠物始终显示。",
					order = 31,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_PetRenderDist")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_PetRenderDist = v
						SetCVar("PB_PetRenderDist", tostring(v))
					end,
				},
				PB_PetRenderDistInCombat = {
					type = "range",
					name = "战斗中宠物渲染距离",
					desc = "战斗中渲染宠物的最大距离。你的宠物始终显示。",
					order = 32,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_PetRenderDistInCombat")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_PetRenderDistInCombat = v
						SetCVar("PB_PetRenderDistInCombat", tostring(v))
					end,
				},

				PB_SummonRenderDist = {
					type = "range",
					name = "默认图腾/召唤物渲染距离",
					desc = "非战斗中渲染图腾/召唤物的最大距离。你的图腾/召唤物始终显示。",
					order = 33,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_SummonRenderDist")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_SummonRenderDist = v
						SetCVar("PB_SummonRenderDist", tostring(v))
					end,
				},
				PB_SummonRenderDistInCombat = {
					type = "range",
					name = "战斗中图腾/召唤物渲染距离",
					desc = "战斗中渲染图腾/召唤物的最大距离。你的图腾/召唤物始终显示。",
					order = 34,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_SummonRenderDistInCombat")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_SummonRenderDistInCombat = v
						SetCVar("PB_SummonRenderDistInCombat", tostring(v))
					end,
				},

				spacer_corpse = {
					type = "header",
					name = "其他对象",
					order = 40,
				},

				PB_CorpseRenderDist = {
					type = "range",
					name = "尸体渲染距离",
					desc = "渲染尸体的最大距离。不会隐藏BOSS及未拾取的任何尸体。",
					order = 41,
					min = -1,
					max = 100,
					step = 1,
					get = function()
						local val = GetCVar("PB_CorpseRenderDist")
						return val and tonumber(val) or 0
					end,
					set = function(v)
						PerfBoost.db.profile.PB_CorpseRenderDist = v
						SetCVar("PB_CorpseRenderDist", tostring(v))
					end,
				},

			},
		},

		spells = {
			type = "group",
			name = "法术视觉设置",
			desc = "配置法术视觉效果和过滤",
			order = 20,
			args = {
				PB_ShowPlayerSpellVisuals = {
					type = "toggle",
					name = "显示其他玩家的法术视觉效果",
					desc = "是否显示来自其他玩家的法术视觉效果。这包括施法、远程武器投射物、魔杖攻击等。",
					order = 1,
					get = function()
						return GetCVar("PB_ShowPlayerSpellVisuals") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_ShowPlayerSpellVisuals = v
						if v == true then
							SetCVar("PB_ShowPlayerSpellVisuals", "1")
						else
							SetCVar("PB_ShowPlayerSpellVisuals", "0")
						end
					end,
				},

				PB_ShowPlayerGroundEffects = {
					type = "toggle",
					name = "显示其他玩家的地面视觉效果",
					desc = "是否显示来自其他玩家的地面视觉效果",
					order = 2,
					get = function()
						return GetCVar("PB_ShowPlayerGroundEffects") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_ShowPlayerGroundEffects = v
						if v == true then
							SetCVar("PB_ShowPlayerGroundEffects", "1")
						else
							SetCVar("PB_ShowPlayerGroundEffects", "0")
						end
					end,
				},

				PB_ShowPlayerAuraVisuals = {
					type = "toggle",
					name = "显示其他玩家的光环视觉效果",
					desc = "是否显示来自其他玩家的光环视觉效果",
					order = 3,
					get = function()
						return GetCVar("PB_ShowPlayerAuraVisuals") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_ShowPlayerAuraVisuals = v
						if v == true then
							SetCVar("PB_ShowPlayerAuraVisuals", "1")
						else
							SetCVar("PB_ShowPlayerAuraVisuals", "0")
						end
					end,
				},

				PB_ShowUnitAuraVisuals = {
					type = "toggle",
					name = "显示其他单位的光环视觉效果",
					desc = "是否显示其他单位(NPC、怪物)的光环视觉效果",
					order = 4,
					get = function()
						return GetCVar("PB_ShowUnitAuraVisuals") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_ShowUnitAuraVisuals = v
						if v == true then
							SetCVar("PB_ShowUnitAuraVisuals", "1")
						else
							SetCVar("PB_ShowUnitAuraVisuals", "0")
						end
					end,
				},

				PB_HideSpellsForHiddenPlayers = {
					type = "toggle",
					name = "隐藏已隐藏玩家的法术视觉效果",
					desc = "隐藏因渲染距离或其他设置而隐藏的玩家的法术视觉效果",
					order = 5,
					get = function()
						return GetCVar("PB_HideSpellsForHiddenPlayers") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_HideSpellsForHiddenPlayers = v
						if v == true then
							SetCVar("PB_HideSpellsForHiddenPlayers", "1")
						else
							SetCVar("PB_HideSpellsForHiddenPlayers", "0")
						end
					end,
				},

				spacer_spells = {
					type = "header",
					order = 10,
				},

				PB_HiddenSpellIds = {
					type = "text",
					name = "始终隐藏的法术ID(按回车保存)",
					desc = "隐藏视觉效果的法术ID列表(英文","分隔)",
					usage = "1234,5678,9012",
					order = 11,
					get = function()
						return GetCVar("PB_HiddenSpellIds") or ""
					end,
					set = function(v)
						PerfBoost.db.profile.PB_HiddenSpellIds = v
						SetCVar("PB_HiddenSpellIds", v)
					end,
				},

				PB_AlwaysShownSpellIds = {
					type = "text",
					name = "始终显示的法术ID(按回车保存)",
					desc = "显示视觉效果的法术ID列表(英文","分隔)，覆盖其他设置",
					usage = "1234,5678 等",
					order = 12,
					get = function()
						return GetCVar("PB_AlwaysShownSpellIds") or ""
					end,
					set = function(v)
						PerfBoost.db.profile.PB_AlwaysShownSpellIds = v
						SetCVar("PB_AlwaysShownSpellIds", v)
					end,
				},

				PB_ApplyHiddenSpellIdsToMe = {
					type = "toggle",
					name = "对自身应用隐藏法术ID列表",
					desc = "是否将隐藏法术ID列表应用于你自己角色的法术",
					order = 13,
					get = function()
						return GetCVar("PB_ApplyHiddenSpellIdsToMe") == "1"
					end,
					set = function(v)
						PerfBoost.db.profile.PB_ApplyHiddenSpellIdsToMe = v
						if v == true then
							SetCVar("PB_ApplyHiddenSpellIdsToMe", "1")
						else
							SetCVar("PB_ApplyHiddenSpellIdsToMe", "0")
						end
					end,
				},

				spacer_debug = {
					type = "header",
					name = " ",
					order = 20,
				},
			},
		},

	},
}

local deuce = PerfBoost:NewModule("PerfBoost Options Menu")
deuce.hasFuBar = IsAddOnLoaded("FuBar") and FuBar
deuce.consoleCmd = not deuce.hasFuBar

PerfBoostOptions = AceLibrary("AceAddon-2.0"):new("AceDB-2.0", "FuBarPlugin-2.0")
PerfBoostOptions.name = "FuBar - PerfBoost"
PerfBoostOptions.hasIcon = "Interface\\Icons\\Spell_Nature_Strength"
PerfBoostOptions.defaultMinimapPosition = 180
PerfBoostOptions.independentProfile = true
PerfBoostOptions.hideWithoutStandby = false

PerfBoostOptions.OnMenuRequest = PerfBoost.cmdtable
local args = AceLibrary("FuBarPlugin-2.0"):GetAceOptionsDataTable(PerfBoostOptions)
for k, v in pairs(args) do
	if PerfBoostOptions.OnMenuRequest.args[k] == nil then
		PerfBoostOptions.OnMenuRequest.args[k] = v
	end
end

SLASH_PBENABLE1, SLASH_PBENABLE2 = '/pbenable', '/perfboostenable'
function SlashCmdList.PBENABLE(msg, editbox)
	local v = not (GetCVar("PB_Enabled") == "1")
	PerfBoost.db.profile.PB_Enabled = v
	if v == true then
		SetCVar("PB_Enabled", "1")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已启用")
	else
		SetCVar("PB_Enabled", "0")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已禁用")
	end
end

SLASH_PBALWAYSRENDER1, SLASH_PBALWAYSRENDER2 = '/pbalwaysrender', '/pbar'
function SlashCmdList.PBALWAYSRENDER(msg, editbox)
	local target = UnitName("target")
	if not target then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 未选择目标")
		return
	end
	
	local current = GetCVar("PB_AlwaysRenderPlayers") or ""
	local names = {}
	if current ~= "" then
		for name in string.gfind(current, "([^,]+)") do
			name = string.gsub(name, "^%s*(.-)%s*$", "%1")
			if name ~= "" then
				names[name] = true
			end
		end
	end
	
	if names[target] then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r " .. target .. " 已在始终渲染列表中")
		return
	end
	
	names[target] = true
	local newList = ""
	for name in pairs(names) do
		if newList == "" then
			newList = name
		else
			newList = newList .. "," .. name
		end
	end
	
	PerfBoost.db.profile.PB_AlwaysRenderPlayers = newList
	SetCVar("PB_AlwaysRenderPlayers", newList)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已将 " .. target .. " 添加到始终渲染列表")
end

SLASH_PBNEVERRENDER1, SLASH_PBNEVERRENDER2 = '/pbneverrender', '/pbnr'
function SlashCmdList.PBNEVERRENDER(msg, editbox)
	local target = UnitName("target")
	if not target then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 未选择目标")
		return
	end
	
	local current = GetCVar("PB_NeverRenderPlayers") or ""
	local names = {}
	if current ~= "" then
		for name in string.gfind(current, "([^,]+)") do
			name = string.gsub(name, "^%s*(.-)%s*$", "%1")
			if name ~= "" then
				names[name] = true
			end
		end
	end
	
	if names[target] then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r " .. target .. " 已在从不渲染列表中")
		return
	end
	
	names[target] = true
	local newList = ""
	for name in pairs(names) do
		if newList == "" then
			newList = name
		else
			newList = newList .. "," .. name
		end
	end
	
	PerfBoost.db.profile.PB_NeverRenderPlayers = newList
	SetCVar("PB_NeverRenderPlayers", newList)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已将 " .. target .. " 添加到从不渲染列表")
end

SLASH_PBALWAYSRENDERREMOVE1, SLASH_PBALWAYSRENDERREMOVE2 = '/pbalwaysrenderremove', '/pbarr'
function SlashCmdList.PBALWAYSRENDERREMOVE(msg, editbox)
	local target = UnitName("target")
	if not target then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 未选择目标")
		return
	end
	
	local current = GetCVar("PB_AlwaysRenderPlayers") or ""
	local names = {}
	if current ~= "" then
		for name in string.gfind(current, "([^,]+)") do
			name = string.gsub(name, "^%s*(.-)%s*$", "%1")
			if name ~= "" and name ~= target then
				names[name] = true
			end
		end
	end
	
	local newList = ""
	for name in pairs(names) do
		if newList == "" then
			newList = name
		else
			newList = newList .. "," .. name
		end
	end
	
	PerfBoost.db.profile.PB_AlwaysRenderPlayers = newList
	SetCVar("PB_AlwaysRenderPlayers", newList)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已将 " .. target .. " 从始终渲染列表中移除")
end

SLASH_PBNEVERRENDERREMOVE1, SLASH_PBNEVERRENDERREMOVE2 = '/pbneverrenderremove', '/pbnrr'
function SlashCmdList.PBNEVERRENDERREMOVE(msg, editbox)
	local target = UnitName("target")
	if not target then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 未选择目标")
		return
	end
	
	local current = GetCVar("PB_NeverRenderPlayers") or ""
	local names = {}
	if current ~= "" then
		for name in string.gfind(current, "([^,]+)") do
			name = string.gsub(name, "^%s*(.-)%s*$", "%1")
			if name ~= "" and name ~= target then
				names[name] = true
			end
		end
	end
	
	local newList = ""
	for name in pairs(names) do
		if newList == "" then
			newList = name
		else
			newList = newList .. "," .. name
		end
	end
	
	PerfBoost.db.profile.PB_NeverRenderPlayers = newList
	SetCVar("PB_NeverRenderPlayers", newList)
	DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已将 " .. target .. " 从不渲染列表中移除")
end

SLASH_PBALWAYSRENDERCLEAR1, SLASH_PBALWAYSRENDERCLEAR2 = '/pbalwaysrenderclear', '/pbarc'
function SlashCmdList.PBALWAYSRENDERCLEAR(msg, editbox)
	PerfBoost.db.profile.PB_AlwaysRenderPlayers = ""
	SetCVar("PB_AlwaysRenderPlayers", "")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已清空始终渲染列表")
end

SLASH_PBNEVERRENDERCLEAR1, SLASH_PBNEVERRENDERCLEAR2 = '/pbneverrenderclear', '/pbnrc'
function SlashCmdList.PBNEVERRENDERCLEAR(msg, editbox)
	PerfBoost.db.profile.PB_NeverRenderPlayers = ""
	SetCVar("PB_NeverRenderPlayers", "")
	DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 已清空从不渲染列表")
end

SLASH_PBHIDEALLPLAYERS1, SLASH_PBHIDEALLPLAYERS2 = '/pbhideallplayers', '/pbhap'
function SlashCmdList.PBHIDEALLPLAYERS(msg, editbox)
	local v = not (GetCVar("PB_HideAllPlayers") == "1")
	PerfBoost.db.profile.PB_HideAllPlayers = v
	if v == true then
		SetCVar("PB_HideAllPlayers", "1")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 隐藏所有玩家已启用")
	else
		SetCVar("PB_HideAllPlayers", "0")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 隐藏所有玩家已禁用")
	end
end

SLASH_PBSHOWALLPLAYERS1, SLASH_PBSHOWALLPLAYERS2 = '/pbshowallplayers', '/pbsap'
function SlashCmdList.PBSHOWALLPLAYERS(msg, editbox)
	local v = not (GetCVar("PB_ShowAllPlayers") == "1")
	PerfBoost.db.profile.PB_ShowAllPlayers = v
	if v == true then
		SetCVar("PB_ShowAllPlayers", "1")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 显示所有玩家已启用")
	else
		SetCVar("PB_ShowAllPlayers", "0")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 显示所有玩家已禁用")
	end
end

SLASH_PBCYCLEPLAYERVISIBILITY1, SLASH_PBCYCLEPLAYERVISIBILITY2 = '/pbcycleplayervisibility', '/pbcycle'
function SlashCmdList.PBCYCLEPLAYERVISIBILITY(msg, editbox)
	local showAll = GetCVar("PB_ShowAllPlayers") == "1"
	local hideAll = GetCVar("PB_HideAllPlayers") == "1"
	
	if not showAll and not hideAll then
		-- 当前状态：正常 -> 显示所有
		PerfBoost.db.profile.PB_ShowAllPlayers = true
		PerfBoost.db.profile.PB_HideAllPlayers = false
		SetCVar("PB_ShowAllPlayers", "1")
		SetCVar("PB_HideAllPlayers", "0")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 玩家可见性：显示所有")
	elseif showAll and not hideAll then
		-- 当前状态：显示所有 -> 隐藏所有
		PerfBoost.db.profile.PB_ShowAllPlayers = false
		PerfBoost.db.profile.PB_HideAllPlayers = true
		SetCVar("PB_ShowAllPlayers", "0")
		SetCVar("PB_HideAllPlayers", "1")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 玩家可见性：隐藏所有")
	else
		-- 当前状态：隐藏所有 -> 正常
		PerfBoost.db.profile.PB_ShowAllPlayers = false
		PerfBoost.db.profile.PB_HideAllPlayers = false
		SetCVar("PB_ShowAllPlayers", "0")
		SetCVar("PB_HideAllPlayers", "0")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 玩家可见性：正常")
	end
end

SLASH_PBTOGGLEPLAYERRENDERIST1, SLASH_PBTOGGLEPLAYERRENDERIST2 = '/pbtoggleplayerrenderist', '/pbtrd'
function SlashCmdList.PBTOGGLEPLAYERRENDERIST(msg, editbox)
	local currentDist = PerfBoost.db.profile.PB_PlayerRenderDist
	local currentDistInCombat = PerfBoost.db.profile.PB_PlayerRenderDistInCombat

	if PerfBoost.db.profile.previous_player_render_dist ~= nil then
		-- restore previous values
		local restoreValue = PerfBoost.db.profile.previous_player_render_dist
		local restoreValueInCombat = PerfBoost.db.profile.previous_player_render_dist_in_combat
		PerfBoost.db.profile.PB_PlayerRenderDist = restoreValue
		PerfBoost.db.profile.PB_PlayerRenderDistInCombat = restoreValueInCombat
		SetCVar("PB_PlayerRenderDist", tostring(restoreValue))
		SetCVar("PB_PlayerRenderDistInCombat", tostring(restoreValueInCombat))
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 玩家渲染距离已恢复为 " .. tostring(restoreValue) .. " (正常) 和 " .. tostring(restoreValueInCombat) .. " (战斗)")
		PerfBoost.db.profile.previous_player_render_dist = nil
		PerfBoost.db.profile.previous_player_render_dist_in_combat = nil
	else
		-- Save current values and set both to 0
		PerfBoost.db.profile.previous_player_render_dist = currentDist
		PerfBoost.db.profile.previous_player_render_dist_in_combat = currentDistInCombat
		PerfBoost.db.profile.PB_PlayerRenderDist = 0
		PerfBoost.db.profile.PB_PlayerRenderDistInCombat = 0
		SetCVar("PB_PlayerRenderDist", "0")
		SetCVar("PB_PlayerRenderDistInCombat", "0")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 玩家渲染距离设置为 0 (已保存: " .. tostring(currentDist) .. " 正常, " .. tostring(currentDistInCombat) .. " 战斗)")
	end
end

SLASH_PBCYCLEDOODADVISIBILITY1, SLASH_PBCYCLEDOODADVISIBILITY2 = '/pbcycledoodadvisibility', '/pbcycledoodads'
function SlashCmdList.PBCYCLEDOODADVISIBILITY(msg, editbox)
	local has_doodad = pcall(GetCVar, "PB_DoodadRenderDist")
	if not has_doodad then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 装饰物渲染距离不可用")
		return
	end

	local currentDist = tonumber(GetCVar("PB_DoodadRenderDist")) or 0

	if PerfBoost.db.profile.previous_doodad_render_dist == nil then
		-- Normal -> 0 (hide doodads)
		PerfBoost.db.profile.previous_doodad_render_dist = currentDist
		PerfBoost.db.profile.PB_DoodadRenderDist = 0
		SetCVar("PB_DoodadRenderDist", "0")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 装饰物渲染距离设置为 0 (隐藏装饰物)")
	elseif currentDist == 0 then
		-- 0 -> -1 (always render)
		PerfBoost.db.profile.PB_DoodadRenderDist = -1
		SetCVar("PB_DoodadRenderDist", "-1")
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 装饰物渲染距离设置为 -1 (始终渲染)")
	else
		-- -1 (or any other state) -> restore previous
		local restoreValue = PerfBoost.db.profile.previous_doodad_render_dist
		PerfBoost.db.profile.PB_DoodadRenderDist = restoreValue
		SetCVar("PB_DoodadRenderDist", tostring(restoreValue))
		DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00PerfBoost:|r 装饰物渲染距离恢复为 " .. tostring(restoreValue))
		PerfBoost.db.profile.previous_doodad_render_dist = nil
	end
end

-- Conditionally add new CVars if they exist (for compatibility with older DLL versions)
local has_laggy_boss_spells = pcall(GetCVar, "PB_HideLaggyBossSpellsOnOthers")
if has_laggy_boss_spells then
	PerfBoost.cmdtable.args.spells.args.PB_HideLaggyBossSpellsOnOthers = {
		type = "toggle",
		name = "隐藏某些BOSS的易卡顿视觉效果",
		desc = "隐藏NAXX冰龙(萨菲隆)、K40狼王(格纳尔穆恩)、K40奥爆男(阿诺玛鲁斯)释放在其他玩家\单位上引起卡顿的视觉效果。",
		order = 6,
		get = function()
			return GetCVar("PB_HideLaggyBossSpellsOnOthers") == "1"
		end,
		set = function(v)
			PerfBoost.db.profile.PB_HideLaggyBossSpellsOnOthers = v
			if v == true then
				SetCVar("PB_HideLaggyBossSpellsOnOthers", "1")
			else
				SetCVar("PB_HideLaggyBossSpellsOnOthers", "0")
			end
		end,
	}
end

local has_debug_shown_spells = pcall(GetCVar, "PB_DebugShownSpells")
if has_debug_shown_spells then
	PerfBoost.cmdtable.args.spells.args.PB_DebugShownSpells = {
		type = "toggle",
		name = "调试显示的技能",
		desc = "将每个正在显示的技能信息打印到日志中。",
		order = 21,
		get = function()
			return GetCVar("PB_DebugShownSpells") == "1"
		end,
		set = function(v)
			PerfBoost.db.profile.PB_DebugShownSpells = v
			if v == true then
				SetCVar("PB_DebugShownSpells", "1")
			else
				SetCVar("PB_DebugShownSpells", "0")
			end
		end,
	}
end

local has_doodad_render_dist = pcall(GetCVar, "PB_DoodadRenderDist")
if has_doodad_render_dist then
	PerfBoost.cmdtable.args.rendering.args.PB_DoodadRenderDist = {
		type = "range",
		name = "装饰物渲染距离",
		desc = "渲染装饰物的最大距离。可互动游戏对象（宝箱、门、任务物品等）不会被隐藏。如果处于PvP标记状态则忽略此设置。",
		order = 42,
		min = -1,
		max = 100,
		step = 1,
		get = function()
			local val = GetCVar("PB_DoodadRenderDist")
			return val and tonumber(val) or 0
		end,
		set = function(v)
			PerfBoost.db.profile.PB_DoodadRenderDist = v
			SetCVar("PB_DoodadRenderDist", tostring(v))
		end,
		}
end

local has_doodad_render_dist_in_cities_and_raids = pcall(GetCVar, "PB_DoodadRenderDistInCitiesAndRaids")
if has_doodad_render_dist_in_cities_and_raids then
	PerfBoost.cmdtable.args.rendering.args.PB_DoodadRenderDistInCitiesAndRaids = {
		type = "range",
		name = "城市与团本中装饰物渲染距离",
		desc = "在城市和40人团队副本中渲染装饰物的最大距离。优先应用。可互动游戏对象（宝箱、门、任务物品等）不会被隐藏。如果处于PvP标记状态则忽略此设置。",
		order = 43,
		min = -1,
		max = 100,
		step = 1,
		get = function()
			local val = GetCVar("PB_DoodadRenderDistInCitiesAndRaids")
			return val and tonumber(val) or 0
		end,
		set = function(v)
			PerfBoost.db.profile.PB_DoodadRenderDistInCitiesAndRaids = v
			SetCVar("PB_DoodadRenderDistInCitiesAndRaids", tostring(v))
		end,
	}
end
