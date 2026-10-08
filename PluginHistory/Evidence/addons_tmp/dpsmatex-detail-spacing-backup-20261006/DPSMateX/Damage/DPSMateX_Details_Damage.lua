-- Global Variables
local DPSMateX = DPSMateX
DPSMateX.Modules.DetailsDamage = {}

-- Local variables
local DetailsArr, DetailsTotal, DmgArr, DetailsUser, DetailsSelected  = {}, 0, {}, "", 1
local DetailsArrComp, DetailsTotalComp, DmgArrComp, DetailsUserComp, DetailsSelectedComp  = {}, 0, {}, "", 1
local g, g4
local curKey = 1
local db, cbt, db2 = {}, 0, {}
local _G = getglobal
local tinsert = table.insert
local strformat = string.format
local toggle = false
local t1, t2, TTotal = {}, {}, 0
local t1Comp, t2Comp, TTotalComp = {}, {}, 0
local ecbt = {}
local PSelected = 1
local PSelected2 = 1

function DPSMateX.Modules.DetailsDamage:UpdateDetails(obj, key)
	curKey = key
	db, cbt,ecbt = DPSMateX:GetMode(key)
	db2 = DPSMateX:GetModeByArr(DPSMateX.DBCache.EDT, key, "EDTaken")

	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_Title:SetText(DPSMateX.L["dmgdoneby"]..obj.user)
	DPSMateX_Details_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", (ecbt[obj.user] or 0)+1).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*((ecbt[obj.user] or 0)+1)/cbt).."%)")
	DPSMateX_Details:Show()
	DetailsArr, DetailsTotal, DmgArr = DPSMateX:EvalTable(DPSMateX.Modules.Damage, DPSMateX.CacheUser[DetailsUser], curKey)
	t1, t2, TTotal = self:EvalToggleTable()
	
	if not g then
		g=DPSMateX.Options.graph:CreateGraphPieChart("DMGPieChart", DPSMateX_Details_Diagram, "CENTER", "CENTER", 0, 0, 176, 176)
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
		DPSMateX_Details_CompareDamage:Hide()
	
	DPSMateX_Details:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
	
end

function DPSMateX.Modules.DetailsDamage:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)
	DPSMateX_Details_CompareDamage:Show()--先show再update scroll,否则不能scroll

	DetailsUserComp = comp
	DPSMateX_Details_CompareDamage_Title:SetText(DPSMateX.L["dmgdoneby"]..comp)
	DPSMateX_Details_CompareDamage_SubTitle:SetText(DPSMateX.L["activity"]..strformat("%.2f", DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0).."s "..DPSMateX.L["of"].." "..strformat("%.2f", cbt).."s ("..strformat("%.2f", 100*(DPSMateX:GetSelectedEffectiveTime(key)[comp] or 0)/cbt).."%)")
	DetailsArrComp, DetailsTotalComp, DmgArrComp = DPSMateX:EvalTable(DPSMateX.RegistredModules[DPSMateX.Settings["windows"][curKey]["CurMode"]], DPSMateX.CacheUser[comp], curKey)
	t1Comp, t2Comp, TTotalComp = self:EvalToggleTable(comp)
	
	if not g4 then
		g4=DPSMateX.Options.graph:CreateGraphPieChart("DMGPieChartComp", DPSMateX_Details_CompareDamage_Diagram, "CENTER", "CENTER", 0, 0, 176, 176)
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
	
	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
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

	FauxScrollFrame_Update(obj,len,8,DPSMateX.DetailLayout.listRowHeight)
	for line=1,8 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(obj)
		if d1[lineplusoffset] ~= nil then
			local user = DPSMateX:GetUserById(d1[lineplusoffset])
			_G(path.."_ScrollButton"..line.."_Name"):SetText(user)
			_G(path.."_ScrollButton"..line.."_Value"):SetText(d2[lineplusoffset][1].." ("..strformat("%.1f", (d2[lineplusoffset][1]*100/d3)).."%)")
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

	FauxScrollFrame_Update(obj,len,10,DPSMateX.DetailLayout.listRowHeight)
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
	
	_G("DPSMateX_Details"..comp.."_LogDetails_Casts"):SetText(DPSMateX.L["detailtotal"]..total)
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

function DPSMateX.Modules.DetailsDamage:CreateGraphTable(comp)
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 5, 270-i*30, 376, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 57, 265, 57, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 192, 265, 192, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 252, 265, 252, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX:DrawDetailTableLine(_G("DPSMateX_Details"..comp.."_LogDetails"), 312, 265, 312, 2, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
end

function DPSMateX.Modules.DetailsDamage:ToggleMode(bool)
	if bool then return end

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


