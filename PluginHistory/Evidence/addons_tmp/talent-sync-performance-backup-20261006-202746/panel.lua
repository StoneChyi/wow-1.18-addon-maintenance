-- BCS_PropertiesPanel.lua
-- 属性悬浮窗模块，集成到 BetterCharacterStats

local ADDON_NAME = "BetterCharacterStats"
local P = BCS.PropertiesPanel or {}
BCS.PropertiesPanel = P

-- 默认配置（包含位置、开关、对齐方式和锁定状态；displayConfig 按职业单独设定）
local DEFAULT_CONFIG = {
    point = "CENTER",
    rel_point = "CENTER",
    x_offset = 350,
    y_offset = -100,
    enabled = true,          -- 悬浮窗默认显示
    align = "LEFT",          -- 对齐方式：LEFT/CENTER/RIGHT
    locked = false,          -- 是否锁定（锁定后点击穿透，不可拖动）
    rowsPerColumn = 0,       -- 0 为自动单列；标题不计入明细行数
    scale = 1,
    titleFontSize = 16,
    detailFontSize = 13,
    lineGap = 3,
    columnWidth = 140,
    colorMode = "label",    -- label / whole / off
    characterPanelEnabled = true, -- 是否在角色面板（按 C）中显示 BCS 属性；关闭后按 C 只显示暴雪原生面板
}

-- 根据职业返回悬浮窗默认显示配置
-- 战士/骑士/盗贼/死骑 → 物理；猎人 → 猎人(远程)；牧师/萨满/德鲁伊 → 治疗；法师/术士 → 法系
local function GetDefaultDisplayConfig()
    local _, class = UnitClass("player")
    if class == "WARRIOR" or class == "PALADIN" or class == "ROGUE" or class == "DEATHKNIGHT" then
        return "物理"
    elseif class == "HUNTER" then
        return "猎人"
    elseif class == "PRIEST" or class == "SHAMAN" or class == "DRUID" then
        return "治疗"
    elseif class == "MAGE" or class == "WARLOCK" then
        return "法系"
    else
        return "防御"
    end
end

-- ===== 属性注册表 =====
-- 编辑器、预设与聊天共用定义；每个配置分别保存显示顺序和大字标题。
-- get 为取值函数，运行期才调用（此时下方各 Display* 函数均已定义）。
local PROPERTY_LIST = {
    -- 物理
    { key = "ap",       label = "攻强",     get = function(self) return self:DisplayAP() end },
    { key = "rap",      label = "远程攻强", get = function(self) return self:DisplayRAP() end },
    { key = "hit",      label = "命中",     get = function(self) return self:DisplayHitRating() end },
    { key = "rhit",     label = "远程命中", get = function(self) return self:DisplayRangedHitRating() end },
    { key = "crit",     label = "暴击",     get = function(self) return self:DisplayPhysicalCrit() end },
    { key = "rcrit",    label = "远程暴击", get = function(self) return self:DisplayRangedCritChance() end },
    { key = "arpen",    label = "破甲",     get = function(self) return self:DisplayArmorPenetration() end },
    { key = "apspeed",  label = "双持攻速", get = function(self) return self:DisplayDualAttackSpeed() end },
    { key = "spd",      label = "攻速",     get = function(self) return self:DisplayAttackSpeed() end },
    -- 法系 / 治疗
    { key = "sp",       label = "法强",     get = function(self) return self:DisplaySP() end },
    { key = "heal",     label = "治疗",     get = function(self) return self:DisplayHealingPower() end },
    { key = "shit",     label = "法命",     get = function(self) return self:DisplaySpellHitRating() end },
    { key = "scrit",    label = "法暴",     get = function(self) return self:DisplaySpellCrit() end },
    { key = "regen",    label = "回蓝",     get = function(self) return self:DisplayManaRegen() end },
    { key = "haste",    label = "急速",     get = function(self) return self:DisplayHaste() end },
    -- 防御
    { key = "armor",    label = "护甲",     get = function(self) return self:DisplayArmor() end },
    { key = "defense",  label = "防御",     get = function(self) return self:DisplayDefense() end },
    { key = "three",    label = "三维",     get = function(self) return self:DisplayThreeDimensions() end },
    { key = "armorDR",  label = "减伤",     get = function(self) return self:DisplayArmorReduction() end },
    { key = "dodge",    label = "躲闪",     get = function(self) return self:DisplayDodge() end },
    { key = "parry",    label = "招架",     get = function(self) return self:DisplayParry() end },
    { key = "block",    label = "格挡",     get = function(self) return self:DisplayBlock() end },
    { key = "blockval", label = "格挡值",   get = function(self) return self:DisplayBlockValue() end },
    { key = "fireRes",  label = "火抗",     get = function(self) return self:DisplayResistance(2, "火抗") end },
    { key = "natureRes",label = "自然抗",   get = function(self) return self:DisplayResistance(3, "自然抗") end },
    { key = "frostRes", label = "冰抗",     get = function(self) return self:DisplayResistance(4, "冰抗") end },
    { key = "shadowRes",label = "暗抗",     get = function(self) return self:DisplayResistance(5, "暗抗") end },
    { key = "arcaneRes",label = "奥抗",     get = function(self) return self:DisplayResistance(6, "奥抗") end },
    -- 其他
    { key = "score",    label = "装等",     get = function(self) return self:GetItemScore() end },
    { key = "speed",    label = "移速",     get = function(self) return self:DisplaySpeed() end },
}

-- 各预设对应的属性 key 列表（与旧版硬编码顺序、内容完全一致）
local PRESET_KEYS = {
    ["物理"] = {"ap", "hit", "crit", "arpen", "apspeed"},
    ["法系"] = {"sp", "shit", "scrit", "regen", "haste"},
    ["治疗"] = {"heal", "sp", "scrit", "regen", "haste"},
    ["猎人"] = {"rap", "sp", "rhit", "rcrit", "arpen", "spd"},
    ["混伤"] = {"ap", "sp", "hit", "crit", "arpen", "apspeed"},
    ["防御"] = {"three", "armor", "armorDR", "defense", "dodge", "parry", "block"},
}

-- 统计数组长度（兼容 Lua 5.0/5.1：不使用 # 运算符，也不用 table.getn）
local function ArrayCount(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

local PROPERTY_BY_KEY = {}
local PROPERTY_COLORS = {
    ap="F6B66D", rap="F6B66D", arpen="F6B66D", speed="F6B66D",
    hit="7ED6C4", rhit="7ED6C4", shit="7ED6C4",
    crit="FF8A70", rcrit="FF8A70", scrit="FF8A70", parry="FF8A70",
    apspeed="6BAEFF", spd="6BAEFF", haste="6BAEFF", dodge="6BAEFF",
    sp="C9A0FF", heal="8FE0A3", regen="8FE0A3",
    armor="B6BBC7", armorDR="B6BBC7", defense="A5B4FC", three="FFD36B",
    block="D8B07C", blockval="D8B07C", score="B6BBC7",
    fireRes="FF8A70", natureRes="8FE0A3", frostRes="6BAEFF",
    shadowRes="C9A0FF", arcaneRes="D8A7E8",
}
for i = 1, ArrayCount(PROPERTY_LIST) do
    PROPERTY_BY_KEY[PROPERTY_LIST[i].key] = PROPERTY_LIST[i]
end

local INFINITY = math.huge or (1 / 0) -- Lua 5.0 的 math 库可能没有 huge 常量
local function IsFiniteNumber(value)
    return type(value) == "number" and value == value
        and value ~= INFINITY and value ~= -INFINITY
end

local function ReadNumber(fn, arg1, arg2)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, arg1, arg2)
    if ok and IsFiniteNumber(value) then return value end
    return nil
end

local function PanelConfig()
    BCSConfig = BCSConfig or {}
    BCSConfig.PropertiesPanel = BCSConfig.PropertiesPanel or {}
    return BCSConfig.PropertiesPanel
end

local function Append(list, value)
    list[ArrayCount(list) + 1] = value
end

-- 各预设有独立的勾选表、顺序及标题；旧 customProps 只迁移到「自定义」。
function P:EnsureProfile(name)
    local panel = PanelConfig()
    name = name or self.displayConfig or GetDefaultDisplayConfig()
    if type(panel.profiles) ~= "table" then panel.profiles = {} end
    local profile = panel.profiles[name]
    if type(profile) ~= "table" then profile = nil end
    if not profile then
        profile = { props = {}, order = {}, titleKey = "auto" }
        if name == "自定义" and type(panel.customProps) == "table" then
            for i = 1, ArrayCount(PROPERTY_LIST) do
                local key = PROPERTY_LIST[i].key
                local selected = panel.customProps[key] == true
                if key == "speed" then selected = panel.customProps.speed ~= false end
                if selected then
                    profile.props[key] = true
                    Append(profile.order, key)
                end
            end
        else
            local seed = PRESET_KEYS[name]
            if not seed and name == "自定义" and PRESET_KEYS[self.displayConfig] then
                local source = self:EnsureProfile(self.displayConfig)
                for i = 1, ArrayCount(source.order) do
                    local key = source.order[i]
                    if source.props[key] then
                        profile.props[key] = true
                        Append(profile.order, key)
                    end
                end
                profile.titleKey = source.titleKey
            else
                seed = seed or PRESET_KEYS[GetDefaultDisplayConfig()]
                for i = 1, ArrayCount(seed) do
                    profile.props[seed[i]] = true
                    Append(profile.order, seed[i])
                end
                profile.props.speed = true
                Append(profile.order, "speed")
                if name == "防御" then profile.titleKey = "three" end
            end
        end
        panel.profiles[name] = profile
    end
    if type(profile.props) ~= "table" then profile.props = {} end
    if type(profile.order) ~= "table" then profile.order = {} end
    if type(profile.titleKey) ~= "string" then profile.titleKey = "auto" end
    -- 丢弃重复/未知顺序项，补回已勾选但缺少顺序的项。
    local order, seen = {}, {}
    for i = 1, ArrayCount(profile.order) do
        local key = profile.order[i]
        if PROPERTY_BY_KEY[key] and not seen[key] then
            Append(order, key)
            seen[key] = true
        end
    end
    for i = 1, ArrayCount(PROPERTY_LIST) do
        local key = PROPERTY_LIST[i].key
        if profile.props[key] and not seen[key] then Append(order, key) end
    end
    profile.order = order
    if profile.titleKey ~= "auto" and (not PROPERTY_BY_KEY[profile.titleKey] or not profile.props[profile.titleKey]) then
        profile.titleKey = "auto"
    end
    if name == "自定义" then
        local legacy = {}
        for key, selected in pairs(profile.props) do legacy[key] = selected end
        legacy.speed = profile.props.speed == true
        panel.customProps = legacy
    end
    return profile
