-- Events
local DPSMateX = DPSMateX
local Parser
DPSMateX.DB.ShieldAsHeal = {
	["Power Word: Shield"] = 0, -- All
}

DPSMateX.DB.ShieldFlags = {
	["Power Word: Shield"] = 0, -- All
	["Ice Barrier"] = 0, -- All
	["The Burrower's Shell"] = 0, -- All
	["Aura of Protection"] = 0, -- All
	["Damage Absorb"] = 0, -- All
	["Physical Protection"] = 1, -- Meele
	["Harm Prevention Belt"] = 0, -- All
	["Mana Shield"] = 1, -- Meele
	["Frost Protection"] = 2, -- Frost
	["Frost Resistance"] = 2, -- Frost
	["Frost Ward"] = 2, -- Frost
	["Fire Protection"] = 3, -- Fire
	["Fire Ward"] = 3, -- Fire
	["Nature Protection"] = 4, -- Nature
	["Shadow Protection"] = 5, -- Shadow
	["Arcane Protection"] = 6, -- Arcane
	["Holy Protection"] = 7, -- Holy
}
DPSMateX.DB.FixedShieldAmounts = {
	["Power Word: Shield"] = 1000, -- All
	["Ice Barrier"] = 818, -- All
	["The Burrower's Shell"] = 900, -- All
	["Aura of Protection"] = 1000, -- All
	["Damage Absorb"] = 550, -- All
	["Physical Protection"] = 500, -- Meele
	["Harm Prevention Belt"] = 500, -- All
	["Mana Shield"] = 570, -- Meele
	["Frost Protection"] = 2500, -- Frost
	["Frost Resistance"] = 600, -- Frost
	["Frost Ward"] = 920, -- Frost
	["Fire Protection"] = 2500, -- Fire
	["Fire Ward"] = 920, -- Fire
	["Nature Protection"] = 2500, -- Nature
	["Shadow Protection"] = 2500, -- Shadow
	["Arcane Protection"] = 2500, -- Arcane
	["Holy Protection"] = 2500, -- Holy
}

DPSMateX.DB.ExtraAttacks = nil

local AbilityFlags = {
	["fire"] = 3,
	["holy"] = 7,
	["arcane"] = 6,
	["shadow"] = 5,
	["nature"] = 4,
	["frost"] = 2,
	["physical"] = 1,
	
	["feuer"] = 3,
	["heilig"] = 7,
	["arkan"] = 6,
	["schatten"] = 5,
	["natur"] = 4,
	["frost"] = 2,
	["physisch"] = 1,
	
	["火焰"] = 3,
	["神圣"] = 7,
	["奥术"] = 6,
	["暗影"] = 5,
	["自然"] = 4,
	["冰霜"] = 2,
	["物理"] = 1,

	["ombre"] = 5,
	["feu"] = 3,
	["nature"] = 4,
	["givre"] = 2,
	["arcane"] = 6,
	["sacré"] = 7,
	["d'ombre"] = 5,
	["d'feu"] = 3,
	["d'nature"] = 4,
	["d'givre"] = 2,
	["d'arcane"] = 6,
	["d'sacré"] = 7,
	["de ombre"] = 5,
	["de feu"] = 3,
	["de givre"] = 2,
	["de nature"] = 4,
	["de arcane"] = 6,
	["de sacré"] = 7,
	["physique"] = 1,
	["d'physique"] = 1,
	["de physique"] = 1,

	["огонь"] = 3,
	["обычный"] = 7,
	["тайная магия"] = 6,
	["тьма"] = 5,
	["природа"] = 4,
	["лед"] = 2,
	["физический урон"] = 1,
}
DPSMateX.DB.NeedUpdate = false
DPSMateX.DB.MainUpdate = 0
DPSMateX.DB.Zones = {
	[DPSMateX.L["mc"]] = true,
	[DPSMateX.L["bwl"]] = true,
	[DPSMateX.L["ony"]] = true,
	[DPSMateX.L["zg"]] = true,
	[DPSMateX.L["aq401"]] = true,
	[DPSMateX.L["aq20"]] = true,
	[DPSMateX.L["aq402"]] = true,
	[DPSMateX.L["naxx"]] = true,
	[DPSMateX.L["azs"]] = true, -- Azuregos
	[DPSMateX.L["bl"]] = true, -- Kazzak
	[DPSMateX.L["dw"]] = true, -- Emerald dragons, not sure if those zone names are correct.
	[DPSMateX.L["hintl"]] = true,
	[DPSMateX.L["ash"]] = true,
	[DPSMateX.L["fe"]] = true
}

local DB = DPSMateX.DB

-- Local Variables
local CombatState = false
local cheatCombat = 0
local UpdateTime = 0.25
local LastUpdate = 0
local MainLastUpdate = 0
local MainUpdateTime = 1.5
local NeedMainUpdate = false
local StatusBarUpdate = 0
local NeedStatusBarUpdate = false

local tinsert = table.insert
local tremove = table.remove
local _G = getglobal
local GT = GetTime
local strfind = string.find
local strgfind = string.gfind
local strsub = string.sub
local strgsub = string.gsub
local ipairs = ipairs
local getn = table.getn
local _

local UL = UnitLevel
local strlower = strlower
local UnitClass = UnitClass
local GetGuildInfo = GetGuildInfo
local GetRaidRosterInfo = GetRaidRosterInfo
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local GetGameTime = GetGameTime
local UnitName = UnitName
local UnitFactionGroup = UnitFactionGroup
local UnitAffectingCombat = UnitAffectingCombat
local UnitIsPlayer = UnitIsPlayer
local UnitBuff = UnitBuff

local pairs = pairs
local floor = floor
local time, path, gen
local AutoAttackAbility

local tablemodes = {"total","current"}

local mod = mod
local function GameTime_GT()
	local hour, minutes = GetGameTime()
	if hour>12 then
		hour = mod(hour, 12)
		if minutes<10 then
			return hour..":0"..minutes.." PM"
		else
			return hour..":"..minutes.." PM"
		end
	else
		hour = mod(hour, 12)
		if minutes<10 then
			return hour..":0"..minutes.." AM"
		else
			return hour..":"..minutes.." AM"
		end
	end
end

-- Begin Functions
DPSMateX.DB.VARIABLES_LOADED = function()
	if not DPSMateX.DB.loaded then
		--shield as heal dectect
		--DPSMateX.ShieldHealDetect = DPSMateX.L["priest"]
		DPSMateX:ApplyModuleLocales()
		
		local reset = not DPSMATEXRESET or DPSMATEXRESET < DPSMateX.VERSION
		if reset then DPSMateX.DB:ResetDB(true, true) end
		DPSMateX.DB:InitDB()
		--remove sync
		DPSMateX.Settings["sync"] = false
		DPSMateX.Settings["columnssunderarmor"] = DPSMateX.Settings["columnssunderarmor"] or { true, true }

		DPSMATEXRESET = DPSMateX.VERSION

		--DPSMateX:SendMessage("DPSMateX build "..DPSMateX.VERSION.." has been loaded!")
		--print('|cff00ffffDPSMateX 已加载|r /dps')

		DPSMateX.DB:PLAYER_LOGIN()
		--DPSMateX.Options.PLAYER_ENTERING_WORLD()
	end
end

DPSMateX.DB.PLAYER_LOGIN = function()
end

DPSMateX.DB.PLAYER_REGEN_DISABLED = function()
	if DPSMateX.Settings["hideincombat"] then
		for _, val in pairs(DPSMateX.Settings["windows"]) do
			if not val then break end
			_G("DPSMateX_"..val["name"]):Hide()
		end
		if DPSMateX.Settings["disablewhilehidden"] then
			DPSMateX:Disable()
		end
	end
	DPSMateX.Options:HideWhenSolo()
	if (not CombatState and cheatCombat<GT()) then
		DPSMateX.Options:NewSegment()
	end
	CombatState = true
	if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end
end

DPSMateX.DB.PLAYER_REGEN_ENABLED = function()
	if DPSMateX.Settings["hideincombat"] then
		for _, val in pairs(DPSMateX.Settings["windows"]) do
			if not val then break end
			if not val["hidden"] then
				_G("DPSMateX_"..val["name"]):Show()
			end
		end
		--DPSMateX:Enable()
	end
	DPSMateX.Options:HideWhenSolo()
end

local cheatDeathTable = {
	["Interface\\Icons\\Ability_Vanish"] = true,
	["Interface\\Icons\\Ability_Rogue_Feighdeath"] = true,
	["Interface\\Icons\\ability_vanish"] = true,
	["Interface\\Icons\\Ability_vanish"] = true,
	["Interface\\Icons\\ability_rogue_feighdeath"] = true,
	["Interface\\Icons\\Ability_rogue_feighdeath"] = true,
}

DPSMateX.DB.PLAYER_AURAS_CHANGED = function()
	time = GT()
	
	for i=1, 32 do
		local tex,stack = UnitBuff("player", i)
		if not tex then break end
		if cheatDeathTable[tex] then
			if cheatCombat<time then
				cheatCombat = time + 10
			end
			break
		end
	end
end

function DPSMateX.DB:MakePetName(player, pet)
	if self.has_superwow then pet = pet .." (".. player ..")" end
	return pet
end

local GetUnitGUID = GetUnitGUID
function DPSMateX.DB:BuildPlayer(unit, unitPet, i)
	--if UnitIsConnected(unit) then
		local name = UnitName(unit)
		if not name then return end  -- 单位不存在，直接返回
		
		local pet = UnitName(unitPet)

		local name_guid = GetUnitGUID(unit)
		local pet_guid = GetUnitGUID(unitPet)
		
		local _,classEng = UnitClass(unit)
		local _,fac = UnitFactionGroup(unit)
		local gname, _, _ = GetGuildInfo(unit)
		local level = UL(unit)

		self:BuildUser(name, strlower(classEng or ""))

		if classEng then
			DPSMateX.CacheUser[name][2] = strlower(classEng)
		end
		
		if pet and pet ~= DPSMateX.L["unknown"] and pet ~= "" then
			pet = self:MakePetName(name, pet)
			self:BuildUser(pet)
			self:AssociatePet(name, pet)
		end

		--pet name conflict with player?
		--if pet and DPSMateX.Parser.TargetParty[pet] then
			--DPSMateX.CacheUser[pet][4] = nil
			--DPSMateX.CacheUser[pet][6] = nil
			--DPSMateX.CacheUser[name][5] = nil
		--end

		if DPSMateX.CacheUser[name][4] then
			DPSMateX.CacheUser[name][4] = nil
			DPSMateX.CacheUser[name][5] = nil
		end
		
		if fac == DPSMateX.L["alliance"] then
			DPSMateX.CacheUser[name][3] = 1
		elseif fac == DPSMateX.L["horde"] then
			DPSMateX.CacheUser[name][3] = -1
		end

		if i then
			DPSMateX.Parser.TargetParty[name] = unit
			if name_guid then DPSMateX.Parser.TargetParty[name_guid] = unit end
			
			if pet then
				DPSMateX.Parser.TargetParty[pet] = unitPet
				if pet_guid then DPSMateX.Parser.TargetParty[pet_guid] = unitPet end
			end
			
			--in raid or party
			local subgrp = i
			if strfind(unit, "raid") then _,_,subgrp = GetRaidRosterInfo(i) end
			
			DPSMateX.Parser.TargetGroup[name] = subgrp
			DPSMateX.Parser.TargetGroup[name_guid or name] = subgrp
			if pet then DPSMateX.Parser.TargetGroup[pet] = subgrp end
			if pet then DPSMateX.Parser.TargetGroup[pet_guid or pet] = subgrp end

			DPSMateX.Parser.GroupTbl[subgrp] = DPSMateX.Parser.GroupTbl[subgrp] or {}
			tinsert(DPSMateX.Parser.GroupTbl[subgrp], {i, name_guid or name, name})
			if pet then tinsert(DPSMateX.Parser.GroupTbl[subgrp], {i, pet_guid or pet, pet}) end
		end

		if (gname and gname ~= "") then
			DPSMateX.CacheUser[name][7] = gname
		end
		if level and level>0 then
			DPSMateX.CacheUser[name][8] = level
		end
	--end
end

DPSMateX.DB.PLAYER_TARGET_CHANGED = function()
	if UnitIsPlayer("target") then
		this:BuildPlayer("target", "targetpet")
	end
end

DPSMateX.DB.UNIT_PET = function(unit)
	this:OnPetUpdate(unit)
end

DPSMateX.DB.PLAYER_PET_CHANGED = function()
	this:OnPetUpdate("player")
end

DPSMateX.DB.PET_STABLE_CLOSED = function()
	this:OnPetUpdate("player")
end

DPSMateX.DB.ZONE_CHANGED_NEW_AREA = function()
	this:ResetTempTable()
	--this:OnGroupUpdate()
end

function DPSMateX.DB:CollectBuffs()
	-- Get buffs of people after reset
	local teamtype = "party"
	local num = GetNumPartyMembers()
	if num<=0 then
		teamtype = "raid"
		num = GetNumRaidMembers()
	end

	local GameTooltip = GameTooltip
	local GameTooltipTextLeft1 = GameTooltipTextLeft1
	local UIParent = UIParent

	for p=1, num do
		for i=1, 32 do
			GameTooltip:SetOwner(UIParent)
			GameTooltip:SetUnitBuff(teamtype..p, i)
			local buff = GameTooltipTextLeft1:GetText()
			GameTooltip:Hide()
			if buff then
				DPSMateX.DB:BuildBuffs(DPSMateX.L["unknown"], UnitName(teamtype..p), buff, false)
			end
		end
	end
	if teamtype == "party" or num <= 0 then
		for i=0,31 do
			GameTooltip:SetOwner(UIParent)
			GameTooltip:SetPlayerBuff(i)
			local buff = GameTooltipTextLeft1:GetText()
			GameTooltip:Hide()
			if buff then
				DPSMateX.DB:BuildBuffs(DPSMateX.L["unknown"], UnitName("player"), buff, false)
			end
		end
	end
