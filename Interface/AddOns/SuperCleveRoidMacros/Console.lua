--[[
	Author: Dennis Werner Garske (DWG) / brian / Mewtiny
	License: MIT License
]]
local _G = _G or getfenv(0)
local CleveRoids = _G.CleveRoids or {}

SLASH_PETATTACK1 = "/petattack"

SlashCmdList.PETATTACK = function(msg) CleveRoids.DoPetAction(PetAttack, msg); end

SLASH_PETFOLLOW1 = "/petfollow"

SlashCmdList.PETFOLLOW = function(msg) CleveRoids.DoPetAction(PetFollow, msg); end

SLASH_PETWAIT1 = "/petwait"

SlashCmdList.PETWAIT = function(msg) CleveRoids.DoPetAction(PetWait, msg); end

SLASH_PETPASSIVE1 = "/petpassive"

SlashCmdList.PETPASSIVE = function(msg) CleveRoids.DoPetAction(PetPassiveMode, msg); end

SLASH_PETAGGRESSIVE1 = "/petaggressive"

SlashCmdList.PETAGGRESSIVE = function(msg) CleveRoids.DoPetAction(PetAggressiveMode, msg); end

SLASH_PETDEFENSIVE1 = "/petdefensive"

SlashCmdList.PETDEFENSIVE = function(msg) CleveRoids.DoPetAction(PetDefensiveMode, msg); end

SLASH_RELOAD1 = "/rl"

SlashCmdList.RELOAD = function() ReloadUI(); end

SLASH_USE1 = "/use"

SlashCmdList.USE = CleveRoids.DoUse

SLASH_EQUIP1 = "/equip"

SlashCmdList.EQUIP = CleveRoids.DoUse
-- take back supermacro and pfUI /equip and /use
SlashCmdList.SMEQUIP = CleveRoids.DoUse
SlashCmdList.PFEQUIP = CleveRoids.DoUse
SlashCmdList.PFUSE = CleveRoids.DoUse

SLASH_EQUIPMH1 = "/equipmh"
SlashCmdList.EQUIPMH = CleveRoids.DoEquipMainhand

SLASH_EQUIPOH1 = "/equipoh"
SlashCmdList.EQUIPOH = CleveRoids.DoEquipOffhand

SLASH_EQSLOT111 = "/equip11"
SlashCmdList.EQSLOT11 = CleveRoids.DoEquipRing1

SLASH_EQSLOT121 = "/equip12"
SlashCmdList.EQSLOT12 = CleveRoids.DoEquipRing2

SLASH_EQSLOT131 = "/equip13"
SlashCmdList.EQSLOT13 = CleveRoids.DoEquipTrinket1

SLASH_EQSLOT141 = "/equip14"
SlashCmdList.EQSLOT14 = CleveRoids.DoEquipTrinket2

SLASH_UNSHIFT1 = "/unshift"

SlashCmdList.UNSHIFT = CleveRoids.DoUnshift

SLASH_UNQUEUE1 = "/unqueue"
-- 修复：/unqueue 原来只是 SpellStopCasting，不会清理本插件记录的队列/施法状态，
-- Nampower 队列把技能延迟弹出时事件可能丢失，状态卡死会导致宏被 [casting] 类条件卡住。
-- 现在先清理插件侧状态再停止施法（注意：Nampower 无清空队列的 API，已排队的技能仍可能弹出） by 武藤纯子酱 2026.8.31
SlashCmdList.UNQUEUE = function()
    CleveRoids.queuedSpell = nil
    if CleveRoids.CurrentSpell then
        CleveRoids.CurrentSpell.type = ""
        CleveRoids.CurrentSpell.spellName = ""
        CleveRoids.CurrentSpell.castingSpellId = nil
    end
    CleveRoids.channelStartTime = 0
    CleveRoids.channelDuration = 0
    if CleveRoids.spell_tracking then
        CleveRoids.spell_tracking["player"] = nil
    end
    if CleveRoids.QueueActionUpdate then
        CleveRoids.QueueActionUpdate()
    end
    SpellStopCasting()
end

-- TODO make this conditional too
SLASH_CANCELAURA1 = "/cancelaura"
SLASH_CANCELAURA2 = "/unbuff"

SlashCmdList.CANCELAURA = CleveRoids.DoConditionalCancelAura

SLASH_CASTPET1 = "/castpet"

SlashCmdList.CASTPET = function(msg)
    CleveRoids.DoCastPet(msg)