end

function P:EnsureCustomProps()
    return self:EnsureProfile().props
end

function P:GetSelectedKeys()
    local profile, keys = self:EnsureProfile(), {}
    for i = 1, ArrayCount(profile.order) do
        local key = profile.order[i]
        if profile.props[key] then Append(keys, key) end
    end
    return keys
end

function P:GetTitleKey()
    local profile = self:EnsureProfile()
    if profile.titleKey ~= "auto" and profile.props[profile.titleKey] then
        return profile.titleKey
    end
    return self:GetSelectedKeys()[1]
end

function P:IsSpeedShown()
    return self:EnsureProfile().props.speed == true
end

function P:FormatPropertyText(key, text)
    if self.colorMode == "off" then return text end
    local color = PROPERTY_COLORS[key] or "FFFFFF"
    if string.find(text, "数据不可用", 1, true) or string.find(text, "获取失败", 1, true) then
        return "|cFFBBBBBB" .. text .. "|r"
    end
    if self.colorMode == "whole" then return "|cFF" .. color .. text .. "|r" end
    local colon = string.find(text, ":", 1, true)
    if not colon then return "|cFF" .. color .. text .. "|r" end
    return "|cFF" .. color .. string.sub(text, 1, colon) .. "|r|cFFFFFFFF"
        .. string.sub(text, colon + 1) .. "|r"
end

-- 按 key 取显示串；取值失败时回退为「标签: 数据不可用」，避免自定义模式下整行丢失
function P:GetPropertyText(key)
    local item = PROPERTY_BY_KEY[key]
    if not item then return nil end
    local ok, text = pcall(item.get, self)
    if ok and type(text) == "string" then return text end
    return item.label .. ": 数据不可用"
end

-- 悬浮窗框架
P.frame = CreateFrame("Frame", nil, UIParent)
P.frame:SetMovable(true)
P.frame:EnableMouse(true)
P.frame:SetWidth(140)
P.frame:SetHeight(110)
P.frame:SetAlpha(.90)
P.frame:SetPoint("CENTER", 350, -100)
P.frame:SetFrameStrata("LOW")
if P.frame.SetClampedToScreen then P.frame:SetClampedToScreen(true) end

-- 标题行（第一行，大字体）
P.frame.title = P.frame:CreateFontString(nil, "ARTWORK")
P.frame.title:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")

-- 详细信息行（其余行，小字体）
P.frame.details = P.frame:CreateFontString(nil, "ARTWORK")
P.frame.details:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")

P.frame:RegisterForDrag("LeftButton")
function P:SaveCenterPosition(snap)
    local frame = self.frame
    local point, _, relPoint, x, y = frame:GetPoint()
    local cx, cy, ux, uy
    if frame.GetCenter and UIParent.GetCenter then
        cx, cy = frame:GetCenter()
        ux, uy = UIParent:GetCenter()
    end
    local centered = cx and cy and ux and uy
    if centered then
        local frameScale = frame.GetEffectiveScale and frame:GetEffectiveScale() or 1
        local parentScale = UIParent.GetEffectiveScale and UIParent:GetEffectiveScale() or 1
        x, y = cx - ux * parentScale / frameScale, cy - uy * parentScale / frameScale
        point, relPoint = "CENTER", "CENTER"
    end
    if not point or not x or not y then return false end
    if snap and x < 20 and x > -20 then x = 0 end
    local panel = PanelConfig()
    panel.point, panel.rel_point = point, relPoint
    panel.x_offset = math.floor(x * 100 + 0.5) / 100
    panel.y_offset = math.floor(y * 100 + 0.5) / 100
    if centered then
        self.pendingCenter = {x=panel.x_offset, y=panel.y_offset}
        self.centerAfterLayout = false
    else self.centerAfterLayout = true end
    return centered and true or false
end

function P:ApplyCenterPosition()
    if not self.pendingCenter or self.dragging then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", self.pendingCenter.x, self.pendingCenter.y)
    self.pendingCenter = nil
end

P.frame:SetScript("OnDragStart", function()
    if P.locked then return end  -- 锁定时禁止拖动
    P.dragging = true
    P.frame:StartMoving()
end)
P.frame:SetScript("OnDragStop", function()
    P.frame:StopMovingOrSizing()
    P.dragging = false
    if P.locked then return end
    -- Save the center now; reanchor on the next display refresh, outside
    -- the native drag-stop callback and before any size changes.
    P:SaveCenterPosition(true)
end)

P.frame:Hide()

-- 定时器（用于实时移速刷新）
P.speedUpdater = nil

-- ===== 刷新节流 =====
-- 悬浮窗由 0.2 秒的定时器驱动，但「重建属性内容」会触发 BCS 的重量级扫描
-- （逐件装备扫 tooltip），不能每 0.2 秒跑一次。策略：
--   1) 属性内容只在「被标记为脏」或「超过最大间隔」时重建；
--   2) 重建之间至少间隔 MIN_BODY_REFRESH 秒，吸收事件风暴（如战斗中光环频繁变化）；
--   3) 每次刷新都重新拼移速行（UnitXP 单次调用，开销可忽略）。
local FAST_TICK         = 0.2   -- 移速行刷新频率（秒）
local MIN_BODY_REFRESH  = 1     -- 属性内容重建的最小间隔（秒）
local MAX_BODY_REFRESH  = 5     -- 属性内容重建的强制间隔（秒），兜底防止漏事件导致数据陈旧

P.lastBodyRefresh = 0     -- 上次重建时间（GetTime）
P.bodyDirty       = true  -- 内容是否需要重建
P.forceNextBuild  = true  -- 下次刷新无条件重建（用户主动操作时置位）
P.bodyFirstLine   = nil   -- 缓存的第一行（标题/主属性）
P.bodyRestLines   = nil   -- 缓存的其余行（不含移速行）
P.appliedAlign    = false -- 已应用的排版对齐方式（false = 尚未排版），用于避免每帧重设锚点
P.lastFirstLine   = nil   -- 上次写入的标题，用于避免无变化的 SetText
P.lastRestLines   = nil   -- 上次写入的明细，用于避免无变化的 SetText

-- 标记内容为「需要重建」：下一次刷新时（受最小间隔约束）重算
function P:MarkDirty()
    self.bodyDirty = true
end

-- 立即重建并刷新一次显示：用于用户主动操作（切换配置/对齐/锁定、/mb 命令），不受节流限制
function P:RefreshNow()
    self.bodyDirty = true
    self.forceNextBuild = true
    if self.showWindow then
        local firstLine, restLines = self:GetDisplayLines()
        self:UpdateDisplay(1, firstLine, restLines)
    end
end

-- 主配置窗口
P.mainFrame = CreateFrame("Frame", "BCSPropertiesPanelMainFrame", UIParent)
P.mainFrame:SetWidth(450)
P.mainFrame:SetHeight(360)
P.mainFrame:SetPoint("CENTER", 0, 0)
P.mainFrame:EnableMouse(true)
P.mainFrame:SetMovable(true)
P.mainFrame:RegisterForDrag("LeftButton")
P.mainFrame:SetScript("OnDragStart", function() P.mainFrame:StartMoving() end)
P.mainFrame:SetScript("OnDragStop", function() P.mainFrame:StopMovingOrSizing() end)

P.mainFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
})
P.mainFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
P.mainFrame:SetBackdropBorderColor(0.5, 0.5, 0.5)

local titleBg = P.mainFrame:CreateTexture(nil, "OVERLAY")
titleBg:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
titleBg:SetPoint("TOPLEFT", 4, -4)
titleBg:SetPoint("TOPRIGHT", -4, -4)
titleBg:SetHeight(24)
titleBg:SetVertexColor(0.2, 0.2, 0.2, 1)

local titleText = P.mainFrame:CreateFontString(nil, "OVERLAY")
titleText:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
titleText:SetPoint("TOP", 0, -5)
titleText:SetText("属性面板")

local closeButton = CreateFrame("Button", nil, P.mainFrame)
closeButton:SetPoint("TOPRIGHT", -8, -8)
closeButton:SetWidth(16)
closeButton:SetHeight(16)

local closeTexture = closeButton:CreateTexture()
closeTexture:SetAllPoints()
closeTexture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")

closeButton:SetScript("OnClick", function() P.mainFrame:Hide() end)
closeButton:SetScript("OnEnter", function() closeTexture:SetVertexColor(1, 0, 0) end)
closeButton:SetScript("OnLeave", function() closeTexture:SetVertexColor(1, 1, 1) end)

-- 帮助按钮
local helpButton = CreateFrame("Button", nil, P.mainFrame)
helpButton:SetPoint("RIGHT", closeButton, "LEFT", -5, 0)
helpButton:SetWidth(16)
helpButton:SetHeight(16)

helpButton:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
})
helpButton:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
helpButton:SetBackdropBorderColor(0, 0, 0, 1)

local helpText = helpButton:CreateFontString(nil, "OVERLAY")
helpText:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
helpText:SetPoint("CENTER", 0, 0)
helpText:SetText("?")
helpText:SetTextColor(1, 0.82, 0)

helpButton:SetScript("OnClick", function()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开设置，编辑当前预设可增减属性/设置标题/排序；/mb custom 打开独立自定义，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 1, 1)
end)

