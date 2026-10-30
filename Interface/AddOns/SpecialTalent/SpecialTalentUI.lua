MAX_TALENT_TABS = 5;
MAX_NUM_TALENTS = 20;
MAX_NUM_TALENT_TIERS = 8;
NUM_TALENT_COLUMNS = 4;
SPECIAL_TALENT_BRANCH_ARRAY = {};
SPECIAL_TALENT_BUTTON_SIZE = 32;
MAX_NUM_BRANCH_TEXTURES = 30;
MAX_NUM_ARROW_TEXTURES = 30;
INITIAL_SPECIAL_TALENT_OFFSET_X = 53;
INITIAL_SPECIAL_TALENT_OFFSET_Y = 45;
TALENT_POINTS_AT_60 = 51;
CYAN_FONT_COLOR_CODE = "|cff00ffff";
MAX_PLAN_COUNT = 20;

TALENT_BRANCH_TEXTURECOORDS = {
	up = {
		[1] = {0.12890625, 0.25390625, 0 , 0.484375},
		[-1] = {0.12890625, 0.25390625, 0.515625 , 1.0}
	},
	down = {
		[1] = {0, 0.125, 0, 0.484375},
		[-1] = {0, 0.125, 0.515625, 1.0}
	},
	left = {
		[1] = {0.2578125, 0.3828125, 0, 0.5},
		[-1] = {0.2578125, 0.3828125, 0.5, 1.0}
	},
	right = {
		[1] = {0.2578125, 0.3828125, 0, 0.5},
		[-1] = {0.2578125, 0.3828125, 0.5, 1.0}
	},
	topright = {
		[1] = {0.515625, 0.640625, 0, 0.5},
		[-1] = {0.515625, 0.640625, 0.5, 1.0}
	},
	topleft = {
		[1] = {0.640625, 0.515625, 0, 0.5},
		[-1] = {0.640625, 0.515625, 0.5, 1.0}
	},
	bottomright = {
		[1] = {0.38671875, 0.51171875, 0, 0.5},
		[-1] = {0.38671875, 0.51171875, 0.5, 1.0}
	},
	bottomleft = {
		[1] = {0.51171875, 0.38671875, 0, 0.5},
		[-1] = {0.51171875, 0.38671875, 0.5, 1.0}
	},
	tdown = {
		[1] = {0.64453125, 0.76953125, 0, 0.5},
		[-1] = {0.64453125, 0.76953125, 0.5, 1.0}
	},
	tup = {
		[1] = {0.7734375, 0.8984375, 0, 0.5},
		[-1] = {0.7734375, 0.8984375, 0.5, 1.0}
	},
};

TALENT_ARROW_TEXTURECOORDS = {
	top = {
		[1] = {0, 0.5, 0, 0.5},
		[-1] = {0, 0.5, 0.5, 1.0}
	},
	right = {
		[1] = {1.0, 0.5, 0, 0.5},
		[-1] = {1.0, 0.5, 0.5, 1.0}
	},
	left = {
		[1] = {0.5, 1.0, 0, 0.5},
		[-1] = {0.5, 1.0, 0.5, 1.0}
	},
};

function SpecialTalentFrame_ToggleFrame()
	if ( SpecialTalentFrame:IsVisible() ) then
		HideUIPanel(SpecialTalentFrame);
	else
		ShowUIPanel(SpecialTalentFrame);
	end
end

function SpecialTalentFrame_ToggleDragged()
	if ( SpecialTalentFrame:IsVisible() ) then
		SpecialTalentFrame:Hide();
	else
		SpecialTalentFrame:Show();
	end
end

function SpecialTalentUI_UpdateResetButtons()
	local buttonNames = {
		"SpecialTalentUI_ResetOneButton",
		"SpecialTalentUI_ResetTwoButton",
		"SpecialTalentUI_ResetThreeButton",
	};
	local fallbackTexts = {
		SPECIAL_TALENT_TAB_ONE,
		SPECIAL_TALENT_TAB_TWO,
		SPECIAL_TALENT_TAB_THREE,
	};

	for i = 1, 3 do
		local button = getglobal(buttonNames[i]);
		if ( button ) then
			local tabName = GetTalentTabInfo(i);
			if ( tabName and tabName ~= "" ) then
				button:SetText(tabName);
			else
				button:SetText(fallbackTexts[i]);
			end
		end
	end
end

-- Sunelegy修改一键应用模拟天赋功能。
SpecialTalentApplyState = {
	active = nil,
	waiting = nil,
	plan = nil,
	lastTab = nil,
	lastTalent = nil,
	lastPoints = nil,
	lastRank = nil,
}

function SpecialTalentUI_RegisterApplyPopup()
	if ( not StaticPopupDialogs or StaticPopupDialogs["SPECIAL_TALENT_APPLY_CONFIRMATION"] ) then
		return;
	end

	StaticPopupDialogs["SPECIAL_TALENT_APPLY_CONFIRMATION"] = {
		text = "%s",
		button1 = SPECIAL_TALENT_CONFIRM,
		button2 = SPECIAL_TALENT_CANCEL,
		OnAccept = function(data)
			if ( data and data.canApply and data.plan ) then
				SpecialTalentUI_BeginApplyPlan(data.plan);
			end
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	};

	StaticPopupDialogs["SPECIAL_TALENT_APPLY_NOTICE"] = {
		text = "%s",
		button1 = SPECIAL_TALENT_CANCEL,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	};
end

function SpecialTalentUI_Notify(messageText)
	if ( not messageText or messageText == "" ) then
		return;
	end
	if ( DEFAULT_CHAT_FRAME ) then
		DEFAULT_CHAT_FRAME:AddMessage(CYAN_FONT_COLOR_CODE..(SPECIAL_TALENT or "SpecialTalent")..":|r "..messageText);
	end
	if ( UIErrorsFrame ) then
		UIErrorsFrame:AddMessage(messageText, 1.0, 0.1, 0.1, 1.0);
	end
end

function SpecialTalentUI_SetApplyButtonEnabled(enabled)
	if ( not SpecialTalentFrameApplyButton ) then
		return;
	end
	if ( enabled ) then
		SpecialTalentFrameApplyButton:Enable();
	else
		SpecialTalentFrameApplyButton:Disable();
	end
end

function SpecialTalentUI_StopApplyPlan(messageText)
	SpecialTalentApplyState.active = nil;
	SpecialTalentApplyState.waiting = nil;
	SpecialTalentApplyState.plan = nil;
	SpecialTalentApplyState.lastTab = nil;
	SpecialTalentApplyState.lastTalent = nil;
	SpecialTalentApplyState.lastPoints = nil;
	SpecialTalentApplyState.lastRank = nil;
	SpecialTalentUI_SetApplyButtonEnabled(1);
	if ( messageText ) then
		SpecialTalentUI_Notify(messageText);
	end
end

function SpecialTalentUI_GetApplyPlanStatus(plan)
	local requiredPoints = 0;
	local numTabs = GetNumTalentTabs();

	for tabID = 1, numTabs do
		local tabPlan = plan[tabID] or { points = 0 };
		local numTalents = GetNumTalents(tabID);

		for talentID = 1, numTalents do
			local _, _, _, _, learnedRank = GetTalentInfo(tabID, talentID);
			local plannedRank = tabPlan[talentID] or 0;

			if ( learnedRank > plannedRank ) then
				return nil, 1;
			end
			requiredPoints = requiredPoints + (plannedRank - learnedRank);
		end
	end

	return requiredPoints;