end

-- Define original implementations before hooking them.
-- This ensures we have a fallback for non-conditional use.
local StartAttack = function(msg)
    if not UnitExists("target") or CleveRoids.IsUnitDead("target") then TargetNearestEnemy() end
    -- Check both event-based flag AND action bar state for reliable detection
    local isAttacking = CleveRoids.CurrentSpell.autoAttack
    if not isAttacking then
        -- Fallback: check action bar state via IsCurrentAction
        local slot = CleveRoids.GetProxyActionSlot(CleveRoids.Localized.Attack)
        if slot and IsCurrentAction(slot) then
            CleveRoids.CurrentSpell.autoAttack = true
            isAttacking = true
        end
    end
    if not isAttacking and not CleveRoids.CurrentSpell.autoAttackLock and UnitExists("target") and UnitCanAttack("player","target") then
        CleveRoids.CurrentSpell.autoAttackLock = true
        CleveRoids.autoAttackLockElapsed = GetTime()
        AttackTarget()
        -- FIX: Immediately set autoAttack flag so subsequent macro lines know attack started
        -- Don't wait for PLAYER_ENTER_COMBAT event which has a delay
        CleveRoids.CurrentSpell.autoAttack = true
        -- FIX: Queue icon update so action bars reflect the new state
        if CleveRoidMacros and CleveRoidMacros.realtime == 0 then
            CleveRoids.QueueActionUpdate()
        end
    end
end

local StopAttack = function(msg)
    -- Deferred to next frame because CastSpellByName starts autoattack as a C++
    -- side-effect that hasn't settled yet — AttackTarget() toggle misses it.
    CleveRoids.DeferStopAttack()
end

-- Register slash commands and assign original handlers.
-- These will be hooked immediately after.
SLASH_STARTATTACK1 = "/startattack"
SlashCmdList.STARTATTACK = StartAttack

SLASH_STOPATTACK1 = "/stopattack"
SlashCmdList.STOPATTACK = StopAttack

SLASH_STOPCASTING1 = "/stopcasting"
SlashCmdList.STOPCASTING = SpellStopCasting

SLASH_CLEARTARGET1 = "/cleartarget"
SlashCmdList.CLEARTARGET = ClearTarget

-- /stopspelltarget：取消当前正在瞄准的法术（条件支持）by 武藤纯子酱 2026.9.3
SLASH_STOPSPELLTARGET1 = "/stopspelltarget"
SlashCmdList.STOPSPELLTARGET = function(msg)
    if string.find(msg or "", "%[") then
        CleveRoids.DoConditionalStopSpellTarget(msg)
    else
        SpellStopTargeting()
    end
end

-- /petdismiss：解散野兽（1.12 无 PetDismiss API，经"解散野兽"技能实现）by 武藤纯子酱 2026.9.3
SLASH_PETDISMISS1 = "/petdismiss"
SlashCmdList.PETDISMISS = function(msg)
    if string.find(msg or "", "%[") then
        CleveRoids.DoConditionalPetDismiss(msg)
    else
        CleveRoids.DoPetAction(CleveRoids._petDismissFallback, msg)
    end
end

----------------------------------
-- HOOK DEFINITIONS START
----------------------------------

-- /cleartarget hook
CleveRoids.Hooks.CLEARTARGET_SlashCmd = SlashCmdList.CLEARTARGET
SlashCmdList.CLEARTARGET = function(msg)
    if CleveRoids.stopMacroFlag then return end
    msg = msg or ""
    if string.find(msg, "%[") then
        CleveRoids.DoConditionalClearTarget(msg)
    else
        CleveRoids.Hooks.CLEARTARGET_SlashCmd()
    end
end

-- /startattack hook
CleveRoids.Hooks.STARTATTACK_SlashCmd = SlashCmdList.STARTATTACK
SlashCmdList.STARTATTACK = function(msg)
    if CleveRoids.stopMacroFlag then return end
    msg = msg or ""
    if string.find(msg, "%[") then
        CleveRoids.DoConditionalStartAttack(msg)
    else
        CleveRoids.Hooks.STARTATTACK_SlashCmd(msg)
    end
end

