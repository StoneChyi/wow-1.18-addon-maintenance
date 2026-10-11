local curChannelList = {"工会","团队","队伍","近聊","自己"}
local smsg = ""
local RC_SendQueue = {}     -- 待发送消息队列（合并+节流，防刷屏限制）
local RC_LastSendTime = 0
local RC_SendFrame = nil
local channelselect = "团队"
local buffraidlist={}
local dpsnamelist={
CHECKBUFFC5NAME1,
CHECKBUFFC5NAME2,
CHECKBUFFC5NAME3,
CHECKBUFFC5NAME4,
CHECKBUFFC5NAME5,
CHECKBUFFC5NAME6,
CHECKBUFFC5NAME7,
CHECKBUFFC5NAME8,
CHECKBUFFC5NAME9,
CHECKBUFFC5NAME10,
CHECKBUFFC5NAME11,
CHECKBUFFC5NAME12,
CHECKBUFFC5NAME13,
CHECKBUFFC5NAME14,
CHECKBUFFC5NAME15,
CHECKBUFFC5NAME16,
CHECKBUFFC5NAME17,
CHECKBUFFC5NAME18,
CHECKBUFFC5NAME19,
CHECKBUFFC5NAME20,
CHECKBUFFC5NAME21,
CHECKBUFFC5NAME22,
}
local dpstextlist={
CHECKBUFFC5TEXT1,
CHECKBUFFC5TEXT2,
CHECKBUFFC5TEXT3,
CHECKBUFFC5TEXT4,
CHECKBUFFC5TEXT5,
CHECKBUFFC5TEXT6,
CHECKBUFFC5TEXT7,
CHECKBUFFC5TEXT8,
CHECKBUFFC5TEXT9,
CHECKBUFFC5TEXT10,
CHECKBUFFC5TEXT11,
CHECKBUFFC5TEXT12,
CHECKBUFFC5TEXT13,
CHECKBUFFC5TEXT14,
CHECKBUFFC5TEXT15,
CHECKBUFFC5TEXT16,
CHECKBUFFC5TEXT17,
CHECKBUFFC5TEXT18,
CHECKBUFFC5TEXT19,
CHECKBUFFC5TEXT20,
CHECKBUFFC5TEXT21,
CHECKBUFFC5TEXT22,	
}
local bufftextlist = {
CHECKBUFFA1TEXT,
CHECKBUFFA2TEXT,
CHECKBUFFA3TEXT,
CHECKBUFFA4TEXT,
CHECKBUFFA5TEXT,
CHECKBUFFA6TEXT,
CHECKBUFFA7TEXT,
CHECKBUFFA8TEXT,
CHECKBUFFA9TEXT,
CHECKBUFFA10TEXT,
CHECKBUFFA11TEXT,
CHECKBUFFB1TEXT,
CHECKBUFFB2TEXT,
CHECKBUFFB3TEXT1,
CHECKBUFFB4TEXT1,
CHECKBUFFB5TEXT1,
CHECKBUFFB6TEXT,
CHECKBUFFB7TEXT1,
CHECKBUFFC4TEXT,
CHECKBUFFB3TEXT2,
CHECKBUFFB4TEXT2,
CHECKBUFFB5TEXT2,
CHECKBUFFB7TEXT2,
CHECKBUFFB8TEXT,
CHECKBUFFB9TEXT,
}
local buffnamelist={}
local checknum = 0
local addname=""
local checknumds = 0
local raidnumber=0
local buffd9checked=0
local potionCount = 0
local buttontypeq={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}  -- 扩展至24
local buttontypen={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}  -- 扩展至24
local buttontypes={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}  -- 扩展至24
local simclasslist={
SIMCLASS1,
SIMCLASS2,
SIMCLASS3,
SIMCLASS4,
SIMCLASS5,
SIMCLASS6,
SIMCLASS7,
SIMCLASS8,
SIMCLASS9,
}
local classlist = {
LOCALCLASS1,
LOCALCLASS2,
LOCALCLASS3,
LOCALCLASS4,
LOCALCLASS5,
LOCALCLASS6,
LOCALCLASS7,
LOCALCLASS8,
LOCALCLASS9,
}
-- 职业颜色（索引与 classlist 对应）
local classColorHex = {
	"C79C6E", -- 战士
	"FFF569", -- 盗贼
	"69CCF0", -- 法师
	"ABD473", -- 猎人
	"FFFFFF", -- 牧师
	"F58CBA", -- 圣骑士
	"FF7D0A", -- 德鲁伊
	"9482C9", -- 术士
	"0070DE", -- 萨满
}
-- 按职业色包裹玩家名
local function RC_ColorName(classIdx, name)
	if name and classIdx and classColorHex[classIdx] then
		return "|cff"..classColorHex[classIdx]..name.."|r"
	end
	return name or ""
end
local shuliang = 0
RC_version = "1.0"
RC_MainLabel = "BUFF检查"

function RC_OnLoad()
	this:RegisterEvent("VARIABLES_LOADED");
	this:RegisterEvent("PLAYER_ENTERING_WORLD")
	SlashCmdList["RC"] = RC_SlashHandler;
	SLASH_RC1 = "/rc";
	-- 标题字号放大（沿用当前字体路径，仅调大小）
	local tf = getglobal("RC_MainFrameTitleText")
	if tf and tf.SetFont and GameFontNormal and GameFontNormal.GetFont then
		local fpath = GameFontNormal:GetFont()
		if fpath then
			tf:SetFont(fpath, 18)
		end
	end
