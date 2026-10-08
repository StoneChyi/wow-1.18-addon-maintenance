-------------------------------------
-- 附魔查询 API
-- 统一的附魔数据访问接口
-- 所有附魔查询都通过这个 API
-- 支持延迟加载机制
-------------------------------------

-- 获取 LibItemEnchant 库
local function GetLibItemEnchant()
    if LibStub then
        return LibStub("LibItemEnchant.7000", true)
    end
    return nil
end

-- 确保数据已加载（如果未加载则触发加载）
local function EnsureDataLoaded()
    if not S_ItemTip_IsEnchantDBLoaded or not S_ItemTip_IsEnchantDBLoaded() then
        -- 数据未加载，尝试立即加载
        if S_ItemTip_LoadEnchantDBNow then
            S_ItemTip_LoadEnchantDBNow()
        end
        return false
    end
    return true
end

-- 根据附魔ID获取附魔名称
function S_ItemTip_GetEnchantNameByID(enchantID)
    if not enchantID or enchantID == 0 then
        return nil
    end
    
    -- 确保数据已加载
    if not EnsureDataLoaded() then
        return nil
    end
    
    -- 从生成的数据库获取名称
    if S_ItemTip_EnchantNames and S_ItemTip_EnchantNames[enchantID] then
        return S_ItemTip_EnchantNames[enchantID]
    end
    
    return nil
end

-- 根据附魔名称获取附魔ID
function S_ItemTip_GetEnchantIDByName(enchantName)
    if not enchantName or enchantName == "" then
        return nil
    end
    
    -- 确保数据已加载
    if not EnsureDataLoaded() then
        return nil
    end
    
    -- 精确匹配
    if S_ItemTip_EnchantByName and S_ItemTip_EnchantByName[enchantName] then
        return S_ItemTip_EnchantByName[enchantName]
    end
    
    -- 模糊匹配
    if S_ItemTip_EnchantNames then
        for id, name in pairs(S_ItemTip_EnchantNames) do
            if string.find(name, enchantName) or string.find(enchantName, name) then
                return id
            end
        end
    end
    
    return nil
end

-- 根据附魔ID获取法术ID（从 LibItemEnchant）
function S_ItemTip_GetEnchantSpellID(enchantID)
    if not enchantID or enchantID == 0 then
        return nil
    end
    
    local lib = GetLibItemEnchant()
    if lib then
        local itemLink = "item:1:" .. enchantID .. ":0:0"
        local spellID = lib:GetEnchantSpellID(itemLink)
        return spellID
    end
    
    return nil
end

-- 根据附魔ID获取物品ID（从 LibItemEnchant）
function S_ItemTip_GetEnchantItemID(enchantID)
    if not enchantID or enchantID == 0 then
        return nil
    end
    
    local lib = GetLibItemEnchant()
    if lib then
        local itemLink = "item:1:" .. enchantID .. ":0:0"
        local itemID = lib:GetEnchantItemID(itemLink)
        return itemID
    end
    
    return nil
end

-- 根据物品链接获取附魔ID
function S_ItemTip_GetEnchantIDFromLink(itemLink)
    if not itemLink then return nil end
    local _, _, enchantID = string.find(itemLink, "item:%d+:(%d+)")
    if enchantID and enchantID ~= "0" then
        return tonumber(enchantID)
    end
    return nil
end

-- 获取附魔的完整信息
function S_ItemTip_GetEnchantInfo(enchantID)
    if not enchantID or enchantID == 0 then
        return nil
    end
    
    local info = {
        id = enchantID,
        name = S_ItemTip_GetEnchantNameByID(enchantID),
        spellID = S_ItemTip_GetEnchantSpellID(enchantID),
        itemID = S_ItemTip_GetEnchantItemID(enchantID),
    }
    
    -- 获取详细信息
    if S_ItemTip_EnchantDetails and S_ItemTip_EnchantDetails[enchantID] then
        local details = S_ItemTip_EnchantDetails[enchantID]
        info.effect_type = details.effect_type
        info.effect_points = details.effect_points
        info.src_item_id = details.src_item_id
        info.flags = details.flags
    end
    
    return info
end

-- 根据名称获取附魔的完整信息
function S_ItemTip_GetEnchantInfoByName(enchantName)
    local enchantID = S_ItemTip_GetEnchantIDByName(enchantName)
    if enchantID then
        return S_ItemTip_GetEnchantInfo(enchantID)
    end
    return nil
end

-- 获取所有附魔的数量
function S_ItemTip_GetEnchantCount()
    if S_ItemTip_EnchantNames then
        local count = 0
        for _ in pairs(S_ItemTip_EnchantNames) do
            count = count + 1
        end
        return count
    end
    return 0
end

-- 搜索附魔（支持模糊搜索）
function S_ItemTip_SearchEnchants(keyword)
    if not keyword or keyword == "" then
        return {}
    end
    
    local results = {}
    
    if S_ItemTip_EnchantNames then
        for id, name in pairs(S_ItemTip_EnchantNames) do
            if string.find(string.lower(name), string.lower(keyword)) then
                table.insert(results, {
                    id = id,
                    name = name
                })
            end
        end
    end
    
    return results
end

-- 导出函数供其他模块使用
S_ItemTip_EnchantAPI = {
    GetNameByID = S_ItemTip_GetEnchantNameByID,
    GetIDByName = S_ItemTip_GetEnchantIDByName,
    GetSpellID = S_ItemTip_GetEnchantSpellID,
    GetItemID = S_ItemTip_GetEnchantItemID,
    GetIDFromLink = S_ItemTip_GetEnchantIDFromLink,
    GetInfo = S_ItemTip_GetEnchantInfo,
    GetInfoByName = S_ItemTip_GetEnchantInfoByName,
    GetCount = S_ItemTip_GetEnchantCount,
    Search = S_ItemTip_SearchEnchants,
}
