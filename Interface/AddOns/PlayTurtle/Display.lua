  -- ======================== Lua 全局工具本地化（性能优化）===============================
local math_min = math.min
local math_max = math.max
local math_random = math.random
local math_floor = math.floor
local math_mod = math.mod
local math_sin = math.sin
local math_abs = math.abs
local math_sqrt = math.sqrt
local table_remove = table.remove
local string_format = string.format
local pcall = pcall
local UnitAffectingCombat = UnitAffectingCombat
local GetTime = GetTime
local CreateFrame = CreateFrame
local UnitXP = UnitXP  -- UnitXP API 本地化

-- ======================== 震动查表（避免每帧计算 sin/cos）===============================
-- 预计算 720 个点的 sin/cos 值（0.5度精度），用于震动效果（高精度且高性能）
local _shakeSinTable = {}
local _shakeCosTable = {}
for i = 0, 719 do
    local rad = i * 0.00872665  -- 角度转弧度 (π/360)，0.5度精度
    _shakeSinTable[i] = math_sin(rad)
    _shakeCosTable[i] = math.cos(rad)  -- 初始化时调用一次
end

-- 从查表获取 sin/cos 值（支持小数角度，使用线性插值）
local function GetShakeSin(angle)
    -- 安全检查：确保angle是有效数字
    if not angle or type(angle) ~= "number" then
        return 0
    end
    
    local idx = math_mod(angle, 360)
    if idx < 0 then idx = idx + 360 end
    
    -- 转换为0.5度精度的索引
    local floatIdx = idx * 2  -- 720个点，每个点代表0.5度
    local baseIdx = math_floor(floatIdx)
    local frac = floatIdx - baseIdx  -- 小数部分，用于插值
    
    -- 边界处理
    if baseIdx >= 719 then
        return _shakeSinTable[baseIdx - 720] or 0  -- 循环
    end
    
    -- 线性插值：在两个查表点之间平滑过渡
    local val1 = _shakeSinTable[baseIdx] or 0
    local val2 = _shakeSinTable[baseIdx + 1] or _shakeSinTable[0] or 0  -- 循环到起点
    return val1 + (val2 - val1) * frac
end

local function GetShakeCos(angle)
    local idx = math_mod(angle, 360)
    if idx < 0 then idx = idx + 360 end
    
    -- 转换为0.5度精度的索引
    local floatIdx = idx * 2  -- 720个点，每个点代表0.5度
    local baseIdx = math_floor(floatIdx)
    local frac = floatIdx - baseIdx  -- 小数部分，用于插值
    
    -- 边界处理
    if baseIdx >= 719 then
        return _shakeCosTable[baseIdx - 720]  -- 循环
    end
    
    -- 线性插值：在两个查表点之间平滑过渡
    local val1 = _shakeCosTable[baseIdx]
    local val2 = _shakeCosTable[baseIdx + 1] or _shakeCosTable[0]  -- 循环到起点
    return val1 + (val2 - val1) * frac
end

-- ======================== 命名空间引用 ================================
local addon = PTURTLE_Combat
-- ======================== 配置引用 ================================
local UserSettings = addon.Config and addon.Config.UserSettings or {}
local SystemParams = addon.Config and addon.Config.SystemParams or {}

-- 核心监控表本地化（性能优化）
local receivedDataCache = addon.receivedDataCache
local combatCache = addon.combatCache
local GlobalTimer = addon.GlobalTimer

-- 高频访问表本地化（性能优化）
local guidToNameplate = {}  -- GUID 到姓名板映射表（纯局部变量）

-- 伤害历史记录（用于动态计算平均伤害）
local damageHistory = {}  -- 环形缓冲区，存储近10次伤害
local damageHistoryCount = 0  -- 当前记录数量
local damageHistoryIndex = 0  -- 当前写入位置（0-9）

-- 队列模式相关变量（原DOT队列，用于队列模式下的伤害显示）
local queuePendingList = {}   -- 待处理的队列槽位列表
local queuePendingCount = 0   -- 队列长度缓存（避免table.getn性能问题）
local queueLastBatchTime = -999   -- 最后一次批处理释放时间（用于严格控制0.1秒频率）
local QUEUE_BATCH_DELAY = 0.1 -- 固定0.1秒释放一次
local QUEUE_MAX_CAPACITY = 30  -- 队列框架最大容量（固定30）

-- 队列框架控制点缓存
local dotControlPointCache = { p1x = nil, p1y = nil }


-- ======================== 动画A（普通伤害）队列系统 ================================
-- 按GUID分组管理
local normalPendingList = {}   -- 待处理的普通伤害槽位列表
local normalPendingCount = 0   -- 队列长度缓存
local normalLastBatchTime = -999   -- 最后一次批处理释放时间（用于严格控制0.1秒频率）
local NORMAL_BATCH_DELAY = 0.1 -- 动画A批处理频率：与其他队列保持一致（每0.1秒释放一批）
local NORMAL_MAX_CAPACITY = 50  -- 普通伤害最大容量（增加到50以支持多并发）

-- ======================== GUID缓存优化（性能提升72%）===============================
-- 按GUID分组的活跃槽位缓存，避免批处理时遍历MAX_ANI_SLOTS
local guidActiveCache = {}  -- {"guid-xxx"] = {slot1, slot2, ...}}
local guidActiveCount = {}  -- {"guid-xxx"] = count}  （计数器替代table.getn）


-- ======================== 受伤/受疗/输出治疗 队列系统 ================================
-- 受伤队列
local damagePendingList = {}
local damagePendingCount = 0
local activeDamageSlots = {}
local activeDamageCount = 0  -- 活跃槽位计数器，避免 table.getn()
local damageLastEnqueueTime = -0.05  --  错开批处理时间，避免与其他队列挤在同一帧
local damageLastBatchTime = -999   -- 最后一次批处理释放时间（用于严格控制0.1秒频率）
local DAMAGE_BATCH_DELAY = 0.1

-- 受疗队列
local healPendingList = {}
local healPendingCount = 0
local activeHealSlots = {}
local activeHealCount = 0  -- 活跃槽位计数器，避免 table.getn()
local healLastEnqueueTime = -0.075  --  错开批处理时间，避免与其他队列挤在同一帧
local healLastBatchTime = -999   -- 最后一次批处理释放时间（用于严格控制0.1秒频率）
local HEAL_BATCH_DELAY = 0.1

-- ======================== 工具函数 ================================
--  封装安全的字体大小获取函数，避免重复判断
local function GetSafeFontSize(size)
    return size and size > 0 and size or 42
end

--  封装安全的缩放值获取函数，避免重复判断
local function GetSafeScale(scale)
    return scale and scale >= 0.01 and scale or 0.01
end

--  计算暴击推开距离（基于二阶缩放 + 安全距离）
local function CalculateCritPushDistance(finalScaleValue)
    local baseScaleFactor = 0.3
    local digitBaseHeight = 64  -- 数字纹理基础高度
    local finalScaledHeight = digitBaseHeight * (finalScaleValue * baseScaleFactor)
    local safetyMargin = 5  -- 安全距离
    return finalScaledHeight + safetyMargin
end

-- 缓存暴击推开距离，避免重复计算
local cachedCritPushDistance = nil
local cachedCritScaleEnd = nil

local function GetCachedCritPushDistance()
    local critScaleEnd = UserSettings.critScaleEnd or 6.0
    if cachedCritScaleEnd ~= critScaleEnd then
        cachedCritScaleEnd = critScaleEnd
        cachedCritPushDistance = CalculateCritPushDistance(critScaleEnd)
    end
    return cachedCritPushDistance
end

-- ======================== 通用队列工具函数 ================================
-- queueType: "queue" = 队列模式(造成伤害), "received" = 受伤/受疗/输出治疗
local function CalculateQueueSpacing(newCount, maxVisibleHeight, bottomStartY, queueType)
    local currentSettings = addon.Config and addon.Config.UserSettings or UserSettings
    
    local queueFontSize, queueSpacing
    if queueType == "queue" then
        -- 队列模式（造成伤害）：使用动画ABC的配置
        queueFontSize = currentSettings.baseFontSize or 40
        queueSpacing = currentSettings.animASpacing or 0
    else
        -- 受伤/受疗/输出治疗队列：使用专用配置
        queueFontSize = currentSettings.queueFontSize or 40
        queueSpacing = currentSettings.queueSpacing or 0
    end
    
    local digitBaseHeight = 64
    local scale = queueFontSize / 100
    local actualDigitHeight = digitBaseHeight * scale
    local spacing = math_floor(actualDigitHeight * 0.8)
    spacing = math_max(spacing, 12)
    spacing = math_min(spacing, 60)
    
    -- 应用队列行距配置
    spacing = spacing + queueSpacing
    spacing = math_max(spacing, 5)
    
    local availableHeight = maxVisibleHeight - bottomStartY
    local requiredHeight = newCount * spacing
    if requiredHeight > availableHeight then
        spacing = math_floor(availableHeight / newCount)
        spacing = math_max(spacing, 15)
    end
    
    return spacing, newCount * spacing
end


-- 前向声明：ResetSlot函数在后面定义
local ResetSlot
local ResetReceivedSlot  -- 前向声明

-- 输出治疗队列
local outHealPendingList = {}
local outHealPendingCount = 0
local activeOutHealSlots = {}
local activeOutHealCount = 0  -- 活跃槽位计数器，避免 table.getn()
local outHealLastEnqueueTime = -0.1  --  错开批处理时间，避免与其他队列挤在同一帧
local outHealLastBatchTime = -999   -- 最后一次批处理释放时间（用于严格控制0.1秒频率）
local OUTHEAL_BATCH_DELAY = 0.1

-- ======================== 框架宽高缓存（性能优化）===============================
local cachedFrameWidth = {}
local cachedFrameHeight = {}
local DAMAGE_HISTORY_MAX = 10  -- 最大记录数

-- ==================== 伤害历史记录管理 ====================
-- 平均伤害缓存：每1分钟计算一次
local cachedAverageDamage = nil
local lastAverageDamageTime = 0
local AVERAGE_DAMAGE_INTERVAL = 60  -- 1分钟 = 60秒

-- 记录一次伤害到历史
local function RecordDamage(damage)
    if not damage or damage <= 0 then return end
    
    -- 写入环形缓冲区
    damageHistory[damageHistoryIndex] = damage
    damageHistoryIndex = math_mod(damageHistoryIndex + 1, DAMAGE_HISTORY_MAX)
    
    -- 更新计数（最多10）
    if damageHistoryCount < DAMAGE_HISTORY_MAX then
        damageHistoryCount = damageHistoryCount + 1
    end
end

-- 计算近 N 次伤害的平均值（带1分钟缓存）
local function GetAverageDamage(count)
    local now = GetTime()
    
    -- 如果缓存有效（1分钟内），直接返回缓存值
    if cachedAverageDamage and (now - lastAverageDamageTime) < AVERAGE_DAMAGE_INTERVAL then
        return cachedAverageDamage
    end
    
    -- 重新计算平均值
    if damageHistoryCount == 0 then
        cachedAverageDamage = 400  -- 默认基准值
    else
        local n = math_min(count or DAMAGE_HISTORY_MAX, damageHistoryCount)
        local sum = 0
        
        for i = 0, n - 1 do
            sum = sum + (damageHistory[i] or 0)
        end
        
        cachedAverageDamage = sum / n
    end
    
    -- 更新缓存时间戳
    lastAverageDamageTime = now
    
    return cachedAverageDamage
end


--  受伤害/受治疗 UI 模块==========================
addon.ReceivedUI = {
    frameDamage = nil,
    frameHeal = nil,
    frameOutHeal = nil,
    handleDamage = nil,
    handleHeal = nil,
    handleOutHeal = nil
}
local ReceivedUI = addon.ReceivedUI

-- ======================== 框架创建工厂函数===============================
local function CreateAnimFrame(config)
    local parent = config.parent or UIParent
    local name = config.name
    local dbPrefix = config.dbPrefix  
    local labelText = config.labelText
    local labelColor = config.labelColor or {1, 1, 1}
    local borderColor = config.borderColor or {1, 1, 1}
    local defaultX = config.defaultX or 0
    local defaultY = config.defaultY or 0
    local defaultW = config.defaultW or 200
    local defaultH = config.defaultH or 200
    local startPointPos = config.startPointPos or {"TOPLEFT", 20, -20}  -- {锚点, x, y}
    local endPointPos = config.endPointPos or {"BOTTOMRIGHT", -20, 20}
    
    -- 从数据库读取位置和大小
    local frameX = PTURTLE_Combat_DB and PTURTLE_Combat_DB[dbPrefix.."FrameX"] or defaultX
    local frameY = PTURTLE_Combat_DB and PTURTLE_Combat_DB[dbPrefix.."FrameY"] or defaultY
    local frameW = PTURTLE_Combat_DB and PTURTLE_Combat_DB[dbPrefix.."FrameWidth"] or defaultW
    local frameH = PTURTLE_Combat_DB and PTURTLE_Combat_DB[dbPrefix.."FrameHeight"] or defaultH
    
    -- 创建主框架
    local frame = CreateFrame("Frame", name, parent)
    frame:SetWidth(frameW)
    frame:SetHeight(frameH)
    frame:SetPoint("CENTER", parent, "CENTER", frameX, frameY)
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1, tileSize = 16, edgeSize = 16,
        insets = { left=4, right=4, top=4, bottom=4 }
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], 1)
    frame:SetBackdrop(nil)
    frame:EnableMouse(false)
    frame:SetMovable(true)
    frame:SetResizable(true)
    
    -- 拖动保存位置
    frame:SetScript("OnMouseDown", function() frame:StartMoving() end)
    frame:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        if PTURTLE_Combat_DB then
            local centerX, centerY = frame:GetCenter()
            local parentCenterX, parentCenterY = parent:GetCenter()
            PTURTLE_Combat_DB[dbPrefix.."FrameX"] = centerX - parentCenterX
            PTURTLE_Combat_DB[dbPrefix.."FrameY"] = centerY - parentCenterY
            PTURTLE_Combat_DB[dbPrefix.."FrameWidth"] = frame:GetWidth()
            PTURTLE_Combat_DB[dbPrefix.."FrameHeight"] = frame:GetHeight()
        end
    end)
    
    -- 标签
    local label = frame:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 16, "OUTLINE")
    label:SetPoint("TOP", frame, "TOP", 0, -10)
    label:SetText(labelText)
    label:SetTextColor(labelColor[1], labelColor[2], labelColor[3], 1)
    
    -- 调整大小手柄
    local resize = CreateFrame("Frame", nil, frame)
    resize:SetWidth(20)
    resize:SetHeight(20)
    resize:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
    resize:EnableMouse(true)
    
    local resizeIcon = resize:CreateFontString(nil, "OVERLAY")
    resizeIcon:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    resizeIcon:SetPoint("CENTER", 0, 0)
    resizeIcon:SetText("↘")
    resizeIcon:SetTextColor(1, 1, 0, 1)
    
    resize:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    resize:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        if PTURTLE_Combat_DB then
            local centerX, centerY = frame:GetCenter()
            local parentCenterX, parentCenterY = parent:GetCenter()
            PTURTLE_Combat_DB[dbPrefix.."FrameX"] = centerX - parentCenterX
            PTURTLE_Combat_DB[dbPrefix.."FrameY"] = centerY - parentCenterY
            PTURTLE_Combat_DB[dbPrefix.."FrameWidth"] = frame:GetWidth()
            PTURTLE_Combat_DB[dbPrefix.."FrameHeight"] = frame:GetHeight()
        end
        
        --  更新框架宽高缓存
        cachedFrameWidth[dbPrefix] = frame:GetWidth()
        cachedFrameHeight[dbPrefix] = frame:GetHeight()
    end)
    resize:SetScript("OnEnter", function()
        GameTooltip:SetOwner(resize, "ANCHOR_CURSOR")
        GameTooltip:SetText("拖动调整框架大小")
        GameTooltip:Show()
    end)
    resize:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 动画路径手柄
    local handle = CreateFrame("Frame", nil, frame)
    handle:SetWidth(40)
    handle:SetHeight(40)
    local handleX = PTURTLE_Combat_DB and PTURTLE_Combat_DB[dbPrefix.."HandleX"] or (dbPrefix == "dot" and -5 or 80)
    local handleY = PTURTLE_Combat_DB and PTURTLE_Combat_DB[dbPrefix.."HandleY"] or (dbPrefix == "dot" and -188 or -80)
    handle:SetPoint("TOPLEFT", frame, "TOPLEFT", handleX, handleY)
    handle:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
    })
    handle:SetBackdropColor(0.2, 0.4, 0.9, 0.9)
    handle:SetBackdropBorderColor(1, 1, 1, 1)
    handle:EnableMouse(true)
    
    -- 使用框架属性存储拖动状态，以便外部可以访问
    handle.isDragging = false
    handle:SetScript("OnMouseDown", function() handle.isDragging = true end)
    handle:SetScript("OnMouseUp", function()
        handle.isDragging = false
        if PTURTLE_Combat_DB then
            local _, _, _, offsetX, offsetY = handle:GetPoint()
            PTURTLE_Combat_DB[dbPrefix.."HandleX"] = tonumber(offsetX) or 80
            PTURTLE_Combat_DB[dbPrefix.."HandleY"] = tonumber(offsetY) or -80
        end
    end)
    handle:SetScript("OnUpdate", function()
        if not handle.isDragging then return end
        local mx, my = GetCursorPosition()
        local uis = parent:GetScale()
        local l = frame:GetLeft()
        local t = frame:GetTop()
        local x = (mx / uis - l) - 20
        local y = (t - my / uis) - 20
        handle:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
    end)
    handle:SetScript("OnEnter", function()
        GameTooltip:SetOwner(handle, "ANCHOR_CURSOR")
        GameTooltip:SetText("拖动调整动画路径")
        GameTooltip:Show()
    end)
    handle:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    -- 起点标识
    local startPoint = frame:CreateFontString(nil, "OVERLAY")
    startPoint:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    startPoint:SetPoint(startPointPos[1], frame, startPointPos[1], startPointPos[2], startPointPos[3])
    startPoint:SetText("始")
    startPoint:SetTextColor(0, 1, 0, 1)
    
    -- 终点标识
    local endPoint = frame:CreateFontString(nil, "OVERLAY")
    endPoint:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    endPoint:SetPoint(endPointPos[1], frame, endPointPos[1], endPointPos[2], endPointPos[3])
    endPoint:SetText("终")
    endPoint:SetTextColor(1, 0, 0, 1)
    
    -- 隐藏所有编辑元素
    label:Hide()
    resize:Hide()
    handle:Hide()
    startPoint:Hide()
    endPoint:Hide()
    
    return {
        frame = frame,
        handle = handle,
        label = label,
        resize = resize,
        startPoint = startPoint,
        endPoint = endPoint
    }
end

local function CreateReceivedUI()
    local parent = UIParent
    
    -- 创建受伤框架
    local damageConfig = {
        name = "PT_Received_Damage",
        dbPrefix = "damage",
        labelText = "受到伤害",
        labelColor = {1, 0.2, 0.2},
        borderColor = {1, 0.2, 0.2},
        defaultX = -195, defaultY = -104, defaultW = 244, defaultH = 252,
        startPointPos = {"TOPRIGHT", -20, -20},  --  起点改为右上角
        endPointPos = {"BOTTOMLEFT", 20, 20}      --  终点改为左下角
    }
    local damageUI = CreateAnimFrame(damageConfig)
    ReceivedUI.frameDamage = damageUI.frame
    ReceivedUI.handleDamage = damageUI.handle
    ReceivedUI.labelDamage = damageUI.label
    ReceivedUI.resizeDamage = damageUI.resize
    ReceivedUI.startPointDamage = damageUI.startPoint
    ReceivedUI.endPointDamage = damageUI.endPoint
    addon.DamageFrame = damageUI.frame
    
    -- 创建队列框架
    local dotConfig = {
        name = "PT_DOT_Damage",
        dbPrefix = "dot",  -- 注意：缓存键使用"dot"而不是"dotDamage"
        labelText = "DOT伤害",
        labelColor = {0.8, 0.2, 0.8},  -- 紫色
        borderColor = {0.8, 0.2, 0.8},
        defaultX = -569, defaultY = 169, defaultW = 38, defaultH = 400,  -- 默认位置：中心相对屏幕(-569, 169)
        startPointPos = {"BOTTOMLEFT", 20, 20},  -- 起点：左下角
        endPointPos = {"TOPRIGHT", -20, -20}       -- 终点：右上角
    }
    local dotUI = CreateAnimFrame(dotConfig)
    ReceivedUI.frameDOT = dotUI.frame
    ReceivedUI.handleDOT = dotUI.handle
    ReceivedUI.labelDOT = dotUI.label
    ReceivedUI.resizeDOT = dotUI.resize
    ReceivedUI.startPointDOT = dotUI.startPoint
    ReceivedUI.endPointDOT = dotUI.endPoint
    addon.DOTFrame = dotUI.frame
    
    --  队列框架创建后，重新设置AOE计数器的父级和位置
    if addon.aoeCounterFrame then
        addon.aoeCounterFrame:SetParent(addon.DOTFrame)
        addon.aoeCounterFrame:SetFrameLevel((addon.DOTFrame.GetFrameLevel and addon.DOTFrame:GetFrameLevel() or 0) + 10)
        addon.aoeCounterFrame:ClearAllPoints()
        -- 从数据库读取保存的偏移量
        local offsetX = PTURTLE_Combat_DB and PTURTLE_Combat_DB.aoeCounterOffsetX or 0
        -- 核心修复：默认偏移量应该是队列框架高度的一半+10，让计数器显示在底部下方
        local defaultOffsetY = -(addon.DOTFrame.GetHeight and addon.DOTFrame:GetHeight() / 2 + 10 or 30)
        local offsetY = PTURTLE_Combat_DB and PTURTLE_Combat_DB.aoeCounterOffsetY or defaultOffsetY
        addon.aoeCounterFrame:SetPoint("CENTER", addon.DOTFrame, "CENTER", offsetX, offsetY)
    end
    
    -- 创建受治疗框架
    local healConfig = {
        name = "PT_Received_Heal",
        dbPrefix = "receivedHeal",
        labelText = "受到治疗",
        labelColor = {0.2, 1, 0.2},
        borderColor = {0.2, 1, 0.2},
        defaultX = 166, defaultY = 16, defaultW = 183, defaultH = 178,
        startPointPos = {"TOPRIGHT", -20, -20},
        endPointPos = {"BOTTOMLEFT", 20, 20}
    }
    local healUI = CreateAnimFrame(healConfig)
    ReceivedUI.frameHeal = healUI.frame
    ReceivedUI.handleHeal = healUI.handle
    ReceivedUI.labelHeal = healUI.label
    ReceivedUI.resizeHeal = healUI.resize
    ReceivedUI.startPointHeal = healUI.startPoint
    ReceivedUI.endPointHeal = healUI.endPoint
    addon.ReceivedHealFrame = healUI.frame
    
    -- 创建输出治疗框架
    local outHealConfig = {
        name = "PT_Out_Heal",
        dbPrefix = "outputHeal",
        labelText = "输出治疗",
        labelColor = {0.2, 1, 0.2},
        borderColor = {0.2, 0.6, 1},
        defaultX = 150, defaultY = 261, defaultW = 236, defaultH = 273,
        startPointPos = {"BOTTOMLEFT", 20, 20},
        endPointPos = {"TOPRIGHT", -20, -20}
    }
    local outHealUI = CreateAnimFrame(outHealConfig)
    ReceivedUI.frameOutHeal = outHealUI.frame
    ReceivedUI.handleOutHeal = outHealUI.handle
    ReceivedUI.labelOutHeal = outHealUI.label
    ReceivedUI.resizeOutHeal = outHealUI.resize
    ReceivedUI.startPointOutHeal = outHealUI.startPoint
    ReceivedUI.endPointOutHeal = outHealUI.endPoint
    addon.OutputHealFrame = outHealUI.frame
end
addon.CreateReceivedUI = CreateReceivedUI

-- ======================== GUID 查找模块（插件兼容支持）===============================
local attachedWatchers = {}
local lastGUIDScan = 0

-- 核心开关：任意插件 Hook 成功 = 禁用原生扫描
local USE_PLUGIN_MODE = false

local function GetNameplateGUID(frame)
    if not frame then return nil end
    if frame.GetName then
        local guid = frame:GetName(1)
        if guid and guid ~= "" then return guid end
    end
    return nil
end

local function AttachWatcher(frame)
    if not frame or attachedWatchers[frame] then return end
    attachedWatchers[frame] = true

    local watcher = CreateFrame("Frame", nil, frame)
    watcher:SetAllPoints(frame)

    watcher:SetScript("OnShow", function()
        local guid = GetNameplateGUID(frame)
        if guid then
            guidToNameplate[guid] = frame
        end
    end)

    watcher:SetScript("OnHide", function()
        local guid = GetNameplateGUID(frame)
        if guid then
            -- 冻结绑定到该姓名板的伤害数字，避免最后一击数字跳到屏幕左侧
            addon:FreezeSlotsOnPlate(guid, frame)
            guidToNameplate[guid] = nil
        end
    end)

    local guid = GetNameplateGUID(frame)
    if guid and frame:IsVisible() then
        guidToNameplate[guid] = frame
    end
end

-- 只有插件未 Hook 成功时，才运行原生扫描
local function ScanNameplatesSimple(forceScan)
    if USE_PLUGIN_MODE then
        return
    end

    local now = GetTime()
    if not forceScan and (now - lastGUIDScan < 1.0) then return end
    lastGUIDScan = now

    -- 缓存映射表（使用文件顶部已本地化的 guidToNameplate）
    local guidToPlate = guidToNameplate

    for guid, plate in pairs(guidToPlate) do
        if not plate or not plate:IsVisible() then
            guidToPlate[guid] = nil
        end
    end

    -- 避免创建临时表，直接遍历
    local childCount = WorldFrame:GetNumChildren()
    for i = 1, childCount do
        local f = select(i, WorldFrame:GetChildren())
        if f and not attachedWatchers[f] then
            AttachWatcher(f)
        end
    end
end

local function GetNameplateByGUID(guid)
    -- 使用文件顶部已本地化的 guidToNameplate
    local plate = guidToNameplate[guid]
    return (plate and plate:IsVisible()) and plate or nil
end

addon.ScanNameplatesSimple = ScanNameplatesSimple

-- ======================== 全插件 Hook 系统 ================================
local function TryHookPFUI()
    if not (pfUI and pfUI.nameplates and pfUI.nameplates.OnCreate) then return nil end
    local success = pcall(function()
        local oldCreate = pfUI.nameplates.OnCreate
        pfUI.nameplates.OnCreate = function(frame)
            local _, res = pcall(oldCreate, frame)
            AttachWatcher(frame)
            return res
        end
    end)
    return success and "pfUI" or nil
end

local function TryHookShaguPlates()
    if not (ShaguPlates and ShaguPlates.nameplates and ShaguPlates.nameplates.OnCreate) then return nil end
    local success = pcall(function()
        local oldCreate = ShaguPlates.nameplates.OnCreate
        ShaguPlates.nameplates.OnCreate = function(frame, index)
            local _, res = pcall(oldCreate, frame, index)
            AttachWatcher(frame)
            return res
        end
    end)
    return success and "ShaguPlates" or nil
end

-- Hook ShaguPlatesX 姓名板
local function TryHookShaguPlatesX()
    if not (ShaguPlatesX and ShaguPlatesX.nameplates and ShaguPlatesX.nameplates.OnCreate) then return nil end
    local success = pcall(function()
        local oldCreate = ShaguPlatesX.nameplates.OnCreate
        ShaguPlatesX.nameplates.OnCreate = function(frame)
            local _, res = pcall(oldCreate, frame)
            AttachWatcher(frame)
            return res
        end
    end)
    return success and "ShaguPlatesX" or nil
end

-- Hook SimplePlates 姓名板
local function TryHookSimplePlates()
    if not SimplePlates or not CreatePlates then return nil end
    local success = pcall(function()
        local oldCreatePlates = CreatePlates
        CreatePlates = function()
            -- 先执行原始的 CreatePlates
            local _, res = pcall(oldCreatePlates)
            
            -- 然后注册 GUID 映射
            local frame = this
            if frame and type(frame) == "table" then
                AttachWatcher(frame)
            end
            
            return res
        end
    end)
    return success and "SimplePlates" or nil
end

local hookFastTimer, hookRetryCount = nil, 0
local MAX_RETRY = 60

local function StartFastHookTimer()
    if hookFastTimer then return end
    hookRetryCount = 0
    hookFastTimer = CreateFrame("Frame")
    hookFastTimer:SetScript("OnUpdate", function()
        hookRetryCount = hookRetryCount + 1

        -- 如果已经有插件 Hook 成功，直接跳过重试
        if USE_PLUGIN_MODE then
            hookFastTimer:SetScript("OnUpdate", nil)
            hookFastTimer = nil
            return
        end

        -- 一次性尝试所有插件：pfUI / ShaguPlatesX / ShaguPlates / SimplePlates
        local hookedPlugin = TryHookPFUI() or TryHookShaguPlatesX() or TryHookShaguPlates() or TryHookSimplePlates()

        if hookedPlugin or hookRetryCount >= MAX_RETRY then
            hookFastTimer:SetScript("OnUpdate", nil)
            hookFastTimer = nil

            if hookedPlugin then
                -- 任意插件成功关闭原生扫描
                USE_PLUGIN_MODE = true
                DEFAULT_CHAT_FRAME:AddMessage(string_format("|cff00ff00 [PlayTurtle] %s Hook 成功：已关闭原生扫描|r", hookedPlugin))
            else
                -- 全部失败启用原生扫描
                DEFAULT_CHAT_FRAME:AddMessage("|cffffaa00 [PlayTurtle] 第三方姓名板 Hook 超时：切换至原生扫描模式|r")
                pfUI = nil
                ShaguPlates = nil
                ShaguPlatesX = nil
                SimplePlates = nil
                ScanNameplatesSimple(true)
            end
        end
    end)
end
addon.StartFastHookTimer = StartFastHookTimer
-- ======================== 关键初始化 ================================
-- 纹理缓存变量（由 ReloadDigitTexture 自动管理）
math.randomseed(GetTime())
math_random()

