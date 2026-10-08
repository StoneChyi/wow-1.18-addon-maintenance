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

-- 辅助函数：获取速度行（仅供悬浮窗使用，失败返回 nil）
local function GetSpeedLine()
    local ok, speed1 = pcall(UnitXP, "speed", "player")
    if ok and speed1 then
        local percent = speed1 * 100 / 7
        return string.format("移速: %.1f%%", percent)
    end
    return nil
end

-- ===== 属性注册表 =====
-- 自定义勾选窗口与预设配置共用同一份定义：数组顺序 = 勾选窗口的阅读顺序（行优先，
-- 从左到右、从上到下） = 悬浮窗显示顺序。第一个勾选项作为「大字标题行」。
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
    { key = "dodge",    label = "躲闪",     get = function(self) return self:DisplayDodge() end },
    { key = "parry",    label = "招架",     get = function(self) return self:DisplayParry() end },
    { key = "block",    label = "格挡",     get = function(self) return self:DisplayBlock() end },
    { key = "blockval", label = "格挡值",   get = function(self) return self:DisplayBlockValue() end },
    -- 其他
    { key = "score",    label = "装等",     get = function(self) return self:GetItemScore() end },
}

-- 各预设对应的属性 key 列表（与旧版硬编码顺序、内容完全一致）
local PRESET_KEYS = {
    ["物理"] = {"ap", "hit", "crit", "arpen", "apspeed"},
    ["法系"] = {"sp", "shit", "scrit", "regen", "haste"},
    ["治疗"] = {"heal", "sp", "scrit", "regen", "haste"},
    ["猎人"] = {"rap", "sp", "rhit", "rcrit", "arpen", "spd"},
    ["混伤"] = {"ap", "sp", "hit", "crit", "arpen", "apspeed"},
    ["防御"] = {"armor", "defense", "hit", "dodge", "parry", "block"},
}

