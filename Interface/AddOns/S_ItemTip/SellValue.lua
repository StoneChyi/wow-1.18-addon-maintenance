ShowSellValueTooltip = ShowSellValueTooltip or 0


function SellValue_OnLoad()
	SellValue_RebuildDB()
	-- ⚠️ 关键：SavedVariables 的还原发生在「插件文件执行完之后」（VARIABLES_LOADED 之前），
	--   所以这里建好的内置库会被存档里的旧 SellValues 整表覆盖（存档是脏的：22505 被存成 88）。
	--   下面两个事件里再重建一次，确保登录后用的一定是内置库。
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("PLAYER_ENTERING_WORLD")

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

SellValue_DBOwned = SellValue_DBOwned or nil   -- 记住「我们自己建的那张表」的引用
function SellValue_RebuildDB()
	SellValues = nil
	SellValue_InitializeDB()
	SellValue_DBOwned = SellValues

end

function SellValue_OnEvent()
    if event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD" then
        -- 只有「存档把整表换成了另一个引用」才需要重建（老版本存档里还留着 SellValues 那张脏表：
        -- 2 万多条全小于 100 铜，22505 被存成 88 = 它的装等）。
        -- 现在 toc 已经不再声明这个变量，正常存档进来后 SellValues 还是我们建的那张，
        -- 引用没变就什么都不做 —— 省掉每次登录 2.2 万条赋值。
        if SellValues ~= SellValue_DBOwned then
            return SellValue_RebuildDB()
        end
        return
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

