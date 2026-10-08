local DPSMateX = DPSMateX
DPSMateX.Modules.DetailsDamageTotal = {}

local g, g2 = nil,nil
local curKey = 1
local db, cbt = {}, 0
local buttons = {}
local ColorTable={}
local _G = getglobal
local tinsert = table.insert
local tremove = table.remove
local strformat = string.format
local toggle = false
local totSumTable = {}
local totMax = 0
local totTime = 0

function DPSMateX.Modules.DetailsDamageTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	buttons = {}
	ColorTable={
		{0.95,0.90,0.5},
		{0.0,0.9,0.0},
		{0.0,0.0,1.0},
		{1.0,1.0,0.0},
		{1.0,0.0,1.0},
		{0.0,1.0,1.0},
		{1.0,1.0,1.0},
		{0.5,0.0,0.0},
		{0.0,0.5,0.0},
		{0.0,0.0,0.5},
		{0.5,0.5,0.0},
		{0.5,0.0,0.5},
		{0.0,0.5,0.5},
		{0.5,0.5,0.5},
		{0.75,0.25,0.25},
		{0.25,0.75,0.25},
		{0.25,0.25,0.75},
		{0.75,0.75,0.25},
		{0.75,0.25,0.75},
		{0.25,0.75,0.75},
		{1.0,0.5,0.0},	
		{0.0,0.5,1.0},
		{1.0,0.0,0.5},
		{0.5,1.0,0.0},
		{0.5,0.0,1.0},
		{0.0,1.0,0.5},
		{0.0,0.25,0.5},
		{0.25,0,0.5},
		{0.5,0.25,0.0},
		{0.5,0.0,0.25},
		{0.5,0.75,0.0},
		{0.5,0.0,0.75},
		{0.0,0.75,0.5},
		{0.75,0.0,0.5},
	}
	if not g then
		g=DPSMateX.Options.graph:CreateGraphLine("DMGDTLineGraph",DPSMateX_Details_DamageTotal_DiagramLine,"CENTER","CENTER",0,0,740,220)
		g2=DPSMateX.Options.graph:CreateStackedGraph("DMGDTStackedGraph",DPSMateX_Details_DamageTotal_DiagramLine,"CENTER","CENTER",0,0,850,220)
		g2:SetGridColor({0.5,0.5,0.5,0.5})
		g2:SetAxisDrawing(true,true)
		g2:SetAxisColor({1.0,1.0,1.0,1.0})
		g2:SetAutoScale(true)
		g2:SetYLabels(true, false)
		g2:SetXLabels(true)
		g2:Hide()
		DPSMateX.Modules.DetailsDamageTotal:CreateGraphTable()
	end
	DPSMateX_Details_DamageTotal_PlayerList_CB:SetChecked(false)
	DPSMateX_Details_DamageTotal_PlayerList_CB.act = false
	DPSMateX_Details_DamageTotal_Title:SetText(DPSMateX.L["dmgdonesum"])
	self:LoadTable()
	self:LoadLegendButtons()
	if toggle then
		self:UpdateStackedGraph()
	else
		self:UpdateLineGraph()
	end
	DPSMateX_Details_DamageTotal:Show()
	DPSMateX_Details_DamageTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

local pairs = pairs
function DPSMateX.Modules.DetailsDamageTotal:UpdateLineGraph()	
	g:ResetData()
	g:SetGridColor({0.5,0.5,0.5,0.5})
	g:SetAxisDrawing(true,true)
	g:SetAxisColor({1.0,1.0,1.0,1.0})
	g:SetAutoScale(true)
	g:SetYLabels(true, false)
	g:SetXLabels(true)
	g2:Hide()
	DPSMateX_Details_DamageTotal_DiagramLine:SetWidth(770)
	DPSMateX_Details_DamageTotal_DiagramLegend:Show()
	g:Show()
	toggle=false
	self:AddTotalDataSeries()
	local Max = totMax
	for cat, val in pairs(buttons) do		
		g:AddDataSeries(val[3], {val[1], {}}, {})
		local temp = DPSMateX:GetMaxValue(val[3], 2)
		if temp>Max then
			Max = temp
		end
	end
	g:SetGridSpacing(totTime/10,Max/7)
