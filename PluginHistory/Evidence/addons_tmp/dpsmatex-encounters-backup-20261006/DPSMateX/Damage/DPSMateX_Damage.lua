local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.Damage = {}
DPSMateX.Modules.Damage.Hist = "DMGDone"
DPSMateX.Options.Options[1]["args"]["damage"] = {
	order = 20,
	type = 'toggle',
	name = DPSMateX.L["damage"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["damage"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["damage"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "damage", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.Damage.Events = {
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
	--"periodic damage"
	"CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE",
	"CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",

	"CHAT_MSG_SPELL_AURA_GONE_SELF",
	"CHAT_MSG_SPELL_AURA_GONE_OTHER",
	"CHAT_MSG_SPELL_AURA_GONE_PARTY",

	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
	"CHAT_MSG_SPELL_DAMAGESHIELDS_ON_OTHERS",
}

-- Register the moodule
DPSMateX:Register("damage", DPSMateX.Modules.Damage, DPSMateX.L["damage"])

local tinsert = table.insert
local tsort = table.sort
local strformat = string.format
local pairs = pairs
local ipairs = ipairs
local type = type

local new_values = {}
local total_value = {}
local sorted_values = {}
local petsMasterSeen = {}

local function SortNameAmounts(na, stbl)
    for name, amount in pairs(na) do
		local t = DPSMateX.Pool.get()
		tinsert(t, amount)
		tinsert(t, name)
        tinsert(stbl, t)
    end

    tsort(stbl, function(a, b) return a[1] > b[1] end)
end

function DPSMateX.Modules.Damage:GetSortedTable(arr, k)
	new_values[k] = DPSMateX:WipeInPool(new_values[k])
	total_value[k] = 0
	petsMasterSeen[k] = DPSMateX:WipeInPool(petsMasterSeen[k])

	for usrId, val in pairs(arr) do
		local unit_name, c, go = DPSMateX:PetFilter(usrId, petsMasterSeen[k])
		if c ~= usrId then val = arr[c] end
		if go then
			if DPSMateX:ApplyFilter(k, unit_name) then
				local unit_dmg = go * ((val and val["i"]) or 0)
				local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[unit_name])
				if petsname and DPSMateX.Settings["mergepets"] then
					for petname,_ in petsname do 
						local pettable = DPSMateX.CacheUser[petname]
						if pettable and arr[pettable[1]] and unit_name~=petname then
							unit_dmg=unit_dmg+(arr[pettable[1]]["i"] or 0)
						end
					end
				end
				new_values[k][unit_name] = (new_values[k][unit_name] or 0) + unit_dmg
				total_value[k] = total_value[k] + unit_dmg
			end
		end
	end

	sorted_values[k] = DPSMateX:WipeInPool(sorted_values[k])
	SortNameAmounts(new_values[k], sorted_values[k])

	return sorted_values[k], total_value[k]
end

local evt_a, evt_u, evt_d, total, pet = {}, {}, {}, 0, nil
function DPSMateX.Modules.Damage:EvalTable(user, k)
	local arr = DPSMateX:GetMode(k)
	--if not arr[user[1]] then return a, total, d end
	total, pet = 0, nil
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_u)
	DPSMateX:WipeInPool(evt_d)

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
		if arr[v] then
			for cat, val in pairs(arr[v]) do
				if (type(val) == "table" and cat~="i") then
					--if val[13]~=0 and cat~="" then
					if cat then
						local usrName = DPSMateX:GetUserById(v)
						if (DPSMateX.CacheUser[usrName][4]) then pet=v; else pet=nil; end
						local i = 1
						while true do
							if (not evt_d[i]) then
								tinsert(evt_a, i, cat) -- ability
								local t = DPSMateX.Pool.get()
								tinsert(t, val[13])
								tinsert(t, pet)
								tinsert(evt_d, i, t) -- value, pet
								break
							else
								if (evt_d[i][1] < val[13]) then
									tinsert(evt_a, i, cat) -- ability
									local t = DPSMateX.Pool.get()
									tinsert(t, val[13])
									tinsert(t, pet)
									tinsert(evt_d, i, t) -- value, pet
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
	end
	return evt_a, total, evt_d
end

local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]="",[4]=""}

