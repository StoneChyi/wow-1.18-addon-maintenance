-- Retail-inspired spacing and grouping on the vanilla UnitPopup API.
-- Shared DropDownList frames are restored before other dropdowns reuse them.
local ROW_HEIGHT, ROW_GAP, GROUP_GAP, PADDING = 26, 2, 8, 12
local building
local primary = { SELF = true, PLAYER = true, PARTY = true, RAID = true,
    FRIEND = true, PET = true }
local groups = {
    WHISPER = 1, INSPECT = 1, TRADE = 1, FOLLOW = 1, TARGET = 1,
    PET_PAPERDOLL = 1, PET_RENAME = 1,
    PF_SET_FOCUS = 2, PF_CLEAR_FOCUS = 2,
    INVITE = 3,
    ADD_FRIEND = 4, WHO = 4, GET_NAME = 4, ADD_GUILD = 4,
    RAID_TARGET_ICON = 5,
    LOOT_METHOD = 6, LOOT_THRESHOLD = 6, LOOT_PROMOTE = 6, LOOT_MASTER = 6,
    PROMOTE = 6, RPROMOTE = 6, RDEMOTE = 6, RAID_LEADER = 6,
    RAID_PROMOTE = 6, RAID_DEMOTE = 6, Convert_To_Raid = 6,
    Promote_To_Assistant = 6, Demote_To_Assistant = 6,
    DUEL = 7, ADD_IGNORE = 7, IGNORE_PLAYER = 7, REMOVE = 7, UNINVITE = 7,
    RAID_REMOVE = 7, LEAVE = 7, Disband = 7, GUILD_LEAVE = 7,
    PET_ABANDON = 7, PET_DISMISS = 7, RESET_INSTANCES = 7, RESET_INSTANCES_FIX = 7,
    CANCEL = 8,
}
local confirmations = {
    ADD_IGNORE = "屏蔽玩家", IGNORE_PLAYER = "屏蔽玩家", REMOVE = "移出团队",
    RAID_REMOVE = "移出团队", UNINVITE = "移出小队", LEAVE = "离开队伍/团队",
}

local function SortMenu(which)
    local menu = UnitPopupMenus[which]
    if not menu then return end
    -- Stable buckets preserve every entry added by pfUI or other addons.
    local ordered = {}
    for group = 1, 8 do
        -- Inspect is always the first action, away from the invite section.
        if group == 1 then
            for _, value in ipairs(menu) do
                if value == "INSPECT" then table.insert(ordered, value) end
            end
        end
        for _, value in ipairs(menu) do
            if value ~= "INSPECT" and (groups[value] or 6) == group then
                table.insert(ordered, value)
            end
        end
    end
    for i, value in ipairs(ordered) do menu[i] = value end
end

local function GroupSignature()
    local names = {}
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name then table.insert(names, name) end
        end
    else
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then table.insert(names, name) end
        end
    end
    table.sort(names)
    return (GetNumRaidMembers() > 0 and "raid:" or "party:") .. table.concat(names, ":")
end

local function AcceptAction(action)
    -- Resolve membership again by the captured name; never reuse a raid index
    -- or target token after a confirmation has been left open.
    if action.value == "ADD_IGNORE" or action.value == "IGNORE_PLAYER" then
        if action.name then AddIgnore(action.name) end
    elseif action.value == "REMOVE" or action.value == "RAID_REMOVE" then
        for i = 1, GetNumRaidMembers() do
            local name, rank = GetRaidRosterInfo(i)
            if name == action.name then
                if (IsRaidLeader() and rank < 2) or (IsRaidOfficer() and rank == 0) then
                    UninviteFromRaid(i)
                end
                return
            end
        end
    elseif action.value == "UNINVITE" then
        if GetNumRaidMembers() > 0 or not IsPartyLeader() then return end
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == action.name then
                UninviteFromParty("party" .. i)
                return
            end
        end
    elseif action.value == "LEAVE" then
        if action.group == GroupSignature() then LeaveParty() end
    end