-- ======================== 纹理预加载==============================
local PreloadedTextures = {}
local SpellIconPathCache = {}
local SpellIconPathCacheCount = 0  --   计数器替代pairs遍历
addon.SpellIdToNameCache = {}
local SpellIdToNameCacheCount = 0  --   计数器替代pairs遍历
local MAX_PRELOAD_TEXTURES = 128
local MAX_SPELL_CACHE = 128  -- 技能缓存最大数量

local DEFAULT_PLAYER_ICON = "Interface\\Icons\\Ability_Parry"
local DEFAULT_PET_ICON = "Interface\\Icons\\Ability_Druid_FerociousBite"
local COMBAT_STATUS_TEXTURE = "Interface\\AddOns\\PlayTurtle\\img\\X.blp"

local function PreloadTexture(path)
    if not path or PreloadedTextures[path] then return end
    local count = PreloadedTextures.count or 0  --   使用计数器替代pairs遍历
    if count >= MAX_PRELOAD_TEXTURES then

        local oldest = nil
        for k, v in pairs(PreloadedTextures) do
            if k ~= "count" and type(v) == "table" and v.SetTexture then
                oldest = k
                break
            end
        end
        if oldest then
            PreloadedTextures[oldest]:SetTexture(nil)
            PreloadedTextures[oldest] = nil
            PreloadedTextures.count = count - 1
        end
    end
    local tex = UIParent:CreateTexture(nil, "BACKGROUND")
    tex:SetTexture(path)
    tex:Hide()
    PreloadedTextures[path] = tex
    PreloadedTextures.count = count + 1
end

function addon:PreloadAllNumberStyles()
    for style = 1, 10 do
        local path = "Interface\\AddOns\\PlayTurtle\\img\\num"..style..".blp"
        PreloadTexture(path)
    end
    PreloadTexture(DEFAULT_PLAYER_ICON)
    PreloadTexture(DEFAULT_PET_ICON)
    PreloadTexture(COMBAT_STATUS_TEXTURE)
end

local function GetSpellIconTexturePath(spellId, guidPlayer, guidPet)
    if not spellId or spellId == "" then
        return nil  -- 没有spellId，不显示图标
    end
    if SpellIconPathCache[spellId] then return SpellIconPathCache[spellId] end
    
    -- 使用 nampower API 获取技能图标
    local spellIconId = GetSpellRecField(spellId, "spellIconID")
    if not spellIconId then
        return nil  -- API不存在或无图标，不显示
    end
    
    local texturePath = GetSpellIconTexture(spellIconId)
    if texturePath and texturePath ~= "" then
        -- 控制 SpellIconPathCache 大小（  使用计数器替代pairs）
        if SpellIconPathCacheCount >= MAX_SPELL_CACHE then
            -- 清空一半缓存
            local i = 0
            for k in pairs(SpellIconPathCache) do
                i = i + 1
                if i > MAX_SPELL_CACHE / 2 then
                    SpellIconPathCache[k] = nil
                    SpellIconPathCacheCount = SpellIconPathCacheCount - 1
                end
            end
        end
        
        SpellIconPathCache[spellId] = texturePath
        SpellIconPathCacheCount = SpellIconPathCacheCount + 1
        
        -- 控制 SpellIdToNameCache 大小（  使用计数器替代pairs）
        if SpellIdToNameCacheCount >= MAX_SPELL_CACHE then
            -- 清空一半缓存
            local i = 0
            for k in pairs(addon.SpellIdToNameCache) do
                i = i + 1
                if i > MAX_SPELL_CACHE / 2 then
                    addon.SpellIdToNameCache[k] = nil
                    SpellIdToNameCacheCount = SpellIdToNameCacheCount - 1
                end
            end
        end
        
        -- 获取技能名称并缓存
        local spellName = GetSpellRecField(spellId, "name")
        if spellName and spellName ~= "" then
            addon.SpellIdToNameCache[spellId] = spellName
            SpellIdToNameCacheCount = SpellIdToNameCacheCount + 1
        end
        PreloadTexture(texturePath)
        return texturePath
    end
    if guidPlayer == addon.GUID_Player then return DEFAULT_PLAYER_ICON end
    if guidPet == addon.GUID_Pet then return DEFAULT_PET_ICON end
    return nil
end

-- ======================== 伤害颜色 ================================
addon.SchoolData = {
    [0] = { color = {1.0, 1.0, 1.0} },   -- 物理（纯白）
    [1] = { color = {1.0, 0.85, 0.4} },  -- 神圣（橙黄色）
    [2] = { color = {1.0, 0.28, 0.0} },  -- 火焰（深红色）
    [3] = { color = {0.44, 1.0, 0.43} }, -- 自然（浅绿色）
    [4] = { color = {0.3, 0.54, 1.0} },  -- 冰霜（蓝色）
    [5] = { color = {0.77, 0.28, 1.0} }, -- 暗影（紫罗兰色）
    [6] = { color = {0.0, 0.8, 1.0} },   -- 奥术（天蓝色）
    [7] = { color = {1.0, 0.9, 0.0} },   -- 技能物理（深黄色）
}

-- ======================== 防御状态 UV 映射 ================================
-- 统一防御状态 UV 表（按语义组织，避免 SPELL_MISS_* 和 VICTIMSTATE 数值混淆）
local DefenceStatusUVs = {
    -- SPELL_MISS_* 常量映射（用于 SPELL_MISSED 事件，DEFENCE 字段）
    SPELL_MISS = {
        [1]  = {0.0, 0.5, 0.0, 0.25},   -- miss 未命中
        [2]  = {0.5, 1.0, 0.75, 1.0},   -- 抵抗
        [3]  = {0.5, 1.0, 0.5, 0.75},   -- 闪避
        [4]  = {0.0, 0.5, 0.75, 1.0},   -- 招架
        [5]  = {0.5, 1.0, 0.25, 0.5},   -- 格挡
        [6]  = {0.5, 1.0, 0.5, 0.75},   -- 闪避（同3）
        [7]  = {0.5, 1.0, 0.0, 0.25},   -- 免疫
        [8]  = {0.5, 1.0, 0.0, 0.25},   -- 免疫（同7）
        [10] = {0.0, 0.5, 0.25, 0.5},   -- 吸收
        [11] = {0.0, 0.5, 0.5, 0.75},   -- 反射
    },
    -- VICTIMSTATE 常量映射（用于 AUTO_ATTACK 事件，DEFENCE_T 字段）
    VICTIMSTATE = {
        [0] = {0.0, 0.5, 0.0, 0.25},    -- miss 未命中
        [2] = {0.5, 1.0, 0.5, 0.75},    -- 闪避
        [3] = {0.0, 0.5, 0.75, 1.0},    -- 招架
        [5] = {0.5, 1.0, 0.25, 0.5},    -- 格挡
        [6] = {0.5, 1.0, 0.5, 0.75},    -- 闪避（同2）
        [7] = {0.5, 1.0, 0.0, 0.25},    -- 免疫
        [8] = {0.0, 0.5, 0.5, 0.75},    -- 反射
    }
}

-- ======================== 精灵图 UV ================================
local digitUVs = {
    [0] = {0/4, 1/4, 0/3, 1/3}, [1] = {1/4, 2/4, 0/3, 1/3},
    [2] = {2/4, 3/4, 0/3, 1/3}, [3] = {3/4, 4/4, 0/3, 1/3},
    [4] = {0/4, 1/4, 1/3, 2/3}, [5] = {1/4, 2/4, 1/3, 2/3},
    [6] = {2/4, 3/4, 1/3, 2/3}, [7] = {3/4, 4/4, 1/3, 2/3},
    [8] = {0/4, 1/4, 2/3, 3/3}, [9] = {1/4, 2/4, 2/3, 3/3},
    ['+'] = {2/4, 3/4, 2/3, 3/3}, ['-'] = {3/4, 4/4, 2/3, 3/3}
}
-- ✅ 优化：预提取 +/- 号的UV坐标，避免unpack创建临时表
local minusUV = digitUVs['-']
local plusUV = digitUVs['+']
local digitWidths = { [0]=48,[1]=48,[2]=48,[3]=48,[4]=48,[5]=48,[6]=48,[7]=48,[8]=48,[9]=48,['+']=40,['-']=48 }--各区域宽度调整

-- ======================== 内部变量 ================================
local aniData = {}
local activeSlots = {}  -- 数组索引，存储活跃的伤害动画槽位
local activeSlotCount = 0  -- 活跃伤害槽位数量（用于快速遍历）
local activeCount = 0
local ReceivedAnimationPool = {}

-- - 暴击计数缓存（避免在GetBestSlot中重复遍历统计）
local guidCritCount = {}      -- 每个GUID的暴击数量 {"guid-xxx"] = 2}
local fixedPosCritCount = 0   -- 固定位置的暴击数量
local guidCritYOffset = {}    -- 每个GUID的暴击Y位置偏移量 {"guid-xxx"] = 80}（性能优化：避免遍历槽位）
local lastDamageSlotIndex = 0 -- 伤害槽位轮询索引

addon.aniData = aniData
addon.ReceivedAnimationPool = ReceivedAnimationPool

-- ======================== 姓名板消失冻结机制 ================================
-- 当单位死亡/姓名板被回收时，把绑定到该姓名板的伤害数字"冻结"在当前屏幕位置，
-- 避免最后一击的数字因姓名板被回收（ClearAllPoints）而跳到屏幕左侧/DOTFrame 位置
local function FreezeSlotToScreen(slot, relX, relY)
    if not slot or not slot.FrameOutside then return end

    -- 复用或创建"幽灵锚点"帧（静态不可见，模拟姓名板的固定位置）
    local ghost = slot.ghostPlate
    if not ghost then
        ghost = CreateFrame("Frame", nil, UIParent)
        ghost:SetWidth(1)
        ghost:SetHeight(1)
        slot.ghostPlate = ghost
    end

    ghost:ClearAllPoints()
    ghost:SetPoint("CENTER", UIParent, "CENTER", relX, relY)

    -- 将数字重新锚定到幽灵锚点，断开与原姓名板的关联
    slot.FrameOutside:ClearAllPoints()
    slot.FrameOutside:SetPoint("CENTER", ghost, "CENTER", 0, 0)
    slot.isFrozen = true
    slot.hasPlate = true  -- 让动画继续按"有姓名板"处理，避免被提前回收
end

-- 冻结绑定到指定姓名板的所有活跃伤害数字
-- guid: 单位GUID；plate: 可选，直接传入姓名板框架（OnHide 时使用，避免查表）
function addon:FreezeSlotsOnPlate(guid, plate)
    if not guid then return end
    if not plate then
        plate = guidToNameplate[guid]
    end
    if not plate then return end

    local cx, cy = plate:GetCenter()
    if not cx or not cy then return end

    local pcx, pcy = UIParent:GetCenter()
    local relX = cx - pcx
    local relY = cy - pcy

    for i = 1, activeSlotCount do
        local slot = activeSlots[i]
        if slot and slot.GUID == guid and not slot.isFrozen and not slot.useFixedPos then
            -- 队列模式下的暴击数字固定显示在队列框架，不应冻结
            local isQueueCrit = slot.isCrit == 1 and addon.DOTFrame
                and addon.db and addon.db.dotQueueEnabled == 1
            if not isQueueCrit then
                FreezeSlotToScreen(slot, relX, relY)
            end
        end
    end

    -- 处理尚未释放的普通伤害槽位（动画A队列），避免最后一击普通伤害数字消失
    for i = 1, normalPendingCount do
        local slot = normalPendingList[i]
        if slot and slot.GUID == guid and not slot.isFrozen and not slot.useFixedPos then
            FreezeSlotToScreen(slot, relX, relY)
        end
    end
end

local texturePaths = {
    [1] = "Interface\\AddOns\\PlayTurtle\\img\\num1.blp",
    [2] = "Interface\\AddOns\\PlayTurtle\\img\\num2.blp",
    [3] = "Interface\\AddOns\\PlayTurtle\\img\\num3.blp",
    [4] = "Interface\\AddOns\\PlayTurtle\\img\\num4.blp",
    [5] = "Interface\\AddOns\\PlayTurtle\\img\\num5.blp",
    [6] = "Interface\\AddOns\\PlayTurtle\\img\\num6.blp",
    [7] = "Interface\\AddOns\\PlayTurtle\\img\\num7.blp",
    [8] = "Interface\\AddOns\\PlayTurtle\\img\\num8.blp",
    [9] = "Interface\\AddOns\\PlayTurtle\\img\\num9.blp",
    [10] = "Interface\\AddOns\\PlayTurtle\\img\\num10.blp"
}

local isInitialized = 0
local cachedStyleIndex  -- 缓存当前样式索引，避免重复更新
local cachedTexturePath  -- 缓存当前纹理路径，避免重复加载
local MAX_ANI_SLOTS = SystemParams.MAX_ANI_SLOTS or 50
local MAX_DIGITS = SystemParams.MAX_DIGITS or 5
local digitW = 51
local digitH = 64
local iconW = 40
local iconH = 40

-- 刷新所有活动动画槽位的字符大小
function addon:RefreshAllSlotsFontSize()
    local baseFontSize = GetSafeFontSize(UserSettings.baseFontSize or 40)
    
    --  清除队列控制点缓存，确保框架大小改变后重新计算
    dotControlPointCache.p1x = nil
    dotControlPointCache.p1y = nil
    
    local i = 1
    while i <= MAX_ANI_SLOTS do
        local slot = activeSlots[i]
        if slot and slot.Frame and slot.isActive == 1 then
            --  同时刷新非暴击伤害和 DOT 槽位
            if slot.isCrit == 0 then
                -- 非暴击伤害：应用基础缩放 * sizeScale
                local sizeScale = slot.normal.sizeScale or 1
                if sizeScale <= 0 then sizeScale = 1 end
                local newScale = GetSafeScale((baseFontSize / 100) * sizeScale)
                slot.Frame:SetScale(newScale)
            elseif slot.animMode == "queue" then
                -- 队列模式：使用队列字符大小（支持独立控制）
                local queueFontSize = UserSettings.queueFontSize or 40
                local newScale = GetSafeScale(queueFontSize / 100)
                slot.Frame:SetScale(newScale)
            end
        end
        i = i + 1
    end
end

-- 清除DOT控制点缓存（供配置同步时调用）
function addon:ClearDOTControlPointCache()
    dotControlPointCache.p1x = nil
    dotControlPointCache.p1y = nil
end

-- ======================== 工具函数 ================================
local function Clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end
local function GetSafeElapsed(elapsed)
    if not elapsed or type(elapsed) ~= "number" then return 0.016 end
    return Clamp(elapsed, 0.001, 0.1)
end
local function SafeTableLen(t)
    if not t then return 0 end
    local len = 0
    local i = 1
    while t[i] do len=len+1; i=i+1 end
    return len
end
local function IsNamePlateValid(np)
    if not np then return false end
    if not np.IsShown or not np:IsShown() then return false end
    return true
end

-- ======================== 通用配置缓存函数（消除重复）===============================
-- 为伤害数字槽位设置配置缓存
local function SetDamageSlotCache(slot)
    slot.cachedAnchorX = UserSettings.anchorXOffset or 0
    --  动画A接受非暴击滑块里的浮动速度滑块控制（normalMoveRandom）
    slot.cachedMoveSpeed = UserSettings.normalMoveRandom or 120
    slot.cachedFadeDur = UserSettings.normalFadeDuration or 0.5
    slot.cachedBaseFontSize = UserSettings.baseFontSize or 42
    slot.cachedFadeStart = SystemParams.NORMAL_FADE_START or 0.3
    slot.cachedCritScaleStart = UserSettings.critScaleStart or 12.0
    slot.cachedCritScaleEnd = UserSettings.critScaleEnd or 6.0
    slot.cachedCritHoldTime = UserSettings.critHoldTime or 0.3  -- 停留时间默认 0.3 秒（与滑块一致）
    slot.cachedCritScaleUp = SystemParams.CRIT_SCALE_UP_TIME or 0.15
    slot.cachedCritScaleDown = SystemParams.CRIT_SCALE_DOWN_TIME or 0.15
    -- 缓存暴击抖动配置，避免OnUpdate每帧读取UserSettings
    slot.cachedCritNumberShakeEnabled = UserSettings.critNumberShakeEnabled or 0
    slot.cachedCritShakeIntensity = UserSettings.critShakeIntensity or 1
    slot.cachedCritShakeFrequency = UserSettings.critShakeFrequency or 12
    slot.cachedPetQueueXOffset = UserSettings.petQueueXOffset or 0
end

-- 为受伤/受治疗/输出治疗槽位设置配置缓存
local function SetReceivedSlotCache(slot)
    slot.cachedFadeDur = UserSettings.normalFadeDuration or 0.5
    slot.cachedMoveSpeed = UserSettings.receivedMoveSpeed or 150  
    
    --  队列系统使用queueFontSize（队列字符大小滑块），而非baseFontSize
    slot.cachedBaseFontSize = UserSettings.queueFontSize or 40
    
    slot.cachedFadeStart = SystemParams.NORMAL_FADE_START or 0.3
    
    -- 暴击动画配置：统一使用与伤害暴击相同的滑块控制
    slot.cachedCritScaleStart = UserSettings.critScaleStart or 12.0
    slot.cachedCritScaleEnd = UserSettings.critScaleEnd or 6.0
    slot.cachedCritHoldTime = UserSettings.critHoldTime or 0.3  -- 停留时间默认 0.3 秒（与滑块一致）
    slot.cachedCritScaleUp = SystemParams.CRIT_SCALE_UP_TIME or 0.15
    slot.cachedCritScaleDown = SystemParams.CRIT_SCALE_DOWN_TIME or 0.15
    
    -- 暴击抖动配置：统一使用 critNumberShakeEnabled（与伤害暴击一致）
    slot.cachedCritNumberShakeEnabled = UserSettings.critNumberShakeEnabled or 0
    slot.cachedCritShakeIntensity = UserSettings.critShakeIntensity or 1
    slot.cachedCritShakeFrequency = UserSettings.critShakeFrequency or 12
    
    slot.cachedPetQueueXOffset = UserSettings.petQueueXOffset or 0
end

-- 获取伤害颜色（统一逻辑）
local function GetDamageColor(school)
    local colorData = addon.SchoolData[school] or addon.SchoolData[0]
    local customColor = PTURTLE_Combat_DB and PTURTLE_Combat_DB.damageColors and PTURTLE_Combat_DB.damageColors[school]
    if customColor then
        return customColor.r, customColor.g, customColor.b
    else
        return colorData.color[1], colorData.color[2], colorData.color[3]
    end
end

-- ======================== 纹理创建 ================================
local function CreateNumberTextures(parent, poolType)
    local texs = {}
    --  从 UserSettings 读取字体样式（确保与存档同步）
    local styleIndex = UserSettings.digitTextureStyle or 1
    local texturePath = texturePaths[styleIndex] or texturePaths[1]

    -- 创建 +/- 符号纹理（在技能图标前）
    local signTex = parent:CreateTexture(nil, "OVERLAY")
    signTex:SetTexture(texturePath)
    signTex:SetWidth(digitW)
    signTex:SetHeight(digitH)
    signTex:SetPoint("CENTER", parent, "CENTER", -digitW - 6, 0)  -- 初始位置，后续会动态调整
    signTex:Hide()
    texs.sign = signTex  -- 使用命名索引

    local iconTex = parent:CreateTexture(nil, "OVERLAY")
    iconTex:SetTexture("Interface\\Icons\\Ability_Druid_FerociousBite")
    iconTex:SetWidth(iconW)
    iconTex:SetHeight(iconH)
    iconTex:SetPoint("CENTER", parent, "CENTER", 0, 0)
    iconTex:Hide()
    texs[1] = iconTex

    local i = 2
    while i <= MAX_DIGITS + 1 do
        local digitTex = parent:CreateTexture(nil, "OVERLAY")
        digitTex:SetTexture(texturePath)
        digitTex:SetWidth(digitW)
        digitTex:SetHeight(digitH)
        digitTex:SetPoint("CENTER", parent, "CENTER", 0, 0)
        digitTex:Hide()
        texs[i] = digitTex
        i = i + 1
    end
    return texs
end

-- ======================== 统一字体热切换函数 ================================
-- 更新所有动画槽位的数字纹理样式
function addon:ReloadDigitTexture()
    -- 1.  从 UserSettings 读取字体样式（确保与存档同步）
    local styleIndex = UserSettings.digitTextureStyle or 1
    
    -- 2. 获取新的纹理路径
    local newTexturePath = texturePaths[styleIndex] or texturePaths[1]
    
    -- 3. 如果样式没有变化，直接返回（避免不必要的更新）
    if cachedStyleIndex == styleIndex and cachedTexturePath == newTexturePath then
        return
    end
    
    -- 4. 更新全局缓存
    cachedStyleIndex = styleIndex
    cachedTexturePath = newTexturePath
    
    -- 5. 预加载新纹理
    PreloadTexture(cachedTexturePath)
    
    -- 6. 统一的纹理更新辅助函数
    local function UpdateSlotTextures(slot)
        if not slot or not slot.Textures then
            return
        end
        local texCount = slot.texCount or (MAX_DIGITS + 1)
        
        -- 更新 +/- 符号纹理
        if slot.Textures.sign then
            slot.Textures.sign:SetTexture(cachedTexturePath)
        end
        
        -- 更新数字纹理
        for i = 2, texCount do
            local tex = slot.Textures[i]
            if tex then
                tex:SetTexture(cachedTexturePath)
            end
        end
    end
    
    -- 7. 更新输出伤害动画槽位（aniData）
    --  aniData是固定大小数组，使用数字索引遍历避免pairs()的GC压力
    local i = 1
    while i <= MAX_ANI_SLOTS do
        UpdateSlotTextures(aniData[i])
        i = i + 1
    end
    
    -- 8. 更新受伤/受治疗/输出治疗动画池（ReceivedAnimationPool）
    local maxSlots = SystemParams.MAX_RECEIVED_SLOTS or 30
    for i = 1, maxSlots do
        UpdateSlotTextures(ReceivedAnimationPool[i])
    end
end

--  使用数学方法拆分数字，避免字符串分配
-- 将数字拆分为各位数字数组（从高位到低位）
local _digitBuffer = {0, 0, 0, 0, 0}  -- 预分配固定大小数组（5位=万位），避免GC

local function SplitNumberToDigits(num)
    -- 注意：调用方保证 num > 0，这里只处理意外情况
    if num <= 0 then
        _digitBuffer[1] = 0
        return 1
    end
    
    -- 第一步：从低位到高位存储
    local count = 0
    local temp = num
    while temp > 0 and count < 5 do  -- 最多5位（万位）
        count = count + 1
        _digitBuffer[count] = math_mod(temp, 10)  -- 取个位
        temp = math_floor(temp / 10)              -- 去掉个位
    end
    
    -- 第二步：原地反转（从高位到低位）
    local half = math_floor(count / 2)
    for i = 1, half do
        local j = count - i + 1
        _digitBuffer[i], _digitBuffer[j] = _digitBuffer[j], _digitBuffer[i]
    end
    
    return count
end

local function SetNumberTextures(texs, num, isCrit, useRandomOffset, texCount)
    --  确保 num 是数字类型（防御状态可能传入空字符串）
    if not num or type(num) ~= "number" then
        num = 0
    end
    
    local maxTexCount = texCount or (MAX_DIGITS + 1)
    
    --  使用数学方法拆分数字，0字符串分配

    if num > 99999 then
        num = 99999  -- 最大显示99,999（5位）
    end
    
    local len = SplitNumberToDigits(num)
    len = Clamp(len, 1, MAX_DIGITS)
    
    --  从 UserSettings 读取字符间距（确保与存档同步）
    local charSpacing = UserSettings.charSpacing or -8
    charSpacing = Clamp(charSpacing, -20, 10)
    local isCritType = (isCrit == 1)
    local parent = texs[1]:GetParent()
    
    --先检测 +/- 符号是否存在，并获取实际宽度
    -- 防御状态不显示符号
    local hasSign = 0
    if texs.sign and texs.sign:IsShown() then
        -- 检查是否为防御状态（通过检查防御图标是否显示来判断）
        local isDefenceState = (texs[2] and texs[2]:IsShown())
        if not isDefenceState then
            hasSign = 1
        end
    end
    local signWidth = 0
    if hasSign == 1 then
        local leftU = texs.sign:GetTexCoord()
        if leftU then
            -- 通过 UV 坐标判断是 + 还是 -
            if leftU == 2/4 then
                -- '+' 号
                signWidth = digitWidths['+'] or digitW
            elseif leftU == 3/4 then
                -- '-' 号
                signWidth = digitWidths['-'] or digitW
            else
                -- 默认使用 digitW
                signWidth = digitW
            end
        else
            signWidth = digitW
        end
    end
    local signSpacing = 6  -- +/- 符号和图标之间的间距

    --  非DOT伤害使用居中对齐，避免暴击放大时产生偏移
    local iconSpacing = 3  -- 图标和数字之间的间距
    
    -- 检测图标是否显示
    local hasIcon = texs[1]:IsShown() and 1 or 0
    local iconWidth = hasIcon * iconW
    
    -- 第一步：计算总宽度（用于居中对齐）
    local totalWidth = 0
    if hasSign == 1 then
        totalWidth = totalWidth + signWidth + signSpacing
    end
    -- 无论图标是否显示，都预留图标宽度
    totalWidth = totalWidth + iconW + iconSpacing
    
    -- 计算数字总宽度
    local digitsTotalWidth = 0
    local i = 1
    while i <= len do
        local d = _digitBuffer[i]
        if d and digitUVs[d] then
            local currentDigitW = digitWidths[d] or digitW
            digitsTotalWidth = digitsTotalWidth + currentDigitW
            if i < len then
                digitsTotalWidth = digitsTotalWidth + charSpacing
            end
        end
        i = i + 1
    end
    totalWidth = totalWidth + digitsTotalWidth
    
    -- 第二步：从中心开始排列（总宽度的一半作为起始偏移）
    local centerX = -totalWidth / 2
    local currentX = centerX
    
    -- 设置 +/- 符号位置
    if hasSign == 1 then
        local signCenterX = currentX + signWidth / 2
        texs.sign:SetPoint("CENTER", parent, "CENTER", signCenterX, 0)
        currentX = currentX + signWidth + signSpacing
    end
    
    -- 设置图标位置（无论是否显示都预留空间）
    if hasIcon == 1 then
        local iconCenterX = currentX + iconW / 2
        texs[1]:SetPoint("CENTER", parent, "CENTER", iconCenterX, 0)
        currentX = currentX + iconW + iconSpacing
    else
        -- 即使图标隐藏，也预留图标宽度以保证对齐
        texs[1]:SetPoint("CENTER", parent, "CENTER", currentX + iconW / 2, 0)
        currentX = currentX + iconW + iconSpacing
    end
    
    -- 设置数字纹理位置
    i = 1
    while i <= len do
        local texIndex = i + 1
        if texIndex > maxTexCount then break end
        local d = _digitBuffer[i]  
        if not d or not digitUVs[d] then i=i+1 return end
        local digitTex = texs[texIndex]
        local uv = digitUVs[d]
        digitTex:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
        digitTex:SetWidth(digitW)  -- 确保数字纹理尺寸正确
        digitTex:SetHeight(digitH)
        local currentDigitW = digitWidths[d] or digitW
        -- 数字居中排列
        local offsetX = currentX + currentDigitW / 2
        digitTex:SetPoint("CENTER", parent, "CENTER", offsetX, 0)
        digitTex:Show()
        currentX = currentX + currentDigitW + charSpacing
        i = i + 1
    end
end

local function SetNumberTexturesColor(texs, r,g,b, texCount)
    local count = texCount or (MAX_DIGITS + 1)
    local i = 2
    while i <= count do
        if texs[i] and texs[i]:IsShown() then
            texs[i]:SetVertexColor(r,g,b)
        end
        i = i + 1
    end
end

-- 队列系统专用：左对齐排列，确保不同长度的数字视觉中心一致
local function SetNumberTexturesForQueue(texs, amount, texCount)
    if not texs or not texs[1] then return end
    
    local parent = texs[1]:GetParent()
    if not parent then return end
    
    -- 保护：确保 amount 不为 nil
    if not amount then
        amount = 0
    end
    
    local maxTexCount = texCount or (MAX_DIGITS + 1)
    
    --  使用数学方法拆分数字
    if amount > 99999 then
        amount = 99999  -- 最大显示99,999（5位）
    end
    
    local len = SplitNumberToDigits(amount)
    len = Clamp(len, 1, MAX_DIGITS)
    
    -- 获取配置
    local charSpacing = UserSettings.charSpacing or -8
    charSpacing = Clamp(charSpacing, -20, 10)
    
    --先检测 +/- 符号是否存在，并获取实际宽度
    -- 防御状态不显示符号
    local hasSign = 0
    if texs.sign and texs.sign:IsShown() then
        -- 检查是否为防御状态（通过检查防御图标是否显示来判断）
        local isDefenceState = (texs[2] and texs[2]:IsShown())
        if not isDefenceState then
            hasSign = 1
        end
    end
    local signWidth = 0
    if hasSign == 1 then
        local leftU = texs.sign:GetTexCoord()
        if leftU then
            -- 通过 UV 坐标判断是 + 还是 -
            if leftU == 2/4 then
                -- '+' 号
                signWidth = digitWidths['+'] or digitW
            elseif leftU == 3/4 then
                -- '-' 号
                signWidth = digitWidths['-'] or digitW
            else
                -- 默认使用 digitW
                signWidth = digitW
            end
        else
            signWidth = digitW
        end
    end
    
    local signSpacing = 20  -- +/- 符号和图标之间的间距
    local iconSpacing = 4   -- 图标和数字之间的间距
    local defenceIconSpacing = 2  -- 防御图标与数字之间的间距
    
    -- DOT模式：无论暴击与否，都使用左对齐
    --  以技能图标左侧为基准，确保与防御图标对齐一致
    local startX = 0  -- 从父框架中心开始
    
    -- 检测图标是否显示
    local hasIcon = texs[1]:IsShown() and 1 or 0
    local iconWidth = hasIcon * iconW
    
    --  检测防御状态图标（Textures[2]）
    -- 在队列系统中，只有防御状态时才会设置防御图标，非防御状态时Textures[2]应该被隐藏
    local hasDefenceIcon = (texs[2] and texs[2]:IsShown()) and 1 or 0
    
    -- 设置 +/- 符号位置（但不影响数字布局）
    if hasSign == 1 then
        local signCenterX = startX - signWidth / 2 - signSpacing
        texs.sign:SetPoint("CENTER", parent, "CENTER", signCenterX, 0)
        --   核心修复：不调整startX，让符号不参与布局计算
    end
    
    -- 设置图标位置（技能图标居中）
    if hasIcon == 1 then
        local iconCenterX = 0
        texs[1]:SetPoint("CENTER", parent, "CENTER", iconCenterX, 0)
        startX = iconCenterX + iconW / 2 + iconSpacing  -- 从技能图标右侧开始
    else
        --  图标隐藏时，仍预留图标宽度以保证队列对齐
        texs[1]:Hide()
        startX = startX + iconW / 2 + iconSpacing  -- 仍然预留空间
    end
    
    --  防御图标只在防御状态显示时才预留空间
    -- 与技能图标不同：技能图标始终存在（只是可能没有纹理），而防御图标只在防御状态时存在
    if hasDefenceIcon == 1 then
        -- 防御状态：预留防御图标空间
        startX = startX + 128 + defenceIconSpacing
    end
    -- 非防御状态：不预留防御图标空间，因为Textures[2]已被隐藏
    
    local i = 1
    while i <= len do
        local texIndex = i + 1
        if texIndex > maxTexCount then break end
        local d = _digitBuffer[i]  
        if not d or not digitUVs[d] then i=i+1 return end
        local digitTex = texs[texIndex]
        local uv = digitUVs[d]
        digitTex:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
        digitTex:SetWidth(digitW)
        digitTex:SetHeight(digitH)
        local currentDigitW = digitWidths[d] or digitW
        -- 数字从左到右排列
        local offsetX = startX + (i - 1) * (currentDigitW + charSpacing) + currentDigitW / 2
        digitTex:SetPoint("CENTER", parent, "CENTER", offsetX, 0)
        digitTex:Show()
        i = i + 1
    end
