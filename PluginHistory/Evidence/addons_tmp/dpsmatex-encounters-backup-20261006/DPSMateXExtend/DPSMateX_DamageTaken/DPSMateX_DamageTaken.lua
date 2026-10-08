local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DamageTaken = {}
DPSMateX.Modules.DamageTaken.Hist = "DMGTaken"
DPSMateX.Options.Options[1]["args"]["damagetaken"] = {
	order = 30,
	type = 'toggle',
	name = DPSMateX.L["damagetaken"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["damagetaken"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["damagetaken"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "damagetaken", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.DamageTaken.Events = {
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
DPSMateX:Register("damagetaken", DPSMateX.Modules.DamageTaken, DPSMateX.L["damagetaken"])

local tinsert = table.insert
local strformat = string.format
local pairs = pairs

-- Pool 复用变量
local sorted_values = {}
local total_value = {}
local evt_a, evt_d = {}, {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]="",[4]=""}
local ab, abn = {},{}

function DPSMateX.Modules.DamageTaken:GetSortedTable(arr,k)
	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	total_value[k] = 0
	for c, v in pairs(arr) do
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(c)) then
			local i = 1
			while true do
				if (not sorted_values[k][i]) then
					local t = DPSMateX.Pool.get()
					tinsert(t, v["i"])
					tinsert(t, c)
					tinsert(sorted_values[k], i, t)
					break
				else
					if sorted_values[k][i][1] < v["i"] then
						local t = DPSMateX.Pool.get()
						tinsert(t, v["i"])
						tinsert(t, c)
						tinsert(sorted_values[k], i, t)
						break
					end
				end
				i=i+1
			end
			total_value[k] = total_value[k] + v["i"]
		end
	end
	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.DamageTaken:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	for cat, val in pairs(arr[user[1]]) do
		if cat~="i" then
			local ta, tb, CV = DPSMateX.Pool.get(), DPSMateX.Pool.get(), 0
			for ca, va in pairs(val) do
				if ca~="i" then
					CV = CV + va[13]
					local i = 1
					while true do
						if (not tb[i]) then
							tinsert(ta, i, ca)
							tinsert(tb, i, va[13])
							break
						else
							if (tb[i] < va[13]) then
								tinsert(ta, i, ca)
								tinsert(tb, i, va[13])
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
					tinsert(t, CV)
					tinsert(t, ta)
					tinsert(t, tb)
					tinsert(evt_d, i, t)
					break
				else
					if (evt_d[i][1] < CV) then
						tinsert(evt_a, i, cat)
						local t = DPSMateX.Pool.get()
						tinsert(t, CV)
						tinsert(t, ta)
						tinsert(t, tb)
						tinsert(evt_d, i, t)
						break
					end
				end
				i = i + 1
			end
		end
	end
	return evt_a, arr[user[1]]["i"], evt_d
end

function DPSMateX.Modules.DamageTaken:GetSettingValues(arr, cbt, k,ecbt)
	local p, pt = "", ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""
	strt[2] = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.DamageTaken:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if totr <= 10000 then pt = "" end; if dmgr<=10000 then p = "" end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		str[4] = ""
		local pname = DPSMateX:GetUserById(na[2])
		if DPSMateX.Settings["columnsdmgtaken"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsdmgtaken"][2] then str[3] = "("..strformat("%.1f", dmg/cbt)..")"; strt[1] = "("..strformat("%.1f", (tot/cbt))..pt..")" end
		if DPSMateX.Settings["columnsdmgtaken"][3] then str[2] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		if DPSMateX.Settings["columnsdmgtaken"][4] then str[4] = " ("..strformat("%.1f", dmg/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[3]..str[1]..str[4]..str[2])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.DamageTaken:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.DamageTaken:EvalTable(DPSMateX.CacheUser[user], k)
		local p, i = 1, 1
		DPSMateX:WipeInPool(ab)
		DPSMateX:WipeInPool(abn)
		
		while a[i] do
			p = 1
			while c[i][2][p] do
				local cat, val = c[i][2][p], c[i][3][p]
				if ab[cat] then
					ab[cat] = ab[cat] + val
				else
					ab[cat] = val
				end
				p = p + 1
			end
			i = i + 1
		end
		
		for cat, val in pairs(ab) do
			if val>0 then
				i = 1
				while true do
					if (not abn[i]) then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(abn, i, t)
						break
					else
						if (abn[i][2] < val) then
							local t = DPSMateX.Pool.get()
							tinsert(t, cat)
							tinsert(t, val)
							tinsert(abn, i, t)
							break
						end
					end
					i = i + 1
				end
			end
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdamage"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..(DPSMateX:GetAbilityById(abn[i][1]) or "Unknown"), abn[i][2].." ("..strformat("%.1f", 100*abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttattacked"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.1f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.DamageTaken:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsDamageTaken:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsDamageTaken:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.DamageTaken:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsDamageTakenTotal:UpdateDetails(obj, key)
end