end

function DPSMateX.DB:OnPetUpdate(unit)
	if unit then
		local subgrp
		local teamtype = "raid"
		local num = GetNumRaidMembers()
		if num<=0 then
			teamtype = "party"
			num = GetNumPartyMembers()
			subgrp = 1
		end

		for i=1, num do
			if unit == teamtype..i then
				self:BuildPlayer(teamtype..i, teamtype.."pet"..i, subgrp or i)
				break
			end
		end

		if unit == "player" then
			subgrp = (num <= 0) and 1 or subgrp --1 in party or solo
			self:BuildPlayer("player", "pet", subgrp)
		end
	end
end

function DPSMateX.DB:OnLoad()
	DPSMateX.DB.ExtraAttacks = {
		[DPSMateX.L["Windfury Weapon"]] = 2,
		[DPSMateX.L["Windfury Totem"]] = 1,
		[DPSMateX.L["Fury of Forgewright"]] = 2,
		[DPSMateX.L["Hand of Justice"]]= 1,
		[DPSMateX.L["Flurry Axe"]] = 1,
		[DPSMateX.L["Eternal Strike"]] = 1,
		[DPSMateX.L["Hack and Slash"]] = 1,
	}
	Parser = DPSMateX.Parser
end

function DPSMateX.DB:AdjustCVars()
	RegisterCVar("CombatLogPeriodicSpells", 1) 
	RegisterCVar("CombatLogRangeParty", 200) 
	RegisterCVar("CombatLogRangePartyPet", 200) 
	RegisterCVar("CombatLogRangeFriendlyPlayers", 200) 
	RegisterCVar("CombatLogRangeFriendlyPlayersPets", 200) 
	RegisterCVar("CombatLogRangeHostilePlayers", 200) 
	RegisterCVar("CombatLogRangeHostilePlayersPets", 200) 
	RegisterCVar("CombatLogRangeCreature", 200) 
	RegisterCVar("CombatDeathLogRange", 200) 

	SetCVar("CombatLogPeriodicSpells", 1) 
	SetCVar("CombatLogRangeParty", 200) 
	SetCVar("CombatLogRangePartyPet", 200) 
	SetCVar("CombatLogRangeFriendlyPlayers", 200) 
	SetCVar("CombatLogRangeFriendlyPlayersPets", 200) 
	SetCVar("CombatLogRangeHostilePlayers", 200) 
	SetCVar("CombatLogRangeHostilePlayersPets", 200) 
	SetCVar("CombatLogRangeCreature", 200) 
	SetCVar("CombatDeathLogRange", 200) 

	if not DPSMateX.DB.has_nampower then
		DEFAULT_CHAT_FRAME:AddMessage("Nampower v3.4及以上未安装，DPSMateX 将无法工作。")
	else
		SetCVar("NP_EnableAutoAttackEvents", "1") 
		SetCVar("NP_EnableAuraCastEvents", "1") 
		SetCVar("NP_EnableSpellHealEvents", "1") 
		SetCVar("NP_EnableSpellGoEvents", "1")
		SetCVar("NP_EnableSpellStartEvents", "1")
	end
end

function DPSMateX.DB:OnGroupUpdate()
	DPSMateX.DB:AdjustCVars()

	DPSMateX.Parser.TargetParty = {}
	DPSMateX.Parser.TargetGroup = {}
	DPSMateX.Parser.GroupTbl = {}

	local subgrp
	local teamtype = "raid"
	local num = GetNumRaidMembers()
	if num<=0 then
		teamtype = "party"
		num = GetNumPartyMembers()
		subgrp = 1
	end

	for i=1, num do
		self:BuildPlayer(teamtype..i, teamtype.."pet"..i, subgrp or i)
	end

	subgrp = (num <= 0) and 1 or subgrp --1 in party or solo

	self:BuildPlayer("player", "pet", subgrp)

	DPSMateX.Parser:AssociateShaman("None", "None", true)
end

function DPSMateX.DB:AssociatePet(name, pet)
	DPSMateX.CacheUser[name][5] = pet
	DPSMateX.CacheUser[pet][4] = true
	DPSMateX.CacheUser[pet][6] = DPSMateX.CacheUser[name][1]
	if self.has_superwow then
		DPSMateX.CacheUser[name][9][pet] = true
	end
end

function DPSMateX.DB:GetPetsName(user)
	local pet
	if self.has_superwow then
		pet = user[9] or (user[5] and { [user[5]] = true })
	else
		if user[5] then pet = { [user[5]] = true } end
	end
	return pet
end

function DPSMateX.DB:GetPetShortName(usrId)
	local Dname = DPSMateX:GetUserById(usrId)
	local _,_,pet,usr = strfind( Dname or "", "^(.-)%s*%((.-)%)")
	pet = pet or Dname
	return pet, usr
end


--12/17 11:19:00.347  未知目标击中平安哥造成6点伤害。
--12/17 11:19:00.347  未知目标击中0x00000000000825AF造成6点伤害。

--12/10 11:12:43.323  0xF14003CA84000374从0x00000000000866F9的喂养宠物效果获得了35点快乐。
--12/10 11:12:43.323  未知目标 (鏡錵水月)从鏡錵水月的喂养宠物效果获得了35点快乐。
function DPSMateX.DB:BuildUser(Dname, Dclass)
	if Dname then
		local DMU, origName

		local usrid = DPSMateX.UserMap[Dname]
		if usrid then 
			origName = Dname 
			Dname = DPSMateX.UserId[usrid]
			DMU = DPSMateX.CacheUser[Dname]
		end

		if not DMU then
			origName = origName or Dname 
			local pet, usr
			if strsub(Dname,1,2) == "0x" then --name is GUID
				local plain = UnitName(Dname) or self.UserUnknown
				--for pets UnitName("0xF1401057BB000CA8") returns only name like "CatCat"
				--so try pet
				local owner = UnitName(Dname.."owner")
				if owner then 
					pet = plain
					usr = owner
					plain = self:MakePetName(owner, pet)
				end
				Dname = plain
			else
				if self.has_superwow then _,_,pet,usr = strfind(Dname, "^(.-)%s*%((.-)%)") end
			end

			DMU = DPSMateX.CacheUser[Dname]
			if not DMU then
				DPSMateX.userlen = DPSMateX.userlen + 1
		
				DPSMateX.CacheUser[Dname] = {
					[1] = DPSMateX.userlen,
					[2] = Dclass,
				}
				DMU = DPSMateX.CacheUser[Dname]
				DPSMateX.UserId[DPSMateX.userlen] = Dname
				if Dname ~= self.UserUnknown and (not pet or pet ~= self.UserUnknown) and (not usr or usr ~= self.UserUnknown) then
					DPSMateX.UserMap[Dname] = DPSMateX.userlen
				end
			end
	
			if self.has_superwow then
				if pet and usr then
					--print("seen user "..origName.." - "..Dname)
					local DMUOfusr = DPSMateX.CacheUser[usr]
					if not DMUOfusr then
						self:BuildUser(usr, nil)
						DMUOfusr = DPSMateX.CacheUser[usr]
					end

					DMU[4] = true --mark as pet
					DMU[6] = DMUOfusr[1] --set owner id
					
					if not DMUOfusr[5] then DMUOfusr[5] = Dname end
					if not DMUOfusr[9] then DMUOfusr[9] = {} end
					DMUOfusr[9][Dname] = true
				end
			end

			if Dname ~= self.UserUnknown and (not pet or pet ~= self.UserUnknown) and (not usr or usr ~= self.UserUnknown) then
				DPSMateX.UserMap[origName] = DMU[1]
			end
		end
		
		return DMU[1], Dname
	end
end

function DPSMateX.DB:AutoAttackAB(user)
	local offhand = DPSMateX.OffHandAttacking[user] or 0
	return AutoAttackAbility[offhand + 1]
end

function DPSMateX.DB:BuildAbility(name, kind, school, user)
	if name then
		if AutoAttackAbility and user and name == self.AAttack then
			--no nampower
			name = self:AutoAttackAB(user)
		end

		local ab = DPSMateX.CacheAbility[name]
		if not ab then
			DPSMateX.abilitylen = DPSMateX.abilitylen + 1
			DPSMateX.CacheAbility[name] = {
				[1] = DPSMateX.abilitylen,
				[2] = kind,
				[3] = school,
			}
			DPSMateX.AbilityId[DPSMateX.abilitylen] = name
			ab = DPSMateX.CacheAbility[name]
			return DPSMateX.abilitylen, ab
		end

		return ab[1], ab
	end
end

-- KTMHOOK
DPSMateX.DB.specialAbTrans = {
	["heroicstrike"] = "Heroic Strike",
	["maul"] = "Maul",	
	["swipe"] = "Swipe",
	["shieldslam"] = "Shield Slam",
	["revenge"] = "Revenge",
	["shieldbash"] = "Shield Bash",
	["sunder"] = "Sunder Armor",
	["cleave"] = "Cleave",
	["searingpain"] = "Searing Pain",
	["earthshock"] = "Earth Shock",
	["mindblast"] = "Mind Blast",
	["holyshield"] = "Holy Shield",
	["thunderfury"] = "Thunderfury",
	["graceofearth"] = "Grace of Earth",
	["blackamnesty"] = "Black Amnesty",
	["whitedamage"] = "AutoAttack",
}
DPSMateX.DB.KTMHOOK = {}
DPSMateX.DB.ktmavail = false

local SendAddonMessage = SendAddonMessage
function DPSMateX.DB:UpdateThreat()
	if self.KTMHOOK ~= {} then
		local str
		for cat, val in pairs(self.KTMHOOK) do
			local curNpc, curNpcNum = {}, 0
			if str then
				str = str..',["'..cat..'"]={'
			else
				str = '["'..cat..'"]={'
			end
			for ca, va in pairs(val) do
				if curNpc[va[1]] then
					str = str..','..va[2]
				else
					if curNpcNum==0 then
						str = str..'["'..va[1]..'"]={'..va[2]
					else
						str = str..'},["'..va[1]..'"]={'..va[2]
					end
					curNpc[va[1]] = true
					curNpcNum = curNpcNum + 1
				end
			end
			str = str..'}}'
		end
		if str then
			self.KTMHOOK = {}
			SendAddonMessage("KLHTMHOOK", str, "RAID")
		end
	end
end

function DPSMateX.DB:Threat(cause, spellname, target, value, amount)
	if value==0 then return end
	if not DPSMateX.EnabledModules["threat"] then return end
	target = self:BuildUser(target)
	cause = self:BuildUser(cause)
	spellname = self:BuildAbility(spellname)
	for cat, val in pairs(tablemodes) do
		if not DPSMateX.DBCache.Threat[cat][cause] then
			DPSMateX.DBCache.Threat[cat][cause] = {}
		end
		if not DPSMateX.DBCache.Threat[cat][cause][target] then
			DPSMateX.DBCache.Threat[cat][cause][target] = {}
		end
		if not DPSMateX.DBCache.Threat[cat][cause][target][spellname] then
			DPSMateX.DBCache.Threat[cat][cause][target][spellname] = {
				[1] = 0, -- Amount
				[2] = 0, -- Min
				[3] = 0, -- Max
				[4] = 0, -- Hits
				["i"] = {}
			}
		end
		local path = DPSMateX.DBCache.Threat[cat][cause][target][spellname]
		path[1] = path[1] + value
		path[4] = path[4] + amount
		if path[2]==0 or path[2]>value then
			path[2] = value
		end
		if path[3]<value then
			path[3] = value
		end
		
		if value>0 then
			local time = floor(DPSMateX.CombatTime[val])
			if path["i"][time] then
				path["i"][time] = path["i"][time] + value
			else
				path["i"][time] = value
			end
		end
	end
	self.NeedUpdate = true
end

local savedValue = {
	["damage"] = 0,
	["dmgt"] = 0,
	["heal"] = 0,
	["eheal"] = 0
}
function DPSMateX.DB:GetAlpha(k)
	if DPSMateX.Settings["windows"][k]["realtime"] then
		local p = savedValue[DPSMateX.Settings["windows"][k]["realtime"]] or 0
		savedValue[DPSMateX.Settings["windows"][k]["realtime"]] = 0
		if p > 50000 then -- That may solve the freeze issue
			p = 50000
		end
		return p
	end
end

function DPSMateX.DB:HookGraphEvents()
	if not self.hooked then
		self.oldDmgDone = DPSMateX.DB.DamageDone
		function DPSMateX.DB:DamageDone(Duser, Dname, Dhit, Dcrit, Dmiss, Dparry, Ddodge, Dresist, Damount, Dglance, Dblock, victim)
			self:oldDmgDone(Duser, Dname, Dhit, Dcrit, Dmiss, Dparry, Ddodge, Dresist, Damount, Dglance, Dblock, victim)
			savedValue["damage"] = savedValue["damage"] + Damount
		end
		self.oldDmgTaken = DPSMateX.DB.DamageTaken
		function DPSMateX.DB:DamageTaken(Duser, Dname, Dhit, Dcrit, Dmiss, Dparry, Ddodge, Dresist, Damount, cause, Dcrush, Dblock)
			self:oldDmgTaken(Duser, Dname, Dhit, Dcrit, Dmiss, Dparry, Ddodge, Dresist, Damount, cause, Dcrush, Dblock)
			savedValue["dmgt"] = savedValue["dmgt"] + Damount
		end
		self.oldHealing = DPSMateX.DB.Healing
		function DPSMateX.DB:Healing(mode, arr, Duser, Dname, Dhit, Dcrit, Damount)
			self:oldHealing(mode, arr, Duser, Dname, Dhit, Dcrit, Damount)
			if mode == 0 then
				savedValue["eheal"] = savedValue["eheal"] + Damount
			elseif mode == 1 then
				savedValue["heal"] = savedValue["heal"] + Damount
			end
		end
		self.hooked = true
	end
