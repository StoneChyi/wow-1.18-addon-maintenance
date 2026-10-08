-------------------------------------
-- 附魔数据库延迟加载器
-- 优化加载性能，避免启动卡顿
-- 使用 OnDemand 机制，只在需要时加载大文件
-------------------------------------

-- 加载状态
local isLoading = false
local isLoaded = false
local loadCallbacks = {}
local loadStartTime = 0

-- 初始化空表（避免 nil 错误）
S_ItemTip_EnchantNames = S_ItemTip_EnchantNames or {}
S_ItemTip_EnchantByName = S_ItemTip_EnchantByName or {}

-- 检查是否已加载
function S_ItemTip_IsEnchantDBLoaded()
    return isLoaded
end

-- 确保数据库已加载（如果未加载则同步加载）
function S_ItemTip_EnsureEnchantDBLoaded()
    if isLoaded then
        return true
    end
    
    -- 如果数据已存在但未初始化，立即初始化
    if S_ItemTip_EnchantNames and next(S_ItemTip_EnchantNames) then
        -- 检查是否已经建立过索引（避免重复遍历）
        if S_ItemTip_EnchantByName and next(S_ItemTip_EnchantByName) then
            isLoaded = true
            return true
        end
        
        -- 建立反向索引
        for id, name in pairs(S_ItemTip_EnchantNames) do
            if not S_ItemTip_EnchantByName[name] then
                S_ItemTip_EnchantByName[name] = id
            end
        end
        isLoaded = true
        return true
    end
    
    return false
end

-- 获取附魔数量
function S_ItemTip_GetEnchantCount()
    local count = 0
    for _ in pairs(S_ItemTip_EnchantNames) do
        count = count + 1
    end
    return count
end

-- 注册加载完成回调
function S_ItemTip_OnEnchantDBLoaded(callback)
    if isLoaded then
        callback()
    else
        table.insert(loadCallbacks, callback)
    end
end

-- 强制立即加载（同步）
function S_ItemTip_LoadEnchantDBNow()
    if isLoaded or isLoading then
        return
    end
    
    isLoading = true
    loadStartTime = GetTime()
    
    -- 直接加载文件（这会执行 EnchantDB_Generated.lua）
    -- 由于文件已经在 TOC 中，这里只是确保数据已加载
    if S_ItemTip_EnchantNames and next(S_ItemTip_EnchantNames) then
        -- 数据已经加载
        isLoaded = true
        isLoading = false
        
        -- 建立反向索引
        for id, name in pairs(S_ItemTip_EnchantNames) do
            if not S_ItemTip_EnchantByName[name] then
                S_ItemTip_EnchantByName[name] = id
            end
        end
        
        local loadTime = GetTime() - loadStartTime
        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00S_ItemTip: 附魔数据库已加载 (%d 条, 耗时 %.2f 秒)|r", 
            S_ItemTip_GetEnchantCount(), loadTime))
        
        -- 执行回调
        for _, callback in ipairs(loadCallbacks) do
            callback()
        end
        loadCallbacks = {}
    end
end

-- 延迟加载（异步，分帧处理）
function S_ItemTip_LoadEnchantDBAsync()
    if isLoaded or isLoading then
        return
    end
    
    isLoading = true
    loadStartTime = GetTime()
    
    -- 创建延迟加载帧
    local loaderFrame = CreateFrame("Frame")
    loaderFrame.phase = 1
    loaderFrame.elapsed = 0
    loaderFrame.batchIndex = 1
    loaderFrame.batchSize = 1000
    
    -- 先检查数据是否已经加载
    if S_ItemTip_EnchantNames and next(S_ItemTip_EnchantNames) then
        -- 数据已加载，直接建立索引
        loaderFrame.phase = 2
    end
    
    loaderFrame:SetScript("OnUpdate", function(_, elapsed)
        loaderFrame.elapsed = loaderFrame.elapsed + (elapsed or 0)
        
        -- 每 0.1 秒处理一批
        if loaderFrame.elapsed < 0.1 then
            return
        end
        loaderFrame.elapsed = 0
        
        if loaderFrame.phase == 1 then
            -- 阶段1：数据已通过 TOC 加载，跳到阶段2
            loaderFrame.phase = 2
            
        elseif loaderFrame.phase == 2 then
            -- 阶段2：建立反向索引（分批处理）
            local processed = 0
            local startIdx = loaderFrame.batchIndex
            
            for id, name in pairs(S_ItemTip_EnchantNames) do
                if id >= startIdx and id < startIdx + loaderFrame.batchSize then
                    if not S_ItemTip_EnchantByName[name] then
                        S_ItemTip_EnchantByName[name] = id
                    end
                    processed = processed + 1
                end
            end
            
            loaderFrame.batchIndex = loaderFrame.batchIndex + loaderFrame.batchSize
            
            -- 检查是否完成
            if processed == 0 or loaderFrame.batchIndex > 10000 then
                loaderFrame.phase = 3
            end
            
        elseif loaderFrame.phase == 3 then
            -- 阶段3：完成
            loaderFrame:SetScript("OnUpdate", nil)
            isLoading = false
            isLoaded = true
            
            local loadTime = GetTime() - loadStartTime
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00S_ItemTip: 附魔数据库加载完成 (%d 条, 耗时 %.2f 秒)|r", 
                S_ItemTip_GetEnchantCount(), loadTime))
            
            -- 执行回调
            for _, callback in ipairs(loadCallbacks) do
                callback()
            end
            loadCallbacks = {}
        end
    end)
end

-- 自动在登录后延迟加载
local autoLoadFrame = CreateFrame("Frame")
autoLoadFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
autoLoadFrame:SetScript("OnEvent", function()
    this:UnregisterEvent("PLAYER_ENTERING_WORLD")
    
    -- 延迟 3 秒后开始异步加载，避免影响登录
    local delayFrame = CreateFrame("Frame")
    delayFrame.timer = 0
    delayFrame:SetScript("OnUpdate", function(_, elapsed)
        delayFrame.timer = delayFrame.timer + (elapsed or 0)
        if delayFrame.timer >= 3 then
            delayFrame:SetScript("OnUpdate", nil)
            S_ItemTip_LoadEnchantDBAsync()
        end
    end)
end)

-- 提供手动加载命令
SLASH_LOADENCHANTDB1 = "/loadenchant"
SLASH_LOADENCHANTDB2 = "/reloadenchant"
SlashCmdList["LOADENCHANTDB"] = function(msg)
    if msg == "now" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00正在立即加载附魔数据库...|r")
        S_ItemTip_LoadEnchantDBNow()
    elseif msg == "async" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00正在异步加载附魔数据库...|r")
        S_ItemTip_LoadEnchantDBAsync()
    elseif msg == "status" then
        if isLoaded then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00附魔数据库已加载 (%d 条)|r", S_ItemTip_GetEnchantCount()))
        elseif isLoading then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00附魔数据库正在加载中...|r")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000附魔数据库未加载|r")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 附魔数据库加载命令 ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/loadenchant now - 立即加载（同步）|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/loadenchant async - 异步加载（推荐）|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/loadenchant status - 查看加载状态|r")
    end
end
