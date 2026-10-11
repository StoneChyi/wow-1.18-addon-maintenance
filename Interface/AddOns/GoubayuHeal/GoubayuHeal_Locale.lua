-- ============================================================
-- 文件名: GoubayuHeal_Locale.lua
-- 功能: 本地化定义（zhCN / 其他语言）
--       包含职业名、法术名、增益/减益名、UI文本、帮助信息等
-- ============================================================

local zhCN = (GetLocale() == "zhCN")

-- ============================================================
-- 阵营名
-- ============================================================
if zhCN then
    GoubayuHeal.Alliance = "联盟"
    GoubayuHeal.Horde = "部落"
else
    GoubayuHeal.Alliance = "Alliance"
    GoubayuHeal.Horde = "Horde"
end

-- ============================================================
-- 职业名
-- ============================================================
if zhCN then
    GoubayuHeal.Druid = "德鲁伊"
    GoubayuHeal.Hunter = "猎人"
    GoubayuHeal.Mage = "法师"
    GoubayuHeal.Paladin = "圣骑士"
    GoubayuHeal.Priest = "牧师"
    GoubayuHeal.Rogue = "盗贼"
    GoubayuHeal.Shaman = "萨满祭司"
    GoubayuHeal.Warlock = "术士"
    GoubayuHeal.Warrior = "战士"
else
    GoubayuHeal.Druid = "Druid"
    GoubayuHeal.Hunter = "Hunter"
    GoubayuHeal.Mage = "Mage"
    GoubayuHeal.Paladin = "Paladin"
    GoubayuHeal.Priest = "Priest"
    GoubayuHeal.Rogue = "Rogue"
    GoubayuHeal.Shaman = "Shaman"
    GoubayuHeal.Warlock = "Warlock"
    GoubayuHeal.Warrior = "Warrior"
end

-- ============================================================
-- 小地图按钮提示
-- ============================================================
if zhCN then
    GoubayuHeal.minimap_tip = "左键点击显示/隐藏选项面板.\n右键点击打开/关闭驱散优先级窗口."
else
    GoubayuHeal.minimap_tip = "Left-click to show/hide the options panel.\nRight-click to toggle the dispel priority window."
end

-- ============================================================
-- 法术、增益、减益名称（中文/英文）
-- ============================================================
if zhCN then
    GoubayuHeal.RANK = "等级"
    GoubayuHeal.Amplify_magic = "魔法增效"
    GoubayuHeal.Banish = "放逐"
    GoubayuHeal.Blessing_of_light = "光明祝福"
    GoubayuHeal.Blessing_of_protection = "保护之手"
    GoubayuHeal.Chain_heal = "治疗链"
    GoubayuHeal.Clearcasting = "清晰预兆"
    GoubayuHeal.Crystal_restore = "水晶恢复"
    GoubayuHeal.HotA = "远古治疗"
    GoubayuHeal.Dampen_magic = "魔法抑制"
    GoubayuHeal.Deep_slumber = "深度沉睡"
    GoubayuHeal.Divine_favor = "神恩术"
    GoubayuHeal.Divine_intervention = "神圣干涉"
    GoubayuHeal.Divine_protection = "圣佑术"
    GoubayuHeal.Divine_shield = "圣盾术"
    GoubayuHeal.First_aid = "急救"
    GoubayuHeal.Flash_heal = "快速治疗"
    GoubayuHeal.Flash_of_light = "圣光闪现"
    GoubayuHeal.Forbearance = "自律"
    GoubayuHeal.Greater_blessing_of_light = "强效光明祝福"
    GoubayuHeal.Greater_heal = "强效治疗术"
    GoubayuHeal.Rapid_healing = "疾速治疗"
    GoubayuHeal.Heal = "治疗术"
    GoubayuHeal.PriestHeal = GoubayuHeal.Heal   -- 牧师治疗术的别名
    GoubayuHeal.Healing_touch = "治疗之触"
    GoubayuHeal.Healing_wave = "治疗波"
    GoubayuHeal.Healing_way = "治疗之道"
    GoubayuHeal.Holy_light = "圣光术"
    GoubayuHeal.Holy_nova = "神圣新星"
    GoubayuHeal.Holy_shock = "神圣震击"
    GoubayuHeal.Ice_barrier = "寒冰护体"
    GoubayuHeal.Inner_focus = "心灵专注"
    GoubayuHeal.Inner_fire = "心灵之火"
    GoubayuHeal.Desperate_prayer = "绝望祷言"
    GoubayuHeal.Lay_on_hands = "圣疗术"
    GoubayuHeal.Lesser_heal = "次级治疗术"
    GoubayuHeal.Lesser_healing_wave = "次级治疗波"
    GoubayuHeal.Lightwell = "光明之泉"
    GoubayuHeal.Mortal_strike = "致死打击"
    GoubayuHeal.Natures_grace = "自然之赐"
    GoubayuHeal.Natures_swiftness = "自然迅捷"
    GoubayuHeal.Shaman_Ancestral_swiftness = "先祖迅捷"
    GoubayuHeal.Phase_shift = "相位变换"
    GoubayuHeal.Power_infusion = "能量灌注"
    GoubayuHeal.Power_word_shield = "真言术：盾"
    GoubayuHeal.Fear_ward = "防护恐惧结界" -- 牧师：团队框架右侧优先级维持
    GoubayuHeal.Stormstrike = "风暴打击" -- 萨满：判断是否增强天赋（风系图腾自动切换用）
    GoubayuHeal.Prayer_of_healing = "治疗祷言"
    GoubayuHeal.Recently_bandaged = "新近包扎"
    GoubayuHeal.Regrowth = "愈合"
    GoubayuHeal.Rejuvenation = "回春术"
    GoubayuHeal.Tree_of_life = "生命之树形态"
    GoubayuHeal.Tree_of_life_short = "生命之树"
    GoubayuHeal.Renew = "恢复"
    GoubayuHeal.Spirit_tap = "精神分流"
    GoubayuHeal.Swiftmend = "迅捷治愈"
    GoubayuHeal.Tranquility = "宁静"
    GoubayuHeal.Unstable_power = "不稳定的力量"
    GoubayuHeal.Weakened_soul = "虚弱灵魂"
    GoubayuHeal.Resurrection = "复活术"
    GoubayuHeal.Redemption = "救赎"
    GoubayuHeal.Rebirth = "复生"
    GoubayuHeal.Ancestral_Spirit = "先祖之魂"
    GoubayuHeal.Holy_Strike = "神圣打击"
    GoubayuHeal.Crusader_strike = "十字军打击"
    GoubayuHeal.Holy_judgement = "神圣制裁"
    GoubayuHeal.Judgment = "审判"
    GoubayuHeal.Judgment_of_Wisdom = "智慧审判"
    GoubayuHeal.Seal_of_Wisdom = "智慧圣印"
    GoubayuHeal.Judgment_of_Crusader = "十字军审判"
    GoubayuHeal.Judgment_of_Light = "光明审判"
    GoubayuHeal.Seal_of_Crusader = "十字军圣印"
    GoubayuHeal.Seal_of_Light = "光明圣印"
    GoubayuHeal.Consecration = "奉献"
    GoubayuHeal.Lay_on_hands = "圣疗术"
    GoubayuHeal.Curse_ot_deadwood = "死木诅咒"
    GoubayuHeal.Gehennas_curse = "基赫纳斯的诅咒"
else
    GoubayuHeal.RANK = "Rank"
    GoubayuHeal.Amplify_magic = "Amplify Magic"
    GoubayuHeal.Banish = "Banish"
    GoubayuHeal.Blessing_of_light = "Blessing of Light"
    GoubayuHeal.Blessing_of_protection = "Hand of Protection"
    GoubayuHeal.Chain_heal = "Chain Heal"
    GoubayuHeal.Clearcasting = "Clearcasting"
    GoubayuHeal.Crystal_restore = "Crystal Restore"
    GoubayuHeal.HotA = "Healing of the Ages"
    GoubayuHeal.Dampen_magic = "Dampen Magic"
    GoubayuHeal.Deep_slumber = "Deep Slumber"
    GoubayuHeal.Divine_favor = "Divine Favor"
    GoubayuHeal.Divine_intervention = "Divine Intervention"
    GoubayuHeal.Divine_protection = "Divine Protection"
    GoubayuHeal.Divine_shield = "Divine Shield"
    GoubayuHeal.First_aid = "First Aid"
    GoubayuHeal.Flash_heal = "Flash Heal"
    GoubayuHeal.Flash_of_light = "Flash of Light"
    GoubayuHeal.Forbearance = "Forbearance"
    GoubayuHeal.Greater_blessing_of_light = "Greater Blessing of Light"
    GoubayuHeal.Greater_heal = "Greater Heal"
    GoubayuHeal.Rapid_healing = "Rapid Healing"
    GoubayuHeal.Heal = "Heal"
    GoubayuHeal.PriestHeal = GoubayuHeal.Heal
    GoubayuHeal.Healing_touch = "Healing Touch"
    GoubayuHeal.Healing_wave = "Healing Wave"
    GoubayuHeal.Healing_way = "Healing Way"
    GoubayuHeal.Holy_light = "Holy Light"
    GoubayuHeal.Holy_nova = "Holy Nova"
    GoubayuHeal.Holy_shock = "Holy Shock"
    GoubayuHeal.Ice_barrier = "Ice Barrier"
    GoubayuHeal.Inner_focus = "Inner Focus"
    GoubayuHeal.Inner_fire = "Inner Fire"
    GoubayuHeal.Desperate_prayer = "Desperate Prayer"
    GoubayuHeal.Lay_on_hands = "Lay on Hands"
    GoubayuHeal.Lesser_heal = "Lesser Heal"
    GoubayuHeal.Lesser_healing_wave = "Lesser Healing Wave"
    GoubayuHeal.Lightwell = "Lightwell"
    GoubayuHeal.Mortal_strike = "Mortal Strike"
    GoubayuHeal.Natures_grace = "Nature's Grace"
    GoubayuHeal.Natures_swiftness = "Nature's Swiftness"
    GoubayuHeal.Shaman_Ancestral_swiftness = "Ancestral Swiftness"
    GoubayuHeal.Phase_shift = "Phase Shift"
    GoubayuHeal.Power_infusion = "Power Infusion"
    GoubayuHeal.Power_word_shield = "Power Word: Shield"
GoubayuHeal.Fear_ward = "Fear Ward" -- Priest: raid-frame right-side priority maintenance
GoubayuHeal.Stormstrike = "Stormstrike" -- Shaman: enhancement check for the air-totem auto switch
    GoubayuHeal.Prayer_of_healing = "Prayer of Healing"
    GoubayuHeal.Recently_bandaged = "Recently bandaged"
    GoubayuHeal.Regrowth = "Regrowth"
    GoubayuHeal.Rejuvenation = "Rejuvenation"
    GoubayuHeal.Tree_of_life = "Tree of Life Form"
    GoubayuHeal.Tree_of_life_short = "Tree of Life"
    GoubayuHeal.Renew = "Renew"
    GoubayuHeal.Spirit_tap = "Spirit Tap"
    GoubayuHeal.Swiftmend = "Swiftmend"
    GoubayuHeal.Tranquility = "Tranquility"
    GoubayuHeal.Unstable_power = "Unstable Power"
    GoubayuHeal.Weakened_soul = "Weakened Soul"
    GoubayuHeal.Resurrection = "Resurrection"
    GoubayuHeal.Redemption = "Redemption"
    GoubayuHeal.Rebirth = "Rebirth"
    GoubayuHeal.Ancestral_Spirit = "Ancestral Spirit"
    GoubayuHeal.Holy_Strike = "Holy Strike"
    GoubayuHeal.Crusader_strike = "Crusader Strike"
    GoubayuHeal.Holy_judgement = "Holy Judgement"
    GoubayuHeal.Judgment = "Judgement"
    GoubayuHeal.Judgment_of_Wisdom = "Judgement of Wisdom"
    GoubayuHeal.Seal_of_Wisdom = "Seal of Wisdom"
    GoubayuHeal.Judgment_of_Crusader = "Judgement of Crusader"
    GoubayuHeal.Judgment_of_Light = "Judgement of Light"
    GoubayuHeal.Seal_of_Crusader = "Seal of Crusader"
    GoubayuHeal.Seal_of_Light = "Seal of Light"
    GoubayuHeal.Consecration = "Consecration"
    GoubayuHeal.Lay_on_hands = "Lay on Hands"
    GoubayuHeal.Curse_ot_deadwood = "Curse of the Deadwood"
    GoubayuHeal.Gehennas_curse = "Gehennas' Curse"
end

-- ============================================================
-- 装备治疗加成 tooltip 匹配文本
-- ============================================================
if zhCN then
    GoubayuHeal.item_heal_bonus_text = {
        "提高法术所造成的治疗效果，最多(%d+%.?%d*)点",
        "提高神圣法术和效果所造成的伤害，最多(%d+%.?%d*)点",
        "提高所有法术和魔法效果所造成的伤害和治疗效果，最多(%d+%.?%d*)点",
        "%+(%d+%.?%d*) 治疗法术",
        "治疗法术 %+(%d+%.?%d*)",
        "治疗 %+(%d+%.?%d*)点",
        "伤害法术 %+(%d+%.?%d*)",
        "提高法术伤害 %+(%d+%.?%d*)",
        "提高治疗效果 %+(%d+%.?%d*)",
        "治疗%+(%d+%.?%d*)点",
        "法术治疗和伤害 %+(%d+%.?%d*)",
        "治疗效果提高最多(%d+%.?%d*)",
        "使治疗法术和效果所回复的生命值提高(%d+%.?%d*)点"
    }
else
    GoubayuHeal.item_heal_bonus_text = {
        "Increases healing done by spells and effects by up to (%d+%.?%d*)%.",
        "Increases damage and healing done by magical spells and effects by up to (%d+%.?%d*)%.",
        "%+(%d+%.?%d*) Healing Spells",
        "Healing Spells %+(%d+%.?%d*)"
    }
end

-- ============================================================
-- BCS同款算法：装备纯治疗强度模式（不计入伤害加成）
-- ============================================================
if zhCN then
    GoubayuHeal.self_heal_power_text = {
        "提高法术所造成的治疗效果，最多(%d+%.?%d*)点",
        "%+(%d+%.?%d*) 治疗法术",
        "治疗法术 %+(%d+%.?%d*)",
        "治疗 %+(%d+%.?%d*)点",
        "提高治疗效果 %+(%d+%.?%d*)",
        "治疗%+(%d+%.?%d*)点",
        "使治疗法术和效果所回复的生命值提高(%d+%.?%d*)点",
        "治疗效果提高最多(%d+%.?%d*)",
        "治疗效果提高(%d+%.?%d*)"
    }
else
    GoubayuHeal.self_heal_power_text = {
        "Increases healing done by spells and effects by up to (%d+%.?%d*)%.",
        "%+(%d+%.?%d*) Healing Spells",
        "Healing Spells %+(%d+%.?%d*)",
        "Increases healing (%d+%.?%d*)%."
    }
end

-- ============================================================
-- BCS同款算法：通用法术强度模式（法术伤害和治疗）
-- ============================================================
if zhCN then
    GoubayuHeal.self_spell_power_text = {
        "提高所有法术和魔法效果所造成的伤害和治疗效果，最多(%d+%.?%d*)点",
        "%+(%d+%.?%d*) 法术伤害和治疗",
        "%+(%d+%.?%d*) 伤害和治疗法术"
    }
else
    GoubayuHeal.self_spell_power_text = {
        "Increases damage and healing done by magical spells and effects by up to (%d+%.?%d*)%.",
        "%+(%d+%.?%d*) Spell Damage and Healing",
        "%+(%d+%.?%d*) Damage and Healing Spells"
    }
end