helpButton:SetScript("OnEnter", function()
    helpButton:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    helpText:SetTextColor(1, 1, 1)
end)
helpButton:SetScript("OnLeave", function()
    helpButton:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    helpText:SetTextColor(1, 0.82, 0)
end)

-- 「角色面板」开关（放在 ? 左边）
-- 关闭后：按 C 只显示暴雪原生角色面板，BCS 不再向角色面板写入内容，属性只在浮动窗显示。
P.characterPanelEnabled = true
local charPanelButton = CreateFrame("Button", nil, P.mainFrame)
charPanelButton:SetPoint("RIGHT", helpButton, "LEFT", -5, 0)
charPanelButton:SetWidth(62)
charPanelButton:SetHeight(16)

charPanelButton:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
})
charPanelButton:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
charPanelButton:SetBackdropBorderColor(0, 0, 0, 1)

local charPanelText = charPanelButton:CreateFontString(nil, "OVERLAY")
charPanelText:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
charPanelText:SetPoint("CENTER", 0, 0)
charPanelText:SetText("角色面板")
charPanelText:SetTextColor(1, 0.82, 0)
charPanelButton.label = charPanelText
P.characterPanelButton = charPanelButton

charPanelButton:SetScript("OnClick", function()
    if P.characterPanelEnabled == false then
        P:SetCharacterPanelEnabled(true)
    else
        P:SetCharacterPanelEnabled(false)
    end
end)

charPanelButton:SetScript("OnEnter", function()
    charPanelButton:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    GameTooltip:SetOwner(charPanelButton, "ANCHOR_RIGHT")
    GameTooltip:SetText("角色面板属性", 1, 1, 1)
    if P.characterPanelEnabled == false then
        GameTooltip:AddLine("当前：关闭", 0.6, 0.6, 0.6, 1)
        GameTooltip:AddLine("按 C 只显示暴雪原生角色面板，", 0.8, 0.8, 0.8, 1)
        GameTooltip:AddLine("BCS 属性只在浮动窗中显示。", 0.8, 0.8, 0.8, 1)
        GameTooltip:AddLine("点击以恢复在角色面板中显示。", 1, 1, 0, 1)
    else
        GameTooltip:AddLine("当前：开启", 1, 0.82, 0, 1)
        GameTooltip:AddLine("按 C 时会把 BCS 属性写入角色面板。", 0.8, 0.8, 0.8, 1)
        GameTooltip:AddLine("点击关闭后，按 C 只显示原生面板，", 0.8, 0.8, 0.8, 1)
        GameTooltip:AddLine("属性只在浮动窗中显示。", 0.8, 0.8, 0.8, 1)
    end
    GameTooltip:Show()
end)

charPanelButton:SetScript("OnLeave", function()
    charPanelButton:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    GameTooltip:Hide()
end)

-- 同步「角色面板」按钮外观（金色 = 开启，灰色 = 关闭）
function P:SyncCharacterPanelButton()
    local btn = self.characterPanelButton
    if not btn or not btn.label then return end
    if self.characterPanelEnabled == false then
        btn.label:SetTextColor(0.45, 0.45, 0.45)
    else
        btn.label:SetTextColor(1, 0.82, 0)
    end
end

-- 设置「在角色面板中显示 BCS 属性」，并立即作用于角色面板
function P:SetCharacterPanelEnabled(enabled)
    enabled = enabled and true or false
    self.characterPanelEnabled = enabled

    BCSConfig = BCSConfig or {}
    if not BCSConfig.PropertiesPanel then
        BCSConfig.PropertiesPanel = {}
    end
    BCSConfig.PropertiesPanel.characterPanelEnabled = enabled

    if BCS and BCS.ApplyCharacterPanelState then
        BCS:ApplyCharacterPanelState()
    end
    self:SyncCharacterPanelButton()

    if enabled then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 角色面板显示已开启（按 C 显示 BCS 属性）", 1, 1, 1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 角色面板显示已关闭（按 C 只显示原生面板，属性仅在浮动窗）", 1, 1, 1)
    end
end

-- 创建按钮的辅助函数
local function CreateButton(text, parent, point, relativePoint, x, y, onClick)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(60)
    button:SetHeight(22)
    button:SetPoint(point, relativePoint, x, y)

    button:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        tile = true,
        tileSize = 16,
    })
    button:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    button:SetBackdropBorderColor(0, 0, 0, 1)

    local label = button:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, 12)
    label:SetPoint("CENTER", 0, 0)
    label:SetText(text)
    label:SetTextColor(1, 0.82, 0)
    button.label = label

    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function()
        button:SetBackdropColor(0.15, 0.15, 0.15, 0.9)
    end)
    button:SetScript("OnLeave", function()
        button:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
    end)
    button:SetScript("OnMouseDown", function()
        label:SetPoint("CENTER", 1, -1)
    end)
    button:SetScript("OnMouseUp", function()
        label:SetPoint("CENTER", 0, 0)
    end)

    return button
end

local APPEARANCE_LIMITS = {
    rowsPerColumn={0, 30}, scale={0.75, 1.5}, titleFontSize={12, 24},
    detailFontSize={10, 20}, lineGap={0, 12}, columnWidth={100, 240},
}

function P:LoadAppearance()
    local panel = PanelConfig()
    for key, limits in pairs(APPEARANCE_LIMITS) do
        local value = tonumber(panel[key])
        if not IsFiniteNumber(value) then value = DEFAULT_CONFIG[key] end
        value = math.max(limits[1], math.min(limits[2], value))
        if key ~= "scale" then value = math.floor(value + 0.5) end
        panel[key], self[key] = value, value
    end
    local mode = panel.colorMode
    if mode ~= "label" and mode ~= "whole" and mode ~= "off" then mode = "label" end
    panel.colorMode, self.colorMode = mode, mode
    self.layoutDirty = true
end

function P:SetPanelOption(key, value)
    PanelConfig()[key] = value
    self:LoadAppearance()
    self:SyncSettingsControls()
    self:RefreshNow()
end

function P:SetLocked(locked, announce)
    if self.dragging then
        self.frame:StopMovingOrSizing()
        self.dragging = false
        self:SaveCenterPosition()
    end
    self.locked = locked == true
    PanelConfig().locked = self.locked
    self.frame:EnableMouse(not self.locked)
    self:SyncSettingsControls()
    if announce then
        local message = self.locked and "悬浮窗已锁定，点击穿透开启" or "悬浮窗已解锁，可拖动"
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r " .. message, 1, 1, 1)
    end
end

P.editPresetButton = CreateButton("编辑当前预设", P.mainFrame, "TOP", P.mainFrame, -145, -78,
    function() P:ShowCustomWindow(not P.customFrame:IsShown()) end)
P.editPresetButton:SetWidth(106)
P.lockButton = CreateButton("锁定", P.mainFrame, "TOP", P.mainFrame, -43, -78,
    function() P:SetLocked(true, true) end)
P.unlockButton = CreateButton("解锁", P.mainFrame, "TOP", P.mainFrame, 29, -78,
    function() P:SetLocked(false, true) end)
P.appearanceResetButton = CreateButton("恢复外观", P.mainFrame, "TOP", P.mainFrame, 134, -78,
    function()
        local panel = PanelConfig()
        for key in pairs(APPEARANCE_LIMITS) do
            panel[key] = DEFAULT_CONFIG[key]
        end
        panel.colorMode = DEFAULT_CONFIG.colorMode
        P:LoadAppearance()
        P:SyncSettingsControls()
        P:RefreshNow()
    end)
P.appearanceResetButton:SetWidth(92)

local COLOR_MODES = {"label", "whole", "off"}
local COLOR_LABELS = { label="属性名染色", whole="整行染色", off="关闭染色" }
P.colorModeButton = CreateButton("属性名染色", P.mainFrame, "TOP", P.mainFrame, -92, -112,
    function()
        local nextMode = "label"
        for i = 1, 3 do
            if COLOR_MODES[i] == P.colorMode then nextMode = COLOR_MODES[(i == 3) and 1 or (i + 1)] end
        end
        P:SetPanelOption("colorMode", nextMode)
    end)
P.colorModeButton:SetWidth(130)
P.alignButton = CreateButton("左对齐", P.mainFrame, "TOP", P.mainFrame, 82, -112,
    function()
        if P.align == "LEFT" then P.align = "CENTER"
        elseif P.align == "CENTER" then P.align = "RIGHT"
        else P.align = "LEFT" end
        PanelConfig().align = P.align
        P:SyncSettingsControls()
        P:RefreshNow()
    end)
P.alignButton:SetWidth(108)

P.optionSliders = {}
local function CreateOptionSlider(key, label, low, high, step, x, y, multiplier)
    local name = "BCSPropertiesOption" .. key
    local slider = CreateFrame("Slider", name, P.mainFrame, "OptionsSliderTemplate")
    slider:SetWidth(174)
    slider:SetHeight(16)
    slider:SetPoint("TOPLEFT", P.mainFrame, "TOPLEFT", x, y)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    local text = getglobal(name .. "Text")
    if getglobal(name .. "Low") then getglobal(name .. "Low"):SetText("") end
    if getglobal(name .. "High") then getglobal(name .. "High"):SetText("") end
    slider.caption, slider.optionLabel, slider.multiplier = text, label, multiplier or 1
    slider:SetScript("OnValueChanged", function()
        local value = math.floor(slider:GetValue() / step + 0.5) * step
        local suffix = key == "scale" and "%" or ""
        local shown = (key == "rowsPerColumn" and value == 0) and "自动单列" or (value .. suffix)
        if text then text:SetText(label .. ": " .. shown) end
        if P.initialized and not P.syncSettings then
            P:SetPanelOption(key, value / slider.multiplier)
        end
    end)
    P.optionSliders[key] = slider
