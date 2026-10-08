local DPSMateX = DPSMateX
-- Global Variables
DPSMateX.Modules.DetailsFails = {}

-- Local variables
local DetailsUser, DetailsUserComp = "", ""
local curKey = 1
local db, cbt = {}, 0
local Buffpos, BuffposComp = 0, 0
local _G = getglobal
local tinsert = table.insert

function DPSMateX.Modules.DetailsFails:UpdateDetails(obj, key)
	DPSMateX_Details_CompareFails:Hide()
	
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_Fails_Title:SetText(DPSMateX.L["failsof"]..obj.user)
	Buffpos = 0
	self:CleanTables("")
	self:UpdateBuffs(0, "")
	DPSMateX_Details_Fails:Show()
	DPSMateX_Details_Fails:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsFails:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareFails_Title:SetText(DPSMateX.L["failsof"]..comp)
	BuffposComp = 0
	self:CleanTables("Compare")
	self:UpdateBuffs(0, "Compare")
	DPSMateX_Details_CompareFails:Show()
end

function DPSMateX.Modules.DetailsFails:CreateGraphTable(obj)
	local lines = {}
	for i=1, 6 do
		-- Horizontal
		DPSMateX.Options.graph:DrawLine(obj, 5, 223-i*30, 670, 223-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	end
	-- Vertical
	DPSMateX.Options.graph:DrawLine(obj, 235, 215, 235, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	DPSMateX.Options.graph:DrawLine(obj, 480, 215, 480, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	DPSMateX.Options.graph:DrawLine(obj, 570, 215, 570, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
end

function DPSMateX.Modules.DetailsFails:CleanTables(comp)
	local path = "DPSMateX_Details_"..comp.."Fails_Buffs_Row"
	for i=1, 6 do
		_G(path..i.."_Icon"):SetTexture()
		_G(path..i.."_Ability"):SetText()
		_G(path..i.."_Victim"):SetText()
		_G(path..i.."_Type"):SetText()
		_G(path..i.."_Amount"):SetText()
	end
end

function DPSMateX.Modules.DetailsFails:Replace(text)
	local a,b = strfind(text, "%(")
	if a and b then
		return strsub(text, 1, a-1)
	end
	return text
end

function DPSMateX.Modules.DetailsFails:Type(id)
	if id == 1 then
		return DPSMateX.L["friendlyfire"]
	elseif id == 2 then
		return DPSMateX.L["damagetaken"]
	else
		return DPSMateX.L["debufftaken"]
	end
end

function DPSMateX.Modules.DetailsFails:UpdateBuffs(arg1, comp, cname)
	if comp~="" and comp then
		cname = DetailsUserComp
	end
	local a = db[DPSMateX.CacheUser[cname or DetailsUser][1]]
	local t1TL = DPSMateX:TableLength(a)-6
	local path = "DPSMateX_Details_"..comp.."Fails_Buffs_Row"
	if comp~="" and comp then
		BuffposComp=BuffposComp-(arg1 or 0)
		if BuffposComp<0 then BuffposComp = 0 end
		if BuffposComp>t1TL then BuffposComp = t1TL end
		if t1TL<0 then BuffposComp = 0 end
		for i=1, 6 do
			local pos = BuffposComp + i
			if not a[pos] then break end
			local ab = DPSMateX:GetAbilityById(a[pos][3])
			_G(path..i).id = a[pos][3]
			_G(path..i.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(self:Replace(ab)))
			_G(path..i.."_Ability"):SetText(ab)
			_G(path..i.."_Victim"):SetText(DPSMateX:GetUserById(a[pos][2]))
			_G(path..i.."_Type"):SetText(self:Type(a[pos][1]))
			_G(path..i.."_Amount"):SetText(a[pos][4])
		end
	else
		Buffpos=Buffpos-(arg1 or 0)
		if Buffpos<0 then Buffpos = 0 end
		if Buffpos>t1TL then Buffpos = t1TL end
		if t1TL<0 then Buffpos = 0 end
		for i=1, 6 do
			local pos = Buffpos + i
			if not a[pos] then break end
			local ab = DPSMateX:GetAbilityById(a[pos][3])
			_G(path..i).id = a[pos][3]
			_G(path..i.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(self:Replace(ab)))
			_G(path..i.."_Ability"):SetText(ab)
			_G(path..i.."_Victim"):SetText(DPSMateX:GetUserById(a[pos][2]))
			_G(path..i.."_Type"):SetText(self:Type(a[pos][1]))
			_G(path..i.."_Amount"):SetText(a[pos][4])
		end
	end
end
