-- Run from Interface/AddOns; use the real engine and shared strict UI fixture.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local originalUse = addon.UseItem
local originalHuge = math.huge
math.huge = nil -- Stock Lua 5.0.3 does not define this field.
local now, hp, mp, manaMaximum, power, combat, dead, ghost, targeting, castAPI, channelAPI
local counts, cooldownEnds, locked, requests, itemReads, resourceReads, useFault
local red = addon.ItemsByID[13446]
local blue = addon.ItemsByID[13444]
local tea = addon.ItemsByID[61675]
local checks = 0
local function Equal(actual, expected, message)
    assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
    checks = checks+1
end
local function Item(name) return addon.ItemsByName[name] end

local function Reset()
    now, hp, mp, manaMaximum, power, combat = 1000, 100, 100, 100, 0, true
    dead, ghost, targeting, castAPI, channelAPI = false, false, false, nil, nil
    counts, cooldownEnds, locked, requests = {}, {}, {}, {}
    itemReads, resourceReads, useFault = 0, 0, nil
    counts[red.key], counts[blue.key], counts[tea.key] = 10, 10, 10
    CatPotionDB.autoUseItems = {}
    GetTime = function() return now end
    UnitHealth = function() resourceReads=resourceReads+1; return hp end
    UnitHealthMax = function() return 100 end
    UnitMana = function() return mp end
    UnitManaMax = function() return manaMaximum end
    UnitPowerType = function() return power end
    UnitAffectingCombat = function() return combat end
    UnitIsDeadOrGhost = function() return dead or ghost end
    UnitIsDead = function() return dead end
    UnitIsGhost = function() return ghost end
    UnitCastingInfo = function() return castAPI end
    UnitChannelInfo = function() return channelAPI end
    SpellIsTargeting = function() return targeting end
    addon.AutoUseSettings = nil
    addon.FindBagItem = function(name)
        itemReads = itemReads+1
        local item = Item(name)
        local count = item and counts[item.key] or 0
        if count > 0 then return 0, item.itemID, count end
        return nil, nil, 0
    end
    GetContainerItemInfo = function(_, slot)
        local item = addon.ItemsByID[slot]
        return "icon", item and counts[item.key] or 0, item and locked[item.key]
    end
    addon.GetCooldownInfo = function(name)
        itemReads = itemReads+1
        local item = Item(name)
        return math.max(0, (cooldownEnds[item.key] or 0)-now), "item", false
    end
    addon.UseItem = function(name, item)
        table.insert(requests, item.key)
        if useFault == "throw" then error("mock rejection") end
        if useFault == "reject" then return false end
        local before = counts[item.key]
        if useFault == "synchronous" then
            counts[item.key] = before-1
            cooldownEnds[item.key] = now+10
        end
        addon.NotifyAutoUseManual(item, before)
        return true
    end
    dofile("CatPotion/AutoUse.lua")
end

local function Event(name, first, second)
    this, event, arg1, arg2 = addon.AutoUseDriver, name, first, second
    this.scripts.OnEvent()
end
local function Tick(delta)
    now = now+(delta or .21)
    local frame = addon.AutoUseDriver
    if frame:IsVisible() then this, arg1 = frame, delta or .21; frame.scripts.OnUpdate() end
end
local function Enable(key, values)
    values = values or {}
    values.enabled = 1
    Equal(addon.SetAutoUseConfig(key, values), true, "configuration accepted")
end
local function Health(value)
    hp = value
    Event("UNIT_HEALTH", "player")
    Tick()
end
local function Status(key)
    return addon.GetAutoUseStatus(key)
end

Reset()
for _, key in ipairs({ red.key, blue.key, tea.key }) do
    Equal(addon.GetAutoUseConfig(key).enabled, 0, "automatic use disabled by default")
