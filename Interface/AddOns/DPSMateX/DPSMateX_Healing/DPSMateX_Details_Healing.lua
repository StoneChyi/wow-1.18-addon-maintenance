local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsHealing = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g, g4
local curKey = 1
local db, cbt, db2 = {}, 0, {}
local tinsert = table.insert
local _G = getglobal
local strformat = string.format
local toggle = false
local t1, t2, TTotal = {}, {}, 0
local t1Comp, t2Comp, TTotalComp = {}, {}, 0
local ecbt = {}
local PSelected = 1
local PSelected2 = 1

function DPSMateX.Modules.DetailsHealing:UpdateDetails(obj, key)
	curKey = key
	db, cbt,ecbt = DPSMateX:GetMode(key)
	db2 = DPSMateX:GetModeByArr(DPSMateX.DBCache.HealingTaken, key, "THealingTaken")

	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_Healing_Title:SetText(DPSMateX.L["healdoneby"]..obj.user)
	DPSMateX_Details_Healing_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.1f", (ecbt[obj.user] or 0)+1).."s "..DPSMateX.L["of"].." "..strformat("%.1f", cbt).."s ("..strformat("%.1f", 100*((ecbt[obj.user] or 0)+1)/cbt).."%)")
	DPSMateX_Details_Healing:Show()
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.Modules.Healing, DPSMateX.CacheUser[DetailsUser], curKey)
	t1, t2, TTotal = self:EvalToggleTable()
	
	if not g then
		g=DPSMateX.Options.graph:CreateGraphPieChart("RHPieChart", DPSMateX_Details_Healing_Diagram, "CENTER", "CENTER", 0, 0, 176, 176)
	end
	
	if toggle then
		self:Player_Update("")
		self:PlayerSpells_Update(1,"")
		self:SelectDetails_HealingButton(1,"")
	else
		self:ScrollFrame_Update("")
		self:SelectDetails_HealingButton(1,"")
	end
	self:UpdatePie(g)
		DPSMateX_Details_CompareHealing:Hide()
	DPSMateX_Details_Healing:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsHealing:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareHealing_Title:SetText(DPSMateX.L["healdoneby"]..comp)
	DPSMateX_Details_CompareHealing_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.1f", DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.1f", cbt).."s ("..strformat("%.1f", 100*(DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0)/cbt).."%)")
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
	t1Comp, t2Comp, TTotalComp = self:EvalToggleTable(comp)
	
	if not g4 then
		g4=DPSMateX.Options.graph:CreateGraphPieChart("RHPieChartComp", DPSMateX_Details_CompareHealing_Diagram, "CENTER", "CENTER", 0, 0, 176, 176)
	end
	
	DPSMateX_Details_CompareHealing:Show()
	if toggle then
		DPSMateX_Details_CompareHealing_playerSpells:Show()
		DPSMateX_Details_CompareHealing_player:Show()
		DPSMateX_Details_CompareHealing_Diagram:Hide()
		DPSMateX_Details_CompareHealing_Log:Hide()
		self:Player_Update("Compare")
		self:PlayerSpells_Update(1, "Compare")
		self:SelectDetails_HealingButton(1, "Compare")
	else
		DPSMateX_Details_CompareHealing_playerSpells:Hide()
		DPSMateX_Details_CompareHealing_player:Hide()
		DPSMateX_Details_CompareHealing_Diagram:Show()
		DPSMateX_Details_CompareHealing_Log:Show()
		self:ScrollFrame_Update("Compare")
		self:SelectDetails_HealingButton(1, "Compare")
	end
	self:UpdatePie(g4, comp)
	end

function DPSMateX.Modules.DetailsHealing:EvalToggleTable(cname)
	local a,b = {},{}
	local d = 0
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
			local i = 1
			while true do
				if (not a[i]) then
					tinsert(b, i, c)
					tinsert(a, i, cat)
					break
				else
					if b[i][1] < CV then
						tinsert(b, i, c)
						tinsert(a, i, cat)
						break
					end
				end
				i=i+1
			end
			d = d + CV
		end
	end
	return a,b,d
end

