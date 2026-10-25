local module, L = BigWigs:ModuleDeclaration("Timbermaw Trash", "Timbermaw Hold")

-- module variables
module.revision = 30138
module.trashMod = true
module.enabletrigger = { "Withermaw Pathfinder", "Withermaw Shaman", "Withermaw Defiler", "Withermaw Ursa", "Withermaw Totemic", "Corruption of Loktanag", "Tainted Mass",  "Son of Ursol", "Foulheart Trickster", "枯喉探路者", "枯喉萨满祭司", "枯喉污染者", "枯喉巨熊怪", "枯喉图腾师", "落潭的腐根", "被污染的胶团", "乌索尔之子", "腐心诡术师" }
module.toggleoptions = {
    "pathfinder_illumination",
    "shaman_blessing",
    "defiler_defiling",
    "defiler_defilingother",
    "defiler_defilingmark",
    "defiler_cloud",
    "defiler_autotarget",  -- [NEW] 新增选项
    -1,
    "ursa_command",
    "ursa_roar",
    -1,
    "totemic_stomp",
    "totemic_totem",
    -1,
    "corruption_boils",
    "corruption_euyonalia",
    "son_rage",
    -1,
    "trickster_siphon"
}
module.zonename = {
    AceLibrary("AceLocale-2.2"):new("BigWigs")["Timbermaw Hold"],
    AceLibrary("Babble-Zone-2.2")["Timbermaw Hold"],
}
local _, playerClass = UnitClass("player")
local BC = AceLibrary("Babble-Class-2.2")

-- module defaults
module.defaultDB = {
    pathfinder_illumination = false,
    shaman_blessing = true,
    defiler_defiling = true,
    defiler_defilingother = true,
    defiler_defilingmark = true,
    defiler_cloud = true,
    defiler_autotarget = false,  -- [NEW] 默认关闭
    ursa_command = playerClass == "HUNTER",
    ursa_roar = true,
    totemic_stomp = true,
    totemic_totem = true,
    corruption_boils = playerClass == BC["SHAMAN"] or playerClass == BC["PRIEST"] or playerClass == BC["PALADIN"],
    corruption_euyonalia = true,
    son_rage = playerClass == BC["HUNTER"],
    trickster_siphon = playerClass == BC["PALADIN"] or playerClass == BC["PRIEST"],
}

