-- 由Sunelegy基于乌龟魔兽版本定制
if(GetLocale()=="zhCN") then
	MAILTO_TOOLTIP =    "点击选择收件人";
	MAILTO_LISTFULL =   "警告:收件人列表已满";
	MAILTO_ADDED =      "添加到收件人列表";
	MAILTO_REMOVED =    "从收件人列表中移除";
	MAILTO_F_ADD =      "(添加 %s)";
	MAILTO_F_REMOVE =   "(移除 %s)";
else
	MAILTO_TOOLTIP =    "Click to select recipient."
	MAILTO_LISTFULL =   "Warning: List is full!"
	MAILTO_ADDED =      " added to MailTo list."
	MAILTO_REMOVED =    " removed from MailTo list."
	MAILTO_F_ADD =      "(Add %s)"
	MAILTO_F_REMOVE =   "(Remove %s)"
end

local MailTo_Selected, MailTo_Name, MailTo_SavedName, Server
S_MailTo_List = {}

-- 选择收件人
function MailTo_ListSelect()
    local value = this.value
    if value then
      MailTo_SavedName = S_MailTo_List[Server][value]
      _G.Mail_To = nil  -- 清空 Mail_To 变量
      SendMailNameEditBox:SetText(MailTo_SavedName)
      SendMailNameEditBox:HighlightText(0, -1)
      SendMailSubjectEditBox:SetFocus()
    end
end

-- 增加收件人
function MailTo_ListAdd(name)
    if not name then name = MailTo_Name end
    tinsert(S_MailTo_List[Server], name)
    sort(S_MailTo_List[Server])
    print("|cff00FAFA"..name..MAILTO_ADDED)
end

-- 移除收件人
function MailTo_ListRemove()
    tremove(S_MailTo_List[Server], MailTo_Selected)
    print("|cff00FAFA"..MailTo_Name..MAILTO_REMOVED)
end

-- 获取收件人姓名
function MailTo_InList(MCname)
    local LCname = string.lower(MCname)
    for key, name in S_MailTo_List[Server] do
      if LCname == string.lower(name) then return key end
    end
end

-- 下拉菜单
function MailTo_ToList_Init()
    local info = {value = 0, notCheckable = 1}
    MailTo_Name = SendMailNameEditBox:GetText()
    if MailTo_Name ~= "" then
		MailTo_Selected = MailTo_InList(MailTo_Name)
		if MailTo_Selected then
			info.text = string.format(MAILTO_F_REMOVE, MailTo_Name)
			info.func = MailTo_ListRemove
		elseif table.getn(S_MailTo_List[Server]) < UIDROPDOWNMENU_MAXBUTTONS then
			info.text = string.format(MAILTO_F_ADD, MailTo_Name)
			info.func = MailTo_ListAdd
		else
			info = nil
			print("|cffff4040"..MAILTO_LISTFULL)
		end
		if info then UIDropDownMenu_AddButton(info) end
    end
    for key, name in S_MailTo_List[Server] do
      info = {text = name, value = key, func = MailTo_ListSelect}
      if key == MailTo_Selected then info.checked = 1 end
      UIDropDownMenu_AddButton(info)
    end
end

--创建下拉按钮
local MailToDropDownMenu = CreateFrame("Button", "MailToDropDownMenu", SendMailNameEditBox)
    local xOffset
    if pfUI and pfUI.env then
        xOffset = 6
    else
        xOffset = -10
    end
MailToDropDownMenu:Show()
MailToDropDownMenu:SetWidth(24)
MailToDropDownMenu:SetHeight(24)
MailToDropDownMenu:SetPoint("RIGHT", SendMailNameEditBox, "RIGHT", xOffset, 0)
MailToDropDownMenu:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
MailToDropDownMenu:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
MailToDropDownMenu:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")

MailToDropDownMenu:SetScript("OnShow", function()
	if not S_MailTo_Menu then
		S_MailTo_Menu = CreateFrame("Button", "S_MailTo_Menu", this, "UIDropDownMenuTemplate")
		S_MailTo_Menu:Hide()
		S_MailTo_Menu.point = "TOPRIGHT"
		S_MailTo_Menu.relativeTo = SendMailNameEditBox
		S_MailTo_Menu.relativePoint = "BOTTOMRIGHT"
		S_MailTo_Menu.xOffset = 0
		S_MailTo_Menu.yOffset = 0
		UIDropDownMenu_Initialize(S_MailTo_Menu, MailTo_ToList_Init, "MENU")
	end
end)

MailToDropDownMenu:SetScript("OnHide", function()
	CloseDropDownMenus()
end)

MailToDropDownMenu:SetScript("OnClick", function()
	ToggleDropDownMenu(nil, nil, S_MailTo_Menu)
	PlaySound("igMainMenuOptionCheckBoxOn")
end)

MailToDropDownMenu:SetScript("OnEnter", function()
	GameTooltip:SetOwner(this,"ANCHOR_TOPRIGHT")
	GameTooltip:SetText(MAILTO_TOOLTIP)
	GameTooltip:Show()
end)

MailToDropDownMenu:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

MailToDropDownMenu:RegisterEvent("VARIABLES_LOADED");
MailToDropDownMenu:SetScript("OnEvent", function()
    Server = GetRealmName()

    if not S_MailTo_List[Server] then
		S_MailTo_List[Server]={}
	end

    MailToDropDownMenu.displayMode = "MENU"
end)