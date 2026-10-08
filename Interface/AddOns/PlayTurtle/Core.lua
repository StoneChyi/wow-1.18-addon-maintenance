PTURTLE_Combat = {}
local addon = PTURTLE_Combat
addon.version = "2.0"

-- ======================== Lua 全局工具本地化（性能优化）===============================
local GetTime = GetTime
local CreateFrame = CreateFrame
local type = type
local tonumber = tonumber
local wipe = wipe
local string_lower = string.lower
local pairs = pairs
local GetUnitName = GetUnitName
local print = print
local string_format = string.format
local math_floor = math.floor
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local string_sub = string.sub

-- ======================== 存档保护机制（防止被pfUI等插件覆盖）===============================
-- 在PLAYER_LOGIN事件中确保存档已加载
local function ProtectSavedVariables()
    -- 确保PTURTLE_Combat_DB存在
    if not PTURTLE_Combat_DB then
        PTURTLE_Combat_DB = {}
    end
    
    -- 确保PTURTLE_Combat_CharDB存在
    if not PTURTLE_Combat_CharDB then
        PTURTLE_Combat_CharDB = {}
    end
    
    -- 验证存档结构
    if type(PTURTLE_Combat_DB) ~= "table" then
        PTURTLE_Combat_DB = {}
    end
    
    if PTURTLE_Combat_CharDB and type(PTURTLE_Combat_CharDB) ~= "table" then
        PTURTLE_Combat_CharDB = {}
    end
end

-- 注册PLAYER_LOGIN事件来保护存档
local protectFrame = CreateFrame("Frame")
protectFrame:RegisterEvent("PLAYER_LOGIN")
protectFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        ProtectSavedVariables()
        
        -- 核心新增：在 PLAYER_LOGIN 后加载个人存档中的技能表
        -- 加载技能过滤表
        if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.skillFilterList then
            addon.skillFilterList = PTURTLE_Combat_CharDB.skillFilterList
        else
            addon.skillFilterList = {}
        end
        
        -- 加载AOE技能表
        if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.AOESkillsByID then
            addon.AOESkillsByID = PTURTLE_Combat_CharDB.AOESkillsByID
        else
            addon.AOESkillsByID = {}
        end
        
        -- 核心新增：统一同步配置（确保存档加载完成后立即同步）
        if addon.SyncConfigFromDB then
            addon:SyncConfigFromDB()
        end
        
        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)

-- ======================== 全局变量与状态==================================
addon.GUID_Player = ""
addon.GUID_Pet = ""
addon.NAME_Player = ""

-- 玩家自身战斗状态  进入战斗时更新   离开战斗时更新
addon.playerInCombat = false  -- true=战斗中，false=非战斗

-- 玩家死亡状态  开始回复时更新   死亡时更新
addon.playerDeadOrNot = nil  -- 1=死亡/灵魂，nil=存活

-- 自动应答密语表   收到密语时添加，玩家脱离战斗时答复并删除整个表
addon.whisperReplyTable = addon.whisperReplyTable or {}  -- 存储已回复的玩家名

-- BigWigs 当前激活的 BOSS 名称（用于自动应答）
addon.currentBigWigsBossName = nil  -- nil=无BOSS，字符串=BOSS中文名

-- BigWigs BOSS 战状态（true=BOSS战中，nil=非BOSS战）
addon.inBigWigsBossFight = nil  -- true=正在打BOSS，nil=未打BOSS

-- ======================== 文字设置面板预览模式 ================================
addon.textPanelPreviewMode = false  -- 文字设置面板预览模式状态
addon.receivedPanelPreviewMode = false  -- 受伤/受治疗/输出治疗预览模式状态

-- ======================== 全局定时器（挂载到 addon 命名空间）===============================
addon.GlobalTimer = addon.GlobalTimer or {
    previewAccumulator = 0,
    receivedPreviewAccumulator = 0
}

-- ======================== 战斗数据缓存表 ================================
-- 用于存储战斗事件解析后的数据
addon.combatCache = {
    GUID_P = "",
    GUID = "",
    SPELLID = "",
    DAMAGE = 0,         -- 数字类型
    CRIT = 0,           -- 数字类型 (0=非暴击, 2=暴击)
    SCHOOL = 0,         -- 数字类型
    DEFENCE = nil,      -- 数字类型或 nil
    DEFENCE_T = nil,    -- 数字类型或 nil
    isDOT = false       -- 是否为DOT伤害（从a8最后一位判断）
}

