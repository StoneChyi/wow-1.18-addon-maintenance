-- Reuse the WoW mocks and existing regression suite.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
CatPotionDB = {
    scale = 1.2, layout = "vertical", layoutLimit = 4,
    locked = 1, showMessages = 0, warningMinutes = 7,
    profiles = { [1] = { name = "默认配置" }, [2] = { name = "另一配置" } },
    profileOrder = { 1, 2 }, activeProfileId = 1, defaultProfileId = 1
}
local database = addon.GetDatabase()
assert(database.profiles[1].scale == 1.2 and database.profiles[2].scale == 1.2)
assert(database.profiles[1].layout == "vertical" and database.profiles[2].layoutLimit == 4)
local first = addon.GetActiveProfile()
assert(first.locked == 1 and first.showMessages == 0 and first.warningMinutes == 7)
first.locked, first.showMessages, first.warningMinutes = 0, 1, 2
first.scale, first.layout, first.layoutLimit = 0.6, "horizontal", 3
assert(addon.SelectProfile(2))
local second = addon.GetActiveProfile()
assert(second.locked == 1 and second.showMessages == 0 and second.warningMinutes == 7)
assert(second.scale == 1.2 and second.layout == "vertical" and second.layoutLimit == 4)
second.scale, second.layoutLimit = 1.4, 7
assert(addon.SelectProfileByName("默认配置"))
assert(addon.GetActiveProfile().scale == 0.6 and addon.GetActiveProfile().layoutLimit == 3)
assert(addon.GetActiveProfile().locked == 0 and addon.GetActiveProfile().showMessages == 1 and addon.GetActiveProfile().warningMinutes == 2)
-- Normalizing saved data again must not overwrite per-profile values with legacy globals.
database = addon.GetDatabase()
assert(database.profiles[2].scale == 1.4 and database.profiles[2].layoutLimit == 7)
local createdId = addon.CreateProfile("新配置")
local created = addon.GetActiveProfile()
assert(created.locked == 0 and created.showMessages == 1 and created.warningMinutes == 4)
assert(created.scale == 0.8 and created.layout == "horizontal" and created.layoutLimit == 2)
assert(addon.DeleteProfile(createdId))
assert(addon.GetActiveProfile().scale == 1.4)
print("PASS: profile appearance migration, independence, selection and defaults")
