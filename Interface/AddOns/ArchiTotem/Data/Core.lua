-- ArchiTotem 核心模块
-- 包含主要的游戏逻辑和事件处理

if SUPERWOW_VERSION then
    SLASH_UTB1 = "/tooltip"
    SlashCmdList["UTB"] = function() end
end

local _G = getfenv()
local L = ArchiTotemLocale
local version = GetAddOnMetadata("ArchiTotem", "Version")
local author = GetAddOnMetadata("ArchiTotem", "Author")

local _, class = UnitClass("player")
local CLOCK_UPDATE_RATE = 0.1

-- 全局变量
ArchiTotemCasted = nil
ArchiTotemCastedTotem = nil
ArchiTotemCastedElement = nil
ArchiTotemCastedButton = nil
ArchiTotemActiveTotem = {}

-- 自动检测召唤图腾的表
ArchiTotem_PendingSummons = {}      -- 待确认的召唤单位（GUID）
ArchiTotem_ActivePlacedTotems = {}  -- 已确认是自己图腾的单位（GUID -> {name, element}）

-- 恢复过程中避免自动保存
ArchiTotem_IsRestoring = false

-- 图腾名称到元素的映射
ArchiTotem_TotemNameToElement = {}

-- Nampower 支持标志
local hasNampower = false
local hasUnitXP = false  -- 标记 UnitXP 是否可用

-- 图腾掌握天赋加成相关（与之前相同，保留）
ArchiTotem_TotemicMasteryBonus = 0
ArchiTotem_TotemicMasteryActive = nil
ArchiTotem_TalentsInitPending = true
ArchiTotem_TalentsInitDeadline = nil
ArchiTotem_TalentsRetryActive = false
ArchiTotem_TalentsRetryNext = nil
ArchiTotem_TalentsRetryDeadline = nil
ArchiTotem_TalentsPollInterval = 0.5

-- 天赋匹配
local TOTEMIC_MASTERY_NAMES = {
    ["Totemic Mastery"] = true,
    ["图腾掌握"] = true,
    ["图腾精通"] = true,
}

local function ArchiTotem_IsTotemicMasteryName(name)
    if not name then return false end
    if TOTEMIC_MASTERY_NAMES[name] then return true end
    local lname = tostring(name)
    if string.find(lname, "Totem") and string.find(lname, "Master") then return true end
    if string.find(lname, "图腾") and (string.find(lname, "掌") or string.find(lname, "精通") or string.find(lname, "统御")) then return true end
    return false
end

local TOTEMIC_MASTERY_CANDIDATES = {
    { tab = 3, index = 8 },
    { tab = 3, index = 5 },
    { tab = 3, index = 4 },
    { tab = 3, index = 2 },
    { tab = 2, index = 5 },
}

local function ArchiTotem_IsTalentAPIReady()
    if not GetNumTalentTabs or not GetNumTalents or not GetTalentInfo then return false end
    local numTabs = GetNumTalentTabs()
    if not numTabs or numTabs <= 0 then return false end
    for tab = 1, numTabs do
        local n = GetNumTalents(tab)
        if n and n > 0 then
            local name = select(1, GetTalentInfo(tab, 1))
            if name ~= nil and name ~= "" then return true end
        end
    end
    return false
end

function ArchiTotem_ScheduleTalentDetection(reason, timeoutSec)
    if ArchiTotem_TalentsRetryActive or ArchiTotem_TotemicMasteryActive ~= nil then return end
    ArchiTotem_TalentsRetryActive = true
    ArchiTotem_TalentsRetryNext = GetTime() + (ArchiTotem_TalentsPollInterval or 0.5)
    ArchiTotem_TalentsRetryDeadline = GetTime() + (timeoutSec or 15)
    ArchiTotem_TalentsInitPending = false
    if ArchiTotem_Options and ArchiTotem_Options["Debug"] then
        ArchiTotem_Print(string.format("[天赋] 启动轮询（原因=%s，超时=%ds）", tostring(reason), timeoutSec or 15), "debug")
    end
end

function ArchiTotem_PrintTotemicMasteryStatus()
    local mode = "自动"
    if ArchiTotem_Options and ArchiTotem_Options.ForceTotemicMastery ~= nil then
        mode = (ArchiTotem_Options.ForceTotemicMastery and "强制开启" or "强制关闭")
    elseif ArchiTotem_Options and ArchiTotem_Options.TotemicMasteryTab and ArchiTotem_Options.TotemicMasteryIndex then
        mode = string.format("索引: %d:%d", ArchiTotem_Options.TotemicMasteryTab, ArchiTotem_Options.TotemicMasteryIndex)
    end
    if ArchiTotem_TotemicMasteryActive then
        ArchiTotem_Print("图腾掌握：已启用（+20% 持续时间） [" .. mode .. "]")
    else
        ArchiTotem_Print("图腾掌握：未启用 [" .. mode .. "]")
    end
end

