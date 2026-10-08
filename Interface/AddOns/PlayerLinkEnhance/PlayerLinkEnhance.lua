UnitPopupButtons["ADD_FRIEND"] = { text = TEXT(ADD_FRIEND), dist = 0 };
UnitPopupButtons["ADD_IGNORE"] = { text = TEXT(IGNORE), dist = 0 };
UnitPopupButtons["WHO"] = { text = TEXT(WHO), dist = 0 };
UnitPopupButtons["ADD_GUILD"] = { text = "邀请入会", dist = 0 };
UnitPopupButtons["GET_NAME"] = { text = "获取名字", dist = 0 };
UnitPopupButtons["RPROMOTE"] = { text = "|cffffffff提升助理↑", dist = 0 };
UnitPopupButtons["RDEMOTE"] = { text = "|cffffffff取消助理↓", dist = 0 };
UnitPopupButtons["UNINVITE"] = { text = "取消邀请", dist = 0 };
UnitPopupButtons["REMOVE"] = { text = "移除", dist = 0 };
UnitPopupButtons["LOOT_MASTER"] = { text = "提升为物品分配者", dist = 0 };
UnitPopupButtons["Convert_To_Raid"] = { text = "|cffffffff转为团队→", dist = 0 }
UnitPopupButtons["Disband"] = { text = "|cffffffff一键解散队伍/团队", dist = 0 }
UnitPopupButtons["Promote_To_Assistant"] = { text = "|cffffffff提升所有为助理 ↑↑↑", dist = 0 }
UnitPopupButtons["Demote_To_Assistant"] = { text = "|cffffffff降职所有助理 ↓↓↓", dist = 0 }

UnitPopupMenus["FRIEND"] = {"WHISPER", "INVITE", "TARGET", "GET_NAME", "ADD_FRIEND", "ADD_IGNORE", "WHO", "ADD_GUILD",
                            "GUILD_PROMOTE", "GUILD_LEAVE", "CANCEL"};
UnitPopupMenus["PARTY"] = {"WHISPER", "PROMOTE", "LOOT_PROMOTE", "RPROMOTE", "RDEMOTE", "UNINVITE", "REMOVE", "INSPECT",
                           "TRADE", "FOLLOW", "DUEL", "ADD_FRIEND", "WHO", "ADD_GUILD", "GET_NAME", "RAID_TARGET_ICON",
                           "CANCEL"};
UnitPopupMenus["PLAYER"] = {"WHISPER", "INVITE", "PROMOTE",  "LOOT_PROMOTE", "RPROMOTE", "RDEMOTE", "REMOVE", "INSPECT",
                            "TRADE", "FOLLOW", "DUEL", "ADD_FRIEND", "ADD_IGNORE", "WHO", "ADD_GUILD", "GET_NAME",
                            "RAID_TARGET_ICON", "CANCEL"};

-- 辅助函数：安全获取下拉菜单框架对象
local function GetDropdownMenu()
    local menu = UIDROPDOWNMENU_INIT_MENU
    if type(menu) == "string" then
        -- 旧版客户端：UIDROPDOWNMENU_INIT_MENU 是字符串（框架名称）
        return _G[menu] or getglobal(menu)
    else
        -- 新版客户端：UIDROPDOWNMENU_INIT_MENU 已经是框架对象
        return menu
    end
end

function PlayerLinkEnhance_OnLoad()
    ori_unitpopup = UnitPopup_OnClick;
    UnitPopup_OnClick = ple_unitpopup;

    ori_SetItemRef = SetItemRef;
    SetItemRef = ple_SetItemRef;

    for index, value in pairs(UnitPopupMenus["SELF"]) do
        if value == "LOOT_PROMOTE" then
            table.insert(UnitPopupMenus["SELF"], index + 1,"LOOT_MASTER")
        elseif value == "RAID_TARGET_ICON" then
            table.insert(UnitPopupMenus["SELF"], index + 1,"Convert_To_Raid")
            table.insert(UnitPopupMenus["SELF"], index + 2,"Disband")
            table.insert(UnitPopupMenus["SELF"], index + 3,"Promote_To_Assistant")
            table.insert(UnitPopupMenus["SELF"], index + 4,"Demote_To_Assistant")
            break
        end
    end
