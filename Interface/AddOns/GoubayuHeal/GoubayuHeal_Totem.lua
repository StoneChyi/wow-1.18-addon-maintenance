-- ============================================================
-- 文件名: GoubayuHeal_Totem.lua
-- 功能: 萨满祭司一键图腾功能
--       包含图腾数据定义、配置管理、计时器跟踪、
--       图腾框架UI、一键放置（5种预设模式）
-- ============================================================

-- ============================================================
-- 常量与类型定义
-- ============================================================

-- 真实时间（wall clock 秒，跨 reload/重登持续）：WoW 1.12 客户端无 os 库，
-- 用原生全局 time()；极端环境缺失时退化为 GetTime()（仅会话内有效，不崩溃）
local function Totem_WallTime()
    if time then
        return time()
    end
    return GetTime()
end

-- 图腾类型枚举
local totemTypes = {
    FIRE = 1,
    WATER = 2,
    EARTH = 3,
    AIR = 4
}


-- 按钮尺寸
local BUTTON_SIZE = 40

-- 元素名常量表：热路径（图腾条显示期间每0.1s）原样每次新建4元素表纯浪费，
-- 提升为文件级共享只读表 by 武藤纯子酱 2026.9.4
local TOTEM_ELEMENT_NAMES = { "Fire", "Water", "Earth", "Air" }

-- 预设配置选项
local TOTEM_PRESET_OPTION_1 = 1

-- ============================================================
-- 图标资源
-- ============================================================

-- 不使用图腾的占位图标
local SKIP_TOTEM_ICONS = {
    "Interface\\Icons\\INV_Misc_QirajiCrystal_02", -- 火
    "Interface\\Icons\\INV_Misc_QirajiCrystal_04", -- 水
    "Interface\\Icons\\INV_Misc_QirajiCrystal_01", -- 土
    "Interface\\Icons\\INV_Misc_QirajiCrystal_03"  -- 风
}

-- 预设选项图标
local PRESET_ICONS = {
    "Interface\\Icons\\INV_Misc_PunchCards_Prismatic", -- 1. 智能补充
    "Interface\\Icons\\INV_Misc_PunchCards_Blue",      -- 2. 超出范围先回收再全部补充
    "Interface\\Icons\\INV_Misc_PunchCards_White",     -- 3. 缺哪个图腾补哪个图腾，不回收
    "Interface\\Icons\\INV_Misc_PunchCards_Yellow",    -- 4. 全部超范围自动回收，不补充
    "Interface\\Icons\\INV_Misc_PunchCards_Red",       -- 5. 什么也不做
    "Interface\\Icons\\INV_Misc_Note_01"               -- 6. 尊重手动图腾（位上有任何图腾就不动）
}

-- ============================================================
-- 图腾数据表（火水土风顺序，1.12版本真实技能）
-- ============================================================

local GoubayuHeal_TotemData = {
    [totemTypes.FIRE] = {
        { name = GoubayuHeal.TotemData.Searing, icon = "Interface\\Icons\\Spell_Fire_SearingTotem", cooldown = 0, duration = 55, skip = false },
        { name = GoubayuHeal.TotemData.FireNova, icon = "Interface\\Icons\\Spell_Fire_SealOfFire", cooldown = 15, duration = 5, skip = false },
        { name = GoubayuHeal.TotemData.Magma, icon = "Interface\\Icons\\Spell_Fire_SelfDestruct", cooldown = 0, duration = 20, skip = false },
        { name = GoubayuHeal.TotemData.FrostRes, icon = "Interface\\Icons\\Spell_FrostResistanceTotem_01", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.FlameTongue, icon = "Interface\\Icons\\Spell_Nature_GuardianWard", cooldown = 0, duration = 120, skip = false }
    },
    [totemTypes.WATER] = {
        { name = GoubayuHeal.TotemData.ManaSpring, icon = "Interface\\Icons\\Spell_Nature_ManaRegenTotem", cooldown = 0, duration = 60, skip = false },
        { name = GoubayuHeal.TotemData.HealingStream, icon = "Interface\\Icons\\INV_Spear_04", cooldown = 0, duration = 60, skip = false },
        { name = GoubayuHeal.TotemData.FireRes, icon = "Interface\\Icons\\Spell_FireResistanceTotem_01", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.PoisonCleansing, icon = "Interface\\Icons\\Spell_Nature_PoisonCleansingTotem", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.DiseaseCleansing, icon = "Interface\\Icons\\Spell_Nature_DiseaseCleansingTotem", cooldown = 0, duration = 120, skip = false }
    },
    [totemTypes.EARTH] = {
        { name = GoubayuHeal.TotemData.Earthbind, icon = "Interface\\Icons\\Spell_Nature_StrengthOfEarthTotem02", cooldown = 15, duration = 45, skip = false },
        { name = GoubayuHeal.TotemData.Tremor, icon = "Interface\\Icons\\Spell_Nature_TremorTotem", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.StrengthOfEarth, icon = "Interface\\Icons\\Spell_Nature_EarthBindTotem", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.Stoneskin, icon = "Interface\\Icons\\Spell_Nature_StoneSkinTotem", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.Stoneclaw, icon = "Interface\\Icons\\Spell_Nature_StoneClawTotem", cooldown = 30, duration = 15, skip = false }
    },
    [totemTypes.AIR] = {
        { name = GoubayuHeal.TotemData.TranquilAir, icon = "Interface\\Icons\\Spell_Nature_Brilliance", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.Grounding, icon = "Interface\\Icons\\Spell_Nature_GroundingTotem", cooldown = 20, duration = 45, skip = false },
        { name = GoubayuHeal.TotemData.Windfury, icon = "Interface\\Icons\\Spell_Nature_Windfury", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.GraceOfAir, icon = "Interface\\Icons\\Spell_Nature_InvisibilityTotem", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.NatureRes, icon = "Interface\\Icons\\Spell_Nature_NatureResistanceTotem", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.Windwall, icon = "Interface\\Icons\\Spell_Nature_EarthBind", cooldown = 0, duration = 120, skip = false },
        { name = GoubayuHeal.TotemData.Sentry, icon = "Interface\\Icons\\Spell_Nature_RemoveCurse", cooldown = 0, duration = 300, skip = false }
    }
}

-- ============================================================
-- 状态变量
-- ============================================================

-- 防止多次初始化
local GoubayuHeal_Totem_Initialized = false

-- 当前显示的备选按钮元素
local GoubayuHeal_Totem_CurrentElement = nil

-- 隐藏备选按钮的延迟计时器
local GoubayuHeal_Totem_HideTimer = nil

-- 图腾掌握天赋缓存
local GoubayuHeal_Totem_MasteryCached = nil

-- ============================================================
-- 不判断范围的技能列表（这些技能只看持续时间，不看buff范围）
-- ============================================================

local SKIP_RANGE_CHECK_TOTEMS = GoubayuHeal.TotemSkipRangeList

-- ============================================================
-- 图腾技能名到Buff名的映射
-- ============================================================

local TOTEM_TO_BUFF_MAP = GoubayuHeal.TotemBuffMap

-- ============================================================
-- 工具函数
-- ============================================================

-- 获取图腾对应的Buff名称
local function GetTotemBuffName(totemName)
    return TOTEM_TO_BUFF_MAP[totemName] or totemName
end

-- 检查技能是否需要跳过范围判断
local function ShouldSkipRangeCheck(totemName)
    for i, name in ipairs(SKIP_RANGE_CHECK_TOTEMS) do
        if name == totemName then
            return true
        end
    end
    return false
end

-- 净化图腾净化半径（码）：图腾覆盖判定与此处重插逻辑共用
GoubayuHeal.Totem_CleanseRange = 26

-- ============================================================
-- Nampower光环快路径：按buff名检测玩家是否拥有对应增益
-- ============================================================

local GoubayuHeal_Totem_BuffIdCache = {}

-- 阴性结果 TTL 缓存：图腾不在身上（未放置/超范围）时原实现每次调用都全 48 槽
-- pcall 反查名字（已缓存ID未命中还会再全重扫一遍），图腾条显示期间 10Hz×4 元素是常驻热点；
-- 0.5s TTL 内直接返回 false，施放图腾时由 Totem_StartCastTimer 主动清除，避免重复施放
-- by 武藤纯子酱 2026.9.4
local GoubayuHeal_Totem_BuffNegCache = {}
local TOTEM_BUFF_NEG_TTL = 0.5

function GoubayuHeal.Totem_HasBuff(buffName)
    if not (GetNampowerVersion and GetUnitField and GetSpellNameAndRankForId) then
        return nil
    end

    local now = GetTime()
    local negUntil = GoubayuHeal_Totem_BuffNegCache[buffName]
    if negUntil and now < negUntil then
        return false
    end

    local cachedId = GoubayuHeal_Totem_BuffIdCache[buffName]
    if not cachedId then
        local auras = GetUnitField("player", "aura")
        if auras then
            for i = 1, 48 do
                local id = auras[i]
                if id and id ~= 0 then
                    local ok, name = pcall(GetSpellNameAndRankForId, id)
                    if ok and name then
                        -- 去等级后缀后比对（反查名可能带"(等级 x)"，buffName是干净名）
                        name = string.gsub(name, "%s*%(.*%)", "")
                        if name == buffName then
                            GoubayuHeal_Totem_BuffIdCache[buffName] = id
                            GoubayuHeal_Totem_BuffNegCache[buffName] = nil
                            return true
                        end
                    end
                end
            end
        end
        GoubayuHeal_Totem_BuffNegCache[buffName] = now + TOTEM_BUFF_NEG_TTL
        return false
    end

    local auras = GetUnitField("player", "aura")
    if auras then
        for i = 1, 48 do
            if auras[i] == cachedId then
                GoubayuHeal_Totem_BuffNegCache[buffName] = nil
                return true
            end
        end
        -- 缓存ID未命中：同名异源/不同等级的同类图腾会覆盖aura（spellId不同），
        -- 按名重扫一次并刷新缓存（否则误判"图腾不在范围"导致红字/重复施放）
        for i = 1, 48 do
            local id = auras[i]
            if id and id ~= 0 then
                local ok, name = pcall(GetSpellNameAndRankForId, id)
                if ok and name then
                    name = string.gsub(name, "%s*%(.*%)", "")
                    if name == buffName then
                        GoubayuHeal_Totem_BuffIdCache[buffName] = id
                        GoubayuHeal_Totem_BuffNegCache[buffName] = nil
                        return true
                    end
                end
            end
        end
    end
    GoubayuHeal_Totem_BuffNegCache[buffName] = now + TOTEM_BUFF_NEG_TTL
    return false
end

-- 统一的图腾buff检测（Nampower快路径，不可用时回退原生API）
local function IsTotemBuffActive(buffName)
    local has = GoubayuHeal.Totem_HasBuff(buffName)
    if has ~= nil then
        return has
    end
    return GoubayuHeal.HasBuffByName("player", buffName)
end

-- ============================================================
-- 图腾持续时间和冷却时间跟踪
-- ============================================================

GoubayuHeal.Totem_Timers = {
    [1] = { durationStart = 0, duration = 0 }, -- 火
    [2] = { durationStart = 0, duration = 0 }, -- 水
    [3] = { durationStart = 0, duration = 0 }, -- 土
    [4] = { durationStart = 0, duration = 0 }  -- 风
}

-- 每个图腾技能自己的冷却状态：totemName → 上次施放时间（GetTime 基准）
-- 冷却按具体图腾独立计算（根基图腾20s只锁自己，
-- 无CD的风怒图腾随时可施放），不做元素级共享锁
GoubayuHeal.Totem_CastedAt = GoubayuHeal.Totem_CastedAt or {}

-- 名称→冷却 秒 懒构建索引：Totem_GetCooldownRemaining 原实现对整个 TotemData
-- 线性扫描，被 0.1s 计时分支嵌套调用（元素数×图腾数×10Hz），建一次索引即 O(1)
-- by 武藤纯子酱 2026.9.4
local GoubayuHeal_TotemCDByName = nil
local function GoubayuHeal_Totem_BuildCDIndex()
    if GoubayuHeal_TotemCDByName then
        return GoubayuHeal_TotemCDByName
    end
    local map = {}
    for _, elementData in ipairs(GoubayuHeal_TotemData) do
        for _, t in ipairs(elementData) do
            if t.name and map[t.name] == nil then
                map[t.name] = t.cooldown or 0
            end
        end
    end
    GoubayuHeal_TotemCDByName = map
    return map
end

-- 具体图腾技能的剩余冷却（秒），无冷却/已过/未记录返回 0
function GoubayuHeal.Totem_GetCooldownRemaining(totemName)
    local casted = GoubayuHeal.Totem_CastedAt and GoubayuHeal.Totem_CastedAt[totemName]
    if not casted then
        return 0
    end
    local cd = GoubayuHeal_Totem_BuildCDIndex()[totemName] or 0
    if cd <= 0 then
        return 0
    end
    local remaining = casted + cd - GetTime()
    if remaining > 0 then
        return remaining
    end
    return 0
end

-- 本元素最近放置的带CD图腾的最大剩余冷却（秒）——按钮CD显示用：
-- 每个图腾独立CD，取元素内所有带CD图腾中最大的剩余值（如先后放根基20s+风怒0s，
-- 按钮显示根基剩余CD；即使当前选中的是无CD图腾，按钮也照常显示已放置图腾的CD；
-- 召回不清除CD记录，reload后重放再召回也能正确显示）
function GoubayuHeal.Totem_GetElementMaxCooldownRemaining(elementIndex)
    local maxRemaining = 0
    local elementData = GoubayuHeal_TotemData and GoubayuHeal_TotemData[elementIndex]
    if elementData then
        for _, t in ipairs(elementData) do
            if t.cooldown and t.cooldown > 0 then
                local r = GoubayuHeal.Totem_GetCooldownRemaining(t.name)
                if r > maxRemaining then
                    maxRemaining = r
                end
            end
        end
    end
    return maxRemaining
end

-- 图腾回收（Totemic Recall）剩余冷却（秒）：未学会/无冷却返回 0。
-- 回收是与"一键放置"配套的长CD技能，显示在放置按钮上，便于判断能否"回收后重放"。
-- 取 start/duration 两个值判断：duration<=1.6 才是公共冷却（不显示）；
-- 真实冷却按剩余时间一直倒数到 0（不能按"剩余<=1.6"过滤，否则最后 1~2 秒会被吞掉）。
-- by 武藤纯子酱 2026.10.20
function GoubayuHeal.Totem_GetRecallCooldownRemaining()
    local name = GoubayuHeal.Spell and GoubayuHeal.Spell.TotemRecall
    if not (name and GoubayuHeal.GetSpellBookSlot) then
        return 0
    end
    local slot = GoubayuHeal.GetSpellBookSlot(name)
    if not slot then
        return 0
    end
    local ok, start, duration = pcall(GetSpellCooldown, slot, BOOKTYPE_SPELL)
    if not ok or not start or not duration or duration <= 0 then
        return 0
    end
    if duration <= 1.6 then
        return 0
    end
    local remain = start + duration - GetTime()
    if remain <= 0 then
        return 0
    end
    return remain
end

-- ============================================================
-- 配置管理
-- ============================================================

