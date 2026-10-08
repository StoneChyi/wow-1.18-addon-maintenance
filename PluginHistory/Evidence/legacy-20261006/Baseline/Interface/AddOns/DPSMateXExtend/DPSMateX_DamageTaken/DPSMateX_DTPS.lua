local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DTPS = {}
DPSMateX.Modules.DTPS.Hist = "DMGTaken"
DPSMateX.Options.Options[1]["args"]["dtps"] = {
	order = 35,
	type = 'toggle',
	name = DPSMateX.L["dtps"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["dtps"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["dtps"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "dtps", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.DTPS.Events = {
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
DPSMateX:Register("dtps", DPSMateX.Modules.DTPS, DPSMateX.L["dtps"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs

local new_values = {}
local total_value = {}
local sorted_values = {}

local evt_a, evt_d, total_ev = {}, {}, 0

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]="",[4]=""}

local tt_ab, tt_abn = {}, {}

function DPSMateX.Modules.DTPS:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for c, v in pairs(arr) do
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(c)) then
			local unitName = DPSMateX:GetUserById(c)
			new_values[k][unitName] = (new_values[k][unitName] or 0) + v["i"]
			total_value[k] = total_value[k] + v["i"]
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

function DPSMateX.Modules.DTPS:EvalTable(user, k, cbt)
	local arr, cbet = DPSMateX:GetMode(k)
	cbt = cbt or cbet
	total_ev = 0
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	if not arr[user[1]] then return evt_a, total_ev, evt_d end
	for cat, val in pairs(arr[user[1]]) do
		if cat~="i" then
			local CV = 0
			local catAbilities = DPSMateX.Pool.get()
			local catValues = DPSMateX.Pool.get()
			for ca, va in pairs(val) do
				if ca~="i" then
					CV = CV + va[13]
					local i = 1
					while true do
						if (not catValues[i]) then
							tinsert(catAbilities, i, ca)
							tinsert(catValues, i, va[13]/cbt)
							break
						else
							if (catValues[i] < va[13]/cbt) then
								tinsert(catAbilities, i, ca)
								tinsert(catValues, i, va[13]/cbt)
								break
							end
						end
						i = i + 1
					end
				end
			end
			local i = 1
			while true do
				if (not evt_d[i]) then
					tinsert(evt_a, i, cat)
					local t = DPSMateX.Pool.get()
					tinsert(t, CV/cbt)
					tinsert(t, catAbilities)
					tinsert(t, catValues)
					tinsert(evt_d, i, t)
					break
				else
					if (evt_d[i][1] < CV/cbt) then
						tinsert(evt_a, i, cat)
						local t = DPSMateX.Pool.get()
						tinsert(t, CV/cbt)
						tinsert(t, catAbilities)
						tinsert(t, catValues)
						tinsert(evt_d, i, t)
						break
					end
				end
				i = i + 1
			end
		end
	end
	total_ev = arr[user[1]]["i"]/(cbt or 1)
	return evt_a, total_ev, evt_d
end

function DPSMateX.Modules.DTPS:GetSettingValues(arr, cbt, k,ecbt)
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
		if totr <= 10000 then pt = "" end; if dmgr<=10000 then p = "" end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		str[4] = ""
		local pname = na[2]
		if DPSMateX.Settings["columnsdtps"][2] then str[1] = " "..strformat("%.1f", dmg/cbt)..p; strt[2] = " "..strformat("%.1f", (tot/cbt))..pt end 
		if DPSMateX.Settings["columnsdtps"][3] then str[2] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		if DPSMateX.Settings["columnsdtps"][1] then str[3] = "("..DPSMateX:Commas(dmg, k)..p..")"; strt[1] = "("..DPSMateX:Commas(tot, k)..pt..")" end
		if DPSMateX.Settings["columnsdtps"][4] then str[4] = " ("..strformat("%.1f", dmg/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname) 
		tinsert(tbl_amount, str[3]..str[1]..str[4]..str[2])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.DTPS:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.DTPS:EvalTable(DPSMateX.CacheUser[user], k)
		DPSMateX:WipeInPool(tt_ab)
		DPSMateX:WipeInPool(tt_abn)

		local i = 1
		while a[i] do
			local p = 1
			while c[i][2][p] do
				if tt_ab[c[i][2][p]] then
					tt_ab[c[i][2][p]] = tt_ab[c[i][2][p]] + c[i][3][p]
				else
					tt_ab[c[i][2][p]] = c[i][3][p]
				end
				p = p + 1
			end
			i = i + 1
		end
		
		for cat, val in pairs(tt_ab) do
			if val>0 then
				local j = 1
				while true do
					if (not tt_abn[j]) then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(tt_abn, j, t)
						break
					else
						if (tt_abn[j][2] < val) then
							local t = DPSMateX.Pool.get()
							tinsert(t, cat)
							tinsert(t, val)
							tinsert(tt_abn, j, t)
							break
						end
					end
					j = j + 1
				end
			end
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdamage"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(tt_abn[i][1]), strformat("%.2f", tt_abn[i][2]).." ("..strformat("%.2f", 100*tt_abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttattacked"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),strformat("%.2f", c[i][1]).." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.DTPS:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsDamageTaken:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsDamageTaken:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.DTPS:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsDamageTakenTotal:UpdateDetails(obj, key)
end