end

function DPSMateX.DB:WeightedAverage(a, b, c, d)
	return ((a*c+b)/(c+d))
end

local spellSchoolNames = {
	-- enUS
	["fire"] = true,
	["nature"] = true,
	["shadow"] = true,
	["holy"] = true,
	["frost"] = true,
	["arcane"] = true,
	
	-- deDE
	["feuer"] = true,
	["natur"] = true,
	["schatten"] = true,
	["arkan"] = true,
	["frost"] = true,
	["heilig"] = true,
	
	--frFR
	["ombre"] = true,
	["feu"] = true,
	["nature"] = true,
	["givre"] = true,
	["arcane"] = true,
	["sacré"] = true,
	["physique"] = true,

	-- ruRU
	["огонь"] = true,
	["обычный"] = true,
	["тайная магия"] = true,
	["тьма"] = true,
	["природа"] = true,
	["лед"] = true,
	["физический урон"] = true,
	
	-- zhCN
	["火焰"] = true,
	["神圣"] = true,
	["奥术"] = true,
	["暗影"] = true,
	["自然"] = true,
	["冰霜"] = true,
	["物理"] = true,
}

local sc

function DPSMateX.DB:AddSpellSchool(ab, school)
	school = strlower(school)
	sc = nil
	if spellSchoolNames[school] then
		sc = school
	else
		for c, _ in pairs(spellSchoolNames) do
			if strfind(school, c) then
				sc = c
				break
			end
		end
	end
	if sc then
		if DPSMateX.CacheAbility[ab] then
			DPSMateX.CacheAbility[ab][3] = sc
		else
			self:BuildAbility(ab,nil,sc)
		end
	end
end

function DPSMateX.DB:UnregisterNextSwing(usr, ability)
	ability = self:BuildAbility(ability, nil, nil, usr)
	usr = self:BuildUser(usr)

	if self.NextSwing[usr] and self.NextSwing[usr][2] == ability then
		self.NextSwing[usr] = nil
	end
	
	if self.NextSwingEDD[usr] and self.NextSwingEDD[usr][2] == ability then 
		self.NextSwingEDD[usr] = nil
	end
end

function DPSMateX.DB:RegisterNextSwing(usr, amount, ability)
	ability = self:BuildAbility(ability, nil, nil, usr)
	usr = self:BuildUser(usr)
	
	if self.NextSwing[usr] and self.NextSwing[usr][2] == ability then
		self.NextSwing[usr][1] = self.NextSwing[usr][1] + 1
	else
		self.NextSwing[usr] = {amount, ability}
	end

	if self.NextSwingEDD[usr] and self.NextSwingEDD[usr][2] == ability then 
		self.NextSwingEDD[usr][1] = self.NextSwingEDD[usr][1] + 1
	else
		self.NextSwingEDD[usr] = {amount, ability}
	end
end

DPSMateX.DB.AAttack = "AutoAttack"
local hackOrder, hackOrder2 = {}, {}

function DPSMateX.DB:TrackingProc(Duser, tsp)
	self:EnemyDamage(true, DPSMateX.DBCache.EDT, Duser, tsp[1], 1, 0, 0, 0, 0, 0, 0, tsp[2], 0, 0)
	self:DamageDone(Duser, tsp[1], 1, 0, 0, 0, 0, 0, 0, 0, 0, tsp[2])
end

function DPSMateX.DB:TrackingProcAll(t)
	for Duser, tsp in pairs(DPSMateX.Parser.TrackingSpell) do
		local slt = tsp[3]
		if not slt then
			DPSMateX.Parser.TrackingSpell[Duser] = nil
		else
			if (t - slt) >= 0.2 then
				self:TrackingProc(Duser, tsp)
				DPSMateX.Parser.TrackingSpell[Duser] = nil
			end
		end
	end
end

DPSMateX.bTrackingThunderArmor = 1
function DPSMateX.DB:DamageDone(Duser, Dname, Dhit, Dcrit, Dmiss, Dparry, Ddodge, Dresist, Damount, Dglance, Dblock, victim)
	if not Duser then return end

	local AbilityName, DuserName = Dname, nil

	Dname = self:BuildAbility(Dname, nil, nil, Duser)
	Duser, DuserName = self:BuildUser(Duser)

	if (not CombatState and cheatCombat<GT()) then
		DPSMateX.Options:NewSegment()
		CombatState = true
		if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end
	else
		--if victim and UnitClassification(victim) == "worldboss" then
			--try make boss fight
		--end
	end

	if AbilityName == self.AAttack then
		local NextSwing = self.NextSwing[Duser]
		if NextSwing then
			if NextSwing[1] > 0 then
			--if not self.windfuryab[NextSwing[2]] or hackOrder[Duser] then
			--if hackOrder[Duser] then
				Dname = NextSwing[2]
				NextSwing[1] = NextSwing[1] - 1
			--	hackOrder[Duser] = false
			--else
			--	hackOrder[Duser] = true
			--end
			else
				self.NextSwing[Duser] = nil
			end
		end
	end
	
	self.NeedUpdate = true

	if victim and strsub(victim, 1, 2) == "0x" then victim = UnitName(victim) end
	
	local  ignoredDamage = victim and DPSMateX.IgnoredDamage[victim]
	--ignored suicide or abnormal damage
	if (victim == DuserName) or (ignoredDamage and Damount > ignoredDamage) then 
		return
	end
	
	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.DamageDone[cat][Duser] then DPSMateX.DBCache.DamageDone[cat][Duser] = {i = 0} end
		gen = DPSMateX.DBCache.DamageDone[cat][Duser]
		if not gen[Dname] then
			gen[Dname] = {
				[1] = 0, -- hit count
				[2] = 0, -- hit min
				[3] = 0, -- hit max
				[4] = 0, -- hit total
				[5] = 0, -- crit count
				[6] = 0, -- crit min
				[7] = 0, -- crit max
				[8] = 0, -- crit total
				[9] = 0, -- miss count
				[10] = 0, -- parry count
				[11] = 0, -- dodge count
				[12] = 0, -- resist count
				[13] = 0, -- amount count
				[14] = 0, -- block count
				[15] = 0, -- block min
				[16] = 0, -- block max
				[17] = 0, -- block total
				[18] = 0, -- glance count
				[19] = 0, -- glance max
				[20] = 0, -- glance min
				[21] = 0, -- glance total
				--[22] = 0, -- Casts -- Deprecated
				["i"] = {}
			}
		end
		path = gen[Dname]
		--if Damount > 0 then 
			path[13] = path[13] + Damount
			if Dhit == 1 then
				if (Damount < path[2] or path[2] == 0) then path[2] = Damount end --hitMin
				if Damount > path[3] then path[3] = Damount end --hitMax 
				path[4] = path[4] + Damount --hitav
				path[1] = path[1] + 1
			elseif Dcrit == 1 then
				if (Damount < path[6] or path[6] == 0) then path[6] = Damount end
				if Damount > path[7] then path[7] = Damount end
				path[8] = path[8] + Damount
				path[5] = path[5] + 1
			elseif Dglance == 1 then
				if (Damount < path[15] or path[15] == 0) then path[15] = Damount end
				if Damount > path[16] then path[16] = Damount end
				path[17] =  path[17] + Damount
				path[14] = path[14] + 1
			elseif Dblock == 1 then--block
				if (Damount < path[19] or path[19] == 0) then path[19] = Damount end --blockMin
				if Damount > path[20] then path[20] = Damount end --blockMax
				path[21] =  path[21] + Damount --blockav
			end
			gen["i"] = gen["i"] + Damount
			time = floor(DPSMateX.CombatTime[val])
			path["i"][time] = (path["i"][time] or 0) + Damount
		--else
			path[9] = path[9] + Dmiss
			path[10] = path[10] + Dparry
			path[11] = path[11] + Ddodge
			path[12] = path[12] + Dresist
			path[18] = path[18] + Dblock
		--end
	end
end

function DPSMateX.DB:DamageTaken(Duser, Dname, Dhit, Dcrit, Dmiss, Dparry, Ddodge, Dresist, Damount, cause, Dcrush, Dblock)
	if not Duser or not cause or not DPSMateX.EnabledModules["damagetaken"] then return end

	Dname = self:BuildAbility(Dname, nil, nil,Duser)
	Duser = self:BuildUser(Duser)
	cause = self:BuildUser(cause)

	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.DamageTaken[cat][Duser] then DPSMateX.DBCache.DamageTaken[cat][Duser] = {i = 0} end
		gen = DPSMateX.DBCache.DamageTaken[cat][Duser]
		if not gen[cause] then
			gen[cause] = {}
		end
		if not gen[cause][Dname] then
			gen[cause][Dname] = {
				[1] = 0, -- hit
				[2] = 0, -- hitlow
				[3] = 0, -- hithigh
				[4] = 0, -- hitaverage
				[5] = 0, -- crit
				[6] = 0, -- critlow
				[7] = 0, -- crithigh
				[8] = 0, -- critaverage
				[9] = 0, -- miss
				[10] = 0, -- parry
				[11] = 0, -- dodge
				[12] = 0, -- resist
				[13] = 0, -- amount
				[14] = 0, -- average
				[15] = 0,
				[16] = 0,
				[17] = 0,
				[18] = 0,
				[19] = 0,
				[20] = 0,
				[21] = 0,
				[22] = 0,
				[23] = 0,
				["i"] = {}
			}
		end
		path = gen[cause][Dname]
		--if Damount > 0 then 
			path[13] = path[13] + Damount
			if Dhit == 1 then
				if (Damount < path[2] or path[2] == 0) then path[2] = Damount end
				if Damount > path[3] then path[3] = Damount end
				path[4] = path[4]+Damount
				path[1] = path[1] + 1
			elseif Dcrit == 1 then
				if (Damount < path[6] or path[6] == 0) then path[6] = Damount end
				if Damount > path[7] then path[7] = Damount end
				path[8] = path[8]+Damount
				path[5] = path[5] + 1
			elseif Dcrush == 1 then
				if (Damount < path[16] or path[16] == 0) then path[16] = Damount end
				if Damount > path[17] then path[17] = Damount end
				path[18] = path[18]+Damount
				path[15] = path[15] + 1
			elseif Dblock == 1 then
				if (Damount < path[21] or path[21] == 0) then path[21] = Damount end
				if Damount > path[22] then path[22] = Damount end
				path[23] = path[23]+Damount
				path[20] = path[20] + 1
			end
			gen["i"] = gen["i"] + Damount
			path[14] = (path[14] + Damount)/2
			time = floor(DPSMateX.CombatTime[val])
			path["i"][time] = (path["i"][time] or 0) + Damount
		--else
			path[9] = path[9] + Dmiss
			path[10] = path[10] + Dparry
			path[11] = path[11] + Ddodge
			path[12] = path[12] + Dresist
			path[20] = path[20] + Dblock
		--end
	end
	self.NeedUpdate = true
end

function DPSMateX.DB:EnemyDamage(mode, arr, Duser, Dname, Dhit, Dcrit, Dmiss, Dparry, Ddodge, Dresist, Damount, Dcause, Dblock, Dcrush_glance)
	if not Duser or not Dcause then return end

	local cause = Dcause
	--[[
	if self.has_superwow then 
		if strsub(Dcause, 1, 2) == "0x" then --name is guid
			cause = UnitName(Dcause)
			if not cause then
				local er = "DPSMateX: EnemyDamage: Invalid GUID: "..Dcause
				print(er)
				CombatLogAdd(er)
				CombatLogAdd(debugstack())
				return
			end
		end
	end
	]]

	local DuserName = Duser
	local causeName = cause
	
	Dname = self:BuildAbility(Dname, nil, nil, Duser)
	Duser = self:BuildUser(Duser)
	cause = self:BuildUser(cause)

	DPSMateX.Temp.ActiveMob[cause] = true

	if not mode then -- EDD
		if not DPSMateX.EnabledModules["enemydamagedone"] then
			return
		end
	else
		local NextSwingEDD = self.NextSwingEDD[Duser]
		if DPSMateX:GetAbilityById(Dname) == self.AAttack and NextSwingEDD then
			if NextSwingEDD[1] > 0 then
				--if not self.windfuryab[NextSwingEDD[2]] or hackOrder2[Duser] then
				Dname = NextSwingEDD[2]
				NextSwingEDD[1] = NextSwingEDD[1] - 1
				--else
				--	hackOrder2[Duser] = true
				--end
			else
				self.NextSwingEDD[Duser] = nil
			end
		end
		--hackOrder2[Duser] = false
	end

	for cat, val in pairs(tablemodes) do 
		if not arr[cat][cause] then arr[cat][cause] = {} end
		gen = arr[cat][cause]
		if not gen[Duser] then
			gen[Duser] = {
				i = 0,
			}
		end
		if not gen[Duser][Dname] then
			gen[Duser][Dname] = {
				[1] = 0, -- hit count
				[2] = 0, -- hit min
				[3] = 0, -- hit max
				[4] = 0, -- hit total
				[5] = 0, -- crit count
				[6] = 0, -- crit min
				[7] = 0, -- crit max
				[8] = 0, -- crit total
				[9] = 0, -- miss count
				[10] = 0, -- parry count
				[11] = 0, -- dodge count
				[12] = 0, -- resist count
				[13] = 0, -- amount count
				[14] = 0, -- block count
				[15] = 0, -- block min
				[16] = 0, -- block max
				[17] = 0, -- block total
				[18] = 0, -- crush or glance count
				[19] = 0, -- crush or glance max
				[20] = 0, -- crush or glance min
				[21] = 0, -- crush or glance total
				--[22] = 0, -- Casts -- Deprecated
				["i"] = {}
			}
		end
		path = gen[Duser][Dname]
		--if Damount > 0 then
			path[13] = path[13] + Damount
			if Dhit == 1 then
				if (Damount < path[2] or path[2] == 0) then path[2] = Damount end
				if Damount > path[3] then path[3] = Damount end
				path[4] = path[4] + Damount
				path[1] = path[1] + 1
			elseif Dcrit == 1 then
				if (Damount < path[6] or path[6] == 0) then path[6] = Damount end
				if Damount > path[7] then path[7] = Damount end
				path[8] = path[8] + Damount
				path[5] = path[5] + 1
			elseif Dcrush_glance == 1 then --crush(by creature) or glance(to creature)
				if (Damount < path[19] or path[19] == 0) then path[19] = Damount end
				if Damount > path[20] then path[20] = Damount end
				path[21] = path[21] + Damount
				path[18] = path[18] + 1
			elseif Dblock == 1 then
				if (Damount < path[15] or path[15] == 0) then path[15] = Damount end
				if Damount > path[16] then path[16] = Damount end
				path[17] = path[17] + Damount
				path[14] = path[14] + 1
			end
			gen[Duser]["i"] = gen[Duser]["i"] + Damount
			time = floor(DPSMateX.CombatTime[val])
			path["i"][time] = (path["i"][time] or 0) + Damount
		--else
			path[9] = path[9] + Dmiss
			path[10] = path[10] + Dparry
			path[11] = path[11] + Ddodge
			path[12] = path[12] + Dresist
			path[14] = path[14] + Dblock
		--end
	end
	if Damount>0 then self:CheckActiveCC(DuserName, causeName) end
	self.NeedUpdate = true
