-- One entry on the bar; selecting a destination never uses the item.
local items = {
    { id = 6948, name = "炉石", icon = "hearth" },
    { id = 41915, name = "翠绿符文", icon = "verdant" },
    { id = 61000, name = "时光符文", icon = "time" },
    { id = 5976, name = "公会战袍", icon = "guild", equip = true }
}
local button = CreateFrame("Button", "diminfo_Teleport", UIParent)
button.IconPadding = 20
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
text:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE") -- Template remains valid if SetFont fails.
-- Use the same independent text anchor and outline-only style as the other modules.
text:SetShadowOffset(0, 0)
text:SetJustifyV("MIDDLE")
text:SetPoint("LEFT", diminfo_Gold, "RIGHT", 40, 0)
local icon = button:CreateTexture(nil, "ARTWORK")
-- The visible artwork is centered in every texture, including the hourglass.
local function UpdateLayout()
    local _, size = text:GetFont()
    size = size or 14
    local iconSize = size + 2
    button.IconPadding = iconSize + 4
    icon:SetWidth(iconSize)
    icon:SetHeight(iconSize)
    icon:ClearAllPoints()
    -- Scale the glyph/line-box correction with the actual font, including fallback.
    icon:SetPoint("RIGHT", text, "LEFT", -4, -size / 7)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", text, "TOPLEFT", -button.IconPadding, 0)
    button:SetPoint("BOTTOMRIGHT", text, "BOTTOMRIGHT", 0, 0)
end
button.UpdateLayout = UpdateLayout
UpdateLayout()
local menu = CreateFrame("Frame", "DimInfoTeleportMenu", UIParent, "UIDropDownMenuTemplate")
menu:Hide()
local hovering, elapsed = false, 0

local function Config()
    return diminfopanel.GetCharacterConfig()
end

local function Selected()
    local id = Config().TeleportItem or 6948
    for _, item in ipairs(items) do
        if item.id == id then return item end
    end
    return items[1]
end

local function ItemID(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return tonumber(id)
end

-- Resolve locations on demand: never use a stale bag slot after items move.
local function Locate(id)
    for slot = 1, 19 do
        if ItemID(GetInventoryItemLink("player", slot)) == id then
            return { inventory = slot }
        end
    end
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            if ItemID(GetContainerItemLink(bag, slot)) == id then
                local _, _, locked = GetContainerItemInfo(bag, slot)
                return { bag = bag, slot = slot, locked = locked }
            end
        end
    end
end

local function State(item, location)
    if not location then return "未携带", false end
    if location.locked then return "物品锁定", false end
    local start, duration, enabled
    if location.inventory then
        start, duration, enabled = GetInventoryItemCooldown("player", location.inventory)
    else
        start, duration, enabled = GetContainerItemCooldown(location.bag, location.slot)
    end
    local remaining = math.max(0, (start or 0) + (duration or 0) - GetTime())
    if remaining > 0 then
        local seconds = math.ceil(remaining)
        if seconds >= 60 then
            return string.format("%d分%02d秒", math.floor(seconds / 60), math.mod(seconds, 60)), false
        end
        return seconds .. "秒", false
    end
    if enabled == 0 then return "暂不可用", false end
    if item.equip and not location.inventory then return "需装备", true end
    return "就绪", true
end

local function Tooltip()
    local item = Selected()
    local location = Locate(item.id)
    GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:ClearLines()
    if location then
        if location.inventory then
            GameTooltip:SetInventoryItem("player", location.inventory)
        else
            GameTooltip:SetBagItem(location.bag, location.slot)
        end
    else
        GameTooltip:AddLine(item.name)
    end
    GameTooltip:AddLine("状态：" .. State(item, location), 1, .82, 0)
    if item.id == 6948 then
        GameTooltip:AddLine("炉石绑定：" .. (GetBindLocation() or "未知"), .7, .7, .7)
    end
    GameTooltip:AddLine("左键：使用当前物品；右键：选择传送物品", .3, 1, .6)
    if item.equip and location and not location.inventory then
        GameTooltip:AddLine("战袍在背包：首次点击装备，再次点击传送。", 1, .82, 0)
    end
    GameTooltip:Show()
end

local function Refresh()
    local item = Selected()
    local location = Locate(item.id)
    local state, ready = State(item, location)
    text:SetText(item.name .. " " .. state)
    local r, g, b = ready and .3 or .7, ready and 1 or .7, ready and .6 or .7
    text:SetTextColor(r, g, b)
    -- Transparent line art shares the label tint; item artwork never enters the bar.
    icon:SetTexture("Interface\\AddOns\\diminfo\\Media\\Teleport\\" .. item.icon)
    icon:SetVertexColor(r, g, b)
    UpdateLayout()
    if hovering then Tooltip() end
end

local function Choose(item)
    return function()
        Config().TeleportItem = item.id
        CloseDropDownMenus()
        Refresh()
        diminfopanel.ReanchorModules()
    end
end

UIDropDownMenu_Initialize(menu, function()
    if (UIDROPDOWNMENU_MENU_LEVEL or 1) ~= 1 then return end
    for _, item in ipairs(items) do
        local location = Locate(item.id)
        local info = {}
        info.text = item.name .. " — " .. State(item, location)
        info.checked = Selected().id == item.id
        info.disabled = not location and 1 or nil
        info.func = Choose(item)
        UIDropDownMenu_AddButton(info, 1)
    end
end, "MENU")

button:SetScript("OnClick", function()
    if arg1 == "RightButton" then
        hovering = false
        GameTooltip:Hide()
        ToggleDropDownMenu(1, nil, menu, button, 0, 0)
    elseif arg1 == "LeftButton" then
        CloseDropDownMenus()
        local item = Selected()
        local location = Locate(item.id)
        local state, ready = State(item, location)
        if not ready then
            UIErrorsFrame:AddMessage(item.name .. "：" .. state, 1, .3, .3)
        elseif location.inventory then
            UseInventoryItem(location.inventory)
        else
            UseContainerItem(location.bag, location.slot)
        end
        Refresh()
    end
end)
button:SetScript("OnEnter", function() hovering = true; Tooltip() end)
button:SetScript("OnLeave", function() hovering = false; GameTooltip:Hide() end)
button:SetScript("OnHide", function()
    hovering = false
    GameTooltip:Hide()
    if UIDROPDOWNMENU_OPEN_MENU == menu then CloseDropDownMenus() end
end)
button:SetScript("OnEvent", Refresh)
button:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < 1 then return end
    elapsed = 0
    Refresh()
end)
for _, eventName in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "BAG_UPDATE",
    "BAG_UPDATE_COOLDOWN", "UNIT_INVENTORY_CHANGED"}) do
    button:RegisterEvent(eventName)
end
-- Refresh only after SavedVariables load, including a settings reset.
button.Refresh = Refresh
