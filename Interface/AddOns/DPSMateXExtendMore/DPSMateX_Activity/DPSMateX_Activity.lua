local DPSMateX = DPSMateX

-- Global Variables
local DPSMateX = DPSMateX

DPSMateX.Modules.Activity = {}
DPSMateX.Modules.Activity.Hist = "names"
DPSMateX.Options.Options[1]["args"]["activity"] = {
	order = 510,
	type = 'toggle',
	name = DPSMateX.L["activity"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["activity"]..".",
	get = function() return DPSMateX.Settings["windows"][(DPSMateX.Options.Dewdrop:GetOpenedParent() or DPSMateX).Key or 1]["options"][1]["activity"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "activity", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}

-- Register the moodule
DPSMateX:Register("activity", DPSMateX.Modules.Activity, DPSMateX.L["activity"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local typeByName = {
	["Total"] = 1,
	["Current fight"] = 2
}
local NameById = {
	[1] = "total",
	[2] = "current"
}

local pairs = pairs

-- Object pool variables
local new_values = {}
local total_value = {}
local sorted_values = {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

function DPSMateX.Modules.Activity:GetSortedTable(arr, k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	local curmode, num = DPSMateX:GetModeName(k)
	local db
	if typeByName[curmode] then
		db = DPSMateX.CombatTime["effective"][typeByName[curmode]]
		total_value[k] = DPSMateX.CombatTime[NameById[typeByName[curmode]]]
	else
		db = DPSMateX.CombatTime["segments"][num][2]
		total_value[k] = DPSMateX.CombatTime["segments"][num][1]
	end
	for cat, val in pairs(db) do -- owner // Does not work for segments
		local name = cat
		if DPSMateX:ApplyFilter(k, name) then
			new_values[k][name] = val
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

function DPSMateX.Modules.Activity:EvalTable(user, k)
	
end

function DPSMateX.Modules.Activity:GetSettingValues(arr, cbt, k)
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""; strt[2] = ""

	local sortedTable, total = DPSMateX.Modules.Activity:GetSortedTable(arr, k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end
		str[1] = ""; str[2] = ""; str[3] = ""
		str[1] = strformat("%.2f", val).."s"; strt[2] = strformat("%.2f", total).."s"
		tinsert(tbl_name, na[2])
		tinsert(tbl_amount, str[2]..str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Activity:ShowTooltip(user,k)
	GameTooltip:Hide()
end

function DPSMateX.Modules.Activity:OpenDetails(obj, key, bool)
end

function DPSMateX.Modules.Activity:OpenTotalDetails(obj, key)
end