end

function RC_OnEvent()
	if ( event == "VARIABLES_LOADED" ) then
		DEFAULT_CHAT_FRAME:AddMessage("RaidCheck"..RC_version.."输入命令/rc打开菜单")
	end
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		RC_Initialize()
	end
end

function RC_Initialize()
	this:UnregisterEvent("PLAYER_ENTERING_WORLD")
	RC_ChannelDropDown_OnShow()
	RC_MainFrameEditBox:SetText("75")	
	-- 添加小队模式支持
	if GetNumRaidMembers() > 0 then
		raidnumber = GetNumRaidMembers()
	elseif GetNumPartyMembers() > 0 then
                raidnumber = GetNumPartyMembers() + 1
	end
	RC_Clean()
end

function RC_SlashHandler(msg)
	RC_MainFrame:Show()
	RC_Clean()
end

function RC_ChannelDropDown_Initialize()
	local info;
	for i = 1, getn(curChannelList), 1 do
		info = {
			text = curChannelList[i];
			func = RC_ChannelDropDown_OnClick;
		};
		UIDropDownMenu_AddButton(info);
		if (curChannelList[i] == channelselect) then
			UIDropDownMenu_SetSelectedID(RC_MainFrameChannelsDropdown, i);
			UIDropDownMenu_SetText(curChannelList[i], RC_MainFrameChannelsDropdown);
		end
	end
end

function RC_ChannelDropDown_OnClick()
	i = this:GetID();
	UIDropDownMenu_SetSelectedID(RC_MainFrameChannelsDropdown, i);
	channelselect = this:GetText();
	RC_ChannelDropDown_OnShow();
end

function RC_ChannelDropDown_OnShow()
	UIDropDownMenu_Initialize(RC_MainFrameChannelsDropdown, RC_ChannelDropDown_Initialize);
	UIDropDownMenu_SetWidth(64, RC_MainFrameChannelsDropdown);
end

function RC_ClassAll()
	for i=1,11,1 do
		local checkBoxName = "RC_MainFrameBuffd"..i.."CheckBox"
		getglobal(checkBoxName):SetChecked(1)
	end
end