function ArchiTotem_UpdateTalents()
    if class ~= "SHAMAN" then
        ArchiTotem_TotemicMasteryBonus = 0
        return
    end
    local hasTalent = false
    if ArchiTotem_Options and ArchiTotem_Options.ForceTotemicMastery ~= nil then
        hasTalent = (ArchiTotem_Options.ForceTotemicMastery == true)
        ArchiTotem_TotemicMasteryBonus = hasTalent and 0.20 or 0
        local prev = ArchiTotem_TotemicMasteryActive
        ArchiTotem_TotemicMasteryActive = hasTalent
        if prev ~= hasTalent then ArchiTotem_PrintTotemicMasteryStatus() end
        if ArchiTotem_Options["Debug"] then ArchiTotem_Print("[天赋] ForceTotemicMastery=" .. tostring(hasTalent)) end
        return
    end

    if ArchiTotem_Options and ArchiTotem_Options.TotemicMasteryTab and ArchiTotem_Options.TotemicMasteryIndex then
        local tab = ArchiTotem_Options.TotemicMasteryTab
        local index = ArchiTotem_Options.TotemicMasteryIndex
        local name, _, _, _, rank = GetTalentInfo(tab, index)
        if name and ArchiTotem_IsTotemicMasteryName(name) and (rank or 0) > 0 then hasTalent = true end
    end

    if not hasTalent then
        for _, pos in ipairs(TOTEMIC_MASTERY_CANDIDATES) do
            local name, _, _, _, rank = GetTalentInfo(pos.tab, pos.index)
            if name and ArchiTotem_IsTotemicMasteryName(name) and (rank or 0) > 0 then
                hasTalent = true
                break
            end
        end
    end

    if not hasTalent then
        local numTabs = GetNumTalentTabs and GetNumTalentTabs() or 0
        for tab = 1, numTabs do
            local numTalents = GetNumTalents(tab) or 0
            for i = 1, numTalents do
                local name, _, _, _, rank = GetTalentInfo(tab, i)
                if name and ArchiTotem_IsTotemicMasteryName(name) and (rank or 0) > 0 then
                    hasTalent = true
                    break
                end
            end
            if hasTalent then break end
        end
    end

    ArchiTotem_TotemicMasteryBonus = hasTalent and 0.20 or 0
    local prev = ArchiTotem_TotemicMasteryActive
    ArchiTotem_TotemicMasteryActive = hasTalent
    if prev ~= hasTalent then ArchiTotem_PrintTotemicMasteryStatus() end
end

function ArchiTotem_Print(msg, type)
    if class ~= "SHAMAN" then return end
    local prefix
    if type == "error" then
        prefix = "|CFF20B2AA[ArchiTotem] |CFFFF0000[ERROR]|r  "
    elseif type == "debug" then
        prefix = "|CFF20B2AA[ArchiTotem] |CFF0000CD[DEBUG]|r  "
    else
        prefix = "|CFF20B2AA[ArchiTotem]|r  "
    end
    return DEFAULT_CHAT_FRAME:AddMessage(prefix .. msg)
end

function ArchiTotem_IsShaman()
    return class == "SHAMAN"
end

function ArchiTotem_Noop()
    return
end

-- 构建图腾名称到元素的映射表
function ArchiTotem_BuildTotemNameToElementMap()
    ArchiTotem_TotemNameToElement = {}
    for buttonName, data in pairs(ArchiTotem_TotemData) do
        local element = string.match(buttonName, "^ArchiTotemButton_(%a+)%d+$")
        if element and data.name then
            local locName = L[data.name] or data.name
            ArchiTotem_TotemNameToElement[locName] = element
        end
    end
end

-- 创建覆盖数显示文本（初始默认放在按钮上方）
function ArchiTotem_CreateCoverageTexts()
    local elements = {"Earth", "Fire", "Water", "Air"}
    for _, element in ipairs(elements) do
        local button = _G["ArchiTotemButton_" .. element .. "1"]
        if button and not _G[element .. "CoverageText"] then
            local text = button:CreateFontString(element .. "CoverageText", "OVERLAY", "GameFontNormal")
            text:SetTextColor(0.5, 1, 0.5, 1)
            -- 默认锚定在按钮顶部上方 2 像素（后续可能被方向调整覆盖）
            text:SetPoint("BOTTOM", button, "TOP", 0, 2)
            text:Hide()
        end
    end
end

-- 根据方向更新覆盖文本位置，避免与持续时间文字重叠
local function ArchiTotem_UpdateCoverageTextPositions()
    local elements = {"Earth", "Fire", "Water", "Air"}
    for _, element in ipairs(elements) do
        local text = _G[element .. "CoverageText"]
        local button = _G["ArchiTotemButton_" .. element .. "1"]
        if text and button then
            text:ClearAllPoints()
            text:SetPoint("BOTTOM", button, "TOP", 0, 2)
        end
    end
end

-- Nampower 检测与事件注册
local function ArchiTotem_CheckNampower()
    if not GetNampowerVersion then hasNampower = false; return end
    local major, minor, patch = GetNampowerVersion()
    if major and (major > 4 or (major == 4 and minor >= 5)) then
        hasNampower = true
        SetCVar("NP_EnableSpellGoEvents", "1")
        this:RegisterEvent("SPELL_GO_SELF")
        this:RegisterEvent("UNIT_MODEL_CHANGED_GUID")
        if ArchiTotem_Options and ArchiTotem_Options["Debug"] then
            ArchiTotem_Print("Nampower detected, enabled SPELL_GO_SELF and UNIT_MODEL_CHANGED_GUID events.")
        end
    else
        hasNampower = false
    end

    -- 检测 UnitXP 是否可用
    local ok = pcall(UnitXP, "nop", "nop")
    hasUnitXP = ok
end

-- 通过技能ID匹配图腾按钮（Nampower 专用）
local function ArchiTotem_FindTotemFromSpellId(spellId)
    if not hasNampower then return nil, nil, nil end
    local spellName, spellRank = GetSpellNameAndRankForId(spellId)
    if not spellName then return nil, nil, nil end
    local cleanName = string.gsub(spellName, "%s*%(.*%)", "")
    if cleanName == "" then return nil, nil, nil end

    local recallName = L["Totemic Recall"]
    if cleanName == recallName then
        return "ArchiTotemButton_Recall", nil, ArchiTotem_TotemData["ArchiTotemButton_Recall"]
    end

    for buttonName, data in pairs(ArchiTotem_TotemData) do
        if buttonName ~= "ArchiTotemButton_AllTotems" and
           buttonName ~= "ArchiTotemButton_Recall" and
           buttonName ~= "ArchiTotemButton_PresetManager" and
           type(data) == "table" and data.name then
            local localizedName = L[data.name] or data.name
            if localizedName == cleanName then
                local element = string.match(buttonName, "^ArchiTotemButton_(%a+)%d+$")
                if element then
                    return buttonName, element, data
                end
            end
        end
    end
    return nil, nil, nil