-- 初始化图腾配置
function GoubayuHeal.Totem_Initialize()
    if not GoubayuHeal.Config then
        GoubayuHeal.Config = GoubayuHeal_Data or {}
        if GoubayuHeal_Data then
            GoubayuHeal_Data = GoubayuHeal.Config
        end
    end

    -- 恢复未过期的图腾CD记录（持久化为wall clock秒；reload/重登后还原剩余CD，
    -- 防止服务器端CD中的图腾被CanCastTotem放行误发）
    if GoubayuHeal_Data and GoubayuHeal_Data["totem_casted_wall"] then
        local nowWall = Totem_WallTime()
        for totemName, wall in pairs(GoubayuHeal_Data["totem_casted_wall"]) do
            local cd = 0
            for _, elementData in ipairs(GoubayuHeal_TotemData) do
                for _, t in ipairs(elementData) do
                    if t.name == totemName then
                        cd = t.cooldown or 0
                        break
                    end
                end
                if cd > 0 then break end
            end
            local remaining = wall + cd - nowWall
            if cd > 0 and remaining > 0 then
                GoubayuHeal.Totem_CastedAt[totemName] = GetTime() - (cd - remaining)
            else
                GoubayuHeal_Data["totem_casted_wall"][totemName] = nil
            end
        end
    end

    -- 如果配置不存在，创建默认配置
    if not GoubayuHeal.Config["shaman_totem"] then
        GoubayuHeal.Config["shaman_totem"] = {
            enabled = 0,
            onekey = 0,
            keep_water_shield = 0,
            locked = false,
            fine = {
                enabled = 0,
                revertAfterCombat = 0,
                selfPoison = 0,
                selfDisease = 0,
                rules = GoubayuHeal.Totem_FineDefaultRules and GoubayuHeal.Totem_FineDefaultRules() or {}
            },
            elements = {
                Fire = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Water = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Earth = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Air = { max = 7, shown = 1, skip = false, selectedIndex = 1 }
            },
            appearance = {
                direction = "up",
                scale = 1,
                showtooltips = true
            },
            order = {
                first = "Fire",
                second = "Water",
                third = "Earth",
                forth = "Air"
            },
            totems = {},
            placePreset = TOTEM_PRESET_OPTION_1,
            position = { x = 0, y = 0, xOffset = 0, yOffset = 0 }
        }
    elseif type(GoubayuHeal.Config["shaman_totem"]) == "number" then
        -- 旧格式转换
        local oldEnabled = GoubayuHeal.Config["shaman_totem"]
        GoubayuHeal.Config["shaman_totem"] = {
            enabled = oldEnabled,
            onekey = 0,
            keep_water_shield = 0,
            locked = false,
            fine = {
                enabled = 0,
                revertAfterCombat = 0,
                selfPoison = 0,
                selfDisease = 0,
                rules = GoubayuHeal.Totem_FineDefaultRules and GoubayuHeal.Totem_FineDefaultRules() or {}
            },
            elements = {
                Fire = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Water = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Earth = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Air = { max = 7, shown = 1, skip = false, selectedIndex = 1 }
            },
            appearance = {
                direction = "up",
                scale = 1,
                showtooltips = true
            },
            order = {
                first = "Fire",
                second = "Water",
                third = "Earth",
                forth = "Air"
            },
            totems = {},
            placePreset = TOTEM_PRESET_OPTION_1,
            position = { x = 0, y = 0, xOffset = 0, yOffset = 0 }
        }
    else
        -- 兼容性检查：确保各个字段存在，但不覆盖已有值
        local cfg = GoubayuHeal.Config["shaman_totem"]
        if cfg.enabled == nil then
            cfg.enabled = 0
        end
        if cfg.onekey == nil then
            cfg.onekey = 0
        end
        if cfg.keep_water_shield == nil then
            cfg.keep_water_shield = 0
        end
        if cfg.locked == nil then
            cfg.locked = false
        end

        if not cfg.appearance then
            cfg.appearance = {
                direction = "up",
                scale = 1,
                showtooltips = true
            }
        else
            if cfg.appearance.scale == nil then
                cfg.appearance.scale = 1
            end
            if cfg.appearance.direction == nil then
                cfg.appearance.direction = "up"
            end
            if cfg.appearance.showtooltips == nil then
                cfg.appearance.showtooltips = true
            end
        end

        if not cfg.elements then
            cfg.elements = {
                Fire = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Water = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Earth = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Air = { max = 7, shown = 1, skip = false, selectedIndex = 1 }
            }
        else
            -- 补全缺失的元素键（旧存档/手工编辑可能缺键，下游裸索引会崩溃）
            local elementDefaults = {
                Fire = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Water = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Earth = { max = 5, shown = 1, skip = false, selectedIndex = 1 },
                Air = { max = 7, shown = 1, skip = false, selectedIndex = 1 }
            }
            for element, def in pairs(elementDefaults) do
                if not cfg.elements[element] then
                    cfg.elements[element] = def
                end
            end
            for element, data in pairs(cfg.elements) do
                if data.selectedIndex == nil then
                    data.selectedIndex = 1
                end
                if data.skip == nil then
                    data.skip = false
                end
            end
        end

        -- 仅缺省时初始化（此前无条件覆盖，用户的自定义排序被每次重置）
        if cfg.order == nil then
            cfg.order = {
                first = "Fire",
                second = "Water",
                third = "Earth",
                forth = "Air"
            }
        end

        if cfg.placePreset == nil then
            cfg.placePreset = TOTEM_PRESET_OPTION_1
        end
    end
end

-- ============================================================
-- 图腾掌握天赋检测
-- ============================================================

local GoubayuHeal_Totem_MasteryPos = { 3, 8 } -- 恢复系 页3 idx8

-- 天赋/技能点变化时清缓存
function GoubayuHeal.Totem_ResetMasteryCache()
    GoubayuHeal_Totem_MasteryCached = nil
end

-- 获取图腾掌握天赋加成（+20%持续时间）
function GoubayuHeal.Totem_GetMasteryBonus()
    if GoubayuHeal_Totem_MasteryCached ~= nil then
        return GoubayuHeal_Totem_MasteryCached
    end

    local bonus = 0
    if GoubayuHeal.my_class == GoubayuHeal.Shaman and GetTalentInfo then
        -- pcall保护：冷启动天赋数据未就绪时GetTalentInfo会抛错（与主文件同口径），
        -- 否则该次施放的duration/CastedAt登记全部丢失且每次施放重复抛错
        local ok, _, _, _, _, rank = pcall(GetTalentInfo,
            GoubayuHeal_Totem_MasteryPos[1], GoubayuHeal_Totem_MasteryPos[2])
        if ok and rank and rank > 0 then
            bonus = 0.20
        end
    end
    GoubayuHeal_Totem_MasteryCached = bonus
    return bonus
end

-- ============================================================
-- 图腾框架：初始化与事件绑定
-- ============================================================

function GoubayuHeal.Totem_OnLoad()
    if GoubayuHeal_Totem_Initialized then
        return
    end
    GoubayuHeal_Totem_Initialized = true

    -- 真实图腾存活追踪状态（GUID级）：待确认的召唤单位 / 已确认放置的图腾
    GoubayuHeal.Totem_PendingSummons = GoubayuHeal.Totem_PendingSummons or {}
    GoubayuHeal.Totem_ActivePlacedTotems = GoubayuHeal.Totem_ActivePlacedTotems or {}

    local _, class = UnitClass("player")
    if class ~= "SHAMAN" then
        GoubayuHeal_TotemFrame:Hide()
        return
    end

    GoubayuHeal.Totem_Initialize()

GoubayuHeal_TotemFrame:RegisterEvent("VARIABLES_LOADED")
GoubayuHeal_TotemFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
GoubayuHeal_TotemFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
GoubayuHeal_TotemFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
GoubayuHeal_TotemFrame:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
GoubayuHeal_TotemFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
-- 脱战后回收图腾（精细图腾管理选项）
-- by 武藤纯子酱 2026.9.21
    GoubayuHeal_TotemFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    -- Nampower 真实图腾存活追踪事件
    GoubayuHeal_TotemFrame:RegisterEvent("SPELL_GO_SELF")
    GoubayuHeal_TotemFrame:RegisterEvent("UNIT_MODEL_CHANGED_GUID")

    -- 启用鼠标滚轮
    GoubayuHeal_TotemFrame:EnableMouseWheel(true)
    GoubayuHeal_TotemFrame:SetScript("OnMouseWheel", GoubayuHeal.Totem_OnMouseWheel)

    -- 创建时间更新框架
    if not GoubayuHeal_TotemTimerFrame then
        GoubayuHeal_TotemTimerFrame = CreateFrame("Frame", nil, UIParent)
        GoubayuHeal_TotemTimerFrame:SetScript("OnUpdate", GoubayuHeal.Totem_OnTimerUpdate)
        GoubayuHeal_TotemTimerFrame.TimeSinceLastUpdate = 0
        GoubayuHeal_TotemTimerFrame.TimeSinceClock = 0
    end

    -- 战斗状态轮询帧（常驻，不依赖图腾窗口是否显示）：用于"战斗结束后回收图腾"的兜底触发
    -- by 武藤纯子酱 2026.9.24
    if not GoubayuHeal_TotemCombatFrame then
        GoubayuHeal_TotemCombatFrame = CreateFrame("Frame", nil, UIParent)
        GoubayuHeal_TotemCombatFrame.acc = 0
        GoubayuHeal_TotemCombatFrame:SetScript("OnUpdate", function()
            this.acc = (this.acc or 0) + arg1
            if this.acc < 0.5 then
                return
            end
            this.acc = 0
            if GoubayuHeal.Totem_CombatPoll then
                pcall(GoubayuHeal.Totem_CombatPoll)
            end
        end)
    end

    -- 设置字体样式
    GoubayuHeal.Totem_SetupFonts()

    GoubayuHeal.Totem_UpdateOrder()
    GoubayuHeal.Totem_UpdateTextures()
    GoubayuHeal.Totem_PositionSpecialButtons()
    GoubayuHeal.Totem_ApplyScale()
    GoubayuHeal.Totem_ToggleFrame()

    print("|cffFF9000[GoubayuHeal]|r " .. GoubayuHeal.Msg.TotemFrameLoaded)
end

-- ============================================================
-- 字体设置
-- ============================================================

function GoubayuHeal.Totem_SetupFonts()
    local elements = TOTEM_ELEMENT_NAMES

    for i, element in ipairs(elements) do
        local durationText = _G["GoubayuHeal_TotemButton_" .. element .. "1DurationText"]
        local cooldownText = _G["GoubayuHeal_TotemButton_" .. element .. "1CooldownText"]

        if durationText then
            durationText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
            durationText:SetShadowColor(0, 0, 0, 1)
            durationText:SetShadowOffset(1, -1)
        end

        if cooldownText then
            cooldownText:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
            cooldownText:SetShadowColor(0, 0, 0, 1)
            cooldownText:SetShadowOffset(1, -1)
        end
    end

    -- 一键放置按钮：图腾回收CD倒计时（与图腾倒计时同字号）
    -- by 武藤纯子酱 2026.10.20
    local placeCD = _G["GoubayuHeal_TotemButton_PlaceCooldownText"]
    if placeCD then
        placeCD:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
        placeCD:SetShadowColor(0, 0, 0, 1)
        placeCD:SetShadowOffset(1, -1)
    end
end

-- ============================================================
-- 时间更新（持续时间/冷却时间显示）
-- ============================================================

function GoubayuHeal.Totem_OnTimerUpdate()
    local elapsed = arg1 or 0
    this.TimeSinceLastUpdate = this.TimeSinceLastUpdate + elapsed
    this.TimeSinceClock = (this.TimeSinceClock or 0) + elapsed

    if not GoubayuHeal_TotemFrame or not GoubayuHeal_TotemFrame:IsShown() then
        return
    end

    -- 低频任务（每0.5秒）：真实图腾存活追踪（GUID级死亡检测）+ 覆盖检测（距离计算较重）
    if this.TimeSinceLastUpdate >= 0.5 then
        if GoubayuHeal.Totem_CheckSummonedUnits then
            pcall(GoubayuHeal.Totem_CheckSummonedUnits)
        end
        if GoubayuHeal.Totem_UpdateTotemCoverage then
            pcall(GoubayuHeal.Totem_UpdateTotemCoverage)
        end
        -- 脱战检测（轮询兜底）：某些环境/插件组合下 PLAYER_REGEN_ENABLED 不会送到本帧，
        -- 这里用战斗状态跳变（战斗中→脱战）触发"战斗结束后回收图腾"
        -- by 武藤纯子酱 2026.9.24
        if GoubayuHeal.Totem_CombatPoll then
            pcall(GoubayuHeal.Totem_CombatPoll)
        end
        this.TimeSinceLastUpdate = 0
    end

    -- 高频计时显示（每0.1秒）：持续时间/冷却倒计时文本实时更新，避免约1秒的显示延迟
    if this.TimeSinceClock < 0.1 then
        return
    end
    this.TimeSinceClock = 0

    local elements = TOTEM_ELEMENT_NAMES

    for i = 1, 4 do
        local button = _G["GoubayuHeal_TotemButton_" .. elements[i] .. "1"]
        if button then
            local durationText = _G["GoubayuHeal_TotemButton_" .. elements[i] .. "1DurationText"]
            local cooldownText = _G["GoubayuHeal_TotemButton_" .. elements[i] .. "1CooldownText"]

            -- 检查图腾是否在范围内
            local inRange = GoubayuHeal.Totem_IsInRange(i)

            -- 计算剩余时间
            local timer = GoubayuHeal.Totem_Timers[i]
            local now = GetTime()

            -- CD显示：本元素最近放置的带CD图腾的最大剩余冷却（按具体图腾独立CD，
            -- 与当前选中图腾是否有CD无关——reload后重放再召回也能正确显示）
            local remainingCooldown = GoubayuHeal.Totem_GetElementMaxCooldownRemaining(i)

            -- 首先检查持续时间
            if timer.durationStart > 0 and timer.duration > 0 then
                local remainingDuration = timer.durationStart + timer.duration - now
                if remainingDuration > 0 then
                    if durationText then
                        durationText:SetText(format("%.0f", remainingDuration))
                        if inRange then
                            durationText:SetTextColor(1, 1, 1)
                        else
                            durationText:SetTextColor(1, 0, 0)
                        end
                        durationText:Show()
                    end
                    if cooldownText then
                        cooldownText:Hide()
                    end
                else
                    -- 持续时间结束，切换到冷却时间
                    timer.durationStart = 0
                    if durationText then
                        durationText:Hide()
                    end
                    if remainingCooldown > 0 then
                        if cooldownText then
                            cooldownText:SetText(format("%.0f", remainingCooldown))
                            if inRange then
                                cooldownText:SetTextColor(1, 0.72, 0.3)
                            else
                                cooldownText:SetTextColor(1, 0, 0)
                            end
                            cooldownText:Show()
                        end
                    else
                        if cooldownText then
                            cooldownText:Hide()
                        end
                    end
                end
            elseif remainingCooldown > 0 then
                if cooldownText then
                    cooldownText:SetText(format("%.0f", remainingCooldown))
                    if inRange then
                        cooldownText:SetTextColor(1, 0.72, 0.3)
                    else
                        cooldownText:SetTextColor(1, 0, 0)
                    end
                    cooldownText:Show()
                end
                if durationText then
                    durationText:Hide()
                end
            else
                if durationText then
                    durationText:Hide()
                end
                if cooldownText then
                    cooldownText:Hide()
                end
            end
        end
    end

    -- 一键放置按钮：显示"图腾回收"剩余冷却（回收可用时隐藏）
    -- by 武藤纯子酱 2026.10.20
    local placeCD = _G["GoubayuHeal_TotemButton_PlaceCooldownText"]
    if placeCD then
        local recallCd = 0
        if GoubayuHeal.Totem_GetRecallCooldownRemaining then
            recallCd = GoubayuHeal.Totem_GetRecallCooldownRemaining()
        end
        if recallCd > 0 then
            placeCD:SetText(format("%.0f", recallCd))
            placeCD:SetTextColor(1, 0.72, 0.3)
            placeCD:Show()
        else
            placeCD:Hide()
        end
    end
end

-- ============================================================
-- 鼠标滚轮缩放
-- ============================================================

function GoubayuHeal.Totem_OnMouseWheel()
    if not GoubayuHeal.Config or not GoubayuHeal.Config["shaman_totem"] then
        return
    end

    local oldScale = GoubayuHeal.Config["shaman_totem"].appearance.scale or 1
    local delta = tonumber(arg1) or 0

    local newScale = oldScale + delta * 0.1
    if newScale < 0.5 then
        newScale = 0.5
    end
    if newScale > 2.0 then
        newScale = 2.0
    end

    if newScale ~= oldScale then
        GoubayuHeal.Config["shaman_totem"].appearance.scale = newScale
        GoubayuHeal_TotemFrame:SetScale(newScale)
        GoubayuHeal.Totem_SaveFramePosition()
    end
end

-- ============================================================
-- 框架显示/更新
-- ============================================================

function GoubayuHeal.Totem_ApplyScale()
    if not GoubayuHeal.Config or not GoubayuHeal.Config["shaman_totem"] then
        return
    end
    local scale = GoubayuHeal.Config["shaman_totem"].appearance.scale or 1
    GoubayuHeal_TotemFrame:SetScale(scale)
end

function GoubayuHeal.Totem_OnShow()
    GoubayuHeal.Totem_UpdateTextures()
end

function GoubayuHeal.Totem_ToggleFrame()
    if not GoubayuHeal.Config or not GoubayuHeal.Config["shaman_totem"] then
        GoubayuHeal.Totem_Initialize()
    end

    if GoubayuHeal.Config["shaman_totem"].enabled == 1 then
        GoubayuHeal_TotemFrame:Show()
        GoubayuHeal.Totem_UpdateTextures()
        GoubayuHeal.Totem_PositionSpecialButtons()
    else
        GoubayuHeal_TotemFrame:Hide()
    end
end

-- ============================================================
-- 事件处理
-- ============================================================

-- 战斗状态轮询：仅维护战斗状态跳变标记（不再自动施法）
-- by 武藤纯子酱 2026.9.24
function GoubayuHeal.Totem_CombatPoll()
    local inCombat = UnitAffectingCombat and UnitAffectingCombat("player")
    GoubayuHeal.Totem_LastInCombat = inCombat and true or false
end

-- 脱战后回收图腾（供"用户主动按键"路径调用：/gbyh <方案> 或 /gbyh totem）
-- 只有在 已脱战 + 开关要求回收 + 自己仍有图腾存活 时才执行召回。
-- 放在主动按键路径里施放，避免自动触发时被客户端/宏插件拦截
-- by 武藤纯子酱 2026.9.24
function GoubayuHeal.Totem_TryRecallAfterCombat()
    local f = GoubayuHeal.Totem_FineEnsure and GoubayuHeal.Totem_FineEnsure() or nil
    if not (f and f.enabled == 1 and (tonumber(f.combatEndMode) or 0) == 2
        and GoubayuHeal.Spell and GoubayuHeal.Spell.TotemRecall) then
        return false
    end
    -- 自己/小队(团队)任一成员(含宠物)仍在战斗 → 不回收：
    -- 避免"队友进战、自己刚脱战"时误回收再重插，浪费 GCD 和蓝  by 武藤纯子酱 2026.10.12
    if GoubayuHeal.Totem_GroupInCombat and GoubayuHeal.Totem_GroupInCombat() then
        return false
    end
    -- 按记录的图腾 GUID 判断：还有自己的图腾存活才召回
    if not (GoubayuHeal.Totem_AnyOwnTotemAlive and GoubayuHeal.Totem_AnyOwnTotemAlive()) then
        return false
    end
    -- 施法中/GCD 中不回收：此时施放会"法术还没有准备好"失败，反复失败会把治疗键卡死；
    -- 直接返回 false 让本次按键继续走治疗  by 武藤纯子酱 2026.10.12
    if GoubayuHeal.casting_spell
        or (GoubayuHeal.GetLeftGCD and GoubayuHeal.GetLeftGCD() > 0) then
        return false
    end
    -- 节流：脱战后每 3 秒最多尝试一次回收（图腾消失检测会清理清单），
    -- 避免每次按键都重复召回、把治疗挡在门外  by 武藤纯子酱 2026.10.12
    local now = GetTime()
    if GoubayuHeal.Totem_RecallAfterCombatAt and (now - GoubayuHeal.Totem_RecallAfterCombatAt) < 3 then
        return false
    end
    GoubayuHeal.Totem_RecallAfterCombatAt = now

    -- 召回静默失效时会误清计时；这里只施放，计时/登记交给"消失检测"在确认图腾真的没了之后清理
    -- （避免"回收后立刻重插"时把新图腾的计时误清）
    -- by 武藤纯子酱 2026.9.24
    CastSpellByName(GoubayuHeal.Spell.TotemRecall)
    return true