-- ============================================================
-- 按键绑定文本
-- ============================================================
if zhCN then
    BINDING_HEADER_GoubayuHeal = "Heart治疗助手"
    BINDING_HEADER_GoubayuHealCLICKS = "Heart单位治疗"
    BINDING_NAME_GoubayuHeal_CUSTOM_1 = "自定义1"
    BINDING_NAME_GoubayuHeal_CUSTOM_2 = "自定义2"
    BINDING_NAME_GoubayuHeal_PLAYER_1 = "玩家自定义1"
    BINDING_NAME_GoubayuHeal_PLAYER_2 = "玩家自定义2"
    BINDING_NAME_GoubayuHeal_P1_1 = "小队1自定义1"
    BINDING_NAME_GoubayuHeal_P1_2 = "小队1自定义2"
    BINDING_NAME_GoubayuHeal_P2_1 = "小队2自定义1"
    BINDING_NAME_GoubayuHeal_P2_2 = "小队2自定义2"
    BINDING_NAME_GoubayuHeal_P3_1 = "小队3自定义1"
    BINDING_NAME_GoubayuHeal_P3_2 = "小队3自定义2"
    BINDING_NAME_GoubayuHeal_P4_1 = "小队4自定义1"
    BINDING_NAME_GoubayuHeal_P4_2 = "小队4自定义2"
    BINDING_NAME_GoubayuHeal_MT1_1 = "主坦克1自定义1"
    BINDING_NAME_GoubayuHeal_MT1_2 = "主坦克1自定义2"
    BINDING_NAME_GoubayuHeal_MT2_1 = "主坦克2自定义1"
    BINDING_NAME_GoubayuHeal_MT2_2 = "主坦克2自定义2"
    BINDING_NAME_GoubayuHeal_MT3_1 = "主坦克3自定义1"
    BINDING_NAME_GoubayuHeal_MT3_2 = "主坦克3自定义2"
    BINDING_NAME_GoubayuHeal_MT4_1 = "主坦克4自定义1"
    BINDING_NAME_GoubayuHeal_MT4_2 = "主坦克4自定义2"
    BINDING_NAME_GoubayuHeal_MT5_1 = "主坦克5自定义1"
    BINDING_NAME_GoubayuHeal_MT5_2 = "主坦克5自定义2"
    BINDING_NAME_GoubayuHeal_MT6_1 = "主坦克6自定义1"
    BINDING_NAME_GoubayuHeal_MT6_2 = "主坦克6自定义2"
    BINDING_NAME_GoubayuHeal_MT7_1 = "主坦克7自定义1"
    BINDING_NAME_GoubayuHeal_MT7_2 = "主坦克7自定义2"
    BINDING_NAME_GoubayuHeal_MT8_1 = "主坦克8自定义1"
    BINDING_NAME_GoubayuHeal_MT8_2 = "主坦克8自定义2"
    BINDING_NAME_GoubayuHeal_MT9_1 = "主坦克9自定义1"
    BINDING_NAME_GoubayuHeal_MT9_2 = "主坦克9自定义2"
    BINDING_NAME_GoubayuHeal_MT10_1 = "主坦克10自定义1"
    BINDING_NAME_GoubayuHeal_MT10_2 = "主坦克10自定义2"
else
    BINDING_HEADER_GoubayuHeal = "GoubayuHeal"
    BINDING_HEADER_GoubayuHealCLICKS = "GoubayuHeal Unit Healing"
    BINDING_NAME_GoubayuHeal_CUSTOM_1 = "Custom 1"
    BINDING_NAME_GoubayuHeal_CUSTOM_2 = "Custom 2"
    BINDING_NAME_GoubayuHeal_PLAYER_1 = "Player Custom 1"
    BINDING_NAME_GoubayuHeal_PLAYER_2 = "Player Custom 2"
    BINDING_NAME_GoubayuHeal_P1_1 = "Party1 Custom 1"
    BINDING_NAME_GoubayuHeal_P1_2 = "Party1 Custom 2"
    BINDING_NAME_GoubayuHeal_P2_1 = "Party2 Custom 1"
    BINDING_NAME_GoubayuHeal_P2_2 = "Party2 Custom 2"
    BINDING_NAME_GoubayuHeal_P3_1 = "Party3 Custom 1"
    BINDING_NAME_GoubayuHeal_P3_2 = "Party3 Custom 2"
    BINDING_NAME_GoubayuHeal_P4_1 = "Party4 Custom 1"
    BINDING_NAME_GoubayuHeal_P4_2 = "Party4 Custom 2"
    BINDING_NAME_GoubayuHeal_MT1_1 = "MainTank1 Custom 1"
    BINDING_NAME_GoubayuHeal_MT1_2 = "MainTank1 Custom 2"
    BINDING_NAME_GoubayuHeal_MT2_1 = "MainTank2 Custom 1"
    BINDING_NAME_GoubayuHeal_MT2_2 = "MainTank2 Custom 2"
    BINDING_NAME_GoubayuHeal_MT3_1 = "MainTank3 Custom 1"
    BINDING_NAME_GoubayuHeal_MT3_2 = "MainTank3 Custom 2"
    BINDING_NAME_GoubayuHeal_MT4_1 = "MainTank4 Custom 1"
    BINDING_NAME_GoubayuHeal_MT4_2 = "MainTank4 Custom 2"
    BINDING_NAME_GoubayuHeal_MT5_1 = "MainTank5 Custom 1"
    BINDING_NAME_GoubayuHeal_MT5_2 = "MainTank5 Custom 2"
    BINDING_NAME_GoubayuHeal_MT6_1 = "MainTank6 Custom 1"
    BINDING_NAME_GoubayuHeal_MT6_2 = "MainTank6 Custom 2"
    BINDING_NAME_GoubayuHeal_MT7_1 = "MainTank7 Custom 1"
    BINDING_NAME_GoubayuHeal_MT7_2 = "MainTank7 Custom 2"
    BINDING_NAME_GoubayuHeal_MT8_1 = "MainTank8 Custom 1"
    BINDING_NAME_GoubayuHeal_MT8_2 = "MainTank8 Custom 2"
    BINDING_NAME_GoubayuHeal_MT9_1 = "MainTank9 Custom 1"
    BINDING_NAME_GoubayuHeal_MT9_2 = "MainTank9 Custom 2"
    BINDING_NAME_GoubayuHeal_MT10_1 = "MainTank10 Custom 1"
    BINDING_NAME_GoubayuHeal_MT10_2 = "MainTank10 Custom 2"
end

-- ============================================================
-- UI标签页标题
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_tab_title = {"组合", "设置", "优先", "团队", "HOT", "复活", "驱散", "高级", "使用说明"}
else
    GoubayuHeal.GUI_tab_title = {"Classes", "Settings", "Priorities", "Raid", "HOT", "Rez", "Dispel", "Adv.", "Help"}
end

-- ============================================================
-- HOT维持标签页：HOT短名
-- ============================================================
GoubayuHeal.hot_short_name = {
    [GoubayuHeal.Rejuvenation] = "回春",
    [GoubayuHeal.Regrowth] = "愈合",
    [GoubayuHeal.Renew] = "恢复",
    [GoubayuHeal.Power_word_shield] = "盾",
}
if not zhCN then
    GoubayuHeal.hot_short_name = {
        [GoubayuHeal.Rejuvenation] = "Rejuv",
        [GoubayuHeal.Regrowth] = "Regrowth",
        [GoubayuHeal.Renew] = "Renew",
        [GoubayuHeal.Power_word_shield] = "PW:S",
    }
end
-- ============================================================
-- 自定义职业组合UI文本
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_new = "新建"
    GoubayuHeal.GUI_delete = "删除"
    GoubayuHeal.GUI_rank = "等级"
    GoubayuHeal.GUI_new_class = "新组合的名称"
    GoubayuHeal.GUI_new_profile = "档案名称"
else
    GoubayuHeal.GUI_new = "New"
    GoubayuHeal.GUI_delete = "Delete"
    GoubayuHeal.GUI_rank = "Rank"
    GoubayuHeal.GUI_new_class = "Name of new class"
    GoubayuHeal.GUI_new_profile = "Profile Name"
end

-- ============================================================
-- 快捷键选项
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_keys = {"关闭", "无", "Alt", "Ctrl", "Shift", "Alt + Ctrl", "Alt + Shift", "Ctrl + Shift", "全部"}
else
    GoubayuHeal.GUI_keys = {"Off", "None", "Alt", "Control", "Shift", "Alt + Control", "Alt + Shift", "Control + Shift", "All"}
end

-- ============================================================
-- 优先级设置文本
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_player_priority = "玩家优先级"
    GoubayuHeal.GUI_party_priority = "队友优先级"
    GoubayuHeal.GUI_raid_priority = "团队优先级"
    GoubayuHeal.GUI_pet_priority = "宠物优先级"
    GoubayuHeal.GUI_MT_priority = "MT优先级"
    GoubayuHeal.GUI_bop_priority = "保护 优先级降低"
    GoubayuHeal.GUI_pws_priority = "盾 优先级降低"
    GoubayuHeal.GUI_rb_priority = "绷带 优先级提升"
    GoubayuHeal.GUI_ws_priority = "灵魂虚弱 优先级提升"
    GoubayuHeal.GUI_ms_priority = "致死 优先级提升"
    GoubayuHeal.GUI_druid_priority = GoubayuHeal.Druid .. " 优先级"
    GoubayuHeal.GUI_hunter_priority = GoubayuHeal.Hunter .. " 优先级"
    GoubayuHeal.GUI_mage_priority = GoubayuHeal.Mage .. " 优先级"
    GoubayuHeal.GUI_paladin_priority = GoubayuHeal.Paladin .. " 优先级"
    GoubayuHeal.GUI_priest_priority = GoubayuHeal.Priest .. " 优先级"
    GoubayuHeal.GUI_rogue_priority = GoubayuHeal.Rogue .. " 优先级"
    GoubayuHeal.GUI_shaman_priority = GoubayuHeal.Shaman .. " 优先级"
    GoubayuHeal.GUI_warlock_priority = GoubayuHeal.Warlock .. " 优先级"
    GoubayuHeal.GUI_warrior_priority = GoubayuHeal.Warrior .. " 优先级"
else
    GoubayuHeal.GUI_player_priority = "Player priority"
    GoubayuHeal.GUI_party_priority = "Party priority"
    GoubayuHeal.GUI_raid_priority = "Raid priority"
    GoubayuHeal.GUI_pet_priority = "Pet priority"
    GoubayuHeal.GUI_MT_priority = "MT priority"
    GoubayuHeal.GUI_bop_priority = "BoP pri. decrease"
    GoubayuHeal.GUI_pws_priority = "PWS pri. decrease"
    GoubayuHeal.GUI_rb_priority = "RB priority increase"
    GoubayuHeal.GUI_ws_priority = "WS priority increase"
    GoubayuHeal.GUI_ms_priority = "MS priority increase"
    GoubayuHeal.GUI_druid_priority = GoubayuHeal.Druid .. " priority"
    GoubayuHeal.GUI_hunter_priority = GoubayuHeal.Hunter .. " priority"
    GoubayuHeal.GUI_mage_priority = GoubayuHeal.Mage .. " priority"
    GoubayuHeal.GUI_paladin_priority = GoubayuHeal.Paladin .. " priority"
    GoubayuHeal.GUI_priest_priority = GoubayuHeal.Priest .. " priority"
    GoubayuHeal.GUI_rogue_priority = GoubayuHeal.Rogue .. " priority"
    GoubayuHeal.GUI_shaman_priority = GoubayuHeal.Shaman .. " priority"
    GoubayuHeal.GUI_warlock_priority = GoubayuHeal.Warlock .. " priority"
    GoubayuHeal.GUI_warrior_priority = GoubayuHeal.Warrior .. " priority"
end

-- ============================================================
-- 团队/HOT/驱散设置文本
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_refined_priority = "精细化优先级"
    GoubayuHeal.GUI_reset_priority = "重置50%"
    GoubayuHeal.GUI_invert_priority = "反向"
    GoubayuHeal.GUI_clear_roles = "清空坦克标记"
    GoubayuHeal.GUI_hot_enabled = "启用HOT维持"
    GoubayuHeal.GUI_hot_clear = "清空"
    GoubayuHeal.GUI_dispel_enabled = "启动一键驱散"
    GoubayuHeal.GUI_dispel_queue = "将驱散加入治疗队列"
    GoubayuHeal.GUI_dispel_interrupt = "允许断条驱散"
    GoubayuHeal.GUI_dispel_hidden = "隐藏驱散窗口"
    GoubayuHeal.GUI_dispel_type = {
        Magic = "驱散魔法",
        Disease = "驱散疾病",
        Poison = "驱散中毒",
        Curse = "驱散诅咒",
        Snare = "驱散移动限制"
    }
else
    GoubayuHeal.GUI_refined_priority = "Refined priority"
    GoubayuHeal.GUI_reset_priority = "Reset 50%"
    GoubayuHeal.GUI_invert_priority = "Invert"
    GoubayuHeal.GUI_clear_roles = "Clear tank marks"
    GoubayuHeal.GUI_hot_enabled = "Enable HOT maintain"
    GoubayuHeal.GUI_hot_clear = "Clear"
    GoubayuHeal.GUI_dispel_enabled = "Enable one-key dispel"
    GoubayuHeal.GUI_dispel_queue = "Add dispel to heal queue"
    GoubayuHeal.GUI_dispel_interrupt = "Allow interrupt-cast dispel"
    GoubayuHeal.GUI_dispel_hidden = "Hide dispel window"
    GoubayuHeal.GUI_dispel_type = {
        Magic = "Dispel Magic",
        Disease = "Dispel Disease",
        Poison = "Dispel Poison",
        Curse = "Dispel Curse",
        Snare = "Dispel Movement"
    }
end

-- ============================================================
-- 常规设置文本
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_shapeshifted_druids = "变形小D当作贼/战士"
    GoubayuHeal.GUI_scan_cache = "周期缓存全团血量"
    GoubayuHeal.GUI_anti_starvation = "防饥饿打乱"
    GoubayuHeal.GUI_np_queue_timeout = "Nampower队列超时"
    GoubayuHeal.GUI_safe_cancel = "过量取消治疗"
    GoubayuHeal.GUI_always_tank_target = "强制满级法术"
    GoubayuHeal.GUI_scale_spells = "自动法术等级"
    GoubayuHeal.GUI_scale_hots = "自动恢复类法术等级"
    GoubayuHeal.GUI_hot_cancel = "HoT门槛"
    GoubayuHeal.GUI_allow_regrowth_overwrite = "允许覆盖愈合"
    GoubayuHeal.GUI_hot_value = "HoT放大"
    GoubayuHeal.GUI_hot_value_battle = "HoT放大-战斗"
    GoubayuHeal.GUI_max_overheal = "最大过量治疗"
    GoubayuHeal.GUI_min_heal_threshold = "治疗门槛"
    GoubayuHeal.GUI_heal_power = "治疗力度"
    GoubayuHeal.GUI_update_time = "刷新时间"
    GoubayuHeal.GUI_heal_strategy = "治疗策略"
    GoubayuHeal.GUI_heal_strategies = {"最小生命", "最小百分比生命", "最多失血", "绝对失血缺口"}
    GoubayuHeal.GUI_heal_charmed = "治疗心控单位"
    GoubayuHeal.GUI_heal_count = "竞争人数限制"
    GoubayuHeal.GUI_Im_the_fastest = "不允许别人比我更快"
else
    GoubayuHeal.GUI_shapeshifted_druids = "Treat shapeshifted druids as rogues/warriors"
    GoubayuHeal.GUI_scan_cache = "Periodic raid health cache"
    GoubayuHeal.GUI_anti_starvation = "Anti-starvation shuffle"
    GoubayuHeal.GUI_np_queue_timeout = "Nampower queue timeout"
    GoubayuHeal.GUI_safe_cancel = "Safe cancel"
    GoubayuHeal.GUI_always_tank_target = "\"Heal Max\" targets"
    GoubayuHeal.GUI_scale_spells = "Scale spells"
    GoubayuHeal.GUI_scale_hots = "Scale HOTs"
    GoubayuHeal.GUI_hot_cancel = "HoT health threshold"
    GoubayuHeal.GUI_allow_regrowth_overwrite = "Allow Regrowth to overwrite"
    GoubayuHeal.GUI_hot_value = "+HoT value"
    GoubayuHeal.GUI_hot_value_battle = "+HoT value combat"
    GoubayuHeal.GUI_max_overheal = "Max overheal"
    GoubayuHeal.GUI_min_heal_threshold = "Min health threshold"
    GoubayuHeal.GUI_heal_power = "Heal power"
    GoubayuHeal.GUI_update_time = "Max update time"
    GoubayuHeal.GUI_heal_strategy = "Heal strategy"
    GoubayuHeal.GUI_heal_strategies = {"Least HP", "Least % life", "Most HP missing", "Max raw deficit"}
    GoubayuHeal.GUI_heal_charmed = "Heal charmed units"
    GoubayuHeal.GUI_heal_count = "heal count"
    GoubayuHeal.GUI_Im_the_fastest = "I'm the fastest"
end

-- ============================================================
-- 高级设置文本
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_CastTime_Debuff = "施法时间补偿"
    GoubayuHeal.GUI_MTCastTime_Debuff = "MT施法时间补偿"
else
    GoubayuHeal.GUI_CastTime_Debuff = "CastTime DeBuff"
    GoubayuHeal.GUI_MTCastTime_Debuff = "MT CastTime DeBuff"
end

-- ============================================================
-- HOT文本正则（用于解析HOT描述）
-- ============================================================
GoubayuHeal.hot_text = {"Interval", "Heal"}