end

-- 通用图腾施放处理
local function ArchiTotem_HandleAutoTotemCast(buttonName, element, data)
    local firstButton = "ArchiTotemButton_" .. element .. "1"
    if buttonName ~= firstButton and ArchiTotem_TotemData[firstButton] and ArchiTotem_TotemData[buttonName] then
        ArchiTotem_Switch(firstButton, buttonName)
    end
    local totemData = ArchiTotem_TotemData[firstButton]
    ArchiTotemActiveTotem[element] = totemData
    ArchiTotemActiveTotem[element].casted = GetTime()
    totemData.cooldownstarted = GetTime()
    
    local cooldownFrame = _G[firstButton .. "Cooldown"]
    if cooldownFrame then
        local duration = totemData.cooldown
        if duration == 0 then duration = 1.5 end
        CooldownFrame_SetTimer(cooldownFrame, GetTime(), duration, 1)
    end
    ArchiTotem_ForceRefreshUI()
end

-- 通用召回处理
local function ArchiTotem_HandleAutoRecall()
    -- 清除所有活跃图腾的倒计时
    for k, v in pairs(ArchiTotemActiveTotem) do
        ArchiTotemActiveTotem[k] = nil
        local durationText = _G[k .. "DurationText"]
        if durationText then durationText:Hide() end
    end
    -- 清空已确认的图腾 GUID 记录
    for guid, _ in pairs(ArchiTotem_ActivePlacedTotems) do
        ArchiTotem_ActivePlacedTotems[guid] = nil
    end
    -- 召回冷却逻辑
    if ArchiTotem_TotemData["ArchiTotemButton_Recall"] then
        local recallData = ArchiTotem_TotemData["ArchiTotemButton_Recall"]
        recallData.cooldownstarted = GetTime()
        local cooldownFrame = _G["ArchiTotemButton_RecallCooldown"]
        if cooldownFrame then
            local duration = recallData.cooldown
            if duration == 0 then duration = 1.5 end
            CooldownFrame_SetTimer(cooldownFrame, GetTime(), duration, 1)
        end
    end
    ArchiTotem_ForceRefreshUI()
end

-- Nampower 事件处理（防重复）
local ArchiTotem_SpellGoHistory = {}
local function ArchiTotem_OnSpellGoSelf(spellId)
    if not hasNampower then return end
    if not spellId then return end
    local now = GetTime()
    local lastTime = ArchiTotem_SpellGoHistory[spellId]
    if lastTime and (now - lastTime) < 0.2 then return end
    ArchiTotem_SpellGoHistory[spellId] = now
    if ArchiTotemCasted == 1 then return end

    local buttonName, element, data = ArchiTotem_FindTotemFromSpellId(spellId)
    if not buttonName then return end
    if buttonName == "ArchiTotemButton_Recall" then
        ArchiTotem_HandleAutoRecall()
    else
        ArchiTotem_HandleAutoTotemCast(buttonName, element, data)
    end
end

-- ========== 战斗日志解析（后备方案，中文） ==========
local function ArchiTotem_CheckCombatLogForTotemRecall(msg)
    if string.find(msg, "你从图腾召回获得") then
        if ArchiTotem_Options and ArchiTotem_Options["Debug"] then ArchiTotem_Print("战斗日志检测到图腾召回") end
        ArchiTotem_HandleAutoRecall()
        return true
    end
    return false
end

local function ArchiTotem_CheckCombatLogForTotem(msg)
    if not string.find(msg, "你施放了") then return false end
    local cleanMsg = string.gsub(msg, "|c%x%x%x%x%x%x%x%x", "")
    cleanMsg = string.gsub(cleanMsg, "|r", "")
    cleanMsg = string.gsub(cleanMsg, "|H.-|h", "")
    cleanMsg = string.gsub(cleanMsg, "|h", "")
    local totemName = string.match(cleanMsg, "你施放了(.+)%.")
    if not totemName then totemName = string.match(cleanMsg, "你施放了(.+)") end
    if not totemName then return false end

    for buttonName, data in pairs(ArchiTotem_TotemData) do
        if buttonName ~= "ArchiTotemButton_AllTotems" and
           buttonName ~= "ArchiTotemButton_Recall" and
           buttonName ~= "ArchiTotemButton_PresetManager" and
           type(data) == "table" and data.name then
            local localizedName = L[data.name]
            if localizedName and string.find(totemName, localizedName) then
                local element = string.match(buttonName, "^ArchiTotemButton_(%a+)%d+$")
                if element then
                    if ArchiTotem_Options and ArchiTotem_Options["Debug"] then ArchiTotem_Print("战斗日志匹配:" .. totemName) end
                    ArchiTotem_HandleAutoTotemCast(buttonName, element, data)
                    return true
                end
            end
        end
    end
    return false
end

