DPSMateX.Modules.DetailsEDTTotal = {}

local g, g2 = nil, nil
local curKey = 1
local db, cbt = {}, 0
local buttons = {}
local ColorTable={}
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local toggle = false
local totSumTable = {}
local totMax, totTime = 0, 0

function DPSMateX.Modules.DetailsEDTTotal:UpdateDetails(obj, key)
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
		g=DPSMateX.Options.graph:CreateGraphLine("EDTTLineGraph",DPSMateX_Details_EDTTotal_DiagramLine,"CENTER","CENTER",0,0,740,220)
		g2=DPSMateX.Options.graph:CreateStackedGraph("EDTTStackedGraph",DPSMateX_Details_EDTTotal_DiagramLine,"CENTER","CENTER",0,0,850,220)
		g2:SetGridColor({0.5,0.5,0.5,0.5})
		g2:SetAxisDrawing(true,true)
		g2:SetAxisColor({1.0,1.0,1.0,1.0})
		g2:SetAutoScale(true)
		g2:SetYLabels(true, false)
		g2:SetXLabels(true)
		g2:Hide()
		self:CreateGraphTable()
	end
	DPSMateX_Details_EDTTotal_PlayerList_CB:SetChecked(false)
	DPSMateX_Details_EDTTotal_PlayerList_CB.act = false
	DPSMateX_Details_EDTTotal_Title:SetText(DPSMateX.L["edtsum"])
	self:LoadTable()
	self:LoadLegendButtons()
	if toggle then
		self:UpdateStackedGraph()
	else
		self:UpdateLineGraph()
	end
	DPSMateX_Details_EDTTotal:Show()
	DPSMateX_Details_EDTTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsEDTTotal:ToggleMode()
	if toggle then
		self:UpdateLineGraph()
		toggle=false
	else
		self:UpdateStackedGraph()
		toggle=true
	end
end

local pairs = pairs
function DPSMateX.Modules.DetailsEDTTotal:UpdateLineGraph()	
	g:ResetData()
	g:SetGridColor({0.5,0.5,0.5,0.5})
	g:SetAxisDrawing(true,true)
	g:SetAxisColor({1.0,1.0,1.0,1.0})
	g:SetAutoScale(true)
	g:SetYLabels(true, false)
	g:SetXLabels(true)
	DPSMateX_Details_EDTTotal_DiagramLine:SetWidth(770)
	DPSMateX_Details_EDTTotal_DiagramLegend:Show()
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
	g2:Hide()
	g:Show()
	toggle=false
end

function DPSMateX.Modules.DetailsEDTTotal:UpdateStackedGraph()
	g:Hide()
	DPSMateX_Details_EDTTotal_DiagramLine:SetWidth(870)
	DPSMateX_Details_EDTTotal_DiagramLegend:Hide()
	
	local Data1 = {}
	local label = {}
	local maxX, maxY = 0,0
	local p = {}
	for cat, val in db do -- npc
		local temp = {}
		if cat~="i" then
			for ca, va in val do
				if ca~="i" then -- user
					for q,s in va do -- abid
						if q~="i" and s["i"] then
							for c,v in s["i"] do
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
				end
			end
			tinsert(label, 1, DPSMateX:GetUserById(cat))
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

function DPSMateX.Modules.DetailsEDTTotal:GetSummarizedTable(arr)
	return DPSMateX.Sync:GetSummarizedTable(arr)
end

function DPSMateX.Modules.DetailsEDTTotal:CreateGraphTable()
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 10, 270-i*30, 860, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 40, 260, 40, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 170, 260, 170, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 540, 260, 540, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 600, 260, 600, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 660, 260, 660, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[14] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 720, 260, 720, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[14]:Show()
	
	lines[15] = DPSMateX.Options.graph:DrawLine(DPSMateX_Details_EDTTotal_PlayerList, 780, 260, 780, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[15]:Show()
end

function DPSMateX.Modules.DetailsEDTTotal:AddTotalDataSeries()
	local sumTable, newArr = {[0]=0}, {}
	local tl = DPSMateX:TableLength(db)
	tl = floor(tl-0.5*tl)
	
	for cat, val in db do -- cause 
		if cat~="i" then
			for ca, va in val do -- user
				if ca~="i" then
					for c, v in va do
						if c~="i" and v["i"] then
							for q,s in v["i"] do
								if sumTable[q] then
									sumTable[q] = sumTable[q] + s
								else
									sumTable[q] = s
								end
							end
						end
					end
				end
			end
		end
	end
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
	g:SetXAxis(0,time)
	g:SetYAxis(0,totMax+20)
	g:SetGridSpacing(totTime/10,(totMax+20)/2)
	
	g:AddDataSeries(totSumTable,{{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}, {})
end

-- crushes?
function DPSMateX.Modules.DetailsEDTTotal:GetTableValues()
	local arr, total = {}, 0
	for cat, val in db do -- cause
		local CV, crit, totCrit, miss, totMiss, hit, totHit, crush, totOverall = 0, 0, 0.000001, 0, 0.000001, 0, 0.000001, 0, 0
		local name = DPSMateX:GetUserById(cat)
		for ca, va in pairs(val) do -- user
			if ca~="i" then
				for c, v in pairs(va) do -- ability
					if c~="i" then
						if v[1]>0 or v[14]>0 then
							totHit=totHit+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
							hit=hit+v[1]
							crush=crush+v[14]
						end
						if v[5]>0 then
							totCrit=totCrit+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
							crit=crit+v[5]
						end
						if v[9]>0 or v[10]>0 or v[11]>0 or v[12]>0 then
							totMiss=totMiss+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
							miss=miss+v[9]+v[10]+v[11]+v[12]
						end
						CV = CV + v[13]
						totOverall = totOverall+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
					end
				end
			end
		end
		tinsert(arr, {name, CV, crit, miss, totCrit, totMiss, cat, hit, totHit, crush,totOverall})
		total = total + CV
	end
	local newArr = {}
	for cat, val in arr do
		local i = 1
		while true do
			if (not newArr[i]) then
				tinsert(newArr, i, val)
				break
			elseif newArr[i][2]<=val[2] then
				tinsert(newArr, i, val)
				break
			end
			i=i+1
		end
	end
	return newArr, total
end

function DPSMateX.Modules.DetailsEDTTotal:CheckButtonCheckAll(obj)
	if obj.act then
		obj.act = false
		for i=1, 30 do 
			local ob = _G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i)
			if ob.user then
				DPSMateX.Modules.DetailsEDTTotal:RemoveLinesButton(ob.user, ob)
				_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i.."_CB"):SetChecked(obj.act)
			end
		end
	else
		obj.act = true
		for i=1, 30 do 
			local ob = _G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i)
			if ob.user then
				DPSMateX.Modules.DetailsEDTTotal:AddLinesButton(ob.user, ob)
				_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i.."_CB"):SetChecked(obj.act)
			end
		end
	end
