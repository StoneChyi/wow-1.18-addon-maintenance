dofile("CatPotion/tests/profile-layout.lua")
local addon = CatPotionAddon
local db = addon.GetDatabase()
GetScreenWidth = function() return 1920 end
GetScreenHeight = function() return 1080 end
local function Flush()
    for _, ui in pairs(addon.Windows) do
        if ui.layoutDriver:IsVisible() then
            this = ui.layoutDriver
            ui.layoutDriver.scripts.OnUpdate()
        end
    end
end
for _, profile in pairs(db.profiles) do profile.windowVisible = 0 end
addon.RefreshPotionWindow()
local firstId, secondId = db.profileOrder[1], db.profileOrder[2]
local first, second = db.profiles[firstId], db.profiles[secondId]
first.selected, second.selected = { mongoose = 1 }, { greaterArcanePower = 1 }
first.scale, second.scale = 0.6, 1.3
first.windowX, second.windowX = 50, 100
first.locked, second.locked = 1, 0
assert(addon.SetProfileWindowVisible(firstId, true))
assert(addon.SetProfileWindowVisible(secondId, true))
Flush()
local a, b = addon.Windows[firstId], addon.Windows[secondId]
assert(a.window ~= b.window and a.window:IsVisible() and b.window:IsVisible())
assert(a.rows[1].itemData.key == "mongoose" and b.rows[1].itemData.key == "greaterArcanePower")
assert(a.window:GetScale() == 0.6 and b.window:GetScale() == 1.3)
assert(a.window.point[4] == 50 and b.window.point[4] == 100)
addon.SelectProfile(secondId)
IsShiftKeyDown = function() return true end
this, arg1 = a.rows[1], "RightButton"
a.rows[1].scripts.OnClick()
assert(first.macroExcluded.mongoose == 1 and not second.macroExcluded.mongoose)
local usedProfile
local originalUse = addon.UseItem
addon.UseItem = function(item, data, slot, profileId) usedProfile = profileId end
IsShiftKeyDown = function() return false end
arg1 = "LeftButton"
a.rows[1].scripts.OnClick()
assert(usedProfile == firstId and db.activeProfileId == secondId)
addon.UseItem = originalUse
local movedA, movedB = false, false
a.window.StartMoving = function() movedA = true end
b.window.StartMoving = function() movedB = true end
a.window.scripts.OnDragStart()
b.window.scripts.OnDragStart()
assert(not movedA and movedB)
b.window.GetCenter = function() return 960, 270 end
b.window.scripts.OnDragStop()
assert(second.windowPosition[1] == 0.5 and second.windowPosition[2] == 0.25)
assert(not first.windowPosition)
assert(addon.SetProfileWindowVisible(firstId, false))
Flush()
assert(not a.window:IsVisible() and b.window:IsVisible())
assert(addon.SetProfileWindowVisible(firstId, true))
for i = 3, 10 do
    local id = addon.CreateProfile("多窗" .. i)
    assert(addon.SetProfileWindowVisible(id, true))
end
Flush()
local extra = addon.CreateProfile("第十一窗")
assert(not addon.SetProfileWindowVisible(extra, true))
assert(db.profiles[extra].windowVisible == 0 and not addon.Windows[extra])
assert(addon.SetProfileWindowVisible(firstId, false))
assert(addon.SetProfileWindowVisible(extra, true))
Flush()
assert(addon.DeleteProfile(secondId))
Flush()
assert(not addon.Windows[secondId] and not b.window:IsVisible())
-- Restoring saved flags recreates the same set without changing the active profile.
local activeId = db.activeProfileId
addon.RefreshPotionWindow()
Flush()
assert(db.activeProfileId == activeId)
local count = 0
for _, ui in pairs(addon.Windows) do if ui.window:IsVisible() then count = count + 1 end end
assert(count == 9)
local originalEnchantInfo, enchantScans = GetWeaponEnchantInfo, 0
for _, profile in pairs(db.profiles) do profile.weaponSlots = { instantPoison6 = { main = 1 } } end
addon.RefreshPotionWindow()
Flush()
GetWeaponEnchantInfo = function()
    enchantScans = enchantScans + 1
    return originalEnchantInfo()
