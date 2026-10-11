------------------------------------- VARIABLES ---------------------------------------
SLIB_NOM = "插件命令控制台";
SLIB_VERS = "1.0";
------------- valeurs par defaut
SlashLibSaved = true;
zSlashLibSavedData= zSlashLibSavedData or  {}
local function SlashLibSavedDatainit()
	SlashLibSavedData = {}
	
	local commands = {
        {"插件重置", "/rl", 1},
        {"清除背包物品数量信息", "/run S_ItemTip_ResetDB()", 1},
        {"收支统计", "/accountant", 1},
        {"分解助手", "/aux tooltip disenchant distribution", 1},
        {"今日价格", "/aux tooltip daily", 1},
        {"平均价格", "/aux tooltip value", 1},
        {"自动工具箱", "/auto", 1},
        {"bufftool技能触发配置", "/bufftool config", 1},
        {"bufftool技能触发锁定", "/bufftool lock", 1},
        {"世界BOSS击杀查询", "/bwcd", 1},
        {"cat！一键宏", "/cat2", 1},
        {"拉人助手", "/caps", 1},
        {"完整宏检查关闭", "/cleveroid macrocheck 0", 1},
        {"线性冷却条+走马灯", "/cl", 1},
        {"DoiteAuras类wa", "/da", 1},
        {"任务同步", "/db query", 1},
        {"任务导航箭头", "/db arrow", 1},
        {"任务追踪器", "/db tracker", 1},
        {"Diminfo信息条", "/dim", 1},
        {"DPS统计设置", "/dps config", 1},
        {"毒药助手", "/ezpoison", 1},
        {"美观经验条重置位置", "/expbar reset", 1}, 
        {"gbyh一键治疗（一键驱散）", "/gbyh", 1},
        {"吃席通告等级，1代表等级", ".hcm 1", 1},
        {"队伍查找器", "/lft", 1},
        {"浮动属性切换", "/mb", 1},
        {"浮动属性面板开关", "/mb toggle", 1},
        {"集合石浮窗开关", "/meeting visible", 1},
        {"鼠标轨迹", "/nc config", 1},
        {"PFUI设置", "/pfui", 1},
        {"PlayTurtle伤害字体设置", "/pt", 1},
        {"灵应录", "/rgui", 1},
	{"开关硬核频道", "/script CloseHC()", 1},
        {"混子走开", "/RC", 1},
        {"副本cd查询", "/RP", 1},
        {"捐赠商店", "/shop", 1},
        {"捐赠商店小地图图标显示", "/shop button", 1},
        {"装等界面切换显示", "/si toggle", 1},
        {"幻化助手", "/Tmog show", 1},
        {"邮箱日志开关", "/tm log", 1},
        {"坦克助手", "/tb", 1},
        {"饰品开关", "/trinket", 1},
        {"Tab距离设置", "/script Tab_SetFrame:Show()", 3},
        {"仇恨窗口显示", "/twt show", 1},
        {"仇恨窗口重置", "/twt rl", 1},
        {"高清伤害字体", "/unitxp", 1},
        {"许愿拍卖", "/xypm", 1},
        {"龙头buff", "/wb", 1},
        {"私聊窗口", "/wim", 1},
        {"私聊快捷回复", "/qr", 1},
    }
	
	for i, command in ipairs(commands) do
		SlashLibSavedData[i] = command
	end
end


-------------
TABLEVISBTNS = {};
SLIBLIGNE = {};
SLIBSCROLLHEIGHT = 14; -- hauteur ligne
SLIBVISLINE = 14; -- nombre de lignes visibles dans la main UI -- nombre de lignes visibles : SLIBVISLINE * SLIBSCROLLHEIGHT = hauteur ScrollFrame et aussi nombre de boutons-lignes
SLIBVISLINELIST = 14; -- nombre de lignes visibles dans la liste des slash-cmds
SLIBLISTALLCMDS = {};
local SEPLIGNE = "\n";

---------------------------------------------------------------------------------------
function slibLigneInit()
	SLIBLIGNE = {};
	SLIBLIGNE["numLi"] = 0;
	SLIBLIGNE["nom"] = "";
	SLIBLIGNE["cmd"] = "";
	SLIBLIGNE["genre"] = 1; -- genre : 1 = slash-cmd, 2 = Emote et 3 = Macro
	SLIBLIGNE["numLiOr"] = 0;
end
local function concattable()
	SlashLibSavedDatainit ()
for i = 1,getn(zSlashLibSavedData) do
	table.insert(SlashLibSavedData,zSlashLibSavedData[i])