end

-- 自己放置的图腾是否还有存活的（按记录的 GUID 逐个 UnitExists 判断）
-- by 武藤纯子酱 2026.9.24
function GoubayuHeal.Totem_AnyOwnTotemAlive()
    local placed = GoubayuHeal.Totem_ActivePlacedTotems
    if not placed then
        return false
    end
    for guid, _ in pairs(placed) do
        if guid and UnitExists and UnitExists(guid) then
            return true
        end
    end
    return false
end


function GoubayuHeal.Totem_OnEvent(event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then
        -- 仅更新时间戳：回收由"用户主动按键"路径触发（见 Totem_TryRecallAfterCombat）
        -- by 武藤纯子酱 2026.9.24
        GoubayuHeal.Totem_LastInCombat = false
        return
    end

    if event == "VARIABLES_LOADED" or event == "PLAYER_ENTERING_WORLD" then
        GoubayuHeal.Totem_Initialize()
        GoubayuHeal.Totem_SetupFonts()
        GoubayuHeal.Totem_UpdateTextures()
        GoubayuHeal.Totem_ApplyScale()
        GoubayuHeal.Totem_ToggleFrame()

        local cfg = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
        if GoubayuHeal_TotemFrame and cfg and cfg.position and cfg.position.point then
            -- 新版存的是锚点目标名称字符串；旧存档可能残留框架引用
            local rel = cfg.position.relativeTo
            if type(rel) == "string" then
                rel = _G[rel]
            end
            if type(rel) ~= "table" or not rel.SetPoint then
                rel = UIParent
            end
            GoubayuHeal_TotemFrame:ClearAllPoints()
            GoubayuHeal_TotemFrame:SetPoint(cfg.position.point, rel,
                cfg.position.relativePoint or "CENTER",
                cfg.position.xOffset or 0,
                cfg.position.yOffset or 0)
        end
    elseif event == "CHARACTER_POINTS_CHANGED" or event == "LEARNED_SPELL_IN_TAB" then
        if GoubayuHeal.Totem_ResetMasteryCache then
            GoubayuHeal.Totem_ResetMasteryCache()
        end
        -- 学新法术（图腾升级）后 aura spellId 会变化，清空 buff ID 缓存强制重建
        GoubayuHeal_Totem_BuffIdCache = {}
    elseif event == "CHAT_MSG_SPELL_SELF_BUFF" then
        -- 有Nampower时由 SPELL_GO_SELF 精确登记，聊天解析仅在无Nampower时兜底
        if not (GetNampowerVersion and GetUnitField) then
            GoubayuHeal.Totem_OnSpellCast(arg1)
        end
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        if arg1 == "player" and not (GetNampowerVersion and GetUnitField) then
            GoubayuHeal.Totem_CheckTotemCast()
        end
    elseif event == "SPELL_GO_SELF" then
        -- Nampower：法术成功施放，登记图腾计时并记录施放信息
        GoubayuHeal.Totem_OnSpellGoSelf(arg2)
    elseif event == "UNIT_MODEL_CHANGED_GUID" then
        -- Nampower：捕获被召唤单位（图腾）GUID；确认属于玩家后加入待确认队列
        local guid = arg1
        if guid and GetNampowerVersion and GetUnitGUID then
            local ok, ownerGuid = pcall(GetUnitGUID, guid .. "owner")
            if ok and ownerGuid and ownerGuid == GetUnitGUID("player")
                and not GoubayuHeal.Totem_ActivePlacedTotems[guid]
                and not GoubayuHeal.Totem_PendingSummons[guid] then
                GoubayuHeal.Totem_PendingSummons[guid] = GetTime()
            end
        end
    end
end

-- ============================================================
-- 图腾施放检测与计时记录
-- ============================================================

-- 检查施放的技能是否是图腾
function GoubayuHeal.Totem_CheckTotemCast()
    local spellName = nil
    if CastingBarFrame and CastingBarFrame.spellName then
        spellName = CastingBarFrame.spellName
    end

    if not spellName then
        return
    end

    -- 去掉等级后缀（如 "灼热图腾(等级 1)"）
    local cleanName = string.gsub(spellName, "%s*%(.*%)", "")

    for i = 1, 4 do
        local totemData = GoubayuHeal_TotemData[i]
        if totemData then
            for _, totem in ipairs(totemData) do
                if totem.name == cleanName then
                    local timer = GoubayuHeal.Totem_Timers[i]
                    local now = GetTime()
                    timer.durationStart = now
                    local masteryBonus = GoubayuHeal.Totem_GetMasteryBonus()
                    timer.duration = (totem.duration or 60) * (1 + masteryBonus)
                    -- 记录该图腾自己的冷却起点（按具体图腾独立CD）
                    GoubayuHeal.Totem_CastedAt[cleanName] = now
                    return
                end
            end
        end
    end
end

-- 施法成功时记录图腾时间（CHAT_MSG_SPELL_SELF_BUFF事件）
function GoubayuHeal.Totem_OnSpellCast(msg)
    if not msg then
        return
    end

    for i = 1, 4 do
        local totemData = GoubayuHeal_TotemData[i]
        if totemData then
            for _, totem in ipairs(totemData) do
                -- 双向匹配：聊天消息里出现的是buff名（如"治疗之泉"），与图腾技能名可能不同
                local buffName = GetTotemBuffName(totem.name)
                if string.find(msg, totem.name)
                    or (buffName and string.find(msg, buffName)) then
                    GoubayuHeal.Totem_StartCastTimer(totem.name)
                    return
                end
            end
        end
    end
end

-- ============================================================
-- 真实图腾存活追踪（GUID级）
-- ============================================================

-- 从技能名反查图腾所属元素索引（1=FIRE,2=WATER,3=EARTH,4=AIR）
local function GoubayuHeal_Totem_FindElement(totemName)
    if not totemName then return nil end
    for i = 1, 4 do
        local totemData = GoubayuHeal_TotemData[i]
        if totemData then
            for _, totem in ipairs(totemData) do
                if totem.name == totemName then
                    return i
                end
            end
        end
    end
    return nil
end

-- 登记图腾施放计时（按技能名，供 SPELL_GO_SELF / 施放路径复用）
function GoubayuHeal.Totem_StartCastTimer(totemName)
    local idx = GoubayuHeal_Totem_FindElement(totemName)
    if not idx then return end
    local timer = GoubayuHeal.Totem_Timers[idx]
    local now = GetTime()
    -- 施放即清该图腾 buff 的阴性缓存：0.5s TTL 内再次一键放置时，
    -- 若 aura 尚未落到玩家身上，阴性缓存会误判"不在范围"导致重复施放
    -- by 武藤纯子酱 2026.9.4
    GoubayuHeal_Totem_BuffNegCache[GetTotemBuffName(totemName)] = nil
    timer.durationStart = now
    local masteryBonus = GoubayuHeal.Totem_GetMasteryBonus()
    -- 在 TotemData 中查找该图腾的时长/冷却
    timer.duration = 0
    for _, totem in ipairs(GoubayuHeal_TotemData[idx]) do
        if totem.name == totemName then
            timer.duration = (totem.duration or 60) * (1 + masteryBonus)
            -- 记录该图腾自己的冷却起点（按具体图腾独立CD；无论从哪里施放——
            -- 插件按钮/技能栏/宏，SPELL_GO_SELF 都会走到这里）
            GoubayuHeal.Totem_CastedAt[totemName] = now
            -- 持久化（wall clock）：reload/重登后按差值还原剩余CD，避免服务器CD中误放
            if (totem.cooldown or 0) > 0 and GoubayuHeal_Data then
                GoubayuHeal_Data["totem_casted_wall"] = GoubayuHeal_Data["totem_casted_wall"] or {}
                GoubayuHeal_Data["totem_casted_wall"][totemName] = Totem_WallTime()
            end
            -- 同步更新按钮图标为实际放置的图腾（单图释放与选中图腾不同时也能正确显示图标+持续时间）
            local elements = TOTEM_ELEMENT_NAMES
            local btnTex = _G["GoubayuHeal_TotemButton_" .. elements[idx] .. "1Texture"]
            if btnTex then
                btnTex:SetTexture(totem.icon)
                btnTex:SetAlpha(1.0)
                btnTex:SetVertexColor(1, 1, 1)
            end
            break
        end
    end
end

-- Nampower SPELL_GO_SELF：按 spellId 反查图腾名并登记计时
function GoubayuHeal.Totem_OnSpellGoSelf(spellId)
    if not spellId or not (GetNampowerVersion and GetSpellNameAndRankForId) then
        return
    end
    local ok, name = pcall(GetSpellNameAndRankForId, spellId)
    if not ok or not name then
        return
    end
    -- 去掉等级后缀（如 "灼热图腾(等级 1)"）
    local cleanName = string.gsub(name, "%s*%(.*%)", "")
    local idx = GoubayuHeal_Totem_FindElement(cleanName)
    if idx then
        GoubayuHeal.Totem_StartCastTimer(cleanName)
    end
end

-- 确认待召唤单位为图腾并登记到已放置表；同时检测已放置图腾是否死亡（GUID不再存在）→ 清除计时
function GoubayuHeal.Totem_CheckSummonedUnits()
    -- 处理待确认的召唤单位（值为加入时间戳：名称未知时3秒内保留重试）
    -- 与下方 ActivePlacedTotems 同口径：先收集后统一删（pairs 遍历中删当前键虽安全，
    -- 但统一风格可避免将来在循环内新增键时变成未定义行为） by 武藤纯子酱 2026.9.4
    local pendingRemove = nil
    for guid, addedAt in pairs(GoubayuHeal.Totem_PendingSummons) do
        local remove = false
        if UnitExists(guid) then
            local name = UnitName(guid)
            if name and name ~= "" and name ~= GoubayuHeal.Msg.TotemUnknownTarget then
                if string.find(name, GoubayuHeal.Msg.TotemNamePattern) then
                    -- 去除名称末尾罗马数字等级后缀
                    local cleanName = string.gsub(name, "%s*[IVXLCDM]+$", "")
                    local idx = GoubayuHeal_Totem_FindElement(cleanName)
                    if idx then
                        -- 中途换图腾：同元素登记新 GUID 前，先清掉被替换的旧 GUID 记录，
                        -- 避免下方“消失检测”把旧 GUID 的消失误判为该元素无图腾而清掉新图腾计时
                        -- by 武藤纯子酱 2026.9.6
                        for g2, d2 in pairs(GoubayuHeal.Totem_ActivePlacedTotems) do
                            if g2 ~= guid and d2.element == idx then
                                GoubayuHeal.Totem_ActivePlacedTotems[g2] = nil
                            end
                        end
                        GoubayuHeal.Totem_ActivePlacedTotems[guid] = { name = name, element = idx }
                    end
                    remove = true
                elseif GetTime() - (addedAt or 0) > 3 then
                    -- 名称3秒仍无法解析（非图腾召唤物）：放弃该GUID
                    remove = true
                end
                -- 名称已知但3秒内：保留待确认
            elseif GetTime() - (addedAt or 0) > 3 then
                -- GUID 已消失且超时：放弃
                remove = true
            end
        else
            remove = true
        end
        if remove then
            pendingRemove = pendingRemove or {}
            table.insert(pendingRemove, guid)
        end
    end
    if pendingRemove then
        for _, guid in ipairs(pendingRemove) do
            GoubayuHeal.Totem_PendingSummons[guid] = nil
        end
    end

    -- 检查已激活图腾：GUID 不存在（被打掉/消失）→ 清除该元素计时与活跃状态
    -- 注意：UnitExists 对"较远/未加载"的单位可能返回假（图腾明明还在），
    -- 故清计时前再做双保险：该元素位若仍能查到自己放置的图腾，则视为未消失
    -- by 武藤纯子酱 2026.9.24
    local toRemove = {}
    for guid, data in pairs(GoubayuHeal.Totem_ActivePlacedTotems) do
        if not UnitExists(guid) then
            local element = data.element
            if element then
                local timer = GoubayuHeal.Totem_Timers[element]
                -- 若刚施放不久（<1秒）暂不清除计时，且 GUID 也保留到下个周期再查
                -- （此前保护期仍移除GUID：倒计时成"幽灵计时"走满、覆盖统计立即消失，两处显示不一致）
                if timer and timer.durationStart > 0 and (GetTime() - timer.durationStart) < 1.0 then
                    -- 保留（下个周期重新判定）
                else
                    -- 双保险：同元素若还有其他"存活"图腾（替换图腾/同名多插），
                    -- 或图腾列表里仍能查到该元素的图腾（UnitExists 假阴性），
                    -- 都不清该元素计时，只移除这条失效 GUID 记录
                    local hasReplacement = false
                    for g2, d2 in pairs(GoubayuHeal.Totem_ActivePlacedTotems) do
                        if g2 ~= guid and d2.element == element and UnitExists(g2) then
                            hasReplacement = true
                            break
                        end
                    end
                    -- 假阴性兜底：遍历可见图腾单位，若仍有该名字的图腾存在则不清计时
                    if not hasReplacement then
                        local elementIdx = element
                        -- 用元素对应的方案图腾名做一次保守判断（图腾仍在则不处理）
                        local cfg = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
                        local eleCfg = cfg and cfg.elements and cfg.elements[TOTEM_ELEMENT_NAMES[elementIdx]]
                        local stillThere = false
                        if eleCfg and eleCfg.selectedIndex and eleCfg.selectedIndex > 0 then
                            local td = GoubayuHeal_TotemData[elementIdx]
                            local nm = td and td[eleCfg.selectedIndex] and td[eleCfg.selectedIndex].name
                            if nm and GetTotemBuffName and IsTotemBuffActive then
                                stillThere = IsTotemBuffActive(GetTotemBuffName(nm))
                            end
                        end
                        -- 再兜底：该元素计时刚开始不久（刚施放，召唤物尚未登记/GUID 延迟）→ 不清计时
                        -- 覆盖"回收后立刻重插""同元素换图腾"等时序竞争场景
                        -- by 武藤纯子酱 2026.9.24
                        if not stillThere and timer and timer.durationStart > 0
                            and (GetTime() - timer.durationStart) < 3.0 then
                            stillThere = true
                        end
                        if not stillThere then
                            -- 死亡/消失只清持续时间，保留冷却倒计时（火焰新星/地缚/根基等图腾的CD仍需等待）
                            if timer then
                                timer.durationStart = 0
                                timer.duration = 0
                            end
                            local elements = TOTEM_ELEMENT_NAMES
                            local durText = _G["GoubayuHeal_TotemButton_" .. elements[element] .. "1DurationText"]
                            if durText then durText:Hide() end
                        end
                    end
                    table.insert(toRemove, guid)
                end
            else
                table.insert(toRemove, guid)
            end
        end
    end
    for _, guid in ipairs(toRemove) do
        GoubayuHeal.Totem_ActivePlacedTotems[guid] = nil
    end
end

-- ============================================================
-- 图腾覆盖检测（主按钮上显示 已覆盖人数/小队人数）
-- ============================================================
function GoubayuHeal.Totem_UpdateTotemCoverage()
    if not (GetNampowerVersion and UnitXP) then
        for _, element in ipairs(TOTEM_ELEMENT_NAMES) do
            local text = _G["GoubayuHeal_TotemButton_" .. element .. "1CoverageText"]
            if text then text:Hide() end
        end
        return
    end

    local elements = TOTEM_ELEMENT_NAMES
    -- 覆盖统计只限本小队（团队中 partyN/GetNumPartyMembers 即本小队成员，不含其他小队），
    -- 并排除死亡、灵魂状态与离线人员（分母同样只算存活在线成员）
    local unitIds = {}
    if not UnitIsDeadOrGhost("player") and UnitIsConnected("player") then
        table.insert(unitIds, "player")
    end
    local n = GetNumPartyMembers()
    for i = 1, n do
        local u = "party" .. i
        if UnitExists(u) and not UnitIsDeadOrGhost(u) and UnitIsConnected(u) then
            table.insert(unitIds, u)
        end
    end
    local maxPlayers = table.getn(unitIds)
    if maxPlayers < 1 then maxPlayers = 1 end
    local coverageCounts = { Fire = 0, Water = 0, Earth = 0, Air = 0 }
    local activeGuids = {}

    -- 收集当前激活图腾 GUID 及其元素（data.element 为数字索引 1-4，转成字符串元素名）
    for guid, data in pairs(GoubayuHeal.Totem_ActivePlacedTotems) do
        if data.element and elements[data.element] then
            activeGuids[elements[data.element]] = guid
        end
    end

    -- 对每个元素计算覆盖：玩家 + 团队/小队成员（30码半径）
    for element, guid in pairs(activeGuids) do
        local count = 0
        for _, unitId in ipairs(unitIds) do
            if UnitExists(unitId) then
                local ok, dist = pcall(UnitXP, "distanceBetween", guid, unitId)
                if ok and dist and dist <= 30 then
                    count = count + 1
                end
            end
        end
        coverageCounts[element] = count
    end

    -- 更新文本与颜色
    for element, count in pairs(coverageCounts) do
        local text = _G["GoubayuHeal_TotemButton_" .. element .. "1CoverageText"]
        if text then
            if activeGuids[element] then
                local ratio = maxPlayers > 0 and (count / maxPlayers) or 0
                if ratio > 0.8 then
                    text:SetTextColor(0.2, 1, 0.2, 1)   -- 绿色 (>80%)
                elseif ratio >= 0.6 then
                    text:SetTextColor(1, 1, 0, 1)        -- 黄色 (60%-80%)
                else
                    text:SetTextColor(1, 0.3, 0.3, 1)    -- 红色 (<60%)
                end
                text:SetText(count .. "/" .. maxPlayers)
                text:Show()
            else
                text:Hide()
            end
        end
    end
end

-- 重置所有计时器
function GoubayuHeal.Totem_ResetAllTimers()
    for i = 1, 4 do
        GoubayuHeal.Totem_Timers[i].durationStart = 0
        GoubayuHeal.Totem_Timers[i].duration = 0
    end
    -- 召回后清除已放置图腾记录
    if GoubayuHeal.Totem_ActivePlacedTotems then
        for k in pairs(GoubayuHeal.Totem_ActivePlacedTotems) do
            GoubayuHeal.Totem_ActivePlacedTotems[k] = nil
        end
    end
    if GoubayuHeal.Totem_PendingSummons then
        for k in pairs(GoubayuHeal.Totem_PendingSummons) do
            GoubayuHeal.Totem_PendingSummons[k] = nil
        end
    end
end

-- ============================================================
-- UI更新：纹理/排序/定位
-- ============================================================

-- 更新纹理
function GoubayuHeal.Totem_UpdateTextures()
    local elements = TOTEM_ELEMENT_NAMES

    for i, element in ipairs(elements) do
        local button = _G["GoubayuHeal_TotemButton_" .. element .. "1"]
        if button then
            local texture = _G["GoubayuHeal_TotemButton_" .. element .. "1Texture"]
            if texture then
                local totemData = GoubayuHeal_TotemData[i]
                local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[element]
                local selectedIndex = elementConfig.selectedIndex or 1
                local skip = elementConfig.skip

                if skip then
                    -- 禁用状态（右键切换）：显示原选中图腾图标但半透明红色
                    texture:SetTexture((totemData and totemData[selectedIndex] and totemData[selectedIndex].icon)
                        or SKIP_TOTEM_ICONS[i])
                    texture:SetAlpha(0.4)
                    texture:SetVertexColor(1, 0.3, 0.3)
                elseif selectedIndex == 0 then
                    texture:SetTexture(SKIP_TOTEM_ICONS[i])
                    texture:SetAlpha(1.0)
                    texture:SetVertexColor(1, 1, 1)
                elseif totemData and totemData[selectedIndex] then
                    texture:SetTexture(totemData[selectedIndex].icon)
                    texture:SetAlpha(1.0)
                    texture:SetVertexColor(1, 1, 1)
                end
            end
        end

        -- 更新备选按钮（按钮索引 2-maxButtons+1 对应技能 1-maxButtons）
        local maxButtons = (element == "Air") and 7 or 5
        for j = 1, maxButtons do
            local altButton = _G["GoubayuHeal_TotemButton_" .. element .. (j + 1)]
            if altButton then
                local altTexture = _G["GoubayuHeal_TotemButton_" .. element .. (j + 1) .. "Texture"]
                if altTexture and GoubayuHeal_TotemData[i] and GoubayuHeal_TotemData[i][j] then
                    altTexture:SetTexture(GoubayuHeal_TotemData[i][j].icon)
                end
            end
        end

        -- "不使用"跳过按钮纹理（此前从未赋值，显示为空白可点击区）
        local skipIndex = ((element == "Air") and 7 or 5) + 2
        local skipTexture = _G["GoubayuHeal_TotemButton_" .. element .. skipIndex .. "Texture"]
        if skipTexture then
            skipTexture:SetTexture(SKIP_TOTEM_ICONS[i])
            skipTexture:SetAlpha(1.0)
            skipTexture:SetVertexColor(1, 1, 1)
        end
    end

    -- 一键放置按钮
    local placeTexture = _G["GoubayuHeal_TotemButton_PlaceTexture"]
    if placeTexture then
        placeTexture:SetTexture("Interface\\Icons\\Spell_Nature_ElementalAbsorption")
    end

    -- 设置按钮 - 显示当前预设的图标
    local settingsTexture = _G["GoubayuHeal_TotemButton_SettingsTexture"]
    if settingsTexture then
        local preset = GoubayuHeal.Config["shaman_totem"].placePreset or 1
        settingsTexture:SetTexture(PRESET_ICONS[preset])
    end
end

-- 更新排序
function GoubayuHeal.Totem_UpdateOrder()
    if not GoubayuHeal.Config or not GoubayuHeal.Config["shaman_totem"] then
        return
    end

    local order = GoubayuHeal.Config["shaman_totem"].order
    if not order then
        return
    end

    local elements = { order.first, order.second, order.third, order.forth }
    local prevButton = nil

    for i, element in ipairs(elements) do
        local button = _G["GoubayuHeal_TotemButton_" .. element .. "1"]
        if button then
            button:ClearAllPoints()
            if i == 1 then
                button:SetPoint("LEFT", GoubayuHeal_TotemFrame, "LEFT", 0, 0)
            else
                button:SetPoint("LEFT", prevButton, "RIGHT", 0, 0)
            end
            prevButton = button
        end
    end
end

-- 定位特殊按钮（放置/设置）
function GoubayuHeal.Totem_PositionSpecialButtons()
    local order = GoubayuHeal.Config["shaman_totem"].order
    if not order then
        return
    end

    local elements = { order.first, order.second, order.third, order.forth }

    -- 第一个按钮（火图腾）相对于框架左边，向右偏移10像素
    local firstButton = _G["GoubayuHeal_TotemButton_" .. elements[1] .. "1"]
    if firstButton then
        firstButton:ClearAllPoints()
        firstButton:SetPoint("LEFT", GoubayuHeal_TotemFrame, "LEFT", 10, 0)
    end

    -- 后续按钮依次排列
    for i = 2, 4 do
        local button = _G["GoubayuHeal_TotemButton_" .. elements[i] .. "1"]
        local prevButton = _G["GoubayuHeal_TotemButton_" .. elements[i - 1] .. "1"]
        if button and prevButton then
            button:ClearAllPoints()
            button:SetPoint("LEFT", prevButton, "RIGHT", 0, 0)
        end
    end

    local lastElement = elements[4]
    local lastButton = _G["GoubayuHeal_TotemButton_" .. lastElement .. "1"]

    -- 设置按钮在前面
    local settingsButton = _G["GoubayuHeal_TotemButton_Settings"]
    if settingsButton and lastButton then
        settingsButton:ClearAllPoints()
        settingsButton:SetPoint("LEFT", lastButton, "RIGHT", 0, 0)
    end

    -- 一键放置按钮在后面
    local placeButton = _G["GoubayuHeal_TotemButton_Place"]
    if placeButton and settingsButton then
        placeButton:ClearAllPoints()
        placeButton:SetPoint("LEFT", settingsButton, "RIGHT", 0, 0)
    end
end

-- ============================================================
-- 主按钮点击事件
-- ============================================================

function GoubayuHeal.Totem_OnClick(totemType, button)
    if totemType >= 1 and totemType <= 4 then
        local elements = TOTEM_ELEMENT_NAMES
        local element = elements[totemType]
        local elementConfig = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
            and GoubayuHeal.Config["shaman_totem"].elements
            and GoubayuHeal.Config["shaman_totem"].elements[element]
        if not elementConfig then
            return
        end

        if button == "RightButton" then
            -- 右键切换禁用/启用该元素图腾
            elementConfig.skip = not elementConfig.skip
            GoubayuHeal.Totem_UpdateTextures()
            return
        end

        if button == "LeftButton" then
            local selectedIndex = elementConfig.selectedIndex or 1
            local skip = elementConfig.skip

            if not skip and selectedIndex > 0 then
                local totemData = GoubayuHeal_TotemData[totemType]
                if totemData and totemData[selectedIndex] then
                    CastSpellByName(totemData[selectedIndex].name)
                end
            end
        end
    elseif totemType == 5 then
        if button == "LeftButton" then
            GoubayuHeal.Totem_PlaceAll()
        elseif button == "RightButton" then
            CastSpellByName(GoubayuHeal.Spell.TotemRecall)
            GoubayuHeal.Totem_ResetAllTimers()
        end
    elseif totemType == 6 then
        -- 设置卡片：左键=按当前预设放置图腾（原左键为空），右键=精细图腾管理；
        -- 预设的选择沿用"悬停显示预设按钮"的原有交互
        -- by 武藤纯子酱 2026.9.21
        if button == "RightButton" then
            if GoubayuHeal.Totem_FineToggleWindow then
                GoubayuHeal.Totem_FineToggleWindow()
            end
        else
            GoubayuHeal.Totem_PlaceAll()
        end
    end
end

-- ============================================================
-- 鼠标悬停：备选按钮显示/隐藏
-- ============================================================

-- 取消隐藏计时器
local function GoubayuHeal_Totem_CancelHideTimer()
    if GoubayuHeal_Totem_HideTimer then
        GoubayuHeal_Totem_HideTimer:Hide()
        GoubayuHeal_Totem_HideTimer = nil
    end
end

-- 延迟隐藏备选按钮
local function GoubayuHeal_Totem_ScheduleHide()
    GoubayuHeal_Totem_CancelHideTimer()

    GoubayuHeal_Totem_HideTimer = CreateFrame("Frame", nil, UIParent)
    GoubayuHeal_Totem_HideTimer.TimeLeft = 0.3

    GoubayuHeal_Totem_HideTimer:SetScript("OnUpdate", function()
        this.TimeLeft = this.TimeLeft - arg1
        if this.TimeLeft <= 0 then
            GoubayuHeal.Totem_HideAltButtons()
            this:Hide()
        end
    end)
end

-- 隐藏备选按钮
function GoubayuHeal.Totem_HideAltButtons()
    local elements = TOTEM_ELEMENT_NAMES

    for _, element in ipairs(elements) do
        local maxButtons = (element == "Air") and 9 or 7
        for j = 2, maxButtons do
            local altButton = _G["GoubayuHeal_TotemButton_" .. element .. j]
            if altButton then
                altButton:Hide()
            end
        end
    end
    GoubayuHeal_Totem_CurrentElement = nil
end

-- 鼠标进入主按钮
function GoubayuHeal.Totem_OnEnter(totemType)
    GoubayuHeal_Totem_CancelHideTimer()

    if totemType >= 1 and totemType <= 4 then
        local elements = TOTEM_ELEMENT_NAMES
        local element = elements[totemType]

        if GoubayuHeal_Totem_CurrentElement and GoubayuHeal_Totem_CurrentElement ~= element then
            GoubayuHeal.Totem_HideAltButtons()
        end

        GoubayuHeal_Totem_CurrentElement = element

        local maxButtons = (element == "Air") and 7 or 5
        local mainButton = _G["GoubayuHeal_TotemButton_" .. element .. "1"]

        -- 显示所有技能按钮（紧贴主按钮顶部向上排列）
        for j = 1, maxButtons do
            local altButton = _G["GoubayuHeal_TotemButton_" .. element .. (j + 1)]
            if altButton then
                altButton:ClearAllPoints()
                altButton:SetPoint("BOTTOM", mainButton, "TOP", 0, (j - 1) * BUTTON_SIZE)
                altButton:Show()
            end
        end

        -- 显示"不使用"按钮（放在最上方）
        local skipIndex = maxButtons + 2
        local skipButton = _G["GoubayuHeal_TotemButton_" .. element .. skipIndex]
        if skipButton then
            skipButton:ClearAllPoints()
            skipButton:SetPoint("BOTTOM", mainButton, "TOP", 0, maxButtons * BUTTON_SIZE)
            skipButton:Show()
        end

        -- 显示tooltip
        local totemData = GoubayuHeal_TotemData[totemType]
        local selectedIndex = GoubayuHeal.Config["shaman_totem"].elements[element].selectedIndex or 1

        if totemData and totemData[selectedIndex] then
            GoubayuHeal.Totem_ShowSpellTooltipByName(totemData[selectedIndex].name)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(GoubayuHeal.TotemUI.LeftCast, 0.82, 0.82, 0.82)
            GameTooltip:Show()
        end
    elseif totemType == 5 then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetText(GoubayuHeal.TotemUI.OneKeyTitle, 1, 1, 1)
        GameTooltip:AddLine(GoubayuHeal.TotemUI.LeftAll, 0.82, 0.82, 0.82)
        GameTooltip:AddLine(GoubayuHeal.TotemUI.RightAll, 0.82, 0.82, 0.82)
        GameTooltip:Show()
    elseif totemType == 6 then
        GoubayuHeal.Totem_HideAltButtons()
        GoubayuHeal.Totem_ShowPresetButtons()

        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetText(GoubayuHeal.TotemUI.SettingsTitle, 1, 1, 1)
        GameTooltip:AddLine(GoubayuHeal.TotemUI.HoverPreset, 0.82, 0.82, 0.82)
        GameTooltip:AddLine(GoubayuHeal.TotemUI.LeftChoosePreset, 0.82, 0.82, 0.82)
        GameTooltip:AddLine(GoubayuHeal.TotemUI.RightChooseFine, 0.82, 0.82, 0.82)
        GameTooltip:Show()
    end
end

-- 鼠标离开主按钮
function GoubayuHeal.Totem_OnLeave(totemType)
    GoubayuHeal_Totem_ScheduleHide()
    GameTooltip:Hide()
end

-- ============================================================
-- 备选按钮鼠标事件
-- ============================================================

function GoubayuHeal.Totem_AltButton_OnEnter(element, index)
    GoubayuHeal_Totem_CancelHideTimer()

    local elementIndex = 0
    local elements = TOTEM_ELEMENT_NAMES
    for i, elem in ipairs(elements) do
        if elem == element then
            elementIndex = i
            break
        end
    end

    local maxButtons = (element == "Air") and 7 or 5
    local elementNames = GoubayuHeal.Element

    -- 按钮索引映射到技能索引：按钮 2 -> 技能 1
    local skillIndex = index - 1

    if skillIndex > maxButtons then
        GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
        GameTooltip:SetText(string.format(GoubayuHeal.TotemUI.NotUsingFmt, elementNames[element]), 1, 1, 1)
        GameTooltip:AddLine(GoubayuHeal.TotemUI.ClickSkipElement, 0.82, 0.82, 0.82)
        GameTooltip:Show()
    elseif elementIndex > 0 and GoubayuHeal_TotemData[elementIndex] then
        local totemData = GoubayuHeal_TotemData[elementIndex][skillIndex]
        if totemData then
            GoubayuHeal.Totem_ShowSpellTooltipByName(totemData.name)
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine(GoubayuHeal.TotemUI.ClickChooseTotem, 0.82, 0.82, 0.82)
            GameTooltip:Show()
        end
    end
end

function GoubayuHeal.Totem_AltButton_OnLeave()
    GoubayuHeal_Totem_ScheduleHide()
    GameTooltip:Hide()
end

-- 通过技能名称显示tooltip
function GoubayuHeal.Totem_ShowSpellTooltipByName(spellName)
    GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)

    -- 法术书中同一技能的每个等级都是独立槽位、且 GetSpellName 第一返回值是不带等级的裸名，
    -- 取"第一个同名槽位"会命中最低等级（tooltip 显示 1 级），而实际施放按名走客户端自动选最高级。
    -- 因此需遍历全部槽位，用 GetSpellName 第二返回值（本地化等级串，如"等级 3"/"Rank 3"）取最高等级槽位；
    -- 若该返回值不可用（解析不到数字），兜底取最后一个同名槽位（法术书内等级升序排列）
    -- by 武藤纯子酱 2026.9.21
    local foundId = nil
    local foundBookType = nil
    local bestRank = -1
    local lastId = nil
    local lastBookType = nil

    for j = 1, 2 do
        local bookType = j == 1 and BOOKTYPE_SPELL or BOOKTYPE_PET
        local numTabs = GetNumSpellTabs()
        for i = 1, numTabs do
            local _, _, offset, num = GetSpellTabInfo(i)
            for id = offset + 1, offset + num do
                local name, rank = GetSpellName(id, bookType)
                if name and name == spellName then
                    lastId = id
                    lastBookType = bookType
                    local rn = tonumber(string.match(rank or "", "%d+"))
                    if rn and rn > bestRank then
                        bestRank = rn
                        foundId = id
                        foundBookType = bookType
                    end
                end
            end
        end
    end

    if not foundId then
        foundId = lastId
        foundBookType = lastBookType
    end

    if foundId and foundBookType then
        GameTooltip:SetSpell(foundId, foundBookType)
    else
        GameTooltip:SetText(spellName, 1, 1, 1)
    end