-- /stopattack hook
CleveRoids.Hooks.STOPATTACK_SlashCmd = SlashCmdList.STOPATTACK
SlashCmdList.STOPATTACK = function(msg)
    if CleveRoids.stopMacroFlag then return end
    msg = msg or ""
    if string.find(msg, "%[") then
        -- If conditionals are present, let the function handle it.
        -- It will only stop the attack if the conditions are met.
        CleveRoids.DoConditionalStopAttack(msg)
    else
        -- If no conditionals, run the original command.
        CleveRoids.Hooks.STOPATTACK_SlashCmd(msg)
    end
end

-- /stopcasting hook
CleveRoids.Hooks.STOPCASTING_SlashCmd = SlashCmdList.STOPCASTING
SlashCmdList.STOPCASTING = function(msg)
    if CleveRoids.stopMacroFlag then return end
    msg = msg or ""
    if string.find(msg, "%[") then
        -- If conditionals are present, let the function handle it.
        -- It will only stop the cast if the conditions are met.
        CleveRoids.DoConditionalStopCasting(msg)
    else
        -- If no conditionals, run the original command.
        CleveRoids.Hooks.STOPCASTING_SlashCmd()
    end
end

-- /unqueue hook
CleveRoids.Hooks.UNQUEUE_SlashCmd = SlashCmdList.UNQUEUE
SlashCmdList.UNQUEUE = function(msg)
    if CleveRoids.stopMacroFlag then return end
    msg = msg or ""
    if string.find(msg, "%[") then
        -- If conditionals are present, let the function handle it.
        CleveRoids.DoConditionalStopCasting(msg)
    else
        -- If no conditionals, run the original command.
        CleveRoids.Hooks.UNQUEUE_SlashCmd()
    end
end

-- /cast hook
CleveRoids.Hooks.CAST_SlashCmd = SlashCmdList.CAST
SlashCmdList.CAST = function(msg)
    if CleveRoids.stopMacroFlag or CleveRoids.skipMacroFlag then return end
    if msg and string.find(msg, "[%[%?!~{]") then
        CleveRoids.DoCast(msg)
    else
        -- Use lastComboPoints which is updated on every OnUpdate tick
        -- This is critical for instant-cast finishers where GetComboPoints() returns 0 immediately
        local currentCP = CleveRoids.lastComboPoints or 0

        -- Also try GetComboPoints as a fallback
        if currentCP == 0 and GetComboPoints then
            currentCP = GetComboPoints()
        end

        if currentCP > 0 then
            if CleveRoids.debug then
                DEFAULT_CHAT_FRAME:AddMessage(
                    string.format("|cffaaff00[/cast Hook]|r Using %d CP for %s",
                        currentCP, tostring(msg)) -- 修复：msg 为 nil 时 format("%s") 崩溃 by 武藤纯子酱 2026.9.11
                )
            end

            -- Pre-inject combo duration into pfUI for instant-cast combo finishers
            -- Get the spell data to find the proper spell name (handles case-insensitive input)
            local spellData = CleveRoids.GetSpell and CleveRoids.GetSpell(msg)
            local spellName = spellData and spellData.name or msg

            -- If GetSpell didn't find it, capitalize first letter as fallback
            if not spellData and spellName then
                spellName = string.upper(string.sub(spellName, 1, 1)) .. string.sub(spellName, 2)
            end

            if CleveRoids.debug then
                DEFAULT_CHAT_FRAME:AddMessage(
                    string.format("|cffcccccc[/cast Debug]|r input='%s', spellName='%s', GetSpell=%s, IsComboScalingSpell=%s",
                        msg, spellName or "nil", tostring(spellData ~= nil), tostring(CleveRoids.IsComboScalingSpell ~= nil))
                )
            end

            if CleveRoids.IsComboScalingSpell and CleveRoids.IsComboScalingSpell(spellName) then
                if CleveRoids.debug then
                    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[/cast Debug]|r IS combo scaling spell")
                end
                local duration = CleveRoids.CalculateComboScaledDuration and
                                 CleveRoids.CalculateComboScaledDuration(spellName, currentCP)
                if CleveRoids.debug then
                    DEFAULT_CHAT_FRAME:AddMessage(
                        string.format("|cffcccccc[/cast Debug]|r duration=%s, pfUI=%s, pfUI.api=%s, pfUI.api.libdebuff=%s, debuffs=%s",
                            tostring(duration), tostring(pfUI ~= nil),
                            tostring(pfUI and pfUI.api ~= nil),
                            tostring(pfUI and pfUI.api and pfUI.api.libdebuff ~= nil),
                            tostring(pfUI and pfUI.api and pfUI.api.libdebuff and pfUI.api.libdebuff.debuffs ~= nil))
                    )
                end
                if duration and CleveRoids.ComboPointTracking then
                    -- Remove rank from spell name for pfUI compatibility
                    local baseName = CleveRoids.StripRank(spellName)
                    -- Populate name-based tracking BEFORE the spell is cast
                    -- This allows pfUI's AddEffect hook to find it
                    CleveRoids.ComboPointTracking[baseName] = {
                        combo_points = currentCP,
                        duration = duration,
                        cast_time = GetTime(),
                        target = UnitName("target") or "Unknown",
                        confirmed = true
                    }
                    if CleveRoids.debug then
                        DEFAULT_CHAT_FRAME:AddMessage(
                            string.format("|cffff00ff[/cast Pre-Tracking]|r Set tracking['%s'] = %ds (%d CP)",
                                baseName, duration, currentCP)
                        )
                    end
                end
            elseif CleveRoids.debug and currentCP > 0 then
                DEFAULT_CHAT_FRAME:AddMessage("|cffff9900[/cast Debug]|r NOT a combo scaling spell")
            end
        end
        CleveRoids.Hooks.CAST_SlashCmd(msg)
    end