end
end
function CloseHC()
	DEFAULT_CHAT_FRAME.editBox:SetText(".hcc")
	ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox,0)
end
function slibScrollerUpdate()
	concattable()
	--if not SlashLibSavedData or getn(SlashLibSavedData)==0  then SlashLibSavedDatainit()  end
	TABLEVISBTNS = {};
	local line; -- 1 through SLIBVISLINE
	local linePlusOffset; -- an index into our data calculated from the scroll offset
	local nbreLiMax = getn(SlashLibSavedData); -- nombre de lignes
	FauxScrollFrame_Update(SlibFrameScroller,nbreLiMax,SLIBVISLINE,SLIBSCROLLHEIGHT);

	for line = 1,SLIBVISLINE,1 do
		linePlusOffset = line + FauxScrollFrame_GetOffset(SlibFrameScroller);
		if (linePlusOffset <= nbreLiMax) then
			TABLEVISBTNS[line] = SlashLibSavedData[linePlusOffset];
			TABLEVISBTNS[line][4] = linePlusOffset;
			getglobal("SlibFrameLine_"..line.."_BtnTitre_TxtTitre"):SetText(TABLEVISBTNS[line][1]);
			getglobal("SlibFrameLine_"..line.."_BtnCmd_Tex"):SetTexture(0.3,0.3,0.3,0.4);
			local genre = TABLEVISBTNS[line][3];
			if (genre == 2) then -- emote
				getglobal("SlibFrameLine_"..line.."_BtnTitre_TxtTitre"):SetTextColor(0.4,0.7,0.9);
			elseif (genre == 3) then -- macro
				getglobal("SlibFrameLine_"..line.."_BtnTitre_TxtTitre"):SetTextColor(0.9,0.4,0.4);
			else
				getglobal("SlibFrameLine_"..line.."_BtnTitre_TxtTitre"):SetTextColor(0.9,0.9,0.4);
			end;
			getglobal("SlibFrameLine_"..line.."_BtnCmd_TxtCmd"):SetText(string.gsub(SlashLibSavedData[linePlusOffset][2],SEPLIGNE,"..."));
			getglobal("SlibFrameLine_"..line):Show();
		else
			getglobal("SlibFrameLine_"..line):Hide();
		end;
	end;
	SlibFrameScroller:Show(); -- ???
end
-------------------------- CHARGEMENT / COMMANDES /BINDINGS ---------------------------
function slibChargement()
	SlashCmdList["SLIBSHOWUI"] = slibUIShow;
		SLASH_SLIBSHOWUI1 = "/slashlib";
		SLASH_SLIBSHOWUI2 = "/cj";

	-------------- bindings
	BINDING_HEADER_SLASHLIB = SLIB_NOM;
	BINDING_NAME_SLIBshow = "显示控制台";

	-------------- suite
	slibLigneInit();
end
function slibUIClose()
	SlibEditFrame:Hide();
	SlibNameDef:SetText("");
	SlibCmdDef:SetText("");
	SlibFrame:Hide();
end
-- function slibUIEditAllumeRadios(numBtn)
-- 	SlibRadBtn1:SetChecked(0);
-- 	SlibRadBtn2:SetChecked(0);
-- 	SlibRadBtn3:SetChecked(1);
-- 	if (numBtn ~= nil and numBtn ~= "") then
-- 		local nbre = strToNumber(numBtn);
-- 		if (nbre > 1 and nbre <= 3) then
-- 			getglobal("SlibRadBtn"..numBtn):SetChecked(1);
-- 		else
-- 			SlibRadBtn3:SetChecked(1);
-- 		end;
-- 	else
-- 		print(SLIB_NOM..": 错误 - 无效按钮!");
-- 	end;
-- end
---------------------------------------------------------------------------------------
------------------------------------------ UI -----------------------------------------
function slibUIShow()
	if (SlibFrame:IsVisible()) then
		slibUIClose();
	else
		slibUIClose(); -- menage
		SlibFrame:Show(); -- ne pas intervertir avec la ligne suivante !
		slibScrollerUpdate(); -- ne pas intervertir avec la ligne precedente !
	end;
end



function slibUIDo(nomBouton)
	slibGetLibLigne(nomBouton);
	if (SLIBLIGNE["cmd"] ~= "") then
		if (SlashLibSaved) then SlibFrame:Hide(); end;
		slibDoSlashCmd(SLIBLIGNE["cmd"]);
	else
		print(SLIB_NOM..": 错误 - 命令 #"..SLIBLIGNE["numLi"].." 不存在!");
	end;
end

