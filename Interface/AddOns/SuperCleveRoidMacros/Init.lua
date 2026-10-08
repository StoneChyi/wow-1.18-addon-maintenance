local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}
_G.CleveRoids = CleveRoids

-- Global flag for other addons to detect SRCM regardless of folder name
-- (pfUI macrotweak checks IsAddOnLoaded("SuperCleveRoidMacros") which fails
-- if the folder was renamed, e.g. "SuperCleveRoidMacros-main" from GitHub)
_G.SRCM_LOADED = true

CleveRoids.ready = false

CleveRoids.Hooks             = CleveRoids.Hooks      or {}
CleveRoids.Hooks.GameTooltip = {}

CleveRoids.Extensions          = CleveRoids.Extensions or {}
CleveRoids.actionEventHandlers = {}
CleveRoids.mouseOverResolvers  = {}

CleveRoids.mouseoverUnit = CleveRoids.mouseoverUnit or nil

-- Environment flags
-- hasSuperwow 仅用于 [mounted]/[nomounted]/[indoor]/[outdoor] 条件的 IsMounted()/IsIndoors()
-- 检测（这两处是全插件唯一保留的 SuperWoW 依赖）；其余功能全部走 Nampower API by 武藤纯子酱 2026.9.1
CleveRoids.hasSuperwow = SetAutoloot and true or false
CleveRoids.hasTurtle   = (type(_G.TURTLE_WOW_VERSION) ~= "nil")
CleveRoids.hasReliquary = (RQ_GetVersion ~= nil)
CleveRoids.supported   = CleveRoids.hasTurtle

CleveRoids.ParsedMsg = {}
CleveRoids.Items     = {}
CleveRoids.Spells    = {}
CleveRoids.PetSpells = {}
CleveRoids.Talents   = {}
CleveRoids.Cooldowns = {}
CleveRoids.Macros    = {}
CleveRoids.Actions   = {}
CleveRoids.Sequences = {}

CleveRoids.lastUpdate = 0
CleveRoids.lastGetItem = nil
CleveRoids.currentSequence = nil

CleveRoids.bookTypes = {BOOKTYPE_SPELL, BOOKTYPE_PET}
CleveRoids.unknownTexture = "Interface\\Icons\\INV_Misc_QuestionMark"

CleveRoids.spell_tracking = {}

-- GUID-based cast tracking (populated by pfUI 7.6 or standalone SPELL_START events)
-- Format: [casterGuid] = {spellID, spellName, icon, startTime, duration, endTime}
CleveRoids.castTracking = {}

-- pfUI 7.6+ with Nampower 2.31.0+ detected (GUID-based cast tracking available)
CleveRoids.hasPfUI76 = false

-- Combo point tracking (initialized early for /cast hook)
CleveRoids.lastComboPoints = 0
CleveRoids.lastComboPointsTime = 0

-- Resist tracking state
-- Structure: { resistType = "full"|"partial", targetGUID = guid }
CleveRoids.resistState = nil

-- KEY_DOWN/KEY_UP state table (populated when Nampower v2.41+ hasKeyEvents)
CleveRoids._keyState = {}

-- Holds information about the currently cast spell
CleveRoids.CurrentSpell = {
    -- "channeled" or "cast"
    type = "",
    -- the name of the spell
    spellName = "",
    -- is the Attack ability enabled
    autoAttack = false,
    -- is the Auto Shot ability enabled
    autoShot = false,
    -- is the Shoot ability (wands) enabled
    wand = false,
}

-- Enhanced casting state tracking
CleveRoids.UpdateCastingState = function()
    if not GetCurrentCastingInfo then return false end

    local castId, visId, autoId, casting, channeling, onswing, autoattack = GetCurrentCastingInfo()

    -- Update CurrentSpell based on actual cast state
    -- NOTE: Channel state is EXCLUSIVELY managed by SPELLCAST_CHANNEL_START/STOP events
    -- This function NEVER touches channel state, only regular casts
    if casting == 1 then
        CleveRoids.CurrentSpell.type = "cast"
        CleveRoids.CurrentSpell.castingSpellId = castId
    elseif CleveRoids.CurrentSpell.type == "cast" then
        -- Only clear if we were in a regular cast (not channel)
        CleveRoids.CurrentSpell.type = ""
        CleveRoids.CurrentSpell.castingSpellId = nil
    end
    -- DO NOT touch channel state here - events handle it

    -- Always update metadata from GetCurrentCastingInfo (onswing/autoattack only here)
    CleveRoids.CurrentSpell.autoAttack = (autoattack == 1)
    CleveRoids.CurrentSpell.onSwingPending = (onswing == 1)
    CleveRoids.CurrentSpell.visualSpellId = visId
    CleveRoids.CurrentSpell.autoRepeatSpellId = autoId
    
    -- Enhanced timing data from GetCastInfo (Nampower 2.18+)
    if GetCastInfo then
        local ok, info = pcall(GetCastInfo)
        if ok and info then
            CleveRoids.CurrentSpell.castRemainingMs = info.castRemainingMs
            CleveRoids.CurrentSpell.castEndTime = info.castEndS
            CleveRoids.CurrentSpell.gcdRemainingMs = info.gcdRemainingMs
            CleveRoids.CurrentSpell.gcdEndTime = info.gcdEndS
        else
            CleveRoids.CurrentSpell.castRemainingMs = nil
            CleveRoids.CurrentSpell.castEndTime = nil
            CleveRoids.CurrentSpell.gcdRemainingMs = nil
            CleveRoids.CurrentSpell.gcdEndTime = nil
        end
    end

    return true
end

CleveRoids.dynamicCmds = {
    ["/cast"]         = true,
    ["/castpet"]      = true,
    ["/castsequence"] = true,
    ["/use"]          = true,
    ["/equip"]        = true,
    ["/equipmh"]      = true,
    ["/equipoh"]      = true,
    ["/equip11"]      = true,
    ["/equip12"]      = true,
    ["/equip13"]      = true,
    ["/equip14"]      = true,
    ["/applymain"]    = true,
    ["/applyoff"]     = true,
}

-- Equipment swap queue system
CleveRoids.equipmentQueue = {}
CleveRoids.equipmentQueueLen = 0  -- PERFORMANCE: Track length to avoid table.getn() every frame
CleveRoids.lastEquipTime = {}
CleveRoids.lastGlobalEquipTime = 0
CleveRoids.EQUIP_COOLDOWN = 1.5  -- Per-slot cooldown
CleveRoids.EQUIP_GLOBAL_COOLDOWN = 0.5  -- Global cooldown

-- PERFORMANCE: Table pool for queue entries to reduce garbage collection
CleveRoids.queueEntryPool = {}

-- PERFORMANCE: Static buffer for proc removal to avoid per-frame allocation
CleveRoids._procRemovalBuffer = {}

-- PERFORMANCE: Static buffer for action grouping to avoid per-call allocation
CleveRoids._actionsToSlotsBuffer = {}
CleveRoids._slotsBuffer = {}
CleveRoids._actionsListBuffer = {}

-- PERFORMANCE: Static buffer for arg backup in SendEventForAction
CleveRoids._originalArgsBuffer = {}

-- KEYED DEBUG: Only prints when the message for a given key changes from last print.
-- Usage: CleveRoids.DebugChanged("immunity_moonfire", formatted_msg)
-- Prevents spam when the same state is reported repeatedly (e.g., per-frame or per-eval).
CleveRoids._lastDebugState = {}
function CleveRoids.DebugChanged(key, msg)
  if not CleveRoids.debug then return end
  if CleveRoids._lastDebugState[key] == msg then return end
  CleveRoids._lastDebugState[key] = msg
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

-- Spell queue state (Nampower)
CleveRoids.queuedSpell = nil
CleveRoids.lastCastSpell = nil

-- 帧内施法护栏：同一帧内多行宏里，前一行 /cast 已发起施法/排队，
-- 但 SPELL_QUEUE_EVENT（queuedSpell 来源）是帧末才派发，本帧内后续宏行的
-- [nochanneling]/[checkchanneled]/[checkcasting] 等守卫看不到排队状态，
-- 会误判"空闲"而把填充法术排队，覆盖 CD 技的排队槽位（Nampower 单槽队列 →
-- CD 技永远不施放、填充技无限连发）by 武藤纯子酱 2026.9.9
CleveRoids._castIssuedThisFrame = false