end

function DPSMateX.DB:Healing(mode, arr, Duser, Dname, Dhit, Dcrit, Damount)
	if (
		(mode==0 and not DPSMateX.EnabledModules["effectivehealing"] and not DPSMateX.EnabledModules["healingandabsorbs"]) or 
		(mode==1 and not DPSMateX.EnabledModules["healing"]) or 
		(mode==2 and not DPSMateX.EnabledModules["overhealing"])) then return end
	if not CombatState then return end
	Duser = self:BuildUser(Duser)
	Dname = self:BuildAbility(Dname)
	for cat, val in pairs(tablemodes) do 
		if not arr[cat][Duser] then arr[cat][Duser] = {i = 0} end
		gen = arr[cat][Duser]
		if not gen[Dname] then
			gen[Dname] = {
				[1] = 0, -- Healing done
				[2] = 0, -- Hit
				[3] = 0, -- Crit
				[4] = 0, -- hitav
				[5] = 0, -- critav
				[6] = 0, -- hitMin
				[7] = 0, -- hitMax
				[8] = 0, -- critMin
				[9] = 0, -- critMax
				["i"] = {}
			}
		end
		path = gen[Dname]
		if Damount > 0 then 
			path[1] = path[1]+Damount
			gen["i"] = gen["i"]+Damount
			if Dhit==1 then
				path[4] = path[4] + Damount 
				if Damount<path[6] or path[6]==0 then
					path[6] = Damount; 
				end
				if Damount>path[7] or path[7]==0 then
					path[7] = Damount 
				end
				path[2] = path[2]+1
			else 
				path[5] = path[5] + Damount 
				if Damount<path[8] or path[8]==0 then
					path[8] = Damount; 
				end
				if Damount>path[9] or path[9]==0 then
					path[9] = Damount 
				end
				path[3] = path[3]+1
			end
			time = floor(DPSMateX.CombatTime[val])
			path["i"][time] = (path["i"][time] or 0) + Damount
		end
	end
	self.NeedUpdate = true
end

function DPSMateX.DB:HealingTaken(mode, arr, Duser, Dname, Dhit, Dcrit, Damount, target)
	if not DPSMateX.HasHealingModules[mode] then return end

	if not CombatState then return end
	Duser = self:BuildUser(Duser)
	Dname = self:BuildAbility(Dname)
	target = self:BuildUser(target)
	for cat, val in pairs(tablemodes) do 
		if not arr[cat][Duser] then arr[cat][Duser] = {i = 0} end
		gen = arr[cat][Duser]
		if not gen[target] then
			gen[target] = {}
		end
		if not gen[target][Dname] then
			gen[target][Dname] = {
				[1] = 0, -- Healing done
				[2] = 0, -- Hit
				[3] = 0, -- Crit
				[4] = 0, -- hitav
				[5] = 0, -- critav
				[6] = 0, -- hitMin
				[7] = 0, -- hitMax
				[8] = 0, -- critMin
				[9] = 0, -- critMax
				["i"] = {}
			}
		end
		path = gen[target][Dname]
		if Damount > 0 then 
			path[1] = path[1]+Damount
			if Dhit==1 then
				path[4] = path[4] + Damount 
				if Damount<path[6] or path[6]==0 then
					path[6] = Damount; 
				end
				if Damount>path[7] or path[7]==0 then
					path[7] = Damount 
				end
				path[2] = path[2]+1
			else
				path[5] = path[5] + Damount 
				if Damount<path[8] or path[8]==0 then
					path[8] = Damount; 
				end
				if Damount>path[9] or path[9]==0 then
					path[9] = Damount 
				end
				path[3] = path[3]+1
			end
			gen["i"] = gen["i"]+Damount
			time = floor(DPSMateX.CombatTime[val])
			path["i"][time] = (path["i"][time] or 0) + Damount
		end
	end
	self.NeedUpdate = true
end

-- Fire etc. Prot Potion
-- Mage: Ice Barrier, Manashield, Fire Protection, Frost Protection
-- Warlock: Shadow Protection
-- Priest: Power Word: Shield
-- Always the first shield that is applied is absorbing the damage. Depending the school it iterates through the shields.
-- Example: Manashield is applied first then Frost Protection Potion.
-- Weasel casts Frostbolt. -> Game: Can Manashield absorb Frost damage? No -> Game: Can Frost Protection Potion Absorb Frost damage? Yes -> OK go for it!
-- Example two: Frost Protection Potion and Power Word Shield
-- Weasel casts Frostbolt. -> Game: Can FPP absorb the FD? Yes -> Go for it. (The Power Word Shield is ignored until FPP fades)
-- What if a shield is refreshed
DPSMateX.DB.realAbility = {
	["Greater Fire Protection Potion"] = "Fire Protection",
	["Greater Frost Protection Potion"] = "Frost Protection",
	["Greater Nature Protection Potion"] = "Nature Protection",
	["Greater Holy Protection Potion"] = "Holy Protection",
	["Greater Shadow Protection Potion"] = "Shadow Protection",
	["Greater Arcane Protection Potion"] = "Arcane Protection",
}
function DPSMateX.DB:AwaitingAbsorbConfirmation(owner, ability, abilityTarget, time)
	tinsert(DPSMateX.Temp.Await, {owner, self.realAbility[ability] or ability, abilityTarget, time})
end

function DPSMateX.DB:ClearAwaitAbsorb()
	local time = GT()
	for cat, val in pairs(DPSMateX.Temp.Await) do
		if (time-val[4])>=10 then
			tremove(DPSMateX.Temp.Await, cat)
			break
		end
	end
end

function DPSMateX.DB:ConfirmAbsorbApplication(ability, abilityTarget, time)
	for cat, val in pairs(DPSMateX.Temp.Await) do
		if val[4]<=time and val[2]==ability then
			if val[3]==abilityTarget then
				self:RegisterAbsorb(val[1], ability, abilityTarget)
				tremove(DPSMateX.Temp.Await, cat)
				return
			end
		end
	end
	self:RegisterAbsorb(DPSMateX.L["unknown"], ability, abilityTarget)
end

function DPSMateX.DB:RegisterAbsorb(owner, ability, abilityTarget)
	if not DPSMateX.EnabledModules["absorbs"] and not DPSMateX.EnabledModules["absorbstaken"] and not DPSMateX.EnabledModules["healingandabsorbs"] then return end

	ability = self:BuildAbility(ability, nil, nil, owner)
	owner = self:BuildUser(owner)
	abilityTarget = self:BuildUser(abilityTarget)

	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.Absorbs[cat][abilityTarget] then
			DPSMateX.DBCache.Absorbs[cat][abilityTarget] = {}
		end
		gen = DPSMateX.DBCache.Absorbs[cat][abilityTarget]
		if not gen[owner] then gen[owner] = {i = {}} end
		if not gen[owner][ability] then gen[owner][ability] = {} end
		tinsert(gen[owner][ability], {
			i = {
				[1] = 0,
				[2] = 0,
				[3] = 0,
				[4] = 0,
			},
		})
	end
	self.NeedUpdate = true
end

function DPSMateX.DB:SetUnregisterVariables(amount, ab, c)
	if amount then
		ab = self:BuildAbility(ab, nil, nil, c)
		c = self:BuildUser(c, nil)
		DPSMateX.Temp.broken = {1,amount,ab,c}
	end
end

function DPSMateX.DB:UnregisterAbsorb(ability, abilityTarget)
	if not DPSMateX.EnabledModules["absorbs"] and not DPSMateX.EnabledModules["absorbstaken"] and not DPSMateX.EnabledModules["healingandabsorbs"] then return end
	ability = self:BuildAbility(ability, nil, nil, abilityTarget)
	abilityTarget = self:BuildUser(abilityTarget)
	local AbsorbingAbility
	for cat, val in pairs(tablemodes) do 
		AbsorbingAbility = self:GetActiveAbsorbAbilityByPlayer(ability, abilityTarget, cat)
		if AbsorbingAbility[1] then
			path = DPSMateX.DBCache.Absorbs[cat][abilityTarget][AbsorbingAbility[1]][AbsorbingAbility[2]][AbsorbingAbility[3]]["i"]
			if path[1] == 0 then
				path[1] = DPSMateX.Temp.broken[1]
				path[2] = DPSMateX.Temp.broken[2]
				path[3] = DPSMateX.Temp.broken[3]
				path[4] = DPSMateX.Temp.broken[4]
				if (DPSMateX.Temp.broken[2] or 0)>0 then tinsert(DPSMateX.DBCache.Absorbs[cat][abilityTarget][AbsorbingAbility[1]]["i"], {DPSMateX.CombatTime[val], DPSMateX.Temp.broken[4], DPSMateX.Temp.broken[3], DPSMateX.Temp.broken[2], AbsorbingAbility[2]}) end
			end
		end
	end
	DPSMateX.Temp.broken = {2,0,0,0}
	self.NeedUpdate = true
end

function DPSMateX.DB:GetActiveAbsorbAbilityByPlayer(ability, abilityTarget, cate)
	local ActiveShield = {}
	if DPSMateX.DBCache.Absorbs[cate][abilityTarget] then
		for cat, val in pairs(DPSMateX.DBCache.Absorbs[cate][abilityTarget]) do
			for ca, va in pairs(val) do
				if ca~="i" then
					for c, v in pairs(va) do
						for ce, ve in pairs(v) do
							if ve[1]==0 and ca==ability then
								ActiveShield = {cat, ca, c}
								break
							end
						end
					end
				end
			end
		end
	end
	return ActiveShield
end

local DPSMateX_Tooltip
local DPSMateX_TooltipTextLeft1

function DPSMateX.DB:GetAbsorbingShield(ability, abilityTarget, cate)
	DPSMateX_Tooltip = DPSMateX_Tooltip or getglobal("DPSMateX_Tooltip")
	DPSMateX_TooltipTextLeft1 = DPSMateX_TooltipTextLeft1 or getglobal("DPSMateX_TooltipTextLeft1")

	local AbsorbingAbility = {}	
	local activeShields = {}
	if DPSMateX.DBCache.Absorbs[cate][abilityTarget] then
		for cat, val in pairs(DPSMateX.DBCache.Absorbs[cate][abilityTarget]) do
			for ca, va in pairs(val) do
				if ca~="i" then
					for c, v in pairs(va) do
						for ce, ve in pairs(v) do
							if ve[1]==0 then
								activeShields[cat] = {ca,c}
								break
							end
						end
					end
				end
			end
		end

		local AAS, ASS = {}, {}
		for cat, val in pairs(activeShields) do
			if self.ShieldFlags[DPSMateX:GetAbilityById(val[1])]==0 then
				AAS[cat] = {val[1],val[2]}
			elseif self.ShieldFlags[DPSMateX:GetAbilityById(val[1])]==AbilityFlags[ability] then
				ASS[cat] = {val[1],val[2]}
			elseif not ability or not AbilityFlags[ability] then
				ASS[cat] = {val[1],val[2]}
			end
		end
		
		if AAS~={} or ASS~={} then
			local unit, buff = DPSMateX.Parser:GetUnitByName(abilityTarget)
			if unit then
				for i=1, 32 do
					DPSMateX_Tooltip:ClearLines()
					DPSMateX_Tooltip:SetUnitBuff(unit, i, "HELPFUL")
					buff = DPSMateX_TooltipTextLeft1:GetText()
					if (not buff) then break end
					buff = self:BuildAbility(buff)
					for cat, val in pairs(AAS) do
						if val[1]==buff then
							AbsorbingAbility = {cat, val[1],val[2]}
							break
						end
					end
					for cat, val in pairs(ASS) do
						if val[1]==buff then
							AbsorbingAbility = {cat, val[1],val[2]}
							break
						end
					end
				end
			else
				if AAS then
					for cat, val in pairs(AAS) do
						return {cat, val[1],val[2]}
					end
				else
					for cat, val in pairs(ASS) do
						return {cat, val[1],val[2]}
					end
				end
			end
		end
	end
	return AbsorbingAbility
end

