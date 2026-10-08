-- Global Variables
local DPSMateX = DPSMateX

DPSMateX.Modules.Casts = {}
DPSMateX.Modules.Casts.Hist = "EDTaken"
DPSMateX.Options.Options[1]["args"]["casts"] = {
	order = 270,
	type = 'toggle',
	name = DPSMateX.L["casts"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["casts"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["casts"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "casts", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Casts.Events = {
	"CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS",
	"CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",

	-- Damage taken (Also EDD) / DeathHistory
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_PARTY_MISSES",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE",
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_HITS",
	"CHAT_MSG_COMBAT_CREATURE_VS_CREATURE_MISSES",
	"CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
}

-- Register the moodule
DPSMateX:Register("casts", DPSMateX.Modules.Casts, DPSMateX.L["casts"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs

-- Object pool variables
local new_values = {}
local total_value = {}
local sorted_values = {}
local evt_a, evt_d = {}, {}
local gst_temp = {}
local eval_temp = {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

function DPSMateX.Modules.Casts:GetSortedTable(arr, k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0
	DPSMateX:WipeInPool(gst_temp)

	for cat, val in arr do
		for c, v in val do
			local CV = 0
			for ca, va in v do
				if ca~="i" then
					local abna = DPSMateX:GetAbilityById(ca)
					if abna~=DPSMateX.L["AutoAttack"] and abna~=DPSMateX.L["AutoAttackOffhand"] and abna~=DPSMateX.L["AutoShot"] then
						CV = CV + va[1] + va[5] + va[9] + va[10] + va[11] + va[12] + va[14] + va[18]
					end
				end
			end
			if gst_temp[c] then gst_temp[c] = gst_temp[c] + CV else gst_temp[c] = CV end
		end
	end
	for cat, val in pairs(gst_temp) do
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(cat)) then
			if val > 0 then
				local name = DPSMateX:GetUserById(cat)
				new_values[k][name] = val
				total_value[k] = total_value[k] + val
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

function DPSMateX.Modules.Casts:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	DPSMateX:WipeInPool(eval_temp)
	local total = 0
	local arr = DPSMateX:GetMode(k)
	for c, v in arr do
		if v[user[1]] then
			for ca, va in v[user[1]] do
				if ca~="i" then
					local CV = va[1] + va[5] + va[9] + va[10] + va[11] + va[12] + va[14] + va[18]
					if eval_temp[ca] then eval_temp[ca] = eval_temp[ca] + CV else eval_temp[ca] = CV end
				end
			end
		end
	end

	for cat, val in pairs(eval_temp) do
		if (not DPSMateX.CacheAbility[DPSMateX.L["AutoAttack"]] or cat~=DPSMateX.CacheAbility[DPSMateX.L["AutoAttack"]][1]) and
			(not DPSMateX.CacheAbility[DPSMateX.L["AutoAttackOffhand"]] or cat~=DPSMateX.CacheAbility[DPSMateX.L["AutoAttackOffhand"]][1]) and
			(not DPSMateX.CacheAbility[DPSMateX.L["AutoShot"]] or cat~=DPSMateX.CacheAbility[DPSMateX.L["AutoShot"]][1]) then
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
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.Casts:GetSettingValues(arr, cbt, k)
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""; strt[2] = ""
	local p = ""
	local pt = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.Casts:GetSortedTable(arr, k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end; if totr <= 10000 then pt = "" end
		str[1] = ""; str[2] = ""; str[3] = ""
		if DPSMateX.Settings["columnscasts"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnscasts"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, na[2])
		tinsert(tbl_amount, str[2]..str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Casts:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local c,b,a = DPSMateX.Modules.Casts:EvalTable(DPSMateX.CacheUser[user], k)
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not c[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(c[i]),a[i].." ("..strformat("%.2f", 100*a[i]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.Casts:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsCasts:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsCasts:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Casts:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsCastsTotal:UpdateDetails(obj, key)
end
