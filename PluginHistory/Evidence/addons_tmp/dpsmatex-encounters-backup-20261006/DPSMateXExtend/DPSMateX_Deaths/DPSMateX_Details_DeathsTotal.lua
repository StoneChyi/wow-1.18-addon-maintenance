local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.DetailsDeathsTotal = {}

-- Local variables
local curKey = 1
local db, cbt = {}, 0
local _G = getglobal
local tinsert = table.insert
local strformat = string.format
local tnbr = tonumber
local TL = 0
local Offset = 0
local DetailsArr = {}
local hexClassColor = {
	warrior = "C79C6E",
	rogue = "FFF569",
	priest = "FFFFFF",
	druid = "FF7D0A",
	warlock = "9482C9",
	mage = "69CCF0",
	hunter = "ABD473",
	paladin = "F58CBA",
	shaman = "0070DE",
}

function DPSMateX.Modules.DetailsDeathsTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsArr = self:EvalDetailsTable()
	Offset = 0
	TL = DPSMateX:TableLength(DetailsArr)
	self:ScrollFrameUpdate(0)
	DPSMateX_Details_Deaths_Total_Title:SetText(DPSMateX.L["deathssum"])
	DPSMateX_Details_Deaths_Total:Show()
	DPSMateX_Details_Deaths_Total:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsDeathsTotal:UpdateRow(row, a, b, c, d, e, f, g, h, i)
	_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row).user = c
	_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row).id = i
	_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_Time"):SetText(a)
	if b~=0 then
		_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_CombatTime"):SetText(strformat("%.2f", b).."s")
	else
		_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_CombatTime"):SetText("")
	end
	if c=="" then
		_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_Victim"):SetText("|cFF"..hexClassColor["warrior"]..c.."|r")
	else
		_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_Victim"):SetText("|cFF"..hexClassColor[DPSMateX.CacheUser[c][2] or "warrior"]..c.."|r")
	end
	if h=="" then
		_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_Cause"):SetText("|cFF"..hexClassColor["warrior"]..h.."|r")
	else
		_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_Cause"):SetText("|cFF"..hexClassColor[DPSMateX.CacheUser[h][2] or "warrior"]..h.."|r")
	end
	_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_Over"):SetText(strformat("%.2f", d).."s")
	_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_Ability"):SetText(e)
	_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_HealIn"):SetText("+"..f)
	_G("DPSMateX_Details_Deaths_Total_LogDetails_Row"..row.."_DamageIn"):SetText("-"..g)
end

function DPSMateX.Modules.DetailsDeathsTotal:EvalDetailsTable()
	local a = {}
	for cat, val in db do -- user
		local temp = {}
		local name = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, name) then
			for ca, va in val do -- individual death
				if va["i"][1]==1 then
					if not temp[ca] then
						temp[ca] = {}
					end
					temp[ca][1] = cat
					temp[ca][2] = name
					temp[ca][3] = va["i"][2] -- Time
					temp[ca][4] = va[1][6] -- CBT time of last event
					if va[3] and (va[1][6] - va[3][6])<=20 and va[3][5]==0 then
						temp[ca][5] = va[1][6] - va[3][6]
					elseif va[2] and (va[1][6] - va[2][6])<=20 and va[2][5]==0 then
						temp[ca][5] = va[1][6] - va[2][6]
					else
						temp[ca][5] = 0
					end
					temp[ca][7] = 0
					temp[ca][8] = 0
					temp[ca][9] = DPSMateX:GetUserById(va[1][1])
					temp[ca][10] = ca
					for p=1, 3 do
						if va[p] then
							if temp[ca][6] then
								temp[ca][6] = temp[ca][6]..", "..DPSMateX:GetAbilityById(va[p][2])
							else
								temp[ca][6] = DPSMateX:GetAbilityById(va[p][2])
							end
							if va[p][5]==1 then
								temp[ca][7] = temp[ca][7]+va[p][3]
							else
								temp[ca][8] = temp[ca][8]+va[p][3]
							end
						end
					end
				end
			end
			for ca,va in temp do
				local i=1
				while true do
					if not a[i] then
						tinsert(a, i, va)
						break
					elseif a[i][4]<va[4] then
						tinsert(a, i, va)
						break
					end
					i = i + 1
				end
			end
		end
	end
	return a
end

function DPSMateX.Modules.DetailsDeathsTotal:ScrollFrameUpdate(direction)
	Offset = Offset - direction
	if (Offset+11)>TL then
		Offset = TL-11
	end
	if Offset<0 then
		Offset = 0
	end
	for i=1, 11 do
		self:UpdateRow(i, "", 0, "", 0, "", "", "", "")
	end
	for i=1, 11 do
		local real = i + Offset
		if not DetailsArr[real] then break end
		self:UpdateRow(i, DetailsArr[real][3], DetailsArr[real][4], DetailsArr[real][2], DetailsArr[real][5], DetailsArr[real][6], DetailsArr[real][7], DetailsArr[real][8], DetailsArr[real][9], DetailsArr[real][10])
	end
end

function DPSMateX.Modules.DetailsDeathsTotal:CreateGraphTable(obj)
	local lines = {}
	comp = comp or ""
	for i=1, 11 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(obj, 10, 375-i*30, 870, 375-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[12] = DPSMateX.Options.graph:DrawLine(obj, 80, 370, 80, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(obj, 150, 370, 150, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[14] = DPSMateX.Options.graph:DrawLine(obj, 240, 370, 240, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[14]:Show()
	
	lines[18] = DPSMateX.Options.graph:DrawLine(obj, 400, 370, 400, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[18]:Show()
	
	lines[15] = DPSMateX.Options.graph:DrawLine(obj, 330, 370, 330, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[15]:Show()
	
	lines[16] = DPSMateX.Options.graph:DrawLine(obj, 685, 370, 685, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[16]:Show()
	
	lines[17] = DPSMateX.Options.graph:DrawLine(obj, 775, 370, 775, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[17]:Show()
end

function DPSMateX.Modules.DetailsDeathsTotal:ShowTooltip(user, obj, id)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.Deaths, DPSMateX.CacheUser[user], curKey, id)
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(user.."'s "..strlower(DPSMateX.L["deathhistory"]), 1,1,1)
	for i=1, DPSMateX.Settings["subviewrows"] do
		if not a[i] then break end
		local type = " (HIT)"
		if c[i][3]==1 then type=" (CRIT)" elseif c[i][3]==2 then type=" (CRUSH)" end
		if c[i][2]==1 then
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),"+"..c[i][1]..type,0.67,0.83,0.45,0.67,0.83,0.45)
		else
			GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),"-"..c[i][1]..type,0.77,0.12,0.23,0.77,0.12,0.23)
		end
	end
	GameTooltip:Show()
end