-- 主加载
function ArchiTotem_OnLoad()
    if class ~= "SHAMAN" then
        ArchiTotem_Options = nil
        ArchiTotem_TotemData = nil
        this:UnregisterAllEvents()
        ArchiTotemFrame:Hide()
        return
    end

    ArchiTotem_InitializeOptions()
    ArchiTotem_InitializeTotemData()
    ArchiTotem_CheckCompatibility()
    if not ArchiTotem_TotemElements then
        ArchiTotem_TotemElements = {"Earth", "Fire", "Water", "Air"}
    end

    this:RegisterForDrag("RightButton")
    for _, popout in ipairs(ArchiTotem_PopoutButtons) do
        _G[popout]:SetScript("OnDragStart", ArchiTotem_Noop)
        _G[popout]:SetScript("OnDragStop", ArchiTotem_Noop)
    end

    this:RegisterEvent("VARIABLES_LOADED")
    this:RegisterEvent("SPELLCAST_STOP")
    this:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
    this:RegisterEvent("CHAT_MSG_SPELL_FAILED_LOCALPLAYER")
    this:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    this:RegisterEvent("PLAYER_ENTERING_WORLD")
    this:RegisterEvent("PLAYER_LOGIN")
    this:RegisterEvent("PLAYER_ALIVE")
    this:RegisterEvent("SPELLS_CHANGED")
    this:RegisterEvent("PLAYER_TALENT_UPDATE")
    this:RegisterEvent("CHARACTER_POINTS_CHANGED")
    this:RegisterEvent("PLAYER_DEAD")

    -- 检测 Nampower 并决定注册方案
    ArchiTotem_CheckNampower()
    if not hasNampower then
        this:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
        this:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
        this:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")
        this:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
        this:RegisterEvent("CHAT_MSG_SPELL_AURA_GONE_SELF")
        if ArchiTotem_Options and ArchiTotem_Options["Debug"] then
            ArchiTotem_Print("Nampower 未找到，启用战斗日志解析。")
        end
    end

    -- 构建名称-元素映射
    ArchiTotem_BuildTotemNameToElementMap()

    -- 创建覆盖文本
    ArchiTotem_CreateCoverageTexts()

    SLASH_ARCHITOTEM1 = "/architotem"
    SLASH_ARCHITOTEM2 = "/at"
    SlashCmdList["ARCHITOTEM"] = ArchiTotem_Command

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ffff图腾助手 已加载|r /at")

    ArchiTotem_UpdateShown()
    ArchiTotem_InitPresetManager()
    ArchiTotem_LoadFramePosition()
    ArchiTotem_UpdateDragHandleVisibility()
    ArchiTotemFrame.TimeSinceLastUpdate = 0
end

function ArchiTotem_EnsureDataIntegrity()
    if not ArchiTotem_TotemData then return false end
    local currentTime = GetTime()
    for buttonName, totemData in pairs(ArchiTotem_TotemData) do
        if totemData then
            if totemData.casted == nil then totemData.casted = currentTime - (totemData.cooldown or 0) end
            if totemData.cooldown == nil then totemData.cooldown = 0 end
            if totemData.duration == nil then totemData.duration = 0 end
        end
    end
    return true
end

function ArchiTotem_OnEvent(event)
    if event == "VARIABLES_LOADED" then
        ArchiTotem_EnsureDataIntegrity()
        ArchiTotem_ScheduleTalentDetection("VARIABLES_LOADED", 20)
        ArchiTotem_ClearAllCooldowns()
        ArchiTotem_UpdateTextures()
        ArchiTotem_UpdateShown()
        ArchiTotem_SetDirection(ArchiTotem_Options["Apperance"].direction)
        ArchiTotem_SetScale(ArchiTotem_Options["Apperance"].scale)
        ArchiTotem_Order(ArchiTotem_Options["Order"].first, ArchiTotem_Options["Order"].second,
            ArchiTotem_Options["Order"].third, ArchiTotem_Options["Order"].forth)

        -- 恢复上次保存的图腾配置（非首次使用时）
        if ArchiTotem_Options["Apperance"].isFirstTime == true then
            ArchiTotem_Options["Apperance"].isFirstTime = false
            ArchiTotem_SetPreset("pve")
            ArchiTotem_Print("欢迎使用图腾大师！已自动设置为PVE组合")
            ArchiTotem_Print("使用 /at 查看所有命令，右键点击组合按钮打开管理界面")
        else
            if ArchiTotem_Options["CurrentTotems"] then
            for k,v in pairs(ArchiTotem_Options["CurrentTotems"]) do print(k);print(v) end
                ArchiTotem_RestoreCurrentTotems()
            end
        end
        -- 确保当前配置保存到选项（覆盖之前可能丢失的存档）
        ArchiTotem_UpdateCurrentTotemsOption()
        ArchiTotem_UpdateShown()
        ArchiTotem_LoadFramePosition()
        ArchiTotem_UpdateDragHandleVisibility()
        -- 更新覆盖文本位置以匹配当前方向
        ArchiTotem_UpdateCoverageTextPositions()
    elseif event == "CHAT_MSG_SPELL_FAILED_LOCALPLAYER" then
        ArchiTotemCasted = 0
    elseif event == "SPELLCAST_STOP" then
        if ArchiTotemCasted == 1 then
            ArchiTotemActiveTotem[ArchiTotemCastedElement] = ArchiTotemCastedTotem
            ArchiTotemActiveTotem[ArchiTotemCastedElement].casted = GetTime()
            ArchiTotem_TotemData[ArchiTotemCastedButton].cooldownstarted = GetTime()
            ArchiTotem_UpdateAllCooldowns(ArchiTotemCastedButton)
            if ArchiTotem_Options["Apperance"].bottomoncast == true then
                local buttonNumber = tonumber(string.sub(ArchiTotemCastedButton, -1, -1))
                if buttonNumber > 1 then
                    local topbutton, bottombutton
                    for i = buttonNumber, 2, -1 do
                        topbutton = string.sub(ArchiTotemCastedButton, 1, -2) .. i
                        bottombutton = string.sub(ArchiTotemCastedButton, 1, -2) .. (i - 1)
                        ArchiTotem_Switch(topbutton, bottombutton)
                        if ArchiTotem_TotemData[topbutton].cooldownstarted == nil then
                            CooldownFrame_SetTimer(_G[topbutton .. "Cooldown"], GetTime(), 1.5, 1)
                        end
                    end
                    local duration = ArchiTotem_TotemData[bottombutton].cooldown
                    if duration == 0 then duration = 1.5 end
                    CooldownFrame_SetTimer(_G[bottombutton .. "Cooldown"], GetTime(), duration, 1)
                end
            end
            ArchiTotemCasted = nil
            ArchiTotemCastedTotem = nil
            ArchiTotemCastedButton = nil
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        ArchiTotem_ScheduleTalentDetection("PLAYER_ENTERING_WORLD", 20)
        if not hasNampower and GetNampowerVersion then ArchiTotem_CheckNampower() end
    elseif event == "PLAYER_LOGIN" then
        ArchiTotem_ScheduleTalentDetection("PLAYER_LOGIN", 20)
    elseif event == "PLAYER_ALIVE" then
        ArchiTotem_ScheduleTalentDetection("PLAYER_ALIVE", 20)
    elseif event == "PLAYER_TALENT_UPDATE" or event == "CHARACTER_POINTS_CHANGED" or event == "SPELLS_CHANGED" then
        ArchiTotem_UpdateTalents()
    elseif event == "SPELLS_CHANGED" then
        ArchiTotem_ScheduleTalentDetection("SPELLS_CHANGED", 20)
    elseif event == "PLAYER_DEAD" then
        for k, v in pairs(ArchiTotemActiveTotem) do
            ArchiTotemActiveTotem[k] = nil
            local durationText = _G[k .. "DurationText"]
            if durationText then durationText:Hide() end
        end
    elseif event == "SPELL_GO_SELF" then
        local spellId = arg2
        ArchiTotem_OnSpellGoSelf(spellId)
    elseif event == "UNIT_MODEL_CHANGED_GUID" then
        local guid = arg1
        if guid and ArchiTotem_IsShaman() then
            local ownerGuid = GetUnitGUID(guid .. "owner")
            if ownerGuid and ownerGuid == GetUnitGUID("player") then
                if not ArchiTotem_ActivePlacedTotems[guid] and not ArchiTotem_PendingSummons[guid] then
                    ArchiTotem_PendingSummons[guid] = true
                    if ArchiTotem_Options and ArchiTotem_Options["Debug"] then
                        ArchiTotem_Print("捕获潜在图腾 GUID: " .. guid, "debug")
                    end
                end
            end
        end
    elseif not hasNampower and (event == "CHAT_MSG_SPELL_SELF_BUFF" or
         event == "CHAT_MSG_SPELL_SELF_DAMAGE" or
         event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" or
         event == "CHAT_MSG_COMBAT_SELF_HITS" or
         event == "CHAT_MSG_SPELL_AURA_GONE_SELF") then
        if arg1 then
            if not ArchiTotem_CheckCombatLogForTotemRecall(arg1) then
                ArchiTotem_CheckCombatLogForTotem(arg1)
            end
        end
    end