-- Macro execution control
CleveRoids.stopMacroFlag = false
CleveRoids.skipMacroFlag = false -- 新增 初始化 by 武藤纯子酱 2026.1.16
CleveRoids.stopOnCastFlag = false -- 新增 初始化 by 武藤纯子酱 2026.1.16

-- PERFORMANCE: Event-driven cached state (updated on events, not polled)
CleveRoids._cachedPlayerInCombat = nil   -- Updated on PLAYER_REGEN_DISABLED, PLAYER_REGEN_ENABLED

CleveRoids.ignoreKeywords = {
    action        = true,
    ignoretooltip = true,
    cancelaura    = true,
    noSpam        = true,  -- ! prefix flag: prevent toggle-off at execution time
    _operators    = true,  -- Metadata for AND/OR operator tracking
    _groups       = true,  -- Grouped conditional values for AND/OR evaluation
    multiscan     = true,  -- Processed before Keywords loop (target resolution)
    mouseuse      = true,  -- Post-cast modifier: auto-click AOE targeting circle at cursor
    stopattack    = true,  -- Post-cast modifier: stop autoattack after cast (CheapShot pattern)
    message       = true,   -- 新增 by 武藤纯子酱 2026.8.10
}

-- TODO: Localize?
CleveRoids.countedItemTypes = {
    ["Consumable"]  = true,
    ["Reagent"]     = true,
    ["Projectile"]  = true,
    ["Trade Goods"] = true,
}


-- TODO: Localize?
CleveRoids.actionSlots    = {}
CleveRoids.reactiveSlots  = {}
CleveRoids.reactiveSpells = {
    [CleveRoids.Localized.Spells["Revenge"]]         = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Overpower"]]       = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Riposte"]]         = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Surprise Attack"]] = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Lacerate"]]        = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Baited Shot"]]     = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Counterattack"]]   = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Arcane Surge"]]    = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
    [CleveRoids.Localized.Spells["Aquatic Form"]]    = true, -- 新增多语言支持 by 武藤纯子酱 2026.2.2
}

CleveRoids.spamConditions = {
    [CleveRoids.Localized.Attack]   = "checkchanneled",
    [CleveRoids.Localized.AutoShot] = "checkchanneled",
    [CleveRoids.Localized.Shoot]    = "checkchanneled",
}

-- PERFORMANCE: Static lookup for toggled buff abilities (built once, used per-frame)
CleveRoids._toggledBuffAbilities = {
    [CleveRoids.Localized.Spells["Prowl"]] = true,
    [CleveRoids.Localized.Spells["Shadowmeld"]] = true,
}

function CleveRoids.IsToggledBuffAbility(spellName)
    return CleveRoids._toggledBuffAbilities[spellName]
end

CleveRoids.auraTextures = {
    [CleveRoids.Localized.Spells["Stealth"]]    = "Interface\\Icons\\Ability_Stealth",
    [CleveRoids.Localized.Spells["Prowl"]]      = "Interface\\Icons\\Spell_Nature_Invisibilty",
    [CleveRoids.Localized.Spells["Shadowform"]] = "Interface\\Icons\\Spell_Shadow_Shadowform",
    [CleveRoids.Localized.Spells["Shadowmeld"]] = "Interface\\Icons\\Spell_Nature_WispSplode",
    ["Seal of Wisdom"] = "Interface\\Icons\\Spell_Holy_RighteousnessAura",
    ["Seal of the Crusader"] = "Interface\\Icons\\Spell_Holy_HolySmite",
    ["Seal of Light"] = "Interface\\Icons\\Spell_Holy_HealingAura",
    ["Seal of the Justice"] = "Interface\\Icons\\Spell_Holy_SealOfWrath",
    ["Seal of Righteousness"] = "Interface\\Icons\\Ability_ThunderBolt",
    ["Seal of Command"] = "Interface\\Icons\\Ability_Warrior_InnerRage",
}


-- I need to make a 2h modifier
-- Maps easy to use weapon type names (e.g. Axes, Shields) to their inventory slot name and their localized tooltip name
CleveRoids.WeaponTypeNames = {
    Daggers   = { slot = "MainHandSlot", name = CleveRoids.Localized.Dagger },
    Fists     = { slot = "MainHandSlot", name = CleveRoids.Localized.FistWeapon },
    Axes      = { slot = "MainHandSlot", name = CleveRoids.Localized.Axe },
    Swords    = { slot = "MainHandSlot", name = CleveRoids.Localized.Sword },
    Staves    = { slot = "MainHandSlot", name = CleveRoids.Localized.Staff },
    Maces     = { slot = "MainHandSlot", name = CleveRoids.Localized.Mace },
    Polearms  = { slot = "MainHandSlot", name = CleveRoids.Localized.Polearm },
    -- OH
    Daggers2  = { slot = "SecondaryHandSlot", name = CleveRoids.Localized.Dagger },
    Fists2    = { slot = "SecondaryHandSlot", name = CleveRoids.Localized.FistWeapon },
    Axes2     = { slot = "SecondaryHandSlot", name = CleveRoids.Localized.Axe },
    Swords2   = { slot = "SecondaryHandSlot", name = CleveRoids.Localized.Sword },
    Maces2    = { slot = "SecondaryHandSlot", name = CleveRoids.Localized.Mace },
    Shields   = { slot = "SecondaryHandSlot", name = CleveRoids.Localized.Shield },
    -- ranged
    Guns      = { slot = "RangedSlot", name = CleveRoids.Localized.Gun },
    Crossbows = { slot = "RangedSlot", name = CleveRoids.Localized.Crossbow },
    Bows      = { slot = "RangedSlot", name = CleveRoids.Localized.Bow },
    Thrown    = { slot = "RangedSlot", name = CleveRoids.Localized.Thrown },
    Wands     = { slot = "RangedSlot", name = CleveRoids.Localized.Wand },
}

-- Detect available features
CleveRoids.hasNampower = (QueueSpellByName ~= nil)
CleveRoids.hasUnitXP = pcall(UnitXP, "nop", "nop")

-- UnitXP（UnitXP_SP3 DLL）加固：参数非法 / 版本不符时 DLL 可能直接抛错（红字），统一 pcall 包裹，
-- 失败返回 nil，成功时原样透传多返回值。按实参个数精确转发，避免给 DLL 多传 nil 参数。
-- 注：Lua 5.0 变参只能读隐式 arg 表，不能把 ... 当表达式用 by 武藤纯子酱 2026.9.23
function CleveRoids.SafeUnitXP(...)
    local fn = _G.UnitXP
    if type(fn) ~= "function" then return nil end
    local n = (arg and arg.n) or 0
    local ok, r1, r2, r3
    if n >= 6 then ok, r1, r2, r3 = pcall(fn, arg[1], arg[2], arg[3], arg[4], arg[5], arg[6])
    elseif n == 5 then ok, r1, r2, r3 = pcall(fn, arg[1], arg[2], arg[3], arg[4], arg[5])
    elseif n == 4 then ok, r1, r2, r3 = pcall(fn, arg[1], arg[2], arg[3], arg[4])
    elseif n == 3 then ok, r1, r2, r3 = pcall(fn, arg[1], arg[2], arg[3])
    elseif n == 2 then ok, r1, r2 = pcall(fn, arg[1], arg[2])
    elseif n == 1 then ok, r1 = pcall(fn, arg[1])
    else ok, r1 = pcall(fn) end
    if not ok then return nil end
    return r1, r2, r3
end

-- @fov（瞄准射击智能选目标）：需 UnitXP_SP3_X 版（含 farthestInFOV）；否则 @fov 回退当前目标。
-- 视野锥/距离配置存于 CleveRoidMacros.fovCone / .fovRange（/cleveroid fov 修改）by 武藤纯子酱 2026.9.12
CleveRoids.hasUnitXPFOV = false
if CleveRoids.hasUnitXP and UnitXP then
    local ok, unitxp = pcall(UnitXP, "version")
    if ok and type(unitxp) == "string" and string.find(unitxp, "UnitXP_SP3_X", 1, true) then
        CleveRoids.hasUnitXPFOV = true
    end
end