function DPSMateX.DB:Absorb(ability, abilityTarget, incTarget)
	if not DPSMateX.EnabledModules["absorbs"] and not DPSMateX.EnabledModules["absorbstaken"] and not DPSMateX.EnabledModules["healingandabsorbs"] then return end
	ability = self:BuildAbility(ability, nil, nil, incTarget)
	incTarget = self:BuildUser(incTarget)
	abilityTarget = self:BuildUser(abilityTarget)
	local AbsorbingAbility
	for cat, val in pairs(tablemodes) do 
		AbsorbingAbility = self:GetAbsorbingShield(DPSMateX.CacheAbility[DPSMateX:GetAbilityById(ability)][3], abilityTarget, cat)
		if AbsorbingAbility[1] then
			if not DPSMateX.DBCache.Absorbs[cat][abilityTarget][AbsorbingAbility[1]][AbsorbingAbility[2]][AbsorbingAbility[3]][incTarget] then
				DPSMateX.DBCache.Absorbs[cat][abilityTarget][AbsorbingAbility[1]][AbsorbingAbility[2]][AbsorbingAbility[3]][incTarget] = {}
			end
			path = DPSMateX.DBCache.Absorbs[cat][abilityTarget][AbsorbingAbility[1]][AbsorbingAbility[2]][AbsorbingAbility[3]][incTarget]
			path[ability] = (path[ability] or 0) + 1
			tinsert(DPSMateX.DBCache.Absorbs[cat][abilityTarget][AbsorbingAbility[1]]["i"], {DPSMateX.CombatTime[val], incTarget, ability, 0, AbsorbingAbility[2]})
		end
	end
end

local OverTimeDispelTickOn = false
local OverTimeDispelTimer = 0
local TrackingProcTimer = 0

DPSMateX.DB.Restor = "Restoration"
DPSMateX.DB.RPotion = "Restorative Potion"
DPSMateX.DB.PFication = "Purification"
DPSMateX.DB.PPotion = "Purification Potion"

--obsolete
function DPSMateX.DB:AwaitHotDispel(ability, target, cause, time)
	if ability == self.RPotion then
		ability = self.Restor
		target = cause
	end
	if ability == self.PPotion then
		ability = self.PFication
		target = cause
	end
	tinsert(DPSMateX.Temp.AwaitHotDispelT, {cause, target, ability, time})
end

--obsolete
function DPSMateX.DB:ClearAwaitHotDispel()
	local time = GT()
	for cat, val in pairs(DPSMateX.Temp.AwaitHotDispelT) do
		if (time-val[4])>=10 then
			DPSMateX.Temp.AwaitHotDispelT[cat] = nil
		end
	end
end

function DPSMateX.DB:RemoveActiveHotDispel(target, ability)
	local ActiveHotDispel = DPSMateX.Temp.ActiveHotDispel[target]
	if not ActiveHotDispel then return end

	for i = getn(ActiveHotDispel), 1, -1 do
		if ActiveHotDispel[i][2] == ability then
			tremove(ActiveHotDispel, i)
		end
	end
end

local dispel_dbg = false
function DPSMateX.DB:dispel_dbg()
	dispel_dbg = not dispel_dbg
end

function DPSMateX.DB:RegisterHotDispel(target, ability, cause)
	if not DPSMateX.HasDispelModules then return end
	
	local time = GT()
	if cause then
		if not DPSMateX.Temp.ActiveHotDispel[target] then DPSMateX.Temp.ActiveHotDispel[target] = {} end
		-- Overwrite active dispels
		self:RemoveActiveHotDispel(target, ability) 
		tinsert(DPSMateX.Temp.ActiveHotDispel[target], {cause, ability, time})
		if dispel_dbg then print("HotDispel "..ability.." on "..select(2,self:BuildUser(target)).." from "..select(2,self:BuildUser(cause))) end
	end
end

function DPSMateX.DB:UnregisterHotDispel(target, ability)
	if self.has_nampower then
		self:RemoveActiveHotDispel(target, ability) 
	end
end

function DPSMateX.DB:RemoveDispelTotem(cause, ability)
	local DispelTotemCasts = DPSMateX.Temp.DispelTotemCasts[cause]
	if DispelTotemCasts then
		for i = getn(DispelTotemCasts), 1, -1 do
			if DispelTotemCasts[i][1] == ability then
				tremove(DispelTotemCasts, i)
				break
			end
		end
	end
end

function DPSMateX.DB:CastDispelTotem(ability, cause, time)
	if not DPSMateX.HasDispelModules then return end

	if not DPSMateX.Temp.DispelTotemCasts[cause] then DPSMateX.Temp.DispelTotemCasts[cause] = {} end
	self:RemoveDispelTotem(cause, ability) 
	tinsert(DPSMateX.Temp.DispelTotemCasts[cause], {ability, time})
	--self:BuildUser(cause)
	if dispel_dbg then print(time_stamp().." "..select(2,self:BuildUser(cause)).." 施放了 "..ability) end
end

--净化药水、圣泉水
--08/14 22:10:51.541  你的外域的恐惧被移除了。
--08/14 22:10:51.541  你施放了净化。
--滋补药剂
--08/25 21:01:22.048  你的麦迪文的灾祸被移除了。
--08/25 21:01:22.048  你施放了恢复。
--驱毒术
--9/9 22:10:54.192  百变派大星二的死灵之毒被移除了。
--9/9 22:10:54.192  不卖伟哥对百变派大星二施放了驱毒术。
--9/9 22:10:54.270  死灵之毒效果从百变派大星二身上消失。
function time_stamp()
	local str = date("%H:%M:%S ")..string.sub(math.mod(GetTime(), 1) * 1000, 1, 3)
	return str
end

function DPSMateX.DB:RegisterLockNLoad(caster, target)
	DB.LockNLoad[caster] = target
end

function DPSMateX.DB:DispelCast(ability, target, caster, time)
	if not DPSMateX.HasDispelModules then return end

	local dc = DPSMateX.Temp.DispelCasts[target]
	if not dc then
		DPSMateX.Temp.DispelCasts[target] = {}
		dc = DPSMateX.Temp.DispelCasts[target]
	end

	dc[1] = ability
	dc[2] = caster
	dc[3] = time
end

function DPSMateX.DB:TryAHotDispel(cause, ability, debuff, target)
	local debuffAB = DPSMateX.CacheAbility[debuff] 
	local debuffType = debuffAB and debuffAB[2]
	local debuffTypeMatched = debuffType and DPSMateX.Parser.DispelTbl[debuffType] and DPSMateX.Parser.DispelTbl[debuffType][ability]

	if dispel_dbg then print(time_stamp().." "..select(2,self:BuildUser(cause)).." try dispelled "..debuff.." of "..select(2,self:BuildUser(target)).." using "..ability) end
	if debuffTypeMatched then --debuffType matched
		self:Dispels(cause, ability..DPSMateX.L["periodic"], target, debuff)
		return true
	end
end

function DPSMateX.DB:SeenDebuffDispelled(debuff, target, time, casterGuid)
	if not DPSMateX.HasDispelModules then return end

	local dc = DPSMateX.Temp.DispelCasts[target]
	if casterGuid then 
		--nampower driven
		local caster = UnitName(casterGuid)
		if Parser.TotemDispels[caster] then
			--dispelled by totem
			self:Dispels(GetUnitGUID(casterGuid.."owner"), caster, target, debuff)
		else
			--dispelled by player
			if dc and dc[3] and dc[2] == casterGuid then
				self:Dispels(casterGuid, dc[1], target, debuff)
			else
				local dispeled
				for ca, hotDispel in ipairs(DPSMateX.Temp.ActiveHotDispel[target] or {}) do --{cause, ability, time}
					--just try dispel
					dispeled = self:TryAHotDispel(hotDispel[1], hotDispel[2], debuff, target)
					if dispeled then break end
				end

				if not dispeled then
					self:Dispels(casterGuid, DPSMateX.L["unknown"], target, debuff)
				end
			end
		end
		if dc then dc[3] = nil end --mark as Invalid
	else
		if dc then
			if time - dc[3] < 1.5 then
				local ca = DPSMateX.CacheAbility[debuff] 
				local debuffType = ca and ca[2]
				local debuffTypeMatched = debuffType and DPSMateX.Parser.DispelTbl[debuffType] and DPSMateX.Parser.DispelTbl[debuffType][dc[1]]
				if debuffTypeMatched then 
					self:Dispels(dc[2], dc[1], target, debuff)
					--DPSMateX.Temp.DispelCasts[target] = nil
					return
				end
			end
		end

		if not DPSMateX.Temp.DebuffDispelled[target] then DPSMateX.Temp.DebuffDispelled[target] = {} end
		tinsert(DPSMateX.Temp.DebuffDispelled[target], {debuff, time})
		OverTimeDispelTickOn = true
	end
end

function DPSMateX.DB:TryDispel(ability, target, cause, time)
	if not DPSMateX.HasDispelModules then return end

	local targetDebuffDispelled = DPSMateX.Temp.DebuffDispelled[target]
	local dispelled = 0

	if targetDebuffDispelled then
		local num = 0
		for i = getn(targetDebuffDispelled), 1, -1 do
			local DebuffDispelled = targetDebuffDispelled[i]  --{debuff, time}
			
			if self:TryAHotDispel(cause, ability, DebuffDispelled[1], target) then
				dispelled = dispelled + 1
				if dispel_dbg then print(time_stamp().." "..select(2,self:BuildUser(cause)).." dispelled "..DebuffDispelled[1].." of "..select(2,self:BuildUser(target)).." using "..ability) end
				tremove(targetDebuffDispelled, i)
			elseif time - DebuffDispelled[2] > 10 then
				--remove long exists dispels anyway
				tremove(targetDebuffDispelled, i)
			else
				num = num + 1
			end
		end
		if num == 0 then 
			DPSMateX.Temp.DebuffDispelled[target] = nil
		end
	end

	--check for remaining dispels
	local dispelRemains
	for target, debuffs in pairs(DPSMateX.Temp.DebuffDispelled) do 
		if getn(debuffs) > 0 then
			dispelRemains = true
			break
		end
	end

	if not dispelRemains then
		if dispel_dbg and dispelled > 0 then print(time_stamp().." no dispels remains") end
		OverTimeDispelTickOn = false
		OverTimeDispelTimer = 0
	end
end

function DPSMateX.DB:TryHotDispel()
	if not DPSMateX.HasDispelModules then return end
	
	local time = GT()
	for target, val in pairs(DPSMateX.Temp.ActiveHotDispel) do
		for ca, hotDispel in ipairs(val) do --{cause, ability, time}
			--just try dispel
			self:TryDispel(hotDispel[2], target, hotDispel[1], time) 
		end
	end
end

function DPSMateX.DB:TryTotemDispels()
	local time = GT()

	local teamtype = "raid"
	local tnum = GetNumRaidMembers()
	if tnum<=0 then
		teamtype = "party"
		tnum = GetNumPartyMembers()
	end

	for cause, DispelTotemCasts in pairs(DPSMateX.Temp.DispelTotemCasts) do -- {cause, {ability,time}}
		for i = getn(DispelTotemCasts), 1, -1 do
			local DispelTotemCast = DispelTotemCasts[i]
			--try dispel team members
			local subgrp = DPSMateX.Parser.TargetGroup[cause]
			if not DPSMateX.Parser.GroupTbl[subgrp] then 
				if dispel_dbg then print(select(2,self:BuildUser(cause)).." has no group "..subgrp) end
			else
				for _, tbl in ipairs(DPSMateX.Parser.GroupTbl[subgrp]) do --{i, name_guid or name, name}
					self:TryDispel(DispelTotemCast[1], tbl[2], cause, GT())
				end
			end
		end
	end
end

function DPSMateX.DB:CheckDispels()
	local time = GT()

	--timeout check
	local num
	for target, ahd in pairs(DPSMateX.Temp.ActiveHotDispel) do -- {target, {cause, ability, time}}
		num = 0
		for i = getn(ahd), 1, -1 do
			local ActiveHotDispel = ahd[i]
			if time - ActiveHotDispel[3] > 20 then
				--timeout
				if dispel_dbg then print(time_stamp().." "..ActiveHotDispel[2].." of "..select(2,self:BuildUser(target)).." from "..select(2,self:BuildUser(ActiveHotDispel[1])).." timed out ") end
				tremove(ahd, i)
			else
				num = num + 1
			end
		end
		if num == 0 then
			DPSMateX.Temp.ActiveHotDispel[target] = nil
		end
	end

	for cause,DispelTotemCasts in pairs(DPSMateX.Temp.DispelTotemCasts) do -- {cause, {ability,time}}
		for i = getn(DispelTotemCasts), 1, -1 do
			local DispelTotemCast = DispelTotemCasts[i]
			if time - DispelTotemCast[2] > 120*1.2 then
				if dispel_dbg then print(time_stamp().." "..DispelTotemCast[1].." of "..select(2,self:BuildUser(cause)).." timed out ") end
				DPSMateX.Temp.DispelTotemCasts[cause] = nil
			end
		end
	end

	local dispelRemains = 0
	local dispelled = 0
	for target, targetDebuffDispelled in pairs(DPSMateX.Temp.DebuffDispelled) do
		num = 0
		for i = getn(targetDebuffDispelled), 1, -1 do
			local DebuffDispelled = targetDebuffDispelled[i]  --{debuff, time}
			if DebuffDispelled then
				if time - DebuffDispelled[2] > 10 then
					dispelled = dispelled + 1
					if dispel_dbg then print(time_stamp().." "..DebuffDispelled[1].." of "..select(2,self:BuildUser(target)).." over time") end
					self:TryDispel(DPSMateX.L["Blessing of the Holy Spring"], target, self.UserUnknown, time)
					tremove(targetDebuffDispelled, i)
				else
					num = num + 1
					dispelRemains = dispelRemains + 1
				end
			end
		end
		if num == 0 then
			DPSMateX.Temp.DebuffDispelled[target] = nil
		end
	end

	if dispelRemains == 0 then
		if dispel_dbg and dispelled > 0 then print(time_stamp().." dispels all end") end
		OverTimeDispelTickOn = false
		OverTimeDispelTimer = 0
	end