end

function DPSMateX.Modules.DetailsEDTTotal:SortLineTable(uid)
	local newArr = {}
	-- user
	for cat, val in db[uid] do -- user
		if cat~="i" then
			for ca, va in val do -- abid
				if ca~="i" and va["i"] then
					for c,v in va["i"] do
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
	return newArr
end

function DPSMateX.Modules.DetailsEDTTotal:AddLinesButton(uid, obj)
	local sumTable = self:SortLineTable(uid)
	DPSMateX_Details_EDTTotal_DiagramLine:SetWidth(770)
	DPSMateX_Details_EDTTotal_DiagramLegend:Show()
	
	sumTable = self:GetSummarizedTable(sumTable, cbt)
	
	local Max = DPSMateX:GetMaxValue(sumTable, 2)
	if Max > totMax then
		g:SetGridSpacing(totTime/10,Max/7)
	end
	g2:Hide()
	g:Show()
	
	g:AddDataSeries(sumTable, {ColorTable[1], {}}, {})
	tinsert(buttons, {ColorTable[1], uid, sumTable})
	tremove(ColorTable, 1)
	obj.act = true
	toggle=false
	self:LoadLegendButtons()
end

function DPSMateX.Modules.DetailsEDTTotal:RemoveLinesButton(uid, obj)
	obj.act = false
	g:ResetData()
	DPSMateX_Details_EDTTotal_DiagramLine:SetWidth(770)
	DPSMateX_Details_EDTTotal_DiagramLegend:Show()
	
	g:Show()
	for cat, val in buttons do
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
	toggle=false
	self:LoadLegendButtons()
end

function DPSMateX.Modules.DetailsEDTTotal:LoadLegendButtons()
	for i=1, 30 do
		_G("DPSMateX_Details_EDTTotal_DiagramLegend_Child_C"..i):Hide()
	end
	for cat, val in pairs(buttons) do
		local name = DPSMateX:GetUserById(val[2])
		local font = _G("DPSMateX_Details_EDTTotal_DiagramLegend_Child_C"..cat.."_Font")
		font:SetText(name)
		font:SetTextColor(DPSMateX:GetClassColor(DPSMateX.CacheUser[name][2]))
		_G("DPSMateX_Details_EDTTotal_DiagramLegend_Child_C"..cat.."_SwatchBg"):SetTexture(val[1][1],val[1][2],val[1][3],1)
		_G("DPSMateX_Details_EDTTotal_DiagramLegend_Child_C"..cat):Show()
	end
end

function DPSMateX.Modules.DetailsEDTTotal:LoadTable()
	local arr, total = DPSMateX.Modules.DetailsEDTTotal:GetTableValues()
	for i=1, 30 do
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i):Hide()
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i.."_CB"):SetChecked(false)
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i.."_CB").act = false
	end
	for cat, val in pairs(arr) do
		if cat>30 then break end
		local r,g,b = DPSMateX:GetClassColor(DPSMateX.CacheUser[val[1]][2])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child"):SetHeight(cat*30)
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Name"):SetText(val[1])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Name"):SetTextColor(r,g,b)
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Amount"):SetText(val[2])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_StatusBar"):SetValue(100*val[2]/arr[1][2])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_StatusBar"):SetStatusBarColor(r,g,b, 1)
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Crush"):SetText(strformat("%.1f", 100*val[10]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Hit"):SetText(strformat("%.1f", 100*val[8]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Crit"):SetText(strformat("%.1f", 100*val[3]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Miss"):SetText(strformat("%.1f", 100*val[4]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_EDPS"):SetText(strformat("%.1f", val[2]/(((DPSMateX.CombatTime["effective"][curKey][val[1]]) or cbt)+1)))
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat).user = val[7]
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat):Show()
	end
end

function DPSMateX.Modules.DetailsEDTTotal:ShowTooltip(user, obj)
	local name = DPSMateX:GetUserById(user)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.EDT, DPSMateX.CacheUser[name], curKey)
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