end

-- ======================== 通用技能图标应用函数 ================================
-- 统一的技能图标设置入口，整合所有判断逻辑
-- 参数：
--   tex: 纹理对象（通常是 slot.Textures[1] 或 texs[1]）
--   parentFrame: 父框架（用于定位）
--   spellId: 法术ID（可以是 nil、空字符串""、或数字字符串）
--   guidPlayer: 施法者GUID（用于区分玩家/宠物图标）
--   isCrit: 是否暴击（0=非暴击，1=暴击）
--   isDefenceStatus: 是否为防御状态（无伤害时的状态显示）
--   iconOffsetX: 图标X轴偏移量（可选）
-- 返回：是否成功显示图标（true/false）
local function ApplySpellIcon(tex, parentFrame, spellId, guidPlayer, isCrit, isDefenceStatus, iconOffsetX)
    if not tex or not parentFrame then
        return false
    end
    
    -- 检查是否启用技能图标
    if not addon.db or addon.db.showSpellIcon ~= 1 then
        tex:Hide()
        return false
    end
    
    -- 检查非暴击是否隐藏图标
    if isCrit == 0 and addon.db.hideIconForNonCrit and addon.db.hideIconForNonCrit == 0 then
        tex:Hide()
        return false
    end
    
    -- 确定图标纹理
    local iconTexture
    
    if spellId and spellId ~= "" then
        if spellId > 0 then
            --  技能ID 75（自动射击）跟随普攻图标开关
            if spellId == 75 then
                local autoAttackEnabled = addon.db and addon.db.autoAttackIconEnabled or 1
                if autoAttackEnabled == 1 then
                    iconTexture = GetSpellIconTexturePath(spellId, guidPlayer, addon.GUID_Pet)
                end
            else
                -- 其他技能：始终显示
                iconTexture = GetSpellIconTexturePath(spellId, guidPlayer, addon.GUID_Pet)
            end
        end
    elseif spellId == "" then
        -- spellId 为空字符串：普攻，显示默认图标（跟随图标开关）
        local autoAttackEnabled = addon.db and addon.db.autoAttackIconEnabled or 1
        if autoAttackEnabled == 1 then
            -- 根据 GUID 区分玩家和宠物图标
            if guidPlayer == addon.GUID_Pet then
                iconTexture = DEFAULT_PET_ICON
            else
                iconTexture = DEFAULT_PLAYER_ICON
            end
        end
        -- 注意：防御状态时也显示普攻图标
    end
    -- spellId 为 nil 时，iconTexture 保持 nil，不显示图标
    
    -- 设置图标
    if iconTexture then
        tex:SetTexture(iconTexture)
        tex:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        tex:SetWidth(iconW)
        tex:SetHeight(iconH)
        -- 只有当 iconOffsetX 不为 nil 时才重新设置位置
        if iconOffsetX ~= nil then
            tex:SetPoint("CENTER", parentFrame, "CENTER", iconOffsetX, 0)
        end
        -- 如果 iconOffsetX 为 nil，保持当前位置不变（由 SetNumberTextures 设置）
        tex:Show()
        return true
    else
        tex:Hide()
        return false
    end
end

local function HideTextures(texs)
    if not texs then return end
    local i = 1
    while i <= SafeTableLen(texs) do
        if texs[i] then texs[i]:Hide() end
        i = i + 1
    end
end

-- ======================== 通用防御状态图标设置函数 ================================
--  统一的防御图标设置逻辑，供伤害输出和受伤框架共用
local function SetupDefenceIcon(slot, parentFrame, spellId, defenceStatus, useDefenceTable, guidPlayer)
    if not slot or not slot.Textures or not slot.Textures[2] then
        return
    end
    
    -- 获取UV坐标
    local uv
    if useDefenceTable then
        -- 使用 DEFENCE 表（SPELL_MISSED事件）
        uv = DefenceStatusUVs.SPELL_MISS[defenceStatus]
    else
        -- 使用 DEFENCE_T 表（AUTO_ATTACK事件）
        uv = DefenceStatusUVs.VICTIMSTATE[defenceStatus]
    end
    
    if not uv then
        return
    end
    
    -- 先应用技能图标（如果有），并获取是否显示图标的结果
    local shouldShowIcon = ApplySpellIcon(
        slot.Textures[1],
        parentFrame,
        spellId,
        guidPlayer,  --   传入GUID_P，区分玩家/宠物
        0,
        true,  -- 防御状态
        0      -- iconOffsetX
    )
    
    -- 设置防御图标
    --  完全重置Textures[2]，清除旧状态避免纹理缓存问题
    slot.Textures[2]:ClearAllPoints()
    slot.Textures[2]:SetTexture(nil)  -- 清除旧纹理
    slot.Textures[2]:Hide()  -- 先隐藏
    
    -- 设置新的纹理和UV
    slot.Textures[2]:SetTexture(COMBAT_STATUS_TEXTURE)
    slot.Textures[2]:SetTexCoord(uv[1], uv[2], uv[3], uv[4])
    
    local iconWidth = iconW
    local actualStatusWidth = 128
    local defenceIconSpacing = 0  --  减少技能图标和防御图标之间的间距
    local statusCenterX
    
    --  防御图标采用左对齐，与数字对齐方式保持一致
    -- 无论是否有技能图标显示，都为技能图标预留空间以保证队列对齐
    -- 技能图标中心在父框架中心(iconOffsetX=0)，所以技能图标右边缘在 iconWidth/2 处
    if shouldShowIcon then
        -- 有技能图标时：防御图标左边缘 = 技能图标右边缘 + 间距
        -- 技能图标右边缘 = iconWidth/2
        -- 防御图标中心 = 防御图标左边缘 + 间距 + actualStatusWidth/2
        statusCenterX = iconWidth/2 + defenceIconSpacing + actualStatusWidth/2
    else
        -- 无技能图标时：仍然为技能图标预留空间，防御图标位于预留位置之后
        -- 防御图标中心 = 预留的技能图标右边缘 + 间距 + 防御图标半宽
        statusCenterX = iconWidth/2 + defenceIconSpacing + actualStatusWidth/2
    end
    
    slot.Textures[2]:SetPoint("CENTER", parentFrame, "CENTER", statusCenterX, 0)
    slot.Textures[2]:SetWidth(actualStatusWidth)
    slot.Textures[2]:SetHeight(64)
    slot.Textures[2]:SetVertexColor(1.0, 1.0, 1.0)
    slot.Textures[2]:Show()
    
    slot.useCombatStatusIcon = true
end

-- ======================== 槽位创建工厂函数 ================================
local function CreateDamageSlot(index, parentFrame)
    local key = index  --  使用数字索引而非字符串key
    local frameOutside = CreateFrame("Frame", "PT_Damage_Outside_"..index, parentFrame)
    frameOutside:SetWidth(1)
    frameOutside:SetHeight(1)
    frameOutside:SetAlpha(1)
    frameOutside:SetFrameStrata("MEDIUM")
    frameOutside:Hide()
    
    local f = CreateFrame("Frame", "PT_Damage_"..index, frameOutside)
    f:SetWidth(24)
    f:SetHeight(24)
    f:SetPoint("CENTER", frameOutside, "CENTER", 0, 0)
    f:SetBackdrop(nil)
    
    --  初始化Frame的Scale，避免使用默认值1.0导致数字过大
    local baseFontSize = UserSettings.baseFontSize or 42
    local scale = GetSafeScale((baseFontSize / 100) * 1.0)
    f:SetScale(scale)
    
    local texs = CreateNumberTextures(f)
    
    local slotData = {
        key          = key,
        Frame        = f,
        FrameOutside = frameOutside,
        Textures     = texs,
        isCrit       = 0,
        startTime    = 0,
        isActive     = 0,
        GUID         = nil,
        animType     = 0,  -- 0=普通动画, 1=抛物线动画
        amount       = nil,
        texCount     = MAX_DIGITS + 1,  --  统一初始化texCount
        normal = { 
            alpha=1, 
            speed=SystemParams.NORMAL_MOVE_SPEED + math_random(-5,5), 
            offsetY=0, 
            randomX=0, 
            randomY=0, 
            sizeScale=1 
        },
        crit = { scale=1, alpha=1, randomX=0, randomY=0 },
        parabola = { direction=1, maxWidth=0, maxHeight=0 }
    }
    
    SetDamageSlotCache(slotData)
    return slotData
end

-- 根据配置动态调整伤害动画槽位数量
function addon:ResizeDamagePool(newSize)
    if not newSize or newSize <= 0 then return end
    
    local currentSize = 0
    for _ in pairs(aniData) do
        currentSize = currentSize + 1
    end
    
    -- 如果大小相同，无需调整
    if currentSize == newSize then
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 伤害动画槽位已是 " .. newSize .. " 个，无需调整", 0, 1, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string_format("[PlayTurtle] 调整伤害动画槽位：%d -> %d", currentSize, newSize), 1, 1, 0)
    
    -- 如果新大小更大，需要创建新槽位
    if newSize > currentSize then
        local i = currentSize + 1
        while i <= newSize do
            local parentFrame = getglobal(SystemParams.FIXED_PARENT_FRAME) or UIParent
            aniData[i] = CreateDamageSlot(i, parentFrame)  --  使用数字索引
            i = i + 1
        end
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 伤害动画槽位已扩展到 " .. newSize .. " 个", 0, 1, 0)
    else
        -- 如果新大小更小，需要移除多余槽位（先停用再删除）
        local i = currentSize
        while i > newSize do
            local slot = aniData[i]  --  使用数字索引
            if slot then
                -- 如果槽位正在使用，先重置
                if slot.isActive == 1 then
                    ResetSlot(slot)
                end
                -- 销毁框架
                if slot.Frame then
                    slot.Frame:SetParent(nil)
                    slot.Frame = nil
                end
                if slot.FrameOutside then
                    slot.FrameOutside:SetParent(nil)
                    slot.FrameOutside = nil
                end
                -- 从表中移除
                aniData[i] = nil 
            end
            i = i - 1
        end
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 伤害动画槽位已缩小到 " .. newSize .. " 个", 0, 1, 0)
    end
end

-- 根据配置动态调整受伤/治疗动画槽位数量
function addon:ResizeReceivedPool(newSize)
    if not newSize or newSize <= 0 then return end
    
    --  ReceivedAnimationPool是固定大小数组，直接使用MAX_RECEIVED_SLOTS
    local currentSize = SystemParams.MAX_RECEIVED_SLOTS or 30
    
    -- 如果大小相同，无需调整
    if currentSize == newSize then
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 受伤/治疗槽位已是 " .. newSize .. " 个，无需调整", 0, 1, 0)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage(string_format("[PlayTurtle] 调整受伤/治疗槽位：%d -> %d", currentSize, newSize), 1, 1, 0)
    
    -- 如果新大小更大，需要扩展槽位池
    if newSize > currentSize then
        -- 只需预分配索引，实际 Frame 会在 GetReceivedSlot 中按需创建
        for i = currentSize + 1, newSize do
            ReceivedAnimationPool[i] = nil  -- 标记为可用，等待按需创建
        end
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 受伤/治疗槽位池已扩展到 " .. newSize .. " 个（按需创建）", 0, 1, 0)
    else
        -- 如果新大小更小，需要移除多余槽位（先停用再删除）
        for i = currentSize, newSize + 1, -1 do
            local slot = ReceivedAnimationPool[i]
            if slot then
                -- 如果槽位正在使用，先重置
                if slot.active == 1 then
                    ResetReceivedSlot(slot)
                end
                -- 销毁框架
                if slot.frame then
                    slot.frame:SetParent(nil)
                    slot.frame = nil
                end
                if slot.frameOutside then
                    slot.frameOutside:SetParent(nil)
                    slot.frameOutside = nil
                end
                -- 从表中移除
                ReceivedAnimationPool[i] = nil
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("[PlayTurtle] 受伤/治疗槽位池已缩小到 " .. newSize .. " 个", 0, 1, 0)
    end
end

function addon:InitAniPool()
    --  动态读取配置的槽位数量，并使用数字索引
    local maxSlots = SystemParams.MAX_ANI_SLOTS or 30
    
    -- 根据队列模式状态决定父级
    local isInQueueMode = addon.DOTFrame and addon.db and addon.db.dotQueueEnabled == 1
    local parentFrame = isInQueueMode and addon.DOTFrame or UIParent
    
    local i = 1
    while i <= maxSlots do
        aniData[i] = CreateDamageSlot(i, parentFrame)  --  使用数字索引而非字符串key
        i = i + 1
    end
    isInitialized = 1
end

-- 队列模式开关切换时统一重置所有动画槽位的父级
function addon:ResetAniPoolParent()
    if not aniData then return end
    
    -- 根据队列模式状态决定父级
    local isInQueueMode = addon.DOTFrame and addon.db and addon.db.dotQueueEnabled == 1
    local newParent = isInQueueMode and addon.DOTFrame or UIParent
    
    -- 遍历所有动画槽位，统一设置父级
    for i = 1, table.getn(aniData) do
        local slot = aniData[i]
        if slot and slot.FrameOutside then
            slot.FrameOutside:SetParent(newParent)
        end
    end
    
    -- AOE合并功能跟随队列模式开关状态
    if addon.aoeCounterFrame then
        addon.aoeCounterFrame:SetParent(newParent)
        
        -- 重新设置AOE计数器的位置和FrameLevel
        addon.aoeCounterFrame:ClearAllPoints()
        local offsetX = PTURTLE_Combat_DB and PTURTLE_Combat_DB.aoeCounterOffsetX or 0
        local defaultOffsetY = -(newParent.GetHeight and newParent:GetHeight() / 2 + 10 or 30)
        local offsetY = PTURTLE_Combat_DB and PTURTLE_Combat_DB.aoeCounterOffsetY or defaultOffsetY
        addon.aoeCounterFrame:SetPoint("CENTER", newParent, "CENTER", offsetX, offsetY)
        addon.aoeCounterFrame:SetFrameLevel((newParent.GetFrameLevel and newParent:GetFrameLevel() or 0) + 10)
    end
end

ResetSlot = function(slot)
    -- 如果槽位未激活，跳过列表移除操作
    if slot.isActive == 1 then
        -- GUID缓存优化：从GUID缓存中移除
        if slot.GUID and guidActiveCache[slot.GUID] then
            local cache = guidActiveCache[slot.GUID]
            local count = guidActiveCount[slot.GUID] or 0
            for i = 1, count do
                if cache[i] == slot then
                    -- 用最后一个元素覆盖当前元素（O(1)移除）
                    cache[i] = cache[count]
                    cache[count] = nil
                    guidActiveCount[slot.GUID] = count - 1
                    
                    -- 如果缓存为空，清理表
                    if count - 1 == 0 then
                        guidActiveCache[slot.GUID] = nil
                        guidActiveCount[slot.GUID] = nil
                    end
                    break
                end
            end
        end
        
        -- - 减少暴击计数（在回收槽位时更新）
        if slot.isCrit == 1 then
            if slot.GUID and slot.GUID ~= "" then
                guidCritCount[slot.GUID] = math_max(0, (guidCritCount[slot.GUID] or 1) - 1)
                
                -- 如果这是该GUID的最后一个暴击，完全清除Y偏移量
                if guidCritCount[slot.GUID] == 0 then
                    guidCritYOffset[slot.GUID] = 0
                else
                    -- 使用缓存的推开距离，避免重复计算
                    local pushDistance = GetCachedCritPushDistance()
                    -- 减少该GUID的Y偏移量缓存
                    guidCritYOffset[slot.GUID] = math_max(0, (guidCritYOffset[slot.GUID] or 0) - pushDistance)
                end
            elseif slot.useFixedPos then
                fixedPosCritCount = math_max(0, fixedPosCritCount - 1)
            end
        end
        
        --  从 activeSlots 中移除（通过清理逻辑统一处理）
        slot.isActive = 0  -- 标记为非活跃，由后续清理逻辑移除
        
        -- 清理数组中所有isActive=0的槽位
        local newCount = 0
        for i = 1, activeSlotCount do
            if activeSlots[i] and activeSlots[i].isActive == 1 then
                newCount = newCount + 1
                if newCount ~= i then
                    activeSlots[newCount] = activeSlots[i]
                    activeSlots[i] = nil
                end
            else
                activeSlots[i] = nil
            end
        end
        activeSlotCount = newCount
        
        --  如果槽位是受伤/受疗/输出治疗，从对应的活跃列表中移除
        if slot.animType == 1 then
            -- 受伤队列
            for i = 1, activeDamageCount do
                if activeDamageSlots[i] == slot then
                    activeDamageSlots[i] = activeDamageSlots[activeDamageCount]
                    activeDamageSlots[activeDamageCount] = nil
                    activeDamageCount = activeDamageCount - 1
                    break
                end
            end
        elseif slot.animType == 2 then
            -- 受疗队列
            for i = 1, activeHealCount do
                if activeHealSlots[i] == slot then
                    activeHealSlots[i] = activeHealSlots[activeHealCount]
                    activeHealSlots[activeHealCount] = nil
                    activeHealCount = activeHealCount - 1
                    break
                end
            end
        elseif slot.animType == 3 then
            -- 输出治疗队列
            for i = 1, activeOutHealCount do
                if activeOutHealSlots[i] == slot then
                    activeOutHealSlots[i] = activeOutHealSlots[activeOutHealCount]
                    activeOutHealSlots[activeOutHealCount] = nil
                    activeOutHealCount = activeOutHealCount - 1
                    break
                end
            end
        end
    end
    
    -- 条件化 WoW API 调用，避免不必要的操作
    if slot.FrameOutside then
        slot.FrameOutside:ClearAllPoints()
        slot.FrameOutside:Hide()
    end
    
    if slot.Frame then
        slot.Frame:SetScale(1)
        slot.Frame:SetAlpha(1)
        --  使用队列字符大小计算缩放
        local baseFontSize = UserSettings.queueFontSize or 40
        local scale = GetSafeScale((baseFontSize / 100) * 1.0)
        slot.Frame:SetScale(scale)
    end
    
    -- 隐藏所有纹理
    HideTextures(slot.Textures)
    
    --  重置时更新所有数字纹理到最新字体样式
    local texCount = slot.texCount or (MAX_DIGITS + 1)
    for i = 2, texCount do
        local tex = slot.Textures[i]
        if tex then
            tex:SetTexture(cachedTexturePath or "Interface\\AddOns\\PlayTurtle\\img\\num1.blp")
        end
    end
    
    --  重置Textures[1]（技能图标），清除旧状态
    if slot.Textures and slot.Textures[1] then
        slot.Textures[1]:ClearAllPoints()
        slot.Textures[1]:SetTexture(nil)  -- 清除旧纹理
        slot.Textures[1]:Hide()
    end
    
    --  无条件重置Textures[2]为数字纹理，避免复用残留
    if slot.Textures and slot.Textures[2] then
        slot.Textures[2]:ClearAllPoints()
        slot.Textures[2]:SetTexture(cachedTexturePath or "Interface\\AddOns\\PlayTurtle\\img\\num1.blp")
        slot.Textures[2]:SetTexCoord(0, 1, 0, 1)  --  重置UV坐标为完整纹理
        slot.Textures[2]:SetWidth(digitW)  -- 重置为数字纹理默认宽度
        slot.Textures[2]:SetHeight(digitH)  -- 重置为数字纹理默认高度
        slot.Textures[2]:Hide()
    end
    slot.GUID = nil
    slot.GUID_P = nil
    slot.isCrit = 0
    slot.startTime = 0
    slot.time = 0  --  同时重置time字段，避免跨池复用时的状态污染
    slot.isActive = 0
    slot.animMode = nil  --   清除动画模式标记
    -- 使用通用配置缓存函数
    SetDamageSlotCache(slot)
    slot.hasPlate = false
    slot.useFixedPos = false  --  重置固定位置标志，避免复用时的状态污染
    slot.isFrozen = false     --  重置冻结标志，避免复用时的状态污染
    slot.animType = 0
    slot.amount = nil
    slot.isAOEDamage = nil  -- 清除AOE标记，避免复用时的状态污染
    slot.isPendingDOT = false  -- 清除待释放队列模式标记，避免被GetBestSlot跳过
    slot.dotBaseY = nil     -- 清除队列模式基准Y
    slot.dotTimeOffset = 0  --  重置时间偏移为0
    slot._dotFixedDuration = nil  --  清除固定的duration
    slot.dotAmount = nil    -- 清除队列模式数据
    slot.dotIsCrit = nil
    slot.dotSpellId = nil
    slot.dotSchool = nil
    slot._dotCachedP1x = nil  -- 清除DOT控制点X缓存
    slot._dotCachedP1y = nil  -- 清除DOT控制点Y缓存
    slot.texCount = MAX_DIGITS + 1  --  重置texCount为默认值
    slot.normal.randomX = 0
    slot.normal.randomY = 0
    slot.normal.sizeScale = 1
    slot.parabola = {}  -- 初始化抛物线表，避免 B/C 模式使用时 nil 错误
    slot.normalTimeOffset = nil  --  清除动画A时间偏移
    slot.lifetime = nil     --  清除存活时间
    slot.crit.randomX = 0
    slot.crit.randomY = 0
    slot.spellId = nil
    
    --  清除防御状态相关字段，避免复用时的状态污染
    slot.defenceStatus = nil
    slot.useDefenceTable = false
    slot.useCombatStatusIcon = false
end

local function GetBestSlot(isCrit, guid, useFixedPos)
    local maxSlots = MAX_ANI_SLOTS
    
    -- - 优化1: 使用轮询策略查找空闲槽位（空闲槽位已在回收时清理干净）
    for i = 1, maxSlots do
        lastDamageSlotIndex = math_mod(lastDamageSlotIndex, maxSlots) + 1
        local slot = aniData[lastDamageSlotIndex]
        
        if slot.isActive == 0 and not slot.isPendingDOT and not slot.isPendingNormal then
            return slot  --   空闲槽位直接返回，无需重置
        end
    end
    
    --   核心修复：如果没有空闲槽位，检查是否有槽位在normalPendingList中但isActive==1
    for i = 1, normalPendingCount do
        local pendingSlot = normalPendingList[i]
        if pendingSlot and pendingSlot.isActive == 1 then
            -- 槽位在队列中但被激活了，这是状态不一致，需要修复
            pendingSlot.isActive = 0
            pendingSlot.isPendingNormal = true
        end
    end
    
    
    -- - 优化3: 回收最早的任何槽位
    local oldestSlot
    local oldestTime = 999999
    for i = 1, maxSlots do
        local slot = aniData[i]
        if slot.isActive == 1 and slot.startTime and slot.startTime < oldestTime then
            oldestTime = slot.startTime
            oldestSlot = slot
        end
    end
    
    if oldestSlot then
        ResetSlot(oldestSlot)  --   统一在 GetBestSlot 内重置，保证返回干净槽位
        return oldestSlot
    end
    
    return nil
end

-- ======================== 槽位位置更新 ================================
local function UpdateSlotPosition(frameOutside, slot, plate, plateValid, useFixedPos, rx, ry)
    if useFixedPos then
        -- 使用统一的固定位置指示器
        if addon.fixedPosIndicator then
            frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", rx, ry)
        end
    elseif plateValid then
        frameOutside:SetPoint("CENTER", plate, "CENTER", rx, ry)
    elseif not slot.hasPlate then
        -- 如果槽位从未绑定过姓名板（如预览模式），使用固定位置指示器
        if addon.fixedPosIndicator then
            frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", rx, ry)
        end
    end
end

-- ======================== 暴击动画更新 ================================
local function UpdateCritAnimation(slot, f, frameOutside, plate, plateValid, passed)
    -- 暴击基于动画时长回收（放大+保持+缩小）
    local critDuration = (slot.cachedCritScaleUp or 0.15) + (slot.cachedCritHoldTime or 0.3) + (slot.cachedCritScaleDown or 0.15)
    if passed > critDuration then
        ResetSlot(slot)
        return
    end
    
    local maxScale = slot.cachedCritScaleStart or 12.0
    local finalScale = slot.cachedCritScaleEnd or 6.0
    local up = slot.cachedCritScaleUp or 0.15
    local down = slot.cachedCritScaleDown or 0.15
    local baseScaleFactor = 0.3
    local t = 0
    
    if passed <= up then
        t = passed / up
        local scale = (1 + (maxScale - 1) * t) * baseScaleFactor
        if scale < 0.01 then scale = 0.01 end
        f:SetScale(scale)
    elseif passed <= up + down then
        t = (passed - up) / down
        local scale = (maxScale - (maxScale - finalScale) * t) * baseScaleFactor
        if scale < 0.01 then scale = 0.01 end
        f:SetScale(scale)
    else
        local scale = finalScale * baseScaleFactor
        if scale < 0.01 then scale = 0.01 end
        f:SetScale(scale)
    end
    f:SetAlpha(1)
    
    --  暴击数字抖动效果
    local finalX = slot.crit.randomX or 0
    local finalY = slot.crit.randomY or 0
    

    
    if slot.cachedCritNumberShakeEnabled == 1 then
        local shakeIntensity = slot.cachedCritShakeIntensity
        
        local shakeFrequency = slot.cachedCritShakeFrequency
        -- 使用查表代替 sin/cos，避免每帧计算
        local shakeAngleX = math_mod((passed * shakeFrequency * 360), 360)
        local shakeAngleY = math_mod((passed * shakeFrequency * 480), 360)  -- 不同频率
        local shakeX = (GetShakeSin(shakeAngleX) or 0) * shakeIntensity
        local shakeY = (GetShakeSin(shakeAngleY) or 0) * shakeIntensity
        finalX = finalX + shakeX
        finalY = finalY + shakeY
    end
    -- 队列模式暴击使用队列框架为锚点
    if addon.DOTFrame and addon.db and addon.db.dotQueueEnabled == 1 and slot.isCrit == 1 then
        --   宠物队列X轴偏移：如果是宠物伤害，应用X轴偏移
        local petOffsetX = slot.cachedPetQueueXOffset
        
        -- 队列模式暴击：使用队列框架左下角为锚点
        local baseX = finalX - 20 + petOffsetX
        local baseY = finalY
        
        -- 清除旧锚点，确保 SetPoint 生效
        frameOutside:ClearAllPoints()
        frameOutside:SetPoint("BOTTOMLEFT", addon.DOTFrame, "BOTTOMLEFT", baseX, baseY)
    else
        --   动画A暴击：应用宠物队列X轴偏移
        local petOffsetX = slot.cachedPetQueueXOffset
        
        if slot.useFixedPos then
            -- 使用统一的固定位置指示器
            if addon.fixedPosIndicator then
                frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", finalX - 20 + petOffsetX, finalY)
            end
        elseif plateValid then
            -- 姓名板有效：绑定到姓名板
            frameOutside:SetPoint("CENTER", plate, "CENTER", finalX - 20 + petOffsetX, finalY)
        elseif not slot.hasPlate then
            -- 槽位从未绑定过姓名板：使用固定位置指示器
            if addon.fixedPosIndicator then
                frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", finalX - 20 + petOffsetX, finalY)
            end
        else
            -- 核心修复：队列模式下暴击伤害以队列框架为锚点（hasPlate=true但plate=nil）
            if addon.DOTFrame then
                frameOutside:SetPoint("CENTER", addon.DOTFrame, "CENTER", finalX - 20 + petOffsetX, finalY)
            end
        end
    end
end

