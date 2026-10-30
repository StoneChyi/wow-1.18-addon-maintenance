ATSW_PossibleCache = {}
ATSW_PossibleGeneration = 0
ATSW_PossibleTTL = 0.25
function ATSW_PossibleInvalidate()
    ATSW_PossibleGeneration = ATSW_PossibleGeneration + 1
end

-- copyright 2006 by Rene Schneider (Slarti on EU-Blackhand), 2017 by laytya
-- Modified by Alexander Shelokhnev (Dreamios on Tel'Abim (Turtle-WoW)) in 2022

local _G = getfenv(0)

ATSW_MAX_TRADESKILL_TABS 			= 8
ATSW_TRADESKILL_HEIGHT 				= 18

ATSW_RECIPES_DISPLAYED 				= 23
ATSW_TASKS_DISPLAYED 					= 5
ATSW_TOOLS_DISPLAYED 					= 4
ATSW_NECESSARIES_DISPLAYED 		= 20
ATSW_AUCTION_ITEMS_DISPLAYED 	= 5

ATSW_TABLE_CREATION_SIZE 			= 10

ATSW_NECESSARY_REAGENT_ADD		= 1
ATSW_NECESSARY_REAGENT_DELETE	= 2

ATSW_POSSIBLE_BAGS						= 1
ATSW_POSSIBLE_BANK						= 2
ATSW_POSSIBLE_ALTS						= 3
ATSW_POSSIBLE_MERCHANT				= 4
ATSW_POSSIBLE_NOTASK					= 5

ATSW_CAST 										= 1
ATSW_FLASH 									= 2
ATSW_FADEOUT 								= 3

ATSW_FLASH_TIME							= 5/60
ATSW_FADEOUT_TIME						= 10/60

ERR_LEARN_RECIPE_PATTERN 			= string.gsub(ERR_LEARN_RECIPE_S, 			'%%s', '(.+)'		)
ERR_LEARN_SPELL_PATTERN 				= string.gsub(ERR_LEARN_SPELL_S, 			'%%s', '(.+)'		)
ERR_LEARN_ABILITY_PATTERN 			= string.gsub(ERR_LEARN_ABILITY_S, 		'%%s', '(.+)'		)
ERR_UNLEARN_RECIPE_PATTERN			= string.gsub(ERR_SPELL_UNLEARNED_S, 	'%%s', '(.+)'		)
ERR_SKILL_UP_PATTERN 					= string.gsub(string.gsub(ERR_SKILL_UP_SI,'%%d', '%%d+'),'%%s','(.+)')
ERR_SKILL_GAINED_PATTERN 				= string.gsub(ERR_SKILL_GAINED_S, 			'%%s', '(.+)'		)
LOOT_ITEM_CREATED_SELF_PATTERN = string.gsub(LOOT_ITEM_CREATED_SELF,	'%%s',	'(.+)'		)

UIPanelWindows['ATSWFrame'			] 	= { area = 'left', 		pushable = 8 }
UIPanelWindows['ATSWCSFrame'		] 	= { area = 'left', 		pushable = 8 }
UIPanelWindows['ATSWConfigFrame'	]	= { area = 'center', 	pushable = 1 }

ATSWTypeColor = {
	['optimal'	]	= {	R = 1.00,	G = 0.50,	B = 0.25	},
	['medium'	]	= {	R = 1.00,	G = 1.00,	B = 0.00	},
	['easy'		]	= {	R = 0.25,	G = 0.75,	B = 0.25	},
	['trivial'		]	= {	R = 0.50,	G = 0.50,	B = 0.50	},
	['used'		]	= {	R = 0.50,	G = 0.50,	B = 0.50	},
	['header'	]	= {	R = 1.00,	G = 0.82,	B = 0		},
	['none'		]	= {	R = 0.25,	G = 0.75,	B = 0.25	}
}

local QualityColor = {
	[1] = {	R = 0.62,	G = 0.62, 	B = 0.62	},
	[2] = {	R = 1,		G = 1, 		B = 1		},
	[3] = {	R = 0.12,	G = 1, 		B = 0		},
	[4] = {	R = 0,		G = 0.44, 	B = 0.87	},
	[5] = {	R = 0.64,	G = 0.21, 	B = 0.93	},
	[6] = {	R = 1,		G = 0.5, 	B = 0		},
	[7] = {	R = 0.9,	G = 0.8, 	B = 0.5		},
	[8] = {	R = 0,		G = 0.8, 	B = 1		}
}

local ToolID = {
	['Blacksmith Hammer'			] 		= 5956,
	['Arclight Spanner'				] 		= 6219,
	['Gyromatic Micro-Adjustor'	]		= 10498,
	['Philosopher\'s Stone'			] 		= 9149,
	['Runed Copper Rod'			] 		= 6218,
	['Runed Silver Rod'				] 		= 6339,
	['Runed Golden Rod'			] 		= 11130,
	['Runed Truesilver Rod'		] 		= 11145,
	['Runed Arcanite Rod'			] 		= 16207
}

local Professions	= {
	'Trade_Engraving',				-- Enchanting
	'Trade_Tailoring',				-- Tailoring
	'Trade_Engineering',			-- Engineering
	'Trade_BlackSmithing',			-- Blacksmithing
	'INV_Jewelry_Necklace_11',	-- Jewelcrafting
	'Spell_Fire_FlameBlades',		-- Smelting
	'Trade_Alchemy',				-- Alchemy
	'INV_Misc_ArmorKit_17',		-- Leatherworking
	'INV_Misc_Food_15',			-- Cooking
	'Spell_Holy_SealOfSacrifice',	-- First Aid
	'Trade_Survival',					-- Survival
	'Ability_Hunter_BeastCall02',	-- Beast Training
	'Trade_BrewPoison'				-- Poisons
}

-- For AtlasLoot addon
local ProfessionNamesForAtlasLoot = {
	['Interface\\Icons\\Trade_Engraving'] = { -- Enchanting
		'EnchantingApprentice1',
		'EnchantingJourneyman1',
		'EnchantingJourneyman2',
		'EnchantingExpert1',
		'EnchantingExpert2',
		'EnchantingArtisan1',
		'EnchantingArtisan2',
		'EnchantingArtisan3'
	},
	['Interface\\Icons\\Trade_Tailoring'] = { -- Tailoring
		'TailoringApprentice1',
		'TailoringJourneyman1',
		'TailoringJourneyman2',
		'TailoringExpert1',
		'TailoringExpert2',
		'TailoringArtisan1',
		'TailoringArtisan2',
		'TailoringArtisan3',
		'TailoringArtisan4'
	},
	['Interface\\Icons\\Trade_Engineering'] = { -- Engineering
		'EngineeringApprentice1',
		'EngineeringJourneyman1',
		'EngineeringJourneyman2',
		'EngineeringExpert1',
		'EngineeringExpert2',
		'EngineeringArtisan1',
		'EngineeringArtisan2',
		'Gnomish1',
		'Goblin1'
	},
	['Interface\\Icons\\Trade_BlackSmithing'] ={ -- Blacksmithing
		'SmithingApprentice1',
		'SmithingJourneyman1',
		'SmithingJourneyman2',
		'SmithingExpert1',
		'SmithingExpert2',
		'SmithingArtisan1',
		'SmithingArtisan2',
		'SmithingArtisan3',
		'Armorsmith1',
		'Weaponsmith1',
		'Axesmith1',
		'Hammersmith1',
		'Swordsmith1'
	},
	['Interface\\Icons\\INV_Jewelry_Necklace_11'] = { -- Jewelcrafting
		'JewelcraftingApprentice1',
		'JewelcraftingJourneyman1',
		'JewelcraftingJourneyman2',
		'JewelcraftingExpert1',
		'JewelcraftingExpert2',
		'JewelcraftingExpert3',
		'JewelcraftingArtisan1',
		'JewelcraftingArtisan2'
	},
	['Interface\\Icons\\Spell_Fire_FlameBlades'] = { -- Smelting
		'Smelting1'
	},
	['Interface\\Icons\\Trade_Alchemy'] = { -- Alchemy
		'AlchemyApprentice1',
		'AlchemyJourneyman1',
		'AlchemyExpert1',
		'AlchemyArtisan1',
		'AlchemyArtisan2'
	},
	['Interface\\Icons\\INV_Misc_ArmorKit_17'] = { -- Leatherworking
		'LeatherApprentice1',
		'LeatherJourneyman1',
		'LeatherJourneyman2',
		'LeatherExpert1',
		'LeatherExpert2',
		'LeatherArtisan1',
		'LeatherArtisan2',
		'LeatherArtisan3',
		'Dragonscale1',
		'Elemental1',
		'Tribal1'
	},
	['Interface\\Icons\\INV_Misc_Food_15'] = { -- Cooking
		'CookingApprentice1',
		'CookingJourneyman1',
		'CookingExpert1',
		'CookingArtisan1'
	},
	['Interface\\Icons\\Spell_Holy_SealOfSacrifice'] = { -- First Aid
		'FirstAid1'
	},
	['Interface\\Icons\\Trade_Survival'] = { -- Survival
		'Survival1',
		'Survival2'
	}, 
	['Interface\\Icons\\Ability_Hunter_BeastCall02'] = {''}, -- Beast Training
	['Interface\\Icons\\Trade_BrewPoison'] = { -- Poisons
		'Poisons1'
	}
}

ATSW_Specializations = {
	['Interface\\Icons\\Trade_Engineering'] = {		-- Engineering
		'INV_Gizmo_02', 					-- Gnomish Engineer
		'Spell_Fire_SelfDestruct' 			-- Goblin Engineer
	},
	['Interface\\Icons\\Trade_BlackSmithing'] ={		-- Blacksmithing
		'INV_Chest_Plate04', 				-- Armorsmith
		'INV_Sword_25', 					-- Weaponsmith
		'INV_Axe_05', 						-- Master Axesmith
		'INV_Hammer_23', 					-- Master Hammersmith
		'INV_Sword_41' 						-- Master Swordsmith
	},
	['Interface\\Icons\\INV_Misc_ArmorKit_17'] = {	-- Leatherworking
		'INV_Misc_MonsterScales_03',	-- Dragonscale Leatherworking
		'Spell_Fire_Volcano', 				-- Elemental Leatherworking
		'Spell_Nature_NullWard'	 		-- Tribal Leatherworking
	}
}

ATSW_Background = {
	['Interface\\Icons\\Trade_Engraving'					]	= 'Enchanting',
	['Interface\\Icons\\Trade_Tailoring'					]	= 'Tailoring',
	['Interface\\Icons\\Trade_Engineering'				]	= 'Engineering',
	['Interface\\Icons\\Trade_BlackSmithing'			]	= 'Blacksmithing',
	['Interface\\Icons\\INV_Jewelry_Necklace_11'	]	= 'Jewelcrafting',
	['Interface\\Icons\\Spell_Fire_FlameBlades'			]	= 'Smelting',
	['Interface\\Icons\\Trade_Alchemy'					]	= 'Alchemy',
	['Interface\\Icons\\INV_Misc_ArmorKit_17'			]	= 'Leatherworking',
	['Interface\\Icons\\INV_Misc_Food_15'				]	= 'Cooking',
	['Interface\\Icons\\Spell_Holy_SealOfSacrifice'		]	= 'FirstAid',
	['Interface\\Icons\\Trade_Survival'						]	= 'Survival',
	['Interface\\Icons\\Ability_Hunter_BeastCall02'	]	= 'BeastTraining',
	['Interface\\Icons\\Trade_BrewPoison'				]	= 'Poisons'
}

-- Colors are stored for code readability
local Color = {
	GREY 		= '|cff7f7f7f',
	LIGHTGREY= '|cff9F9F9F',
	RED 			= '|cffff0000',
	WHITE 		= '|cffFFFFFF',
	GREEN 		= '|cff00FF00',
	DARKGREEN = '|cff1f8f1f',
	PURPLE 	= '|cff9F3FFF',
	BLUE 		= '|cff0070dd',
	ORANGE 	= '|cffff7f3f',
	YELLOW 	= '|cffffff00',
	DEFAULT 	= '|cffFFd200'
}

local function GetUnitClass(Unit)
	local _, Class = UnitClass(Unit)
	
	if Class and string.len(Class) > 0 then
		local First = string.upper(string.sub(Class, 1, 1))
		local Rest = string.upper(string.sub(Class, 2))
		
		Class = First .. Rest
	end
	
	return Class
end

local realm 										= GetRealmName()
local player 										= UnitName('player')
local class											= GetUnitClass('player')
ATSW_player										= player
ATSW_realm										= realm

ATSW_Characters 								= {}
ATSW_Characters[realm] 					= {}

local TradeSkill

function ATSW_TradeSkill()
	return TradeSkill
end

local InitializedOnShow 						= false
local ReagentsDataIsComplete 				= true
local RecipesDataIsComplete 				= -1
local RecipesDataTries 						= 0
local CooldownUpdateTime 					= 0
local LoadingProfessions 						= false
local UpdateCount								= 0
local LastCastName 							= nil
local NoDropDownUpdate					= false
local BankFrameOpened						= false

local s 				= ERR_USE_LOCKED_WITH_ITEM_S 		-- 'Requires %s'
local sRequires 	= string.sub(s, 1, string.find(s, '%s')) 	-- Delete %s

ATSW_Debug 									= false

ATSW_SwitchingFrames						= false
ATSW_SwitchingToEditor					= false
ATSW_SwitchingToMain						= false

-- Selected
ATSW_Profession 								= {}
ATSW_Profession[realm]						= {}
ATSW_Profession[realm][player] 			= nil
ATSW_SelectedRecipe 						= {}
ATSW_SelectedRecipe[realm]				= {}
ATSW_SelectedRecipe[realm][player]	= {}

-- Top control panel
ATSW_SortBy 									= {}
ATSW_SortBy[realm] 							= {}
ATSW_SortBy[realm][player] 				= {}
ATSW_SearchString 							= {}
ATSW_SearchString[realm] 					= {}
ATSW_SearchString[realm][player] 		= {}
ATSW_BlockSearchTextChanged 			= false
ATSW_SubClassFilter 							= {}
ATSW_SubClassFilter[realm] 					= {}
ATSW_SubClassFilter[realm][player] 		= {}
ATSW_InvSlotFilter 							= {}
ATSW_InvSlotFilter[realm] 					= {}
ATSW_InvSlotFilter[realm][player] 		= {}

-- Recipes auxiliary arrays
ATSW_ContractedCategories 				= {}
ATSW_ContractedCategories[realm] 		= {}
ATSW_ContractedCategories[realm][player] = {}
ATSW_ScrollOffset 								= {}
ATSW_ScrollOffset[realm] 					= {}
ATSW_ScrollOffset[realm][player] 			= {}
ATSW_NeedToUpdate 						= {}
ATSW_NeedToUpdate[realm] 				= {}
ATSW_NeedToUpdate[realm][player] 	= {}

-- Previous recipes
ATSW_PreviousRecipes 						= {}
ATSW_PreviousRecipes[realm] 				= {}
ATSW_PreviousRecipes[realm][player] 	= {}

-- Tasks
ATSW_Tasks 										= {}
ATSW_Tasks[realm] 							= {}
ATSW_Tasks[realm][player] 					= {}
ATSW_NecessaryReagents 					= {}
ATSW_NecessaryReagents[realm] 		= {}
ATSW_NecessaryReagents[realm][player] = {}
ATSW_TimeCost									= {}

-- Bottom control panel
ATSW_Amount 									= {}
ATSW_Amount[realm] 						= {}
ATSW_Amount[realm][player] 				= {}

-- Processing
local Processing = {
	Active			= false,
	Profession		= nil,
	Recipe			= nil,
	Texture			= nil,
	RecipeTime	= 0,
	Amount			= 0,
	Time				= 0,
	Delay				= 0,
	Complete		= 0,
	Stop				= false
}

-- Options
ATSW_Options = {
	Unified 							= true,
	ConsiderBank 					= false,
	ConsiderAlts 					= false,
	ConsiderMerchants 			= false,
	RecipeTooltip 				= true,
	AutoBuy 						= false,
	DisplayShoppingList 			= true,
	NoConfirmMats 				= false, -- true: send reagent list to chat directly, without confirmation popup (/atsw matsconfirm)
}

ATSW_Attributes = {}
ATSW_Attributes[realm] = {}
ATSW_Attributes[realm][player] = {}

-- Transform old settings. Remove in the future, 2026 year maybe.
if ATSW_Unified ~= nil then
	ATSW_Options.Unified 						= ATSW_Unified
	ATSW_Options.ConsiderBank 				= ATSW_ConsiderBank
	ATSW_Options.ConsiderAlts 				= ATSW_ConsiderAlts
	ATSW_Options.ConsiderMerchants 		= ATSW_ConsiderMerchants
	ATSW_Options.RecipeTooltip 				= ATSW_RecipeTooltip
	ATSW_Options.AutoBuy 						= ATSW_AutoBuy
	ATSW_Options.DisplayShoppingList 		= ATSW_DisplayShoppingList
	ATSW_Unified = nil
	ATSW_ConsiderBank = nil
	ATSW_ConsiderAlts = nil
	ATSW_ConsiderMerchants = nil
	ATSW_RecipeTooltip = nil
	ATSW_AutoBuy = nil
	ATSW_DisplayShoppingList = nil
end

-- Controllable tables instead of standard tables do not leave garbage if they change in the game

ATSW = {
	Recipes 									= {},
	RecipesSize 							= {},
	RecipesSorted 						= {},
	RecipesSortedSize 					= {},
}

ATSW.Recipes[realm] 							= {}
ATSW.Recipes[realm][player] 				= {}
ATSW.RecipesSize[realm] 					= {}
ATSW.RecipesSize[realm][player] 			= {}
ATSW.RecipesSorted[realm] 				= {}
ATSW.RecipesSorted[realm][player] 		= {}
ATSW.RecipesSortedSize[realm] 			= {}
ATSW.RecipesSortedSize[realm][player]	= {}

-- Utility functions
local function SetVisible(Frame, State)
	if Frame then
		if State then
			Frame:Show()
		else
			Frame:Hide()
		end
	end
end

local function SetEnabled(Frame, State)
	if Frame then
		if State then
			Frame:Enable()
		else
			Frame:Disable()
		end
	end
end

local function SetSize(Object, Size, SizeY)
	Object:SetWidth(Size)
	Object:SetHeight(SizeY or Size)
end

local function FormatTime(Seconds, FourDigits)
	if tonumber(Seconds) then
		local Time
		local D, H, M, S = ChatFrame_TimeBreakDown(Seconds)
	  
		if D > 0 then
			Time =  string.format('%dd:%dh', D, H)
		elseif H > 0 then
			Time = string.format('%dh:%dm', H, M)
		else
			if FourDigits then
				Time = string.format( '%02d:%02d', M, S)
			else
				if M > 0 then
					Time = string.format('%d:%02d', M, S)
				elseif S > 0 then
					Time = string.format('%d', S)
				end
			end
		end
		
		return Time
	end
end

local function FormatCooldown(Cooldown)
	if Cooldown then
		local Time = math.floor(Cooldown)
		
		if Time > 0 then
			Time = SecondsToTime(Time, false)
			Time = string.gsub(Time, 'Day', 'day')
			Time = string.gsub(Time, 'Hr', 'hour')
			Time = string.gsub(Time, 'Min', 'minute')
			Time = string.gsub(Time, 'Sec', 'second')
		end
		
		return Time
	end
end

local function ShortFormatCooldown(Cooldown, FourDigits)
	if Cooldown and type(Cooldown) == 'number' and Cooldown >= 0 then
		return FormatTime(Cooldown, FourDigits)
	else
		return ''
	end
end

local function ConvertCooldown(Cooldown, Long)
	if Cooldown then
		local S = Cooldown - GetTime()
		
		if S >= 0 then
			if Long then
				return FormatCooldown(S)
			else
				return ' |cffE00000(' .. ShortFormatCooldown(S) .. ')|r'
			end
		end
	end
end

local function HexToDec(Hex)
    Hex = string.upper(Hex)
	
    local Total = 0
	
    for I = 1, string.len(Hex) do
        local Char = string.byte(Hex, I)
        local Numeric
		
        if Char > 64 then
            Numeric = Char - 55
        else
            Numeric = Char - 48
        end
		
        Total = Total + Numeric * math.pow(16, string.len(Hex) - I)
    end
	
    return Total
end

local function Round(number, decimals)
    return math.floor((number * math.pow(10, decimals) + 0.5)) / math.pow(10, decimals)
end

local function LinkToName(Link)
	if Link then
		return string.gsub(Link,'^.*%[(.*)%].*$','%1')
	end
end

local function LinkToColor(Link)
    if Link then
        return string.gsub(Link, '^.*|cff(.-)|.*$', '%1')
    end
end

local function GetLinkColorRGB(Link)
    if Link then
        local Color = HexToDec(LinkToColor(Link))
        local R	= math.floor(Color / 65536)
        local G	= math.floor((Color - R * 65536) / 256)
        local B	= math.floor((Color - R * 65536 - G * 256))
		
        return R/255, G/255, B/255
    end
end

local function ColorToQuality(R, G, B)
	if R then
		for I = 1, table.getn(QualityColor) do
			local C = QualityColor[I]
			
			if C.R == Round(R, 2) and C.G == Round(G, 2) and C.B == Round(B, 2) then
				return I
			end
		end
	end
	
	return 0
end

local function LinkToQuality(Link)
	local R, G, B = GetLinkColorRGB(Link)
	
	return ColorToQuality(R, G, B)
end

local function ATSW_LinkToID(Link)
    if Link then
		local _, _, LinkType, ID = string.find(Link, '^.*|H?([^:]*):?(%d+)')
		
        return tonumber(ID)
    end
end

local function ATSW_GetAHUnitPrice(Link)
	-- AH price via aux auction estimate (falls back to daily_min_buyout when no scan data)
	if not Link then
		return nil
	end

	-- aux 核心模块只通过 require 暴露（不挂全局 _G.aux.history），此处 require 取得 history 模块
	local ok_h, history = pcall(require, 'aux.core.history')

	-- 改取“今日价格”用 history.market_value（= daily_min_buyout，今日最低一口价）
	-- 原 history.value 是加权历史均价，非今日价
	if not ok_h or not history or not history.market_value then
		return nil
	end

	-- Lua 5.0 的 string.find 返回 起始, 结束, 捕获1, 捕获2，必须用 _ 占位跳过前两个返回值
	-- 参考 D://AdvancedTradeSkillWindow//atsw.lua 的 string.find(link, 'item:(%d+)') 写法
	local _, _, item_id, suffix_id = string.find(Link, 'item:(%d+):?(%d*)')

	if not item_id then
		return nil
	end

	suffix_id = tonumber(suffix_id) or 0
	local item_key = item_id .. ':' .. suffix_id
	local ok, price = pcall(history.market_value, item_key)

	if ok and price and price > 0 then
		return price
	end

	return nil
end

local function ATSW_FormatCost(copper)
	copper = math.floor(copper or 0)

	if copper <= 0 then
		return '0铜'
	end

	local g = math.floor(copper / 10000)
	local s = math.floor((copper - g * 10000) / 100)
	local c = math.mod(copper, 100)
	local text = ''

	if g > 0 then text = text .. g .. '金 ' end
	if s > 0 then text = text .. s .. '银 ' end
	if c > 0 then text = text .. c .. '铜' end

	return (text ~= '' and text) or '0铜'
end

local ITEM_MIN_LEVEL_PATTERN = string.gsub(ITEM_MIN_LEVEL,'%%d', '(%%d+)')

local function GetItemMinLevel(ID, Reagent)
	local Stats = {GetTradeSkillItemStats(ID)}

	for I, V in pairs(Stats) do
		local _, _, Level = string.find(V, ITEM_MIN_LEVEL_PATTERN)

		if Level then
			return tonumber(Level)
		end
	end
end

local function GetItemTexture(ID)
	local _, _, _, _, _, _, _, _, Texture = GetItemInfo(ID)
	
	return Texture
end

local function RemoveEscapeCharacters(String)
	local Result = tostring(String)
	
	Result = gsub(Result, '|c........', ''			) 	-- Remove color start.
	Result = gsub(Result, '|r', ''						) 	-- Remove color end.
	Result = gsub(Result, '|H.-|h(.-)|h', '%1'	) 	-- Remove links.
	Result = gsub(Result, '|T.-|t', ''				) 	-- Remove textures.
	Result = gsub(Result, '{.-}', ''					) 	-- Remove raid target icons.
	
	return Result
end

local function GetCategoryTexture(Expanded)
	return 'Interface\\Buttons\\UI-' .. (Expanded and 'Min' or 'Pl') .. 'usButton-Up'
end

local function GetSpellNum(Name)
	local I, SName = 0
	
	repeat
		I = I + 1
		SName = GetSpellName(I, BOOKTYPE_SPELL)
		
		if SName and Name and string.find(SName, Name) then
			return I
		end
	until not SName
end

local function GetProfessionTexture(Name)
	local SpellNum = GetSpellNum(Name)
	
	if SpellNum then
		return GetSpellTexture(SpellNum, BOOKTYPE_SPELL)
	end
end

local function Icon(Name)
	return Name and ('Interface\\Icons\\' .. Name)
end

local function IsEnchant(Index)
	local I = Icon('Spell_Holy_GreaterHeal')
	
	if type(Index) == 'string' then
		return Index == I
	elseif type(Index) == 'number' then
		return ATSW_GetCraftTexture(Index) == I
	end
end

local function GetLatency()
	local _, _, lag = GetNetStats()
	
	return lag / 1000
end

local function Debug(Message)
	if ATSW_Debug then
		ChatFrame1:AddMessage('ATSW Debug: ' .. (Message or 'nil'))
	end
end

local Key = {
	Ctrl = function()
		return IsControlKeyDown()
	end,
	Shift = function()
		return IsShiftKeyDown()
	end,
	Alt = function()
		return IsAltKeyDown()
	end
}

local Delayed										= false
ATSW_InTime									= 0

-- Game information get functions

local function GetCraftCaption()
	local Skill, Rank, MaxRank, Name
	
	if TradeSkill	then		Skill, Rank, MaxRank = GetTradeSkillLine()
						else		Skill 						= GetCraftName()
									_, Rank, MaxRank 	= GetCraftDisplaySkillLine()	end
	
	if ATSW_ProfessionExists(Skill) then
		Name = Skill
	else
		Name = LastCastName
	end
	
	return Name, Rank, MaxRank
end

local function GetCraftCount()
	if TradeSkill	then	return GetNumTradeSkills()
						else	return GetNumCrafts() end
end

local function GetFirstCraft()
	if TradeSkill	then	return GetFirstTradeSkill()
						else	local _, _, Type = GetCraftInfo(1)
								return 1 + (Type == 'header' and 1 or 0) end
end

local function GetCraftNameType		(Index)
	local Name, Type, SubName
	
	if TradeSkill	then	Name, Type = GetTradeSkillInfo(Index)
						else	Name, SubName, Type = GetCraftInfo(Index) end
	
	return Name, SubName, Type
end

local function GetCraftLink					(Index)
	if TradeSkill	then	return GetTradeSkillItemLink(Index)
						else	return GetCraftItemLink(Index) end
end

ATSW_AtlasIDCache = {}

local function CraftIDtoAtlasID(ID, Enchants)
	if ATSW_AtlasIDCache[ID] then
		return ATSW_AtlasIDCache[ID]
	end
	
	local DB = GetSpellInfoVanillaDB or GetSpellInfoAtlasLootDB
	local Table
	
	if Enchants then
		Table = DB['enchants']
	else
		Table = DB['craftspells']
	end
	
	if Table then
		for I, Value in pairs(Table) do
			local Item = Value.craftItem or Value.item
			
			if Item and ID and Item == ID then
				ATSW_AtlasIDCache[ID] = I
				
				return I
			end
		end
	end
end

local function GetCraftTexture			(Index)
	local Icon
	local DB = GetSpellInfoVanillaDB or GetSpellInfoAtlasLootDB
	
	if DB then
		local ID = ATSW_LinkToID(GetCraftLink(Index))
		local AtlasID = CraftIDtoAtlasID(ID, not TradeSkill)
		local Info = DB['enchants'][AtlasID] or DB['craftspells'][AtlasID]
		
		Icon = Info and (Info['icon'] or GetItemTexture(Info['craftItem']))
	end
	
	if not Icon then
		if TradeSkill	then	Icon = GetTradeSkillIcon(Index)
							else	Icon = GetCraftIcon(Index) end
	end
	
	return Icon
end

function ATSW_GetCraftTexture			(Index)
	return GetCraftTexture(Index)
end

local function GetCraftMinMax				(Index)
	local Min, Max
	
	if TradeSkill	then	Min, Max = GetTradeSkillNumMade(Index)
						else	Min, Max = 1, 1 end
	
	return Min, Max
end

local function GetCraftCooldown			(Index)
	if TradeSkill	then	return GetTradeSkillCooldown(Index) end
end

local function GetReagentCount			(Index)
	if TradeSkill	then	return GetTradeSkillNumReagents(Index)
						else	return GetCraftNumReagents(Index) end
end

-- 校验索引是否指向当前打开的商业技能/附魔列表里的有效配方行，带材料序号时顺带校验材料存在。
-- ATSW_GetPositionFromGame 在列表里找不到配方时会兜底返回上次扫描缓存的位置，列表变化后
-- 该位置可能越界或指向标题行，直接调 SetTradeSkillItem/SetCraftItem 会报 INVALID ... ITEM。
function ATSW_IsValidCraftIndex(Index, ReagentIndex)
	if not Index then
		return false
	end
	
	local Name, _, Type = GetCraftNameType(Index)
	
	if not Name or Type == "header" then
		return false
	end
	
	if ReagentIndex and GetReagentCount(Index) < ReagentIndex then
		return false
	end
	
	return true
end

local function GetCraftInformation		(Index)
	local Name, SubName, Type, Available, Expanded, Action, TrainingCost, RequiredLevel
	
	if TradeSkill	then	Name, 				 Type, Available, Expanded, Action 								= GetTradeSkillInfo(Index)
						else	Name, SubName, Type, Available, Expanded, TrainingCost, RequiredLevel	= GetCraftInfo(Index) end
	
	return Name, SubName, Type, Available, Expanded, Action or TrainingCost, RequiredLevel
end

local function GetCraftData				(Index)
	local Name, SubName, Type, Available, Expanded, ActionOrTrainingCost, RequiredLevel = GetCraftInformation(Index)
	local Min, Max = GetCraftMinMax(Index)
	
	return 	Name, SubName, Type,
				GetCraftTexture		(Index),
				GetCraftLink			(Index),
				Min, Max,
				GetCraftCooldown	(Index),
				GetReagentCount	(Index),
				ActionOrTrainingCost,
				RequiredLevel
end

local function GetReagentInformation	(Index, ReagentIndex)
	if TradeSkill	then	return GetTradeSkillReagentInfo(Index, ReagentIndex)
						else	return GetCraftReagentInfo(Index, ReagentIndex) end
end

local function GetReagentLink			(Index, ReagentIndex)
	if TradeSkill	then	return GetTradeSkillReagentItemLink(Index, ReagentIndex)
						else	return GetCraftReagentItemLink(Index, ReagentIndex) end
end

local function GetReagentData			(Index, ReagentIndex)
	local Name, Texture, Amount, PlayerAmount = GetReagentInformation(Index, ReagentIndex)
	local Link = GetReagentLink(Index, ReagentIndex)
	
	return Name, Texture, Amount, PlayerAmount, Link
end

local function GetCraftRequirements	(Index)
	if TradeSkill	then	return GetTradeSkillTools(Index)
						else	return GetCraftSpellFocus(Index) end
end

local function SelectCraftItem				(Index)
	if TradeSkill	then	return SelectTradeSkill(Index)
						else	return SelectCraft(Index) end
end

local function Craft							(Index, Amount)
	if TradeSkill	then	DoTradeSkill(Index, Amount)
						else	DoCraft(Index) end
end

local function Profession()
	return ATSW_Profession[realm] and ATSW_Profession[realm][player]
end

local function RecipeSelected()
	return ATSW_SelectedRecipe[realm][player][Profession()]
end

function ATSW_RecipeSelected()
	return RecipeSelected()
end

local function Recipes(Prof)
	return ATSW.Recipes[realm][player][Prof or Profession()]
end

local function RecipesSize(Value)
	if tonumber(Value) and Profession() then
		ATSW.RecipesSize[realm][player][Profession()] = Value
	else
		return ATSW.RecipesSize[realm][player][Value or Profession()] or 0
	end
end

local function Recipe(I, Prof)
	return Recipes(Prof or Profession() )[I]
end

function ATSW_Recipe(I)
	return Recipe(I)
end

local function AddRecipe(Index)
	local Size = RecipesSize() + 1
	
	if Size > table.getn(Recipes()) then
		for I = 1, ATSW_TABLE_CREATION_SIZE do
			table.insert(Recipes(),
								{	
									Name 			= nil,
									SubName		= nil,
									Type 			= nil,
									Texture 		= nil,
									Position 		= nil,
									Link 				= nil,
									ProductMin 	= 0,
									ProductMax 	= 0,
									Cooldown 		= nil,
									Reagents		= {},
									ReagentsSize 	= 0,
									TrainingCost	= 0,
									RequiredLevel	= nil
								})
			
			for RI = 1, MAX_TRADE_SKILL_REAGENTS do
				table.insert(Recipe(Size-1+I).Reagents, 
								{
									Name 			= nil,
									Texture			= nil,
									Amount			= 0,
									PlayerAmount	= 0,
									Link				= nil
								})
			end
		end
	end
	
	local R = Recipe(Size)
	
	R.Name, 		R.SubName, 		R.Type, 			R.Texture, 	R.Link, 	R.ProductMin, 	R.ProductMax,
	R.Cooldown, 	R.ReagentsSize, 	R.TrainingCost, 	R.RequiredLevel = GetCraftData(Index)
	R.Position = Index
	
	for I = 1, R.ReagentsSize do
		Rt = R.Reagents[I]
		
		Rt.Name, Rt.Texture, Rt.Amount, Rt.PlayerAmount, Rt.Link = GetReagentData(Index, I)
	end
	
	if R.Cooldown then
		R.Cooldown = GetTime() + R.Cooldown
	end
	
	RecipesSize(Size)
end

local function RecipesSorted()
	return ATSW.RecipesSorted[realm][player][Profession()]
end

local function RecipesSortedSize(Value)
	if Value and Profession() then
		ATSW.RecipesSortedSize[realm][player][Profession()] = Value
	end
	
	return ATSW.RecipesSortedSize[realm][player][Profession()] or 0
end

local function RecipeSorted(I)
	return RecipesSorted()[I]
end

local function AddRecipeSorted(R)
	local Size = RecipesSortedSize() + 1
	
	if Size > table.getn(RecipesSorted()) then
		for I = 1, ATSW_TABLE_CREATION_SIZE do
			table.insert(RecipesSorted(), nil )
		end
	end
	
	RecipesSorted()[Size] = R
	RecipesSortedSize(Size)
end

-- Wrap functions with smaller names for easy access from code

local function NeedToUpdate()
	return ATSW_NeedToUpdate[realm][player][Profession()]
end

local function SetNeedToUpdate(Prof, Value)
	if Value == nil then Value = true end
	
	if Prof then
		ATSW_NeedToUpdate[realm][player][Prof] = Value
	else
		for I in pairs(ATSW_NeedToUpdate[realm][player]) do
			ATSW_NeedToUpdate[realm][player][I] = Value
		end
	end
end

local function PreviousRecipes(Prof)
	return ATSW_PreviousRecipes[realm][player][Prof or Profession()]
end

local function PreviousRecipesSize(Prof)
	return table.getn(PreviousRecipes(Prof or Profession()) or {})
end

local function PreviousRecipe(I)
	return PreviousRecipes()[I]
end

local function SortBy()
	return ATSW_SortBy[realm][player][Profession()]
end

local function SearchString()
	return ATSW_SearchString[realm][player][Profession()]
end

local function SetSearchString(Text)
	ATSW_SearchString[realm][player][Profession()] = Text
end

local function ScrollOffset()
	return ATSW_ScrollOffset[realm][player][Profession()]
end

local function Contracted()
	return ATSW_ContractedCategories[realm][player][Profession()][SortBy()]
end

function ATSW_Contracted()
	return Contracted()
end

local function SubClass()
	return ATSW_SubClassFilter[realm][player][Profession()]
end

local function InvSlot()
	return ATSW_InvSlotFilter[realm][player][Profession()]
end

local function SetSubClass(Value)
	if Profession() then
		ATSW_SubClassFilter[realm][player][Profession()] = Value
	end
end

local function SetInvSlot(Value)
	if Profession() then
		ATSW_InvSlotFilter[realm][player][Profession()] = Value
	end
end

local function Tasks(Prof)
	return ATSW_Tasks[realm][player][Prof or Profession()]
end

local function TasksSize(Prof)
	return table.getn(Tasks(Prof or Profession()) or {})
end

local function Task(I, Prof)
	return Tasks(Prof or Profession())[I]
end
	
local function DoTaskExist(Name, Prof)
	for I, V in pairs(Tasks(Prof or Profession())) do
		if V.Name == Name then
			return I
		end
	end
end

local function NoTasks()
	if ATSW_Tasks and ATSW_Tasks[realm] and ATSW_Tasks[realm][player] then
		local TotalAmount = 0
		
		for I in pairs(ATSW_Tasks[realm][player]) do
			TotalAmount = TotalAmount + TasksSize(I)
		end
		
		return TotalAmount == 0
	else
		return true
	end
end

local function NecessaryReagents()
	return ATSW_NecessaryReagents[realm][player]
end

local function NecessaryReagentsSize()
	return table.getn(NecessaryReagents())
end

local function NecessaryReagent(I)
	return NecessaryReagents()[I]
end

local function ResetNecessaries()
	for I = 1, NecessaryReagentsSize() do
		table.remove(NecessaryReagents(), NecessaryReagentsSize()+1-I)
	end
end

function ATSW_ShowAttributes(Value)
	if Value ~= nil and Profession() then
		ATSW_Attributes[realm][player][Profession()] = Value
		
		if SearchString() ~= '' then
			ATSW_GetRecipesSorted(true)
		end
	else
		return ATSW_Attributes[realm][player][Profession()]
	end
end

-- Sound (Open/Close) management functions and reading of last casted spell

Original_PlaySound = PlaySound

local function Stub() end

local Original_CastSpellByName = CastSpellByName
local function MyCastSpellByName(Name, OnSelf)
	local Storage = PlaySound
	
	LastCastName = Name
	
	PlaySound = Stub	
	Original_CastSpellByName(Name, OnSelf)
	PlaySound = Storage
end
CastSpellByName = MyCastSpellByName

local Original_CastSpell = CastSpell
local function MyCastSpell(spellID, spellbookType)
	
	local Storage = PlaySound
	
	LastCastName = GetSpellName(spellID, spellbookType)
	
	PlaySound = Stub
	Original_CastSpell(spellID, spellbookType)
	PlaySound = Storage
end
CastSpell = MyCastSpell

local function GetNameFromTooltip(Slot)
	ATSWActionNameTooltip:SetParent(UIParent)
	ATSWActionNameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
	ATSWActionNameTooltip:SetAction(Slot)
	
	return ATSWActionNameTooltipTextLeft1:GetText()
end

local Original_UseAction = UseAction
local function MyUseAction(Slot, CheckCursor, OnSelf)
	local Storage = PlaySound
	
	LastCastName = GetNameFromTooltip(Slot)
	
	PlaySound = Stub
	Original_UseAction(Slot, CheckCursor, OnSelf)
	PlaySound = Storage
end
UseAction = MyUseAction

-- Craft delay detection functions

local Original_PickupContainerItem = PickupContainerItem
local function MyPickupContainerItem(Bag, Slot)
	Processing.Delay = GetTime()
	Original_PickupContainerItem(Bag, Slot)
end
PickupContainerItem = MyPickupContainerItem

local Original_BindEnchant = BindEnchant
local function MyBindEnchant()
	Processing.Delay = GetTime()
	Original_BindEnchant()
end
BindEnchant = MyBindEnchant

local Original_ReplaceEnchant = ReplaceEnchant
local function MyReplaceEnchant()
	Processing.Delay = GetTime()
	Original_ReplaceEnchant()
end
ReplaceEnchant = MyReplaceEnchant

local Original_ReplaceTradeEnchant = ReplaceTradeEnchant
local function MyReplaceTradeEnchant()
	Processing.Delay = GetTime()
	Original_ReplaceTradeEnchant()
end
ReplaceTradeEnchant = MyReplaceTradeEnchant

-- Getting information from craft list functions

local function GetRecipeID(Name)
	if Name then
		return ATSW_LinkToID(Recipe(ATSW_GetRecipePosition(Name)).Link)
	end
end

local function GetTradeSkillsPosition(Name)
	for I = 1, GetCraftCount() do
		if GetCraftNameType(I) == Name then
			return I
		end
	end
	
	return false
end

local function IsInTradeSkills(Name)
	return GetTradeSkillsPosition(Name) ~= false
end

local function DropDownFilterPass(Name)
	return not (SubClass() > 0 or InvSlot() > 0) or IsInTradeSkills(Name)
end

local function SubNameToString(SubName)
	return SubName and SubName ~= '' and ('     ' .. Color.GREY .. '(' .. SubName .. ')|r') or ''
end

function ATSW_SubNameToString(SubName)
	return SubNameToString(SubName)
end

local function SubNameToName(Name)
	if Name then
		local LName
		local _, _, SubName = string.find(Name, '%s%s%s%(+(.+)%)+')
		
		-- Triple space means SubName is in Name
		local TripleSpace = string.find(Name, '%s%s%s')
		
		if TripleSpace then
			LName = string.sub(Name, 1, TripleSpace - 1)
		else
			LName = Name
		end
		
		return LName, SubName
	end
end

local function RecipePosition(Name, List, ListSize)
	if Name and ListSize > 0 then
		local LName, SubName = SubNameToName(Name)
		
		if SubName == '' then
			SubName = nil
		end
		
		for I = 1, ListSize do
			local R = List[I]
			
			if R.Name == LName and (SubName and R.SubName == SubName or SubName == nil) then
				return R.Position
			end
		end
	end
end

local function GetRecipePosition(Name, Prof)
	if Prof == nil then
		Prof = Profession()
	end
	
	return RecipePosition(Name, Recipes(Prof), RecipesSize(Prof))
end

function ATSW_GetRecipePosition(Name, Prof)
	return GetRecipePosition(Name, Prof)
end

local function GetRecipeSortedPosition(Name)
	return RecipePosition(Name, RecipesSorted(), RecipesSortedSize())
end

local function GetPositionFromGame(Name)
	local I = 0
	local GName, GSubName
	
	local Name, SubName = SubNameToName(Name)
	
	repeat
		I = I + 1
		
		GName, GSubName = GetCraftNameType(I)

		if GName and GName == Name and (SubName and GSubName == SubName or SubName == nil) then
			return I
		end
	until not GName
	
	if not GName then
		return GetRecipePosition(Name)
	end
end

function ATSW_GetPositionFromGame(Name)
	return GetPositionFromGame(Name)
end

function ATSW_GetContractedPos(Name)
    for I = 1, table.getn(Contracted()) do
        if Contracted()[I] == Name then
            return I
        end
    end
end

function ATSW_IsContracted(Name)
	return ATSW_GetContractedPos(Name)
end

local function IsExpanded(Name)
	return not ATSW_IsContracted(Name)
end

function ATSW_GetProfessionTexture(Name)
	return GetProfessionTexture(Name)
end

local function IsBeastTraining()
	return GetProfessionTexture(Profession()) == Icon('Ability_Hunter_BeastCall02')
end

local function IsSmelting()
	return GetProfessionTexture(Profession()) == Icon('Spell_Fire_FlameBlades')
end

local function IsPoisons()
	return GetProfessionTexture(Profession()) == Icon('Trade_BrewPoison')
end

local function IsEnchanting()
	return GetProfessionTexture(Profession()) == Icon('Trade_Engraving')
end

local function ClassColorize(Name)
	local Color = {
		['Druid']		= '|cffff7c0a',
		['Hunter']	= '|cffaad372',
		['Mage']		= '|cff3fc7eb',
		['Paladin']	= '|cfff48cba',
		['Priest']	= '|cffffffff',
		['Rogue']	= '|cfffff468',
		['Shaman']	= '|cff0070dd',
		['Warlock']	= '|cff8788ee',
		['Warrior']	= '|cffc69b6d'
	}

	for I in ipairs(ATSW_Characters[realm]) do
		if ATSW_Characters[realm][I].Name == Name then
			return Color[ATSW_Characters[realm][I].Class] .. Name .. '|r'
		end
	end
	
	return Name
end

local function GetCraftingTime(Name, Amount)
	local ID = GetRecipeID(Name)
	local Cost = ATSW_TimeCost[ID]
	local DB = GetSpellInfoVanillaDB or GetSpellInfoAtlasLootDB
	
	if Cost then
		return Cost*(Amount or 0)
	elseif DB then
		local AtlasID = CraftIDtoAtlasID(ID)
		
		if AtlasID then
			local castTime = DB['craftspells'][AtlasID]['castTime']
			
			return castTime
		end
	end
end

ATSW_TEST = 9000

function ATSW_TooltipSetSkill(Tooltip, Index)
	-- 索引无效（过期缓存位置）时直接放弃，避免客户端报 INVALID TRADE SKILL ITEM
	if not ATSW_IsValidCraftIndex(Index) then
		return
	end
	
	if ATSW_TradeSkill() then
		Tooltip:SetTradeSkillItem(Index)
	else
		Tooltip:SetCraftSpell(Index)
	end
end

-- Main code section

local function SetSizeAndPoints(S, Width, Point, RelativePoint, RelativeTo, X, Y)
	S:SetJustifyH('LEFT')
	S:SetJustifyV('TOP')
	S:SetWidth(Width)
	S:SetPoint(Point, RelativePoint, RelativeTo, X, Y)
end

local HelpItems = 0

local function AddHelpItem(Parameter, Description, NoReplace)
	local C = HelpItems
	
	if not Parameter 	then Parameter 	= '' end
	if not Description 	then Description	= '' end
	
	if not NoReplace then
		Parameter 	= string.gsub(Parameter, '|c', '|cffFFD100')
		Description = string.gsub(Description, '|c', '|cffFFD100')
	end
	
	local Frame 				= ATSWSearchHelpFrame
	
	local S = Frame:CreateFontString('ATSWHelp' .. C + 1, 'ARTWORK', 'GameFontHighlightSmall')
	
	if C == 0 then
		SetSizeAndPoints(S, 120, 'TOPLEFT', ATSWSearchHelpFrame, 'TOPLEFT', 20, -50)
	else
		SetSizeAndPoints(S, 120, 'TOPLEFT', 'ATSWHelp' .. C, 'BOTTOMLEFT', 0, -15)
	end
	
	S:SetText(Parameter)
	
	local D = Frame:CreateFontString('ATSWHelp' .. C + 1 .. 'Description', 'ARTWORK', 'GameFontHighlightSmall')
	
	SetSizeAndPoints(D, 265, 'TOPLEFT', S, 'TOPRIGHT')
	
	D:SetText(Description)
	
	HelpItems = C + 1
end

function ATSW_CreateListButtons()
	-- Create recipe buttons
	for R = 1, ATSW_RECIPES_DISPLAYED do
		local B = CreateFrame('Button', 'ATSWRecipe' .. R, ATSWFrame, 'ATSWRecipeButtonTemplate')
		
		B.XOffset 	= 22
		B.Position	= nil
		B.Name 	= nil
		B.Type 		= nil
		B.Possible 	= nil
		B.Text		= nil
		
		if R == 1 then
			B:SetPoint	('TOP', ATSWFrame, 'TOP', 0, -77)
		else
			B:SetPoint	('TOP', 'ATSWRecipe' .. R - 1, 'BOTTOM', 0, 0)
		end
		
		B:SetWidth	(ATSWListScrollFrame:GetWidth())
		B:SetHeight	(ATSW_TRADESKILL_HEIGHT)
		
		B:SetPoint		('LEFT', ATSWFrame, 'LEFT', B.XOffset, 0)
	end
	
	-- Set highlight frame
	ATSWHighlight:SetHeight(ATSW_TRADESKILL_HEIGHT)
	ATSWHighlightMouseOver:SetHeight(ATSW_TRADESKILL_HEIGHT)
	
	-- Create tool buttons
	for T = 1, ATSW_TOOLS_DISPLAYED do
		local B = CreateFrame('Button', 'ATSWTool' .. T, ATSWFrame, 'ATSWToolTemplate')
		
		if T == 1 then
			B:SetPoint	('LEFT', ATSWToolsLabel, 'RIGHT', 4, 0)
		else
			B:SetPoint	('LEFT', 'ATSWTool' .. T - 1, 'RIGHT', 6, 0)
		end
	end
	
	-- Create reagent buttons
	local Columns = 4
	local Row, Column
	
	for R = 1, MAX_TRADE_SKILL_REAGENTS do
		local B 	= CreateFrame('Button', 'ATSWReagent' .. R, ATSWFrame, 'ATSWReagentTemplate')
		
		Row 		= math.ceil(R/Columns)
		Column 	= R - ((Row - 1) * Columns)
		
		if Column == 1 then
			if Row == 1 then
				B:SetPoint	('TOPLEFT', ATSWReagentsLabel, 'BOTTOMLEFT', 11, -6)
			else
				B:SetPoint	('TOPLEFT', 'ATSWReagent' .. 1 + (Columns * (math.max(Row - 2, 0))) , 'BOTTOMLEFT', 0, -30)
			end
		else
			B:SetPoint		('LEFT', 'ATSWReagent' .. R - 1, 'RIGHT', 55, 0)
		end
		
		B:SetID(R)
	end
	
	-- Create task buttons
	for T = 1, ATSW_TASKS_DISPLAYED do
		local B 	= CreateFrame('Button', 'ATSWTask' .. T, ATSWFrame, 'ATSWTaskButtonTemplate')
		
		if T == 1 then
			B:SetPoint	('TOPLEFT', ATSWHorizontalBar1Left, 'TOPLEFT', 6, -14)
		else
			B:SetPoint	('TOPLEFT', 'ATSWTask' .. T - 1, 'BOTTOMLEFT', 0, -5)
		end
		
		B:SetWidth	(314)
		B:SetHeight	(ATSW_TRADESKILL_HEIGHT)
		
		local D = CreateFrame('Button', 'ATSWTask' .. T .. 'DeleteButton', B, 'UIPanelCloseButton')
		
		D:SetWidth	(18)
		D:SetHeight	(18)
		D:SetPoint		('RIGHT', ATSWTaskScrollFrame, 'RIGHT', -3, 0)
		D:SetPoint		('TOP', B, 'TOP', 0, 1)
		D:SetScript	('OnClick', ATSW_TaskDeleteOnClick)
	end
	
	-- Create search help strings
	AddHelpItem(ATSW_HELP_REAGENT, 				ATSW_HELP_REAGENT_DESC)
	AddHelpItem(ATSW_HELP_LEVEL, 					ATSW_HELP_LEVEL_DESC)
	AddHelpItem(ATSW_HELP_QUALITY, 				ATSW_HELP_QUALITY_DESC)
	AddHelpItem(ATSW_HELP_POSSIBLE, 				ATSW_HELP_POSSIBLE_DESC)
	AddHelpItem(ATSW_HELP_POSSIBLE_TOTAL, 	ATSW_HELP_POSSIBLE_TOTAL_DESC)
	AddHelpItem()
	AddHelpItem()
	AddHelpItem()
	AddHelpItem(ATSW_HELP_QNAMES, 				ATSW_HELP_QNAMES_DESC, 	true)
	AddHelpItem(ATSW_HELP_QCOLORS, 				ATSW_HELP_QCOLORS_DESC,	true)
end

local function UnregisterEvents(Frame, ...)
	for _, Event in ipairs(arg) do
		Frame:UnregisterEvent(Event)
	end
end

local function RegisterEvents(Frame, ...)
	for _, Event in ipairs(arg) do
		Frame:RegisterEvent(Event)
	end
end

function ATSW_OnLoad()
	-- Unregister events from Blizzard professions frames
	EnableAddOn('Blizzard_TradeSkillUI')
	EnableAddOn('Blizzard_CraftUI')
	LoadAddOn('Blizzard_TradeSkillUI')
	LoadAddOn('Blizzard_CraftUI')
	
	UnregisterEvents(TradeSkillFrame,
		'SKILL_LINES_CHANGED',
		'PLAYER_ENTERING_WORLD',
		'TRADE_SKILL_UPDATE',
		'UNIT_PORTRAIT_UPDATE')
	
	UnregisterEvents(CraftFrame,
		'SKILL_LINES_CHANGED',
		'CRAFT_UPDATE',
		'UNIT_PORTRAIT_UPDATE',
		'SPELLS_CHANGED',
		'UNIT_PET_TRAINING_POINTS')
	
	UnregisterEvents(UIParent,
		'TRADE_SKILL_SHOW',
		'TRADE_SKILL_CLOSE',
		'CRAFT_SHOW',
		'CRAFT_CLOSE')
	
	-- Register slash commands
    SLASH_ATSW1 				= '/atsw'
    SLASH_ATSW2 				= '/advancedtradeskillwindow'
    SlashCmdList['ATSW'] 	= ATSW_Command
	
	-- Register events
	RegisterEvents(ATSWFrame,
		'TRADE_SKILL_SHOW',
		'TRADE_SKILL_CLOSE',
		'CRAFT_SHOW',
		'CRAFT_CLOSE',
		'UNIT_PET',
		'UNIT_PET_TRAINING_POINTS',
		'BAG_UPDATE',
		'BANKFRAME_OPENED',
		'BANKFRAME_CLOSED',
		'MERCHANT_SHOW',
		'MERCHANT_UPDATE',
		'MERCHANT_CLOSED',
		'AUCTION_HOUSE_CLOSED',
		'AUCTION_HOUSE_SHOW',
		'PLAYERBANKSLOTS_CHANGED',
		'PLAYERBANKBAGSLOTS_CHANGED',
		'PLAYER_ENTERING_WORLD',
		'CHAT_MSG_SYSTEM',
		'CHAT_MSG_SKILL',
		'CHAT_MSG_LOOT',
		'CVAR_UPDATE',
		'UI_ERROR_MESSAGE')
	
	-- Attach name sort checkbox
	ATSWNameSortCheckbox:SetPoint('LEFT', ATSWDifficultySortCheckbox, 'RIGHT', ATSWDifficultySortCheckboxText2:GetWidth()+5, 0)
	
	-- Create side tabs
	for T = 1, ATSW_MAX_TRADESKILL_TABS do
		local CB = CreateFrame('CheckButton', 'ATSWFrameTab' .. T, ATSWFrameSideTabsFrame, 'ATSWTabTemplate')
		
		if T == 1 then
			CB:SetPoint('TOPLEFT', ATSWFrameSideTabsFrame, 'TOPRIGHT', 0, -36)
		else
			CB:SetPoint('TOPLEFT', 'ATSWFrameTab' .. T - 1, 'BOTTOMLEFT', 0, -17)
		end
	end
	
	-- Fix Blizzard GameTooltip edges insets (from 5 to 4)
	local R, G, B, A = GameTooltip:GetBackdropColor()
	
	GameTooltip:SetBackdrop({bgFile=[[Interface\Tooltips\UI-Tooltip-Background]], edgeFile=[[Interface\Tooltips\UI-Tooltip-Border]], tile = true, edgeSize = 16, tileSize = 16, insets = {left = 4, right = 4, top = 4, bottom = 4}})
	GameTooltip:SetBackdropColor(R, G, B, A)
	
	-- Fix a bug which shows error 'skillOffset is nil' on line 171 of Blizzard_TradeSkillUI.lua (modified by Turtle-WoW team)
	FauxScrollFrame_SetOffset(TradeSkillListScrollFrame, 0)
	
	ATSWFrame:SetMovable(true)
	ATSWFrame:EnableMouse(true)
	ATSWFrame:RegisterForDrag('LeftButton')
	ATSWFrame:SetScript('OnDragStart', function() this:StartMoving() end)
	ATSWFrame:SetScript('OnDragStop',
		function()
			this:StopMovingOrSizing()
			-- 保存拖动后的位置，重载/重开后仍生效
			if not ATSW_FramePosition then ATSW_FramePosition = {} end
			ATSW_FramePosition.main = { x = this:GetLeft(), y = this:GetTop() - UIParent:GetTop() }
		end
	)
end

local function SetDropDownFilter(SubClass, InvSlot)
	ATSWFrame:UnregisterEvent(	'TRADE_SKILL_UPDATE'	)
	
	local SubClasses 	= table.getn({GetTradeSkillSubClasses()})
	local InvSlots 	= table.getn({GetTradeSkillInvSlots()})
	
	if SubClasses < SubClass then
		SubClass = 0
	end
	
	if InvSlots < InvSlot then
		InvSlot = 0
	end
	
	SetTradeSkillSubClassFilter		(	SubClass, 1, 1					)
	SetTradeSkillInvSlotFilter			(	InvSlot, 1, 1					)
	
	if ATSWFrame.UpdateIsRegistered then
		ATSWFrame:RegisterEvent	(	'TRADE_SKILL_UPDATE'	)
	end
end

function ATSW_UpdateListScroll()
	FauxScrollFrame_Update			(	ATSWListScrollFrame, RecipesSortedSize(),
													ATSW_RECIPES_DISPLAYED,
													ATSW_TRADESKILL_HEIGHT,
													nil, nil, nil, ATSWHighlight, 300, 300	)
end

function ATSW_UpdateTaskListScroll()
	FauxScrollFrame_Update			(	ATSWTaskScrollFrame, TasksSize(),
													ATSW_TASKS_DISPLAYED,
													ATSW_TRADESKILL_HEIGHT-1			)
end

local function SetSortBy(Sort)
	if Profession() then
		ATSW_SortBy[realm][player][Profession()] = Sort
		ATSW_GetRecipesSorted(true)
	end
end

local OldCraftCount = 0

local function WhatReagentIsLackingData()
	for I = 1, MAX_TRADE_SKILL_REAGENTS do
		local Button 				= _G['ATSWReagent' .. I]
		local ButtonTexture 	= _G['ATSWReagent' .. I .. 'Texture']
		
		if Button:IsVisible() then
			if not (ButtonTexture:GetTexture() and Button.Name and Button.Link) then
				return Button
			end
		end
	end
	
	return false
end

function ATSW_OnUpdate(TimePassed)
	-- Loading recipes
	
    if ATSWFrame:IsVisible() or ATSWCSFrame:IsVisible() then
		-- Update frame if trade skill count is changed
		if ATSWFrame.UpdateIsRegistered then
			if NeedToUpdate() then
				ATSW_UpdateFrame()
			end
			
			if 	UpdateCount > 0 then
				if IsBeastTraining() then
					ATSW_UpdateFrame()
				end
				
				ATSW_UpdateStatusBarRank()
				
				UpdateCount = 0
			end
		else
			 -- This check is necessary for fast initial loading while data is not in the game cache
			if OldCraftCount ~= GetCraftCount() then
				OldCraftCount = GetCraftCount()
				ATSW_UpdateFrame()
			end
		end
		
		-- Update missing recipes data
		if RecipesDataIsComplete > -1 then
			if RecipesDataTries > 0 then
				RecipesDataTries = RecipesDataTries - 1
			else
				local Complete = false
				
				SetDropDownFilter(0, 0) -- It is needed for congruence of Recipe index and Game index
				
				if RecipesSize() ~= GetCraftCount() then
					Complete = true
				else
					for I = 1, RecipesSize() do
						local R = Recipe(I)
						
						if R.Type ~= 'header' then
							if not (R.Name and R.Texture) then
								local Name 	= GetCraftNameType(I)
								local Texture	= GetCraftTexture(I)
								
								if Name and Texture then
									Complete = true
								end
							end
						end
					end
				end
				
				SetDropDownFilter(SubClass(), InvSlot())
				
				if Complete then
					RecipesDataIsComplete = -1
					ATSW_GetRecipes(true)
					ATSW_SelectRecipe(RecipeSelected())
				else
					RecipesDataIsComplete 	= RecipesDataIsComplete + 2
					RecipesDataTries 			= RecipesDataIsComplete
				end
			end
		end
		
		-- Update missing reagents data
		if not ReagentsDataIsComplete and RecipeSelected() then
			local B = WhatReagentIsLackingData()
			
			if B then
				local Name, Texture, _, _, Link = GetReagentData(B.RecipeIndex, B.ReagentIndex)
				
				ReagentsDataIsComplete = (Name and Texture and Link) ~= nil
				
				if ReagentsDataIsComplete then
					for I = 1, RecipesSize() do
						local R = Recipe(I)
						
						for J = 1, R.ReagentsSize do
							local Rt = R.Reagents[J]
							
							Rt.Name, Rt.Texture, Rt.Amount, Rt.PlayerAmount, Rt.Link = GetReagentData(I, J)
						end
					end
					
					ATSW_SelectRecipe(RecipeSelected())
				end
			end
		end
		
		-- Update scroll offset
		if ScrollOffset() and ATSWListScrollFrameScrollBar:GetValue() ~= ScrollOffset() then
			ATSWListScrollFrameScrollBar:SetValue(ScrollOffset())
		end
		
		-- Update cooldowns
		if GetTime() - 1 >= CooldownUpdateTime then
			-- Set cooldowns for recipe buttons
			for I = 1, ATSW_RECIPES_DISPLAYED do
				local Button = _G['ATSWRecipe' .. I]
				local ButtonSubText = _G['ATSWRecipe' .. I .. 'SubText']
				
				if Button:IsVisible() and Button.Position and not IsBeastTraining() then
					ButtonSubText:SetText(ConvertCooldown(Recipe(Button.Position).Cooldown) or '')
				end
			end
			
			-- Set cooldowns for task buttons
			for I = 1, ATSW_TASKS_DISPLAYED do
				local Button = _G['ATSWTask' .. I]
				
				if Button:IsVisible() and Button.Position then
					Button:SetText(Button.Text .. (ConvertCooldown(Recipe(Button.Position).Cooldown) or ''))
				end
			end
			
			-- Set cooldown for schematic
			if ATSWRecipeCooldown.Cooldown then
				local CD = ConvertCooldown(ATSWRecipeCooldown.Cooldown, true)
				
				if CD then
					ATSWRecipeCooldown:SetText(COOLDOWN_REMAINING .. ' ' .. CD)
				else
					ATSWRecipeCooldown.Cooldown = nil
					ATSWRecipeCooldown:SetText('')
				end
			end
			
			-- If cooldowns in recipes are expired, then set them to nil and update Create button
			for I = 1, RecipesSize() do
				local R = Recipe(I)
				
				if R.Cooldown and R.Cooldown < GetTime() then
					R.Cooldown = nil
					
					if DoTaskExist(R.Name) or R.Name == RecipeSelected() then
						ATSW_UpdateCreateButton()
					end
				end
			end
			
			CooldownUpdateTime = GetTime()
		end
		
		ATSW_ArmorCraftCompatibility()
    end
	
	-- Progress bar
	
	if ATSWProgressBar.Working then
		local Bar 			= ATSWProgressBar
		local Border 		= ATSWProgressBarBorder
		local Spark 		= ATSWProgressBarSpark
		local Stop			= ATSWProgressBarStop
		local Glow 		= ATSWProgressBarGlow
		local ItemFound
		
		for I = 1, ATSW_TASKS_DISPLAYED do
			local Button 	= _G['ATSWTask' .. I]
		
			if Button.Name == Processing.Recipe then	
				ItemFound = true
				
				if not Bar.TaskItem or Bar.TaskItem ~= Button then
					Bar:		SetParent(Button)
					Bar:		SetPoint('TOPLEFT', Button:GetName(), 'TOPLEFT', -2, 0)
					Bar:		SetFrameLevel(12)
					Border:	SetFrameLevel(13)
					Spark:	SetFrameLevel(14)
					Button:	SetFrameLevel(15)
					
					Bar.TaskItem = Button
				end
				
				break
			end
		end
		
		if ItemFound then
			if not Bar:IsVisible() then
				Bar:			Show()
				
				if Bar.Mode == ATSW_CAST then
					Spark:	Show()
					Stop:	SetParent(Bar)
					Stop:	SetFrameLevel(15)
					Stop:	Show()
				end
			end
		else
			Bar:				Hide()
			Stop:			Hide()
		end
		
		if Bar.Mode == ATSW_CAST then
			if GetTime() < Bar.EndTime then
				Bar:		SetValue(GetTime())
				Spark:	SetPoint('CENTER', Bar, 'LEFT', (1 - (Bar.EndTime - GetTime())/(Bar.EndTime - Bar.StartTime)) * Bar:GetWidth(), -1)
			else
				if IsEnchant(Processing.Texture) then
					Bar.Mode = ATSW_FLASH
				end
			end
			
			local TimeLeft 	= Bar.EndTime - GetTime()
			
			ATSWProgressBarStopSubText:SetText(ShortFormatCooldown(TimeLeft+1, true))
		elseif Bar.Mode == ATSW_FLASH then 		-- Glow appearing
			local Alpha = Glow:GetAlpha() + TimePassed / ATSW_FLASH_TIME
			
			Glow:			SetAlpha(math.min(Alpha, 1))
			
			if Spark:IsVisible() then
				local Min, Max = Bar:GetMinMaxValues()
				
				Bar:		SetValue(Max)
				Stop:	Hide()
				Spark:	Hide()
			end
			
			if Alpha >= 1 then
				Bar.Mode = ATSW_FADEOUT
			end
		elseif Bar.Mode == ATSW_FADEOUT then 	-- Glow disappearing
			local Alpha = Glow:GetAlpha() - TimePassed / ATSW_FADEOUT_TIME
			
			if Alpha > 0 then
				Glow:	SetAlpha(Alpha)
				Bar:		SetAlpha(Alpha)
				
				if Bar:IsVisible() and Task(Bar.TaskItem.TaskIndex).Amount == 1 then
					Bar.TaskItem:SetAlpha(Alpha)
				end
			else
				ATSW_CompleteTask()
				Bar:		Hide()
			end
		end
	end
	
	-- Delay functions
	
	if Delayed and GetTime() > ATSW_InTime then
		ATSW_Delayed()
		Delayed = false
	end
end

function ATSW_Delayed()
end

local function Delay(Function, Time)
	ATSW_Delayed = Function
	ATSW_InTime = GetTime() + Time
	Delayed = true
end

function ATSW_ProfessionExists(Prof)
	if Prof then
		local _, _, _, NumSpells = GetSpellTabInfo(1)
		
		for I in ipairs(Professions) do
			local ProfessionTexture = Icon(Professions[I])
		
			for B = 1, NumSpells do
				local Texture 	= GetSpellTexture	(B, 'BOOKTYPE_SPELL')
				local Name		= GetSpellName		(B, 'BOOKTYPE_SPELL')
				
				if Texture and Texture == ProfessionTexture and string.find(Name, Prof) then
					return true
				end
			end
		end
	end
end

local function GetFirstProfession()
	local _, _, _, NumSpells = GetSpellTabInfo(1)
	
	-- Search spell book by texture
	for I in ipairs(Professions) do
		local ProfessionTexture = Icon(Professions[I])
		
		for B = 1, NumSpells do
			local Texture	= GetSpellTexture	(B, 'BOOKTYPE_SPELL')
			
			if Texture and Texture == ProfessionTexture then
				return GetSpellName(B, 'BOOKTYPE_SPELL')
			end
		end
	end
end

local function ResetTabs()
	for T = 1, ATSW_MAX_TRADESKILL_TABS do
		local Tab = _G['ATSWFrameTab'..T]
		
		if Tab then
			Tab.Name = nil
			
			local NormalTexture = Tab:GetNormalTexture()
			
			if NormalTexture then
				NormalTexture:SetTexture(nil)
			end
		end
	end
end

local function TabExists(Texture)
	for T = 1, ATSW_MAX_TRADESKILL_TABS do
		local Tab = _G['ATSWFrameTab'..T]
		
		if Tab then
			local NormalTexture = Tab:GetNormalTexture()
			
			if NormalTexture then
				local TabTexture = NormalTexture:GetTexture()
				
				if TabTexture and string.lower(TabTexture) == string.lower(Texture) then
					return true
				end
			end
		end
	end
end

local function ChangeSmeltingIcon(Texture)
	if Texture == 'Interface\\Icons\\Spell_Fire_FlameBlades' then
		return 'Interface\\AddOns\\AdvancedTradeSkillWindow2\\Textures\\Smelting'
	end
	
	return Texture
end

function ATSW_ConfigureSkillButtons(Exception)
	local _, _, _, NumSpells = GetSpellTabInfo(1)

	ResetTabs()
	
	-- Iterate tabs
	for T = 1, ATSW_MAX_TRADESKILL_TABS do
		local Tab = _G['ATSWFrameTab' .. T]
		local TabName, TabTexture
		
		-- Iterate professions
		for I in ipairs(Professions) do
			local ProfessionTexture = Icon(Professions[I])
			
			ProfessionTexture = ChangeSmeltingIcon(ProfessionTexture)
			
			if not TabExists(ProfessionTexture) then
				-- Scan spell book for professions
				for B = 1, NumSpells do
					local Texture 	= GetSpellTexture	(B, 'BOOKTYPE_SPELL')
					local Name		= GetSpellName		(B, 'BOOKTYPE_SPELL')
					
					Texture = ChangeSmeltingIcon(Texture)
					
					if Name ~= Exception and Texture and Texture == ProfessionTexture then
						TabName 		= GetSpellName(B, 'BOOKTYPE_SPELL')
						TabTexture 	= Texture
						
						break
					end
				end
				
				if TabTexture then
					break
				end
			end
		end
		
		SetVisible(Tab, TabTexture)
		
		Tab.Name = TabName
		Tab:SetNormalTexture(TabTexture)
	end
	
	if Profession() then
		ATSW_SelectTab(Profession())
	end
end

function ATSW_SelectTab(Name)
	for T = 1, ATSW_MAX_TRADESKILL_TABS do
		local Tab = _G['ATSWFrameTab' .. T]
		
		Tab:SetChecked(Tab.Name == Name)
	end
end

function ATSW_AttachTabsTo(Frame)
	if ATSWFrameSideTabsFrame:GetParent() ~= Frame then
		ATSWFrameSideTabsFrame:SetParent(Frame)
		ATSWFrameSideTabsFrame:ClearAllPoints()
		ATSWFrameSideTabsFrame:SetPoint('TOPLEFT', Frame, 'TOPRIGHT', -59, -28)
		ATSWFrameSideTabsFrame:Show()
	end
end

function ATSW_SwitchToFrame(Frame)
	local function GetFrame(F)
		if 			F == 1 then return ATSWFrame
		elseif 	F == 2 then return ATSWCSFrame end
	end
	
	ATSW_SwitchingFrames = true
	
	if ATSW_SwitchingToMain then
		ATSW_SwitchingToMain = false
	else
		if Frame and not (GetFrame(1):IsVisible() or GetFrame(2):IsVisible()) then
			Original_PlaySound('igCharacterInfoOpen')
		end
	end
	
	for I = 1, 2 do
		local F = GetFrame(I)
		
		if F:IsVisible() and F ~= Frame then
			if Frame == ATSWCSFrame then
				ATSW_SwitchingToEditor = true
			end
			
			HideUIPanel(F)
		end
	end
	
	for I = 1, 2 do
		local F = GetFrame(I)
		
		if not F:IsVisible() and F == Frame then
			ShowUIPanel				(F)
			ATSW_AttachTabsTo	(F)

			-- 用户拖过框架则恢复上次保存的位置，否则走默认贴边逻辑
			local Restored = false

			local function RestorePos(key)
				local pos = ATSW_FramePosition and ATSW_FramePosition[key]
				if not pos or type(pos.x) ~= "number" or type(pos.y) ~= "number" then
					return false
				end
				-- 旧版本曾把 GetTop()（屏幕坐标，恒为正）直接当偏移量存储，
				-- 还原会把框架顶出屏幕外导致"打不开"。合法新值 = GetTop()-UIParent:GetTop() 必 <= 0，
				-- 据此过滤掉历史坏数据，回退到默认贴边逻辑（保证能打开）。
				if pos.y > 0 then
					return false
				end
				local sw, sh = UIParent:GetWidth(), UIParent:GetHeight()
				local x = math.max(0, math.min(pos.x, math.max(0, sw - 50)))
				local y = math.max(-(sh - 50), pos.y)
				F:ClearAllPoints()
				F:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x, y)
				return true
			end

			if ATSW_FramePosition then
				if F == ATSWFrame then
					Restored = RestorePos("main")
				elseif F == ATSWCSFrame then
					Restored = RestorePos("cs")
				end
			end

			if not Restored then
				if not (BlizzMo and ATSWFrame.settings and ATSWFrame.settings.save) then
					if MerchantFrame:IsVisible() then
						local oldCenter = UIParent.center

						UIParent.center = nil
						SetCenterFrame(F)
						UIParent.center = oldCenter
					else
						local oldLeft = UIParent.left

						UIParent.left = nil
						SetLeftFrame(F)
						UIParent.left = oldLeft
					end
				end
			end
		end
	end
	
	if not Frame and Processing.Active then
		Processing.Stop = true
	end
	
	ATSW_SwitchingFrames = false
end

local function LoadAllProfessionsOnce()
	if not LoadingProfessions then
		LoadingProfessions 			= true
		
		local CurrentProfession 	= GetCraftCaption()
		local LastName				=	CurrentProfession
		
		local _, _, _, NumSpells 	= GetSpellTabInfo(1)
		
		ATSWFrame:	UnregisterEvent(	'TRADE_SKILL_SHOW'	)
		ATSWFrame:	UnregisterEvent(	'TRADE_SKILL_CLOSE'	)
		ATSWFrame:	UnregisterEvent(	'CRAFT_SHOW'				)
		ATSWFrame:	UnregisterEvent(	'CRAFT_CLOSE'				)
		
		local OldSound 				= PlaySound
		PlaySound 					= Stub
		
		for I in ipairs(Professions) do
			local ProfessionTexture = Icon(Professions[I])
			
			for B = 1, NumSpells do
				local Texture			= GetSpellTexture	(B, 'BOOKTYPE_SPELL')
				local Name 			= GetSpellName		(B, 'BOOKTYPE_SPELL')
				
				if Name and not string.find(Name, CurrentProfession) and Texture == ProfessionTexture then
					CastSpellByName(Name)
					LastName = Name
					
					break
				end
			end
		end
		
		if LastName ~= CurrentProfession then
			CloseTradeSkill()
			CloseCraft()
			CastSpellByName(CurrentProfession)
		end
		
		PlaySound 						= OldSound
		
		ATSWFrame:	RegisterEvent(	'TRADE_SKILL_SHOW'	)
		ATSWFrame:	RegisterEvent(	'TRADE_SKILL_CLOSE'	)
		ATSWFrame:	RegisterEvent(	'CRAFT_SHOW'				)
		ATSWFrame:	RegisterEvent(	'CRAFT_CLOSE'				)
	end
end

local function ATSW_Show()
	LoadAllProfessionsOnce()
	-- This function will cause all learned professions recipe data to load into the game from the server at once.
	-- After the user chose another profession the recipe data is already in the game to be loaded into the frame.
	
	if not InitializedOnShow then
		ATSW_CreateListButtons()
		
		for I = 1, ATSW_TASKS_DISPLAYED do
			_G['ATSWTask' .. I .. 'DeleteButton']:GetNormalTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
			_G['ATSWTask' .. I .. 'DeleteButton']:GetPushedTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8)
		end
		
		ATSW_ConfigureSkillButtons()
		ATSW_AtlasLoot = ATSW_CheckForAtlasLootLoaded()
		
		InitializedOnShow = true
	end
	
	ATSW_InitializeFrame					()
	ATSW_UpdateCaption					()
	ATSW_ShowSort						()
	ATSW_ShowSearch					()
	ATSW_UpdateBackground			()
	ATSW_SelectTab						(Profession())
	ATSW_ShowAmount					()
	ATSW_ShowAmountMenu			(TradeSkill)
	ATSW_ShowDropDownMenu		(TradeSkill)
	ATSW_ShowReagentsButton		(not IsBeastTraining())
	ATSW_ShowTaskButton				(not IsBeastTraining() and not IsEnchanting())
	SetVisible(ATSWTaskScrollFrame, not IsBeastTraining() and not IsEnchanting())
	ATSW_ShowTrainingPointsMenu	(IsBeastTraining())
	
	ATSWAttributesButton:SetChecked(ATSW_ShowAttributes())
	
	if RecipesSize() > 0 then
		ATSW_GetRecipes()
		ATSW_ShowSelection()
		ATSW_UpdateTasks()
		
		if SortBy() == 'Custom' then
			ATSWCS_FillAllRecipes()
			ATSWCS_Update()
		end
	end
	
	if NoTasks() then
		ResetNecessaries()
	end
	
	ATSW_SwitchToFrame(ATSWFrame)
	
	ATSWUpdaterFrame:Show()
	ATSW_UpdateListScroll()
end

function CloseATSW()
	if ATSW_TradeSkill() then
		CloseTradeSkill()
	else
		CloseCraft()
	end
end

function ATSW_Hide()
	if UIParent:IsVisible() then
		ATSW_SwitchToFrame()
		Original_PlaySound('igCharacterInfoClose')
	end
	
	if ATSW_SwitchingToEditor then
		ATSW_SwitchingToEditor = false
	else
		PlaySound('igCharacterInfoClose')
	end
	
	ATSWUpdaterFrame:Hide()
end

local function InitializeTable(Table, Value, Prof)
	if Prof == nil then
		Prof = Profession()
	end

	if Table 							== nil 	then Table 								= {} 		end
	if Table[realm] 					== nil 	then Table[realm] 						= {} 		end
	if Table[realm][player] 		== nil 	then Table[realm][player] 			= {} 		end
	if Table[realm][player][Prof] == nil 	then Table[realm][player][Prof]	= Value 	end
end

local function InitializeTables()
	local function InitializeContractedCategories()
		local Table = ATSW_ContractedCategories
		
		InitializeTable(Table, {})
		
		if 	Table[realm][player][Profession()]['Category'] == nil 	then
			Table[realm][player][Profession()]['Category'] = {}
		end
		
		if 	Table[realm][player][Profession()]['Custom'] == nil 	then
			Table[realm][player][Profession()]['Custom'] = {}
		end
	end
	
	InitializeTable(ATSW.Recipes, 				{}			)
	InitializeTable(ATSW.RecipesSize, 			0				)
	InitializeTable(ATSW.RecipesSorted, 		{}			)
	InitializeTable(ATSW.RecipesSortedSize, 0				)
	InitializeTable(ATSW_SelectedRecipe, 	nil			)
	InitializeTable(ATSW_Attributes, 			false			)
	InitializeTable(ATSW_NeedToUpdate, 	true			)
	InitializeTable(ATSW_SortBy, 				'Category'	)
	InitializeTable(ATSW_SearchString, 		''				)
	InitializeTable(ATSW_SubClassFilter, 		0				)
	InitializeTable(ATSW_InvSlotFilter, 		0				)
	InitializeTable(ATSW_ScrollOffset, 			0				)
	InitializeTable(ATSW_Amount, 				0				)
	InitializeTable(ATSW_PreviousRecipes, 	{}			)
	InitializeTable(ATSW_Tasks, 					{}			)
	InitializeTable(ATSW_CustomCategories, {}			)
	InitializeTable(ATSW_CSOpenCategory, 	0				)
	InitializeTable(ATSW_CSSelected, 			''				)
	
	InitializeContractedCategories()
end

local function InitializeProfession()
	local Table = ATSW_Profession
	
	if not Table 						then Table = {} 						end
	if not Table[realm] 			then Table[realm] = {} 				end
	if not Table[realm][player] 	then Table[realm][player] = nil 	end
end

local function GetProfession()
	InitializeProfession()
	
	local Skill = GetCraftCaption()
	
	if Skill and Skill ~= 'UNKNOWN' then
		ATSW_Profession[realm][player] = Skill
	end
	
	return Skill
end

function ATSW_UpdateStatusBarRank()
	local _, Rank, MaxRank 	= GetCraftCaption()
	
	SetVisible(ATSWRankFrame, 		Rank > 0)
	SetVisible(ATSWRankFrameRank, 	MaxRank > 0)
	SetVisible(ATSWRankFrameSpark,	Rank ~= MaxRank)
	
	if ATSWRankFrame:IsVisible() then
		ATSWRankFrame:			SetMinMaxValues(0, MaxRank)
		ATSWRankFrame:			SetValue(Rank)
		ATSWRankFrameSpark:	SetPoint('CENTER', ATSWRankFrame, 'LEFT', ATSWRankFrame:GetWidth() * Rank/MaxRank, 0)
	end
	
	if ATSWRankFrameRank:IsVisible() then
		ATSWRankFrameRank:		SetText(Rank .. '/' .. MaxRank)
	end
end

function ATSW_InitializeFrame()
	local SameProfession = GetCraftCaption() == Profession()
	
	if not SameProfession or RecipesSize() == 0 then
		GetProfession					()
		InitializeTables					()
		ATSW_ShowDropDown	()
		
		if RecipesSize() == 0 then
			ATSW_HideRecipes			()
			ATSW_HideRecipe			()

			ATSW_HideTasks			()
		end
	end
	
	if IsBeastTraining() then -- This is an easy and quick fix of an issue, not a solid complete solution
		ATSW_HideRecipe()
	end
end

function ATSW_UpdateBackground()
	local BG = ATSW_Background[GetProfessionTexture(Profession())]
	
	if BG then
		ATSWBackground:SetTexture('Interface\\AddOns\\AdvancedTradeSkillWindow2\\Textures\\Background\\' .. BG)
	else
		ATSWBackground:SetTexture(nil)
	end
end

function ATSW_FindSpecialization()
		local I = 0
		local STexture
		local Specs = ATSW_Specializations[GetProfessionTexture(Profession())]
		
		if Specs then
			repeat
				I = I + 1
				
				STexture = GetSpellTexture(I, BOOKTYPE_SPELL)
				
				if STexture then
					for S = 1, table.getn(Specs) do
						if STexture == Icon(Specs[S]) then
							return Color.GREY .. ' (' .. GetSpellName(I, BOOKTYPE_SPELL) .. ')|r'
						end
					end
				end
			until not STexture or I == 36
		end
		
		return ''
	end

function ATSW_UpdateCaption()
	local Name = GetCraftCaption()
	
	-- Set status bar info
	
	ATSWFrameTitleText:SetText(format(TEXT(TRADE_SKILL_TITLE), Name) .. ATSW_FindSpecialization())
	ATSW_UpdateStatusBarRank()
	
	-- Set skill portrait
	SetPortraitToTexture(ATSWFramePortrait, GetProfessionTexture(Name))
end

function ATSW_UpdateFrame()
	ATSW_InitializeFrame()
	ATSW_GetRecipes(true)
	ATSW_ShowSelection()
	
	if NoDropDownUpdate then
		NoDropDownUpdate = false
	else
		ATSW_ShowDropDown()
	end
	
	if SortBy() == 'Custom' then
		ATSWCS_FillAllRecipes()
		ATSWCS_Update()
	end
	
	SetNeedToUpdate(Profession(), false)
	
	if not ATSWFrame.UpdateIsRegistered and RecipesSize() > 0 and RecipesSize() == GetCraftCount()  then
		ATSWFrame:RegisterEvent(	'TRADE_SKILL_UPDATE'				)
		ATSWFrame:RegisterEvent(	'CRAFT_UPDATE'						)
		ATSWFrame.UpdateIsRegistered = true
	end
	
	ATSW_UpdateTasks()
	ATSW_ShowTrainingPoints()
end

function ATSW_OnEvent()
	if ATSW_Debug then
		local s = ''
		
		if arg1 	then s = s .. ' (|cffB0B0B0arg1|r = '  .. 	'|cffFFD100' .. arg1 .. '|r' 	end
		if arg2 	then s = s .. ', |cffB0B0B0arg2|r = '  ..	'|cffFFD100' .. arg2 .. '|r' 	end
		if arg3 	then s = s .. ', |cffB0B0B0arg3|r = '  ..	'|cffFFD100' .. arg3 .. '|r' 	end
		if arg4 	then s = s .. ', |cffB0B0B0arg4|r = '  ..	'|cffFFD100' .. arg4 .. '|r' 	end
		if arg5 	then s = s .. ', |cffB0B0B0arg5|r = '  ..	'|cffFFD100' .. arg5 .. '|r' 	end
		if arg6 	then s = s .. ', |cffB0B0B0arg6|r = '  ..	'|cffFFD100' .. arg6 .. '|r' 	end
		if arg7 	then s = s .. ', |cffB0B0B0arg7|r = '  ..	'|cffFFD100' .. arg7 .. '|r' 	end
		if arg8 	then s = s .. ', |cffB0B0B0arg8|r = '  ..	'|cffFFD100' .. arg8 .. '|r' 	end
		if arg9 	then s = s .. ', |cffB0B0B0arg9|r = '  ..	'|cffFFD100' .. arg9 .. '|r' 	end
		if arg10	then s = s .. ', |cffB0B0B0arg10|r = ' ..	'|cffFFD100' .. arg10 .. '|r' 	end
		
		if s ~= '' then s = s .. ')' end
		
		-- Filter NPCScan TargetUnit() spam
		if not (event == 'UI_ERROR_MESSAGE' and string.find(arg1, ERR_UNIT_NOT_FOUND)) then
			Debug('|cffB0B0B0event|r = ' .. '|cffFFD100' .. tostring(event) .. '|r' .. s)
		end
	end
	
    if 			event == 'UNIT_PET'									then
	
		ATSW_ShowTrainingPoints()
		
    elseif 	event == 'UNIT_PET_TRAINING_POINTS' 		then
	
		ATSW_ShowTrainingPoints()
	
    elseif 	event == 'BANKFRAME_OPENED'
    or 		event == 'PLAYERBANKSLOTS_CHANGED'
    or 		event == 'PLAYERBANKBAGSLOTS_CHANGED' 	then
		
		BankFrameOpened = true
        ATSW_SaveBank()
	
    elseif 	event == 'BANKFRAME_CLOSED' 					then
	
		BankFrameOpened = false
	
    elseif 	event == 'MERCHANT_SHOW' 						then
		
        ATSW_UpdateMerchant()
        
		if ATSW_Options.AutoBuy then
			ATSW_BuyFromMerchant()
		else
			ATSW_SetBuyFrameVisible()
		end
		
		if ATSWFrame:IsVisible() and not (BlizzMo and ATSWFrame.settings and ATSWFrame.settings.save) then
			local oldCenter = UIParent.center
			
			UIParent.center = nil
			SetCenterFrame(ATSWFrame)
			UIParent.center = oldCenter
		end
    elseif 	event == 'MERCHANT_CLOSED' 						then
	
		ATSWBuyNecessaryFrame:Hide()
		
		if ATSWFrame:IsVisible() and not (BlizzMo and ATSWFrame.settings and ATSWFrame.settings.save) then
			local oldLeft = UIParent.left 
			
			UIParent.left = nil
			SetLeftFrame(ATSWFrame)
			UIParent.left = oldLeft
		end
    elseif 	event == 'MERCHANT_UPDATE' 						then
	
		ATSW_UpdateMerchant()
	
    elseif 	event == 'AUCTION_HOUSE_SHOW' 				then
	
        ATSW_ShowAuctionShoppingList()
	
    elseif 	event == 'AUCTION_HOUSE_CLOSED' 			then
	
        ATSWShoppingListFrame:Hide()
	
    elseif 	event == 'BAG_UPDATE' 								then
		if BankFrameOpened then
			ATSW_SaveBank()
		end
		
		ATSW_SaveBag(arg1)
		
		if ATSWFrame:IsVisible() then
			-- Check if a selected tool is update
			for Slot = 1, GetContainerNumSlots(arg1) do
				local function ToolIsUpdating(BID)
					for I = 1, ATSW_TOOLS_DISPLAYED do
						local Button = _G['ATSWTool' .. I]
						
						if Button:IsVisible() then
							local ToolID = ToolID[Button.Name]
						
							if BID == ToolID then
								return true
							end
						end
					end
					
					return false
				end
				
				local BID = ATSW_LinkToID(GetContainerItemLink(arg1, Slot))
				
				if ToolIsUpdating(BID) then
					ATSW_SelectRecipe(RecipeSelected())
				end
			end
		end
		
		-- Update all frame sections
		
		if ATSWFrame:					IsVisible() 	then 	ATSW_UpdateRecipes					()
																			ATSW_UpdateTasks					()
																			
		if RecipeSelected()								then 	ATSW_SelectRecipe(RecipeSelected()) 	end end
		
		if ATSWCSFrame:				IsVisible() 	then 	ATSWCS_UpdateATSWFrame		()
																			ATSWCS_Update						()		end
		
		ATSW_UpdateNecessaryReagents()
		
		if MerchantFrame:				IsVisible() 	then 	ATSW_SetBuyFrameVisible			() 	end
		if ATSWShoppingListFrame:	IsVisible() 	then 	ATSW_UpdateAuctionList			() 	end
		
    elseif 	event == 'TRADE_SKILL_UPDATE'
	or 		event == 'CRAFT_UPDATE' 							then
		
		UpdateCount = UpdateCount + 1
	
    elseif 	event == 'SPELLCAST_START'  						then
		
		if arg1 == Processing.Recipe and not Processing.Active then
			local function ColorizeProgressBar()
				local R, G, B = 1, 0.82, 0
				
				local Colors = {
					[2840] 	= {R = 0.72, G = 0.45, B = 0.20}, -- Copper
					[3576] 	= {R = 1.00, G = 0.89, B = 0.48}, -- Tin
					[2841] 	= {R = 0.80, G = 0.67, B = 0.36}, -- Bronze
					[2842] 	= {R = 0.75, G = 0.75, B = 0.78}, -- Silver
					[3575] 	= {R = 0.62, G = 0.63, B = 0.65}, -- Iron
					[3577] 	= {R = 1.00, G = 0.84, B = 0.00}, -- Gold
					[3859] 	= {R = 0.64, G = 0.72, B = 0.68}, -- Steel
					[3860] 	= {R = 0.74, G = 0.85, B = 0.67}, -- Mithril
					[6037] 	= {R = 0.85, G = 0.98 ,B = 0.98}, -- Truesilver
					[12359] = {R = 0.50, G = 0.75, B = 0.71}, -- Thorium
					[11371] = {R = 0.57, G = 0.56, B = 0.54}, -- Dark Iron
					[17771] = {R = 0.78, G = 0.73 ,B = 0.86}, -- Elementium
				}
				
			local function GetColor(ID)
				local C = ID and Colors[ID]

				if C then
					return C.R, C.G, C.B
				end

				return R, G, B
			end
				
				if IsSmelting() then
					R, G, B = GetColor(GetRecipeID(Processing.Recipe))
				end
				
				ATSWProgressBarTexture:SetVertexColor(R, G, B)
			end
			
			Processing.RecipeTime = arg2 / 1000
			
			local ID = GetRecipeID(arg1)
			
			if ID then
				ATSW_TimeCost[ID] = Processing.RecipeTime
			end
			
			local CastTime = Processing.RecipeTime
			
			if TradeSkill then
				CastTime = CastTime * Processing.Amount
			end
			
			ATSW_InitializeProgressBar(Processing.Delay, (Processing.Delay + CastTime))
			ColorizeProgressBar()
			Processing.Delay = GetTime() - Processing.Delay
			ATSW_StartProcessing()
		end
		
	elseif	event == 'SPELLCAST_INTERRUPTED'				then
		
		ATSW_StopProcessing()
		
	elseif 	event == 'PLAYER_ENTERING_WORLD' 			then
		
		ATSW_SaveBag(0)
		ATSW_Hide()
		
		-- Initialize Table
		local Table = ATSW_NecessaryReagents

		if Table == nil then
			Table = {}
		end
		
		if Table[realm] == nil then
			Table[realm] = {}
		end
		
		if Table[realm][player] == nil then
			Table[realm][player] = {}
		end
		
		if ATSW_Characters then 
			if ATSW_Characters[realm] then
				for I in ipairs(ATSW_Characters[realm]) do
					if ATSW_Characters[realm][I].Name == player then
						return
					end
				end
			else
				ATSW_Characters[realm] = {}
			end
		end
		
		table.insert(ATSW_Characters[realm], {
			Name 	= player,
			Class		= class
		})
		
	elseif 	event == 'CHAT_MSG_SYSTEM' 						then
	
		if string.find(arg1, ERR_LEARN_RECIPE_PATTERN)
		or string.find(arg1, ERR_LEARN_SPELL_PATTERN) then 				-- Learn new recipe event
			SetNeedToUpdate()
		end
		
		if string.find(arg1, ERR_UNLEARN_RECIPE_PATTERN) then 			-- Unlearn profession event
			local _, _, Skill = string.find(arg1, ERR_UNLEARN_RECIPE_PATTERN)
			
			if ATSW_ProfessionExists(Skill) then
				-- Reset previous recipes
				for I = 1, PreviousRecipesSize(Skill) do
					table.remove(PreviousRecipes(Skill), PreviousRecipesSize(Skill)-1+I)
				end
				
				ATSW_ConfigureSkillButtons(Skill) -- Reconfigure tabs except Skill
				
				-- Reset tasks
				for I = 1, TasksSize(Skill) do
					ATSW_DeleteTask(Task(I, Skill).Name, nil, Skill)
				end
				
				-- Reset necessary settings
				ATSW_SelectedRecipe	[realm][player][Skill]	= nil
				ATSW.RecipesSize			[realm][player][Skill]	= 0
				ATSW.RecipesSortedSize	[realm][player][Skill]	= 0
				ATSW_SubClassFilter		[realm][player][Skill]	= 0
				ATSW_InvSlotFilter			[realm][player][Skill]	= 0
				ATSW_SelectedRecipe	[realm][player][Skill]	= nil
				ATSW_ScrollOffset			[realm][player][Skill]	= 0
				
				if Skill == Profession() then
					ATSW_Profession[realm][player]		= nil
					
					ATSW_SwitchToFrame() -- Hide frame if Skill is selected
				end
			end
		end
	elseif 	event == 'CHAT_MSG_LOOT' 						then
		
		-- Task completion
		if Processing.Active then
			if string.find(arg1, LOOT_ITEM_CREATED_SELF_PATTERN) then -- React on 'You create: %s' pattern
				Bar = ATSWProgressBar
				
				if Processing.Amount > 1 then
					ATSW_CompleteTask()
				else
					if Processing.Stop then
						ATSW_CompleteTask() -- Complete immediately
					else
						Bar.Mode = ATSW_FLASH -- Start flash animation
					end
				end
				
				RecipesRemaining = Processing.Amount - Processing.Complete
				
				TimePassed 	= GetTime() - Bar.StartTime
				ERT 				= (Processing.RecipeTime + GetLatency()) * RecipesRemaining -- Estimated remaining time
				
				Bar.EndTime = GetTime() + TimePassed + ERT
				
				Bar:SetMinMaxValues(Bar.StartTime, Bar.EndTime)
			end
		end
	elseif 	event == 'CHAT_MSG_SKILL' 							then
	
		if string.find(arg1, ERR_SKILL_UP_PATTERN) then						-- Increase profession rank event
			local _, _, Skill = string.find(arg1, ERR_SKILL_UP_PATTERN)
			
			NoDropDownUpdate = true
			
			if ATSW_ProfessionExists(Skill) then
				SetNeedToUpdate(Skill)
			else
				SetNeedToUpdate()
			end
			
			ATSW_UpdateStatusBarRank()
		elseif string.find(arg1, ERR_SKILL_GAINED_PATTERN) then 			-- Learn new profession event
			ATSW_ConfigureSkillButtons()
		end
	elseif 	event == 'CVAR_UPDATE' 								then
		if arg1 		== 'USE_UISCALE' 		then
			ATSWRecipeTooltip:SetScale(GetCVar('uiscale'))
		elseif arg1	== 'WINDOWED_MODE'	then
			-- Fix for BarGlow texture becomes white if toggling windowed mode
			ATSWProgressBarGlow:SetTexture(nil)
			ATSWProgressBarGlow:SetTexture('Interface\\AddOns\\AdvancedTradeSkillWindow2\\Textures\\ProgressBarFlash')
			ATSWOptionsMenuHeader:SetTexture(nil)
			ATSWOptionsMenuHeader:SetTexture('Interface\\AddOns\\AdvancedTradeSkillWindow2\\Textures\\UI-DialogBox-Header')
		end
	elseif 	event == 'UI_ERROR_MESSAGE' 						then
		if Processing.Active and (string.find(arg1, ERR_INV_FULL) or string.find(arg1, ERR_ITEM_MAX_COUNT) or string.find(arg1, sRequires)) then
			ATSW_StopProcessing()
		end
	elseif 	event == 'TRADE_SKILL_SHOW' 						then
		if UIParent:IsVisible() then
			if ATSWFrame:IsVisible() or ATSWCSFrame:IsVisible() then
				ATSWFrame:	UnregisterEvent	('CRAFT_CLOSE'		)
				CloseCraft()
				ATSWFrame:	RegisterEvent		('CRAFT_CLOSE'		)
			end
			
			TradeSkill = true
			ATSW_Show()
		else
			CloseTradeSkill()
		end
	elseif 	event == 'CRAFT_SHOW' 									then
		if UIParent:IsVisible() then
			if ATSWFrame:IsVisible() or ATSWCSFrame:IsVisible() then
				ATSWFrame:	UnregisterEvent	('TRADE_SKILL_CLOSE')
				CloseTradeSkill()
				
				if TradeSkill then
					Processing.Stop = true
				end
				
				ATSWFrame:	RegisterEvent		('TRADE_SKILL_CLOSE')
			end
		
			TradeSkill = false
			ATSW_Show()
		else
			CloseCraft()
		end
	elseif event == 'TRADE_SKILL_CLOSE' then
		ATSW_Hide()
	elseif event == 'CRAFT_CLOSE' then
		ATSW_Hide()
    end
end

-- Control

local function SetSortCheckboxes(Sort)
	ATSWCategorySortCheckbox:	SetChecked(	Sort == 'Category'	)
	ATSWDifficultySortCheckbox:	SetChecked(	Sort == 'Difficulty'		)
	ATSWNameSortCheckbox:		SetChecked(	Sort == 'Name'			)
	ATSWCustomSortCheckbox:		SetChecked(	Sort == 'Custom'		)
	ATSWMaterialsSortCheckbox:	SetChecked(	Sort == 'Materials'	)
	SetVisible(ATSWCustomEditorButton, Sort == 'Custom')
end

function ATSW_SortCheckbox_OnClick()
	SetSortBy(this.Sort)
	SetSortCheckboxes(this.Sort)
end

local function FilterDropDownButton_OnClick(This, Filter, SetFilter, FilterDropDown, SetTradeSkillFilter)
	local Value = This:GetID() - 1
	
	if Value ~= Filter then
		SetFilter(Value)
		UIDropDownMenu_SetSelectedID(FilterDropDown, Value + 1)
		SetTradeSkillFilter(Value, 1, 1)
		
		ATSW_GetRecipesSorted(true)
	end
end

function ATSWSubClassDropDownButton_OnClick()
	FilterDropDownButton_OnClick(this, SubClass, SetSubClass, ATSWSubClassDropDown, SetTradeSkillSubClassFilter)
end

function ATSWInvSlotDropDownButton_OnClick()
	FilterDropDownButton_OnClick(this, InvSlot, SetInvSlot, ATSWInvSlotDropDown, SetTradeSkillInvSlotFilter)
end

local function InsertIntoAuction(Link)
	local _, _, Name = string.find(Link, '%[?([^%[%]]*)%]')

	if aux_frame and aux_frame:IsVisible() then
		local aux = require 'aux'
		local info = require 'aux.util.info'
		
		local _, _, ID = string.find(Link, 'item:(%d+)')
		local Item = string.format('item:%d', tonumber(ID))
		local item_info = info.item(tonumber(aux.select(3, strfind(Item, '^item:(%d+)'))))
		
		if item_info and aux.get_tab().CLICK_LINK then
			aux.get_tab().CLICK_LINK(item_info)
		end
	elseif AuxBuySearchBox and AuxBuySearchBox:IsVisible() then
		AuxBuySearchBox:SetText(Name)
		AuxBuySearchButton_OnClick()
	elseif AuxBuyNameInputBox and AuxBuyNameInputBox:IsVisible() then 
		AuxBuyNameInputBox:SetText(Name)
		Aux.buy.SearchButton_onclick()
	elseif CanSendAuctionQuery() and AuctionFrame and AuctionFrame:IsVisible() then
		BrowseName:SetText(Name)
		AuctionFrameBrowse_Search()
		BrowseNoResultsText:SetText(BROWSE_NO_RESULTS)
	end
end

function ATSWRecipeButton_OnClick(Button)
	local Link 		= this.Link
	
	if Button == 'LeftButton' then
		local Name 	= this.Name
		local Type 	= this.Type
		
		if not Key.Ctrl() and Key.Shift() and not Key.Alt() and not (Type == 'header') then
			if ChatFrameEditBox:IsVisible() or WIM_EditBoxInFocus then
				ATSW_SayReagents(this.Position)
			elseif not (IsBeastTraining() or Type == 'header') then
				local Possible = ATSW_HowManyItemsArePossibleToCreate(Name)
				
				ATSW_AddTask(Name, Possible > 0 and Possible or 1)
			end
		elseif Key.Ctrl() and not Key.Shift() and not Key.Alt() and Link then
			DressUpItemLink(Link)
		else
			ATSW_SelectRecipe(Name, Type)
		end
	elseif Button == 'RightButton' then
		InsertIntoAuction(Link)
	end
end

function ATSW_TaskDeleteOnClick()
	ATSW_DeleteTask(this:GetParent().Name)
end

function ATSWTool_OnClick(Button)
	if Button == 'LeftButton' then
		table.insert(PreviousRecipes(), RecipeSelected())
		ATSW_SelectRecipe(this.Name)
	end
end

function ATSWReagentsButton_OnClick()
    if ATSWReagentsFrame:IsVisible() then
        ATSWReagentsFrame:Hide()
    else
		for R = 1, ATSW_NECESSARIES_DISPLAYED do -- Create reagent frame buttons
			local F = CreateFrame('Frame', 'ATSWRFReagent' .. R, ATSWReagentsFrame, 'ATSWRFReagentTemplate')
			
			if R == 1 then
				F:SetPoint('TOPLEFT', 26, -59)
			else
				F:SetPoint('TOPLEFT', 'ATSWRFReagent' .. R - 1, 'BOTTOMLEFT')
			end
		end
		
        ATSW_UpdateNecessaryReagents()
		ATSWReagentsFrame:Show()
    end
end

local function Crement(Edge, Step)
	local Amount	= ATSWAmountBox:GetNumber()
	
	if not Key.Ctrl() and Key.Shift() and not Key.Alt() then
		Amount = Edge
	end
	
	if Amount ~= Edge then
		ATSWAmountBox:SetNumber(Amount + Step)
	else
		if Edge == 0 then
			ATSWAmountBox:SetText(ATSW_ALL)
		else
			ATSWAmountBox:SetText(Edge)
		end
	end
end

function ATSWFrameDecrement_OnClick()
	Crement(0, -1)
end

function ATSWFrameIncrement_OnClick()
	Crement(100, 1)
end

function ATSWTask_OnClick(arg1)
	if IsEnchanting() then
		return
	end
	
	if arg1 == 'LeftButton' then
		if not Key.Ctrl() and Key.Shift() and not Key.Alt() and not Processing.Active and not Recipe(this.Position).Cooldown then
			local QName 			= Task(this.TaskIndex).Name
			local QAmount 		= Task(this.TaskIndex).Amount
			local IncludeTasks 	= true
			local Possible 			= ATSW_HowManyItemsArePossibleToCreate(QName, ATSW_POSSIBLE_NOTASK) > 0
			
			if Possible then
				ATSW_Craft(QName, QAmount)
			end
		else
			ATSWRecipeButton_OnClick(arg1)
		end
	end
end

function ATSWTaskButton_OnClick()
	if IsEnchanting() then
		return
	end
	
	local Amount = ATSWAmountBox:GetNumber()
	local Name = RecipeSelected()
	
	if Amount == 0 and TradeSkill then
		if ATSW_Options.ConsiderBank or ATSW_Options.ConsiderAlts or ATSW_Options.ConsiderMerchants then
			Amount = ATSW_HowManyItemsArePossibleToCreateWithConsidering(Name)
		else
			Amount = ATSW_HowManyItemsArePossibleToCreate(Name)
		end
	end
	
	if Amount == 0 then
		Amount = 1
	end

	ATSW_AddTask(Name, Amount)
end

function ATSWCreateButton_OnClick()
	local Amount = ATSWAmountBox:GetNumber()
	local Name = RecipeSelected()
	
	if IsBeastTraining() then
		Craft(GetRecipePosition(Name))
		return
	end
	
	-- Enchanting produces no items: craft directly, skip the task queue
	if IsEnchanting() then
		if Amount == 0 then
			Amount = 1
		end
		
		Craft(GetRecipePosition(Name), Amount)
		return
	end
	
	if not Processing.Active then
		if Amount == 0 then
			if TradeSkill then
				Amount = ATSW_HowManyItemsArePossibleToCreate(Name)
			else
				Amount = 1
			end
		end
		
		local QName, QAmount
		
		for I = 1, TasksSize() do
			if ATSW_HowManyItemsArePossibleToCreate(Task(I).Name, ATSW_POSSIBLE_NOTASK) > 0 then
				QName		= Task(I).Name
				QAmount	= Task(I).Amount
				
				break
			end
		end
		
		-- Nothing craftable in the queue: enqueue the selected recipe (its
		-- dependencies are added recursively), then craft the first craftable
		-- task in the dependency chain
		if not QName then
			ATSW_AddTask(Name, Amount)
			
			for I = 1, TasksSize() do
				if ATSW_HowManyItemsArePossibleToCreate(Task(I).Name, ATSW_POSSIBLE_NOTASK) > 0 then
					QName		= Task(I).Name
					QAmount	= Task(I).Amount
					
					break
				end
			end
		end
		
		if QName and QAmount then
			ATSW_Craft(QName, QAmount)
		end
	end
end

function ATSW_ShowFrame()
	CastSpellByName(ATSW_ProfessionExists(Profession()) and Profession() or GetFirstProfession() or '')
end

function ATSW_Command(Command)
	local function Chat(msg)
		DEFAULT_CHAT_FRAME:AddMessage(msg)
	end
	
    if 			Command == 'options'
	or 		Command == 'configuration' 
	or 		Command == 'config' 	then
		ATSW_ToggleOptionsFrame()
	elseif 	Command == 'debug' 	then
		ATSW_Debug = not ATSW_Debug
	elseif 	Command == 'matsconfirm' then
		ATSW_Options.NoConfirmMats = not ATSW_Options.NoConfirmMats
		Chat('ATSW: reagent list confirmation ' .. (ATSW_Options.NoConfirmMats and 'off (sends directly)' or 'on (asks first)'))
    else
		ATSW_ShowFrame()
	end
end

function ATSW_ToggleOptionsFrame()
    if ATSWConfigFrame:IsVisible() then
		HideUIPanel(ATSWConfigFrame)
    else
		ATSWOFUnifiedButton:					SetChecked(ATSW_Options.Unified)
		ATSWOFSeparateButton:					SetChecked(not ATSW_Options.Unified)
		ATSWOFIncludeBankButton:			SetChecked(ATSW_Options.ConsiderBank)
		ATSWOFIncludeAltsButton:				SetChecked(ATSW_Options.ConsiderAlts)
		ATSWOFIncludeMerchantsButton:		SetChecked(ATSW_Options.ConsiderMerchants)
		ATSWOFAutoBuyButton:					SetChecked(ATSW_Options.AutoBuy)
		ATSWOFTooltipButton:					SetChecked(ATSW_Options.RecipeTooltip)
		ATSWOFShoppingListButton:			SetChecked(ATSW_Options.DisplayShoppingList)
		
        ShowUIPanel(ATSWConfigFrame)
    end
end

function ATSWRecipe_OnClick()
	local Link = this.Link
	
    if arg1 == 'RightButton' then
        InsertIntoAuction(Link)
	elseif arg1 == 'LeftButton' then
		if Key.Ctrl() and not Key.Shift() and not Key.Alt() then
			DressUpItemLink(Link)
		elseif not Key.Ctrl() and Key.Shift() and not Key.Alt() then
			if WIM_EditBoxInFocus then
				WIM_EditBoxInFocus:Insert(Link)
			elseif ChatFrameEditBox:IsVisible() then
				ChatFrameEditBox:Insert(Link)
			else
				if Link then
					ATSWSearchBox:SetText(':r ' .. (LinkToName(Link) or ''))
				end
			end
		elseif string.find(this:GetName(), 'ATSWReagent') then
			local ReagentID = ATSW_LinkToID(GetReagentLink(GetPositionFromGame(RecipeSelected()), this:GetID()))
			
			for I = 1, RecipesSize() do
				if ReagentID == ATSW_LinkToID(Recipe(I).Link) then
					table.insert(PreviousRecipes(), RecipeSelected())
					
					ATSW_SelectRecipe(Recipe(I).Name)
				end
			end
		end
	end
end

function ATSWPreviousItemButton_OnClick()
	ATSW_SelectRecipe(table.remove(PreviousRecipes()))
end

function ATSWSubClassDropDown_OnLoad()
	_G[this:GetName()..'Button']:SetHeight(26)
	UIDropDownMenu_Initialize(this, ATSWSubClassDropDown_Initialize)
	UIDropDownMenu_SetWidth(120)
	UIDropDownMenu_SetSelectedID(ATSWSubClassDropDown, 1)
end

function ATSWSubClassDropDown_OnShow()
	UIDropDownMenu_Initialize(this, ATSWSubClassDropDown_Initialize)
	UIDropDownMenu_SetWidth(120)
end

function ATSWSubClassDropDown_Initialize()
    ATSWFilterFrame_LoadSubClasses(GetTradeSkillSubClasses())
end

local function SetDropDownText(frame, filter, t, DefaultText)
	local Text
	
	if filter > 0 then
		Text = t[filter]
	elseif table.getn(t) == 1 then
		Text = t[1]
	else
		Text = DefaultText
	end
	
	UIDropDownMenu_SetText(Text, frame)
end

function ATSWFilterFrame_LoadSubClasses(...)
    local info = {}
	local filter = SubClass()
	
	if not filter then
		filter = 0
	end
	
	if filter > arg.n then
		filter = 0
	end
	
	info.func = ATSWSubClassDropDownButton_OnClick
	
    if arg.n > 1 then
        info.text = ALL_SUBCLASSES
		info.checked = filter == 0
        UIDropDownMenu_AddButton(info)
		
		if info.checked then
			UIDropDownMenu_SetSelectedID(ATSWSubClassDropDown, 1)
		end
    end
	
    for I = 1, arg.n do
        info.text = arg[I]
		info.checked = filter == I
        UIDropDownMenu_AddButton(info)
		
		if info.checked then
			UIDropDownMenu_SetSelectedID(ATSWSubClassDropDown, I+1)
		end
    end
	
	if filter == 0 then
		UIDropDownMenu_SetSelectedID(ATSWSubClassDropDown, 1)
	end
	
	SetDropDownText(ATSWSubClassDropDown, filter, arg, ALL_SUBCLASSES)
end

function ATSWInvSlotDropDown_OnLoad()
	_G[this:GetName()..'Button']:SetHeight(26)
	UIDropDownMenu_Initialize(this, ATSWInvSlotDropDown_Initialize)
	UIDropDownMenu_SetWidth(120)
	UIDropDownMenu_SetSelectedID(ATSWInvSlotDropDown, 1)
end

function ATSWInvSlotDropDown_OnShow()
	UIDropDownMenu_Initialize(this, ATSWInvSlotDropDown_Initialize)
	UIDropDownMenu_SetWidth(120)
end

function ATSWInvSlotDropDown_Initialize()
    ATSWFilterFrame_LoadInvSlots(GetTradeSkillInvSlots())
end

function ATSWFilterFrame_LoadInvSlots(...)
    local info = {}
	local filter = InvSlot()
	
	if not filter then
		filter = 0
	end
	
	if filter > arg.n then
		filter = 0
	end
	
	info.func = ATSWInvSlotDropDownButton_OnClick
	
    if arg.n > 1 then
        info.text = ALL_INVENTORY_SLOTS
		info.checked = filter == 0
        UIDropDownMenu_AddButton(info)
		
		if info.checked then
			UIDropDownMenu_SetSelectedID(ATSWInvSlotDropDown, 1)
		end
    end
	
    for I = 1, arg.n do
        info.text = arg[I]
		info.checked = filter == I
        UIDropDownMenu_AddButton(info)
		
		if info.checked then
			UIDropDownMenu_SetSelectedID(ATSWInvSlotDropDown, I+1)
		end
    end
	
	if filter == 0 then
		UIDropDownMenu_SetSelectedID(ATSWInvSlotDropDown, 1)
	end
	
	SetDropDownText(ATSWInvSlotDropDown, filter, arg, ALL_INVENTORY_SLOTS)
end

-- Get recipes from server

function ATSW_GetRecipes(New)
	if RecipesSize() == 0 or New then
		SetDropDownFilter(0, 0) -- It is needed for full trade skill list initial loading
		RecipesSize(0)
		
		for I = 1, GetCraftCount() do
			AddRecipe(I)
		end
	end
	
	SetDropDownFilter(SubClass(), InvSlot())
	ATSW_GetRecipesSorted(New)
end

function ATSW_GetRecipesSorted(New)
	if RecipesSortedSize() == 0 or New then
		if 			SortBy() == 'Category' 	then ATSW_GetRecipesSortedByCategory	()
		elseif 	SortBy() == 'Difficulty' 	then ATSW_GetRecipesSortedByDifficulty	()
		elseif 	SortBy() == 'Name' 		then ATSW_GetRecipesSortedByName		()
		elseif 	SortBy() == 'Custom' 	then ATSW_GetRecipesSortedByCustom	()
		elseif 	SortBy() == 'Materials' 	then ATSW_GetRecipesSortedByMaterials() end
	end
	
	ATSW_UpdateRecipes()
end

-- Sorting of recipes

function ATSW_GetRecipesSortedByCategory()
	RecipesSortedSize(0)
	
	local Expanded, H = true
	
	for I = 1, RecipesSize() do
		local R = Recipe(I)
		
		if R.Type == 'header' then
			H = R
		else
			if ATSW_Filter(R) and DropDownFilterPass(R.Name) then
				if H then
					Expanded = IsExpanded(H.Name)
					AddRecipeSorted(H)
					H = nil
				end
				
				if Expanded then
					AddRecipeSorted(R)
				end
			end
		end
	end
end

local function GetRecipesSortedWithoutHeaders()
	RecipesSortedSize(0)
	
	for I = 1, RecipesSize() do
		local R = Recipe(I)
		
		if R.Type ~= 'header' and ATSW_Filter(R) and DropDownFilterPass(R.Name) then
			AddRecipeSorted(R)
		end
	end
end

function ATSW_TypeToNumber(Type)
	local Number = 0
	
	if Type 	== 'trivial' 	then Number = 4 end
	if Type 	== 'easy' 	then Number = 3 end
	if Type 	== 'medium'	then Number = 2 end
	if Type 	== 'optimal' 	then Number = 1 end
	if Type 	== 'none' 	then Number = 0 end
	
	return Number
end

local function GetReagentDataProfName(Name)
	return ProfessionNamesForReagentData[GetProfessionTexture(Name)]
end

function ATSW_CompareDifficulty(Left, Right)
	return ATSW_TypeToNumber(Left.Type) < ATSW_TypeToNumber(Right.Type)
end

function ATSW_GetRecipesSortedByDifficulty()
	GetRecipesSortedWithoutHeaders()
	
	ATSW_Sort(RecipesSorted(), RecipesSortedSize(), ATSW_CompareDifficulty)
	
	-- Compatibility with AtlasLoot
	if ATSW_AtlasLoot then
		ATSW_Sort(RecipesSorted(), RecipesSortedSize(), ATSW_CompareDifficultyUsingExternalData)
	end
end

function ATSW_GetRecipesSortedByName()
	local function CompareName(Left, Right)
		return string.lower(Left.Name) < string.lower(Right.Name)
	end

	GetRecipesSortedWithoutHeaders()
	ATSW_Sort(RecipesSorted(), RecipesSortedSize(), CompareName)
end

function ATSW_GetRecipesSortedByMaterials()
	-- 材料足够的配方排前面：当前材料可制作至少 1 个的优先；
	-- 同组内可制作数量多的靠前，最后按名称排序。
	GetRecipesSortedWithoutHeaders()

	local Counts = {}

	for I = 1, RecipesSortedSize() do
		local R = RecipesSorted()[I]
		Counts[R.Name] = ATSW_HowManyItemsArePossibleToCreateWithConsidering(R.Name)
	end

	local function CompareMaterials(Left, Right)
		local LeftCount  = Counts[Left.Name] or 0
		local RightCount = Counts[Right.Name] or 0

		-- 材料足够（可制作数量 >= 1）的排前面
		if (LeftCount > 0) ~= (RightCount > 0) then
			return LeftCount > 0
		end

		-- 同组内可制作数量多的靠前
		if LeftCount ~= RightCount then
			return LeftCount > RightCount
		end

		return string.lower(Left.Name) < string.lower(Right.Name)
	end

	ATSW_Sort(RecipesSorted(), RecipesSortedSize(), CompareMaterials)
end

function ATSW_GetRecipesSortedByCustom()
	RecipesSortedSize(0)
	
	-- First add all custom categories and recipes in them
	local function Categories()
		return ATSW_CustomCategories[realm][player][Profession()]
	end
	
	local Size = table.getn(Categories())
	
	local function Category(C)
		return Categories()[C]
	end
	
	local function CatRecipe(C, I)
		return Category(C).Items[I]
	end
	
	local Expanded, HeaderAdded
	
	for C = 1, Size do
		Expanded = IsExpanded(Category(C).Name)
		HeaderAdded = false
		
		for I = 1, table.getn(Category(C).Items) do
			local R = CatRecipe(C, I)

			if R.Type ~= 'header' and ATSW_Filter(R) and DropDownFilterPass(R.Name) and IsInTradeSkills(R.Name) then
				if not HeaderAdded then
					AddRecipeSorted(Category(C))
					HeaderAdded = true
				end
				
				if Expanded then
					AddRecipeSorted(Recipe(GetRecipePosition(R.Name)))
				end
			end
		end
	end
	
	-- Then add uncategorized recipes into the category 'Uncategorized'
	
	HeaderAdded = false
	
	for I = 1, RecipesSize() do
		local R = Recipe(I)
		
		if R.Type ~= 'header' and not ATSWCS_IsCategorized(R.Name, R.SubName) and ATSW_Filter(R) and DropDownFilterPass(R.Name) then
			if not HeaderAdded then
				AddRecipeSorted({Name = ATSW_UNCATEGORIZED, Type = 'header'})
				HeaderAdded = true
			end
			
			if IsExpanded(ATSW_UNCATEGORIZED) then
				AddRecipeSorted(R)
			end
		end
	end
end

-- Thank you kikito for the function(https://stackoverflow.com/users/312586/kikito)
-- https://stackoverflow.com/questions/36820438/how-can-built-in-sorting-algorithm-be-so-fast
function ATSW_Sort(Table, Size, SortingFunction)
	local function Sort(Table, Left, Right, SortingFunction)
		if Right - Left > 0 then
			local P = Left
			
			for I = Left + 1, Right do
				if SortingFunction(Table[I], Table[P]) then
					if I == P + 1 then	Table[P], Table[P+1] = Table[P+1], Table[P]
					else						Table[P], Table[P+1], Table[I] = Table[I], Table[P], Table[P+1] end
					
					P = P + 1
				end
			end
			
			Sort(Table, Left, P - 1, SortingFunction)
			Sort(Table, P + 1, Right, SortingFunction)
		end
	end
	
	Sort(Table, 1, Size, SortingFunction)
end

local StatW = Color.WHITE .. '%d' .. Color.LIGHTGREY
local StatWP = Color.WHITE .. '%d%%' .. Color.LIGHTGREY
local StatWS = Color.WHITE .. '%s' .. Color.LIGHTGREY
local StatG = Color.GREEN .. '%d' .. Color.LIGHTGREY
local StatGS = Color.GREEN .. '%s' .. Color.LIGHTGREY

local EnchantPatterns = {
	{Pattern = 'enchant[s]* a piece of (%a+) .+ increase[s]* the ([%a%s]+) of the wearer by (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 1},
    {Pattern = 'enchant[s]* a piece of ([%a%s]+) armor to [%a]+ [+]*(%d+%%*) [to%s]*([%a%s]+).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* a piece of ([%a%s]+) armor so it has.+ (%d+%%*) chance per hit of giving.+ (%d+) points of ([%a%s]+).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%4$s' .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to [%a]+ [+]*(%d+%%*) ([%a%s]+) skill.', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to increase (%a+).* resistance by (%d+).', Return = Color.WHITE .. '%3$d' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_RESIST .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 4},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to [%a]+ [+]*(%d+%%*).* (%a+) resistance', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_RESIST .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 4},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to restore (%d+%%*) (%a+) every (.+).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_EVERY .. Color.WHITE .. '%4$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to do (%d+%%*) additional[%s%a]* damage [%a]+ (%a+).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ATSW_DAMAGE_TO .. Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to [%a]+ [+]*(%d+%%*)[%s%a]* ([%a%s]+).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to [%a]+ [%a%s]*(%d+%%*) chance [%s%a]* ([%a%s]+).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to decrease (%a+) .+by (%d+%%*).', Return = Color.WHITE .. '-%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s'},
	{Pattern = 'enchant[s]* [a%s]*([%a%s]+) to [%a%s]+ [+]*(%d*%%*)([%a%s]+) bonus([%a%s]*).', Return = Color.WHITE .. '+%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s%4$s' .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to [%a]+ a slight ([%a%s]+) increase.', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to often .+ the target reducing their ([%a%s]+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_TO_REDUCE .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to often strike.+ (%d+).+ (%a+) damage.', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_DAMAGE_ON_HIT .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s-]+) to have a chance of (%a+) and [%a%s]+ damage to (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%2$s' .. ATSW_AND_DAMAGING .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_ON_HIT_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) so .+ the ([%a%s]+) skill of the wearer is increased by (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) so that it increases[%a%s]* resistance to (%a+) [%a%s]*by (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_RESIST .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 2},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) so that it increases the ([%a%s]+) of .+ by (%d+).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 2},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) so that it increases ([%a%s]+) by (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 2},
    {Pattern = 'enchant[s]*[%s]*[a%s]*.* (%a+) so .+ the wearer\'s ([%a%s]+) by (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s'},
	{Pattern = 'enchant[s]* [a%s]*([%a%s]+) to increase the ([%a%s]+) of the wearer by (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 1},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to increase.* healing.+ by.* (%d+%%*).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ATSW_HEALING .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 1},
    {Pattern = 'enchant[s]*[%a%s]* (%a+) to increase ([%a%s]+) by (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 1},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to [%a]+ ([%a%s]+) damage by[%a%s]* (%d+%%*).', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_SPELL_DAMAGE .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to [%a]+ .+(%d+%%*).+ (%a+) damage when casting.+spells.', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%3$s' .. ATSW_SPELL_DAMAGE .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to [%a%s]+ (%d+%%*) ([%a%s]*)damage to .*spells.', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. '%3$s' .. ATSW_SPELL_DAMAGE .. ATSW_FOR .. Color.WHITE .. '%1$s'},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to do (%d+%%*) additional[%s%a]* damage.', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ATSW_DAMAGE .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) to.* steal life.* and give it to.+', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. ATSW_VAMPIRISM .. Color.LIGHTGREY .. ATSW_ON_HIT_FOR .. Color.WHITE .. '%1$s'}, -- Lifestealing
    {Pattern = 'enchant[s]* [a%s]*([%a%s]+) so that often when attacking.* heals.* (%d+) to (%d+).* (%a+) by (%d+) for (.+)', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.GREEN .. '%2$d' .. Color.WHITE .. '-' .. Color.GREEN .. '%3$d' .. Color.LIGHTGREY .. ATSW_HEALTH_AND .. Color.WHITE .. '%5$d' .. Color.LIGHTGREY .. ' ' .. '%4$s' .. ATSW_FOR .. Color.WHITE .. '%6$s' .. Color.LIGHTGREY .. ATSW_ON_HIT_FOR .. Color.WHITE .. '%1$s'} -- Crusader
}

local PoisonPatterns = {
    {Pattern = '.+ (%d+)%% chance .+ (%d+) to (%d+) ([%a%s]*)damage', Return = Color.WHITE .. '%1$d%%' .. Color.LIGHTGREY .. ATSW_TO .. Color.WHITE .. '%2$d-%3$d ' .. Color.LIGHTGREY .. '%4$sdmg', Similar = 1},
    {Pattern = '.+ threat.+', Return = Color.WHITE .. ATSW_PLUS_THREAT},
    {Pattern = '.+ (%d+)%% chance .+ (%d+) (%a*[%s]*)damage', Return = Color.WHITE .. '%1$d%%' .. Color.LIGHTGREY .. ATSW_TO .. Color.WHITE .. '%2$d ' .. Color.LIGHTGREY .. '%3$sdmg', Similar = 1},
    {Pattern = '.+ (%d+)%% chance .+ slowing their ([%a%s]+) by (%d+)%% for (%d+) (%a+)', Return = Color.WHITE .. '%1$d%%' .. Color.LIGHTGREY .. ATSW_TO .. Color.WHITE .. '-%3$d%% ' .. Color.LIGHTGREY .. '%2$s' .. ATSW_FOR .. Color.WHITE .. '%4$d %5$s', Similar = 1},
    {Pattern = '.+ (%d+)%% chance .+ increasing their casting time by (%d+)%% for (%d+) (%a+)', Return = Color.WHITE .. '%1$d%%' .. Color.LIGHTGREY .. ATSW_TO .. Color.WHITE .. '-%2$d%% ' .. Color.LIGHTGREY .. ATSW_CAST_TIME .. ATSW_FOR .. Color.WHITE .. '%3$d %4$s', Similar = 1},
    {Pattern = '.+ (%d+)%% chance .+ reducing all healing .+ by (%d+%%*) for (%d+) (%a+)', Return = Color.WHITE .. '%1$d%%' .. Color.LIGHTGREY .. ATSW_TO .. Color.WHITE .. '-%2$s ' .. Color.LIGHTGREY .. ATSW_INC_HEAL .. ATSW_FOR .. Color.WHITE .. '%3$d %4$s', Similar = 1},
    {Pattern = '. Stacks up to (%d+) times.', Return = Color.LIGHTGREY .. ATSW_STACK .. Color.WHITE .. '%1$d'},
    {Pattern = '(%d+) charges.', Return = Color.WHITE .. '%1$d' .. Color.LIGHTGREY .. ATSW_CHARGES},
}

local AttributePatterns = {
	{Pattern = '(%d+) Armor', Return = StatW .. ATSW_ARMOR},
    {Pattern = '[+-]+(%d+) [%a%s]*Strength', Return = StatW .. ATSW_STR},
    {Pattern = '[+-]+(%d+) [%a%s]*Agility', Return = StatW .. ATSW_AGI},
    {Pattern = '[+-]+(%d+) [%a%s]*Stamina', Return = StatW .. ATSW_STA},
    {Pattern = '[+-]+(%d+) [%a%s]*Intellect', Return = StatW .. ATSW_INT},
    {Pattern = '[+-]+(%d+) [%a%s]*Spirit', Return = StatW .. ATSW_SPI},
	
	{Pattern = 'gain (%d+) [%a%s]*Strength', Return = StatW .. ATSW_STR},
    {Pattern = 'gain (%d+) [%a%s]*Agility', Return = StatW .. ATSW_AGI},
    {Pattern = 'gain (%d+) [%a%s]*Stamina', Return = StatW .. ATSW_STA},
    {Pattern = 'gain (%d+) [%a%s]*Intellect', Return = StatW .. ATSW_INT},
    {Pattern = 'gain (%d+) [%a%s]*Spirit', Return = StatW .. ATSW_SPI},
	
	{Pattern = ' eat.+ increase.* (%a+) by (%d+)', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ' ' .. '%1$s'},
	
	{Pattern = 'gain (%d+)%% ([%a]+)', Return = StatWP .. ' ' .. '%2$s'},
    {Pattern = 'gain .+ and (%d+) ([%a]+)', Return = StatW .. ' ' .. '%2$s'},
    {Pattern = 'eat.+ [%a]+ (%d+) ([%a]+) every (%d+) (%a+)', Return = StatW .. ' ' .. '%2$s' .. ATSW_EVERY .. '%3$d %4$s'},
	
    {Pattern = 'All Stats (.%d+)', Return = StatW .. ATSW_ALL_ATTRIBUTES},
    {Pattern = '[+-]+(%d+) (%a+) Resistance[%.]*$', Return = Color.WHITE .. '%1$d' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_RESIST},
    {Pattern = '[+-]+(%d+) All Resistances', Return = StatW .. ATSW_ALL_RESIST},
	
    {Pattern = '(%d+) Slot([%a%s]*) (%a+)', Return = StatW .. ATSW_SLOTS .. '%2$s' .. ' ' .. '%3$s'},
    {Pattern = 'Equip: (%a+) [+](%d+).', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ' ' .. '%1$s'},
	
	{Pattern = 'gain[s]* (.%d+) (%a+) damage', Return = Color.WHITE .. '%1$d ' .. Color.LIGHTGREY .. '%2$s' .. ATSW_DAMAGE},
    {Pattern = 'Absorb[s]* (%d+) to (%d+) (%a+) damage.+Lasts (.+).', Return = Color.WHITE .. '%1$d-%2$d ' .. Color.LIGHTGREY .. '%3$s' .. ATSW_DAMAGE_ABSORB .. ATSW_FOR .. Color.WHITE .. '%4$s', Similar = 4},
    {Pattern = 'Absorb[s]* (%d+) (%a+) damage.+Lasts (.+).', Return = Color.WHITE .. '%1$d ' .. Color.LIGHTGREY .. '%2$s' .. ATSW_DAMAGE_ABSORB .. ATSW_FOR .. Color.WHITE .. '%3$s', Similar = 4},
    {Pattern = 'Reflect[s]* (%a+) .+ (%d+) sec.', Return = Color.LIGHTGREY .. '%1$s' .. ATSW_REFLECT .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%2$d sec.'},
	{Pattern = 'Chance on hit: decrease the ([%a%s]+) by (%d+%%*) for ([%d%.]+) (%a+).+affected.+ cannot stealth or turn invisible', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '-%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ', ' .. ATSW_MINUS_STEALTH_INVIS .. ATSW_FOR .. Color.WHITE .. '%3$d %4$s', Similar = 13},
	{Pattern = 'decrease the ([%a%s]+) by (%d+%%*) for ([%d%.]+) (%a+).', Return = Color.WHITE .. '-%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_FOR .. Color.WHITE .. '%3$s %4$s', Similar = 13},
    {Pattern = 'increases Fishing by (%d+) (.+)', Return = StatW .. ATSW_FISHING .. '%s', Similar = 1},
    {Pattern = 'Increase[s]*[d]* Defense %+(%d+)', Return = StatW .. ATSW_DEFENSE},
    {Pattern = 'Reduces([%s%a]+) spell damage taken by (%d+%%*).', Return = Color.WHITE .. '-%2$s' .. Color.LIGHTGREY .. '%1$s' .. ATSW_DAMAGE_TAKEN},
    {Pattern = 'Reduc[%a]+ damage taken from critical hits and damage over time effects by (%d+)%%.', Return = Color.WHITE .. '-%1$d%%' .. Color.LIGHTGREY .. ATSW_DMG_TAKEN_CRITS_DOTS},
    {Pattern = 'Increases damage and healing done by magical spells and effects(.*) by up to (%d+)', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ATSW_SPELL_POWER .. '%1$s', Similar = 1},
    {Pattern = 'Increases (%a+) spell damage by up to (%d+) for (.+).', Return = Color.WHITE .. '%2$d ' .. Color.LIGHTGREY .. '%1$s' .. ATSW_DAMAGE_FOR .. Color.WHITE .. ' %3$s.'},
    {Pattern = 'Increases spell (%a+) damage by up to (%d+) for (.+).', Return = Color.WHITE .. '%2$d ' .. Color.LIGHTGREY .. '%1$s' .. ATSW_DAMAGE_FOR .. Color.WHITE .. ' %3$s.'},
    {Pattern = 'Increases (%a+) damage by up to (%d+) for (.+).', Return = Color.WHITE .. '%2$d ' .. Color.LIGHTGREY .. '%1$s' .. ATSW_DAMAGE_FOR .. Color.WHITE .. ' %3$s.'},
    {Pattern = 'Increases damage done to (%a+) by magical spells and effects by up to (%d+)', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ATSW_SPELL_DAMAGE_TO .. '%1$s', Similar = 1},
    {Pattern = 'Increases damage done by (%a+) spells and effects by up to (%d+)', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_DAMAGE, Similar = 1},
    {Pattern = 'Increases healing done by spells and effects by up to (%d+)', Return = StatW .. ATSW_HEALING, Similar = 1},
    {Pattern = '(%d+%.?%d*)%% of damage dealt is returned as healing', Return = StatWP .. ' ' .. ATSW_VAMPIRISM, Similar = 1},
    {Pattern = 'Increases .+ chance to block attacks .+ (%d+)%%.', Return = StatWP .. ATSW_BLOCK, Similar = 1},
    {Pattern = 'Increases .+ block value .+ (%d+).', Return = StatW .. ATSW_BLOCK, Similar = 1},
    {Pattern = 'Increases your chance to parry an attack by (%d+).', Return = StatWP .. ATSW_PARRY, Similar = 1},
    {Pattern = 'Decreases your chance to parry an attack by (%d+).', Return = Color.WHITE .. '-%1$d%%' .. Color.LIGHTGREY .. ATSW_PARRY, Similar = 1},
    {Pattern = 'Increases your chance to dodge an attack by (%d+).', Return = StatWP .. ATSW_DODGE, Similar = 1},
    {Pattern = 'Increases your attack and casting speed by (%d+).', Return = StatWP .. ATSW_ATTACK_AND_CASTING_SPEED, Similar = 1},
    {Pattern = 'Equip: .*Increases ([%a%s]+) by (%d+)%%%.', Return = Color.WHITE .. '%2$d%%' .. Color.LIGHTGREY .. ' ' .. '%1$s', Similar = 1},
	{Pattern = 'Equip: .*Increases [your]*[%s]*(.+) by ([%d]+[%%]*).', Return = Color.WHITE .. '+%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s', Similar = 1},
	{Pattern = 'Equip: .*Increases [the]*[your]*[%s]*([%a%s%d]+).', Return = Color.WHITE .. '+ %s', Similar = 1},
	{Pattern = 'Use: Slightly increases [the]*[your]*[%s]*([%a%s%d]+) for ([%a%s%d]+).', Return = Color.WHITE .. '+ %s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s', Similar = 1},
	{Pattern = 'Equip: .*Increase[s]* [your]*[%s]*(.+) by (%d+)%%.', Return = Color.WHITE .. '+%2$d%%' .. Color.LIGHTGREY .. ' ' .. '%1$s', Similar = 1},
	{Pattern = '.*Increase [your]*[%s]*([%a%s]+) for ([%a%s%d]+).', Return = Color.LIGHTGREY .. '+ %s' .. ATSW_FOR .. Color.WHITE .. '%s.', Similar = 1},
	{Pattern = 'Use: Increases [%a%s]*resistance to (%a+)[%a%s]* by (%d+%%*) for ([%d%s%a]+).', Return = Color.WHITE .. '+%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_RESIST .. ATSW_FOR .. Color.WHITE .. '%3$s', Similar = 3},
	{Pattern = 'Increases [%a%s]*resistance to (%a+)[%a%s]* by (%d+%%*).', Return = Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_RESIST, Similar = 3},
	{Pattern = 'Increases (%a+) by (%d+) and .+ critical hit by (%d+)%% for (.+).', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ' %1$s' .. ATSW_AND .. Color.WHITE .. '%3$d%%' .. Color.LIGHTGREY .. ATSW_CRIT .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%4$s'},
	{Pattern = 'the attacker has a (%d+)%%+ chance of being inflicted with disease that increases their damage taken by (%d+) for ([%a%s%d%.]+). Lasts for ([%a%s%d%.]+).', Return = StatWP .. ATSW_OF .. Color.WHITE .. '+%d' .. Color.LIGHTGREY .. ' ' .. ATSW_DAMAGE_ATTACKER_FOR .. Color.WHITE .. '%s,' .. Color.LIGHTGREY .. ATSW_LASTS .. Color.WHITE .. '%s.'},
	{Pattern = '(%d+%%*) chance of dealing (%d+)([%s%a]*) on a successful melee attack.', Return = StatWS .. ' ' .. '%1$d%2$s' .. ATSW_ON_MELEE},
	{Pattern = 'Use: Imbiber is ([%a%s%d]+) for the next ([%a%s%d]+).', Return = StatWS .. ATSW_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'Use: Increases your ([%a%s]+) by (%d+%%*) for ([%d%s%a%.]+).', Return = Color.WHITE .. '+%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_FOR .. Color.WHITE .. '%3$s', Similar = 3},
	{Pattern = 'Use: Increases the player\'s ([%a%s]+) by (%d+%%*) for ([%d%s%a]+).', Return = Color.WHITE .. '+%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_FOR .. Color.WHITE .. '%3$s', Similar = 3},
	{Pattern = 'Use: Increases ([%a%s]+) by (%d+%%*) for ([%d%s%a%.]+).', Return = Color.WHITE .. '+%2$s' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_FOR .. Color.WHITE .. '%3$s', Similar = 3},
	{Pattern = 'Use: attempts to remove one (%a+), one (%a+) and one (%a+) from.+', Return = Color.WHITE .. '-%s, -%s, -%s'},
	
	{Pattern = 'Use: Increases ([%a%s%d]+) by (%d+) to (%d+) and increases (%a+) by (%d+) for ([%a%s%d%.]+).', Return = Color.WHITE .. '%2$d-%3$d ' .. Color.LIGHTGREY .. '%1$s, ' .. Color.WHITE .. '%5$d' .. Color.LIGHTGREY .. ' ' .. '%4$s' .. ATSW_FOR .. Color.WHITE .. '%6$s', Similar = 6},
	{Pattern = 'Use: Increases (.+) by (%d+) to (%d+).', Return = Color.WHITE .. '%2$d-%3$d ' .. Color.LIGHTGREY .. '%1$s', Similar = 6},
	{Pattern = 'Use: Your (.+) is increased and your (.+) goes up by (%d+%%*).+Lasts (.+).', Return = Color.WHITE .. '+%3$s ' .. Color.LIGHTGREY .. '%2$s' .. ATSW_AND .. '%1$s' .. ATSW_FOR .. Color.WHITE .. '%4$s'},
	{Pattern = 'Use: [%a]+ is cured of up to ([%a%s%d]+) poison[s]* up to ([%a%s%d]+).', Return = Color.WHITE .. '-%s' .. Color.LIGHTGREY .. ATSW_POISONS_OF .. Color.WHITE .. '%s'},
	{Pattern = 'Decreases the magical resistances of your spell targets by (%d+).', Return = Color.WHITE .. '-%d' .. Color.LIGHTGREY .. ATSW_TARGETS_ALL_RESIST},
	{Pattern = ': Removes (%d+) magic, curse, poison.+ disease effect.+ every (%d+) seconds for ([%a%s%d]+).', Return = Color.WHITE .. '-%d ' .. Color.LIGHTGREY .. ATSW_NON_PHYSICAL_DEBUFF .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. ATSW_SECONDS_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'Use: Regenerate (.+) for (.+).', Return = StatWS .. ATSW_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'Use: Makes you immune to (.+) for [the%snext]*[%s]*([%a%s%d]+).', Return = Color.LIGHTGREY .. ATSW_IMMUNITY_TO .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s', Similar = 5},
	{Pattern = 'Use: Allows the imbiber to ([%a%s%d]+) for ([%a%s%d]+).', Return = Color.WHITE .. '+ %s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s', Similar = 2},
	{Pattern = 'Use: [%a]+s the imbiber ([%a%s%d]+) for ([%a%s%d]+).', Return = Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s', Similar = 2},
	{Pattern = 'Use: [%a]+s the imbiber ([%a%s%d]+) for ([%a%s%d]+).', Return = Color.WHITE .. '+ %s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s', Similar = 2},
	{Pattern = 'Shows the location of all nearby (%a+) on.+ minimap for ([%a%s%d]+)', Return = Color.LIGHTGREY .. ATSW_SHOWS .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'Use: When applied to a melee weapon it gives a (%d+%%+) chance of casting (.+) at the opponent.+Lasts ([%a%s%d]+).', Return = Color.WHITE .. '+%s' .. Color.LIGHTGREY .. ATSW_TO_CAST .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'Equip: Allows (%d+%%*) of your (%a+) regeneration to [%a]+ while ([%a%s]+).', Return = Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_REGEN_IF .. Color.WHITE .. '%s', Similar = 2},
	{Pattern = 'Equip: Allows ([%a%s%d]+).', Return = Color.WHITE .. '%s', Similar = 2},
	{Pattern = '.*Allows [%a%s%d]+ to ([%a%s%d]+).', Return = Color.WHITE .. '%s', Similar = 2},
	{Pattern = '.*Allows control of a mechanical target for a short time.', Return = Color.WHITE .. ATSW_CONTROL_MECHANICAL},
	{Pattern = 'Shoots a firework .+ that (.+).', Return = Color.LIGHTGREY .. '%s'},
	{Pattern = 'reducing its melee and spell damage by (%d+) and its movement rate by (%d+)%% for (%d+) (%a+).', Return = Color.WHITE .. '-%d' .. Color.LIGHTGREY .. ATSW_MELEE_SPELL_DAMAGE_AND .. Color.WHITE .. '-%d%%' .. Color.LIGHTGREY .. ATSW_MOVEMENT_FOR .. Color.WHITE .. '%d %s'},
	
	{Pattern = 'Use: shrinks .+ reducing [%a]+ ([%a%s]+) by (%d+)', Return = Color.WHITE .. '-%2$d' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_OF_TARGET},
	{Pattern = 'Causes all (%a+) .+ to run away for (%d+) (%a+).', Return = Color.LIGHTGREY .. ATSW_SCARES .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%d %s.'},
	{Pattern = '.*Attaches [%a%s]+ to a (.+) that .+ (%a+) by (%d+%%*)', Return = Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ' ' .. '%2$s' .. ATSW_FOR .. Color.WHITE .. ' %1$s', Similar = 3},
	{Pattern = 'Drops a target dummy .+ (%d+) seconds', Return = Color.LIGHTGREY .. ATSW_ATTRACTS_MONSTERS .. Color.WHITE .. '%d sec.', Similar = 3},
	{Pattern = 'Use: .+ weapon.+ swing (%d+)%%.* for (%d+) (%a+).', Return = StatWP .. ATSW_ATTACK_SPEED_FOR .. Color.WHITE .. '%d %s.'},
	{Pattern = 'Creates a battle chicken.', Return = Color.WHITE .. ATSW_WILL_FIGHT},
	{Pattern = ': Gives you a ([%a%s%d]+) that lets you ([%a%s%d]+).', Return = StatWS .. ATSW_TO_OTHER .. Color.WHITE .. '%s', Similar = 3},
	{Pattern = 'Use: Increases your (.+) by up to (%d+) and your (.+) by up to (%d+) for (.+).', Return = Color.WHITE .. '%2$d %1$s' .. Color.LIGHTGREY .. ATSW_AND .. Color.WHITE .. '%4$d %3$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%5$s', Similar = 3},
	{Pattern = 'Use: Improves your chance to hit by (%d+)%% for (.+).', Return = StatWP .. ATSW_HIT_FOR .. Color.WHITE .. '%s.', Similar = 3},
	{Pattern = 'Use: Improves your chance to hit with spells by (%d+)%% for (.+).', Return = StatWP .. ATSW_SPELL_HIT_FOR .. Color.WHITE .. '%s.', Similar = 3},
	{Pattern = 'Equip: Improves your chance to get a critical strike with ([%a%s]+) by (%d+)%%.', Return = Color.WHITE .. '%2$d%%' .. Color.LIGHTGREY .. ' ' .. '%1$s' .. ATSW_CRIT, Similar = 3},
	{Pattern = 'Use: Improves your chance to get a critical strike by (%d+)%% for (.+).', Return = StatWP .. ATSW_CRIT_FOR .. Color.WHITE .. ' %s.', Similar = 3},
	{Pattern = 'Use: Improves your chance to get a critical strike with([%s%a]*) spells by (%d+)%% for (.+).', Return = Color.WHITE .. '%2$d%% %1$s' .. ATSW_SPELL_CRIT_FOR .. Color.WHITE .. '%3$s.', Similar = 3},
	{Pattern = 'Use: [%a]+s your [%a%d%s]+ to ([%a%s%d]+).', Return = Color.WHITE .. ATSW_WILL .. Color.WHITE .. '%s', Similar = 3},
	{Pattern = '.+: Reduces your (.+)[%a%s%d]* for (%d+)', Return = Color.WHITE .. '-' .. Color.LIGHTGREY .. '%s' .. ATSW_FOR .. Color.WHITE .. '%d sec.', Similar = 3},
	{Pattern = 'Chance on hit: Blasts up to (%d+) (%a+) for (%d+) to (%d+) (%a+) damage', Return = Color.LIGHTGREY .. ATSW_CHANCE_FOR .. Color.WHITE .. '%3$d-%4$d ' .. Color.LIGHTGREY .. '%5$s' .. ATSW_DAMAGE_TO .. ' %1$d %2$s', Similar = 4},
	{Pattern = 'Chance on hit: Blasts .+ (%d+) (%a+) damage', Return = Color.LIGHTGREY .. ATSW_CHANCE_FOR .. Color.WHITE .. '%d ' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE, Similar = 4},
	{Pattern = 'Chance on hit: Sends a .+ at the enemy.+ (%d+) to (%d+) (%a+) damage', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. ' %s' .. ATSW_DAMAGE, Similar = 4},
	{Pattern = 'Use: Blasts ([%a%s]+).', Return = StatWS .. '', Similar = 14},
	{Pattern = 'Use: Deals (%d+) (%a+) damage every (.+) to (.+) for (.+).', Return = StatWS .. Color.LIGHTGREY .. ' ' .. '%s' .. ATSW_DAMAGE_PER .. Color.WHITE .. '%s ' .. Color.LIGHTGREY .. ATSW_TO_OTHER .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'Use: Does (%d+) (%a+) damage .+ yard .+ every (%d+) seconds for ([%a%s%d]+)', Return = Color.WHITE .. '%d' .. Color.LIGHTGREY .. ' ' .. '%s' .. ATSW_DAMAGE_PER .. Color.WHITE .. ' %d sec.' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s.'},
	{Pattern = '.(%d+) attack power in ([%a%s%,]+) forms only', Return = StatW .. ATSW_ATTACK_POWER_IN .. Color.WHITE .. '%s form', Similar = 9},
	{Pattern = '.(%d+) attack power', Return = StatW .. ATSW_ATTACK_POWER, Similar = 9},
	{Pattern = '.(%d+) ranged Attack Power', Return = StatW .. ATSW_RANGED_POWER},
	{Pattern = 'increases attack power by (%d+) against (%a+)', Return = StatW .. ATSW_ATTACK_POWER_AGAINST .. Color.WHITE .. '%s'},
	{Pattern = 'Your attacks ignore (%d+) of the target\'s armor', Return = StatW .. ATSW_ARMOR_IGNORE},
	{Pattern = '[+]+ (%d+) [-]+ (%d+) (%a+) damage', Return = Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. ' ' .. '%s' .. ATSW_DAMAGE},
	{Pattern = '(%d+%.?%d*) damage per second', Return = StatWS .. ATSW_DPS},
	{Pattern = 'Improves your chance to hit by (%d+)', Return = StatWP .. ATSW_HIT, Similar = 3},
	{Pattern = 'Improves your chance to hit with spells by (%d+)', Return = StatWP .. ATSW_SPELL_HIT, Similar = 3},
	{Pattern = 'Improves your chance to get a critical strike by (%d+)', Return = StatWP .. ATSW_CRIT, Similar = 3},
	{Pattern = 'Improves your chance to get a critical strike with([%s%a]*) spells by (%d+)', Return = Color.WHITE .. '%2$d%%' .. Color.LIGHTGREY .. '%1$s' .. ATSW_SPELL_CRIT, Similar = 3},
	{Pattern = 'Heals (%d+) damage over (.+)', Return = StatG .. ATSW_HEALTH_OVER .. Color.WHITE .. '%s'},
	{Pattern = 'Heals (%d+) health and (%d+) mana', Return = StatG .. ATSW_HEALTH .. Color.WHITE .. ', ' .. StatW .. ATSW_MANA},
	{Pattern = 'Dispels polymorph', Return = Color.LIGHTGREY .. ATSW_DISPEL .. ' ' .. Color.WHITE .. ATSW_POLYMORPH},
	{Pattern = 'Restores (%d+) ([^t][%a%s%d][%a%s%d][%a%s%d]*)(%.?%s?)', Return = StatG .. ' %s'},
	{Pattern = 'Restores (%d+) to (%d+) (.+).', Return = Color.GREEN .. '%d' .. Color.LIGHTGREY .. '-' .. Color.GREEN .. '%d' .. Color.LIGHTGREY .. ' ' .. '%s'},
	
	{Pattern = 'Reduces the cooldown of your (.+) ability by (.+)', Return = StatWS .. ATSW_CD_REDUCED_BY .. Color.WHITE .. '%s'},
	{Pattern = 'Reduces the mana cost of your (.+) by (.+)', Return = StatWS .. ATSW_COST_REDUCED_BY .. Color.WHITE .. '%s'},
	
	{Pattern = 'Drains (%d+) to (%d+) mana .+ Silences .+ (%d+)', Return = Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. ATSW_MANA_BURN_SILENCE .. Color.WHITE .. '%d sec.'},
	{Pattern = 'Equip: (%d+)%% chance.+ (%d+) to (%d+)([%a%s]*) damage on a successful melee attack', Return = Color.WHITE .. '%d%%' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE, Similar = 4},
	{Pattern = 'chance to strike your ranged target.* (%d+) to (%d+)([%a%s]*) damage', Return = Color.LIGHTGREY .. ATSW_CHANCE_FOR .. Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE, Similar = 4},
	{Pattern = 'damaging you for (%d+) to (%d+)([%s%a]*) damage', Return = Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE_TO_YOU},
	{Pattern = '(%d+) to (%d+)([%s%a]*) damage to you', Return = Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE_TO_YOU},
	{Pattern = '(%d+)%% chance to stun.*(%d+) sec.', Return = Color.LIGHTGREY .. ATSW_STUN .. Color.WHITE .. '%2$d sec,' .. Color.LIGHTGREY .. ATSW_CHANCE .. Color.WHITE .. '%1$d%%', Similar = 5},
	{Pattern = 'Chance on hit: stun.*(%d+)%s*sec', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF_STUN .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. ATSW_SECONDS, Similar = 5},
	{Pattern = 'Use: Increase (%a+) by (%d+).', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ' %1$s'},
	{Pattern = 'Use: Increase ([%a%s]+) damage by (%d+) for (.+).', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ATSW_DAMAGE_FOR .. ' ' .. Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s'},
	{Pattern = ': ([%a]+) Damage received is reduced by (%d+%%*).', Return = Color.WHITE .. '-%2$s' .. Color.LIGHTGREY .. ' %1$s' .. ATSW_DAMAGE_RECEIVED},
	{Pattern = 'When struck by a harmful spell, the caster of that spell has a (%d+)%% chance to.* ([%a]+)[d].* for (.+).', Return = StatWP .. ATSW_TO_OTHER .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_ATTACKER_OF_SPELL_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'When struck by a non%-periodic damage spell you have a (%d+)%% chance of getting a (.+) spell shield that absorbs (%d+) to (%d+) of that school of damage', Return = Color.WHITE .. '%1$d%%' .. Color.LIGHTGREY .. ATSW_IF_DAMAGED_BY_SPELL .. Color.WHITE .. '%3$d-%4$d' .. Color.LIGHTGREY .. ATSW_OF_SAME_SCHOOL_FOR .. Color.WHITE .. '%2$s', Similar = 4},
	{Pattern = '(%d+) to (%d+)([%a%s]*) damage', Return = Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE, Similar = 4},
	{Pattern = 'When struck.* has a (%d+)%% chance to heal you for (%d+) to (%d+).', Return = StatWP .. ATSW_TO_RESTORE .. Color.WHITE .. '%d-%d' .. Color.LIGHTGREY .. ATSW_HEALTH_IF_DAMAGED, Similar = 10},
	{Pattern = 'Heal ([%a%s]+) for (%d+) to (%d+).', Return = Color.GREEN .. '%2$d-%3$d' .. Color.LIGHTGREY .. ATSW_HEALTH_TO .. Color.WHITE .. '%1$s', Similar = 10},
	{Pattern = 'When struck.* has a (%d+)%% chance of stealing (%d+) life from the attacker over (.+).', Return = StatWP .. ATSW_CHANCE_OF .. ATSW_VAMPIRISM .. ': ' .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. ATSW_OVER .. Color.WHITE .. '%s'},
	{Pattern = 'When struck.* has a (%d+)%% chance to reduce damage taken by (%a+) .+ by (%d+%%*) for ([%a%s%d]+)', Return = StatWP .. ATSW_CHANCE_TO_REDUCE .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_DAMAGE_TAKEN_BY .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'When struck by.* (%a+) attacker, that attacker has.* (%d+)%% chance of.+ to (%a+) for (%d+) (%a+).+ level (%d+) and below', Return = Color.WHITE .. '%2$d%%' .. Color.LIGHTGREY .. ATSW_CHANCE_TO .. Color.WHITE .. '%3$s ' .. Color.LIGHTGREY .. '%1$s' .. Color.LIGHTGREY .. ATSW_ATTACKER_OF_LEVEL .. Color.WHITE .. '%6$d' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%4$d %5$s.'},
	{Pattern = 'Adds [+](%d+) healing and damage from spells to an item worn on the ([%a%s%,]+).+ level (%d+) and above', Return = Color.WHITE .. '%d' .. Color.LIGHTGREY .. ATSW_SPELL_POWER_FOR .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_OF_LEVEL .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. ATSW_AND_ABOVE},
	{Pattern = 'Adds (%d+) (%a+) damage to your [%a]+ attack', Return = StatW .. ATSW_OTHER_DAMAGE},
	{Pattern = 'Equip: Immune to Disarm', Return = Color.LIGHTGREY .. ATSW_IMMUNE_TO .. Color.WHITE .. ATSW_DISARM},
	{Pattern = 'Chance on hit: Disarm .* for (%d+) sec.', Return = Color.LIGHTGREY .. ATSW_CHANCE_TO .. Color.WHITE .. ATSW_DISARM .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%d sec.'},
	{Pattern = 'Chance on hit: protect[s]*.* with a (%a+) shield.', Return = Color.LIGHTGREY .. ATSW_CHANCE_FOR .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_SHIELD},
	{Pattern = 'Chance on hit: reduce[s]*.* threat [%a%s\']+.', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. ATSW_MINUS_THREAT},
	{Pattern = 'Chance on hit: reduce[s]*.* (%a+) by (%d+%%*) for (%d+) (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '-%2$s' .. Color.LIGHTGREY .. ATSW_TARGETS_STAT .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%3$d %4$s.', Similar = 12},
	{Pattern = 'Chance on hit: reduce[s]*.* (%a+) by (%d+%%*).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '-%2$s' .. Color.LIGHTGREY .. ATSW_TARGETS_STAT, Similar = 12},
	{Pattern = '. Stacks up to (%d+) times.', Return = Color.LIGHTGREY .. ATSW_STACK .. Color.WHITE .. '%d'},
	{Pattern = 'Chance on hit: dispels[%a%s\']+.', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. ATSW_DISPEL},
	{Pattern = 'Chance on hit: .+ target for (%d+) (%a+) damage and an additional (%d+)([%s%a]*) damage over ([%d%.]+) (%a+)', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. ' %s' .. ATSW_DAMAGE_AND .. Color.WHITE .. '%d%s' .. Color.LIGHTGREY .. ATSW_DAMAGE_OVER .. Color.WHITE .. '%s %s.', Similar = 11},
	{Pattern = 'Chance on hit: .+ (%d+)([%s%a]*) damage over ([%d%.]+) (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE_OVER .. Color.WHITE .. '%s %s.', Similar = 11},
	{Pattern = 'Chance on hit: Party .+ crit increased by (%d+%%+).+Lasts.* ([%d%.]+) (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '+%s' .. Color.LIGHTGREY .. ATSW_CRIT_FOR_PARTY .. Color.WHITE .. '%s %s.'},
	{Pattern = 'Give[s] (%d+).* (%a+) to.* party members.', Return = Color.WHITE .. '%d' .. Color.LIGHTGREY .. ' %s' .. ATSW_FOR_PARTY},
	{Pattern = 'Equip: Increase[s]*.* (%a+) of.* party members by (%d+).', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ' %1$s' .. ATSW_FOR_PARTY},
	{Pattern = 'Chance on landing a damaging spell to deal (%d+)([%s%a]*) damage while sacrificing (%d+) (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. '%s' .. ATSW_DAMAGE_AND .. Color.WHITE .. '-%d' .. Color.LIGHTGREY .. ATSW_HEALTH_ON_SPELL_HIT},
	{Pattern = 'Chance on hit: Spell damage taken by target.* increased by (%d+%%*) for ([%d%.]+) (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '+%s' .. Color.LIGHTGREY .. ATSW_SPELL_DAMAGE_TAKEN_BY_TARGET},
	{Pattern = 'Chance on hit: Increase[s]*.* critical strike chance of.* next attack made within (%d+) (%a+) by (%d+)%%', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '+%3$d' .. Color.LIGHTGREY .. ATSW_CRIT_OF_NEXT_ATTACK .. Color.WHITE .. '%1$d %2$s'},
	{Pattern = 'and slowing (%a+) speed by (%d+)%% for (%d+) (%a+)', Return = Color.WHITE .. '-%2$d%%' .. Color.LIGHTGREY .. ' %1$s' .. ATSW_FOR .. '%3$d %4$s.'},
	{Pattern = 'Chance on hit: .+ movement slow.* by (%d+)%% and increasing the time between attacks by (%d+)%% for (%d+) (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '-%d%%' .. Color.LIGHTGREY .. ATSW_MOVEMENT_AND .. Color.WHITE .. '-%d%% ' .. Color.LIGHTGREY .. ATSW_ATTACK_SPEED_OF_TARGET .. Color.WHITE .. '%d %s'},
	{Pattern = 'Chance on hit: Heal self for (%d+) to (%d+) and increases ([%a%s]+) by (%d+) for ([%d%.]+) (%a+).', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%1$d-%2$d' .. Color.LIGHTGREY .. ATSW_HEALTH_AND .. Color.WHITE .. '%4$d' .. Color.LIGHTGREY .. '%3$s' .. ATSW_FOR .. Color.WHITE .. '%5$s %6$s'},
	{Pattern = 'On successful melee or ranged attack.+ (%d+) (%a+) and.+ drain (%d+) (%a+)', Return = Color.LIGHTGREY .. ATSW_CHANCE_OF .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. '%s' .. ATSW_AND_DRAIN .. Color.WHITE .. '%d' .. Color.LIGHTGREY .. ATSW_MANA_ON_HIT},
	{Pattern = 'Protects the wearer from .+ Shadow Flame', Return = Color.LIGHTGREY .. ATSW_PROTECTION_FROM .. Color.WHITE .. 'Onyxia\'s Shadow Flame'},
	{Pattern = '(%d+) yard[s]*', Return = Color.LIGHTGREY .. ATSW_RADIUS .. Color.WHITE .. ' %d'},
	{Pattern = 'stuns [%a%s%d]+ for (%d+) (%a+)', Return = Color.LIGHTGREY .. ATSW_STUN .. Color.WHITE .. '%d %s', Similar = 5},
	
	{Pattern = 'companion', Return = ATSW_COMPANION},
	{Pattern = 'Adds a toy', Return = ATSW_TOY},
	{Pattern = 'Goblin Jumper Cables XL', Return = Color.WHITE .. '50%%' .. Color.LIGHTGREY .. ATSW_CHANCE_TO_RESURRECT, Similar = 'cables'},
	{Pattern = 'Goblin Jumper Cables', Return = Color.WHITE .. '33%%' .. Color.LIGHTGREY .. ATSW_CHANCE_TO_RESURRECT, Similar = 'cables'},
	{Pattern = 'Portable Wormhole Generator: ([%a%s%d%-]+)', Return = Color.LIGHTGREY .. ATSW_PORTAL_TO .. Color.WHITE .. '%s'},
	{Pattern = 'Use: .+ transport[s]* .+ to ([%a%s]+)', Return = Color.LIGHTGREY .. ATSW_TELEPORT_TO .. Color.WHITE .. '%s'},
	{Pattern = 'control.* mind .+ for (%d+) (%a+)', Return = Color.LIGHTGREY .. ATSW_MIND_CONTROL_FOR .. Color.WHITE .. '%d %s'},
	{Pattern = 'detects.* stealth.* invisible', Return = Color.WHITE .. ATSW_STEALTH_INVISIBILITY_DETECTION},
	{Pattern = 'World Enlarger', Return = Color.LIGHTGREY .. ATSW_REDUCE_YOUR .. Color.WHITE .. ATSW_SIZE},
	{Pattern = 'Charge an enemy, knocking it silly for (%d+) seconds.', Return = Color.LIGHTGREY .. ATSW_INCAPACITATE .. Color.WHITE .. '%d sec.'},
	{Pattern = 'Use: .+ protect.* (%d+) damage.* over.* (%d+) (%a+).', Return = Color.WHITE .. '%d' .. Color.LIGHTGREY .. ATSW_DAMAGE_ABSORB_FOR .. Color.WHITE .. '%d %s.'},
	{Pattern = 'Gordok Ogre Suit', Return = Color.LIGHTGREY .. ATSW_DISGUISE .. Color.WHITE .. ATSW_GORDOK_OGRE},
	{Pattern = 'Savory Deviate Delight', Return = Color.LIGHTGREY .. ATSW_DISGUISE .. Color.WHITE .. ATSW_PIRATE_OR_NINJA},
	{Pattern = 'Flask of Petrification', Return = Color.WHITE .. ATSW_FLASK_OF_PETRIFICATION},
	{Pattern = 'Grants (%d+)%% spell critical and (%d+) ([%a%s]+) for (.+).', Return = Color.WHITE .. '%d%%' .. Color.LIGHTGREY .. ATSW_CRIT .. ATSW_AND .. Color.WHITE .. '%d %s' .. Color.LIGHTGREY .. ATSW_FOR .. '%s'},
	
	{Pattern = 'Increase[s]*.+ damage of a ([%a%s-]+) by (%d+) for (.+).', Return = Color.WHITE .. '%2$d' .. Color.LIGHTGREY .. ATSW_DAMAGE_FOR .. ' ' .. Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s'},
	{Pattern = 'Attach.* .+ to your ([%a%s-]+) that increase[s]* your ([%a%s]+) by (%d+).', Return = Color.WHITE .. '%3$d' .. Color.LIGHTGREY .. ' %2$s' .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
	{Pattern = 'Attach.* .+ to your ([%a%s-]+) that deal[s]* damage every time you block with it.', Return = Color.LIGHTGREY .. ATSW_DAMAGE_ON_BLOCK_FOR .. Color.WHITE .. '%1$s', Similar = 3},
	{Pattern = 'Attach.* .+ to your ([%a%s-]+), making it impossible to ([%a%s]+).', Return = Color.LIGHTGREY .. ATSW_IMMUNITY_TO .. Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s'},
	{Pattern = 'Removes existing [%a%s]+ and makes you immune to ([%a%s]+) for (.+).', Return = Color.LIGHTGREY .. ATSW_IMMUNITY_TO .. Color.WHITE .. '%s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%s'},
	{Pattern = 'Attach.* [%a]+ to your ([%a%s]+) that increase[s]* your ([%a%s]+) slightly.', Return = Color.WHITE .. '+%2$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s', Similar = 3},
	{Pattern = 'Attach.* a counterweight to a (.+) making it (%d+)%% faster', Return = Color.WHITE .. '+%2$d%%' .. Color.LIGHTGREY .. ATSW_ATTACK_SPEED_FOR .. Color.WHITE .. '%1$s'},
	{Pattern = 'Use: .*increase the (%a+) .+ worn on the ([%a%s%,]+) by (%d+).+ level (%d+) and above.', Return = Color.WHITE .. '%3$d' .. Color.LIGHTGREY .. ' %1$s' .. ATSW_FOR .. Color.WHITE .. '%2$s' .. Color.LIGHTGREY .. ATSW_OF_LEVEL .. Color.WHITE .. '%4$d' .. Color.LIGHTGREY .. ATSW_AND_ABOVE, Similar = 15},
	{Pattern = 'Use: .*increase the (%a+) .+ worn on the ([%a%s%,]+) by (%d+) and (%a+) by (%d+).', Return = Color.WHITE .. '%3$d' .. Color.LIGHTGREY .. ' %1$s' .. ATSW_AND .. Color.WHITE .. '%5$d' .. Color.LIGHTGREY .. ' %4$s' .. ATSW_FOR .. Color.WHITE .. '%2$s', Similar = 15},
	{Pattern = 'Use: Increase critical chance on [a%s]*([%a%s]+) by (%d+)%% for (.+).', Return = Color.WHITE .. '%2$d%%' .. Color.LIGHTGREY .. ATSW_CRIT_FOR .. ' ' .. Color.WHITE .. '%3$s' .. Color.LIGHTGREY .. ATSW_FOR .. Color.WHITE .. '%1$s'},
	{Pattern = ': [%a]+s [%a%s%d]+ that [%a]*[%s]*([%a%s%d]+).', Return = StatWS, LastResort = true},
	{Pattern = 'Use: Increases ([%a%s%d]+) by (%d+)%.', Return = Color.WHITE .. '+%2$d ' .. Color.LIGHTGREY .. '%1$s.', LastResort = true},
}

for _, Item in pairs(EnchantPatterns) do
	Item.Pattern = string.lower(Item.Pattern)
end

for _, Item in pairs(PoisonPatterns) do
	Item.Pattern = string.lower(Item.Pattern)
end

for _, Item in pairs(AttributePatterns) do
	Item.Pattern = string.lower(Item.Pattern)
end

local function ReplaceWords(w)
	local r = ''
	
	if w == 'one' then
		r = 1
	elseif w == 'two' then
		r = 2
	elseif w == 'three' then
		r = 3
	elseif w == 'four' then
		r = 4
	elseif w == 'five' then
		r = 5
	elseif w == 'six' then
		r = 6
	elseif w == 'seven' then
		r = 7
	elseif w == 'eight' then
		r = 8
	elseif w == 'nine' then
		r = 9
	end
	
	return r
end

local function GetAttributes(Recipe)
	if Recipe.Type == 'header' then
		return ''
	end
	
	if Recipe.Attributes then
		return Recipe.Attributes
	end
	
	ATSWRecipeItemTooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT')
	
	local GamePosition = GetPositionFromGame(Recipe.Name)
	
	if GamePosition then
		ATSW_TooltipSetSkill(ATSWRecipeItemTooltip, GamePosition)
	else
		return
	end
	
	local I, Text, TextRight = 0
	local Return = ''
	local IsCloth
	local IsPoison
	
	repeat
		I = I + 1
		Text = _G['ATSWRecipeItemTooltipTextLeft' .. I]
		TextRight = _G['ATSWRecipeItemTooltipTextRight' .. I]
		Text = Text and Text:GetText()
		TextRight = TextRight and TextRight:GetText()
		
		local Similar = false
		
		if TextRight == 'Cloth' then
			IsCloth = true
		end
		
		if Text then
			Text = string.lower(Text)
			
			if I == 1 and string.find(Text, 'poison') then
				IsPoison = true
			end
		end
		
		local cR, cG, cB = _G['ATSWRecipeItemTooltipTextLeft' .. I]:GetTextColor()
		
		cR = math.floor(cR + 0.5)
		cG = math.floor(cG + 0.5)
		cB = math.floor(cB + 0.5)
		
		if Text 
		and string.sub(Text, 1, 1) ~= '\"'
		and not string.find(Text, '%(%d+%) ') then
			local Patterns, PatternFound
			
			if string.find(string.sub(Text, 1, 26), 'enchant[s]* ') then
				Patterns = EnchantPatterns
			elseif IsPoison then
				Patterns = PoisonPatterns
			else
				Patterns = AttributePatterns
			end
			
			for _, Item in pairs(Patterns) do
				if Item.Similar ~= Similar
				and not (Item.LastResort and PatternFound) then
					local PStart, PEnd, A, B, C, D, E, F = string.find(Text, Item.Pattern)
					
					if PStart and not (Item.Pattern == '(%d+) armor' and IsCloth) then
						PatternFound = true
						
						if Return ~= '' then
							Return = Return .. Color.WHITE .. ',|r '
						end

						if Item.Return then
							local Minus = ''
							
							if Item.ReplaceWords == 1then
								A = ReplaceWords(A)
							end
							
							if string.sub(Text, 1, 1) == '-' then
								Minus = Color.WHITE .. '-|r'
							end
							
							Return = Return .. Minus .. string.format(Item.Return, A, B, C, D, E, F) .. '|r'
						else
							Return = Return .. Color.LIGHTGREY .. Text .. '|r'
						end
						
						if Item.Similar then
							Similar = Item.Similar
						end
						
						if string.find(Return, 'str')
						and string.find(Return, 'agi')
						and string.find(Return, 'sta')
						and string.find(Return, 'int')
						and string.find(Return, 'spi') then
							local _, _, str = string.find(Return, '(%d+)' .. Color.LIGHTGREY .. ' str')
							local _, _, agi = string.find(Return, '(%d+)' .. Color.LIGHTGREY .. ' agi')
							local _, _, sta = string.find(Return, '(%d+)' .. Color.LIGHTGREY .. ' sta')
							local _, _, int = string.find(Return, '(%d+)' .. Color.LIGHTGREY .. ' int')
							local _, _, spi = string.find(Return, '(%d+)' .. Color.LIGHTGREY .. ' spi')
							
							if str == agi and str == sta and str == int and str == spi then
								local Start = string.find(Return, '%d+' .. Color.LIGHTGREY .. ' str')
								local _, End, Amount = string.find(Return, '(%d+)' .. Color.LIGHTGREY .. ' spi.')
								
								local StrLeft = string.sub(Return, 1, Start-1)
								local StrRight = string.sub(Return, End+1, string.len(Return))
								
								Return = StrLeft .. Amount .. Color.LIGHTGREY .. ' all attributes|r' .. StrRight
							end
						end
						
						if string.find(Return, 'arcane resist')
						and string.find(Return, 'fire resist')
						and string.find(Return, 'nature resist')
						and string.find(Return, 'frost resist')
						and string.find(Return, 'shadow resist') then
							local Start = string.find(Return, '%d+' .. Color.LIGHTGREY .. ' arcane')
							local _, End, Amount = string.find(Return, '(%d+)' .. Color.LIGHTGREY .. ' shadow resist')
							
							local StrLeft = string.sub(Return, 1, Start-1)
							local StrRight = string.sub(Return, End+1, string.len(Return))
							
							Return = StrLeft .. Amount .. Color.LIGHTGREY .. ' all resist' .. StrRight
						end
						
						if string.find(string.sub(Text, 1, 26), 'enchant[s]* ') then
							break
						end
						
						if (cR == 1 and cG == 1 and cB == 1)
						or	string.len(Text) - (PEnd-PStart+1) < 11 then -- Optimization: detection of full pattern match
							break
						end
						
						if PStart == 1 and PEnd == string.len(Text) then
							break
						end
					end
				end
			end

			if Return == ''
			and I == ATSWRecipeItemTooltip:NumLines()
			and I > 1
			and not string.find(Text, 'races: ')
			and not string.find(Text, 'classes: ') 
			and not string.find(Text, 'tools: ') 
			and not string.find(Text, 'reagents: ') then
				if not (cR == 1 and cG == 1 and cB == 1) then
					local Pos = string.find(Text, ': ')
					
					if not Pos then
						Pos = 0
					else
						Pos = Pos + 2
					end
					
					Text = string.sub(Text, Pos, string.len(Text))

					if string.len(Text) > 47 then
						Text = string.sub(Text, 1, 47) .. '...'
					end
					
					Return = Color.LIGHTGREY .. Text .. '|r'
				end
			end
		end
	until not Text
	
	ATSWRecipeItemTooltip:SetOwner(this, '')
	
	Recipe.Attributes = Return
	
	return Return
end

local function RemoveColorTags(Text)
    local Result = Text
	
    while string.find(Result, '|c%x%x%x%x%x%x%x%x') do
        Result = string.gsub(Result, '|c%x%x%x%x%x%x%x%x', '')
    end
	
    Result = string.gsub(Result, '|r', '')
	
    return Result
end

function ATSW_UpdateRecipes()
	local ScrollOffset 				= ScrollOffset() / ATSW_TRADESKILL_HEIGHT
	local TextureWidth				= ATSWRecipe1Texture:GetWidth()
	local _, _, _, TextureLeft	= ATSWRecipe1Texture:GetPoint(1)
	local FrameWidth				= ATSWListScrollFrame:GetWidth()
	local SkillUpReserve			= 0				-- no list skill-up text, so no extra reserve
	
	for I = 1, ATSW_RECIPES_DISPLAYED do
		local Button 					= _G['ATSWRecipe' .. I]
		
		local Index 					= I + ScrollOffset
		local Exist 						= Index <= RecipesSortedSize()
		local R, Possible
		local Text, SubText = ''
		
		SetVisible(Button, false) -- Needed for tooltip update if scrolled
		SetVisible(Button, Exist)
		
		if Exist then
			R = RecipeSorted(Index)
			
			if R.Type == 'header' then
				R.Texture 				= GetCategoryTexture(IsExpanded(R.Name))
			else
				if not (R.Name and R.Texture and (R.Link or IsBeastTraining())) then
					RecipesDataIsComplete 	= RecipesDataIsComplete + 2
					RecipesDataTries 			= RecipesDataIsComplete
				end
			end
			
			local ButtonText		= _G['ATSWRecipe' .. I .. 'Text']
			local ButtonSubText	= _G['ATSWRecipe' .. I .. 'SubText']
			local ButtonTexture 	= _G['ATSWRecipe' .. I .. 'Texture']
			local QualityTexture 	= _G['ATSWRecipe' .. I .. 'QualityTexture']
			local ButtonHighlight 	= _G['ATSWRecipe' .. I .. 'Highlight']
			
			local point, relativeTo, relativePoint, _, yOfs = Button:GetPoint(2) -- LEFT, ATSWFrame, LEFT
			local BorderSize 			= 0.071
			local cR, cG, cB 			= GetLinkColorRGB(R.Link)
			local PossibleAmount	= 0
			local PossibleTotal		= 0
			local TypeColor 			= ATSWTypeColor[R.Type]
			local XOffset				= 0
			local HighlightSize 		= 0.2
			local TP = R.TrainingCost
			
			if R.Type == 'header' then
				HighlightSize 			= 0
				BorderSize 				= 0
			else
				XOffset 					= 20
				
				if not IsBeastTraining() then
					PossibleAmount 		= ATSW_HowManyItemsArePossibleToCreate(R.Name,
						ATSW_Options.ConsiderBank 			and ATSW_POSSIBLE_BANK,
						ATSW_Options.ConsiderAlts 			and ATSW_POSSIBLE_ALTS,
						ATSW_Options.ConsiderMerchants 	and ATSW_POSSIBLE_MERCHANT)
					PossibleTotal 			= ATSW_HowManyItemsArePossibleToCreateWithConsidering	(R.Name)
					
					if ATSW_Options.Unified then
						Possible 			= PossibleAmount > 0 and PossibleAmount
					elseif PossibleTotal > 0 then
						Possible				= PossibleAmount .. '/' .. PossibleTotal
					end
					
					if Possible then
						Possible				= ' |cffB0B0B0[' .. Possible .. ']|r'
					end
				end
			end
			
			if ATSW_ShowAttributes() and R.Type ~= 'header' then
				Text = GetAttributes(R)
				Button:SetFont('Fonts\\FRIZQT__.ttf', 10)
			else
				Text = R.Name .. SubNameToString(R.SubName)
				Button:SetFont('Fonts\\FRIZQT__.ttf', 12)
			end
			
			Text = Text .. (Possible or '')
			
			if TP and TP > 0 then
				SubText = format(TRAINER_LIST_TP, TP)
				
				if R.Type == 'used' then
					SubText = Color.GREY .. SubText .. '|r'
				end
			else
				SubText = ConvertCooldown(R.Cooldown) or ''
			end
			
			Button:SetText(RemoveColorTags(Text))
			
			local TextWidth = Button:GetTextWidth()

			Button:				SetText				(Text)
			ButtonSubText:	SetText				(SubText)
			Button:				SetTextColor		(TypeColor.R, TypeColor.G, TypeColor.B)

		-- Skill-up thresholds are intentionally shown only in tooltips, not in the list row,
		-- because the four-colour string overlaps the recipe name on the narrow list entries.
		local SkillUpText = _G['ATSWRecipe' .. I .. 'SkillUpText']
		if SkillUpText then
			SkillUpText:Hide()
		end
			Button:				SetPoint			(point, relativeTo:GetName(), relativePoint, Button.XOffset + XOffset, yOfs)
			
			if R.Type ~= 'header' then
				Button:			SetWidth			(FrameWidth - XOffset + 4)
			else
				Button:			SetWidth			(math.min(TextureLeft + TextureWidth + TextWidth, FrameWidth - XOffset) + 4)
			end
			
			local MaxTextWidth = math.max(0, FrameWidth - XOffset - SkillUpReserve - 25)
			if TextWidth > MaxTextWidth then
				TextWidth = MaxTextWidth
			else
				TextWidth = 0
			end
			
			ButtonText:		SetWidth			(TextWidth)
			ButtonTexture:	SetTexture		(R.Texture)
			ButtonTexture:	SetTexCoord		(0+BorderSize, 1-BorderSize, 0+BorderSize, 1-BorderSize)
			ButtonHighlight:	SetTexCoord		(0+HighlightSize, 1-HighlightSize, 0+HighlightSize, 1-HighlightSize)
			ButtonHighlight:	SetDesaturated	(R.Type ~= 'header')
			QualityTexture:	SetVertexColor	(cR, cG, cB)
			
			SetVisible(QualityTexture, cR and cG and cB and not (cR == 1 and cG == 1 and cB == 1))
			
			if R.Type == 'header' then
				Button:RegisterForClicks('LeftButtonUp')
			else
				Button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
			end
		end
		
		Button.Name 			= R and (R.Name .. (R.SubName and R.SubName ~= '' and ('   (' .. R.SubName .. ')') or ''))
		Button.SubName	= R and R.SubName
		Button.Type 			= R and R.Type
		Button.Link			= R and R.Link
		Button.Position		= R and R.Position
		Button.Possible 		= Possible
		Button.Text			= Text
	end
	
	ATSW_SetHighlight(RecipeSelected())
	ATSW_UpdateListScroll()
end

function ATSW_HideRecipes()
	for I = 1, ATSW_RECIPES_DISPLAYED do
		_G['ATSWRecipe' .. I]:Hide()
	end
end

function ATSW_UpdateTasks()
	if IsBeastTraining() or IsEnchanting() then
		ATSW_HideTasks()
		SetVisible(ATSWTaskScrollFrame, false)
		
		return
	end
	
    local Offset 				= FauxScrollFrame_GetOffset(ATSWTaskScrollFrame)
	
	for I = 1, ATSW_TASKS_DISPLAYED do
		local Button 			= _G['ATSWTask' .. I]
		local DeleteButton 	= _G['ATSWTask' .. I .. 'DeleteButton']
		
		local Name, Type, Amount, Texture, Link, Cooldown, Pos, Text, TypeColor, Possible
		local Index 			= I + Offset
		local Exist 				= Task(Index)
		local tR, tG, tB 		= 1, 1, 1
		
		SetVisible(Button, false) -- It is needed for tooltip update if button text is changed
		SetVisible(Button, Exist)
		SetVisible(DeleteButton, Exist)
		
		if Exist then
			Name				= Exist.Name
			Amount				= Exist.Amount
			Texture				= Exist.Texture
			Time					= GetCraftingTime(Name, Amount)
			
			Pos = GetRecipePosition(Name)
			
			if Pos then
				Type 			= Recipe(Pos).Type or 'trivial'
				Link				= Recipe(Pos).Link
				Cooldown 		= Recipe(Pos).Cooldown
				TypeColor 		= ATSWTypeColor[Type]
				tR, tG, tB 		= TypeColor.R, TypeColor.G, TypeColor.B
			end
			
			local ItemTexture 			= _G['ATSWTask' .. I .. 'Texture']
			local QualityTexture 		= _G['ATSWTask' .. I .. 'QualityTexture']
			local TimeCost		 		= _G['ATSWTask' .. I .. 'TimeCost']
			local R, G, B 					= GetLinkColorRGB(Link)
			local t_Width 				= ItemTexture:GetWidth()
			local _, _, _, t_xOfs, _ 	= ItemTexture:GetPoint(0)
			local NameIsProcessing 	= Processing.Active and (Name == Processing.Recipe)
			local PossibleAmount		= ATSW_HowManyItemsArePossibleToCreateWithConsidering(Name)
			
			if PossibleAmount > 0 then
				PossibleAmount 			= '|cff10C010' .. PossibleAmount .. '|r'
			end
			
			Text = Name .. ' |cffB0B0B0[' .. Amount .. '/' .. PossibleAmount .. '|cffB0B0B0]|r'
			
			Button.R 						= tR
			Button.G 						= tG
			Button.B 						= tB
			Button.TaskIndex 			= Index
			DeleteButton.TaskIndex 	= Index
			
			Button:				SetText			(Text .. (ConvertCooldown(Cooldown) or ''))
			Button:				SetTextColor	(tR, tG, tB)
			ItemTexture:		SetTexture	(Texture)
			Button:				SetWidth		(Button:GetTextWidth() + t_xOfs + t_Width + 4)
			QualityTexture:	SetVertexColor(R, G, B)
			TimeCost:			SetText			(ShortFormatCooldown(Time, true))
			
			SetVisible(DeleteButton, 	not NameIsProcessing)
			SetVisible(TimeCost, 		not NameIsProcessing)
			SetVisible(QualityTexture, R and G and B and not (R == 1 and G == 1 and B == 1))
			
			Button:SetAlpha(1)
		end
		
		Button.Name 			= Name
		Button.Text			= Text
		Button.Position		=	Pos
		Button.TaskIndex	= Exist and Index
	end
	
	SetEnabled	(ATSWReagentsButton, 	NecessaryReagentsSize() ~= 0)
	SetVisible		(ATSWWeb, 					TasksSize() == 0)
	
	ATSW_UpdateCreateButton()
	ATSW_UpdateTaskListScroll()
end

function ATSW_HideTasks()
	for I = 1, ATSW_TASKS_DISPLAYED do
		_G['ATSWTask' .. I]:Hide()
	end
end

function ATSW_ShowSort()
	SetSortCheckboxes(SortBy())
end

function ATSW_ShowSearch()
	ATSW_BlockSearchTextChanged = true
	ATSWSearchBox:SetText(SearchString())
	
	SetVisible(ATSWSearchLabel, SearchString() == '')
	SetVisible(ATSWSearchIcon,  SearchString() == '')
	
	if SearchString() == '' then
		ATSWSearchBox:ClearFocus()
	end
	
	ATSW_BlockSearchTextChanged = false
end

function ATSW_ShowDropDown()
	UIDropDownMenu_Initialize(ATSWSubClassDropDown, 	ATSWSubClassDropDown_Initialize)
	UIDropDownMenu_Initialize(ATSWInvSlotDropDown, 	ATSWInvSlotDropDown_Initialize)
end

function ATSW_ShowSelection()
	local function FirstCraft()
		local Name, SubName = GetCraftNameType(GetFirstCraft())
		
		if SubName and SubName ~= '' then
			Name = Name .. '   (' .. SubName .. ')'
		end
		
		return Name
	end

	ATSW_SelectRecipe(RecipeSelected() or FirstCraft())
end

function ATSW_ShowAmount()
	local Number = ATSW_Amount[realm][player][Profession()]
	
	if Number == 0 then
		ATSWAmountBox:SetText(ATSW_ALL)
	else
		ATSWAmountBox:SetNumber(Number)
	end
end

function ATSW_ShowTrainingPoints()
	if IsBeastTraining() then
		local Total, Spent = GetPetTrainingPoints()
		
		ATSWTrainingPointsText:SetText(Total - Spent)
		ATSWTrainingPointsFrame:SetWidth(ATSWTrainingPointsLabel:GetWidth()+ATSWTrainingPointsText:GetWidth()+20)
	end
end

function ATSW_ShowAmountMenu			(Visible)
	SetVisible(ATSWAmountText, 			Visible)
	SetVisible(ATSWDecrementButton, 	Visible)
	SetVisible(ATSWAmountBox, 			Visible)
	SetVisible(ATSWIncrementButton, 	Visible)
end

function ATSW_ShowDropDownMenu		(Visible)
	ATSWSubClassDropDown:				Hide() -- Needed for Dropdown list disappearance if changing professions
	ATSWInvSlotDropDown:					Hide()
	
	SetVisible(ATSWSubClassDropDown, 	Visible)
	SetVisible(ATSWInvSlotDropDown, 	Visible)
end

function ATSW_ShowReagentsButton		(Visible)
	SetVisible(ATSWReagentsButton, 		Visible)
	
	if not Visible then
		ATSWReagentsFrame:Hide()
	end
end

function ATSW_ShowTaskButton			(Visible)
	SetVisible(ATSWTaskButton, 			Visible)
end

function ATSW_ShowTrainingPointsMenu	(Visible)
	SetVisible(ATSWTrainingPointsFrame, Visible)
end

function ATSW_SelectRecipe(Name, Type)
	if Name then
		if Type == 'header' then
			ATSW_SwitchCategory(Name)
		else
			-- Store selected recipe name
			ATSW_SelectedRecipe[realm][player][Profession()] = Name
			ATSW_ShowRecipe(Name)
		end
	else
		ATSW_SelectedRecipe[realm][player][Profession()] = nil
		ATSW_HideRecipe()
	end
	
	ATSW_UpdateCreateButton()
end

function ATSW_SwitchCategory(Name)
	if ATSW_IsContracted(Name) then
		table.remove(Contracted(), ATSW_GetContractedPos(Name))
	else
		table.insert(Contracted(), Name)
	end
	
	ATSW_GetRecipesSorted(true)
end

function ATSW_ShowRecipe(Name)
	local GamePosition = GetPositionFromGame(Name)
	
	if not GamePosition then
		return
	end
	
	SelectCraftItem(GamePosition)
	
	ATSWRecipeName:Show()
	ATSWRecipeIcon:Show()
	
	local Recipe = Recipe(GetRecipePosition(Name))
	
	if not Recipe then
		ATSW_HideRecipe()
		
		return
	end
	
	-- Name
	ATSWRecipeName:SetText(Recipe.Name)
	
	-- Icon
	local Quality = LinkToQuality(Recipe.Link)
	
	SetVisible(ATSWRecipeIconQualityTexture, Quality > 2)
	
	if Recipe.Texture then
		ATSWRecipeIcon:SetNormalTexture(Recipe.Texture)
		ATSWRecipeIcon.Link = Recipe.Link
	else
		ATSWRecipeIcon:Hide()
	end
	
	-- Quality border
	if Quality > 2 then
		local RColor = QualityColor[Quality]
		
		ATSWRecipeIconQualityTexture:SetVertexColor(RColor.R, RColor.G, RColor.B)
	else
		ATSWRecipeIconQualityTexture:SetVertexColor(1, 1, 1)
	end
	
	-- Amount of production
	local Min	= Recipe.ProductMin
	local Max	= Recipe.ProductMax
	
	if Max > 1 then
		if Min == Max then
			ATSWRecipeIconAmount:SetText(Min)
		else
			ATSWRecipeIconAmount:SetText(Min .. '-' .. Max)
		end
	else
		ATSWRecipeIconAmount:SetText('')
	end
	
	-- Cooldown
	local Cooldown = ConvertCooldown(Recipe.Cooldown, true)
	
	SetVisible(ATSWRecipeCooldown, Cooldown)
	ATSWRecipeCooldown.Cooldown = Recipe.Cooldown
	ATSWRecipeCooldown:SetText((Cooldown and COOLDOWN_REMAINING .. ' ' .. Cooldown) or '')
	
	local function ToolStringToTable(...)
		local Table = {}
		
		for I = 1, arg.n, 2 do
			table.insert(Table, {	Name 		= arg[I],
											Available	= arg[I+1]	})
		end
		
		return Table
	end
	
	local Tools, Required
	local BeastTraining = IsBeastTraining()
	
	if BeastTraining then
		-- Requirements
		local Button 					= _G['ATSWTool' .. 1]
		local ButtonText 			= _G['ATSWTool' .. 1 .. 'Text']
		local ButtonTexture 		= _G['ATSWTool' .. 1 .. 'Texture']
		local ReqLevel				= Recipe.RequiredLevel
		
		Required 						= BuildColoredListString(GetCraftRequirements(GamePosition))
		
		SetVisible(ATSWToolsLabel, 	Required or ReqLevel and ReqLevel > 0)
		SetVisible(Button, 				Required or ReqLevel and ReqLevel > 0)
		ATSWToolsLabel:SetText(REQUIRES_LABEL .. ' ')
		
		if Required then
			Button:						SetText(Required)
		else
			if ReqLevel and ReqLevel > 0 then
				if UnitLevel('pet') >= ReqLevel then
					Button:SetText(format(RemoveEscapeCharacters(TRAINER_PET_LEVEL), ReqLevel))
				else
					Button:SetText(format(TRAINER_PET_LEVEL_RED, ReqLevel))
				end
			else
				Button:SetText('')
			end
		end
		
		ButtonTexture:				SetWidth(Texture and 16 or -1)
		Button:							SetWidth(Button:GetTextWidth() + ButtonTexture:GetWidth())
		ButtonText:					SetTextColor(0, 0, 0)
		SetEnabled(Button, false)
	else
		-- Tools
		Tools = ToolStringToTable(GetCraftRequirements(GamePosition))
		
		SetVisible(ATSWToolsLabel, table.getn(Tools) > 0)
		ATSWToolsLabel:SetText(ATSW_TOOLS)
		
		for I = 1, ATSW_TOOLS_DISPLAYED do
			local Button 				= _G['ATSWTool' .. I]
			local ButtonText 		= _G['ATSWTool' .. I .. 'Text']
			local ButtonTexture 	= _G['ATSWTool' .. I .. 'Texture']
			local Exist 					= table.getn(Tools) >= I
			local R 						= 0
			local Texture, Name, Available
			local Position, Link
			
			SetVisible(Button, Exist)
			
			if Exist then
				Name					= Tools[I].Name
				Available				= Tools[I].Available
				
				local ID 				= ToolID[Name]
				
				if ID then
					Texture = GetItemTexture(ID)
				end
				
				R 							= (Available or not Texture) and 0 or 1
				Position 				= GetRecipePosition(Name)
				Link						= Position and GetCraftLink(Position)
				
				SetEnabled(Button, Position)
				ButtonTexture:		SetWidth(Texture and 16 or -1)
				ButtonTexture:		SetTexture(Texture)
				Button:					SetText(Name .. (I < table.getn(Tools) and ',' or ''))
				ButtonText:			SetTextColor(R, 0, 0)
				Button:					SetWidth(Button:GetTextWidth() + ButtonTexture:GetWidth())
			end
			
			Button.R					= R
			Button.Name				= Name
			Button.Link				= Link
			Button.Position 			= Position
		end
	end
	
	SetVisible(ATSWCostText, 			BeastTraining)
	SetVisible(ATSWCraftDescription, 	BeastTraining)
	
	if BeastTraining then
		-- Training cost
		if Recipe.TrainingCost > 0 then
			-- 标红规则与原版界面一致：剩余点数低于全价时标红仅作提示，
			-- 实际扣费是差价（已学低级技能时），标红不代表学不起
			local Total, Spent = GetPetTrainingPoints()
			local Usable = math.max(Total - Spent, 0)

			if Usable >= Recipe.TrainingCost then
				ATSWCostText:SetText(Recipe.TrainingCost .. ' ' .. TRAINING_POINTS_LABEL)
			else
				ATSWCostText:SetText(RED_FONT_COLOR_CODE .. Recipe.TrainingCost .. FONT_COLOR_CODE_CLOSE .. ' ' .. TRAINING_POINTS_LABEL)
			end
		end
		
		SetVisible(ATSWReagentsLabel, 	Recipe.TrainingCost > 0)
		SetVisible(ATSWCostText, 			Recipe.TrainingCost > 0)
		ATSWReagentsLabel:SetText(COSTS_LABEL .. ' ')
		
		-- Description
		local Description = GetCraftDescription(GamePosition)
		
		SetVisible(ATSWCraftDescription, Description)
		
		if Description then
			ATSWCraftDescription:SetText(Description)
		end
	else
		-- Reagents
		local NumReagents 		= Recipe.ReagentsSize
		
		SetVisible(ATSWReagentsLabel, NumReagents > 0)
		ATSWReagentsLabel:SetText(SPELL_REAGENTS)
		
		for I = 1, MAX_TRADE_SKILL_REAGENTS do
			local Button 				= _G['ATSWReagent' .. I]
			local ButtonQuality 	= _G['ATSWReagent' .. I .. 'QualityTexture']
			local Exists 				= I <= NumReagents
			local RName, RTexture, RAmount, RPlayerAmount, RLink, RTotalAmount, Quality, RColor, R, G, B, A, Craftable, Position
			
			SetVisible(Button, false) -- It is needed for tooltip update if schematic is changed
			SetVisible(Button, Exists)

			if Exists then
				local ButtonTexture 	= _G['ATSWReagent' .. I .. 'Texture']
				local ButtonAmount 	= _G['ATSWReagent' .. I .. 'Amount']
				local ButtonTitle 		= _G['ATSWReagent' .. I .. 'Title']
				local Pos 					= Recipe.Position
				
				RName, RTexture, RAmount, RPlayerAmount, RLink = GetReagentData(GamePosition, I)
				
				if not (RName and RTexture and RLink) then
					ReagentsDataIsComplete = false
				end
				
				if RLink then
					Quality 				= LinkToQuality(RLink)
					
					if Quality > 2 then
						RColor			= QualityColor[Quality]
						R, G, B			= RColor.R, RColor.G, RColor.B
					else
						R, G, B 			= 1, 1, 1
					end
					
					SetVisible(ButtonQuality, Quality > 2)
					
					if RPlayerAmount and RAmount then
						A 						= 0.5 + (RPlayerAmount >= RAmount and 0.45 or 0)
						RTotalAmount 	= RPlayerAmount .. ' /' .. RAmount
					else
						A 						= 0.5
						RTotalAmount 	= ''
					end
					
					-- ButtonTitle:SetTextColor(R, G, B, A) -- Colored title
					ButtonTitle:SetTextColor(0, 0, 0, 1) -- Black title
				end
				
				Position 				= GetRecipePosition(RName)
				
				ButtonTexture:		SetTexture		(RTexture)
				ButtonTexture:		SetVertexColor	(A, A, A, A)
				ButtonAmount:		SetText				(RTotalAmount)
				ButtonTitle:			SetText				(RName or '')
				ButtonQuality:		SetVertexColor	(R, G, B, 0.5)
			end
			
			Button.Name 				= RName
			Button.Link				= RLink
			Button.R 					= R 
			Button.G 					= G
			Button.B 					= B
			Button.Position 			= Position
			Button.RecipeIndex 	= Recipe.Position
			Button.ReagentIndex 	= I
		end
	end
	
	
-- 制作成本 (aux 今日最低一口价 daily_min_buyout)
	do
		local AHCost, AHAvailable = 0, false

		for I = 1, Recipe.ReagentsSize do
			local RL	= Recipe.Reagents[I].Link
			local RA	= Recipe.Reagents[I].Amount or 0

			if RL and RA > 0 then
				local UnitPrice = ATSW_GetAHUnitPrice(RL)

				if UnitPrice then
					AHCost			= AHCost + UnitPrice * RA
					AHAvailable	= true
				end
			end
		end

		if AHAvailable then
			ATSWCostAHText:SetText('制作成本 (今日价): ' .. ATSW_FormatCost(AHCost))
		else
			ATSWCostAHText:SetText('制作成本 (今日价): 无数据')
		end

		SetVisible(ATSWCostAHText, Recipe.ReagentsSize > 0)
	end

ATSW_SetHighlight(Name)
	
	-- Remove previous recipe if it is selected
	
	for I, V in pairs(PreviousRecipes()) do
		if V == Recipe.Name then
			table.remove(PreviousRecipes(), I)
			
			break
		end
	end
	
	-- Previous recipes button
	SetVisible(ATSWPreviousItemButton, PreviousRecipesSize() > 0)
	
	-- Task button
	ATSWTaskButton:Enable()
	
	-- Amount control
	ATSWIncrementButton:Enable()
	ATSWDecrementButton:Enable()
end

function ATSW_HideRecipe()
	local Visible = false
	
	ATSW_SetHighlight(nil)
	
	SetVisible(ATSWRecipeName, 		Visible)
	SetVisible(ATSWRecipeIcon, 		Visible)
	SetVisible(ATSWRecipeCooldown,	Visible)
	SetVisible(ATSWToolsLabel, 			Visible)
	SetVisible(ATSWReagentsLabel,	Visible)
	SetVisible(ATSWCostAHText, 			Visible)
	SetVisible(ATSWCraftDescription,	Visible)
	
	for I = 1, ATSW_RECIPES_DISPLAYED do
		_G['ATSWRecipe' .. I]:UnlockHighlight()
	end
	
	for I = 1, ATSW_TOOLS_DISPLAYED do
		SetVisible(_G['ATSWTool' .. I], 		Visible)
	end
	
	for I = 1, MAX_TRADE_SKILL_REAGENTS do
		SetVisible(_G['ATSWReagent' .. I], 	Visible)
	end
	
	-- Task button
	ATSWTaskButton:Disable()
	
	-- Amount control
	ATSWIncrementButton:Disable()
	ATSWDecrementButton:Disable()
end

function ATSW_SetHighlight(Name)
	if HighlightButton then
		HighlightButton:UnlockHighlight()
		HighlightButton = nil
	end
	
	if Name then
		for I = 1, ATSW_RECIPES_DISPLAYED do
			local Button = _G['ATSWRecipe' .. I]
			
			if Button.Name == Name then
				local R, G, B = Button:GetTextColor()
				
				ATSWHighlight:SetPoint('TOP', Button)
				ATSWHighlightTexture:SetVertexColor(R, G, B, 0.8)
				
				HighlightButton = Button
			end
		end
	end
	
	if HighlightButton then
		HighlightButton:LockHighlight()
	end
	
	SetVisible(ATSWHighlight, HighlightButton)
end

function ATSW_UpdateCreateButton()
	local Amount = ATSWAmountBox:GetNumber()
	local TaskPossible, Possible = 0
	local IncludeTasks = true
	
	local Position 	= GetPositionFromGame(RecipeSelected())
	
	if RecipesSize() > 0 then
		Possible = not Processing.Active
		
		if not Processing.Active then
			local Type
			
			if Position then
				_, _, Type		= GetCraftNameType(Position)
			end
			
			if IsBeastTraining() then
				if UnitName('pet') and Position then
					local _, _, _, _, _, _, ReqLevel = GetCraftInformation(Position)

					-- 原版界面的启用条件是"只要不是已学（'used'）就能点"，点数够不够由服务端在
					-- DoCraft 时判定：craftType 与 TrainingCost 都按从 0 学起的全价计算，
					-- 已学低级技能时实际只扣差价（如持久耐力8级后学9级），任何基于全价的预判
					-- 都会把这种情况误判为不可学。这里只额外保留宠物等级门槛（不够级学了也失败）
					Possible = Type ~= 'used'

					if ReqLevel and ReqLevel > 0 then
						if UnitLevel('pet') < ReqLevel then
							Possible = false
						end
					end
				else
					Possible = false
				end
			else
				if not Amount or Amount == 0 then
					Amount = 1
				end
				
				Possible = (Position and not GetCraftCooldown(Position)) and (Type ~= 'used') and ATSW_HowManyItemsArePossibleToCreate(RecipeSelected()) >= Amount
				
				for I = 1, TasksSize() do
					Pos = GetPositionFromGame(Task(I).Name)
					
					if Pos and not GetCraftCooldown(Pos) then
						if ATSW_HowManyItemsArePossibleToCreate(Task(I).Name, ATSW_POSSIBLE_NOTASK) > 0 then
							Possible = not (Processing.Active and Processing.Recipe == Task(I).Name)
							
							break
						end
					end
				end
			end
		end
	end
	
	if not Processing.Active then
		SetEnabled(ATSWCreateButton, Possible)
	end
	
	local Name = _G[GetCraftButtonToken()]
	local Text
	
	if Name == 'Enchant' then
		if Position and IsEnchant(Position) then
			Text = ATSW_ENCHANT
		else
			Text = CREATE
		end
	elseif Name == 'Create' or Name == 'Use' then
		Text = CREATE
	else
		Text = Name
	end
	
	ATSWCreateButton:SetText(Text or Name or '')
	ATSWCreateButton:SetWidth(math.max(ATSWCreateButton:GetTextWidth() + 25, 82))
end

function ATSW_Craft(Name, Amount)
	local Possible
	local Index = GetPositionFromGame(Name)
	
	if TradeSkill then
		Possible 				= ATSW_HowManyItemsArePossibleToCreate(Name, ATSW_POSSIBLE_NOTASK)
	else
		Possible 				= 1
	end
	
	Processing.Profession	= Profession()
	Processing.Recipe 		= Name
	Processing.Texture		= GetCraftTexture(Index)
	Processing.Amount 		= math.min(Amount, Possible)
	Processing.Delay			= GetTime()
	
	--Compatibility with otravi Cast Bar
	oCBIcon = Processing.Texture
	oCBName = Name
	
	ATSWFrame:RegisterEvent('SPELLCAST_START')
	
	ATSW_PushCreateButton()
	Delay(function ()
				ATSW_PushCreateButton(Processing.Active)
			end, GetLatency()*4)
	
	Craft(Index, Amount)
end

local function GetReagents(Name, Amount, Link, Texture, Table)
	local Table = Table or {}
	local Amount = Amount or 1
	
	local Pos = GetPositionFromGame(Name)
	
	if not Pos then
		for I = 1, table.getn(Table) do
			if Table[I].Name == Name then
				Table[I].Amount = Table[I].Amount + Amount
				
				return Table
			end
		end
		
		table.insert(Table,	{	Name 	= Name,
										Amount = Amount,
										Link 		= Link,
										Texture	= Texture	})
		
		return Table
	end
	
	for I = 1, GetReagentCount(Pos) do
		local RName, RTexture, RAmount, _, RLink = GetReagentData(Pos, I)
		local Min = GetCraftMinMax(GetPositionFromGame(Name))
		local Amount = math.ceil(Amount / Min)
		
		Table = GetReagents(RName, (RAmount * Amount), RLink, RTexture, Table)
	end
	
	return Table
end

local function GetSayTooltipString()
	if ChatFrameEditBox:IsVisible() or WIM_EditBoxInFocus then
		local ChatType, ChatNumber
		local SayTarget = ''
		
		if WIM_EditBoxInFocus ~= nil then
			ChatType 		= 'WHISPER'
			ChatNumber 	= WIM_EditBoxInFocus:GetParent().theUser
			
			SayTarget 		= ATSW_TOOLTIP_TO .. WIM_UserWithClassColor(ChatNumber)
		else
			ChatType, ChatNumber = ChatFrameEditBox.chatType

			if ChatType == 'WHISPER' then
					ChatNumber = ChatFrameEditBox.tellTarget
			elseif ChatType == 'CHANNEL' then
					ChatNumber = ChatFrameEditBox.channelTarget
					
					local ChatID, ChatName = GetChannelName(ChatNumber)
				
					SayTarget = ATSW_TOOLTIP_TO .. '[' .. ChatID .. '. ' .. ChatName ..']'
			elseif ChatType == 'YELL' then
					SayTarget = ATSW_TOOLTIP_TO .. ATSW_TOOLTIP_YELL
			elseif ChatType == 'PARTY' then
					SayTarget = ATSW_TOOLTIP_TO .. ATSW_TOOLTIP_PARTY
			elseif ChatType == 'GUILD' then
					SayTarget = ATSW_TOOLTIP_TO .. ATSW_TOOLTIP_GUILD
			elseif ChatType == 'RAID' then
					SayTarget = ATSW_TOOLTIP_TO .. ATSW_TOOLTIP_RAID
			end
		end

		return ATSW_TOOLTIP_SAYREAGENTS .. SayTarget, ChatType, ChatNumber
	else
		return ''
	end
end

local Lines = {}
local Message = ''
local TooltipString, ChatType, ChatNumber

StaticPopupDialogs['SAYREAGENTS'] = {
	text = '',
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function()
		SendChatMessage(Message, ChatType, nil, ChatNumber)
		
		for L = 1, table.getn(Lines) do
			SendChatMessage(Lines[L], ChatType, nil, ChatNumber)
		end
	end,
	timeout = 0,
	preferredIndex = 2,
	showAlert = 1,
	hideOnEscape = 1
}

function ATSW_SayReagents(Position)
    TooltipString, ChatType, ChatNumber = GetSayTooltipString()
	
    local LineStart
	local R = Recipe(Position)
	
	if R.Link then
		if IsEnchant(Position) then
			LineStart = ''
		else
			LineStart = ATSW_REAGENTLIST1 .. ' '
		end
		
		local Reagents = GetReagents(R.Name)
		
		if ATSW_Options.NoConfirmMats and ChatType then
			-- Send the list straight to the current chat, with clickable item links
			SendChatMessage(LineStart .. R.Link .. ' ' .. ATSW_REAGENTLIST2, ChatType, nil, ChatNumber)
			
			for L = 1, table.getn(Reagents) do
				local Line = Reagents[L].Link or Reagents[L].Name
				
				if Reagents[L].Amount > 1 then
					Line = Line .. ' (' .. Reagents[L].Amount .. ')'
				end
				
				SendChatMessage(Line, ChatType, nil, ChatNumber)
			end
		else
			local S = string.format(TooltipString, '^.*|cffffffff?(%s*)') .. '|r?\n\n' .. LineStart .. R.Link .. ' ' .. ATSW_REAGENTLIST2
			
			Lines = {}
			
			for L = 1, table.getn(Reagents) do
				local Line = Reagents[L].Link or Reagents[L].Name
				
				if Reagents[L].Amount > 1 then
					Line = Line .. ' (' .. Reagents[L].Amount .. ')'
				end
				
				S = S .. '\n' .. Line
				
				table.insert(Lines, Line)
			end
			
			StaticPopupDialogs['SAYREAGENTS'].text = S .. '\n'
			Message = LineStart .. R.Link .. ' ' .. ATSW_REAGENTLIST2
			
			StaticPopup_Show('SAYREAGENTS')
		end
	end
end

function ATSW_HowManyItemsArePossibleToCreateWithConsidering(Name)
	return ATSW_HowManyItemsArePossibleToCreate(
				Name,
				ATSW_Options.ConsiderBank 			and ATSW_POSSIBLE_BANK,
				ATSW_Options.ConsiderAlts 			and ATSW_POSSIBLE_ALTS,
				ATSW_Options.ConsiderMerchants 	and ATSW_POSSIBLE_MERCHANT,
				ATSW_POSSIBLE_NOTASK	)
end

function ATSW_CalcPossible(Name, ...)
	-- A visited table passed as the last argument guards against circular
	-- recipe dependencies (would otherwise recurse until stack overflow)
	local Visited 	= {}
	local ArgCount 	= arg.n
	
	if type(arg[ArgCount]) == 'table' then
		Visited 	= arg[ArgCount]
		ArgCount 	= ArgCount - 1
	end
	
	if Visited[Name] then
		return 0
	end
	
	Visited[Name] = true
	
	local Pos 					= GetRecipePosition(Name)
	
	if Pos then
		local I = 0
		local Possible, PossibleAmountTotal
		local MaxReagents 		= GetReagentCount(Pos)
		
		if MaxReagents > 0 then
			local function Param(P)
				for I = 1, ArgCount do
					if arg[I] == P then
						return I
					end
				end
				
				return false
			end
			
			local function SetMinPossible(Amount)
				Amount 				= math.floor(Amount)
				
				if not PossibleAmountTotal or Amount < PossibleAmountTotal then
					PossibleAmountTotal = Amount
				end
				
				if PossibleAmountTotal < 0 then
					PossibleAmountTotal = 0
				end
			end
			
			repeat
				I = I + 1
				
				local RName, _, RAmount, RPlayerAmount = GetReagentData(Pos, I)
				local TotalAmount 	= RPlayerAmount
				
				if Param(ATSW_POSSIBLE_BANK) then
					TotalAmount 		= TotalAmount + ATSW_GetBankAmount(RName)
				end
				
				if Param(ATSW_POSSIBLE_ALTS) then
					TotalAmount 		= TotalAmount + ATSW_GetAltsAmount(RName)
				end
				
				if Param(ATSW_POSSIBLE_MERCHANT) then
					if ATSW_IsInMerchant(RName) and TotalAmount < RAmount then
						TotalAmount 	= math.max(PossibleAmountTotal and PossibleAmountTotal * RAmount or 0, RAmount)
					end
				end
				
				-- Add how many of an intermediate reagent can be crafted from its own reagents
				if GetRecipePosition(RName) then
					local BranchVisited = {}
					local SubArgs 		= {}
					
					for K, V in pairs(Visited) do
						BranchVisited[K] = V
					end
					
					-- Lua 5.0 unpack() has no range arguments: forward the flags in a fresh table
					if Param(ATSW_POSSIBLE_BANK) then
						table.insert(SubArgs, ATSW_POSSIBLE_BANK)
					end
					
					if Param(ATSW_POSSIBLE_ALTS) then
						table.insert(SubArgs, ATSW_POSSIBLE_ALTS)
					end
					
					if Param(ATSW_POSSIBLE_MERCHANT) then
						table.insert(SubArgs, ATSW_POSSIBLE_MERCHANT)
					end
					
					table.insert(SubArgs, ATSW_POSSIBLE_NOTASK)
					table.insert(SubArgs, BranchVisited)
					
					TotalAmount = TotalAmount + ATSW_HowManyItemsArePossibleToCreate(RName, unpack(SubArgs))
				end
				
				SetMinPossible(TotalAmount / RAmount)
				
				Possible = PossibleAmountTotal > 0
			until I == MaxReagents or not Possible
			
			if Possible and not Param(ATSW_POSSIBLE_NOTASK) then
				local TaskExist = DoTaskExist(Name)
				
				if TaskExist then
					SetMinPossible(PossibleAmountTotal - Task(TaskExist).Amount)
				end
			end
			
			return PossibleAmountTotal
		end
	end
	
	return 0
end

function ATSW_HowManyItemsArePossibleToCreate(Name, ...)
	local ArgCount = arg.n
	
	if type(arg[ArgCount]) == 'table' then
		return ATSW_CalcPossible(Name, unpack(arg))
	end
	
	-- 参数组合压成一个数字当缓存槽：数字键不产生字符串垃圾
	local Bits = 0
	
	for I = 1, ArgCount do
		local A = arg[I]
		
		if 			A == ATSW_POSSIBLE_BANK 			then Bits = Bits + 1
		elseif 	A == ATSW_POSSIBLE_ALTS 			then Bits = Bits + 2
		elseif 	A == ATSW_POSSIBLE_MERCHANT 	then Bits = Bits + 4
		elseif 	A == ATSW_POSSIBLE_NOTASK 		then Bits = Bits + 8 end
	end
	
	local CacheKey = tostring(Profession() or "") .. "\001" .. tostring(Name)
	local Slot = ATSW_PossibleCache[CacheKey]
	
	if not Slot then
		Slot 											= { Value = {}, Gen = {}, Time = {} }
		ATSW_PossibleCache[CacheKey] 	= Slot
	end
	
	local Now = GetTime()
	
	if Slot.Gen[Bits] == ATSW_PossibleGeneration and (Now - (Slot.Time[Bits] or 0)) < ATSW_PossibleTTL then
		return Slot.Value[Bits]
	end
	
	local Value 			= ATSW_CalcPossible(Name, unpack(arg))
	Slot.Value[Bits] 	= Value
	Slot.Gen[Bits] 		= ATSW_PossibleGeneration
	Slot.Time[Bits] 	= Now
	
	return Value
end

function ATSW_SetNecessary(Name, Amount, Link, Texture, NecessaryReagentMode)
	if  Name and Amount and Amount > 0 then
		local NPos
		
		for I = 1, NecessaryReagentsSize() do
			if NecessaryReagent(I).Name == Name then
				NPos = I
			end
		end
		
		if NPos then
			if NecessaryReagentMode == ATSW_NECESSARY_REAGENT_DELETE then
				if NecessaryReagent(NPos).Amount > Amount then
					NecessaryReagent(NPos).Amount = NecessaryReagent(NPos).Amount - Amount
				else
					table.remove(NecessaryReagents(), NPos)
				end
			elseif (NecessaryReagentMode == ATSW_NECESSARY_REAGENT_ADD) or not NecessaryReagentMode then
				NecessaryReagent(NPos).Amount = NecessaryReagent(NPos).Amount + Amount
			end
		elseif (NecessaryReagentMode == ATSW_NECESSARY_REAGENT_ADD) or not NecessaryReagentMode then
			table.insert(NecessaryReagents(),	{	Name 	= Name,
																	Texture = Texture,
																	Amount = Amount,
																	Link 		= Link		})
		end
		
		if ATSWReagentsFrame:IsVisible() then
			ATSW_UpdateNecessaryReagents()
		end
		
		if MerchantFrame:IsVisible() then
			ATSW_SetBuyFrameVisible()
		end
		
		if NecessaryReagentsSize() > 0 then
			if ATSWShoppingListFrame:IsVisible() then
				ATSW_UpdateAuctionList()
			else
				ATSW_ShowAuctionShoppingList()
			end
		else
			ATSWShoppingListFrame:Hide()
		end
	end
end

-- Task functions

local function AmountInTasksIndirect(Name, Prof)
	local Amount = 0
	
	for I = 1, TasksSize(Prof) do
		local Pos = GetRecipePosition(Task(I, Prof).Name, Prof)
		local TaskAmount = Task(I, Prof).Amount
		
		for J = 1, Recipe(Pos, Prof).ReagentsSize do
			local R = Recipe(Pos, Prof).Reagents[J]
			
			if R.Name == Name then
				Amount = Amount + R.Amount * TaskAmount
				
				break
			end
		end
	end
	
	return Amount
end

local function AmountInTasksDirect(Name, Prof)
	local Pos = DoTaskExist(Name, Prof)
	
	if Pos then 
		return Task(Pos, Prof).Amount
	else
		return 0
	end
end

local function AmountInTasks(Name, Prof)
	return AmountInTasksIndirect(Name, Prof) - AmountInTasksDirect(Name, Prof)
end

function ATSW_AddTask(Name, Amount, Link, Texture, Recursive, NecessaryReagentMode, Insert, Prof)
	ATSW_PossibleInvalidate() -- 任务变了（2026.10.28）
	if IsEnchanting() then
		return
	end
	
	if Name then
		if Prof == nil then
			Prof = Profession()
		end
		
		local Pos = GetRecipePosition(Name, Prof)
		
		local function Possession(Name)
			local Bags, Bank, OtherCharacters
			
			Bags 					= ATSW_GetBagsAmount(Name)
			Bank 				= ATSW_Options.ConsiderBank 	and ATSW_GetBankAmount(Name) 	or 0
			OtherCharacters	= ATSW_Options.ConsiderAlts	 	and ATSW_GetAltsAmount(Name) 	or 0
			
			return Bags + Bank + OtherCharacters
		end
		
		if Pos then
			if Amount and Amount > 0 then
				if not NecessaryReagentMode then
					local TPos = DoTaskExist(Name)
						
					if TPos then
						Task(TPos).Amount = Task(TPos).Amount + Amount
					else
						local InsertPos = Insert and DoTaskExist(Insert) or TasksSize() + 1
						
						table.insert(Tasks(), InsertPos, {	Name 	= Name,
																		Amount = Amount,
																		Texture = GetCraftTexture(Pos)	})
					end
				end
				
				for I = 1, Recipe(Pos, Prof).ReagentsSize do
					local R = Recipe(Pos, Prof).Reagents[I]
					local Merchant, Required, InsertBefore = 1, 0
					
					Merchant = ATSW_Options.ConsiderMerchants and ATSW_Merchant[R.Name] and 0 or 1
					
					if GetRecipePosition(R.Name, Prof) then
						local Min = GetCraftMinMax(GetRecipePosition(R.Name, Prof))
						
						Required = math.ceil(((AmountInTasksIndirect(R.Name, Prof) - (AmountInTasksDirect(R.Name, Prof) * Min) - math.ceil(Possession(R.Name) / Min))) / Min) * Merchant
						
						if AmountInTasksDirect(Name, Prof) > 0 and AmountInTasksDirect(R.Name, Prof) == 0 then
							InsertBefore = Name
						end
					else
						Required = R.Amount * Amount
					end
					
					if Required < 0 then
						NecessaryReagentMode = ATSW_NECESSARY_REAGENT_ADD
						Required = Amount
					end
					
					ATSW_AddTask(R.Name, Required, R.Link, R.Texture, true, NecessaryReagentMode, InsertBefore or Insert , Prof)
				end
				
				if not Recursive then
					ATSW_UpdateRecipes()
					ATSW_UpdateTasks()
				end
			end
		else
			ATSW_SetNecessary(Name, Amount, Link, Texture, NecessaryReagentMode)
		end
	end
end

function ATSW_DeleteTask(Name, Amount, Prof)
	ATSW_PossibleInvalidate() -- 任务变了（2026.10.28）
	for I = 1, TasksSize(Prof) do
		T = Task(I, Prof)
		
		if T.Name == Name then
			-- Get removing amount
			local Removed = Amount or T.Amount
			
			-- Remove task
			if not Amount or T.Amount <= Amount then
				table.remove(Tasks(Prof), I)
			else
				T.Amount = T.Amount - Amount
			end
			
			-- Remove necessary item
			ATSW_AddTask(Name, Removed, nil, nil, nil, ATSW_NECESSARY_REAGENT_DELETE, nil, Prof)
			
			if NoTasks() then
				ResetNecessaries()
			end
			
			-- Update lists
			if not (Prof and Prof ~= Profession()) then
				ATSW_UpdateRecipes()
				ATSW_UpdateTasks()
			end
			
			break
		end
	end
end

-- Progress bar functions

function ATSW_InitializeProgressBar(StartTime, EndTime)
	ATSWProgressBar:SetMinMaxValues(StartTime, EndTime)
	ATSWProgressBar:		SetAlpha(1)
	ATSWProgressBarGlow:SetAlpha(0)
	
	ATSWProgressBar.StartTime = StartTime
	ATSWProgressBar.EndTime 	= EndTime
	ATSWProgressBar.Mode		= ATSW_CAST
	ATSWProgressBar.Working 	= true
end

ATSW_Time = 0

function ATSW_StartProcessing()
	ATSWFrame:RegisterEvent('SPELLCAST_INTERRUPTED')
	
	Processing.Complete			= 0
	Processing.Stop					= false
	Processing.Active				= true
	
	ATSW_UpdateTasks()
end

function ATSW_PushCreateButton(State)
	if State or (State == nil) then
		ATSWCreateButton:SetButtonState('PUSHED', true)
		ATSWCreateButton:SetHighlightTexture('')
		ATSWCreateButton:SetTextColor(0.5, 0.5, 0.5)
		ATSWCreateButton:SetHighlightTextColor(0.5, 0.5, 0.5)
	elseif State == false then
		ATSWCreateButton:SetButtonState('NORMAL', false)
		ATSWCreateButton:SetHighlightTexture('Interface\\Buttons\\UI-Panel-Button-Highlight')
		ATSWCreateButton:SetTextColor(1, 0.82, 0)
		ATSWCreateButton:SetHighlightTextColor(1, 0.82, 0)
	end
end

function ATSW_StopProcessing()
	ATSWFrame:UnregisterEvent('SPELLCAST_START')
	ATSWFrame:UnregisterEvent('SPELLCAST_INTERRUPTED')
	
	Processing.Active				= false
	Processing.Stop					= false
	ATSWProgressBar.Working 	= false
	ATSWProgressBar.TaskItem 	= nil
	ATSWProgressBar:Hide()
	
	ATSW_PushCreateButton(false)
	ATSW_UpdateTasks()
end

function ATSW_CompleteTask()
	ATSW_DeleteTask(Processing.Recipe, 1, Processing.Profession)
	Processing.Amount 			= Processing.Amount - 1
	Processing.Complete 		= Processing.Complete + 1
	
	if (Processing.Profession == Profession()) and ATSWFrame:IsVisible() then
		local Cooldown 			= GetCraftCooldown(GetPositionFromGame(Processing.Recipe))
		
		if Cooldown then
			ATSW_UpdateFrame()
		end
	end
	
	if Processing.Amount == 0 or Processing.Stop then
		ATSW_StopProcessing()
	end
end

-- Auction/Necessaries functions

function ATSW_ShowAuctionShoppingList()
    if (AuctionFrame and AuctionFrame:IsVisible() or aux_frame and aux_frame:IsVisible()) and 
	NecessaryReagentsSize() > 0 and 
	ATSW_Options.DisplayShoppingList then
		for A = 1, ATSW_AUCTION_ITEMS_DISPLAYED do -- Create auction shopping frame buttons
			if not _G['ATSWSLFReagent' .. A] then
				local F = CreateFrame('Frame', 'ATSWSLFReagent' .. A, ATSWShoppingListFrame, 'ATSWSLFReagentTemplate')
				
				if A == 1 then
					F:SetPoint('TOPLEFT', 10, -44)
				else
					F:SetPoint('TOPLEFT', 'ATSWSLFReagent' .. A - 1, 'BOTTOMLEFT')
				end
			end
		end
		
		-- Attach (Compatible with aux)
        if not aux_frame and AuctionFrame then
            ATSWShoppingListFrame:SetPoint('TOPLEFT', 'AuctionFrame', 'TOPLEFT', 348, -435.5)
        else
            ATSWShoppingListFrame:ClearAllPoints()
            ATSWShoppingListFrame:SetPoint('TOPRIGHT', 'aux_frame', 'BOTTOMRIGHT', 30, 0)
        end
		
        ATSWShoppingListFrame:Show()
		
		ATSW_UpdateAuctionList() -- Update
    end
end

function ATSWAuction_SearchForRecipe()
    InsertIntoAuction(this:GetParent().Link)
end

local function UpdateReagentList(ButtonName, ButtonsMax, Offset)
	for I = 1, ButtonsMax do
		local Button				= _G[ButtonName .. I					]
        local Item 					= _G[ButtonName .. I .. 'Item'		]
        local Bags 					= _G[ButtonName .. I .. 'Bags'		]
        local Bank 					= _G[ButtonName .. I .. 'Bank'		]
		local Alts 					= _G[ButtonName .. I .. 'Alt'			]
        local Merchant 			= _G[ButtonName .. I .. 'Merchant'	]
		
		local R 						= NecessaryReagent(I + Offset)
		
		SetVisible(Button, false) -- It is needed for tooltip update if button text is changed
		SetVisible(Button, R)
		
        if R and Button then
			local C				= LinkToColor(R.Link) or 'ffffff'
            local AmountBags 	= ATSW_GetBagsAmount	(R.Name)
            local AmountBank 	= ATSW_GetBankAmount	(R.Name)
            local AmountAlts 	= ATSW_GetAltsAmount		(R.Name)
            local IsInMerchant	= ATSW_IsInMerchant		(R.Name)
			
			Button.Link			= R.Link
			Button.Name 			= R.Name
			
			SetEnabled(Bags, 		false)
			SetEnabled(Bank, 		false)
			SetEnabled(Merchant,	false)
			
			if AmountBags 	==	0 	then AmountBags 	=	Color.GREY 	..	AmountBags 	.. 	'|r' end
			if AmountBank 	==	0 	then AmountBank 	=	Color.GREY 	.. 	AmountBank 	..	'|r' end
			if AmountAlts		==   0 	then AmountAlts 	=	Color.GREY 	..	AmountAlts 	.. 	'|r' end
			
			Item:	SetNormalTexture	(R.Texture)
            Item:	SetText					('|cff' .. C .. '[' .. R.Name .. ']|r ' .. Color.GREY .. '[' .. R.Amount .. ']|r')
            Bags:		SetText					(AmountBags)
			Bank:	SetText					(AmountBank)
			Alts:		SetText					(AmountAlts)
						SetVisible				(Merchant, IsInMerchant)
        end
    end
end

function ATSW_UpdateAuctionList()
	local ButtonsMax	= ATSW_AUCTION_ITEMS_DISPLAYED
    local Offset			= FauxScrollFrame_GetOffset(ATSWSLScrollFrame)
	
	UpdateReagentList	('ATSWSLFReagent', ButtonsMax, Offset)
	
    FauxScrollFrame_Update(ATSWSLScrollFrame, NecessaryReagentsSize(), ButtonsMax, ATSW_TRADESKILL_HEIGHT)
end

function ATSW_UpdateNecessaryReagents()
	if NoTasks() then
		ResetNecessaries()
	end
	
	if NecessaryReagentsSize() == 0 then
		ATSWReagentsFrame:Hide()
	else
		UpdateReagentList('ATSWRFReagent', ATSW_NECESSARIES_DISPLAYED, 0)
		SetVisible(ATSWReagentsFrameAndMore, 	NecessaryReagentsSize() > ATSW_NECESSARIES_DISPLAYED)
	end
end

-- Search functions

function ATSWSearchBox_OnTextChanged(Text)
	if not ATSW_BlockSearchTextChanged then
		SetSearchString(Text)
		
		if RecipesSize() > 0 then
			ATSW_GetRecipesSorted(true)
		end
	end
end

local function ReplaceMagicCharacters(String)
	local S = String
	-- Magic characters are ^$()%.[]*? and maybe + and -
	
	S = string.gsub(S, '%%', '%%%%')
	S = string.gsub(S, '%[', '%%[')
	S = string.gsub(S, '%^', '%%^')
	S = string.gsub(S, '%$', '%%$')
	S = string.gsub(S, '%(', '%%(')
	S = string.gsub(S, '%)', '%%)')
	S = string.gsub(S, '%.', '%%.')
	S = string.gsub(S, '%[', '%%[')
	S = string.gsub(S, '%]', '%%]')
	S = string.gsub(S, '%*', '%%*')
	S = string.gsub(S, '%?', '%%?')
	
	return S
end

local function RemoveSideSpaces(S)
	if S then
		_, _, S = string.find(S, '^%s*(.-)%s*$')
	end
	
	return S
end

local Parameters = {}

function ATSW_Filter(R, Type)
	local Name = R.Name
	
	if not Name then
		return false
	elseif Name == '' then
		return true
	end
	
	ParameterString = string.lower(ReplaceMagicCharacters(SearchString()))
	
	for I in pairs(Parameters) do
		Parameters[I] = nil
	end
	
	local _, _, Search = string.find(ParameterString, '^([^:]*)')
	
	if Search then
		Parameters['name'] = RemoveSideSpaces(Search)
	end
	
	for w in string.gfind(ParameterString, ':[^:]+') do
		local _, _, Param_Name, Param_Value = string.find(w, ':(%a+)%s([^:]+)')
		
		RemoveSideSpaces(Param_Value)
		
		if Param_Name then
			Parameters[Param_Name] = Param_Value
		end
	end
	
	for PName, PValue in pairs(Parameters) do
		if ATSW_ShowAttributes() then
			Name = GetAttributes(R)
		end
		
		if PName == 'name' then
			if not string.find(string.lower(Name), PValue) then
				return false
			end
		end
		
		if PName == 'reagent' or PName == 'r' then
			local Index = GetRecipePosition(Name)
			
			if Index then
				local Found = false
				
				for J = 1, Recipe(Index).ReagentsSize do
					if string.find(string.lower(GetReagentData(Index, J) or ''), PValue) then
						Found = true
					end
				end
				
				if not Found then
					return false
				end
			else
				return false
			end
		end
		
		if	PName == 'level'
		or	PName == 'rarity'
		or	PName == 'quality'
		or PName == 'q'
		or	PName == 'possible' 
		or	PName == 'possibletotal' then
			local PMin, PDirection, PMax
			
			if PName == 'rarity' or PName == 'quality' or PName == 'q' then
				_, _, PMin, PDirection, PMax = string.find(PValue, '^(%a+)%s*([%+%-]?)%s*(%a-)$')
				
				local QualityNames = {
					['grey'		] 			= 1,
					['white'		] 			= 2,
					['green'		] 			= 3,
					['blue'		] 			= 4,
					['purple'		]			= 5,
					['orange'	]	 		= 6,
					['gold'		] 			= 7,
					['cyan'		] 			= 8,

					['poor'		] 			= 1,
					['common'	] 			= 2,
					['uncommon'] 		= 3,
					['rare'		] 			= 4,
					['epic'		]			= 5,
					['legendary'] 			= 6,
					['artifact'	] 			= 7,
					['heirloom'	] 			= 8
				}
				
				PMin	=	QualityNames[PMin]
				PMax	=	QualityNames[PMax]
			else
				_, _, PMin, PDirection, PMax = string.find(PValue, '^(%d+)%s*([%+%-]?)%s*(%d-)$')
				
				PMin =	tonumber(PMin)
				PMax =	tonumber(PMax)
			end
			
			local Param
			
			if 			PName == 'level' 				then
						Param = GetItemMinLevel(Recipe(GetRecipePosition(Name)).Position) or 0
						
			elseif 	PName == 'rarity' or PName == 'quality' or PName == 'q' then
						Param = LinkToQuality(Recipe(GetRecipePosition(Name)).Link)
						
			elseif 	PName == 'possible' 			then
						Param = ATSW_HowManyItemsArePossibleToCreate(Name)
						
			elseif 	PName == 'possibletotal' 	then
						Param = ATSW_HowManyItemsArePossibleToCreateWithConsidering(Name)
			end
			
			if PMin and not PMax then
				if PDirection ~= '' then
					if PDirection == '+' then
						return Param >= PMin
					elseif PDirection == '-' then
						return Param <= PMin
					end
				else
					return Param == PMin
				end
			elseif PDirection == '-' then
				return Param > PMin and Param < PMax
			elseif PDirection == '+' then
				return Param == PMin + PMax
			end
		end
	end
	
	return true
end

-- Tooltip functions

function ATSWItemButton_OnEnter()
	local Link = this:GetParent().Link
	
	Link = string.gsub(Link, '|c(%x+)|H(item:%d+:%d+:%d+:%d+)|h%[(.-)%]|h|r', '%2')
	
    if Link then
        GameTooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT')
        GameTooltip:SetPoint('BOTTOMLEFT', this:GetName(), 'TOPLEFT')
        GameTooltip:SetHyperlink(Link)
        GameTooltip:Show()
    end
end

function ATSWItemButton_OnLeave()
    GameTooltip:Hide()
end

function CreateDynamicTooltip(TooltipName)
	local Name = TooltipName
    local Tooltip = CreateFrame('GameTooltip', Name, UIParent, 'GameTooltipTemplate')

    Tooltip:SetBackdrop({
        bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
        edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
	Tooltip:SetBackdropColor(0.09, 0.09, 0.18, 1)

    Tooltip.NumLines = 0
	Tooltip.MaxLineWidth = 0

    Tooltip:SetScale(GetCVar('uiscale'))
	Tooltip:SetFrameStrata('TOOLTIP')

    function ClearFrameObject(Object, IsTexture)
        if Object then
            Object:ClearAllPoints()

            if IsTexture then
                Object:SetTexture(nil)
            else
                Object:SetText('')
            end

            Object:Hide()
        end
    end

    function IncrementLineCount()
        Tooltip.NumLines = Tooltip.NumLines + 1

        return Tooltip.NumLines
    end

    function SetPointToPrevious(Object, LineIndex, PrevText)
		Object:ClearAllPoints()
		
        if LineIndex == 1 then
            Object:SetPoint('TOPLEFT', Tooltip, 'TOPLEFT', 10, -10)
        else
			Object:SetPoint('TOP', PrevText, 'BOTTOM', 0, -4)
			Object:SetPoint('LEFT', Tooltip, 'LEFT', 10, 0)
        end
    end

    function CreateTooltipLine(IconPath, LeftText, RightText, R, G, B)
        local LineIndex = IncrementLineCount()
		local Width = 0
		local IsHeader = LineIndex == 1

        if LineIndex == 1 then
            Tooltip:AddLine(' ')
        end

        local Texture = _G[Name .. 'TextureLeft' .. LineIndex]
        local LeftFontString = _G[Name .. 'TextLeft' .. LineIndex]
        local RightFontString = _G[Name .. 'TextRight' .. LineIndex]

        if IconPath then
            if not Texture then
                Texture = Tooltip:CreateTexture(Name .. 'TextureLeft' .. LineIndex)
				Texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            end

            if IsHeader then
                SetSize(Texture, 20, 20)
            else
                SetSize(Texture, 16, 16)
            end
			
            SetPointToPrevious(Texture, LineIndex, _G[Name .. 'TextLeft' .. (LineIndex - 1)])

            Texture:SetTexture(IconPath)
            Texture:Show()
        else
            if Texture then
                ClearFrameObject(Texture, true)
            end
        end

        if not LeftFontString then
            LeftFontString = Tooltip:CreateFontString(Name .. 'TextLeft' .. LineIndex, 'ARTWORK', IsHeader and 'GameTooltipHeaderText' or 'GameFontNormal')
        end
		
		if not (R and G and B) then
			R, G, B = 1, 0.82, 0
        end
		
		LeftFontString:SetTextColor(R, G, B)
		
        if IconPath then
			LeftFontString:ClearAllPoints()
            LeftFontString:SetPoint('LEFT', Texture, 'RIGHT', 2, 0)
        else
            SetPointToPrevious(LeftFontString, LineIndex, _G[Name .. 'TextLeft' .. (LineIndex - 1)])
        end

		if R and R > 1 then -- Set font
			LeftFontString:SetFont('Fonts\\FRIZQT__.ttf', R)
		elseif not IsHeader then
			LeftFontString:SetFont('Fonts\\FRIZQT__.ttf', 12)
		end
		
        LeftFontString:SetText(LeftText)
        LeftFontString:Show()
		
		if LeftText then
			Width = Width + string.len(LeftText) * 3.7
		end

        if RightText then
            if not RightFontString then
                RightFontString = Tooltip:CreateFontString(Name .. 'TextRight' .. LineIndex, 'ARTWORK', IsHeader and 'GameTooltipHeaderText' or 'GameTooltipText')
            end
			
			RightFontString:SetTextColor(1, 0.82, 0)
			RightFontString:ClearAllPoints()
            RightFontString:SetPoint('TOP', LeftFontString, 'TOP')
            RightFontString:SetPoint('RIGHT', Tooltip, 'RIGHT', -10, 0)
            RightFontString:SetText(RightText)
            RightFontString:Show()
			
			Width = Width + string.len(RightText) * 3.5
        else
            if RightFontString then
                ClearFrameObject(RightFontString, false)
            end
        end
		
		Tooltip.MaxLineWidth = math.max(math.max(Width, Tooltip.MaxLineWidth), 350)
    end

    function Tooltip:AddIconLine(IconPath, Text, R, G, B)
        CreateTooltipLine(IconPath, Text, nil, R, G, B)
    end

    function Tooltip:AddTextLine(Text, R, G, B)
        CreateTooltipLine(nil, Text, nil, R, G, B)
    end

    function Tooltip:AddDoubleLine(IconPath, LeftText, RightText, R, G, B)
        CreateTooltipLine(IconPath, LeftText, RightText, R, G, B)
    end

    function Tooltip:ClearLines()
        for I = Tooltip.NumLines, 1, -1 do
            ClearFrameObject(_G[Name .. 'TextureLeft' .. I], true)
            ClearFrameObject(_G[Name .. 'TextLeft' .. I], false)
            ClearFrameObject(_G[Name .. 'TextRight' .. I], false)
        end

        Tooltip.NumLines = 0
		Tooltip.MaxLineWidth = 0
    end

    return Tooltip
end

ATSWRecipeTooltip = CreateDynamicTooltip('ATSWRecipeTooltip')

local function CreateGameTooltip(TooltipName)
    local Tooltip = CreateFrame('GameTooltip', TooltipName, UIParent, 'GameTooltipTemplate')

    Tooltip:SetBackdrop(nil)
    Tooltip:SetScale(GetCVar('uiscale'))
    Tooltip:Hide()

    return Tooltip
end

ATSWRecipeItemTooltip = CreateGameTooltip('ATSWRecipeItemTooltip')

local function AddSpace(S)
	if string.len(S) 	== 0 then
		S = S .. '    '
	elseif string.len(S) 	== 1 then
		S = S .. '  '
	end
	
	return S
end

local function AddColor(S, Amount)
	if Amount == 0 then
		S = Color.GREY .. S	.. '|r'
	else
		S = '|cffffffff' .. S .. '|r'
	end
	
	return S
end

local function WordWrap(Text, Max)
	if not Text then
		return ''
	end

	local Length = string.len(Text)
	
	if Length <= Max then
		return Text
	end

	local Result = ''
	local I = 1

	while I <= Length do
		Result = Result .. string.sub(Text, I, I + Max - 1)
		I = I + Max
		
		if I <= Length then
			Result = Result .. '\n'
		end
	end

	return Result
end

function ATSW_ShowRecipeTooltip()
    if not ATSW_Options.RecipeTooltip then
		return
	end
	
	local R = Recipe(GetRecipeSortedPosition(this.Name))
	
	if IsBeastTraining() then
		if R then
			GameTooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT')
			GameTooltip:SetCraftSpell(R.Position)
		end
		
		return
	end
	
	local Tooltip = ATSWRecipeTooltip
	
	Tooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT', -4, 5)
	
	if this.Type == 'header' then
		return
	end
	
	local LINE_HEIGHT = 18
	
	Tooltip:ClearLines()
	
	-- Header
	
	local cR, cG, cB = 1, 1, 1
	
	if R.Link then
		cR, cG, cB = GetLinkColorRGB(R.Link)
	end

	Tooltip:AddIconLine(R.Texture, R.Name, cR, cG, cB)
	
	-- Game tooltip information
	
	ATSWRecipeItemTooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT')
	
	ATSW_TooltipSetSkill(ATSWRecipeItemTooltip, this.Position)
	
	ATSWRecipeItemTooltipTextLeft1:SetText(' ')
	ATSWRecipeItemTooltip:Show()
	
	local Height = ATSWRecipeItemTooltip:GetHeight()
	
	if Height > LINE_HEIGHT * 2 then
		for I = 1, Height/LINE_HEIGHT do
			Tooltip:AddTextLine(' ')
		end
	end

	-- Skill ups
	
	local AtlasLoot, SU2, SU3, SU4 = ATSW_SkillUps(R.Name, ATSW_GetRecipeSpellID(R))
	
	if AtlasLoot then
		Tooltip:AddTextLine(ATSW_TOOLTIP_SKILLUPS .. Color.ORANGE .. (AtlasLoot or '?') ..' ' .. Color.YELLOW .. (SU2 or '?') ..' ' .. Color.GREEN .. (SU3 or '?') ..' ' .. Color.GREY .. (SU4 or '?'), 11)
	end
	
	-- Required reagents
	
	Tooltip:AddTextLine(' ')
	Tooltip:AddDoubleLine(nil, ATSW_TOOLTIP_NECESSARY,
		ATSW_TOOLTIP_INBAGS 	.. '   ' .. ATSW_TOOLTIP_INBANK .. '   ' .. ATSW_TOOLTIP_ONALTS)
	
	-- Reagents
	
	local Reagents = GetReagents(R.Name, 1)
	
	for I = 1, 19 do
		if I <= table.getn(Reagents) then
			local R = Reagents[I]
			local Bags 				= ATSW_GetBagsAmount	(R.Name)
			local Bank 				= ATSW_GetBankAmount	(R.Name)
			local Alts 				= ATSW_GetAltsAmount		(R.Name)
			local Merchant 		= ''
			
			if ATSW_IsInMerchant(R.Name) then
				Merchant 			= ' ' .. Color.GREY .. ATSW_TOOLTIP_BUYABLE..'|r'
			end
			
			local Amountstring 	= ''
			
			if R.Amount > 1 then
				Amountstring 	= Color.GREY .. ' (' .. R.Amount .. ')|r'
			end
			
			if Bags == 0 then
				Bags = ''
			end
			
			if Bank == 0 then
				Bank = ''
			end
			
			if Alts == 0 then
				Alts = ''
			end
			
			local BagStr, BankStr, AltsStr = Bags, Bank, Alts
			
			BagStr 	= AddSpace	(BagStr				)
			BankStr	= AddSpace	(BankStr			)
			AltsStr 	= AddSpace	(AltsStr				)
			BagStr	= AddColor	(BagStr, 	Bags	)
			BankStr	= AddColor	(BankStr, 	Bank	)
			AltsStr	= AddColor	(AltsStr,		Alts	)
			
			local cR, cG, cB = GetLinkColorRGB(R.Link)
			
			Tooltip:AddDoubleLine(R.Texture, 
				(R.Name or '') .. Amountstring .. Merchant, 
				BagStr 	.. '       ' .. BankStr .. '       ' .. AltsStr .. ' ', cR, cG, cB)
		end
	end
	
	local S
	
	if ChatFrameEditBox:IsVisible() or WIM_EditBoxInFocus then
		S = GetSayTooltipString()
	elseif ATSW_HowManyItemsArePossibleToCreate(R.Name) > 0 then
		S = ATSW_TOOLTIP_ADDITEM
	end
	
	Tooltip:Show()
	Tooltip:SetHeight(Tooltip.NumLines * LINE_HEIGHT + 12 - ATSWRecipeItemTooltip:NumLines() * 2.3)
	
	if S then
		Tooltip:AddTextLine(S)
		Tooltip:SetHeight(Tooltip:GetHeight() + 24)
	end
	
	Tooltip:SetWidth(Tooltip.MaxLineWidth)
	
	ATSWRecipeItemTooltip:ClearAllPoints()
	ATSWRecipeItemTooltip:SetPoint('TOPLEFT', Tooltip, 'TOPLEFT', 0, -8)
end

-- Inventory functions

ATSW_Bags = {}

function ATSW_SaveBag(Bag)
	ATSW_PossibleInvalidate() -- 背包内容变了（2026.10.28）
    if ATSW_Bags[realm] == nil then
        ATSW_Bags[realm] = {}
    end
	
	if ATSW_Bags[realm][player] == nil then
		ATSW_Bags[realm][player] = {}
	end
	
	if ATSW_Bags[realm][player][Bag] == nil then
		ATSW_Bags[realm][player][Bag] = {}
	end
	
	-- Clear
	for Slot in pairs(ATSW_Bags[realm][player][Bag]) do
		ATSW_Bags[realm][player][Bag][Slot] = nil
	end
	
	-- Memorize
	for Slot = 1, GetContainerNumSlots(Bag) do
		local Name = LinkToName(GetContainerItemLink(Bag, Slot))
		
		if Name then
			local _, Amount = GetContainerItemInfo(Bag, Slot)
			
			if ATSW_Bags[realm][player][Bag][Slot] == nil then
				ATSW_Bags[realm][player][Bag][Slot] = {}
			end
			
			 ATSW_Bags[realm][player][Bag][Slot][Name] = Amount
		end
	end
end

function ATSW_GetBagsAmount(Name)
    local Total = 0
	
	if Name then
		for Bag = 0, 4 do
			for Slot = 1, GetContainerNumSlots(Bag) do
				local ItemName = LinkToName(GetContainerItemLink(Bag, Slot))
				
				if ItemName and ItemName == Name then
					local _, Amount = GetContainerItemInfo(Bag, Slot)
					
					Total = Total + Amount
				end
			end
		end
	end
	
    return Total
end

-- Bank functions

ATSW_Bank = {}

function ATSW_SaveBank()
	ATSW_PossibleInvalidate() -- 银行内容变了（2026.10.28）
	if BankFrameOpened then
		if not ATSW_Bank[realm] then
			ATSW_Bank[realm] = {}
		end
		
		if not ATSW_Bank[realm][player] then
			ATSW_Bank[realm][player] = {}
		end
		
		-- Clear
		for I in pairs(ATSW_Bank[realm][player]) do
			ATSW_Bank[realm][player][I] = nil
		end
		
		-- Memorize item slots
		for Slot = 1, 24 do
			local Name = LinkToName(GetContainerItemLink(BANK_CONTAINER, Slot))
			
			if Name then
				local _, Amount = GetContainerItemInfo(BANK_CONTAINER, Slot)
				
				ATSW_AddToBank(Name, Amount)
			end
		end
		
		-- Memorize bank bag slots
		for Container = 5, 10 do
			for Slot = 1, GetContainerNumSlots(Container) do
				local Name = LinkToName(GetContainerItemLink(Container, Slot))
				
				if Name then
					local _, Amount = GetContainerItemInfo(Container, Slot)
					
					ATSW_AddToBank(Name, Amount)
				end
			end
		end
		
		if ATSWFrame:					IsVisible() then ATSW_UpdateRecipes					() end
		if ATSWReagentsFrame:		IsVisible() then ATSW_UpdateNecessaryReagents	() end
		if ATSWShoppingListFrame:	IsVisible() then ATSW_UpdateAuctionList				() end
	end
end

function ATSW_AddToBank(Name, Amount)
    if not ATSW_Bank[realm] then
        ATSW_Bank[realm] = {}
		ATSW_Bank[realm][player] = {}
    end
	
	local BankAmount = ATSW_Bank[realm][player][Name] or 0
	
	ATSW_Bank[realm][player][Name] = BankAmount + Amount
end

function ATSW_GetBankAmount(Name)
    if Name then
		if ATSW_Bank[realm] then
			if ATSW_Bank[realm][player] then
				if ATSW_Bank[realm][player][Name] then
					return ATSW_Bank[realm][player][Name]
				end
			end
		end
	end
	
    return 0
end

-- Alternative character functions
local function GetAltsAmountInBags(Name, PlayerName)
	local Table		= ATSW_Bags[realm]
	local Amount	= 0
	
	if Name and Table then
		for PName in pairs(Table) do
			if (PlayerName and PlayerName == PName) or (PlayerName == nil and PName ~= player) then
				for Bag 	in pairs(Table[PName]) do
					for Slot 	in pairs(Table[PName][Bag]) do
						for IName, IAmount in pairs(Table[PName][Bag][Slot]) do
							if IName == Name then
								Amount = Amount + IAmount
							end
						end
					end
				end
			end
		end
	end
	
	return Amount
end

local function GetAltsAmountInBank(Name, PlayerName)
	local Table		= ATSW_Bank[realm]
	local Amount	= 0
	
	if Name and Table then
		for PName in pairs(Table) do
			if PName ~= player then
				for IName, IAmount in pairs(Table[PName]) do
					if IName == Name then
						Amount = Amount + IAmount
					end
				end
			end
		end
	end
	
	return Amount
end

function ATSW_GetAltsAmount(Name)
    return GetAltsAmountInBags(Name) + GetAltsAmountInBank(Name)
end

local function GetLocation(Table, In)
	if Name then
		for RName in pairs(Table) do
			if RName == realm then
				for PName in pairs(Table[RName]) do
					if PName ~= player then
						local Amount = 0
						
						if Table == ATSW_Bags then
							Amount = Amount + GetAltsAmountInBags(Name, PName)
						elseif Table == ATSW_Bank then
							Amount = Amount + GetAltsAmountInBank(Name, PName)
						end
						
						if Amount > 0 then
							if not HeaderAdded then
								Tooltip:AddTextLine(ATSW_TOOLTIP_POSSESS .. ' ' .. this:GetParent().Link .. ':')
								
								HeaderAdded = true
							end
							
							Tooltip:AddTextLine(ClassColorize(PName) .. ': ' .. '|cffffffff' .. Amount .. '|r ' .. In)
						end
					end
				end
			end
		end
	end
end

function ATSW_GetAltsLocationIntoTooltip(Name)
	local HeaderAdded = false
	local Tooltip = ATSWRecipeTooltip
	
	Tooltip:ClearLines()
	Tooltip:SetOwner(this, 'ANCHOR_BOTTOMRIGHT', 0)
	
	GetLocation(ATSW_Bags, ATSW_ALTLIST1)
	GetLocation(ATSW_Bank, ATSW_ALTLIST2)
	
	Tooltip:Show()
	Tooltip:SetWidth(Tooltip.MaxLineWidth)
	Tooltip:SetHeight(18 + Tooltip.NumLines * 16)
end

-- Merchant functions

ATSW_Merchant = {}

function ATSW_UpdateMerchant()
	ATSW_PossibleInvalidate() -- 商人出售列表变了（2026.10.28）
    if MerchantFrame:IsVisible() then
		for I = 1, GetMerchantNumItems() do
			local Name, _, _, _, Available = GetMerchantItemInfo(I)
			
			if Name and Available == -1 then
				ATSW_Merchant[Name] = true
			end
		end
	end
end

function ATSW_IsInMerchant(Name)
    return Name and ATSW_Merchant[Name]
end

local function GetMerchantReagentsPrice(Buy)
	if not (MerchantFrame:IsVisible() and NecessaryReagentsSize() > 0) then
		return
	end
	
	local TotalPrice = 0
	
	for N = 1, NecessaryReagentsSize() do
		-- Calculate total price
		local Item = NecessaryReagent(N)
		
		for M = 1, GetMerchantNumItems() do
			local MName, _, MPrice, MQuantity, MAvailable = GetMerchantItemInfo(M)
			
			if Item.Name == MName then
				local HaveQuantity	= ATSW_GetBagsAmount(Item.Name) + (ATSW_ConsigerBank and ATSW_GetBankAmount(Item.Name) or 0)
				local NeedQuantity	= Item.Amount - HaveQuantity
				local BuyQuantity = math.ceil(NeedQuantity / MQuantity)
				
				if BuyQuantity > MAvailable and MAvailable > 0 then
					BuyQuantity = MAvailable
				end
				
				if BuyQuantity < 0 then
					BuyQuantity = 0
				end
				
				TotalPrice = TotalPrice + BuyQuantity * MPrice
				
				if Buy and BuyQuantity > 0 then
					BuyMerchantItem(M, BuyQuantity)
				end
			end
		end
	end
	
	return TotalPrice
end

function ATSW_SetBuyFrameVisible()
	local Price = GetMerchantReagentsPrice()
	
   if Price and Price > 0 then
		MoneyFrame_Update(ATSWBuyPrice:GetName(), Price)
		ATSWBuyButton:Enable()
		ATSWBuyNecessaryFrame:Show()
	else
		ATSWBuyNecessaryFrame:Hide()
	end
end

function ATSW_BuyFromMerchant()
    GetMerchantReagentsPrice(true)
end

-- Compatibility with other AddOns

-- ArmorCraft
function ATSW_ArmorCraftCompatibility()
	if AC_Craft and AC_Craft:GetParent() ~= ATSWFrame then
		AC_Craft:				SetParent			(ATSWFrame)
		AC_Craft:				SetPoint			('TOPLEFT', 'ATSWFrame', 'TOPRIGHT', 0, 0)
		AC_Craft:				SetFrameLevel	(0)
		AC_ToggleButton:	SetParent			(ATSWFrame)
		AC_ToggleButton:	SetFrameLevel	(ATSWFrame:GetFrameLevel() + 3)
		AC_ToggleButton:	ClearAllPoints()
		AC_ToggleButton:	SetPoint			('RIGHT', 'ATSWFrameCloseButton', 'LEFT', - AC_ToggleButton:GetWidth() - 80)
		AC_UseButton:		ClearAllPoints()
		AC_UseButton:		SetFrameLevel	(ATSWFrame:GetFrameLevel() + 3)
		AC_UseButton:		SetPoint			('RIGHT', 'AC_ToggleButton', 'LEFT', -2, 0)
		AC_Craft:				SetAlpha			(1.0)
		AC_ToggleButton:	SetAlpha			(1.0)
		AC_UseButton:		SetAlpha			(1.0)
		AC_ToggleButton:	Show()
	end
end

-- AtlasLoot
ATSW_AtlasLoot = nil

function ATSW_CheckForAtlasLootLoaded()
	return AtlasLoot_Data and AtlasLoot_Data['AtlasLootCrafting']
end

ATSWSkillUpCache = {}

-- Build lookup indexes from AtlasLoot's crafting database (AtlasLoot_Data["AtlasLootCrafting"]).
-- Primary index : numeric spell/enchant ID  (language independent -> works on any client locale)
-- Secondary index: stripped recipe name      (legacy path, works for English clients)
-- Scanning ALL sub-tables (not just the old Apprentice/Journeyman/... ones) also covers recipes
-- that the new AtlasLoot moved into specialist tables (EnchantingCloak1, SmithingHelm1, ...).
-- Set to false once the skill-up display works, to silence the in-chat diagnostics.
ATSW_SKILLUP_DEBUG = false
ATSW_SkillUpDebugCount = 0
ATSW_SkillUpSeen = {}

local function ATSW_SkillUpDebug(...)
	if ATSW_SKILLUP_DEBUG then
		DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[ATSW-SkillUp]|r " .. string.format(unpack(arg)))
	end
end

function ATSW_BuildAtlasLootSkillIndex()
	if not ATSW_AtlasLoot then return end
	if ATSW_AtlasLootSkillIndex then return end

	ATSW_AtlasLootSkillIndex = {}
	ATSW_AtlasLootNameIndex = {}

	local soPat = '=so1=%s*(%d+)%s*=so2=%s*(%d+)%s*=so3=%s*(%d+)%s*=so4=%s*(%d+)'

	local ok, err = pcall(function()
		for _, Table in pairs(ATSW_AtlasLoot) do
			if type(Table) == 'table' then
				for _, Info in pairs(Table) do
					if type(Info) == 'table' then
						local idField = Info[1]
						local diffField = Info[4]

						if idField and type(diffField) == 'string' then
							-- string.find returns (start, end, capture1, capture2, ...) -> discard start/end with _
							local _, _, s1, s2, s3, s4 = string.find(diffField, soPat)

							if s1 then
								-- numeric spell/enchant ID from AtlasLoot's first field (e.g. "e7418" / "s2329" / "22384")
								-- NOTE: Lua 5.0 string.gsub returns (string, count) -- wrap in () so only the
								-- string is passed to tonumber, otherwise the count would be read as the base arg.
								local spellID = tonumber((string.gsub(tostring(idField), '%D', '')))

								if spellID then
									ATSW_AtlasLootSkillIndex[spellID] = { tonumber(s1), tonumber(s2), tonumber(s3), tonumber(s4) }
								end

								-- stripped name (drop the leading =qN= / =ds= prefix) for the legacy path
								local nameField = Info[3]

								if nameField and type(nameField) == 'string' then
									local nm = string.gsub(nameField, '^=.-=', '')

									if nm ~= '' then
										ATSW_AtlasLootNameIndex[string.lower(nm)] = { tonumber(s1), tonumber(s2), tonumber(s3), tonumber(s4) }
									end
								end
							end
						end
					end
				end
			end
		end
	end)

	if not ok then
		ATSW_SkillUpDebug("index build error: %s", tostring(err))
	end

	local n = 0
	for _ in pairs(ATSW_AtlasLootSkillIndex) do n = n + 1 end
	ATSW_SkillUpDebug("AtlasLoot detected=%s, spell-index entries=%d, name-index entries=%d",
		tostring(ATSW_AtlasLoot ~= nil), n, (function() local m=0; for _ in pairs(ATSW_AtlasLootNameIndex or {}) do m=m+1 end; return m end)())
	ATSW_SkillUpDebug("APIs: GetTradeSkillRecipeLink=%s, GetCraftRecipeLink=%s, TradeSkill=%s",
		tostring(type(GetTradeSkillRecipeLink) == 'function'),
		tostring(type(GetCraftRecipeLink) == 'function'),
		tostring(TradeSkill))
end

-- Get the numeric spell/enchant ID for a recipe.
-- This client (SuperWoW + Nampower build) does NOT expose GetTradeSkillRecipeLink /
-- GetCraftRecipeLink, so the recipe/spell link is unavailable by that route.
-- Workaround based on what the game DOES provide:
--   * Craft frame (enchanting): GetCraftItemLink() returns the *enchant* link
--     |Henchant:ID|h (enchanting "crafts" an enchant, not an item). Its ID matches
--     AtlasLoot's eXXXX key -> use R.Link.
--   * TradeSkill frame: GetTradeSkillItemLink() returns the *result item* link, whose
--     ID differs from the spell ID AtlasLoot uses (sXXXX). No reliable source here, so we
--     return nil and let the (English) name fallback handle it on English clients.
function ATSW_GetRecipeSpellID(R)
	if not R then
		ATSW_SkillUpDebug("GetRecipeSpellID: R is nil")
		return nil
	end

	if TradeSkill then
		-- TradeSkill frame: R.Link is the *result item* link, not the spell link.
		local k = "ts:" .. tostring(R.Name)
		if ATSW_SKILLUP_DEBUG and not ATSW_SkillUpSeen[k] then
			ATSW_SkillUpSeen[k] = true
			ATSW_SkillUpDebug("GetRecipeSpellID(tradeskill): name=%s R.Link=%s -> nil (item link, no spell ID)",
				tostring(R.Name), tostring(R.Link))
		end
		return nil
	end

	-- Craft frame (enchanting): R.Link is the enchant link, e.g. |Henchant:7418|h
	local id
	if R.Link then
		id = ATSW_LinkToID(R.Link)
	end

	local k = "en:" .. tostring(R.Link)
	if ATSW_SKILLUP_DEBUG and not ATSW_SkillUpSeen[k] then
		ATSW_SkillUpSeen[k] = true
		ATSW_SkillUpDebug("GetRecipeSpellID(enchant): link=%s id=%s", tostring(R.Link), tostring(id))
	end

	return id
end


-- [ATSW skillup] 中文配方名 -> 技能涨点(橙/黄/绿/灰) 桥接表
-- 提取自旧版 AtlasLoot 3.2.8 (zhCN 配方名) Database/Crafting.lua。
-- 新版 3.3.8 配方名改为英文，旧 ATSW 按名字匹配在中文客户端失效；
-- 本表让交易技能也能用中文名命中涨点数据（附魔仍走 eXXXX ID 路径）。
-- [ATSW skillup] 中文配方名 -> 技能涨点(橙/黄/绿/灰) 桥接表
-- 自动生成：源 = AtlasLoot  ̃3.3.8 Database/Crafting.lua + Locale/locale.cn.lua
-- 未本地化条目(生存专业服务端中文化)由 OVERRIDE 提供。
-- [ATSW skillup] 中文配方名 -> 技能涨点(橙/黄/绿/灰) 桥接表
-- 自动生成：源 = AtlasLoot 3.3.8 Database/Crafting.lua + Locale/locale.cn.lua
-- 未本地化条目(生存专业服务端中文化)由 OVERRIDE 提供。
-- [ATSW skillup] 中文配方名 -> 技能涨点(橙/黄/绿/灰) 桥接表
-- 自动生成：源 = AtlasLoot 3.3.8 Database/Crafting.lua + Locale/locale.cn.lua
-- 未本地化条目(生存专业服务端中文化)由 OVERRIDE 提供。
-- [ATSW skillup] 中文配方名 -> 技能涨点(橙/黄/绿/灰) 桥接表
-- 自动生成：源 = AtlasLoot 3.3.8 Database/Crafting.lua + Locale/locale.cn.lua
-- 未本地化条目(生存专业服务端中文化)由 OVERRIDE 提供。
ATSW_CnSkillUpByName = {
	["Advanced Camouflage"] = {245,265,275,285},
	["Agitating Poison I"] = {1,290,300,310},
	["Aromatic Berries"] = {240,260,270,280},
	["Arthas' Tears"] = {220,250,270,320},
	["Astronomer Raiments"] = {300,315,322,330},
	["Black Lotus"] = {300,345,375,400},
	["Blackmouth Fishing Trap"] = {125,145,155,165},
	["Blindweed"] = {235,260,285,335},
	["Briarthorn"] = {70,95,120,170},
	["Bright Wood Arrows"] = {145,165,175,185},
	["Brilliant Mana Oil"] = {300,310,320,330},
	["Brilliant Wizard Oil"] = {300,310,320,330},
	["Bruiseweed"] = {100,130,150,200},
	["Bundle of Bright Wood Sticks"] = {125,135,140,145},
	["Bundle of Shade Wood Sticks"] = {175,185,190,195},
	["Bundle of Star Wood Sticks"] = {270,275,280,285},
	["Bundle of Tropical Sticks"] = {225,235,240,245},
	["Cooling Rations Bag"] = {290,310,320,330},
	["Crude Fishing Rod"] = {70,90,100,110},
	["Depthstalker Helm"] = {300,300,300,300},
	["Dimensional Ripper: Everlook"] = {260,285,295,305},
	["Dreamfoil"] = {270,295,320,370},
	["Earthroot"] = {15,40,65,115},
	["Edged Machete"] = {165,185,195,205},
	["Emergency Parachute"] = {250,270,280,290},
	["Enchanted Gemstone Oil"] = {275,275,280,300},
	["Enchanted Leather"] = {250,250,255,260},
	["Enchanted Thorium"] = {250,250,255,260},
	["Eternal Dreamstone Shard"] = {300,300,300,300},
	["Fadeleaf"] = {160,190,210,260},
	["Festival Dress"] = {250,265,280,295},
	["Firebloom"] = {205,235,255,305},
	["Firefin Fishing Trap"] = {175,195,205,215},
	["Fisherman's Backpack"] = {285,305,315,325},
	["Fishing Bag"] = {105,125,135,145},
	["Gardening Broom"] = {95,115,125,135},
	["Gardening Gloves"] = {65,85,95,105},
	["Gardening Pitchfork"] = {120,140,150,160},
	["Ghost Mushroom"] = {245,270,295,345},
	["Golden Sansam"] = {260,280,310,360},
	["Goldthorn"] = {170,195,220,270},
	["Grave Moss"] = {120,150,170,220},
	["Greater Magic Wand"] = {70,110,130,150},
	["Greater Mystic Wand"] = {175,195,215,235},
	["Gromsblood"] = {250,275,300,350},
	["Hat of the Junior Chef"] = {140,160,170,180},
	["Healing Salve"] = {100,120,130,140},
	["Heavy Duty Machete"] = {260,280,285,290},
	["Herbalist's Knapsack"] = {285,305,315,325},
	["Hiking Staff"] = {215,235,245,255},
	["Hunting Spear"] = {90,110,120,130},
	["Icecap"] = {290,315,340,390},
	["Iron Buckle"] = {150,150,152,155},
	["Iron Spear"] = {165,185,195,205},
	["Jungle Remedy"] = {195,215,225,235},
	["Khadgar's Whisker"] = {185,210,235,285},
	["Kingsblood"] = {125,155,175,225},
	["Lesser Magic Wand"] = {10,75,95,115},
	["Lesser Mana Oil"] = {250,260,270,280},
	["Lesser Mystic Wand"] = {155,175,195,215},
	["Lesser Wizard Oil"] = {200,210,220,230},
	["Liferoot"] = {150,175,200,250},
	["Lined Wintercloak"] = {185,205,215,225},
	["Mageroyal"] = {50,75,100,150},
	["Major Healing Salve"] = {300,320,330,340},
	["Makeshift Knife"] = {60,80,90,100},
	["Mastercraft Fishing Rod"] = {275,295,305,315},
	["Miner's Rucksack"] = {280,300,310,320},
	["Minor Mana Oil"] = {150,160,170,180},
	["Minor Wizard Oil"] = {45,55,65,75},
	["Mountain Silversage"] = {280,305,330,380},
	["Murloc Scale Coat"] = {125,145,155,165},
	["Nutritious Rations"] = {205,225,235,245},
	["Oakwood Bow"] = {100,120,130,140},
	["Oil-Powered Cooker"] = {295,315,325,335},
	["Peacebloom"] = {1,25,50,100},
	["Philosopher's Stone"] = {200,240,260,280},
	["Plaguebloom"] = {285,310,335,385},
	["Portable Wormhole Generator: Orgrimmar"] = {120,145,157,170},
	["Portable Wormhole Generator: Stormwind"] = {120,145,157,170},
	["Potent Healing Salve"] = {150,170,180,190},
	["Premium Fishing Lure"] = {250,270,280,290},
	["Primalist's Gloves "] = {270,285,290,295},
	["Prospector’s Magnifying Lens"] = {300,320,330,340},
	["Purple Lotus"] = {210,240,260,310},
	["Razor-sharp Skinning Knife"] = {270,290,300,310},
	["Reinforced Fishing Rod"] = {170,190,200,210},
	["Reliable Fishing Rod"] = {135,155,165,175},
	["Rugged Mining Sack"] = {140,160,170,180},
	["Runed Arcanite Rod"] = {290,310,330,350},
	["Runed Copper Rod"] = {1,5,7,10},
	["Runed Golden Rod"] = {150,175,195,215},
	["Runed Silver Rod"] = {100,130,150,170},
	["Runed Truesilver Rod"] = {200,220,240,260},
	["Savory Fishing Lure"] = {200,220,230,240},
	["Shade Wood Arrows"] = {205,225,235,245},
	["Sharpened Herb Sickle"] = {180,200,210,220},
	["Silverleaf"] = {1,25,50,100},
	["Simple Fishing Lure"] = {100,120,130,140},
	["Skinner's Carryall"] = {285,305,315,325},
	["Skinner's Pack"] = {110,130,140,150},
	["Sleek Pinewood Bow"] = {190,210,220,230},
	["Slowing Bolas"] = {155,175,185,195},
	["Smoking Heart of the Mountain"] = {265,285,305,325},
	["Smooth Ironfeather Arrows"] = {255,275,285,295},
	["Snap Trap"] = {160,180,190,200},
	["Snowmaster 9000"] = {190,190,210,230},
	["Spectre Shade Ring"] = {180,200,210,220},
	["Spiced Berries"] = {240,260,270,280},
	["Spicy Fishing Lure"] = {150,170,180,190},
	["Spirited Precision Sickle"] = {300,320,330,340},
	["Stabilizing Healing Salve"] = {250,270,280,290},
	["Starfeather Arrows"] = {300,320,330,340},
	["Stonescale Fishing Trap"] = {275,295,305,315},
	["Stranglekelp"] = {85,115,135,185},
	["Studded Rations Bag"] = {150,170,180,190},
	["Sturdy Blade"] = {130,150,160,170},
	["Sturdy Cane"] = {130,150,160,170},
	["Sturdy Knife"] = {130,150,160,170},
	["Sturdy Net"] = {130,130,135,140},
	["Sungrass"] = {230,255,280,330},
	["Sunshade Hat"] = {235,255,265,275},
	["Superior Healing Salve"] = {200,220,230,240},
	["Thick Rations Bag"] = {235,255,265,275},
	["Thorium Edged Machete"] = {260,280,285,290},
	["Thorium Spear"] = {265,285,295,305},
	["Throwable Net"] = {140,160,170,180},
	["Treasure Compass"] = {145,165,175,185},
	["Tree Hatchet"] = {215,235,245,255},
	["Ultrasafe Transporter: Gadgetzan"] = {260,285,295,305},
	["Vine Cutter"] = {215,235,245,255},
	["Warped Recurve Bow"] = {240,260,270,280},
	["Water Trudgers"] = {175,195,205,215},
	["Weak Healing Salve"] = {50,70,80,90},
	["Wild Steelbloom"] = {115,145,165,215},
	["Wintersbite"] = {195,225,245,295},
	["Wizard Oil"] = {275,285,295,305},
	["一把螺栓"] = {30,45,52,60},
	["一捆树枝"] = {5,10,12,15},
	["不牢固的扳机"] = {200,200,220,240},
	["不稳定的奥术宝石"] = {nil,275,277,280},
	["不稳定的采矿炸药"] = {75,90,97,105},
	["世界放大器"] = {260,260,265,270},
	["丛林大杂烩"] = {175,215,235,255},
	["丝绸卷"] = {125,135,140,145},
	["丝绸小包"] = {150,170,185,200},
	["丝质头带"] = {160,170,175,180},
	["丝质绷带"] = {150,150,180,210},
	["丝质长披风"] = {185,205,220,235},
	["中型护甲片"] = {100,115,122,130},
	["中皮"] = {100,100,105,110},
	["乌木刀"] = {255,280,292,305},
	["乌木戒指"] = {75,95,105,115},
	["乌龟戒指"] = {160,185,195,205},
	["亚麻包"] = {45,70,87,105},
	["亚麻布卷"] = {1,25,37,50},
	["亚麻披风"] = {1,35,47,60},
	["亚麻绷带"] = {1,30,45,60},
	["亚麻腰带"] = {15,50,67,85},
	["亚麻靴"] = {65,90,107,125},
	["亮布手套"] = {270,285,300,315},
	["亮布披风"] = {275,290,305,320},
	["亮布短裤"] = {290,305,320,335},
	["亮布长袍"] = {270,285,300,315},
	["亮铜项链"] = {65,85,92,100},
	["亮闪闪的钢匕首"] = {180,205,217,230},
	["仇恨熔炉头盔"] = {290,300,310,320},
	["仇恨熔炉护手"] = {285,300,310,320},
	["仇恨熔炉护腿"] = {290,300,310,320},
	["仇恨熔炉胸甲"] = {290,300,310,320},
	["仇恨熔炉腰带"] = {275,300,312,325},
	["仇恨熔炉靴子"] = {275,300,310,320},
	["仿真机械蛙"] = {265,285,295,305},
	["优质治疗药水"] = {215,230,250,270},
	["优质法力药水"] = {260,275,295,315},
	["优质皮外套"] = {85,115,130,145},
	["优质皮带"] = {80,110,125,140},
	["优质皮手套"] = {75,105,120,135},
	["优质皮披风"] = {85,105,120,135},
	["优质皮裤"] = {105,130,142,155},
	["优质皮靴"] = {90,120,135,150},
	["优雅翡翠"] = {nil,250,252,255},
	["体面的白衬衣"] = {170,180,185,190},
	["侏儒作战小鸡"] = {230,250,260,270},
	["侏儒微调器"] = {175,175,195,215},
	["侏儒护目镜"] = {210,230,240,250},
	["侏儒撒网器"] = {210,230,240,250},
	["侏儒死亡射线"] = {240,260,270,280},
	["侏儒洗脑帽"] = {235,255,265,275},
	["侏儒火箭靴"] = {225,245,255,265},
	["侏儒缩小射线"] = {205,225,235,245},
	["侏儒通用遥控器"] = {125,150,162,175},
	["侏儒防护腰带"] = {215,235,245,255},
	["侏儒隐形装置"] = {200,220,230,240},
	["侦测亡灵药剂"] = {230,245,265,285},
	["侦测恶魔药剂"] = {250,265,285,305},
	["侦测次级隐形药剂"] = {195,215,235,255},
	["便利口粮袋"] = {40,60,70,80},
	["便携式青铜迫击炮"] = {165,185,195,205},
	["信念外衣"] = {300,315,330,345},
	["信念手套"] = {150,170,185,200},
	["修复的电灯"] = {230,250,260,270},
	["修理机器人74A型"] = {300,320,330,340},
	["修道院灰烬护腕"] = {170,185,195,205},
	["偏斜护肩"] = {300,315,322,330},
	["元素磨刀石"] = {300,300,310,320},
	["先知之刃"] = {300,320,330,340},
	["先知药剂"] = {265,280,300,320},
	["光亮护腕"] = {300,320,330,340},
	["光芒之怒指环"] = {300,320,330,340},
	["光芒手套"] = {300,315,330,345},
	["光芒护腕"] = {300,315,330,345},
	["光芒护腿"] = {300,315,330,345},
	["光芒衬肩"] = {300,315,330,345},
	["光芒长袍"] = {300,315,330,345},
	["光辉蓝宝石戒指"] = {300,320,330,340},
	["免伤锁甲"] = {300,320,330,340},
	["兽人护腿"] = {210,250,260,270},
	["冥想手套"] = {130,150,165,180},
	["冬夜法袍"] = {285,300,315,330},
	["冬天爷爷的手套"] = {190,210,220,230},
	["冰川外衣"] = {300,315,330,345},
	["冰川手套"] = {300,315,330,345},
	["冰川护腕"] = {300,315,330,345},
	["冰川披风"] = {300,315,330,345},
	["冰覆披风"] = {200,220,235,250},
	["冰霜之力药剂"] = {190,210,230,250},
	["冰霜之油"] = {200,220,240,260},
	["冰霜皮质披风"] = {180,200,210,220},
	["冰霜缚斩者"] = {180,190,195,200},
	["冰霜防护药水"] = {190,205,225,245},
	["冷木斧"] = {270,290,300,310},
	["净化药水"] = {285,300,320,340},
	["凤凰手套"] = {125,150,167,185},
	["凤凰短裤"] = {125,150,167,185},
	["初级坚韧药剂"] = {50,80,100,120},
	["初级抗魔药水"] = {110,135,155,175},
	["初级敏捷药剂"] = {50,80,100,120},
	["初级治疗药水"] = {1,55,75,95},
	["初级法力药水"] = {25,65,85,105},
	["初级活力药水"] = {40,70,90,110},
	["初级防御药剂"] = {1,55,75,95},
	["刺花护腕"] = {105,125,135,145},
	["刺须鲶鱼"] = {100,140,160,180},
	["力反馈盾牌"] = {300,320,330,340},
	["力量法袍"] = {190,210,225,240},
	["加列拉之杖"] = {200,225,235,245},
	["加速药水"] = {300,315,322,330},
	["劣质平衡石"] = {1,15,35,55},
	["劣质火枪"] = {50,80,95,110},
	["劣质火炬"] = {1,10,12,15},
	["劣质火药"] = {1,20,30,40},
	["劣质炸药"] = {1,30,45,60},
	["劣质瑟银戒指"] = {235,245,250,255},
	["劣质的宝石串"] = {35,45,50,55},
	["劣质的铜戒指"] = {1,21,30,40},
	["劣质真银戒指"] = {200,200,205,210},
	["劣质砂纸"] = {1,21,25,30},
	["劣质砂轮"] = {25,45,65,85},
	["劣质磨刀石"] = {1,15,35,55},
	["劣质秘银戒指"] = {175,175,177,180},
	["劣质铜壳炸弹"] = {30,60,75,90},
	["劣质铜外衣"] = {1,15,35,55},
	["劣质青铜战靴"] = {95,125,140,155},
	["劣质青铜护肩"] = {110,140,155,170},
	["劣质青铜护腕"] = {100,140,160,180},
	["劣质青铜护腿"] = {105,145,160,175},
	["劣质青铜胸甲"] = {105,145,160,175},
	["化石合剂"] = {300,315,322,330},
	["北极外套"] = {300,320,330,340},
	["北极手套"] = {300,320,330,340},
	["北极护腕"] = {300,320,330,340},
	["午夜之戒"] = {125,145,155,165},
	["午夜吊坠"] = {120,145,155,165},
	["半人马战甲"] = {300,320,330,340},
	["半人马指环"] = {160,180,190,200},
	["半人马权威护肩"] = {300,320,330,340},
	["华丽山地宝石"] = {300,330,345,360},
	["华丽瑟银手斧"] = {275,300,312,325},
	["华丽的秘银权杖"] = {200,220,230,240},
	["华丽秘银手镯"] = {200,225,237,250},
	["华丽血石匕首"] = {300,320,330,340},
	["占卜者兜帽"] = {230,230,230,230},
	["占卜者手套"] = {225,225,225,225},
	["占卜者护肩"] = {230,230,230,230},
	["占卜者裤子"] = {230,230,230,230},
	["占卜者长袍"] = {235,235,235,235},
	["占卜者鞋子"] = {225,225,225,225},
	["卡多雷蜘蛛烤肉"] = {10,50,70,90},
	["厚丝质绷带"] = {180,180,210,240},
	["厚亚麻绷带"] = {40,50,75,100},
	["厚皮"] = {200,200,202,205},
	["厚皮弹药包"] = {225,245,255,265},
	["厚符文布绷带"] = {290,290,320,350},
	["厚绒线绷带"] = {115,115,150,185},
	["厚重战斧"] = {70,110,130,150},
	["厚重护甲片"] = {200,220,230,240},
	["厚重的宝石串"] = {150,150,152,155},
	["厚重砂纸"] = {150,150,155,160},
	["厚重黑曜石胸甲"] = {300,320,330,340},
	["厚魔纹绷带"] = {240,240,270,300},
	["厚鱼人皮甲"] = {170,190,200,210},
	["原始水晶石"] = {150,155,157,160},
	["原始蝙蝠皮外套"] = {300,320,330,340},
	["原始蝙蝠皮手套"] = {300,320,330,340},
	["原始蝙蝠皮护腕"] = {300,320,330,340},
	["双线毛纺护肩"] = {110,135,152,170},
	["发条娃娃"] = {205,205,205,205},
	["发条式同步协调陀螺仪"] = {170,170,190,210},
	["古代法老智慧之杖"] = {170,190,200,210},
	["古代矮人宝石"] = {185,185,195,205},
	["古拉巴什浓汤"] = {300,300,300,300},
	["古拉巴什魔精"] = {300,315,322,330},
	["吉尔尼斯热炖菜"] = {200,240,260,280},
	["君王板甲头盔"] = {295,315,325,335},
	["君王板甲战靴"] = {295,315,325,335},
	["君王板甲护肩"] = {265,285,295,305},
	["君王板甲护胸"] = {300,320,330,340},
	["君王板甲护腕"] = {270,290,300,310},
	["君王板甲护腿"] = {300,320,330,340},
	["君王板甲腰带"] = {265,285,295,305},
	["啤酒烤猪排"] = {25,60,80,100},
	["圆润翡翠"] = {175,180,182,185},
	["土灵丝质腰带"] = {195,215,230,245},
	["土灵外衣"] = {170,190,205,220},
	["土灵皮护肩"] = {135,160,172,185},
	["地狱火手套"] = {300,315,330,345},
	["地狱灾祸手杖"] = {160,180,190,200},
	["地精工兵炸药"] = {205,205,225,245},
	["地精施工头盔"] = {205,225,235,245},
	["地精无线电"] = {225,240,250,260},
	["地精暗雷"] = {195,215,225,235},
	["地精火箭头盔"] = {245,265,275,285},
	["地精火箭燃油"] = {210,225,245,265},
	["地精火箭燃油配方"] = {205,205,205,205},
	["地精火箭靴"] = {225,245,255,265},
	["地精炸弹箱"] = {230,230,250,270},
	["地精芥末蘸蚌肉"] = {125,165,185,205},
	["地精起搏器"] = {165,165,180,200},
	["地精起搏器XL型"] = {265,285,295,305},
	["地精迫击炮"] = {205,225,235,245},
	["地精采矿头盔"] = {205,225,235,245},
	["地精龙枪"] = {240,260,270,280},
	["坚固的平衡石"] = {200,200,205,210},
	["坚固的砂轮"] = {200,200,205,210},
	["坚固的磨刀石"] = {200,200,205,210},
	["坚固砂纸"] = {200,200,205,210},
	["坚硬的铜戒指"] = {25,45,52,60},
	["坚韧药剂"] = {175,195,215,235},
	["垂钓小舟"] = {115,135,145,155},
	["塔铸皇冠"] = {300,325,337,350},
	["塔铸破坏者"] = {300,325,337,350},
	["塔铸肩铠"] = {300,325,337,350},
	["塔铸胸甲"] = {300,325,337,350},
	["塞纳留斯之袋"] = {300,315,330,345},
	["塞纳里奥草药包"] = {275,290,305,320},
	["增亮护目镜"] = {175,195,205,215},
	["增长药剂"] = {90,120,140,160},
	["多彩护手"] = {300,320,330,340},
	["多彩护腿"] = {300,300,300,300},
	["多彩披风"] = {300,320,330,340},
	["多彩褶裙"] = {120,145,162,180},
	["多汁猪排"] = {110,130,150,170},
	["多重抗性合剂"] = {300,315,322,330},
	["夜幕"] = {300,320,330,340},
	["夜色外套"] = {205,225,235,245},
	["夜色头带"] = {205,225,235,245},
	["夜色护肩"] = {210,230,240,250},
	["夜色披风"] = {230,250,260,270},
	["夜色短裤"] = {230,250,260,270},
	["夜色长靴"] = {235,255,265,275},
	["夜视步枪"] = {145,170,182,195},
	["夜鳞鱼汤"] = {250,290,310,330},
	["大口径秘银步枪"] = {220,240,250,260},
	["大地卫士外套"] = {300,300,300,300},
	["大地胸甲"] = {265,nil,nil,nil},
	["大块的熊排"] = {110,150,170,190},
	["大型爆盐炸弹"] = {200,200,220,240},
	["大型红色烟花"] = {175,175,187,200},
	["大型红色烟花束"] = {275,275,280,285},
	["大型绿色烟花"] = {175,175,187,200},
	["大型绿色烟花束"] = {275,275,280,285},
	["大型蓝色烟花"] = {175,175,187,200},
	["大型蓝色烟花束"] = {275,275,280,285},
	["大型铜壳炸弹"] = {105,105,130,155},
	["大师长袍"] = {115,140,157,175},
	["大法师之袍"] = {300,315,330,345},
	["大法师腰带"] = {300,315,330,345},
	["大炸弹"] = {235,235,255,275},
	["大酋长头盔"] = {300,320,330,340},
	["大附魔袋"] = {300,315,330,345},
	["大鱼片"] = {275,315,335,355},
	["天火宝石戒指"] = {210,280,290,300},
	["天蓝星火"] = {265,265,285,305},
	["天青石胸针"] = {205,220,227,235},
	["奇美拉外衣"] = {290,310,320,330},
	["奇美拉手套"] = {265,270,280,290},
	["奇美拉护腿"] = {280,300,310,320},
	["奇美拉长靴"] = {275,295,305,315},
	["奢华宝石项链"] = {80,100,110,120},
	["奥妮克希亚鳞片披风"] = {300,320,330,340},
	["奥术光辉吊坠"] = {280,300,305,310},
	["奥术炸弹"] = {300,320,330,340},
	["奥术翡翠"] = {295,300,302,305},
	["奥法之袍"] = {150,170,185,200},
	["奥法巨人药剂"] = {300,310,330,350},
	["奥法药剂"] = {235,250,270,290},
	["奥秘之杖"] = {300,320,330,340},
	["奥金万能钥匙"] = {275,275,280,285},
	["奥金圣剑"] = {300,320,330,340},
	["奥金带扣"] = {300,325,337,350},
	["奥金幼龙"] = {300,320,330,340},
	["奥金斧"] = {300,320,330,340},
	["奥金棒"] = {275,275,280,285},
	["姜饼"] = {1,45,65,85},
	["嫩狼肉排"] = {225,265,285,305},
	["孔雀石戒指"] = {20,40,47,55},
	["宇宙外衣"] = {300,300,300,300},
	["宇宙头饰"] = {300,300,300,300},
	["宇宙护腿"] = {300,300,300,300},
	["宇宙衬肩"] = {300,300,300,300},
	["守御护符"] = {300,320,330,340},
	["守护之甲"] = {175,195,205,215},
	["守护图腾"] = {135,155,165,175},
	["守护手套"] = {190,210,220,230},
	["守护披风"] = {185,205,215,225},
	["守护短裤"] = {160,180,190,200},
	["守护腕甲"] = {195,215,225,235},
	["守护腰带"] = {170,190,200,210},
	["安全传送器 - 加基森"] = {260,285,295,305},
	["安德麦蚌肉杂烩"] = {225,265,285,305},
	["安静的机械雪人"] = {250,320,330,340},
	["完美的奥金步枪"] = {300,320,330,340},
	["宝石商的魔棒"] = {nil,235,245,255},
	["宝石皮带"] = {185,205,215,225},
	["宝石瞄准镜"] = {225,140,147,155},
	["宝石纲要"] = {275,275,297,320},
	["宝石透镜"] = {125,140,147,155},
	["宝石项圈"] = {160,180,190,200},
	["实心炸弹"] = {175,175,185,195},
	["实心炸药"] = {175,175,185,195},
	["寒冬之刃"] = {190,215,227,240},
	["寒冰偏斜器"] = {155,175,185,195},
	["寒冰护卫者"] = {300,320,330,340},
	["寒鳞护手"] = {300,320,330,340},
	["寒鳞护腕"] = {300,320,330,340},
	["寒鳞胸甲"] = {300,320,330,340},
	["寻心者"] = {300,320,330,340},
	["导尘者腰带"] = {300,315,330,345},
	["封印雕饰"] = {245,245,265,285},
	["将军之帽"] = {240,255,270,285},
	["小型巨魔血戒"] = {50,70,80,90},
	["小型强固戒指"] = {50,70,77,85},
	["小型爆盐炸弹"] = {100,130,145,160},
	["小型珍珠戒指"] = {65,85,92,100},
	["小型红色烟花"] = {125,125,137,150},
	["小型绿色烟花"] = {125,125,137,150},
	["小型蓝色烟花"] = {125,125,137,150},
	["小型青铜炸弹"] = {120,120,145,170},
	["小珍珠法杖"] = {55,75,82,90},
	["尖锐黄水晶"] = {200,205,207,210},
	["屠魔药剂"] = {250,265,285,305},
	["山地护肩"] = {130,155,167,180},
	["山地披风"] = {150,170,180,190},
	["山地皮外衣"] = {100,125,137,150},
	["山地皮手套"] = {145,170,182,195},
	["山地腰带"] = {120,145,157,170},
	["山狗肉排"] = {50,90,110,130},
	["山猫步靴"] = {75,nil,nil,nil},
	["岩石戒指"] = {100,120,130,140},
	["崇高领主甲胄"] = {300,320,330,340},
	["工匠眼镜"] = {185,205,215,225},
	["巧克力鱼"] = {300,300,300,300},
	["巨人药剂"] = {245,260,280,300},
	["巨型宝石指环"] = {nil,315,322,330},
	["巨型瑟银战斧"] = {280,305,317,330},
	["巨型铁斧"] = {185,210,222,235},
	["巨型铁锤"] = {145,175,190,205},
	["巨型黑色锤"] = {230,255,267,280},
	["巫术师兜帽"] = {165,185,200,215},
	["巫毒披风"] = {240,260,270,280},
	["巫毒短裤"] = {240,260,270,280},
	["巫毒长袍"] = {215,235,245,255},
	["巫毒面具"] = {220,240,250,260},
	["巫纹头巾"] = {300,315,330,345},
	["巫纹护腿"] = {275,290,305,320},
	["巫纹长袍"] = {300,315,330,345},
	["帝国板甲护手"] = {270,280,285,290},
	["干烤狼肉串"] = {100,140,160,180},
	["平静"] = {285,310,322,335},
	["幻光宝玉"] = {200,205,205,205},
	["幻彩吊坠"] = {300,300,307,315},
	["幻影之刃"] = {245,270,282,295},
	["幻象染料"] = {245,260,280,300},
	["幽影墨玉"] = {260,265,267,270},
	["弱效巨魔之血药水"] = {15,60,80,100},
	["强力净化器"] = {275,285,290,295},
	["强力嗅盐"] = {300,300,330,360},
	["强力巨魔之血药水"] = {125,150,170,190},
	["强力抗毒药剂"] = {130,130,165,200},
	["强力爆盐炸弹"] = {275,275,285,295},
	["强化亚麻斗篷"] = {60,85,102,120},
	["强化毛纺护肩"] = {120,145,162,180},
	["强效冰霜之力药剂"] = {300,300,315,330},
	["强效冰霜防护药水"] = {290,305,325,345},
	["强效奥术之力药剂"] = {300,300,315,330},
	["强效奥术防护药水"] = {290,305,325,345},
	["强效奥法药剂"] = {285,300,320,340},
	["强效怒气药水"] = {255,270,290,310},
	["强效敏捷药剂"] = {240,255,275,295},
	["强效昏睡药水"] = {275,290,310,330},
	["强效暗影防护药水"] = {290,305,325,345},
	["强效水下呼吸药剂"] = {215,230,250,270},
	["强效治疗药水"] = {155,175,195,215},
	["强效法力药水"] = {205,220,240,260},
	["强效火力药剂"] = {250,265,285,305},
	["强效火焰防护药水"] = {290,305,325,345},
	["强效石盾药水"] = {280,295,315,335},
	["强效神圣防护药水"] = {290,305,325,345},
	["强效禁锢徽记"] = {210,230,240,250},
	["强效聪颖药剂"] = {235,250,270,290},
	["强效自然力量药剂"] = {300,315,322,330},
	["强效自然防护药水"] = {290,305,325,345},
	["强效防御药剂"] = {195,215,235,255},
	["强能草药沙拉"] = {300,325,345,365},
	["强能黄水晶吊坠"] = {175,195,202,210},
	["彩虹之锤"] = {140,170,185,200},
	["彩鳍鱼"] = {50,90,110,130},
	["影月宝珠"] = {85,105,115,125},
	["影皮手套"] = {200,210,220,230},
	["影铸之眼"] = {85,105,115,125},
	["微光白玉坠戒"] = {nil,320,330,340},
	["德莱尼水晶魔棒"] = {200,225,235,245},
	["忘却的圣杯"] = {300,330,340,350},
	["快捷箭袋"] = {225,245,255,265},
	["快速暗影反射器"] = {300,320,330,340},
	["怒气药水"] = {60,90,110,130},
	["急速生长药剂"] = {200,200,212,225},
	["恶魔布包"] = {280,300,315,330},
	["恶魔布帽"] = {290,305,320,335},
	["恶魔布手套"] = {300,315,330,345},
	["恶魔布护肩"] = {300,315,330,345},
	["恶魔布短裤"] = {275,290,305,320},
	["恶魔布袍"] = {300,315,330,345},
	["恶魔布靴"] = {285,300,315,330},
	["惊艳帝王石"] = {300,310,315,320},
	["戈多克食人魔装"] = {275,285,290,295},
	["战熊热裤"] = {285,305,315,325},
	["战熊背心"] = {275,295,305,315},
	["手工亚麻裤"] = {70,95,112,130},
	["手工皮外衣"] = {1,40,55,70},
	["手工皮带"] = {25,55,70,85},
	["手工皮护腕"] = {1,40,55,70},
	["手工皮披风"] = {1,40,55,70},
	["手工皮短裤"] = {15,45,60,75},
	["手工皮靴"] = {1,40,55,70},
	["扳手"] = {50,70,80,90},
	["抑制头环"] = {135,155,165,175},
	["抗毒药剂"] = {80,80,115,150},
	["抗毒药水"] = {120,145,165,185},
	["抗魔药水"] = {210,225,245,265},
	["护卫披风"] = {300,315,330,345},
	["报警机器人"] = {265,275,280,285},
	["掘地鼠炖肉"] = {90,130,150,170},
	["掠夺者兜帽"] = {265,265,265,265},
	["掠夺者手套"] = {260,260,260,260},
	["掠夺者披肩"] = {265,265,265,265},
	["掠夺者裤子"] = {265,265,265,265},
	["掠夺者长袍"] = {270,270,270,270},
	["掠夺者鞋子"] = {260,260,260,260},
	["支配之权杖"] = {300,330,340,350},
	["支配之龙印"] = {300,320,330,340},
	["敏捷药剂"] = {185,205,225,245},
	["斑点黄尾鱼"] = {225,265,285,305},
	["旅行帐篷"] = {50,100,110,120},
	["无底包"] = {300,315,330,345},
	["无暇月亮石"] = {175,180,182,185},
	["旭日皇冠"] = {250,250,270,290},
	["明亮灰烬石"] = {200,205,207,210},
	["明亮瑟银微光"] = {255,270,277,285},
	["明亮的铜戒指"] = {15,35,45,55},
	["昏睡药水"] = {230,245,265,285},
	["星型宝石护腕"] = {nil,270,280,290},
	["星形护符"] = {220,220,240,260},
	["星形瑟银指环"] = {260,260,275,290},
	["星形红玉戒指"] = {nil,300,310,320},
	["星界护符"] = {nil,175,192,210},
	["星辰腰带"] = {200,220,235,250},
	["普通瞄准镜"] = {110,135,147,160},
	["智慧药剂"] = {90,120,140,160},
	["暗影之力药剂"] = {250,265,285,305},
	["暗影之油"] = {165,190,210,230},
	["暗影头巾"] = {170,190,205,220},
	["暗影宝珠"] = {100,120,130,140},
	["暗影护目镜"] = {120,145,157,170},
	["暗影皮靴"] = {205,225,230,235},
	["暗影石戒指"] = {105,125,135,145},
	["暗影防护药水"] = {135,160,180,200},
	["暗纹之靴"] = {240,255,270,285},
	["暗纹手套"] = {225,240,255,270},
	["暗纹护肩"] = {235,250,265,280},
	["暗纹短裤"] = {210,225,240,255},
	["暗纹长袍"] = {215,230,245,260},
	["暗纹面罩"] = {245,260,275,290},
	["暗色护腕"] = {185,205,215,225},
	["暗色皮带"] = {195,215,225,235},
	["暗色皮护腿"] = {165,185,195,205},
	["暗色皮甲"] = {175,195,205,215},
	["暗色长靴"] = {200,220,230,240},
	["暗草护腕"] = {80,160,170,180},
	["暴怒药水"] = {175,195,215,235},
	["曙光护腕"] = {115,135,142,150},
	["月光咒符"] = {nil,275,285,295},
	["月光外衣"] = {90,115,130,145},
	["月光法杖"] = {125,150,160,170},
	["月布"] = {250,290,305,320},
	["月布包"] = {300,315,330,345},
	["月布外衣"] = {300,315,330,345},
	["月布头饰"] = {300,315,330,345},
	["月布手套"] = {300,315,330,345},
	["月布护肩"] = {300,315,330,345},
	["月布护腿"] = {290,305,320,335},
	["月布长袍"] = {300,315,330,345},
	["月布长靴"] = {290,295,310,325},
	["月牙斧"] = {200,225,237,250},
	["月钢宽剑"] = {180,205,217,230},
	["有限无敌药水"] = {250,275,295,315},
	["木喉之力"] = {290,310,320,330},
	["木喉之怒"] = {290,310,320,330},
	["木喉之智"] = {290,305,320,335},
	["木喉作战手套"] = {300,320,330,340},
	["木喉肩铠"] = {300,325,337,350},
	["木喉衬肩"] = {300,315,330,345},
	["未淬火的符文剑"] = {300,320,330,340},
	["机械修理包"] = {200,200,220,240},
	["机械幼龙"] = {200,220,230,240},
	["机械松鼠"] = {75,105,120,135},
	["杂味炖肉"] = {75,115,135,155},
	["杂烩蚌肉"] = {90,130,150,170},
	["林栖者外衣"] = {300,315,330,345},
	["林栖者头冠"] = {300,315,330,345},
	["林栖者护肩"] = {300,315,330,345},
	["柔光戒指"] = {65,85,92,100},
	["柔光照明法杖"] = {210,235,245,255},
	["柔韧奥术石"] = {300,320,330,340},
	["梦境丝线"] = {300,300,300,300},
	["梦境丝线手套"] = {300,300,300,300},
	["梦境丝线护腕"] = {300,300,300,300},
	["梦境丝线披肩"] = {300,300,300,300},
	["梦境丝线裙裤"] = {300,300,300,300},
	["梦境使者"] = {300,320,330,340},
	["梦境皮革"] = {300,320,330,340},
	["梦境皮革护腕"] = {300,320,330,340},
	["梦境皮革护腿"] = {300,320,330,340},
	["梦境皮革披肩"] = {300,320,330,340},
	["梦境皮革腰带"] = {300,320,330,340},
	["梦境精华药剂"] = {300,315,322,330},
	["梦境药剂"] = {240,255,275,295},
	["梦境钢铁护腕"] = {300,325,337,350},
	["梦境钢铁护腿"] = {300,325,337,350},
	["梦境钢铁长靴"] = {300,325,337,350},
	["梦幻龙鳞胸甲"] = {300,320,330,340},
	["梦精猫鼬药剂"] = {300,310,330,350},
	["梦纹外衣"] = {225,240,255,270},
	["梦纹头饰"] = {250,265,280,295},
	["梦纹手套"] = {225,240,255,270},
	["梦酊火酒药剂"] = {300,310,330,350},
	["梦钢带扣"] = {300,325,337,350},
	["棕色亚麻外衣"] = {10,45,57,70},
	["棕色亚麻短裤"] = {30,55,72,90},
	["棕色亚麻衬衣"] = {1,35,47,60},
	["棕色亚麻长袍"] = {30,55,72,90},
	["棱光护符"] = {265,265,285,305},
	["棱光鳞甲头盔"] = {300,300,305,310},
	["橙色军用衬衣"] = {220,225,230,235},
	["橙色魔纹衬衣"] = {215,220,225,230},
	["次级巫师袍"] = {135,155,170,185},
	["次级敏捷药剂"] = {140,165,185,205},
	["次级治疗药水"] = {55,85,105,125},
	["次级法力药水"] = {120,145,165,185},
	["次级石盾药水"] = {215,230,250,270},
	["次级隐形药水"] = {165,185,205,225},
	["歼灭者"] = {300,320,330,340},
	["毁灭红玉指环"] = {300,330,350,370},
	["毁灭者的黑暗之握"] = {300,320,330,340},
	["比兹尼克247x128精确瞄准镜"] = {300,320,330,340},
	["毛布卷"] = {75,90,97,105},
	["毛皮护甲片"] = {250,255,265,275},
	["毛纺包"] = {80,105,122,140},
	["毛纺斗篷"] = {75,100,117,135},
	["毛纺靴"] = {95,120,137,155},
	["水下呼吸药剂"] = {90,120,140,160},
	["水下诱鱼器"] = {150,150,160,170},
	["水手的陨落"] = {190,210,220,230},
	["水晶护腕"] = {280,285,297,310},
	["水晶火焰护腕"] = {255,275,285,295},
	["水晶耳环"] = {185,205,215,225},
	["水煮蚌肉"] = {50,90,110,130},
	["水煮阳鳞鲑鱼"] = {250,290,310,330},
	["水银环"] = {265,285,292,300},
	["沙漠肉丸子"] = {285,325,345,365},
	["沙行者护手"] = {300,320,330,340},
	["沙行者护腕"] = {300,320,330,340},
	["沙行者胸甲"] = {300,320,330,340},
	["油炸红腮鱼"] = {225,265,285,305},
	["治疗药水"] = {110,135,155,175},
	["法力药水"] = {160,180,200,220},
	["法拉基祭祀图腾"] = {140,160,170,180},
	["法术掌握手套"] = {300,315,330,345},
	["法术能量护目镜超级改良版"] = {270,290,300,310},
	["法术能量护目镜超级版"] = {225,245,255,265},
	["泛光月亮石胸针"] = {185,200,207,215},
	["泰坦之锤"] = {300,320,330,340},
	["泰坦合剂"] = {300,315,322,330},
	["泰坦护腿"] = {300,320,330,340},
	["洛丹伦胸甲"] = {100,275,295,310},
	["洛克湖狂鱼"] = {50,90,110,130},
	["洛恩塔姆薯块"] = {275,315,335,355},
	["洞察束带"] = {300,320,330,340},
	["活力行动药水"] = {285,300,320,340},
	["活动假人"] = {85,115,130,145},
	["流木鱼竿"] = {10,40,55,70},
	["海员香辣炖菜"] = {35,75,95,115},
	["海洋之心"] = {200,220,230,240},
	["海洋之怒"] = {115,120,130,140},
	["海洋之根"] = {200,215,225,235},
	["海龟汤"] = {175,215,235,255},
	["淡黄色衬衣"] = {135,145,150,155},
	["深沉白玉"] = {270,270,272,275},
	["深海护手"] = {230,250,260,270},
	["深海的凝视"] = {190,190,210,230},
	["深海项链"] = {85,105,115,125},
	["深红丝质外衣"] = {185,205,215,225},
	["深红丝质手套"] = {210,225,240,255},
	["深红丝质护肩"] = {190,210,225,240},
	["深红丝质披风"] = {180,200,215,230},
	["深红丝质腰带"] = {175,195,210,225},
	["深红丝质长袍"] = {205,220,235,250},
	["深红丝质马裤"] = {195,215,225,235},
	["深红护卫法杖"] = {nil,290,300,310},
	["清洁布"] = {180,200,210,220},
	["清醒药水"] = {300,315,322,330},
	["渴魔手套"] = {75,150,167,185},
	["溶解毒药"] = {1,285,310,335},
	["溶解毒药 II"] = {1,325,350,375},
	["滋补药剂"] = {210,225,245,265},
	["滑皮鲭鱼"] = {1,45,65,85},
	["漂亮的红衬衣"] = {110,135,152,170},
	["漂亮的绿衬衣"] = {120,145,162,180},
	["漂亮的蓝衬衣"] = {120,145,162,180},
	["漆黑曜石"] = {285,290,292,295},
	["潜水头盔"] = {230,250,260,270},
	["激发潜能之戒"] = {290,320,330,340},
	["灌注精华手套"] = {300,300,305,310},
	["火力药剂"] = {140,165,185,205},
	["火山战锤"] = {290,315,327,340},
	["火山护肩"] = {300,320,330,340},
	["火山护腿"] = {270,290,300,310},
	["火山胸甲"] = {285,305,315,325},
	["火怒护腿"] = {300,300,300,300},
	["火核狙击步枪"] = {300,320,330,340},
	["火焰之油"] = {130,150,160,170},
	["火焰偏斜器"] = {125,125,150,175},
	["火焰勋章"] = {110,130,140,150},
	["火焰头盔"] = {250,270,280,290},
	["火焰护目镜"] = {205,225,235,245},
	["火焰披风"] = {275,290,305,320},
	["火焰防护药水"] = {165,210,230,250},
	["火链胸甲"] = {300,325,337,350},
	["灰布外衣"] = {260,275,290,305},
	["灰布手套"] = {270,285,300,315},
	["灰布披风"] = {275,290,305,320},
	["灰布短裤"] = {280,295,310,325},
	["灰布长袍"] = {225,240,255,270},
	["灰布长靴"] = {245,260,275,290},
	["灰烬堕落戒指"] = {260,280,290,300},
	["灰烬宝石护腕"] = {300,320,330,340},
	["灰烬石神像"] = {220,240,250,260},
	["灰烬石镶嵌指环"] = {225,240,247,255},
	["灰色毛纺衬衣"] = {100,110,120,130},
	["灰色毛纺长袍"] = {105,130,147,165},
	["灵魂袋"] = {260,275,290,305},
	["灼热金剑"] = {190,215,227,240},
	["炖陆行鸟"] = {50,90,110,130},
	["炖龙虾"] = {275,315,335,355},
	["炫光头盔"] = {300,320,330,340},
	["炫光护腿"] = {300,320,330,340},
	["炫光肩铠"] = {300,320,330,340},
	["炫光胸甲"] = {300,320,330,340},
	["炸弹宠物"] = {205,205,205,205},
	["点铁成金"] = {225,240,260,280},
	["炼金石"] = {300,315,322,330},
	["炽热板甲护手"] = {290,310,320,330},
	["炽热红宝石"] = {200,205,207,210},
	["炽热链甲护肩"] = {300,320,330,340},
	["炽热链甲束带"] = {295,315,325,335},
	["烈性火药"] = {125,125,135,145},
	["烈性炸药"] = {125,125,135,145},
	["烈日黄玉戒指"] = {185,200,210,220},
	["烈焰核心靴子"] = {300,300,300,300},
	["烟熏胸针"] = {200,220,230,240},
	["烟熏鲈鱼"] = {240,280,300,320},
	["烟花发射器"] = {225,245,255,265},
	["烟花束发射器"] = {275,295,305,315},
	["烤狮排"] = {125,175,195,215},
	["烤科多肉"] = {35,75,95,115},
	["烤迅猛龙肉"] = {175,215,235,255},
	["烤野猪肉"] = {1,45,65,85},
	["烤鱿鱼"] = {240,280,300,320},
	["烤鲑鱼"] = {275,315,335,355},
	["烤鼠尾鱼"] = {80,120,140,160},
	["烧烤巨蚌"] = {175,215,235,255},
	["烧烤狼肉"] = {1,45,65,85},
	["烧烤秃鹰翅膀"] = {175,215,235,255},
	["热狼排"] = {175,215,235,255},
	["煮熟的光滑大鱼"] = {225,265,285,305},
	["煮蟹爪"] = {85,125,145,165},
	["熏熊肉"] = {40,80,100,120},
	["熔岩护腿"] = {300,300,300,300},
	["熔岩犬皮靴"] = {295,315,325,335},
	["熔岩腰带"] = {300,320,330,340},
	["熔火升华之冠"] = {300,320,330,340},
	["熔火恶魔布包"] = {300,315,330,345},
	["熔火护甲片"] = {300,320,330,340},
	["熔火犬皮腰带"] = {300,320,330,340},
	["熔火猎犬手套"] = {300,300,300,300},
	["熔火腰带"] = {300,320,330,340},
	["熔炼梦境钢锭"] = {300,350,362,375},
	["熔炼源质"] = {300,350,362,375},
	["熔炼瑟银"] = {250,250,250,250},
	["熔炼真银"] = {230,230,230,230},
	["熔炼秘银"] = {175,175,175,175},
	["熔炼金锭"] = {155,170,177,185},
	["熔炼钢锭"] = {165,165,165,165},
	["熔炼铁锭"] = {125,125,130,140},
	["熔炼铜锭"] = {1,25,45,70},
	["熔炼银锭"] = {75,100,112,125},
	["熔炼锡锭"] = {65,65,70,75},
	["熔炼青铜"] = {65,65,90,115},
	["熔炼黑铁"] = {230,230,230,230},
	["熔铸头盔"] = {300,320,330,340},
	["熟化中毛皮"] = {100,115,122,130},
	["熟化厚毛皮"] = {200,200,200,200},
	["熟化毛皮"] = {250,250,255,260},
	["熟化轻毛皮"] = {35,55,65,75},
	["熟化重毛皮"] = {150,160,165,170},
	["燃星宝石"] = {225,225,227,230},
	["爆炸护盾"] = {75,100,120,140},
	["牙爪圣物"] = {120,140,150,160},
	["特效巨魔之血药水"] = {290,305,325,345},
	["特效抗毒药剂"] = {300,300,330,360},
	["特效治疗药水"] = {275,290,310,330},
	["特效法力药水"] = {295,310,330,350},
	["特效活力药水"] = {300,310,320,330},
	["牺牲长袍"] = {300,300,300,300},
	["狂鱼肉片"] = {50,90,110,130},
	["狙击瞄准镜"] = {240,260,270,280},
	["狮心头盔"] = {300,320,330,340},
	["狮王之力药剂"] = {1,55,75,95},
	["狼头之盔"] = {225,245,255,265},
	["猛毒尖冠"] = {145,165,175,185},
	["猝火艾泽拉斯钻石"] = {275,280,282,285},
	["猪肉干"] = {80,120,140,160},
	["猪肝馅饼"] = {50,90,110,130},
	["猫眼药剂"] = {200,220,240,260},
	["猫眼超级护目镜"] = {220,240,250,260},
	["猫鼬药剂"] = {280,295,315,335},
	["猫鼬长靴"] = {300,320,330,340},
	["献祭之油"] = {205,220,240,260},
	["玉蛇刀"] = {175,200,212,225},
	["王之决断"] = {85,105,115,125},
	["玛瑙头冠"] = {125,145,155,165},
	["玫瑰色护目镜"] = {230,250,260,270},
	["珍珠匕首"] = {110,140,155,170},
	["珍珠披风"] = {90,115,132,150},
	["琥珀宝珠"] = {95,110,120,130},
	["琥珀指环"] = {60,80,87,95},
	["琥珀石吊坠"] = {80,105,115,125},
	["瑟银头盔"] = {280,300,310,320},
	["瑟银巨剑"] = {260,285,297,310},
	["瑟银带扣"] = {240,265,277,290},
	["瑟银弹"] = {285,305,315,325},
	["瑟银手榴弹"] = {260,280,290,300},
	["瑟银护甲"] = {250,270,280,290},
	["瑟银护腕"] = {255,275,285,295},
	["瑟银护腿"] = {300,320,330,340},
	["瑟银火枪"] = {260,280,290,300},
	["瑟银盾刺"] = {275,295,305,315},
	["瑟银管"] = {275,295,305,315},
	["瑟银腰带"] = {250,270,280,290},
	["瑟银长靴"] = {280,300,310,320},
	["瑟银零件"] = {260,280,290,300},
	["瑟银马刺"] = {275,300,310,320},
	["璀璨玛瑙"] = {135,135,137,140},
	["生命护肩"] = {270,290,300,310},
	["生命护腿"] = {285,305,315,325},
	["生命胸甲"] = {300,320,330,340},
	["生存剥皮刀"] = {10,30,45,60},
	["电动惩戒器"] = {250,270,280,290},
	["电压中和自然反射器"] = {290,310,320,330},
	["瘦狼排"] = {125,165,185,205},
	["瘦鹿肉"] = {110,150,170,190},
	["白玉手镯"] = {250,280,290,300},
	["白玉指环"] = {290,320,330,340},
	["白色亚麻衬衣"] = {1,35,47,60},
	["白色亚麻长袍"] = {30,55,72,90},
	["白色冒险者衬衣"] = {160,170,175,180},
	["白色婚纱"] = {250,255,260,265},
	["白色强盗面罩"] = {215,220,225,230},
	["白色毛绒裙"] = {110,135,152,170},
	["白色皮夹克"] = {60,90,105,120},
	["白银万能钥匙"] = {100,100,110,120},
	["白魂头盔"] = {300,320,330,340},
	["皇家宝石法杖"] = {215,235,245,255},
	["皇家曙光权杖"] = {240,260,275,290},
	["皮质小弹药包"] = {30,60,75,90},
	["皱褶皮短裤"] = {35,65,80,95},
	["盖亚的拥抱"] = {300,315,330,345},
	["真银万能钥匙"] = {200,200,210,220},
	["真银变压器"] = {260,270,275,280},
	["真银圣剑"] = {260,285,297,310},
	["真银带扣"] = {225,225,230,235},
	["真银护手"] = {225,245,255,265},
	["真银棒"] = {200,205,207,210},
	["真银胸甲"] = {245,265,275,285},
	["石之护符"] = {100,125,135,145},
	["石英指环"] = {155,175,185,195},
	["石鳞鱼油"] = {250,250,255,260},
	["石鳞鳕鱼"] = {175,190,210,230},
	["破冰护手"] = {300,320,330,340},
	["破冰护腕"] = {300,320,330,340},
	["破冰胸甲"] = {300,320,330,340},
	["破碎守护者的护符"] = {300,320,325,330},
	["硬化蝎壳头盔"] = {250,270,280,290},
	["硬化蝎壳战靴"] = {235,255,265,275},
	["硬化蝎壳手套"] = {225,245,255,265},
	["硬化蝎壳护肩"] = {240,260,270,280},
	["硬化蝎壳护腕"] = {220,240,250,260},
	["硬化蝎壳护腿"] = {245,265,275,285},
	["硬化蝎壳胸甲"] = {220,240,250,260},
	["硬化铜手镯"] = {50,70,75,80},
	["硬化青铜法杖"] = {100,120,130,140},
	["硬甲皮"] = {250,250,250,250},
	["硬铁短剑"] = {160,185,197,210},
	["碎裂黑曜石盾牌"] = {300,320,330,340},
	["碎铁金锤"] = {170,195,207,220},
	["碧蓝丝质外衣"] = {150,170,185,200},
	["碧蓝丝质头巾"] = {145,155,160,165},
	["碧蓝丝质手套"] = {145,165,180,195},
	["碧蓝丝质披风"] = {175,195,210,225},
	["碧蓝丝质短裤"] = {140,160,175,190},
	["碧蓝丝质腰带"] = {175,195,210,225},
	["碧蓝戒指"] = {60,80,87,95},
	["碧蓝护肩"] = {190,210,225,240},
	["礼服夹克"] = {250,265,280,295},
	["礼服短裤"] = {245,250,255,260},
	["礼服衬衣"] = {240,245,250,255},
	["神圣防护药水"] = {100,130,150,170},
	["神秘杂烩"] = {175,215,235,255},
	["禁锢徽记"] = {125,145,155,165},
	["科多兽皮包"] = {40,70,85,100},
	["科多肉杂烩"] = {200,240,260,280},
	["秘银外壳"] = {215,215,235,255},
	["秘银带扣"] = {185,210,222,235},
	["秘银机械幼龙"] = {250,270,280,290},
	["秘银杆"] = {200,225,237,250},
	["秘银杆设计图"] = {205,205,205,205},
	["秘银火枪"] = {205,225,235,245},
	["秘银盾刺"] = {215,235,245,255},
	["秘银短裤"] = {210,230,240,250},
	["秘银破片炸弹"] = {215,215,235,255},
	["秘银符文战锤"] = {245,270,282,295},
	["秘银管"] = {195,195,215,235},
	["秘银细剑"] = {240,265,277,290},
	["秘银罩帽"] = {230,250,260,270},
	["秘银螺旋弹"] = {245,245,265,285},
	["秘银重斧"] = {210,235,247,260},
	["秘银重靴"] = {235,255,265,275},
	["秘银马刺"] = {235,255,265,275},
	["秘银魔剑"] = {225,250,262,275},
	["秘银鳞片手套"] = {220,240,250,260},
	["秘银鳞片护肩"] = {235,255,265,275},
	["秘银鳞片护腕"] = {215,235,245,255},
	["秘银鳞片短裤"] = {210,230,240,250},
	["秘银黑石项链"] = {245,265,275,285},
	["移形披风"] = {300,320,330,340},
	["究极充能奥术反射器"] = {290,310,320,330},
	["空间撕裂器 - 永望镇"] = {260,285,295,305},
	["窃贼手套"] = {140,165,177,190},
	["符文之刃"] = {285,310,322,335},
	["符文冥河护腿"] = {300,315,330,345},
	["符文冥河腰带"] = {300,315,330,345},
	["符文冥河长靴"] = {300,315,330,345},
	["符文布卷"] = {250,255,257,260},
	["符文布外套"] = {260,275,290,305},
	["符文布头带"] = {295,310,325,340},
	["符文布手套"] = {275,290,305,320},
	["符文布护肩"] = {300,315,330,345},
	["符文布披风"] = {265,280,295,310},
	["符文布短裤"] = {285,300,315,330},
	["符文布绷带"] = {260,260,290,320},
	["符文布背包"] = {260,275,290,305},
	["符文布腰带"] = {255,270,285,300},
	["符文布袍"] = {260,275,290,305},
	["符文布靴"] = {280,295,310,325},
	["符文护符"] = {230,230,252,275},
	["符文板甲"] = {300,320,330,340},
	["符文板甲头盔"] = {300,320,330,340},
	["符文板甲战靴"] = {300,320,330,340},
	["符文板甲护肩"] = {300,320,330,340},
	["符文板甲护腿"] = {300,320,330,340},
	["符文皮甲"] = {300,320,330,340},
	["符文皮甲头环"] = {290,310,320,330},
	["符文皮甲护手"] = {270,290,300,310},
	["符文皮甲护肩"] = {300,320,330,340},
	["符文皮甲护腕"] = {275,295,305,315},
	["符文皮甲短裤"] = {300,320,330,340},
	["符文皮甲腰带"] = {280,300,310,320},
	["符文真银戒指"] = {220,240,250,260},
	["符文蚀刻之握"] = {300,320,330,340},
	["符文蚀刻护肩"] = {300,320,330,340},
	["符文蚀刻王冠"] = {300,320,330,340},
	["符文蚀刻胫甲"] = {300,320,330,340},
	["符文蚀刻胸甲"] = {300,320,330,340},
	["符文蚀刻腿甲"] = {300,320,330,340},
	["笨重的铜戒指"] = {25,25,45,65},
	["筛盐器"] = {250,270,280,290},
	["简易亚麻短裤"] = {1,35,47,60},
	["简易弹弓"] = {30,50,60,70},
	["简易投掷炸弹"] = {100,115,122,130},
	["简易投掷炸弹II"] = {200,200,210,220},
	["简易的亚麻靴"] = {20,50,67,85},
	["简易的木制花盆"] = {75,100,112,125},
	["简易的裙子"] = {40,65,82,100},
	["简易的褶裙"] = {75,100,117,135},
	["简易的黑裙子"] = {235,240,245,250},
	["简易草药袋"] = {40,60,70,80},
	["粉碎者"] = {235,260,272,285},
	["粉色魔纹衬衣"] = {235,240,245,250},
	["粗制平衡石"] = {65,65,72,80},
	["粗制火药粉"] = {75,85,90,95},
	["粗制炸药"] = {75,90,97,105},
	["粗制瞄准镜"] = {60,90,105,120},
	["粗制砂轮"] = {75,75,87,100},
	["粗制磨刀石"] = {65,65,72,80},
	["粗糙手斧"] = {15,25,35,45},
	["粗糙猎弓"] = {15,25,35,45},
	["粗糙的宝石串"] = {125,140,142,145},
	["粗糙的金戒指"] = {150,165,170,175},
	["粗糙的铁戒指"] = {150,165,170,175},
	["粗糙短杖"] = {15,25,35,45},
	["粗糙砂纸"] = {70,90,95,100},
	["粗糙砍刀"] = {15,25,35,45},
	["粗糙青铜戒指"] = {90,100,107,115},
	["粗野的聚焦手杖"] = {300,330,340,350},
	["精制实心弹丸"] = {125,125,135,145},
	["精制望远镜"] = {135,160,172,185},
	["精制秘银头盔"] = {210,265,275,285},
	["精制秘银战靴"] = {210,265,275,285},
	["精制秘银手套"] = {220,240,250,260},
	["精制秘银护肩"] = {225,245,255,265},
	["精制秘银短裤"] = {220,240,250,260},
	["精制秘银胸甲"] = {210,260,270,280},
	["精制轻弹丸"] = {1,30,45,60},
	["精制重弹丸"] = {75,85,90,95},
	["精制钻石手镯"] = {300,325,332,340},
	["精密奥金转换器"] = {285,305,315,325},
	["精密珠宝工具包"] = {175,185,190,195},
	["精密陀螺仪护目镜"] = {300,320,330,340},
	["精工风暴战锤"] = {300,320,330,340},
	["精炼智慧合剂"] = {300,315,322,330},
	["精确瞄准镜"] = {180,200,210,220},
	["精致手工火枪"] = {120,145,157,170},
	["精致的宝石串"] = {200,200,205,210},
	["精致的矮人项链"] = {185,185,200,215},
	["精致的金手镯"] = {200,220,230,240},
	["精致秘银头冠"] = {210,230,240,250},
	["精致秘银护符"] = {180,200,210,220},
	["精致钻石宝冠"] = {300,320,330,340},
	["精钢战靴"] = {185,210,222,235},
	["紫色丝质衬衣"] = {185,195,200,205},
	["紫色魔纹衬衣"] = {230,235,240,245},
	["红色亚麻包"] = {70,95,112,130},
	["红色亚麻外衣"] = {55,80,97,115},
	["红色亚麻衬衣"] = {40,65,82,100},
	["红色亚麻长袍"] = {40,65,82,100},
	["红色冒险者衬衣"] = {175,185,190,195},
	["红色毛纺包"] = {115,140,157,175},
	["红色毛纺靴"] = {95,120,137,155},
	["红色烟花束"] = {225,225,237,250},
	["红色焰火"] = {150,150,162,175},
	["红色节庆裤装"] = {250,265,280,295},
	["红色雏龙手套"] = {120,145,157,170},
	["红色魔纹包"] = {235,250,265,280},
	["红色魔纹外衣"] = {215,230,245,260},
	["红色魔纹头带"] = {240,255,270,285},
	["红色魔纹手套"] = {225,240,255,270},
	["红色魔纹护肩"] = {235,250,265,280},
	["红色魔纹短裤"] = {215,230,245,260},
	["红龙鳞片护肩"] = {300,300,300,300},
	["红龙鳞片护腿"] = {295,300,300,300},
	["红龙鳞片胸甲"] = {300,320,330,340},
	["红龙鳞片长靴"] = {295,300,300,300},
	["纯金戒指"] = {nil,325,335,345},
	["纯银戒指"] = {135,155,165,175},
	["练习锁"] = {100,115,122,130},
	["织法者之杖"] = {265,285,292,300},
	["织法者坠饰"] = {265,275,285,295},
	["绒线绷带"] = {80,80,115,150},
	["结实的铁锤"] = {155,180,192,205},
	["绚丽宝钻"] = {270,275,277,280},
	["绽放翡翠之杖"] = {165,185,195,205},
	["绿色丝甲"] = {165,185,200,215},
	["绿色丝质包"] = {175,195,210,225},
	["绿色丝质护肩"] = {180,200,215,230},
	["绿色亚麻护腕"] = {60,85,102,120},
	["绿色亚麻衬衣"] = {70,95,112,130},
	["绿色幼龙护甲"] = {175,195,205,215},
	["绿色幼龙护腕"] = {190,210,220,230},
	["绿色护目镜"] = {150,175,187,200},
	["绿色毛纺包"] = {95,120,137,155},
	["绿色毛纺外衣"] = {85,110,127,145},
	["绿色烟花束"] = {225,225,237,250},
	["绿色焰火"] = {150,150,162,175},
	["绿色皮带"] = {160,180,190,200},
	["绿色皮护腕"] = {180,200,210,220},
	["绿色皮甲"] = {155,175,185,195},
	["绿色节日衬衣"] = {190,200,205,210},
	["绿色透镜"] = {245,265,275,285},
	["绿色龙鳞护手"] = {280,300,310,320},
	["绿铁头盔"] = {170,195,207,220},
	["绿铁战靴"] = {145,175,190,205},
	["绿铁护手"] = {150,180,195,210},
	["绿铁护肩"] = {160,185,197,210},
	["绿铁护腕"] = {165,190,202,215},
	["绿铁护腿"] = {155,180,192,205},
	["绿铁锁甲"] = {180,205,217,230},
	["绿龙鳞片护腿"] = {270,290,300,310},
	["绿龙鳞片胸甲"] = {260,280,290,300},
	["缀玉戒指"] = {70,90,95,100},
	["缚风者手套"] = {300,315,330,345},
	["缥缈的霜花皇冠"] = {280,285,297,310},
	["美味小鱼"] = {1,45,65,85},
	["美味煎蛋卷"] = {130,170,190,210},
	["美味风蛇"] = {85,125,145,165},
	["美味鼠尾鱼"] = {175,215,235,255},
	["羽饰胸甲"] = {250,270,280,290},
	["翡翠和谐指环"] = {170,190,197,205},
	["翡翠帝王石"] = {300,320,330,340},
	["翡翠梦境者护胸"] = {300,300,300,300},
	["翼爪戒指"] = {145,165,175,185},
	["联合收割机组件"] = {175,175,195,215},
	["脆炸蜥蜴尾"] = {100,140,160,180},
	["腐肉大餐"] = {175,215,235,255},
	["腐蚀术"] = {290,315,327,340},
	["腐蚀毒药"] = {1,280,305,330},
	["腐蚀毒药 II"] = {1,300,325,350},
	["自动净化装置"] = {140,165,177,190},
	["自然防护药水"] = {190,210,230,250},
	["自爆绵羊"] = {150,175,187,200},
	["自由行动药剂"] = {150,175,195,215},
	["致伤毒药"] = {1,185,210,235},
	["致命毒药"] = {130,175,200,225},
	["致命毒药 II"] = {170,215,240,265},
	["致命毒药 III"] = {210,255,280,305},
	["致命毒药 IV"] = {250,295,320,345},
	["致命毒药 V"] = {1,300,325,350},
	["致命的短枪"] = {105,130,142,155},
	["致命的青铜短剑"] = {125,155,170,185},
	["致命瞄准镜"] = {210,230,240,250},
	["致密平衡石"] = {250,255,257,260},
	["致密炸药"] = {250,250,260,270},
	["致密炸药粉"] = {250,250,255,260},
	["致密的宝石串"] = {235,240,240,240},
	["致密砂纸"] = {250,260,265,270},
	["致密砂轮"] = {250,255,257,260},
	["致密磨刀石"] = {250,255,257,260},
	["致残毒药"] = {1,125,150,175},
	["致残毒药 II"] = {230,275,300,325},
	["致盲粉"] = {1,170,195,220},
	["舒适的皮帽"] = {200,220,230,240},
	["艾泽拉斯红玉"] = {275,280,282,285},
	["苏生黄玉"] = {300,320,330,340},
	["荆木头盔"] = {300,320,330,340},
	["荆木腰带"] = {300,320,330,340},
	["荆木长靴"] = {300,320,330,340},
	["草药烘蛋"] = {1,45,65,85},
	["荒芜"] = {250,275,287,300},
	["菊花茶"] = {60,100,120,140},
	["萨弗隆战锤"] = {300,325,337,350},
	["蓝光斧"] = {220,245,257,270},
	["蓝玉指环"] = {290,320,330,340},
	["蓝色亚麻外衣"] = {55,80,97,115},
	["蓝色亚麻衬衣"] = {40,65,82,100},
	["蓝色亚麻长袍"] = {70,95,112,130},
	["蓝色烟花束"] = {225,225,237,250},
	["蓝色焰火"] = {150,150,162,175},
	["蓝色罩衫"] = {100,125,142,160},
	["蓝色龙鳞长靴"] = {290,310,320,330},
	["蓝龙鳞片护肩"] = {295,315,325,335},
	["蓝龙鳞片护腿"] = {300,320,330,340},
	["蓝龙鳞片胸甲"] = {285,305,315,325},
	["虎纹戒指"] = {50,70,77,85},
	["虚灵外套"] = {300,300,300,300},
	["虚灵头饰"] = {300,300,300,300},
	["虚灵护肩"] = {300,300,300,300},
	["虚灵护腿"] = {300,300,300,300},
	["虚空之心咒符"] = {280,280,300,320},
	["虚空法袍"] = {300,315,330,345},
	["蛇盘之杖"] = {100,120,130,140},
	["蛇鳞手套"] = {105,130,142,155},
	["蛇鳞披风"] = {90,120,135,150},
	["蛇鳞腰带"] = {115,140,152,165},
	["蛋奶酒"] = {35,75,95,115},
	["蛛丝之靴"] = {125,150,167,185},
	["蛛丝便鞋"] = {140,160,175,190},
	["蛮力药剂"] = {275,290,310,330},
	["蛮皮外衣"] = {225,245,255,265},
	["蛮皮头盔"] = {225,245,255,265},
	["蛮皮战靴"] = {245,265,275,285},
	["蛮皮护肩"] = {220,240,250,260},
	["蛮皮护腿"] = {250,270,280,290},
	["蛮皮披风"] = {250,270,280,290},
	["蜘蛛肉肠"] = {200,240,260,280},
	["蜘蛛腰带"] = {180,200,215,230},
	["蜘蛛蛋糕"] = {110,150,170,190},
	["蜜汁烤猪排"] = {175,215,235,255},
	["蝎肉大餐"] = {20,60,80,100},
	["蟹肉蛋糕"] = {75,115,135,155},
	["血火头饰"] = {200,220,230,240},
	["血爪"] = {300,320,330,340},
	["血石战刃"] = {225,260,267,275},
	["血肠"] = {60,100,120,140},
	["血腥带扣"] = {300,325,337,350},
	["血藤外套"] = {300,315,330,345},
	["血藤护目镜"] = {300,320,330,340},
	["血藤护腿"] = {300,315,330,345},
	["血藤透镜"] = {300,320,330,340},
	["血藤长靴"] = {300,315,330,345},
	["血虎护肩"] = {300,320,330,340},
	["血虎胸甲"] = {300,320,330,340},
	["血魂护手"] = {300,320,330,340},
	["血魂护肩"] = {300,320,330,340},
	["血魂胸甲"] = {300,320,330,340},
	["要塞护手"] = {300,320,330,340},
	["解谜手套"] = {300,300,300,300},
	["设计图：金带扣"] = {175,175,180,185},
	["语音增强模组"] = {290,310,320,330},
	["说服者"] = {300,320,330,340},
	["赤脊山炖肉"] = {100,135,155,175},
	["超凡护腿"] = {300,320,330,340},
	["超凡罩帽"] = {300,320,330,340},
	["超凡肩甲"] = {300,320,330,340},
	["超凡胸甲"] = {300,320,330,340},
	["超强巨魔之血药水"] = {180,200,220,240},
	["超强防御药剂"] = {265,280,300,320},
	["超级煎蛋卷"] = {225,265,285,305},
	["超级能量合剂"] = {300,315,322,330},
	["超能电池组"] = {250,250,260,270},
	["转化秘银"] = {225,240,260,280},
	["转化：元素之土"] = {300,315,322,330},
	["转化：元素之水"] = {300,315,322,330},
	["转化：元素火焰"] = {300,301,305,310},
	["转化：土转生命"] = {275,275,282,290},
	["转化：奥金"] = {275,275,282,290},
	["转化：死灵化水"] = {275,275,282,290},
	["转化：水转死灵"] = {275,275,282,290},
	["转化：点气成火"] = {275,275,282,290},
	["转化：点水成气"] = {275,275,282,290},
	["转化：点火成土"] = {275,275,282,290},
	["转化：生命归土"] = {275,275,282,290},
	["转化：转土成水"] = {275,275,282,290},
	["软底亚麻靴"] = {80,105,122,140},
	["轻型护甲片"] = {1,30,45,60},
	["轻型黑曜石腰带"] = {300,320,330,340},
	["轻巧的皮手套"] = {120,145,157,170},
	["轻皮"] = {1,20,30,40},
	["轻皮护腕"] = {70,100,115,130},
	["轻皮短裤"] = {95,125,140,155},
	["轻皮箭袋"] = {30,60,75,90},
	["辉光蓝宝石"] = {nil,290,292,295},
	["辉煌女王的皇冠"] = {300,320,330,340},
	["辉煌蓝宝石"] = {nil,250,252,255},
	["辐光头饰"] = {295,315,325,335},
	["辐光手套"] = {285,305,315,325},
	["辐光护腿"] = {300,320,330,340},
	["辐光胸甲"] = {270,290,300,310},
	["辐光腰带"] = {260,280,290,300},
	["辐光长靴"] = {290,310,320,330},
	["辛德拉长老的高贵法杖"] = {300,330,350,370},
	["辣椒蟹肉"] = {225,265,285,305},
	["达农佐的泰拉比姆情调"] = {300,300,300,300},
	["达农佐的泰拉比姆惊喜"] = {300,300,300,300},
	["达农佐的泰拉比姆趣味"] = {300,300,300,300},
	["迅捷之靴"] = {200,220,230,240},
	["迅捷药水"] = {60,90,110,130},
	["迅猛龙皮背心"] = {165,185,195,205},
	["迅猛龙皮腰带"] = {165,185,195,205},
	["迅行护腕"] = {300,320,330,340},
	["迪尔格的超美味奇美拉肉片"] = {300,325,345,365},
	["迫击炮：重载"] = {205,205,205,205},
	["迷人的黄玉项链"] = {200,220,230,240},
	["退化射线"] = {160,180,190,200},
	["透明治疗药水"] = {50,80,100,120},
	["速效毒药"] = {1,125,150,175},
	["速效毒药 II"] = {120,165,190,215},
	["速效毒药 III"] = {160,205,230,255},
	["速效毒药 IV"] = {200,245,270,295},
	["速效毒药 V"] = {240,285,340,335},
	["速效毒药 VI"] = {280,325,350,375},
	["速游药水"] = {100,130,150,170},
	["造弓师手套"] = {125,150,162,175},
	["邪恶皮甲"] = {300,320,330,340},
	["邪恶皮甲头环"] = {280,300,310,320},
	["邪恶皮甲护手"] = {260,280,290,300},
	["邪恶皮甲护腕"] = {265,285,295,305},
	["邪恶皮甲短裤"] = {290,310,320,330},
	["邪恶皮甲腰带"] = {300,320,330,340},
	["采药人手套"] = {135,160,172,185},
	["重型土灵手套"] = {145,170,182,195},
	["重型护甲片"] = {150,170,180,190},
	["重型木喉腰带"] = {290,310,320,330},
	["重型木喉长靴"] = {300,320,330,340},
	["重型秘银头盔"] = {245,255,265,275},
	["重型秘银手套"] = {205,225,235,245},
	["重型秘银护肩"] = {205,225,235,245},
	["重型秘银胸甲"] = {230,250,260,270},
	["重型箭袋"] = {150,170,180,190},
	["重型蝎壳外衣"] = {265,285,295,305},
	["重型蝎壳头盔"] = {295,315,325,335},
	["重型蝎壳护手"] = {275,295,305,315},
	["重型蝎壳护肩"] = {300,320,330,340},
	["重型蝎壳护腕"] = {255,275,285,295},
	["重型蝎壳护腿"] = {285,305,315,325},
	["重型蝎壳腰带"] = {280,300,310,320},
	["重型黑曜石腰带"] = {300,320,330,340},
	["重平衡石"] = {125,125,132,140},
	["重皮"] = {150,150,155,160},
	["重皮弹药包"] = {150,170,180,190},
	["重皮球"] = {150,150,155,160},
	["重砂轮"] = {125,125,137,150},
	["重磅铁制炸弹"] = {190,190,210,230},
	["重磅青铜炸弹"] = {140,140,165,190},
	["重磨刀石"] = {125,125,132,140},
	["野人亚麻外衣"] = {70,95,112,130},
	["野人手套"] = {150,170,180,190},
	["野人护肩"] = {175,195,205,215},
	["野人护腕"] = {155,175,185,195},
	["野人护腿"] = {170,190,200,210},
	["野人背心"] = {190,210,220,230},
	["野人腰带"] = {200,220,230,240},
	["野人铁手套"] = {185,210,222,235},
	["野人铁护肩"] = {160,185,197,210},
	["野人铁盔"] = {175,200,212,225},
	["野人铁质胸甲"] = {160,185,197,210},
	["野人铁靴"] = {180,205,217,230},
	["野刺锁甲"] = {270,290,300,310},
	["野性之皮"] = {300,320,330,340},
	["野葡萄药水"] = {225,240,260,280},
	["野蛮狂怒"] = {300,320,330,340},
	["金棒"] = {150,155,157,160},
	["金棘茶"] = {175,175,190,205},
	["金焰水晶手镯"] = {155,155,160,165},
	["金玉戒指"] = {210,235,245,255},
	["金色徽记护符"] = {170,180,190,200},
	["金色黎明衬肩"] = {300,320,330,340},
	["金鳞战靴"] = {200,225,237,250},
	["金鳞护手"] = {205,225,235,245},
	["金鳞护肩"] = {175,200,212,225},
	["金鳞护腕"] = {185,210,222,235},
	["金鳞护腿"] = {170,195,207,220},
	["金鳞罩盔"] = {190,215,227,240},
	["金鳞胸甲"] = {195,220,232,245},
	["钢带扣"] = {200,195,200,205},
	["钢质头盔"] = {215,235,245,255},
	["钢质武器链"] = {190,215,227,240},
	["钢质胸甲"] = {200,225,237,250},
	["钢铁板甲头盔"] = {230,230,230,230},
	["钢铁板甲护手"] = {220,220,220,220},
	["钢铁板甲护肩"] = {230,230,230,230},
	["钢铁板甲护腿"] = {225,225,225,225},
	["钢铁板甲胸甲"] = {225,225,225,225},
	["钢铁板甲长靴"] = {220,220,220,220},
	["铁带扣"] = {140,170,185,200},
	["铁棒"] = {160,160,170,180},
	["铁炉堡胸甲"] = {100,140,160,180},
	["铁炉堡链甲"] = {70,110,130,150},
	["铁皮手雷"] = {175,175,195,215},
	["铁羽护肩"] = {270,290,300,310},
	["铁羽胸甲"] = {290,310,320,330},
	["铁花戒指"] = {190,205,215,225},
	["铁藤手套"] = {300,320,330,340},
	["铁藤胸甲"] = {300,320,330,340},
	["铁藤腰带"] = {300,320,330,340},
	["铁质平衡锤"] = {165,190,202,215},
	["铁质灯笼"] = {160,180,190,200},
	["铁质盾刺"] = {150,180,195,210},
	["铜制灯笼"] = {20,40,50,60},
	["铜带扣"] = {25,65,85,105},
	["铜手镯"] = {1,21,33,45},
	["铜指虎"] = {30,60,62,65},
	["铜斧"] = {20,60,80,100},
	["铜杖"] = {45,60,67,75},
	["铜管"] = {50,80,95,110},
	["铜质匕首"] = {30,70,90,110},
	["铜质双刃刀"] = {30,70,90,110},
	["铜质大锤"] = {65,105,125,145},
	["铜质宝石手套"] = {60,100,120,140},
	["铜质战斧"] = {35,75,95,115},
	["铜质护腕"] = {1,20,40,60},
	["铜质短剑"] = {25,65,85,105},
	["铜质符文护手"] = {40,80,100,120},
	["铜质符文护腕"] = {90,115,127,140},
	["铜质符文短裤"] = {45,85,105,125},
	["铜质符文胸甲"] = {80,120,140,160},
	["铜质符文腰带"] = {70,110,130,150},
	["铜质调节器"] = {65,95,110,125},
	["铜质重剑"] = {95,135,155,175},
	["铜质钉锤"] = {15,55,75,95},
	["铜质链甲外衣"] = {35,75,95,115},
	["铜质链甲战靴"] = {20,60,80,100},
	["铜质链甲短裤"] = {1,50,70,90},
	["铜质链甲腰带"] = {35,75,95,115},
	["铭文圣典"] = {260,280,287,295},
	["铭文板甲护腿"] = {300,320,330,340},
	["银头鲑鱼"] = {175,215,235,255},
	["银棒"] = {100,105,107,110},
	["银色护肩"] = {300,315,330,345},
	["银色长靴"] = {290,305,320,335},
	["银触媒"] = {90,110,125,140},
	["银质勋章"] = {135,150,160,170},
	["银鳞胸甲"] = {145,175,190,205},
	["锋利之爪"] = {75,90,95,100},
	["镀银猎枪"] = {130,155,167,180},
	["镀银青铜战靴"] = {130,160,175,190},
	["镀银青铜护手"] = {135,165,180,195},
	["镀银青铜护肩"] = {125,155,170,185},
	["镀银青铜护腿"] = {155,180,192,205},
	["镀银青铜胸甲"] = {130,160,175,190},
	["镶嵌宝石之戒"] = {300,330,350,370},
	["镶饰瑟银战锤"] = {270,295,307,320},
	["镶饰的铜戒指"] = {35,55,62,70},
	["长嘴泥鳅"] = {50,90,110,130},
	["长蛇焰火"] = {250,250,260,270},
	["闪亮护腕"] = {80,100,110,120},
	["闪亮月亮石板"] = {195,195,217,240},
	["闪亮水玉"] = {150,155,157,160},
	["闪亮青绿石戒指"] = {190,210,220,230},
	["闪亮青铜戒指"] = {90,105,112,120},
	["闪光的金项链"] = {190,205,215,225},
	["闪光的银项链"] = {135,155,165,175},
	["闪光雷"] = {185,185,205,225},
	["闪光项链"] = {80,100,110,120},
	["闪烁的钻戒"] = {300,320,330,340},
	["闪耀月亮石指环"] = {130,150,160,170},
	["闪耀白玉"] = {235,235,237,240},
	["闪耀轻剑"] = {280,305,317,330},
	["防御药剂"] = {130,155,175,195},
	["阿尔萨斯的礼物"] = {240,255,275,295},
	["附魔师长靴"] = {175,195,210,225},
	["降落伞披风"] = {225,245,255,265},
	["隐形药水"] = {235,250,270,290},
	["雕花皮外衣"] = {40,70,85,100},
	["雕花皮手套"] = {55,85,100,115},
	["雕花皮短裤"] = {75,105,120,135},
	["雕花皮质披风"] = {60,90,105,120},
	["雕花皮靴"] = {55,85,100,115},
	["雷云徽记"] = {290,310,320,330},
	["雷云护腕"] = {nil,310,320,330},
	["雷云魔印"] = {290,310,325,340},
	["雷暴"] = {285,305,315,325},
	["雷暴手套"] = {300,320,330,340},
	["雷暴护肩"] = {295,315,325,335},
	["雷暴短裤"] = {275,295,305,315},
	["雷织外衣"] = {225,240,255,270},
	["雷织头带"] = {240,255,270,285},
	["雷织手套"] = {220,235,250,265},
	["雷织护肩"] = {245,260,275,290},
	["雷织短裤"] = {220,235,250,265},
	["雷织长靴"] = {250,265,280,295},
	["雾林头冠"] = {105,135,145,155},
	["霜刃外套"] = {300,320,330,340},
	["霜刃手套"] = {295,315,325,335},
	["霜刃护腿"] = {285,305,315,325},
	["霜刃长靴"] = {275,295,305,315},
	["霜纹外套"] = {255,270,285,300},
	["霜纹手套"] = {265,280,295,310},
	["霜纹短裤"] = {280,295,310,325},
	["霜纹长袍"] = {255,270,285,300},
	["霜虎之刃"] = {200,225,237,250},
	["青绿石坠饰"] = {215,215,225,235},
	["青铜匕首"] = {105,135,150,165},
	["青铜巨剑"] = {130,160,175,190},
	["青铜带扣"] = {90,115,127,140},
	["青铜战斧"] = {135,165,180,195},
	["青铜战锤"] = {125,155,170,185},
	["青铜手镯"] = {105,120,132,145},
	["青铜斧"] = {115,145,160,175},
	["青铜权杖"] = {110,130,140,150},
	["青铜框架"] = {145,145,170,195},
	["青铜短剑"] = {120,150,165,180},
	["青铜管"] = {105,105,130,155},
	["青铜花纹护腕"] = {120,150,165,180},
	["青铜荣耀者"] = {120,140,145,150},
	["青铜重锤"] = {130,160,175,190},
	["青铜钉锤"] = {110,140,155,170},
	["韧化皮手套"] = {135,160,172,185},
	["韧化皮甲"] = {120,145,157,170},
	["预视之眼"] = {285,320,330,340},
	["预言家帽子"] = {205,205,205,205},
	["预言家手套"] = {200,200,200,200},
	["预言家护肩"] = {205,205,205,205},
	["预言家裤子"] = {205,205,205,205},
	["预言家长袍"] = {210,210,210,210},
	["预言家靴子"] = {200,200,200,200},
	["风之靴"] = {255,255,255,255},
	["风暴护手"] = {295,315,325,335},
	["风暴鳞片护腿"] = {300,300,300,300},
	["风行者之靴"] = {300,300,300,300},
	["飞火护手"] = {300,320,330,340},
	["飞火护腕"] = {300,320,330,340},
	["飞火胸甲"] = {300,320,330,340},
	["飞虎护目镜"] = {100,130,145,160},
	["食人魔力量药剂"] = {150,175,195,215},
	["食人魔白骨指环"] = {170,200,210,220},
	["首领头饰"] = {270,290,291,295},
	["首领护肩"] = {280,285,290,295},
	["首领短裤"] = {280,290,291,295},
	["首领长靴"] = {275,290,291,295},
	["首领马甲"] = {285,290,291,295},
	["香烤狮肉"] = {150,190,210,230},
	["香脆蝙蝠翅"] = {1,45,65,85},
	["香辣狼肉"] = {10,50,70,90},
	["骗子兜帽"] = {210,225,230,235},
	["骗子外衣"] = {210,235,240,245},
	["骗子手套"] = {200,215,220,225},
	["骗子护腿"] = {205,225,230,235},
	["骗子腰带"] = {200,215,220,225},
	["骗子靴子"] = {200,215,220,225},
	["高爆炸弹"] = {235,235,255,275},
	["高级亚麻手套"] = {35,60,77,95},
	["高级假人"] = {185,185,205,225},
	["高级技师护目镜"] = {290,310,320,330},
	["高级毛纺手套"] = {85,110,127,145},
	["高级毛纺披风"] = {100,125,142,160},
	["高级毛纺短裤"] = {110,135,152,170},
	["高级活动假人"] = {275,295,305,315},
	["高辐射烈焰反射器"] = {290,310,320,330},
	["高速秘银弹头"] = {210,210,230,250},
	["高速青铜齿轮"] = {125,125,150,175},
	["高雅之冠"] = {230,260,270,280},
	["鬼纹外衣"] = {275,290,305,320},
	["鬼纹手套"] = {270,285,300,315},
	["鬼纹短裤"] = {290,305,320,335},
	["鬼纹腰带"] = {265,280,295,310},
	["魔化战锤"] = {280,305,317,330},
	["魔化手镯"] = {125,145,155,165},
	["魔化护甲片"] = {300,320,330,340},
	["魔化瑟银头盔"] = {300,320,330,340},
	["魔化瑟银带扣"] = {285,285,297,310},
	["魔化瑟银护腿"] = {300,320,330,340},
	["魔化瑟银胸甲"] = {300,320,330,340},
	["魔化符文布包"] = {275,290,305,320},
	["魔化翡翠"] = {250,255,257,260},
	["魔化魔纹布包"] = {225,240,255,270},
	["魔导力量之杖"] = {300,325,335,345},
	["魔暴龙皮手套"] = {290,310,320,330},
	["魔暴龙皮护腿"] = {300,320,330,340},
	["魔法禁锢徽记"] = {230,260,275,290},
	["魔符雕刻护腕"] = {300,320,330,340},
	["魔纹包"] = {225,240,255,270},
	["魔纹布卷"] = {175,180,182,185},
	["魔纹绷带"] = {210,210,240,270},
	["魔网亲和披风"] = {300,300,300,300},
	["魔血药水"] = {275,290,310,330},
	["魔铸胸甲"] = {285,305,315,325},
	["鱼人脚蹼"] = {125,145,155,165},
	["鱼人鳍汤"] = {90,130,150,170},
	["鱼人鳞片护腕"] = {190,210,220,230},
	["鱼人鳞片胸甲"] = {95,125,140,155},
	["鱼人鳞片腰带"] = {90,120,135,150},
	["鳄鱼浓汤"] = {120,160,180,200},
	["鳄鱼炖肉"] = {150,160,180,200},
	["鳄鱼肉排"] = {80,120,140,160},
	["麻痹毒药"] = {1,150,175,200},
	["麻痹毒药 II"] = {1,215,240,265},
	["麻痹毒药 III"] = {1,285,310,335},
	["黄玉坠饰"] = {160,160,180,200},
	["黄金万能钥匙"] = {150,150,160,170},
	["黄金权杖"] = {nil,260,270,280},
	["黄金石英头冠"] = {175,195,202,210},
	["黄金符文戒指"] = {285,310,320,330},
	["黄金能量核心"] = {150,150,170,190},
	["黄金酒杯"] = {175,195,202,210},
	["黎明之刃"] = {275,300,312,325},
	["黎明使者护肩"] = {290,310,320,330},
	["黎明手套"] = {300,320,330,340},
	["黎明束腰"] = {290,310,320,330},
	["黎明皮靴"] = {290,310,320,330},
	["黎明石锤"] = {300,325,337,350},
	["黑丝衬衣"] = {155,165,170,175},
	["黑口鱼油"] = {80,80,90,100},
	["黑手"] = {300,320,330,340},
	["黑暗之手"] = {145,165,180,195},
	["黑暗之矛"] = {300,320,330,340},
	["黑暗之靴"] = {140,160,175,190},
	["黑暗之魂护肩"] = {300,320,330,340},
	["黑暗之魂护腿"] = {300,320,330,340},
	["黑暗之魂胸甲"] = {300,320,330,340},
	["黑暗符文头盔"] = {300,320,330,340},
	["黑暗符文护手"] = {300,320,330,340},
	["黑暗符文胸甲"] = {300,320,330,340},
	["黑曜石带扣"] = {300,300,310,320},
	["黑曜石胸针"] = {175,190,197,205},
	["黑曜石锁甲"] = {300,320,330,340},
	["黑皮外套"] = {100,125,137,150},
	["黑皮战靴"] = {100,125,137,150},
	["黑皮手套"] = {120,155,167,180},
	["黑皮护肩"] = {140,165,177,190},
	["黑皮披风"] = {110,135,147,160},
	["黑皮短裤"] = {115,140,152,165},
	["黑皮腰带"] = {125,150,162,175},
	["黑石铁夹"] = {140,160,170,180},
	["黑色丝质背包"] = {185,205,220,235},
	["黑色冒险者衬衣"] = {200,210,215,220},
	["黑色卫士"] = {300,320,330,340},
	["黑色怒火"] = {300,320,330,340},
	["黑色雏龙外衣"] = {100,125,137,150},
	["黑色雏龙披风"] = {100,125,137,150},
	["黑色魔纹之靴"] = {230,245,260,275},
	["黑色魔纹外衣"] = {205,220,235,250},
	["黑色魔纹头带"] = {230,245,260,275},
	["黑色魔纹手套"] = {215,230,245,260},
	["黑色魔纹护肩"] = {230,245,260,275},
	["黑色魔纹短裤"] = {205,220,235,250},
	["黑色魔纹长袍"] = {210,225,240,255},
	["黑色龙鳞战靴"] = {300,320,330,340},
	["黑色龙鳞护肩"] = {300,320,330,340},
	["黑色龙鳞护腿"] = {300,320,330,340},
	["黑色龙鳞胸甲"] = {290,310,320,330},
	["黑铁利剑"] = {300,320,330,340},
	["黑铁头盔"] = {300,320,330,340},
	["黑铁带扣"] = {275,275,280,285},
	["黑铁徽记之戒"] = {290,320,330,340},
	["黑铁战斧"] = {300,320,330,340},
	["黑铁护手"] = {300,320,330,340},
	["黑铁护肩"] = {280,300,310,320},
	["黑铁护腕"] = {295,315,325,335},
	["黑铁护腿"] = {300,320,330,340},
	["黑铁斩碎者"] = {275,295,305,315},
	["黑铁板甲"] = {285,305,315,325},
	["黑铁步枪"] = {275,295,305,315},
	["黑铁炸弹"] = {285,305,315,325},
	["黑铁粉碎者"] = {265,285,295,305},
	["黑铁锁甲"] = {270,290,300,310},
	["黑铁长靴"] = {300,320,330,340},
	["龙喉手套"] = {170,170,182,195},
	["龙喉护甲片"] = {175,175,182,190},
	["龙息红椒"] = {200,240,260,280},
	["龙鳞带扣"] = {235,235,240,245},
	["龙鳞护手"] = {225,245,255,265},
	["龙鳞护腿"] = {245,245,245,245},
	["龙鳞胸甲"] = {255,275,285,295},
	["龟壳头盔"] = {230,250,260,270},
	["龟壳手套"] = {205,225,235,245},
	["龟壳护腕"] = {210,230,240,250},
	["龟壳护腿"] = {235,255,265,275},
	["龟壳胸甲"] = {210,230,240,250},
}

ATSW_CnSkillUpByID = {
	[37] = {300,320,330,340},
	[55] = {175,175,182,190},
	[57] = {200,195,200,205},
	[69] = {175,175,180,185},
	[70] = {170,170,182,195},
	[74] = {235,235,240,245},
	[85] = {275,275,280,285},
	[90] = {225,225,230,235},
	[93] = {185,185,200,215},
	[95] = {285,285,297,310},
	[102] = {300,300,310,320},
	[104] = {185,185,195,205},
	[115] = {200,200,212,225},
	[765] = {1,25,50,100},
	[785] = {50,75,100,150},
	[2149] = {1,40,55,70},
	[2152] = {1,30,45,60},
	[2153] = {15,45,60,75},
	[2158] = {90,120,135,150},
	[2159] = {85,105,120,135},
	[2160] = {40,70,85,100},
	[2161] = {55,85,100,115},
	[2162] = {60,90,105,120},
	[2163] = {60,90,105,120},
	[2164] = {75,105,120,135},
	[2165] = {100,115,122,130},
	[2166] = {120,145,157,170},
	[2167] = {100,125,137,150},
	[2168] = {110,135,147,160},
	[2169] = {100,125,137,150},
	[2329] = {1,55,75,95},
	[2330] = {1,55,75,95},
	[2331] = {25,65,85,105},
	[2332] = {40,70,90,110},
	[2333] = {140,165,185,205},
	[2334] = {50,80,100,120},
	[2335] = {60,90,110,130},
	[2337] = {55,85,105,125},
	[2385] = {10,45,57,70},
	[2386] = {65,90,107,125},
	[2387] = {1,35,47,60},
	[2389] = {40,65,82,100},
	[2392] = {40,65,82,100},
	[2393] = {1,35,47,60},
	[2394] = {40,65,82,100},
	[2395] = {70,95,112,130},
	[2396] = {70,95,112,130},
	[2397] = {60,85,102,120},
	[2399] = {85,110,127,145},
	[2401] = {95,120,137,155},
	[2402] = {75,100,117,135},
	[2403] = {105,130,147,165},
	[2406] = {100,110,120,130},
	[2447] = {1,25,50,100},
	[2449] = {15,40,65,115},
	[2450] = {70,95,120,170},
	[2453] = {100,130,150,200},
	[2538] = {1,45,65,85},
	[2539] = {10,50,70,90},
	[2540] = {1,45,65,85},
	[2541] = {50,90,110,130},
	[2542] = {50,90,110,130},
	[2543] = {75,115,135,155},
	[2544] = {75,115,135,155},
	[2545] = {85,125,145,165},
	[2546] = {80,120,140,160},
	[2547] = {100,135,155,175},
	[2548] = {110,130,150,170},
	[2549] = {100,140,160,180},
	[2657] = {1,25,45,70},
	[2658] = {75,100,112,125},
	[2659] = {65,65,90,115},
	[2660] = {1,15,35,55},
	[2661] = {35,75,95,115},
	[2662] = {1,50,70,90},
	[2663] = {1,20,40,60},
	[2664] = {90,115,127,140},
	[2665] = {65,65,72,80},
	[2666] = {70,110,130,150},
	[2667] = {80,120,140,160},
	[2668] = {105,145,160,175},
	[2670] = {105,145,160,175},
	[2671] = {100,140,160,180},
	[2672] = {120,150,165,180},
	[2673] = {130,160,175,190},
	[2674] = {125,125,132,140},
	[2675] = {145,175,190,205},
	[2737] = {15,55,75,95},
	[2738] = {20,60,80,100},
	[2739] = {25,65,85,105},
	[2740] = {110,140,155,170},
	[2741] = {115,145,160,175},
	[2742] = {120,150,165,180},
	[2795] = {25,60,80,100},
	[2835] = {130,175,200,225},
	[2837] = {170,215,240,265},
	[2881] = {1,20,30,40},
	[2963] = {1,25,37,50},
	[2964] = {75,90,97,105},
	[3115] = {1,15,35,55},
	[3116] = {65,65,72,80},
	[3117] = {125,125,132,140},
	[3170] = {15,60,80,100},
	[3171] = {90,120,140,160},
	[3172] = {110,135,155,175},
	[3173] = {120,145,165,185},
	[3174] = {120,145,165,185},
	[3175] = {250,275,295,315},
	[3176] = {125,150,170,190},
	[3177] = {130,155,175,195},
	[3188] = {150,175,195,215},
	[3230] = {50,80,100,120},
	[3275] = {1,30,45,60},
	[3276] = {40,50,75,100},
	[3277] = {80,80,115,150},
	[3278] = {115,115,150,185},
	[3292] = {95,135,155,175},
	[3293] = {35,75,95,115},
	[3294] = {70,110,130,150},
	[3295] = {125,155,170,185},
	[3296] = {130,160,175,190},
	[3297] = {145,175,190,205},
	[3304] = {65,65,70,75},
	[3307] = {125,125,130,140},
	[3308] = {155,170,177,185},
	[3319] = {20,60,80,100},
	[3320] = {25,45,65,85},
	[3321] = {35,75,95,115},
	[3323] = {40,80,100,120},
	[3324] = {45,85,105,125},
	[3325] = {60,100,120,140},
	[3326] = {75,75,87,100},
	[3328] = {110,140,155,170},
	[3330] = {125,155,170,185},
	[3331] = {130,160,175,190},
	[3333] = {135,165,180,195},
	[3334] = {145,175,190,205},
	[3336] = {150,180,195,210},
	[3337] = {125,125,137,150},
	[3355] = {115,145,165,215},
	[3356] = {125,155,175,225},
	[3357] = {150,175,200,250},
	[3358] = {185,210,235,285},
	[3369] = {120,150,170,220},
	[3370] = {80,120,140,160},
	[3371] = {60,100,120,140},
	[3372] = {90,130,150,170},
	[3373] = {120,160,180,200},
	[3376] = {130,170,190,210},
	[3377] = {110,150,170,190},
	[3397] = {110,150,170,190},
	[3398] = {125,175,195,215},
	[3399] = {150,190,210,230},
	[3400] = {175,215,235,255},
	[3420] = {1,125,150,175},
	[3421] = {230,275,300,325},
	[3447] = {110,135,155,175},
	[3448] = {165,185,205,225},
	[3449] = {165,190,210,230},
	[3450] = {175,195,215,235},
	[3451] = {180,200,220,240},
	[3452] = {160,180,200,220},
	[3453] = {195,215,235,255},
	[3454] = {200,220,240,260},
	[3491] = {105,135,150,165},
	[3492] = {160,185,197,210},
	[3493] = {175,200,212,225},
	[3494] = {155,180,192,205},
	[3495] = {170,195,207,220},
	[3496] = {180,205,217,230},
	[3497] = {200,225,237,250},
	[3498] = {185,210,222,235},
	[3500] = {200,225,237,250},
	[3501] = {165,190,202,215},
	[3502] = {170,195,207,220},
	[3503] = {190,215,227,240},
	[3504] = {160,185,197,210},
	[3505] = {175,200,212,225},
	[3506] = {155,180,192,205},
	[3507] = {170,195,207,220},
	[3508] = {180,205,217,230},
	[3511] = {195,220,232,245},
	[3513] = {185,210,222,235},
	[3515] = {200,225,237,250},
	[3569] = {165,165,165,165},
	[3753] = {25,55,70,85},
	[3755] = {45,70,87,105},
	[3756] = {55,85,100,115},
	[3757] = {80,105,122,140},
	[3758] = {95,120,137,155},
	[3759] = {75,105,120,135},
	[3760] = {150,170,180,190},
	[3761] = {85,115,130,145},
	[3762] = {100,125,137,150},
	[3763] = {80,110,125,140},
	[3764] = {145,170,182,195},
	[3765] = {120,155,167,180},
	[3766] = {125,150,162,175},
	[3767] = {120,145,157,170},
	[3768] = {130,155,167,180},
	[3769] = {140,165,177,190},
	[3770] = {135,160,172,185},
	[3771] = {150,170,180,190},
	[3772] = {155,175,185,195},
	[3773] = {175,195,205,215},
	[3774] = {160,180,190,200},
	[3775] = {170,190,200,210},
	[3776] = {180,200,210,220},
	[3777] = {195,215,225,235},
	[3778] = {185,205,215,225},
	[3779] = {200,220,230,240},
	[3780] = {150,170,180,190},
	[3813] = {150,170,185,200},
	[3816] = {35,55,65,75},
	[3817] = {100,115,122,130},
	[3818] = {160,190,210,260},
	[3819] = {195,225,245,295},
	[3820] = {85,115,135,185},
	[3821] = {170,195,220,270},
	[3839] = {125,135,140,145},
	[3840] = {35,60,77,95},
	[3841] = {60,85,102,120},
	[3842] = {70,95,112,130},
	[3843] = {85,110,127,145},
	[3844] = {100,125,142,160},
	[3845] = {80,105,122,140},
	[3847] = {95,120,137,155},
	[3848] = {110,135,152,170},
	[3849] = {120,145,162,180},
	[3850] = {110,135,152,170},
	[3851] = {125,150,167,185},
	[3852] = {130,150,165,180},
	[3854] = {145,165,180,195},
	[3855] = {125,150,167,185},
	[3856] = {140,160,175,190},
	[3857] = {165,185,200,215},
	[3858] = {170,190,205,220},
	[3859] = {150,170,185,200},
	[3860] = {175,195,210,225},
	[3861] = {185,205,220,235},
	[3862] = {200,220,235,250},
	[3863] = {180,200,215,230},
	[3864] = {200,220,235,250},
	[3865] = {175,180,182,185},
	[3866] = {110,135,152,170},
	[3868] = {125,150,167,185},
	[3869] = {135,145,150,155},
	[3870] = {155,165,170,175},
	[3871] = {170,180,185,190},
	[3872] = {185,195,200,205},
	[3873] = {200,210,215,220},
	[3914] = {30,55,72,90},
	[3915] = {1,35,47,60},
	[3918] = {1,20,30,40},
	[3919] = {1,30,45,60},
	[3920] = {1,30,45,60},
	[3922] = {30,45,52,60},
	[3923] = {30,60,75,90},
	[3924] = {50,80,95,110},
	[3925] = {50,80,95,110},
	[3926] = {65,95,110,125},
	[3928] = {75,105,120,135},
	[3929] = {75,85,90,95},
	[3930] = {75,85,90,95},
	[3931] = {75,90,97,105},
	[3932] = {85,115,130,145},
	[3933] = {100,130,145,160},
	[3934] = {100,130,145,160},
	[3936] = {105,130,142,155},
	[3937] = {105,105,130,155},
	[3938] = {105,105,130,155},
	[3939] = {120,145,157,170},
	[3940] = {120,145,157,170},
	[3941] = {120,120,145,170},
	[3942] = {125,125,150,175},
	[3944] = {125,125,150,175},
	[3945] = {125,125,135,145},
	[3946] = {125,125,135,145},
	[3947] = {125,125,135,145},
	[3949] = {130,155,167,180},
	[3950] = {140,140,165,190},
	[3952] = {140,165,177,190},
	[3953] = {145,145,170,195},
	[3954] = {145,170,182,195},
	[3955] = {150,175,187,200},
	[3956] = {150,175,187,200},
	[3957] = {155,175,185,195},
	[3958] = {160,160,170,180},
	[3959] = {160,180,190,200},
	[3960] = {165,185,195,205},
	[3961] = {170,170,190,210},
	[3962] = {175,175,195,215},
	[3963] = {175,175,195,215},
	[3965] = {185,185,205,225},
	[3966] = {185,205,215,225},
	[3967] = {190,190,210,230},
	[3968] = {195,215,225,235},
	[3969] = {200,220,230,240},
	[3971] = {200,220,230,240},
	[3972] = {200,200,220,240},
	[3973] = {90,110,125,140},
	[3977] = {60,90,105,120},
	[3978] = {110,135,147,160},
	[3979] = {180,200,210,220},
	[4094] = {175,215,235,255},
	[4096] = {165,185,195,205},
	[4097] = {165,185,195,205},
	[4508] = {50,80,100,120},
	[4625] = {205,235,255,305},
	[4942] = {215,230,250,270},
	[5244] = {40,70,85,100},
	[5763] = {1,150,175,200},
	[6412] = {10,50,70,90},
	[6413] = {20,60,80,100},
	[6414] = {35,75,95,115},
	[6415] = {50,90,110,130},
	[6416] = {50,90,110,130},
	[6417] = {90,130,150,170},
	[6418] = {100,140,160,180},
	[6419] = {110,150,170,190},
	[6458] = {135,160,172,185},
	[6499] = {50,90,110,130},
	[6500] = {125,165,185,205},
	[6501] = {90,130,150,170},
	[6510] = {1,170,195,220},
	[6517] = {110,140,155,170},
	[6518] = {140,170,185,200},
	[6521] = {90,115,132,150},
	[6617] = {60,90,110,130},
	[6618] = {175,195,215,235},
	[6624] = {150,175,195,215},
	[6661] = {190,210,220,230},
	[6686] = {70,95,112,130},
	[6688] = {115,140,157,175},
	[6690] = {135,155,170,185},
	[6692] = {150,170,185,200},
	[6693] = {175,195,210,225},
	[6695] = {185,205,220,235},
	[6702] = {90,120,135,150},
	[6703] = {95,125,140,155},
	[6704] = {170,190,200,210},
	[6705] = {190,210,220,230},
	[7126] = {1,40,55,70},
	[7133] = {105,130,142,155},
	[7135] = {115,140,152,165},
	[7147] = {160,180,190,200},
	[7149] = {170,190,200,210},
	[7151] = {175,195,205,215},
	[7153] = {185,205,215,225},
	[7156] = {190,210,220,230},
	[7179] = {90,120,140,160},
	[7181] = {155,175,195,215},
	[7183] = {1,55,75,95},
	[7213] = {175,215,235,255},
	[7221] = {150,180,195,210},
	[7222] = {165,190,202,215},
	[7223] = {185,210,222,235},
	[7224] = {190,215,227,240},
	[7255] = {100,130,150,170},
	[7256] = {135,160,180,200},
	[7257] = {165,210,230,250},
	[7258] = {190,205,225,245},
	[7259] = {190,210,230,250},
	[7408] = {65,105,125,145},
	[7421] = {1,5,7,10},
	[7430] = {50,70,80,90},
	[7623] = {30,55,72,90},
	[7624] = {30,55,72,90},
	[7629] = {55,80,97,115},
	[7630] = {55,80,97,115},
	[7633] = {70,95,112,130},
	[7639] = {100,125,142,160},
	[7643] = {115,140,157,175},
	[7751] = {1,45,65,85},
	[7752] = {1,45,65,85},
	[7753] = {50,90,110,130},
	[7754] = {50,90,110,130},
	[7755] = {100,140,160,180},
	[7795] = {100,130,150,170},
	[7817] = {95,125,140,155},
	[7818] = {100,105,107,110},
	[7827] = {50,90,110,130},
	[7828] = {175,190,210,230},
	[7836] = {80,80,90,100},
	[7837] = {130,150,160,170},
	[7841] = {100,130,150,170},
	[7845] = {140,165,185,205},
	[7892] = {120,145,162,180},
	[7893] = {120,145,162,180},
	[7928] = {150,150,180,210},
	[7929] = {180,180,210,240},
	[7934] = {80,80,115,150},
	[7935] = {130,130,165,200},
	[7953] = {90,120,135,150},
	[7954] = {105,130,142,155},
	[7955] = {115,140,152,165},
	[8238] = {85,125,145,165},
	[8240] = {90,120,140,160},
	[8243] = {185,185,205,225},
	[8322] = {90,115,130,145},
	[8334] = {100,115,122,130},
	[8339] = {100,115,122,130},
	[8366] = {70,110,130,150},
	[8367] = {100,140,160,180},
	[8465] = {40,65,82,100},
	[8467] = {110,135,152,170},
	[8483] = {160,170,175,180},
	[8489] = {175,185,190,195},
	[8604] = {1,45,65,85},
	[8607] = {40,80,100,120},
	[8681] = {1,125,150,175},
	[8687] = {120,165,190,215},
	[8691] = {160,205,230,255},
	[8694] = {1,215,240,265},
	[8758] = {140,160,175,190},
	[8760] = {145,155,160,165},
	[8762] = {160,170,175,180},
	[8764] = {170,190,205,220},
	[8766] = {175,195,210,225},
	[8768] = {150,150,152,155},
	[8770] = {190,210,225,240},
	[8772] = {175,195,210,225},
	[8774] = {180,200,215,230},
	[8776] = {15,50,67,85},
	[8778] = {140,160,175,190},
	[8780] = {145,165,180,195},
	[8782] = {150,170,185,200},
	[8784] = {165,185,200,215},
	[8786] = {175,195,210,225},
	[8789] = {180,200,215,230},
	[8791] = {185,205,215,225},
	[8793] = {190,210,225,240},
	[8795] = {190,210,225,240},
	[8797] = {195,215,230,245},
	[8799] = {195,215,225,235},
	[8802] = {205,220,235,250},
	[8804] = {210,225,240,255},
	[8831] = {210,240,260,310},
	[8836] = {220,250,270,320},
	[8838] = {230,255,280,330},
	[8839] = {235,260,285,335},
	[8845] = {245,270,295,345},
	[8846] = {250,275,300,350},
	[8880] = {30,70,90,110},
	[8895] = {225,245,255,265},
	[9058] = {1,40,55,70},
	[9059] = {1,40,55,70},
	[9060] = {30,60,75,90},
	[9062] = {30,60,75,90},
	[9064] = {35,65,80,95},
	[9065] = {70,100,115,130},
	[9068] = {95,125,140,155},
	[9070] = {100,125,137,150},
	[9072] = {120,145,157,170},
	[9074] = {120,145,157,170},
	[9145] = {125,150,162,175},
	[9146] = {135,160,172,185},
	[9147] = {135,160,172,185},
	[9148] = {140,165,177,190},
	[9149] = {145,170,182,195},
	[9193] = {150,170,180,190},
	[9194] = {150,170,180,190},
	[9195] = {165,185,195,205},
	[9196] = {175,195,205,215},
	[9197] = {175,195,205,215},
	[9198] = {180,200,210,220},
	[9201] = {185,205,215,225},
	[9202] = {190,210,220,230},
	[9206] = {195,215,225,235},
	[9207] = {200,220,230,240},
	[9208] = {200,220,230,240},
	[9269] = {125,150,162,175},
	[9271] = {150,150,160,170},
	[9273] = {165,165,180,200},
	[9513] = {60,100,120,140},
	[9811] = {160,185,197,210},
	[9813] = {160,185,197,210},
	[9814] = {175,200,212,225},
	[9818] = {180,205,217,230},
	[9820] = {185,210,222,235},
	[9916] = {200,225,237,250},
	[9918] = {200,200,205,210},
	[9920] = {200,200,205,210},
	[9921] = {200,200,205,210},
	[9926] = {205,225,235,245},
	[9928] = {205,225,235,245},
	[9931] = {210,230,240,250},
	[9933] = {210,230,240,250},
	[9935] = {215,235,245,255},
	[9937] = {215,235,245,255},
	[9939] = {215,235,245,255},
	[9942] = {220,240,250,260},
	[9945] = {220,240,250,260},
	[9950] = {220,240,250,260},
	[9952] = {225,245,255,265},
	[9954] = {225,245,255,265},
	[9957] = {210,250,260,270},
	[9959] = {230,250,260,270},
	[9961] = {230,250,260,270},
	[9964] = {235,255,265,275},
	[9966] = {235,255,265,275},
	[9968] = {235,255,265,275},
	[9970] = {245,255,265,275},
	[9972] = {210,260,270,280},
	[9974] = {245,265,275,285},
	[9979] = {210,265,275,285},
	[9980] = {210,265,275,285},
	[9983] = {30,70,90,110},
	[9985] = {125,155,170,185},
	[9986] = {130,160,175,190},
	[9987] = {135,165,180,195},
	[9993] = {210,235,247,260},
	[9995] = {220,245,257,270},
	[9997] = {225,250,262,275},
	[10001] = {230,255,267,280},
	[10003] = {235,260,272,285},
	[10005] = {240,265,277,290},
	[10007] = {245,270,282,295},
	[10009] = {245,270,282,295},
	[10011] = {250,275,287,300},
	[10013] = {255,280,292,305},
	[10015] = {260,285,297,310},
	[10097] = {175,175,175,175},
	[10098] = {230,230,230,230},
	[10482] = {200,200,200,200},
	[10487] = {200,220,230,240},
	[10490] = {200,220,230,240},
	[10499] = {205,225,235,245},
	[10507] = {205,225,235,245},
	[10509] = {205,225,235,245},
	[10511] = {210,230,240,250},
	[10516] = {210,230,240,250},
	[10518] = {210,230,240,250},
	[10520] = {215,235,245,255},
	[10525] = {220,240,250,260},
	[10529] = {220,240,250,260},
	[10531] = {220,240,250,260},
	[10533] = {220,240,250,260},
	[10542] = {225,245,255,265},
	[10544] = {225,245,255,265},
	[10546] = {225,245,255,265},
	[10548] = {230,250,260,270},
	[10550] = {230,250,260,270},
	[10552] = {230,250,260,270},
	[10554] = {235,255,265,275},
	[10556] = {235,255,265,275},
	[10558] = {235,255,265,275},
	[10560] = {240,260,270,280},
	[10562] = {240,260,270,280},
	[10564] = {240,260,270,280},
	[10566] = {245,265,275,285},
	[10568] = {245,265,275,285},
	[10570] = {250,270,280,290},
	[10572] = {250,270,280,290},
	[10574] = {250,270,280,290},
	[10619] = {225,245,255,265},
	[10621] = {225,245,255,265},
	[10630] = {230,250,260,270},
	[10632] = {250,270,280,290},
	[10647] = {250,270,280,290},
	[10650] = {255,275,285,295},
	[10840] = {210,210,240,270},
	[10841] = {240,240,270,300},
	[10844] = {300,300,330,360},
	[11341] = {200,245,270,295},
	[11342] = {240,285,340,335},
	[11343] = {280,325,350,375},
	[11357] = {210,255,280,305},
	[11358] = {250,295,320,345},
	[11400] = {1,285,310,335},
	[11448] = {205,220,240,260},
	[11449] = {185,205,225,245},
	[11450] = {195,215,235,255},
	[11451] = {205,220,240,260},
	[11452] = {210,225,245,265},
	[11453] = {210,225,245,265},
	[11454] = {200,225,237,250},
	[11456] = {210,225,245,265},
	[11457] = {215,230,250,270},
	[11458] = {225,240,260,280},
	[11459] = {200,240,260,280},
	[11460] = {230,245,265,285},
	[11461] = {235,250,270,290},
	[11464] = {235,250,270,290},
	[11465] = {235,250,270,290},
	[11466] = {240,255,275,295},
	[11467] = {240,255,275,295},
	[11468] = {240,255,275,295},
	[11472] = {245,260,280,300},
	[11473] = {245,260,280,300},
	[11476] = {250,265,285,305},
	[11477] = {250,265,285,305},
	[11478] = {250,265,285,305},
	[11479] = {225,240,260,280},
	[11480] = {225,240,260,280},
	[11643] = {205,225,235,245},
	[12044] = {1,35,47,60},
	[12045] = {20,50,67,85},
	[12046] = {75,100,117,135},
	[12047] = {120,145,162,180},
	[12048] = {205,220,235,250},
	[12049] = {205,220,235,250},
	[12050] = {210,225,240,255},
	[12052] = {210,225,240,255},
	[12053] = {215,230,245,260},
	[12055] = {215,230,245,260},
	[12056] = {215,230,245,260},
	[12059] = {215,220,225,230},
	[12060] = {215,230,245,260},
	[12061] = {215,220,225,230},
	[12062] = {220,235,250,265},
	[12063] = {220,235,250,265},
	[12064] = {220,225,230,235},
	[12065] = {225,240,255,270},
	[12066] = {225,240,255,270},
	[12067] = {225,240,255,270},
	[12068] = {225,240,255,270},
	[12069] = {225,240,255,270},
	[12070] = {225,240,255,270},
	[12071] = {225,240,255,270},
	[12072] = {230,245,260,275},
	[12073] = {230,245,260,275},
	[12074] = {230,245,260,275},
	[12075] = {230,235,240,245},
	[12076] = {235,250,265,280},
	[12077] = {235,240,245,250},
	[12078] = {235,250,265,280},
	[12079] = {235,250,265,280},
	[12080] = {235,240,245,250},
	[12081] = {240,255,270,285},
	[12082] = {240,255,270,285},
	[12083] = {240,255,270,285},
	[12084] = {240,255,270,285},
	[12085] = {240,245,250,255},
	[12086] = {245,260,275,290},
	[12087] = {245,260,275,290},
	[12088] = {245,260,275,290},
	[12089] = {245,250,255,260},
	[12090] = {250,265,280,295},
	[12091] = {250,255,260,265},
	[12092] = {250,265,280,295},
	[12093] = {250,265,280,295},
	[12259] = {155,180,192,205},
	[12260] = {1,15,35,55},
	[12584] = {150,150,170,190},
	[12585] = {175,175,185,195},
	[12586] = {175,175,185,195},
	[12587] = {175,195,205,215},
	[12589] = {195,195,215,235},
	[12590] = {175,175,195,215},
	[12591] = {200,200,220,240},
	[12594] = {205,225,235,245},
	[12595] = {205,225,235,245},
	[12596] = {210,210,230,250},
	[12597] = {210,230,240,250},
	[12599] = {215,215,235,255},
	[12603] = {215,215,235,255},
	[12607] = {220,240,250,260},
	[12609] = {200,220,240,260},
	[12614] = {220,240,250,260},
	[12615] = {225,245,255,265},
	[12616] = {225,245,255,265},
	[12617] = {230,250,260,270},
	[12618] = {230,250,260,270},
	[12619] = {235,235,255,275},
	[12620] = {240,260,270,280},
	[12621] = {245,245,265,285},
	[12622] = {245,265,275,285},
	[12624] = {250,270,280,290},
	[12715] = {205,205,205,205},
	[12716] = {205,225,235,245},
	[12717] = {205,225,235,245},
	[12718] = {205,225,235,245},
	[12722] = {225,240,250,260},
	[12754] = {235,235,255,275},
	[12755] = {230,230,250,270},
	[12758] = {245,265,275,285},
	[12759] = {240,260,270,280},
	[12760] = {205,205,225,245},
	[12895] = {205,205,205,205},
	[12897] = {210,230,240,250},
	[12899] = {205,225,235,245},
	[12902] = {210,230,240,250},
	[12903] = {215,235,245,255},
	[12905] = {225,245,255,265},
	[12906] = {230,250,260,270},
	[12907] = {235,255,265,275},
	[12908] = {240,260,270,280},
	[13028] = {175,175,190,205},
	[13220] = {1,185,210,235},
	[13240] = {205,205,205,205},
	[13463] = {270,295,320,370},
	[13464] = {260,280,310,360},
	[13465] = {280,305,330,380},
	[13466] = {285,310,335,385},
	[13467] = {290,315,340,390},
	[13468] = {300,345,375,400},
	[13628] = {150,175,195,215},
	[13702] = {200,220,240,260},
	[14293] = {10,75,95,115},
	[14379] = {150,155,157,160},
	[14380] = {200,205,207,210},
	[14807] = {70,110,130,150},
	[14809] = {155,175,195,215},
	[14810] = {175,195,215,235},
	[14891] = {230,230,230,230},
	[14930] = {225,245,255,265},
	[14932] = {225,245,255,265},
	[15255] = {200,200,220,240},
	[15292] = {265,285,295,305},
	[15293] = {270,290,300,310},
	[15294] = {275,295,305,315},
	[15295] = {280,300,310,320},
	[15296] = {285,305,315,325},
	[15596] = {265,285,305,325},
	[15628] = {205,205,205,205},
	[15633] = {205,205,205,205},
	[15833] = {230,245,265,285},
	[15853] = {125,165,185,205},
	[15855] = {175,215,235,255},
	[15856] = {175,215,235,255},
	[15861] = {175,215,235,255},
	[15863] = {175,215,235,255},
	[15865] = {175,215,235,255},
	[15906] = {200,240,260,280},
	[15910] = {200,240,260,280},
	[15915] = {225,265,285,305},
	[15933] = {225,265,285,305},
	[15935] = {1,45,65,85},
	[15972] = {180,205,217,230},
	[15973] = {190,215,227,240},
	[16153] = {250,250,250,250},
	[16639] = {250,255,257,260},
	[16640] = {250,255,257,260},
	[16641] = {250,255,257,260},
	[16642] = {250,270,280,290},
	[16643] = {250,270,280,290},
	[16644] = {255,275,285,295},
	[16645] = {260,280,290,300},
	[16646] = {265,285,295,305},
	[16647] = {265,285,295,305},
	[16648] = {270,290,300,310},
	[16649] = {270,290,300,310},
	[16650] = {270,290,300,310},
	[16651] = {275,295,305,315},
	[16652] = {280,300,310,320},
	[16653] = {280,300,310,320},
	[16654] = {285,305,315,325},
	[16655] = {290,310,320,330},
	[16656] = {290,310,320,330},
	[16657] = {295,315,325,335},
	[16658] = {295,315,325,335},
	[16659] = {295,315,325,335},
	[16660] = {290,310,320,330},
	[16661] = {295,315,325,335},
	[16662] = {300,320,330,340},
	[16663] = {300,320,330,340},
	[16664] = {300,320,330,340},
	[16665] = {300,320,330,340},
	[16667] = {285,305,315,325},
	[16724] = {300,320,330,340},
	[16725] = {300,320,330,340},
	[16726] = {300,320,330,340},
	[16728] = {300,320,330,340},
	[16729] = {300,320,330,340},
	[16730] = {300,320,330,340},
	[16731] = {300,320,330,340},
	[16732] = {300,320,330,340},
	[16741] = {300,320,330,340},
	[16742] = {300,320,330,340},
	[16744] = {300,320,330,340},
	[16745] = {300,320,330,340},
	[16746] = {300,320,330,340},
	[16960] = {260,285,297,310},
	[16965] = {270,290,300,310},
	[16967] = {270,295,307,320},
	[16969] = {275,300,312,325},
	[16970] = {275,300,312,325},
	[16971] = {280,305,317,330},
	[16973] = {280,305,317,330},
	[16978] = {280,305,317,330},
	[16980] = {285,310,322,335},
	[16983] = {285,310,322,335},
	[16984] = {290,315,327,340},
	[16985] = {290,315,327,340},
	[16986] = {300,320,330,340},
	[16987] = {300,320,330,340},
	[16988] = {300,320,330,340},
	[16990] = {300,320,330,340},
	[16991] = {300,320,330,340},
	[16992] = {300,320,330,340},
	[16993] = {300,320,330,340},
	[16994] = {300,320,330,340},
	[16995] = {300,320,330,340},
	[17180] = {250,250,255,260},
	[17181] = {250,250,255,260},
	[17187] = {275,275,282,290},
	[17551] = {250,250,255,260},
	[17552] = {255,270,290,310},
	[17553] = {260,275,295,315},
	[17554] = {265,280,300,320},
	[17555] = {265,280,300,320},
	[17556] = {275,290,310,330},
	[17557] = {275,290,310,330},
	[17559] = {275,275,282,290},
	[17560] = {275,275,282,290},
	[17561] = {275,275,282,290},
	[17562] = {275,275,282,290},
	[17563] = {275,275,282,290},
	[17564] = {275,275,282,290},
	[17565] = {275,275,282,290},
	[17566] = {275,275,282,290},
	[17570] = {280,295,315,335},
	[17571] = {280,295,315,335},
	[17572] = {285,300,320,340},
	[17573] = {285,300,320,340},
	[17574] = {290,305,325,345},
	[17575] = {290,305,325,345},
	[17576] = {290,305,325,345},
	[17577] = {290,305,325,345},
	[17578] = {290,305,325,345},
	[17579] = {290,305,325,345},
	[17580] = {295,310,330,350},
	[17632] = {300,315,322,330},
	[17634] = {300,315,322,330},
	[17635] = {300,315,322,330},
	[17636] = {300,315,322,330},
	[17637] = {300,315,322,330},
	[17638] = {300,315,322,330},
	[18238] = {225,265,285,305},
	[18239] = {225,265,285,305},
	[18240] = {240,280,300,320},
	[18241] = {225,265,285,305},
	[18242] = {240,280,300,320},
	[18243] = {250,290,310,330},
	[18244] = {250,290,310,330},
	[18245] = {275,315,335,355},
	[18246] = {275,315,335,355},
	[18247] = {275,315,335,355},
	[18401] = {250,255,257,260},
	[18402] = {255,270,285,300},
	[18403] = {255,270,285,300},
	[18404] = {255,270,285,300},
	[18405] = {260,275,290,305},
	[18406] = {260,275,290,305},
	[18407] = {260,275,290,305},
	[18408] = {260,275,290,305},
	[18409] = {265,280,295,310},
	[18410] = {265,280,295,310},
	[18411] = {265,280,295,310},
	[18412] = {270,285,300,315},
	[18413] = {270,285,300,315},
	[18414] = {270,285,300,315},
	[18415] = {270,285,300,315},
	[18416] = {275,290,305,320},
	[18417] = {275,290,305,320},
	[18418] = {275,290,305,320},
	[18419] = {275,290,305,320},
	[18420] = {275,290,305,320},
	[18421] = {275,290,305,320},
	[18422] = {275,290,305,320},
	[18423] = {280,295,310,325},
	[18424] = {280,295,310,325},
	[18434] = {280,295,310,325},
	[18436] = {285,300,315,330},
	[18437] = {285,300,315,330},
	[18438] = {285,300,315,330},
	[18439] = {290,305,320,335},
	[18440] = {290,305,320,335},
	[18441] = {290,305,320,335},
	[18442] = {290,305,320,335},
	[18444] = {295,310,325,340},
	[18445] = {300,315,330,345},
	[18446] = {300,315,330,345},
	[18447] = {300,315,330,345},
	[18448] = {300,315,330,345},
	[18449] = {300,315,330,345},
	[18450] = {300,315,330,345},
	[18451] = {300,315,330,345},
	[18452] = {300,315,330,345},
	[18453] = {300,315,330,345},
	[18454] = {300,315,330,345},
	[18455] = {300,315,330,345},
	[18456] = {300,315,330,345},
	[18457] = {300,315,330,345},
	[18458] = {300,315,330,345},
	[18560] = {250,290,305,320},
	[18629] = {260,260,290,320},
	[18630] = {290,290,320,350},
	[19047] = {250,250,255,260},
	[19048] = {255,275,285,295},
	[19049] = {260,280,290,300},
	[19050] = {260,280,290,300},
	[19051] = {265,285,295,305},
	[19052] = {265,285,295,305},
	[19053] = {265,270,280,290},
	[19054] = {300,320,330,340},
	[19055] = {270,290,300,310},
	[19058] = {250,255,265,275},
	[19059] = {270,290,300,310},
	[19060] = {270,290,300,310},
	[19061] = {270,290,300,310},
	[19062] = {270,290,300,310},
	[19063] = {275,295,305,315},
	[19064] = {275,295,305,315},
	[19065] = {275,295,305,315},
	[19066] = {275,295,305,315},
	[19067] = {275,295,305,315},
	[19068] = {275,295,305,315},
	[19070] = {280,300,310,320},
	[19071] = {280,300,310,320},
	[19072] = {280,300,310,320},
	[19073] = {280,300,310,320},
	[19074] = {285,305,315,325},
	[19075] = {285,305,315,325},
	[19076] = {285,305,315,325},
	[19077] = {285,305,315,325},
	[19078] = {285,305,315,325},
	[19079] = {285,305,315,325},
	[19080] = {285,305,315,325},
	[19081] = {290,310,320,330},
	[19082] = {290,310,320,330},
	[19083] = {290,310,320,330},
	[19084] = {290,310,320,330},
	[19085] = {290,310,320,330},
	[19086] = {290,310,320,330},
	[19087] = {295,315,325,335},
	[19088] = {295,315,325,335},
	[19089] = {295,315,325,335},
	[19090] = {295,315,325,335},
	[19091] = {300,320,330,340},
	[19092] = {300,320,330,340},
	[19093] = {300,320,330,340},
	[19094] = {300,320,330,340},
	[19095] = {300,320,330,340},
	[19097] = {300,320,330,340},
	[19098] = {300,320,330,340},
	[19100] = {300,320,330,340},
	[19101] = {300,320,330,340},
	[19102] = {300,320,330,340},
	[19103] = {300,320,330,340},
	[19104] = {300,320,330,340},
	[19107] = {300,320,330,340},
	[19435] = {290,295,310,325},
	[19567] = {250,270,280,290},
	[19666] = {100,100,110,120},
	[19667] = {150,150,160,170},
	[19668] = {200,200,210,220},
	[19669] = {275,275,280,285},
	[19788] = {250,250,255,260},
	[19790] = {260,280,290,300},
	[19791] = {260,280,290,300},
	[19792] = {260,280,290,300},
	[19793] = {265,285,295,305},
	[19794] = {270,290,300,310},
	[19795] = {275,295,305,315},
	[19796] = {275,295,305,315},
	[19799] = {285,305,315,325},
	[19800] = {285,305,315,325},
	[19814] = {275,295,305,315},
	[19815] = {285,305,315,325},
	[19819] = {290,310,320,330},
	[19825] = {290,310,320,330},
	[19830] = {300,320,330,340},
	[19831] = {300,320,330,340},
	[19833] = {300,320,330,340},
	[20051] = {290,310,330,350},
	[20201] = {275,275,280,285},
	[20626] = {225,265,285,305},
	[20648] = {100,100,105,110},
	[20649] = {150,150,155,160},
	[20650] = {200,200,202,205},
	[20848] = {300,315,330,345},
	[20849] = {300,315,330,345},
	[20853] = {295,315,325,335},
	[20854] = {300,320,330,340},
	[20855] = {300,320,330,340},
	[20872] = {295,315,325,335},
	[20873] = {300,320,330,340},
	[20874] = {295,315,325,335},
	[20876] = {300,320,330,340},
	[20890] = {300,320,330,340},
	[20897] = {300,320,330,340},
	[20916] = {175,215,235,255},
	[21143] = {1,45,65,85},
	[21144] = {35,75,95,115},
	[21161] = {300,325,337,350},
	[21175] = {200,240,260,280},
	[21913] = {190,215,227,240},
	[21923] = {190,210,230,250},
	[21940] = {190,190,210,230},
	[21943] = {190,210,220,230},
	[21945] = {190,200,205,210},
	[22331] = {250,250,250,250},
	[22480] = {225,265,285,305},
	[22704] = {300,320,330,340},
	[22711] = {200,210,220,230},
	[22727] = {300,320,330,340},
	[22732] = {300,310,320,330},
	[22757] = {300,300,310,320},
	[22759] = {300,315,330,345},
	[22761] = {275,315,335,355},
	[22793] = {300,320,330,340},
	[22795] = {300,320,330,340},
	[22797] = {300,320,330,340},
	[22808] = {215,230,250,270},
	[22813] = {275,285,290,295},
	[22815] = {275,285,290,295},
	[22866] = {300,315,330,345},
	[22867] = {300,315,330,345},
	[22868] = {300,315,330,345},
	[22869] = {300,315,330,345},
	[22870] = {300,315,330,345},
	[22902] = {300,315,330,345},
	[22921] = {300,320,330,340},
	[22922] = {300,320,330,340},
	[22923] = {300,320,330,340},
	[22926] = {300,320,330,340},
	[22927] = {300,320,330,340},
	[22928] = {300,320,330,340},
	[22967] = {300,350,362,375},
	[23066] = {150,150,162,175},
	[23067] = {150,150,162,175},
	[23068] = {150,150,162,175},
	[23069] = {200,200,210,220},
	[23070] = {250,250,260,270},
	[23071] = {260,270,275,280},
	[23077] = {260,280,290,300},
	[23078] = {265,285,295,305},
	[23079] = {275,285,290,295},
	[23080] = {275,275,285,295},
	[23081] = {290,310,320,330},
	[23082] = {300,320,330,340},
	[23096] = {265,275,280,285},
	[23129] = {260,260,265,270},
	[23190] = {150,150,155,160},
	[23399] = {155,175,185,195},
	[23486] = {260,285,295,305},
	[23489] = {260,285,295,305},
	[23507] = {250,250,260,270},
	[23628] = {290,310,320,330},
	[23629] = {300,320,330,340},
	[23632] = {290,310,320,330},
	[23633] = {300,320,330,340},
	[23636] = {300,320,330,340},
	[23637] = {300,320,330,340},
	[23638] = {300,320,330,340},
	[23639] = {300,320,330,340},
	[23650] = {300,320,330,340},
	[23652] = {300,320,330,340},
	[23653] = {300,320,330,340},
	[23662] = {290,305,320,335},
	[23663] = {300,315,330,345},
	[23664] = {290,305,320,335},
	[23665] = {300,315,330,345},
	[23666] = {300,315,330,345},
	[23667] = {300,315,330,345},
	[23703] = {290,310,320,330},
	[23704] = {300,320,330,340},
	[23705] = {290,310,320,330},
	[23706] = {300,320,330,340},
	[23707] = {300,320,330,340},
	[23708] = {300,320,330,340},
	[23709] = {300,320,330,340},
	[23710] = {300,320,330,340},
	[23787] = {300,300,330,360},
	[24091] = {300,315,330,345},
	[24092] = {300,315,330,345},
	[24093] = {300,315,330,345},
	[24121] = {300,320,330,340},
	[24122] = {300,320,330,340},
	[24123] = {300,320,330,340},
	[24124] = {300,320,330,340},
	[24125] = {300,320,330,340},
	[24136] = {300,320,330,340},
	[24137] = {300,320,330,340},
	[24138] = {300,320,330,340},
	[24139] = {300,320,330,340},
	[24140] = {300,320,330,340},
	[24141] = {300,320,330,340},
	[24266] = {300,315,322,330},
	[24356] = {300,320,330,340},
	[24357] = {300,320,330,340},
	[24365] = {275,290,310,330},
	[24366] = {275,290,310,330},
	[24367] = {285,300,320,340},
	[24368] = {290,305,325,345},
	[24399] = {300,320,330,340},
	[24418] = {150,160,180,200},
	[24654] = {300,320,330,340},
	[24655] = {280,300,310,320},
	[24703] = {300,320,330,340},
	[24801] = {285,325,345,365},
	[24846] = {300,320,330,340},
	[24847] = {300,320,330,340},
	[24848] = {300,320,330,340},
	[24849] = {300,320,330,340},
	[24850] = {300,320,330,340},
	[24851] = {300,320,330,340},
	[24901] = {300,315,330,345},
	[24902] = {300,315,330,345},
	[24903] = {300,315,330,345},
	[24912] = {300,320,330,340},
	[24913] = {300,320,330,340},
	[24914] = {300,320,330,340},
	[24940] = {100,125,137,150},
	[25124] = {45,55,65,75},
	[25125] = {150,160,170,180},
	[25126] = {200,210,220,230},
	[25127] = {250,260,270,280},
	[25128] = {275,285,295,305},
	[25129] = {300,310,320,330},
	[25130] = {300,310,320,330},
	[25146] = {300,301,305,310},
	[25347] = {1,300,325,350},
	[25659] = {300,325,345,365},
	[25704] = {80,120,140,160},
	[25954] = {175,215,235,255},
	[26011] = {250,320,330,340},
	[26085] = {260,275,290,305},
	[26086] = {280,300,315,330},
	[26087] = {300,315,330,345},
	[26277] = {250,265,285,305},
	[26279] = {300,320,330,340},
	[26403] = {250,265,280,295},
	[26407] = {250,265,280,295},
	[26416] = {125,125,137,150},
	[26417] = {125,125,137,150},
	[26418] = {125,125,137,150},
	[26420] = {175,175,187,200},
	[26421] = {175,175,187,200},
	[26422] = {175,175,187,200},
	[26423] = {225,225,237,250},
	[26424] = {225,225,237,250},
	[26425] = {225,225,237,250},
	[26426] = {275,275,280,285},
	[26427] = {275,275,280,285},
	[26428] = {275,275,280,285},
	[26442] = {225,245,255,265},
	[26443] = {275,295,305,315},
	[27585] = {300,320,330,340},
	[27586] = {300,320,330,340},
	[27587] = {300,320,330,340},
	[27588] = {300,320,330,340},
	[27589] = {300,320,330,340},
	[27590] = {300,320,330,340},
	[27658] = {225,240,255,270},
	[27659] = {275,290,305,320},
	[27660] = {300,315,330,345},
	[27724] = {275,290,305,320},
	[27725] = {300,315,330,345},
	[27829] = {300,320,330,340},
	[27830] = {300,320,330,340},
	[27832] = {300,320,330,340},
	[28205] = {300,315,330,345},
	[28207] = {300,315,330,345},
	[28208] = {300,315,330,345},
	[28209] = {300,315,330,345},
	[28210] = {300,315,330,345},
	[28219] = {300,320,330,340},
	[28220] = {300,320,330,340},
	[28221] = {300,320,330,340},
	[28222] = {300,320,330,340},
	[28223] = {300,320,330,340},
	[28224] = {300,320,330,340},
	[28242] = {300,320,330,340},
	[28243] = {300,320,330,340},
	[28244] = {300,320,330,340},
	[28461] = {300,320,330,340},
	[28462] = {300,320,330,340},
	[28463] = {300,320,330,340},
	[28472] = {300,320,330,340},
	[28473] = {300,320,330,340},
	[28474] = {300,320,330,340},
	[28480] = {300,315,330,345},
	[28481] = {300,315,330,345},
	[28482] = {300,315,330,345},
	[29728] = {1,21,25,30},
	[29730] = {1,21,30,40},
	[29732] = {1,21,33,45},
	[30004] = {155,175,185,195},
	[30006] = {165,185,195,205},
	[30008] = {165,185,195,205},
	[30010] = {170,190,200,210},
	[30013] = {175,195,205,215},
	[30015] = {175,185,190,195},
	[30017] = {180,200,210,220},
	[30022] = {185,205,215,225},
	[30024] = {190,210,220,230},
	[30027] = {200,220,230,240},
	[30029] = {200,220,230,240},
	[30031] = {255,275,285,295},
	[30033] = {260,280,285,290},
	[30035] = {260,280,285,290},
	[30037] = {265,285,295,305},
	[30039] = {270,290,300,310},
	[30042] = {270,275,280,285},
	[30045] = {275,295,305,315},
	[30050] = {280,300,310,320},
	[30052] = {285,305,315,325},
	[30054] = {285,305,315,325},
	[30057] = {290,310,320,330},
	[30063] = {300,320,330,340},
	[30065] = {285,305,315,325},
	[30067] = {300,320,330,340},
	[30069] = {295,315,325,335},
	[30071] = {125,145,155,165},
	[30073] = {140,160,170,180},
	[30078] = {160,180,190,200},
	[30084] = {175,195,205,215},
	[30086] = {275,295,305,315},
	[36747] = {195,215,225,235},
	[36749] = {300,320,330,340},
	[36751] = {300,320,330,340},
	[36765] = {5,10,12,15},
	[36766] = {15,25,35,45},
	[36767] = {15,25,35,45},
	[36768] = {15,25,35,45},
	[36769] = {15,25,35,45},
	[36770] = {20,40,50,60},
	[36771] = {30,50,60,70},
	[36772] = {40,60,70,80},
	[36773] = {40,60,70,80},
	[36774] = {50,70,80,90},
	[36785] = {60,80,90,100},
	[36786] = {65,85,95,105},
	[36787] = {70,90,100,110},
	[36788] = {90,110,120,130},
	[36789] = {95,115,125,135},
	[36795] = {205,225,235,245},
	[36796] = {205,225,235,245},
	[36797] = {215,235,245,255},
	[36798] = {215,235,245,255},
	[36799] = {215,235,245,255},
	[36800] = {225,235,240,245},
	[36801] = {235,255,265,275},
	[36802] = {235,255,265,275},
	[36803] = {240,260,270,280},
	[36804] = {240,260,270,280},
	[36805] = {240,260,270,280},
	[36806] = {245,265,275,285},
	[36807] = {250,270,280,290},
	[36808] = {250,270,280,290},
	[36809] = {250,270,280,290},
	[36842] = {100,120,130,140},
	[36843] = {100,120,130,140},
	[36844] = {100,120,130,140},
	[36845] = {105,125,135,145},
	[36846] = {110,130,140,150},
	[36847] = {120,140,150,160},
	[36848] = {125,145,155,165},
	[36849] = {125,135,140,145},
	[36850] = {130,130,135,140},
	[36851] = {130,150,160,170},
	[36852] = {130,150,160,170},
	[36853] = {130,150,160,170},
	[36854] = {135,155,165,175},
	[36855] = {140,160,170,180},
	[36856] = {140,160,170,180},
	[36857] = {145,165,175,185},
	[36858] = {145,165,175,185},
	[36859] = {150,170,180,190},
	[36860] = {150,170,180,190},
	[36861] = {150,170,180,190},
	[36901] = {300,300,315,330},
	[36903] = {300,300,315,330},
	[36905] = {300,330,350,370},
	[36907] = {300,320,330,340},
	[36909] = {300,300,305,310},
	[36911] = {300,300,305,310},
	[36913] = {300,315,322,330},
	[36929] = {300,310,330,350},
	[36932] = {300,310,330,350},
	[36935] = {300,310,330,350},
	[41001] = {15,35,45,55},
	[41003] = {20,40,47,55},
	[41005] = {25,45,52,60},
	[41007] = {35,55,62,70},
	[41009] = {45,60,67,75},
	[41011] = {50,70,75,80},
	[41013] = {50,70,77,85},
	[41015] = {50,70,77,85},
	[41017] = {55,75,82,90},
	[41019] = {60,80,87,95},
	[41021] = {60,80,87,95},
	[41023] = {65,85,92,100},
	[41025] = {65,85,92,100},
	[41027] = {70,90,95,100},
	[41029] = {70,90,95,100},
	[41031] = {35,45,50,55},
	[41033] = {80,100,110,120},
	[41035] = {80,105,115,125},
	[41037] = {85,105,115,125},
	[41039] = {90,100,107,115},
	[41041] = {90,105,112,120},
	[41043] = {95,110,120,130},
	[41045] = {100,120,130,140},
	[41047] = {100,120,130,140},
	[41049] = {105,120,132,145},
	[41051] = {105,125,135,145},
	[41053] = {110,130,140,150},
	[41055] = {120,145,155,165},
	[41057] = {125,145,155,165},
	[41059] = {125,150,160,170},
	[41061] = {125,145,155,165},
	[41063] = {125,145,155,165},
	[41065] = {125,140,142,145},
	[41067] = {125,135,145,155},
	[41069] = {135,150,160,170},
	[41071] = {135,155,165,175},
	[41073] = {125,140,147,155},
	[41075] = {225,140,147,155},
	[41077] = {175,185,190,195},
	[41081] = {150,165,170,175},
	[41083] = {150,165,170,175},
	[41085] = {225,240,247,255},
	[41087] = {235,245,250,255},
	[41089] = {245,265,275,285},
	[41091] = {250,260,265,270},
	[41093] = {255,270,277,285},
	[41095] = {260,280,287,295},
	[41097] = {265,285,292,300},
	[41099] = {265,285,292,300},
	[41101] = {280,285,297,310},
	[41103] = {280,285,297,310},
	[41105] = {280,300,305,310},
	[41201] = {150,150,155,160},
	[41203] = {150,150,152,155},
	[41205] = {155,155,160,165},
	[41207] = {155,175,185,195},
	[41209] = {165,185,195,205},
	[41211] = {170,190,197,205},
	[41213] = {175,195,202,210},
	[41215] = {175,195,202,210},
	[41217] = {175,195,202,210},
	[41219] = {175,175,177,180},
	[41221] = {185,200,210,220},
	[41223] = {190,205,215,225},
	[41225] = {190,205,215,225},
	[41227] = {200,220,230,240},
	[41229] = {200,200,205,210},
	[41231] = {50,70,80,90},
	[41233] = {200,200,205,210},
	[41235] = {215,215,225,235},
	[41237] = {200,200,205,210},
	[41239] = {210,230,240,250},
	[41241] = {215,235,245,255},
	[41243] = {220,240,250,260},
	[41245] = {220,240,250,260},
	[41247] = {65,85,92,100},
	[41249] = {25,25,45,65},
	[41251] = {265,265,285,305},
	[41253] = {300,320,330,340},
	[41255] = {300,320,330,340},
	[41257] = {300,320,330,340},
	[41261] = {250,250,270,290},
	[41263] = {190,190,210,230},
	[41265] = {260,260,275,290},
	[41267] = {300,330,350,370},
	[41269] = {300,330,350,370},
	[41271] = {nil,325,335,345},
	[41273] = {265,265,285,305},
	[41275] = {160,160,180,200},
	[41277] = {220,220,240,260},
	[41279] = {280,280,300,320},
	[41281] = {230,230,252,275},
	[41283] = {nil,175,192,210},
	[41285] = {195,195,217,240},
	[41287] = {290,310,325,340},
	[41303] = {nil,315,322,330},
	[41305] = {nil,260,270,280},
	[41307] = {nil,235,245,255},
	[41309] = {nil,300,310,320},
	[41311] = {nil,270,280,290},
	[41313] = {nil,290,300,310},
	[41315] = {nil,275,285,295},
	[41317] = {nil,320,330,340},
	[41321] = {80,100,110,120},
	[41323] = {100,125,135,145},
	[41325] = {110,130,140,150},
	[41327] = {135,155,165,175},
	[41329] = {160,185,195,205},
	[41331] = {160,180,190,200},
	[41333] = {170,180,190,200},
	[41335] = {80,100,110,120},
	[41337] = {115,135,142,150},
	[41339] = {135,155,165,175},
	[41348] = {255,275,285,295},
	[41350] = {260,280,290,300},
	[41352] = {210,235,245,255},
	[41354] = {210,280,290,300},
	[41356] = {275,275,297,320},
	[41541] = {190,210,220,230},
	[41546] = {200,220,230,240},
	[41548] = {200,220,230,240},
	[41550] = {200,220,230,240},
	[41552] = {200,225,235,245},
	[41554] = {210,235,245,255},
	[41556] = {180,200,210,220},
	[41558] = {200,225,235,245},
	[41560] = {75,95,105,115},
	[41562] = {85,105,115,125},
	[41564] = {100,120,130,140},
	[41566] = {115,120,130,140},
	[41568] = {130,150,160,170},
	[41570] = {145,165,175,185},
	[41572] = {160,180,190,200},
	[41574] = {170,200,210,220},
	[41579] = {190,210,220,230},
	[41581] = {100,120,130,140},
	[41583] = {140,160,170,180},
	[41585] = {170,190,200,210},
	[41587] = {80,160,170,180},
	[41589] = {185,205,215,225},
	[41591] = {180,200,210,220},
	[41601] = {200,205,207,210},
	[41603] = {200,205,207,210},
	[41605] = {200,205,207,210},
	[41607] = {150,155,157,160},
	[41609] = {275,280,282,285},
	[41611] = {260,265,267,270},
	[41613] = {285,290,292,295},
	[41615] = {295,300,302,305},
	[41617] = {275,280,282,285},
	[41619] = {300,310,315,320},
	[41621] = {250,255,257,260},
	[41623] = {175,180,182,185},
	[41625] = {270,275,277,280},
	[41627] = {150,155,157,160},
	[41629] = {175,180,182,185},
	[41631] = {200,205,205,205},
	[41633] = {225,225,227,230},
	[41635] = {235,235,237,240},
	[41637] = {nil,250,252,255},
	[41639] = {nil,250,252,255},
	[41641] = {nil,275,277,280},
	[41643] = {nil,290,292,295},
	[41696] = {300,320,330,340},
	[41698] = {300,320,330,340},
	[41700] = {300,320,330,340},
	[41702] = {300,320,330,340},
	[41704] = {300,320,330,340},
	[41706] = {300,320,330,340},
	[41708] = {290,320,330,340},
	[41710] = {290,320,330,340},
	[41712] = {290,320,330,340},
	[41714] = {250,280,290,300},
	[41716] = {230,260,270,280},
	[41718] = {200,225,237,250},
	[41720] = {240,260,275,290},
	[41722] = {300,300,307,315},
	[41724] = {245,245,265,285},
	[41726] = {105,125,135,145},
	[41728] = {140,160,170,180},
	[41730] = {170,185,195,205},
	[41732] = {85,105,115,125},
	[41734] = {120,140,150,160},
	[41736] = {160,180,190,200},
	[41738] = {200,215,225,235},
	[41740] = {105,135,145,155},
	[41742] = {145,165,175,185},
	[41744] = {200,220,230,240},
	[41746] = {85,105,115,125},
	[41748] = {135,155,165,175},
	[41750] = {185,200,207,215},
	[41752] = {175,190,197,205},
	[41754] = {200,220,230,240},
	[41756] = {205,220,227,235},
	[41758] = {275,275,280,300},
	[41760] = {135,135,137,140},
	[41762] = {270,270,272,275},
	[41764] = {300,320,330,340},
	[41768] = {300,320,330,340},
	[41770] = {235,240,240,240},
	[41774] = {265,275,285,295},
	[41776] = {125,145,155,165},
	[41778] = {nil,310,320,330},
	[41780] = {290,310,320,330},
	[41782] = {285,310,320,330},
	[41784] = {230,260,275,290},
	[41786] = {210,230,240,250},
	[41788] = {300,320,330,340},
	[41790] = {290,320,330,340},
	[41792] = {300,330,340,350},
	[41794] = {285,320,330,340},
	[41796] = {300,330,340,350},
	[41798] = {300,320,325,330},
	[41800] = {300,330,340,350},
	[41802] = {300,325,335,345},
	[41804] = {300,320,330,340},
	[41806] = {300,320,330,340},
	[41808] = {300,325,332,340},
	[41821] = {300,330,345,360},
	[45054] = {35,75,95,115},
	[45057] = {75,90,97,105},
	[45063] = {75,100,120,140},
	[45066] = {75,150,167,185},
	[45069] = {75,nil,nil,nil},
	[45451] = {300,350,362,375},
	[45453] = {300,300,300,300},
	[45455] = {300,320,330,340},
	[45457] = {300,300,300,300},
	[45459] = {300,300,300,300},
	[45461] = {300,300,300,300},
	[45463] = {300,300,300,300},
	[45467] = {300,325,337,350},
	[45469] = {300,325,337,350},
	[45471] = {300,325,337,350},
	[45473] = {300,320,330,340},
	[45475] = {300,320,330,340},
	[45477] = {300,320,330,340},
	[45479] = {300,320,330,340},
	[45481] = {300,320,330,340},
	[45483] = {300,320,330,340},
	[45485] = {300,300,300,300},
	[45487] = {300,325,337,350},
	[45611] = {1,290,300,310},
	[45625] = {300,300,300,300},
	[45627] = {200,240,260,280},
	[45878] = {1,285,310,335},
	[45882] = {1,325,350,375},
	[45989] = {300,315,322,330},
	[46064] = {1,10,12,15},
	[46066] = {125,145,155,165},
	[46068] = {180,200,210,220},
	[46072] = {50,100,110,120},
	[46073] = {115,135,145,155},
	[46074] = {75,100,112,125},
	[46075] = {160,180,190,200},
	[46077] = {230,250,260,270},
	[46085] = {300,300,300,300},
	[46600] = {100,275,295,310},
	[46608] = {250,250,260,270},
	[46610] = {250,270,280,290},
	[46620] = {200,215,220,225},
	[46621] = {200,215,220,225},
	[46622] = {200,215,220,225},
	[46623] = {205,225,230,235},
	[46624] = {210,235,240,245},
	[46625] = {210,225,230,235},
	[46626] = {220,220,220,220},
	[46627] = {220,220,220,220},
	[46628] = {225,225,225,225},
	[46629] = {225,225,225,225},
	[46630] = {230,230,230,230},
	[46631] = {230,230,230,230},
	[46633] = {230,230,230,230},
	[46634] = {235,235,235,235},
	[46635] = {230,230,230,230},
	[46636] = {225,225,225,225},
	[46637] = {225,225,225,225},
	[46638] = {230,230,230,230},
	[46639] = {205,205,205,205},
	[46640] = {210,210,210,210},
	[46641] = {205,205,205,205},
	[46642] = {205,205,205,205},
	[46643] = {200,200,200,200},
	[46644] = {200,200,200,200},
	[46645] = {265,265,265,265},
	[46646] = {265,265,265,265},
	[46647] = {270,270,270,270},
	[46648] = {260,260,260,260},
	[46649] = {260,260,260,260},
	[46650] = {265,265,265,265},
	[46651] = {225,260,267,275},
	[46652] = {300,320,330,340},
	[46653] = {295,300,300,300},
	[46654] = {300,300,300,300},
	[46655] = {295,300,300,300},
	[46656] = {300,300,300,300},
	[46657] = {300,320,330,340},
	[46659] = {300,300,300,300},
	[46660] = {270,280,285,290},
	[46661] = {300,320,330,340},
	[46662] = {205,225,230,235},
	[46663] = {30,60,62,65},
	[46664] = {75,90,95,100},
	[46665] = {120,140,145,150},
	[46666] = {180,190,195,200},
	[46667] = {300,315,322,330},
	[46695] = {245,245,245,245},
	[47015] = {270,285,290,295},
	[47016] = {280,285,290,295},
	[47017] = {270,290,291,295},
	[47018] = {280,290,291,295},
	[47019] = {285,290,291,295},
	[47020] = {275,290,291,295},
	[47021] = {300,320,330,340},
	[47022] = {300,320,330,340},
	[47023] = {300,320,330,340},
	[47024] = {300,320,330,340},
	[47025] = {300,320,330,340},
	[47026] = {300,320,330,340},
	[47027] = {120,145,157,170},
	[47028] = {120,145,157,170},
	[47029] = {290,300,310,320},
	[47030] = {290,300,310,320},
	[47031] = {290,300,310,320},
	[47032] = {275,300,312,325},
	[47033] = {285,300,310,320},
	[47034] = {275,300,310,320},
	[47035] = {300,300,300,300},
	[47101] = {10,30,45,60},
	[47103] = {10,40,55,70},
	[49551] = {300,325,345,365},
	[51924] = {1,280,305,330},
	[52576] = {1,300,325,350},
	[52747] = {290,310,320,330},
	[52749] = {290,310,320,330},
	[54001] = {290,310,320,330},
	[54003] = {290,310,320,330},
	[54005] = {300,325,337,350},
	[54007] = {300,300,300,300},
	[54009] = {300,325,337,350},
	[54011] = {300,300,300,300},
	[54013] = {300,300,300,300},
	[54015] = {300,300,300,300},
	[57008] = {265,nil,nil,nil},
	[57010] = {255,255,255,255},
	[57012] = {300,300,300,300},
	[57014] = {300,300,300,300},
	[57016] = {300,300,300,300},
	[57018] = {300,300,300,300},
	[57020] = {300,315,330,345},
	[57022] = {300,320,330,340},
	[57024] = {300,315,330,345},
	[57026] = {300,320,330,340},
	[57047] = {300,300,300,300},
	[57049] = {300,300,300,300},
	[57051] = {300,300,300,300},
	[57111] = {300,315,322,330},
	[57113] = {275,300,310,320},
	[57115] = {300,320,330,340},
	[57129] = {300,315,322,330},
	[57131] = {300,315,322,330},
	[57163] = {25,65,85,105},
	[57166] = {90,115,127,140},
	[57169] = {140,170,185,200},
	[57172] = {185,210,222,235},
	[57175] = {240,265,277,290},
	[57178] = {300,325,337,350},
	[57181] = {300,325,337,350},
	[57187] = {300,325,337,350},
	[57189] = {300,325,337,350},
	[57191] = {300,325,337,350},
	[57193] = {300,325,337,350},
	[57196] = {300,325,337,350},
	[57518] = {300,300,300,300},
	[57555] = {300,315,322,330},
	[57557] = {300,315,322,330},
	[57601] = {300,300,300,300},
	[57603] = {300,300,300,300},
	[57605] = {300,300,300,300},
	[57607] = {300,300,300,300},
	[57609] = {300,300,300,300},
	[57611] = {300,300,300,300},
	[57613] = {300,300,300,300},
	[57615] = {300,300,300,300},
	[57617] = {300,320,330,340},
	[57619] = {300,320,330,340},
	[57621] = {300,320,330,340},
	[57623] = {300,320,330,340},
	[57625] = {300,320,330,340},
	[57627] = {300,320,330,340},
	[57629] = {300,320,330,340},
	[57631] = {300,320,330,340},
	[57633] = {300,300,300,300},
	[58044] = {175,215,235,255},
}

function ATSW_SkillUps(Name, SpellID)
	-- re-detect AtlasLoot in case it loaded after our first OnShow
	if not ATSW_AtlasLoot then
		ATSW_AtlasLoot = ATSW_CheckForAtlasLootLoaded()
	end

	if not ATSW_AtlasLoot then
		return
	end

	ATSW_BuildAtlasLootSkillIndex()

	if not ATSW_AtlasLootSkillIndex then
		return
	end

	local cacheKey = SpellID or Name

	if ATSWSkillUpCache[cacheKey] then
		local C = ATSWSkillUpCache[cacheKey]

		return C[1], C[2], C[3], C[4]
	end

	local res

	-- 1) match by numeric spell/enchant ID (language independent)
	--    (enchanting hits via R.Link eXXXX; tradeskills have no ID source in this client,
	--     but the zhCN bridge by ID is kept as a redundant path)
	if SpellID then
		res = ATSW_AtlasLootSkillIndex[SpellID]
		if not res and ATSW_CnSkillUpByID then
			res = ATSW_CnSkillUpByID[SpellID]
		end
	end

	-- 2) fallback: match by (stripped) name. This is what makes tradeskills work on a
	--    Chinese client: the new AtlasLoot 3.3.8 stores English recipe names only, but the
	--    zhCN bridge (ATSW_CnSkillUpByName) is regenerated from AtlasLoot 3.3.8's
	--    Database/Crafting.lua + Locale/locale.cn.lua, with a curated override for the
	--    server-localized Survival recipes that the locale file does not translate.
	if not res and Name then
		local nm = string.lower(Name)
		-- strip any color/link codes the game might attach to the name
		nm = string.gsub(nm, '|c%x%x%x%x%x%x%x%x', '')
		nm = string.gsub(nm, '|r', '')
		nm = string.gsub(nm, '|H[^|]*|h', '')
		nm = string.gsub(nm, '|h', '')
		res = ATSW_AtlasLootNameIndex[nm]
		if not res and ATSW_CnSkillUpByName then
			res = ATSW_CnSkillUpByName[nm]
		end
	end

	if res then
		ATSWSkillUpCache[cacheKey] = res

		if ATSW_SKILLUP_DEBUG and not ATSW_SkillUpSeen[cacheKey] then
			ATSW_SkillUpSeen[cacheKey] = true
			ATSW_SkillUpDebug("match OK: name=%s spellID=%s -> %s|%s|%s|%s",
				tostring(Name), tostring(SpellID), tostring(res[1]), tostring(res[2]), tostring(res[3]), tostring(res[4]))
		end

		return res[1], res[2], res[3], res[4]
	end

	if ATSW_SKILLUP_DEBUG and not ATSW_SkillUpSeen[cacheKey] then
		ATSW_SkillUpSeen[cacheKey] = true
		-- Show what the (stripped) name looks like and whether the zhCN bridge has it,
		-- so we can tell a name mismatch from a missing entry.
		local stripped = string.lower(tostring(Name))
		stripped = string.gsub(stripped, '|c%x%x%x%x%x%x%x%x', '')
		stripped = string.gsub(stripped, '|r', '')
		stripped = string.gsub(stripped, '|H[^|]*|h', '')
		stripped = string.gsub(stripped, '|h', '')
		local bridgeHit = ATSW_CnSkillUpByName and (ATSW_CnSkillUpByName[stripped] ~= nil)
		ATSW_SkillUpDebug("NO match: name=%s spellID=%s strippedNm=[%s] bridgeHit=%s idxSize=%d",
			tostring(Name), tostring(SpellID), stripped, tostring(bridgeHit),
			(function() local n=0; for _ in pairs(ATSW_AtlasLootSkillIndex or {}) do n=n+1 end; return n end)())
	end
end

function ATSW_CompareSkill(Name, SpellID)
	local SU1, SU2, SU3, SU4 = ATSW_SkillUps(Name, SpellID)
	
	SU1 = SU1 or 0
	SU2 = SU2 or 0
	SU3 = SU3 or 0
	SU4 = SU4 or 0
	
	if SU1 then
		return SU1*20+(SU2-SU1)+(SU3-SU2)+(SU4-SU3) -- Works somehow
	else
		return 0
	end
end

function ATSW_CompareDifficultyUsingExternalData(Left, Right)
	return (ATSW_TypeToNumber(Left.Type) == ATSW_TypeToNumber(Right.Type)) and (ATSW_CompareSkill(Left.Name, ATSW_GetRecipeSpellID(Left)) > ATSW_CompareSkill(Right.Name, ATSW_GetRecipeSpellID(Right)))
end