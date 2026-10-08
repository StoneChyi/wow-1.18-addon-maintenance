-- ============================================
--  无双交互  WushuangLoot.lua  (v1.2)
--  配合 wsloot.dll (hook UnitXP dispatch 0x517350)
--
--  命令: /无双交互   输入一次, 执行一次交互
-- ============================================

local COLOR = "|cff00ff00[无双交互]|r"

-- ========== 按键绑定显示名 (游戏内「按键设置」面板) ==========
-- 内部标识符仍是 WSLootPick (Bindings.xml 里 name="WSLootPick")，
-- 这里只控制面板里展示的中文名称。
BINDING_HEADER_WUSHUANGLOOT = "无双交互"
BINDING_NAME_WSLootPick = "无双交互"

-- ========== 屏幕分辨率适配：以1920x1080为设计基准 ==========
-- 2K(2560x1440) 多是 VanillaFixes 类模组适配出来的，gxResolution 的格式/取值无法保证（很可能解析不出高度）。
-- 因此双保险：优先解析 gxResolution 高度；解析不出时用 GetScreenHeight()（虚拟高度）兜底。
-- 任一信号显示超过 1080p（>1300）即视为 2K，套用 2K 专用尺寸 x1.333。1080p 及以下走原逻辑。
local xyRes = GetCVar("gxResolution") or ""
local _, _, _, xyResH = string.find(xyRes, "(%d+)[xX%*](%d+)")
xyResH = tonumber(xyResH)
local xyScrH = GetScreenHeight() or 1080
local WSLootScreenScale
if (xyResH and xyResH > 1080) or xyScrH > 1300 then
    WSLootScreenScale = 1440 / 1080  -- 2K 专用：设计尺寸 x 1.333
else
    WSLootScreenScale = xyScrH / 1080  -- 原逻辑，1080p 及以下保持不变
end

-- 勾选状态持久化 (SavedVariables, 由 WoW 在 reload/退出时自动落盘)
-- 声明见 WushuangLoot.toc: ## SavedVariables: WushuangLootDB
WushuangLootDB = WushuangLootDB or {}

local function Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(COLOR .. " " .. msg)
    end
end

-- DLL 是否已连接 (wsloot.dll 注册的 Lua 表)
local function DllReady()
    return type(WSLoot) == "table" and type(WSLoot.Loot) == "function"
end

-- 触发 DLL 注册 (调用 UnitXP 会触发 detour 里的 luaL_openlib)
local function EnsureRegistered()
    if not DllReady() then
        UnitXP("player")
    end
    return DllReady()
end

-- 保存所有复选框引用, 供 CalcMask 使用
local checkboxes = {}

-- 计算当前掩码 (勾选的类别 bit 之和)
local function CalcMask()
    local m = 0
    for _, cb in ipairs(checkboxes) do
        if cb:GetChecked() then
            m = m + cb.bit
        end
    end
    -- "交互指定NPC" 也要带上 NPC 位 BIT_NPC(16),
    -- 否则 ApplyMask 会把 DLL 里 SetFilter 置好的 16 位清零, 过滤分支不执行
    if WushuangLootDB and WushuangLootDB.filterOn == 1 then
        m = m + 16
    end
    return m
end

-- 应用掩码到 DLL
local setMaskWarned = false
local function ApplyMask()
    EnsureRegistered()
    if DllReady() then
        if WSLoot.SetMask then
            WSLoot.SetMask(CalcMask())
        elseif not setMaskWarned then
            setMaskWarned = true
            Print("|cffff0000wsloot.dll 版本过低: 缺少 SetMask，分类勾选将不生效|r")
        end
    end
end

-- 执行一次交互
local function DoOnce()
    EnsureRegistered()
    if DllReady() then
        ApplyMask()      -- 执行前按当前所有复选框勾选状态同步掩码
        WSLoot.Loot()
        return true
    end
    return false
end

-- 斜杠命令: 输入一次 /无双交互, 执行一次
local function HandleSlash()
    if not DoOnce() then
        Print("|cffff0000未检测到 wsloot.dll，请先将 DLL 注入游戏进程|r")
    end
end

SLASH_WSLoot1 = "/无双交互"
SlashCmdList["WSLoot"] = HandleSlash