end

local lootMasterRaidName

local function ple_IsAllRaidOfficer()
    local isOfficer = true
    for i=1,40 do
        local name, rank = GetRaidRosterInfo(i);
        if name and rank == 0 then
            isOfficer = false
            break
        end
    end
    return isOfficer
end

local function ple_UnitInfo(unitName)
    local raidRank = 0
    local unitIsInRaid = false
    local index = 0
    for i = 1, GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i);
        if name == unitName then
            unitIsInRaid = true
            raidRank = rank
            index = i
            break
        end
    end
    return unitIsInRaid, raidRank, index
end

local function ple_ChangeAssistantStatic()
    local IsAllRaidOfficer = ple_IsAllRaidOfficer()
    for i=1,GetNumRaidMembers() do
        local name, rank = GetRaidRosterInfo(i);
        if name and rank ~=2 then
            if IsAllRaidOfficer then
                DemoteAssistant(name)
            else
                PromoteToAssistant(name)
            end
        end
    end
    if IsAllRaidOfficer then
        ChatFrame1:AddMessage("已取消所有人的助理权限 ↓↓↓",1,1,0);
    else
        ChatFrame1:AddMessage("已将所有人提升为助理权限 ↑↑↑",1,1,0);
    end
end

local function ple_Disband()
    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()
    if raidCount > 0 then
        for i = 1, raidCount do
            if UnitName("raid"..i) == UnitName("player") then
                i = i + 1
            else
                UninviteFromRaid(i)
            end
        end
    elseif partyCount > 0 then
        for i = 1, partyCount do
            UninviteFromParty("party"..i)
        end
    end
end

hooksecurefunc("UnitPopup_HideButtons", function()
    -- 修改：使用安全函数获取下拉菜单框架
    local dropdownMenu = GetDropdownMenu();
    if not dropdownMenu or not UnitPopupMenus[dropdownMenu.which] then return end

    local isLeader = 0;
    if IsPartyLeader() or IsRaidLeader() then
        isLeader = 1;
    end

    local isAssistant = 0;
    if (IsRaidOfficer()) then
        isAssistant = 1;
    end

    local canCoop = 0;
    if (dropdownMenu.unit and UnitCanCooperate("player", dropdownMenu.unit)) then
        canCoop = 1;
    end

    local offline = 0
    if (dropdownMenu.unit and UnitIsConnected(dropdownMenu.unit)) then
        offline = 1;
    end

    local raidCount = GetNumRaidMembers()
    local partyCount = GetNumPartyMembers()
    local IsAllRaidOfficer = ple_IsAllRaidOfficer()
    local unitIsInRaid, rank, unitIsInParty = false, 0, false
    if raidCount > 0 then
        unitIsInRaid, rank = ple_UnitInfo(dropdownMenu.name)
    elseif partyCount > 0 then
        unitIsInParty = dropdownMenu.name == UnitName("party1") or dropdownMenu.name == UnitName("party2") or
                            dropdownMenu.name == UnitName("party3") or dropdownMenu.name == UnitName("party4") or
                            dropdownMenu.name == UnitName("player")
    end

    for index, value in UnitPopupMenus[dropdownMenu.which] do
        if (value == "INVITE") then
            if (raidCount > 0 or partyCount >0) and (isAssistant == 0 and isLeader == 0) then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            else
                -- 去掉 canCoop 的判断
                if (dropdownMenu.unit) then
                    if unitIsInRaid or unitIsInParty then
                        UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
                    else
                        UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
                    end
                else
                    if raidCount > 0 then
                        if unitIsInRaid then
                            UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
                        else
                            UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
                        end
                    elseif unitIsInParty then
                        UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
                    else
                        UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
                    end
                end
            end
        elseif value == "PROMOTE" then
            if (canCoop == 1) and (unitIsInRaid or unitIsInParty) and isLeader == 1 and offline == 1 then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "LOOT_PROMOTE" then
            local lootMethod;
            local lootMaster;
            lootMethod, lootMaster = GetLootMethod();

            if ((not unitIsInParty and not unitIsInRaid) or offline == 0 or (partyCount == 0 and raidCount == 0) or (isLeader == 0) or (lootMethod ~= "master") or (lootMaster and (dropdownMenu.unit == "party"..lootMaster)) or (dropdownMenu.unit == "target" and dropdownMenu.name == UnitName("player") and (lootMaster == 0 or not lootMaster) ) or ((dropdownMenu.unit == "player") and not lootMaster)) or (lootMasterRaidName and dropdownMenu.name == lootMasterRaidName) then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "RPROMOTE" then
            if isLeader == 1 and raidCount > 0 and unitIsInRaid and (rank ~= 1) and offline == 1 then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "RDEMOTE" then
            if isLeader == 1 and raidCount > 0 and unitIsInRaid and (rank == 1) and offline == 1 then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif (value == "UNINVITE") then
            if raidCount > 0 then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            elseif not unitIsInParty then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif (value == "REMOVE") then
            if raidCount > 0 and unitIsInRaid and ((isLeader == 1 and rank < 2) or (isAssistant == 1 and rank == 0)) then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "LOOT_MASTER" then
            local lootMethod, lootMaster = GetLootMethod();
            if  (raidCount > 0 and isLeader == 1 and lootMethod == "master" and not lootMaster) then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "Convert_To_Raid" then
            if (isLeader == 1 and raidCount == 0 and partyCount > 0 and dropdownMenu.unit == "player") then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "Disband" then
            if ( (isLeader == 1) and (raidCount > 0 or partyCount > 0) and dropdownMenu.unit == "player") then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "Promote_To_Assistant" then
            if isLeader == 1 and raidCount > 0 and (not IsAllRaidOfficer) then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        elseif value == "Demote_To_Assistant" then
            if isLeader == 1 and raidCount > 0 and IsAllRaidOfficer then
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
            else
                UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0;
            end
        -- 强制显示团队标记图标
        elseif value == "RAID_TARGET_ICON" then
            UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
        end
    end
end)

