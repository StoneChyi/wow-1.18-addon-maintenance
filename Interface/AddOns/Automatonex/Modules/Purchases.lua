
assert(Automaton, "Automaton not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("Automaton_Purchases")

----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Purchases"] = "自动购买材料",
		["Purchases1"] = "自动购买材料1",
		["Purchases2"] = "自动购买材料2",
		["Automatically restock items"] = "与商人对话时，自动补充特定材料",
		["Reagent"] = "施法材料",
		["Set item to buy"] = "设置购买项目",
		["Quantity"] = "目标持有数量",
		["Set the number of purchased items"] = "背包中希望保持的件数；不足一份时按商人整份补足。重叠名单按最高目标，不相加。",
		["Bought "] = "买了 ",
		[" items."] = " 物品.",
		["Already have "] = "已有 ",
		["List"] = "打印全部列表",
		["Add Item"] = "添加物品ID：(回车确认，一次添加一个)",
		["Remove Item"] = "移除物品ID(按回车确认，一次添加一个)",
		["Purge"] = "清空列表",
		["Purged list for "] = "已清空列表：",

		["Invalid item ID"] = "无效的物品ID",
		["Item info not loaded, please try again later"] = "物品信息未加载，请稍后再试",
	} end)

L:RegisterTranslations("zhCN", function()
	return {
		["Purchases"] = "自动购买材料",
		["Purchases1"] = "自动购买材料1",
		["Purchases2"] = "自动购买材料2",
		["Automatically restock items"] = "与商人对话时，自动补充特定材料",
		["Reagent"] = "施法材料",
		["Set item to buy"] = "设置购买项目",
		["Quantity"] = "目标持有数量",
		["Set the number of purchased items"] = "背包中希望保持的件数；不足一份时按商人整份补足。重叠名单按最高目标，不相加。",
		["Bought "] = "买了 ",
		[" items."] = " 物品.",
		["Already have "] = "已有 ",
		["List"] = "打印全部列表",
		["Add Item"] = "添加物品ID：(回车确认，一次添加一个)",
		["Remove Item"] = "移除物品ID(按回车确认，一次添加一个)",
		["Purge"] = "清空列表",
		["Purged list for "] = "已清空列表：",

		["Invalid item ID"] = "无效的物品ID",
		["Item info not loaded, please try again later"] = "物品信息未加载，请稍后再试",
	} end)

----------------------------------
--      Module Declaration      --
----------------------------------
-- 使用角色名+服务器名作为唯一标识
local playerName = UnitName("player")
local realmName = GetRealmName()
local playerKey = playerName .. "-" .. realmName

local Automaton_Purchases = Automaton:NewModule("Purchases")
Automaton_Purchases.modulename = L["Purchases"]
Automaton_Purchases.moduledesc = L["Automatically restock items"]

