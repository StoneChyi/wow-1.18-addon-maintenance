pfUI.addonskinner:RegisterSkin("En_AutoEquip", function()
    local penv = pfUI:GetEnvironment()
    local StripTextures, SkinButton = penv.StripTextures, penv.SkinButton

    --local hideFrame = CreateFrame("Frame")
    --hideFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    --hideFrame:SetScript("OnEvent", function()
        --if event == "PLAYER_ENTERING_WORLD" then
            --EAE_Frame:Hide()
        --end
    --end)

    SkinButton(EAE_FrameSaveButton)
    EAE_FrameSaveButton:SetText("存")
    
    for i = 1, 8 do
        local button = _G["EAE_FrameSetButton"..i]
        if button then
            SkinButton(button)
            button:SetText(i)
        end
    end
    
    SkinButton(EAE_FrameNakedButton)
    EAE_FrameNakedButton:SetText("脱")

pfUI.addonskinner:UnregisterSkin("En_AutoEquip")
end)