local DPSMateX = DPSMateX
DPSMateX.Modules.DetailsFFTTotal = {}

local g
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local strformat = string.format
local toggle = false

function DPSMateX.Modules.DetailsFFTTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)

	if not self.compactTableInitialized then
		self.compactTableInitialized = true
		DPSMateX.Modules.DetailsFFTTotal:CreateGraphTable()
	end
	DPSMateX_Details_FFTTotal_Title:SetText(DPSMateX.L["fftsum"])
	self:LoadTable()
		DPSMateX_Details_FFTTotal:Show()
	DPSMateX_Details_FFTTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

local pairs = pairs

function DPSMateX.Modules.DetailsFFTTotal:CreateGraphTable()
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_FFTTotal_PlayerList, 10, 270-i*30, 860, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_FFTTotal_PlayerList, 40, 260, 40, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_FFTTotal_PlayerList, 170, 260, 170, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_FFTTotal_PlayerList, 540, 260, 540, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_FFTTotal_PlayerList, 600, 260, 600, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_FFTTotal_PlayerList, 660, 260, 660, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[13] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_FFTTotal_PlayerList, 740, 260, 740, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
end

function DPSMateX.Modules.DetailsFFTTotal:GetTableValues()
	local total = 0
	local temp = {}
	for cat, val in db do
		local crit, totCrit, miss, totMiss, time, last = 0, 0.000001, 0, 0.000001, 0, 0
		local name = DPSMateX:GetUserById(cat)
		for q, s in val do
			local CV = 0
			local catName = DPSMateX:GetUserById(q)
			if DPSMateX:ApplyFilter(curKey, catName) and  DPSMateX.CacheUser[catName] and  DPSMateX.CacheUser[name] then
				if DPSMateX.CacheUser[name][3] == DPSMateX.CacheUser[catName][3] and DPSMateX.CacheUser[catName][3] and DPSMateX.CacheUser[name][3] then
					for ca, va in s do
						if ca~="i" then
							totCrit=totCrit+va[1]+va[5]+va[9]+va[10]+va[11]+va[12]+va[14]
							crit=crit+va[5]
							totMiss=totMiss+va[1]+va[5]+va[9]+va[10]+va[11]+va[12]+va[14]
							miss=miss+va[9]+va[10]+va[11]+va[12]
							CV = CV + va[13]
						end
					end
					
					if temp[cat] then
						temp[cat][2] = temp[cat][2] + CV
						temp[cat][3] = temp[cat][3] + crit
						temp[cat][4] = temp[cat][4] + miss
						temp[cat][6] = temp[cat][6] + totCrit
						temp[cat][7] = temp[cat][7] + totMiss
					else
						temp[cat] = {name, CV, crit, miss, 0, totCrit, totMiss, cat}
					end
					total = total + CV
				end
			end
		end
	end
	local newArr = {}
	for cat, val in temp do
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

function DPSMateX.Modules.DetailsFFTTotal:RoundToH(val)
	if val>100 then
		return 100
	end
	return val
end

function DPSMateX.Modules.DetailsFFTTotal:CompareVal(x,y)
	if x>y then
		return y
	end
	return x
end

function DPSMateX.Modules.DetailsFFTTotal:LoadTable()
	local arr, total = self:GetTableValues()
	local i = 0
	for i=1, 30 do
		_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..i):Hide()
	end
	for cat, val in arr do
		if DPSMateX.CacheUser[val[1]][4] then
			i=i+1
		else
			if (cat-i)>30 then break end
			local r,g,b = DPSMateX:GetClassColor(DPSMateX.CacheUser[val[1]][2])
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child"):SetHeight((cat-i)*DPSMateX.DetailLayout.tableRowHeight)
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetText(val[1])
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetTextColor(r,g,b)
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_Amount"):SetText(val[2])
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetValue(100*val[2]/arr[1][2])
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetStatusBarColor(r,g,b, 1)
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_Crit"):SetText(strformat("%.1f", 100*val[3]/val[6]).."%")
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_Miss"):SetText(strformat("%.1f", 100*val[4]/val[7]).."%")
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_DPS"):SetText(strformat("%.1f", val[2]/cbt))
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i).."_ActiveTime"):SetText(self:CompareVal(ceil(val[5]), ceil(cbt)).."s | "..strformat("%.1f", self:RoundToH(100*val[5]/cbt)).."%")
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i)).user = val[8]
			_G("DPSMateX_Details_FFTTotal_PlayerList_Child_R"..(cat-i)):Show()
		end
	end
end

function DPSMateX.Modules.DetailsFFTTotal:ShowTooltip(user, obj)
	local name = DPSMateX:GetUserById(user)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.FriendlyFireTaken, DPSMateX.CacheUser[name], curKey)
	local pet = ""
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(name.."'s "..strlower(DPSMateX.L["damagetaken"]), 1,1,1)
	for i=1, DPSMateX.Settings["subviewrows"] do
		if not a[i] then break end
		GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		for p=1, 3 do 
			if not c[i][2][p] or c[i][3][p]==0 then break end
			GameTooltip:AddDoubleLine("       "..p..". "..DPSMateX:GetAbilityById(c[i][2][p]),c[i][3][p].." ("..strformat("%.2f", 100*c[i][3][p]/c[i][1]).."%)",0.5,0.5,0.5,0.5,0.5,0.5)
		end
	end
	GameTooltip:Show()
end
