local tmpCount = 0
local currentCharacter = nil
local S_Position = nil


function S_ItemTip_ResetDB()
	if not currentCharacter then
		currentCharacter = GetRealmName() .. "-" .. UnitName("player")
		if not currentCharacter or currentCharacter == "-" then
			return
		end
	end
	S_CountDB = {}
	S_CountDB[currentCharacter] = {}
end

function InventoryCounter_UpdateBagsAndBank()
	if not S_CountDB[currentCharacter] then
		S_CountDB[currentCharacter] = {}
	end
	S_Position = "银行"
	S_CountDB[currentCharacter][S_Position] = nil
	S_CountDB[currentCharacter][S_Position] = {}
  
	for bag = -1, 10 do
		if bag == 0 then
		  S_Position = "背包"
		  S_CountDB[currentCharacter][S_Position] = nil
		  S_CountDB[currentCharacter][S_Position] = {}
		end
		if bag == 5 then
		  S_Position = "银行"
		end
		local bagSize = GetContainerNumSlots(bag)
		if bagSize > 0 then
			for slot = 1, bagSize do
				local _, itemCount = GetContainerItemInfo(bag, slot)
				-- SuperWoW：带充能物品（法力/巫师之油等）的 count 返回负的剩余充能（剩5次→-5），
				-- 取负还原为真实充能数再入库，否则 tooltip 合计显示负数（与 OneBag/aux 同口径）
				if itemCount and itemCount < 0 and SetAutoloot then itemCount = -itemCount end
				local itemLink = GetContainerItemLink(bag, slot)
				if itemCount then
					local itemstring = string.sub(itemLink, string.find(itemLink, "%[")+1, string.find(itemLink, "%]")-1)
					tmpCount = S_CountDB[currentCharacter][S_Position][itemstring]
					if not tmpCount then
						S_CountDB[currentCharacter][S_Position][itemstring] = itemCount
					else
						S_CountDB[currentCharacter][S_Position][itemstring] = tmpCount + itemCount
					end
				end
			end
		end
	end
end

S_ItemTip_Frame = CreateFrame("Frame", "S_ItemTip_Frame", GameTooltipTemplate)
S_ItemTip_Frame:RegisterEvent("VARIABLES_LOADED")
S_ItemTip_Frame:RegisterEvent("BAG_UPDATE")
S_ItemTip_Frame:RegisterEvent("BANKFRAME_OPENED")
S_ItemTip_Frame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
S_ItemTip_Frame:SetScript("OnEvent", function (self)
    if event == "VARIABLES_LOADED" then
		currentCharacter = GetRealmName() .. "-" .. UnitName("player")
		if not S_CountDB then
			S_CountDB = {}
		end
		if not S_CountDB[currentCharacter] then
			S_CountDB[currentCharacter] = {}
		end
    end
	
    if event == "BAG_UPDATE" then
		S_Position = "背包"
		if not S_CountDB[currentCharacter] then
			S_CountDB[currentCharacter] = {}
		end
		S_CountDB[currentCharacter][S_Position] = nil
		S_CountDB[currentCharacter][S_Position] = {}
		for bag = 0, 4 do
			bagSize = GetContainerNumSlots(bag)
			if bagSize > 0 then
				for slot = 1, bagSize do
					local _, itemCount = GetContainerItemInfo(bag, slot)
					-- SuperWoW 负充能修正，同上（背包路径）
					if itemCount and itemCount < 0 and SetAutoloot then itemCount = -itemCount end
					local itemLink = GetContainerItemLink(bag, slot)
					if itemCount then
						local itemstring = string.sub(itemLink, string.find(itemLink, "%[")+1, string.find(itemLink, "%]")-1)
						tmpCount = S_CountDB[currentCharacter][S_Position][itemstring]
						if not tmpCount then
							S_CountDB[currentCharacter][S_Position][itemstring] = itemCount
						else
							S_CountDB[currentCharacter][S_Position][itemstring] = tmpCount + itemCount
						end
					end
				end
			end
		end
    end
    if event == "BANKFRAME_OPENED" then
		InventoryCounter_UpdateBagsAndBank()
    end
    if event == "PLAYERBANKSLOTS_CHANGED" then
		InventoryCounter_UpdateBagsAndBank()
    end
end)
 
local S_ItemTipCountFrame = CreateFrame("Frame", "S_ItemTipCountFrame", GameTooltip)

S_ItemTipCountFrame:SetScript("OnShow", function(self)

	local currentRealm = GetRealmName()
	local realmPrefix = currentRealm .. "-"
	local realmPrefixLen = string.len(realmPrefix)
	
    if S_CountDB then
		local lbl = getglobal("GameTooltipTextLeft1")
		local tipsframe = GetMouseFocus() and GetMouseFocus():GetName() or ""
		if lbl and (tipsframe ~= "WorldFrame") and (tipsframe ~= "Minimap") and not string.find(tipsframe, "pfMiniMapPin") and getglobal('GameTooltipTextLeft2'):GetText()~= ITEM_BIND_QUEST then
			local itemName, totalCount, initLineAdded = lbl:GetText(), 0, nil
			
			if itemName and (itemName == "炉石" or itemName == "Hearthstone") then
				return
			end
			
			local locationCount = 0
			local totalItemCount = 0
			
			for char,charData in pairs(S_CountDB) do
				if string.sub(char, 1, realmPrefixLen) == currentRealm .. "-" then
					for slot,slotData in pairs(charData) do
						local count = slotData[itemName]
						if count then
							locationCount = locationCount + 1
							totalItemCount = totalItemCount + count
						end
					end
				end
			end
			
			if locationCount > 1 or totalItemCount > 1 then
				for char,_ in pairs(S_CountDB) do
					if string.sub(char, 1, realmPrefixLen) == currentRealm .. "-" then
						for slot,_ in pairs(S_CountDB[char]) do
							local count = S_CountDB[char][slot][itemName]
							if count then
								if not initLineAdded then
									GameTooltip:AddLine(" ", 0, 0, 0, 0)
									initLineAdded = true
								end
								totalCount = totalCount + count
								local displayName = string.sub(char, realmPrefixLen + 1)
								GameTooltip:AddDoubleLine(displayName .. "[" .. slot .. "]", count, 0.65, 0.75, 0.85, 0.65, 0.75, 0.85)
							end
						end
					end
				end
				if (totalCount>1) then
					GameTooltip:AddDoubleLine("合计", totalCount, 0, 0.8, 1, 0, 0.8, 1)
				end
			end
		end
    end
    GameTooltip:Show()
end)

S_ItemTipCountFrame:SetScript("OnHide", function()
	GameTooltip:Hide()
end)