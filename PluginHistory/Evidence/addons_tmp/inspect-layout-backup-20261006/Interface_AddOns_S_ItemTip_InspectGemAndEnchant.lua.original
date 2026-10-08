--显示附魔图标
--基于扫描和缓存的实现
--1.12 版本只有附魔，没有宝石系统
--性能优化：GUID永久缓存、立即执行（类似 MerInspect）

-- 持久化缓存（保存到 SavedVariables，永久缓存不清理）
-- 格式：itemLink -> {enchantName, timestamp}
S_ItemTip_EnchantCache = S_ItemTip_EnchantCache or {}

-- 单位GUID缓存（永久缓存，类似 MerInspect 的 guids 表）
local unitGuidCache = {}
local scanningUnit = nil
local taskTimer = 0  -- 任务调度器计时器
local taskQueue = {}  -- 任务队列

-- 工程附魔ID列表（瞄准镜、盾刺、马刺等）
local EngineeringEnchants = {
    [30] = true,   -- 粗制瞄准镜
    [32] = true,   -- 普通瞄准镜
    [33] = true,   -- 精确瞄准镜
    [663] = true,  -- 致命瞄准镜
    [664] = true,  -- 狙击瞄准镜
    [2523] = true, -- 比兹尼克247x128精确瞄准镜
    [43] = true,   -- 铁质盾刺
    [463] = true,  -- 秘银盾刺
    [464] = true,  -- 秘银马刺
    [34] = true,   -- 铁质平衡锤
}

-- 从 LibItemEnchant 获取附魔物品ID
local function GetEnchantItemID(enchantID)
    if LibStub then
        local LibItemEnchant = LibStub("LibItemEnchant.7000", true)
        if LibItemEnchant and LibItemEnchant.GetEnchantItemID then
            return LibItemEnchant:GetEnchantItemID(enchantID)
        end
    end
    return nil
end

--可附魔的部位
local EnchantParts = {
    [1] = { 1, "头部" },
    [2] = { 1, "颈部" },  -- 颈部不能附魔
    [3] = { 1, "肩部" },
    [5] = { 1, "胸部" },
    [6] = { 1, "腰部" },  -- 腰部不能附魔
    [7] = { 1, "腿部" },
    [8] = { 1, "脚部" },
    [9] = { 1, "手腕" },
    [10] = { 1, "手部" },
    [11] = { 1, "手指" },  -- 戒指（附魔师专属）
    [12] = { 1, "手指" },  -- 戒指（附魔师专属）
    [13] = { 0, "饰品" },  -- 饰品不能附魔
    [14] = { 0, "饰品" },  -- 饰品不能附魔
    [15] = { 1, "背部" },
    [16] = { 1, "主手" },
    [17] = { 1, "副手" },
    [18] = { 1, "远程" },  -- 远程武器（弓、枪、弩等）
}

-- 最大图标数量限制（防止内存泄露）
local MAX_ICON_COUNT = 20

--创建图标框架
local function CreateIconFrame(frame, index)
    local icon = CreateFrame("Frame", nil, frame)
    icon.index = index
    icon:Hide()
    icon:SetWidth(16)  -- 从18减小到16
    icon:SetHeight(16)
    
    -- 设置 Backdrop 边框（1.12 版本不需要 BackdropTemplate）
    icon:SetBackdrop({
        edgeFile = "Interface\\AddOns\\S_ItemTip\\Pig_Border.blp",
        edgeSize = 10
    })
    icon:SetBackdropBorderColor(1, 0.82, 0, 1)  -- 默认金色边框
    
    -- 设置较高的层级，确保不被遮挡
    icon:SetFrameLevel(frame:GetFrameLevel() + 10)
    
    -- 启用鼠标事件，阻止穿透到下层
    icon:EnableMouse(true)
    icon:SetToplevel(true)
    
    icon:SetScript("OnEnter", function()
        if this.title then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:SetText(this.title, 0, 1, 0.5, 1, true)
			--[[
            if this.enchantID then
                GameTooltip:AddLine("附魔ID: " .. this.enchantID, 1, 1, 1)
            end
			]]
            GameTooltip:Show()
        end
    end)
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- 图标纹理（居中显示）
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetWidth(12)  -- 从14减小到12
    icon.texture:SetHeight(12)
    icon.texture:SetPoint("CENTER", icon, "CENTER", 0, 0)
    -- 裁剪掉图标边框，只保留中间的图案
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    
    frame["gemIcon"..index] = icon
    return icon
end

--隐藏所有图标
local function HideAllIcons(frame)
    local index = 1
    while frame["gemIcon"..index] do
        frame["gemIcon"..index].title = nil
        frame["gemIcon"..index].enchantID = nil
        frame["gemIcon"..index].itemLink = nil
        frame["gemIcon"..index].spellID = nil
        frame["gemIcon"..index]:Hide()
        index = index + 1
    end
