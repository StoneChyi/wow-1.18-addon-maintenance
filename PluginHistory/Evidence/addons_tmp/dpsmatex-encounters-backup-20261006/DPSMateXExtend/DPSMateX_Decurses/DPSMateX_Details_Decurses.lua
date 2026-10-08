local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsDecurses = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g, g2
local curKey = 1
local db, cbt = {}, 0
local tinsert = table.insert
local _G = getglobal
local strformat = string.format

function DPSMateX.Modules.DetailsDecurses:UpdateDetails(obj, key)
	DPSMateX_Details_CompareDecurses:Hide()
	
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_Decurses_Title:SetText(DPSMateX.L["decursesby"]..obj.user)
	DetailsArr, DetailsTotal, DmgArr = self:EvalDetailsTable()
	DPSMateX_Details_Decurses:Show()
	self:ScrollFrame_Update("")
	self:SelectCreatureButton(1,"")
	self:SelectCreatureAbilityButton(1,1,"")
	DPSMateX_Details_Decurses:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsDecurses:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareDecurses_Title:SetText(DPSMateX.L["decursesby"]..comp)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = self:EvalDetailsTable(comp)
	DPSMateX_Details_CompareDecurses:Show()
	self:ScrollFrame_Update("Compare")
	self:SelectCreatureButton(1,"Compare")
	self:SelectCreatureAbilityButton(1,1,"Compare")
end

function DPSMateX.Modules.DetailsDecurses:EvalDetailsTable(cname)
	local a, b, total = {}, {}, 0
	for cat, val in db[DPSMateX.CacheUser[cname or DetailsUser][1]] do -- 41 Ability
		if cat~="i" then
			local CV, ta, tb = 0, {}, {}
			for ca, va in val do
				local taa, tbb, CVV = {}, {}, 0
				for c, v in va do
					if DPSMateX.Modules.Decurses:IsValid(DPSMateX:GetAbilityById(c), DPSMateX:GetAbilityById(cat), DPSMateX.CacheUser[cname or DetailsUser]) then
						CVV = CVV + v
						local i = 1
						while true do
							if (not tbb[i]) then
								tinsert(tbb, i, v)
								tinsert(taa, i, c)
								break
							else
								if tbb[i] < v then
									tinsert(tbb, i, v)
									tinsert(taa, i, c)
									break
								end
							end
							i=i+1
						end
					end
				end
				local i = 1
				while true do
					if (not tb[i]) then
						tinsert(tb, i, {CVV, taa, tbb})
						tinsert(ta, i, ca)
						break
					else
						if tb[i][1] < CVV then
							tinsert(tb, i, {CVV, taa, tbb})
							tinsert(ta, i, ca)
							break
						end
					end
					i=i+1
				end
				CV = CV + CVV
			end
			if CV>0 then
				local i = 1
				while true do
					if (not b[i]) then
						tinsert(b, i, {CV, ta, tb})
						tinsert(a, i, cat)
						break
					else
						if b[i][1] < CV then
							tinsert(b, i, {CV, ta, tb})
							tinsert(a, i, cat)
							break
						end
					end
					i=i+1
				end
			end
			total = total + CV
		end
	end
	return a, total, b
end

