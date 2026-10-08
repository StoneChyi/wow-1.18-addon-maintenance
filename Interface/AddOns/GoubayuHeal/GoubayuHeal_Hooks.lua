-- ============================================================
-- 文件名: GoubayuHeal_Hooks.lua
-- 功能: 钩子函数，用于拦截 CastSpellByName / CastSpell / SpellStopCasting / SpellStopTargeting
--       以追踪施法目标，确保治疗目标正确传递
-- ============================================================

-- 确保 clean_spell_awaiting_target 函数存在
if not GoubayuHeal.clean_spell_awaiting_target then
    function GoubayuHeal.clean_spell_awaiting_target()
        GoubayuHeal.spell_awaiting_target_Spell = nil
        GoubayuHeal.spell_awaiting_target_Rank = nil
        GoubayuHeal.spell_awaiting_target_Target = nil
    end
end

-- 拦截 CastSpellByName，提取法术名和等级，若为治疗法术则记录等待目标
function GoubayuHeal.CastSpellByName(inputspell, onSelf)
    if not inputspell then
        return
    end
    local _, tempSpell, rank, spell

    -- 去除末尾分号和空白（用懒惰匹配，避免贪婪 .* 吞掉分号后 ;? 永远匹配不到）
    _, _, spell = strfind(inputspell, "^(.-);?%s*$")

    -- 去除末尾的 ()
    while (string.sub(spell, -2) == "()") do
        spell = string.sub(spell, 1, -3)
    end

    -- 去除开头空白
    _, _, spell = strfind(spell, "^%s*(.*)$")

    -- 尝试匹配等级后缀 (等级 x) / (Rank x)，%d+ 兼容两位数等级（恢复10级/治疗之触11级以上）
    -- 三级回退，依次尝试：
    --   1. RANK  —— 魔兽客户端内置全局字符串（非插件定义！游戏内 /run print(RANK, LEVEL) 可查看，
    --               zhCN 客户端 RANK="级别"），处理游戏动作条/宏生成的字符串
    --   2. LEVEL —— 同为客户端内置全局字符串（zhCN 客户端 LEVEL="等级"）
    --   3. GoubayuHeal.RANK —— 插件自构等级后缀用的词（Locale.lua，zhCN="等级"/enUS="Rank"），
    --               处理本插件 Heal() 拼出的 "技能名(等级 x)" 字符串
    _, _, tempSpell, rank = strfind(spell, "(.*)%(" .. (RANK or "") .. " (%d+)%)$")
    if not tempSpell then
        _, _, tempSpell, rank = strfind(spell, "(.*)%(" .. (LEVEL or "") .. " (%d+)%)$")
    end
    if not tempSpell and GoubayuHeal.RANK and GoubayuHeal.RANK ~= RANK then
        _, _, tempSpell, rank = strfind(spell, "(.*)%(" .. GoubayuHeal.RANK .. " (%d+)%)$")
    end
    if (tempSpell and rank) then
        spell = tempSpell
        rank = tonumber(rank)
    else
        rank = 0
    end

    -- 若当前没有正在记录的治疗目标，且该法术属于治疗法术，则记录等待目标
    if (GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][rank]
        and not (GoubayuHeal.i_am_healing and GoubayuHeal.healing[GoubayuHeal.i_am_healing]
            and GoubayuHeal.healing[GoubayuHeal.i_am_healing][GoubayuHeal.my_name])) then
        -- 新记录先清掉旧 Target 残留：上次自施留下的 "player" 若不清，
        -- 本次非自施施法会被 SPELLCAST_START 强制指到自己 by 武藤纯子酱 2026.9.4
        GoubayuHeal.spell_awaiting_target_Target = nil
        GoubayuHeal.spell_awaiting_target_Spell = spell
        GoubayuHeal.spell_awaiting_target_Rank = rank
        -- 仅显式"对自己施法"才标记：原版约定第二参为 1/true/"player"；
        -- Nampower 增强版第二参是目标 GUID 字符串，不能再按真值当作"对自己"处理，
        -- 但传入玩家自己的 GUID 时语义上就是自施，需比对识别
        if onSelf == true or onSelf == 1 or onSelf == "player"
            or (type(onSelf) == "string" and GoubayuHeal.GetUnitGUID
                and onSelf == GoubayuHeal.GetUnitGUID("player")) then
            GoubayuHeal.spell_awaiting_target_Target = "player"
        end
    end

    -- 庇佑打标：本次施放"愈合"时记录 目标是否有回春 + 自身是否有该天赋
    -- （施法目标：自施=player；Nampower 第二参为目标GUID；否则当前友方目标）
    if spell == GoubayuHeal.Regrowth and GoubayuHeal.MarkRegrowthCast then
        local tUnit
        if onSelf == true or onSelf == 1 or onSelf == "player" then
            tUnit = "player"
        elseif type(onSelf) == "string" and onSelf ~= "" then
            tUnit = onSelf
        elseif UnitExists("target") and UnitIsFriend("player", "target") then
            tUnit = "target"
        end
        if tUnit then
            GoubayuHeal.MarkRegrowthCast(tUnit)
        end
    end
end

-- 拦截 CastSpell (按法术书槽位)，类似处理
function GoubayuHeal.CastSpell(id, book)
    local spell, rank = GetSpellName(id, book)
    -- GetSpellName 第二返回值是本地化串（如"级别 2"/"Rank 2"），需提取数字；
    -- Spells 的等级键是数字，字符串键恒 nil（此钩子此前从未生效过）
    rank = tonumber(string.match(rank or "", "%d+"))
    if (GoubayuHeal.Spells[spell] and GoubayuHeal.Spells[spell][rank]
        and not (GoubayuHeal.i_am_healing and GoubayuHeal.healing[GoubayuHeal.i_am_healing]
            and GoubayuHeal.healing[GoubayuHeal.i_am_healing][GoubayuHeal.my_name])) then
        -- 同 CastSpellByName：先清旧 Target 残留（槽位路径此前从不触碰 Target）
        -- by 武藤纯子酱 2026.9.4
        GoubayuHeal.spell_awaiting_target_Target = nil
        GoubayuHeal.spell_awaiting_target_Spell = spell
        GoubayuHeal.spell_awaiting_target_Rank = rank
    end

    -- 庇佑打标：经法术书槽位施放"愈合"时同样记录（当前友方目标，否则自施）
    if spell == GoubayuHeal.Regrowth and GoubayuHeal.MarkRegrowthCast then
        local tUnit = (UnitExists("target") and UnitIsFriend("player", "target"))
            and "target" or "player"
        GoubayuHeal.MarkRegrowthCast(tUnit)
    end
end

-- 施法取消时清理等待目标
function GoubayuHeal.SpellStopCasting()
    if GoubayuHeal.spell_awaiting_target_Spell then
        GoubayuHeal.clean_spell_awaiting_target()
    end
end

-- 停止选择目标时清理等待目标
function GoubayuHeal.SpellStopTargeting()
    if GoubayuHeal.spell_awaiting_target_Spell then
        GoubayuHeal.clean_spell_awaiting_target()
    end
end