end
CreateOptionSlider("rowsPerColumn", "每列明细行数", 0, 30, 1, 24, -163)
CreateOptionSlider("scale", "整体缩放", 75, 150, 5, 252, -163, 100)
CreateOptionSlider("titleFontSize", "标题字号", 12, 24, 1, 24, -218)
CreateOptionSlider("detailFontSize", "明细字号", 10, 20, 1, 252, -218)
CreateOptionSlider("lineGap", "行距", 0, 12, 1, 24, -273)
CreateOptionSlider("columnWidth", "列宽", 100, 240, 10, 252, -273)

local layoutHint = P.mainFrame:CreateFontString(nil, "OVERLAY")
layoutHint:SetFont(STANDARD_TEXT_FONT, 11)
layoutHint:SetPoint("TOP", 0, -305)
layoutHint:SetText("标题不计行数；超出续列，屏幕不足时自动增行")
layoutHint:SetTextColor(0.75, 0.75, 0.75)

function P:SyncSettingsControls()
    self.syncSettings = true
    for key, slider in pairs(self.optionSliders) do
        slider:SetValue((self[key] or DEFAULT_CONFIG[key]) * slider.multiplier)
    end
    self.syncSettings = false
    self.colorModeButton.label:SetText(COLOR_LABELS[self.colorMode] or COLOR_LABELS.label)
    local aligns = {LEFT="左对齐", CENTER="居中", RIGHT="右对齐"}
    self.alignButton.label:SetText(aligns[self.align] or "左对齐")
    self.lockButton.label:SetText(self.locked and "已锁定" or "锁定")
    self.unlockButton.label:SetText(self.locked and "解锁" or "已解锁")
    if self.locked then self.lockButton:Disable(); self.unlockButton:Enable()
    else self.lockButton:Enable(); self.unlockButton:Disable() end
end

P.mainFrame:SetScript("OnShow", function() if P.initialized then P:SyncSettingsControls() end end)
P.mainFrame:SetScript("OnHide", function() if P.customFrame then P.customFrame:Hide() end end)

-- 切换显示配置（预设或自定义）：统一入口，供按钮 / 命令调用
function P:SelectConfig(name, silent)
    if not PRESET_KEYS[name] and name ~= "自定义" then return false end
    -- 切到「自定义」前先固化初始勾选（以切换前的预设为准）
    if name == "自定义" then
        self:EnsureProfile("自定义")
    end

    local editorShown = self.customFrame and self.customFrame:IsShown()
    self.displayConfig = name
    if not BCSConfig.PropertiesPanel then
        BCSConfig.PropertiesPanel = {}
    end
    BCSConfig.PropertiesPanel.displayConfig = name

    -- 自定义自动打开编辑器；编辑器已打开时切换预设会同步内容。
    self:EnsureProfile(name)
    if silent then
        if editorShown then self:RefreshCustomRows() end
    else
        self:ShowCustomWindow(name == "自定义" or editorShown)
    end

    self:SyncConfigButtons()
    self:RefreshNow()
    return true
end

-- 配置选择按钮
local buttonWidth = 52
local numButtons = 7
local totalButtonWidth = buttonWidth * numButtons
local spacing = (P.mainFrame:GetWidth() - totalButtonWidth) / (numButtons + 1)

local configTypes = {"物理", "法系", "治疗", "猎人", "混伤", "防御", "自定义"}
P.configButtons = {}
for i = 1, numButtons do
    local x = -P.mainFrame:GetWidth() / 2 + spacing * i + buttonWidth * (i - 0.5)
    local buttonText = configTypes[i]

    local btn = CreateButton(buttonText, P.mainFrame, "TOP", P.mainFrame, x, -42, function()
        P:SelectConfig(buttonText)
    end)
    btn:SetWidth(buttonWidth)
    P.configButtons[i] = btn
end

-- 高亮当前生效的配置按钮
function P:SyncConfigButtons()
    if not self.configButtons then return end
    for i = 1, ArrayCount(self.configButtons) do
        local btn = self.configButtons[i]
        if btn and btn.label and configTypes[i] then
            if configTypes[i] == self.displayConfig then
                btn.label:SetTextColor(1, 1, 1)
            else
                btn.label:SetTextColor(1, 0.82, 0)
            end
        end
    end
end

-- 发送到输入框按钮
local inputButton = CreateButton("发送输入框", P.mainFrame, "BOTTOM", P.mainFrame, -80, 10, function()
    P:SendPropertiesToInput()
end)
inputButton:SetWidth(80)

-- 发送密语按钮
local whisperButton = CreateButton("发送密语", P.mainFrame, "BOTTOMRIGHT", P.mainFrame, -100, 10, function()
    P:SendPropertiesToWhisper()
end)
whisperButton:SetWidth(80)

-- 初始化位置和配置（由 ADDON_LOADED 事件调用）
function P:Init()
    -- 确保 BCSConfig.PropertiesPanel 存在
    if not BCSConfig.PropertiesPanel then
        BCSConfig.PropertiesPanel = {}
    end

    -- 合并默认配置，确保每个字段都有值（displayConfig 除外，按需按职业设定）
    local panel = BCSConfig.PropertiesPanel
    for k, v in pairs(DEFAULT_CONFIG) do
        if panel[k] == nil then
            panel[k] = v
        end
    end

    -- 首次加载（无已保存的 displayConfig）时，按职业设定默认显示配置
    if panel.displayConfig == nil then
        panel.displayConfig = GetDefaultDisplayConfig()
    end

    -- 设置悬浮窗位置
    local point = panel.point
    local rel_point = panel.rel_point
    local x = panel.x_offset
    local y = panel.y_offset
    self.frame:ClearAllPoints()
    self.frame:SetPoint(point, UIParent, rel_point, x, y)
    self.pendingCenter = nil
    -- Migrate legacy corner anchors after rendering their original preset,
    -- so adopting a center anchor does not relocate the existing window.
    self.centerAfterLayout = point ~= "CENTER" or rel_point ~= "CENTER"

    -- 设置显示配置到 P.displayConfig
    self.displayConfig = panel.displayConfig
    if not PRESET_KEYS[self.displayConfig] and self.displayConfig ~= "自定义" then
        self.displayConfig = GetDefaultDisplayConfig()
        panel.displayConfig = self.displayConfig
    end

    self:LoadAppearance()
    self:EnsureProfile()
    self.initialized = true
    self:SyncSettingsControls()

    -- 设置对齐方式
    self.align = panel.align
    if self.align ~= "LEFT" and self.align ~= "CENTER" and self.align ~= "RIGHT" then
        self.align, panel.align = "LEFT", "LEFT"
    end

    -- 设置锁定状态
    self.locked = panel.locked
    self:SetLocked(panel.locked == true)

    -- 设置显示状态
    self.showWindow = panel.enabled
    if not self.showWindow then
        self.frame:Hide()
    end

    -- 角色面板显示开关（默认开启）：同步按钮外观并把状态应用到角色面板
    self.characterPanelEnabled = (panel.characterPanelEnabled ~= false)
    self:SyncCharacterPanelButton()
    if BCS and BCS.ApplyCharacterPanelState then
        BCS:ApplyCharacterPanelState()
    end

    -- 高亮当前生效的配置按钮
    self:SyncConfigButtons()
end

-- 定时刷新移速（由定时器调用）
function P:RefreshSpeedDisplay()
    if not self.showWindow then
        -- 安全停止定时器
        if self.speedUpdater then
            self.speedUpdater:Cancel()
            self.speedUpdater = nil
        end
        return
    end
    local firstLine, restLines = self:GetDisplayLines()
    self:UpdateDisplay(1, firstLine, restLines)
end