-- 按键绑定安全包装: 绑定快捷键时调用, 无 DLL 给提示而非报错
-- (Bindings.xml 里 WSLootPick 绑定执行 WSLootBindPick())
function WSLootBindPick()
    if not DoOnce() then
        Print("|cffff0000未检测到 wsloot.dll，请先将 DLL 注入游戏进程|r")
    end
end

-- ==================== 设置界面 (主界面 + 复选框) ====================
local TYPES = {
    { label = "尸体", bit = 1, tip = "可拾取的怪物尸体" },
    { label = "道具", bit = 8, tip = "箱子/矿石/草药等可交互物体" },
    { label = "商人", bit = 16, tip = "友善可对话的 NPC" },
}

local WSLootFrame = CreateFrame("Frame", "WSLootFrame", UIParent)
WSLootFrame:SetFrameStrata("DIALOG")
WSLootFrame:SetPoint("CENTER", 0, 0)
WSLootFrame:SetWidth(150)
WSLootFrame:SetHeight(250)
WSLootFrame:SetScale(WSLootScreenScale * 0.8)   -- 分辨率适配 × 用户缩放(80%)
WSLootFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
WSLootFrame:Hide()
WSLootFrame:SetMovable(true)
WSLootFrame:EnableMouse(true)
WSLootFrame:EnableKeyboard(true)
WSLootFrame:RegisterForDrag("LeftButton")
WSLootFrame:SetScript("OnDragStart", function() WSLootFrame:StartMoving() end)
WSLootFrame:SetScript("OnDragStop", function() WSLootFrame:StopMovingOrSizing() end)
tinsert(UISpecialFrames, "WSLootFrame")

local title = WSLootFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("无双交互设置")

local closeBtn = CreateFrame("Button", nil, WSLootFrame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -3, -3)
closeBtn:SetScript("OnClick", function() WSLootFrame:Hide() end)

