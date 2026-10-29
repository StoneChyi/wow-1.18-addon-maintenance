-- Per-character settings for the three explicitly supported recovery items.
local addon = CatPotionAddon
local panel, draft, loading

local function Text(parent, value, size)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- The inherited built-in font remains valid if the chosen file fails.
    label:SetFont("Fonts\\FRIZQT__.TTF", size or 11, "OUTLINE")
    label:SetTextColor(0.84, 0.9, 0.98)
    label:SetJustifyH("LEFT")
    label:SetText(value)
    return label
end

local function Button(parent, value, width)
    local button = CreateFrame("Button", nil, parent)
    button:SetWidth(width)
    button:SetHeight(26)
    addon.ApplyFlatBackdrop(button, 0.08, 0.22, 0.34, 0.98)
    button.label = Text(button, value, 11)
    button.label:SetPoint("CENTER", button, "CENTER", 0, 0)
    return button
end

local function Check(parent, value, field, y)
    local check = Button(parent, value, 360)
    check:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, y)
    check.label:ClearAllPoints()
    check.label:SetPoint("LEFT", check, "LEFT", 27, 0)
    check.mark = check:CreateTexture(nil, "OVERLAY")
    check.mark:SetTexture("Interface\\Buttons\\WHITE8X8")
    check.mark:SetVertexColor(0.25, 0.78, 1, 1)
    check.mark:SetWidth(11)
    check.mark:SetHeight(11)
    check.mark:SetPoint("LEFT", check, "LEFT", 7, 0)
    check:SetScript("OnClick", function()
        draft[field] = addon.ToBoolean(draft[field]) and 0 or 1
        if addon.ToBoolean(draft[field]) then check.mark:Show() else check.mark:Hide() end
    end)
    return check
end

local function Threshold(parent, value, field, y)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetWidth(348)
    slider:SetHeight(14)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    addon.ApplyFlatBackdrop(slider, 0.035, 0.055, 0.09, 0.98)
    slider.title = Text(slider, value, 12)
    slider.title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 7)
    slider.valueText = Text(slider, "0%", 12)
    slider.valueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 7)
    slider:SetScript("OnValueChanged", function()
        if loading or not draft then return end
        local number = math.max(0, math.min(100, math.floor((tonumber(slider:GetValue()) or 0) + 0.5)))
        draft[field] = number
        slider.valueText:SetText(number == 0 and "关闭此条件" or (number .. "%"))
    end)
    return slider
end

local function CreatePanel()
    local frame = CreateFrame("Frame", "CatPotionAutoUseSettings", UIParent)
    addon.AutoUseSettings = frame
    frame:SetWidth(400)
    frame:SetHeight(332)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    addon.ApplyFlatBackdrop(frame, 0.045, 0.065, 0.1, 0.99)
    frame.title = Text(frame, "阈值自动使用", 14)
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -15)
    frame.description = Text(frame, "当前角色共用；隐藏小窗后仍会检查。", 10)
    frame.description:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -42)
    frame.enabled = Check(frame, "启用此物品的阈值自动使用（默认关闭）", "enabled", -66)
    frame.combatOnly = Check(frame, "仅在战斗中自动使用", "combatOnly", -98)
    frame.health = Threshold(frame, "生命低于", "healthThreshold", -162)
    frame.mana = Threshold(frame, "法力低于", "manaThreshold", -218)
    frame.hint = Text(frame, "", 10)
    frame.hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -242)
    frame.hint:SetWidth(364)
    frame.hint:SetHeight(29)
    frame.message = Text(frame, "", 10)
    frame.message:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -275)
    frame.message:SetWidth(364)
    frame.message:SetHeight(16)
    frame.save = Button(frame, "保存", 76)
    frame.save:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -102, 12)
    frame.cancel = Button(frame, "取消", 76)
    frame.cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 12)
    frame.cancel:SetScript("OnClick", function() frame:Hide() end)
    frame.save:SetScript("OnClick", function()
        if addon.ToBoolean(draft.enabled) and draft.healthThreshold == 0 and draft.manaThreshold == 0 then
            frame.message:SetText("请至少设置一个大于 0% 的阈值。")
            return
        end
        if addon.SetAutoUseConfig(frame.item.key, draft) == false then
            frame.message:SetText("设置未保存，请重新打开后再试。")
            return
        end
        frame:Hide()
        if addon.RefreshPotionTimers then addon.RefreshPotionTimers() end
    end)
    if type(UISpecialFrames) == "table" then table.insert(UISpecialFrames, "CatPotionAutoUseSettings") end
    frame:Hide()
    return frame
end

function addon.ShowAutoUseSettings(item)
    if not addon.IsAutoUseItem or not addon.IsAutoUseItem(item) then return false end
    local config = addon.GetAutoUseConfig(item)
    if not config then return false end
    panel = panel or CreatePanel()
    panel.item = item
    draft = {
        enabled = config.enabled, combatOnly = config.combatOnly,
        healthThreshold = config.healthThreshold, manaThreshold = config.manaThreshold,
    }
    loading = true
    panel.title:SetText((item.label or item.item) .. " · 自动使用")
    panel.message:SetText("")
    if addon.ToBoolean(draft.enabled) then panel.enabled.mark:Show() else panel.enabled.mark:Hide() end
    if addon.ToBoolean(draft.combatOnly) then panel.combatOnly.mark:Show() else panel.combatOnly.mark:Hide() end
    local health = item.key ~= "majorMana"
    local mana = item.key ~= "majorHealing"
    panel.health:EnableMouse(health)
    panel.mana:EnableMouse(mana)
    panel.health:SetAlpha(health and 1 or 0.35)
    panel.mana:SetAlpha(mana and 1 or 0.35)
    panel.health:SetValue(draft.healthThreshold)
    panel.mana:SetValue(draft.manaThreshold)
    panel.health.valueText:SetText(health and (draft.healthThreshold == 0 and "关闭此条件" or (draft.healthThreshold .. "%")) or "不适用")
    panel.mana.valueText:SetText(mana and (draft.manaThreshold == 0 and "关闭此条件" or (draft.manaThreshold .. "%")) or "不适用")
    panel.hint:SetText(item.key == "nordanaarTea"
        and "生命或法力任一条件满足即可；0% 表示关闭该条件。"
        or "低于阈值才触发；0% 表示关闭该条件。")
    loading = false
    panel:Show()
    return true
end