end

-- ============================================================
-- 备选按钮点击：选择图腾
-- ============================================================

function GoubayuHeal.Totem_SelectSpell(element, index)
    local elementIndex = 0
    local elements = TOTEM_ELEMENT_NAMES
    for i, elem in ipairs(elements) do
        if elem == element then
            elementIndex = i
            break
        end
    end

    local maxButtons = (element == "Air") and 7 or 5
    local skillIndex = index - 1

    if elementIndex > 0 then
        if skillIndex > maxButtons then
            GoubayuHeal.Config["shaman_totem"].elements[element].skip = true
            GoubayuHeal.Config["shaman_totem"].elements[element].selectedIndex = 0
        else
            GoubayuHeal.Config["shaman_totem"].elements[element].selectedIndex = skillIndex
            GoubayuHeal.Config["shaman_totem"].elements[element].skip = false
        end

        GoubayuHeal.Totem_UpdateTextures()
        GoubayuHeal.Totem_HideAltButtons()
    end
end

-- ============================================================
-- 设置按钮：预设菜单
-- ============================================================

-- 延迟隐藏预设按钮
local GoubayuHeal_Totem_PresetHideTimer = nil

local function GoubayuHeal_Totem_CancelPresetHideTimer()
    if GoubayuHeal_Totem_PresetHideTimer then
        GoubayuHeal_Totem_PresetHideTimer:Hide()
        GoubayuHeal_Totem_PresetHideTimer = nil
    end
