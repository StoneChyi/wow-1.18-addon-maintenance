--由佚名基于Shagu装备评分插件修改 20250210
--别特鸣谢：天乖乖

local lib = LibStub("LibItem-enUS-1.0")
local libLevel = LibStub("LibItemLevel-1.0")
LibItem_Level = libLevel and libLevel.Item_Level or LibItem_Level or {}
local USE_PFUI_STYLE = (pfUI and type(pfUI) == "table") or IsAddOnLoaded("pfUI")

local EquipSoltList = {
	INVTYPE_2HWEAPON,
	INVTYPE_BODY,
	INVTYPE_CHEST,
	INVTYPE_CLOAK,
	INVTYPE_FEET,
	INVTYPE_FINGER,
	INVTYPE_HAND,
	INVTYPE_HEAD,
	INVTYPE_HOLDABLE,
	INVTYPE_LEGS,
	INVTYPE_NECK,
	INVTYPE_RANGED,
	INVTYPE_RELIC,
	INVTYPE_ROBE,
	INVTYPE_SHIELD,
	INVTYPE_SHOULDER,
	INVTYPE_TABARD,
	INVTYPE_TRINKET,
	INVTYPE_WAIST,
	INVTYPE_WEAPON,
	INVTYPE_WEAPONMAINHAND,
	INVTYPE_WEAPONOFFHAND,
	INVTYPE_WRIST,
	"枪械",
	"弩",
	"魔杖",
	"投掷武器",
	"弹药",
}

local function IsEquip()
	if ItemRefTooltip:IsVisible() then
		for i = 2,5 do
			local EquipText = getglobal("ItemRefTooltipTextLeft"..i):GetText()
			for _, equip in pairs(EquipSoltList) do
				if EquipText == equip then
					return true
				end
			end
		end
	else
		for i = 2,5 do
			local EquipText = getglobal("GameTooltipTextLeft"..i):GetText()
			for _, equip in pairs(EquipSoltList) do
				if EquipText == equip then
					return true
				end
			end
		end	
	end

	return false
end

local function Add_ItemLevelLine(itemID, itemLevel)
    if not itemID or not itemLevel or itemLevel <= 0 then return end

    if IsEquip() then
        local tooltip = ItemRefTooltip:IsVisible() and ItemRefTooltip or GameTooltip
        local lineAdded = false

         for i = 1, tooltip:NumLines() do
            local line = _G[tooltip:GetName() .. "TextLeft" .. i]
            if line and line:GetText() and string.find(line:GetText(), "装备等级") then
                lineAdded = true
                break
            end
        end

        if not lineAdded then
            tooltip:AddLine("装备等级 " .. itemLevel, 1, 1, 0)
            tooltip:Show()
        end
    end
end

ItemSocre = CreateFrame("Frame" , "ItemSocreTooltip", GameTooltip)
ItemSocre:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
ItemSocre:SetScript("OnEvent", function()
	-- 处理鼠标悬停：如果 mouseover 是玩家则显示装等（同时避免与 SetUnit 钩子重复）
	if GameTooltip:IsVisible() and UnitExists("mouseover") and UnitIsPlayer("mouseover") then
		local score = ItemSocre:ScanUnit("mouseover")
		if score and score > 0 then
			local found = false
            for i = 1, GameTooltip:NumLines() do
                local line = _G["GameTooltipTextLeft" .. i]
                if line and line:GetText() and string.find(line:GetText(), "装备等级") then
                    found = true
                    break
                end
            end
            if not found then
				GameTooltip:AddLine("装备等级 " .. score, 1, 1, 0)
				GameTooltip:Show()
			end
		end
	end
end)

ItemSocre:SetScript("OnShow", function()
	if GameTooltip.itemLink then
		local _, _, itemID = string.find(GameTooltip.itemLink, "item:(%d+):%d+:%d+:%d+")
		local itemLevel = LibItem_Level[tonumber(itemID)] or 0
		Add_ItemLevelLine(itemID, itemLevel)
	end
end)

ItemSocre:SetScript("OnHide", function()
	GameTooltip.itemLink = nil
end)

