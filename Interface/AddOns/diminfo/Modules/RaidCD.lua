-- 引入服务器配置 (baseResetTime均设置为北京时间)
local SERVER_CONFIGS = {
        
    -- 群星盆地配置
    ["Basin of Stars"] = {
        -- 7天冷却副本
        [1] = {name = "熔火之心", resetDays = 7, baseResetTime = 1784174400}, -- 2026年7月16日中午12点
        [2] = {name = "黑翼之巢", resetDays = 7, baseResetTime = 1784174400},
        [3] = {name = "安其拉神殿", resetDays = 7, baseResetTime = 1784174400},
        [4] = {name = "纳克萨玛斯", resetDays = 7, baseResetTime = 1784174400},
        [5] = {name = "翡翠圣殿", resetDays = 7, baseResetTime = 1784174400},
        [6] = {name = "卡拉赞之塔", resetDays = 7, baseResetTime = 1784692800}, --2026年7月22日中午12点
		[11] = {name = "木喉要塞", resetDays = 7, baseResetTime = 1784260800}, -- 2026年7月17日中午12点
        
        -- 5天冷却副本
        [7] = {name = "卡拉赞下层大厅", resetDays = 5, baseResetTime = 1784260800}, -- 2026年7月17日中午12点
        [8] = {name = "奥妮克希亚的巢穴", resetDays = 5, baseResetTime = 1784260800},
        
        -- 3天冷却副本
        [9] = {name = "祖尔格拉布", resetDays = 3, baseResetTime = 1784347200}, -- 2026年7月18日中午12点
        [10] = {name = "安其拉废墟", resetDays = 3, baseResetTime = 1784347200}
    },  
        
    -- 基赫纳斯配置
    ["Gehennas"] = {
        -- 7天冷却副本
        [1] = {name = "熔火之心", resetDays = 7, baseResetTime = 1761537600}, --2025年10月27日中午12点
        [2] = {name = "黑翼之巢", resetDays = 7, baseResetTime = 1761537600},
        [3] = {name = "安其拉神殿", resetDays = 7, baseResetTime = 1761537600},
        [4] = {name = "纳克萨玛斯", resetDays = 7, baseResetTime = 1761537600},
        [5] = {name = "翡翠圣殿", resetDays = 7, baseResetTime = 1761537600},
        -- [6] = {name = "卡拉赞之塔", resetDays = 7, baseResetTime = 1761537600},
		[11] = {name = "木喉要塞", resetDays = 7, baseResetTime = 1789099200},
        
        -- 5天冷却副本
        [7] = {name = "卡拉赞下层大厅", resetDays = 5, baseResetTime = 1774065600}, 
        [8] = {name = "奥妮克希亚的巢穴", resetDays = 5, baseResetTime = 1774065600}, --2026年3月21日中午12点
        
        -- -- 3天冷却副本
        [9] = {name = "祖尔格拉布", resetDays = 3, baseResetTime = 1769486400}, --2026年1月27日中午12点
        [10] = {name = "安其拉废墟", resetDays = 3, baseResetTime = 1769486400}
    },
	
	--永歌荒野
	["Eversong Wilds"] = {       
		-- 7天冷却副本
        [1] = {name = "熔火之心", resetDays = 7, baseResetTime = 1782014400}, --2026年6月21日中午12点
        [2] = {name = "黑翼之巢", resetDays = 7, baseResetTime = 1782014400},
        -- [3] = {name = "安其拉神殿", resetDays = 7, baseResetTime = 1760673600},
        -- [4] = {name = "纳克萨玛斯", resetDays = 7, baseResetTime = 1760673600},
        [5] = {name = "翡翠圣殿", resetDays = 7, baseResetTime = 1782014400},
        -- [6] = {name = "卡拉赞之塔", resetDays = 7, baseResetTime = 1760673600},
		-- [11] = {name = "木喉要塞", resetDays = 7, baseResetTime = 1789099200}, 
        
        -- 5天冷却副本
        [7] = {name = "卡拉赞下层大厅", resetDays = 5, baseResetTime = 1782014400}, 
        [8] = {name = "奥妮克希亚的巢穴", resetDays = 5, baseResetTime = 1782014400},  --2026年6月21日中午12点
        
        -- -- 3天冷却副本
        [9] = {name = "祖尔格拉布", resetDays = 3, baseResetTime = 1788062400},
        -- [10] = {name = "安其拉废墟", resetDays = 3, baseResetTime = 1760673600}
    },
	
	-- 默认服务器配置（用于未在列表中的服务器）
	["默认"] = {
		default = true,
		message = "暂时无法获取服务器团本和活动信息，后续更新"
	},
}

