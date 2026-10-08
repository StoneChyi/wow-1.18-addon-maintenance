local _G, _ = _G or getfenv()

-- todo tankmode messages to send if guid is target, for tankmode highlight
-- todo save TWT_SPEC per sender so it caches from other people's inspects
--    SendAddonMessage(TWT.prefix, TWTtargetGUID, TWT.channel)
local __lower = string.lower
local __repeat = string.rep
local __strlen = string.len
local __find = string.find
local __substr = string.sub
local __parseint = tonumber
local __parsestring = tostring
local __getn = table.getn
local __tinsert = table.insert
local __tsort = table.sort
local __pairs = pairs
local __floor = math.floor
local __abs = abs
local __char = string.char

TWT = CreateFrame("Frame")

TWT.addonVer = '9.9.9'
TWT.threatApi = 'TWTv4=';
TWT.tankModeApi = 'TMTv1=';
TWT.UDTS = 'TWT_UDTSv4';
TWT.showedUpdateNotification = false
TWT.addonName = '|cffabd473TWT|cff11cc11 |cffcdfe00仇恨统计器'
-- 目标GUID和名称缓存表
TWTtargetGUIDCache = TWTtargetGUIDCache or {}

-- 清理不存在的目标ID
function TWT.cleanupTargetGUIDCache()
    local removed = 0
    for guid, _ in pairs(TWTtargetGUIDCache) do
        if not UnitExists(guid) then
            TWTtargetGUIDCache[guid] = nil
            removed = removed + 1
        end
    end
    if removed > 0 and TWT_CONFIG.debug then
        twtdebug('Cleaned up ' .. removed .. ' invalid target GUIDs')
    end
end

-- 清空目标缓存
function TWT.clearTargetGUIDCache()
    TWTtargetGUIDCache = {}
    if TWT_CONFIG.debug then
        twtdebug('Target GUID cache cleared')
    end
end

-- 更新目标GUID的函数
function TWT.updateTargetGUID()
    local isLeader = IsRaidOfficer()
    local isAssistant = IsRaidLeader()
    TWT.isGroupLeaderOrAssistant = isLeader or isAssistant 
end



-- 通过ID查找目标名称
function TWT.getTargetNameByID(id)
    -- 将数字ID转换为16进制
    local hexID = string.format('%X', id)
    -- 确保是6位
    hexID = string.sub(string.rep('0', 6) .. hexID, -6)
    
    -- 在缓存中查找匹配的GUID
    for guid, name in pairs(TWTtargetGUIDCache) do
        -- 提取GUID的最后6位
        local guidSuffix = string.sub(guid, -6)
        if string.upper(guidSuffix) == hexID then
            -- 获取目标的标记编号
            local raidTargetIndex = GetRaidTargetIndex(guid)
            twtdebug('Found target ' .. name .. ' with GUID ' .. guid .. ' and raid index ' .. (raidTargetIndex or 'nil'))
            return name, raidTargetIndex,guid
        end
    end
    
    -- 如果缓存中没有找到，尝试直接通过ID获取单位
    local unitId = 'target'
    if UnitExists(unitId) then
        local  _,unitGUID = UnitExists(unitId)
        if unitGUID then
            local guidSuffix = string.sub(unitGUID, -6)
            if string.upper(guidSuffix) == hexID then
                local unitName = UnitName(unitId)
                local raidTargetIndex = GetRaidTargetIndex(unitId)
                twtdebug('Found target directly: ' .. unitName .. ' with raid index ' .. (raidTargetIndex or 'nil'))
                -- 保存到缓存
                TWTtargetGUIDCache[unitGUID] = unitName
                return unitName, raidTargetIndex
            end
        end
    end
    
    -- 如果仍然没找到，返回原始ID和nil标记编号
    twtdebug('Target not found with ID ' .. id)
    return '目标-'..id, nil
end

TWT.prefix  = 'TWT'
TWT.channel = 'RAID'
TWT.name = UnitName('player')
local _, cl = UnitClass('player')
TWT.class = __lower(cl)

TWT.lastAggroWarningSoundTime = 0
TWT.lastAggroWarningGlowTime = 0
TWT.isGroupLeaderOrAssistant = false
TWT.lastDeathMessageTime = 0
TWT.lastReplyMessageTime = 0
TWT.tempMessagee = false
TWT.AGRO = '-Pull Aggro at-'
TWT.threatsFrames = {}
TWT.limit = 0 -- 存储仇恨限制值

TWT.threats = {}

TWT.targetName = ''
TWT.relayTo = {}
TWT.shouldRelay = false
TWT.inCombat = false
TWT.healerMasterTarget = ''

TWT.updateSpeed = 0.2

TWT.targetFrameVisible = false
TWT.PFUItargetFrameVisible = false

TWT.nameLimit = 30
TWT.windowStartWidth = 300
TWT.windowWidth = 300
TWT.minBars = 5
TWT.maxBars = 18

TWT.roles = {}
TWT.spec = {}

TWT.tankModeThreats = {}

TWT.custom = {
    ['The Prophet Skeram'] = 0
}

TWT.withAddon = 0
TWT.addonStatus = {}

