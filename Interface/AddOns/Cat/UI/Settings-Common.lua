-- Shared builders for settings panels. All visual values intentionally match
-- the former per-panel implementations.

function MPBindConfigCheckButton(button, getSaved, key, afterChange)
    button:SetScript("OnClick", function()
        local saved = getSaved()
        if this:GetChecked() then
            saved[key] = 1
        else
            saved[key] = 0
        end
        if afterChange then
            afterChange(saved[key])
        end
    end)
end

function MPCreateConfigSlider(name, parent, point, relativeTo, relativePoint,
                              x, y, width, height, minValue, maxValue,
                              valueStep, defaultValue)
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint(point, relativeTo, relativePoint, x, y)
    slider:SetWidth(width)
    slider:SetHeight(height)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(valueStep)
    slider:SetValue(defaultValue)
    MPCatUISliderRegionHide(slider)
    return slider
end

function MPCreateConfigSelector(parent, addonName, onSelect)
    local buttons = {}
    local x = { 300, 370, 440 }

    local function BindButton(index)
        buttons[index]:SetScript("OnClick", function()
            buttons[index]:SetChecked(true)
            for buttonIndex = 1, 3 do
                if buttonIndex ~= index then
                    buttons[buttonIndex]:SetChecked(false)
                end
            end
            DEFAULT_CHAT_FRAME:AddMessage(MPTipsColor.."切换到 [配置 "..index.."]|r")
            onSelect(index)
        end)
    end

    for index = 1, 3 do
        local button = CreateFrame("CheckButton", addonName.."radio"..index, parent, "UIRadioButtonTemplate")
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", x[index], -44)
        button.text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        button.text:SetPoint("LEFT", button, "RIGHT", 0, 0)
        button.text:SetFont("Fonts\\FRIZQT__.TTF", 12)
        button.text:SetText(" 配置 "..index)
        buttons[index] = button
    end

    for index = 1, 3 do
        BindButton(index)
    end

    return buttons
end

function MPCreateCommonSettingsFooter(parent, addonName, getSaved)
    MPBottomLine(parent)

    local power = MPPublicCheckButton(parent, addonName.."CheckButton", 20, 40, MPLanguage.UI_Set_EnablePowerPotion)
    MPBindConfigCheckButton(power, getSaved, "Power")

    local powerSettings = MPPublicButton(parent, addonName.."CheckButton", MPLanguage.UI_Set_Settings, 150, 34, 80, 22)
    powerSettings:SetScript("OnClick", function()
        MPCatSettingsCloseAll()
        CatUISettingsPower:Show()
    end)

    local pick = MPPublicCheckButton(parent, addonName.."CheckButton", 340, 40, MPLanguage.UI_Set_EnableAutoLoot)
    MPBindConfigCheckButton(pick, getSaved, "Pick")

    local pickSettings = MPPublicButton(parent, addonName.."CheckButton", MPLanguage.UI_Set_Settings, 405, 34, 80, 22)
    pickSettings:SetScript("OnClick", function()
        MPCatSettingsCloseAll()
        CatUISettingAutoLoot:Show()
    end)

    return power, pick
end

function MPRefreshAndCenterSettingsWindows(windows)
    for _, window in ipairs(windows) do
        if window.run then
            window.run()
        else
            local init = _G[window[1]]
            if type(init) == "function" then
                init()
                local frame = _G[window[2]]
                frame:Hide()
                frame:ClearAllPoints()
                frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            end
        end
    end
end