-- 按重置周期分组（保持不变）
local RAID_GROUPS = {
    {
        name = "7天CD副本",
        color = "|cFFFF8000", -- 橙色
        raids = {1, 2, 3, 4, 5, 6, 11}
    },
    {
        name = "5天CD副本",
        color = "|cFF9370DB", -- 紫色
        raids = {7, 8}
    },
    {
        name = "3天CD副本",
        color = "|cFF0070DE", -- 蓝色
        raids = {9, 10}
    }
}

-- 暗月马戏团配置
local DARKMOON_FAIRE_CONFIG = {
    baseResetTime = 1779552000, -- 基准时间：2026年5月24日0点（北京时间），此时在雷霆崖
    resetDays = 7, -- 7天轮换一次
    locations = {
        [0] = "雷霆崖",
        [1] = "闪金镇"
    }
}

-- 祖格隐藏boss配置
local ZG_HIDDEN_BOSS_CONFIG = {
    baseResetTime = 1777910400, -- 基准时间：2026年5月5日0点（北京时间），此时是雷纳塔基
    resetDays = 14, -- 14天轮换一次（两周）
    bosses = {
        [0] = "雷纳塔基",
        [1] = "乌苏雷", 
        [2] = "格里雷克",
        [3] = "哈扎拉尔"
    }
}

-- 双倍战场配置
local BATTLEGROUND_BONUS_CONFIG = {
    baseResetTime = 1779465600, -- 基准时间：2026年5月23日0点（北京时间），此时是血环
    resetDays = 1, -- 1天轮换一次
    battlegrounds = {
        [0] = "血环竞技场",
        [1] = "荆棘峡谷", 
        [2] = "奥特兰克山谷",
        [3] = "战歌峡谷",
        [4] = "阿拉希盆地"
    }
}

-- =============================================================================
-- 跨角色CD存储
-- =============================================================================
RaidCD_AccountData = RaidCD_AccountData or {}

-- 获取当前服务器配置
local function GetCurrentServerConfig()
    local serverName = GetRealmName() or "默认"
    local config = SERVER_CONFIGS[serverName]
    
    -- 如果找不到当前服务器配置，使用默认配置
    if not config then
        config = SERVER_CONFIGS["默认"]
    end
    
    return config, serverName
end

-- 获取当前服务器的副本配置
local RAID_CONFIG, CURRENT_SERVER_NAME = GetCurrentServerConfig()

-- =============================================================================
-- 工具函数
-- =============================================================================

-- 获取本地时间(北京时间)
local function GetCurrentTime()
    return time()
end

-- 格式化剩余时间
local function FormatTimeLeft(timeLeft)
    if timeLeft <= 0 then return "已重置" end

    local days = math.floor(timeLeft / 86400)
    local hours = math.floor(math.mod(timeLeft, 86400) / 3600)
    local minutes = math.floor(math.mod(timeLeft, 3600) / 60)

    if days > 0 then
        return string.format("%d天%d小时%d分", days, hours, minutes)
    elseif hours > 0 then
        return string.format("%d小时%d分", hours, minutes)
    else
        return string.format("%d分钟", minutes)
    end
end

-- 计算下一个重置时间
local function CalculateNextResetTime(raidID)
    local config = RAID_CONFIG[raidID]
    if not config or not config.baseResetTime then return nil end
    
    local currentTime = GetCurrentTime()
    local cycle = config.resetDays * 24 * 3600
    local baseTime = config.baseResetTime
    
    -- 计算下一个重置时间
    local timeSinceBase = currentTime - baseTime
    local cyclesSinceBase = math.floor(timeSinceBase / cycle)
    local nextReset = baseTime + (cyclesSinceBase + 1) * cycle
    
    return nextReset
end

