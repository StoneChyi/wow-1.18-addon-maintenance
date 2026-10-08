-- ====================== 解析模块    ======================
local addon = PTURTLE_Combat

-- ======================== Lua 全局工具本地化 ================================
local tonumber = tonumber
local tostring = tostring
local type = type
local pairs = pairs
local next = next
local math_random = math.random
local math_min = math.min
local math_exp = math.exp
local math_sin = math.sin
local math_cos = math.cos
local math_pi = math.pi
local math_floor = math.floor
local string_gsub = string.gsub
local string_lower = string.lower
local string_sub = string.sub
local strlen = strlen
local table_remove = table.remove
local table_getn = table.getn
local table_insert = table.insert


-- ======================== API 本地化 ================================
local GetTime = GetTime
local GetSpellRecField = GetSpellRecField
local GetUnitName = GetUnitName
local UnitClassification = UnitClassification
local UnitXP = UnitXP  -- UnitXP API 本地化
local UnitExists = UnitExists
local bit_band = bit.band
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local UnitXP = UnitXP
local SendChatMessage = SendChatMessage

-- ======================== 内部引用 ================================
local worldBossGUIDs = addon.worldBossGUIDs
-- 生物临存表初始化（确保在使用前已存在）
if not addon.creatureCache then
    addon.creatureCache = {}
end

-- 召唤物所有者缓存（避免高频字符串拼接和 UnitExists 调用）
local ownerCache = {}
local OWNER_CACHE_MAX = 10  -- 核心优化：缓存上限降至10，简化清理逻辑
local ownerCacheOrder = {}  -- 核心新增：维护插入顺序的数组，实现FIFO淘汰
local ownerCacheIndex = {}  -- - 新增：哈希索引，O(1)查找位置
-- 核心优化：预分配字符串后缀，避免每次拼接
local OWNER_SUFFIX = "owner"

-- AOE 累加器对象池（避免高频表创建）
local aoeItemPool = {}  -- 空闲对象池
local AOE_POOL_MAX = 20  -- 对象池最大容量

-- SpellID 转字符串缓存（避免高频 tostring）
local spellIdToStrCache = {}
local SPELLID_STR_CACHE_MAX = 50  -- 缓存上限
local spellIdStrCacheCount = 0  -- - 新增：计数器，避免 pairs 遍历


-- ======================== 工具函数 ================================
-- 性能优化：公共技能过滤检查函数
local function IsSkillFiltered(spellId)
    if not spellId or spellId == "" then
        return false  -- 空技能ID不过滤（如平砍）
    end
    return addon.skillFilterList and addon.skillFilterList[spellId]
end

-- 核心新增：早期返回辅助函数（减少嵌套深度）
local function EarlyReturnIfFiltered(spellId)
    if IsSkillFiltered(spellId) then
        return true  -- 已过滤，调用方应 return
    end
    return false  -- 未过滤，继续处理
end

-- 根据法术 ID 获取技能名称
local function GetSpellNameAndRankForId(spellId)
    if not spellId then return nil end
    return GetSpellRecField(spellId, "name")
end

-- 核心新增：召唤物缓存管理函数（FIFO淘汰策略）
local function AddToOwnerCache(guid, ownerGUID)
    -- - 优化：如果已存在，使用哈希索引O(1)查找位置
    if ownerCache[guid] then
        local pos = ownerCacheIndex[guid]
        if pos then
            table_remove(ownerCacheOrder, pos)
            ownerCacheIndex[guid] = nil
            
            -- - 更新后续元素的索引
            for i = pos, table_getn(ownerCacheOrder) do
                local key = ownerCacheOrder[i]
                ownerCacheIndex[key] = i
            end
        end
    end
    
    -- 如果缓存已满，删除最旧的条目
    if table_getn(ownerCacheOrder) >= OWNER_CACHE_MAX then
        local oldestKey = table_remove(ownerCacheOrder, 1)  -- 删除数组第一个元素
        ownerCache[oldestKey] = nil  -- 删除哈希表中的对应项
        ownerCacheIndex[oldestKey] = nil  -- - 删除索引
        
        -- - 更新所有元素的索引
        for i = 1, table_getn(ownerCacheOrder) do
            local key = ownerCacheOrder[i]
            ownerCacheIndex[key] = i
        end
    end
    
    -- 添加新条目到末尾
    local newPos = table_getn(ownerCacheOrder) + 1
    table_insert(ownerCacheOrder, guid)
    ownerCache[guid] = ownerGUID
    ownerCacheIndex[guid] = newPos  -- - 记录索引
end

-- AOE 累加器对象池管理（零内存分配）
local function GetAOEItemFromPool()
    -- 从池中获取空闲对象
    local item = table_remove(aoeItemPool)
    if item then
        -- 重置字段
        item.spellId = nil
        item.damage = 0
        item.count = 0
        item.school = 0
        item.queueTime = 0
        item.isHeal = nil
        return item
    end
    
    -- 池为空，创建新对象
    return {
        spellId = nil,
        damage = 0,
        count = 0,
        school = 0,
        queueTime = 0,
        isHeal = nil
    }
end

local function ReturnAOEItemToPool(item)
    -- 如果池未满，回收对象
    if table_getn(aoeItemPool) < AOE_POOL_MAX then
        table_insert(aoeItemPool, item)
    end
end

-- 暴露回收函数给 Display 模块
addon.ReturnAOEItemToPool = ReturnAOEItemToPool

-- SpellID 转字符串缓存（零内存分配）
local function SpellIdToStr(spellId)
    local cached = spellIdToStrCache[spellId]
    if cached then
        return cached
    end
    
    -- 缓存未命中，转换并缓存
    local str = tostring(spellId)
    spellIdToStrCache[spellId] = str
    spellIdStrCacheCount = spellIdStrCacheCount + 1  -- - 计数器+1
    
    -- - 优化：如果缓存过大，清空一半（使用计数器，避免 pairs 遍历）
    if spellIdStrCacheCount > SPELLID_STR_CACHE_MAX then
        -- 清空一半
        local half = math_floor(spellIdStrCacheCount / 2)
        local i = 0
        for k in pairs(spellIdToStrCache) do
            spellIdToStrCache[k] = nil
            i = i + 1
            spellIdStrCacheCount = spellIdStrCacheCount - 1  -- - 计数器-1
            if i >= half then break end
        end
    end
    
    return str