end

CleveRoids.Hooks.TARGET_SlashCmd = SlashCmdList.TARGET
CleveRoids.TARGET_SlashCmd = function(msg)
    local tmsg = CleveRoids.Trim(msg or "") -- 修复：缺 local，tmsg 泄漏为全局变量；并加 nil 保护（无参 /target）by 武藤纯子酱 2026.9.11

    if tmsg ~= "" and not string.find(tmsg, "%[") and not string.find(tmsg, "@") then
        CleveRoids.Hooks.TARGET_SlashCmd(tmsg)
        return
    end

    if CleveRoids.DoTarget(tmsg) then
        if UnitExists("target") then
            return
        end
    end
    CleveRoids.Hooks.TARGET_SlashCmd(msg)
end
SlashCmdList.TARGET = CleveRoids.TARGET_SlashCmd

-- /follow：跟随目标（支持 [条件]）by 武藤纯子酱 2026.9.16
CleveRoids.Hooks.FOLLOW_SlashCmd = SlashCmdList.FOLLOW
SLASH_FOLLOW1 = "/follow"
SlashCmdList.FOLLOW = function(msg)
    msg = msg or ""
    if string.find(msg, "%[") then
        CleveRoids.DoFollow(msg)
    elseif CleveRoids.Hooks.FOLLOW_SlashCmd then
        CleveRoids.Hooks.FOLLOW_SlashCmd(msg)
    end
end


SLASH_CASTSEQUENCE1 = "/castsequence"
SlashCmdList.CASTSEQUENCE = function(msg)
    msg = CleveRoids.Trim(msg)
    local sequence = CleveRoids.GetSequence(msg)
    if not sequence then return end
    -- if not sequence.active then return end

    CleveRoids.DoCastSequence(sequence)
end



SLASH_RUNMACRO1 = "/runmacro" --新增条件支持 by 武藤纯子酱 2025.11.26
function SlashCmdList.RUNMACRO(msg)
    if not msg then return end
    return CleveRoids.SafeRunMacro("macro", msg)
end

-- Global RunMacro wrapper for user convenience (delegates to namespaced internal function)
-- This pattern ensures internal logic uses CleveRoids.ExecuteMacroByName and won't break
-- if another addon overwrites the global RunMacro
-- NOTE: When SuperMacro is also loaded, Compatibility/SuperMacro.lua redirects this to
-- SuperMacro_RunMacro so macros go through RunLine (where CRM commands are intercepted)
function RunMacro(name)
    return CleveRoids.ExecuteMacroByName(name)
end

SLASH_RETARGET1 = "/retarget" --新增条件支持 by 武藤纯子酱 2025.11.26
SlashCmdList.RETARGET = function(msg)
    CleveRoids.DoRetarget(msg)
end

SLASH_STOPMACRO1 = "/stopmacro"
SlashCmdList.STOPMACRO = function(msg)
    CleveRoids.DoStopMacro(msg)
end

SLASH_SKIPMACRO1 = "/skipmacro"
SlashCmdList.SKIPMACRO = function(msg)
    CleveRoids.DoSkipMacro(msg)
end