end

function SpecialTalentUI_FindNextApplyTalent(plan)
	local hasPending = nil;
	local numTabs = GetNumTalentTabs();

	for tabID = 1, numTabs do
		local tabPlan = plan[tabID] or { points = 0 };
		local _, _, pointsSpent = GetTalentTabInfo(tabID);
		local numTalents = GetNumTalents(tabID);

		for talentID = 1, numTalents do
			local _, _, tier, _, learnedRank, maxRank, _, meetsPrereq = GetTalentInfo(tabID, talentID);
			local plannedRank = tabPlan[talentID] or 0;

			if ( learnedRank > plannedRank ) then
				return nil, nil, 1;
			end
			if ( learnedRank < plannedRank ) then
				hasPending = 1;
				if ( learnedRank < maxRank and meetsPrereq and ((tier - 1) * 5 <= pointsSpent) ) then
					return tabID, talentID;
				end
			end
		end
	end

	return nil, nil, hasPending;
end

function SpecialTalentUI_ContinueApplyPlan()
	if ( not SpecialTalentApplyState.active or not SpecialTalentApplyState.plan ) then
		return;
	end

	if ( SpecialTalentApplyState.waiting ) then
		local currentPoints = UnitCharacterPoints("player");
		local _, _, _, _, currentRank = GetTalentInfo(SpecialTalentApplyState.lastTab, SpecialTalentApplyState.lastTalent);

		if ( currentPoints >= SpecialTalentApplyState.lastPoints and currentRank <= SpecialTalentApplyState.lastRank ) then
			return;
		end

		SpecialTalentApplyState.waiting = nil;
	end

	local requiredPoints, hasConflict = SpecialTalentUI_GetApplyPlanStatus(SpecialTalentApplyState.plan);
	if ( hasConflict ) then
		SpecialTalentUI_StopApplyPlan(SPECIAL_TALENT_APPLY_CONFLICT);
		return;
	end
	if ( requiredPoints == 0 ) then
		SpecialTalentUI_StopApplyPlan(SPECIAL_TALENT_APPLY_DONE);
		return;
	end
	if ( UnitCharacterPoints("player") < requiredPoints ) then
		SpecialTalentUI_StopApplyPlan(SPECIAL_TALENT_APPLY_NO_POINTS);
		return;
	end

	local tabID, talentID, hasPending = SpecialTalentUI_FindNextApplyTalent(SpecialTalentApplyState.plan);
	if ( not tabID ) then
		if ( hasPending ) then
			SpecialTalentUI_StopApplyPlan(SPECIAL_TALENT_APPLY_CONFLICT);
		else
			SpecialTalentUI_StopApplyPlan(SPECIAL_TALENT_APPLY_DONE);
		end
		return;
	end

	SpecialTalentApplyState.lastTab = tabID;
	SpecialTalentApplyState.lastTalent = talentID;
	SpecialTalentApplyState.lastPoints = UnitCharacterPoints("player");
	SpecialTalentApplyState.lastRank = select(5, GetTalentInfo(tabID, talentID));
	SpecialTalentApplyState.waiting = 1;

	LearnTalent(tabID, talentID);
end

function SpecialTalentUI_GetSelectedPlan()
	local player, selectedPlan, plan;

	SpecialTalent_LoadPlannedSaved();
	player = PlayerOfRealm;
	selectedPlan = SpecialTalentPlannedSaved[player]["selectedPlan"];
	plan = SpecialTalentPlannedSaved[player]["plans"][selectedPlan];

	return plan;
end

function SpecialTalentUI_GetApplyPlanPopupInfo(plan)
	local requiredPoints, hasConflict, tabID, talentID, hasPending;

	if ( SpecialTalentApplyState.active ) then
		return SPECIAL_TALENT_APPLY_RUNNING, nil, "SPECIAL_TALENT_APPLY_CONFIRMATION";
	end

	requiredPoints, hasConflict = SpecialTalentUI_GetApplyPlanStatus(plan);
	if ( hasConflict ) then
		return SPECIAL_TALENT_APPLY_CONFLICT, nil, "SPECIAL_TALENT_APPLY_NOTICE";
	end
	if ( requiredPoints == 0 ) then
		return SPECIAL_TALENT_APPLY_MATCHED, nil, "SPECIAL_TALENT_APPLY_CONFIRMATION";
	end
	if ( UnitCharacterPoints("player") < requiredPoints ) then
		return SPECIAL_TALENT_APPLY_NO_POINTS, nil, "SPECIAL_TALENT_APPLY_NOTICE";
	end

	tabID, talentID, hasPending = SpecialTalentUI_FindNextApplyTalent(plan);
	if ( not tabID and hasPending ) then
		return SPECIAL_TALENT_APPLY_CONFLICT, nil, "SPECIAL_TALENT_APPLY_NOTICE";
	end

	return SPECIAL_TALENT_APPLY_CONFIRM, 1, "SPECIAL_TALENT_APPLY_CONFIRMATION";
end

function SpecialTalentUI_BeginApplyPlan(plan)
	local requiredPoints, hasConflict;

	if ( SpecialTalentApplyState.active ) then
		SpecialTalentUI_Notify(SPECIAL_TALENT_APPLY_RUNNING);
		return;
	end

	requiredPoints, hasConflict = SpecialTalentUI_GetApplyPlanStatus(plan);
	if ( hasConflict ) then
		SpecialTalentUI_Notify(SPECIAL_TALENT_APPLY_CONFLICT);
		return;
	end
	if ( requiredPoints == 0 ) then
		SpecialTalentUI_Notify(SPECIAL_TALENT_APPLY_MATCHED);
		return;
	end
	if ( UnitCharacterPoints("player") < requiredPoints ) then
		SpecialTalentUI_Notify(SPECIAL_TALENT_APPLY_NO_POINTS);
		return;
	end

	SpecialTalentApplyState.active = 1;
	SpecialTalentApplyState.plan = plan;
	SpecialTalentApplyState.waiting = nil;
	SpecialTalentApplyState.lastTab = nil;
	SpecialTalentApplyState.lastTalent = nil;
	SpecialTalentApplyState.lastPoints = nil;
	SpecialTalentApplyState.lastRank = nil;
	SpecialTalentUI_SetApplyButtonEnabled(nil);
	SpecialTalentUI_Notify(SPECIAL_TALENT_APPLY_RUNNING);
	SpecialTalentUI_ContinueApplyPlan();
end

function SpecialTalentUI_StartApplyPlan()
	local plan, messageText, canApply, popupName;

	plan = SpecialTalentUI_GetSelectedPlan();
	messageText, canApply, popupName = SpecialTalentUI_GetApplyPlanPopupInfo(plan);
	SpecialTalentUI_RegisterApplyPopup();
	StaticPopup_Show(popupName, messageText, nil, { plan = plan, canApply = canApply });
end

