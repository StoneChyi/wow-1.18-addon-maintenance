-- ArchiTotem 数据模块
-- 包含图腾数据初始化和默认配置

local _G = getfenv()
local _, class = UnitClass("player")

-- 图腾元素列表
local totemElements = { "Earth", "Fire", "Water", "Air" }
ArchiTotem_TotemElements = totemElements

-- 弹出按钮列表
local ArchiTotemPopout = {
	"ArchiTotemButton_Earth2", "ArchiTotemButton_Earth3", "ArchiTotemButton_Earth4", "ArchiTotemButton_Earth5",
	"ArchiTotemButton_Fire2", "ArchiTotemButton_Fire3", "ArchiTotemButton_Fire4", "ArchiTotemButton_Fire5",
	"ArchiTotemButton_Water2", "ArchiTotemButton_Water3", "ArchiTotemButton_Water4", "ArchiTotemButton_Water5",
	"ArchiTotemButton_Air2", "ArchiTotemButton_Air3", "ArchiTotemButton_Air4", "ArchiTotemButton_Air5",
	"ArchiTotemButton_Air6", "ArchiTotemButton_Air7",
}
ArchiTotem_PopoutButtons = ArchiTotemPopout

-- 初始化默认选项
function ArchiTotem_InitializeOptions()
	if class ~= "SHAMAN" or ArchiTotem_Options then
		return
	end

	ArchiTotem_Options = {}

	-- 各元素配置
	ArchiTotem_Options["Ear"] = { max = 5, shown = 1, skip = false }
	ArchiTotem_Options["Fir"] = { max = 5, shown = 1, skip = false }
	ArchiTotem_Options["Wat"] = { max = 5, shown = 1, skip = false }
	ArchiTotem_Options["Air"] = { max = 7, shown = 1, skip = false }

	-- 外观配置
	ArchiTotem_Options["Apperance"] = {
		direction = "up",
		scale = 1,
		allonmouseover = false,
		bottomoncast = true,
		shownumericcooldowns = true,
		showtooltips = true,
		showrecallbutton = true,
		showpresetmanagerbutton = true,
		isFirstTime = true  -- 标记是否是第一次使用
	}

	-- 排序配置
	ArchiTotem_Options["Order"] = {
		first = "Earth",
		second = "Fire",
		third = "Water",
		forth = "Air"
	}

	ArchiTotem_Options["Debug"] = false

	-- 天赋相关（图腾掌握）
	ArchiTotem_Options["ForceTotemicMastery"] = nil  -- 可手动强制 on/off；nil 为自动检测
	ArchiTotem_Options["TotemicMasteryTab"] = nil   -- 可手动指定 tab 索引（1~3）
	ArchiTotem_Options["TotemicMasteryIndex"] = nil -- 可手动指定天赋在该 tab 的索引

	-- 拖拽手柄配置
	ArchiTotem_Options.locked = false  -- 默认解锁状态，显示拖拽手柄
	ArchiTotem_Options.framePosition = nil  -- 主框架位置，nil 表示使用默认位置

	-- 图腾预设组合
	ArchiTotem_Options["Presets"] = {
		pve = {
			Earth = "Strength of Earth Totem",
			Fire = "Flametongue Totem",
			Water = "Mana Spring Totem",
			Air = "Windfury Totem"
		},
		pvp = {
			Earth = "Tremor Totem",
			Fire = "Searing Totem",
			Water = "Healing Stream Totem",
			Air = "Grounding Totem"
		},
		resist = {
			Earth = "Stoneskin Totem",
			Fire = "Frost Resistance Totem",
			Water = "Fire Resistance Totem",
			Air = "Nature Resistance Totem"
		},
		custom = {
			Earth = "Strength of Earth Totem",
			Fire = "Searing Totem",
			Water = "Mana Spring Totem",
			Air = "Tranquil Air Totem"
		}
	}

	-- 按键绑定配置
	ArchiTotem_Options["KeyBindings"] = {
		CastAllTotems = nil,
		RecallTotems = nil,
		CastEarth = nil,
		CastFire = nil,
		CastWater = nil,
		CastAir = nil,
		ToggleSkipEarth = nil,
		ToggleSkipFire = nil,
		ToggleSkipWater = nil,
		ToggleSkipAir = nil
	}