TWT.classColors = {
    ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
    ["mage"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
    ["rogue"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
    ["druid"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
    ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
    ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
    ["priest"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
    ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
    ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, c = "|cfff58cba" },
    ["agro"] = { r = 0.96, g = 0.1, b = 0.1, c = "|cffff1111" },
      ["other"] = { r = 0.8, g = 0.8, b = 0.8, c = "|cffaaaaaa" }
}

TWT.classCoords = {
    ["priest"] = { 0.52, 0.73, 0.27, 0.48 },
    ["mage"] = { 0.23, 0.48, 0.02, 0.23 },
    ["warlock"] = { 0.77, 0.98, 0.27, 0.48 },
    ["rogue"] = { 0.48, 0.73, 0.02, 0.23 },
    ["druid"] = { 0.77, 0.98, 0.02, 0.23 },
    ["hunter"] = { 0.02, 0.23, 0.27, 0.48 },
    ["shaman"] = { 0.27, 0.48, 0.27, 0.48 },
    ["warrior"] = { 0.02, 0.23, 0.02, 0.23 },
    ["paladin"] = { 0.02, 0.23, 0.52, 0.73 },
      ["other"] = { 0.52, 0.73, 0.27, 0.48 },
}

TWT.fonts = {
    '粗圆', 
}


function twtprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('[TWT]|cff0070de:' .. GetTime() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage(TWT.classColors[TWT.class].c .. "[TWT] |cffffffff" .. a)
end

function twtdebug(a)
    local time = GetTime() + 0.0001
    if not TWT_CONFIG.debug then
        return false
    end
    if a == nil then
        twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff attempt to print a nil value.')
        return
    end
    if type(a) == 'boolean' then
        if a then
            twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff[true]')
        else
            twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff[false]')
        end
        return true
    end
    twtprint('|cff0070de[D:' .. time .. ']|cffffffff[' .. a .. ']')
end

SLASH_TWT1 = "/twt"
SLASH_TWT2 = "/tw"
SlashCmdList["TWT"] = function(cmd)
    if cmd then
        if __substr(cmd, 1, 4) == 'show' then
            _G['TWTMain']:Show()
            TWT_CONFIG.visible = true
            return true
        end
        if __substr(cmd, 1, 8) == 'tankmode' then
            if TWT_CONFIG.tankMode then
                twtprint('Tank Mode is already enabled.')
                return false
            else
                TWT_CONFIG.tankMode = true
                twtprint('Tank Mode enabled.')
            end
            return true
        end
        if __substr(cmd, 1, 6) == 'skeram' then
            if TWT_CONFIG.skeram then
                TWT_CONFIG.skeram = false
                twtprint('Skeram module disabled.')
                return true
            end
            TWT_CONFIG.skeram = true
            twtprint('Skeram module enabled.')
            return true
        end
        if __substr(cmd, 1, 5) == 'debug' then
            if TWT_CONFIG.debug then
                TWT_CONFIG.debug = false
                _G['pps']:Hide()
                twtprint('Debugging disabled')
                return true
            end
            TWT_CONFIG.debug = true
            _G['pps']:Show()
            twtdebug('Debugging enabled')
            return true
        end
        
        -- 重置窗口位置到屏幕中央
        if __substr(cmd, 1, 2) == 'rl' then
            local frame = _G['TWTMain']
            if frame then
                frame:ClearAllPoints()
                frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
                twtprint('窗口位置已重置到屏幕中央')
            else
                twtprint('无法找到TWT主窗口')
            end
            return true
        end
        
        -- 重新加载初始化设置
        if __substr(cmd, 1, 3) == 'ini' then
            twtprint('重新加载初始化设置...')
            TWT.init()
            twtprint('初始化设置已重新加载')
            return true
        end


        if __substr(cmd, 1, 3) == 'who' then
            TWT.queryWho()
            return true
        end

        twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff available commands:')
        twtprint('/twt show - 显示主窗口 (也可用 /twtshow)')
        twtprint('/twt debug - 启用/禁用调试模式 (也可用 /twtdebug)')
        twtprint('/twt rl - 重置窗口位置到屏幕中央')
        twtprint('/twt ini - 重新加载初始化设置')
        twtprint('/twt who - 查询团队成员信息')
        twtprint('注意: 所有 /twt 命令也可以使用 /tw 前缀')
    end
end

SLASH_TWTSHOW1 = "/twtshow"
SlashCmdList["TWTSHOW"] = function(cmd)
    if cmd then
        _G['TWTMain']:Show()
        TWT_CONFIG.visible = true
    end
end

SLASH_TWTDEBUG1 = "/twtdebug"
SlashCmdList["TWTDEBUG"] = function(cmd)
    if cmd then
        if TWT_CONFIG.debug then
            TWT_CONFIG.debug = false
            twtprint('Debugging disabled')
            return true
        end
        TWT_CONFIG.debug = true
        twtdebug('Debugging enabled')
        return true
    end
end

TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("PLAYER_REGEN_DISABLED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")
TWT:RegisterEvent("PLAYER_ENTERING_WORLD")
TWT:RegisterEvent("PARTY_MEMBERS_CHANGED")
TWT:RegisterEvent("UNIT_HEALTH")
TWT:RegisterEvent("UNIT_MODEL_CHANGED")
TWT:RegisterEvent("ZONE_CHANGED_NEW_AREA")

TWT.threatQuery = CreateFrame("Frame")
TWT.threatQuery:Show()
TWT.history = {}
TWT.tankName = ''
TWT.classes = {}

local timeStart = GetTime()
local totalPackets = 0
local totalData = 0
local uiUpdates = 0

TWT:SetScript("OnEvent", function()
    if event then
        if event == 'ADDON_LOADED' and arg1 == 'TWThreat' then
            return TWT.init()
        end

        if event == "PARTY_MEMBERS_CHANGED" then
            return TWT.getClasses()
        end
        if event == "PLAYER_ENTERING_WORLD" then
            -- TWT.sendMyVersion()
            TWT.combatEnd()
            if UnitAffectingCombat('player') then
                TWT.combatStart(true)
            end
            -- 进入世界时清理缓存
            TWT.cleanupTargetGUIDCache()
            return true
        end
        
        -- 切换地图时清空缓存
        if event == "ZONE_CHANGED_NEW_AREA" then
            TWT.clearTargetGUIDCache()
            return true
        end
        
        -- -- 处理仇恨限制消息
        if event == 'CHAT_MSG_ADDON' and __find(arg2, 'limit=', 1, true) then
            local limit = __substr(arg2, 6) -- 获取等号后面的数字
            TWT.handleLimitPacket(limit)
            return true
        end
        local currentTime = GetTime()
        if currentTime - TWT.lastReplyMessageTime >= 2 then
         if event == 'CHAT_MSG_ADDON' and arg2 == "DEAD_MSG" and TWT.isGroupLeaderOrAssistant then
           TWT.tempMessagee = true
              TWT.lastReplyMessageTime = currentTime
             end
        end
        if event == 'CHAT_MSG_ADDON' and __find(arg2, TWT.threatApi, 1, true) then
            if TWT.tempMessagee then
                SendAddonMessage(arg1,arg2,arg3)
                TWT.tempMessagee = false
            end
                twtdebug('Received message: ' .. arg2)
            totalPackets = totalPackets + 1
            totalData = totalData + __strlen(arg2)
            local threatData = arg2
            if __find(threatData, '#') and __find(threatData, TWT.tankModeApi) then
                local packetEx = __explode(threatData, '#')
                if packetEx[1] and packetEx[2] then
                    threatData = packetEx[1]
                    TWT.handleTankModePacket(packetEx[2])
                end
            end            
            return TWT.handleThreatPacket(threatData)
        end

        -- 修改条件判断，只要arg1包含'twt'字符串即可
        if event == 'CHAT_MSG_ADDON' and string.find(string.lower(arg1), 'twt') then
            if __substr(arg2, 1, 11) == 'TWTVersion:' and arg4 ~= TWT.name then
                if not TWT.showedUpdateNotification then
                    local verEx = __explode(arg2, ':')
                    if TWT.version(verEx[2]) > TWT.version(TWT.addonVer) then
                        twtprint('New version available ' ..
                                TWT.classColors[TWT.class].c .. 'v' .. verEx[2] .. ' |cffffffff(current version ' ..
                                TWT.classColors['paladin'].c .. 'v' .. TWT.addonVer .. '|cffffffff)')
                        twtprint('Update at ' .. TWT.classColors[TWT.class].c .. 'https://github.com/CosminPOP/TWThreat')
                        TWT.showedUpdateNotification = true
                    end
                end
                return true
            end

            if __substr(arg2, 1, 7) == 'TWT_WHO' then
                TWT.send('TWT_ME:' .. TWT.addonVer)
                return true
            end

            if __substr(arg2, 1, 15) == 'TWTRoleTexture:' then
                local tex = __explode(arg2, ':')[2] or ''
                TWT.roles[arg4] = tex
                return true
            end

            if __substr(arg2, 1, 7) == 'TWT_ME:' then

                if TWT.addonStatus[arg4] then

                    local msg = __explode(arg2, ':')[2]
                    local verColor = ""
                    if TWT.version(msg) == TWT.version(TWT.addonVer) then
                        verColor = TWT.classColors['hunter'].c
                    end
                    if TWT.version(msg) < TWT.version(TWT.addonVer) then
                        verColor = '|cffff1111'
                    end
                    if TWT.version(msg) + 1 == TWT.version(TWT.addonVer) then
                        verColor = '|cffff8810'
                    end

                    TWT.addonStatus[arg4]['v'] = '    ' .. verColor .. msg
                    TWT.withAddon = TWT.withAddon + 1

                    TWT.updateWithAddon()

                    return true
                end

                return false
            end

            return false

        end
        if event == "PLAYER_REGEN_DISABLED" then
            return TWT.combatStart(true)
        end
        if event == "PLAYER_REGEN_ENABLED" then
            return TWT.combatEnd()
        end
        if event == "PLAYER_TARGET_CHANGED" then

            if not TWT.targetChanged() then
                TWT.hideThreatFrames(true)
            end

            return true
        end
        
        -- 处理 UNIT_MODEL_CHANGED 事件 - 保存 GUID 和 单位名称
        if event == "UNIT_MODEL_CHANGED" then
            local guid = arg1
            if guid and UnitExists(guid) then
                local unitName = UnitName(guid)
                if unitName then
                    -- 保存到目标 GUID 缓存
                    TWTtargetGUIDCache[guid] = unitName
                    twtdebug('UNIT_MODEL_CHANGED: Saved ' .. unitName .. ' (' .. guid .. ')')
                end
            end
            
            -- 同时记录自己的当前目标
            if UnitExists("target") then
                local _,guid = UnitExists("target")
                local unitName = UnitName(guid)
                if unitName then
                     TWTtargetGUIDCache[guid] = unitName
                    twtdebug('UNIT_MODEL_CHANGED: Also saved current target ' .. unitName .. ' (' .. guid .. ')')
                end
            end
            
            return true
        end
        
        -- 处理 NAME_PLATE_UNIT_ADDED 事件 - 确保名称板单位的 GUID 被缓存
        if event == "NAME_PLATE_UNIT_ADDED" then
            local unitId = arg1
            if unitId and UnitExists(unitId) then
                local _,guid = UnitExists(unitId)
                local unitName = UnitName(unitId)
                if guid and unitName then
                    TWTtargetGUIDCache[guid] = unitName
                    twtdebug('NAME_PLATE_UNIT_ADDED: Saved ' .. unitName .. ' (' .. guid .. ')')
                end
            end
            return true
        end

        -- 处理 UPDATE_MOUSEOVER_UNIT 事件 - 缓存鼠标悬停单位的 GUID
        if event == "UPDATE_MOUSEOVER_UNIT" then
            local unitId = "mouseover"
            if UnitExists(unitId) then
                local _,guid = UnitExists(unitId)
                local unitName = UnitName(unitId)
                if guid and unitName then
                    TWTtargetGUIDCache[guid] = unitName
                    twtdebug('UPDATE_MOUSEOVER_UNIT: Saved ' .. unitName .. ' (' .. guid .. ')')
                end
            end
            return true
        end
    end
end)

function QueryWho_OnClick()
    TWT.queryWho()
end



function TWT.queryWho()
    TWT.withAddon = 0
    TWT.addonStatus = {}
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            local _, class = UnitClass('raid' .. i)

            TWT.addonStatus[n] = {
                ['class'] = __lower(class),
                ['v'] = '|cff888888   -   '
            }
            if z == '离线' then
                TWT.addonStatus[n]['v'] = '|cffff0000offline'
            end
        end
    end
    twtprint('Sending who query...')
    _G['TWTWithAddonList']:Show()
    TWT.send('TWT_WHO')
end

function TWT.updateWithAddon()

    local rosterList = ''
    local i = 0
    for n, data in next, TWT.addonStatus do
        i = i + 1
        rosterList = rosterList .. TWT.classColors[data['class']].c .. n .. __repeat(' ', 12 - __strlen(n)) .. ' ' .. data['v'] .. ' |cff888888'
        if i < 4 then
            rosterList = rosterList .. '| '
        end
        if i == 4 then
            rosterList = rosterList .. '\n'
            i = 0
        end
    end
    _G['TWTWithAddonListText']:SetText(rosterList)
    _G['TWTWithAddonListTitle']:SetText('Addon Raid Status ' .. TWT.withAddon .. '/' .. GetNumRaidMembers())
end

TWT.glowFader = CreateFrame('Frame')
TWT.glowFader:Hide()

TWT.glowFader:SetScript("OnShow", function()
    this.startTime = GetTime() - 1
    this.dir = 10
    _G['TWTFullScreenGlow']:SetAlpha(0.01)
    _G['TWTFullScreenGlow']:Show()
end)
TWT.glowFader:SetScript("OnHide", function()
    this.startTime = GetTime()
end)
TWT.glowFader:SetScript("OnUpdate", function()
    local plus = 0.04
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()

        if _G['TWTFullScreenGlow']:GetAlpha() >= 0.6 then
            this.dir = -1
        end

        _G['TWTFullScreenGlow']:SetAlpha(_G['TWTFullScreenGlow']:GetAlpha() + 0.03 * this.dir)

        if _G['TWTFullScreenGlow']:GetAlpha() <= 0 then
            TWT.glowFader:Hide()
        end


    end
end)

function TWT.init()

    if not TWT_CONFIG then
        TWT_CONFIG = {
            visible = true,
            colTPS = true,
            colThreat = true,
            colPerc = true,
            labelRow = true,
        }
    end

    TWT_CONFIG.windowScale = TWT_CONFIG.windowScale or 1
    TWT_CONFIG.glow = TWT_CONFIG.glow or false
    TWT_CONFIG.perc = TWT_CONFIG.perc or false
    TWT_CONFIG.glowPFUI = TWT_CONFIG.glowPFUI or false
    TWT_CONFIG.percPFUI = TWT_CONFIG.percPFUI or false
    TWT_CONFIG.percPFUItop = TWT_CONFIG.percPFUItop or false
    TWT_CONFIG.percPFUIbottom = TWT_CONFIG.percPFUIbottom or false
    TWT_CONFIG.percPFUIoffsetX = TWT_CONFIG.percPFUIoffsetX or 0
    TWT_CONFIG.percPFUIoffsetY = TWT_CONFIG.percPFUIoffsetY or 0
    TWT_CONFIG.showInCombat = TWT_CONFIG.showInCombat or false
    TWT_CONFIG.hideOOC = TWT_CONFIG.hideOOC or false
    TWT_CONFIG.font = TWT_CONFIG.font or 'Roboto'
    TWT_CONFIG.fontSize = TWT_CONFIG.fontSize or 14
    TWT_CONFIG.barHeight = TWT_CONFIG.barHeight or 20
    TWT_CONFIG.visibleBars = TWT_CONFIG.visibleBars or TWT.minBars
    -- Ensure visibleBars is at least minBars and at most maxBars
    TWT_CONFIG.visibleBars = math.max(TWT.minBars, math.min(TWT.maxBars, TWT_CONFIG.visibleBars))
    TWT_CONFIG.fullScreenGlow = TWT_CONFIG.fullScreenGlow or false
    TWT_CONFIG.aggroSound = TWT_CONFIG.aggroSound or false
    TWT_CONFIG.aggroThreshold = TWT_CONFIG.aggroThreshold or 85
    TWT_CONFIG.tankMode = TWT_CONFIG.tankMode or false
    TWT_CONFIG.tankModeStick = TWT_CONFIG.tankModeStick or 'Free' -- Top, Right, Left, Right, Free
    TWT_CONFIG.lock = TWT_CONFIG.lock or false
    TWT_CONFIG.visible = TWT_CONFIG.visible or false
    TWT_CONFIG.colTPS = TWT_CONFIG.colTPS or false
    TWT_CONFIG.colThreat = TWT_CONFIG.colThreat or false
    TWT_CONFIG.colPerc = TWT_CONFIG.colPerc or false
    TWT_CONFIG.labelRow = TWT_CONFIG.labelRow or false
    TWT_CONFIG.skeram = TWT_CONFIG.skeram or false

    TWT_CONFIG.combatAlpha = TWT_CONFIG.combatAlpha or 1
    TWT_CONFIG.oocAlpha = TWT_CONFIG.oocAlpha or 1
    TWT_CONFIG.useCustomTitleColor = TWT_CONFIG.useCustomTitleColor or false
    TWT_CONFIG.customTitleColor = TWT_CONFIG.customTitleColor or { r = 0.5, g = 0.5, b = 1 }
    TWT_CONFIG.customTitleAlpha = TWT_CONFIG.customTitleAlpha or 1
    TWT_CONFIG.titleHeight = TWT_CONFIG.titleHeight or 20
    TWT_CONFIG.dataLimit = TWT_CONFIG.dataLimit or 6

    if TWT.class ~= 'paladin' and TWT.class ~= 'warrior' and TWT.class ~= 'druid' then
        _G['TWTMainSettingsTankMode']:Disable()
        TWT_CONFIG.tankMode = false
    end

    TWT_CONFIG.debug = TWT_CONFIG.debug or false

    if TWT_CONFIG.visible then
        _G['TWTMain']:Show()
    else
        _G['TWTMain']:Hide()
    end

    if TWT_CONFIG.tankMode then
        _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)
        _G['TWTMainSettingsFullScreenGlow']:Disable()
        _G['TWTMainSettingsAggroSound']:SetChecked(TWT_CONFIG.fullScreenGlow)
        _G['TWTMainSettingsAggroSound']:Disable()
    end

    if TWT_CONFIG.lock then
        _G['TWTMainLockButton']:SetNormalTexture('Interface\\addons\\TWThreat\\images\\icon_locked')
    else
        _G['TWTMainLockButton']:SetNormalTexture('Interface\\addons\\TWThreat\\images\\icon_unlocked')
    end

    _G['TWTFullScreenGlowTexture']:SetWidth(GetScreenWidth())
    _G['TWTFullScreenGlowTexture']:SetHeight(GetScreenHeight())

    -- 初始化标题栏高度滑块
    if _G['TWTMainSettingsTitleHeightSlider'] then
        _G['TWTMainSettingsTitleHeightSlider']:SetValue(TWT_CONFIG.titleHeight)
    end

    _G['TWTMainSettingsFrameHeightSlider']:SetValue(TWT_CONFIG.barHeight) -- calls FrameHeightSlider_OnValueChanged()
    _G['TWTMainSettingsWindowScaleSlider']:SetValue(TWT_CONFIG.windowScale) -- calls FrameHeightSlider_OnValueChanged()
    _G['TWTMainSettingsFontSizeSlider']:SetValue(TWT_CONFIG.fontSize) -- calls FontSizeSlider_OnValueChanged()

    _G['TWTMainSettingsCombatAlphaSlider']:SetValue(TWT_CONFIG.combatAlpha) -- calls CombatOpacitySlider_OnValueChanged()
    _G['TWTMainSettingsOOCAlphaSlider']:SetValue(TWT_CONFIG.oocAlpha) -- calls OOCombatSlider_OnValueChanged()



    _G['TWTMainSettingsAggroThresholdSlider']:SetValue(TWT_CONFIG.aggroThreshold) -- calls AggroThresholdSlider_OnValueChanged()
    _G['TWTMainSettingsDataLimitSlider']:SetValue(TWT_CONFIG.dataLimit) -- calls DataLimitSlider_OnValueChanged()
    
    -- 初始化窗口高度
    local titleHeight = TWT_CONFIG.titleHeight
    local labelRowHeight = TWT_CONFIG.labelRow and (math.floor(titleHeight * 0.8) + 8) or 0
    _G['TWTMain']:SetHeight(TWT_CONFIG.barHeight * TWT_CONFIG.dataLimit + titleHeight + labelRowHeight)

    _G['TWTMainSettingsFontButton']:SetText(TWT_CONFIG.font)

    _G['TWTMainSettingsTargetFrameGlow']:SetChecked(TWT_CONFIG.glow)
    _G['TWTMainSettingsTargetFrameGlowPFUI']:SetChecked(TWT_CONFIG.glowPFUI)
    _G['TWTMainSettingsPercNumbers']:SetChecked(TWT_CONFIG.perc)
    _G['TWTMainSettingsPercNumbersPFUI']:SetChecked(TWT_CONFIG.percPFUI)
    _G['TWTMainSettingsPercNumbersPFUItop']:SetChecked(TWT_CONFIG.percPFUItop)
    _G['TWTMainSettingsPercNumbersPFUIbottom']:SetChecked(TWT_CONFIG.percPFUIbottom)
    if _G['TWTMainSettingsPercNumbersPFUIoffsetX'] then
        _G['TWTMainSettingsPercNumbersPFUIoffsetX']:SetText(TWT_CONFIG.percPFUIoffsetX)
    end
    if _G['TWTMainSettingsPercNumbersPFUIoffsetY'] then
        _G['TWTMainSettingsPercNumbersPFUIoffsetY']:SetText(TWT_CONFIG.percPFUIoffsetY)
    end
    _G['TWTMainSettingsShowInCombat']:SetChecked(TWT_CONFIG.showInCombat)
    _G['TWTMainSettingsHideOOC']:SetChecked(TWT_CONFIG.hideOOC)
    _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)
    _G['TWTMainSettingsAggroSound']:SetChecked(TWT_CONFIG.aggroSound)
    _G['TWTMainSettingsTankMode']:SetChecked(TWT_CONFIG.tankMode)

    _G['TWTMainSettingsColumnsTPS']:SetChecked(TWT_CONFIG.colTPS)
    _G['TWTMainSettingsColumnsThreat']:SetChecked(TWT_CONFIG.colThreat)
    _G['TWTMainSettingsColumnsPercent']:SetChecked(TWT_CONFIG.colPerc)

    _G['TWTMainSettingsLabelRow']:SetChecked(TWT_CONFIG.labelRow)

    -- 先设置标签行显隐，再设置列标签位置（列标签内部会根据 labelRow 决定显示）
    TWT.updateLabelRowVisibility()
    TWT.setColumnLabels()

    _G['TWTMainSettingsFontButtonNT']:SetVertexColor(0.4, 0.4, 0.4)

    local color = TWT.classColors[TWT.class]

    _G['TWTMainTitleBG']:SetVertexColor(color.r, color.g, color.b)
    _G['TWTMainSettingsTitleBG']:SetVertexColor(color.r, color.g, color.b)
    _G['TWTMainTankModeWindowTitleBG']:SetVertexColor(color.r, color.g, color.b)

    _G['TWThreatDisplayTarget']:SetScale(UIParent:GetScale())

    -- fonts
    local fontFrames = {}

    for i, font in TWT.fonts do
        fontFrames[i] = CreateFrame('Button', 'Font_' .. font, _G['TWTMainSettingsFontList'], 'TWTFontFrameTemplate')

        fontFrames[i]:SetPoint("TOPLEFT", _G["TWTMainSettingsFontList"], "TOPLEFT", 0, 17 - i * 17)

        _G['Font_' .. font]:SetID(i)
        _G['Font_' .. font .. 'Name']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. font .. ".ttf", 20)
        _G['Font_' .. font .. 'Name']:SetText(font)
        _G['Font_' .. font .. 'HT']:SetVertexColor(1, 1, 1, 0.5)

        fontFrames[i]:Show()
    end

    --UnitPopupButtons["INSPECT_TALENTS"] = { text = 'Inspect Talents', dist = 0 }
    --
    --TWT.addInspectMenu("PARTY")
    --TWT.addInspectMenu("PLAYER")
    --TWT.addInspectMenu("RAID")
    --
    --TWT.hooksecurefunc("UnitPopup_OnClick", function()
    --    local button = this.value
    --    if button == "INSPECT_TALENTS" then
    --
    --        _G['TWTTalentFrame']:Hide()
    --
    --        TWT_SPEC = {
    --            class = UnitClass('target'),
    --            {
    --                name = 'Arms',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 27,
    --                numTalents = 18
    --            },
    --            {
    --                name = 'Fury',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 24,
    --                numTalents = 17
    --            },
    --            {
    --                name = 'Protection',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 0,
    --                numTalents = 17
    --            }
    --        }
    --
    --        TWT.send('TWTShowTalents:' .. UnitName('target'))
    --
    --    end
    --end)
    --
    --UIParentLoadAddOn("Blizzard_TalentUI")

    TWT.updateTitleBarText()
    TWT.updateSettingsTabs(1)
    
    -- 设置初始设置界面状态
    if _G['TWTMainSettingsUseCustomTitleColor'] then
        _G['TWTMainSettingsUseCustomTitleColor']:SetChecked(TWT_CONFIG.useCustomTitleColor)
    end
    
    if _G['TWTMainSettingsTitleAlphaSlider'] then
        _G['TWTMainSettingsTitleAlphaSlider']:SetValue(TWT_CONFIG.customTitleAlpha)
    end
    
    -- 更新标题栏颜色
    TWTUpdateTitleBarColor()
    
    -- 初始化颜色选择器的颜色
    if _G['TWTMainSettingsTitleColorPickerNT'] and TWT_CONFIG.customTitleColor then
        _G['TWTMainSettingsTitleColorPickerNT']:SetVertexColor(
            TWT_CONFIG.customTitleColor.r,
            TWT_CONFIG.customTitleColor.g,
            TWT_CONFIG.customTitleColor.b
        )
    end

    TWT.checkTargetFrames()
    
    -- 初始化标题栏高度和UI元素位置
    TitleHeightSlider_OnValueChanged()

    twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff loaded.')
    return true
end

function TWT.updateSettingsTabs(tab)
    local color = TWT.classColors[TWT.class]
    _G['TWTMainSettingsTabsUnderline']:SetVertexColor(color.r, color.g, color.b)

    for i = 1, 3 do
        _G['TWTMainSettingsTab' .. i]:Hide()
        _G['TWTMainSettingsTab' .. i .. 'ButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['TWTMainSettingsTab' .. i .. 'ButtonHT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['TWTMainSettingsTab' .. i .. 'ButtonPT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['TWTMainSettingsTab' .. i .. 'ButtonText']:SetTextColor(0.4, 0.4, 0.4)
    end

    _G['TWTMainSettingsTab' .. tab .. 'ButtonNT']:SetVertexColor(color.r, color.g, color.b, 1)
    _G['TWTMainSettingsTab' .. tab .. 'ButtonText']:SetTextColor(1, 1, 1)

    _G['TWTMainSettingsTab' .. tab]:Show()

end

function TWTSettingsTab_OnClick(tab)
    TWT.updateSettingsTabs(tab)
end

function TWTHealerMasterTarget_OnClick()

    TWT.getClasses()

    if not UnitExists('target') or not UnitIsPlayer('target')
            or UnitName('target') == TWT.name then

        if TWT.healerMasterTarget == '' then
            twtprint('Please target a tank.')
        else
            TWT.removeHealerMasterTarget()
        end

        return false
    end

    if UnitName('target') == TWT.healerMasterTarget then
        return TWT.removeHealerMasterTarget()
    end

    TWT.send('TWT_HMT:' .. UnitName('target'))

    local color = TWT.classColors[TWT.getClass(UnitName('target'))]

    twtprint('Trying to set Healer Master Target to ' .. color.c .. UnitName('target'))

end

function TWT.removeHealerMasterTarget()
    TWT.send('TWT_HMT_REM:' .. TWT.healerMasterTarget)

    twtprint('Healer Master Target cleared.')

    TWT.healerMasterTarget = ''
    TWT.targetName = ''

    TWT.threats = TWT.wipe(TWT.threats)

    _G['TWTMainSettingsHealerMasterTargetButton']:SetText('From Target')
    _G['TWTMainSettingsHealerMasterTargetButtonNT']:SetVertexColor(1, 1, 1, 1)

    TWT.updateUI('removeHealerMasterTarget')

    return true
end

function TWT.addInspectMenu(to)
    local found = 0
    for i, j in UnitPopupMenus[to] do
        if j == "TRADE" then
            found = i
        end
    end
    if found ~= 0 then
        UnitPopupMenus[to][__getn(UnitPopupMenus[to]) + 1] = UnitPopupMenus[to][__getn(UnitPopupMenus[to])]
        for i = __getn(UnitPopupMenus[to]) - 1, found, -1 do
            UnitPopupMenus[to][i] = UnitPopupMenus[to][i - 1]
        end
    end
    UnitPopupMenus[to][found] = "INSPECT_TALENTS"
end


function TWT.getClass(name)
    return TWT.classes[name] or 'priest'
  end

function TWT.getClasses()
    if TWT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local name = GetRaidRosterInfo(i)
                local _, raidCls = UnitClass('raid' .. i)
                TWT.classes[name] = __lower(raidCls)
            end
        end
    end
    if TWT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) and UnitClass('party' .. i) then
                    local name = UnitName('party' .. i)
                    local _, raidCls = UnitClass('party' .. i)
                    TWT.classes[name] = __lower(raidCls)
                end
            end
        end
    end
    twtdebug('classes saved')
    return true
end



function TWT.handleThreatPacket(packet)

    --twtdebug(packet)

    local playersString = __substr(packet, __find(packet, TWT.threatApi) + __strlen(TWT.threatApi), __strlen(packet))

    TWT.threats = TWT.wipe(TWT.threats)
    TWT.tankName = ''

    local players = __explode(playersString, ';')

    for _, tData in players do

        local msgEx = __explode(tData, ':')

        -- udts handling
        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] then

            local player = msgEx[1]
            local tank = msgEx[2] == '1'
            local threat = __parseint(msgEx[3])
            local perc = __parseint(msgEx[4])
            local melee = msgEx[5] == '1'

            if UnitName('target') and not UnitIsPlayer('target') and TWT.shouldRelay then
                --relay
                for i, name in TWT.relayTo do
                    twtdebug('relaying to ' .. i .. ' ' .. name)
                end
                TWT.send('TWTRelayV1' ..
                        ':' .. UnitName('target') ..
                        ':' .. player ..
                        ':' .. msgEx[3] ..
                        ':' .. threat ..
                        ':' .. perc ..
                        ':' .. msgEx[6]);
            end

            local time = time()

            if TWT.history[player] then
                TWT.history[player][time] = threat
            else
                TWT.history[player] = {}
            end

            TWT.threats[player] = {
                threat = threat,
                tank = tank,
                perc = perc,
                melee = melee,
                tps = TWT.calcTPS(player),
                class = TWT.getClass(player)
            }

            if tank then
                TWT.tankName = player
            end
        end
    end

    if not TWT.threats[TWT.name] then
        TWT.threats[TWT.name] = {
                threat = 0,
                tank = 0,
                perc = 0,
                melee = 0,
                tps = 0,
                class = __lower(UnitClass('player'))
            }
    end
    
    TWT.calcAGROPerc()

    TWT.updateUI()

end

function TWT.handleLimitPacket(limit)
    -- 将限制值转换为数字
    TWT.limit = __parseint(limit) or 0 -- 如果解析失败，默认为0
    twtdebug('Received threat limit: ' .. TWT.limit)
    -- 更新UI以反映新的限制
    TWT.updateUI('limit_change')
end

function TWT.handleTankModePacket(packet)



    --twtdebug(msg)

    local playersString = __substr(packet, __find(packet, TWT.tankModeApi) + __strlen(TWT.tankModeApi), __strlen(packet))

    TWT.tankModeThreats = TWT.wipe(TWT.tankModeThreats)

    local players = __explode(playersString, ';')

    for _, tData in players do

        local msgEx = __explode(tData, ':')

        if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] then

            local creatureID = tonumber(msgEx[2])
            local creatureName, raidTargetIndex, unitguid = TWT.getTargetNameByID(creatureID)
            local guid = msgEx[2] --keep it string
            local name = msgEx[3]
            local perc = __parseint(msgEx[4])

            TWT.tankModeThreats[guid] = {
                creature = creatureName,
                name = name,
                perc = perc,
                originalID = guid,
                raidTargetIndex = raidTargetIndex,
                guid = unitguid,
            }
            TWT.updateUI('tankMode_change')

        end

    end