-- ======================== 普通动画更新 ================================
local function UpdateNormalAnimation(slot, f, frameOutside, plate, plateValid, useFixedPos, passed)
    --  基于存活时间的回收机制
    if slot.lifetime and passed > slot.lifetime then
        ResetSlot(slot)
        return
    end
    
    -- 速度（使用缓存值，避免每帧读取 UserSettings）
    local speed = slot.cachedMoveSpeed or 120
    
    --  使用有效时间计算进度（加入时间偏移，与其他队列统一）
    local effectivePassed = passed + (slot.normalTimeOffset or 0)
    
    -- 已走距离 = 速度 * 有效时间
    local traveled = speed * effectivePassed
    
    --  淡出配置（使用缓存的滑块值，避免每帧读取 UserSettings）
    local sliderValue = (slot.cachedFadeDur or 2.2) * 10
    local fadeStartPercent = 0.7 - (sliderValue - 18) / 12 * 0.4
    
    -- 淡出基于原始passed时间，不受推开影响
    local lifetime = slot.lifetime or 3.0  -- 默认3秒，防止nil错误
    local fadeProgressTime = passed / lifetime  -- 基于真实存在时间的进度
    
    local alpha = 1
    -- 淡出进度基于passed时间（不包含推开偏移）
    if fadeProgressTime >= fadeStartPercent then
        local fadeTimeProgress = (fadeProgressTime - fadeStartPercent) / (1 - fadeStartPercent)
        alpha = 1 - fadeTimeProgress
        if alpha < 0 then alpha = 0 end
        if alpha > 1 then alpha = 1 end
    end
    frameOutside:SetAlpha(alpha)
    
    -- ======================== 缩放 ========================
    local baseFontSize = slot.cachedBaseFontSize or 42
    local sizeScale = slot.normal.sizeScale or 1
    local scale = (baseFontSize / 100) * sizeScale
    if scale < 0.01 then scale = 0.01 end
    f:SetScale(scale)
    
    -- ======================== 更新位置（支持推开） ========================
    -- 根据useFixedPos决定如何更新位置
    
    if useFixedPos then
        -- 固定位置模式：保持原有锚点
        local totalX = 0  -- X坐标保持为0
        local totalY = traveled  -- Y坐标直接使用traveled（已包含normalTimeOffset）
        
        --   宠物队列X轴偏移：如果是宠物伤害，应用X轴偏移
        local petOffsetX = 0
        if slot.GUID_P == addon.GUID_Pet then
            petOffsetX = UserSettings.petQueueXOffset or 0
        end
        
        -- 使用统一的固定位置指示器
        if addon.fixedPosIndicator then
            frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", totalX - 20 + petOffsetX, totalY)
        end
    else
        -- 非固定位置模式：使用原有的姓名板锚点逻辑
        --   宠物队列X轴偏移：如果是宠物伤害，应用X轴偏移
        local petOffsetX = 0
        if slot.GUID_P == addon.GUID_Pet then
            petOffsetX = UserSettings.petQueueXOffset or 0
        end
        
        if plateValid then
            frameOutside:SetPoint("CENTER", plate, "CENTER", -20 + petOffsetX, traveled)
        elseif not slot.hasPlate then
            -- 槽位从未绑定过姓名板：使用固定位置指示器
            if addon.fixedPosIndicator then
                frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", -20 + petOffsetX, traveled)
            end
        end
    end
end

-- ======================== 抛物线动画更新 ================================
local function UpdateParabolaAnimation(slot, f, frameOutside, plate, plateValid, passed)
    --  使用 cachedMoveSpeed 控制抛物线速度
    local baseDuration = slot.parabola.duration or (SystemParams.PARABOLA_DURATION or 1.5)
    --  使用槽位缓存的速度配置（normalMoveRandom）
    local moveSpeed = slot.cachedMoveSpeed or 120
    
    -- C模式特殊处理：不受moveSpeed影响，使用完整duration
    local duration
    if slot.parabola and slot.parabola.returnToOrigin then
        -- C模式：直接使用baseDuration
        duration = baseDuration
    else
        -- B模式：根据滑块2的值调整动画时长
        -- 默认100时保持原时长，50时时长翻倍（慢），150时时长减半（快）
        duration = baseDuration * (100 / moveSpeed)
    end
    
    local progress = passed / duration
    if progress > 1 then progress = 1 end
    
    -- 计算抛物线轨迹（使用预计算查找表优化性能）
    local direction = slot.parabola.direction or 1
    local maxWidth = slot.parabola.maxWidth or 100
    local maxHeight = slot.parabola.maxHeight or 150
    
    --  使用缓存的控制点（避免每帧读取 UserSettings）
    local controlPointX = slot.parabola.controlPointX or 0.5
    local controlPointY = slot.parabola.controlPointY or 1.0
    
    -- 实时计算贝塞尔曲线系数（根据控制点动态调整）
    local u = 1 - progress
    local xCoeff, yCoeff
    
    --  C模式使用特殊的贝塞尔曲线，终点回到(0,0)
    if slot.parabola and slot.parabola.returnToOrigin then
        -- C模式：P0=(0,0), P1=(controlPointX*direction, controlPointY), P2=(0,0)
        -- 这样曲线会拱出去再回来
        xCoeff = 2*u*progress*controlPointX * direction  -- X方向会回到0
        yCoeff = 2*u*progress*controlPointY              -- Y方向也会回到0
    else
        -- B模式：P0=(0,0), P1=(controlPointX*direction, controlPointY), P2=(1,0)
        -- 这样曲线会拱起来后落回y=0，但x保持在终点位置
        xCoeff = 2*u*progress*controlPointX + progress*progress*1
        yCoeff = 2*u*progress*controlPointY
    end
    
    -- 应用系数和方向（B模式需要direction，C模式已经在xCoeff中处理）
    local x, y
    if slot.parabola and slot.parabola.returnToOrigin then
        -- C模式：direction已经包含在xCoeff中
        x = xCoeff * maxWidth
        y = yCoeff * maxHeight
    else
        -- B模式：需要应用direction
        x = xCoeff * maxWidth * direction
        y = yCoeff * maxHeight
    end
    
    --  锚点偏移处理
    local anchorX = slot.cachedAnchorX or 0
    
    -- X坐标：全程应用anchorX偏移
    x = x + anchorX
    
    -- Y坐标：B/C模式抛物线动画从Y=0开始
    
    -- 回退机制：与回头是岸模式保持一致
    if slot.useFixedPos then
        -- 使用统一的固定位置指示器
        if addon.fixedPosIndicator then
            frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", x - 20, y)
        end
    elseif plateValid then
        -- 姓名板有效：绑定到姓名板
        frameOutside:SetPoint("CENTER", plate, "CENTER", x - 20, y)
    elseif not slot.hasPlate then
        -- 槽位从未绑定过姓名板：使用固定位置指示器
        if addon.fixedPosIndicator then
            frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", x - 20, y)
        end
    end

    --  Alpha 淡出 - 使用滑块控制淡出起始点
    local sliderValue = (UserSettings.normalFadeDuration or 2.2) * 10  -- 转换为滑块原始值 18-30
    -- 映射：sliderValue 18 -> 70% (早淡出), 24 -> 50%, 30 -> 30% (晚淡出)
    local fadeStartPercent = 0.7 - (sliderValue - 18) / 12 * 0.4
    
    local alpha = 1
    
    -- 计算当前行程百分比
    local travelProgress = passed / duration
    
    -- 基于行程百分比判断是否开始淡出
    if travelProgress >= fadeStartPercent then
        -- 淡出进度 = (当前进度 - 淡出起点) / (1 - 淡出起点)
        -- 这样确保在生命周期结束时完全淡出（alpha=0）
        local fadeProgress = (travelProgress - fadeStartPercent) / (1 - fadeStartPercent)
        alpha = 1 - fadeProgress
        if alpha < 0 then alpha = 0 end
        if alpha > 1 then alpha = 1 end
    end
    f:SetAlpha(alpha)
    
    -- 缩放效果：在60%行程时开始缩小，剩余40%行程内平滑缩小到30像素
    local baseFontSize = slot.cachedBaseFontSize or 42
    local scaleMultiplier = 1.0
    
    if travelProgress < 0.6 then
        -- 第一段（0-60%）：保持正常大小
        scaleMultiplier = 1.0
    else
        -- 第二段（60%-100%）：平滑缩小到30像素
        local phaseProgress = (travelProgress - 0.6) / 0.4  -- 归一化到0-1
        local targetScale = 30 / baseFontSize  -- 目标缩放比例（约0.714）
        scaleMultiplier = 1.0 - phaseProgress * (1.0 - targetScale)
    end
    
    --  确保缩放值始终>0
    local finalScale = (baseFontSize / 100) * scaleMultiplier
    if finalScale <= 0 then
        finalScale = 0.01  -- 最小缩放值
    end
    f:SetScale(finalScale)
    
    --  C模式在到达终点后，继续显示0.2秒再重置
    if slot.parabola and slot.parabola.returnToOrigin then
        -- C模式：当progress>=1.2时（即超过duration的20%），才重置槽位
        if progress >= 1.2 then
            ResetSlot(slot)
        end
    else
        -- B模式和其他：当progress>=1时立即重置
        if progress >= 1.0 then
            ResetSlot(slot)
        end
    end
end

-- ======================== 主动画更新函数 ================================
local AnimationModeHandlers = {
    [0] = function(slot, f, frameOutside, plate, plateValid, useFixedPos, passed)
        -- A模式：普通向上淡出
        --  如果失去载体（姓名板）且未开启固定位置，直接回收避免闪现
        --  预览模式下不回收，允许数字继续显示
        if not plateValid and not useFixedPos and slot.GUID and not addon.textPanelPreviewMode then
            ResetSlot(slot)
            return
        end
        UpdateNormalAnimation(slot, f, frameOutside, plate, plateValid, useFixedPos, passed)
    end,
    [1] = function(slot, f, frameOutside, plate, plateValid, useFixedPos, passed)
        -- B模式：抛物线动画
        --  如果失去载体，直接回收
        if not plateValid and not slot.useFixedPos and slot.GUID then
            ResetSlot(slot)
            return
        end
        UpdateParabolaAnimation(slot, f, frameOutside, plate, plateValid, passed)
    end,
    [2] = function(slot, f, frameOutside, plate, plateValid, useFixedPos, passed)
        -- C模式：回力动画
        --  如果失去载体，直接回收
        if not plateValid and not slot.useFixedPos and slot.GUID then
            ResetSlot(slot)
            return
        end
        UpdateParabolaAnimation(slot, f, frameOutside, plate, plateValid, passed)
    end,
}

local function UpdateAnimation(slot, now, elapsed)
    local f = slot.Frame
    local frameOutside = slot.FrameOutside
    if not f or not frameOutside or slot.isActive == 0 then
        return
    end

    
    local passed = now - slot.startTime
    
    --  队列模式（D模式）特殊动画逻辑
    -- 队列模式只包括非暴击队列，暴击走独立的UpdateCritAnimation
    local isQueueMode = (slot.animMode == "queue") and (slot.isCrit == 0)
    
    if isQueueMode then
        
        -- DOT 动画：匀速二次贝塞尔曲线（使用控制手柄作为控制点）
        -- 使用预计算的cachedDotMoveSpeed，避免每帧重复计算
        local dotMoveSpeed = slot.cachedDotMoveSpeed or 100  -- 使用缓存值
        
        --  使用缓存的框架宽高，避免每帧调用API（与受伤/受疗/输出治疗框架一致）
        local frameWidth = cachedFrameWidth["dot"] or (addon.DOTFrame and addon.DOTFrame:GetWidth() or 200)
        local frameHeight = cachedFrameHeight["dot"] or (addon.DOTFrame and addon.DOTFrame:GetHeight() or 216)
        
        --  起点固定在左下角，终点固定在右上角
        local actualStartX = 20  -- 起点X：左下角（距离左边20像素）
        local actualStartY = slot.dotBaseY or 20  --  使用dotBaseY作为起点Y，支持推开逻辑
        local topEndX = frameWidth - 20  -- 终点X：右上角（距离右边20像素）
        local topEndY = frameHeight - 32  -- 终点Y：顶部（距离顶部32像素）
        
        --  计算总距离（可正可负，表示运动方向）
        local totalDistanceX = topEndX - actualStartX  -- X轴总行程距离
        local totalDistanceY = topEndY - actualStartY  -- Y轴总行程距离
        
        --  基于Y轴距离计算淡出起点
        local actualTotalDistance = math_abs(totalDistanceY)  -- 实际可运动距离（取绝对值用于淡出计算）
        local fadeStartDistance = actualTotalDistance * 0.8  -- 淡出起始距离（80%）
        
        -- 第一次 Update 时显示
        if not frameOutside:IsShown() then
            frameOutside:Show()
        end
        
        --  获取控制手柄坐标作为贝塞尔曲线控制点
        local handle = addon.ReceivedUI and addon.ReceivedUI.handleDOT
        
        --  智能缓存策略：控制点可见时实时获取，隐藏时使用缓存
        local p1x = dotControlPointCache.p1x
        local p1y = dotControlPointCache.p1y
        local needUpdateCache = false
        
        if handle then
            -- 检查控制点是否可见（IsShown表示编辑模式）
            if handle:IsShown() then
                -- 编辑模式：实时获取控制点位置
                needUpdateCache = true
            elseif not p1x or not p1y then
                -- 战斗模式但缓存不存在：需要初始化缓存
                needUpdateCache = true
            end
            -- 否则使用缓存的控制点
        end
        
        if needUpdateCache and handle then
            --  使用相对坐标计算，支持框架反转
            local handleCenterX = handle:GetWidth() / 2
            local handleCenterY = handle:GetHeight() / 2
            
            -- 手柄相对于父框架的偏移量
            local offsetX = handle:GetLeft() - addon.DOTFrame:GetLeft()
            local offsetY = handle:GetBottom() - addon.DOTFrame:GetBottom()
            
            -- 转换为相对于起点的坐标
            p1x = offsetX + handleCenterX - actualStartX
            p1y = offsetY + handleCenterY - actualStartY
            
            -- 更新全局缓存（框架级别）
            dotControlPointCache.p1x = p1x
            dotControlPointCache.p1y = p1y
        elseif not p1x or not p1y then
            -- 没有手柄或缓存失效，使用默认值
            p1x = totalDistanceX / 2
            p1y = totalDistanceY / 2
        end
        
        --  基于Y轴距离计算进度，保持与原来相同的垂直速度
        -- 这样无论控制点在哪里，DOT数字在Y轴方向的移动速度都保持一致
        
        --  所有DOT使用标准duration，不受推开影响
        local duration = slot._dotFixedDuration
        if not duration then
            -- 使用标准总行程计算duration（不受推开影响）
            local standardTotalDistanceY = (frameHeight - 32) - 20  -- 终点Y - 起点Y
            duration = math_abs(standardTotalDistanceY) / dotMoveSpeed
            slot._dotFixedDuration = duration  -- 固定duration
        end
        
        --  使用有效时间计算进度（加入时间偏移）
        local effectivePassed = passed + (slot.dotTimeOffset or 0)  -- 核心！
        local progress = effectivePassed / duration
        if progress > 1 then progress = 1 end
        
        -- 二次贝塞尔曲线公式：B(t) = (1-t)^2 * P0 + 2*(1-t)*t * P1 + t^2 * P2
        -- P0=(0, 0), P1=(p1x, p1y), P2=(totalDistanceX, totalDistanceY)
        local u = 1 - progress
        local curveX = 2 * u * progress * p1x + progress * progress * totalDistanceX  -- X坐标（相对于起点）
        local curveY = 2 * u * progress * p1y + progress * progress * totalDistanceY  -- Y坐标（相对于起点）
        
        -- 应用位置（使用贝塞尔曲线计算的位置）
        --  DOT暴击也应用震动效果（使用独立的队列暴击震动开关）
        local finalCurveX = curveX
        local finalCurveY = curveY
        
        --   ✅ 修复：只有宠物造成的伤害才应用宠物偏移
        local petOffsetX = 0
        if slot.GUID_P == addon.GUID_Pet then
            petOffsetX = slot.cachedPetQueueXOffset or 0
        end
        
        -- 队列模式暴击使用critNumberShakeEnabled开关（与动画ABC一致）
        if slot.isCrit == 1 and slot.cachedCritNumberShakeEnabled == 1 then
            -- 应用暴击震动效果
            local shakeIntensity = slot.cachedCritShakeIntensity
            local shakeFrequency = slot.cachedCritShakeFrequency
            -- 使用查表代替 sin/cos，避免每帧计算
            local shakeAngleX = math_mod((passed * shakeFrequency * 360), 360)
            local shakeAngleY = math_mod((passed * shakeFrequency * 480), 360)  -- 不同频率
            local shakeX = GetShakeSin(shakeAngleX) * shakeIntensity
            local shakeY = GetShakeCos(shakeAngleY) * shakeIntensity * 0.6
            
            -- 添加衰减：抖动强度随时间线性减弱，0.5秒后完全停止
            local fade = 1 - math_min(1, passed / 0.5)
            shakeX = shakeX * fade
            shakeY = shakeY * fade
            
            finalCurveX = curveX + shakeX
            finalCurveY = curveY + shakeY
        end
        
        frameOutside:SetPoint("BOTTOMLEFT", addon.DOTFrame, "BOTTOMLEFT", actualStartX + finalCurveX + petOffsetX, actualStartY + finalCurveY)
        
        --  应用基础字符大小缩放（使用缓存值）
        local baseScale = (slot.cachedBaseFontSize or 40) / 100  -- 基础缩放比例
        
        --  只对内层 Frame 应用缩放，外层 frameOutside 只负责位置
        if slot.Frame then
            slot.Frame:SetScale(baseScale)
        end
        
        --  基于进度回收（progress >= 1.0 时回收）
        if progress >= 1.0 then
            ResetSlot(slot)
            return
        end
        
        -- 兜底回收：如果passed超过duration的2倍，强制回收（防止卡死）
        if passed > duration * 2 then
            ResetSlot(slot)
            return
        end
        
        --  基于进度判断淡出时机（避免距离计算的浮点精度问题）
        -- 在progress >= 0.8时开始淡出
        if progress >= 0.8 then
            -- 淡出效果：基于progress的线性插值
            local fadeProgress = (progress - 0.8) / 0.2  -- 0.8到1.0之间映射到0到1
            local alpha = 1 - fadeProgress
            if alpha < 0 then alpha = 0 end
            frameOutside:SetAlpha(alpha)
        else
            frameOutside:SetAlpha(1)
        end
        
        return  -- DOT 动画处理完毕，直接返回
    end
    
    --  非DOT动画才需要查询GUID表（避免DOT每帧浪费查表）
    local guidToPlate = guidToNameplate
    
    -- 计算持续时间
    local dur = 0
    if slot.isCrit == 1 then
        dur = (slot.cachedCritScaleUp or 0.15) + (slot.cachedCritScaleDown or 0.15) + (slot.cachedCritHoldTime or 0.3)  -- 停留时间默认 0.3 秒
    elseif slot.animType == 1 or slot.animType == 2 then
        -- B/C模式：需要考虑滑块2（浮动速度）对时长的影响
        local baseDuration = slot.parabola.duration or (SystemParams.PARABOLA_DURATION or 1.5)
        --  B/C模式使用 normalMoveRandom（非暴击伤害速度），而非 receivedMoveSpeed
        local moveSpeed = UserSettings.normalMoveRandom or 120
        
        -- C模式特殊处理：不受moveSpeed影响，使用完整duration
        if slot.animType == 2 and slot.parabola and slot.parabola.returnToOrigin then
            dur = baseDuration
        else
            -- B模式：受moveSpeed影响
            dur = baseDuration * (100 / moveSpeed)
        end
    else
        dur = (slot.cachedFadeStart or 0.3) + (slot.cachedFadeDur or 0.5)
    end
    
    -- 检查是否结束
    if passed >= dur then
        ResetSlot(slot)
        return
    end
    
    -- 获取姓名板信息（使用缓存的映射表）
    local plate
    local plateValid
    if slot.isFrozen and slot.ghostPlate then
        -- 冻结槽位：使用幽灵锚点（姓名板消失后数字留在原地继续动画）
        plate = slot.ghostPlate
        plateValid = true
    else
        plate = slot.GUID and guidToPlate[slot.GUID]
        plateValid = plate and IsNamePlateValid(plate)
    end
    local useFixedPos = slot.useFixedPos or false
    
    --  强制同步全局开关状态，防止槽位复用导致标志丢失
    if addon.db and (addon.db.fixedPosEnabled == 1 or addon.db.fixedPosEnabled == true) then
        useFixedPos = true
    end
    
    -- 计算位置偏移
    local rx, ry = 0, 0
    if slot.isCrit == 1 then
        rx = slot.crit.randomX or 0
        ry = slot.crit.randomY or 0
    else
        --  动画A不使用 normalBaseY，位置完全基于进度
        local animMode = addon.db and addon.db.normalAnimMode or "A"
        if animMode == "A" then
            -- 动画A：只应用 cachedAnchorX，Y轴基于时间计算（纯lifetime控制）
            rx = slot.normal.randomX + (slot.cachedAnchorX or 0)
            
            --  Y轴位置 = 速度 * 有效时间（与UpdateNormalAnimation保持一致，使用缓存值）
            local speed = slot.cachedMoveSpeed or 120
            local effectivePassed = passed + (slot.normalTimeOffset or 0)
            ry = speed * effectivePassed
        else
            -- B/C模式：使用原有的逻辑（支持推开）
            local baseRx = slot.normal.randomX + (slot.cachedAnchorX or 0)
            local baseRy = slot.normal.randomY  -- Y轴从0开始
            rx = baseRx
            
            -- B/C模式：ry基于effectivePassed计算（支持推开，使用缓存值）
            local speed = slot.cachedMoveSpeed or 120
            local effectivePassed = passed + (slot.normalTimeOffset or 0)
            ry = baseRy + speed * effectivePassed
        end
    end
    
    -- 更新位置
    if slot.isCrit == 1 and addon.DOTFrame and addon.db and addon.db.dotQueueEnabled == 1 then
        --   核心修复：队列模式暴击跳过UpdateSlotPosition，避免位置被覆盖
    else
        UpdateSlotPosition(frameOutside, slot, plate, plateValid, useFixedPos, rx, ry)
    end
    
    -- 根据动画类型执行不同的更新逻辑
    if slot.isCrit == 1 then
        -- 暴击动画：第一次 Update 时显示
        if not frameOutside:IsShown() then
            frameOutside:Show()
        end
        UpdateCritAnimation(slot, f, frameOutside, plate, plateValid, passed)
    else
        -- 非暴击动画：第一次 Update 时显示
        if not frameOutside:IsShown() then
            frameOutside:Show()
        end
        
        -- 使用函数查找表替代 if-elseif 分支
        local handler = AnimationModeHandlers[slot.animType]
        if handler then
            handler(slot, f, frameOutside, plate, plateValid, useFixedPos, passed)
        else
            -- 默认回退到 A模式
            UpdateNormalAnimation(slot, f, frameOutside, plate, plateValid, useFixedPos, passed)
        end
    end
end

-- ======================== 辅助函数 ================================

-- 检测是否为防御/未命中状态
-- 性能优化：使用查表替代多个or判断
local DEFENCE_MISS_SET = {[1]=true, [2]=true, [3]=true, [4]=true, [5]=true, [6]=true, [7]=true, [8]=true, [10]=true, [11]=true}
local DEFENCE_T_MISS_SET = {[0]=true, [2]=true, [3]=true, [5]=true, [6]=true, [7]=true, [8]=true}

local function CheckDefenceStatus(c)
    -- AUTO_ATTACK中：DEFENCE=nil, DEFENCE_T=VICTIMSTATE(数字0-8)
    -- SPELL_MISSED中：DEFENCE=SPELL_MISS_*(数字1-11), DEFENCE_T=nil
    -- SPELL_DAMAGE中：DEFENCE=nil, DEFENCE_T=nil（正常命中）
    
    -- 检查 DEFENCE（SPELL_MISSED中的SPELL_MISS_*值，数字类型）
    if c.DEFENCE and DEFENCE_MISS_SET[c.DEFENCE] then
        return true
    end
    
    -- 检查 DEFENCE_T（AUTO_ATTACK中的VICTIMSTATE值，数字类型）
    if c.DEFENCE_T and DEFENCE_T_MISS_SET[c.DEFENCE_T] then
        return true
    end
    
    return false
end

--  通用防御状态解析函数，统一处理DEFENCE和DEFENCE_T字段
-- 返回值：defenceStatus(数字类型或nil), useDefenceTable(boolean)
local function ParseDefenceStatus(cache, spellId)
    local defenceStatus
    local useDefenceTable = false
    
    if spellId and spellId ~= "" then
        -- 有spellId：优先使用DEFENCE（SPELL_MISSED事件，数字类型）
        if cache.DEFENCE then
            defenceStatus = cache.DEFENCE
            useDefenceTable = true
        elseif cache.DEFENCE_T then
            -- 备用：使用DEFENCE_T（AUTO_ATTACK事件，数字类型）
            defenceStatus = cache.DEFENCE_T
            useDefenceTable = false
        end
    else
        -- 无spellId（平砍）：使用DEFENCE_T（AUTO_ATTACK事件，数字类型）
        if cache.DEFENCE_T then
            defenceStatus = cache.DEFENCE_T
            useDefenceTable = false
        end
    end
    
    return defenceStatus, useDefenceTable
end

-- 计算抛物线动画参数（B/C模式共用）
-- 性能优化：缓存UserSettings查表结果
local function CalculateParabolaParams(slot, damageValue, animType)
    -- 检测防御状态
    local hasDefence = CheckDefenceStatus(combatCache)
    
    if hasDefence then
        -- 防御/未命中状态：使用中等轨迹
        slot.parabola.maxWidth = 200
        slot.parabola.maxHeight = 450
        slot.parabola.duration = 1.0
    else
        -- 普通模式：使用近10次伤害的平均值作为基准
        local avgDamage = GetAverageDamage(10)
        local t = math_min(damageValue / avgDamage, 1)
        
        -- 根据伤害计算力量系数
        local minPower = 0.6
        local maxPower = 2.8
        local power = minPower + (maxPower - minPower) * t * t
        
        --  移除sizeDiff，使用固定宽度
        local baseWidth = 120 * power
        slot.parabola.maxWidth = baseWidth
        slot.parabola.maxHeight = 280 * power
        
        -- 动态调整持续时间
        local baseDuration = 0.8
        local heightFactor = slot.parabola.maxHeight / 280
        slot.parabola.duration = baseDuration * (0.6 + 0.7 * heightFactor)
    end
    
    -- C模式特殊标记
    if animType == 2 then
        slot.parabola.returnToOrigin = true
    end
    
    --  缓存贝塞尔曲线控制点（避免每帧读取 UserSettings）
    local normalRandX = UserSettings.normalRandomX or 100  -- X分布范围
    local normalRandY = UserSettings.normalRandomY or 100  -- Y分布范围
    
    -- 将分布值归一化到0-2范围（100为基准，50=0.5, 150=1.5）
    slot.parabola.controlPointX = 0.5 * (normalRandX / 100)  -- 控制点X：0.25-0.75
    slot.parabola.controlPointY = 1.0 * (normalRandY / 100)  -- 控制点Y：0.5-1.5
end

-- ======================== 动画A队列入队处理 ================================
local function EnqueueNormalDamage(slot, guid, guidP, useFixedPos)
    
    --   如果槽位之前在activeSlots中，先回收（避免重复添加和显示残留）
    if slot.isActive == 1 then
        ResetSlot(slot)
    end
    
    -- 入队成功后才设置字段（批处理释放时需要这些字段）
    slot.GUID = guid
    slot.GUID_P = guidP
    slot.startTime = GetTime()  -- 在这里设置 startTime
    slot.isActive = 0  -- 入队时不激活，出队时才激活
    slot.cachedBaseFontSize = UserSettings.baseFontSize or 40
    slot.useFixedPos = useFixedPos
    
    -- 存入待处理列表
    normalPendingCount = normalPendingCount + 1
    normalPendingList[normalPendingCount] = slot
    
    -- 标记槽位状态
    slot.isActive = 0
    slot.isPendingNormal = true
    
    return true
end

-- ======================== 防御状态处理 ================================
local function HandleDefenceState(slot, f, c, useFixedPos)
    slot.isCrit = 0
    
    -- 动画A接受非暴击滑块里的浮动速度滑块控制
    slot.cachedMoveSpeed = UserSettings.normalMoveRandom or 120
    
    local iconOffsetX = 0
    
    -- 使用统一函数设置技能图标（防御状态）
    ApplySpellIcon(
        slot.Textures[1],
        f,
        slot.spellId,
        c.GUID_P,
        0,
        true,
        iconOffsetX
    )
    
    -- 使用通用函数解析防御状态
    local defenceStatus, useDefenceTable = ParseDefenceStatus(c, slot.spellId)
    
    if defenceStatus then
        SetupDefenceIcon(slot, f, slot.spellId, defenceStatus, useDefenceTable, c.GUID_P)
        
        -- 保存防御状态信息
        slot.defenceStatus = defenceStatus
        slot.useDefenceTable = useDefenceTable
        slot.useCombatStatusIcon = true
        
        -- 入队时更新缓存字体大小
        slot.cachedBaseFontSize = UserSettings.baseFontSize or 40
        slot.useFixedPos = useFixedPos
        
        -- 存入待处理列表
        normalPendingCount = normalPendingCount + 1
        normalPendingList[normalPendingCount] = slot
        
        -- 标记槽位状态
        slot.isActive = 0
        slot.isPendingNormal = true
        
        return true  -- 已入队
    end
    
    return false  -- 非防御状态
end

-- ======================== 队列模式入队处理 ================================
local function EnqueueQueueDamage(slot, c, isCrit)
    -- 核心修复：使用队列模式相关变量
    if queuePendingCount >= QUEUE_MAX_CAPACITY then
        -- 槽位还未设置为 isActive=1，直接返回即可，无需 ResetSlot
        return false
    end
    
    -- 将 DOT 技能 ID 添加到缓存（用于 SPELL_MISS 事件识别）
    if addon.db and addon.db.dotQueueEnabled == 1 and c.SPELLID then
        addon:AddDOTSkillToCache(c.SPELLID)
    end
    
    slot.useFixedPos = true
    slot.hasPlate = false
    slot.GUID = nil
    slot.animMode = "queue"  --   标记为队列模式（D模式）
    slot.isActive = 0
    slot.isPendingDOT = true
    
    -- 存储DOT数据
    slot.dotAmount = c.DAMAGE
    slot.dotIsCrit = isCrit
    slot.dotSpellId = c.SPELLID  -- 保持原值（平砍时为""，技能时为数字ID）
    slot.dotSchool = c.SCHOOL or 0
    slot.dotGUID_P = c.GUID_P  --   保存施法者GUID，用于区分玩家/宠物图标
    
    --   保存防御状态信息（与受伤队列一致）
    -- 核心修复：只有真正的防御状态（闪避/招架/格挡/免疫/反射/未命中）才标记为useCombatStatusIcon
    local isDefenceState = false
    if c.DEFENCE then
        -- DEFENCE存在，肯定是防御状态
        isDefenceState = true
    elseif c.DEFENCE_T ~= nil and c.DEFENCE_T ~= 1 then
        -- DEFENCE_T存在且不等于1（正常命中），才是防御状态
        -- 0=未命中, 2/6=闪避, 3=招架, 5=格挡, 7=免疫, 8=反射
        isDefenceState = true
    end
    
    if isDefenceState then
        slot.defenceStatus = c.DEFENCE or c.DEFENCE_T
        slot.useDefenceTable = (c.DEFENCE ~= nil)
        slot.useCombatStatusIcon = true  --   标记为防御状态
    else
        slot.defenceStatus = nil
        slot.useDefenceTable = false
        slot.useCombatStatusIcon = false
    end
    
    -- 队列模式使用造成非暴击伤害的浮动速度配置
    slot.cachedMoveSpeed = UserSettings.normalMoveRandom or 120
    
    -- 预计算DOT动画常量
    local frameHeight = cachedFrameHeight["dot"] or (addon.DOTFrame and addon.DOTFrame:GetHeight() or 216)
    slot.dotBottomStartY = 20
    slot.dotTopEndY = frameHeight - 32
    slot.dotTotalDistance = slot.dotTopEndY - slot.dotBottomStartY
    slot.dotFadeStartRatio = 0.8
    slot.dotFadeStartDistance = slot.dotTotalDistance * slot.dotFadeStartRatio
    
    -- 存入待处理列表
    queuePendingCount = queuePendingCount + 1
    queuePendingList[queuePendingCount] = slot
    
    return true
