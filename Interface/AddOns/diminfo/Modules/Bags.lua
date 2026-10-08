local onestorage = AceLibrary("OneStorage-2.0")
local lastmoney, income = 0, 0

-- 背包
local diminfo_Bag = CreateFrame("Button", "diminfo_Bag", UIParent)
local Text = diminfo_Bag:CreateFontString(nil, "OVERLAY")
Text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
Text:SetPoint("LEFT", diminfo_Durability, "RIGHT", 20, 0)
diminfo_Bag:SetAllPoints(Text)

local usedSlots, usedAmmoSlots, usedSoulSlots, usedProfSlots, ammoQuantity, totalSlots
local function OnEvent()
	-- 是否有箭袋、灵魂袋、专业袋的情况
	usedSlots, usedAmmoSlots, usedSoulSlots, usedProfSlots, ammoQuantity, totalSlots = 0, 0, 0, 0, 0, 0
	local Bags = {0, 1, 2, 3, 4}
	
	for _, bag in Bags do
		local tmp, qty = 0, 0
		for slot = 1, GetContainerNumSlots(bag) do
			local texture, itemCount = GetContainerItemInfo(bag, slot)
			if( texture) then
				tmp = tmp + 1
				qty = qty + itemCount
			end
		end
			
		local isAmmo, isSoul, isProf = onestorage:GetBagTypes(bag)
			
		if isAmmo then
			usedAmmoSlots = usedAmmoSlots + tmp
			ammoQuantity = ammoQuantity + qty
		elseif isSoul then
			usedSoulSlots = usedSoulSlots + tmp
		elseif isProf then
			usedProfSlots = usedProfSlots + tmp
		else
			usedSlots = usedSlots + tmp
			totalSlots = totalSlots + GetContainerNumSlots(bag)
		end
	end
	
	freeSlots = totalSlots - usedSlots

	Text:SetText("背包"..HexColors(SetPercentColor(freeSlots, totalSlots))..freeSlots.."|r")
end

--鼠标提示
diminfo_Bag:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:ClearLines()
	GameTooltip:AddLine("背包")
	GameTooltip:AddLine("左键:背包", .3, 1, .6)
	if IsAddOnLoaded("SUCC-bag") then
		GameTooltip:AddLine("右键:离线银行", .3, 1, .6)
	elseif IsAddOnLoaded("Bagnon_Forever") then
		GameTooltip:AddLine("右键:离线银行", .3, 1, .6)
	elseif IsAddOnLoaded("OneView") then
		GameTooltip:AddLine("右键:离线银行", .3, 1, .6)
	elseif IsAddOnLoaded("OneBag") then
		GameTooltip:AddLine("右键:离线银行", .3, 1, .6)
	end
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("容量 "..usedSlots.."/"..totalSlots)
	if ammoQuantity and ammoQuantity > 0 then
		GameTooltip:AddLine("弹药 "..ammoQuantity)
	elseif usedSoulSlots and usedSoulSlots > 0 then
		GameTooltip:AddLine("灵魂碎片 "..usedSoulSlots)
	end
	GameTooltip:Show()
end)

diminfo_Bag:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function OnClick()
    if arg1 == "LeftButton" then
        OpenAllBags()
    else
        if IsAddOnLoaded("SUCC-bag") and SUCC_bagOfflineBank_Toggle then
            -- 打开或关闭SUCC_bagOfflineBank
            SUCC_bagOfflineBank_Toggle()
        elseif IsAddOnLoaded("Bagnon_Forever") and BagnonFrame_Toggle then
            BagnonFrame_Toggle("Banknon")
        elseif IsAddOnLoaded("OneView") and OneViewFrame then
            if OneViewFrame:IsVisible() then
                OneViewFrame:Hide()
            else
                OneViewFrame:Show()
            end
        elseif IsAddOnLoaded("OneBag") and OneViewFrame then
            if OneViewFrame:IsVisible() then
                OneViewFrame:Hide()
            else
                OneViewFrame:Show()
            end
        end
    end
end

diminfo_Bag:RegisterEvent("PLAYER_LOGIN")
diminfo_Bag:RegisterEvent("BAG_UPDATE")
diminfo_Bag:SetScript("OnEvent", OnEvent)
diminfo_Bag:SetScript("OnMouseDown", function() OnClick() end)