end

function GoubayuHeal.Totem_SchedulePresetHide()
    GoubayuHeal_Totem_CancelPresetHideTimer()

    GoubayuHeal_Totem_PresetHideTimer = CreateFrame("Frame", nil, UIParent)
    GoubayuHeal_Totem_PresetHideTimer.TimeLeft = 0.5

    GoubayuHeal_Totem_PresetHideTimer:SetScript("OnUpdate", function()
        this.TimeLeft = this.TimeLeft - arg1
        if this.TimeLeft <= 0 then
            GoubayuHeal.Totem_HidePresetButtons()
            this:Hide()
        end
    end)
end

-- 显示预设选项按钮
function GoubayuHeal.Totem_ShowPresetButtons()
    GoubayuHeal_Totem_CancelPresetHideTimer()

    local settingsButton = _G["GoubayuHeal_TotemButton_Settings"]
    if not settingsButton then
        return
    end

    local scale = GoubayuHeal.Config["shaman_totem"].appearance.scale or 1

    if not GoubayuHeal_TotemPresetButtons then
        GoubayuHeal_TotemPresetButtons = {}
    end

    for i = 1, 6 do
        local button = GoubayuHeal_TotemPresetButtons[i]
        if not button then
            button = CreateFrame("Button", "GoubayuHeal_TotemPresetButton" .. i,
                GoubayuHeal_TotemFrame)
            button:SetFrameStrata("DIALOG")
            button:SetWidth(BUTTON_SIZE)
            button:SetHeight(BUTTON_SIZE)
            button:EnableMouse(true)
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

            button.presetIndex = i

            button.icon = button:CreateTexture(nil, "ARTWORK")
            button.icon:SetAllPoints()

            button:SetScript("OnEnter", function()
                GoubayuHeal_Totem_CancelPresetHideTimer()
                local presetNames = GoubayuHeal.TotemUI.Presets
                local idx = this.presetIndex
                GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
                GameTooltip:SetText(presetNames[idx], 1, 1, 1)
                GameTooltip:AddLine(GoubayuHeal.TotemUI.ClickChoosePreset, 0.82, 0.82, 0.82)
                GameTooltip:Show()
            end)

            button:SetScript("OnLeave", function()
                GoubayuHeal.Totem_SchedulePresetHide()
                GameTooltip:Hide()
            end)

            button:SetScript("OnClick", function()
                local idx = this.presetIndex
                GoubayuHeal.Config["shaman_totem"].placePreset = idx
                GoubayuHeal.Totem_UpdateTextures()
                GoubayuHeal.Totem_HidePresetButtons()
                -- 点击后按钮被隐藏不触发 OnLeave，手动收掉 tooltip 防残留
                GameTooltip:Hide()
            end)

            GoubayuHeal_TotemPresetButtons[i] = button
        end

        button.icon:SetTexture(PRESET_ICONS[i])

        button:ClearAllPoints()
        if i == 1 then
            button:SetPoint("BOTTOM", settingsButton, "TOP", 0, 0)
        else
            button:SetPoint("BOTTOM", GoubayuHeal_TotemPresetButtons[i - 1], "TOP", 0, 0)
        end
        button:Show()
    end
end

-- 隐藏预设选项按钮
function GoubayuHeal.Totem_HidePresetButtons()
    if GoubayuHeal_TotemPresetButtons then
        for _, button in ipairs(GoubayuHeal_TotemPresetButtons) do
            button:Hide()
        end
    end
end

-- 打开预设菜单（右键点击设置按钮）
function GoubayuHeal.Totem_OpenPresetMenu()
    local presetNames = GoubayuHeal.TotemUI.Presets

    if not GoubayuHeal_TotemPresetMenu then
        GoubayuHeal_TotemPresetMenu = CreateFrame("Frame", "GoubayuHeal_TotemPresetMenu",
            UIParent)
        GoubayuHeal_TotemPresetMenu:SetFrameStrata("DIALOG")
        GoubayuHeal_TotemPresetMenu:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        GoubayuHeal_TotemPresetMenu:SetBackdropColor(0, 0, 0, 0.9)
        GoubayuHeal_TotemPresetMenu:EnableMouse(true)
        GoubayuHeal_TotemPresetMenu.buttons = {}
    end

    for _, btn in ipairs(GoubayuHeal_TotemPresetMenu.buttons) do
        btn:Hide()
    end

    local buttonHeight = 24
    local menuWidth = 200
    local menuHeight = table.getn(presetNames) * buttonHeight + 10

    GoubayuHeal_TotemPresetMenu:SetWidth(menuWidth)
    GoubayuHeal_TotemPresetMenu:SetHeight(menuHeight)

    for i, name in ipairs(presetNames) do
        local button = GoubayuHeal_TotemPresetMenu.buttons[i]
        if not button then
            button = CreateFrame("Button", nil, GoubayuHeal_TotemPresetMenu)
            button:SetHeight(buttonHeight)
            button:SetWidth(menuWidth - 10)

            button.text = button:CreateFontString(nil, "ARTWORK", "GameFontNormal")
            button.text:SetAllPoints()
            button.text:SetJustifyH("LEFT")

            local highlight = button:CreateTexture(nil, "HIGHLIGHT")
            highlight:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
            highlight:SetAllPoints()
            button:SetHighlightTexture(highlight)

            GoubayuHeal_TotemPresetMenu.buttons[i] = button
        end

        button.text:SetText(name)
        button:ClearAllPoints()
        button:SetPoint("TOP", GoubayuHeal_TotemPresetMenu, "TOP", 0, -5 - (i - 1) * buttonHeight)
        local idx = i
        button:SetScript("OnClick", function()
            GoubayuHeal.Config["shaman_totem"].placePreset = idx
            GoubayuHeal.Totem_UpdateTextures()
            GoubayuHeal_TotemPresetMenu:Hide()
        end)
        button:Show()
    end

    local x, y = GetCursorPosition()
    local scale = UIParent:GetScale()
    GoubayuHeal_TotemPresetMenu:ClearAllPoints()
    GoubayuHeal_TotemPresetMenu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
    GoubayuHeal_TotemPresetMenu:Show()

    GoubayuHeal_TotemPresetMenu:SetScript("OnEnter", function() end)
    GoubayuHeal_TotemPresetMenu:SetScript("OnLeave", function()
        GoubayuHeal_TotemPresetMenu:Hide()
    end)
end

-- ============================================================
-- 保存窗口位置
-- ============================================================

function GoubayuHeal.Totem_SaveFramePosition()
    if not GoubayuHeal.Config or not GoubayuHeal.Config["shaman_totem"] then
        return
    end

    local point, relativeTo, relativePoint, xOfs, yOfs = GoubayuHeal_TotemFrame:GetPoint()
    -- relativeTo 是框架引用，直接存入 SavedVariables 会导致 1.12 客户端崩溃（错误 #132），必须只存锚点目标名称
    local relativeToName = "UIParent"
    if relativeTo and type(relativeTo) == "table" and relativeTo.GetName then
        local n = relativeTo:GetName()
        if n and n ~= "" then
            relativeToName = n
        end
    end
    GoubayuHeal.Config["shaman_totem"].position = {
        point = point,
        relativeTo = relativeToName,
        relativePoint = relativePoint,
        xOffset = xOfs,
        yOffset = yOfs
    }
end

-- ============================================================
-- 范围检测辅助函数
-- ============================================================

-- 检查图腾是否在范围内（有同名BUFF）
function GoubayuHeal.Totem_IsInRange(elementIndex)
    local elements = TOTEM_ELEMENT_NAMES
    local element = elements[elementIndex]
    local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[element]
    local selectedIndex = elementConfig.selectedIndex or 1
    local skip = elementConfig.skip

    if skip or selectedIndex <= 0 then
        return true
    end

    local totemData = GoubayuHeal_TotemData[elementIndex]
    if totemData and totemData[selectedIndex] then
        local totemName = totemData[selectedIndex].name
        if ShouldSkipRangeCheck(totemName) then
            return true
        end
        local buffName = GetTotemBuffName(totemName)
        return IsTotemBuffActive(buffName)
    end

    return true
end

-- 检查图腾是否可以施放
local function GoubayuHeal_CanCastTotem(totemIndex, totemData)
    local timer = GoubayuHeal.Totem_Timers[totemIndex]
    local now = GetTime()
    local totemName = totemData.name
    local buffName = GetTotemBuffName(totemName)

    -- 冷却判定：按具体图腾技能自己的剩余冷却（每个图腾独立CD）。
    -- 必须放在skip分支之前：火焰新星/地缚/石爪/根基全部在skip列表里，
    -- 若只在else分支检查，这些带CD图腾在duration结束后CD未到时仍会白发并报"未准备好"
    if GoubayuHeal.Totem_GetCooldownRemaining
        and GoubayuHeal.Totem_GetCooldownRemaining(totemName) > 0 then
        return false
    end

    if ShouldSkipRangeCheck(totemName) then
        -- 表里的技能：只看持续时间，有持续时间就不释放
        if timer.durationStart > 0 and timer.duration > 0 then
            local remainingDuration = timer.durationStart + timer.duration - now
            if remainingDuration > 0 then
                return false
            end
        end
        return true
    else
        -- 表外的技能：正常检查
        if timer.durationStart > 0 and timer.duration > 0 then
            local remainingDuration = timer.durationStart + timer.duration - now
            if remainingDuration > 0 then
                if IsTotemBuffActive(buffName) then
                    return false
                end
            end
        end

        return not IsTotemBuffActive(buffName)
    end
end

-- ============================================================
-- 放置单个图腾
-- ============================================================

function GoubayuHeal.Totem_PlaceSingle(elementIndex)
    local elements = TOTEM_ELEMENT_NAMES
    local element = elements[elementIndex]
    local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[element]
    local selectedIndex = elementConfig.selectedIndex or 1
    local skip = elementConfig.skip

    -- 精细图腾管理：该元素本轮已被精细逻辑接管（已插/已在场/CD中）→ 不要覆盖成默认图腾
    -- by 武藤纯子酱 2026.9.21
    if GoubayuHeal.Totem_FineHandled and GoubayuHeal.Totem_FineHandled[elementIndex] then
        return
    end

    if not skip and selectedIndex > 0 then
        local totemData = GoubayuHeal_TotemData[elementIndex]
        if totemData and totemData[selectedIndex] then
            -- 强制回落（净化结束后）：忽略"已在场"判定，只查该图腾自身CD
            local forceDefault = GoubayuHeal.Totem_FineForceDefault
                and GoubayuHeal.Totem_FineForceDefault[elementIndex]
            if forceDefault then
                local cdReady = true
                if GoubayuHeal.Totem_GetCooldownRemaining
                    and GoubayuHeal.Totem_GetCooldownRemaining(totemData[selectedIndex].name) > 0 then
                    cdReady = false
                end
                if cdReady then
                    CastSpellByName(totemData[selectedIndex].name)
                end
            elseif GoubayuHeal_CanCastTotem(elementIndex, totemData[selectedIndex]) then
                CastSpellByName(totemData[selectedIndex].name)
            end
        end
    end
end

-- ============================================================
-- 一键放置：5种预设模式
-- ============================================================

-- 辅助：检查所有图腾是否都超出范围
function GoubayuHeal.Totem_AreAllOutOfRange()
    local elements = TOTEM_ELEMENT_NAMES
    local outOfRangeCount = 0
    local hasActiveTotem = false
    local skipListCount = 0
    local activeCount = 0

    -- 统计在SKIP_RANGE_CHECK_TOTEMS表中的图腾数量 + 实际参与判定的元素数
    -- （阈值基数必须扣除右键禁用/"不使用"的元素，否则禁用任一元素后回收分支永不触发）
    for i = 1, 4 do
        local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[elements[i]]
        local skip = elementConfig.skip
        local selectedIndex = elementConfig.selectedIndex or 1

        if not skip and selectedIndex > 0 then
            activeCount = activeCount + 1
            local totemData = GoubayuHeal_TotemData[i]
            if totemData and totemData[selectedIndex] then
                local totemName = totemData[selectedIndex].name
                if ShouldSkipRangeCheck(totemName) then
                    skipListCount = skipListCount + 1
                end
            end
        end
    end

    local threshold = activeCount - skipListCount
    if threshold < 1 then
        threshold = 1
    end

    -- 统计超出范围的图腾数量
    for i = 1, 4 do
        local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[elements[i]]
        local skip = elementConfig.skip
        local selectedIndex = elementConfig.selectedIndex or 1

        if not skip and selectedIndex > 0 then
            hasActiveTotem = true
            local totemData = GoubayuHeal_TotemData[i]
            if totemData and totemData[selectedIndex] then
                local totemName = totemData[selectedIndex].name
                local timer = GoubayuHeal.Totem_Timers[i]
                local now = GetTime()
                local hasDuration = timer.durationStart > 0 and timer.duration > 0
                    and (timer.durationStart + timer.duration - now > 0)
                local buffName = GetTotemBuffName(totemName)
                local hasBuff = IsTotemBuffActive(buffName)
                local inSkipList = ShouldSkipRangeCheck(totemName)

                if not inSkipList and hasDuration and not hasBuff then
                    outOfRangeCount = outOfRangeCount + 1
                end
            end
        end
    end

    return hasActiveTotem and (outOfRangeCount >= threshold)
end

-- 辅助：检查所有图腾是否都有持续时间
function GoubayuHeal.Totem_AreAllHaveDuration()
    local elements = TOTEM_ELEMENT_NAMES

    for i = 1, 4 do
        local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[elements[i]]
        local skip = elementConfig.skip
        local selectedIndex = elementConfig.selectedIndex or 1

        if not skip and selectedIndex > 0 then
            local timer = GoubayuHeal.Totem_Timers[i]
            local now = GetTime()
            if not (timer.durationStart > 0 and timer.duration > 0
                and (timer.durationStart + timer.duration - now > 0)) then
                return false
            end
        end
    end

    return true
end

-- 辅助：简单检查是否有图腾超出范围（预设2用）
function GoubayuHeal.Totem_HasAnyOutOfRangeSimple()
    local elements = TOTEM_ELEMENT_NAMES

    for i = 1, 4 do
        local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[elements[i]]
        local skip = elementConfig.skip
        local selectedIndex = elementConfig.selectedIndex or 1

        if not skip and selectedIndex > 0 then
            if not GoubayuHeal.Totem_IsInRange(i) then
                return true
            end
        end
    end

    return false
end

-- 预设1: 全部图腾超出范围先回收再补充，其他情况少哪个补哪个
function GoubayuHeal.Totem_PlacePreset1()
    if GoubayuHeal.Totem_AreAllOutOfRange() then
        CastSpellByName(GoubayuHeal.Spell.TotemRecall)
        GoubayuHeal.Totem_ResetAllTimers()
        for i = 1, 4 do
            GoubayuHeal.Totem_PlaceSingle(i)
        end
    else
        local elements = TOTEM_ELEMENT_NAMES
        for i = 1, 4 do
            local element = elements[i]
            local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[element]
            local selectedIndex = elementConfig.selectedIndex or 1
            local skip = elementConfig.skip

            if not skip and selectedIndex > 0 then
                local totemData = GoubayuHeal_TotemData[i]
                if totemData and totemData[selectedIndex] then
                    local totemName = totemData[selectedIndex].name
                    if ShouldSkipRangeCheck(totemName) then
                        GoubayuHeal.Totem_PlaceSingle(i)
                    else
                        if not GoubayuHeal.Totem_IsInRange(i) then
                            GoubayuHeal.Totem_PlaceSingle(i)
                        end
                    end
                end
            end
        end
    end
end

-- 预设2: 只要有图腾超出范围先回收再全部补充
function GoubayuHeal.Totem_PlacePreset2()
    if GoubayuHeal.Totem_AreAllHaveDuration()
        and GoubayuHeal.Totem_HasAnyOutOfRangeSimple() then
        CastSpellByName(GoubayuHeal.Spell.TotemRecall)
        GoubayuHeal.Totem_ResetAllTimers()
        for i = 1, 4 do
            GoubayuHeal.Totem_PlaceSingle(i)
        end
    else
        for i = 1, 4 do
            GoubayuHeal.Totem_PlaceSingle(i)
        end
    end
end

-- 预设3: 缺哪个图腾补哪个图腾，不回收
function GoubayuHeal.Totem_PlacePreset3()
    local elements = TOTEM_ELEMENT_NAMES
    for i = 1, 4 do
        local element = elements[i]
        local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[element]
        local selectedIndex = elementConfig.selectedIndex or 1
        local skip = elementConfig.skip

        if not skip and selectedIndex > 0 then
            local totemData = GoubayuHeal_TotemData[i]
            if totemData and totemData[selectedIndex] then
                local totemName = totemData[selectedIndex].name
                if ShouldSkipRangeCheck(totemName) then
                    GoubayuHeal.Totem_PlaceSingle(i)
                else
                    if not GoubayuHeal.Totem_IsInRange(i) then
                        GoubayuHeal.Totem_PlaceSingle(i)
                    end
                end
            end
        end
    end
end

-- 预设4: 全部超范围自动回收，不补充
function GoubayuHeal.Totem_PlacePreset4()
    if GoubayuHeal.Totem_AreAllOutOfRange() then
        CastSpellByName(GoubayuHeal.Spell.TotemRecall)
        GoubayuHeal.Totem_ResetAllTimers()
    end