-- Enable "first action only" mode - stop evaluation after first successful /cast or /use
-- Example:
--   /firstaction
--   /cast [myrawpower:>48] Shred
--   /cast [myrawpower:>40] Claw
-- Result: Only Shred casts if energy >= 48, Claw won't be queued
SLASH_FIRSTACTION1 = "/firstaction"
SlashCmdList.FIRSTACTION = function(msg)
    CleveRoids.DoFirstAction(msg)
end

-- Re-enable multi-queue behavior after /firstaction
-- Use this to restore normal evaluation where multiple casts can queue
-- Example:
--   /firstaction
--   /cast [myrawpower:>48] Shred      -- Priority section
--   /cast [myrawpower:>40] Claw
--   /nofirstaction
--   /cast Tiger's Fury                -- Can queue alongside above
SLASH_NOFIRSTACTION1 = "/nofirstaction"
SlashCmdList.NOFIRSTACTION = function(msg)
    CleveRoids.DoNoFirstAction(msg)
end

-- QuickHeal with conditionals support (requires QuickHeal addon)
-- Usage: /quickheal [conditionals] [target] [type]
-- Examples:
--   /quickheal                     -- Smart heal (auto-select target)
--   /quickheal target              -- Heal current target
--   /quickheal [combat] party      -- Heal party member if in combat
--   /quickheal [mypower:>50] mt    -- Heal tank if mana > 50%
--   /quickheal [threat:<80] hot    -- Apply HoT if threat is low
SLASH_QUICKHEAL1 = "/quickheal"
SLASH_QUICKHEAL2 = "/qh"
SlashCmdList.QUICKHEAL = function(msg)
    CleveRoids.DoQuickHeal(msg)
end

--- Execute QuickHeal with optional conditionals
--- @param msg string The command arguments (conditionals + QuickHeal params)
function CleveRoids.DoQuickHeal(msg)
    -- Check if QuickHeal addon is loaded
    if type(QuickHeal) ~= "function" then
        if not CleveRoids._quickHealErrorShown then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[SuperCleveRoidMacros]|r The /quickheal command requires the QuickHeal addon.", 1, 0.5, 0.5)
            CleveRoids._quickHealErrorShown = true
        end
        return
    end

    msg = CleveRoids.Trim(msg or "")

    -- Check if there are conditionals
    if string.find(msg, "%[") then
        -- 修复：ParseMsg 的第一返回值是字符串（动作内容），不是动作数组，
        -- 原代码 table.getn(actions) 对字符串取长度必然报错，条件版 /quickheal 完全不可用。
        -- 改为逐分支解析并评估条件，命中第一个满足条件的分支后执行 QuickHeal by 武藤纯子酱 2026.8.31
        local function quickHealAction(args)
            args = CleveRoids.Trim(args or "")
            -- 与无条件分支保持一致：QuickHeal 首参可为目标或类型关键字，由插件自行解析
            if args == "" then
                QuickHeal()
            else
                QuickHeal(args)
            end
            return true
        end

        for _, branch in pairs(CleveRoids.splitStringIgnoringQuotes(msg)) do
            if branch and branch ~= "" then
                if CleveRoids.DoWithConditionals(branch, quickHealAction, nil, false, quickHealAction) then
                    return
                end
            end
        end
        -- No conditions matched - don't heal
        return
    else
        -- No conditionals, pass through to QuickHeal directly
        -- Parse basic args: target and/or type
        local args = msg
        if args == "" then
            QuickHeal()
        else
            -- QuickHeal accepts: Target, SpellID, extParam, forceMaxHPS
            -- Common targets: player, target, targettarget, party, mt, nonmt, subgroup
            -- Common types: heal, hot, hs (paladin), chainheal (shaman)
            QuickHeal(args)
        end
    end
end

--新增 by 武藤纯子酱 2025.11.26
SLASH_PETSTAY1 = "/petstay"
SlashCmdList.PETSTAY = function(msg) CleveRoids.DoPetAction(PetWait, msg); end

