local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsHealingAndAbsorbs = {}

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

function DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateDetails(obj, key)
	curKey = key
	db, cbt,ecbt = DPSMateX:GetMode(key)
	db2 = DPSMateX:GetModeByArr(DPSMateX.DBCache.EHealingTaken, key, "EHealingTaken")
	DPSMateX_Details_HealingAndAbsorbs.proc = "None"
	UIDropDownMenu_SetSelectedValue(DPSMateX_Details_HealingAndAbsorbs_DiagramLegend_Procs, "None")
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_HealingAndAbsorbs_Title:SetText(DPSMateX.L["habby"]..obj.user)
	DPSMateX_Details_HealingAndAbsorbs_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", (ecbt[obj.user] or 0)+1).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*((ecbt[obj.user] or 0)+1)/cbt).."%)")
	DPSMateX_Details_HealingAndAbsorbs:Show()
	UIDropDownMenu_Initialize(DPSMateX_Details_HealingAndAbsorbs_DiagramLegend_Procs, DPSMateX.Modules.DetailsHealingAndAbsorbs.ProcsDropDown)
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[DetailsUser], curKey)
	t1, t2, TTotal = self:EvalToggleTable()
	
	if not g then
		g=DPSMateX.Options.graph:CreateGraphPieChart("HABPieChart", DPSMateX_Details_HealingAndAbsorbs_Diagram, "CENTER", "CENTER", 0, 0, 200, 200)
		g2=DPSMateX.Options.graph:CreateGraphLine("HABLineGraph",DPSMateX_Details_HealingAndAbsorbs_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g3=DPSMateX.Options.graph:CreateStackedGraph("HABStackedGraph",DPSMateX_Details_HealingAndAbsorbs_DiagramLine,"CENTER","CENTER",0,0,950,230)
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
		self:SelectDetails_HealingAndAbsorbsButton(1,"")
	else
		self:ScrollFrame_Update("")
		self:SelectDetails_HealingAndAbsorbsButton(1,"")
	end
	self:UpdatePie(g)
	if toggle2 then
		self:UpdateStackedGraph(g3)
	else
		self:UpdateLineGraph(g2, "")
	end
	
	DPSMateX_Details_CompareHealingAndAbsorbs:Hide()
	DPSMateX_Details_CompareHealingAndAbsorbs_Graph:Hide()
	DPSMateX_Details_HealingAndAbsorbs:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)
	
	DPSMateX_Details_CompareHealingAndAbsorbs.proc = "None"
	UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareHealingAndAbsorbs_DiagramLegend_Procs, "None")
	DetailsUserComp = comp
	DPSMateX_Details_CompareHealingAndAbsorbs_Title:SetText(DPSMateX.L["habby"]..comp)
	DPSMateX_Details_CompareHealingAndAbsorbs_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", DPSMateX.CombatTime["effective"][key][comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*(DPSMateX.CombatTime["effective"][key][comp] or 0)/cbt).."%)")
	UIDropDownMenu_Initialize(DPSMateX_Details_CompareHealingAndAbsorbs_DiagramLegend_Procs, DPSMateX.Modules.DetailsHealingAndAbsorbs.ProcsDropDown_CompareHealingAndAbsorbs)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
	t1Comp, t2Comp, TTotalComp = self:EvalToggleTable(comp)
	
	if not g4 then
		g4=DPSMateX.Options.graph:CreateGraphPieChart("HABPieChartComp", DPSMateX_Details_CompareHealingAndAbsorbs_Diagram, "CENTER", "CENTER", 0, 0, 200, 200)
		g5=DPSMateX.Options.graph:CreateGraphLine("HABLineGraphComp",DPSMateX_Details_CompareHealingAndAbsorbs_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g6=DPSMateX.Options.graph:CreateStackedGraph("HABStackedGraphComp",DPSMateX_Details_CompareHealingAndAbsorbs_DiagramLine,"CENTER","CENTER",0,0,950,230)
		g6:SetGridColor({0.5,0.5,0.5,0.5})
		g6:SetAxisDrawing(true,true)
		g6:SetAxisColor({1.0,1.0,1.0,1.0})
		g6:SetAutoScale(true)
		g6:SetYLabels(true, false)
		g6:SetXLabels(true)
		g7=DPSMateX.Options.graph:CreateGraphLine("HABLineGraphSum",DPSMateX_Details_CompareHealingAndAbsorbs_Graph,"CENTER","CENTER",0,0,1950,230)
	end
	
	DPSMateX_Details_CompareHealingAndAbsorbs:Show()
	if toggle then
		DPSMateX_Details_CompareHealingAndAbsorbs_playerSpells:Show()
		DPSMateX_Details_CompareHealingAndAbsorbs_player:Show()
		DPSMateX_Details_CompareHealingAndAbsorbs_Diagram:Hide()
		DPSMateX_Details_CompareHealingAndAbsorbs_Log:Hide()
		self:Player_Update("Compare")
		self:PlayerSpells_Update(1, "Compare")
		self:SelectDetails_HealingAndAbsorbsButton(1, "Compare")
	else
		DPSMateX_Details_CompareHealingAndAbsorbs_playerSpells:Hide()
		DPSMateX_Details_CompareHealingAndAbsorbs_player:Hide()
		DPSMateX_Details_CompareHealingAndAbsorbs_Diagram:Show()
		DPSMateX_Details_CompareHealingAndAbsorbs_Log:Show()
		self:ScrollFrame_Update("Compare")
		self:SelectDetails_HealingAndAbsorbsButton(1, "Compare")
	end
	self:UpdatePie(g4, comp)
	if toggle2 then
		self:UpdateStackedGraph(g6, "Compare", comp)
	else
		self:UpdateLineGraph(g5, "Compare", comp)
	end
	self:UpdateSumGraph()
	
	DPSMateX_Details_CompareHealingAndAbsorbs_Graph:Show()
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateSumGraph()
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
		tinsert(ata, {val[1],val[2], self:CheckProcs(DPSMateX_Details_CompareHealingAndAbsorbs.proc, val[1]+min+1, DetailsUserComp)})
	end
	
	local Data2={{0,0}}
	for cat, val in DPSMateX:ScaleDown(sumTableTwo, minT) do
		tinsert(Data2, {val[1],val[2], self:CheckProcs(DPSMateX_Details_HealingAndAbsorbs.proc, val[1]+minT+1)})
	end

	g7:AddDataSeries(ata,{{0.2,0.8,0.2,0.8}, {0.5,0.8,0.9,0.8}}, self:AddProcPoints(DPSMateX_Details_CompareHealingAndAbsorbs.proc, ata, DetailsUserComp))
	g7:AddDataSeries(Data2,{{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}, self:AddProcPoints(DPSMateX_Details_HealingAndAbsorbs.proc, Data2))
	g7:Show()
end

local pairs = pairs

function DPSMateX.Modules.DetailsHealingAndAbsorbs:EvalToggleTable(cname)
	local a,b = {},{}
	local d = 0
	local hackTemp = {}
	for cat, val in db2 do
		if val[DPSMateX.CacheUser[cname or DetailsUser][1]] then
			local CV = 0
			local c = {[1] = 0,[2] = {},[3] = {}}
			for p, v in val[DPSMateX.CacheUser[cname or DetailsUser][1]] do
				CV = CV + v[1]
				local i = 1
				while true do
					if (not c[2][i]) then
						tinsert(c[3], i, v)
						tinsert(c[2], i, p)
						break
					else
						if c[3][i][1] < v[1] then
							tinsert(c[3], i, v)
							tinsert(c[2], i, p)
							break
						end
					end
					i=i+1
				end
			end
			c[1] = CV
			hackTemp[cat] = {}
			tinsert(hackTemp[cat], c)
			d = d + CV
		end
	end
	
	-- Absorbs
	for cat, val in DPSMateX.DBCache.Absorbs[curKey] do
		if val[DPSMateX.CacheUser[cname or DetailsUser][1]] then
			local CV = 0
			local c = {[1] = 0,[2] = {},[3] = {}}
			for ca, va in val[DPSMateX.CacheUser[cname or DetailsUser][1]] do
				local dmg = 5
				local hit, hitav, hitmin, hitmax = 0, 0, 0, 0
				local shieldname = DPSMateX:GetAbilityById(ca)
				if ca~="i" then
					for ce, ve in pairs(va) do -- 1
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
										p = ceil((1/totalHits)*((DPSMateX.CacheUser[cname or DetailsUser][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[shieldname]*0.33)
									end
									PerShieldAbsorb=PerShieldAbsorb+ss*p
								end
							end
						end
						if ve["i"][1]==1 then
							PerShieldAbsorb=PerShieldAbsorb+ve["i"][2]
						end
						dmg = dmg+PerShieldAbsorb
						if PerShieldAbsorb>hitmax then hitmax = PerShieldAbsorb end
						if (PerShieldAbsorb<hitmin or hitmin == 0) and PerShieldAbsorb>0 then hitmin = PerShieldAbsorb end
						hitav = DPSMateX.DB:WeightedAverage(hitav, PerShieldAbsorb, hit, 1)
						hit=hit+1
					end
				
					local temp ={
						[1] = dmg,
						[2] = hit,
						[3] = 0,
						[4] = hitav,
						[5] = 0,
						[6] = hitmin,
						[7] = hitmax,
						[8] = 0,
						[9] = 0
					}
					
					local i = 1
					while true do
						if (not c[2][i]) then
							tinsert(c[3], i, temp)
							tinsert(c[2], i, ca)
							break
						else
							if c[3][i][1] < dmg then
								tinsert(c[3], i, temp)
								tinsert(c[2], i, ca)
								break
							end
						end
						i=i+1
					end
					CV = CV + dmg
				end
			end
			if CV>0 then
				c[1] = CV
				if not hackTemp[cat] then
					hackTemp[cat] = {}
				end
				tinsert(hackTemp[cat], c)
				d = d + CV
			end
		end
	end
	-- Summing same player together
	for cat, val in pairs(hackTemp) do
		local totVal = 0;
		local newAbArr = {[1] = 0,[2] = {},[3] = {}}
		for ca, va in pairs(val) do
			for c, v in pairs(va[3]) do
				local p=1;
				while true do
					if (not newAbArr[2][p]) then
						tinsert(newAbArr[3], p, v)
						tinsert(newAbArr[2], p, va[2][c])
						break
					elseif newAbArr[3][p][1]<v[1] then
						tinsert(newAbArr[3], p, v)
						tinsert(newAbArr[2], p, va[2][c])
						break
					end
					p = p + 1
				end
			end
			newAbArr[1] = newAbArr[1] + va[1]
			totVal = totVal + va[1]
		end
		local i = 1
		while true do
			if (not a[i]) then
				tinsert(b, i, newAbArr)
				tinsert(a, i, cat)
				break
			else
				if b[i][1] < totVal then
					tinsert(b, i, newAbArr)
					tinsert(a, i, cat)
					break
				end
			end
			i=i+1
		end
	end
	return a,b,d
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:ScrollFrame_Update(comp)
	if not comp then comp = DPSMateX_Details_HealingAndAbsorbs.LastScroll or "" end
	local line, lineplusoffset
	local obj = _G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollFrame")
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
			local ability = DPSMateX:GetAbilityById(uArr[lineplusoffset])
			_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line.."_Name"):SetText(ability)
			_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line.."_Value"):SetText(dArr[lineplusoffset][1].." ("..strformat("%.2f", (dArr[lineplusoffset][1]*100/dTot)).."%)")
			_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line):SetWidth(335)
				_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line.."_Name"):SetWidth(225)
			else
				_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line):SetWidth(320)
				_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line.."_Name"):SetWidth(210)
			end
			_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line):Show()
		else
			_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line):Hide()
		end
		_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line.."_selected"):Hide()
		if dSel == lineplusoffset then
			_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:SelectDetails_HealingAndAbsorbsButton(i, comp, cname)
	if not comp then comp = DPSMateX_Details_HealingAndAbsorbs.LastScroll or "" end
	local pathh = ""
	local path,obj,lineplusoffset
	local uArr, dSel, d2, dArr = DetailsArr, DetailsSelected, t2, DmgArr
	local arr = DPSMateX.DBCache.EHealing[curKey]
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dSel = DetailsSelectedComp
		if not cname then
			cname = DetailsUserComp
		end
		d2 = t2Comp
	end
	local user, pet = DPSMateX.CacheUser[cname or DetailsUser][1], ""
	if toggle then
		pathh = "DPSMateX_Details_"..comp.."HealingAndAbsorbs_playerSpells"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
		if d2[obj.id] then
			path = d2[obj.id][3][lineplusoffset]
		end
	else
		pathh = "DPSMateX_Details_"..comp.."HealingAndAbsorbs_Log"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
		if arr[user] then
			path = arr[user][tonumber(uArr[lineplusoffset])]
		end
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
	local hit, crit, hitav, critav, hitMin, hitMax, critMin, critMax, total, max = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
	if dArr[lineplusoffset] and dArr[lineplusoffset][2] and not toggle then -- IsAbsorb
		local abString = DPSMateX:GetAbilityById(tonumber(uArr[lineplusoffset]))
		for cat, val in DPSMateX.DBCache.Absorbs[curKey] do 
			for ca, va in val do
				if ca == DPSMateX.CacheUser[cname or DetailsUser][1] then -- Owner
					for c, v in va do -- Every Ability
						if c==tonumber(uArr[lineplusoffset]) then
							for ce, ve in v do -- Every individual shield
								local PerShieldAbsorb = 0
								for cet, vel in ve do
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
											if p>DPSMateX.DB.FixedShieldAmounts[abString] then
												p = DPSMateX.DB.FixedShieldAmounts[abString]
											end
											if p==5 or dmg==0 then
												p = ceil((1/totalHits)*((DPSMateX.CacheUser[cname or DetailsUser][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[abString]*0.33)
											end
											PerShieldAbsorb=PerShieldAbsorb+ss*p
											
											if PerShieldAbsorb>hitMax then hitMax = PerShieldAbsorb end
											if (PerShieldAbsorb<hitMin or hitMin == 0) and PerShieldAbsorb>0 then hitMin = PerShieldAbsorb end
											hitav = DPSMateX.DB:WeightedAverage(hitav, PerShieldAbsorb, hit, ss)
											hit=hit+ss
										end
									end
								end
								if ve["i"][1]==1 then
									PerShieldAbsorb=PerShieldAbsorb+ve["i"][2]
								end
							end
						end
					end
				end
			end
		end
		total, max = hit, hit
	elseif path then
		hit, crit, hitav, critav, hitMin, hitMax, critMin, critMax = path[2], path[3], path[4], path[5], path[6], path[7], path[8], path[9]
		total, max = hit+crit, DPSMateX:TMax({hit, crit})
	end
	
	-- Hit
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount0_Amount"):SetText(hit)
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount0_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount0_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount0_StatusBar"):SetStatusBarColor(0.3,0.7,1.0,1)
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Average0"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Min0"):SetText(hitMin)
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Max0"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount1_Amount"):SetText(crit)
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount1_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount1_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Amount1_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Average1"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Min1"):SetText(critMin)
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs_Max1"):SetText(critMax)
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:Player_Update(comp)
	if not comp then comp = DPSMateX_Details_HealingAndAbsorbs.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."HealingAndAbsorbs_player"
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
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Name"):SetTextColor(r,g,b)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[lineplusoffset][1].." ("..strformat("%.2f", (d2[lineplusoffset][1]*100/d3)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\"..img)
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

function DPSMateX.Modules.DetailsHealingAndAbsorbs:PlayerSpells_Update(i, comp)
	if not comp then comp = DPSMateX_Details_HealingAndAbsorbs.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."HealingAndAbsorbs_playerSpells"
	local obj = _G(path.."_ScrollFrame")
	obj.id = (i + FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_player_ScrollFrame"))) or obj.id
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d2 = t2Comp
		d4 = PSelected2
	end
	local len = DPSMateX:TableLength(d2[i][2])

	FauxScrollFrame_Update(obj,len,10,24)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d2[obj.id][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(d2[obj.id][2][lineplusoffset]) or "Sinister Strike"
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[obj.id][3][lineplusoffset][1].." ("..strformat("%.2f", (d2[obj.id][3][lineplusoffset][1]*100/d2[obj.id][1])).."%)")
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
		if d4 == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
	if comp ~= "" and comp~=nil then
		PSelected2 = obj.id
	else
		PSelected = obj.id
	end
	for p=1, 8 do
		_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_player_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_player_ScrollButton"..i.."_selected"):Show()
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

function DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdatePie(gg, cname)
	local dArr, dTot, uArr = DmgArr, DetailsTotal, DetailsArr
	if cname then
		dArr = DmgArrComp
		uArr = DetailsArrComp
		dTot = DetailsTotalComp
	end
	gg:ResetPie()
	for cat, val in dArr do
		gg:AddPie(val[1]*100/dTot, 0, DPSMateX:GetAbilityById(uArr[cat]))
	end
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateLineGraph(gg, comp, cname)
	if not comp then comp = DPSMateX_Details_HealingAndAbsorbs.LastScroll or "" end
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
		tinsert(Data1, {val[1],val[2], self:CheckProcs(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs").proc, val[1]+min+1, cname)})
	end
	local colorT = {{1.0,0.0,0.0,0.8}, {1.0,1.0,0.0,0.8}}
	if cname then
		colorT = {{0.2,0.8,0.2,0.8}, {0.5,0.8,0.9,0.8}}
	end

	gg:AddDataSeries(Data1,colorT, self:AddProcPoints(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs").proc, Data1, cname))
	gg:Show()
	toggle2=false
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateStackedGraph(gg, comp, cname)
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
	if toggle3 then
		if db2[d1[d4]] then
			if db2[d1[d4]][DPSMateX.CacheUser[cname or DetailsUser][1]] then
				for cat, val in db2[d1[d4]][DPSMateX.CacheUser[cname or DetailsUser][1]] do
					if cat~="i" and val["i"] then
						local temp = {}
						for c, v in val["i"] do
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
								elseif c<=temp[i][1] then
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
								tinsert(b, i, val[1])
								tinsert(label, i, DPSMateX:GetAbilityById(cat))
								tinsert(Data1, i, temp)
								break
							elseif b[i]>=val[1] then
								tinsert(b, i, val[1])
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
		-- Add absorbs points
		local temp = {}
		if DPSMateX.DBCache.Absorbs[curKey][d1[d4]] then
			if DPSMateX.DBCache.Absorbs[curKey][d1[d4]][DPSMateX.CacheUser[cname or DetailsUser][1]] then
				for ca, va in DPSMateX.DBCache.Absorbs[curKey][d1[d4]][DPSMateX.CacheUser[cname or DetailsUser][1]]["i"] do
					local i, dmg = 1, 5
					if DPSMateX.DBCache.DamageTaken[1][d1[d4]] then
						if DPSMateX.DBCache.DamageTaken[1][d1[d4]][va[2]] then
							if DPSMateX.DBCache.DamageTaken[1][d1[d4]][va[2]][va[3]] then
								dmg = DPSMateX.DBCache.DamageTaken[1][d1[d4]][va[2]][va[3]][14]
								if dmg>DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])] then
									dmg = DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]
								end
							end
						end
					end
					if dmg==5 or dmg==0 then
						dmg = ceil((1/15)*((DPSMateX.CacheUser[cname or DetailsUser][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]*0.33)
					end
					if va[4] then
						dmg = dmg + va[4]
					end
					if dmg>0 then
						if not temp[va[5]] then
							temp[va[5]] = {}
						end
						while true do
							if (not temp[va[5]][i]) then
								tinsert(temp[va[5]], i, {va[1], dmg})
								break
							elseif va[1]<=temp[va[5]][i][1] then
								tinsert(temp[va[5]], i, {va[1], dmg})
								break
							end
							i=i+1
						end
					end
				end
			end
		end
		for cat, val in temp do
			tinsert(label, 1, DPSMateX:GetAbilityById(cat))
			tinsert(Data1, 1, val)
		end
		
		local min
		for cat, val in Data1 do
			local pmin = DPSMateX:GetMinValue(val, 1)
			if not min or pmin<min then
				min = pmin
			end
		end
		for cat, val in Data1 do
			Data1[cat] = DPSMateX:ScaleDown(val, min)
		end
		
		gg:ResetData()
		gg:SetGridSpacing((maxX-(min or 0))/7,maxY/7)	
	else
		if DPSMateX.DBCache.EHealing[curKey][DPSMateX.CacheUser[cname or DetailsUser][1]] then
			for cat, val in DPSMateX.DBCache.EHealing[curKey][DPSMateX.CacheUser[cname or DetailsUser][1]] do
				if cat~="i" and val["i"] then
					local temp = {}
					for c, v in val["i"] do
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
							elseif c<=temp[i][1] then
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
							tinsert(b, i, val[1])
							tinsert(label, i, DPSMateX:GetAbilityById(cat))
							tinsert(Data1, i, temp)
							break
						elseif b[i]>=val[1] then
							tinsert(b, i, val[1])
							tinsert(label, i, DPSMateX:GetAbilityById(cat))
							tinsert(Data1, i, temp)
							break
						end
						i = i + 1
					end
				end
			end
		end
		-- Add absorbs points
		local temp = {}
		for cat, val in DPSMateX.DBCache.Absorbs[curKey] do
			if val[DPSMateX.CacheUser[cname or DetailsUser][1]] then
				for ca, va in val[DPSMateX.CacheUser[cname or DetailsUser][1]]["i"] do
					local i, dmg = 1, 5
					if DPSMateX.DBCache.DamageTaken[1][cat] then
						if DPSMateX.DBCache.DamageTaken[1][cat][va[2]] then
							if DPSMateX.DBCache.DamageTaken[1][cat][va[2]][va[3]] then
								dmg = DPSMateX.DBCache.DamageTaken[1][cat][va[2]][va[3]][14]
								if dmg>DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])] then
									dmg = DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]
								end
							end
						end
					end
					if dmg==5 or dmg==0 then
						dmg = ceil((1/15)*((DPSMateX.CacheUser[cname or DetailsUser][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]*0.33)
					end
					if va[4] then
						dmg = dmg + va[4]
					end
					if dmg>0 then
						if not temp[va[5]] then
							temp[va[5]] = {}
						end
						while true do
							if (not temp[va[5]][i]) then
								tinsert(temp[va[5]], i, {va[1], dmg})
								break
							elseif va[1]<=temp[va[5]][i][1] then
								tinsert(temp[va[5]], i, {va[1], dmg})
								break
							end
							i=i+1
						end
					end
				end
			end
		end
		for cat, val in temp do
			tinsert(label, 1, DPSMateX:GetAbilityById(cat))
			tinsert(Data1, 1, val)
		end
		
		gg:ResetData()
		gg:SetGridSpacing(maxX/7,maxY/7)
	end
	
	gg:AddDataSeries(Data1,{1.0,0.0,0.0,0.8}, {}, label)
	gg:Show()
	toggle2 = true
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs"), 5, 270-i*30, 370, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs"), 57, 265, 57, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs"), 192, 265, 192, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs"), 252, 265, 252, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."HealingAndAbsorbs_LogDetails_HealingAndAbsorbs"), 312, 265, 312, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:ProcsDropDown()
	local arr = DPSMateX.Modules.DetailsHealingAndAbsorbs:GetAuraGainedArr(curKey)
	DPSMateX_Details_HealingAndAbsorbs.proc = "None"
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_Details_HealingAndAbsorbs_DiagramLegend_Procs, this.value)
		DPSMateX_Details_HealingAndAbsorbs.proc = this.value
		if not toggle2 then
			DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateLineGraph(g2, "")
		end
		if DetailsUserComp then
			DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateSumGraph()
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
			if DPSMateX:TContains(DPSMateX.Parser.procs, ability) then
				UIDropDownMenu_AddButton{
					text = ability,
					value = cat,
					func = on_click,
				}
			end
		end
	end
	
	if DPSMateX_Details_HealingAndAbsorbs.LastUser~=DetailsUser then
		UIDropDownMenu_SetSelectedValue(DPSMateX_Details_HealingAndAbsorbs_DiagramLegend_Procs, "None")
	end
	DPSMateX_Details_HealingAndAbsorbs.LastUser = DetailsUser
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:ProcsDropDown_CompareHealingAndAbsorbs()
	local arr = DPSMateX.Modules.DetailsHealingAndAbsorbs:GetAuraGainedArr(curKey)
	DPSMateX_Details_CompareHealingAndAbsorbs.proc = "None"
	
    local function on_click()
        UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareHealingAndAbsorbs_DiagramLegend_Procs, this.value)
		DPSMateX_Details_CompareHealingAndAbsorbs.proc = this.value
		if not toggle2 then
			DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateLineGraph(g5, "Compare", DetailsUserComp)
		end
		if DetailsUserComp then
			DPSMateX.Modules.DetailsHealingAndAbsorbs:UpdateSumGraph()
		end
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
			if DPSMateX:TContains(DPSMateX.Parser.procs, ability) then
				UIDropDownMenu_AddButton{
					text = ability,
					value = cat,
					func = on_click,
				}
			end
		end
	end
	
	if DPSMateX_Details_CompareHealingAndAbsorbs.LastUser~=DetailsUserComp then
		UIDropDownMenu_SetSelectedValue(DPSMateX_Details_CompareHealingAndAbsorbs_DiagramLegend_Procs, "None")
	end
	DPSMateX_Details_CompareHealingAndAbsorbs.LastUser = DetailsUserComp
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:SortLineTable(arr, b, cname)
	local newArr = {}
	if b then
		if DPSMateX.DBCache.Absorbs[curKey][b] then
			if DPSMateX.DBCache.Absorbs[curKey][b][DPSMateX.CacheUser[cname or DetailsUser][1]] then
				for ca, va in DPSMateX.DBCache.Absorbs[curKey][b][DPSMateX.CacheUser[cname or DetailsUser][1]]["i"] do
					local i, dmg = 1, 5
					if DPSMateX.DBCache.DamageTaken[1][b] then
						if DPSMateX.DBCache.DamageTaken[1][b][va[2]] then
							if DPSMateX.DBCache.DamageTaken[1][b][va[2]][va[3]] then
								dmg = DPSMateX.DBCache.DamageTaken[1][b][va[2]][va[3]][14]
								if dmg>DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])] then
									dmg = DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]
								end
							end
						end
					end
					if dmg==5 or dmg==0 then
						dmg = ceil((1/15)*((DPSMateX.CacheUser[cname or DetailsUser][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]*0.33)
					end
					if va[4] then
						dmg = dmg + va[4]
					end
					if dmg>0 then
						while true do
							if (not newArr[i]) then
								tinsert(newArr, i, {va[1], dmg})
								break
							else
								if newArr[i][1] > va[1] then
									tinsert(newArr, i, {va[1], dmg})
									break
								end
							end
							i=i+1
						end
					end
				end
			end
		end
		if arr[b] then
			if arr[b][DPSMateX.CacheUser[cname or DetailsUser][1]] then
				for cat, val in arr[b][DPSMateX.CacheUser[cname or DetailsUser][1]] do
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
	else
		for cat, val in DPSMateX.DBCache.Absorbs[curKey] do
			if val[DPSMateX.CacheUser[cname or DetailsUser][1]] then
				for ca, va in val[DPSMateX.CacheUser[cname or DetailsUser][1]]["i"] do
					local i, dmg = 1, 5
					if DPSMateX.DBCache.DamageTaken[1][cat] then
						if DPSMateX.DBCache.DamageTaken[1][cat][va[2]] then
							if DPSMateX.DBCache.DamageTaken[1][cat][va[2]][va[3]] then
								dmg = DPSMateX.DBCache.DamageTaken[1][cat][va[2]][va[3]][14]
								if dmg>DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])] then
									dmg = DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]
								end
							end
						end
					end
					if dmg==5 or dmg==0 then
						dmg = ceil((1/15)*((DPSMateX.CacheUser[cname or DetailsUser][8] or 60)/60)*DPSMateX.DB.FixedShieldAmounts[DPSMateX:GetAbilityById(va[5])]*0.33)
					end
					if va[4] then
						dmg = dmg + va[4]
					end
					if dmg>0 then
						while true do
							if (not newArr[i]) then
								tinsert(newArr, i, {va[1], dmg})
								break
							else
								if newArr[i][1] > va[1] then
									tinsert(newArr, i, {va[1], dmg})
									break
								end
							end
							i=i+1
						end
					end
				end
			end
		end
		if DPSMateX.DBCache.EHealing[curKey][DPSMateX.CacheUser[cname or DetailsUser][1]] then
			for cat, val in DPSMateX.DBCache.EHealing[curKey][DPSMateX.CacheUser[cname or DetailsUser][1]] do
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
	return newArr
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:GetSummarizedTable(arr, b, cname)
	return DPSMateX.Sync:GetSummarizedTable(self:SortLineTable(arr, b, cname))
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:GetAuraGainedArr(k)
	local modes = {["total"]=1,["currentfight"]=2}
	for cat, val in pairs(DPSMateX.Settings["windows"][k]["options"][2]) do
		if val then
			if strfind(cat, "segment") then
				local num = tonumber(strsub(cat, 8))
				return DPSMateX.DPSMateXHistory["Auras"][num]
			else
				return DPSMateX.DBCache.AurasGained[modes[cat]]
			end
		end
	end
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:CheckProcs(name, val, cname)
	local arr = self:GetAuraGainedArr(curKey)
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