-- ======================== 受到伤害和受到治疗数据收集表 ================================
-- 用于监听玩家受到伤害、受到治疗、输出治疗事件
addon.receivedDataCache = {
    GUID_OTHERS = nil,  -- 其他目标标记（1=玩家对他人的输出治疗，nil=玩家受到治疗/伤害）
    spellId = nil,      -- 法术 ID
    amount = nil,       -- 伤害/治疗量（数字类型）
    school = nil,       -- 伤害类型 参照映射表（3=自然）
    isCrit = nil,       -- 是否暴击（1=暴击，0=非暴击）
    beHeal = nil,       -- 是否是受到治疗（1=受到治疗，0=受到伤害）
    DEFENCE = nil,      -- 物理防御状态（数字类型）
    DEFENCE_T = nil     -- 法术防御/命中状态（数字类型）
}

-- ======================== DOT伤害数据收集表 ================================
-- 用于显示持续性伤害(DOT)的数字动画
addon.dotDataCache = {
    GUID = "",          -- 受害者 GUID
    spellId = nil,      -- 法术 ID
    amount = nil,       -- 伤害量（数字类型）
    school = nil,       -- 伤害类型
    isCrit = 0,         -- 是否暴击（1=暴击，0=非暴击）
    isDOT = true        -- 标记为 DOT 伤害
}

-- ======================== DOT 伤害显示（复用 ReceivedAnimationPool）===============================
-- 不再需要单独的 DOTBatchQueue 和 DOTSlotPool

-- ======================== 技能过滤列表===============================
-- 核心新增：初始化为空表，在 PLAYER_LOGIN 事件中从存档加载
addon.skillFilterList = {}

-- ======================== 法术监控列表===============================
addon.spellsDB = {}

-- ======================== BUFF监控列表===============================
addon.buffsDB = {}

-- ======================== AOE 技能 ID 列表（使用技能 ID 而非名称）===============================
-- 核心新增：初始化为空表，在 PLAYER_LOGIN 事件中从存档加载
addon.AOESkillsByID = {}

-- ======================== AOE 累计系统 ================================
addon.aoeAccumulator = {}  -- AOE 伤害累加器（按spellId索引）
addon.aoeAccumulatorKeys = {}  -- AOE累加器的数字索引列表（0 GC遍历）
addon.aoeAccumulatorCount = 0  -- AOE累加器中的项目数量
addon.AOE_QUEUE_DELAY = 0.3  -- AOE 延迟释放时间（秒）

-- ======================== DOT 技能 ID 缓存 ================================
-- 用于在 SPELL_MISS 事件中识别 DOT 技能的防御状态
addon.dotSkillCache = {}      -- spellId -> true（哈希表，O(1)查找）
addon.dotSkillOrder = {}      -- 维护插入顺序的数组（FIFO淘汰）
addon.DOT_CACHE_MAX = 15      -- 缓存上限

-- 添加 DOT 技能 ID 到缓存
function addon:AddDOTSkillToCache(spellId)
    if not spellId or spellId == "" then return end
    
    -- 如果已存在，直接返回
    if self.dotSkillCache[spellId] then
        return
    end
    
    -- 如果缓存已满，删除最旧的条目
    if table.getn(self.dotSkillOrder) >= self.DOT_CACHE_MAX then
        local oldestSpellId = table.remove(self.dotSkillOrder, 1)  -- 删除数组第一个元素
        self.dotSkillCache[oldestSpellId] = nil  -- 删除哈希表中的对应项
    end
    
    -- 添加新条目到末尾
    table.insert(self.dotSkillOrder, spellId)
    self.dotSkillCache[spellId] = true
end

-- 检查技能 ID 是否在 DOT 缓存中
function addon:IsDOTSkillInCache(spellId)
    return self.dotSkillCache[spellId] == true
end

-- 清空 DOT 缓存（进入战斗时调用）
function addon:ClearDOTSkillCache()
    wipe(self.dotSkillCache)
    wipe(self.dotSkillOrder)
end

-- 队伍状态初始化标志
addon.groupTypeInitialized = false

