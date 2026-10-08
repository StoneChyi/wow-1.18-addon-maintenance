-------------------------------------
-- S_ItemTip 核心模块
-- 统一的配置、日志、缓存管理
-------------------------------------

-- 命名空间
S_ItemTip = S_ItemTip or {}

-------------------------------------
-- 配置管理
-------------------------------------
S_ItemTip.Config = {
    version = "1.3.3-Optimized",
    defaults = {
        showInspectFrame = true,
        showMendeleev = true,
        showItemCount = true,
        showSellValue = true,
        showMajorLevel = true,
        cacheSize = 1000,
        logLevel = 1,  -- 0=关闭, 1=错误, 2=警告, 3=信息, 4=调试
    },
}

function S_ItemTip.Config:Load()
    S_ItemTip_Settings = S_ItemTip_Settings or {}
    for k, v in pairs(self.defaults) do
        if S_ItemTip_Settings[k] == nil then
            S_ItemTip_Settings[k] = v
        end
    end
end

function S_ItemTip.Config:Get(key)
    return S_ItemTip_Settings[key]
end

function S_ItemTip.Config:Set(key, value)
    S_ItemTip_Settings[key] = value
end

-------------------------------------
-- 日志系统
-------------------------------------
S_ItemTip.Logger = {
    level = 1,
}

function S_ItemTip.Logger:SetLevel(level)
    self.level = level
    S_ItemTip.Config:Set("logLevel", level)
end

function S_ItemTip.Logger:Error(msg)
    if self.level >= 1 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[S_ItemTip错误] " .. msg .. "|r")
    end
end

function S_ItemTip.Logger:Warn(msg)
    if self.level >= 2 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFAA00[S_ItemTip警告] " .. msg .. "|r")
    end
end

function S_ItemTip.Logger:Info(msg)
    if self.level >= 3 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[S_ItemTip] " .. msg .. "|r")
    end
end

function S_ItemTip.Logger:Debug(msg)
    if self.level >= 4 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF888888[S_ItemTip调试] " .. msg .. "|r")
    end
end

-------------------------------------
-- 缓存管理（LRU缓存）
-------------------------------------
S_ItemTip.Cache = {
    data = {},
    accessOrder = {},
    maxSize = 1000,
}

function S_ItemTip.Cache:Init(maxSize)
    self.maxSize = maxSize or 1000
    self.data = {}
    self.accessOrder = {}
end

function S_ItemTip.Cache:Get(key)
    local value = self.data[key]
    if value then
        -- 更新访问顺序
        self:UpdateAccess(key)
        return value
    end
    return nil
end

function S_ItemTip.Cache:Set(key, value)
    -- 检查是否需要清理
    if not self.data[key] and self:Count() >= self.maxSize then
        self:Clean()
    end
    
    self.data[key] = value
    self:UpdateAccess(key)
end

function S_ItemTip.Cache:UpdateAccess(key)
    -- 移除旧的访问记录
    for i, k in ipairs(self.accessOrder) do
        if k == key then
            table.remove(self.accessOrder, i)
            break
        end
    end
    -- 添加到末尾（最新访问）
    table.insert(self.accessOrder, key)
end

function S_ItemTip.Cache:Clean()
    -- 删除最旧的 20% 缓存
    local toRemove = math.floor(self.maxSize * 0.2)
    for i = 1, toRemove do
        local oldestKey = table.remove(self.accessOrder, 1)
        if oldestKey then
            self.data[oldestKey] = nil
        end
    end
    S_ItemTip.Logger:Debug("清理了 " .. toRemove .. " 个缓存项")
end

function S_ItemTip.Cache:Count()
    local count = 0
    for _ in pairs(self.data) do
        count = count + 1
    end
    return count
end

function S_ItemTip.Cache:Clear()
    self.data = {}
    self.accessOrder = {}
    S_ItemTip.Logger:Info("缓存已清空")
end

-------------------------------------
-- 工具函数
-------------------------------------
S_ItemTip.Utils = {}

-- 安全的 GetItemInfo（带错误处理）
function S_ItemTip.Utils.SafeGetItemInfo(itemID)
    if not itemID then return nil end
    
    local success, result = pcall(function()
        return {GetItemInfo(itemID)}
    end)
    
    if success and result[1] then
        return unpack(result)
    end
    return nil
end

