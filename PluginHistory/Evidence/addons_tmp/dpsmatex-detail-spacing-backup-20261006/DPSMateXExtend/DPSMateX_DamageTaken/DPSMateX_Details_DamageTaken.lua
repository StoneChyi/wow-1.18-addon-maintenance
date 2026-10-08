local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsDamageTaken = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local curKey = 1
local db, cbt = {}, 0
local tinsert = table.insert
local _G = getglobal
local strformat = string.format
local toggle, toggle3 = false, false

function DPSMateX.Modules.DetailsDamageTaken:UpdateDetails(obj, key)
	DPSMateX_Details_CompareDamageTaken:Hide()

	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_DamageTaken_Title:SetText(DPSMateX.L["dmgtakenby"]..obj.user)
	DPSMateX_Details_DamageTaken:Show()
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.Modules.DamageTaken, DPSMateX.CacheUser[DetailsUser], curKey)

	self:ScrollFrame_Update("")
	self:SelectCreatureButton(1,"")
	self:SelectDetailsButton(1,1,"")

		DPSMateX_Details_DamageTaken:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsDamageTaken:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareDamageTaken_Title:SetText(DPSMateX.L["dmgtakenby"]..comp)
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)

	DPSMateX_Details_CompareDamageTaken:Show()
	self:ScrollFrame_Update("Compare", comp)
	self:SelectCreatureButton(1, "Compare", comp)
	self:SelectDetailsButton(1,1, "Compare", comp)
	
	end