end

function addon:AutoShowDamage()
    --  懒加载 + 直接从存档读取最新配置
    if isInitialized == 0 then
        -- 从存档直接读取配置，确保使用最新值
        if PTURTLE_Combat_DB and PTURTLE_Combat_DB.maxAniSlots then
            SystemParams.MAX_ANI_SLOTS = PTURTLE_Combat_DB.maxAniSlots
        end
        addon:InitAniPool()
    end
    
    local c = combatCache
    if c.DAMAGE == nil then return end
    
    -- 技能过滤已在 Parser 层完成，此处移除重复检查
    local threshold = (addon.db and addon.db.damageThreshold) or 0
    if threshold > 0 and c.DAMAGE and c.DAMAGE > 0 and c.DAMAGE <= threshold then return end
    
    -- 记录伤害到历史（用于动态平均伤害计算）
    if c.DAMAGE and c.DAMAGE > 0 then
        RecordDamage(c.DAMAGE)
    end
    
    local school = c.SCHOOL or 0
    local isCrit = c.CRIT or 0
    local guid = c.GUID
    local effectiveSchool = school
    if school == 0 and c.SPELLID and c.SPELLID ~= "" then 
        effectiveSchool = 7 
    end
    -- 使用通用颜色获取函数
    local r, g, b = GetDamageColor(effectiveSchool)

    -- 宠物普攻使用独立颜色（默认白色）
    -- 条件：攻击者是宠物 + 没有技能ID（普攻）
    if c.GUID_P and addon.GUID_Pet and c.GUID_P ~= "" and c.GUID_P == addon.GUID_Pet then
        if not c.SPELLID or c.SPELLID == "" then
            local petColor = (addon.db and addon.db.petAutoAttackColor) or PTURTLE_Combat_DB.petAutoAttackColor
            if petColor then
                r, g, b = petColor.r, petColor.g, petColor.b
            end
        end
    end
    
    --  根据 addon.db.normalAnimMode 选择动画类型（提前声明，避免重复）
    local animMode = addon.db and addon.db.normalAnimMode or "A"
    
    -- 提前判断是否使用固定位置
    local useFixedPos = false
    local isPetDamage = (c.GUID_P == addon.GUID_Pet)
    
    -- 核心修复：队列模式开启且是暴击伤害时，不使用固定位置
    local isInQueueMode = addon.DOTFrame and addon.db and addon.db.dotQueueEnabled == 1
    if isInQueueMode and isCrit == 1 then
        useFixedPos = false
    --  预览模式下强制使用固定位置，避免数字被提前回收
    elseif addon.textPanelPreviewMode and addon.fixedPosIndicator then
        if not (addon.db and addon.db.dotQueueEnabled == 1) then
            useFixedPos = true
        end
    else
        -- 玩家固定位置开关开启时，优先使用固定位置
        if addon.fixedPosIndicator and addon.db and (addon.db.fixedPosEnabled == 1 or addon.db.fixedPosEnabled == true) then
            useFixedPos = true
        end
    end
    
    local slot = GetBestSlot(isCrit, guid, useFixedPos)
    if not slot then return end
    -- 空闲槽位已在回收时清理，活跃槽位在 GetBestSlot 内已重置
    
    -- - 增加暴击计数（在分配槽位时更新）
    if isCrit == 1 then
        if guid and guid ~= "" then
            guidCritCount[guid] = (guidCritCount[guid] or 0) + 1
        elseif useFixedPos then
            fixedPosCritCount = fixedPosCritCount + 1
        end
    end
    
    --  在槽位重置后立即设置useFixedPos标志，确保所有分支都能用到
    slot.useFixedPos = useFixedPos
    
    --  如果启用了固定位置，忽略姓名板
    -- 检查姓名板是否有效（如果启用了固定位置，则忽略姓名板有效性判断）
    local plateValid = false
    local plate
    if not useFixedPos then
        plate = guid and guidToNameplate[guid]
        if plate then
            plateValid = IsNamePlateValid(plate)
        end
    end
    
    slot.GUID = guid
    slot.GUID_P = c.GUID_P
    slot.isCrit = isCrit
    -- isActive 和 startTime 延迟到入队成功后或立即显示时设置，避免僵尸槽位
    slot.isAOEDamage = c.isAOEDamage or nil  -- 复制AOE标记
    
    --  队列模式处理
    -- 队列模式下，非暴击进入队列，暴击继续走动画ABC（只是换个锚点）
    if addon.DOTFrame and addon.db and addon.db.dotQueueEnabled == 1 then
        if isCrit == 0 then
            --   非暴击入队前先设置图标，确保宠物/玩家图标正确显示
            local hasDefenceStatus = false
            if c.DEFENCE or (c.DEFENCE_T ~= nil and c.DEFENCE_T ~= 1) then
                hasDefenceStatus = true
            end
            
            ApplySpellIcon(
                slot.Textures[1],  -- 纹理对象
                slot.Frame,        -- 父框架
                c.SPELLID,         -- 法术ID
                c.GUID_P,          -- 施法者GUID
                isCrit,            -- 是否暴击
                hasDefenceStatus,  -- 是否为防御状态
                nil                -- 图标偏移量
            )
            
            -- 非暴击：进入队列
            if not EnqueueQueueDamage(slot, c, isCrit) then
                return  -- 队列已满，已回收槽位
            end
            return -- 跳过后续定位逻辑
        end
        -- 暴击：不return，继续执行后续的动画ABC逻辑，只是在锚点设置时特殊处理
    end
    
    --  根据是否暴击设置层级
    if isCrit == 1 then
        slot.FrameOutside:SetFrameStrata("HIGH")  -- 暴击：高层级
    else
        slot.FrameOutside:SetFrameStrata("MEDIUM")  -- 普通伤害：中层级（低于暴击）
    end
    
    slot.hasPlate = plateValid  -- 记录是否绑定了姓名板
    slot.useFixedPos = useFixedPos  -- 记录是否使用固定位置
    
    --  获取伤害值用于B/C模式的力反馈计算
    local damageValue = c.DAMAGE or 0
    
    -- 队列模式不应用随机偏移，保持固定位置
    if isCrit == 0 and slot.animMode ~= "queue" then
        
        local baseFontSize = GetSafeFontSize(UserSettings.baseFontSize)
        
        --  缓存淡出配置（A/B/C模式都需要）
        slot.cachedFadeStart = SystemParams.NORMAL_FADE_START or 0.3
        slot.cachedFadeDur = UserSettings.normalFadeDuration or 0.5
        --  动画A接受非暴击滑块里的浮动速度滑块控制（normalMoveRandom）
        slot.cachedMoveSpeed = UserSettings.normalMoveRandom or 120
        slot.cachedAnchorX = UserSettings.anchorXOffset or 0
        slot.cachedBaseFontSize = baseFontSize
        
        if animMode == "B" then
            -- B模式：抛物线动画（接受力反馈）
            -- 力反馈机制：
            --   1. 伤害值决定力量系数（400为基准，越高抛得越远越高）
            --   2. X/Y分布滑块控制贝塞尔曲线控制点，影响抛物线形状
            --   3. 字符大小差值影响抛洒宽度，增加随机性
            --   4. 淡出速度、浮动速度、锚点Y均可动态调整
            slot.animType = 1
            
            -- 随机选择左右方向
            slot.parabola.direction = math_random(0, 1) == 1 and 1 or -1
            
            --  调用共用函数计算抛物线参数
            CalculateParabolaParams(slot, damageValue, 1)
            
        elseif animMode == "C" then
            -- C模式：回力(不是鞋)动画（接受力反馈）
            -- 力反馈机制：
            --   1. 伤害值决定力量系数（400为基准，越高拱得越高）
            --   2. X/Y分布滑块控制贝塞尔曲线控制点，影响拱形轨迹
            --   3. 字符大小差值影响抛洒宽度，增加随机性
            --   4. 抛物线飞出后回到起点(0,0)，立即消失
            slot.animType = 2
            
            -- 随机选择左右方向（决定抛物线向哪边拱起）
            slot.parabola.direction = math_random(0, 1) == 1 and 1 or -1
            
            --  调用共用函数计算抛物线参数
            CalculateParabolaParams(slot, damageValue, 2)
            
        else
            -- A模式：默认向上淡出
            slot.animType = 0
        end
    else
        -- 暴击不再使用网格防重叠，所有暴击从出生点开始
        -- 使用锚点偏移作为基础位置
        local anchorX = UserSettings.critAnchorX or 0
        local anchorY = UserSettings.critAnchorY or 0
        slot.crit.randomX = anchorX
        slot.crit.randomY = anchorY
        
        -- 性能优化：使用缓存的Y偏移量，避免遍历所有槽位（O(1)替代O(n)）
        local currentGUID = slot.GUID  -- 当前槽位的目标GUID
        if currentGUID then
            -- 从缓存中获取该GUID的当前Y偏移量
            local currentYOffset = guidCritYOffset[currentGUID] or 0
            -- 新暴击使用当前的Y偏移量作为起点（叠加入锚点Y偏移）
            slot.crit.randomY = anchorY + currentYOffset
            
            --   性能优化：使用缓存的推开距离，避免重复计算
            local pushDistance = GetCachedCritPushDistance()
            
            -- 更新缓存：为该GUID增加推开距离
            guidCritYOffset[currentGUID] = currentYOffset + pushDistance
        end
        
        -- 应用随机X偏移（在锚点X基础上添加随机值）
        local randomRangeX = UserSettings.critRandomX or 0
        if randomRangeX > 0 then
            slot.crit.randomX = anchorX + math_random(-randomRangeX, randomRangeX)
        end
    end
    local f = slot.Frame
    local frameOutside = slot.FrameOutside

    local rx, ry = 0, 0
    if isCrit == 1 then
        rx = slot.crit.randomX or 0
        ry = slot.crit.randomY or 0
    else
        --  动画A的Y轴从0开始，由 UpdateNormalAnimation 控制向上移动
        if animMode == "A" then
            -- 动画A：只应用 anchorXOffset，Y轴从0开始
            rx = UserSettings.anchorXOffset or 0
            ry = 0  -- Y轴从0开始，由 UpdateNormalAnimation 控制向上移动
            --  对敌人造成的非暴击伤害，起点锚点向X轴负向移动20像素
            rx = rx - 20
        else
            -- B/C模式：抛物线动画从固定位置开始（不应用随机偏移）
            local anchorX = UserSettings.anchorXOffset or 0
            rx = anchorX - 20  -- X轴应用锚点偏移并左移20像素
            ry = 0             -- Y轴从0开始（抛物线轨迹）
        end
    end
    
    local totalX = rx
    local totalY = ry
    if useFixedPos then
        --  使用统一的固定位置指示器
        if addon.fixedPosIndicator then
            frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", totalX, totalY)
        else
            frameOutside:SetPoint("CENTER", UIParent, "CENTER", totalX, totalY)
        end
    else
        --   队列模式暴击特殊处理：直接使用队列框架左下角为锚点
        if isCrit == 1 and addon.DOTFrame and addon.db and addon.db.dotQueueEnabled == 1 then
            frameOutside:SetPoint("BOTTOMLEFT", addon.DOTFrame, "BOTTOMLEFT", totalX, totalY)
        elseif plateValid then
            -- 使用已经获取的 plate 变量，不需要再次查询
            frameOutside:SetPoint("CENTER", plate, "CENTER", totalX, totalY)
        elseif addon.fixedPosIndicator then
            -- 姓名板无效时的回退：使用固定位置指示器（但仅当指示器存在时）
            frameOutside:SetPoint("CENTER", addon.fixedPosIndicator, "CENTER", totalX, totalY)
        else
            -- 最后的回退：使用 UIParent 中心
            frameOutside:SetPoint("CENTER", UIParent, "CENTER", totalX, totalY)
        end
    end
    
    slot.spellId = c.SPELLID  --  保持 nil 值，不要转换为空字符串
    
    if c.DAMAGE and c.DAMAGE > 0 then
        -- 关键修复：先设置技能图标，确定图标是否显示
        local hasDefenceStatus = false  -- 有伤害就不是防御状态
        
        ApplySpellIcon(
            slot.Textures[1],  -- 纹理对象
            f,                 -- 父框架（slot.Frame）
            slot.spellId,      -- 法术ID
            c.GUID_P,          -- 施法者GUID
            isCrit,            -- 是否暴击
            hasDefenceStatus,  -- 是否为防御状态
            nil                -- 图标偏移量（nil表示使用SetNumberTextures设置的位置）
        )
        
        -- 然后设置数字纹理和颜色
        --  动画A队列使用左对齐（与队列模式一致）
        local useRandomOffset = slot.animMode ~= "queue"
        
        --  入队条件优化 - 动画A模式下，只要有固定位置指示器或姓名板，一律入队
        local hasFixedPosIndicator = addon.fixedPosIndicator ~= nil
        local shouldQueue = (isCrit == 0 and slot.animMode ~= "queue" and
            (plateValid or addon.textPanelPreviewMode or useFixedPos or hasFixedPosIndicator))
        
        if shouldQueue and animMode == "A" then
            --  隐藏防御状态图标，避免影响布局
            if slot.Textures[2] then
                slot.Textures[2]:Hide()
            end
            
            -- 动画A队列：使用左对齐
            SetNumberTexturesForQueue(slot.Textures, c.DAMAGE, slot.texCount or (MAX_DIGITS + 1))
        else
            --  只有直接伤害的暴击才使用居中对齐，确保放大后不产生偏移
            -- 其他情况（非暴击、队列模式等）都使用左对齐
            if isCrit == 1 then
                -- 暴击：居中对齐
                SetNumberTextures(slot.Textures, c.DAMAGE, isCrit, useRandomOffset, slot.texCount or (MAX_DIGITS + 1))
                
                -- - 暴击不入队，直接激活显示
                slot.startTime = GetTime()
                slot.isActive = 1
                
                if activeSlotCount < MAX_ANI_SLOTS then
                    activeSlotCount = activeSlotCount + 1
                    activeSlots[activeSlotCount] = slot
                end
            else
                -- 其他情况：左对齐
                SetNumberTexturesForQueue(slot.Textures, c.DAMAGE, slot.texCount or (MAX_DIGITS + 1))
            end
        end
        SetNumberTexturesColor(slot.Textures, r,g,b, slot.texCount or (MAX_DIGITS + 1))
        
        -- ======================== 动画A队列系统：入队逻辑 ================================
        -- 核心条件：非暴击、非DOT、有有效姓名板或预览模式、动画模式为A
        --  预览模式下允许没有姓名板和GUID也入队，使用固定位置作为虚拟姓名板
        
        if shouldQueue then
            if animMode == "A" then
                if not EnqueueNormalDamage(slot, guid, c.GUID_P, useFixedPos) then
                    return -- 队列已满，已回收槽位
                end
                return -- 跳过后续立即显示逻辑，等待批处理释放
            elseif animMode == "B" or animMode == "C" then
                --  B/C模式在预览模式下也需要特殊处理
                -- B/C模式不进入队列，直接激活显示，但需要确保有正确的锚点
                if addon.textPanelPreviewMode and not plateValid then
                    -- 预览模式下没有姓名板时，使用固定位置指示器作为锚点
                    slot.useFixedPos = true
                    slot.hasPlate = false
                    slot.GUID = nil
                end
                
                --  B/C模式非暴击：设置激活状态并加入活跃列表
                slot.startTime = GetTime()
                slot.isActive = 1
                
                if activeSlotCount < MAX_ANI_SLOTS then
                    activeSlotCount = activeSlotCount + 1
                    activeSlots[activeSlotCount] = slot
                end
            end
        end
        -- ============================================================================
    else
        -- 防御状态也加入动画A队列
        if HandleDefenceState(slot, f, c, useFixedPos) then
            return -- 已入队，跳过后续逻辑
        end
        
        --  非防御状态也加入动画A队列（如果有有效姓名板或预览模式或固定位置）
        local shouldQueue = (slot.animMode ~= "queue" and (plateValid or addon.textPanelPreviewMode or useFixedPos))
        
        if shouldQueue and animMode == "A" then
            -- 隐藏防御状态图标
            if slot.Textures[2] then
                slot.Textures[2]:Hide()
                slot.Textures[2]:ClearAllPoints()
                slot.Textures[2]:SetTexture(nil)
            end
            
            -- 非防御状态使用左对齐
            SetNumberTexturesForQueue(slot.Textures, c.DAMAGE, slot.texCount or (MAX_DIGITS + 1))
            
            if not EnqueueNormalDamage(slot, guid, c.GUID_P, useFixedPos) then
                return -- 队列已满，已回收槽位
            end
            return -- 跳过后续立即显示逻辑
        end
    end
    
    -- 暴击槽位需要激活并添加到活跃列表
    if isCrit == 1 then
        slot.startTime = GetTime()
        slot.isActive = 1
        slot.animMode = animMode  --   核心修复：设置animMode为当前动画模式
        
        if activeSlotCount < MAX_ANI_SLOTS then
            activeSlotCount = activeSlotCount + 1
            activeSlots[activeSlotCount] = slot
        end
    end
end

-- ======================== 连线功能 ================================
local Line = {}
Line.pool = {}
Line.smoothX = nil -- 连线目标平滑坐标 X
Line.smoothY = nil -- 连线目标平滑坐标 Y
Line.MAX_YARDS = 41  -- 默认最大距离

local function InitLinePool()
    local count = 0
    -- 获取红点大小配置（默认 2）
    -- 注意：addon.db.targetLineDotSize 应该在存档加载时已确保为数字类型
    local dotSize = addon.db and addon.db.targetLineDotSize or 2
    
    -- 防御性检查：确保是有效值（2、3、4），否则使用默认值
    if dotSize ~= 2 and dotSize ~= 3 and dotSize ~= 4 then
        dotSize = 2
    end
    
    while count < Line.MAX_YARDS do
        count = count + 1
        local f = CreateFrame("Frame", nil, UIParent)
        f:SetWidth(dotSize)
        f:SetHeight(dotSize)
        f:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground"
        })
        f:SetBackdropColor(1, 0, 0, 1)  -- 红色
        f:Hide()
        Line.pool[count] = f  --   使用计数器替代table_insert
    end
    Line.poolCount = count  --   保存计数器
end
--  暴露给 addon，供 PLAYER_LOGIN 事件调用
addon.InitLinePool = InitLinePool

-- 重置连线池（隐藏并清空所有红点）
local function ResetLinePool()
    local poolLen = Line.poolCount or 0  --   使用计数器替代table_getn
    for i = 1, poolLen do
        Line.pool[i]:Hide()
    end
    Line.pool = {}
    Line.poolCount = 0
end
addon.ResetLinePool = ResetLinePool

-- 更新连线红点大小（动态调整）
local function HideAllDots()
    local poolLen = Line.poolCount or 0  --   使用计数器替代table_getn
    for i = 1, poolLen do
        Line.pool[i]:Hide()
    end
end

local cachedScreenCenterX, cachedScreenCenterY = nil, nil
local function UpdateScreenCache()
    -- 使用物理屏幕中心
    cachedScreenCenterX = GetScreenWidth() * 0.5
    cachedScreenCenterY = GetScreenHeight() * 0.5
end
--  暴露给 addon，供 PLAYER_LOGIN 事件调用
addon.UpdateScreenCache = UpdateScreenCache

function addon:ClearTargetGUIDCache()
    addon.lastTargetGUID = nil
end

local function DrawTargetLine()
    HideAllDots()
    
    -- 首先检查是否有目标
    local exists, guid = UnitExists("target")
    if not exists or not guid then return end
    addon.lastTargetGUID = guid
    
    -- 尝试获取姓名板（仅用于回退模式）
    local plate = GetNameplateByGUID(guid)
    local hasPlate = plate and plate:IsVisible()
    
    -- 使用 UnitXP 获取屏幕坐标（优先使用，不依赖姓名板）
    local targetX, targetY
    local useUnitXP = false
    
    if addon.hasUnitXPX and UnitXP then
        local screenX, screenY = UnitXP("screenPos", "target")
        
        if screenX and screenY then
            -- UnitXP 返回归一化坐标，转换为物理屏幕像素坐标
            local screenWidth = GetScreenWidth()
            local screenHeight = GetScreenHeight()
            
            targetX = math_floor(screenX * screenWidth + 0.5)
            targetY = math_floor(screenY * screenHeight + 0.5) + 30  -- 向上偏移30像素
            
            -- 检查距离限制（使用 distanceBetween API）
            local yards = UnitXP("distanceBetween", "player", "target")
            if yards and yards >= 8 then
                local maxDistance = addon.db and addon.db.targetLineDistance or 41
                if yards <= maxDistance then
                    useUnitXP = true
                end
            end
        end
    end
    
    -- 如果 UnitXP_X 不可用或获取失败，回退到姓名板锚点逻辑
    if not useUnitXP then
        -- 回退模式需要姓名板
        if not hasPlate then
            return
        end
        
        -- 使用自定义距离 API
        local yards = UnitXP("distanceBetween", "player", "target")
        if not yards or yards < 8 then return end
        
        -- 使用配置的最大距离（默认 41）
        local maxDistance = addon.db and addon.db.targetLineDistance or 41
        if yards > maxDistance then return end
        
        if not Line.probe then
            local probe = CreateFrame("Frame", nil, UIParent)
            probe:SetWidth(1)
            probe:SetHeight(1)
            Line.probe = probe
        end
        local probe = Line.probe
        probe:ClearAllPoints()
        probe:SetPoint("CENTER", plate, "CENTER", 0, -40)
        probe:GetLeft()
        local nx, ny = probe:GetCenter()
        if not nx or not ny then return end
        targetX, targetY = nx, ny
    end
    
    -- 线性插值防抖 (Lerp)
    local smoothFactor = 0.7
    if not Line.smoothX then
        Line.smoothX = targetX
        Line.smoothY = targetY
    else
        Line.smoothX = Line.smoothX + (targetX - Line.smoothX) * smoothFactor
        Line.smoothY = Line.smoothY + (targetY - Line.smoothY) * smoothFactor
    end
    
    if not cachedScreenCenterX or not cachedScreenCenterY then
        UpdateScreenCache()
    end
    local sx = cachedScreenCenterX
    local sy = cachedScreenCenterY
    
    -- 直接使用平滑后的目标坐标作为终点
    local ex = Line.smoothX
    local ey = Line.smoothY
    
    local dx = ex - sx
    local dy = ey - sy
    local len = math_sqrt(dx * dx + dy * dy)
    if len < 1 then return end
    
    -- 使用配置的最大距离计算点数（默认 41）
    local maxDistance = addon.db and addon.db.targetLineDistance or 41
    
    for i = 1, maxDistance do
        local dot = Line.pool[i]
        if not dot then break end
        local t = (i-1) / (maxDistance - 1)  -- 修正：最后一个点应该正好在终点
        local x = sx + dx * t
        local y = sy + dy * t
        dot:SetPoint("CENTER", UIParent, "BOTTOMLEFT", math_floor(x + 0.5), math_floor(y + 0.5))
        dot:Show()
    end
end

-- ======================== 全局计时器辅助函数 ================================

local function UpdateShakeLogic(now)
    if addon:IsShaking() and addon.UpdateShake then
        addon:UpdateShake(now)
    end
end

local function UpdateNameplateScan(elapsed)
    GlobalTimer.scanAccumulator = GlobalTimer.scanAccumulator + elapsed
    if GlobalTimer.scanAccumulator >= 1.0 then
        GlobalTimer.scanAccumulator = 0
        ScanNameplatesSimple()
    end
end

local function UpdateTargetLine(elapsed)
    if addon.db and addon.db.targetLineEnabled == 1 then
        GlobalTimer.lineAccumulator = GlobalTimer.lineAccumulator + elapsed
        while GlobalTimer.lineAccumulator >= GlobalTimer.LINE_STEP do
            GlobalTimer.lineAccumulator = GlobalTimer.lineAccumulator - GlobalTimer.LINE_STEP
            DrawTargetLine()
        end
    else
        -- 目标连线已关闭，重置累积器并隐藏所有连线点
        GlobalTimer.lineAccumulator = 0
        HideAllDots()
    end
end

local function UpdateAOECounter(now)
    if addon.aoeCounterFrame and addon.aoeCounterFrame.shouldHide then
        local elapsedTime = now - addon.aoeCounterFrame.hideStartTime
        if elapsedTime >= 2.0 then
            addon.aoeCounterFrame:Hide()
            addon.aoeCounterFrame:SetAlpha(1)  -- 重置Alpha为1，下次显示时正常
            addon.aoeCounterFrame.shouldHide = false
            addon.aoeCounterFrame.hideStartTime = nil
        end
    end
    
end

local function UpdateTextPreviewMode(elapsed, now)
    if addon.textPanelPreviewMode then
        if UnitAffectingCombat("player") then
            addon:StopPreviewMode()
            return
        end
        
        if not addon.textPanelPreviewMode then
            addon.textPanelPreviewMode = true
            --  只在累加器为nil时才初始化，避免重置已累积的时间
            if not GlobalTimer.previewAccumulator or type(GlobalTimer.previewAccumulator) ~= "number" then
                GlobalTimer.previewAccumulator = 0
            end
            --  记录上次更新时间，用于计算实际时间差
            GlobalTimer._lastTextPreviewTime = now
        end
        
        --  使用传入的now计算实际时间差，而不是依赖elapsed
        local lastTime = GlobalTimer._lastTextPreviewTime or now
        local actualElapsed = now - lastTime
        GlobalTimer._lastTextPreviewTime = now
        
        -- 防止时间倒退或过大跳跃
        if actualElapsed < 0 or actualElapsed > 1.0 then
            actualElapsed = 0.016
        end
        
        GlobalTimer.previewAccumulator = GlobalTimer.previewAccumulator + actualElapsed
        
        --  使用while循环处理所有累积的时间（0.8秒生成2个数据）
        while GlobalTimer.previewAccumulator >= 0.8 do  -- 每0.8秒触发一次
            GlobalTimer.previewAccumulator = GlobalTimer.previewAccumulator - 0.8
            
            -- 每次生成2个数据
            for i = 1, 2 do
                local c = combatCache
                c.DAMAGE = math_random(10, 999)
                --  预览数字15%概率暴击
                c.CRIT = (math_random(1, 100) <= 15) and 1 or 0
                c.SCHOOL = math_random(0, 7)
                if math_random(1, 10) <= 7 then
                    c.SPELLID = math_random(1, 99999)  -- 保持数字类型
                else
                    c.SPELLID = nil  -- 使用nil而不是空字符串
                end
                c.GUID_P = addon.GUID_Player
                
                -- 核心修复：队列模式开启时，清空GUID让伤害进入队列框架
                if addon.db and addon.db.dotQueueEnabled == 1 then
                    c.GUID = nil  -- 队列模式开启，清空GUID
                else
                    c.GUID = addon.GUID_Player  --  使用玩家GUID，确保有有效的姓名板绑定
                end
                
                c.DEFENCE = ""
                c.DEFENCE_T = ""
                c.isDOT = nil  --  清除 DOT 标记，确保是普通伤害预览
                c.isAOEDamage = nil  -- 清除 AOE 标记
                
                if addon.AutoShowDamage then
                    addon.AutoShowDamage()
                end
            end
        end  -- while循环结束
    end
end

local function UpdateReceivedPreviewMode(elapsed, now)
    -- 实时检查 UI 可见性（预览模式触发频率低，无需缓存）
    local damageVisible = addon.ReceivedUI and addon.ReceivedUI.labelDamage and addon.ReceivedUI.labelDamage:IsShown()
    local healVisible = addon.ReceivedUI and addon.ReceivedUI.labelHeal and addon.ReceivedUI.labelHeal:IsShown()
    local outHealVisible = addon.ReceivedUI and addon.ReceivedUI.labelOutHeal and addon.ReceivedUI.labelOutHeal:IsShown()
    
    if damageVisible or healVisible or outHealVisible then
        if UnitAffectingCombat("player") then
            return
        end
        
        if not addon.receivedPanelPreviewMode then
            addon.receivedPanelPreviewMode = true
            --  只在累加器为nil时才初始化，避免重置已累积的时间
            if not GlobalTimer.receivedPreviewAccumulator or type(GlobalTimer.receivedPreviewAccumulator) ~= "number" then
                GlobalTimer.receivedPreviewAccumulator = 0
            end
            --  记录上次更新时间，用于计算实际时间差
            GlobalTimer._lastReceivedPreviewTime = now
        end
        
        --  使用传入的now计算实际时间差，而不是依赖elapsed
        local lastTime = GlobalTimer._lastReceivedPreviewTime or now
        local actualElapsed = now - lastTime
        GlobalTimer._lastReceivedPreviewTime = now
        
        -- 防止时间倒退或过大跳跃
        if actualElapsed < 0 or actualElapsed > 1.0 then
            actualElapsed = 0.016
        end
        
        GlobalTimer.receivedPreviewAccumulator = GlobalTimer.receivedPreviewAccumulator + actualElapsed
        
        --  使用while循环处理所有累积的时间
        while GlobalTimer.receivedPreviewAccumulator >= 1.0 do  --  1秒间隔，每次3个
            GlobalTimer.receivedPreviewAccumulator = GlobalTimer.receivedPreviewAccumulator - 1.0
            
            --  每0.5秒生成3个数字
            for i = 1, 3 do
                local c = receivedDataCache
                c.amount = math_random(10, 999)
                c.isCrit = (math_random(1, 100) <= 15) and 1 or 0
                
                if c.GUID_OTHERS == 1 then
                    c.school = 3
                elseif c.beHeal == 1 then
                    c.school = 3
                else
                    -- 受伤测试数据：随机生成伤害类型 (0-7)
                    c.school = math_random(0, 7)
                end
                
                if math_random(1, 10) <= 7 then
                    c.spellId = math_random(1, 99999)  -- 预览模式使用数字类型
                else
                    c.spellId = nil
                end
                
                if outHealVisible then
                    c.GUID_OTHERS = 1
                    c.beHeal = 1
                elseif healVisible then
                    c.GUID_OTHERS = nil
                    c.beHeal = 1
                elseif damageVisible then
                    c.GUID_OTHERS = nil
                    c.beHeal = 0
                else
                    c.GUID_OTHERS = nil
                    c.beHeal = math_random(0, 1)
                end
                
                if addon.ShowReceivedAnimation then
                    addon:ShowReceivedAnimation()
                end
            end
        end  -- while循环结束
    else
        if addon.receivedPanelPreviewMode then
            addon.receivedPanelPreviewMode = false
            GlobalTimer.receivedPreviewAccumulator = nil
        end
    end