-- Nampower 专属能力标志（默认 false，由 NampowerAPI 特性检测回填）：
-- hasNampowerGuidAPI : Nampower v3.0+ GetUnitGUID —— GUID/mark#/owner 扩展 token 可用于
--                      原生单位函数（替代 SuperWoW 的 GUID 通用单位参数）
-- hasAuraSpellIds    : Nampower GetUnitField 可用且 UnitBuff/UnitDebuff spellID hook 已安装
--                      （替代 SuperWoW 的 aura spellID 扩展返回值与 GetPlayerBuffID） by 武藤纯子酱 2026.9.1
CleveRoids.hasNampowerGuidAPI = false
CleveRoids.hasAuraSpellIds = false

-- Extended Nampower feature flags (populated by NampowerAPI.lua)
CleveRoids.nampowerVersion = { major = 0, minor = 0, patch = 0 }
CleveRoids.hasExtendedNampower = false  -- True if v2.12+ with new API functions

-- Feature detection messages
local function PrintFeatures()
    local features = {}
    if CleveRoids.hasSuperwow then table.insert(features, "SuperWoW") end
    if CleveRoids.hasNampower then
        local ver = CleveRoids.nampowerVersion
        if ver.major > 0 then
            table.insert(features, string.format("Nampower v%d.%d.%d", ver.major, ver.minor, ver.patch))
        else
            table.insert(features, "Nampower")
        end
    end
    if CleveRoids.hasUnitXP then table.insert(features, "UnitXP") end
    if CleveRoids.hasReliquary then
        local ok, major, minor, patch = pcall(RQ_GetVersion)
        if ok and major then
            table.insert(features, string.format("Reliquary v%d.%d.%d", major, minor, patch))
        else
            table.insert(features, "Reliquary")
        end
    end
    if CleveRoids.hasTurtle then table.insert(features, "Turtle") end

    if table.getn(features) > 0 then
        CleveRoids.Print("Enhanced features: " .. table.concat(features, ", "))
    end
end

-- Immunity data version - increment this when changing immunity data format
-- This will cause all immunity data to be reset on addon update
-- v3: Fixed Master Strike false physical immunity recording (split CC spell handling)
-- v4: Fixed false immunity recording when target dies with spells in-flight (dead = IMMUNE)
-- v5: Fixed false physical immunity from unknown spell schools (now uses DBC lookup; unknown defaults to nil not "physical")
-- v6: Reset stale immunity data that may contain false positives
CleveRoids.IMMUNITY_DATA_VERSION = 6

-- Call on next frame to ensure everything is loaded
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    this:UnregisterAllEvents()

    -- Check immunity data version and reset if outdated
    CleveRoidMacros = CleveRoidMacros or {}
    CleveRoids_ImmunityData = CleveRoids_ImmunityData or {}
    local savedVersion = CleveRoidMacros.immunityDataVersion or 0

    if savedVersion < CleveRoids.IMMUNITY_DATA_VERSION then
        -- Check if there was existing data to clear
        local hadData = next(CleveRoids_ImmunityData) ~= nil

        -- Version changed - reset all immunity data
        CleveRoids_ImmunityData = {}
        CleveRoidMacros.immunityDataVersion = CleveRoids.IMMUNITY_DATA_VERSION

        if hadData then
            -- Show message if we actually cleared existing data
            CleveRoids.Print("|cffff9900Immunity data reset|r - addon updated to data version " .. CleveRoids.IMMUNITY_DATA_VERSION)
        end
    end

    -- Detect pfUI macrotweak conflict (folder name mismatch)
    -- pfUI macrotweak disables itself via IsAddOnLoaded("SuperCleveRoidMacros"),
    -- but this fails when the addon folder is renamed (e.g. GitHub download adds "-main").
    -- When both are active: conflicting SendChatMessage hooks, duplicate /use and /equip
    -- handlers, and #showtooltip can leak into chat (pfUI only filters "#showtooltip "
    -- with trailing space, missing bare "#showtooltip").
    if pfUI and pfUI.module and pfUI.module["macrotweak"]
       and not IsAddOnLoaded("SuperCleveRoidMacros") then
        CleveRoids.Print("|cffff0000WARNING:|r Your addon folder name is not |cff00ff00SuperCleveRoidMacros|r.")
        CleveRoids.Print("This causes a conflict with pfUI's macrotweak module.")
        CleveRoids.Print("Please rename the folder to exactly |cff00ff00SuperCleveRoidMacros|r and /reload.")
    end

    -- Initialize NampowerAPI if available
    if CleveRoids.NampowerAPI then
        local API = CleveRoids.NampowerAPI

        -- Get version info
        local major, minor, patch = API.GetVersion()
        CleveRoids.nampowerVersion = { major = major, minor = minor, patch = patch }

        -- Check for extended API (v2.12+)
        CleveRoids.hasExtendedNampower = API.HasMinimumVersion(2, 12, 0)

        -- Sync feature flags
        if API.features then
            CleveRoids.hasGetSpellRec = API.features.hasGetSpellRec
            CleveRoids.hasGetItemStats = API.features.hasGetItemStats
            CleveRoids.hasGetUnitData = API.features.hasGetUnitData
            CleveRoids.hasGetSpellModifiers = API.features.hasGetSpellModifiers
            CleveRoids.hasEnhancedSpellFunctions = API.features.hasEnhancedSpellFunctions
            -- v2.37+: CastSpellByName supports unit token strings as 2nd param
            CleveRoids.hasCastSpellByNameUnitToken = API.features.hasCastSpellByNameUnitToken
            -- v3.0+ GetUnitGUID：GUID/mark#/owner 扩展 token 可用于原生单位函数 by 武藤纯子酱 2026.9.1
            CleveRoids.hasNampowerGuidAPI = API.features.hasGetUnitGUID
            -- v2.8+ GetUnitField：UnitBuff/UnitDebuff spellID hook 在本文件加载时已安装 by 武藤纯子酱 2026.9.1
            CleveRoids.hasAuraSpellIds = API.features.hasGetUnitField
        end

        -- Initialize the API
        API.Initialize()

        -- /cleveroid castinfo 子命令：技能施法信息表查看/清空（链式挂到 HandleConsoleCommand 末尾，
        -- 此处 ADDON_LOADED 时机晚于 Console/CursiveCustomSpells 的定义与钩子，链不会断）by 武藤纯子酱 2026.9.1
        if API.HandleCastInfoCommand then
            local prevConsoleHandler = CleveRoids.HandleConsoleCommand
            CleveRoids.HandleConsoleCommand = function(msg)
                local _, _, cmd, args = string.find(msg or "", "^(%S+)%s*(.*)$")
                if cmd and string.lower(cmd) == "castinfo" then
                    API.HandleCastInfoCommand(args)
                    return
                end
                if prevConsoleHandler then return prevConsoleHandler(msg) end
            end
        end
    end    

    PrintFeatures()
end)

--新增鼠标按键1-5的支持 by 武藤纯子酱 2025.11.26
CleveRoids.MouseDown = "LeftButton"
CleveRoids.MouseDownTime = GetTime() -- 新增 by 武藤纯子酱 2025.11.26
CleveRoids.Allbutton = {}

function CleveRoids.GetAllButtons()
    -- 修复：按钮帧可能为 nil（条形插件未初始化/改名）时 table.insert 会留下空洞，
    -- 导致下方 ipairs 在空洞处提前停止、后续按钮漏挂 OnMouseDown；改为只插入非 nil by 武藤纯子酱 2026.9.12
    local function addButton(btn)
        if btn then table.insert(CleveRoids.Allbutton, btn) end
    end

    for i = 1, 12 do
        addButton(_G["ActionButton"..i])
        addButton(_G["MultiBarBottomLeftButton"..i])
        addButton(_G["MultiBarBottomRightButton"..i])
        addButton(_G["MultiBarRightButton"..i])
        addButton(_G["MultiBarLeftButton"..i])
        addButton(_G["BonusActionButton"..i])
    end

    if pfUI and pfUI.bars then
        for i = 1, 12 do
            addButton(_G["pfActionBarMainButton"..i])
            addButton(_G["pfActionBarPagingButton"..i])
            addButton(_G["pfActionBarRightButton"..i])
            addButton(_G["pfActionBarVerticalButton"..i])
            addButton(_G["pfActionBarLeftButton"..i])
            addButton(_G["pfActionBarTopButton"..i])
        end
    end

    if ZBAR_VERSION then
        for barIndex = 1, 4 do
            for buttonIndex = 1, 12 do
                addButton(_G["zBar"..barIndex.."Button"..buttonIndex])
            end
        end
    end

    for _, v in ipairs(CleveRoids.Allbutton) do
        v:SetScript("OnMouseDown", function()
            if arg1 then 
                CleveRoids.MouseDown = arg1 
                CleveRoids.MouseDownTime = GetTime()
            end
        end)
    end
    
    return