for i, t in ipairs(TYPES) do
    local bit = t.bit
    local cb = CreateFrame("CheckButton", "WSLootCB"..i, WSLootFrame, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", 15, -50 - (i - 1) * 28)
    cb:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
    cb:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
    cb:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
    cb:SetChecked(true)  -- 默认勾选, 实际状态在 VARIABLES_LOADED 后从存档恢复
    cb.bit = bit
    cb.label = t.label
    checkboxes[i] = cb
    local label = t.label
    local tip = t.tip or "勾选启用该类自动交互"
    cb:SetScript("OnClick", function()
        WushuangLootDB = WushuangLootDB or {}
        WushuangLootDB[label] = cb:GetChecked() and 1 or 0
        -- 商人与"交互指定NPC"互斥: 勾选商人时取消对方
        if label == "商人" and cb:GetChecked() and WSLootFilterCB then
            WSLootFilterCB:SetChecked(false)
            WushuangLootDB.filterOn = 0
            -- 同步关闭 DLL 端过滤器, 否则仍按指定NPC模式 (直接调 DLL 全局表, 不依赖 local ApplyFilter)
            if WSLoot and WSLoot.FilterOn then WSLoot.FilterOn(0) end
        end
        ApplyMask()
    end)
    cb:SetScript("OnEnter", function()
        GameTooltip:SetOwner(cb, "ANCHOR_RIGHT")
        GameTooltip:SetText(label, 1, 1, 1)
        GameTooltip:AddLine(tip, 1, 1, 1)
        GameTooltip:Show()
    end)
    cb:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    local text = cb:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("LEFT", cb, "RIGHT", 5, 0)
    text:SetText(label)
end

-- ==================== NPC 名字过滤 UI ====================
-- 复选框 "交互指定NPC" + 文字输入框 (模糊匹配, 逗号分隔多词)
-- 位置: 3 个分类复选框占 3 行 (每行28), 从 -50 起, 第4行约 -138

-- 把关键词 hex 编码成纯 ASCII 再逐字节传 (参考 XyTracker 的 XyHexEncode)
-- 规避 WoW Lua 中文在字节边界处的损坏: 中文先编码成 %02x 的 ASCII 串, DLL 端还原
local function HexEncode(s)
    if not s or s == "" then return "" end
    local t = {}
    for i = 1, string.len(s) do
        t[i] = string.format("%02x", string.byte(s, i))
    end
    return table.concat(t)
end

-- 传 hex 字符串 (纯 ASCII, 每个字符都是单字节, 不会在 Lua 边界损坏)
-- DLL 端 WSLoot.SetFilter(b1,b2,...,bN) 收到后还原成原始 UTF-8 字节
local function PushFilterBytes(txt)
    if not (WSLoot and WSLoot.SetFilter) then return end
    txt = txt or ""
    -- 末尾补逗号: DLL 端 g_filter 缓冲区在末词后会残留上一轮脏字节,
    -- 补逗号可把脏字节隔在最后一个词之外, 避免污染末词匹配 (等价于手动在结尾加逗号)
    if txt ~= "" and string.sub(txt, -1) ~= "," then
        txt = txt .. ","
    end
    local hex = HexEncode(txt)
    if hex == "" then
        WSLoot.SetFilter()   -- 空调用 = 清空关键词
        return
    end
    local args = {}
    for i = 1, string.len(hex) do
        args[i] = string.byte(hex, i)
    end
    WSLoot.SetFilter(unpack(args))
end

-- 同步过滤设置到 DLL (使用全局 frame 名, 避免 local 初始化顺序问题)
local function ApplyFilter()
    EnsureRegistered()
    if not DllReady() then return end
    local ed = WSLootFilterEdit
    local cb = WSLootFilterCB
    if not ed then return end
    local txt = ed:GetText() or ""
    PushFilterBytes(txt)
    if WSLoot.FilterOn and cb and cb:GetChecked() then
        WSLoot.FilterOn(1)
    elseif WSLoot.FilterOn then
        WSLoot.FilterOn(0)
    end
end

local filterCB = CreateFrame("CheckButton", "WSLootFilterCB", WSLootFrame, "UICheckButtonTemplate")
filterCB:SetPoint("TOPLEFT", 15, -138)
filterCB:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
filterCB:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
filterCB:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD")
filterCB:SetChecked(false)
filterCB:SetScript("OnClick", function()
    WushuangLootDB = WushuangLootDB or {}
    WushuangLootDB.filterOn = filterCB:GetChecked() and 1 or 0
    -- 与商人互斥: 勾选交互指定NPC时取消商人复选框
    if filterCB:GetChecked() then
        for _, cb in ipairs(checkboxes) do
            if cb.bit == 16 then   -- 商人
                cb:SetChecked(false)
                WushuangLootDB[cb.label] = 0
            end
        end
        ApplyMask()
    end
    ApplyFilter()
end)
filterCB:SetScript("OnEnter", function()
    GameTooltip:SetOwner(filterCB, "ANCHOR_RIGHT")
    GameTooltip:SetText("交互指定NPC")
    GameTooltip:AddLine("勾选后，商人(NPC)交互只匹配输入框内的名字(模糊匹配，逗号分隔多个)", 1, 1, 1)
    GameTooltip:Show()
end)
filterCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
local filterTextLabel = filterCB:CreateFontString(nil, "ARTWORK", "GameFontNormal")
filterTextLabel:SetPoint("LEFT", filterCB, "RIGHT", 5, 0)
filterTextLabel:SetText("交互指定NPC")

local filterEdit = CreateFrame("EditBox", "WSLootFilterEdit", WSLootFrame, "InputBoxTemplate")
filterEdit:SetPoint("TOPLEFT", 15, -176)
filterEdit:SetWidth(100)
filterEdit:SetHeight(20)
filterEdit:SetAutoFocus(false)
filterEdit:SetText("")
filterEdit:SetScript("OnEnterPressed", function() filterEdit:ClearFocus() end)
filterEdit:SetScript("OnEscapePressed", function() filterEdit:ClearFocus() end)
filterEdit:SetScript("OnTextChanged", function()
    WushuangLootDB = WushuangLootDB or {}
    WushuangLootDB.filterText = filterEdit:GetText()
    ApplyFilter()
end)
filterEdit:SetScript("OnEnter", function()
    GameTooltip:SetOwner(filterEdit, "ANCHOR_RIGHT")
    GameTooltip:SetText("过滤关键词")
    GameTooltip:AddLine("输入 NPC 名字片段，如 机器人；多个词用逗号分隔，命中任一即交互", 1, 1, 1)
    GameTooltip:Show()
end)
filterEdit:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- 勾选状态持久化: VARIABLES_LOADED 时从 SavedVariables 恢复, PLAYER_LOGOUT 时写回
local function RestoreChecks()
    WushuangLootDB = WushuangLootDB or {}
    for i, cb in ipairs(checkboxes) do
        local lbl = TYPES[i] and TYPES[i].label
        if lbl then
            local raw = WushuangLootDB[lbl]
            if raw == nil then
                cb:SetChecked(true)
            else
                cb:SetChecked(raw == 1)
            end
        end
    end

    -- 恢复 NPC 名字过滤 UI
    local fon = WushuangLootDB.filterOn
    filterCB:SetChecked(fon == 1)
    filterEdit:SetText(WushuangLootDB.filterText or "")
    ApplyFilter()

    -- 加载时若商人与交互指定NPC都勾选: 商人优先生效, 取消指定
    local merchantOn = false
    for _, cb in ipairs(checkboxes) do
        if cb.bit == 16 then merchantOn = cb:GetChecked() end
    end
    if merchantOn and filterCB:GetChecked() then
        filterCB:SetChecked(false)
        WushuangLootDB.filterOn = 0
        ApplyFilter()
    end

    ApplyMask()
end

local svFrame = CreateFrame("Frame")
svFrame:RegisterEvent("VARIABLES_LOADED")
svFrame:RegisterEvent("PLAYER_LOGOUT")
svFrame:SetScript("OnEvent", function()
    if event == "VARIABLES_LOADED" then
        RestoreChecks()
    elseif event == "PLAYER_LOGOUT" then
        WushuangLootDB = WushuangLootDB or {}
        for i, cb in ipairs(checkboxes) do
            local lbl = TYPES[i] and TYPES[i].label
            if lbl then WushuangLootDB[lbl] = cb:GetChecked() and 1 or 0 end
        end
    end
end)

local hint = WSLootFrame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
hint:SetPoint("BOTTOM", 0, 14)
hint:SetText("/无双交互 执行一次交互")

-- 命令: /拾取设置 切换界面
local function HandleSettings()
    if WSLootFrame:IsShown() then
        WSLootFrame:Hide()
    else
        WSLootFrame:Show()
    end
end

SLASH_WSLootSettings1 = "/拾取设置"
SlashCmdList["WSLootSettings"] = HandleSettings

-- ==================== 小地图图标 ====================
local WSLootMinimapButton = CreateFrame("Button", "WSLootMinimapButton", Minimap)
WSLootMinimapButton:SetFrameStrata("MEDIUM")
WSLootMinimapButton:SetWidth(33)
WSLootMinimapButton:SetHeight(33)
WSLootMinimapButton:SetFrameLevel(8)
WSLootMinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
WSLootMinimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local mmIcon = WSLootMinimapButton:CreateTexture("WSLootMinimapButtonIcon", "BACKGROUND")
mmIcon:SetTexture("Interface\\AddOns\\WushuangLoot\\tga\\tubiao")
mmIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
mmIcon:SetWidth(21)
mmIcon:SetHeight(21)
mmIcon:SetPoint("CENTER", 0, 0)

WSLootMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
local mmAngle = 225

local function UpdateMinimapButtonPosition()
    local radius = 80
    local mx, my = Minimap:GetCenter()
    if not mx or not my then return end
    local rad = math.rad(mmAngle)
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    WSLootMinimapButton:ClearAllPoints()
    WSLootMinimapButton:SetPoint("CENTER", UIParent, "BOTTOMLEFT", mx + x, my + y)
end
UpdateMinimapButtonPosition()

WSLootMinimapButton:RegisterForDrag("LeftButton")
WSLootMinimapButton:SetScript("OnDragStart", function()
    WSLootMinimapButton:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        if not mx or not my or not px or not py then return end
        local scale = UIParent:GetEffectiveScale()
        local dx = (px / scale) - mx
        local dy = (py / scale) - my
        mmAngle = math.deg(math.atan2(dy, dx))
        UpdateMinimapButtonPosition()
    end)
end)
WSLootMinimapButton:SetScript("OnDragStop", function()
    WSLootMinimapButton:SetScript("OnUpdate", nil)
end)