end

function DPSMateX.DB:Dispels(cause, Dname, target, aura)
	if not DPSMateX.HasDispelModules then return end
	
	cause = self:BuildUser(cause)
	target = self:BuildUser(target)
	Dname = self:BuildAbility(Dname)
	aura = self:BuildAbility(aura)
	
	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.Dispels[cat][cause] then
			DPSMateX.DBCache.Dispels[cat][cause] = {
				i = {
					[1] = 0,
					[2] = {}
				},
			}
		end
		gen = DPSMateX.DBCache.Dispels[cat][cause]
		if not gen[Dname] then
			gen[Dname] = {}
		end
		if not gen[Dname][target] then 
			gen[Dname][target] = {}
		end
		path = gen[Dname][target]
		if not path[aura] then
			path[aura] = 0
		end
		path[aura] = path[aura]+1
		gen["i"][1] = gen["i"][1]+1
		tinsert(gen["i"][2], {DPSMateX.CombatTime[val], aura, target, GameTime_GT()})
	end
	self.NeedUpdate = true
end

function DPSMateX.DB:UnregisterDeath(target)
	if not DPSMateX.EnabledModules["deaths"] then return end
	if strfind(target, "%s") then return end
	target = self:BuildUser(target)
	local p
	for cat, val in pairs(tablemodes) do 
		if DPSMateX.DBCache.Deaths[cat][target] then
			DPSMateX.DBCache.Deaths[cat][target][1]["i"][1]=1 --mark as dead
			DPSMateX.DBCache.Deaths[cat][target][1]["i"][2]=GameTime_GT()
			DPSMateX.DBCache.Deaths[cat][target][1]["i"][3]=(DPSMateX.turtle_wow and GT()) or 0
			if cat==1 and DPSMateX.Parser.TargetParty[DPSMateX:GetUserById(target)] then 
				p = DPSMateX.DBCache.Deaths[cat][target][1][1]
				DPSMateX:Broadcast(4, DPSMateX:GetUserById(target), DPSMateX:GetUserById(p[1]), DPSMateX:GetAbilityById(p[2]), p[3]) 
			end
		end
	end
end

function DPSMateX.DB:DeathHistory(targetname, user, ability, amount, hit, crit, type, crush)
	if not targetname or not DPSMateX.EnabledModules["deaths"] then return end

	local target = self:BuildUser(targetname)
	ability = self:BuildAbility(ability, nil, nil, user)
	local cause = self:BuildUser(user)

	local hitCritCrush
	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.Deaths[cat][target] then
			DPSMateX.DBCache.Deaths[cat][target] = {}
		end
		gen = DPSMateX.DBCache.Deaths[cat][target]
		if not gen[1] then
			gen[1] = {
				i = {
					[1] = 0,
					[2] = "",
				},
			}
		end

		--if gen[1]["i"][1]==1 and GT()-gen[1]["i"][3]>2 then -- already dead
		if gen[1]["i"][1]==1 then -- already dead
			if GT() - gen[1]["i"][3] > 2 then
				tinsert(gen, 1, {i = {0,""}})
		  	end
		end

		hitCritCrush = 0
		if crit==1 then hitCritCrush = 1 elseif crush==1 then hitCritCrush = 2 end
		tinsert(gen[1], 1, {
			[1] = cause,
			[2] = ability,
			[3] = amount,
			[4] = hitCritCrush,
			[5] = type,
			[6] = DPSMateX.CombatTime[val],
			[7] = GameTime_GT(),
		})
		if gen[1][21] then
			tremove(gen[1], 21)
		end
	end
end

function DPSMateX.DB:AwaitAfflicted(cause, ability, target, time)
	for cat, val in pairs(DPSMateX.Temp.AfflictedStun) do
		if val[1]==cause and ((val[4]+0.5)<=time or (val[4]-0.5)>=time) then
			return
		end
	end
	tinsert(DPSMateX.Temp.AfflictedStun, {cause,ability,target,time})
end

function DPSMateX.DB:ConfirmAfflicted(target, ability, time)
	for cat, val in pairs(DPSMateX.Temp.AfflictedStun) do
		if val[2]==ability and val[3]==target and val[4]<=time then
			if DPSMateX.Parser.Kicks[ability] then self:AssignPotentialKick(val[1], val[2], val[3], time) end
			self:EnemyDamage(true, DPSMateX.DBCache.EDT, val[1], ability, 1, 0, 0,0,0, 0,0, target, 0, 0)
			tremove(DPSMateX.Temp.AfflictedStun, cat)
			return 
		end
	end
end

function DPSMateX.DB:RegisterPotentialKick(target, ability, time)
	if DB.has_nampower then return end --nampower dont need this

	if not DPSMateX.EnabledModules["interrupts"] then return end
	--不记录团队或队伍玩家施法被打断
	if DPSMateX.Parser.TargetParty[target] then return end
	for cat, val in ipairs(DPSMateX.Temp.AwaitKick) do
		if val[1]==target and val[2]==ability then
			val[3] = time
			return
		end
	end
	tinsert(DPSMateX.Temp.AwaitKick, {target, ability, time})
end

function DPSMateX.DB:UnregisterPotentialKick(cause, ability, time)
	if not DPSMateX.EnabledModules["interrupts"] then return end
	for cat, val in ipairs(DPSMateX.Temp.AwaitKick) do
		if val[1]==cause and val[2]==ability and val[3]<=time then
			tremove(DPSMateX.Temp.AwaitKick, cat)
			break
		end
	end
end

function DPSMateX.DB:AssignPotentialKick(cause, ability, target, time)
	for cat, val in ipairs(DPSMateX.Temp.AwaitKick) do
		if val[1] == target and val[3] <= time then
			if not val[6] then
				val[6] = cause
				val[7] = ability
				if val[5] then --val[5] for superwow kick, otherwise fall to UpdateKicks
					self:Kick(val[6], val[1], val[7], val[2])
					tremove(DPSMateX.Temp.AwaitKick, cat)
				end
			end
		end
	end
end

function DPSMateX.DB:UpdateKicks()
	local time = GT()
	local duration = self.has_superwow and 1.5 or 10

	for cat, val in ipairs(DPSMateX.Temp.AwaitKick) do
		if (time-val[3])>=duration then
			if not self.has_superwow then --superwow log interrupts via UNIT_CASTEVENT
				if val[6] then
					self:Kick(val[6], val[1], val[7], val[2])
				end
			end
			tremove(DPSMateX.Temp.AwaitKick, cat)
		end
	end
end

--for superwow only
function DPSMateX.DB:Kicked(whom, ability) 
	local time = GT()
	for cat, val in pairs(DPSMateX.Temp.AwaitKick) do
		if val[1] == whom then
			val[2] = ability
			val[3] = time
			val[5] = 1
			return
		end
	end

	tinsert(DPSMateX.Temp.AwaitKick, {whom, ability, time, nil, 1})
end

function DPSMateX.DB:Kick(cause, target, causeAbility, targetAbility)
	if not DPSMateX.EnabledModules["interrupts"] then return end
	target = self:BuildUser(target)
	cause = self:BuildUser(cause)
	causeAbility = self:BuildAbility(causeAbility)
	targetAbility = self:BuildAbility(targetAbility)
	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.Interrupts[cat][cause] then
			DPSMateX.DBCache.Interrupts[cat][cause] = {
				i = {
					[1] = 0,
					[2] = {}
				},
			}
		end
		gen = DPSMateX.DBCache.Interrupts[cat][cause]
		if not gen[causeAbility] then
			gen[causeAbility] = {}
		end
		if not gen[causeAbility][target] then
			gen[causeAbility][target] = {}
		end
		path = gen[causeAbility][target]
		if not path[targetAbility] then
			path[targetAbility] = 0
		end
		gen["i"][1] = gen["i"][1] + 1
		tinsert(gen["i"][2], {DPSMateX.CombatTime[val], GameTime_GT(), targetAbility, target})
		path[targetAbility]=path[targetAbility]+1
	end
end

function DPSMateX.DB:AwaitingBuff(caster, target, ability, time)
	tinsert(DPSMateX.Temp.AwaitBuff, {caster, ability, target, time})
end

function DPSMateX.DB:ClearAwaitBuffs()
	local time = GT()
	for cat, val in pairs(DPSMateX.Temp.AwaitBuff) do
		if (time-(val[4] or 0))>=5 then
			DPSMateX.Temp.AwaitBuff[cat] = nil
		end
	end
end

function DPSMateX.DB:ConfirmBuff(target, ability, time)
	for cat, val in pairs(DPSMateX.Temp.AwaitBuff) do
		if val[4]<=(time or 0) then
			if val[2]==ability and val[3]==target then
				self:BuildBuffs(val[1], target, ability, false)
				tremove(DPSMateX.Temp.AwaitBuff, cat)
				return val[1] --return the caster
			end
		end
	end

	self:BuildBuffs(self.UserUnknown, target, ability, false)
end

function DPSMateX.DB:BuildBuffs(cause, target, ability, bool)
	if not DPSMateX.EnabledModules["aurasgained"] then return end

	target = self:BuildUser(target)
	cause = self:BuildUser(cause)

	if not cause then return end

	ability = self:BuildAbility(ability)
	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.AurasGained[cat][target] then
			DPSMateX.DBCache.AurasGained[cat][target] = {}
		end
		gen = DPSMateX.DBCache.AurasGained[cat][target]
		if not gen[ability] then
			gen[ability] = {
				[1] = {},
				[2] = {},
				[3] = {},
				[4] = bool,
				[5] = 0,
				[6] = 0,
			}
		end
		path = gen[ability]
		if not path[3][cause] then
			path[3][cause] = 0
		end
		for i=1, (path[5]-path[6]) do
			tinsert(path[2], path[1][path[6]+1])
			path[6] = path[6] + 1
		end
		tinsert(path[1], DPSMateX.CombatTime[val])
		path[5] = path[5] + 1
		path[3][cause] = path[3][cause] + 1
	end
	self.NeedUpdate = true
end

local DPSMateX_Tooltip
local DPSMateX_TooltipTextLeft1
local DPSMateX_TooltipTextRight1
local ToolTipParent

function DPSMateX.DB:FillDebuffType(target, ability)
	local _, ab = self:BuildAbility(ability)

	if ab and not ab[2] then
		_,target = self:BuildUser(target)
		local unit = DPSMateX.Parser.TargetParty[target]
		if unit then
			DPSMateX_Tooltip = DPSMateX_Tooltip or getglobal("DPSMateX_Tooltip")
			DPSMateX_TooltipTextLeft1 = DPSMateX_TooltipTextLeft1 or getglobal("DPSMateX_TooltipTextLeft1")
			DPSMateX_TooltipTextRight1 = DPSMateX_TooltipTextRight1 or getglobal("DPSMateX_TooltipTextRight1")
			ToolTipParent = ToolTipParent or UIParent

			for i = 1, 16 do
				DPSMateX_Tooltip:ClearLines()
				DPSMateX_Tooltip:SetOwner(ToolTipParent, "ANCHOR_NONE")
				DPSMateX_Tooltip:SetUnitDebuff(unit, i)
				local text = DPSMateX_TooltipTextLeft1:GetText()
				
				if not text then break end

				if text == ability then
					ab[2] = DPSMateX_TooltipTextRight1:GetText() or ""
					break
				end
			end
		end
	end
end

function DPSMateX.DB:DestroyBuffs(target, ability)
	if not DPSMateX.EnabledModules["aurasgained"] then return end
	target = self:BuildUser(target)
	local abilityId = self:BuildAbility(ability)
	local TL

	for cat, val in pairs(tablemodes) do 
		if not DPSMateX.DBCache.AurasGained[cat][target] then
			DPSMateX.DBCache.AurasGained[cat][target] = {}
		end

		gen = DPSMateX.DBCache.AurasGained[cat][target]

		if ability ~= "all" then
			if not gen[abilityId] then
				gen[abilityId] = {
					[1] = {},
					[2] = {},
					[3] = {},
					[4] = nil,
					[5] = 0,
					[6] = 0,
				}
			else
				path = gen[abilityId]
				TL = path[6]+1
				if not path[1][TL] then
					path[1][TL] = DPSMateX.CombatTime[val]
					path[5] = path[5] + 1
				end
				tinsert(path[2], DPSMateX.CombatTime[val])
				path[6] = path[6] + 1
			end
		else --detroy all
			for _,path in gen do
				TL = path[6]+1
				if not path[1][TL] then
					path[1][TL] = DPSMateX.CombatTime[val]
					path[5] = path[5] + 1
				end
				tinsert(path[2], DPSMateX.CombatTime[val])
				path[6] = path[6] + 1
			end
		end
	end
	self.NeedUpdate = true
end

function DPSMateX.DB:GetOptionsTrue(i,k)
	for cat,val in pairs(DPSMateX.Settings["windows"][k]["options"][i]) do
		if val then
			return cat
		end
	end
end

function DPSMateX.DB:UpdatePlayerCBT(cbt)
	local notInCombat = true
	local type = "raid"
	local num = GetNumRaidMembers()
	local cbt1, cbt2 = DPSMateX.CombatTime["effective"][1], DPSMateX.CombatTime["effective"][2]
	if num<=0 then
		type = "party"
		num = GetNumPartyMembers()
		if UnitAffectingCombat("player") then
			local player = DPSMateX.Parser.playername
			cbt1[player] = (cbt1[player] or 0) + cbt
			cbt2[player] = (cbt2[player] or 0) + cbt
			notInCombat = false
		end
	end
	local name
	for i=1, num do
		if UnitAffectingCombat(type..i) then
			name = UnitName(type..i)
			cbt1[name] = (cbt1[name] or 0) + cbt
			cbt2[name] = (cbt2[name] or 0) + cbt
			notInCombat = false
		end
	end
	return notInCombat