function ple_unitpopup()
    -- 修改：使用安全函数获取下拉菜单框架
    local dropdownFrame = GetDropdownMenu();
    local button = this.value;
    local unit = dropdownFrame.unit;
    local name = dropdownFrame.name;
    local server = dropdownFrame.server;

    if (button == "ADD_FRIEND") then
        AddFriend(name);
    elseif (button == "ADD_IGNORE") then
        AddIgnore(name);
    elseif (button == "WHO") then
        SendWho("n-" .. name);
    elseif (button == "ADD_GUILD") then
        GuildInviteByName(name);
    elseif (button == "GET_NAME") then
        ple_GetName(name);
    elseif (button == "RPROMOTE") then
        PromoteToAssistant(name);
        ChatFrame1:AddMessage("已将 " .. name .. " 提升为助理权限 ↑↑↑", 1, 1, 0);
    elseif (button == "RDEMOTE") then
        DemoteAssistant(name);
        ChatFrame1:AddMessage("已取消 " .. name .. " 的助理权限 ↓↓↓", 1, 1, 0);
    elseif (button == "REMOVE") then
        local _, _, index = ple_UnitInfo(name)
        UninviteFromRaid(index)
    elseif button == "LOOT_MASTER" then
        lootMasterRaidName = nil
        SetLootMethod("master", UnitName("player"));
    elseif button == "LOOT_PROMOTE" then
        lootMasterRaidName = name
        SetLootMethod("master", name);
    elseif button == "Disband" then
        StaticPopup_Show("CONFIRM_DISBAND_GROUP")
    elseif button == "Convert_To_Raid" then
        ConvertToRaid()
    elseif button == "Promote_To_Assistant" then
        ple_ChangeAssistantStatic()
    elseif button == "Demote_To_Assistant" then
        ple_ChangeAssistantStatic()
    else
        return ori_unitpopup();
    end
    PlaySound("UChatScrollButton");
