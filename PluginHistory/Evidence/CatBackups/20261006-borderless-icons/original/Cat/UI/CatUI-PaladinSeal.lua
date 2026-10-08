-- 审判控制：保留原有选项编号，新增公正与面板外观设置。
local ADDON_NAME = "CatUI-PaladinSeal"
local PaladinSealSettingsUIVersion = 2
local updating = false
local positionRestored = false
local activeConfigs = {}

CatPaladinSeal = CreateFrame("Frame", ADDON_NAME.."Frame", UIParent)
CatPaladinSeal:Hide()
CatPaladinSeal:SetWidth(330)
CatPaladinSeal:SetHeight(138)
CatPaladinSeal:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
CatPaladinSeal:SetFrameLevel(1)
CatPaladinSeal:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CatPaladinSeal:SetBackdropColor(0.1, 0.1, 0.2, 0.7)
CatPaladinSeal:SetScale(0.8)
CatPaladinSeal:EnableMouse(true)
CatPaladinSeal:SetMovable(true)

local function SavePosition()
    if not MPPaladinSealSaved then return end
    local left, top = CatPaladinSeal:GetLeft(), CatPaladinSeal:GetTop()
    if not left or not top then return end
    local ratio = CatPaladinSeal:GetEffectiveScale() / UIParent:GetEffectiveScale()
    MPPaladinSealSaved.PositionX = left * ratio
    MPPaladinSealSaved.PositionY = top * ratio
end

local function ApplyScale(value)
    if CatPaladinSeal:GetScale() == value then return end
    -- 保持屏幕上的左上角；不能让承载滑条的窗口跟着缩放。
    local left, top = CatPaladinSeal:GetLeft(), CatPaladinSeal:GetTop()
    local oldScale = CatPaladinSeal:GetEffectiveScale()
    CatPaladinSeal:SetScale(value)
    if left and top then
        local ratio = oldScale / CatPaladinSeal:GetEffectiveScale()
        CatPaladinSeal:ClearAllPoints()
        CatPaladinSeal:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left * ratio, top * ratio)
        if positionRestored then SavePosition() end
    end
end

-- 只有标题栏接受拖动，滑条和图标不会触发整个窗口移动。
local dragHandle = CreateFrame("Frame", nil, CatPaladinSeal)
dragHandle:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", 0, 0)
dragHandle:SetWidth(225)
dragHandle:SetHeight(28)
dragHandle:EnableMouse(true)
dragHandle:RegisterForDrag("LeftButton")
dragHandle:SetScript("OnDragStart", function()
    if MPPaladinSealSaved and MPPaladinSealSaved.Locked == 1 then return end
    CatPaladinSeal:StartMoving()
end)
dragHandle:SetScript("OnDragStop", function()
    CatPaladinSeal:StopMovingOrSizing()
    SavePosition()
end)

local function Label(parent, text, x, y)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetText(text)
    return label
end
local title = Label(dragHandle, "|cFFF58CBA圣骑士 - 审判控制|r", 10, -10)
local closeButton = CreateFrame("Button", nil, CatPaladinSeal, "UIPanelCloseButton")
closeButton:SetWidth(32)
closeButton:SetHeight(32)
closeButton:SetPoint("TOPRIGHT", CatPaladinSeal, "TOPRIGHT", -5, -2)
closeButton:SetScript("OnClick", function()
    CatPaladinSeal:Hide()
    MPPublicSaved.PaladinSealDisplay = 0
end)

local justiceButtons, sealButtons = {}, {}
local function SetIconSelected(button, selected)
    -- 选中亮度用 RGB 表示，与整个窗口的透明度分开。
    -- 只调整颜色，不重设子按钮/纹理 alpha；整体透明度由窗口统一应用。
    local brightness = 0.3
    if selected then brightness = 1 end
    button.icon:SetVertexColor(brightness, brightness, brightness)
    button.text:SetTextColor(brightness, brightness, brightness)
end
local function SelectButtons(buttons)
    for _, button in ipairs(buttons) do
        button.MPCatRefreshAppearance()
    end
