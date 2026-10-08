if not Cursive.nampower then
	return
end

local L = AceLibrary("AceLocale-2.2"):new("Cursive")
local curseCommands = L["|cffffcc00Cursive:|cffffaaaa Commands:"]
local priorityChoices = L["|cffffcc00Priority choices:"]
local curseOptions = L["|cffffcc00Options (separate with ,):"]
local UnitXPLoad = (function()
	if pcall(UnitXP, "nop", "nop") then 
		return 1
	else
		return 0
	end
end)

local commandOptions = {
	warnings = L["Display text warnings when a curse fails to cast."],
	resistsound = L["Play a sound when a curse is resisted."],
	expiringsound = L["Play a sound when a curse is about to expire."],
	allowooc = L["Allow out of combat targets to be multicursed.  Would only consider using this solo to avoid potentially griefing raids/dungeons by pulling unintended mobs."],
	minhp = L["Minimum HP for a target to be considered.  Example usage minhp=10000. "],
	refreshtime = L["Time threshold at which to allow refreshing a curse.  Default is 0 seconds."],
	priotarget = L["Always prioritize current target when choosing target for multicurse.  Does not affect 'curse' command."],
	ignoretarget = L["Ignore the current target when choosing target for multicurse.  Does not affect 'curse' command."],
	playeronly = L["Only choose players and ignore npcs when choosing target for multicurse.  Does not affect 'curse' command."],
	istapped = L["Only choose mobs tagged by other players when choosing target for multicurse.  Does not affect 'curse' command."],
	name = L["Filter targets by name. Can be a partial match.  If no match is found, the command will do nothing."],
	ignorespellid = L["Ignore targets with the specified spell id already on them. Useful for ignoring targets that already have a shared debuff."],
	ignorespelltexture = L["Ignore targets with the specified spell texture already on them. Useful for ignoring targets that already have a shared debuff."],
	malediction = L["For Warlocks with the Malediction talent: when checking if Curse of Recklessness, Curse of the Elements, or Curse of Shadow is already on a target, check for Curse of Agony instead. Default is 1 (enabled). Set malediction=0 to disable and check for the original curse."],
	
	--新增commands条件 by 武藤纯子酱 2025.8.28
	maxhp = L["Maximum HP for a target to be considered. Example usage maxhp=50000."],
	maxhppercent = L["Maximum health percentage threshold. Example: maxhppercent=50 (Targets with HP% ≤ 50%%)"],
	minhppercent = L["Minimum health percentage threshold. Example: minhppercent=50 (Targets with HP% ≥ 50%%)"],
	isboss = L["Filter boss-type targets only"],
	distance = L["Target distance. Without UnitXP, 1/2/3 = 28/11.11/9.9 yards; with UnitXP, the value is used as yards."],
	buffids = L["Filter targets with specific buff IDs. Example: buffids=789"],	
	buffnames = L["Filter targets with specific buff name. Example: buffnames='Power Word: Shield'"],	
	notbehind = L["Filter units is behind."],
}

local commands = {
	["curse"] = L["/cursive curse <spellName:str>|<guid?:str>|<options?:List<str>>: Casts spell if not already on target/guid"],
	["multicurse"] = L["/cursive multicurse <spellName:str>|<priority?:str>|<options?:List<str>>: Picks target based on priority and casts spell if not already on target"],
	["target"] = L["/cursive target <spellName:str>|<priority?:str>|<options?:List<str>>: Targets unit based on priority if spell in range and not already on target"],
}

local PRIORITY_HIGHEST_HP = "HIGHEST_HP"
local PRIORITY_LOWEST_HP = "LOWEST_HP"
local PRIORITY_RAID_MARK = "RAID_MARK"
local PRIORITY_RAID_MARK_SQUARE = "RAID_MARK_SQUARE"
local PRIORITY_INVERSE_RAID_MARK = "INVERSE_RAID_MARK"
local PRIORITY_HIGHEST_HP_RAID_MARK = "HIGHEST_HP_RAID_MARK"
local PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE = "HIGHEST_HP_RAID_MARK_SQUARE"
local PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK = "HIGHEST_HP_INVERSE_RAID_MARK"
-- 新增优先级定义 by 武藤纯子酱 2025.8.28
local PRIORITY_BOSS_RAID_MARK = "BOSS_RAID_MARK"
local PRIORITY_BOSS_HIGHEST_HP = "BOSS_HIGHEST_HP"