-- 获取暗月马戏团信息
local function GetDarkmoonFaireInfo()
    local currentTime = GetCurrentTime()
    local cycle = DARKMOON_FAIRE_CONFIG.resetDays * 24 * 3600
    local baseTime = DARKMOON_FAIRE_CONFIG.baseResetTime
    
    local timeSinceBase = currentTime - baseTime
    local cyclesSinceBase = math.floor(timeSinceBase / cycle)
    
    local currentLocation = DARKMOON_FAIRE_CONFIG.locations[math.mod(cyclesSinceBase, 2)]
    local nextReset = baseTime + (cyclesSinceBase + 1) * cycle
    local timeLeft = nextReset - currentTime
    local nextLocation = DARKMOON_FAIRE_CONFIG.locations[math.mod(cyclesSinceBase + 1, 2)]
    
    return currentLocation, nextLocation, timeLeft
end

-- 获取祖格隐藏boss信息
local function GetZGHiddenBossInfo()
    local currentTime = GetCurrentTime()
    local cycle = ZG_HIDDEN_BOSS_CONFIG.resetDays * 24 * 3600
    local baseTime = ZG_HIDDEN_BOSS_CONFIG.baseResetTime
    
    local timeSinceBase = currentTime - baseTime
    local cyclesSinceBase = math.floor(timeSinceBase / cycle)
    
    local currentBoss = ZG_HIDDEN_BOSS_CONFIG.bosses[math.mod(cyclesSinceBase, 4)]
    local nextReset = baseTime + (cyclesSinceBase + 1) * cycle
    local timeLeft = nextReset - currentTime
    local nextBoss = ZG_HIDDEN_BOSS_CONFIG.bosses[math.mod(cyclesSinceBase + 1, 4)]
    
    return currentBoss, nextBoss, timeLeft
end

-- 获取双倍战场信息
local function GetBattlegroundBonusInfo()
    local currentTime = GetCurrentTime()
    local cycle = BATTLEGROUND_BONUS_CONFIG.resetDays * 24 * 3600
    local baseTime = BATTLEGROUND_BONUS_CONFIG.baseResetTime
    
    local timeSinceBase = currentTime - baseTime
    local cyclesSinceBase = math.floor(timeSinceBase / cycle)
    
    local currentBattleground = BATTLEGROUND_BONUS_CONFIG.battlegrounds[math.mod(cyclesSinceBase, 5)]
    local nextReset = baseTime + (cyclesSinceBase + 1) * cycle
    local timeLeft = nextReset - currentTime
    local nextBattleground = BATTLEGROUND_BONUS_CONFIG.battlegrounds[math.mod(cyclesSinceBase + 1, 5)]
    
    return currentBattleground, nextBattleground, timeLeft
end

-- 获取副本名称到ID的映射
local function CreateRaidNameToIDMap()
    local map = {}
    for id, config in pairs(RAID_CONFIG) do
        if type(config) == "table" and not config.default then
            map[config.name] = id
            if config.name == "熔火之心" then map["Molten Core"] = id
            elseif config.name == "黑翼之巢" then map["Blackwing Lair"] = id
            elseif config.name == "安其拉神殿" then map["Ahn'Qiraj Temple"] = id
            elseif config.name == "纳克萨玛斯" then map["Naxxramas"] = id
            elseif config.name == "翡翠圣殿" then map["Emerald Sanctum"] = id
            elseif config.name == "卡拉赞之塔" then map["Tower of Karazhan"] = id
            elseif config.name == "卡拉赞下层大厅" then map["Lower Karazhan Halls"] = id
            elseif config.name == "奥妮克希亚的巢穴" then map["Onyxia's Lair"] = id
            elseif config.name == "祖尔格拉布" then map["Zul'Gurub"] = id
            elseif config.name == "安其拉废墟" then map["Ruins of Ahn'Qiraj"] = id
			elseif config.name == "木喉要塞" then map["Timbermaw Hold"] = id
            end
        end
    end
    return map
end

local RAID_NAME_TO_ID = CreateRaidNameToIDMap()

-- =============================================================================
-- 界面创建
-- =============================================================================

-- 创建界面元素
local diminfo_RaidCD = CreateFrame("Button", "diminfo_RaidCD", UIParent)
local Text = diminfo_RaidCD:CreateFontString(nil, "OVERLAY")
Text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
Text:SetPoint("RIGHT", diminfo_Time, "LEFT", -20, 0)
diminfo_RaidCD:SetAllPoints(Text)

-- 存储副本锁定状态
local myList = {}
local lastUpdateTime = 0

-- =============================================================================
-- 核心功能
-- =============================================================================

-- 获取玩家等级
local function GetPlayerLevel()
    return UnitLevel("player")
end

-- 检查是否是满级玩家
local function IsMaxLevelPlayer()
    return GetPlayerLevel() >= 60
