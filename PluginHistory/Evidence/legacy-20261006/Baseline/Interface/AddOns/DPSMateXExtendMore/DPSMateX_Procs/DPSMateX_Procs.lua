local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.Procs = {}
DPSMateX.Modules.Procs.Hist = "Auras"
DPSMateX.Options.Options[1]["args"]["procs"] = {
	order = 234,
	type = 'toggle',
	name = DPSMateX.L["procs"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["procs"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["procs"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "procs", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Procs.Events = {
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PARTY_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
	"CHAT_MSG_SPELL_AURA_GONE_SELF",
	"CHAT_MSG_SPELL_AURA_GONE_OTHER",
	"CHAT_MSG_SPELL_AURA_GONE_PARTY",
}

-- Register the moodule
DPSMateX:Register("procs", DPSMateX.Modules.Procs, DPSMateX.L["procs"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
DPSMateX.Modules.Procs.nonProcProcs = {
	["Holy Strength"] = true,
	["Felstriker"] = true,
	["Sanctuary"] = true,
	["Fury of Forgewright"] = true,
	["Primal Blessing"] = true,
	["Spinal Reaper"] = true, -- To test
	["Netherwind Focus"] = true, -- To test
	["Parry"] = true, -- To test
	["Untamed Fury"] = true,
	["Aura of the Blue Dragon"] = true, -- Mana Darkmoon card
	["Invigorate"] = true,
	["Head Rush"] = true,
	["Enigma Resist Bonus"] = true,
	["Enigma Blizzard Bonus"] = true,
	["Not There"] = true,
	["Epiphany"] = true,
	["Inspiration"] = true,
	["Blessed Recovery"] = true,
	["Focused Casting"] = true,
	["Clearcasting"] = true,
	["Nature's Grace"] = true,
	["Battlegear of Eternal Justice"] = true,
	["Redoubt"] = true,
	["Vengeance"] = true,
	["Stormcaller's Wrath"] = true,
	["Ancestral Healing"] = true,
	["Vampirism"] = true,
	["Nightfall"] = true,
	["Cheat Death"] = true,
	["Flurry"] = true,
	["Enrage"] = true,
	["Quick Shots"] = true,
}

local pairs = pairs

-- Object pool variables
local new_values = {}
local total_value = {}
local sorted_values = {}
local evt_a, evt_d = {}, {}
local eval_temp = {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

function DPSMateX.Modules.Procs:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for cat, val in pairs(arr) do -- 2 Target
		local name = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(k, name) then
			local CV = 0
			for ca, va in pairs(val) do -- 3 ability
				local abilityName = DPSMateX:GetAbilityById(ca)
				if (DPSMateX.Parser.procs[abilityName] and va[4]) or self.nonProcProcs[abilityName] or DPSMateX.Parser.DmgProcs[abilityName] then
					for c, v in va[1] do -- 1 Ability
						CV=CV+1
					end
				end
			end
			if CV > 0 then
				new_values[k][name] = CV
				total_value[k] = total_value[k] + CV
			end
		end
	end

	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	for name, amount in pairs(new_values[k]) do
		local t = DPSMateX.Pool.get()
		tinsert(t, amount)
		tinsert(t, name)
		tinsert(sorted_values[k], t)
	end
	tsort(sorted_values[k], function(a, b) return a[1] > b[1] end)

	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.Procs:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	DPSMateX:WipeInPool(eval_temp)
	local total = 0
	local arr = DPSMateX:GetMode(k)
	for cat, val in pairs(arr[user[1]]) do -- 3 Ability
		local name = DPSMateX:GetAbilityById(cat)
		if (DPSMateX.Parser.procs[name] and val[4]) or self.nonProcProcs[name] or DPSMateX.Parser.DmgProcs[name] then
			local CV = 0
			for c, v in val[1] do -- 1 Ability
				CV=CV+1
			end
			if eval_temp[cat] then eval_temp[cat]=eval_temp[cat]+CV else eval_temp[cat]=CV end
		end
	end
	for cat, val in pairs(eval_temp) do
		local i = 1
		while true do
			if (not evt_d[i]) then
				tinsert(evt_d, i, val)
				tinsert(evt_a, i, cat)
				break
			else
				if evt_d[i] < val then
					tinsert(evt_d, i, val)
					tinsert(evt_a, i, cat)
					break
				end
			end
			i=i+1
		end
		total = total + val
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.Procs:GetSettingValues(arr, cbt, k)
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""; strt[2] = ""
	local p = ""
	local pt = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.Procs:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end; if totr <= 10000 then pt = "" end
		str[1] = ""; str[2] = ""; str[3] = ""
		if DPSMateX.Settings["columnsprocs"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsprocs"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, na[2])
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Procs:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.Procs:EvalTable(DPSMateX.CacheUser[user], k)
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i].." ("..strformat("%.2f", 100*c[i]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.Procs:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsProcs:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsProcs:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Procs:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsProcsTotal:UpdateDetails(obj, key)
end


