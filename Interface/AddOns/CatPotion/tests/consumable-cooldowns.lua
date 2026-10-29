-- Run from Interface/AddOns. Reuse the existing WoW 1.12 UI mock.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local now, assertions = 1000, 0
local bag, cooldowns, calls, targetCalls = {}, {}, {}, {}
GetTime = function() return now end
GetContainerNumSlots = function(index) return index == 0 and 30 or 0 end
GetContainerItemLink = function(index, slot)
    local entry = index == 0 and bag[slot]
    if entry then return "|Hitem:" .. entry.id .. ":0:0:0|h[" .. (entry.name or "localized alias") .. "]|h" end
end
GetContainerItemInfo = function(index, slot)
    local entry = bag[slot]
    return entry and "icon", entry and entry.count, entry and entry.locked
end
GetContainerItemCooldown = function(index, slot)
    local entry = bag[slot]
    local cd = entry and cooldowns[entry.id]
    if cd then return cd[1], cd[2], cd[3] end
    return 0, 0, 1
end
UseContainerItem = function(index, slot) calls[#calls + 1] = bag[slot].id end
UnitAffectingCombat = function() return false end
UnitExists = function() return true, "old-guid" end
UnitIsUnit = function() return false end
TargetUnit = function(unit) targetCalls[#targetCalls + 1] = unit end
SpellIsTargeting = function() return false end
addon.PlayerIsEating = function() return false end
addon.GetBuffTime = function() return 0 end
local function Equal(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    assertions = assertions + 1
end
local function Event(name)
    event = name
    addon.WindowEvents.scripts.OnEvent()
end
local function Reset()
    now = now + 2000
    bag, cooldowns, calls, targetCalls = {}, {}, {}, {}
    addon.CancelPendingItemUses()
    addon.MarkBagCacheDirty()
end
local function Put(slot, id, count)
    bag[slot] = { id = id, count = count or 1 }
    addon.MarkBagCacheDirty()
end
local function Item(key)
    for _, item in ipairs(addon.Items) do if item.key == key then return item end end
end
local potion, oil, quickness = Item("majorHealing"), Item("immolationOil"), Item("quickness")
local sapper, grenade, tea = Item("sapperCharge"), Item("thoriumGrenade"), Item("nordanaarTea")
local rune, juju, sleep = Item("darkRune"), Item("jujuFlurry"), Item("dreamlessSleep")
local profile = addon.GetDatabase().profiles[addon.GetDatabase().defaultProfileId]
local newCount, keys = 0, {}
for _, item in ipairs(addon.Items) do
    assert(not keys[item.key], "unique key: " .. item.key)
    keys[item.key] = true
    if item.defaultMacroExcluded then
        newCount = newCount + 1
        assert(item.itemID and addon.GetItemTexture(item), "new item identity and static texture")
        assert(not item.requiresEquipped, "engineering equipment excluded")
    end
end
Equal(newCount, 59, "catalogue count including capital wormholes, orange and sand")
Equal(Item("battleChicken"), nil, "equipped engineering trinket removed")
Equal(Item("gnomishRocketBoots"), nil, "rocket boots removed")
Equal(quickness.itemID, 61181, "Turtle haste potion, not TBC haste potion")
Equal(tea.itemID, 61675, "Turtle herbal tea ID")
Equal(addon.GetItemTexture(Item("limitedInvulnerability")), "Interface\\Icons\\INV_Potion_121", "current Turtle invulnerability texture")

local orange, sand = Item("conjuredManaOrange"), Item("hourglassSand")
Equal(orange.itemID, 83004, "conjured orange ID")
Equal(sand.itemID, 19183, "bronze affliction sand ID")
Equal(addon.GetItemTexture(orange), "Interface\\Icons\\INV_Misc_Food_41", "orange client texture")
Equal(addon.GetItemTexture(sand), "Interface\\Icons\\INV_Misc_Dust_14", "sand client texture")
Equal(orange.categoryCooldown, 1, "item food cooldown overrides spell default")
Equal(orange.gcd, 0, "orange has no spell GCD")
Equal(sand.cooldown, 0, "sand has no personal cooldown")
Equal(sand.gcd, 0, "sand has no spell GCD")
assert(addon.IsMacroExcluded(orange, profile) and addon.IsMacroExcluded(sand, profile), "orange and sand remain manual-only")
Reset()
Put(1, orange.itemID, 2)
Put(2, sand.itemID, 2)
UnitAffectingCombat = function() return true end
Equal(addon.UseItem(orange.item, orange), false, "cannot eat orange in combat")
Equal(#calls, 0, "blocked food does not send a use request")
Equal(addon.UseItem(sand.item, sand), true, "sand usable in combat")
bag[2].count = 1
Event("BAG_UPDATE")
Equal(addon.GetCooldownRemaining(sand.item), 0, "confirmed sand use invents no cooldown")
UnitAffectingCombat = function() return false end
Equal(addon.UseItem(orange.item, orange), true, "orange usable outside combat")
bag[1].count = 1
Event("BAG_UPDATE")
Equal(addon.GetCooldownRemaining(orange.item), 1, "confirmed food use tracks one second category cooldown")
Equal(addon.GetCooldownRemaining(potion.item), 0, "food does not trigger potion shared cooldown")
now = now + 1.1
Equal(addon.GetCooldownRemaining(orange.item), 0, "short food cooldown expires")

Reset()
Put(1, potion.itemID, 2)
Put(2, potion.itemID, 3)
local b, s, count = addon.FindBagItem(potion.item)
Equal(count, 5, "ID matching and multi-stack count")
cooldowns[potion.itemID] = { now, 120, 1 }
Equal(addon.GetCooldownRemaining(potion.item), 120, "native potion cooldown")
Equal(addon.GetCooldownRemaining(quickness.item), 120, "shared potion cooldown without bag item")
Equal(addon.UseItem(potion.item, potion), false, "cooldown blocks click")
now = now + 119.9
assert(addon.GetCooldownRemaining(potion.item) > 0, "last fraction of cooldown not skipped")
Equal(addon.UseItem(potion.item, potion), false, "last fraction blocks use")
now = now + 0.2
Equal(addon.GetCooldownRemaining(potion.item), 0, "expired cooldown")

Reset()
Put(1, oil.itemID)
cooldowns[oil.itemID] = { now, 3, 1 }
Equal(addon.GetCooldownRemaining(oil.item), 3, "three second elixir category cooldown")
Equal(addon.GetCooldownRemaining(potion.item), 0, "oil independent from potion category")
now = now + 2.5
Equal(addon.UseItem(oil.item, oil), false, "last half second still blocked")

Reset()
Put(1, potion.itemID)
GetSpellName = function(index) if index == 1 then return "火球术" end end
GetSpellCooldown = function() return now, 1.5, 1 end
addon.MarkSpellCacheDirty()
cooldowns[potion.itemID] = { now, 1.5, 1 }
Equal(addon.GetCooldownRemaining(potion.item), 0, "off-GCD potion ignores verified spell GCD")
GetSpellCooldown = function() return 0, 0, 1 end
cooldowns[potion.itemID] = { now, 1, 1 }
Equal(addon.GetCooldownRemaining(potion.item), 1, "real short item cooldown retained")

Reset()
Put(1, sleep.itemID)
cooldowns[sleep.itemID] = { now, 1.5, 1 }
local remaining, kind = addon.GetCooldownInfo(sleep.item)
Equal(remaining, 1.5, "GCD duration read from client")
Equal(kind, "gcd", "GCD distinguished from item cooldown")
Equal(addon.UseItem(sleep.item, sleep), false, "GCD blocks applicable item")

Reset()
Put(1, sapper.itemID)
cooldowns[sapper.itemID] = { now, 300, 1 }
Equal(addon.GetCooldownRemaining(sapper.item), 300, "sapper personal five minute cooldown")
Equal(addon.GetCooldownRemaining(grenade.item), 60, "sapper shares one minute, not five")
now = now + 61
Equal(addon.GetCooldownRemaining(grenade.item), 0, "grenade ready before sapper")
Equal(addon.GetCooldownRemaining(sapper.item), 239, "sapper remains on personal cooldown")

Reset()
Put(1, tea.itemID)
cooldowns[tea.itemID] = { now, 120, 1 }
Equal(addon.GetCooldownRemaining(tea.item), 120, "tea effective cooldown")
Equal(addon.GetCooldownRemaining(rune.item), 120, "tea and rune category shared")
Equal(addon.GetCooldownRemaining(potion.item), 0, "tea separate from potion category")

Reset()
Put(1, sapper.itemID)
Equal(addon.UseItem(sapper.item, sapper), true, "request accepted")
Equal(addon.GetCooldownRemaining(sapper.item), 0, "request alone does not invent cooldown")
bag[1] = nil
Event("BAG_UPDATE")
Equal(addon.GetCooldownRemaining(sapper.item), 300, "last charge consumption preserves personal cooldown")
Equal(addon.GetCooldownRemaining(grenade.item), 60, "last charge consumption preserves shared cooldown")

Reset()
Put(1, potion.itemID)
Equal(addon.UseItem(potion.item, potion), true, "failed request issued")
Event("UI_ERROR_MESSAGE")
bag[1] = nil
Event("BAG_UPDATE")
Equal(addon.GetCooldownRemaining(potion.item), 0, "failed request does not start phantom cooldown")

Reset()
Put(1, juju.itemID, 5)
Equal(addon.UseItem(juju.item, juju), true, "Juju click issued")
Equal(targetCalls[1], "player", "Juju self-target")
Equal(targetCalls[2], "old-guid", "previous target restored")

Reset()
Put(1, potion.itemID)
cooldowns[potion.itemID] = { 0, 0, 0 }
Equal(addon.UseItem(potion.item, potion), false, "disabled item blocked even without duration")

Reset()
Put(1, potion.itemID)
Put(2, sapper.itemID)
Put(3, quickness.itemID)
profile.selected = { majorHealing = 1, sapperCharge = 1, quickness = 1 }
profile.weaponSlots, profile.macroExcluded = {}, {}
Equal(addon.UseNextSelectedPotion(profile.id), false, "new items default to manual display")
profile.macroExcluded.quickness = 0
Equal(addon.UseNextSelectedPotion(), true, "explicit opt-in uses short buff")
Equal(calls[1], quickness.itemID, "restoration and bomb not auto-consumed")
now = now + 1
addon.GetBuffTime = function(name) return name == quickness.buff and 20 or 0 end
Equal(addon.UseNextSelectedPotion(), false, "short buff not renewed inside four minute warning")

-- Exercise the real settings and row callbacks, including default macro flags.
local madeFrames = {}
local previousCreateFrame = CreateFrame
CreateFrame = function(...)
    local frame = previousCreateFrame(unpack(arg))
    function frame:GetThumbTexture() return self:CreateTexture() end
    function frame:GetFrameLevel() return 1 end
    function frame:GetMinMaxValues() return 0, 1000 end
    function frame:GetValue() return 0 end
    madeFrames[#madeFrames + 1] = frame
    return frame
end
profile.selected, profile.macroExcluded = {}, {}
dofile("CatPotion/Settings.lua")
addon.ShowSettings()
local checkCount, quicknessCheck = 0, nil
for _, frame in ipairs(madeFrames) do
    if rawget(frame, "itemKey") and Item(frame.itemKey).defaultMacroExcluded then
        checkCount = checkCount + 1
        if frame.itemKey == "quickness" then quicknessCheck = frame end
    end
end
Equal(checkCount, 57, "all faction-independent new items present in settings")
this = quicknessCheck
this.scripts.OnClick()
Equal(profile.selected.quickness, 1, "settings checkbox enables display")
Equal(profile.macroExcluded.quickness, 1, "settings selection keeps short buff out of macro")
this = quicknessCheck
this.scripts.OnClick()
this.scripts.OnClick()
Equal(profile.macroExcluded.quickness, 1, "reselect restores safe default")
addon.RefreshPotionRows()
local rows = addon.Windows[addon.GetDatabase().defaultProfileId].rows
local quickRow
for _, row in ipairs(rows) do if row.itemData and row.itemData.key == "quickness" then quickRow = row end end
IsShiftKeyDown = function() return true end
this, arg1 = quickRow, "RightButton"
this.scripts.OnClick()
Equal(profile.macroExcluded.quickness, 0, "row Shift-right click opts buff into macro")
Equal(#calls, 1, "right click never uses an item")
profile.selected.majorHealing = 1
addon.RefreshPotionRows()
local healRow
for _, row in ipairs(rows) do if row.itemData and row.itemData.key == "majorHealing" then healRow = row end end
IsShiftKeyDown = function() return false end
this, arg1 = healRow, "RightButton"
this.scripts.OnClick()
assert(addon.IsMacroExcluded(potion, profile), "restoration row stays manual-only")
print("PASS: " .. assertions .. " consumable catalogue, native/shared/GCD, last-charge and macro assertions")
