ShowSellValueTooltip = ShowSellValueTooltip or 0


function SellValue_OnLoad()
	SellValue_InitializeDB()
	this:RegisterEvent("MERCHANT_SHOW")

	SellValue_Saved_OnTooltipAddMoney = SellValue_Tooltip:GetScript("OnTooltipAddMoney")
	SellValue_Tooltip:SetScript("OnTooltipAddMoney", SellValue_OnTooltipAddMoney)

	Stubby.RegisterFunctionHook("EnhTooltip.AddTooltip", 300, tooltipHandler)
	
end

function tooltipHandler(funcVars, retVal, frame, name, link, quality, count, price)

	if ShowSellValueTooltip ~= 1 then
		return nil
	end
	
	if EnhTooltip.LinkType(link) ~= "item" then return end

	local itemID = EnhTooltip.BreakLink(link)
	if (not itemID) then return end
	local _, _, _, _, sType, _, iCount, _, sTexture = GetItemInfo(tonumber(itemID))
	local scount = count
	local sell = SellValues[itemID]

	if sTexture then
		EnhTooltip.SetIcon(sTexture)
	end

--	if sell and (sell > 0) then
--		EnhTooltip.AddLine("售于商贩", sell* scount, embedded, true)
--	end

	if scount and (scount > 1) then
		EnhTooltip.AddLine("每组堆叠 "..iCount, nil, embedded)
	end

--	if sType then
--		EnhTooltip.AddLine("类型 "..sType, nil, embedded)
--		EnhTooltip.LineColor(0.6, 0.4, 0.8)
--	end

	if itemID then
		EnhTooltip.AddLine("物品ID "..itemID, nil, embedded)
		EnhTooltip.LineColor(0.8, 0.5, 0.6)
	end
end

function SellValue_OnEvent()
    if event == "MERCHANT_SHOW" then
        return SellValue_MerchantScan(this)
    end
end

SellValue_Saved_GameTooltip_OnEvent = GameTooltip_OnEvent
GameTooltip_OnEvent = function ()
    if event ~= "CLEAR_TOOLTIP" then
        return SellValue_Saved_GameTooltip_OnEvent()
    end 
end

function SellValue_OnTooltipAddMoney ()
    SellValue_Saved_OnTooltipAddMoney()
    if InRepairMode() then return end
    SellValue_LastItemMoney = arg1 
end

function SellValue_SaveFor(bag, slot, id, money)
    if not (bag and slot and id and money) then return end
		
    local _, stackCount = GetContainerItemInfo(bag, slot)
    if stackCount and stackCount > 0 then
        local costOfOne = money / stackCount
        if not SellValues then SellValues = {} end
		if costOfOne > 0 then
			SellValues[id] = costOfOne
		end
    end
end

function SellValue_MerchantScan(frame)
    for bag=0,NUM_BAG_FRAMES do
        for slot=1,GetContainerNumSlots(bag) do
            local itemId = SellValue_GetItemID(bag, slot)
            if itemId ~= "" then
                SellValue_LastItemMoney = 0
                SellValue_Tooltip:SetBagItem(bag, slot)
                SellValue_SaveFor(bag, slot, itemId, SellValue_LastItemMoney)
            end
        end
    end
end

function SellValue_OnHide()
    this = this:GetParent()
    return GameTooltip_ClearMoney()
end

function SellValue_GetItemID(bag, slot)
    local linktext = nil
  
    if (bag == -1) then
        linktext = GetInventoryItemLink("player", slot)
    else
        linktext = GetContainerItemLink(bag, slot)
    end

    if linktext then
        return tonumber(SellValue_IDFromLink(linktext))
    else
        return ""
    end
end

function SellValue_IDFromLink(itemlink)
    if itemlink then
        local _, _, itemID = string.find(itemlink, "item:(%d+):%d+:%d+:%d+")
        if itemID then
            return itemID
        end
    end
end



SLASH_ITEMID1 = "/itemid"
SlashCmdList["ITEMID"] = function(msg)
	if msg == "show" then 
		ShowSellValueTooltip = 1
		print("物品ID框启用")
	elseif msg == "hide" then
		ShowSellValueTooltip = 0
		print("物品ID框关闭")
	elseif msg == "stat" then
		if ShowSellValueTooltip == 1 then
			print("物品ID框已启用")
		else 
			print("物品ID框已关闭")
		end
	else
		print("S_Itemtip插件“itemid”指令用法：")
		print("/itemid show - 打开物品ID框体")
		print("/itemid hide - 关闭物品ID框体")
		print("/itemid stat - 显示物品ID框体状态")
	end
	
end