local priorities = {
	[PRIORITY_HIGHEST_HP] = L["Target with the highest HP."],
	[PRIORITY_LOWEST_HP] = L["Target with the lowest HP."],
	[PRIORITY_RAID_MARK] = L["Target with the highest raid mark."],
	[PRIORITY_RAID_MARK_SQUARE] = L["Target with the highest raid mark with Cross set to -1 and Skull set to -2 (Square highest prio at 6)."],
	[PRIORITY_INVERSE_RAID_MARK] = L["Target with the lowest raid mark."],
	[PRIORITY_HIGHEST_HP_RAID_MARK] = L["Target with the highest HP and raid mark."],
	[PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE] = L["Same as HIGHEST_HP_RAID_MARK but with RAID_MARK_SQUARE mark prio."],
	[PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK] = L["Same as HIGHEST_HP_RAID_MARK but with INVERSE_RAID_MARK mark prio."],
	-- 新增优先级定义 by 武藤纯子酱 2025.8.28
	[PRIORITY_BOSS_RAID_MARK] = L["Target BOSS with the highest raid mark."],
	[PRIORITY_BOSS_HIGHEST_HP] = L["Target BOSS with the highest HP."],
}

local curseNoTarget = L["|cffffcc00Cursive:|cffffaaaa Couldn't find a target to curse."]

local function parseOptions(optionsStr)
	local options = {  }

	if optionsStr then
		for option, _ in pairs(commandOptions) do
			-- special case for minhp as it takes a param
			if option == "minhp" then
				local _, _, minHp = string.find(optionsStr, "minhp=(%d+)")
				if minHp then
					options["minhp"] = tonumber(minHp)
				end
			elseif option == "refreshtime" then
				local _, _, refreshTime = string.find(optionsStr, "refreshtime=(%d+)")
				if refreshTime then
					options["refreshtime"] = tonumber(refreshTime)
				end
			elseif option == "name" then
				local _, _, name = string.find(optionsStr, "name=([%w%s]+)")
				if name then
					options["name"] = name
				end
			elseif option == "ignorespellid" then
				local _, _, spellId = string.find(optionsStr, "ignorespellid=(%d+)")
				if spellId then
					options["ignorespellid"] = tonumber(spellId)
				end
			elseif option == "ignorespelltexture" then
				local _, _, texture = string.find(optionsStr, "ignorespelltexture=([%w_]+)")
				if texture then
					options["ignorespelltexture"] = texture
				end
			elseif option == "malediction" then
				local _, _, maledictionVal = string.find(optionsStr, "malediction=(%d)")
				if maledictionVal then
					options["malediction"] = tonumber(maledictionVal)
				end
			elseif option == "maxhp" then  --新增最大血量过滤 by 武藤纯子酱 2025.8.28
				local _, _, maxHp = string.find(optionsStr, "maxhp=(%d+)")
				if maxHp then
					options["maxhp"] = tonumber(maxHp)
				end			
			elseif option == "maxhppercent" then  --新增小于某血量百分比过滤 by 武藤纯子酱 2025.8.28
				local _, _, maxHpPercent = string.find(optionsStr, "maxhppercent=(%d+)")
				if maxHpPercent then
					options["maxhppercent"] = tonumber(maxHpPercent)
				end
			elseif option == "minhppercent" then  --新增大于某血量百分比过滤 by 武藤纯子酱 2025.8.28
				local _, _, minHpPercent = string.find(optionsStr, "minhppercent=(%d+)")
				if minHpPercent then
					options["minhppercent"] = tonumber(minHpPercent)
				end
			elseif string.find(optionsStr, "isboss") then --新增目标为BOSS过滤 by 武藤纯子酱 2025.8.28
				local _, _, isBoss = string.find(optionsStr, "isboss=([%w%s]+)")
				if isBoss then
					options["isboss"] = true
				end
			elseif string.find(optionsStr, "distance") then --新增距离过滤 by 武藤纯子酱 2025.8.28
				local _, _, val = string.find(optionsStr, "distance=(%d+)") -- 修复：支持多位数字（码数） by 武藤纯子酱 2026.9.17
				if val then 
					options["distance"] = tonumber(val) 
				end   
			elseif option == "buffids" then  -- 新增BUFF ID过滤 by 武藤纯子酱 2025.8.28
				local _, _, ids = string.find(optionsStr, "buffids=([%d,]+)")
				if ids then
					options["buffids"] = tonumber(ids)
				end
			elseif option == "buffnames" then -- 新增BUFF名字过滤 by 武藤纯子酱 2025.8.28
				-- 匹配三种格式：引号包裹、无引号、带空格的情况
				local pattern = "buffnames%s*=%s*([\"']?)([^;]-)%1"
				local _, _, quote, name = string.find(optionsStr, pattern)
				if name then
					-- 去除首尾空格同时保留技能名中的特殊字符
					local trimmedName = string.gsub(name, "^%s*(.-)%s*$", "%1")
					options["buffnames"] = trimmedName
				end
			elseif string.find(optionsStr, "notbehind") then --新增目标是否在身后过滤 by 武藤纯子酱 2025.8.28
				local _, _, notbehind = string.find(optionsStr, "notbehind=([%w%s]+)")
				if notbehind then
					options["notbehind"] = true
				end				
			elseif string.find(optionsStr, option) then
				options[option] = true
			end
		end
	end

	return options
