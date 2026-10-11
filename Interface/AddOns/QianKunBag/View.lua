local Q = QianKunBag
local backdrop = { bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16,
    insets={left=4, right=4, top=4, bottom=4} }

function Q:Font(parent, template)
    -- Valid built-in font object before ANY SetText, including empty/hidden labels.
    return parent:CreateFontString(nil, "OVERLAY", template or "GameFontNormal")
end

function Q:TextButton(parent, text, width, callback)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width); button:SetHeight(24)
    button:SetBackdrop(backdrop); button:SetBackdropColor(0.12, 0.15, 0.20, 1)
    button.label = self:Font(button)
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0); button.label:SetText(text)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button:SetScript("OnClick", callback)
    return button
end

function Q:CreateView()
    if self.window then return end
    local window = CreateFrame("Frame", "QianKunBagWindow", UIParent)
    self.window = window
    window:Hide()
    window:SetFrameStrata("DIALOG"); window:SetMovable(true); window:EnableMouse(true)
    window:SetClampedToScreen(true); window:RegisterForDrag("LeftButton")
    window:SetBackdrop(backdrop); window:SetBackdropColor(0.045, 0.055, 0.08, 0.97)
    local x, y = tonumber(self.db.x) or 0, tonumber(self.db.y) or 0
    if x ~= x or math.abs(x) > 10000 then x = 0 end
    if y ~= y or math.abs(y) > 10000 then y = 0 end
    window:SetPoint("CENTER", UIParent, "CENTER", x, y)
    window:SetScript("OnDragStart", function() this:StartMoving() end)
    window:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        local cx, cy = this:GetCenter(); local px, py = UIParent:GetCenter()
        if cx and cy and px and py then Q.db.x = cx-px; Q.db.y = cy-py end
    end)
    window:SetScript("OnHide", function()
        if Q.hover then Q:Leave(Q.hover) end
        if Q.popup then Q.popup:Hide() end
        for _, button in pairs(Q.buttons) do
            if button.hasStackSplit == 1 and StackSplitFrame then StackSplitFrame:Hide() end
        end
        Q:Sleep()
    end)
    table.insert(UISpecialFrames, "QianKunBagWindow")
    self.title = self:Font(window, "GameFontNormalLarge")
    self.title:SetPoint("TOPLEFT", window, "TOPLEFT", 15, -14)
    self.title:SetText("乾坤背包 · 独立试用")
    self.close = self:TextButton(window, "关闭", 45, function() Q.window:Hide() end)
    self.close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, -10)
    self.sort = self:TextButton(window, "整理显示", 80, function() Q:Command("sort") end)
    self.sort:SetPoint("TOPRIGHT", self.close, "TOPLEFT", -5, 0)
    self.searchBox = CreateFrame("EditBox", "QianKunBagSearch", window, "InputBoxTemplate")
    self.searchBox:SetFontObject(GameFontNormal)
    self.searchBox:SetWidth(180); self.searchBox:SetHeight(22); self.searchBox:SetAutoFocus(false)
    self.searchBox:SetPoint("TOPLEFT", window, "TOPLEFT", 20, -43)
    self.searchBox:SetText("")
    self.searchBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    self.searchBox:SetScript("OnEnterPressed", function() this:ClearFocus() end)
    self.searchBox:SetScript("OnTextChanged", function()
        Q.search = string.lower(this:GetText() or ""); Q:ApplySearch()
    end)
    self.searchHint = self:Font(window, "GameFontHighlightSmall")
    self.searchHint:SetPoint("LEFT", self.searchBox, "RIGHT", 8, 0)
    self.searchHint:SetText("搜索名称 / 类别 / ID")
    self.scroll = CreateFrame("ScrollFrame", "QianKunBagScroll", window, "UIPanelScrollFrameTemplate")
    self.scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -76)
    self.scroll:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -32, 42)
    self.content = CreateFrame("Frame", "QianKunBagContent", self.scroll)
    self.scroll:SetScrollChild(self.content)
    self.scroll:EnableMouseWheel(true)
    self.scroll:SetScript("OnMouseWheel", function()
        local value = this:GetVerticalScroll() - (arg1 or 0) * 38
        this:SetVerticalScroll(math.max(0, math.min(this:GetVerticalScrollRange(), value)))
    end)
    self.status = self:Font(window, "GameFontHighlightSmall")
    self.status:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 15, 24)
    self.status:SetText("")
    self.hint = self:Font(window, "GameFontHighlightSmall")
    self.hint:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 15, 10)
    self.hint:SetText("Alt+右键归类 · 整理不移动实物")
    self.parents = {}
    for bag = 0, 4 do
        local parent = CreateFrame("Frame", "QianKunBagContainer" .. bag, self.content)
        parent:SetID(bag); parent:SetAllPoints(self.content)
        self.parents[bag] = parent
    end
