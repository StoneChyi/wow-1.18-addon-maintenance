-- Reuse the UI/API mocks and verify the real UseItem targeting path.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local now = 1000
GetTime = function() return now end
addon.PlayerIsEating = function() return false end
addon.RequestPotionUseRefresh = function() end
local database = addon.GetDatabase()
local profile = database.profiles[database.defaultProfileId]
profile.selected = {}
profile.weaponSlots = { elementalStone = { main = 1, off = 1 } }
local applied, calls, inventory = {}, {}, { [16] = true, [17] = true }
addon.FindBagItem = function() return 0, 1, 10 end
GetContainerItemInfo = function() return "icon", 10, false end
addon.GetCooldownRemaining = function() return 0 end
GetInventoryItemLink = function(_, slot) return inventory[slot] end
addon.GetWeaponEnchantTime = function(_, slot) return applied[slot] or 0 end
UseContainerItem = function() calls[#calls + 1] = "use" end
PickupInventoryItem = function(slot)
    calls[#calls + 1] = slot
    applied[slot] = 1800
end
ClearCursor = function() calls[#calls + 1] = "clear" end
local function Press()
    now = now + 2
    calls = {}
    return CatPotionUseCommand("")
end
assert(Press() and #calls == 3 and calls[2] == 16, "macro applies main hand")
assert(not CatPotionUseCommand("") and #calls == 3, "throttle prevents duplicate use")
assert(Press() and #calls == 3 and calls[2] == 17, "next press applies off hand")
assert(not Press() and #calls == 0, "healthy enchants skipped")
applied[17] = 30
assert(Press() and calls[2] == 17, "expiring offhand renewed")
applied = {}
inventory[16] = nil
assert(Press() and calls[2] == 17, "empty main hand skipped")
profile.weaponSlots.elementalStone = { main = 0, off = 0 }
assert(not Press() and #calls == 0, "disabled slots skipped")
profile.weaponSlots.elementalStone = { off = 1 }
applied = {}
UnitCastingInfo = function() return "applying stone" end
assert(not Press() and #calls == 0, "casting protected")
UnitCastingInfo = nil
addon.PlayerIsEating = function() return true end
assert(not Press() and #calls == 0, "eating protected")
addon.PlayerIsEating = function() return false end
addon.GetCooldownRemaining = function() return 20 end
assert(not Press() and #calls == 0, "cooldown skipped")
addon.GetCooldownRemaining = function() return 0 end
addon.FindBagItem = function() return nil end
assert(not Press() and #calls == 0, "missing stone skipped")
addon.FindBagItem = function() return 0, 1, 10 end
-- Bare command must not take weapon selections from the active profile.
local otherId = addon.CreateProfile("Weapon macro test")
local other = database.profiles[otherId]
other.selected = {}
other.weaponSlots = {}
assert(Press() and calls[2] == 17, "bare command uses default profile")
applied = {}
now = now + 2
calls = {}
assert(not CatPotionUseCommand("Weapon macro test") and #calls == 0, "named profile isolated")
print("PASS: weapon macro targeting, renewal, guards and profile isolation")