end
local function IconButton(name, text, texture, x, y, field, value, buttons)
    local button = CreateFrame("Button", ADDON_NAME..name, CatPaladinSeal)
    button.selectionValue = value
    button:SetWidth(36)
    button:SetHeight(36)
    button:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", x, y)
    -- ARTWORK 位于 pfUI 深色按钮底板上方；使用匿名纹理避免全局名称冲突。
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints()
    button.icon:SetTexture("Interface\\Icons\\"..texture)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.text:SetPoint("BOTTOM", button, "BOTTOM", 0, 5)
    button.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    button.text:SetTextColor(1, 1, 1)
    button.text:SetText(text)
    button.MPCatRefreshAppearance = function()
        SetIconSelected(button, MPPaladinSealSaved and MPPaladinSealSaved[field] == value)
    end
    button.MPCatRefreshAppearance()
    table.insert(buttons, button)
    button:SetScript("OnClick", function()
        local selected = value
        if MPPaladinSealSaved[field] == value then
            selected = -1
        end
        MPPaladinSealSaved[field] = selected
        if field == "Seal" and type(MPCatPaladinTankManualSealChanged) == "function" then MPCatPaladinTankManualSealChanged() end
        if field == "Seal" then MPCatPaladinSyncRetSeal() end
        SelectButtons(buttons)
    end)
    return button
end
Label(CatPaladinSeal, "审判", 10, -50)
IconButton("JusticeButtonNormal", "无", "Spell_Nature_WispSplode", 50, -40, "Justice", 0, justiceButtons)
IconButton("JusticeButtonWisdom", "智慧", "Spell_Holy_RighteousnessAura", 95, -40, "Justice", 1, justiceButtons)
IconButton("JusticeButtonRight", "光明", "Spell_Holy_HealingAura", 140, -40, "Justice", 2, justiceButtons)
IconButton("JusticeButtonCrusader", "十字军", "Spell_Holy_HolySmite", 185, -40, "Justice", 3, justiceButtons)
IconButton("JusticeButtonFair", "公正", "Spell_Holy_SealOfWrath", 230, -40, "Justice", 4, justiceButtons)
local sealLabel = Label(CatPaladinSeal, "圣印", 10, -100)
local outputSeal = IconButton("SealButtonOutput", "无", "Spell_Nature_WispSplode", 50, -90, "Seal", -1, sealButtons)
outputSeal.MPCatRefreshAppearance = function()
    local value = MPPaladinSealSaved and MPPaladinSealSaved.Seal
    if value == 4 then
        outputSeal.icon:SetTexture("Interface\\Icons\\Ability_ThunderBolt")
        outputSeal.text:SetText("正义")
    elseif value == 5 then
        outputSeal.icon:SetTexture("Interface\\Icons\\Ability_Warrior_InnerRage")
        outputSeal.text:SetText("命令")
    else
        outputSeal.icon:SetTexture("Interface\\Icons\\Spell_Nature_WispSplode")
        outputSeal.text:SetText("无")
    end
    SetIconSelected(outputSeal, value == 4 or value == 5)
end
outputSeal.MPCatRefreshAppearance()
outputSeal:SetScript("OnClick", function()
    local value = MPPaladinSealSaved.Seal
    if value == 4 then value = 5 elseif value == 5 then value = -1 else value = 4 end
    MPPaladinSealSaved.Seal = value
    if type(MPCatPaladinTankManualSealChanged) == "function" then MPCatPaladinTankManualSealChanged() end
    MPCatPaladinSyncRetSeal()
    SelectButtons(sealButtons)
end)
IconButton("SealButtonWisdom", "智慧", "Spell_Holy_RighteousnessAura", 95, -90, "Seal", 1, sealButtons)
IconButton("SealButtonRight", "光明", "Spell_Holy_HealingAura", 140, -90, "Seal", 2, sealButtons)
IconButton("SealButtonCrusader", "十字军", "Spell_Holy_HolySmite", 185, -90, "Seal", 3, sealButtons)
IconButton("SealButtonFair", "公正", "Spell_Holy_SealOfWrath", 230, -90, "Seal", 6, sealButtons)

