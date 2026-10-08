-- 创建密语盒子按钮
local buttonmove = 0
boxButton = CreateFrame("Button", "WIMBoxButton", UIParent)
boxButton:SetWidth(32)
boxButton:SetHeight(32)
boxButton:SetText("") -- 不显示文字
boxButton:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 33, 0)
boxButton:SetMovable(true)
boxButton:RegisterForDrag("LeftButton")
boxButton:SetAlpha(0) -- 初始隐藏，由下方 OnUpdate 渐隐逻辑控制显隐

boxButton:SetScript("OnDragStart", function(self)
    if IsShiftKeyDown() then
        boxButton:StartMoving()
	buttonmove = 1
    end
end)
boxButton:SetScript("OnDragStop", function(self)
    boxButton:StopMovingOrSizing()
end)

-- 鼠标悬停高亮贴图
if not boxButton.highlight then
    boxButton.highlight = boxButton:CreateTexture(nil, "HIGHLIGHT")
    boxButton.highlight:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-BlinkHilight.blp")
    boxButton.highlight:SetAllPoints(boxButton)
    boxButton.highlight:Hide()
end
boxButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(boxButton, "ANCHOR_RIGHT")
        GameTooltip:AddLine("WIM密语管理")
        GameTooltip:AddLine("左键点击打开联系人")
	GameTooltip:AddLine("按住Shift+左键拖动盒子")
	GameTooltip:AddLine("按住Shift+左键单击复位盒子")
	GameTooltip:AddLine("/wim打开设置面板")
        GameTooltip:Show()
    if boxButton.highlight then
        boxButton.highlight:Show()
    end
end)
boxButton:SetScript("OnLeave", function()
    GameTooltip:Hide()
    if boxButton.highlight then
        boxButton.highlight:Hide()
    end
end)


-- 聊天图标
if not boxButton.icon then
    boxButton.icon = boxButton:CreateTexture(nil, "OVERLAY", nil, 7)
    boxButton.icon:SetTexture("Interface\\AddOns\\WIM\\Images\\Say")
    boxButton.icon:SetAllPoints(boxButton)
end

-- 添加未读消息计数泡泡
if not boxButton.bubbleBg then
    boxButton.bubbleBg = boxButton:CreateTexture(nil, "OVERLAY")
    boxButton.bubbleBg:SetTexture("Interface\\AddOns\\WIM\\Images\\Aura72")
    boxButton.bubbleBg:SetWidth(23)
    boxButton.bubbleBg:SetHeight(23)
    boxButton.bubbleBg:SetVertexColor(1, 0, 0, 1) -- 红色
    boxButton.bubbleBg:SetPoint("BOTTOMRIGHT", boxButton, "TOPRIGHT", 9, -10)
    boxButton.bubbleBg:Hide()
end

boxButton.bubble = boxButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
boxButton.bubble:SetPoint("CENTER", boxButton.bubbleBg, "CENTER", -1, 2)
boxButton.bubble:SetText("")
boxButton.bubble:Hide()

-- 更新未读消息计数显示
WIM_contact_Unread = WIM_contact_Unread or {} -- 未读消息计数
--联系人列表脏标记：收到消息只标脏，由 boxButton 的 OnUpdate 在盒子可见时合并刷新一次。
--避免多窗口同时收到多条密语时，每条都全量重建联系人列表（原逻辑即使盒子隐藏也照样重建，多窗同收时明显卡顿）
WIM_ContactListDirty = false
function WIM_MarkContactListDirty()
    WIM_ContactListDirty = true
end
function UpdateUnreadBubble()
    local totalUnread = 0
    for _, count in pairs(WIM_contact_Unread) do
        totalUnread = totalUnread + count
    end

    if totalUnread > 0 then
        if boxButton.bubbleBg then
            boxButton.bubbleBg:Show()
        end
        boxButton.bubble:SetText(totalUnread)
        boxButton.bubble:Show()
    else
        if boxButton.bubbleBg then
            boxButton.bubbleBg:Hide()
        end
        boxButton.bubble:Hide()
    end
    WIM_ContactListDirty = true --标脏即可，列表由 OnUpdate 在盒子可见时合并刷新（优化：不再每条消息都全量重建）