-- localization
L:RegisterTranslations("enUS", function()
    return {
        cmd = "TimbermawTrash",

        pathfinder_illumination_cmd = "pathfinder_illumination",
        pathfinder_illumination_name = "Cauterizing Illumination Alert",
        pathfinder_illumination_desc = "Warns when Withermaw Pathfinders gain their 8yd fire aura",

        shaman_blessing_cmd = "shaman_blessing",
        shaman_blessing_name = "Withermaw Blessing Alert",
        shaman_blessing_desc = "Warns when Withermaw Shamans apply their Blessing to others (physical damage immunity)",

        defiler_defiling_cmd = "defiler_defiling",
        defiler_defiling_name = "Withered Defiling Alert",
        defiler_defiling_desc = "Get a personal warning when a Withermaw Defiler puts Withered Defiling on you, and announce it to /say",

        defiler_defilingother_cmd = "defiler_defilingother",
        defiler_defilingother_name = "Withered Defiling Warning",
        defiler_defilingother_desc = "Get warnings about other players suffering from Withered Defiling",

        defiler_defilingmark_cmd = "defiler_defilingmark",
        defiler_defilingmark_name = "Withered Defiling Mark",
        defiler_defilingmark_desc = "Mark players suffering from Withered Defiling",

        defiler_cloud_cmd = "defiler_cloud",
        defiler_cloud_name = "Poison Cloud Alert",
        defiler_cloud_desc = "Warn when you are standing in a Poison Cloud cast by a Withermaw Defiler or Tainted Mass",

        -- [NEW] 新增英文本地化
        defiler_autotarget_cmd = "defiler_autotarget",
        defiler_autotarget_name = "Auto-Target Defiler",
        defiler_autotarget_desc = "Automatically mark and target the Withermaw Defiler that cast Poison Cloud.",

        ursa_command_cmd = "ursa_command",
        ursa_command_name = "Ursol's Command Alert",
        ursa_command_desc = "Warn when a Withermaw Ursa applies their buff aura (Frenzy dispel)",

        ursa_roar_cmd = "ursa_roar",
        ursa_roar_name = "Roar of the Ursa Alert",
        ursa_roar_desc = "Warns when a Withermaw Ursa begins to cast their aoe fear",

        totemic_stomp_cmd = "totemic_stomp",
        totemic_stomp_name = "War Stomp Alert",
        totemic_stomp_desc = "Warns when a Withermaw Totemic begins to cast War Stomp",

        totemic_totem_cmd = "totemic_totem",
        totemic_totem_name = "Corrupted Totem Alert",
        totemic_totem_desc = "Warns when a Withermaw Totemic begins to summon a Corrupted Totem",

        -- 待实测校准：图腾师施法日志（来源：团本小助理规则库）
        trigger_totemic_stomp = "begins to cast War Stomp",
        msg_totemic_stomp = "War Stomp - melee move out, raid hug the wall!",
        trigger_totemic_totem = "begins to cast Summon Corrupted Totem",
        msg_totemic_totem = "Corrupted Totem - move away, watch for shadow nova!",

        corruption_boils_cmd = "corruption_boils",
        corruption_boils_name = "Black Boils Warning",
        corruption_boils_desc = "Warn when Corruption of Loktanag applies Black Boils so they can be cleansed",

        corruption_euyonalia_cmd = "corruption_euyonalia",
        corruption_euyonalia_name = "Euyonalia Alert",
        corruption_euyonalia_desc = "Cast bar and personal alert when you are afflicted by Euyonalia so you can distance before getting dispelled",

        son_rage_cmd = "son_rage",
        son_rage_name = "Ancient Rage Alert",
        son_rage_desc = "Warn when Son of Ursol frenzies",

        trickster_siphon_cmd = "trickster_siphon",
        trickster_siphon_name = "Foulheart Siphon Warning",
        trickster_siphon_desc = "Warn about victims of Foulheart Siphon (drain) by Foulheart Tricksters",


        trigger_pathfinder_illumination = "Withermaw Pathfinder .+ Cauterizing Illumination",
        msg_pathfinder_illumination = "Fire Aura around Pathfinder!",

        trigger_shaman_blessing = "(.+) gains Withermaw Blessing",
        msg_shaman_blessing = "%s immune to physical - Purge!",

        trigger_defiler_defiling = "(.+) ...? afflicted by Withered Defiling",
        msg_defiler_defiling = "Get out of the raid! - Withered Defiling",
        msg_defiler_defilingOther = "Withered Defiling on %s",
        bar_defiler_defiling = "Withered Defiling",
        say_defiler_defiling = "Don't be near me - Withered Defiling!",
        trigger_defiler_cloud = "^You are afflicted by Poison Cloud",
        trigger_defiler_cloudTick = "^You suffer (.+) Nature damage from Withermaw Defiler's Poison Cloud",
        warn_defiler_cloud = "MOVE",

        trigger_ursa_command = "Withermaw Ursa gains Ursol's Command",
        msg_ursa_command = "Ursa Buff Aura active - Tranq Shot!",
        trigger_ursa_roar = "Withermaw Ursa begins to perform Roar of the Ursa.",
        bar_ursa_roar = "Ursa Fear",

        trigger_corruption_boils = "(.+) ...? afflicted by Black Boils",
        msg_corruption_boils = "Black Boils on %s - cleanse them!",
        trigger_corruption_euyonaliaCast = "Corruption of Loktanag begins to cast Euyonalia.",
        bar_corruption_euyonaliaCast = "AoE Disease",
        trigger_corruption_euyonalia = "^You are afflicted by Euyonalia",
        msg_corruption_euyonalia = "You have Euyonalia - spreads on cleanse!",

        trigger_son_rage = "Son of Ursol gains Ancient Rage",
        msg_son_rage = "Bear Enrage - Tranq Shot!",

        trigger_trickster_siphon = "(.+) ...? afflicted by Foulheart Siphon.",
        msg_trickster_siphon = "Drain on %s - dispel them!",
    }
end)