end

-- 预设5: 什么也不做
function GoubayuHeal.Totem_PlacePreset5()
end

-- 风系图腾自动切换（可选项，默认关）：
--   ① 小队无战士、但有猎人/盗贼：方案是风怒图腾 → 自动换风之优雅图腾
--   ② 小队战士/猎人/盗贼都没有，且自己没学风暴打击（非增强萨）：
--      方案是风怒/风之优雅 → 自动换宁静之风图腾
-- 返回应替换的图腾名；不满足条件返回 nil
-- by 武藤纯子酱 2026.9.21
function GoubayuHeal.Totem_FineAirAutoSwitch()
    local f = GoubayuHeal.Totem_FineEnsure()
    -- 只受自身开关控制（不要求"启用精细图腾管理"）
    if not f or (tonumber(f.airAutoSwitch) or 0) ~= 1 then
        return nil
    end

    local cfg = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
    local elementConfig = cfg and cfg.elements and cfg.elements.Air
    if not elementConfig then
        return nil
    end
    local idx = elementConfig.selectedIndex or 1
    local airData = GoubayuHeal_TotemData[4]
    local cur = (airData and airData[idx]) and airData[idx].name
    if not cur then
        return nil
    end

    local WF = GoubayuHeal.TotemData.Windfury
    local GOA = GoubayuHeal.TotemData.GraceOfAir
    local TA = GoubayuHeal.TotemData.TranquilAir

    -- 风系表顺序固定：1 宁静之风 2 根基 3 风怒 4 风之优雅 5 自然抗 6 风墙 7 哨塔
    -- 仅当方案风系图腾是"风怒/风之优雅/宁静之风"三者之一时才自动更换；
    -- 其他风系图腾（根基/自然抗性/风墙/哨塔）不受影响
    -- by 武藤纯子酱 2026.9.21
    local WF_INDEX, GOA_INDEX, TA_INDEX = 3, 4, 1
    local isWF = (tonumber(idx) == WF_INDEX) or (cur == WF)
    local isGOA = (tonumber(idx) == GOA_INDEX) or (cur == GOA)
    local isTA = (tonumber(idx) == TA_INDEX) or (cur == TA)
    if (not isWF) and (not isGOA) and (not isTA) then
        return nil
    end

    local hasWarrior, hasHunter, hasRogue = false, false, false
    local shamanCount = 1 -- 自己
    local function check(u)
        if not UnitExists(u) then
            return
        end
        local _, class = UnitClass(u)
        if class == "WARRIOR" then
            hasWarrior = true
        elseif class == "HUNTER" then
            hasHunter = true
        elseif class == "ROGUE" then
            hasRogue = true
        elseif class == "SHAMAN" then
            shamanCount = shamanCount + 1
        end
    end

    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        -- 风系图腾增益只作用于自己的小队：团队时按小队号过滤，只统计本小队成员，且跳过自己
        -- （原先扫全团：别的队有战士就会误判成"有战士"→风怒，忽略本小队的猎/盗；
        -- 且 raidN 含自己会把 shamanCount 多算一次，单人萨满也被当成"多萨满"）
        -- by 武藤纯子酱 2026.10.10
        local mySubgroup = nil
        for i = 1, numRaid do
            if UnitIsUnit("raid" .. i, "player") then
                local _, _, sub = GetRaidRosterInfo(i)
                mySubgroup = sub
                break
            end
        end
        for i = 1, numRaid do
            local u = "raid" .. i
            if not UnitIsUnit(u, "player") then
                local _, _, sub = GetRaidRosterInfo(i)
                if mySubgroup and sub == mySubgroup then
                    check(u)
                end
            end
        end
    else
        for i = 1, GetNumPartyMembers() do
            check("party" .. i)
        end
    end

    -- 是否增强萨：法术书里有风暴打击
    local hasStormstrike = false
    if GoubayuHeal.Stormstrike and GoubayuHeal.GetSpellBookSlot then
        -- 注意：GetSpellBookSlot 对"没找到"会缓存并返回 false，不能用 ~= nil 判断
        local slot = GoubayuHeal.GetSpellBookSlot(GoubayuHeal.Stormstrike)
        if slot then
            hasStormstrike = true
        end
    end

    local desired
    if hasStormstrike then
        -- 增强萨：方案优雅/宁静之风→保持；方案风怒→有战士保持风怒、无战士换优雅
        if isTA then
            desired = TA
        elseif isGOA then
            desired = GOA
        elseif hasWarrior then
            desired = WF
        else
            desired = GOA
        end
    else
        -- 非增强（奶萨）：有战士→风怒；无战士有猎/盗→优雅；都没有→宁静之风
        if hasWarrior then
            desired = WF
        elseif hasHunter or hasRogue then
            desired = GOA
        else
            desired = TA
        end
    end

    -- 多萨满：按自己身上已有的风系 buff 避免重复
    -- 队伍里只有自己一个萨满时不可能冲突 → 直接跳过这层判断
    -- 例：别的萨满已给风怒，而你要上的也是风怒 → 改上优雅；风怒+优雅都有 → 上宁静之风
    -- 注意：若该 buff 来自"自己已放置的图腾"，不算冲突（否则会把自己插的风怒误判成别人的而换掉）
    -- by 武藤纯子酱 2026.9.23
    if shamanCount <= 1 then
        return desired
    end

    local function selfPlacedTotem(name)
        local placed = GoubayuHeal.Totem_ActivePlacedTotems
        if placed then
            for _, d in pairs(placed) do
                if d and d.name == name then
                    return true
                end
            end
        end
        -- 兜底（带惰性）：自己施放过该图腾后、在它的持续时间（存活期）内都算"自己的"。
        -- 已放置清单是每秒扫描更新的，存在"自己刚插、扫描还没登记"的空档，
        -- 判定过紧会导致自己的 buff 被误判成别人的而反复换图腾
        local castAt = GoubayuHeal.Totem_CastedAt and GoubayuHeal.Totem_CastedAt[name]
        if castAt then
            local dur = 120
            local idx = GoubayuHeal_Totem_FindElement(name)
            if idx and GoubayuHeal_TotemData[idx] then
                for _, totem in ipairs(GoubayuHeal_TotemData[idx]) do
                    if totem.name == name then
                        dur = totem.duration or 120
                        break
                    end
                end
            end
            if (GetTime() - castAt) < dur then
                return true
            end
        end
        return false
    end

    local hasWFBuff = IsTotemBuffActive(GetTotemBuffName(WF))
    local hasGOABuff = IsTotemBuffActive(GetTotemBuffName(GOA))
    if hasWFBuff and hasGOABuff then
        return TA
    end
    if desired == WF and hasWFBuff and not selfPlacedTotem(WF) then
        return GOA
    end
    if desired == GOA and hasGOABuff and not selfPlacedTotem(GOA) then
        return WF
    end

    return desired
end

-- 该元素位上是否存在任意图腾（不论是不是方案里选的那个；含手动放置的）
-- by 武藤纯子酱 2026.9.21
function GoubayuHeal.Totem_ElementHasAnyTotem(elementIndex)
    local element = TOTEM_ELEMENT_NAMES[elementIndex]
    local placed = GoubayuHeal.Totem_ActivePlacedTotems
    if placed then
        for _, d in pairs(placed) do
            if d and d.element and (d.element == element or d.element == elementIndex) then
                return true
            end
        end
    end
    return false
end

-- 预设6: 尊重手动图腾——该元素位上只要有任何图腾在场就不动；
-- 图腾消失（被消耗/过期/手动回收）后才补方案图腾
-- by 武藤纯子酱 2026.9.21
function GoubayuHeal.Totem_PlacePreset6()
    local elements = TOTEM_ELEMENT_NAMES
    for i = 1, 4 do
        local element = elements[i]
        local elementConfig = GoubayuHeal.Config["shaman_totem"].elements[element]
        local selectedIndex = elementConfig.selectedIndex or 1
        local skip = elementConfig.skip

        if not skip and selectedIndex > 0 then
            -- 强制回落（净化结束后）：即使位上有图腾（净化图腾）也要补方案图腾
            local forceDefault = GoubayuHeal.Totem_FineForceDefault
                and GoubayuHeal.Totem_FineForceDefault[i]
            if forceDefault or not GoubayuHeal.Totem_ElementHasAnyTotem(i) then
                GoubayuHeal.Totem_PlaceSingle(i)
            end
        end
    end
end

-- 一键放置主入口
function GoubayuHeal.Totem_PlaceAll()
    -- 放置前先刷新"已放置图腾"清单（该扫描平时只在图腾窗口显示时每秒跑），
    -- 否则窗口隐藏时清单是旧的，预设6"尊重手动图腾"会看不到你手动插的图腾
    -- by 武藤纯子酱 2026.9.21
    if GoubayuHeal.Totem_CheckSummonedUnits then
        pcall(GoubayuHeal.Totem_CheckSummonedUnits)
    end

    -- 精细图腾管理优先：先处理命中的元素（条件图腾/自我净化图腾），被接管的元素本轮不再插默认
    -- by 武藤纯子酱 2026.9.21
    GoubayuHeal.Totem_FineHandled = nil
    if GoubayuHeal.Totem_FinePlaceAll then
        pcall(GoubayuHeal.Totem_FinePlaceAll)
    end

    local preset = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
        and GoubayuHeal.Config["shaman_totem"].placePreset or 1

    if preset == 1 then
        GoubayuHeal.Totem_PlacePreset1()
    elseif preset == 2 then
        GoubayuHeal.Totem_PlacePreset2()
    elseif preset == 3 then
        GoubayuHeal.Totem_PlacePreset3()
    elseif preset == 4 then
        GoubayuHeal.Totem_PlacePreset4()
    elseif preset == 5 then
        GoubayuHeal.Totem_PlacePreset5()
    elseif preset == 6 then
        GoubayuHeal.Totem_PlacePreset6()
    end

    -- 1.12 无 GetTotemInfo，无法对比槽位变化；返回值未使用，直接视为已施放
    return true
end

-- ============================================================
-- 队伍战斗判定（用于"仅战斗中自动插图腾"）
-- 定义：自己 / 小队(团队)成员 / 各自宠物 中至少一个处于战斗
-- by 武藤纯子酱 2026.9.21
-- ============================================================

function GoubayuHeal.Totem_GroupInCombat()
    if not UnitAffectingCombat then
        return true
    end
    if UnitAffectingCombat("player") then
        return true
    end

    local numRaid = GetNumRaidMembers()
    local count = (numRaid > 0) and numRaid or GetNumPartyMembers()
    local prefix = (numRaid > 0) and "raid" or "party"

    for i = 1, count do
        local u = prefix .. i
        if UnitExists(u) and UnitAffectingCombat(u) then
            return true
        end
        local pu = prefix .. "pet" .. i
        if UnitExists(pu) and UnitAffectingCombat(pu) then
            return true
        end
    end

    if UnitExists("pet") and UnitAffectingCombat("pet") then
        return true
    end

    return false
end

-- ============================================================
-- 精细图腾管理（条件图腾 + 自我净化图腾）
-- 优先级：自我净化图腾 > 精细条件图腾 > 方案默认图腾
-- by 武藤纯子酱 2026.9.21
-- ============================================================

-- 配置补默认字段（旧存档兼容）
function GoubayuHeal.Totem_FineEnsure()
    local cfg = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
    if not cfg then
        return nil
    end
    if type(cfg.fine) ~= "table" then
        cfg.fine = {}
    end
    local f = cfg.fine
    if f.enabled == nil then f.enabled = 0 end
    if f.revertAfterCombat == nil then f.revertAfterCombat = 0 end
    if f.selfPoison == nil then f.selfPoison = 0 end
    if f.selfDisease == nil then f.selfDisease = 0 end
    if f.manaSpringPct == nil then f.manaSpringPct = 0 end
    if f.recallAfterCombat == nil then f.recallAfterCombat = 0 end
    -- 条件图腾自身CD中时是否回退方案默认图腾（默认开）
    -- by 武藤纯子酱 2026.9.21
    if f.revertOnCooldown == nil then f.revertOnCooldown = 1 end
    -- 风系图腾自动切换（默认关）
    if f.airAutoSwitch == nil then f.airAutoSwitch = 0 end
    -- 战斗结束后行为（滑块）：0=只要怪在就保持（旧 revertAfterCombat=0 且 recall=0）
    -- 1=换回默认图腾（旧 revertAfterCombat=1）；2=回收图腾（旧 recallAfterCombat=1）
    -- by 武藤纯子酱 2026.9.21
    if f.combatEndMode == nil then
        if f.recallAfterCombat == 1 then
            f.combatEndMode = 2
        elseif f.revertAfterCombat == 1 then
            f.combatEndMode = 1
        else
            f.combatEndMode = 0
        end
    end
    if type(f.rules) ~= "table" then f.rules = {} end
    return f
end

-- 预设条件图腾规则（敌人名字按客户端语言匹配：zhCN 为已验证名单，enUS 留空由用户填写）
function GoubayuHeal.Totem_FineDefaultRules()
    local rules = {}
    local tremor = GoubayuHeal.TotemData and GoubayuHeal.TotemData.Tremor
    local grounding = GoubayuHeal.TotemData and GoubayuHeal.TotemData.Grounding

    if (GetLocale() == "zhCN") then
        table.insert(rules, {
            enabled = 1, element = "Earth", totem = tremor, range = 80, insight = 1,
            enemies = "格拉斯,奈法利安,死亡骑士,孟菲斯托斯,皇后,魔鳞护龙者,魔鳞监工,魔鳞巨龙,圣所梦游者",
        })
        table.insert(rules, {
            enabled = 1, element = "Air", totem = grounding, range = 60, insight = 1,
            enemies = "哈卡,女皇,战车,骑士,主教",
        })
    else
        table.insert(rules, {
            enabled = 1, element = "Earth", totem = tremor, range = 80, insight = 1,
            enemies = "",
        })
        table.insert(rules, {
            enabled = 1, element = "Air", totem = grounding, range = 60, insight = 1,
            enemies = "",
        })
    end
    return rules
end

-- 敌人名单采集：玩家目标 + 团队/小队成员的目标（可取距离/视野）+ Nampower 施法者（近8秒，按名字匹配）
function GoubayuHeal.Totem_UpdateEnemyList()
    local list = {}
    local seen = {}

    local function add(unit, canMeasure)
        if not unit or not UnitExists(unit) then
            return
        end
        if UnitCanAttack and not UnitCanAttack("player", unit) then
            return
        end
        local name = GoubayuHeal.UnitName and GoubayuHeal.UnitName(unit) or UnitName(unit)
        if name and name ~= "" and not seen[name] then
            seen[name] = true
            table.insert(list, { name = name, unit = canMeasure and unit or nil })
        end
    end

    add("target", true)

    local numRaid = GetNumRaidMembers()
    if numRaid > 0 then
        for i = 1, numRaid do
            add("raid" .. i .. "target", true)
        end
    else
        for i = 1, GetNumPartyMembers() do
            add("party" .. i .. "target", true)
        end
    end

    -- Nampower 施法者补充（无法判阵营，靠名字匹配；GUID 仍可用于测距/视野）
    local casters = GoubayuHeal.Totem_RecentCasters
    if casters then
        local now = GetTime()
        for name, entry in pairs(casters) do
            if name and name ~= "" and not seen[name] and (now - (entry.time or 0)) <= 8 then
                seen[name] = true
                table.insert(list, { name = name, unit = entry.guid })
            end
        end
    end

    GoubayuHeal.Totem_EnemyList = list
end

-- Nampower 施法者名采集（SPELL_START_OTHER / SPELL_GO_OTHER：第3参 = 施法者GUID）
local GoubayuHeal_Totem_CasterFrame
function GoubayuHeal.Totem_InitCasterTracking()
    if GoubayuHeal_Totem_CasterFrame or not GetNampowerVersion then
        return
    end
    GoubayuHeal_Totem_CasterFrame = CreateFrame("Frame")
    GoubayuHeal_Totem_CasterFrame:RegisterEvent("SPELL_START_OTHER")
    GoubayuHeal_Totem_CasterFrame:RegisterEvent("SPELL_GO_OTHER")
    GoubayuHeal_Totem_CasterFrame:SetScript("OnEvent", function()
        local guid = arg3
        if not guid then
            return
        end
        local name = GoubayuHeal.UnitName and GoubayuHeal.UnitName(guid)
        if name and name ~= "" then
            GoubayuHeal.Totem_RecentCasters = GoubayuHeal.Totem_RecentCasters or {}
            GoubayuHeal.Totem_RecentCasters[name] = { time = GetTime(), guid = guid }
        end
    end)
end

-- UnitXP 可用性（本文件内独立探测，避免跨文件局部变量）
local function Totem_FineHasUnitXP()
    if GoubayuHeal.Totem_hasUnitXP == nil then
        GoubayuHeal.Totem_hasUnitXP = (pcall and pcall(UnitXP, "nop", "nop")) or false
    end
    return GoubayuHeal.Totem_hasUnitXP
end

-- 规则条件：敌人名单命中（可选距离/视野）
function GoubayuHeal.Totem_FineRuleMatches(rule)
    if not rule or rule.enabled == 0 or not rule.enemies then
        return false
    end

    local names = {}
    for n in string.gfind(tostring(rule.enemies), "[^,，;；%s]+") do
        names[n] = true
    end
    if not next(names) then
        return false
    end

    local range = tonumber(rule.range) or 0
    local list = GoubayuHeal.Totem_EnemyList or {}

    for _, e in ipairs(list) do
        if e.name and names[e.name] then
            if range <= 0 or not e.unit then
                -- 不限距离，或该来源无法测量（按"命中"处理，避免漏插）
                return true
            end

            if Totem_FineHasUnitXP() then
                local okD, d = pcall(UnitXP, "distanceBetween", "player", e.unit)
                if okD and type(d) == "number" and d <= range then
                    if rule.insight ~= 1 then
                        return true
                    end
                    local okS, ins = pcall(UnitXP, "inSight", "player", e.unit)
                    if (not okS) or (ins ~= false) then
                        return true
                    end
                end
            elseif CheckInteractDistance and range >= 28 and CheckInteractDistance(e.unit, 4) then
                return true
            end
        end
    end

    return false