end
function RefreshUnread(user) --刷新未读信息计数
	if WIM_contact_Unread and WIM_contact_Unread[user] then
		WIM_contact_Unread[user] = 0 --清除当前联系人未读计数
	end
	if WIM_History[user] then
		for i=1, table.getn(WIM_History[user]) do 
			WIM_History[user][i]["unread"] = 0
		end
	end
        UpdateUnreadBubble() --更新未读计数
end

-- 按钮渐隐逻辑：有未读/正在拖动时常显；鼠标悬停附近时显示，离开后逐渐淡出至透明
boxButton:SetScript("OnUpdate", function() --按钮靠鼠标自动渐隐
	--联系人列表脏标记合并刷新：同帧多条消息只重建一次列表，且仅在盒子可见时重建（原逻辑每条消息全量重建，盒子隐藏时也重建）
	if WIM_ContactListDirty and boxFrame:IsShown() then
		WIM_ContactListDirty = false
		UpdateWIMContactList()
	end
	if this.bubble:IsShown() or buttonmove == 1 then
		this:SetAlpha(1)
	elseif not MouseIsOver(this, 50, -50, -50, 50) and this:GetAlpha() == 0 then
		return
	else
		if MouseIsOver(this, 50, -50, -50, 50) then
			this:SetAlpha(1)
		elseif this:GetAlpha() > 0 then
			this:SetAlpha(this:GetAlpha() - 0.01)
		end
	end
end)

-- 创建密语盒子窗口
boxFrame = CreateFrame("Frame", "WIMBoxFrame", UIParent)
boxFrame:SetBackdrop{
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", -- 黑色半透明背景
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- 纯白线条
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
}
boxFrame:SetBackdropColor(0, 0, 0, .8) -- 黑色半透明
boxFrame:SetBackdropBorderColor(1, 1, 1, 1) -- 黑色线条
boxFrame:SetWidth(160)
boxFrame:SetHeight(254)
-- 联系人作为前景浮层显示，避免默认 MEDIUM 层级被聊天窗口和其他界面遮挡。
-- 保持低于 TOOLTIP，让联系人提示和物品提示仍能正常显示。
boxFrame:SetFrameStrata("FULLSCREEN_DIALOG")
boxFrame:SetToplevel(true)
boxFrame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",242+50+384,775-25);
boxFrame:Hide()
--打开盒子时立即重建联系人列表（消息到达只标脏、不重建，打开时才补一次，保证显示不滞后）
boxFrame:SetScript("OnShow", function()
	boxFrame:Raise()
	WIM_ContactListDirty = false
	UpdateWIMContactList()
end)
--可拖动
boxFrame:SetMovable(true)
boxFrame:EnableMouse(true)
boxFrame:RegisterForDrag("LeftButton")
boxFrame:SetScript("OnDragStart", function()
    	boxFrame:StartMoving()
end)
boxFrame:SetScript("OnDragStop", function()
    	boxFrame:StopMovingOrSizing()
end)
--标题背景
boxFrame.tex = boxFrame:CreateTexture(nil, "OVERLAY")
boxFrame.tex:SetTexture(0,0,0,0.5)
boxFrame.tex:SetPoint("TOP",0,-5)
boxFrame.tex:SetWidth(150)
boxFrame.tex:SetHeight(17)
--标题文字
boxFrame.text = boxFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
boxFrame.text:SetText("联系人")
boxFrame.text:SetPoint("CENTER",boxFrame.tex,"CENTER",0,0)
--关闭按钮
if not boxFrame.closeBtn then
    boxFrame.closeBtn = CreateFrame("Button", nil, boxFrame)
    boxFrame.closeBtn:SetWidth(30)
    boxFrame.closeBtn:SetHeight(30)
    boxFrame.closeBtn:SetPoint("TOPRIGHT", boxFrame, "TOPRIGHT", 2, 2)
    boxFrame.closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    boxFrame.closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    boxFrame.closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    boxFrame.closeBtn:SetScript("OnClick", function() boxFrame:Hide() end)