end

-- 去除图腾名称末尾的罗马数字等级后缀
local function ArchiTotem_CleanTotemName(name)
    if not name then return nil end
    -- 匹配结尾可能存在的空格和罗马数字（I/V/X的常见组合，支持到 V 甚至更高）
    local cleaned = string.gsub(name, "%s*[IVXLCDM]+$", "")
    return cleaned
end

-- 修改 ArchiTotem_BuildTotemNameToElementMap
function ArchiTotem_BuildTotemNameToElementMap()
    ArchiTotem_TotemNameToElement = {}
    for buttonName, data in pairs(ArchiTotem_TotemData) do
        local element = string.match(buttonName, "^ArchiTotemButton_(%a+)%d+$")
        if element and data.name then
            local locName = L[data.name] or data.name
            -- 使用清理后的名字作为键
            local cleanName = ArchiTotem_CleanTotemName(locName)
            ArchiTotem_TotemNameToElement[cleanName] = element
        end
    end
end

-- 修改 ArchiTotem_CheckSummonedUnits 中的名字匹配部分
function ArchiTotem_CheckSummonedUnits()
    -- 处理待确认的召唤单位
    for guid, _ in pairs(ArchiTotem_PendingSummons) do
        if UnitExists(guid) then
            local name = UnitName(guid)
            if name and name ~= "" and name ~= "未知目标" then
                if string.find(name, "图腾") then
                    local cleanName = ArchiTotem_CleanTotemName(name)
                    if cleanName then
                        local element = ArchiTotem_TotemNameToElement[cleanName]
                        if element then
                            ArchiTotem_ActivePlacedTotems[guid] = {name = name, element = element}
                        end
                    end
                end
                ArchiTotem_PendingSummons[guid] = nil
            else
                ArchiTotem_PendingSummons[guid] = nil
            end
        else
            ArchiTotem_PendingSummons[guid] = nil
        end
    end

    -- 检查已激活的图腾，若不存在则清理
    local toRemove = {}
    for guid, data in pairs(ArchiTotem_ActivePlacedTotems) do
        if not UnitExists(guid) then
            local element = data.element
            if element then
                local activeTotem = ArchiTotemActiveTotem[element]
                -- 若该元素有活跃图腾且刚施放不久（<1秒），暂不清除，避免闪烁
                if activeTotem and activeTotem.casted and (GetTime() - activeTotem.casted) < 1.0 then
                    -- 保留，不清理
                else
                    ArchiTotemActiveTotem[element] = nil
                    local durationText = _G[element .. "DurationText"]
                    if durationText then durationText:Hide() end
                end
            end
            table.insert(toRemove, guid)
        end
    end
    for _, guid in ipairs(toRemove) do
        ArchiTotem_ActivePlacedTotems[guid] = nil
    end
end

