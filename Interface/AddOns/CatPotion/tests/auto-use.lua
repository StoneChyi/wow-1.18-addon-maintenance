-- Run from Interface/AddOns; use the real engine and shared strict UI fixture.
dofile("CatPotion/tests/weapon-charges.lua")
local addon = CatPotionAddon
local originalUse = addon.UseItem
local originalHuge = math.huge
math.huge = nil -- Stock Lua 5.0.3 does not define this field.
local now, hp, mp, manaMaximum, power, combat, dead, ghost, targeting, castAPI, channelAPI
local counts, cooldownEnds, locked, requests, itemReads, resourceReads, useFault
local maxHP, classFile, moving, buffs, harmfulSleep, harmfulScans
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
    maxHP, classFile, moving, buffs, harmfulSleep, harmfulScans = 100, "ROGUE", false, {}, false, 0
    counts, cooldownEnds, locked, requests = {}, {}, {}, {}
    itemReads, resourceReads, useFault = 0, 0, nil
    counts[red.key], counts[blue.key], counts[tea.key] = 10, 10, 10
    CatPotionDB.autoUseItems = {}
    GetTime = function() return now end
    UnitHealth = function() resourceReads=resourceReads+1; return hp end
    UnitHealthMax = function() return maxHP end
    UnitMana = function() return mp end
    UnitManaMax = function() return manaMaximum end
    UnitPowerType = function() return power end
    UnitClass = function() return classFile, classFile end
    UnitAffectingCombat = function() return combat end
    UnitIsDeadOrGhost = function() return dead or ghost end
    UnitIsDead = function() return dead end
    UnitIsGhost = function() return ghost end
    UnitCastingInfo = function() return castAPI end
    UnitChannelInfo = function() return channelAPI end
    SpellIsTargeting = function() return targeting end
    PlayerIsMoving = function() return moving end
    UnitXP, GetUnitSpeed = nil, nil
    addon.PlayerIsEating = function() return buffs.eating == true end
    addon.GetBuffTime = function(name) return buffs[name] or 0 end
    GetPlayerBuff = function(index, filter)
        Equal(filter, "HARMFUL", "sleep detection reads harmful aura handles")
        harmfulScans = harmfulScans+1
        return harmfulSleep and index==0 and 40 or -1
    end
    GetPlayerBuffTexture = function(handle)
        return harmfulSleep and handle==40 and "Interface\\Icons\\Spell_Nature_Sleep" or nil
    end
    GetPlayerBuffTimeLeft = function(handle) return handle==40 and 30 or 0 end
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

-- Extended catalogue is opt-in; capability metadata drives the dynamic dialog.
local extraKeys = { "majorHealthstone", "majorRejuvenation", "superiorHealing", "superiorMana", "greaterMana",
    "greaterDreamlessSleep", "dreamlessSleep", "thistleTea", "demonicRune", "darkRune", "conjuredManaOrange" }
Reset()
for _, key in ipairs(extraKeys) do
    Equal(addon.IsAutoUseItem(key), true, key .. " supported")
    Equal(addon.GetAutoUseConfig(key).enabled, 0, key .. " remains disabled by default")
    Equal(type(addon.GetAutoUseDefinition(key).health), "boolean", key .. " metadata is a capability boolean")