end

function Q:GetButton(record)
    local button = self.buttons[record.key]
    if button then return button end
    -- Each physical bag has its own permanent parent ID. No GetID monkey patch.
    local name = "QianKunBagItem" .. record.bag .. "_" .. record.slot
    button = CreateFrame("Button", name, self.parents[record.bag], "ContainerFrameItemButtonTemplate")
    button:Hide(); button:SetID(record.slot); button:SetWidth(34); button:SetHeight(34)
    button:SetFrameLevel(self.parents[record.bag]:GetFrameLevel() + 1)
    button:SetScript("OnUpdate", nil)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); button:RegisterForDrag("LeftButton")
    button:SetScript("OnClick", function()
        if arg1 == "RightButton" and IsAltKeyDown() and not CursorHasItem() then
            Q:OpenAssignment(this)
        else
            -- Native handler supplies use/equip, chat links, dress-up and splitting.
            ContainerFrameItemButton_OnClick(arg1)
            Q:MarkBag(this:GetParent():GetID())
        end
    end)
    button:SetScript("OnDragStart", function()
        PickupContainerItem(this:GetParent():GetID(), this:GetID())
        Q:MarkBag(this:GetParent():GetID())
    end)
    button:SetScript("OnReceiveDrag", function()
        if CursorHasItem() then
            PickupContainerItem(this:GetParent():GetID(), this:GetID())
            Q:MarkBag(this:GetParent():GetID())
        end
    end)
    button:SetScript("OnEnter", function()
        Q.hover = this; Q.hoverElapsed = 0; Q:Tooltip(this)
        if CursorUpdate then CursorUpdate() end
        Q:Wake()
    end)
    button:SetScript("OnLeave", function() Q:Leave(this) end)
    button:SetScript("OnHide", function()
        Q:Leave(this)
        if this.hasStackSplit == 1 and StackSplitFrame then StackSplitFrame:Hide() end
    end)
    button.qOverlay = CreateFrame("Frame", nil, button)
    button.qOverlay:SetAllPoints(button); button.qOverlay:SetFrameLevel(button:GetFrameLevel() + 2)
    button.qCount = self:Font(button.qOverlay)
    button.qCount:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 1); button.qCount:SetText("")
    button.qBorder = button.qOverlay:CreateTexture(nil, "OVERLAY")
    button.qBorder:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.qBorder:SetBlendMode("ADD"); button.qBorder:SetWidth(60); button.qBorder:SetHeight(60)
    button.qBorder:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.qCooldown = getglobal(name .. "Cooldown")
    if not button.qCooldown then button.qCooldown = CreateFrame("Model", name .. "Cooldown", button, "CooldownFrameTemplate") end
    button.qCooldown:SetAllPoints(button)
    button.qCooldown:SetFrameLevel(button:GetFrameLevel() + 1)
    self.buttons[record.key] = button; self:Count("created")
    return button
end

