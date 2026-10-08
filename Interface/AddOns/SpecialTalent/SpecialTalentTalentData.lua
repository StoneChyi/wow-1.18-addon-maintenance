local SPECIAL_TALENT_CLASS_TOKENS = {
	Druid = "DRUID",
	Hunter = "HUNTER",
	Mage = "MAGE",
	Paladin = "PALADIN",
	Priest = "PRIEST",
	Rogue = "ROGUE",
	Shaman = "SHAMAN",
	Warlock = "WARLOCK",
	Warrior = "WARRIOR",
}

local SPECIAL_TALENT_TAB_PREFIX_TO_CLASS = {
	Druid = "DRUID",
	Hunter = "HUNTER",
	Mage = "MAGE",
	Paladin = "PALADIN",
	Priest = "PRIEST",
	Rogue = "ROGUE",
	Shaman = "SHAMAN",
	Warlock = "WARLOCK",
	Warrior = "WARRIOR",
}

local function SpecialTalent_GetClassToken()
	local localizedClass, classToken = UnitClass("player");
	if ( not classToken or classToken == "" ) then
		classToken = SPECIAL_TALENT_CLASS_TOKENS[localizedClass];
	end
	if ( not classToken or classToken == "" ) then
		local _, _, _, fileName = GetTalentTabInfo(1);
		if ( fileName ) then
			for prefix, token in pairs(SPECIAL_TALENT_TAB_PREFIX_TO_CLASS) do
				if ( string.find(fileName, prefix, 1, 1) == 1 ) then
					classToken = token;
					break;
				end
			end
		end
	end
	return classToken;
end

local function SpecialTalent_NormalizeIconPath(iconPath)
	if ( not iconPath ) then
		return nil;
	end
	iconPath = string.lower(iconPath);
	iconPath = string.gsub(iconPath, "\\", "/");
	iconPath = string.gsub(iconPath, "^interface/icons/", "");
	return iconPath;
end

local function SpecialTalent_GetEmbeddedTalentCount(tabData)
	local count = 0;
	while ( tabData and tabData[count + 1] ) do
		count = count + 1;
	end
	return count;
end

local function SpecialTalent_GetPreferredTalentDataSets()
	if ( GetLocale() == "zhCN" ) then
		return SpecialTalent_TurtleTalentsData_zhCN, SpecialTalent_TurtleTalentsData_enUS;
	end
	return SpecialTalent_TurtleTalentsData_enUS, SpecialTalent_TurtleTalentsData_zhCN;
end

local function SpecialTalent_DoesClassDataMatch(classData)
	local numTabs = GetNumTalentTabs();
	if ( not numTabs or numTabs < 1 ) then
		return nil;
	end

	for tabID = 1, numTabs do
		local dataTab = classData[tabID];
		local tabName, _, _, fileName = GetTalentTabInfo(tabID);
		if ( not dataTab or not tabName ) then
			return nil;
		end
		if ( dataTab.name ~= tabName ) then
			return nil;
		end
		if ( dataTab.background and fileName and dataTab.background ~= fileName ) then
			return nil;
		end

		local numTalents = GetNumTalents(tabID);
		if ( SpecialTalent_GetEmbeddedTalentCount(dataTab) ~= numTalents ) then
			return nil;
		end

		for talentID = 1, numTalents do
			local dataTalent = dataTab[talentID];
			local talentName, iconTexture, _, _, _, maxRank = GetTalentInfo(tabID, talentID);
			if ( not dataTalent or not talentName ) then
				return nil;
			end
			if ( dataTalent.name ~= talentName ) then
				return nil;
			end
			if ( dataTalent.icon and iconTexture and SpecialTalent_NormalizeIconPath(dataTalent.icon) ~= SpecialTalent_NormalizeIconPath(iconTexture) ) then
				return nil;
			end
			if ( not dataTalent.desc or not dataTalent.desc[1] ) then
				return nil;
			end
			if ( maxRank and not dataTalent.desc[maxRank] ) then
				return nil;
			end
		end
	end

	if ( classData[numTabs + 1] ) then
		return nil;
	end

	return 1;
end

SpecialTalentTalentDataState = {
	classToken = nil,
	classData = nil,
	matched = nil,
}

-- Sunelegy修改天赋数据校验逻辑。
function SpecialTalent_ResolveTalentData(forceRefresh)
	local classToken = SpecialTalent_GetClassToken();
	if ( not classToken ) then
		return nil;
	end

	if ( not forceRefresh and SpecialTalentTalentDataState.classToken == classToken and SpecialTalentTalentDataState.matched ~= nil ) then
		return SpecialTalentTalentDataState.classData;
	end

	local preferredData, secondaryData = SpecialTalent_GetPreferredTalentDataSets();
	local matchedClassData = nil;
	local candidateData = nil;
	local numTabs = GetNumTalentTabs();

	if ( not numTabs or numTabs < 1 ) then
		return nil;
	end

	if ( preferredData and preferredData[classToken] and SpecialTalent_DoesClassDataMatch(preferredData[classToken]) ) then
		matchedClassData = preferredData[classToken];
		candidateData = preferredData;
	elseif ( secondaryData and secondaryData[classToken] and SpecialTalent_DoesClassDataMatch(secondaryData[classToken]) ) then
		matchedClassData = secondaryData[classToken];
		candidateData = secondaryData;
	end

	SpecialTalentTalentDataState.classToken = classToken;
	SpecialTalentTalentDataState.classData = matchedClassData;
	SpecialTalentTalentDataState.matched = matchedClassData and 1 or 0;
	SpecialTalentTalentDataState.dataSet = candidateData;

	return matchedClassData;