L:RegisterTranslations("zhCN", function()
    return {
        cmd = "TimbermawTrash",

        pathfinder_illumination_cmd = "pathfinder_illumination",
        pathfinder_illumination_name = "灼烧启发警报",
        pathfinder_illumination_desc = "当枯喉探路者获得8码火焰光环时发出警告",

        shaman_blessing_cmd = "shaman_blessing",
        shaman_blessing_name = "枯喉祝福警报",
        shaman_blessing_desc = "当枯喉萨满祭司给他人施加祝福（物理伤害免疫）时发出警告",

        defiler_defiling_cmd = "defiler_defiling",
        defiler_defiling_name = "枯萎玷污警报",
        defiler_defiling_desc = "当枯喉污染者对你施放枯萎玷污时获得个人警报，并通过/say喊话",

        defiler_defilingother_cmd = "defiler_defilingother",
        defiler_defilingother_name = "枯萎玷污提醒",
        defiler_defilingother_desc = "获得关于其他玩家受到枯萎玷污影响的提醒",

        defiler_defilingmark_cmd = "defiler_defilingmark",
        defiler_defilingmark_name = "枯萎玷污标记",
        defiler_defilingmark_desc = "标记受到枯萎玷污影响的玩家",

        defiler_cloud_cmd = "defiler_cloud",
        defiler_cloud_name = "毒云术警报",
        defiler_cloud_desc = "当你站在枯喉污染者或被污染的胶团施放的毒云中时发出警告",

        -- [NEW] 新增中文本地化
        defiler_autotarget_cmd = "defiler_autotarget",
        defiler_autotarget_name = "自动转火污染者",
        defiler_autotarget_desc = "自动标记并切换目标到施放毒云的枯喉污染者。",

        ursa_command_cmd = "ursa_command",
        ursa_command_name = "巨熊的命令警报",
        ursa_command_desc = "当枯喉巨熊怪施放增益光环（狂暴可驱散）时发出警告",

        ursa_roar_cmd = "ursa_roar",
        ursa_roar_name = "巨熊的咆哮警报",
        ursa_roar_desc = "当枯喉巨熊怪开始施放范围恐惧时发出警告",

        totemic_stomp_cmd = "totemic_stomp",
        totemic_stomp_name = "战争践踏警报",
        totemic_stomp_desc = "当枯喉图腾师开始施放战争践踏时发出警告（待实测校准）",

        totemic_totem_cmd = "totemic_totem",
        totemic_totem_name = "堕落图腾警报",
        totemic_totem_desc = "当枯喉图腾师开始施放召唤堕落图腾时发出警告（待实测校准）",

        corruption_boils_cmd = "corruption_boils",
        corruption_boils_name = "黑脓疮提醒",
        corruption_boils_desc = "当落潭的腐根施放黑脓疮时发出警告以便驱散",

        corruption_euyonalia_cmd = "corruption_euyonalia",
        corruption_euyonalia_name = "恶液烂芽警报",
        corruption_euyonalia_desc = "当你被恶液烂芽影响时显示施法条和个人警报，以便在驱散前远离人群",

        son_rage_cmd = "son_rage",
        son_rage_name = "远古之怒警报",
        son_rage_desc = "当乌索尔之子进入狂暴状态时发出警告",

        trickster_siphon_cmd = "trickster_siphon",
        trickster_siphon_name = "腐心虹吸提醒",
        trickster_siphon_desc = "当玩家受到腐心诡术师的腐心虹吸警告",


        trigger_pathfinder_illumination = "枯喉探路者受到了灼烧启发效果的影响",
        msg_pathfinder_illumination = "探路者周围有火焰光环！",

        trigger_shaman_blessing = "(.+)获得了枯喉祝福的效果",
        msg_shaman_blessing = "%s物理免疫-驱散！",

        trigger_defiler_defiling = "(.+)受到了枯萎玷污效果的影响",
        msg_defiler_defiling = "离开团队！-枯萎玷污",
        msg_defiler_defilingOther = "%s中了枯萎玷污",
        bar_defiler_defiling = "枯萎玷污",
        say_defiler_defiling = "别靠近我-中了枯萎玷污！",
        trigger_defiler_cloud = "^你受到了毒云术效果的影响",
        trigger_defiler_cloudTick = "^你受到%d+点自然伤害（枯喉污染者的毒云术）",
        warn_defiler_cloud = "快离开",

        trigger_ursa_command = "枯喉巨熊怪获得了巨熊的命令的效果",
        msg_ursa_command = "巨熊怪增益光环激活-宁神射击！",
        trigger_ursa_roar = "枯喉巨熊怪开始施放巨熊的咆哮",
        bar_ursa_roar = "巨熊怪恐惧",

        -- 待实测校准：图腾师施法日志（来源：团本小助理规则库）
        trigger_totemic_stomp = "开始施放战争践踏",
        msg_totemic_stomp = "战争践踏——近战离开，大团靠墙！",
        trigger_totemic_totem = "开始施放召唤堕落图腾",
        msg_totemic_totem = "堕落图腾——远离，注意暗影新星！",

        trigger_corruption_boils = "(.+)受到了黑脓疮效果的影响",
        msg_corruption_boils = "%s中了黑脓疮-驱散他们！",
        trigger_corruption_euyonaliaCast = "落潭的腐根开始施放恶液烂芽",
        bar_corruption_euyonaliaCast = "范围疾病",
        trigger_corruption_euyonalia = "^你受到了恶液烂芽效果的影响",
        msg_corruption_euyonalia = "你中了恶液烂芽-驱散时会传播！",

        trigger_son_rage = "乌索尔之子获得了远古之怒的效果",
        msg_son_rage = "乌索尔之子狂暴-宁神射击！",

        trigger_trickster_siphon = "(.+)受到了腐心虹吸效果的影响",
        msg_trickster_siphon = "%s被吸血-驱散他们！",
    }
end)

