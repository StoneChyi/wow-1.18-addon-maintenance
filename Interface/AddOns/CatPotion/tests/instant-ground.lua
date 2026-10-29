-- Run from Interface/AddOns with Lua 5.1; exercise the actual Core and row handlers.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local water = addon.ItemsByName["斯坦索姆圣水"]
local checks, requests, casts, targeting = 0, 0, 0, false
local settings, warnings, calls = {}, {}, {}
local fault, castResult, makeCircle, locked, cooldown, unavailable
local originalUse = addon.UseItem

local function Equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks + 1
end

local function Reset()
    requests, casts, targeting = 0, 0, false
    settings = { NP_QuickcastTargetingSpells = "1", NP_QueueTargetingSpells = "1" }
    warnings, calls = {}, {}
    fault, castResult, makeCircle, locked, cooldown, unavailable = nil, nil, true, false, 0, false
    addon.CancelPendingItemUses()
    UnitXP = function(command, argument)
        if command == "version" then
            if fault == "version" then error("no version") end
            return 1784609206
        elseif command == "isGroundTargetPending" then
            if fault == "pending" then error("unsupported probe") end
            return targeting
        elseif command == "castAOE" then
            Equal(argument, "player", "cast only at player")
            Equal(settings.NP_QuickcastTargetingSpells, "0", "quickcast remains disabled through placement")
            Equal(settings.NP_QueueTargetingSpells, "0", "target queue remains disabled through placement")
            casts = casts + 1
            if fault == "cast" then error("cast failed") end
            if castResult ~= false and fault ~= "uncleared" then targeting = false end
            return castResult
        end
        error("unknown UnitXP command")
    end
end

GetTime = function() return 2000 end
GetContainerItemInfo = function() return "icon", 10, locked end
addon.FindBagItem = function() return 0, 1, 10 end
addon.GetCooldownRemaining = function() return cooldown end
addon.GetCooldownInfo = function() return cooldown, "item", unavailable end
addon.RequestPotionUseRefresh = function() end
addon.Print = function(message, forced, profileId)
    table.insert(warnings, { message = message, forced = forced, profileId = profileId })
end
SpellIsTargeting = function() return targeting end
GetCVar = function(name)
    if settings[name] == nil then error("unknown CVar") end
    return settings[name]
end
SetCVar = function(name, value)
    table.insert(calls, { name, value })
    if fault == "set" and name == "NP_QueueTargetingSpells" and value == "0" then error("set failed") end
    if fault == "silent" and value == "0" then return end
    if fault == "restore" and value == "1" then error("restore failed") end
    settings[name] = value
end
UseContainerItem = function(bag, slot)
    Equal(bag, 0, "uses the located bag")
    Equal(slot, 1, "uses the located slot")
    requests = requests + 1
    if fault == "use" then error("request failed") end
    Equal(settings.NP_QuickcastTargetingSpells, "0", "left/right never quickcast at mouse")
    Equal(settings.NP_QueueTargetingSpells, "0", "left/right never enqueue later ground targeting")
    targeting = makeCircle
end

Reset()
Equal(addon.IsInstantGroundItem(water), true, "holy water is whitelisted")
Equal(addon.IsInstantGroundItem(addon.ItemsByName["致密炸弹"]), false, "cast-time dynamite excluded")
Equal(addon.IsInstantGroundItem(addon.ItemsByName["地精工兵炸药"]), false, "sapper is not a ground item")
Equal(addon.UseItem(water.item, water), true, "left manual request")
Equal(requests, 1, "manual request sent once")
Equal(casts, 0, "left never calls UnitXP placement")
Equal(targeting, true, "left preserves manual targeting circle")
Equal(settings.NP_QuickcastTargetingSpells, "1", "left restores quickcast preference")
Equal(settings.NP_QueueTargetingSpells, "1", "left restores queue preference")

Reset()
Equal(addon.UseItem(water.item, water, nil, "owner", "player"), true, "right self request")
Equal(requests, 1, "right requests once")
Equal(casts, 1, "right places once")
Equal(targeting, false, "right consumes the current circle")
Equal(settings.NP_QuickcastTargetingSpells, "1", "right restores quickcast")
Equal(settings.NP_QueueTargetingSpells, "1", "right restores queue")
Equal(warnings[table.getn(warnings)].profileId, "owner", "request message keeps profile owner")

for _, problem in ipairs({ "missing", "version", "old", "badVersion" }) do
    Reset()
    if problem == "missing" then UnitXP = nil
    elseif problem == "version" then fault = "version"
    elseif problem == "old" then UnitXP = function() return 1782863999 end
    else UnitXP = function() return "1784609206" end end
    Equal(addon.UseItem(water.item, water, nil, nil, "player"), false, problem .. " rejects right before request")
    Equal(requests, 0, problem .. " does not consume water")
    Equal(casts, 0, problem .. " does not cast")
    Equal(addon.UseItem(water.item, water), true, problem .. " retains manual left click")
end

Reset()
targeting = true
Equal(addon.UseItem(water.item, water, nil, nil, "player"), false, "preexisting targeting rejected")
Equal(requests, 0, "preexisting selection not replaced")
Equal(casts, 0, "preexisting selection not cast")
Equal(targeting, true, "preexisting selection remains intact")
Equal(table.getn(calls), 0, "preexisting selection leaves CVars untouched")