function RC_Clean()
	for i=1,11,1 do
		local checkBoxName = "RC_MainFrameBuffa"..i.."Button"
		getglobal(checkBoxName):SetTextColor(1, 0.82, 0)
	end
	for i=1,7,1 do
		local checkBoxName = "RC_MainFrameBuffb"..i.."Button"
		getglobal(checkBoxName):SetTextColor(1, 0.82, 0)
	end
	for i=1,6,1 do   -- 改为6，对应c1-c6
		local checkBoxName = "RC_MainFrameBuffc"..i.."Button"
		getglobal(checkBoxName):SetTextColor(1, 0.82, 0)
	end
	for i=1,10,1 do
		local checkBoxName = "RC_MainFrameBuffd"..i.."CheckBox"
		getglobal(checkBoxName):SetChecked(0)
	end
	buttontypeq={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
	buttontypen={1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
	buttontypes={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	buttontypes[25] = 0
	buttontypes[26] = 0
	RC_SendQueue = {}
	-- 小队模式下也显示检查按钮
	if GetNumRaidMembers() > 0 then
		if IsRaidLeader() or IsRaidOfficer() then
			RC_MainFrameBuffd10CheckBox:Show()
		else
			RC_MainFrameBuffd10CheckBox:Show()
		end
	elseif GetNumPartyMembers() > 0 then
            RC_MainFrameBuffd10CheckBox:Show()
	end
end

function RC_SetTip()
	if this == RC_MainFrameBuffa1Button then
		if (buttontypen[1]==0 and buttontypeq[1]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[1].."人缺智力"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][6]==i and buffraidlist[j][7]==0) then
						RC_ResultToolTip:AddLine((i.."队"..RC_ColorName(buffraidlist[j][5], simclasslist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffa2Button then
		if (buttontypen[2]==0 and buttontypeq[2]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[2].."人缺耐力"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][6]==i and buffraidlist[j][8]==0) then
						RC_ResultToolTip:AddLine((i.."队"..RC_ColorName(buffraidlist[j][5], simclasslist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end			
		end
	end
	if this == RC_MainFrameBuffa3Button then		
		if (buttontypen[3]==0 and buttontypeq[3]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[3].."人缺精神"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][6]==i and buffraidlist[j][9]==0) then
						RC_ResultToolTip:AddLine((i.."队"..RC_ColorName(buffraidlist[j][5], simclasslist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffa4Button then
		if (buttontypen[4]==0 and buttontypeq[4]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[4].."人缺爪子"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][6]==i and buffraidlist[j][10]==0) then
						RC_ResultToolTip:AddLine((i.."队"..RC_ColorName(buffraidlist[j][5], simclasslist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffa5Button then
		if (buttontypen[5]==0 and buttontypeq[5]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[5].."人缺暗抗"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][6]==i and buffraidlist[j][11]==0) then
						RC_ResultToolTip:AddLine((i.."队"..RC_ColorName(buffraidlist[j][5], simclasslist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffa6Button then
		if (buttontypen[6]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[6].."人已绑灵魂石"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for j=1,raidnumber,1 do
				if (buffraidlist[j][4]>0 and buffraidlist[j][12]==1 and (buffraidlist[j][5]==5 or buffraidlist[j][5]==6)) then
					RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
				end
			end
		else
			RC_ResultToolTip:AddLine("警告!无人绑灵魂石", 1, 0, 0)
		end
	end
	if this == RC_MainFrameBuffa7Button then
		if (buttontypen[7]==0 and buttontypeq[7]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[7].."人缺智慧祝福"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][13]==0) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffa8Button then
		if (buttontypen[8]==0 and buttontypeq[8]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[8].."人缺王者祝福"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][14]==0) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end	
	if this == RC_MainFrameBuffa9Button then
		if (buttontypen[9]==0 and buttontypeq[9]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[9].."人缺光明祝福"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][15]==0) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end		
	if this == RC_MainFrameBuffa10Button then
		if (buttontypen[10]==0 and buttontypeq[10]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[10].."人缺力量祝福"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,2,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][16]==0) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end		
	if this == RC_MainFrameBuffa11Button then
		if (buttontypen[11]==0 and buttontypeq[11]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[11].."人缺拯救祝福"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][17]==0) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end	
	if this == RC_MainFrameBuffb1Button then
		if (buttontypen[12]==0 and buttontypeq[12]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			local hejiPlayers = {}
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i) then
						local yaojiCount = 0
						local yaojiNames = {}
						if buffraidlist[j][27] == 1 then yaojiCount = yaojiCount + 1; table.insert(yaojiNames, "泰坦") end
						if buffraidlist[j][28] == 1 then yaojiCount = yaojiCount + 1; table.insert(yaojiNames, "精炼") end
						if buffraidlist[j][29] == 1 then yaojiCount = yaojiCount + 1; table.insert(yaojiNames, "超能") end
						if yaojiCount == 0 then
							RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0, 0)  -- 无药剂显示红色
						else
							buttontypes[12] = shuliang
							local yaojiText = table.concat(yaojiNames, "/")
							RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])..":"..yaojiText), 1, 0.82, 0)
						end
					end
				end
			end
		end
	end

	if this == RC_MainFrameBuffb2Button then
		if (buttontypen[13]==0 and buttontypeq[13]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[13].."人无赞扎之魂"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][19]==0) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffb3Button then
		if (buttontypen[14]==0 and buttontypeq[14]==0) then
			local nlname="人无暗抗药剂"
			local nlnum=1
			if buffd9checked==1 then
				nlname="人无强效暗抗"
				nlnum=2
			end
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[14]..nlname), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][20]<nlnum) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffb4Button then
		if (buttontypen[15]==0 and buttontypeq[15]==0) then
			local nlname="人无火抗药剂"
			local nlnum=1
			if buffd9checked==1 then
				nlname="人无强效火抗"
				nlnum=2
			end
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[15]..nlname), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][21]<nlnum) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffb5Button then
		if (buttontypen[16]==0 and buttontypeq[16]==0) then
			local nlname="人无冰抗药剂"
			local nlnum=1
			if buffd9checked==1 then
				nlname="人无强效冰抗"
				nlnum=2
			end
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[16]..nlname), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][22]<nlnum) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffb6Button then
		if (buttontypen[17]==0 and buttontypeq[17]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[17].."人无奥抗药剂"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][23]==0) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffb7Button then
		if (buttontypen[18]==0 and buttontypeq[18]==0) then
			local nlname="人无自然药剂"
			local nlnum=1
			if buffd9checked==1 then
				nlname="人无强效自然"
				nlnum=2
			end
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[18]..nlname), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for i=1,9,1 do
				for j=1,raidnumber,1 do
					if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i and buffraidlist[j][24]<nlnum) then
						RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
					end
				end
			end
		end
	end
	if this == RC_MainFrameBuffc1Button then
		if (buttontypen[19]==0 and buttontypeq[19]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[19].."人未到位"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for j=1,raidnumber,1 do
				if (buffraidlist[j][2]==0) then
					RC_ResultToolTip:AddLine(("掉线:"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0, 0)
				end
			end
			for j=1,raidnumber,1 do
				if (buffraidlist[j][2]==1) then
					RC_ResultToolTip:AddLine(("死亡:"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0, 0)
				end
			end
			for j=1,raidnumber,1 do
				if (buffraidlist[j][2]==2) then
					RC_ResultToolTip:AddLine(("过远:"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
				end
			end
		end
	end
	if this == RC_MainFrameBuffc2Button then
		if (buttontypen[20]==0 and buttontypeq[20]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[20].."人有PVP"), 1, 0.82, 0)
			RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
			for j=1,raidnumber,1 do
				if (buffraidlist[j][4]>0 and buffraidlist[j][3]==1) then
					RC_ResultToolTip:AddLine((RC_ColorName(buffraidlist[j][5], classlist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])), 1, 0.82, 0)
				end
			end
		end
	end
if this == RC_MainFrameBuffc3Button then
    if (buttontypen[21]==0 and buttontypeq[21]==0) then
        local hpnamelist={}
        local hpgrouplist={}
        local hpclasslist={}
        local hphplist={}
        local hpsortname={}
        local hpsortgroup={}
        local hpsortclass={}
        local hpsorthp={}
        
        for j=1,raidnumber,1 do
            if (buffraidlist[j][4]>0 and buffraidlist[j][4]<(RC_MainFrameHpNowButton:GetText()*1)) then
                table.insert(hpnamelist, buffraidlist[j][1])
                table.insert(hpgrouplist, buffraidlist[j][6])
                table.insert(hpclasslist, buffraidlist[j][5])
                table.insert(hphplist, buffraidlist[j][4])
            end
        end
        
        for i=1,buttontypes[21],1 do
            j=1
            k=1
            tempname=hpnamelist[1]
            tempgroup=hpgrouplist[1]
            tempclass=hpclasslist[1]
            temphp=hphplist[1]
            
            while hphplist[j]~=nil do
                if temphp>=hphplist[j] then
                    temphp=hphplist[j]
                    k=j
                end
                j=j+1
            end
            
            table.insert(hpsortname,hpnamelist[k])
            table.insert(hpsortgroup,hpgrouplist[k])
            table.insert(hpsortclass,hpclasslist[k])
            table.insert(hpsorthp,hphplist[k])
            table.remove(hpnamelist,k)
            table.remove(hpgrouplist,k)
            table.remove(hpclasslist,k)
            table.remove(hphplist,k)
        end
        
        RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
        RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[21].."人装等不足"), 1, 0.82, 0)
        if (buttontypes[26] or 0) > 0 then
            RC_ResultToolTip:AddLine(("未检测:"..buttontypes[26].."人"), 0.6, 0.6, 0.6)
        end
        RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
        
        for i=1,buttontypes[21],1 do
            local displayText = hpsortgroup[i].."队"..RC_ColorName(hpsortclass[i], simclasslist[hpsortclass[i]])..":"..RC_ColorName(hpsortclass[i], hpsortname[i])..":"..hpsorthp[i]
            RC_ResultToolTip:AddLine(displayText, 1, 0.82, 0)
        end
        for j=1,raidnumber,1 do
            if type(buffraidlist[j][31])=="string" then
                RC_ResultToolTip:AddLine(buffraidlist[j][6].."队"..RC_ColorName(buffraidlist[j][5], simclasslist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])..":"..buffraidlist[j][31], 0.6, 0.6, 0.6)
            end
        end
    end