end

function ple_SetItemRef(link, text, button)
    if (strsub(link, 1, 6) == "player") then
        local name = strsub(link, 8);
        if (name and (strlen(name) > 0)) then
            name = gsub(name, "([^%s]*)%s+([^%s]*)%s+([^%s]*)", "%3");
            name = gsub(name, "([^%s]*)%s+([^%s]*)", "%2");
            if (IsShiftKeyDown()) then
                local staticPopup;
                staticPopup = StaticPopup_Visible("ADD_IGNORE");
                if (staticPopup) then
                    getglobal(staticPopup .. "EditBox"):SetText(name);
                    return;
                end
                staticPopup = StaticPopup_Visible("ADD_FRIEND");
                if (staticPopup) then
                    getglobal(staticPopup .. "EditBox"):SetText(name);
                    return;
                end
                staticPopup = StaticPopup_Visible("ADD_GUILDMEMBER");
                if (staticPopup) then
                    getglobal(staticPopup .. "EditBox"):SetText(name);
                    return;
                end
                staticPopup = StaticPopup_Visible("ADD_RAIDMEMBER");
                if (staticPopup) then
                    getglobal(staticPopup .. "EditBox"):SetText(name);
                    return;
                end
                if (ChatFrameEditBox:IsVisible()) then
                    ChatFrameEditBox:Insert(name);
                else
                    SendWho("n-" .. name);
                end
            elseif (IsControlKeyDown()) then
                TargetByName(name);
            elseif (IsAltKeyDown()) then
                ple_GetName(name);
            elseif (button == "RightButton") then
                FriendsFrame_ShowDropdown(name, 1);
            else
                ChatFrame_SendTell(name);
            end
        end
        return;
    end
    return ori_SetItemRef(link, text, button);
end

function ple_GetName(name)
    if (ChatFrameEditBox:IsVisible()) then
        ChatFrameEditBox:Insert(name);
        ChatFrameEditBox:HighlightText();
    else
        DEFAULT_CHAT_FRAME.editBox:Hide();
        DEFAULT_CHAT_FRAME.editBox.chatType = "SAY";
        ChatEdit_UpdateHeader(DEFAULT_CHAT_FRAME.editBox);
        if (not DEFAULT_CHAT_FRAME.editBox:IsVisible()) then
            DEFAULT_CHAT_FRAME.editBox:Show()
            DEFAULT_CHAT_FRAME.editBox:Insert(name);
            DEFAULT_CHAT_FRAME.editBox:HighlightText();
        end
    end
end

-- 创建确认弹窗
StaticPopupDialogs["CONFIRM_DISBAND_GROUP"] = {
    text = "你确定要解散队伍/团队吗？",
    button1 = "确定",
    button2 = "取消",
    OnAccept = function()
        ple_Disband()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3
}

-- PLE_SAFER_MENU_BEGIN

SLASH_PLEMENU1 = "/plemenu"
SlashCmdList.PLEMENU = function()
    DEFAULT_CHAT_FRAME:AddMessage(PLE_SAFER_MENU_LOADED and
        "头像菜单优化已加载：观察装备置顶，邀请入队独立分组。" or
        "头像菜单优化未加载。请查看插件错误提示。", 1, .85, .25)
end

-- Retail-inspired spacing and grouping on the vanilla UnitPopup API.
-- Shared DropDownList frames are restored before other dropdowns reuse them.
local ROW_HEIGHT, ROW_GAP, GROUP_GAP, PADDING = 18, 1, 4, 6
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
                backdrop:SetBackdropColor(.055, .065, .08, .85)
            end
        end
    end
    local width = math.max(140, (list.maxWidth or 0) + 15)
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
        local height = (row.value == "INSPECT" or row.value == "INVITE") and 20 or ROW_HEIGHT
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
    copy.textHeight = copy.textHeight or UIDROPDOWNMENU_DEFAULT_TEXT_HEIGHT or 12
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

PLE_SAFER_MENU_LOADED = "1.8.3-compact"
-- PLE_SAFER_MENU_END