function slibUINew()
	slibUIEditResetTex();
	SlibNameDef:SetText("");
	SlibCmdDef:SetText("");
	--slibUIEditAllumeRadios(1); -- genre "slash-cmd" par defaut
	slibLigneInit();
	SlibEditFrame:Show();
	SlibNameDef:SetFocus();
end



 function slibUIEdit(nomBouton)
	slibGetLibLigne(nomBouton);
	if (SLIBLIGNE["numLi"] > 0) then
		slibUIEditResetTex();
		getglobal("SlibFrameLine_"..SLIBLIGNE["numLi"].."_BtnCmd_Tex"):SetTexture(1,1,0,0.9);
		SlibNameDef:SetText(SLIBLIGNE["nom"]);
		SlibCmdDef:SetText(SLIBLIGNE["cmd"]);
		--slibUIEditAllumeRadios(SLIBLIGNE["genre"]);
		SlibEditFrame:Show();
		SlibNameDef:SetFocus();
	end;
end

function slibUIEditResetTex()
	for i = 1,SLIBVISLINE,1 do
		getglobal("SlibFrameLine_"..i.."_BtnCmd_Tex"):SetTexture(0.3,0.3,0.3,0.4);
	end;
end

function slibUIEditSave()
	local nom = SlibNameDef:GetText();
	if (nom ~= "") then
		local commande = SlibCmdDef:GetText();
		local novoLigne = {nom,commande,slibUIEditGetNumRadio()};
		if (SLIBLIGNE["numLi"] == 0) then -- new
			table.insert(zSlashLibSavedData,novoLigne);
		else
			zSlashLibSavedData[SLIBLIGNE["numLiOr"]] = novoLigne;
		end;
		---------
		zSlashLibSavedData = sortTable(zSlashLibSavedData,1,"1","200");
		---------
		slibScrollerUpdate();
		slibUIEditResetTex();
		SlibEditFrame:Hide();
	else
		mPrint(SLIB_NOM..": 键入个名字，定义为这个新的命令行!");
	end;
end

function slibUIEditDelete(nomBouton)
	if (nomBouton ~= nil and nomBouton ~= "") then -- si appel depuis l'UI principale (clic liste)
		slibGetLibLigne(nomBouton);
	end;
	if (SLIBLIGNE["numLi"] > 0) then -- appel normal : btn "delete" UI edition
		table.remove(zSlashLibSavedData,SLIBLIGNE["numLiOr"]);
		slibScrollerUpdate();
		SlibEditFrame:Hide();
	else
		print(SLIB_NOM..": 空的不能删除!");
	end;
end

function slibUIEditCancel()
	SlibEditFrame:Hide();
	SlibNameDef:SetText("");
	SlibCmdDef:SetText("");
	slibUIEditResetTex();
	slibLigneInit(); -- secu
end



function slibUIEditGetNumRadio()
	-- local i;
	-- for i = 1,3,1 do
	-- 	if (getglobal("SlibRadBtn"..i):GetChecked() == 1) then return i; end;
	-- end;
	return 1; -- defaut
end



function slibScrollerListUpdate()
	local line; -- 1 through nbreLiVis
	local linePlusOffset; -- an index into our data calculated from the scroll offset
	local nbreLiMax = getn(SLIBLISTALLCMDS); -- nombre de lignes
	FauxScrollFrame_Update(SlibListFrameScroller,nbreLiMax,SLIBVISLINELIST,SLIBSCROLLHEIGHT);
	
	for line = 1,SLIBVISLINELIST,1 do
		linePlusOffset = line + FauxScrollFrame_GetOffset(SlibListFrameScroller);
		if (linePlusOffset <= nbreLiMax) then
			getglobal("SlibListLigneBtn_"..line.."_Texte"):SetText(SLIBLISTALLCMDS[linePlusOffset]);
			getglobal("SlibListLigneBtn_"..line):Show();
		else
			getglobal("SlibListLigneBtn_"..line):Hide();
		end;
	end;
	SlibListFrameScroller:Show(); -- ???
end
function slibreset()
	
	slibScrollerUpdate()

end
function slibUIEditListClick(txtBouton)
    if (txtBouton ~= nil) then
        if (string.sub(txtBouton,1,1) == "/" or string.sub(txtBouton,1,1) == ".") then
            if (IsControlKeyDown()) then -- DO (TEST)
                SlibCmdDef:SetText(SlibCmdDef:GetText()..txtBouton);
            else -- AJOUT EDIT
                slibDoSlashCmd(txtBouton);
            end;
        else
            print(SLIB_NOM..": 错误 - "..txtBouton.." 不是个有效命令行!");
        end;
    else
        print(SLIB_NOM..": 错误 - 无效命令行(NIL)!");
    end;