end
	if this == RC_MainFrameBuffc5Button then
		if (buttontypen[23]==0) then
			RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
			RC_ResultToolTip:AddLine("DPS增强情况:", 1, 0.82, 0)	
			-- 按职业和药剂种类分组统计
			local classPotionGroups = {}
			local classCounts = {}
			local maxDisplay = 30
			local currentPage = 1
			
			for j=1,raidnumber,1 do
	if buffraidlist[j] and buffraidlist[j][4]>0 and (buffraidlist[j][5] == 1 or buffraidlist[j][5] == 2 or buffraidlist[j][5] == 3 or buffraidlist[j][5] == 4 or buffraidlist[j][5] == 8) then
					local classIndex = buffraidlist[j][5]
					local potion = buffraidlist[j][26] or "无"
					if not classPotionGroups[classIndex] then
						classPotionGroups[classIndex] = {}
						classCounts[classIndex] = 0
					end
					if not classPotionGroups[classIndex][potion] then
						classPotionGroups[classIndex][potion] = {}
					end
					table.insert(classPotionGroups[classIndex][potion], buffraidlist[j][1])
					classCounts[classIndex] = classCounts[classIndex] + 1
				end
			end
			
			local totalItems = 0
			for classIndex, potions in pairs(classPotionGroups) do
				for potion, players in pairs(potions) do
					totalItems = totalItems + 1
				end
			end
			local totalPages = math.ceil(totalItems / maxDisplay)
			
			RC_ResultToolTip:AddLine("第"..currentPage.."页/共"..totalPages.."页", 0, 1, 0)
			
			local displayed = 0
			local startIndex = (currentPage - 1) * maxDisplay + 1
			local endIndex = currentPage * maxDisplay
			
			for classIndex, potions in pairs(classPotionGroups) do
				local sortedPotions = {}
				for potion, players in pairs(potions) do
					table.insert(sortedPotions, {potion=potion, players=players, count=table.getn(players)})
				end
				table.sort(sortedPotions, function(a,b) return a.count > b.count end)
				
				for _, data in ipairs(sortedPotions) do
					displayed = displayed + 1
					if displayed >= startIndex and displayed <= endIndex then
						local colorR, colorG, colorB = 1, 0.82, 0
						local buffCount = 0
						for k=1,16,1 do
							if string.find(data.potion, dpsnamelist[k]) then
								buffCount = buffCount + 1
							end
						end
						
						if buffCount <= 1 then
							colorR, colorG, colorB = 1, 0, 0
						end
						
						RC_ResultToolTip:AddLine("["..buffCount.."]"..RC_ColorName(classIndex, classlist[classIndex])..":"..RC_ColorName(classIndex, table.concat(data.players, ","))..":"..data.potion, colorR, colorG, colorB)
					end
				end
			end
		end
	end
    -- 新增奥抗检测ToolTip
    if this == RC_MainFrameBuffc6Button then
        if (buttontypen[24]==0 and buttontypeq[24]==0) then
            local lowResPlayers = {}
            local notDetectPlayers = {}
            local threshold = tonumber(RC_MainFrameBuffcHpButton:GetText()) or 0
            for j=1, raidnumber, 1 do
                local note = buffraidlist[j][31]
                if type(note)=="string" then
                    -- 未检测到的人：离线 / 死亡 / 距离过远
                    table.insert(notDetectPlayers, {
                        name = buffraidlist[j][1],
                        group = buffraidlist[j][6],
                        class = buffraidlist[j][5],
                        reason = note
                    })
                elseif buffraidlist[j][4] > 0 and (buffraidlist[j][30] or 0) < threshold then
                    table.insert(lowResPlayers, {
                        name = buffraidlist[j][1],
                        group = buffraidlist[j][6],
                        class = buffraidlist[j][5],
                        res = buffraidlist[j][30] or 0
                    })
                end
            end
            table.sort(lowResPlayers, function(a,b) return a.group < b.group end)
            table.sort(notDetectPlayers, function(a,b) return a.group < b.group end)

            RC_ResultToolTip:AddLine(addname, 1, 0.82, 0)
            RC_ResultToolTip:AddLine(("检查"..checknum.."队员:"..buttontypes[24].."人奥抗不足"), 1, 0.82, 0)
            if (buttontypes[25] or 0) > 0 then
                RC_ResultToolTip:AddLine(("未检测:"..buttontypes[25].."人"), 0.6, 0.6, 0.6)
            end
            RC_ResultToolTip:AddLine(" ", 1, 0.82, 0)
            for _, p in ipairs(lowResPlayers) do
                RC_ResultToolTip:AddLine(p.group.."队"..RC_ColorName(p.class, simclasslist[p.class])..":"..RC_ColorName(p.class, p.name)..":"..p.res, 1, 0.82, 0)
            end
            for _, p in ipairs(notDetectPlayers) do
                RC_ResultToolTip:AddLine(p.group.."队"..RC_ColorName(p.class, simclasslist[p.class])..":"..RC_ColorName(p.class, p.name)..":"..p.reason, 0.6, 0.6, 0.6)
            end
        end
    end