-- 计算并更新图腾覆盖文本
function ArchiTotem_UpdateTotemCoverage()
    if not hasUnitXP then
        for _, element in ipairs({"Earth","Fire","Water","Air"}) do
            local text = _G[element .. "CoverageText"]
            if text then text:Hide() end
        end
        return
    end

    local unitIds = {"player", "party1", "party2", "party3", "party4"}
    local elements = {Earth = true, Fire = true, Water = true, Air = true}

    -- 动态计算小队最大人数（玩家 + 队友）
    local maxPlayers = GetNumPartyMembers() + 1

    -- 初始化覆盖数为0
    local coverageCounts = {Earth = 0, Fire = 0, Water = 0, Air = 0}
    local activeGuids = {}  -- 记录每个元素当前激活的图腾 GUID

    -- 收集当前激活的图腾 GUID 及其元素
    for guid, data in pairs(ArchiTotem_ActivePlacedTotems) do
        if data.element and elements[data.element] then
            activeGuids[data.element] = guid
        end
    end

    -- 对每个元素计算覆盖
    for element, guid in pairs(activeGuids) do
        local count = 0
        for _, unitId in ipairs(unitIds) do
            if UnitExists(unitId) then
                local dist = UnitXP("distanceBetween", guid, unitId)
                if dist and dist <= 30 then
                    count = count + 1
                end
            end
        end
        coverageCounts[element] = count
    end

    -- 更新 UI 文本，并设置颜色
    for element, count in pairs(coverageCounts) do
        local text = _G[element .. "CoverageText"]
        if text then
            if activeGuids[element] then
                local ratio = maxPlayers > 0 and (count / maxPlayers) or 0
                if ratio > 0.8 then
                    text:SetTextColor(0.2, 1, 0.2, 1)   -- 绿色 (>80%)
                elseif ratio >= 0.6 then
                    text:SetTextColor(1, 1, 0, 1)        -- 黄色 (60%-80%)
                else
                    text:SetTextColor(1, 0.3, 0.3, 1)    -- 红色 (<60%)
                end
                text:SetText(count .. "/" .. maxPlayers)
                text:Show()
            else
                text:Hide()
            end
        end
    end
end

-- 以下为原有函数（ArchiTotem_GetSpellId, CastTotem, Switch, UpdateCooldown, UpdateAllCooldowns, OnUpdate 等）
function ArchiTotem_GetSpellId(spell)
    local localizeSpell = L[spell]
    local spellID = 0
    for id = 1, 360 do
        local spellName = GetSpellName(id, BOOKTYPE_SPELL)
        if spellName and string.find(spellName, localizeSpell) then spellID = id end
    end
    return spellID
end

function ArchiTotem_CastTotem()
    ArchiTotemCasted = 1
    ArchiTotemCastedTotem = ArchiTotem_TotemData[this:GetName()]
    ArchiTotemCastedElement = string.sub(this:GetName(), 18, -2)
    ArchiTotemCastedButton = this:GetName()
    if ArchiTotemCastedTotem.casted == nil then
        ArchiTotemCastedTotem.casted = GetTime() - ArchiTotemCastedTotem.cooldown
    end
    local mincooldown = ArchiTotemCastedTotem.cooldown
    if mincooldown < 1.5 then mincooldown = 1.5 end
    local localizeSpell = L[ArchiTotem_TotemData[this:GetName()].name]
    CastSpellByName(localizeSpell)
end

function ArchiTotem_Switch(arg1, arg2)
    local temp = ArchiTotem_TotemData[arg1]
    ArchiTotem_TotemData[arg1] = ArchiTotem_TotemData[arg2]
    ArchiTotem_TotemData[arg2] = temp

    _G[arg1 .. "CooldownText"]:Hide()
    _G[arg1 .. "CooldownBg"]:Hide()
    _G[arg2 .. "CooldownText"]:Hide()
    _G[arg2 .. "CooldownBg"]:Hide()

    if ArchiTotem_TotemData[arg1] and ArchiTotem_GetSpellId(ArchiTotem_TotemData[arg1].name) ~= 0 then
        local _, duration1 = GetSpellCooldown(ArchiTotem_GetSpellId(ArchiTotem_TotemData[arg1].name), BOOKTYPE_SPELL)
        if ArchiTotem_TotemData[arg1].casted == nil then
            ArchiTotem_TotemData[arg1].casted = GetTime() - (ArchiTotem_TotemData[arg1].cooldown or 0)
        end
        if duration1 and duration1 > 0 then
            CooldownFrame_SetTimer(_G[arg1 .. "Cooldown"], ArchiTotem_TotemData[arg1].casted, duration1, 1)
        end
    end

    if ArchiTotem_TotemData[arg2] and ArchiTotem_GetSpellId(ArchiTotem_TotemData[arg2].name) ~= 0 then
        local _, duration2 = GetSpellCooldown(ArchiTotem_GetSpellId(ArchiTotem_TotemData[arg2].name), BOOKTYPE_SPELL)
        if ArchiTotem_TotemData[arg2].casted == nil then
            ArchiTotem_TotemData[arg2].casted = GetTime() - (ArchiTotem_TotemData[arg2].cooldown or 0)
        end
        if duration2 and duration2 > 0 then
            CooldownFrame_SetTimer(_G[arg2 .. "Cooldown"], ArchiTotem_TotemData[arg2].casted, duration2, 1)
        end
    end

    ArchiTotem_UpdateTextures()
    ArchiTotem_UpdatePresetManagerDisplay()

    -- 如果交换改变了第一个按钮，更新当前图腾存档
    if string.sub(arg1, -1) == "1" or string.sub(arg2, -1) == "1" then
        ArchiTotem_UpdateCurrentTotemsOption()
    end
end