local function Slider(name, x, y, width, minValue, maxValue, onChange, parent)
    parent = parent or CatPaladinSeal
    local slider = CreateFrame("Slider", ADDON_NAME..name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    slider:SetWidth(width)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(1)
    _G[slider:GetName().."Low"]:Hide()
    _G[slider:GetName().."High"]:Hide()
    local text = _G[slider:GetName().."Text"]
    slider:SetScript("OnValueChanged", function()
        if updating or not MPPaladinSealSaved then return end
        local value = math.floor(slider:GetValue() + 0.5)
        value = math.max(minValue, math.min(maxValue, value))
        if slider:GetValue() ~= value then
            updating = true
            slider:SetValue(value)
            updating = false
        end
        onChange(value, text)
    end)
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function()
        slider:SetValue(math.max(minValue, math.min(maxValue, slider:GetValue() + arg1)))
    end)
    return slider, text
end

-- 独立窗口保持固定尺寸和透明度，拖动缩放滑条时滑条自身不会位移。
CatPaladinSealSettings = CreateFrame("Frame", ADDON_NAME.."AppearanceFrame", UIParent)
CatPaladinSealSettings:Hide()
CatPaladinSealSettings:SetWidth(330)
CatPaladinSealSettings:SetHeight(195)
CatPaladinSealSettings:SetScale(0.9)
CatPaladinSealSettings:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
if CatPaladinSealSettings.SetClampedToScreen then CatPaladinSealSettings:SetClampedToScreen(true) end
CatPaladinSealSettings:SetFrameLevel(3)
CatPaladinSealSettings:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
CatPaladinSealSettings:SetBackdropColor(0.1, 0.1, 0.2, 0.9)
CatPaladinSealSettings:EnableMouse(true)
CatPaladinSealSettings:SetMovable(true)
local settingsDrag = CreateFrame("Frame", nil, CatPaladinSealSettings)
settingsDrag:SetPoint("TOPLEFT", CatPaladinSealSettings, "TOPLEFT", 0, 0)
settingsDrag:SetWidth(280)
settingsDrag:SetHeight(28)
settingsDrag:EnableMouse(true)
settingsDrag:RegisterForDrag("LeftButton")
settingsDrag:SetScript("OnDragStart", function() CatPaladinSealSettings:StartMoving() end)
settingsDrag:SetScript("OnDragStop", function() CatPaladinSealSettings:StopMovingOrSizing() end)
local settingsTitle = Label(settingsDrag, "审判控制 - 外观设置", 10, -10)
local settingsClose = CreateFrame("Button", nil, CatPaladinSealSettings, "UIPanelCloseButton")
settingsClose:SetWidth(32)
settingsClose:SetHeight(32)
settingsClose:SetPoint("TOPRIGHT", CatPaladinSealSettings, "TOPRIGHT", -5, -2)
settingsClose:SetScript("OnClick", function() CatPaladinSealSettings:Hide() end)
local settingsButton = CreateFrame("Button", ADDON_NAME.."SettingsButton", CatPaladinSeal, "UIPanelButtonTemplate")
settingsButton:SetPoint("TOPRIGHT", CatPaladinSeal, "TOPRIGHT", -43, -8)
settingsButton:SetWidth(54)
settingsButton:SetHeight(20)
settingsButton:SetText("设置")
settingsButton:SetScript("OnClick", function()
    if CatPaladinSealSettings:IsVisible() then CatPaladinSealSettings:Hide() return end
    CatPaladinSealSettings:Show()
end)
CatPaladinSeal:SetScript("OnHide", function() CatPaladinSealSettings:Hide() end)

-- 标题、设置文字和关闭图标共用标题栏中心线；关闭按钮换肤缩小后仍保持对齐。
local function AlignHeader(frame, label, close)
    label:ClearAllPoints()
    label:SetPoint("LEFT", frame, "TOPLEFT", 10, -18)
    close:ClearAllPoints()
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -18 + close:GetHeight() / 2)
end
local function AlignHeaders()
    AlignHeader(CatPaladinSeal, title, closeButton)
    AlignHeader(CatPaladinSealSettings, settingsTitle, settingsClose)
    settingsButton:ClearAllPoints()
    settingsButton:SetPoint("RIGHT", closeButton, "LEFT", -6, 0)
end
AlignHeaders()