end

local function handleSlashCommands(msg, editbox)
	if not msg or msg == "" then
		DEFAULT_CHAT_FRAME:AddMessage(curseCommands)
		for _, description in pairs(commands) do
			DEFAULT_CHAT_FRAME:AddMessage(description)
		end
		DEFAULT_CHAT_FRAME:AddMessage(priorityChoices)
		for priority, description in pairs(priorities) do
			DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00" .. priority .. "|R: " .. description)
		end

		DEFAULT_CHAT_FRAME:AddMessage(curseOptions)
		for option, description in pairs(commandOptions) do
			DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00" .. option .. "|R: " .. description)
		end
		return
	end
	-- get first word in string
	local _, _, command, args = string.find(msg, "(%w+) (.*)")
	if command == "curse" then
		local spellName, targetedGuid, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Curse(spellName, targetedGuid, options)
	elseif command == "multicurse" then
		local spellName, priority, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Multicurse(spellName, priority, options)
	elseif command == "target" then
		local spellName, priority, optionsStr = Cursive.utils.strsplit("|", args)
		local options = parseOptions(optionsStr)
		Cursive:Target(spellName, priority, options)
	else
		DEFAULT_CHAT_FRAME:AddMessage(L["|cffffcc00Cursive:|cffffaaaa Unknown command."])
		DEFAULT_CHAT_FRAME:AddMessage(curseCommands)
		for _, description in pairs(commands) do
			DEFAULT_CHAT_FRAME:AddMessage(description)
		end
	end
end

