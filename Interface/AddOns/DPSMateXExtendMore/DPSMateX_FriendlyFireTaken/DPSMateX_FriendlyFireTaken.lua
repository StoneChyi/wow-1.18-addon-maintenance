local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.FriendlyFireTaken = {}
DPSMateX.Modules.FriendlyFireTaken.Hist = "EDTaken"
DPSMateX.Options.Options[1]["args"]["friendlyfiretaken"] = {
	order = 261,
	type = 'toggle',
	name = DPSMateX.L["friendlyfiretaken"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["friendlyfiretaken"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["friendlyfiretaken"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "friendlyfiretaken", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}

-- Register the moodule
DPSMateX:Register("friendlyfiretaken", DPSMateX.Modules.FriendlyFireTaken, DPSMateX.L["friendlyfiretaken"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs

-- Object pool variables
local new_values = {}
local total_value = {}
local sorted_values = {}
local evt_a, evt_d = {}, {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]="",[4]=""}
local tt_ab, tt_abn = {}, {}

function DPSMateX.Modules.FriendlyFireTaken:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for c, v in pairs(arr) do
		local cName = DPSMateX:GetUserById(c)
		if DPSMateX:ApplyFilter(k, cName) then
			local CV = 0
			for cat, val in pairs(v) do
				local catName = DPSMateX:GetUserById(cat)
				if DPSMateX.CacheUser[catName] and DPSMateX.CacheUser[cName] then
					if DPSMateX.CacheUser[cName][3] == DPSMateX.CacheUser[catName][3] and DPSMateX.CacheUser[catName][3] then
						CV = CV + val["i"]
					end
				end
			end
			if CV > 0 then
				new_values[k][cName] = CV
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

function DPSMateX.Modules.FriendlyFireTaken:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	local total = 0
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	for c, v in arr[user[1]] do
		local cName = DPSMateX:GetUserById(c)
		local CV = 0
		local aa = DPSMateX.Pool.get()
		local bb = DPSMateX.Pool.get()
		if DPSMateX.CacheUser[cName][3] == user[3] and DPSMateX.CacheUser[cName][3] then
			for cat, val in v do
				if cat~="i" then
					local i = 1
					while true do
						if (not bb[i]) then
							tinsert(bb, i, val[13])
							tinsert(aa, i, cat)
							break
						else
							if bb[i] < val[13] then
								tinsert(bb, i, val[13])
								tinsert(aa, i, cat)
								break
							end
						end
						i=i+1
					end
					CV = CV + val[13]
				end
			end
		end
		if CV > 0 then
			local i = 1
			while true do
				if (not evt_d[i]) then
					tinsert(evt_d, i, {CV, aa, bb})
					tinsert(evt_a, i, c)
					break
				else
					if evt_d[i][1] < CV then
						tinsert(evt_d, i, {CV, aa, bb})
						tinsert(evt_a, i, c)
						break
					end
				end
				i=i+1
			end
			total = total + CV
		end
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.FriendlyFireTaken:GetSettingValues(arr, cbt, k,ecbt)
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""; strt[2] = ""
	local p = ""
	local pt = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.FriendlyFireTaken:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end; if totr <= 10000 then pt = "" end; if dmgr<=10000 then p = "" end
		str[1] = ""; str[2] = ""; str[3] = ""; str[4] = ""
		local pname = na[2]
		if DPSMateX.Settings["columnsfriendlyfiretaken"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsfriendlyfiretaken"][3] then str[2] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		if DPSMateX.Settings["columnsfriendlyfiretaken"][2] then str[3] = "("..strformat("%.1f", dmg/cbt)..")"; strt[1] = "("..strformat("%.1f", (tot/cbt))..pt..")" end
		if DPSMateX.Settings["columnsfriendlyfiretaken"][4] then str[4] = " ("..strformat("%.1f", dmg/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[3]..str[1]..str[4]..str[2])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.FriendlyFireTaken:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.FriendlyFireTaken:EvalTable(DPSMateX.CacheUser[user], k)
		DPSMateX:WipeInPool(tt_ab)
		DPSMateX:WipeInPool(tt_abn)
		local p, i = 1, 1

		while a[i] do
			p = 1
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
				i = 1
				while true do
					if (not tt_abn[i]) then
						tinsert(tt_abn, i, {cat, val})
						break
					else
						if (tt_abn[i][2] < val) then
							tinsert(tt_abn, i, {cat, val})
							break
						end
					end
					i = i + 1
				end
			end
		end

		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdamage"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(tt_abn[i][1]), tt_abn[i][2].." ("..strformat("%.2f", 100*tt_abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end

		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttattacked"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.FriendlyFireTaken:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsFFT:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsFFT:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.FriendlyFireTaken:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsFFTTotal:UpdateDetails(obj, key)
end