end
Equal(addon.IsAutoUseItem("hourglassSand"), false, "non-recovery sand remains manual")
Equal(addon.IsAutoUseItem("powerfulAntivenom"), false, "non-resource antivenom remains manual")
Equal(addon.IsAutoUseItem("limitedInvulnerability"), false, "functional potion does not become resource-triggered")
Equal(addon.GetAutoUseConfig({ key="majorHealthstone", itemID=19012 }), addon.GetAutoUseConfig("majorHealthstone"), "healthstone talent variant shares config")
Equal(addon.GetAutoUseConfig({ key="majorHealthstone", itemID=19013 }), addon.GetAutoUseConfig("majorHealthstone"), "second healthstone variant shares config")
Equal(addon.GetAutoUseDefinition("thistleTea").energy, true, "thistle tea energy capability")
Equal(addon.GetAutoUseDefinition("thistleTea").mana, false, "thistle tea has no mana capability")
Equal(addon.GetAutoUseDefinition("demonicRune").costsHealth, true, "rune health-cost capability")
Equal(addon.GetAutoUseDefinition("demonicRune").minHealthValue, 1101, "rune uses conservative absolute floor")
Equal(addon.GetAutoUseDefinition("conjuredManaOrange").outOfCombatOnly, true, "orange is always outside combat")
Equal(addon.GetAutoUseDefinition("dreamlessSleep").needsRest, true, "sleep potion requires rest guard")
addon.SetAutoUseConfig(red.key, { enabled=1, healthThreshold=44, combatOnly=0 })
dofile("CatPotion/AutoUse.lua")
Equal(addon.GetAutoUseConfig(red.key).enabled, 1, "expanded catalogue does not reset old enabled state")
Equal(addon.GetAutoUseConfig(red.key).healthThreshold, 44, "expanded catalogue preserves old threshold")
Equal(addon.GetAutoUseConfig(red.key).combatOnly, 0, "expanded catalogue preserves old combat preference")

for _, key in ipairs({ "majorHealthstone", "majorRejuvenation", "superiorHealing", "greaterDreamlessSleep", "dreamlessSleep", "conjuredManaOrange" }) do
    Reset()
    Enable(key)
    counts[key], hp = 10, 10
    if key=="conjuredManaOrange" then combat=false end
    Tick()
    Equal(requests[1], key, key .. " responds to health")
end
for _, key in ipairs({ "majorRejuvenation", "superiorMana", "greaterMana", "greaterDreamlessSleep", "dreamlessSleep", "demonicRune", "darkRune", "conjuredManaOrange" }) do
    Reset()
    Enable(key)
    counts[key], hp, maxHP, mp = 10, 2500, 3000, 10
    if key=="conjuredManaOrange" then combat=false end
    Tick()
    Equal(requests[1], key, key .. " responds to mana")
end

Reset()
Enable("majorHealthstone")
Enable(red.key)
Enable(tea.key)
counts.majorHealthstone, hp, mp = 10, 10, 10
Tick()
Equal(requests[1], "majorHealthstone", "healthstone leads health priority")
Reset()
Enable("superiorHealing")
Enable(red.key)
counts.superiorHealing, counts[red.key], hp = 10, 0, 10
Tick()
Equal(requests[1], "superiorHealing", "lower-tier heal fills missing major potion")

Reset()
Enable("thistleTea", { manaThreshold=90 })
counts.thistleTea, power, mp = 10, 3, 24
Equal(addon.GetAutoUseConfig("thistleTea").energyThreshold, 25, "energy default threshold")
Equal(addon.GetAutoUseConfig("thistleTea").manaThreshold, 0, "energy item cannot use mana rule")
Tick()
Equal(requests[1], "thistleTea", "rogue low energy uses thistle tea")
for _, wrongPower in ipairs({ 0, 1, 2 }) do
    Reset()
    Enable("thistleTea")
    counts.thistleTea, power, mp = 10, wrongPower, 1
    Tick()
    Equal(table.getn(requests), 0, "non-energy resource cannot trigger thistle tea")
end
Reset()
Enable("thistleTea")
counts.thistleTea, power, mp, classFile = 10, 3, 1, "DRUID"
Tick()
Equal(table.getn(requests), 0, "druid energy form does not consume rogue-only tea")
Reset()
Enable(blue.key)
Enable(tea.key)
power, mp = 3, 1
Tick()
Equal(table.getn(requests), 0, "energy is never substituted for missing mana percent")
Reset()
Enable("thistleTea")
counts.thistleTea, power, mp = 10, 3, 100
Tick()
local energyReads = resourceReads
mp = 24
Event("UNIT_ENERGY", "target")
Tick()
Equal(resourceReads, energyReads, "target energy event ignored")
Event("UNIT_ENERGY", "player")
Tick()
Equal(requests[1], "thistleTea", "player energy event wakes engine")