end

--获取可用的图标框架（带内存泄露保护）
local function GetIconFrame(frame)
    local index = 1
    while frame["gemIcon"..index] do
        if not frame["gemIcon"..index]:IsShown() then
            return frame["gemIcon"..index]
        end
        index = index + 1
        -- 防止无限创建图标框架
        if index > MAX_ICON_COUNT then
            -- 达到最大数量，复用第一个图标
            local firstIcon = frame["gemIcon1"]
            firstIcon:Hide()
            firstIcon.title = nil
            firstIcon.enchantID = nil
            firstIcon.itemLink = nil
            firstIcon.spellID = nil
            return firstIcon
        end
    end
    return CreateIconFrame(frame, index)
end

-- 检测是否启用 SuperWoW
local hasSuperWoW = (SetAutoloot ~= nil)

-- 生成物品链接的缓存键（只保留物品ID和附魔ID）
local function GetItemCacheKey(itemLink)
    if not itemLink then return nil end
    
    -- 提取：item:itemID:enchantID:gem1:gem2:gem3:gem4:...
    local _, _, itemID, enchantID = string.find(itemLink, "item:(%d+):(%d+)")
    if itemID and enchantID and enchantID ~= "0" then
        return itemID .. ":" .. enchantID
    end
    
    return nil
end

-- 从物品链接提取附魔ID
local function GetEnchantIDFromLink(itemLink)
    return S_ItemTip_GetEnchantIDFromLink(itemLink)
end

-- 调试模式开关
local DEBUG_MODE = false

-- 获取附魔名称（直接从映射库获取，永久缓存）
-- 返回：enchantName, enchantIcon, enchantQuality
local function GetEnchantName(itemLink, unit, slot)
    if not itemLink then return nil, nil, nil end
    
    local enchantID = GetEnchantIDFromLink(itemLink)
    if not enchantID then return nil, nil, nil end
    
    -- 检查缓存（永久缓存，类似 MerInspect）
    local cacheKey = enchantID
    if unitGuidCache[cacheKey] then
        return unitGuidCache[cacheKey].name, nil, nil
    end
    
    -- 直接从 EnchantDB_Generated.lua 的映射库获取名称
    local enchantName = nil
    if S_ItemTip_EnchantNames and S_ItemTip_EnchantNames[enchantID] then
        enchantName = S_ItemTip_EnchantNames[enchantID]
    else
        -- 如果映射库中没有，返回附魔ID
        enchantName = "附魔 #" .. enchantID
    end
    
    -- 永久缓存结果
    unitGuidCache[cacheKey] = {
        name = enchantName
    }
    
    return enchantName, nil, nil
end

--显示附魔图标
local function ShowEnchant(parentFrame, itemLink, anchorFrame, slotFrame)
    if not itemLink then 
        return 0 
    end
    
    local unit = parentFrame.currentUnit or "target"
    
    -- 检查该部位是否可以附魔
    if not EnchantParts[slotFrame.slotId] then
        return 0
    end
    
    -- 检查是否有附魔ID
    local enchantID = GetEnchantIDFromLink(itemLink)
    
    -- 如果有附魔ID（不为0），就显示图标
    if enchantID and enchantID ~= 0 then
        -- 获取附魔名称
        local enchantName = GetEnchantName(itemLink, unit, slotFrame.slotId)
        if not enchantName then
            enchantName = "附魔 #" .. enchantID
        end
        
        local icon = GetIconFrame(parentFrame)
        
        -- 尝试获取附魔物品ID
        local itemID = GetEnchantItemID(enchantID)
        local iconTexture = nil
        local borderColor = {1, 0.82, 0, 1}  -- 默认金色
        
        if itemID then
            -- 获取物品信息
            local itemName, _, itemQuality, _, _, _, _, _, _, texture = GetItemInfo(itemID)
            if texture then
                iconTexture = texture
                -- 根据物品品质设置边框颜色
                if itemQuality then
                    local r, g, b = GetItemQualityColor(itemQuality)
                    borderColor = {r, g, b, 1}
                end
            end
        end
        
        -- 如果没有获取到物品图标，使用默认图标
        if not iconTexture then
            if EngineeringEnchants[enchantID] then
                -- 工程附魔 - 使用齿轮图标，蓝色边框
                iconTexture = "Interface\\Icons\\Trade_Engineering"
                borderColor = {0.3, 0.7, 1, 1}
            else
                -- 普通附魔 - 使用附魔图标，金色边框
                iconTexture = "Interface\\Icons\\Trade_Engraving"
                borderColor = {1, 0.82, 0, 1}
            end
        end
        
        -- 设置图标和边框
        icon:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
        icon.texture:SetTexture(iconTexture)
        
        icon.title = enchantName
        icon.enchantID = enchantID
        icon.itemLink = nil
        icon.spellID = nil
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", anchorFrame, "RIGHT", 6, 0)  -- 减少间距
        icon:Show()
        return 18  -- 16像素图标 + 2像素间距
    end
    
    -- 没有附魔，不显示任何图标
    return 0