end

-- 创建滚动区域
local contactScroll = CreateFrame("ScrollFrame", "WIMContactScroll", boxFrame, "UIPanelScrollFrameTemplate")
contactScroll:SetWidth(132)
contactScroll:SetHeight(boxFrame:GetHeight()-30)
contactScroll:SetPoint("TOPLEFT", boxFrame, "TOPLEFT", 0, -24)

local pfUIoy,pfUIox
if IsAddOnLoaded("pfUI") then --pfUI适配
	pfUI.api.CreateBackdrop(boxFrame, nil, nil, .8)
	pfUI.api.CreateBackdropShadow(boxFrame)
	boxFrame:SetHeight(256)
	pfUI.api.SkinCloseButton(boxFrame.closeBtn,boxFrame,-6,-6)
	pfUI.api.SkinScrollbar(WIMContactScrollScrollBar)
	pfUIoy=0
	pfUIox=0
else
	pfUIoy=-5.3
	pfUIox=2
end

-- 创建联系人列表框
local contactFrame = CreateFrame("Frame", "WIMContactFrame", contactScroll)
contactFrame:SetWidth(155)
contactFrame:SetHeight(boxFrame:GetHeight()-10)
--("TOPLEFT", boxFrame, "TOPLEFT", 0, -40)
contactFrame:SetBackdrop{
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
}
contactFrame:SetBackdropColor(0.1,0.1,0.1,0)
--边框透明度设置
contactFrame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0)
contactFrame:SetPoint("TOPLEFT", contactScroll, "TOPLEFT", 0, 0)

-- 联系人按钮池
local contactButtons = {}

-- 计算表长度（兼容Lua 5.0）
local function tableLength(t)
    if not t then return 0 end
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- 十六进制职业颜色转RGB（如 "ff7d0a" -> 1, 0.49, 0.04）
local function HexColorToRGB(hex)
    local r = tonumber(string.sub(hex, 1, 2), 16) or 255
    local g = tonumber(string.sub(hex, 3, 4), 16) or 255
    local b = tonumber(string.sub(hex, 5, 6), 16) or 255
    return r/255, g/255, b/255
end

-- 查询联系人在线状态：1=在线 0=离线 nil=未知（非好友且非公会成员）
-- 优化：改为 O(1) 查表。WIM_LoadFriendList / WIM_LoadGuildList 在名单刷新事件时同步记录在线状态
--（原逻辑每个联系人都要全量扫好友列表+公会名单，联系人多、公会大时每次重建列表都是上万次 API 调用，多窗同收消息时卡顿主力）
local function GetContactOnlineStatus(name)
    if WIM_FriendList[name] then
        if WIM_FriendOnline and WIM_FriendOnline[name] then
            return 1
        end
        return 0
    end
    if WIM_GuildList[name] then
        if WIM_GuildOnline and WIM_GuildOnline[name] then
            return 1
        end
        return 0
    end
    return nil
end