end

-- 创建工具提示扫描器 by 武藤纯子酱 2025.11.26
CleveRoids.Scanner = CreateFrame("GameTooltip", "CleverDismountScanner", nil, "GameTooltipTemplate")
CleveRoids.Scanner:SetOwner(UIParent, "ANCHOR_NONE")

CleveRoids.MountPatterns = {
    -- deDE
    "^Erhöht Tempo um (.+)%%",
    -- enUS
    "^Increases speed by (.+)%%",
    -- esES
    "^Aumenta la velocidad en un (.+)%%",
    -- frFR
    "^Augmente la vitesse de (.+)%%",
    -- ruRU
    "^Скорость увеличена на (.+)%%",
    -- koKR
    "^이동 속도 (.+)%%만큼 증가",
    -- zhCN
    "^速度提高(.+)%%",

    -- turtle-wow
    "speed based on",
    "Slow and steady...",
    "Riding",
    "根据您的骑行技能提高速度。",
    "根据骑术技能提高速度。",
    "又慢又稳......",
}

CleveRoids.FlyMountPatterns = {
    -- turtle-wow flying ride
    "Increases flying speed by (.+)%% for (.+) sec.",
    "飞行速度提高(.+)%%。",
}

CleveRoids.SpellCastTimes = CleveRoids.SpellCastTimes or {} -- 添加delay延迟记录表 by 武藤纯子酱 2025.11.26
CleveRoids.AssistsUnit = CleveRoids.AssistsUnit or {} -- 添加assists延迟记录表 by 武藤纯子酱 2025.11.26
CleveRoids.SpellTarget = CleveRoids.SpellTarget or {} -- 添加delay目标延迟记录表 by 武藤纯子酱 2026.1.20
CleveRoids.Tags = CleveRoids.Tags or {} -- 添加Tags标签表 by 武藤纯子酱 2026.1.27
CleveRoids.SetTags = false -- 添加/settag标记，表示当前正在settag by 武藤纯子酱 2026.1.28
CleveRoids.TagUnits = CleveRoids.TagUnits or {} -- 添加TagUnits标签表 by 武藤纯子酱 2026.1.27

-- 创建一个事件监听器框架
local Last_Friend_Target = CreateFrame("Frame")
CleveRoids.LastFriendTarget = nil

-- 注册需要监听的事件
Last_Friend_Target:RegisterEvent("PLAYER_TARGET_CHANGED")

Last_Friend_Target:SetScript("OnEvent", function()
    if UnitExists("target") and UnitIsFriend("player", "target") then 
        CleveRoids.LastFriendTarget = CleveRoids.GetGUID("target")
    end;
end)

-- 增加宏执行栈结构 by 武藤纯子酱 2025.11.26
CleveRoids.MacroStack = {}
CleveRoids.MaxMacroDepth = 10 -- 最大递归深度


-- 安全执行宏的函数 by 武藤纯子酱 2025.11.26
function CleveRoids.SafeRunMacro(macroType, msg)
    local action = function(args)
        -- 在条件处理前检查调用栈
        local stackSize = table.getn(CleveRoids.MacroStack)
        local currentMacro = stackSize > 0 and CleveRoids.MacroStack[stackSize] or nil
        if currentMacro and currentMacro == args then
            CleveRoids.Print("警告: 宏不能直接调用自身")
            return false
        end
        
        -- 检查调用栈深度
        if stackSize >= CleveRoids.MaxMacroDepth then
            CleveRoids.Print("警告: 宏调用深度超过限制 ("..CleveRoids.MaxMacroDepth..")")
            return false
        end
        
        if macroType == "macro" then
            return CleveRoids.ExecuteMacroByName(args)
        else
            return RunSuperMacro(args)
        end
    end
    
    if string.find(msg, "%[") then
        return CleveRoids.DoWithConditionals(msg, nil, CleveRoids.FixEmptyTarget, false, action)
    else
        return action(msg)
    end
end

-- 按条件选中目标 by 武藤纯子酱 2025.11.26
function CleveRoids.DoConditionalTargeting(msg, targetFunc, isFriendly)
    local unitID = CleveRoids.GetGUID("target")

    -- handled 必须声明在 for 循环外：局部变量作用域仅限循环体，循环后读到全局
    -- nil 会导致"条件已命中也执行恢复目标"，/targetenemyplayer 等全部失效
    -- （旧版此处为全局赋值能工作但不规范）by 武藤纯子酱 2026.9.3
    local handled = false
    for k, v in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
        if CleveRoids.DoWithConditionals(v, targetFunc, CleveRoids.FixEmptyTarget, false,
            function(name)
                if name and name ~= "" then
                    targetFunc(name)
                else
                    targetFunc()
                end

                -- 验证目标类型
                if UnitExists("target") then
                    if isFriendly then
                        if not UnitCanAssist("player", "target") then
                            if unitID then
                                TargetUnit(unitID)
                            else
                                ClearTarget()
                            end
                        end
                    else
                        if not UnitCanAttack("player", "target") then
                            if unitID then
                                TargetUnit(unitID)
                            else
                                ClearTarget()
                            end
                        end
                    end
                end
            end) then
            handled = true
            break
        end
    end
    -- 如果未处理（条件不满足），恢复之前的目标
    if not handled then
        if unitID then
            TargetUnit(unitID)
        else
            ClearTarget()
        end
    end
    return handled
end

-- 装备到指定装备栏 by 武藤纯子酱 2025.11.26
function CleveRoids.EquipItemToSlot(itemName, slotId)
    local item = CleveRoids.GetItem(itemName)
    if not item then return false end
    -- 检查当前槽位是否已经装备了这个物品
    local currentItemLink = GetInventoryItemLink("player", slotId)
    if currentItemLink then
        local _,_,itemId = string.find(currentItemLink,"item:(%d+)")        
        local currentItemName = GetItemInfo(itemId)    
        if currentItemName and currentItemName == item.name then
            return true -- 已经装备，不需要操作
        end
    end
    if item.bagID then
        CleveRoids.GetNextBagSlotForUse(item, itemName)
        PickupContainerItem(item.bagID, item.slot)
    elseif item.inventoryID then
        PickupInventoryItem(item.inventoryID)
    else
        return false
    end
    EquipCursorItem(slotId)
    ClearCursor()
    CleveRoids.lastItemIndexTime = 0
    return true
end

-- 创建主帧用于定时更新
CleveRoids.TimerFrame = CreateFrame("Frame")
local DeathTimers = {} -- 全局表存储存活目标的计时数据

-- 定义定时器参数
local interval = 0.3
local elapsedTime = 0