hooksecurefunc("SetItemRef", function(link, button)
	if ItemRefTooltip:IsVisible() then
		local _, _, itemID = string.find(link, "item:(%d+):%d+:%d+:%d+")
		local itemLevel = LibItem_Level[tonumber(itemID)] or 0
		Add_ItemLevelLine(itemID, itemLevel)
	end
end)

if IsAddOnLoaded("StatCompare") then
	StatCompareSelfFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	StatCompareSelfFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
	StatCompareSelfFrame:RegisterEvent("BAG_UPDATE")
	StatCompareSelfFrame:SetScript("OnEvent", function()
		local score = ItemSocre:ScanUnit("player")
		if score and score > 0 then
			if USE_PFUI_STYLE then
				PlayerItemGS:SetText("装等: " .. score)
			else
				PlayerItemGS:SetText("装备等级: " .. score)
			end
			PlayerItemGS:SetTextColor(1, 1, 0)
		else
			PlayerItemGS:SetText()
		end
	end)
end

-- 增加AtlasLoot装备装等显示支持
if AtlasLootItem_OnEnter then
    local Hook_AtlasLootItem_OnEnter = AtlasLootItem_OnEnter
    AtlasLootItem_OnEnter = function()
        Hook_AtlasLootItem_OnEnter()
        local sid = this.itemID
        if sid == 0 then
            return
        end

        local st = string.sub(sid, 1, 1)
        local itemID = sid
        if st == "e" then
            return
        elseif st == "s" then
            if GetSpellInfoVanillaDB then
                itemID = GetSpellInfoVanillaDB["craftspells"][tonumber(string.sub(sid, 2))]["craftItem"]
            else
                return
            end
        end

        local tooltip = AtlasLootTooltip
        if st == "s" then
            tooltip = AtlasLootTooltip2
        end

        local itemLevel = LibItem_Level[tonumber(itemID)] or 0
        if itemLevel == 0 then
            local itemName = GetItemInfo(itemID)
            if itemName and lib and lib.Item_enUS then
                for realID, engName in pairs(lib.Item_enUS) do
                    if engName == itemName then
                        itemLevel = LibItem_Level[realID] or 0
                        break
                    end
                end
            end
        end

        if itemLevel > 0 then
            local lineAdded = false
            for i = 1, tooltip:NumLines() do
                local line = _G[tooltip:GetName().."TextLeft"..i]
                if line and line:GetText() and string.find(line:GetText(), "装备等级") then
                    lineAdded = true
                    break
                end
            end
            if not lineAdded then
                tooltip:AddLine("装备等级 " .. itemLevel, 1, 1, 0)
                tooltip:Show()
            end
        end
    end
end

local ItemSocreHookInspectUnit = InspectUnit
function InspectUnit(unit)
	ItemSocreHookInspectUnit(unit)
	local score = ItemSocre:ScanUnit("target")
	if IsAddOnLoaded("StatCompare") then
		if score and score > 0 then
			TargetItemGS:SetText("装备等级 " .. score)
			TargetItemGS:SetTextColor(1, 1, 0)
		else
			TargetItemGS:SetText()
		end
	end
end

function ItemSocre:Calculate(rarity, ilvl)
	if not rarity then rarity = 0 end

	local qualityScale = 1
	if rarity == 5 then
		qualityScale = 1.3
	elseif rarity == 4 then
		qualityScale = 1.0
	elseif rarity == 3 then
		qualityScale = 0.85
	elseif rarity == 2 then
		qualityScale = 0.6
	elseif rarity == 1 then
		qualityScale = 0.25
	end

	return ilvl * qualityScale
end

