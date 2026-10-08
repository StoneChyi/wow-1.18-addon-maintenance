-- Run from Interface/AddOns. Verify stored order, actual drag/click callbacks,
-- deferred layouts, weapon-slot ownership and settings reset.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local db = addon.GetDatabase()
local profileId = db.activeProfileId
local profile, ui = db.profiles[profileId], addon.Windows[profileId]
local now, shift, mouseRow, focusOverride, uses = 5000, false, nil, nil, {}
GetTime = function() return now end
GetScreenWidth = function() return 1024 end
GetScreenHeight = function() return 768 end
IsShiftKeyDown = function() return shift and 1 or nil end
MouseIsOver = function(row) return row == mouseRow and 1 or nil end
GetMouseFocus = function() return focusOverride or mouseRow end
UnitFactionGroup = function() return "Alliance" end
local assertions = 0
local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end
local function Keys(entries)
    local keys = {}
    for _, entry in ipairs(entries) do keys[#keys + 1] = entry.key end
    return table.concat(keys, ",")
end
local function Order(p) return Keys(addon.GetProfileWindowEntries(p or profile)) end
local function Rows()
    local keys = {}
    for _, row in ipairs(ui.rows) do
        if row:IsVisible() then keys[#keys + 1] = row.entryKey end
    end
    return table.concat(keys, ",")
end
local function Row(key)
    for _, row in ipairs(ui.rows) do if row:IsVisible() and row.entryKey == key then return row end end
end
local function Click(row, button)
    this, arg1 = row, button or "LeftButton"
    row.scripts.OnClick()
end
local function Start(row)
    this, arg1 = row, "LeftButton"
    row.scripts.OnDragStart()
end
local function Stop(row, target)
    mouseRow, this = target, row
    row.scripts.OnDragStop()
end
local function Layout()
    this, arg1 = ui.layoutDriver, 0.01
    ui.layoutDriver.scripts.OnUpdate()
    now = now + 0.3
end
profile.selected = { mongoose = 1, majorHealing = 1, stormwindWormhole = 1, orgrimmarWormhole = 1 }
profile.weaponSlots = { instantPoison6 = { main = 1, off = 1 } }
profile.windowOrder = {}
profile.windowVisible, profile.locked = 1, 1
ui.RefreshPotionRows()
ui.window:Show()
local baseline = "mongoose,instantPoison6:16,instantPoison6:17,majorHealing,stormwindWormhole"
Equal(Order(), baseline, "default category order and faction filtering")
Equal(Rows(), baseline, "existing window layout order preserved")
Equal(addon.SwapProfileWindowEntries(profileId, "mongoose", "mongoose"), false, "self drop rejected")
Equal(addon.SwapProfileWindowEntries(profileId, "mongoose", "orgrimmarWormhole"), false, "hidden faction cannot receive drop")
Equal(addon.SwapProfileWindowEntries(99999, "mongoose", "majorHealing"), false, "deleted profile rejected")
addon.UseItem = function(name, item, slot, owner)
    uses[#uses + 1] = { item = item.key, slot = slot, profile = owner }
    return true
end

local source, target = Row("mongoose"), Row("majorHealing")
Start(source)
Stop(source, target)
Click(source)
Equal(Order(), baseline, "drag without Shift does not reorder")
Equal(#uses, 0, "ordinary drag release cannot consume a potion")
now = now + 0.3
shift = true
Click(source)
local excluded = profile.macroExcluded.mongoose
Click(source, "RightButton")
Equal(#uses, 0, "Shift click never consumes")
Equal(profile.macroExcluded.mongoose, excluded, "Shift right click never changes macro flag")
Start(source)
Equal(ui.dragSourceKey, "mongoose", "Shift arms source")
local targetPoint = target.point
shift = false -- Releasing the modifier during a drag must still suppress use.
Stop(source, target)
Click(target)
local swapped = "majorHealing,instantPoison6:16,instantPoison6:17,mongoose,stormwindWormhole"
Equal(Order(), swapped, "drop swaps two positions")
Equal(#uses, 0, "release on destination never consumes")
Equal(Rows(), baseline, "rows wait for next frame")
Equal(target.point, targetPoint, "drag callback leaves native anchors untouched")
Equal(ui.layoutDriver:IsVisible(), true, "safe layout scheduled")
Layout()
Equal(Rows(), swapped, "next frame applies saved order")
Equal(profile.locked, 1, "window lock does not block item sorting")
Equal(profile.selected.mongoose, 1, "sorting preserves selection")
Equal(profile.macroExcluded.mongoose, excluded, "sorting preserves macro flag")

shift = true
source = Row("majorHealing")
Start(source)
Stop(source, nil)
Equal(Order(), swapped, "dropping outside cancels")
Start(source)
Stop(source, source)
Equal(Order(), swapped, "dropping on source cancels")
Start(source)
focusOverride = {} -- Another window covers a source-window row at the cursor.
Stop(source, Row("mongoose"))
Equal(Order(), swapped, "drop over another window cannot swap underlying rows")
focusOverride = nil
Start(source)
this = ui.window
ui.window.scripts.OnHide()
Equal(ui.dragSourceKey, nil, "hiding cancels drag")
Stop(source, Row("mongoose"))
Equal(Order(), swapped, "cancelled drag cannot swap later")

Start(Row("instantPoison6:17"))
Stop(Row("instantPoison6:17"), Row("majorHealing"))
Layout()
Equal(Row("instantPoison6:17").weaponSlot, 17, "offhand slot follows moved item")
Equal(Row("instantPoison6:16").weaponSlot, 16, "main hand retains separate identity")
Equal(profile.weaponSlots.instantPoison6.off, 1, "sorting preserves hand selection")
shift = false
Click(Row("instantPoison6:17"))
Equal(uses[1].slot, 17, "moved offhand click still targets offhand")
Equal(uses[1].profile, profileId, "moved click retains owner profile")
local customized = Order()
profile.selected.majorHealing = 0
ui.RefreshPotionRows()
Equal(Row("majorHealing"), nil, "deselected row removed")
profile.selected.majorHealing = 1
ui.RefreshPotionRows()
Equal(Order(), customized, "reselected item restores custom position")
profile.selected.darkRune = 1
Equal(string.sub(Order(), -8), "darkRune", "new selection appends to customized order")
profile.selected.darkRune = nil

profile.layout, profile.layoutLimit, profile.minimized = "vertical", 2, 1
ui.RequestPotionWindowRefresh()
Layout()
Equal(Rows(), customized, "vertical compact mode preserves custom order")
Equal(ui.rows[1].point[4], 0, "vertical first item in first column")
Equal(ui.rows[2].point[5], -42, "vertical second item in next row")
profile.layout, profile.layoutLimit, profile.minimized = "horizontal", 2, 0
ui.RequestPotionWindowRefresh()
Layout()
Equal(Rows(), customized, "regular horizontal mode preserves custom order")
Equal(ui.rows[2].point[4], 139, "horizontal second item in next column")

local otherId = addon.CreateProfile("Order test")
local other = db.profiles[otherId]
other.selected = { mongoose = 1, majorHealing = 1 }
other.windowOrder = 42
addon.GetDatabase()
Equal(type(other.windowOrder), "table", "invalid order storage normalized")
Equal(Order(other), "mongoose,majorHealing", "new profile starts with default order")
Equal(addon.SwapProfileWindowEntries(otherId, "mongoose", "majorHealing"), true, "other profile can sort")
Equal(Order(), customized, "other profile sorting leaves source unchanged")
Equal(addon.SwapProfileWindowEntries(profileId, "mongoose", "majorHealing"), true, "source can sort while another profile is active")
Equal(Order(other), "majorHealing,mongoose", "source sorting leaves other unchanged")
-- Malformed imported entries neither duplicate nor hide selected items.
other.windowOrder = { "missing", "majorHealing", "majorHealing", 10, "mongoose" }
Equal(Order(other), "majorHealing,mongoose", "invalid saved entries ignored")
addon.SwapProfileWindowEntries(otherId, "majorHealing", "mongoose")
Equal(table.concat(other.windowOrder, ","), "mongoose,majorHealing", "saving removes invalid and duplicate entries")

-- Display order must never change replenish priority.
other.selected = { mongoose = 1, giants = 1 }
other.weaponSlots = {}
other.windowOrder = { "mongoose", "giants" }
local canonical = addon.GetProfileWindowEntries({ selected = other.selected })
local first = canonical[1].item.key
addon.SwapProfileWindowEntries(otherId, canonical[1].key, canonical[2].key)
addon.FindBagItem = function() return 0, 1, 1 end
addon.GetBuffTime = function() return 0 end
addon.GetCooldownRemaining = function() return 0 end
addon.PlayerIsEating = function() return false end
uses = {}
Equal(addon.UseNextSelectedPotion(otherId), true, "macro still finds potion")
Equal(uses[1].item, first, "macro retains canonical priority after display swap")
addon.SelectProfile(profileId)

-- Real settings reset button resets only the active configuration.
local frames, baseCreate = {}, CreateFrame
CreateFrame = function(kind, name, ...)
    local frame = baseCreate(kind, name, ...)
    frame.GetFrameLevel = function() return 1 end
    if kind == "Slider" then
        local thumb = frame:CreateTexture()
        frame.GetThumbTexture = function() return thumb end
    end
    frames[#frames + 1] = frame
    return frame
end
dofile("CatPotion/Settings.lua")
addon.ShowSettings()
local manager, reset
for _, frame in ipairs(frames) do
    local label = rawget(frame, "label")
    if label and label.text == "配置管理" then manager = frame end
end
this = manager
manager.scripts.OnClick()
for _, frame in ipairs(frames) do
    local label = rawget(frame, "label")
    if label and label.text == "恢复默认顺序" then reset = frame end
end
Equal(reset ~= nil, true, "reset button accessible in profile manager")
local savedOther = Order(other)
this = reset
reset.scripts.OnClick()
Equal(Order(), baseline, "reset restores default source order")
Equal(Order(other), savedOther, "reset leaves other profile order alone")
Layout()
Equal(Rows(), baseline, "reset safely rearranges current window")

-- Reloading the addon reconstructs the same order from per-character SavedVariables.
addon.SwapProfileWindowEntries(profileId, "mongoose", "majorHealing")
local saved = Order()
dofile("CatPotion/Core.lua")
Equal(Keys(CatPotionAddon.GetProfileWindowEntries(CatPotionAddon.GetDatabase().profiles[profileId])), saved, "order survives addon reload")
print("PASS: " .. assertions .. " custom window order assertions")
