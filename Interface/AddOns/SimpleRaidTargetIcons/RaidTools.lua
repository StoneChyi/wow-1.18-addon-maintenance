-- Vanilla 1.12: use this/arg1 callbacks and explicit 1/0 saved options.
local defaults = {
    SHOW_SAVE_BUTTON = 1, SHOW_HEALTH = 1, SHOW_HEALTH_PERCENT = 1,
    SHOW_SHORT_NAME = 0, SHOW_RESET_BUTTON = 1, SHOW_READY_BUTTON = 1,
    SHOW_COUNTDOWN_BUTTON = 1, SHOW_CLEAR_BUTTON = 1, SHOW_SETTINGS_BUTTON = 1,
    SHOW_HUNTER_BUTTON = 1, HEALTH_BAR_WIDTH = 44, SHOW_LOOT_BUTTON = 1,
}
local sideDefaults = {
    SAVE_BUTTON_SIDE = "RIGHT", READY_BUTTON_SIDE = "LEFT", COUNTDOWN_BUTTON_SIDE = "LEFT",
    RESET_BUTTON_SIDE = "RIGHT", CLEAR_BUTTON_SIDE = "RIGHT", SETTINGS_BUTTON_SIDE = "RIGHT",
    LOOT_BUTTON_SIDE = "RIGHT",
}
local defaultOrder = {"READY_BUTTON", "COUNTDOWN_BUTTON", "LOOT_BUTTON", "SAVE_BUTTON",
    "CLEAR_BUTTON", "RESET_BUTTON", "SETTINGS_BUTTON"}
local toolNames = {READY_BUTTON="就位确认", COUNTDOWN_BUTTON="开怪倒数", LOOT_BUTTON="分配方式",
    SAVE_BUTTON="存 / 还原", CLEAR_BUTTON="清除标记", RESET_BUTTON="重置副本", SETTINGS_BUTTON="设置"}
local tools, checks, health, sideControls, positionControls = {}, {}, {}, {}, {}
local lootMenu, orderMenu
local menuRefresh = CreateFrame("Frame", "SRTI_MenuRefresh")
local pendingMenu
local LootVisible
local initialized = false
local lootLayoutVisible
local countdown = CreateFrame("Frame")
countdown:Hide()