-- 生成类别配置的工具函数
local function createCategoryOptions(category)
	return {
		list = {
			type = "execute",
			name = L["List"],
			desc = "打印"..L[category].."的自动购买列表",
			func = function() 
				local reagents = Automaton_Purchases.db.profile[category.."_reagents"][playerKey] or {}
				Automaton_Purchases:Print(L[category].." 自动购买列表:")
				if next(reagents) then
					for itemId, itemName in pairs(reagents) do
						Automaton_Purchases:Print(string.format("- %s (ID: %s)", itemName, itemId))
					end
				else
					Automaton_Purchases:Print("列表为空")
				end
			end
		},
		add = {
			type = "text",
			name = L["Add Item"],
			desc = "添加需要自动购买的物品ID(直接输入ID).|N一次只能添加一个物品",
			order = 1,
			usage = "物品ID",
			get = false,
			set = function(v) 
				if v and v ~= "" then
					local itemId = Automaton_Purchases:NormalizeItemID(v)
					local itemIdNum = tonumber(itemId)
					if not itemId then
						Automaton_Purchases:Print(L["Invalid item ID"])
						return
					end
					
					local itemName = Automaton_Purchases:ItemMetadata("item:" .. itemId .. ":0:0:0")
					if not itemName then
						Automaton_Purchases:Print(L["Item info not loaded, please try again later"])
						return
					end
					
					Automaton_Purchases:EnsurePlayerTables()
                    Automaton_Purchases.db.profile[category.."_reagents"][playerKey][itemId] = itemName
                    Automaton_Purchases:CancelRestock("settings")
					Automaton_Purchases:Print(string.format(L[category].." 已添加: %s (ID: %s)", itemName, itemId))
				end
			end,
		},
		remove = {
			type = "text",
			name = L["Remove Item"],
			desc = "输入物品ID移除自动购买物品",
			order = 2,
			usage = "物品ID",
			get = false,
			set = function(v) 
				if v and v ~= "" then
					local itemId = Automaton_Purchases:NormalizeItemID(v)
                    if not itemId then Automaton_Purchases:Print(L["Invalid item ID"]); return end
					local reagents = Automaton_Purchases.db.profile[category.."_reagents"][playerKey] or {}
					local itemName = reagents[itemId]
					if itemName then
						reagents[itemId] = nil
                        Automaton_Purchases:CancelRestock("settings")
						Automaton_Purchases:Print(string.format(L[category].." 已移除: %s (ID: %s)", itemName, itemId))
					else
						Automaton_Purchases:Print(L[category].." 未找到物品ID: " .. itemId)
					end
				end
			end,
		},
		purge = {
			type = "execute",
			name = L["Purge"],
			desc = "清空"..L[category].."的自动购买列表.",
			func = function() 
				Automaton_Purchases:EnsurePlayerTables()
                Automaton_Purchases.db.profile[category.."_reagents"][playerKey] = {};
                Automaton_Purchases:CancelRestock("settings")
				Automaton_Purchases:Print(L["Purged list for "] .. L[category])
			end
		},
		quantity = {
			type = "range",
			name = L["Quantity"],
			desc = L["Set the number of purchased items"],
			order = 3,
			get = function() 
				return Automaton_Purchases.db.profile[category.."_quantity"][playerKey] or
					Automaton_Purchases.db.profile[category.."_quantity"].default 
			end,
			set = function(v) 
				if type(v) ~= "number" or v ~= v or v < 0 or v > 300 or v ~= math.floor(v) then return end
                Automaton_Purchases:EnsurePlayerTables()
                Automaton_Purchases.db.profile[category.."_quantity"][playerKey] = v
                Automaton_Purchases:CancelRestock("settings")
				Automaton_Purchases:Print(string.format(L[category].." 购买数量已设置为: %d", v))
			end,
			min = 0,
			max = 300,
			step = 5,
			bigStep = 10,
		},
	}
end

-- 配置选项分组
Automaton_Purchases.options = {
	original = {
		type = "group",
		name = L["Purchases"],
		desc = L["Automatically restock items"],
		order = 1,
		args = createCategoryOptions("Purchases")
	},
	category1 = {
		type = "group",
		name = L["Purchases1"],
		desc = L["Automatically restock items"],
		order = 2,
		args = createCategoryOptions("Purchases1")
	},
	category2 = {
		type = "group",
		name = L["Purchases2"],
		desc = L["Automatically restock items"],
		order = 3,
		args = createCategoryOptions("Purchases2")
	}
}

------------------------------
--      Initialization      --
------------------------------

function Automaton_Purchases:OnInitialize()
	self.db = Automaton:AcquireDBNamespace("Purchases")

	-- 注册默认数据库（包含原始类别和两个新类别）
	Automaton:RegisterDefaults("Purchases", "profile", {
		disabled = true,
		-- 原始类别数据
		Purchases_quantity = {
			default = 0,
		},
		Purchases_reagents = {
			default = {},
		},
		-- 新类别1数据
		Purchases1_quantity = {
			default = 0,
		},
		Purchases1_reagents = {
			default = {},
		},
		-- 新类别2数据
		Purchases2_quantity = {
			default = 0,
		},
		Purchases2_reagents = {
			default = {},
		},
	})
	Automaton:SetDisabledAsDefault(self, "Purchases")

	self:EnsurePlayerTables()
	self:RegisterOptions(self.options)
