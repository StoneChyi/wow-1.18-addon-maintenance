-- Global Variables
local DPSMateX = DPSMateX
DPSMateX.Modules.DetailsDeaths = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g, g2
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert

function DPSMateX.Modules.DetailsDeaths:UpdateDetails(obj, key)
	DPSMateX_Details_CompareDeaths:Hide()
	
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_Deaths_Title:SetText(DPSMateX.L["deathsof"]..obj.user)
	DetailsArr = self:EvalDetailsTable()
	DPSMateX_Details_Deaths:Show()
	self:ScrollFrame_Update("")
	self:SelectDetailsButton(1,"")
	DPSMateX_Details_Deaths:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsDeaths:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareDeaths_Title:SetText(DPSMateX.L["deathsof"]..comp)
	DetailsArrComp = self:EvalDetailsTable(comp)
	DPSMateX_Details_CompareDeaths:Show()
	self:ScrollFrame_Update("Compare")
	self:SelectDetailsButton(1,"Compare")
end

function DPSMateX.Modules.DetailsDeaths:EvalDetailsTable(cname)
	local arr = {}
	for cat, val in db[DPSMateX.CacheUser[cname or DetailsUser][1]] do -- user
		if val["i"][1] == 1 then
			tinsert(arr, {val[1][1], val["i"][2], val})
		end
	end
	return arr
end

function DPSMateX.Modules.DetailsDeaths:ScrollFrame_Update(comp)
	comp = comp or DPSMateX_Details_Deaths.LastScroll
	local line, lineplusoffset
	local obj = _G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollFrame")
	local uArr, dSel = DetailsArr, DetailsSelected
	if comp~="" and comp then
		uArr = DetailsArrComp
		dSel = DetailsSelectedComp
	end
	local len = DPSMateX:TableLength(uArr)
	FauxScrollFrame_Update(obj,len,14,24)
	for line=1,14 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if uArr[lineplusoffset] ~= nil then
			_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line.."_Name"):SetText(DPSMateX:GetUserById(uArr[lineplusoffset][1]))
			_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line.."_Value"):SetText(uArr[lineplusoffset][2])
			_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\npc")
			if len < 14 then
				_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line):SetWidth(265)
				_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line.."_Name"):SetWidth(155)
			else
				_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line):SetWidth(250)
				_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line.."_Name"):SetWidth(140)
			end
			_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line):Show()
		else
			_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line):Hide()
		end
		_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line.."_selected"):Hide()
		if dSel == lineplusoffset then
			_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsDeaths:SelectDetailsButton(i, comp)
	comp = comp or ""
	local obj = _G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollFrame")
	local lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
	local uArr = DetailsArr
	if comp~="" and comp then
		uArr = DetailsArrComp
		DetailsSelectedComp = lineplusoffset
	else
		DetailsSelected = lineplusoffset
	end
	for p=1, 14 do
		_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."Deaths_Log_ScrollButton"..i.."_selected"):Show()
	
	for i=1, 20 do
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_Time"):SetText()
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_CombatTime"):SetText()
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_Cause"):SetText()
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_Cause"):SetTextColor()
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_Ability"):SetText()
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_Type"):SetText()
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_HealIn"):SetText()
		_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..i.."_DamageIn"):SetText()
	end
	for cat, val in uArr[i][3] do
		if cat~="i" then
			local name = DPSMateX:GetUserById(val[1])
			local type,r,g,b = "HIT", DPSMateX:GetClassColor(DPSMateX.CacheUser[name][2])
			if val[4]==1 then type="CRIT" elseif val[4]==2 then type="CRUSH" end
			_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_Time"):SetText(val[7])
			_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_CombatTime"):SetText(ceil(val[6]).."s")
			_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_Cause"):SetText(name)
			_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_Cause"):SetTextColor(r,g,b,1)
			_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_Ability"):SetText(DPSMateX:GetAbilityById(val[2]))
			_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_Type"):SetText(type)
			if val[5]==1 then
				_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_HealIn"):SetText("+"..val[3])
				_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_DamageIn"):SetText("")
			else
				_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_HealIn"):SetText("")
				_G("DPSMateX_Details_"..comp.."Deaths_LogDetails_Child_Row"..cat.."_DamageIn"):SetText("-"..val[3])
			end
		end
	end
end

function DPSMateX.Modules.DetailsDeaths:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 11 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."Deaths_LogDetails"), 10, 375-i*30, 590, 375-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[12] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."Deaths_LogDetails"), 80, 370, 80, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."Deaths_LogDetails"), 160, 370, 160, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[14] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."Deaths_LogDetails"), 260, 370, 260, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[14]:Show()
	
	lines[15] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."Deaths_LogDetails"), 360, 370, 360, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[15]:Show()
	
	lines[16] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."Deaths_LogDetails"), 410, 370, 410, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[16]:Show()
	
	lines[17] = DPSMateX.Options.graph:DrawLine(_G("DPSMateX_Details_"..comp.."Deaths_LogDetails"), 500, 370, 500, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[17]:Show()
end