local function Print(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cffc0ffc0[SRTI]|r " .. text)
end

local function NormalizeToolOrder(reset)
    local saved = not reset and BANANA_CONFIG.TOOL_ORDER
    local order, seen = {}, {}
    if type(saved) == "table" then
        for _, id in ipairs(saved) do
            if toolNames[id] and not seen[id] then table.insert(order, id) seen[id] = true end
        end
    end
    for _, id in ipairs(defaultOrder) do
        if not seen[id] then table.insert(order, id) end
    end
    BANANA_CONFIG.TOOL_ORDER = order
    return order
end

local function SideTools(id)
    local result = {}
    for _, other in ipairs(BANANA_CONFIG.TOOL_ORDER) do
        if BANANA_CONFIG[other .. "_SIDE"] == BANANA_CONFIG[id .. "_SIDE"]
            and BANANA_CONFIG["SHOW_" .. other] == 1
            and (other ~= "LOOT_BUTTON" or other == id or LootVisible()) then table.insert(result, other) end
    end
    return result
end

local function ToolPosition(id)
    for position, other in ipairs(SideTools(id)) do
        if other == id then return position end
    end
end

local function MoveTool(id, position)
    if not toolNames[id] or BANANA_CONFIG["SHOW_" .. id] ~= 1 then return end
    local siblings = SideTools(id)
    position = math.max(1, math.min(table.getn(siblings), position))
    local order = BANANA_CONFIG.TOOL_ORDER
    for i, other in ipairs(order) do
        if other == id then table.remove(order, i) break end
    end
    siblings = SideTools(id)
    local anchor = siblings[position] or siblings[table.getn(siblings)]
    local insertion = table.getn(order) + 1
    for i, other in ipairs(order) do
        if other == anchor then insertion = i + (siblings[position] and 0 or 1) break end
    end
    table.insert(order, insertion, id)
    Banana_Layout()
end

function SRTI_ApplyToolDefaults(reset)
    for key, value in pairs(defaults) do
        if reset or BANANA_CONFIG[key] == nil then BANANA_CONFIG[key] = value end
    end
    for key, value in pairs(sideDefaults) do
        if reset or BANANA_CONFIG[key] == nil then BANANA_CONFIG[key] = value end
    end
    NormalizeToolOrder(reset)
end

local function GroupVisible()
    if BANANA_CONFIG.ENABLED ~= 1 then return false end
    if GetNumRaidMembers() > 0 then return BANANA_CONFIG.SHOW_IN_RAID == 1 end
    if GetNumPartyMembers() > 0 then return BANANA_CONFIG.SHOW_IN_PARTY == 1 end
    return BANANA_CONFIG.SHOW_OUT_OF_GROUP == 1
end

LootVisible = function()
    return GroupVisible() and BANANA_CONFIG.SHOW_LOOT_BUTTON == 1
        and (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0)
end

local lootModes = {
    freeforall = {"自由拾取", "队伍成员均可直接拾取物品。", .4, 1, .5, "自由"},
    roundrobin = {"轮流拾取", "队伍成员轮流获得拾取机会。", .4, .8, 1, "轮流"},
    master = {"队长分配", "达到分配品质的物品由指定的物品分配者分配。", 1, .55, .25, "队长"},
    group = {"队伍拾取", "达到分配品质的物品通过需求 / 贪婪掷骰分配。", 1, .85, .3, "队伍"},
    needbeforegreed = {"需求优先", "达到分配品质的物品优先由能够使用的成员需求。", .8, .6, 1, "需求"},
}
local unknownLoot = {"等待同步", "分配方式暂未同步，请稍候。", .7, .7, .7, "待定"}

local function CanChangeLoot()
    if not LootVisible() or not SetLootMethod then return false end
    if GetNumRaidMembers() > 0 then return IsRaidLeader() end
    return IsPartyLeader()
end

local function LootMode()
    -- Vanilla 1.12 GetLootMethod's first return is the method token.
    local method = GetLootMethod and GetLootMethod()
    return lootModes[method] or unknownLoot
end

local function LootTooltip()
    local mode = LootMode()
    GameTooltip:SetOwner(tools.loot, "ANCHOR_TOP")
    GameTooltip:SetText("当前分配方式：" .. mode[1])
    GameTooltip:AddLine(mode[2], .8, .8, .8, 1)
    GameTooltip:AddLine("左键：打开分配菜单", .7, .7, .7, 1)
    if not CanChangeLoot() then GameTooltip:AddLine("只有队长或团长可以切换分配方式。", 1, .6, .3, 1) end
    GameTooltip:Show()
end

local function UpdateLootButton()
    local mode = LootMode()
    if tools.loot.mode ~= mode then
        tools.loot.label:SetText(mode[6])
        tools.loot.label:SetTextColor(mode[3], mode[4], mode[5])
        tools.loot.mode = mode
    end
    if tools.loot.hovered then LootTooltip() end
end

local function CloseMenus()
    pendingMenu = nil
    menuRefresh:SetScript("OnUpdate", nil)
    CloseDropDownMenus()
    -- 1.12 caches the last menu name; invalidate it when rebuilding positions or pages.
    UIDROPDOWNMENU_OPEN_MENU = nil
end

local function ResetMenu(frame)
    frame.selectedID, frame.selectedValue, frame.selectedName = nil, nil, nil
    -- Native list buttons are shared across menus and can retain check textures.
    for level = 1, UIDROPDOWNMENU_MAXLEVELS or 2 do
        for index = 1, UIDROPDOWNMENU_MAXBUTTONS or 32 do
            local name = "DropDownList" .. level .. "Button" .. index
            local button, check = getglobal(name), getglobal(name .. "Check")
            if button then button.checked = false button:UnlockHighlight() end
            if check then check:Hide() end
        end
    end
end

local function AddMenuButton(info, level)
    -- Explicitly leave titles, recipients, navigation and unselected rows unchecked.
    if info.checked == nil then info.checked = false end
    UIDropDownMenu_AddButton(info, level)
end

local function ShowLootMenu(pickMaster, page)
    lootMenu.pickMaster, lootMenu.page = pickMaster, page or 1
    CloseMenus()
    ResetMenu(lootMenu)
    ToggleDropDownMenu(1, nil, lootMenu, tools.loot, 0, 0)
end

local function QueueLootMenu(pickMaster, page)
    CloseMenus()
    pendingMenu = {pickMaster=pickMaster, page=page}
    -- 1.12 finishes checkbox handling after info.func(). Rebuild on the next UI frame,
    -- so that work cannot toggle a recipient or navigation row that reused the clicked button.
    menuRefresh:SetScript("OnUpdate", function()
        local request = pendingMenu
        pendingMenu = nil
        menuRefresh:SetScript("OnUpdate", nil)
        if request and LootVisible() then ShowLootMenu(request.pickMaster, request.page) end
    end)
end

local function SetLoot(mode, unit, expectedName)
    -- Recheck at selection time: leadership and membership may have changed with the menu open.
    if not CanChangeLoot() then Print("只有队长或团长可以切换分配方式。") return end
    if mode == "master" then
        if not unit or not UnitExists(unit) or UnitName(unit) ~= expectedName then
            Print("成员已变化，请重新选择物品分配者。") QueueLootMenu(true, 1) return
        end
        SetLootMethod("master", expectedName)
    else
        SetLootMethod(mode)
    end
    CloseMenus()
    -- Read the client's actual state; never display a requested method as already confirmed.
    SRTI_UpdateTools()
end

local function LootMenuInitialize()
    if (UIDROPDOWNMENU_MENU_LEVEL or 1) ~= 1 then return end
    local allowed = CanChangeLoot()
    if lootMenu.pickMaster then
        local members = {}
        local function AddMember(unit)
            local name = UnitName(unit)
            if name and UnitExists(unit) then table.insert(members, {unit, name}) end
        end
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do AddMember("raid" .. i) end
        elseif GetNumPartyMembers() > 0 then
            AddMember("player")
            for i = 1, GetNumPartyMembers() do AddMember("party" .. i) end
        end
        local pages = math.max(1, math.ceil(table.getn(members) / 10))
        local page = math.min(lootMenu.page or 1, pages)
        AddMenuButton({text="选择物品分配者（" .. page .. "/" .. pages .. "）", isTitle=1, notCheckable=1}, 1)
        for i = (page-1)*10+1, math.min(page*10, table.getn(members)) do
            local unit, name = members[i][1], members[i][2]
            AddMenuButton({text=name, notCheckable=1, keepShownOnClick=1, disabled=not allowed and 1 or nil,
                func=function() SetLoot("master", unit, name) end}, 1)
        end
        if page > 1 then AddMenuButton({text="上一页", notCheckable=1, keepShownOnClick=1,
            func=function() QueueLootMenu(true, page-1) end}, 1) end
        if page < pages then AddMenuButton({text="下一页", notCheckable=1, keepShownOnClick=1,
            func=function() QueueLootMenu(true, page+1) end}, 1) end
        AddMenuButton({text="返回分配方式", notCheckable=1, keepShownOnClick=1,
            func=function() QueueLootMenu(false) end}, 1)
        return
    end
    AddMenuButton({text=allowed and "选择分配方式" or "仅队长 / 团长可切换", isTitle=1, notCheckable=1}, 1)
    for _, token in ipairs({"freeforall", "roundrobin", "master", "group", "needbeforegreed"}) do
        local method = token
        AddMenuButton({text=lootModes[method][1], checked=LootMode()==lootModes[method] and 1 or nil,
            disabled=not allowed and 1 or nil, keepShownOnClick=method=="master" and 1 or nil,
            func=function()
                if method == "master" then
                    if CanChangeLoot() then QueueLootMenu(true, 1) end
                else SetLoot(method) end
            end}, 1)
    end
end

local function Leader(assistant)
    if GetNumRaidMembers() > 0 then
        return IsRaidLeader() or (assistant and IsRaidOfficer())
    end
    return GetNumPartyMembers() == 0 or IsPartyLeader()
end

local function CanReset()
    if not ResetInstances then Print("当前客户端不支持重置副本。") return false end
    if UnitAffectingCombat("player") then Print("战斗中不能重置副本。") return false end
    if IsInInstance and IsInInstance() then
        Print("请先离开副本再重置。") return false
    end
    if not Leader(false) then Print("只有队长或团长可以重置副本。") return false end
    return true
end

StaticPopupDialogs["SRTI_RESET_INSTANCES"] = {
    text = "重置所有可重置的副本？\n请确认队友已离开副本。",
    button1 = ACCEPT, button2 = CANCEL,
    OnAccept = function() if CanReset() then ResetInstances() end end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}

local function ReadyCheck()
    if GetNumRaidMembers() + GetNumPartyMembers() == 0 then
        Print("请先加入队伍或团队。") return
    end
    if not Leader(true) then Print("就位确认需要队长、团长或助理权限。") return end
    if DoReadyCheck then DoReadyCheck() else Print("当前客户端不支持就位确认。") end
end

local function Announce(text)
    if GetNumRaidMembers() > 0 then
        SendChatMessage(text, "RAID_WARNING")
    elseif GetNumPartyMembers() > 0 then
        SendChatMessage(text, "PARTY")
    else
        Print(text)
    end
end

function SRTI_StopCountdown(announce)
    if countdown.untilTime then
        countdown.untilTime = nil
        countdown:SetScript("OnUpdate", nil)
        countdown:Hide()
        if announce then Announce("倒数已取消。") end
    end
end

local function CountdownClick()
    if countdown.untilTime then SRTI_StopCountdown(true) return end
    if arg1 == "RightButton" then return end
    if not Leader(true) then Print("开怪倒数需要队长、团长或助理权限。") return end
    countdown.untilTime = GetTime() + 5
    countdown.last = 5
    Announce("5 秒后开怪！")
    countdown:SetScript("OnUpdate", function()
        if not GroupVisible() or BANANA_CONFIG.SHOW_COUNTDOWN_BUTTON ~= 1 or not Leader(true) then
            SRTI_StopCountdown(false) return
        end
        local remaining = math.max(0, math.ceil(countdown.untilTime - GetTime()))
        if remaining ~= countdown.last then
            countdown.last = remaining
            if remaining == 0 then
                Announce("开怪！")
                SRTI_StopCountdown(false)
            else
                Announce(tostring(remaining) .. " 秒")
            end
        end
    end)
    countdown:Show()
end

local function CreateTool(key, label, title, tip, color, onClick)
    local button = CreateFrame("Button", "SRTI_" .. key, UIParent)
    button:SetWidth(36)
    button:SetHeight(36)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetFont(STANDARD_TEXT_FONT, 20, "OUTLINE")
    text:SetPoint("CENTER", button, "CENTER", 0, 0)
    text:SetText(label)
    text:SetTextColor(unpack(color))
    button.label = text
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(tip, .8, .8, .8, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:Hide()
    return button
end

function SRTI_UpdateToolOptions()
    for key, check in pairs(checks) do check:SetChecked(BANANA_CONFIG[key] == 1) end
    for key, button in pairs(sideControls) do
        button:SetText(BANANA_CONFIG[key] == "LEFT" and "左侧" or "右侧")
    end
    for id, button in pairs(positionControls) do
        local position = ToolPosition(id)
        button:SetText(position and ("第" .. position .. "位") or "已关闭")
        if position then button:Enable() else button:Disable() end
    end
    local width = getglobal("SRTI_HealthWidth")
    if width then width:SetText(tostring(BANANA_CONFIG.HEALTH_BAR_WIDTH or 44)) end
end

local function OrderMenuInitialize()
    if not orderMenu.tool or (UIDROPDOWNMENU_MENU_LEVEL or 1) ~= 1 then return end
    local id = orderMenu.tool
    local title = id=="LOOT_BUTTON" and not LootVisible() and "分配方式：预设组队后的位置"
        or (toolNames[id] .. "：从标记向外排列")
    AddMenuButton({text=title, isTitle=1, notCheckable=1}, 1)
    for i = 1, table.getn(SideTools(id)) do
        local position = i
        AddMenuButton({text="第" .. i .. "位" .. (i==1 and "（最靠近标记）" or ""),
            checked=ToolPosition(id)==i and 1 or nil, func=function() MoveTool(id, position) end}, 1)
    end
end

local function CreateOptions()
    -- Include both columns in the draggable frame's bounds for screen clamping.
    BananaConfigFrame:SetWidth(704)
    BananaConfigFrame:SetHeight(557)
    local header = getglobal("BananaConfigFramePanel1")
    local title = getglobal("BananaConfigFramePanel1LabelTitle")
    local close = getglobal("BananaConfigFrameButtonClose")
    if header then header:SetWidth(684) end
    if title then title:SetWidth(652) end
    if close and header then
        close:ClearAllPoints()
        close:SetPoint("TOPRIGHT", header, "TOPRIGHT", -7, -6)
    end
    local panel = CreateFrame("Frame", "SRTI_ToolOptions", BananaConfigFrame)
    panel:SetWidth(380)
    panel:SetHeight(486)
    panel:SetPoint("TOPLEFT", BananaConfigFrame, "TOPLEFT", 316, -56)
    panel:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile="Interface\\Tooltips\\UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16,
        insets={left=5, right=5, top=5, bottom=5}})
    panel:SetBackdropColor(0, 0, 0, .9)
    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -16)
    heading:SetText("标记血条与团队工具")
    orderMenu = CreateFrame("Frame", "SRTI_OrderMenu", UIParent, "UIDropDownMenuTemplate")
    orderMenu:Hide()
    UIDropDownMenu_Initialize(orderMenu, OrderMenuInitialize, "MENU")
    local options = {
        {"SHOW_HUNTER_BUTTON", "显示猎人印记图标"},
        {"SHOW_SAVE_BUTTON", "存 / 还原", "SAVE_BUTTON_SIDE"},
        {"SHOW_HEALTH", "显示标记目标血条"},
        {"SHOW_HEALTH_PERCENT", "血条显示生命百分比"},
        {"SHOW_SHORT_NAME", "显示短姓名（长名省略）"},
        {"SHOW_RESET_BUTTON", "重置副本", "RESET_BUTTON_SIDE"},
        {"SHOW_READY_BUTTON", "就位确认", "READY_BUTTON_SIDE"},
        {"SHOW_COUNTDOWN_BUTTON", "5 秒开怪倒数", "COUNTDOWN_BUTTON_SIDE"},
        {"SHOW_CLEAR_BUTTON", "清除全部标记", "CLEAR_BUTTON_SIDE"},
        {"SHOW_SETTINGS_BUTTON", "设置", "SETTINGS_BUTTON_SIDE"},
        {"SHOW_LOOT_BUTTON", "分配方式（组队显示）", "LOOT_BUTTON_SIDE"},
    }
    for i, option in ipairs(options) do
        local key = option[1]
        local check = CreateFrame("CheckButton", "SRTI_Option_" .. key, panel, "OptionsCheckButtonTemplate")
        check:SetWidth(24)
        check:SetHeight(24)
        check:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -38 - (i-1)*28)
        getglobal(check:GetName() .. "Text"):SetText(option[2])
        check:SetScript("OnClick", function()
            BANANA_CONFIG[key] = this:GetChecked() and 1 or 0
            if key == "SHOW_COUNTDOWN_BUTTON" then SRTI_StopCountdown(false) end
            Banana_Layout()
            Banana_UpdateStatus()
        end)
        checks[key] = check
        if option[3] then
            local sideKey = option[3]
            local side = CreateFrame("Button", "SRTI_Side_" .. sideKey, panel, "UIPanelButtonTemplate")
            side:SetWidth(56)
            side:SetHeight(22)
            side:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -80, -39 - (i-1)*28)
            side:SetScript("OnClick", function()
                BANANA_CONFIG[sideKey] = BANANA_CONFIG[sideKey] == "LEFT" and "RIGHT" or "LEFT"
                SRTI_UpdateToolOptions()
                Banana_Layout()
            end)
            sideControls[sideKey] = side
            local id = string.gsub(sideKey, "_SIDE$", "")
            local position = CreateFrame("Button", "SRTI_Position_" .. id, panel, "UIPanelButtonTemplate")
            position:SetWidth(56)
            position:SetHeight(22)
            position:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -39 - (i-1)*28)
            position:SetScript("OnClick", function()
                orderMenu.tool = id
                CloseMenus()
                ResetMenu(orderMenu)
                ToggleDropDownMenu(1, nil, orderMenu, this, 0, 0)
            end)
            positionControls[id] = position
        end
    end
    local sizeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    sizeLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -362)
    sizeLabel:SetText("血条宽度（点击切换）")
    local width = CreateFrame("Button", "SRTI_HealthWidth", panel, "UIPanelButtonTemplate")
    width:SetWidth(56)
    width:SetHeight(22)
    width:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -356)
    width:SetScript("OnClick", function()
        local current = BANANA_CONFIG.HEALTH_BAR_WIDTH or 44
        BANANA_CONFIG.HEALTH_BAR_WIDTH = current == 36 and 44 or (current == 44 and 52 or 36)
        SRTI_UpdateToolOptions()
        Banana_Layout()
        Banana_UpdateStatus()
    end)
    for i, value in ipairs({"LEFT", "RIGHT"}) do
        local side = value
        local all = CreateFrame("Button", "SRTI_AllTools" .. side, panel, "UIPanelButtonTemplate")
        all:SetWidth(116)
        all:SetHeight(22)
        all:SetPoint("TOPLEFT", panel, "TOPLEFT", 18 + (i-1)*128, -386)
        all:SetText(side == "LEFT" and "工具全部放左侧" or "工具全部放右侧")
        all:SetScript("OnClick", function()
            for key in pairs(sideDefaults) do BANANA_CONFIG[key] = side end
            SRTI_UpdateToolOptions()
            Banana_Layout()
        end)
    end
    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -422)
    note:SetWidth(344)
    note:SetHeight(54)
    note:SetJustifyH("LEFT")
    note:SetText("第 1 位最靠近标记；隐藏工具不占位。\n分配按钮仅组队显示，可提前设置组队后的位置。\n黄色血条表示刚损失的生命；/srti 打开设置。")
    SRTI_UpdateToolOptions()