local consecration = CreateFrame("Button", ADDON_NAME.."ConsecrationButton", CatPaladinSeal)
consecration:SetPoint("TOPLEFT", CatPaladinSeal, "TOPLEFT", 285, -65)
consecration:SetWidth(36)
consecration:SetHeight(36)
consecration.icon = consecration:CreateTexture(nil, "ARTWORK")
consecration.icon:SetAllPoints()
consecration.icon:SetTexture("Interface\\Icons\\Spell_Holy_InnerFire")
consecration:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
consecration:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
consecration.text = consecration:CreateFontString(nil, "OVERLAY", "GameFontNormal")
consecration.text:SetPoint("BOTTOM", consecration, "BOTTOM", 0, 3)
consecration.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
consecration.text:SetTextColor(1, 1, 1)
local consecrationLabels = { [0] = "关闭", [1] = "低", [2] = "中", [3] = "高" }
local function ConsecrationMode()
    if MPPaladinSealSaved.Consecration ~= 1 then return 0 end
    return MPPaladinSealSaved.ConsecrationPriority
end
local function RefreshConsecrationIcon()
    local mode = ConsecrationMode()
    consecration.text:SetText("奉献\n"..consecrationLabels[mode])
    SetIconSelected(consecration, mode ~= 0)
end
consecration.MPCatRefreshAppearance = function()
    if not MPPaladinSealSaved then
        consecration.text:SetText("奉献\n关闭")
        SetIconSelected(consecration, false)
        return
    end
    RefreshConsecrationIcon()
end
consecration.MPCatRefreshAppearance()
local function ChangeConsecration(direction)
    local mode = math.mod(ConsecrationMode() + direction + 4, 4)
    if mode == 0 then
        MPPaladinSealSaved.Consecration = 0
    else
        MPPaladinSealSaved.Consecration = 1
        MPPaladinSealSaved.ConsecrationPriority = mode
    end
    MPCatPaladinSyncConsecration("Consecration", MPPaladinSealSaved.Consecration)
    RefreshConsecrationIcon()
end
consecration:RegisterForClicks("LeftButtonUp", "RightButtonUp")
consecration:SetScript("OnClick", function()
    if arg1 == "RightButton" then ChangeConsecration(-1) else ChangeConsecration(1) end
end)
consecration:EnableMouseWheel(true)
consecration:SetScript("OnMouseWheel", function()
    if arg1 > 0 then ChangeConsecration(1) elseif arg1 < 0 then ChangeConsecration(-1) end
end)
function MPCatPaladinSealRefreshIcons()
    if MPCatPaladinTankRecoveryActive then sealLabel:SetText("圣印\n|cff66ccff回蓝|r") else sealLabel:SetText("圣印") end
    SelectButtons(justiceButtons)
    SelectButtons(sealButtons)
    consecration.MPCatRefreshAppearance()
end
-- 背景透明度独立于图标、文字和按钮；兼容原生背景及 pfUI 的独立背景框。
function MPCatPaladinSealApplyAppearance()
    AlignHeaders()
    if not MPPaladinSealSaved or type(MPPaladinSealSaved.Alpha) ~= "number" then return end
    local opacity = MPPaladinSealSaved.Alpha
    CatPaladinSeal:SetAlpha(1)
    if CatPaladinSeal.backdrop then
        local background = CatPaladinSeal.backdrop
        local red, green, blue = background:GetBackdropColor()
        local baseAlpha = 0.75
        if pfUI and pfUI.api and pfUI.api.GetStringColor and pfUI_config then
            local _, _, _, configuredAlpha = pfUI.api.GetStringColor(pfUI_config.appearance.border.background)
            baseAlpha = math.min(baseAlpha, tonumber(configuredAlpha) or baseAlpha)
        end
        background:SetAlpha(1)
        background:SetBackdropColor(red, green, blue, baseAlpha * opacity)
    else
        CatPaladinSeal:SetBackdropColor(0.1, 0.1, 0.2, 0.7 * opacity)
    end
    MPCatPaladinSealRefreshIcons()
