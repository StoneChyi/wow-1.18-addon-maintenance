-- STSMmayor 自动盾牌换装插件
-- 魔兽世界1.12版本

-- 初始化Gratuity-2.0库
local gratuity = AceLibrary("Gratuity-2.0")
local DURABILITY_TEMPLATE = DURABILITY_TEMPLATE or "耐久度 (%d+) / (%d+)"

-- 插件状态
STSMmayor_Enabled = false

-- 上次的盾牌耐久度，用于避免重复预警
local lastShieldDurability = -1

-- 定时器相关设置
local BAG_CHECK_INTERVAL = 20 -- 背包检查间隔（秒）
local DURABILITY_CHECK_INTERVAL = 1 -- 耐久度检查间隔（秒）
local AUTO_SWAP_THRESHOLD = 15 -- 自动换盾耐久阈值（点数）
local REPAIR_WARNING_THRESHOLD = 20 -- 修理警告耐久阈值（点数）
local lastBagCheckTime = 0 -- 上次检查背包的时间
local lastDurabilityCheckTime = 0 -- 上次检查耐久度的时间
local bagCheckTimer = nil -- 定时器对象
local durabilityCheckTimer = nil -- 耐久度检查定时器
local hadBrokenShield = false -- 上次检查时是否有破损盾牌
local lowDurabilityWarningShown = false -- 跟踪是否已显示低耐久警告

-- 防无限循环机制
local EQUIP_COOLDOWN = 3 -- 换盾冷却时间（秒）
local lastEquipAttempt = 0 -- 上次尝试换盾的时间

-- 耐久度监控窗口相关变量
local durabilityFrame = nil -- 耐久度监控窗口
local positionFrame = nil -- 不缩放的固定位置锚点
local durabilityText = nil -- 耐久度文本显示
local closeButton = nil -- 关闭按钮
local equipButton = nil -- 换盾按钮
local repairButton = nil -- 修理按钮
local autoSwapCheckButton = nil -- 自动换盾开关
local autoSwapCheckText = nil -- 自动换盾开关文本
local pickupButton, autoSwapText, autoRepairText, robotDetectionText
local autoRepairCheckButton, robotDetectionCheckButton, autoRepairInteractHint
local settingsLoaded = false
local startupComplete = false
local startupFrame = nil
local appearanceFrame = nil
local isFrameMoving = false
local isDurabilityFrameVisible = false -- 窗口是否可见
local equipFailed = false -- 记录上次换装是否失败
local STSMmayor_AutoSwapEnabled = true -- 自动换盾开关，默认开启
local STSMmayor_AutoRepairEnabled = false -- 自动修理开关，默认关闭
local STSMmayor_RobotDetectionEnabled = false -- 机器人检测开关，默认关闭
local AUTO_REPAIR_THRESHOLD = 30 -- 自动修理耐久阈值（百分比）
local FORCE_REACTIVE_DISK_ID = 18168 -- 力反馈盾牌：按物品编号识别，兼容不同语言
local forceReactiveDiskEquipped = false

-- Only an equipment transition opens the panel. Inventory refreshes while
-- already wearing the disk must respect a manual hide/disable in this session.
local function STSMmayor_ForceReactiveDiskJustEquipped()
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if not slotID then return false end
    local itemLink = GetInventoryItemLink("player", slotID)
    local _, _, itemID = string.find(itemLink or "", "item:(%d+):")
    local wearing = tonumber(itemID) == FORCE_REACTIVE_DISK_ID
    local justEquipped = wearing and not forceReactiveDiskEquipped
    -- Update before enabling: shield checks may cause a nested equipment event.
    forceReactiveDiskEquipped = wearing
    return justEquipped
end

-- 每个角色独立保存；等 SavedVariables 加载完成后再读取。
function STSMmayor_LoadSettings()
    if settingsLoaded then return end
    if type(STSMmayorDB) ~= "table" then STSMmayorDB = {} end
    if type(STSMmayorDB.AutoSwap) == "boolean" then
        STSMmayor_AutoSwapEnabled = STSMmayorDB.AutoSwap
    end
    if type(STSMmayorDB.AutoRepair) == "boolean" then
        STSMmayor_AutoRepairEnabled = STSMmayorDB.AutoRepair
    end
    if type(STSMmayorDB.RobotDetection) == "boolean" then
        STSMmayor_RobotDetectionEnabled = STSMmayorDB.RobotDetection
    end
    if type(STSMmayorDB.Enabled) == "boolean" then
        STSMmayor_Enabled = STSMmayorDB.Enabled
    else
        STSMmayorDB.Enabled = nil
    end
    -- Validate old or manually edited appearance settings before touching the UI.
    local function bounded(value, fallback, low, high)
        if type(value) ~= "number" or value ~= value then return fallback end
        return math.max(low, math.min(value, high))
    end
    STSMmayorDB.UIScale = bounded(STSMmayorDB.UIScale, 0.9, 0.5, 1.5)
    STSMmayorDB.BackgroundAlpha = bounded(STSMmayorDB.BackgroundAlpha, 0.35, 0, 1)
    if type(STSMmayorDB.PositionLocked) ~= "boolean" then STSMmayorDB.PositionLocked = false end
    settingsLoaded = true
end

-- Position is owned by an unscaled, fixed-size anchor. The visible panel is
-- always attached to its top-left with zero offsets and may scale independently.
local STSMmayor_PositionPoints = {
    TOPLEFT = {0, 1}, TOP = {0.5, 1}, TOPRIGHT = {1, 1},
    LEFT = {0, 0.5}, CENTER = {0.5, 0.5}, RIGHT = {1, 0.5},
    BOTTOMLEFT = {0, 0}, BOTTOM = {0.5, 0}, BOTTOMRIGHT = {1, 0},
}

local function STSMmayor_ValidPositionAnchor(anchor)
    return type(anchor) == "table" and STSMmayor_PositionPoints[anchor.point]
        and STSMmayor_PositionPoints[anchor.relativePoint]
        and type(anchor.x) == "number" and type(anchor.y) == "number"
        and anchor.x - anchor.x == 0 and anchor.y - anchor.y == 0
end

function STSMmayor_SaveSettings()
    if not settingsLoaded then return end
    STSMmayorDB.AutoSwap = STSMmayor_AutoSwapEnabled
    STSMmayorDB.AutoRepair = STSMmayor_AutoRepairEnabled
    STSMmayorDB.RobotDetection = STSMmayor_RobotDetectionEnabled
    STSMmayorDB.Enabled = STSMmayor_Enabled
    STSMmayorDB.Visible = isDurabilityFrameVisible
    if positionFrame and not isFrameMoving then
        -- Native dragging can leave GetPoint() empty or unreliable on 1.12.
        -- Read the unscaled carrier's actual geometry, never the scaled panel.
        local left, top = positionFrame:GetLeft(), positionFrame:GetTop()
        local parentLeft, parentBottom = UIParent:GetLeft(), UIParent:GetBottom()
        local ownScale, parentScale = positionFrame:GetEffectiveScale(), UIParent:GetEffectiveScale()
        if type(left) == "number" and type(top) == "number"
            and type(parentLeft) == "number" and type(parentBottom) == "number"
            and type(ownScale) == "number" and type(parentScale) == "number" and parentScale > 0 then
            local ratio = ownScale / parentScale
            local anchor = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT",
                x = left * ratio - parentLeft, y = top * ratio - parentBottom }
            if STSMmayor_ValidPositionAnchor(anchor) then
                STSMmayorDB.PositionAnchor = anchor
                return true
            end
        end
        -- Missing geometry must not erase the last valid saved position.
    end
    return false
end

-- Capture again after native dragging has finished its next layout pass.
-- Retries are bounded and run only after a drag, never as permanent polling.
function STSMmayor_FinishMoving()
    if not positionFrame or not isFrameMoving then return end
    positionFrame:StopMovingOrSizing()
    isFrameMoving = false
    STSMmayor_SaveSettings()
    local deadline, nextAttempt = GetTime() + 1, 0
    positionFrame:SetScript("OnUpdate", function()
        local now = GetTime()
        if now < nextAttempt then return end
        nextAttempt = now + 0.05
        if now > deadline or (not isFrameMoving and STSMmayor_SaveSettings()) then
            positionFrame:SetScript("OnUpdate", nil)
        end
    end)
end

local function STSMmayor_SetPositionAnchor(point, relativePoint, x, y)
    positionFrame:SetPoint(point, UIParent, relativePoint, x, y)
    -- Also keep the explicit restored anchor if the engine has no geometry yet.
    STSMmayorDB.PositionAnchor = { point = point, relativePoint = relativePoint, x = x, y = y }
end

function STSMmayor_RestorePosition()
    if not positionFrame then return end
    local anchor = STSMmayorDB.PositionAnchor
    positionFrame:ClearAllPoints()
    if STSMmayor_ValidPositionAnchor(anchor) then
        STSMmayor_SetPositionAnchor(anchor.point, anchor.relativePoint, anchor.x, anchor.y)
        return
    end
    -- Migrate the old scaled-panel anchor once, compensating its point within
    -- the old 320x34 panel. Never repeat this conversion when a slider changes.
    local old = STSMmayorDB.Anchor
    local scale = STSMmayorDB.UIScale
    if STSMmayor_ValidPositionAnchor(old) then
        local point = STSMmayor_PositionPoints[old.point]
        STSMmayor_SetPositionAnchor("TOPLEFT", old.relativePoint,
            (old.x - point[1] * 320) * scale,
            (old.y + (1 - point[2]) * 34) * scale)
        return
    end
    local position = STSMmayorDB.Position
    if type(position) == "table" and type(position.x) == "number" and type(position.y) == "number"
        and position.x - position.x == 0 and position.y - position.y == 0 then
        local width, height = UIParent:GetWidth(), UIParent:GetHeight()
        local x = math.max(0, math.min(position.x * width, math.max(0, width - 320 * scale)))
        local bottom = math.max(0, math.min(position.y * height, math.max(0, height - 34 * scale)))
        local y = bottom + 34 * scale
        STSMmayor_SetPositionAnchor("TOPLEFT", "BOTTOMLEFT", x, y)
    else
        STSMmayor_SetPositionAnchor("TOPLEFT", "CENTER", -160 * scale, -UIParent:GetHeight() / 4 + 34 * scale)
    end