end

-- Remove the last UTF-8 character, never split a Chinese code point.
local function ShortName(font, name, width)
    font:SetWidth(0)
    font:SetText(name)
    if font:GetStringWidth() > width then
        local prefix = name
        repeat
            local n = string.len(prefix)
            while n > 1 and string.byte(prefix, n) >= 128 and string.byte(prefix, n) < 192 do n = n - 1 end
            prefix = string.sub(prefix, 1, n-1)
            font:SetText(prefix .. "..")
        until font:GetStringWidth() <= width or prefix == ""
    end
    font:SetWidth(width)
end

local function ClearDamage(bar)
    bar.damage:Hide()
    bar.damagePeak = nil
    bar:SetScript("OnUpdate", nil)
end

local function DrawDamage(bar)
    local fraction = bar.fraction or 0
    local loss = math.max(0, (bar.damagePeak or fraction) - fraction)
    if loss * bar:GetWidth() < .5 then ClearDamage(bar) return end
    bar.damage:ClearAllPoints()
    bar.damage:SetPoint("LEFT", bar, "LEFT", fraction * bar:GetWidth(), 0)
    bar.damage:SetWidth(loss * bar:GetWidth())
    bar.damage:SetHeight(bar:GetHeight())
    bar.damage:Show()
end

local function AnimateDamage()
    local bar = this
    if not GroupVisible() or BANANA_CONFIG.SHOW_HEALTH ~= 1 then ClearDamage(bar) return end
    if GetTime() > bar.damageUntil then
        bar.damagePeak = math.max(bar.fraction, bar.damagePeak - (arg1 or 0) * 1.5)
    end
    DrawDamage(bar)
