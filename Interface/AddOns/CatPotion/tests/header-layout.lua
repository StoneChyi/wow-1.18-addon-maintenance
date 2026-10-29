-- Run from Interface/AddOns; verify the actual header and dropdown callbacks.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local db = addon.GetDatabase()
local id = db.defaultProfileId
local profile = db.profiles[id]
local ui = addon.Windows[id]
GetScreenWidth = function() return 1920 end
GetScreenHeight = function() return 1080 end
profile.weaponSlots = {}
profile.selected = { mongoose = 1, arcanePower = 1 }
profile.layout, profile.layoutLimit, profile.minimized = "horizontal", 2, 0
profile.windowVisible = 1
local assertions = 0
local function Check(condition, message)
    assert(condition, message)
    assertions = assertions + 1
end
local function Refresh()
    ui.RefreshPotionWindow()
    this = ui.layoutDriver
    ui.layoutDriver.scripts.OnUpdate()
end
local function CheckHeader(message)
    Check(ui.profileSwitchButton:IsVisible(), message .. ": profile switch visible")
    local width = ui.window:GetWidth()
    local switch = ui.profileSwitchButton
    local close = ui.closeButton
    local switchRight = width + switch.point[4]
    local switchLeft = switchRight - switch:GetWidth()
    local closeLeft = width + close.point[4] - close:GetWidth()
    Check(switchLeft >= 10, message .. ": switch inside window padding")
    Check(switchRight <= closeLeft - 4, message .. ": switch does not overlap close")
    if ui.settingsButton:IsVisible() then
        local settingsLeft = width + ui.settingsButton.point[4] - ui.settingsButton:GetWidth()
        Check(switchRight <= settingsLeft - 4, message .. ": switch does not overlap settings")
    end
end
Refresh()
Check(ui.window:GetWidth() == 294, "two columns retain existing width")
CheckHeader("normal two columns")
this = ui.profileSwitchButton
this.scripts.OnClick()
Check(ui.profileMenu:IsVisible(), "two-column dropdown opens")
Check(#ui.profileMenuEntries >= 1, "two-column dropdown contains profiles")
this.scripts.OnClick()
Check(not ui.profileMenu:IsVisible(), "dropdown closes on second click")

profile.layoutLimit = 3
profile.selected.greaterArcanePower = 1
Refresh()
CheckHeader("normal three columns")
profile.layoutLimit = 2
Refresh()
CheckHeader("switch back to two columns")

profile.minimized = 1
Refresh()
Check(ui.window:GetWidth() == 104, "compact two columns retain existing width")
Check(ui.settingsButton:IsVisible(), "compact header always retains settings")
CheckHeader("compact two columns")
profile.selected = { mongoose = 1 }
Refresh()
CheckHeader("compact one item")
profile.minimized = 0
Refresh()
Check(ui.window:GetWidth() == 155, "normal one item retains existing width")
CheckHeader("normal one item")

profile.selected = { mongoose = 1, arcanePower = 1 }
profile.layout = "vertical"
Refresh()
CheckHeader("vertical two items per column")
profile.selected = {}
Refresh()
CheckHeader("empty selection")
print("PASS: " .. assertions .. " header layout and two-column dropdown assertions")