end

-- 初始化图腾数据
function ArchiTotem_InitializeTotemData()
	if class ~= "SHAMAN" or ArchiTotem_TotemData then
		return
	end

	ArchiTotem_TotemData = {}

	-- 土系图腾
	local earthTotems = {
		{ name = "Earthbind Totem", icon = "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02", duration = 45, cooldown = 15 },
		{ name = "Tremor Totem", icon = "Interface\\Icons\\Spell_Nature_TremorTotem", duration = 120, cooldown = 0 },
		{ name = "Strength of Earth Totem", icon = "Interface\\Icons\\Spell_Nature_EarthBindTotem", duration = 120, cooldown = 0 },
		{ name = "Stoneskin Totem", icon = "Interface\\Icons\\Spell_Nature_StoneSkinTotem", duration = 120, cooldown = 0 },
		{ name = "Stoneclaw Totem", icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem", duration = 15, cooldown = 30 }
	}

	-- 火系图腾
	local fireTotems = {
		{ name = "Searing Totem", icon = "Interface\\Icons\\Spell_Fire_SearingTotem", duration = 55, cooldown = 0 },
		{ name = "Fire Nova Totem", icon = "Interface\\Icons\\Spell_Fire_SealOfFire", duration = 5, cooldown = 15 },
		{ name = "Magma Totem", icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", duration = 20, cooldown = 0 },
		{ name = "Frost Resistance Totem", icon = "Interface\\Icons\\Spell_FrostResistanceTotem_01", duration = 120, cooldown = 0 },
		{ name = "Flametongue Totem", icon = "Interface\\Icons\\Spell_Nature_GuardianWard", duration = 120, cooldown = 0 }
	}

	-- 水系图腾
	local waterTotems = {
		{ name = "Mana Spring Totem", icon = "Interface\\Icons\\Spell_Nature_ManaRegenTotem", duration = 60, cooldown = 0 },
		{ name = "Healing Stream Totem", icon = "Interface\\Icons\\INV_Spear_04", duration = 60, cooldown = 0 },
		{ name = "Fire Resistance Totem", icon = "Interface\\Icons\\Spell_FireResistanceTotem_01", duration = 120, cooldown = 0 },
		{ name = "Poison Cleansing Totem", icon = "Interface\\Icons\\Spell_Nature_PoisonCleansingTotem", duration = 120, cooldown = 0 },
		{ name = "Disease Cleansing Totem", icon = "Interface\\Icons\\Spell_Nature_DiseaseCleansingTotem", duration = 120, cooldown = 0 }
	}

	-- 风系图腾
	local airTotems = {
		{ name = "Tranquil Air Totem", icon = "Interface\\Icons\\Spell_Nature_Brilliance", duration = 120, cooldown = 0 },
		{ name = "Grounding Totem", icon = "Interface\\Icons\\Spell_Nature_GroundingTotem", duration = 45, cooldown = 20 },
		{ name = "Windfury Totem", icon = "Interface\\Icons\\Spell_Nature_Windfury", duration = 120, cooldown = 0 },
		{ name = "Grace of Air Totem", icon = "Interface\\Icons\\Spell_Nature_InvisibilityTotem", duration = 120, cooldown = 0 },
		{ name = "Nature Resistance Totem", icon = "Interface\\Icons\\Spell_Nature_NatureResistanceTotem", duration = 120, cooldown = 0 },
		{ name = "Windwall Totem", icon = "Interface\\Icons\\Spell_Nature_EarthBind", duration = 120, cooldown = 0 },
		{ name = "Sentry Totem", icon = "Interface\\Icons\\Spell_Nature_RemoveCurse", duration = 300, cooldown = 0 }
	}

	-- 初始化各系图腾数据
	ArchiTotem_InitializeElementTotems("Earth", earthTotems)
	ArchiTotem_InitializeElementTotems("Fire", fireTotems)
	ArchiTotem_InitializeElementTotems("Water", waterTotems)
	ArchiTotem_InitializeElementTotems("Air", airTotems)

	-- 一键图腾按钮数据
	ArchiTotem_TotemData["ArchiTotemButton_AllTotems"] = {
		icon = nil,
		name = "Call of the Elements",
		duration = 0,
		cooldown = 0,
		cooldownstarted = nil,
		casted = nil
	}

	-- 召回图腾按钮数据
	ArchiTotem_TotemData["ArchiTotemButton_Recall"] = {
		icon = nil,
		name = "Totemic Recall",
		duration = 0,
		cooldown = 6,
		cooldownstarted = nil,
		casted = nil
	}
end

-- 初始化单个元素的图腾数据
function ArchiTotem_InitializeElementTotems(element, totems)
	for i, totem in ipairs(totems) do
		local buttonName = "ArchiTotemButton_" .. element .. i
		ArchiTotem_TotemData[buttonName] = {
			icon = totem.icon,
			name = totem.name,
			duration = totem.duration,
			cooldown = totem.cooldown,
			cooldownstarted = nil,
			casted = GetTime() - (totem.cooldown or 0)  -- 确保 casted 有初始值
		}
	end
end

-- 兼容性检查函数
function ArchiTotem_CheckCompatibility()
	if class ~= "SHAMAN" then
		return
	end

	-- 确保跳过选项存在（兼容性检查）
	if ArchiTotem_Options["Ear"] and ArchiTotem_Options["Ear"].skip == nil then
		ArchiTotem_Options["Ear"].skip = false
	end
	if ArchiTotem_Options["Fir"] and ArchiTotem_Options["Fir"].skip == nil then
		ArchiTotem_Options["Fir"].skip = false
	end
	if ArchiTotem_Options["Wat"] and ArchiTotem_Options["Wat"].skip == nil then
		ArchiTotem_Options["Wat"].skip = false
	end
	if ArchiTotem_Options["Air"] and ArchiTotem_Options["Air"].skip == nil then
		ArchiTotem_Options["Air"].skip = false
	end
	
	-- 确保外观选项存在
	if not ArchiTotem_Options["Apperance"] then
		ArchiTotem_Options["Apperance"] = {
			direction = "up",
			scale = 1,
			allonmouseover = false,
			bottomoncast = true,
			shownumericcooldowns = true,
			showtooltips = true,
			showrecallbutton = true,
			showpresetmanagerbutton = true,
			isFirstTime = false  -- 老用户不需要首次设置
		}
	else
		-- 为现有用户添加新选项
		if ArchiTotem_Options["Apperance"].isFirstTime == nil then
			ArchiTotem_Options["Apperance"].isFirstTime = false  -- 现有用户标记为非首次
		end
		if ArchiTotem_Options["Apperance"].showpresetmanagerbutton == nil then
			ArchiTotem_Options["Apperance"].showpresetmanagerbutton = true
		end
	end
	
	-- 确保预设存在
	if not ArchiTotem_Options["Presets"] then
		ArchiTotem_Options["Presets"] = {
			pve = {
				Earth = "Strength of Earth Totem",
				Fire = "Flametongue Totem",
				Water = "Mana Spring Totem",
				Air = "Windfury Totem"
			},
			pvp = {
				Earth = "Tremor Totem",
				Fire = "Searing Totem",
				Water = "Healing Stream Totem",
				Air = "Grounding Totem"
			},
			resist = {
				Earth = "Stoneskin Totem",
				Fire = "Frost Resistance Totem",
				Water = "Fire Resistance Totem",
				Air = "Nature Resistance Totem"
			},
			custom = {
				Earth = "Strength of Earth Totem",
				Fire = "Searing Totem",
				Water = "Mana Spring Totem",
				Air = "Tranquil Air Totem"
			}
		}
	end
end