function Q:Paint(record)
    local button = self:GetButton(record)
    local old = button.qRecord
    local texture = record.texture or (record.meta and record.meta.texture)
    local textureChanged = not old or button.qTexture ~= texture
    if textureChanged then
        SetItemButtonTexture(button, texture or "Interface\\PaperDoll\\UI-Backpack-EmptySlot")
        button.qTexture = texture
    end
    if not old or old.count ~= record.count or old.charges ~= record.charges then
        SetItemButtonCount(button, 0)
        local count = record.charges > 0 and record.charges or record.count
        button.qCount:SetText(count > 1 and count or "")
    end
    if not old or old.locked ~= record.locked or textureChanged then
        SetItemButtonDesaturated(button, record.locked and 1 or nil, 0.5, 0.5, 0.5)
    end
    local quality = record.meta and record.meta.quality or -1
    if not old or button.qQuality ~= quality then
        button.qQuality = quality
        if quality > 1 and ITEM_QUALITY_COLORS[quality] then
            local color = ITEM_QUALITY_COLORS[quality]
            button.qBorder:SetVertexColor(color.r, color.g, color.b, 0.7); button.qBorder:Show()
        else button.qBorder:Hide() end
    end
    button.qRecord = record
    button.count = record.count; button.hasItem = record.occupied and 1 or nil; button.readable = record.readable
    if not old or old.link ~= record.link then self:Cooldown(button) end
    self:SearchButton(button)
    self:Count("painted")
    if self.hover == button then self:Tooltip(button) end
end

function Q:Cooldown(button)
    local record = button.qRecord
    local start, duration, enabled = 0, 0, 0
    if record and record.occupied then start, duration, enabled = GetContainerItemCooldown(record.bag, record.slot) end
    start, duration, enabled = start or 0, duration or 0, enabled or 0
    if button.qStart ~= start or button.qDuration ~= duration or button.qEnabled ~= enabled then
        CooldownFrame_SetTimer(button.qCooldown, start, duration, enabled)
        button.qStart, button.qDuration, button.qEnabled = start, duration, enabled
    end
end

function Q:RefreshCooldowns()
    for key, button in pairs(self.buttons) do if self.slots[key] then self:Cooldown(button) end end
end

function Q:Layout()
    local grouped = self:BuildGroups()
    local columns = self.db.columns
    local width, y = columns * 38, 4
    self.content:SetWidth(width); self.window:SetWidth(width + 52)
    self.title:SetWidth(width - 110); self.title:SetHeight(20)
    self.searchBox:SetWidth(math.max(90, width - 140))
    self.searchHint:SetWidth(120); self.searchHint:SetHeight(20)
    for _, category in ipairs(self.categoryOrder) do
        local list = grouped[category.id]
        local count = table.getn(list)
        local header = self.groups[category.id]
        if count > 0 then
            if not header then header = self:Font(self.content); self.groups[category.id] = header end
            header:ClearAllPoints(); header:SetPoint("TOPLEFT", self.content, "TOPLEFT", 2, -y)
            header:SetText(category.name .. " (" .. count .. ")"); header:Show(); y = y + 22
            for index, record in ipairs(list) do
                local button = self:GetButton(record)
                if button.qRecord ~= record then self:Paint(record) end
                button:ClearAllPoints()
                button:SetPoint("TOPLEFT", self.content, "TOPLEFT", math.mod(index-1, columns)*38, -y-math.floor((index-1)/columns)*38)
                button:Show()
            end
            y = y + math.ceil(count / columns)*38 + 8
        elseif header then header:Hide() end
    end
    self.content:SetHeight(math.max(1, y))
    local maxHeight = math.max(220, math.min(560, UIParent:GetHeight() - 80))
    self.window:SetHeight(math.max(220, math.min(maxHeight, y + 125)))
    self.scroll:SetVerticalScroll(0)
    self.layoutNeeded = nil; self.geometryPending = nil; self.hasLayout = true; self:Count("layouts")
