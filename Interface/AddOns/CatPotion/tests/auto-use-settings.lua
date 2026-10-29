-- Exercise real settings controls and the existing row handlers with strict fonts.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
GetScreenWidth = function() return 1920 end
GetScreenHeight = function() return 1080 end
dofile("CatPotion/AutoUse.lua")
local checks, uses = 0, 0
local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local create = CreateFrame
CreateFrame = function(kind, name, parent, template)
    local frame = create(kind, name, parent, template)
    if kind == "Slider" then
        function frame:SetValue(value)
            self.value = value
            local old = this
            this = self
            if self.scripts.OnValueChanged then self.scripts.OnValueChanged() end
            this = old
        end
        function frame:GetValue() return self.value end
        function frame:EnableMouse(enabled) self.mouseEnabled = enabled end
    end
    return frame
end
failedFontPaths["Fonts\\FRIZQT__.TTF"] = true
dofile("CatPotion/AutoUseSettings.lua")
local red = addon.ItemsByName["特效治疗药水"]
local blue = addon.ItemsByName["特效法力药水"]
local tea = addon.ItemsByName["诺达纳尔草药茶"]
local function Click(button)
    this = button
    button.scripts.OnClick()
end
Equal(addon.ShowAutoUseSettings(addon.ItemsByName["猫鼬药剂"]), false, "unsupported item cannot open threshold settings")
Equal(addon.ShowAutoUseSettings(red), true, "red settings open")
local panel = addon.AutoUseSettings
Equal(panel:IsVisible(), true, "dialog visible")
Equal(addon.GetAutoUseConfig(red).enabled, 0, "opening settings never enables automation")
Equal(panel.enabled.mark:IsVisible(), false, "disabled by default shown accurately")
Equal(panel.health.mouseEnabled, true, "red health slider enabled")
Equal(panel.mana.mouseEnabled, false, "red mana slider disabled")
Equal(panel.title.font ~= nil, true, "title keeps inherited font when FRIZ fails")
Equal(panel.message.font ~= nil, true, "empty status text has initialized font")
panel.health:SetValue(43)
Click(panel.enabled)
Equal(addon.GetAutoUseConfig(red).enabled, 0, "editing checkbox is only a draft")
Click(panel.cancel)
Equal(addon.GetAutoUseConfig(red).enabled, 0, "cancel never enables")
Equal(addon.GetAutoUseConfig(red).healthThreshold, 35, "cancel does not save threshold")

addon.ShowAutoUseSettings(red)
Equal(addon.AutoUseSettings, panel, "one dialog reused across opens")
panel.health:SetValue(40)
Click(panel.enabled)
Click(panel.combatOnly)
Click(panel.save)
Equal(panel:IsVisible(), false, "save closes settings")
Equal(addon.GetAutoUseConfig(red).enabled, 1, "explicit save enables")
Equal(addon.GetAutoUseConfig(red).healthThreshold, 40, "red saved health threshold")
Equal(addon.GetAutoUseConfig(red).manaThreshold, 0, "red never enables mana condition")
Equal(addon.GetAutoUseConfig(red).combatOnly, 0, "combat-only choice persisted")

addon.ShowAutoUseSettings(blue)
Equal(panel.health.mouseEnabled, false, "blue health slider disabled")
Equal(panel.mana.mouseEnabled, true, "blue mana slider enabled")
panel.health:SetValue(88)
panel.mana:SetValue(27)
Click(panel.enabled)
Click(panel.save)
Equal(addon.GetAutoUseConfig(blue).healthThreshold, 0, "irrelevant blue health input cannot be enabled")
Equal(addon.GetAutoUseConfig(blue).manaThreshold, 27, "blue independent mana threshold")
Equal(addon.GetAutoUseConfig(red).healthThreshold, 40, "blue editing leaves red unchanged")