function DPSMateX.Modules.DetailsDecurses:ScrollFrame_Update(comp)
	comp = comp or DPSMateX_Details_Decurses.LastScroll
	local line, lineplusoffset
	local obj = _G("DPSMateX_Details_"..comp.."Decurses_Log_ScrollFrame")
	local path = "DPSMateX_Details_"..comp.."Decurses_Log_ScrollButton"
	local uArr, dArr, dTot = DetailsArr, DmgArr, DetailsTotal
	if comp~="" and comp then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
	end
	local len = DPSMateX:TableLength(uArr)
	FauxScrollFrame_Update(obj,len,14,24)
	for line=1,14 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if uArr[lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(uArr[lineplusoffset])
			_G(path..line.."_Name"):SetText(ability)
			_G(path..line.."_Value"):SetText(dArr[lineplusoffset][1].." ("..strformat("%.2f", 100*dArr[lineplusoffset][1]/dTot).."%)")
			_G(path..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 14 then
				_G(path..line):SetWidth(235)
				_G(path..line.."_Name"):SetWidth(125)
			else
				_G(path..line):SetWidth(220)
				_G(path..line.."_Name"):SetWidth(110)
			end
			_G(path..line):Show()
		else
			_G(path..line):Hide()
		end
		_G(path..line.."_selected"):Hide()
	end
end

function DPSMateX.Modules.DetailsDecurses:SelectCreatureButton(i, comp)
	comp = comp or DPSMateX_Details_Decurses.LastScroll
	local line, lineplusoffset
	local obj = _G("DPSMateX_Details_"..comp.."Decurses_LogTwo_ScrollFrame")
	i = i or obj.index
	obj.index = i
	local path = "DPSMateX_Details_"..comp.."Decurses_LogTwo_ScrollButton"
	local uArr, dArr, dTot = DetailsArr, DmgArr, DetailsTotal
	if comp~="" and comp then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
	end
	local len = DPSMateX:TableLength(dArr[i][2])
	FauxScrollFrame_Update(obj,len,14,24)
	for line=1,14 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[i][2][lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(dArr[i][2][lineplusoffset])
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path..line.."_Name"):SetText(user)
			_G(path..line.."_Name"):SetTextColor(r,g,b)
			_G(path..line.."_Value"):SetText(dArr[i][3][lineplusoffset][1].." ("..strformat("%.2f", 100*dArr[i][3][lineplusoffset][1]/dArr[i][1]).."%)")
			_G(path..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\"..img)
			if len < 14 then
				_G(path..line):SetWidth(235)
				_G(path..line.."_Name"):SetWidth(125)
			else
				_G(path..line):SetWidth(220)
				_G(path..line.."_Name"):SetWidth(110)
			end
			_G(path..line):Show()
		else
			_G(path..line):Hide()
		end
		_G(path..line.."_selected"):Hide()
	end
	for p=1, 14 do
		_G("DPSMateX_Details_"..comp.."Decurses_Log_ScrollButton"..p.."_selected"):Hide()
	end
	_G(path.."1_selected"):Show()
	DPSMateX.Modules.DetailsDecurses:SelectCreatureAbilityButton(i, 1, comp)
	_G("DPSMateX_Details_"..comp.."Decurses_Log_ScrollButton"..i.."_selected"):Show()
end

function DPSMateX.Modules.DetailsDecurses:SelectCreatureAbilityButton(i, p, comp)
	comp = comp or DPSMateX_Details_Decurses.LastScroll
	local line, lineplusoffset
	local obj = _G("DPSMateX_Details_"..comp.."Decurses_LogThree_ScrollFrame")
	i = i or _G("DPSMateX_Details_"..comp.."Decurses_LogTwo_ScrollFrame").index
	p = p or obj.index
	obj.index = p
	local path = "DPSMateX_Details_"..comp.."Decurses_LogThree_ScrollButton"
	local uArr, dArr, dTot = DetailsArr, DmgArr, DetailsTotal
	if comp~="" and comp then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
	end
	local len = DPSMateX:TableLength(dArr[i][3][p][2])
	FauxScrollFrame_Update(obj,len,14,24)
	for line=1,14 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[i][3][p][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(dArr[i][3][p][2][lineplusoffset])
			_G(path..line.."_Name"):SetText(ability)
			_G(path..line.."_Value"):SetText(dArr[i][3][p][3][lineplusoffset].." ("..strformat("%.2f", 100*dArr[i][3][p][3][lineplusoffset]/dArr[i][3][p][1]).."%)")
			_G(path..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 14 then
				_G(path..line):SetWidth(235)
				_G(path..line.."_Name"):SetWidth(125)
			else
				_G(path..line):SetWidth(220)
				_G(path..line.."_Name"):SetWidth(110)
			end
			_G(path..line):Show()
		else
			_G(path..line):Hide()
		end
		_G(path..line.."_selected"):Hide()
	end
	for i=1, 14 do
		_G("DPSMateX_Details_"..comp.."Decurses_LogTwo_ScrollButton"..i.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."Decurses_LogTwo_ScrollButton"..p.."_selected"):Show()
end