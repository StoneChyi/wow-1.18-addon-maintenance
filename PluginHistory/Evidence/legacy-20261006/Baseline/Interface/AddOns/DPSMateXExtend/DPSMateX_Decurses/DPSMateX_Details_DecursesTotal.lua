local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsDecursesTotal = {}

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

function DPSMateX.Modules.DetailsDecursesTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsArr = self:EvalDetailsTable()
	Offset = 0
	TL = DPSMateX:TableLength(DetailsArr)
	self:ScrollFrameUpdate(0)
	DPSMateX_Details_Decurses_Total_Title:SetText(DPSMateX.L["decursessum"])
	DPSMateX_Details_Decurses_Total:Show()
	DPSMateX_Details_Decurses_Total:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsDecursesTotal:UpdateRow(row, a, b, c, d, e)
	_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row).user = c
	_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_Time"):SetText(a or DPSMateX.DB.UserUnknown)
	if b~=0 then
		_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_CombatTime"):SetText(strformat("%.2f", b).."s")
	else
		_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_CombatTime"):SetText("")
	end
	if c == "" then
		_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_Cause"):SetText("")
	else
		_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_Cause"):SetText("|cFF"..hexClassColor[DPSMateX.CacheUser[c][2] or "warrior"]..c.."|r")
	end
	if d == "" then
		_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_Target"):SetText("")
	else
		_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_Target"):SetText("|cFF"..hexClassColor[DPSMateX.CacheUser[d][2] or "warrior"]..d.."|r")
	end
	_G("DPSMateX_Details_Decurses_Total_LogDetails_Row"..row.."_Ability"):SetText(e)
end

function DPSMateX.Modules.DetailsDecursesTotal:EvalDetailsTable()
	local a = {}
	for cat, val in db do -- user
		local name = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, name) then
			for ca, va in val["i"][2] do
				local ab = DPSMateX:GetAbilityById(va[2])
				local abtwo = DPSMateX:GetUserById(va[3])
				if DPSMateX.Modules.Decurses:IsValid(ab, abtwo, DPSMateX.CacheUser[name]) then
					local i=1
					while true do
						if not a[i] then
							tinsert(a, i, {va[4], va[1], name, abtwo, ab, cat})
							break
						elseif a[i][2]<va[1] then
							tinsert(a, i, {va[4], va[1], name, abtwo, ab, cat})
							break
						end
						i=i+1
					end
				end
			end
		end
	end
	return a
end

function DPSMateX.Modules.DetailsDecursesTotal:ScrollFrameUpdate(direction)
	Offset = Offset - direction
	if (Offset+11)>TL then
		Offset = TL-11
	end
	if Offset<0 then
		Offset = 0
	end
	for i=1, 11 do
		self:UpdateRow(i, "", 0, "", "", "")
	end
	for i=1, 11 do
		local real = i + Offset
		if not DetailsArr[real] then break end
		self:UpdateRow(i, DetailsArr[real][1], DetailsArr[real][2], DetailsArr[real][3], DetailsArr[real][4], DetailsArr[real][5], DetailsArr[real][6])
	end
end

function DPSMateX.Modules.DetailsDecursesTotal:CreateGraphTable(obj)
	local lines = {}
	comp = comp or ""
	for i=1, 11 do
		-- Horizontal
		lines[i] = DPSMateX.Options.graph:DrawLine(obj, 10, 375-i*30, 570, 375-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
		lines[i]:Show()
	end
	-- Vertical
	lines[12] = DPSMateX.Options.graph:DrawLine(obj, 80, 370, 80, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[12]:Show()
	
	lines[13] = DPSMateX.Options.graph:DrawLine(obj, 150, 370, 150, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[13]:Show()
	
	lines[14] = DPSMateX.Options.graph:DrawLine(obj, 240, 370, 240, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[14]:Show()
	
	lines[15] = DPSMateX.Options.graph:DrawLine(obj, 330, 370, 330, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	lines[15]:Show()
end

function DPSMateX.Modules.DetailsDecursesTotal:ShowTooltip(user, obj, id)
	local a,b,c = DPSMateX:EvalTable(DPSMateX.Modules.Decurses, DPSMateX.CacheUser[user], curKey, id)
	GameTooltip:SetOwner(obj, "TOPLEFT")
	GameTooltip:AddLine(user.."'s "..strlower(DPSMateX.L["decurses"]), 1,1,1)
	for i=1, DPSMateX.Settings["subviewrows"] do
		if not a[i] then break end
		GameTooltip:AddDoubleLine(i..". "..DPSMateX:GetAbilityById(a[i]),c[i].." ("..strformat("%.2f", 100*c[i]/b).."%)",1,1,1,1,1,1)
	end
	GameTooltip:Show()
end