-- 统计数组长度（兼容 Lua 5.0/5.1：不使用 # 运算符，也不用 table.getn）
local function ArrayCount(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- 确保自定义勾选表存在；首次创建时以「当前预设」作为初始勾选
function P:EnsureCustomProps()
    BCSConfig = BCSConfig or {}
    if not BCSConfig.PropertiesPanel then
        BCSConfig.PropertiesPanel = {}
    end
    local props = BCSConfig.PropertiesPanel.customProps
    if props then return props end

    props = {}
    local seed = PRESET_KEYS[self.displayConfig]
    if not seed then
        -- displayConfig 尚未就绪（极少数情况）：退回本职业默认预设
        seed = PRESET_KEYS[GetDefaultDisplayConfig()] or PRESET_KEYS["物理"]
    end
    for i = 1, ArrayCount(seed) do
        props[seed[i]] = true
    end
    props.speed = true          -- 移速行默认开启（保持与预设一致）
    BCSConfig.PropertiesPanel.customProps = props
    return props
end

-- 当前生效的属性 key 顺序列表（预设走 PRESET_KEYS，自定义按注册表顺序过滤）
function P:GetSelectedKeys()
    local preset = PRESET_KEYS[self.displayConfig]
    if preset then return preset end

    local props = self:EnsureCustomProps()
    local keys = {}
    local n = 0
    for i = 1, ArrayCount(PROPERTY_LIST) do
        local k = PROPERTY_LIST[i].key
        if props[k] then
            n = n + 1
            keys[n] = k
        end
    end
    return keys
end

-- 是否显示移速行：预设恒显示，自定义由勾选项决定（默认显示）
function P:IsSpeedShown()
    if PRESET_KEYS[self.displayConfig] then return true end
    local props = self:EnsureCustomProps()
    return props.speed ~= false
end

-- 按 key 取显示串；取值失败时回退为「标签: 数据不可用」，避免自定义模式下整行丢失
function P:GetPropertyText(key)
    for i = 1, ArrayCount(PROPERTY_LIST) do
        local item = PROPERTY_LIST[i]
        if item.key == key then
            local ok, text = pcall(item.get, self)
            if ok and text then return text end
            return item.label .. ": 数据不可用"
        end
    end
    return nil
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

-- 标题行（第一行，大字体）
P.frame.title = P.frame:CreateFontString(nil, "ARTWORK")
P.frame.title:SetFont("Fonts\\ARIALN.ttf", 16, "OUTLINE")

-- 详细信息行（其余行，小字体）
P.frame.details = P.frame:CreateFontString(nil, "ARTWORK")
P.frame.details:SetFont("Fonts\\ARIALN.ttf", 13, "OUTLINE")

P.frame:RegisterForDrag("LeftButton")
P.frame:SetScript("OnDragStart", function()
    if P.locked then return end  -- 锁定时禁止拖动
    P.frame:StartMoving()
end)
P.frame:SetScript("OnDragStop", function()
    P.frame:StopMovingOrSizing()
    if P.locked then return end
    local point, _, rel_point, x_offset, y_offset = P.frame:GetPoint()
    if x_offset < 20 and x_offset > -20 then x_offset = 0 end

    -- 确保 BCSConfig.PropertiesPanel 存在
    if not BCSConfig.PropertiesPanel then
        BCSConfig.PropertiesPanel = {}
    end

    -- 保存位置
    BCSConfig.PropertiesPanel.point = point
    BCSConfig.PropertiesPanel.rel_point = rel_point
    BCSConfig.PropertiesPanel.x_offset = math.floor(x_offset)
    BCSConfig.PropertiesPanel.y_offset = math.floor(y_offset)
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
P.mainFrame:SetHeight(120)
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
    DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开配置窗口，/mb custom 自定义属性勾选窗口，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 1, 1)
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

-- 切换显示配置（预设或自定义）：统一入口，供按钮 / 命令调用
function P:SelectConfig(name)
    -- 切到「自定义」前先固化初始勾选（以切换前的预设为准）
    if name == "自定义" then
        self:EnsureCustomProps()
    end

    self.displayConfig = name
    if not BCSConfig.PropertiesPanel then
        BCSConfig.PropertiesPanel = {}
    end
    BCSConfig.PropertiesPanel.displayConfig = name

    -- 自定义模式同时打开勾选窗口，预设模式则收起
    if name == "自定义" then
        self:ShowCustomWindow(true)
    else
        self:ShowCustomWindow(false)
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

    local btn = CreateButton(buttonText, P.mainFrame, "CENTER", P.mainFrame, x, 15 - 20, function()
        P:SelectConfig(buttonText)
        -- 预设按钮点完收起主窗口；自定义按钮保留（勾选窗口就开在它右侧）
        if buttonText ~= "自定义" then
            P.mainFrame:Hide()
        end
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
    self.frame:SetPoint(point, UIParent, rel_point, x, y)

    -- 设置显示配置到 P.displayConfig
    self.displayConfig = panel.displayConfig

    -- 设置对齐方式
    self.align = panel.align

    -- 设置锁定状态
    self.locked = panel.locked

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

-- 更新悬浮窗显示（接收第一行和其余行）
-- 为配合 0.2 秒的定时刷新，这里做了两处省开销处理：
--   1) 排版（锚点/宽度/对齐/标题颜色）只在首次或对齐方式变化时重设一次；
--   2) 文本只在内容真正变化时才 SetText，避免无意义的字体排版。
function P:UpdateDisplay(show, firstLine, restLines)
    if show ~= 1 then
        self.frame:Hide()
        -- 隐藏时停止定时器
        if self.speedUpdater then
            self.speedUpdater:Cancel()
            self.speedUpdater = nil
        end
        return
    end

    -- 排版只在首次显示或对齐方式变化时重设
    if self.appliedAlign ~= self.align then
        -- 清除旧锚点，根据对齐方式重新设置
        self.frame.title:ClearAllPoints()
        self.frame.details:ClearAllPoints()

        local margin = 10  -- 左右边距
        local frameWidth = self.frame:GetWidth()

        if self.align == "LEFT" then
            self.frame.title:SetPoint("TOPLEFT", self.frame, "TOPLEFT", margin, -10)
            self.frame.details:SetPoint("TOPLEFT", self.frame, "TOPLEFT", margin, -30)
        elseif self.align == "RIGHT" then
            self.frame.title:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -margin, -10)
            self.frame.details:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -margin, -30)
        else -- CENTER
            self.frame.title:SetPoint("TOP", self.frame, "TOP", 0, -10)
            self.frame.details:SetPoint("TOP", self.frame, "TOP", 0, -30)
        end
        self.frame.title:SetWidth(frameWidth - margin * 2)
        self.frame.details:SetWidth(frameWidth - margin * 2)

        -- 设置对齐方式
        self.frame.title:SetJustifyH(self.align)
        self.frame.details:SetJustifyH(self.align)

        -- 根据当前职业设置标题颜色
        local _, class = UnitClass("player")
        local color = RAID_CLASS_COLORS[class]
        if color then
            self.frame.title:SetTextColor(color.r, color.g, color.b)
        else
            self.frame.title:SetTextColor(1, 1, 1)
        end

        -- 排版变化后强制重写一次文本
        self.appliedAlign = self.align
        self.lastFirstLine = nil
        self.lastRestLines = nil
    end

    -- 仅在内容变化时写文本
    if self.lastFirstLine ~= firstLine then
        self.frame.title:SetText(firstLine)
        self.lastFirstLine = firstLine
    end
    if self.lastRestLines ~= restLines then
        self.frame.details:SetText(restLines)
        self.lastRestLines = restLines
    end

    -- 根据锁定状态设置鼠标启用/禁用（锁定则禁用鼠标，实现点击穿透）
    self.frame:EnableMouse(not self.locked)

    self.frame:Show()

    -- 启动实时移速刷新定时器（如果尚未启动）
    if not self.speedUpdater then
        self.speedUpdater = C_Timer.NewTicker(FAST_TICK, function() P:RefreshSpeedDisplay() end)
    end