-- 预估单位死亡时间
function CleveRoids.CalculateTimeRemaining(unitID)
    local data = DeathTimers[unitID]
    if not data or not data.historyCount or data.historyCount < 2 then return 1000 end
    
    -- 1. 加权平均法计算剩余时间
    local totalWeight = 0
    local weightedDamage = 0
    local maxHistory = 50
    
    for i = math.max(1, data.historyCount - maxHistory + 1), data.historyCount do
        if data.history[i] then
            local weight = 1 + (i - (data.historyCount - maxHistory)) * 0.8
            weightedDamage = weightedDamage + (data.history[i].damage or 0) * weight
            totalWeight = totalWeight + weight
        end
    end
    
    local timeRemainingWeighted = data.lastTimeRemaining or 1000
    if totalWeight > 0 then
        local avgDPS = (weightedDamage / totalWeight) / interval
        if avgDPS > 0 then
            timeRemainingWeighted = math.max(0, CleveRoids.NampowerAPI.GetUnitHealth(unitID) / avgDPS)
        end
    end
    
    -- 2. 近5秒平均伤害法计算剩余时间 - 使用实际时间跨度
    local currentTime = GetTime()
    local damage5s = 0
    local earliestTime = currentTime  -- 记录最早的有效伤害时间
    
    -- 遍历历史记录，统计最近5秒内的伤害总和
    for i = data.historyCount, 1, -1 do
        local record = data.history[i]
        if not record or not record.time then break end
        
        local timeDiff = currentTime - record.time
        if timeDiff <= 5 then
            damage5s = damage5s + (record.damage or 0)
            earliestTime = record.time  -- 更新最早的时间戳
        else
            break  -- 一旦超出5秒范围就停止遍历
        end
    end
    
    local timeRemaining5s = 1000
    local timeSpan = math.max(0.1, currentTime - earliestTime) -- 实际时间跨长，最小0.1秒
    
    --至少需要3秒数据才信任近5秒统计，否则只用加权平均
    if timeSpan >= 3 then
        local dps5s = damage5s / timeSpan  -- 使用实际时间跨长计算DPS
        timeRemaining5s = math.max(0, CleveRoids.NampowerAPI.GetUnitHealth(unitID) / dps5s)
        
        -- Debug: 查看实际统计时间跨长
        -- CleveRoids.Print("Time Span: ", string.format("%.1f秒", timeSpan))
    end
    
    -- 更新最后使用的剩余时间
    data.lastTimeRemaining = timeRemainingWeighted

    -- 返回两种算法的最小值
    return (timeSpan >= 3) and math.min(timeRemainingWeighted, timeRemaining5s) or timeRemainingWeighted
end

-- 计算到血量还剩20%所需时间
function CleveRoids.GetTimeTo20PercentHealth(unit)
    if not unit then unit = "target" end
    
    -- 如果单位不存在，返回1000
    if not UnitExists(unit) then
        return 1000, false
    end
    
    -- 如果单位已死亡或灵魂状态，返回0
    if UnitIsDeadOrGhost(unit) then
        return 0, true
    end
    
    -- 获取当前血量和最大血量
    local currentHealth = CleveRoids.NampowerAPI.GetUnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)
    
    -- 如果最大血量为0，返回1000
    if maxHealth <= 0 or not maxHealth then
        return 1000, false
    end
    
    -- 计算当前血量百分比
    local currentPercent = (currentHealth / maxHealth) * 100
    
    -- 如果当前血量已经低于20%，直接返回true
    if currentPercent <= 20 then
        return 0, true
    end
    
    -- 计算20%血量的具体值
    local healthThreshold = maxHealth * 0.2
    
    -- 计算需要减少的血量
    local healthToLose = currentHealth - healthThreshold
    
    -- 如果不需要减少血量（理论上不会发生，但安全起见）
    if healthToLose <= 0 then
        return 0, true
    end
    
    -- 获取单位GUID用于查找历史数据
    local unitID = CleveRoids.GetGUID(unit)
    
    -- 获取该单位的伤害历史数据
    local data = DeathTimers[unitID]
    if not data or not data.historyCount or data.historyCount < 2 then
        -- 没有足够的历史数据，无法预估
        return 1000, false
    end
    
    -- 使用与死亡预估相同的算法计算当前DPS
    local currentTime = GetTime()
    
    -- 1. 加权平均法计算DPS
    local totalWeight = 0
    local weightedDamage = 0
    local maxHistory = 50
    
    for i = math.max(1, data.historyCount - maxHistory + 1), data.historyCount do
        if data.history[i] then
            local weight = 1 + (i - (data.historyCount - maxHistory)) * 0.8
            weightedDamage = weightedDamage + (data.history[i].damage or 0) * weight
            totalWeight = totalWeight + weight
        end
    end
    
    local weightedDPS = 0
    if totalWeight > 0 then
        weightedDPS = (weightedDamage / totalWeight) / interval
    end
    
    -- 2. 近5秒平均伤害法计算DPS
    local damage5s = 0
    local earliestTime = currentTime
    
    -- 遍历历史记录，统计最近5秒内的伤害总和
    for i = data.historyCount, 1, -1 do
        local record = data.history[i]
        if not record or not record.time then break end
        
        local timeDiff = currentTime - record.time
        if timeDiff <= 5 then
            damage5s = damage5s + (record.damage or 0)
            earliestTime = record.time
        else
            break
        end
    end
    
    local dps5s = 0
    local timeSpan = math.max(0.1, currentTime - earliestTime)
    
    if timeSpan >= 3 then
        dps5s = damage5s / timeSpan
    end
    
    -- 选择更保守的DPS估计（取较小值，这样预估时间会更长，更安全）
    local estimatedDPS = 0
    if weightedDPS > 0 and dps5s > 0 then
        estimatedDPS = math.min(weightedDPS, dps5s)
    elseif weightedDPS > 0 then
        estimatedDPS = weightedDPS
    elseif dps5s > 0 then
        estimatedDPS = dps5s
    else
        -- 没有有效的DPS数据
        return 1000, false
    end
    
    -- 如果DPS为0或负数，无法预估
    if estimatedDPS <= 0 then
        return 1000, false
    end
    
    -- 计算到20%血量所需时间
    local timeTo20Percent = healthToLose / estimatedDPS
    
    -- 返回预估时间（秒），以及是否已低于20%
    return math.max(0, timeTo20Percent), false
end

-- 简化调用接口：如果低于20%返回0，否则返回剩余时间
function CleveRoids.GetTargetPercent20Time(unit)
    if not unit then unit = "target" end
    
    local timeRemaining, isBelow20 = CleveRoids.GetTimeTo20PercentHealth(unit)
    
    if isBelow20 then
        return 0
    elseif timeRemaining then
        return timeRemaining
    else
        -- 无法预估的情况
        return 1000
    end
end

-- 主体函数
-- 性能优化：①unitsToCheck 改用模块级复用表（原每 tick 新建）；
-- ②历史条目表复用+回收（原每战斗单位每 tick 新建 {damage,time} 表，团战 ≈100 表/s）。
-- history 保持线性数组（消费方 CalculateTimeRemaining 按序号加权读取，环形化需改 4 处读取循环）
-- by 武藤纯子酱 2026.8.31
local _unitsToCheckPool = {}
CleveRoids.TimerFrame:SetScript("OnUpdate", function()
    if (GetTime() - elapsedTime) < interval then
        return
    end
    elapsedTime = GetTime()
    local unitsToCheck = _unitsToCheckPool

    if (elapsedTime - CleveRoids.MouseDownTime) > 0.1 then  -- 新增定期清除鼠标按键记录 by 武藤纯子酱 2025.11.27
        CleveRoids.MouseDown = "LeftButton"
    end

    -- 遍历所有跟踪的单位
    for guid, _ in pairs(CleveRoids.knownEnemyGuids) do
        if UnitAffectingCombat(guid) then
            unitsToCheck[guid] = true
        end
    end

    -- 清理无效单位：移除"已不在追踪列表（unitsToCheck）"、"已脱离战斗"或"已死亡"的目标，
    -- 其余目标的历史保留（切换目标不再清空，避免频繁重置 ttk/死亡预估）by 武藤纯子酱 2026.9.9
    for unitID in pairs(DeathTimers) do
        local valid = false
        if unitsToCheck[unitID] and (CleveRoids.hasNampowerGuidAPI or UnitExists(unitID)) then
            valid = UnitAffectingCombat(unitID) and not UnitIsDeadOrGhost(unitID)
        end
        if not valid then
            DeathTimers[unitID] = nil
        end
    end

    -- 更新有效单位数据
    for unitID in pairs(unitsToCheck) do
        -- unitID 为 GUID：Nampower v3.0+ 扩展 token 解析器使原生 UnitExists/UnitAffectingCombat
        -- 接受 GUID 参数（替代 SuperWoW 的 GUID 通用单位参数） by 武藤纯子酱 2026.9.1
        if (CleveRoids.hasNampowerGuidAPI or UnitExists(unitID)) and not UnitIsDeadOrGhost(unitID) then
            local currentHealth = CleveRoids.NampowerAPI.GetUnitHealth(unitID)
            local currentTime = GetTime()

            if not DeathTimers[unitID] then
                DeathTimers[unitID] = {
                    history = {},
                    historyCount = 0,
                    lastHealth = currentHealth,
                    lastTime = currentTime
                }
            end

            local data = DeathTimers[unitID]
            local damage = (data.lastHealth or 0) - currentHealth

            -- 条目表复用：从备用槽取表写入本 tick 采样（零分配）；窗口滑出时最老条目表回收为备用槽
            local entry = data.spare
            if not entry then entry = {}; data.spare = entry end
            data.historyCount = (data.historyCount or 0) + 1
            data.history[data.historyCount] = entry
            entry.damage = damage
            entry.time = currentTime

            if data.historyCount > 20 then
                data.spare = data.history[1] -- 回收滑出窗口的最老条目表
                for i = 1, 20 do
                    data.history[i] = data.history[i+1]
                end
                data.historyCount = 20
            end

            data.lastHealth = currentHealth
            data.lastTime = currentTime
        end
    end

    -- 复用表清空（零分配，供下一 tick 使用）
    for guidClear in pairs(unitsToCheck) do
        unitsToCheck[guidClear] = nil
    end
end)