-- timer and icon variables
local timer = {
    defiler_defiling = 12,
    ursa_command = 3,
    ursa_roar = 3,
    corruption_euyonaliaCast = 2,
}

local icon = {
    defiler_defiling = "Spell_Shadow_CreepingPlague",
    poisonCloud = "ABILITY_CREATURE_POISON_06",
    euyonalia = "Spell_Shadow_CallofBone",
    ursa_roar = "Ability_Druid_DemoralizingRoar",
}

local syncName = {
    defiler_defiling = "THDefilerDefiling" .. module.revision,
    corruption_boils = "THCorruptionBoils" .. module.revision,
    trickster_siphon = "THTricksterSiphon" .. module.revision,
    pathfinder_illumination = "THPathfinderIllumination" .. module.revision,
    ursa_command = "THUrsaCommand" .. module.revision,
    son_rage = "THSonRage" .. module.revision,
    shaman_blessing = "THShamanBlessing" .. module.revision,
    corruption_euyonaliaCast = "THCorruptionEuyonaliaCast" .. module.revision,
    ursa_roar = "THUrsaRoar" .. module.revision,
    totemic_stomp = "THTotemicStomp" .. module.revision,
    totemic_totem = "THTotemicTotem" .. module.revision,
}

local guid = {
    boss = "0xF13000FE7C279933",
}