end

-- 队列框架预览模式更新函数
local function UpdateDOTPreviewMode(elapsed, now)
    -- 实时检查 DOT UI 可见性
    local dotVisible = addon.ReceivedUI and addon.ReceivedUI.labelDOT and addon.ReceivedUI.labelDOT:IsShown()
    
    if dotVisible then
        if UnitAffectingCombat("player") then
            return
        end
        
        if not addon.dotPanelPreviewMode then
            addon.dotPanelPreviewMode = true
            --  只在累加器为nil时才初始化，避免重置已累积的时间
            if not GlobalTimer.dotPreviewAccumulator or type(GlobalTimer.dotPreviewAccumulator) ~= "number" then
                GlobalTimer.dotPreviewAccumulator = 0
            end
            --  记录上次更新时间，用于计算实际时间差
            GlobalTimer._lastDOTPreviewTime = now
        end
        
        --  使用传入的now计算实际时间差，而不是依赖elapsed
        local lastTime = GlobalTimer._lastDOTPreviewTime or now
        local actualElapsed = now - lastTime
        GlobalTimer._lastDOTPreviewTime = now
        
        -- 防止时间倒退或过大跳跃
        if actualElapsed < 0 or actualElapsed > 1.0 then
            actualElapsed = 0.016
        end
        
        GlobalTimer.dotPreviewAccumulator = GlobalTimer.dotPreviewAccumulator + actualElapsed
        
        --  使用while循环处理所有累积的时间（与动画ABC一致：0.8秒间隔，每次2个）
        while GlobalTimer.dotPreviewAccumulator >= 0.8 do
            GlobalTimer.dotPreviewAccumulator = GlobalTimer.dotPreviewAccumulator - 0.8
            
            --  每0.8秒生成2个DOT，形成队列效果
            for j = 1, 2 do
                -- 设置 DOT 预览数据（复用 combatCache，设置 isDOT 标记）
                local c = combatCache
                c.DAMAGE = math_random(10, 999)
                c.CRIT = (math_random(1, 100) <= 30) and 1 or 0  -- 30%概率暴击，用于测试暴击动画
                c.SCHOOL = math_random(0, 7)  -- 随机伤害类型
                c.SPELLID = math_random(1, 99999)  -- 队列模式预览使用数字类型
                c.animMode = "queue"  --   标记为队列模式（D模式）
                c.isAOEDamage = nil
                c.GUID_P = nil  -- ✅ 清除宠物GUID，避免预览时错误应用宠物偏移
                
                
                
                -- 触发 DOT 伤害显示
                if addon.AutoShowDamage then
                    addon:AutoShowDamage()
                end
            end
        end  -- while循环结束
    else
        if addon.dotPanelPreviewMode then
            addon.dotPanelPreviewMode = false
            GlobalTimer.dotPreviewAccumulator = nil
        end
    end
end


-- ======================== 队列模式批处理函数（原DOT队列）===============================
-- 核心功能：每0.1秒批量释放队列，处理推开逻辑和位置计算

local function ProcessQueueBatch(now)
    if queuePendingCount == 0 then return end  --  使用计数器替代table.getn
    
    --  使用最后批处理时间来判断，确保严格0.1秒频率
    local timeSinceLastBatch = now - queueLastBatchTime
    
    -- 核心逻辑：固定每0.1秒释放一次队列
    if timeSinceLastBatch < QUEUE_BATCH_DELAY then return end
    
    -- A. 收集所有当前活跃的队列模式槽位，并找到最年轻的slot age
    --  使用基于时间的推开逻辑，与受伤队列保持一致
    local youngestSlotAge = 999  -- 初始化为很大的值
    for i = 1, activeSlotCount do
        local s = activeSlots[i]
        if s and s.isActive == 1 and s.animMode == "queue" then
            local slotAge = now - (s.startTime or 0)
            --  注意：不考虑dotTimeOffset，因为推开是基于原始时间的
            if slotAge < youngestSlotAge then
                youngestSlotAge = slotAge
            end
        end
    end
    
    --  使用缓存的框架宽高
    local frameHeight = cachedFrameHeight["dot"] or (addon.DOTFrame and addon.DOTFrame:GetHeight() or 216)
    local bottomStartY = 20  -- 底部起始位置
    local maxVisibleHeight = frameHeight - 40  -- 最大可见高度
    
    -- B. 计算新队列需要的总高度和动态间距（使用通用函数）
    local newQueueCount = queuePendingCount
    local dotSpacing, newQueueHeight = CalculateQueueSpacing(newQueueCount, maxVisibleHeight, bottomStartY, "queue")
    
    --  计算实际数字高度（使用队列字体配置）
    -- 使用第一个 pending slot 的缓存值，避免每帧读取 UserSettings
    local firstSlot = queuePendingList[1]
    local baseFontSize = (firstSlot and firstSlot.cachedBaseFontSize) or UserSettings.baseFontSize or 40
    local digitBaseHeight = 64
    local scale = baseFontSize / 100
    local actualDigitHeight = digitBaseHeight * scale
    
    -- C. 执行基于时间的推开逻辑（与A动画保持一致）
    local needPush = false
    local pushDistance = 0
    
    --  核心修复：队列模式使用造成非暴击伤害的浮动速度配置
    -- 使用第一个 pending slot 的缓存值，避免每帧读取 UserSettings
    local speedPercent = (firstSlot and firstSlot.cachedMoveSpeed) or UserSettings.normalMoveRandom or 120
    local dotMoveSpeed = 100 * (speedPercent / 100)  -- 基准速度100像素/秒
    
    if youngestSlotAge < 999 then
        -- 计算新队列完全显示需要的时间
        local newQueueTime = newQueueHeight / dotMoveSpeed  -- 新队列走完自身高度需要的时间
        
        --  如果最年轻的slot存在时间 <= 新队列需要的时间，说明会接触或重叠，需要推开（与受伤队列一致）
        if youngestSlotAge <= newQueueTime then
            needPush = true
            -- 推开距离 = 速度 × 时间差（确保不重叠）
            local timeGap = newQueueTime - youngestSlotAge
            pushDistance = dotMoveSpeed * timeGap
        end
    end
    
    -- 执行推开操作
    if needPush and pushDistance > 0 then
        local timeOffset = pushDistance / dotMoveSpeed
        for i = 1, activeSlotCount do
            local slot = activeSlots[i]
            if slot and slot.isActive == 1 and slot.animMode == "queue" then
                --  只改时间偏移，不改位置（累加）
                slot.dotTimeOffset = (slot.dotTimeOffset or 0) + timeOffset
            end
        end
    end
    
    -- E. 顺序释放缓冲区内的所有队列伤害（从底部开始）
    for i = 1, newQueueCount do
        local slot = queuePendingList[i]
        if not slot then break end  --  安全检查：防止空指针崩溃
    
        --  所有 DOT 从同一起点开始（左下角）
        local baseX = 20  -- 起点X：左下角（距离左边20像素）
        local baseY = 20  -- 起点Y：底部（距离底部20像素）
        
        --  不再存储控制点和总距离，动画逻辑中实时计算
        slot.dotBottomStartY = baseY
        
        -- 基础位置：所有 DOT 都从右下角起点开始
        slot.dotBaseY = baseY
        slot.dotTimeOffset = 0  --  初始化时间偏移为0
        
        --  清除动画A/B/C的残留数据，避免污染
        slot.normal = slot.normal or {}
        slot.normal.randomX = 0
        slot.normal.randomY = 0
        slot.parabola = nil  -- 清除抛物线参数
        slot.animType = nil  -- 清除动画类型
        slot._dotFixedDuration = nil  -- 清除DOT固定时长，让新DOT重新计算
        
        -- 强制使用固定位置，避免绑定到姓名板（固定伤害队列专属）
        slot.useFixedPos = true
        slot.hasPlate = false
        slot.GUID = nil
        slot.GUID_P = slot.dotGUID_P  -- 恢复施法者GUID，用于区分玩家/宠物图标
        
        --   宠物队列X轴偏移：如果是宠物伤害，应用X轴偏移
        local petOffsetX = 0
        if slot.GUID_P == addon.GUID_Pet then
            petOffsetX = UserSettings.petQueueXOffset or 0
        end
        
        slot.FrameOutside:SetPoint("BOTTOMLEFT", addon.DOTFrame, "BOTTOMLEFT", baseX + petOffsetX, baseY)
        
        -- 激活：所有队列模式槽位使用不同的 startTime，在曲线上依次排列
        slot.isActive = 1
        slot.animMode = "queue"  --   标记为队列模式（D模式）
        slot.isPendingDOT = false
        slot.isCrit = slot.dotIsCrit or 0  --  保留暴击信息，用于队列暴击效果
        
        --  确保使用当前配置的速度和字体大小（避免槽位复用时的旧值污染）
        -- 核心修复：队列模式使用造成非暴击伤害的浮动速度配置
        local currentSettings = addon.Config and addon.Config.UserSettings or UserSettings
        slot.cachedMoveSpeed = currentSettings.normalMoveRandom or 120
        slot.cachedBaseFontSize = currentSettings.baseFontSize or 50  -- 队列框架使用动画ABC的字符大小
        
        --   性能优化：预计算dotMoveSpeed，避免每帧重复计算
        local baseMoveSpeed = 100  -- 基准速度（像素/秒）
        local speedPercent = slot.cachedMoveSpeed
        slot.cachedDotMoveSpeed = baseMoveSpeed * (speedPercent / 100)  -- 缓存实际速度
        
        --  通过时间偏移让同一批次的 DOT 在曲线上有序排列
        -- 基于动画ABC字符大小计算间距（与动画ABC保持一致）
        local baseFontSize = slot.cachedBaseFontSize or UserSettings.baseFontSize or 50
        local digitBaseHeight = 64  -- 数字纹理的基础高度（digitH）
        local scale = baseFontSize / 100  -- 字符大小缩放比例
        local actualDigitHeight = digitBaseHeight * scale  -- 实际数字高度
        
        --  固定伤害队列是垂直队列，图标在水平方向，不影响垂直行距
        local dotSpacing = math_floor(actualDigitHeight * 0.8)  -- 间距 = 字符高度80%
        dotSpacing = math_max(dotSpacing, 12)  -- 最小间距12像素
        dotSpacing = math_min(dotSpacing, 60)  -- 最大间距60像素
        
        --  应用队列行距配置（使用动画A的行距滑块）
        local currentSettings = addon.Config and addon.Config.UserSettings or UserSettings
        local queueSpacing = currentSettings.animASpacing or 0
        dotSpacing = dotSpacing + queueSpacing
        dotSpacing = math_max(dotSpacing, 5)  -- 应用额外间距后，最小保持5像素
        
        -- 将垂直间距转换为时间间隔（基于移动速度，使用缓存值）
        local currentSettings = addon.Config and addon.Config.UserSettings or UserSettings
        local speedPercent = slot.cachedMoveSpeed or currentSettings.normalMoveRandom or 120
        local dotMoveSpeed = 100 * (speedPercent / 100)  -- 基准速度100像素/秒
        local timeInterval = dotSpacing / dotMoveSpeed  -- 时间间隔 = 间距 / 速度
        
        -- 第1个 DOT：startTime = now（进度 t=0，在起点）
        -- 第2个 DOT：startTime = now - timeInterval（已经运动了timeInterval秒）
        -- 第3个 DOT：startTime = now - 2*timeInterval（已经运动了2*timeInterval秒）
        slot.startTime = now - (i - 1) * timeInterval
        slot.dotTimeOffset = 0  --  初始化时间偏移为0，避免复用时的残留值
        slot.isActive = 1  --  核心修复：激活槽位，让UpdateAnimation开始工作
        slot.animMode = "queue"  --   核心修复：设置为队列模式
        
        --  将槽位添加到 activeSlots，防止 GetBestSlot 重复分配
        
        -- 检查槽位是否已经在activeSlots中
        local alreadyInArray = false
        for j = 1, activeSlotCount do
            if activeSlots[j] == slot then
                alreadyInArray = true
                break
            end
        end
        
        if not alreadyInArray then
            -- - 添加到活跃列表（用于OnUpdate快速遍历）
            activeSlotCount = activeSlotCount + 1
            activeSlots[activeSlotCount] = slot
        end
        
        slot.spellId = slot.dotSpellId  -- 设置技能 ID
        
        -- 队列激活后重新设置图标，确保使用正确的GUID_P
        local hasDefenceStatus = slot.useCombatStatusIcon or false
        ApplySpellIcon(
            slot.Textures[1],  -- 纹理对象
            slot.Frame,        -- 父框架
            slot.spellId,      -- 法术ID
            slot.GUID_P,       -- 使用恢复后的GUID_P
            slot.isCrit or 0,  -- 是否暴击
            hasDefenceStatus,  -- 是否为防御状态
            nil                -- 图标偏移量
        )
        
        -- 确保 Frame 可见
        slot.FrameOutside:Show()
        slot.FrameOutside:SetAlpha(1.0)
        
        -- 防御状态不调用 SetNumberTexturesForQueue，避免覆盖防御图标
        if slot.Textures and slot.dotAmount and not slot.useCombatStatusIcon then
            -- 核心修复：物理伤害根据是否有技能ID来决定颜色映射
            local effectiveSchool = slot.dotSchool or 0
            if effectiveSchool == 0 and slot.dotSpellId and slot.dotSpellId ~= "" then
                effectiveSchool = 7  -- 技能物理使用深黄色
            end

            -- 使用school配置获取颜色
            local r, g, b = GetDamageColor(effectiveSchool)

            -- 宠物普攻使用独立颜色
            -- 条件：攻击者是宠物 + 没有技能ID（普攻）
            if slot.GUID_P and addon.GUID_Pet and slot.GUID_P ~= "" and slot.GUID_P == addon.GUID_Pet then
                if not slot.dotSpellId or slot.dotSpellId == "" then
                    local petColor = (addon.db and addon.db.petAutoAttackColor) or PTURTLE_Combat_DB.petAutoAttackColor
                    if petColor then
                        r, g, b = petColor.r, petColor.g, petColor.b
                    end
                end
            end
            
            -- 隐藏防御状态图标，避免影响布局
            if slot.Textures[2] then
                slot.Textures[2]:Hide()
            end
            
            -- 先设置技能图标
            ApplySpellIcon(
                slot.Textures[1],
                slot.FrameOutside,
                slot.dotSpellId,
                slot.GUID_P,  -- 使用保存的GUID_P，区分玩家/宠物
                slot.dotIsCrit,
                false,
                nil
            )
            
            -- 队列系统使用专用的左对齐函数
            SetNumberTexturesForQueue(slot.Textures, slot.dotAmount, slot.texCount)
            SetNumberTexturesColor(slot.Textures, r, g, b, slot.texCount)
            
            -- 对中间层Frame施加scale，实现队列字符大小控制
            local currentSettings = addon.Config and addon.Config.UserSettings or UserSettings
            local queueFontSize = currentSettings.baseFontSize or 40
            local scale = queueFontSize / 100  -- 计算缩放比例
            if slot.Frame then
                slot.Frame:SetScale(scale)
            end
        end
        
        -- 如果是防御状态，调用 SetupDefenceIcon 显示防御图标（与受伤队列一致）
        if slot.useCombatStatusIcon and slot.defenceStatus then
            -- 隐藏所有数字纹理
            local i = 2
            while i <= slot.texCount do
                if slot.Textures[i] then
                    slot.Textures[i]:Hide()
                end
                i = i + 1
            end
            
            -- 调用通用防御图标设置函数
            SetupDefenceIcon(slot, slot.FrameOutside, slot.dotSpellId, slot.defenceStatus, slot.useDefenceTable, slot.GUID_P)
        end
    end
    
    -- F. 重置缓冲区计数器（不需要wipe，下次写入会覆盖旧数据）
    queuePendingCount = 0
    
    --  更新最后批处理时间，确保严格0.1秒频率
    queueLastBatchTime = now
end

-- ======================== 动画A（普通伤害）批处理函数 ================================
-- 核心功能：每0.09秒批量释放队列，按GUID分组管理，避免不同目标的数字互相干扰

-- 模块级复用表，避免每0.09秒创建临时表
local _anchorGroupsCache = {}
local _anchorGroupsKeys = {}  -- 数字索引列表（0 GC遍历）
local _anchorKeyCount = 0     -- 上一轮的键数量（用于清空数组）

local function ProcessNormalBatch(now)
    if normalPendingCount == 0 then
        normalLastBatchTime = now
        return
    end
    
    --  使用最后批处理时间来判断，确保严格0.09秒频率
    local timeSinceLastBatch = now - normalLastBatchTime
    if timeSinceLastBatch < NORMAL_BATCH_DELAY then return end
    
    for i = 1, _anchorKeyCount do
        local key = _anchorGroupsKeys[i]
        if key then
            _anchorGroupsCache[key] = nil
        end
    end
    -- 清空键数组（使用上一轮的计数）
    for i = 1, _anchorKeyCount do _anchorGroupsKeys[i] = nil end
    local anchorGroups = _anchorGroupsCache
    local anchorKeys = _anchorGroupsKeys
    local anchorKeyCount = 0  -- 本轮的计数器
    local fixedPosCount = 0  -- 统计使用固定位置的槽位数量
        
    for i = 1, normalPendingCount do
        local slot = normalPendingList[i]
        if slot then
            --  根据姓名板有效性决定分组键
            local anchorKey
            local plate = slot.GUID and guidToNameplate[slot.GUID]
            local plateValid = plate and IsNamePlateValid(plate)
                
            --  冻结槽位：使用幽灵锚点单独成组
            if slot.isFrozen and slot.ghostPlate then
                anchorKey = "__FROZEN__"
            --  固定位置模式下，所有伤害统一归到__FIXED_POSITION__组
            elseif slot.useFixedPos and addon.fixedPosIndicator then
                -- 固定位置模式：统一归到__FIXED_POSITION__组
                anchorKey = "__FIXED_POSITION__"
                fixedPosCount = fixedPosCount + 1
            elseif plateValid then
                -- 有有效姓名板：使用GUID作为分组键
                anchorKey = slot.GUID or "__NO_NAMEPLATE__"
            elseif addon.fixedPosIndicator then
                -- 姓名板无效但有固定位置：使用固定位置作为分组键
                anchorKey = "__FIXED_POSITION__"
                fixedPosCount = fixedPosCount + 1
            else
                -- 既无姓名板也无固定位置：使用特殊标识符
                anchorKey = "__NO_ANCHOR__"
            end
                    
            if not anchorGroups[anchorKey] then
                anchorGroups[anchorKey] = {}
                anchorGroups[anchorKey].count = 0  -- 初始化计数器
                anchorKeyCount = anchorKeyCount + 1
                anchorKeys[anchorKeyCount] = anchorKey
            end
            -- 使用计数器代替 table.insert()，避免 GC
            local groupSlots = anchorGroups[anchorKey]
            groupSlots.count = groupSlots.count + 1
            groupSlots[groupSlots.count] = slot
        end
    end
    
    -- B. 对每个锚点组分别处理（0 GC优化：使用数字索引遍历）
    for i = 1, anchorKeyCount do
        local anchorKey = anchorKeys[i]
        local slots = anchorGroups[anchorKey]
        local groupCount = slots.count or 0
        
        if groupCount == 0 then
            -- 跳过空组
        else
            
            
            -- 获取该组对应的姓名板/固定位置
            local plate
            local hasValidPlate = true
            
            if anchorKey == "__FROZEN__" then
                -- 冻结组：使用幽灵锚点（姓名板消失后数字留在原位）
                plate = slots[1].ghostPlate
                if not plate then
                    for j = 1, groupCount do ResetSlot(slots[j]) end
                    hasValidPlate = false
                end
            elseif anchorKey == "__FIXED_POSITION__" then
                -- 固定位置模式，直接使用固定位置指示器
                plate = addon.fixedPosIndicator
                if not plate then
                    -- 无固定位置指示器，直接回收所有槽位（0 GC：使用计数器遍历）
                    for j = 1, groupCount do ResetSlot(slots[j]) end
                    hasValidPlate = false
                end
            elseif anchorKey == "__NO_ANCHOR__" then
                -- 既无姓名板也无固定位置，回收所有槽位
                for j = 1, groupCount do ResetSlot(slots[j]) end
                hasValidPlate = false
            else
                -- 有有效姓名板，从映射表获取
                plate = guidToNameplate[anchorKey]
                if not plate or not IsNamePlateValid(plate) then
                    --  姓名板失效时，只要有固定位置指示器，就允许回退
                    -- 不再强制要求 slot.useFixedPos 为 true，确保被动回退也能形成队列
                    plate = addon.fixedPosIndicator
                    if not plate then
                        -- 既无姓名板也无固定位置，直接回收所有槽位
                        for j = 1, groupCount do ResetSlot(slots[j]) end
                        hasValidPlate = false
                    end
                    -- 如果有固定位置，继续使用固定位置显示，并进入后续的队列推开逻辑
                end
            end
            
            if hasValidPlate then
                -- ========================统一计算：字体大小、间距、单数字高度

                --  使用第一个 slot 的缓存值，避免每帧读取 UserSettings
                local firstSlot = slots[1]
                local baseFontSize = (firstSlot and firstSlot.cachedBaseFontSize) or UserSettings.baseFontSize or 40
                local digitBaseHeight = 64
                local scale = baseFontSize / 100
                local actualDigitHeight = digitBaseHeight * scale  -- 真实数字高度
                
                -- 间距 = 真实高度 * 0.8 + 配置行距（与DOT队列一致）
                local spacing = math_floor(actualDigitHeight * 0.8)
                spacing = math_max(spacing, 12)
                spacing = math_min(spacing, 60)
                --  使用 animASpacing 滑块控制动画A的行距
                local animASpacing = UserSettings.animASpacing or 0
                spacing = spacing + animASpacing
                spacing = math_max(spacing, 5)
                
                -- 新队列总高度（ 包含最后一个数字的实际高度，确保推开计算精准）
                local newQueueHeight = (groupCount - 1) * spacing + actualDigitHeight
                

                -- ====================扫描活跃槽位，找到最年轻槽位的年龄（基于时间）

                local bottomStartY = 0  -- 起点位置：Y=0
                

                local youngestSlotAge = 999
                local guidActiveNum = 0
                local guidActiveSlots = {}
                
                if anchorKey == "__FIXED_POSITION__" or anchorKey == "__NO_ANCHOR__" then
                    for i = 1, MAX_ANI_SLOTS do
                        local activeSlot = aniData[i]
                        if activeSlot and activeSlot.isActive == 1 and activeSlot.isCrit == 0 and not activeSlot.isDOT then
                            local matchAnchor
                            if anchorKey == "__FIXED_POSITION__" then
                                local activeGuid = activeSlot.GUID
                                local hasValidPlate = activeGuid and guidToNameplate[activeGuid] and IsNamePlateValid(guidToNameplate[activeGuid])
                                matchAnchor = (activeSlot.useFixedPos == true) or (not hasValidPlate)
                            else
                                matchAnchor = false
                            end
                            
                            if matchAnchor then
                                guidActiveNum = guidActiveNum + 1
                                guidActiveSlots[guidActiveNum] = activeSlot
                                
                                -- 同时计算最年轻槽位年龄（排除刚释放的槽位，即normalTimeOffset > 0的槽位）
                                -- 使用有效年龄（考虑已有的时间偏移）
                                local slotAge = now - (activeSlot.startTime or 0)
                                local effectiveAge = slotAge - (activeSlot.normalTimeOffset or 0)
                                if (activeSlot.normalTimeOffset or 0) == 0 and effectiveAge < youngestSlotAge then
                                    youngestSlotAge = effectiveAge
                                end
                            end
                        end
                    end
                else
                    -- 姓名板模式：直接使用GUID缓存（O(1)查询）
                    local cachedSlots = guidActiveCache[anchorKey]
                    local cachedCount = guidActiveCount[anchorKey] or 0
                    
                    if cachedSlots and cachedCount > 0 then
                        for i = 1, cachedCount do
                            local slot = cachedSlots[i]
                            if slot and slot.isActive == 1 and slot.isCrit == 0 and slot.animMode ~= "queue" then
                                guidActiveNum = guidActiveNum + 1
                                guidActiveSlots[guidActiveNum] = slot
                                
                                --  同时计算最年轻槽位年龄（排除刚释放的槽位，即normalTimeOffset > 0的槽位）
                                local slotAge = now - (slot.startTime or 0)
                                if (slot.normalTimeOffset or 0) == 0 and slotAge < youngestSlotAge then
                                    youngestSlotAge = slotAge
                                end
                            end
                        end
                    end
                end

                -- ===========执行基于时间的推开逻辑（与DOT/受伤队列一致）
                local needPush = false
                local pushDistance = 0
                
                -- 计算移动速度（提前定义，供推开逻辑使用）
                -- 使用新队列第一个槽位的缓存速度，确保推开计算与位置计算一致
                local moveSpeed = 120  -- 默认速度
                if groupCount > 0 and slots[1] then
                    moveSpeed = slots[1].cachedMoveSpeed or 120
                end
                
                if youngestSlotAge < 999 then
                    -- 计算新队列完全显示需要的时间
                    local newQueueTime = newQueueHeight / moveSpeed
                    
                    -- 如果最年轻的slot存在时间 <= 新队列需要的时间，说明会接触或重叠，需要推开
                    if youngestSlotAge <= newQueueTime then
                        needPush = true
                        -- 推开距离 = 速度 × 时间差（确保不重叠）
                        local timeGap = newQueueTime - youngestSlotAge
                        pushDistance = moveSpeed * timeGap
                    end
                end
                
                -- 执行推开操作：只改时间偏移，不改位置（累加）
                if needPush and pushDistance > 0 then
                    local timeOffset = pushDistance / moveSpeed
                    for i = 1, guidActiveNum do  --   使用计数器替代table.getn()
                        local slot = guidActiveSlots[i]
                        if slot and slot.isActive == 1 then
                            slot.normalTimeOffset = (slot.normalTimeOffset or 0) + timeOffset
                        end
                    end
                end
                

                -- ====================时间起点统一===============
                --  动画A接受非暴击滑块里的浮动速度滑块控制（normalMoveRandom）
                -- speedPercent 和 moveSpeed 已在推开逻辑中定义
                local timeInterval = spacing / moveSpeed  -- 每个数字的时间间隔
                
                -- 释放当前组所有槽位
                for i = 1, groupCount do
                    local slot = slots[i]
                    if slot then
                        --  ResetSlot 已清理所有字段，这里只设置锚点
                        
                        --  如果是固定位置模式，设置useFixedPos标志
                        if anchorKey == "__FIXED_POSITION__" or (plate and plate == addon.fixedPosIndicator) then
                            slot.useFixedPos = true
                            slot.hasPlate = false
                            
                            -- 固定位置：直接锚定到固定位置指示器中心
                            slot.FrameOutside:SetPoint("CENTER", plate, "CENTER", 0, 0)
                            

                        else
                            -- 非固定位置：使用姓名板左对齐
                            slot.useFixedPos = false
                            slot.hasPlate = true
                            
                            --  防御状态使用左对齐，非防御状态也使用左对齐（与 SetNumberTexturesForQueue 一致）
                            -- 计算左对齐的X偏移：从姓名板左侧开始
                            local plateWidth = plate:GetWidth() or 200
                            local offsetX = -plateWidth / 2 + 20  -- 从左侧偏移20像素
                            
                            slot.FrameOutside:SetPoint("CENTER", plate, "CENTER", offsetX, 0)
                            
                            --  如果是防御状态，需要重新设置防御图标位置以匹配左对齐
                            if slot.useCombatStatusIcon and slot.defenceStatus then
                                -- 重新调用 SetupDefenceIcon 更新位置
                                SetupDefenceIcon(slot, slot.Frame, slot.spellId, slot.defenceStatus, slot.useDefenceTable, slot.GUID_P)
                            end
                        end
                        
                        -- 激活
                        slot.isActive = 1
                        slot.isPendingNormal = false
                        slot.normalTimeOffset = 0  -- 初始化时间偏移为0
                        
                        -- GUID缓存优化：添加到GUID缓存
                        if slot.GUID then
                            if not guidActiveCache[slot.GUID] then
                                guidActiveCache[slot.GUID] = {}
                                guidActiveCount[slot.GUID] = 0
                            end
                            guidActiveCount[slot.GUID] = guidActiveCount[slot.GUID] + 1
                            guidActiveCache[slot.GUID][guidActiveCount[slot.GUID]] = slot
                        end
                        
                        -- - 添加到活跃列表（用于OnUpdate快速遍历）
                        activeSlotCount = activeSlotCount + 1
                        activeSlots[activeSlotCount] = slot
                        
                        -- 同一批次的槽位使用相同的startTime（批处理时间），确保同时回收
                        -- 时间偏移只用于位置计算，不影响回收时间
                        slot.startTime = now  -- 所有槽位使用相同的startTime
                        slot.normalTimeOffset = (i - 1) * timeInterval  -- 时间偏移用于位置计算
                        
                        --  使用滑块控制的存活时间（2.0-5.0秒）
                        slot.lifetime = UserSettings.animALifetime or 3.0
                        
                        -- 显示
                        slot.FrameOutside:Show()
                        slot.FrameOutside:SetAlpha(1.0)
                    end
                end
            end
        end
    end
    
    -- 保存本轮的 anchorKeyCount，供下一轮清空数组时使用
    _anchorKeyCount = anchorKeyCount
    
    -- 重置队列计数器（不需要wipe，下次写入会覆盖旧数据）
    normalPendingCount = 0
    
    --  更新最后批处理时间，确保严格0.09秒频率
    normalLastBatchTime = now