end

function SRTI_ApplyHealthGeometry()
    local width = math.max(36, math.min(52, tonumber(BANANA_CONFIG.HEALTH_BAR_WIDTH) or 44))
    for index = 1, 9 do
        local button = getglobal("RaidTargetFrame" .. index .. "Button")
        local icon = getglobal("RaidTargetFrame" .. index .. "ButtonIcon")
        if button then button:SetWidth(BANANA_CONFIG.SHOW_HEALTH == 1 and width + 4 or 36) end
        if icon then
            icon:ClearAllPoints()
            icon:SetPoint("TOP", button, "TOP", 0, -2)
        end
        local bar = health[index]
        if bar then
            local oldWidth = bar:GetWidth()
            bar:SetWidth(width)
            bar:ClearAllPoints()
            bar:SetPoint("TOP", button, "BOTTOM", 0, BANANA_CONFIG.SHOW_HEALTH_PERCENT == 1 and -15 or -2)
            if oldWidth ~= width then bar.fullName = nil end
            for tick, texture in ipairs(bar.ticks) do
                texture:ClearAllPoints()
                texture:SetPoint("LEFT", bar, "LEFT", width * tick / 4, 0)
            end
            if bar.damagePeak then DrawDamage(bar) end
        end
    end
end

function SRTI_UpdateHealth(index, cur)
    local bar = health[index]
    if not bar then return end
    local unit = cur.Unit
    if (index == 9 and BANANA_CONFIG.SHOW_HUNTER_BUTTON ~= 1) or not cur.Target or not unit or not UnitExists(unit) or Banana_GetSymbol(unit) ~= index then
        ClearDamage(bar)
        bar.identity = nil
        bar:Hide()
        bar.name:Hide()
        return
    end
    local maximum = UnitHealthMax(unit) or 0
    if BANANA_CONFIG.SHOW_HEALTH == 1 and maximum > 0 then
        local dead = UnitIsDead(unit) or UnitIsGhost(unit)
        local current = dead and 0 or math.max(0, math.min(maximum, UnitHealth(unit) or 0))
        local fraction = current / maximum
        local _, guid = UnitExists(unit)
        local identity = guid or (unit .. ":" .. (UnitName(unit) or ""))
        local previous = bar.fraction
        if dead or identity ~= bar.identity or maximum ~= bar.maximum or not previous then
            ClearDamage(bar)
        elseif fraction < previous then
            bar.damagePeak = math.max(bar.damagePeak or previous, previous)
            bar.damageUntil = GetTime() + .45
            bar:SetScript("OnUpdate", AnimateDamage)
        elseif fraction > previous then
            ClearDamage(bar)
        end
        bar.identity = identity
        if bar.maximum ~= maximum then bar:SetMinMaxValues(0, maximum) bar.maximum = maximum end
        if bar.current ~= current then bar:SetValue(current) bar.current = current end
        if bar.fraction ~= fraction then
            if fraction > .5 then bar:SetStatusBarColor(.15, .9, .35)
            elseif fraction > .25 then bar:SetStatusBarColor(1, .55, .08)
            else bar:SetStatusBarColor(.95, .12, .12) end
            bar.fraction = fraction
        end
        if bar.damagePeak then DrawDamage(bar) end
        local text = dead and "死亡" or (math.floor(fraction*100+.5) .. "%")
        if bar.percent ~= text then bar.text:SetText(text) bar.percent = text end
        if BANANA_CONFIG.SHOW_HEALTH_PERCENT == 1 then bar.text:Show() else bar.text:Hide() end
        bar:Show()
    else
        ClearDamage(bar)
        bar.identity = nil
        bar:Hide()
    end
    if BANANA_CONFIG.SHOW_SHORT_NAME == 1 then
        local name = UnitName(unit) or cur.Target
        local nameWidth = math.min(bar:GetWidth(), cur.FrameButton:GetWidth() - 4)
        if bar.fullName ~= name or bar.nameWidth ~= nameWidth then
            ShortName(bar.name, name, nameWidth)
            bar.fullName, bar.nameWidth = name, nameWidth
        end
        bar.name:ClearAllPoints()
        if bar:IsShown() then
            bar.name:SetPoint("TOP", bar, "BOTTOM", 0, -1)
        else
            bar.name:SetPoint("TOP", cur.FrameButton, "BOTTOM", 0, -1)
        end
        bar.name:Show()
    else
        bar.name:Hide()
    end