end

function STSMmayor_ResetPosition()
    STSMmayor_LoadSettings()
    if not durabilityFrame then STSMmayor_CreateDurabilityFrame() end
    if isFrameMoving then positionFrame:StopMovingOrSizing(); isFrameMoving = false end
    STSMmayorDB.PositionAnchor = nil
    STSMmayorDB.Anchor = nil
    STSMmayorDB.Position = nil
    STSMmayor_RestorePosition()
    STSMmayor_SaveSettings()
end

-- 聊天消息颜色
local CHAT_COLOR = "|cff40ff40" -- 绿色
local ERROR_COLOR = "|cffff4040" -- 红色
local WARNING_COLOR = "|cffffff00" -- 黄色（预警用）
local REPAIR_WARNING_COLOR = "|cffff8040" -- 橙色（修理警告用）

-- 修理机器人状态显示文本
local repairBotText = nil

-- 机器人：事件立即发现，动态间隔校验，姓名板分批补查。
local repairBotGUID = nil
local repairBotUnits = {}
local deadRepairBots = {}
local repairBotEventsOn = false
local lastBotRefresh = -1
local lastBotPlateScan = -1
local robotIndicator = nil
local nextBotRefresh = 0
local plateQueue, plateQueueIndex = nil, 1
local nextPlateSlice = 0

local function STSMmayor_BotBusy()
    return UnitAffectingCombat("player") or (type(GetFramerate) == "function" and GetFramerate() < 30)
end

local function STSMmayor_BotPollInterval()
    if not durabilityFrame or not durabilityFrame:IsShown() then return 2 end
    if STSMmayor_BotBusy() then return 0.75 end
    if next(repairBotUnits) or (robotIndicator and robotIndicator.Status == "present") then return 0.25 end
    return 1
end

local function STSMmayor_IsGUID(guid)
    return type(guid) == "string" and string.find(guid, "^0x%x+$")
        and not string.find(guid, "^0x0+$")
end

local function STSMmayor_IsRepairBotName(name)
    if type(name) ~= "string" then return false end
    local lower = strlower(name)
    return string.find(lower, "^修理机器人7[45][ab]型$") ~= nil
        or string.find(lower, "^战地修理机器人7[45][ab]型$") ~= nil
        or string.find(lower, "^修理機器人7[45][ab]型$") ~= nil
        or string.find(lower, "^field repair bot 7[45][ab]$") ~= nil
        or string.find(lower, "^repair bot 7[45][ab]$") ~= nil
end

local function STSMmayor_GetBotGUID(unit)
    if STSMmayor_IsGUID(unit) then return unit end
    for _, getter in ipairs({ GetUnitGUID or false, UnitGUID or false }) do
        if type(getter) == "function" then
            local ok, guid = pcall(getter, unit)
            if ok and STSMmayor_IsGUID(guid) then return guid end
        end
    end
    -- pcall adds its success flag BEFORE UnitExists' exists and GUID results.
    local ok, exists, guid = pcall(UnitExists, unit)
    if ok and exists and STSMmayor_IsGUID(guid) then return guid end
end

local function STSMmayor_UnitIsRepairBot(unit)
    if not unit then return false end
    local okName, name = pcall(UnitName, unit)
    if not okName or not STSMmayor_IsRepairBotName(name) then return false end
    local guid = STSMmayor_GetBotGUID(unit)
    if guid and deadRepairBots[guid] then return false end
    local okExists, exists = pcall(UnitExists, unit)
    if not okExists or not exists then return false end
    local okVis, visible = pcall(UnitIsVisible, unit)
    if not okVis or not visible then return false end
    local okAttack, canAttack = pcall(UnitCanAttack, "player", unit)
    if not okAttack or canAttack then return false end
    if type(UnitIsDeadOrGhost) == "function" then
        local ok, dead = pcall(UnitIsDeadOrGhost, unit)
        if ok and dead then return false end
    elseif type(UnitIsDead) == "function" then
        local ok, dead = pcall(UnitIsDead, unit)
        if ok and dead then return false end
    end
    if type(UnitHealth) == "function" then
        local ok, health = pcall(UnitHealth, unit)
        if ok and type(health) == "number" and health <= 0 then return false end
    end
    return true
end

-- Verified against the installed wsloot.dll: its object scan rejects center
-- distances above 5 yards, before the NPC branch's separate 6-yard check.
-- Match that effective 5-yard limit using 3D positions, including height.
local REPAIR_BOT_RANGE = 5

local function STSMmayor_ValidNumber(value)
    return type(value) == "number" and value - value == 0
end

local function STSMmayor_BotRange(unit)
    if type(UnitPosition) == "function" then
        local okPlayer, px, py, pz = pcall(UnitPosition, "player")
        local okUnit, x, y, z = pcall(UnitPosition, unit)
        if okPlayer and okUnit and STSMmayor_ValidNumber(px) and STSMmayor_ValidNumber(py)
            and STSMmayor_ValidNumber(pz) and STSMmayor_ValidNumber(x)
            and STSMmayor_ValidNumber(y) and STSMmayor_ValidNumber(z) then
            local dx, dy, dz = x - px, y - py, z - pz
            return dx * dx + dy * dy + dz * dz <= REPAIR_BOT_RANGE * REPAIR_BOT_RANGE, true
        end
    end
    if type(UnitXP) == "function" then
        local ok, distance = pcall(UnitXP, "distanceBetween", "player", unit)
        if ok and STSMmayor_ValidNumber(distance) and distance >= 0 then
            return distance <= REPAIR_BOT_RANGE, true
        end
    end
    -- Visible plates/targets alone cannot prove that a unit is within 5 yards.
    return nil, true
end

-- UnitIsVisible only means the client has loaded the unit; it does not test
-- walls. Query the player's line of sight, never the camera's visibility.
-- This is a local precheck, not a server-confirmed interaction result.
local function STSMmayor_BotInSight(unit)
    if type(UnitXP) ~= "function" then return false end
    local ok, inSight = pcall(UnitXP, "inSight", "player", unit)
    -- Lua treats 0 and -1 as true, so never use generic truthiness here.
    return ok and (inSight == true or inSight == 1)
end

local function STSMmayor_RememberRepairBot(unit)
    if not STSMmayor_UnitIsRepairBot(unit) or STSMmayor_BotRange(unit) ~= true then return false end
    local guid = STSMmayor_GetBotGUID(unit)
    -- Keep nearby candidates even while occluded so walking around a wall
    -- can restore green on the normal poll, without another discovery event.
    if guid then repairBotUnits[guid] = true end
    return true
end


function STSMmayor_ResetRepairBots()
    repairBotUnits = {}; deadRepairBots = {}; repairBotGUID = nil
    lastBotPlateScan = -1; lastBotRefresh = -1
    nextBotRefresh = 0; plateQueue = nil; plateQueueIndex = 1; nextPlateSlice = 0
end

local function STSMmayor_ScanRobotPlates()
    if not WorldFrame or not WorldFrame.GetChildren then return end
    -- Only inspect frames already present; never enable nameplates or switch target.
    local now = GetTime()
    local busy = STSMmayor_BotBusy()
    local interval = busy and 5 or 2
    if not durabilityFrame or not durabilityFrame:IsShown() then interval = 10 end
    if not plateQueue and (lastBotPlateScan < 0 or now - lastBotPlateScan >= interval) then
        lastBotPlateScan = now
        plateQueue = { WorldFrame:GetChildren() }
        plateQueueIndex = 1
    end
    if not plateQueue or now < nextPlateSlice then return end
    nextPlateSlice = now + (busy and 0.5 or 0.25)
    -- Bound lookup work per slice even in crowded areas. Retain the snapshot
    -- until the scan completes, rather than enumerating WorldFrame every tick.
    local count = table.getn(plateQueue)
    local last = math.min(count, plateQueueIndex + 63)
    for index = plateQueueIndex, last do
        local frame = plateQueue[index]
        if frame.IsShown and frame:IsShown() and frame.GetName then
            local ok, guid = pcall(frame.GetName, frame, 1)
            if ok and STSMmayor_IsGUID(guid) then STSMmayor_RememberRepairBot(guid) end
        end
    end
    plateQueueIndex = last + 1
    if plateQueueIndex > count then plateQueue = nil end
end

function STSMmayor_CheckForRepairBot()
    STSMmayor_ScanRobotPlates()
    local found = false
    for guid in pairs(repairBotUnits) do
        if STSMmayor_UnitIsRepairBot(guid) and STSMmayor_BotRange(guid) == true then
            if STSMmayor_BotInSight(guid) then
                found = true; repairBotGUID = guid
            end
        else
            repairBotUnits[guid] = nil
        end
    end
    -- Standard unit tokens remain usable even without a GUID extension.
    if STSMmayor_RememberRepairBot("target") and STSMmayor_BotInSight("target") then found = true end
    if STSMmayor_RememberRepairBot("mouseover") and STSMmayor_BotInSight("mouseover") then found = true end
    if not found then repairBotGUID = nil end
    return found
end