-- ============================================================
-- 详细设置提示（鼠标悬浮显示）
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_desc = {
        -- 设置标签页 - 左栏滑块
        ["HoT门槛"] = "目标身上已有持续治疗效果（恢复/回春等）时：仅当目标血量低于此百分比且本次将要施放的HOT等级高于目标已有等级时，才允许用高级HOT覆盖低级HOT；同级或更低等级、或血量未低于门槛时均不覆盖。值越低越保守。0% = 有HOT就绝不覆盖（需Nampower光环数据判断等级）。",
        ["HoT放大"] = "脱战状态下持续治疗法术（恢复/回春）的智能缩放倍率。100% = 根据目标缺口自动选择等级；0% = 一律使用最低等级；最高可设到 400% = 一律使用最高等级。",
        ["HoT放大-战斗"] = "战斗状态下持续治疗法术的智能缩放倍率。通常设为低于脱战值，以节省法力用于即时治疗。100% = 与脱战相同。",
        ["最大过量治疗"] = "允许的最大过量治疗比例。安全取消开启时，如果预估过量超过此阈值，正在读条的治疗法术将被自动取消。0% = 不允许任何过量，100% = 允许全部过量。",
        ["治疗门槛"] = "目标血量低于此百分比时才施放治疗。100% 表示只治疗非满血目标；70% 表示只治疗血量低于 70% 的目标，可大幅节省法力。",
        ["治疗力度"] = "直接治疗法术的智能缩放力度。100% = 根据血量缺口自动选择等级；0% = 始终最低等级；200% = 始终最高等级。",
        ["刷新时间"] = "玩家数据（生命值、buff、debuff 等）的刷新间隔（秒）。值越大 CPU 占用越低但反应越慢。2.5 秒为默认推荐值。",
        ["治疗策略"] = "治疗优先级排序策略。1 = 最小生命值：绝对血量最低优先（适合坦克）；2 = 最小百分比：血量百分比最低优先（兼顾坦克和 DPS）；3 = 最多失血：绝对失血量最多优先（适合群体治疗）；4 = 绝对失血缺口：按最大生命-当前生命的绝对值降序，缺口越大越优先（适合优先治疗 T 等大血量目标）。",
        -- 设置标签页 - 右栏复选框
        ["治疗心控单位"] = "开启后会对被精神控制或魅惑的队友施放治疗（例如被暗影控制的牧师队友）。关闭则跳过被控制的队友。",
        ["竞争人数限制"] = "对同一目标同时治疗的其他治疗者数量上限。达到此值后跳过该目标，避免过度治疗。设为 10 则不限制。",
        ["不允许别人比我更快"] = "当检测到其他治疗者正在治疗同一目标且会比我先完成时，自动取消我的施法。适合需要精确协调的团队。",
        ["自动恢复类法术等级"] = "开启后，持续治疗法术（恢复、回春术）也会按目标缺口和HoT放大倍率进行智能缩放等级。关闭则固定使用方案中设定的等级。",
        ["自动法术等级"] = "开启后，蓝量不足以施放所选技能等级时，自动降到当前蓝量能施放的最高等级以节省法力；蓝量充足则正常施放。关闭则蓝量不足时直接不施放。技能等级本身的智能缩放由「治疗力度/HoT放大」和方案内每个技能的「缩放」开关控制，与此选项相互独立。",
        ["过量取消治疗"] = "开启后，正在读条的治疗法术如果预估过量超过最大过量阈值，将被自动取消。一级法术仅在目标满血时取消。",
        ["强制满级法术"] = "强制使用法术最高等级，忽略自动等级缩放。适合坦克血量危急需要快速抬血的场景。",
        ["变形小D当作贼/战士"] = "熊/猎豹形态的德鲁伊按战士/盗贼的优先级处理（独立能量条，主要需要物理治疗）。关闭则按德鲁伊正常优先级。",
        ["周期缓存全团血量"] = "战斗中且未施法时，每0.2秒自动缓存一次全团/小队的掉血数据。点击/gbyh治疗时，若距上次缓存不超过0.2秒，直接以缓存数据作为判定依据，不再现场扫描全团；超过0.2秒则现场扫描兜底。关闭则始终现场扫描。",
        ["防饥饿打乱"] = "开启后，治疗目标按优先级排序后再打乱，避免一直奶同一个最低血的目标，让团里其他掉血的人也有机会被治疗（适合多目标同时掉血的场景）。关闭则始终优先治疗优先级最高的目标。",
        ["Nampower队列超时"] = "Nampower环境下：技能入队后超过该时间（秒）仍未执行（如队列卡死/异常时间戳），会自动取消队列并重算下一个可施法技能，避免偶尔卡死。0.1-3秒可调。仅装Nampower时有效。",
        -- 优先级标签页 - 角色优先级
        ["玩家优先级"] = "你自己的治疗优先级权重。100% = 与 MT 相同优先级；0% = 不治疗自己。",
        ["队友优先级"] = "同小队队友的治疗优先级权重。100% = 最高优先。",
        ["团队优先级"] = "非同小队团队成员的治疗优先级权重。通常设为低于队友优先级。",
        ["宠物优先级"] = "宠物的治疗优先级权重。设为较低值避免优先治疗宠物。",
        ["MT优先级"] = "被指定为 MT 的玩家在基础优先级之上额外叠加的加成值。0% = MT 仅按基础优先级排列。",
        -- 优先级标签页 - Buff/Debuff 优先级
        ["保护 优先级降低"] = "有保护祝福的玩家优先级乘以此倍率。保护祝福使目标免疫物理攻击，可适当降低治疗优先级。100% = 不影响。",
        ["盾 优先级降低"] = "有真言术：盾的玩家优先级乘以此倍率。盾吸收了伤害后治疗价值降低。100% = 不影响。",
        ["绷带 优先级提升"] = "正在使用急救（绷带）的玩家的优先级额外加成。0% = 不加成。",
        ["灵魂虚弱 优先级提升"] = "有虚弱灵魂 debuff 的玩家优先级额外加成。虚弱灵魂使目标暂时无法被套盾。0% = 不加成。",
        ["致死 优先级提升"] = "受到致死打击 debuff 的玩家优先级额外加成。致死打击使治疗效果减半，这些目标更需紧急治疗。0% = 不加成。",
        -- 优先级标签页 - 职业优先级
        ["德鲁伊 优先级"] = "德鲁伊类成员的治疗优先级权重。值越高越优先治疗该职业。",
        ["猎人 优先级"] = "猎人类成员的治疗优先级权重。",
        ["法师 优先级"] = "法师类成员的治疗优先级权重。",
        ["圣骑士 优先级"] = "圣骑士类成员的治疗优先级权重。",
        ["牧师 优先级"] = "牧师类成员的治疗优先级权重。",
        ["盗贼 优先级"] = "盗贼类成员的治疗优先级权重。",
        ["萨满祭司 优先级"] = "萨满祭司类成员的治疗优先级权重。",
        ["术士 优先级"] = "术士类成员的治疗优先级权重。",
        ["战士 优先级"] = "战士类成员的治疗优先级权重。战士通常优先级最高。",
        -- 高级标签页
        ["施法时间补偿"] = "普通目标的施法时间补偿值（毫秒）。战斗中估算过量时额外扣除，用于补偿法术推后/被打断风险。0 ms = 不补偿。",
        ["MT施法时间补偿"] = "对 MT 的施法时间补偿值（毫秒）。通常设为比普通目标更高，因坦克治疗时 Boss 技能频繁打断。0 ms = 不补偿。",
    }
else
    GoubayuHeal.GUI_desc = {
        ["HoT health threshold"] = "When the target already has a HoT (Renew/Rejuvenation): it is only overwritten if target health is below this percentage AND the new HoT rank is HIGHER than the existing one (upgrade). Same or lower rank, or health above the threshold, is never overwritten. Lower = more conservative. 0% = never overwrite an existing HoT. (Rank detection requires Nampower.)",
        ["+HoT value"] = "Smart rank scaling multiplier for HoTs (Renew/Rejuvenation) while out of combat. 100% = auto based on deficit; 0% = always min rank; up to 400% = always max rank.",
        ["+HoT value combat"] = "Smart rank scaling multiplier for HoTs while in combat. Usually set lower than out-of-combat to save mana. 100% = same as out of combat.",
        ["Max overheal"] = "Maximum allowed overheal ratio. When safe cancel is enabled and predicted overheal exceeds this, the casting spell is cancelled. 0% = no overheal, 100% = all allowed.",
        ["Min health threshold"] = "Only heal targets below this health percentage. 100% = heal any non-full target; 70% = only heal below 70% HP to save mana.",
        ["Heal power"] = "Smart rank scaling power for direct heals. 100% = auto based on missing HP; 0% = always min rank; 200% = always max rank.",
        ["Max update time"] = "Player data refresh interval in seconds. Higher = less frequent updates, lower CPU. 2.5 s is the default recommended value.",
        ["Heal strategy"] = "Priority sorting: 1 = Least HP (lowest absolute HP, good for tanks); 2 = Least % (lowest HP%, balanced); 3 = Most Missing (most HP missing, good for group heals); 4 = Most Missing value (priority x missing HP, absolute deficit).",
        ["Heal charmed units"] = "Heal mind-controlled or charmed allies. Disabled = skip charmed units.",
        ["heal count"] = "Max other healers healing the same target. When exceeded, skip the target. 10 = effectively no limit.",
        ["I'm the fastest"] = "When another healer is casting on the same target and would finish first, auto-cancel your cast. Useful for coordinated raid healing.",
        ["Scale HOTs"] = "Smart rank scaling for HoTs (Renew, Rejuvenation) based on multiplier and target deficit. Disabled = use profile rank.",
        ["Scale spells"] = "When enabled, if mana is insufficient for the chosen spell rank, auto step down to the highest affordable rank to save mana; if mana is sufficient, cast normally. Disabled = no cast if mana is insufficient. (Smart rank scaling by HP deficit is controlled separately by Heal power / HoT value and the per-entry Scale toggle.)",
        ["Safe cancel"] = "Auto-cancel healing spells when predicted overheal exceeds Max Overheal. First-rank spells only cancel at full health.",
        ["\"Heal Max\" targets"] = "Force highest spell rank, ignoring auto scaling. Useful for burst healing or tank emergencies.",
        ["Treat shapeshifted druids as rogues/warriors"] = "Bear/Cat form Druids are prioritized like Rogues/Warriors (independent energy/rage bar; they mainly need physical healing). Disabled = normal Druid priority.",
        ["Periodic raid health cache"] = "While in combat and not casting, caches the whole raid/party health every 0.2s. When you trigger /gbyh within 0.2s of the last cache, the cached data is used as the decision basis instead of re-scanning the raid; older than 0.2s falls back to an on-demand scan. Disabled = always scan on demand.",
        ["Anti-starvation shuffle"] = "When enabled, after sorting heal targets by priority, the list is shuffled so the addon does not keep healing the same lowest-HP target; other wounded members also get a chance (good when many targets are hurt at once). Disabled = always heal the highest-priority target first.",
        ["Nampower queue timeout"] = "In Nampower mode: if a queued spell is not executed within this many seconds (e.g. stuck/abnormal queue timestamp), the queue is cancelled and the next castable spell is re-decided, avoiding occasional hangs. 0.1-3s. Only relevant with Nampower installed.",
        ["Player priority"] = "Your own healing priority weight. 100% = highest priority; 0% = do not heal self.",
        ["Party priority"] = "Party members healing priority weight. 100% = highest.",
        ["Raid priority"] = "Non-party raid members priority weight.",
        ["Pet priority"] = "Pet healing priority weight.",
        ["MT priority"] = "Extra priority bonus for the designated Main Tank (added on top of base priority). 0% = base priority only.",
        ["BoP pri. decrease"] = "Priority multiplied by this factor for players with Blessing of Protection. BoP makes target immune to physical attacks. 100% = no change.",
        ["PWS pri. decrease"] = "Priority multiplied by this factor for players with Power Word: Shield. Shield absorbs damage, reducing heal urgency. 100% = no change.",
        ["RB priority increase"] = "Extra priority added for players currently using First Aid (bandaging). 0% = no bonus.",
        ["WS priority increase"] = "Extra priority for players with Weakened Soul debuff (cannot receive shields, needs priority healing). 0% = no bonus.",
        ["MS priority increase"] = "Extra priority for players with Mortal Strike debuff (halves healing received, more urgent). 0% = no bonus.",
        ["Druid priority"] = "Druid class healing priority weight.",
        ["Hunter priority"] = "Hunter class healing priority weight.",
        ["Mage priority"] = "Mage class healing priority weight.",
        ["Paladin priority"] = "Paladin class healing priority weight.",
        ["Priest priority"] = "Priest class healing priority weight.",
        ["Rogue priority"] = "Rogue class healing priority weight.",
        ["Shaman priority"] = "Shaman class healing priority weight.",
        ["Warlock priority"] = "Warlock class healing priority weight.",
        ["Warrior priority"] = "Warrior class healing priority weight.",
        ["CastTime DeBuff"] = "Cast time compensation in ms for normal targets. Extra amount subtracted from estimated healing to account for pushback/interruption risk. 0 ms = no compensation.",
        ["MT CastTime DeBuff"] = "Cast time compensation in ms for Main Tank. Usually higher than normal targets due to frequent boss ability interrupts.",
    }
end

-- ============================================================
-- 使用说明分页文本
-- ============================================================
if zhCN then
    GoubayuHeal.GUI_help_lines = {
        "【页面说明】",
        "· 组合：新建/编辑治疗方案，为各血量档位设置法术与等级；可从法术库拖入技能、为条目挂接附件（如自然迅捷/先祖迅捷）。第二行只显示当前职业专属开关（萨满图腾/水盾、圣骑圣印/审判/打击），德鲁伊另有\"艾森娜\"滑块（调节目标有愈合/回春时的优先级加成，0=禁用）。",
        "· 组合：方案行\"方案独立配置\"开关可让各方案独立保存设置（设置/优先/团队/HOT/复活/驱散/高级），切换方案时设置自动跟随；关闭则所有方案共用一套设置。新建方案时可在\"复制方案\"下拉选择已有方案作为蓝本（含其设置），选择\"无\"则使用默认设置。",
        "· 组合：牧师可启用\"交替技能\"（祈祷之书，连续同技能时改用交替技能，不同技能交替才能省蓝；施法被打断/失败后优先重试原技能）、\"保持心灵之火\"（无buff时自动上）、\"绝望祷言\"（血量低于阈值时最高优先级断条施放）；萨满可启用\"链无弹跳转波\"；德鲁伊可启用\"保持生命之树形态\"；\"防饥饿打乱\"可避免总奶同一目标。",
        "· 组合：圣骑士\"近战奶\"仅在存在敌对目标且目标处于近战范围（5码/攻击距离）时打近战，内容为：保持智慧圣印→维持智慧审判→十字军打击，随后按方案档位治疗（神圣震击/圣光术/圣光闪现等作为方案技能生效，治疗对象优先级遵循方案的优先级设置）；无法近战时自动回退为原始治疗方案。",
        "· 组合：圣骑士\"圣盾术\"\"圣佑术\"滑块——自身血量低于各自阈值时最高优先级断条施放（仅对自己；需不在CD、无自律debuff）；0% = 关闭。两者与牧师\"绝望祷言\"滑块同类。",
        "· 组合：萨满图腾窗口的四个元素主按钮支持\"右键禁用\"——右键点击某个元素按钮即切换禁用/启用该元素的图腾（禁用时图标半透明红色），一键插图腾时跳过被禁用的元素，便于控蓝只插少量图腾。",
        "· 组合：自动治疗在预估下一个目标时会考虑当前在读治疗量——目标\"当前血量+在读治疗量\"已满则降低其优先级，让仍有缺口的目标优先，避免对快满目标重复治疗。",
        "· 组合：\"法术预估数据\"可编辑各法术的基础治疗值/法伤加成比例/放大系数，首次进入自动从技能描述缓存，重置后重新读取。",
        "· 设置：治疗门槛、最大过量、HoT缩放系数、刷新频率、治疗策略、Nampower队列超时等全局参数。",
        "· 优先：玩家/小队/团队/宠物/MT 及各职业的治疗优先级，以及增益/减益（保护祝福、真言盾、虚弱灵魂、致死等）的优先级。",
        "· 团队：设置团队成员职责（坦克/MT）、复活顺序、各成员的HoT维护等级。",
        "· HOT：各成员恢复/回春等HoT的自动维护等级与开关。",
        "· 复活：一键复活相关配置与优先级。喊话内容可用 $t 代表被复活目标的名字（Nampower下从施法目标GUID获取，非Nampower自动target到目标）。",
        "· 驱散：一键驱散开关、各驱散法术的优先级与队列。",
        "· 高级：高级选项（自动法术等级、强制最高等级、安全取消、隐藏方案等），以及\"导出配置/导入配置\"（生成 GBYH 开头的紧凑字符串，可保存分享并还原全部设置，含各方案独立设置）。",
        "· 驱散：一键驱散宏（/gbyh dispel 或绑定按键）自动净化最优目标；\"传染诅咒\"类中招者8码内有队友时暂缓驱散并喊话警告（5秒节流）；萨满自动优先用清毒/祛病图腾覆盖26码内目标。",
        "· 竞争检测（设置页）：\"竞争人数限制\"与\"不允许别人比我更快\"可同时开启、分别判定——前者按目标上其他治疗者读条数量跳过，后者按\"别人的治疗条会先落地\"跳过（瞬发不受限）；全部目标被覆盖时自动兜底治疗最大缺口，绝不观望。",
        "· 图腾：每个图腾独立计时CD与持续时间（0.1秒刷新精度，与图腾大师同）；CD跨重载持久化；覆盖人数只统计本小队存活在线成员（30码）。",
        "· 组合：圣骑士方案可配置\"圣疗术\"（无预估数值档位）——血量低于阈值时自动施放，恢复满血并清空自身法力，注意其长冷却。",
        "· 使用说明：本页。",
        "",
        "【使用方法】",
        "1. 打开设置界面：输入 /gbyh 或点击小地图按钮。",
        "2. 在\"组合\"页新建/编辑治疗方案：为各血量百分比档位设置对应的法术与等级。",
        "3. 牧师方案若包含神圣新星/治疗祷言，一键治疗会自动智能切换团刷或单体。",
        "4. 将方案绑定到动作条/宏/按键，或用下方命令触发治疗。",
        "",
        "【常用命令】",
        "/gbyh 或 /gbyheal       打开/关闭设置界面",
        "/gbyh save <名称>        将当前设置保存为档案",
        "/gbyh load <名称>        加载档案",
        "/gbyh delete <名称>      删除档案",
        "/gbyh list               列出所有档案",
        "/gbyh opt                打开/关闭选项面板",
        "/gbyh mm                 显示/隐藏小地图按钮",
        "/gbyh reset              重置窗口位置",
        "/gbyh totemreset         重置图腾窗口位置到屏幕中间",
        "/gbyh totem              一键插图腾（当前配置的全部图腾）",
        "/gbyh totemrecall        一键回收图腾",
        "/gbyh showall            显示所有方案（含隐藏方案）",
        "/gbyh togglehidden       切换隐藏方案显示",
        "/gbyh tank               将当前友方目标设为坦克（MT角色，团刷中坦克优先级最高）",
        "/gbyh tankheal [方案]    纯坦克模式：只治疗坦克与自己（需先设坦克/MT）",
        "/gbyh rez                一键复活",
        "/gbyh dispel             一键驱散",
        "/gbyh dispelprio         打开/关闭驱散优先级设置窗口",
        "/gbyh help               显示帮助",
        "/gbyh <方案名>           对指定方案执行一键治疗（始终走团刷；方案中含祷言/新星自动团刷/单体切换，坦克MT→8T在团刷中优先级递减）",
        "",
        "【API 调用】（用于 /script 或宏）",
        "GoubayuHeal.HealMostWounded(\"standard\")  按方案治疗最伤的队员（牧师方案含神圣新星/治疗祷言时自动切换团刷/单体）",
        "GoubayuHeal.ActionHeal(\"standard\")       方案治疗（与 HealMostWounded 团刷行为一致；坦克/目标/自身智能判断）",
        "GoubayuHeal.Heal(unit, spell, rank)        对指定单位施放法术，如 Heal(\"party1\", \"快速治疗\", 7)",
        "GoubayuHeal.DoRez()                        一键复活",
        "GoubayuHeal.CanHeal(unit)                  判断单位是否可治疗",
        "GoubayuHeal.UnitName(unit)                 获取单位名字",
        "GoubayuHeal.HasBuffByName(unit, buffName)  检测单位是否有指定名称的增益",
        "GoubayuHeal.Dispel()                       一键驱散（扫描全队并净化最优目标）",
        "GoubayuHeal.Dispel_Priority()              队列驱散（按驱散优先阈值判定，供方案队列集成）",
        "GoubayuHeal.Dispel_TogglePrioWindow()      打开/关闭驱散优先级设置窗口",
        "GoubayuHeal.Dispel_Scan()                  手动扫描全队可驱散减益",
        "GoubayuHeal.Dispel_BuildPrio()             重建驱散扫描目标优先级",
        "GoubayuHeal.Dispel_OnRosterChange()        团队变动时刷新驱散目标",
        "GoubayuHeal.Dispel_UpdateUsable()          重扫当前职业可用的驱散法术",
        "GoubayuHeal.Dispel_CanCast(unit)           判断目标是否可驱散（射程/视野/友方）",
        "GoubayuHeal.Dispel_GetDebuffInfo(u, i)     读取单位第i个减益（名称/类型/图标/层数）",
        "GoubayuHeal.SafeUpdateSpells()             重建法术库（天赋/法术书变动后调用）",
        "GoubayuHeal.GetSelfHealPower()             获取自己当前实时治疗强度",
        "GoubayuHeal.GetSpellHealing(u, 法术, 等级) 计算法术对单位的实际治疗量",
        "",
        "【示例宏】",
        "/script GoubayuHeal.HealMostWounded(\"standard\")",
        "/script GoubayuHeal.ActionHeal(\"standard\")",
        "/script GoubayuHeal.DoRez()",
    }
