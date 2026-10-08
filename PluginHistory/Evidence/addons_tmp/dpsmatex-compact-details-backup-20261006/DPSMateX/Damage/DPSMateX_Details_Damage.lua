-- Global Variables
local DPSMateX = DPSMateX
DPSMateX.Modules.DetailsDamage = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g, g2, g3, g4, g5, g6, g7
local curKey = 1
local db, cbt, db2 = {}, 0, {}
local _G = getglobal
local tinsert = table.insert
local strformat = string.format
local toggle, toggle2, toggle3 = false, false, false
local t1, t2, TTotal = {}, {}, 0
local t1Comp, t2Comp, TTotalComp = {}, {}, 0
local ecbt = {}
local PSelected = 1
local PSelected2 = 1

function DPSMateX.Modules.DetailsDamage:UpdateDetails(obj, key)
	curKey = key
	db, cbt,ecbt = DPSMateX:GetMode(key)
	db2 = DPSMateX:GetModeByArr(DPSMateX.DBCache.EDT, key, "EDTaken")
	DPSMateX_Details.proc = "None"
	UIDropDownMenu_SetSelectedValue(DPSMateX_Details_DiagramLegend_Procs, "None")
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_Title:SetText(DPSMateX.L["dmgdoneby"]..obj.user)
	DPSMateX_Details_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", (ecbt[obj.user] or 0)+1).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*((ecbt[obj.user] or 0)+1)/cbt).."%)")
	DPSMateX_Details:Show()
	UIDropDownMenu_Initialize(DPSMateX_Details_DiagramLegend_Procs, DPSMateX.Modules.DetailsDamage.ProcsDropDown)
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.Modules.Damage, DPSMateX.CacheUser[DetailsUser], curKey)
	t1, t2, TTotal = self:EvalToggleTable()
	
	if not g then
		g=DPSMateX.Options.graph:CreateGraphPieChart("DMGPieChart", DPSMateX_Details_Diagram, "CENTER", "CENTER", 0, 0, 200, 200)
		g2=DPSMateX.Options.graph:CreateGraphLine("DMGLineGraph",DPSMateX_Details_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g3=DPSMateX.Options.graph:CreateStackedGraph("DMGStackedGraph",DPSMateX_Details_DiagramLine,"CENTER","CENTER",0,0,850,230)
		g3:SetGridColor({0.5,0.5,0.5,0.5})
		g3:SetAxisDrawing(true,true)
		g3:SetAxisColor({1.0,1.0,1.0,1.0})
		g3:SetAutoScale(true)
		g3:SetYLabels(true, false)
		g3:SetXLabels(true)
	end
	
	if toggle then
		self:Player_Update("")
		self:PlayerSpells_Update(1,"")
		self:SelectDetailsButton(1,"")
	else
		self:ScrollFrame_Update("")
		self:SelectDetailsButton(1,"")
	end
	self:UpdatePie(g)
	if toggle2 then
		self:UpdateStackedGraph(g3)
	else
		self:UpdateLineGraph(g2, "")
	end
	
	DPSMateX_Details_CompareDamage:Hide()
	DPSMateX_Details_CompareDamage_Graph:Hide()
	
	DPSMateX_Details:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
	
end

function DPSMateX.Modules.DetailsDamage:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)
	DPSMateX_Details_CompareDamage:Show()--先show再update scroll,否则不能scroll
	
	DPSMateX_Details_CompareDamage.proc = "None"
	UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareDamage_DiagramLegend_Procs, "None")
	DetailsUserComp = comp
	DPSMateX_Details_CompareDamage_Title:SetText(DPSMateX.L["dmgdoneby"]..comp)
	DPSMateX_Details_CompareDamage_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*(DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0)/cbt).."%)")
	UIDropDownMenu_Initialize(DPSMateX_Details_CompareDamage_DiagramLegend_Procs, DPSMateX.Modules.DetailsDamage.ProcsDropDown_CompareDamage)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
	t1Comp, t2Comp, TTotalComp = self:EvalToggleTable(comp)
	
	if not g4 then
		g4=DPSMateX.Options.graph:CreateGraphPieChart("DMGPieChartComp", DPSMateX_Details_CompareDamage_Diagram, "CENTER", "CENTER", 0, 0, 200, 200)
		g5=DPSMateX.Options.graph:CreateGraphLine("DMGLineGraphComp",DPSMateX_Details_CompareDamage_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g6=DPSMateX.Options.graph:CreateStackedGraph("DMGStackedGraphComp",DPSMateX_Details_CompareDamage_DiagramLine,"CENTER","CENTER",0,0,850,230)
		g6:SetGridColor({0.5,0.5,0.5,0.5})
		g6:SetAxisDrawing(true,true)
		g6:SetAxisColor({1.0,1.0,1.0,1.0})
		g6:SetAutoScale(true)
		g6:SetYLabels(true, false)
		g6:SetXLabels(true)
		g7=DPSMateX.Options.graph:CreateGraphLine("DMGLineGraphSum",DPSMateX_Details_CompareDamage_Graph,"CENTER","CENTER",0,0,1950,230)
	end
	
	if toggle then
		self:Player_Update("_CompareDamage")
		self:PlayerSpells_Update(1, "_CompareDamage")
		self:SelectDetailsButton(1, "_CompareDamage")
		DPSMateX_Details_CompareDamage_playerSpells:Show()
		DPSMateX_Details_CompareDamage_player:Show()
		DPSMateX_Details_CompareDamage_Diagram:Hide()
		DPSMateX_Details_CompareDamage_Log:Hide()
	else
		self:ScrollFrame_Update("_CompareDamage")
		self:SelectDetailsButton(1,"_CompareDamage")
		DPSMateX_Details_CompareDamage_playerSpells:Hide()
		DPSMateX_Details_CompareDamage_player:Hide()
		DPSMateX_Details_CompareDamage_Diagram:Show()
		DPSMateX_Details_CompareDamage_Log:Show()
	end
	self:UpdatePie(g4, comp)
	if toggle2 then
		self:UpdateStackedGraph(g6, "_CompareDamage", comp)
	else
		self:UpdateLineGraph(g5, "_CompareDamage", comp)
	end
	self:UpdateSumGraph()
	
	DPSMateX_Details_CompareDamage_Graph:Show()
end

function DPSMateX.Modules.DetailsDamage:UpdateSumGraph()
	-- Executing the sumGraph
	local sumTable, sumTableTwo
	if toggle3 then
		sumTable = self:GetSummarizedTable(db2, t1Comp[PSelected2], DetailsUserComp)
		sumTableTwo = self:GetSummarizedTable(db2, t1[PSelected])
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
		tinsert(ata, {val[1],val[2], self:CheckProcs(DPSMateX_Details_CompareDamage.proc, val[1]+min+1, DetailsUserComp)})
	end
	
	local Data2={{0,0}}
	for cat, val in DPSMateX:ScaleDown(sumTableTwo, minT) do
		tinsert(Data2, {val[1],val[2], self:CheckProcs(DPSMateX_Details.proc, val[1]+minT+1)})
	end

	g7:AddDataSeries(ata,{{0.2,0.8,0.2,0.8}, {0.5,0.8,0.9,0.8}}, self:AddProcPoints(DPSMateX_Details_CompareDamage.proc, ata, DetailsUserComp))
	g7:AddDataSeries(Data2,{{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}, self:AddProcPoints(DPSMateX_Details.proc, Data2))
	g7:Show()
end

local pairs = pairs
local ipairs = ipairs

function DPSMateX.Modules.DetailsDamage:EvalToggleTable(comp)
	local a,b,u = {},{},{}
	local d,pet = 0,nil

	local user = DPSMateX.CacheUser[comp or DetailsUser]

	u={user[1]}
	local petsname = DPSMateX.DB:GetPetsName(user)
	if petsname and DPSMateX.Settings["mergepets"] then
		for petname,_ in pairs(petsname) do 
			if (petname ~= DPSMateX.L["unknown"] and DPSMateX.CacheUser[petname]) and
				DPSMateX.CacheUser[petname][1]~=user[1] then 
				tinsert(u, DPSMateX.CacheUser[petname][1])
			end
		end
	end

	for cat, arr in pairs(db2) do
		local c = {[1] = 0,[2] = {},[3] = {}} --{total, abilities, ability values}
		for _, v in ipairs(u) do
			if arr[v] then
				for p, val in pairs(arr[v]) do
					if p ~= "i" then
						local usrName = DPSMateX:GetUserById(v)
						if (DPSMateX.CacheUser[usrName][4]) then pet=v; else pet=nil; end
						local i = 1
						while true do
							if (not c[2][i]) then
								tinsert(c[3], i, val)
								tinsert(c[2], i, {p,pet})
								break
							else
								if c[3][i][13] < val[13] then
									tinsert(c[3], i, val) --value
									tinsert(c[2], i, {p,pet}) --ability
									break
								end
							end
							i=i+1
						end
					end
				end
				c[1] = arr[v]["i"]
			end
		end
		
		if c[2][1] then 
			local i = 1
			while true do
				if (not a[i]) then
					tinsert(b, i, c)
					tinsert(a, i, cat)
					break
				else
					if b[i][1] < c[1] then
						tinsert(b, i, c)
						tinsert(a, i, cat)
						break
					end
				end
				i=i+1
			end
			d = d + c[1]
		end
	end
	return a,b,d
end

function DPSMateX.Modules.DetailsDamage:ScrollFrame_Update(comp)
	if not comp then comp = DPSMateX_Details.LastScroll or "" end
	local line, lineplusoffset
	local obj = _G("DPSMateX_Details"..comp.."_Log_ScrollFrame")
	local path = "DPSMateX_Details"..comp.."_Log"
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedComp
	end
	local pet, len = "", DPSMateX:TableLength(uArr)
	
	FauxScrollFrame_Update(obj,len,10,24)
	for line=1,10 do
		lineplusoffset = line + (FauxScrollFrame_GetOffset(obj) or 0)
		if uArr[lineplusoffset] ~= nil then
			pet = dArr[lineplusoffset][2]
			pet = pet and DPSMateX.DB:GetPetShortName(pet)
			pet = pet and ("("..pet..")") or ""
			
			local ability = DPSMateX:GetAbilityById(uArr[lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability..pet)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[lineplusoffset][1].." ("..strformat("%.1f", (dArr[lineplusoffset][1]*100/dTot)).."%)")
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
		if dSel == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsDamage:Player_Update(comp)
	if not comp then comp = DPSMateX_Details.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details"..comp.."_player"
	local obj = _G(path.."_ScrollFrame")
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d1 = t1Comp
		d2 = t2Comp
		d3 = TTotalComp
		d4 = PSelected2
	end
	local len = DPSMateX:TableLength(d1)

	FauxScrollFrame_Update(obj,len,8,24)
	for line=1,8 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d1[lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(d1[lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[lineplusoffset][1].." ("..strformat("%.1f", (d2[lineplusoffset][1]*100/d3)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\npc")
			if len < 8 then
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
		if d4 == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsDamage:PlayerSpells_Update(i, comp)
	if not comp then comp = DPSMateX_Details.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details"..comp.."_playerSpells"
	local obj = _G(path.."_ScrollFrame")

	local offset = FauxScrollFrame_GetOffset(_G("DPSMateX_Details"..comp.."_player_ScrollFrame"))
	obj.id = (i and  (i + offset)) or obj.id

	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d2 = t2Comp
		d4 = PSelected2
	end
	local len = DPSMateX:TableLength(d2[obj.id][2])

	FauxScrollFrame_Update(obj,len,10,24)
	local pet
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		local av = d2[obj.id][2][lineplusoffset]
		if av ~= nil then
			pet = DPSMateX.DB:GetPetShortName(av[2]) or ""
			local ability = DPSMateX:GetAbilityById(av[1])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability..pet)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[obj.id][3][lineplusoffset][13].." ("..strformat("%.1f", (d2[obj.id][3][lineplusoffset][13]*100/d2[obj.id][1])).."%)")
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
		if DetailsSelected == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
	if comp ~= "" and comp~=nil then
		PSelected2 = obj.id
	else
		PSelected = obj.id
	end
	for p=1, 8 do
		if obj.id - offset == p then
			_G("DPSMateX_Details"..comp.."_player_ScrollButton"..p.."_selected"):Show()
		else
			_G("DPSMateX_Details"..comp.."_player_ScrollButton"..p.."_selected"):Hide()
		end
	end
	if toggle3 then
		if toggle2 then
			if comp ~= "" and comp~=nil then
				self:UpdateStackedGraph(g6, comp, DetailsUserComp)
			else
				self:UpdateStackedGraph(g3)
			end
		else
			if comp ~= "" and comp~=nil then
				self:UpdateLineGraph(g5, comp, DetailsUserComp)
			else
				self:UpdateLineGraph(g2, "")
			end
		end
		if DetailsUserComp then
			self:UpdateSumGraph()
		end
	end
end

function DPSMateX.Modules.DetailsDamage:SelectDetailsButton(i, comp, cname)
	if not comp then comp = DPSMateX_Details.LastScroll or "" end
	local pathh = ""
	local path,obj,lineplusoffset
	local uArr, dSel, d2 = DetailsArr, DetailsSelected, t2
	local dArr = DmgArr
	
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dSel = DetailsSelectedComp
		dArr = DmgArrComp
		if not cname then
			cname = DetailsUserComp
		end
		d2 = t2Comp
	end
	local user, pet = DPSMateX.CacheUser[cname or DetailsUser][1],""

	local glance, glanceMin, glanceMax, glanceav 
	local block, blockMin, blockMax, blockav 

	if toggle then
		pathh = "DPSMateX_Details"..comp.."_playerSpells"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + (FauxScrollFrame_GetOffset(obj) or 0)
		path = d2[obj.id][3][lineplusoffset]
		if not path then return end
		--因吹斯听
		glance, glanceMin, glanceMax, glanceav = path[18], path[19], path[20], path[21]
		block, blockMin, blockMax, blockav = path[14], path[15], path[16], path[17]
	else
		pathh = "DPSMateX_Details"..comp.."_Log"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + (FauxScrollFrame_GetOffset(obj) or 0)
	
		local ability = tonumber(uArr[lineplusoffset])
		local PetId = dArr[lineplusoffset][2] or nil
		user=DPSMateX.CacheUser[cname or DetailsUser][1];
		if PetId then
			local petname = DPSMateX:GetUserById(PetId)
			if petname and petname~=(cname or DetailsUser) then 
				user = PetId
			end
		end
		path = db[user][tonumber(uArr[lineplusoffset])]
		if not path then return end
		--因吹斯听
		glance, glanceMin, glanceMax, glanceav  = path[14], path[15], path[16], path[17]
		block, blockMin, blockMax, blockav = path[18], path[19], path[20], path[21]
	end
	if comp ~= "" and comp~=nil then
		DetailsSelectedComp = lineplusoffset
	else
		DetailsSelected = lineplusoffset
	end
	for p=1, 10 do
		_G(pathh.."_ScrollButton"..p.."_selected"):Hide()
	end
	_G(pathh.."_ScrollButton"..i.."_selected"):Show()
	
	local hit, crit, miss, parry = path[1], path[5], path[9], path[10]
	local dodge, resist, hitMin, hitMax = path[11], path[12], path[2], path[3]
	local critMin, critMax, hitav, critav = path[6], path[7], path[4], path[8]
	
	local total, max = hit+crit+miss+parry+dodge+resist+glance+block, DPSMateX:TMax({hit, crit, miss, parry, dodge, resist, glance, block})
	
	_G("DPSMateX_Details"..comp.."_LogDetails_Casts"):SetText("C: "..total)
	-- Block
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount0_Amount"):SetText(block)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount0_Percent"):SetText(strformat("%.1f", 100*block/total).."%")
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount0_StatusBar"):SetValue(ceil(100*block/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount0_StatusBar"):SetStatusBarColor(0.3,0.7,1.0,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average0"):SetText(ceil(blockav/DPSMateX:ProbZero(block)))
	_G("DPSMateX_Details"..comp.."_LogDetails_Min0"):SetText(blockMin)
	_G("DPSMateX_Details"..comp.."_LogDetails_Max0"):SetText(blockMax)
	
	-- Glance
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount1_Amount"):SetText(glance)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount1_Percent"):SetText(strformat("%.1f", 100*glance/total).."%")
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount1_StatusBar"):SetValue(ceil(100*glance/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount1_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average1"):SetText(ceil(glanceav/DPSMateX:ProbZero(glance)))
	_G("DPSMateX_Details"..comp.."_LogDetails_Min1"):SetText(glanceMin)
	_G("DPSMateX_Details"..comp.."_LogDetails_Max1"):SetText(glanceMax)
	
	-- Hit
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount2_Amount"):SetText(hit)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount2_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount2_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount2_StatusBar"):SetStatusBarColor(0.9,0.0,0.0,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average2"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details"..comp.."_LogDetails_Min2"):SetText(hitMin)
	_G("DPSMateX_Details"..comp.."_LogDetails_Max2"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount3_Amount"):SetText(crit)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount3_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount3_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount3_StatusBar"):SetStatusBarColor(0.0,0.9,0.0,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average3"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details"..comp.."_LogDetails_Min3"):SetText(critMin)
	_G("DPSMateX_Details"..comp.."_LogDetails_Max3"):SetText(critMax)
	
	-- Miss
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount4_Amount"):SetText(miss)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount4_Percent"):SetText(strformat("%.1f", 100*miss/total).."%")

	_G("DPSMateX_Details"..comp.."_LogDetails_Amount4_StatusBar"):SetValue(ceil(100*miss/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount4_StatusBar"):SetStatusBarColor(0.0,0.0,1.0,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average4"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Min4"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Max4"):SetText("-")
	
	-- Parry
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount5_Amount"):SetText(parry)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount5_Percent"):SetText(strformat("%.1f", 100*parry/total).."%")
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount5_StatusBar"):SetValue(ceil(100*parry/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount5_StatusBar"):SetStatusBarColor(1.0,1.0,0.0,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average5"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Min5"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Max5"):SetText("-")
	
	-- Dodge
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount6_Amount"):SetText(dodge)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount6_Percent"):SetText(strformat("%.1f", 100*dodge/total).."%")
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount6_StatusBar"):SetValue(ceil(100*dodge/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount6_StatusBar"):SetStatusBarColor(1.0,0.0,1.0,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average6"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Min6"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Max6"):SetText("-")
	
	-- Resist
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount7_Amount"):SetText(resist)
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount7_Percent"):SetText(strformat("%.1f", 100*resist/total).."%")
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount7_StatusBar"):SetValue(ceil(100*resist/max))
	_G("DPSMateX_Details"..comp.."_LogDetails_Amount7_StatusBar"):SetStatusBarColor(0.0,1.0,1.0,1)
	_G("DPSMateX_Details"..comp.."_LogDetails_Average7"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Min7"):SetText("-")
	_G("DPSMateX_Details"..comp.."_LogDetails_Max7"):SetText("-")
end

function DPSMateX.Modules.DetailsDamage:UpdatePie(gg, cname)
	local uArr, dArr, dTot = DetailsArr, DmgArr, DetailsTotal
	if cname then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
	end

	gg:ResetPie()
	
	-- Prepare data sorted by percentage
	local pieData = {}
	for i, val in pairs(uArr) do
		local user
		if (dArr[i][2]) and DPSMateX.Settings["mergepets"] and DPSMateX:GetUserById(dArr[i][2]) ~= (cname or DetailsUser) then 
			user=dArr[i][2]
		else 
			user=DPSMateX.CacheUser[cname or DetailsUser][1]
		end
		local percent = (db[user][val][13]*100/dTot)
		tinsert(pieData, {
			percent = percent,
			user = user,
			ability = val
		})
	end
	
	-- Sort by percentage in descending order
	table.sort(pieData, function(a, b) return a.percent > b.percent end)
	
	-- Add sorted data to pie chart
	for _, data in ipairs(pieData) do
		gg:AddPie(data.percent, nil, DPSMateX:GetUserById(data.user)..": "..DPSMateX:GetAbilityById(data.ability))
	end
end

function DPSMateX.Modules.DetailsDamage:UpdateLineGraph(gg, comp, cname)
	if not comp then comp = DPSMateX_Details.LastScroll or "" end
	if g3 then
		g3:Hide()
	end
	if g6 then
		g6:Hide()
	end	
	local sumTable
	if toggle3 then
		if comp ~= "" and comp~=nil then
			sumTable = self:GetSummarizedTable(db2, t1Comp[PSelected2], cname)
		else
			sumTable = self:GetSummarizedTable(db2, t1[PSelected])
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
		tinsert(Data1, {val[1],val[2], self:CheckProcs(_G("DPSMateX_Details"..comp).proc, val[1]+(min-1), cname)})
	end
	local colorT = {{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}
	if cname then
		colorT = {{0.2,0.8,0.2,0.8}, {0.5,0.8,0.9,0.8}}
	end
	
	gg:AddDataSeries(Data1,colorT, self:AddProcPoints(_G("DPSMateX_Details"..comp).proc, Data1, cname))
	gg:Show()
	toggle2 = false
end

function DPSMateX.Modules.DetailsDamage:UpdateStackedGraph(gg, comp, cname)
	if not comp then comp = DPSMateX_Details.LastScroll or "" end
	if g2 then
		g2:Hide()
	end
	if g5 then
		g5:Hide()
	end
	
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d1 = t1Comp
		d2 = t2Comp
		d4 = PSelected2
	end
	
	local Data1 = {}
	local label = {}
	local b = {}
	local p = {}
	local maxY = 0
	local maxX = 0
	local temp = {}
	local temp2 = {}
	if toggle3 then
		for cat, val in pairs(db2[d1[d4]][DPSMateX.CacheUser[cname or DetailsUser][1]]) do
			if cat~="i" and val["i"] then
				for c, v in pairs(val["i"]) do
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
		
		-- pet
		local user = cname or DetailsUser
		local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[user])
		if petsname and DPSMateX.Settings["mergepets"] then
			for petname,_ in pairs(petsname) do 
				if petname ~= user then
					local PetId = DPSMateX.CacheUser[petname][1]
					if db2[d1[d4]][PetId] then
						for cat, val in pairs(db2[d1[d4]][PetId]) do
							if cat~="i" and val["i"] then
								for c, v in pairs(val["i"]) do
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
					end
				end
			end
		end
		
		local min
		for cat, val in pairs(temp) do
			local pmin = DPSMateX:GetMinValue(val, 1)
			if not min or pmin<min then
				min = pmin
			end
		end
		for cat, val in pairs(temp) do
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
		for cat, val in pairs(Data1) do
			Data1[cat] = DPSMateX:ScaleDown(val, min)
		end
	
		gg:ResetData()
		gg:SetGridSpacing((maxX-min)/7,maxY/7)
	else
		for cat, val in pairs(db[DPSMateX.CacheUser[cname or DetailsUser][1]]) do
			if cat~="i" and val["i"] then
				local temp = {}
				for c, v in pairs(val["i"]) do
					local key = tonumber(strformat("%.1f", c))
					if p[key] then
						p[key] = p[key] + v
					else
						p[key] = v
					end
					local i = 1
					while true do
						if not temp[i] then
							tinsert(temp, i, {c,v})
							break
						elseif c<temp[i][1] then
							tinsert(temp, i, {c,v})
							break
						end
						i = i + 1
					end
					maxY = math.max(p[key], maxY)
					maxX = math.max(c, maxX)
				end
				local i = 1
				while true do
					if not b[i] then
						tinsert(b, i, val[13])
						tinsert(label, i, DPSMateX:GetAbilityById(cat))
						tinsert(Data1, i, temp)
						break
					elseif b[i]>=val[13] then
						tinsert(b, i, val[13])
						tinsert(label, i, DPSMateX:GetAbilityById(cat))
						tinsert(Data1, i, temp)
						break
					end
					i = i + 1
				end
			end
		end
		-- Pet
		local user = cname or DetailsUser
		local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[user])
		if petsname and DPSMateX.Settings["mergepets"] then 
			for petname,_ in pairs(petsname) do 
				if petname ~= user then
					local PetId = DPSMateX.CacheUser[petname][1]
					if db[PetId] then
						for cat, val in pairs(db[PetId]) do
							if cat~="i" and val["i"] then
								local temp = {}
								for c, v in pairs(val["i"]) do
									local key = tonumber(strformat("%.1f", c))
									if p[key] then
										p[key] = p[key] + v
									else
										p[key] = v
									end
									local i = 1
									while true do
										if not temp[i] then
											tinsert(temp, i, {c,v})
											break
										elseif c<temp[i][1] then
											tinsert(temp, i, {c,v})
											break
										end
										i = i + 1
									end
									maxY = math.max(p[key], maxY)
									maxX = math.max(c, maxX)
								end
								local i = 1
								while true do
									if not b[i] then
										tinsert(b, i, val[13])
										tinsert(label, i, DPSMateX:GetAbilityById(cat))
										tinsert(Data1, i, temp)
										break
									elseif b[i]>=val[13] then
										tinsert(b, i, val[13])
										tinsert(label, i, DPSMateX:GetAbilityById(cat))
										tinsert(Data1, i, temp)
										break
									end
									i = i + 1
								end
							end
						end
					end
				end
			end
		end
	
		gg:ResetData()
		gg:SetGridSpacing(maxX/7,maxY/7)
	end
	
	gg:AddDataSeries(Data1,{1.0,0.0,0.0,0.8}, {}, label)
	gg:Show()
	toggle2 = true
end

function DPSMateX.Modules.DetailsDamage:CreateGraphTable(comp)
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 5, 270-i*30, 376, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 57, 265, 57, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 192, 265, 192, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 252, 265, 252, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 312, 265, 312, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

function DPSMateX.Modules.DetailsDamage:ProcsDropDown()
	local arr = DPSMateX.Modules.DetailsDamage:GetAuraGainedArr(curKey)
	DPSMateX_Details.proc = "None"
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_Details_DiagramLegend_Procs, this.value)
		DPSMateX_Details.proc = this.value
		if not toggle2 then
			DPSMateX.Modules.DetailsDamage:UpdateLineGraph(g2, "")
		end
		if DetailsUserComp then
			DPSMateX.Modules.DetailsDamage:UpdateSumGraph()
		end
    end
	
	UIDropDownMenu_AddButton{
		text = "None",
		value = "None",
		func = on_click,
	}
	
	-- Adding dynamic channel
	if arr[DPSMateX.CacheUser[DetailsUser][1]] then
		for cat, val in pairs(arr[DPSMateX.CacheUser[DetailsUser][1]]) do
			local ability = DPSMateX:GetAbilityById(cat)
			if DPSMateX.Parser.procs[ability] or DPSMateX.Parser.DmgProcs[ability] then
				UIDropDownMenu_AddButton{
					text = ability,
					value = cat,
					func = on_click,
				}
			end
		end
	end
	
	if DPSMateX_Details.LastUser~=DetailsUser then
		UIDropDownMenu_SetSelectedValue(DPSMateX_Details_DiagramLegend_Procs, "None")
	end
	DPSMateX_Details.LastUser = DetailsUser