end

local notInCombat, cbtpt
local init=true
local initTime = 0
local klhtmLocal, klhtmInit

local org_collectgarbage = collectgarbage

local gc_time, meminfo
local gcinfo = gcinfo

function collectgarbage()
	if DPSMateX.Settings.collectgarbage and CombatState then return end
	gc_time = GT()
	return org_collectgarbage();
end

function DPSMateX.DB:OnUpdate()
	local arg1 = arg1

	if (CombatState) then
		notInCombat = false
		LastUpdate = LastUpdate + arg1
		if LastUpdate>=UpdateTime then
			cbtpt = DPSMateX.CombatTime["effective"]
			DPSMateX.CombatTime["total"] = DPSMateX.CombatTime["total"] + LastUpdate
			DPSMateX.CombatTime["current"] = DPSMateX.CombatTime["current"] + LastUpdate
			notInCombat = self:UpdatePlayerCBT(LastUpdate) -- Slowing it down
			
			-- Check NPC E CBT Time (May be inaccurate) -> Can be used as active time later
			for cat, _ in pairs(DPSMateX.Temp.ActiveMob) do
				local name = DPSMateX:GetUserById(cat)
				cbtpt[1][name] = (cbtpt[1][name] or 0) + LastUpdate
				cbtpt[2][name] = (cbtpt[2][name] or 0) + LastUpdate
			end
			DPSMateX:WipeTable(DPSMateX.Temp.ActiveMob)
			DPSMateX:WipeTable(DPSMateX.Parser.SendSpell)
			LastUpdate = 0
		end
		
		if DPSMateX.bTrackingThunderArmor then
			TrackingProcTimer = TrackingProcTimer + arg1
			if TrackingProcTimer >= 0.2 or notInCombat then
				self:TrackingProcAll(GT())
				TrackingProcTimer = 0
			end
		end

		if notInCombat then
			CombatState = false
			if DPSMateX.Insights then DPSMateX.Insights:EndCombat() end

			if DPSMateX.Settings.collectgarbage then
				local curmem = gcinfo()
				meminfo = meminfo or curmem
				gc_time = gc_time or 0

				if (GT() - gc_time > 60) or (curmem - meminfo > 16*1024) then
					collectgarbage()
					meminfo = curmem
					--print("DPSMateX: Performing automatic garbage collection.")
					gc_time = GT()
				end
			end
		end
	else
		self.MainUpdate = self.MainUpdate + arg1
	end
	
	MainLastUpdate = MainLastUpdate + arg1
	StatusBarUpdate = StatusBarUpdate + arg1

	if self.NeedUpdate then
		self.NeedUpdate = false
		NeedMainUpdate = true
		NeedStatusBarUpdate = true
	end
	
	if MainLastUpdate>=MainUpdateTime then
		if NeedMainUpdate then
			self:UpdateKicks()
			if self.ktmavail then
				self:UpdateThreat()
			end
			NeedMainUpdate = false
		end
		MainLastUpdate = 0
	end

	if StatusBarUpdate >= 1 then
		if NeedStatusBarUpdate then
			DPSMateX:SetStatusBarValue(true)
			NeedStatusBarUpdate = false
		end
		StatusBarUpdate = 0
	end

	if OverTimeDispelTickOn then
		OverTimeDispelTimer = OverTimeDispelTimer + arg1
		if OverTimeDispelTimer > 2 then --try totem dispel 2 seconds later
			self:TryHotDispel()
			self:TryTotemDispels()
			self:CheckDispels()
			OverTimeDispelTimer = 0
		end
	end

	if self.MainUpdate>=30 then
		self:ClearAwaitBuffs()
		self:ClearAwaitAbsorb()
		--self:ClearAwaitHotDispel()
		self.MainUpdate = 0
	end

	-- Init delay to make sure klhtm module is loaded
	if init then
		initTime = initTime + arg1
		if (initTime > 5) then
			if not klhtmInit then klhtmLocal = klhtm end
			klhtmInit = true
			if klhtmLocal then
				local oldModSpecialAttack = klhtmLocal.combat.specialattack
				klhtmLocal.combat.specialattack = function(abilityid, target, damage, iscrit, spellschool)
					oldModSpecialAttack(abilityid, target, damage, iscrit, spellschool)
					if DPSMateX.DB.specialAbTrans[abilityid] then
						if not DPSMateX.DB.KTMHOOK[DPSMateX.DB.specialAbTrans[abilityid]] then
							DPSMateX.DB.KTMHOOK[DPSMateX.DB.specialAbTrans[abilityid]] = {}
						end
						tinsert(DPSMateX.DB.KTMHOOK[DPSMateX.DB.specialAbTrans[abilityid]], {target, klhtmLocal.combat.event.threat})
						DPSMateX.DB:Threat(DPSMateX.Parser.playername, DPSMateX.DB.specialAbTrans[abilityid], target, klhtmLocal.combat.event.threat, 1)
					end
				end

				local oldModNormalAttack = klhtmLocal.combat.normalattack
				klhtmLocal.combat.normalattack = function(spellname, spellid, damage, isdot, target, iscrit, spellschool)
					oldModNormalAttack(spellname, spellid, damage, isdot, target, iscrit, spellschool)
					if not DPSMateX.DB.KTMHOOK[spellname] then
						DPSMateX.DB.KTMHOOK[spellname] = {}
					end
					tinsert(DPSMateX.DB.KTMHOOK[spellname], {target, klhtmLocal.combat.event.threat})
					DPSMateX.DB:Threat(DPSMateX.Parser.playername, spellname, target, klhtmLocal.combat.event.threat, 1)
				end

				local oldModHeal = klhtmLocal.combat.registerheal
				klhtmLocal.combat.registerheal = function(spellname, spellid, amount, target)
					local ka, kb = strfind(spellname, " critically")
					if (ka and kb) then spellname = strsub(spellname, 1, ka-1) end
					oldModHeal(spellname, spellid, amount, target)
					if not DPSMateX.DB.KTMHOOK[spellname] then
						DPSMateX.DB.KTMHOOK[spellname] = {}
					end
					tinsert(DPSMateX.DB.KTMHOOK[spellname], {target, klhtmLocal.combat.event.threat})
					DPSMateX.DB:Threat(DPSMateX.Parser.playername, spellname, target, klhtmLocal.combat.event.threat, 1)
				end

				local oldModPowerGain = klhtmLocal.combat.powergain
				klhtmLocal.combat.powergain = function(amount, powertype, spellid)
					oldModPowerGain(amount, powertype, spellid)
					if not DPSMateX.DB.KTMHOOK[powertype] then
						DPSMateX.DB.KTMHOOK[powertype] = {}
					end
					local target = UnitName("target") or DPSMateX.Parser.playername
					tinsert(DPSMateX.DB.KTMHOOK[powertype], {target, klhtmLocal.combat.event.threat})
					DPSMateX.DB:Threat(DPSMateX.Parser.playername, powertype, target, klhtmLocal.combat.event.threat, 1)
				end
				self.ktmavail = true
			end
			init = false
		end
	end
end

-- Type: 1 => FriendlyFire, 2 => Damage taken, 3 => Debuff taken
function DPSMateX.DB:BuildFail(type, user, cause, ability, amount)
	if not cause or not DPSMateX.EnabledModules["fails"] then return end

	ability = self:BuildAbility(ability, nil, nil, user)
	local username
	user,username = self:BuildUser(user)
	cause = self:BuildUser(cause)
	local time = GameTime_GT()
	for cat, val in pairs(tablemodes) do
		if not DPSMateX.DBCache.Fails[cat][cause] then
			DPSMateX.DBCache.Fails[cat][cause] = {}
		end
		tinsert(DPSMateX.DBCache.Fails[cat][cause], 1, {
			[1] = type,
			[2] = user,
			[3] = ability,
			[4] = amount,
			[5] = DPSMateX.CombatTime[val],
			[6] = time,
		})
	end
	DPSMateX:Broadcast(3, username, cause, ability, amount, type)
	self.NeedUpdate = true
end

function DPSMateX.DB:BuildActiveCC(target, ability)
	if not DPSMateX.Temp.ActiveCC[target] then
		DPSMateX.Temp.ActiveCC[target] = {}
	end
	DPSMateX.Temp.ActiveCC[target][ability] = true
end

function DPSMateX.DB:RemoveActiveCC(target, ability)
	if not DPSMateX.Temp.ActiveCC[target] then
		DPSMateX.Temp.ActiveCC[target] = {}
	end
	if DPSMateX.Temp.ActiveCC[target][ability] then
		DPSMateX.Temp.ActiveCC[target][ability] = false;
	end
end

function DPSMateX.DB:CheckActiveCC(cause, target)
	if DPSMateX.Temp.ActiveCC[target] then
		for cat, val in pairs(DPSMateX.Temp.ActiveCC[target]) do
			if val then
				for c, v in pairs(DPSMateX.Temp.ActiveCC[target]) do
					DPSMateX.Temp.ActiveCC[target][c] = false
				end
				self:ProcCCBreaker(target, cat, cause)
				return true
			end
		end
	end
	return false
end

function DPSMateX.DB:ProcCCBreaker(target, ability, cause)
	if not DPSMateX.EnabledModules["ccbreaker"] then return end
	local time = GameTime_GT()
	ability = self:BuildAbility(ability)
	cause = self:BuildUser(cause)
	target = self:BuildUser(target)
	for cat, val in pairs(tablemodes) do
		if not DPSMateX.DBCache.CCBreaker[cat][cause] then
			DPSMateX.DBCache.CCBreaker[cat][cause] = {}
		end
		tinsert(DPSMateX.DBCache.CCBreaker[cat][cause], 1, {
			[1] = ability,
			[2] = target,
			[3] = DPSMateX.CombatTime[val],
			[4] = time
		})
	end
end

function DPSMateX.DB:RegisterShieldAsHeal(caster, target, effect)
	if DPSMateX.Parser:GetUnitByName(target) and DPSMateX.Parser:GetUnitByName(caster) then
		local sc = DPSMateX.Parser.TargetShieldCasts
		sc[target] = sc[target] or {}
		sc[target][effect] = caster
	end
end

function DPSMateX.DB:RemoveShieldAsHeal(effect, target)
	local sc = DPSMateX.Parser.TargetShieldCasts[target]
	if sc and sc[effect] then
		sc[effect] = nil
	end
end

DPSMateX.DB:SetScript("OnEvent", function()
	-- Copy event arguments before legacy handlers can invoke other frame scripts.
	local extension, ev, receiver = DPSMateX.Insights, event, this
	local a1,a2,a3,a4,a5,a6,a7,a8,a9 = arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9
	if extension then extension:PrepareEvent(ev,a1,a2,a3,a4) end
	receiver[ev](a1)
	if extension then extension:OnEvent(ev, a1,a2,a3,a4,a5,a6,a7,a8,a9) end
end)

function DPSMateX.DB:IsCombatActive()
	return CombatState
end

function DPSMateX.DB:BeginInsightsCombat()
	if not CombatState then
		DPSMateX.Options:NewSegment()
		CombatState = true
		if DPSMateX.Insights then DPSMateX.Insights:StartCombat() end
	end
end
DPSMateX.DB:SetScript("OnUpdate", function() this:OnUpdate() end)

DPSMateX.DB.trackedSpells = {
	[9907] = "Faerie Fire",
	[17392] = "Faerie Fire (Feral)",
	[11597] = "Sunder Armor",
	[11722] = "Curse of the Elements",
	[11717] = "Curse of Recklessness",
	[17937] = "Curse of Shadow",
	[11708] = "Curse of Weakness",
	[11719] = "Curse of Tongues",
	[11198] = "Expose Armor", --only tracking max rank for above spells
} 

if GetLocale() == "zhCN" then
	DPSMateX.DB.trackedSpells = {
		[9907] = "精灵之火",
		[17392] = "精灵之火（野性）",
		[11597] = "破甲攻击",
		[11722] = "元素诅咒",
		[11717] = "鲁莽诅咒",
		[17937] = "暗影诅咒",
		[11708] = "虚弱诅咒",
		[11719] = "语言诅咒",
		[11198] = "破甲", --only tracking max rank for above spells
	}
end

local locale = GetLocale()
local CombatLogAdd = CombatLogAdd
local GetSpellNameAndRankForId = GetSpellNameAndRankForId

DPSMateX.DB.AUTO_ATTACK_EVENT = function()
	local attackerGuid, targetGuid, totalDamage, hitInfo, victimState, subDamageCount, blockedAmount, totalAbsorb, totalResist = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
	local attackerName = UnitName(attackerGuid)
	if not attackerName then attackerName = attackerGuid end
	local targetName = UnitName(targetGuid)
	--print auto attacks names and all arguments
	--concate all arguments to one string
	local str = attackerName.." "..targetName.." "..totalDamage.." hi "..hitInfo.." vs "..victimState.." sc "..subDamageCount.." "..blockedAmount.." "..totalAbsorb.." "..totalResist
	--if attackerGuid == DPSMateX.Parser.player then print(str) end
	print(str) 
end

DPSMateX.DB.AUTO_ATTACK_SELF = function()
	DPSMateX.Parser:HitsX()
end

DPSMateX.DB.AUTO_ATTACK_OTHER = function()
	DPSMateX.Parser:HitsX()
end

DPSMateX.DB.ENV_DAMAGE_EVENT = function()
	local unitGuid, dmgType, damage, absorb, resist	= arg1, arg2, arg3, arg4, arg5
	local unitName = UnitName(unitGuid)

	local str = unitName.." env "..damage.." "..dmgType.." "..absorb.." "..resist
	--if attackerGuid == DPSMateX.Parser.player then print(str) end
	print(str) 