end

function RC_Report()
    local numLines = RC_ResultToolTip:NumLines()
    local lines = {}

    if numLines == 1 then
        table.insert(lines, getglobal("RC_ResultToolTipTextLeft1"):GetText())
    elseif this == RC_MainFrameBuffb1Button then
        local noHejiPlayers = {}
        for i=1,9,1 do
            for j=1,raidnumber,1 do
                if (buffraidlist[j][4]>0 and buffraidlist[j][5]==i) then
                    local yaojiCount = 0
                    if buffraidlist[j][27] == 1 then yaojiCount = yaojiCount + 1 end
                    if buffraidlist[j][28] == 1 then yaojiCount = yaojiCount + 1 end
                    if buffraidlist[j][29] == 1 then yaojiCount = yaojiCount + 1 end
                    if yaojiCount == 0 then
                        table.insert(noHejiPlayers, RC_ColorName(buffraidlist[j][5], classlist[i])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1]))
                    end
                end
            end
        end
        if table.getn(noHejiPlayers) > 0 then
            table.insert(lines, "未吃合剂人员:"..table.concat(noHejiPlayers, " "))
        end
    else
        if this == RC_MainFrameBuffc5Button then
            table.insert(lines, "全体检查")
            table.insert(lines, "DPS增强情况：")
            for j=1,raidnumber,1 do
                if buffraidlist[j][4]>0 and (buffraidlist[j][5] == 1 or buffraidlist[j][5] == 2 or buffraidlist[j][5] == 3 or buffraidlist[j][5] == 4 or buffraidlist[j][5] == 8) then
                    local playerBuffCount = 0
                    if buffraidlist[j][26] and buffraidlist[j][26] ~= "无" then
                        for k=1,16,1 do
                            if string.find(buffraidlist[j][26], dpsnamelist[k]) then
                                playerBuffCount = playerBuffCount + 1
                            end
                        end
                    end
                    if playerBuffCount == 1 then
                        table.insert(lines, RC_ColorName(buffraidlist[j][5], classlist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])..":"..buffraidlist[j][26])
                    end
                end
            end
            for j=1,raidnumber,1 do
                if buffraidlist[j][4]>0 and (buffraidlist[j][5] == 1 or buffraidlist[j][5] == 2 or buffraidlist[j][5] == 3 or buffraidlist[j][5] == 4 or buffraidlist[j][5] == 8) then
                    if buffraidlist[j][26] == nil or buffraidlist[j][26] == "" then
                        table.insert(lines, RC_ColorName(buffraidlist[j][5], classlist[buffraidlist[j][5]])..":"..RC_ColorName(buffraidlist[j][5], buffraidlist[j][1])..":无药剂")
                    end
                end
            end
            for i = 1, numLines do 
                local lineText = getglobal("RC_ResultToolTipTextLeft" .. i):GetText() 
                if lineText and lineText ~= " " then
                    if string.match(lineText, ":无$") then
                        table.insert(lines, lineText)
                    end
                end 
            end 
        else
            for i = 1, numLines do
                local lineText = getglobal("RC_ResultToolTipTextLeft" .. i):GetText()
                if lineText and lineText ~= " " then
                    table.insert(lines, lineText)
                end
            end
        end
    end
    RC_QueueMsgs(lines)
end