local crowdControlledSpellIds = {
	[700] = { name = L["sleep"], rank = 1, duration = 20 },
	[1090] = { name = L["sleep"], rank = 2, duration = 30 },
	[2937] = { name = L["sleep"], rank = 3, duration = 40 },

	[339] = { name = L["entangling roots"], rank = 1, duration = 12 },
	[1062] = { name = L["entangling roots"], rank = 2, duration = 15 },
	[5195] = { name = L["entangling roots"], rank = 3, duration = 18 },
	[5196] = { name = L["entangling roots"], rank = 4, duration = 21 },
	[9852] = { name = L["entangling roots"], rank = 5, duration = 24 },
	[9853] = { name = L["entangling roots"], rank = 6, duration = 27 },

	[2637] = { name = L["hibernate"], rank = 1, duration = 20 },
	[18657] = { name = L["hibernate"], rank = 2, duration = 30 },
	[18658] = { name = L["hibernate"], rank = 3, duration = 40 },

	[1425] = { name = L["shackle undead"], rank = 1, duration = 30 },
	[9486] = { name = L["shackle undead"], rank = 2, duration = 40 },
	[10956] = { name = L["shackle undead"], rank = 3, duration = 50 },

	-- polymorph
	[118] = { name = L["polymorph"], rank = L["Rank 1"], duration = 20 },
	[12824] = { name = L["polymorph"], rank = L["Rank 2"], duration = 30 },
	[12825] = { name = L["polymorph"], rank = L["Rank 3"], duration = 40 },
	[12826] = { name = L["polymorph"], rank = L["Rank 4"], duration = 50 },

	[28270] = { name = L["polymorph: cow"], rank = L["Rank 1"], duration = 50 },
	[28271] = { name = L["polymorph: turtle"], rank = L["Rank 1"], duration = 50 },
	[28272] = { name = L["polymorph: pig"], rank = L["Rank 1"], duration = 50 },

	[2878] = { name = L["turn undead"], rank = 1, duration = 10 },
	[5627] = { name = L["turn undead"], rank = 2, duration = 15 },
	[10326] = { name = L["turn undead"], rank = 3, duration = 20 },

	[2094] = { name = L["blind"], rank = 1, duration = 10 },
	[21060] = { name = L["blind"], rank = 1, duration = 10 },

	[6770] = { name = L["sap"], rank = 1, duration = 25 },
	[2070] = { name = L["sap"], rank = 2, duration = 35 },
	[11297] = { name = L["sap"], rank = 3, duration = 45 },

	[1776] = { name = L["gouge"], rank = 1, duration = 4 },
	[1777] = { name = L["gouge"], rank = 2, duration = 4 },
	[8629] = { name = L["gouge"], rank = 3, duration = 4 },
	[11285] = { name = L["gouge"], rank = 4, duration = 4 },
	[11286] = { name = L["gouge"], rank = 5, duration = 4 },

	[3355] = { name = L["freezing trap"], rank = 1, duration = 10 },
	[14308] = { name = L["freezing trap"], rank = 2, duration = 15 },
	[14309] = { name = L["freezing trap"], rank = 3, duration = 20 },

	[710] = { name = L["banish"], rank = 1, duration = 30 },
	[18647] = { name = L["banish"], rank = 2, duration = 30 },

	-- mind control effects
	[28410] = { name = "Chains of Kel'Thuzad" }, -- we aren't casting these, name doesn't matter
	[7621] = { name = "Arugal's Curse" },
	[24261] = { name = "Brain Wash" },
	[12888] = { name = "Cause Insanity" },
	[24327] = { name = "Cause Insanity" },
	[26079] = { name = "Cause Insanity" },
	[24327] = { name = "Cause Insanity" },
	[23174] = { name = "Chromatic Mutation" },
	[25806] = { name = "Creature of Nightmare" },
	[23298] = { name = "Demonic Doom" },
	[7645] = { name = "Dominate Mind" },
	[14515] = { name = "Dominate Mind" },
	[15859] = { name = "Dominate Mind" },
	[20604] = { name = "Dominate Mind" },
	[20740] = { name = "Dominate Mind" },
	[17405] = { name = "Domination" },
	[3442] = { name = "Enslave" },
	[13181] = { name = "Gnomish Mind Control Cap" },
	[26740] = { name = "Gnomish Mind Control Cap" },
	[12483] = { name = "Hex of Jammal'an" },
	[25772] = { name = "Mental Domination" },
	[7967] = { name = "Naralex's Nightmare" },
	[19469] = { name = "Poison Mind" },
	[17244] = { name = "Possess" },
	[22667] = { name = "Shadow Command" },
	[20668] = { name = "Sleepwalk" },
	[785] = { name = "True Fulfillment" },
	[26195] = { name = "Whisperings of C'Thun" },
	[26197] = { name = "Whisperings of C'Thun" },
	[26198] = { name = "Whisperings of C'Thun" },
	[26258] = { name = "Whisperings of C'Thun" },
	[26259] = { name = "Whisperings of C'Thun" },
	[24178] = { name = "Will of Hakkar" },

	-- immunity effects
	[642] = { name = "Divine Shield" },
	[1020] = { name = "Divine Shield" },
	[13874] = { name = "Divine Shield" },
	[5573] = { name = "Divine Protection" },
	[13007] = { name = "Divine Protection" },
	[6356] = { name = "Spell Immunity" },
	[6724] = { name = "Light of Elune" },
	[7121] = { name = "Anti-Magic Shield" },
	[19645] = { name = "Anti-Magic Shield" },
	[24021] = { name = "Anti-Magic Shield" },
	[8361] = { name = "Purity" },
	[8611] = { name = "Phase Shift" },
	[45713] = { name = "Phase Shift" },
	[9438] = { name = "Arcane Bubble" },
	[11958] = { name = "Ice Block" },
	[12843] = { name = "Mordresh's Shield" },
	[21892] = { name = "Arcane Protection" },
	[51096] = { name = "Worgen Dimension" },
	[51228] = { name = "Invulnerability" },
	[52010] = { name = "Pending Detonation" },
	[53225] = { name = "Ward of Vorgendor" },
	[57644] = { name = "Veil of Vorgendor" },
}