end

function DPSMateX.Modules.DetailsDamage:ProcsDropDown_CompareDamage()
	local arr = DPSMateX.Modules.DetailsDamage:GetAuraGainedArr(curKey)
	DPSMateX_Details_CompareDamage.proc = "None"
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareDamage_DiagramLegend_Procs, this.value)
		DPSMateX_Details_CompareDamage.proc = this.value
		if not toggle2 then
			DPSMateX.Modules.DetailsDamage:UpdateLineGraph(g5, "_CompareDamage", DetailsUserComp)
		end
		DPSMateX.Modules.DetailsDamage:UpdateSumGraph()
    end
	
	UIDropDownMenu_AddButton{
		text = "None",
		value = "None",
		func = on_click,
	}
	
	-- Adding dynamic channel
	if arr[DPSMateX.CacheUser[DetailsUserComp][1]] then
		for cat, val in pairs(arr[DPSMateX.CacheUser[DetailsUserComp][1]]) do
			local ability = DPSMateX:GetAbilityById(cat)
			if DPSMateX.Parser.procs[ability] or DPSMateX.Parser.DmgProcs[ability] then
				UIDropDownMenu_AddButton{
					text = ability,
					value = cat,
					func = on_click,
				}
			end
		end
	end
	
	if DPSMateX_Details_CompareDamage.LastUser~=DetailsUserComp then
		UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareDamage_DiagramLegend_Procs, "None")
	end
	DPSMateX_Details_CompareDamage.LastUser = DetailsUserComp