function ArchiTotem_ClearAllCooldowns()
    for k, v in ArchiTotem_TotemData do
        v.cooldownstarted = nil
    end
end

function ArchiTotem_UpdateCooldown(Buttonname, duration)
    local cooldown = _G[Buttonname .. "Cooldown"]
    if cooldown ~= nil then
        if duration == 0 then duration = 1.5 end
        CooldownFrame_SetTimer(cooldown, GetTime(), duration, 1)
    end
end

function ArchiTotem_UpdateAllCooldowns(_)
    for k, v in ArchiTotem_TotemData do
        if v.casted == nil then v.casted = GetTime() - v.cooldown end
        local duration = 1.5
        if GetTime() > (v.casted + v.cooldown) then
            if ArchiTotemCastedButton == k then duration = v.cooldown else duration = 1.5 end
            ArchiTotem_UpdateCooldown(k, duration)
        end
    end
end

function ArchiTotem_OnUpdate(arg1)
    this.TimeSinceLastUpdate = this.TimeSinceLastUpdate + arg1
    if this.TimeSinceLastUpdate > CLOCK_UPDATE_RATE then
        -- 天赋检测轮询
        if ArchiTotem_TalentsRetryActive and GetTime() >= (ArchiTotem_TalentsRetryNext or 0) then
            ArchiTotem_TalentsRetryNext = GetTime() + (ArchiTotem_TalentsPollInterval or 0.5)
            if ArchiTotem_IsTalentAPIReady() then
                ArchiTotem_TalentsRetryActive = false
                ArchiTotem_TalentsInitPending = false
                ArchiTotem_UpdateTalents()
                ArchiTotem_PrintTotemicMasteryStatus()
            elseif GetTime() >= (ArchiTotem_TalentsRetryDeadline or 0) then
                ArchiTotem_TalentsRetryActive = false
                ArchiTotem_TalentsInitPending = false
                ArchiTotem_UpdateTalents()
                ArchiTotem_PrintTotemicMasteryStatus()
            end
        end

        -- 原有图腾持续时间更新
        for k, v in ArchiTotemActiveTotem do
            local baseDuration = v.duration or 0
            local bonus = ArchiTotem_TotemicMasteryBonus or 0
            local effectiveDuration = baseDuration > 0 and (baseDuration * (1 + bonus)) or baseDuration
            local timeLeft = (v.casted or 0) + effectiveDuration - GetTime()
            if timeLeft <= 0 then
                ArchiTotemActiveTotem[k] = nil
                _G[k .. "DurationText"]:Hide()
            else
                local minutes = math.floor(timeLeft / 60)
                local seconds = math.floor(timeLeft - (minutes * 60))
                _G[k .. "DurationText"]:Show()
                local secondsStr = tostring(seconds)
                if seconds < 10 then secondsStr = "0" .. secondsStr end
                _G[k .. "DurationText"]:SetText(tostring(minutes) .. ":" .. secondsStr)
            end
        end

        -- 原有冷却计时器
        for k, v in ArchiTotem_TotemData do
            if ArchiTotem_Options["Apperance"].shownumericcooldowns == true then
                if v.cooldownstarted == nil then
                    -- 无冷却
                else
                    if GetTime() > (v.cooldownstarted + v.cooldown) then
                        _G[k .. "CooldownText"]:Hide()
                        _G[k .. "CooldownBg"]:Hide()
                        v.cooldownstarted = nil
                        if k == "ArchiTotemButton_Recall" then
                            local buttonText = _G["RecallButtonText"]
                            if buttonText then buttonText:Show() end
                        end
                    else
                        _G[k .. "CooldownBg"]:Show()
                        _G[k .. "CooldownText"]:Show()
                        local totalSeconds = (v.cooldown + (v.cooldownstarted - GetTime()))
                        local minutes = math.floor(totalSeconds / 60)
                        local seconds = math.floor(totalSeconds - (minutes * 60))
                        if minutes > 0 then
                            local secondsStr = tostring(seconds)
                            if seconds < 10 then secondsStr = "0" .. tostring(seconds) end
                            _G[k .. "CooldownText"]:SetText(tostring(minutes) .. ":" .. secondsStr)
                        else
                            _G[k .. "CooldownText"]:SetText(tostring(seconds))
                        end
                        if k == "ArchiTotemButton_Recall" then
                            local buttonText = _G["RecallButtonText"]
                            if buttonText then buttonText:Hide() end
                        end
                    end
                end
            end
        end

        -- 召唤单位确认检查
        ArchiTotem_CheckSummonedUnits()
        -- 图腾覆盖文本更新
        ArchiTotem_UpdateTotemCoverage()
        this.TimeSinceLastUpdate = 0
    end
end

-- 拖拽手柄相关函数（与之前相同）
function ArchiTotem_DragHandle_OnLoad()
    ArchiTotem_UpdateDragHandleVisibility()
    if ArchiTotem_Options and ArchiTotem_Options["Debug"] then
        local dragHandle = getglobal("ArchiTotemDragHandle")
        if dragHandle then
            ArchiTotem_Print("[DEBUG] 拖拽手柄已加载", "debug")
        else
            ArchiTotem_Print("错误：无法找到拖拽手柄对象", "error")
        end
    end
end

function ArchiTotem_DragHandle_OnDragStart()
    local mainFrame = getglobal("ArchiTotemFrame")
    if mainFrame then mainFrame:StartMoving() end
end

function ArchiTotem_DragHandle_OnDragStop()
    local mainFrame = getglobal("ArchiTotemFrame")
    if mainFrame then
        mainFrame:StopMovingOrSizing()
        ArchiTotem_SaveFramePosition()
    end
end

function ArchiTotem_DragHandle_OnClick(button)
    if button == "RightButton" then
        ArchiTotem_ToggleLock()
    elseif button == "LeftButton" and IsShiftKeyDown() then
        ArchiTotem_ResetFramePosition()
    end