end

---------------------------------------------------------------------------------------
------------------------------------ FCNS INTERNES ------------------------------------


function slibGetLibLigne(nomBouton)
	if (nomBouton ~= nil) then
		local numBtn = strToNumber(extractValeur(nomBouton,"_"));

		if (numBtn > 0 and numBtn <= getn(TABLEVISBTNS)) then
			SLIBLIGNE["numLi"] = numBtn;
			SLIBLIGNE["nom"] = TABLEVISBTNS[numBtn][1];
			SLIBLIGNE["cmd"] = TABLEVISBTNS[numBtn][2];
			SLIBLIGNE["genre"] = TABLEVISBTNS[numBtn][3];
			SLIBLIGNE["numLiOr"] = TABLEVISBTNS[numBtn][4];
		else
			slibLigneInit();
			print(SLIB_NOM..": 错误 - 无法找到 #"..nilSiNul(numBtn).."!");
		end;
	else
		slibLigneInit();
		print(SLIB_NOM..": 错误 - 空行!");
	end;
end

function slibDoSlashCmd(chaineCmd)
    local chaine = chaineCmd..SEPLIGNE;
    local pos1,pos2,chaineTemp;
    local i = 1;
    while string.find(chaine,SEPLIGNE,1,true) ~= nil do
        pos1,pos2 = string.find(chaine,SEPLIGNE,1,true);
        chaineTemp = string.sub(chaine,1,pos1 - 1);
        -------- envoi ligne de commande
        if (string.sub(chaineTemp,1,1) == "/" or string.sub(chaineTemp,1,1) == ".") then
            DEFAULT_CHAT_FRAME.editBox:SetText(chaineTemp);
            ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox,0);
        else
            print(SLIB_NOM..": 错误 - "..chaineTemp.." 不是有效命令!");
        end;
        --------
        chaine = string.sub(chaine,pos2 + 1);
        i = i + 1;
        if (i > 50) then return; end; -- secu
    end;
end

function listeAllSlashCmd()
	SLIBLISTALLCMDS = {};
	local prevCommande = "";
	for index,value in pairs(SlashCmdList) do -- SlashCmdList = table Blizzard des slash-cmds
		local i = 1;
		local cmdString = TEXT(getglobal("SLASH_"..index..i));
		while (cmdString) do
			if (cmdString ~= prevCommande) then
				table.insert(SLIBLISTALLCMDS,cmdString);
				prevCommande = cmdString;
			end;
			i = i + 1;
			cmdString = TEXT(getglobal("SLASH_"..index..i));
		end;
	end;
	table.sort(SLIBLISTALLCMDS);
end

---------------------------------------------------------------------------------------
--排序（按照数字1-200排序）
function sortTable(tableOr,cle,sens,genre)
	local tableTemp = {};
	for i in ipairs(tableOr)do
		table.insert(tableTemp,i);
	end;
	if (sens == nil) then sens = "1"; end;
	sens = string.upper(string.sub(sens,1,1));
	if (genre == nil) then genre = "200"; end;
	genre = string.upper(string.sub(genre,1,1));
	for i in ipairs(tableTemp)do
		tableTemp[i] = tableOr[tableTemp[i]];
	end
	return tableTemp;
end