end

function Q:SearchButton(button)
    local record = button.qRecord
    if not record then return end
    local category = self.categoryByID[record.category]
    local text = string.lower((record.meta and record.meta.name or "") .. " " .. (category and category.name or "") .. " " .. (record.id or ""))
    local match = self.search == "" or string.find(text, self.search, 1, true)
    local alpha = match and 1 or 0.22
    if button.qAlpha ~= alpha then button:SetAlpha(alpha); button.qAlpha = alpha end
end

function Q:ApplySearch()
    for _, button in pairs(self.buttons) do self:SearchButton(button) end
end

function Q:UpdateStatus()
    if not self.status then return end
    local text = (self.filled or 0) .. "/" .. (self.total or 0) .. " 格"
        .. ((self.pending or 0) > 0 and " · 信息待就绪 " .. self.pending or "")
        .. (self.layoutNeeded and " · 位置待整理" or "")
    if self.statusText ~= text then self.status:SetText(text); self.statusText = text end
end

function Q:Tooltip(button)
    local record = button.qRecord
    if not record or not button:IsVisible() then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if record.occupied then
        GameTooltip:SetBagItem(record.bag, record.slot)
        local category = self.categoryByID[record.category]
        GameTooltip:AddLine("乾坤背包：" .. (category and category.name or "其他") .. " · " .. record.reason, 0.55, 0.8, 1)
        GameTooltip:AddLine("Alt+右键：指定此物品的类别", 0.7, 0.7, 0.7)
    else
        GameTooltip:SetText("空格 · " .. (GetBagName(record.bag) or (record.bag == 0 and "背包" or "容器")))
        GameTooltip:AddLine("袋 " .. record.bag .. " / 槽 " .. record.slot .. "；遵循该容器物品限制。", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end

function Q:Leave(button)
    if self.hover == button then self.hover = nil end
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
    if ResetCursor then ResetCursor() end
end

function Q:OpenAssignment(button)
    local record = button.qRecord
    if not record or not record.id or self:Busy() then return end
    if GetContainerItemLink(record.bag, record.slot) ~= record.link then
        self:MarkBag(record.bag); self:Print("该槽位物品刚发生变化，请更新后再归类。"); return
    end
    if not self.popup then
        local popup = CreateFrame("Frame", "QianKunBagAssignment", self.window)
        self.popup = popup; popup:SetFrameStrata("FULLSCREEN_DIALOG")
        popup:EnableMouse(true)
        popup:SetWidth(190); popup:SetBackdrop(backdrop); popup:SetBackdropColor(0.06, 0.07, 0.10, 1)
        popup.title = self:Font(popup); popup.title:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -12)
        popup.rows = {}
        local row = 0
        for _, category in ipairs(self.categoryOrder) do
            if category.id ~= "empty" then
                local id = category.id
                local option = self:TextButton(popup, category.name, 166, function() Q:SetOverride(Q.popup.itemID, id); Q.popup:Hide() end)
                option:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -35-row*25)
                table.insert(popup.rows, option); row = row + 1
            end
        end
        local auto = self:TextButton(popup, "恢复自动分类", 166, function() Q:SetOverride(Q.popup.itemID, nil); Q.popup:Hide() end)
        auto:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -35-row*25); row = row + 1
        local close = self:TextButton(popup, "关闭", 166, function() Q.popup:Hide() end)
        close:SetPoint("TOPLEFT", popup, "TOPLEFT", 12, -35-row*25)
        popup:SetHeight(70+row*25)
        popup:SetClampedToScreen(true)
        table.insert(UISpecialFrames, "QianKunBagAssignment")
    end
    self.popup.itemID = record.id
    self.popup.title:SetText("物品 " .. record.id .. " 归类")
    self.popup:ClearAllPoints(); self.popup:SetPoint("CENTER", self.window, "CENTER", 0, 0)
    self.popup:Show()
end