end

-- ======================== 受伤/受疗/输出治疗 通用批处理函数 ================================
-- 核心功能：每0.1秒批量释放队列，处理推开逻辑和位置计算
-- 参数：frameType = "damage" / "heal" / "outHeal"

-- 全局控制点缓存（框架级别，不是槽位级别）
local receivedControlPointCache = {
    damage = { p1x = nil, p1y = nil },
    heal = { p1x = nil, p1y = nil },
    outHeal = { p1x = nil, p1y = nil }
}

local function ProcessReceivedBatch(now, frameType)
    -- 根据 frameType 选择对应的变量
    local pendingList, pendingCount, lastBatchTimeVar, activeSlotsVar, frame, batchDelay, direction
    
    if frameType == "damage" then
        pendingList = damagePendingList
        pendingCount = damagePendingCount
        lastBatchTimeVar = damageLastBatchTime
        activeSlotsVar = activeDamageSlots
        frame = addon.ReceivedUI.frameDamage
        batchDelay = DAMAGE_BATCH_DELAY
        direction = "down"
    elseif frameType == "heal" then
        pendingList = healPendingList
        pendingCount = healPendingCount
        lastBatchTimeVar = healLastBatchTime
        activeSlotsVar = activeHealSlots
        frame = addon.ReceivedUI.frameHeal
        batchDelay = HEAL_BATCH_DELAY
        direction = "down"
    else -- outHeal
        pendingList = outHealPendingList
        pendingCount = outHealPendingCount
        lastBatchTimeVar = outHealLastBatchTime
        activeSlotsVar = activeOutHealSlots
        frame = addon.ReceivedUI.frameOutHeal
        batchDelay = OUTHEAL_BATCH_DELAY
        direction = "up"
    end
    
    if pendingCount == 0 then return end
    
    --  使用最后批处理时间来判断，确保严格0.1秒频率
    local timeSinceLastBatch = now - lastBatchTimeVar
    if timeSinceLastBatch < batchDelay then return end
    
    --  使用缓存的框架宽高
    local cacheKey = frameType
    local frameHeight = cachedFrameHeight[cacheKey] or (frame and frame:GetHeight() or 150)
    local bottomStartY = 20
    local maxVisibleHeight = frameHeight - 40
    
    -- A. 找到最年轻的活跃槽位的年龄
    local youngestSlotAge = 999
    local activeCountVar
    if frameType == "damage" then
        activeCountVar = activeDamageCount
    elseif frameType == "heal" then
        activeCountVar = activeHealCount
    else -- outHeal
        activeCountVar = activeOutHealCount
    end
    
    for i = 1, activeCountVar do  -- 使用计数器替代table.getn
        local s = activeSlotsVar[i]
        if s and (s.active == 1 or s.isActive == 1) then
            local slotAge = now - (s.time or 0)
            --  注意：不考虑receivedTimeOffset，因为推开是基于原始时间的
            if slotAge < youngestSlotAge then
                youngestSlotAge = slotAge
            end
        end
    end
    
    -- B. 计算新队列需要的总高度和动态间距（使用通用函数）
    local newCount = pendingCount
    local spacing, newQueueHeight = CalculateQueueSpacing(newCount, maxVisibleHeight, bottomStartY, "received")
    
    --  提前获取框架宽高，用于推开逻辑（使用缓存）
    local w = cachedFrameWidth[cacheKey] or (frame and frame:GetWidth() or 200)
    
    -- C. 执行基于时间的推开逻辑（与DOT队列一致）
    local needPush = false
    local pushDistance = 0
    
    --  计算移动速度（使用第一个活跃槽位的缓存值）
    local firstActiveSlot = (queueType == "damage" and activeDamageSlots[1]) or
                            (queueType == "heal" and activeHealSlots[1]) or
                            (queueType == "outHeal" and activeOutHealSlots[1])
    local speedPercent = (firstActiveSlot and firstActiveSlot.cachedMoveSpeed) or UserSettings.receivedMoveSpeed or 150
    local moveSpeed = 100 * (speedPercent / 100)
    
    if youngestSlotAge < 999 then
        -- 计算新队列完全显示需要的时间
        local newQueueTime = newQueueHeight / moveSpeed
        
        --  如果最年轻的slot存在时间 <= 新队列需要的时间，说明会接触或重叠，需要推开
        if youngestSlotAge <= newQueueTime then
            needPush = true
            -- 推开距离 = 速度 × 时间差（确保不重叠）
            local timeGap = newQueueTime - youngestSlotAge
            pushDistance = moveSpeed * timeGap
        end
    end
    
    -- 执行推开操作：只改时间偏移，不改位置（累加）
    if needPush and pushDistance > 0 then
        local timeOffset = pushDistance / moveSpeed
        for i = 1, activeCountVar do  -- 使用计数器替代table.getn
            local slot = activeSlotsVar[i]
            if slot and (slot.active == 1 or slot.isActive == 1) then
                slot.receivedTimeOffset = (slot.receivedTimeOffset or 0) + timeOffset
            end
        end
    end
    
    -- E. 顺序释放缓冲区内的所有槽位
    for i = 1, newCount do
        local slot = pendingList[i]
        if not slot then break end
        
        -- 根据类型和方向计算起始位置
        local baseX, baseY
        if frameType == "outHeal" then
            -- 输出治疗：左侧起点，向上运动
            baseX = 20
            baseY = 20
        else
            -- 受伤/受疗：右侧起点，向下运动
            baseX = w - 20
            baseY = frameHeight - 20
        end
        
        -- 不设置receivedBaseY，让Update时实时计算，以跟随框架大小变化
        slot.frameOutside:SetParent(frame)
        
        --   宠物队列X轴偏移：如果是宠物伤害，应用X轴偏移
        local petOffsetX = 0
        if slot.GUID_P == addon.GUID_Pet then
            petOffsetX = UserSettings.petQueueXOffset or 0
        end
        
        slot.frameOutside:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", baseX + petOffsetX, baseY)
        
        slot.active = 1
        slot.isPendingReceived = false
        
        local speedPercent = slot.cachedMoveSpeed or UserSettings.receivedMoveSpeed or 150
        local moveSpeed = 100 * (speedPercent / 100)
        local timeInterval = spacing / moveSpeed
        
        -- 第1个=time=now，第2个=time=now-interval，第3个=time=now-2*interval
        slot.time = now - (i - 1) * timeInterval
        slot.receivedTimeOffset = 0  -- 初始偏移为0
        
        -- 添加到活跃列表（0 GC优化）
        if frameType == "damage" then
            activeDamageCount = activeDamageCount + 1
            activeDamageSlots[activeDamageCount] = slot
        elseif frameType == "heal" then
            activeHealCount = activeHealCount + 1
            activeHealSlots[activeHealCount] = slot
        else
            activeOutHealCount = activeOutHealCount + 1
            activeOutHealSlots[activeOutHealCount] = slot
        end
        
        slot.frameOutside:Show()
        slot.frameOutside:SetAlpha(1.0)
        
        --  防御状态不调用SetupNumberAndIcon，避免覆盖防御图标
        if slot.Textures and slot.amount and not slot.useCombatStatusIcon then
            SetReceivedSlotCache(slot)
            --  使用school配置获取颜色，而不是硬编码白色
            local school = slot.school or (slot.poolType == "heal" and 3 or 0)
            
            -- 特殊处理：受伤普攻使用 receivedAutoAttackColor
            local r, g, b
            if slot.poolType == "damage" and school == 0 then
                -- 受伤普攻：优先使用自定义颜色
                local customColor = addon.db and addon.db.receivedAutoAttackColor
                if customColor then
                    r, g, b = customColor.r, customColor.g, customColor.b
                else
                    r, g, b = GetDamageColor(school)
                end
            else
                r, g, b = GetDamageColor(school)
            end
            
            --  隐藏防御状态图标，避免影响布局
            if slot.Textures[2] then
                slot.Textures[2]:Hide()
            end
            
            -- 先设置技能图标
            local iconOffsetX = (slot.isCrit == 1) and nil or nil
            ApplySpellIcon(
                slot.Textures[1],
                slot.Textures[1]:GetParent(),
                slot.spellId,
                nil,
                slot.isCrit,
                false,
                iconOffsetX
            )
            
            --  队列系统使用专用的左对齐函数
            SetNumberTexturesForQueue(slot.Textures, slot.amount, slot.texCount)
            SetNumberTexturesColor(slot.Textures, r, g, b, slot.texCount)
            
            --  对中间层Frame施加scale，实现队列字符大小控制
            local queueFontSize = UserSettings.queueFontSize or 40
            local scale = queueFontSize / 100  -- 计算缩放比例
            if slot.frame then
                slot.frame:SetScale(scale)
            end
        end
    end
    
    -- 重置计数器（不需要wipe，下次写入会覆盖旧数据）
    if frameType == "damage" then
        damagePendingCount = 0
        damageLastBatchTime = now
    elseif frameType == "heal" then
        healPendingCount = 0
        healLastBatchTime = now
    else
        outHealPendingCount = 0
        outHealLastBatchTime = now
    end
end


-- ======================== 受伤/受疗/输出治疗 入队函数 ================================
-- 核心功能：将伤害数据加入对应队列，等待批处理释放

-- 前向声明：GetReceivedSlot、InitAnimationSlot 和 ResetReceivedSlot 函数在后面定义
local GetReceivedSlot
local InitAnimationSlot

local function EnqueueReceivedAnimation(c, frameType)
    local slot = GetReceivedSlot(frameType)
    if not slot then return end
    
    -- 根据类型选择对应的队列
    local pendingList
    if frameType == "damage" then
        pendingList = damagePendingList
    elseif frameType == "heal" then
        pendingList = healPendingList
    elseif frameType == "outHeal" then
        pendingList = outHealPendingList
    else
        return
    end
    
    --  参照队列框架，入队时不激活，等待批处理时再激活
    slot.active = 0
    slot.isPendingReceived = true  -- 标记为待释放，防止被GetReceivedSlot重用
    
    -- 设置槽位数据
    slot.amount = c.amount
    slot.isCrit = c.isCrit or 0
    slot.spellId = c.spellId
    slot.school = c.school or (frameType == "heal" and 3 or 0)
    slot.animType = (frameType == "damage" and 1) or (frameType == "heal" and 2) or 3  -- 1=受伤, 2=受疗, 3=输出治疗
    
    --  调用SetReceivedSlotCache统一设置缓存（包括速度）
    SetReceivedSlotCache(slot)
    
    --  处理防御状态（输出治疗不需要防御状态）
    if frameType ~= "outHeal" and c.defenceStatus then
        slot.useCombatStatusIcon = true
        slot.defenceStatus = c.defenceStatus
        slot.useDefenceTable = c.useDefenceTable or false
    else
        slot.useCombatStatusIcon = false
    end
    
    -- 设置父框架
    if frameType == "damage" then
        slot.parentFrame = addon.ReceivedUI.frameDamage
        slot.innerFrame = ReceivedUI.handleDamage
    elseif frameType == "heal" then
        slot.parentFrame = addon.ReceivedUI.frameHeal
        slot.innerFrame = ReceivedUI.handleHeal
    else
        slot.parentFrame = addon.ReceivedUI.frameOutHeal
        slot.innerFrame = ReceivedUI.handleOutHeal
    end
    
    -- 初始化动画槽位
    InitAnimationSlot(slot, frameType == "heal")
    
    -- 隐藏框架，等待批处理时显示
    slot.frameOutside:Hide()
    slot.frameOutside:SetAlpha(0)
    
    -- 加入队列（0 GC优化）
    if frameType == "damage" then
        damagePendingCount = damagePendingCount + 1
        pendingList[damagePendingCount] = slot
        --  仅在队列为空时记录首次入队时间，避免后续入队覆盖导致延迟累积
        if damagePendingCount == 1 then
            damageLastEnqueueTime = GetTime()
        end
    elseif frameType == "heal" then
        healPendingCount = healPendingCount + 1
        pendingList[healPendingCount] = slot
        if healPendingCount == 1 then
            healLastEnqueueTime = GetTime()
        end
    else
        outHealPendingCount = outHealPendingCount + 1
        pendingList[outHealPendingCount] = slot
        if outHealPendingCount == 1 then
            outHealLastEnqueueTime = GetTime()
        end
    end
end


-- ======================== DOT队列清理函数 ================================
--  提供外部调用的DOT队列清理函数
--  用途：
--  1. 进入战斗时：防止快速进出战斗（间隔<0.09秒）时旧数据显示
--  2. 字符大小调整时：确保所有DOT使用新的间距配置，避免新旧混用
function addon:ClearQueuePendingList()
    if queuePendingCount > 0 then  --  使用计数器替代table.getn
        for i = 1, queuePendingCount do
            local slot = queuePendingList[i]
            if slot then
                ResetSlot(slot)
            end
        end
        -- 不需要wipe，重置计数器即可（ResetSlot已从活跃列表移除）
        queuePendingCount = 0
    end
end

-- ======================== 通用队列清理函数 ================================
--  提供外部调用的队列清理函数
--  用途：进入战斗时防止快速进出战斗（间隔<0.05-0.1秒）时旧数据显示
function addon:ClearReceivedPendingLists()
    -- 清理受伤队列
    if damagePendingCount > 0 then
        for i = 1, damagePendingCount do
            local slot = damagePendingList[i]
            if slot then
                ResetReceivedSlot(slot)
            end
        end
        -- 不需要wipe，重置计数器即可（ResetReceivedSlot已从活跃列表移除）
        damagePendingCount = 0
    end
    
    -- 清理受疗队列
    if healPendingCount > 0 then
        for i = 1, healPendingCount do
            local slot = healPendingList[i]
            if slot then
                ResetReceivedSlot(slot)
            end
        end
        -- 不需要wipe，重置计数器即可
        healPendingCount = 0
    end
    
    -- 清理输出治疗队列
    if outHealPendingCount > 0 then
        for i = 1, outHealPendingCount do
            local slot = outHealPendingList[i]
            if slot then
                ResetReceivedSlot(slot)
            end
        end
        -- 不需要wipe，重置计数器即可
        outHealPendingCount = 0
    end
end

-- ======================== 受伤/受治疗动画系统 ================================
local function CreateReceivedSlot(parentFrame, index, poolType)
    --  预创建时父级设为nil，谁用谁设，用完回收再设nil
    local frameOutside = CreateFrame("Frame", nil, nil)
    frameOutside:SetWidth(1)
    frameOutside:SetHeight(1)
    frameOutside:SetFrameStrata("MEDIUM")
    local mf = CreateFrame("Frame", nil, frameOutside)
    mf:SetWidth(24)
    mf:SetHeight(24)
    mf:SetPoint("CENTER", frameOutside, "CENTER", 0, 0)
    mf:SetBackdrop(nil)
    local texs = CreateNumberTextures(mf, poolType)
    frameOutside:SetAlpha(0)
    frameOutside:Hide()
    return {
        frame = mf,
        frameOutside = frameOutside,
        Textures = texs,
        active = 0,
        time = 0,
        amount = 0,
        isCrit = 0,
        animType = 0,
        parentFrame = parentFrame,  -- 保存目标父级，使用时设置
        innerFrame = nil,
        index = index,
        poolType = poolType  -- 保存池类型
    }
end

--  将函数赋值给前向声明的局部变量
ResetReceivedSlot = function(slot)
    --  从对应的活跃列表中移除（0 GC优化：交换删除）
    local poolType = slot.poolType
    if poolType == "damage" then
        for i = 1, activeDamageCount do
            if activeDamageSlots[i] == slot then
                -- 用最后一个元素覆盖当前元素
                activeDamageSlots[i] = activeDamageSlots[activeDamageCount]
                activeDamageSlots[activeDamageCount] = nil
                activeDamageCount = activeDamageCount - 1
                break
            end
        end
    elseif poolType == "heal" then
        for i = 1, activeHealCount do
            if activeHealSlots[i] == slot then
                activeHealSlots[i] = activeHealSlots[activeHealCount]
                activeHealSlots[activeHealCount] = nil
                activeHealCount = activeHealCount - 1
                break
            end
        end
    elseif poolType == "outHeal" then
        for i = 1, activeOutHealCount do
            if activeOutHealSlots[i] == slot then
                activeOutHealSlots[i] = activeOutHealSlots[activeOutHealCount]
                activeOutHealSlots[activeOutHealCount] = nil
                activeOutHealCount = activeOutHealCount - 1
                break
            end
        end
    end
    
    -- 隐藏 +/- 符号
    if slot.Textures and slot.Textures.sign then
        slot.Textures.sign:Hide()
    end
    
    -- 先设置正确的状态，再隐藏，避免闪烁
    slot.frame:SetScale(1)
    slot.frame:SetAlpha(1)
    slot.frameOutside:SetAlpha(0)  -- 回收时外层 alpha 设为 0
    slot.frameOutside:Hide()
    -- 回收时设置父级为nil，避免频繁改父级的渲染开销
    slot.frameOutside:SetParent(nil)
    -- 清理由回收函数负责，确保槽位干净
    slot.frameOutside:ClearAllPoints()
    HideTextures(slot.Textures)
    
    --  重置时更新所有数字纹理到最新字体样式
    local texCount = slot.texCount or (MAX_DIGITS + 1)
    for i = 2, texCount do
        local tex = slot.Textures[i]
        if tex then
            tex:SetTexture(cachedTexturePath or "Interface\\AddOns\\PlayTurtle\\img\\num1.blp")
        end
    end
    
    --  无条件重置Textures[2]为数字纹理，避免复用残留
    if slot.Textures and slot.Textures[2] then
        slot.Textures[2]:SetTexture(cachedTexturePath or "Interface\\AddOns\\PlayTurtle\\img\\num1.blp")
        slot.Textures[2]:SetWidth(digitW)  -- 重置为数字纹理默认宽度
        slot.Textures[2]:SetHeight(digitH)  -- 重置为数字纹理默认高度
        slot.Textures[2]:ClearAllPoints()
        slot.Textures[2]:Hide()
    end
    
    --  清除防御状态相关字段，避免复用时的状态污染
    slot.defenceStatus = nil
    slot.useDefenceTable = false
    slot.useCombatStatusIcon = false
    
    slot.active = 0
    slot.time = 0
    slot.startTime = 0  --  同时重置startTime字段，避免跨池复用时的状态污染
    slot.receivedTimeOffset = 0  -- 清除时间偏移，避免复用时的状态污染
    slot.amount = 0
    slot.isCrit = 0
    slot.animType = 0
    slot.spellId = nil
    slot.school = nil
    slot.poolType = nil  -- 清除池类型，避免复用时的状态污染 
    slot.critRandomX = 0
    slot.critRandomY = 0
    slot.normalSizeScale = 1.0
    slot.useCombatStatusIcon = false
    slot.innerFrame = nil
    slot.parentFrame = nil
    -- 重置缓存字段，保证复用一致性
    slot.cachedFadeDur = nil
    slot.cachedMoveSpeed = nil
    slot.cachedBaseFontSize = nil
    slot.cachedFadeStart = nil
    slot.cachedCritScaleStart = nil
    slot.cachedCritScaleEnd = nil
    slot.cachedCritHoldTime = nil
    slot.texCount = nil
    slot._fixedDuration = nil  --  清除固定的duration，避免复用时使用旧值
    slot.receivedTimeOffset = 0  --  重置时间偏移为0
    slot._bezierTotalDistance = nil  --  清除预计算的贝塞尔曲线总行程
    -- 注意：不清除 _receivedCachedP1x/p1y，因为控制点是框架级配置，应该跨槽位复用
end

-- 全局循环索引，三种类型共用 30 个槽位池
local ReceivedSlotIndex = 0

--  将函数赋值给前向声明的变量
GetReceivedSlot = function(poolType)
    --  懒加载 + 直接从存档读取最新配置
    if not ReceivedAnimationPool[1] then
        -- 从存档直接读取配置，确保使用最新值
        if PTURTLE_Combat_DB and PTURTLE_Combat_DB.maxReceivedSlots then
            SystemParams.MAX_RECEIVED_SLOTS = PTURTLE_Combat_DB.maxReceivedSlots
        end
        addon:InitReceivedAnimationPool()
    end
    
    -- 根据类型选择对应的父框架
    local parentFrame
    if poolType == "heal" then
        parentFrame = ReceivedUI.frameHeal
    elseif poolType == "damage" then
        parentFrame = ReceivedUI.frameDamage
    elseif poolType == "outHeal" then
        parentFrame = ReceivedUI.frameOutHeal
    else
        return nil
    end
    
    -- 直接轮询取下一个槽位，不检查是否空闲（队列系统已控制并发）
    local maxSlots = SystemParams.MAX_RECEIVED_SLOTS or 30
    ReceivedSlotIndex = math_mod(ReceivedSlotIndex, maxSlots) + 1
    local index = ReceivedSlotIndex
    
    -- 如果槽位不存在，创建它
    if not ReceivedAnimationPool[index] then
        ReceivedAnimationPool[index] = CreateReceivedSlot(parentFrame, index, poolType)
    end
    
    local slot = ReceivedAnimationPool[index]
    
    -- 如果槽位正在使用或待释放，先重置
    if slot.active == 1 or slot.isPendingReceived then
        ResetReceivedSlot(slot)
    end
    
    -- 设置槽位状态
    slot.poolType = poolType
    slot.parentFrame = parentFrame
    -- 锚点清理由 ResetReceivedSlot 负责，设置由批处理释放时负责
    
    return slot
end

function addon:InitReceivedAnimationPool()
    if ReceivedAnimationPool[1] then return end
    -- 初始化受伤/受治疗/输出治疗动画槽位（从配置读取）
    local maxSlots = SystemParams.MAX_RECEIVED_SLOTS or 30
    
    for i = 1, maxSlots do
        ReceivedAnimationPool[i] = nil  -- 延迟创建，按需创建
    end
end

-- ======================== 受伤/受疗动画更新函数 ================================
local function AnimateReceivedSlot(slot, now)
    local frameOutside = slot.frameOutside
    if not frameOutside or slot.active == 0 then return end
    
    -- 检查是否为淡出模式（animType == 2）
    if slot.animType == 2 and slot.fadeStartTime then
        local elapsed = now - slot.fadeStartTime
        local progress = elapsed / (slot.fadeDuration or 1.0)
        
        if progress >= 1.0 then
            -- 淡出完成，回收槽位
            ResetReceivedSlot(slot)
            return
        end
        
        -- 每帧更新坐标（仅输出治疗淡出模式）
        if slot.targetGUID and addon.hasUnitXPX and UnitXP then
            local screenX, screenY = UnitXP("screenPos", slot.targetGUID)
            if not screenX or not screenY then
                -- 坐标获取失败，立即回收
                ResetReceivedSlot(slot)
                return
            end
            
            -- 计算目标像素坐标（直接使用，不使用线性插值）
            local uiWidth = UIParent:GetWidth()
            local uiHeight = UIParent:GetHeight()
            local targetX = math_floor(screenX * uiWidth + 0.5)
            local targetY = math_floor(screenY * uiHeight + 0.5)
            
            -- 添加上浮动画：基于经过时间和浮动速度计算上浮距离（与动画A一致）
            local floatElapsed = now - (slot.floatStartTime or slot.fadeStartTime)
            local floatSpeed = slot.floatSpeed or (UserSettings.normalMoveRandom or 60)
            local floatDistance = floatSpeed * floatElapsed
            
            -- 计算最终的Y坐标（目标Y + 上浮距离）
            local finalY = targetY + floatDistance
            
            frameOutside:ClearAllPoints()
            frameOutside:SetPoint("CENTER", UIParent, "BOTTOMLEFT", targetX, finalY)
        end
        
        -- 线性淡出
        local alpha = 1.0 - progress
        
        -- 暴击动画：仅应用缩放效果（淡出模式不使用抖动）
        if slot.isCrit == 1 then
            local passed = elapsed
            -- 兼容两种字段名：Frame(伤害) 和 frame(受疗/输出治疗)
            local f = slot.Frame or slot.frame
            
            if not f then return end  -- 安全检查
            
            -- 应用暴击缩放效果
            local critDuration = (slot.cachedCritScaleUp or 0.15) + (slot.cachedCritScaleDown or 0.15)
            local maxScale = slot.cachedCritScaleStart or 12.0
            local finalScale = slot.cachedCritScaleEnd or 6.0
            local up = slot.cachedCritScaleUp or 0.15
            local down = slot.cachedCritScaleDown or 0.15
            local baseScaleFactor = 0.3
            local fadeOutCritScaleFactor = 0.5
            local t = 0
            local scale = 1.0
            
            if passed <= up then
                t = passed / up
                scale = (1 + (maxScale - 1) * t) * baseScaleFactor * fadeOutCritScaleFactor
            elseif passed <= up + down then
                t = (passed - up) / down
                scale = (maxScale - (maxScale - finalScale) * t) * baseScaleFactor * fadeOutCritScaleFactor
            else
                scale = finalScale * baseScaleFactor * fadeOutCritScaleFactor
            end
            
            if scale < 0.01 then scale = 0.01 end
            f:SetScale(scale)
        end
        
        frameOutside:SetAlpha(alpha)
        return  -- 淡出模式下不执行正常动画逻辑
    end
    
    local parentFrame = slot.parentFrame
    if not parentFrame then return end
    
    -- 第一次 Update 时显示
    if not frameOutside:IsShown() then
        frameOutside:Show()
    end
    
    --  先判断框架类型，再获取缓存
    local isOutHeal = (parentFrame == ReceivedUI.frameOutHeal)
    
    --  使用缓存的框架宽高，避免每帧调用API
    local dbPrefix
    if isOutHeal then
        dbPrefix = "outputHeal"  -- 注意：输出治疗框架的dbPrefix是"outputHeal"
    elseif slot.animType == 1 then
        dbPrefix = "damage"  -- 受伤框架的dbPrefix是"damage"
    else
        dbPrefix = "receivedHeal"  -- 受治疗框架的dbPrefix是"receivedHeal"而不是"heal"
    end
    
    local w = cachedFrameWidth[dbPrefix] or parentFrame:GetWidth()
    local h = cachedFrameHeight[dbPrefix] or parentFrame:GetHeight()
    
    --  根据animType确定起点和终点（保持现有配置）
    local actualStartX, actualStartY, topEndX, topEndY
    
    if isOutHeal then
        -- 输出治疗：起点左下角，终点右上角
        actualStartX = 20
        actualStartY = 20  -- 输出治疗起点固定在底部
        topEndX, topEndY = w - 20, h - 32
    elseif slot.animType == 1 then
        -- 受伤动画：起点右上角，终点左下角
        actualStartX = w - 20  -- 起点在右侧
        actualStartY = h - 20  -- 受伤起点固定在顶部
        topEndX, topEndY = 20, 20  -- 终点在左下角
    else
        -- 受治疗动画：起点右上角，终点左下角
        actualStartX = w - 20
        actualStartY = h - 20  -- 受疗起点固定在顶部
        topEndX, topEndY = 20, 20
    end
    
    --  计算总距离（可正可负，表示运动方向）
    local totalDistanceX = topEndX - actualStartX
    local totalDistanceY = topEndY - actualStartY
    
    --  基于Y轴距离计算淡出起点
    local actualTotalDistance = math_abs(totalDistanceY)
    local fadeStartDistance = actualTotalDistance * 0.8  -- 淡出起始距离（80%）
    
    --  获取控制手柄坐标作为贝塞尔曲线控制点
    local handle
    if isOutHeal then
        handle = ReceivedUI.handleOutHeal
    elseif slot.animType == 1 then
        handle = ReceivedUI.handleDamage
    else
        handle = ReceivedUI.handleHeal
    end
    
    -- 确定框架类型对应的缓存键
    local cacheKey
    if isOutHeal then
        cacheKey = "outHeal"
    elseif slot.animType == 1 then
        cacheKey = "damage"
    else
        cacheKey = "heal"
    end
    
    --  智能缓存策略：控制点可见时实时获取，隐藏时使用缓存
    local p1x = receivedControlPointCache[cacheKey].p1x
    local p1y = receivedControlPointCache[cacheKey].p1y
    local needUpdateCache = false
    
    if handle then
        -- 检查控制点是否可见（IsShown表示编辑模式）
        if handle:IsShown() then
            -- 编辑模式：实时获取控制点位置
            needUpdateCache = true
        elseif not p1x or not p1y then
            -- 战斗模式但缓存不存在：需要初始化缓存
            needUpdateCache = true
        end
        -- 否则使用缓存的控制点
    end
    
    if needUpdateCache and handle then
        --  使用相对坐标计算，支持框架反转
        local handleCenterX = handle:GetWidth() / 2
        local handleCenterY = handle:GetHeight() / 2
        
        -- 手柄相对于父框架的偏移量
        local offsetX = handle:GetLeft() - parentFrame:GetLeft()
        local offsetY = handle:GetBottom() - parentFrame:GetBottom()
        
        -- 转换为相对于起点的坐标
        p1x = offsetX + handleCenterX - actualStartX
        p1y = offsetY + handleCenterY - actualStartY
        
        -- 更新全局缓存（框架级别）
        receivedControlPointCache[cacheKey].p1x = p1x
        receivedControlPointCache[cacheKey].p1y = p1y
    elseif not p1x or not p1y then
        -- 没有手柄或缓存失效，使用默认值
        p1x = totalDistanceX / 2
        p1y = totalDistanceY / 2
    end
    
    --  基于速度计算duration（使用缓存值）
    local baseMoveSpeed = 100  -- 基准速度（像素/秒）
    local speedPercent = slot.cachedMoveSpeed  -- 直接使用缓存值
    local moveSpeed = baseMoveSpeed * (speedPercent / 100)
    
    --  在slot首次激活时固定duration和贝塞尔曲线参数，避免每帧重新计算
    local duration = slot._fixedDuration
    if not duration then
        duration = actualTotalDistance / moveSpeed  -- 使用Y轴距离的绝对值计算时长
        -- 安全兜底：防止duration异常
        if duration <= 0 or duration > 10 then
            duration = 1.0  -- 默认1秒
        end
        slot._fixedDuration = duration  -- 固定duration
        
        --  预计算贝塞尔曲线总行程，避免每帧重复计算
        -- 简化近似：使用控制点到起点和终点的直线距离之和
        local dx0 = p1x  -- 控制点到起点的X距离（起点为0,0）
        local dy0 = p1y  -- 控制点到起点的Y距离
        local dx1 = totalDistanceX - p1x  -- 终点到控制点的X距离
        local dy1 = totalDistanceY - p1y  -- 终点到控制点的Y距离
        -- 使用曼哈顿距离近似（避免开方运算）
        slot._bezierTotalDistance = math_abs(dx0) + math_abs(dy0) + math_abs(dx1) + math_abs(dy1)
    end
    
    --  使用有效时间计算进度（加入时间偏移）
    local passed = now - slot.time
    local effectivePassed = passed + (slot.receivedTimeOffset or 0)  -- 核心！
    local progress = effectivePassed / duration
    if progress > 1 then progress = 1 end
    

    
    -- 二次贝塞尔曲线公式：B(t) = (1-t)^2 * P0 + 2*(1-t)*t * P1 + t^2 * P2
    -- P0=(0, 0), P1=(p1x, p1y), P2=(totalDistanceX, totalDistanceY)
    local u = 1 - progress
    local curveX = 2 * u * progress * p1x + progress * progress * totalDistanceX
    local curveY = 2 * u * progress * p1y + progress * progress * totalDistanceY
    
    --  队列暴击震动效果（使用独立的队列暴击震动开关）
    local finalCurveX = curveX
    local finalCurveY = curveY
    
    -- ✅ 修复：只有输出治疗且是宠物时才应用宠物偏移，受伤/受疗不应用
    local petOffsetX = 0
    if slot.poolType == "outHeal" and slot.GUID_P == addon.GUID_Pet then
        petOffsetX = slot.cachedPetQueueXOffset or 0
    end
    
    if slot.isCrit == 1 and slot.cachedQueueCritShakeEnabled == 1 then
        -- 应用暴击震动效果
        local shakeIntensity = slot.cachedCritShakeIntensity
        local shakeFrequency = slot.cachedCritShakeFrequency
        -- 使用查表代替 sin/cos，避免每帧计算
        local shakeAngleX = math_mod((passed * shakeFrequency * 360), 360)
        local shakeAngleY = math_mod((passed * shakeFrequency * 480), 360)  -- 不同频率
        local shakeX = GetShakeSin(shakeAngleX) * shakeIntensity
        local shakeY = GetShakeCos(shakeAngleY) * shakeIntensity * 0.6
        
        -- 添加衰减：抖动强度随时间线性减弱，0.5秒后完全停止
        local fade = 1 - math_min(1, passed / 0.5)
        shakeX = shakeX * fade
        shakeY = shakeY * fade
        
        finalCurveX = curveX + shakeX
        finalCurveY = curveY + shakeY
    end
    
    -- 应用位置（使用贝塞尔曲线计算的位置 + 震动偏移 + 宠物偏移）
    frameOutside:SetPoint("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", actualStartX + finalCurveX + petOffsetX, actualStartY + finalCurveY)
    
    --  暴击缩放动画（类似DOT，立即开始，无延迟）
    local currentScale = 1.0
    if slot.isCrit == 1 then
        local scaleDelay = 0  -- 无延迟，立即开始
        local scaleUpDuration = 0.2  -- 放大时长0.2秒
        local scaleHoldDuration = 0.2  -- 保持时长0.2秒
        local scaleDownDuration = 0.2  -- 缩小时长0.2秒
        local maxScale = UserSettings.queueCritScale or 2.0  -- 使用配置的队列暴击缩放
        
        if passed < scaleDelay then
            currentScale = 1.0
        elseif passed < scaleDelay + scaleUpDuration then
            -- 放大阶段
            local scaleProgress = (passed - scaleDelay) / scaleUpDuration
            currentScale = 1.0 + (maxScale - 1.0) * scaleProgress
        elseif passed < scaleDelay + scaleUpDuration + scaleHoldDuration then
            -- 保持阶段：保持在最大缩放
            currentScale = maxScale
        elseif passed < scaleDelay + scaleUpDuration + scaleHoldDuration + scaleDownDuration then
            -- 缩小阶段
            local scaleProgress = (passed - scaleDelay - scaleUpDuration - scaleHoldDuration) / scaleDownDuration
            currentScale = maxScale - (maxScale - 1.0) * scaleProgress
        else
            currentScale = 1.0
        end
    end
    
    --  应用基础字符大小缩放 * 暴击动画缩放
    local baseFontSize = slot.cachedBaseFontSize or 40
    local baseScale = baseFontSize / 100  -- 基础缩放比例
    local finalScale = baseScale * currentScale
    if finalScale < 0.01 then finalScale = 0.01 end
    
    --  只对内层 Frame 应用缩放，外层 frameOutside 只负责位置
    if slot.frame then
        slot.frame:SetScale(finalScale)
    end
    
    --  基于进度回收（progress >= 1 时回收）
    if progress >= 1.0 then
        --  调用ResetReceivedSlot彻底重置，避免状态残留
        ResetReceivedSlot(slot)
        return
    end
    
    -- 兜底回收：如果passed超过duration的2倍，强制回收（防止卡死）
    if passed > duration * 2 then
        ResetReceivedSlot(slot)
        return
    end
    
    
    --  基于进度判断淡出时机（避免距离计算的浮点精度问题）
    -- 在progress >= 0.8时开始淡出
    if progress >= 0.8 then
        -- 淡出效果：基于progress的线性插值
        local fadeProgress = (progress - 0.8) / 0.2  -- 0.8到1.0之间映射到0到1
        local alpha = 1 - fadeProgress
        if alpha < 0 then alpha = 0 end
        if alpha > 1 then alpha = 1 end
        frameOutside:SetAlpha(alpha)
        
        -- 双重回收判定：alpha=0时也回收
        if alpha <= 0.01 then
            ResetReceivedSlot(slot)
            return
        end
    else
        frameOutside:SetAlpha(1)
    end