local repairBotEventFrame = CreateFrame("Frame", "STSMmayorRobotWatcher")
repairBotEventFrame:Hide()
repairBotEventFrame:SetScript("OnEvent", function(selfArg, eventArg, unitArg)
    if not STSMmayor_Enabled or not STSMmayor_RobotDetectionEnabled then return end
    local currentEvent = eventArg or event
    local unit = unitArg or arg1
    if currentEvent == "PLAYER_ENTERING_WORLD" then
        STSMmayor_ResetRepairBots()
        STSMmayor_UpdateRepairBotStatus()
    elseif currentEvent == "PLAYER_TARGET_CHANGED" or currentEvent == "UPDATE_MOUSEOVER_UNIT" then
        STSMmayor_RememberRepairBot(currentEvent == "PLAYER_TARGET_CHANGED" and "target" or "mouseover")
        STSMmayor_UpdateRepairBotStatus()
    elseif STSMmayor_IsGUID(unit) then
        if currentEvent == "UNIT_DIED" then
            if not repairBotUnits[unit] then return end
            deadRepairBots[unit] = true
            repairBotUnits[unit] = nil
            STSMmayor_UpdateRepairBotStatus()
        elseif repairBotUnits[unit] or STSMmayor_RememberRepairBot(unit) then
            STSMmayor_UpdateRepairBotStatus()
        end
    end
end)
repairBotEventFrame:SetScript("OnUpdate", function()
    local now = GetTime()
    if now >= nextBotRefresh then
        lastBotRefresh = now
        STSMmayor_UpdateRepairBotStatus()
        nextBotRefresh = now + STSMmayor_BotPollInterval()
    end
end)

function STSMmayor_SetRepairBotEvents(enable)
    if enable and not repairBotEventsOn then
        for _, name in ipairs({ "UNIT_FLAGS", "UNIT_FACTION", "PLAYER_TARGET_CHANGED",
            "UPDATE_MOUSEOVER_UNIT", "PLAYER_ENTERING_WORLD", "UNIT_FLAGS_GUID",
            "UNIT_NAME_UPDATE_GUID", "UNIT_MODEL_CHANGED_GUID", "UNIT_DIED" }) do
            -- Older clients may reject extension event names individually.
            pcall(function() repairBotEventFrame:RegisterEvent(name) end)
        end
        repairBotEventsOn = true
        lastBotRefresh = -1; lastBotPlateScan = -1
        nextBotRefresh = 0
        repairBotEventFrame:Show()
    elseif not enable then
        repairBotEventFrame:UnregisterAllEvents()
        repairBotEventFrame:Hide()
        repairBotEventsOn = false
        STSMmayor_ResetRepairBots()
    end
end

function STSMmayor_UpdateRepairBotStatus()
    if not durabilityFrame then return end
    local enabled = STSMmayor_Enabled and STSMmayor_RobotDetectionEnabled
    local found = enabled and STSMmayor_CheckForRepairBot()
    local r, g, b = 0.5, 0.5, 0.5
    local text = "修理机器人检测已关闭（可在设置中开启）"
    local state = "disabled"
    if enabled then
        if found then
            r, g, b = 0.2, 0.9, 0.25
            text = "修理机器人在5码内且无遮挡（本地预判；仍受商人/过滤设置及服务器规则影响）"
            state = "present"
        else
            r, g, b = 0.95, 0.2, 0.2
            text = "未确认可交互的修理机器人（超出5码、被遮挡或距离/视线检测不可用）"
            state = "missing"
        end
    end
    if not repairBotText then
        repairBotText = durabilityFrame:CreateFontString(nil, "OVERLAY")
        -- Hidden FontStrings still require a font before their first SetText.
        repairBotText:SetFont(STSMmayor_GetUIFont(), 11, "OUTLINE")
    end
    if repairBotText:GetText() ~= text then repairBotText:SetText(text) end
    repairBotText:Hide()
    if robotDetectionText and robotDetectionText.botState ~= state then
        robotDetectionText.botState = state
        robotDetectionText:SetTextColor(r, g, b)
    end
    -- Checking existence need not invalidate UI textures when nothing changed.
    if robotIndicator and robotIndicator.Status ~= state then
        robotIndicator.Status = state
        robotIndicator.Tip = text
        robotIndicator.Icon:SetVertexColor(r, g, b, 1)
        robotIndicator:SetBackdropBorderColor(r, g, b, 1)
        if GameTooltip.IsOwned and GameTooltip:IsOwned(robotIndicator) then
            GameTooltip:SetText(text, r, g, b); GameTooltip:Show()
        end
    end
end

-- 检查是否为盾牌物品
function STSMmayor_IsOffHandItem(itemLink)
    if not itemLink then
        return false
    end
    
    -- 从物品链接中提取物品ID
    local _, _, itemID = string.find(itemLink, "item:(%d+):")
    if not itemID then
        return false
    end
    
    -- 获取物品信息
    local success, itemInfo = pcall(function()
        return {GetItemInfo(tonumber(itemID))}
    end)
    
    if not success or not itemInfo or table.getn(itemInfo) < 8 then
        return false
    end
    
    local equipLoc = itemInfo[8] -- WoW 1.12中字段8是装备位置字符串
    
    -- 只检查盾牌类型
    return equipLoc == "INVTYPE_SHIELD"
end

-- 单行操作面板；背景透明度与缩放单独保存，文字不随背景变淡。
function STSMmayor_GetUIFont()
    return (pfUI and pfUI.font_default) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
end

local function STSMmayor_FlatBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame:SetBackdropColor(0.08, 0.08, 0.08, 0.92)
    frame:SetBackdropBorderColor(0.28, 0.28, 0.28, 1)
end

function STSMmayor_LayoutFooter()
    if not durabilityFrame then return end
    -- Dependency and robot details live in tooltips, keeping the main panel one row.
    if autoRepairInteractHint then autoRepairInteractHint:Hide() end
    if repairBotText then repairBotText:Hide() end
    durabilityFrame:SetHeight(34)
end

function STSMmayor_ApplyAppearance()
    if not durabilityFrame then return end
    local function apply(frame)
        if not frame then return end
        local r, g, b = frame:GetBackdropColor()
        frame:SetBackdropColor(r or 0.08, g or 0.08, b or 0.08, STSMmayorDB.BackgroundAlpha)
    end
    -- pfUI buttons use a child backdrop, while its legacy root skin uses the frame.
    apply(durabilityFrame)
    for _, button in ipairs({equipButton, repairButton, pickupButton, STSMmayorSettingsButton, robotIndicator}) do
        apply(button.backdrop or button)
    end
end

function STSMmayor_SetUIScale(scale)
    if type(scale) ~= "number" or scale - scale ~= 0 then return end
    scale = math.max(0.5, math.min(scale, 1.5))
    if STSMmayorDB.UIScale == scale then return end
    STSMmayorDB.UIScale = scale
    -- The position frame and both frames' anchor offsets remain untouched.
    if durabilityFrame then durabilityFrame:SetScale(scale) end
end

function STSMmayor_SetPositionLocked(locked)
    STSMmayorDB.PositionLocked = locked and true or false
    if positionFrame then
        if isFrameMoving then
            STSMmayor_FinishMoving()
        end
        positionFrame:SetMovable(not STSMmayorDB.PositionLocked)
    end
    STSMmayor_SaveSettings()
end

