--[[
    NampowerAPI.lua - Nampower API Integration Layer

    Provides wrapper functions for Nampower's extended Lua API with fallbacks
    for older versions or when functions are unavailable.

    Core Nampower Functions Wrapped (v2.8+):
    - GetSpellRec / GetSpellRecField - Spell record data from client DB
    - GetItemStats / GetItemStatsField - Item stats from client DB
    - GetUnitData / GetUnitField - Low-level unit field access
    - GetSpellModifiers - Spell modifier calculations (talents, buffs, etc.)

    Inventory/Equipment Functions (v2.18+):
    - FindPlayerItemSlot - Fast item location lookup
    - GetEquippedItems / GetEquippedItem - Equipment inspection
    - GetBagItems / GetBagItem - Bag contents inspection
    - GetCastInfo - Detailed cast/channel/GCD information
    - GetSpellIdCooldown / GetItemIdCooldown - Detailed cooldown info with item metadata

    Trinket/Item Functions (v2.20+):
    - GetTrinkets - Enumerate equipped and bagged trinkets
    - GetTrinketCooldown - Get trinket cooldown by slot/ID/name
    - UseTrinket - Use trinket by slot/ID/name with optional target
    - UseItemIdOrName - Use any item by ID/name with optional target

    Enhanced Functions (accept spell name or "spellId:number"):
    - GetSpellTexture, GetSpellName, GetSpellCooldown, GetSpellAutocast
    - ToggleSpellAutocast, PickupSpell, CastSpell, IsCurrentCast, IsSpellPassive

    Copy Parameter (v2.20+):
    - Most table-returning functions now accept [copy] parameter
    - Pass 1 to get independent copy safe for storage
    - Without copy, table references are reused - extract values immediately!

    Utility Functions (v2.22+):
    - DisenchantAll - Auto-disenchant items by ID/name or quality

    Cooldown Detail Tables (v2.23+):
    - GetSpellIdCooldown/GetItemIdCooldown now include item metadata:
      itemId, itemHasActiveSpell, itemActiveSpellId

    Auto-Attack Events (v2.24+):
    - AUTO_ATTACK_SELF / AUTO_ATTACK_OTHER events
    - Detailed hit info: damage, crit/glancing/crushing, dodge/parry/block
    - Requires NP_EnableAutoAttackEvents=1 CVar to enable

    Spell Start/Go Events (v2.25+):
    - SPELL_START_SELF / SPELL_START_OTHER - Server notifies cast time spell begun
    - SPELL_GO_SELF / SPELL_GO_OTHER - Server notifies spell completed casting
    - Requires NP_EnableSpellStartEvents=1 and NP_EnableSpellGoEvents=1 CVars

    Spell Heal/Energize Events (v2.26+):
    - SPELL_HEAL_BY_SELF / SPELL_HEAL_BY_OTHER / SPELL_HEAL_ON_SELF
    - SPELL_ENERGIZE_BY_SELF / SPELL_ENERGIZE_BY_OTHER / SPELL_ENERGIZE_ON_SELF
    - Requires NP_EnableSpellHealEvents=1 and NP_EnableSpellEnergizeEvents=1 CVars

    Texture Lookup Functions (v2.27+):
    - GetItemIconTexture(displayInfoId) - Get item texture path from display info ID
    - GetSpellIconTexture(spellIconId) - Get spell texture path from spell icon ID

    Nameplate GUID (v2.28+):
    - CSimpleFrame:GetName(1) returns nameplate unit GUID

    Ammo Query (v2.29+):
    - GetAmmo() - Returns equipped ammo item ID and total count

    Aura Slot Extensions (v2.30+):
    - auraSlot parameter on BUFF/DEBUFF_ADDED/REMOVED events (raw 0-based slot)
    - BUFF_UPDATE_DURATION_SELF / DEBUFF_UPDATE_DURATION_SELF events
    - GetPlayerAuraDuration(auraSlot) - Get duration info for player aura by slot

    Spell Miss Events (v2.31+):
    - SPELL_MISS_SELF / SPELL_MISS_OTHER - Spell miss/resist/immune/dodge/etc.
    - GetSpellPower([mode]) - Player mod damage done for all 7 schools

    Aura Event State Parameter (v2.32+):
    - Buff/debuff events include 7th `state` parameter (0=added, 1=removed, 2=modified)
    - REMOVED events now properly fire for stack decrements (state=2)

    Duration Event SpellId (v2.33+):
    - BUFF/DEBUFF_UPDATE_DURATION_SELF include spellId as 4th parameter
    - GetCastInfo() guid field fix (no code change needed)

    Settings Integration:
    - Reads from NampowerSettings addon when available
    - Falls back to CVars when addon not present

    Aura Cancel Functions (v2.34+):
    - CancelPlayerAuraSlot(auraSlot) - Cancel buff/debuff by raw 0-based aura slot
    - CancelPlayerAuraSpellId(spellId, [ignoreMissing]) - Cancel buff/debuff by spell ID
      Pass ignoreMissing=1 to skip aura-slot presence check (for server-side
      overflow buffs that have no client aura slot in the 48-slot array)

    GUID String Fix & Talent Helper (v2.35+):
    - GetUnitData/GetUnitField now return GUID-type fields (charm, summon, charmedBy,
      summonedBy, createdBy, target, persuaded, channelObject) as hex strings
      (e.g., "0x0600000012345678") instead of raw numbers to avoid Lua 64-bit precision loss
    - LearnTalentRank(talentPage, talentIndex, rank) - Learn a specific talent rank directly

    Player State Functions (v2.36+):
    - PlayerIsMoving() - Returns 1 if player is moving, nil if stationary
    - PlayerIsRooted() - Returns 1 if player is rooted, nil if not
    - PlayerIsSwimming() - Returns 1 if player is swimming, nil if not

    Unit Token Cast & Mouseover (v2.37+):
    - CastSpellByName(spellName, unitToken) - 2nd param now accepts unit token strings
      (e.g. "mouseover", "party1", "focus") in addition to GUIDs and 1 (self).
      Enables soft-casting on unit tokens without changing the player's visible target.
    - SetMouseoverUnit(unitToken) - Programmatically set the mouseover unit.
      Previously only available via SuperWoW; now also provided by Nampower.

    Spell Duration & Enhanced SPELL_START (v2.38+):
    - GetSpellDuration(spellId, [ignoreModifiers]) - Returns duration in ms.
      For channeling spells: channel duration. For others: first aura effect duration.
      Pass ignoreModifiers=1 to get base duration (ignores talents/buffs).
      Returns 0 if spell has no duration, nil if spellId invalid.
    - SPELL_START_SELF / SPELL_START_OTHER now include two new parameters:
        arg7 = duration (ms) - channel duration for channeling spells, 0 otherwise
        arg8 = spellType   - 0=Normal, 1=Channeling, 2=Autorepeating
      Use spellType to distinguish channeling spells (SPELL_START_OTHER carries both
      cast-time and channeling spells since there is no separate SPELL_CHANNEL_START
      packet for other players).

    Unit GUID Events (v2.39+):
    - New GUID-based unit events fire once per unit state change instead of once per
      registered token. Each event carries GUID + flags for player/target/mouseover/pet/
      party/raid membership. Avoids event spam from per-token firing.
    - Events: UNIT_HEALTH_GUID, UNIT_MANA_GUID, UNIT_RAGE_GUID, UNIT_ENERGY_GUID,
      UNIT_PET_GUID, UNIT_FLAGS_GUID, UNIT_AURA_GUID, UNIT_DYNAMIC_FLAGS_GUID,
      UNIT_NAME_UPDATE_GUID, UNIT_PORTRAIT_UPDATE_GUID, UNIT_MODEL_CHANGED_GUID,
      UNIT_INVENTORY_CHANGED_GUID, PLAYER_GUILD_UPDATE_GUID
    - UNIT_COMBAT_GUID: fires once per combat feedback event with full combat detail
      (action, damage, school, hitInfo) instead of per token.
    - Granular CVars to control which unit tokens fire standard UNIT_* events:
        NP_EnableUnitEventsPet (default 1), NP_EnableUnitEventsParty (default 1),
        NP_EnableUnitEventsRaid (default 1), NP_EnableUnitEventsMouseover (default 1),
        NP_EnableUnitEventsGuid (default 1), NP_EnableUnitEventsGuidFiltering (default 1)

    Corpse Guid & Packed GUID Fix (v2.40+):
    - SPELL_START_SELF/OTHER now include arg9 = corpseOwnerGuid (string or nil):
        GUID of the player who owns the corpse target; nil if no corpse target.
    - SPELL_GO_SELF/OTHER now include arg8 = corpseOwnerGuid (string or nil).
    - Fixed packed GUID parsing bug that caused target to appear as "0x000000000"
      for some player GUIDs.

    Keyboard Events & Extended Unit Token Support (v2.41+):
    - KEY_DOWN / KEY_UP events: fire when keyboard keys are pressed and released.
      Any addon can register for these to react to key input without frame scripts.
    - Internal unit token resolver extended: all Nampower functions that accept a
      unit string (SetMouseoverUnit, UseItemIdOrName, CastSpellByName, etc.) now
      support additional formats beyond standard tokens and GUIDs:
        mark1..mark8        - resolve to the unit bearing that raid marker
        <base>owner         - owner of <base> (e.g. "targetowner" = target's owner)
        <base>target        - target of <base> (e.g. "mouseovertarget")
        <base>pet           - pet of <base>   (e.g. "party1pet")
      <base> can be a standard token, a GUID string, or a mark token.
      Suffix matching is case-insensitive.
      Note: GetGUIDFromName is an internal C++ helper, NOT a new Lua global.

    GetUnitGUID Rename, IsAuraHidden, Hidden Aura luaSlot Fix (v3.0+):
    - UnitGUID renamed to GetUnitGUID (global function). The addon uses SuperWoW's
      UnitExists for GUIDs so this rename is not breaking, but GetUnitGUID supports
      extended tokens (mark1-mark8, <base>owner/target/pet suffixes).
    - IsAuraHidden(spellId): returns 1 if the spell's aura is hidden from Lua aura
      APIs (UnitBuff/UnitDebuff won't show it). Useful for detecting hidden CC spells.
    - luaSlot in BUFF/DEBUFF events now returns 0 for hidden auras (was incorrect before).

    No-Queue Cast by ID & SPELL_CAST_EVENT Target Default (v3.1+):
    - CastSpellNoQueue(spellId, spellBook [, unit]) - Cast by spell ID without spell queueing.
      spellBook: 0 for player spells, "pet" for pet spells.
      Optional unit parameter for targeting (same tokens as CastSpellByName).
    - CastSpellByNameNoQueue now accepts unit token as second parameter (same as CastSpellByName).
    - SPELL_CAST_EVENT targetGuid now defaults to current target's GUID instead of null GUID
      ("0x0000000000000000"). Still overridden by explicit target (CastSpellByName 2nd param,
      SpellTargetUnit mouseover).

    File I/O, Combat Log Flush, Encrypted Login, and Backwards-Compatible Import/Export (v3.2+):
    - WriteCustomFile(filename, content, [mode]) - Write to CustomData directory.
      mode: "w" (overwrite, default), "a" (append), "b" (binary).
    - ReadCustomFile(filename) - Read from CustomData directory. Returns nil if not found.
    - CustomFileExists(filename) - Check file existence in CustomData directory.
    - ExecuteCustomLuaFile(filename) - Execute a .lua file from CustomData directory.
    - ImportFile(filename) - Read from Imports directory (.txt appended automatically).
      Backwards compatibility with SuperWoW; patched security issues.
    - ExportFile(filename, text) - Write to Imports directory (.txt appended automatically).
    - CombatLogFlush() - Immediately flush combat log buffer to disk.
    - EncryptPassword(password) / EncryptedServerLogin(username, encryptedBase64) -
      GlueXML-only encrypted login helpers using Windows DPAPI.

    Chat Bubble Controls, Demon Autocast Enhancements (v3.3+):
    - Enhanced chat bubble controls via CVars: NP_ChatBubbleDistance,
      NP_ChatBubblesWhisper, NP_ChatBubblesRaid, NP_ChatBubblesBattleground.
    - NP_PreserveGreaterDemonAutocast now also saves/restores reaction states
      (aggressive/defensive/passive) including for infernal.
    - CastSpell now handles spells not in DBC gracefully.

    Environmental Damage, Damage Shield, Dispel Events (v3.4+):
    - ENVIRONMENTAL_DMG_SELF / ENVIRONMENTAL_DMG_OTHER - Environmental damage events
      (exhaustion, drowning, fall, lava, slime, fire). Params: unitGuid, dmgType,
      damage, absorb, resist. No CVar needed.
    - DAMAGE_SHIELD_SELF / DAMAGE_SHIELD_OTHER - Damage shield events (Thorns, etc.).
      Params: unitGuid, targetGuid, damage, spellSchool. No CVar needed.
    - SPELL_DISPEL_BY_SELF / SPELL_DISPEL_BY_OTHER - Spell dispel events.
      Params: casterGuid, targetGuid, spellId. No CVar needed.

    GetSpellRangeData, GUID Event Init Fix (v4.0+):
    - GetSpellRangeData(rangeIndex) - Returns minRange, maxRange, flags, name for a
      SpellRange DBC entry. flags=0 is ranged, flags=1 is melee (Combat Range).
      Use with GetSpellRecField(spellId, "rangeIndex") to look up a spell's range.
    - Hooks initialized later so _GUID events work even with old perf_boost.

    PvP Unit Data Revert (v4.1+):
    - v4.0 restricted GetUnitData/GetUnitField and suppressed BUFF/DEBUFF_ADDED/REMOVED_OTHER
      for PvP-flagged attackable units. v4.1 reverts this — the information is already
      accessible via tooltips in the base game.

    Current version: v4.0.0
]]

local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids

-- Nampower API namespace
-- Force table creation if not already a table (guards against addon conflicts)
if type(CleveRoids.NampowerAPI) ~= "table" then
    CleveRoids.NampowerAPI = {}
end
local API = CleveRoids.NampowerAPI

--------------------------------------------------------------------------------
-- VERSION DETECTION AND FEATURE FLAGS
--------------------------------------------------------------------------------

-- Cached version info (set during initialization)
API._version = { major = 0, minor = 0, patch = 0, initialized = false }

-- Get Nampower version as major, minor, patch
-- Returns 0, 0, 0 if Nampower not installed
function API.GetVersion()
    if API._version.initialized then
        return API._version.major, API._version.minor, API._version.patch
    end

    if GetNampowerVersion then
        local major, minor, patch = GetNampowerVersion()
        API._version.major = major or 0
        API._version.minor = minor or 0
        API._version.patch = patch or 0
    end
    API._version.initialized = true

    return API._version.major, API._version.minor, API._version.patch
end

-- Get version as a single comparable number (e.g., 2.18.3 -> 2018003)
function API.GetVersionNumber()
    local major, minor, patch = API.GetVersion()
    return (major * 1000000) + (minor * 1000) + patch
end

-- Check if installed version meets minimum requirement
function API.HasMinimumVersion(reqMajor, reqMinor, reqPatch)
    local major, minor, patch = API.GetVersion()

    if major > reqMajor then
        return true
    elseif major == reqMajor then
        if minor > reqMinor then
            return true
        elseif minor == reqMinor and patch >= (reqPatch or 0) then
            return true
        end
    end
    return false
end

-- Version requirements for each feature group
-- Format: { major, minor, patch, globalFunction (optional verification) }
API.VERSION_REQUIREMENTS = {
    -- v2.0+ - Base spell queuing
    ["SpellQueue"]              = { 2, 0, 0, "QueueSpellByName" },
    ["GetCurrentCastingInfo"]   = { 2, 0, 0, "GetCurrentCastingInfo" },

    -- v2.8+ - DBC data access
    ["GetSpellRec"]             = { 2, 8, 0, "GetSpellRec" },
    ["GetSpellRecField"]        = { 2, 8, 0, "GetSpellRecField" },
    ["GetItemStats"]            = { 2, 8, 0, "GetItemStats" },
    ["GetItemStatsField"]       = { 2, 8, 0, "GetItemStatsField" },
    ["GetUnitData"]             = { 2, 8, 0, "GetUnitData" },
    ["GetUnitField"]            = { 2, 8, 0, "GetUnitField" },
    ["GetSpellModifiers"]       = { 2, 8, 0, "GetSpellModifiers" },

    -- v2.11+ - GetNampowerVersion itself (meta-feature)
    ["GetNampowerVersion"]      = { 2, 11, 0, "GetNampowerVersion" },

    -- v2.12+ - Enhanced spell functions and range/usable checks
    ["EnhancedSpellFunctions"]  = { 2, 12, 0 },  -- No single function to verify
    ["IsSpellInRange"]          = { 2, 12, 0, "IsSpellInRange" },
    ["IsSpellUsable"]           = { 2, 12, 0, "IsSpellUsable" },
    ["GetSpellIdForName"]       = { 2, 12, 0, "GetSpellIdForName" },
    ["GetSpellNameAndRankForId"]= { 2, 12, 0, "GetSpellNameAndRankForId" },
    ["GetSpellSlotTypeIdForName"]={ 2, 12, 0, "GetSpellSlotTypeIdForName" },
    ["CastSpellByNameNoQueue"]  = { 2, 12, 0, "CastSpellByNameNoQueue" },
    ["QueueScript"]             = { 2, 12, 0, "QueueScript" },

    -- v2.13+ - QueueSpellByName with target parameter
    ["QueueSpellWithTarget"]    = { 2, 13, 0 },  -- Same function, new parameter

    -- v2.14+ - GetItemLevel standalone function
    ["GetItemLevel"]            = { 2, 14, 0, "GetItemLevel" },

    -- v2.18+ - Inventory, equipment, detailed cast/cooldown info
    ["FindPlayerItemSlot"]      = { 2, 18, 0, "FindPlayerItemSlot" },
    ["GetEquippedItems"]        = { 2, 18, 0, "GetEquippedItems" },
    ["GetEquippedItem"]         = { 2, 18, 0, "GetEquippedItem" },
    ["GetBagItems"]             = { 2, 18, 0, "GetBagItems" },
    ["GetBagItem"]              = { 2, 18, 0, "GetBagItem" },
    ["GetCastInfo"]             = { 2, 18, 0, "GetCastInfo" },
    ["GetSpellIdCooldown"]      = { 2, 18, 0, "GetSpellIdCooldown" },
    ["GetItemIdCooldown"]       = { 2, 18, 0, "GetItemIdCooldown" },
    ["ChannelStopCastingNextTick"]={ 2, 18, 0, "ChannelStopCastingNextTick" },

    -- v2.20+ - Trinket API, item usage, copy parameter support, aura cast events
    ["GetTrinkets"]             = { 2, 20, 0, "GetTrinkets" },
    ["GetTrinketCooldown"]      = { 2, 20, 0, "GetTrinketCooldown" },
    ["UseTrinket"]              = { 2, 20, 0, "UseTrinket" },
    ["UseItemIdOrName"]         = { 2, 20, 0, "UseItemIdOrName" },
    ["CopyParameter"]           = { 2, 20, 0 },  -- Table copy support
    ["AuraCastEvents"]          = { 2, 20, 0 },  -- AURA_CAST_ON_SELF/OTHER events

    -- v2.22+ - Utility functions
    ["DisenchantAll"]           = { 2, 22, 0, "DisenchantAll" },

    -- v2.23+ - Enhanced bag queries, cooldown item metadata
    ["GetBagItemsWithIndex"]    = { 2, 23, 0 },  -- GetBagItems(bagIndex) parameter
    ["CooldownItemMetadata"]    = { 2, 23, 0 },  -- itemId, itemHasActiveSpell, itemActiveSpellId

    -- v2.24+ - Auto-attack events
    ["AutoAttackEvents"]        = { 2, 24, 0 },  -- AUTO_ATTACK_SELF/OTHER events

    -- v2.25+ - Spell start/go/failed/delayed/channel events
    ["SpellStartEvents"]        = { 2, 25, 0 },  -- SPELL_START_SELF/OTHER events
    ["SpellGoEvents"]           = { 2, 25, 0 },  -- SPELL_GO_SELF/OTHER events
    ["SpellFailedEvents"]       = { 2, 25, 0 },  -- SPELL_FAILED_SELF/OTHER events
    ["SpellDelayedEvents"]      = { 2, 25, 0 },  -- SPELL_DELAYED_SELF/OTHER events (OTHER does not fire; server only sends to affected player)
    ["SpellChannelEvents"]      = { 2, 25, 0 },  -- SPELL_CHANNEL_START / SPELL_CHANNEL_UPDATE events (self-only)

    -- v2.26+ - Spell heal/energize events
    ["SpellHealEvents"]         = { 2, 26, 0 },  -- SPELL_HEAL_BY_SELF/OTHER/ON_SELF events
    ["SpellEnergizeEvents"]     = { 2, 26, 0 },  -- SPELL_ENERGIZE_BY_SELF/OTHER/ON_SELF events

    -- v2.27+ - Texture lookup functions
    ["GetItemIconTexture"]      = { 2, 27, 0, "GetItemIconTexture" },
    ["GetSpellIconTexture"]     = { 2, 27, 0, "GetSpellIconTexture" },

    -- v2.28+ - Nameplate GUID via CSimpleFrame:GetName(1)
    ["NameplateGUID"]           = { 2, 28, 0 },

    -- v2.29+ - Ammo query
    ["GetAmmo"]                 = { 2, 29, 0, "GetAmmo" },

    -- v2.30+ - Aura slot extensions
    ["AuraSlotParameter"]       = { 2, 30, 0 },
    ["AuraDurationEvents"]      = { 2, 30, 0 },
    ["GetPlayerAuraDuration"]   = { 2, 30, 0, "GetPlayerAuraDuration" },

    -- v2.31+ - Spell miss events and spell power query
    ["SpellMissEvents"]         = { 2, 31, 0 },  -- SPELL_MISS_SELF/OTHER events
    ["GetSpellPower"]           = { 2, 31, 0, "GetSpellPower" },

    -- v2.32+ - Aura event state parameter and stack removal fix
    ["AuraEventState"]          = { 2, 32, 0 },

    -- v2.33+ - UPDATE_DURATION spellId parameter and GetCastInfo guid fix
    ["DurationEventSpellId"]    = { 2, 33, 0 },
    ["GetCastInfoGuidFix"]      = { 2, 33, 0 },


    -- v2.34+ - Aura cancel functions
    ["CancelPlayerAuraSlot"]    = { 2, 34, 0, "CancelPlayerAuraSlot" },
    ["CancelPlayerAuraSpellId"] = { 2, 34, 0, "CancelPlayerAuraSpellId" },


    -- v2.35+ - GUID string fix and talent helper
    ["GuidStringFormat"]        = { 2, 35, 0 },  -- GetUnitData/GetUnitField return GUID fields as hex strings
    ["LearnTalentRank"]         = { 2, 35, 0, "LearnTalentRank" },

    -- v2.36+ - Player state functions
    ["PlayerIsMoving"]          = { 2, 36, 0, "PlayerIsMoving" },
    ["PlayerIsRooted"]          = { 2, 36, 0, "PlayerIsRooted" },
    ["PlayerIsSwimming"]        = { 2, 36, 0, "PlayerIsSwimming" },

    -- v2.37+ - Unit token cast support and SetMouseoverUnit
    ["CastSpellByNameUnitToken"]= { 2, 37, 0 },  -- CastSpellByName accepts unit token strings as 2nd param
    ["SetMouseoverUnit"]        = { 2, 37, 0, "SetMouseoverUnit" },

    -- v2.38+ - GetSpellDuration and enhanced SPELL_START parameters
    ["GetSpellDuration"]        = { 2, 38, 0, "GetSpellDuration" },
    ["SpellStartSpellType"]     = { 2, 38, 0 },  -- duration + spellType params added to SPELL_START events

    -- v2.39+ - Unit GUID events and granular unit event CVars
    ["UnitGuidEvents"]          = { 2, 39, 0 },  -- UNIT_HEALTH_GUID, UNIT_MANA_GUID, etc.
    ["UnitCombatGuid"]          = { 2, 39, 0 },  -- UNIT_COMBAT_GUID event
    ["UnitEventGranularControl"]= { 2, 39, 0 },  -- NP_EnableUnitEvents* CVars

    -- v2.40+ - Corpse GUID param in spell events and packed GUID fix
    ["SpellStartCorpseParam"]   = { 2, 40, 0 },  -- arg9=corpseOwnerGuid added to SPELL_START events
    ["SpellGoCorpseParam"]      = { 2, 40, 0 },  -- arg8=corpseOwnerGuid added to SPELL_GO events
    ["PackedGuidFix"]           = { 2, 40, 0 },  -- Fix for packed GUID parsing (target showed as 0x000000000)

    -- v2.41+ - Keyboard events and extended unit token support
    ["KeyEvents"]               = { 2, 41, 0 },  -- KEY_DOWN / KEY_UP events (keyboard input events)
    ["ExtendedUnitTokens"]      = { 2, 41, 0 },  -- Internal unit token resolution now supports "owner"/"target"/"pet"/"mark" in all Nampower functions (SetMouseoverUnit, UseItemIdOrName, etc.)

    -- v3.0+ - GetUnitGUID rename, IsAuraHidden, hidden aura luaSlot fix
    ["GetUnitGUID"]             = { 3, 0, 0, "GetUnitGUID" },
    ["IsAuraHidden"]            = { 3, 0, 0, "IsAuraHidden" },
    ["HiddenAuraLuaSlotFix"]    = { 3, 0, 0 },

    -- v3.1+ - CastSpellNoQueue by ID, SPELL_CAST_EVENT target default
    ["CastSpellNoQueue"]            = { 3, 1, 0, "CastSpellNoQueue" },  -- Cast by spell ID without queueing; accepts optional unit token
    ["SpellCastEventDefaultTarget"] = { 3, 1, 0 },  -- SPELL_CAST_EVENT targetGuid now defaults to current target instead of null GUID

    -- v3.2+ - File I/O, combat log flush, encrypted login (GlueXML), backwards-compatible import/export
    ["WriteCustomFile"]         = { 3, 2, 0, "WriteCustomFile" },
    ["ReadCustomFile"]          = { 3, 2, 0, "ReadCustomFile" },
    ["CustomFileExists"]        = { 3, 2, 0, "CustomFileExists" },
    ["ExecuteCustomLuaFile"]    = { 3, 2, 0, "ExecuteCustomLuaFile" },
    ["ImportFile"]              = { 3, 2, 0, "ImportFile" },
    ["ExportFile"]              = { 3, 2, 0, "ExportFile" },
    ["CombatLogFlush"]          = { 3, 2, 0, "CombatLogFlush" },

    -- v3.3+ - Chat bubble controls, demon autocast reaction state preservation
    ["ChatBubbleControls"]      = { 3, 3, 0 },  -- NP_ChatBubbleDistance, NP_ChatBubblesWhisper, NP_ChatBubblesRaid, NP_ChatBubblesBattleground
    ["DemonAutocastReactions"]  = { 3, 3, 0 },  -- NP_PreserveGreaterDemonAutocast now saves/restores reaction states including infernal

    -- v3.4+ - Environmental damage, damage shield, dispel events
    ["EnvironmentalDmgEvents"]  = { 3, 4, 0 },  -- ENVIRONMENTAL_DMG_SELF/OTHER events
    ["DamageShieldEvents"]      = { 3, 4, 0 },  -- DAMAGE_SHIELD_SELF/OTHER events
    ["SpellDispelEvents"]       = { 3, 4, 0 },  -- SPELL_DISPEL_BY_SELF/OTHER events

    -- v4.0+ - GetSpellRangeData, GUID event init fix
    ["GetSpellRangeData"]       = { 4, 0, 0, "GetSpellRangeData" },
    ["GuidEventInitFix"]        = { 4, 0, 0 },  -- _GUID events now work with old perf_boost (hooks initialized later)

    -- v4.1+ - Revert PvP unit data restrictions from v4.0
    ["PvpUnitDataRevert"]       = { 4, 1, 0 },  -- GetUnitData/GetUnitField no longer restricted for PvP-flagged units; BUFF/DEBUFF events restored
}

-- Check if a specific feature is available
-- Uses both version check AND function existence verification
function API.HasFeature(featureName)
    local req = API.VERSION_REQUIREMENTS[featureName]
    if not req then
        return false
    end

    -- Check version requirement
    if not API.HasMinimumVersion(req[1], req[2], req[3]) then
        return false
    end

    -- If a global function is specified, verify it exists
    if req[4] then
        return _G[req[4]] ~= nil
    end

    return true
end

-- Get the minimum version required for a feature
-- Returns major, minor, patch or nil if feature unknown
function API.GetFeatureVersion(featureName)
    local req = API.VERSION_REQUIREMENTS[featureName]
    if req then
        return req[1], req[2], req[3]
    end
    return nil
end

-- Feature flags (populated during initialization)
-- These provide quick boolean lookups after init
API.features = {}

-- Initialize all feature flags based on version detection
local function InitializeFeatures()
    local f = API.features

    -- Initialize version cache first
    API.GetVersion()

    -- Base Nampower detection (v2.0+)
    f.hasNampower = API.HasFeature("SpellQueue")
    f.hasSpellQueue = f.hasNampower
    f.hasGetCurrentCastingInfo = API.HasFeature("GetCurrentCastingInfo")

    -- v2.8+ DBC data access
    f.hasGetSpellRec = API.HasFeature("GetSpellRec")
    f.hasGetSpellRecField = API.HasFeature("GetSpellRecField")
    f.hasGetItemStats = API.HasFeature("GetItemStats")
    f.hasGetItemStatsField = API.HasFeature("GetItemStatsField")
    f.hasGetUnitData = API.HasFeature("GetUnitData")
    f.hasGetUnitField = API.HasFeature("GetUnitField")
    f.hasGetSpellModifiers = API.HasFeature("GetSpellModifiers")

    -- v2.11+ GetNampowerVersion
    f.hasGetNampowerVersion = API.HasFeature("GetNampowerVersion")

    -- v2.12+ Enhanced spell functions
    f.hasEnhancedSpellFunctions = API.HasFeature("EnhancedSpellFunctions")
    f.hasIsSpellInRange = API.HasFeature("IsSpellInRange")
    f.hasIsSpellUsable = API.HasFeature("IsSpellUsable")
    f.hasGetSpellIdForName = API.HasFeature("GetSpellIdForName")
    f.hasGetSpellNameAndRankForId = API.HasFeature("GetSpellNameAndRankForId")
    f.hasGetSpellSlotTypeIdForName = API.HasFeature("GetSpellSlotTypeIdForName")
    f.hasCastSpellByNameNoQueue = API.HasFeature("CastSpellByNameNoQueue")
    f.hasQueueScript = API.HasFeature("QueueScript")

    -- v2.13+ QueueSpellByName with target
    f.hasQueueSpellWithTarget = API.HasFeature("QueueSpellWithTarget")

    -- v2.14+ GetItemLevel
    f.hasGetItemLevel = API.HasFeature("GetItemLevel")

    -- v2.18+ Inventory/Equipment/Cast info
    f.hasFindPlayerItemSlot = API.HasFeature("FindPlayerItemSlot")
    f.hasGetEquippedItems = API.HasFeature("GetEquippedItems")
    f.hasGetEquippedItem = API.HasFeature("GetEquippedItem")
    f.hasGetBagItems = API.HasFeature("GetBagItems")
    f.hasGetBagItem = API.HasFeature("GetBagItem")
    f.hasGetCastInfo = API.HasFeature("GetCastInfo")
    f.hasGetSpellIdCooldown = API.HasFeature("GetSpellIdCooldown")
    f.hasGetItemIdCooldown = API.HasFeature("GetItemIdCooldown")
    f.hasChannelStopCastingNextTick = API.HasFeature("ChannelStopCastingNextTick")

    -- v2.20+ Trinket/Item API and Aura Cast Events
    f.hasGetTrinkets = API.HasFeature("GetTrinkets")
    f.hasGetTrinketCooldown = API.HasFeature("GetTrinketCooldown")
    f.hasUseTrinket = API.HasFeature("UseTrinket")
    f.hasUseItemIdOrName = API.HasFeature("UseItemIdOrName")
    f.hasCopyParameter = API.HasFeature("CopyParameter")
    f.hasAuraCastEvents = API.HasFeature("AuraCastEvents")

    -- v2.22+ Utility functions
    f.hasDisenchantAll = API.HasFeature("DisenchantAll")

    -- v2.23+ Enhanced features
    f.hasGetBagItemsWithIndex = API.HasFeature("GetBagItemsWithIndex")
    f.hasCooldownItemMetadata = API.HasFeature("CooldownItemMetadata")

    -- v2.24+ Auto-attack events
    f.hasAutoAttackEvents = API.HasFeature("AutoAttackEvents")

    -- v2.25+ Spell start/go/failed/delayed/channel events
    f.hasSpellStartEvents = API.HasFeature("SpellStartEvents")
    f.hasSpellGoEvents = API.HasFeature("SpellGoEvents")
    f.hasSpellFailedEvents = API.HasFeature("SpellFailedEvents")
    f.hasSpellDelayedEvents = API.HasFeature("SpellDelayedEvents")
    f.hasSpellChannelEvents = API.HasFeature("SpellChannelEvents")

    -- v2.26+ Spell heal/energize events
    f.hasSpellHealEvents = API.HasFeature("SpellHealEvents")
    f.hasSpellEnergizeEvents = API.HasFeature("SpellEnergizeEvents")

    -- v2.27+ Texture lookup functions
    f.hasGetItemIconTexture = API.HasFeature("GetItemIconTexture")
    f.hasGetSpellIconTexture = API.HasFeature("GetSpellIconTexture")

    -- v2.28+ Nameplate GUID
    f.hasNameplateGUID = API.HasFeature("NameplateGUID")

    -- v2.29+ Ammo query
    f.hasGetAmmo = API.HasFeature("GetAmmo")

    -- v2.30+ Aura slot extensions
    f.hasAuraSlotParameter = API.HasFeature("AuraSlotParameter")
    f.hasAuraDurationEvents = API.HasFeature("AuraDurationEvents")
    f.hasGetPlayerAuraDuration = API.HasFeature("GetPlayerAuraDuration")

    -- v2.31+ Spell miss events and spell power
    f.hasSpellMissEvents = API.HasFeature("SpellMissEvents")
    f.hasGetSpellPower = API.HasFeature("GetSpellPower")

    -- v2.32+ Aura event state parameter
    f.hasAuraEventState = API.HasFeature("AuraEventState")

    -- v2.33+ Duration event spellId and GetCastInfo guid fix
    f.hasDurationEventSpellId = API.HasFeature("DurationEventSpellId")
    f.hasGetCastInfoGuidFix = API.HasFeature("GetCastInfoGuidFix")

    -- v2.34+ Aura cancel functions
    f.hasCancelPlayerAuraSlot = API.HasFeature("CancelPlayerAuraSlot")
    f.hasCancelPlayerAuraSpellId = API.HasFeature("CancelPlayerAuraSpellId")

    -- v2.35+ GUID string format and talent helper
    f.hasGuidStringFormat = API.HasFeature("GuidStringFormat")
    f.hasLearnTalentRank = API.HasFeature("LearnTalentRank")

    -- v2.36+ Player state functions
    f.hasPlayerIsMoving = API.HasFeature("PlayerIsMoving")
    f.hasPlayerIsRooted = API.HasFeature("PlayerIsRooted")
    f.hasPlayerIsSwimming = API.HasFeature("PlayerIsSwimming")

    -- v2.37+ Unit token cast support and SetMouseoverUnit
    f.hasCastSpellByNameUnitToken = API.HasFeature("CastSpellByNameUnitToken")
    f.hasSetMouseoverUnit = API.HasFeature("SetMouseoverUnit")

    -- v2.38+ GetSpellDuration and enhanced SPELL_START parameters
    f.hasGetSpellDuration = API.HasFeature("GetSpellDuration")
    f.hasSpellStartSpellType = API.HasFeature("SpellStartSpellType")

    -- v2.39+ Unit GUID events and granular unit event CVars
    f.hasUnitGuidEvents = API.HasFeature("UnitGuidEvents")
    f.hasUnitCombatGuid = API.HasFeature("UnitCombatGuid")
    f.hasUnitEventGranularControl = API.HasFeature("UnitEventGranularControl")

    -- v2.40+ Corpse GUID param in spell events and packed GUID fix
    f.hasSpellStartCorpseParam = API.HasFeature("SpellStartCorpseParam")
    f.hasSpellGoCorpseParam = API.HasFeature("SpellGoCorpseParam")
    f.hasPackedGuidFix = API.HasFeature("PackedGuidFix")

    -- v2.41+ Keyboard events and extended unit token support
    f.hasKeyEvents = API.HasFeature("KeyEvents")
    f.hasExtendedUnitTokens = API.HasFeature("ExtendedUnitTokens")

    -- v3.0+ GetUnitGUID, IsAuraHidden, hidden aura luaSlot fix
    f.hasGetUnitGUID = API.HasFeature("GetUnitGUID")
    f.hasIsAuraHidden = API.HasFeature("IsAuraHidden")
    f.hasHiddenAuraLuaSlotFix = API.HasFeature("HiddenAuraLuaSlotFix")

    -- v3.1+ CastSpellNoQueue by ID, SPELL_CAST_EVENT default target
    f.hasCastSpellNoQueue = API.HasFeature("CastSpellNoQueue")
    f.hasSpellCastEventDefaultTarget = API.HasFeature("SpellCastEventDefaultTarget")

    -- v3.2+ File I/O, combat log flush, backwards-compatible import/export
    f.hasWriteCustomFile = API.HasFeature("WriteCustomFile")
    f.hasReadCustomFile = API.HasFeature("ReadCustomFile")
    f.hasCustomFileExists = API.HasFeature("CustomFileExists")
    f.hasExecuteCustomLuaFile = API.HasFeature("ExecuteCustomLuaFile")
    f.hasImportFile = API.HasFeature("ImportFile")
    f.hasExportFile = API.HasFeature("ExportFile")
    f.hasCombatLogFlush = API.HasFeature("CombatLogFlush")

    -- v3.3+ Chat bubble controls, demon autocast enhancements
    f.hasChatBubbleControls = API.HasFeature("ChatBubbleControls")
    f.hasDemonAutocastReactions = API.HasFeature("DemonAutocastReactions")

    -- v3.4+ Environmental damage, damage shield, dispel events
    f.hasEnvironmentalDmgEvents = API.HasFeature("EnvironmentalDmgEvents")
    f.hasDamageShieldEvents = API.HasFeature("DamageShieldEvents")
    f.hasSpellDispelEvents = API.HasFeature("SpellDispelEvents")

    -- v4.0+ GetSpellRangeData, GUID event init fix
    f.hasGetSpellRangeData = API.HasFeature("GetSpellRangeData")
    f.hasGuidEventInitFix = API.HasFeature("GuidEventInitFix")

    -- v4.1+ Revert PvP unit data restrictions
    f.hasPvpUnitDataRevert = API.HasFeature("PvpUnitDataRevert")

    -- Runtime detection for enhanced spell functions (verify by testing)
    if f.hasEnhancedSpellFunctions and GetSpellTexture then
        local success, result = pcall(function()
            return GetSpellTexture("Attack")
        end)
        f.hasEnhancedSpellFunctions = success and (result ~= nil)
    end
end

-- Legacy function for compatibility (now just calls InitializeFeatures)
local function DetectEnhancedSpellFunctions()
    return API.features.hasEnhancedSpellFunctions
end

-- Initialize features immediately on load
InitializeFeatures()

--------------------------------------------------------------------------------
-- UnitBuff/UnitDebuff spell ID hooks (loaded at file load time)
-- Nampower v2.8+ GetUnitField 复刻 SuperWoW 的 UnitBuff/UnitDebuff 扩展返回值：
--   UnitBuff 追加第 3 返回值 spellID，UnitDebuff 追加第 4 返回值 spellID。
-- 必须在本文件加载时安装（早于 Utility.lua 的 `local _UnitDebuff = UnitDebuff`
-- 别名捕获），否则 Utility 的别名会持有未 hook 的原函数导致 spellID 缺失。
-- GetUnitField "aura" returns [1-32]=buff spellIDs, [33-48]=debuff spellIDs
--
-- 自检测透传：若底层 UnitBuff/UnitDebuff 已返回 spellID（SuperWoW 的 C 级补丁
-- 在 Lua 加载前就已增强这两个函数），则原样透传、绝不丢弃——SuperWoW 的实现
-- 在 texture 非空时保证 spellID 非空，而 GetUnitField 查询在单位对象未加载或
-- 隐藏光环导致槽位错位时可能返回 nil，会把 ShaguPlatesX 等按 SuperWoW 语义
-- 消费第 3/4 返回值的插件打崩（seen[nil] → "table index is nil"）。 by 武藤纯子酱 2026.9.1
--------------------------------------------------------------------------------
local function InstallAuraSpellIdHooks()
    if not _G.GetUnitField then return end     -- Need GetUnitField for aura data

    local _origUnitBuff = _G.UnitBuff
    local _origUnitDebuff = _G.UnitDebuff

    -- UnitBuff(unit, index, castable) => texture, stacks, spellID
    -- 修复：透传第 3 参数 castable（1.12 原生"仅显示我施放的 buff"过滤）。
    -- 原签名 (unit, index) 会吞掉该参数，导致 sRaidFrames 等按 castable 过滤
    -- buff 的团队框架过滤失效——所有人的药剂/合剂等 buff 全部显示 by 武藤纯子酱 2026.9.9
    _G.UnitBuff = function(unit, index, castable)
        local texture, stacks, firstExtra = _origUnitBuff(unit, index, castable)
        if not texture then return nil end

        -- SuperWoW 环境下原函数第 3 返回值即 spellID——直接透传 by 武藤纯子酱 2026.9.1
        if firstExtra then return texture, stacks, firstExtra end

        local spellID = nil
        local auras = _G.GetUnitField(unit, "aura")
        if auras then
            -- Buff index i maps to aura slot i (1-based)
            spellID = auras[index]
            if spellID and spellID <= 0 then spellID = nil end
        end

        return texture, stacks, spellID
    end

    -- UnitDebuff(unit, index, mask) => texture, stacks, debuffType, spellID
    -- 修复：透传第 3 参数 mask（1.12 原生"仅显示可驱散 debuff"过滤），同上 by 武藤纯子酱 2026.9.9
    _G.UnitDebuff = function(unit, index, mask)
        local texture, stacks, debuffType, firstExtra = _origUnitDebuff(unit, index, mask)
        if not texture then return nil end

        -- SuperWoW 环境下原函数第 4 返回值即 spellID——直接透传 by 武藤纯子酱 2026.9.1
        if firstExtra then return texture, stacks, debuffType, firstExtra end

        local spellID = nil
        local auras = _G.GetUnitField(unit, "aura")
        if auras then
            -- Debuff index i maps to aura slot 32 + i (1-based)
            spellID = auras[32 + index]
            if spellID and spellID <= 0 then spellID = nil end
        end

        return texture, stacks, debuffType, spellID
    end

    API.auraSpellIdHooksInstalled = true
end

-- Install immediately (Nampower v2.8+ GetUnitField available at load time)
InstallAuraSpellIdHooks()

-- 加载时立即回填 aura spellID 可用性标志 by 武藤纯子酱 2026.9.1：
-- Core.lua 顶层（早于 ADDON_LOADED）有依赖此标志的判断（如 AuraScanTooltip 是否创建）
CleveRoids.hasAuraSpellIds = (API.features.hasGetUnitField == true) and (API.auraSpellIdHooksInstalled == true)

--------------------------------------------------------------------------------
-- NAMPOWER SETTINGS ACCESS
--------------------------------------------------------------------------------

-- Cache for settings to avoid repeated lookups
API.settingsCache = {}
API.settingsCacheTime = 0
API.SETTINGS_CACHE_DURATION = 5  -- Refresh every 5 seconds

-- All known Nampower CVars with their defaults
API.defaultSettings = {
    NP_QueueCastTimeSpells = "1",
    NP_QueueInstantSpells = "1",
    NP_QueueChannelingSpells = "1",
    NP_QueueTargetingSpells = "1",
    NP_QueueOnSwingSpells = "0",
    NP_QueueSpellsOnCooldown = "1",
    NP_InterruptChannelsOutsideQueueWindow = "0",
    NP_SpellQueueWindowMs = "500",
    NP_OnSwingBufferCooldownMs = "500",
    NP_ChannelQueueWindowMs = "1500",
    NP_TargetingQueueWindowMs = "500",
    NP_CooldownQueueWindowMs = "250",
    NP_MinBufferTimeMs = "55",
    NP_NonGcdBufferTimeMs = "100",
    NP_MaxBufferIncreaseMs = "30",
    NP_RetryServerRejectedSpells = "1",
    NP_QuickcastTargetingSpells = "0",
    NP_QuickcastOnDoubleCast = "0",  -- v2.18+: cast targeting spells by double-casting
    NP_ReplaceMatchingNonGcdCategory = "0",
    NP_OptimizeBufferUsingPacketTimings = "0",
    NP_PreventRightClickTargetChange = "0",
    NP_PreventRightClickPvPAttack = "1",
    NP_DoubleCastToEndChannelEarly = "0",
    NP_SpamProtectionEnabled = "1",
    NP_ChannelLatencyReductionPercentage = "75",
    NP_NameplateDistance = "41",
    -- v2.20+ CVars
    NP_PreventMountingWhenBuffCapped = "1",  -- Prevent mounting when buff capped (32 buffs)
    NP_EnableAuraCastEvents = "0",  -- Enable AURA_CAST_ON_SELF/OTHER events
    -- v2.24+ CVars
    NP_EnableAutoAttackEvents = "0",  -- Enable AUTO_ATTACK_SELF/OTHER events
    -- v2.25+ CVars
    NP_EnableSpellStartEvents = "0",  -- Enable SPELL_START_SELF/OTHER events
    NP_EnableSpellGoEvents = "0",     -- Enable SPELL_GO_SELF/OTHER events
    -- v2.26+ CVars
    NP_EnableSpellHealEvents = "0",   -- Enable SPELL_HEAL_BY_SELF/OTHER/ON_SELF events
    NP_EnableSpellEnergizeEvents = "0", -- Enable SPELL_ENERGIZE_BY_SELF/OTHER/ON_SELF events
    -- v2.39+ CVars
    NP_EnableUnitEventsPet = "1",       -- Fire unit events for pet/partypet1-4 tokens
    NP_EnableUnitEventsParty = "1",     -- Fire unit events for party1-4 tokens
    NP_EnableUnitEventsRaid = "1",      -- Fire unit events for raid1-40 tokens
    NP_EnableUnitEventsMouseover = "1", -- Fire unit events for mouseover token
    NP_EnableUnitEventsGuid = "1",      -- Fire UNIT_* events using raw GUID as unit token (mimics SuperWoW)
    NP_EnableUnitEventsGuidFiltering = "1", -- Suppress high-freq raw GUID events that have _GUID variants
    -- v3.1+ CVars
    NP_PreserveGreaterDemonAutocast = "1",  -- Remember/restore greater demon autocast preferences (v3.3+: also saves reaction states incl. infernal)
    -- v3.3+ CVars
    NP_ChatBubbleDistance = "60",            -- Max distance for chat bubbles
    NP_ChatBubblesWhisper = "0",             -- Show chat bubbles for whispers
    NP_ChatBubblesRaid = "0",                -- Show chat bubbles for raid leader/warning
    NP_ChatBubblesBattleground = "0",        -- Show chat bubbles for battleground chat
}

-- Get a Nampower setting value
-- Priority: NampowerSettings addon (per-character) > CVar > default
function API.GetSetting(settingName)
    -- Check if NampowerSettings addon is loaded and has per-character settings enabled
    if Nampower and Nampower.db and Nampower.db.profile then
        if Nampower.db.profile.per_character_settings and Nampower.db.profile[settingName] ~= nil then
            return Nampower.db.profile[settingName]
        end
    end

    -- Fall back to CVar
    local cvarValue = GetCVar(settingName)
    if cvarValue then
        return cvarValue
    end

    -- Return default if known
    return API.defaultSettings[settingName]
end

-- Get a Nampower setting as a boolean
function API.GetSettingBool(settingName)
    local value = API.GetSetting(settingName)
    if type(value) == "boolean" then
        return value
    end
    return value == "1" or value == true
end

-- Get a Nampower setting as a number
function API.GetSettingNumber(settingName)
    local value = API.GetSetting(settingName)
    return tonumber(value) or 0
end

-- Check if spell queuing is enabled for a given spell type
function API.IsQueueingEnabled(spellType)
    if not API.features.hasNampower then
        return false
    end

    if spellType == "cast" or spellType == "casttime" then
        return API.GetSettingBool("NP_QueueCastTimeSpells")
    elseif spellType == "instant" or spellType == "gcd" then
        return API.GetSettingBool("NP_QueueInstantSpells")
    elseif spellType == "channel" or spellType == "channeling" then
        return API.GetSettingBool("NP_QueueChannelingSpells")
    elseif spellType == "targeting" or spellType == "aoe" then
        return API.GetSettingBool("NP_QueueTargetingSpells")
    elseif spellType == "onswing" or spellType == "swing" then
        return API.GetSettingBool("NP_QueueOnSwingSpells")
    elseif spellType == "cooldown" then
        return API.GetSettingBool("NP_QueueSpellsOnCooldown")
    end

    -- Default: all queuing enabled
    return API.GetSettingBool("NP_QueueCastTimeSpells")
end

-- Check if ANY spell queuing is enabled
function API.IsAnyQueueingEnabled()
    if not API.features.hasNampower then
        return false
    end

    -- Check all spell type queuing settings
    return API.GetSettingBool("NP_QueueCastTimeSpells")
        or API.GetSettingBool("NP_QueueInstantSpells")
        or API.GetSettingBool("NP_QueueChannelingSpells")
        or API.GetSettingBool("NP_QueueOnSwingSpells")
end

-- Get the queue window for a given spell type (in seconds)
function API.GetQueueWindow(spellType)
    local ms = 500  -- default

    if spellType == "channel" or spellType == "channeling" then
        ms = API.GetSettingNumber("NP_ChannelQueueWindowMs")
    elseif spellType == "targeting" or spellType == "aoe" then
        ms = API.GetSettingNumber("NP_TargetingQueueWindowMs")
    elseif spellType == "cooldown" then
        ms = API.GetSettingNumber("NP_CooldownQueueWindowMs")
    elseif spellType == "onswing" or spellType == "swing" then
        ms = API.GetSettingNumber("NP_OnSwingBufferCooldownMs")
    else
        ms = API.GetSettingNumber("NP_SpellQueueWindowMs")
    end

    return ms / 1000  -- Convert to seconds
end

--------------------------------------------------------------------------------
-- SPELL RECORD API (GetSpellRec / GetSpellRecField)
--------------------------------------------------------------------------------

-- Cache for spell records
API.spellRecCache = {}

-- Get full spell record data
-- Returns nil if spell not found or API unavailable (requires v2.8+)
-- Pass copy=1 to get an independent copy safe for storage (v2.20+)
-- WARNING: Without copy, table references are reused - extract values immediately!
function API.GetSpellRecord(spellId, copy)
    if not spellId or spellId == 0 then return nil end

    -- Requires v2.8+ for GetSpellRec
    if not API.features.hasGetSpellRec then
        return nil
    end

    -- Check cache first (only for non-copy requests)
    if not copy and API.spellRecCache[spellId] then
        return API.spellRecCache[spellId]
    end

    -- Copy parameter requires v2.20+
    -- When caching (not copy), also request copy=1 if available for safe storage
    -- This prevents issues with Nampower's table reuse
    local useCopy = nil
    if API.features.hasCopyParameter then
        useCopy = copy or 1  -- Use caller's copy value, or 1 for caching
    end

    -- Use native function
    if GetSpellRec then
        local rec = GetSpellRec(spellId, useCopy)
        if rec then
            if not copy then
                API.spellRecCache[spellId] = rec
            end
            return rec
        end
    end

    return nil
end

-- Get a specific field from spell record
-- Returns nil if not found (requires v2.8+)
-- Pass copy=1 to get an independent copy for array fields (v2.20+)
function API.GetSpellField(spellId, fieldName, copy)
    if not spellId or spellId == 0 then return nil end

    -- Requires v2.8+ for GetSpellRecField
    if not API.features.hasGetSpellRecField then
        return nil
    end

    -- Copy parameter requires v2.20+
    local useCopy = copy and API.features.hasCopyParameter and copy or nil

    -- Use native function (more efficient for single field)
    if GetSpellRecField then
        local success, result = pcall(GetSpellRecField, spellId, fieldName, useCopy)
        if success then
            return result
        end
        return nil
    end

    -- Fallback to full record lookup
    local rec = API.GetSpellRecord(spellId, copy)
    if rec then
        return rec[fieldName]
    end

    return nil
end

-- Get spell name by ID (enhanced, uses new API when available)
function API.GetSpellNameById(spellId)
    if not spellId or spellId == 0 then return nil end

    -- Try GetSpellNameAndRankForId first (Nampower function)
    if GetSpellNameAndRankForId then
        local name, rank = GetSpellNameAndRankForId(spellId)
        if name then return name, rank end
    end

    -- Fall back to GetSpellRecField
    if GetSpellRecField then
        local name = GetSpellRecField(spellId, "name")
        local rank = GetSpellRecField(spellId, "rank")
        if name then return name, rank end
    end

    return nil
end

-- Get spell cast time in seconds
function API.GetSpellCastTime(spellId)
    local castTime = API.GetSpellField(spellId, "castTime")
    if castTime then
        return castTime / 1000  -- Convert from ms to seconds
    end
    return nil
end

-- Get spell school (0=Physical, 1=Holy, 2=Fire, 3=Nature, 4=Frost, 5=Shadow, 6=Arcane)
function API.GetSpellSchool(spellId)
    return API.GetSpellField(spellId, "school")
end

-- Get spell mana cost
function API.GetSpellManaCost(spellId)
    return API.GetSpellField(spellId, "manaCost")
end

-- SpellRange.dbc lookup table: rangeIndex -> maxRange (in yards)
-- From vanilla 1.12.1 client data (corrected based on actual spell ranges)
API.SpellRangeTable = {
    [0] = 0,      -- Self Only
    [1] = 5,      -- Combat Range (Melee)
    [2] = 30,     -- 30 yard range (Frostbolt, etc.)
    [3] = 35,     -- 35 yard range
    [4] = 30,     -- 30 yard range (Arcane Missiles, etc.)
    [5] = 40,     -- 40 yard range
    [6] = 45,     -- 45 yard range
    [7] = 100,    -- Vision Range
    [8] = 20,     -- 20 yard range
    [9] = 10,     -- 10 yard range
    [10] = 8,     -- 8 yard range
    [11] = 15,    -- 15 yard range (Charge)
    [12] = 25,    -- 25 yard range
    [13] = 100,   -- Anywhere/Unlimited
    [14] = 0,     -- Self Only (alternate)
    [15] = 80,    -- 80 yard range (hunters)
    [16] = 18,    -- 18 yard range
    [17] = 60,    -- 60 yard range
    [18] = 5,     -- Melee (alternate)
    [19] = 25,    -- 25 yard range (alternate)
    [20] = 30,    -- 30 yard range (alternate)
    [21] = 35,    -- 35 yard range (alternate)
    [22] = 40,    -- 40 yard range (alternate)
    [23] = 0,     -- Touch
    [24] = 41,    -- 41 yard range
    [25] = 10,    -- 10 yard range (alternate)
    [26] = 50,    -- 50 yard range
    [27] = 55,    -- 55 yard range
    [28] = 65,    -- 65 yard range
    [29] = 70,    -- 70 yard range
    [30] = 50000, -- Unlimited
    [31] = 8,     -- 8 yard range (alternate)
    [32] = 7,     -- 7 yard range
    [33] = 11,    -- 11 yard range
    [34] = 12,    -- 12 yard range
    [35] = 28,    -- 28 yard range
    [36] = 6,     -- 6 yard range
    [37] = 13,    -- 13 yard range
    [38] = 15,    -- 15 yard range (alternate)
    [39] = 100,   -- 100 yard range (alternate)
    [40] = 150,   -- 150 yard range
}

-- Unit target types that require distance checking (from DBC)
-- These target OTHER units, not self - so distance matters
-- Excludes TARGET_UNIT_CASTER (1) which is self-cast and always in range
local UNIT_TARGET_TYPES_NEED_RANGE = {
    [5] = true,   -- TARGET_UNIT_PET
    [6] = true,   -- TARGET_UNIT_TARGET_ENEMY
    [21] = true,  -- TARGET_UNIT_TARGET_ALLY
    [22] = true,  -- TARGET_UNIT_PARTY
    [23] = true,  -- TARGET_UNIT_PARTY_AROUND_CASTER
    [25] = true,  -- TARGET_UNIT_PET (alternate)
    [38] = true,  -- TARGET_UNIT_TARGET_ANY
}

-- Helper to check a target value or array for unit targeting
local function checkTargetForUnitType(target)
    if not target then return nil end

    -- If it's a table (array of 3 effect targets), check each element
    if type(target) == "table" then
        for i = 1, 3 do
            local val = target[i]
            if val and UNIT_TARGET_TYPES_NEED_RANGE[val] then
                return true  -- Found a unit-targeting effect
            end
        end
        -- Check if any element has a value (even if not unit-targeting)
        for i = 1, 3 do
            if target[i] and target[i] ~= 0 then
                return false  -- Has target data but not unit-targeting
            end
        end
        return nil
    end

    -- If it's a number, check directly
    if type(target) == "number" then
        if UNIT_TARGET_TYPES_NEED_RANGE[target] then
            return true
        end
        if target ~= 0 then
            return false  -- Has target data but not unit-targeting
        end
    end

    return nil
end

-- 性能优化：静态 DBC 字段缓存（rangeIndex / 是否单位目标 / 射程）。这些值运行期不变，
-- 仅 SPELLS_CHANGED 时失效，避免每次范围检查重复 pcall+查表 by 武藤纯子酱 2026.9.11
API._rangeIndexCache = {}
API._unitTargetedCache = {}
API._spellRangeYardsCache = {}
function API.ClearSpellRangeCaches()
    API._rangeIndexCache = {}
    API._unitTargetedCache = {}
    API._spellRangeYardsCache = {}
end
if CreateFrame then
    local _rangeCacheFrame = CreateFrame("Frame")
    _rangeCacheFrame:RegisterEvent("SPELLS_CHANGED")
    _rangeCacheFrame:SetScript("OnEvent", function() API.ClearSpellRangeCaches() end)
end

-- 带缓存的 rangeIndex（0 是合法值，用 false 作“无值”哨兵）
function API.GetSpellRangeIndexCached(spellId)
    local c = API._rangeIndexCache[spellId]
    if c ~= nil then
        if c == false then return nil end
        return c
    end
    local v = API.GetSpellField(spellId, "rangeIndex")
    if v == nil then API._rangeIndexCache[spellId] = false; return nil end
    API._rangeIndexCache[spellId] = v
    return v
end

-- Check if a spell requires distance checking to another unit
-- Returns true if the spell targets other units (needs range check)
-- Returns false if self-cast, ground-targeted, or area effect (always "in range")
-- Returns nil if unknown
function API.IsUnitTargetedSpell(spellId)
    if not spellId or spellId == 0 then return nil end
    local cached = API._unitTargetedCache[spellId]
    if cached ~= nil then return cached end

    -- Check effectImplicitTargetA
    local targetA = API.GetSpellField(spellId, "effectImplicitTargetA")
    local resultA = checkTargetForUnitType(targetA)
    if resultA == true then
        API._unitTargetedCache[spellId] = true
        return true  -- Targets other units, needs range check
    end

    -- Also check targetB
    local targetB = API.GetSpellField(spellId, "effectImplicitTargetB")
    local resultB = checkTargetForUnitType(targetB)
    if resultB == true then
        API._unitTargetedCache[spellId] = true
        return true  -- Targets other units, needs range check
    end

    -- If either returned false (has data but not unit-targeting), spell doesn't need range check
    if resultA == false or resultB == false then
        API._unitTargetedCache[spellId] = false
        return false
    end

    return nil  -- Unknown（nil 不缓存）
end

-- Get spell range (max range in yards)
function API.GetSpellRange(spellId)
    if not spellId or spellId == 0 then return nil end
    local c = API._spellRangeYardsCache[spellId]
    if c ~= nil then
        if c == false then return nil end
        return c
    end

    local rangeIndex = API.GetSpellRangeIndexCached(spellId)
    if rangeIndex then
        -- Prefer GetSpellRangeData (v4.0+) for runtime DBC lookup (covers custom ranges)
        if API.features.hasGetSpellRangeData and _G.GetSpellRangeData then
            local minRange, maxRange, flags, name = _G.GetSpellRangeData(rangeIndex)
            if maxRange and maxRange > 0 then
                API._spellRangeYardsCache[spellId] = maxRange
                return maxRange
            end
        end

        -- Fallback: hardcoded SpellRange table
        local range = API.SpellRangeTable[rangeIndex]
        if range then
            API._spellRangeYardsCache[spellId] = range
            return range
        end
    end

    API._spellRangeYardsCache[spellId] = false
    return nil
end

-- Get spell cooldown from record (base cooldown, not current)
function API.GetSpellBaseCooldown(spellId)
    local recoveryTime = API.GetSpellField(spellId, "recoveryTime")
    if recoveryTime then
        return recoveryTime / 1000  -- Convert from ms to seconds
    end
    return nil
end

--------------------------------------------------------------------------------
-- ITEM STATS API (GetItemStats / GetItemStatsField)
--------------------------------------------------------------------------------

-- Cache for item stats
API.itemStatsCache = {}

-- Get full item stats data
-- Requires v2.8+ for GetItemStats
-- Pass copy=1 to get an independent copy safe for storage (v2.20+)
-- WARNING: Without copy, table references are reused - extract values immediately!
function API.GetItemRecord(itemId, copy)
    if not itemId or itemId == 0 then return nil end

    -- Requires v2.8+ for GetItemStats
    if not API.features.hasGetItemStats then
        return nil
    end

    -- Check cache first (only for non-copy requests)
    if not copy and API.itemStatsCache[itemId] then
        return API.itemStatsCache[itemId]
    end

    -- Copy parameter requires v2.20+
    -- When caching (not copy), also request copy=1 if available for safe storage
    -- This prevents issues with Nampower's table reuse
    local useCopy = nil
    if API.features.hasCopyParameter then
        useCopy = copy or 1  -- Use caller's copy value, or 1 for caching
    end

    -- Use native function
    if GetItemStats then
        local ok, stats = pcall(GetItemStats, itemId, useCopy)
        if ok and stats then
            if not copy then
                API.itemStatsCache[itemId] = stats
            end
            return stats
        end
    end

    return nil
end

-- Get a specific field from item stats
-- Requires v2.8+ for GetItemStatsField
-- Pass copy=1 to get an independent copy for array fields (v2.20+)
function API.GetItemField(itemId, fieldName, copy)
    if not itemId or itemId == 0 then return nil end

    -- Requires v2.8+ for GetItemStatsField
    if not API.features.hasGetItemStatsField then
        return nil
    end

    -- Copy parameter requires v2.20+
    local useCopy = copy and API.features.hasCopyParameter and copy or nil

    -- Use native function (more efficient)
    if GetItemStatsField then
        local success, result = pcall(GetItemStatsField, itemId, fieldName, useCopy)
        if success then
            return result
        end
        return nil
    end

    -- Fallback to full record lookup
    local stats = API.GetItemRecord(itemId, copy)
    if stats then
        return stats[fieldName]
    end

    return nil
end

-- Get item level
-- Uses standalone GetItemLevel (v2.14+) or falls back to GetItemStatsField (v2.8+)
function API.GetItemLevel(itemId)
    -- Use dedicated function if available (v2.14+)
    if API.features.hasGetItemLevel and GetItemLevel then
        local success, result = pcall(GetItemLevel, itemId)
        if success then return result end
    end

    -- Fallback to GetItemField (v2.8+)
    return API.GetItemField(itemId, "itemLevel")
end

-- Get item name
function API.GetItemName(itemId)
    return API.GetItemField(itemId, "displayName")
end

-- Get item quality (0=Poor, 1=Common, 2=Uncommon, 3=Rare, 4=Epic, 5=Legendary)
function API.GetItemQuality(itemId)
    return API.GetItemField(itemId, "quality")
end

-- Get weapon speed in seconds
function API.GetWeaponSpeed(itemId)
    local delay = API.GetItemField(itemId, "delay")
    if delay then
        return delay / 1000
    end
    return nil
end

-- Get item inventory type (equipment slot)
-- Returns: inventoryType number, or nil if not equippable
-- Common types: 0=Non-equip, 1=Head, 2=Neck, 3=Shoulder, 4=Shirt, 5=Chest,
--               6=Waist, 7=Legs, 8=Feet, 9=Wrist, 10=Hands, 11=Finger, 12=Trinket,
--               13=One-Hand, 14=Shield, 15=Ranged, 16=Back, 17=Two-Hand,
--               18=Bag, 20=Robe, 21=Main Hand, 22=Off Hand, 23=Holdable,
--               24=Ammo, 25=Thrown, 26=Ranged Right, 28=Relic
function API.GetItemInventoryType(itemId)
    local ok, result = pcall(API.GetItemField, itemId, "inventoryType")
    if ok then return result end
    return nil
end

-- Convert inventoryType to equipment slot ID(s)
-- Returns slotId, altSlotId (for rings/trinkets)
API.inventoryTypeToSlot = {
    [1] = 1,       -- Head -> HeadSlot
    [2] = 2,       -- Neck -> NeckSlot
    [3] = 3,       -- Shoulder -> ShoulderSlot
    [4] = 4,       -- Shirt -> ShirtSlot
    [5] = 5,       -- Chest -> ChestSlot
    [6] = 6,       -- Waist -> WaistSlot
    [7] = 7,       -- Legs -> LegsSlot
    [8] = 8,       -- Feet -> FeetSlot
    [9] = 9,       -- Wrist -> WristSlot
    [10] = 10,     -- Hands -> HandsSlot
    [11] = {11, 12}, -- Finger -> Finger0Slot or Finger1Slot
    [12] = {13, 14}, -- Trinket -> Trinket0Slot or Trinket1Slot
    [13] = 16,     -- One-Hand -> MainHandSlot (can also go off-hand)
    [14] = 17,     -- Shield -> SecondaryHandSlot
    [15] = 18,     -- Ranged -> RangedSlot
    [16] = 15,     -- Back -> BackSlot
    [17] = 16,     -- Two-Hand -> MainHandSlot
    [20] = 5,      -- Robe -> ChestSlot
    [21] = 16,     -- Main Hand -> MainHandSlot
    [22] = 17,     -- Off Hand -> SecondaryHandSlot
    [23] = 17,     -- Holdable -> SecondaryHandSlot
    [24] = 0,      -- Ammo -> AmmoSlot
    [25] = 18,     -- Thrown -> RangedSlot
    [26] = 18,     -- Ranged Right -> RangedSlot
    [28] = 18,     -- Relic -> RangedSlot
}

-- Get equipment slot ID for an item
-- Returns slotId, altSlotId for items that can go in multiple slots
function API.GetItemEquipSlot(itemId)
    local ok, invType = pcall(API.GetItemInventoryType, itemId)
    if not ok or not invType or invType == 0 then return nil end

    local slotInfo = API.inventoryTypeToSlot[invType]
    if type(slotInfo) == "table" then
        return slotInfo[1], slotInfo[2]  -- Primary and alt slot
    end
    return slotInfo, nil
end

--------------------------------------------------------------------------------
-- UNIT DATA API (GetUnitData / GetUnitField) - Requires v2.8+
--------------------------------------------------------------------------------

-- Get full unit data (no caching - unit data changes frequently)
-- Requires v2.8+ for GetUnitData
-- Pass copy=1 to get an independent copy safe for storage (v2.20+)
-- WARNING: Without copy, table references are reused - extract values immediately!
function API.GetUnitRecord(unitToken, copy)
    if not unitToken then return nil end

    -- Requires v2.8+ for GetUnitData
    if not API.features.hasGetUnitData then
        return nil
    end

    -- Copy parameter requires v2.20+
    local useCopy = copy and API.features.hasCopyParameter and copy or nil

    if GetUnitData then
        return GetUnitData(unitToken, useCopy)
    end

    return nil
end

-- Get a specific unit field
-- Requires v2.8+ for GetUnitField
-- Pass copy=1 to get an independent copy for array fields (v2.20+)
function API.GetUnitFieldValue(unitToken, fieldName, copy)
    if not unitToken then return nil end

    -- Requires v2.8+ for GetUnitField
    if not API.features.hasGetUnitField then
        return nil
    end

    -- Copy parameter requires v2.20+
    local useCopy = copy and API.features.hasCopyParameter and copy or nil

    -- Use native function (more efficient)
    if GetUnitField then
        local success, result = pcall(GetUnitField, unitToken, fieldName, useCopy)
        if success then
            return result
        end
        return nil
    end

    -- Fallback to full record
    local data = API.GetUnitRecord(unitToken, copy)
    if data then
        return data[fieldName]
    end

    return nil
end

-- Get unit's current auras as spell IDs
-- Pass copy=1 to get an independent copy safe for storage (v2.20+)
function API.GetUnitAuras(unitToken, copy)
    return API.GetUnitFieldValue(unitToken, "aura", copy)
end

-- Get unit resistances table
-- Pass copy=1 to get an independent copy safe for storage (v2.20+)
function API.GetUnitResistances(unitToken, copy)
    return API.GetUnitFieldValue(unitToken, "resistances", copy)
end

-- Get specific resistance value
-- school: 1=Armor, 2=Holy, 3=Fire, 4=Nature, 5=Frost, 6=Shadow, 7=Arcane
function API.GetUnitResistance(unitToken, school)
    local resistances = API.GetUnitResistances(unitToken)
    if resistances and school then
        return resistances[school]
    end
    return nil
end

-- Check if unit has a specific aura by spell ID
function API.UnitHasAura(unitToken, spellId)
    local auras = API.GetUnitAuras(unitToken)
    if not auras or not spellId then return false end

    for _, auraId in ipairs(auras) do
        if auraId == spellId then
            return true
        end
    end
    return false
end

-- Get unit's aura stack counts (auraApplications field)
-- Pass copy=1 to get an independent copy safe for storage (v2.20+)
function API.GetUnitAuraApplications(unitToken, copy)
    return API.GetUnitFieldValue(unitToken, "auraApplications", copy)
end

-- Composite helper: Search unit's auras for a spell by ID or lowercase name,
-- returning match info with stack count from auraApplications.
--
-- Parameters:
--   unitToken       - Unit token (e.g., "target", "focus")
--   searchSpellId   - Spell ID to match (number), or nil for name search
--   searchNameLower - Lowercase spell name to match (string), or nil for ID search
--
-- Returns:
--   nil                              - GetUnitField unavailable (caller should use slow path)
--   false                            - Searched but aura not found
--   true, matchedSpellId, stacks, slotIndex - Found; slotIndex 1-32 = buff, 33-48 = debuff
function API.FindUnitAuraInfo(unitToken, searchSpellId, searchNameLower)
    if not unitToken then return nil end
    if not searchSpellId and not searchNameLower then return nil end

    local auras = API.GetUnitAuras(unitToken)
    if not auras then return nil end  -- GetUnitField unavailable

    local applications = API.GetUnitAuraApplications(unitToken)

    for i = 1, 48 do
        local auraId = auras[i]
        if auraId and auraId ~= 0 then
            local matched = false

            if searchSpellId then
                matched = (auraId == searchSpellId)
            elseif searchNameLower then
                local name = GetSpellRecField and GetSpellRecField(auraId, "name")
                if name then
                    -- Strip rank suffix for consistent matching
                    local baseName = CleveRoids.StripRank(name)
                    if string.lower(baseName) == searchNameLower then
                        matched = true
                    end
                end
            end

            if matched then
                -- auraApplications is 0-indexed (0 = 1 stack); convert to 1-indexed
                local stacks = applications and (applications[i] or 0) + 1 or 0
                return true, auraId, stacks, i
            end
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- INVENTORY & EQUIPMENT API (v2.18+)
--------------------------------------------------------------------------------

-- Find an item in player's inventory by ID or name
-- Requires v2.18+ for native FindPlayerItemSlot (with Lua fallback)
-- Returns: bagIndex, slot (see wiki for bag index meanings)
-- bagIndex nil + slot = equipped item (slot is equipment slot 0-18)
-- bagIndex + slot = item in bag
-- nil, nil = item not found
function API.FindPlayerItemSlot(itemIdOrName)
    if not itemIdOrName then return nil, nil end

    -- Use native function if available (v2.18+)
    if API.features.hasFindPlayerItemSlot and FindPlayerItemSlot then
        return FindPlayerItemSlot(itemIdOrName)
    end

    -- Fallback: manual search for older versions
    -- This is much slower but works without Nampower 2.18
    local itemName = itemIdOrName
    if type(itemIdOrName) == "number" then
        -- Try to get item name from ID
        itemName = API.GetItemName(itemIdOrName)
        if not itemName then
            -- Try GetItemInfo as fallback (only works for cached items)
            itemName = GetItemInfo(itemIdOrName)
        end
        if not itemName then
            return nil, nil  -- Can't resolve item ID
        end
    end

    -- Search equipped items first (WoW API uses 1-19 for inventory slots)
    for slot = 1, 19 do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local name = GetItemInfo(link)
            if name and string.lower(name) == string.lower(itemName) then
                return nil, slot  -- Equipped (1-indexed, matches Nampower behavior)
            end
        end
    end

    -- Search bags (0 = backpack, 1-4 = bags)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local name = GetItemInfo(link)
                if name and string.lower(name) == string.lower(itemName) then
                    return bag, slot
                end
            end
        end
    end

    return nil, nil  -- Not found
end

-- Get all equipped items for a unit
-- Requires v2.18+ for native GetEquippedItems (with Lua fallback for player only)
-- Returns table with slot indices (0-18) as keys, item info tables as values
function API.GetEquippedItems(unitToken)
    unitToken = unitToken or "player"
    -- 注：原生 GetEquippedItems 路径有 BUG，已禁用，统一走下方 fallback by 武藤纯子酱 2025.12.25
    -- Fallback: manual lookup for player only
    if unitToken ~= "player" then
        return nil  -- Can't inspect other units without native API
    end

    local items = {}
    for slot = 0, 18 do
        local link = GetInventoryItemLink("player", slot + 1)
        if link then
            local _, _, itemId = string.find(link, "item:(%d+)")
            if itemId then
                items[slot] = {
                    itemId = tonumber(itemId),
                    -- Other fields not available without native API
                }
            end
        end
    end

    return items
end

-- Get equipped item info for a specific slot
-- Requires v2.18+ for native GetEquippedItem (with Lua fallback for player only)
-- Slot numbers: 1=Head, 2=Neck, 3=Shoulder... 16=MainHand, 17=OffHand, 18=Ranged
function API.GetEquippedItem(unitToken, slot)
    unitToken = unitToken or "player"

    -- Use native function if available (v2.18+)
    if API.features.hasGetEquippedItem and GetEquippedItem then
        return GetEquippedItem(unitToken, slot)
    end

    -- Fallback: manual lookup for player
    if unitToken ~= "player" then
        return nil
    end

    local link = GetInventoryItemLink("player", slot + 1)  -- 1-indexed
    if link then
        local _, _, itemId = string.find(link, "item:(%d+)")
        if itemId then
            return {
                itemId = tonumber(itemId),
            }
        end
    end

    return nil
end

-- Get all items in bags, or items in a specific bag
-- Requires v2.18+ for native GetBagItems (with Lua fallback)
-- bagIndex parameter requires v2.23+
-- If bagIndex is nil: returns nested table: bagIndex -> { slot -> itemInfo }
-- If bagIndex is specified: returns single table: slot -> itemInfo for that bag only
-- Bag indices: 0=backpack, 1-4=bags, -1=bank slots, 5-10=bank bags, -2=keyring
function API.GetBagItems(bagIndex)
    -- Use native function if available (v2.18+)
    if API.features.hasGetBagItems and GetBagItems then
        -- bagIndex parameter requires v2.23+
        if bagIndex ~= nil and not API.features.hasGetBagItemsWithIndex then
            -- Fall through to Lua fallback for single-bag query on older versions
        else
            return GetBagItems(bagIndex)
        end
    end

    -- Fallback: manual enumeration
    if bagIndex ~= nil then
        -- Single bag query
        local bagContents = {}
        local numSlots = GetContainerNumSlots(bagIndex) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bagIndex, slot)
            if link then
                local _, _, itemId = string.find(link, "item:(%d+)")
                local _, count = GetContainerItemInfo(bagIndex, slot)
                if itemId then
                    bagContents[slot] = {
                        itemId = tonumber(itemId),
                        stackCount = count or 1,
                    }
                end
            end
        end
        return bagContents
    end

    -- All bags query
    local bags = {}
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        if numSlots > 0 then
            bags[bag] = {}
            for slot = 1, numSlots do
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, itemId = string.find(link, "item:(%d+)")
                    local _, count = GetContainerItemInfo(bag, slot)
                    if itemId then
                        bags[bag][slot] = {
                            itemId = tonumber(itemId),
                            stackCount = count or 1,
                        }
                    end
                end
            end
        end
    end

    return bags
end

-- Get item info for a specific bag slot
-- Requires v2.18+ for native GetBagItem (with Lua fallback)
function API.GetBagItem(bagIndex, slot)
    -- Use native function if available (v2.18+)
    if API.features.hasGetBagItem and GetBagItem then
        return GetBagItem(bagIndex, slot)
    end

    -- Fallback: manual lookup
    local link = GetContainerItemLink(bagIndex, slot)
    if link then
        local _, _, itemId = string.find(link, "item:(%d+)")
        local _, count = GetContainerItemInfo(bagIndex, slot)
        if itemId then
            return {
                itemId = tonumber(itemId),
                stackCount = count or 1,
            }
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- 装备槽编号自动校准（Equipped-slot numbering auto-calibration） by 武藤纯子酱 2026.8.31
--------------------------------------------------------------------------------
-- 背景：不同 Nampower 版本对"已装备物品"的槽位编号可能不一致——
--   FindPlayerItemSlot：官方文档标注装备槽返回 0-18（0 基），但部分版本实测返回 1-19（1 基）
--   GetEquippedItem / GetEquippedItems：官方文档标注 1-19（1 基），同样可能存在版本差异
-- 因此既不信任文档、也不硬编码偏移：用玩家当前已装备物品的 vanilla 槽位（1-19，
-- 与 GetInventoryItemLink / UseInventoryItem / PickupInventoryItem 的编号一致）
-- 与 API 的实际返回值现场比对，得出偏移量并缓存：
--   _findSlotOffset    = vanilla槽位 - FindPlayerItemSlot返回值   （0 = 1基, 1 = 0基）
--   _equippedKeyOffset = vanilla槽位 - GetEquippedItem(s) 键/入参 （0 = 1基, 1 = 0基）
-- 检测结果只取决于所加载的 nampower 版本，装备更换不影响编号规则，无需失效；
-- 若检测时玩家物品尚未就绪，会在后续调用中自动重试。
--------------------------------------------------------------------------------
local _findSlotOffset = nil
local _equippedKeyOffset = nil

local function DetectEquippedSlotOffsets()
    if _findSlotOffset and _equippedKeyOffset then return end

    for vslot = 1, 19 do
        local link = GetInventoryItemLink("player", vslot)
        if link then
            local _, _, idStr = string.find(link, "item:(%d+)")
            local id = tonumber(idStr)
            if id then
                -- 校准 FindPlayerItemSlot 的装备槽编号 by 武藤纯子酱 2026.8.31
                if not _findSlotOffset and FindPlayerItemSlot then
                    local b, s = FindPlayerItemSlot(id)
                    if b == nil and s then
                        local diff = vslot - s
                        if diff == 0 or diff == 1 then
                            _findSlotOffset = diff
                            if CleveRoids.debug then
                                CleveRoids.Print("|cff88ff88[NampowerAPI]|r 校准：FindPlayerItemSlot 装备槽编号 = " .. (diff == 0 and "1-19（1基）" or "0-18（0基）"))
                            end
                        end
                    end
                end

                -- 校准 GetEquippedItem 的槽位编号（两个候选槽位只有一个命中该物品，避免同 ID 邻位误判） by 武藤纯子酱 2026.8.31
                if not _equippedKeyOffset and GetEquippedItem then
                    local itV = GetEquippedItem("player", vslot)
                    local itV1 = (vslot > 1) and GetEquippedItem("player", vslot - 1) or nil
                    local atV = (itV and itV.itemId == id) or false
                    local atV1 = (itV1 and itV1.itemId == id) or false
                    if atV and not atV1 then
                        _equippedKeyOffset = 0
                        if CleveRoids.debug then
                            CleveRoids.Print("|cff88ff88[NampowerAPI]|r 校准：GetEquippedItem 槽位编号 = 1-19（1基）")
                        end
                    elseif atV1 and not atV then
                        _equippedKeyOffset = 1
                        if CleveRoids.debug then
                            CleveRoids.Print("|cff88ff88[NampowerAPI]|r 校准：GetEquippedItem 槽位编号 = 0-18（0基）")
                        end
                    end
                end

                if _findSlotOffset and _equippedKeyOffset then return end
            end
        end
    end
end

-- FindPlayerItemSlot 的装备槽返回值 → vanilla 槽位（1-19）
function API.FindSlotToVanillaSlot(slot)
    if not _findSlotOffset then
        DetectEquippedSlotOffsets()
    end
    -- 检测失败时按官方文档（0-18，0 基）兜底 by 武藤纯子酱 2026.8.31
    return slot + (_findSlotOffset or 1)
end

-- GetEquippedItem/GetEquippedItems 的键/入参 → vanilla 槽位（1-19）
function API.EquippedKeyToVanillaSlot(key)
    if not _equippedKeyOffset then
        DetectEquippedSlotOffsets()
    end
    -- 检测失败时按官方文档（1-19，1 基）兜底 by 武藤纯子酱 2026.8.31
    return key + (_equippedKeyOffset or 0)
end

-- vanilla 槽位（1-19） → GetEquippedItem 入参
function API.VanillaSlotToEquippedKey(vslot)
    if not _equippedKeyOffset then
        DetectEquippedSlotOffsets()
    end
    return vslot - (_equippedKeyOffset or 0)
end

--------------------------------------------------------------------------------
-- OPTIMIZED ITEM FINDING (v2.18+)
-- These functions provide fast item lookup compatible with CleveRoids.Items format
--------------------------------------------------------------------------------

-- Fast item lookup using v2.18 FindPlayerItemSlot
-- Returns item info table compatible with CleveRoids.Items format:
--   { name, itemId, inventoryID } for equipped items
--   { name, itemId, bagID, slot } for bag items
-- Returns nil if item not found
function API.FindItemFast(itemIdOrName)
    if not itemIdOrName then return nil end

    -- Use native v2.18 function if available (much faster than Lua scan)
    if FindPlayerItemSlot then
        local bag, slot = FindPlayerItemSlot(itemIdOrName)

        if slot then
            local itemInfo = {}

            if bag == nil then
                -- 已装备物品：槽位编号经自动校准（0基/1基都兼容，见 DetectEquippedSlotOffsets）；
                -- 依次尝试「校准值、原值、原值+1」三个候选，并用查到的物品 ID 与搜索目标比对，
                -- 命中即返回——即使校准兜底值与实际版本不符也能自愈 by 武藤纯子酱 2026.8.31
                local searchedId = tonumber(itemIdOrName)
                local candidates = { API.FindSlotToVanillaSlot(slot), slot, slot + 1 }
                for ci = 1, table.getn(candidates) do
                    local invSlot = candidates[ci]
                    if invSlot and invSlot >= 1 and invSlot <= 19 then
                        local link = GetInventoryItemLink("player", invSlot)
                        if link then
                            local _, _, itemId = string.find(link, "item:(%d+)")
                            itemId = tonumber(itemId)
                            -- 第一个候选（校准值）直接可信；其余候选仅在 ID 比对命中时才接受 by 武藤纯子酱 2026.8.31
                            if ci == 1 or searchedId == nil or itemId == searchedId then
                                local _, _, name = string.find(link, "|h%[(.-)%]|h")
                                itemInfo.inventoryID = invSlot
                                itemInfo.itemId = itemId
                                itemInfo.name = name
                                itemInfo._source = "nampower_equipped"
                                return itemInfo
                            end
                        end
                    end
                end
            else
                -- Bag item
                local link = GetContainerItemLink(bag, slot)
                if link then
                    local _, _, itemId = string.find(link, "item:(%d+)")
                    local _, _, name = string.find(link, "|h%[(.-)%]|h")
                    local _, count = GetContainerItemInfo(bag, slot)
                    itemInfo.bagID = bag
                    itemInfo.slot = slot
                    itemInfo.itemId = tonumber(itemId)
                    itemInfo.name = name
                    itemInfo.count = count or 1
                    itemInfo._source = "nampower_bag"
                    return itemInfo
                end
            end
        end

        return nil  -- Not found via native lookup
    end

    -- Fallback: no v2.18 API, return nil (caller should use existing methods)
    return nil
end

-- Check if an item is equipped in a specific slot (fast)
-- Returns true if item matches by ID or name
function API.IsItemInSlot(itemIdOrName, inventorySlot)
    if not itemIdOrName or not inventorySlot then return false end

    -- Use native v2.18 GetEquippedItem if available
    -- 修复：必须用特性标志判断，否则兼容层空桩会让 `if GetEquippedItem` 恒真、永远 return false by 武藤纯子酱 2026.9.11
    if API.features.hasGetEquippedItem and GetEquippedItem then
        -- 槽位编号自动校准（不同版本可能 0-18 或 1-19，见 DetectEquippedSlotOffsets），不硬编码偏移 by 武藤纯子酱 2026.8.31
        local slotInfo = GetEquippedItem("player", API.VanillaSlotToEquippedKey(inventorySlot))
        if slotInfo and slotInfo.itemId then
            local checkId = tonumber(itemIdOrName)
            if checkId then
                return slotInfo.itemId == checkId
            else
                -- Check by name
                local itemName = API.GetItemName(slotInfo.itemId)
                if itemName then
                    return string.lower(itemName) == string.lower(itemIdOrName)
                end
            end
        end
        return false
    end

    -- Fallback: use GetInventoryItemLink
    local link = GetInventoryItemLink("player", inventorySlot)
    if not link then return false end

    local checkId = tonumber(itemIdOrName)
    if checkId then
        local _, _, currentId = string.find(link, "item:(%d+)")
        return currentId and tonumber(currentId) == checkId
    else
        local _, _, currentName = string.find(link, "|h%[(.-)%]|h")
        return currentName and string.lower(currentName) == string.lower(itemIdOrName)
    end
end

-- Check if item is equipped anywhere (fast)
-- Returns inventorySlot if equipped, nil otherwise
function API.FindEquippedItem(itemIdOrName)
    if not itemIdOrName then return nil end

    -- Use native v2.18 FindPlayerItemSlot if available
    if FindPlayerItemSlot then
        local bag, slot = FindPlayerItemSlot(itemIdOrName)
        if bag == nil and slot then
            return slot  -- Nampower returns 1-indexed slot directly
        end
        return nil  -- Not equipped (might be in bag or not found)
    end

    -- Fallback: scan equipped slots
    local checkId = tonumber(itemIdOrName)
    local checkName = (not checkId) and string.lower(itemIdOrName) or nil

    for invSlot = 1, 19 do
        local link = GetInventoryItemLink("player", invSlot)
        if link then
            if checkId then
                local _, _, currentId = string.find(link, "item:(%d+)")
                if currentId and tonumber(currentId) == checkId then
                    return invSlot
                end
            elseif checkName then
                local _, _, currentName = string.find(link, "|h%[(.-)%]|h")
                if currentName and string.lower(currentName) == checkName then
                    return invSlot
                end
            end
        end
    end

    return nil
end

-- Find item in bags only (not equipped) - fast
-- Returns bag, slot if found, nil otherwise
function API.FindBagItem(itemIdOrName)
    if not itemIdOrName then return nil, nil end

    -- Use native v2.18 FindPlayerItemSlot if available
    if FindPlayerItemSlot then
        local bag, slot = FindPlayerItemSlot(itemIdOrName)
        if bag ~= nil and slot then
            return bag, slot
        end
        return nil, nil  -- Not in bags (might be equipped or not found)
    end

    -- Fallback: scan bags
    local checkId = tonumber(itemIdOrName)
    local checkName = (not checkId) and string.lower(itemIdOrName) or nil

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                if checkId then
                    local _, _, currentId = string.find(link, "item:(%d+)")
                    if currentId and tonumber(currentId) == checkId then
                        return bag, slot
                    end
                elseif checkName then
                    local _, _, currentName = string.find(link, "|h%[(.-)%]|h")
                    if currentName and string.lower(currentName) == checkName then
                        return bag, slot
                    end
                end
            end
        end
    end

    return nil, nil
end

-- Use an item by ID or name (fast lookup)
-- Returns true if item was used, false otherwise
function API.UseItem(itemIdOrName)
    if not itemIdOrName then return false end

    -- Try native v2.18 lookup first
    local itemInfo = API.FindItemFast(itemIdOrName)
    if itemInfo then
        ClearCursor()
        if itemInfo.inventoryID then
            UseInventoryItem(itemInfo.inventoryID)
            return true
        elseif itemInfo.bagID and itemInfo.slot then
            UseContainerItem(itemInfo.bagID, itemInfo.slot)
            return true
        end
    end

    -- No v2.18 API or item not found via native lookup
    return false
end

-- Equip an item from bags to a specific slot (fast lookup)
-- Returns true if equip was attempted, false if item not found
function API.EquipItem(itemIdOrName, targetSlot)
    if not itemIdOrName then return false end

    -- Check if already equipped in target slot
    if targetSlot and API.IsItemInSlot(itemIdOrName, targetSlot) then
        return true  -- Already equipped
    end

    -- Find the item
    local itemInfo = API.FindItemFast(itemIdOrName)
    if not itemInfo then return false end

    -- If already equipped (but not in target slot), need to swap
    if itemInfo.inventoryID then
        if targetSlot and itemInfo.inventoryID ~= targetSlot then
            -- Item equipped in wrong slot - pick up and move
            ClearCursor()
            PickupInventoryItem(itemInfo.inventoryID)
            if CursorHasItem and CursorHasItem() then
                EquipCursorItem(targetSlot)
                ClearCursor()
                return true
            end
        end
        return true  -- Already equipped (and no target slot specified)
    end

    -- Item in bag - equip it
    if itemInfo.bagID and itemInfo.slot then
        ClearCursor()
        PickupContainerItem(itemInfo.bagID, itemInfo.slot)
        if CursorHasItem and CursorHasItem() then
            if targetSlot then
                EquipCursorItem(targetSlot)
            else
                -- Auto-equip to appropriate slot
                AutoEquipCursorItem()
            end
            ClearCursor()
            return true
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- CAST INFO API (v2.18+)
--------------------------------------------------------------------------------

-- Get detailed information about current cast/channel
-- Requires v2.18+ for native GetCastInfo (with GetCurrentCastingInfo fallback for v2.0+)
-- Returns table with: castId, spellId, guid, castType, castStartS, castEndS,
--                     castRemainingMs, castDurationMs, gcdEndS, gcdRemainingMs
-- Returns nil if no active cast
function API.GetCastInfo()
    -- Use native function if available (v2.18+)
    if API.features.hasGetCastInfo and GetCastInfo then
        local ok, result = pcall(GetCastInfo)
        if ok then
            return result
        end
        -- If pcall failed, fall through to fallback
    end

    -- Fallback: use GetCurrentCastingInfo (less detailed, v2.0+)
    if API.features.hasGetCurrentCastingInfo and GetCurrentCastingInfo then
        local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()
        if castId and castId > 0 then
            return {
                spellId = castId,
                castType = channeling == 1 and 3 or 0,  -- 3 = CHANNEL, 0 = NORMAL
                -- Timing info not available without native GetCastInfo
            }
        end
    end

    return nil
end

-- Check if currently casting (convenience wrapper)
function API.IsCasting()
    local info = API.GetCastInfo()
    return info ~= nil
end

-- Cached spell ID for GCD queries via GetSpellIdCooldown
local _gcdProbeSpellId = nil

-- Get GCD remaining in milliseconds
-- Uses GetSpellIdCooldown (works for instant casts) with GetCastInfo as fast-path
function API.GetGCDRemainingMs()
    -- Fast path: GetCastInfo reports GCD during active casts/channels
    local info = API.GetCastInfo()
    if info and info.gcdRemainingMs and info.gcdRemainingMs > 0 then
        return info.gcdRemainingMs
    end

    -- Primary path: GetSpellIdCooldown reads GCD from spell history (works after instant casts)
    if API.features.hasGetSpellIdCooldown and _G.GetSpellIdCooldown then
        -- Get a probe spell ID: first spell in the spellbook
        if not _gcdProbeSpellId then
            local name = GetSpellName(1, BOOKTYPE_SPELL)
            if name and _G.GetSpellIdForName then
                _gcdProbeSpellId = _G.GetSpellIdForName(name)
            end
        end
        if _gcdProbeSpellId then
            local cd = _G.GetSpellIdCooldown(_gcdProbeSpellId)
            if cd and cd.gcdCategoryRemainingMs and cd.gcdCategoryRemainingMs > 0 then
                return cd.gcdCategoryRemainingMs
            end
        end
    end

    return 0
end

-- Get cast remaining in milliseconds
function API.GetCastRemainingMs()
    local info = API.GetCastInfo()
    if info and info.castRemainingMs then
        return info.castRemainingMs
    end
    return 0
end

--------------------------------------------------------------------------------
-- COOLDOWN API (v2.18+)
--------------------------------------------------------------------------------

-- Get detailed cooldown information for a spell
-- Requires v2.18+ for native GetSpellIdCooldown (with GetSpellCooldown fallback)
-- Returns table with: isOnCooldown, cooldownRemainingMs,
--   individual cooldown: individualStartS, individualDurationMs, individualRemainingMs, isOnIndividualCooldown
--   category cooldown: categoryId, categoryStartS, categoryDurationMs, categoryRemainingMs, isOnCategoryCooldown
--   GCD: gcdCategoryId, gcdCategoryStartS, gcdCategoryDurationMs, gcdCategoryRemainingMs, isOnGcdCategoryCooldown
--   item metadata (v2.23+): itemId, itemHasActiveSpell, itemActiveSpellId
function API.GetSpellCooldownInfo(spellId)
    if not spellId or spellId == 0 then return nil end

    -- Use native function if available (v2.18+)
    if API.features.hasGetSpellIdCooldown and GetSpellIdCooldown then
        return GetSpellIdCooldown(spellId)
    end

    -- Fallback: use GetSpellCooldown (less detailed)
    local spellName = API.GetSpellNameById(spellId)
    if spellName then
        local start, duration = GetSpellCooldown(spellName, BOOKTYPE_SPELL)
        if start and start > 0 then
            local remaining = (start + duration) - GetTime()
            if remaining > 0 then
                return {
                    isOnCooldown = 1,
                    cooldownRemainingMs = remaining * 1000,
                }
            end
        end
    end

    return { isOnCooldown = 0, cooldownRemainingMs = 0 }
end

-- Get detailed cooldown information for an item
-- Requires v2.18+ for native GetItemIdCooldown (with GetItemCooldown fallback)
-- Returns same table structure as GetSpellCooldownInfo
-- v2.23+ adds: itemId, itemHasActiveSpell, itemActiveSpellId
function API.GetItemCooldownInfo(itemId)
    if not itemId or itemId == 0 then return nil end

    -- Use native function if available (v2.18+)
    if API.features.hasGetItemIdCooldown and GetItemIdCooldown then
        return GetItemIdCooldown(itemId)
    end

    -- Fallback: use GetItemCooldown (less detailed)
    local start, duration = GetItemCooldown(itemId)
    if start and start > 0 then
        local remaining = (start + duration) - GetTime()
        if remaining > 0 then
            return {
                isOnCooldown = 1,
                cooldownRemainingMs = remaining * 1000,
            }
        end
    end

    return { isOnCooldown = 0, cooldownRemainingMs = 0 }
end

-- Check if a spell is on cooldown (ignoring GCD)
function API.IsSpellOnCooldown(spellId, ignoreGCD)
    local info = API.GetSpellCooldownInfo(spellId)
    if not info then return false end

    if ignoreGCD then
        -- Only check individual and category cooldowns
        return (info.isOnIndividualCooldown == 1) or (info.isOnCategoryCooldown == 1)
    end

    return info.isOnCooldown == 1
end

-- Get remaining cooldown for a spell in seconds
function API.GetSpellCooldownRemaining(spellId)
    local info = API.GetSpellCooldownInfo(spellId)
    if info and info.cooldownRemainingMs then
        return info.cooldownRemainingMs / 1000
    end
    return 0
end

--------------------------------------------------------------------------------
-- CHANNEL CONTROL API (v2.18+)
--------------------------------------------------------------------------------

-- Stop channeling early on the next tick
-- Requires v2.18+ for ChannelStopCastingNextTick
-- Only works if NP_QueueChannelingSpells is enabled
function API.StopChannelNextTick()
    if API.features.hasChannelStopCastingNextTick and ChannelStopCastingNextTick then
        ChannelStopCastingNextTick()
        return true
    end
    return false
end

--------------------------------------------------------------------------------
-- TRINKET API (v2.20+)
--------------------------------------------------------------------------------

-- Trinket slot constants
API.TRINKET_SLOT = {
    FIRST = 13,   -- First trinket slot (slot 13 in equipment)
    SECOND = 14,  -- Second trinket slot (slot 14 in equipment)
}

-- Get all trinkets (equipped and in bags)
-- Requires v2.20+ for native GetTrinkets (with Lua fallback)
-- Returns table with: itemId, trinketName, texture, itemLevel, bagIndex (nil=equipped), slotIndex
-- Pass copy=1 to get an independent copy safe for storage (v2.20+)
function API.GetTrinkets(copy)
    -- Use native function if available (v2.20+)
    if API.features.hasGetTrinkets and GetTrinkets then
        -- Copy parameter supported in v2.20+
        return GetTrinkets(copy)
    end

    -- Fallback: manual enumeration
    local trinkets = {}
    local index = 1

    -- Check equipped trinket slots (13 and 14)
    for _, slot in ipairs({13, 14}) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local _, _, itemId = string.find(link, "item:(%d+)")
            local _, _, name = string.find(link, "|h%[(.-)%]|h")
            local texture = GetInventoryItemTexture("player", slot)
            if itemId then
                local numItemId = tonumber(itemId)
                local itemLevel = API.GetItemLevel(numItemId)
                trinkets[index] = {
                    itemId = numItemId,
                    trinketName = name or "Unknown",
                    texture = texture,
                    itemLevel = itemLevel,
                    bagIndex = nil,  -- nil means equipped
                    slotIndex = slot == 13 and 1 or 2,
                }
                index = index + 1
            end
        end
    end

    -- Check bags for trinkets (inventoryType 12 = Trinket)
    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local _, _, itemId = string.find(link, "item:(%d+)")
                if itemId then
                    local numItemId = tonumber(itemId)
                    local invType = API.GetItemInventoryType(numItemId)
                    if invType == 12 then  -- Trinket
                        local _, _, name = string.find(link, "|h%[(.-)%]|h")
                        local texture = GetContainerItemInfo(bag, slot)
                        local itemLevel = API.GetItemLevel(numItemId)
                        trinkets[index] = {
                            itemId = numItemId,
                            trinketName = name or "Unknown",
                            texture = texture,
                            itemLevel = itemLevel,
                            bagIndex = bag,
                            slotIndex = slot,
                        }
                        index = index + 1
                    end
                end
            end
        end
    end

    return trinkets
end

-- Get cooldown for an equipped trinket
-- Requires v2.20+ for native GetTrinketCooldown (with Lua fallback)
-- slot: 1 or 13 = first trinket, 2 or 14 = second trinket
--       OR item ID (number) or item name (string) to match
-- Returns cooldown detail table (same as GetSpellIdCooldown/GetItemIdCooldown)
-- Returns -1 if no matching trinket is equipped
function API.GetTrinketCooldown(slot)
    -- Use native function if available (v2.20+)
    if API.features.hasGetTrinketCooldown and GetTrinketCooldown then
        return GetTrinketCooldown(slot)
    end

    -- Normalize slot number
    local equipSlot
    if type(slot) == "number" then
        if slot == 1 or slot == 13 then
            equipSlot = 13
        elseif slot == 2 or slot == 14 then
            equipSlot = 14
        else
            -- Treat as item ID - find in trinket slots
            for _, checkSlot in ipairs({13, 14}) do
                local link = GetInventoryItemLink("player", checkSlot)
                if link then
                    local _, _, currentId = string.find(link, "item:(%d+)")
                    if currentId and tonumber(currentId) == slot then
                        equipSlot = checkSlot
                        break
                    end
                end
            end
        end
    elseif type(slot) == "string" then
        -- Match by name
        local slotLower = string.lower(slot)
        for _, checkSlot in ipairs({13, 14}) do
            local link = GetInventoryItemLink("player", checkSlot)
            if link then
                local _, _, name = string.find(link, "|h%[(.-)%]|h")
                if name and string.lower(name) == slotLower then
                    equipSlot = checkSlot
                    break
                end
            end
        end
    end

    if not equipSlot then
        return -1  -- No matching trinket found
    end

    -- Get item ID from equipped slot
    local link = GetInventoryItemLink("player", equipSlot)
    if not link then
        return -1
    end

    local _, _, itemId = string.find(link, "item:(%d+)")
    if not itemId then
        return -1
    end

    -- Get cooldown info
    return API.GetItemCooldownInfo(tonumber(itemId))
end

-- Use an equipped trinket
-- Requires v2.20+ for native UseTrinket (with Lua fallback)
-- slot: 1 or 13 = first trinket, 2 or 14 = second trinket
--       OR item ID (number) or item name (string) to match
-- target: optional unit token or GUID
-- Returns: 1 if used, 0 if use failed, -1 if trinket not found
function API.UseTrinket(slot, target)
    -- Use native function if available (v2.20+)
    if API.features.hasUseTrinket and UseTrinket then
        return UseTrinket(slot, target)
    end

    -- Normalize slot number
    local equipSlot
    if type(slot) == "number" then
        if slot == 1 or slot == 13 then
            equipSlot = 13
        elseif slot == 2 or slot == 14 then
            equipSlot = 14
        else
            -- Treat as item ID - find in trinket slots
            for _, checkSlot in ipairs({13, 14}) do
                local link = GetInventoryItemLink("player", checkSlot)
                if link then
                    local _, _, currentId = string.find(link, "item:(%d+)")
                    if currentId and tonumber(currentId) == slot then
                        equipSlot = checkSlot
                        break
                    end
                end
            end
        end
    elseif type(slot) == "string" then
        -- Match by name
        local slotLower = string.lower(slot)
        for _, checkSlot in ipairs({13, 14}) do
            local link = GetInventoryItemLink("player", checkSlot)
            if link then
                local _, _, name = string.find(link, "|h%[(.-)%]|h")
                if name and string.lower(name) == slotLower then
                    equipSlot = checkSlot
                    break
                end
            end
        end
    end

    if not equipSlot then
        return -1  -- No matching trinket found
    end

    -- Use the trinket
    ClearCursor()
    UseInventoryItem(equipSlot)
    return 1
end

--------------------------------------------------------------------------------
-- ITEM USAGE API (v2.20+)
--------------------------------------------------------------------------------

-- Use an item by ID or name
-- Requires v2.20+ for native UseItemIdOrName (with Lua fallback)
-- itemIdOrName: item ID (number) or item name (string)
-- target: optional unit token or GUID
-- Returns: 1 if used successfully, 0 if not found or use failed
function API.UseItemIdOrName(itemIdOrName, target)
    -- Use native function if available (v2.20+)
    if API.features.hasUseItemIdOrName and UseItemIdOrName then
        return UseItemIdOrName(itemIdOrName, target)
    end

    -- Fallback: use existing API.UseItem
    if API.UseItem(itemIdOrName) then
        return 1
    end

    return 0
end

--------------------------------------------------------------------------------
-- DISENCHANT API (v2.22+)
--------------------------------------------------------------------------------

-- Automatically disenchant items in inventory
-- Requires v2.22+ for DisenchantAll (no fallback available)
-- Mode 1: DisenchantAll(itemIdOrName, [includeSoulbound]) - specific item by ID/name
-- Mode 2: DisenchantAll(quality, [includeSoulbound]) - "greens", "blues", or "greens|blues" (v2.23+)
-- includeSoulbound: pass 1 to include soulbound items (default: 0)
-- Returns: 1 if first disenchant succeeded, 0 if no items found or failed
--
-- WARNING: This function WILL disenchant items without confirmation!
-- Quest items are always protected. Soulbound items protected by default.
-- Only affects bags 0-4 (not bank).
function API.DisenchantAll(itemIdOrNameOrQuality, includeSoulbound)
    -- Use native function if available (v2.22+)
    if API.features.hasDisenchantAll and DisenchantAll then
        return DisenchantAll(itemIdOrNameOrQuality, includeSoulbound)
    end

    -- No fallback available - requires Nampower 2.22+
    return 0
end

--------------------------------------------------------------------------------
-- EVENT CONSTANTS (v2.18+, updated v2.20)
--------------------------------------------------------------------------------

-- Spell queue event codes
API.QUEUE_EVENT = {
    ON_SWING_QUEUED = 0,
    ON_SWING_QUEUE_POPPED = 1,
    NORMAL_QUEUED = 2,
    NORMAL_QUEUE_POPPED = 3,
    NON_GCD_QUEUED = 4,
    NON_GCD_QUEUE_POPPED = 5,
}

-- Spell cast event types
API.CAST_TYPE = {
    NORMAL = 0,
    NON_GCD = 1,
    ON_SWING = 2,
    CHANNEL = 3,
    TARGETING = 4,
    TARGETING_NON_GCD = 5,
}

-- Buff/debuff event names (v2.18+)
-- Parameters: guid, slot, spellId, stackCount, auraLevel (v2.20+), auraSlot (v2.30+, raw 0-based),
--             state (v2.32+, 0=added/1=removed/2=modified)
API.AURA_EVENTS = {
    "BUFF_ADDED_SELF",
    "BUFF_REMOVED_SELF",
    "BUFF_ADDED_OTHER",
    "BUFF_REMOVED_OTHER",
    "DEBUFF_ADDED_SELF",
    "DEBUFF_REMOVED_SELF",
    "DEBUFF_ADDED_OTHER",
    "DEBUFF_REMOVED_OTHER",
}

-- Aura cast event names (v2.20+, requires NP_EnableAuraCastEvents=1)
-- Parameters: spellId, casterGuid, targetGuid, effect, effectAuraName,
--             effectAmplitude, effectMiscValue, durationMs, auraCapStatus
-- auraCapStatus bitfield: 1 = buff bar full, 2 = debuff bar full
API.AURA_CAST_EVENTS = {
    "AURA_CAST_ON_SELF",   -- Fires when aura lands on active player
    "AURA_CAST_ON_OTHER",  -- Fires when aura lands on other units
}

-- Aura cap status bitfield values (for AURA_CAST events)
API.AURA_CAP_STATUS = {
    BUFF_BAR_FULL = 1,
    DEBUFF_BAR_FULL = 2,
    BOTH_FULL = 3,
}

-- Aura event state constants (v2.32+)
-- The 7th parameter on BUFF/DEBUFF_ADDED/REMOVED events
API.AURA_STATE = {
    ADDED = 0,     -- Newly added aura
    REMOVED = 1,   -- Fully removed aura
    MODIFIED = 2,  -- Stack change (ADDED if increased, REMOVED if decreased)
}

-- Aura duration update event names (v2.30+)
-- Fires when a buff/debuff duration is refreshed on the player
-- Parameters: auraSlot (0-based raw slot index), durationMs, expirationTimeMs, spellId (v2.33+)
API.AURA_DURATION_EVENTS = {
    "BUFF_UPDATE_DURATION_SELF",    -- Player buff duration refreshed
    "DEBUFF_UPDATE_DURATION_SELF",  -- Player debuff duration refreshed
}

-- Auto-attack event names (v2.24+, requires NP_EnableAutoAttackEvents=1)
-- Parameters: attackerGuid, targetGuid, totalDamage, hitInfo, victimState,
--             subDamageCount, blockedAmount, totalAbsorb, totalResist
API.AUTO_ATTACK_EVENTS = {
    "AUTO_ATTACK_SELF",   -- Fires when active player is the target
    "AUTO_ATTACK_OTHER",  -- Fires when active player is attacker or different unit is target
}

-- HitInfo bitfield values (for AUTO_ATTACK events)
-- Converted to decimal for Lua 5.0 compatibility (no hex literals)
API.HITINFO = {
    NORMALSWING = 0,
    UNK0 = 1,
    AFFECTS_VICTIM = 2,
    LEFTSWING = 4,          -- Off-hand attack
    UNK3 = 8,
    MISS = 16,              -- 0x10
    ABSORB = 32,            -- 0x20
    RESIST = 64,            -- 0x40
    CRITICALHIT = 128,      -- 0x80
    UNK8 = 256,             -- 0x100
    UNK9 = 8192,            -- 0x2000
    GLANCING = 16384,       -- 0x4000
    CRUSHING = 32768,       -- 0x8000
    NOACTION = 65536,       -- 0x10000
    SWINGNOHITSOUND = 524288, -- 0x80000
}

-- VictimState values (for AUTO_ATTACK events)
API.VICTIMSTATE = {
    UNAFFECTED = 0,   -- Seen with HITINFO_MISS
    NORMAL = 1,
    DODGE = 2,
    PARRY = 3,
    INTERRUPT = 4,
    BLOCKS = 5,
    EVADES = 6,
    IS_IMMUNE = 7,
    DEFLECTS = 8,
}

-- Unit GUID events (v2.39+)
-- Fire once per unit state change, identified by GUID rather than unit token.
-- Unlike standard UNIT_HEALTH etc. (one event per registered token), each GUID event
-- fires exactly once and carries flags for player/target/mouseover/pet/party/raid.
-- Parameters: guid, isPlayer, isTarget, isMouseover, isPet, partyIndex, raidIndex
API.UNIT_GUID_EVENTS = {
    "UNIT_HEALTH_GUID",
    "UNIT_MANA_GUID",
    "UNIT_RAGE_GUID",
    "UNIT_ENERGY_GUID",
    "UNIT_PET_GUID",
    "UNIT_FLAGS_GUID",
    "UNIT_AURA_GUID",
    "UNIT_DYNAMIC_FLAGS_GUID",
    "UNIT_NAME_UPDATE_GUID",
    "UNIT_PORTRAIT_UPDATE_GUID",
    "UNIT_MODEL_CHANGED_GUID",
    "UNIT_INVENTORY_CHANGED_GUID",
    "PLAYER_GUILD_UPDATE_GUID",
    -- UNIT_COMBAT_GUID: guid, action, damage, school, hitInfo, isPet, partyIndex, raidIndex
    "UNIT_COMBAT_GUID",
}

-- Spell start/go event names (v2.25+)
-- These provide improved granularity over UNIT_CASTEVENT for spell cast tracking
-- SPELL_START: Server notifies a spell with cast time has begun
-- SPELL_GO: Server notifies a spell has completed casting (projectile launched, instant landed)
-- v2.38+: SPELL_START includes arg7=durationMs, arg8=spellType
-- v2.40+: SPELL_START includes arg9=corpseOwnerGuid (string or nil)
-- v2.40+: SPELL_GO includes arg8=corpseOwnerGuid (string or nil)
API.SPELL_START_EVENTS = {
    "SPELL_START_SELF",   -- Player starts casting (requires NP_EnableSpellStartEvents=1)
    "SPELL_START_OTHER",  -- Other unit starts casting
}

API.SPELL_GO_EVENTS = {
    "SPELL_GO_SELF",   -- Player's spell completed/fired (requires NP_EnableSpellGoEvents=1)
    "SPELL_GO_OTHER",  -- Other unit's spell completed/fired
}

-- Spell heal event names (v2.26+, requires NP_EnableSpellHealEvents=1)
-- Parameters: targetGuid, casterGuid, spellId, amount, isCritical, isPeriodic
API.SPELL_HEAL_EVENTS = {
    "SPELL_HEAL_BY_SELF",   -- Player healed a target
    "SPELL_HEAL_BY_OTHER",  -- Other unit healed a target
    "SPELL_HEAL_ON_SELF",   -- Player was healed
}

-- Spell energize event names (v2.26+, requires NP_EnableSpellEnergizeEvents=1)
-- Parameters: targetGuid, casterGuid, spellId, powerType, amount, isPeriodic
-- powerType: 0=mana, 1=rage, 2=focus, 3=energy, 4=happiness
API.SPELL_ENERGIZE_EVENTS = {
    "SPELL_ENERGIZE_BY_SELF",   -- Player energized a target
    "SPELL_ENERGIZE_BY_OTHER",  -- Other unit energized a target
    "SPELL_ENERGIZE_ON_SELF",   -- Player was energized
}

-- Power type constants (for SPELL_ENERGIZE events)
API.POWER_TYPE = {
    MANA = 0,
    RAGE = 1,
    FOCUS = 2,
    ENERGY = 3,
    HAPPINESS = 4,
}

-- Unit events (v2.20+)
API.UNIT_EVENTS = {
    "UNIT_DIED",  -- Parameters: guid
}

-- Spell school constants (for reference)
API.SPELL_SCHOOL = {
    PHYSICAL = 0,
    HOLY = 1,
    FIRE = 2,
    NATURE = 3,
    FROST = 4,
    SHADOW = 5,
    ARCANE = 6,
}

-- Resistance indices (1-indexed for Lua tables)
API.RESISTANCE_INDEX = {
    ARMOR = 1,
    HOLY = 2,
    FIRE = 3,
    NATURE = 4,
    FROST = 5,
    SHADOW = 6,
    ARCANE = 7,
}

--------------------------------------------------------------------------------
-- SPELL MODIFIERS API (GetSpellModifiers)
--------------------------------------------------------------------------------

-- Modifier type constants
API.MODIFIER_DAMAGE = 0
API.MODIFIER_DURATION = 1
API.MODIFIER_THREAT = 2
API.MODIFIER_ATTACK_POWER = 3
API.MODIFIER_CHARGES = 4
API.MODIFIER_RANGE = 5
API.MODIFIER_RADIUS = 6
API.MODIFIER_CRITICAL_CHANCE = 7
API.MODIFIER_ALL_EFFECTS = 8
API.MODIFIER_NOT_LOSE_CASTING_TIME = 9
API.MODIFIER_CASTING_TIME = 10
API.MODIFIER_COOLDOWN = 11
API.MODIFIER_SPEED = 12
API.MODIFIER_COST = 14
API.MODIFIER_CRIT_DAMAGE_BONUS = 15
API.MODIFIER_RESIST_MISS_CHANCE = 16
API.MODIFIER_JUMP_TARGETS = 17
API.MODIFIER_CHANCE_OF_SUCCESS = 18
API.MODIFIER_ACTIVATION_TIME = 19
API.MODIFIER_EFFECT_PAST_FIRST = 20
API.MODIFIER_CASTING_TIME_OLD = 21
API.MODIFIER_DOT = 22
API.MODIFIER_HASTE = 23
API.MODIFIER_SPELL_BONUS_DAMAGE = 24
API.MODIFIER_MULTIPLE_VALUE = 27
API.MODIFIER_RESIST_DISPEL_CHANCE = 28

-- Get spell modifiers
-- Requires v2.8+ for GetSpellModifiers
-- Returns: flatMod, percentMod, hasModifier
function API.GetModifiers(spellId, modifierType)
    if not API.features.hasGetSpellModifiers or not GetSpellModifiers then
        return 0, 0, false
    end

    if not spellId or spellId == 0 then
        return 0, 0, false
    end

    local flat, percent, ret = GetSpellModifiers(spellId, modifierType)
    return flat or 0, percent or 0, ret and ret ~= 0
end

-- Get duration modifier for a spell (useful for debuff tracking)
-- Returns modified duration given base duration
function API.GetModifiedDuration(spellId, baseDuration)
    if not baseDuration then return nil end

    local flat, percent, hasModifier = API.GetModifiers(spellId, API.MODIFIER_DURATION)

    if not hasModifier then
        return baseDuration
    end

    -- Apply flat modifier first, then percentage
    -- 修复：按 SCRIPTS.md，GetSpellModifiers 第二返回值是"增量"（如 10 表示 +10%），
    -- 应乘 (1 + percent/100)；原写法 (percent/100) 会把 +30% 缩成 0.3 倍、-10% 变负值 by 武藤纯子酱 2026.8.31
    local modified = baseDuration + flat
    if percent ~= 0 then
        modified = modified * (1 + percent / 100)
    end

    return modified
end

-- Get damage modifier for a spell
function API.GetDamageModifier(spellId)
    local flat, percent = API.GetModifiers(spellId, API.MODIFIER_DAMAGE)
    return flat, percent
end

-- Get cooldown modifier for a spell
function API.GetCooldownModifier(spellId)
    local flat, percent = API.GetModifiers(spellId, API.MODIFIER_COOLDOWN)
    return flat, percent
end

-- Get cast time modifier for a spell
function API.GetCastTimeModifier(spellId)
    local flat, percent = API.GetModifiers(spellId, API.MODIFIER_CASTING_TIME)
    return flat, percent
end

-- Get cost modifier for a spell
function API.GetCostModifier(spellId)
    local flat, percent = API.GetModifiers(spellId, API.MODIFIER_COST)
    return flat, percent
end

--------------------------------------------------------------------------------
-- ENHANCED SPELL LOOKUP (using new "spellId:number" and name syntax)
--------------------------------------------------------------------------------

-- Convert spell identifier to spellId:number format if needed
-- Input can be: spellSlot (number), "spellId:123", or "Spell Name"
function API.NormalizeSpellIdentifier(identifier, bookType)
    if not identifier then return nil end

    -- Already in spellId:number format
    if type(identifier) == "string" and string.find(identifier, "^spellId:") then
        -- 修复：spellId: 标识只有增强函数路径（Nampower 扩展 GetSpellName 等）能解析，
        -- 旧环境下原版 API 只认数字槽位，直接透传会抛 "Usage:"——返回 nil 让调用方走兜底 by 武藤纯子酱 2026.9.9
        if API.features.hasEnhancedSpellFunctions then
            return identifier
        end
        return nil
    end

    -- If it's a number and enhanced functions exist, keep as-is (slot) or convert to spellId
    if type(identifier) == "number" then
        if API.features.hasEnhancedSpellFunctions then
            -- 修复：真实法术 ID 也有 ≤120 的（如 116 冰霜箭）。原固定阈值会把它们误当槽位。
            -- 改为探测：是有效法术书槽位（GetSpellName 有名）→ 槽位；否则若是有效法术 ID → 按 ID
            -- by 武藤纯子酱 2026.9.11
            if identifier > 0 and identifier <= 120 then
                local book = bookType or BOOKTYPE_SPELL
                local slotName = GetSpellName and GetSpellName(identifier, book)
                if slotName then
                    return identifier, book
                end
                if GetSpellRecField and GetSpellRecField(identifier, "name") then
                    return "spellId:" .. identifier
                end
                return identifier, book
            else
                -- Likely a spell ID, convert to spellId:number format
                return "spellId:" .. identifier
            end
        end
        return identifier, bookType
    end

    -- It's a spell name
    if type(identifier) == "string" then
        -- If enhanced functions available, pass name directly
        if API.features.hasEnhancedSpellFunctions then
            return identifier
        end

        -- Fall back to manual lookup
        local spell = CleveRoids.GetSpell and CleveRoids.GetSpell(identifier)
        if spell then
            return spell.spellSlot, spell.bookType
        end
    end

    return nil
end

-- Get spell texture (works with name, spellId:number, or slot)
function API.GetSpellTexture(identifier, bookType)
    if API.features.hasEnhancedSpellFunctions then
        -- Pass directly to native function
        local id = API.NormalizeSpellIdentifier(identifier)
        if id then
            return GetSpellTexture(id, bookType)
        end
    else
        -- Fall back to slot-based lookup
        local slot, book = API.NormalizeSpellIdentifier(identifier, bookType)
        if slot then
            return GetSpellTexture(slot, book or BOOKTYPE_SPELL)
        end
    end
    return nil
end

-- Get item icon texture by display info ID (v2.27+)
-- Parameters:
--   displayInfoId (number): The item's display info ID from GetItemStatsField(itemId, "displayInfoID")
-- Returns:
--   Texture path string (e.g., "Interface\Icons\INV_Sword_04"), or nil if not found
function API.GetItemIconTexture(displayInfoId)
    if not displayInfoId or type(displayInfoId) ~= "number" then
        return nil
    end

    if API.features.hasGetItemIconTexture and GetItemIconTexture then
        return GetItemIconTexture(displayInfoId)
    end

    return nil
end

-- Get item icon texture by item ID (convenience wrapper)
-- Parameters:
--   itemId (number): The item's ID
-- Returns:
--   Texture path string, or nil if not found
function API.GetItemIconTextureByItemId(itemId)
    if not itemId or type(itemId) ~= "number" then
        return nil
    end

    -- Get displayInfoID from item stats
    if GetItemStatsField then
        local displayInfoId = GetItemStatsField(itemId, "displayInfoID")
        if displayInfoId then
            return API.GetItemIconTexture(displayInfoId)
        end
    end

    return nil
end

-- Get spell icon texture by spell icon ID (v2.27+)
-- Parameters:
--   spellIconId (number): The spell's icon ID from GetSpellRecField(spellId, "spellIconID")
-- Returns:
--   Texture path string with Interface\Icons\ prefix (e.g., "Interface\Icons\Spell_Frost_FrostBolt02"), or nil if not found
function API.GetSpellIconTexture(spellIconId)
    if not spellIconId or type(spellIconId) ~= "number" then
        return nil
    end

    if API.features.hasGetSpellIconTexture and GetSpellIconTexture then
        return GetSpellIconTexture(spellIconId)
    end

    return nil
end

-- Get spell icon texture by spell ID (convenience wrapper)
-- Parameters:
--   spellId (number): The spell's ID
-- Returns:
--   Texture path string, or nil if not found
function API.GetSpellIconTextureBySpellId(spellId)
    if not spellId or type(spellId) ~= "number" then
        return nil
    end

    -- Get spellIconID from spell record
    if GetSpellRecField then
        local spellIconId = GetSpellRecField(spellId, "spellIconID")
        if spellIconId then
            return API.GetSpellIconTexture(spellIconId)
        end
    end

    return nil
end

-- Get spell name (works with name, spellId:number, or slot)
function API.GetSpellName(identifier, bookType)
    if API.features.hasEnhancedSpellFunctions then
        local id = API.NormalizeSpellIdentifier(identifier)
        if id then
            return GetSpellName(id, bookType)
        end
    else
        local slot, book = API.NormalizeSpellIdentifier(identifier, bookType)
        if slot then
            return GetSpellName(slot, book or BOOKTYPE_SPELL)
        end
    end
    return nil
end

-- Get spell cooldown (works with name, spellId:number, or slot)
-- Returns: start, duration (same as native)
function API.GetSpellCooldown(identifier, bookType)
    if API.features.hasEnhancedSpellFunctions then
        local id = API.NormalizeSpellIdentifier(identifier)
        if id then
            return GetSpellCooldown(id, bookType)
        end
    else
        local slot, book = API.NormalizeSpellIdentifier(identifier, bookType)
        if slot then
            return GetSpellCooldown(slot, book or BOOKTYPE_SPELL)
        end
    end
    return nil
end

-- Check if spell is passive
function API.IsSpellPassive(identifier, bookType)
    if API.features.hasEnhancedSpellFunctions then
        local id = API.NormalizeSpellIdentifier(identifier)
        if id then
            return IsSpellPassive(id, bookType)
        end
    else
        local slot, book = API.NormalizeSpellIdentifier(identifier, bookType)
        if slot then
            return IsSpellPassive(slot, book or BOOKTYPE_SPELL)
        end
    end
    return nil
end

--------------------------------------------------------------------------------
-- SPELL ID LOOKUP UTILITIES
--------------------------------------------------------------------------------

-- Cache for spell ID lookups
API.spellIdCache = {}

-- Get spell ID from name (cached)
function API.GetSpellIdFromName(spellName)
    if not spellName then return nil end

    -- Check cache
    if API.spellIdCache[spellName] then
        return API.spellIdCache[spellName]
    end

    -- Use Nampower's GetSpellIdForName
    if GetSpellIdForName then
        local spellId = GetSpellIdForName(spellName)
        if spellId and spellId > 0 then
            API.spellIdCache[spellName] = spellId
            return spellId
        end
    end

    return nil
end

-- Get spell slot, book type, and ID from name
function API.GetSpellSlotInfo(spellName)
    if not spellName then return nil end

    -- Use Nampower's GetSpellSlotTypeIdForName
    if GetSpellSlotTypeIdForName then
        local slot, bookType, spellId = GetSpellSlotTypeIdForName(spellName)
        if slot and slot > 0 then
            return slot, bookType, spellId
        end
    end

    -- Fallback to CleveRoids.GetSpell
    if CleveRoids.GetSpell then
        local spell = CleveRoids.GetSpell(spellName)
        if spell then
            local spellId = API.GetSpellIdFromName(spellName)
            return spell.spellSlot, spell.bookType, spellId
        end
    end

    return nil
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

-- Initialize the API module
function API.Initialize()
    -- Detect enhanced spell functions
    DetectEnhancedSpellFunctions()

    -- NOTE: UnitBuff/UnitDebuff spell ID hooks are now installed at file load time (by 武藤纯子酱 2026.9.1)
    -- (InstallAuraSpellIdHooks above) so that Utility.lua's `local _UnitDebuff`
    -- alias captures the hooked version. Do NOT move this call back into
    -- API.Initialize (it runs on ADDON_LOADED, after Utility.lua has loaded).

    -- Auto-enable required Nampower event CVars.
    -- Nampower reads CVars at DLL load time, so changes take effect on next reload.
    -- We set them now so every subsequent session works automatically.
    if SetCVar and GetCVar then
        local f = API.features

        -- NP_EnableAuraCastEvents (v2.20+) - required for [debuffcapped], [mybuffcapped], overflow buff tracking
        if f.hasAuraCastEvents and GetCVar("NP_EnableAuraCastEvents") ~= "1" then
            SetCVar("NP_EnableAuraCastEvents", "1")
        end

        -- NP_EnableAutoAttackEvents (v2.24+) - required for [lastswing], [incominghit]
        if f.hasAutoAttackEvents and GetCVar("NP_EnableAutoAttackEvents") ~= "1" then
            SetCVar("NP_EnableAutoAttackEvents", "1")
        end

        -- NP_EnableSpellStartEvents (v2.25+) - required for SPELL_START_SELF/OTHER cast tracking
        if f.hasSpellStartEvents and GetCVar("NP_EnableSpellStartEvents") ~= "1" then
            SetCVar("NP_EnableSpellStartEvents", "1")
        end

        -- NP_EnableSpellGoEvents (v2.25+) - required for SPELL_GO_SELF/OTHER cast tracking
        if f.hasSpellGoEvents and GetCVar("NP_EnableSpellGoEvents") ~= "1" then
            SetCVar("NP_EnableSpellGoEvents", "1")
        end
    end
end

-- Clear caches (call on respec/spell change)
function API.ClearCaches()
    API.spellRecCache = {}
    API.itemStatsCache = {}
    API.spellIdCache = {}
    API.settingsCache = {}
    API.spellTypeCache = {}
end

--------------------------------------------------------------------------------
-- CONVENIENCE WRAPPERS FOR EXISTING CODE
--------------------------------------------------------------------------------

-- Check if a spell is in range (wrapper around IsSpellInRange with fallbacks)
function API.IsSpellInRange(spellIdentifier, unit)
    unit = unit or "target"

    -- Convert name to ID if needed
    local spellId = nil
    local checkValue = spellIdentifier
    if type(spellIdentifier) == "string" and not string.find(spellIdentifier, "^spellId:") then
        spellId = API.GetSpellIdFromName(spellIdentifier)
        if spellId and spellId > 0 then
            checkValue = spellId
        end
    elseif type(spellIdentifier) == "number" then
        spellId = spellIdentifier
    end

    -- Check for self-cast spells FIRST before native range check
    -- Self-targeted spells are always in range regardless of what IsSpellInRange returns
    if spellId and spellId > 0 then
        local rangeIndex = API.GetSpellRangeIndexCached(spellId) -- 性能优化：走缓存 by 武藤纯子酱 2026.9.11
        -- rangeIndex 0 = Self Only, 14 = Self Only (alternate), 23 = Touch
        if rangeIndex == 0 or rangeIndex == 14 or rangeIndex == 23 then
            return 1  -- Self-targeted spells are always in range
        end
        -- Fallback: if rangeIndex lookup failed but spell range is 0, it's self-only
        if rangeIndex == nil then
            local spellRange = API.GetSpellRange(spellId)
            if spellRange == 0 or spellRange == nil then
                return 1  -- Assume self-only if range is 0 or unknown
            end
        end
    end

    -- Try native IsSpellInRange (wrapped in pcall to handle invalid spell IDs)
    local nativeResult = nil
    if IsSpellInRange then
        local success, result = pcall(IsSpellInRange, checkValue, unit)
        if success then
            nativeResult = result
            -- result == 1 (in range), 0 (out of range), -1 (invalid/non-unit-targeted), nil (error)
            if nativeResult == 0 or nativeResult == 1 then
                return nativeResult
            end
        end
        -- If pcall failed, nativeResult stays nil and we fall through to UnitXP
    end

    -- If native returned -1, check DBC target type to determine handling
    if nativeResult == -1 and spellId and spellId > 0 then
        local isUnitTargeted = API.IsUnitTargetedSpell(spellId)

        if isUnitTargeted then
            -- Unit-targeted spell (like channeled Arcane Missiles) - use distance check
            local spellRange = API.GetSpellRange(spellId)
            if spellRange and spellRange > 0 and CleveRoids.hasUnitXP and UnitExists(unit) then
                local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
                if distance then
                    return (distance <= spellRange) and 1 or 0
                end
            end
            -- Fall through to return 1 if we can't check distance
        end

        -- Non-unit-targeted spell (self-cast like Presence of Mind, or ground-targeted like Blizzard)
        -- Always in range
        return 1
    end

    -- For nil results (native couldn't determine), try UnitXP distance check
    if spellId and spellId > 0 and CleveRoids.hasUnitXP and UnitExists(unit) then
        local spellRange = API.GetSpellRange(spellId)
        if spellRange and spellRange > 0 then
            local distance = CleveRoids.SafeUnitXP("distanceBetween", "player", unit)
            if distance then
                return (distance <= spellRange) and 1 or 0
            end
        end
    end

    return nil  -- Can't determine
end

-- Check if a spell is usable (wrapper around IsSpellUsable)
-- Returns usable, oom on success; nil on error (spell not in spellbook)
function API.IsSpellUsable(spellIdentifier)
    if not _G.IsSpellUsable then
        return nil
    end

    -- If enhanced functions available, pass directly
    if API.features.hasEnhancedSpellFunctions then
        local ok, usable, oom = pcall(_G.IsSpellUsable, spellIdentifier)
        if ok then return usable, oom end
        return nil
    end

    -- Convert to ID if name
    if type(spellIdentifier) == "string" then
        local spellId = API.GetSpellIdFromName(spellIdentifier)
        if spellId then
            local ok, usable, oom = pcall(_G.IsSpellUsable, spellId)
            if ok then return usable, oom end
            return nil
        end
    end

    local ok, usable, oom = pcall(_G.IsSpellUsable, spellIdentifier)
    if ok then return usable, oom end
    return nil
end

--------------------------------------------------------------------------------
-- SMART CASTING SYSTEM
--------------------------------------------------------------------------------

-- Spell type constants
API.SPELL_TYPE_UNKNOWN = 0
API.SPELL_TYPE_CAST = 1      -- Has cast time
API.SPELL_TYPE_INSTANT = 2   -- Instant, on GCD
API.SPELL_TYPE_CHANNEL = 3   -- Channeled spell
API.SPELL_TYPE_ON_SWING = 4  -- Next-melee (Heroic Strike, etc.)
API.SPELL_TYPE_NON_GCD = 5   -- Instant, not on GCD (trinkets, etc.)

-- Known on-swing spells (by name, localized via CleveRoids.Localized when available)
API.onSwingSpells = {
    [CleveRoids.Localized.Spells["Heroic Strike"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Cleave"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Maul"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Slam"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Raptor Strike"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    --[CleveRoids.Localized.Spells["Mongoose Bite"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
}

-- Known channeled spells (by name)
API.channeledSpells = {
    [CleveRoids.Localized.Spells["Arcane Missiles"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Blizzard"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Drain Life"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Drain Mana"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Drain Soul"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Evocation"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Health Funnel"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Hellfire"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Hurricane"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Mind Flay"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Rain of Fire"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Tranquility"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Volley"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    --[CleveRoids.Localized.Spells["Mind Soothe"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["Mind Vision"]] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [CleveRoids.Localized.Spells["First Aid"]] = true, -- Bandaging -- 修复多语言支持 by 武藤纯子酱 2026.1.4
}

-- Cache for spell type lookups
API.spellTypeCache = {}

-- Determine spell type for a given spell
-- Returns: SPELL_TYPE_* constant
function API.GetSpellType(spellName)
    if not spellName then return API.SPELL_TYPE_UNKNOWN end

    -- Strip rank from name for cache lookup
    local baseName = CleveRoids.StripRank(spellName) -- 修复多语言支持 by 武藤纯子酱 2025.12.18

    -- Check cache first
    if API.spellTypeCache[baseName] then
        return API.spellTypeCache[baseName]
    end

    local spellType = API.SPELL_TYPE_UNKNOWN

    -- Check known on-swing spells first (highest priority)
    if API.onSwingSpells[baseName] then
        spellType = API.SPELL_TYPE_ON_SWING
        API.spellTypeCache[baseName] = spellType
        return spellType
    end

    -- Check known channeled spells
    if API.channeledSpells[baseName] then
        spellType = API.SPELL_TYPE_CHANNEL
        API.spellTypeCache[baseName] = spellType
        return spellType
    end

    -- Try to use GetSpellRec for accurate detection
    local spellId = API.GetSpellIdFromName(spellName)
    if spellId and spellId > 0 and API.features.hasGetSpellRec then
        local rec = API.GetSpellRecord(spellId)
        if rec then
            -- Check for channeled via attributes
            -- SPELL_ATTR_EX_CHANNELED = 4 (0x00000004) in attributesEx
            local attrEx = rec.attributesEx or 0
            if bit and bit.band(attrEx, 4) ~= 0 then
                spellType = API.SPELL_TYPE_CHANNEL
                API.spellTypeCache[baseName] = spellType
                return spellType
            end

            -- Check cast time
            local castTime = rec.castTime or 0
            if castTime > 0 then
                spellType = API.SPELL_TYPE_CAST
            else
                -- Instant spell - check if it's on GCD
                -- startRecoveryTime > 0 means it triggers GCD
                local recoveryTime = rec.startRecoveryTime or 0
                if recoveryTime > 0 then
                    spellType = API.SPELL_TYPE_INSTANT
                else
                    spellType = API.SPELL_TYPE_NON_GCD
                end
            end

            API.spellTypeCache[baseName] = spellType
            return spellType
        end
    end

    -- Fallback: assume instant if no other info
    -- This is safe because Nampower will handle it correctly anyway
    spellType = API.SPELL_TYPE_INSTANT
    API.spellTypeCache[baseName] = spellType
    return spellType
end

-- Get the queue setting name for a spell type
local function GetQueueSettingForType(spellType)
    if spellType == API.SPELL_TYPE_CAST then
        return "NP_QueueCastTimeSpells"
    elseif spellType == API.SPELL_TYPE_INSTANT then
        return "NP_QueueInstantSpells"
    elseif spellType == API.SPELL_TYPE_CHANNEL then
        return "NP_QueueChannelingSpells"
    elseif spellType == API.SPELL_TYPE_ON_SWING then
        return "NP_QueueOnSwingSpells"
    elseif spellType == API.SPELL_TYPE_NON_GCD then
        return "NP_QueueInstantSpells"  -- Non-GCD uses instant setting
    end
    return nil
end

-- Check if queuing is enabled for a specific spell
function API.IsSpellQueueingEnabled(spellName)
    if not API.features.hasSpellQueue then
        return false
    end

    local spellType = API.GetSpellType(spellName)
    local settingName = GetQueueSettingForType(spellType)

    if settingName then
        return API.GetSettingBool(settingName)
    end

    -- Default: use cast time spell setting
    return API.GetSettingBool("NP_QueueCastTimeSpells")
end

-- Smart cast function that uses QueueSpellByName when appropriate
-- Returns: true if cast was attempted, false otherwise
-- Parameters:
--   spellName: The spell name (with optional rank)
--   target: Optional target unit/GUID (for Nampower v2.37+ CastSpellByName 2nd param) by 武藤纯子酱 2026.9.1
--   forceQueue: If true, always use QueueSpellByName (if available, v2.0+)
--   forceNoQueue: If true, never use QueueSpellByName
function API.SmartCast(spellName, target, forceQueue, forceNoQueue)
    if not spellName then return false end

    -- Determine whether to use queuing
    local useQueue = false

    if forceNoQueue then
        useQueue = false
    elseif forceQueue then
        useQueue = API.features.hasSpellQueue
    else
        -- Check if queuing is enabled for this spell type
        useQueue = API.IsSpellQueueingEnabled(spellName)
    end

    -- Check if we have a non-standard target (e.g., @mouseover)
    -- QueueSpellByName in older Nampower versions doesn't support target parameter
    -- Only Nampower v2.13+ supports QueueSpellByName with target
    local hasNonStandardTarget = target and target ~= "target"
    local canQueueWithTarget = API.features.hasQueueSpellWithTarget

    -- Cast the spell
    if useQueue and API.features.hasSpellQueue and QueueSpellByName then
        if hasNonStandardTarget then
            -- 修复：按 SCRIPTS.md，QueueSpellByName(spellName) 不支持目标参数（文档亦无 QueueSpellWithTarget），
            -- 带非默认目标时改走 CastSpellByName(unitToken)（Nampower 原生支持），避免静默丢失目标 by 武藤纯子酱 2026.8.31
            -- Fall through to CastSpellByName with target
        else
            -- No target or target is "target" - safe to use queue
            QueueSpellByName(spellName)
            return true
        end
    end

    -- Use standard casting (either queuing wasn't possible or we need target support)
    if CastSpellByName then
        if target and API.features.hasCastSpellByNameUnitToken then
            -- Nampower v2.37+: CastSpellByName 2nd param accepts unit token or GUID by 武藤纯子酱 2026.9.1
            CastSpellByName(spellName, target)
        else
            CastSpellByName(spellName)
        end
        return true
    end

    return false
end

-- Cast without queuing (uses CastSpellByNameNoQueue if available, v2.12+; v3.1+ supports unit target)
function API.CastNoQueue(spellName, target)
    if not spellName then return false end

    -- Use Nampower's no-queue function if available (v2.12+)
    if API.features.hasCastSpellByNameNoQueue and CastSpellByNameNoQueue then
        if target then
            CastSpellByNameNoQueue(spellName, target)
        else
            CastSpellByNameNoQueue(spellName)
        end
        return true
    end

    -- Fall back to standard cast
    -- 修复：原版 CastSpellByName 第二参数语义是 onSelf（布尔），未检查
    -- hasCastSpellByNameUnitToken 就传单位 token，在旧 Nampower/纯 SuperWoW 环境
    -- 会把法术静默施放到自己身上 by 武藤纯子酱 2026.9.9
    if CastSpellByName then
        if target and API.features.hasCastSpellByNameUnitToken then
            CastSpellByName(spellName, target)
        elseif target then
            -- 无单位 token 支持时先选中目标再施放
            if TargetUnit then pcall(TargetUnit, target) end
            CastSpellByName(spellName)
        else
            CastSpellByName(spellName)
        end
        return true
    end

    return false
end

-- Cast by spell ID without queuing (v3.1+)
function API.CastNoQueueById(spellId, target)
    if not spellId then return false end

    if API.features.hasCastSpellNoQueue and _G.CastSpellNoQueue then
        if target then
            _G.CastSpellNoQueue(spellId, 0, target)
        else
            _G.CastSpellNoQueue(spellId, 0)
        end
        return true
    end

    -- Fall back to CastNoQueue by name
    local name = API.GetSpellNameById(spellId)
    if name then
        return API.CastNoQueue(name, target)
    end

    return false
end

-- Force queue a spell (uses QueueSpellByName directly, v2.0+)
function API.ForceQueue(spellName, target) -- 修复：对于有conditional.target的技能直接施放，指定施法目标 by 武藤纯子酱 2025.12.6
    if not spellName then return false end

    if API.features.hasSpellQueue and QueueSpellByName and (not target or target == "target") then
        -- 仅默认目标（或无目标）时使用队列；QueueSpellByName 不支持目标参数（见 SCRIPTS.md）
        QueueSpellByName(spellName)
        return true
    end

    -- Fall back to standard cast if queue not available
    -- 修复：有目标时不能丢弃 target；且第二参数仅在有单位 token 支持时才是"施法目标"，
    -- 原版语义是 onSelf（布尔），否则会静默施放到自己 by 武藤纯子酱 2026.9.9
    if CastSpellByName then
        if target and target ~= "target" then
            if API.features.hasCastSpellByNameUnitToken then
                CastSpellByName(spellName, target)
            else
                if TargetUnit then pcall(TargetUnit, target) end
                CastSpellByName(spellName)
            end
        else
            CastSpellByName(spellName)
        end
        return true
    end

    return false
end

-- Queue a script to run after current cast (uses QueueScript if available, v2.12+)
function API.QueueScript(script, priority)
    if not script then return false end

    if API.features.hasQueueScript and QueueScript then
        QueueScript(script, priority or 1)
        return true
    end

    return false
end

-- Get equipped ammo ID and total count (v2.29+)
-- Returns: ammoId, ammoCount (or nil, nil if unavailable)
function API.GetAmmo()
    if not API.features.hasGetAmmo or not _G.GetAmmo then
        return nil, nil
    end
    return _G.GetAmmo()
end

-- Get player aura duration info by raw slot index (v2.30+)
-- auraSlot: 0-based raw aura slot (0-31 = buffs, 32-47 = debuffs)
-- Returns: spellId, durationMs, expirationTimeMs (or nil if unavailable)
function API.GetPlayerAuraDuration(auraSlot)
    if not API.features.hasGetPlayerAuraDuration or not _G.GetPlayerAuraDuration then
        return nil, nil, nil
    end
    return _G.GetPlayerAuraDuration(auraSlot)
end

-- Count occupied player buff slots using GetPlayerAuraDuration (v2.30+)
-- Returns: count of occupied buff slots (0-32), or nil if unavailable
function API.CountPlayerBuffSlots()
    if not API.features.hasGetPlayerAuraDuration or not _G.GetPlayerAuraDuration then
        return nil
    end
    local count = 0
    for i = 0, 31 do
        local spellId = _G.GetPlayerAuraDuration(i)
        if spellId and spellId > 0 then
            count = count + 1
        end
    end
    return count
end

-- Count occupied player debuff slots using GetPlayerAuraDuration (v2.30+)
-- Returns: count of occupied debuff slots (0-16), or nil if unavailable
function API.CountPlayerDebuffSlots()
    if not API.features.hasGetPlayerAuraDuration or not _G.GetPlayerAuraDuration then
        return nil
    end
    local count = 0
    for i = 32, 47 do
        local spellId = _G.GetPlayerAuraDuration(i)
        if spellId and spellId > 0 then
            count = count + 1
        end
    end
    return count
end

-- Clear spell type cache (call on spec change)
function API.ClearSpellTypeCache()
    API.spellTypeCache = {}
end

--------------------------------------------------------------------------------
-- SPELL MISS CONSTANTS (v2.31+)
--------------------------------------------------------------------------------

-- MissInfo enum values from SPELL_MISS_SELF/OTHER events
API.MISS_INFO = {
    NONE = 0, MISS = 1, RESIST = 2, DODGE = 3, PARRY = 4, BLOCK = 5,
    EVADE = 6, IMMUNE = 7, IMMUNE2 = 8, DEFLECT = 9, ABSORB = 10, REFLECT = 11,
}

--------------------------------------------------------------------------------
-- SPELL POWER QUERY (v2.31+)
--------------------------------------------------------------------------------

-- Get spell power for all 7 damage schools (v2.31+)
-- mode: optional mode parameter passed to GetSpellPower
-- Returns: physical, holy, fire, nature, frost, shadow, arcane (or nil if unavailable)
function API.GetSpellPower(mode)
    if not API.features.hasGetSpellPower or not _G.GetSpellPower then
        return nil, nil, nil, nil, nil, nil, nil
    end
    return _G.GetSpellPower(mode)
end

-- Get duration of a spell in milliseconds (v2.38+)
-- For channeling spells: returns the channel duration.
-- For non-channeling spells: returns the first aura effect duration.
-- spellId: spell ID to look up
-- ignoreModifiers: pass 1 to ignore talent/buff modifiers (returns base duration)
-- Returns: duration in ms (0 if spell has no duration), or nil if spellId invalid
function API.GetSpellDuration(spellId, ignoreModifiers)
    if not API.features.hasGetSpellDuration or not _G.GetSpellDuration then
        return nil
    end
    return _G.GetSpellDuration(spellId, ignoreModifiers)
end

--------------------------------------------------------------------------------
-- AURA CANCEL FUNCTIONS (v2.34+)
--------------------------------------------------------------------------------

-- Cancel a player aura by raw 0-based aura slot (v2.34+)
-- auraSlot: 0-31 for buffs, 32-47 for debuffs
function API.CancelPlayerAuraSlot(auraSlot)
    if not API.features.hasCancelPlayerAuraSlot or not _G.CancelPlayerAuraSlot then
        return false
    end
    _G.CancelPlayerAuraSlot(auraSlot)
    return true
end

-- Cancel a player aura by spell ID (v2.34+)
-- spellId: the spell ID to cancel
-- ignoreMissing: pass 1 to skip aura-slot presence check (useful for buff-capped hidden auras)
function API.CancelPlayerAuraSpellId(spellId, ignoreMissing)
    if not API.features.hasCancelPlayerAuraSpellId or not _G.CancelPlayerAuraSpellId then
        return false
    end
    _G.CancelPlayerAuraSpellId(spellId, ignoreMissing)
    return true
end

--------------------------------------------------------------------------------
-- TALENT HELPER (v2.35+)
--------------------------------------------------------------------------------

-- Learn a specific talent rank directly (v2.35+)
-- talentPage: 1-3 (talent tab)
-- talentIndex: 1-32 (talent position within tab)
-- rank: 1-5 (rank to learn)
function API.LearnTalentRank(talentPage, talentIndex, rank)
    if not API.features.hasLearnTalentRank or not _G.LearnTalentRank then
        return false
    end
    if not talentPage or not talentIndex or not rank then return false end
    if talentPage < 1 or talentPage > 3 then return false end
    if talentIndex < 1 or talentIndex > 32 then return false end
    if rank < 1 or rank > 5 then return false end
    _G.LearnTalentRank(talentPage, talentIndex, rank)
    return true
end

-- Get unit GUID by token (v3.0+)
-- Supports extended tokens: mark1-mark8, <base>owner/target/pet suffixes
function API.GetUnitGUID(unitToken)
    if not API.features.hasGetUnitGUID or not _G.GetUnitGUID then
        return nil
    end
    return _G.GetUnitGUID(unitToken)
end

-- Check if a spell's aura would be hidden from Lua aura APIs (v3.0+)
function API.IsAuraHidden(spellId)
    if not API.features.hasIsAuraHidden or not _G.IsAuraHidden then
        return nil
    end
    return _G.IsAuraHidden(spellId)
end

-- Get spell range data from SpellRange DBC by rangeIndex (v4.0+)
-- Returns minRange, maxRange, flags, name or nil if unavailable/invalid
-- flags: 0 = ranged, 1 = melee (Combat Range)
-- Note: returned ranges are raw DBC values before combat reach adjustments
function API.GetSpellRangeData(rangeIndex)
    if not API.features.hasGetSpellRangeData or not _G.GetSpellRangeData then
        return nil
    end
    return _G.GetSpellRangeData(rangeIndex)
end

--------------------------------------------------------------------------------
-- HEALTH/POWER WRAPPERS (GetUnitField extended token support with fallback)
--------------------------------------------------------------------------------

-- Get unit health via GetUnitField (extended token support) with standard API fallback
function API.GetUnitHealth(unitToken)
    if API.features.hasGetUnitField and GetUnitField then
        -- 性能优化：player token 必定合法，跳过 pcall；其余 token 保留 pcall 兜底 by 武藤纯子酱 2026.9.11
        if unitToken == "player" then
            local val = GetUnitField(unitToken, "health")
            if val then return val end
            return UnitHealth(unitToken)
        end
        -- 修复：GetUnitField 对无效/旧版不支持的 token 会抛错，pcall 包裹后回退标准 API
        -- by 武藤纯子酱 2026.9.11
        local ok, val = pcall(GetUnitField, unitToken, "health")
        if ok and val then return val end
    end
    return UnitHealth(unitToken)
end

function API.GetUnitMaxHealth(unitToken)
    if API.features.hasGetUnitField and GetUnitField then
        if unitToken == "player" then
            local val = GetUnitField(unitToken, "maxHealth")
            if val then return val end
            return UnitHealthMax(unitToken)
        end
        local ok, val = pcall(GetUnitField, unitToken, "maxHealth")
        if ok and val then return val end
    end
    return UnitHealthMax(unitToken)
end

-- powerType: nil=current, 0=mana, 1=rage, 2=focus, 3=energy
-- GetUnitField uses power1-power4 fields
local POWER_FIELDS = { [0] = "power1", [1] = "power2", [2] = "power3", [3] = "power4" }
local MAX_POWER_FIELDS = { [0] = "maxPower1", [1] = "maxPower2", [2] = "maxPower3", [3] = "maxPower4" }

function API.GetUnitPower(unitToken, powerType)
    if API.features.hasGetUnitField and GetUnitField and powerType then
        local field = POWER_FIELDS[powerType]
        if field then
            if unitToken == "player" then
                local val = GetUnitField(unitToken, field) -- 性能优化：player token 免 pcall by 武藤纯子酱 2026.9.11
                if val then return val end
                return UnitMana(unitToken)
            end
            local ok, val = pcall(GetUnitField, unitToken, field) -- 修复：pcall 包裹 by 武藤纯子酱 2026.9.11
            if ok and val then return val end
        end
    end
    return UnitMana(unitToken)
end

function API.GetUnitMaxPower(unitToken, powerType)
    if API.features.hasGetUnitField and GetUnitField and powerType then
        local field = MAX_POWER_FIELDS[powerType]
        if field then
            if unitToken == "player" then
                local val = GetUnitField(unitToken, field) -- 性能优化：player token 免 pcall by 武藤纯子酱 2026.9.11
                if val then return val end
                return UnitManaMax(unitToken)
            end
            local ok, val = pcall(GetUnitField, unitToken, field) -- 修复：pcall 包裹 by 武藤纯子酱 2026.9.11
            if ok and val then return val end
        end
    end
    return UnitManaMax(unitToken)
end

--------------------------------------------------------------------------------
-- CAST TIME TOOLTIP QUERY（tooltip 施法时间查询）by 武藤纯子酱 2026.9.1
--------------------------------------------------------------------------------
-- Nampower 没有 per-spell 施法时间 API（SpellRec 无 castTime 字段，castingTimeIndex
-- 只是 DBC 索引）。本函数解析法术书 tooltip 的施法时间行，按三分支返回：
--   "X秒施法时间" / "X sec cast"  → type="cast",    value=施法时间(秒，DBC 基础值)
--   "瞬发法术"     / "Instant"     → type="instant", value=0
--   "需引导"       / "Channeled"   → type="channel", value=引导总时长(秒，经 GetSpellDuration)
-- 注意：tooltip 显示的是 DBC 基础施法时间（1.12 的天赋减读条/急速不反映在 tooltip），
--       实际施法时间 = 基础值 × GetUnitField("player","modCastSpeed")；
--       正在读条时的服务器权威值以 GetCastInfo().castDurationMs / SPELL_START_SELF arg6 为准。
-- 返回：type(string), value(number), rawLine(string|nil)；未识别返回 nil
local castTimeScanTip

-- 法术书扫描上界：不依赖 GetNumSpellTabs/GetTabInfo（1.12 下不可用/语义不符导致漏扫，
-- 曾因此使技能施法时间学习全面失败），以 GetSpellName 返回 nil 为终止条件
-- （与 Utility.lua 既有扫描模式一致），600 为防死循环安全上限 by 武藤纯子酱 2026.9.1
local function GetSpellBookMaxSlot()
    local i = 1
    while i <= 600 and GetSpellName(i, BOOKTYPE_SPELL) do
        i = i + 1
    end
    return i - 1
end

local function GetCastTimeScanTip()
    if not castTimeScanTip then
        castTimeScanTip = CreateFrame("GameTooltip", "SCRMCastTimeScanTip", nil, "GameTooltipTemplate")
        castTimeScanTip:SetOwner(UIParent, "ANCHOR_NONE")
    end
    return castTimeScanTip
end

function API.GetSpellCastTimeInfo(spellName)
    if not spellName or spellName == "" then return nil end
    local tip = GetCastTimeScanTip()

    -- 法术书定位：主路径 Nampower GetSpellSlotTypeIdForName（O(1)，返回槽位/书类型/ID）；
    -- 兜底：逐条扫描（GetSpellName 直到 nil，同名取最后一个 = 最高等级）by 武藤纯子酱 2026.9.1
    local slot = nil
    if API.features.hasGetSpellSlotTypeIdForName and GetSpellSlotTypeIdForName then
        local ok, s = pcall(GetSpellSlotTypeIdForName, spellName)
        if ok and type(s) == "number" and s > 0 then slot = s end
    end
    if not slot then
        local maxSpell = GetSpellBookMaxSlot()
        for i = 1, maxSpell do
            local n = GetSpellName(i, BOOKTYPE_SPELL)
            if n == spellName then slot = i end
        end
    end
    if not slot then return nil end

    tip:ClearLines()
    tip:SetSpell(slot, BOOKTYPE_SPELL)

    local castSec, isInstant, isChannel, rawLine
    local numLines = tip:NumLines() or 0
    for i = 1, numLines do
        for _, side in ipairs({ "Left", "Right" }) do
            local fs = getglobal("SCRMCastTimeScanTipText" .. side .. i)
            local text = fs and fs:GetText()
            if text and text ~= "" then
                if not castSec and not isInstant and not isChannel
                    and (string.find(text, "施法时间") or string.find(text, "sec cast")) then
                    -- 提取行内首个数字（zhCN: "3.5秒施法时间" / enUS: "3.5 sec cast"）
                    local _, _, num = string.find(text, "([%d%.]+)")
                    if num then castSec = tonumber(num) end
                    rawLine = text
                elseif not isInstant and (string.find(text, "瞬发") or string.find(text, "Instant")) then
                    isInstant = true
                    rawLine = text
                elseif not isChannel and (string.find(text, "引导") or string.find(text, "Channel")) then
                    isChannel = true
                    rawLine = text
                end
            end
        end
    end

    if isChannel then
        -- 需引导 → 查引导总时长（GetSpellDuration 对引导法术返回引导时长，毫秒；Cursive 同款）
        -- spellId 主路径 GetSpellSlotTypeIdForName：支持 "奥术飞弹(等级 5)" 带等级名（按等级定位）；
        -- GetSpellIdForName 同样支持带等级名（如 "Frostbolt(Rank 1)"，实测确认），
        -- 仅纯技能名时返回最高等级 ID；兜底路径同样可按等级定位 by 武藤纯子酱 2026.9.2
        local channelSec = nil
        local spellId = nil
        if API.features.hasGetSpellSlotTypeIdForName and GetSpellSlotTypeIdForName then
            local ok, slot, bookType, sid = pcall(GetSpellSlotTypeIdForName, spellName)
            if ok and type(sid) == "number" and sid > 0 then spellId = sid end
        end
        if not spellId and API.features.hasGetSpellIdForName and GetSpellIdForName then
            spellId = GetSpellIdForName(spellName)
        end
        if spellId and GetSpellDuration then
            local ok, ms = pcall(GetSpellDuration, spellId)
            if ok and ms and ms > 0 then channelSec = ms / 1000 end
        end
        return "channel", channelSec, rawLine
    elseif castSec then
        return "cast", castSec, rawLine
    elseif isInstant then
        return "instant", 0, rawLine
    end
    return nil, nil, rawLine
end

--------------------------------------------------------------------------------
-- SPELL CAST INFO TABLE（技能施法信息表）by 武藤纯子酱 2026.9.1
--------------------------------------------------------------------------------
-- 两层设计 by 武藤纯子酱 2026.9.1：
--   ① 基础表（SavedVariables，静态）：CleveRoids_SpellCastInfo.spells[小写技能名] =
--        { spellid, name, rank, castType, castTime, line }
--        castType: "channel"=引导 / "cast"=非引导（瞬发技 castTime=0）
--        castTime: 秒；引导技 = 引导总时长（GetSpellDuration）；非引导 = tooltip 基础施法时间
--     tooltip 无施法时间/瞬发/引导标记的技能（被动、专业等）不收录。
--   ② 生效值（实时）：API.GetEffectiveSpellCastTime —— 0.1s TTL 缓存内实时计算，
--        非引导 = 基础值 × 当前 modCastSpeed（急速变化实时生效）；
--        引导 = GetSpellDuration 实时值（含玩家时长类修正）。
--   表不预扫描：仅在 getcast/getchannel 公式引用到某技能时惰性学习（识别过的才进表）。
--   技能定位主路径 GetSpellSlotTypeIdForName（支持 "火球术(等级 5)" 带等级名，可按等级引用）。
-- 维护命令：/cleveroid castinfo show <技能名> | clear（clear 兼作强制重学）
-- 条件公式（独立命名，避免与 [casttime]/[channeltime] 条件冲突）：
--   getcast(技能名) = 实时施法时间；getchannel(技能名) = 实时引导总时长
--   getmh()/getoh()/getranged() = 实时主手/副手/远程攻速
--   支持 + - * / 与括号，如 getchannel(奥术飞弹)/6
--------------------------------------------------------------------------------

-- 学习单个技能（tooltip 扫描 + 法术书等级 + GetSpellIdForName）
function API.LearnSpellCastInfo(spellName)
    if not spellName or spellName == "" then return nil end
    local castType, value, rawLine = API.GetSpellCastTimeInfo(spellName)
    if not castType then return nil end  -- 无标记 → 放弃
    -- 引导技时长获取失败（value=nil）时不得落表：否则 castTime=0 永久写入
    -- SavedVariables 且命中缓存永不重学，getchannel 恒返回 0；放弃本次让其可重试
    -- by 武藤纯子酱 2026.9.2
    if castType == "channel" and not value then return nil end

    -- 等级文本与法术 ID：主路径 Nampower GetSpellSlotTypeIdForName（一次调用返回
    -- 槽位/书类型/ID，O(1)）；兜底：法术书扫描（GetSpellName 直到 nil）by 武藤纯子酱 2026.9.1
    local rank, spellId = nil, nil
    if API.features.hasGetSpellSlotTypeIdForName and GetSpellSlotTypeIdForName then
        local ok, slot, bookType, sid = pcall(GetSpellSlotTypeIdForName, spellName)
        if ok and type(slot) == "number" and slot > 0 then
            spellId = (type(sid) == "number" and sid ~= 0) and sid or nil
            local n, r = GetSpellName(slot, bookType or BOOKTYPE_SPELL)
            if n == spellName then rank = r end
        end
    end
    if not rank then
        local maxSlot = GetSpellBookMaxSlot()
        for i = 1, maxSlot do
            local n, r = GetSpellName(i, BOOKTYPE_SPELL)
            if n == spellName then rank = r end
        end
    end
    if not spellId and API.features.hasGetSpellIdForName and GetSpellIdForName then
        -- GetSpellIdForName 支持带等级名（如 "Frostbolt(Rank 1)"），可按等级定位 by 武藤纯子酱 2026.9.2
        spellId = GetSpellIdForName(spellName)
    end

    CleveRoids_SpellCastInfo = CleveRoids_SpellCastInfo or {}
    CleveRoids_SpellCastInfo.spells = CleveRoids_SpellCastInfo.spells or {}
    local entry = {
        spellid = spellId,
        name = spellName,
        rank = rank,
        castType = castType,
        castTime = value or 0,
        line = rawLine,
    }
    CleveRoids_SpellCastInfo.spells[string.lower(spellName)] = entry
    return entry
end

-- 查询（未收录时惰性学习一次；学不到的技能本会话内记失败不再重试）
-- 表只维护 getcast/getchannel 实际引用过的技能——不做全量法术书预扫描 by 武藤纯子酱 2026.9.1
-- 基础值学习持久化到 SavedVariables，已知技能永不重复解析 tooltip
function API.GetStoredSpellCastInfo(spellName)
    if not spellName or spellName == "" then return nil end
    CleveRoids_SpellCastInfo = CleveRoids_SpellCastInfo or {}
    local spells = CleveRoids_SpellCastInfo.spells
    if not spells then
        spells = {}
        CleveRoids_SpellCastInfo.spells = spells
    end
    local key = string.lower(spellName)
    local hit = spells[key]
    if hit then return hit end
    if API._castInfoLearnFailed and API._castInfoLearnFailed[key] then return nil end
    local learned = API.LearnSpellCastInfo(spellName)
    if not learned then
        API._castInfoLearnFailed = API._castInfoLearnFailed or {}
        API._castInfoLearnFailed[key] = true
        return nil
    end
    return spells[key]
end

-- 生效施法时间（0.1s TTL 实时缓存，遵守项目缓存规则≤0.1s）by 武藤纯子酱 2026.9.1
-- kind: "getcast"=施法时间（引导技返回其引导时长；瞬发=0）
--       "getchannel"=引导总时长（仅引导技；非引导返回 nil）
-- 急速变化实时生效：非引导 = 基础值 × 当前 modCastSpeed（GetUnitField 实时读取）；
--                   引导 = GetSpellDuration 实时值（已含玩家时长类修正）
local EFF_TIME_TTL = 0.1
function API.GetEffectiveSpellCastTime(spellName, kind)
    local info = API.GetStoredSpellCastInfo(spellName)
    if not info then return nil end
    local now = GetTime()
    API._castTimeEffCache = API._castTimeEffCache or {}
    local key = string.lower(spellName) .. "|" .. tostring(kind)
    local c = API._castTimeEffCache[key]
    if c and (now - c.t) < EFF_TIME_TTL then return c.value end
    local value
    if kind == "getchannel" then
        if info.castType ~= "channel" then
            value = nil
        elseif info.spellid and GetSpellDuration then
            -- 主路径：Nampower GetSpellDuration 实时值（已应用全部修正，急速/天赋实时反映）
            local ok, ms = pcall(GetSpellDuration, info.spellid)
            value = (ok and ms and ms > 0) and (ms / 1000) or nil
        end
        if not value then
            value = info.castTime  -- 兜底：信息表静态基础值
        end
    else  -- getcast
        if info.castType == "channel" then
            value = info.castTime  -- 引导技的施法时间字段即引导时间
        else
            -- 主路径：基础值 × 当前 modCastSpeed（GetUnitField 实时读取，急速变化实时生效）；
            -- tooltip 字符串解析仅在首次学习基础值时使用（一次性，运行时零解析开销）
            local mod = 1
            if API.features.hasGetUnitField and GetUnitField then
                local m = GetUnitField("player", "modCastSpeed")
                if type(m) == "number" and m > 0 then mod = m end
            end
            value = (info.castTime or 0) * mod
        end
    end
    API._castTimeEffCache[key] = { t = now, value = value }
    return value
end

-- 实时攻速（0.1s TTL）by 武藤纯子酱 2026.9.1
-- kind: "getmh"=主手 / "getoh"=副手 / "getranged"=远程（秒，装备+急速后的实际值）
-- 分层：Nampower GetUnitField（实时实际值，主路径）→ 原版 API（UnitAttackSpeed /
-- UnitRangedDamage，兜底）→ nil。攻速无 tooltip 字符串可解析，不设该层。
function API.GetEffectiveAttackSpeed(kind)
    local now = GetTime()
    API._attackSpeedEffCache = API._attackSpeedEffCache or {}
    local c = API._attackSpeedEffCache[kind]
    if c and (now - c.t) < EFF_TIME_TTL then return c.value end
    local value
    if kind == "getmh" or kind == "getoh" then
        local field = (kind == "getmh") and "baseAttackTime" or "offhandAttackTime"
        -- 主路径：Nampower GetUnitField（毫秒，实时实际值）
        if API.features.hasGetUnitField and GetUnitField then
            local ms = GetUnitField("player", field)
            if type(ms) == "number" and ms > 0 then value = ms / 1000 end
        end
        -- 兜底：原版 UnitAttackSpeed（秒）
        if not value and UnitAttackSpeed then
            local a, b = UnitAttackSpeed("player")
            local s = (kind == "getmh") and a or b
            if type(s) == "number" and s > 0 then value = s end
        end
    else  -- getranged
        -- 主路径：Nampower GetUnitField rangedAttackTime（毫秒，实时实际值）
        if API.features.hasGetUnitField and GetUnitField then
            local ms = GetUnitField("player", "rangedAttackTime")
            if type(ms) == "number" and ms > 0 then value = ms / 1000 end
        end
        -- 兜底：原版 UnitRangedDamage 第 3 返回值（秒）
        if not value and UnitRangedDamage then
            local _, _, s = UnitRangedDamage("player")
            if type(s) == "number" and s > 0 then value = s end
        end
    end
    API._attackSpeedEffCache[kind] = { t = now, value = value }
    return value
end

--------------------------------------------------------------------------------
-- 施法时间/攻速公式引擎 by 武藤纯子酱 2026.9.1
-- 语法（独立命名，不与 [casttime]/[channeltime] 等条件冲突）：
--   getcast(技能名)     实时施法时间（引导技返回其引导时长；瞬发=0）
--   getchannel(技能名)  实时引导总时长（仅引导技）
--   getmh()             实时主手攻击速度（秒）
--   getoh()             实时副手攻击速度（秒；无副手=nil）
--   getranged()         实时远程攻击速度（秒；无远程=nil）
-- 支持 + - * / 与括号、小数
-- 示例：getchannel(奥术飞弹)/5   (getcast(火球术)+0.5)*2   getmh()*2
-- getcast/getchannel 走 API.GetEffectiveSpellCastTime（0.1s TTL，急速实时生效）；
-- 攻速走 API.GetEffectiveAttackSpeed（0.1s TTL，Nampower 实时 API 主路径）
--------------------------------------------------------------------------------

-- 公式函数名清单（IsSpellTimeFormula 与求值器共用）
local FORMULA_FUNC_NAMES = { "getcast", "getchannel", "getmh", "getoh", "getranged" }
local SPEED_FORMULA_FUNCS = { getmh = true, getoh = true, getranged = true }

-- 是否形如施法时间/攻速公式（用于区分普通字符串量）
function API.IsSpellTimeFormula(s)
    if type(s) ~= "string" then return false end
    local t = string.gsub(s, "^%s+", "")
    if string.sub(t, 1, 1) == "(" then return true end
    for _, fn in ipairs(FORMULA_FUNC_NAMES) do
        if string.find(t, "^" .. fn .. "%s*%(") then return true end
    end
    return false
end

-- 字符串中是否包含公式函数调用（任意位置，非锚定）——
-- 供条件参数解析器判断：含公式调用时 "/" 是除号而非 OR 分隔符 by 武藤纯子酱 2026.9.1
function API.FormulaCallPresent(s)
    if type(s) ~= "string" then return false end
    for _, fn in ipairs(FORMULA_FUNC_NAMES) do
        if string.find(s, fn .. "%s*%(", 1, false) then return true end
    end
    return false
end
CleveRoids.FormulaCallPresent = function(s) return API.FormulaCallPresent(s) end

-- 是否存在"被引号包裹的公式段"——条件参数解析器据此跳过多值 "/" 拆分：
-- 公式比较值必须用 "..." 包裹（如 [channeltime:end<"getchannel(奥术飞弹)/6"]），
-- 引号内的 "/" 是除号而非 OR 多值分隔符 by 武藤纯子酱 2026.9.1
function API.QuotedFormulaPresent(s)
    if type(s) ~= "string" then return false end
    for quoted in string.gfind(s, '"([^"]*)"') do
        if API.FormulaCallPresent(quoted) then return true end
    end
    return false
end
CleveRoids.QuotedFormulaPresent = function(s) return API.QuotedFormulaPresent(s) end

-- 求值：返回数值或 nil（语法错误/除零/技能未收录）
function API.EvaluateSpellTimeFormula(expr)
    if type(expr) ~= "string" then return nil end
    local s = expr
    local pos = 1
    local len = string.len(s)

    local skipWS = function()
        while pos <= len do
            local c = string.sub(s, pos, pos)
            if c == " " or c == "\t" then pos = pos + 1 else break end
        end
    end

    local parseExpr  -- 前置声明（+/- 层）

    -- 原子：数字 | 函数调用 | 括号表达式
    local parseAtom = function()
        skipWS()
        if pos > len then return nil end
        if string.sub(s, pos, pos) == "(" then
            pos = pos + 1
            local v = parseExpr()
            skipWS()
            if v and string.sub(s, pos, pos) == ")" then
                pos = pos + 1
                return v
            end
            return nil
        end
        local _, _, num = string.find(s, "^(%d*%.?%d+)", pos)
        if num then
            pos = pos + string.len(num)
            return tonumber(num)
        end
        local funcName, fEnd
        for _, fn in ipairs(FORMULA_FUNC_NAMES) do
            local _, fe = string.find(s, "^" .. fn .. "%s*%(", pos)
            if fe then
                funcName = fn
                fEnd = fe
                break
            end
        end
        if funcName then
            pos = fEnd + 1
            -- 括号深度配平提取参数：技能名可自带等级后缀括号（如 火球术(等级 5)），
            -- 不能只找第一个 ")"，否则参数被截断导致按等级引用失败 by 武藤纯子酱 2026.9.1
            local depth, close = 1, nil
            for j = pos, len do
                local c = string.sub(s, j, j)
                if c == "(" then
                    depth = depth + 1
                elseif c == ")" then
                    depth = depth - 1
                    if depth == 0 then
                        close = j
                        break
                    end
                end
            end
            if not close then return nil end
            local name = string.sub(s, pos, close - 1)
            pos = close + 1
            name = string.gsub(name, "^%s+", "")
            name = string.gsub(name, "%s+$", "")
            -- 去包裹引号：兼容 "..." 包裹写法（如 getcast("火球术(等级 5)")），
            -- 否则带引号名查信息表必然失配 by 武藤纯子酱 2026.9.2
            name = string.gsub(name, '"', "")
            if SPEED_FORMULA_FUNCS[funcName] then
                -- 攻速三兄弟：零参数（括号内忽略），0.1s TTL 实时值
                return API.GetEffectiveAttackSpeed(funcName)
            end
            -- 施法/引导时间：0.1s TTL 实时生效值（急速变化实时反映）
            return API.GetEffectiveSpellCastTime(name, funcName)
        end
        return nil
    end

    -- 一元 +/- 
    local parseFactor
    parseFactor = function()
        skipWS()
        local head = string.sub(s, pos, pos)
        if head == "-" then
            pos = pos + 1
            local v = parseFactor()
            if v then return -v end
            return nil
        elseif head == "+" then
            pos = pos + 1
            return parseFactor()
        end
        return parseAtom()
    end

    -- */ 层
    local parseTerm = function()
        local v = parseFactor()
        if v == nil then return nil end
        while true do
            skipWS()
            local op = string.sub(s, pos, pos)
            if op == "*" or op == "/" then
                pos = pos + 1
                local rhs = parseFactor()
                if rhs == nil then return nil end
                if op == "*" then
                    v = v * rhs
                else
                    if rhs == 0 then return nil end
                    v = v / rhs
                end
            else
                break
            end
        end
        return v
    end

    -- +- 层
    parseExpr = function()
        local v = parseTerm()
        if v == nil then return nil end
        while true do
            skipWS()
            local op = string.sub(s, pos, pos)
            if op == "+" or op == "-" then
                pos = pos + 1
                local rhs = parseTerm()
                if rhs == nil then return nil end
                if op == "+" then v = v + rhs else v = v - rhs end
            else
                break
            end
        end
        return v
    end

    local result = parseExpr()
    skipWS()
    if result == nil or pos <= len then return nil end  -- 有剩余字符 = 解析失败
    return result
end

-- /cleveroid castinfo 子命令处理（由 Init.lua 在 ADDON_LOADED 链入 HandleConsoleCommand）
-- 表只经 getcast/getchannel 引用惰性维护，无 scan 子命令；clear 兼作强制重学 by 武藤纯子酱 2026.9.1
function API.HandleCastInfoCommand(args)
    local _, _, subcmd, rest = string.find(args or "", "^(%S+)%s*(.*)$")
    subcmd = subcmd and string.lower(subcmd) or "show"
    if subcmd == "clear" then
        CleveRoids_SpellCastInfo = { spells = {} }
        API._castInfoLearnFailed = nil
        API._castTimeEffCache = nil
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[SpellCastInfo]|r 已清空，下次引用时惰性重学")
    else
        -- show [技能名]（参数去包裹引号，兼容 show "技能名" 写法）by 武藤纯子酱 2026.9.2
        if rest and rest ~= "" then
            rest = string.gsub(rest, '"', "")
            local info = API.GetStoredSpellCastInfo(rest)
            if info then
                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                    "|cff00ff00[SpellCastInfo]|r %s：ID=%s，%s，%s，时间=%.2fs",
                    tostring(info.name), tostring(info.spellid), tostring(info.rank),
                    info.castType == "channel" and "引导" or "非引导", info.castTime or 0))
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[SpellCastInfo]|r 未收录或无法学习：" .. rest)
            end
        else
            local count = 0
            if CleveRoids_SpellCastInfo and CleveRoids_SpellCastInfo.spells then
                for _ in pairs(CleveRoids_SpellCastInfo.spells) do count = count + 1 end
            end
            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                "|cff00ff00[SpellCastInfo]|r 共 %d 条（仅 getcast/getchannel 引用过的技能）。用法：castinfo show <技能名> / clear。公式：getcast(名)、getchannel(名)、getmh()、getoh()、getranged()，支持 + - * / 括号（均 0.1s TTL 实时值）",
                count))
        end
    end
end

-- CleveRoids 命名空间别名（供 Conditionals 等使用）
CleveRoids.GetStoredSpellCastInfo = function(name) return API.GetStoredSpellCastInfo(name) end
CleveRoids.EvaluateSpellTimeFormula = function(e) return API.EvaluateSpellTimeFormula(e) end
CleveRoids.IsSpellTimeFormula = function(s) return API.IsSpellTimeFormula(s) end

--------------------------------------------------------------------------------
-- RELIQUARY DBC FUNCTIONS (optional DLL)
--------------------------------------------------------------------------------

-- Safe Reliquary call wrapper — returns nil on missing DLL or lookup failure
local function RQ_SafeCall(func, ...)
    if not func then return nil end
    local ok, result = pcall(func, unpack(arg))
    if ok then return result end
    return nil
end

-- Get item set data from DBC by set ID
-- Returns: { name, itemId_1..17, setSpellId_1..8, setThreshold_1..8 } or nil
function API.GetItemSet(setId)
    if not setId or not _G.RQ_GetItemSet then return nil end
    return RQ_SafeCall(_G.RQ_GetItemSet, setId)
end

-- Get the set ID for an item (via Nampower's GetItemStatsField)
-- Returns: setId (number) or nil if item has no set
function API.GetItemSetId(itemId)
    if not itemId then return nil end
    local setId = API.GetItemField(itemId, "itemSet")
    if setId and setId ~= 0 then return setId end
    return nil
end

-- Get all item IDs belonging to a set (from Reliquary DBC)
-- Returns: { itemId1, itemId2, ... } or nil
function API.GetItemSetItems(setId)
    local setData = API.GetItemSet(setId)
    if not setData then return nil end

    local items = {}
    for i = 1, 17 do
        local id = setData["itemId_" .. i]
        if id then
            id = tonumber(id)
            if id and id ~= 0 then
                table.insert(items, id)
            end
        end
    end

    if table.getn(items) > 0 then return items end
    return nil
end

-- Get set bonus spell/threshold pairs from DBC
-- Returns: { { spellId = N, threshold = N }, ... } or nil
function API.GetItemSetBonuses(setId)
    local setData = API.GetItemSet(setId)
    if not setData then return nil end

    local bonuses = {}
    for i = 1, 8 do
        local spellId = setData["setSpellId_" .. i]
        local threshold = setData["setThreshold_" .. i]
        if spellId and threshold then
            spellId = tonumber(spellId)
            threshold = tonumber(threshold)
            if spellId and spellId ~= 0 and threshold and threshold > 0 then
                table.insert(bonuses, { spellId = spellId, threshold = threshold })
            end
        end
    end

    if table.getn(bonuses) > 0 then return bonuses end
    return nil
end

-- Get spell effect radius in yards from DBC
-- spellId: the spell to look up
-- effectIndex: 1, 2, or 3 (which effect slot, default 1)
-- Returns: radius (number) or nil
function API.GetSpellEffectRadius(spellId, effectIndex)
    effectIndex = effectIndex or 1
    if not spellId then return nil end

    -- Get the radius index from the spell's effect via Nampower
    local radiusField = "effectRadiusIndex"
    local rec = API.GetSpellRecord(spellId)
    if not rec then return nil end

    -- effectRadiusIndex is an array field — access by effect index
    local radiusIndex = nil
    if rec.effectRadiusIndex then
        if type(rec.effectRadiusIndex) == "table" then
            radiusIndex = rec.effectRadiusIndex[effectIndex]
        else
            -- Single value (effect 1 only)
            if effectIndex == 1 then
                radiusIndex = rec.effectRadiusIndex
            end
        end
    end

    if not radiusIndex or radiusIndex == 0 then return nil end

    -- Try Reliquary for the SpellRadius DBC lookup
    if _G.RQ_GetSpellRadius then
        local radiusData = RQ_SafeCall(_G.RQ_GetSpellRadius, radiusIndex)
        if radiusData and radiusData.radius then
            local radius = tonumber(radiusData.radius)
            if radius and radius > 0 then return radius end
        end
    end

    return nil
end

function API.FindUnitAuraDispel(unitToken, searchNameLower) -- 新增FindUnitAuraDispel函数检测Dispel类型 by 武藤纯子酱 2026.3.14
    if not unitToken then return false end
    if not searchNameLower then return false end

    local auras = API.GetUnitAuras(unitToken)
    if not auras then return false end  -- GetUnitField unavailable

    for i = 33, 48 do
        local auraId = auras[i]
        if auraId and auraId ~= 0 then
            local matched = false

            if searchNameLower then
				local dispel = GetSpellRecField and GetSpellRecField(auraId, "dispel")
				if CleveRoids.DebuffType[dispel] and CleveRoids.DebuffType[dispel] == searchNameLower then
					matched = true
				end
            end

            if matched then
                return true
            end
        end
    end

    return false
end

-- Expose API globally for other addons
_G.CleveRoids.NampowerAPI = API -- 将CleveRoidsNampowerAPI更名为CleveRoids.NampowerAPI by 武藤纯子酱 2026.2.11