-- 获取单位血量百分比函数
function addon:GetUnitPercent(guid)
    if not guid then
        return nil, nil, nil
    end
    
    local data = GetUnitData(guid)
    
    -- 安全检查
    if data and data.maxHealth and data.maxHealth > 0 then
        local hpPercent = (data.health / data.maxHealth) * 100
        return hpPercent, data.health, data.maxHealth
    end
    
    -- 无法获取血量
    return nil, nil, nil
end

-- ======================== 统一配置管理 ================================
-- 用户可调节配置
addon.Config = addon.Config or {
    UserSettings = {
        critScaleStart = 10.0,       -- 一阶缩放默认 100（滑块值）* 0.3 = 30 倍最大放大
        critScaleEnd = 4.0,          -- 二阶缩放默认 40（滑块值）* 0.3 = 12 倍最终大小
        BOSS_MUSIC_ENABLED = 1,     -- BOSS 奏乐功能开关（默认开启）
        
        -- 伤害数字显示相关配置
        normalFadeDuration = 1.5,   -- 淡出时长默认 1.5 秒
        normalMoveRandom = 60,     -- 浮动速度默认 60（像素/秒）
        animALifetime = 1.2,        -- 动画A存活时间默认 1.2 秒
        normalRandomX = 80,        -- X 分布默认 80
        normalRandomY = 50,         -- Y 分布默认 50
        anchorXOffset = 0,          -- 锚点 X 偏移改为 0（水平居中）
        baseFontSize = 42,          -- 字符大小默认 42
        charSpacing = -10,           -- 字符间距默认 -10
        digitTextureStyle = 1,      -- 数字样式默认 1
        critDistributionRangeX = 120, -- X 轴分布范围默认 120（±120px）
        critDistributionRangeY = 140,  -- Y 轴分布范围默认 140（向上 0-140px）
    },
    
    -- 系统内部参数（不建议修改）
    SystemParams = {
        MAX_ANI_SLOTS = 50,         -- 最大伤害动画槽位数量（默认回头是岸模式）
        MAX_RECEIVED_SLOTS = 30,    -- 最大受伤/受治疗/输出治疗动画槽位数量（共用，默认回头是岸模式）
        CRIT_SCALE_UP_TIME = 0.15,  -- 暴击放大时间
        CRIT_SCALE_DOWN_TIME = 0.12,-- 暴击缩放时间
        NORMAL_MOVE_SPEED = 40,     -- 普通数字移动速度
        NORMAL_FADE_START = 0.5,    -- 普通数字淡出开始时间
        MAX_DIGITS = 5,             -- 最大数字位数
        FIXED_PARENT_FRAME = "UIParent",
        
        -- 抛物线动画参数（独立动画类型，所有模式均可使用）
        PARABOLA_DURATION = 1.5,    -- 抛物线动画持续时间
    }
}

-- 初始化姓名板扫描相关
addon.lastNameplateScan = addon.lastNameplateScan or (GetTime() - 1.0) 
addon.NAMEPLATE_SCAN_INTERVAL = 0.1  
addon.scanTimerFrame = nil  -- 姓名板扫描定时器 Frame  