--更新联系人列表
local btnlastuser
function UpdateWIMContactList()
    -- 清理旧按钮
    for _, btn in ipairs(contactButtons) do
        btn:Hide()
        -- 移除旧的个别清除按钮
        if btn.clearBtn then
            btn.clearBtn:Hide()
        end
    end

    local idx = 1
    local HistoryNames = {};
    local HistoryNamesU = {};
    local HistoryNamesNU = {};

    if WIM_History then
        for key, _ in pairs(WIM_History) do
            local unread = (WIM_contact_Unread and WIM_contact_Unread[key]) or 0
            if unread>0 then
                table.insert(HistoryNamesU, key);
            else
                table.insert(HistoryNamesNU, key);
            end
        end
	--按最近消息时间排序
	--优化：预计算每个联系人的最后消息时间，排序比较只做查表。
	--（原比较器每次比较都对两边各做 tableLength 全表遍历 + 字符串拼接，联系人×历史条数大时排序本身就是卡顿点）
        local lastTimes = {}
        for key in pairs(WIM_History) do
            local box = WIM_History[key]
            if type(box) == "table" and table.getn(box) > 0 then
                local last = box[table.getn(box)]
                lastTimes[key] = (last and last.date.." "..last.time) or ""
            else
                lastTimes[key] = ""
            end
        end
        table.sort(HistoryNamesU, function(a, b)
            return lastTimes[b] < lastTimes[a]
        end)
        table.sort(HistoryNamesNU, function(a, b)
            return lastTimes[b] < lastTimes[a]
        end)
        for _, v in pairs(HistoryNamesU) do
            table.insert(HistoryNames, v);
	end
        for _, v in pairs(HistoryNamesNU) do
            table.insert(HistoryNames, v);
	end
    end

    for _, HistoryName in ipairs(HistoryNames) do
        local btn = contactButtons[idx]
        if not btn then
            btn = CreateFrame("Button", "btn"..idx, contactFrame)
            btn:SetWidth(110)
            btn:SetHeight(18)
            btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            --btn往左边偏移一点
            btn:SetPoint("LEFT", contactFrame, "LEFT", -10, 0)
            
            if not btn.text then
                btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                btn.text:SetPoint("LEFT", btn, "LEFT", 14, 0)
                btn.text:SetJustifyH("LEFT")
                btn.text:SetWidth(100)
            end
            -- 在线状态指示点
            if not btn.online then
                btn.online = btn:CreateTexture(nil, "ARTWORK")
                btn.online:SetTexture("Interface\\AddOns\\WIM\\Images\\Aura72")
                btn.online:SetWidth(10)
                btn.online:SetHeight(10)
                btn.online:SetPoint("LEFT", btn, "LEFT", 2, 0)
            end
		--显示未读计数
            if not btn.unreadtex then
    		btn.unreadtex = btn:CreateTexture(nil, "ARTWORK")
    		btn.unreadtex:SetTexture("Interface\\AddOns\\WIM\\Images\\Aura72")
    		btn.unreadtex:SetWidth(20)
    		btn.unreadtex:SetHeight(20)
    		btn.unreadtex:SetVertexColor(1, 0, 0, 1) -- 红色
    		btn.unreadtex:SetPoint("RIGHT", btn, "RIGHT", -5, 0)
            end
            if not btn.unread then
                btn.unread = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                btn.unread:SetPoint("CENTER", btn.unreadtex, "CENTER", -1, 0)
                btn.unread:SetTextColor(1, 1, 1)
            end

            -- 添加删除按钮
            if not btn.clearBtn then
                btn.clearBtn = CreateFrame("Button", nil, btn)
                btn.clearBtn:SetWidth(20)
                btn.clearBtn:SetHeight(20)
                btn.clearBtn:SetPoint("RIGHT", btn, "RIGHT", 6, 0)
                btn.clearBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
                btn.clearBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
                btn.clearBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
                btn.clearBtn:Hide()
                -- 修改删除按钮的点击事件
		btn.clearBtn:SetScript("OnClick", function()
			PlaySound("igMainMenuClose");
			local senderName = btn.text and btn.text:GetText() or ""
			if senderName ~= "" then
				WIM_History[senderName] = nil;
				RefreshUnread(senderName) --刷新未读信息计数
				if getglobal('WIM_msgFrame'..senderName) then
					getglobal('WIM_msgFrame'..senderName):Hide()
				end
			end
		end)
		if IsAddOnLoaded("pfUI") then --pfUI适配
			pfUI.api.SkinCloseButton(btn.clearBtn,btn,0,-1)
		end
            end

            contactButtons[idx] = btn
        end
        btn.text:SetText(HistoryName)

        -- 显示未读计数
        local unread = (WIM_contact_Unread and WIM_contact_Unread[HistoryName]) or 0
        if unread > 0 then
            btn.unreadtex:Show()
            btn.unread:SetText(unread)
            btn.unread:Show()
            btn.text:SetTextColor(1, 1, 0.5)  -- 高亮未读联系人
        else
            btn.unreadtex:Hide()
            btn.unread:Hide()
            -- 按职业着色：who缓存 → 持久化记录 → pfUI玩家库，都没有用原默认金色
            local class = WIM_PlayerCache and WIM_PlayerCache[HistoryName] and WIM_PlayerCache[HistoryName].class
            if (not class or class == "") and WIM_ContactClass then
                class = WIM_ContactClass[HistoryName]
            end
            if (not class or class == "") and pfUI and pfUI_playerDB and pfUI_playerDB[HistoryName] then
                local pfc = pfUI_playerDB[HistoryName].class
                if pfc and WIM_PfUIClassMap then
                    class = WIM_PfUIClassMap[pfc] -- pfUI库是英文大写职业，映射回本地化职业名
                end
            end
            if (not class or class == "") and ShaguTweaks_cache and ShaguTweaks_cache["players"] and ShaguTweaks_cache["players"][HistoryName] then
                local stc = ShaguTweaks_cache["players"][HistoryName].class
                if stc and WIM_PfUIClassMap then
                    class = WIM_PfUIClassMap[stc] -- ShaguTweaks玩家库同为英文大写职业，映射回本地化职业名
                end
            end
            if class and WIM_ClassColors and WIM_ClassColors[class] then
                btn.text:SetTextColor(HexColorToRGB(WIM_ClassColors[class]))
            else
                btn.text:SetTextColor(1, 0.82, 0)  -- 普通颜色
            end
        end
        -- 在线状态指示：绿=在线 灰=离线 隐藏=未知（非好友且非公会成员）
        local status = GetContactOnlineStatus(HistoryName)
        if status == 1 then
            btn.online:SetVertexColor(0, 1, 0, 1)
            btn.online:Show()
        elseif status == 0 then
            btn.online:SetVertexColor(0.5, 0.5, 0.5, 1)
            btn.online:Show()
        else
            btn.online:Hide()
        end
        btn.unreadtex:ClearAllPoints()
        btn.unreadtex:SetPoint("LEFT", btn, "LEFT", -13, 0)

	--列表按钮排序
        btn:SetPoint("TOPLEFT", contactFrame, "TOPLEFT", 20, -5 - (idx-1)*20)
        btn:Show()
        btn.sender = HistoryName
        btn.lastClickTime = 0
	--左键点击列表按钮
        btn:SetScript("OnClick", function()
		local name = btn.text:GetText()
		-- 发送私聊时是否弹出窗口受 popOnSend 控制：关闭时回退默认聊天框
		if(WIM_Data.popOnSend) then
			WIM_PostMessage(name)
		else
			WIM_OpenDefaultWhisper(name)
		end
		--多窗口模式：点击联系人弹出独立窗口后隐藏联系人列表；单窗口模式盒子为中心 UI，保持打开
		if(WIM_Data.multiWindow ~= false and boxFrame and boxFrame:IsShown()) then
			boxFrame:Hide()
		end
        end)

	-- 右键点击列表按钮
        btn:SetScript("OnMouseUp", function() --显示删除按钮
		if arg1 == "RightButton" then
			btn.clearBtn:Show()
		end
        end)
	-- 添加悬停提示
        btn:SetScript("OnEnter", function()
                GameTooltip:SetOwner(btn.clearBtn, "ANCHOR_RIGHT")
                GameTooltip:AddLine("右键点击删除此联系人的历史记录")
                GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function()
		btn.clearBtn:Hide()
                GameTooltip:Hide()
        end)
        btn.clearBtn:SetScript("OnEnter", function() --删除按钮
		btn.clearBtn:Show()
        end)
        btn.clearBtn:SetScript("OnLeave", function()
		btn.clearBtn:Hide()
        end)

        idx = idx + 1
    end
    -- 每个按钮高度约20，最小高度200
    local totalHeight = math.max(200, (idx - 1) * 20)
    contactFrame:SetHeight(totalHeight)

    -- 让联系人列表成为滚动区域的内容
    contactScroll:SetScrollChild(contactFrame)