end

function TWT.calcAGROPerc()

    local tankThreat = 0
    for _, data in next, TWT.threats do
        if data.tank then
            tankThreat = data.threat
            break
        end
    end

    TWT.threats[TWT.AGRO] = {
        class = 'agro',
        threat = 0,
        perc = 10,
        tps = '',
        history = {},
        tank = false,
        melee = false
    }

    if not TWT.threats[TWT.name] then
        twtdebug('threats de name is bad')
        return false
    end

    TWT.threats[TWT.AGRO].threat = tankThreat * (TWT.threats[TWT.name].melee and 1.1 or 1.3)
    if TWT.threats[TWT.AGRO].threat == 0 then
        TWT.threats[TWT.AGRO].threat = 1
    end
    TWT.threats[TWT.AGRO].perc = TWT.threats[TWT.name].melee and 110 or 130

end

function TWT.combatStart(startforced)
    if TWT.inCombat == true and startforced ~= true then
        return
    end
    TWT.inCombat = true
    TWT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    --twtdebug('wipe threats combatstart')
    --TWT.threats = TWT.wipe(TWT.threats)
    --TWT.tankModeThreats = TWT.wipe(TWT.tankModeThreats)
    TWT.hideThreatFrames(true)
    TWT.shouldRelay = TWT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if TWT_CONFIG.showInCombat then
        _G['TWTMain']:Show()
    end

    TWT.spec = {}
    for t = 1, GetNumTalentTabs() do
        TWT.spec[t] = {
            talents = 0,
            texture = ''
        }
        for i = 1, GetNumTalents(t) do
            local _, _, _, _, currRank = GetTalentInfo(t, i);
            TWT.spec[t].talents = TWT.spec[t].talents + currRank
        end
    end

    local specIndex = 1
    for i = 2, 4 do
        local name, texture = GetSpellTabInfo(i);
        if name and texture then
            TWT.spec[specIndex].name = name
            texture = __explode(texture, '\\')
            texture = texture[__getn(texture)]
            TWT.spec[specIndex].texture = texture
            specIndex = specIndex + 1
        end
    end

    local sendTex = TWT.spec[1].texture
    if TWT.spec[2].talents > TWT.spec[1].talents and TWT.spec[2].talents > TWT.spec[3].talents then
        sendTex = TWT.spec[2].texture
    end
    if TWT.spec[3].talents > TWT.spec[1].talents and TWT.spec[3].talents > TWT.spec[2].talents then
        sendTex = TWT.spec[3].texture
    end

    -- 所有职业图标统一修正映射表
    local classIconMap = {
        ['warrior']   = 'Ability_Warrior_BattleShout',
        ['mage']      = 'Spell_Frost_SummonWaterElemental_2',
        ['rogue']     = 'Ability_Gouge',
        ['druid']     = 'Ability_Druid_Maul',
        ['hunter']    = 'Ability_Hunter_RunningShot',
        ['shaman']    = 'Spell_Nature_BloodLust',
        ['priest']    = 'spell_holy_holybolt',
        ['warlock']   = 'Spell_Nature_Drowsy',
        ['paladin']   = 'SPELL_HOLY_AVENGINEWRATH',
        ['other']     = 'Temp',
    }

    -- 应用职业图标修正
    if classIconMap[TWT.class] then
        sendTex = classIconMap[TWT.class]
    end

    TWT.send('TWTRoleTexture:' .. sendTex)

    TWT.getClasses()

    TWT.updateUI('combatStart')

    TWT.threatQuery:Show()
    TWT.barAnimator:Show()

    TWTTankModeWindowChangeStick_OnClick()

    _G['TWTMain']:SetAlpha(TWT_CONFIG.combatAlpha)

    return true
end

