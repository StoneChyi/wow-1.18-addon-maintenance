-- Global Variables
local DPSMateX = DPSMateX

DPSMateX.Modules.SunderArmor = {}
DPSMateX.Modules.SunderArmor.Hist = "EDTaken"
DPSMateX.Options.Options[1]["args"]["sunderarmor"] = {
	order = 270,
	type = 'toggle',
	name = DPSMateX.L["sunderarmor"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["sunderarmor"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["sunderarmor"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "sunderarmor", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.SunderArmor.Events = {
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
DPSMateX:Register("sunderarmor", DPSMateX.Modules.SunderArmor, DPSMateX.L["sunderarmor"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs

local SpellIdList
local function BuildAbilityList()
	if SpellIdList then return end
	SpellIdList = {}
	for k,v in DPSMateX.DB.trackedSpells do
		SpellIdList[v] = true
	end
end

local new_values = {}
local total_value = {}
local sorted_values = {}
local gst_temp = {}

local eval_temp = {}
local evt_a, evt_d, total_ev = {}, {}, 0

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

function DPSMateX.Modules.SunderArmor:GetSortedTable(arr, k)
	BuildAbilityList()

	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0
	gst_temp = DPSMateX:WipeInPool(gst_temp)

	for cat, val in arr do
		for c, v in val do
			local CV = 0
			for ca, va in v do
				if ca~="i" then
					if SpellIdList[DPSMateX:GetAbilityById(ca)] then
						CV = CV + va[1] + va[5] + va[9] + va[10] + va[11] + va[12] + va[14] + va[18]
					end
				end
			end
			gst_temp[c] = (gst_temp[c] or 0) + CV
		end
	end
	for userId, amount in pairs(gst_temp) do
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(userId)) and amount > 0 then
			local userName = DPSMateX:GetUserById(userId)
			new_values[k][userName] = (new_values[k][userName] or 0) + amount
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
	tsort(sorted_values[k], function(a,b) return a[1] > b[1] end)

	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.SunderArmor:EvalTable(user, k)
	BuildAbilityList()

	local arr = DPSMateX:GetMode(k)
	total_ev = 0
	eval_temp = DPSMateX:WipeInPool(eval_temp)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	for c, v in arr do
		if v[user[1]] then
			for ca, va in v[user[1]] do
				if ca~="i" and SpellIdList[DPSMateX:GetAbilityById(ca)] then
					local CV = va[1] + va[5] + va[9] + va[10] + va[11] + va[12] + va[14] + va[18]
					eval_temp[ca] = (eval_temp[ca] or 0) + CV
				end
			end
		end
	end

	for cat, val in pairs(eval_temp) do
		local i = 1
		while true do
			if (not evt_d[i]) then
				tinsert(evt_a, i, cat)
				tinsert(evt_d, i, val)
				break
			else
				if evt_d[i] < val then
					tinsert(evt_a, i, cat)
					tinsert(evt_d, i, val)
					break
				end
			end
			i=i+1
		end
		total_ev = total_ev + val
	end
	return evt_a, total_ev, evt_d
end

function DPSMateX.Modules.SunderArmor:GetSettingValues(arr, cbt, k,ecbt)
	local p, pt = "", ""
	strt[1] = ""
	strt[2] = ""

	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)

	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = self:GetSortedTable(arr, k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end; if totr <= 10000 then pt = "" end; if dmgr<=10000 then p = "" end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		local pname = na[2]
		if DPSMateX.Settings["columnssunderarmor"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnssunderarmor"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[2]..str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.SunderArmor:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local c,b,a = DPSMateX.Modules.SunderArmor:EvalTable(DPSMateX.CacheUser[user], k)
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not c[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(c[i]),a[i].." ("..strformat("%.2f", 100*a[i]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.SunderArmor:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsSunderArmor:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsSunderArmor:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.SunderArmor:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsSunderArmorTotal:UpdateDetails(obj, key)
end
