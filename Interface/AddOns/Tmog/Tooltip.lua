local NORMAL = NORMAL_FONT_COLOR_CODE
local WHITE = HIGHLIGHT_FONT_COLOR_CODE
local GREY = GRAY_FONT_COLOR_CODE
local YELLOW = "|cffFFFF00"
local GREEN = "|cff00A000"
local BLUE = "|cff0070de"
local PINK = "|cffff80ff"
local L = Tmog.L

local TmogTooltip = CreateFrame("GameTooltip", "TmogTooltip", UIParent, "GameTooltipTemplate")
TmogTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local TmogScanTooltip = CreateFrame("GameTooltip", "TmogScanTooltip", nil, "GameTooltipTemplate")
TmogScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

local original_SetTooltipMoney = SetTooltipMoney
function SetTooltipMoney(frame, money)
	if frame.insideHook then
		frame.tooltipMoney = money or 0
	else
		original_SetTooltipMoney(frame, money)
	end
end

function Tmog.HookTooltip(frame)
	-- 1.12 上 GetFrameType() 对 GameTooltip 的返回值不可靠（4.7 直接盲钩也能跑），
	-- 改为按方法探测，避免守卫误判导致钩子被静默跳过。
	if not (frame and type(frame.SetHyperlink) == "function" and type(frame.SetBagItem) == "function") then
		return
	end

	-- ⛔ 1.12 的 GameTooltip 没有 OnTooltipSetItem / OnTooltipCleared 脚本槽（2.0+ 才有），
	--    且 1.12 找不到自身方法时会回退到全局表 —— 别的插件（pfUI）注册的全局
	--    HookScript(f, script, func) 会被这行当成方法调用，回调拿到的 self 是 nil，
	--    直接报 "attempt to index local `self'"；同时下面 16 个 Set*Item 包装全部装不上，
	--    幻化提示整块失效。故只走 4.7 验证过的手动包装路径，不碰 HookScript / hooksecurefunc。

	local original_SetBagItem = frame.SetBagItem
	function frame.SetBagItem(self, container, slot)
		self.insideHook = true
		local hasCooldown, repairCost = original_SetBagItem(self, container, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetContainerItemLink(container, slot))
		Tmog.ExtendTooltip(self)
		return hasCooldown, repairCost
	end

	local original_SetInventoryItem = frame.SetInventoryItem
	function frame.SetInventoryItem(self, unit, slot, nameOnly)
		self.insideHook = true
		local hasItem, hasCooldown, repairCost = original_SetInventoryItem(self, unit, slot, nameOnly)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetInventoryItemLink(unit, slot))
		Tmog.ExtendTooltip(self)
		return hasItem, hasCooldown, repairCost
	end

	local original_SetLootRollItem = frame.SetLootRollItem
	function frame.SetLootRollItem(self, id)
		self.insideHook = true
		original_SetLootRollItem(self, id)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetLootRollItemLink(id))
		Tmog.ExtendTooltip(self)
	end

	local original_SetLootItem = frame.SetLootItem
	function frame.SetLootItem(self, slot)
		self.insideHook = true
		original_SetLootItem(self, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetLootSlotLink(slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetMerchantItem = frame.SetMerchantItem
	function frame.SetMerchantItem(self, merchantIndex)
		self.insideHook = true
		original_SetMerchantItem(self, merchantIndex)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetMerchantItemLink(merchantIndex))
		Tmog.ExtendTooltip(self)
	end

	local original_SetQuestLogItem = frame.SetQuestLogItem
	function frame.SetQuestLogItem(self, itemType, index)
		self.insideHook = true
		original_SetQuestLogItem(self, itemType, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetQuestLogItemLink(itemType, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetQuestItem = frame.SetQuestItem
	function frame.SetQuestItem(self, itemType, index)
		self.insideHook = true
		original_SetQuestItem(self, itemType, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetQuestItemLink(itemType, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetHyperlink = frame.SetHyperlink
	function frame.SetHyperlink(self, arg1)
		self.insideHook = true
		original_SetHyperlink(self, arg1)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(arg1)
		Tmog.ExtendTooltip(self)
	end

	local original_SetInboxItem = frame.SetInboxItem
	function frame.SetInboxItem(self, mailID, attachmentIndex)
		self.insideHook = true
		original_SetInboxItem(self, mailID, attachmentIndex)
		self.insideHook = nil
		if GetInboxItemLink then
			self.itemID = Tmog.IDFromLink(GetInboxItemLink(mailID, attachmentIndex))
		else
			self.itemID = Tmog.GetItemIDByName(GetInboxItem(mailID, attachmentIndex))
		end
		Tmog.ExtendTooltip(self)
	end

	local original_SetCraftItem = frame.SetCraftItem
	function frame.SetCraftItem(self, skill, slot)
		self.insideHook = true
		original_SetCraftItem(self, skill, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetCraftReagentItemLink(skill, slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetCraftSpell = frame.SetCraftSpell
	function frame.SetCraftSpell(self, slot)
		self.insideHook = true
		original_SetCraftSpell(self, slot)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetCraftItemLink(slot))
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradeSkillItem = frame.SetTradeSkillItem
	function frame.SetTradeSkillItem(self, skillIndex, reagentIndex)
		self.insideHook = true
		original_SetTradeSkillItem(self, skillIndex, reagentIndex)
		self.insideHook = nil
		if reagentIndex then
			self.itemID = Tmog.IDFromLink(GetTradeSkillReagentItemLink(skillIndex, reagentIndex))
		else
			self.itemID = Tmog.IDFromLink(GetTradeSkillItemLink(skillIndex))
		end
		Tmog.ExtendTooltip(self)
	end

	local original_SetAuctionItem = frame.SetAuctionItem
	function frame.SetAuctionItem(self, atype, index)
		self.insideHook = true
		original_SetAuctionItem(self, atype, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetAuctionItemLink(atype, index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetAuctionSellItem = frame.SetAuctionSellItem
	function frame.SetAuctionSellItem(self)
		self.insideHook = true
		original_SetAuctionSellItem(self)
		self.insideHook = nil
		local name, texture, stackSize, quality, canUse, price, maxStack, link = GetAuctionSellItemInfo()
		if link then
			self.itemID = Tmog.IDFromLink(link)
		else
			self.itemID = Tmog.GetItemIDByName(name)
		end
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradePlayerItem = frame.SetTradePlayerItem
	function frame.SetTradePlayerItem(self, index)
		self.insideHook = true
		original_SetTradePlayerItem(self, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetTradePlayerItemLink(index))
		Tmog.ExtendTooltip(self)
	end

	local original_SetTradeTargetItem = frame.SetTradeTargetItem
	function frame.SetTradeTargetItem(self, index)
		self.insideHook = true
		original_SetTradeTargetItem(self, index)
		self.insideHook = nil
		self.itemID = Tmog.IDFromLink(GetTradeTargetItemLink(index))
		Tmog.ExtendTooltip(self)
	end

	local original_OnHide = frame:GetScript("OnHide")
	frame:SetScript("OnHide", function()
		if original_OnHide then original_OnHide(frame) end
		frame.itemID = nil
		frame.tmogLine = nil
		frame.tooltipMoney = 0
	end)
end

-- 4.7 原版逻辑：把「已收集 / 未收集」插到物品名下方的第 2 行，
-- 外观信息（独特 / 非独特外观 + 所在配装）追加到底部。
local WrappingLines = {
	["^Set:"] = string.gsub("^"..ITEM_SET_BONUS, "%%s", ""),
	["^%(%d%) Set:"] = string.gsub(string.gsub(ITEM_SET_BONUS_GRAY, "%(%%d%)", "^%%(%%d%%)"), "%%s", ""),
	["^Effect:"] = string.gsub("^"..ITEM_SPELL_EFFECT, "%%s", ""),
	["^Equip:"] = "^"..ITEM_SPELL_TRIGGER_ONEQUIP,
	["^Chance on hit:"] = "^"..ITEM_SPELL_TRIGGER_ONPROC,
	["^Use:"] = "^"..ITEM_SPELL_TRIGGER_ONUSE,
	["^\nRequires"] = "^\n"..string.gsub(ITEM_REQ_SKILL, "%%s", "")
}

local lines = {}
for i = 1, 30 do lines[i] = {} end

local function AddCollectionStatus(slot, itemID, tooltip)
	local name = tooltip:GetName()
	local numLines = tooltip:NumLines()
	local left, right
	local leftText, rightText
	local rL, gL, bL
	local rR, gR, bR
	local status, wrap

	for i in pairs(lines) do
		for j in pairs(lines[i]) do
			lines[i][j] = nil
		end
	end

	for i = 1, numLines do
		left = _G[name .. "TextLeft" .. i]
		right = _G[name .. "TextRight" .. i]
		if left and left:GetText() then
			leftText = left:GetText()
			rightText = (right and right:IsShown()) and right:GetText() or nil
			rL, gL, bL = left:GetTextColor()
			if right then rR, gR, bR = right:GetTextColor() end
			if not lines[i] then lines[i] = {} end
			lines[i][1] = leftText
			lines[i][2] = rightText
			lines[i][3] = rL
			lines[i][4] = gL
			lines[i][5] = bL
			lines[i][6] = rR
			lines[i][7] = gR
			lines[i][8] = bR
		end
	end

	if not lines[1][1] then
		return
	end

	if TMOG_CACHE[slot][itemID] then
		status = GREEN..L["Collected"].."|r"
	else
		status = YELLOW..L["Not collected"].."|r"
	end

	tooltip:SetText(lines[1][1], lines[1][3], lines[1][4], lines[1][5], 1, false)

	if numLines < 28 then
		tooltip:AddLine(status)
	elseif lines[2][1] then
		lines[2][1] = status.."\n"..lines[2][1]
	end

	for i = 2, table.getn(lines) do
		if lines[i][1] then
			if lines[i][2] then
				tooltip:AddDoubleLine(lines[i][1], lines[i][2], lines[i][3], lines[i][4], lines[i][5], lines[i][6], lines[i][7], lines[i][8])
			else
				wrap = false
				if string.sub(lines[i][1], 1, 1) == "\"" then
					wrap = true
				else
					for _, pattern in pairs(WrappingLines) do
						if string.find(lines[i][1], pattern) then
							wrap = true
							break
						end
					end
				end
				tooltip:AddLine(lines[i][1], lines[i][3], lines[i][4], lines[i][5], wrap)
			end
		end
	end
end

local lastItemName = nil
local lastSlot = nil

function Tmog.ExtendTooltip(self)
	self = self or this
	local itemID = tonumber(self.itemID)
	if itemID and self ~= TmogTooltip and not GetItemInfo(itemID) then
		Tmog.CacheItem(itemID)
	end
	if itemID then
		local itemName = GetItemInfo(itemID)
		if itemName ~= lastItemName then
			local slot = Tmog.GetTransmogSlot(itemID, "player", self)
			lastItemName = itemName
			lastSlot = slot
		end
		if lastSlot then
			AddCollectionStatus(lastSlot, itemID, self)
		end
		if self ~= TmogTooltip and Tmog.Transmogable(itemID) then
			local str
			if not Tmog.ItemDisplayGroup[itemID] then
				if not Tmog.IsKnownAppearance(itemID) then
					str = NORMAL..L["Unknown appearance"]
				else
					str = NORMAL..L["Unique appearance"]
				end
			else
				str = NORMAL..L["Non-unique appearance"]
			end
			local outfits = Tmog.GetOutfitsWithItem(itemID)
			local numTotal = table.getn(outfits)
			if numTotal > 0 then
				str = str..GRAY_FONT_COLOR_CODE.." ("..string.format(L["Outfits: %s"], table.concat(outfits, ", "))..")"..FONT_COLOR_CODE_CLOSE
			end
			local numLines = self:NumLines()
			if numLines < 30 then
				self:AddLine(str, 1, 0.82, 0, numTotal > 3)
			else
				-- 满 30 行只能并进已有行。末行不一定是文字：别的插件可能在那里留了一行
				-- 空白占位（例如 S_ItemTip 给金币框留的空行），往它后面接 "\n" 就会
				-- 凭空多出一排空白。所以往上找第一个真正有文字的行。
				local target
				for i = numLines, 1, -1 do
					local l = _G[self:GetName().."TextLeft"..i]
					local t = l and l:GetText()
					if t and not string.find(t, "^%s*$") then
						target = l
						break
					end
				end
				if target then
					target:SetText(target:GetText().."\n"..str)
				end
			end
			self.tmogLine = str
		end
		self:Show()
	end
	local money = self.tooltipMoney or 0
	if money > 0 then
		original_SetTooltipMoney(self, money)
		self:Show()
	end
end

local original_OnShow = GameTooltip:GetScript("OnShow")
GameTooltip:SetScript("OnShow", function()
	if original_OnShow then original_OnShow(GameTooltip) end

	if aux_frame and aux_frame:IsShown() then
		local frame = GetMouseFocus()
		if not frame then return end
		local parent = frame:GetParent()
		if not (parent and parent.row and parent.row.record) then return end

		GameTooltip.itemID = tonumber(parent.row.record.item_id)
		Tmog.ExtendTooltip(GameTooltip)
	end
end)