function DPSMateX.Modules.DetailsDamageTaken:ScrollFrame_Update(comp, cname)
	if not comp then comp = DPSMateX_Details_DamageTaken.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."DamageTaken_LogCreature"
	local obj = _G(path.."_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedComp
	end
	local pet, len = "", DPSMateX:TableLength(uArr)
	
	FauxScrollFrame_Update(obj,len,8,DPSMateX.DetailLayout.listRowHeight)
	for line=1,8 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if uArr[lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(uArr[lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[lineplusoffset][1].." ("..strformat("%.1f", (dArr[lineplusoffset][1]*100/dTot)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\npc")
			if len < 8 then
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

function DPSMateX.Modules.DetailsDamageTaken:SelectCreatureButton(i, comp, cname)
	if not comp then comp = DPSMateX_Details_DamageTaken.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."DamageTaken_Log"
	local obj = _G(path.."_ScrollFrame")

	i = i + FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."DamageTaken_LogCreature_ScrollFrame")) or obj.index
	obj.index = i
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		DetailsSelectedComp = i
		dSel = DetailsSelectedComp
	else
		DetailsSelected = i
		dSel = DetailsSelected
	end
	local pet, len = "", DPSMateX:TableLength(dArr[i][2])

	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if dArr[i][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(dArr[i][2][lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(dArr[i][3][lineplusoffset].." ("..strformat("%.1f", (dArr[i][3][lineplusoffset]*100/dTot)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(335*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(225*DPSMateX.DetailLayout.xScale)
			else
				_G(path.."_ScrollButton"..line):SetWidth(320*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth(210*DPSMateX.DetailLayout.xScale)
			end
			_G(path.."_ScrollButton"..line):Show()
		else
			_G(path.."_ScrollButton"..line):Hide()
		end
		_G(path.."_ScrollButton"..line.."_selected"):Hide()
		_G(path.."_ScrollButton1_selected"):Show()
	end
	for p=1, 8 do
		_G("DPSMateX_Details_"..comp.."DamageTaken_LogCreature_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogCreature_ScrollButton"..(i-FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."DamageTaken_LogCreature_ScrollFrame"))).."_selected"):Show()
	self:SelectDetailsButton(i,1, comp, cname)
	end

function DPSMateX.Modules.DetailsDamageTaken:SelectDetailsButton(p,i,comp,cname)
	if not comp then comp = DPSMateX_Details_DamageTaken.LastScroll or "" end
	local obj = _G("DPSMateX_Details_"..comp.."DamageTaken_Log_ScrollFrame")
	local lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
	local uArr, dArr, dSel = DetailsArr, DmgArr, DetailsSelected
	
	for p=1, 10 do
		_G("DPSMateX_Details_"..comp.."DamageTaken_Log_ScrollButton"..p.."_selected"):Hide()
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
	_G("DPSMateX_Details_"..comp.."DamageTaken_Log_ScrollButton"..i.."_selected"):Show()
	
	local path = db[DPSMateX.CacheUser[cname or DetailsUser][1]][creature][ability]
	local hit, crit, miss, parry, dodge, resist, hitMin, hitMax, critMin, critMax, hitav, critav, crush, crushMin, crushMax, crushav, block, blockMin, blockMax, blockav = path[1], path[5], path[9], path[10], path[11], path[12], path[2], path[3], path[6], path[7], path[4], path[8], path[15], path[16], path[17], path[18], path[20], path[21], path[22], path[23]
	local total, max = hit+crit+miss+parry+dodge+resist+crush+block, DPSMateX:TMax({hit, crit, miss, parry, dodge, resist, crush, block})
	
	--_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Casts"):SetText("C: "..path[19])
	-- Block
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount1_Amount"):SetText(block)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount1_Percent"):SetText(strformat("%.1f", 100*block/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount1_StatusBar"):SetValue(ceil(100*block/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount1_StatusBar"):SetStatusBarColor(0.5,0.7,0.3,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average1"):SetText(ceil(blockav/DPSMateX:ProbZero(block)))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min1"):SetText(blockMin)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max1"):SetText(blockMax)
	
	-- Crush
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount2_Amount"):SetText(crush)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount2_Percent"):SetText(strformat("%.1f", 100*crush/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount2_StatusBar"):SetValue(ceil(100*crush/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount2_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average2"):SetText(ceil(crushav/DPSMateX:ProbZero(crush)))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min2"):SetText(crushMin)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max2"):SetText(crushMax)
	
	-- Hit
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount3_Amount"):SetText(hit)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount3_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount3_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount3_StatusBar"):SetStatusBarColor(0.9,0.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average3"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min3"):SetText(hitMin)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max3"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount4_Amount"):SetText(crit)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount4_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount4_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount4_StatusBar"):SetStatusBarColor(0.0,0.9,0.0,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average4"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min4"):SetText(critMin)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max4"):SetText(critMax)
	
	-- Miss
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount5_Amount"):SetText(miss)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount5_Percent"):SetText(strformat("%.1f", 100*miss/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount5_StatusBar"):SetValue(ceil(100*miss/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount5_StatusBar"):SetStatusBarColor(0.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min5"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max5"):SetText("-")
	
	-- Parry
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount6_Amount"):SetText(parry)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount6_Percent"):SetText(strformat("%.1f", 100*parry/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount6_StatusBar"):SetValue(ceil(100*parry/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount6_StatusBar"):SetStatusBarColor(1.0,1.0,0.0,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min6"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max6"):SetText("-")
	
	-- Dodge
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount7_Amount"):SetText(dodge)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount7_Percent"):SetText(strformat("%.1f", 100*dodge/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount7_StatusBar"):SetValue(ceil(100*dodge/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount7_StatusBar"):SetStatusBarColor(1.0,0.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min7"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max7"):SetText("-")
	
	-- Resist
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount8_Amount"):SetText(resist)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount8_Percent"):SetText(strformat("%.1f", 100*resist/total).."%")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount8_StatusBar"):SetValue(ceil(100*resist/max))
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Amount8_StatusBar"):SetStatusBarColor(0.0,1.0,1.0,1)
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Average8"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Min8"):SetText("-")
	_G("DPSMateX_Details_"..comp.."DamageTaken_LogDetails_Max8"):SetText("-")
end

function DPSMateX.Modules.DetailsDamageTaken:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."DamageTaken_Log"), 352, 270-i*30, 717, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."DamageTaken_Log"), 402, 260, 402, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."DamageTaken_Log"), 537, 260, 537, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."DamageTaken_Log"), 597, 260, 597, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."DamageTaken_Log"), 657, 260, 657, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

local pairs = pairs