function SpecialTalentFrame_OnLoad()
	SpecialTalentUI_RegisterApplyPopup();
	this:RegisterEvent("CHARACTER_POINTS_CHANGED");
	this:RegisterEvent("SPELLS_CHANGED");
	this:RegisterEvent("UNIT_PORTRAIT_UPDATE");
	this:RegisterEvent("ADDON_LOADED");
	for tab=1, MAX_TALENT_TABS do
		SPECIAL_TALENT_BRANCH_ARRAY[tab]={};
		for i=1, MAX_NUM_TALENT_TIERS do
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i] = {};
			for j=1, NUM_TALENT_COLUMNS do
				SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j] = {id=nil, up=0, left=0, right=0, down=0, leftArrow=0, rightArrow=0, topArrow=0};
			end
		end
	end

	this.learnMode = "learned";
	PlayerOfRealm = UnitName("player").." of "..GetRealmName();
	SpecialTalentFrame_Toggle = SpecialTalentFrame_ToggleFrame;
	-- Sunelegy修改：让整个框体（含标题栏空白）可拖动，不止头像。
	this:RegisterForDrag("LeftButton");
end

local SpecialTalentButtonHeightAdjusted = setmetatable({}, { __mode = "k" });

function SpecialTalentFrame_OnShow()
	-- Sunelegy修改：每次打开时恢复拖动后的位置，覆盖 ShowUIPanel 按 area 的默认定位。
	if ( SpecialTalentFrameSaved and SpecialTalentFrameSaved.frameDragged == 1 and SpecialTalentFrameSaved.frameLeft and SpecialTalentFrameSaved.frameTop ) then
		SpecialTalentFrame:ClearAllPoints();
		SpecialTalentFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", SpecialTalentFrameSaved.frameLeft, SpecialTalentFrameSaved.frameTop);
	end
	SetButtonPulse(TalentMicroButton, 0, 1);

	PlaySound("TalentScreenOpen");
	UpdateMicroButtons();
	SpecialTalent_LoadPlannedSaved();

	if (not SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]]["name"]) then
		SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]]["name"] = SPECIAL_TALENT.." - "..SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]
	end

	SpecialTalentFrameTitleText:SetText(SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]]["name"]);
	SetPortraitTexture(SpecialTalentFramePortrait, "player");
	local tpoints = max(UnitLevel("player")-9, 0);
	SpecialTalentFrameTalentPointsText:SetText(tpoints);
	SpecialTalentFramePlannedCheckButtonText:SetTextColor(0,1,1);
	if ( SpecialTalentFrameResetButton ) then
		SpecialTalentFrameResetButton:SetText(SPECIAL_TALENT_RESET_PLAN);
	end
	if ( SpecialTalentFrameApplyButton ) then
		SpecialTalentFrameApplyButton:SetText(SPECIAL_TALENT_APPLY_PLAN);
	end
	SpecialTalentUI_SetApplyButtonEnabled(not SpecialTalentApplyState.active);
	SpecialTalentUI_UpdateResetButtons();
	SpecialTalent_ResolveTalentData(1);

	if pfUI and pfUI.env then
		local penv = pfUI:GetEnvironment()
		local SkinButton = penv.SkinButton
		-- Sunelegy修改兼容 pfUI 皮肤。
		
		-- 定义需要美化的按钮列表
		local buttons = {
			"SpecialTalentFrameMinimizeButton",
			"SpecialTalentFramePreviousButtonSmall",
			"SpecialTalentFrameNextButtonSmall",
			"SpecialTalentFramePreviousButtonLarge",
			"SpecialTalentFrameNextButtonLarge",
			"SpecialTalentRename",
			"SpecialTalentFrameResetButton",
			"SpecialTalentFrameApplyButton"
		}

		-- 循环美化所有按钮
		for _, buttonName in ipairs(buttons) do
			local button = _G[buttonName];
			if button then
				SkinButton(button)
				-- 同一按钮只微调一次高度，避免反复开窗持续缩小。
				if not SpecialTalentButtonHeightAdjusted[button] then
					button:SetHeight(button:GetHeight() - 1)
					SpecialTalentButtonHeightAdjusted[button] = true;
				end
			end
		end

	end

	SpecialTalentFrame_Update();
end

function SpecialTalentFrame_OnHide()
	UpdateMicroButtons();
	PlaySound("TalentScreenClose");
end

function SpecialTalentFrame_GetTalentTabDisplayInfo(tabID)
	if ( SpecialTalent_GetTalentTabDisplayInfo ) then
		return SpecialTalent_GetTalentTabDisplayInfo(tabID);
	end
	return GetTalentTabInfo(tabID);
end

function SpecialTalentFrame_Minimize()
	SpecialTalentFrameSaved.frameMinimized=1;
	if ( not SpecialTalentFrameSaved.tabShown ) then
		SpecialTalentFrameSaved.tabShown=1;
	end
	SpecialTalentFrameMinimizeButton:SetText("放大");
	SpecialTalentFrameMinimizeButton:SetWidth(39);
	SpecialTalentUI_ResetConfirmationPanel:SetPoint("TOPLEFT", SpecialTalentFrame, "TOPRIGHT", 3, -12);
	UIPanelWindows["SpecialTalentFrame"] = { area = "left", pushable = 6, whileDead = 1 };
	SpecialTalentFrame:SetWidth(345);
	SpecialTalentFrame:SetHeight(586);
	for i=2, 4 do
		getglobal("SpecialTalentFrameBorder_TopLeft"..i):Hide();
		getglobal("SpecialTalentFrameBorder_BottomLeft"..i):Hide();
	end
	for i=1, MAX_TALENT_TABS do
		local button=getglobal("SpecialTalentFrameTab"..i);
		if ( not button ) then
			break;
		end
		button:Show();

		getglobal("SpecialTalentFrameTabFrame"..i):SetPoint("TOPLEFT", SpecialTalentFrame, "TOPLEFT", 0, -80);
	end
	SpecialTalentFrameTabs_Initialize();

	SpecialTalentFrameNextButtonSmall:Show();
	SpecialTalentFramePreviousButtonSmall:Show();
	SpecialTalentFrameNextButtonLarge:Hide();
	SpecialTalentFramePreviousButtonLarge:Hide();
	SpecialTalentFrameResetButton:ClearAllPoints();
	SpecialTalentFrameResetButton:SetPoint("TOPRIGHT", SpecialTalentFrameApplyButton, "TOPLEFT", 0, 0);

	SpecialTalentFrameTalentPointsText:Hide();
	SpecialTalentFrameTalentPoints:Hide();
	SpecialTalentFrameUnspentPointsText:SetPoint("LEFT", SpecialTalentFrame, "TOP", -145, -84);

	SpecialTalentFrameLearnedPointsText:SetPoint("RIGHT", SpecialTalentFrame, "TOP", 122, -65);
	SpecialTalentFramePlannedPointsText:SetPoint("RIGHT", SpecialTalentFrame, "TOP", 122, -84);
	SpecialTalentFrameLearnedCheckButton:SetPoint("RIGHT", SpecialTalentFrame, "TOP", -19, -65);
	SpecialTalentFramePlannedCheckButton:SetPoint("RIGHT", SpecialTalentFrame, "TOP", -19, -84);

end