local spellImmuneGuids = {
  ["0xF1300030A9014A44"] = true, -- Blackwing Spellbinder
  ["0xF1300030A911F78C"] = true, -- Blackwing Spellbinder
  ["0xF1300030A911F78D"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014EFE"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014F08"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014E75"] = true, -- Blackwing Spellbinder
  ["0xF1300030A9014E6D"] = true, -- Blackwing Spellbinder
}

local function isMobCrowdControlled(guid)
	local auras = GetUnitField(guid, "aura") or {}
	for i, spellId in pairs(auras) do
		if crowdControlledSpellIds[spellId] then
			return true
		end
	end
	return false
end

local function isMobSpellImmune(guid)
	return spellImmuneGuids[guid] and true or false
end

local function GetSquarePrioRaidTargetIndex(guid)
	local index = GetRaidTargetIndex(guid)
	if index == 7 then
		return 0 -- cross becomes 0
	elseif index == 8 then
		return -1 -- skull becomes -1
	elseif index == 0 then
		return -2 -- nomark becomes -2
	end
	return index or -2
end

local function hasSpellId(guid, ignoreSpellId)
	local auras = GetUnitField(guid, "aura")
	for i, spellId in pairs(auras) do
		if spellId == ignoreSpellId then
			return true
		end
	end
	return false
end

local function hasSpellTexture(guid, ignoreTexture)
	local auras = GetUnitField(guid, "aura") -- 修改通过Nampower API识别 by 武藤纯子酱 2026.3.31
	for i, spellId in pairs(auras) do
		if spellId then
			local okIconId, iconId = pcall(GetSpellRecField, spellId, "spellIconID")
			if okIconId and iconId and iconId > 0 then
				local okTex, texture = pcall(GetSpellIconTexture, iconId)
				if okTex and type(texture) == "string" and string.find(texture, ignoreTexture) then
					return true
				end
			end
		end
	end
	return false
end

-- 新增：距离选项换算。无UnitXP时 1/2/3 为档位(28/11.11/9.9码)；有UnitXP时按码数处理 by 武藤纯子酱 2026.9.17
local distanceTiers = { 28, 11.11, 9.9 }
local function GetDistanceThreshold(value)
	if UnitXPLoad == 0 and distanceTiers[value] then
		return distanceTiers[value]
	end
	return value
end

local function passedOptionFilters(guid, options)
	-- 新增 by 武藤纯子酱 2025.8.28
	local distance = Cursive:GetDistanceBand(guid)	
	local playerGUID = GetUnitGUID("player")

	if options["name"] then
		local name = UnitName(guid)
		if not string.find(name, options["name"]) then
			return false
		end
	end
	if options["ignorespellid"] then
		if hasSpellId(guid, options["ignorespellid"]) then
			return false
		end
	end
	if options["ignorespelltexture"] then
		if hasSpellTexture(guid, options["ignorespelltexture"]) then
			return false
		end
	end
	if options["playeronly"] and not UnitIsPlayer(guid) then
		return false
	end
	if options["istapped"] and not UnitIsTapped(guid) then
		return false
	end	
	--新增目标为BOSS过滤 by 武藤纯子酱 2025.8.28
	if options["isboss"] and not isBossClassification(guid) then
		return false
	end   
	--新增最大血量过滤 by 武藤纯子酱 2025.8.28
	if options["maxhp"] then
		local hp = UnitHealth(guid)
		if hp > options["maxhp"] then
			return false
		end
	end
	--新增小于某血量百分比过滤 by 武藤纯子酱 2025.8.28
	if options["maxhppercent"] then
		local maxHp = UnitHealthMax(guid)
		local currentHp = UnitHealth(guid)
		if (currentHp / maxHp * 100) > options["maxhppercent"] then
			return false
		end
	end
	--新增大于某血量百分比过滤 by 武藤纯子酱 2025.8.28
	if options["minhppercent"] then
		local maxHp = UnitHealthMax(guid)
		local currentHp = UnitHealth(guid)
		if (currentHp / maxHp * 100) < options["minhppercent"] then
			return false
		end
	end
	--新增距离过滤 by 武藤纯子酱 2025.8.28
	-- 无UnitXP：1/2/3 按档位(28/11.11/9.9码)；有UnitXP：按码数。由GetDistanceBand给出对应距离 by 武藤纯子酱 2026.9.17
	if options["distance"] then
		local threshold = GetDistanceThreshold(options["distance"])
		if not distance or distance > threshold then
			return false
		end
	end
	-- 新增BUFF ID过滤 by 武藤纯子酱 2025.8.28
	if options["buffids"] and not GetUnitBuffID(guid, options["buffids"]) then
		return false
	end
	-- 新增BUFF名字过滤 by 武藤纯子酱 2025.8.28
	if options["buffnames"] and not GetUnitBuffByName(guid, options["buffnames"]) then
		return false
	end	
	--新增目标是否在身后过滤 by 武藤纯子酱 2025.8.28
	if options["notbehind"] and UnitXP("behind", guid, "player") then
		return false
	end	
	return true
end

local function pickTarget(selectedPriority, lowercaseSpellNameNoRank, checkRange, options)
	-- Curse the target that best matches the selected priority
	local highestPrimaryValue = -10
	local highestSecondaryValue = -10
	local targetedGuid = nil

	if selectedPriority == PRIORITY_LOWEST_HP then
		highestPrimaryValue = 999999999999 -- should be bigger than any mob hp
	end

	local minHp = options["minhp"]
	local ignoreInFight = options["allowooc"]
	local refreshTime = options["refreshtime"]
	--新增 by 武藤纯子酱 2025.8.28
	local maxHp = options["maxhp"]
	local maxHpPercent = options["maxhppercent"]
	local minHpPercent = options["minhppercent"]

	local currentTargetGuid = GetUnitGUID("target")

	local seenRaidMark = nil -- if we have seen a raid mark

	for guid, time in pairs(Cursive.core.guids) do
		-- apply filters
		local shouldDisplay = Cursive:ShouldDisplayGuid(guid)
		-- check if target displayed
		if shouldDisplay then
			if not options["ignoretarget"] or guid ~= currentTargetGuid then
				-- check if in combat already or player is actively targeting the mob
				if ignoreInFight or Cursive.filter.infight(guid) or guid == currentTargetGuid then
					if passedOptionFilters(guid, options) then
						local passedRangeCheck = false
						if IsSpellInRange then
							local result
							if Cursive.curses.isDruid and string.find(lowercaseSpellNameNoRank, L["faerie fire (feral)"]) then -- 修复多语言支持 by 武藤纯子酱 2025.10.2
								-- IsSpellInRange doesn't work with Faerie Fire (Feral), use spellid instead
								result = IsSpellInRange(17392, guid)
							else
								result = IsSpellInRange(lowercaseSpellNameNoRank, guid)
							end
							if result == -1 then
								passedRangeCheck = checkRange == false or CheckInteractDistance(guid, 4) -- fallback to old range check
							else
								-- 0 or 1
								passedRangeCheck = result == 1
							end
						else
							-- prioritize targets within 28 yards first to improve chances of being in range
							passedRangeCheck = checkRange == false or CheckInteractDistance(guid, 4)
						end
						if passedRangeCheck then
							-- check if the target has the curse
              if not Cursive.curses:HasCurse(lowercaseSpellNameNoRank, guid, refreshTime, options["malediction"]) and
                  not isMobCrowdControlled(guid) and
                  not isMobSpellImmune(guid) then
								local mobHp = UnitHealth(guid)
								-- HP value checks
								local hpValid = true
								--修改 by 武藤纯子酱 2025.8.28
								local mobMaxHp = UnitHealthMax(guid)
								local hpPercent = (mobHp / mobMaxHp) * 100
								if minHp and mobHp < minHp then hpValid = false end
								if maxHp and mobHp > maxHp then hpValid = false end
								if minHpPercent and hpPercent < minHpPercent then hpValid = false end
								if maxHpPercent and hpPercent > maxHpPercent then hpValid = false end
								if hpValid then --修改 by 武藤纯子酱 2025.8.28
									local primaryValue = -1
									local secondaryValue = -1
									if options["priotarget"] and guid == currentTargetGuid then
										seenRaidMark = true
										primaryValue = 999999999999 -- should be bigger than any mob hp
									elseif selectedPriority == PRIORITY_HIGHEST_HP then
										primaryValue = UnitHealth(guid) or 0
									elseif selectedPriority == PRIORITY_LOWEST_HP then
										primaryValue = UnitHealth(guid) or 999999999999
									elseif selectedPriority == PRIORITY_RAID_MARK then
										primaryValue = GetRaidTargetIndex(guid) or 0
									elseif selectedPriority == PRIORITY_RAID_MARK_SQUARE then
										primaryValue = GetSquarePrioRaidTargetIndex(guid)
									elseif selectedPriority == PRIORITY_INVERSE_RAID_MARK then
										primaryValue = -1 * (GetRaidTargetIndex(guid) or 9)
									elseif selectedPriority == PRIORITY_HIGHEST_HP_RAID_MARK then
										secondaryValue = GetRaidTargetIndex(guid) or 0
										if secondaryValue > 0 and not seenRaidMark then
											highestPrimaryValue = -10 -- reset highestPriorityValue if this is the first raid mark we've seen
											seenRaidMark = true
										end
										primaryValue = UnitHealth(guid) or 0
									elseif selectedPriority == PRIORITY_HIGHEST_HP_RAID_MARK_SQUARE then
										secondaryValue = GetSquarePrioRaidTargetIndex(guid)
										if secondaryValue > -2 and not seenRaidMark then
											highestPrimaryValue = -10 -- reset highestPriorityValue if this is the first raid mark we've seen
											seenRaidMark = true
										end
										primaryValue = UnitHealth(guid) or 0
									elseif selectedPriority == PRIORITY_HIGHEST_HP_INVERSE_RAID_MARK then
										secondaryValue = -1 * (GetRaidTargetIndex(guid) or 9)
										if secondaryValue > -9 and not seenRaidMark then
											highestPrimaryValue = -10 -- reset highestPriorityValue if this is the first raid mark we've seen
											seenRaidMark = true
										end
										primaryValue = UnitHealth(guid) or 0
									end

									if selectedPriority == PRIORITY_LOWEST_HP then
										if primaryValue < highestPrimaryValue then
											highestPrimaryValue = primaryValue
											targetedGuid = guid
										end
									elseif primaryValue > highestPrimaryValue then
										highestPrimaryValue = primaryValue
										highestSecondaryValue = secondaryValue
										targetedGuid = guid
									elseif primaryValue == highestPrimaryValue and secondaryValue > highestSecondaryValue then
										highestSecondaryValue = secondaryValue
										targetedGuid = guid
									end
								end
							end
						end
					end
				end
			end
		end
	end

	-- run again if no target found ignoring range (only if IsSpellInRange is not available)
	if not targetedGuid and checkRange == true and not IsSpellInRange then
		targetedGuid = pickTarget(selectedPriority, lowercaseSpellNameNoRank, false, options)
	end

	return targetedGuid
end

local function castSpellWithOptions(spellName, lowercaseSpellNameNoRank, targetedGuid, options)
	if options["resistsound"] then
		Cursive.curses:EnableResistSound(targetedGuid)
	end
	if options["expiringsound"] then
		Cursive.curses:RequestExpiringSound(lowercaseSpellNameNoRank, targetedGuid)
	end
	CastSpellByName(spellName, targetedGuid)
end

function Cursive:Curse(spellName, targetedGuid, options)
	if not spellName or not targetedGuid then
		DEFAULT_CHAT_FRAME:AddMessage(commands["curse"])
		return false
	end

	if targetedGuid and string.sub(targetedGuid, 1, 2) ~= "0x" then
		targetedGuid = GetUnitGUID(targetedGuid)

		if not targetedGuid then
			if options["warnings"] then
				DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
			end
			return false
		end
	end

	if targetedGuid then
		-- check for options
		if not passedOptionFilters(targetedGuid, options) then
			if options["warnings"] then
				DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
			end
			return false
		end
	end

	-- remove (Rank x) from spellName if it exists
	local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

	if targetedGuid and
			not Cursive.curses:HasCurse(lowercaseSpellNameNoRank, targetedGuid, options["refreshtime"], options["malediction"]) and
			not isMobCrowdControlled(targetedGuid) and
			not isMobSpellImmune(targetedGuid) then
		castSpellWithOptions(string.lower(spellName), lowercaseSpellNameNoRank, targetedGuid, options)
		return true
	elseif options["warnings"] then
		DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
	end

	return false
end

local function getSpellTarget(spellName, priority, options)
	if not spellName then
		DEFAULT_CHAT_FRAME:AddMessage(commands["multicurse"])
		return
	end

	if priority and not priorities[priority] then
		DEFAULT_CHAT_FRAME:AddMessage(priorityChoices)
		for choice, description in pairs(priorities) do
			DEFAULT_CHAT_FRAME:AddMessage("|CFFFFFF00" .. choice .. "|R: " .. description)
		end
		return
	end

	local selectedPriority = priority or PRIORITY_HIGHEST_HP

	-- remove (Rank x) from spellName if it exists
	local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)

	return pickTarget(selectedPriority, lowercaseSpellNameNoRank, true, options)
