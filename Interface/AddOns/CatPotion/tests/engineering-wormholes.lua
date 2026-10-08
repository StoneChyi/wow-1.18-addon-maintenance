-- Run from Interface/AddOns. Test faction filtering through the real settings,
-- quick window, manual use and macro paths, including charge/cooldown updates.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local faction, race = "Alliance", "HighElf"
UnitFactionGroup = function(unit)
    assert(unit == "player")
    return faction
end
UnitRace = function() return race, race end
local sw, org = addon.ItemsByID[51312], addon.ItemsByID[51313]
local assertions = 0
local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end
Equal(sw.item, "便携式虫洞制造机：暴风城", "Stormwind localized identity")
Equal(org.item, "便携式虫洞制造机：奥格瑞玛", "Orgrimmar localized identity")
for _, item in ipairs({ sw, org }) do
    Equal(item.cooldown, 3600, "one hour cooldown")
    Equal(item.gcd, 1.5, "real spell GCD")
    Equal(item.categoryCooldown, 0, "no potion or explosive shared category")
    Equal(addon.GetItemTexture(item), "Interface\\Icons\\INV_Gizmo_06", "client icon")
    Equal(addon.IsMacroExcluded(item, { macroExcluded = { [item.key] = 0 } }), true, "manual only even with imported macro flag")
end