-- ======================== 统一配置同步函数 ================================
function addon:SyncConfigFromDB()
    if not PTURTLE_Combat_DB or not addon.Config or not addon.Config.UserSettings then
        -- 核心修复：确保 Config 和 UserSettings 存在
        if not addon.Config then
            addon.Config = {}
        end
        if not addon.Config.UserSettings then
            addon.Config.UserSettings = {}
        end
        if not addon.Config.SystemParams then
            addon.Config.SystemParams = {}
        end
        return
    end
    
    local db = PTURTLE_Combat_DB
    local userSettings = addon.Config.UserSettings
    local systemParams = addon.Config.SystemParams
    
    -- 辅助函数：安全获取数字类型配置
    local function safeNumber(value, default)
        if type(value) == "number" then
            return value
        elseif type(value) == "string" then
            return tonumber(value) or default
        else
            return default
        end
    end
    
    -- ========== 右侧滑块配置 ==========
    userSettings.normalFadeDuration = safeNumber(db.rightSlider1Value, 20) / 10  -- 淡出速度
    userSettings.normalMoveRandom = safeNumber(db.rightSlider2Value, 60)       -- 浮动速度
    
    userSettings.baseFontSize = safeNumber(db.rightSlider3Value, 50)            -- 字符大小
    
    userSettings.normalRandomX = safeNumber(db.rightSlider4Value, 80)          -- X 分布
    userSettings.normalRandomY = safeNumber(db.rightSlider5Value, 50)           -- Y 分布
    userSettings.animASpacing = safeNumber(db.rightSlider6Value, 10)               -- 行距（动画A）
    userSettings.animALifetime = safeNumber(db.rightSlider7Value, 12) / 10      -- 存活时间（动画A）
    userSettings.charSpacing = safeNumber(db.rightSlider8Value, -8)             -- 字符间距
    userSettings.digitTextureStyle = safeNumber(db.rightSlider9Value, 1)        -- 字体样式
    userSettings.petQueueXOffset = safeNumber(db.petQueueXOffset, 0)            -- 宠物队列X偏移
    
    -- ========== 左侧滑块配置（暴击相关）==========
    userSettings.critScaleStart = safeNumber(db.leftSlider1Value, 120) / 10     -- 一阶缩放
    userSettings.critScaleEnd = safeNumber(db.leftSlider2Value, 50) / 10        -- 二阶缩放
    userSettings.critHoldTime = safeNumber(db.leftSlider3Value, 3) / 10         -- 停留时间
    userSettings.critAnchorX = safeNumber(db.leftSlider4Value, 0)               -- 锚点X偏移
    userSettings.critAnchorY = safeNumber(db.leftSlider5Value, 0)               -- 锚点Y偏移
    userSettings.critRandomX = safeNumber(db.leftSlider6Value, 100)               -- X轴偏移（暴击随机）
    userSettings.critShakeIntensity = safeNumber(db.critShakeIntensityValue, 10) / 10    -- 暴击抖动强度（滑块值/10）
    userSettings.critShakeFrequency = safeNumber(db.leftSlider7Value, 10)       -- 暴击抖动频率
    userSettings.critNumberShakeEnabled = safeNumber(db.critNumberShakeEnabled, 0) -- 暴击数字抖动开关（独立于屏幕震动）
    userSettings.queueCritShakeEnabled = safeNumber(db.queueCritShakeEnabled, 0) -- 队列暴击震动开关
    
    -- 同步到 addon.db（用于Parser和UI按钮）
    if addon.db then
        addon.db.critShakeEnabled = safeNumber(db.critShakeEnabled, 0)          -- 屏幕震动开关
        addon.db.damageAnimEnabled = safeNumber(db.damageAnimEnabled, 0)        -- 受伤动画开关（默认关闭）
        addon.db.dotQueueEnabled = safeNumber(db.dotQueueEnabled, 0)            -- 队列模式开关（开启后所有伤害进入队列框架排队显示）
    end
    
    -- ========== 系统参数 ==========
    systemParams.MAX_ANI_SLOTS = safeNumber(db.maxAniSlots, 50)  -- 默认 50（回头是岸模式）
    systemParams.MAX_RECEIVED_SLOTS = safeNumber(db.maxReceivedSlots, 30)  -- 默认 30（回头是岸模式）
    
    -- ========== 其他配置 ==========
    userSettings.BOSS_MUSIC_ENABLED = safeNumber(db.BOSS_MUSIC_ENABLED, 1)      -- BOSS 奏乐开关
    
    -- 非暴击动画模式
    if addon.db then
        addon.db.normalAnimMode = db.normalAnimMode or "A"
    end
    
    -- 补充遗漏的配置项（确保完整同步，所有开关都使用 safeNumber 确保数字类型）
    db.hideIconForNonCrit = safeNumber(db.hideIconForNonCrit, 1)                -- 非暴击隐藏图标
    db.autoAttackIconEnabled = safeNumber(db.autoAttackIconEnabled, 1)          -- 普攻图标开关
    db.fixedPosEnabled = safeNumber(db.fixedPosEnabled, 0)                      -- 玩家固定位置开关
    db.showSpellIcon = safeNumber(db.showSpellIcon, 1)                          -- 显示技能图标
    db.damageThreshold = safeNumber(db.damageThreshold, 0)                      -- 伤害阈值（核心修复：允许0值，使用 safeNumber 确保数字类型）
    db.CRIT_SHAKE_ENABLED = safeNumber(db.CRIT_SHAKE_ENABLED, 0)                -- 造成暴击震动（默认关闭）
    db.beCritShakeEnabled = safeNumber(db.beCritShakeEnabled, 1)                -- 受暴击震动（默认开启）
    db.receivedHealEnabled = safeNumber(db.receivedHealEnabled, 0)              -- 受到治疗显示
    db.receivedDamageEnabled = safeNumber(db.receivedDamageEnabled, 0)          -- 受到伤害显示
    db.outHealEnabled = safeNumber(db.outHealEnabled, 0)                        -- 输出治疗显示
    db.collectSummonerInfo = safeNumber(db.collectSummonerInfo, 0)              -- 召唤物信息收集
    
    -- 核心修复：配置同步后，清除 DOT 控制点缓存，确保动画路径正确
    if addon.ClearDOTControlPointCache then
        addon:ClearDOTControlPointCache()
    end