-- 接口函数
-- 示例调用方式:
-- /script print(CleveRoids.GetTargetDeathTime("target"))
function CleveRoids.GetTargetDeathTime(unit)
    if not unit then unit = "target" end

    if CleveRoids.hasNampowerGuidAPI then
        local targetGUID = CleveRoids.GetGUID(unit)
        if not targetGUID or not UnitExists(unit) then return 1000 end
        if UnitIsDeadOrGhost(unit) then return 0 end
        local data = DeathTimers[targetGUID]
        if data then
            return math.floor(CleveRoids.CalculateTimeRemaining(targetGUID) + 0.5)
        end
    else
        if not UnitExists(unit) then return 1000 end
        if UnitIsDeadOrGhost(unit) then return 0 end
        for unitID in pairs(DeathTimers) do
            if UnitIsUnit(unit, unitID) then
                return math.floor(CleveRoids.CalculateTimeRemaining(unitID) + 0.5)
            end
        end
    end
    return 1000
end

CleveRoids.PlayerSummons = {}

-- 增强事件响应
CleveRoids.TimerFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
CleveRoids.TimerFrame:RegisterEvent("PLAYER_REGEN_ENABLED") -- 玩家退出战斗（脱战）
CleveRoids.TimerFrame:RegisterEvent("UNIT_MODEL_CHANGED_GUID") -- 新增myunit检测 by 武藤纯子酱 2026.4.27
CleveRoids.TimerFrame:SetScript("OnEvent", function()
    if event == "PLAYER_TARGET_CHANGED" then
        -- 修复：切换目标不再清空 DeathTimers 整表（原 DeathTimers = {} 会连带清掉其他
        -- 在战斗目标的计时历史，导致 ttk/死亡预估频繁重置）。仅强制立即采样一次。
        -- 清理交由 OnUpdate（脱战/死亡）与 PLAYER_REGEN_ENABLED（玩家脱战整表清空）by 武藤纯子酱 2026.9.9
        elapsedTime = interval
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 玩家退出战斗：清空整个死亡计时表 by 武藤纯子酱 2026.9.9
        DeathTimers = {}
    elseif event == "UNIT_MODEL_CHANGED_GUID" then -- 新增myunit检测 by 武藤纯子酱 2026.4.27
        local guid = arg1
        -- 修复：GetUnitGUID 为 Nampower v3.0+ 专属，缺失环境下直调抛错 by 武藤纯子酱 2026.9.9
        if guid and GetUnitGUID then
            local ownerGuid = GetUnitGUID(guid .. "owner")
            if ownerGuid and ownerGuid == GetUnitGUID("player") then
                if not CleveRoids.PlayerSummons[guid] then
                    CleveRoids.PlayerSummons[guid] = ""
                end
            end
        end
    end
end)

-- 通过attackbar插件获取平砍/平射计时 by 武藤纯子酱 2025.11.27
function CleveRoids.GetAttackState()
    local now = GetTime()
    local mhStarted, mhRemaining, ohStarted, ohRemaining = 0, 0, 0, 0
    local isMelee = CleveRoids.CurrentSpell.autoAttack
    local isRanged = CleveRoids.CurrentSpell.autoShot or CleveRoids.CurrentSpell.wand
    
    -- 获取主手攻击信息
    if Abar_Mhr and Abar_Mhr:IsVisible() then
        mhStarted = now - Abar_Mhr.st
        mhRemaining = Abar_Mhr.et - now
    end
    
    -- 获取副手攻击信息
    if Abar_Oh and Abar_Oh:IsVisible() then
        ohStarted = now - Abar_Oh.st
        ohRemaining = Abar_Oh.et - now
    end

    -- 确保值不为负
    mhStarted = math.max(0, mhStarted)
    mhRemaining = math.max(0, mhRemaining)
    ohStarted = math.max(0, ohStarted)
    ohRemaining = math.max(0, ohRemaining)
    
    return {
        mhStarted = mhStarted,
        mhRemaining = mhRemaining,
        ohStarted = ohStarted,
        ohRemaining = ohRemaining,
        isMelee = isMelee,
        isRanged = isRanged,
    }
end

function CleveRoids.IsGuidValid(condTarget, conds)
    if not condTarget or not UnitExists(condTarget) or UnitIsDeadOrGhost(condTarget) then
        return false
    end
    local orig = conds.target
    conds.target = condTarget
    local ok = true
    for k, _ in pairs(conds) do
        if not CleveRoids.ignoreKeywords[k] then
            local fn = CleveRoids.Keywords[k]
            if not fn or not fn(conds) then ok = false; break end
        end
    end
    conds.target = orig
    return ok
end

-- ============================================================================
-- 特殊单位标识（@cursor/@cursive/@mostwounded/@filter/@inherit 等）统一处理 by 武藤纯子酱 2026.8.31
-- ============================================================================
-- 所有"不是固定 UnitId、需要动态解析"的目标标识统一登记在这里：
--   - 判定是否为特殊标识：CleveRoids.IsSpecialUnitTarget(unit)
--   - 解析为具体单位：   CleveRoids.ResolveSpecialUnit(unit, ctx)
-- 各处不再各自硬编码长串字符串比较
CleveRoids.SPECIAL_UNIT_TARGETS = {
    cursor           = true, -- 鼠标指向（施法/选目标场景各自有特殊处理）
    none             = true, -- 正式服语法：中断自动自我施放、强制出现瞄准光标（施法场景特殊处理）by 武藤纯子酱 2026.9.3
    cursive          = true, -- Cursive 跟踪列表中第一个满足条件的单位
    mostwoundedparty = true, -- 小队（含自身/宠物）掉血最多者
    mostwoundedraid  = true, -- 团队（含宠物）掉血最多者
    mostwounded      = true, -- 团队优先、无团队则小队，掉血最多者
    filterparty      = true, -- 小队（含自身/宠物）第一个满足条件者
    filterraid       = true, -- 团队（含宠物）第一个满足条件者
    filter           = true, -- 团队优先、无团队则小队，第一个满足条件者
    inherit          = true, -- 继承上一次宏目标 CleveRoids.MacroTarget
    fov              = true, -- 瞄准射击：视野锥内直线穿透最多敌人（UnitXP farthestInFOV，需 X 版；无结果回退当前目标）by 武藤纯子酱 2026.9.12
    farthestinfov    = true, -- fov 的别名 by 武藤纯子酱 2026.9.12
    tar              = true, -- @target 的简写（当前目标）by 武藤纯子酱 2026.9.16
    tartar           = true, -- @targettarget 的简写（目标的目标）by 武藤纯子酱 2026.9.16
    cur              = true, -- @cursor 的简写（鼠标位置）by 武藤纯子酱 2026.9.16
    fo               = true, -- @focus 的简写（焦点）by 武藤纯子酱 2026.9.16
    mouse            = true, -- @mouseover 的简写（鼠标指向）by 武藤纯子酱 2026.9.16
}

