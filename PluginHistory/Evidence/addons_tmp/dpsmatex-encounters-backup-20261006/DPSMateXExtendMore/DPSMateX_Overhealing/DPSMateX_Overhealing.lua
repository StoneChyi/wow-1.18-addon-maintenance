local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.Overhealing = {}
DPSMateX.Modules.Overhealing.Hist = "OHealing"
DPSMateX.Options.Options[1]["args"]["overhealing"] = {
	order = 80,
	type = 'toggle',
	name = DPSMateX.L["overhealing"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["overhealing"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["overhealing"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "overhealing", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Overhealing.Events = {
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
DPSMateX:Register("overhealing", DPSMateX.Modules.Overhealing, DPSMateX.L["overhealing"])

local tinsert = table.insert
local strformat = string.format
local pairs = pairs
local type = type

-- Pool 复用变量
local sorted_values = {}
local total_value = {}
local evt_a, evt_u, evt_d = {}, {}, {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]="",[4]=""}
local htaken, htakenPet = {}, {}

function DPSMateX.Modules.Overhealing:GetSortedTable(arr,k)
	local CV = 0
	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	total_value[k] = 0

	for c, val in pairs(arr) do
		local name = DPSMateX:GetUserById(c)
		if (not DPSMateX.CacheUser[name][4] or (DPSMateX.CacheUser[name][4] and not DPSMateX.Settings["mergepets"])) then
			if DPSMateX:ApplyFilter(k, name) then
				CV = val["i"]
				local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[name])
				if petsname and DPSMateX.Settings["mergepets"] then
					for petname,_ in petsname do 
						local pettable = DPSMateX.CacheUser[petname]
						if pettable and arr[pettable[1]] and name~=petname then
							CV=CV+arr[pettable[1]]["i"]
						end
					end
				end
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
	end
	return sorted_values[k], total_value[k]
end

function DPSMateX.Modules.Overhealing:EvalTable(user, k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_u)
	DPSMateX:WipeInPool(evt_d)
	local total = 0
	local pet = nil
	local arr = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end

	tinsert(evt_u, user[1])
	local petsname = DPSMateX.DB:GetPetsName(user)
	if petsname and DPSMateX.Settings["mergepets"] then
		for petname,_ in pairs(petsname) do 
			if (petname ~= DPSMateX.L["unknown"] and DPSMateX.CacheUser[petname] and arr[DPSMateX.CacheUser[petname][1]]) and
				DPSMateX.CacheUser[petname][1]~=user[1] then 
				tinsert(evt_u, DPSMateX.CacheUser[petname][1])
			end
		end
	end

	for _, v in pairs(evt_u) do
		for cat, val in pairs(arr[v]) do
			if (type(val) == "table" and cat~="i") then
				if val[1]~=0 and cat~="" then
					if (DPSMateX.CacheUser[DPSMateX:GetUserById(v)][4]) then pet=v; else pet=nil; end
					local i = 1
					while true do
						if (not evt_d[i]) then
							tinsert(evt_a, i, cat)
							local t = DPSMateX.Pool.get()
							tinsert(t, val[1])
							tinsert(t, pet)
							tinsert(evt_d, i, t)
							break
						else
							if (evt_d[i][1] < val[1]) then
								tinsert(evt_a, i, cat)
								local t = DPSMateX.Pool.get()
								tinsert(t, val[1])
								tinsert(t, pet)
								tinsert(evt_d, i, t)
								break
							end
						end
						i = i + 1
					end
				end
			end
		end
		total=total+arr[v]["i"]
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.Overhealing:GetSettingValues(arr, cbt, k,ecbt)
	local p, pt = "", ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""
	strt[2] = ""

	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.Overhealing:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local pname = DPSMateX:GetUserById(na[2])
		local va, tot, sort, varea, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if varea==0 then break end; if totr <= 10000 then pt = "" end; if varea<=10000 then p = "" end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		str[4] = ""
		if DPSMateX.Settings["columnsoverhealing"][1] then str[1] = " "..DPSMateX:Commas(va, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsoverhealing"][3] then str[2] = " ("..strformat("%.1f", 100*varea/totr).."%)" end
		if DPSMateX.Settings["columnsoverhealing"][2] then str[3] = "("..strformat("%.1f", va/cbt)..p..")"; strt[1] = "("..strformat("%.1f", (tot/cbt))..pt..")"  end
		if DPSMateX.Settings["columnsoverhealing"][4] then str[4] = " ("..strformat("%.1f", va/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[3]..str[1]..str[4]..str[2])
		tinsert(tlb_percent, 100*(varea/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.Overhealing:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.Healing:EvalTable(DPSMateX.CacheUser[user], k)
		local db = DPSMateX:GetModeByArr(DPSMateX.DBCache.HealingTaken, k, "THealingTaken")
		local petDamage = 0
		local p, i = 1, 1
		DPSMateX:WipeInPool(htaken)
		DPSMateX:WipeInPool(htakenPet)

		-- Getting the value of the pet
		while a[i] do
			if c[i][2] then
				petDamage = petDamage + c[i][1]
			end
			i = i + 1
		end

		local userId = DPSMateX.CacheUser[user][1]
		local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[user])

		for cat, val in pairs(db) do
			if val[userId] then
				p = 0
				for _, va in pairs(val[userId]) do
					p = p + va[1]
				end
				if p>0 then
					i = 1
					while true do
						if (not htaken[i]) then
							local t = DPSMateX.Pool.get()
							tinsert(t, cat)
							tinsert(t, p)
							tinsert(htaken, i, t)
							break
						else
							if (htaken[i][2] < p) then
								local t = DPSMateX.Pool.get()
								tinsert(t, cat)
								tinsert(t, p)
								tinsert(htaken, i, t)
								break
							end
						end
						i = i + 1
					end
				end
			end

			if petsname then
				for petname,_ in pairs(petsname) do 
					if DPSMateX.CacheUser[petname] and val[DPSMateX.CacheUser[petname][1]] then
						p = 0
						for _, va in pairs(val[DPSMateX.CacheUser[petname][1]]) do
							p = p + va[1]
						end
						if p>0 then
							i = 1
							while true do
								if (not htakenPet[i]) then
									local t = DPSMateX.Pool.get()
									tinsert(t, cat)
									tinsert(t, p)
									tinsert(htakenPet, i, t)
									break
								else
									if (htakenPet[i][2] < p) then
										local t = DPSMateX.Pool.get()
										tinsert(t, cat)
										tinsert(t, p)
										tinsert(htakenPet, i, t)
										break
									end
								end
								i = i + 1
							end
						end
					end
				end
			end
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["tthealing"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["tthealed"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not htaken[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(htaken[i][1]), htaken[i][2].." ("..strformat("%.2f", 100*htaken[i][2]/b).."%)", 1,1,1,1,1,1)
		end

		if petDamage~=0 and petsname then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(DPSMateX.L["ttpet2"],(DPSMateX.CacheUser[user][5] or "pets").." 等".." ("..strformat("%.2f", 100*petDamage/b).."%)",1,0.82,0,1,1,1)
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["tthealing"]..DPSMateX.L["ttabilities"])
			i, p = 1,1
			while DPSMateX.Settings["subviewrows"]>=p do
				if not a[i] then break end
				if c[i][2] then 
					GameTooltip:AddDoubleLine(p..". "..DPSMateX:GetAbilityById(a[i]).." - "..DPSMateX:GetUserById(c[i][2]), c[i][1].." ("..strformat("%.2f", 100*c[i][1]/petDamage).."%)",1,1,1,1,1,1)
					p = p + 1
				end
				i = i + 1
			end
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["ttattacked"])
			for i=1, DPSMateX.Settings["subviewrows"] do
				if not htakenPet[i] then break end
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(htakenPet[i][1]), htakenPet[i][2].." ("..strformat("%.2f", 100*htakenPet[i][2]/petDamage).."%)", 1,1,1,1,1,1)
			end
		end
	end
end

function DPSMateX.Modules.Overhealing:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsOverhealing:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsOverhealing:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Overhealing:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsOverhealingTotal:UpdateDetails(obj, key)
end

