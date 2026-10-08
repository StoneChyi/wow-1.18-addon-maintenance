local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.DetailsAbsorbsTaken = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected, DetailsSelectedTwo, DetailsSelectedThree  = {}, 0, {}, "", 1, 1, 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp, DetailsSelectedTwoComp, DetailsSelectedThreeComp  = {}, 0, {}, "", 1, 1, 1
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local strformat = string.format

function DPSMateX.Modules.DetailsAbsorbsTaken:UpdateDetails(obj, key)
	DPSMateX_Details_CompareAbsorbsTaken:Hide()
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	
	DetailsSelected, DetailsSelectedTwo, DetailsSelectedThree = 1, 1, 1
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_AbsorbsTaken_Title:SetText(DPSMateX.L["absorbstakenby"]..obj.user)
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[DetailsUser], curKey)
	DPSMateX_Details_AbsorbsTaken:Show()
	self:ScrollFrame_Update("")
	self:SelectCreatureButton(1,"")
	self:SelectCauseButton(1,1,"")
	self:SelectCauseABButton(1,1,1,"")
		DPSMateX_Details_AbsorbsTaken:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsAbsorbsTaken:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	
	DetailsSelectedComp, DetailsSelectedTwoComp, DetailsSelectedThreeComp = 1, 1, 1
	DetailsUserComp = comp
	DPSMateX_Details_CompareAbsorbsTaken_Title:SetText(DPSMateX.L["absorbstakenby"]..comp)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
	DPSMateX_Details_CompareAbsorbsTaken:Show()
	self:ScrollFrame_Update("Compare")
	self:SelectCreatureButton(1, "Compare")
	self:SelectCauseButton(1,1, "Compare")
	self:SelectCauseABButton(1,1,1, "Compare")
	end

function DPSMateX.Modules.DetailsAbsorbsTaken:ScrollFrame_Update(comp)
	comp = comp or DPSMateX_Details_AbsorbsTaken.LastScroll
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."AbsorbsTaken_LogCreature"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp~="" and comp then
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
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(125*DPSMateX.DetailLayout.xScale)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(110*DPSMateX.DetailLayout.xScale)
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

function DPSMateX.Modules.DetailsAbsorbsTaken:SelectCreatureButton(i, comp)
	comp = comp or DPSMateX_Details_AbsorbsTaken.LastScroll
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."AbsorbsTaken_Log"
	local obj = _G(path.."_ScrollFrame")
	if i then
		obj.index = i + FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogCreature_ScrollFrame"))
	end
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelectedTwo
	if comp~="" and comp then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedTwoComp
		DetailsSelectedComp = obj.index
	else
		DetailsSelected = obj.index
	end
	local len = DPSMateX:TableLength(dArr[obj.index][2])
	
	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[obj.index][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(dArr[obj.index][2][lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[obj.index][3][lineplusoffset][1].." ("..strformat("%.2f", (dArr[obj.index][3][lineplusoffset][1]*100/dTot)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(235*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(125*DPSMateX.DetailLayout.xScale)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(110*DPSMateX.DetailLayout.xScale)
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
	DPSMateX.Modules.DetailsAbsorbsTaken:SelectCauseButton(obj.index,1, comp)
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogCreature_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogCreature_ScrollButton"..(obj.index-FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogCreature_ScrollFrame"))).."_selected"):Show()
	end

function DPSMateX.Modules.DetailsAbsorbsTaken:SelectCauseButton(i,p, comp)
	comp = comp or DPSMateX_Details_AbsorbsTaken.LastScroll
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."AbsorbsTaken_LogTwo"
	local obj = _G(path.."_ScrollFrame")
	local obj2 = _G("DPSMateX_Details_"..comp.."AbsorbsTaken_Log_ScrollFrame")
	if p then
		obj.index = p
	end
	i = obj2.index or i
	p = obj.index or p
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelectedThree
	if comp~="" and comp then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedThreeComp
		DetailsSelectedTwoComp = obj.index
	else
		DetailsSelectedTwo = obj.index
	end
	local len = DPSMateX:TableLength(dArr[i][3][p][2])
	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[i][3][p][2][lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(dArr[i][3][p][2][lineplusoffset])
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[i][3][p][3][lineplusoffset][1].." ("..strformat("%.2f", (dArr[i][3][p][3][lineplusoffset][1]*100/dArr[i][3][p][1])).."%)")
			if DPSMateX.CacheUser[user][2] then
				_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\"..img)
			else
				_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\npc")
			end
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(235*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(125*DPSMateX.DetailLayout.xScale)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(110*DPSMateX.DetailLayout.xScale)
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
	DPSMateX.Modules.DetailsAbsorbsTaken:SelectCauseABButton(i,p,1, comp)
	for qq=1, 10 do
		_G("DPSMateX_Details_"..comp.."AbsorbsTaken_Log_ScrollButton"..qq.."_selected"):Hide()
	end
	if (p-FauxScrollFrame_GetOffset(obj2))>0 then
		_G("DPSMateX_Details_"..comp.."AbsorbsTaken_Log_ScrollButton"..(p-FauxScrollFrame_GetOffset(obj2)).."_selected"):Show()
	end
end

function DPSMateX.Modules.DetailsAbsorbsTaken:SelectCauseABButton(i,p,q,comp)
	comp = comp or DPSMateX_Details_Absorbs.LastScroll
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."AbsorbsTaken_LogThree"
	local obj = _G(path.."_ScrollFrame")
	local obj2 = _G("DPSMateX_Details_"..comp.."AbsorbsTaken_Log_ScrollFrame")
	local obj3 = _G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogTwo_ScrollFrame")
	local obj4 = _G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogCreature_ScrollFrame")
	if q then
		obj.index = q
	end
	q = obj.index or q
	p = obj3.index or p
	i = obj2.index or i
	local uArr, dArr, dTot = DetailsArr, DmgArr, DetailsTotal
	if comp~="" and comp then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		DetailsSelectedThreeComp = obj.index
	else
		DetailsSelectedThree = obj.index
	end
	local len = DPSMateX:TableLength(dArr[i][3][p][3][q][2])
	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[i][3][p][3][q][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(dArr[i][3][p][3][q][2][lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[i][3][p][3][q][3][lineplusoffset].." ("..strformat("%.2f", (dArr[i][3][p][3][q][3][lineplusoffset]*100/dArr[i][3][p][3][q][1])).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(235*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(125*DPSMateX.DetailLayout.xScale)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(110*DPSMateX.DetailLayout.xScale)
			end
			_G(path.."_ScrollButton"..line):Show()
		else
			_G(path.."_ScrollButton"..line):Hide()
		end
		_G(path.."_ScrollButton"..line.."_selected"):Hide()
	end
	for qq=1, 10 do
		_G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogTwo_ScrollButton"..qq.."_selected"):Hide()
	end
	if (q-FauxScrollFrame_GetOffset(obj3))>0 then
		_G("DPSMateX_Details_"..comp.."AbsorbsTaken_LogTwo_ScrollButton"..(q-FauxScrollFrame_GetOffset(obj3)).."_selected"):Show()
	end
end

local pairs = pairs

