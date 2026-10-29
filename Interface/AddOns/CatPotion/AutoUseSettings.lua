-- Per-character recovery settings; resource controls follow item capabilities.
local addon = CatPotionAddon
local panel, draft, loading

local function Finite(value)
    local number = tonumber(value)
    if number and number-number == 0 then return number end
end

local function SavePosition(frame)
    local x, y = frame:GetCenter()
    local width, height = GetScreenWidth(), GetScreenHeight()
    x, y, width, height = Finite(x), Finite(y), Finite(width), Finite(height)
    if x and y and width and height and width > 0 and height > 0 then
        addon.GetDatabase().autoUseWindowPosition = { x / width, y / height, rel = true }
    end
end

local function LoadPosition(frame)
    local position = addon.GetDatabase().autoUseWindowPosition
    local width, height = Finite(GetScreenWidth()), Finite(GetScreenHeight())
    local x = type(position) == "table" and Finite(position[1])
    local y = type(position) == "table" and Finite(position[2])
    frame:ClearAllPoints()
    if x and y and position.rel == true and width and height and width > 0 and height > 0 then
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", math.max(0, math.min(1, x))*width, math.max(0, math.min(1, y))*height)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

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
    check.disabled = false
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
        if check.disabled then return end
        draft[field] = addon.ToBoolean(draft[field]) and 0 or 1
        if addon.ToBoolean(draft[field]) then check.mark:Show() else check.mark:Hide() end
    end)
    return check
end

local function NumberText(field, number)
    if field == "priority" then return tostring(number) end
    return number == 0 and (field == "minHealthPercent" and "仅生命点数下限" or "关闭此条件") or (number .. "%")
end

local function Threshold(parent, value, field, y, minimum, maximum)
    minimum, maximum = minimum or 0, maximum or 100
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetWidth(348)
    slider:SetHeight(14)
    slider:SetPoint("TOPLEFT", parent, "TOPLEFT", 24, y)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(1)
    slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
    addon.ApplyFlatBackdrop(slider, 0.035, 0.055, 0.09, 0.98)
    slider.title = Text(slider, value, 12)
    slider.title:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 7)
    slider.valueText = Text(slider, "0%", 12)
    slider.valueText:SetPoint("BOTTOMRIGHT", slider, "TOPRIGHT", 0, 7)
    slider:SetScript("OnValueChanged", function()
        if loading or not draft then return end
        local number = math.max(minimum, math.min(maximum, math.floor((tonumber(slider:GetValue()) or minimum) + 0.5)))
        draft[field] = number
        slider.valueText:SetText(NumberText(field, number))
    end)
    return slider
end

