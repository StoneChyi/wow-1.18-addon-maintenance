DPSMateX.Modules.DetailsAbsorbsTakenTotal = {}

local g
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local strformat = string.format
local toggle = false

function DPSMateX.Modules.DetailsAbsorbsTakenTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)

	DPSMateX_Details_AbsorbsTakenTotal_Title:SetText(DPSMateX.L["absorbstakensum"])
	self:LoadTable()
		DPSMateX_Details_AbsorbsTakenTotal:Show()
	DPSMateX_Details_AbsorbsTakenTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

local pairs = pairs

function DPSMateX.Modules.DetailsAbsorbsTakenTotal:CreateGraphTable()
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 10, 270-i*30, 860, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 40, 260, 40, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 170, 260, 170, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 510, 260, 510, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 570, 260, 570, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 630, 260, 630, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[14] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 690, 260, 690, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[14]:Show()
	
	lines[15] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 750, 260, 750, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[15]:Show()
	
	lines[16] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_AbsorbsTakenTotal_PlayerList, 810, 260, 810, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[16]:Show()
end

function DPSMateX.Modules.DetailsAbsorbsTakenTotal:GetTableValues()
	local arr, total = {}, 0
	local temp = {}
	for cat, val in db do -- 28 Target
		local PerPlayerAbsorb = 0
		local abAbsorb = {}
		local totHits = 0
		local tarname = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, tarname) then
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
						if abAbsorb[DPSMateX.DB.ShieldFlags[shieldname] or 0] then
							abAbsorb[DPSMateX.DB.ShieldFlags[shieldname] or 0] = abAbsorb[DPSMateX.DB.ShieldFlags[shieldname] or 0] + PerAbilityAbsorb
						else
							abAbsorb[DPSMateX.DB.ShieldFlags[shieldname] or 0] = PerAbilityAbsorb
						end
					end
				end
				PerPlayerAbsorb = PerPlayerAbsorb+PerOwnerAbsorb
			end
			if PerPlayerAbsorb>0 then
				if temp[tarname] then
					temp[tarname][2] = temp[tarname][2] + PerPlayerAbsorb
					temp[tarname][3] = temp[tarname][3] + ((abAbsorb[0] or 0)+(abAbsorb[1] or 0))
					temp[tarname][4] = temp[tarname][4] + (abAbsorb[3] or 0)
					temp[tarname][5] = temp[tarname][5] + (abAbsorb[2] or 0)
					temp[tarname][6] = temp[tarname][6] + (abAbsorb[4] or 0)
					temp[tarname][7] = temp[tarname][7] + (abAbsorb[5] or 0)
					temp[tarname][8] = temp[tarname][8] + (abAbsorb[6] or 0)
					temp[tarname][9] = temp[tarname][9] + (abAbsorb[7] or 0)
				else
					temp[tarname] = {tarname, PerPlayerAbsorb, (abAbsorb[0] or 0)+(abAbsorb[1] or 0), abAbsorb[3] or 0, abAbsorb[2] or 0, abAbsorb[4] or 0, abAbsorb[5] or 0, abAbsorb[6] or 0, abAbsorb[7] or 0}
				end
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
	return newArr, total
end

function DPSMateX.Modules.DetailsAbsorbsTakenTotal:RoundToH(val)
	if val>100 then
		return 100
	end
	return val
end

function DPSMateX.Modules.DetailsAbsorbsTakenTotal:CompareVal(x,y)
	if x>y then
		return y
	end
	return x
end

function DPSMateX.Modules.DetailsAbsorbsTakenTotal:LoadTable()
	local arr, total = self:GetTableValues()
	local i = 0
	for i=1, 30 do
		_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..i):Hide()
	end
	for cat, val in arr do
		if DPSMateX.CacheUser[val[1]][4] then
			i=i+1
		else
			if (cat-i)>30 then break end
			local r,g,b = DPSMateX:GetClassColor(DPSMateX.CacheUser[val[1]][2])
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child"):SetHeight((cat-i)*30)
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetText(val[1])
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetTextColor(r,g,b)
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_Amount"):SetText(val[2])
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetValue(100*val[2]/arr[1][2])
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetStatusBarColor(r,g,b, 1)
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_All"):SetText(strformat("%.1f", 100*val[3]/val[2]).."%")
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_FIR"):SetText(strformat("%.1f", 100*val[4]/val[2]).."%")
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_FRR"):SetText(strformat("%.1f", 100*val[5]/val[2]).."%")
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_NAR"):SetText(strformat("%.1f", 100*val[6]/val[2]).."%")
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_SHR"):SetText(strformat("%.1f", 100*val[7]/val[2]).."%")
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i).."_ARR"):SetText(strformat("%.1f", 100*val[8]/val[2]).."%")
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i)).user = val[1]
			_G("DPSMateX_Details_AbsorbsTakenTotal_PlayerList_Child_R"..(cat-i)):Show()
		end
	end
end

function DPSMateX.Modules.DetailsAbsorbsTakenTotal:ShowTooltip(user, obj)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.AbsorbsTaken, DPSMateX.CacheUser[user], curKey)
	local pet = ""
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(user.."'s "..strlower(DPSMateX.L["absorbeddmg"]), 1,1,1)
	for i=1, DPSMateX.Settings["subviewrows"] do
		if not a[i] then break end
		GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%2.f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		for p=1, 3 do
			if not c[i][2][p] then break end
			GameTooltip:AddDoubleLine("      "..p..". "..DPSMateX:GetAbilityById(c[i][2][p]),c[i][3][p][1].." ("..strformat("%.2f", 100*c[i][3][p][1]/c[i][1]).."%)",0.5,0.5,0.5,0.5,0.5,0.5)
		end
	end
	GameTooltip:Show()
end
