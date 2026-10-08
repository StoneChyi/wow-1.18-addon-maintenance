--[[
	--主要来自xcal插件，凡人修改
    author: moird, 凡人
    email: peirthies@gmail.com
    
    说明:
	[1]使用小键盘运算
	[2]ESC:清除
	[3]回退键:回退
	[4]TAB:关闭
	
	提示：打开计算器的时候会接管键盘按键结果
]]
local XCALC_NUMBERDISPLAY = "0";
local XCALC_RUNNINGTOTAL = "";
local XCALC_PREVIOUSKEYTYPE = "none";
local XCALC_PREVIOUSOP = "";

local function LimitStringLength(str)
    if string.len(str) > 13 then
        str = string.sub(str, 1, 13) -- 截取字符串的前13位
    end
    return str
end

local function xcalc_display(displaynumber, memoryset)
    if ( displaynumber == nil or displaynumber == "" ) then
        displaynumber = "0";
    end
    XCALC_NUMBERDISPLAY = displaynumber;
    xcalc_numberdisplay:SetText(LimitStringLength(displaynumber));
end

--定义按键和相应处理函数的映射关系表
local NUMKeyMap = {
    NUMPAD0 = "0",
    NUMPAD1 = "1",
    NUMPAD2 = "2",
    NUMPAD3 = "3",
    NUMPAD4 = "4",
    NUMPAD5 = "5",
    NUMPAD6 = "6",
    NUMPAD7 = "7",
    NUMPAD8 = "8",
    NUMPAD9 = "9",
	NUMPADDECIMAL = ".",
}

local FuncKeyMap = {
    NUMPADPLUS = "+",
    NUMPADMINUS = "-",
    NUMPADMULTIPLY = "*",
    NUMPADDIVIDE = "/",
    ENTER = "=",
    BACKSPACE = "backspace",
    TAB = "hide",
    ESCAPE = "clear"
}

--全部清除
local function xcalc_clear()
    XCALC_RUNNINGTOTAL = "";
    XCALC_PREVIOUSKEYTYPE = "none";
    XCALC_PREVIOUSOP = "";
    xcalc_display("0");
end

--退格
local function xcalc_backspace()
    currText = XCALC_NUMBERDISPLAY;
    if (currText == "0") then
        return;
    else
        length = string.len(currText)-1;
        if (length < 0) then
            length = 0;
        end
        currText = string.sub(currText,0,length);
        if (string.len(currText) < 1) then
            xcalc_display("0");
        else
            xcalc_display(currText);
        end
    end
end

local function xcalc_xcalculate(expression)
	local tempvar = "QCExpVal";

	setglobal(tempvar, nil);
	RunScript(tempvar .. "=(" .. expression .. ")");
	local result = getglobal(tempvar);

	return result;
end

--"+ - * /"运算
local function xcalc_funckey(key)
	currText = XCALC_NUMBERDISPLAY;
	if (XCALC_PREVIOUSKEYTYPE=="none" or XCALC_PREVIOUSKEYTYPE=="num") then
			if (key == "/" or key == "*" or key == "-" or key == "+") then
					
				if (XCALC_PREVIOUSOP~="" and XCALC_PREVIOUSOP~="=") then
					temp = XCALC_RUNNINGTOTAL .. XCALC_PREVIOUSOP .. currText;
					currText = xcalc_xcalculate(temp);
				end
				XCALC_RUNNINGTOTAL = currText;
				XCALC_PREVIOUSOP = key;
			elseif (key == "=") then
				if (XCALC_PREVIOUSOP~="=" and XCALC_PREVIOUSOP~="") then
					temp = XCALC_RUNNINGTOTAL .. XCALC_PREVIOUSOP .. currText;
					currText = xcalc_xcalculate(temp);
					XCALC_RUNNINGTOTAL = currText;
					XCALC_PREVIOUSOP="=";
				end
			else
			
			end
				
	else --must be a func key, a second+ time
		if (key == "/" or key == "*" or key == "-" or key == "+") then
			XCALC_PREVIOUSOP=key;
		else
			XCALC_PREVIOUSOP="";
		end 
	end
	XCALC_PREVIOUSKEYTYPE = "func";
	xcalc_display(currText);
end

--数字和小数点输入
local function xcalc_numkey(key)
	currText = XCALC_NUMBERDISPLAY;

	if (XCALC_PREVIOUSKEYTYPE=="none" or XCALC_PREVIOUSKEYTYPE=="num")then
		if (key == ".") then
			if (string.find(currText, "%.") == nil) then
				currText = currText .. ".";
			end
		else
			if (currText == "0") then
				currText = "";
			end	

			currText = currText .. key;
		end
	else
		if (key == ".") then
			currText = "0.";
		else
			currText = key;
		end
	end

	XCALC_PREVIOUSKEYTYPE = "num";
    xcalc_display(currText);
end