end

-- 自我净化需求：自己身上有"未被驱散黑名单屏蔽"的毒/病时，返回对应净化图腾名
function GoubayuHeal.Totem_FineSelfCleanse()
    local f = GoubayuHeal.Totem_FineEnsure()
    if not f or f.enabled ~= 1 then
        return nil
    end
    if (f.selfPoison ~= 1) and (f.selfDisease ~= 1) then
        return nil
    end
    if not GoubayuHeal.Dispel_GetDebuffInfo then
        return nil
    end

    local blacklist = GoubayuHeal.Config and GoubayuHeal.Config["dispel_blacklist"]
    local wantPoison, wantDisease = false, false

    -- 扫描一个单位是否有"未被黑名单屏蔽"的毒/病
    local function scanUnit(unit)
        for i = 1, 32 do
            local name, dtype = GoubayuHeal.Dispel_GetDebuffInfo(unit, i)
            if not name then
                break
            end
            if name ~= "" and not (blacklist and blacklist[name]) then
                if dtype == "Poison" then
                    wantPoison = true
                elseif dtype == "Disease" then
                    wantDisease = true
                end
            end
        end
    end

    -- 自己
    scanUnit("player")

    -- 本小队成员（实时判定：每次重新取自己的 subgroup，团长换队后立即生效）
    -- 图腾只净化本小队，故这里必须按"自己所在小队"过滤，而不是全团
    -- by 武藤纯子酱 2026.9.24
    local numRaid = GetNumRaidMembers()
    local function inOwnSubgroup(u)
        if not (UnitExists(u) and not UnitIsDeadOrGhost(u)) then
            return false
        end
        if GoubayuHeal.Dispel_IsWithinRange and not GoubayuHeal.Dispel_IsWithinRange(u, 26) then
            return false
        end
        if numRaid > 0 then
            -- 团队：按实时 subgroup 过滤（GetRaidRosterInfo 第 3 返回值为小队号）
            if not GetRaidRosterInfo then
                return false
            end
            local mySub
            for i = 1, numRaid do
                local rname = GetRaidRosterInfo(i)
                if rname and (UnitIsUnit and UnitIsUnit("player", "raid" .. i)) then
                    local _, _, sub = GetRaidRosterInfo(i)
                    mySub = sub
                    break
                end
            end
            if not mySub then
                return false
            end
            for i = 1, numRaid do
                local rname = GetRaidRosterInfo(i)
                if rname and (UnitIsUnit and UnitIsUnit(u, "raid" .. i)) then
                    local _, _, sub = GetRaidRosterInfo(i)
                    return sub == mySub
                end
            end
            return false
        end
        -- 小队：本队成员与队宠
        for i = 1, 4 do
            if UnitIsUnit and (UnitIsUnit(u, "party" .. i) or UnitIsUnit(u, "partypet" .. i)) then
                return true
            end
        end
        return false
    end

    local count = (numRaid > 0) and numRaid or GetNumPartyMembers()
    local prefix = (numRaid > 0) and "raid" or "party"
    for i = 1, count do
        local u = prefix .. i
        if inOwnSubgroup(u) then
            scanUnit(u)
        end
    end

    if wantDisease and (f.selfDisease == 1) then
        return GoubayuHeal.TotemData.DiseaseCleansing
    end
    if wantPoison and (f.selfPoison == 1) then
        return GoubayuHeal.TotemData.PoisonCleansing
    end
    return nil
end

-- 某元素本轮应插的"精细图腾"数据（自我净化 > 条件规则），无则返回 nil
function GoubayuHeal.Totem_FineDesiredData(elementIndex)
    local f = GoubayuHeal.Totem_FineEnsure()
    if not f then
        return nil
    end

    -- 风系自动切换只受自身开关控制：主开关（启用精细图腾管理）关闭时也要生效
    -- by 武藤纯子酱 2026.9.21
    if f.enabled ~= 1 then
        if elementIndex == 4 then
            local alt = GoubayuHeal.Totem_FineAirAutoSwitch()
            local airData = GoubayuHeal_TotemData[4]
            if alt and airData then
                for i = 1, table.getn(airData) do
                    if airData[i].name == alt then
                        return airData[i]
                    end
                end
            end
        end
        return nil
    end

    local elements = TOTEM_ELEMENT_NAMES
    local element = elements[elementIndex]
    local totemData = GoubayuHeal_TotemData[elementIndex]
    if not totemData then
        return nil
    end

    local function findData(name)
        if not name then
            return nil
        end
        for i = 1, table.getn(totemData) do
            if totemData[i].name == name then
                return totemData[i]
            end
        end
        return nil
    end

    -- ① 自我净化图腾（最高优先级；返回第二值 true 表示"持续卡CD补插直到debuff消失"）
    local cleanse = GoubayuHeal.Totem_FineSelfCleanse()
    if cleanse then
        local d = findData(cleanse)
        if d then
            return d, true
        end
    end

    -- ② 条件图腾（战斗结束后行为：1/2 时非战斗不参与；0 则只要怪在就保持）
    local endMode = tonumber(f.combatEndMode) or 0
        local skipRules = (endMode == 1 or endMode == 2) and UnitAffectingCombat
            and not UnitAffectingCombat("player")
        if not skipRules then
            for _, rule in ipairs(f.rules) do
                if rule.element == element and GoubayuHeal.Totem_FineRuleMatches(rule) then
                    local d = findData(rule.totem)
                    if d then
                        return d
                    end
                end
            end
        end

    -- 法力之泉（开关类）：优先级低于条件规则、高于方案默认
    -- by 武藤纯子酱 2026.9.21
    local mp2 = tonumber(f.manaSpringPct) or 0
    if mp2 > 0 and element == "Water" then
        local mana = (UnitMana and UnitMana("player")) or 0
        local manaMax = (UnitManaMax and UnitManaMax("player")) or 0
        if manaMax > 0 and (mana / manaMax * 100) < mp2 then
            local d = findData(GoubayuHeal.TotemData.ManaSpring)
            if d then
                return d
            end
        end
    end

    -- ③ 风系自动切换（无战士/有猎盗等）：作为风元素在规则之后的兜底
    if element == "Air" then
        local alt = GoubayuHeal.Totem_FineAirAutoSwitch()
        if alt then
            local d = findData(alt)
            if d then
                return d
            end
        end
    end

    return nil
end

-- 该图腾是否已在场（已放置清单优先，退回buff判定）
local function Totem_FineIsActive(desiredName)
    local placed = GoubayuHeal.Totem_ActivePlacedTotems
    if placed then
        for _, d in pairs(placed) do
            if d and d.name == desiredName then
                return true
            end
        end
    end
    if GetTotemBuffName and IsTotemBuffActive then
        if IsTotemBuffActive(GetTotemBuffName(desiredName)) then
            return true
        end
    end
    return false
end

-- 放置某元素的精细图腾；返回 true = 该元素本轮由精细逻辑接管（不要再插默认）
function GoubayuHeal.Totem_FinePlace(elementIndex)
    local desired, keepPressing = GoubayuHeal.Totem_FineDesiredData(elementIndex)
    if not desired then
        return false
    end

    -- 自我净化：只要还有可驱散的毒/病就持续补插（不等图腾持续时间走完），
    -- 直到身上没有对应 debuff（黑名单项不计）才回退到条件/默认图腾
    -- by 武藤纯子酱 2026.9.21
    if keepPressing then
        if GoubayuHeal.Totem_GetCooldownRemaining
            and GoubayuHeal.Totem_GetCooldownRemaining(desired.name) > 0 then
            local f = GoubayuHeal.Totem_FineEnsure()
            if f and (tonumber(f.revertOnCooldown) or 1) == 1 then
                return false
            end
            return true
        end
        CastSpellByName(desired.name)
        return true
    end

    -- 已在场 → 保持（也不换默认）
    if Totem_FineIsActive(desired.name) then
        return true
    end

    -- 该图腾自身CD未就绪：开了"CD中回退默认"就让默认图腾顶上（返回 false），否则本轮空置
    if GoubayuHeal.Totem_GetCooldownRemaining
        and GoubayuHeal.Totem_GetCooldownRemaining(desired.name) > 0 then
        local f = GoubayuHeal.Totem_FineEnsure()
        if f and (tonumber(f.revertOnCooldown) or 1) == 1 then
            return false
        end
        return true
    end

    CastSpellByName(desired.name)
    return true
end

-- 一键放置前统一处理：刷新敌人名单 + 逐元素判定/放置，记录被接管的元素
function GoubayuHeal.Totem_FinePlaceAll()
    local f = GoubayuHeal.Totem_FineEnsure()
    if not f or f.enabled ~= 1 then
        GoubayuHeal.Totem_FineHandled = nil
        return
    end

    GoubayuHeal.Totem_InitCasterTracking()
    GoubayuHeal.Totem_UpdateEnemyList()
    GoubayuHeal.Totem_FineForceDefault = nil

    local handled = nil
    for i = 1, 4 do
        if GoubayuHeal.Totem_FineDesiredData(i) then
            -- 只有精细逻辑真正接管（已插/已在场）才标记；CD中回退时交由默认路径补插
            if GoubayuHeal.Totem_FinePlace(i) then
                handled = handled or {}
                handled[i] = true
            end
        end
    end
    GoubayuHeal.Totem_FineHandled = handled

    -- 净化结束后的强制回落：水元素位上当前是净化图腾（清毒/祛病，无论谁插的）、
    -- 而这一轮已经不需要净化 → 顶掉净化图腾、强制补回方案水图腾
    -- （即使预设是"尊重手动图腾"也不保留净化图腾）
    -- by 武藤纯子酱 2026.9.23
    if not GoubayuHeal.Totem_FineSelfCleanse() then
        local activeCleanse = false
        local placed = GoubayuHeal.Totem_ActivePlacedTotems
        if placed then
            for _, d in pairs(placed) do
                if d and d.name and d.element
                    and (d.element == "Water" or d.element == 2)
                    and (d.name == GoubayuHeal.TotemData.PoisonCleansing
                        or d.name == GoubayuHeal.TotemData.DiseaseCleansing) then
                    activeCleanse = true
                    break
                end
            end
        end
        -- 手动插的图腾可能还没被扫描登记，再用光环兜底判断
        if not activeCleanse and GetTotemBuffName and IsTotemBuffActive then
            local pb = GetTotemBuffName(GoubayuHeal.TotemData.PoisonCleansing)
            local db = GetTotemBuffName(GoubayuHeal.TotemData.DiseaseCleansing)
            if (pb and IsTotemBuffActive(pb)) or (db and IsTotemBuffActive(db)) then
                activeCleanse = true
            end
        end
        if activeCleanse then
            if handled then
                handled[2] = nil
            end
            GoubayuHeal.Totem_FineHandled = handled
            GoubayuHeal.Totem_FineForceDefault = { [2] = true }
        end
    end
end

-- ============================================================
-- 精细图腾管理设置窗口
-- by 武藤纯子酱 2026.9.21
-- ============================================================

local TOTEM_FINE_MAX_RULES = 12
local TOTEM_FINE_ELEMENTS = { "Fire", "Water", "Earth", "Air" }
local TotemFineWin
local TotemFineRows = {}
local TotemFineHead = {}

local function Totem_FineFS(parent, text, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetFont("Fonts\\FRIZQT__.TTF", size or 10, "OUTLINE")
    fs:SetText(text or "")
    fs:SetTextColor(r or 1, g or 1, b or 1)
    return fs
end

local function Totem_FineButton(parent, width, height, text, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(width)
    b:SetHeight(height)
    if GoubayuHeal.UI and GoubayuHeal.UI.ApplyFlatBackdrop then
        GoubayuHeal.UI.ApplyFlatBackdrop(b, 0.07, 0.07, 0.07, 0.95)
    end
    b.text = Totem_FineFS(b, text, 9, 1, 1, 1)
    b.text:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetScript("OnClick", function()
        if onClick then
            onClick()
        end
        if GoubayuHeal.Totem_FineRefreshWindow then
            pcall(GoubayuHeal.Totem_FineRefreshWindow)
        end
    end)
    return b
end

-- 主设置页同款开关（滑块式，轨道+圆钮）
local function Totem_FineCheck(parent, labelText, onChange)
    local sw = CreateFrame("Button", nil, parent)
    sw:SetWidth(40)
    sw:SetHeight(18)
    sw.checked = false

    local track = sw:CreateTexture(nil, "BACKGROUND")
    track:SetTexture("Interface\\Buttons\\WHITE8X8")
    track:SetPoint("TOPLEFT", sw, "TOPLEFT", 1, -1)
    track:SetPoint("BOTTOMRIGHT", sw, "BOTTOMRIGHT", -1, 1)
    track:SetVertexColor(0.15, 0.15, 0.15, 1)

    local knob = sw:CreateTexture(nil, "OVERLAY")
    knob:SetTexture("Interface\\Buttons\\WHITE8X8")
    knob:SetWidth(14)
    knob:SetHeight(14)

    sw.SetChecked = function(self, val)
        sw.checked = val and true or false
        if sw.checked then
            track:SetVertexColor(0.78, 0.56, 0.25, 1)
            knob:SetVertexColor(0.90, 0.87, 0.80, 1)
            knob:ClearAllPoints()
            knob:SetPoint("RIGHT", sw, "RIGHT", -3, 0)
        else
            track:SetVertexColor(0.15, 0.15, 0.15, 1)
            knob:SetVertexColor(0.55, 0.55, 0.55, 1)
            knob:ClearAllPoints()
            knob:SetPoint("LEFT", sw, "LEFT", 3, 0)
        end
    end

    sw.label = Totem_FineFS(sw, labelText, 10, 1, 1, 1)
    sw.label:SetPoint("LEFT", sw, "RIGHT", 4, 0)

    sw:SetScript("OnClick", function()
        sw:SetChecked(not sw.checked)
        if onChange then
            onChange(sw.checked)
        end
        if GoubayuHeal.Totem_FineRefreshWindow then
            pcall(GoubayuHeal.Totem_FineRefreshWindow)
        end
    end)

    sw:SetChecked(false)
    return sw
end

local function Totem_FineEdit(parent, width)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetWidth(width)
    e:SetHeight(20)
    e:SetAutoFocus(false)
    e:SetTextInsets(4, 4, 0, 0)
    e:SetFontObject(GameFontNormalSmall)
    e:SetTextColor(1, 1, 1)
    if GoubayuHeal.UI and GoubayuHeal.UI.ApplyFlatBackdrop then
        GoubayuHeal.UI.ApplyFlatBackdrop(e, 0.025, 0.025, 0.025, 0.9)
    end
    return e
end

local function Totem_FineTotemNames(element)
    local names = {}
    for i = 1, 4 do
        if TOTEM_ELEMENT_NAMES[i] == element then
            local data = GoubayuHeal_TotemData[i]
            if data then
                for j = 1, table.getn(data) do
                    table.insert(names, data[j].name)
                end
            end
        end
    end
    return names
end

local function Totem_FineRule(index)
    local f = GoubayuHeal.Totem_FineEnsure()
    return f and f.rules[index] or nil
end

local function Totem_FineCreateRow(parent, i)
    local row = CreateFrame("Frame", nil, parent)
    row:SetWidth(600)
    row:SetHeight(26)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 14, -106 - (i - 1) * 30)
    row.index = i

    row.names = Totem_FineEdit(row, 226)
    row.names:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.names:SetScript("OnTextChanged", function()
        local rule = Totem_FineRule(row.index)
        if rule and not row.refreshing then
            rule.enemies = this:GetText() or ""
        end
    end)

    row.elementDD = GoubayuHeal.UI.CreateDropDown(row, 76, function()
        local list = {}
        for _, e in ipairs(TOTEM_FINE_ELEMENTS) do
            table.insert(list, { text = (GoubayuHeal.Element and GoubayuHeal.Element[e]) or e,
                value = e })
        end
        return list
    end, function(text, buttonClicked, info)
        local rule = Totem_FineRule(row.index)
        local v = info and info.value
        if rule and v then
            rule.element = v
            -- 换了元素后，图腾不在该元素列表里则取第一个
            local names = Totem_FineTotemNames(v)
            local found = false
            for _, nm in ipairs(names) do
                if nm == rule.totem then
                    found = true
                    break
                end
            end
            if not found then
                rule.totem = names[1]
            end
        end
        -- 下拉不会自动回显，必须自己设文本（此前漏了，选完名字不变）
        row.elementDD:SetText(text or "")
    end)
    row.elementDD:SetPoint("LEFT", row.names, "RIGHT", 6, 0)

    row.totemDD = GoubayuHeal.UI.CreateDropDown(row, 150, function()
        local list = {}
        local rule = Totem_FineRule(row.index)
        local element = (rule and rule.element) or "Earth"
        for _, nm in ipairs(Totem_FineTotemNames(element)) do
            table.insert(list, { text = nm, value = nm })
        end
        return list
    end, function(text, buttonClicked, info)
        local rule = Totem_FineRule(row.index)
        local v = info and info.value
        if rule and v then
            rule.totem = v
        end
        row.totemDD:SetText(text or "")
    end)
    row.totemDD:SetPoint("LEFT", row.elementDD, "RIGHT", 6, 0)

    row.range = Totem_FineEdit(row, 40)
    row.range:SetPoint("LEFT", row.totemDD, "RIGHT", 6, 0)
    row.range:SetScript("OnTextChanged", function()
        local rule = Totem_FineRule(row.index)
        if rule and not row.refreshing then
            rule.range = tonumber(this:GetText()) or 0
        end
    end)

    row.insight = Totem_FineCheck(row, GoubayuHeal.TotemUI.FineSight, function(checked)
        local rule = Totem_FineRule(row.index)
        if rule then
            rule.insight = checked and 1 or 0
        end
    end)
    row.insight:SetPoint("LEFT", row.range, "RIGHT", 8, 0)

    row.enabled = Totem_FineCheck(row, GoubayuHeal.TotemUI.FineEnable, function(checked)
        local rule = Totem_FineRule(row.index)
        if rule then
            rule.enabled = checked and 1 or 0
        end
    end)
    row.enabled:SetPoint("LEFT", row.insight.label, "RIGHT", 10, 0)

    row.up = Totem_FineButton(row, 20, 20, "升", function()
        local f = GoubayuHeal.Totem_FineEnsure()
        local idx = row.index
        if f and idx > 1 and f.rules[idx] then
            f.rules[idx], f.rules[idx - 1] = f.rules[idx - 1], f.rules[idx]
        end
    end)
    row.up:SetPoint("LEFT", row.enabled.label, "RIGHT", 10, 0)

    row.down = Totem_FineButton(row, 20, 20, "降", function()
        local f = GoubayuHeal.Totem_FineEnsure()
        local idx = row.index
        if f and f.rules[idx] and f.rules[idx + 1] then
            f.rules[idx], f.rules[idx + 1] = f.rules[idx + 1], f.rules[idx]
        end
    end)
    row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)

    row.del = Totem_FineButton(row, 16, 20, "X", function()
        local f = GoubayuHeal.Totem_FineEnsure()
        if f and f.rules[row.index] then
            table.remove(f.rules, row.index)
        end
    end)
    row.del:SetPoint("LEFT", row.down, "RIGHT", 2, 0)

    row.insight:SetChecked(false)
    row.enabled:SetChecked(true)
    return row