end

local categories = { "Purchases", "Purchases1", "Purchases2" }
function Automaton_Purchases:NormalizeItemID(value)
    local id = tonumber(value)
    if not id or id ~= id or id < 1 or id > 2147483647 or id ~= math.floor(id) then return nil end
    return tostring(id)
end
local function LinkID(link)
    if type(link) ~= "string" then return nil end
    local _, _, id = string.find(link, "item:(%d+):")
    return Automaton_Purchases:NormalizeItemID(id)
end
function Automaton_Purchases:EnsurePlayerTables()
    for _, category in ipairs(categories) do
        for _, suffix in ipairs({ "_reagents", "_quantity" }) do
            local key = category .. suffix
            if type(self.db.profile[key]) ~= "table" then self.db.profile[key] = {} end
        end
        local lists = self.db.profile[category .. "_reagents"]
        if type(lists[playerKey]) ~= "table" then lists[playerKey] = {} end
    end
end
function Automaton_Purchases:ItemMetadata(link)
    local ok, name, _, _, _, _, v6, v7, v8 = pcall(_G.GetItemInfo, link)
    if not ok or not name then return nil end
    if type(v7) == "number" and v7 > 0 then return name, v6, v7 end
    if type(v8) == "number" and v8 > 0 then return name, v7, v8 end
end
function Automaton_Purchases:GetRestockTargets()
    local targets = {}
    for _, category in ipairs(categories) do
        local amounts = self.db.profile[category .. "_quantity"] or {}
        local target = tonumber(amounts[playerKey] or amounts.default)
        local lists = self.db.profile[category .. "_reagents"] or {}
        if target and target == target and target > 0 and target <= 300 and target == math.floor(target) then
            for raw in pairs(lists[playerKey] or {}) do
                local id = self:NormalizeItemID(raw)
                if id then targets[id] = math.max(targets[id] or 0, target) end
            end
        end
    end
    return targets
end
function Automaton_Purchases:SearchItem(itemId)
    itemId = self:NormalizeItemID(itemId)
    local count = 0
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if itemId and LinkID(GetContainerItemLink(bag, slot)) == itemId then
                local _, amount = GetContainerItemInfo(bag, slot)
                count = count + (tonumber(amount) or 0)
            end
        end
    end
    return count
end
function Automaton_Purchases:GetRestockCapacity(link)
    local bulk = pfUI and pfUI.buyemall
    if bulk and bulk.GetCapacity then return bulk:GetCapacity(link) end
    local id = LinkID(link)
    local name, _, stack = self:ItemMetadata(link)
    if not id or not name or not stack then return 0 end
    local capacity = 0
    for bag = 0, 4 do
        local normal = bag == 0
        if bag > 0 then
            local _, subtype = self:ItemMetadata(GetInventoryItemLink("player", bag + 19))
            normal = subtype == "Bag" or subtype == "背包" or subtype == "容器" or subtype == "Container"
        end
        for slot = 1, GetContainerNumSlots(bag) do
            local current = GetContainerItemLink(bag, slot)
            local texture, count, locked = GetContainerItemInfo(bag, slot)
            if not locked then
                if not current and not texture and normal then capacity = capacity + stack
                elseif LinkID(current) == id and count and count > 0 then capacity = capacity + math.max(0, stack - count) end
            end
        end
    end
    return capacity
end
function Automaton_Purchases:IsRestockProtected(id)
    return self.restockSession and self.restockSession.targets[self:NormalizeItemID(id)] ~= nil