end
Equal(addon.GetAutoUseConfig(red).healthThreshold, 35, "red default health threshold")
Equal(addon.GetAutoUseConfig(blue).manaThreshold, 25, "blue default mana threshold")
Equal(addon.GetAutoUseConfig(tea).healthThreshold, 35, "tea default health threshold")
Equal(addon.GetAutoUseConfig(tea).manaThreshold, 25, "tea default mana threshold")
Equal(addon.IsAutoUseItem(addon.ItemsByID[13180]), false, "holy water excluded")
Equal(addon.IsAutoUseItem({ key=red.key, itemID=13180 }), false, "forged item identity rejected")
Equal(addon.GetAutoUseConfig("mongoose"), nil, "unsupported configuration rejected")
Equal(addon.SetAutoUseConfig("mongoose", { enabled=1 }), false, "unsupported setter rejected")
for index=1,20 do Event("UNIT_HEALTH", "player"); Tick() end
addon.NotifyAutoUseManual(red, 10)
Equal(itemReads, 0, "default-off resource/manual activity never scans items")
Equal(resourceReads, 0, "default-off driver never polls health")
Equal(table.getn(requests), 0, "default-off never uses items")
addon.SetAutoUseConfig(red.key, { enabled="1", healthThreshold=150, manaThreshold=99, combatOnly=0 })
local config = addon.GetAutoUseConfig(red.key)
Equal(config.healthThreshold, 100, "health clamped to 100")
Equal(config.manaThreshold, 0, "red cannot react to mana")
Equal(config.combatOnly, 0, "optional outside-combat rule saved")
addon.SetAutoUseConfig(blue.key, { healthThreshold=22, manaThreshold=-3 })
Equal(addon.GetAutoUseConfig(blue.key).healthThreshold, 0, "blue cannot react to health")
Equal(addon.GetAutoUseConfig(blue.key).manaThreshold, 0, "zero disables resource condition")
addon.SetAutoUseConfig(tea.key, { healthThreshold=0/0, manaThreshold="26.6" })
Equal(addon.GetAutoUseConfig(tea.key).healthThreshold, 35, "invalid number uses default")
Equal(addon.GetAutoUseConfig(tea.key).manaThreshold, 27, "threshold normalization rounds")
addon.SetAutoUseConfig(tea.key, { healthThreshold=1/0, manaThreshold=-1/0 })
Equal(addon.GetAutoUseConfig(tea.key).healthThreshold, 35, "positive infinity falls back without math.huge")
Equal(addon.GetAutoUseConfig(tea.key).manaThreshold, 25, "negative infinity falls back without math.huge")

Reset()
Enable(red.key)
Tick()
Equal(itemReads, 0, "healthy enabled driver does not query item data")
Equal(addon.AutoUseDriver:IsVisible(), false, "healthy engine sleeps until an event")
local reads = resourceReads
Event("UNIT_HEALTH", "target")
Tick()
Equal(resourceReads, reads, "other units do not wake resource evaluation")
Health(35)
Equal(table.getn(requests), 0, "equal threshold does not trigger")
hp = 34
for index=1,20 do Event("UNIT_HEALTH", "player") end
Tick(.19)
Equal(table.getn(requests), 0, "resource burst coalesced for 0.2 seconds")
Tick(.02)
Equal(table.getn(requests), 1, "strictly below threshold triggers once")
Equal(requests[1], red.key, "red used for low health")
Equal(Status(red.key), "pending", "UseItem true remains pending")
Tick(.3)
Equal(table.getn(requests), 1, "internal manual hook cannot cause duplicate request")
counts[red.key], cooldownEnds[red.key] = 9, now+5
Event("BAG_UPDATE", 0)
Tick()
Equal(Status(red.key), "cooldown", "native cooldown/consumption confirms request")
Tick(1)
Equal(table.getn(requests), 1, "confirmed cooldown prevents repeated low-health use")
Tick(5)
Equal(table.getn(requests), 2, "actual cooldown ending rearms even while health stays low")

