local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsOHealingTaken = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local strformat = string.format
local toggle, toggle3 = false, false

function DPSMateX.Modules.DetailsOHealingTaken:UpdateDetails(obj, key)
	DPSMateX_Details_CompareOHealingTaken:Hide()
	
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_OHealingTaken_Title:SetText(DPSMateX.L["ohealtakenby"]..obj.user)
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[DetailsUser], curKey)
	DPSMateX_Details_OHealingTaken:Show()
	self:ScrollFrame_Update("")
	self:SelectCreatureButton(1,"")
	self:SelectDetailsButton(1,1,"")

		DPSMateX_Details_OHealingTaken:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsOHealingTaken:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareOHealingTaken_Title:SetText(DPSMateX.L["ohealtakenby"]..comp)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)

	DPSMateX_Details_CompareOHealingTaken:Show()
	self:ScrollFrame_Update("Compare", comp)
	self:SelectCreatureButton(1, "Compare", comp)
	self:SelectDetailsButton(1,1, "Compare", comp)
	
	end

function DPSMateX.Modules.DetailsOHealingTaken:ScrollFrame_Update(comp)
	if not comp then comp = DPSMateX_Details_OHealingTaken.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."OHealingTaken_LogCreature"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedComp
	end
	local len = DPSMateX:TableLength(uArr)

	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if uArr[lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(uArr[lineplusoffset])
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Name"):SetTextColor(r,g,b)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[lineplusoffset][1].." ("..strformat("%.2f", (dArr[lineplusoffset][1]*100/dTot)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\"..img)
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(235*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((235)*DPSMateX.DetailLayout.xScale-142.32)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((220)*DPSMateX.DetailLayout.xScale-142.32)
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

function DPSMateX.Modules.DetailsOHealingTaken:SelectCreatureButton(i, comp)
	if not comp then comp = DPSMateX_Details_OHealingTaken.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."OHealingTaken_Log"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		DetailsSelectedComp = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."OHealingTaken_LogCreature_ScrollFrame"))
		dSel = DetailsSelectedComp
	else
		DetailsSelected = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."OHealingTaken_LogCreature_ScrollFrame"))
		dSel = DetailsSelected
	end
	local len = DPSMateX:TableLength(dArr[i][2])

	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	obj.index = dSel
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[dSel][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(dArr[dSel][2][lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[dSel][3][lineplusoffset].." ("..strformat("%.2f", (dArr[dSel][3][lineplusoffset]*100/dArr[dSel][1])).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(335*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((335)*DPSMateX.DetailLayout.xScale-142.32)
			else
				_G(path.."_ScrollButton"..line):SetWidth(320*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((320)*DPSMateX.DetailLayout.xScale-142.32)
			end
			_G(path.."_ScrollButton"..line):Show()
		else
			_G(path.."_ScrollButton"..line):Hide()
		end
		_G(path.."_ScrollButton"..line.."_selected"):Hide()
		_G(path.."_ScrollButton1_selected"):Show()
	end
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."OHealingTaken_LogCreature_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogCreature_ScrollButton"..i.."_selected"):Show()
	self:SelectDetailsButton(DetailsSelected,1, comp)
	end

function DPSMateX.Modules.DetailsOHealingTaken:SelectDetailsButton(p,i, comp, cname)
	if not comp then comp = DPSMateX_Details_OHealingTaken.LastScroll or "" end
	local obj = _G("DPSMateX_Details_"..comp.."OHealingTaken_Log_ScrollFrame")
	local lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
	local uArr, dArr, dSel = DetailsArr, DmgArr, DetailsSelected
	
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."OHealingTaken_Log_ScrollButton"..p.."_selected"):Hide()
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
	_G("DPSMateX_Details_"..comp.."OHealingTaken_Log_ScrollButton"..i.."_selected"):Show()
	
	local path = db[DPSMateX.CacheUser[cname or DetailsUser][1]][creature][ability]
	local hit, crit, hitav, critav, hitMin, hitMax, critMin, critMax = path[2], path[3], path[4], path[5], path[6], path[7], path[8], path[9]
	local total, max = hit+crit, DPSMateX:TMax({hit, crit})
	
	-- Hit
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount1_Amount"):SetText(hit)
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount1_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount1_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount1_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Average1"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Min1"):SetText(hitMin)
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Max1"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount2_Amount"):SetText(crit)
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount2_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount2_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Amount2_StatusBar"):SetStatusBarColor(0.9,0.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Average2"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Min2"):SetText(critMin)
	_G("DPSMateX_Details_"..comp.."OHealingTaken_LogDetails_Max2"):SetText(critMax)
end

function DPSMateX.Modules.DetailsOHealingTaken:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."OHealingTaken_Log"), 352, 270-i*30, 717, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."OHealingTaken_Log"), 402, 265, 402, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."OHealingTaken_Log"), 537, 265, 537, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."OHealingTaken_Log"), 597, 265, 597, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."OHealingTaken_Log"), 657, 265, 657, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
end