else
    GoubayuHeal.GUI_help_lines = {
        "[Pages]",
        "· Classes: create/edit heal profiles; set a spell & rank per health% threshold; drag spells in from the library and attach extras (e.g. Nature's/Ancestral Swiftness). The 2nd row shows only current-class toggles (Shaman totem/water shield, Paladin seals/judgments/strikes); druids also get an \"Aessina's Bloom\" slider (priority bonus for targets under Rejuvenation/Regrowth, 0 = disabled).",
        "· Classes: the \"Per-profile settings\" toggle on the profile row saves settings (Settings/Priorities/Raid/HOT/Rez/Dispel/Adv.) per profile and follows profile switching; off = all profiles share one set. When creating a new profile you can pick an existing one in the \"Copy profile\" dropdown to clone it (incl. its settings), or \"None\" to start from defaults.",
        "· Classes: Priests can enable \"Alternating spells\" (Prayer Book; alternates when the same spell would be cast twice in a row; interrupted/failed casts are retried first), \"Maintain Inner Fire\" (auto-cast when missing), and \"Desperate Prayer\" (cast at highest priority when health drops below the threshold); Shamans can enable \"Chain-to-wave on no bounce\"; Druids \"Maintain Tree of Life form\"; \"Anti-starvation shuffle\" avoids always healing the same target.",
        "· Classes: Paladin \"Melee heal\" only melees when an enemy target exists and is in melee range (5yd/attack range): maintain Seal of Wisdom → keep Judgment of Wisdom → Crusader Strike, then heal per the profile's health% tiers (Holy Strike/Holy Light/Flash of Light etc. work as profile spells; heal-target priority follows the profile priorities); when no melee target is available it falls back to the normal heal profile.",
        "· Classes: Paladin \"Divine Shield\"/\"Divine Protection\" sliders - cast at highest priority when your own health drops below the set threshold (self only; requires no cooldown, mana, and no Forbearance debuff); 0% = disabled. Same pattern as the Priest \"Desperate Prayer\" slider.",
        "· Classes: In the totem window, right-click any of the four element buttons to toggle that element disabled/enabled (disabled shows a semi-transparent red icon); disabled elements are skipped by one-click placing, handy for mana-efficient setups with only a few totems.",
        "· Classes: When predicting the next heal target, incoming heals are taken into account - a target whose \"current health + incoming heal\" is already full gets lower priority, so targets with real deficits are preferred and overhealing is avoided.",
        "· Classes: \"Spell estimate data\" edits base heal / spell power ratio / scale factor per spell; auto-cached from the tooltip on first entry; Reset re-reads them.",
        "· Settings: heal threshold, max overheal, HoT scaling, update frequency, heal strategy, Nampower queue timeout, and other global options.",
        "· Priorities: heal priority for player/party/raid/pet/MT and each class, plus buff/debuff priorities (Blessing of Protection, Power Word: Shield, Weakened Soul, Mortal Strike, etc.).",
        "· Raid: set member roles (tank/MT), resurrection order, and per-member HoT maintenance ranks.",
        "· HOT: per-member auto-maintenance rank and toggle for Rejuvenation/Renew-style HoTs.",
        "· Rez: one-click resurrection options and priority. Use $t in the rez message to insert the resurrected target's name (via cast-target GUID under Nampower; auto-targets the target otherwise).",
        "· Dispel: one-click dispel toggle, per-spell priority and queue.",
        "· Dispel: bind /gbyh dispel to a key for one-click dispel; \"infectious curse\" targets with allies within 8yd defer the dispel with a warning shout (5s throttle); Shamans auto-prefer Poison/Disease Cleansing Totems within 26yd.",
        "· Competition (Settings): \"healer count limit\" and \"block faster healers\" can both be enabled and are judged independently - skip by concurrent healer count, or by \"someone's heal lands before yours\" (instants exempt); when every target is covered the addon force-heals the biggest deficit - never idles.",
        "· Totems: per-totem independent cooldown and duration timing (0.1s refresh, same precision as Totem Master); CDs persist across reloads; coverage counts only living, connected members of your own subgroup (30yd).",
        "· Classes: Paladin profiles can include \"Lay on Hands\" (no-estimate tier) - auto-cast below the threshold, heals to full and drains your mana; mind its long cooldown.",
        "· Adv.: advanced options (auto spell rank, force max rank, safe cancel, hidden profiles, etc.), plus \"Export config\"/\"Import config\" (a compact GBYH-prefixed string for sharing and restoring all settings, incl. per-profile ones).",
        "· Help: this page.",
        "",
        "[Usage]",
        "1. Open the settings: type /gbyh or click the minimap button.",
        "2. On the Classes tab, create/edit heal profiles: assign a spell & rank per health% threshold.",
        "3. If a Priest profile contains Holy Nova / Prayer of Healing, one-click healing auto-switches between AoE and single target.",
        "4. Bind profiles to action bars / macros / keys, or use the commands below.",
        "",
        "[Commands]",
        "/gbyh or /gbyheal        Open/close the settings window",
        "/gbyh save <name>         Save current settings as a profile",
        "/gbyh load <name>         Load a profile",
        "/gbyh delete <name>       Delete a profile",
        "/gbyh list                List all profiles",
        "/gbyh opt                 Toggle the options panel",
        "/gbyh mm                  Show/hide the minimap button",
        "/gbyh reset               Reset window position",
        "/gbyh totemreset          Reset the totem window to screen center",
        "/gbyh totem               Place all totems in one click",
        "/gbyh totemrecall         Recall all totems in one click",
        "/gbyh showall             Show all profiles (incl. hidden)",
        "/gbyh togglehidden        Toggle hidden profiles display",
        "/gbyh tank                Set current friendly target as tank (MT role; highest priority in raid heal)",
        "/gbyh tankheal [profile]  Tank-only mode: heal the tank and yourself (requires a tank/MT set first)",
        "/gbyh rez                 One-click resurrection",
        "/gbyh dispel              One-click dispel",
        "/gbyh dispelprio          Open/close the dispel priority window",
        "/gbyh help                Show help",
        "/gbyh <profile>           One-click heal for a profile (always raid-heals; auto AoE/single with Nova/Prayer; tanks MT->8T get decreasing priority)",
        "",
        "[API] (for /script or macros)",
        "GoubayuHeal.HealMostWounded(\"standard\")  Heal the most wounded unit by profile (Priest profiles with Nova/Prayer auto-switch AoE/single)",
        "GoubayuHeal.ActionHeal(\"standard\")       Profile healing (raid-heal behavior same as HealMostWounded; tank/target/self aware)",
        "GoubayuHeal.Heal(unit, spell, rank)        Cast a spell on a unit, e.g. Heal(\"party1\", \"Flash Heal\", 7)",
        "GoubayuHeal.DoRez()                        One-click resurrection",
        "GoubayuHeal.CanHeal(unit)                  Check if a unit can be healed",
        "GoubayuHeal.UnitName(unit)                 Get a unit's name",
        "GoubayuHeal.HasBuffByName(unit, buffName)  Check if a unit has a buff by name",
        "GoubayuHeal.Dispel()                       One-click dispel (scan the group and cleanse the best target)",
        "GoubayuHeal.Dispel_Priority()              Queue dispel (threshold-based, for profile queue integration)",
        "GoubayuHeal.Dispel_TogglePrioWindow()      Toggle the dispel priority window",
        "GoubayuHeal.Dispel_Scan()                  Manually scan the group for dispellable debuffs",
        "GoubayuHeal.Dispel_BuildPrio()             Rebuild the dispel scan target priority",
        "GoubayuHeal.Dispel_OnRosterChange()        Refresh dispel targets on roster changes",
        "GoubayuHeal.Dispel_UpdateUsable()          Re-scan the class's available dispel spells",
        "GoubayuHeal.Dispel_CanCast(unit)           Check if a target is dispellable (range/LOS/friendly)",
        "GoubayuHeal.Dispel_GetDebuffInfo(u, i)     Read the unit's i-th debuff (name/type/icon/stacks)",
        "GoubayuHeal.SafeUpdateSpells()             Rebuild the spell library (call after talent/spellbook changes)",
        "GoubayuHeal.GetSelfHealPower()             Get your current live healing power",
        "GoubayuHeal.GetSpellHealing(u, spell, rank) Calculate a spell's actual healing on a unit",
        "",
        "[Example Macros]",
        "/script GoubayuHeal.HealMostWounded(\"standard\")",
        "/script GoubayuHeal.ActionHeal(\"standard\")",
        "/script GoubayuHeal.DoRez()",
    }
end

