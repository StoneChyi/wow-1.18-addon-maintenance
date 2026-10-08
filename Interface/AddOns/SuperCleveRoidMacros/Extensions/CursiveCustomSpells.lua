--[[
    CursiveCustomSpells Extension

    Automatically injects custom spell definitions into Cursive's tracking system.
    Any spell in this list will be tracked by Cursive when you cast it normally.

    Format:
        [spellID] = { name = "lowercase spell name", rank = X, duration = Y },

    Optional fields:
        variableDuration = true     -- Duration can be modified by talents/haste
        calculateDuration = func    -- Function returning dynamic duration
        numTicks = N                -- Number of DoT ticks (for tick tracking)
        darkHarvest = true          -- Affected by Dark Harvest talent
]]

local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids
-- 修复：原 `or {}` 无实际作用——紧接的 table 字面量即解引用 CleveRoids.Localized.Spells，
-- 缺任一环节仍会崩；改为真正的守卫（正常加载时二者必存在）by 武藤纯子酱 2026.9.11
if not (CleveRoids and CleveRoids.Localized and CleveRoids.Localized.Spells) then return end

--============================================================================
-- CUSTOM SPELL DEFINITIONS
-- Add your custom debuffs here. They will be auto-tracked when cast.
--============================================================================

CleveRoids.CustomCursiveSpells = CleveRoids.CustomCursiveSpells or {
    --========================================================================
    -- WARRIOR DEBUFFS (from database.turtlecraft.gg)
    --========================================================================

    -- Deep Wounds (talent proc, bleed over 12 sec - ticks every 3s)
    [12721] = { name = strlower(CleveRoids.Localized.Spells["Deep Wounds"]), rank = 1, duration = 6 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [12162] = { name = strlower(CleveRoids.Localized.Spells["Deep Wounds"]), rank = 1, duration = 6 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [12850] = { name = strlower(CleveRoids.Localized.Spells["Deep Wounds"]), rank = 2, duration = 6 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [12868] = { name = strlower(CleveRoids.Localized.Spells["Deep Wounds"]), rank = 3, duration = 6 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Hamstring (15 sec snare, 50% movement speed)
    [1715] = { name = strlower(CleveRoids.Localized.Spells["Hamstring"]), rank = 1, duration = 15, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11
    [7372] = { name = strlower(CleveRoids.Localized.Spells["Hamstring"]), rank = 2, duration = 15, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11
    [7373] = { name = strlower(CleveRoids.Localized.Spells["Hamstring"]), rank = 3, duration = 15, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11

    --========================================================================
    -- TAUNTS (personal debuffs)
    --========================================================================

    -- Taunt (Warrior, 3 sec)
    [355] = { name = strlower(CleveRoids.Localized.Spells["Taunt"]), rank = 1, duration = 3, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11
    [29060] = { name = strlower(CleveRoids.Localized.Spells["Taunt"]), rank = 1, duration = 3, variableDuration = true },  -- variant -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11

    -- Growl (Druid Bear, 3 sec)
    [6795] = { name = strlower(CleveRoids.Localized.Spells["Growl"]), rank = 1, duration = 3 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Mocking Blow (Warrior, 6 sec)
    [694] = { name = strlower(CleveRoids.Localized.Spells["Mocking Blow"]), rank = 1, duration = 6, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11
    [7400] = { name = strlower(CleveRoids.Localized.Spells["Mocking Blow"]), rank = 2, duration = 6, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11
    [7402] = { name = strlower(CleveRoids.Localized.Spells["Mocking Blow"]), rank = 3, duration = 6, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11
    [20559] = { name = strlower(CleveRoids.Localized.Spells["Mocking Blow"]), rank = 4, duration = 6, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11
    [20560] = { name = strlower(CleveRoids.Localized.Spells["Mocking Blow"]), rank = 5, duration = 6, variableDuration = true }, -- 对齐Cursive技能表 by 武藤纯子酱 2026.9.11

    -- Hand of Reckoning (Paladin, 3 sec)
    [62124] = { name = strlower(CleveRoids.Localized.Spells["Hand of Reckoning"]), rank = 1, duration = 3 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    --========================================================================
    -- PALADIN JUDGEMENT DEBUFFS
    -- Generic 20271 is handled specially below to detect seal type
    --========================================================================

    -- Judgement of the Crusader (10 sec, +holy damage taken)
    [21183] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 1, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20188] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 2, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20300] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 3, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20301] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 4, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20302] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 5, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20303] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 6, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20304] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 6, duration = 10 },  -- variant -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [25942] = { name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), rank = 1, duration = 10 },  -- variant -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Judgement of Light (10 sec, heals attackers)
    [20185] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Light"]), rank = 1, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20344] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Light"]), rank = 2, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20345] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Light"]), rank = 3, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20346] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Light"]), rank = 4, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Judgement of Wisdom (10 sec, restores mana to attackers)
    [20186] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), rank = 1, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20354] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), rank = 2, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [20355] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), rank = 3, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [51750] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), rank = 5, duration = 10 },  -- Rank 5 cast (confirmed) -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [51751] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), rank = 4, duration = 10 },  -- Rank 4 cast -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [51752] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), rank = 5, duration = 10 },  -- debuff effect ID -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [25757] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), rank = 1, duration = 10 },  -- variant -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Judgement of Justice (10 sec, prevents fleeing)
    [20184] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Justice"]), rank = 1, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [25945] = { name = strlower(CleveRoids.Localized.Spells["Judgement of Justice"]), rank = 2, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    --========================================================================
    -- ROGUE POISONS
    --========================================================================