end

StaticPopupDialogs["PLE_CONFIRM_UNIT_ACTION"] = {
    text = "%s", button1 = "确定", button2 = "取消",
    OnAccept = function(action)
        -- Vanilla passes dialog.data; global this is the clicked button.
        if action then AcceptAction(action) end
    end,
    OnHide = function() this.data = nil end,
    timeout = 0, whileDead = 1, hideOnEscape = 1,
}

local function ConfirmAction(value, name)
    local action = { value = value, name = name, group = GroupSignature() }
    local text = "确定要" .. confirmations[value]
    if value ~= "LEAVE" then text = text .. "「" .. (name or UNKNOWN) .. "」" end
    local dialog = StaticPopup_Show("PLE_CONFIRM_UNIT_ACTION", text .. "吗？")
    if dialog then dialog.data = action end
    CloseDropDownMenus()
end

local function SavePoints(region)
    local points = {}
    for i = 1, region:GetNumPoints() do points[i] = { region:GetPoint(i) } end
    return points
end

local function RestorePoints(region, points)
    region:ClearAllPoints()
    for _, point in ipairs(points) do region:SetPoint(unpack(point)) end
end

local function ResetList(list)
    if not list.pleSaved then list.pleRows = nil; return end
    for button, saved in pairs(list.pleSaved.buttons) do
        button:SetHeight(saved.height)
        button:SetWidth(saved.width)
        button:SetHitRectInsets(unpack(saved.hit))
        RestorePoints(button, saved.points)
        local text = getglobal(button:GetName() .. "NormalText")
        RestorePoints(text, saved.textPoints)
        local highlight = getglobal(button:GetName() .. "Highlight")
        highlight:SetTexture(saved.texture)
        highlight:SetBlendMode(saved.blend)
        highlight:SetVertexColor(unpack(saved.color))
        if button.pleDivider then button.pleDivider:Hide() end
    end
    for backdrop, color in pairs(list.pleSaved.backdrops) do
        backdrop:SetBackdropColor(unpack(color))
    end
    list:SetHeight(list.pleSaved.height)
    list:SetWidth(list.pleSaved.width)
    list.pleSaved, list.pleRows = nil, nil
end

local function LayoutList(list)
    local rows = list.pleRows
    if not rows or table.getn(rows) == 0 then return end
    if not list.pleSaved then
        list.pleSaved = { height = list:GetHeight(), width = list:GetWidth(),
            buttons = {}, backdrops = {} }
        for _, suffix in ipairs({ "Backdrop", "MenuBackdrop" }) do
            local frame = getglobal(list:GetName() .. suffix)
            -- pfUI draws the background on its own child backdrop.
            local backdrop = frame and (frame.backdrop or frame)
            if backdrop then
                list.pleSaved.backdrops[backdrop] = { backdrop:GetBackdropColor() }
                backdrop:SetBackdropColor(.055, .065, .08, .98)
            end
        end
    end
    local width = math.max(240, (list.maxWidth or 0) + 15)
    local y, previous = PADDING, nil
    for i, row in ipairs(rows) do
        local button = getglobal(list:GetName() .. "Button" .. i)
        local highlight = getglobal(button:GetName() .. "Highlight")
        local text = getglobal(button:GetName() .. "NormalText")
        if not list.pleSaved.buttons[button] then
            list.pleSaved.buttons[button] = {
                height = button:GetHeight(), width = button:GetWidth(),
                hit = { button:GetHitRectInsets() }, points = SavePoints(button),
                textPoints = SavePoints(text), texture = highlight:GetTexture(),
                blend = highlight.GetBlendMode and highlight:GetBlendMode() or "ADD",
                color = { highlight:GetVertexColor() },
            }
        end
        local group = row.title and 0 or (building and building.primary and
            (groups[row.value] or 6) or row.group)
        if previous and group ~= previous then
            y = y + GROUP_GAP
            if not button.pleDivider then
                button.pleDivider = button:CreateTexture(nil, "ARTWORK")
                button.pleDivider:SetTexture(1, 1, 1, .16)
                button.pleDivider:SetHeight(1)
            end
            button.pleDivider:ClearAllPoints()
            button.pleDivider:SetPoint("BOTTOMLEFT", button, "TOPLEFT", 4, 4)
            button.pleDivider:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", -4, 4)
            button.pleDivider:Show()
        elseif button.pleDivider then
            button.pleDivider:Hide()
        end
        previous = group
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", list, "TOPLEFT", 8, -y)
        button:SetWidth(width - 16)
        local height = (row.value == "INSPECT" or row.value == "INVITE") and 32 or ROW_HEIGHT
        button:SetHeight(height)
        button:SetHitRectInsets(0, 0, 0, 0)
        text:ClearAllPoints()
        text:SetPoint("LEFT", button, "LEFT", row.notCheckable and 10 or 27, 0)
        highlight:SetTexture(.2, .58, .85, .32)
        highlight:SetBlendMode("BLEND")
        highlight:SetVertexColor(1, 1, 1, 1)
        y = y + height + ROW_GAP
    end
    list:SetWidth(width)
    list:SetHeight(y - ROW_GAP + PADDING)
