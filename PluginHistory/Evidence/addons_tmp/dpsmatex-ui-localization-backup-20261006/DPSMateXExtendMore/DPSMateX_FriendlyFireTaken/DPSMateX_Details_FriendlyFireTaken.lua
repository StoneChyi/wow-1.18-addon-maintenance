local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsFFT = {}

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

function DPSMateX.Modules.DetailsFFT:UpdateDetails(obj, key)
	DPSMateX_Details_CompareFFT:Hide()
	
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_FFT_Title:SetText(DPSMateX.L["fftby"]..obj.user)
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[DetailsUser], curKey)
	DPSMateX_Details_FFT:Show()
	self:ScrollFrame_Update("")
	self:SelectCreatureButton(1,"")
	self:SelectDetailsButton(1,1,"")

		DPSMateX_Details_FFT:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsFFT:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareFFT_Title:SetText(DPSMateX.L["fftby"]..comp)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)

	DPSMateX_Details_CompareFFT:Show()
	self:ScrollFrame_Update("Compare", comp)
	self:SelectCreatureButton(1, "Compare", comp)
	self:SelectDetailsButton(1,1, "Compare", comp)
	
	end

function DPSMateX.Modules.DetailsFFT:ScrollFrame_Update(comp)
	if not comp then comp = DPSMateX_Details_FFT.LastScroll or "" end
	local line, lineplusOffset
	local path = "DPSMateX_Details_"..comp.."FFT_LogCreature"
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
		lineplusOffset = line + FauxScrollFrame_GetOffset(obj)
		if uArr[lineplusOffset] ~= nil then
			local user = DPSMateX:GetUserById(uArr[lineplusOffset])
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Name"):SetTextColor(r,g,b)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[lineplusOffset][1].." ("..strformat("%.2f", (dArr[lineplusOffset][1]*100/dTot)).."%)")
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
		if dSel == lineplusOffset then
			_G(path.."_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsFFT:SelectCreatureButton(i, comp)
	if not comp then comp = DPSMateX_Details_FFT.LastScroll or "" end
	local line, lineplusOffset
	local path = "DPSMateX_Details_"..comp.."FFT_Log"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		DetailsSelectedComp = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."FFT_LogCreature_ScrollFrame"))
		dSel = DetailsSelectedComp
	else
		DetailsSelected = i+FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."FFT_LogCreature_ScrollFrame"))
		dSel = DetailsSelected
	end
	local len = DPSMateX:TableLength(dArr[i][2])

	FauxScrollFrame_Update(obj,len,10,24)
	obj.index = dSel
	for line=1,10 do
		lineplusOffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[dSel][2][lineplusOffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(dArr[dSel][2][lineplusOffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[dSel][3][lineplusOffset].." ("..strformat("%.2f", (dArr[dSel][3][lineplusOffset]*100/dArr[dSel][1])).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
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
		_G(path.."_ScrollButton1_selected"):Show()
	end
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."FFT_LogCreature_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."FFT_LogCreature_ScrollButton"..i.."_selected"):Show()
	self:SelectDetailsButton(DetailsSelected,1, comp)
	end

function DPSMateX.Modules.DetailsFFT:SelectDetailsButton(p,i, comp, cname)
	if not comp then comp = DPSMateX_Details_FFT.LastScroll or "" end
	local obj = _G("DPSMateX_Details_"..comp.."FFT_Log_ScrollFrame")
	local lineplusOffset = i + FauxScrollFrame_GetOffset(obj)
	local uArr, dArr, dSel = DetailsArr, DmgArr, DetailsSelected
	
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."FFT_Log_ScrollButton"..p.."_selected"):Hide()
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
	local ability = tonumber(dArr[p][2][lineplusOffset])
	local creature = tonumber(uArr[p])
	_G("DPSMateX_Details_"..comp.."FFT_Log_ScrollButton"..i.."_selected"):Show()
	
	local path = db[DPSMateX.CacheUser[cname or DetailsUser][1]][creature][ability]
	local hit, crit, miss, parry, dodge, resist, hitMin, hitMax, critMin, critMax, hitav, critav = path[1], path[5], path[9], path[10], path[11], path[12], path[2], path[3], path[6], path[7], path[4], path[8]
	local total, max = hit+crit+miss+parry+dodge+resist, DPSMateX:TMax({hit, crit, miss, parry, dodge, resist})
	
	-- Hit
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount2_Amount"):SetText(hit)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount2_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount2_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount2_StatusBar"):SetStatusBarColor(0.9,0.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Average2"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Min2"):SetText(hitMin)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Max2"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount3_Amount"):SetText(crit)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount3_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount3_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount3_StatusBar"):SetStatusBarColor(0.0,0.9,0.0,1)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Average3"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Min3"):SetText(critMin)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Max3"):SetText(critMax)
	
	-- Miss
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount4_Amount"):SetText(miss)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount4_Percent"):SetText(strformat("%.1f", 100*miss/total).."%")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount4_StatusBar"):SetValue(ceil(100*miss/max))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount4_StatusBar"):SetStatusBarColor(0.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Average4"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Min4"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Max4"):SetText("-")
	
	-- Parry
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount5_Amount"):SetText(parry)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount5_Percent"):SetText(strformat("%.1f", 100*parry/total).."%")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount5_StatusBar"):SetValue(ceil(100*parry/max))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount5_StatusBar"):SetStatusBarColor(1.0,1.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Average5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Min5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Max5"):SetText("-")
	
	-- Dodge
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount6_Amount"):SetText(dodge)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount6_Percent"):SetText(strformat("%.1f", 100*dodge/total).."%")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount6_StatusBar"):SetValue(ceil(100*dodge/max))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount6_StatusBar"):SetStatusBarColor(1.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Average6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Min6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Max6"):SetText("-")
	
	-- Resist
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount7_Amount"):SetText(resist)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount7_Percent"):SetText(strformat("%.1f", 100*resist/total).."%")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount7_StatusBar"):SetValue(ceil(100*resist/max))
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Amount7_StatusBar"):SetStatusBarColor(0.0,1.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Average7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Min7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."FFT_LogDetails_Max7"):SetText("-")
end

function DPSMateX.Modules.DetailsFFT:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."FFT_Log"), 252, 270-i*30, 617, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."FFT_Log"), 302, 260, 302, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."FFT_Log"), 437, 260, 437, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."FFT_Log"), 497, 260, 497, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."FFT_Log"), 557, 260, 557, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

