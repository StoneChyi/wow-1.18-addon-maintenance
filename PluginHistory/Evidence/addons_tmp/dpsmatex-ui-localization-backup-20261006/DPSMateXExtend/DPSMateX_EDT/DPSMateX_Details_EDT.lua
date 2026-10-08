local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.DetailsEDT = {}

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

function DPSMateX.Modules.DetailsEDT:UpdateDetails(obj, key)
	DPSMateX_Details_CompareEDT:Hide()
	
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_EDT_Title:SetText(DPSMateX.L["dmgtakenby"]..obj.user)
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[DetailsUser], curKey)
	DPSMateX_Details_EDT:Show()

	self:Creature_Update("")
	self:ScrollFrame_Update("")
	self:SelectDetailsButton(1,1, "")

		DPSMateX_Details_EDT:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsEDT:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareEDT_Title:SetText(DPSMateX.L["dmgtakenby"]..comp)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)

	DPSMateX_Details_CompareEDT:Show()
	self:ScrollFrame_Update("Compare", comp)
	self:SelectDetailsButton(1,1, "Compare", comp)
	
	end

function DPSMateX.Modules.DetailsEDT:ScrollFrame_Update(comp)
	if not comp then comp = DPSMateX_Details_EDT.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."EDT_Log"
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
		if dSel == lineplusoffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsEDT:Creature_Update(comp)
	if not comp then comp = DPSMateX_Details_EDT.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."EDT_LogCreature"
	local obj = _G(path.."_ScrollFrame")

	local d1,d2,d3,d4 = DetailsArr, DmgArr, DetailsTotal, DetailsSelected

	if comp ~= "" and comp~=nil then
		d1 = DetailsArrComp
		d2 = DmgArrComp
		d3 = DetailsTotalComp
		d4 = DetailsSelectedComp
	end
	local len = DPSMateX:TableLength(d1)

	FauxScrollFrame_Update(obj,len,10,24)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d1[lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(d1[lineplusoffset])
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Name"):SetTextColor(r,g,b)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[lineplusoffset][1].." ("..strformat("%.1f", (d2[lineplusoffset][1]*100/d3)).."%)")
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

function DPSMateX.Modules.DetailsEDT:SelectCreatureButton(i, comp)
	if not comp then comp = DPSMateX_Details_EDT.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."EDT_Log"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	i = i or 1

	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		DetailsSelectedComp = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."EDT_LogCreature_ScrollFrame"))
		dSel = DetailsSelectedComp
	else
		DetailsSelected = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."EDT_LogCreature_ScrollFrame"))
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
		_G("DPSMateX_Details_"..comp.."EDT_LogCreature_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."EDT_LogCreature_ScrollButton"..i.."_selected"):Show()
	--DPSMateX.Modules.DetailsEDT:SelectDetailsButton(DetailsSelected, 1, comp)
	--self:SelectDetailsButton(DetailsSelected,1, comp)
	end

function DPSMateX.Modules.DetailsEDT:SelectDetailsButton(p,i, comp, cname)
	if not comp then comp = DPSMateX_Details_EDT.LastScroll or "" end
	local obj = _G("DPSMateX_Details_"..comp.."EDT_Log_ScrollFrame")
	local lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
	local uArr, dArr, dSel = DetailsArr, DmgArr, DetailsSelected
	
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."EDT_Log_ScrollButton"..p.."_selected"):Hide()
	end
	
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dSel = DetailsSelectedComp
		if not cname then
			cname = DetailsUserComp
		end
	end
	
	if comp ~= "" and comp~=nil then
		DetailsSelectedComp = lineplusoffset
	else
		DetailsSelected = lineplusoffset
	end
	
	-- Performance?
	local ability = tonumber(dArr[p][2][lineplusoffset])
	local creature = tonumber(uArr[p])
	_G("DPSMateX_Details_"..comp.."EDT_Log_ScrollButton"..i.."_selected"):Show()
	
	local path = db[DPSMateX.CacheUser[cname or DetailsUser][1]][creature][ability]
	local hit, crit, miss, parry, dodge, resist, hitMin, hitMax, critMin, critMax, hitav, critav, block, blockMin, blockMax, blockav, glance, glanceMin, glanceMax, glanceav = path[1], path[5], path[9], path[10], path[11], path[12], path[2], path[3], path[6], path[7], path[4], path[8], path[14], path[15], path[16], path[17], path[18], path[19], path[20], path[21]
	local total, max = hit+crit+miss+parry+dodge+resist+glance+block, DPSMateX:TMax({hit, crit, miss, parry, dodge, resist, glance, block})
	
	--_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Casts"):SetText("C: "..path[22])
	-- Block
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount0_Amount"):SetText(block)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount0_Percent"):SetText(strformat("%.1f", 100*block/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount0_StatusBar"):SetValue(ceil(100*block/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount0_StatusBar"):SetStatusBarColor(0.3,0.7,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average0"):SetText(ceil(blockav/DPSMateX:ProbZero(block)))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min0"):SetText(blockMin)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max0"):SetText(blockMax)
	
	-- Glance
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount1_Amount"):SetText(glance)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount1_Percent"):SetText(strformat("%.1f", 100*glance/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount1_StatusBar"):SetValue(ceil(100*glance/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount1_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average1"):SetText(ceil(glanceav/DPSMateX:ProbZero(glance)))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min1"):SetText(glanceMin)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max1"):SetText(glanceMax)
	
	-- Hit
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount2_Amount"):SetText(hit)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount2_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount2_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount2_StatusBar"):SetStatusBarColor(0.9,0.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average2"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min2"):SetText(hitMin)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max2"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount3_Amount"):SetText(crit)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount3_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount3_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount3_StatusBar"):SetStatusBarColor(0.0,0.9,0.0,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average3"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min3"):SetText(critMin)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max3"):SetText(critMax)
	
	-- Miss
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount4_Amount"):SetText(miss)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount4_Percent"):SetText(strformat("%.1f", 100*miss/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount4_StatusBar"):SetValue(ceil(100*miss/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount4_StatusBar"):SetStatusBarColor(0.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average4"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min4"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max4"):SetText("-")
	
	-- Parry
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount5_Amount"):SetText(parry)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount5_Percent"):SetText(strformat("%.1f", 100*parry/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount5_StatusBar"):SetValue(ceil(100*parry/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount5_StatusBar"):SetStatusBarColor(1.0,1.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max5"):SetText("-")
	
	-- Dodge
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount6_Amount"):SetText(dodge)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount6_Percent"):SetText(strformat("%.1f", 100*dodge/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount6_StatusBar"):SetValue(ceil(100*dodge/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount6_StatusBar"):SetStatusBarColor(1.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max6"):SetText("-")
	
	-- Resist
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount7_Amount"):SetText(resist)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount7_Percent"):SetText(strformat("%.1f", 100*resist/total).."%")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount7_StatusBar"):SetValue(ceil(100*resist/max))
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Amount7_StatusBar"):SetStatusBarColor(0.0,1.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Average7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Min7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."EDT_LogDetails_Max7"):SetText("-")
end

function DPSMateX.Modules.DetailsEDT:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDT_Log"), 352, 270-i*30, 717, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDT_Log"), 402, 265, 402, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDT_Log"), 537, 265, 537, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDT_Log"), 597, 265, 597, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."EDT_Log"), 657, 265, 657, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

