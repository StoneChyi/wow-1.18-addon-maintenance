local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.Fails = {}
DPSMateX.Modules.Fails.Hist = "Fails"
DPSMateX.Options.Options[1]["args"]["fails"] = {
	order = 300,
	type = 'toggle',
	name = DPSMateX.L["fails"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["fails"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["fails"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "fails", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Fails.Events = {
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
	
	-- Healing/Absorbs/Fail/DeathHistory/Dispels
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PARTY_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",

	-- Absorbs/Auras
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS",
	"CHAT_MSG_SPELL_BREAK_AURA",
	"CHAT_MSG_SPELL_AURA_GONE_SELF",
	"CHAT_MSG_SPELL_AURA_GONE_OTHER",
	"CHAT_MSG_SPELL_AURA_GONE_PARTY",
}

-- Register the moodule
DPSMateX:Register("fails", DPSMateX.Modules.Fails, DPSMateX.L["fails"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local ipairs = ipairs
local pairs = pairs

local new_values = {}
local total_value = {}
local sorted_values = {}

local eval_temp = {}
local evt_a, evt_d, total_ev = {}, {}, 0

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

function DPSMateX.Modules.Fails:GetSortedTable(arr, k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for cat, val in arr do
		local name = DPSMateX:GetUserById(cat)
		local amount = DPSMateX:TableLength(val)
		new_values[k][name] = amount
		total_value[k] = total_value[k] + amount
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

function DPSMateX.Modules.Fails:EvalTable(user, k)
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	total_ev = 0
	eval_temp = DPSMateX:WipeInPool(eval_temp)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	for _, v in arr[user[1]] do
		eval_temp[v[1]] = (eval_temp[v[1]] or 0) + 1
		total_ev = total_ev + 1
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
	end
	return evt_a, total_ev, evt_d
end

function DPSMateX.Modules.Fails:GetSettingValues(arr, cbt, k,ecbt)
	strt[1] = ""
	strt[2] = ""

	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)

	local sortedTable, total = self:GetSortedTable(arr, k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		local pname = na[2]
		if DPSMateX.Settings["columnsfails"][1] then str[1] = " "..DPSMateX:Commas(dmg, k); strt[2] = DPSMateX:Commas(tot, k) end
		if DPSMateX.Settings["columnsfails"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[2]..str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Fails:Type(id)
	if id == 1 then
		return DPSMateX.L["friendlyfire"]
	elseif id == 2 then
		return DPSMateX.L["damagetaken"]
	end
	return DPSMateX.L["debufftaken"]
end

function DPSMateX.Modules.Fails:ShowTooltip(user,k)
	local a,b,c = self:EvalTable(DPSMateX.CacheUser[user], k)
	if DPSMateX.Settings["informativetooltips"] then
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..self:Type(a[i]),c[i].." ("..strformat("%.2f", 100*c[i]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.Fails:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsFails:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsFails:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Fails:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsFailsTotal:UpdateDetails(obj, key)
end