end

function SRTI_ToolRowSpacing()
    local extra = 0
    if BANANA_CONFIG.SHOW_HEALTH == 1 then
        extra = extra + 15
        if BANANA_CONFIG.SHOW_HEALTH_PERCENT == 1 then extra = extra + 13 end
    end
    if BANANA_CONFIG.SHOW_SHORT_NAME == 1 then extra = extra + 11 end
    return 4 + extra
end

-- Follow the outside edges of every layout, including reversal and detached hunter mark.
function SRTI_LayoutTools()
    if not initialized then return end
    lootLayoutVisible = LootVisible()
    local flipped = BANANA_CONFIG.FLIP == 1
    local start = RaidTargetFrame1Button
    if BANANA_CONFIG.SHOW_HUNTER_BUTTON == 1 and BANANA_CONFIG.DETACH ~= 1 and BANANA_CONFIG.BUTTON_LAYOUT ~= 5 then start = RaidTargetFrame9Button end
    local ending = RaidTargetFrame8Button
    -- Vertical tools use their own column beside the top icon, clear of the blood bars.
    if BANANA_CONFIG.BUTTON_LAYOUT == 4 then start = RaidTargetFrame1Button ending = RaidTargetFrame1Button end
    local before, after = start, ending
    if flipped and BANANA_CONFIG.BUTTON_LAYOUT ~= 4 and BANANA_CONFIG.BUTTON_LAYOUT ~= 5 then before, after = ending, start end
    local buttons = {READY_BUTTON=tools.ready, COUNTDOWN_BUTTON=tools.countdown, LOOT_BUTTON=tools.loot,
        SAVE_BUTTON=getglobal("SRTI_SaveBtn"), CLEAR_BUTTON=tools.clear, RESET_BUTTON=tools.reset, SETTINGS_BUTTON=tools.settings}
    for _, id in ipairs(NormalizeToolOrder()) do
        local button = buttons[id]
        if button then
            button:SetScale(BANANA_CONFIG.BUTTON_SCALE / 100)
            button:ClearAllPoints()
            local isLeft = BANANA_CONFIG[id .. "_SIDE"] == "LEFT"
            if isLeft then button:SetPoint("RIGHT", before, "LEFT", -4, 0)
            else button:SetPoint("LEFT", after, "RIGHT", 4, 0) end
            if BANANA_CONFIG["SHOW_" .. id] == 1 and (button ~= tools.loot or lootLayoutVisible) then
                if isLeft then before = button else after = button end
            end
        end
    end
    SRTI_UpdateToolOptions()
    SRTI_UpdateTools()