end

function GoubayuHeal.Totem_FineRefreshWindow()
    local f = GoubayuHeal.Totem_FineEnsure()
    if not TotemFineWin or not f then
        return
    end

    local function sync(cb, on)
        if cb then
            cb:SetChecked(on)
        end
    end

    local function focused(e)
        -- HasFocus 经由元表提供，直接取字段恒 nil；用 pcall 兜底
        if not e then
            return false
        end
        local ok, res = pcall(function()
            return e:HasFocus()
        end)
        return ok and res and true or false
    end

    sync(TotemFineHead.enabled, f.enabled == 1)
    local cfgLock = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
    sync(TotemFineHead.lockFrame, cfgLock and cfgLock.locked and true or false)
    sync(TotemFineHead.selfPoison, f.selfPoison == 1)
    sync(TotemFineHead.selfDisease, f.selfDisease == 1)
    sync(TotemFineHead.cdRevert, (tonumber(f.revertOnCooldown) or 1) == 1)
    sync(TotemFineHead.airSwitch, (tonumber(f.airAutoSwitch) or 0) == 1)
    if TotemFineHead.combatEndSlider then
        local v = tonumber(f.combatEndMode) or 0
        TotemFineHead.combatEndSlider:SetValue(v)
        if TotemFineHead.combatEndText then
            local modes = GoubayuHeal.TotemUI.FineCombatEndModes
            TotemFineHead.combatEndText:SetText((modes and modes[v + 1]) or tostring(v))
        end
    end
    if TotemFineHead.manaSlider then
        local v = tonumber(f.manaSpringPct) or 0
        TotemFineHead.manaSlider:SetValue(v)
        if TotemFineHead.manaPct then
            TotemFineHead.manaPct:SetText(math.floor(v + 0.5) .. "%")
        end
    end

    local count = table.getn(f.rules)
    for i = 1, TOTEM_FINE_MAX_RULES do
        local row = TotemFineRows[i]
        local rule = f.rules[i]
        if row then
            if rule then
                row.refreshing = true
                row:Show()
                if not focused(row.names) then
                    row.names:SetText(tostring(rule.enemies or ""))
                end
                row.elementDD:SetText((GoubayuHeal.Element and GoubayuHeal.Element[rule.element])
                    or rule.element or "")
                row.totemDD:SetText(tostring(rule.totem or ""))
                if not focused(row.range) then
                    row.range:SetText(tostring(tonumber(rule.range) or 0))
                end
                row.refreshing = nil
                sync(row.insight, rule.insight == 1)
                sync(row.enabled, rule.enabled ~= 0)
            else
                row:Hide()
            end
        end
    end

    if TotemFineHead.addBtn then
        if count >= TOTEM_FINE_MAX_RULES then
            TotemFineHead.addBtn:Disable()
            TotemFineHead.addBtn:SetAlpha(0.5)
        else
            TotemFineHead.addBtn:Enable()
            TotemFineHead.addBtn:SetAlpha(1)
        end
    end
end

function GoubayuHeal.Totem_CreateFineWindow()
    if TotemFineWin then
        return TotemFineWin
    end

    local w = CreateFrame("Frame", "GoubayuHealTotemFineFrame", UIParent)
    w:SetWidth(780)
    w:SetHeight(580)
    w:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    w:SetFrameStrata("DIALOG")
    w:EnableMouse(true)
    w:SetMovable(true)
    w:RegisterForDrag("LeftButton")
    w:SetScript("OnDragStart", function() this:StartMoving() end)
    w:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    if GoubayuHeal.UI and GoubayuHeal.UI.ApplyFlatBackdrop then
        GoubayuHeal.UI.ApplyFlatBackdrop(w, 0.03, 0.03, 0.03, 0.96)
    end
    TotemFineWin = w

    local title = Totem_FineFS(w, GoubayuHeal.TotemUI.FineTitle, 12, 1, 0.82, 0.3)
    title:SetPoint("TOPLEFT", w, "TOPLEFT", 14, -10)

    local close = Totem_FineButton(w, 22, 18, "X", function()
        w:Hide()
    end)
    close:SetPoint("TOPRIGHT", w, "TOPRIGHT", -10, -8)

    local tip = Totem_FineFS(w, GoubayuHeal.TotemUI.FineTip, 10, 0.75, 0.75, 0.75)
    tip:SetPoint("TOPLEFT", w, "TOPLEFT", 14, -30)
    tip:SetWidth(750)
    tip:SetJustifyH("LEFT")

    TotemFineHead.enabled = Totem_FineCheck(w,
        GoubayuHeal.TotemUI.FineEnabled, function(checked)
            local f = GoubayuHeal.Totem_FineEnsure()
            if f then
                f.enabled = checked and 1 or 0
            end
        end)
    TotemFineHead.enabled:SetPoint("TOPLEFT", w, "TOPLEFT", 14, -62)

    -- 锁定图腾框架（与"启用精细图腾管理"同一行，右侧）
    -- by 武藤纯子酱 2026.9.21
    TotemFineHead.lockFrame = Totem_FineCheck(w, GoubayuHeal.TotemUI.FineLockFrame,
        function(checked)
            local cfg = GoubayuHeal.Config and GoubayuHeal.Config["shaman_totem"]
            if cfg then
                cfg.locked = checked and true or false
            end
        end)
    TotemFineHead.lockFrame:SetPoint("TOPLEFT", w, "TOPLEFT", 320, -62)
    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(TotemFineHead.lockFrame, GoubayuHeal.TotemUI.FineLockFrame,
            GoubayuHeal.TotemUI.FineLockFrameTip)
    end

    -- 表头
    local hx = { 14, 246, 328, 484 }
    local ht = { GoubayuHeal.TotemUI.FineEnemies, GoubayuHeal.TotemUI.FineElement,
        GoubayuHeal.TotemUI.FineTotemLabel, GoubayuHeal.TotemUI.FineRange }
    for i = 1, table.getn(ht) do
        if ht[i] ~= "" then
            local h = Totem_FineFS(w, ht[i], 9, 0.72, 0.72, 0.72)
            h:SetPoint("TOPLEFT", w, "TOPLEFT", hx[i], -86)
        end
    end

    for i = 1, TOTEM_FINE_MAX_RULES do
        TotemFineRows[i] = Totem_FineCreateRow(w, i)
        TotemFineRows[i]:Hide()
    end

    TotemFineHead.addBtn = Totem_FineButton(w, 90, 20, GoubayuHeal.TotemUI.FineAdd, function()
        local f = GoubayuHeal.Totem_FineEnsure()
        if f and table.getn(f.rules) < TOTEM_FINE_MAX_RULES then
            table.insert(f.rules, {
                enabled = 1, element = "Earth", totem = Totem_FineTotemNames("Earth")[1],
                range = 0, insight = 0, enemies = "",
            })
        end
    end)
    TotemFineHead.addBtn:SetPoint("TOPLEFT", w, "TOPLEFT", 14, -484)

    -- 重置规则：恢复为"宏"里的默认套（战栗/根基两条条件规则 + 自净化开 + 法力之泉20%）
    -- by 武藤纯子酱 2026.9.21
    TotemFineHead.resetBtn = Totem_FineButton(w, 90, 20, GoubayuHeal.TotemUI.FineReset,
        function()
            local f = GoubayuHeal.Totem_FineEnsure()
            if f then
                f.enabled = 1
                f.rules = (GoubayuHeal.Totem_FineDefaultRules
                    and GoubayuHeal.Totem_FineDefaultRules()) or {}
                f.selfPoison = 1
                f.selfDisease = 1
                f.manaSpringPct = 20
                f.combatEndMode = 0
            end
        end)
    TotemFineHead.resetBtn:SetPoint("TOPLEFT", w, "TOPLEFT", 116, -484)
    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(TotemFineHead.resetBtn, GoubayuHeal.TotemUI.FineReset,
            GoubayuHeal.TotemUI.FineResetTip)
    end

    -- CD 中回退默认图腾（默认开）：条件图腾需要重插但自身CD中时，先用方案默认图腾顶上
    -- by 武藤纯子酱 2026.9.21
    TotemFineHead.cdRevert = Totem_FineCheck(w, GoubayuHeal.TotemUI.FineCDRevert,
        function(checked)
            local f = GoubayuHeal.Totem_FineEnsure()
            if f then
                f.revertOnCooldown = checked and 1 or 0
            end
        end)
    TotemFineHead.cdRevert:SetPoint("TOPLEFT", w, "TOPLEFT", 412, -517)
    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(TotemFineHead.cdRevert, GoubayuHeal.TotemUI.FineCDRevert,
            GoubayuHeal.TotemUI.FineCDRevertTip)
    end

    -- 风系图腾自动切换（默认关）：无战士有猎/盗→风怒换优雅；三者都无且非增强→换宁静之风
    -- by 武藤纯子酱 2026.9.21
    TotemFineHead.airSwitch = Totem_FineCheck(w, GoubayuHeal.TotemUI.FineAirSwitch,
        function(checked)
            local f = GoubayuHeal.Totem_FineEnsure()
            if f then
                f.airAutoSwitch = checked and 1 or 0
            end
        end)
    TotemFineHead.airSwitch:SetPoint("TOPLEFT", w, "TOPLEFT", 616, -517)
    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(TotemFineHead.airSwitch, GoubayuHeal.TotemUI.FineAirSwitch,
            GoubayuHeal.TotemUI.FineAirSwitchTip)
    end

    TotemFineHead.selfPoison = Totem_FineCheck(w,
        GoubayuHeal.TotemUI.FineSelfPoison, function(checked)
            local f = GoubayuHeal.Totem_FineEnsure()
            if f then
                f.selfPoison = checked and 1 or 0
            end
        end)
    TotemFineHead.selfPoison:SetPoint("TOPLEFT", w, "TOPLEFT", 14, -516)
    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(TotemFineHead.selfPoison, GoubayuHeal.TotemUI.FineSelfPoison,
            GoubayuHeal.TotemUI.FineSelfPoisonTip)
    end

    TotemFineHead.selfDisease = Totem_FineCheck(w,
        GoubayuHeal.TotemUI.FineSelfDisease, function(checked)
            local f = GoubayuHeal.Totem_FineEnsure()
            if f then
                f.selfDisease = checked and 1 or 0
            end
        end)
    TotemFineHead.selfDisease:SetPoint("TOPLEFT", w, "TOPLEFT", 208, -516)
    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(TotemFineHead.selfDisease, GoubayuHeal.TotemUI.FineSelfDisease,
            GoubayuHeal.TotemUI.FineSelfDiseaseTip)
    end

    -- 战斗结束后行为：一个三档滑块（与法力之泉滑块同一行，长度一致）
    -- 0=只要怪在就保持 / 1=换回默认图腾 / 2=回收图腾
    -- by 武藤纯子酱 2026.9.21
    local ceLabel = Totem_FineFS(w, GoubayuHeal.TotemUI.FineCombatEnd, 10, 1, 1, 1)
    ceLabel:SetPoint("TOPLEFT", w, "TOPLEFT", 350, -550)
    ceLabel:SetWidth(84)

    local ceSlider = CreateFrame("Slider", nil, w)
    ceSlider:SetWidth(160)
    ceSlider:SetHeight(12)
    ceSlider:SetOrientation("HORIZONTAL")
    ceSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    ceSlider:SetPoint("LEFT", ceLabel, "RIGHT", 6, 0)

    local ceThumb = ceSlider:GetThumbTexture()
    if ceThumb then
        ceThumb:SetWidth(12)
        ceThumb:SetHeight(12)
        ceThumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
    end

    -- 背景轨道（此前漏了，导致看不到那条线）
    local ceRail = ceSlider:CreateTexture(nil, "BACKGROUND")
    ceRail:SetTexture("Interface\\Buttons\\WHITE8X8")
    ceRail:SetHeight(4)
    ceRail:SetPoint("LEFT", ceSlider, "LEFT", 0, 0)
    ceRail:SetPoint("RIGHT", ceSlider, "RIGHT", 0, 0)
    ceRail:SetVertexColor(0.25, 0.25, 0.25, 0.8)

    local ceText = Totem_FineFS(w, "", 10, 1, 0.82, 0.3)
    ceText:SetPoint("LEFT", ceSlider, "RIGHT", 6, 0)

    ceSlider:SetMinMaxValues(0, 2)
    ceSlider:SetValueStep(1)
    ceSlider:SetScript("OnValueChanged", function()
        local v = math.floor((this:GetValue() or 0) + 0.5)
        local modes = GoubayuHeal.TotemUI.FineCombatEndModes
        ceText:SetText((modes and modes[v + 1]) or tostring(v))
        local f = GoubayuHeal.Totem_FineEnsure()
        if f then
            f.combatEndMode = v
        end
    end)

    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(ceSlider, GoubayuHeal.TotemUI.FineCombatEnd,
            GoubayuHeal.TotemUI.FineCombatEndTip)
    end

    TotemFineHead.combatEndSlider = ceSlider
    TotemFineHead.combatEndText = ceText

    -- 法力之泉阈值滑块（0 = 从不；低于该蓝量百分比时优先插法力之泉）——与上一行滑块等长并排
    local msLabel = Totem_FineFS(w, GoubayuHeal.TotemUI.FineManaSpring, 10, 1, 1, 1)
    msLabel:SetPoint("TOPLEFT", w, "TOPLEFT", 14, -550)
    msLabel:SetWidth(84)

    local msSlider = CreateFrame("Slider", nil, w)
    msSlider:SetWidth(160)
    msSlider:SetHeight(12)
    msSlider:SetOrientation("HORIZONTAL")
    msSlider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
    msSlider:SetPoint("LEFT", msLabel, "RIGHT", 6, 0)

    local msThumb = msSlider:GetThumbTexture()
    if msThumb then
        msThumb:SetWidth(12)
        msThumb:SetHeight(12)
        msThumb:SetVertexColor(0.90, 0.87, 0.80, 0.9)
    end

    local msRail = msSlider:CreateTexture(nil, "BACKGROUND")
    msRail:SetTexture("Interface\\Buttons\\WHITE8X8")
    msRail:SetHeight(4)
    msRail:SetPoint("LEFT", msSlider, "LEFT", 0, 0)
    msRail:SetPoint("RIGHT", msSlider, "RIGHT", 0, 0)
    msRail:SetVertexColor(0.25, 0.25, 0.25, 0.8)

    local msPct = Totem_FineFS(w, "0%", 10, 1, 1, 1)
    msPct:SetPoint("LEFT", msSlider, "RIGHT", 6, 0)

    msSlider:SetMinMaxValues(0, 100)
    msSlider:SetValueStep(5)
    msSlider:SetScript("OnValueChanged", function()
        local v = math.floor((this:GetValue() or 0) + 0.5)
        msPct:SetText(v .. "%")
        local f = GoubayuHeal.Totem_FineEnsure()
        if f then
            f.manaSpringPct = v
        end
    end)

    TotemFineHead.manaSlider = msSlider
    TotemFineHead.manaPct = msPct

    if GoubayuHeal.UI and GoubayuHeal.UI.SetTooltip then
        GoubayuHeal.UI.SetTooltip(msSlider, GoubayuHeal.TotemUI.FineManaSpring,
            GoubayuHeal.TotemUI.FineManaSpringTip)
    end

    w:Hide()
    return w
end

function GoubayuHeal.Totem_FineToggleWindow()
    local w = GoubayuHeal.Totem_CreateFineWindow()
    if not w then
        return
    end
    if w:IsShown() then
        w:Hide()
    else
        w:Show()
        GoubayuHeal.Totem_FineRefreshWindow()
    end
end