-- 多列布局只在布局参数/行数变化时重排；移速仍走 0.2 秒节拍。
function P:UpdateDisplay(show, firstLine, restLines)
    if show ~= 1 then
        self.frame:Hide()
        if self.speedUpdater then self.speedUpdater:Cancel(); self.speedUpdater = nil end
        return
    end
    self:ApplyCenterPosition()
    local lines = {}
    local iter = string.gfind or string.gmatch
    for line in iter(restLines or "", "[^\n]+") do Append(lines, line) end
    local count = ArrayCount(lines)
    local rows = self.rowsPerColumn or 0
    if rows == 0 then rows = math.max(1, count) end
    local width = self.columnWidth or 140
    local screenWidth = UIParent:GetWidth() / (self.scale or 1)
    local maxColumns = math.max(1, math.floor((screenWidth - 8) / (width + 12)))
    rows = math.max(rows, math.ceil(count / maxColumns))
    local columns = math.max(1, math.ceil(count / rows))
    local actualRows = math.min(rows, count)
    local gap = self.lineGap or 3
    local titleSize = self.titleFontSize or 16
    local detailSize = self.detailFontSize or 13
    local signature = table.concat({self.align or "LEFT", rows, columns, actualRows,
        width, gap, titleSize, detailSize, self.scale or 1, self.colorMode or "label"}, ":")

    self.frame.columns = self.frame.columns or {self.frame.details}
    for i = 1, columns do
        if not self.frame.columns[i] then
            self.frame.columns[i] = self.frame:CreateFontString(nil, "ARTWORK")
        end
    end
    if self.layoutDirty or self.layoutSignature ~= signature then
        self.frame:SetScale(self.scale or 1)
        self.frame.title:SetFont("Fonts\\ARIALN.ttf", titleSize, "OUTLINE")
        self.frame.title:ClearAllPoints()
        self.frame.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10, -10)
        self.frame.title:SetJustifyH(self.align or "LEFT")
        local _, class = UnitClass("player")
        local color = self.colorMode == "off" and RAID_CLASS_COLORS[class]
        if color then self.frame.title:SetTextColor(color.r, color.g, color.b)
        else self.frame.title:SetTextColor(1, 1, 1) end
        self.frame:SetWidth(columns * width + (columns - 1) * 12 + 20)
        self.frame:SetHeight(titleSize + 22 + actualRows * (detailSize + gap))
        self.frame.title:SetWidth(self.frame:GetWidth() - 20)
        for i = 1, ArrayCount(self.frame.columns) do
            local text = self.frame.columns[i]
            text:SetFont("Fonts\\ARIALN.ttf", detailSize, "OUTLINE")
            text:SetTextColor(1, 1, 1)
            text:SetJustifyH(self.align or "LEFT")
            text:SetJustifyV("TOP")
            if text.SetSpacing then text:SetSpacing(gap) end
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + (i - 1) * (width + 12), -(titleSize + 18))
            text:SetWidth(width)
        end
        self.layoutSignature, self.layoutDirty = signature, false
        self.lastFirstLine, self.lastColumnTexts = nil, {}
        self.measurementDirty = true
    end
    if self.lastFirstLine ~= firstLine then
        self.frame.title:SetText(firstLine or "（未选择属性）")
        self.lastFirstLine = firstLine
        self.measurementDirty = true
    end
    self.lastColumnTexts = self.lastColumnTexts or {}
    for i = 1, ArrayCount(self.frame.columns) do
        local text = self.frame.columns[i]
        if i <= columns and count > 0 then
            local values = {}
            for j = (i - 1) * rows + 1, math.min(i * rows, count) do Append(values, lines[j]) end
            local value = table.concat(values, "\n")
            if self.lastColumnTexts[i] ~= value then
                text:SetText(value)
                self.lastColumnTexts[i] = value
                self.measurementDirty = true
            end
            text:Show()
        else text:Hide() end
    end
    -- 窄列/大字体发生换行时按实际文字高度扩展，防止底部属性被裁切。
    if self.measurementDirty then
        local titleHeight = titleSize
        if self.frame.title.GetStringHeight then
            titleHeight = math.max(titleHeight, self.frame.title:GetStringHeight() or 0)
        end
        local bodyHeight = actualRows * (detailSize + gap)
        for i = 1, columns do
            local text = self.frame.columns[i]
            if count > 0 and text.GetStringHeight then
                bodyHeight = math.max(bodyHeight, text:GetStringHeight() or 0)
            end
            text:ClearAllPoints()
            text:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 10 + (i - 1) * (width + 12), -(titleHeight + 18))
        end
        self.frame:SetHeight(titleHeight + 22 + bodyHeight)
        self.measurementDirty = false
    end
    self.frame:EnableMouse(not self.locked)
    self.frame:Show()
    if self.centerAfterLayout and not self.dragging then
        self:SaveCenterPosition()
        self:ApplyCenterPosition()
    end
    if not self.speedUpdater then
        self.speedUpdater = C_Timer.NewTicker(FAST_TICK, function() P:RefreshSpeedDisplay() end)
    end
end

-- 获取移动速度显示字符串（供聊天发送使用，总是返回字符串）
function P:DisplaySpeed()
    local speed1 = ReadNumber(UnitXP, "speed", "player")
    if speed1 then
        local percent = speed1 * 100 / 7
        return string.format("移速: %.1f%%", percent)
    else
        return "移速: 数据不可用"
    end
end

-- 一次重建内三项防御概率使用同一快照；聊天发送独立重新取值。
function P:BuildBody()
    local previousForce = BCS.ForceCalculate
    BCS.ForceCalculate = true
    self.defenseSnapshot = {
        dodge = ReadNumber(GetDodgeChance),
        parry = ReadNumber(GetParryChance),
        block = ReadNumber(GetBlockChance),
    }
    local keys = self:GetSelectedKeys()
    local entries = {}
    for i = 1, ArrayCount(keys) do
        local key = keys[i]
        -- 移速与急速实时读取，避免光环事件早于客户端数值更新时缓存旧值。
        Append(entries, {key=key, text=key ~= "speed" and key ~= "haste" and self:GetPropertyText(key) or nil})
    end
    self.defenseSnapshot = nil
    BCS.ForceCalculate = previousForce
    self.bodyEntries = entries
    self.bodyTitleKey = self:GetTitleKey()
    self.lastBodyRefresh = GetTime()
    self.bodyDirty, self.forceNextBuild = false, false
end

function P:GetDisplayLines()
    local elapsed = GetTime() - (self.lastBodyRefresh or 0)
    if not self.bodyEntries or self.forceNextBuild
        or (self.bodyDirty and elapsed >= MIN_BODY_REFRESH)
        or elapsed >= MAX_BODY_REFRESH then self:BuildBody() end
    local firstLine, rest = nil, {}
    for i = 1, ArrayCount(self.bodyEntries) do
        local entry = self.bodyEntries[i]
        local text = entry.text
        if entry.key == "speed" then text = self:DisplaySpeed()
        elseif entry.key == "haste" then text = self:DisplayHaste() end
        text = self:FormatPropertyText(entry.key, text or "数据不可用")
        if entry.key == self.bodyTitleKey then firstLine = text
        else Append(rest, text) end
    end
    return firstLine or "（未选择属性）", table.concat(rest, "\n")
end

-- 以下为原有函数，保持不变（用于聊天和内部调用）
-- 获取用于聊天的属性字符串
function P:GetPropertiesForChat()
    local playerName, playerLevel, playerClass = UnitName("player"), UnitLevel("player"), UnitClass("player")
    local itemScore = self:GetItemScore()

    -- 与悬浮窗一致：不受 C 面板当前分页影响，独立取全部所需数值
    local prevForce = BCS.ForceCalculate
    BCS.ForceCalculate = true

    -- 与悬浮窗共用同一套属性注册表：预设 / 自定义输出完全一致
    -- 装等已固定在标题里，故此处跳过 "score" 项，避免重复
    local parts = {}
    local n = 0
    local keys = self:GetSelectedKeys()
    for i = 1, ArrayCount(keys) do
        if keys[i] ~= "score" then
            local text = self:GetPropertyText(keys[i])
            if text then
                n = n + 1
                parts[n] = text
            end
        end
    end

    -- 还原按需计算开关
    BCS.ForceCalculate = prevForce

    return playerName .. " (Lv" .. playerLevel .. " " .. playerClass .. "): " .. itemScore ..
           " 当前属性 (" .. self.displayConfig .. "): " .. table.concat(parts, ", ")
end

-- 发送属性到输入框
function P:SendPropertiesToInput()
    local propertiesText = self:GetPropertiesForChat()

    local editBox = nil
    if ChatEdit_GetActiveWindow then
        editBox = ChatEdit_GetActiveWindow()
    end
    if not editBox and ChatFrame1 and ChatFrame1.editBox then
        editBox = ChatFrame1.editBox
        ChatFrame1.editBox:Show()
    end
    if not editBox then
        local frame = DEFAULT_CHAT_FRAME or ChatFrame1
        if frame then
            frame.editBox:Show()
            frame.editBox:SetFocus()
            editBox = frame.editBox
        end
    end

    if editBox then
        editBox:SetText(propertiesText)
        editBox:HighlightText()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000PropertiesPanel: 无法找到聊天输入框|r")
    end

    self.mainFrame:Hide()
end

-- 发送属性到密语
function P:SendPropertiesToWhisper()
    local propertiesText = self:GetPropertiesForChat()
    local targetName = UnitName("target")
    if targetName then
        SendChatMessage(propertiesText, "WHISPER", nil, targetName)
    else
        if WIM_EditBoxInFocus then
            WIM_EditBoxInFocus:SetText(propertiesText)
            WIM_EditBoxInFocus:HighlightText()
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000PropertiesPanel: 没有选择目标且WIM未加载|r")
        end
    end
    self.mainFrame:Hide()
end

-- 以下为各属性显示函数（均调用BCS函数）
function P:GetItemScore()
    if ItemSocre and type(ItemSocre.ScanUnit) == "function" then
        local playerScore = ReadNumber(ItemSocre.ScanUnit, ItemSocre, "player")
        if playerScore and playerScore > 0 then
            return "装等: " .. playerScore
        end
    end
    return "装等: 数据不可用"
end

function P:DisplayAP()
    local base, posBuff, negBuff = UnitAttackPower("player")
    return "攻强: " .. (base + posBuff + negBuff)
end

function P:DisplayRAP()
    local base, posBuff, negBuff = UnitRangedAttackPower("player")
    return "远程攻强: " .. (base + posBuff + negBuff)
end

function P:DisplaySP()
    if not BCS then
        return "法强: 数据不可用"
    end

    -- 若安装了 Nampower，使用其 GetSpellPower 并取各系最大值
    if BCS:IsNampowerReady() then
        local physical, holy, fire, nature, frost, shadow, arcane = GetSpellPower()
        -- 使用 or 0 确保所有参数都是数字
        local totalPower = math.max(holy or 0, fire or 0, nature or 0, frost or 0, shadow or 0, arcane or 0)
        return "法强: " .. math.floor(totalPower + 0.5)
    else
        local value1, value2 = BCS:GetSpellPower()
        value2 = value2 or 0
        return "法强: " .. math.floor(value1 + value2 + 0.5)
    end
end

function P:DisplayManaRegen()
    if BCS then
        local _, manaRegen2, manaRegen3 = BCS:GetManaRegen()
        manaRegen2 = manaRegen2 or 0
        manaRegen3 = manaRegen3 or 0
        local total = manaRegen2 + manaRegen3 * 0.4
        return "回蓝: " .. math.floor(total)
    else
        return "回蓝: 数据不可用"
    end
end

function P:DisplayHealingPower()
    if BCS then
        local power, _, _, dmg = BCS:GetSpellPower()
        dmg = dmg or 0
        local heal = BCS:GetHealingPower()
        heal = heal + power - dmg
        return "治疗: " .. math.floor(heal)
    else
        return "治疗: 数据不可用"
    end
end

function P:DisplayPhysicalCrit()
    if BCS then
        local success, crit = pcall(BCS.GetCritChance, BCS)
        if success and crit then
            return "暴击: " .. string.format("%.2f", crit) .. "%"
        else
            return "暴击: 数据获取失败"
        end
    else
        return "暴击: 数据不可用"
    end
end