-- 将提示行合并为长消息入队，由节流帧按间隔发送，避免触发聊天刷屏限制
function RC_QueueMsgs(lines)
    local buf = ""
    for i = 1, table.getn(lines), 1 do
        local line = lines[i]
        if line and line ~= "" then
            if buf == "" then
                buf = line
            elseif string.len(buf) + string.len(line) + 1 <= 250 then
                buf = buf .. " " .. line
            else
                table.insert(RC_SendQueue, buf)
                buf = line
            end
        end
    end
    if buf ~= "" then
        table.insert(RC_SendQueue, buf)
    end
    if not RC_SendFrame then
        RC_SendFrame = CreateFrame("Frame", "RC_SendThrottleFrame", UIParent)
        RC_SendFrame:SetScript("OnUpdate", function()
            if table.getn(RC_SendQueue) == 0 then return end
            if GetTime() - RC_LastSendTime < 0.5 then return end
            RC_LastSendTime = GetTime()
            smsg = table.remove(RC_SendQueue, 1)
            RC_SayChannel()
        end)
    end
    local pending = table.getn(RC_SendQueue)
    if pending > 1 then
        DEFAULT_CHAT_FRAME:AddMessage("RaidCheck: 消息较多，已合并为"..pending.."条并间隔发送，防止刷屏限制")
    end
end

-- 单条消息独立入队（不合并），供 BUFF 分配通报按 HDL 格式逐段发送
function RC_QueueMsgOne(msg)
    if not msg or msg == "" then return end
    table.insert(RC_SendQueue, msg)
    if not RC_SendFrame then
        RC_SendFrame = CreateFrame("Frame", "RC_SendThrottleFrame", UIParent)
        RC_SendFrame:SetScript("OnUpdate", function()
            if table.getn(RC_SendQueue) == 0 then return end
            if GetTime() - RC_LastSendTime < 0.5 then return end
            RC_LastSendTime = GetTime()
            smsg = table.remove(RC_SendQueue, 1)
            RC_SayChannel()
        end)
    end
end

