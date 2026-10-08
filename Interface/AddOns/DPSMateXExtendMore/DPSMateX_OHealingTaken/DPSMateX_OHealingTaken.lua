local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.OHealingTaken = {}
DPSMateX.Modules.OHealingTaken.Hist = "OHealingTaken"
DPSMateX.Options.Options[1]["args"]["OHealingTaken"] = {
	order = 81,
	type = 'toggle',
	name = DPSMateX.L["OHealingTaken"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["OHealingTaken"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["OHealingTaken"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "OHealingTaken", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.OHealingTaken.Events = {
	-- Healing/Absorbs/Fail/DeathHistory/Dispels
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PARTY_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
}

-- Register the moodule
DPSMateX:Register("OHealingTaken", DPSMateX.Modules.OHealingTaken, DPSMateX.L["OHealingTaken"])

local tinsert = table.insert
local strformat = string.format
local pairs = pairs

-- Pool 复用变量
local sorted_values = {}
local total_value = {}
local evt_a, evt_d = {}, {}, {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]="",[4]=""}
local tt_ab, tt_abn = {}, {}

function DPSMateX.Modules.OHealingTaken:GetSortedTable(arr,k)
	local CV = 0
	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	total_value[k] = 0

	for c, v in pairs(arr) do
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(c)) then
			CV = v["i"] or 0
			local i = 1
			while true do
				if (not sorted_values[k][i]) then
					local t = DPSMateX.Pool.get()
					tinsert(t, CV)
					tinsert(t, c)
					tinsert(sorted_values[k], i, t)
					break
				else
					if sorted_values[k][i][1] < CV then
						local t = DPSMateX.Pool.get()
						tinsert(t, CV)
						tinsert(t, c)
						tinsert(sorted_values[k], i, t)
						break
					end
				end
				i=i+1
			end
			total_value[k] = total_value[k] + CV
		end
	end
	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.OHealingTaken:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	local total = 0
	local arr = DPSMateX:GetMode(k)
	if arr[user[1]] then
		for cat, val in pairs(arr[user[1]]) do
			if cat~="i" then
				local CV = 0
				local evt_ta = DPSMateX.Pool.get()
				local evt_tb = DPSMateX.Pool.get()
				for ca, va in pairs(val) do
					CV=CV+va[1]
					local i = 1
					while true do
						if (not evt_tb[i]) then
							tinsert(evt_ta, i, ca)
							tinsert(evt_tb, i, va[1])
							break
						else
							if (evt_tb[i] < va[1]) then
								tinsert(evt_ta, i, ca)
								tinsert(evt_tb, i, va[1])
								break
							end
						end
						i = i + 1
					end
				end
				local i = 1
				while true do
					if (not evt_d[i]) then
						tinsert(evt_a, i, cat)
						local t = DPSMateX.Pool.get()
						tinsert(t, CV)
						tinsert(t, evt_ta)
						tinsert(t, evt_tb)
						tinsert(evt_d, i, t)
						break
					else
						if (evt_d[i][1] < CV) then
							tinsert(evt_a, i, cat)
							local t = DPSMateX.Pool.get()
							tinsert(t, CV)
							tinsert(t, evt_ta)
							tinsert(t, evt_tb)
							tinsert(evt_d, i, t)
							break
						end
					end
					i = i + 1
				end
			end
			total=total+arr[user[1]]["i"]
		end
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.OHealingTaken:GetSettingValues(arr, cbt, k,ecbt)
	local p, pt = "", ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""
	strt[2] = ""

	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = self:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local pname = DPSMateX:GetUserById(na[2])
		local va, tot, sort, varea, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if varea==0 then break end; if totr <= 10000 then pt = "" end; if varea<=10000 then p = "" end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		str[4] = ""
		if DPSMateX.Settings["columnsohealingtaken"][1] then str[1] = " "..DPSMateX:Commas(va, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsohealingtaken"][3] then str[2] = " ("..strformat("%.1f", 100*varea/totr).."%)" end
		if DPSMateX.Settings["columnsohealingtaken"][2] then str[3] = " ("..strformat("%.1f", va/cbt)..")"; strt[1] = " ("..strformat("%.1f", (tot/cbt))..pt..")" end
		if DPSMateX.Settings["columnsohealingtaken"][4] then str[4] = " ("..strformat("%.1f", va/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[3]..str[1]..str[4]..str[2])
		tinsert(tlb_percent, 100*(varea/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.OHealingTaken:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.OHealingTaken:EvalTable(DPSMateX.CacheUser[user], k)
		local totalVal = 0
		local p, i = 1, 1
		DPSMateX:WipeInPool(tt_ab)
		DPSMateX:WipeInPool(tt_abn)
		
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
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(tt_abn, i, t)
						break
					else
						if (tt_abn[i][2] < val) then
							local t = DPSMateX.Pool.get()
							tinsert(t, cat)
							tinsert(t, val)
							tinsert(tt_abn, i, t)
							break
						end
					end
					i = i + 1
				end
				totalVal = totalVal + val
			end
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["tthealing"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(tt_abn[i][1]), tt_abn[i][2].." ("..strformat("%.2f", 100*tt_abn[i][2]/totalVal).."%)", 1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["tthealed"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/totalVal).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.OHealingTaken:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsOHealingTaken:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsOHealingTaken:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.OHealingTaken:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsOverhealingTakenTotal:UpdateDetails(obj, key)
end