WSLootMinimapButton:SetScript("OnClick", function()
    if WSLootFrame:IsShown() then
        WSLootFrame:Hide()
    else
        WSLootFrame:Show()
    end
end)

WSLootMinimapButton:SetScript("OnEnter", function()
    GameTooltip:SetOwner(WSLootMinimapButton, "ANCHOR_LEFT")
    GameTooltip:SetText("自动交互")
    GameTooltip:AddLine("左键点击显示/隐藏界面", 1, 1, 1)
    GameTooltip:Show()
end)
WSLootMinimapButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ==================== DLL 能力探测与低版本降级 ====================
-- 不同版本的 wsloot.dll 暴露的函数可能不同(新版有 CorpseTick/SetFilter/FilterOn,
-- 旧版可能只有 Loot/NpcTick, 甚至没有 SetMask)。这里按"能力"而非"版本号"降级, 更稳健。
local dllCaps = nil
local tickFn = nil
local capsReported = false

local function DetectDllCaps()
    dllCaps = {
        Loot       = (type(WSLoot) == "table" and type(WSLoot.Loot) == "function"),
        SetMask    = (type(WSLoot) == "table" and type(WSLoot.SetMask) == "function"),
        SetFilter  = (type(WSLoot) == "table" and type(WSLoot.SetFilter) == "function"),
        FilterOn   = (type(WSLoot) == "table" and type(WSLoot.FilterOn) == "function"),
        CorpseTick = (type(WSLoot) == "table" and type(WSLoot.CorpseTick) == "function"),
        NpcTick    = (type(WSLoot) == "table" and type(WSLoot.NpcTick) == "function"),
    }
    -- 常驻驱动优先 CorpseTick; 低版本 DLL 降级到 NpcTick
    if dllCaps.CorpseTick then
        tickFn = WSLoot.CorpseTick
    elseif dllCaps.NpcTick then
        tickFn = WSLoot.NpcTick
    else
        tickFn = nil
    end
