-- The shared harness enforces real FontString initialization; all controls here
-- are the actual Window.lua controls, not a mirrored layout implementation.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local db = addon.GetDatabase()
local id = db.defaultProfileId
local profile = db.profiles[id]
local ui = addon.Windows[id]
local checks, opens, starts, stops = 0, 0, 0, 0
local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end
GetScreenWidth = function() return 1920 end
GetScreenHeight = function() return 1080 end
GetTime = function() return 3000 end
profile.name = "这是一个很长的配置名称，不能挤掉设置按钮"
profile.weaponSlots = {}
profile.windowVisible = 1
local naked = ui.window:CreateFontString(nil, "OVERLAY")
Equal(pcall(function() naked:SetText("missing font") end), false, "fontless SetText must fail")
failedFontPaths["Fonts\\FRIZQT__.TTF"] = true
Equal(naked:SetFont("Fonts\\FRIZQT__.TTF", 12), nil, "configured font failure is real")
naked:SetFontObject(GameFontNormal)
naked:SetText("built-in fallback")

local function Refresh()
    ui.RefreshPotionWindow()
    this = ui.layoutDriver
    ui.layoutDriver.scripts.OnUpdate()
end
for _, minimized in ipairs({ 0, 1 }) do
    for _, columns in ipairs({ 1, 2, 3 }) do
        for _, direction in ipairs({ "horizontal", "vertical" }) do
            profile.minimized, profile.layoutLimit, profile.layout = minimized, columns, direction
            profile.selected = { mongoose = 1, arcanePower = 1, greaterArcanePower = 1 }
            Refresh()
            Equal(ui.settingsButton:IsVisible(), true, "settings always visible")
            Equal(ui.profileSwitchButton:IsVisible(), true, "switch always visible")
            Equal(ui.closeButton:IsVisible(), true, "close always visible")
            local width = ui.window:GetWidth()
            local toolRight = width + ui.settingsButton.point[4]
            local toolLeft = toolRight - ui.settingsButton:GetWidth()
            local switchRight = width + ui.profileSwitchButton.point[4]
            local switchLeft = switchRight - ui.profileSwitchButton:GetWidth()
            local closeLeft = width + ui.closeButton.point[4] - ui.closeButton:GetWidth()
            Equal(switchLeft >= 10, true, "switch inside header")
            Equal(switchRight <= toolLeft - 4, true, "switch does not cover tool")
            Equal(toolRight <= closeLeft - 4, true, "tool does not cover close")
            Equal(ui.rows[1]:GetWidth(), minimized == 1 and 40 or 135, "tool never consumes item column")
            Equal(ui.settingsButton.label.font ~= nil, true, "tool label retains built-in font after SetFont failure")
        end
    end
end
profile.minimized, profile.layout, profile.layoutLimit = 1, "horizontal", 1
profile.selected = { mongoose = 1 }
Refresh()
Equal(ui.window:GetWidth(), 94, "smallest compact window reserves complete toolbar")
Equal(ui.settingsButton:GetWidth(), 22, "narrow settings button compact")
Equal(ui.settingsButton.label.text, "设", "narrow label fits existing button")

local secondId = addon.CreateProfile("独立窗口锁定")
local second = db.profiles[secondId]
second.selected, second.weaponSlots = { mongoose = 1 }, {}
second.minimized, second.locked = 1, 1
addon.SetProfileWindowVisible(secondId, true)
local secondUI = addon.Windows[secondId]
Equal(secondUI.settingsButton.label.font ~= nil, true, "new-window label survives failed configured font")
addon.SelectProfile(secondId)
profile.locked = 0
ui.window.StartMoving = function() starts = starts + 1 end
ui.window.StopMovingOrSizing = function() stops = stops + 1 end
ui.window.scripts.OnDragStart()
Equal(starts, 1, "unlocked window can drag")
this, arg1 = ui.settingsButton, "RightButton"
ui.settingsButton.scripts.OnClick()
Equal(profile.locked, 1, "tool right click locks owning window")
Equal(second.locked, 1, "tool does not change another window")
Equal(db.activeProfileId, secondId, "locking does not switch settings profile")
Equal(stops, 1, "locking stops an active drag")
ui.window.scripts.OnDragStart()
Equal(starts, 1, "locked drag ignored")
ui.settingsButton.scripts.OnClick()
Equal(profile.locked, 0, "second right click unlocks")
ui.window.scripts.OnDragStart()
Equal(starts, 2, "unlocked drag restored")
addon.ShowSettings = function() opens = opens + 1 end
this, arg1 = ui.settingsButton, "LeftButton"
ui.settingsButton.scripts.OnClick()
Equal(opens, 1, "left tool opens settings")
Equal(db.activeProfileId, id, "left selects owning settings profile")
Equal(profile.locked, 0, "left does not change lock")

-- Modifier interactions use the owning profile and preserve drag suppression.
local shift, uses = false, 0
IsShiftKeyDown = function() return shift end
addon.UseItem = function() uses = uses + 1 end
local row = ui.rows[1]
this, arg1 = row, "RightButton"
local excluded = profile.macroExcluded.mongoose
row.scripts.OnClick()
Equal(profile.macroExcluded.mongoose, excluded, "plain right no longer toggles macro")
Equal(uses, 0, "plain right does not consume ordinary potion")
shift = true
arg1 = "LeftButton"
row.scripts.OnClick()
Equal(profile.macroExcluded.mongoose, excluded, "Shift-left reserved for sorting")
Equal(uses, 0, "Shift-left does not use potion")
arg1 = "RightButton"
row.scripts.OnClick()
Equal(profile.macroExcluded.mongoose, addon.ToBoolean(excluded) and 0 or 1, "Shift-right toggles macro")
Equal(second.macroExcluded.mongoose, nil, "modifier toggle belongs to clicked window")
local toggled = profile.macroExcluded.mongoose
ui.suppressRowClickUntil = 3000.25
row.scripts.OnClick()
Equal(profile.macroExcluded.mongoose, toggled, "drag release suppresses modifier toggle")
ui.suppressRowClickUntil = 0
ui.dragSourceKey = "mongoose"
row.scripts.OnClick()
Equal(profile.macroExcluded.mongoose, toggled, "active drag suppresses modifier toggle")
ui.dragSourceKey = nil
shift = false
arg1 = "LeftButton"
row.scripts.OnClick()
Equal(uses, 1, "plain left still manually uses")

-- A simulated reload constructs fresh controls from the same persisted profile.
profile.locked = 1
dofile("CatPotion/Window.lua")
local reloaded = addon.Windows[id]
Equal(addon.GetDatabase().profiles[id].locked, 1, "lock survives reload")
local reloadedStarts = 0
reloaded.window.StartMoving = function() reloadedStarts = reloadedStarts + 1 end
reloaded.window.scripts.OnDragStart()
Equal(reloadedStarts, 0, "reloaded locked window cannot drag")
Equal(reloaded.settingsButton:IsVisible(), true, "reloaded compact settings stays visible")
print("PASS: " .. checks .. " compact header, per-window lock, modifier and strict font assertions")