end

function DPSMateX.Modules.DetailsDamageTotal:UpdateStackedGraph()
	g:Hide()
	DPSMateX_Details_DamageTotal_DiagramLine:SetWidth(870)
	DPSMateX_Details_DamageTotal_DiagramLegend:Hide()
	
	local Data1 = {}
	local label = {}
	local maxX, maxY = 0,0
	local p = {}
	for cat, val in db do
		local temp = {}
		local user =DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, user) then
			for ca, va in val do
				if ca~="i" then
					for c,v in va["i"] do
						local i = 1
						while true do
							if not temp[i] then
								tinsert(temp, i, {c,v})
								break
							elseif c<=temp[i][1] then
								tinsert(temp, i, {c,v})
								break
							end
							i=i+1
						end
						if p[c] then
							p[c] = p[c] + v
						else
							p[c] = v
						end
						if maxX == 0 or maxX<c then
							maxX = c
						end
					end
				end
			end
			tinsert(label, 1, user)
			tinsert(Data1, 1, temp)
		end
	end
	for cat, val in p do
		if maxY<val then
			maxY = val
		end
	end
	
	g2:ResetData()
	g2:SetGridSpacing(maxX/7,(maxY/2)/14)
	
	g2:AddDataSeries(Data1,{1.0,0.0,0.0,0.8}, {}, label)
	g2:Show()
	toggle=true
end

function DPSMateX.Modules.DetailsDamageTotal:ToggleMode()
	if toggle then
		self:UpdateLineGraph()
		toggle=false
	else
		self:UpdateStackedGraph()
		toggle=true
	end
end

function DPSMateX.Modules.DetailsDamageTotal:GetSummarizedTable(arr)
	return DPSMateX.Sync:GetSummarizedTable(arr)
end

function DPSMateX.Modules.DetailsDamageTotal:CreateGraphTable()
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_DamageTotal_PlayerList, 10, 270-i*30, 860, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_DamageTotal_PlayerList, 40, 260, 40, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_DamageTotal_PlayerList, 170, 260, 170, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_DamageTotal_PlayerList, 540, 260, 540, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_DamageTotal_PlayerList, 600, 260, 600, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_DamageTotal_PlayerList, 660, 260, 660, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_DamageTotal_PlayerList, 740, 260, 740, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
end

function DPSMateX.Modules.DetailsDamageTotal:AddTotalDataSeries()
	local sumTable, newArr = {[0]=0}, {}
	
	local temp = {}
	for cat, val in db do
		local user = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, user) then
			temp[user] = true
			for ca, va in val do
				if ca~="i" and va["i"] then
					for c,v in va["i"] do
						if sumTable[c] then
							sumTable[c] = sumTable[c] + v
						else
							sumTable[c] = v
						end
					end
				end
			end
		end
	end
	
	local tl = DPSMateX:TableLength(temp)
	tl = ceil(tl-0.3*tl)
	
	for cat, val in sumTable do
		local i=1
		while true do
			if (not newArr[i]) then 
				tinsert(newArr, i, {cat, val/tl})
				break
			end
			if cat<newArr[i][1] then
				tinsert(newArr, i, {cat, val/tl})
				break
			end
			i=i+1
		end
	end
	
	totSumTable = self:GetSummarizedTable(newArr)
	
	totMax = DPSMateX:GetMaxValue(totSumTable, 2)
	totTime = DPSMateX:GetMaxValue(totSumTable, 1)
	g:SetXAxis(0,totTime)
	g:SetYAxis(0,totMax)
	g:SetGridSpacing(totTime/10,totMax/7)
	
	g:AddDataSeries(totSumTable,{{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}, {})
end

function DPSMateX.Modules.DetailsDamageTotal:GetTableValues()
	local arr, total = {}, 0
	for cat, val in db do
		local name = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, name) then
			local crit, totCrit, miss, totMiss, time, last = 0, 0.000001, 0, 0.000001, 0, 0
			for ca, va in val do
				if ca~="i" then
					totCrit=totCrit+va[1]+va[5]+va[9]+va[10]+va[11]+va[12]+va[14]
					crit=crit+va[5]
					totMiss=totMiss+va[1]+va[5]+va[9]+va[10]+va[11]+va[12]+va[14]
					miss=miss+va[9]+va[10]+va[11]+va[12]
				else
					time = tonumber(strformat("%.2f", DPSMateX:GetSelectedEffectiveTime(curKey)[name] or 0))
				end
			end
			tinsert(arr, {name, val["i"], crit, miss, time, totCrit, totMiss, cat})
			total = total + val["i"]
		end
	end
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