end

-- ====================== 核心工具函数 =====================================
function addon:Print(msg)
    print("[PlayTurtle] " .. msg)
end

function addon:Debug(msg)
    self:Print("[调试] " .. msg)
end

--==================== 玩家/宠物信息初始化=====================================
function addon:InitPlayerAndPetInfo()
    local exists, currentGUID = UnitExists("player")
    if not exists then currentGUID = "" end
    currentGUID = currentGUID or ""
    local currentName = GetUnitName("player") or ""
     
    if currentGUID then
        addon.GUID_Player = currentGUID
        addon.NAME_Player = currentName
    end
    
    -- 宠物信息
    local exists, petGUID = UnitExists("pet")
    if not exists then petGUID = "" end
    petGUID = petGUID or ""
    if petGUID ~= "" then
        addon.GUID_Pet = petGUID
    end
end

-- 更新宠物 GUID
function addon:UpdatePetGUID()
    local exists, newPetGUID = UnitExists("pet")
    if not exists then newPetGUID = "" end
    newPetGUID = newPetGUID or ""
    if newPetGUID ~= "" and newPetGUID ~= addon.GUID_Pet then
        addon.GUID_Pet = newPetGUID
    end
end

-- ===================初始化队伍状态检测======
function addon:InitGroupType()
    -- 优先级判断：团队 > 小队 > 单人
    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()
    
    if raidCount > 0 then
        addon.groupType = "raid"
    elseif partyCount > 0 then
        addon.groupType = "party"
    else
        addon.groupType = "solo"
    end
end

-- ===================初始化关闭暴雪伤害显示和必要的 nampower 设置开启======
function addon:InitBlizzardDamageSetting()
   
    SetCVar("CombatDamage", 0)
    SetCVar("NP_EnableSpellGoEvents", 1)
    SetCVar("NP_EnableAutoAttackEvents", 1)
    SetCVar("NP_EnableSpellHealEvents", 1)
    SetCVar("NP_EnableSpellEnergizeEvents", 1)
    --SHOW_COMBAT_TEXT = "0"
end

-- ===================初始化 UnitXP 依赖检测======
-- 检测 UnitXP API 是否存在及版本
local hasUnitXP = false
local hasUnitXPX = false  -- UnitXP_X (魔改版)

-- 首先检测基础 UnitXP API
local r1, r2 = pcall(UnitXP, "nop", "nop")
if r1 == true and r2 == true then
    hasUnitXP = true
    
    -- 进一步检测是否为 UnitXP_X (检查 version API)
    local v1, v2 = pcall(UnitXP, "version")
    if v1 == true and v2 and type(v2) == "string" and v2 ~= "" then
        hasUnitXPX = true
    end
end

addon.hasUnitXP = hasUnitXP
addon.hasUnitXPX = hasUnitXPX