function STSMmayor_ToggleAppearance()
    if appearanceFrame and appearanceFrame:IsShown() then appearanceFrame:Hide(); return end
    if not appearanceFrame then
        appearanceFrame = CreateFrame("Frame", "STSMmayorAppearanceFrame", UIParent)
        appearanceFrame:SetWidth(230)
        appearanceFrame:SetHeight(264)
        appearanceFrame:SetFrameStrata("DIALOG")
        appearanceFrame:SetClampedToScreen(true)
        appearanceFrame:EnableMouse(true)
        STSMmayor_FlatBackdrop(appearanceFrame)
        if pfUI and pfUI.api and pfUI.env and pfUI.env.C then
            pfUI.api.CreateBackdrop(appearanceFrame, nil, true)
        end
        -- The settings popup stays readable, even when the main panel is transparent.
        appearanceFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.94)
        local function makeCheck(name, label, y, enabled, callback)
            local button = CreateFrame("CheckButton", name, appearanceFrame, "UICheckButtonTemplate")
            button:SetWidth(14)
            button:SetHeight(14)
            button:SetPoint("TOPLEFT", appearanceFrame, "TOPLEFT", 13, y)
            button:SetChecked(enabled)
            button:SetScript("OnClick", callback)
            local text = appearanceFrame:CreateFontString(nil, "OVERLAY")
            text:SetFont(STSMmayor_GetUIFont(), 11, "OUTLINE")
            text:SetPoint("LEFT", button, "RIGHT", 3, 0)
            text:SetHeight(14)
            text:SetJustifyV("MIDDLE")
            text:SetText(label)
            text:SetTextColor(0.8, 0.8, 0.8)
            button.Label = text
            return button, text
        end
        autoSwapCheckButton, autoSwapText = makeCheck("STSMmayorAutoSwapCheck", "自动换盾", -16,
            STSMmayor_AutoSwapEnabled, function()
                STSMmayor_AutoSwapEnabled = not STSMmayor_AutoSwapEnabled
                autoSwapCheckButton:SetChecked(STSMmayor_AutoSwapEnabled)
                STSMmayor_SaveSettings()
                if STSMmayor_AutoSwapEnabled and STSMmayor_Enabled then
                    lastShieldDurability = -1
                    STSMmayor_CheckShield()
                end
            end)
        autoRepairCheckButton, autoRepairText = makeCheck("STSMmayorAutoRepairCheck", "自动修理", -42,
            STSMmayor_AutoRepairEnabled, function()
                STSMmayor_AutoRepairEnabled = not STSMmayor_AutoRepairEnabled
                autoRepairCheckButton:SetChecked(STSMmayor_AutoRepairEnabled)
                STSMmayor_SaveSettings()
                -- Enabling the option must not open an interaction. The regular
                -- durability check decides whether repair is actually needed.
            end)
        robotDetectionCheckButton, robotDetectionText = makeCheck("STSMmayorRobotDetectionCheck", "机器人检测", -68,
            STSMmayor_RobotDetectionEnabled, function()
                STSMmayor_RobotDetectionEnabled = not STSMmayor_RobotDetectionEnabled
                robotDetectionCheckButton:SetChecked(STSMmayor_RobotDetectionEnabled)
                STSMmayor_SetRepairBotEvents(STSMmayor_Enabled and STSMmayor_RobotDetectionEnabled)
                if not STSMmayor_RobotDetectionEnabled then STSMmayor_ResetRepairBots() end
                STSMmayor_UpdateRepairBotStatus()
                STSMmayor_SaveSettings()
            end)

        if pfUI and pfUI.api and pfUI.env and pfUI.env.C then
            local api = pfUI.api
            for _, button in ipairs({ autoSwapCheckButton, autoRepairCheckButton, robotDetectionCheckButton }) do
                api.SkinCheckbox(button)
                if button.backdrop then
                    button.backdrop:ClearAllPoints()
                    button.backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
                    button.backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
                end
                local checked = button:GetCheckedTexture()
                if checked then
                    checked:ClearAllPoints()
                    checked:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
                    checked:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
                end
            end
        end
        for _, button in ipairs({ autoSwapCheckButton, autoRepairCheckButton, robotDetectionCheckButton }) do
            button:SetHitRectInsets(0, button == robotDetectionCheckButton and -58 or -47, 0, 0)
        end
        robotDetectionCheckButton:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(STSMmayor_RobotDetectionEnabled and repairBotText and repairBotText:GetText()
                or "修理机器人检测已关闭", 0.9, 0.9, 0.9)
            GameTooltip:Show()
        end)
        robotDetectionCheckButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
        local function makeSlider(name, label, y, low, high, callback)
            local slider = CreateFrame("Slider", name, appearanceFrame)
            slider:SetWidth(204)
            slider:SetHeight(10)
            slider:SetPoint("TOPLEFT", appearanceFrame, "TOPLEFT", 13, y)
            slider:SetOrientation("HORIZONTAL")
            slider:SetMinMaxValues(low, high)
            slider:SetValueStep(1)
            slider:EnableMouse(true)
            STSMmayor_FlatBackdrop(slider)
            slider:SetThumbTexture("Interface\\Buttons\\WHITE8X8")
            local thumb = slider:GetThumbTexture()
            thumb:SetTexture(0.8, 0.7, 0.35, 1)
            thumb:SetWidth(8)
            thumb:SetHeight(16)
            slider.Label = slider:CreateFontString(nil, "OVERLAY")
            slider.Label:SetFont(STSMmayor_GetUIFont(), 11, "OUTLINE")
            slider.Label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 7)
            slider:SetScript("OnValueChanged", function()
                if appearanceFrame.syncing then return end
                local control = this
                local value = math.floor(control:GetValue() + 0.5)
                callback(value)
                control.Label:SetText(label .. ": " .. value .. "%")
                STSMmayor_ApplyAppearance()
                STSMmayor_SaveSettings()
            end)
            return slider
        end
        appearanceFrame.Transparency = makeSlider("STSMmayorTransparencySlider", "背景透明度", -120, 0, 100,
            function(value) STSMmayorDB.BackgroundAlpha = 1 - value / 100 end)
        appearanceFrame.Scale = makeSlider("STSMmayorScaleSlider", "界面大小", -172, 50, 150,
            function(value) STSMmayor_SetUIScale(value / 100) end)
        local lock = CreateFrame("CheckButton", "STSMmayorPositionLockCheck", appearanceFrame, "UICheckButtonTemplate")
        lock:SetWidth(14)
        lock:SetHeight(14)
        lock:SetPoint("TOPLEFT", appearanceFrame, "TOPLEFT", 13, -203)
        lock:SetHitRectInsets(0, -50, 0, 0)
        lock.Label = lock:CreateFontString(nil, "OVERLAY")
        lock.Label:SetFont(STSMmayor_GetUIFont(), 11, "OUTLINE")
        lock.Label:SetPoint("LEFT", lock, "RIGHT", 3, 0)
        lock.Label:SetHeight(14)
        lock.Label:SetJustifyV("MIDDLE")
        lock.Label:SetText("锁定位置")
        lock.Label:SetTextColor(0.9, 0.9, 0.9)
        if pfUI and pfUI.api and pfUI.env and pfUI.env.C then
            pfUI.api.SkinCheckbox(lock)
            if lock.backdrop then
                lock.backdrop:ClearAllPoints()
                lock.backdrop:SetPoint("TOPLEFT", lock, "TOPLEFT", 0, 0)
                lock.backdrop:SetPoint("BOTTOMRIGHT", lock, "BOTTOMRIGHT", 0, 0)
            end
            local checked = lock:GetCheckedTexture()
            if checked then
                checked:ClearAllPoints()
                checked:SetPoint("TOPLEFT", lock, "TOPLEFT", 2, -2)
                checked:SetPoint("BOTTOMRIGHT", lock, "BOTTOMRIGHT", -2, 2)
            end
        end
        lock:SetScript("OnClick", function()
            STSMmayor_SetPositionLocked(not STSMmayorDB.PositionLocked)
            lock:SetChecked(STSMmayorDB.PositionLocked)
        end)
        appearanceFrame.Lock = lock
        local close = CreateFrame("Button", "STSMmayorAppearanceClose", appearanceFrame, "UIPanelButtonTemplate")
        close:SetWidth(72)
        close:SetHeight(22)
        close:SetPoint("BOTTOM", appearanceFrame, "BOTTOM", 0, 8)
        close:SetNormalTexture("")
        close:SetPushedTexture("")
        close:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        close:GetHighlightTexture():SetVertexColor(0.7, 0.7, 0.7, 0.15)
        STSMmayor_FlatBackdrop(close)
        close:SetText("完成")
        close:GetFontString():SetFont(STSMmayor_GetUIFont(), 11, "OUTLINE")
        if pfUI and pfUI.api and pfUI.env and pfUI.env.C then
            pfUI.api.SkinButton(close, 0.45, 0.65, 0.85)
        end
        local label = close:GetFontString()
        label:ClearAllPoints()
        label:SetPoint("CENTER", close, "CENTER", 0, 0)
        label:SetJustifyH("CENTER")
        label:SetJustifyV("MIDDLE")
        close:SetScript("OnClick", function() appearanceFrame:Hide() end)
    end
    appearanceFrame.syncing = true
    local transparency = math.floor((1 - STSMmayorDB.BackgroundAlpha) * 100 + 0.5)
    local scale = math.floor(STSMmayorDB.UIScale * 100 + 0.5)
    appearanceFrame.Transparency:SetValue(transparency)
    appearanceFrame.Transparency.Label:SetText("背景透明度: " .. transparency .. "%")
    appearanceFrame.Scale:SetValue(scale)
    appearanceFrame.Scale.Label:SetText("界面大小: " .. scale .. "%")
    appearanceFrame.Lock:SetChecked(STSMmayorDB.PositionLocked)
    autoSwapCheckButton:SetChecked(STSMmayor_AutoSwapEnabled)
    autoRepairCheckButton:SetChecked(STSMmayor_AutoRepairEnabled)
    robotDetectionCheckButton:SetChecked(STSMmayor_RobotDetectionEnabled)
    STSMmayor_UpdateRepairBotStatus()
    appearanceFrame.syncing = false
    -- Independent of the scaled/movable panel: a slider cannot move under the
    -- cursor as a side effect of changing its own value.
    appearanceFrame:ClearAllPoints()
    appearanceFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    appearanceFrame:Show()
end

function STSMmayor_UpdateInteractButtons()
    if not repairButton or not pickupButton then return end
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()
    local available = hasInteract or hasWushuang
    for _, button in ipairs({ repairButton, pickupButton }) do
        button:Enable()
        button.Label:SetTextColor(available and 0.9 or 0.45, available and 0.9 or 0.45, available and 0.9 or 0.45)
        button:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            local tip = "未检测到 Interact 或无双拾取模组"
            if available then
                if this == repairButton then
                    tip = hasWushuang and "一键修理 (/STSMF) · 无双交互" or "一键修理 (/STSMF) · Interact"
                else
                    tip = hasInteract and "一键拾取 (/STSML) · Interact" or "一键拾取 (/STSML) · 无双交互"
                end
            end
            GameTooltip:SetText(tip, 0.9, 0.9, 0.9)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    repairButton:SetScript("OnClick", available and function() STSMmayor_AutoRepair() end or function() end)
    pickupButton:SetScript("OnClick", available and function() STSMmayor_AutoPickup() end or function() end)
    if autoRepairInteractHint then
        if available then autoRepairInteractHint:Hide() else autoRepairInteractHint:Show() end
    end
    STSMmayor_LayoutFooter()
end