function RC_Check()
    raidnumber = GetNumRaidMembers()
    local checkcheckc = 0
    local checkcheckd = ""
    addname = ""
    for i=1,9,1 do
        local checkBoxName = "RC_MainFrameBuffd"..i.."CheckBox"
        if getglobal(checkBoxName):GetChecked() then
            checkcheckc = 1
        end
    end
    local tempb = 0
    for i=1,9,1 do
        local checkBoxName = "RC_MainFrameBuffd"..i.."CheckBox"
        if getglobal(checkBoxName):GetChecked() then
            checkcheckd = checkcheckd..simclasslist[i]
            tempb = tempb+1
        end
    end
    if checkcheckc == 0 then 
        DEFAULT_CHAT_FRAME:AddMessage(NOSELECTCLASS)
        return
    end
    if (tempb==9) then
        addname = "全体检查"
    else
        addname = checkcheckd.."检查"
    end
    if(GetNumRaidMembers()==0) then 
        DEFAULT_CHAT_FRAME:AddMessage(NORAID)
        return
    end
    buffraidlist = {}
    checknum = 0
    checknumds = 0
    for i = 1, GetNumRaidMembers(), 1 do
        -- 初始化buffraidlist[i]，扩展至31个字段（索引30存奥抗，31存未检测原因：离线/死亡/距离过远）
        table.insert(buffraidlist, {"",0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,"",0,0,0,0,0})
        local raidnum = "raid"..i
        local rccname, rccrank, rccgroup = GetRaidRosterInfo(i)
        buffraidlist[i][1] = rccname
        if UnitIsConnected(raidnum) then 
            if UnitIsDeadOrGhost(raidnum) then
                buffraidlist[i][2] = 1
            else
                if UnitIsVisible(raidnum) then
                    buffraidlist[i][2] = 3
                else
                    buffraidlist[i][2] = 2
                end
            end
        end
        if UnitIsPVP(raidnum) then
            buffraidlist[i][3] = 1
        end
        buffraidlist[i][6] = rccgroup
        for j = 1,9,1 do
            if (classlist[j]==UnitClass(raidnum)) then
                buffraidlist[i][5] = j
            end
        end
        local checkBoxName = "RC_MainFrameBuffd"..buffraidlist[i][5].."CheckBox"
        if (getglobal(checkBoxName):GetChecked() and buffraidlist[i][2]<=1) then
            checknumds = checknumds+1
            -- 未检测原因：状态0=离线，1=死亡（记录到索引31，供奥抗提示用）
            buffraidlist[i][31] = (buffraidlist[i][2]==0) and "离线" or "死亡"
        end
        if (getglobal(checkBoxName):GetChecked() and buffraidlist[i][2]>1) then
            checknum = checknum+1
            if buffraidlist[i][2] == 2 then
                -- 在线且存活但 UnitIsVisible 为 false：距离过远，装等/抗性/增益均无法可靠检测
                buffraidlist[i][31] = "距离过远"
            else
            buffraidlist[i][4] = ItemSocre and ItemSocre.ScanUnit and ItemSocre:ScanUnit(raidnum) or 0
            if buffraidlist[i][5]<3 then
                buffraidlist[i][7] = 1
                buffraidlist[i][9] = 1
                buffraidlist[i][13] = 1
            else
                buffraidlist[i][16] = 1
            end
            --- 获取奥术抗性 ---
            if StatScanner_ScanAllInspect then
                    StatScanner_ScanAllInspect(raidnum)
                end
                if SC_BuffScanner_ScanAllInspect then
                    SC_BuffScanner_ScanAllInspect(StatScanner_bonuses, raidnum)
                end
                if StatCompare_CharStats_Scan then
                    StatCompare_CharStats_Scan(StatScanner_bonuses, raidnum)
                end
                local arcaneRes = CharStats_fullvals and CharStats_fullvals["ARCANERES"]
                if not arcaneRes then
                    arcaneRes = UnitResistance(raidnum, 6)  -- 6 对应奥术抗性（0=护甲 1=神圣 2=火焰 3=自然 4=冰霜 5=暗影 6=奥术）
                end
                buffraidlist[i][30] = arcaneRes or 0
            
            local buffid = 1 
            while (UnitBuff(raidnum,buffid)) do
                RC_ChkBuffToolTip:ClearLines()
                RC_ChkBuffToolTip:SetUnitBuff(raidnum,buffid)
                buffname = RC_ChkBuffToolTipTextLeft1:GetText()
                bufftext = RC_ChkBuffToolTipTextLeft2:GetText()
                for k=1,19,1 do
                    if (bufftext==bufftextlist[k]) then
                        buffraidlist[i][k+6] = 1
                        break
                    end
                end
                if (bufftext==bufftextlist[12]) then
                    buffraidlist[i][27] = 1
                elseif (bufftext==bufftextlist[24]) then
                    buffraidlist[i][28] = 1
                elseif (bufftext==bufftextlist[25]) then
                    buffraidlist[i][29] = 1
                end
                if (bufftext==bufftextlist[14]) then
                    buffraidlist[i][20] = 2
                end
                if (bufftext==bufftextlist[20]) then
                    buffraidlist[i][20] = 2
                end
                if (bufftext==bufftextlist[15]) then
                    buffraidlist[i][21] = 2
                end
                if (bufftext==bufftextlist[21]) then
                    buffraidlist[i][21] = 2
                end
                if (bufftext==bufftextlist[16]) then
                    buffraidlist[i][22] = 2
                end
                if (bufftext==bufftextlist[22]) then
                    buffraidlist[i][22] = 2
                end
                if (bufftext==bufftextlist[18]) then
                    buffraidlist[i][24] = 2
                end
                if (bufftext==bufftextlist[23]) then
                    buffraidlist[i][24] = 2
                end
                for k=1,16,1 do
                    if (bufftext==dpstextlist[k]) then
                        buffraidlist[i][26] = buffraidlist[i][26]..dpsnamelist[k]
                    end
                end
                buffid = buffid + 1
            end
            end
        end
    end
    buttontypeq = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    buttontypen = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
    buttontypes = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    buttontypes[25] = 0
    buttontypes[26] = 0
    for i = 1, GetNumRaidMembers(), 1 do
        -- 到位统计：面向全体团员（含离线/死亡/距离过远）
        if (buffraidlist[i][2]==3) then
            buttontypen[19]=0
        else
            buttontypeq[19]=0
            buttontypes[19]=buttontypes[19]+1
        end
        -- 未检测统计（离线/死亡/距离过远，仅勾选职业）：装等与奥抗共用
        if type(buffraidlist[i][31])=="string" then
            buttontypeq[24]=0
            buttontypes[25]=(buttontypes[25] or 0)+1
            buttontypeq[21]=0
            buttontypes[26]=(buttontypes[26] or 0)+1
        end
        if  buffraidlist[i][4]>0 then
            if buffraidlist[i][26]~="" then
                buttontypen[23]=0					
            else
                buttontypeq[23]=0
            end			
            for j=10,11,1 do
                if buffraidlist[i][j]==1 then
                    buttontypen[j-6]=0					
                else
                    buttontypeq[j-6]=0
                    buttontypes[j-6]=buttontypes[j-6]+1
                end				
            end	
            if buffraidlist[i][8]==1 then
                buttontypen[2]=0					
            else
                buttontypeq[2]=0
                buttontypes[2]=buttontypes[2]+1
            end				
            for j=14,15,1 do
                if buffraidlist[i][j]==1 then
                    buttontypen[j-6]=0					
                else
                    buttontypeq[j-6]=0
                    buttontypes[j-6]=buttontypes[j-6]+1
                end				
            end
            for j=17,18,1 do
                if buffraidlist[i][j]==1 then
                    buttontypen[j-6]=0					
                else
                    buttontypeq[j-6]=0
                    buttontypes[j-6]=buttontypes[j-6]+1
                end				
            end
            for j=27,29,1 do
                if buffraidlist[i][j]==1 then
                    buttontypen[12]=0			
                else
                    buttontypeq[12]=0
                    buttontypes[12]=buttontypes[12]+1
                end				
            end
            if (buffraidlist[i][19]==1 ) then
                buttontypen[13]=0
            else
                if (buffraidlist[i][19]==0) then
                    buttontypeq[13]=0
                    buttontypes[13]=buttontypes[13]+1
                end
            end
            if (buffraidlist[i][13]==1 and buffraidlist[i][5]>2) then
                buttontypen[7]=0
            else
                if (buffraidlist[i][13]==0 and buffraidlist[i][5]>2) then
                    buttontypeq[7]=0
                    buttontypes[7]=buttontypes[7]+1
                end
            end
            if (buffraidlist[i][16]==1 and buffraidlist[i][5]<3) then
                buttontypen[10]=0
            else
                if (buffraidlist[i][16]==0 and buffraidlist[i][5]<3) then
                    buttontypeq[10]=0
                    buttontypes[10]=buttontypes[10]+1
                end
            end
            if (buffraidlist[i][7]==1 and buffraidlist[i][5]>2) then
                buttontypen[1]=0
            else
                if (buffraidlist[i][7]==0 and buffraidlist[i][5]>2) then
                    buttontypeq[1]=0
                    buttontypes[1]=buttontypes[1]+1
                end
            end
            if (buffraidlist[i][9]==1 and buffraidlist[i][5]>2) then
                buttontypen[3]=0
            else
                if (buffraidlist[i][9]==0 and buffraidlist[i][5]>2) then
                    buttontypeq[3]=0
                    buttontypes[3]=buttontypes[3]+1
                end
            end
            if (buffraidlist[i][12]==1 and (buffraidlist[i][5]==5 or buffraidlist[i][5]==6)) then
                buttontypen[6]=0
                buttontypes[6]=buttontypes[6]+1
            end
            if (buffraidlist[i][3]==0) then
                buttontypen[20]=0				
            else
                buttontypeq[20]=0
                buttontypes[20]=buttontypes[20]+1
            end
            if (buffraidlist[i][4]>(RC_MainFrameHpNowButton:GetText()*1)) then
                buttontypen[21]=0
            else
                buttontypeq[21]=0
                buttontypes[21]=buttontypes[21]+1
            end
            if (buffraidlist[i][23]==1) then
                buttontypen[17]=0
            else
                buttontypeq[17]=0
                buttontypes[17]=buttontypes[17]+1
            end
            -- 奥抗检测统计（使用索引24；未检测已在外层单列到25）
            local threshold = tonumber(RC_MainFrameBuffcHpButton:GetText()) or 0
            if (buffraidlist[i][30] or 0) >= threshold then
                buttontypen[24]=0
            else
                buttontypeq[24]=0
                buttontypes[24]=buttontypes[24]+1
            end
            if RC_MainFrameBuffd9CheckBox:GetChecked() then
                buffd9checked=1
                if (buffraidlist[i][20]==2) then
                    buttontypen[14]=0
                else
                    buttontypeq[14]=0
                    buttontypes[14]=buttontypes[14]+1
                end
                if (buffraidlist[i][21]==2) then
                    buttontypen[15]=0
                else
                    buttontypeq[15]=0
                    buttontypes[15]=buttontypes[15]+1
                end
                if (buffraidlist[i][22]==2) then
                    buttontypen[16]=0
                else
                    buttontypeq[16]=0
                    buttontypes[16]=buttontypes[16]+1
                end
                if (buffraidlist[i][24]==2) then
                    buttontypen[18]=0
                else
                    buttontypeq[18]=0
                    buttontypes[18]=buttontypes[18]+1
                end
            else
                buffd9checked=0
                if (buffraidlist[i][20]>0) then
                    buttontypen[14]=0
                else
                    buttontypeq[14]=0
                    buttontypes[14]=buttontypes[14]+1
                end
                if (buffraidlist[i][21]>0) then
                    buttontypen[15]=0
                else
                    buttontypeq[15]=0
                    buttontypes[15]=buttontypes[15]+1
                end
                if (buffraidlist[i][22]>0) then
                    buttontypen[16]=0
                else
                    buttontypeq[16]=0
                    buttontypes[16]=buttontypes[16]+1
                end
                if (buffraidlist[i][24]>0) then
                    buttontypen[18]=0
                else
                    buttontypeq[18]=0
                    buttontypes[18]=buttontypes[18]+1
                end
            end
        end
    end	
    for i = 1, 23, 1 do  -- 注意：这里只循环到23，c6对应24将在后面单独处理
        if i < 12 then
            ButtonName = "RC_MainFrameBuffa"..i.."Button"
        else
            if i < 19 then 
                ButtonName = "RC_MainFrameBuffb"..(i-11).."Button"
            else
                ButtonName = "RC_MainFrameBuffc"..(i-18).."Button"
            end
        end 
        if buttontypen[i]==1 then 
            getglobal(ButtonName):SetTextColor(0, 0, 0)
        else
            if buttontypeq[i]==1 then 
                getglobal(ButtonName):SetTextColor(0, 1, 0)
            else
                getglobal(ButtonName):SetTextColor(1, 0.82, 0)
            end
        end
    end
    -- 单独设置c6按钮颜色
    if buttontypen[24]==1 then
        RC_MainFrameBuffc6Button:SetTextColor(0, 0, 0)
    elseif buttontypeq[24]==1 then
        RC_MainFrameBuffc6Button:SetTextColor(0, 1, 0)
    else
        RC_MainFrameBuffc6Button:SetTextColor(1, 0.82, 0)
    end
    if buttontypen[6]==1 then 
        RC_MainFrameBuffa6Button:SetTextColor(1, 0, 1)
    end	
    if (buttontypes[25] or 0) > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("提示: "..buttontypes[25].."人未能检测(离线/死亡/距离过远)，相关检查结果仅供参考")
    end
end

function RC_SayChannel()
	if channelselect == "工会" then 
		SendChatMessage(smsg, "GUILD")
	end
	if channelselect == "团队" then 
		SendChatMessage(smsg, "RAID")
	end
	if channelselect == "队伍" then 
		SendChatMessage(smsg, "PARTY")
	end
	if channelselect == "近聊" then 
		SendChatMessage(smsg, "SAY")
	end
	if channelselect == "自己" then 
		DEFAULT_CHAT_FRAME:AddMessage(smsg)
	end
end