function SpecialTalentFrame_Maximize()
	SpecialTalentFrameSaved.frameMinimized=nil;
	SpecialTalentFrameMinimizeButton:SetText("缩小");
	SpecialTalentFrameMinimizeButton:SetWidth(38);
	SpecialTalentUI_ResetConfirmationPanel:SetPoint("TOPLEFT", SpecialTalentFrame, "TOPRIGHT", -33, -12);
	UIPanelWindows["SpecialTalentFrame"] = { area = "doublewide", pushable = 6, whileDead = 1 };
	SpecialTalentFrame:SetWidth(900);
	SpecialTalentFrame:SetHeight(586);
	for i=2, 4 do
		getglobal("SpecialTalentFrameBorder_TopLeft"..i):Show();
		getglobal("SpecialTalentFrameBorder_BottomLeft"..i):Show();
	end
	for i=1, MAX_TALENT_TABS do
		local button=getglobal("SpecialTalentFrameTab"..i);
		if ( not button ) then
			break;
		end
		button:Hide();

		getglobal("SpecialTalentFrameTabFrame"..i):SetPoint("TOPLEFT", SpecialTalentFrame, "TOPLEFT", (i-1)*278, -80);
	end

	SpecialTalentFrameNextButtonSmall:Hide();
	SpecialTalentFramePreviousButtonSmall:Hide();
	SpecialTalentFrameNextButtonLarge:Show();
	SpecialTalentFramePreviousButtonLarge:Show();
	SpecialTalentFrameResetButton:ClearAllPoints();
	SpecialTalentFrameResetButton:SetPoint("TOPRIGHT", SpecialTalentFramePreviousButtonLarge, "TOPLEFT", 0, 0);

	SpecialTalentFrameTalentPointsText:Show();
	SpecialTalentFrameTalentPoints:Show();
	SpecialTalentFrameUnspentPointsText:SetPoint("LEFT", SpecialTalentFrame, "TOP", 25, -81);

	SpecialTalentFrameLearnedPointsText:SetPoint("RIGHT", SpecialTalentFrame, "TOP", -25, -60);
	SpecialTalentFramePlannedPointsText:SetPoint("RIGHT", SpecialTalentFrame, "TOP", -25, -81);
	SpecialTalentFrameLearnedCheckButton:SetPoint("RIGHT", SpecialTalentFrame, "TOP", -165, -60);
	SpecialTalentFramePlannedCheckButton:SetPoint("RIGHT", SpecialTalentFrame, "TOP", -165, -81);

end

function SpecialTalentFrame_OnEvent()
	if ( (event == "CHARACTER_POINTS_CHANGED") or (event == "SPELLS_CHANGED") ) then
		SpecialTalentFrame_Update();
		SpecialTalentUI_ContinueApplyPlan();
	elseif ( event == "UNIT_PORTRAIT_UPDATE" ) then
		if ( arg1 == "player" ) then
			SetPortraitTexture(SpecialTalentFramePortrait, "player");
		end
	elseif ( event=="ADDON_LOADED" and (arg1=="SpecialTalent" or arg1=="SpecialTalentUI") ) then
		this:UnregisterEvent("ADDON_LOADED");
		if ( not SpecialTalentFrameSaved ) then
			SpecialTalentFrameSaved={};
		end
		SpecialTalent_LoadPlannedSaved();
		SpecialTalentUI_UpdateResetButtons();
		SpecialTalentFrame_CheckDragged();
		SpecialTalentFrameTabs_Initialize();
	end

end

function SpecialTalentFrameTalent_OnEvent()
	if ( GameTooltip:IsOwned(this) ) then
		GameTooltip:SetTalent(this.tabID, this:GetID());
	end
end

function SpecialTalentFrame_OnDrag()
	if ( not SpecialTalentFrameSaved ) then
		SpecialTalentFrameSaved={};
	end
	SpecialTalentFrameSaved.frameDragged = 1;
	SpecialTalentFrameSaved.frameLeft = SpecialTalentFrame:GetLeft();
	SpecialTalentFrameSaved.frameTop = SpecialTalentFrame:GetTop();
	-- Sunelegy修改：置为 user-placed，使 ShowUIPanel 不再覆盖拖动后的位置。
	SpecialTalentFrame:SetUserPlaced(1);
	SpecialTalentFrame_CheckDragged();
end