end
function Automaton_Purchases:IsPurchasePending() return self.pendingPurchase ~= nil end
function Automaton_Purchases:CanStartManualPurchase()
    if self.purchaseUncertain then return false, "uncertain" end
    if self.pendingPurchase then return false, "pending" end
    return true
end
function Automaton_Purchases:ReportRestock(session)
    if not session then return end
    session.reported = session.reported or {}
    for id, count in pairs(session.bought or {}) do
        local delta = count - (session.reported[id] or 0)
        if delta > 0 then
            self:Print("补货已收到 " .. delta .. " 件：" .. ((session.names or {})[id] or ("ID " .. id)))
            session.reported[id] = count
        end
    end
end
function Automaton_Purchases:CancelRestock(reason)
    if self.restockSession then
        self.restockSession.cancelled = reason or true
        self:ReportRestock(self.restockSession)
    end
    if not self.pendingPurchase then
        self.restockTicket = nil
        self:CancelScheduledEvent("Automaton_Restock")
    end
end
function Automaton_Purchases:ScheduleRestock()
    local ticket = {}
    self.restockTicket = ticket
    self:ScheduleEvent("Automaton_Restock", function()
        if self.restockTicket ~= ticket then return end
        self:RestockTick()
        if self.restockTicket == ticket and (self.pendingPurchase or (self.restockSession and not self.restockSession.cancelled)) then self:ScheduleRestock() end
    end, .15)
end
function Automaton_Purchases:SetMerchantOwner(owner)
    if self.merchantOwner == owner then return end
    self:CancelRestock("handoff")
    self.merchantOwner = owner
    self:UpdateRestockEvents()
end
function Automaton_Purchases:UpdateRestockEvents()
    self:UnregisterAllEvents()
    if self.restockActive and not self.merchantOwner then
        self:RegisterEvent("MERCHANT_SHOW")
        self:RegisterEvent("MERCHANT_CLOSED")
    end
    -- Close/leave must also retire a previously sent request after disabling.
    self:RegisterEvent("PLAYER_LEAVING_WORLD", "MERCHANT_CLOSED")
end
function Automaton_Purchases:OnEnable()
    self:EnsurePlayerTables()
    self.restockActive = true
    if pfUI and pfUI.autovendor and pfUI.autovendor.SyncRestockOwnership then pfUI.autovendor:SyncRestockOwnership() end
    self:UpdateRestockEvents()
end
function Automaton_Purchases:OnDisable()
    self.restockActive = nil
    self:CancelRestock("disabled")
    self.restockSession = nil
    self:UpdateRestockEvents()
end
function Automaton_Purchases:MERCHANT_CLOSED()
    self:CancelRestock("closed")
    self.restockSession = nil
    if not self.pendingPurchase then self.purchaseUncertain = nil end
end
function Automaton_Purchases:MERCHANT_SHOW()
    if self.restockSession or not self.restockActive then return end
    self.restockSession = { targets = self:GetRestockTargets(), started = GetTime(), offers = nil }
    self:ScheduleRestock()
