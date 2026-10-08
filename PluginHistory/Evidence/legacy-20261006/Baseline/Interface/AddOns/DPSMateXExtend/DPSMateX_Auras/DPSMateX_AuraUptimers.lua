local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.AurasUptimers = {}
DPSMateX.Modules.AurasUptimers.Hist = "Auras"
DPSMateX.Options.Options[1]["args"]["aurasuptime"] = {
	order = 250,
	type = 'toggle',
	name = DPSMateX.L["aurauptime"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["aurauptime"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["aurasuptime"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "aurasuptime", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.AurasUptimers.Events = {
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
DPSMateX:Register("aurasuptime", DPSMateX.Modules.AurasUptimers, DPSMateX.L["aurauptime"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs

local new_values = {}
local total_value = {}
local sorted_values = {}

local evt_a, evt_b, evt_c, total_ev = {}, {}, {}, 0

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

function DPSMateX.Modules.AurasUptimers:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for cat, val in pairs(arr) do -- 2 Target
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(cat)) then
			local CV = 0
			for ca, va in pairs(val) do -- 3 Ability
				for c, v in pairs(va) do -- each one
					if c==1 then
						for ce, ve in pairs(v) do
							CV=CV+1
						end
					end
				end
			end
			local userName = DPSMateX:GetUserById(cat)
			new_values[k][userName] = CV
			total_value[k] = total_value[k] + CV
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

function DPSMateX.Modules.AurasUptimers:EvalTable(user, k)
	local arr, cbt = DPSMateX:GetMode(k)
	if cbt>1 then
		cbt = cbt - 1;
	end
	total_ev = 0
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_b)
	DPSMateX:WipeInPool(evt_c)

	for cat, val in pairs(arr[user[1]]) do -- 3 Ability
		local CV, CVV = 0, 0
		for ca, va in pairs(val[1]) do -- each one
			if arr[user[1]][cat][2][ca] then
				CV=CV+(arr[user[1]][cat][2][ca]-va)
			end
			CVV=CVV+1
		end
		local i = 1
		CV = tonumber(strformat("%.2f", (100*CV)/cbt))
		while true do
			if (not evt_b[i]) then
				tinsert(evt_c, i, CVV)
				tinsert(evt_b, i, CV)
				tinsert(evt_a, i, cat)
				break
			else
				if evt_b[i] < CV then
					tinsert(evt_c, i, CVV)
					tinsert(evt_b, i, CV)
					tinsert(evt_a, i, cat)
					break
				end
			end
			i=i+1
		end
	end
	return evt_a, total_ev, evt_b, evt_c
end

function DPSMateX.Modules.AurasUptimers:GetSettingValues(arr, cbt, k,ecbt)
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
		if DPSMateX.Settings["columnsaurauptime"][1] then str[1] = " "..(DPSMateX:Commas(dmg, k) or dmg); strt[2] = DPSMateX:Commas(tot, k) or totr end
		if DPSMateX.Settings["columnsaurauptime"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.AurasUptimers:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.AurasUptimers:EvalTable(DPSMateX.CacheUser[user], k)
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i].."%",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.AurasUptimers:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.Auras:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.Auras:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.AurasUptimers:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsAurasTotal:UpdateDetails(obj, key)
end