end

-- 获取移动速度显示字符串（供聊天发送使用，总是返回字符串）
function P:DisplaySpeed()
    local ok, speed1 = pcall(UnitXP, "speed", "player")
    if ok and speed1 then
        local percent = speed1 * 100 / 7
        return string.format("移速: %.1f%%", percent)
    else
        return "移速: 数据不可用"
    end
end

-- 真正重建属性内容（会触发 BCS 各重量级取值函数，属于节流对象）
-- 注意：只写入缓存，不含移速行
function P:BuildBody()
    -- 悬浮窗独立计算：临时绕过 helper.lua 的「按 C 面板当前分页才计算」限制，
    -- 使显示内容不受角色面板当前选中的分类影响（用完立即还原）
    local prevForce = BCS.ForceCalculate
    BCS.ForceCalculate = true

    -- 统一走属性注册表：预设与自定义共用同一条输出链路，
    -- 保证勾选窗口里看到的顺序 = 悬浮窗顺序 = 聊天文本顺序
    local keys = self:GetSelectedKeys()
    local firstLine = nil          -- 第一个属性作为大字标题行
    local restLines = ""

    for i = 1, ArrayCount(keys) do
        local text = self:GetPropertyText(keys[i])
        if text then
            if firstLine == nil then
                firstLine = text
            elseif restLines == "" then
                restLines = text
            else
                restLines = restLines .. "\n" .. text
            end
        end
    end

    if firstLine == nil then
        firstLine = "（未选择属性）"
    end

    -- 还原按需计算开关
    BCS.ForceCalculate = prevForce

    -- 写入缓存并清除脏标记（移速行在 GetDisplayLines 中另行拼接）
    self.bodyFirstLine = firstLine
    self.bodyRestLines = restLines
    self.lastBodyRefresh = GetTime()
    self.bodyDirty = false
    self.forceNextBuild = false
end

-- 获取悬浮窗显示内容（返回第一行和其余行）
-- 节流：属性内容仅在「脏标记 + 最小间隔」或「超过最大间隔」时重建，
-- 其余刷新只重新拼接移速行（UnitXP 单次调用，开销可忽略）
function P:GetDisplayLines()
    local elapsed = GetTime() - (self.lastBodyRefresh or 0)

    if self.bodyRestLines == nil
        or self.forceNextBuild
        or (self.bodyDirty and elapsed >= MIN_BODY_REFRESH)
        or (elapsed >= MAX_BODY_REFRESH) then
        self:BuildBody()
    end

    local restLines = self.bodyRestLines or ""

    -- 移速行每拍实时拼接（UnitXP 单次调用，开销可忽略）；自定义模式下可被取消勾选
    if self:IsSpeedShown() then
        local speedLine = GetSpeedLine()
        if speedLine then
            if restLines == "" then
                restLines = speedLine
            else
                restLines = restLines .. "\n" .. speedLine
            end
        end
    end

    return self.bodyFirstLine, restLines
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

    -- 移速行：预设恒显示，自定义由勾选项决定
    if self:IsSpeedShown() then
        n = n + 1
        parts[n] = self:DisplaySpeed()
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
    if ItemSocre then
        local playerScore = ItemSocre:ScanUnit("player")
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
        return "命中: " .. math.floor(hit + 0.5) .. "%"
    else
        return "命中: 数据不可用"
    end
