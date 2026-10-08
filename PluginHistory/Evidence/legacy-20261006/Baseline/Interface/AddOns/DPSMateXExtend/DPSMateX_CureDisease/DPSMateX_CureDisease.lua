local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.CureDisease = {}
DPSMateX.Modules.CureDisease.Hist = "Dispels"
DPSMateX.Options.Options[1]["args"]["curedisease"] = {
	order = 200,
	type = 'toggle',
	name = DPSMateX.L["curedisease"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["curedisease"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["curedisease"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "curedisease", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.CureDisease.Events = {
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
DPSMateX:Register("curedisease", DPSMateX.Modules.CureDisease, DPSMateX.L["curedisease"])
local tinsert = table.insert
local strformat = string.format
local pairs = pairs

-- Pool 复用变量
local sorted_values = {}
local total_value = {}
local evt_a, evt_b = {}, {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}
local temp_eval = {}
local a, b, abn, abnt = {}, {}, {}, {}

function DPSMateX.Modules.CureDisease:IsValid(ab, cast)
	if DPSMateX.CacheAbility[ab][2]==DPSMateX.L["disease"] or (DPSMateX.Parser.DeDisease[cast] and not DPSMateX.CacheAbility[ab][2]) or (DPSMateX.Parser.DeDisease[cast] and DPSMateX.CacheAbility[ab][2] and DPSMateX.CacheAbility[ab][2]==DPSMateX.L["disease"]) then
		return true
	end
	return false
end

function DPSMateX.Modules.CureDisease:GetSortedTable(arr,k)
	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	total_value[k] = 0
	if arr then
		for cat, val in pairs(arr) do -- 3 Owner
			if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(cat)) then
				local CV = 0
				for ca, va in pairs(val) do -- 42 Ability
					if ca~="i" then
						for c, v in pairs(va) do -- 3 Target
							for ce, ve in pairs(v) do -- 10 Cured Ability
								if self:IsValid(DPSMateX:GetAbilityById(ce), DPSMateX:GetAbilityById(ca)) then
									CV=CV+ve
								end
							end
						end
					end
				end
				local i = 1
				while true do
					if (not sorted_values[k][i]) then
						local t = DPSMateX.Pool.get()
						tinsert(t, CV)
						tinsert(t, cat)
						tinsert(sorted_values[k], i, t)
						break
					else
						if sorted_values[k][i][1] < CV then
							local t = DPSMateX.Pool.get()
							tinsert(t, CV)
							tinsert(t, cat)
							tinsert(sorted_values[k], i, t)
							break
						end
					end
					i=i+1
				end
				total_value[k] = total_value[k] + CV
			end
		end
	end
	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.CureDisease:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_b)
	local total = 0
	temp_eval = DPSMateX:WipeInPool(temp_eval)
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	for cat, val in pairs(arr[user[1]]) do -- 41 Ability
		if cat~="i" then
			for ca, va in pairs(val) do -- 3 Target
				for c, v in pairs(va) do -- 10 Cured Ability
					if self:IsValid(DPSMateX:GetAbilityById(c), DPSMateX:GetAbilityById(cat)) then
						if temp_eval[c] then temp_eval[c]=temp_eval[c]+v else temp_eval[c]=v end
					end
				end
			end
		end
	end
	for cat, val in pairs(temp_eval) do
		local i = 1
		while true do
			if (not evt_b[i]) then
				tinsert(evt_b, i, val)
				tinsert(evt_a, i, cat)
				break
			else
				if evt_b[i] < val then
					tinsert(evt_b, i, val)
					tinsert(evt_a, i, cat)
					break
				end
			end
			i=i+1
		end
		total = total + val
	end
	return evt_a, total, evt_b
end

function DPSMateX.Modules.CureDisease:GetSettingValues(arr, cbt, k)
	local p, pt = "", ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""
	strt[2] = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.CureDisease:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local dmg, tot, sort = na[1], total, sortedTable[1][1]
		if dmg==0 then break end; if tot <= 10000 then pt = "" end;
		str[1] = ""
		str[2] = ""
		str[3] = ""
		if DPSMateX.Settings["columnsdisease"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsdisease"][2] then str[3] = " ("..strformat("%.1f", 100*dmg/tot).."%)" end
		tinsert(tbl_name, DPSMateX:GetUserById(na[2]))
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmg/sort))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.CureDisease:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local p, sum = 0, 0
		DPSMateX:WipeInPool(a)
		DPSMateX:WipeInPool(b)
		DPSMateX:WipeInPool(abn)
		DPSMateX:WipeInPool(abnt)
		local arr = DPSMateX:GetMode(k)
		if arr[DPSMateX.CacheUser[user][1]] then 
			for cat, val in pairs(arr[DPSMateX.CacheUser[user][1]]) do -- 41 Ability
				if cat~="i" then
					for ca, va in pairs(val) do -- Cleansed guy
						for c, v in pairs(va) do -- Cleansed ability
							if self:IsValid(DPSMateX:GetAbilityById(c), DPSMateX:GetAbilityById(cat)) then
								if b[c] then b[c] = b[c] + v else b[c] = v end
								if a[ca] then a[ca] = a[ca] + v else a[ca] = v end
							end
						end
					end
				end
			end
		end
		
		for cat, val in pairs(a) do
			i = 1
			while true do
				if not abn[i] then
					local t = DPSMateX.Pool.get()
					tinsert(t, cat)
					tinsert(t, val)
					tinsert(abn, i, t)
					break
				else
					if abn[i][2]<val then
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
		for cat, val in pairs(b) do
			i = 1
			while true do
				if not abnt[i] then
					local t = DPSMateX.Pool.get()
					tinsert(t, cat)
					tinsert(t, val)
					tinsert(abnt, i, t)
					break
				else
					if abnt[i][2]<val then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(abnt, i, t)
						break
					end
				end
				i = i + 1
			end
			sum = sum + val
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not abnt[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(abnt[i][1]),abnt[i][2].." ("..strformat("%.2f", 100*abnt[i][2]/sum).."%)",1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(abn[i][1]), abn[i][2].." ("..strformat("%.2f", 100*abn[i][2]/sum).."%)", 1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.CureDisease:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsCureDisease:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsCureDisease:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.CureDisease:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsCureDiseaseTotal:UpdateDetails(obj, key)
end
