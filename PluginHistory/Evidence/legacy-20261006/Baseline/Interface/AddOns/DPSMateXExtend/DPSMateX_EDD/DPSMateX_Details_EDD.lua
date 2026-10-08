local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsEDD = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g, g2, g3, g4, g7
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local strformat = string.format
local toggle, toggle3 = false, false

function DPSMateX.Modules.DetailsEDD:UpdateDetails(obj, key)
	DPSMateX_Details_CompareEDD:Hide()
	DPSMateX_Details_CompareEDD_Graph:Hide()

	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_EDD_Title:SetText(DPSMateX.L["dmgdoneby"]..obj.user)
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[DetailsUser], curKey)
	DPSMateX_Details_EDD:Show()
	self:ScrollFrame_Update("")
	self:SelectCreatureButton(1, "")
	self:SelectDetailsButton(1,1, "")
	DPSMateX_Details_EDD:Show()
	self:ScrollFrame_Update("")
	self:SelectCreatureButton(1, "")
	self:SelectDetailsButton(1,1, "")
	
	if not g then
		g=DPSMateX.Options.graph:CreateStackedGraph("EDDStackedGraph",DPSMateX_Details_EDD_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g:SetGridColor({0.5,0.5,0.5,0.5})
		g:SetAxisDrawing(true,true)
		g:SetAxisColor({1.0,1.0,1.0,1.0})
		g:SetAutoScale(true)
		g:SetYLabels(true, false)
		g:SetXLabels(true)
		g2=DPSMateX.Options.graph:CreateGraphLine("EDDLineGraph",DPSMateX_Details_EDD_DiagramLine,"CENTER","CENTER",0,0,950,230)
	end
	
	if toggle then
		self:UpdateStackedGraph(g)
	else
		self:UpdateLineGraph(g2, "")
	end
	DPSMateX_Details_EDD:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsEDD:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)
	
	DPSMateX_Details_CompareEDD.proc = "None"
	--UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareEDD_DiagramLegend_Procs, "None")
	DetailsUserComp = comp
	DPSMateX_Details_CompareEDD_Title:SetText(DPSMateX.L["dmgtakenby"]..comp)
	--UIDropDownMenu_Initialize(DPSMateX_Details_CompareEDD_DiagramLegend_Procs, DPSMateX.Modules.DetailsEDD.ProcsDropDown_Compare)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
	
	if not g3 then
		g3=DPSMateX.Options.graph:CreateStackedGraph("EDDStackedGraphComp",DPSMateX_Details_CompareEDD_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g3:SetGridColor({0.5,0.5,0.5,0.5})
		g3:SetAxisDrawing(true,true)
		g3:SetAxisColor({1.0,1.0,1.0,1.0})
		g3:SetAutoScale(true)
		g3:SetYLabels(true, false)
		g3:SetXLabels(true)
		g4=DPSMateX.Options.graph:CreateGraphLine("EDDLineGraphComp",DPSMateX_Details_CompareEDD_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g7=DPSMateX.Options.graph:CreateGraphLine("EDDLineGraphSumComp",DPSMateX_Details_CompareEDD_Graph,"CENTER","CENTER",0,0,1950,230)
	end
	
	DPSMateX_Details_CompareEDD:Show()
	self:ScrollFrame_Update("Compare", comp)
	self:SelectCreatureButton(1, "Compare", comp)
	self:SelectDetailsButton(1,1, "Compare", comp)
	
	if toggle then
		self:UpdateStackedGraph(g3, "Compare", comp)
	else
		self:UpdateLineGraph(g4, "Compare", comp)
	end
	self:UpdateSumGraph()
	
	DPSMateX_Details_CompareEDD_Graph:Show()
end

function DPSMateX.Modules.DetailsEDD:UpdateSumGraph()
	-- Executing the sumGraph
	local sumTable, sumTableTwo
	if toggle3 then
		sumTable = self:GetSummarizedTable(db, DetailsArrComp[DetailsSelectedComp], DetailsUserComp)
		sumTableTwo = self:GetSummarizedTable(db, DetailsArr[DetailsSelected])
	else
		sumTable = self:GetSummarizedTable(db, nil, DetailsUserComp)
		sumTableTwo = self:GetSummarizedTable(db, nil)
	end
	
	local max = DPSMateX:GetMaxValue(sumTable, 2)
	local time = DPSMateX:GetMaxValue(sumTable, 1)
	local min = DPSMateX:GetMinValue(sumTable, 1)
	local maxT = DPSMateX:GetMaxValue(sumTableTwo, 2)
	local timeT = DPSMateX:GetMaxValue(sumTableTwo, 1)
	local minT = DPSMateX:GetMinValue(sumTableTwo, 1)
	local smax, smin, stime = max, min, time
	
	if max<maxT then
		smax = maxT
	end
	if min>minT then
		smin = minT
	end
	if time<timeT then
		stime = timeT
	end
	g7:ResetData()
	g7:SetXAxis(0,stime-smin)
	g7:SetYAxis(0,smax+200)
	g7:SetGridSpacing((stime-smin)/20,smax/7)
	g7:SetGridColor({0.5,0.5,0.5,0.5})
	g7:SetAxisDrawing(true,true)
	g7:SetAxisColor({1.0,1.0,1.0,1.0})
	g7:SetAutoScale(true)
	g7:SetYLabels(true, false)
	g7:SetXLabels(true)
	
	local ata={{0,0}}
	for cat, val in DPSMateX:ScaleDown(sumTable, min) do
		--tinsert(ata, {val[1],val[2], self:CheckProcs(DPSMateX_Details_CompareEDD.proc, val[1]+min, DetailsUserComp)})
		tinsert(ata, {val[1],val[2], {}})
	end
	
	local Data2={{0,0}}
	for cat, val in DPSMateX:ScaleDown(sumTableTwo, minT) do
		--tinsert(Data2, {val[1],val[2], self:CheckProcs(DPSMateX_Details_EDD.proc, val[1]+minT)})
		tinsert(Data2, {val[1],val[2], {}})
	end

	--g7:AddDataSeries(ata,{{0.2,0.8,0.2,0.8}, {0.5,0.8,0.9,0.8}}, self:AddProcPoints(DPSMateX_Details_CompareEDD.proc, ata, DetailsUserComp))
	--g7:AddDataSeries(Data2,{{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}, self:AddProcPoints(DPSMateX_Details_EDD.proc, Data2))
	g7:AddDataSeries(ata,{{0.5,0.8,0.9,0.8}, {0.2,0.8,0.2,0.8}}, {})
	g7:AddDataSeries(Data2,{{1.0,1.0,0.0,0.8}, {1.0,0.0,0.0,0.8}}, {})
	g7:Show()
end

function DPSMateX.Modules.DetailsEDD:ScrollFrame_Update(comp)
	if not comp then comp = DPSMateX_Details_EDD.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."EDD_LogCreature"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedComp
	end
	local len = DPSMateX:TableLength(uArr)
	
	FauxScrollFrame_Update(obj,len,10,24)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if uArr[lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(uArr[lineplusoffset])
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Name"):SetTextColor(r,g,b)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[lineplusoffset][1].." ("..strformat("%.1f", (dArr[lineplusoffset][1]*100/dTot)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\"..img)
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(235)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(125)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(110)
			end
			_G(path.."_ScrollButton"..line):Show()
		else
			_G(path.."_ScrollButton"..line):Hide()
		end
		_G(path.."_ScrollButton"..line.."_selected"):Hide()
		if dSel == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsEDD:SelectCreatureButton(i, comp)
	if not comp then comp = DPSMateX_Details_EDD.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."EDD_Log"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		DetailsSelectedComp = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."EDD_LogCreature_ScrollFrame"))
		dSel = DetailsSelectedComp
	else
		DetailsSelected = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."EDD_LogCreature_ScrollFrame"))
		dSel = DetailsSelected
	end
	local len = DPSMateX:TableLength(dArr[i][2])

	FauxScrollFrame_Update(obj,len,10,24)
	obj.index = dSel
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[dSel][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(dArr[dSel][2][lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[dSel][3][lineplusoffset].." ("..strformat("%.1f", (dArr[dSel][3][lineplusoffset]*100/dArr[dSel][1])).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(335)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(225)
			else
				_G(path.."_ScrollButton"..line):SetWidth(320)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(210)
			end
			_G(path.."_ScrollButton"..line):Show()
		else
			_G(path.."_ScrollButton"..line):Hide()
		end
		_G(path.."_ScrollButton"..line.."_selected"):Hide()
		_G(path.."_ScrollButton1_selected"):Show()
	end
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."EDD_LogCreature_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."EDD_LogCreature_ScrollButton"..i.."_selected"):Show()
	self:SelectDetailsButton(dSel,1, comp)
	if toggle3 then
		if toggle then
			if comp ~= "" and comp~=nil then
				self:UpdateStackedGraph(g3, "Compare", DetailsUserComp)
			else
				self:UpdateStackedGraph(g)
			end
		else
			if comp ~= "" and comp~=nil then
				self:UpdateLineGraph(g4, "Compare", DetailsUserComp)
			else
				self:UpdateLineGraph(g2, "")
			end
		end
		if DetailsUserComp then
			self:UpdateSumGraph()
		end
	end
end

function DPSMateX.Modules.DetailsEDD:SelectDetailsButton(p,i, comp, cname)
	if not comp then comp = DPSMateX_Details_EDD.LastScroll or "" end
	local obj = _G("DPSMateX_Details_"..comp.."EDD_Log_ScrollFrame")
	local lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
	local uArr, dArr, dSel = DetailsArr, DmgArr, DetailsSelected
	
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."EDD_Log_ScrollButton"..p.."_selected"):Hide()
	end
	
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dSel = DetailsSelectedComp
		if not cname then
			cname = DetailsUserComp
		end
	end
	
	-- Performance?
	local ability = tonumber(dArr[p][2][lineplusoffset])
	local creature = tonumber(uArr[p])
	_G("DPSMateX_Details_"..comp.."EDD_Log_ScrollButton"..i.."_selected"):Show()
	
	local path = db[DPSMateX.CacheUser[cname or DetailsUser][1]][creature][ability]
	local hit, crit, miss, parry, dodge, resist, hitMin, hitMax, critMin, critMax, hitav, critav, block, blockMin, blockMax, blockav, crush, crushMin, crushMax, crushav = path[1], path[5], path[9], path[10], path[11], path[12], path[2], path[3], path[6], path[7], path[4], path[8], path[14], path[15], path[16], path[17], path[18], path[19], path[20], path[21]
	local total, max = hit+crit+miss+parry+dodge+resist+crush+block, DPSMateX:TMax({hit, crit, miss, parry, dodge, resist, crush, block})
	
	--_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Casts"):SetText("C: "..path[22])
	-- Block
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount0_Amount"):SetText(block)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount0_Percent"):SetText(strformat("%.1f", 100*block/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount0_StatusBar"):SetValue(ceil(100*block/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount0_StatusBar"):SetStatusBarColor(0.3,0.7,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average0"):SetText(ceil(blockav/DPSMateX:ProbZero(block)))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min0"):SetText(blockMin)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max0"):SetText(blockMax)
	
	-- Crush
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount1_Amount"):SetText(crush)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount1_Percent"):SetText(strformat("%.1f", 100*crush/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount1_StatusBar"):SetValue(ceil(100*crush/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount1_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average1"):SetText(ceil(crushav/DPSMateX:ProbZero(crush)))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min1"):SetText(crushMin)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max1"):SetText(crushMax)
	
	-- Hit
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount2_Amount"):SetText(hit)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount2_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount2_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount2_StatusBar"):SetStatusBarColor(0.9,0.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average2"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min2"):SetText(hitMin)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max2"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount3_Amount"):SetText(crit)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount3_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount3_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount3_StatusBar"):SetStatusBarColor(0.0,0.9,0.0,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average3"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min3"):SetText(critMin)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max3"):SetText(critMax)
	
	-- Miss
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount4_Amount"):SetText(miss)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount4_Percent"):SetText(strformat("%.1f", 100*miss/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount4_StatusBar"):SetValue(ceil(100*miss/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount4_StatusBar"):SetStatusBarColor(0.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average4"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min4"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max4"):SetText("-")
	
	-- Parry
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount5_Amount"):SetText(parry)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount5_Percent"):SetText(strformat("%.1f", 100*parry/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount5_StatusBar"):SetValue(ceil(100*parry/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount5_StatusBar"):SetStatusBarColor(1.0,1.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max5"):SetText("-")
	
	-- Dodge
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount6_Amount"):SetText(dodge)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount6_Percent"):SetText(strformat("%.1f", 100*dodge/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount6_StatusBar"):SetValue(ceil(100*dodge/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount6_StatusBar"):SetStatusBarColor(1.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max6"):SetText("-")
	
	-- Resist
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount7_Amount"):SetText(resist)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount7_Percent"):SetText(strformat("%.1f", 100*resist/total).."%")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount7_StatusBar"):SetValue(ceil(100*resist/max))
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Amount7_StatusBar"):SetStatusBarColor(0.0,1.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Average7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Min7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDD_LogDetails_Max7"):SetText("-")
end

function DPSMateX.Modules.DetailsEDD:UpdateLineGraph(gg, comp, cname)
	if g then
		g:Hide()
	end
	if g3 then
		g3:Hide()
	end
	local sumTable
	if toggle3 then
		if comp~="" and comp then
			sumTable = self:GetSummarizedTable(db, DetailsArrComp[DetailsSelectedComp], DetailsUserComp)
		else
			sumTable = self:GetSummarizedTable(db, DetailsArr[DetailsSelected])
		end
	else
		sumTable = self:GetSummarizedTable(db, nil, cname)
	end
	local max = DPSMateX:GetMaxValue(sumTable, 2)
	local time = DPSMateX:GetMaxValue(sumTable, 1)
	local min = DPSMateX:GetMinValue(sumTable, 1)
	
	gg:ResetData()
	gg:SetXAxis(0,time-min)
	gg:SetYAxis(0,max+200)
	gg:SetGridSpacing((time-min)/10,max/7)
	gg:SetGridColor({0.5,0.5,0.5,0.5})
	gg:SetAxisDrawing(true,true)
	gg:SetAxisColor({1.0,1.0,1.0,1.0})
	gg:SetAutoScale(true)
	gg:SetYLabels(true, false)
	gg:SetXLabels(true)

	local Data1={{0,0}}
	for cat, val in DPSMateX:ScaleDown(sumTable, min) do
		tinsert(Data1, {val[1],val[2], {}})
	end

	local colorT = {{1.0,0.0,0.0,0.8}, {1.0,0.0,0.0,0.8}}
	if cname then
		colorT = {{0.5,0.8,0.9,0.8}, {0.2,0.8,0.2,0.8}}
	end

	gg:AddDataSeries(Data1,colorT, {})
	gg:Show()
end

function DPSMateX.Modules.DetailsEDD:UpdateStackedGraph(gg, comp, cname)
	if g2 then
		g2:Hide()
	end
	if g4 then
		g4:Hide()
	end
	
	local Data1 = {}
	local label = {}
	local b = {}
	local p = {}
	local maxY = 0
	local maxX = 0
	local temp = {}
	local temp2 = {}
	local dSel, uArr = DetailsSelected, DetailsArr
	if comp~="" and comp then
		uArr = DetailsArrComp
		dSel = DetailsSelectedComp
	end
	
	if toggle3 then
		for cat, val in db[DPSMateX.CacheUser[cname or DetailsUser][1]][uArr[dSel]] do
			if cat~="i" and val["i"] then
				for c, v in val["i"] do
					local key = tonumber(strformat("%.1f", c))
					if not temp[cat] then
						temp[cat] = {}
						temp2[cat] = 0
					end
					if p[key] then
						p[key] = p[key] + v
					else
						p[key] = v
					end
					local i = 1
					while true do
						if not temp[cat][i] then
							tinsert(temp[cat], i, {c,v})
							break
						elseif c<=temp[cat][i][1] then
							tinsert(temp[cat], i, {c,v})
							break
						end
						i = i + 1
					end
					temp2[cat] = temp2[cat] + val[13]
					maxY = math.max(p[key], maxY)
					maxX = math.max(c, maxX)
				end
			end
		end	
	else
		for cat, val in db[DPSMateX.CacheUser[cname or DetailsUser][1]] do
			for ca, va in val do
				if ca~="i" and va["i"] then
					for c, v in va["i"] do
						local key = tonumber(strformat("%.1f", c))
						if not temp[ca] then
							temp[ca] = {}
							temp2[ca] = 0
						end
						if p[key] then
							p[key] = p[key] + v
						else
							p[key] = v
						end
						local i = 1
						while true do
							if not temp[ca][i] then
								tinsert(temp[ca], i, {c,v})
								break
							elseif c<=temp[ca][i][1] then
								tinsert(temp[ca], i, {c,v})
								break
							end
							i = i + 1
						end
						temp2[ca] = temp2[ca] + va[13]
						maxY = math.max(p[key], maxY)
						maxX = math.max(c, maxX)
					end
				end
			end
		end
	end
	local min
	for cat, val in temp do
		local pmin = DPSMateX:GetMinValue(val, 1)
		if not min or pmin<min then
			min = pmin
		end
	end
	for cat, val in temp do
		local i = 1
		while true do
			if not b[i] then
				tinsert(b, i, temp2[cat])
				tinsert(label, i, DPSMateX:GetAbilityById(cat))
				tinsert(Data1, i, val)
				break
			elseif b[i]>=temp2[cat] then
				tinsert(b, i, temp2[cat])
				tinsert(label, i, DPSMateX:GetAbilityById(cat))
				tinsert(Data1, i, val)
				break
			end
			i = i + 1
		end
	end
	
	for cat, val in Data1 do
		Data1[cat] = DPSMateX:ScaleDown(val, min)
	end
	
	gg:ResetData()
	gg:SetGridSpacing((maxX-min)/7,maxY/7)
	
	gg:AddDataSeries(Data1,{1.0,0.0,0.0,0.8}, {}, label)
	gg:Show()
end

function DPSMateX.Modules.DetailsEDD:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDD_Log"), 352, 270-i*30, 717, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDD_Log"), 402, 265, 402, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDD_Log"), 537, 265, 537, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDD_Log"), 597, 265, 597, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDD_Log"), 657, 265, 657, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