end

function P:DisplayRangedCritChance()
    if BCS then
        local success, crit = pcall(BCS.GetRangedCritChance, BCS)
        if success and crit then
            return "暴击: " .. string.format("%.2f", crit) .. "%"
        else
            return "暴击: 数据获取失败"
        end
    else
        return "暴击: 数据不可用"
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
    if not BCS then
        return "急速: 数据不可用"
    end

    local haste = nil

    -- 若安装了 Nampower，使用 GetUnitField 获取施法速度系数
    if BCS:IsNampowerReady() then
        local castSpeed = GetUnitField("player", "modCastSpeed")
        if castSpeed then
            haste = (1 / castSpeed - 1) * 100
        end
    end

    -- 回退到 BCS 内置估算
    if not haste then
        local val1, val2 = BCS:EstimateHaste()
        if val1 == nil then
            haste = BCS:GetHaste()
        else
            haste = val1
        end
    end

    if haste == nil then
        return "急速: 数据不可用"
    end

    return "急速: " .. string.format("%.2f", haste) .. "%"
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
        local speed = select(1, UnitRangedDamage("player"))
        return string.format("攻速: %.2f", math.floor(speed * 100 + 0.5) / 100)
    else
        local speed = select(1, UnitAttackSpeed("player"))
        return string.format("攻速: %.2f", speed)
    end
end

-- 以下三个防御类取值在自定义模式下可能被任意职业勾选，故统一 pcall 兜底，
-- 避免个别客户端缺少对应全局 API 时整行丢失
function P:DisplayDodge()
    local ok, dodge = pcall(GetDodgeChance)
    if ok and dodge then
        return "躲闪: " .. string.format("%.2f", dodge) .. "%"
    end
    return "躲闪: 数据不可用"
end

function P:DisplayParry()
    local ok, parry = pcall(GetParryChance)
    if ok and parry then
        return "招架: " .. string.format("%.2f", parry) .. "%"
    end
    return "招架: 数据不可用"
end

function P:DisplayBlock()
    local ok, block = pcall(GetBlockChance)
    if ok and block then
        return "格挡: " .. string.format("%.2f", block) .. "%"
    end
    return "格挡: 数据不可用"
end

function P:DisplayBlockValue()
    local ok, value = pcall(GetBlockValue)
    if ok and value then
        return "格挡值: " .. math.floor(value + 0.5)
    end
    return "格挡值: 数据不可用"
end

function P:DisplayArmor()
    if BCS then
        local base, effectiveArmor, armor = UnitArmor("player")
        return "护甲: " .. armor
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

-- ===== 自定义属性勾选窗口 =====
-- 与主配置窗口并排显示；勾选即时生效（只标脏，走节流路径）
local CBOX_ROW_H = 18          -- 每行高度
local CBOX_COLS  = 2           -- 列数
local CBOX_COL_W = 132         -- 每列宽度

local itemCount = ArrayCount(PROPERTY_LIST)
local rowCount  = math.ceil(itemCount / CBOX_COLS)

P.customFrame = CreateFrame("Frame", "BCSPropertiesPanelCustomFrame", UIParent)
P.customFrame:SetWidth(CBOX_COL_W * CBOX_COLS + 24)
P.customFrame:SetHeight(112 + rowCount * CBOX_ROW_H)
P.customFrame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    tile = true,
    tileSize = 16,
})
P.customFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
P.customFrame:SetBackdropBorderColor(0.5, 0.5, 0.5)
P.customFrame:SetMovable(true)
P.customFrame:EnableMouse(true)
P.customFrame:RegisterForDrag("LeftButton")
P.customFrame:SetScript("OnDragStart", function() P.customFrame:StartMoving() end)
P.customFrame:SetScript("OnDragStop", function() P.customFrame:StopMovingOrSizing() end)
P.customFrame:SetFrameStrata("DIALOG")
P.customFrame:Hide()