end
arg1 = 1
addon.RefreshDriver.scripts.OnUpdate()
assert(enchantScans == 1)
GetWeaponEnchantInfo = originalEnchantInfo
-- Legacy single-window state belongs only to the previously active profile.
CatPotionDB = {
    profiles = { [1] = { name = "默认配置" }, [2] = { name = "原当前配置" } },
    profileOrder = { 1, 2 }, defaultProfileId = 1, activeProfileId = 2,
    windowVisible = 1, windowX = 123, windowY = -45
}
db = addon.GetDatabase()
assert(db.profiles[1].windowVisible == 0 and db.profiles[2].windowVisible == 1)
assert(db.profiles[2].windowX == 123 and db.profiles[2].windowY == -45)
addon.RefreshPotionWindow()
Flush()
assert(addon.Windows[2].window:IsVisible() and not addon.Windows[1])
print("PASS: independent windows, row ownership, scale, position, lock, 10-window cap and deletion")
print("PASS: shared enchant polling and legacy single-window migration")
db.profiles[2].hideInCombat = 1
assert(addon.SetProfileWindowVisible(1, true))
Flush()
event = "PLAYER_REGEN_DISABLED"
addon.WindowEvents.scripts.OnEvent()
Flush()
assert(not addon.Windows[2].window:IsVisible() and addon.Windows[1].window:IsVisible())
assert(db.profiles[2].windowVisible == 1)
event = "PLAYER_REGEN_ENABLED"
addon.WindowEvents.scripts.OnEvent()
Flush()
assert(addon.Windows[2].window:IsVisible())
event = "PLAYER_REGEN_DISABLED"
addon.WindowEvents.scripts.OnEvent()
assert(addon.SetProfileWindowVisible(2, false))
event = "PLAYER_REGEN_ENABLED"
addon.WindowEvents.scripts.OnEvent()
Flush()
assert(not addon.Windows[2].window:IsVisible())
print("PASS: per-profile combat hiding, restoration and manual close preservation")

event = "PLAYER_REGEN_ENABLED"
addon.WindowEvents.scripts.OnEvent()
local targetId = addon.CreateProfile("切换目标")
local sourceId = db.profileOrder[1]
local sourceUI = addon.Windows[sourceId]
local target = db.profiles[targetId]
sourceUI.window.GetCenter = function() return 960, 270 end
target.selected = { greaterArcanePower = 1 }
target.scale = 1.2
assert(addon.SwitchPotionWindowProfile(sourceId, targetId))
Flush()
assert(db.profiles[sourceId].windowVisible == 0 and target.windowVisible == 1)
assert(not sourceUI.window:IsVisible() and addon.Windows[targetId].window:IsVisible())
assert(db.activeProfileId == targetId)
assert(target.windowPosition[1] == 0.5 and target.windowPosition[2] == 0.25)
assert(addon.Windows[targetId].rows[1].itemData.key == "greaterArcanePower")
assert(addon.Windows[targetId].window:GetScale() == 1.2)
assert(not addon.SwitchPotionWindowProfile(targetId, targetId))
assert(addon.SetProfileWindowVisible(sourceId, true))
Flush()
local originalPrint, rejection = addon.Print, nil
addon.Print = function(message, errorMessage) rejection = { message, errorMessage } end
target.hideInCombat = 1
event = "PLAYER_REGEN_DISABLED"
addon.WindowEvents.scripts.OnEvent()
Flush()
assert(not addon.Windows[targetId].window:IsVisible() and target.windowVisible == 1)
assert(not addon.SwitchPotionWindowProfile(sourceId, targetId))
assert(rejection and rejection[2] == true and string.find(rejection[1], "已经开启"))
assert(db.profiles[sourceId].windowVisible == 1 and db.activeProfileId == targetId)
addon.Print = originalPrint
event = "PLAYER_REGEN_ENABLED"
addon.WindowEvents.scripts.OnEvent()
assert(addon.SetProfileWindowVisible(sourceId, false))
Flush()
-- Select a closed profile through the actual dropdown entry callback.
local targetUI = addon.Windows[targetId]
targetUI.profileMenuOffset = 0
targetUI.RefreshProfileMenu()
for _, entry in ipairs(targetUI.profileMenuEntries) do
    if entry.targetProfileId == sourceId then
        this = entry
        entry.scripts.OnClick()
        break
    end
end
Flush()
assert(db.profiles[sourceId].windowVisible == 1 and target.windowVisible == 0)
assert(sourceUI.window:IsVisible() and not targetUI.window:IsVisible())
assert(db.activeProfileId == sourceId)
print("PASS: dropdown switching, position transfer, target appearance and already-open combat-hidden rejection")