-- Track actual controls; the shared UI mock needs a slider thumb implementation.
local frames, baseCreateFrame = {}, CreateFrame
CreateFrame = function(kind, name, ...)
    local frame = baseCreateFrame(kind, name, ...)
    frame.GetFrameLevel = function() return 1 end
    if kind == "Slider" then
        local thumb = frame:CreateTexture()
        frame.GetThumbTexture = function() return thumb end
    end
    frames[#frames + 1] = frame
    return frame
end
local profile = addon.GetActiveProfile()
local ui = addon.Windows[addon.GetDatabase().activeProfileId]
local function CheckFaction(expected, hidden)
    Equal(addon.IsItemAvailableForPlayer(expected), true, race .. " matching faction")
    Equal(addon.IsItemAvailableForPlayer(hidden), false, race .. " opposing faction hidden")
    Equal(addon.IsItemAvailableForPlayer(addon.ItemsByID[13446]), true, "ordinary potion remains available")
    -- Simulate importing selections for both factions: the quick window must filter.
    profile.selected = { [sw.key] = 1, [org.key] = 1 }
    profile.weaponSlots = {}
    ui.RefreshPotionRows()
    local visible, row = 0
    for _, candidate in ipairs(ui.rows) do
        if candidate:IsVisible() then
            visible, row = visible + 1, candidate
            Equal(candidate.itemData.key, expected.key, "quick window faction selection")
        end
    end
    Equal(visible, 1, "only matching wormhole in quick window")
    -- Recreate settings to model logging in as another race, without modifying data.
    local first = #frames + 1
    dofile("CatPotion/Settings.lua")
    addon.ShowSettings()
    local matching, opposing, selectAll
    for index = first, #frames do
        local frame = frames[index]
        local key = rawget(frame, "itemKey")
        if key == expected.key then matching = frame end
        if key == hidden.key then opposing = frame end
        local label = rawget(frame, "label")
        if label and label.text == "药剂全选" then selectAll = frame end
    end
    Equal(matching ~= nil, true, "matching settings checkbox exists")
    Equal(opposing, nil, "opposing settings checkbox never created")
    profile.selected = {}
    this = selectAll
    selectAll.scripts.OnClick()
    Equal(profile.selected[expected.key], 1, "select all includes matching device")
    Equal(profile.selected[hidden.key], nil, "select all excludes opposing device")
    return row
end
CheckFaction(sw, org)
faction, race = "Horde", "Goblin"
CheckFaction(org, sw)
faction = nil
Equal(addon.IsItemAvailableForPlayer(sw), false, "unknown faction hides Stormwind device")
Equal(addon.IsItemAvailableForPlayer(org), false, "unknown faction hides Orgrimmar device")
faction, race = "Alliance", "Human"

local now, charges, calls, nativeCD, bagID = 1000, -5, 0, nil, 51312
GetTime = function() return now end
GetContainerNumSlots = function(bag) return bag == 0 and 1 or 0 end
GetContainerItemLink = function()
    if charges then return "|Hitem:" .. bagID .. ":0:0:0|h[English item name]|h" end
end
GetContainerItemInfo = function() return "icon", charges, false end
GetContainerItemCooldown = function()
    if nativeCD then return nativeCD[1], nativeCD[2], 1 end
    return 0, 0, 1
end
UseContainerItem = function() calls = calls + 1 end
addon.PlayerIsEating = function() return false end
addon.GetBuffTime = function() return 0 end
addon.MarkBagCacheDirty()
profile.selected = { [sw.key] = 1, [org.key] = 1 }
profile.weaponSlots = {}
profile.macroExcluded = { [sw.key] = 0, [org.key] = 0 }
ui.RefreshPotionRows()
Equal(ui.rows[1].itemData.key, sw.key, "human sees Stormwind device")
Equal(ui.rows[1].countText.text, 5, "negative bag charges displayed as remaining uses")
-- The generic mock returns a no-op function for absent fields; real frames return nil.
ui.rows[1].weaponSlot = false
Equal(addon.UseNextSelectedPotion(), false, "macro never teleports")
Equal(calls, 0, "macro sends no use request")
this, arg1 = ui.rows[1], "RightButton"
ui.rows[1].scripts.OnClick()
Equal(profile.macroExcluded[sw.key], 0, "right click cannot enable wormhole macro")
this, arg1 = ui.rows[1], "LeftButton"
ui.rows[1].scripts.OnClick()
Equal(calls, 1, "left click uses device from bag")
Equal(addon.GetCooldownRemaining(sw.item), 0, "request alone does not start cooldown")
charges = -4
addon.MarkBagCacheDirty()
addon.ConfirmPendingItemUses()
Equal(addon.GetCooldownRemaining(sw.item), 3600, "confirmed charge use starts one hour fallback")
now = now + 3601
nativeCD = { now, 1.5 }
local remaining, kind = addon.GetCooldownInfo(sw.item)
Equal(remaining, 1.5, "native global cooldown retained")
Equal(kind, "gcd", "global cooldown classified")
Equal(addon.UseItem(sw.item), false, "global cooldown blocks use")
now = now + 2
nativeCD = { now, 3590 }
Equal(addon.GetCooldownRemaining(sw.item), 3590, "native cooldown overrides base duration")
Equal(addon.UseItem(sw.item), false, "item cooldown blocks use")
now = now + 3591
nativeCD, charges = nil, -1
addon.MarkBagCacheDirty()
Equal(addon.UseItem(sw.item), true, "last charge can be used")
charges = nil
addon.MarkBagCacheDirty()
addon.ConfirmPendingItemUses()
Equal(addon.GetCooldownRemaining(sw.item), 3600, "last charge retains cooldown after device disappears")
faction = "Horde"
Equal(addon.UseItem(sw.item), false, "direct use rejects opposite faction")
Equal(calls, 2, "no extra request on opposite faction")
bagID, charges = 51313, -5
addon.MarkBagCacheDirty()
Equal(addon.GetCooldownRemaining(org.item), 0, "capital devices have independent item cooldowns")
Equal(addon.UseItem(org.item), true, "Horde manually uses Orgrimmar device")
Equal(calls, 3, "Orgrimmar sends one use request")
charges = -4
addon.MarkBagCacheDirty()
addon.ConfirmPendingItemUses()
Equal(addon.GetCooldownRemaining(org.item), 3600, "Orgrimmar confirmed charge cooldown")
print("PASS: " .. assertions .. " engineering wormhole assertions")