end

function DPSMateX.Modules.DetailsDamage:SortLineTable(t, b, cname)
	local newArr = {}
	if b then
		for cat, val in t[b][DPSMateX.CacheUser[cname or DetailsUser][1]] do
			if cat~="i" and val["i"] then
				for ca, va in val["i"] do
					local i=1
					while true do
						if (not newArr[i]) then 
							tinsert(newArr, i, {ca, va})
							break
						end
						if ca<=newArr[i][1] then
							tinsert(newArr, i, {ca, va})
							break
						end
						i=i+1
					end
				end
			end
		end
		-- Pet
		local user = cname or DetailsUser
		local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[user])
		if petsname then 
			for petname,_ in pairs(petsname) do
				if petname ~= user then
					local PetId = DPSMateX.CacheUser[petname][1]
					if t[PetId] then
						for cat, val in t[b][PetId] do
							if cat~="i" and val["i"] then
								for ca, va in val["i"] do
									local i=1
									while true do
										if (not newArr[i]) then 
											tinsert(newArr, i, {ca, va})
											break
										end
										if ca<=newArr[i][1] then
											tinsert(newArr, i, {ca, va})
											break
										end
										i=i+1
									end
								end
							end
						end
					end
				end
			end
		end
	else
		if t[DPSMateX.CacheUser[cname or DetailsUser][1]] then
			for cat, val in t[DPSMateX.CacheUser[cname or DetailsUser][1]] do
				if cat~="i" and val["i"] then
					for ca, va in val["i"] do
						local i=1
						while true do
							if (not newArr[i]) then 
								tinsert(newArr, i, {ca, va})
								break
							end
							if ca<=newArr[i][1] then
								tinsert(newArr, i, {ca, va})
								break
							end
							i=i+1
						end
					end
				end
			end
		end
		-- Pet
		local user = cname or DetailsUser
		local petsname = DPSMateX.DB:GetPetsName(DPSMateX.CacheUser[user])
		if petsname then 
			for petname, _ in pairs(petsname) do
				if petname ~= user then
					local PetId = DPSMateX.CacheUser[petname][1]
					if t[PetId] then
						for cat, val in t[PetId] do
							if cat~="i" and val["i"] then
								for ca, va in val["i"] do
									local i=1
									while true do
										if (not newArr[i]) then 
											tinsert(newArr, i, {ca, va})
											break
										end
										if ca<=newArr[i][1] then
											tinsert(newArr, i, {ca, va})
											break
										end
										i=i+1
									end
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

