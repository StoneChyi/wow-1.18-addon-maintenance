-------------------------------------
-- 附魔查询表 - 优化版（移除重复数据）
-- 直接使用 EnchantDB_Generated.lua 的映射库
-- 只保留元数据（等级、部位、法术ID）
-------------------------------------

-- 附魔元数据（等级、部位、法术ID）
-- 格式：[enchantID] = { level = xxx, slot = "部位", spellID = xxx }
local EnchantMetadata = {
    -- 武器附魔
    [1900] = { level = 60, slot = "武器", spellID = 20034 },  -- 十字军
    [1898] = { level = 60, slot = "武器", spellID = 20032 },  -- 生命偷取
    [1899] = { level = 60, slot = "武器", spellID = 20033 },  -- 邪恶武器
    [1894] = { level = 60, slot = "武器", spellID = 20029 },  -- 冰寒
    [803] = { level = 50, slot = "武器", spellID = 13898 },   -- 烈焰
    [2443] = { level = 60, slot = "武器", spellID = 21931 },  -- 寒冬之力
    [2504] = { level = 60, slot = "武器", spellID = 22749 },  -- 法术能量
    [2505] = { level = 60, slot = "武器", spellID = 22750 },  -- 治疗能量
    [2563] = { level = 60, slot = "武器", spellID = 23799 },  -- 力量
    [2567] = { level = 60, slot = "武器", spellID = 23803 },  -- 强效精神
    [2568] = { level = 60, slot = "武器", spellID = 23804 },  -- 强效智力
    [2564] = { level = 60, slot = "武器", spellID = 23800 },  -- 敏捷
    [912] = { level = 60, slot = "武器", spellID = 13915 },   -- 屠魔
    [805] = { level = 50, slot = "武器", spellID = 13943 },   -- 强效攻击
    [853] = { level = 40, slot = "武器", spellID = 13653 },   -- 次级屠兽
    [854] = { level = 40, slot = "武器", spellID = 13655 },   -- 次级元素杀手
    
    -- 双手武器附魔
    [1903] = { level = 60, slot = "双手武器", spellID = 20035 },  -- 特效精神
    [1904] = { level = 60, slot = "双手武器", spellID = 20036 },  -- 特效智力
    [1896] = { level = 60, slot = "双手武器", spellID = 20030 },  -- 超强冲击
    [963] = { level = 45, slot = "双手武器", spellID = 13937 },   -- 强效冲击
    [2646] = { level = 35, slot = "双手武器", spellID = 27837 },  -- 敏捷
    
    -- 胸甲附魔
    [1892] = { level = 60, slot = "胸甲", spellID = 20026 },  -- 特效生命
    [1893] = { level = 60, slot = "胸甲", spellID = 20028 },  -- 特效法力
    [1891] = { level = 60, slot = "胸甲", spellID = 20025 },  -- 强效属性
    [928] = { level = 50, slot = "胸甲", spellID = 13941 },   -- 状态
    [908] = { level = 45, slot = "胸甲", spellID = 13858 },   -- 超强生命
    [913] = { level = 45, slot = "胸甲", spellID = 13917 },   -- 超强法力
    
    -- 护腕附魔
    [1885] = { level = 60, slot = "护腕", spellID = 20010 },  -- 超强力量
    [1886] = { level = 60, slot = "护腕", spellID = 20011 },  -- 超强耐力
    [1884] = { level = 60, slot = "护腕", spellID = 20009 },  -- 超强精神
    [1883] = { level = 60, slot = "护腕", spellID = 20008 },  -- 强效智力
    [2565] = { level = 60, slot = "护腕", spellID = 23801 },  -- 法力回复
    [923] = { level = 50, slot = "护腕", spellID = 13931 },   -- 偏斜
    
    -- 手套附魔
    [927] = { level = 60, slot = "手套", spellID = 20013 },   -- 强效力量
    [1887] = { level = 60, slot = "手套", spellID = 20012 },  -- 强效敏捷
    [2613] = { level = 60, slot = "手套", spellID = 25072 },  -- 威胁
    [2614] = { level = 60, slot = "手套", spellID = 25073 },  -- 暗影能量
    [2615] = { level = 60, slot = "手套", spellID = 25074 },  -- 冰霜能量
    [2616] = { level = 60, slot = "手套", spellID = 25078 },  -- 火焰能量
    [2617] = { level = 60, slot = "手套", spellID = 25079 },  -- 治疗能量
    
    -- 靴子附魔
    [911] = { level = 50, slot = "靴子", spellID = 13890 },   -- 初级速度
    
    -- 披风附魔
    [1889] = { level = 60, slot = "披风", spellID = 20015 },  -- 超强防御
    [1888] = { level = 60, slot = "披风", spellID = 20014 },  -- 强效抗性
    [910] = { level = 60, slot = "披风", spellID = 25083 },   -- 潜行
    [2622] = { level = 60, slot = "披风", spellID = 25086 },  -- 躲闪
    [2621] = { level = 60, slot = "披风", spellID = 25084 },  -- 狡诈
    [2619] = { level = 60, slot = "披风", spellID = 25081 },  -- 强效火焰抗性
    [2620] = { level = 60, slot = "披风", spellID = 25082 },  -- 强效自然抗性
    
    -- 盾牌附魔
    [1890] = { level = 60, slot = "盾牌", spellID = 20016 },  -- 活力
}