function DPSMateX.Modules.Damage:GetSettingValues(arr, cbt, k, ecbt)
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
		str[4] = ""
		local pname = na[2]
		if DPSMateX.Settings["columnsdmg"][1] then str[1] = " "..DPSMateX:Commas(dmg, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsdmg"][2] then str[2] = "("..strformat("%.1f", (dmg/cbt))..p..")"; strt[1] = "("..strformat("%.1f", (tot/cbt))..pt..") " end
		if DPSMateX.Settings["columnsdmg"][3] then str[3] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		if DPSMateX.Settings["columnsdmg"][4] then str[4] = " ("..strformat("%.1f", dmg/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[2]..str[1]..str[4]..str[3])
		tinsert(tlb_percent, 100*(dmgr/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

local edtaken, edtakenPet = {}, {}
function DPSMateX.Modules.Damage:ShowTooltip(user,k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.Damage:EvalTable(DPSMateX.CacheUser[user], k)
		local db = DPSMateX:GetModeByArr(DPSMateX.DBCache.EDT, k, "EDTaken")
		local i, p = 1, 0
		local petDamage = 0
		DPSMateX:WipeInPool(edtaken)
		DPSMateX:WipeInPool(edtakenPet)
		-- Getting the value of the pet
		while a[i] do
			if c[i][2] then
				petDamage = petDamage + c[i][1]
			end
			i = i + 1
		end
		
		local userId = DPSMateX.CacheUser[user][1]
		local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[user])
		-- Getting edt values
		for cat, val in pairs(db) do
			if val[userId] then
			-- Check if val[userId] is a table before accessing its "i" key
			local edtValue = val[userId]
			local iValue = 0
			
			if type(edtValue) == "table" then
				local iData = edtValue["i"] or 0
				-- Ensure iData is a number
				if type(iData) == "table" then
					iValue = 0 -- 或者根据实际情况设置一个合理的默认值
				else
					iValue = iData
				end
			elseif type(edtValue) == "number" then
				-- If it's a number, use it directly
				iValue = edtValue
			end
			
			if iValue > 0 then
				i = 1
				while true do
					if (not edtaken[i]) then
						local t = DPSMateX.Pool.get()
						tinsert(t, cat)
						tinsert(t, iValue)
						tinsert(edtaken, i, t)
						break
					else
						if (edtaken[i][2] < iValue) then
							local t = DPSMateX.Pool.get()
							tinsert(t, cat)
							tinsert(t, iValue)
							tinsert(edtaken, i, t)
							break
						end
					end
					i = i + 1
				end
			end
			end
			
			if petsname then
			for petname,_ in pairs(petsname) do 
				if DPSMateX.CacheUser[petname] then
					local petId = DPSMateX.CacheUser[petname][1]
					if val[petId] then
						-- Check if val[petId] is a table before accessing its "i" key
					local petEdtValue = val[petId]
					local petIValue = 0
					
					if type(petEdtValue) == "table" then
						local iData = petEdtValue["i"] or 0
						-- Ensure iData is a number
						if type(iData) == "table" then
							petIValue = 0 -- 或者根据实际情况设置一个合理的默认值
						else
							petIValue = iData
						end
					elseif type(petEdtValue) == "number" then
						-- If it's a number, use it directly
						petIValue = petEdtValue
					end
					
					if petIValue > 0 then
							i = 1
							while true do
								if (not edtakenPet[i]) then
									local t = DPSMateX.Pool.get()
									tinsert(t, cat)
									tinsert(t, petIValue)
									tinsert(edtakenPet, i, t)
									break
								else
									if (edtakenPet[i][2] < petIValue) then
										local t = DPSMateX.Pool.get()
										tinsert(t, cat)
										tinsert(t, petIValue)
										tinsert(edtakenPet, i, t)
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
		end
	
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttdamage"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			if not c[i][2] then 
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/(b-petDamage)).."%)",1,1,1,1,1,1)
			end
		end
		
		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttattacked"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not edtaken[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(edtaken[i][1]), edtaken[i][2].." ("..strformat("%.2f", 100*edtaken[i][2]/(b-petDamage)).."%)", 1,1,1,1,1,1)
		end
		
		if petDamage~=0 and petsname then
			GameTooltip:AddLine(" ")
			GameTooltip:AddDoubleLine(DPSMateX.L["ttpet2"],(DPSMateX.CacheUser[user][5] or "pets").." 等".." ("..strformat("%.2f", 100*petDamage/b).."%)",1,0.82,0,1,1,1)
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["ttdamage"]..DPSMateX.L["ttabilities"])
			i, p = 1,1
			while DPSMateX.Settings["subviewrows"]>=p do
				if not a[i] then break end
				if c[i][2] then 
					GameTooltip:AddDoubleLine(p..". "..DPSMateX:GetAbilityById(a[i]).." - "..DPSMateX.DB:GetPetShortName(c[i][2]), c[i][1].." ("..strformat("%.2f", 100*c[i][1]/petDamage).."%)",1,1,1,1,1,1)
					p = p + 1
				end
				i = i + 1
			end
			GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttpet"]..DPSMateX.L["ttattacked"])
			for i=1, DPSMateX.Settings["subviewrows"] do
				if not edtakenPet[i] then break end
				GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(edtakenPet[i][1]), edtakenPet[i][2].." ("..strformat("%.2f", 100*edtakenPet[i][2]/petDamage).."%)", 1,1,1,1,1,1)
			end
		end
	end
end

function DPSMateX.Modules.Damage:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsDamage:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsDamage:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.Damage:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsDamageTotal:UpdateDetails(obj, key)
end
