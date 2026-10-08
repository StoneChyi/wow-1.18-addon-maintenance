local DPSMateX = DPSMateX

-- Global Variables
DPSMateX.Modules.DetailsSunderArmorTotal = {}

-- Local variables
local curKey = 1
local db, cbt = {}, 0
local Buffpos = 0
local _G = getglobal
local tinsert = table.insert
local DetailsArr = {}
local TL = 0

function DPSMateX.Modules.DetailsSunderArmorTotal:UpdateDetails(obj, key)
	curKey = key
	db, cbt = DPSMateX:GetMode(key)
	DPSMateX_Details_SunderArmorTotal_Title:SetText(DPSMateX.L["sunderarmorsum"])
	Buffpos = 0
	DetailsArr = self:EvalDetailsTable()
	TL = DPSMateX:TableLength(DetailsArr)-6
	self:CleanTables()
	self:UpdateBuffs(0)
	DPSMateX_Details_SunderArmorTotal:Show()
	
	DPSMateX_Details_SunderArmorTotal:SetScale((DPSMateX.Settings["targetscale"] or 0.58)/UIParent:GetScale())
end

function DPSMateX.Modules.DetailsSunderArmorTotal:EvalDetailsTable()
	local z, b = {}, {}
	for cat, _ in DPSMateX.DBCache.DamageDone[curKey] do
		local user = DPSMateX:GetUserById(cat)
		if DPSMateX:ApplyFilter(curKey, user) then
			local c,_,a = DPSMateX:EvalTable(DPSMateX.Modules.SunderArmor, DPSMateX.CacheUser[DPSMateX:GetUserById(cat)], curKey)
			for ca, va in a do
				if z[c[ca]] then
					z[c[ca]] = z[c[ca]] + va
				else
					z[c[ca]] = va
				end
			end
		end
	end
	for cat, val in z do
		local i=1
		while true do
			if not b[i] then
				tinsert(b, i, {val,cat})
				break
			elseif b[i][1]<val then
				tinsert(b, i, {val,cat})
				break
			end
			i=i+1
		end
	end
	z = nil
	return b
end

function DPSMateX.Modules.DetailsSunderArmorTotal:CreateGraphTable(obj)
	local lines = {}
	for i=1, 6 do
		-- Horizontal
		DPSMateX.Options.graph:DrawLine(obj, 5, 223-i*30, 345, 223-i*30, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
	end
	-- Vertical
	DPSMateX.Options.graph:DrawLine(obj, 235, 215, 235, 15, 20, {0.5,0.5,0.5,0.5}, "BACKGROUND")
end

function DPSMateX.Modules.DetailsSunderArmorTotal:CleanTables(comp)
	local path = "DPSMateX_Details_SunderArmorTotal_Buffs_Row"
	for i=1, 6 do
		_G(path..i.."_Icon"):SetTexture()
		_G(path..i.."_Name"):SetText()
		_G(path..i.."_Count"):SetText()
	end
end

function DPSMateX.Modules.DetailsSunderArmorTotal:Replace(text)
	local a,b = strfind(text, "%(")
	if a and b then
		return strsub(text, 1, a-1)
	end
	return text
end

function DPSMateX.Modules.DetailsSunderArmorTotal:UpdateBuffs(arg1, comp, cname)
	local path = "DPSMateX_Details_SunderArmorTotal_Buffs_Row"
	Buffpos=Buffpos-(arg1 or 0)
	if Buffpos<0 then Buffpos = 0 end
	if Buffpos>TL then Buffpos = TL end
	if TL<0 then Buffpos = 0 end
	for i=1, 6 do
		local pos = Buffpos + i
		if not DetailsArr[pos] then break end
		local ab = DPSMateX:GetAbilityById(DetailsArr[pos][2])
		_G(path..i.."_Icon"):SetTexture(DPSMateX.BabbleSpellX:GetSpellIcon(self:Replace(ab)))
		_G(path..i.."_Name"):SetText(ab)
		_G(path..i.."_Count"):SetText(DetailsArr[pos][1])
	end
end