function extractValeur(chaine,sep)
	-- renvoit la portion de la chaine passee situee entre les 2 premiers sep (ou vide si sep n'est pas trouve)
	if (chaine ~= nil and sep ~= nil) then
		local pos = string.find(chaine,"_",1,true);
		if (pos ~= nil) then
			local chaineTemp = string.sub(chaine,pos + 1);
			pos = string.find(chaineTemp,"_",1,true);
			if (pos ~= nil) then
				return (string.sub(chaineTemp,1,pos - 1));
			else
				return chaineTemp;
			end;
		else
			return "";
		end;
	else
		return nil;
	end;
end

function strToNumber(chaine)
	local valeur = tonumber(string.gsub(string.gsub(chaine,"\"",""),"\'",""),10);
	if (valeur == nil) then valeur = 0; end;
	return valeur;
end

function booleanToSr(valeur)
	if (valeur) then return "true"; else return "false"; end;
end

function booleanToBin(valeur)
	return (valeur == 1);
end

function videSiNul(valeur)
	if (valeur == nil) then return ""; else return valeur; end;
end

function nilSiNul(valeur)
	if (valeur == nil) then return "NIL"; else return valeur; end;
end
------------------------------------- AIDE ONLINE -------------------------------------
function slibSlashListe()
	local i;
	local aideOnline =  {};
	aideOnline[1] = "/cj: 显示命令行";
	print("------------------------");
	for i = 1,getn(aideOnline),1 do
		print("   "..aideOnline[i].."\n");
	end;
	print("------------------------");
end

--聊天框创建"命令"按钮
local MySlashButton = CreateFrame("Button", "MySlashButton", ChatFrame)
SetSize(MySlashButton, 16, 16)
MySlashButton:SetNormalTexture("Interface\\AddOns\\MySlash\\UiLogo.tga")
MySlashButton:SetPushedTexture("Interface\\AddOns\\MySlash\\UiLogo.tga")
MySlashButton:GetPushedTexture():SetTexCoord(.09,.91,.09,.91)
MySlashButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
MySlashButton:GetHighlightTexture():SetTexCoord(.09,.91,.09,.91)

MySlashButton:SetPoint("BOTTOMRIGHT", ChatFrame1, "TOPRIGHT", 20, -17)

-- 添加状态保存和加载
MySlashButton:RegisterEvent("PLAYER_ENTERING_WORLD")
MySlashButton:RegisterEvent("PLAYER_LEAVING_WORLD")

MySlashButton:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        -- 加载保存的状态
        if MySlashButtonState ~= nil then
            if MySlashButtonState then
                MySlashButton:Show()
            else
                MySlashButton:Hide()
            end
        end
    elseif event == "PLAYER_LEAVING_WORLD" then
        -- 保存当前状态
        MySlashButtonState = MySlashButton:IsVisible()
    end
end)

MySlashButton:SetScript("OnMouseDown", function()
	if arg1 == "LeftButton" then
		PlaySound("igChatEmoteButton")
		slibUIShow()
		--slibUIEditListShow()
	end	
end)

MySlashButton:SetScript("OnEnter", function() 
	GameTooltip:SetOwner(this, "ANCHOR_TOP", 0, 6)
	GameTooltip:AddLine("命令")
	GameTooltip:Show()
end)

MySlashButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
EnableAutohide(MySlashButton, 1)



--Tab距离
Tab_Set = 10
local Tab_SetFrame = CreateFrame("Frame", "Tab_SetFrame", UIParent)
SetSize(Tab_SetFrame, 180, 100)
Tab_SetFrame:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background", edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 }})
Tab_SetFrame:SetBackdropColor(0, 0, 0, 0.5)
Tab_SetFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
Tab_SetFrame:Hide()

Tab_SetFrame.Slider = CreateFrame("Slider", "TabSlider", Tab_SetFrame, "OptionsSliderTemplate")
Tab_SetFrame.Slider:SetPoint("CENTER", 0, 10)
Tab_SetFrame.Slider:SetMinMaxValues(1, 50)
Tab_SetFrame.Slider:SetValueStep(1)
getglobal(Tab_SetFrame.Slider:GetName() .. "Low"):SetText(1)
getglobal(Tab_SetFrame.Slider:GetName() .. "High"):SetText(50)
Tab_SetFrame.Slider:SetScript("OnValueChanged", function()
	if GetMouseFocus() == this then
		getglobal(this:GetName() .. 'Text'):SetText("Tab距离："..arg1)
		if Tab_Set ~= nil then
			Tab_Set = arg1
		end
	end
end)

local function GetTabValue()
	if Tab_Set ~= nil then
		return Tab_Set
	else
		return 10
	end
end

Tab_SetFrame:SetScript("OnShow", function()
	getglobal(Tab_SetFrame.Slider:GetName() .. 'Text'):SetText("Tab距离："..GetTabValue())
	Tab_SetFrame.Slider:SetValue(GetTabValue())
end)

Tab_SetFrame.Confirm = CreateFrame("Button", "TabSliderConfirm", Tab_SetFrame, "UIPanelButtonTemplate")
SetSize(Tab_SetFrame.Confirm, 40, 25)
Tab_SetFrame.Confirm:SetFont(STANDARD_TEXT_FONT, 14)
Tab_SetFrame.Confirm:SetPoint("CENTER", 0, -25)	
Tab_SetFrame.Confirm:SetText("确认")
Tab_SetFrame.Confirm:SetScript("OnMouseDown", function()
	SlashCmdList["CONSOLE"]("targetNearestDistance "..Tab_Set)
	SlashCmdList["CONSOLE"]("targetNearestDistanceRadius "..Tab_Set)
end)

Tab_SetFrame.Confirm:SetScript("OnMouseUp", function()
	Tab_SetFrame:Hide()
end)

