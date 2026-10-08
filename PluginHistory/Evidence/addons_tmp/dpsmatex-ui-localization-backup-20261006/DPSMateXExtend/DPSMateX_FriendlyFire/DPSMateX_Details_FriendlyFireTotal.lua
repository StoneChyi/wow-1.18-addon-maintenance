local DPSMateX = DPSMateX
DPSMateX.Modules.DetailsFFTotal = {}

local g
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local strformat = string.format
local toggle = false

function DPSMateX.Modules.DetailsFFTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)

	if not self.compactTableInitialized then
		self.compactTableInitialized = true
		DPSMateX.Modules.DetailsFFTotal:CreateGraphTable()
	end
	DPSMateX_Details_FFTotal_Title:SetText(DPSMateX.L["ffsum"])
	self:LoadTable()
		DPSMateX_Details_FFTotal:Show()
	DPSMateX_Details_FFTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

local pairs = pairs

function DPSMateX.Modules.DetailsFFTotal:CreateGraphTable()
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_FFTotal_PlayerList, 10, 270-i*30, 860, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_FFTotal_PlayerList, 40, 260, 40, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_FFTotal_PlayerList, 170, 260, 170, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_FFTotal_PlayerList, 540, 260, 540, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_FFTotal_PlayerList, 600, 260, 600, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_FFTotal_PlayerList, 660, 260, 660, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_FFTotal_PlayerList, 740, 260, 740, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
end

function DPSMateX.Modules.DetailsFFTotal:GetTableValues()
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
					
					if temp[q] then
						temp[q][2] = temp[q][2] + CV
						temp[q][3] = temp[q][3] + crit
						temp[q][4] = temp[q][4] + miss
						temp[q][6] = temp[q][6] + totCrit
						temp[q][7] = temp[q][7] + totMiss
					else
						temp[q] = {catName, CV, crit, miss, 0, totCrit, totMiss, q}
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

function DPSMateX.Modules.DetailsFFTotal:RoundToH(val)
	if val>100 then
		return 100
	end
	return val
end

function DPSMateX.Modules.DetailsFFTotal:CompareVal(x,y)
	if x>y then
		return y
	end
	return x
end

function DPSMateX.Modules.DetailsFFTotal:LoadTable()
	local arr, total = self:GetTableValues()
	local i = 0
	for i=1, 30 do
		_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..i):Hide()
	end
	for cat, val in arr do
		if DPSMateX.CacheUser[val[1]][4] then
			i=i+1
		else
			if (cat-i)>30 then break end
			local r,g,b = DPSMateX:GetClassColor(DPSMateX.CacheUser[val[1]][2])
			_G("DPSMateX_Details_FFTotal_PlayerList_Child"):SetHeight((cat-i)*30)
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetText(val[1])
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetTextColor(r,g,b)
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_Amount"):SetText(val[2])
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetValue(100*val[2]/arr[1][2])
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetStatusBarColor(r,g,b, 1)
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_Crit"):SetText(strformat("%.1f", 100*val[3]/val[6]).."%")
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_Miss"):SetText(strformat("%.1f", 100*val[4]/val[7]).."%")
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_DPS"):SetText(strformat("%.1f", val[2]/cbt))
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i).."_ActiveTime"):SetText(self:CompareVal(ceil(val[5]), ceil(cbt)).."s | "..strformat("%.1f", self:RoundToH(100*val[5]/cbt)).."%")
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i)).user = val[8]
			_G("DPSMateX_Details_FFTotal_PlayerList_Child_R"..(cat-i)):Show()
		end
	end
end

function DPSMateX.Modules.DetailsFFTotal:ShowTooltip(user, obj)
	local name = DPSMateX:GetUserById(user)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.FriendlyFire, DPSMateX.CacheUser[name], curKey)
	local pet = ""
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(name.."'s "..strlower(DPSMateX.L["damagedone"]), 1,1,1)
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
