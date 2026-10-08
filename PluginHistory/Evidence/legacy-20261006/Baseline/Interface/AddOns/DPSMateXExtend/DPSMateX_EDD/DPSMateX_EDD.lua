local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.EDD = {}
DPSMateX.Modules.EDD.Hist = "EDDone"
DPSMateX.Options.Options[1]["args"]["enemydamagedone"] = {
	order = 40,
	type = 'toggle',
	name = DPSMateX.L["enemydamagedone"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["enemydamagedone"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["enemydamagedone"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "enemydamagedone", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.EDD.Events = {
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
DPSMateX:Register("enemydamagedone", DPSMateX.Modules.EDD, DPSMateX.L["enemydamagedone"])

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

function DPSMateX.Modules.EDD:GetSortedTable(arr,k)
	local CV, i
	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	total_value[k] = 0
	for c, v in pairs(arr) do
		CV = 0
		for cat, val in pairs(v) do
			if cat~="i" then
				CV = CV+val["i"]
			end
		end
		i = 1
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
	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.EDD:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	local total = 0
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	for cat, val in pairs(arr[user[1]]) do
		local ta, td = DPSMateX.Pool.get(),DPSMateX.Pool.get()
		for ca, va in pairs(val) do
			if ca~="i" then
				local i = 1
				while true do
					if (not td[i]) then
						tinsert(ta, i, ca)
						tinsert(td, i, va[13])
						break
					else
						if (td[i] < va[13]) then
							tinsert(ta, i, ca)
							tinsert(td, i, va[13])
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
				tinsert(t, val["i"])
				tinsert(t, ta)
				tinsert(t, td)
				tinsert(evt_d, i, t)
				break
			else
				if (evt_d[i][1] < val["i"]) then
					tinsert(evt_a, i, cat)
					local t = DPSMateX.Pool.get()
					tinsert(t, val["i"])
					tinsert(t, ta)
					tinsert(t, td)
					tinsert(evt_d, i, t)
					break
				end
			end
			i = i + 1
		end
		total=total+val["i"]
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.EDD:GetSettingValues(arr, cbt, k,ecbt)
	local p, pt = "", ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""
	strt[2] = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.EDD:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local dmg, tot, sort, dmgr, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if dmgr==0 then break end; if totr <= 10000 then pt = "" end; if dmgr<=10000 then p = "" end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		str[4] = ""
		local pname = DPSMateX:GetUserById(na[2])
		if DPSMateX.Settings["columnsedd"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsedd"][3] then str[2] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		if DPSMateX.Settings["columnsedd"][2] then str[3] = "("..strformat("%.1f", dmg/cbt)..p..")" strt[1] = "("..strformat("%.1f", (tot/cbt))..pt..")" end
		if DPSMateX.Settings["columnsedd"][4] then str[4] = " ("..strformat("%.1f", dmg/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[3]..str[1]..str[4]..str[2])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.EDD:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.EDD:EvalTable(DPSMateX.CacheUser[user], k)
		local p, i = 1, 1
		DPSMateX:WipeInPool(ab)
		DPSMateX:WipeInPool(abn)
		
		while a[i] do
			p = 1
			local cat, val = c[i][2][p], c[i][3][p]
			while cat do
				if ab[cat] then
					ab[cat] = ab[cat] + val
				else
					ab[cat] = val
				end
				p = p + 1
				cat, val = c[i][2][p], c[i][3][p]
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
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(abn[i][1]), abn[i][2].." ("..strformat("%.2f", 100*abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttattacked"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end


function DPSMateX.Modules.EDD:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsEDD:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsEDD:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.EDD:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsEDDTotal:UpdateDetails(obj, key)
end