function SpecialTalentFrame_Update()
	local numTabs = GetNumTalentTabs();
	local learnedText = SpecialTalentFrameLearnedPointsText;
	local plannedText = SpecialTalentFramePlannedPointsText;
	local learned = "";
	local planned = "";
	local player = PlayerOfRealm;

	SpecialTalent_LoadPlannedSaved();
	local currentPlan = SpecialTalentPlannedSaved[player]["plans"][SpecialTalentPlannedSaved[player]["selectedPlan"]];

	SpecialTalentFrame_UpdateTalentPoints();
	SpecialTalentFrameTabs_Initialize();

	for f=1, MAX_TALENT_TABS do

		local talentTabName, iconTexture, pointsSpent, fileName = SpecialTalentFrame_GetTalentTabDisplayInfo(f);
		if ( not talentTabName ) then
			break;
		end
		local currentTabPlan = SpecialTalent_EnsurePlanTab(currentPlan, f);
		getglobal("SpecialTalentFrameTabFrame"..f):Hide();
		local base;
		local name = talentTabName;
		if ( fileName and fileName ~= "" ) then
			base = "Interface\\TalentFrame\\"..fileName.."-";
		else
			base = "Interface\\TalentFrame\\MageFire-";
		end
		getglobal("SpecialTalentFrameTabFrame"..f.."BackgroundTopLeft"):SetTexture(base.."TopLeft");
		getglobal("SpecialTalentFrameTabFrame"..f.."BackgroundTopRight"):SetTexture(base.."TopRight");
		getglobal("SpecialTalentFrameTabFrame"..f.."BackgroundBottomLeft"):SetTexture(base.."BottomLeft");
		getglobal("SpecialTalentFrameTabFrame"..f.."BackgroundBottomRight"):SetTexture(base.."BottomRight");

		if ( f > 1 ) then
			learned = learned.."/";
			planned = planned.."/";
		end
		learned = learned..pointsSpent;
		planned = planned..currentTabPlan.points;
		getglobal("SpecialTalentFrameTabFrame"..f.."SpentPoints"):SetText(format(MASTERY_POINTS_SPENT, name).." "..NORMAL_FONT_COLOR_CODE..pointsSpent..FONT_COLOR_CODE_CLOSE);
		getglobal("SpecialTalentFrameTabFrame"..f.."SpentPoints"):SetText(CYAN_FONT_COLOR_CODE .. currentTabPlan.points .. "|r :"..RED_FONT_COLOR_CODE..talentTabName.."|r: "..NORMAL_FONT_COLOR_CODE..pointsSpent.."|r");
		getglobal("SpecialTalentFrameTabFrame"..f).pointsSpent = pointsSpent;

		local numTalents = GetNumTalents(f);
		if ( numTalents > MAX_NUM_TALENTS ) then
			message(SPECIAL_TALENT_TOO_MANY_TALENTS);
		end

		SpecialTalentFrame_ResetBranches(f);
		local tier, column, rank, maxRank, isExceptional, isLearnable;
		local forceDesaturated, tierUnlocked;
		local button;

		getglobal("SpecialTalentFrameTabFrame"..f).greatestTier = 0;

		if ( not SpecialTalentFrameSaved.frameMinimized or SpecialTalentFrameSaved.tabShown==f ) then
			getglobal("SpecialTalentFrameTabFrame"..f):Show();
			for i=1, MAX_NUM_TALENTS do
				button = getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i);
				if ( i <= numTalents ) then
					name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(f, i);
					SPECIAL_TALENT_BRANCH_ARRAY[f][tier][column].id = button:GetID();
				end
			end
			for i=1, MAX_NUM_TALENTS do
				button = getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i);

				if ( i <= numTalents ) then

					name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(f, i);

					local plannedPoints = currentTabPlan[i];
					if ( not plannedPoints or plannedPoints<1 ) then
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Planned"):Hide();
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."PlannedBorder"):Hide();
					else
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Planned"):SetText(plannedPoints);
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Planned"):SetTextColor(0,1,1);
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Planned"):Show();
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."PlannedBorder"):Show();
					end

					if ( rank > 0 ) then
						if ( rank < maxRank ) then
							getglobal( "SpecialTalentFrameTabFrame"..f.."Talent"..i.."Rank" ):SetTextColor( GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b );
						else
							getglobal( "SpecialTalentFrameTabFrame"..f.."Talent"..i.."Rank" ):SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
						end
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Rank"):SetText(rank);
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."RankBorder"):Show();
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Rank"):Show();
					else
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."RankBorder"):Hide();
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Rank"):Hide();
					end

					SetSpecialTalentButtonLocation(button, tier, column);
					SPECIAL_TALENT_BRANCH_ARRAY[f][tier][column].id = button:GetID();
					SetItemButtonTexture(button, iconTexture);

					local tabPointsSpent, talentPoints, requirementsMet;
					if ( SpecialTalentFrame.learnMode == "learned" ) then
						tabPointsSpent = getglobal("SpecialTalentFrameTabFrame"..f).pointsSpent;
						talentPoints = SpecialTalentFrame.talentPoints;
					elseif ( SpecialTalentFrame.learnMode == "planned" ) then
						tabPointsSpent = currentTabPlan.points;
						talentPoints = TALENT_POINTS_AT_60 - currentPlan.points;
						rank = currentTabPlan[i] or 0;
					end

					if ( talentPoints <= 0 and rank == 0  ) then
						forceDesaturated = 1;
					else
						forceDesaturated = nil;
					end

					if ( (tier - 1) * 5 <= tabPointsSpent ) then
						tierUnlocked = 1;
					else
						tierUnlocked = nil;
					end
					-- compare highest tier
					if ( tier > getglobal("SpecialTalentFrameTabFrame"..f).greatestTier and rank>0 ) then
						getglobal("SpecialTalentFrameTabFrame"..f).greatestTier = tier;
					end

					requirementsMet = SpecialTalentFrame_SetPrereqs(tier, column, forceDesaturated, tierUnlocked, f, SpecialTalent_GetTalentPrereqs(f, i)) and meetsPrereq;

					-- Talent must meet prereqs or the player must have no points to spend
					if ( requirementsMet ) then
						getglobal(button:GetName().."IconTexture"):SetAlpha(1);
						button.clickable = 1;

						if ( rank < maxRank ) then
							-- Rank is green if not maxed out
							getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Slot"):SetVertexColor(0.1, 1.0, 0.1);
						else
							getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Slot"):SetVertexColor(1.0, 0.82, 0);
						end
					else
						getglobal(button:GetName().."IconTexture"):SetAlpha(.3);
						button.clickable = nil;
						getglobal("SpecialTalentFrameTabFrame"..f.."Talent"..i.."Slot"):SetVertexColor(0.5, 0.5, 0.5);
					end

					button:Show();
				else
					button:Hide();
				end
			end
		end

		-- Draw the prereq branches
		local node;
		local textureIndex = 1;
		local xOffset, yOffset;
		local texCoords;
		-- Variable that decides whether or not to ignore drawing pieces
		local ignoreUp;
		local tempNode;
		SpecialTalentFrame_ResetBranchTextureCount(f);
		SpecialTalentFrame_ResetArrowTextureCount(f);
		for i=1, MAX_NUM_TALENT_TIERS do
			for j=1, NUM_TALENT_COLUMNS do
				node = SPECIAL_TALENT_BRANCH_ARRAY[f][i][j];

				-- Setup offsets
				xOffset = ((j - 1) * SPECIAL_TALENT_BUTTON_SIZE * 2) + INITIAL_SPECIAL_TALENT_OFFSET_X ;
				yOffset = -((i - 1) * SPECIAL_TALENT_BUTTON_SIZE * 1.75) - INITIAL_SPECIAL_TALENT_OFFSET_Y + 4;

				if ( node.id ) then
					-- Has talent
					if ( node.up ~= 0 ) then
						if ( not ignoreUp ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset, yOffset + SPECIAL_TALENT_BUTTON_SIZE, f);
						else
							ignoreUp = nil;
						end
					end
					if ( node.down ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset, yOffset - SPECIAL_TALENT_BUTTON_SIZE + 1, f);
					end
					if ( node.left ~= 0 ) then
							SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset - SPECIAL_TALENT_BUTTON_SIZE, yOffset, f);
					end
					if ( node.right ~= 0 ) then
						-- See if any connecting branches are gray and if so color them gray
						tempNode = SPECIAL_TALENT_BRANCH_ARRAY[f][i][j+1];
						if ( tempNode.left ~= 0 and tempNode.down < 0 ) then
							SpecialTalentFrame_SetBranchTexture(i, j-1, TALENT_BRANCH_TEXTURECOORDS["right"][tempNode.down], xOffset + SPECIAL_TALENT_BUTTON_SIZE, yOffset, f);
						else
							SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + SPECIAL_TALENT_BUTTON_SIZE + 1, yOffset, f);
						end
					end
					-- Draw arrows
					if ( node.rightArrow ~= 0 ) then
						SpecialTalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["right"][node.rightArrow], xOffset + SPECIAL_TALENT_BUTTON_SIZE/2 + 5, yOffset, f);
					end
					if ( node.leftArrow ~= 0 ) then
						SpecialTalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["left"][node.leftArrow], xOffset - SPECIAL_TALENT_BUTTON_SIZE/2 - 5, yOffset, f);
					end
					if ( node.topArrow ~= 0 ) then
						SpecialTalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["top"][node.topArrow], xOffset, yOffset + SPECIAL_TALENT_BUTTON_SIZE/2, f);
					end
				else
					-- Doesn't have a talent
					if ( node.up ~= 0 and node.left ~= 0 and node.right ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tup"][node.up], xOffset, yOffset, f);
					elseif ( node.down ~= 0 and node.left ~= 0 and node.right ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tdown"][node.down], xOffset, yOffset, f);
					elseif ( node.left ~= 0 and node.down ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topright"][node.left], xOffset , yOffset, f);
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32, f);
					elseif ( node.left ~= 0 and node.up ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomright"][node.left], xOffset , yOffset, f);
					elseif ( node.left ~= 0 and node.right ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + SPECIAL_TALENT_BUTTON_SIZE, yOffset, f);
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset + 1, yOffset, f);
					elseif ( node.right ~= 0 and node.down ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topleft"][node.right], xOffset , yOffset, f);
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32, f);
					elseif ( node.right ~= 0 and node.up ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomleft"][node.right], xOffset , yOffset, f);
					elseif ( node.up ~= 0 and node.down ~= 0 ) then
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset, yOffset, f);
						SpecialTalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset , yOffset - 32, f);
						ignoreUp = 1;
					end
				end
			end -- for
			-- Hide any unused branch textures
			for i=SpecialTalentFrame_GetBranchTextureCount(f), MAX_NUM_BRANCH_TEXTURES do
				getglobal("SpecialTalentFrameTabFrame"..f.."Branch"..i):Hide();
			end
			-- Hide and unused arrow textures
			for i=SpecialTalentFrame_GetArrowTextureCount(f), MAX_NUM_ARROW_TEXTURES do
				getglobal("SpecialTalentFrameTabFrame"..f.."ArrowFrameArrow"..i):Hide();
			end
		end -- if
	end --- for each tab frame
	local maxpoints = max(UnitLevel("player")-9, 0);
	local avail = maxpoints - SpecialTalentFrame.talentPoints;
	learned = learned.." = "..avail.."/"..maxpoints;
	learnedText:SetText(learned);
	planned = planned.." = "..currentPlan.points.."/"..TALENT_POINTS_AT_60;
	plannedText:SetText(planned);
end

function SpecialTalentFrame_SetArrowTexture(tier, column, texCoords, xOffset, yOffset, tab)
	local arrowTexture = SpecialTalentFrame_GetArrowTexture(tab);
	arrowTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
	arrowTexture:SetPoint("TOPLEFT", "SpecialTalentFrameTabFrame"..tab.."ArrowFrame", "TOPLEFT", xOffset, yOffset);
end

function  SpecialTalentFrame_SetBranchTexture(tier, column, texCoords, xOffset, yOffset, tab)
	local branchTexture =  SpecialTalentFrame_GetBranchTexture(tab);
	branchTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
	branchTexture:SetPoint("TOPLEFT", "SpecialTalentFrameTabFrame"..tab, "TOPLEFT", xOffset, yOffset);
end

function SpecialTalentFrame_GetArrowTexture(tab)
	local tabframe = getglobal("SpecialTalentFrameTabFrame"..tab);
	local index = tabframe.arrowIndex;
	local arrowTexture = getglobal("SpecialTalentFrameTabFrame"..tab.."ArrowFrameArrow".. index);
	getglobal("SpecialTalentFrameTabFrame"..tab).arrowIndex = index + 1;
	if ( not arrowTexture ) then
		message(SPECIAL_TALENT_NOT_ENOUGH_ARROW_TEXTURES);
	else
		arrowTexture:Show();
		return arrowTexture;
	end
end

function SpecialTalentFrame_GetBranchTexture(tab)
	local tabframe = getglobal("SpecialTalentFrameTabFrame"..tab);
	local index = tabframe.textureIndex;
	local branchTexture = getglobal("SpecialTalentFrameTabFrame"..tab.."Branch"..index);
	 tabframe.textureIndex = index + 1;
	if ( not branchTexture ) then
		message(SPECIAL_TALENT_NOT_ENOUGH_BRANCH_TEXTURES);
	else
		branchTexture:Show();
		return branchTexture;
	end
end

function SpecialTalentFrame_ResetArrowTextureCount(tab)
	 getglobal("SpecialTalentFrameTabFrame"..tab).arrowIndex = 1;
end

function SpecialTalentFrame_ResetBranchTextureCount(tab)
	 getglobal("SpecialTalentFrameTabFrame"..tab).textureIndex = 1;
end

function SpecialTalentFrame_GetArrowTextureCount(tab)
	return  getglobal("SpecialTalentFrameTabFrame"..tab).arrowIndex;
end

function SpecialTalentFrame_GetBranchTextureCount(tab)
	return getglobal("SpecialTalentFrameTabFrame"..tab).textureIndex;
end

function SpecialTalentFrame_SetPrereqs(...)
	local buttonTier = arg[1];
	local buttonColumn = arg[2];
	local forceDesaturated = arg[3];
	local tierUnlocked = arg[4];
	local tab = arg[5];
	local tier, column, isLearnable;
	local requirementsMet;
	if ( tierUnlocked and not forceDesaturated ) then
		requirementsMet = 1;
	else
		requirementsMet = nil;
	end
	for i=6, arg.n, 3 do
		tier = arg[i];
		column = arg[i+1];
		isLearnable = arg[i+2];
		if ( not isLearnable or forceDesaturated ) then
			requirementsMet = nil;
		end
		SpecialTalentFrame_DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet, tab);
	end
	return requirementsMet;