-- 判断是否为特殊单位标识（不对应固定 UnitId，需要动态解析） by 武藤纯子酱 2026.8.31
function CleveRoids.IsSpecialUnitTarget(unit)
    if type(unit) ~= "string" then return false end
    -- 性能优化：结果缓存（避免每次 string.lower 分配）；上限 512 防止 GUID 无限增长 by 武藤纯子酱 2026.9.11
    local cache = CleveRoids._specialUnitCache
    if not cache then cache = {}; CleveRoids._specialUnitCache = cache; CleveRoids._specialUnitCacheN = 0 end
    local c = cache[unit]
    if c ~= nil then return c end
    local r = (CleveRoids.SPECIAL_UNIT_TARGETS[string.lower(unit)] == true)
    if CleveRoids._specialUnitCacheN >= 512 then
        cache = {}; CleveRoids._specialUnitCache = cache; CleveRoids._specialUnitCacheN = 0
    end
    cache[unit] = r
    CleveRoids._specialUnitCacheN = CleveRoids._specialUnitCacheN + 1
    return r
end

-- 解析特殊单位标识为具体 UnitId/GUID by 武藤纯子酱 2026.8.31
-- ctx: 条件表（用于 IsGuidValid 校验，可为 nil）
-- 返回值：
--   字符串  解析成功（cursor 原样返回，由调用方按施法/选目标语义处理）
--   nil     解析失败（无可选目标等软失败）
--   false   硬失败（如 Cursive 未加载），调用方应中止当前动作
function CleveRoids.ResolveSpecialUnit(unit, ctx)
    if type(unit) ~= "string" then return nil end
    unit = string.lower(unit)

    if unit == "cursor" then
        return "cursor"
    elseif unit == "none" then
        -- @none：原样返回，由调用方（DoWithConditionals）按"禁自动自我施放+瞄准光标"处理
        -- by 武藤纯子酱 2026.9.3
        return "none"
    elseif unit == "focus" then
        return CleveRoids.GetFocusUnitId()
    elseif unit == "focustarget" then
        local focusUnitId = CleveRoids.GetFocusUnitId()
        return focusUnitId and (focusUnitId .. "target") or nil
    elseif unit == "tar" then
        return "target"
    elseif unit == "tartar" then
        return "targettarget"
    elseif unit == "cur" then
        return "cursor"
    elseif unit == "fo" then
        return CleveRoids.GetFocusUnitId()
    elseif unit == "mouse" then
        return "mouseover"
    elseif unit == "cursive" then
        if not CleveRoids.RequireCursive("cursive") then
            return false
        end
        -- 遍历所有跟踪的单位
        for guid, _ in pairs(Cursive.core.guids) do
            if CleveRoids.IsGuidValid(guid, ctx) then
                return guid
            end
        end
        return nil
    elseif unit == "inherit" then
        return CleveRoids.MacroTarget
    elseif unit == "fov" or unit == "farthestinfov" then
        -- 瞄准射击智能选目标：需 UnitXP_SP3_X 版（含 farthestInFOV）；未装/版本不符/无结果 → 回退当前目标 by 武藤纯子酱 2026.9.12
        if CleveRoids.hasUnitXPFOV then
            local cfg = CleveRoidMacros
            local cone = (cfg and tonumber(cfg.fovCone)) or 2
            local range = (cfg and tonumber(cfg.fovRange)) or 41
            local ok, guid = pcall(UnitXP, "farthestInFOV", cone, range)
            if ok and guid then return guid end
        end
        return "target"
    elseif string.find(unit, "^mostwounded") or string.find(unit, "^filter") then
        local findMostWounded = (string.find(unit, "^mostwounded") ~= nil)
        local units = {}

        if string.find(unit, "party$") then
            -- 仅小队范围
            if GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do
                    -- 与原实现一致：mostwounded 先查宠物再查队员，filter 先查队员再查宠物 by 武藤纯子酱 2026.8.31
                    if findMostWounded then
                        table.insert(units, "partypet"..i)
                        table.insert(units, "party"..i)
                    else
                        table.insert(units, "party"..i)
                        table.insert(units, "partypet"..i)
                    end
                end
            end
        elseif string.find(unit, "raid$") then
            -- 仅团队范围
            if UnitInRaid("player") then
                for i = 1, GetNumRaidMembers() do
                    if findMostWounded then
                        table.insert(units, "raidpet"..i)
                        table.insert(units, "raid"..i)
                    else
                        table.insert(units, "raid"..i)
                        table.insert(units, "raidpet"..i)
                    end
                end
            end
        else
            -- 团队优先，无团队则小队
            if UnitInRaid("player") then
                for i = 1, GetNumRaidMembers() do
                    if findMostWounded then
                        table.insert(units, "raidpet"..i)
                        table.insert(units, "raid"..i)
                    else
                        table.insert(units, "raid"..i)
                        table.insert(units, "raidpet"..i)
                    end
                end
            elseif GetNumPartyMembers() > 0 then
                for i = 1, GetNumPartyMembers() do
                    if findMostWounded then
                        table.insert(units, "partypet"..i)
                        table.insert(units, "party"..i)
                    else
                        table.insert(units, "party"..i)
                        table.insert(units, "partypet"..i)
                    end
                end
            end
        end

        -- 始终把自己和宠物放在最后作为兜底（与原各分支实现一致） by 武藤纯子酱 2026.8.31
        table.insert(units, "player")
        table.insert(units, "pet")

        local best, bestHPLost = nil, 0
        for _, u in ipairs(units) do
            if UnitExists(u) then
                if findMostWounded then
                    local hpLost = UnitHealthMax(u) - CleveRoids.NampowerAPI.GetUnitHealth(u)
                    if hpLost > bestHPLost and CleveRoids.IsGuidValid(u, ctx) then
                        best, bestHPLost = u, hpLost
                    end
                elseif CleveRoids.IsGuidValid(u, ctx) then
                    return u
                end
            end
        end
        return best
    end

    return unit
end

function CleveRoids.ParseCasttimeArg(arg)
    local mode = "end"
    local spellIdentifier = nil
    local rawName = nil

    if type(arg) == "table" then
        rawName = arg.name
    elseif type(arg) == "string" then
        rawName = arg
    end

    if type(rawName) == "string" then
        local pipePos = string.find(rawName, "|", 1, true)
        if pipePos then
            local prefix = string.sub(rawName, 1, pipePos - 1)
            local suffix = string.sub(rawName, pipePos + 1)
            local lowerPrefix = string.lower(prefix)
            if lowerPrefix == "start" or lowerPrefix == "end" then
                mode = lowerPrefix
                spellIdentifier = suffix
                -- 如果后缀以 | 开头，去掉第一个（可能是重复的）
                if string.sub(spellIdentifier, 1, 1) == "|" then
                    spellIdentifier = string.sub(spellIdentifier, 2)
                end
            else
                -- 没有合法前缀，整个字符串视为技能标识符
                spellIdentifier = rawName
            end
        else
            local lowerRaw = string.lower(rawName)
            if lowerRaw == "start" or lowerRaw == "end" then
                mode = lowerRaw
            else
                spellIdentifier = rawName
            end
        end
    end
    return mode, spellIdentifier
end

CleveRoids.SpellSchoolName = {
    [0] = "physical",  -- SPELL_SCHOOL_NORMAL (Physical/Armor)
    [1] = "holy",      -- SPELL_SCHOOL_HOLY
    [2] = "fire",      -- SPELL_SCHOOL_FIRE
    [3] = "nature",    -- SPELL_SCHOOL_NATURE
    [4] = "frost",     -- SPELL_SCHOOL_FROST
    [5] = "shadow",    -- SPELL_SCHOOL_SHADOW
    [6] = "arcane"     -- SPELL_SCHOOL_ARCANE
}

CleveRoids.DebuffType = {
    [1] = "magic",
    [2] = "curse",
    [3] = "disease",
    [4] = "poison",
}

-- 保存当前天赋到指定编号 by 武藤纯子酱 2026.5.13
function CleveRoids.SaveCurrentTalentSet(slot, setName)
    if not slot or slot < 1 or slot > 8 then return end
    -- 确保天赋索引是最新的
    CleveRoids.IndexTalents()
    local talents = {}
    -- 遍历所有天赋，只记录已学习的
    for tab = 1, GetNumTalentTabs() do
        for i = 1, GetNumTalents(tab) do
            local name, _, _, _, rank = GetTalentInfo(tab, i)
            if name and rank and rank > 0 then
                talents[name] = rank
            end
        end
    end
    -- 存储
    CleveRoids_TalentSets = CleveRoids_TalentSets or {}
    local finalSetName = setName or ("天赋套装" .. slot)
    CleveRoids_TalentSets[slot] = {
        name = finalSetName,
        talents = talents,
        timestamp = GetTime(),
    }
    CleveRoids.Print(string.format("已保存当前天赋为套装 %d: %s", slot, finalSetName))