SLASH_CASTRANDOM1 = "/castrandom"
function SlashCmdList.CASTRANDOM(msg)
    if not msg then return end

    local action = function(args, conditionals)
        if not args or args == "" then return end

        -- 修复：原 strsplit(args, ",") 参数颠倒（全局 strsplit 是 (delimiter, subject)
        -- 且返回多值，单赋值只取到首值字符串）→ getn(字符串) 报错；改用本插件的表版分割
        -- by 武藤纯子酱 2026.9.11
        local tbl = CleveRoids.splitString(args, ",")
        -- 过滤空项——"/castrandom A,,B" 随机到空项会 CastSpellByName("") 抛 Usage，
        -- "/castrandom ," 全空项时 math.random(1,0) 抛 "interval is empty" by 武藤纯子酱 2026.9.11
        local filtered = {}
        for i = 1, getn(tbl) do
            local item = tbl[i]
            if item and item ~= "" then
                -- 去首尾空格
                while strsub(item,1,1) == " " do item = strsub(item,2) end
                while item ~= "" and strsub(item,strlen(item)) == " " do item = strsub(item, 1, (strlen(item)-1)) end
                if item ~= "" then
                    table.insert(filtered, item)
                end
            end
        end
        if getn(filtered) == 0 then return end

        local spell = filtered[math.random(1,getn(filtered))]
        -- 统一引导打断：/castrandom 也按 clip 模式处理（conditionals 由 DoWithConditionals 传入） by 武藤纯子酱 2026.9.12
        if CleveRoids.ClipBeforeSpellCast and not CleveRoids.ClipBeforeSpellCast(spell, conditionals) then
            return
        end
        CastSpellByName(spell)
    end
    
    if string.find(msg, "%[") then
        CleveRoids.DoConditionalCastRandom(action,msg)
    else
        action(msg)
    end
end

SLASH_UNSHIFT2 = "/cancelform"

SLASH_SWITCH1 = "/switch"
SlashCmdList.SWITCH = CleveRoids.DoSwitch

SLASH_EQUIPSLOT1 = "/equipslot"
SlashCmdList.EQUIPSLOT = CleveRoids.DoEquipSlot

SLASH_ASSIST1 = "/assist"
SlashCmdList.ASSIST = CleveRoids.DoAssist
 
SLASH_TARGETENEMY1 = "/targetenemy"
SlashCmdList.TARGETENEMY = CleveRoids.DoTargetEnemy
 
SLASH_TARGETENEMYPLAYER1 = "/targetenemyplayer"
SlashCmdList.TARGETENEMYPLAYER = CleveRoids.DoTargetEnemyPlayer
 
SLASH_TARGETFRIEND1 = "/targetfriend"
SlashCmdList.TARGETFRIEND = CleveRoids.DoTargetFriend
 
SLASH_TARGETFRIENDPLAYER1 = "/targetfriendplayer"
SlashCmdList.TARGETFRIENDPLAYER = CleveRoids.DoTargetFriendPlayer
 
SLASH_TARGETLASTENEMY1 = "/targetlastenemy"
SlashCmdList.TARGETLASTENEMY = CleveRoids.DoTargetLastEnemy
 
SLASH_TARGETLASTFRIEND1 = "/targetlastfriend"
SlashCmdList.TARGETLASTFRIEND = CleveRoids.DoTargetLastFriend
 
SLASH_TARGETLASTTARGET1 = "/targetlasttarget"
SLASH_TARGETLASTTARGET2 = "/lasttarget"
SlashCmdList.TARGETLASTTARGET = CleveRoids.DoTargetLastTarget
 
SLASH_TARGETPARTY1 = "/targetparty"
SlashCmdList.TARGETPARTY = CleveRoids.DoTargetParty
 
SLASH_TARGETRAID1 = "/targetraid"
SlashCmdList.TARGETRAID = CleveRoids.DoTargetRaid

SLASH_TARGETEXACT1 = "/targetexact"
SlashCmdList.TARGETEXACT = CleveRoids.DoTargetExact

SLASH_PETAUTOCASTOFF1 = "/petautocastoff"
SlashCmdList.PETAUTOCASTOFF = CleveRoids.DoPetAutoCastOff
 
SLASH_PETAUTOCASTON1 = "/petautocaston"
SlashCmdList.PETAUTOCASTON = CleveRoids.DoPetAutoCastOn
 
SLASH_PETAUTOCASTTOGGLE1 = "/petautocasttoggle"
SlashCmdList.PETAUTOCASTTOGGLE = CleveRoids.DoPetAutoCastToggle

SLASH_MOUNT1 = "/mount"
SlashCmdList.MOUNT = CleveRoids.DoMount
 
SLASH_DISMOUNT1 = "/dismount"
SlashCmdList.DISMOUNT = CleveRoids.DoDismount

SLASH_CHANGEACTIONBAR1 = "/changeactionbar"
SlashCmdList.CHANGEACTIONBAR = CleveRoids.DoChangeActionBar

SLASH_SWAPACTIONBAR1 = "/swapactionbar"
SlashCmdList.SWAPACTIONBAR = CleveRoids.DoSwapActionBar

