local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.EffectiveHPS = {}
DPSMateX.Modules.EffectiveHPS.Hist = "EHealing"
DPSMateX.Options.Options[1]["args"]["effectivehps"] = {
	order = 100,
	type = 'toggle',
	name = DPSMateX.L["effectivehps"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["effectivehps"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["effectivehps"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "effectivehps", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.EffectiveHPS.Events = {
	-- Healing/Absorbs/Fail/DeathHistory/Dispels
	"CHAT_MSG_SPELL_PET_BUFF",
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
DPSMateX:Register("effectivehps", DPSMateX.Modules.EffectiveHPS, DPSMateX.L["effectivehps"])

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
local ehtaken, ehtakenPet = {}, {}

function DPSMateX.Modules.EffectiveHPS:GetSortedTable(arr,k)
	local CV = 0
	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	total_value[k] = 0

	for c, val in pairs(arr) do
		local name = DPSMateX:GetUserById(c)
		local userInfo = DPSMateX.CacheUser[name]
		if userInfo and (not userInfo[4] or (userInfo[4] and not DPSMateX.Settings["mergepets"])) then
			if DPSMateX:ApplyFilter(k, name) then
				CV = val["i"] or 0
			local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[name])
			if petsname and DPSMateX.Settings["mergepets"] then
				for petname,_ in petsname do 
					local pettable = DPSMateX.CacheUser[petname]
					if pettable and arr[pettable[1]] and name~=petname then
						CV=CV+(arr[pettable[1]]["i"] or 0)
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

function DPSMateX.Modules.EffectiveHPS:EvalTable(user, k, cbt)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_u)
	DPSMateX:WipeInPool(evt_d)
	local total = 0
	local pet = nil
	local arr, cbet = DPSMateX:GetMode(k)
	if not arr[user[1]] then return end
	cbt = cbt or cbet or 1

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
					local usrName = DPSMateX:GetUserById(v)
					if (DPSMateX.CacheUser[usrName][4]) then pet=v; else pet=nil; end
					local i = 1
					while true do
						if (not evt_d[i]) then
							tinsert(evt_a, i, cat)
							local t = DPSMateX.Pool.get()
							tinsert(t, val[1]/cbt)
							tinsert(t, pet)
							tinsert(evt_d, i, t)
							break
						else
							if (evt_d[i][1] < val[1]/cbt) then
								tinsert(evt_a, i, cat)
								local t = DPSMateX.Pool.get()
								tinsert(t, val[1]/cbt)
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
	return evt_a, total/cbt, evt_d
end

function DPSMateX.Modules.EffectiveHPS:GetSettingValues(arr, cbt, k,ecbt)
	local p, pt = "", ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""
	strt[2] = ""

	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.EffectiveHPS:GetSortedTable(arr,k)
	for _, na in ipairs(sortedTable) do
		local val = na[1]
		local pname = DPSMateX:GetUserById(na[2])
		local va, tot, sort, varea, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1][1], k)
		if varea==0 then break end; if totr <= 10000 then pt = "" end; if varea<=10000 then p = "" end
		str[1] = ""
		str[2] = ""
		str[3] = ""
		str[4] = ""
		if DPSMateX.Settings["columnsehps"][2] then str[1] = " "..strformat("%.1f", va/cbt)..p; strt[2] = " "..strformat("%.1f", (tot/cbt))..pt end
		if DPSMateX.Settings["columnsehps"][3] then str[2] = " ("..strformat("%.1f", 100*varea/totr).."%)" end
		if DPSMateX.Settings["columnsehps"][1] then str[3] = "("..DPSMateX:Commas(va, k)..p..")"; strt[1] = "("..DPSMateX:Commas(tot, k)..pt..")" end
		if DPSMateX.Settings["columnsehps"][4] then str[4] = " ("..strformat("%.1f", va/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[3]..str[1]..str[4]..str[2])
		tinsert(tlb_percent, 100*(varea/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.EffectiveHPS:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.EffectiveHPS:EvalTable(DPSMateX.CacheUser[user], k)
		local db, cbt = DPSMateX:GetModeByArr(DPSMateX.DBCache.EHealingTaken, k, "EHealingTaken")
		local petDamage = 0
		local p, i = 1, 1
		DPSMateX:WipeInPool(ehtaken)
		DPSMateX:WipeInPool(ehtakenPet)

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
						if (not ehtaken[i]) then
							local t = DPSMateX.Pool.get()
							tinsert(t, cat)
							tinsert(t, p)
							tinsert(ehtaken, i, t)
							break
						else
							if (ehtaken[i][2] < p) then
								local t = DPSMateX.Pool.get()
								tinsert(t, cat)
								tinsert(t, p)
								tinsert(ehtaken, i, t)
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
								if (not ehtakenPet[i]) then
									local t = DPSMateX.Pool.get()
									tinsert(t, cat)
									tinsert(t, p)
									tinsert(ehtakenPet, i, t)
									break
								else
									if (ehtakenPet[i][2] < p) then
										local t = DPSMateX.Pool.get()
										tinsert(t, cat)
										tinsert(t, p)
										tinsert(ehtakenPet, i, t)
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
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]), strformat("%.2f", c[i][1]).." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["tthealed"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not ehtaken[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(ehtaken[i][1]), strformat("%.2f", ehtaken[i][2]/cbt).." ("..strformat("%.2f", 100*(ehtaken[i][2]/cbt)/b).."%)", 1,1,1,1,1,1)
		end

		if petDamage~=0 and petsname then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(DPSMateX.L["ttpet2"],(DPSMateX.CacheUser[user][5] or "pets").." 等".." ("..strformat("%.2f", 100*petDamage/b).."%)",1,0.82,0,1,1,1)
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["tthealing"]..DPSMateX.L["ttabilities"])
			i, p = 1,1
			while DPSMateX.Settings["subviewrows"]>=p do
				if not a[i] then break end
				if c[i][2] then 
					GameTooltip:AddDoubleLine(p..". "..DPSMateX:GetAbilityById(a[i]).." - "..DPSMateX.DB:GetPetShortName(c[i][2]), strformat("%.2f", c[i][1]).." ("..strformat("%.2f", 100*c[i][1]/petDamage).."%)",1,1,1,1,1,1)
					p = p + 1
				end
				i = i + 1
			end
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["ttattacked"])
			for i=1, DPSMateX.Settings["subviewrows"] do
				if not ehtakenPet[i] then break end
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(ehtakenPet[i][1]), strformat("%.2f", ehtakenPet[i][2]/cbt).." ("..strformat("%.2f", 100*(ehtakenPet[i][2]/cbt)/petDamage).."%)", 1,1,1,1,1,1)
			end
		end
	end
end

function DPSMateX.Modules.EffectiveHPS:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsEHealing:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsEHealing:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.EffectiveHPS:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsEHealingTotal:UpdateDetails(obj, key)
end