-- 检查 tooltip 是否包含指定文本
function S_ItemTip.Utils.HasTooltipLine(tooltip, searchText)
    if not tooltip or not searchText then return false end
    
    for i = 1, tooltip:NumLines() do
        local line = _G[tooltip:GetName() .. "TextLeft" .. i]
        if line and line:GetText() and string.find(line:GetText(), searchText) then
            return true
        end
    end
    return false
end

-- 设置品质颜色
function S_ItemTip.Utils.SetQualityColor(frame, quality)
    if not frame or not quality then return 1, 1, 1 end
    
    local r, g, b = GetItemQualityColor(quality)
    if frame.SetTextColor then
        frame:SetTextColor(r, g, b)
    elseif frame.SetBackdropColor then
        frame:SetBackdropColor(r, g, b, 0.2)
    elseif frame.SetBackdropBorderColor then
        frame:SetBackdropBorderColor(r, g, b, 1)
    end
    return r, g, b
end

-- 从物品链接提取物品ID
function S_ItemTip.Utils.GetItemIDFromLink(itemLink)
    if not itemLink then return nil end
    local _, _, itemID = string.find(itemLink, "item:(%d+):")
    return tonumber(itemID)
end

-- 从物品链接提取附魔ID
function S_ItemTip.Utils.GetEnchantIDFromLink(itemLink)
    if not itemLink then return nil end
    local _, _, enchantID = string.find(itemLink, "item:%d+:(%d+)")
    if enchantID and enchantID ~= "0" then
        return tonumber(enchantID)
    end
    return nil
end

-------------------------------------
-- 事件管理器
-------------------------------------
S_ItemTip.EventManager = {
    timers = {},
    frame = nil,
}

function S_ItemTip.EventManager:Init()
    if not self.frame then
        self.frame = CreateFrame("Frame")
        self.frame:SetScript("OnUpdate", function()
            self:OnUpdate()
        end)
    end
end

function S_ItemTip.EventManager:AddTimer(name, interval, callback, oneShot)
    self.timers[name] = {
        interval = interval,
        elapsed = 0,
        callback = callback,
        oneShot = oneShot or false,
    }
end

function S_ItemTip.EventManager:RemoveTimer(name)
    self.timers[name] = nil
end

function S_ItemTip.EventManager:OnUpdate()
    for name, timer in pairs(self.timers) do
        timer.elapsed = timer.elapsed + arg1
        if timer.elapsed >= timer.interval then
            timer.elapsed = 0
            timer.callback()
            if timer.oneShot then
                self.timers[name] = nil
            end
        end
    end
end

-------------------------------------
-- 初始化
-------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "S_ItemTip" then
        -- 加载配置
        S_ItemTip.Config:Load()
        S_ItemTip.Logger.level = S_ItemTip.Config:Get("logLevel")
        
        -- 初始化缓存
        S_ItemTip.Cache:Init(S_ItemTip.Config:Get("cacheSize"))
        
        -- 初始化事件管理器
        S_ItemTip.EventManager:Init()
        
        S_ItemTip.Logger:Info("核心模块已加载 v" .. S_ItemTip.Config.version)
    end
end)

-------------------------------------
-- 斜杠命令
-------------------------------------
SLASH_SITEMTIPCORE1 = "/sitcore"
SlashCmdList["SITEMTIPCORE"] = function(msg)
    local command, param = string.match(msg, "^(%S+)%s*(.-)$")
    
    if not command or command == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== S_ItemTip 核心命令 ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/sitcore cache - 查看缓存统计|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/sitcore clearcache - 清空缓存|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/sitcore loglevel <0-4> - 设置日志等级|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/sitcore version - 查看版本|r")
        return
    end
    
    if command == "cache" then
        local count = S_ItemTip.Cache:Count()
        local maxSize = S_ItemTip.Cache.maxSize
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00缓存: %d / %d (%.1f%%)|r", 
            count, maxSize, (count / maxSize) * 100))
    elseif command == "clearcache" then
        S_ItemTip.Cache:Clear()
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00缓存已清空|r")
    elseif command == "loglevel" then
        local level = tonumber(param)
        if level and level >= 0 and level <= 4 then
            S_ItemTip.Logger:SetLevel(level)
            local levelNames = {"关闭", "错误", "警告", "信息", "调试"}
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00日志等级已设置为: " .. levelNames[level + 1] .. "|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000无效的日志等级（0-4）|r")
        end
    elseif command == "version" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00S_ItemTip 版本: " .. S_ItemTip.Config.version .. "|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未知命令: " .. command .. "|r")
    end
end