end
local scale, scaleText = Slider("Scale", 20, -60, 290, 60, 150, function(value, text)
    MPPaladinSealSaved.Scale = value / 100
    ApplyScale(MPPaladinSealSaved.Scale)
    text:SetText("大小："..value.."%")
end, CatPaladinSealSettings)
local alpha, alphaText = Slider("Transparency", 20, -112, 290, 0, 70, function(value, text)
    MPPaladinSealSaved.Alpha = 1 - value / 100
    MPCatPaladinSealApplyAppearance()
    text:SetText("背景透明度："..value.."%")
end, CatPaladinSealSettings)
local lock = CreateFrame("CheckButton", ADDON_NAME.."LockPosition", CatPaladinSealSettings, "UICheckButtonTemplate")
lock:SetPoint("TOPLEFT", CatPaladinSealSettings, "TOPLEFT", 14, -150)
local lockText = lock:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lockText:SetPoint("LEFT", lock, "RIGHT", 0, 0)
lockText:SetText("锁定面板位置")
local function RefreshLock()
    local locked = MPPaladinSealSaved.Locked == 1
    lock:SetChecked(locked)
    CatPaladinSeal:SetMovable(not locked)
    dragHandle:EnableMouse(not locked)
end
lock:SetScript("OnClick", function()
    if this:GetChecked() then MPPaladinSealSaved.Locked = 1 else MPPaladinSealSaved.Locked = 0 end
    CatPaladinSeal:StopMovingOrSizing()
    SavePosition()
    RefreshLock()
end)

function MPCatPaladinSealReset()
    MPPaladinSealSaved.Version = PaladinSealSettingsUIVersion
    MPPaladinSealSaved.Seal = -1
    MPPaladinSealSaved.Justice = -1
    MPPaladinSealSaved.Consecration = 1
    MPPaladinSealSaved.ConsecrationPriority = 1
    MPPaladinSealSaved.Scale = 0.8
    MPPaladinSealSaved.Alpha = 1
    MPPaladinSealSaved.SharedConsecration = 1
    MPPaladinSealSaved.Locked = 0
end

local function ValidValue(value, defaultValue, minimum, maximum, integer)
    if type(value) ~= "number" or value ~= value then return defaultValue end
    value = math.max(minimum, math.min(maximum, value))
    if integer then value = math.floor(value + 0.5) end
    return value
end

function MPCatPaladinSealInit()
    if updating then return end
    if not MPPaladinSealSaved then
        MPPaladinSealSaved = {}
    end
    -- 仅补齐新字段，保留旧选项编号及已有角色设置。
    local saved = MPPaladinSealSaved
    -- 打开窗口、改透明度都不能触发整组重置。版本变化也只增量迁移。
    saved.Version = PaladinSealSettingsUIVersion
    saved.Justice = ValidValue(saved.Justice, -1, -1, 4, true)
    saved.Seal = ValidValue(saved.Seal, -1, -1, 6, true)
    if saved.Seal == 0 then saved.Seal = -1 end
    saved.Locked = saved.Locked == 1 and 1 or 0
    saved.Consecration = ValidValue(saved.Consecration, 1, 0, 2, true)
    if saved.SharedConsecration ~= 1 then
        -- 旧版“按配置”沿用原同步对象的开关，其余已有选择直接迁移。
        if saved.Consecration == 2 then
            local profiles = MPPaladinCJSaved
            if saved.ControlRole == "TANK" then profiles = MPPaladinTankSaved end
            local old = profiles and profiles[saved.ControlConfig or 1]
            saved.Consecration = old and old.Consecration or 1
        end
        saved.SharedConsecration = 1
    end
    saved.Consecration = ValidValue(saved.Consecration, 1, 0, 1, true)
    saved.ConsecrationPriority = ValidValue(saved.ConsecrationPriority, 1, 1, 3, true)
    saved.Scale = ValidValue(saved.Scale, 0.8, 0.6, 1.5)
    saved.Alpha = ValidValue(saved.Alpha, 1, 0.3, 1)
    updating = true
    scale:SetValue(math.floor(saved.Scale * 100 + 0.5))
    alpha:SetValue(math.floor((1 - saved.Alpha) * 100 + 0.5))
    updating = false
    RefreshConsecrationIcon()
    RefreshLock()
    scaleText:SetText("大小："..math.floor(saved.Scale * 100 + 0.5).."%")
    alphaText:SetText("背景透明度："..math.floor((1 - saved.Alpha) * 100 + 0.5).."%")
    ApplyScale(saved.Scale)
    if not positionRestored then
        positionRestored = true
        if type(saved.PositionX) == "number" and type(saved.PositionY) == "number" then
            local ratio = UIParent:GetEffectiveScale() / CatPaladinSeal:GetEffectiveScale()
            CatPaladinSeal:ClearAllPoints()
            CatPaladinSeal:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.PositionX * ratio, saved.PositionY * ratio)
        end
    end
    MPCatPaladinSealApplyAppearance()
    MPCatPaladinSyncRetSeal()