end

-- 延迟扫描附魔的函数（使用任务队列）
--[[
local function DelayedScanEnchants(unit)
    -- 添加到任务队列
    table.insert(taskQueue, {
        unit = unit,
        timestamp = GetTime(),
        expired = GetTime() + 3,  -- 3秒超时
        executed = false
    })
end
]]
-- 执行扫描任务
--[[
local function ExecuteScanTask(task)
    local frame = S_ItemTip_InspectFrame
    if not frame or not frame:IsShown() then
        return false
    end
    
    local unit = task.unit
    
    -- 检查单位是否有效
    if not UnitExists(unit) then
        return false
    end
    
    -- 先隐藏所有图标
    HideAllIcons(frame)
    
    -- 为每个槽位显示附魔图标
    local maxWidth = frame:GetWidth()
    local enchantCount = 0
    for i, slotFrame in ipairs(frame.slotFrames) do
        if slotFrame.itemLink then
            local iconWidth = ShowEnchant(frame, slotFrame.itemLink, slotFrame.itemName, slotFrame)
            if iconWidth > 0 then
                enchantCount = enchantCount + 1
            end
            -- 增加右边距以确保图标不会超出边框
            local totalWidth = 15 + 32 + 24 + slotFrame.itemName:GetWidth() + iconWidth + 30
            if totalWidth > maxWidth then
                maxWidth = totalWidth
            end
        else
            -- 如果没有物品链接，确保该槽位的图标被隐藏
            if frame["gemIcon"..i] then
                frame["gemIcon"..i]:Hide()
            end
        end
    end
    
    -- 调整框架宽度（增加额外边距）
    if maxWidth > frame:GetWidth() then
        frame:SetWidth(maxWidth + 10)
    end
    
    -- 更新GUID缓存（记录扫描时间，但不影响显示）
    local unitName = UnitName(unit)
    unitGuidCache[unitName] = {
        scanTime = time(),
        enchantCount = enchantCount
    }
    
    return true
end
]]
-- 任务调度器（类似 LibSchedule）
local taskScheduler = CreateFrame("Frame")
--[[  a delayed scan seems not necessary , and an OnUpdate func cost too much
taskScheduler:SetScript("OnUpdate", function()
    taskTimer = taskTimer + arg1
    
    -- 每0.5秒检查一次任务队列
    if taskTimer < 0.5 then
        return
    end
    
    taskTimer = 0
    local now = GetTime()
    
    -- 处理任务队列
    for i = table.getn(taskQueue), 1, -1 do
        local task = taskQueue[i]
        
        -- 检查是否超时
        if now > task.expired then
            table.remove(taskQueue, i)
        -- 检查是否可以执行（延迟0.5秒）
        elseif not task.executed and (now - task.timestamp) >= 0.5 then
            task.executed = true
            local success = ExecuteScanTask(task)
            if success then
                table.remove(taskQueue, i)
            end
        end
    end
end)
]]
-- 单位名称缓存，避免重复处理（1.12 版本使用名称代替 GUID）
-- 已移至文件顶部的 unitGuidCache

--Hook 到装备更新函数（立即执行，不延迟）
local originalUpdateFrame = S_ItemTip_UpdateFrame
function S_ItemTip_UpdateFrame(unit)
    if originalUpdateFrame then
        originalUpdateFrame(unit)
    end
    
    local frame = S_ItemTip_InspectFrame
    if not frame or not frame:IsShown() then
        return
    end
    
    -- 保存当前单位
    frame.currentUnit = unit
    scanningUnit = unit
    
    -- 立即扫描附魔（不使用任务队列，类似 MerInspect）
    if not UnitExists(unit) then
        return
    end
    
    -- 先隐藏所有图标
    HideAllIcons(frame)
    
    -- 为每个槽位显示附魔图标
    local maxWidth = frame:GetWidth()
    local enchantCount = 0
    for i, slotFrame in ipairs(frame.slotFrames) do
        if slotFrame.itemLink then
            local iconWidth = ShowEnchant(frame, slotFrame.itemLink, slotFrame.itemName, slotFrame)
            if iconWidth > 0 then
                enchantCount = enchantCount + 1
            end
            -- 增加右边距以确保图标不会超出边框
            local totalWidth = 15 + 32 + 24 + slotFrame.itemName:GetWidth() + iconWidth + 30
            if totalWidth > maxWidth then
                maxWidth = totalWidth
            end
        else
            -- 如果没有物品链接，确保该槽位的图标被隐藏
            if frame["gemIcon"..i] then
                frame["gemIcon"..i]:Hide()
            end
        end
    end
    
    -- 调整框架宽度（增加额外边距）
    if maxWidth > frame:GetWidth() then
        frame:SetWidth(maxWidth + 10)
    end
    
    -- 更新GUID缓存（记录扫描时间）
    local unitName = UnitName(unit)
    unitGuidCache[unitName] = {
        scanTime = time(),
        enchantCount = enchantCount
    }
