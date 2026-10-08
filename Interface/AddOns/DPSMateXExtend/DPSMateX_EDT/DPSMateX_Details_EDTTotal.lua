DPSMateX.Modules.DetailsEDTTotal = {}

local g
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local tremove = tremove
local strformat = string.format
local toggle = false
local totMax, totTime = 0, 0

function DPSMateX.Modules.DetailsEDTTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)

	if not self.compactTableInitialized then
		self.compactTableInitialized = true
		self:CreateGraphTable()
	end
	DPSMateX_Details_EDTTotal_Title:SetText(DPSMateX.L["edtsum"])
	self:LoadTable()
		DPSMateX_Details_EDTTotal:Show()
	DPSMateX_Details_EDTTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

local pairs = pairs

function DPSMateX.Modules.DetailsEDTTotal:CreateGraphTable()
	local lines = {}
	for i=1, 8 do
		-- Horizontal
		lines[i] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 10, 270-i*30, 860, 270-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[9] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 40, 260, 40, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[9]:Show()
	
	lines[10] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 170, 260, 170, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[10]:Show()
	
	lines[11] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 540, 260, 540, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[11]:Show()
	
	lines[12] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 600, 260, 600, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 660, 260, 660, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[14] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 720, 260, 720, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[14]:Show()
	
	lines[15] = DPSMateX:DrawDetailTableLine(DPSMateX_Details_EDTTotal_PlayerList, 780, 260, 780, 10, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[15]:Show()
end

-- crushes?
function DPSMateX.Modules.DetailsEDTTotal:GetTableValues()
	local arr, total = {}, 0
	for cat, val in db do -- cause
		local CV, crit, totCrit, miss, totMiss, hit, totHit, crush, totOverall = 0, 0, 0.000001, 0, 0.000001, 0, 0.000001, 0, 0
		local name = DPSMateX:GetUserById(cat)
		for ca, va in pairs(val) do -- user
			if ca~="i" then
				for c, v in pairs(va) do -- ability
					if c~="i" then
						if v[1]>0 or v[14]>0 then
							totHit=totHit+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
							hit=hit+v[1]
							crush=crush+v[14]
						end
						if v[5]>0 then
							totCrit=totCrit+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
							crit=crit+v[5]
						end
						if v[9]>0 or v[10]>0 or v[11]>0 or v[12]>0 then
							totMiss=totMiss+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
							miss=miss+v[9]+v[10]+v[11]+v[12]
						end
						CV = CV + v[13]
						totOverall = totOverall+v[1]+v[5]+v[9]+v[10]+v[11]+v[12]+v[14]
					end
				end
			end
		end
		tinsert(arr, {name, CV, crit, miss, totCrit, totMiss, cat, hit, totHit, crush,totOverall})
		total = total + CV
	end
	local newArr = {}
	for cat, val in arr do
		local i = 1
		while true do
			if (not newArr[i]) then
				tinsert(newArr, i, val)
				break
			elseif newArr[i][2]<=val[2] then
				tinsert(newArr, i, val)
				break
			end
			i=i+1
		end
	end
	return newArr, total
end

function DPSMateX.Modules.DetailsEDTTotal:LoadTable()
	local arr, total = DPSMateX.Modules.DetailsEDTTotal:GetTableValues()
	for i=1, 30 do
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..i):Hide()
	end
	for cat, val in pairs(arr) do
		if cat>30 then break end
		local r,g,b = DPSMateX:GetClassColor(DPSMateX.CacheUser[val[1]][2])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child"):SetHeight(cat*DPSMateX.DetailLayout.tableRowHeight)
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Name"):SetText(val[1])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Name"):SetTextColor(r,g,b)
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Amount"):SetText(val[2])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_StatusBar"):SetValue(100*val[2]/arr[1][2])
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_StatusBar"):SetStatusBarColor(r,g,b, 1)
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_AmountPerc"):SetText(strformat("%.1f", 100*val[2]/total).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Crush"):SetText(strformat("%.1f", 100*val[10]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Hit"):SetText(strformat("%.1f", 100*val[8]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Crit"):SetText(strformat("%.1f", 100*val[3]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_Miss"):SetText(strformat("%.1f", 100*val[4]/val[11]).."%")
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat.."_EDPS"):SetText(strformat("%.1f", val[2]/(((DPSMateX:GetSelectedEffectiveTime(curKey)[val[1]]) or cbt)+1)))
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat).user = val[7]
		_G("DPSMateX_Details_EDTTotal_PlayerList_Child_R"..cat):Show()
	end
end

function DPSMateX.Modules.DetailsEDTTotal:ShowTooltip(user, obj)
	local name = DPSMateX:GetUserById(user)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.EDT, DPSMateX.CacheUser[name], curKey)
	local pet = ""
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(name.."'s "..strlower(DPSMateX.L["damagetaken"]), 1,1,1)
	for i=1, DPSMateX.Settings["subviewrows"] do
		if not a[i] then break end
		GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		for p=1, 3 do 
			if not c[i][2][p] or c[i][3][p]==0 then break end
			GameTooltip:AddDoubleLine("       "..p..". "..DPSMateX:GetAbilityById(c[i][2][p]),c[i][3][p].." ("..strformat("%.2f", 100*c[i][3][p]/c[i][1]).."%)",0.5,0.5,0.5,0.5,0.5,0.5)
		end
	end
	GameTooltip:Show()
end