function TWT.combatEnd()
    TWT.inCombat = false
    TWT.updateTargetFrameThreatIndicators(-1, '')

    twtdebug('time = ' .. (TWT.round(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
            totalPackets / (GetTime() - timeStart) .. ' packets/s')

    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    twtdebug('wipe threats combat end')

    TWT.threats = TWT.wipe(TWT.threats)
    TWT.tankModeThreats = TWT.wipe(TWT.tankModeThreats)
    TWT.history = TWT.wipe(TWT.history)

    if TWT_CONFIG.hideOOC then
        _G['TWTMain']:Hide()
    end                               
    TWT.updateUI('combatEnd')

    TWT.barAnimator:Hide()

    if TWT_CONFIG.tankMode then
        _G['TWTMainTankModeWindow']:Hide()
    end

    _G['TWTWarning']:Hide()

    TWT.updateTitleBarText()

    _G['TWTMain']:SetAlpha(TWT_CONFIG.oocAlpha)

    TWT.hideThreatFrames(true)       

    return true

end

function TWT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if __getn(TWT.relayTo) == 0 then
        return false
    end

    -- in raid
    if TWT.channel == 'RAID' and GetNumRaidMembers() > 0 then
        for index, name in TWT.relayTo do
            local found = false
            for i = 0, GetNumRaidMembers() do
                if GetRaidRosterInfo(i) and UnitName('raid' .. i) == name then
                    found = true
                end
            end
            if not found then
                TWT.relayTo[index] = nil
                twtdebug(name .. ' removed from relay')
            end
        end
    end
    if TWT.channel == 'PARTY' and GetNumPartyMembers() > 0 then
        for index, name in TWT.relayTo do
            local found = false
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) == name then
                    found = true
                end
            end
            if not found then
                TWT.relayTo[index] = nil
                twtdebug(name .. ' removed from relay')
            end
        end
    end

    if __getn(TWT.relayTo) == 0 then
        return false
    end

    return true
end

function TWT.checkTargetFrames()
    if _G['TargetFrame']:IsVisible() ~= nil then
        TWT.targetFrameVisible = true
    else
        TWT.targetFrameVisible = false
    end

    if _G['pfTarget'] and _G['pfTarget']:IsVisible() ~= nil then
        TWT.PFUItargetFrameVisible = true
    else
        TWT.PFUItargetFrameVisible = false
    end
end

function TWT.hideThreatFrames(force)
    if TWT.tableSize(TWT.threats) == 0 or force then
        for name in next, TWT.threatsFrames do
            TWT.threatsFrames[name]:Hide()
        end
    end
end

function TWT.targetChanged()

    if not UnitAffectingCombat('player') and _G['TWTMainSettings']:IsVisible() == 1 then
        return true
    end

    TWT.channel = (GetNumRaidMembers() > 0) and 'RAID' or 'PARTY'

    if UIParent:GetScale() ~= _G['TWThreatDisplayTarget']:GetScale() then
        _G['TWThreatDisplayTarget']:SetScale(UIParent:GetScale())
    end

    if TWT.healerMasterTarget ~= '' then
        return true
    end

    TWT.targetName = ''
    TWT.updateTargetFrameThreatIndicators(-1)

    -- lost target
    if not UnitExists('target') then
        return false
    end

    -- target is dead, dont show anything
    if UnitIsDead('target') then
        return false
    end

    -- dont show anything
    if UnitIsPlayer('target') then
        return false
    end

    -- -- non interesting target
    -- if UnitClassification('target') ~= 'worldboss' and UnitClassification('target') ~= 'elite' then
    --     return false
    -- end

    -- no raid or party
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    -- not in combat
    if not UnitAffectingCombat('target') then
        return false
    end

    twtdebug('wipe target changed')
    TWT.threats = TWT.wipe(TWT.threats)
    TWT.history = TWT.wipe(TWT.history)

    -- if TWT_CONFIG.skeram then
        -- skeram hax
        --The Prophet Skeram
        --_G['TWTWarning']:Hide()
        --if UnitAffectingCombat('player') then
        --    if UnitName('target') == 'The Prophet Skeram' and TWT.custom['The Prophet Skeram'] ~= 0 then

        --            _G['TWTWarningText']:SetText("|cff00ff00- REAL -");
        --            _G['TWTWarning']:Show()
        --        else
        --            _G['TWTWarningText']:SetText("- CLONE -");
        --            _G['TWTWarning']:Show()
        --        end
        --    end
        --end
    -- end

    TWT.targetName = TWT.unitNameForTitle(UnitName('target'))
    
 
    TWT.updateTitleBarText(TWT.targetName)

    return true
end

function TWT.send(msg)
    -- 发送消息前更新目标GUID
    TWT.updateTargetGUID()
    
    -- 检查是否在团队或队伍中
    local inRaid = GetNumRaidMembers() > 0
    local inParty = GetNumPartyMembers() > 0
    
    -- 只有在团队或队伍中才发送消息
    if inRaid or inParty then
        -- 设置正确的频道
        TWT.channel = inRaid and 'RAID' or 'PARTY'
        
        -- 添加发送频率限制，避免发送过于频繁
        local currentTime = GetTime()
        if not TWT.lastSendMessageTime or (currentTime - TWT.lastSendMessageTime >= 0.2) then
            SendAddonMessage(TWT.prefix, msg, TWT.channel)
            TWT.lastSendMessageTime = currentTime
        end
    end
end

function TWT.UnitDetailedThreatSituation(limit)
    TWT.updateTargetGUID()
    
    -- 如果没有传入limit，使用配置中的dataLimit
    if not limit then
        limit = TWT_CONFIG.dataLimit or 6
    end
    limit = math.max(1, math.min(12, limit))
    
    -- Debug: Function called
    if TWT_CONFIG.debug then
        twtdebug('UnitDetailedThreatSituation called with limit: ' .. tostring(limit))
    end

    -- 检查是否在团队或队伍中
    local inRaid = GetNumRaidMembers() > 0
    local inParty = GetNumPartyMembers() > 0
    
    if TWT_CONFIG.debug then
        twtdebug('Group check: inRaid=' .. tostring(inRaid) .. ', inParty=' .. tostring(inParty))
    end
    
    -- 只有在团队或队伍中才发送消息
    if inRaid or inParty then
        -- 设置正确的频道
        TWT.channel = inRaid and 'RAID' or 'PARTY'
        
        local prefix2 = TWT.UDTS
        local prefix = TWT.UDTS .. '_TM'
     
        -- 添加发送频率限制，避免发送过于频繁
        local currentTime = GetTime()
        if TWT_CONFIG.debug then
            local lastTimeStr = TWT.lastLimitMessageTime and tostring(TWT.lastLimitMessageTime) or 'nil'
            twtdebug('Send check: currentTime=' .. tostring(currentTime) .. ', lastLimitMessageTime=' .. lastTimeStr .. ', diff=' .. tostring(currentTime - (TWT.lastLimitMessageTime or 0)))
        end
        
        if not TWT.lastLimitMessageTime or (currentTime - TWT.lastLimitMessageTime >= 0.5) then
            if TWT_CONFIG.debug then
                twtdebug('Sending threat query: prefix=' .. prefix .. ', prefix2=' .. prefix2 .. ', limit=' .. tostring(limit) .. ', channel=' .. TWT.channel)
            end
 
            SendAddonMessage(prefix, "limit=" .. limit, TWT.channel)
            SendAddonMessage(prefix2, "limit=" .. limit, TWT.channel)
            TWT.lastLimitMessageTime = currentTime
        else
            if TWT_CONFIG.debug then
                twtdebug('Throttled: sending too frequently')
            end
        end
    else
        if TWT_CONFIG.debug then
            twtdebug('Not sending: not in raid or party')
        end
    end
    
    -- 死亡消息发送逻辑保持不变
    if TWT.isGroupLeaderOrAssistant and (inRaid or inParty) then
       if UnitIsDead('player') == 1 then
           local currentTime = GetTime()
           -- 每2秒发送一条消息
           if currentTime - TWT.lastDeathMessageTime >= 2 then
               -- 发送死亡消息
               local SW = 'DEAD_MSG'
               SendAddonMessage(TWT.prefix, SW, TWT.channel)
               TWT.lastDeathMessageTime = currentTime
           end
       end
    end
end
function TWT.updateUI(from)

    --twtdebug('update ui call from [' .. (from or '') .. ']')

    TWT.checkTargetFrames()

    if TWT_CONFIG.debug then
        _G['pps']:SetText('Traffic: ' .. TWT.round((totalPackets / (GetTime() - timeStart)) * 10) / 10
                .. 'packets/s (' .. TWT.round(totalData / (GetTime() - timeStart)) .. ' cps)'
                .. TWT.round(uiUpdates / (GetTime() - timeStart)) .. ' ups ')
        _G['pps']:Show()
    else
        _G['pps']:Hide()
    end

    uiUpdates = uiUpdates + 1

    if not TWT.barAnimator:IsVisible() then
        TWT.barAnimator:Show()
    end

    TWT.hideThreatFrames()

    -- 选项切换时强制更新UI
    local isOptionChange = from and (from == 'option_change' or from == 'limit_change' or from == 'tankMode_change')
    
    -- 优化条件判断，确保设置选项变化时能更新UI
    if TWT.inCombat ~= true and not _G['TWTMainSettings']:IsVisible() and not isOptionChange then
        TWT.updateTargetFrameThreatIndicators(-1)
        return false
    end

    if TWT.targetName == '' and not (_G['TWTMainSettings']:IsVisible() or isOptionChange) then
        return false
    end

    if _G['TWTMainSettings']:IsVisible() and not UnitAffectingCombat('player') then
        TWT.tankName = 'Tenk'
    end

    local index = 0
    local playerIndex = 0  -- 只计算玩家信息的索引

    for name, data in TWT.ohShitHereWeSortAgain(TWT.threats, true) do

        -- 使用配置中的dataLimit作为显示限制（只限制玩家信息，不限制Pull Aggro行）
        local visibleLimit = TWT.limit > 0 and TWT.limit or TWT_CONFIG.dataLimit
        -- Pull Aggro行总是显示，不计入限制
        local isAgroRow = (name == TWT.AGRO)
        if data and TWT.threats[TWT.name] and (isAgroRow or playerIndex < visibleLimit) then

            index = index + 1
            -- 只对非Pull Aggro行计数
            if not isAgroRow then
                playerIndex = playerIndex + 1
            end
            if not TWT.threatsFrames[index] then
                TWT.threatsFrames[index] = CreateFrame('Frame', 'TWThreat' .. index, _G["TWTMain"], 'TWThreat')
            end

            _G['TWThreat' .. index]:SetAlpha(TWT_CONFIG.combatAlpha)
            _G['TWThreat' .. index]:SetWidth(TWT.windowWidth - 2)

            _G['TWThreat' .. index .. 'Name']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", TWT_CONFIG.fontSize, "OUTLINE")
            _G['TWThreat' .. index .. 'TPS']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", TWT_CONFIG.fontSize, "OUTLINE")
            _G['TWThreat' .. index .. 'Threat']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", TWT_CONFIG.fontSize, "OUTLINE")
            _G['TWThreat' .. index .. 'Perc']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", TWT_CONFIG.fontSize, "OUTLINE")

            _G['TWThreat' .. index]:SetHeight(TWT_CONFIG.barHeight - 1)
            _G['TWThreat' .. index .. 'BG']:SetHeight(TWT_CONFIG.barHeight - 2)

            TWT.threatsFrames[index]:ClearAllPoints()
            -- 计算正确的Y偏移量，考虑动态标题栏高度和标签行
            local yOffset = -TWT_CONFIG.titleHeight
            if TWT_CONFIG.labelRow then
                -- 标签行高度为标题高度的80% + 4px偏移
                local labelRowHeight = math.floor(TWT_CONFIG.titleHeight * 0.8) + 8
                yOffset = yOffset - labelRowHeight
            end
            
            TWT.threatsFrames[index]:SetPoint("TOPLEFT", _G["TWTMain"], "TOPLEFT", 0,
                    yOffset + TWT_CONFIG.barHeight - 1 - index * TWT_CONFIG.barHeight)


            -- icons
            _G['TWThreat' .. index .. 'AGRO']:Hide()
            _G['TWThreat' .. index .. 'Role']:Show()
            if name ~= TWT.AGRO then

                _G['TWThreat' .. index .. 'Role']:SetWidth(TWT_CONFIG.barHeight - 2)
                _G['TWThreat' .. index .. 'Role']:SetHeight(TWT_CONFIG.barHeight - 2)
                _G['TWThreat' .. index .. 'Name']:SetPoint('LEFT', _G['TWThreat' .. index .. 'Role'], 'RIGHT', 1 + (TWT_CONFIG.barHeight / 15), -1)
                if TWT.roles[name] then
                    _G['TWThreat' .. index .. 'Role']:SetTexture('Interface\\Icons\\' .. TWT.roles[name])
                    _G['TWThreat' .. index .. 'Role']:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    _G['TWThreat' .. index .. 'Role']:Show()
                else
                    _G['TWThreat' .. index .. 'Role']:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes')
                    local coords = TWT.classCoords[data.class] or {0, 1, 0, 1}
                    _G['TWThreat' .. index .. 'Role']:SetTexCoord(unpack(coords))
                end

            else
                _G['TWThreat' .. index .. 'AGRO']:Show()
                _G['TWThreat' .. index .. 'Role']:Hide()
            end


            -- tps
            _G['TWThreat' .. index .. 'TPS']:SetText(data.tps)

            -- labels
            TWT.setBarLabels(_G['TWThreat' .. index .. 'Perc'], _G['TWThreat' .. index .. 'Threat'], _G['TWThreat' .. index .. 'TPS'])

            -- perc
            _G['TWThreat' .. index .. 'Perc']:SetText(TWT.round(data.perc) .. '%')

            if TWT.name ~= TWT.tankName and name == TWT.AGRO then
                _G['TWThreat' .. index .. 'Perc']:SetText(100 - TWT.round(TWT.threats[TWT.name].perc) .. '%')
            end

            -- name
            _G['TWThreat' .. index .. 'Name']:SetText(TWT.classColors['other'].c .. name)

            -- bar width and color
            local color = TWT.classColors[data.class]

            if name == TWT.name then

                if UnitName('target') ~= '预言者斯克拉姆' then
                    if name == __char(77) .. __lower(__char(79, 77, 79)) and data.perc >= 95 then
                        _G['TWTWarningText']:SetText("- STOP DPS " .. __char(77) .. __lower(__char(79, 77, 79)) .. " -");
                        _G['TWTWarning']:Show()
                    else
                        _G['TWTWarning']:Hide()
                    end
                end

                if TWT_CONFIG.aggroSound and data.perc >= TWT_CONFIG.aggroThreshold and time() - TWT.lastAggroWarningSoundTime > 5
                        and not TWT_CONFIG.fullScreenGlow then
                    PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
                    TWT.lastAggroWarningSoundTime = time()
                end

                if TWT_CONFIG.fullScreenGlow and data.perc >= TWT_CONFIG.aggroThreshold and time() - TWT.lastAggroWarningGlowTime > 5 then
                    TWT.glowFader:Show()
                    TWT.lastAggroWarningGlowTime = time()
                    if TWT_CONFIG.aggroSound then
                        PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
                    end
                end

                TWT.updateTitleBarText(TWT.targetName .. ' (' .. TWT.round(data.perc) .. '%)')

                _G['TWThreat' .. index .. 'Threat']:SetText(TWT.formatNumber(data.threat))

                if data.perc == 0 then TWT.barAnimator:animateTo(index, empty) else TWT.barAnimator:animateTo(index, data.perc) end

            elseif name == TWT.AGRO then

                TWT.barAnimator:animateTo(index, nil)

                _G['TWThreat' .. index .. 'BG']:SetWidth(TWT.windowWidth - 2)
                _G['TWThreat' .. index .. 'Threat']:SetText('+' .. TWT.formatNumber(data.threat - TWT.threats[TWT.name].threat))

                local colorLimit = 50

                if TWT.threats[TWT.name].perc >= 0 and TWT.threats[TWT.name].perc < colorLimit then
                    _G['TWThreat' .. index .. 'BG']:SetVertexColor(TWT.threats[TWT.name].perc / colorLimit, 1, 0, 0.9)
                elseif TWT.threats[TWT.name].perc >= colorLimit then
                    _G['TWThreat' .. index .. 'BG']:SetVertexColor(1, 1 - (TWT.threats[TWT.name].perc - colorLimit) / colorLimit, 0, 0.9)
                end

                if TWT.tankName == TWT.name then
                    _G['TWThreat' .. index .. 'BG']:SetVertexColor(1, 0, 0, 1)
                    _G['TWThreat' .. index .. 'Perc']:SetText('')
                end

            else

                TWT.barAnimator:animateTo(index, data.perc)

                _G['TWThreat' .. index .. 'Threat']:SetText(TWT.formatNumber(data.threat))
                _G['TWThreat' .. index .. 'BG']:SetVertexColor(color.r, color.g, color.b, 0.9)
            end

            if data.tank then

                TWT.barAnimator:animateTo(index, 100, true)

            end

            if name == TWT.name then
                _G['TWThreat' .. index .. 'BG']:SetVertexColor(1, 0.2, 0.2, 1)
                TWT.updateTargetFrameThreatIndicators(data.perc)
            end

            TWT.threatsFrames[index]:Show()

        end

    end

    -- 隐藏超出显示范围的威胁条（使用index来隐藏）
    for i = index + 1, __getn(TWT.threatsFrames) do
        if TWT.threatsFrames[i] then
            TWT.threatsFrames[i]:Hide()
        end
    end

    if TWT_CONFIG.tankMode then

        _G['TMEF1']:Hide()
        _G['TMEF2']:Hide()
        _G['TMEF3']:Hide()
        _G['TMEF4']:Hide()
        _G['TMEF5']:Hide()

        _G['TWTMainTankModeWindow']:SetHeight(0)

        if TWT.tableSize(TWT.tankModeThreats) > 1 then
            local i = 0
            for guid, data in next, TWT.tankModeThreats do

                i = i + 1
                if i > 5 then
                    break
                end
                _G['TWTMainTankModeWindow']:SetHeight(i * 25 + 23)

                _G['TMEF' .. i .. 'Target']:SetText(data.creature)
                _G['TMEF' .. i .. 'Player']:SetText(TWT.classColors[TWT.getClass(data.name)].c .. data.name)
                _G['TMEF' .. i .. 'Perc']:SetText(TWT.round(data.perc) .. '%')
                _G['TMEF' .. i .. 'TargetButton']:SetID(guid)
                _G['TMEF' .. i]:SetPoint("TOPLEFT", _G["TWTMainTankModeWindow"], "TOPLEFT", 0, -21 + 24 - i * 25)

                -- 显示或隐藏标记图标
                if data.raidTargetIndex and data.raidTargetIndex > 0 then
                    _G['TMEF' .. i .. 'RaidTargetIcon']:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
                    local offset = (data.raidTargetIndex - 1) * 0.25
                    local yOffset = 0
                    if data.raidTargetIndex > 4 then
                        offset = offset - 1 -- 重置X偏移
                        yOffset = 0.25 -- 使用下半部分纹理
                    end
                    _G['TMEF' .. i .. 'RaidTargetIcon']:SetTexCoord(offset, offset + 0.25, yOffset, yOffset + 0.25)
                    _G['TMEF' .. i .. 'RaidTargetIcon']:Show()
                else
                    _G['TMEF' .. i .. 'RaidTargetIcon']:Hide()
                end

                if data.perc >= 0 and data.perc < 50 then
                    _G['TMEF' .. i .. 'BG']:SetVertexColor(data.perc / 50, 1, 0, 0.5)
                else
                    _G['TMEF' .. i .. 'BG']:SetVertexColor(1, 1 - (data.perc - 50) / 50, 0, 0.5)
                end

                _G['TMEF' .. i]:Show()

                _G['TWTMainTankModeWindow']:Show()

            end

        else
            _G['TWTMainTankModeWindow']:Hide()
        end
    else
        _G['TWTMainTankModeWindow']:Hide()
    end

end

TWT.barAnimator = CreateFrame('Frame')
TWT.barAnimator:Hide()
TWT.barAnimator.frames = {}

function TWT.barAnimator:animateTo(index, perc, instant)

    if perc == nil then
        TWT.barAnimator.frames['TWThreat' .. index .. 'BG'] = perc
        return false
    end

    if perc == empty then
        _G['TWThreat' .. index .. 'BG']:SetWidth(2)
        return true
    end
    
    perc = TWT.round(perc)
    perc = perc > 100 and 100 or perc

    local width = TWT.round((TWT.windowWidth - 2) * perc / 100)
    if instant then
        _G['TWThreat' .. index .. 'BG']:SetWidth(width)
        return true
    end
    TWT.barAnimator.frames['TWThreat' .. index .. 'BG'] = width
end

TWT.barAnimator:SetScript("OnShow", function()
    this.startTime = GetTime()
    TWT.barAnimator.frames = {}
end)
TWT.barAnimator:SetScript("OnUpdate", function()
    local currentW, step, diff
    for frame, w in TWT.barAnimator.frames do
        currentW = TWT.round(_G[frame]:GetWidth())

        diff = currentW - w

        if diff ~= 0 then

            step = 12
            --if __abs(diff) > 50 then
            --    step = 9
            --elseif __abs(diff) > 100 then
            --    step = 12
            --elseif __abs(diff) > 200 then
            --    step = 15
            --end

            -- grow
            if diff < 0 then
                if __abs(diff) < step then
                    step = __abs(diff)
                end
                _G[frame]:SetWidth(currentW + step)
            else
                if diff < step then
                    step = diff
                end
                _G[frame]:SetWidth(currentW - step)
            end
        end
    end
end)

TWT.threatQuery:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWT.threatQuery:SetScript("OnHide", function()
end)
TWT.threatQuery:SetScript("OnUpdate", function()
    
    if not this.startTime then this.startTime = GetTime() end
    local plus = TWT.updateSpeed
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        -- Debug: OnUpdate triggered
        if TWT_CONFIG.debug then
            twtdebug('threatQuery OnUpdate triggered')
        end
        
        local inRaid = GetNumRaidMembers() > 0
        local inParty = GetNumPartyMembers() > 0
        if not inRaid and not inParty then
            if TWT_CONFIG.debug then
                twtdebug('No raid or party, skipping')
            end
            return false
        end
        
        if UnitAffectingCombat('target') then
            if TWT_CONFIG.debug then
                twtdebug('Target is in combat')
            end
            TWT.combatStart()
            if TWT.targetName == '' then
                twtdebug('threatQuery target = blank ')
                -- try to re-get target
                TWT.targetChanged()
                return false
            end
            
            if TWT_CONFIG.debug then
                twtdebug('Target name: ' .. TWT.targetName)
                twtdebug('Config check: glow=' .. tostring(TWT_CONFIG.glow) .. ', perc=' .. tostring(TWT_CONFIG.perc) .. ', glowPFUI=' .. tostring(TWT_CONFIG.glowPFUI) .. ', percPFUI=' .. tostring(TWT_CONFIG.percPFUI) .. ', fullScreenGlow=' .. tostring(TWT_CONFIG.fullScreenGlow) .. ', tankMode=' .. tostring(TWT_CONFIG.tankMode) .. ', visible=' .. tostring(TWT_CONFIG.visible))
            end

            if TWT_CONFIG.glow or TWT_CONFIG.perc or
                    TWT_CONFIG.glowPFUI or TWT_CONFIG.percPFUI or
                    TWT_CONFIG.fullScreenGlow or TWT_CONFIG.tankMode or
                    TWT_CONFIG.visible then
                if TWT.healerMasterTarget == '' then
                    if TWT_CONFIG.debug then
                        twtdebug('Calling UnitDetailedThreatSituation')
                    end
                    -- 使用滑块的值作为limit，确保在有效范围内
                    local safeLimit = math.max(1, math.min(12, TWT_CONFIG.dataLimit))
                    
                    TWT.UnitDetailedThreatSituation(safeLimit)
                else
                    if TWT_CONFIG.debug then
                        twtdebug('Skipping because healerMasterTarget is set: ' .. TWT.healerMasterTarget)
                    end
                end
            else
                twtdebug('not asking threat situation - no relevant config enabled')
            end
        else
            if TWT_CONFIG.debug then
                twtdebug('Target not in combat, skipping')
            end
        end
    end
end)

function TWT.calcTPS(name)

    local data = TWT.history[name]

    if not data then
        return 0
    end

    local older = time()
    for t in next, data do
        if t < older then
            older = t
        end
    end

    if TWT.tableSize(data) > 10 then
        TWT.history[name][older] = nil
    end

    local tps = 0
    local mean = 0

    local time = time()

    for i = 0, TWT.tableSize(data) - 1 do
        if TWT.history[name][time - i] and TWT.history[name][time - i - 1] then
            tps = tps + TWT.history[name][time - i] - TWT.history[name][time - i - 1]
            mean = mean + 1
        end
    end

    if mean > 0 and tps > 0 then
        return TWT.round(tps / mean)
    end

    return 0

end

function TWT.updateTargetFrameThreatIndicators(perc)

    if TWT_CONFIG.fullScreenGlow then
        _G['TWTFullScreenGlow']:Show()
    else
        _G['TWTFullScreenGlow']:Hide()
    end

    if perc == -1 then
        TWT.updateTitleBarText()
        _G['TWThreatDisplayTarget']:Hide()
        _G['TWThreatDisplayTargetPFUI']:Hide()

        --TWT.hideThreatFrames()

        return false
    end

    if not TWT_CONFIG.glow and not TWT_CONFIG.perc and not TWT.targetFrameVisible then
        _G['TWThreatDisplayTarget']:Hide()
    end

    if not TWT_CONFIG.glowPFUI and not TWT_CONFIG.percPFUI and not TWT.PFUItargetFrameVisible then
        _G['TWThreatDisplayTargetPFUI']:Hide()
    end

    if not TWT.targetFrameVisible and not TWT.PFUItargetFrameVisible then
        return false
    end

    if TWT.targetFrameVisible then
        _G['TWThreatDisplayTarget']:Show()
    end
    if TWT.PFUItargetFrameVisible then
        _G['TWThreatDisplayTargetPFUI']:Show()
    end

    perc = TWT.round(perc)

    if TWT_CONFIG.glow then

        local unitClassification = UnitClassification('target')
        if unitClassification == 'worldboss' then
            unitClassification = 'elite'
        end

        _G['TWThreatDisplayTargetGlow']:SetTexture('Interface\\addons\\TWThreat\\images\\' .. unitClassification)

        if perc >= 0 and perc < 50 then
            _G['TWThreatDisplayTargetGlow']:SetVertexColor(perc / 50, 1, 0, perc / 50)
        elseif perc >= 50 then
            _G['TWThreatDisplayTargetGlow']:SetVertexColor(1, 1 - (perc - 50) / 50, 0, 1)
        end

        _G['TWThreatDisplayTargetGlow']:Show()
    else
        _G['TWThreatDisplayTargetGlow']:Hide()
    end

    if TWT_CONFIG.glowPFUI and _G['pfTarget'] then

        if perc >= 0 and perc < 50 then
            _G['TWThreatDisplayTargetPFUIGlow']:SetVertexColor(perc / 50, 1, 0, perc / 50)
        elseif perc >= 50 then
            _G['TWThreatDisplayTargetPFUIGlow']:SetVertexColor(1, 1 - (perc - 50) / 50, 0, 1)
        end

        _G['TWThreatDisplayTargetPFUIGlow']:Show()
    else
        _G['TWThreatDisplayTargetPFUIGlow']:Hide()
    end

    if TWT_CONFIG.perc then

        if TWT_CONFIG.tankMode then
            _G['TWThreatDisplayTargetNumericBG']:SetPoint('TOPLEFT', 24, -7)
            _G['TWThreatDisplayTargetNumericBG']:SetWidth(79)
            _G['TWThreatDisplayTargetNumericBorder']:SetPoint('TOPLEFT', 20, -3)
            _G['TWThreatDisplayTargetNumericBorder']:SetWidth(128)
            _G['TWThreatDisplayTargetNumericBorder']:SetTexture('Interface\\addons\\TWThreat\\images\\numericthreatborder_wide')
            _G['TWThreatDisplayTargetNumericPerc']:SetPoint('TOPLEFT', -1, 3)
            _G['TWThreatDisplayTargetNumericPerc']:SetWidth(128)
        else
            _G['TWThreatDisplayTargetNumericBG']:SetPoint('TOPLEFT', 44, -7)
            _G['TWThreatDisplayTargetNumericBG']:SetWidth(36)
            _G['TWThreatDisplayTargetNumericBorder']:SetPoint('TOPLEFT', 38, -3)
            _G['TWThreatDisplayTargetNumericBorder']:SetWidth(64)
            _G['TWThreatDisplayTargetNumericBorder']:SetTexture('Interface\\addons\\TWThreat\\images\\numericthreatborder')
            _G['TWThreatDisplayTargetNumericPerc']:SetPoint('TOPLEFT', 31, 3)
            _G['TWThreatDisplayTargetNumericPerc']:SetWidth(64)
        end

        local tankModePerc = 0

        if TWT_CONFIG.tankMode then
            local second = ''
            local index = 0
            for name, data in TWT.ohShitHereWeSortAgain(TWT.threats, true) do
                index = index + 1
                if index == 3 then
                    tankModePerc = TWT.round(data.perc)
                    local unitId = TWT.targetFromName(name)
            second = TWT.unitNameForTitle(name, 6, unitId) .. ' ' .. tankModePerc .. '%'
                    break
                    --TWT.classColors[TWT.getClass(name)].c ..
                end
            end
            if second ~= '' then
                _G['TWThreatDisplayTargetNumericPerc']:SetText(second)
            else
                _G['TWThreatDisplayTargetNumericPerc']:SetText(perc .. '%')
            end
        else
            _G['TWThreatDisplayTargetNumericPerc']:SetText(perc .. '%')
        end

        if tankModePerc ~= 0 then
            perc = tankModePerc
        end

        if perc >= 0 and perc < 50 then
            _G['TWThreatDisplayTargetNumericBG']:SetVertexColor(perc / 50, 1, 0, 1)
        elseif perc >= 50 then
            _G['TWThreatDisplayTargetNumericBG']:SetVertexColor(1, 1 - (perc - 50) / 50, 0)
        end

        _G['TWThreatDisplayTargetNumericPerc']:Show()
        _G['TWThreatDisplayTargetNumericBG']:Show()
        _G['TWThreatDisplayTargetNumericBorder']:Show()
    else
        _G['TWThreatDisplayTargetNumericPerc']:Hide()
        _G['TWThreatDisplayTargetNumericBG']:Hide()
        _G['TWThreatDisplayTargetNumericBorder']:Hide()
    end

    if TWT_CONFIG.percPFUI and _G['pfTarget'] then

        local offset = 0
        if TWT_CONFIG.percPFUIbottom then
            offset = -_G['pfTarget']:GetHeight() - 32 / 2
        end

        if TWT_CONFIG.tankMode then
            _G['TWThreatDisplayTargetPFUINumericBG']:SetPoint('TOPLEFT', 0 + TWT_CONFIG.percPFUIoffsetX, 18 + offset + TWT_CONFIG.percPFUIoffsetY)
            _G['TWThreatDisplayTargetPFUINumericBG']:SetWidth(76)
            _G['TWThreatDisplayTargetPFUINumericBorder']:SetPoint('TOPLEFT', -6 + TWT_CONFIG.percPFUIoffsetX, 19 + offset + TWT_CONFIG.percPFUIoffsetY)
            _G['TWThreatDisplayTargetPFUINumericBorder']:SetTexture('Interface\\addons\\TWThreat\\images\\numericthreatborder_pfui_wide')
            _G['TWThreatDisplayTargetPFUINumericPerc']:SetPoint('TOPLEFT', -26 + TWT_CONFIG.percPFUIoffsetX, 25 + offset + TWT_CONFIG.percPFUIoffsetY)
            _G['TWThreatDisplayTargetPFUINumericPerc']:SetWidth(128)
        else
            _G['TWThreatDisplayTargetPFUINumericBG']:SetPoint('TOPLEFT', 134 + TWT_CONFIG.percPFUIoffsetX, 24 + offset + TWT_CONFIG.percPFUIoffsetY)
            _G['TWThreatDisplayTargetPFUINumericBG']:SetWidth(37)
            _G['TWThreatDisplayTargetPFUINumericBorder']:SetPoint('TOPLEFT', 128 + TWT_CONFIG.percPFUIoffsetX, 25 + offset + TWT_CONFIG.percPFUIoffsetY)
            _G['TWThreatDisplayTargetPFUINumericBorder']:SetTexture('Interface\\addons\\TWThreat\\images\\numericthreatborder_pfui')
            _G['TWThreatDisplayTargetPFUINumericPerc']:SetPoint('TOPLEFT', 128 + TWT_CONFIG.percPFUIoffsetX, 31 + offset + TWT_CONFIG.percPFUIoffsetY)
            _G['TWThreatDisplayTargetPFUINumericPerc']:SetWidth(64)
        end

        local tankModePerc = 0

        if TWT_CONFIG.tankMode then
            local second = ''
            local index = 0
            for name, data in TWT.ohShitHereWeSortAgain(TWT.threats, true) do
                index = index + 1
                if index == 3 then
                    tankModePerc = TWT.round(data.perc)
                    local unitId = TWT.targetFromName(name)
            second = TWT.unitNameForTitle(name, 6, unitId) .. ' ' .. tankModePerc .. '%'
                    break
                end
            end
            if second ~= '' then
                _G['TWThreatDisplayTargetPFUINumericPerc']:SetText(second)
            else
                _G['TWThreatDisplayTargetPFUINumericPerc']:SetText(perc .. '%')
            end
        else
            _G['TWThreatDisplayTargetPFUINumericPerc']:SetText(perc .. '%')
        end

        if tankModePerc ~= 0 then
            perc = tankModePerc
        end

        if perc >= 0 and perc < 50 then
            _G['TWThreatDisplayTargetPFUINumericBG']:SetVertexColor(perc / 50, 1, 0, 1)
        elseif perc >= 50 then
            _G['TWThreatDisplayTargetPFUINumericBG']:SetVertexColor(1, 1 - (perc - 50) / 50, 0)
        end

        _G['TWThreatDisplayTargetPFUINumericPerc']:Show()
        _G['TWThreatDisplayTargetPFUINumericBG']:Show()
        _G['TWThreatDisplayTargetPFUINumericBorder']:Show()
    else
        _G['TWThreatDisplayTargetPFUINumericPerc']:Hide()
        _G['TWThreatDisplayTargetPFUINumericBG']:Hide()
        _G['TWThreatDisplayTargetPFUINumericBorder']:Hide()
    end

end

function TWTMainWindow_Resizing()
    _G['TWTMain']:SetAlpha(0.4)
end

function TWTMainMainWindow_Resized()
    _G['TWTMain']:SetAlpha(UnitAffectingCombat('player') and TWT_CONFIG.combatAlpha or TWT_CONFIG.oocAlpha)

    TWT.setMinMaxResize()
    TWT.updateUI('TWTMainMainWindow_Resized')
end

function FrameHeightSlider_OnValueChanged()
    TWT_CONFIG.barHeight = _G['TWTMainSettingsFrameHeightSlider']:GetValue()
    TWT.setMinMaxResize()
    TWT.updateUI('FrameHeightSlider_OnValueChanged')
end

function FontSizeSlider_OnValueChanged()
    TWT_CONFIG.fontSize = _G['TWTMainSettingsFontSizeSlider']:GetValue()
    TWT.updateUI('FontSizeSlider_OnValueChanged')
end

function WindowScaleSlider_OnValueChanged()
    TWT_CONFIG.windowScale = _G['TWTMainSettingsWindowScaleSlider']:GetValue()

    local x, y = _G['TWTMain']:GetLeft(), _G['TWTMain']:GetTop()
    local sx, sy = _G['TWTMainTankModeWindow']:GetLeft(), _G['TWTMainTankModeWindow']:GetTop()
    local s = _G['TWTMain']:GetEffectiveScale()
    local ss = _G['TWTMainTankModeWindow']:GetEffectiveScale()
    local posX, posY = 0, 0
    local sposX, sposY = 0, 0

    if x and y and s then
        x, y = x * s, y * s
        posX = x
        posY = y
    end
    if sx and sy and ss then
        sx, sy = sx * ss, sy * ss
        sposX = sx
        sposY = sy
    end

    _G['TWTMain']:SetScale(TWT_CONFIG.windowScale)
    _G['TWTMainTankModeWindow']:SetScale(TWT_CONFIG.windowScale)

    s = _G['TWTMain']:GetEffectiveScale()
    ss = _G['TWTMainTankModeWindow']:GetEffectiveScale()
    posX, posY = posX / s, posY / s
    sposX, sposY = sposX / ss, sposY / ss
    _G['TWTMain']:ClearAllPoints()
    _G['TWTMainTankModeWindow']:ClearAllPoints()
    _G['TWTMain']:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", posX, posY)
    _G['TWTMainTankModeWindow']:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", sposX, sposY)

    if TWT_CONFIG.tankModeStick ~= 'Free' then
        TWTTankModeWindowChangeStick_OnClick(TWT_CONFIG.tankModeStick)
    end
end

function CombatOpacitySlider_OnValueChanged()
    TWT_CONFIG.combatAlpha = _G['TWTMainSettingsCombatAlphaSlider']:GetValue()
    _G['TWTMain']:SetAlpha(UnitAffectingCombat('player') and TWT_CONFIG.combatAlpha or TWT_CONFIG.oocAlpha)
end

function OOCombatSlider_OnValueChanged()
    TWT_CONFIG.oocAlpha = _G['TWTMainSettingsOOCAlphaSlider']:GetValue()
    _G['TWTMain']:SetAlpha(UnitAffectingCombat('player') and TWT_CONFIG.combatAlpha or TWT_CONFIG.oocAlpha)
end

function AggroThresholdSlider_OnValueChanged()
    TWT_CONFIG.aggroThreshold = _G['TWTMainSettingsAggroThresholdSlider']:GetValue()
end

function DataLimitSlider_OnValueChanged()
    -- 获取滑块值并修正偏移，使显示1对应实际1行
    local sliderValue = _G['TWTMainSettingsDataLimitSlider']:GetValue()
    TWT_CONFIG.dataLimit = sliderValue
    -- 更新显示文本
    if _G['TWTMainSettingsDataLimitSliderValueText'] then
        _G['TWTMainSettingsDataLimitSliderValueText']:SetText(tostring(sliderValue))
    end
    -- 只更新数据行数，不调整窗口高度
    TWT.updateUI('DataLimitSlider_OnValueChanged')
end

function TWT.updateLabelRowVisibility()
    if TWT_CONFIG.labelRow then
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -TWT_CONFIG.titleHeight - 4)
        _G['TWTMainNameLabel']:Show()
        _G['TWTMainTPSLabel']:Show()
        _G['TWTMainThreatLabel']:Show()
        _G['TWTMainPercLabel']:Show()
    else
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -TWT_CONFIG.titleHeight)
        _G['TWTMainNameLabel']:Hide()
        _G['TWTMainTPSLabel']:Hide()
        _G['TWTMainThreatLabel']:Hide()
        _G['TWTMainPercLabel']:Hide()
    end