end

-- ======================== 公共检测函数 ================================
-- 检测是否是玩家施放的 AOE 技能
local function IsAOESkillFromPlayer(casterGuid, spellId)
    return casterGuid == addon.GUID_Player 
        and addon.AOESkillsByID 
        and addon.AOESkillsByID[spellId]
end

-- ✅ 新增：获取召唤物的所有者GUID（带缓存）
local function GetSummonerOwnerGUID(guid)
    -- 快速路径：玩家和宠物直接返回nil（不是召唤物）
    if guid == addon.GUID_Player or guid == addon.GUID_Pet then
        return nil
    end
    
    -- 检查开关
    local collectSummonerInfo = PTURTLE_Combat_DB and PTURTLE_Combat_DB.collectSummonerInfo or 0
    if collectSummonerInfo ~= 1 then
        return nil
    end
    
    -- 查询缓存
    local ownerGUID = ownerCache[guid]
    
    -- 缓存未命中，查询并缓存结果
    if ownerGUID == nil then
        local exists, resultGuid = UnitExists(guid .. OWNER_SUFFIX)
        ownerGUID = exists and resultGuid or false  -- false 表示不是召唤物
        
        -- 使用统一的FIFO缓存管理函数
        AddToOwnerCache(guid, ownerGUID)
    end
    
    -- 返回所有者GUID（false表示不是召唤物）
    return ownerGUID ~= false and ownerGUID or nil
end

-- 检测是否是玩家、宠物或玩家的召唤物
local function IsPlayerOrPetOrSummoner(guid)
    -- 检查是否是玩家或宠物
    if guid == addon.GUID_Player or guid == addon.GUID_Pet then
        return true
    end
    
    -- 检查是否是玩家的召唤物
    local ownerGUID = GetSummonerOwnerGUID(guid)
    return ownerGUID == addon.GUID_Player
end

-- 获取正确的GUID（如果是召唤物则返回宠物GUID）
local function GetEffectiveGUID(guid)
    -- 如果是玩家或宠物，直接返回
    if guid == addon.GUID_Player or guid == addon.GUID_Pet then
        return guid
    end
    
    -- 检查是否是玩家的召唤物
    local ownerGUID = GetSummonerOwnerGUID(guid)
    if ownerGUID == addon.GUID_Player then
        return addon.GUID_Pet
    end
    
    return guid
end

PTURTLE_Combat_CharDB = PTURTLE_Combat_CharDB or {}

local combatCache = addon.combatCache
local receivedDataCache = addon.receivedDataCache

-- ======================== 震动参数 ================================
local SHAKE_DURATION = 0.25 -- 晃动时长
local SHAKE_INTENSITY = 0.35 -- 强度
local MAIN_FREQ_SCALE = 12 -- 震动频率（调高=更丝滑）
local DECAY_SPEED = 2.5 -- 衰减速度
local Y_INTENSITY_RATIO = 0.5 -- 上下幅度
local SCALE_FACTOR = 1.2 -- 放大系数

-- 震动状态
local isShaking = false
local startTime = 0
local savedCameraX = 0
local savedCameraY = 0
local lastShakeTime = 0  -- 上次震动时间

function addon:IsShaking()
    return isShaking
end

-- ======================== 启动震动 ================================
function addon:ShakeScreen()
    if not PTURTLE_Combat.hasUnitXP then return end
    
    -- 如果正在震动中，直接返回
    if isShaking then return end
    
    -- 检查震动间隔：如果距离上次震动时间太短，则忽略
    local shakeInterval = (PTURTLE_Combat_DB.shakeCheckInterval or 1000) / 1000  -- 转换为秒
    local currentTime = GetTime()
    if (currentTime - lastShakeTime) < shakeInterval then
        return  -- 间隔未到，不触发震动
    end

    -- 保存原始位置
    savedCameraX = UnitXP("cameraHorizontalDisplacement", "get") or 0
    savedCameraY = UnitXP("cameraHeight", "get") or 0

    isShaking = true
    startTime = currentTime
    lastShakeTime = currentTime  -- 记录本次震动时间
end

-- ======================== 更新震动 ================================
function addon:UpdateShake(currentTime)
    if not PTURTLE_Combat.hasUnitXP then return end

    if not isShaking then
        UnitXP("cameraHorizontalDisplacement", "set", savedCameraX)
        UnitXP("cameraHeight", "set", savedCameraY)
        return
    end

    local elapsed = currentTime - startTime

    -- 复位
    if elapsed > SHAKE_DURATION then
        UnitXP("cameraHorizontalDisplacement", "set", savedCameraX)
        UnitXP("cameraHeight", "set", savedCameraY)
        isShaking = false
        return
    end

    -- 高频正弦震动
    local progress = math_min(elapsed / SHAKE_DURATION, 1)
    local decay = math_exp(-progress * DECAY_SPEED)
    local wave = math_sin(elapsed * MAIN_FREQ_SCALE) * SHAKE_INTENSITY * decay

    -- 左右震动
    local x = wave * SCALE_FACTOR
    -- 上下震动
    local y = math_sin(elapsed * MAIN_FREQ_SCALE + 1.0) * SHAKE_INTENSITY * Y_INTENSITY_RATIO * SCALE_FACTOR

  
    UnitXP("cameraHorizontalDisplacement", "set", savedCameraX + x)
    UnitXP("cameraHeight", "set", savedCameraY + y)
end