function ItemSocre:ScanUnit(unit)
    if not UnitIsPlayer(unit) then return nil end

    local score = 0
    local _, class = UnitClass(unit)
    local isHunter = (class == "HUNTER")

    local slotCoefficients = {
        [1] = 1,
        [2] = 0.5625,
        [3] = 0.75,
        [5] = 1,
        [6] = 0.5625,
        [7] = 0.75,
        [8] = 0.75,
        [9] = 0.75,
        [10] = 0.75,
        [11] = 0.5625,
        [12] = 0.5625,
        [13] = 0.5625,
        [14] = 0.5625,
        [15] = 0.5625,
        [16] = 1,
        [17] = 1,
        [18] = 0.3164,
    }

    for i = 1, 19 do
        if i ~= 4 and i ~= 19 then
            local itemLink = GetInventoryItemLink(unit, i)
            if itemLink then
                local _, _, itemID = string.find(itemLink, "item:(%d+):%d+:%d+:%d+")
                local itemLevel = LibItem_Level[tonumber(itemID)] or 0
                local itemName, _, itemRarity = GetItemInfo(itemID)

                if itemLevel == 0 then              
                    local itemName = GetItemInfo(itemID)
                    if itemName and lib and lib.Item_enUS then
                        for realID, engName in pairs(lib.Item_enUS) do
                            if engName == itemName then
                                local newItemLevel = LibItem_Level[realID] or 0
                                itemLevel = newItemLevel
                                break
                            end
                        end
                    end
                end

                local coef = slotCoefficients[i] or 1

                if i == 16 then
					local _, _, _, _, _, _, _, equipSlot = GetItemInfo(itemID)
					if equipSlot == "INVTYPE_2HWEAPON" then
                        coef = isHunter and 1 or 2.6836
                    else
                        coef = isHunter and 0.5 or 1.6836
                    end
                elseif i == 17 then
                    coef = isHunter and 0.5 or 1
                elseif i == 18 then
                    coef = isHunter and 2 or 0.3164
                end

                local itemScore = ItemSocre:Calculate(itemRarity, itemLevel)
                if itemScore then
                    score = score + (itemScore * coef)
                end
            end
        end
    end

    local divisor = 17
    score = tonumber(string.format("%0.1f", (score / divisor) * 1.355))

    if score ~= 0 then return score else return nil end
end

function ItemSocre:GetItemLinkByName(name)
	for itemID = 1, 25818 do
		local itemName, hyperLink, itemQuality = GetItemInfo(itemID)
		if (itemName and itemName == name) then
			local _, _, _, hex = GetItemQualityColor(tonumber(itemQuality))
			return hex.. "|H"..hyperLink.."|h["..itemName.."]|h|r"
		end
	end
end

local HookSetBagItem = GameTooltip.SetBagItem
function GameTooltip.SetBagItem(self, container, slot)
	GameTooltip.itemLink = GetContainerItemLink(container, slot)
	_, GameTooltip.itemCount = GetContainerItemInfo(container, slot)
	-- SuperWoW：带充能物品（法力/巫师之油等）count 返回负的剩余充能，归一为正（与 ItemCount.lua 同口径）
	if GameTooltip.itemCount and GameTooltip.itemCount < 0 and SetAutoloot then GameTooltip.itemCount = -GameTooltip.itemCount end
	return HookSetBagItem(self, container, slot)
end

local HookSetQuestLogItem = GameTooltip.SetQuestLogItem
function GameTooltip.SetQuestLogItem(self, itemType, index)
	GameTooltip.itemLink = GetQuestLogItemLink(itemType, index)
	if not GameTooltip.itemLink then return end
	return HookSetQuestLogItem(self, itemType, index)
end

local HookSetQuestItem = GameTooltip.SetQuestItem
function GameTooltip.SetQuestItem(self, itemType, index)
	GameTooltip.itemLink = GetQuestItemLink(itemType, index)
	return HookSetQuestItem(self, itemType, index)
end

local HookSetLootItem = GameTooltip.SetLootItem
function GameTooltip.SetLootItem(self, slot)
	GameTooltip.itemLink = GetLootSlotLink(slot)
	HookSetLootItem(self, slot)
end

local HookSetInboxItem = GameTooltip.SetInboxItem
function GameTooltip.SetInboxItem(self, mailID, attachmentIndex)
	local itemName, itemTexture, inboxItemCount, inboxItemQuality = GetInboxItem(mailID)
	GameTooltip.itemLink = ItemSocre:GetItemLinkByName(itemName)
	return HookSetInboxItem(self, mailID, attachmentIndex)
end