local spellId = {
    one = 30196,
}

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "AfflictionEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "AfflictionEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "AfflictionEvent")

    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS", "EnemyBuffEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE", "EnemyBuffEvent")

    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE", "CastEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_CREATURE_VS_CREATURE_BUFF", "CastEvent")

    self:ThrottleSync(1, syncName.pathfinder_illumination)
    self:ThrottleSync(1, syncName.ursa_command)
    self:ThrottleSync(1, syncName.son_rage)
    self:ThrottleSync(1, syncName.shaman_blessing)
    self:ThrottleSync(1, syncName.corruption_euyonaliaCast)
    self:ThrottleSync(1, syncName.ursa_roar)
    self:ThrottleSync(3, syncName.totemic_stomp)
    self:ThrottleSync(3, syncName.totemic_totem)
end

function module:OnSetup()
end

function module:OnEngage()
end

function module:OnDisengage()
end

-- [MODIFIED] 修改 AfflictionEvent 以提取毒云施法者
function module:AfflictionEvent(msg)
    if string.find(msg, L["trigger_defiler_cloud"]) then
        self:PoisonCloud()  -- 没有施法者信息，直接调用
        return
    elseif string.find(msg, L["trigger_defiler_cloudTick"]) then
        -- 尝试提取施法者名称（英文和中文两种模式）
        -- 注意：Lua 5.0（1.12 客户端）没有 string.match，必须用 string.find 捕获
        local caster = nil
        -- 英文模式: "from <caster>'s Poison Cloud"
        local _, _, cEn = string.find(msg, "from (.+)'s Poison Cloud")
        if cEn then
            caster = cEn
        else
            -- 中文模式: "（<caster>的毒云术）"
            local _, _, cCn = string.find(msg, "（(.+)的毒云术）")
            if cCn then caster = cCn end
        end
        self:PoisonCloud(caster)  -- 传入提取到的施法者（可能为 nil）
        return
    elseif self.db.profile.corruption_euyonalia and string.find(msg, L["trigger_corruption_euyonalia"]) then
        self:Message(L["msg_corruption_euyonalia"], "Attention", true, "Alert")
        return
    end

    local _, _, player = string.find(msg, L["trigger_defiler_defiling"])
    if player then
        player = player == "你" and UnitName("player") or player
        self:Sync(syncName.defiler_defiling .. player)
        return
    end

    local _, _, player = string.find(msg, L["trigger_corruption_boils"])
    if player then
        player = player == "你" and UnitName("player") or player
        self:Sync(syncName.corruption_boils .. player)
        return
    end

    local _, _, player = string.find(msg, L["trigger_trickster_siphon"])
    if player then
        player = player == "你" and UnitName("player") or player
        self:Sync(syncName.trickster_siphon .. player)
        return
    end
end

function module:EnemyBuffEvent(msg)
    if string.find(msg, L["trigger_pathfinder_illumination"]) then
        self:Sync(syncName.pathfinder_illumination)
        return
    elseif string.find(msg, L["trigger_ursa_command"]) then
        self:Sync(syncName.ursa_command)
        return
    elseif string.find(msg, L["trigger_son_rage"]) then
        self:Sync(syncName.son_rage)
        return
    end
    local _, _, mob = string.find(msg, L["trigger_shaman_blessing"])
    if mob then
        self:Sync(syncName.shaman_blessing .. " " .. mob)
        return
    end
    local _, _, pet = string.find(msg, L["trigger_defiler_defiling"])
    if pet then
        self:Sync(syncName.defiler_defiling .. pet)
        return
    end
end