function DPSMateX.Modules.DetailsHealingAndAbsorbs:AddProcPoints(name, dat, cname)
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

function DPSMateX.Modules.DetailsHealingAndAbsorbs:ToggleMode(bool)
	if bool then
		if toggle2 then
			self:UpdateLineGraph(g2,"")
			if DetailsUserComp then
				self:UpdateLineGraph(g5,"Compare", DetailsUserComp)
			end
		else
			self:UpdateStackedGraph(g3)
			if DetailsUserComp then
				self:UpdateStackedGraph(g6,"Compare", DetailsUserComp)
			end
		end
	else
		if toggle then
			toggle = false
			self:ScrollFrame_Update("")
			self:SelectDetails_HealingAndAbsorbsButton(1,"")
			DPSMateX_Details_HealingAndAbsorbs_playerSpells:Hide()
			DPSMateX_Details_HealingAndAbsorbs_player:Hide()
			DPSMateX_Details_HealingAndAbsorbs_Diagram:Show()
			DPSMateX_Details_HealingAndAbsorbs_Log:Show()
			
			if DetailsUserComp then
				self:ScrollFrame_Update("Compare")
				self:SelectDetails_HealingAndAbsorbsButton(1, "Compare")
				DPSMateX_Details_CompareHealingAndAbsorbs_playerSpells:Hide()
				DPSMateX_Details_CompareHealingAndAbsorbs_player:Hide()
				DPSMateX_Details_CompareHealingAndAbsorbs_Diagram:Show()
				DPSMateX_Details_CompareHealingAndAbsorbs_Log:Show()
			end
		else
			toggle = true
			self:Player_Update("")
			self:PlayerSpells_Update(1,"")
			self:SelectDetails_HealingAndAbsorbsButton(1,"")
			DPSMateX_Details_HealingAndAbsorbs_playerSpells:Show()
			DPSMateX_Details_HealingAndAbsorbs_player:Show()
			DPSMateX_Details_HealingAndAbsorbs_Diagram:Hide()
			DPSMateX_Details_HealingAndAbsorbs_Log:Hide()
			
			if DetailsUserComp then
				self:Player_Update("Compare")
				self:PlayerSpells_Update(1, "Compare")
				self:SelectDetails_HealingAndAbsorbsButton(1, "Compare")
				DPSMateX_Details_CompareHealingAndAbsorbs_playerSpells:Show()
				DPSMateX_Details_CompareHealingAndAbsorbs_player:Show()
				DPSMateX_Details_CompareHealingAndAbsorbs_Diagram:Hide()
				DPSMateX_Details_CompareHealingAndAbsorbs_Log:Hide()
			end
		end
	end
end

function DPSMateX.Modules.DetailsHealingAndAbsorbs:ToggleIndividual()
	if toggle3 then
		toggle3 = false
	else
		toggle3 = true
	end
	if toggle2 then
		self:UpdateStackedGraph(g3)
		if DetailsUserComp then 
			self:UpdateStackedGraph(g6,"Compare", DetailsUserComp)
		end
	else
		self:UpdateLineGraph(g2,"")
		if DetailsUserComp then
			self:UpdateLineGraph(g5,"Compare", DetailsUserComp)
		end
	end
	if DetailsUserComp then
		self:UpdateSumGraph()
	end
end