end

function Cursive:Multicurse(spellName, priority, options)
	local targetedGuid = getSpellTarget(spellName, priority, options)
	if targetedGuid then
		local lowercaseSpellNameNoRank = Cursive.utils.GetLowercaseSpellNameNoRank(spellName)
		castSpellWithOptions(string.lower(spellName), lowercaseSpellNameNoRank, targetedGuid, options)
		return true
	elseif options["warnings"] then
		DEFAULT_CHAT_FRAME:AddMessage(curseNoTarget)
	end
	return false
end

function Cursive:GetTarget(spellName, priority, options)
	return getSpellTarget(spellName, priority, options)
end

function Cursive:Target(spellName, priority, options)
	local targetedGuid = getSpellTarget(spellName, priority, options)
	if targetedGuid then
		TargetUnit(targetedGuid)
		return true
	end
	return false
end
-- 新增Cursive:GetDistanceBand函数 by 武藤纯子酱 2025.8.28
function Cursive:GetDistanceBand(unit, testunit)
	if not UnitExists(unit) then return nil end

	-- 修复：testunit 缺省时回退为 "player"，避免 UnitXP 收到 nil 导致距离判定失败 by 武藤纯子酱 2026.9.17
	testunit = testunit or "player"

	if pcall(UnitXP, "nop", "nop") then
		if UnitXP("inSight", testunit, unit) then
			return UnitXP("distanceBetween", testunit, unit)
		else
			return nil
		end
	elseif CheckInteractDistance(unit, 3) then -- 9.9码（决斗）
		return 9.9
	elseif CheckInteractDistance(unit, 2) then -- 11.11码（交易）
		return 11.11
	elseif CheckInteractDistance(unit, 4) or CheckInteractDistance(unit, 1) then -- 28码（跟随和查看）
		return 28
	else
		return nil -- 超出所有检测范围
	end
