-- Independent WoW 1.12 backpack. No Bagshui hooks, data writes or dependencies.
QianKunBag = { version = "0.1.0", dirty = {}, slots = {}, sizes = {},
    metadata = {}, buttons = {}, groups = {}, stats = {}, pendingRetry = {},
    retryCount = 0, search = "", layoutNeeded = true }
local Q = QianKunBag
BINDING_HEADER_QIANKUNBAG = "乾坤背包（独立试用）"
BINDING_NAME_QIANKUNBAG_TOGGLE = "打开/关闭乾坤背包"

function Q:Count(key, amount)
    self.stats[key] = (self.stats[key] or 0) + (amount or 1)
end

function Q:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff88ccff乾坤背包|r " .. message)
end

function Q:Init()
    if self.ready then return end
    if type(QianKunBagDB) ~= "table" then QianKunBagDB = {} end
    self.db = QianKunBagDB
    if type(self.db.overrides) ~= "table" then self.db.overrides = {} end
    if type(self.db.groupOrder) ~= "table" then self.db.groupOrder = {} end
    self.db.columns = math.max(6, math.min(16, math.floor(tonumber(self.db.columns) or 12)))
    self:CompileCategories()
    self.ready = true
    self:MarkAll()
end

function Q:IsOpen()
    return self.window and self.window:IsShown()
end

function Q:MarkBag(bag)
    if type(bag) == "number" and bag >= 0 and bag <= 4 and bag == math.floor(bag) then
        self.dirty[bag] = true
        self.retryCount = 0
    end
    if self:IsOpen() then self:Wake() end
end

function Q:MarkAll()
    for bag = 0, 4 do self.dirty[bag] = true end
    self.retryCount = 0
    if self:IsOpen() then self:Wake() end
end

function Q:Busy()
    return CursorHasItem() or (StackSplitFrame and StackSplitFrame:IsShown())
end

function Q:Open()
    self:Init()
    self:CreateView()
    if self:IsOpen() then return end
    -- Opening validates live containers even if a client event was lost.
    self:MarkAll()
    self.retryCount = 0
    self:Refresh(true)
    self:RefreshCooldowns()
    self.window:Show()
    self:Wake()
end

function Q:Toggle()
    if self:IsOpen() then self.window:Hide() else self:Open() end
end

function Q:Wake()
    if self.running or not self:IsOpen() then return end
    self.running = true
    self.events:SetScript("OnUpdate", function() Q:Tick(arg1 or 0) end)
end

function Q:Sleep()
    self.running = nil
    self.events:SetScript("OnUpdate", nil)
end

function Q:WithButton(button, handler)
    local previous = this
    this = button
    local ok, problem = pcall(handler)
    this = previous
    if not ok then error(problem) end
end

function Q:Tick(elapsed)
    if not self:IsOpen() then self:Sleep(); return end
    if next(self.dirty) then self:Refresh(false) end
    if self.cooldownsDirty then
        self.cooldownsDirty = nil
        self:RefreshCooldowns()
    end
    if self.geometryPending and not self:Busy() then self:Layout(); self:UpdateStatus() end
    if self.retryAt and GetTime() >= self.retryAt then
        self.retryAt = nil
        for bag in pairs(self.pendingRetry) do self.dirty[bag] = true end
        self.retryCount = self.retryCount + 1
    end
    if self.hover then
        self.hoverElapsed = (self.hoverElapsed or 0) + elapsed
        local modifier = (IsShiftKeyDown() and "s" or "") .. (IsControlKeyDown() and "c" or "") .. (IsAltKeyDown() and "a" or "")
        if modifier ~= self.modifier or self.hoverElapsed >= 1 then
            self.modifier = modifier
            self.hoverElapsed = 0
            self:Tooltip(self.hover)
        end
        if CursorUpdate then self:WithButton(self.hover, CursorUpdate) end
    end
    if not next(self.dirty) and not self.cooldownsDirty and not self.retryAt and not self.hover and not self.geometryPending then self:Sleep() end
end

function Q:OnEvent(kind, value)
    if kind == "ADDON_LOADED" then
        if value == "QianKunBag" then self:Init() end
    elseif kind == "PLAYER_ENTERING_WORLD" then
        self:Init(); self:MarkAll(); self.retryCount = 0
    elseif kind == "BAG_UPDATE" then
        self:MarkBag(tonumber(value))
    elseif kind == "ITEM_LOCK_CHANGED" then
        -- This client may supply no bag/slot arguments for the lock event.
        self:MarkAll()
    elseif kind == "UNIT_INVENTORY_CHANGED" then
        if value == "player" then self:MarkAll() end
    elseif kind == "BAG_UPDATE_COOLDOWN" then
        self.cooldownsDirty = true
        if self:IsOpen() then self:Wake() end
    end
end

function Q:Command(message)
    local _, _, action, rest = string.find(message or "", "^%s*(%S*)%s*(.-)%s*$")
    action = string.lower(action or "")
    self:Init()
    if action == "" then self:Toggle()
    elseif action == "sort" then
        if self:Busy() then self:Print("先结束游标操作或拆分，再整理显示。"); return end
        if not self:IsOpen() then self:Open() else self.layoutNeeded = true; self:MarkAll(); self:Refresh(true) end
    elseif action == "stats" then
        local entries = 0
        for _ in pairs(self.metadata) do entries = entries + 1 end
        self:Print("v" .. self.version .. "；缓存 " .. entries .. "；控件 " .. (self.stats.created or 0)
            .. "；容器扫描 " .. (self.stats.bags or 0) .. "；变动槽 " .. (self.stats.changed or 0)
            .. "；分类 " .. (self.stats.classified or 0) .. "；布局 " .. (self.stats.layouts or 0)
            .. "；按钮更新 " .. (self.stats.painted or 0) .. "；上次刷新 " .. (self.lastMs or "不可计时") .. " ms")
    elseif action == "columns" then
        local columns = tonumber(rest)
        if not columns or columns ~= math.floor(columns) or columns < 6 or columns > 16 then self:Print("用法：/qkb columns 6到16"); return end
        if self:Busy() then self:Print("先结束游标操作或拆分。"); return end
        self.db.columns = columns; self.layoutNeeded = true
        if self:IsOpen() then self:Refresh(true) end
    elseif action == "assign" then
        local _, _, category, id = string.find(rest, "^(%S+)%s+(%d+)$")
        self:SetOverride(tonumber(id), category)
    elseif action == "auto" then
        self:SetOverride(tonumber(rest), nil)
    elseif action == "order" then
        if self:SetGroupOrder(rest) and self:IsOpen() then self:Refresh(false) end
    elseif action == "categories" then
        for _, category in ipairs(self.categoryOrder) do self:Print(category.id .. " = " .. category.name) end
    else
        self:Print("/qkb 开关；sort 显示整理；stats 计数；columns 6到16；categories 类别；assign 类别ID 物品ID；auto 物品ID；order 类别ID,类别ID...")
    end
end

Q.events = CreateFrame("Frame", "QianKunBagEvents")
Q.events:SetScript("OnEvent", function() Q:OnEvent(event, arg1) end)
for _, kind in ipairs({"ADDON_LOADED", "PLAYER_ENTERING_WORLD", "BAG_UPDATE", "ITEM_LOCK_CHANGED", "UNIT_INVENTORY_CHANGED", "BAG_UPDATE_COOLDOWN"}) do
    Q.events:RegisterEvent(kind)
end
SLASH_QIANKUNBAG1 = "/qkb"
SlashCmdList.QIANKUNBAG = function(message) Q:Command(message) end