local function CreatePanel()
    local frame = CreateFrame("Frame", "CatPotionAutoUseSettings", UIParent)
    addon.AutoUseSettings = frame
    frame:SetWidth(400)
    frame:SetHeight(332)
    LoadPosition(frame)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    -- Match the existing potion windows: clamp once; never re-anchor on drop.
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame.dragging = false
    frame:SetScript("OnDragStart", function()
        frame.dragging = true
        frame:StartMoving()
    end)
    frame:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        frame.dragging = false
        SavePosition(frame)
    end)
    frame:SetScript("OnHide", function()
        if frame.dragging then
            frame:StopMovingOrSizing()
            frame.dragging = false
            SavePosition(frame)
        end
    end)
    addon.ApplyFlatBackdrop(frame, 0.045, 0.065, 0.1, 0.99)
    frame.title = Text(frame, "阈值自动使用", 14)
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -15)
    frame.description = Text(frame, "当前角色共用；隐藏小窗仍生效。拖动空白处可移动。", 10)
    frame.description:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -42)
    frame.enabled = Check(frame, "启用此物品的阈值自动使用（默认关闭）", "enabled", -66)
    frame.combatOnly = Check(frame, "仅在战斗中自动使用", "combatOnly", -98)
    frame.singlePerEpisode = Check(frame, "同轮资源不足只自动用一种（本角色共用）", "singlePerEpisode", -130)
    frame.singlePerEpisode:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.singlePerEpisode, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("同一轮资源不足，只自动使用一种恢复品。", 0.85, 0.9, 1)
        GameTooltip:AddLine("恢复至本轮最高触发线加5个百分点（上限100%）后重新允许。", 0.7, 0.8, 0.9)
        GameTooltip:AddLine("关闭此项可继续自动补用；左键手动始终可用。", 0.7, 0.8, 0.9)
        GameTooltip:Show()
    end)
    frame.singlePerEpisode:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.episodeHint = Text(frame, "同轮限制需资源恢复后重置，仍可左键手动使用。", 10)
    frame.episodeHint:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -159)
    frame.priority = Threshold(frame, "自动优先级（数值越小越先）", "priority", -194, 1, 100)
    frame.priority:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.priority, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        GameTooltip:AddLine("数值越小，同类资源恢复中越先使用。", 0.85, 0.9, 1)
        GameTooltip:AddLine("保命仍优先于回蓝；同值沿用原有顺序。", 0.7, 0.8, 0.9)
        GameTooltip:AddLine("无货、冷却或条件不符时会考虑下一项。", 0.7, 0.8, 0.9)
        GameTooltip:Show()
    end)
    frame.priority:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.health = Threshold(frame, "生命低于", "healthThreshold", -162)
    frame.mana = Threshold(frame, "法力低于", "manaThreshold", -218)
    frame.energy = Threshold(frame, "能量低于", "energyThreshold", -274)
    frame.minHealth = Threshold(frame, "使用时生命必须高于", "minHealthPercent", -330)
    frame.hint = Text(frame, "", 10)
    frame.hint:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -242)
    frame.hint:SetWidth(364)
    frame.hint:SetHeight(40)
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
        local definition = addon.GetAutoUseDefinition(frame.item)
        local hasCondition = (definition.health and draft.healthThreshold > 0)
            or (definition.mana and draft.manaThreshold > 0) or (definition.energy and draft.energyThreshold > 0)
        if addon.ToBoolean(draft.enabled) and not hasCondition then
            frame.message:SetText("请至少设置一个大于 0% 的阈值。")
            return
        end
        if addon.SetAutoUseConfig(frame.item.key, draft) == false then
            frame.message:SetText("设置未保存，请重新打开后再试。")
            return
        end
        addon.SetAutoUsePolicy({ singlePerEpisode = draft.singlePerEpisode })
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
    local definition = addon.GetAutoUseDefinition(item)
    local policy = addon.GetAutoUsePolicy()
    if not config or not definition then return false end
    panel = panel or CreatePanel()
    panel:Hide()
    panel.item = item
    draft = {
        enabled = config.enabled, combatOnly = config.combatOnly,
        healthThreshold = config.healthThreshold, manaThreshold = config.manaThreshold,
        energyThreshold = config.energyThreshold, minHealthPercent = config.minHealthPercent,
        priority = config.priority, singlePerEpisode = policy.singlePerEpisode,
    }
    loading = true
    panel.title:SetText((item.label or item.item) .. " · 自动使用")
    panel.message:SetText("")
    if addon.ToBoolean(draft.enabled) then panel.enabled.mark:Show() else panel.enabled.mark:Hide() end
    if addon.ToBoolean(draft.combatOnly) then panel.combatOnly.mark:Show() else panel.combatOnly.mark:Hide() end
    if addon.ToBoolean(draft.singlePerEpisode) then panel.singlePerEpisode.mark:Show() else panel.singlePerEpisode.mark:Hide() end
    panel.combatOnly.disabled = definition.outOfCombatOnly
    panel.combatOnly:EnableMouse(not definition.outOfCombatOnly)
    panel.combatOnly:SetAlpha(definition.outOfCombatOnly and 0.5 or 1)
    panel.combatOnly.label:SetText(definition.outOfCombatOnly and "此物品仅在脱战时自动使用" or "仅在战斗中自动使用")
    local rows = {
        { panel.priority, "priority", true },
        { panel.health, "healthThreshold", definition.health },
        { panel.mana, "manaThreshold", definition.mana },
        { panel.energy, "energyThreshold", definition.energy },
        { panel.minHealth, "minHealthPercent", definition.costsHealth },
    }
    local y, last = 194, 194
    for _, row in ipairs(rows) do
        local slider, field, supported = unpack(row)
        slider:EnableMouse(supported)
        slider:SetValue(draft[field] or 0)
        if supported then
            slider:ClearAllPoints()
            slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 24, -y)
            slider:Show()
            local number = draft[field] or 0
            slider.valueText:SetText(NumberText(field, number))
            last, y = y, y+56
        else
            slider:Hide()
            slider.valueText:SetText("不适用")
        end
    end
    panel.hint:ClearAllPoints()
    panel.hint:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -(last+30))
    panel.message:ClearAllPoints()
    panel.message:SetPoint("TOPLEFT", panel, "TOPLEFT", 18, -(last+74))
    panel:SetHeight(last+136)
    local hint = definition.health and definition.mana and "生命或法力任一条件满足即可；0% 关闭该条件。"
        or "低于阈值才触发；0% 关闭该条件。"
    if definition.energy then hint = "按能量百分比触发；仅适用于盗贼能量，0% 关闭。" end
    if definition.costsHealth then
        hint = "此物品消耗生命；生命至少 " .. definition.minHealthValue .. " 点，且高于所设生命安全线。"
    elseif definition.needsRest then
        hint = hint .. " 站定且未在持续恢复时使用。"
    end
    panel.hint:SetText(hint)
    loading = false
    panel:Show()
    return true
end
