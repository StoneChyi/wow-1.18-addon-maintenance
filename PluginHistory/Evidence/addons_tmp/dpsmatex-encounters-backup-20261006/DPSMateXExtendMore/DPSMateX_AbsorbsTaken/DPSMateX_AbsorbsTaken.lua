local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.AbsorbsTaken = {}
DPSMateX.Modules.AbsorbsTaken.Hist = "Absorbs"
DPSMateX.Options.Options[1]["args"]["absorbstaken"] = {
	order = 120,
	type = 'toggle',
	name = DPSMateX.L["absorbstaken"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["absorbstaken"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["absorbstaken"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "absorbstaken", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.AbsorbsTaken.Events = {
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
DPSMateX:Register("absorbstaken", DPSMateX.Modules.AbsorbsTaken, DPSMateX.L["absorbstaken"])

local tinsert = table.insert
local strformat = string.format

local pairs = pairs

-- Object pool variables
local sorted_values = {}
local total_value = {}
local evt_a, evt_u, evt_d = {}, {}, {}
local tbl_name, tbl_amount, tlb_percent = {}, {}, {}
local strt = {[1]="",[2]=""}
local str = {[1]="",[2]="",[3]="",[4]=""}
local tt_ab, tt_abn = {}, {}

function DPSMateX.Modules.AbsorbsTaken:GetSortedTable(arr,k)
	local total = 0
	if not sorted_values[k] then sorted_values[k] = DPSMateX.Pool.get() end
	local b = sorted_values[k]
	DPSMateX:WipeInPool(b)
	for cat, val in pairs(arr) do -- 28 Target
		if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(cat)) then
			local PerPlayerAbsorb = 0
			for ca, va in pairs(val) do -- 28 Owner
				local ownername = DPSMateX:GetUserById(ca)
				local PerOwnerAbsorb = 0
				for c, v in pairs(va) do -- Power Word: Shield
					if c~="i" then
						local shieldname = DPSMateX:GetAbilityById(c)
						local PerAbilityAbsorb = 0
						for ce, ve in pairs(v) do -- 1
							local PerShieldAbsorb = 0
							for cet, vel in pairs(ve) do
								if cet~="i" then
									local totalHits = 0
									for qq,ss in vel do
										totalHits = totalHits + ss
									end
									for qq,ss in vel do
										local p = 5
										if DPSMateX.DBCache.DamageTaken[1][cat] then
											--DPSMateX:SendMessage("VTEST: 1")
											if DPSMateX.DBCache.DamageTaken[1][cat][cet] then
												--DPSMateX:SendMessage("VTEST: 2")
												if DPSMateX.DBCache.DamageTaken[1][cat][cet][qq] then
												--	DPSMateX:SendMessage("VTEST: 3")
													if DPSMateX.DBCache.DamageTaken[1][cat][cet][qq][14]~=0 then
														p=ceil(DPSMateX.DBCache.DamageTaken[1][cat][cet][qq][14])
														--DPSMateX:SendMessage("VALUE: "..p)
													end
												end
											end
										end
										if DPSMateX.DBCache.EDT[1][cat] and p==5 or p==0 then
											if DPSMateX.DBCache.EDT[1][cat][cet] then
													--DPSMateX:SendMessage("ZERO TEST BEFORE//"..DPSMateX:GetAbilityById(qq))
												if DPSMateX.DBCache.EDT[1][cat][cet][qq] then
													--DPSMateX:SendMessage("ZERO TEST//"..DPSMateX:GetAbilityById(qq))
													if DPSMateX.DBCache.EDT[1][cat][cet][qq][4]~=0 then
														p=ceil((DPSMateX.DBCache.EDT[1][cat][cet][qq][4]+DPSMateX.DBCache.EDT[1][cat][cet][qq][8])/2)
													end
												end
											end
										end
										if p>DPSMateX.DB.FixedShieldAmounts[shieldname] then
											p = DPSMateX.DB.FixedShieldAmounts[shieldname]
										end
										if p==5 or p==0 then
											p = ceil((1/totalHits)*((DPSMateX.CacheUser[ownername][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[shieldname]*0.33)
										end
										PerShieldAbsorb=PerShieldAbsorb+ss*p
									end
								end
							end
							if ve["i"][1]==1 then
								PerShieldAbsorb=PerShieldAbsorb+ve["i"][2]
							end
							PerAbilityAbsorb = PerAbilityAbsorb+PerShieldAbsorb
						end
						PerOwnerAbsorb = PerOwnerAbsorb+PerAbilityAbsorb
					end
				end
				PerPlayerAbsorb = PerPlayerAbsorb+PerOwnerAbsorb
			end
			total = total+PerPlayerAbsorb
			local i = 1
			while true do
				if (not b[i]) then
					tinsert(b, i, {PerPlayerAbsorb, cat})
					break
				else
					if b[i][1] < PerPlayerAbsorb then
						tinsert(b, i, {PerPlayerAbsorb, cat})
						break
					end
				end
				i=i+1
			end
		end
	end
	return b, total
end
				
local temp = {}
function DPSMateX.Modules.AbsorbsTaken:EvalTable(user, k)
	local arr = DPSMateX:GetMode(k)
	DPSMateX:WipeInPool(evt_a)
	DPSMateX:WipeInPool(evt_d)
	local total = 0
	for cat, val in arr[user[1]] do -- 28 Target
		local ownername = DPSMateX:GetUserById(cat)
		local PerTargetAbsorb = 0
		local ta = DPSMateX.Pool.get()
		local tb = DPSMateX.Pool.get()
		temp = DPSMateX:WipeInPool(temp)
		for ca, va in pairs(val) do -- Power Word Shield
			if ca~="i" then
				local shieldname = DPSMateX:GetAbilityById(ca)
				local PerAbilityAbsorb = 0
				local taa = DPSMateX.Pool.get()
				local tbb = DPSMateX.Pool.get()
				for c, v in pairs(va) do -- 1
					local PerShieldAbsorb = 0
					for ce, ve in pairs(v) do
						if ce~="i" then
							local totalHits = 0
							for qq,ss in ve do
								totalHits = totalHits + ss
							end
							for qq,ss in ve do
								local p = 5
								if DPSMateX.DBCache.DamageTaken[1][user[1]] then
									if DPSMateX.DBCache.DamageTaken[1][user[1]][ce] then
										if DPSMateX.DBCache.DamageTaken[1][user[1]][ce][qq] then
											if DPSMateX.DBCache.DamageTaken[1][user[1]][ce][qq][14]~=0 then
												p=ceil(DPSMateX.DBCache.DamageTaken[1][user[1]][ce][qq][14])
											end
										end
									end
								elseif DPSMateX.DBCache.EDT[1][user[1]] then
									if DPSMateX.DBCache.EDT[1][user[1]][ce] then
										if DPSMateX.DBCache.EDT[1][user[1]][ce][qq] then
											if DPSMateX.DBCache.EDT[1][user[1]][ce][qq][4]~=0 then
												p=ceil((DPSMateX.DBCache.EDT[1][user[1]][ce][qq][4]+DPSMateX.DBCache.EDT[1][user[1]][ce][qq][8])/2)
											end
										end
									end
								end
								if p>DPSMateX.DB.FixedShieldAmounts[shieldname] then
									p = DPSMateX.DB.FixedShieldAmounts[shieldname]
								end
								if p==5 or p==0 then
									p = ceil((1/totalHits)*((DPSMateX.CacheUser[ownername][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[shieldname]*0.33)
								end
								PerShieldAbsorb=PerShieldAbsorb+ss*p
								if not temp[ce] then temp[ce] = DPSMateX.Pool.get() end
								if not temp[ce][qq] then temp[ce][qq] = ss*p else temp[ce][qq] =temp[ce][qq]+ss*p end
							end
						end
					end
					if v["i"][1]==1 then
						PerShieldAbsorb=PerShieldAbsorb+v["i"][2]
						if not temp[v["i"][4]] then temp[v["i"][4]] = DPSMateX.Pool.get() end
						if not temp[v["i"][4]][v["i"][3]] then temp[v["i"][4]][v["i"][3]] = v["i"][2] else temp[v["i"][4]][v["i"][3]] = temp[v["i"][4]][v["i"][3]] + v["i"][2] end
					end
					PerAbilityAbsorb=PerAbilityAbsorb+PerShieldAbsorb
				end
				PerTargetAbsorb=PerTargetAbsorb+PerAbilityAbsorb
				for ut, utt in temp do
					local CVV = 0
					local qa = DPSMateX.Pool.get()
					local qd = DPSMateX.Pool.get()
					for qt, qtt in utt do
						CVV = CVV + qtt
						if qtt>0 then
							local i = 1
							while true do
								if (not qd[i]) then
									tinsert(qd, i, qtt)
									tinsert(qa, i, qt)
									break
								else
									if qd[i] < qtt then
										tinsert(qd, i, qtt)
										tinsert(qa, i, qt)
										break
									end
								end
								i=i+1
							end
						end
					end
					if CVV>0 then
						local i = 1
						while true do
							if (not tbb[i]) then
								tinsert(tbb, i, {CVV, qa, qd})
								tinsert(taa, i, ut)
								break
							else
								if tbb[i][1] < CVV then
									tinsert(tbb, i, {CVV, qa, qd})
									tinsert(taa, i, ut)
									break
								end
							end
							i=i+1
						end
					end
				end
				if PerAbilityAbsorb>0 then
					local i = 1
					while true do
						if (not tb[i]) then
							tinsert(tb, i, {PerAbilityAbsorb, taa, tbb})
							tinsert(ta, i, ca)
							break
						else
							if tb[i][1] < PerAbilityAbsorb then
								tinsert(tb, i, {PerAbilityAbsorb, taa, tbb})
								tinsert(ta, i, ca)
								break
							end
						end
						i=i+1
					end
				end
			end
		end
		if PerTargetAbsorb>0 then
			local i = 1
			while true do
				if (not evt_d[i]) then
					tinsert(evt_d, i, {PerTargetAbsorb, ta, tb})
					tinsert(evt_a, i, cat)
					break
				else
					if evt_d[i][1] < PerTargetAbsorb then
						tinsert(evt_d, i, {PerTargetAbsorb, ta, tb})
						tinsert(evt_a, i, cat)
						break
					end
				end
				i=i+1
			end
		end
		total=total+PerTargetAbsorb
	end
	return evt_a, total, evt_d
end

function DPSMateX.Modules.AbsorbsTaken:GetSettingValues(arr, cbt, k,ecbt)
	local pt = ""
	DPSMateX:WipeInPool(tbl_name)
	DPSMateX:WipeInPool(tbl_amount)
	DPSMateX:WipeInPool(tlb_percent)
	strt[1] = ""; strt[2] = ""
	local p = ""
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	local sortedTable, total = DPSMateX.Modules.AbsorbsTaken:GetSortedTable(arr,k)
	for cat, val in pairs(sortedTable) do
		local va, tot, sort, varea, totr, sortr = DPSMateX:FormatNumbers(val[1], total, sortedTable[1][1], k)
		if varea==0 then break end; if totr <= 10000 then pt = "" end; if varea<=10000 then p = "" end
		str[1] = ""; str[2] = ""; str[3] = ""; str[4] = ""
		local pname = DPSMateX:GetUserById(val[2])
		if DPSMateX.Settings["columnsabsorbstaken"][1] then str[1] = " "..DPSMateX:Commas(va, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnsabsorbstaken"][2] then str[2] = " ("..strformat("%.1f", 100*varea/totr).."%)" end
		if DPSMateX.Settings["columnsabsorbstaken"][3] then str[3] = " ("..strformat("%.1f", va/cbt)..p..")" end
		if DPSMateX.Settings["columnsabsorbstaken"][4] then str[4] = " ("..strformat("%.1f", va/(ecbt[pname] or cbt))..p..")" end
		tinsert(tbl_name, pname)
		tinsert(tbl_amount, str[1]..str[3]..str[4]..str[2])
		tinsert(tlb_percent, 100*(varea/sortr))
	end
	return tbl_name, tbl_amount, tlb_percent, strt
end

function DPSMateX.Modules.AbsorbsTaken:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.AbsorbsTaken:EvalTable(DPSMateX.CacheUser[user], k)
		DPSMateX:WipeInPool(tt_ab)
		DPSMateX:WipeInPool(tt_abn)
		local p, i = 1, 1

		while a[i] do
			p = 1
			while c[i][2][p] do
				if tt_ab[c[i][2][p]] then
					tt_ab[c[i][2][p]] = tt_ab[c[i][2][p]] + c[i][3][p][1]
				else
					tt_ab[c[i][2][p]] = c[i][3][p][1]
				end
				p = p + 1
			end
			i = i + 1
		end
		for cat, val in pairs(tt_ab) do
			if val>0 then
				i = 1
				while true do
					if (not tt_abn[i]) then
						tinsert(tt_abn, i, {cat, val})
						break
					else
						if (tt_abn[i][2] < val) then
							tinsert(tt_abn, i, {cat, val})
							break
						end
					end
					i = i + 1
				end
			end
		end

		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabsorbed"]..DPSMateX.L["ttabilities"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not tt_abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(tt_abn[i][1]), tt_abn[i][2].." ("..strformat("%.2f", 100*tt_abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end

		GameTooltip:AddLine(DPSMateX.L["tttop"]..DPSMateX.Settings["subviewrows"]..DPSMateX.L["ttabsorbed"])
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.AbsorbsTaken:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsAbsorbsTaken:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsAbsorbsTaken:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.AbsorbsTaken:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsAbsorbsTakenTotal:UpdateDetails(obj, key)
end