end

function SpecialTalentFrame_DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet, tab)
	if ( requirementsMet ) then
		requirementsMet = 1;
	else
		requirementsMet = -1;
	end

	-- Check to see if are in the same column
	if ( buttonColumn == column ) then
		-- Check for blocking talents
		if ( (buttonTier - tier) > 1 ) then
			-- If more than one tier difference
			for i=tier + 1, buttonTier - 1 do
				if ( SPECIAL_TALENT_BRANCH_ARRAY[tab][i][buttonColumn].id ) then
					-- If there's an id, there's a blocker
					message(format(SPECIAL_TALENT_LAYOUT_BLOCKED_VERTICAL, SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][i].id));
					return;
				end
			end
		end

		-- Draw the lines
		for i=tier, buttonTier - 1 do
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][buttonColumn].down = requirementsMet;
			if ( (i + 1) <= (buttonTier - 1) ) then
				SPECIAL_TALENT_BRANCH_ARRAY[tab][i + 1][buttonColumn].up = requirementsMet;
			end
		end

		-- Set the arrow
		SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][buttonColumn].topArrow = requirementsMet;
		return;
	end
	-- Check to see if they're in the same tier
	if ( buttonTier == tier ) then
		local left = min(buttonColumn, column);
		local right = max(buttonColumn, column);

		-- See if the distance is greater than one space
		if ( (right - left) > 1 ) then
			-- Check for blocking talents
			for i=left + 1, right - 1 do
				if ( SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][i].id ) then
					-- If there's an id, there's a blocker
					message(SPECIAL_TALENT_LAYOUT_BLOCKER);
					return;
				end
			end
		end
		-- If we get here then we're in the clear
		for i=left, right - 1 do
			SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][i].right = requirementsMet;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][i+1].left = requirementsMet;
		end
		-- Determine where the arrow goes
		if ( buttonColumn < column ) then
			SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][buttonColumn].rightArrow = requirementsMet;
		else
			SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][buttonColumn].leftArrow = requirementsMet;
		end
		return;
	end
	-- Now we know the prereq is diagonal from us
	local left = min(buttonColumn, column);
	local right = max(buttonColumn, column);
	-- Don't check the location of the current button
	if ( left == column ) then
		left = left + 1;
	else
		right = right - 1;
	end
	-- Check for blocking talents
	local blocked = nil;
	for i=left, right do
		if ( SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][i].id ) then
			-- If there's an id, there's a blocker
			blocked = 1;
		end
	end
	left = min(buttonColumn, column);
	right = max(buttonColumn, column);
	if ( not blocked ) then
		SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][buttonColumn].down = requirementsMet;
		SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][buttonColumn].up = requirementsMet;

		for i=tier, buttonTier - 1 do
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][buttonColumn].down = requirementsMet;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i + 1][buttonColumn].up = requirementsMet;
		end

		for i=left, right - 1 do
			SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][i].right = requirementsMet;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][i+1].left = requirementsMet;
		end
		-- Place the arrow
		SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][buttonColumn].topArrow = requirementsMet;
		return;
	end
	-- If we're here then we were blocked trying to go vertically first so we have to go over first, then up
	if ( left == buttonColumn ) then
		left = left + 1;
	else
		right = right - 1;
	end
	-- Check for blocking talents
	for i=left, right do
		if ( SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][i].id ) then
			-- If there's an id, then throw an error
			message(format(SPECIAL_TALENT_LAYOUT_UNDRAWABLE, SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][i].id));
			return;
		end
	end
	-- If we're here we can draw the line
	left = min(buttonColumn, column);
	right = max(buttonColumn, column);
	--SPECIAL_TALENT_BRANCH_ARRAY[tab][tier][column].down = requirementsMet;
	--SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][column].up = requirementsMet;

	for i=tier, buttonTier-1 do
		SPECIAL_TALENT_BRANCH_ARRAY[tab][i][column].up = requirementsMet;
		SPECIAL_TALENT_BRANCH_ARRAY[tab][i+1][column].down = requirementsMet;
	end

	-- Determine where the arrow goes
	if ( buttonColumn < column ) then
		SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][buttonColumn].rightArrow =  requirementsMet;
	else
		SPECIAL_TALENT_BRANCH_ARRAY[tab][buttonTier][buttonColumn].leftArrow =  requirementsMet;
	end
