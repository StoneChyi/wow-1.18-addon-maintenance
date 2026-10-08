local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.Interrupts = {}
DPSMateX.Modules.Interrupts.Hist = "Interrupts"
DPSMateX.Options.Options[1]["args"]["interrupts"] = {
	order = 160,
	type = 'toggle',
	name = DPSMateX.L["interrupts"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["interrupts"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["interrupts"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "interrupts", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Interrupts.Events = {
	-- Damage
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
}

-- Register the moodule
DPSMateX:Register("interrupts", DPSMateX.Modules.Interrupts, DPSMateX.L["interrupts"])

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
local str = {[1]="",[2]="",[3]=""}

local tt_ab, tt_abn, tt_abPet, tt_abnPet = {}, {}, {}, {}

function DPSMateX.Modules.Interrupts:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for cat, val in pairs(arr) do -- 1 Owner
		local name = DPSMateX:GetUserById(cat)
		if (not DPSMateX.CacheUser[name][4] or (DPSMateX.CacheUser[name][4] and not DPSMateX.Settings["mergepets"])) then
			if DPSMateX:ApplyFilter(k, name) then
				local CV = val["i"][1]
				if DPSMateX.CacheUser[name][5] and DPSMateX.CacheUser[DPSMateX.CacheUser[name][5]] and DPSMateX.CacheUser[DPSMateX.CacheUser[name][5]][1] and arr[DPSMateX.CacheUser[DPSMateX.CacheUser[name][5]][1]] and DPSMateX.Settings["mergepets"] and DPSMateX.CacheUser[name][5]~=name then
					CV=CV+arr[DPSMateX.CacheUser[DPSMateX.CacheUser[name][5]][1]]["i"][1]
				end
				new_values[k][name] = CV
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

local u = {}
function DPSMateX.Modules.Interrupts:EvalTable(user, k)
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	total_ev = 0
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	u = DPSMateX:WipeInPool(u)
	u[1] = user[1]
	if (user[5] and user[5] ~= DPSMateX.L["unknown"] and arr[DPSMateX.CacheUser[user[5]][1]]) and DPSMateX.Settings["mergepets"] then u[2] = DPSMateX.CacheUser[user[5]][1] end
	for _, vvv in pairs(u) do
		for cat, val in pairs(arr[vvv]) do -- 41 Ability
			if cat~="i" then
				local CV = 0
				local d, e = DPSMateX.Pool.get(), DPSMateX.Pool.get()
				local isPet = false
				if (DPSMateX.CacheUser[DPSMateX:GetUserById(vvv)][4]) then isPet=true; else isPet=false; end
				for ca, va in pairs(val) do
					local CVV = 0
					for c, v in pairs(va) do
						CV = CV + v
						CVV = CVV + v
					end
					local i = 1
					while true do
						if (not d[i]) then
							tinsert(d, i, CVV)
							tinsert(e, i, ca)
							break
						else
							if d[i] < CVV then
								tinsert(d, i, CVV)
								tinsert(e, i, ca)
								break
							end
						end
						i=i+1
					end
				end
				if CV>0 then
					local i = 1
					while true do
						if (not evt_d[i]) then
							tinsert(evt_a, i, {cat, isPet})
							local innerT = DPSMateX.Pool.get()
							tinsert(innerT, CV)
							tinsert(innerT, e)
							tinsert(innerT, d)
							tinsert(evt_d, i, innerT)
							break
						else
							if evt_d[i][1] < CV then
								tinsert(evt_a, i, {cat, isPet})
								local innerT = DPSMateX.Pool.get()
								tinsert(innerT, CV)
								tinsert(innerT, e)
								tinsert(innerT, d)
								tinsert(evt_d, i, innerT)
								break
							end
						end
						i=i+1
					end
				end
			end
		end
		total_ev = total_ev + arr[vvv]["i"][1]
	end
	return evt_a, total_ev, evt_d
end

function DPSMateX.Modules.Interrupts:GetSettingValues(arr, cbt, k,ecbt)
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
		if DPSMateX.Settings["columnsinterrupts"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsinterrupts"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Interrupts:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.Interrupts:EvalTable(DPSMateX.CacheUser[user], k)
		local petTotal = 0
		DPSMateX:WipeInPool(tt_ab)
		DPSMateX:WipeInPool(tt_abn)
		DPSMateX:WipeInPool(tt_abPet)
		DPSMateX:WipeInPool(tt_abnPet)

		local i = 1
		while a[i] do
			if a[i][2] then
				p = 1
				while c[i][2][p] do
					tt_abPet[c[i][2][p]] = (tt_abPet[c[i][2][p]] or 0) + c[i][3][p]
					petTotal = petTotal + c[i][3][p]
					p = p + 1
				end
			else
				p = 1
				while c[i][2][p] do
					tt_ab[c[i][2][p]] = (tt_ab[c[i][2][p]] or 0) + c[i][3][p]
					p = p + 1
				end
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
		for cat, val in pairs(tt_abPet) do
			if val>0 then
				local j = 1
				while true do
					if (not tt_abnPet[j]) then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(tt_abnPet, j, t)
						break
					else
						if (tt_abnPet[j][2] < val) then
							local t = DPSMateX.Pool.get()
							tinsert(t, cat)
							tinsert(t, val)
							tinsert(tt_abnPet, j, t)
							break
						end
					end
					j = j + 1
				end
			end
		end

		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttinterrupt"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			if not a[i][2] then 
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i][1]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/(b-petTotal)).."%)",1,1,1,1,1,1)
			end
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttinterrupted"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(tt_abn[i][1]), tt_abn[i][2].." ("..strformat("%.2f", 100*tt_abn[i][2]/(b-petTotal)).."%)", 1,1,1,1,1,1)
		end
		
		if petTotal~=0 and DPSMateX.CacheUser[user][5] then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(DPSMateX.L["ttpet2"],DPSMateX.CacheUser[user][5].."<"..user.."> ("..strformat("%.2f", 100*petTotal/b).."%)",1,0.82,0,1,1,1)
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["ttinterrupt"]..DPSMateX.L["ttabilities"])
			local pp = 1
			i = 1
			while DPSMateX.Settings["subviewrows"]>=pp do
				if not a[i] then break end
				if a[i][2] then 
					GameTooltip:AddDoubleLine(pp..". "..DPSMateX:GetAbilityById(a[i][1]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/petTotal).."%)",1,1,1,1,1,1)
					pp = pp + 1
				end
				i = i + 1
			end
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["ttinterrupted"])
			for i=1, DPSMateX.Settings["subviewrows"] do
				if not tt_abnPet[i] then break end
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(tt_abnPet[i][1]), tt_abnPet[i][2].." ("..strformat("%.2f", 100*tt_abnPet[i][2]/petTotal).."%)", 1,1,1,1,1,1)
			end
		end
	end
end

function DPSMateX.Modules.Interrupts:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsInterrupts:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsInterrupts:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Interrupts:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsInterruptsTotal:UpdateDetails(obj, key)
end