function P:DisplayHitRating()
    if BCS then
        local hit = BCS:GetHitRating()
        return "命中: " .. math.floor(hit + 0.5) .. "%"
    else
        return "命中: 数据不可用"
    end
end

function P:DisplayRangedHitRating()
    if BCS and BCS.GetRangedHitRating then
        local hit = BCS:GetRangedHitRating()
        return "远程命中: " .. math.floor(hit + 0.5) .. "%"
    else
        return "远程命中: 数据不可用"
    end
end

function P:DisplayRangedCritChance()
    if BCS then
        local success, crit = pcall(BCS.GetRangedCritChance, BCS)
        if success and crit then
            return "远程暴击: " .. string.format("%.2f", crit) .. "%"
        else
            return "远程暴击: 数据获取失败"
        end
    else
        return "远程暴击: 数据不可用"
    end
end

function P:DisplaySpellCrit()
    if BCS then
        local success, crit = pcall(BCS.GetSpellCritChance, BCS)
        if success and crit then
            return "法暴: " .. string.format("%.2f", crit) .. "%"
        else
            return "法暴: 数据获取失败"
        end
    else
        return "法暴: 数据不可用"
    end
end

function P:DisplaySpellHitRating()
    if BCS and BCS.GetSpellHitRating then
        local base, fire, frost, arcane, shadow, holy = BCS:GetSpellHitRating()
        base = base or 0
        fire = fire or 0
        frost = frost or 0
        arcane = arcane or 0
        shadow = shadow or 0
        holy = holy or 0
        local otherMax = math.max(fire, frost, arcane, shadow, holy)
        return "法命: " .. math.floor(base + otherMax + 0.5) .. "%"
    else
        return "法命: 数据不可用"
    end
end

function P:DisplayHaste()
    if not BCS then return "急速: 数据不可用" end

    local haste
    local _, class = UnitClass("player")
    -- Paladin Zeal affects attack speed. The cast coefficient may only remove
    -- millisecond timer rounding when it agrees with the actual melee interval.
    if class == "PALADIN" then
        local ok, measured, base, current = pcall(self.GetMeleeHaste, self)
        if ok and IsFiniteNumber(measured) then
            haste = measured
            local tolerance = 0.00000025
            if measured > 0 and IsFiniteNumber(base) and base > 0
                and IsFiniteNumber(current) and current > 0
                and math.abs(current - math.floor(current * 1000 + 0.5) / 1000) <= tolerance then
                local castSpeed = ReadNumber(GetUnitField, "player", "modCastSpeed")
                if castSpeed and castSpeed > 0 then
                    local precise = (1 / castSpeed - 1) * 100
                    local expected = base * castSpeed
                    local rounding = expected - current
                    if IsFiniteNumber(precise) and precise > 0
                        and rounding >= -tolerance and rounding <= 0.001 + tolerance then
                        haste = precise
                    end
                end
            end
        end
        if not IsFiniteNumber(haste) then
            local previousForce = BCS.ForceCalculate
            BCS.ForceCalculate = true
            haste = ReadNumber(BCS.GetCalculatedMeleeHaste or BCS.GetHaste, BCS)
            BCS.ForceCalculate = previousForce
        end
        -- A melee statistic must fall back to the factor calculation, not
        -- silently switch to the unrelated casting-speed coefficient.
        if not IsFiniteNumber(haste) then return "急速: 数据不可用" end
        return "急速: " .. string.format("%.2f", haste) .. "%"
    end
    if not IsFiniteNumber(haste) and type(BCS.IsNampowerReady) == "function" then
        local ok, ready = pcall(BCS.IsNampowerReady, BCS)
        if ok and ready then
            local castSpeed = ReadNumber(GetUnitField, "player", "modCastSpeed")
            if castSpeed and castSpeed > 0 then haste = (1 / castSpeed - 1) * 100 end
        end
    end
    if not IsFiniteNumber(haste) then haste = ReadNumber(BCS.EstimateHaste, BCS) end
    if not IsFiniteNumber(haste) then
        local previousForce = BCS.ForceCalculate
        BCS.ForceCalculate = true
        haste = ReadNumber(BCS.GetHaste, BCS)
        BCS.ForceCalculate = previousForce
    end
    if not IsFiniteNumber(haste) then return "急速: 数据不可用" end
    return "急速: " .. string.format("%.2f", haste) .. "%"
end

-- Same attack-speed ratio as the character panel's melee haste, for source comparison.
function P:GetMeleeHaste()
    if not BCS then return nil end
    local base
    local canIdentifyWeapon = type(GetInventoryItemLink) == "function"
    local weaponKey
    if canIdentifyWeapon then weaponKey = GetInventoryItemLink("player", 16) end
    if canIdentifyWeapon and self.hasteWeaponBase and self.hasteWeaponKey == weaponKey then
        base = self.hasteWeaponBase
    else
        -- Prefer the item's original millisecond delay to the rounded tooltip.
        local _, _, itemID = string.find(weaponKey or "", "item:(%d+)")
        local delay = itemID and ReadNumber(GetItemStatsField, tonumber(itemID), "delay")
        if delay and delay > 0 then base = delay / 1000 end
        if not base then base = ReadNumber(BCS.GetOriWeaponSpeed, BCS, 16) end
        if base and base > 0 then
            self.hasteWeaponKey, self.hasteWeaponBase = weaponKey, base
        else self.hasteWeaponBase = nil end
    end
    local _, class = UnitClass("player")
    if class == "DRUID" and BCS.GetDruidForm and BCS.L_FORM then
        local ok, form = pcall(BCS.GetDruidForm, BCS)
        if ok and form == BCS.L_FORM.BEAR then base = 2.5
        elseif ok and form == BCS.L_FORM.CAT then base = 1 end
    end
    local current = ReadNumber(UnitAttackSpeed, "player")
    if base and base > 0 and current and current > 0 then
        -- The client's integer attack timer can lose a millisecond when
        -- converting a float back to milliseconds. Normalize only this
        -- boundary error, never all haste values below a fixed percentage.
        local boundaryTolerance = 0.00000025
        local baseRounded = math.floor(base * 1000 + 0.5) / 1000
        local currentRounded = math.floor(current * 1000 + 0.5) / 1000
        if math.abs(base - current) <= 0.001 + boundaryTolerance
            and math.abs(base - baseRounded) <= boundaryTolerance
            and math.abs(current - currentRounded) <= boundaryTolerance then
            return 0, base, current
        end
        return (base / current - 1) * 100, base, current
    end
end

function P:DisplayDualAttackSpeed()
    local mainHandSpeed, offHandSpeed = UnitAttackSpeed("player")
    if offHandSpeed then
        return string.format("攻速: %.2f/%.2f", mainHandSpeed, offHandSpeed)
    else
        return string.format("攻速: %.2f", mainHandSpeed)
    end
end

function P:DisplayAttackSpeed()
    local _, playerClass = UnitClass("player")
    if playerClass == "HUNTER" then
        local speed = UnitRangedDamage("player")
        return string.format("攻速: %.2f", math.floor(speed * 100 + 0.5) / 100)
    else
        local speed = UnitAttackSpeed("player")
        return string.format("攻速: %.2f", speed)
    end
end

-- 以下三个防御类取值在自定义模式下可能被任意职业勾选，故统一 pcall 兜底，
-- 避免个别客户端缺少对应全局 API 时整行丢失
function P:DisplayDodge()
    local dodge = self:GetDefenseChance("dodge")
    if dodge then
        return "躲闪: " .. string.format("%.2f", dodge) .. "%"
    end
    return "躲闪: 数据不可用"
end

function P:DisplayParry()
    local parry = self:GetDefenseChance("parry")
    if parry then
        return "招架: " .. string.format("%.2f", parry) .. "%"
    end
    return "招架: 数据不可用"
end

function P:DisplayBlock()
    local block = self:GetDefenseChance("block")
    if block then
        return "格挡: " .. string.format("%.2f", block) .. "%"
    end
    return "格挡: 数据不可用"
end

function P:DisplayBlockValue()
    local value = ReadNumber(GetBlockValue)
    if value == nil and BCS and type(BCS.GetBlockValue) == "function" then
        value = ReadNumber(BCS.GetBlockValue, BCS)
    end
    if value then
        return "格挡值: " .. math.floor(value + 0.5)
    end
    return "格挡值: 数据不可用"
end

function P:GetDefenseChance(key)
    if self.defenseSnapshot then return self.defenseSnapshot[key] end
    if key == "dodge" then return ReadNumber(GetDodgeChance) end
    if key == "parry" then return ReadNumber(GetParryChance) end
    if key == "block" then return ReadNumber(GetBlockChance) end
    return nil
end

function P:DisplayThreeDimensions()
    local dodge = self:GetDefenseChance("dodge")
    local parry = self:GetDefenseChance("parry")
    local block = self:GetDefenseChance("block")
    if dodge == nil or parry == nil or block == nil then return "三维: 数据不可用" end
    return string.format("三维: %.2f%%", dodge + parry + block)
end

function P:DisplayResistance(school, label)
    if type(UnitResistance) ~= "function" then return label .. ": 数据不可用" end
    local ok, base, effective = pcall(UnitResistance, "player", school)
    if not ok then return label .. ": 数据不可用" end
    -- 某些扩展客户端只返回一个值；第二返回值存在但无效时不伪装成基础值。
    local value = effective
    if value == nil then value = base end
    if not IsFiniteNumber(value) then return label .. ": 数据不可用" end
    return label .. ": " .. math.floor(value + 0.5)
end

function P:DisplayArmorReduction()
    local _, armor = UnitArmor("player")
    -- 有目标时以目标等级为准，无目标时以玩家等级为参照。
    local level = UnitLevel(UnitExists("target") and "target" or "player")
    -- “？级”目标返回 -1，按玩家等级 + 3 估算，避免将等级标记作为无效数据。
    if level == -1 then
        local playerLevel = UnitLevel("player")
        if IsFiniteNumber(playerLevel) and playerLevel > 0 then
            level = playerLevel + 3
        end
    end
    if not IsFiniteNumber(armor) or not IsFiniteNumber(level) or level <= 0 then
        return "减伤: 数据不可用"
    end
    armor = math.max(0, armor)
    local reduction = math.min(0.75, armor / (armor + 400 + 85 * level)) * 100
    return string.format("减伤: %.2f%%", reduction)