-- ====================== 法术伤害解析 ======================
function addon:ParseSpellDamage(a1, a2, a3, a4, a5, a6, a7, a8)
    local playerGUID = addon.GUID_Player

    if a1 == playerGUID then
        -- 性能优化：检查技能过滤，避免不必要的缓存写入和动画调用
        if EarlyReturnIfFiltered(a3) then return end
        
        -- 玩家受到伤害，存储到受到伤害缓存表
        receivedDataCache.GUID_OTHERS = nil   -- 清除 GUID_OTHERS，标记为玩家受到伤害
        receivedDataCache.spellId = a3      -- 法术 ID
        receivedDataCache.amount = a4       -- 伤害量
        receivedDataCache.isCrit = (a6 == 2) and 1 or 0  -- 2=暴击（数字），转换为1；其他为非暴击，转换为0
        receivedDataCache.school = a7       -- 伤害类型
        receivedDataCache.beHeal = 0       -- 不是受到治疗，赋值为 0
        receivedDataCache.DEFENCE = nil     -- 物理防御（SPELL_DAMAGE 不使用）
        receivedDataCache.DEFENCE_T = nil    -- 法术防御（SPELL_DAMAGE 不使用）
        
        addon:ShowReceivedAnimation()
        -- 检查是否暴击并触发屏幕震动（受到技能暴击）
        if a6 == 2 then
            -- 检查 beCritShakeEnabled 开关
            if addon.db and addon.db.beCritShakeEnabled == 0 then
                -- 开关关闭，不震动
            else
                local shakeFunc = addon.ShakeScreen
                if shakeFunc then
                    shakeFunc()
                end
            end
        end
        return
    end
    

    -- 检查是否是玩家、宠物或玩家的召唤物
    if IsPlayerOrPetOrSummoner(a2) then
        if EarlyReturnIfFiltered(a3) then return end
        
        -- AOE 技能检测：如果是玩家施放的 AOE 技能，加入队列
        local isAOE = IsAOESkillFromPlayer(a2, a3)  -- ✅ a2 是施法者GUID
        
        if isAOE then
            
            -- - 优化：确保累加器已初始化（只在首次时创建）
            if not addon.aoeAccumulator then
                addon.aoeAccumulator = {}
            end
            if not addon.aoeAccumulatorKeys then
                addon.aoeAccumulatorKeys = {}
            end
            
            local aoeAccumulator = addon.aoeAccumulator
            local aoeKeys = addon.aoeAccumulatorKeys
            
            -- 查找是否已有同技能的累计项
            if aoeAccumulator[a3] then
                -- 已有同技能项，累加伤害、次数并更新时间
                aoeAccumulator[a3].damage = aoeAccumulator[a3].damage + a4
                aoeAccumulator[a3].count = aoeAccumulator[a3].count + 1  -- 核心修复：移除or 1，避免count=0时被错误处理
                aoeAccumulator[a3].queueTime = GetTime()
                
                -- 更新AOE计数器显示
                if addon.UpdateAOECountOnIndicator then
                    addon:UpdateAOECountOnIndicator(aoeAccumulator[a3].count)
                end
            else
                -- 没有同技能项，从对象池获取或创建新项
                local newItem = GetAOEItemFromPool()
                newItem.spellId = a3
                newItem.damage = a4
                newItem.count = 1
                newItem.school = a7
                newItem.queueTime = GetTime()
                aoeAccumulator[a3] = newItem
                
                -- 添加到数字索引列表（0 GC遍历）
                table.insert(aoeKeys, a3)
                
                -- ：更新AOE计数器显示
                if addon.UpdateAOECountOnIndicator then
                    addon:UpdateAOECountOnIndicator(1)
                end
            end
            
            return  -- AOE技能不立即显示，等待队列处理（混合暴击/非暴击）
        end
        
        -- a8 格式: "X,X,X,Y"，最后一位 Y=3 表示 DOT 伤害
        local isDOT = false
        if a8 and strlen(a8) > 0 then
            local lastChar = string.byte(a8, strlen(a8))
            isDOT = (lastChar == 51)  -- ASCII 51 = '3'
        end
        
        -- 更新战斗数据（字段覆盖，避免创建新表）
        combatCache.GUID_P = GetEffectiveGUID(a2)    --攻击者
        combatCache.GUID = a1       --受害者
        combatCache.SPELLID = a3    --法术 ID
        combatCache.DAMAGE = a4     --伤害
        combatCache.CRIT = (a6 == 2) and 1 or 0  -- 2=暴击（数字），转换为1；其他为非暴击，转换为0
        combatCache.SCHOOL = a7     --法术类型
        combatCache.DEFENCE = nil     --物理防御（SPELL_DAMAGE 不使用）
        combatCache.DEFENCE_T = nil    --法术防御（SPELL_DAMAGE 不使用）
        combatCache.isAOEDamage = nil  -- 明确标记为非AOE伤害
        combatCache.animMode = isDOT and "queue" or nil      -- ✅ 队列模式标记
        
        if a6 == 2 then
            -- 检查 critShakeEnabled 开关
            if addon.db and addon.db.critShakeEnabled == 0 then
                -- 开关关闭，不震动
            else
                local shakeFunc = addon.ShakeScreen
                if shakeFunc then
                    shakeFunc()
                end
            end
        end
        
        -- 触发伤害数字显示
        addon:AutoShowDamage()
    end
    
    -- 检查伤害来源是否是世界 BOSS（已废弃，改用 BigWigs Hook）
end

-- ====================== 受到治疗数据收集 ======================
-- 监听 SPELL_HEAL_ON_SELF
function addon:ParseReceivedHeal(_, _, a3, a4, a5, _, _)
    -- 性能优化：检查技能过滤，避免不必要的缓存写入和动画调用
    if EarlyReturnIfFiltered(a3) then return end
    
    -- 更新受到治疗缓存数据
    receivedDataCache.GUID_OTHERS = nil  -- 清除 GUID_OTHERS，标记为受到治疗
    receivedDataCache.spellId = a3      -- 法术 ID
    receivedDataCache.amount = a4       -- 治疗量
    receivedDataCache.isCrit = (a5 == 1) and 1 or 0  -- 1=暴击（数字），转换为1；其他为非暴击，转换为0
    receivedDataCache.school = 3        -- 自然（浅绿色）
    receivedDataCache.beHeal = 1      -- 是受到治疗，赋值为 1
    receivedDataCache.DEFENCE = nil     -- 物理防御（HEAL 不使用）
    receivedDataCache.DEFENCE_T = nil    -- 法术防御（HEAL 不使用）
    
    addon:ShowReceivedAnimation()
end