end

-- 获取副本锁定状态
local function GetMySavedInstances()
    if RAID_CONFIG.default or not IsMaxLevelPlayer() then
        return
    end
    
    local n = GetNumSavedInstances()
    
    for id, _ in pairs(RAID_CONFIG) do
        if type(RAID_CONFIG[id]) == "table" and not RAID_CONFIG[id].default then
            myList[id] = 0
        end
    end
    
    for i = 1, n do
        local instanceName, lockedId, reset = GetSavedInstanceInfo(i)
        if instanceName then
            local raidID = RAID_NAME_TO_ID[instanceName]
            if not raidID then
                for name, id in pairs(RAID_NAME_TO_ID) do
                    if string.find(instanceName, name) then
                        raidID = id
                        break
                    end
                end
            end
            if raidID then
                myList[raidID] = lockedId
            end
        end
    end
    
    lastUpdateTime = GetCurrentTime()
end

-- 保存当前角色的CD信息（存储每个副本的锁定时间戳）
local function SaveCurrentCharacterRaidCD()
    -- 确保全局表已初始化
    RaidCD_AccountData = RaidCD_AccountData or {}
    
    if RAID_CONFIG.default or not IsMaxLevelPlayer() then
        return
    end
    
    local server = GetRealmName()
    local char = UnitName("player")
    if not server or not char then return end
    
    local key = server .. "|" .. char
    local data = {}
    local currentTime = GetCurrentTime()
    
    for raidId, locked in pairs(myList) do
        if locked ~= 0 then
            local raidInfo = RAID_CONFIG[raidId]
            if raidInfo and raidInfo.name then
                data[raidInfo.name] = currentTime  -- 存储锁定时间戳
            end
        end
    end
    
    RaidCD_AccountData[key] = data
end

-- 更新显示文本
local function UpdateDisplay()
    if RAID_CONFIG.default then
        Text:SetText("|cff00ff00活动信息|r")
        return
    end
    
    if not IsMaxLevelPlayer() then
        Text:SetText("|cff00ff00活动信息|r")
        return
    end
    
    GetMySavedInstances()
    SaveCurrentCharacterRaidCD()  -- 保存到全局
    
    local lockedCount = 0
    for _, locked in pairs(myList) do
        if locked ~= 0 then
            lockedCount = lockedCount + 1
        end
    end
    
    Text:SetText("|cff00ff00团本CD (" .. lockedCount .. ")|r")
end

-- 强制刷新副本信息
local function ForceUpdateRaidData()
    if RAID_CONFIG.default or not IsMaxLevelPlayer() then
        return
    end
    RequestRaidInfo()
    UpdateDisplay()
end

-- 获取同账号其他角色的CD信息（自动过滤已过期的锁定，且只返回有锁定的角色）
local function GetOtherCharactersRaidCD()
    -- 确保全局表已初始化
    RaidCD_AccountData = RaidCD_AccountData or {}
    
    local currentServer = GetRealmName()
    local currentChar = UnitName("player")
    local result = {}
    local currentTime = GetCurrentTime()
    
    for key, data in pairs(RaidCD_AccountData) do
        local server, char = strmatch(key, "^(.*)|(.*)$")
        if server and char and (server == currentServer and char ~= currentChar) then
            local validRaids = {}
            for raidName, timestamp in pairs(data) do
                -- 查找副本ID
                local raidID = RAID_NAME_TO_ID[raidName]
                if raidID then
                    local raidInfo = RAID_CONFIG[raidID]
                    if raidInfo then
                        -- 计算当前周期的起始时间（即上次重置时间）
                        local nextReset = CalculateNextResetTime(raidID)
                        local cycle = raidInfo.resetDays * 24 * 3600
                        local cycleStart = nextReset - cycle  -- 当前周期的起始时间
                        if timestamp >= cycleStart then
                            table.insert(validRaids, raidName)
                        end
                    end
                end
            end
            -- 只添加有CD的角色
            if table.getn(validRaids) > 0 then
                result[char] = validRaids
            end
        end
    end
    return result
end