end

function SpecialTalent_PlanTalent( tabID, talentID )
	local _, _, tier, column, _, maxRank = GetTalentInfo(tabID, talentID);
	local saved = SpecialTalentPlannedSaved[PlayerOfRealm];
	local tab = saved["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]][tabID];
	local plannedPoints = tab[talentID];
	local tabPoints = tab.points;
	local talentPoints = saved["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]].points;

	if ( talentPoints<TALENT_POINTS_AT_60 ) then
		if ( not plannedPoints ) then
			tab[talentID] = 1;
			tab.points = tabPoints + 1;
			saved["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]].points = talentPoints + 1;
		elseif ( plannedPoints < maxRank ) then
			plannedPoints = plannedPoints + 1;
			tab[talentID] = plannedPoints;
			tab.points = tabPoints + 1;
			saved["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]].points = talentPoints + 1;
		end
	end
	SpecialTalentFrame_Update();
end

function SpecialTalent_UnplanTalent( tabID, talentID )
	local _, _, tier, column = GetTalentInfo(tabID, talentID);
	local saved = SpecialTalentPlannedSaved[PlayerOfRealm];
	local tab = saved["plans"][saved["selectedPlan"]][tabID];
	local plannedPoints = tab[talentID];
	local tabPoints = tab.points;
	local talentPoints = saved["plans"][saved["selectedPlan"]].points;

	if ( plannedPoints and plannedPoints > 0 ) then
		-- check if tiers below and enough talentPoints to spare
		local hiTier = getglobal("SpecialTalentFrameTabFrame"..tabID).greatestTier;
		local tierPoints, tierFine, tierTotal = 0, 1, {};
		for i=1, hiTier do
			tierTotal[i]=0;
		end
		for i=1, GetNumTalents(tabID) do
			local _,_,t,_,r = SpecialTalent_GetTalentInfo(tabID, i);
			if ( t > hiTier  ) then break; end
			tierTotal[t]=tierTotal[t]+r;
			-- check dependent talents
			local rt, rc = SpecialTalent_GetTalentPrereqs(tabID, i);
			if ( rt ) then
				if ( r>0 and (rt==tier and rc==column) ) then
					tierFine=nil;
				end
			end
		end
		if ( tierFine ) then
			for i=tier+1, hiTier do
				tierPoints=0;
				for j=1, i-1 do
					tierPoints=tierPoints + tierTotal[j];
				end
				if ( tierPoints <= (i-1)*5 ) then
					tierFine=nil;
				end
			end
		end
		if ( tier==hiTier or tierFine ) then
			plannedPoints = plannedPoints > 1 and plannedPoints-1 or nil;
			tab[talentID] = plannedPoints;
			tab.points = tabPoints-1;
			saved["plans"][saved["selectedPlan"]].points = talentPoints-1;
		end
	end
	SpecialTalentFrame_Update();
end

-- Sunelegy修改已学模式仅允许左键。
function SpecialTalentFrameTalent_OnClick()
	local tabID, talentID = this.tabID, this:GetID();
	if ( SpecialTalentFrame.learnMode=="learned" ) then
		if ( arg1=="LeftButton" ) then
			LearnTalent(tabID, talentID);
			SpecialTalentFrame_Update();
		end
	elseif ( SpecialTalentFrame.learnMode=="planned" ) then
		-- check if requirements met
		if ( not this.clickable ) then
			return;
		end

		if ( arg1=="LeftButton" ) then
			SpecialTalent_PlanTalent( tabID, talentID );
		elseif ( arg1=="RightButton" ) then
			SpecialTalent_UnplanTalent( tabID, talentID );
		end
	end
	SpecialTalentButton_OnEnter();
end

function SpecialTalentFrameTalent_OnMouseWheel(value)
	-- check if requirements met
	if ( SpecialTalentFrame.learnMode=="planned" and this.clickable ) then
		if ( value > 0 ) then
			SpecialTalent_PlanTalent( this.tabID, this:GetID() );
		elseif ( value < 0 ) then
			SpecialTalent_UnplanTalent( this.tabID, this:GetID() );
		end
		SpecialTalentButton_OnEnter();
	end
end

-- Helper functions
function SpecialTalentFrame_UpdateTalentPoints()
	local cp1 = UnitCharacterPoints("player");
	SpecialTalentFrameUnspentPointsText:SetText(cp1);
	SpecialTalentFrame.talentPoints = cp1;
end

function SetSpecialTalentButtonLocation(button, tier, column)
	column = ((column - 1) * SPECIAL_TALENT_BUTTON_SIZE * 2) + INITIAL_SPECIAL_TALENT_OFFSET_X;
	tier = -((tier - 1) * SPECIAL_TALENT_BUTTON_SIZE * 1.75) - INITIAL_SPECIAL_TALENT_OFFSET_Y ;
	button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT", column, tier);
end

function SpecialTalentFrame_ResetBranches(tab)
	for i=1, MAX_NUM_TALENT_TIERS do
		for j=1, NUM_TALENT_COLUMNS do
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].id = nil;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].up = 0;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].down = 0;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].left = 0;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].right = 0;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].rightArrow = 0;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].leftArrow = 0;
			SPECIAL_TALENT_BRANCH_ARRAY[tab][i][j].topArrow = 0;
		end
	end
end

function SpecialTalent_EnsurePlanTab(plan, tabID)
	if ( not plan[tabID] ) then
		plan[tabID] = {};
	end
	if ( not plan[tabID].points ) then
		plan[tabID].points = 0;
	end
	return plan[tabID];
end