-- 附魔缓存（用于性能优化，永久缓存不清理）
local enchantCache = {}

-- 附魔等级和部位索引
local EnchantByLevel = {}
local EnchantBySlot = {}

-- 初始化索引
local function InitializeIndexes()
    for enchantID, metadata in pairs(EnchantMetadata) do
        local level = metadata.level
        local slot = metadata.slot
        
        -- 按等级分类
        if not EnchantByLevel[level] then
            EnchantByLevel[level] = {}
        end
        table.insert(EnchantByLevel[level], enchantID)
        
        -- 按部位分类
        if not EnchantBySlot[slot] then
            EnchantBySlot[slot] = {}
        end
        table.insert(EnchantBySlot[slot], enchantID)
    end
end

InitializeIndexes()

-- 根据附魔ID获取元数据
function S_ItemTip_GetEnchantMetadata(enchantID)
    return EnchantMetadata[enchantID]
end

-- 根据附魔名称查询附魔ID（使用统一 API + 永久缓存）
function S_ItemTip_GetEnchantByName(enchantName)
    if not enchantName or enchantName == "" then
        return nil
    end
    
    -- 检查缓存（永久缓存，不过期）
    if enchantCache[enchantName] then
        local cached = enchantCache[enchantName]
        return cached.enchantID, cached.spellID, nil, cached.slot, cached.name
    end
    
    -- 使用统一的 API 查询
    local enchantID = S_ItemTip_GetEnchantIDByName(enchantName)
    if enchantID then
        local metadata = EnchantMetadata[enchantID]
        local spellID = metadata and metadata.spellID
        local slot = metadata and metadata.slot
        local name = S_ItemTip_GetEnchantNameByID(enchantID)
        
        -- 永久缓存结果
        enchantCache[enchantName] = {
            enchantID = enchantID,
            spellID = spellID,
            slot = slot,
            name = name
        }
        
        return enchantID, spellID, nil, slot, name
    end
    
    return nil
end

-- 根据等级查询附魔列表
function S_ItemTip_GetEnchantsByLevel(level)
    local results = {}
    local enchantIDs = EnchantByLevel[level] or {}
    
    for _, enchantID in ipairs(enchantIDs) do
        local name = S_ItemTip_GetEnchantNameByID(enchantID)
        local metadata = EnchantMetadata[enchantID]
        if name and metadata then
            table.insert(results, {
                id = enchantID,
                name = name,
                level = metadata.level,
                slot = metadata.slot,
                spellID = metadata.spellID
            })
        end
    end
    
    return results
end