end

function SRTI_UpdateTools()
    if not initialized then return end
    local lootVisible = LootVisible()
    if lootVisible ~= lootLayoutVisible then SRTI_LayoutTools() return end
    if lootVisible then
        UpdateLootButton()
        tools.loot:Show()
    else
        tools.loot:Hide()
        if UIDROPDOWNMENU_OPEN_MENU == lootMenu or UIDROPDOWNMENU_OPEN_MENU == lootMenu:GetName() then CloseMenus() end
        if tools.loot.hovered then GameTooltip:Hide() tools.loot.hovered = nil end
    end
    local visible = GroupVisible()
    local options = {ready="SHOW_READY_BUTTON", countdown="SHOW_COUNTDOWN_BUTTON",
        clear="SHOW_CLEAR_BUTTON", reset="SHOW_RESET_BUTTON", settings="SHOW_SETTINGS_BUTTON"}
    for key, option in pairs(options) do
        if visible and BANANA_CONFIG[option] == 1 then tools[key]:Show() else tools[key]:Hide() end
    end
    local save = getglobal("SRTI_SaveBtn")
    if save then
        if visible and BANANA_CONFIG.SHOW_SAVE_BUTTON == 1 then save:Show() else save:Hide() end
    end
    if not visible then
        SRTI_StopCountdown(false)
        for _, bar in ipairs(health) do ClearDamage(bar) end
    end