end

local OriginalAddButton = UIDropDownMenu_AddButton
UIDropDownMenu_AddButton = function(info, level)
    level = level or 1
    local list = getglobal("DropDownList" .. level)
    if not building then
        if list then ResetList(list) end
        return OriginalAddButton(info, level)
    end
    local copy = {}
    for key, value in pairs(info) do copy[key] = value end
    copy.textHeight = math.max(14, copy.textHeight or 0)
    if building.primary and copy.value == "INSPECT" and not copy.isTitle then
        copy.text, copy.textR, copy.textG, copy.textB = "观察装备", .45, .82, 1
    elseif building.primary and copy.value == "INVITE" and not copy.isTitle then
        copy.text, copy.textR, copy.textG, copy.textB = "邀请入队", .45, 1, .58
    elseif building.primary and groups[copy.value] == 7 and not copy.isTitle then
        copy.textR, copy.textG, copy.textB = 1, .52, .38
        copy.text = string.gsub(string.gsub(copy.text or "", "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
    end
    if confirmations[copy.value] and copy.func and not copy.isTitle then
        local value, name = copy.value, building.name
        copy.func = function() ConfirmAction(value, name) end
        if value == "UNINVITE" then copy.text = "移出小队" end
        copy.text = (copy.text or "") .. "…"
    end
    OriginalAddButton(copy, level)
    list.pleRows = list.pleRows or {}
    table.insert(list.pleRows, { value = copy.value, title = copy.isTitle,
        notCheckable = copy.notCheckable,
        group = building.primary and (groups[copy.value] or 6) or 1 })
end

local OriginalShowMenu = UnitPopup_ShowMenu
UnitPopup_ShowMenu = function(dropdown, which, unit, name, userData)
    local level = UIDROPDOWNMENU_MENU_LEVEL or 1
    local list = getglobal("DropDownList" .. level)
    ResetList(list)
    local isPrimary = level == 1 and primary[which]
    if isPrimary then SortMenu(which) end
    local previous = building
    building = { primary = isPrimary, name = name or (unit and UnitName(unit)) }
    -- Clear the build context even if another addon raises an error.
    local ok, err = pcall(function()
        OriginalShowMenu(dropdown, which, unit, name, userData)
        LayoutList(list)
    end)
    building = previous
    if not ok then error(err) end
end

for level = 1, UIDROPDOWNMENU_MAXLEVELS do
    local list = getglobal("DropDownList" .. level)
    local oldShow, oldHide = list:GetScript("OnShow"), list:GetScript("OnHide")
    list:SetScript("OnShow", function()
        if oldShow then oldShow() end
        LayoutList(this)
    end)
    list:SetScript("OnHide", function()
        ResetList(this)
        if oldHide then oldHide() end
    end)
end
