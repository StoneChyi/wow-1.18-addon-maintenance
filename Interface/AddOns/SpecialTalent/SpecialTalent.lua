function SpecialTalentFrame_LoadUI()
	if ( SpecialTalentFrame or SpecialTalentFrame_Toggle ) then
		return;
	end
	UIParentLoadAddOn("SpecialTalentUI");
end

function ToggleTalentFrame()
	SpecialTalentFrame_LoadUI();
	if ( SpecialTalentFrame_Toggle ) then
		SpecialTalentFrame_Toggle();
	else
		TalentFrame_LoadUI();
		if ( TalentFrame_Toggle ) then
			TalentFrame_Toggle();
		end
	end
end

function UpdateTalentButton()
end

local oldUpdateMicroButtons = UpdateMicroButtons;
function UpdateMicroButtons()
	oldUpdateMicroButtons();
	if ( (SpecialTalentFrame and SpecialTalentFrame:IsVisible()) or (TalentFrame and TalentFrame:IsVisible()) ) then
		TalentMicroButton:SetButtonState("PUSHED", 1);
	else
		TalentMicroButton:SetButtonState("NORMAL");
	end
end