end


--Hook 到装备更新函数
local function ExportCache()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 导出附魔缓存 ===|r")
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00复制以下代码到其他角色使用 /enchant import|r")
    DEFAULT_CHAT_FRAME:AddMessage("---开始---")
    
    local count = 0
    for cacheKey, data in pairs(S_ItemTip_EnchantCache) do
        local enchantName = type(data) == "table" and data.enchantName or data
        -- 转义特殊字符
        enchantName = string.gsub(enchantName, "\"", "\\\"")
        DEFAULT_CHAT_FRAME:AddMessage(string.format('S_ItemTip_EnchantCache["%s"]={enchantName="%s",timestamp=%d}', 
            cacheKey, enchantName, time()))
        count = count + 1
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("---结束---")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00共导出 " .. count .. " 个附魔|r")
end

-- 显示缓存的附魔列表
SLASH_ENCHANTCACHE1 = "/enchant"
SlashCmdList["ENCHANTCACHE"] = function(msg)
    if msg == "cache" or msg == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 已缓存的附魔 ===|r")
        local count = 0
        for cacheKey, data in pairs(S_ItemTip_EnchantCache) do
            count = count + 1
            -- 兼容旧格式（字符串）和新格式（表）
            local enchantName = type(data) == "table" and data.enchantName or data
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[" .. cacheKey .. "] " .. enchantName .. "|r")
        end
        if count == 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000暂无缓存的附魔|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00共缓存了 " .. count .. " 个附魔|r")
        end
    elseif msg == "stats" or msg == "stat" then
        -- 性能统计
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 性能统计 ===|r")
        
        local cacheCount = 0
        for _ in pairs(S_ItemTip_EnchantCache) do
            cacheCount = cacheCount + 1
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00附魔缓存: " .. cacheCount .. " / " .. MAX_CACHE_SIZE .. "|r")
        
        local guidCount = 0
        for _ in pairs(unitGuidCache) do
            guidCount = guidCount + 1
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00GUID缓存: " .. guidCount .. "|r")
        
        if scanningUnit then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00当前扫描: " .. UnitName(scanningUnit) .. "|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00当前扫描: 无|r")
        end
    elseif msg == "export" then
        ExportCache()
    elseif msg == "import" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00请在聊天框输入导出的代码，每行一条|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00格式: S_ItemTip_EnchantCache[\"xxx\"]={...}|r")
    elseif msg == "clear" then
        S_ItemTip_EnchantCache = {}
        unitGuidCache = {}
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00所有缓存已清空|r")
    elseif msg == "debug" then
        DEBUG_MODE = not DEBUG_MODE
        if DEBUG_MODE then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00调试模式已开启|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00调试模式已关闭|r")
        end
    elseif msg == "superwow" then
        if hasSuperWoW then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00SuperWoW 已启用|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000SuperWoW 未启用|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00用法:|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant - 查看已缓存的附魔|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant cache - 查看已缓存的附魔|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant stats - 查看性能统计|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant export - 导出缓存（可分享给其他玩家）|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant import - 导入说明|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant clear - 清空所有缓存|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant debug - 开启/关闭调试模式|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchant superwow - 检查 SuperWoW 状态|r")
    end
end



-- 检测 SuperWoW 状态
if hasSuperWoW then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00S_ItemTip: 附魔扫描功能已加载 (SuperWoW 已启用)|r")
else
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00S_ItemTip: 附魔扫描功能已加载|r")
end
DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /enchant 查看已缓存的附魔|r")
DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /enchant stats 查看性能统计|r")
DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /enchant clear 清空所有缓存|r")

-- 显示缓存统计
local cacheCount = 0
for _ in pairs(S_ItemTip_EnchantCache) do
    cacheCount = cacheCount + 1
end

if cacheCount > 0 then
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00已加载 " .. cacheCount .. " 个附魔缓存|r")
end

-- 性能优化总结
DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88性能优化: GUID永久缓存 + 立即执行 - 类似 MerInspect|r")
