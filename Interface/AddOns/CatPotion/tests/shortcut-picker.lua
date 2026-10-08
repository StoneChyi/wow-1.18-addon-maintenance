-- Run from Interface/AddOns. Load the actual chat bar and verify its "药" button
-- against the real picker/window APIs, including edge placement and paging.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local screenWidth, screenHeight, rootScale, barScale = 1200, 800, 1, 1
local anchorX, anchorY = 400, 40
GetScreenWidth = function() return screenWidth end
GetScreenHeight = function() return screenHeight end
UIParent.GetWidth = function() return screenWidth end
UIParent.GetHeight = function() return screenHeight end
UIParent.GetScale = function() return rootScale end
UIParent.GetEffectiveScale = function() return rootScale end
CatPotionDB = {
    profiles = {
        [1] = { name = "默认", selected = { mongoose = 1 }, windowVisible = 0 },
        [2] = { name = "PVP", selected = { majorHealing = 1 }, windowVisible = 0 },
        [3] = { name = "工程", selected = { sapperCharge = 1 }, windowVisible = 0 }
    },
    profileOrder = { 1, 2, 3 }, defaultProfileId = 1, activeProfileId = 3,
    nextProfileId = 4, profileWindowsMigrated = true
}
local db = addon.GetDatabase()
addon.RefreshPotionWindow()
local settingsShown, messages = 0, {}
addon.ShowSettings = function() settingsShown = settingsShown + 1 end
addon.TogglePotionWindow = function() error("chat bar must not toggle the active profile") end
DEFAULT_CHAT_FRAME.AddMessage = function(_, text) messages[#messages + 1] = text end
dofile("S_ChatBar/ChatBar.lua")
local button = ChannelCatPotion
button.GetEffectiveScale = function() return rootScale * barScale end
button.GetCenter = function() return anchorX / barScale, anchorY / barScale end
local assertions = 0
local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end
local function Check(value, label)
    assert(value, label)
    assertions = assertions + 1
end
local function Click(kind)
    this, arg1 = button, kind or "LeftButton"
    button.scripts.OnClick()
end
local function Flush()
    for _, ui in pairs(addon.Windows) do
        this, arg1 = ui.layoutDriver, 0.01
        ui.layoutDriver.scripts.OnUpdate()
    end
end
local function Pick(id)
    local picker = addon.WindowPicker
    for _, entry in ipairs(picker.profileMenuEntries) do
        if entry:IsVisible() and entry.targetProfileId == id then
            this = entry
            entry.scripts.OnClick()
            Flush()
            return entry
        end
    end
    error("profile not on visible page: " .. id)
end
local function Label(id)
    for _, entry in ipairs(addon.WindowPicker.profileMenuEntries) do
        if entry:IsVisible() and entry.targetProfileId == id then return entry.text:GetText() end
    end
end
local function CheckBounds(label)
    local menu = addon.WindowPicker.profileMenu
    menu.GetEffectiveScale = function() return rootScale * menu:GetScale() end
    addon.WindowPicker.RefreshProfileMenu()
    local scale, point = menu:GetEffectiveScale(), menu.point
    Equal(point[1], "BOTTOMLEFT", label .. " screen anchor")
    local left, bottom = point[4] * scale, point[5] * scale
    Check(left >= 8 * rootScale - 0.01, label .. " left edge")
    Check(bottom >= 8 * rootScale - 0.01, label .. " bottom edge")
    Check(left + menu:GetWidth() * scale <= (screenWidth - 8) * rootScale + 0.01, label .. " right edge")
    Check(bottom + menu:GetHeight() * scale <= (screenHeight - 8) * rootScale + 0.01, label .. " top edge")
end

Click()
local picker = addon.WindowPicker
Check(picker.profileMenu:IsVisible(), "picker opens with every window closed")
Equal(settingsShown, 0, "left click does not open settings")
Equal(db.profiles[3].windowVisible, 0, "left click does not open latest active profile")
Equal(Label(1), "默认（已关闭）", "closed status shown")
Equal(Label(2), "PVP（已关闭）", "all configurations listed")
picker.profileMenu.scripts.OnShow()
Check(picker.profileMenuBlocker:IsVisible(), "outside-click blocker enabled")
this = picker.profileMenuBlocker
picker.profileMenuBlocker.scripts.OnMouseUp()
Check(not picker.profileMenu:IsVisible(), "outside click dismisses picker")
picker.profileMenu.scripts.OnHide()
Check(not picker.profileMenuBlocker:IsVisible(), "blocker removed on dismiss")
Click()
Click()
Check(not picker.profileMenu:IsVisible(), "repeated left click dismisses")
Click()
Pick(1)
Equal(db.activeProfileId, 3, "choosing window leaves active settings configuration unchanged")
Equal(db.profiles[1].windowVisible, 1, "chosen default window opens")
Equal(db.profiles[3].windowVisible, 0, "latest configuration stays closed")
Equal(addon.Windows[1].rows[1].itemData.key, "mongoose", "chosen window has own contents")
Click()
Equal(Label(1), "默认（已开启）", "open status refreshes")
Pick(2)
Check(addon.Windows[1].window:IsVisible() and addon.Windows[2].window:IsVisible(), "multiple chosen windows stay open")
Equal(addon.Windows[2].rows[1].itemData.key, "majorHealing", "second window has own contents")
Click()
Pick(1)
Check(not addon.Windows[1].window:IsVisible() and addon.Windows[2].window:IsVisible(), "selection closes only chosen open window")
Click()
Click("RightButton")
Equal(settingsShown, 1, "right click opens settings")
Check(not picker.profileMenu:IsVisible(), "right click closes picker")
Click("RightButton")
Equal(settingsShown, 2, "right click always opens rather than toggles settings")
Equal(db.activeProfileId, 3, "right click preserves settings configuration")
Click()
MouseIsOver = function(frame) return frame == button end
this, arg1 = picker.profileMenuBlocker, "RightButton"
picker.profileMenuBlocker.scripts.OnMouseUp()
Equal(settingsShown, 3, "right click on shortcut opens settings through outside blocker")
Check(not picker.profileMenu:IsVisible(), "blocker right click dismisses picker")

-- Picker and each small-window switch menu cannot cover one another.
addon.SetProfileWindowVisible(1, true)
Flush()
Click()
this = addon.Windows[1].profileSwitchButton
this.scripts.OnClick()
Check(not picker.profileMenu:IsVisible(), "window triangle dismisses shortcut picker")
Check(addon.Windows[1].profileMenu:IsVisible(), "window triangle still opens switch menu")
Click()
Check(not addon.Windows[1].profileMenu:IsVisible(), "shortcut dismisses window switch menu")
Check(addon.Windows[1].window:IsVisible(), "opening picker preserves window visibility")

-- Battle-hidden windows count as open; toggling one off must prevent restoration.
db.profiles[2].hideInCombat = 1
event = "PLAYER_REGEN_DISABLED"
addon.WindowEvents.scripts.OnEvent()
Flush()
Check(not addon.Windows[2].window:IsVisible(), "PVP window hides in combat")
picker.profileMenu:Hide()
Click()
Equal(Label(2), "PVP（已开启）", "battle-hidden window shows logical open state")
Pick(2)
event = "PLAYER_REGEN_ENABLED"
addon.WindowEvents.scripts.OnEvent()
Flush()
Equal(db.profiles[2].windowVisible, 0, "picker closes battle-hidden window")
Check(not addon.Windows[2].window:IsVisible(), "closed window stays closed after combat")

for index = 4, 12 do addon.CreateProfile("配置" .. index) end
addon.SelectProfile(3)
picker.profileMenu:Hide()
Click()
Check(picker.profileMenuNext:IsVisible(), "more than eight profiles paginate")
this = picker.profileMenuNext
this.scripts.OnClick()
Check(Label(12) ~= nil, "last configuration reachable by page button")
Pick(12)
Equal(db.profiles[12].windowVisible, 1, "later-page selection opens correct profile")
Equal(db.activeProfileId, 3, "later-page selection does not change active profile")

-- The existing ten-window cap is still enforced without closing any other window.
addon.SetProfileWindowVisible(12, false)
for index = 1, 10 do addon.SetProfileWindowVisible(index, true) end
picker.profileMenu:Hide()
Click()
this = picker.profileMenuNext
this.scripts.OnClick()
Pick(12)
Equal(db.profiles[12].windowVisible, 0, "ten-window cap enforced")
Equal(db.profiles[1].windowVisible, 1, "cap rejection preserves existing window")
Check(string.find(messages[#messages], "10") ~= nil, "cap rejection explains limit")

for _, corner in ipairs({ { 15, 25 }, { 1190, 25 }, { 1190, 790 }, { 15, 790 } }) do
    anchorX, anchorY = corner[1], corner[2]
    picker.profileMenu:Hide()
    Click()
    CheckBounds("corner " .. anchorX .. "," .. anchorY)
end
rootScale, barScale = 0.75, 1.4
CheckBounds("scaled toolbar")
screenWidth, screenHeight, anchorX, anchorY = 240, 150, 230, 20
CheckBounds("small screen")
Check(picker.profileMenuPageSize < 8, "small screen reduces rows per page")
local visited = {}
picker.profileMenuOffset = 0
picker.RefreshProfileMenu()
for index = 1, #db.profileOrder do
    for _, entry in ipairs(picker.profileMenuEntries) do
        if entry:IsVisible() then visited[entry.targetProfileId] = true end
    end
    this = picker.profileMenuNext
    this.scripts.OnClick()
end
for _, id in ipairs(db.profileOrder) do Check(visited[id], "every configuration reachable on small screen " .. id) end
picker.profileMenuOffset = 0
picker.RefreshProfileMenu()
this, arg1 = picker.profileMenu, -1
picker.profileMenu.scripts.OnMouseWheel()
Equal(picker.profileMenuOffset, 1, "mouse wheel pages profiles")

local original = CatPotionAddon
CatPotionAddon = nil
Click()
Check(string.find(messages[#messages], "CatPotion") ~= nil, "missing addon reports clear message")
CatPotionAddon = original
print("PASS: " .. assertions .. " chat bar picker assertions")
