assert(Automaton, "Automaton not found!")

----------------------------------
--      Module Declaration      --
----------------------------------

local Automaton_ItemLinkEnUS = Automaton:NewModule("ItemLinkEnUS")
local self = Automaton_ItemLinkEnUS

-- 本地化配置
local L = AceLibrary("AceLocale-2.2"):new("Automaton_ItemLinkEnUS")
L:RegisterTranslations("zhCN", function() return {
    ["ItemLinkEnUS"] = "物品链接英文转换",
    ["Convert item links to English when using Alt+Click"] = "Alt+点击时将物品链接转换为英文名称",
} end)

-- 模块基本信息
Automaton_ItemLinkEnUS.modulename = L["ItemLinkEnUS"]
Automaton_ItemLinkEnUS.moduledesc = L["Convert item links to English when using Alt+Click"]
Automaton_ItemLinkEnUS.options = {} -- 该模块无额外配置项

----------------------------------
--      Local Functions        --
----------------------------------

-- Resolve the optional database lazily: its absence must not break startup or
-- ordinary clicks, and loading it later should not require another hook layer.
local function EnglishName(id)
    if not LibStub then return end
    local ok, library = pcall(function() return LibStub("LibItem-enUS-1.0", true) end)
    local names = ok and type(library) == "table" and library.Item_enUS
    local name = type(names) == "table" and (names[id] or names[tostring(id)])
    if type(name) == "string" and name ~= "" then return name end
end
local function LinkParts(value)
    if type(value) ~= "string" then return end
    local _, _, payload = string.find(value, "|H(item:[^|]+)|h")
    if not payload then local _, _, raw = string.find(value, "^(item:[^|]+)$"); payload = raw end
    local _, _, id = string.find(payload or "", "^item:(%d+)")
    return payload, tonumber(id)
end
function Automaton_ItemLinkEnUS:WantsLink(button, ignoreModifiers)
    return self.runtimeActive and not ignoreModifiers and button == "LeftButton"
        and ChatFrameEditBox and ChatFrameEditBox:IsVisible() and IsAltKeyDown()
        and not IsControlKeyDown() and not IsShiftKeyDown()
end
function Automaton_ItemLinkEnUS:InsertEnglish(value, display)
    local payload, id = LinkParts(value)
    local name = id and EnglishName(id)
    if not payload or not name then return false end
    local _, _, color = string.find(display or value, "|c(%x%x%x%x%x%x%x%x)")
    if not color and type(GetItemInfo) == "function" then
        local ok, _, _, quality = pcall(GetItemInfo, value)
        local qualityColor = ok and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
        local _, _, hex = string.find(qualityColor and qualityColor.hex or "", "|c(%x%x%x%x%x%x%x%x)")
        color = hex
    end
    -- Keep enchantment/random suffix fields from the clicked link, not a cached
    -- base item. Inserting text never changes the player's cursor item.
    ChatFrameEditBox:Insert("|c" .. (color or "ffffffff") .. "|H" .. payload .. "|h[" .. name .. "]|h|r")
    return true
end
function Automaton_ItemLinkEnUS:PaperDollItemSlotButton_OnClick(button, ignoreShift)
    if self:WantsLink(button, ignoreShift) and this and this.GetID
        and self:InsertEnglish(GetInventoryItemLink("player", this:GetID())) then return end
    return self.hooks.PaperDollItemSlotButton_OnClick(button, ignoreShift)
end
function Automaton_ItemLinkEnUS:ContainerFrameItemButton_OnClick(button, ignoreShift)
    if self:WantsLink(button, ignoreShift) and this and this.GetID and this.GetParent then
        local parent = this:GetParent()
        if parent and parent.GetID and self:InsertEnglish(GetContainerItemLink(parent:GetID(), this:GetID())) then return end
    end
    return self.hooks.ContainerFrameItemButton_OnClick(button, ignoreShift)
end
function Automaton_ItemLinkEnUS:MerchantItemButton_OnClick(button, ignoreModifiers)
    if self:WantsLink(button, ignoreModifiers) and MerchantFrame and MerchantFrame.selectedTab == 1
        and this and this.GetID and self:InsertEnglish(GetMerchantItemLink(this:GetID())) then return end
    return self.hooks.MerchantItemButton_OnClick(button, ignoreModifiers)
end
function Automaton_ItemLinkEnUS:LootFrameItem_OnClick(button)
    if self:WantsLink(button) and this and this.slot and self:InsertEnglish(GetLootSlotLink(this.slot)) then return end
    return self.hooks.LootFrameItem_OnClick(button)
end
function Automaton_ItemLinkEnUS:SetItemRef(link, text, button)
    if self:WantsLink(button) and self:InsertEnglish(link, text) then return end
    return self.hooks.SetItemRef(link, text, button)
end
function Automaton_ItemLinkEnUS:InstallHooks()
    if not self.runtimeActive then return end
    for _, name in ipairs({ "PaperDollItemSlotButton_OnClick", "ContainerFrameItemButton_OnClick",
        "MerchantItemButton_OnClick", "LootFrameItem_OnClick", "SetItemRef" }) do
        if type(_G[name]) == "function" and not self:IsHooked(name) then self:Hook(name) end
    end
end
function Automaton_ItemLinkEnUS:OnInitialize()
    self.db = Automaton:AcquireDBNamespace("ItemLinkEnUS")
    Automaton:RegisterDefaults("ItemLinkEnUS", "profile", { disabled = true })
    Automaton:SetDisabledAsDefault(self, "ItemLinkEnUS")
    self:RegisterOptions(self.options)
end
function Automaton_ItemLinkEnUS:OnEnable()
    if self.runtimeActive then self:InstallHooks(); return end
    self.runtimeActive = true
    self:InstallHooks()
    self:RegisterEvent("ADDON_LOADED", "InstallHooks")
end
function Automaton_ItemLinkEnUS:OnDisable()
    self.runtimeActive = nil
    self:UnregisterAllEvents()
    self:UnhookAll()
end