function DPSMateX.Modules.DetailsDamage:GetSummarizedTable(arr, b, cname)
	return DPSMateX.Sync:GetSummarizedTable(self:SortLineTable(arr, b, cname))
end

function DPSMateX.Modules.DetailsDamage:GetAuraGainedArr(k)
	local modes = {["total"]=1,["currentfight"]=2}
	for cat, val in pairs(DPSMateX.Settings["windows"][k]["options"][2]) do
		if val then
			if cat == "segmentsonly" then
				-- 返回空表，避免nil错误
				return {}
			elseif strfind(cat, "segment") then
				local num = tonumber(strsub(cat, 8))
				return DPSMateX.DPSMateXHistory["Auras"][num] or {}
			else
				return DPSMateX.DBCache.AurasGained[modes[cat]] or {}
			end
		end
	end
	return {}
end

function DPSMateX.Modules.DetailsDamage:CheckProcs(name, val, cname)
	local arr = DPSMateX.Modules.DetailsDamage:GetAuraGainedArr(curKey)
	if arr[DPSMateX.CacheUser[cname or DetailsUser][1]] then
		if arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name] then
			for i=1, DPSMateX:TableLength(arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][1]) do
				if not arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][1][i] or not arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][2][i] or arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][4] then return false end
				if val > arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][1][i] and val < arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][2][i] then
					return true
				end
			end
		end
	end
	return false
