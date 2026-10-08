local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.Dispels = {}
DPSMateX.Modules.Dispels.Hist = "Dispels"
DPSMateX.Options.Options[1]["args"]["dispels"] = {
	order = 180,
	type = 'toggle',
	name = DPSMateX.L["dispels"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["dispels"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["dispels"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "dispels", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Dispels.Events = {
	"CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_SELF_DAMAGE",
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
DPSMateX:Register("dispels", DPSMateX.Modules.Dispels, DPSMateX.L["dispels"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs

local new_values = {}
local total_value = {}
local sorted_values = {}

local eval_temp = {}
local evt_a, evt_d, total_ev = {}, {}, 0

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

local tt_a, tt_b = {}, {}
local tt_abn, tt_abnt = {}, {}

function DPSMateX.Modules.Dispels:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for cat, val in pairs(arr) do -- 3 Owner
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(cat)) then
			local userName = DPSMateX:GetUserById(cat)
			new_values[k][userName] = val["i"][1]
			total_value[k] = total_value[k] + val["i"][1]
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

function DPSMateX.Modules.Dispels:EvalTable(user, k)
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	total_ev = arr[user[1]]["i"][1]
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	for cat, val in pairs(arr[user[1]]) do -- 41 Ability
		if cat~="i" then
			local CV = 0
			for ca, va in pairs(val) do
				for c, v in pairs(va) do
					CV = CV + v
				end
			end
			local i = 1
			while true do
				if (not evt_d[i]) then
					tinsert(evt_a, i, cat)
					tinsert(evt_d, i, CV)
					break
				else
					if evt_d[i] < CV then
						tinsert(evt_a, i, cat)
						tinsert(evt_d, i, CV)
						break
					end
				end
				i = i + 1
			end
		end
	end
	return evt_a, total_ev, evt_d
end

function DPSMateX.Modules.Dispels:GetSettingValues(arr, cbt, k,ecbt)
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
		if DPSMateX.Settings["columnsdispels"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsdispels"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[2]..str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Dispels:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local sum = 0
		DPSMateX:WipeInPool(tt_a)
		DPSMateX:WipeInPool(tt_b)
		DPSMateX:WipeInPool(tt_abn)
		DPSMateX:WipeInPool(tt_abnt)

		local arr = DPSMateX:GetMode(k)
		if arr[DPSMateX.CacheUser[user][1]] then
			for cat, val in pairs(arr[DPSMateX.CacheUser[user][1]]) do -- 41 Ability
				if cat~="i" then
					for ca, va in pairs(val) do -- Cleansed guy
						local p = 0
						for c, v in pairs(va) do -- Cleansed ability
							tt_b[c] = (tt_b[c] or 0) + v
							p = p + v
						end
						tt_a[ca] = (tt_a[ca] or 0) + p
					end
				end
			end
		end

		for cat, val in pairs(tt_a) do
			local i = 1
			while true do
				if not tt_abn[i] then
					local t = DPSMateX.Pool.get()
					tinsert(t, cat)
					tinsert(t, val)
					tinsert(tt_abn, i, t)
					break
				else
					if tt_abn[i][2]<val then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(tt_abn, i, t)
						break
					end
				end
				i = i + 1
			end
		end
		for cat, val in pairs(tt_b) do
			sum = sum + val
			local i = 1
			while true do
				if not tt_abnt[i] then
					local t = DPSMateX.Pool.get()
					tinsert(t, cat)
					tinsert(t, val)
					tinsert(tt_abnt, i, t)
					break
				else
					if tt_abnt[i][2]<val then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(tt_abnt, i, t)
						break
					end
				end
				i = i + 1
			end
		end

		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abnt[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(tt_abnt[i][1]),tt_abnt[i][2].." ("..strformat("%.2f", 100*tt_abnt[i][2]/sum).."%)",1,1,1,1,1,1)
		end

		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(tt_abn[i][1]), tt_abn[i][2].." ("..strformat("%.2f", 100*tt_abn[i][2]/sum).."%)", 1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.Dispels:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsDispels:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsDispels:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Dispels:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsDispelsTotal:UpdateDetails(obj, key)
end
