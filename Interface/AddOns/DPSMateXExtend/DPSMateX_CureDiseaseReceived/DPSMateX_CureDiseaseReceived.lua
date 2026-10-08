local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.CureDiseaseReceived = {}
DPSMateX.Modules.CureDiseaseReceived.Hist = "Dispels"
DPSMateX.Options.Options[1]["args"]["diseasecurereceived"] = {
	order = 205,
	type = 'toggle',
	name = DPSMateX.L["curediseasereceived"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["curediseasereceived"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["diseasecurereceived"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "diseasecurereceived", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}

-- Register the moodule
DPSMateX:Register("diseasecurereceived", DPSMateX.Modules.CureDiseaseReceived, DPSMateX.L["curediseasereceived"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs

local new_values = {}
local total_value = {}
local sorted_values = {}
local gst_temp = {}

local evt_a, evt_d, total_ev = {}, {}, 0

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}
local tt_ab, tt_abn = {}, {}

function DPSMateX.Modules.CureDiseaseReceived:IsValid(ab, cast)
	if DPSMateX.CacheAbility[ab][2]==DPSMateX.L["disease"] or (DPSMateX.Parser.DeDisease[cast] and not DPSMateX.CacheAbility[ab][2]) or (DPSMateX.Parser.DeDisease[cast] and DPSMateX.CacheAbility[ab][2] and DPSMateX.CacheAbility[ab][2]==DPSMateX.L["disease"]) then
		return true
	end
	return false
end

function DPSMateX.Modules.CureDiseaseReceived:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0
	gst_temp = DPSMateX:WipeInPool(gst_temp)

	for cat, val in pairs(arr) do -- 3 Owner
		for ca, va in pairs(val) do -- 42 Ability
			if ca~="i" then
				for c, v in pairs(va) do -- 3 Target
					if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(c)) then
						for ce, ve in pairs(v) do -- 10 Cured Ability
							if self:IsValid(DPSMateX:GetAbilityById(ce), DPSMateX:GetAbilityById(ca)) then
								gst_temp[c] = (gst_temp[c] or 0) + ve
							end
						end
					end
				end
			end
		end
	end

	for userId, amount in pairs(gst_temp) do
		local userName = DPSMateX:GetUserById(userId)
		new_values[k][userName] = (new_values[k][userName] or 0) + amount
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

function DPSMateX.Modules.CureDiseaseReceived:EvalTable(user, k)
	local arr = DPSMateX:GetMode(k)
	total_ev = 0
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	for cat, val in pairs(arr) do -- 3 Owner
		local catTotal = 0
		local catAbilities = DPSMateX.Pool.get()
		local catValues = DPSMateX.Pool.get()
		for ca, va in pairs(val) do -- 42 Ability
			if ca~="i" then
				for c, v in pairs(va) do -- 3 Target
					if c==user[1] then
						for ce, ve in pairs(v) do -- 10 Cured Ability
							if self:IsValid(DPSMateX:GetAbilityById(ce), DPSMateX:GetAbilityById(ca)) then
								catTotal = catTotal + ve
								local i = 1
								while true do
									if (not catValues[i]) then
										tinsert(catValues, i, ve)
										tinsert(catAbilities, i, ce)
										break
									else
										if catValues[i] < ve then
											tinsert(catValues, i, ve)
											tinsert(catAbilities, i, ce)
											break
										end
									end
									i=i+1
								end
							end
						end
						break
					end
				end
			end
		end
		if catTotal > 0 then
			local i = 1
			while true do
				if (not evt_d[i]) then
					tinsert(evt_a, i, cat)
					local t = DPSMateX.Pool.get()
					tinsert(t, catTotal)
					tinsert(t, catAbilities)
					tinsert(t, catValues)
					tinsert(evt_d, i, t)
					break
				else
					if evt_d[i][1] < catTotal then
						tinsert(evt_a, i, cat)
						local t = DPSMateX.Pool.get()
						tinsert(t, catTotal)
						tinsert(t, catAbilities)
						tinsert(t, catValues)
						tinsert(evt_d, i, t)
						break
					end
				end
				i=i+1
			end
			total_ev = total_ev + catTotal
		end
	end
	return evt_a, total_ev, evt_d
end

function DPSMateX.Modules.CureDiseaseReceived:GetSettingValues(arr, cbt, k,ecbt)
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
		if DPSMateX.Settings["columnsdiseasereceived"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsdiseasereceived"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.CureDiseaseReceived:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.CureDiseaseReceived:EvalTable(DPSMateX.CacheUser[user], k)
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
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(tt_abn[i][1]), tt_abn[i][2].." ("..strformat("%.2f", 100*tt_abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.CureDiseaseReceived:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsCureDiseaseReceived:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsCureDiseaseReceived:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.CureDiseaseReceived:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsCureDiseaseTotal:UpdateDetails(obj, key)
end
