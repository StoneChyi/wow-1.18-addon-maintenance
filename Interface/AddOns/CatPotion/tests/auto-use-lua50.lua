-- Run from Interface/AddOns with the actual lua50.exe interpreter.
-- No FontStrings or game/account files are constructed or changed.
local now, uses, cooldownUntil, checks = 0, 0, 0, 0
local function Check(value, message)
    assert(value, message)
    checks = checks+1
end
local red = { key="majorHealing", itemID=13446, item="red" }
local blue = { key="majorMana", itemID=13444, item="blue" }
local tea = { key="nordanaarTea", itemID=61675, item="tea" }
CatPotionDB = {}
CatPotionAddon = { ItemsByID={ [13446]=red, [13444]=blue, [61675]=tea } }
local addon = CatPotionAddon
function addon.ToBoolean(value) return value==true or value==1 or value=="1" end
function addon.GetDatabase() return CatPotionDB end
function addon.FindBagItem() return 0, 1, 10 end
function addon.GetCooldownInfo() return math.max(0, cooldownUntil-now), "item", false end
function addon.UseItem(name, item)
    uses = uses+1
    addon.NotifyAutoUseManual(item, 10)
    return true
end
function CreateFrame()
    local frame = { scripts={}, visible=true }
    function frame:SetScript(name, func) self.scripts[name]=func end
    function frame:RegisterEvent() end
    function frame:Hide() self.visible=false end
    function frame:Show() self.visible=true end
    function frame:IsVisible() return self.visible end
    return frame
end
function GetTime() return now end
function UnitHealth() return 20 end
function UnitHealthMax() return 100 end
function UnitMana() return 100 end
function UnitManaMax() return 100 end
function UnitPowerType() return 0 end
function UnitAffectingCombat() return true end
function UnitIsDeadOrGhost() return false end
function SpellIsTargeting() return false end
function GetContainerItemInfo() return "icon", 10, false end

-- Also reproduces stock Lua 5.0's missing math.huge when run in another runtime.
math.huge = nil
dofile("CatPotion/AutoUse.lua")
Check(not addon.AutoUseDriver:IsVisible(), "default-off engine must sleep")
Check(addon.GetAutoUseConfig(red).enabled==0, "default disabled")
Check(addon.SetAutoUseConfig(red, { healthThreshold=41 }), "normal numeric setter")
Check(addon.GetAutoUseConfig(red).healthThreshold==41, "normal number normalized")
addon.SetAutoUseConfig(red, { healthThreshold=0/0 })
Check(addon.GetAutoUseConfig(red).healthThreshold==35, "NaN fallback")
addon.SetAutoUseConfig(red, { healthThreshold=1/0 })
Check(addon.GetAutoUseConfig(red).healthThreshold==35, "positive infinity fallback")
addon.SetAutoUseConfig(red, { healthThreshold=-1/0 })
Check(addon.GetAutoUseConfig(red).healthThreshold==35, "negative infinity fallback")
addon.SetAutoUseConfig(red, { enabled=1, healthThreshold=35 })
Check(addon.AutoUseDriver:IsVisible(), "enable wakes driver")
now=.21
addon.AutoUseDriver.scripts.OnUpdate()
Check(uses==1, "low-health request once")
Check(addon.GetAutoUseStatus(red)=="pending", "true is pending, not success")
now=.42
cooldownUntil=5
addon.AutoUseDriver.scripts.OnUpdate()
Check(addon.GetAutoUseStatus(red)=="cooldown", "real cooldown confirms")
Check(uses==1, "manual notification did not recurse")
now=6
addon.AutoUseDriver.scripts.OnUpdate()
Check(uses==2, "cooldown expiry rearms still-low health")
print("PASS: " .. checks .. " native " .. tostring(_VERSION) .. " auto-use compatibility assertions")