Reset()
Enable(red.key)
hp = 10
Tick()
counts[red.key] = 9 -- Confirm consumption with no usable duration; do not invent 120s.
Event("BAG_UPDATE", 0)
Tick()
Equal(Status(red.key), "await_resource", "count confirmation does not fabricate a cooldown")
Tick(3)
Equal(table.getn(requests), 1, "unrecovered resource stays disarmed without cooldown evidence")
Health(39)
Health(20)
Equal(table.getn(requests), 1, "four points above threshold do not rearm")
Health(40)
Health(20)
Equal(table.getn(requests), 2, "five-point recovery rearms")

Reset()
Enable(red.key)
Enable(blue.key)
Enable(tea.key)
hp, mp = 10, 5
Tick()
Equal(requests[1], red.key, "health red outranks mana blue and tea")
Equal(table.getn(requests), 1, "one request across all profiles/windows per round")
Event("UNIT_MANA", "player")
Tick()
Equal(table.getn(requests), 1, "pending global mutex blocks other recovery items")

Reset()
Enable(red.key)
Enable(tea.key)
locked[red.key], hp = true, 10
Tick()
Equal(requests[1], tea.key, "locked high-priority red does not starve tea")
Equal(Status(red.key), "locked", "locked candidate has distinct status")
Reset()
Enable(red.key)
Enable(tea.key)
counts[red.key], hp = 0, 10
Tick()
Equal(requests[1], tea.key, "tea is health fallback when red absent")
Reset()
Enable(blue.key)
Enable(tea.key)
hp, mp = 90, 10
Tick()
Equal(requests[1], blue.key, "blue first for mana")
Reset()
Enable(blue.key)
Enable(tea.key)
hp, mp, cooldownEnds[blue.key] = 90, 10, now+30
Tick()
Equal(requests[1], tea.key, "tea is mana fallback when blue is cooling down")

for _, guard in ipairs({ "dead", "ghost", "castingAPI", "channelAPI", "selection", "outOfCombat", "popup" }) do
    Reset()
    Enable(red.key)
    hp = 10
    if guard=="dead" then dead=true elseif guard=="ghost" then ghost=true
    elseif guard=="castingAPI" then castAPI="cast" elseif guard=="channelAPI" then channelAPI="channel"
    elseif guard=="selection" then targeting=true elseif guard=="outOfCombat" then combat=false
    else addon.AutoUseSettings={ IsVisible=function() return true end } end
    Tick()
    Equal(table.getn(requests), 0, guard .. " prevents new automatic request")
end
Reset()
Enable(red.key, { combatOnly=0 })
hp, combat = 10, false
Tick()
Equal(table.getn(requests), 1, "outside combat allowed only when explicitly configured")
for _, noMana in ipairs({ "rage", "zeroMaximum" }) do
    Reset()
    Enable(blue.key)
    mp = 0
    if noMana=="rage" then power=1 else manaMaximum=0 end
    Tick()
    Equal(table.getn(requests), 0, noMana .. " is not low mana")
end

Reset()
Enable(red.key)
hp = 10
Event("SPELLCAST_START", "heal", 3000)
Tick()
Equal(table.getn(requests), 0, "classic cast event blocks without enhanced API")
Event("SPELLCAST_STOP")
Tick()
Equal(table.getn(requests), 1, "classic cast stop resumes")
Reset()
Enable(red.key)
hp = 10
Event("SPELLCAST_CHANNEL_START", 3000)
Tick()
Event("SPELLCAST_FAILED")
Tick()
Event("SPELLCAST_INTERRUPTED")
Tick()
Equal(table.getn(requests), 0, "unrelated failed spells do not end active channel")
Event("SPELLCAST_CHANNEL_UPDATE", 1000)
Tick(.5)
Equal(table.getn(requests), 0, "channel update uses remaining time")
Tick(1)
Equal(table.getn(requests), 1, "channel natural expiry resumes without permanent block")