function DPSMateX.Modules.DetailsDamageTotal:CheckButtonCheckAll(obj)
	if obj.act then
		obj.act = false
		for i=1, 30 do 
			local ob = _G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..i)
			if ob.user then
				self:RemoveLinesButton(ob.user, ob)
				_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..i.."_CB"):SetChecked(obj.act)
			end
		end
	else
		obj.act = true
		for i=1, 30 do 
			local ob = _G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..i)
			if ob.user then
				self:RemoveLinesButton(ob.user, ob)
				self:AddLinesButton(ob.user, ob)
				_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..i.."_CB"):SetChecked(obj.act)
			end
		end
	end
end

function DPSMateX.Modules.DetailsDamageTotal:SortLineTable(uid)
	local user = DPSMateX:GetUserById(uid)
	local newArr = {}
	-- user
	for cat, val in db[DPSMateX.CacheUser[user][1]] do
		if cat~="i" and val["i"] then
			for c,v in val["i"] do
				local i = 1
				while true do
					if not newArr[i] then
						tinsert(newArr, i, {c,v})
						break
					elseif c<=newArr[i][1] then
						tinsert(newArr, i, {c,v})
						break
					end
					i = i+1
				end
			end
		end
	end
	-- Pet
	local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[user])
	if petsname and DPSMateX.Settings["mergepets"] then
		for petname, _ in pairs(petsname) do
			if petname ~=user then
				local PetId = DPSMateX.CacheUser[petname][1]
				if db[PetId] then
					for cat, val in db[PetId] do
						if cat~="i" and val["i"] then
							for c,v in val["i"] do
								local i = 1
								while true do
									if not newArr[i] then
										tinsert(newArr, i, {c,v})
										break
									elseif c<=newArr[i][1] then
										tinsert(newArr, i, {c,v})
										break
									end
									i = i+1
								end
							end
						end
					end
				end
			end
		end
	end
	return newArr
end

function DPSMateX.Modules.DetailsDamageTotal:AddLinesButton(uid, obj)
	local sumTable = self:SortLineTable(uid)
	
	sumTable = self:GetSummarizedTable(sumTable)
	
	local Max = DPSMateX:GetMaxValue(sumTable, 2)
	if Max > totMax then
		g:SetGridSpacing(totTime/10,Max/7)
	end
	
	g:AddDataSeries(sumTable, {ColorTable[1], {}}, {})
	tinsert(buttons, {ColorTable[1], uid, sumTable})
	tremove(ColorTable, 1)
	g2:Hide()
	DPSMateX_Details_DamageTotal_DiagramLine:SetWidth(770)
	DPSMateX_Details_DamageTotal_DiagramLegend:Show()
	g:Show()
	toggle=false
	obj.act = true
	self:LoadLegendButtons()
end

