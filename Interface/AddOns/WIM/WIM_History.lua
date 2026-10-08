--[Functions: GUI Interface for WIM_History.xml

WIM_HistoryView_Name_Selected = "";
WIM_HistoryView_Filter_Selected = "";

function WIM_HistoryView_NameClick()
	if(WIM_HistoryView_Name_Selected ~= this.Name) then
		WIM_HistoryView_Filter_Selected = "";
	end
	WIM_HistoryView_Name_Selected = this.theName;
	WIM_HistoryViewFiltersScrollBar_Update();
end

function WIM_HistoryView_FilterClick()
	WIM_HistoryView_Filter_Selected = this.theName;
end

function WIM_HistoryViewNameScrollBar_Update()
	local line;
	local lineplusoffset;
	local HistoryNames = {};
	
	for key in WIM_History do
		table.insert(HistoryNames, key);
	end
	table.sort(HistoryNames);
	
	FauxScrollFrame_Update(WIM_HistoryFrameNameListScrollBar,table.getn(HistoryNames),15,16);
	for line=1,15 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(WIM_HistoryFrameNameListScrollBar);
		if lineplusoffset <= table.getn(HistoryNames) then
			getglobal("WIM_HistoryFrameNameListButton"..line.."Name"):SetText(HistoryNames[lineplusoffset]);
			getglobal("WIM_HistoryFrameNameListButton"..line).theName = HistoryNames[lineplusoffset];
			if ( WIM_HistoryView_Name_Selected == HistoryNames[lineplusoffset] ) then
				getglobal("WIM_HistoryFrameNameListButton"..line):LockHighlight();
			else
				getglobal("WIM_HistoryFrameNameListButton"..line):UnlockHighlight();
			end
			getglobal("WIM_HistoryFrameNameListButton"..line):Show();
		else
			getglobal("WIM_HistoryFrameNameListButton"..line):Hide();
		end
	end
end




function WIM_HistoryViewFiltersScrollBar_Update()
	local line;
	local lineplusoffset;
	local Filters = {};
	
	local tDate = "";
	local lDate = "";
	if(WIM_History[WIM_HistoryView_Name_Selected]) then
		for i=1,table.getn(WIM_History[WIM_HistoryView_Name_Selected]) do
			tDate = WIM_History[WIM_HistoryView_Name_Selected][i].date;
			if(tDate ~= lDate) then
				table.insert(Filters, tDate);
				lDate = tDate;
			end
		end
	end
	table.sort(Filters);
	table.insert(Filters, 1, WIM_L_NONESHOWALL);
	if(WIM_HistoryView_Filter_Selected == "") then
		--[WIM_HistoryView_Filter_Selected = Filters[1];
	end
	
	FauxScrollFrame_Update(WIM_HistoryFrameFilterListScrollBar,table.getn(Filters),7,16);
	for line=1,7 do
		lineplusoffset = line + FauxScrollFrame_GetOffset(WIM_HistoryFrameFilterListScrollBar);
		if lineplusoffset <= table.getn(Filters) then
			getglobal("WIM_HistoryFrameFilterListButton"..line.."Name"):SetText(Filters[lineplusoffset]);
			if(lineplusoffset == 1) then
				getglobal("WIM_HistoryFrameFilterListButton"..line).theName = "";
			else
				getglobal("WIM_HistoryFrameFilterListButton"..line).theName = Filters[lineplusoffset];
			end
			if ( WIM_HistoryView_Filter_Selected == Filters[lineplusoffset] ) then
				getglobal("WIM_HistoryFrameFilterListButton"..line):LockHighlight();
			else
				getglobal("WIM_HistoryFrameFilterListButton"..line):UnlockHighlight();
			end
			getglobal("WIM_HistoryFrameFilterListButton"..line):Show();
		else
			getglobal("WIM_HistoryFrameFilterListButton"..line):Hide();
		end
	end
	WIM_HistoryView_ShowMessages();
end


function WIM_HistoryView_ShowMessages()
	local tStamp = "";
	local tFrom = "";
	local tMsg = "";
	local prevDate = "";

	WIM_HistoryFrameMessageListScrollingMessageFrame:Clear();
	if(WIM_History[WIM_HistoryView_Name_Selected]) then
		for i = 1, table.getn(WIM_History[WIM_HistoryView_Name_Selected]) do
			if(WIM_HistoryView_Filter_Selected == "" or WIM_HistoryView_Filter_Selected == WIM_History[WIM_HistoryView_Name_Selected][i].date) then
				if(WIM_HistoryView_Filter_Selected == "") then
					if(prevDate ~= WIM_History[WIM_HistoryView_Name_Selected][i].date) then
						prevDate = WIM_History[WIM_HistoryView_Name_Selected][i].date
						WIM_HistoryFrameMessageListScrollingMessageFrame:AddMessage(" ");
						WIM_HistoryFrameMessageListScrollingMessageFrame:AddMessage("|cffffffff["..prevDate.."]|r");
					end
				end
				tStamp = "|cff"..WIM_RGBtoHex(WIM_Data.displayColors.sysMsg.r, WIM_Data.displayColors.sysMsg.g, WIM_Data.displayColors.sysMsg.b)..WIM_History[WIM_HistoryView_Name_Selected][i].time.."|r ";
				tFrom = "[|Hplayer:"..WIM_History[WIM_HistoryView_Name_Selected][i].from.."|h"..WIM_GetAlias(WIM_History[WIM_HistoryView_Name_Selected][i].from, true).."|h]: ";
				tMsg = tStamp..tFrom..WIM_History[WIM_HistoryView_Name_Selected][i].msg;
				if(WIM_History[WIM_HistoryView_Name_Selected][i].type == 1) then
					WIM_HistoryFrameMessageListScrollingMessageFrame:AddMessage(tMsg, WIM_Data.displayColors.wispIn.r, WIM_Data.displayColors.wispIn.g, WIM_Data.displayColors.wispIn.b);
				elseif(WIM_History[WIM_HistoryView_Name_Selected][i].type == 2) then
					WIM_HistoryFrameMessageListScrollingMessageFrame:AddMessage(tMsg, WIM_Data.displayColors.wispOut.r, WIM_Data.displayColors.wispOut.g, WIM_Data.displayColors.wispOut.b);
				end
			end
		end
	end
	WIM_UpdateScrollBars(WIM_HistoryFrameMessageListScrollingMessageFrame);
end

--[复制框一次性初始化：接管滚轮、准备文本测量
local WIM_HistoryCopyInited = false;
local WIM_HistoryCopyMeasure = nil;
function WIM_HistoryCopy_Init()
	if(WIM_HistoryCopyInited) then return; end;
	WIM_HistoryCopyInited = true;
	local sf = WIM_HistoryCopyFrameScroll;
	local eb = WIM_HistoryCopyFrameScrollEdit;
	--[滚轮滚动（参考ChatLog：编辑框和滚动框都接管，1.12模板不自带滚轮）
	local wheelFunc = function()
		local cur = sf:GetVerticalScroll();
		if(arg1 > 0) then
			sf:SetVerticalScroll(math.max(cur - 40, 0));
		else
			sf:SetVerticalScroll(math.min(cur + 40, sf:GetVerticalScrollRange()));
		end
	end;
	eb:EnableMouseWheel(true);
	eb:SetScript("OnMouseWheel", wheelFunc);
	sf:EnableMouseWheel(true);
	sf:SetScript("OnMouseWheel", wheelFunc);
	--[pfUI美化（与联系人盒子同一套 pfUI.api 调用）
	if IsAddOnLoaded("pfUI") then
		pfUI.api.CreateBackdrop(WIM_HistoryCopyFrame, nil, nil, .8)
		pfUI.api.CreateBackdropShadow(WIM_HistoryCopyFrame)
		pfUI.api.SkinCloseButton(WIM_HistoryCopyFrameExitButton, WIM_HistoryCopyFrame, -6, -6)
		pfUI.api.SkinScrollbar(WIM_HistoryCopyFrameScrollScrollBar)
		pfUI.api.SkinButton(WIM_HistoryFrameMessageListCopyButton)
	end
	--[测量用FontString，与编辑框同字体同宽，用于计算换行后的文本总高度
	WIM_HistoryCopyMeasure = WIM_HistoryCopyFrame:CreateFontString(nil, "OVERLAY");
	WIM_HistoryCopyMeasure:SetFont("Fonts\\FZLBJW.TTF", 12);
	WIM_HistoryCopyMeasure:SetJustifyH("LEFT");
	WIM_HistoryCopyMeasure:Hide();
end

--[复制当前查看的历史聊天内容：生成纯文本并弹出全选编辑框，用户按 Ctrl+C 复制
function WIM_History_CopyChat()
	local sel = WIM_HistoryView_Name_Selected;
	if(sel == "" or not WIM_History[sel]) then return; end;
	local lines = {};
	local prevDate = "";
	for i = 1, table.getn(WIM_History[sel]) do
		local h = WIM_History[sel][i];
		if(WIM_HistoryView_Filter_Selected == "" or WIM_HistoryView_Filter_Selected == h.date) then
			local msg = h.msg or "";
			msg = string.gsub(msg, "|T.-|t", ""); --[过滤贴图
			msg = string.gsub(msg, "|H.-|h(.-)|h", "%1"); --[链接保留显示文字
			msg = string.gsub(msg, "|c%x%x%x%x%x%x%x%x", "");
			msg = string.gsub(msg, "|r", "");
			if(WIM_HistoryView_Filter_Selected == "") then
				if(prevDate ~= h.date) then
					prevDate = h.date;
					tinsert(lines, "===== "..prevDate.." =====");
				end
				tinsert(lines, "["..h.time.."] "..h.from..": "..msg);
			else
				tinsert(lines, "["..h.date.." "..h.time.."] "..h.from..": "..msg);
			end
		end
	end
	local text = table.concat(lines, "\n");
	if(string.len(text) > 60000) then --[内容过长时只保留最后部分，防止编辑框卡顿
		text = string.sub(text, -60000);
	end
	WIM_HistoryCopy_Init();
	local sf = WIM_HistoryCopyFrameScroll;
	local eb = WIM_HistoryCopyFrameScrollEdit;
	eb:SetText(text);
	WIM_HistoryCopyFrame:Show(); --[先显示，隐藏状态下量不到文本排版高度
	--[多行编辑框不会自动撑高，按文本实际高度设置，滚动条/滚轮才有滚动范围
	WIM_HistoryCopyMeasure:SetWidth(eb:GetWidth());
	WIM_HistoryCopyMeasure:SetText(text);
	local h = WIM_HistoryCopyMeasure:GetHeight();
	if(h < sf:GetHeight()) then h = sf:GetHeight(); end;
	eb:SetHeight(h);
	sf:UpdateScrollChildRect(); --[子框尺寸变了必须手动刷新，否则滚动范围仍是0
	sf:SetVerticalScroll(0);
	eb:SetFocus();
	eb:HighlightText(0);
end