end

DPSMateX.DB.ENVIRONMENTAL_DMG_SELF = function()
	DPSMateX.Parser:EnvDamageX()
end

DPSMateX.DB.ENVIRONMENTAL_DMG_OTHER = function()
	DPSMateX.Parser:EnvDamageX()
end

DPSMateX.DB.DAMAGE_SHIELD_EVENT = function()
	local unitGuid, targetGuid, damage, spellSchool = arg1, arg2, arg3, arg4

	local unitName = UnitName(unitGuid)
	local targetName = UnitName(targetGuid)

	local str = unitName.." reflects "..targetName.." "..damage.." "..spellSchool
	print(str)
end

DPSMateX.DB.DAMAGE_SHIELD_SELF = function()
	DPSMateX.Parser:DamageShiledX()
end

DPSMateX.DB.DAMAGE_SHIELD_OTHER = function()
	DPSMateX.Parser:DamageShiledX()
end

DPSMateX.DB.SPELL_DISPEL_EVENT = function()
	local casterGuid, targetGuid, spellId = arg1, arg2, arg3

	local unitName = casterGuid and UnitName(casterGuid) or "nil"
	local targetName = targetGuid and UnitName(targetGuid) or "nil"

	local str = unitName.." dispels "..targetName.." "..GetSpellNameAndRankForId(spellId)
	print(str)
end

DPSMateX.DB.SPELL_DISPEL_BY_SELF = function()
	DPSMateX.Parser:SpellDispelX()
end

DPSMateX.DB.SPELL_DISPEL_BY_OTHER = function()
	DPSMateX.Parser:SpellDispelX()
end

DPSMateX.DB.SPELL_FAILED_SELF_EVENT = function()
	local spellId, spellResult, failedByServer = arg1, arg2, arg3

	local str = (GetSpellNameAndRankForId(spellId) or "nil").." failed "..(spellResult or "nil").." "..(failedByServer or "nil")
	print(str)
end

DPSMateX.DB.SPELL_FAILED_OTHER_EVENT = function()
	local casterGuid, spellId = arg1, arg2

	local str = (GetSpellNameAndRankForId(spellId) or "nil").." failed ".. " for "..(UnitName(casterGuid) or "nil")
	print(str)
end

DPSMateX.DB.SPELL_FAILED_SELF = function() 
	DPSMateX.Parser:SpellFailedSelfX()
end

 DPSMateX.DB.SPELL_FAILED_OTHER = function()
	DPSMateX.Parser:SpellFailedOtherX()
end

DPSMateX.DB.SPELL_START_EVENT = function()
 	local itemId, spellId, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed, corpseOwnerGuid = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8

	local str = (UnitName(casterGuid) or "nil").." start "..(GetSpellNameAndRankForId(spellId) or "nil").." ("..itemId..").. on "..(UnitName(targetGuid) or "nil").." "..castFlags.." "..numTargetsHit.." "..numTargetsMissed
	if casterGuid == DPSMateX.Parser.player then print(str) end
end

DPSMateX.DB.SPELL_START_SELF = function() 
	DPSMateX.Parser:SpellStartX()
end

DPSMateX.DB.SPELL_START_OTHER = function()
	DPSMateX.Parser:SpellStartX()
end

DPSMateX.DB.SPELL_GO_EVENT = function()
 	local itemId, spellId, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed, corpseOwnerGuid = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8

	local str = (UnitName(casterGuid) or "nil").." cast "..(GetSpellNameAndRankForId(spellId) or "nil").." ("..itemId..").. on "..(UnitName(targetGuid) or "nil").." "..castFlags.." "..numTargetsHit.." "..numTargetsMissed
	if casterGuid == DPSMateX.Parser.player then print(str) end
end

DPSMateX.DB.SPELL_GO_SELF = function() 
	DPSMateX.Parser:SpellGoX()
end

DPSMateX.DB.SPELL_GO_OTHER = function()
	DPSMateX.Parser:SpellGoX()
end

DPSMateX.DB.UNIT_DIED_EVENT = function()
	local unitGuid = arg1

	local str = UnitName(unitGuid).." dies"
	print(str)
end

DPSMateX.DB.UNIT_DIED = function()
	DPSMateX.Parser:UnitDiedX()
end

DPSMateX.DB.CHAT_MSG_SPELL_SELF_BUFF = function()
	DPSMateX.Parser:ExtractProcTrigger()
end

DPSMateX.DB.CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF = function()
	DPSMateX.Parser:ExtractProcTrigger()
end

DPSMateX.DB.CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF = function()
	DPSMateX.Parser:ExtractProcTrigger()
end

DPSMateX.DB.SPELL_DAMAGE_EVENT = function()
	local targetGuidStr,casterGuidStr,spellId,amount,mitigationStr,hitInfo,spellSchool,effectAuraStr = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8
	local attackerName = UnitName(casterGuidStr)
	local targetName = UnitName(targetGuidStr)
	local spell = GetSpellNameAndRankForId(spellId)
	
	local str = "SPELL "..""..(attackerName or "nil").." "..(GetSpellNameAndRankForId(spellId) or spellId).." "..(targetName or "nil").." "..amount.." "..hitInfo.." ("..mitigationStr..") "..spellSchool.." ("..effectAuraStr..")"
	--if casterGuidStr == DPSMateX.Parser.player then print(str) end
	print(str)
end

DPSMateX.DB.SPELL_DAMAGE_EVENT_SELF = function()
	DPSMateX.Parser:SpellDamageX()
end

DPSMateX.DB.SPELL_DAMAGE_EVENT_OTHER = function()
	DPSMateX.Parser:SpellDamageX()
end

DPSMateX.DB.SPELL_MISS = function()
	local casterGuid, targetGuid, spellId, missInfo = arg1, arg2, arg3, arg4
	local attackerName = UnitName(casterGuid)
	local targetName = UnitName(targetGuid)

	local str = "SPELL_MISS "..""..attackerName.." "..GetSpellNameAndRankForId(spellId).." "..targetName.." "..missInfo
	if casterGuid == DPSMateX.Parser.player then print(str) end
end

DPSMateX.DB.SPELL_MISS_SELF = function()
	DPSMateX.Parser:SpellDamageMiss()
end

DPSMateX.DB.SPELL_MISS_OTHER = function()
	DPSMateX.Parser:SpellDamageMiss()
end

DPSMateX.DB.BUFF_CHANGED_EVENT = function(self, debuff, caston)
	local guid, luaSlot, spellId, stacks, auraLevel, auraSlot, state = arg1, arg2, arg3, arg4, arg5, arg6, arg7
	guid = guid or "nil"
	luaSlot = luaSlot or "nil"
	stacks = stacks or "nil"
	auraLevel = auraLevel or "nil"
	auraSlot = auraSlot or "nil"
	state = state or "nil"

	local str = (debuff and "DEBUFF " or "BUFF ")..(caston and "add " or "rmv ")..UnitName(guid).." "..luaSlot.." "..(GetSpellNameAndRankForId(spellId) or "nil").." "..stacks.." "..auraLevel.." "..auraSlot.." "..state
	if casterGuidStr == DPSMateX.Parser.player then print(str) end
	ChatFrame1:AddMessage(date("%H:%M:%S ")..str)
end

DPSMateX.DB.BUFF_ADDED_SELF = function()
	DPSMateX.Parser:AuraChangedX(false, true)
end

DPSMateX.DB.BUFF_ADDED_OTHER = function()
	DPSMateX.Parser:AuraChangedX(false, true)
end

DPSMateX.DB.DEBUFF_ADDED_SELF = function()
	DPSMateX.Parser:AuraChangedX(true, true)
end

DPSMateX.DB.DEBUFF_ADDED_OTHER = function()
	DPSMateX.Parser:AuraChangedX(true, true)
end

DPSMateX.DB.BUFF_REMOVED_SELF = function()
	DPSMateX.Parser:AuraChangedX(false, false)
end

DPSMateX.DB.BUFF_REMOVED_OTHER = function()
	DPSMateX.Parser:AuraChangedX(false, false)
end

DPSMateX.DB.DEBUFF_REMOVED_SELF = function()
	DPSMateX.Parser:AuraChangedX(true, false)
end

DPSMateX.DB.DEBUFF_REMOVED_OTHER = function()
	DPSMateX.Parser:AuraChangedX(true, false)
end

DPSMateX.DB.SPELL_HEAL_EVENT = function()
	local targetGuid, casterGuid, spellId, amount, critical, periodic = arg1, arg2, arg3, arg4, arg5, arg6
	local str = "HEAL "..UnitName(casterGuid).." "..UnitName(targetGuid).." "..GetSpellNameAndRankForId(spellId).." "..amount.." "..critical.." "..periodic

	print(date("%H:%M:%S ")..str)
end

DPSMateX.DB.SPELL_HEAL_BY_SELF = function()
	DPSMateX.Parser:SpellHealX()
end

DPSMateX.DB.SPELL_HEAL_BY_OTHER = function()
	DPSMateX.Parser:SpellHealX()
end

DPSMateX.DB.AURA_CAST_ON_EVENT = function()
	local spellId, casterGuid, targetGuid, effect, effectAuraName, effectAmplitude, effectMiscValue, durationMs, auraCapStatus = arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
	--effect 王者 = SPELL_EFFECT_APPLY_AURA = 6
	--effectAuraName 王者 = SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE = 137

	local str = "ACAST "..""..GetSpellNameAndRankForId(spellId).." "..UnitName(casterGuid).." "..(targetGuid and UnitName(targetGuid) or "nil ").." "..effect.." "..effectAuraName.." "..effectAmplitude.." "..effectMiscValue.." "..durationMs.." "..auraCapStatus
	--if casterGuidStr == DPSMateX.Parser.player then print(str) end
	ChatFrame1:AddMessage(str)
end

DPSMateX.DB.AURA_CAST_ON_SELF = function()
	DPSMateX.Parser:AuraCastX(true, false)
end

DPSMateX.DB.AURA_CAST_ON_OTHER = function()
	DPSMateX.Parser:AuraCastX(true, false)
end

DPSMateX.DB.SPELL_ENERGIZE = function()
	local targetGuid, casterGuid, spellId, powerType, amount, periodic = arg1, arg2, arg3, arg4, arg5, arg6
	local attackerName = UnitName(casterGuid)
	local targetName = UnitName(targetGuid)
	--print auto attacks names and all arguments
	--concate all arguments to one string
	--local str = "SPELL_ENERGIZE"..""..attackerName.." "..GetSpellNameAndRankForId(spellId).." "..targetName.." "..amount.." "..powerType.." "..periodic
	--print(str)
end

DPSMateX.DB.SPELL_ENERGIZE_BY_SELF = function()
	DPSMateX.DB.SPELL_ENERGIZE()
end

DPSMateX.DB.SPELL_ENERGIZE_BY_OTHER = function()
	DPSMateX.DB.SPELL_ENERGIZE()
end

DPSMateX.DB.OnSpellStart = function(self, caster, spellId) 
	if not DPSMateX.Parser.TargetParty[caster] then
		DB:RegisterPotentialKick(caster, GetSpellNameAndRankForId(spellId), GT())
	end
end

DPSMateX.DB.OnSpellCast = function(self, caster, target, spellId) 
	local spell = GetSpellNameAndRankForId(spellId)
	if DPSMateX.bTrackingThunderArmor then
		if DPSMateX.DB.trackedSpells[spellId] then
			if not DPSMateX.Parser.TrackingSpell[caster] then
				DPSMateX.Parser.TrackingSpell[caster] = {spell, target, GT()}
			end
			if CombatLogAdd and locale == "zhCN" then
				CombatLogAdd((caster == Parser.player and "你" or UnitName(caster)).."对"..(UnitName(target) or "nil") .. "施放了"..GetSpellNameAndRankForId(spellId))
			end
		end
	end
	if Parser.TotemDispels[spell] then 
		DB:CastDispelTotem(spell, caster, GT()) 
	elseif Parser.Dispels[spell] then 
		DB:DispelCast(spell, target, caster, GT())
	end;
	if Parser.RCD[spell] then DPSMateX:Broadcast(2, caster, target, spell) end;
	--track 荷枪实弹
	if spell == "瞄准射击" then DB:RegisterLockNLoad(caster, target) end
end

DPSMateX.DB.OnSpellFailed = function(self, caster, spellId) 
	local spell = GetSpellNameAndRankForId(spellId)

	if not UnitIsPlayer(caster) then
		if CombatLogAdd and locale == "zhCN" then
			CombatLogAdd(UnitName(caster).."的".. spell .. "施放失败了")
		end
	end
	if not DPSMateX.Parser.TargetParty[caster] then DPSMateX.DB:Kicked(caster, spell) end
end

--no nampower fall to UNIT_CASTEVENT
DPSMateX.DB.UNIT_CASTEVENT = function()
	local action = arg3
	local caster = arg1

	if action == "MAINHAND" then
		AutoAttackAbility = AutoAttackAbility or { DPSMateX.L["AutoAttack"], DPSMateX.L["AutoAttackOffhand"] }
		DPSMateX.OffHandAttacking[caster] = nil
	elseif action == "OFFHAND" then
		AutoAttackAbility = AutoAttackAbility or { DPSMateX.L["AutoAttack"], DPSMateX.L["AutoAttackOffhand"] }
		DPSMateX.OffHandAttacking[caster] = 1
	elseif action == "START" then
		DB:OnSpellStart(caster, arg4)
	elseif action == "CAST" then
		if DPSMateX.Parser.TargetParty[caster] then
			local target = arg2
			local spellId = arg4
			DB:OnSpellCast(caster, target, spellId)
		end
	elseif action == "FAIL" then
		--"FAIL"发生在打断技能之前...
		--if arg1 ~= DPSMateX.Parser.player then
		DB:OnSpellFailed(caster, arg4)
	end
end