-- ============================================================
-- 运行时文本（命令、错误消息、UI 标签等，非 GUI 选项）
-- ============================================================
if zhCN then
    -- 打印消息
    GoubayuHeal.Msg = {
        -- 通用
        MissingTalent = "[GoubayuHeal Helper] 当前天赋下没有技能 %s",
        MissingTalentCast = "[GoubayuHeal Helper] 施法警告: 当前天赋下没有技能 %s",
        RezNotFound = "未找到可用的复活技能",
        RezInCombat = "战斗中无法救人（德鲁伊的战斗复活除外）",
        DispelTotemCast = "[GoubayuHeal] 插图腾驱散 %s - %s",
        DispelCast = "[GoubayuHeal] 驱散 %s - %s",
        CurseAwayRaid = "警告: -- %s -- 中了%s，请远离人群！",
        CurseAwayWhisper = "你中了%s，请快速远离人群！",
        TankNotInGroup = "%s 不在队伍/团队中。坦克模式已关闭。",
        TankNotInGroup2 = "%s 不在队伍/团队中。坦克模式已关闭",
        -- 命令 save/load/list/delete
        SaveNeedName = "你必须指定要保存设置的档案名",
        SaveOK = "设置已保存为档案\"%s\"",
        LoadNeedName = "你必须指定要从哪个档案加载设置",
        LoadNotFound = "找不到档案\"%s\"",
        LoadOK = "档案\"%s\"已加载",
        DeleteNeedName = "你必须指定要删除的档案",
        DeleteNotFound = "找不到档案\"%s\"",
        DeleteOK = "档案\"%s\"已删除",
        ListTitle = "已保存的档案",
        ListEmpty = "没有保存的档案",
        -- 命令 opt/reset/totem...
        ResetWindow = "窗口位置已重置到屏幕中心",
        TotemResetWindow = "图腾窗口位置已重置到屏幕中间",
        TotemRecallDone = "已执行一键回收图腾",
        ShowAllTitle = "所有配置方案(包括隐藏方案):",
        ShowAllEmpty = "没有配置方案",
        HiddenSchemesOn = "启用",
        HiddenSchemesOff = "禁用",
        HiddenSchemesToggle = "隐藏方案显示: %s",
        TankNotExist = "方案 \"%s\" 不存在",
        TankModeHeal = "坦克模式: 治疗 %s",
        TankModeNone = "坦克模式: 未设置坦克(MT)",
        TankSet = "将只治疗坦克: %s",
        TankMustInGroup = "坦克单位必须在你的团队或小队中：%s 不在其中",
        TankKeep = "当前坦克保持不变: %s",
        NoTank = "未设置坦克(MT)",
        TankUnset = "将不再只治疗 %s",
        -- help
        HelpUsage = "用法",
        HelpSave = "/gbyh save <档案>|cffffffff   - 将当前设置保存到<档案>",
        HelpLoad = "/gbyh load <档案>|cffffffff   - 从档案加载设置",
        HelpList = "/gbyh list|cffffffff             - 列出所有已保存的档案",
        HelpDelete = "/gbyh delete <档案>|cffffffff - 删除<档案>",
        HelpGui = "/gbyh gui|cffffffff              - 隐藏/显示界面元素",
        HelpMm = "/gbyh mm|cffffffff               - 隐藏/显示小地图按",
        HelpOpt = "/gbyh opt|cffffffff              - 隐藏/显示选项面板",
        HelpReset = "/gbyh reset|cffffffff            - 重置窗口位置到屏幕中心	",
        HelpShowAll = "/gbyh showall|cffffffff          - 显示所有配置方案（包括隐藏方案）",
        HelpToggleHidden = "/gbyh togglehidden|cffffffff     - 切换是否显示隐藏方案",
        -- 槽位名（装备检查）
        SlotNames = {
            [1] = "头部", [2] = "项链", [3] = "肩膀", [4] = "衬衣", [5] = "胸部",
            [6] = "腰部", [7] = "腿部", [8] = "脚部", [9] = "手腕", [10] = "手套",
            [11] = "戒指1", [12] = "戒指2", [13] = "饰品1", [14] = "饰品2",
            [15] = "背部", [16] = "主手", [17] = "副手", [18] = "远程", [19] = "弹药",
        },
        SlotUnset = "无",
        HotUnlearned = "未学",
        HotUnset = "无",
        SlUnitsSuffix = "人",
        SlTimeSuffix = " s",
        SlMsSuffix = "ms",
        -- 角色
        RoleNone = "无",
        -- 复活喊话默认值
        RezMessageDefault = "复活吧我的勇士！",
        -- 武器油（buff 名，客户端可能显示中/英文，两套都保留）
        WeaponOil1 = "卓越法力之油",
        WeaponOil2 = "Brilliant Mana Oil",
        -- 水之护盾（中英文名都保留）
        WaterShieldZH = "水之护盾",
        WaterShieldEN = "Water Shield",
        -- 亡者之眼（乌龟服物品 buff，客户端显示英文名）
        EyeOfTheDead = "Eye of the Dead",
        -- 特殊 debuff 名
        WyvernSting = "翼龙钉刺",
        MutatingInjection = "变异注射",
        -- 图腾面板
        TotemFrameLoaded = "图腾框架加载完成",
        TotemUnknownTarget = "未知目标",
        TotemNamePattern = "图腾",
        -- 复活相关
        HolyLight = "圣光术",
        -- 团队/标签
        GroupPrefix = "队伍 ",
    }
    -- Dispel 类型名/短名/颜色
    GoubayuHeal.DispelTypeName = {
        Magic = "驱散魔法", Disease = "驱散疾病", Poison = "驱散中毒",
        Curse = "驱散诅咒", Snare = "驱散移动限制",
    }
    GoubayuHeal.DispelTypeShort = {
        Magic = "魔法", Disease = "疾病", Poison = "中毒",
        Curse = "诅咒", Snare = "移动限制",
    }
    -- 职业显示名
    GoubayuHeal.ClassDisplayName = {
        DRUID = "德鲁伊", HUNTER = "猎人", MAGE = "法师",
        PALADIN = "圣骑士", PRIEST = "牧师",
        ROGUE = "盗贼", SHAMAN = "萨满祭司",
        WARLOCK = "术士", WARRIOR = "战士",
    }
    -- 防误驱散减益默认
    GoubayuHeal.DispelDefaultDebuffs = {
        "鲁莽诅咒", "金度的欺骗", "外域的恐惧", "军团诅咒", "相位转换",
        "不稳定的法力", "变异注射", "圣殿心智衰退", "翼龙钉刺", "毒蘑菇", "食欲之罪",
        "麦迪文的灾祸", "腐蚀之种",
        -- 新增默认屏蔽（防误驱散）by 武藤纯子酱 2026.9.21
        "梦热", "吸血鬼光环", "幽冥放逐", "翡翠腐烂", "翡翠松懈", "圣心腐朽", "伊兰尼库斯之祸",
    }
    -- 增量默认屏蔽：仅把"新增批次"补充进已有黑名单。
    -- 只增不删：不覆盖、也不清除任何已有条目（含此前批次误加项与用户手动添加项），避免误删用户自定义；
    -- 按 Version 只执行一次。
    -- 新增批次时：把条目追加到 Debuffs，并把 Version +1（zhCN/enUS 两块都要改，Version 保持一致）
    -- by 武藤纯子酱 2026.9.21
    GoubayuHeal.DispelDefaultDebuffsMerge = {
        Version = 3,
        Debuffs = {
            "梦热", "吸血鬼光环", "幽冥放逐", "翡翠腐烂", "翡翠松懈", "圣心腐朽", "伊兰尼库斯之祸",
            -- 名称修正：该减益游戏内中文为"食欲之罪"（en 仍为 Gluttony's Avarice）
            -- by 武藤纯子酱 2026.9.21
            "食欲之罪",
        },
    }
    GoubayuHeal.DispelFilterDebuffs = {
        "冰柱", "奥术超载", "无梦睡眠", "强效昏睡", "风歌夜曲",
        "摩尔达的勇气", "芬古斯的狂暴", "斯里基克的机智", "雷霆之怒", "熔岩镣铐",
    }
    GoubayuHeal.DispelClassFilter = {
        WARRIOR = { "上古狂乱", "点燃法力", "污浊之魂", "莫罗斯诅咒", "魔鳞诅咒" },
        ROGUE = { "沉默", "上古狂乱", "点燃法力", "污浊之魂", "烟雾弹", "往日的尖啸", "莫罗斯诅咒", "魔鳞诅咒" },
        WARLOCK = { "裂隙纠缠" },
    }
    -- 需远离人群的减益（不限于诅咒：命中后要先确认周围没人再驱散）
    -- by 武藤纯子酱 2026.9.21
    GoubayuHeal.DispelNearbyCurseTargets = {
        "大领主印记", "麦迪文的腐化", "恶液烂芽",
    }
    -- 驱散技能（按职业）
    GoubayuHeal.DispelSpells = {
        ["PALADIN"] = {
            Magic = { "清洁术" },
            Poison = { "清洁术", "纯净术" },
            Disease = { "清洁术", "纯净术" },
            Snare = { "自由之手" },
        },
        ["DRUID"] = {
            Curse = { "解除诅咒" },
            Poison = { "驱毒术", "消毒术" },
        },
        ["PRIEST"] = {
            Magic = { "驱散魔法" },
            -- 优先"驱除疾病"(Abolish Disease，持续解疾病)，与 enUS 列表一致；
            -- 顺序反了会取到"祛病术"(Cure Disease，低级瞬解) by 武藤纯子酱 2026.10.9
            Disease = { "驱除疾病", "祛病术" },
        },
        ["SHAMAN"] = {
            Poison = { "消毒术" },
            Disease = { "祛病术" },
        },
        ["MAGE"] = { Curse = { "解除次级诅咒" } },
        ["WARLOCK"] = { Magic = { "吞噬魔法" } },
    }
    -- 驱散窗口 UI
    GoubayuHeal.DispelUI = {
        WindowTitle = "驱散",
        ButtonPriority = "优先级",
        ButtonAdd = "添加目标",
        ButtonClear = "清除",
        ButtonAdd2 = "添加",
        ButtonReset = "重置",
        Reset50 = "重置50%",
        Reset0 = "重置0%",
        Invert = "反向",
        PartyOnly = "只驱散小队",
        GroupPrefix = "队伍 ",
        PrioWindowTitle = "驱散优先级（0=忽略 4=默认 8=优先）",
        PrioHint = "右键点击成员名可移除；0=忽略 4=默认 8=优先",
        ClassFilterLabel = "职业开关：",
        ClassFilterTip = "开启：该职业成员正常参与驱散。\n关闭：无论上方优先级如何设置，该职业都不会被驱散。\n默认全部开启，点击切换。",
    }
    -- 萨满图腾
    GoubayuHeal.Totem = {
        TotemPoison = "清毒图腾",
        TotemDisease = "祛病图腾",
    }
    -- 技能名（用于 CastSpellByName 等）
    GoubayuHeal.Spell = {
        TotemRecall = "图腾召回",
        HealingWave = "治疗波",
    }
    -- 装备 tooltip 匹配模式（中英文都保留，匹配两种客户端文本）
    GoubayuHeal.TooltipPattern = {
        Use = { "^%s*使用[:：]", "^%s*Use[:：]" },
        Radius = { "周围半径", "[Rr]adius" },
        Set = { "^%s*套装[:：]", "^%s*Set[:：]" },
    }
    -- HOT 描述正则（第3捕获可含"到320"这类区间后缀，解析端剔除非数字）
    GoubayuHeal.HotRegex = "在(%d+)秒内恢复[^%d]*(%d+)([%d到]*)点生命值。"
    -- 直接治疗锚定模式（乌龟服 zhCN 文本用"恢复/回复X到Y点生命值"两种写法；
    -- 圣光术文本先出现"治疗X到Y点伤害"组，必须锚定"生命值"取组，否则取错）
    GoubayuHeal.HealSpellPatterns = {
        [GoubayuHeal.Holy_light] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Flash_of_light] = { "恢复(%d+)到(%d+)点生命值", "回复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Flash_heal] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Greater_heal] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Heal] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Lesser_heal] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Healing_touch] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Healing_wave] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Lesser_healing_wave] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        [GoubayuHeal.Prayer_of_healing] = { "回复(%d+)到(%d+)点生命值", "恢复(%d+)到(%d+)点生命值" },
        -- 神圣打击：描述"...为你和10码范围内最多4名队友恢复90点生命值和90点法力值..."
        -- 捕获"恢复N点生命值"，记为每目标治疗量 Heal
        [GoubayuHeal.Holy_Strike] = { "恢复(%d+)点生命值" },
        -- 愈合：直接治疗段 + HoT 段（数字顺序=捕获顺序：直接2个、HoT秒数、HoT量2个）
        [GoubayuHeal.Regrowth] = {
            "恢复(%d+)到(%d+)点生命值。在(%d+)秒内恢复[^%d]*(%d+)[^%d]*(%d*)点生命值",
            "回复(%d+)到(%d+)点生命值。在(%d+)秒内恢复[^%d]*(%d+)[^%d]*(%d*)点生命值",
        },
        -- 真言术：盾（吸收+持续+后续禁盾时间；第二条兜底无"之后的"写法）
        [GoubayuHeal.Power_word_shield] = {
            "吸收(%d+)点伤害，持续(%d+)秒.-之后的(%d+)秒",
            "吸收(%d+)点伤害，持续(%d+)秒",
        },
        -- 宁静：每秒恢复X点，持续Y秒
        [GoubayuHeal.Tranquility] = { "每[^%d]*恢复(%d+)点生命值，持续(%d+)秒" },
    }
    -- Codec 错误消息
    GoubayuHeal.Codec = {
        NaN = "无效数字(NaN)",
        NumTooLong = "数字过长",
        StrTooLong = "字符串过长",
        NestTooDeep = "嵌套过深",
        ElemTooLong = "表元素过长",
        CompressedIncomplete = "压缩文本不完整",
        BadCompressedRef = "压缩文本引用无效",
        TooLarge = "导入内容超过安全限制",
        BadLength = "文本长度不正确",
        BadChar = "文本包含无效字符",
        BadEnd = "文本结尾不完整",
        BadPad = "填充字符位置不正确",
        Incomplete = "数据不完整",
        BadType = "无法识别的类型码",
        InvalidText = "无效文本",
        BadPrefix = "导出文本前缀不正确（需 GBYH:1:）",
        BadChecksum = "校验和不匹配（导出文本可能被修改或复制不完整）",
        NotInitialized = "配置尚未初始化",
        ImportNotTable = "导入数据不是配置表",
    }
    -- 图腾元素短名
    GoubayuHeal.Element = {
        Fire = "火", Water = "水", Earth = "土", Air = "风",
    }
    -- 图腾技能名（CastSpellByName 用）
    GoubayuHeal.TotemData = {
        Searing = "灼热图腾", FireNova = "火焰新星图腾", Magma = "熔岩图腾",
        FrostRes = "抗寒图腾", FlameTongue = "火舌图腾",
        ManaSpring = "法力之泉图腾", HealingStream = "治疗之泉图腾", FireRes = "抗火图腾",
        PoisonCleansing = "清毒图腾", DiseaseCleansing = "祛病图腾",
        Earthbind = "地缚图腾", Tremor = "战栗图腾", StrengthOfEarth = "大地之力图腾",
        Stoneskin = "石肤图腾", Stoneclaw = "石爪图腾",
        TranquilAir = "宁静之风图腾", Grounding = "根基图腾", Windfury = "风怒图腾",
        GraceOfAir = "风之优雅图腾", NatureRes = "自然抗性图腾", Windwall = "风墙图腾",
        Sentry = "岗哨图腾",
    }
    -- 不判断范围的图腾列表
    GoubayuHeal.TotemSkipRangeList = {
        "灼热图腾", "火焰新星图腾", "熔岩图腾", "清毒图腾", "祛病图腾",
        "根基图腾", "地缚图腾", "战栗图腾", "石爪图腾",
    }
    -- 图腾技能名到Buff名的映射
    GoubayuHeal.TotemBuffMap = {
        [GoubayuHeal.TotemData.FrostRes] = "冰霜抗性",
        [GoubayuHeal.TotemData.FlameTongue] = "火舌图腾被动",
        [GoubayuHeal.TotemData.ManaSpring] = "法力之泉",
        [GoubayuHeal.TotemData.HealingStream] = "治疗之泉",
        [GoubayuHeal.TotemData.FireRes] = "火焰抗性",
        [GoubayuHeal.TotemData.StrengthOfEarth] = "大地之力",
        [GoubayuHeal.TotemData.Stoneskin] = "石肤术",
        [GoubayuHeal.TotemData.TranquilAir] = "宁静之风",
        [GoubayuHeal.TotemData.Grounding] = "根基图腾效果",
        [GoubayuHeal.TotemData.Windfury] = "风怒图腾效果",
        [GoubayuHeal.TotemData.GraceOfAir] = "风之优雅",
        [GoubayuHeal.TotemData.NatureRes] = "自然抗性",
        [GoubayuHeal.TotemData.Windwall] = "风墙",
        [GoubayuHeal.TotemData.Sentry] = "岗哨图腾",
    }
    -- 图腾面板 tooltip 文本
    GoubayuHeal.TotemUI = {
        LeftCast = "左键: 释放图腾",
        OneKeyTitle = "一键放置",
        LeftAll = "左键: 一键放置所有图腾",
        RightAll = "右键: 召回所有图腾",
        SettingsTitle = "设置",
        HoverPreset = "鼠标滑过显示预设选项",
        LeftChoosePreset = "左键: 按当前预设放置图腾",
        NotUsingFmt = "不使用%s图腾",
        ClickSkipElement = "点击跳过此元素图腾",
        ClickChooseTotem = "点击选择此图腾",
        ClickChoosePreset = "点击选择此预设",
        RightChooseFine = "右键: 精细图腾管理",
        -- 精细图腾管理窗口 by 武藤纯子酱 2026.9.21
        FineButtonTip = "精细图腾管理",
        FineTitle = "精细图腾管理",
        FineTip = "按战斗目标名字插指定图腾（优先级高于默认方案）；勾选下方两项后，自己中毒/疾病（且不在驱散黑名单）时优先插对应净化图腾。",
        FineEnabled = "启用精细图腾管理（未勾选时以下设置无效）",
        FineLockFrame = "锁定图腾框架",
        FineLockFrameTip = "勾选后图腾框架不能再用鼠标拖动移动位置。",
        FineEnemies = "敌人名字（逗号分隔）",
        FineElement = "元素",
        FineTotemLabel = "图腾",
        FineRange = "距离",
        FineSight = "视野",
        FineEnable = "启用",
        FineAdd = "添加规则",
        FineReset = "重置规则",
        FineResetTip = "恢复为默认套：启用精细管理；战栗图腾（格拉斯/奈法利安/死亡骑士/孟菲斯托斯/皇后/魔鳞护龙者/魔鳞监工/魔鳞巨龙/圣所梦游者，80码内且可见）；根基图腾（哈卡/女皇/战车/骑士/主教，60码内且可见）；自身中毒/疾病用对应净化图腾；蓝量低于20%优先法力之泉。",
        FineCDRevert = "CD 中回退默认图腾",
        FineCDRevertTip = "条件图腾需要重插但自身还在冷却时，先用方案默认图腾顶上，冷却好了自动换回条件图腾。图腾被消耗/消失/手动回收后同样适用。",
        FineSelfPoisonTip = "勾选后：本队（26码内含自己）有人中毒（驱散黑名单里的不算），就持续补插清毒图腾，直到中毒消失；随后自动回退到条件图腾/方案默认。",
        FineSelfDiseaseTip = "勾选后：本队（26码内含自己）有人得病（驱散黑名单里的不算），就持续补插祛病图腾，直到疾病消失；随后自动回退到条件图腾/方案默认。",
        FineAirSwitch = "风系图腾自动切换",
        FineAirSwitchTip = "小队无战士但有猎人/盗贼：方案是风怒图腾时自动换风之优雅图腾；小队战士/猎人/盗贼都没有且自己没学风暴打击（非增强萨）：方案是风怒或风之优雅时自动换宁静之风图腾。",
        FineSelfPoison = "用清毒图腾驱散本队的毒",
        FineSelfDisease = "用祛病图腾驱散本队的疾病",
        FineCombatEnd = "战斗结束后",
        FineCombatEndModes = { "只要怪在就保持", "换回默认图腾", "回收图腾" },
        FineCombatEndTip = "战斗结束（脱战）后如何处理条件图腾：只要怪在就保持 / 换回方案默认图腾 / 直接召回图腾（之后由方案重新补插）。",
        FineManaSpring = "法力之泉阈值",
        FineManaSpringTip = "蓝量低于该比例时，水元素位优先插法力之泉图腾；0=从不（优先级：净化图腾 > 法力之泉 > 条件图腾 > 方案默认）。",
        Presets = {
            "全部图腾超出范围先回收再补充，其他情况少哪个补哪个",
            "只要有图腾超出范围先回收再全部补充",
            "缺哪个图腾补哪个图腾，不回收",
            "全部超范围自动回收，不补充",
            "什么也不做",
            "尊重手动图腾：该元素位上有任何图腾就不动，图腾消失后才补方案图腾",
        },
    }
    -- GUI 界面文本
    GoubayuHeal.UI = {
        OK = "确定", Cancel = "取消", Reset = "重置", None = "无", Off = "关",
        Close = "关闭", Copy = "复制", Add = "添加", Import = "导入",
        RankPrefix = "等级 ", RanksSuffix = " 级",
        ScaleMark = " · 缩放", AttachMarkFmt = " · 挂:%s",
        Author = "by 武藤纯子酱",
        HelpTitle = "GoubayuHeal 使用说明",
        -- 法术选择弹窗
        SpellSelect = "选择法术",
        AutoScaleRank = "自动缩放等级",
        AttachSpellLabel = "挂接法术:",
        AltSpellLabel = "交替技能:",
        OKTip = "将该法术加入当前方案",
        -- 法术预估
        EstTitle = "法术预估数据",
        EstTitleFmt = "法术预估数据：%s",
        ColRank = "等级",
        ColHeal = "基础治疗值",
        ColRatio = "法伤加成比例",
        ColScale = "放大系数",
        EstHint = "清空输入框 = 恢复该行默认；改动影响法术预估（需重开界面生效）。",
        EstSavedFmt = "[GoubayuHeal] 已保存 %s 的预估数据。",
        -- 复制方案
        CopySchemeLabel = "复制方案:",
        CopyScheme = "复制方案",
        CopySchemeTip = "选择要复制为蓝本的已有方案：点击“确定”后，该方案的技能组合会复制到新方案；若已开启“方案独立配置”，该方案的各项设置也会一并复制。选择“无”则新方案为空白技能组合，使用默认设置。",
        -- 名称校验
        BadClassName = "不能使用 \"load\", \"save\", \"delete\", \"list\", \"none\" 作为组合名。",
        BadProfileName = "不能使用 \"load\", \"save\", \"delete\", \"list\", \"none\" 作为档案名。",
        NoProfileName = "没有输入档案名称。",
        ProfileSavedFmt = "档案 \"%s\" 已保存。",
        -- 导入/导出
        TransferTitle = "导入 / 导出配置",
        ExportTitle = "导出配置",
        ImportTitle = "导入配置",
        ExportHint = "已生成当前配置文本，点击“复制”后粘贴到记事本保存。",
        ImportHint = "粘贴配置文本，点击“导入”应用。将替换当前全部设置。",
        ImportOK = "配置导入成功。",
        ImportFailFmt = "导入失败：%s",
        ExportFailFmt = "导出失败：%s",
        ExportUnavailable = "导出功能不可用",
        NoInput = "没有输入内容",
        PrefixErrPattern = "前缀不正确",
        ParseFailFmt = "无法解析：%s",
        FormatError = "格式错误",
        ParseErrorFmt = "解析出错：%s",
        NotConfigTable = "导入数据不是有效的配置表",
        MissingClasses = "导入数据缺少 classes 方案配置",
        -- 组合页
        SchemeLabel = "方案:",
        DeletedClassFmt = "[GoubayuHeal] 已删除组合 %s",
        ChooseScheme = "选择方案",
        ChooseSchemeTip = "左键选择组合方案，右键删除该方案。",
        NewScheme = "新建方案",
        NewSchemeTip = "创建一个新的治疗组合方案。",
        DeleteScheme = "删除方案",
        DeleteSchemeTip = "删除当前方案及其对应的 _D/_S/_T 派生方案。",
        PerScheme = "方案独立配置",
        PerSchemeTip = "开启后，设置、优先、团队、HOT、复活、驱散、高级各页面的设置按方案独立保存；切换方案时，页面设置自动切换到对应方案的配置。\n\n关闭后，所有方案共用同一套设置。\n\n开启状态下新建方案时，若在“复制方案”下拉中选择某个已有方案，该方案的技能组合与设置会一并复制到新方案；选择“无”则新方案使用空白技能组合与默认设置。",
        NotThisClass = "非本职业不可用",
        -- 职业专属
        OneKeyTotem = "一键图腾",
        OneKeyTotemTip = "开启后，自动治疗时才会按当前预设一键插图腾；关闭则只显示图腾窗口，绝不自动插图腾。手动一键插图腾请用 /gbyh totem。",
        TotemWindow = "图腾窗口",
        TotemWindowTip = "开启后显示图腾窗口，方便快速放置和管理图腾（不会自动插图腾）。",
        KeepWaterShield = "保持水盾",
        KeepWaterShieldTip = "开启后，当你没有水之护盾时，使用治疗技能会自动补充水之护盾。",
        CnbLabel = "链转波:",
        LHW = "次级波",
        CnbTitle = "链无弹跳转波",
        CnbTip = "治疗链主目标7.5码内无可弹跳目标时，改用同等治疗量的治疗波/次级治疗波节省法力。0=关闭，1=转治疗波，2=转次级治疗波。",
        MeleeHeal = "近战奶",
        MeleeHealTip = "近战奶骑一键宏：保持智慧圣印→维持所选审判→近战填充（神圣震击/神圣打击群疗/十字军打击）→按方案档位治疗。仅在存在敌对目标且目标在近战范围时打近战，无法近战时回退正常治疗方案。",
        MeleeJudgmentLabel = "审判:",
        MeleeJudgmentTitle = "近战奶维持的审判",
        MeleeJudgmentTip = "近战奶维持的审判类型。选十字军/光明时：目标缺少该审判debuff → 先切对应圣印、审判目标、再切回智慧圣印；目标已有该审判 → 正常保持智慧圣印。智慧 = 维持智慧审判（原行为）。不审判 = 近战循环完全不施放审判。",
        JwText = "智慧",
        JcText = "十字军",
        JlText = "光明",
        NoneText = "不审判",
        MeleeSealToggle = "智慧圣印",
        MeleeSealToggleTip = "开启后近战循环给自己保持智慧圣印（回蓝）。关闭后不再挂智慧圣印（维持十字军/光明审判所需的对应圣印不受影响）。",
        MeleeCSToggle = "十字军打击",
        MeleeCSToggleTip = "关闭后近战填充不再使用十字军打击（只保留神圣震击与神圣打击群疗）。默认开启。",
        ConsecToggle = "保持奉献",
        ConsecToggleTip = "开启后，近战循环中只要奉献不在冷却就施放1级奉献（以自身为中心的范围技能，占用公共CD）。不需要加入技能库。",
        HSInterruptToggle = "断条神圣打击",
        HSInterruptToggleTip = "开启后，神圣打击群疗条件满足（范围内掉血人数达标）时会打断当前正在读条的治疗并立即施放神圣打击。",
        MeleeHSMissingLabel = "打击缺血量:",
        MeleeHSMissingTip = "神圣打击群疗触发条件：范围内掉血超过该数值（当前生命比满血少的量）的队友数达到“打击人数”时才打神圣打击。默认 200。",
        MeleeHSCountLabel = "打击人数:",
        MeleeHSCountTip = "神圣打击群疗触发条件：范围内掉血超过“打击缺血量”的队友（含本人/宠物）至少达到该数量时才打神圣打击。默认 3。",
        MeleeHSRangeLabel = "打击范围:",
        MeleeHSRangeTip = "神圣打击群疗的触发范围（码）：统计该范围内掉血超过“打击缺血量”的队友人数。默认 10 码。",
        AoeOverrideTitle = "群疗条件覆盖",
        AoeOverrideHint = "覆盖该技能的触发条件（留空恢复默认）。仅对群体治疗技能生效。",
        AoeRangeLabel = "范围(码):",
        AoeCountLabel = "人数:",
        AoeMissingLabel = "最小掉血:",
        DsLabel = "圣盾术:",
        DsTitle = "圣盾术自动施放阈值",
        DsTip = "自身血量低于该百分比时，最高优先级断条施放圣盾术（仅对自己；需不在CD、蓝量够、且无自律debuff）。0% = 关闭。",
        Dp2Label = "圣佑术:",
        Dp2Title = "圣佑术自动施放阈值",
        Dp2Tip = "自身血量低于该百分比时，最高优先级断条施放圣佑术（仅对自己；需不在CD、蓝量够、且无自律debuff）。0% = 关闭。",
        AllowFirstRank = "一级无视过量",
        AllowFirstRankTip = "开启后，一级法术将无视过量治疗，持续治疗直到达到治疗门槛。",
        KeepTree = "保持生命之树形态",
        KeepTreeTip = "开启后，当处于施法者形态时自动切换为生命之树形态（治疗加成）。已在树/熊/猫等形态时不干扰。",
        EssenceLabel = "艾森娜:",
        EssenceTipDruid = "艾森娜之花效果：德鲁伊专属",
        EssenceTip = "艾森娜之花效果",
        EssenceTipBody = "目标身上有愈合或回春时优先级加成百分比，0 表示禁用。",
        ForceGreater = "疾速只用强效",
        ForceGreaterTip = "开启后，当玩家身上存在[疾速治疗]buff时，只使用强效治疗术（无论方案设了什么技能）；若方案设了对应等级的强效治疗术则用该等级，否则统一用1级。buff不在时按正常方案。",
        AlternateSpells = "交替技能",
        AlternateSpellsTip = "开启后，配合方案条目中设置的[交替技能]：当连续两次要施放同一技能时，改用该条目的交替技能施放（不同技能交替才能触发祈祷之书天赋省蓝）。若方案本身已让两次用不同技能，则不额外交替。",
        T8Two = "8T2",
        T8TwoTip = "穿8件T2时勾选。强效治疗术会附带一个5级恢复HOT（HOT名为\"强效治疗术\"，数值/时长/法伤加成与5级恢复相同）：①团刷对比时单体按 强效治疗术+5级恢复HOT×50%（HOT通常跳不完） 计算；②连续强效治疗术自带HOT即可触发祈祷之书，不再插入交替技能。",
        T35Label = "T3.5:",
        T35Title = "T3.5 套装件数",
        T35Tip = "选择已装备的T3.5套装件数档位：3T3.5 = 神圣震击治疗量提高192；5T3.5 = 在3件效果基础上，神圣打击治疗量提高10%。",
        T35None = "无",
        T35Three = "3T3.5",
        T35Five = "5T3.5",
        T25Five = "5T2.5",
        T25FiveTip = "勾选后（德鲁伊5件T2.5）：治疗之触对身上有回春术或愈合的目标治疗效果提高10%。",
        AllowRegrowthOverwrite = "允许覆盖愈合",
        AllowRegrowthOverwriteTip = "勾选后（默认）：愈合不再受 HoT 门槛限制，目标残血时可用同级或低级愈合覆盖刷新已有愈合，避免因身上挂着旧愈合而迟迟不加血。",
        KeepInnerFire = "保持心灵之火",
        KeepInnerFireTip = "开启后，当玩家身上没有[心灵之火]buff时，自动给自己施放心灵之火。",
        DpLabel = "绝望祷言:",
        DpTitle = "绝望祷言自动施放阈值",
        DpTip = "自身血量低于该百分比时，最高优先级断条施放绝望祷言（需已学习、不在CD、蓝量够）。0% = 关闭。",
        -- 组合页流程
        FlowHeader = "当前方案",
        LibraryHeader = "法术库",
        Edit = "编辑",
        EditTip = "修改该条目的百分比、等级、缩放与挂接法术。",
        DeleteTip = "从当前方案删除该条目。",
        -- HOT 页
        HotPrioLabel = "HOT维持阈值",
        HotPrioTip = "团队最低血量高于此百分比时，以维持HOT为第一优先级；有人低于此百分比时，以加血为第一要务。",
        HotNoHots = "当前职业没有可维持的HOT",
        -- 复活页
        RezButton = "一键复活",
        RezButtonTip = "复活目标，否则自动选择等待列表中最合适的死亡单位施放复活术，并发送复活喊话。",
        RezHint = "也可使用命令 /gbyh rez 触发。",
        RezMsgLabel = "复活喊话:",
        RezMsgTip = "复活后发送的消息，$t 会被替换为被复活者的名字。",
        RezChanLabel = "喊话频道:",
        RezChanTip = "SAY=喊话, PARTY=小队, RAID=团队, NONE=不喊话。团队模式下选 RAID 会自动降级为 PARTY。",
        RezPriTitle = "复活优先级",
        RezSliderTip = "该职业被复活的优先级权重。值越高越优先被复活。",
        -- 驱散页
        DispelPrioTipTitle = "驱散优先级",
        DispelPrioTipBody = "打开驱散优先级设置窗口（各成员驱散优先级：0=忽略 4=默认 8=优先）",
        DispelPrioThreshold = "驱散优先阈值",
        DispelPrioThresholdTip = "团队最低血量高于此百分比时以驱散为第一优先级；设为0%则任何情况下都优先驱散。",
        DispelFilterLabel = "可驱散类型",
        -- 设置页分区标题 by 武藤纯子酱 2026.9.21
        DispelSecBasic = "驱散功能",
        DispelSecBehavior = "行为开关",
        DispelSecAppearance = "窗口外观",
        CantDispelFmt = "你的职业无法驱散%s。",
        DispelPets = "驱散宠物",
        DispelWyvern = "驱散翼龙钉刺",
        DispelMutating = "驱散变异注射",
        ForceDispel = "强制驱散",
        ShadowformFilter = "暗影形态过滤",
        DispelPrint = "开启聊天通告",
        ShowBackdrop = "显示背景",
        ShowHeader = "显示标题",
        LockWindow = "锁定窗口",
        FlipUI = "界面反转",
        Scale = "缩放",
        Opacity = "透明度",
        ShowDebuffs = "显示减益",
        Blacklist = "黑名单设置",
        BlacklistTip = "需要忽略的减益：输入名称添加，左键选中后点X或右键移除。加入后不会出现在驱散列表，防止误驱散。",
        ClassHide = "职业隐藏",
        ClassHideTip = "选择职业后，为该职业隐藏指定减益：输入名称添加，左键选中后点X或右键移除。",
        HideDebuffs = "隐藏减益",
        HideDebuffsTip = "指定某些减益不被显示/驱散：输入名称添加，左键选中后点X或右键移除。不影响同类型其他减益。",
        PerSchemeTip_Refined = "开启后，每个成员下方滑块的值才参与该成员的优先级计算（滑块默认50%）。关闭时所有成员按基础优先级治疗，滑块置灰不可拖动。",
        ResetTip = "将当前所有成员的优先级滑块重置为50%。",
        InvertTip = "将当前所有成员的优先级取反（1-当前值），如30%变70%，再点一次变回30%。",
        ClearRolesTip = "将所有成员的坦克/副坦标记清空为无（含MT，同时关闭坦克模式）。",
        MemberSliderTip = "每个成员下方的滑块控制该成员的个人优先级（需先开启顶部\"精细化优先级\"开关）。",
        -- 防护恐惧结界优先级下拉（仅牧师） by 武藤纯子酱 2026.9.21
        FearWardTip = "防护恐惧结界优先级：10 最高、1 最低，默认无；同一优先级只能有一个人。牧师专用：自动为这些成员维持防护恐惧结界。",
        -- 左侧坦克/副坦标记框提示 by 武藤纯子酱 2026.9.21
        RoleBoxTitle = "坦克/副坦标记",
        RoleBoxTip = "点击为该成员设置 MT / 2T… / 无：MT 表示当前主坦克（影响坦克优先级与坦克模式），同一标记同一时间只能有一个人。",
        HotEnabledTip = "开启后，按下方每个成员设置的HOT及等级自动补HOT（目标BUFF栏满或已有同类HOT时不会重复上）。",
        HotClearTip = "清空所有成员设置的HOT（全部变为无）。",
        DispelEnabledTip = "开启后显示常驻的驱散小窗，并可通过点击窗口按钮或/gbyh dispel一键驱散。",
        DispelQueueTip = "勾选后，/gbyh 方案名 会在满足驱散优先阈值时先执行驱散；不勾选则仅通过/gbyh dispel驱散。",
        DispelInterruptTip = "勾选后，驱散时会打断当前施法；不勾选则在施法中不驱散。",
        DispelHiddenTip = "勾选后隐藏常驻驱散小窗，只能通过/gbyh dispel，或勾选'将驱散加入治疗队列'后通过/gbyh 方案名驱散。",
        -- 高级页
        ProfileLabel = "档案:",
        DeletedProfileFmt = "[GoubayuHeal] 已删除档案 %s",
        ProfileLoadedFmt = "档案 \"%s\" 已加载。",
        SaveConfig = "保存档案",
        ImportExportLabel = "导入导出配置:",
        ExportTip = "把当前全部设置（方案、优先级、团队勾选等）生成为文本，可保存分享。",
        ImportTip = "粘贴配置文本导入，将替换当前全部设置。",
    }