for _, key in ipairs({ "demonicRune", "darkRune" }) do
    Reset()
    Enable(key)
    counts[key], hp, maxHP, mp = 10, 1800, 3000, 10
    Tick()
    Equal(table.getn(requests), 0, key .. " equal safety percentage blocked")
    Health(1801)
    Equal(requests[1], key, key .. " strictly above safety percentage permitted")
    Reset()
    Enable(key, { minHealthPercent=50 })
    counts[key], hp, maxHP, mp = 10, 1100, 2000, 10
    Tick()
    Equal(table.getn(requests), 0, key .. " absolute health floor still blocks")
    Health(1101)
    Equal(requests[1], key, key .. " conservative absolute floor is inclusive at 1101")
    Reset()
    Enable(key)
    counts[key], hp, maxHP, mp, power = 10, 2500, 3000, 1, 3
    Tick()
    Equal(table.getn(requests), 0, key .. " low energy cannot trigger health sacrifice")
end

Reset()
Enable("conjuredManaOrange", { combatOnly=1 })
counts.conjuredManaOrange, hp = 10, 10
Equal(addon.GetAutoUseConfig("conjuredManaOrange").combatOnly, 0, "orange cannot get contradictory combat-only config")
Tick()
Equal(table.getn(requests), 0, "orange never used during combat")
combat = false
Event("PLAYER_REGEN_ENABLED")
Tick()
Equal(requests[1], "conjuredManaOrange", "orange becomes eligible outside combat")
for _, key in ipairs({ "conjuredManaOrange", "greaterDreamlessSleep", "dreamlessSleep" }) do
    Reset()
    Enable(key)
    counts[key], hp, moving = 10, 10, true
    if key=="conjuredManaOrange" then combat=false end
    Tick()
    Equal(table.getn(requests), 0, key .. " cannot start while moving")
    Equal(Status(key), "moving", key .. " reports movement guard")
    moving = false
    Tick(.6)
    Equal(requests[1], key, key .. " resumes once stationary")
end
Reset()
Enable("dreamlessSleep")
counts.dreamlessSleep, hp = 10, 10
PlayerIsMoving = nil
Tick()
Equal(Status("dreamlessSleep"), "stationary_unknown", "missing motion provider is not guessed stationary")
Equal(table.getn(requests), 0, "unknown movement leaves manual option")
PlayerIsMoving = function() return false end
UnitXP = function(command) if command=="speed" then return 2 end end
Tick(.6)
Equal(table.getn(requests), 0, "any provider confirming movement blocks rest item")
UnitXP = function(command) if command=="speed" then return 0 end end
Tick(.6)
Equal(requests[1], "dreamlessSleep", "confirmed optional movement API enables rest item")

for _, aura in ipairs({ "eating", "Drink", "无梦睡眠", "强效昏睡" }) do
    Reset()
    Enable(red.key)
    hp = 10
    if aura=="eating" then buffs.eating=true else buffs[aura]=20 end
    Tick()
    Equal(table.getn(requests), 0, aura .. " recovery is not interrupted by another automatic item")
end
Reset()
Enable(red.key)
hp, harmfulSleep = 10, true
Tick()
Equal(table.getn(requests), 0, "harmful sleep outside ordinary buff cache blocks auto-use")
local scans = harmfulScans
Tick(.6)
Tick(.6)
Equal(harmfulScans, scans, "harmful aura scan is event-cached, not repeated per poll")
harmfulSleep = false
Event("PLAYER_AURAS_CHANGED")
Tick()
Equal(requests[1], red.key, "aura removal event resumes recovery requests")

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
