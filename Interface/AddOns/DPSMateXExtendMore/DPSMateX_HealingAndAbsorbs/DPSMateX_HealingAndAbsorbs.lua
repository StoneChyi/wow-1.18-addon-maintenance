local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.HealingAndAbsorbs = {}
DPSMateX.Modules.HealingAndAbsorbs.Hist = "Absorbs"
DPSMateX.Options.Options[1]["args"]["healingandabsorbs"] = {
	order = 130,
	type = 'toggle',
	name = DPSMateX.L["healingandabsorbs"],
	desc = DPSMateX.L["show"].." "..DPSMateX.L["healingandabsorbs"]..".",
	get = function() return DPSMateX.Settings["windows"][DPSMateX.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["healingandabsorbs"] end,
	set = function() DPSMateX.Options:ToggleDrewDrop(1, "healingandabsorbs", DPSMateX.Options.Dewdrop:GetOpenedParent()) end,
}
DPSMateX.Modules.HealingAndAbsorbs.Events = {
	-- Healing/Absorbs/Fail/DeathHistory/Dispels
	"CHAT_MSG_SPELL_SELF_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
	"CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
	"CHAT_MSG_SPELL_HOSTILEPLAYER_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_BUFFS",
	"CHAT_MSG_SPELL_PARTY_BUFF",
	"CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
	
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
DPSMateX:Register("healingandabsorbs", DPSMateX.Modules.HealingAndAbsorbs, DPSMateX.L["healingandabsorbs"])

local tinsert = table.insert
local strformat = string.format

local pairs = pairs
function DPSMateX.Modules.HealingAndAbsorbs:GetSortedTable(arr, k)
	local b, a, total = {}, {}, 0
	local f, g, h = {}, {}, {}
	local temp = {}
	if arr then
		for cat, val in pairs(arr) do -- 28 Target
			local PerPlayerAbsorb = 0
			for ca, va in pairs(val) do -- 28 Owner
				local ownername = DPSMateX:GetUserById(ca)
				if DPSMateX:ApplyFilter(k, ownername) then
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
												if DPSMateX.DBCache.DamageTaken[1][cat][cet] then
													if DPSMateX.DBCache.DamageTaken[1][cat][cet][qq] then
														if DPSMateX.DBCache.DamageTaken[1][cat][cet][qq][14]~=0 then
															p=ceil(DPSMateX.DBCache.DamageTaken[1][cat][cet][qq][14])
														end
													end
												end
											elseif DPSMateX.DBCache.EDT[1][cat] then
												if DPSMateX.DBCache.EDT[1][cat][cet] then
													if DPSMateX.DBCache.EDT[1][cat][cet][qq] then
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
					if b[ca] then
						b[ca] = b[ca] + PerOwnerAbsorb
					else
						b[ca] = PerOwnerAbsorb
					end
				end
			end
			total = total+PerPlayerAbsorb
		end
		
		-- Evaluate E Healing table
		local d, total2 = {}, 0
		local arr = DPSMateX:GetModeByArr(DPSMateX.DBCache.EHealing, k, "EHealing")
		for c, v in pairs(arr) do
			if DPSMateX:ApplyFilter(k, DPSMateX:GetUserById(c)) then
				d[c] = v["i"]
				total2 = total2 + v["i"]
			end
		end
		
		-- Merge tables
		total=total+total2
		for cat, val in b do
			g[cat] = val
			--if d[cat] then g[cat] = g[cat] + d[cat] end
		end
		for cat, val in d do
			if g[cat] then
				g[cat] = g[cat] + val
			else
				g[cat] = val
			end
			--if b[cat] then g[cat] = g[cat] + b[cat] end
		end
		for cat, val in g do
			local i = 1
			while true do
				if (not f[i]) then
					tinsert(f, i, val)
					tinsert(h, i, cat)
					break
				else
					if f[i] < val then
						tinsert(f, i, val)
						tinsert(h, i, cat)
						break
					end
				end
				i=i+1
			end
		end
	end
	return f, total, h
end

function DPSMateX.Modules.HealingAndAbsorbs:EvalTable(user, k)
	local b, total = {}, 0
	local temp = {}
	local arr = DPSMateX:GetModeByArr(DPSMateX.DBCache.Absorbs, k, "Absorbs")
	local ownername = DPSMateX:GetUserById(user[1])
	for cat, val in pairs(arr) do -- 28 Target
		for ca, va in pairs(val) do -- 28 Owner
			if ca==user[1] then
				for c, v in pairs(va) do -- Power Word: Shield
					if c~="i" then
						local shieldname = DPSMateX:GetAbilityById(c)
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
											if DPSMateX.DBCache.DamageTaken[1][cat][cet] then
												if DPSMateX.DBCache.DamageTaken[1][cat][cet][qq] then
													if DPSMateX.DBCache.DamageTaken[1][cat][cet][qq][14]~=0 then
														p=ceil(DPSMateX.DBCache.DamageTaken[1][cat][cet][qq][14])
													end
												end
											end
										elseif DPSMateX.DBCache.EDT[1][cat] then
											if DPSMateX.DBCache.EDT[1][cat][cet] then
												if DPSMateX.DBCache.EDT[1][cat][cet][qq] then
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
										if not temp[cet] then temp[cet] = {} end
										if not temp[cet][qq] then temp[cet][qq] = ss*p else temp[cet][qq] =temp[cet][qq]+ss*p end
									end
								end
							end
							if ve["i"][1]==1 then
								PerShieldAbsorb=PerShieldAbsorb+ve["i"][2]
							end
							if b[c] then b[c]=b[c]+PerShieldAbsorb else b[c]=PerShieldAbsorb end
						end
					end
				end
				break
			end
		end
	end
	
	-- Evaluate E Healing table
	local d = {}
	local arr = DPSMateX:GetModeByArr(DPSMateX.DBCache.EHealing, k, "EHealing")
	if arr[user[1]] then
		for c, v in pairs(arr[user[1]]) do
			if c~="i" then
				if d[c] then d[c]=d[c]+v[1] else d[c]=v[1] end
			end
		end
	end
	
	-- Merge tables
	local f, h = {}, {}
	for cat, val in pairs(d) do
		local i = 1
		while true do
			if (not f[i]) then
				tinsert(f, i, {val, false})
				tinsert(h, i, cat)
				break
			else
				if f[i][1] < val then
					tinsert(f, i, {val, false})
					tinsert(h, i, cat)
					break
				end
			end
			i=i+1
		end
		total=total+val
	end
	

	for cat, val in pairs(b) do
		local i = 1
		while true do
			if (not f[i]) then
				tinsert(f, i, {val, true})
				tinsert(h, i, cat)
				break
			else
				if f[i][1] < val then
					tinsert(f, i, {val, true})
					tinsert(h, i, cat)
					break
				end
			end
			i=i+1
		end
		total=total+val
	end
	return h, total, f
end

function DPSMateX.Modules.HealingAndAbsorbs:GetSettingValues(arr, cbt, k,ecbt)
	local pt = ""
	local name, value, perc, sortedTable, total, a, p, strt = {}, {}, {}, {}, 0, 0, "", {[1]="",[2]=""}
	if DPSMateX.Settings["windows"][k]["numberformat"] == 2 or DPSMateX.Settings["windows"][k]["numberformat"] == 4 then p = "K"; pt = "K" end
	sortedTable, total, a = DPSMateX.Modules.HealingAndAbsorbs:GetSortedTable(arr, k)
	for cat, val in pairs(sortedTable) do
		local va, tot, sort, varea, totr, sortr = DPSMateX:FormatNumbers(val, total, sortedTable[1], k)
		if varea==0 then break end; if totr <= 10000 then pt = "" end; if varea<=10000 then p = "" end
		local str = {[1]="",[2]="",[3]="",[4]=""}
		local pname = DPSMateX:GetUserById(a[cat])
		if DPSMateX.Settings["columnshab"][1] then str[1] = " "..DPSMateX:Commas(va, k)..p; strt[2] = DPSMateX:Commas(tot, k)..pt end
		if DPSMateX.Settings["columnshab"][3] then str[2] = " ("..strformat("%.1f", 100*varea/totr).."%)" end
		if DPSMateX.Settings["columnshab"][2] then str[3] = "("..strformat("%.1f", va/cbt)..")"; strt[1] = "("..strformat("%.1f", (tot/cbt))..pt..")" end
		if DPSMateX.Settings["columnshab"][4] then str[4] = " ("..strformat("%.1f", va/(ecbt[pname] or cbt))..p..")" end
		tinsert(name, pname) 
		tinsert(value, str[3]..str[1]..str[4]..str[2])
		tinsert(perc, 100*(varea/sortr))
	end
	return name, value, perc, strt
end

function DPSMateX.Modules.HealingAndAbsorbs:ShowTooltip(user, k)
	if DPSMateX.Settings["informativetooltips"] then
		local a,b,c = DPSMateX.Modules.HealingAndAbsorbs:EvalTable(DPSMateX.CacheUser[user], k)
		local db = DPSMateX:GetModeByArr(DPSMateX.DBCache.EHealingTaken, k, "EHealingTaken")
		local abn, p, i = {}, 1, 1
		
		for cat, val in pairs(db) do
			if val[DPSMateX.CacheUser[user][1]] then
				p = 0
				for _, va in pairs(val[DPSMateX.CacheUser[user][1]]) do
					p = p + va[1]
				end
				if p>0 then
					i = 1
					while true do
						if (not abn[i]) then
							tinsert(abn, i, {cat, p})
							break
						else
							if (abn[i][2] < p) then
								tinsert(abn, i, {cat, p})
								break
							end
						end
						i = i + 1
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
			if not abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(abn[i][1]), abn[i][2].." ("..strformat("%.2f", 100*abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end
	end
end

function DPSMateX.Modules.HealingAndAbsorbs:OpenDetails(obj, key, bool)
	if bool then
		DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateCompare(obj, key, bool)
	else
		DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateDetails(obj, key)
	end
end

function DPSMateX.Modules.HealingAndAbsorbs:OpenTotalDetails(obj, key)
	DPSMateX.Modules.DetailsHABTotal:UpdateDetails(obj, key)
end