function module:CastEvent(msg)
    if string.find(msg, L["trigger_corruption_euyonaliaCast"]) then
        self:Sync(syncName.corruption_euyonaliaCast)
        return
    elseif string.find(msg, L["trigger_ursa_roar"]) then
        self:Sync(syncName.ursa_roar)
        return
    elseif string.find(msg, L["trigger_totemic_stomp"]) then
        self:Sync(syncName.totemic_stomp)
        return
    elseif string.find(msg, L["trigger_totemic_totem"]) then
        self:Sync(syncName.totemic_totem)
        return
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    local _, _, player = string.find(sync, syncName.defiler_defiling .. "(.+)")
    if player then
        self:WitheredDefiling(player)
        return
    end
    local _, _, player = string.find(sync, syncName.corruption_boils .. "(.+)")
    if player and self.db.profile.corruption_boils then
        self:Message(string.format(L["msg_corruption_boils"],player), "Attention")
        return
    end
    local _, _, player = string.find(sync, syncName.trickster_siphon .. "(.+)")
    if player and self.db.profile.trickster_siphon then
        self:Message(string.format(L["msg_trickster_siphon"],player), "Attention")
        return
    end

    if self.db.profile.pathfinder_illumination and sync == syncName.pathfinder_illumination then
        self:Message(L["msg_pathfinder_illumination"], "Urgent")
        return
    elseif self.db.profile.ursa_command and sync == syncName.ursa_command then
        self:Message(L["msg_ursa_command"], "Attention")
        return
    elseif self.db.profile.son_rage and sync == syncName.son_rage then
        self:Message(L["msg_son_rage"], "Urgent")
        return
    elseif self.db.profile.shaman_blessing and sync == syncName.shaman_blessing and rest then
        self:Message(string.format(L["msg_shaman_blessing"],rest), "Attention", nil, "Alert")
        return
    elseif self.db.profile.corruption_euyonalia and sync == syncName.corruption_euyonaliaCast then
        self:Bar(L["bar_corruption_euyonaliaCast"], timer.corruption_euyonaliaCast, icon.euyonalia, true, "Yellow")
        self:Sound("Beware")
        return
    elseif self.db.profile.ursa_roar and sync == syncName.ursa_roar then
        self:Bar(L["bar_ursa_roar"], timer.ursa_roar, icon.ursa_roar, true, "Cyan")
        self:Sound("Alarm")
        return
    elseif self.db.profile.totemic_stomp and sync == syncName.totemic_stomp then
        self:Message(L["msg_totemic_stomp"], "Urgent", nil, "Alarm")
        return
    elseif self.db.profile.totemic_totem and sync == syncName.totemic_totem then
        self:Message(L["msg_totemic_totem"], "Attention")
        return
    end
end

-- [MODIFIED] 修改 PoisonCloud 函数，增加施法者参数和自动转火标记功能
function module:PoisonCloud(caster)
    if not self.db.profile.defiler_cloud then return end

    self:WarningSign(icon.poisonCloud, 1, false, L["warn_defiler_cloud"])
    self:Sound("voiceOut")

    -- [NEW] 自动标记并转火施法者（如果提供了施法者名称且选项开启）
    if caster and self.db.profile.defiler_autotarget then
        -- 如果当前目标不是该施法者，则切换目标
        if UnitName("target") ~= caster then
            TargetByName(caster, true)
        end
        -- 如果切换成功且当前目标匹配，设置团队标记
        if UnitName("target") == caster then
            local mark = self:GetAvailableRaidMark()
            if mark then
                SetRaidTarget("target", mark)
                -- 5秒后清除标记（避免占用）
                self:ScheduleEvent("ClearDefilerMark_" .. caster, function()
                    if UnitName("target") == caster then
                        SetRaidTarget("target", 0)
                    end
                end, 5)
            end
        end
    end
end

function module:WitheredDefiling(player)
    if player == UnitName("player") and self.db.profile.defiler_defiling then
        self:Message(L["msg_defiler_defiling"], "Important", true, "voiceOut")
        self:Bar(L["bar_defiler_defiling"], timer.defiler_defiling, icon.defiler_defiling, true, "Red")
        SendChatMessage(L["say_defiler_defiling"], "SAY")
    elseif self.db.profile.defiler_defilingother then
        self:Message(string.format(L["msg_defiler_defilingOther"],player), "Urgent")
    end
    if self.db.profile.defiler_defilingmark then
        local markToUse = self:GetAvailableRaidMark()
        if markToUse then
            self:SetRaidTargetForPlayer(player, markToUse)
            self:ScheduleEvent("RemoveDefilingMark"..player, self.RestoreInitialRaidTargetForPlayer, timer.defiler_defiling, self, player)
        end
    end
end