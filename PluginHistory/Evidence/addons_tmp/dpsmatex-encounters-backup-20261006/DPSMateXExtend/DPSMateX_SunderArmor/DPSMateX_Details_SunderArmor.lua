local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.DetailsSunderArmor = {}

-- Local variables
local DetailsUser, DetailsUserComp = "", ""
local curKey = 1
local db, cbt = {}, 0
local Buffpos, BuffposComp = 0, 0
local _G = getglobal
local tinsert = table.insert

function DPSMateX.Modules.DetailsSunderArmor:UpdateDetails(obj, key)
	DPSMateX_Details_CompareSunderArmor:Hide()
	
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DetailsUser = obj.user
	DetailsUserComp = nil
	DPSMateX_Details_SunderArmor_Title:SetText(DPSMateX.L["sunderarmorof"]..obj.user)
	Buffpos = 0
	self:CleanTables("")
	self:UpdateBuffs(0, "")
	DPSMateX_Details_SunderArmor:Show()
	
	DPSMateX_Details_SunderArmor:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsSunderArmor:UpdateCompare(obj, key, comp)
	self:UpdateDetails(obj, key)

	DetailsUserComp = comp
	DPSMateX_Details_CompareSunderArmor_Title:SetText(DPSMateX.L["sunderarmorof"]..comp)
	BuffposComp = 0
	self:CleanTables("Compare")
	self:UpdateBuffs(0, "Compare")
	DPSMateX_Details_CompareSunderArmor:Show()
end

function DPSMateX.Modules.DetailsSunderArmor:CreateGraphTable(obj)
	local lines = {}
	for i=1, 6 do
		-- Horizontal
		DPSMateX.Options.graph:DrawLine(obj, 5, 223-i*30, 345, 223-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	end
	-- Vertical
	DPSMateX.Options.graph:DrawLine(obj, 235, 215, 235, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
end

function DPSMateX.Modules.DetailsSunderArmor:CleanTables(comp)
	local path = "DPSMateX_Details_"..comp.."SunderArmor_Buffs_Row"
	for i=1, 6 do
		_G(path..i.."_Icon"):SetTexture()
		_G(path..i.."_Name"):SetText()
		_G(path..i.."_Count"):SetText()
	end
end

function DPSMateX.Modules.DetailsSunderArmor:Replace(text)
	local a,b = strfind(text, "%(")
	if a and b then
		return strsub(text, 1, a-1)
	end
	return text
end

function DPSMateX.Modules.DetailsSunderArmor:UpdateBuffs(arg1, comp, cname)
	if comp~="" and comp then
		cname = DetailsUserComp
	end
	local c,b,a = DPSMateX:EvalTable(DPSMateX.Modules.SunderArmor, DPSMateX.CacheUser[cname or DetailsUser], curKey)
	local t1TL = DPSMateX:TableLength(a)-6
	local path = "DPSMateX_Details_"..comp.."SunderArmor_Buffs_Row"
	if comp~="" and comp then
		BuffposComp=BuffposComp-(arg1 or 0)
		if BuffposComp<0 then BuffposComp = 0 end
		if BuffposComp>t1TL then BuffposComp = t1TL end
		if t1TL<0 then BuffposComp = 0 end
		for i=1, 6 do
			local pos = BuffposComp + i
			if not a[pos] then break end
			local ab = DPSMateX:GetAbilityById(c[pos])
			_G(path..i).id = c[pos]
			_G(path..i.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(self:Replace(ab)))
			_G(path..i.."_Name"):SetText(ab)
			_G(path..i.."_Count"):SetText(a[pos])
		end
	else
		Buffpos=Buffpos-(arg1 or 0)
		if Buffpos<0 then Buffpos = 0 end
		if Buffpos>t1TL then Buffpos = t1TL end
		if t1TL<0 then Buffpos = 0 end
		for i=1, 6 do
			local pos = Buffpos + i
			if not a[pos] then break end
			local ab = DPSMateX:GetAbilityById(c[pos])
			_G(path..i).id = c[pos]
			_G(path..i.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(self:Replace(ab)))
			_G(path..i.."_Name"):SetText(ab)
			_G(path..i.."_Count"):SetText(a[pos])
		end
	end
end
