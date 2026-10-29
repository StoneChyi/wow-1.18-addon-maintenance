-- Run from the workspace root with a Lua interpreter:
--   fengari CatPotion/tests/weapon-charges.lua
-- Minimal WoW API mocks; no game files or SavedVariables are modified.
table.getn = table.getn or function(value) return #value end
local now, scans = 100, 0
local equipped = {}
local frames = {}
local function noop() end
local methods = {}
local function NewFrame(kind, name, parent)
    local frame = { kind = kind or "Frame", name = name, parent = parent, scripts = {}, visible = true, width = 100, height = 100, scale = 1 }
    setmetatable(frame, { __index = function(_, key) if key == "font" then return nil end; return methods[key] or noop end })
    function frame:SetScript(name, callback) self.scripts[name] = callback end
    function frame:CreateTexture() return NewFrame() end
    function frame:SetTextColor(red, green, blue) self.textColor = { red, green, blue } end
    function frame:SetText(value) methods.SetText(self, value); self.text = value end
    function frame:GetText() return self.text end
    function frame:SetWidth(value) self.width = value end
    function frame:SetHeight(value) self.height = value end
    function frame:GetWidth() return self.width end
    function frame:GetHeight() return self.height end
    function frame:SetScale(value) self.scale = value end
    function frame:GetScale() return self.scale end
    function frame:SetPoint(...) self.point = { ... } end
    function frame:Show() self.visible = true end
    function frame:Hide() self.visible = false end
    function frame:IsVisible() return self.visible end
    function frame:NumLines() return 2 end
    function frame:SetInventoryItem(unit, slot)
        local first, second = NewFrame(), NewFrame()
        first:SetText("Test weapon")
        second:SetText(equipped[slot] and equipped[slot].text)
        _G.CatPotionWeaponTooltipTextLeft1 = first
        _G.CatPotionWeaponTooltipTextLeft2 = second
    end
    frames[#frames + 1] = frame
    return frame
end
dofile("../../Tools/tests/wow112_fontstring_mock.lua")(methods, NewFrame)
function CreateFrame(kind, name, parent)
    local frame = NewFrame(kind, name, parent)
    if name then _G[name] = frame end
    return frame
end
STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
UIParent = NewFrame()
GameTooltip = NewFrame()
SlashCmdList = {}
DEFAULT_CHAT_FRAME = NewFrame()
UIDropDownMenu_Initialize = noop
UIDropDownMenu_SetWidth = noop
getglobal = function(name) return _G[name] end
GetTime = function() return now end
GetContainerNumSlots = function() return 0 end
GetPlayerBuffTexture = function() return nil end
GetInventoryItemLink = function() return "test weapon link" end
GetWeaponEnchantInfo = function()
    scans = scans + 1
    local main, off = equipped[16], equipped[17]
    return main ~= nil, main and main.time, main and main.charges,
        off ~= nil, off and off.time, off and off.charges
end

dofile("CatPotion/Core.lua")
local addon = CatPotionAddon
local assertions = 0
local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end
local function Refresh()
    addon.MarkWeaponEnchantCacheDirty()
end
equipped[16] = { text = "速效毒药 VI（30分钟）（120次）", time = 1800000, charges = 999 }
equipped[17] = { text = "溶解毒药 II（30分钟）（37 次）", time = 1800000, charges = 998 }
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), 120, "tooltip priority")
Equal(addon.GetWeaponEnchantCharges("溶解毒药 II", 17), 37, "offhand and optional whitespace")
Equal(scans, 1, "one shared scan for both hands")
Equal(addon.GetWeaponEnchantCharges("溶解毒药 II", 16), nil, "wrong poison")
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 17), nil, "wrong hand")
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 18), nil, "unsupported slot")
equipped[16].text = "速效毒药 VI（30分钟）"
equipped[16].charges = 75
Refresh()
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), 75, "API fallback")
equipped[16].charges = 0
Refresh()
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), nil, "unknown API zero")
equipped[16].charges = nil
Refresh()
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), nil, "missing count")
equipped[16].text = "速效毒药 VI（30分钟）（0次）"
Refresh()
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), 0, "explicit tooltip zero")
equipped[16].text = "速效毒药 VI（1秒）（3次）"
equipped[16].time = 1000
Refresh()
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), 3, "before expiration")
now = now + 2
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), nil, "expired count cleared")
equipped[16] = nil
Refresh()
Equal(addon.GetWeaponEnchantCharges("速效毒药 VI", 16), nil, "removed enchant")
equipped[16] = { text = "致命毒药 IV（30分钟）（44次）", time = 1800000 }
Refresh()
Equal(addon.GetWeaponEnchantCharges("致命毒药 IV", 16), 44, "deadly poison IV exact match")
Equal(addon.GetWeaponEnchantCharges("致命毒药 V", 16), nil, "deadly poison IV does not match V")
equipped[16] = { text = "致命毒药 V（30分钟）（55次）", time = 1800000 }
Refresh()
Equal(addon.GetWeaponEnchantCharges("致命毒药 V", 16), 55, "deadly poison V exact match")
Equal(addon.GetWeaponEnchantCharges("致命毒药 IV", 16), nil, "deadly poison V does not match IV")