end

-- 打开盒子时刷新联系人列表
boxButton:SetScript("OnClick", function()
	if not IsShiftKeyDown() then
		--列表刷新由 boxFrame OnShow 兜底（不再提前手动重建，避免打开时重复重建两次）
		if boxFrame:IsShown() then
			boxFrame:Hide()
		else
			boxFrame:Show()
		end
	else
		boxButton:ClearAllPoints()
		boxButton:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 33, 0)
		buttonmove = 0
	end
end)

--按设置把聊天窗口吸附到联系人盒子的左/右侧（boxSide: "LEFT"=盒子在聊天窗口左侧）——单窗口模式用
local function WIM_ContactDockWindow(theWin)
	if WIM_Data and WIM_Data.boxSide == "LEFT" then
		theWin:SetPoint("TOPLEFT",boxFrame,"TOPRIGHT",pfUIoy, pfUIox);
	else
		theWin:SetPoint("TOPLEFT",boxFrame,"TOPLEFT",-theWin:GetWidth()-pfUIoy, pfUIox);
	end
end

--聊天框位置；多窗口模式=级联独立摆放可单独拖动；单窗口模式=吸附联系人盒子随其移动
function WIM_SetWindowLocation(theWin,ttype)
	if WIM_Data.multiWindow == false then
		--单窗口模式：窗口吸附在联系人盒子旁，拖动盒子/窗口一起移动，盒子关闭时窗口一起隐藏
		WIM_ContactDockWindow(theWin)
		theWin:SetScript("OnDragStart", function()
			boxFrame:StartMoving()
			WIM_ContactDockWindow(theWin)
		end)
		theWin:SetScript("OnDragStop", function()
			boxFrame:StopMovingOrSizing()
		end)
		boxFrame:SetScript("OnDragStart", function()
			boxFrame:StartMoving()
			WIM_ContactDockWindow(theWin);
		end)
		boxFrame:SetScript("OnDragStop", function()
			boxFrame:StopMovingOrSizing()
		end)
		boxFrame:SetScript("OnHide", function()
			--关盒子时隐藏"当前显示"的聊天窗口：用 WIM_NowShowWindow 实时取，
			--原闭包固定捕获最后一个创建的窗口，切换过联系人后关盒子会隐藏错窗口（表现为左侧聊天窗口关不掉）
			local curWin = WIM_NowShowWindow and getglobal('WIM_msgFrame'..WIM_NowShowWindow);
			if(curWin) then curWin:Hide(); end
		end)
	else
		--多窗口模式：D:\WIM 样式——纯级联定位，窗口拖动交给 XML 模板（不在此覆盖 OnDragStart/OnDragStop）
		local CascadeOffset_Left = 0;
		local CascadeOffset_Top = 0;
		if(WIM_Data.winCascade.enabled) then
			CascadeOffset_Left = WIM_CascadeDirection[WIM_Data.winCascade.direction].left;
			CascadeOffset_Top = WIM_CascadeDirection[WIM_Data.winCascade.direction].top;
		end
		theWin:SetPoint(
			"TOPLEFT",
			"UIParent",
			"BOTTOMLEFT",
			(WIM_Data.winLoc.left + WIM_CascadeStep*CascadeOffset_Left),
			(WIM_Data.winLoc.top + WIM_CascadeStep*CascadeOffset_Top)
		);
		--恢复联系人盒子独立拖动，并解除单窗口模式下"盒子关闭→隐藏窗口"的联动（多窗口照搬 D:\WIM）
		boxFrame:SetScript("OnDragStart", function() boxFrame:StartMoving() end)
		boxFrame:SetScript("OnDragStop", function() boxFrame:StopMovingOrSizing() end)
		boxFrame:SetScript("OnHide", nil)
	end
end

-- 初始化未读气泡
UpdateUnreadBubble()