end

function P:DisplayArmor()
    if BCS then
        local base, effectiveArmor, armor = UnitArmor("player")
        if not IsFiniteNumber(effectiveArmor) then return "护甲: 数据不可用" end
        return "护甲: " .. math.floor(effectiveArmor + 0.5)
    else
        return "护甲: 数据不可用"
    end
end

function P:DisplayDefense()
    if BCS then
        local base, modifier = UnitDefense("player")
        return "防御: " .. (base + modifier)
    else
        return "防御: 数据不可用"
    end
end

function P:DisplayArmorPenetration()
    if BCS then
        local armorPen = BCS:GetArmorPenetrationValue()
        return "破甲: " .. math.floor(armorPen + 0.5)
    else
        return "破甲: 数据不可用"
    end
end

-- ===== 当前预设属性编辑器 =====
local CBOX_ROW_H, CBOX_COLS, CBOX_COL_W = 20, 2, 166
local itemCount = ArrayCount(PROPERTY_LIST)
local rowCount = math.ceil(itemCount / CBOX_COLS)

P.customFrame = CreateFrame("Frame", "BCSPropertiesPanelCustomFrame", UIParent)
P.customFrame:SetWidth(CBOX_COL_W * CBOX_COLS + 28)
P.customFrame:SetHeight(194 + rowCount * CBOX_ROW_H)
P.customFrame:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", tile=true, tileSize=16})
P.customFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.94)
P.customFrame:SetMovable(true)
P.customFrame:EnableMouse(true)
P.customFrame:RegisterForDrag("LeftButton")
P.customFrame:SetScript("OnDragStart", function() P.customFrame:StartMoving() end)
P.customFrame:SetScript("OnDragStop", function() P.customFrame:StopMovingOrSizing() end)
P.customFrame:SetFrameStrata("DIALOG")
P.customFrame:Hide()

local function EditorLabel(text, x, y, size)
    local label = P.customFrame:CreateFontString(nil, "OVERLAY")
    label:SetFont(STANDARD_TEXT_FONT, size or 12)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end
P.editorTitle = EditorLabel("编辑预设", 14, -10, 14)
P.editorTitle:SetTextColor(1, 0.82, 0)
EditorLabel("各预设分别保存，标题项不重复显示", 14, -32, 11):SetTextColor(0.75, 0.75, 0.75)
EditorLabel("大字标题", 14, -61)
EditorLabel("排序属性", 14, -91)
EditorLabel("减伤参照", 14, -122)
EditorLabel("当前目标；无目标时按自身等级计算", 86, -122, 10)

local editorClose = CreateButton("关闭", P.customFrame, "TOPRIGHT", P.customFrame, -12, -8,
    function() P.customFrame:Hide() end)
editorClose:SetWidth(46)

function P:SetTitleKey(key)
    local profile = self:EnsureProfile()
    if key ~= "auto" and not profile.props[key] then return end
    profile.titleKey = key
    self:RefreshCustomRows()
    self:RefreshNow()
end

function P:MoveProperty(key, direction)
    local profile = self:EnsureProfile()
    local keys = self:GetSelectedKeys()
    for i = 1, ArrayCount(keys) do
        if keys[i] == key then
            local nextIndex = i + direction
            if nextIndex < 1 or nextIndex > ArrayCount(keys) then return end
            keys[i], keys[nextIndex] = keys[nextIndex], keys[i]
            -- 未选项保留在尾部，之后重新勾选时可恢复。
            local seen = {}
            for j = 1, ArrayCount(keys) do seen[keys[j]] = true end
            for j = 1, ArrayCount(profile.order) do
                if not seen[profile.order[j]] then Append(keys, profile.order[j]) end
            end
            profile.order = keys
            self:RefreshCustomRows()
            self:RefreshNow()
            return
        end
    end
end

local function CreateEditorMenu(name, y, titleMenu)
    local menu = CreateFrame("Frame", name, P.customFrame, "UIDropDownMenuTemplate")
    menu:SetPoint("TOPLEFT", P.customFrame, "TOPLEFT", 86, y)
    UIDropDownMenu_SetWidth(130, menu)
    UIDropDownMenu_Initialize(menu, function()
        if not P.initialized then return end
        local profile = P:EnsureProfile()
        if titleMenu then
            local info = {text="自动（第一项）", value="auto", checked=profile.titleKey == "auto"}
            info.func = function() P:SetTitleKey("auto") end
            UIDropDownMenu_AddButton(info)
        end
        local keys = P:GetSelectedKeys()
        for i = 1, ArrayCount(keys) do
            local key = keys[i]
            local info = {text=PROPERTY_BY_KEY[key].label, value=key}
            if titleMenu then
                info.checked = profile.titleKey == key
                info.func = function() P:SetTitleKey(key) end
            else
                info.checked = P.sortKey == key
                info.func = function() P.sortKey = key; P:RefreshCustomRows() end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    return menu
end
P.titleMenu = CreateEditorMenu("BCSPropertiesTitleMenu", -51, true)
P.sortMenu = CreateEditorMenu("BCSPropertiesSortMenu", -81, false)
local upButton = CreateButton("上移", P.customFrame, "TOPLEFT", P.customFrame, 254, -84,
    function() if P.sortKey then P:MoveProperty(P.sortKey, -1) end end)
upButton:SetWidth(40)
local downButton = CreateButton("下移", P.customFrame, "TOPLEFT", P.customFrame, 304, -84,
    function() if P.sortKey then P:MoveProperty(P.sortKey, 1) end end)
downButton:SetWidth(40)

local function PositionCustomWindow()
    local f = P.customFrame
    local screenW = UIParent:GetWidth()
    local right, left = P.mainFrame:GetRight(), P.mainFrame:GetLeft()
    f:ClearAllPoints()
    if right and right + f:GetWidth() + 10 <= screenW - 4 then
        f:SetPoint("TOPLEFT", P.mainFrame, "TOPRIGHT", 10, 0)
    elseif left and left - f:GetWidth() - 10 >= 4 then
        f:SetPoint("TOPRIGHT", P.mainFrame, "TOPLEFT", -10, 0)
    else f:SetPoint("CENTER", UIParent, "CENTER", 0, 0) end
end

local function CreateCheckRow(item, x, y)
    local key = item.key
    local row = CreateFrame("Button", nil, P.customFrame)
    row:SetWidth(CBOX_COL_W)
    row:SetHeight(CBOX_ROW_H)
    row:SetPoint("TOPLEFT", P.customFrame, "TOPLEFT", x, y)
    row.box = row:CreateTexture(nil, "ARTWORK")
    row.box:SetWidth(14)
    row.box:SetHeight(14)
    row.box:SetPoint("LEFT", 0, 0)
    row.text = row:CreateFontString(nil, "OVERLAY")
    row.text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    row.text:SetPoint("LEFT", row.box, "RIGHT", 3, 0)
    row.text:SetText(item.label)
    row.key = key
    function row:Refresh()
        local selected = P:EnsureProfile().props[key]
        row.box:SetTexture(selected and "Interface\\Buttons\\UI-CheckBox-Check" or "Interface\\Buttons\\UI-CheckBox-Up")
        local label = item.label
        if P:GetTitleKey() == key then label = label .. "（标题）" end
        row.text:SetText(label)
        if selected then
            local color = PROPERTY_COLORS[key]
            if P.colorMode ~= "off" and color then row.text:SetText("|cFF" .. color .. label .. "|r") end
            row.text:SetTextColor(1, 1, 1)
        else row.text:SetTextColor(0.6, 0.6, 0.6) end
    end
    row:SetScript("OnClick", function()
        local profile = P:EnsureProfile()
        profile.props[key] = not profile.props[key] or nil
        if profile.props[key] then
            local found = false
            for i = 1, ArrayCount(profile.order) do if profile.order[i] == key then found = true end end
            if not found then Append(profile.order, key) end
        elseif profile.titleKey == key then profile.titleKey = "auto" end
        P:RefreshCustomRows()
        P:MarkDirty()
    end)
    row:SetScript("OnEnter", function()
        GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
        if key == "three" then
            GameTooltip:SetText("三维：躲闪概率 + 招架概率 + 格挡概率")
            GameTooltip:AddLine("使用原始百分比求和后保留两位小数。", 0.8, 0.8, 0.8, 1)
        elseif key == "armorDR" then
            GameTooltip:SetText("减伤（经典规则估算）")
            GameTooltip:AddLine("按有效护甲与当前目标等级计算，上限 75%。", 0.8, 0.8, 0.8, 1)
            GameTooltip:AddLine("无目标时按自身等级计算；？级目标按自身等级 + 3 估算。", 0.8, 0.8, 0.8, 1)
            GameTooltip:AddLine("不包含姿态、天赋、技能减伤或魔法抗性。", 0.8, 0.8, 0.8, 1)
        else GameTooltip:SetText(item.label) end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return row
end

P.customRows = {}
for i = 1, itemCount do
    local r = math.floor((i - 1) / CBOX_COLS)
    local col = (i - 1) - r * CBOX_COLS
    P.customRows[i] = CreateCheckRow(PROPERTY_LIST[i], 14 + col * CBOX_COL_W, -(150 + r * CBOX_ROW_H))
end

function P:ResetCurrentProfile()
    local panel = PanelConfig()
    local name = self.displayConfig
    panel.profiles[name] = nil
    if name == "自定义" then panel.customProps = nil end
    self:EnsureProfile(name)
    self.sortKey = nil
    self:RefreshCustomRows()
    self:RefreshNow()
end

local selectAll = CreateButton("全选", P.customFrame, "BOTTOM", P.customFrame, -126, 10, function()
    local profile = P:EnsureProfile()
    for i = 1, itemCount do profile.props[PROPERTY_LIST[i].key] = true end
    P:RefreshCustomRows()
    P:MarkDirty()
end)
selectAll:SetWidth(56)
local clearAll = CreateButton("清空", P.customFrame, "BOTTOM", P.customFrame, -52, 10, function()
    local profile = P:EnsureProfile()
    for key in pairs(profile.props) do profile.props[key] = nil end
    profile.titleKey = "auto"
    P:RefreshCustomRows()
    P:MarkDirty()
end)
clearAll:SetWidth(56)
local reset = CreateButton("恢复预设", P.customFrame, "BOTTOM", P.customFrame, 32, 10,
    function() P:ResetCurrentProfile() end)
reset:SetWidth(76)
local done = CreateButton("完成", P.customFrame, "BOTTOM", P.customFrame, 126, 10, function()
    ApplyReductionLevel()
    P:RefreshNow()
    P.customFrame:Hide()
end)
done:SetWidth(56)
P.customButtons = {selectAll=selectAll, clearAll=clearAll, reset=reset, done=done}

function P:RefreshCustomRows()
    local profile = self:EnsureProfile()
    self.editorTitle:SetText("编辑预设：" .. (self.displayConfig or "自定义"))
    for i = 1, ArrayCount(self.customRows) do self.customRows[i]:Refresh() end
    local title = profile.titleKey == "auto" and "自动（第一项）" or PROPERTY_BY_KEY[profile.titleKey].label
    UIDropDownMenu_SetText(title, self.titleMenu)
    local keys = self:GetSelectedKeys()
    if not self.sortKey or not profile.props[self.sortKey] then self.sortKey = keys[1] end
    UIDropDownMenu_SetText(self.sortKey and PROPERTY_BY_KEY[self.sortKey].label or "未选择属性", self.sortMenu)
end

function P:ShowCustomWindow(show)
    if show then
        self:RefreshCustomRows()
        PositionCustomWindow()
        self.customFrame:Show()
    else self.customFrame:Hide() end
end

-- 事件处理
P.frame:RegisterEvent("ADDON_LOADED")
P.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
P.frame:RegisterEvent("UNIT_AURA")
P.frame:RegisterEvent("PLAYER_AURAS_CHANGED")
P.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
P.frame:RegisterEvent("UNIT_LEVEL")

P.frame:SetScript("OnEvent", function(self, event, arg1)
    -- 兼容两种 SetScript 回调约定：
    --   A) 现代写法：回调收到 (self, event, arg1)
    --   B) 香草 1.12：回调不传参，事件名与参数只在全局 event / arg1 上
    -- 以「事件名是否为空」判定，A 约定下这几行是空操作，两种客户端都正确。
    if not event then
        event = _G.event
        arg1 = _G.arg1
    end

    if event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        -- 确保 BCSConfig 存在
        BCSConfig = BCSConfig or {}

        -- 初始化配置表（如果不存在）
        if not BCSConfig.PropertiesPanel then
            BCSConfig.PropertiesPanel = {}
        end

        -- 调用初始化函数
        P:Init()

        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 已加载，输入 /mb 呼出配置选择窗口", 1, 1, 1)
    end

    if event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
        P.hasteWeaponBase = nil
    end

    if event == "PLAYER_AURAS_CHANGED"
        or (event == "UNIT_AURA" and (not arg1 or arg1 == "player"))
        or (event == "UNIT_INVENTORY_CHANGED" and arg1 == "player") then
        if BCS and BCS.InvalidateHasteCache then BCS:InvalidateHasteCache() end
    end

    -- 切换目标时立即更新减伤参照，其余事件保留节流。
    if event == "PLAYER_TARGET_CHANGED" then P.forceNextBuild = true end

    -- 事件只标记「需要重建」，具体重建时机交给节流逻辑（最小间隔 + 最大间隔），
    -- 避免战斗中光环频繁变化时每 0.2 秒重扫一遍全部装备
    -- 另：本面板只显示玩家自身数值，UNIT_AURA 只需响应 player（arg1 为 nil 时保守放行）
    if event ~= "UNIT_AURA" or not arg1 or arg1 == "player" then
        P:MarkDirty()
    end

    -- 仅在开启状态下刷新显示
    if not P.showWindow then
        P.frame:Hide()
        return
    end

    -- 注意：这里走「节流路径」（MarkDirty + GetDisplayLines），
    -- 重建时机由最小/最大间隔决定，避免事件风暴触发高频重扫
    local firstLine, restLines = P:GetDisplayLines()
    P:UpdateDisplay(1, firstLine, restLines)
end)