SLASH_USERNADOM1 = "/userandom"
function SlashCmdList.USERNADOM(msg)
    if not msg then return end

    local action = function(args)
        if not args or args == "" then return end

        -- 修复：原 strsplit(args, ",") 参数颠倒/多值问题，改用表版分割；空项过滤防止
        -- math.random(1,0) 与 DoUse("") 崩溃 by 武藤纯子酱 2026.9.11
        local items = CleveRoids.splitString(args, ",")
        local filtered = {}
        for i = 1, getn(items) do
            local it = items[i]
            if it and it ~= "" then
                while strsub(it,1,1) == " " do it = strsub(it,2) end
                while it ~= "" and strsub(it,strlen(it)) == " " do it = strsub(it, 1, (strlen(it)-1)) end
                if it ~= "" then
                    table.insert(filtered, it)
                end
            end
        end
        if getn(filtered) == 0 then return end

        local item = filtered[math.random(1,getn(filtered))]
        CleveRoids.DoUse(item)
    end
    
    if string.find(msg, "%[") then
        CleveRoids.DoWithConditionals(msg, nil, CleveRoids.FixEmptyTarget, false, action)
    else
        action(msg)
    end
end

SLASH_FEED1 = "/feed"
SlashCmdList.FEED = function(msg)
    CleveRoids.DoFeed(msg)
end

SLASH_RUNSUPERMACRO1 = "/runsupermacro"
function SlashCmdList.RUNSUPERMACRO(msg)
    if not msg or not RunSuperMacro then return false end
    return CleveRoids.SafeRunMacro("supermacro", msg)
end

SLASH_RH1 = "/rh"
function SlashCmdList.RH(msg)
    if not msg then return end
    
    -- 解析模式：mw|a|ms
    local action = function(args)
        if not args or args == "" then return end
        
        -- 提取模式字符（mw/a/ms）和实际参数
        local mode, actualArgs
        if string.sub(args, 1, 2) == "mw" then
            mode = "mw"
            actualArgs = string.sub(args, 3)
        -- 修复：/rh a 需要整段才是模式"a"，否则 /rh all /rh arena 等以 a 开头的参数被误判
        -- 为模式"a"导致参数被吞掉首字符 by 武藤纯子酱 2026.8.31
        elseif args == "a" or string.sub(args, 1, 2) == "a " then
            mode = "a"
            actualArgs = string.sub(args, (args == "a") and 2 or 3)
        elseif string.sub(args, 1, 2) == "ms" then
            mode = "ms"
            actualArgs = string.sub(args, 3)
        else
            -- 默认模式为 mw（向后兼容）
            mode = "mw"
            actualArgs = args
        end
        
        -- 去除参数开头的空格
        actualArgs = CleveRoids.Trim(actualArgs)
        
        -- 根据模式调用相应的函数
        if mode == "mw" and type(Heart_HealMostWounded) == "function" then
            Heart_HealMostWounded(actualArgs)
        elseif mode == "a" and type(Heart_ActionHeal) == "function" then
            Heart_ActionHeal(actualArgs)
        elseif mode == "ms" and type(Heart_HealMostWoundedMS) == "function" then
            Heart_HealMostWoundedMS(actualArgs)
		else
			return
        end
    end
    
    if string.find(msg, "%[") then
        -- 支持条件判断
        CleveRoids.DoWithConditionals(msg, nil, CleveRoids.FixEmptyTarget, false, action)
    else
        action(msg)
    end
end

SLASH_SETTAG1 = "/settag"
function SlashCmdList.SETTAG(msg)
	CleveRoids.SetTags = true
	
	local tag = CleveRoids.Trim(string.gsub(msg or "", "%[.-%]", "")) -- 修复：nil 保护（无参 /settag）by 武藤纯子酱 2026.9.11

	if not tag or tag == "" then return end
	-- 记录该 tag 性质：其 /settag 行是否含"引导计时"条件（供 clip 模式 2 判定：
	-- 含引导计时判定的 tag 成立后，引用该 tag 的行也按"引导计时行"处理）by 武藤纯子酱 2026.9.12
	CleveRoids._channelTimingTags = CleveRoids._channelTimingTags or {}
	local _tagSrc = msg or ""
	CleveRoids._channelTimingTags[tag] = (string.find(_tagSrc, "channeltime", 1, true) or string.find(_tagSrc, "schtime", 1, true) or string.find(_tagSrc, "getchannel", 1, true)) and true or nil
	
	CleveRoids.Tags[tag] = false
	CleveRoids.TagUnits[tag] = {}
	
    local action = function(args)
        if not args or args == "" then return end -- 修复：空 tag 不再写入 Tags[""]=true by 武藤纯子酱 2026.8.31
        CleveRoids.Tags[args] = true
        CleveRoids.SetTags = false
    end
	
	local removetag = function()
		CleveRoids.SetTags = false
	end

    if string.find(msg, "%[") then		
        -- 支持条件判断
        CleveRoids.DoWithConditionals(msg, removetag, CleveRoids.FixEmptyTarget, false, action)
    else		
        action(tag)
		CleveRoids.SetTags = false
    end