end

function SpecialTalent_GetEmbeddedTalentInfo(tabID, talentID)
	local classData = SpecialTalent_ResolveTalentData();
	if ( not classData or not classData[tabID] ) then
		return nil;
	end
	return classData[tabID][talentID];
end

local function SpecialTalent_GetFallbackTalentTabData(tabID)
	local classToken = SpecialTalent_GetClassToken();
	local preferredData, secondaryData = SpecialTalent_GetPreferredTalentDataSets();
	local classData = nil;

	if ( not classToken ) then
		return nil;
	end

	if ( preferredData and preferredData[classToken] and preferredData[classToken][tabID] ) then
		classData = preferredData[classToken];
	elseif ( secondaryData and secondaryData[classToken] and secondaryData[classToken][tabID] ) then
		classData = secondaryData[classToken];
	end

	if ( not classData ) then
		return nil;
	end

	return classData[tabID];
end

function SpecialTalent_GetTalentTabDisplayInfo(tabID)
	local name, texture, pointsSpent, background = GetTalentTabInfo(tabID);
	local tabData = nil;

	if ( not name or name == "" or not texture or not background ) then
		tabData = SpecialTalent_GetFallbackTalentTabData(tabID);
	end

	if ( not tabData ) then
		return name, texture, pointsSpent, background;
	end

	if ( (not name or name == "") and tabData.name ) then
		name = tabData.name;
	end
	if ( not texture and tabData[1] and tabData[1].icon ) then
		texture = "Interface\\Icons\\"..tabData[1].icon;
	end
	if ( not background and tabData.background ) then
		background = tabData.background;
	end
	if ( not pointsSpent ) then
		pointsSpent = 0;
	end

	return name, texture, pointsSpent, background;
end

function SpecialTalent_GetPlannedTalentRank(tabID, talentID)
	if ( not PlayerOfRealm or not SpecialTalentPlannedSaved or not SpecialTalentPlannedSaved[PlayerOfRealm] ) then
		return nil;
	end

	local playerPlans = SpecialTalentPlannedSaved[PlayerOfRealm];
	local selectedPlan = playerPlans["selectedPlan"];
	if ( not selectedPlan or not playerPlans["plans"] or not playerPlans["plans"][selectedPlan] ) then
		return nil;
	end

	local tabPlan = playerPlans["plans"][selectedPlan][tabID];
	if ( not tabPlan ) then
		return nil;
	end

	return tabPlan[talentID];
end

-- Sunelegy修改天赋提示，支持模拟加点并同时显示当前与下一层描述。
function SpecialTalent_SetCustomTalentTooltip(tabID, talentID)
	local talentData = SpecialTalent_GetEmbeddedTalentInfo(tabID, talentID);
	if ( not talentData ) then
		return nil;
	end

	local gameName, _, _, _, learnedRank, maxRank = GetTalentInfo(tabID, talentID);
	local plannedRank = SpecialTalent_GetPlannedTalentRank(tabID, talentID);
	local activeRank = learnedRank or 0;
	local rankLabel = TOOLTIP_TALENT_RANK;
	local currentDescription = nil;
	local nextRank = nil;
	local nextDescription = nil;

	if ( SpecialTalentFrame and SpecialTalentFrame.learnMode == "planned" ) then
		activeRank = plannedRank or 0;
		rankLabel = PLANNED_RANK;
	end

	if ( activeRank < 0 ) then
		activeRank = 0;
	end
	if ( maxRank and activeRank > maxRank ) then
		activeRank = maxRank;
	end

	if ( activeRank > 0 ) then
		currentDescription = talentData.desc and talentData.desc[activeRank];
	end

	if ( maxRank and activeRank < maxRank ) then
		nextRank = activeRank + 1;
		nextDescription = talentData.desc and talentData.desc[nextRank];
	end

	if ( not currentDescription and not nextDescription ) then
		return nil;
	end

	GameTooltip:ClearLines();
	GameTooltip:AddLine(talentData.name or gameName or UNKNOWN, 1.0, 1.0, 1.0);
	GameTooltip:AddLine(format(rankLabel, activeRank, maxRank or activeRank), 1.0, 1.0, 1.0);

	if ( currentDescription ) then
		GameTooltip:AddLine(currentDescription, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
	end

	if ( nextDescription ) then
		if ( currentDescription ) then
			GameTooltip:AddLine(" ");
		end
		GameTooltip:AddLine(TOOLTIP_TALENT_NEXT_RANK, 1.0, 1.0, 1.0);
		GameTooltip:AddLine(nextDescription, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
	end
	GameTooltip:Show();

	return 1;
end