-- 聊天命令
local function HandleSlashCommand(arg)
    if arg == "" then
        -- 无参数：切换主配置窗口
        if P.mainFrame:IsShown() then
            P.mainFrame:Hide()
        else
            P.mainFrame:Show()
        end
    elseif arg == "off" or arg == "hide" then
        -- 关闭悬浮窗
        P.showWindow = false
        P.frame:Hide()
        if not BCSConfig.PropertiesPanel then
            BCSConfig.PropertiesPanel = {}
        end
        BCSConfig.PropertiesPanel.enabled = false
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已隐藏", 1, 1, 1)
    elseif arg == "on" or arg == "show" then
        -- 显示悬浮窗
        P.showWindow = true
        P:RefreshNow()
        if not BCSConfig.PropertiesPanel then
            BCSConfig.PropertiesPanel = {}
        end
        BCSConfig.PropertiesPanel.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已显示", 1, 1, 1)
    elseif arg == "toggle" or arg == "visible" then
        -- 切换悬浮窗显示状态
        if P.showWindow then
            P.showWindow = false
            P.frame:Hide()
            if not BCSConfig.PropertiesPanel then
                BCSConfig.PropertiesPanel = {}
            end
            BCSConfig.PropertiesPanel.enabled = false
            DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已隐藏", 1, 1, 1)
        else
            P.showWindow = true
            P:RefreshNow()
            if not BCSConfig.PropertiesPanel then
                BCSConfig.PropertiesPanel = {}
            end
            BCSConfig.PropertiesPanel.enabled = true
            DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已显示", 1, 1, 1)
        end
    elseif arg == "align left" then
        P.align = "LEFT"
        if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
        BCSConfig.PropertiesPanel.align = "LEFT"
        P:RefreshNow()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 对齐方式设置为左对齐", 1, 1, 1)
    elseif arg == "align center" then
        P.align = "CENTER"
        if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
        BCSConfig.PropertiesPanel.align = "CENTER"
        P:RefreshNow()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 对齐方式设置为居中对齐", 1, 1, 1)
    elseif arg == "align right" then
        P.align = "RIGHT"
        if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
        BCSConfig.PropertiesPanel.align = "RIGHT"
        P:RefreshNow()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 对齐方式设置为右对齐", 1, 1, 1)
    elseif arg == "haste" then
        local function Report(label, value)
            DEFAULT_CHAT_FRAME:AddMessage("急速取值 · " .. label .. ": "
                .. (IsFiniteNumber(value) and string.format("%.4f", value) or "不可用"))
        end
        local castSpeed = ReadNumber(GetUnitField, "player", "modCastSpeed")
        Report("施法速度系数", castSpeed)
        Report("接口急速（%）", castSpeed and castSpeed > 0 and (1 / castSpeed - 1) * 100 or nil)
        Report("施法时间估算（%）", BCS and ReadNumber(BCS.LiveEstimateHaste, BCS))
        local _, class = UnitClass("player")
        Report("装备与增益统计（%）", BCS and ReadNumber(BCS.GetLiveHaste, BCS, class == "PALADIN" and "melee" or nil))
        Report("近战急速（%）", P:GetMeleeHaste())
        local zealValue, zealReason
        if BCS and type(BCS.GetZealHastePerStack) == "function" then
            local ok, value, reason = pcall(BCS.GetZealHastePerStack, BCS)
            if ok then zealValue, zealReason = value, reason end
        end
        Report("狂热每层（%）", zealValue)
        if not IsFiniteNumber(zealValue) and zealReason then
            DEFAULT_CHAT_FRAME:AddMessage("狂热技能读取 · " .. zealReason)
        end
        DEFAULT_CHAT_FRAME:AddMessage("浮窗当前值 · " .. P:DisplayHaste())
        if BCS and BCS.GetHasteAuraDetails then
            local ok, auras = pcall(BCS.GetHasteAuraDetails, BCS)
            if ok then
                for i = 1, ArrayCount(auras) do
                    local aura = auras[i]
                    DEFAULT_CHAT_FRAME:AddMessage("急速增益 · " .. aura.name .. "（" .. aura.stacks .. "层）: " .. aura.text)
                end
            end
        end
    elseif arg == "lock" then
        P:SetLocked(true, true)
    elseif arg == "unlock" then
        P:SetLocked(false, true)
    elseif arg == "togglelock" then
        if P.locked then
            HandleSlashCommand("unlock")
        else
            HandleSlashCommand("lock")
        end
    elseif arg == "custom" or arg == "自定义" then
        -- 切换到自定义模式并打开勾选窗口
        P:SelectConfig("自定义")
        P.mainFrame:Show()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 已切换到自定义属性，可勾选属性、选择大字标题和调整顺序", 1, 1, 1)
    elseif arg == "panel" or arg == "charpanel" or arg == "角色面板" then
        -- 切换「是否在角色面板中显示 BCS 属性」
        P:SetCharacterPanelEnabled(P.characterPanelEnabled == false)
    elseif string.find(arg, "^align ") then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 未知的对齐方式，可用：left, center, right", 1, 0, 0)
    else
        -- 未知参数，提示用法
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开设置，编辑当前预设可增减属性/设置标题/排序；/mb custom 打开独立自定义，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 0, 0)
    end
end

SLASH_PROPERTIESPANEL1 = "/mb"
SlashCmdList["PROPERTIESPANEL"] = HandleSlashCommand

-- 初始隐藏主窗口
P.mainFrame:Hide()