-- ====================== 输出治疗数据收集 ======================
-- 监听 SPELL_HEAL_BY_SELF
function addon:ParseOutHeal(targetGuid, casterGuid, spellId, amount, critical)
    -- 在比较时直接读取，确保 GUID 同步
    if targetGuid == addon.GUID_Player then
        return
    end
    
    -- 性能优化：检查技能过滤，避免不必要的缓存写入和动画调用
    if EarlyReturnIfFiltered(spellId) then return end
    
    -- AOE 技能检测：如果是玩家施放的 AOE 治疗技能，加入队列
    if IsAOESkillFromPlayer(casterGuid, spellId) then
        local isCrit = (critical == 1) and 1 or 0
        
        -- 只将非暴击治疗入队累计，暴击治疗走正常流程
        if isCrit == 0 then
            -- - 优化：确保累加器已初始化（只在首次时创建）
            if not addon.aoeAccumulator then
                addon.aoeAccumulator = {}
            end
            
            local aoeAccumulator = addon.aoeAccumulator
            
            -- 查找是否已有同技能的累计项
            if aoeAccumulator[spellId] then
                -- 已有同技能项，累加治疗量、次数并更新时间
                aoeAccumulator[spellId].damage = aoeAccumulator[spellId].damage + amount
                aoeAccumulator[spellId].count = aoeAccumulator[spellId].count + 1  -- 核心修复：移除or 1，避免count=0时被错误处理
                aoeAccumulator[spellId].queueTime = GetTime()
                
                -- 更新AOE计数器显示
                if addon.UpdateAOECountOnIndicator then
                    addon:UpdateAOECountOnIndicator(aoeAccumulator[spellId].count)
                end
            else
                -- 没有同技能项，从对象池获取或创建新项
                local newItem = GetAOEItemFromPool()
                newItem.spellId = spellId
                newItem.damage = amount
                newItem.count = 1
                newItem.school = 3  -- 自然系（浅绿色）
                newItem.queueTime = GetTime()
                newItem.isHeal = true  -- 标记为治疗类型
                aoeAccumulator[spellId] = newItem
                
                -- 更新AOE计数器显示
                if addon.UpdateAOECountOnIndicator then
                    addon:UpdateAOECountOnIndicator(1)
                end
            end
            
            return  -- AOE非暴击治疗不立即显示，等待队列处理
        end
        -- 暴击治疗：不入队，继续走下面的正常流程
    end
    
    -- 更新输出治疗缓存数据（治疗目标是其他人）
    receivedDataCache.GUID_OTHERS = 1  -- 标记为输出治疗
    receivedDataCache.spellId = spellId      -- 法术 ID
    receivedDataCache.amount = amount       -- 治疗量
    receivedDataCache.isCrit = (critical == 1) and 1 or 0  -- 1=暴击（数字），转换为1；其他为非暴击，转换为0
    receivedDataCache.school = 3        -- 自然（浅绿色）
    receivedDataCache.beHeal = nil      -- 输出治疗不需要 beHeal
    receivedDataCache.DEFENCE = nil     -- 物理防御（OUTPUT_HEAL 不使用）
    receivedDataCache.DEFENCE_T = nil    -- 法术防御（OUTPUT_HEAL 不使用）
    receivedDataCache.targetGUID = targetGuid  -- ✅ 新增：保存目标 GUID，用于 UnitXP 获取屏幕坐标
    
    addon:ShowReceivedAnimation()
end

-- ====================== 能量回复解析 ======================
function addon:ParseEnergize(spellId, powerType, amount)
    -- powerType: 0=法力, 1=怒气, 3=能量

    local school
    if powerType == 0 then  -- 法力
        school = 6  -- 奥术（天蓝色）
    elseif powerType == 1 then  -- 怒气
        school = 2  -- 火焰（深红色）
    elseif powerType == 3 then  -- 能量
        school = 7  -- 技能物理（深黄色）
    else
        return  -- 不是目标能量类型，直接返回
    end
    
    -- 更新受治疗缓存数据（用于在受治疗框体中显示）
    receivedDataCache.GUID_OTHERS = nil  -- 不是输出治疗
    receivedDataCache.spellId = spellId      -- 法术 ID
    receivedDataCache.amount = amount       -- 回复量
    receivedDataCache.isCrit = 0            -- 能量回复不暴击
    receivedDataCache.beHeal = 1            -- 标记为受治疗类型（在受治疗框体显示）
    receivedDataCache.school = school       -- 根据能量类型设置颜色
    receivedDataCache.DEFENCE = nil         -- 不使用防御字段
    receivedDataCache.DEFENCE_T = nil       -- 不使用防御字段
    
    addon:ShowReceivedAnimation()
end

-- ====================== 环境伤害解析 ======================
function addon:ParseEnvironmentalDamage(dmgType, damage)
    -- dmgType: 0=疲劳, 1=溺水, 2=跌落, 3=熔岩, 4=淤泥, 5=火焰, 6=虚空跌落
    -- 只关心 dmgType 和 damage，显示在受伤框架中，使用深红色
    
    -- 更新受伤害缓存数据（用于在受伤框体中显示）
    receivedDataCache.GUID_OTHERS = nil  -- 不是输出治疗
    receivedDataCache.spellId = nil       -- 环境伤害没有法术 ID
    receivedDataCache.amount = damage    -- 伤害量
    receivedDataCache.isCrit = 0         -- 环境伤害不暴击
    receivedDataCache.beHeal = 0         -- 标记为受到伤害（在受伤框体显示）
    receivedDataCache.school = 2         -- 火焰（深红色）
    receivedDataCache.DEFENCE = nil      -- 不使用防御字段
    receivedDataCache.DEFENCE_T = nil    -- 不使用防御字段
    
    addon:ShowReceivedAnimation()
end

-- ====================== 反伤盾伤害解析 ======================
function addon:ParseDamageShield(shieldOwnerGuid, targetGuid, damage, spellSchool)
    -- shieldOwnerGuid: 拥有者GUID
    -- targetGuid: 受害者GUID
    -- damage: 反伤量
    -- spellSchool:  (0=物理, 1=神圣, 2=火焰, 3=自然, 4=冰霜, 5=暗影, 6=奥术)
    
    if targetGuid == addon.GUID_Player then
        -- 玩家受到反伤，显示在受伤框架
        receivedDataCache.GUID_OTHERS = nil  -- 不是输出治疗
        receivedDataCache.spellId = nil      -- 反伤盾没有法术 ID，不显示图标
        receivedDataCache.amount = damage    -- 伤害量
        receivedDataCache.isCrit = 0         -- 反伤盾不暴击
        receivedDataCache.beHeal = 0         -- 标记为受到伤害（在受伤框体显示）
        receivedDataCache.school = spellSchool or 0
        receivedDataCache.DEFENCE = nil      -- 不使用防御字段
        receivedDataCache.DEFENCE_T = nil    -- 不使用防御字段
        
        addon:ShowReceivedAnimation()
    elseif shieldOwnerGuid == addon.GUID_Player then
        -- 对敌人造成的反伤，显示在输出框架
        combatCache.GUID_P = shieldOwnerGuid   -- 施法者（玩家）
        combatCache.GUID = targetGuid          -- 受害者（敌人）
        combatCache.SPELLID = nil              -- 反伤盾没有法术 ID
        combatCache.DAMAGE = damage            -- 伤害量
        combatCache.CRIT = 0                   -- 反伤盾不暴击
        combatCache.SCHOOL = spellSchool or 0  -- 法术学校
        combatCache.DEFENCE = nil              -- 不使用防御字段
        combatCache.DEFENCE_T = nil            -- 不使用防御字段
        combatCache.isAOEDamage = nil          -- 反伤盾不是 AOE
        combatCache.animMode = nil                -- 反伤盾不是队列模式
        
        addon:AutoShowDamage()
    end