function STSMmayor_CreateDurabilityFrame()
    if durabilityFrame then return durabilityFrame end
    STSMmayor_LoadSettings()
    positionFrame = CreateFrame("Frame", "STSMmayorPositionFrame", UIParent)
    positionFrame:SetWidth(1)
    positionFrame:SetHeight(1)
    positionFrame:SetFrameStrata("MEDIUM")
    positionFrame:SetMovable(not STSMmayorDB.PositionLocked)
    positionFrame:SetClampedToScreen(true)
    positionFrame:EnableMouse(false)
    durabilityFrame = CreateFrame("Frame", "STSMmayorDurabilityFrame", positionFrame)
    durabilityFrame:SetPoint("TOPLEFT", positionFrame, "TOPLEFT", 0, 0)
    durabilityFrame:SetWidth(320)
    durabilityFrame:SetHeight(34)
    durabilityFrame:SetFrameStrata("MEDIUM")
    durabilityFrame:SetScale(STSMmayorDB.UIScale)
    durabilityFrame:SetMovable(false)
    -- Clamping a scaled child can mutate its anchor in this client. Only the
    -- unscaled position frame participates in native movement and clamping.
    durabilityFrame:SetClampedToScreen(false)
    durabilityFrame:EnableMouse(true)
    durabilityFrame:RegisterForDrag("LeftButton")
    durabilityFrame:SetScript("OnDragStart", function()
        if STSMmayorDB.PositionLocked then return end
        if appearanceFrame then appearanceFrame:Hide() end
        isFrameMoving = true
        positionFrame:StartMoving()
    end)
    durabilityFrame:SetScript("OnDragStop", function()
        if not isFrameMoving then return end
        STSMmayor_FinishMoving()
    end)
    durabilityFrame:SetScript("OnHide", function()
        if isFrameMoving then
            STSMmayor_FinishMoving()
        end
        if appearanceFrame then appearanceFrame:Hide() end
    end)
    STSMmayor_FlatBackdrop(durabilityFrame)

    local function makeButton(name, label, x, callback)
        local button = CreateFrame("Button", name, durabilityFrame, "UIPanelButtonTemplate")
        button:SetWidth(32)
        button:SetHeight(24)
        button:SetPoint("LEFT", durabilityFrame, "LEFT", x, 0)
        button:SetNormalTexture("")
        button:SetPushedTexture("")
        button:SetDisabledTexture("")
        button:SetHighlightTexture("Interface\\Buttons\\WHITE8X8")
        button:GetHighlightTexture():SetVertexColor(0.7, 0.7, 0.7, 0.15)
        STSMmayor_FlatBackdrop(button)
        button:SetText(label)
        button.Label = button:GetFontString()
        button.Label:SetFont(STSMmayor_GetUIFont(), 12, "OUTLINE")
        button.Label:SetTextColor(0.9, 0.9, 0.9)
        button:SetScript("OnClick", callback)
        return button
    end
    equipButton = makeButton("STSMmayorEquipButton", "换盾", 118, function() STSMmayor_ManualEquip() end)
    repairButton = makeButton("STSMmayorRepairButton", "修理", 154, function() STSMmayor_AutoRepair() end)
    pickupButton = makeButton("STSMmayorPickupButton", "拾取", 190, function() STSMmayor_AutoPickup() end)
    equipButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("手动换盾 (/STSMC)", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    equipButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    robotIndicator = CreateFrame("Button", "STSMmayorRobotIndicator", durabilityFrame)
    robotIndicator:SetWidth(18)
    robotIndicator:SetHeight(18)
    robotIndicator:SetPoint("LEFT", durabilityFrame, "LEFT", 232, 0)
    robotIndicator:EnableMouse(true)
    STSMmayor_FlatBackdrop(robotIndicator)
    robotIndicator.Icon = robotIndicator:CreateTexture(nil, "ARTWORK")
    robotIndicator.Icon:SetPoint("TOPLEFT", robotIndicator, "TOPLEFT", 2, -2)
    robotIndicator.Icon:SetPoint("BOTTOMRIGHT", robotIndicator, "BOTTOMRIGHT", -2, 2)
    robotIndicator.Icon:SetTexture("Interface\\Icons\\INV_Gizmo_02")
    robotIndicator:SetScript("OnEnter", function()
        GameTooltip:SetOwner(robotIndicator, "ANCHOR_RIGHT")
        GameTooltip:SetText(robotIndicator.Tip or "修理机器人检测", 0.9, 0.9, 0.9)
        GameTooltip:Show()
    end)
    robotIndicator:SetScript("OnLeave", function() GameTooltip:Hide() end)

    STSMmayorSettingsButton = makeButton("STSMmayorSettingsButton", "设置", 260,
        function() STSMmayor_ToggleAppearance() end)
    STSMmayorSettingsButton:SetWidth(34)
    STSMmayorSettingsButton:SetHeight(20)
    STSMmayorSettingsButton:ClearAllPoints()
    STSMmayorSettingsButton:SetPoint("LEFT", durabilityFrame, "LEFT", 260, 0)

    closeButton = CreateFrame("Button", "STSMmayorCloseButton", durabilityFrame, "UIPanelButtonTemplate")
    closeButton:SetWidth(16)
    closeButton:SetHeight(16)
    closeButton:SetPoint("TOPRIGHT", durabilityFrame, "TOPRIGHT", -6, -8)
    closeButton:SetNormalTexture("")
    closeButton:SetPushedTexture("")
    closeButton:SetHighlightTexture("")
    closeButton:SetText("×")
    closeButton:SetFont(STSMmayor_GetUIFont(), 14, "OUTLINE")
    closeButton:GetFontString():SetTextColor(0.9, 0.35, 0.35)
    closeButton:SetScript("OnClick", function() STSMmayor_HideDurabilityFrame() end)

    durabilityText = durabilityFrame:CreateFontString(nil, "OVERLAY")
    durabilityText:SetFont(STSMmayor_GetUIFont(), 12, "OUTLINE")
    durabilityText:SetPoint("LEFT", durabilityFrame, "LEFT", 8, 0)
    durabilityText:SetHeight(24)
    durabilityText:SetJustifyV("MIDDLE")
    durabilityText:SetWidth(104)
    durabilityText:SetJustifyH("LEFT")
    durabilityText:SetText("未装备盾牌")

    autoRepairInteractHint = durabilityFrame:CreateFontString(nil, "OVERLAY")
    autoRepairInteractHint:SetFont(STSMmayor_GetUIFont(), 11, "OUTLINE")
    autoRepairInteractHint:SetWidth(296)
    autoRepairInteractHint:SetJustifyH("LEFT")
    autoRepairInteractHint:SetTextColor(0.85, 0.45, 0.35)
    autoRepairInteractHint:SetText("拾取与修理不可用：未加载交互模组")
    autoRepairInteractHint:Hide()

    if pfUI and pfUI.api and pfUI.env and pfUI.env.C then
        local api = pfUI.api
        api.CreateBackdrop(durabilityFrame, nil, true)
        for _, button in ipairs({ equipButton, repairButton, pickupButton, STSMmayorSettingsButton }) do
            api.SkinButton(button, 0.45, 0.65, 0.85)
            button.Label:SetFont(STSMmayor_GetUIFont(), 12, "OUTLINE")
        end
        api.SkinCloseButton(closeButton, durabilityFrame, -6, -8)
        closeButton:SetText("")
    end
    for _, button in ipairs({ equipButton, repairButton, pickupButton, STSMmayorSettingsButton }) do
        button.Label:ClearAllPoints()
        button.Label:SetPoint("CENTER", button, "CENTER", 0, 0)
        button.Label:SetJustifyH("CENTER")
        button.Label:SetJustifyV("MIDDLE")
    end
    closeButton:ClearAllPoints()
    closeButton:SetPoint("RIGHT", durabilityFrame, "RIGHT", -6, 0)
    if not closeButton.icon then
        local label = closeButton:GetFontString()
        label:ClearAllPoints()
        label:SetPoint("CENTER", closeButton, "CENTER", 0, 0)
    end
    STSMmayor_UpdateInteractButtons()
    STSMmayor_ApplyAppearance()
    STSMmayor_UpdateRepairBotStatus()
    STSMmayor_RestorePosition()
    durabilityFrame:Hide()
    return durabilityFrame
end


-- 更新耐久度显示
function STSMmayor_UpdateDurabilityDisplay()
    if not durabilityFrame or not durabilityText then
        return
    end
    
    -- 检查副手装备
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if slotID then
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            if STSMmayor_IsOffHandItem(itemLink) then
                -- 获取耐久度信息（使用兼容函数）
                local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
                if durability and maxDurability and maxDurability > 0 then
                    local durabilityPercent = math.floor((durability / maxDurability) * 100)
                    local r, g, b = 1, 1, 1 -- 默认白色
                    
                    -- 根据耐久度设置颜色
                    if durabilityPercent < 30 then
                        r, g, b = 1, 0, 0 -- 红色
                    elseif durabilityPercent < 60 then
                        r, g, b = 1, 0.5, 0 -- 橙色
                    elseif durabilityPercent < 75 then
                        r, g, b = 1, 1, 0 -- 黄色
                    else
                        r, g, b = 0, 1, 0 -- 绿色
                    end
                    
                    durabilityText:SetTextColor(r, g, b)
                    durabilityText:SetText(durability .. "/" .. maxDurability .. " (" .. durabilityPercent .. "%)")
                    
                    -- 检查是否需要自动修理（耐久低于30%）
                    if STSMmayor_AutoRepairEnabled and durabilityPercent < AUTO_REPAIR_THRESHOLD then
                        STSMmayor_AutoRepair()
                    end
                else
                    durabilityText:SetTextColor(1, 1, 1) -- 白色
                    durabilityText:SetText("盾牌: 未知耐久")
                end
            else
                durabilityText:SetTextColor(1, 1, 0) -- 黄色
                durabilityText:SetText("非盾牌物品")
            end
        else
            durabilityText:SetTextColor(1, 1, 0) -- 黄色
            durabilityText:SetText("未装备盾牌")
        end
    else
        durabilityText:SetTextColor(1, 0, 0) -- 红色
        durabilityText:SetText("错误")
    end
end

-- 显示耐久度监控窗口
function STSMmayor_ShowDurabilityFrame()
    if not durabilityFrame then
        STSMmayor_CreateDurabilityFrame()
    end

    durabilityFrame:Show()
    isDurabilityFrameVisible = true
    STSMmayor_UpdateDurabilityDisplay() -- 恢复更新显示
    STSMmayor_UpdateInteractButtons()
    STSMmayor_UpdateRepairBotStatus()
    STSMmayor_SaveSettings()
end

-- 隐藏耐久度监控窗口
function STSMmayor_HideDurabilityFrame()
    if durabilityFrame then
        durabilityFrame:Hide()
    end
    isDurabilityFrameVisible = false
    STSMmayor_SaveSettings()
end

-- 切换耐久度监控窗口的显示状态
function STSMmayor_ToggleDurabilityFrame()
    if isDurabilityFrameVisible then
        STSMmayor_HideDurabilityFrame()
    else
        STSMmayor_ShowDurabilityFrame()
    end
end

-- 事件注册
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGOUT")
f:RegisterEvent("UNIT_INVENTORY_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("UPDATE_INVENTORY_DURABILITY") -- 专门检测耐久度变化的事件

-- 创建定期检查耐久度的定时器
local durabilityChecker = CreateFrame("Frame")
durabilityChecker:SetScript("OnUpdate", function()
    -- 只在插件启用时执行检查
    if not STSMmayor_Enabled then
        return
    end
    
    local elapsed = arg1
    local currentTime = GetTime()
    if currentTime - lastDurabilityCheckTime >= DURABILITY_CHECK_INTERVAL then
        lastDurabilityCheckTime = currentTime
        -- 定期检查耐久度并更新显示
        STSMmayor_UpdateDurabilityDisplay()
        STSMmayor_CheckShield()
    end
end)

-- 合并为一套初始化流程，兼容 1.12 的全局 event/arg1。
function STSMmayor_SetEnabled(enabled)
    STSMmayor_LoadSettings()
    STSMmayor_Enabled = enabled and true or false
    if STSMmayor_Enabled then
        STSMmayor_SetRepairBotEvents(STSMmayor_RobotDetectionEnabled)
        STSMmayor_ShowDurabilityFrame()
        STSMmayor_CheckShield()
        STSMmayor_StartBagCheckTimer()
    else
        STSMmayor_SetRepairBotEvents(false)
        STSMmayor_HideDurabilityFrame()
        STSMmayor_StopBagCheckTimer()
    end
    STSMmayor_SaveSettings()
end

f:SetScript("OnEvent", function(selfArg, eventArg, unitArg)
    local currentEvent = eventArg or event
    local currentUnit = unitArg or arg1
    if currentEvent == "ADDON_LOADED" and currentUnit == "STSMmayor" then
        STSMmayor_LoadSettings()
    elseif currentEvent == "PLAYER_LOGOUT" then
        -- Reloading while still dragging must capture the final location too.
        if positionFrame and isFrameMoving then
            positionFrame:StopMovingOrSizing()
            isFrameMoving = false
        end
        STSMmayor_SaveSettings()
    elseif (currentEvent == "UNIT_INVENTORY_CHANGED" and currentUnit == "player")
        or currentEvent == "UPDATE_INVENTORY_DURABILITY" then
        if not startupComplete then return end
        if currentEvent == "UNIT_INVENTORY_CHANGED" and STSMmayor_ForceReactiveDiskJustEquipped() then
            STSMmayor_SetEnabled(true)
            return
        end
        STSMmayor_UpdateDurabilityDisplay()
        if STSMmayor_Enabled then STSMmayor_CheckShield() end
    elseif currentEvent == "PLAYER_ENTERING_WORLD" then
        STSMmayor_LoadSettings()
        if startupComplete then
            if STSMmayor_ForceReactiveDiskJustEquipped() then
                STSMmayor_SetEnabled(true)
                return
            end
            STSMmayor_UpdateDurabilityDisplay()
            if STSMmayor_Enabled then STSMmayor_CheckShield() end
            return
        end
        if startupFrame then return end
        startupFrame = CreateFrame("Frame")
        local restoreAt = GetTime() + 2
        startupFrame:SetScript("OnUpdate", function()
            if GetTime() < restoreAt then return end
            startupFrame:SetScript("OnUpdate", nil)
            startupFrame:Hide()
            startupComplete = true
            -- An equipped disk explicitly enables the addon on login/reload.
            -- Automatic repair/swap choices and the saved position remain intact.
            if STSMmayor_ForceReactiveDiskJustEquipped() then
                STSMmayor_Enabled = true
                STSMmayorDB.Visible = true
            elseif STSMmayorDB.Enabled == nil then
                STSMmayor_Enabled = STSMmayor_IsInTargetZone() and true or false
            end
            local showWindow = STSMmayorDB.Visible
            if type(showWindow) ~= "boolean" then showWindow = STSMmayor_Enabled end
            STSMmayor_SetRepairBotEvents(STSMmayor_Enabled and STSMmayor_RobotDetectionEnabled)
            if STSMmayor_Enabled or showWindow then STSMmayor_CreateDurabilityFrame() end
            if showWindow then STSMmayor_ShowDurabilityFrame() end
            if STSMmayor_Enabled then
                STSMmayor_CheckShield()
                STSMmayor_StartBagCheckTimer()
            end
            STSMmayor_SaveSettings()
        end)
    end
end)

-- 获取背包物品耐久度的函数（使用Gratuity-2.0库提高性能）
function STSMmayor_GetContainerItemDurability(bag, slot)
    if not gratuity then
        return nil, nil
    end
    
    -- 使用Gratuity库获取背包物品的tooltip信息
    gratuity:SetBagItem(bag, slot)
    
    -- 使用FindDeformat方法查找耐久度信息（支持多语言）
    local durability, maxDurability = gratuity:FindDeformat(DURABILITY_TEMPLATE)
    if durability and maxDurability then
        return tonumber(durability), tonumber(maxDurability)
    end
    
    -- 备用方案：如果FindDeformat失败，尝试手动扫描
    for i = 1, gratuity:NumLines() do
        local tooltipText = gratuity:GetLine(i)
        if tooltipText then
            -- 查找耐久度格式 "耐久度 XX / XX"
            local _, _, current, max = string.find(tooltipText, "耐久度 (%d+) / (%d+)")
            if current and max then
                return tonumber(current), tonumber(max)
            end
            
            -- 也查找英文格式 "Durability XX / XX"
            local _, _, current2, max2 = string.find(tooltipText, "Durability (%d+) / (%d+)")
            if current2 and max2 then
                return tonumber(current2), tonumber(max2)
            end
        end
    end
    
    return nil, nil
end

-- 获取装备耐久度的函数（使用Gratuity-2.0库提高性能）
function STSMmayor_GetInventoryDurability(slotID)
    if not gratuity then
        return nil, nil
    end
    
    -- 使用Gratuity库获取装备物品的tooltip信息
    gratuity:SetInventoryItem("player", slotID)
    
    -- 使用FindDeformat方法查找耐久度信息（支持多语言）
    local durability, maxDurability = gratuity:FindDeformat(DURABILITY_TEMPLATE)
    if durability and maxDurability then
        return tonumber(durability), tonumber(maxDurability)
    end
    
    -- 备用方案：如果FindDeformat失败，尝试手动扫描
    for i = 1, gratuity:NumLines() do
        local tooltipText = gratuity:GetLine(i)
        if tooltipText then
            -- 查找耐久度格式 "耐久度 XX / XX"
            local _, _, current, max = string.find(tooltipText, "耐久度 (%d+) / (%d+)")
            if current and max then
                return tonumber(current), tonumber(max)
            end
            
            -- 也查找英文格式 "Durability XX / XX"
            local _, _, current2, max2 = string.find(tooltipText, "Durability (%d+) / (%d+)")
            if current2 and max2 then
                return tonumber(current2), tonumber(max2)
            end
        end
    end
    
    return nil, nil
end

-- 检查盾牌耐久度
function STSMmayor_CheckShield()
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    local itemLink = GetInventoryItemLink("player", slotID)
    
    if not itemLink then
        -- 如果没有装备，重置上次耐久度
        lastShieldDurability = -1
        return
    end
    
    -- 检查是否是盾牌
    if STSMmayor_IsOffHandItem(itemLink) then
        -- 获取耐久度信息（使用兼容函数）
        local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
        
        if durability and maxDurability and maxDurability > 0 then
            local durabilityPercent = durability / maxDurability
            
            -- 只在耐久度发生变化时输出信息，避免刷屏
            if durability ~= lastShieldDurability then
                
                -- 检查是否需要换盾（耐久度小于等于自动换盾阈值）
                if durability <= AUTO_SWAP_THRESHOLD then
                    if STSMmayor_AutoSwapEnabled then
                        STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 盾牌耐久过低（" .. durability .. "点），自动更换中...")
                        lastShieldDurability = durability
                        equipFailed = true -- 标记换装失败状态，需要重检
                        
                        -- 尝试自动换盾
                        local swapSuccess = STSMmayor_AutoEquipShield()
                        if not swapSuccess then
                            STSMmayor_Print(ERROR_COLOR .. "✗ 自动换盾失败，请手动检查背包中的盾牌")
                        end
                    else
                        STSMmayor_Print(WARNING_COLOR .. "⚠ 盾牌耐久过低（" .. durability .. "点），请尽快手动更换盾牌或修理")
                    end
                elseif durability <= REPAIR_WARNING_THRESHOLD then -- 耐久度在阈值之间时警告
                    STSMmayor_Print(WARNING_COLOR .. "⚠ 盾牌耐久偏低（" .. durability .. "点），请注意准备更换")
                elseif durability < 10 then -- 保留原有的低耐久警告
                    STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 盾牌耐久度仅剩 " .. durability .. " 点！")
                end
                
                lastShieldDurability = durability
            end
        else
            if lastShieldDurability ~= 0 then
                STSMmayor_Print(WARNING_COLOR .. "无法获取盾牌耐久度信息")
                lastShieldDurability = 0
            end
        end
    else
        if lastShieldDurability ~= -2 then
            STSMmayor_Print(WARNING_COLOR .. "副手装备的不是盾牌")
            lastShieldDurability = -2
        end
    end
end

-- 自动换盾功能
function STSMmayor_AutoEquipShield()
    -- 防止频繁换装
    local currentTime = GetTime()
    if currentTime - lastEquipAttempt < EQUIP_COOLDOWN then
        STSMmayor_Print(WARNING_COLOR .. "换装冷却中，请稍后再试...")
        return
    end
    lastEquipAttempt = currentTime
    
    STSMmayor_Print(CHAT_COLOR .. "开始寻找可替换的盾牌...")
    
    -- 扫描背包前8个格子寻找耐久度最好的盾牌（从左到右，跳过耐久为0的）
    local bestShield = nil
    local bestDurabilityPercent = 0
    local bestBag, bestSlot = nil, nil
    local shieldCandidates = {}
    
    for bag = 0, 0 do -- 只检查背包0号包
        local success, numSlots = pcall(GetContainerNumSlots, bag)
        if success and numSlots then
            for slot = 1, math.min(8, numSlots) do -- 从左到右检查前8个格子
                local success2, itemLink = pcall(GetContainerItemLink, bag, slot)
                if success2 and itemLink and STSMmayor_IsOffHandItem(itemLink) then
                    -- 检查这个盾牌的耐久度
                    local _, _, itemID = string.find(itemLink, "item:(%d+):")
                    if itemID then
                        local durability, maxDurability = STSMmayor_GetContainerItemDurability(bag, slot)
                        local durabilityPercent = 0
                        
                        if durability and maxDurability and maxDurability > 0 then
                            durabilityPercent = durability / maxDurability
                            
                            -- 跳过耐久度低于自动换盾阈值的盾牌
                            if durability < AUTO_SWAP_THRESHOLD then
                                STSMmayor_Print(REPAIR_WARNING_COLOR .. "跳过第" .. slot .. "格低耐久盾牌：" .. itemLink .. "（" .. durability .. "点）")
                            else
                                table.insert(shieldCandidates, {
                                    link = itemLink,
                                    bag = bag,
                                    slot = slot,
                                    durabilityPercent = durabilityPercent,
                                    durability = durability or 0,
                                    maxDurability = maxDurability or 1
                                })
                                
                                -- 选择耐久度最高的盾牌（如果耐久度相同，选择更靠左的）
                                if durabilityPercent > bestDurabilityPercent then
                                    bestDurabilityPercent = durabilityPercent
                                    bestShield = itemLink
                                    bestBag = bag
                                    bestSlot = slot
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- 显示找到的盾牌候选
    if table.getn(shieldCandidates) > 0 then
        STSMmayor_Print(CHAT_COLOR .. "找到 " .. table.getn(shieldCandidates) .. " 个候选盾牌：")
        for i, candidate in ipairs(shieldCandidates) do
            local status = ""
            if candidate.durabilityPercent > 0.75 then
                status = CHAT_COLOR .. "(优秀)"
            elseif candidate.durabilityPercent > 0.5 then
                status = WARNING_COLOR .. "(良好)"
            elseif candidate.durabilityPercent > 0.25 then
                status = REPAIR_WARNING_COLOR .. "(较差)"
            else
                status = ERROR_COLOR .. "(破损)"
            end
            
            STSMmayor_Print("  背包第" .. candidate.slot .. "格: " .. candidate.link .. " " .. status .. 
                          " 耐久:" .. candidate.durability .. "/" .. candidate.maxDurability .. 
                          " (" .. math.floor(candidate.durabilityPercent * 100) .. "%)")
        end
    end
    
    -- 装备最好的盾牌
    if bestShield and bestDurabilityPercent > 0 then -- 只要耐久度大于0就可以换
        STSMmayor_Print(CHAT_COLOR .. "选择最佳盾牌：" .. bestShield .. " (耐久度：" .. math.floor(bestDurabilityPercent * 100) .. "%)")
        
        -- 装备盾牌
        PickupContainerItem(bestBag, bestSlot)
        PickupInventoryItem(GetInventorySlotInfo("SecondaryHandSlot"))
        
        STSMmayor_Print(CHAT_COLOR .. "自动换盾完成！")
        equipFailed = false -- 重置失败标记
        return true
    else
        STSMmayor_Print(WARNING_COLOR .. "背包中没有找到可用的盾牌（耐久度需≥15点）")
        STSMmayor_Print(WARNING_COLOR .. "请将可用的盾牌放置到背包前8个格子中")
        equipFailed = true -- 标记换装失败
        return false
    end
end

-- 生成并显示盾牌状态报告
function STSMmayor_GenerateShieldReport()
    -- 检查当前副手装备
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if slotID then
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            if STSMmayor_IsOffHandItem(itemLink) then
                -- 显示耐久度信息（使用兼容函数）
                local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
                if durability and maxDurability and maxDurability > 0 then
                    local durabilityPercent = math.floor((durability / maxDurability) * 100)
                    STSMmayor_Print(CHAT_COLOR .. "当前副手：" .. itemLink .. " 耐久：" .. durability .. "/" .. maxDurability .. " (" .. durabilityPercent .. "%)")
                else
                    STSMmayor_Print(CHAT_COLOR .. "当前副手：" .. itemLink .. " 耐久：未知")
                end
            else
                STSMmayor_Print(WARNING_COLOR .. "当前副手未装备盾牌")
            end
        else
            STSMmayor_Print(WARNING_COLOR .. "当前副手未装备盾牌")
        end
    else
        STSMmayor_Print(ERROR_COLOR .. "无法获取副手槽位信息")
    end
    
    -- 扫描背包前8个格子中的盾牌物品
    local shieldCount = 0
    for bag = 0, 0 do -- 只检查背包0号包
        local success, numSlots = pcall(GetContainerNumSlots, bag)
        if success and numSlots then
            for slot = 1, math.min(8, numSlots) do -- 只检查前8个格子
                local success2, itemLink = pcall(GetContainerItemLink, bag, slot)
                if success2 and itemLink and STSMmayor_IsOffHandItem(itemLink) then
                    shieldCount = shieldCount + 1
                    -- 获取耐久度
                    local durability, maxDurability = STSMmayor_GetContainerItemDurability(bag, slot)
                    local durabilityText = ""
                    if durability and maxDurability and maxDurability > 0 then
                        local durabilityPercent = math.floor((durability / maxDurability) * 100)
                        durabilityText = " 耐久：" .. durability .. "/" .. maxDurability .. " (" .. durabilityPercent .. "%)"
                    else
                        durabilityText = " 耐久：未知"
                    end
                    STSMmayor_Print(CHAT_COLOR .. "背包第" .. slot .. "格：" .. itemLink .. durabilityText)
                end
            end
        end
    end
    
    if shieldCount == 0 then
        STSMmayor_Print(WARNING_COLOR .. "背包前8格未找到盾牌，请将可用盾牌放置到前8个格子中")
    end
end

-- 检查并重试换装（如果之前失败）
function STSMmayor_CheckAndRetryEquip()
    if not equipFailed then
        return -- 如果上次没有失败，不需要重试
    end
    
    -- 首先检查当前副手装备的耐久度（这是重要的检查）
    local slotID = GetInventorySlotInfo("SecondaryHandSlot")
    if slotID then
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink and STSMmayor_IsOffHandItem(itemLink) then
            local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
            if durability and maxDurability then
                if durability > AUTO_SWAP_THRESHOLD then
                    equipFailed = false -- 盾牌确实有耐久，重置失败标记
                    STSMmayor_Print(CHAT_COLOR .. "当前盾牌已修复，无需更换")
                    return
                else
                    -- 当前盾牌耐久仍低于阈值，需要继续尝试换装
                    STSMmayor_Print(REPAIR_WARNING_COLOR .. "当前盾牌耐久仍为" .. durability .. "点，继续寻找替换...")
                end
            else
                -- 无法获取耐久信息，假设仍有问题
                STSMmayor_Print(WARNING_COLOR .. "无法检测当前盾牌耐久度，继续监控...")
            end
        else
            -- 副手不是盾牌或未装备，需要换装
            STSMmayor_Print(WARNING_COLOR .. "副手未装备盾牌，尝试换装...")
        end
    else
        -- 无法获取副手信息
        STSMmayor_Print(ERROR_COLOR .. "无法获取副手信息，继续监控...")
        return
    end
    
    -- 只有确认当前盾牌有问题时才尝试重新换装
    STSMmayor_Print(CHAT_COLOR .. "检查背包中是否有可用的盾牌...")
    local success = STSMmayor_AutoEquipShield()
    if success then
        equipFailed = false -- 换装成功，重置失败标记
    else
        STSMmayor_Print(WARNING_COLOR .. "请将可用的盾牌放置到背包前8个格子中，系统将自动检测")
    end
end

-- 检查背包中的装备耐久度
function STSMmayor_CheckBagForBrokenShields()
    local hasBrokenShield = false
    local brokenShields = {}
    
    -- 检查背包前8个格子
    for bag = 0, 0 do -- 只检查背包，不检查银行包
        for slot = 1, 8 do -- 只检查前8个格子
            local success, itemLink = pcall(GetContainerItemLink, bag, slot)
            if success and itemLink and STSMmayor_IsOffHandItem(itemLink) then
                -- 检查这个盾牌的耐久度
                local durability, maxDurability = STSMmayor_GetContainerItemDurability(bag, slot)
                if durability and maxDurability and durability < AUTO_SWAP_THRESHOLD then
                    -- 获取物品名称
                    local _, _, itemID = string.find(itemLink, "item:(%d+):")
                    local itemName = "未知盾牌"
                    if itemID then
                        local success2, itemInfo = pcall(function()
                            return {GetItemInfo(tonumber(itemID))}
                        end)
                        if success2 and itemInfo and itemInfo[1] then
                            itemName = itemInfo[1]
                        end
                    end
                    
                    -- 记录破损盾牌信息
                    table.insert(brokenShields, {
                        slot = slot,
                        name = itemName,
                        durability = durability,
                        itemID = itemID
                    })
                    
                    hasBrokenShield = true
                end
            end
        end
    end
    
    -- 只在第一次检测到破损盾牌时显示警告
    if hasBrokenShield and not hadBrokenShield then
        STSMmayor_Print(REPAIR_WARNING_COLOR .. "⚠ 警告：背包中发现破损盾牌，请及时修理！")
        -- 显示详细的破损盾牌列表
        for _, shield in ipairs(brokenShields) do
            if shield.durability == 0 then
                STSMmayor_Print(REPAIR_WARNING_COLOR .. "  背包第" .. shield.slot .. "格：" .. shield.name .. " 已破损（耐久度为0）")
            else
                STSMmayor_Print(REPAIR_WARNING_COLOR .. "  背包第" .. shield.slot .. "格：" .. shield.name .. " 耐久过低（" .. shield.durability .. "点）")
            end
        end
    end
    
    -- 检测盾牌修复情况
    if hadBrokenShield and not hasBrokenShield then
        STSMmayor_Print(CHAT_COLOR .. "背包中的破损盾牌已全部修复！")
    end
    
    -- 更新破损盾牌状态
    hadBrokenShield = hasBrokenShield
    
    -- 同时检查身上盾牌是否需要更换（如果之前更换失败）
    STSMmayor_CheckAndRetryEquip()
    
    return hasBrokenShield
end

-- 打印消息
function STSMmayor_Print(message)
    DEFAULT_CHAT_FRAME:AddMessage(CHAT_COLOR .. "[STSMmayor] " .. message)
end

-- 打印两个拾取模组（Interact / 无双拾取）的载入情况
function STSMmayor_PrintLootStatus()
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()
    local function modTag(ok)
        if ok then
            return "|cff00ff00已加载|r"
        else
            return "|cffff4040未加载|r"
        end
    end
    STSMmayor_Print("拾取模组检测：Interact " .. modTag(hasInteract) .. CHAT_COLOR
        .. "，无双拾取 " .. modTag(hasWushuang))
    if not hasInteract and not hasWushuang then
        STSMmayor_Print(WARNING_COLOR .. "两个拾取模组均未加载，拾/修按钮不可用，请安装Interact或无双拾取")
    end
end

-- 检测是否在目标区域（斯坦索姆、东瘟疫之地或东墙大门）
function STSMmayor_IsInTargetZone()
    local zoneName = GetRealZoneText() or GetZoneText() or ""
    local subZoneName = GetSubZoneText() or ""
    
    -- 检查是否在斯坦索姆、东瘟疫之地或东墙大门（支持中英文名称）
    local lowerZone = strlower(zoneName)
    local lowerSubZone = strlower(subZoneName)
    
    local result = strfind(lowerZone, "斯坦索姆") or strfind(lowerSubZone, "斯坦索姆") or 
                   strfind(lowerZone, "stratholme") or strfind(lowerSubZone, "stratholme") or
                   strfind(lowerZone, "东瘟疫之地") or strfind(lowerSubZone, "东瘟疫之地") or
                   strfind(lowerZone, "eastern plaguelands") or strfind(lowerSubZone, "eastern plaguelands") or
                   strfind(lowerZone, "东墙大门") or strfind(lowerSubZone, "东墙大门") or
                   strfind(lowerZone, "eastern wall") or strfind(lowerSubZone, "eastern wall")
    
    return result
end

-- 手动换装命令
function STSMmayor_ManualEquip()
    if not STSMmayor_Enabled then
        STSMmayor_Print(ERROR_COLOR .. "插件当前处于关闭状态，请先使用/STSM命令开启插件")
        return
    end
    
    STSMmayor_Print("手动执行盾牌换装...")
    local success = STSMmayor_AutoEquipShield()
    
    -- 换装后延迟刷新信息
    if success then
        -- 延迟1秒后刷新显示，确保装备信息已更新
        local refreshFrame = CreateFrame("Frame")
        local refreshAt = GetTime() + 1
        refreshFrame:SetScript("OnUpdate", function()
            if GetTime() >= refreshAt then
                STSMmayor_UpdateDurabilityDisplay()
                STSMmayor_CheckShield()
                this:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- 检测Interact模组是否加载
function STSMmayor_IsInteractLoaded()
    -- 使用更精确的检测方法，参考dimino插件中的实现
    return type(Interact) == "function" or (Interact and (type(Interact.Version) == "function" or Interact.Version ~= nil))
end

-- 检测无双拾取模组是否加载
-- 参考diminfo插件Loaddll.lua：wsloot.dll注入后会注册全局WSLoot表
function STSMmayor_IsWushuangLoaded()
    if type(WSLoot) == "table" then
        return true
    end
    -- WSLoot表由wsloot.dll在首次调用UnitXP时注册（与无双交互插件EnsureRegistered逻辑一致）
    -- 主动触发一次，避免DLL已注入但表尚未注册时误判
    if type(UnitXP) == "function" then
        pcall(UnitXP, "player")
    end
    return type(WSLoot) == "table"
end

-- 执行一次无双拾取交互（等价于在聊天框输入 /无双交互 命令）
function STSMmayor_DoWushuangInteract()
    -- 优先走无双交互插件的斜杠命令处理器（内部含DLL注册检测与分类掩码同步，与手动输入/无双交互完全一致）
    if type(SlashCmdList) == "table" and type(SlashCmdList.WSLoot) == "function" then
        SlashCmdList.WSLoot()
        return true
    end
    -- 兜底：未安装无双交互插件但wsloot.dll已注册WSLoot表时，直接调用DLL
    if type(WSLoot) ~= "table" and type(UnitXP) == "function" then
        pcall(UnitXP, "player")
    end
    if type(WSLoot) == "table" and type(WSLoot.Loot) == "function" then
        WSLoot.Loot()
        return true
    end
    return false
end

-- 自动修理功能
function STSMmayor_AutoRepair()
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()

    -- 两个拾取模组都未检测到时才报错
    if not hasInteract and not hasWushuang then
        STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动修理功能无效")
        return false
    end

    -- 修按钮路由：装了无双拾取（无论是否同时装了Interact）都用/无双交互与商人交互修理；
    -- 仅装Interact时沿用旧逻辑 Interact(1)
    if hasWushuang and STSMmayor_DoWushuangInteract() then
        return true
    end

    if hasInteract then
        Interact(1)
        return true
    end

    STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动修理功能无效")
    return false
end

-- 自动拾取功能
function STSMmayor_AutoPickup()
    local hasInteract = STSMmayor_IsInteractLoaded()
    local hasWushuang = STSMmayor_IsWushuangLoaded()

    -- 两个拾取模组都未检测到时才报错
    if not hasInteract and not hasWushuang then
        STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动拾取功能无效")
        return false
    end

    -- 拾按钮路由：只要装了Interact就用Interact(0)（两个模组都装时拾按钮归Interact）；
    -- 仅装无双拾取时才用/无双交互
    if hasInteract then
        Interact(0)
        return true
    end

    if hasWushuang and STSMmayor_DoWushuangInteract() then
        return true
    end

    STSMmayor_Print(ERROR_COLOR .. "未检测到任何拾取模组，自动拾取功能无效")
    return false
end

-- 命令处理
SLASH_STSM1 = "/STSM"
SLASH_STSMC1 = "/STSMC"
SLASH_STSMSHOW1 = "/STSMSHOW"
SLASH_STSMHIDE1 = "/STSMHIDE"

-- 修理命令
SLASH_STSMF1 = "/STSMF"

-- 拾取命令
SLASH_STSML1 = "/STSML"

-- 检查命令
SLASH_STSMcheck1 = "/STSMcheck"

SlashCmdList["STSMSHOW"] = function(msg)
    STSMmayor_ShowDurabilityFrame()
end

SlashCmdList["STSMHIDE"] = function(msg)
    STSMmayor_HideDurabilityFrame()
end

-- 开始背包检查定时器
function STSMmayor_StartBagCheckTimer()
    if bagCheckTimer then
        return
    end
    
    lastBagCheckTime = GetTime()
    bagCheckTimer = CreateFrame("Frame")
    bagCheckTimer:SetScript("OnUpdate", function()
        local now = GetTime()
        if now - lastBagCheckTime >= BAG_CHECK_INTERVAL then
            lastBagCheckTime = now
            STSMmayor_CheckBagForBrokenShields()
            
            -- 添加自动修理检查
            if STSMmayor_AutoRepairEnabled then
                local slotID = GetInventorySlotInfo("SecondaryHandSlot")
                if slotID then
                    local itemLink = GetInventoryItemLink("player", slotID)
                    if itemLink and STSMmayor_IsOffHandItem(itemLink) then
                        local durability, maxDurability = STSMmayor_GetInventoryDurability(slotID)
                        if durability and maxDurability and maxDurability > 0 then
                            local durabilityPercent = math.floor((durability / maxDurability) * 100)
                            if durabilityPercent < AUTO_REPAIR_THRESHOLD then
                                STSMmayor_AutoRepair()
                            end
                        end
                    end
                end
            end
            
            -- 检查修理机器人状态
            STSMmayor_UpdateRepairBotStatus()

            -- 刷新拾取模组按钮状态（无双DLL可能在窗口打开后才连接成功，复用20秒定时器，不新增OnUpdate）
            STSMmayor_UpdateInteractButtons()
        end
    end)
end

-- 停止背包检查定时器
function STSMmayor_StopBagCheckTimer()
    if bagCheckTimer then
        bagCheckTimer:Hide()
        bagCheckTimer:SetScript("OnUpdate", nil)
        bagCheckTimer = nil
    end
    lastBagCheckTime = 0
end

SlashCmdList["STSM"] = function(msg)
    STSMmayor_SetEnabled(not STSMmayor_Enabled)
end

SlashCmdList["STSMC"] = function(msg)
    STSMmayor_ManualEquip()
end

SlashCmdList["STSMF"] = function()
    STSMmayor_AutoRepair()
end

SlashCmdList["STSML"] = function()
    STSMmayor_AutoPickup()
end

SlashCmdList["STSMcheck"] = function()
    STSMmayor_CheckBagForBrokenShields()
end


-- Recover a position saved by an earlier scaling bug without resetting preferences.
SLASH_STSMPOS1 = "/stsmpos"
SlashCmdList["STSMPOS"] = function() STSMmayor_ResetPosition() end