for _, problem in ipairs({ "cast", "uncleared", "false", "noCircle", "pending" }) do
    Reset()
    fault = problem
    if problem == "false" then castResult = false end
    if problem == "noCircle" then makeCircle = false end
    Equal(addon.UseItem(water.item, water, nil, nil, "player"), true, problem .. " reports issued request only")
    Equal(requests, 1, problem .. " uses once")
    Equal(casts, problem == "noCircle" and 0 or 1, problem .. " no blind or delayed placement")
    Equal(targeting, problem == "cast" or problem == "uncleared" or problem == "false", problem .. " manual fallback circle")
    Equal(settings.NP_QuickcastTargetingSpells, "1", problem .. " restores quickcast")
    Equal(settings.NP_QueueTargetingSpells, "1", problem .. " restores queue")
end

for _, problem in ipairs({ "set", "silent", "use" }) do
    Reset()
    fault = problem
    Equal(addon.UseItem(water.item, water, nil, nil, "player"), false, problem .. " fails safely")
    Equal(requests, problem == "use" and 1 or 0, problem .. " setup failure never requests")
    Equal(casts, 0, problem .. " never places a different spell")
    Equal(settings.NP_QuickcastTargetingSpells, "1", problem .. " restores first setting")
    Equal(settings.NP_QueueTargetingSpells, "1", problem .. " restores second setting")
end

Reset()
fault = "restore"
Equal(addon.UseItem(water.item, water, nil, nil, "player"), true, "restore error does not hide issued request")
local restoreWarning = false
for _, entry in ipairs(warnings) do if string.find(entry.message, "未能恢复") then restoreWarning = true end end
Equal(restoreWarning, true, "restoration failure is visible")

Reset()
settings = { NP_QuickcastTargetingSpells = "0", NP_QueueTargetingSpells = "0" }
Equal(addon.UseItem(water.item, water, nil, nil, "player"), true, "already disabled settings work")
Equal(table.getn(calls), 0, "unchanged settings need no writes")

Reset()
local savedGet, savedSet = GetCVar, SetCVar
GetCVar, SetCVar = nil, nil
settings.NP_QuickcastTargetingSpells, settings.NP_QueueTargetingSpells = "0", "0"
UseContainerItem = function() requests = requests + 1; targeting = true end
Equal(addon.UseItem(water.item, water, nil, nil, "player"), true, "classic without optional CVar APIs")
Equal(casts, 1, "UnitXP placement does not require Nampower")
GetCVar, SetCVar = savedGet, savedSet

Reset()
Equal(addon.UseItem("致密炸弹", water, nil, nil, "player"), false, "mismatched item data cannot bypass whitelist")
Equal(addon.UseItem(water.item, water, nil, nil, "target"), false, "other placement modes not exposed")
Equal(addon.UseItem(water.item, water, 16, nil, "player"), false, "weapon path not accepted as ground casting")
Equal(requests, 0, "invalid ground requests are side-effect free")
for _, guard in ipairs({ "locked", "cooldown", "unavailable" }) do
    Reset()
    if guard == "locked" then locked = true elseif guard == "cooldown" then cooldown = 3 else unavailable = true end
    Equal(addon.UseItem(water.item, water, nil, nil, "player"), false, guard .. " preserved")
    Equal(requests, 0, guard .. " prevents use")
end

-- Shared CreateRow callbacks must pass the owning profile and selected mode in
-- normal, minimized and multiple independent windows; drag remains inert.
local db = addon.GetDatabase()
local firstId = db.defaultProfileId
local secondId = addon.CreateProfile("Ground item regression")
local invoked = {}
addon.UseItem = function(itemName, itemData, weaponSlot, owner, placement)
    table.insert(invoked, { name = itemName, data = itemData, slot = weaponSlot, owner = owner, placement = placement })
end
for _, profileId in ipairs({ firstId, secondId }) do
    local profile = db.profiles[profileId]
    profile.selected, profile.weaponSlots = { stratholmeWater = 1 }, {}
    profile.macroExcluded.stratholmeWater = 0
    addon.SetProfileWindowVisible(profileId, true)
    for _, miniature in ipairs({ 0, 1 }) do
        profile.minimized = miniature
        addon.RefreshPotionRows()
        local ui = addon.Windows[profileId]
        local row = ui.rows[1]
        Equal(row.itemData, water, "ground row selected")
        row.weaponSlot = false -- Mock absent-field fallback is a function, unlike actual frames.
        this, arg1 = row, "LeftButton"
        row.scripts.OnClick()
        Equal(invoked[table.getn(invoked)].placement, nil, "left passes manual mode")
        Equal(invoked[table.getn(invoked)].owner, profileId, "left preserves window profile")
        this, arg1 = row, "RightButton"
        row.scripts.OnClick()
        Equal(invoked[table.getn(invoked)].placement, "player", "right passes self mode")
        Equal(invoked[table.getn(invoked)].owner, profileId, "right preserves window profile")
        Equal(profile.macroExcluded.stratholmeWater, 0, "right does not toggle macro exclusion")
        local before = table.getn(invoked)
        IsShiftKeyDown = function() return true end
        row.scripts.OnClick()
        Equal(table.getn(invoked), before, "Shift-right manual-only water never casts or toggles macro")
        IsShiftKeyDown = function() return false end
        ui.dragSourceKey = "stratholmeWater"
        row.scripts.OnClick()
        Equal(table.getn(invoked), before, "dragged row never throws")
        ui.dragSourceKey = nil
    end
    Equal(addon.IsMacroExcluded(water, profile), true, "water remains outside automatic macro")
end
addon.UseItem = originalUse
print("PASS: " .. checks .. " instant ground item assertions; real Core/row handlers, fallback and CVar restoration")
