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