end

function TWTChangeSetting_OnClick(checked, code)
    if code == 'lock' then
        checked = not TWT_CONFIG[code]
        if checked then
            _G['TWTMainLockButton']:SetNormalTexture('Interface\\addons\\TWThreat\\images\\icon_locked')
        else
            _G['TWTMainLockButton']:SetNormalTexture('Interface\\addons\\TWThreat\\images\\icon_unlocked')
        end
    end
    TWT_CONFIG[code] = checked
    
    -- 处理自定义标题栏颜色设置变化
    if code == 'useCustomTitleColor' then
        TWTUpdateTitleBarColor()
    end
    
    if code == 'tankMode' then
        if checked then
            TWT.testBars(true)
            TWT_CONFIG.fullScreenGlow = false
            TWT_CONFIG.aggroSound = false
            _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)
            _G['TWTMainSettingsFullScreenGlow']:Disable()
            _G['TWTMainSettingsAggroSound']:SetChecked(TWT_CONFIG.fullScreenGlow)
            _G['TWTMainSettingsAggroSound']:Disable()

            _G['TWTMainTankModeWindowStickTopButton']:Show()
            _G['TWTMainTankModeWindowStickRightButton']:Show()
            _G['TWTMainTankModeWindowStickBottomButton']:Show()
            _G['TWTMainTankModeWindowStickLeftButton']:Show()

            _G['TWTMainTankModeWindow']:Show()
        else
            _G['TWTMainSettingsFullScreenGlow']:Enable()
            _G['TWTMainSettingsAggroSound']:Enable()
            _G['TWTMainTankModeWindow']:Hide()
        end
    end
    if code == 'aggroSound' and checked and not UnitAffectingCombat('player') then
        PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
    end

    if code == 'fullScreenGlow' and checked and not UnitAffectingCombat('player') then
        TWT.glowFader:Show()
    end

    if code == 'percPFUItop' then
        TWT_CONFIG.percPFUIbottom = false
        _G['TWTMainSettingsPercNumbersPFUIbottom']:SetChecked(TWT_CONFIG.percPFUIbottom)
    end
    if code == 'percPFUIbottom' then
        TWT_CONFIG.percPFUItop = false
        _G['TWTMainSettingsPercNumbersPFUItop']:SetChecked(TWT_CONFIG.percPFUItop)
    end

    if code == 'labelRow' then
        TWT.updateLabelRowVisibility()
        TWT.setMinMaxResize()
        -- 重新调整背景和标签位置
        TitleHeightSlider_OnValueChanged()
        -- 强制刷新UI
        TWT.updateUI('labelRow_change')
        return
    end

    TWT.setColumnLabels()

    -- 更新标题栏高度和标签位置
    TitleHeightSlider_OnValueChanged()

    -- 选项切换时强制刷新UI，添加明确的来源标识
    local updateSource = 'option_change'
    if code == 'tankMode' then
        updateSource = 'tankMode_change'
    end
    TWT.updateUI(updateSource)
