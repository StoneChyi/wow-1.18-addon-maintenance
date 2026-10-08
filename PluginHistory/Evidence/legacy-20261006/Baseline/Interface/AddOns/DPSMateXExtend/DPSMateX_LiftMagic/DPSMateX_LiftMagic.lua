local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.LiftMagic = {}
DPSMateX.Modules.LiftMagic.Hist = "Dispels"
DPSMateX.Options.Options[1]["args"]["liftmagic"] = {
	order = 220,
	type = 'toggle',
	name = DPSMateX.L["liftmagic"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["liftmagic"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["liftmagic"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "liftmagic", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.LiftMagic.Events = {
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
DPSMateX:Register("liftmagic", DPSMateX.Modules.LiftMagic, DPSMateX.L["liftmagic"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs

local new_values = {}
local total_value = {}
local sorted_values = {}

local evt_a, evt_d, eval_temp, total_ev = {}, {}, {}, 0

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]=""}

local tt_ab, tt_abn, tt_ab2, tt_abn2 = {}, {}, {}, {}

function DPSMateX.Modules.LiftMagic:IsValid(ab, cast)
	if DPSMateX.CacheAbility[ab][2]==DPSMateX.L["magic"] or (DPSMateX.Parser.DeMagic[cast] and not DPSMateX.CacheAbility[ab][2]) or (DPSMateX.Parser.DeMagic[cast] and DPSMateX.CacheAbility[ab][2] and DPSMateX.CacheAbility[ab][2]==DPSMateX.L["magic"]) then
		return true
	end
	return false
end

function DPSMateX.Modules.LiftMagic:GetSortedTable(arr,k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0

	for cat, val in pairs(arr) do -- 3 Owner
		local user = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(k, user) then
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
			new_values[k][user] = (new_values[k][user] or 0) + CV
			total_value[k] = total_value[k] + CV
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

function DPSMateX.Modules.LiftMagic:EvalTable(user, k)
	local arr = DPSMateX:GetMode(k)
	total_ev = 0
	DPSMateX:WipeInPool(eval_temp)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)

	if not arr[user[1]] then return evt_a, total_ev, evt_d end
	for cat, val in pairs(arr[user[1]]) do -- 41 Ability
		if cat~="i" then
			for ca, va in pairs(val) do -- 3 Target
				for c, v in pairs(va) do -- 10 Cured Ability
					if self:IsValid(DPSMateX:GetAbilityById(c), DPSMateX:GetAbilityById(cat)) then
						eval_temp[c] = (eval_temp[c] or 0) + v
					end
				end
			end
		end
	end
	for cat, val in pairs(eval_temp) do
		local i = 1
		while true do
			if (not evt_d[i]) then
				tinsert(evt_d, i, val)
				tinsert(evt_a, i, cat)
				break
			else
				if evt_d[i] < val then
					tinsert(evt_d, i, val)
					tinsert(evt_a, i, cat)
					break
				end
			end
			i=i+1
		end
		total_ev = total_ev + val
	end
	return evt_a, total_ev, evt_d
end

function DPSMateX.Modules.LiftMagic:GetSettingValues(arr, cbt, k,ecbt)
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
		if DPSMateX.Settings["columnsmagic"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsmagic"][2] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		tinsert(tbl_name, na[2])
		tinsert(tbl_amount, str[1]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.LiftMagic:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local sum = 0
		DPSMateX:WipeInPool(tt_ab)
		DPSMateX:WipeInPool(tt_abn)
		DPSMateX:WipeInPool(tt_ab2)
		DPSMateX:WipeInPool(tt_abn2)

		local arr = DPSMateX:GetMode(k)
		if arr[DPSMateX.CacheUser[user][1]] then 
			for cat, val in pairs(arr[DPSMateX.CacheUser[user][1]]) do -- 41 Ability
				if cat~="i" then
					for ca, va in pairs(val) do -- Cleansed guy
						for c, v in pairs(va) do -- Cleansed ability
							if self:IsValid(DPSMateX:GetAbilityById(c), DPSMateX:GetAbilityById(cat)) then
								tt_ab[c] = (tt_ab[c] or 0) + v
								tt_ab2[ca] = (tt_ab2[ca] or 0) + v
							end
						end
					end
				end
			end
		end
		
		for cat, val in pairs(tt_ab2) do
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
		for cat, val in pairs(tt_ab) do
			local i = 1
			while true do
				if not tt_abn2[i] then
					local t = DPSMateX.Pool.get()
					tinsert(t, cat)
					tinsert(t, val)
					tinsert(tt_abn2, i, t)
					break
				else
					if tt_abn2[i][2]<val then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, val)
						tinsert(tt_abn2, i, t)
						break
					end
				end
				i = i + 1
			end
			sum = sum + val
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn2[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(tt_abn2[i][1]),tt_abn2[i][2].." ("..strformat("%.2f", 100*tt_abn2[i][2]/sum).."%)",1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdispelled"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(tt_abn[i][1]), tt_abn[i][2].." ("..strformat("%.2f", 100*tt_abn[i][2]/sum).."%)", 1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.LiftMagic:OpenDetails(obj, key,bool)
	if bool then
		DPSMateX.Modules.DetailsLiftMagic:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsLiftMagic:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.LiftMagic:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsLiftMagicTotal:UpdateDetails(obj, key)
end