function SpecialTalent_LoadPlannedSaved()
	local player= PlayerOfRealm;
	local selectedPlan;
	if ( not SpecialTalentPlannedSaved ) then
		SpecialTalentPlannedSaved={};
	end
	if ( not SpecialTalentPlannedSaved[player] ) then
		SpecialTalentPlannedSaved[player]={};
	end
	if ( not SpecialTalentPlannedSaved[player]["selectedPlan"] ) then
		SpecialTalentPlannedSaved[player]["selectedPlan"]=1;
	end
	if ( not SpecialTalentPlannedSaved[player]["plans"] ) then
		SpecialTalentPlannedSaved[player]["plans"]={};
	end
	selectedPlan = SpecialTalentPlannedSaved[player]["selectedPlan"];
	if ( not SpecialTalentPlannedSaved[player]["plans"][selectedPlan] ) then
		SpecialTalentPlannedSaved[player]["plans"][selectedPlan]={};
	end
	if ( not SpecialTalentPlannedSaved[player]["plans"][selectedPlan].points) then
		SpecialTalentPlannedSaved[player]["plans"][selectedPlan].points = 0;
	end
	for t=1, MAX_TALENT_TABS do
		SpecialTalent_EnsurePlanTab(SpecialTalentPlannedSaved[player]["plans"][selectedPlan], t);
	end
end

function SpecialTalentFrameTabs_Initialize()
	local selectedTab = 1;
	if ( SpecialTalentFrameSaved and SpecialTalentFrameSaved.tabShown ) then
		selectedTab = SpecialTalentFrameSaved.tabShown;
	end

	for i=1, MAX_TALENT_TABS do
		local button = getglobal("SpecialTalentFrameTab"..i);
		if ( not button ) then
			break;
		end
		local name, texture = SpecialTalentFrame_GetTalentTabDisplayInfo(i);
		button.tooltip = name or UNKNOWN;
		if ( texture ) then
			button:SetNormalTexture(texture);
		end
		if ( button:GetID() == selectedTab ) then
			button:SetChecked(1);
		else
			button:SetChecked(0);
		end
	end
end

function SpecialTalentFrameTab_OnEnter()
	local name = this.tooltip;
	local texture;

	if ( not name or name == "" or name == UNKNOWN ) then
		name, texture = SpecialTalentFrame_GetTalentTabDisplayInfo(this:GetID());
		if ( name and name ~= "" ) then
			this.tooltip = name;
		end
		if ( texture ) then
			this:SetNormalTexture(texture);
		end
	end

	if ( not name or name == "" ) then
		return;
	end

	GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
	GameTooltip:SetText(name);
end

function SpecialTalentFrameTab_OnClick()
	for i=1, MAX_TALENT_TABS do
		local button = getglobal("SpecialTalentFrameTab"..i);
		if ( not button ) then
			break;
		end
		button:SetChecked(0);
	end
	this:SetChecked(1);

	SpecialTalentFrameSaved.tabShown = this:GetID();
	SpecialTalentFrame_Update();
end

function SpecialTalentFrame_CheckDragged()
	if ( SpecialTalentFrameSaved and SpecialTalentFrameSaved.frameDragged == 1 ) then
		local left = SpecialTalentFrameSaved.frameLeft;
		local top = SpecialTalentFrameSaved.frameTop;
		SpecialTalentFrame:ClearAllPoints();
		SpecialTalentFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top);
		-- Sunelegy修改：保留 UIPanelWindows 注册、保持 ToggleFrame，使拖动后 ESC 仍能关闭本框体。
		SpecialTalentFrame_Toggle = SpecialTalentFrame_ToggleFrame;
		if ( SpecialTalentFrameSaved.frameMinimized ) then
			SpecialTalentFrame_Minimize();
		else
			SpecialTalentFrame_Maximize();
		end
	else
		SpecialTalentFrame_ResetDrag();
	end
end

function SpecialTalentFrame_ResetDrag()
	if ( SpecialTalentFrameSaved and SpecialTalentFrameSaved.frameDragged ) then
		SpecialTalentFrameSaved.frameDragged = nil;
		SpecialTalentFrameSaved.frameLeft = nil;
		SpecialTalentFrameSaved.frameTop = nil;
	end
	if ( SpecialTalentFrameSaved.frameMinimized ) then
		SpecialTalentFrame_Minimize();
	else
		SpecialTalentFrame_Maximize();
	end
	SpecialTalentFrame_Toggle = SpecialTalentFrame_ToggleFrame;
	SpecialTalentFrame_Toggle();
	SpecialTalentFrame_Toggle();
end

function SpecialTalent_GetTalentInfo(tabID, talentID, planned)
	if (talentID == nil) then
		message(SPECIAL_TALENT_MISSING_TALENT_ID);
	end
		local name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tabID, talentID);
		if ( SpecialTalentFrame.learnMode == "planned" or planned ) then
			rank = SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]][tabID][talentID] or 0;
		end
		return name, iconTexture, tier, column, rank, maxRank, isExceptional, meetsPrereq;

end

function SpecialTalent_GetTalentPrereqs(tabID, talentID, planned)
	local prereqs = {GetTalentPrereqs(tabID, talentID)};
	local i=1;
	while prereqs[i] do
		local tier, column, isLearnable = prereqs[i], prereqs[i+1], prereqs[i+2];

		local _, _, _, _, rank, maxRank = SpecialTalent_GetTalentInfo(tabID, SPECIAL_TALENT_BRANCH_ARRAY[tabID][tier][column].id, (SpecialTalentFrame.learnMode == "planned" or planned) );
		if ( rank==maxRank ) then
			prereqs[i+2]=1;
		else
			prereqs[i+2]=nil;
		end
		i=i+3;
	end
	return unpack(prereqs);
end

function SpecialTalentButton_OnEnter()
	local tabID, talentID = this.tabID, this:GetID()
	GameTooltip:Hide();
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
	if ( not SpecialTalent_SetCustomTalentTooltip(tabID, talentID) ) then
		GameTooltip:SetTalent(tabID, talentID);
	end
end

function SpecialTalentUI_NextPlan()
	SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] = SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] + 1
	if SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] == MAX_PLAN_COUNT + 1 then
		SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] = 1
	end
	SpecialTalentUI_ChangePlan()
end

function SpecialTalentUI_PreviousPlan()
	SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] = SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] - 1
	if SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] == 0 then
		SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"] = MAX_PLAN_COUNT
	end
	SpecialTalentUI_ChangePlan()
end

function SpecialTalentUI_ChangePlan()
	SpecialTalent_LoadPlannedSaved();
	SpecialTalentFrame_Update()
	-- Sunelegy修改兼容旧存档，切换方案时补齐缺失的方案名。
	if (not SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]]["name"]) then
		SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]]["name"] = SPECIAL_TALENT.." - "..SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]
	end

	SpecialTalentFrameTitleText:SetText(SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]]["name"]);
end

function SpecialTalentUI_RenameCurrentPlan(name)
	SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]]["name"] = name;
	SpecialTalentUI_ChangePlan();
end

function SpecialTalentUI_ResetCurrentTree(tree)
	SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]].points =
	SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]].points -
	SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]][tree].points;

	SpecialTalentPlannedSaved[PlayerOfRealm]["plans"][SpecialTalentPlannedSaved[PlayerOfRealm]["selectedPlan"]][tree] = nil;
end

function SpecialTalentUI_ResetTree(tree)
	if tree == 1 or tree == 2 or tree == 3 then
		SpecialTalentUI_ResetCurrentTree(tree)
	else
		SpecialTalentUI_ResetCurrentTree(1)
		SpecialTalentUI_ResetCurrentTree(2)
		SpecialTalentUI_ResetCurrentTree(3)
	end
	SpecialTalentUI_ChangePlan();
end