end


-- ======================== HitInfo 解码器===============================
local function ParseHitInfo(hitInfo)
    -- 位运算判断各命中类型（只判断暴击/碾压）
    local isCritical = bit_band(hitInfo, 128) ~= 0   -- 0x80 暴击
    local isCrushing = bit_band(hitInfo, 32768) ~= 0 -- 0x8000 碾压
    
    -- 按优先级返回值
    if isCritical or isCrushing then
        return 2  -- 暴击/碾压返回 2
    else
        return 0  -- 普通命中返回 0
    end
end

-- ====================== 平砍解析 ======================
function addon:ParseAutoAttack(a1, a2, a3, a4, a5, _, _, _)
    local hitType = ParseHitInfo(a4)

    -- 如果 a2 是玩家，存储到受到伤害缓存表
    if a2 == addon.GUID_Player then
        -- 玩家受到伤害，存储到受到伤害缓存表
        receivedDataCache.GUID_OTHERS = nil   -- 清除 GUID_OTHERS，标记为玩家受到伤害
        receivedDataCache.spellId = ""        -- 平砍没有法术 ID
        receivedDataCache.amount = a3          -- 伤害量
        receivedDataCache.isCrit = (hitType == 2) and 1 or 0  -- 2=暴击，转换为1；其他为非暴击，转换为0
        receivedDataCache.school = 0           -- 物理（纯白）
        receivedDataCache.beHeal = 0          -- 不是受到治疗，赋值为 0
        receivedDataCache.DEFENCE = nil     -- 物理防御（AUTO_ATTACK 不使用 DEFENCE）
        receivedDataCache.DEFENCE_T = a5  -- 0=未命中 2/6=闪避，3=招架，5=格挡 7=免疫  8=反射
        
        addon:ShowReceivedAnimation()
        -- 检查是否暴击并触发屏幕震动（受到平砍暴击）
        if hitType == 2 then
            -- 检查 beCritShakeEnabled 开关
            if addon.db and addon.db.beCritShakeEnabled == 0 then
                -- 开关关闭，不震动
            else
                local shakeFunc = addon.ShakeScreen
                if shakeFunc then
                    shakeFunc()
                end
            end
        end
        return
    end

    -- 检查是否是玩家、宠物或玩家的召唤物
    if IsPlayerOrPetOrSummoner(a1) then
            
        -- 更新战斗数据（字段覆盖，避免创建新表）
        combatCache.GUID_P = GetEffectiveGUID(a1)
        combatCache.GUID = a2
        combatCache.SPELLID = ""
        combatCache.DAMAGE = a3
        combatCache.CRIT = (hitType == 2) and 1 or 0  -- 2=暴击/碾压，转换为1；其他为非暴击，转换为0
        combatCache.SCHOOL = 0
        combatCache.DEFENCE = nil  --物理防御（AUTO_ATTACK 不使用 DEFENCE）
        combatCache.DEFENCE_T = a5  --0=未命中 2/6=闪避，3=招架，5=格挡 7=免疫  8=反射  
        combatCache.isAOEDamage = nil  -- 平砍不是 AOE
        combatCache.animMode = nil        -- 平砍不是队列模式
    --[[VICTIMSTATE_UNAFFECTED = 0   -- 目标未受到影响（未命中/MISS）
        VICTIMSTATE_NORMAL = 1       -- 正常命中（造成伤害/治疗）
        VICTIMSTATE_DODGE = 2        -- 闪避
        VICTIMSTATE_PARRY = 3        -- 招架
        VICTIMSTATE_INTERRUPT = 4    -- 打断
        VICTIMSTATE_BLOCKS = 5       -- 格挡
        VICTIMSTATE_EVADES = 6       -- 躲避（怪物消失/脱离战斗）
        VICTIMSTATE_IS_IMMUNE = 7    -- 免疫
        VICTIMSTATE_DEFLECTS = 8     -- 偏转/反弹]]
        
        if hitType == 2 then
            -- 检查 critShakeEnabled 开关
            if addon.db and addon.db.critShakeEnabled == 0 then
                -- 开关关闭，不震动
            else
                local shakeFunc = addon.ShakeScreen
                if shakeFunc then
                    shakeFunc()
                end
            end
        end
        
        addon:AutoShowDamage()
    end
end