end
function Automaton_Purchases:RestockTick()
    local pending = self.pendingPurchase
    if pending then
        local received = self:SearchItem(pending.id) >= pending.count + pending.pack
        local paid = pending.price == 0 or GetMoney() <= pending.money - pending.price
        if received and paid then
            self.pendingPurchase = nil
            local vendor = pfUI and pfUI.autovendor
            if vendor and vendor.ProtectPurchase then vendor:ProtectPurchase(pending.link) end
            local original = pending.session
            original.bought = original.bought or {}
            original.bought[pending.id] = (original.bought[pending.id] or 0) + pending.pack
            if original.cancelled then self:ReportRestock(original) end
        elseif GetTime() - pending.sent >= 5 then
            self.pendingPurchase = nil
            self.purchaseUncertain = true
            self:CancelRestock("timeout")
            self:Print("补货未收到完整购买反馈，已停止；请核对背包后关闭并重新打开商人。")
        end
        return
    end
    local session = self.restockSession
    if not session or session.cancelled then return end
    if not self.restockActive or self.purchaseUncertain or not MerchantFrame or not MerchantFrame:IsShown()
        or MerchantFrame.selectedTab ~= 1 then self:CancelRestock("inactive"); return end
    local bulk = pfUI and pfUI.buyemall
    if bulk and bulk.CanStartRestock then
        local ready, why = bulk:CanStartRestock()
        if not ready then
            if why == "uncertain" then self:CancelRestock("manual-uncertain") end
            return
        end
    end
    if bulk and bulk.IsBusy and bulk:IsBusy() then self:CancelRestock("manual"); return end
    local vendor = pfUI and pfUI.autovendor
    local seller = Automaton.modules and Automaton.modules.Sell
    if (vendor and vendor.IsSelling and vendor:IsSelling()) or (seller and seller.IsSelling and seller:IsSelling()) or CursorHasItem() then
        if session.busyMoney ~= GetMoney() then
            session.busyMoney, session.busySince = GetMoney(), GetTime()
        end
        if GetTime() - (session.busySince or session.started) >= 10 then
            self:CancelRestock("busy")
            self:Print("商人操作长时间未完成，本次补货已停止；请处理后重新打开商人。")
        end
        return
    end
    session.busyMoney, session.busySince = nil, nil
    local targets = self:GetRestockTargets()
    for id, target in pairs(session.targets) do if targets[id] ~= target then self:CancelRestock("settings"); return end end
    for id, target in pairs(targets) do if session.targets[id] ~= target then self:CancelRestock("settings"); return end end
    if not session.offers then
        session.offers = {}
        session.names = {}
        local seen = {}
        for i = 1, GetMerchantNumItems() do
            local link = GetMerchantItemLink(i)
            local id = LinkID(link)
            local name, _, price, pack, stock, _, extended = GetMerchantItemInfo(i)
            if id and targets[id] and not seen[id] and name and extended ~= true and extended ~= 1 and type(price) == "number" and price >= 0
                and type(pack) == "number" and pack > 0 and pack == math.floor(pack) then
                table.insert(session.offers, { index=i, link=link, id=id, price=price, pack=pack })
                seen[id] = true
                session.names[id] = name
            end
        end
        session.position = 1
    end
    local offer = session.offers[session.position]
    if not offer then self:CancelRestock("done"); return end
    local count = self:SearchItem(offer.id)
    if count >= targets[offer.id] then session.position = session.position + 1; return end
    local name, _, price, pack, stock, _, extended = GetMerchantItemInfo(offer.index)
    if GetMerchantItemLink(offer.index) ~= offer.link or not name or price ~= offer.price or pack ~= offer.pack or extended == true or extended == 1 then
        self:CancelRestock("changed"); return
    end
    if type(GetMerchantItemCostInfo) == "function" then
        local ok, costs = pcall(GetMerchantItemCostInfo, offer.index)
        if not ok or (costs and costs > 0) then session.position = session.position + 1; return end
    end
    if type(stock) ~= "number" or stock == 0 or stock < -1 or GetMoney() < price
        or self:GetRestockCapacity(offer.link) < pack then session.position = session.position + 1; return end
    if vendor and vendor.ProtectPurchase then vendor:ProtectPurchase(offer.link) end
    self.pendingPurchase = { id=offer.id, link=offer.link, count=count, pack=pack, price=price, money=GetMoney(), sent=GetTime(), session=session }
    -- The 1.12 API takes merchant packs. Keep native single-pack handling
    -- instead of caller-chosen bulk quantities; wait for both acknowledgments.
    local ok, err = pcall(BuyMerchantItem, offer.index, 1)
    if not ok then
        self.purchaseUncertain = true
        self:CancelRestock("error")
        self:Print("补货请求失败，已停止：" .. tostring(err))
    end
end
