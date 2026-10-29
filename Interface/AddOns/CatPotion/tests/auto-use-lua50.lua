-- Run from Interface/AddOns with the actual lua50.exe interpreter.
-- No FontStrings or game/account files are constructed or changed.
local now, uses, cooldownUntil, checks = 0, 0, 0, 0
local health, maximumHealth, mana, powerType, combat, moving, lastItem = 20, 100, 100, 0, true, false, nil
local function Check(value, message)
    assert(value, message)
    checks = checks+1
end
local red = { key="majorHealing", itemID=13446, item="red" }
local blue = { key="majorMana", itemID=13444, item="blue" }
local tea = { key="nordanaarTea", itemID=61675, item="tea" }
local stone = { key="majorHealthstone", itemID=9421, item="stone" }
local thistle = { key="thistleTea", itemID=7676, item="thistle" }
local rune = { key="demonicRune", itemID=12662, item="rune" }
local orange = { key="conjuredManaOrange", itemID=83004, item="orange" }
local sleep = { key="dreamlessSleep", itemID=12190, item="sleep" }
CatPotionDB = {}
CatPotionAddon = { ItemsByID={ [13446]=red, [13444]=blue, [61675]=tea } }
local addon = CatPotionAddon
addon.ItemsByID[9421], addon.ItemsByID[7676], addon.ItemsByID[12662] = stone, thistle, rune
addon.ItemsByID[83004], addon.ItemsByID[12190] = orange, sleep
function addon.ToBoolean(value) return value==true or value==1 or value=="1" end
function addon.GetDatabase() return CatPotionDB end
function addon.FindBagItem() return 0, 1, 10 end
function addon.GetCooldownInfo() return math.max(0, cooldownUntil-now), "item", false end
function addon.UseItem(name, item)
    uses = uses+1
    lastItem = item.key
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
function UnitHealth() return health end
function UnitHealthMax() return maximumHealth end
function UnitMana() return mana end
function UnitManaMax() return 100 end
function UnitPowerType() return powerType end
function UnitClass() return "Rogue", "ROGUE" end
function UnitAffectingCombat() return combat end
function PlayerIsMoving() return moving end
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

local function Fresh()
    now, uses, cooldownUntil, lastItem = 0, 0, 0, nil
    health, maximumHealth, mana, powerType, combat, moving = 20, 100, 100, 0, true, false
    CatPotionDB.autoUseItems = {}
    dofile("CatPotion/AutoUse.lua")
end
local function Event(name)
    event, arg1, arg2 = name, "player", nil
    addon.AutoUseDriver.scripts.OnEvent()
end
Fresh()
Check(addon.GetAutoUseDefinition("majorHealthstone").health, "healthstone metadata")
Check(addon.GetAutoUseConfig({ key="majorHealthstone", itemID=19013 })==addon.GetAutoUseConfig(stone), "healthstone alternate config")
addon.SetAutoUseConfig(stone, { enabled=1 })
addon.SetAutoUseConfig(red, { enabled=1 })
now=.21
addon.AutoUseDriver.scripts.OnUpdate()
Check(lastItem=="majorHealthstone", "healthstone native priority")
Fresh()
Check(addon.GetAutoUseConfig(thistle).enabled==0, "new item remains disabled")
Check(addon.GetAutoUseDefinition(thistle).energy, "energy metadata")
addon.SetAutoUseConfig(thistle, { enabled=1 })
health, mana, powerType, now = 100, 20, 3, .21
addon.AutoUseDriver.scripts.OnUpdate()
Check(lastItem=="thistleTea", "native energy rule")
Fresh()
addon.SetAutoUseConfig(rune, { enabled=1, minHealthPercent=50 })
health, maximumHealth, mana, now = 1100, 2000, 10, .21
addon.AutoUseDriver.scripts.OnUpdate()
Check(uses==0, "native rune absolute floor")
health, now = 1101, .5
Event("UNIT_HEALTH")
now=.8
addon.AutoUseDriver.scripts.OnUpdate()
Check(lastItem=="demonicRune", "native rune dual health guard")
Fresh()
addon.SetAutoUseConfig(orange, { enabled=1, combatOnly=1 })
Check(addon.GetAutoUseConfig(orange).combatOnly==0, "native orange forces outside-combat config")
now=.21
addon.AutoUseDriver.scripts.OnUpdate()
Check(uses==0, "native orange cannot start in combat")
combat=false
Event("PLAYER_REGEN_ENABLED")
now=.5
addon.AutoUseDriver.scripts.OnUpdate()
Check(lastItem=="conjuredManaOrange", "native orange outside combat")
Fresh()
addon.SetAutoUseConfig(sleep, { enabled=1 })
moving, now=true,.21
addon.AutoUseDriver.scripts.OnUpdate()
Check(uses==0, "native rest movement guard")
moving, now=false,1
addon.AutoUseDriver.scripts.OnUpdate()
Check(lastItem=="dreamlessSleep", "native rest resumes stationary")
print("PASS: " .. checks .. " native " .. tostring(_VERSION) .. " auto-use compatibility assertions")