-- 根据部位查询附魔列表
function S_ItemTip_GetEnchantsBySlot(slot)
    local results = {}
    local enchantIDs = EnchantBySlot[slot] or {}
    
    for _, enchantID in ipairs(enchantIDs) do
        local name = S_ItemTip_GetEnchantNameByID(enchantID)
        local metadata = EnchantMetadata[enchantID]
        if name and metadata then
            table.insert(results, {
                id = enchantID,
                name = name,
                level = metadata.level,
                slot = metadata.slot,
                spellID = metadata.spellID
            })
        end
    end
    
    -- 按等级排序
    table.sort(results, function(a, b)
        return a.level < b.level
    end)
    
    return results
end

-- 显示所有附魔
function S_ItemTip_ListAllEnchants()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 附魔数据库 ===|r")
    
    local count = S_ItemTip_GetEnchantCount()
    if count > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00从 DBC 加载了 " .. count .. " 个附魔|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /enchantid <名称> 查询具体附魔|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00示例: /eid 十字军|r")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000附魔数据库未加载|r")
end

-- 斜杠命令
SLASH_ENCHANTLOOKUP1 = "/enchantid"
SLASH_ENCHANTLOOKUP2 = "/eid"
SlashCmdList["ENCHANTLOOKUP"] = function(msg)
    if msg == "" or msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 附魔查询命令 ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchantid <附魔名称> - 查询附魔ID|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchantid level <等级> - 查询指定等级的附魔|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchantid slot <部位> - 查询指定部位的附魔|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchantid list - 显示所有附魔|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00/enchantid cache - 查看缓存统计|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00示例: /enchantid 十字军|r")
        return
    end
    
    if msg == "list" then
        S_ItemTip_ListAllEnchants()
        return
    end
    
    if msg == "cache" then
        local count = 0
        for _ in pairs(enchantCache) do
            count = count + 1
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00缓存了 " .. count .. " 个附魔查询结果|r")
        return
    end
    
    -- 查询等级
    local _, _, levelStr = string.find(msg, "level%s+(%d+)")
    if levelStr then
        local level = tonumber(levelStr)
        local enchants = S_ItemTip_GetEnchantsByLevel(level)
        if table.getn(enchants) > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 等级 " .. level .. " 的附魔 ===|r")
            for _, enchant in ipairs(enchants) do
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF88FF88%s|r (%s) - 附魔ID: |cFFFFFF00%d|r, 法术ID: |cFFFFFF00%d|r", 
                    enchant.name, enchant.slot, enchant.id, enchant.spellID or 0))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到等级 " .. level .. " 的附魔|r")
        end
        return
    end
    
    -- 查询部位
    local _, _, slotStr = string.find(msg, "slot%s+(.+)")
    if slotStr then
        local enchants = S_ItemTip_GetEnchantsBySlot(slotStr)
        if table.getn(enchants) > 0 then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== " .. slotStr .. " 的附魔 ===|r")
            for _, enchant in ipairs(enchants) do
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF88FF88%s|r (Lv%d) - 附魔ID: |cFFFFFF00%d|r, 法术ID: |cFFFFFF00%d|r", 
                    enchant.name, enchant.level, enchant.id, enchant.spellID or 0))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到 " .. slotStr .. " 的附魔|r")
        end
        return
    end
    
    -- 查询名称
    local enchantID, spellID, itemID, slot, name = S_ItemTip_GetEnchantByName(msg)
    if enchantID then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00=== 附魔信息 ===|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88附魔名称:|r " .. (name or msg))
        DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88附魔ID:|r |cFFFFFF00" .. enchantID .. "|r")
        
        if spellID then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88法术ID:|r |cFFFFFF00" .. spellID .. "|r")
        end
        
        if slot then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88部位:|r " .. slot)
        end
        
        local metadata = EnchantMetadata[enchantID]
        if metadata then
            DEFAULT_CHAT_FRAME:AddMessage("|cFF88FF88等级:|r " .. metadata.level)
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000未找到附魔: " .. msg .. "|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00提示: 使用 /enchantid list 查看所有附魔|r")
    end
end

DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00S_ItemTip: 附魔查询功能已加载（优化版）|r")
DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00使用 /enchantid 或 /eid 查询附魔ID|r")