end

function TWT.setColumnLabels()
    -- 如果标签行被禁用，则隐藏所有标签并返回
    if not TWT_CONFIG.labelRow then
        _G['TWTMainNameLabel']:Hide()
        _G['TWTMainTPSLabel']:Hide()
        _G['TWTMainThreatLabel']:Hide()
        _G['TWTMainPercLabel']:Hide()
        return
    end

    _G['TWTMain']:SetWidth(TWT.windowStartWidth - 70 - 70 - 70)

    TWT.nameLimit = 5
    
    -- 动态计算标签Y偏移量，永远在标题栏色块下方4px处
    local labelYOffset = -TWT_CONFIG.titleHeight - 4
    
    -- 计算标签字体大小，与姓名标签保持一致
    local titleFontSize = math.floor(TWT_CONFIG.titleHeight * 0.6)
    local labelFontSize = math.floor(titleFontSize * 0.8)
    
    -- 设置所有标签的字体大小，确保高度统一
    local fontPath = "Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf"
    -- 先设置所有标签的字体，确保字体大小一致
    local allLabels = {
        _G['TWTMainNameLabel'],
        _G['TWTMainTPSLabel'],
        _G['TWTMainThreatLabel'],
        _G['TWTMainPercLabel']
    }
    
    for _, label in ipairs(allLabels) do
        if label then
            label:SetFont(fontPath, labelFontSize, "OUTLINE")
        end
    end
    
    -- 计算每个显示列的总宽度偏移
    local columnWidth = 70
    local rightOffset = -10
    local totalColumns = 0
    
    -- 先计算总列数和总宽度
    if TWT_CONFIG.colPerc then totalColumns = totalColumns + 1 end
    if TWT_CONFIG.colThreat then totalColumns = totalColumns + 1 end
    if TWT_CONFIG.colTPS then totalColumns = totalColumns + 1 end
    
    -- 重置主窗口宽度
    _G['TWTMain']:SetWidth(TWT.windowStartWidth - columnWidth * totalColumns)
    
    -- 设置姓名标签
    if _G['TWTMainNameLabel'] then
        _G['TWTMainNameLabel']:ClearAllPoints()
        _G['TWTMainNameLabel']:SetPoint('TOPLEFT', 5, labelYOffset)
        _G['TWTMainNameLabel']:Show()
    end
    
    -- 设置右侧标签，从右到左
    -- 1. 最大值%标签（最右侧）
    if TWT_CONFIG.colPerc then
        _G['TWTMainPercLabel']:Show()
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + columnWidth)
        TWT.nameLimit = TWT.nameLimit + 8
        
        _G['TWTMainPercLabel']:ClearAllPoints()
        _G['TWTMainPercLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], rightOffset, labelYOffset)
        rightOffset = rightOffset - columnWidth
    else
        _G['TWTMainPercLabel']:Hide()
    end

    -- 2. 威胁值标签
    if TWT_CONFIG.colThreat then
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + columnWidth)
        TWT.nameLimit = TWT.nameLimit + 8

        _G['TWTMainThreatLabel']:ClearAllPoints()
        _G['TWTMainThreatLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], rightOffset, labelYOffset)
        rightOffset = rightOffset - columnWidth
        _G['TWTMainThreatLabel']:Show()
    else
        _G['TWTMainThreatLabel']:Hide()
    end

    -- 3. TPS标签（最左侧的右侧标签）
    if TWT_CONFIG.colTPS then
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + columnWidth)
        TWT.nameLimit = TWT.nameLimit + 8

        _G['TWTMainTPSLabel']:ClearAllPoints()
        _G['TWTMainTPSLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], rightOffset, labelYOffset)
        _G['TWTMainTPSLabel']:Show()
    else
        _G['TWTMainTPSLabel']:Hide()
    end

    if TWT.nameLimit < 14 then
        TWT.nameLimit = 14
    end

    if _G['TWTMain']:GetWidth() < 190 then
        _G['TWTMain']:SetWidth(190)
    end

    TWT.windowWidth = _G['TWTMain']:GetWidth()

    TWT.setMinMaxResize()
end

function TWT.setMinMaxResize()
    local titleHeight = TWT_CONFIG.titleHeight
    local labelRowHeight = TWT_CONFIG.labelRow and (math.floor(titleHeight * 0.8) + 8) or 0
    _G['TWTMain']:SetMinResize(TWT.windowWidth, TWT_CONFIG.barHeight * 1 + titleHeight + labelRowHeight)
    _G['TWTMain']:SetMaxResize(TWT.windowWidth, TWT_CONFIG.barHeight * 12 + titleHeight + labelRowHeight)
end

function TWT.setBarLabels(perc, threat, tps)

    if TWT_CONFIG.colPerc then
        perc:Show()
    else
        perc:Hide()
    end

    if TWT_CONFIG.colThreat then

        if TWT_CONFIG.colPerc then
            threat:SetPoint('RIGHT', -10 - 70 + 4, 0)
        else
            threat:SetPoint('RIGHT', -10 + 4, 0)
        end

        threat:Show()
    else
        threat:Hide()
    end

    if TWT_CONFIG.colTPS then

        if TWT_CONFIG.colThreat then
            if TWT_CONFIG.colPerc then
                tps:SetPoint('RIGHT', -10 - 70 - 70 + 4, 0)
            else
                tps:SetPoint('RIGHT', -10 - 70 + 4, 0)
            end
        elseif TWT_CONFIG.colPerc then
            tps:SetPoint('RIGHT', -10 - 70 + 4, 0)
        else
            tps:SetPoint('RIGHT', -10 + 4, 0)
        end

        tps:Show()
    else
        tps:Hide()
    end

end

function TWT.testBars(show)

    if UnitAffectingCombat('player') then
        return false
    end

    if show then
        TWT.roles['Tenk'] = 'ability_warrior_defensivestance'
        TWT.roles['Chad'] = 'spell_holy_auraoflight'
        TWT.roles[TWT.name] = 'ability_hunter_pet_turtle'
        TWT.roles['Olaf'] = 'ability_racial_bearform'
        TWT.roles['Jimmy'] = 'ability_backstab'
        TWT.roles['Miranda'] = 'spell_shadow_shadowwordpain'
        TWT.roles['Karen'] = 'spell_holy_powerinfusion'
        TWT.roles['Felix'] = 'spell_fire_sealoffire'
        TWT.roles['Tom'] = 'spell_shadow_shadowbolt'
        TWT.roles['Bill'] = 'ability_marksmanship'
        TWT.threats = {
            [TWT.AGRO] = {
                class = 'agro', threat = 1100, perc = 110, tps = '',
                history = {}, melee = true, tank = false
            },
            ['Tenk'] = {
                class = 'warrior', threat = 1000, perc = 100, tps = 100,
                history = {}, melee = true, tank = true },
            ['Chad'] = {
                class = 'paladin', threat = 990, perc = 99, tps = 99,
                history = {}, melee = true, tank = false },
            [TWT.name] = {
                class = TWT.class, threat = 750, perc = 75, tps = 75,
                history = {}, melee = false, tank = false
            },
            ['Olaf'] = {
                class = 'druid', threat = 700, perc = 70, tps = 70,
                history = {}, melee = true, tank = false
            },
            ['Jimmy'] = {
                class = 'rogue', threat = 500, perc = 50, tps = 50,
                history = {}, melee = true, tank = false
            },
            ['Miranda'] = {
                class = 'priest', threat = 450, perc = 45, tps = 45,
                history = {}, melee = false, tank = false
            },
            ['Karen'] = {
                class = 'priest', threat = 400, perc = 40, tps = 40,
                history = {}, melee = true, tank = false
            },
            ['Felix'] = {
                class = 'mage', threat = 350, perc = 35, tps = 35,
                history = {}, melee = false, tank = false
            },
            ['Tom'] = {
                class = 'warlock', threat = 250, perc = 25, tps = 25,
                history = {}, melee = false, tank = false
            },
            ['Bill'] = {
                class = 'hunter', threat = 100, perc = 10, tps = 10,
                history = {}, melee = false, tank = false
            }
        }

        TWT.tankModeThreats = {
            [1] = {
                creature = 'Infectious Ghoul',
                name = 'Bob',
                perc = 78
            },
            [2] = {
                creature = 'Venom Stalker',
                name = 'Alice',
                perc = 95
            },
            [3] = {
                creature = 'Living Monstrosity',
                name = 'Chad',
                perc = 52
            },
            [4] = {
                creature = 'Deathknight Captain',
                name = 'Olaf',
                perc = 81
            },
            [5] = {
                creature = 'Patchwerk TEST',
                name = 'Jimmy',
                perc = 12
            },
        }

        TWT.targetChanged()

        TWT.targetName = "仇恨统计器"

        TWT.updateUI('testBars')
    else
        TWT.combatEnd()
    end
end
function TWTCloseButton_OnClick()
    _G['TWTMain']:Hide()
    twtprint('Window closed. Type |cff69ccf0/twt show|cffffffff or |cff69ccf0/twtshow|cffffffff to restore it.')
    TWT_CONFIG.visible = false
end

function TWTTankModeWindowCloseButton_OnClick()
    twtprint('Tank Mode disabled. Type |cff69ccf0/twt tankmode|cffffffff to enable it or go into settings.')
    TWTChangeSetting_OnClick(false, 'tankMode')
    _G['TWTMainSettingsTankMode']:SetChecked(false)
end

function TWTTankModeWindowChangeStick_OnClick(to)
    if to then
        TWT_CONFIG.tankModeStick = to
    end
    if TWT_CONFIG.tankModeStick == 'Top' then
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('BOTTOMLEFT', _G['TWTMain'], 'TOPLEFT', 0, 1)
    elseif TWT_CONFIG.tankModeStick == 'Right' then
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('TOPLEFT', _G['TWTMain'], 'TOPRIGHT', 1, 0)
    elseif TWT_CONFIG.tankModeStick == 'Bottom' then
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('TOPLEFT', _G['TWTMain'], 'BOTTOMLEFT', 0, -1)
    elseif TWT_CONFIG.tankModeStick == 'Left' then
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('TOPRIGHT', _G['TWTMain'], 'TOPLEFT', -1, 0)
    end
end

function TWTSettingsToggle_OnClick()
    if _G['TWTMainSettings']:IsVisible() == 1 then
        _G['TWTMainSettings']:Hide()
        TWT.testBars(false)

        _G['TWTMainTankModeWindowStickTopButton']:Hide()
        _G['TWTMainTankModeWindowStickRightButton']:Hide()
        _G['TWTMainTankModeWindowStickBottomButton']:Hide()
        _G['TWTMainTankModeWindowStickLeftButton']:Hide()

    else
        _G['TWTMainSettings']:Show()

        if TWT_CONFIG.tankMode then
            TWTTankModeWindowChangeStick_OnClick()
            _G['TWTMainTankModeWindowStickTopButton']:Show()
            _G['TWTMainTankModeWindowStickRightButton']:Show()
            _G['TWTMainTankModeWindowStickBottomButton']:Show()
            _G['TWTMainTankModeWindowStickLeftButton']:Show()
        end

        TWT.testBars(true)
    end
end

function TWTFontButton_OnClick()
    if _G['TWTMainSettingsFontList']:IsVisible() then
        _G['TWTMainSettingsFontList']:Hide()
    else
        _G['TWTMainSettingsFontList']:Show()
    end
end

function TWTFontSelect(id)
    TWT_CONFIG.font = TWT.fonts[id]
    _G['TWTMainSettingsFontButton']:SetText(TWT_CONFIG.font)
    TWT.updateUI('TWTFontSelect')
end

function TWTTargetButton_OnClick(index)

    local targetData = TWT.tankModeThreats[__parsestring(index)]
    if targetData then
        -- 尝试使用缓存中的GUID查找完整GUID
        local hexID = string.format('%X', targetData.originalID)
        hexID = string.sub(string.rep('0', 6) .. hexID, -6)
        
        for guid, name in pairs(TWTtargetGUIDCache) do
            local guidSuffix = string.sub(guid, -6)
            if string.upper(guidSuffix) == hexID then
                -- 使用完整GUID选取目标
                TargetUnit(guid)
                return true
            end
        end
        
        -- 如果没找到，退回到使用名称
        AssistByName(targetData.name)
        return true
    end

    twtprint('Cannot target tankmode target.')

    return false
end

function __explode(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = __find(str, delimiter, from, 1, true)
    while delim_from do
        __tinsert(result, __substr(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = __find(str, delimiter, from, true)
    end
    __tinsert(result, __substr(str, from))
    return result
end

function TWT.ohShitHereWeSortAgain(t, reverse)
    local a = {}
    for n, l in __pairs(t) do
        __tinsert(a, { ['threat'] = l.threat, ['perc'] = l.perc, ['tps'] = l.tps, ['name'] = n })
    end
    if reverse then
        __tsort(a, function(b, c)
            return b['perc'] > c['perc']
        end)
    else
        __tsort(a, function(b, c)
            return b['perc'] < c['perc']
        end)
    end

    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i]['name'], t[a[i]['name']]
        end
    end
    return iter
end

function TWT.formatNumber(n)

    if n < 0 then
        n = 0
    end

    if n < 999 then
        return TWT.round(n)
    end
    if n < 999999 then
        return TWT.round(n / 10) / 100 .. 'K' or 0
    end
    --1,000,000
    return TWT.round(n / 10000) / 100 .. 'M' or 0
end

function TWT.tableSize(t)
    local size = 0
    for _, _ in next, t do
        size = size + 1
    end
    return size
end

function TWT.targetFromName(name)
    if name == TWT.name then
        return 'target'
    end
    
    -- 尝试从团队中查找
    if TWT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n = GetRaidRosterInfo(i)
                if n == name then
                    return 'raid' .. i
                end
            end
        end
    end
    
    -- 尝试从队伍中查找
    if TWT.channel == 'PARTY' or (not TWT.channel and GetNumPartyMembers() > 0) then
        for i = 1, GetNumPartyMembers() do
            local unitId = 'party' .. i
            if UnitName(unitId) then
                if name == UnitName(unitId) then
                    return unitId
                end
            end
        end
    end
    
      -- 最后尝试目标
     return 'target'
end

-- 威胁值查询函数
function TWTtargetThreat(mode, rank)
    if mode == "t" then
        -- 返回指定排名的威胁目标
        local rankNum = rank or 1
        local currentRank = 0
        
        -- 遍历排序后的威胁数据
        for name, data in TWT.ohShitHereWeSortAgain(TWT.threats, true) do
            currentRank = currentRank + 1
            if currentRank == rankNum then
                return name, data.perc or 0
            end
        end
        
        return "", 0 -- 如果找不到指定排名，返回空字符串和0
        
    elseif mode == "m" then
        -- 返回自己的威胁百分比
        if TWT.threats[TWT.name] and TWT.threats[TWT.name].perc then
            return TWT.threats[TWT.name].perc
        else
            return 0
        end
    end
    
    return nil
end

-- 标记图标纹理路径 (使用单个整合纹理)
local MARK_TEXTURE = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local markTexCoords = {
                 {0, 0.25, 0, 0.25},        -- 1: 黄星
                 {0.25, 0.5, 0, 0.25},      -- 2: 橙圆
                 {0.5, 0.75, 0, 0.25},      -- 3: 紫菱形
                 {0.75, 1, 0, 0.25},        -- 4: 绿三角
                 {0, 0.25, 0.25, 0.5},      -- 5: 月亮
                 {0.25, 0.5, 0.25, 0.5},    -- 6: 蓝方
                 {0.5, 0.75, 0.25, 0.5},    -- 7: 红叉
                 {0.75, 1, 0.25, 0.5},      -- 8: 骷髅
}

-- 初始化坦克模块窗口移动功能
function TWTInitTankModeWindowMovement()
    if not _G['TWTMainTankModeWindow'] then return end
    
    -- 设置窗口为可移动
       _G['TWTMainTankModeWindow']:SetToplevel(true)
       _G['TWTMainTankModeWindow']:SetMovable(true)
        _G['TWTMainTankModeWindow']:EnableMouse(true)
       _G['TWTMainTankModeWindow']:SetClampedToScreen(true)
    
    -- 添加鼠标事件处理
    _G['TWTMainTankModeWindow']:SetScript('OnMouseDown', function(_, button)
        if button == 'LeftButton' then
         _G['TWTMainTankModeWindow']:StartMoving()
        end
    end)
    
    _G['TWTMainTankModeWindow']:SetScript('OnMouseUp', function(_, button)
        if button == 'LeftButton' then
          _G['TWTMainTankModeWindow']:StopMovingOrSizing()
        end
    end)
end

-- 在加载时初始化移动功能
TWTInitTankModeWindowMovement()

function TWT.unitNameForTitle(name, limit, unitId)
    limit = limit or TWT.nameLimit
    local formattedName = name
    
    if __strlen(name) > limit then
        formattedName = __substr(name, 1, limit) .. ' '
    end
    
    -- 添加团队标记图标到名字左侧
    if unitId and UnitExists(unitId) then
        local raidIconIndex = GetRaidTargetIndex(unitId)
        
        if raidIconIndex and markTexCoords[raidIconIndex] then
            local coords = markTexCoords[raidIconIndex]
            formattedName = '|T' .. MARK_TEXTURE .. ':' .. 12 .. ':' .. 12 .. ':0:0:' .. 
                           256 .. ':' .. 256 .. ':' .. (coords[1]*256) .. ':' .. (coords[2]*256) .. ':' .. 
                           (coords[3]*256) .. ':' .. (coords[4]*256) .. '|t ' .. formattedName
        end
    end
    
    return formattedName
end

function TWT.targetRaidIcon(iconIndex)

    for i = 1, GetNumRaidMembers() do
        if TWT.targetRaidSymbolFromUnit("raid" .. i, iconIndex) then
            return true
        end
    end
    for i = 1, GetNumPartyMembers() do
        if TWT.targetRaidSymbolFromUnit("party" .. i, iconIndex) then
            return true
        end
    end
    if TWT.targetRaidSymbolFromUnit("player", iconIndex) then
        return true
    end
    return false
end

function TWT.updateTitleBarText(text)
    if not text then
        _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)
        return true
    end
    _G['TWTMainTitle']:SetText(text)
end

function TWTUpdateTitleBarColor()
    local color
    local alpha = 1
    
    -- 根据配置选择颜色
    if TWT_CONFIG.useCustomTitleColor and TWT_CONFIG.customTitleColor then
        color = TWT_CONFIG.customTitleColor
        alpha = TWT_CONFIG.customTitleAlpha
    else
        color = TWT.classColors[TWT.class]
    end
    
    -- 设置各个标题栏的颜色和透明度
    _G['TWTMainTitleBG']:SetVertexColor(color.r, color.g, color.b, alpha)
    _G['TWTMainSettingsTitleBG']:SetVertexColor(color.r, color.g, color.b, alpha)
    _G['TWTMainTankModeWindowTitleBG']:SetVertexColor(color.r, color.g, color.b, alpha)
    
    -- 设置设置界面标签页按钮的颜色
    for i = 1, 3 do
        if _G['TWTMainSettingsTab' .. i .. 'ButtonNT'] then
            _G['TWTMainSettingsTab' .. i .. 'ButtonNT']:SetVertexColor(color.r, color.g, color.b, 1)
        end
        if _G['TWTMainSettingsTab' .. i .. 'ButtonHT'] then
            _G['TWTMainSettingsTab' .. i .. 'ButtonHT']:SetVertexColor(color.r, color.g, color.b, 1)
        end
        if _G['TWTMainSettingsTab' .. i .. 'ButtonPT'] then
            _G['TWTMainSettingsTab' .. i .. 'ButtonPT']:SetVertexColor(color.r, color.g, color.b, 1)
        end
    end
    
    -- 更新标签页下划线颜色
    if _G['TWTMainSettingsTabsUnderline'] then
        _G['TWTMainSettingsTabsUnderline']:SetVertexColor(color.r, color.g, color.b)
        _G['TWTMainSettingsTabsUnderline']:SetPoint('TOPLEFT', 1, -43) -- 固定值，不随标题栏高度变化
    end
    
    -- 更新设置标签页位置
    for i = 1, 3 do
        if _G['TWTMainSettingsTab' .. i .. 'Button'] then
            _G['TWTMainSettingsTab' .. i .. 'Button']:SetPoint('TOPLEFT', 1 + (i - 1) * 82, -20) -- 固定值，不随标题栏高度变化
        end
        if _G['TWTMainSettingsTab' .. i] then
            _G['TWTMainSettingsTab' .. i]:SetPoint('TOPLEFT', 0, -44) -- 固定值，不随标题栏高度变化
        end
    end
    
    -- 更新标签颜色，使用与标题栏相同的颜色
    local labelColor = color
    local labelAlpha = alpha
    
    if _G['TWTMainNameLabel'] then
        _G['TWTMainNameLabel']:SetTextColor(labelColor.r, labelColor.g, labelColor.b, labelAlpha)
    end
    if _G['TWTMainTPSLabel'] then
        _G['TWTMainTPSLabel']:SetTextColor(labelColor.r, labelColor.g, labelColor.b, labelAlpha)
    end
    if _G['TWTMainThreatLabel'] then
        _G['TWTMainThreatLabel']:SetTextColor(labelColor.r, labelColor.g, labelColor.b, labelAlpha)
    end
    if _G['TWTMainPercLabel'] then
        _G['TWTMainPercLabel']:SetTextColor(labelColor.r, labelColor.g, labelColor.b, labelAlpha)
    end
    
    -- 确保标题文本垂直居中
    if _G['TWTMainTitle'] then
        local titleFontSize = math.floor(TWT_CONFIG.titleHeight * 0.6)
        
        -- 清除所有旧锚点
        _G['TWTMainTitle']:ClearAllPoints()
        
        -- 精确计算垂直居中的Y偏移量
        local titleBGHalfHeight = TWT_CONFIG.titleHeight / 2
        local textHalfHeight = titleFontSize / 2
        local titleYOffset = -titleBGHalfHeight + textHalfHeight
        
        -- 设置左对齐和垂直居中
        _G['TWTMainTitle']:SetPoint('TOPLEFT', 5, titleYOffset)
    end
end

function TWTTitleColorPicker_OnClick()
    -- 确保TWT_CONFIG.customTitleColor存在
    if not TWT_CONFIG.customTitleColor then
        TWT_CONFIG.customTitleColor = { r = 1, g = 1, b = 1 }
    end
    
    -- 保存原始颜色值，用于取消操作
    local originalColor = {
        r = TWT_CONFIG.customTitleColor.r,
        g = TWT_CONFIG.customTitleColor.g,
        b = TWT_CONFIG.customTitleColor.b
    }
    
    -- 设置颜色选择器函数
    ColorPickerFrame.func = function()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        r = r or 1
        g = g or 1
        b = b or 1
        
        -- 保存选择的颜色
        TWT_CONFIG.customTitleColor = { r = r, g = g, b = b }
        
        -- 更新颜色选择器按钮的显示颜色
        if _G['TWTMainSettingsTitleColorPickerNT'] then
            _G['TWTMainSettingsTitleColorPickerNT']:SetVertexColor(r, g, b)
        end
        
        -- 更新标题栏颜色
        TWTUpdateTitleBarColor()
    end
    
    -- 设置取消函数
    ColorPickerFrame.cancelFunc = function()
        -- 恢复原始颜色
        TWT_CONFIG.customTitleColor = originalColor
        
        -- 更新颜色选择器按钮的显示颜色
        if _G['TWTMainSettingsTitleColorPickerNT'] then
            _G['TWTMainSettingsTitleColorPickerNT']:SetVertexColor(
                originalColor.r,
                originalColor.g,
                originalColor.b
            )
        end
        
        -- 更新标题栏颜色
        TWTUpdateTitleBarColor()
    end
    
    -- 禁用透明度功能（可选）
    ColorPickerFrame.opacityFunc = nil
    ColorPickerFrame.hasOpacity = false
    
    -- 设置初始颜色
    ColorPickerFrame:SetColorRGB(
        TWT_CONFIG.customTitleColor.r,
        TWT_CONFIG.customTitleColor.g,
        TWT_CONFIG.customTitleColor.b
    )
    
    -- 显示颜色选择器
    ColorPickerFrame:Show()
end

function TWTTitleAlphaSlider_OnValueChanged()
    local alpha = this:GetValue()
    TWT_CONFIG.customTitleAlpha = alpha
    
    -- 如果启用了自定义颜色，立即更新标题栏透明度
    if TWT_CONFIG.useCustomTitleColor then
        TWTUpdateTitleBarColor()
    end
end

-- 标题栏高度滑块函数
function TitleHeightSlider_OnValueChanged()
    TWT_CONFIG.titleHeight = _G['TWTMainSettingsTitleHeightSlider']:GetValue()
    
    -- 更新标题栏高度
    _G['TWTMainTitleBG']:SetHeight(TWT_CONFIG.titleHeight)
    -- 保持设置窗口标题栏高度固定
    _G['TWTMainSettingsTitleBG']:SetHeight(20)
    
    -- 更新标题文本位置和字体大小
    local titleFontSize = math.floor(TWT_CONFIG.titleHeight * 0.6) -- 字体大小为标题高度的60%
    
    -- 确保标题文字在标题栏背景中垂直居中
    -- 清除所有旧锚点
    _G['TWTMainTitle']:ClearAllPoints()
    
    -- 精确计算垂直居中的Y偏移量
    -- 标题栏背景高度的一半减去标题文字高度的一半
    local titleBGHalfHeight = TWT_CONFIG.titleHeight / 2
    local textHalfHeight = titleFontSize / 2
    local titleYOffset = -titleBGHalfHeight + textHalfHeight
    
    -- 设置左对齐和垂直居中
    _G['TWTMainTitle']:SetPoint('TOPLEFT', 5, titleYOffset)
    _G['TWTMainTitle']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", titleFontSize, "OUTLINE")
    
    -- 更新标签位置
    if TWT_CONFIG.labelRow then
        -- 标签大小跟随标题大小变化
        local labelFontSize = math.floor(titleFontSize * 0.8) -- 标签字体大小为标题的80%
        
        -- 设置所有标签的字体大小
        local fontPath = "Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf"
        _G['TWTMainNameLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        _G['TWTMainTPSLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        _G['TWTMainThreatLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        _G['TWTMainPercLabel']:SetFont(fontPath, labelFontSize, "OUTLINE")
        
        -- 计算标签的Y偏移量，确保所有标签在同一水平线上
        local labelYOffset = -TWT_CONFIG.titleHeight - 4
        
        -- 更新所有标签位置，确保它们在同一水平线上
        _G['TWTMainNameLabel']:ClearAllPoints()
        _G['TWTMainNameLabel']:SetPoint('TOPLEFT', 5, labelYOffset)
        
        -- 调用setColumnLabels函数来重新设置所有标签的正确位置
        TWT.setColumnLabels()
        
        local labelRowHeight = TWT_CONFIG.labelRow and (math.floor(TWT_CONFIG.titleHeight * 0.8) + 8) or 0
        -- 只更新标题栏和标签位置，不调整窗口高度
        
        -- 更新仇恨条背景位置
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -TWT_CONFIG.titleHeight - labelRowHeight)
    else
        -- 只更新仇恨条背景位置，不调整窗口高度
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -TWT_CONFIG.titleHeight)
    end
    
    -- 只更新调整范围，不调整窗口高度
    TWT.setMinMaxResize()
    TWT.updateUI('TitleHeightSlider_OnValueChanged')
end


-- https://github.com/shagu/pfUI/blob/master/api/api.lua#L596
function TWT.wipe(src)
    -- notes: table.insert, table.remove will have undefined behavior
    -- when used on tables emptied this way because Lua removes nil
    -- entries from tables after an indeterminate time.
    -- Instead of table.insert(t,v) use t[table.getn(t)+1]=v as table.getn collapses nil entries.
    -- There are no issues with hash tables, t[k]=v where k is not a number behaves as expected.
    local mt = getmetatable(src) or {}
    if mt.__mode == nil or mt.__mode ~= "kv" then
        mt.__mode = "kv"
        src = setmetatable(src, mt)
    end
    for k in __pairs(src) do
        src[k] = nil
    end
    return src
end

TWT.hooks = {}
--https://github.com/shagu/pfUI/blob/master/compat/vanilla.lua#L37
function TWT.hooksecurefunc(name, func, append)
    if not _G[name] then
        return
    end

    TWT.hooks[__parsestring(func)] = {}
    TWT.hooks[__parsestring(func)]["old"] = _G[name]
    TWT.hooks[__parsestring(func)]["new"] = func

    if append then
        TWT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    else
        TWT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    end

    _G[name] = TWT.hooks[__parsestring(func)]["function"]
end

function TWT.pairsByKeys(t, f)
    local a = {}
    for n in __pairs(t) do
        __tinsert(a, n)
    end
    __tsort(a, function(a, b)
        return a < b
    end)
    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function TWT.round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return __floor(num * mult + 0.5) / mult
end

function TWT.version(ver)
    local verEx = __explode(ver, '.')

    if verEx[3] then
        -- new versioning with 3 numbers
        return __parseint(verEx[1]) * 100 +
                __parseint(verEx[2]) * 10 +
                __parseint(verEx[3]) * 1
    end

    -- old versioning
    return __parseint(verEx[1]) * 10 +
            __parseint(verEx[2]) * 1

end
-- function TWT.sendMyVersion()
--     SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "PARTY")
--     SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "GUILD")
--     SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "RAID")
--     SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "BATTLEGROUND")
-- end