-- 定义显示工具提示的函数（默认模式）
local function ShowRaidCDTooltip()
    GameTooltip:SetOwner(diminfo_RaidCD, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:ClearLines()
    
    if RAID_CONFIG.default then
        GameTooltip:AddLine("活动信息 - " .. CURRENT_SERVER_NAME)
        GameTooltip:AddLine("|cffff0000" .. RAID_CONFIG.message .. "|r")
        GameTooltip:Show()
        return
    end
    
    local currentTime = GetCurrentTime()
	local playerLevel = GetPlayerLevel()
	
	if not IsMaxLevelPlayer() then
        GameTooltip:AddLine("活动信息 - " .. CURRENT_SERVER_NAME .. " (等级 " .. playerLevel .. ")")
        GameTooltip:AddLine(" ")
        local currentLocation, nextLocation, timeLeft = GetDarkmoonFaireInfo()
        GameTooltip:AddLine("|cffff0000暗月马戏团|r")
        GameTooltip:AddLine("  当前: |cff00ff00" .. currentLocation .. "|r")
        GameTooltip:AddLine("  下次: |cff00ff00" .. nextLocation .. " (" .. FormatTimeLeft(timeLeft) .. ")|r")
        GameTooltip:AddLine(" ")
        local currentBG, nextBG, bgTimeLeft = GetBattlegroundBonusInfo()
        GameTooltip:AddLine("|cffff0000双倍战场|r")
        GameTooltip:AddLine("  今日: |cff00ff00" .. currentBG .. "|r")
        GameTooltip:AddLine("  明日: |cff00ff00" .. nextBG .. " (" .. FormatTimeLeft(bgTimeLeft) .. ")|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("达到60级后显示完整团本和活动信息", .3, 1, .6)
        GameTooltip:AddLine("左键:集合石 or LFT", .3, 1, .6)
		GameTooltip:AddLine("按住 Alt 显示同账号其他角色团本CD", 0.8, 0.8, 1)
        GameTooltip:Show()
        return
    end
    
    GameTooltip:AddLine("团本锁定状态 - " .. CURRENT_SERVER_NAME)
    
    for _, group in ipairs(RAID_GROUPS) do
        GameTooltip:AddLine(group.color .. group.name .. "|r")
        for _, raidId in ipairs(group.raids) do
            local raidInfo = RAID_CONFIG[raidId]
            if raidInfo then
                local raidName = raidInfo.name
                local nextReset = CalculateNextResetTime(raidId)
                local timeLeft = nextReset and (nextReset - currentTime) or 0
                
                if myList[raidId] ~= 0 then
                    GameTooltip:AddLine("  |cffff0000" .. raidName .. "|cffff0000 - 锁定ID: " .. myList[raidId] .. " (重置: " .. FormatTimeLeft(timeLeft) .. ")")
                else
                    GameTooltip:AddLine("  |cff00ff00" .. raidName .. "|r - 未锁定 (重置: " .. FormatTimeLeft(timeLeft) .. ")")
                end
            end
        end
        GameTooltip:AddLine(" ")
    end    
	
    local currentLocation, nextLocation, timeLeft = GetDarkmoonFaireInfo()
    GameTooltip:AddLine("|cffff0000暗月马戏团|r")
    GameTooltip:AddLine("  当前: |cff00ff00" .. currentLocation .. "|r    下次: |cff00ff00" .. nextLocation .. " (" .. FormatTimeLeft(timeLeft) .. ")|r"  )
    GameTooltip:AddLine(" ")
    
    local currentBoss, nextBoss, zgTimeLeft = GetZGHiddenBossInfo()
    GameTooltip:AddLine("|cffff0000祖格隐藏BOSS|r")
    GameTooltip:AddLine("  本轮: |cff00ff00" .. currentBoss .. "|r    下轮: |cff00ff00" .. nextBoss .. " (" .. FormatTimeLeft(zgTimeLeft) .. ")|r")
    GameTooltip:AddLine(" ")
    
    local currentBG, nextBG, bgTimeLeft = GetBattlegroundBonusInfo()
    GameTooltip:AddLine("|cffff0000双倍战场|r")
    GameTooltip:AddLine("  今日: |cff00ff00" .. currentBG .. "|r    明日: |cff00ff00" .. nextBG .. " (" .. FormatTimeLeft(bgTimeLeft) .. ")|r")
    GameTooltip:AddLine(" ")
    
    GameTooltip:AddLine("最后更新: " .. date("%H:%M:%S", lastUpdateTime) .. ";  左键:集合石 or LFT;  右键:手动刷新", .3, 1, .6)
	GameTooltip:AddLine("按住 Alt 显示同账号其他角色团本CD", 0.8, 0.8, 1)
    
    GameTooltip:Show()
end

-- =============================================================================
-- 鼠标悬停事件（包含Alt切换）
-- =============================================================================

-- 创建独立的 Alt 监测 Frame
local altMonitor = CreateFrame("Frame")
altMonitor:Hide()

diminfo_RaidCD:SetScript("OnEnter", function()
    local currentAlt = nil
    
    -- 刷新提示内容的函数
    local function RefreshTooltip()
        GameTooltip:ClearLines()
        GameTooltip:SetOwner(diminfo_RaidCD, "ANCHOR_BOTTOMRIGHT")
        
        if IsAltKeyDown() then
            -- ====== Alt按下：显示其他角色的CD信息 ======
            GameTooltip:AddLine("同账号其他角色团本CD", 1, 1, 0)
            GameTooltip:AddLine(" ")
            
            local others = GetOtherCharactersRaidCD()
            if next(others) then
                for char, raids in pairs(others) do
                    GameTooltip:AddLine(char .. "：")
                    for _, raidName in ipairs(raids) do
                        GameTooltip:AddLine("  |cffff0000" .. raidName .. "|r")
                    end
                    GameTooltip:AddLine(" ")
                end
            else
                GameTooltip:AddLine("暂无其他角色数据", 0.5, 0.5, 0.5)
            end
        else
            ShowRaidCDTooltip() 
        end
        
        GameTooltip:Show()
    end
    
    -- 首次显示
    RefreshTooltip()
    
    -- Alt监测
    altMonitor:SetScript("OnUpdate", function(self, elapsed)
        local altDown = IsAltKeyDown()
        if altDown ~= currentAlt then
            currentAlt = altDown
            RefreshTooltip()
        end
    end)
    altMonitor:Show()
end)

diminfo_RaidCD:SetScript("OnLeave", function()
    GameTooltip:Hide()
    altMonitor:Hide()
    altMonitor:SetScript("OnUpdate", nil)
end)

-- =============================================================================
-- 点击事件
-- =============================================================================

diminfo_RaidCD:SetScript("OnMouseDown", function()
    if arg1 == "RightButton" then
        if not RAID_CONFIG.default then
            ForceUpdateRaidData()
            if MouseIsOver(diminfo_RaidCD) then
                local onEnterFunc = diminfo_RaidCD:GetScript("OnEnter")
                if onEnterFunc then
                    onEnterFunc(diminfo_RaidCD)
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00团本CD信息已手动刷新|r")
        else
            return
        end
    elseif arg1 == "LeftButton" then
        if Meeting and Meeting.Toggle then
            Meeting:Toggle()
        else
            LFT_Toggle()
        end
    end
end)

-- =============================================================================
-- 事件触发
-- =============================================================================

-- 延时函数
local function Schedule(delay, func)
    local frame = CreateFrame("Frame")
    local elapsed = 0
    
    frame:SetScript("OnUpdate", function()        
        local sinceLastUpdate = arg1 or 0
        elapsed = elapsed + sinceLastUpdate
        if elapsed >= delay then
            func()
            this:SetScript("OnUpdate", nil)
        end
    end)
    
    return frame
end

-- 注册事件
diminfo_RaidCD:RegisterEvent("PLAYER_ENTERING_WORLD")
diminfo_RaidCD:RegisterEvent("CHAT_MSG_SYSTEM")
diminfo_RaidCD:RegisterEvent("PLAYER_LEVEL_UP")

diminfo_RaidCD:SetScript("OnEvent", function()
    local event = event
    local msg = arg1
    
    if event == "PLAYER_ENTERING_WORLD" then
        RAID_CONFIG, CURRENT_SERVER_NAME = GetCurrentServerConfig()
        RAID_NAME_TO_ID = CreateRaidNameToIDMap()
        
        Schedule(2, function()
            ForceUpdateRaidData()
        end)
		
	elseif event == "PLAYER_LEVEL_UP" then
        UpdateDisplay()	
        
    elseif event == "CHAT_MSG_SYSTEM" then
        if msg and (string.find(msg, "保存") or string.find(msg, "saved")) then
            Schedule(2, function()                
                RequestRaidInfo()
            end)
            Schedule(4, function()                
                ForceUpdateRaidData()
            end)
			Schedule(6, function()                
                ForceUpdateRaidData()
            end)
        end
    end
end)

-- 初始显示
UpdateDisplay()