local HookSetInventoryItem = GameTooltip.SetInventoryItem
function GameTooltip.SetInventoryItem(self, unit, slot)
	GameTooltip.itemLink = GetInventoryItemLink(unit, slot)
	return HookSetInventoryItem(self, unit, slot)
end

local HookSetLootRollItem = GameTooltip.SetLootRollItem
function GameTooltip.SetLootRollItem(self, id)
	GameTooltip.itemLink = GetLootRollItemLink(id)
	return HookSetLootRollItem(self, id)
end

local HookSetMerchantItem = GameTooltip.SetMerchantItem
function GameTooltip.SetMerchantItem(self, merchantIndex)
	GameTooltip.itemLink = GetMerchantItemLink(merchantIndex)
	return HookSetMerchantItem(self, merchantIndex)
end

local HookSetCraftItem = GameTooltip.SetCraftItem
function GameTooltip.SetCraftItem(self, skill, slot)
	GameTooltip.itemLink = GetCraftReagentItemLink(skill, slot)
	return HookSetCraftItem(self, skill, slot)
end

local HookSetCraftSpell = GameTooltip.SetCraftSpell
function GameTooltip.SetCraftSpell(self, slot)
	GameTooltip.itemLink = GetCraftItemLink(slot)
	return HookSetCraftSpell(self, slot)
end

local HookSetTradeSkillItem = GameTooltip.SetTradeSkillItem
function GameTooltip.SetTradeSkillItem(self, skillIndex, reagentIndex)
	if reagentIndex then
		GameTooltip.itemLink = GetTradeSkillReagentItemLink(skillIndex, reagentIndex)
	else
		GameTooltip.itemLink = GetTradeSkillItemLink(skillIndex)
	end
	return HookSetTradeSkillItem(self, skillIndex, reagentIndex)
end

local HookSetAuctionItem = GameTooltip.SetAuctionItem
function GameTooltip.SetAuctionItem(self, atype, index)
  local itemName, _, itemCount = GetAuctionItemInfo(atype, index)
  if itemCount and itemCount < 0 and SetAutoloot then itemCount = -itemCount end -- SuperWoW 负充能修正
  GameTooltip.itemCount = itemCount
  GameTooltip.itemLink = ItemSocre:GetItemLinkByName(itemName)
  return HookSetAuctionItem(self, atype, index)
end

local HookSetAuctionSellItem = GameTooltip.SetAuctionSellItem
function GameTooltip.SetAuctionSellItem(self)
	local itemName, _, itemCount = GetAuctionSellItemInfo()
	if itemCount and itemCount < 0 and SetAutoloot then itemCount = -itemCount end -- SuperWoW 负充能修正
	GameTooltip.itemCount = itemCount
	GameTooltip.itemLink = ItemSocre:GetItemLinkByName(itemName)
	return HookSetAuctionSellItem(self)
end

local HookSetTradePlayerItem = GameTooltip.SetTradePlayerItem
function GameTooltip.SetTradePlayerItem(self, index)
	GameTooltip.itemLink = GetTradePlayerItemLink(index)
	return HookSetTradePlayerItem(self, index)
end

local HookSetTradeTargetItem = GameTooltip.SetTradeTargetItem
function GameTooltip.SetTradeTargetItem(self, index)
	GameTooltip.itemLink = GetTradeTargetItemLink(index)
	return HookSetTradeTargetItem(self, index)
end

if USE_PFUI_STYLE then -- ===== 新增：支持 PFUI 头像框架（钩住 GameTooltip.SetUnit 显示玩家装等） =====
	local HookSetUnit = GameTooltip.SetUnit
	function GameTooltip.SetUnit(self, unit)
		HookSetUnit(self, unit)
		if unit and UnitExists(unit) and UnitIsPlayer(unit) then
			local score = ItemSocre:ScanUnit(unit)
			if score and score > 0 then
				local found = false
				for i = 1, self:NumLines() do
					local text = _G[self:GetName() .. "TextLeft" .. i]
					if text and text:GetText() and string.find(text:GetText(), "装备等级") then
						found = true
						break
					end
				end
				if not found then
					self:AddLine("装备等级 " .. score, 1, 1, 0)
					self:Show()
				end
			end
		end
	end
end