end
-- 新增Cursive:GetNearestEnemyNum函数 by 武藤纯子酱 2025.8.28
function Cursive:GetNearestEnemyNum(distance, unitxp, testunit)
	local count = 0
	local testguid
	
	if not unitxp or unitxp == 0 then
		local unitrange = 0
		
		-- 参数有效性检查
		if distance ~= 1 and distance ~= 2 and distance ~= 3 then
			return 0  -- 无效参数直接返回0
		elseif distance == 1 then
			unitrange = 28
		elseif distance == 2 then
			unitrange = 11.11
		elseif distance == 3 then
			unitrange = 9.9
		end
		
		if testunit then
			local ok, guid = pcall(GetUnitGUID, testunit)
			if ok then
				testguid = guid
			else
				return 0
			end
		else
			testguid = GetUnitGUID("player")
		end
		
		-- 遍历所有跟踪的敌人
		for guid, _ in pairs(Cursive.core.guids) do		
			-- 基础过滤：单位存在且未死亡
			if UnitExists(guid) and not UnitIsDead(guid) and UnitCanAttack("player",guid) then
				-- 获取单位的距离带
				local unitDistance = Cursive:GetDistanceBand(guid, testguid)
				-- 匹配指定距离带且通过显示检测
				if unitDistance and unitDistance <= unitrange and self:ShouldDisplayGuid(guid) then
					count = count + 1
				end
			end
		end
		return count
	elseif unitxp == 1 and tonumber(distance) then
		if testunit then
			local ok, guid = pcall(GetUnitGUID, testunit)
			if ok then
				testguid = guid
			else
				return 0
			end
		else
			testguid = GetUnitGUID("player")
		end
	
		-- 遍历所有跟踪的敌人
		for guid, _ in pairs(Cursive.core.guids) do		
			-- 基础过滤：单位存在且未死亡
			if UnitExists(guid) and not UnitIsDead(guid) and UnitCanAttack("player",guid) then
				-- 获取单位的距离带
				local unitDistance = Cursive:GetDistanceBand(guid, testguid)
				-- 匹配指定距离带且通过显示检测
				if unitDistance and unitDistance <= distance and self:ShouldDisplayGuid(guid) then
					count = count + 1
				end
			end
		end
		return count
	else
		return 0
	end
end
-- 以下新增函数 by 武藤纯子酱 2025.8.28
local function isBossClassification(guid)
	-- 修复：classifications 表当前未维护，缺失时回退 UnitClassification，避免索引 nil 报错 by 武藤纯子酱 2026.9.17
	local classification = Cursive.core.classifications and Cursive.core.classifications[guid]
	if not classification then
		classification = UnitClassification(guid)
	end
	return (classification == "worldboss" or classification == "rareelite")
end

local function GetUnitBuffID(guid,spellId)
	local auras = GetUnitField(guid, "aura")
	for i, sId in pairs(auras) do
		if sId and sId == spellId then
			return true
		end
	end

	return false
end

function GetUnitBuffByName(guid, buffName)
	local searchName = strlower(buffName)

	local auras = GetUnitField(guid, "aura")
	for i, sId in pairs(auras) do
		local auraName = GetSpellRecField(sId,"name")
		if auraName and strlower(auraName) == searchName then
			return true
		end
	end

	return false
end

SLASH_CURSIVE1 = "/cursive" --creating the slash command
SlashCmdList["CURSIVE"] = handleSlashCommands --associating the function with the slash command