end

-- 删除指定编号的天赋套装 by 武藤纯子酱 2026.5.13
function CleveRoids.DeleteTalentSet(slot)
    if not slot or slot < 1 or slot > 8 then return end
    CleveRoids_TalentSets = CleveRoids_TalentSets or {}
    if CleveRoids_TalentSets[slot] then
        local name = CleveRoids_TalentSets[slot].name
        CleveRoids_TalentSets[slot] = nil
        CleveRoids.Print(string.format("已删除套装 %d: %s", slot, name))
    else
        CleveRoids.Print(string.format("套装 %d 不存在", slot))
    end
end

-- 列出所有已保存的天赋套装 by 武藤纯子酱 2026.5.13
function CleveRoids.ListTalentSets()
    CleveRoids_TalentSets = CleveRoids_TalentSets or {}
    local hasAny = false
    CleveRoids.Print("|cff88ff88=== 已保存的天赋套装 ===|r")
    for slot = 1, 8 do
        local set = CleveRoids_TalentSets[slot]
        if set then
            local talentCount = 0
            for _, v in pairs(set.talents) do
                if v > 0 then talentCount = talentCount + 1 end
            end
            CleveRoids.Print(string.format("  [%d] %s (已学%d个天赋)", slot, set.name, talentCount))
            hasAny = true
        end
    end
    if not hasAny then
        CleveRoids.Print("  暂无保存的天赋套装。")
        CleveRoids.Print("  使用 /cleveroid talentsave <编号> [名称] 保存当前天赋。")
    end
end

-- 比较当前天赋表与保存的天赋表是否完全一致 by 武藤纯子酱 2026.5.13
-- @param current table 当前天赋表（可能包含未点天赋，值为 0）
-- @param saved table 保存的天赋表（仅包含已点天赋，值 > 0）
-- @return boolean
function CleveRoids.TalentTablesEqual(current, saved)
    -- 辅助函数：确保值是数字
    local function getRank(val)
        if type(val) == "number" then
            return val
        elseif type(val) == "boolean" then
            return 0
        else
            return 0
        end
    end

    -- 检查 saved 中的每个天赋
    for name, savedRank in pairs(saved) do
        local currentRank = getRank(current[name])
        if currentRank ~= savedRank then
            return false
        end
    end

    -- 检查 current 中是否有 saved 中不存在的已点天赋（rank > 0）
    for name, currentVal in pairs(current) do
        local currentRank = getRank(currentVal)
        if currentRank > 0 then
            local savedRank = saved[name]
            if not savedRank or savedRank ~= currentRank then
                return false
            end
        end
    end

    return true
end

-- 检查当前天赋是否与指定套装匹配 by 武藤纯子酱 2026.5.13
-- @param identifier 套装编号 (1-8) 或套装名称 (字符串)
-- @return boolean
function CleveRoids.IsCurrentTalentSetMatch(identifier)
    -- 确保天赋索引最新
    CleveRoids.IndexTalents()
    local currentTalents = CleveRoids.Talents

    -- 获取保存的套装
    local savedSet = nil

    -- 尝试作为编号处理
    local num = tonumber(identifier)
    if num and num >= 1 and num <= 8 then
        savedSet = CleveRoids_TalentSets[num]
    else
        -- 作为名称处理
        for slot, set in pairs(CleveRoids_TalentSets) do
            if set.name == identifier then
                savedSet = set
                break
            end
        end
    end

    if not savedSet then
        return false  -- 套装不存在
    end

    -- 比较两个天赋表
    return CleveRoids.TalentTablesEqual(currentTalents, savedSet.talents)
end

-- 装备栏位名称 → ID 映射（1-19 对应 WoW 标准槽位） by 武藤纯子酱 2026.7.1
CleveRoids.SlotNameToId = {
    head = 1, neck = 2, shoulder = 3, shirt = 4, chest = 5,
    waist = 6, legs = 7, feet = 8, wrist = 9, hands = 10,
    finger1 = 11, finger2 = 12, trinket1 = 13, trinket2 = 14,
    back = 15, mainhand = 16, offhand = 17, ranged = 18, tabard = 19,
}

-- 将槽位标识（名称或数字）转换为标准 ID（1-19） by 武藤纯子酱 2026.7.1
function CleveRoids.GetSlotIdFromName(name)
    -- 修复：导出 API 对 name 加类型守卫（防未来调用方传 nil/非字符串）by 武藤纯子酱 2026.9.9
    if type(name) ~= "string" and type(name) ~= "number" then return nil end
    local slotId = tonumber(name)
    if slotId and slotId >= 1 and slotId <= 19 then return slotId end
    if type(name) ~= "string" then return nil end
    local lower = string.lower(name)
    return CleveRoids.SlotNameToId[lower]
end

-- 获取指定槽位的耐久度百分比（0-100），若物品无耐久或未装备则返回 nil by 武藤纯子酱 2026.7.1
function CleveRoids.GetSlotDurabilityPercent(slotId)
    if not slotId or slotId < 1 or slotId > 19 then return nil end
    local item = CleveRoids.NampowerAPI.GetEquippedItem("player", slotId)
    if not item then return nil end
    local current = item.durability
    local max = item.maxDurability
    if not current or not max or max == 0 then return nil end
    return (current / max) * 100
end

-- 计算远程技能弹道飞行时间（秒） by 武藤纯子酱 2026.7.3
-- @param spellId number 技能ID
-- @param targetUnit string|nil 目标单位标识（如 "target" 或 GUID）
-- @return number 预估飞行时间（秒），最小 0.2，最大 1.5
function CleveRoids.GetProjectileFlightTime(spellId, targetUnit)
    -- 默认保底值
    local baseDelay = 0.2

    -- 读取用户配置的速度，默认 25，限制 10-40
    local speed = CleveRoidMacros and CleveRoidMacros.projectileSpeed or 25
    if speed < 10 then speed = 10 end
    if speed > 40 then speed = 40 end

    -- 1. 获取目标距离
    local distance = nil
    if targetUnit and UnitExists(targetUnit) then
        if CleveRoids.hasUnitXP then
            distance = CleveRoids.SafeUnitXP("distanceBetween", "player", targetUnit)
        end
    end

    if not distance or distance <= 3 then
        return baseDelay
    end

    -- 2. 获取技能最大射程
    local maxRange = 30
    local rangeIndex = GetSpellRecField(spellId, "rangeIndex")
    -- 修复：GetSpellRangeData 是 Nampower v4.0+ 才有的全局，旧版本需守卫 by 武藤纯子酱 2026.8.31
    if rangeIndex and GetSpellRangeData then
        local _, maxRangeFromDBC = GetSpellRangeData(rangeIndex)
        if maxRangeFromDBC and maxRangeFromDBC > 0 then
            maxRange = maxRangeFromDBC
        end
    end

    if distance > maxRange then
        distance = maxRange
    end

    -- 3. 计算飞行时间：距离 / 速度 + 0.2 秒服务器缓冲
    local flightTime = (distance / speed) + 0.2

    return math.max(0.2, math.min(1.5, flightTime))
end

CleveRoids.MacroTarget = nil
CleveRoids.TrueTarget = nil
CleveRoids.SetScan = nil
CleveRoids._mostWoundedGroupCache = nil
CleveRoids_TalentSets = CleveRoids_TalentSets or {} -- 新增天赋套数统计 by 武藤纯子酱 2026.5.13
CleveRoids.lastSpellID = nil   -- 记录上一次成功施法的 spellID by 武藤纯子酱 2026.5.15

-- 消息队列与发送控制 by 武藤纯子酱 2026.8.10
CleveRoids.messageQueue = {}                -- { guid, text, timestamp }
CleveRoids.lastSendMessageTime = 0
CleveRoids.SENDMESSAGE_CD = 1.0             -- 1秒CD
CleveRoids.MESSAGE_PREFIX = "SCRM"          -- 插件前缀
_G["CleveRoids"] = CleveRoids
