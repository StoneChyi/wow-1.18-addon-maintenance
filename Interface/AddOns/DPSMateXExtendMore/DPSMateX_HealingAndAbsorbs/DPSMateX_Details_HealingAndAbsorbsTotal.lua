local DPSMateX = DPSMateX
DPSMateX.Modules.DetailsHABTotal = {}

local g
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local strformat = string.format
local toggle = false

function DPSMateX.Modules.DetailsHABTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)

	if not self.compactTableInitialized then
		self.compactTableInitialized = true
		DPSMateX.Modules.DetailsHABTotal:CreateGraphTable()
	end
	DPSMateX_Details_HABTotal_Title:SetText(DPSMateX.L["habsum"])
	self:LoadTable()
		DPSMateX_Details_HABTotal:Show()
	DPSMateX_Details_HABTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

local pairs = pairs

function DPSMateX.Modules.DetailsHABTotal:CreateGraphTable()
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_HABTotal_PlayerList, 10, 270-i*30, 860, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_HABTotal_PlayerList, 40, 260, 40, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_HABTotal_PlayerList, 170, 260, 170, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_HABTotal_PlayerList, 540, 260, 540, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_HABTotal_PlayerList, 600, 260, 600, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_HABTotal_PlayerList, 660, 260, 660, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[13] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_HABTotal_PlayerList, 740, 260, 740, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
end

function DPSMateX.Modules.DetailsHABTotal:GetTableValues()
	local arr, total = {}, 0
	for cat, val in DPSMateX.DBCache.EHealing[curKey] do
		local name = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, name) then
			local crit, totCrit, miss, totMiss, time, last = 0, 0.000001, 0, 0.000001, 0, 0
			for ca, va in val do
				if ca~="i" then
					totCrit=totCrit+va[3]+va[2]
					totMiss=totMiss+va[2]+va[3]
					crit=crit+va[3]
					miss=miss+va[2]
				else
					time = tonumber(strformat("%.2f", DPSMateX.CombatTime["effective"][curKey][name] or 0))
				end
			end
			tinsert(arr, {name, val["i"], crit, miss, time, totCrit, totMiss, cat})
			total = total + val["i"]
		end
	end
	
	local temp = {}
	for cat, val in db do -- 28 Target
		local PerPlayerAbsorb = 0
		local totHits = 0
		for ca, va in pairs(val) do -- 28 Owner
			local ownername = DPSMateX:GetUserById(ca)
			if DPSMateX:ApplyFilter(curKey, ownername) then
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
									totHits = totHits + totalHits
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
				if temp[ownername] then
					temp[ownername][2] = temp[ownername][2] + PerOwnerAbsorb
					temp[ownername][4] = temp[ownername][4] + totHits
					temp[ownername][6] = temp[ownername][6] + totHits
					temp[ownername][7] = temp[ownername][7] + totHits
				else
					temp[ownername] = {ownername, PerOwnerAbsorb, 0, totHits, DPSMateX.CombatTime["effective"][curKey][ownername] or 0, totHits, totHits, ca}
				end
			end
		end
	end
	
	-- Merging!
	for ca, va in temp do
		for c, v in arr do
			if v[1]==ca and temp[ca] then
				arr[c][2] = arr[c][2] + va[2]
				arr[c][4] = arr[c][4] + va[4]
				arr[c][6] = arr[c][6] + va[4]
				arr[c][7] = arr[c][7] + va[4]  
				total = total + va[2]
				temp[ca] = nil
			end
		end
	end
	
	for ca, va in temp do
		if va then
			tinsert(arr, va)
			total = total + va[2]
		end
	end
	temp = nil
	
	local newArr = {}
	for cat, val in arr do
		if val[2]>0 then
			local i = 1
			while true do
				if (not newArr[i]) then
					tinsert(newArr, i, val)
					break
				else
					if newArr[i][2] < val[2] then
						tinsert(newArr, i, val)
						break
					end
				end
				i=i+1
			end
		end
	end
	return newArr, total
end

function DPSMateX.Modules.DetailsHABTotal:RoundToH(val)
	if val>100 then
		return 100
	end
	return val
end

function DPSMateX.Modules.DetailsHABTotal:CompareVal(x,y)
	if x>y then
		return y
	end
	return x
end

function DPSMateX.Modules.DetailsHABTotal:LoadTable()
	local arr, total = self:GetTableValues()
	local i = 0
	for i=1, 30 do
		_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..i):Hide()
	end
	for cat, val in arr do
		if DPSMateX.CacheUser[val[1]][4] then
			i=i+1
		else
			if (cat-i)>30 then break end
			local r,g,b = DPSMateX:GetClassColor(DPSMateX.CacheUser[val[1]][2])
			_G("DPSMateX_Details_HABTotal_PlayerList_Child"):SetHeight((cat-i)*DPSMateX.DetailLayout.tableRowHeight)
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetText(val[1])
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetTextColor(r,g,b)
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_Amount"):SetText(val[2])
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetValue(100*val[2]/arr[1][2])
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetStatusBarColor(r,g,b, 1)
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_Crit"):SetText(strformat("%.1f", 100*val[3]/val[6]).."%")
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_Hit"):SetText(strformat("%.1f", 100*val[4]/val[7]).."%")
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_HPS"):SetText(strformat("%.1f", val[2]/cbt))
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i).."_ActiveTime"):SetText(self:CompareVal(ceil(val[5]), ceil(cbt)).."s | "..strformat("%.1f", self:RoundToH(100*val[5]/cbt)).."%")
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i)).user = val[8]
			_G("DPSMateX_Details_HABTotal_PlayerList_Child_R"..(cat-i)):Show()
		end
	end
end

function DPSMateX.Modules.DetailsHABTotal:ShowTooltip(user, obj)
	local name = DPSMateX:GetUserById(user)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.HealingAndAbsorbs, DPSMateX.CacheUser[name], curKey)
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(name.."'s "..strlower(DPSMateX.L["tehealing"]), 1,1,1)
	if DPSMateX.Settings["informativetooltips"] then
		for i=1, DPSMateX.Settings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
	GameTooltip:Show()
end