function DPSMateX.Modules.DetailsEDD:SortLineTable(arr, b, cname)
	local newArr = {}
	if b then
		for cat, val in arr[DPSMateX.CacheUser[cname or DetailsUser][1]][b] do
			if cat~="i" and val["i"] then
				for c,v in val["i"] do
					local i = 1
					while true do
						if not newArr[i] then
							tinsert(newArr, i, {c,v})
							break
						else
							if c<=newArr[i][1] then
								tinsert(newArr, i, {c,v})
								break
							end
						end
						i = i +1
					end
				end
			end
		end	
	else
		for cat, val in arr[DPSMateX.CacheUser[cname or DetailsUser][1]] do
			for ca, va in val do
				if ca~="i" and va["i"] then
					for c,v in va["i"] do
						local i = 1
						while true do
							if not newArr[i] then
								tinsert(newArr, i, {c,v})
								break
							else
								if c<=newArr[i][1] then
									tinsert(newArr, i, {c,v})
									break
								end
							end
							i = i +1
						end
					end
				end
			end
		end
	end
	return newArr
end

function DPSMateX.Modules.DetailsEDD:GetSummarizedTable(arr, b, cname)
	return DPSMateX.Sync:GetSummarizedTable(self:SortLineTable(arr, b, cname))
end

function DPSMateX.Modules.DetailsEDD:ToggleMode() 
	if toggle then
		self:UpdateLineGraph(g2, "")
		if DetailsUserComp then
			self:UpdateLineGraph(g4, "Compare", DetailsUserComp)
		end
		toggle = false
	else
		self:UpdateStackedGraph(g)
		if DetailsUserComp then
			self:UpdateStackedGraph(g3, "Compare", DetailsUserComp)
		end
		toggle = true
	end
end

function DPSMateX.Modules.DetailsEDD:ToggleIndividual()
	if toggle3 then
		toggle3 = false
	else
		toggle3 = true
	end
	if toggle then
		self:UpdateStackedGraph(g)
		if DetailsUserComp then
			self:UpdateStackedGraph(g3, "Compare", DetailsUserComp)
		end
	else
		self:UpdateLineGraph(g2, "")
		if DetailsUserComp then
			self:UpdateLineGraph(g4, "Compare", DetailsUserComp)
		end
	end
	if DetailsUserComp then
		self:UpdateSumGraph()
	end
end