local customTitle = P.customFrame:CreateFontString(nil, "OVERLAY")
customTitle:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
customTitle:SetPoint("TOP", 0, -8)
customTitle:SetText("自定义属性")
customTitle:SetTextColor(1, 0.82, 0)

local customHint = P.customFrame:CreateFontString(nil, "OVERLAY")
customHint:SetFont(STANDARD_TEXT_FONT, 11)
customHint:SetPoint("TOP", 0, -27)
customHint:SetText("勾选即时生效，第一项显示为大字标题")
customHint:SetTextColor(0.7, 0.7, 0.7)

-- 避让排版：右侧放不下就改放左侧，避免小分辨率下被裁切
local function PositionCustomWindow()
    local f = P.customFrame
    local screenW = 1024
    if GetScreenWidth then
        local ok, w = pcall(GetScreenWidth)
        if ok and w and w > 0 then screenW = w end
    end
    f:ClearAllPoints()
    local frameRight = nil
    if P.mainFrame.GetRight then
        local ok, right = pcall(P.mainFrame.GetRight, P.mainFrame)
        if ok and right then frameRight = right end
    end
    if frameRight and (frameRight + f:GetWidth() + 10 > screenW - 4) then
        f:SetPoint("TOPRIGHT", P.mainFrame, "TOPLEFT", -10, 0)
    else
        f:SetPoint("TOPLEFT", P.mainFrame, "TOPRIGHT", 10, 0)
    end
end

-- 单个勾选行（点击整行切换；左侧方框用官方勾选贴图表示状态）
local function CreateCheckRow(parent, label, x, y, isChecked, onToggle)
    local row = CreateFrame("Button", nil, parent)
    row:SetWidth(CBOX_COL_W)
    row:SetHeight(CBOX_ROW_H)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)

    local box = row:CreateTexture(nil, "ARTWORK")
    box:SetWidth(14)
    box:SetHeight(14)
    box:SetPoint("LEFT", 0, 0)

    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture("Interface\\Buttons\\UI-CheckBox-Highlight")
    hl:SetWidth(14)
    hl:SetHeight(14)
    hl:SetPoint("LEFT", 0, 0)
    if hl.SetBlendMode then hl:SetBlendMode("ADD") end

    local text = row:CreateFontString(nil, "OVERLAY")
    text:SetFont(STANDARD_TEXT_FONT, 12, "OUTLINE")
    text:SetPoint("LEFT", box, "RIGHT", 3, 0)
    text:SetText(label)

    row.box = box
    row.text = text

    function row:Refresh()
        if isChecked() then
            box:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
            text:SetTextColor(1, 1, 1)
        else
            box:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
            text:SetTextColor(0.6, 0.6, 0.6)
        end
    end

    row:SetScript("OnClick", function()
        onToggle()
        row:Refresh()
    end)
    row:SetScript("OnEnter", function() text:SetTextColor(1, 0.82, 0) end)
    row:SetScript("OnLeave", function() row:Refresh() end)

    -- 注意：此处不要 Refresh()。本函数在文件加载期被调用，那时 BCSConfig /
    -- displayConfig 尚未就绪，提前读取会污染保存配置（勾选表被错误种子创建）。
    -- 外观统一由 P:RefreshCustomRows() 在窗口显示前刷新。
    return row
end

-- 按注册表生成所有属性勾选项（行优先两列：阅读顺序 = 显示顺序）
P.customRows = {}
for i = 1, itemCount do
    local item = PROPERTY_LIST[i]
    local key = item.key
    -- 不用 % 运算符，兼容 Lua 5.0
    local r = math.floor((i - 1) / CBOX_COLS)
    local col = (i - 1) - r * CBOX_COLS
    local x = 12 + col * CBOX_COL_W
    local y = -(46 + r * CBOX_ROW_H)

    P.customRows[i] = CreateCheckRow(P.customFrame, item.label, x, y,
        function()
            return P:EnsureCustomProps()[key] == true
        end,
        function()
            local props = P:EnsureCustomProps()
            if props[key] then
                props[key] = nil
            else
                props[key] = true
            end
            P:MarkDirty()   -- 只标脏，连点也不会触发多轮重扫
        end)