function DPSMateX.Modules.DetailsHealing:ScrollFrame_Update(comp)
	if not comp then comp = DPSMateX_Details_Healing.LastScroll or "" end
	local line, lineplusoffset
	local obj = _G("DPSMateX_Details_"..comp.."Healing_Log_ScrollFrame")
	local uArr, dArr, dTot, dSel = DetailsArr, DmgArr, DetailsTotal, DetailsSelected
	if comp ~= "" and comp~=nil then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
		dSel = DetailsSelectedComp
	end
	local pet, len = "", DPSMateX:TableLength(uArr)

	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if uArr[lineplusoffset] ~= nil then
			pet = dArr[lineplusoffset][2]
			pet = pet and DPSMateX.DB:GetPetShortName(pet)
			pet = pet and ("("..pet..")") or ""

			local ability = DPSMateX:GetAbilityById(uArr[lineplusoffset])
			_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line.."_Name"):SetText(ability..pet)
			_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line.."_Value"):SetText(dArr[lineplusoffset][1].." ("..strformat("%.1f", (dArr[lineplusoffset][1]*100/dTot)).."%)")
			_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line):SetWidth(335*DPSMateX.DetailLayout.xScale)
				_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line.."_Name"):SetWidth((335)*DPSMateX.DetailLayout.xScale-151.12)
			else
				_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line):SetWidth(320*DPSMateX.DetailLayout.xScale)
				_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line.."_Name"):SetWidth((320)*DPSMateX.DetailLayout.xScale-151.12)
			end
			_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line):Show()
		else
			_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line):Hide()
		end
		_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line.."_selected"):Hide()
		if dSel == lineplusoffset then
			_G("DPSMateX_Details_"..comp.."Healing_Log_ScrollButton"..line.."_selected"):Show()
		end
	end
end

function DPSMateX.Modules.DetailsHealing:SelectDetails_HealingButton(i, comp, cname)
	if not comp then comp = DPSMateX_Details_Healing.LastScroll or "" end
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
	local user, pet = DPSMateX.CacheUser[cname or DetailsUser][1], ""
	if toggle then
		pathh = "DPSMateX_Details_"..comp.."Healing_playerSpells"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + FauxScrollFrame_GetOffset(obj)
		path = d2[obj.id][3][lineplusoffset]
	else
		pathh = "DPSMateX_Details_"..comp.."Healing_Log"
		obj = _G(pathh.."_ScrollFrame")
		lineplusoffset = i + FauxScrollFrame_GetOffset(obj)

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
	local hit, crit, hitav, critav, hitMin, hitMax, critMin, critMax = path[2], path[3], path[4], path[5], path[6], path[7], path[8], path[9]
	local total, max = hit+crit, DPSMateX:TMax({hit, crit})
	
	-- Hit
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount0_Amount"):SetText(hit)
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount0_Percent"):SetText(strformat("%.1f", 100*hit/total).."%")
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount0_StatusBar"):SetValue(ceil(100*hit/max))
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount0_StatusBar"):SetStatusBarColor(0.3,0.7,1.0,1)
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Average0"):SetText(ceil(hitav/DPSMateX:ProbZero(hit)))
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Min0"):SetText(hitMin)
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Max0"):SetText(hitMax)
	
	-- Crit
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount1_Amount"):SetText(crit)
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount1_Percent"):SetText(strformat("%.1f", 100*crit/total).."%")
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount1_StatusBar"):SetValue(ceil(100*crit/max))
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Amount1_StatusBar"):SetStatusBarColor(1.0,0.7,0.3,1)
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Average1"):SetText(ceil(critav/DPSMateX:ProbZero(crit)))
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Min1"):SetText(critMin)
	_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing_Max1"):SetText(critMax)
end

