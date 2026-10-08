local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.Deaths = {}
DPSMateX.Modules.Deaths.Hist = "Deaths"
DPSMateX.Options.Options[1]["args"]["deaths"] = {
	order = 160,
	type = 'toggle',
	name = DPSMateX.L["deaths"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["deaths"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["deaths"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "deaths", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Deaths.Events = {
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
	
	-- Death/DeathHistory
	"CHAT_MSG_COMBAT_FRIENDLY_DEATH",
	"CHAT_MSG_COMBAT_HOSTILE_DEATH",
}

-- Register the moodule
DPSMateX:Register("deaths", DPSMateX.Modules.Deaths, DPSMateX.L["deaths"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs

local new_values = {}
local total_value = {}
local sorted_values = {}

local evt_a, evt_d = {}, {}

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

function DPSMateX.Modules.Deaths:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	if arr then
		for cat, val in pairs(arr) do -- 28
			if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(cat)) then
				local CV = 0
				for ca, va in pairs(val) do -- 1 (Death)
					if va["i"][1]==1 then
						CV=CV+1
					end
				end
				local userName = DPSMateX:GetUserById(cat)
				new_values[k][userName] = CV
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
	tsort(sorted_values[k], function(a,b) return a[1] > b[1] end)

	return sorted_values[k], total_value[k]
end

-- Needs improvement, but kinda all tooltips need that
function DPSMateX.Modules.Deaths:EvalTable(user, k, id)
	local arr = DPSMateX:GetMode(k)
	local p = 1
	if not arr[user[1]] then return end
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	if arr[user[1]][1] then 
		if arr[user[1]][1]["i"][1]~=1 then p=2 else p=1 end 
		if arr[user[1]][id or p] then 
			for ca, va in pairs(arr[user[1]][id or p]) do -- 1 (Death)
				if ca~="i" then
					local detailT = DPSMateX.Pool.get()
					tinsert(detailT, va[3])
					tinsert(detailT, va[5])
					tinsert(detailT, va[4])
					tinsert(evt_d, ca, detailT)
					tinsert(evt_a, ca, va[2])
				end
			end
		end
	end
	return evt_a, 0, evt_d
end

function DPSMateX.Modules.Deaths:GetSettingValues(arr, cbt, k,ecbt)
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
		if DPSMateX.Settings["columnsdeaths"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsdeaths"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Deaths:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.Deaths:EvalTable(DPSMateX.CacheUser[user], k)
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			local ctype = " (HIT)"
			if c[i][3]==1 then ctype=" (CRIT)" elseif c[i][3]==2 then ctype=" (CRUSH)" end
			if c[i][2]==1 then
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),"+"..c[i][1]..ctype,0.67,0.83,0.45,0.67,0.83,0.45)
			else
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),"-"..c[i][1]..ctype,0.77,0.12,0.23,0.77,0.12,0.23)
			end
		end
	end
end

function DPSMateX.Modules.Deaths:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsDeaths:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsDeaths:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Deaths:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsDeathsTotal:UpdateDetails(obj, key)
end