-- ====================== 法术未命中解析 ======================
--[[参数
string casterGuid — 施法者 GUID
string targetGuid — 目标 GUID
int spellId — 法术 ID
int missInfo — 未命中类型]]
function addon:ParseSpellMiss(a1, a2, a3, a4)
    -- 如果 a1（施法者）是玩家，检查是否需要喊话
    if a1 == addon.GUID_Player and a3 == 19801 then  -- 宁神射击 ID: 19801
        -- 不是单人状态就喊话（团队或小队）
        if addon.groupType ~= "solo" then
            -- 随机选择一句话
            local rand = math.random(1, 2)
            local msg
            if rand == 1 then
                msg = "|cFF00FF00[PlayTurtle]|r |cFFFF0000<宁神射击>|r|cFF0080FF打歪了|r，沙子迷了我的眼！"
            else
                msg = "|cFF00FF00[PlayTurtle]|r |cFFFF0000<宁神射击>|r|cFF0080FF被招架了|r，今天真的点背！"
            end
            
            -- 根据队伍类型选择频道
            local channel = addon.groupType == "raid" and "RAID" or "PARTY"
            SendChatMessage(msg, channel)
        end
    end

    -- 如果 a2（目标）是玩家，存储到受伤表
    if a2 == addon.GUID_Player then
        
        receivedDataCache.GUID_OTHERS = nil   -- 清除标记，标记为玩家受到伤害
        receivedDataCache.spellId = a3      -- 法术 ID
        receivedDataCache.amount = nil       -- 未命中/闪避等没有伤害量
        receivedDataCache.isCrit = 0         -- 未命中不是暴击
        receivedDataCache.school = 0         -- 伤害类型
        receivedDataCache.beHeal = 0         -- 不是受到治疗
        receivedDataCache.DEFENCE = a4       -- SPELL_MISS_*: 1=未命中 2=抵抗 3/6=闪避 4=招架 5=格挡 7/8=免疫 10=吸收 11=反射
        receivedDataCache.DEFENCE_T = nil    -- SPELL_MISSED 不使用 DEFENCE_T
        
        addon:ShowReceivedAnimation()
        return
    end
    
    -- 如果 a1（施法者）是玩家、宠物或召唤物，更新战斗数据
    if IsPlayerOrPetOrSummoner(a1) then
        -- 性能优化：检查技能过滤，避免不必要的缓存写入和动画调用
        if EarlyReturnIfFiltered(a3) then return end
        
        -- ✅ 检查是否是 DOT 技能的防御状态
        local isDOTSkill = addon:IsDOTSkillInCache(a3)
        
        -- ✅ 检查是否是 AOE 技能
        local isAOESkill = IsAOESkillFromPlayer(a1, a3)
        
        -- 更新战斗数据（字段覆盖，避免创建新表）
        combatCache.GUID_P = GetEffectiveGUID(a1)   --施法者
        combatCache.GUID = a2   --目标
        combatCache.SPELLID = a3   --技能 ID
        combatCache.DAMAGE = 0  -- 未命中/抵抗等没有伤害量，使用数字 0
        combatCache.CRIT = 0  -- 非暴击
        combatCache.SCHOOL = 0  -- 法术类型默认为 0
        combatCache.DEFENCE = a4   --missinfo   1=未命中 2=抵抗 3/6=躲闪 4=招架  5=格挡  7/8=免疫   10=吸收  11=反射
        combatCache.DEFENCE_T = nil  -- SPELL_MISSED 不使用 DEFENCE_T
        combatCache.isAOEDamage = isAOESkill  -- ✅ AOE 技能标记
        combatCache.animMode = (isDOTSkill or isAOESkill) and "queue" or nil  -- ✅ DOT 或 AOE 技能都标记为队列模式
    --[[SPELL_MISS_NONE    = 0   -- 无未命中（正常命中，不会出现）
        SPELL_MISS_MISS    = 1   -- 未命中
        SPELL_MISS_RESIST  = 2   -- 抵抗（部分/完全抵抗）
        SPELL_MISS_DODGE   = 3   -- 闪避
        SPELL_MISS_PARRY   = 4   -- 招架
        SPELL_MISS_BLOCK   = 5   -- 格挡
        SPELL_MISS_EVADE   = 6   -- 躲避（目标无法被攻击）
        SPELL_MISS_IMMUNE  = 7   -- 免疫
        SPELL_MISS_IMMUNE2 = 8   -- 免疫（第二种类型）
        SPELL_MISS_DEFLECT = 9   -- 偏转
        SPELL_MISS_ABSORB  = 10  -- 吸收
        SPELL_MISS_REFLECT = 11  -- 反射]]
        
        -- 调用显示函数
        addon:AutoShowDamage()
    end
end

-- ====================== BUFF/DEBUFF_ADDED_SELF 获得解析 ======================
function addon:ParseBuffAdded(_, _, a3, _)  --a1=GUID    a3=SPELLID
    -- 检查是否在监控列表中（使用个人数据库）
    if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.monitoredBuffs then
        local buffData = PTURTLE_Combat_CharDB.monitoredBuffs[SpellIdToStr(a3)]
        if buffData then
            -- 如果喊话不为 nil，则执行喊话
            if buffData.shout then
                -- 处理喊话内容中的占位符
                local shoutContent = buffData.shout
                
                -- 替换 # 为技能名称（带颜色）
                local skillName = GetSpellNameAndRankForId(a3)
                if skillName then
                    shoutContent = string_gsub(shoutContent, "#", "|cff00ff00" .. skillName .. "|r")
                else
                    -- 如果获取不到技能名，移除#
                    shoutContent = string_gsub(shoutContent, "#", "")
                end
                            
                -- 拼接完整喊话内容
                local fullShout = "|cff00bfff[PlayTurtle]|r " .. shoutContent .. ""
                
                -- 根据队伍状态选择频道
                if addon.groupType == "raid" then
                    SendChatMessage(fullShout, "RAID")
                elseif addon.groupType == "party" then
                    SendChatMessage(fullShout, "PARTY")
                end
            end
            
            -- 如果音乐不为 nil，则播放音乐
            if buffData.music then
                if PlaySoundFile then
                    local path = "Interface\\AddOns\\PlayTurtle\\Sound\\" .. buffData.music
                    pcall(PlaySoundFile, path, "Master")
                end
            end
        end
    end
end

-- ====================== SPELL_GO_SELF 解析 ======================
function addon:ParseSpellGo(_, a2, _, a4)---a2=SPELLID    a4=TARGETGUID
    -- 检查是否在监控列表中（使用个人数据库）
    if PTURTLE_Combat_CharDB and PTURTLE_Combat_CharDB.monitoredSpells then
        local spellData = PTURTLE_Combat_CharDB.monitoredSpells[SpellIdToStr(a2)]
        if spellData then
            -- 如果喊话不为 nil，则执行喊话
            if spellData.shout then
                -- 获取目标怪物名称
                local targetName = UnitName(a4)
                
                -- 处理喊话内容中的占位符
                local shoutContent = spellData.shout
                
                -- 替换 @ 为目标名称（带颜色）
                if targetName and targetName ~= "" then
                    shoutContent = string_gsub(shoutContent, "@", "|cffff8000<" .. targetName .. ">|r")
                end
                            
                -- 替换 # 为技能名称（带颜色）
                local skillName = GetSpellNameAndRankForId(a2)
                if skillName then
                    shoutContent = string_gsub(shoutContent, "#", "|cff00ff00" .. skillName .. "|r")
                else
                    -- 如果获取不到技能名，移除#
                    shoutContent = string_gsub(shoutContent, "#", "")
                end
                            
                -- 拼接完整喊话内容（插件名在最前面，其他内容保持原色）
                local fullShout = "|cff00bfff[PlayTurtle]|r " .. shoutContent .. ""
                
                -- 根据队伍状态选择频道
                if addon.groupType == "raid" then
                    SendChatMessage(fullShout, "RAID")
                elseif addon.groupType == "party" then
                    SendChatMessage(fullShout, "PARTY")
                end
            end
            
            -- 如果音乐不为 nil，则播放音乐
            if spellData.music then
                if PlaySoundFile then
                    local path = "Interface\\AddOns\\PlayTurtle\\Sound\\" .. spellData.music
                    pcall(PlaySoundFile, path, "Master")
                end
            end
        end
    end