-- Verify row display and polling without UNIT_INVENTORY_CHANGED events.
equipped[16] = { text = "腐蚀毒药 II（30分钟）（60次）", time = 1800000 }
Refresh()
Equal(addon.GetWeaponEnchantCharges("腐蚀毒药 II", 16), 60, "corrosive poison II match")
Equal(addon.GetWeaponEnchantTime("腐蚀毒药", 16), 0, "corrosive poison II does not match unranked")
equipped[16] = { text = "腐蚀毒药（30分钟）（40次）", time = 1800000 }
Refresh()
Equal(addon.GetWeaponEnchantCharges("腐蚀毒药", 16), 40, "unranked corrosive poison match")
Equal(addon.GetWeaponEnchantTime("腐蚀毒药 II", 16), 0, "unranked corrosive poison does not match II")

equipped[16] = { text = "速效毒药 VI（30分钟）（90次）", time = 1800000 }
dofile("CatPotion/Window.lua")
local testWindow = addon.Windows[addon.GetDatabase().activeProfileId].window
local profile = addon.GetActiveProfile()
profile.weaponSlots = { instantPoison6 = { main = 1, off = 1 }, dissolvePoison2 = { off = 1 } }
profile.selected = { mongoose = 1 }
addon.RefreshPotionRows()
local mainRow, wrongHandRow, offRow, normalRow
for _, frame in ipairs(frames) do
    local item = rawget(frame, "itemData")
    if item then
        if item.key == "instantPoison6" and frame.weaponSlot == 16 then mainRow = frame end
        if item.key == "instantPoison6" and frame.weaponSlot == 17 then wrongHandRow = frame end
        if item.key == "dissolvePoison2" then offRow = frame end
        if item.key == "mongoose" then normalRow = frame end
    end
end
Equal(mainRow.chargeText.text, "90", "main row count")
Equal(offRow.chargeText.text, "37", "off row count")
Equal(wrongHandRow.chargeText.text, "", "mismatched row blank")
Equal(normalRow.chargeText.text, "", "ordinary item blank")
Equal(mainRow.chargeText.point[1], "TOPLEFT", "count anchor")
Equal(mainRow.countText.point[1], "BOTTOMRIGHT", "bag count anchor unchanged")
equipped[16].text = "速效毒药 VI（30分钟）（89次）"
testWindow:Show()
arg1 = 1.01
addon.RefreshDriver.scripts.OnUpdate()
Equal(mainRow.chargeText.text, "89", "poll detects consumption without event")
testWindow:Hide()
local scansBeforeHide = scans
addon.RefreshDriver.scripts.OnUpdate()
Equal(scans, scansBeforeHide, "hidden window does not poll")
equipped[16].text = "速效毒药 VI（30分钟）（80次）"
addon.RefreshPotionRows()
Equal(mainRow.chargeText.text, "80", "reopen refreshes immediately")
testWindow:Show()
local function CheckChargeColor(count, red, green, blue)
    equipped[16].text = "速效毒药 VI（30分钟）（" .. count .. "次）"
    addon.RefreshDriver.scripts.OnUpdate()
    Equal(mainRow.chargeText.text, tostring(count), "threshold count " .. count)
    Equal(mainRow.chargeText.textColor[1], red, "red channel at " .. count)
    Equal(mainRow.chargeText.textColor[2], green, "green channel at " .. count)
    Equal(mainRow.chargeText.textColor[3], blue, "blue channel at " .. count)
end
CheckChargeColor(20, 1, 0.82, 0.2)
CheckChargeColor(19, 1, 0.3, 0.3)
Equal(offRow.chargeText.textColor[2], 0.82, "offhand color stays independent")
CheckChargeColor(0, 1, 0.3, 0.3)
CheckChargeColor(100, 1, 0.82, 0.2)
equipped[16] = nil
testWindow:Show()
addon.RefreshDriver.scripts.OnUpdate()
Equal(mainRow.chargeText.text, "", "removed poison clears row")
Equal(mainRow.chargeText.textColor[2], 0.82, "removed poison resets warning color")
-- Same-name food renewal can update the API without an aura event.
local foodRemaining, eatingRemaining, auraScans = 60, 20, 0
GetPlayerBuffTexture = function(index)
    if index == 0 then auraScans = auraScans + 1; return "food" end
    if index == 1 and eatingRemaining > 0 then return "eating" end
end
GetPlayerBuffTimeLeft = function(index)
    return index == 0 and foodRemaining or eatingRemaining
end
function CatPotionAuraTooltip:SetPlayerBuff(index)
    local line = NewFrame()
    line:SetText(index == 0 and "进食充分" or "正在进食中")
    _G.CatPotionAuraTooltipTextLeft1 = line
end
addon.MarkAuraCacheDirty()
local function TickFood()
    now = now + 1
    arg1 = 1
    addon.RefreshDriver.scripts.OnUpdate()
end
TickFood()
foodRemaining = 900
TickFood()
Equal(addon.GetBuffTime("进食充分"), 900, "food renewal without event")
local scansWhileEating = auraScans
TickFood()
Equal(auraScans, scansWhileEating + 1, "poll once per second while eating")
eatingRemaining = 0
TickFood()
local scansAtStop = auraScans
foodRemaining = 1200
TickFood()
Equal(addon.GetBuffTime("进食充分"), 1200, "delayed food renewal after eating")
TickFood()
Equal(auraScans, scansAtStop + 2, "two followup scans after eating")
TickFood()
TickFood()
Equal(auraScans, scansAtStop + 2, "polling stops after followups")
Equal(addon.GetBuffTime("进食充分"), 1198, "normal cached countdown resumes")
print("PASS: " .. assertions .. " weapon charge and food refresh assertions")