end

SLASH_CRMRUN1 = "/crmrun"
SlashCmdList.CRMRUN = function(msg)
    CleveRoids.DoCrmRun(msg)
end

SLASH_SENDMESSAGE1 = "/sendmessage"
SlashCmdList.SENDMESSAGE = function(msg)
    CleveRoids.DoSendMessage(msg)
end

SlashCmdList.COMMENT = function() end

-- /attack：等同 /startattack（开始自动攻击）by 武藤纯子酱 2026.9.16
SLASH_ATTACK1 = "/attack"
SlashCmdList.ATTACK = StartAttack

-- /lastenemy：等同 /targetlastenemy（选上一个敌人）by 武藤纯子酱 2026.9.16
SLASH_TARGETLASTENEMY2 = "/lastenemy"

-- /autoshoot：等同 /cast !自动射击 by 武藤纯子酱 2026.9.16
SLASH_AUTOSHOOT1 = "/autoshoot"
SlashCmdList.AUTOSHOOT = function(msg) CleveRoids.DoBangCast(msg, CleveRoids.Localized.AutoShot) end

-- /shootattack：等同 /cast !射击 by 武藤纯子酱 2026.9.16
SLASH_SHOOTATTACK1 = "/shootattack"
SlashCmdList.SHOOTATTACK = function(msg) CleveRoids.DoBangCast(msg, CleveRoids.Localized.Shoot) end

-- /stopshoot：关闭自动射击/射击 by 武藤纯子酱 2026.9.16
SLASH_STOPSHOOT1 = "/stopshoot"
SlashCmdList.STOPSHOOT = function(msg) CleveRoids.DoStopShoot(msg) end

-- /pickup：拿起装备栏/背包物品 by 武藤纯子酱 2026.9.16
SLASH_PICKUP1 = "/pickup"
SlashCmdList.PICKUP = function(msg) CleveRoids.DoPickup(msg) end

-- /unequip：卸下指定装备栏 by 武藤纯子酱 2026.9.16
SLASH_UNEQUIP1 = "/unequip"
SlashCmdList.UNEQUIP = function(msg) CleveRoids.DoUnequip(msg) end

-- /click：模拟点击有名字的 UI 按钮（1.12 无此命令，用 Button:Click() 实现）by 武藤纯子酱 2026.9.23
SLASH_CLICK1 = "/click"
SlashCmdList.CLICK = function(msg) CleveRoids.DoClick(msg) end

-- /threshold：设置/显示拾取品质门槛（1.12 无此命令，用 SetLootThreshold 实现）by 武藤纯子酱 2026.9.23
SLASH_THRESHOLD1 = "/threshold"
SlashCmdList.THRESHOLD = function(msg) CleveRoids.DoThreshold(msg) end

-- 屏蔽/注释整行：把任意命令写成 /--命令 即临时禁用该行（如 /--cast、/--use、/--petattack）
-- 为所有已注册命令自动生成 /--<命令> 别名，统一指向 no-op 的 COMMENT 处理器 by 武藤纯子酱 2026.9.16
do
    local G = _G or getfenv(0)
    local seen, cmds = {}, {}
    for k, val in pairs(G) do
        if type(k) == "string" and string.sub(k, 1, 6) == "SLASH_" and type(val) == "string" then
            local c = string.match(val, "^/([%a%d_-]+)$") -- 仅 ASCII 命令
            if c and not seen[c] then
                seen[c] = true
                table.insert(cmds, c)
            end
        end
    end
    for i = 1, table.getn(cmds) do
        G["SLASH_COMMENT" .. i] = "/--" .. cmds[i]
    end
end

--以上为新增 by 武藤纯子酱 2025.11.26