end

function ArchiTotem_DragHandle_OnEnter()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("ArchiTotem 拖拽手柄", 1, 1, 1)
    GameTooltip:AddLine("拖拽移动整个界面", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Shift+左键: 重置位置", 0.8, 0.8, 0.8)
    if ArchiTotem_Options and ArchiTotem_Options.locked then
        GameTooltip:AddLine("状态: 已锁定", 1, 0.2, 0.2)
    else
        GameTooltip:AddLine("状态: 未锁定", 0.2, 1, 0.2)
    end
    GameTooltip:Show()
end

function ArchiTotem_UpdateDragHandleVisibility()
    local dragHandle = getglobal("ArchiTotemDragHandle")
    if not ArchiTotem_Options then return end
    if not dragHandle then
        ArchiTotem_Print("错误：无法找到拖拽手柄对象", "error")
        return
    end
    if ArchiTotem_Options.locked then
        dragHandle:Hide()
    else
        dragHandle:Show()
    end
end

function ArchiTotem_ToggleLock()
    if not ArchiTotem_Options then return end
    ArchiTotem_Options.locked = not ArchiTotem_Options.locked
    ArchiTotem_UpdateDragHandleVisibility()
    if ArchiTotem_Options.locked then
        ArchiTotem_Print("图腾界面已锁定，拖拽手柄已隐藏")
    else
        ArchiTotem_Print("图腾界面已解锁，拖拽手柄已显示")
    end
end

function ArchiTotem_SaveFramePosition()
    local mainFrame = getglobal("ArchiTotemFrame")
    if not ArchiTotem_Options or not mainFrame then return end
    local point, _, relativePoint, xOfs, yOfs = mainFrame:GetPoint()
    ArchiTotem_Options.framePosition = {
        point = point,
        relativePoint = relativePoint,
        xOffset = xOfs,
        yOffset = yOfs
    }
end

function ArchiTotem_LoadFramePosition()
    local mainFrame = getglobal("ArchiTotemFrame")
    if not ArchiTotem_Options or not ArchiTotem_Options.framePosition or not mainFrame then return end
    local pos = ArchiTotem_Options.framePosition
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOffset, pos.yOffset)
end

function ArchiTotem_ResetFramePosition()
    local mainFrame = getglobal("ArchiTotemFrame")
    if not mainFrame then return end
    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    ArchiTotem_SaveFramePosition()
    ArchiTotem_Print("图腾界面位置已重置到屏幕中央")
end

function ArchiTotem_TestDragHandle()
    local dragHandle = getglobal("ArchiTotemDragHandle")
    ArchiTotem_Print("=== 拖拽手柄调试信息 ===")
    if dragHandle then
        ArchiTotem_Print("拖拽手柄对象存在")
        ArchiTotem_Print("当前可见状态: " .. tostring(dragHandle:IsVisible()))
        ArchiTotem_Print("当前显示状态: " .. tostring(dragHandle:IsShown()))
        dragHandle:Show()
        ArchiTotem_Print("已强制显示拖拽手柄")
        local point, _, relativePoint, x, y = dragHandle:GetPoint()
        if point then
            ArchiTotem_Print("位置: " .. point .. " -> " .. relativePoint .. " (" .. x .. ", " .. y .. ")")
        else
            ArchiTotem_Print("无法获取位置信息")
        end
    else
        ArchiTotem_Print("错误：拖拽手柄对象不存在", "error")
    end
    if ArchiTotem_Options then
        ArchiTotem_Print("锁定状态: " .. tostring(ArchiTotem_Options.locked))
    else
        ArchiTotem_Print("ArchiTotem_Options 不存在")
    end
    ArchiTotem_Print("=== 调试信息结束 ===")
end

-- 确保在方向改变时也更新覆盖文本位置
local origSetDirection = ArchiTotem_SetDirection
function ArchiTotem_SetDirection(dir)
    origSetDirection(dir)
    ArchiTotem_UpdateCoverageTextPositions()
end

-- 将各元素第一个图腾的名称存入选项（用于下次登录恢复）
function ArchiTotem_UpdateCurrentTotemsOption()
    if ArchiTotem_IsRestoring then return end
    if not ArchiTotem_Options["CurrentTotems"] then
        ArchiTotem_Options["CurrentTotems"] = {}
    end
    for _, element in ipairs(ArchiTotem_TotemElements) do
        local buttonName = "ArchiTotemButton_" .. element .. "1"
        if ArchiTotem_TotemData[buttonName] then
            ArchiTotem_Options["CurrentTotems"][element] = ArchiTotem_TotemData[buttonName].name
        end
    end
end

-- 根据保存的选项恢复各元素的首选图腾
function ArchiTotem_RestoreCurrentTotems()
    local current = ArchiTotem_Options["CurrentTotems"]
    if not current then return end

    ArchiTotem_IsRestoring = true
    for element, targetName in pairs(current) do
        local threeLetter = string.sub(element, 1, 3)
        local maxTotems = ArchiTotem_Options[threeLetter].max
        local targetPos = nil
        for i = 1, maxTotems do
            local btn = "ArchiTotemButton_" .. element .. i
            if ArchiTotem_TotemData[btn] and ArchiTotem_TotemData[btn].name == targetName then
                targetPos = i
                break
            end
        end
        if targetPos and targetPos > 1 then
            local firstBtn = "ArchiTotemButton_" .. element .. "1"
            local targetBtn = "ArchiTotemButton_" .. element .. targetPos
            ArchiTotem_Switch(firstBtn, targetBtn)
        end
    end
    ArchiTotem_IsRestoring = false
    ArchiTotem_UpdateCurrentTotemsOption()
end