end

-- ====================== 战斗状态管理（新增） ======================
-- 脱离战斗处理
function addon:OnPlayerRegenEnabled()
    -- 脱离战斗
    addon.playerInCombat = false
    
    -- 核心修复：脱战后，如果框体仍然可见，重新启动预览模式
    if addon.ReceivedUI then
        local damageVisible = addon.ReceivedUI.labelDamage and addon.ReceivedUI.labelDamage:IsShown()
        local healVisible = addon.ReceivedUI.labelHeal and addon.ReceivedUI.labelHeal:IsShown()
        local outHealVisible = addon.ReceivedUI.labelOutHeal and addon.ReceivedUI.labelOutHeal:IsShown()
        
        if damageVisible or healVisible or outHealVisible then
            -- 至少有一个框体可见，启动预览模式
            if not addon.receivedPanelPreviewMode then
                addon.receivedPanelPreviewMode = true
                -- 核心修复：只在累加器为nil时才初始化，避免重置已累积的时间
                if not addon.GlobalTimer.receivedPreviewAccumulator or type(addon.GlobalTimer.receivedPreviewAccumulator) ~= "number" then
                    addon.GlobalTimer.receivedPreviewAccumulator = 0
                end
            end
        end
    end
    
    -- 直接检查当前 BOSS GUID 对应的 BOSS 是否还在战斗中（已废弃，改用 BigWigs Hook）
end

-- 进入战斗处理
function addon:OnPlayerRegenDisabled()
    -- 进入战斗（说明玩家还活着）
    addon.playerInCombat = true
    addon.playerDeadOrNot = nil  -- 重置为存活状态
    
    -- 清空生物临存表
    addon.creatureCache = {}
    
    -- 核心新增：进入战斗时预初始化槽位，避免首次伤害丢失
    if addon.AutoShowDamage and not addon._aniPoolInitialized then
        -- 触发一次懒加载，确保槽位已创建
        local oldCache = addon.combatCache
        addon.combatCache = { DAMAGE = nil }  -- 临时数据，不会真正显示
        addon:AutoShowDamage()
        addon.combatCache = oldCache  -- 恢复原数据
        addon._aniPoolInitialized = true
    end
    if addon.ShowReceivedAnimation and not addon._receivedPoolInitialized then
        -- 触发受伤/治疗槽位初始化
        local oldCache = addon.receivedDataCache
        addon.receivedDataCache = { amount = nil }
        addon:ShowReceivedAnimation()
        addon.receivedDataCache = oldCache
        addon._receivedPoolInitialized = true
    end
    
    -- 进入战斗时立即停止预览模式
    if addon.textPanelPreviewMode then
        addon:StopPreviewMode()
    end
    if addon.receivedPanelPreviewMode then
        addon.receivedPanelPreviewMode = false
        addon.GlobalTimer.receivedPreviewAccumulator = nil
    end
    -- 核心新增：进入战斗时停止 DOT 预览模式
    if addon.dotPanelPreviewMode then
        addon.dotPanelPreviewMode = false
        addon.GlobalTimer.dotPreviewAccumulator = nil
    end
    
    -- 核心新增：进入战斗时清理 AOE 累加器和队列，避免旧数据污染新战斗
    if addon.aoeAccumulator then
        -- 回收所有 AOE item 到对象池
        for spellId, item in pairs(addon.aoeAccumulator) do
            if addon.ReturnAOEItemToPool then
                addon.ReturnAOEItemToPool(item)
            end
        end
        wipe(addon.aoeAccumulator)
    end
    
    -- 清理队列待处理队列（回收槽位）
    if addon.ClearQueuePendingList then
        addon:ClearQueuePendingList()
    end
    
    -- 核心新增：清理受伤/受疗/输出治疗待处理队列（回收槽位）
    if addon.ClearReceivedPendingLists then
        addon:ClearReceivedPendingLists()
    end
    
    -- 进入战斗时关闭所有UI界面
    if addon.panel and addon.panel:IsVisible() then
        addon.panel:Hide()
        if PTURTLE_Combat_DB then
            PTURTLE_Combat_DB.panelVisible = false
        end
    end
    if addon.subPanel and addon.subPanel:IsVisible() then
        addon.subPanel:Hide()
    end
    
    -- 隐藏固定位置指示器
    if addon.db.fixedPosEnabled and addon.fixedPosIndicator then
        addon.fixedPosIndicator:Hide()
    end
    -- 核心新增：AOE计数器设置为透明而不是隐藏，并禁用鼠标
    if addon.aoeCounterFrame then
        addon.aoeCounterFrame:SetAlpha(0)
        addon.aoeCounterFrame:EnableMouse(false)  -- 核心修改：Slash命令关闭面板时禁用鼠标
    end
    
    -- 关闭受伤/受治疗/输出治疗编辑框架
    if addon.DamageFrame then
        addon.DamageFrame:StopMovingOrSizing()  -- 核心修复：停止拖动状态
        addon.DamageFrame:SetBackdrop(nil)
        addon.DamageFrame:EnableMouse(false)
    end
    if addon.ReceivedHealFrame then
        addon.ReceivedHealFrame:StopMovingOrSizing()  -- 核心修复：停止拖动状态
        addon.ReceivedHealFrame:SetBackdrop(nil)
        addon.ReceivedHealFrame:EnableMouse(false)
    end
    if addon.OutputHealFrame then
        addon.OutputHealFrame:StopMovingOrSizing()  -- 核心修复：停止拖动状态
        addon.OutputHealFrame:SetBackdrop(nil)
        addon.OutputHealFrame:EnableMouse(false)
    end
    -- 核心新增：进入战斗时隐藏 DOT 框架
    if addon.DOTFrame then
        addon.DOTFrame:StopMovingOrSizing()  -- 核心修复：停止拖动状态
        addon.DOTFrame:SetBackdrop(nil)
        addon.DOTFrame:EnableMouse(false)
    end
    if addon.ReceivedUI then
        -- 核心修复：停止所有手柄的拖动/调整大小状态
        if addon.ReceivedUI.handleDamage then
            addon.ReceivedUI.handleDamage.isDragging = false  -- 清除拖动标志
            addon.ReceivedUI.handleDamage:Hide()
        end
        if addon.ReceivedUI.handleHeal then
            addon.ReceivedUI.handleHeal.isDragging = false  -- 清除拖动标志
            addon.ReceivedUI.handleHeal:Hide()
        end
        if addon.ReceivedUI.handleOutHeal then
            addon.ReceivedUI.handleOutHeal.isDragging = false  -- 清除拖动标志
            addon.ReceivedUI.handleOutHeal:Hide()
        end
        if addon.ReceivedUI.handleDOT then
            addon.ReceivedUI.handleDOT.isDragging = false  -- 清除拖动标志
            addon.ReceivedUI.handleDOT:Hide()
        end
        
        if addon.ReceivedUI.labelDamage then addon.ReceivedUI.labelDamage:Hide() end
        if addon.ReceivedUI.startPointDamage then addon.ReceivedUI.startPointDamage:Hide() end
        if addon.ReceivedUI.endPointDamage then addon.ReceivedUI.endPointDamage:Hide() end
        if addon.ReceivedUI.resizeDamage then addon.ReceivedUI.resizeDamage:Hide() end
        if addon.ReceivedUI.handleDamage then addon.ReceivedUI.handleDamage:Hide() end
        
        if addon.ReceivedUI.labelHeal then addon.ReceivedUI.labelHeal:Hide() end
        if addon.ReceivedUI.startPointHeal then addon.ReceivedUI.startPointHeal:Hide() end
        if addon.ReceivedUI.endPointHeal then addon.ReceivedUI.endPointHeal:Hide() end
        if addon.ReceivedUI.resizeHeal then addon.ReceivedUI.resizeHeal:Hide() end
        if addon.ReceivedUI.handleHeal then addon.ReceivedUI.handleHeal:Hide() end
        
        if addon.ReceivedUI.labelOutHeal then addon.ReceivedUI.labelOutHeal:Hide() end
        if addon.ReceivedUI.startPointOutHeal then addon.ReceivedUI.startPointOutHeal:Hide() end
        if addon.ReceivedUI.endPointOutHeal then addon.ReceivedUI.endPointOutHeal:Hide() end
        if addon.ReceivedUI.resizeOutHeal then addon.ReceivedUI.resizeOutHeal:Hide() end
        if addon.ReceivedUI.handleOutHeal then addon.ReceivedUI.handleOutHeal:Hide() end
        -- 核心新增：隐藏 DOT 框架 UI 元素
        if addon.ReceivedUI.labelDOT then addon.ReceivedUI.labelDOT:Hide() end
        if addon.ReceivedUI.startPointDOT then addon.ReceivedUI.startPointDOT:Hide() end
        if addon.ReceivedUI.endPointDOT then addon.ReceivedUI.endPointDOT:Hide() end
        if addon.ReceivedUI.resizeDOT then addon.ReceivedUI.resizeDOT:Hide() end
        if addon.ReceivedUI.handleDOT then addon.ReceivedUI.handleDOT:Hide() end
    end