end

function DPSMateX.Modules.DetailsDamage:AddProcPoints(name, dat, cname)
	local bool, data, LastVal = false, {}, 0
	local arr = self:GetAuraGainedArr(curKey)
	if arr[DPSMateX.CacheUser[cname or DetailsUser][1]] then
		if arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name] then
			if arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][4] then
				for cat, val in pairs(dat) do
					for i=1, DPSMateX:TableLength(arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][1]) do
						if arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][1][i]<=val[1] then
							local tempbool = true
							for _, va in pairs(data) do
								if va[1] == arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][1][i] then
									tempbool = false
									break
								end
							end
							if tempbool then	
								bool = true
								tinsert(data, {arr[DPSMateX.CacheUser[cname or DetailsUser][1]][name][1][i], LastVal, {val[1], val[2]}})
							end
						end
					end
					LastVal = {val[1], val[2]}
				end
			end
		end
	end
	return {bool, data}
end

function DPSMateX.Modules.DetailsDamage:ToggleMode(bool)
	if bool then
		if toggle2 then
			self:UpdateLineGraph(g2,"")
			if DetailsUserComp then
				self:UpdateLineGraph(g5,"_CompareDamage", DetailsUserComp)
			end
		else
			self:UpdateStackedGraph(g3)
			if DetailsUserComp then
				self:UpdateStackedGraph(g6,"_CompareDamage", DetailsUserComp)
			end
		end
	else
		if toggle then
			toggle = false
			DPSMateX_Details_playerSpells:Hide()
			DPSMateX_Details_player:Hide()
			DPSMateX_Details_Diagram:Show()
			DPSMateX_Details_Log:Show()
			self:ScrollFrame_Update("")
			self:SelectDetailsButton(1,"")
			
			if DetailsUserComp then
				DPSMateX_Details_CompareDamage_playerSpells:Hide()
				DPSMateX_Details_CompareDamage_player:Hide()
				DPSMateX_Details_CompareDamage_Diagram:Show()
				DPSMateX_Details_CompareDamage_Log:Show()
				self:ScrollFrame_Update("_CompareDamage")
				self:SelectDetailsButton(1,"_CompareDamage")
			end
		else
			toggle = true
			DPSMateX_Details_playerSpells:Show()
			DPSMateX_Details_player:Show()
			DPSMateX_Details_Diagram:Hide()
			DPSMateX_Details_Log:Hide()
			self:Player_Update("")
			self:PlayerSpells_Update(1,"")
			self:SelectDetailsButton(1,"")
			
			if DetailsUserComp then
				DPSMateX_Details_CompareDamage_playerSpells:Show()
				DPSMateX_Details_CompareDamage_player:Show()
				DPSMateX_Details_CompareDamage_Diagram:Hide()
				DPSMateX_Details_CompareDamage_Log:Hide()
				self:Player_Update("_CompareDamage")
				self:PlayerSpells_Update(1, "_CompareDamage")
				self:SelectDetailsButton(1, "_CompareDamage")
			end
		end
	end
end

function DPSMateX.Modules.DetailsDamage:ToggleIndividual()
	if toggle3 then
		toggle3 = false
	else
		toggle3 = true
	end
	if toggle2 then
		self:UpdateStackedGraph(g3)
		if DetailsUserComp then 
			self:UpdateStackedGraph(g6,"_CompareDamage", DetailsUserComp)
		end
	else
		self:UpdateLineGraph(g2,"")
		if DetailsUserComp then
			self:UpdateLineGraph(g5,"_CompareDamage", DetailsUserComp)
		end
	end
	if DetailsUserComp then
		self:UpdateSumGraph()
	end
end