--================================= 注册命令=========================================
SLASH_PLAYTURTLE1 = "/pt"
SLASH_PLAYTURTLE2 = "/playturtle"
SlashCmdList["PLAYTURTLE"] = function(msg)
    local lowerMsg = string_lower(msg or "")
    if lowerMsg == "choice" or lowerMsg == "mode" then
        -- 显示性能模式选择对话框
        if addon.CreateModeChoiceDialog then
            addon:CreateModeChoiceDialog()
        else
            addon:Print("模式选择功能未加载！")
        end
    elseif lowerMsg == "shake" then
        if addon.ShakeScreen then
            addon:ShakeScreen()
            addon:Print("触发屏幕震动测试")
        else
            addon:Print("震动功能未加载！")
        end
    elseif lowerMsg == "testboss" then
        addon:Print("开始播放 BOSS 击败音乐测试...")
        
        local musicPath = "Interface\\AddOns\\PlayTurtle\\Sound\\Music\\MS_1.mp3"
        if PlaySoundFile then
            pcall(PlaySoundFile, musicPath)
            addon:Print(" 正在播放 BOSS 死亡音乐：MS_1.mp3")
            addon:Print(" 如果听不到声音，请检查：")
            addon:Print(" 1. 游戏音效设置是否开启")
            addon:Print(" 2. 主音量是否足够")
            addon:Print(" 3. 音乐文件是否存在：Interface\\AddOns\\PlayTurtle\\Sound\\Music\\MS_1.mp3")
        end
    elseif lowerMsg == "status" then
        print("\n=== PlayTurtle 状态 ===")
        print("玩家 GUID: '" .. (addon.GUID_Player or "nil") .. "'")
        print("玩家 NAME: '" .. (addon.NAME_Player or "nil") .. "'")
        print("宠物 GUID: '" .. (addon.GUID_Pet or "nil") .. "'")
        print("队伍状态：" .. (addon.groupType == "raid" and "团队" or addon.groupType == "party" and "小队" or addon.groupType == "solo" and "单人" or "未知"))
        
        -- 核心新增：显示受伤/受疗/输出治疗容器状态
        if addon.ReceivedAnimationPool then
            local maxSlots = addon.SystemParams and addon.SystemParams.MAX_RECEIVED_SLOTS or 30
            local damageCount = table.getn(addon.activeDamageSlots or {})
            local healCount = table.getn(addon.activeHealSlots or {})
            local outHealCount = table.getn(addon.activeOutHealSlots or {})
            local totalActive = damageCount + healCount + outHealCount
            local usageRate = totalActive / maxSlots
            
            print("\n=== 受伤/受疗/输出治疗容器 ===")
            print(string_format("最大槽位: %d", maxSlots))
            print(string_format("受伤活跃: %d | 受疗活跃: %d | 输出治疗活跃: %d", damageCount, healCount, outHealCount))
            print(string_format("总活跃数: %d (%.1f%%)", totalActive, usageRate * 100))
        end
        
        -- 核心新增：显示输出伤害容器状态
        if addon.AnimationPool then
            local activeDamageCount = table.getn(addon.activeSlots or {})
            local maxDamageSlots = addon.SystemParams and addon.SystemParams.MAX_ANI_SLOTS or 50
            local damageUsageRate = activeDamageCount / maxDamageSlots
            
            print("\n=== 输出伤害容器 ===")
            print(string_format("最大槽位: %d", maxDamageSlots))
            print(string_format("活跃数: %d (%.1f%%)", activeDamageCount, damageUsageRate * 100))
        end
        
        print("====================")
    elseif lowerMsg == "frames" then
        -- - 输出3个框架的当前位置和大小信息
        if addon.ReceivedUI then
            DEFAULT_CHAT_FRAME:AddMessage("\n========== [PlayTurtle] 框架当前信息 ==========", 1, 1, 0)
            
            -- 受伤框架
            if addon.DamageFrame then
                local x, y = addon.DamageFrame:GetCenter()
                local w, h = addon.DamageFrame:GetWidth(), addon.DamageFrame:GetHeight()
                local centerX, centerY = UIParent:GetCenter()
                local relX = math_floor(x - centerX)
                local relY = math_floor(y - centerY)
                
                DEFAULT_CHAT_FRAME:AddMessage("受伤框架 (Damage):", 1, 0.8, 0.2)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  位置: X=%d, Y=%d (相对屏幕中心)", relX, relY), 0.8, 0.8, 0.8)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  大小: 宽=%d, 高=%d", w, h), 0.8, 0.8, 0.8)
                
                if addon.ReceivedUI.handleDamage then
                    local hx = addon.ReceivedUI.handleDamage:GetLeft() - addon.DamageFrame:GetLeft()
                    local hy = -(addon.DamageFrame:GetTop() - addon.ReceivedUI.handleDamage:GetTop())
                    DEFAULT_CHAT_FRAME:AddMessage(string_format("  蓝色手柄: X=%d, Y=%d (相对框架左上角)", math_floor(hx), math_floor(hy)), 0.8, 0.8, 0.8)
                end
            end
            
            -- 受治疗框架
            if addon.ReceivedHealFrame then
                local x, y = addon.ReceivedHealFrame:GetCenter()
                local w, h = addon.ReceivedHealFrame:GetWidth(), addon.ReceivedHealFrame:GetHeight()
                local centerX, centerY = UIParent:GetCenter()
                local relX = math_floor(x - centerX)
                local relY = math_floor(y - centerY)
                
                DEFAULT_CHAT_FRAME:AddMessage("\n受治疗框架 (Heal):", 0.2, 1, 0.2)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  位置: X=%d, Y=%d (相对屏幕中心)", relX, relY), 0.8, 0.8, 0.8)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  大小: 宽=%d, 高=%d", w, h), 0.8, 0.8, 0.8)
                
                if addon.ReceivedUI.handleHeal then
                    local hx = addon.ReceivedUI.handleHeal:GetLeft() - addon.ReceivedHealFrame:GetLeft()
                    local hy = -(addon.ReceivedHealFrame:GetTop() - addon.ReceivedUI.handleHeal:GetTop())
                    DEFAULT_CHAT_FRAME:AddMessage(string_format("  蓝色手柄: X=%d, Y=%d (相对框架左上角)", math_floor(hx), math_floor(hy)), 0.8, 0.8, 0.8)
                end
            end
            
            -- 输出治疗框架
            if addon.OutputHealFrame then
                local x, y = addon.OutputHealFrame:GetCenter()
                local w, h = addon.OutputHealFrame:GetWidth(), addon.OutputHealFrame:GetHeight()
                local centerX, centerY = UIParent:GetCenter()
                local relX = math_floor(x - centerX)
                local relY = math_floor(y - centerY)
                
                DEFAULT_CHAT_FRAME:AddMessage("\n输出治疗框架 (OutHeal):", 0.2, 0.6, 1)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  位置: X=%d, Y=%d (相对屏幕中心)", relX, relY), 0.8, 0.8, 0.8)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  大小: 宽=%d, 高=%d", w, h), 0.8, 0.8, 0.8)
                
                if addon.ReceivedUI.handleOutHeal then
                    local hx = addon.ReceivedUI.handleOutHeal:GetLeft() - addon.OutputHealFrame:GetLeft()
                    local hy = -(addon.OutputHealFrame:GetTop() - addon.ReceivedUI.handleOutHeal:GetTop())
                    DEFAULT_CHAT_FRAME:AddMessage(string_format("  蓝色手柄: X=%d, Y=%d (相对框架左上角)", math_floor(hx), math_floor(hy)), 0.8, 0.8, 0.8)
                end
            end
            
            -- 队列框架
            if addon.DOTFrame then
                local x, y = addon.DOTFrame:GetCenter()
                local w, h = addon.DOTFrame:GetWidth(), addon.DOTFrame:GetHeight()
                local centerX, centerY = UIParent:GetCenter()
                local relX = math_floor(x - centerX)
                local relY = math_floor(y - centerY)
                
                DEFAULT_CHAT_FRAME:AddMessage("\n队列框架 (DOT):", 0.8, 0.2, 0.8)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  位置: X=%d, Y=%d (相对屏幕中心)", relX, relY), 0.8, 0.8, 0.8)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  大小: 宽=%d, 高=%d", w, h), 0.8, 0.8, 0.8)
                
                if addon.ReceivedUI.handleDOT then
                    local hx = addon.ReceivedUI.handleDOT:GetLeft() - addon.DOTFrame:GetLeft()
                    local hy = -(addon.DOTFrame:GetTop() - addon.ReceivedUI.handleDOT:GetTop())
                    DEFAULT_CHAT_FRAME:AddMessage(string_format("  蓝色手柄: X=%d, Y=%d (相对框架左上角)", math_floor(hx), math_floor(hy)), 0.8, 0.8, 0.8)
                end
            end
            
            DEFAULT_CHAT_FRAME:AddMessage("================================================\n", 1, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 框架尚未初始化", 1, 0, 0)
        end
    elseif lowerMsg == "aoe" then
        -- 查看 AOE 技能列表和队列状态
        print("\n=== AOE 技能配置与队列状态 ===")
        
        -- 显示已配置的 AOE 技能
        print("【已配置的 AOE 技能】")
        local aoeCount = 0
        for spellId, _ in pairs(addon.AOESkillsByID) do
            local spellName = GetSpellRecField(spellId, "name") or "未知技能"
            print(string.format("  ID: %d - %s", spellId, spellName))
            aoeCount = aoeCount + 1
        end
        if aoeCount == 0 then
            print("  (未配置任何 AOE 技能)")
        else
            print(string.format("  总计：%d 个技能", aoeCount))
        end
        
        print("----------------------------")
        
        -- 显示当前 AOE 累加器状态
        print("【AOE 累加器状态】")
        local accumulator = addon.aoeAccumulator or {}
        local count = 0
        for _ in pairs(accumulator) do
            count = count + 1
        end
        print(string.format("  技能数量：%d", count))
        
        if count > 0 then
            print("  累加内容：")
            local index = 0
            for spellId, item in pairs(accumulator) do
                index = index + 1
                local spellName = GetSpellRecField(item.spellId, "name") or "未知技能"
                print(string.format("    [%d] SpellID: %d (%s), 累计伤害: %d",
                    index, item.spellId, spellName, item.damage))
            end
        else
            print("  (累加器为空)")
        end
        
        print("====================\n")
    elseif lowerMsg == "frame" then
        -- 查看所有框架位置信息
        print("\n【框架位置信息】")
        
        -- 队列框架
        if addon.DOTFrame then
            local x, y = addon.DOTFrame:GetCenter()
            local width = addon.DOTFrame:GetWidth() or 0
            local height = addon.DOTFrame:GetHeight() or 0
            if x and y then
                print(string.format("  队列框架：中心(%.1f, %.1f) | 尺寸(%dx%d)", x, y, width, height))
            else
                print("  队列框架：未显示")
            end
        else
            print("  队列框架：未初始化")
        end
        
        -- 固定位置指示器
        if addon.fixedPosIndicator then
            local x, y = addon.fixedPosIndicator:GetCenter()
            if x and y then
                print(string.format("  固定位置指示器：中心(%.1f, %.1f)", x, y))
            else
                print("  固定位置指示器：未显示")
            end
        else
            print("  固定位置指示器：未初始化")
        end
        
        print("====================\n")
    else
        -- 获取当前模式信息
        local damageSlots = PTURTLE_Combat_DB and PTURTLE_Combat_DB.maxAniSlots or 50
        local receivedSlots = PTURTLE_Combat_DB and PTURTLE_Combat_DB.maxReceivedSlots or 30
        local currentMode = (damageSlots >= 100) and "一意孤行" or "回头是岸"
        
        -- 统计实际创建的槽位数量
        local createdDamageCount = 0
        if addon.aniData then
            -- 核心优化：aniData是固定大小数组，使用数字索引遍历
            local maxSlots = PTURTLE_Combat_DB and PTURTLE_Combat_DB.maxAniSlots or 50
            for i = 1, maxSlots do
                if addon.aniData[i] then
                    createdDamageCount = createdDamageCount + 1
                end
            end
        end
        
        local createdReceivedCount = 0
        if addon.ReceivedAnimationPool then
            -- 核心优化：ReceivedAnimationPool是固定大小数组，使用数字索引遍历
            local maxSlots = PTURTLE_Combat_DB and PTURTLE_Combat_DB.maxReceivedSlots or 30
            for i = 1, maxSlots do
                if addon.ReceivedAnimationPool[i] then
                    createdReceivedCount = createdReceivedCount + 1
                end
            end
        end
        
        print("\n==== PlayTurtle 帮助 ========")
        print(string.format("当前模式：「%s」", currentMode))
        print(string.format("伤害动画：配置 %d 槽位 | 已创建 %d 槽位", damageSlots, createdDamageCount))
        print(string.format("受伤/治疗：配置 %d 槽位 | 已创建 %d 槽位", receivedSlots, createdReceivedCount))
        print("/pt status - 查看当前状态（GUID/队伍信息）")
        print("/pt shake - 测试屏幕震动功能")
        print("/pt testboss - 测试 BOSS 击败音乐播放")
        print("/pt npshow - 查看映射表")
        print("/pt aoe - 查看 AOE 技能配置与队列状态")
        print("/pt choice - 性能模式选择（回头是岸/一意孤行）")
        print("====================\n")
        
        -- 核心新增：同时弹出控制面板
        if addon.CreatePanel then
            addon:CreatePanel()
            if addon.panel then
                addon.panel:Show()
                addon.db.panelVisible = true
                PTURTLE_Combat_DB.panelVisible = true
            end
        end
    end
end