end

function SRTI_InitTools()
    if initialized then return end
    SRTI_ApplyToolDefaults()
    tools.ready = CreateTool("ReadyButton", "位", "就位确认", "左键：发起就位确认", {.4, .9, .4},
        function() if arg1 == "LeftButton" then ReadyCheck() end end)
    tools.countdown = CreateTool("CountdownButton", "倒", "开怪倒数", "左键：开始 / 取消 5 秒倒数；右键：取消", {1, .8, .3}, CountdownClick)
    tools.clear = CreateTool("ClearButton", "清", "清除全部标记", "左键：直接清除已标记单位；SuperWoW 可枚举场上标记；保留存档", {1, .4, .4},
        function() if arg1 == "LeftButton" then Banana_ClearAllSymbols() Banana_UpdateStatus() end end)
    tools.reset = CreateTool("ResetButton", "重", "重置副本", "左键：确认后重置副本（需离开副本并拥有队长权限）", {1, .75, .35},
        function() if arg1 == "LeftButton" and CanReset() then StaticPopup_Show("SRTI_RESET_INSTANCES") end end)
    tools.settings = CreateTool("SettingsButton", "设", "标记助手设置", "左键：打开 / 关闭设置面板", {.4, .75, 1},
        function() if arg1 == "LeftButton" then Banana_Toggle() end end)
    tools.loot = CreateTool("LootButton", "", "当前分配方式", "", {1, 1, 1}, function()
        if arg1 == "LeftButton" and LootVisible() then ShowLootMenu(false) end
    end)
    tools.loot.label:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
    tools.loot.label:SetWidth(34)
    tools.loot.label:SetHeight(17)
    lootMenu = CreateFrame("Frame", "SRTI_LootMenu", UIParent, "UIDropDownMenuTemplate")
    lootMenu:Hide()
    UIDropDownMenu_Initialize(lootMenu, LootMenuInitialize, "MENU")
    tools.loot:SetScript("OnEnter", function()
        if LootVisible() then tools.loot.hovered = true LootTooltip() end
    end)
    tools.loot:SetScript("OnLeave", function() tools.loot.hovered = nil GameTooltip:Hide() end)
    local lootEvents = CreateFrame("Frame")
    lootEvents:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
    lootEvents:RegisterEvent("PARTY_MEMBERS_CHANGED")
    lootEvents:RegisterEvent("RAID_ROSTER_UPDATE")
    lootEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    lootEvents:SetScript("OnEvent", function() SRTI_UpdateTools() end)
    for index = 1, 9 do
        local button = getglobal("RaidTargetFrame" .. index .. "Button")
        local bar = CreateFrame("StatusBar", "SRTI_Health" .. index, button)
        bar:SetWidth(BANANA_CONFIG.HEALTH_BAR_WIDTH)
        bar:SetHeight(12)
        bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
        bar:EnableMouse(false)
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        bg:SetTexture("Interface\\Buttons\\WHITE8X8")
        bg:SetVertexColor(.04, .04, .06, 1)
        bar.damage = bar:CreateTexture(nil, "BACKGROUND")
        bar.damage:SetTexture("Interface\\Buttons\\WHITE8X8")
        bar.damage:SetVertexColor(1, .85, .2, 1)
        bar.damage:Hide()
        bar.ticks = {}
        for tick = 1, 3 do
            local texture = bar:CreateTexture(nil, "OVERLAY")
            texture:SetTexture("Interface\\Buttons\\WHITE8X8")
            texture:SetVertexColor(0, 0, 0, .6)
            texture:SetWidth(1)
            texture:SetHeight(12)
            bar.ticks[tick] = texture
        end
        for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
            local border = bar:CreateTexture(nil, "OVERLAY")
            border:SetTexture("Interface\\Buttons\\WHITE8X8")
            border:SetVertexColor(0, 0, 0, 1)
            if edge == "TOP" or edge == "BOTTOM" then
                border:SetHeight(1)
                border:SetPoint(edge .. "LEFT", bar, edge .. "LEFT", 0, 0)
                border:SetPoint(edge .. "RIGHT", bar, edge .. "RIGHT", 0, 0)
            else
                border:SetWidth(1)
                border:SetPoint("TOP" .. edge, bar, "TOP" .. edge, 0, 0)
                border:SetPoint("BOTTOM" .. edge, bar, "BOTTOM" .. edge, 0, 0)
            end
        end
        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bar.text:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
        bar.text:SetHeight(12)
        bar.text:SetPoint("BOTTOM", bar, "TOP", 0, 1)
        bar.text:SetTextColor(1, 1, 1)
        -- Parent the name to the icon so it can stay visible with health disabled.
        bar.name = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bar.name:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
        bar.name:SetHeight(10)
        bar.name:SetJustifyH("CENTER")
        bar.name:SetTextColor(.9, .9, .9)
        bar:Hide()
        bar.name:Hide()
        health[index] = bar
    end
    CreateOptions()
    initialized = true
    SRTI_ApplyHealthGeometry()
    local onShow = BananaConfigFrame:GetScript("OnShow")
    local onHide = BananaConfigFrame:GetScript("OnHide")
    BananaConfigFrame:SetScript("OnShow", function()
        if onShow then onShow() end
        SRTI_UpdateToolOptions()
        Banana_UpdateStatus()
    end)
    BananaConfigFrame:SetScript("OnHide", function()
        if onHide then onHide() end
        Banana_UpdateStatus()
    end)
    SRTI_LayoutTools()
    Banana_UpdateStatus()
end