for _, failure in ipairs({ "reject", "throw", "unconfirmed" }) do
    Reset()
    Enable(red.key)
    hp = 10
    useFault = failure
    Tick()
    Equal(table.getn(requests), 1, failure .. " first attempt")
    Tick(.5)
    Event("UI_ERROR_MESSAGE", "unrelated error")
    Tick(.5)
    Equal(table.getn(requests), 1, failure .. " errors cannot erase serial backoff")
    if failure=="unconfirmed" then
        Tick(1.2)
        Equal(Status(red.key), "unconfirmed", "request timeout never reports success")
        Equal(table.getn(requests), 1, "timeout also has failure backoff")
        Tick(2.1)
    else Tick(1.2) end
    Equal(table.getn(requests), 2, failure .. " retries after bounded backoff")
end

Reset()
Enable(red.key)
hp = 10
-- A manual use may have synchronously changed both count and cooldown already.
counts[red.key], cooldownEnds[red.key] = 9, now+10
addon.NotifyAutoUseManual(red, 10)
Tick()
Equal(Status(red.key), "cooldown", "manual before-count/native CD confirms synchronous use")
Equal(table.getn(requests), 0, "manual use coordinates automatic cooldown")
Tick(2)
Equal(table.getn(requests), 0, "manual confirmation does not duplicate use")
Reset()
Enable(red.key)
hp = 10
addon.NotifyAutoUseManual(addon.ItemsByID[13180], 10)
Tick()
Equal(table.getn(requests), 0, "other manual items share two-second request mutex")
Tick(2)
Equal(table.getn(requests), 1, "automatic recovery resumes after manual mutex")

Reset()
Enable(red.key)
hp, useFault = 10, "synchronous"
Tick()
Equal(Status(red.key), "pending", "synchronous auto use still waits for observation")
Tick()
Equal(Status(red.key), "cooldown", "synchronous auto consumption confirms once")
Tick(3)
Equal(table.getn(requests), 1, "auto hook recursion never double-requests")

Reset()
Enable(red.key)
hp = 10
Tick()
addon.SetAutoUseConfig(red.key, { enabled=0 })
Tick(.5)
Equal(table.getn(requests), 1, "disabling preserves issued request observation but issues nothing else")
Tick(4)
Equal(addon.AutoUseDriver:IsVisible(), false, "disabled engine sleeps after pending timeout")

Reset()
Enable(red.key)
hp = 10
Tick()
addon.AutoUseSettings = { IsVisible=function() return true end }
counts[red.key], cooldownEnds[red.key] = 9, now+10
Event("BAG_UPDATE", 0)
Tick()
Equal(Status(red.key), "cooldown", "settings popup does not prevent pending confirmation")
Equal(table.getn(requests), 1, "settings popup cannot issue an additional item")

-- Real Core.UseItem performs the final bag lock/cooldown checks and invokes the
-- manual notification hook. The automatic path must remain one request.
Reset()
Enable(red.key)
hp = 10
addon.RequestPotionUseRefresh = function() end
addon.UseItem = originalUse
UseContainerItem = function(_, slot)
    local item = addon.ItemsByID[slot]
    table.insert(requests, item.key)
    counts[item.key] = counts[item.key]-1
    cooldownEnds[item.key] = now+120
end
for _, window in pairs(addon.Windows) do window.window:Hide() end
Tick()
Equal(table.getn(requests), 1, "real Core.UseItem works with every potion window hidden")
Equal(Status(red.key), "pending", "real Core true still means request pending")
Tick()
Equal(Status(red.key), "cooldown", "real Core/manual hook shares the same confirmation state")
Tick(2)
Equal(table.getn(requests), 1, "real hook cannot recurse into a second use")
math.huge = originalHuge
print("PASS: " .. checks .. " recovery auto-use config, priority, safety, pending, hysteresis and scheduling assertions")