end

-- 单位死亡处理
function addon:OnUnitDead(diedGUID)
    -- 冻结该单位的伤害数字，避免最后一击数字因姓名板回收而跳到屏幕左侧
    if addon.FreezeSlotsOnPlate then
        addon:FreezeSlotsOnPlate(diedGUID)
    end

    -- 世界 BOSS 死亡处理（已废弃，改用 BigWigs Hook）
    -- if worldBossGUIDs[diedGUID] then
    --     -- 标记有 BOSS 死亡
    --     addon.bossIsDead = true
    --         
    --     -- 是世界 BOSS 死亡，播放音乐
    --     if addon.Config and addon.Config.BOSS_MUSIC_ENABLED == 1 then
    --         if PlaySoundFile then
    --             local musicPath = "Interface\\AddOns\\PlayTurtle\\Sound\\Music\\MS_1.mp3"
    --             pcall(PlaySoundFile, musicPath)
    --         end
    --     end
    --     
    --     -- 记录最后击杀的 BOSS 名称
    --     addon.lastBossName = GetUnitName(diedGUID) or "未知 BOSS"
    --     
    --     -- 只删除死亡的单个 BOSS（支持多 BOSS 同时存在）
    --     worldBossGUIDs[diedGUID] = nil
    --     
    --     -- 如果死亡的是当前缓存的 BOSS，清空缓存
    --     if addon.currentBossGUID == diedGUID then
    --         addon.currentBossGUID = nil
    --     end
    --     
    --     -- 如果缓存被清空且还有其他 BOSS，立即提取一个新的并验证
    --     if not addon.currentBossGUID and next(worldBossGUIDs) then
    --         -- 从表中提取第一个 GUID
    --         local newBossGUID = next(worldBossGUIDs)
    --         
    --         -- 立即验证是否在战斗中（返回 1=在战斗，nil=不在）
    --         if UnitAffectingCombat(newBossGUID) == 1 then
    --             -- 在战斗中，使用这个 GUID
    --             addon.currentBossGUID = newBossGUID
    --         else
    --             --  不在战斗中或不存在，从表中删除
    --             worldBossGUIDs[newBossGUID] = nil
    --         end
    --     end
    -- end
    
    -- 再检查是否是玩家死亡
    if diedGUID == addon.GUID_Player then
        -- 玩家死亡
        addon.playerDeadOrNot = 1
        
        -- 如果 BOSS 还没死，发送战死密语（已废弃，改用 BigWigs Hook）
        -- if not addon.bossIsDead then
        --     addon:HandlePlayerDeathWhisper()
        -- end
    end
end