--[[
    -- Deadly Poison (12 sec, stacking nature DoT)
    [2818] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 1, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [2819] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 2, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [11353] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 3, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [11354] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 4, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [25349] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 5, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [3583] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 1, duration = 12 },   -- proc effect -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [10022] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 2, duration = 12 },  -- proc effect -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [13582] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 3, duration = 12 },  -- proc effect -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [21787] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 4, duration = 12 },  -- proc effect -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [21788] = { name = strlower(CleveRoids.Localized.Spells["Deadly Poison"]), rank = 5, duration = 12 },  -- proc effect -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Crippling Poison (12 sec, -50% movement speed)
    [3409] = { name = strlower(CleveRoids.Localized.Spells["Crippling Poison"]), rank = 1, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [11201] = { name = strlower(CleveRoids.Localized.Spells["Crippling Poison"]), rank = 2, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [25809] = { name = strlower(CleveRoids.Localized.Spells["Crippling Poison"]), rank = 2, duration = 12 },  -- variant -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Wound Poison (15 sec, -healing received)
    [13218] = { name = strlower(CleveRoids.Localized.Spells["Wound Poison"]), rank = 1, duration = 15 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [13222] = { name = strlower(CleveRoids.Localized.Spells["Wound Poison"]), rank = 2, duration = 15 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [13223] = { name = strlower(CleveRoids.Localized.Spells["Wound Poison"]), rank = 3, duration = 15 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [13224] = { name = strlower(CleveRoids.Localized.Spells["Wound Poison"]), rank = 4, duration = 15 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [25648] = { name = strlower(CleveRoids.Localized.Spells["Wound Poison"]), rank = 5, duration = 15 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    -- Mind-numbing Poison (10 sec, -casting speed)
    [5760] = { name = strlower(CleveRoids.Localized.Spells["Mind-numbing Poison"]), rank = 1, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [8692] = { name = strlower(CleveRoids.Localized.Spells["Mind-numbing Poison"]), rank = 2, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [11398] = { name = strlower(CleveRoids.Localized.Spells["Mind-numbing Poison"]), rank = 3, duration = 10 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [25810] = { name = strlower(CleveRoids.Localized.Spells["Mind-numbing Poison"]), rank = 2, duration = 10 },  -- variant -- 修复多语言支持 by 武藤纯子酱 2026.1.4
]]
    --========================================================================
    -- THUNDERFURY PROC DEBUFFS
    --========================================================================

    -- Thunderfury - Nature Resist Reduction (12 sec, chains to 5 targets)
    [21992] = { name = strlower(CleveRoids.Localized.Spells["Thunderfury"]), rank = 1, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    -- Thunderfury - Attack Speed Slow (12 sec, -20% attack speed on primary target)
    [27648] = { name = strlower(CleveRoids.Localized.Spells["Thunderfury Slow"]), rank = 1, duration = 12 }, -- 修复多语言支持 by 武藤纯子酱 2026.1.4

    --========================================================================
    -- CUSTOM/SERVER-SPECIFIC (add your own below)
    --========================================================================
    -- [12345] = { name = "custom debuff", rank = 1, duration = 18 },
}

--============================================================================
-- PALADIN JUDGEMENT SEAL DETECTION
-- Maps seal buff textures to judgement debuff names and their reference spellIDs
--============================================================================

local sealToJudgement = {
    -- Seal texture -> { name, referenceSpellID (must be in trackedCurseIds), judgementTexture }
    ["Interface\\Icons\\Spell_Holy_RighteousnessAura"] = {
        name = strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"]), -- 修复多语言支持 by 武藤纯子酱 2026.1.4
        spellID = 20186,  -- JoW rank 1 (in our custom list)
        texture = "Interface\\Icons\\Spell_Holy_RighteousnessAura", -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    },
    ["Interface\\Icons\\Spell_Holy_HealingAura"] = {
        name = strlower(CleveRoids.Localized.Spells["Judgement of Light"]), -- 修复多语言支持 by 武藤纯子酱 2026.1.4
        spellID = 20185,  -- JoL rank 1 (in our custom list)
        texture = "Interface\\Icons\\Spell_Holy_HealingAura",
    },
    ["Interface\\Icons\\Spell_Holy_HolySmite"] = {
        name = strlower(CleveRoids.Localized.Spells["Judgement of the Crusader"]), -- 修复多语言支持 by 武藤纯子酱 2026.1.4
        spellID = 21183,  -- JotC rank 1 (in our custom list)
        texture = "Interface\\Icons\\Spell_Holy_HolySmite",
    },
    ["Interface\\Icons\\Spell_Holy_SealOfWrath"] = {
        name = strlower(CleveRoids.Localized.Spells["Judgement of Justice"]), -- 修复多语言支持 by 武藤纯子酱 2026.1.4
        spellID = 20184,  -- JoJ rank 1 (in our custom list)
        texture = "Interface\\Icons\\Spell_Holy_SealOfWrath",
    },
    ["Interface\\Icons\\Ability_ThunderClap"] = {
        name = strlower(CleveRoids.Localized.Spells["Judgement of Righteousness"]), -- 修复多语言支持 by 武藤纯子酱 2026.1.4
        spellID = 20187,  -- fallback, may need correct ID
        texture = "Interface\\Icons\\Ability_ThunderClap",
    },
    ["Interface\\Icons\\Spell_Holy_SealOfMight"] = {
        name = strlower(CleveRoids.Localized.Spells["Judgement of Command"]), -- 修复多语言支持 by 武藤纯子酱 2026.1.4
        spellID = 20467,  -- fallback, may need correct ID
        texture = "Interface\\Icons\\Spell_Holy_SealOfMight",
    },
}

-- Detect active seal from player buffs and return judgement info
local function GetActiveSealJudgementInfo()
    -- 修复：GetPlayerBuff 的 id 空间是 0-31（-1 表示无），原循环 1..32 漏掉 0 号位且 32 无效 by 武藤纯子酱 2026.8.31
    for i = 0, 31 do
        local id = GetPlayerBuff(i, "HELPFUL")
        if id < 0 then break end
        local texture = GetPlayerBuffTexture(id)
        if not texture then break end
        if sealToJudgement[texture] then
            return sealToJudgement[texture]
        end
    end
    -- Fallback to generic judgement
    return { name = strlower(CleveRoids.Localized.Spells["Judgement"]), spellID = 20271, texture = "Interface\\Icons\\Spell_Holy_RighteousFury" } -- 修复多语言支持 by 武藤纯子酱 2026.1.4
end

--============================================================================
-- AUTOMATIC INJECTION INTO CURSIVE
-- Hooks Cursive's LoadCurses to inject our spells after every reload
--============================================================================

local function InjectCustomSpells()
    if not Cursive or not Cursive.curses or not Cursive.curses.trackedCurseIds then
        return 0
    end

    -- 修复：守卫链不完整——Cursive 版本可能缺少 trackedCurseNamesToTextures 子表，
    -- libdebuff 可能没有 GetCachedIcon 方法；且本函数被 hook 进 Cursive 的 LoadCurses
    -- （无 pcall），任何一处缺失都会中断 Cursive 的诅咒装载 by 武藤纯子酱 2026.9.9
    if type(Cursive.curses.trackedCurseNamesToTextures) ~= "table" then
        return 0
    end

    local count = 0
    for spellID, data in pairs(CleveRoids.CustomCursiveSpells) do
        -- 删除：name/rank 读取后从未使用（实际用 data.name/data.rank） by 武藤纯子酱 2026.9.11
        local texture
        if CleveRoids.libdebuff and type(CleveRoids.libdebuff.GetCachedIcon) == "function" then
            texture = CleveRoids.libdebuff:GetCachedIcon(spellID)
        end
        if texture then
            -- Always update/add (in case Cursive reloaded and cleared them)
            Cursive.curses.trackedCurseIds[spellID] = {
                name = data.name,
                rank = data.rank or 1,
                duration = data.duration,
                texture = texture,
                variableDuration = data.variableDuration,
                calculateDuration = data.calculateDuration,
                numTicks = data.numTicks,
                darkHarvest = data.darkHarvest,
            }
            Cursive.curses.trackedCurseNamesToTextures[data.name] = texture
            count = count + 1
        end
    end

    return count
end

-- Hook Cursive's LoadCurses function to inject after every reload
local function HookCursiveLoadCurses()
    if not Cursive or not Cursive.curses or not Cursive.curses.LoadCurses then
        return false
    end

    -- Check if already hooked
    if Cursive.curses._customSpellsHooked then
        return true
    end

    -- Store original function
    local originalLoadCurses = Cursive.curses.LoadCurses

    -- Replace with hooked version
    -- 修复：原包装只 (self) 且无 return，会丢弃原函数返回值与额外参数 by 武藤纯子酱 2026.9.11
    Cursive.curses.LoadCurses = function(...)
        -- Call original first（全量透传参数并保留其全部返回值）by 武藤纯子酱 2026.9.11
        local results = { originalLoadCurses(unpack(arg)) }

        -- Then inject our custom spells (silent)
        -- pcall 兜底：注入失败不中断 Cursive 的诅咒装载
        pcall(InjectCustomSpells)

        -- 修复：原只回传第一个返回值，导致多返回值信息丢失 by 武藤纯子酱 2026.9.11
        local maxIdx = 0
        for i = 1, 32 do
            if results[i] ~= nil then maxIdx = i end
        end
        if maxIdx >= 1 then
            return unpack(results, 1, maxIdx)
        end
        return nil
    end

    Cursive.curses._customSpellsHooked = true
    return true
end

--============================================================================
-- EXTENSION REGISTRATION
--============================================================================

local ext = CleveRoids.RegisterExtension("CursiveCustomSpells")
local hooked = false
local retryFrame = nil

-- Retry injection periodically until successful
local function StartRetryTimer()
    if retryFrame then return end

    retryFrame = CreateFrame("Frame")
    local elapsed = 0
    local attempts = 0

    retryFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 0.5 then  -- Check every 0.5 seconds
            elapsed = 0
            attempts = attempts + 1

            if HookCursiveLoadCurses() then
                hooked = true
                InjectCustomSpells()
                retryFrame:SetScript("OnUpdate", nil)
                retryFrame = nil
            elseif attempts >= 20 then  -- Give up after 10 seconds
                retryFrame:SetScript("OnUpdate", nil)
                retryFrame = nil
            end
        end
    end)
end

ext.OnLoad = function()
    -- Try to hook immediately (Cursive might already be loaded)
    if HookCursiveLoadCurses() then
        hooked = true
        InjectCustomSpells()
    else
        -- Start retry timer and also register events as backup
        StartRetryTimer()
        ext.RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
    end
end

ext.OnPlayerEnteringWorld = function()
    if not hooked then
        if HookCursiveLoadCurses() then
            hooked = true
            InjectCustomSpells()
        end
    end
    -- Don't unregister - keep checking on zone changes
end

--============================================================================
-- PALADIN JUDGEMENT HOOK
-- Intercepts generic Judgement (20271) and applies correct debuff name
--============================================================================

local JUDGEMENT_SPELL_ID = 20271
local judgementHooked = false

local function HookJudgementDetection()
    if judgementHooked then return end
    if not Cursive or not Cursive.curses then return end

    -- DO NOT register 20271 in trackedCurseIds - we handle it ourselves
    -- This prevents Cursive's native handler from creating a duplicate

    -- Register our own SPELL_GO_SELF handler（Nampower v2.25+，替代 SuperWoW UNIT_CASTEVENT）by 武藤纯子酱 2026.9.1
    -- SPELL_GO_SELF 载荷：itemId, spellId, casterGuid, targetGuid, castFlags, numTargetsHit, numTargetsMissed
    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("SPELL_GO_SELF")
    eventFrame:SetScript("OnEvent", function()
        local itemId, spellID, casterGuid, targetGuid = arg1, arg2, arg3, arg4

        -- Only handle our Judgement casts
        if spellID ~= JUDGEMENT_SPELL_ID then return end

        -- Check if it's the player casting
        local playerGuid = CleveRoids.GetGUID("player")
        if casterGuid ~= playerGuid then return end

        -- No explicit target (e.g. null GUID) → nothing to apply
        if not targetGuid or targetGuid == "" or targetGuid == "0x0000000000000000" then return end

        -- 修复：补子表守卫（Cursive 版本差异可能导致子表缺失，原直接索引会崩） by 武藤纯子酱 2026.9.11
        local curses = Cursive.curses
        if type(curses.trackedCurseIds) ~= "table"
            or type(curses.guids) ~= "table"
            or type(curses.trackedCurseNamesToTextures) ~= "table" then
            return
        end

        -- Detect which seal is active and get full judgement info
        local info = GetActiveSealJudgementInfo()

        -- Make sure the reference spellID is in trackedCurseIds
        if not Cursive.curses.trackedCurseIds[info.spellID] then
            Cursive.curses.trackedCurseIds[info.spellID] = {
                name = info.name,
                rank = 1,
                duration = 10,
                texture = info.texture,
            }
        end

        -- Apply the curse manually with the correct name
        if not Cursive.curses.guids[targetGuid] then
            Cursive.curses.guids[targetGuid] = {}
        end

        Cursive.curses.guids[targetGuid][info.name] = {
            rank = 1,
            duration = 10,
            start = GetTime(),
            spellID = info.spellID,  -- Use the seal-specific spellID
            targetGuid = targetGuid,
            currentPlayer = true,
        }

        -- Add texture mapping for display
        Cursive.curses.trackedCurseNamesToTextures[info.name] = info.texture
    end)

    judgementHooked = true
end

-- Hook judgement detection when Cursive is ready
local judgementRetryFrame = CreateFrame("Frame")
judgementRetryFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
judgementRetryFrame:SetScript("OnEvent", function()
    -- Delay slightly to ensure Cursive is fully loaded
    local elapsed = 0
    judgementRetryFrame:SetScript("OnUpdate", function()
        elapsed = elapsed + arg1
        if elapsed >= 1 then
            HookJudgementDetection()
            judgementRetryFrame:SetScript("OnUpdate", nil)
        end
    end)
end)

--============================================================================
-- JUDGEMENT REFRESH ON MELEE HIT
-- Judgement of Light/Wisdom refresh their duration when the Paladin hits
--============================================================================

local judgementNames = {
    [strlower(CleveRoids.Localized.Spells["Judgement of Wisdom"])] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    [strlower(CleveRoids.Localized.Spells["Judgement of Light"])] = true, -- 修复多语言支持 by 武藤纯子酱 2026.1.4
    -- 修复：只有 JoL/JoW 会在骑士近战命中时刷新时长；JotC/JoJ/JoR/JoC 是固定时长 debuff，
    -- 原先把它们也一并刷新，导致 Cursive 计时条比实际长很多 by 武藤纯子酱 2026.8.31
}

-- Refresh all active judgements on a target
local function RefreshJudgementsOnTarget(targetGuid)
    if not Cursive or not Cursive.curses or not Cursive.curses.guids then return end
    if not targetGuid or not Cursive.curses.guids[targetGuid] then return end

    local now = GetTime()
    for curseName, curseData in pairs(Cursive.curses.guids[targetGuid]) do
        if judgementNames[curseName] and curseData.currentPlayer then
            -- Refresh the timer
            curseData.start = now
        end
    end
end

-- Hook melee combat events for auto attacks
local meleeRefreshFrame = CreateFrame("Frame")
meleeRefreshFrame:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
meleeRefreshFrame:SetScript("OnEvent", function()
    -- 修复：原用英文 "^You hit/^You crit" 解析目标名，zhCN 下永不匹配导致平砍不刷新 JoL/JoW；
    -- 改为不依赖文案：收到“自身近战命中”即刷新当前目标 by 武藤纯子酱 2026.9.11
    if not arg1 then return end
    local targetGuid = CleveRoids.GetGUID("target")
    if targetGuid then
        RefreshJudgementsOnTarget(targetGuid)
    end
end)

-- Hook SPELL_GO_SELF for melee ability hits (Crusader Strike, etc.)（Nampower，替代 SuperWoW UNIT_CASTEVENT）by 武藤纯子酱 2026.9.1
local meleeAbilityFrame = CreateFrame("Frame")
meleeAbilityFrame:RegisterEvent("SPELL_GO_SELF")
meleeAbilityFrame:SetScript("OnEvent", function()
    local itemId, spellID, casterGuid, targetGuid = arg1, arg2, arg3, arg4

    -- Check if it's the player casting
    local playerGuid = CleveRoids.GetGUID("player")
    if casterGuid ~= playerGuid then return end

    -- Skip Judgement itself (20271) - it applies, doesn't refresh
    if spellID == JUDGEMENT_SPELL_ID then return end

    -- Only refresh for melee abilities (instant casts with target)
    -- We can't easily detect "melee only" so refresh on any successful cast on target
    if targetGuid and targetGuid ~= "" and targetGuid ~= "0x0000000000000000" then
        RefreshJudgementsOnTarget(targetGuid)
    end
end)

--============================================================================
-- CONSOLE COMMANDS: /cleveroid cursive
--============================================================================

local originalConsoleHandler = CleveRoids.HandleConsoleCommand

CleveRoids.HandleConsoleCommand = function(msg)
    local _, _, cmd, args = string.find(msg or "", "^(%S+)%s*(.*)$")
    cmd = cmd and string.lower(cmd) or ""

    if cmd == "cursive" then
        local _, _, subcmd, subargs = string.find(args or "", "^(%S+)%s*(.*)$")
        subcmd = subcmd and string.lower(subcmd) or "list"

        if subcmd == "list" then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CursiveCustomSpells]|r Custom spell list:")
            local count = 0
            for spellID, data in pairs(CleveRoids.CustomCursiveSpells) do
                local status = ""
                if Cursive and Cursive.curses and Cursive.curses.trackedCurseIds[spellID] then
                    status = " |cff00ff00[active]|r"
                else
                    status = " |cffff0000[not loaded]|r"
                end
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  [%d] %s (rank %d, %ds)%s",
                    spellID, data.name, data.rank or 1, data.duration, status))
                count = count + 1
            end
            if count == 0 then
                DEFAULT_CHAT_FRAME:AddMessage("  (none - edit CursiveCustomSpells.lua to add)")
            end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("  Hook status: %s",
                hooked and "|cff00ff00active|r" or "|cffff0000not hooked|r"))

        elseif subcmd == "add" then
            local _, _, spellID, duration, customName = string.find(subargs, "^(%d+)%s+(%d+)%s*(.*)$")
            spellID = tonumber(spellID)
            duration = tonumber(duration)

            if not spellID or not duration then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Usage:|r /cleveroid cursive add <spellID> <duration> [name]")
                return
            end

            local name = GetSpellRecField(spellID, "name")
            local texture = CleveRoids.libdebuff and type(CleveRoids.libdebuff.GetCachedIcon) == "function" and CleveRoids.libdebuff:GetCachedIcon(spellID) or nil
            if not name then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Error:|r Spell ID " .. spellID .. " not found.")
                return
            end

            local spellName = customName ~= "" and string.lower(customName) or string.lower(name)

            CleveRoids.CustomCursiveSpells[spellID] = {
                name = spellName,
                rank = 1,
                duration = duration,
            }

            -- Inject immediately
            -- 守卫链补全：两个目标子表逐一校验 by 武藤纯子酱 2026.9.9
            if Cursive and Cursive.curses
                and type(Cursive.curses.trackedCurseIds) == "table"
                and type(Cursive.curses.trackedCurseNamesToTextures) == "table" then
                Cursive.curses.trackedCurseIds[spellID] = {
                    name = spellName,
                    rank = 1,
                    duration = duration,
                    texture = texture,
                }
                Cursive.curses.trackedCurseNamesToTextures[spellName] = texture
            end

            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[CursiveCustomSpells]|r Added: [%d] %s (%ds) - will auto-track on cast",
                spellID, spellName, duration))
            DEFAULT_CHAT_FRAME:AddMessage("  Note: Edit CursiveCustomSpells.lua to make permanent.")

        elseif subcmd == "remove" then
            local spellID = tonumber(subargs)
            if not spellID then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Usage:|r /cleveroid cursive remove <spellID>")
                return
            end

            if CleveRoids.CustomCursiveSpells[spellID] then
                local name = CleveRoids.CustomCursiveSpells[spellID].name
                CleveRoids.CustomCursiveSpells[spellID] = nil

                if Cursive and Cursive.curses and Cursive.curses.trackedCurseIds and Cursive.curses.trackedCurseIds[spellID] then
                    Cursive.curses.trackedCurseIds[spellID] = nil
                end
                -- 修复：同步清除 名称→贴图 映射，避免残留 by 武藤纯子酱 2026.9.11
                if Cursive and Cursive.curses and Cursive.curses.trackedCurseNamesToTextures and name then
                    Cursive.curses.trackedCurseNamesToTextures[name] = nil
                end

                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[CursiveCustomSpells]|r Removed: [%d] %s",
                    spellID, name))
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cffff0000Error:|r Spell ID " .. spellID .. " not in custom list.")
            end

        elseif subcmd == "inject" then
            local count = InjectCustomSpells()
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cff00ff00[CursiveCustomSpells]|r Injected %d spell(s).", count))

        elseif subcmd == "debugseal" then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CursiveCustomSpells]|r Scanning player buffs for seals:")
            for i = 0, 31 do -- 修复：槽位 0..31（与 GetActiveSealJudgementInfo 一致，原 1..32 错位） by 武藤纯子酱 2026.9.11
                local texture = GetPlayerBuffTexture(i)
                if not texture then break end
                local match = sealToJudgement[texture] and "|cff00ff00 MATCH|r" or ""
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  [%d] %s%s", i, texture, match))
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CursiveCustomSpells]|r Known seal textures:")
            for tex, data in pairs(sealToJudgement) do
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  %s -> %s", tex, data.name))
            end

        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[CursiveCustomSpells]|r Commands:")
            DEFAULT_CHAT_FRAME:AddMessage("  /cleveroid cursive list - Show custom spells and status")
            DEFAULT_CHAT_FRAME:AddMessage("  /cleveroid cursive add <spellID> <duration> [name]")
            DEFAULT_CHAT_FRAME:AddMessage("  /cleveroid cursive remove <spellID>")
            DEFAULT_CHAT_FRAME:AddMessage("  /cleveroid cursive inject - Force re-injection")
        end
        return
    end

    if originalConsoleHandler then
        originalConsoleHandler(msg)
    end
end

return ext