addon.ShowAutoUseSettings(tea)
Equal(panel.health.mouseEnabled, true, "tea health condition available")
Equal(panel.mana.mouseEnabled, true, "tea mana condition available")
Equal(string.find(panel.hint.text, "任一", 1, true) ~= nil, true, "tea OR condition explained")
panel.health:SetValue(31)
panel.mana:SetValue(22)
Click(panel.enabled)
Click(panel.save)
Equal(addon.GetAutoUseConfig(tea).healthThreshold, 31, "tea health persisted")
Equal(addon.GetAutoUseConfig(tea).manaThreshold, 22, "tea mana persisted")
addon.ShowAutoUseSettings(tea)
panel.health:SetValue(0)
panel.mana:SetValue(0)
Click(panel.save)
Equal(panel:IsVisible(), true, "enabled rule without a condition rejected")
Equal(string.len(panel.message.text) > 0, true, "invalid save has initialized text feedback")
Equal(addon.GetAutoUseConfig(tea).healthThreshold, 31, "invalid save keeps previous configuration")
Click(panel.cancel)

-- Verify modifier/right/left dispatch on actual rows in more than one window.
local db = addon.GetDatabase()
local profile = addon.GetActiveProfile()
profile.weaponSlots = {}
profile.selected = { majorHealing = 1, majorMana = 1, nordanaarTea = 1, mongoose = 1 }
profile.windowVisible = 1
local ui = addon.Windows[db.activeProfileId]
ui.RefreshPotionWindow()
this = ui.layoutDriver
ui.layoutDriver.scripts.OnUpdate()
local redrow, buffrow
for _, row in ipairs(ui.rows) do
    if row.itemData and row.itemData.key == red.key then redrow = row end
    if row.itemData and row.itemData.key == "mongoose" then buffrow = row end
end
assert(redrow and buffrow)
local shift = false
IsShiftKeyDown = function() return shift end
addon.UseItem = function() uses = uses + 1; return true end
GetTime = function() return 10000 end
ui.suppressRowClickUntil = 0
this, arg1 = redrow, "RightButton"
redrow.scripts.OnClick()
Equal(panel:IsVisible(), true, "plain right opens real threshold panel")
Equal(panel.item, red, "right click opens clicked item")
Equal(uses, 0, "right settings never consumes")
panel:Hide()
shift = true
local excluded = profile.macroExcluded[red.key]
redrow.scripts.OnClick()
Equal(panel:IsVisible(), false, "Shift-right does not open threshold panel")
Equal(profile.macroExcluded[red.key], excluded, "manual-only recovery items remain excluded from buff macro")
Equal(uses, 0, "Shift-right cannot consume recovery item")
this, arg1 = buffrow, "RightButton"
local old = addon.IsMacroExcluded(buffrow.itemData, profile)
buffrow.scripts.OnClick()
Equal(addon.IsMacroExcluded(buffrow.itemData, profile), not old, "Shift-right ordinary buff macro unchanged")
shift = false
this, arg1 = redrow, "LeftButton"
redrow.scripts.OnClick()
Equal(uses, 1, "plain left keeps manual use")
shift = true
redrow.scripts.OnClick()
Equal(uses, 1, "Shift-left remains reserved for sorting")

local secondId = addon.CreateProfile("阈值共用")
local second = db.profiles[secondId]
second.selected, second.weaponSlots = { majorHealing = 1 }, {}
addon.SetProfileWindowVisible(secondId, true)
local other = addon.Windows[secondId]
this = other.layoutDriver
other.layoutDriver.scripts.OnUpdate()
shift = false
this, arg1 = other.rows[1], "RightButton"
other.rows[1].scripts.OnClick()
Equal(panel.item.key, red.key, "another window opens same item")
Equal(panel.health:GetValue(), 40, "all windows share character threshold")
Equal(uses, 1, "another window opening still sends no use")
panel:Hide()
print("PASS: " .. checks .. " threshold dialog, strict font, cancel/save and row interaction assertions")