-- 处理函数
local function CalculathandleKey(arg)
	if NUMKeyMap[arg] then
		xcalc_numkey(NUMKeyMap[arg])
    elseif FuncKeyMap[arg] then
        if FuncKeyMap[arg] == "backspace" then
            xcalc_backspace()
        elseif FuncKeyMap[arg] == "hide" then
            HideUIPanel(xcalc_window)
        elseif FuncKeyMap[arg] == "clear" then
            xcalc_clear()
        else
            xcalc_funckey(FuncKeyMap[arg])
        end
    end
end

--发送数值到聊天框
local function xcalc_numberdisplay_click()
	if ( arg1 == "LeftButton" ) then
		local channel,chatnumber = ChatFrameEditBox.chatType
		if channel == "WHISPER" then
			chatnumber = ChatFrameEditBox.tellTarget
		elseif channel == "CHANNEL" then
			chatnumber = ChatFrameEditBox.channelTarget
		end
		SendChatMessage(XCALC_NUMBERDISPLAY,channel,nil,chatnumber)
	end
end

local function xcalc_windowframe()
    --主框体
    local frame = CreateFrame("Frame", "xcalc_window", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:EnableKeyboard(true)
    frame:SetMovable(true)
	SetSize(frame, 200, 110)
    frame:SetScript("OnMouseDown", function() frame:StartMoving() end)
    frame:SetScript("OnMouseUp", function() frame:StopMovingOrSizing() end)
	frame:SetScript("OnKeyDown", function() CalculathandleKey(arg1) end)
    frame:SetBackdrop({bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        tile = true, tileSize = 14, edgeSize = 14,
                        insets = { left = 3, right = 3, top = 3, bottom = 3 }})
	frame:SetBackdropColor(0, 0, 0, .8)					
    frame:SetPoint("CENTER", 250, 150)

    --输入框
    local NumberBG = CreateFrame("Frame", "NumberBG", frame)
	NumberBG:SetFrameStrata("FULLSCREEN")
	SetSize(NumberBG, 175, 50)
	NumberBG:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false, tileSize = 14, edgeSize = 14,
		insets = {left = 3, right = 3, top = 3, bottom = 3}
	})
	NumberBG:SetBackdropColor(0, 0, 0, 0)
    NumberBG:SetPoint("TOPLEFT", 12, -15)

	--输入框数字
    local numberdisplay = frame:CreateFontString("xcalc_numberdisplay", "OVERLAY")
    numberdisplay:SetWidth(165)
    numberdisplay:SetFont(STANDARD_TEXT_FONT, 50)
	numberdisplay:SetTextColor(1, 1, 1)
    numberdisplay:SetJustifyH("RIGHT")
    numberdisplay:SetPoint("RIGHT", "NumberBG", "RIGHT", -10, 0)
    numberdisplay:SetText(XCALC_NUMBERDISPLAY)
    
    --按键"发送"
    local sendbutton = CreateFrame("Button", "xcalc_sendbutton", frame, "UIPanelButtonTemplate")
    SetSize(sendbutton, 30, 26)
    sendbutton:SetPoint("TOPRIGHT", numberdisplay, "BOTTOMRIGHT", -27, -20)
	sendbutton:SetText("发送")
    sendbutton:SetScript("OnMouseUp", function() xcalc_numberdisplay_click() end)

	--关闭
    local closebutton = CreateFrame("Button", "closebutton", frame, "UIPanelButtonTemplate")
    SetSize(closebutton, 30, 26)
    closebutton:SetPoint("LEFT", sendbutton, "RIGHT", 5, 0)
	closebutton:SetText("关闭")
    closebutton:SetScript("OnMouseUp", function() xcalc_windowdisplay() end)

    --说明
    local explainbutton = CreateFrame("Button", "xcalc_explainbutton", frame)
    SetSize(explainbutton, 30, 25)
	explainbutton:SetPoint("BOTTOMLEFT", 10, 15)
	explainbutton:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_LEFT")
		GameTooltip:ClearLines()
		GameTooltip:AddLine("使用说明")
		GameTooltip:AddLine("[1]使用小键盘运算|N[2]ESC:清除|N[3]回退键:回退|N[4]TAB:关闭|N|N提示：打开计算器的时候会接管键盘按键结果")
		GameTooltip:Show()
	end)
	explainbutton:SetScript("OnLeave", function() GameTooltip:Hide() end)	
    local explain = frame:CreateTexture("xcalc_explain")
    SetSize(explain, 20, 20)
    explain:SetTexture("Interface\\AddOns\\diminfo\\Media\\explain")
    explain:SetPoint("BOTTOMLEFT", 10, 15)	
    local explainstr = frame:CreateFontString("xcalc_explainstr", "GameFontNormal")
    SetSize(explainstr, 50, 20)
    explainstr:SetFont("Fonts\\FZJZJW.TTF",14)
	explainstr:SetTextColor(1,0.8196079,0)
    explainstr:SetPoint("LEFT", explain, "RIGHT", -10, 0)
	explainstr:SetText("(说明)")
end

--显示窗口
function xcalc_windowdisplay()
	if (xcalc_window == nil) then
		xcalc_windowframe();
	elseif (xcalc_window:IsVisible()) then
		xcalc_window:Hide();
    else
        xcalc_window:Show();
	end
end