end

-- 连接成功后打印一次兼容报告, 让用户知道当前 DLL 支持哪些能力
local function ReportDllCaps()
    if capsReported then return end
    capsReported = true
    if not dllCaps then return end
    local tickName = dllCaps.CorpseTick and "CorpseTick"
                    or (dllCaps.NpcTick and "NpcTick(旧版降级)") or "无"
    local miss = {}
    if not dllCaps.SetMask then table.insert(miss, "SetMask") end
    if not (dllCaps.SetFilter and dllCaps.FilterOn) then table.insert(miss, "NPC过滤") end
    if not (dllCaps.CorpseTick or dllCaps.NpcTick) then table.insert(miss, "Tick") end
    local msg = "wsloot.dll 已连接 | 驱动:" .. tickName
    if table.getn(miss) > 0 then
        msg = msg .. " | 低版本缺少: " .. table.concat(miss, ",") .. " (对应功能不可用)"
    end
    Print(msg)
end

-- 自动连接检测 (加载后周期性尝试注册直到成功)
local initFrame = CreateFrame("Frame")
initFrame:SetScript("OnUpdate", function()
    if DllReady() then
        initFrame:SetScript("OnUpdate", nil)
        DetectDllCaps()
        ReportDllCaps()
        ApplyMask()
        Print("已连接 wsloot.dll")
    elseif not UnitAffectingCombat("player") then
        UnitXP("player")
    end
end)

-- 常驻驱动: 每 5 帧调一次 DLL 的 tick 函数; DLL 端 NPC_WAIT_FRAMES=2
-- 优先 CorpseTick, 低版本 DLL 降级到 NpcTick (由 DetectDllCaps 解析缓存到 tickFn)
local tickFrame = CreateFrame("Frame")
local tickCount = 0
tickFrame:SetScript("OnUpdate", function()
    tickCount = tickCount + 1
    if tickCount >= 3 then
        tickCount = 0
        if DllReady() then
            if not dllCaps then DetectDllCaps() end   -- 首次连接时解析一次
            if tickFn then tickFn() end
        end
    end
end)

print(COLOR .. " 加载完成 | /无双交互 执行一次交互")