end

-- 移速行（仍在 0.2 秒节拍上实时刷新，仅受勾选开关控制）
P.customSpeedRow = CreateCheckRow(P.customFrame, "移速（实时）", 12, -(46 + rowCount * CBOX_ROW_H + 4),
    function()
        return P:EnsureCustomProps().speed ~= false
    end,
    function()
        local props = P:EnsureCustomProps()
        if props.speed == false then
            props.speed = true
        else
            props.speed = false
        end
        P:MarkDirty()
    end)

-- 全选
local selectAllBtn = CreateButton("全选", P.customFrame, "BOTTOM", P.customFrame, -95, 10, function()
    local props = P:EnsureCustomProps()
    for i = 1, itemCount do
        props[PROPERTY_LIST[i].key] = true
    end
    props.speed = true
    P:RefreshCustomRows()
    P:MarkDirty()
end)
selectAllBtn:SetWidth(78)

-- 清空
local clearAllBtn = CreateButton("清空", P.customFrame, "BOTTOM", P.customFrame, 0, 10, function()
    local props = P:EnsureCustomProps()
    for i = 1, itemCount do
        props[PROPERTY_LIST[i].key] = nil
    end
    props.speed = false
    P:RefreshCustomRows()
    P:MarkDirty()
end)
clearAllBtn:SetWidth(78)

-- 完成：立即刷新一次并收起窗口
local doneBtn = CreateButton("完成", P.customFrame, "BOTTOM", P.customFrame, 95, 10, function()
    P:RefreshNow()
    P.customFrame:Hide()
end)
doneBtn:SetWidth(78)

-- 供外部/测试访问
P.customButtons = { selectAll = selectAllBtn, clearAll = clearAllBtn, done = doneBtn }

-- 刷新所有勾选框外观（读配置表，与显示状态对齐）
function P:RefreshCustomRows()
    if self.customRows then
        for i = 1, ArrayCount(self.customRows) do
            self.customRows[i]:Refresh()
        end
    end
    if self.customSpeedRow then
        self.customSpeedRow:Refresh()
    end
end

-- 显示/隐藏勾选窗口
function P:ShowCustomWindow(show)
    if show then
        self:EnsureCustomProps()
        self:RefreshCustomRows()
        PositionCustomWindow()
        self.customFrame:Show()
    else
        self.customFrame:Hide()
    end
end

-- 事件处理
P.frame:RegisterEvent("ADDON_LOADED")
P.frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
P.frame:RegisterEvent("UNIT_AURA")

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
    elseif arg == "lock" then
        P.locked = true
        if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
        BCSConfig.PropertiesPanel.locked = true
        P:RefreshNow()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已锁定，点击穿透开启", 1, 1, 1)
    elseif arg == "unlock" then
        P.locked = false
        if not BCSConfig.PropertiesPanel then BCSConfig.PropertiesPanel = {} end
        BCSConfig.PropertiesPanel.locked = false
        P:RefreshNow()
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 悬浮窗已解锁，可拖动", 1, 1, 1)
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
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 已切换到自定义属性，请在勾选窗口中勾选要显示的条目", 1, 1, 1)
    elseif arg == "panel" or arg == "charpanel" or arg == "角色面板" then
        -- 切换「是否在角色面板中显示 BCS 属性」
        P:SetCharacterPanelEnabled(P.characterPanelEnabled == false)
    elseif arg:match("^align ") then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 未知的对齐方式，可用：left, center, right", 1, 0, 0)
    else
        -- 未知参数，提示用法
        DEFAULT_CHAT_FRAME:AddMessage("|cFFF5F54A PropertiesPanel:|r 用法：/mb 打开配置窗口，/mb custom 自定义属性勾选窗口，/mb off/hide 隐藏悬浮窗，/mb on/show 显示悬浮窗，/mb toggle/visible 切换显示，/mb align left/center/right 设置对齐方式，/mb lock/unlock/togglelock 锁定/解锁悬浮窗，/mb panel 切换是否在角色面板（按 C）中显示 BCS 属性", 1, 0, 0)
    end
end

SLASH_PROPERTIESPANEL1 = "/mb"
SlashCmdList["PROPERTIESPANEL"] = HandleSlashCommand

-- 初始隐藏主窗口
P.mainFrame:Hide()