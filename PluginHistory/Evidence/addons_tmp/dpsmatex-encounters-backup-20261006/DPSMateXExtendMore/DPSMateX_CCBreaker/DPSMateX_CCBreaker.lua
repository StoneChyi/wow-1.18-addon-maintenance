local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.CCBreaker = {}
DPSMateX.Modules.CCBreaker.Hist = "CCBreaker"
DPSMateX.Options.Options[1]["args"]["ccbreaker"] = {
	order = 310,
	type = 'toggle',
	name = DPSMateX.L["ccbreaker"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["ccbreaker"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["ccbreaker"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "ccbreaker", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.CCBreaker.Events = {
	-- Damage
	"CHAT_MSG_COMBAT_SELF_HITS",
	"CHAT_MSG_COMBAT_SELF_MISSES",
	"CHAT_MSG_SPELL_SELF_DAMAGE",
	"CHAT_MSG_COMBAT_PARTY_HITS",
	"CHAT_MSG_SPELL_PARTY_DAMAGE",
	"CHAT_MSG_COMBAT_PARTY_MISSES",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_HITS",
	"CHAT_MSG_COMBAT_FRIENDLYPLAYER_MISSES",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
	-- Pet Damage
	"CHAT_MSG_COMBAT_PET_HITS",
	"CHAT_MSG_COMBAT_PET_MISSES",
	--"CHAT_MSG_SPELL_PET_BUFF",
	"CHAT_MSG_SPELL_PET_DAMAGE",
	
	-- EDD (Enemy player) / DeathHistory
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
DPSMateX:Register("ccbreaker", DPSMateX.Modules.CCBreaker, DPSMateX.L["ccbreaker"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
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

function DPSMateX.Modules.CCBreaker:GetSortedTable(arr, k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for cat, val in arr do
		local name = DPSMateX:GetUserById(cat)
		local amount = DPSMateX:TableLength(val)
		if DPSMateX:ApplyFilter(k, name) then
			new_values[k][name] = amount
			total_value[k] = total_value[k] + amount
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

function DPSMateX.Modules.CCBreaker:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	DPSMateX:WipeInPool(eval_temp)
	local total = 0
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	for _, v in arr[user[1]] do
		if eval_temp[v[1]] then eval_temp[v[1]] = eval_temp[v[1]] + 1 else eval_temp[v[1]] = 1 end
		total=total+1
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
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.CCBreaker:GetSettingValues(arr, cbt, k)
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""; strt[2] = ""
	local p = ""
	local pt = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.CCBreaker:GetSortedTable(arr, k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end; if totr <= 10000 then pt = "" end
		str[1] = ""; str[2] = ""; str[3] = ""
		if DPSMateX.Settings["columnsccbreaker"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsccbreaker"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, na[2])
		tinsert(tbl_amount, str[2]..str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.CCBreaker:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = self:EvalTable(DPSMateX.CacheUser[user], k)
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i].." ("..strformat("%.2f", 100*c[i]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.CCBreaker:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsCCBreaker:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsCCBreaker:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.CCBreaker:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsCCBreakerTotal:UpdateDetails(obj, key)
end