function DPSMateX.Modules.DetailsHealing:Player_Update(comp)
	if not comp then comp = DPSMateX_Details_Healing.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."Healing_player"
	local obj = _G(path.."_ScrollFrame")
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d1 = t1Comp
		d2 = t2Comp
		d3 = TTotalComp
		d4 = PSelected2
	end
	local len = DPSMateX:TableLength(d1)

	FauxScrollFrame_Update(obj,len,8,DPSMateX.DetailLayout.listRowHeight)
	for line=1,8 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d1[lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(d1[lineplusoffset])
			local r,g,b,img = DPSMateX:GetClassColor(DPSMateX.CacheUser[user][2])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Name"):SetTextColor(r,g,b)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[lineplusoffset][1].." ("..strformat("%.1f", (d2[lineplusoffset][1]*100/d3)).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture("Interface\\AddOns\\DPSMateX\\images\\class\\"..img)
			if len < 8 then
				_G(path.."_ScrollButton"..line):SetWidth(235*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((235)*DPSMateX.DetailLayout.xScale-151.12)
			else
				_G(path.."_ScrollButton"..line):SetWidth(220*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((220)*DPSMateX.DetailLayout.xScale-151.12)
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

function DPSMateX.Modules.DetailsHealing:PlayerSpells_Update(i, comp)
	if not comp then comp = DPSMateX_Details_Healing.LastScroll or "" end
	local line, lineplusoffset
	local path = "DPSMateX_Details_"..comp.."Healing_playerSpells"
	local obj = _G(path.."_ScrollFrame")
	obj.id = (i + FauxScrollFrame_GetOffset(_G("DPSMateX_Details_"..comp.."Healing_player_ScrollFrame"))) or obj.id
	local d1,d2,d3,d4 = t1,t2,TTotal,PSelected
	if comp ~= "" and comp~=nil then
		d2 = t2Comp
		d4 = PSelected2
	end
	local len = DPSMateX:TableLength(d2[i][2])

	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
	for line=1,10 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d2[obj.id][2][lineplusoffset] ~= nil then
			local ability = DPSMateX:GetAbilityById(d2[obj.id][2][lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(ability)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[obj.id][3][lineplusoffset][1].." ("..strformat("%.1f", (d2[obj.id][3][lineplusoffset][1]*100/d2[obj.id][1])).."%)")
			_G(path.."_ScrollButton"..line.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(strsub(ability, 1, (strfind(ability, "%(") or 0)-1) or ability))
			if len < 10 then
				_G(path.."_ScrollButton"..line):SetWidth(335*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((335)*DPSMateX.DetailLayout.xScale-151.12)
			else
				_G(path.."_ScrollButton"..line):SetWidth(320*DPSMateX.DetailLayout.xScale)
				_G(path.."_ScrollButton"..line.."_Name"):SetWidth((320)*DPSMateX.DetailLayout.xScale-151.12)
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
		_G("DPSMateX_Details_"..comp.."Healing_player_ScrollButton"..p.."_selected"):Hide()
	end
	_G("DPSMateX_Details_"..comp.."Healing_player_ScrollButton"..i.."_selected"):Show()
	end

function DPSMateX.Modules.DetailsHealing:UpdatePie(gg, cname)
	local uArr, dArr, dTot = DetailsArr, DmgArr, DetailsTotal
	if cname then
		uArr = DetailsArrComp
		dArr = DmgArrComp
		dTot = DetailsTotalComp
	end
	gg:ResetPie()
	for cat, val in uArr do
		local user
		if (dArr[cat][2]) and DPSMateX.Settings["mergepets"] and DPSMateX:GetUserById(dArr[cat][2]) ~= (cname or DetailsUser) then 
			user=dArr[cat][2]
		else 
			user=DPSMateX.CacheUser[cname or DetailsUser][1]
		end
		local percent = (db[user][val][1]*100/dTot)
		gg:AddPie(percent, 0, DPSMateX:GetUserById(user)..": "..DPSMateX:GetAbilityById(val))
	end
end

function DPSMateX.Modules.DetailsHealing:CreateGraphTable(comp)
	local lines = {}
	comp = comp or ""
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing"), 5, 270-i*30, 490.909091, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing"), 56.818182, 265, 56.818182, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing"), 272.727273, 265, 272.727273, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing"), 345.454545, 265, 345.454545, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details_"..comp.."Healing_LogDetails_Healing"), 418.181818, 265, 418.181818, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

local pairs = pairs

function DPSMateX.Modules.DetailsHealing:ToggleMode(bool)
	if bool then return end

		if toggle then
			toggle = false
			self:ScrollFrame_Update("")
			self:SelectDetails_HealingButton(1,"")
			DPSMateX_Details_Healing_playerSpells:Hide()
			DPSMateX_Details_Healing_player:Hide()
			DPSMateX_Details_Healing_Diagram:Show()
			DPSMateX_Details_Healing_Log:Show()
			
			if DetailsUserComp then
				self:ScrollFrame_Update("Compare")
				self:SelectDetails_HealingButton(1, "Compare")
				DPSMateX_Details_CompareHealing_playerSpells:Hide()
				DPSMateX_Details_CompareHealing_player:Hide()
				DPSMateX_Details_CompareHealing_Diagram:Show()
				DPSMateX_Details_CompareHealing_Log:Show()
			end
		else
			toggle = true
			DPSMateX_Details_Healing_playerSpells:Show()
			DPSMateX_Details_Healing_player:Show()
			DPSMateX_Details_Healing_Diagram:Hide()
			DPSMateX_Details_Healing_Log:Hide()
			self:Player_Update("")
			self:PlayerSpells_Update(1,"")
			self:SelectDetails_HealingButton(1,"")

			if DetailsUserComp then
				DPSMateX_Details_CompareHealing_playerSpells:Show()
				DPSMateX_Details_CompareHealing_player:Show()
				DPSMateX_Details_CompareHealing_Diagram:Hide()
				DPSMateX_Details_CompareHealing_Log:Hide()				
				self:Player_Update("Compare")
				self:PlayerSpells_Update(1, "Compare")
				self:SelectDetails_HealingButton(1, "Compare")
			end
		end
	
end