end

-- 一套面板选择同时服务两种宏；只同步正在使用/编辑的配置。
function MPCatPaladinControlUpdating() return updating end

-- 公共圣印编号与旧惩戒骑输出圣印编号不同；保留旧的正义/命令编号。
local retSealValues = { [1] = 4, [2] = 5, [3] = 6, [4] = 2, [5] = 3, [6] = 7 }
function MPCatPaladinSyncRetSeal(config)
    if not MPPaladinSealSaved then return end
    config = ValidValue(config or activeConfigs.RET or MPPaladinCJConfig, 1, 1, 3, true)
    local settings = MPPaladinCJSaved and MPPaladinCJSaved[config]
    if not settings then return end
    local value = retSealValues[MPPaladinSealSaved.Seal]
    local enabled = value and 1 or 0
    local changed = settings.Seal ~= enabled or (value and settings.Seal_Value ~= value)
    settings.Seal = enabled
    if value then settings.Seal_Value = value end
    if changed and MPCatRefreshPaladinCJSeal then
        local previous = updating
        updating = true
        MPCatRefreshPaladinCJSeal(config)
        updating = previous
    end
end

function MPCatPaladinApplyControl(role, config)
    if not MPPaladinSealSaved or MPPaladinSealSaved.SharedConsecration ~= 1 then MPCatPaladinSealInit() end
    config = ValidValue(config, 1, 1, 3, true)
    activeConfigs[role] = config
    if role == "RET" then MPCatPaladinSyncRetSeal(config) end
    local profiles = MPPaladinCJSaved
    local refresh = MPCatRefreshPaladinCJConsecration
    if role == "TANK" then profiles = MPPaladinTankSaved; refresh = MPCatRefreshPaladinTankConsecration end
    local settings = profiles and profiles[config]
    if not settings then return end
    local changed = settings.Consecration ~= MPPaladinSealSaved.Consecration
        or settings.Consecration_Priority ~= MPPaladinSealSaved.ConsecrationPriority
    settings.Consecration = MPPaladinSealSaved.Consecration
    settings.Consecration_Priority = MPPaladinSealSaved.ConsecrationPriority
    if changed and refresh then
        local previous = updating
        updating = true
        refresh(config)
        updating = previous
    end
end

function MPCatPaladinSyncConsecration(key, value, role, config)
    if updating then return end
    if not MPPaladinSealSaved then MPCatPaladinSealInit() end
    if key == "Consecration" then
        MPPaladinSealSaved.Consecration = ValidValue(value, 1, 0, 1, true)
    elseif key == "Consecration_Priority" then
        MPPaladinSealSaved.ConsecrationPriority = ValidValue(value, 1, 1, 3, true)
    else
        return
    end
    if role then activeConfigs[role] = ValidValue(config, 1, 1, 3, true) end
    MPCatPaladinApplyControl("RET", activeConfigs.RET or MPPaladinCJConfig or 1)
    MPCatPaladinApplyControl("TANK", activeConfigs.TANK or MPPaladinTankConfig or 1)
    if role then
        -- 设置界面的点击需要反向刷新公共面板，但不会改变窗口位置。
        MPCatPaladinSealInit()
    end
end

CatPaladinSeal:SetScript("OnShow", function() MPCatPaladinSealInit() end)

-- 登录/重载后主动恢复外观，不依赖玩家重新打开面板或移动滑条。
CatPaladinSeal:RegisterEvent("PLAYER_ENTERING_WORLD")
CatPaladinSeal:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then MPCatPaladinSealInit() end
end)