else
    -- English
    GoubayuHeal.Msg = {
        MissingTalent = "[GoubayuHeal Helper] Spell not found in current talents %s",
        MissingTalentCast = "[GoubayuHeal Helper] Cast warning: Spell not found in current talents %s",
        RezNotFound = "No resurrection spell available",
        RezInCombat = "Cannot resurrect in combat (except Druid combat rez)",
        DispelTotemCast = "[GoubayuHeal] Totem dispel %s - %s",
        DispelCast = "[GoubayuHeal] Dispel %s - %s",
        CurseAwayRaid = "Warning: -- %s -- has %s, move away from group!",
        CurseAwayWhisper = "You have %s, move away from group quickly!",
        TankNotInGroup = "%s is not in party/raid. Tank mode disabled.",
        TankNotInGroup2 = "%s is not in party/raid. Tank mode disabled",
        SaveNeedName = "You must specify a profile name to save",
        SaveOK = "Settings saved as profile \"%s\"",
        LoadNeedName = "You must specify a profile name to load",
        LoadNotFound = "Profile \"%s\" not found",
        LoadOK = "Profile \"%s\" loaded",
        DeleteNeedName = "You must specify a profile name to delete",
        DeleteNotFound = "Profile \"%s\" not found",
        DeleteOK = "Profile \"%s\" deleted",
        ListTitle = "Saved profiles",
        ListEmpty = "No saved profiles",
        ResetWindow = "Window position reset to screen center",
        TotemResetWindow = "Totem window position reset to screen center",
        TotemRecallDone = "All totems recalled",
        ShowAllTitle = "All profiles (including hidden):",
        ShowAllEmpty = "No profiles",
        HiddenSchemesOn = "enabled",
        HiddenSchemesOff = "disabled",
        HiddenSchemesToggle = "Hidden schemes display: %s",
        TankNotExist = "Profile \"%s\" does not exist",
        TankModeHeal = "Tank mode: healing %s",
        TankModeNone = "Tank mode: no tank (MT) set",
        TankSet = "Will only heal tank: %s",
        TankMustInGroup = "Tank unit must be in your party/raid: %s is not",
        TankKeep = "Current tank kept: %s",
        NoTank = "No dedicated tank",
        TankUnset = "Will no longer only heal %s",
        HelpUsage = "Usage",
        HelpSave = "/gbyh save <profile>|cffffffff   - Save current settings as <profile>",
        HelpLoad = "/gbyh load <profile>|cffffffff   - Load a profile",
        HelpList = "/gbyh list|cffffffff             - List all saved profiles",
        HelpDelete = "/gbyh delete <profile>|cffffffff - Delete <profile>",
        HelpGui = "/gbyh gui|cffffffff              - Hide/show UI elements",
        HelpMm = "/gbyh mm|cffffffff               - Hide/show minimap button",
        HelpOpt = "/gbyh opt|cffffffff              - Hide/show options panel",
        HelpReset = "/gbyh reset|cffffffff            - Reset window position to screen center",
        HelpShowAll = "/gbyh showall|cffffffff          - Show all profiles (including hidden)",
        HelpToggleHidden = "/gbyh togglehidden|cffffffff     - Toggle hidden profiles display",
        SlotNames = {
            [1] = "Head", [2] = "Neck", [3] = "Shoulder", [4] = "Shirt", [5] = "Chest",
            [6] = "Waist", [7] = "Legs", [8] = "Boots", [9] = "Wrist", [10] = "Hands",
            [11] = "Ring1", [12] = "Ring2", [13] = "Trinket1", [14] = "Trinket2",
            [15] = "Back", [16] = "MainHand", [17] = "OffHand", [18] = "Ranged", [19] = "Ammo",
        },
        SlotUnset = "-",
        HotUnlearned = "n/a",
        HotUnset = "-",
        SlUnitsSuffix = "",
        SlTimeSuffix = " s",
        SlMsSuffix = "ms",
        RoleNone = "-",
        RezMessageDefault = "Rise, my champion!",
        -- Weapon oil buff names (keep both client-language variants)
        WeaponOil1 = "卓越法力之油",
        WeaponOil2 = "Brilliant Mana Oil",
        -- Water Shield (keep both language variants)
        WaterShieldZH = "水之护盾",
        WaterShieldEN = "Water Shield",
        -- Eye of the Dead (Turtle WoW item buff, shown in English)
        EyeOfTheDead = "Eye of the Dead",
        -- Special debuff names
        WyvernSting = "Wyvern Sting",
        MutatingInjection = "Mutating Injection",
        -- Totem panel
        TotemFrameLoaded = "Totem panel loaded",
        TotemUnknownTarget = "Unknown",
        TotemNamePattern = "[Tt]otem",
        HolyLight = "Holy Light",
        GroupPrefix = "Group ",
    }
    GoubayuHeal.DispelTypeName = {
        Magic = "Dispel Magic", Disease = "Dispel Disease", Poison = "Dispel Poison",
        Curse = "Dispel Curse", Snare = "Dispel Movement",
    }
    GoubayuHeal.DispelTypeShort = {
        Magic = "Magic", Disease = "Disease", Poison = "Poison",
        Curse = "Curse", Snare = "Movement",
    }
    GoubayuHeal.ClassDisplayName = {
        DRUID = "Druid", HUNTER = "Hunter", MAGE = "Mage",
        PALADIN = "Paladin", PRIEST = "Priest",
        ROGUE = "Rogue", SHAMAN = "Shaman",
        WARLOCK = "Warlock", WARRIOR = "Warrior",
    }
    GoubayuHeal.DispelDefaultDebuffs = {
        "Curse of Recklessness", "Delusions of Jin'do", "Dread of Outland", "Curse of Legion",
        "Phase Shifted", "Unstable Mana", "Mutating Injection", "Temple Enfeeblement", "Wyvern Sting",
        "Poisonous Mushroom", "Gluttony's Avarice", "Doom of Medivh", "Seed of Corruption",
        -- 新增默认屏蔽（防误驱散）by 武藤纯子酱 2026.9.21
        "Dreamfever", "Vampiric Aura", "Nether Banishment", "Emerald Rot", "Emerald Instability",
        "Sanctum Mind Decay", "Bane of Eranikus",
    }
    -- 增量默认屏蔽：仅把"新增批次"补充进已有黑名单（不覆盖用户已删/已添加的条目）
    -- 新增批次时：把条目追加到 Debuffs，并把 Version +1（zhCN/enUS 两块都要改，Version 保持一致）
    -- by 武藤纯子酱 2026.9.21
    GoubayuHeal.DispelDefaultDebuffsMerge = {
        Version = 3,
        Debuffs = {
            "Dreamfever", "Vampiric Aura", "Nether Banishment", "Emerald Rot", "Emerald Instability",
            "Sanctum Mind Decay", "Bane of Eranikus",
        },
    }
    GoubayuHeal.DispelFilterDebuffs = {
        "Icicles", "Arcane Overload", "Dreamless Sleep", "Greater Dreamless Sleep", "Songflower Serenade",
        "Mol'dar's Moxie", "Fengus' Ferocity", "Slip'kik's Savvy", "Thunderfury", "Magma Shackles",
    }
    GoubayuHeal.DispelClassFilter = {
        WARRIOR = { "Ancient Hysteria", "Ignite Mana", "Tainted Mind", "Moroes Curse", "Curse of Manascale" },
        ROGUE = { "Silence", "Ancient Hysteria", "Ignite Mana", "Tainted Mind", "Smoke Bomb", "Screams of the Past", "Moroes Curse", "Curse of Manascale" },
        WARLOCK = { "Rift Entanglement" },
    }
    -- Debuffs requiring the target to be away from others before dispelling (not curse-only)
    -- by 武藤纯子酱 2026.9.21
    GoubayuHeal.DispelNearbyCurseTargets = {
        "Greater Mark of the Dawn", "Medivh's Corruption", "Euyonalia",
    }
    GoubayuHeal.DispelSpells = {
        ["PALADIN"] = {
            Magic = { "Cleanse" },
            Poison = { "Cleanse", "Purify" },
            Disease = { "Cleanse", "Purify" },
            Snare = { "Hand of Freedom" },
        },
        ["DRUID"] = {
            Curse = { "Remove Curse" },
            Poison = { "Abolish Poison", "Cure Poison" },
        },
        ["PRIEST"] = {
            Magic = { "Dispel Magic" },
            Disease = { "Abolish Disease", "Cure Disease" },
        },
        ["SHAMAN"] = {
            Poison = { "Cure Poison" },
            Disease = { "Cure Disease" },
        },
        ["MAGE"] = { Curse = { "Remove Lesser Curse" } },
        ["WARLOCK"] = { Magic = { "Devour Magic" } },
    }
    GoubayuHeal.DispelUI = {
        WindowTitle = "Dispel",
        ButtonPriority = "Priority",
        ButtonAdd = "Add target",
        ButtonClear = "Clear",
        ButtonAdd2 = "Add",
        ButtonReset = "Reset",
        Reset50 = "Reset 50%",
        Reset0 = "Reset 0%",
        Invert = "Invert",
        PartyOnly = "Only party",
        GroupPrefix = "Group ",
        PrioWindowTitle = "Dispel Priority (0=ignore 4=default 8=prioritize)",
        PrioHint = "Right-click a member name to remove; 0=ignore 4=default 8=prioritize",
        ClassFilterLabel = "Classes:",
        ClassFilterTip = "ON: members of this class are dispelled normally.\nOFF: this class is never dispelled, regardless of the priority settings above.\nAll classes are ON by default. Click to toggle.",
    }
    GoubayuHeal.Totem = {
        TotemPoison = "Poison Cleansing Totem",
        TotemDisease = "Disease Cleansing Totem",
    }
    GoubayuHeal.Spell = {
        TotemRecall = "Totemic Recall",
        HealingWave = "Healing Wave",
    }
    -- Tooltip patterns (keep both languages so either client text matches)
    GoubayuHeal.TooltipPattern = {
        Use = { "^%s*Use[:：]", "^%s*使用[:：]" },
        Radius = { "[Rr]adius", "周围半径" },
        Set = { "^%s*Set[:：]", "^%s*套装[:：]" },
    }
    -- HOT description pattern (3rd capture may hold a "to N" range suffix; stripped when parsing)
    GoubayuHeal.HotRegex = "Heals (%d+) total over (%d+) sec"
    -- Direct heal anchored patterns (prefer the heal group; fall back to generic scanning)
    GoubayuHeal.HealSpellPatterns = {
        [GoubayuHeal.Holy_light] = { "heals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Flash_of_light] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Flash_heal] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Greater_heal] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Heal] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Lesser_heal] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Healing_touch] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Healing_wave] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Lesser_healing_wave] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        [GoubayuHeal.Prayer_of_healing] = { "[Hh]eals[^%d]*(%d+)[^%d]*(%d+)" },
        -- Holy Strike: "...heals you and up to 4 allies within 10 yd for 90 health and 90 mana."
        [GoubayuHeal.Holy_Strike] = { "[Ff]or (%d+)[^%d]*[Hh]ealth" },
        -- Power Word: Shield (absorb + duration; Delay falls back to generic)
        [GoubayuHeal.Power_word_shield] = { "absorb[^%d]*(%d+)[^%d]*damage[^%d]*(%d+) sec" },
    }
    GoubayuHeal.Codec = {
        NaN = "Invalid number (NaN)",
        NumTooLong = "Number too long",
        StrTooLong = "String too long",
        NestTooDeep = "Nesting too deep",
        ElemTooLong = "Table element too long",
        CompressedIncomplete = "Compressed text incomplete",
        BadCompressedRef = "Bad compressed reference",
        TooLarge = "Imported content exceeds safety limit",
        BadLength = "Invalid text length",
        BadChar = "Text contains invalid character",
        BadEnd = "Incomplete text ending",
        BadPad = "Invalid pad character position",
        Incomplete = "Incomplete data",
        BadType = "Unrecognized type code",
        InvalidText = "Invalid text",
        BadPrefix = "Export text prefix is incorrect (expected GBYH:1:)",
        BadChecksum = "Checksum mismatch (export text may have been modified or copied incompletely)",
        NotInitialized = "Config not initialized yet",
        ImportNotTable = "Imported data is not a config table",
    }
    GoubayuHeal.Element = {
        Fire = "Fire", Water = "Water", Earth = "Earth", Air = "Air",
    }
    -- Totem spell names (used with CastSpellByName)
    GoubayuHeal.TotemData = {
        Searing = "Searing Totem", FireNova = "Fire Nova Totem", Magma = "Magma Totem",
        FrostRes = "Frost Resistance Totem", FlameTongue = "Flametongue Totem",
        ManaSpring = "Mana Spring Totem", HealingStream = "Healing Stream Totem",
        FireRes = "Fire Resistance Totem",
        PoisonCleansing = "Poison Cleansing Totem", DiseaseCleansing = "Disease Cleansing Totem",
        Earthbind = "Earthbind Totem", Tremor = "Tremor Totem",
        StrengthOfEarth = "Strength of Earth Totem",
        Stoneskin = "Stoneskin Totem", Stoneclaw = "Stoneclaw Totem",
        TranquilAir = "Tranquil Air Totem", Grounding = "Grounding Totem", Windfury = "Windfury Totem",
        GraceOfAir = "Grace of Air Totem", NatureRes = "Nature Resistance Totem",
        Windwall = "Windwall Totem", Sentry = "Sentry Totem",
    }
    -- Totems that skip the range check
    GoubayuHeal.TotemSkipRangeList = {
        "Searing Totem", "Fire Nova Totem", "Magma Totem", "Poison Cleansing Totem",
        "Disease Cleansing Totem", "Grounding Totem", "Earthbind Totem", "Tremor Totem",
        "Stoneclaw Totem",
    }
    -- Totem spell name to buff name mapping
    GoubayuHeal.TotemBuffMap = {
        [GoubayuHeal.TotemData.FrostRes] = "Frost Resistance",
        [GoubayuHeal.TotemData.FlameTongue] = "Flametongue Totem Passive",
        [GoubayuHeal.TotemData.ManaSpring] = "Mana Spring",
        [GoubayuHeal.TotemData.HealingStream] = "Healing Stream",
        [GoubayuHeal.TotemData.FireRes] = "Fire Resistance",
        [GoubayuHeal.TotemData.StrengthOfEarth] = "Strength of Earth",
        [GoubayuHeal.TotemData.Stoneskin] = "Stoneskin",
        [GoubayuHeal.TotemData.TranquilAir] = "Tranquil Air",
        [GoubayuHeal.TotemData.Grounding] = "Grounding Totem Effect",
        [GoubayuHeal.TotemData.Windfury] = "Windfury Totem Effect",
        [GoubayuHeal.TotemData.GraceOfAir] = "Grace of Air",
        [GoubayuHeal.TotemData.NatureRes] = "Nature Resistance",
        [GoubayuHeal.TotemData.Windwall] = "Windwall",
        [GoubayuHeal.TotemData.Sentry] = "Sentry Totem",
    }
    -- Totem panel tooltip texts
    GoubayuHeal.TotemUI = {
        LeftCast = "Left-click: cast totem",
        OneKeyTitle = "One-key place",
        LeftAll = "Left-click: place all totems",
        RightAll = "Right-click: recall all totems",
        SettingsTitle = "Settings",
        HoverPreset = "Hover to show preset options",
        LeftChoosePreset = "Left-click: place totems with the current preset",
        NotUsingFmt = "Disable %s totems",
        ClickSkipElement = "Click to skip this element's totems",
        ClickChooseTotem = "Click to choose this totem",
        ClickChoosePreset = "Click to choose this preset",
        RightChooseFine = "Right-click: fine totem management",
        -- Fine totem management window by 武藤纯子酱 2026.9.21
        FineButtonTip = "Fine totem management",
        FineTitle = "Fine Totem Management",
        FineTip = "Place a specific totem when named enemies are in the fight (higher priority than the default profile). If the boxes below are ticked, a cleansing totem is placed first when you have a poison/disease that is not blacklisted.",
        FineEnabled = "Enable fine totem management (settings below are ignored when off)",
        FineLockFrame = "Lock totem frame",
        FineLockFrameTip = "When ticked, the totem frame can no longer be dragged with the mouse.",
        FineEnemies = "Enemy names (comma separated)",
        FineElement = "Element",
        FineTotemLabel = "Totem",
        FineRange = "Range",
        FineSight = "Sight",
        FineEnable = "On",
        FineAdd = "Add rule",
        FineReset = "Reset rules",
        FineResetTip = "Restore the default set: enable fine management; Tremor Totem (Gluth/Nefarian/Death Knight/Mephistroth/The Queen/Manascale dragonspawn, overseer, drake/Sanctum Sleepwalker within 80 yd and in sight); Grounding Totem (Hakkar/The Queen/Chariot/Knight/Bishop within 60 yd and in sight); cleansing totems for your poison/disease; Mana Spring below 20% mana.",
        FineCDRevert = "Fallback to default while on CD",
        FineCDRevertTip = "When a conditional totem needs re-placing but is still on cooldown, place the profile's default totem first and switch back once it is ready. Also applies after the totem is consumed, expires or is recalled.",
        FineSelfPoisonTip = "When ticked: while anyone in your party (within 26 yd, including you) has a dispellable poison (not in the dispel blacklist), keep placing the Cleansing Totem until it is gone, then fall back to the conditional/profile totem.",
        FineSelfDiseaseTip = "When ticked: while anyone in your party (within 26 yd, including you) has a dispellable disease (not in the dispel blacklist), keep placing the Disease Cleansing Totem until it is gone, then fall back to the conditional/profile totem.",
        FineAirSwitch = "Auto air totem switch",
        FineAirSwitchTip = "No warrior but hunter/rogue in the group: Windfury Totem is replaced by Grace of Air. No warrior/hunter/rogue at all and you have no Stormstrike (not enhancement): Windfury or Grace of Air is replaced by Tranquil Air Totem.",
        FineSelfPoison = "Cleansing Totem for the party's poison",
        FineSelfDisease = "Disease Cleansing Totem for the party's disease",
        FineCombatEnd = "After combat",
        FineCombatEndModes = { "Keep while enemy present", "Revert to defaults", "Recall totems" },
        FineCombatEndTip = "What to do with conditional totems after combat: keep them while the enemy is present / revert to the profile defaults / recall all totems (they will be re-placed by the profile).",
        FineManaSpring = "Mana Spring below",
        FineManaSpringTip = "In the water slot, use Mana Spring Totem when your mana is below this percent; 0 = never (priority: cleansing totem > mana spring > conditional totems > profile default).",
        Presets = {
            "Recall out-of-range totems first then refill missing; otherwise refill the missing one",
            "If any totem is out of range, recall all then place all",
            "Refill the missing totems without recalling",
            "Auto recall all out-of-range totems, no refill",
            "Do nothing",
            "Respect manual totems: keep any totem in the slot, refill the profile totem only once it is gone",
        },
    }
    -- GUI texts
    GoubayuHeal.UI = {
        OK = "OK", Cancel = "Cancel", Reset = "Reset", None = "None", Off = "Off",
        Close = "Close", Copy = "Copy", Add = "Add", Import = "Import",
        RankPrefix = "Rank ", RanksSuffix = " ranks",
        ScaleMark = " · scaled", AttachMarkFmt = " · attach: %s",
        Author = "by 武藤纯子酱",
        HelpTitle = "GoubayuHeal Usage",
        -- Spell select popup
        SpellSelect = "Select Spell",
        AutoScaleRank = "Auto scale rank",
        AttachSpellLabel = "Attach spell:",
        AltSpellLabel = "Alternate spell:",
        OKTip = "Add this spell to the current scheme",
        -- Spell estimate
        EstTitle = "Spell Estimate Data",
        EstTitleFmt = "Spell Estimate Data: %s",
        ColRank = "Rank",
        ColHeal = "Base Heal",
        ColRatio = "Spell Power Ratio",
        ColScale = "Scale Factor",
        EstHint = "Empty input = restore the row default; changes affect spell estimates (reopen UI to apply).",
        EstSavedFmt = "[GoubayuHeal] Saved estimate data for %s.",
        -- Copy scheme
        CopySchemeLabel = "Copy scheme:",
        CopyScheme = "Copy scheme",
        CopySchemeTip = "Choose an existing scheme to copy as the template: after clicking \"OK\", its spell combination is copied to the new scheme; if \"Per-scheme settings\" is enabled, its settings are copied too. Choose \"None\" to start with an empty combination and default settings.",
        -- Name validation
        BadClassName = "Cannot use \"load\", \"save\", \"delete\", \"list\", \"none\" as scheme names.",
        BadProfileName = "Cannot use \"load\", \"save\", \"delete\", \"list\", \"none\" as profile names.",
        NoProfileName = "No profile name entered.",
        ProfileSavedFmt = "Profile \"%s\" saved.",
        -- Import/Export
        TransferTitle = "Import / Export Config",
        ExportTitle = "Export Config",
        ImportTitle = "Import Config",
        ExportHint = "Config text generated. Click \"Copy\" and paste it into a text editor to save.",
        ImportHint = "Paste config text and click \"Import\" to apply. This replaces ALL current settings.",
        ImportOK = "Config imported successfully.",
        ImportFailFmt = "Import failed: %s",
        ExportFailFmt = "Export failed: %s",
        ExportUnavailable = "Export unavailable",
        NoInput = "No input content",
        PrefixErrPattern = "prefix",
        ParseFailFmt = "Unable to parse: %s",
        FormatError = "format error",
        ParseErrorFmt = "Parse error: %s",
        NotConfigTable = "Imported data is not a valid config table",
        MissingClasses = "Imported data is missing the classes scheme config",
        -- Classes page
        SchemeLabel = "Scheme:",
        DeletedClassFmt = "[GoubayuHeal] Deleted scheme %s",
        ChooseScheme = "Choose scheme",
        ChooseSchemeTip = "Left-click to choose a scheme, right-click to delete it.",
        NewScheme = "New scheme",
        NewSchemeTip = "Create a new healing scheme.",
        DeleteScheme = "Delete scheme",
        DeleteSchemeTip = "Delete the current scheme and its _D/_S/_T derived schemes.",
        PerScheme = "Per-scheme settings",
        PerSchemeTip = "When enabled, the Settings, Priorities, Raid, HOT, Rez, Dispel and Advanced pages are saved per scheme; switching schemes switches their settings automatically.\n\nWhen disabled, all schemes share one set of settings.\n\nWhen enabled and creating a new scheme, picking an existing scheme in the \"Copy scheme\" dropdown copies its combination and settings; \"None\" starts blank with default settings.",
        NotThisClass = "Not available for this class",
        -- Class specifics
        OneKeyTotem = "One-key Totems",
        OneKeyTotemTip = "When enabled, auto-healing also places totems by the current preset; when off, only the totem window is shown and totems are never placed automatically. Use /gbyh totem to place manually.",
        TotemWindow = "Totem Window",
        TotemWindowTip = "Shows the totem window for quickly placing and managing totems (no auto placing).",
        KeepWaterShield = "Keep Water Shield",
        KeepWaterShieldTip = "When enabled, healing spells automatically refresh Water Shield if you do not have it.",
        CnbLabel = "Chain->Wave:",
        LHW = "LHW",
        CnbTitle = "Chain Heal no-bounce to Wave",
        CnbTip = "When Chain Heal's main target has no bounce target within 7.5 yards, cast a Healing Wave / Lesser Healing Wave of equal healing to save mana. 0=off, 1=Healing Wave, 2=Lesser Healing Wave.",
        MeleeHeal = "Melee Heal",
        MeleeHealTip = "Melee paladin one-key macro: keep Seal of Wisdom -> maintain the selected Judgement -> melee fillers (Holy Shock / Holy Strike AoE / Crusader Strike) -> heal by profile ranks. Only melees while an enemy target is in melee range; otherwise falls back to the normal healing profile.",
        MeleeJudgmentLabel = "Judgement:",
        MeleeJudgmentTitle = "Melee maintain judgement",
        MeleeJudgmentTip = "Which judgement the melee rotation maintains. Crusader/Light: if the target lacks that judgement debuff, switch to the matching seal, judge, then switch back to Seal of Wisdom; if the target already has it, keep Seal of Wisdom as usual. Wisdom = maintain Wisdom (original behavior). No Judge = the melee rotation never casts Judgement.",
        JwText = "Wisdom",
        JcText = "Crusader",
        JlText = "Light",
        NoneText = "No Judge",
        MeleeSealToggle = "Seal of Wisdom",
        MeleeSealToggleTip = "When enabled, the melee rotation keeps Seal of Wisdom up on yourself (mana). When disabled, no Wisdom Seal is cast (the matching seal required for Crusader/Light judgement maintenance is unaffected).",
        MeleeCSToggle = "Crusader Strike",
        MeleeCSToggleTip = "When disabled, the melee rotation no longer uses Crusader Strike (only Holy Shock and Holy Strike AoE remain). Enabled by default.",
        ConsecToggle = "Keep Consecration",
        ConsecToggleTip = "When enabled, the melee rotation casts rank 1 Consecration whenever it is off cooldown (self-centered AoE, uses the global cooldown). No library entry needed.",
        HSInterruptToggle = "Interrupt for Holy Strike",
        HSInterruptToggleTip = "When enabled, if the Holy Strike AoE conditions are met (deficit count reached), the currently casting heal is interrupted and Holy Strike is cast immediately.",
        MeleeHSMissingLabel = "Holy Strike heal loss:",
        MeleeHSMissingTip = "Holy Strike AoE trigger: cast only when the count of allies whose missing health exceeds this amount reaches the 'Holy Strike count' value. Default 200.",
        MeleeHSCountLabel = "Holy Strike count:",
        MeleeHSCountTip = "Holy Strike AoE trigger: minimum number of allies (incl. self/pet) missing more HP than the 'Holy Strike heal loss' value. Default 3.",
        MeleeHSRangeLabel = "Holy Strike range:",
        MeleeHSRangeTip = "Holy Strike AoE trigger range (yd): counts allies within this range that miss more HP than the 'Holy Strike heal loss' value. Default 10.",
        AoeOverrideTitle = "AoE Condition Override",
        AoeOverrideHint = "Override this spell's trigger conditions (empty = default). Only applies to AoE heal spells.",
        AoeRangeLabel = "Range(yd):",
        AoeCountLabel = "Count:",
        AoeMissingLabel = "Min deficit:",
        DsLabel = "Divine Shield:",
        DsTitle = "Divine Shield auto-cast threshold",
        DsTip = "When your health falls below this percentage, cast Divine Shield at top priority interrupting casts (self only; requires off cooldown, enough mana and no Forbearance debuff). 0% = off.",
        Dp2Label = "Divine Protection:",
        Dp2Title = "Divine Protection auto-cast threshold",
        Dp2Tip = "When your health falls below this percentage, cast Divine Protection at top priority interrupting casts (self only; requires off cooldown, enough mana and no Forbearance debuff). 0% = off.",
        AllowFirstRank = "Rank 1 ignores overheal",
        AllowFirstRankTip = "When enabled, rank 1 spells ignore overheal and keep healing until the heal threshold is reached.",
        KeepTree = "Keep Tree of Life Form",
        KeepTreeTip = "When enabled, automatically switches to Tree of Life Form while in caster form (healing bonus). Does not interfere when already in tree/bear/cat forms.",
        EssenceLabel = "Essence:",
        EssenceTipDruid = "Aessina's Bloom effect: Druid only",
        EssenceTip = "Aessina's Bloom effect",
        EssenceTipBody = "Priority bonus percentage when the target has Regrowth or Rejuvenation; 0 disables.",
        ForceGreater = "Rapid: only Greater Heal",
        ForceGreaterTip = "When enabled, while the [Rapid Healing] buff is on you only Greater Heal is cast (no matter what the profile says); if the profile has the matching rank of Greater Heal it is used, otherwise rank 1. Without the buff the normal profile applies.",
        AlternateSpells = "Alternate spells",
        AlternateSpellsTip = "When enabled, works with the [alternate spell] set on profile entries: when the same spell would be cast twice in a row, the entry's alternate spell is cast instead (alternating different spells triggers the Prayer book talent mana saving). If the profile already alternates two different spells, no extra alternation happens.",
        T8Two = "8T2",
        T8TwoTip = "Check when wearing 8x T2. Greater Heal comes with a free rank-5 Renew HoT (HoT named \"Greater Heal\", same value/duration/spellpower as rank 5 Renew): 1) AoE comparison counts single-target as Greater Heal + rank-5 Renew HoT x 50% (HoTs rarely tick out fully); 2) consecutive Greater Heals trigger Prayer Book via the built-in HoT, so no alternate spells are inserted.",
        T35Label = "T3.5:",
        T35Title = "T3.5 set pieces",
        T35Tip = "Select the equipped T3.5 set tier: 3T3.5 = Holy Shock healing +192; 5T3.5 = additionally, Holy Strike healing +10%.",
        T35None = "None",
        T35Three = "3T3.5",
        T35Five = "5T3.5",
        T25Five = "5T2.5",
        T25FiveTip = "When checked (Druid 5x T2.5): Healing Touch healing is increased by 10% against targets affected by Rejuvenation or Regrowth.",
        AllowRegrowthOverwrite = "Allow Regrowth overwrite",
        AllowRegrowthOverwriteTip = "When checked (default): Regrowth is no longer blocked by the HoT threshold - at low health it may overwrite an existing Regrowth with the same or a lower rank, so healing is not stalled by an old HoT.",
        KeepInnerFire = "Keep Inner Fire",
        KeepInnerFireTip = "When enabled, automatically casts Inner Fire on yourself when you do not have the [Inner Fire] buff.",
        DpLabel = "Desperate Prayer:",
        DpTitle = "Desperate Prayer auto-cast threshold",
        DpTip = "When your health falls below this percentage, cast Desperate Prayer at top priority interrupting casts (requires learned, off cooldown, enough mana). 0% = off.",
        -- Classes flow
        FlowHeader = "Current Scheme",
        LibraryHeader = "Spell Library",
        Edit = "Edit",
        EditTip = "Edit this entry's percentage, rank, scaling and attached spell.",
        DeleteTip = "Remove this entry from the current scheme.",
        -- HOT page
        HotPrioLabel = "HOT Maintain Threshold",
        HotPrioTip = "While the raid's lowest health is above this percentage, maintaining HOTs is top priority; when someone drops below it, direct healing becomes the first priority.",
        HotNoHots = "No maintainable HOT for this class",
        -- Rez page
        RezButton = "One-key Resurrect",
        RezButtonTip = "Resurrects the target, otherwise automatically picks the best suited dead unit from the waiting list, casts resurrection and sends the announce message.",
        RezHint = "Also triggered by the /gbyh rez command.",
        RezMsgLabel = "Res Announce:",
        RezMsgTip = "Message sent after resurrecting; $t is replaced with the resurrected player's name.",
        RezChanLabel = "Announce Channel:",
        RezChanTip = "SAY=say, PARTY=party, RAID=raid, NONE=no announce. In raid mode choosing RAID automatically downgrades to PARTY.",
        RezPriTitle = "Resurrection Priority",
        RezSliderTip = "Priority weight for this class being resurrected. Higher values are resurrected first.",
        -- Dispel page
        DispelPrioTipTitle = "Dispel Priority",
        DispelPrioTipBody = "Open the dispel priority window (per-member dispel priority: 0=ignore 4=default 8=prioritize)",
        DispelPrioThreshold = "Dispel Priority Threshold",
        DispelPrioThresholdTip = "While the raid's lowest health is above this percentage, dispelling is top priority; at 0% dispel always takes priority.",
        DispelFilterLabel = "Dispel Types",
        -- 设置页分区标题 by 武藤纯子酱 2026.9.21
        DispelSecBasic = "Dispel",
        DispelSecBehavior = "Behavior",
        DispelSecAppearance = "Window Appearance",
        CantDispelFmt = "Your class cannot dispel %s.",
        DispelPets = "Dispel pets",
        DispelWyvern = "Dispel Wyvern Sting",
        DispelMutating = "Dispel Mutating Injection",
        ForceDispel = "Force dispel",
        ShadowformFilter = "Shadowform filter",
        DispelPrint = "Enable chat announce",
        ShowBackdrop = "Show backdrop",
        ShowHeader = "Show header",
        LockWindow = "Lock window",
        FlipUI = "Flip layout",
        Scale = "Scale",
        Opacity = "Opacity",
        ShowDebuffs = "Show debuffs",
        Blacklist = "Blacklist",
        BlacklistTip = "Debuffs to ignore: type a name and add; left-click to select then press X or right-click to remove. Blacklisted debuffs never appear in the dispel list, preventing misdispels.",
        ClassHide = "Class filter",
        ClassHideTip = "After choosing a class, hide specific debuffs for that class: type a name and add; left-click to select then press X or right-click to remove.",
        HideDebuffs = "Hide debuffs",
        HideDebuffsTip = "Mark debuffs to never be shown/dispelled: type a name and add; left-click to select then press X or right-click to remove. Does not affect other debuffs of the same type.",
        PerSchemeTip_Refined = "When enabled, each member's slider value participates in that member's priority calculation (default 50%). When disabled, all members are healed by base priority and the sliders are grayed out.",
        ResetTip = "Resets all members' priority sliders to 50%.",
        InvertTip = "Inverts all members' priorities (1 - current value), e.g. 30% becomes 70%; clicking again reverts it.",
        ClearRolesTip = "Clears all members' tank/off-tank marks to None (including MT, and turns off tank mode).",
        MemberSliderTip = "Each member's slider controls that member's personal priority (requires the top \"Refined priority\" switch).",
        -- Fear Ward priority dropdown (priest only) by 武藤纯子酱 2026.9.21
        FearWardTip = "Fear Ward priority: 10 = highest, 1 = lowest, default none; each priority holds only one member. Priest only: keeps Fear Ward up on these members.",
        -- Left-side tank/off-tank mark tooltip by 武藤纯子酱 2026.9.21
        RoleBoxTitle = "Tank / off-tank mark",
        RoleBoxTip = "Click to set MT / 2T... / None for this member. MT is the main tank (affects tank priority and tank mode); each mark can be held by one member at a time.",
        HotEnabledTip = "When enabled, automatically re-applies each member's HOT and rank (won't stack when the target's buff bar is full or a similar HOT is already active).",
        HotClearTip = "Clears all members' HOT settings (everything becomes None).",
        DispelEnabledTip = "Shows the always-on dispel window; dispel via the window button or /gbyh dispel.",
        DispelQueueTip = "When checked, /gbyh <scheme> dispels first when the dispel priority threshold is met; unchecked, only /gbyh dispel dispels.",
        DispelInterruptTip = "When checked, dispelling interrupts your current cast; unchecked, no dispel while casting.",
        DispelHiddenTip = "Hides the always-on dispel window; only /gbyh dispel works, or /gbyh <scheme> after checking \"Add dispel to heal queue\".",
        -- Advanced page
        ProfileLabel = "Profile:",
        DeletedProfileFmt = "[GoubayuHeal] Deleted profile %s",
        ProfileLoadedFmt = "Profile \"%s\" loaded.",
        SaveConfig = "Save Profile",
        ImportExportLabel = "Import/Export:",
        ExportTip = "Generates text of all current settings (schemes, priorities, raid checks etc.) for saving or sharing.",
        ImportTip = "Paste config text to import; this replaces all current settings.",
    }
end