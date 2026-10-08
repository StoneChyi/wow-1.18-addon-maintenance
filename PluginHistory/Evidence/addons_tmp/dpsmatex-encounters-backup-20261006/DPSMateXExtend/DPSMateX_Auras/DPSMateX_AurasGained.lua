local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.AurasGained = {}
DPSMateX.Modules.AurasGained.Hist = "Auras"
DPSMateX.Options.Options[1]["args"]["aurasgained"] = {
	order = 230,
	type = 'toggle',
	name = DPSMateX.L["aurasgained"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["aurasgained"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["aurasgained"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "aurasgained", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.AurasGained.Events = {
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
DPSMateX:Register("aurasgained", DPSMateX.Modules.AurasGained, DPSMateX.L["aurasgained"])

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

function DPSMateX.Modules.AurasGained:GetSortedTable(arr,k)
	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	total_value[k] = 0
	for cat, val in pairs(arr) do -- 2 Target
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(cat)) then
			local CV = 0
			for ca, va in pairs(val) do -- 3 ability
				for c, v in pairs(va) do -- 1 Ability
					if c==1 then
						for ce, ve in pairs(v) do
							CV=CV+1
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
	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.AurasGained:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_b)
	local total = 0
	temp_eval = DPSMateX:WipeInPool(temp_eval)
	local arr = DPSMateX:GetMode(k)
	for cat, val in pairs(arr[user[1]]) do -- 3 Ability
		local CV = 0
		for ca, va in pairs(val) do -- each one
			if ca==1 then
				for ce, ve in pairs(va) do
					CV=CV+1
				end
			end
		end
		if temp_eval[cat] then temp_eval[cat]=temp_eval[cat]+CV else temp_eval[cat]=CV end
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

function DPSMateX.Modules.AurasGained:GetSettingValues(arr, cbt, k)
	local p, pt = "", ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""
	strt[2] = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.AurasGained:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local dmg, tot, sort = na[1], total, sortedTable[1][1]
		if dmg==0 then break end; if tot <= 10000 then pt = "" end;
		str[1] = ""
		str[2] = ""
		str[3] = ""
		if DPSMateX.Settings["columnsaurasgained"][1] then str[1] = " "..(DPSMateX:Commas(dmg, k) or dmg); strt[2] = DPSMateX:Commas(tot, k) or tot end
		if DPSMateX.Settings["columnsaurasgained"][2] then str[3] = " ("..strformat("%.1f", 100*dmg/tot).."%)" end
		tinsert(tbl_name, DPSMateX:GetUserById(na[2]))
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmg/sort))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.AurasGained:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.AurasGained:EvalTable(DPSMateX.CacheUser[user], k)
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i].." ("..strformat("%.2f", 100*c[i]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.AurasGained:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.Auras:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.Auras:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.AurasGained:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsAurasTotal:UpdateDetails(obj, key)
end