function DPSMateX.Modules.DetailsDamageTotal:RemoveLinesButton(uid, obj)
	obj.act = false
	g:ResetData()
	for cat, val in pairs(buttons) do
		if val[2]==uid then
			tinsert(ColorTable, 1, val[1])
			tremove(buttons, cat)
			break
		end
	end
	
	local Max = totMax
	g:AddDataSeries(totSumTable,{{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}, {})
	for cat, val in pairs(buttons) do		
		g:AddDataSeries(val[3], {val[1], {}}, {})
		local temp = DPSMateX:GetMaxValue(val[3], 2)
		if temp>Max then
			Max = temp
		end
	end
	g:SetGridSpacing(totTime/10,Max/7)
	g2:Hide()
	DPSMateX_Details_DamageTotal_DiagramLine:SetWidth(770)
	DPSMateX_Details_DamageTotal_DiagramLegend:Show()
	g:Show()
	toggle = false
	self:LoadLegendButtons()
end

function DPSMateX.Modules.DetailsDamageTotal:LoadLegendButtons()
	for i=1, 30 do
		_G("DPSMateX_Details_DamageTotal_DiagramLegend_Child_C"..i):Hide()
	end
	for cat, val in buttons do
		local name = DPSMateX:GetUserById(val[2])
		local font = _G("DPSMateX_Details_DamageTotal_DiagramLegend_Child_C"..cat.."_Font")
		font:SetText(name)
		font:SetTextColor(DPSMateX:GetClassColor(DPSMateX.CacheUser[name][2]))
		_G("DPSMateX_Details_DamageTotal_DiagramLegend_Child_C"..cat.."_SwatchBg"):SetTexture(val[1][1],val[1][2],val[1][3],1)
		_G("DPSMateX_Details_DamageTotal_DiagramLegend_Child_C"..cat):Show()
	end
end

function DPSMateX.Modules.DetailsDamageTotal:RoundToH(val)
	if val>100 then
		return 100
	end
	return val
end

function DPSMateX.Modules.DetailsDamageTotal:CompareVal(x,y)
	if x>y then
		return y
	end
	return x
end

function DPSMateX.Modules.DetailsDamageTotal:LoadTable()
	local arr, total = self:GetTableValues()
	local i = 0
	for i=1, 30 do
		_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..i):Hide()
		_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..i.."_CB"):SetChecked(false)
		_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..i.."_CB").act = false
	end
	for cat, val in arr do
		if DPSMateX.CacheUser[val[1]][4] then
			i=i+1
		else
			if (cat-i)>30 then break end
			local r,g,b = DPSMateX:GetClassColor(DPSMateX.CacheUser[val[1]][2])
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child"):SetHeight((cat-i)*30)
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetText(val[1])
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_Name"):SetTextColor(r,g,b)
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_Amount"):SetText(val[2])
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetValue(100*val[2]/arr[1][2])
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_StatusBar"):SetStatusBarColor(r,g,b, 1)
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_Crit"):SetText(strformat("%.1f", 100*val[3]/val[6]).."%")
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_Miss"):SetText(strformat("%.1f", 100*val[4]/val[7]).."%")
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_DPS"):SetText(strformat("%.1f", val[2]/cbt))
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i).."_ActiveTime"):SetText(self:CompareVal(ceil(val[5]), ceil(cbt)).."s | "..strformat("%.1f", self:RoundToH(100*val[5]/cbt)).."%")
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i)).user = val[8]
			_G("DPSMateX_Details_DamageTotal_PlayerList_Child_R"..(cat-i)):Show()
		end
	end
end

function DPSMateX.Modules.DetailsDamageTotal:ShowTooltip(user, obj)
	local name = DPSMateX:GetUserById(user)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.Damage, DPSMateX.CacheUser[name], curKey)
	local pet = ""
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(name.."'s "..strlower(DPSMateX.L["damagedone"]), 1,1,1)
	if not a or not b or not c then return end
	for i=1, DPSMateX.Settings["subviewrows"] do
		if not a[i] then break end
		pet = c[i][2]
		pet = pet and DPSMateX.DB:GetPetShortName(pet)
		pet = pet and ("("..pet..")") or ""
		GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i])..pet,c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
	end
	GameTooltip:Show()
end