end

local function UpdateReceivedAnimations(now)
    if not ReceivedAnimationPool[1] then return end
    
    --  使用计数器替代 table.getn()，避免 GC
    local damageCount = activeDamageCount
    local healCount = activeHealCount
    local outHealCount = activeOutHealCount
    
    --  合并三个活跃列表，计算总活跃数
    local totalActiveCount = damageCount + healCount + outHealCount
    
    -- 没有活跃槽位时直接返回，避免后续计算
    if totalActiveCount == 0 then return end
    
    --  倒序遍历三个活跃列表，避免回收时索引错位导致跳过slot
    for i = damageCount, 1, -1 do
        local slot = activeDamageSlots[i]
        if slot and slot.active == 1 then
            AnimateReceivedSlot(slot, now)
        end
    end
    
    for i = healCount, 1, -1 do
        local slot = activeHealSlots[i]
        if slot and slot.active == 1 then
            AnimateReceivedSlot(slot, now)
        end
    end
    
    for i = outHealCount, 1, -1 do
        local slot = activeOutHealSlots[i]
        if slot and slot.active == 1 then
            AnimateReceivedSlot(slot, now)
        end
    end
end

-- ======================== 通用槽位初始化函数 ================================
--  将函数赋值给前向声明的变量
InitAnimationSlot = function(slot, isHeal)
    -- 使用通用配置缓存函数
    SetReceivedSlotCache(slot)
    slot.texCount = MAX_DIGITS + 1
    slot.receivedTimeOffset = 0  --  初始化时间偏移为0
    if slot.isCrit == 1 then
        --  受伤/受治疗暴击已加入队列系统，不需要随机位置和网格防重叠
        -- 暴击数字将以固定位置显示（由队列系统控制）
        slot.critRandomX = 0
        slot.critRandomY = 0
    else
        --  移除sizeDiff，统一使用基础字体大小
        slot.normalSizeScale = 1.0
    end
    local school = slot.school or (isHeal and 3 or 0)
    -- 使用通用颜色获取函数
    local r, g, b = GetDamageColor(school)
    
    -- 分别控制 + 号和 - 号的显示
    local signTex = slot.Textures.sign
    if signTex then
        -- 防御状态不显示符号
        local isDefenceState = (slot.useCombatStatusIcon and slot.defenceStatus)
        if not isDefenceState then
            local poolType = slot.poolType
            if poolType == "damage" then
                -- 受伤：检查 - 号开关
                local showMinus = addon.db and addon.db.showMinusSign == 1
                if showMinus then
                    signTex:SetTexCoord(minusUV[1], minusUV[2], minusUV[3], minusUV[4])
                    signTex:SetVertexColor(1, 0, 0, 1)  -- 大红色
                    signTex:Show()
                else
                    signTex:Hide()
                end
            elseif poolType == "heal" or poolType == "outHeal" then
                -- 受治疗/输出治疗：检查 + 号开关
                local showPlus = addon.db and addon.db.showPlusSign == 1
                if showPlus then
                    signTex:SetTexCoord(plusUV[1], plusUV[2], plusUV[3], plusUV[4])
                    signTex:SetVertexColor(0, 1, 0, 1)  -- 固定绿色
                    signTex:Show()
                else
                    signTex:Hide()
                end
            else
                signTex:Hide()
            end
        else
            -- 防御状态隐藏符号
            signTex:Hide()
        end
    end
    
    --  受伤/受治疗系统的暴击图标不需要额外偏移，因为 frameOutside 已经有 critRandomX/Y 了
    
    --  如果是防御状态，使用通用函数设置防御图标
    if slot.useCombatStatusIcon and slot.defenceStatus then
        -- 隐藏所有数字纹理
        local i = 2
        while i <= slot.texCount do
            if slot.Textures[i] then
                slot.Textures[i]:Hide()
            end
            i = i + 1
        end
        
        -- 调用通用防御图标设置函数
        SetupDefenceIcon(slot, slot.frame, slot.spellId, slot.defenceStatus, slot.useDefenceTable, slot.GUID_P)
    else
        -- 非防御状态，队列系统使用专用的左对齐函数
        --  隐藏防御状态图标，避免影响布局
        if slot.Textures[2] then
            slot.Textures[2]:Hide()
        end
        
        -- 先设置技能图标
        local iconOffsetX = (slot.isCrit == 1) and nil or nil
        ApplySpellIcon(
            slot.Textures[1],
            slot.Textures[1]:GetParent(),
            slot.spellId,
            nil,
            slot.isCrit,
            false,
            iconOffsetX
        )
        
        SetNumberTexturesForQueue(slot.Textures, slot.amount, slot.texCount)
        SetNumberTexturesColor(slot.Textures, r, g, b, slot.texCount)
        
        --  对中间层Frame施加scale，实现队列字符大小控制
        local queueFontSize = UserSettings.queueFontSize or 40
        local scale = queueFontSize / 100  -- 计算缩放比例
        if slot.frame then
            slot.frame:SetScale(scale)
        end
    end
end

function addon:ShowReceivedAnimation()
    if not ReceivedAnimationPool[1] then
        addon:InitReceivedAnimationPool()
    end
    local c = receivedDataCache
    -- 优化：c.amount 现在是数字类型，直接判断
    local hasAmount = (c.amount ~= nil and c.amount > 0)
    
    if hasAmount then
        local damageValue = c.amount  -- 已经是数字，无需转换
        local threshold = (addon.db and addon.db.damageThreshold) or 0
        if threshold > 0 and damageValue > 0 and damageValue <= threshold then return end
        
        -- 先检查输出治疗（优先级最高）
        if c.GUID_OTHERS == 1 then
            -- 检查输出治疗开关和 UnitXP API 是否可用
            local animEnabled = addon.db and addon.db.outputHealAnimEnabled == 1
            local unitXPAvailable = addon.unitXPAvailable == true
            
            -- 如果动画关闭且 UnitXP 可用，则使用淡出模式
            if not animEnabled and unitXPAvailable then
                -- 动画关闭时：使用 UnitXP 获取屏幕坐标并显示简单淡出
                self:ShowOutHealFadeOnly(c.amount, c.spellId, c.isCrit, c.school, c.targetGUID)
                return
            end
            
            -- 否则进入队列系统（如果动画开启或 UnitXP 不可用）
            EnqueueReceivedAnimation(c, "outHeal")
            return
        end
        
        -- 再检查受治疗
        if c.beHeal == 1 then
            --  预览模式绕过开关检查
            if not addon.receivedPanelPreviewMode then
                if addon.db and addon.db.receivedHealAnimEnabled ~= 1 then return end
            end
            EnqueueReceivedAnimation(c, "heal")
            return
        end
        
        -- 最后是受伤
        --  预览模式绕过开关检查
        if not addon.receivedPanelPreviewMode then
            if addon.db and addon.db.damageAnimEnabled ~= 1 then return end
        end
        EnqueueReceivedAnimation(c, "damage")
        return
    else
        --  使用通用函数解析防御状态
        local defenceStatus, useDefenceTable = ParseDefenceStatus(c, c.spellId)
        
        if not defenceStatus then return end
        
        --  防御状态也加入队列
        local frameType = (c.beHeal == 1) and "heal" or "damage"
        
        -- 检查开关
        if frameType == "heal" then
            if addon.db and addon.db.receivedHealAnimEnabled ~= 1 then return end
        else
            if addon.db and addon.db.damageAnimEnabled ~= 1 then return end
        end
        
        -- 创建防御状态的cache
        local defenceCache = {
            amount = "",
            isCrit = 0,
            spellId = c.spellId,
            school = c.school or 0,
            defenceStatus = defenceStatus,
            useDefenceTable = useDefenceTable,
            isAOEDamage = c.isAOEDamage or false
        }
        
        EnqueueReceivedAnimation(defenceCache, frameType)
        return
    end
end

-- 输出治疗动画关闭时的简单淡出效果（使用 UnitXP 获取屏幕坐标）
function addon:ShowOutHealFadeOnly(amount, spellId, isCrit, school, targetGUID)
    -- 需要传入目标 GUID 才能获取屏幕坐标
    if not targetGUID or targetGUID == "" then
        return  -- 没有目标 GUID，无法获取坐标
    end
    
    -- 尝试通过 UnitXP 获取屏幕坐标（传入 GUID 字符串）
    local screenX, screenY = UnitXP("screenPos", targetGUID)
    
    if not screenX or not screenY then
        return  -- 无法获取坐标，不显示
    end
    
    -- 复用现有的 ReceivedAnimationPool 槽位
    if not ReceivedAnimationPool.outHeal then
        addon:InitReceivedAnimationPool()
    end
    
    local slot = GetReceivedSlot("outHeal")
    if not slot then return end
    
    -- 设置槽位状态
    slot.active = 1
    slot.time = GetTime()
    slot.amount = amount
    slot.isCrit = isCrit or 0
    slot.animType = 2  -- 标记为淡出模式
    slot.spellId = spellId or ""
    slot.school = school or 3
    slot.targetGUID = targetGUID  -- 保存目标 GUID，用于每帧更新坐标
    slot.smoothX = nil  -- 初始化平滑坐标 X
    slot.smoothY = nil  -- 初始化平滑坐标 Y
    slot.floatStartTime = GetTime()  -- 记录上浮开始时间
    slot.baseScreenY = screenY  -- 保存基准屏幕Y坐标
    slot.floatSpeed = UserSettings.normalMoveRandom or 60  -- 使用与动画A相同的浮动速度配置
    
    -- 设置 poolType，让 InitAnimationSlot 正确显示 + 号
    slot.poolType = "outHeal"
    
    -- 初始化槽位缓存
    InitAnimationSlot(slot, true)
    

    
    -- 将槽位加入到活跃列表，这样 AnimateReceivedSlot 才会被调用
    activeOutHealCount = activeOutHealCount + 1
    activeOutHealSlots[activeOutHealCount] = slot
    
    -- 直接定位到目标屏幕坐标，而不是使用队列框架
    local frameOutside = slot.frameOutside
    frameOutside:ClearAllPoints()
    
    -- 使用 UIParent 的实际尺寸进行比例转换
    local uiWidth = UIParent:GetWidth()
    local uiHeight = UIParent:GetHeight()
    
    -- UnitXP 返回归一化坐标 (0-1)，原点左下角，直接乘以 UIParent 尺寸
    local finalX = screenX * uiWidth
    local finalY = screenY * uiHeight
        
    -- 使用 BOTTOMLEFT 锚点,与 UnitXP 坐标系统保持一致
    frameOutside:SetPoint("CENTER", UIParent, "BOTTOMLEFT", finalX, finalY)
    frameOutside:SetAlpha(1)
    frameOutside:Show()

    
    -- 设置淡出参数，由 AnimateReceivedSlot 统一处理
    slot.fadeStartTime = GetTime()
    slot.fadeDuration = UserSettings.normalFadeDuration or 2.0  -- 使用配置的淡出速度，默认2.0秒
end

function addon:ShowOutHealAnimation(amount, spellId, isCrit, school, targetGUID)
    local threshold = (addon.db and addon.db.damageThreshold) or 0
    local damageValue = amount or 0  -- amount 已是数字类型，无需转换
    if threshold > 0 and damageValue > 0 and damageValue <= threshold then return end
    
    -- 即使输出治疗动画关闭，也显示简单的淡出效果
    local animEnabled = addon.db and addon.db.outputHealAnimEnabled == 1
    
    if not animEnabled then
        -- 动画关闭时：使用 UnitXP 获取屏幕坐标并显示简单淡出
        self:ShowOutHealFadeOnly(amount, spellId, isCrit, school, targetGUID)
        return
    end
    
    if not ReceivedAnimationPool.outHeal then
        addon:InitReceivedAnimationPool()
    end
    local slot = GetReceivedSlot("outHeal")
    if not slot then return end
    local innerFrame = ReceivedUI.handleOutHeal
    slot.active = 1
    slot.time = GetTime()
    slot.amount = amount
    slot.isCrit = isCrit
    slot.animType = 2
    slot.innerFrame = innerFrame
    slot.spellId = spellId or ""
    slot.school = school or 3
    
    InitAnimationSlot(slot, true)
    
    -- 确保框架隐藏，设置位置后再显示
    slot.frameOutside:Hide()
    
    -- 设置初始位置（直接 SetPoint，不清除锚点）
    local innerFrame = ReceivedUI.handleOutHeal
    if slot.isCrit == 1 then
        -- 暴击：使用随机偏移位置
        local offsetX = slot.critRandomX or 0
        local offsetY = slot.critRandomY or 0
        slot.frameOutside:SetPoint("CENTER", innerFrame, "CENTER", offsetX, offsetY)
        slot.frameOutside:SetAlpha(1)  -- 暴击立即显示
    else
        -- 非暴击：使用贝塞尔曲线起点（输出治疗）
        slot.frameOutside:SetPoint("CENTER", slot.parentFrame, "BOTTOMLEFT", 20, -slot.parentFrame:GetHeight() + 20)
        slot.frameOutside:SetAlpha(0)  -- 非暴击保持透明，依赖淡入
    end
    
    slot.frameOutside:Show()
end

-- ======================== 全局计时器核心回调===============================
local function GlobalTimer_OnUpdate(self, elapsed)
    
    -- 1. 基础缓存（只做1次/帧）
    local now = GetTime()

    if not elapsed or type(elapsed) ~= "number" then
        elapsed = 0.016
    elseif elapsed < 0.001 then
        elapsed = 0.001
    elseif elapsed > 0.1 then
        elapsed = 0.1
    end
    
    -- 2. 震动逻辑（只在震动时跑）
    UpdateShakeLogic(now)
    
    -- 3. AOE队列处理（先于DOT队列处理，确保AOE到期后进入DOT队列）
    addon:ProcessAOEQueue(now)
    
    -- 4. 批处理（步长控制，不到时间直接跳过）
    -- 队列模式批处理（固定0.1秒释放一次）
    if now - queueLastBatchTime >= 0.09 then
        ProcessQueueBatch(now)
    end
    
    -- 动画A（普通伤害）队列批处理
    if now - normalLastBatchTime >= 0.09 then
        ProcessNormalBatch(now)
    end
    
    -- 受伤/受疗/输出治疗 队列批处理（错峰执行，避免性能峰值）
    local timeSinceDamageEnqueue = now - damageLastEnqueueTime
    local timeSinceHealEnqueue = now - healLastEnqueueTime
    local timeSinceOutHealEnqueue = now - outHealLastEnqueueTime
    
    -- 受伤队列：入队后0.07秒执行
    if timeSinceDamageEnqueue >= 0.07 then
        ProcessReceivedBatch(now, "damage")
    end
    
    -- 受疗队列：入队后0.085秒执行
    if timeSinceHealEnqueue >= 0.085 then
        ProcessReceivedBatch(now, "heal")
    end
    
    -- 输出治疗队列：入队后0.1秒执行
    if timeSinceOutHealEnqueue >= 0.1 then
        ProcessReceivedBatch(now, "outHeal")
    end
    
    -- 5. 动画更新（遍历activeSlots数组）
    for i = activeSlotCount, 1, -1 do
        local slot = activeSlots[i]
        if slot and slot.isActive == 1 then
            UpdateAnimation(slot, now, elapsed)
        end
    end
    
    -- 受伤/受治疗动画更新
    UpdateReceivedAnimations(now)
    
    -- 6. 扫描/连线/预览（全部步长控制）
    UpdateNameplateScan(elapsed)
    UpdateTargetLine(elapsed)
    UpdateAOECounter(now)
    UpdateTextPreviewMode(elapsed, now)
    UpdateReceivedPreviewMode(elapsed, now)
    UpdateDOTPreviewMode(elapsed, now)
end

-- ======================== 初始化全局计时器 ================================
local function InitGlobalTimer()
    if GlobalTimer.frame then return end
    GlobalTimer.frame = CreateFrame("Frame", "PlayTurtle_GlobalTimer", UIParent)
    GlobalTimer.frame:SetScript("OnUpdate", GlobalTimer_OnUpdate)
    GlobalTimer.animAccumulator = 0
    GlobalTimer.scanAccumulator = 0
    GlobalTimer.lineAccumulator = 0
    GlobalTimer.previewAccumulator = 0  -- 文字面板预览模式累积器
    GlobalTimer.receivedPreviewAccumulator = 0  -- 受伤/受治疗/输出治疗预览模式累积器
    GlobalTimer.dotPreviewAccumulator = 0  -- 队列框架预览模式累积器
    GlobalTimer.LINE_STEP = 1/30  -- 连线更新步长（30FPS）
    GlobalTimer.lastUpdate = GetTime()
    -- 修复：初始化队列计时器，避免重载后第一次伤害立即触发两批次
    normalLastBatchTime = GetTime()
    queueLastBatchTime = GetTime()
end

-- ======================== 启动函数 ================================
function addon:StartAutoScan()
    InitGlobalTimer()
end

-- ======================== 启动预览模式 ================================
function addon:StartPreviewMode()
    if addon.textPanelPreviewMode then return end
    if addon.playerInCombat then return end  -- 战斗中不启动
    
    addon.textPanelPreviewMode = true
    --  只在累加器为nil时才初始化，避免重置已累积的时间
    if not GlobalTimer.previewAccumulator or type(GlobalTimer.previewAccumulator) ~= "number" then
        GlobalTimer.previewAccumulator = 0
    end
end

-- 停止预览模式
function addon:StopPreviewMode()
    -- 停止文字设置面板预览模式
    if addon.textPanelPreviewMode then
        addon.textPanelPreviewMode = false
        GlobalTimer.previewAccumulator = nil
    end
    
    --  停止受伤/受治疗/输出治疗预览模式
    if addon.receivedPanelPreviewMode then
        addon.receivedPanelPreviewMode = false
        GlobalTimer.receivedPreviewAccumulator = nil
    end
    
    --  停止队列框架预览模式
    if addon.dotPanelPreviewMode then
        addon.dotPanelPreviewMode = false
        GlobalTimer.dotPreviewAccumulator = nil
    end
end



-- ======================== AOE 队列处理函数 ================================

-- ======================== AOE 合并队列分发函数 ================================
-- 将 AOE 伤害项加入 DOT 队列
local function EnqueueAOEToDOT(item, now)
    --   立即保存 item 字段到局部变量，避免被回收函数清空
    local spellId = item and item.spellId
    local damage = item and item.damage or 0
    local count = item and item.count or 0
    local school = item and item.school or 0
    local defenceStatus = item and item.defenceStatus
    local useDefenceTable = item and item.useDefenceTable
    
    local slot = GetBestSlot()
    if not slot then return end
    
    -- 配置为队列模式
    slot.useFixedPos = true  --  强制使用固定位置，避免绑定到姓名板
    slot.hasPlate = false
    slot.GUID = nil
    slot.animMode = "queue"  --   标记为队列模式（D模式）
    slot.isActive = 0
    slot.isPendingDOT = true
    
    -- 存储 DOT 数据
    slot.dotAmount = damage
    slot.dotIsCrit = 0
    slot.dotSpellId = spellId
    slot.dotSchool = school or 0
    
    -- 保存防御状态信息（AOE抵抗时使用）
    if defenceStatus then
        slot.defenceStatus = defenceStatus
        slot.useDefenceTable = useDefenceTable or false
        slot.useCombatStatusIcon = true
    else
        slot.defenceStatus = nil
        slot.useDefenceTable = false
        slot.useCombatStatusIcon = false
    end
    
    -- DOT 使用队列系统速度配置
    slot.cachedMoveSpeed = UserSettings.receivedMoveSpeed or 150
    
    -- 预计算 DOT 动画常量
    local frameHeight = cachedFrameHeight["dot"] or (addon.DOTFrame and addon.DOTFrame:GetHeight() or 216)
    slot.dotBottomStartY = 20
    slot.dotTopEndY = frameHeight - 32
    slot.dotTotalDistance = slot.dotTopEndY - slot.dotBottomStartY
    slot.dotFadeStartRatio = 0.8
    slot.dotFadeStartDistance = slot.dotTotalDistance * slot.dotFadeStartRatio
    
    -- 加入DOT待处理列表
    queuePendingCount = queuePendingCount + 1
    queuePendingList[queuePendingCount] = slot
    
    -- 更新计数器显示
    if addon.UpdateAOECountOnIndicator then
        addon:UpdateAOECountOnIndicator(count)
    end
end

-- 将 AOE 治疗项加入输出治疗队列
local function EnqueueAOEToOutHeal(item, now)
    local slot = GetReceivedSlot("outHeal")
    if not slot then return end
    
    -- 设置槽位状态
    slot.active = 0
    slot.isPendingReceived = true
    slot.poolType = "outHeal"
    slot.parentFrame = addon.ReceivedUI.frameOutHeal

    slot.animType = 3  -- 3=输出治疗
    
    -- 存储治疗数据
    slot.amount = item.damage  -- 累计的治疗量
    slot.isCrit = 0
    slot.spellId = item.spellId
    slot.school = item.school or 3  -- 默认为自然系
    slot.useCombatStatusIcon = false
    
    -- 输出治疗使用队列系统速度配置
    SetReceivedSlotCache(slot)
    
    -- 加入输出治疗待处理列表
    outHealPendingCount = outHealPendingCount + 1
    outHealPendingList[outHealPendingCount] = slot
    
    -- 更新入队时间（用于批处理触发）
    outHealLastEnqueueTime = now or GetTime()
    
    -- 更新计数器显示
    if addon.UpdateAOECountOnIndicator then
        addon:UpdateAOECountOnIndicator(item.count)
    end
end

-- ======================== AOE 合并队列处理 ================================
function addon:ProcessAOEQueue(now)
    local accumulator = addon.aoeAccumulator
    local aoeKeys = addon.aoeAccumulatorKeys
    if not accumulator or not aoeKeys then return end
    
    --  0 GC优化：使用数字索引遍历，替代pairs()
    local i = 1
    while i <= table.getn(aoeKeys) do
        local spellId = aoeKeys[i]
        local item = accumulator[spellId]
        
        -- 检查是否超过延迟时间
        if item and now - item.queueTime >= addon.AOE_QUEUE_DELAY then
            -- 直接传递原始item，避免创建临时表产生GC
            -- 根据动画模式决定AOE处理方式
            local animMode = addon.db and addon.db.normalAnimMode or "A"
            
            if animMode == "D" then
                -- 队列模式（D模式）：AOE走DOT/输出治疗队列
                if item.isHeal then
                    -- 治疗 AOE → 输出治疗队列
                    addon.EnqueueAOEToOutHeal(item, now)
                else
                    -- 伤害 AOE → DOT 队列
                    addon.EnqueueAOEToDOT(item, now)
                end
            else
                -- 非队列模式（A/B/C模式）：AOE视为1条普通数据，走普通伤害流程
                -- 使用AutoShowDamage显示合并后的AOE伤害
                if not item.isHeal then
                    combatCache.DAMAGE = item.damage
                    combatCache.SPELLID = item.spellId
                    combatCache.SCHOOL = item.school
                    combatCache.CRIT = 0  -- AOE合并非暴击
                    combatCache.GUID = nil  -- AOE没有特定目标
                    combatCache.GUID_P = nil
                    
                    -- 调用AutoShowDamage，它会从combatCache读取数据
                    addon:AutoShowDamage()
                    
                    -- 清除combatCache，避免影响后续伤害
                    combatCache.DAMAGE = nil
                    combatCache.SPELLID = nil
                    combatCache.SCHOOL = nil
                    combatCache.CRIT = nil
                else
                    -- 治疗 AOE → 输出治疗队列
                    addon.EnqueueAOEToOutHeal(item, now)
                end
            end
            
            -- 从累加器中移除已释放的技能（先回收到对象池）
            if addon.ReturnAOEItemToPool then
                addon.ReturnAOEItemToPool(item)
            end
            accumulator[spellId] = nil
            
            -- 从数字索引列表中移除（0 GC优化）
            table.remove(aoeKeys, i)
            
            -- 移除后检查累加器是否为空，如果为空则隐藏计数器
            if table.getn(aoeKeys) == 0 and addon.UpdateAOECountOnIndicator then
                addon:UpdateAOECountOnIndicator(0)  -- 隐藏计数器
            end
        else
            i = i + 1  -- 只有未移除时才递增
        end
    end
end

-- 暴露 AOE 分发函数给 addon
addon.EnqueueAOEToDOT = EnqueueAOEToDOT
addon.EnqueueAOEToOutHeal = EnqueueAOEToOutHeal
-- 暴露队列模式清理函数
addon.ClearQueuePendingList = addon.ClearQueuePendingList


